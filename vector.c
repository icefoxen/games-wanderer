/* Yay, vectors!
 * Let's see how we can actually expose a C datatype directly to Lua.
 * Where possible, all the modification is done in place.
 * Interface:
 * v = vector.new( x, y, z )
 * v:x
 * v:y
 * v:z
 * v:x,y,z = something
 * v:add
 * v:sub
 * v:mul
 * v:div
 * v:magnitude
 * v:normalize
 * v:dot
 * v:cross
 * v:copy
 */

#include <math.h>
#include <string.h>
#include "common.h"

#define MT_NAME "array"

typedef struct {
   double x;
   double y;
   double z;
} vector;


static int newVector( lua_State* L ) {
   double x = (double) luaL_checknumber( L, 1 );
   double y = (double) luaL_checknumber( L, 2 );
   double z = (double) luaL_checknumber( L, 3 );

   vector* v = (vector*) lua_newuserdata( L, sizeof( vector ) );
   // Set the metatable on the newly created userdata.
   luaL_getmetatable( L, MT_NAME );
   lua_setmetatable( L, -2 );

   v->x = x;
   v->y = y;
   v->z = z;

   return 1;
}

// Function to safely pull a vector off the Lua stack
static vector* checkvector( lua_State* L, int idx ) {
   void* userdat = luaL_checkudata( L, idx, MT_NAME );
   luaL_argcheck( L, userdat != NULL, 1, "'vector' expected" );
   return (vector*) userdat;
}

static int vector2string( lua_State* L ) {
   vector* v = checkvector( L, 1 );
   lua_pushfstring( L, "vector( %f, %f, %f )", v->x, v->y, v->z );
   return 1;
}

static int getVectorItem( lua_State* L ) {
   vector* v = checkvector( L, 1 );
   const char* s = luaL_checkstring( L, 2 );
   if( strncmp( "x", s, 1 ) == 0 ) {
      lua_pushnumber( L, v->x );
   } else if( strncmp( "y", s, 1 ) == 0 ) {
      lua_pushnumber( L, v->y );
   } else if( strncmp( "z", s, 1 ) == 0 ) {
      lua_pushnumber( L, v->z );
   } else {
      // OMG IT WORKS
      lua_getmetatable( L, 1 );
      lua_insert( L, 2 );  // ( v s mt - v mt s )
      lua_gettable( L, 2 );
   }
   return 1; 
}

static int setVectorItem( lua_State* L ) {
   vector* v = checkvector( L, 1 );
   const char* s = luaL_checkstring( L, 2 );
   double i = luaL_checknumber( L, 3 );
   if( strncmp( "x", s, 1 ) == 0 ) {
      v->x = i;
   } else if( strncmp( "y", s, 1 ) == 0 ) {
      v->y = i;
   } else if( strncmp( "z", s, 1 ) == 0 ) {
      v->z = i;
   } else {
      luaL_error( L, "Tried to set invalid field for vector: %s", s );
   }
   return 0; 
}


static int magnitude( lua_State* L ) {
   vector* v = checkvector( L, 1 );
   double d = sqrt( (v->x * v->x) + (v->y * v->y) + (v->z * v->z) );
   lua_pushnumber( L, d );
   return 1;
}

static int relativeMagnitude( lua_State* L ) {
   vector* v = checkvector( L, 1 );
   double d = (v->x * v->x) + (v->y * v->y) + (v->z * v->z);
   lua_pushnumber( L, d );
   return 1;
}

static int add( lua_State* L ) {
   vector* v1 = checkvector( L, 1 );
   vector* v2 = checkvector( L, 2 );
   v1->x += v2->x;
   v1->y += v2->y;
   v1->z += v2->z;
   return 0;
}

static int sub( lua_State* L ) {
   vector* v1 = checkvector( L, 1 );
   vector* v2 = checkvector( L, 2 );
   v1->x -= v2->x;
   v1->y -= v2->y;
   v1->z -= v2->z;
   return 0;
}

static int mul( lua_State* L ) {
   vector* v = checkvector( L, 1 );
   double n = luaL_checknumber( L, 2 );
   v->x *= n;
   v->y *= n;
   v->z *= n;
   return 0;
}

static int div( lua_State* L ) {
   vector* v = checkvector( L, 1 );
   double n = luaL_checknumber( L, 2 );
   v->x /= n;
   v->y /= n;
   v->z /= n;
   return 0;
}

static int normalize( lua_State* L ) {
   vector* v = checkvector( L, 1 );
   double d = sqrt( (v->x * v->x) + (v->y * v->y) + (v->z * v->z) );
   v->x = v->x / d;
   v->y = v->y / d;
   v->z = v->z / d;
   return 0;
}

static int copy( lua_State* L ) {
   vector* v = checkvector( L, 1 );
   lua_pop( L, 1 );
   lua_pushnumber( L, v->x );
   lua_pushnumber( L, v->y );
   lua_pushnumber( L, v->z );
   return newVector( L );
}

static int dot( lua_State* L ) {
   vector* v1 = checkvector( L, 1 );
   vector* v2 = checkvector( L, 2 );
   double d = (v1->x * v2->x) + (v1->y * v2->y) + (v1->z * v2->z);
   lua_pushnumber( L, d );
   return 1;
}

// I THINK this is right.
// I also don't think I ever use it...
/*
static void cross( vector* v1, vector* v2, vector* res ) {
   double a = 0;
   double b = 0;
   double c = 0;
   a =   (v1->y * v2->z) - (v1->z * v2->y);
   b = -((v1->x * v2->z) - (v1->z * v2->x));
   c =   (v1->x * v2->y) - (v1->y * v2->x);
   res->x = a;
   res->y = b;
   res->z = c; 
}
*/


static const struct luaL_reg vectorlib[] = {
   {"new", newVector},
   {NULL, NULL}
};

static void setMetatables( lua_State* L ) { 
   luaL_newmetatable( L, MT_NAME ); 

   lua_pushstring( L, "__index" );
   lua_pushcfunction( L, getVectorItem );
   lua_rawset( L, -3 );  // metatable.__index = getVectorItem

   lua_pushstring( L, "__newindex" );
   lua_pushcfunction( L, setVectorItem );
   lua_rawset( L, -3 );

   lua_pushstring( L, "__tostring" );
   lua_pushcfunction( L, vector2string );
   lua_rawset( L, -3 );

   lua_pushstring( L, "magnitude" );
   lua_pushcfunction( L, magnitude );
   lua_rawset( L, -3 );

   lua_pushstring( L, "relativeMagnitude" );
   lua_pushcfunction( L, relativeMagnitude );
   lua_rawset( L, -3 );

   lua_pushstring( L, "add" );
   lua_pushcfunction( L, add );
   lua_rawset( L, -3 );

   lua_pushstring( L, "sub" );
   lua_pushcfunction( L, sub );
   lua_rawset( L, -3 );

   lua_pushstring( L, "mul" );
   lua_pushcfunction( L, mul );
   lua_rawset( L, -3 );

   lua_pushstring( L, "div" );
   lua_pushcfunction( L, div );
   lua_rawset( L, -3 );

   lua_pushstring( L, "dot" );
   lua_pushcfunction( L, dot );
   lua_rawset( L, -3 );

   lua_pushstring( L, "copy" );
   lua_pushcfunction( L, copy );
   lua_rawset( L, -3 );

   lua_pushstring( L, "normalize" );
   lua_pushcfunction( L, normalize );
   lua_rawset( L, -3 );
}

int luaopen_wanderer_vector( lua_State* L ) {
   setMetatables( L ); 
   luaL_register( L, "vector", vectorlib );
   return 1;
}
