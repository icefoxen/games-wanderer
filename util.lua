util = {}

function util.printTable( t )
   for x, y in pairs( t ) do
      print( x, y )
   end
end

function util.d2r( degrees )
   return (degrees / 180) * math.pi
end

-- Sigh.
function util.tableJoin( t1, t2 )
   local new = {}
   for unused, itm in pairs( t1 ) do
      table.insert( new, itm )
   end
   for unused, itm in pairs( t2 ) do
      table.insert( new, itm )
   end
   return new
end



module( "util" )
