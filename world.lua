-- This file contains functions to randomly generate the universe.

require( "util" )
require( "gameobj" )

world = {}

function world.newObject( cfg, x, y, z )
   local g = gameobj.new( cfg )
   g.pos.x = x
   g.pos.y = y
   g.pos.z = z
   return g
end


function world.makeStuff( config, num, offset, x, y, z )
   local objects = {}
   for i = 0, num do
      local xoff = math.random() * offset - (offset/2)
      local yoff = math.random() * offset - (offset/2)
      local zoff = math.random() * offset - (offset/2)
      local s = world.newObject( config, x + xoff, y + yoff, z + zoff )
      s:randomOrientation()
      table.insert( objects, s )
   end
   return objects
end

function world.makeStella( x, y, z )
   local numSparks = math.floor( math.random() * 50 )
   local numPillars = math.floor( math.random() * 50 )
   local numRings = math.floor( math.random() * 50 )
   local numSpirals = math.floor( math.random() * 50 )
   local numFragments = math.floor( math.random() * 50 )
   local numGlitters = math.floor( math.random() * 50 )
   local offset = 2000

   local objects = {}

   objects = util.tableJoin( objects,
      world.makeStuff( "spark.cfg", numSparks, offset, x, y, z ) ) 
   objects = util.tableJoin( objects,
      world.makeStuff( "pillar.cfg", numPillars, offset, x, y, z ) )

   objects = util.tableJoin( objects,
      world.makeStuff( "ring.cfg", numRings, offset, x, y, z ) )
   objects = util.tableJoin( objects,
      world.makeStuff( "spiral.cfg", numSpirals, offset, x, y, z ) )

   objects = util.tableJoin( objects,
      world.makeStuff( "fragment.cfg", numFragments, offset, x, y, z ) )
   objects = util.tableJoin( objects,
      world.makeStuff( "glitter.cfg", numGlitters, offset, x, y, z ) )

   local stella = world.newObject( "stella.cfg", x, y, z )
   table.insert( objects, stella )
   return objects
end

function world.makeWorld()
   --return objects
   local s1 = world.makeStella( 0, 0, 0 )
   s1 = util.tableJoin( s1, world.makeStella( 1000, 0, 0 ) )
   s1 = util.tableJoin( s1, world.makeStella( 3000, 1100, 964 ) )
   return s1

end

-- Uncommenting these mysteriously makes textures stop working.
-- You got me.
-- I'm not really in a state to think about this too much longer, I think.
--
--world.stella = gameobj.new( "stella.cfg" )
--world.gasfield = gameobj.new( "gasfield.cfg" )
--world.rock = gameobj.new( "rock.cfg" )

--function world.stella.new( density )
   --self.density = density
   --self.scale = density / 100
--end

--function world.gasfield.new( density )
   --self.density = density
   --self.scale = density / 10
--end

--function world.rock.new( density )
--   self.density = density
--   self.scale = density / 1000
--end


module( "world" )
