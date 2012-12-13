-- A generic resource system designed to ensure that things are only
-- loaded once.
-- Basically, you give it a loader function, and get a 'resource' object
-- back.  You can give it a filename, and it will either return the object
-- with that name, or load it if it doesn't exist and then return it.


require( "config" )
require( "mesh" )
require( "wanderer.misc" )

resource = {}

resource.DATADIR = "data/"
resource.CONFDIR = resource.DATADIR .. "configs/"
resource.MESHDIR = resource.DATADIR .. "meshes/"
resource.TEXDIR = resource.DATADIR .. "textures/"


-- I <3 closures
-- This is cute, 'cause you can't do a.get( "get" ) and have it overwrite
-- itself, because it already exists.  Huzzah!
function resource.newLoader( loaderfunc, path )
   local t = {}
   t.path = path

   function t:get( key )
      local fullpath = t.path .. key
      local x = t[fullpath]
      if x == nil then
         --print( "Loading " .. fullpath )
         x = loaderfunc( fullpath )
         t[fullpath] = x
      end
      return x
   end 

   return t
end

resource.texLoader = resource.newLoader( misc.loadTexture, resource.TEXDIR )
resource.meshLoader = resource.newLoader( mesh.loadObj, resource.MESHDIR )
resource.confLoader = resource.newLoader( config.loadConfig, resource.CONFDIR )

module( "resource" )
