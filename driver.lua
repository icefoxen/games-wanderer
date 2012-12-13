require( "gameobj" )
require( "resource" )
require( "camera" )
--require( "world" )
require( "terrain" )
require( "wanderer.misc" )
require( "util")

driver = {}

function driver.new()
   local obj = {}
   setmetatable( obj, driver )
   driver.__index = driver

   obj.frames = 0
   obj.continue = true
   obj.objects = {}
   obj.player = false
   obj.accelon = false
   obj.camera = camera.new()
   obj.key = resource.confLoader:get( "input.cfg" )
   return obj
end

function driver:doInput( dt )
   misc.startInput()
   local keystate = misc.getKeystate()
   if( keystate[sdlk.ESCAPE] ) then
      self.continue = false
   end

   
   if( keystate[self.key.accel] or self.accelon ) then
      self.player:accelerate( dt )
      self.accelon = false
   end
   if( keystate[self.key.decel] ) then
      self.player:decelerate( dt )
      self.accelon = false
   end

   if( keystate[self.key.up] ) then
      self.player:rotate( dt, -1, 0, 0 )
   elseif( keystate[self.key.down] ) then
      self.player:rotate( dt, 1, 0, 0 )
   end
   if( keystate[self.key.right] ) then
      self.player:rotate( dt, 0, 1, 0 )
   elseif( keystate[self.key.left] ) then
      self.player:rotate( dt, 0, -1, 0 )
   end
   if( keystate[self.key.rollleft] ) then
      self.player:rotate( dt, 0, 0, 1 )
   elseif( keystate[self.key.rollright] ) then
      self.player:rotate( dt, 0, 0, -1 )
   end

   if( keystate[self.key.accelon] ) then
      self.accelon = true
   elseif( keystate[self.key.acceloff] ) then
      self.accelon = false
   end

   local x, y, buttons = misc.getRelativeMouseState()
   -- Left = 1, middle = 2, right = 4, mousewheel doesn't show up.  >_<
   -- XXX: Possibly because it pushes and releases instantly?
   --print( buttons )
   if (buttons == 1) or (buttons == 4) then
      self.camera:addPhi( -x / 500 )
      self.camera:addTheta( y / 500 )
   elseif buttons == 2 then
      self.camera:snapToRear()
   end

end

-- XXX: The distance parsing thing is amazingly ad-hoc.
-- It works okay, though.
-- Wait, no, it actually doesn't.  ...anyway.
function driver:doDrawing()
   -- XXX: numfaces is purely for profiling, can be taken out.
   local numfaces = 0
   for x, obj in pairs( self.objects ) do
      local distance = obj:distanceFrom( self.camera.pos )
      local axis, v = obj.rot:toAxis()
      local lod = 0
      if distance > 1000 then
         lod = 1
      end
      obj:draw( lod )
   end
end

function driver:addObject( obj )
   self.objects[obj] = obj
end

function driver:addObjects( objs )
   for i, x in pairs( objs ) do
      self.objects[x] = x
   end
end

function driver:delObject( obj )
   self.objects[obj] = nil
end

function driver:doDeath()
   for x, obj in pairs( self.objects ) do
      if not obj.alive then
         self:delObject( obj )
      end
   end
end

function driver:doCalc( dt )
   for x, obj in pairs( self.objects ) do
      obj:calc( dt )
   end
end


function driver:doMainloop() 
   local starttime = misc.getTicks()
   local lastFrame = 0
   local dt = 0
   local now = 0

   self.player = gameobj.t:derive( "corvette.cfg" )
   self.player.pos.z = -100 
   self:addObject( self.player )

   self:addObjects( terrain.generateWorld() )

   self.camera:snapToRear()


   while self.continue do
      self:doInput( dt )
      self:doCalc( dt )
      self:doDeath()
      self.camera:orient( self.player.pos, self.player.rot )
      misc.startFrame( self.camera.pos, self.player.pos, self.camera.top )
      self:doDrawing() 
      misc.endFrame()

      if self.acceltoggle then
         self.player:accelerate( dt )
         print( "Accel on\n" )
      end

      self.frames = self.frames + 1
      now = misc.getTicks()
      dt = now - lastFrame
      lastFrame = now
   end

   local runtime = misc.getTicks() - starttime
   local fps = self.frames / (runtime / 1000)
   print( "FPS:", fps )
end

module( "driver" )
