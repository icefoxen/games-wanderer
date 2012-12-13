require( "resource" )
require( "object" )
require( "wanderer.misc" )
require( "wanderer.vector" )
require( "wanderer.quaternion" )

-- Game Object module and prototype class.
gameobj = {}
gameobj.t = object.t:new()

function gameobj.t:init( configfile ) 
   if not configfile then
      return self
   end
   self.config = resource.confLoader:get( configfile )
   self.mesh = resource.meshLoader:get( self.config.mesh )
   if self.config.texture then
      self.texture = resource.texLoader:get( self.config.texture )
   else
      -- XXX: Dummy texture?  Error message?
      self.texture = nil
   end

   self.pos = vector.new( 0, 0, 0 )
   self.vel = 0
   self.rot = quaternion.new()
   self.alive = true
   self.scale = self.config["scale"]

   self.maxvel = self.config["maxvelocity"]
   self.accel = self.config["accel"]
   self.rotrate = self.config["rotation"]

   return self
end

function gameobj.t:distanceFrom( vec )
   local dist = vec:copy()
   dist:sub( self.pos )
   return dist:magnitude()
end

-- lod = level of detail, 0 = highest
function gameobj.t:draw( lod )
   -- Note: does not return a real vector, just an array.
   local axis, v = self.rot:toAxis()
   if self.texture then
      misc.bindTexture( self.texture )
   end
   self.mesh:draw( self.pos, axis, v, self.scale )
end

function gameobj.t:move( vector )
   self.pos:add( vector )
end

function gameobj.t:rotate( dt, x, y, z )
   local q = quaternion.new()
   q:fromAxis( -1, x * self.rotrate * dt, y * self.rotrate * dt, z * self.rotrate * dt )
   q:normalize()
   self.rot:mul( q )
   self.rot:normalize()
end

function gameobj.t:randomOrientation()
   self.rot.w = math.random()
   self.rot.x = math.random()
   self.rot.y = math.random()
   self.rot.z = math.random()
end

function gameobj.t:accelerate( dt )
   self.vel = math.min( self.maxvel, self.vel + (self.accel * dt) )
end

function gameobj.t:decelerate( dt )
   self.vel = math.max( 0, self.vel - (self.accel * dt) )
end

function gameobj.t:doDrag( dt )
   self:decelerate( dt / 20 )
end

function gameobj.t:calc( dt )
   -- Sadly, toMatrix() doesn't return a real vector.  Oh well.
   local x, y, z = self.rot:toMatrix()
   local vx = vector.new( z.x, z.y, z.z )
   vx:mul( self.vel * dt )
   self:doDrag( dt )
   self.pos:add( vx )
end

module( "gameobj" )
