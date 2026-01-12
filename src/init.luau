--[=[
    Used for cleanup of various data types and instances.

    @class Heap
--]=]

local Heap = {}
Heap.__index = Heap

-- Types
export type Heap = typeof(setmetatable({}, Heap))

-- Constants
local TABLE_CLEANUP_METHODS = {
    "Destroy",
    "Disconnect",
    "Cleanup",
    "Clean",
    "Cancel",
}

local CLEANUP_METHOD_NAMES = {
    ["Instance"] = "Destroy",
    ["RBXScriptConnection"] = "Disconnect",
}

-- Imports
local Packages = script:FindFirstChild("Packages")
local Typer = if Packages then require(Packages.Typer) else require(script.Parent.Typer)

local function GetMatchingCleanupCallback(Object : any, CleanupMethodName : string?) : () -> nil
    local ThisType = typeof(Object)

    if ThisType == "function" then
        return Object
    elseif ThisType == "thread" then
        return function()
            task.cancel(Object)
        end
    end

    if CLEANUP_METHOD_NAMES[ThisType] then
        return Object[CLEANUP_METHOD_NAMES[ThisType]] :: (Object) -> nil
    end

    if ThisType == "table" then
        if CleanupMethodName then
            return Object[CleanupMethodName] :: (Object) -> nil
        end

        for _, GenericCleanupName in TABLE_CLEANUP_METHODS do
            if typeof(Object[GenericCleanupName]) == "function" then
                return Object[GenericCleanupName] :: (Object) -> nil
            end

            if typeof(Object[GenericCleanupName:lower()]) == "function" then
                return Object[GenericCleanupName:lower()] :: (Object) -> nil
            end
        end
    end

    error(`No cleanup function found for object: {Object}`)
end

local function AssertPromiseValidity(Object : any)
    local Success = pcall(function()
        Typer.TupleAssertion("table", "function", "function", "function")(Object, Object.getStatus, Object.finally, Object.cancel)
    end)

    if not Success then
        error(`Expected object ({Object}) to be a promise`)
    end
end

--[=[
    Creates a new heap instance.

    ```lua
    local HeapInstance = Heap.new()

    HeapInstance:Add(...)
    HeapInstance:Remove(...)
    HeapInstance:Destroy()
    ```

    @return Heap
--]=]

function Heap.new() : Heap
    local self = setmetatable({}, Heap)

    self.CleanupQueue = {}
    self.IsCleaning = false

    return self
end

--[=[
    Adds userdata or an instance to the heap. Supported types include: Instance, RBXScriptConnection, function, thread, or table.

    ```lua
    local HeapInstance = Heap.new()

    HeapInstance:Add(workspace.Baseplate)

    HeapInstance:Add(RunService.RenderStepped:Connect(function()
        -- ...
    end))

    HeapInstance:Add(function()
        -- ...
    end)
    ```

    @param Object any -- The object to be cleaned up
    @param CleanupMethodName string? -- If you're passing a table, this is an optional setting to choose the cleanup function name (defaults to Destroy or Disconnect)
    @return any -- The object you inputted
--]=]

function Heap:Add(Object : any, CleanupMethodName : string?)
    if self.IsCleaning then
        error("Cannot add an object to heap during cleanup")
    end

    self.CleanupQueue[Object] = GetMatchingCleanupCallback(Object, CleanupMethodName)
end

--[=[
    Adds a promise to the heap. Will return the promise, meaning it can be chained.

    ```lua
    -- local MyPromise = ...

    local HeapInstance = Heap.new()

    HeapInstance:AddPromise(MyPromise)
    ```

    @param Promise Promise -- The promise to be cleaned up
    @return Promise -- The same promise that was inputted
--]=]

function Heap:AddPromise(Object : any)
    if self.IsCleaning then
        error("Cannot add a promise to heap during cleanup")
    end

    AssertPromiseValidity(Object)

    if Object:getStatus() == "Started" then
        Object:finally(function()
            if self.IsCleaning then
                return
            end

            self.CleanupQueue[Object] = nil
        end)

        self:Add(Object)
    end

    return Object
end

--[=[
    Tells the Heap to destroy itself when the inputted instance is destroyed or parented to nil.

    ```lua
    local HeapInstance = Heap.new()

    HeapInstance:AttachToInstance(PartInstance)
    ```

    @param Instance Instance -- The instance to track
--]=]

function Heap:AttachToInstance(Object : Instance)
    if self.IsCleaning then
        error("Can't attach to instance when cleaning")
    elseif not Object:IsDescendantOf(game) then
        error("Can't attach to already destroyed instance")
    end

    local Connection = Object.Destroying:Once(function()
        self:Destroy()
    end)

    self:Add(Connection)

    return Connection
end

--[=[
    Creates another Heap and adds it to this (the parent) one.

    ```lua
    local HeapInstance = Heap.new()

    local SubHeapInstance = HeapInstance:Extend()
    ```

    @return Heap -- The sub-Heap
--]=]

function Heap:Extend()
    if self.IsCleaning then
        error("Can't extend heap when cleaning")
    end

    local SubHeap = Heap.new()

    Heap:Add(SubHeap)

    return SubHeap
end

--[=[
    Removes an object from Heap's cleanup.

    ```lua
    local HeapInstance = Heap.new()

    HeapInstance:Add(Value)
    HeapInstance:Remove(Value) -- No longer cleaned up
    ```

    @param Object any -- The object to be removed from cleanup
--]=]

function Heap:Remove(Object : any)
    if self.IsCleaning then
        error("Can't remove object when cleaning")
    end

    self.CleanupQueue[Object] = nil
end

--[=[
    Returns a function that, when called, destroys the Heap.

    ```lua
    local HeapInstance = Heap.new()

    local Destroy = HeapInstance:GetWrappedDestroy()

    Destroy()
    ```

    @return () -> nil
--]=]

function Heap:GetWrappedDestroy()
    return function()
        self:Destroy()
    end
end

--[=[
    Destroys the Heap, cleaning up all objects and promises inside of it.

    ```lua
    local HeapInstance = Heap.new()

    -- Add stuff...

    HeapInstance:Destroy()
    ```
--]=]

function Heap:Destroy()
    self.IsCleaning = true

    for Object : any, CleanupCallback : (any) -> nil in self.CleanupQueue do
        task.spawn(CleanupCallback, Object)
        self.CleanupQueue[Object] = nil
    end

    table.clear(self)
end

return Heap