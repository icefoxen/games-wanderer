
object = {}

object.t = {}
object.t.__index = object.t

function object.t:new( ... )
   local obj = {}
   obj.super = nil
   setmetatable( obj, object.t )
   obj.__index = obj
   return obj
end

function object.t:derive( ... )
   local newobj = {}

   newobj.super = self
   setmetatable( newobj, self )
   newobj.__index = newobj

   return newobj:init( ... )
end

function object.t:init( ... )
   return self
end

module( "object" )
