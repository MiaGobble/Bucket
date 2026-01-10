--[=[
    Used for cleanup of various data types and instances.

    @class Heap
--]=]

local Heap = {}
Heap.__index = Heap

--[=[
    Creates a new heap instance.

    @return Heap
--]=]

function Heap.new()
    
end

--[=[
    Adds userdata or an instance to the heap. Supported types include: Instance, RBXScriptConnection, function, thread, or table.

    @param Object any -- The object to be cleaned up
    @param CleanupMethodName -- If you're passing a table, this is an optional setting to choose the cleanup function name (defaults to Destroy or Disconnect)
    @return any -- The object you inputted
--]=]

function Heap:Add()
    
end

--[=[
    Adds a promise to the heap. Will return the promise, meaning it can be chained.

    @param Promise Promise -- The promise to be cleaned up
    @return Promise -- The same promise that was inputted
--]=]

function Heap:AddPromise()
    
end

--[=[
    Tells the Heap to destroy itself when the inputted instance is destroyed or parented to nil.

    @param Instance Instance -- The instance to track
--]=]

function Heap:AttachToInstance()
    
end

--[=[
    Creates another Heap and adds it to this (the parent) one.

    @return Heap -- The sub-Heap
--]=]

function Heap:Extend()
    
end

--[=[
    Removes an object from Heap's cleanup.

    @param Object any -- The object to be removed from cleanup
--]=]

function Heap:Remove()
    
end

--[=[
    Returns a function that, when called, destroys the Heap.

    @return () -> nil
--]=]

function Heap:GetWrappedDestroy()
    
end

--[=[
    Destroys the Heap, cleaning up all objects and promises inside of it.
--]=]

function Heap:Destroy()
    
end

return Heap