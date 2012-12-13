-- .obj mesh loader

require( "wanderer.cmesh" )

mesh = {}

function mesh.makeVertex( x, y, z )
   return {x, y, z}
end

function mesh.makeNormal( x, y, z )
   return {x, y, z }
end

function mesh.makeUV( u, v )
   return {u, v}
end

function mesh.makeFacePart( v, u, n )
   return {v, u, n}
end

mesh.numregex = "%-?%d+%.%d+e?-?%d*"

function mesh.parsenum( x )
   local n = tonumber( x )
   if n == nil then
      --print( "Fudging", x )
      return 0
   end
   return n
end

function mesh.parseVertex( line )
   local iter = string.gmatch( line, mesh.numregex )
   local x = mesh.parsenum( iter() )
   local y = mesh.parsenum( iter() )
   local z = mesh.parsenum( iter() )
   --print( "Vertex:", x, y, z )
   return mesh.makeVertex( x, y, z )
end

function mesh.parseNormal( line )
   local iter = string.gmatch( line, mesh.numregex )
   local x = mesh.parsenum( iter() )
   local y = mesh.parsenum( iter() )
   local z = mesh.parsenum( iter() )
   --print( "Normal:", x, y, z )
   return mesh.makeNormal( x, y, z )
end

function mesh.parseUV( line )
   local iter = string.gmatch( line, mesh.numregex )
   local u = mesh.parsenum( iter() )
   local v = mesh.parsenum( iter() )
   --print( "UV:", u, v )
   return mesh.makeUV( u, 1 - v )
end


function mesh.parseFace( line )
   local regex = "(%d+)/(%d*)/(%d*)"
   local face = {}
   for v, u, n in string.gmatch( line, regex ) do
      --print( "Face:", v, u, n )
      table.insert( face, {mesh.parsenum( v ), mesh.parsenum( u ), mesh.parsenum( n )} )
   end
   if #face ~= 3 then
      error( "All faces in .obj file must be triangles!" );
   end
   return face
end

-- ...wow.  This is so much nicer in Lua...
-- 'Cause it's string handling isn't ENTIRELY crap.
function mesh.loadObj( filename )
   local file = io.open( filename )
   assert( file, "File not found: " .. filename )
   local m = {}
   m.vertices = {}
   m.uvs = {}
   m.normals = {}
   m.faces = {}
   for line in file:lines() do
      if string.find( line, "v ", 0, true ) then
         table.insert( m.vertices, mesh.parseVertex( line ) )
      elseif string.find( line, "vn ", 0, true ) then
         table.insert( m.normals, mesh.parseNormal( line ) )
      elseif string.find( line, "vt ", 0, true ) then
         table.insert( m.uvs, mesh.parseUV( line ) )
      elseif string.find( line, "f ", 0, true ) then
         table.insert( m.faces, mesh.parseFace( line ) )
      end
   end
   file:close()

   local f = {}
   for i, x in pairs( m.vertices ) do
      f[#m.vertices - i] = x
   end

   local s = string.format( "Mesh %s loaded.\n\t%d vertices, %d normals, %d UVs, %d faces.", filename, #m.vertices, #m.normals, #m.uvs, #m.faces );
   print( s )

   -- Now we load the mesh into C
   local cm = cmesh.new( #m.vertices, #m.normals, #m.uvs, #m.faces )
   for i,v in pairs( m.vertices ) do
      cm:addVertex( i-1, v[1], v[2], v[3] )
   end
   for i,n in pairs( m.normals ) do
      cm:addNormal( i-1, n[1], n[2], n[3] )
   end
   for i,u in pairs( m.uvs ) do
      cm:addUV( i-1, u[1], u[2] )
   end
   for i,f in pairs( m.faces ) do
      cm:addFace( i-1, f[1][1], f[1][2], f[1][3], f[2][1], f[2][2], f[2][3],
      f[3][1], f[3][2], f[3][3] )
   end

   -- Are we using display lists?  :-P
   -- Probably not.
   --if cm.initMesh then
   --   cm:initMesh()
   --end

   return cm
end


module( "mesh" )
