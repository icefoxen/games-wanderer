require( "wanderer.vector" )
require( "wanderer.misc" )

camera = {}

function camera.new()
   local obj = {}
   setmetatable( obj, camera )
   camera.__index = camera

   obj.dist = 10
   obj.theta = 0.1
   obj.phi = 0.1

   obj.pos = vector.new( 0, 0, 0 )
   obj.top = vector.new( 0, 1, 0 )

   return obj
end

function camera:addDistance( d )
   self.dist = self.dist + d
end

function camera:addPhi( p )
   self.phi = self.phi + p
end

function camera:addTheta( t )
   self.theta = self.theta + t
end

function camera:snapToRear()
   self.theta = -math.pi/2
   self.phi = 0
end

-- XXX: The setup and variable handling of this function is a bit baroque...
-- See if you can handle the math a bit more nicely.
function camera:orient( targetvec, facingquat )
   local fx, fy, fz = facingquat:toMatrix()
   fx = vector.new( fx.x, fx.y, fx.z )
   fy = vector.new( fy.x, fy.y, fy.z )
   fz = vector.new( fz.x, fz.y, fz.z )
   self.top = fy:copy()   -- This isn't 100% right, but works okay

   local xoff = self.dist * math.sin( self.theta ) * math.sin( self.phi )
   local yoff = self.dist * math.cos( self.theta )
   local zoff = self.dist * math.sin( self.theta ) * math.cos( self.phi )

   fx:mul( xoff )
   fy:mul( yoff )
   fz:mul( zoff )

   self.pos = vector.new( targetvec.x, targetvec.y, targetvec.z )
   self.pos:add( fx )
   self.pos:add( fy )
   self.pos:add( fz )
end


module( "camera" )
