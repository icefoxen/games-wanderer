#!/usr/bin/env lua
-- A mostly conceptual, at this moment, outline of what the program should
-- look like on the Lua side of things.

require( "wanderer.misc" )
require( "sdlk" )
require( "resource" )
require( "gameobj" )
require( "driver" )
--require( "util" )


function main()
   graphicconf = resource.confLoader:get( "graphics.cfg" )
   misc.initGraphics( graphicconf.x, graphicconf.y, graphicconf.bpp )

   local d = driver.new()
   -- Catch Lua errors, so that SDL doesn't segfault when they happen.  :-P
   local res, errormessage = pcall( d.doMainloop, d )
   if not res then
      print( "Some error happened:" )
      print( errormessage )
   end

   misc.quitGraphics()
end

main()
