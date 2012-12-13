-- So technically, anything could be written as just as script.
-- Practically, I want some system to help keep thigns consistant,
-- and not pollute the namespace too much.
-- Now... how to do that?  I dunno yet.
--
-- Aha.  I know now.  loadfile().

-- Each config file is just a statement that *returns* a table full of
-- config values.  Hah.

config = {}

function config.loadConfig( filename )
   local fn = filename
   --print( "Loading config file " .. fn )
   local chunk = loadfile( fn )
   assert( chunk, "Empty or invalid config file: " .. fn )
   return chunk()
end

module( "config" )
