require( "gameobj" )

terrain = {}
terrain.t = gameobj.t:derive()

function terrain.t:init( cfg, density, x, y, z )
   gameobj.t.init( self, cfg )

   self.pos.x = x
   self.pos.y = y
   self.pos.z = z
   --print( "Okay...", self.pos )
   self.density = density
   self.scale = density / 100
   self.surroundings = self:makeSurroundings()
   return self
end

function terrain.t:draw( lod )
   if lod < 1 then
      for _, itm in pairs( self.surroundings ) do
         itm:draw( lod )
      end
   end
   gameobj.t.draw( self )
end

function terrain.t:conservativeDraw()
   gameobj.t.draw( self )
end

-- XXX: Think of a better name for this function.  :-P
function terrain.t:makeChildTerrain( config, offset )
   local xoff = math.random() * offset - (offset/2)
   local yoff = math.random() * offset - (offset/2)
   local zoff = math.random() * offset - (offset/2)
   --print( "Config:", config )
   local s = gameobj.t:derive( config )
   --print( self.pos, self )
   s.pos.x = self.pos.x + xoff
   s.pos.y = self.pos.y + yoff
   s.pos.z = self.pos.z + zoff
   s:randomOrientation()
   return s
end

function terrain.t:makeSurroundings()
   local accm = {}
   local surr = self.config['surroundings']
   for _, itm in pairs( surr ) do
      for i=0,itm.count do
         local thing = self:makeChildTerrain( itm.config, 1000 )
         table.insert( accm, thing )
      end
   end
   return accm
end


function terrain.generateWorld()
   print( "****Generating world..." )
   local objects = {}
   -- Generate core
   for i=0,20 do
      local offset = 10000
      local x = (math.random() * offset) - (offset / 2)
      local y = (math.random() * offset) - (offset / 2)
      local z = (math.random() * offset) - (offset / 2)

      local s = terrain.t:derive( "stella.cfg", 1000, x, y, z ) 
      objects[s] = s
   end

   for i=0,20 do
      local offset = 10000
      local x = (math.random() * offset) - (offset / 2)
      local y = (math.random() * offset) - (offset / 2)
      local z = (math.random() * offset) - (offset / 2)

      local s = terrain.t:derive( "rock.cfg", 1000, x, y, z ) 
      objects[s] = s
   end

   for i=0,20 do
      local offset = 10000
      local x = (math.random() * offset) - (offset / 2)
      local y = (math.random() * offset) - (offset / 2)
      local z = (math.random() * offset) - (offset / 2)

      local s = terrain.t:derive( "gasfield.cfg", 1000, x, y, z ) 
      objects[s] = s
   end

   -- Generate first rings
   -- XXX: Make things not overlap somehow?
   local r = 50000
   local deltaR = 1000
   for i=0,100 do
      local theta = math.random() * (2 * 3.14159)
      local phi = math.random() * (2 * 3.14159)
      local x = (r + (math.random() * deltaR)) * math.cos( theta )
      local y = (r + (math.random() * deltaR)) * math.sin( theta )
      local z = math.random() * deltaR
      local s = terrain.t:derive( "stella.cfg", 1000, x, y, z )
      objects[s] = s
   end

   for i=0,100 do
      local theta = math.random() * (2 * 3.14159)
      local phi = math.random() * (2 * 3.14159)
      local y = (r + (math.random() * deltaR)) * math.cos( theta )
      local z = (r + (math.random() * deltaR)) * math.sin( theta )
      local x = math.random() * deltaR
      local s = terrain.t:derive( "rock.cfg", 1000, x, y, z )
      objects[s] = s
   end

   for i=0,100 do
      local theta = math.random() * (2 * 3.14159)
      local phi = math.random() * (2 * 3.14159)
      local z = (r + (math.random() * deltaR)) * math.cos( theta )
      local x = (r + (math.random() * deltaR)) * math.sin( theta )
      local y = math.random() * deltaR
      local s = terrain.t:derive( "gasfield.cfg", 1000, x, y, z )
      objects[s] = s
   end

   print( "***Done generating world." )
   return objects

end


module( "terrain" )
