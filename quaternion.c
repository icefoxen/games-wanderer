// To understand how this works, look at vector.c first.
// At least, the C <-> Lua parts of it.  The math is still a mystery to everyone.
// :-P
#include "common.h"
#include <math.h>
#include <string.h>

#define MT_NAME "quaternion"

typedef struct {
   double w;
   double x;
   double y;
   double z;
} quaternion;

static int newQuaternion( lua_State* L ) {
   quaternion* q = (quaternion*) lua_newuserdata( L, sizeof( quaternion ) );
   luaL_getmetatable( L, MT_NAME );
   lua_setmetatable( L, -2 );

   q->w = 1;
   q->x = 0;
   q->y = 0;
   q->z = 0;

   return 1;
}

static quaternion* checkquaternion( lua_State* L, int idx ) {
   void* userdat = luaL_checkudata( L, idx, MT_NAME );
   luaL_argcheck( L, userdat != NULL, 1, "'quaternion' expected" );
   return (quaternion*) userdat;

}

static int quaternion2string( lua_State* L ) {
   quaternion* q = checkquaternion( L, 1 );
   lua_pushfstring( L, "quaternion( %f, %f, %f, %f )", q->w, q->x, q->y, q->z );
   return 1;
}

static int getItem( lua_State* L ) {
   quaternion* q = checkquaternion( L, 1 );
   const char* s = luaL_checkstring( L, 2 );
   if( strncmp( "w", s, 1 ) == 0 ) {
      lua_pushnumber( L, q->w );
   } else if( strncmp( "x", s, 1 ) == 0 ) {
      lua_pushnumber( L, q->x );
   } else if( strncmp( "y", s, 1 ) == 0 ) {
      lua_pushnumber( L, q->y );
   } else if( strncmp( "z", s, 1 ) == 0 ) {
      lua_pushnumber( L, q->z );
   } else {
      lua_getmetatable( L, 1 );
      lua_insert( L, 2 );
      lua_gettable( L, 2 );
   }
   return 1; 
}

static int setItem( lua_State* L ) {
   quaternion* q = checkquaternion( L, 1 );
   const char* s = luaL_checkstring( L, 2 );
   double i = luaL_checknumber( L, 3 );
   if( strncmp( "w", s, 1 ) == 0 ) {
      q->w = i;
   } else if( strncmp( "x", s, 1 ) == 0 ) {
      q->x = i;
   } else if( strncmp( "y", s, 1 ) == 0 ) {
      q->y = i;
   } else if( strncmp( "z", s, 1 ) == 0 ) {
      q->z = i;
   } else {
      luaL_error( L, "Tried to set invalid field for quaternion: %s", s );
   }
   return 0; 
}

static int magnitude( lua_State* L ) {
   quaternion* q = checkquaternion( L, 1 );
   double d = sqrt( (q->w * q->w) + (q->x * q->x) + 
         (q->y * q->y) + (q->z * q->z ) );
   lua_pushnumber( L, d );
   return 1;
}

static int normalize( lua_State* L ) {
   magnitude( L );
   quaternion* q = checkquaternion( L, 1 );
   double mag = luaL_checknumber( L, 2 );
   q->w = q->w / mag;
   q->x = q->x / mag;
   q->y = q->y / mag;
   q->z = q->z / mag; 
   return 0;
}

static int set( lua_State* L ) {
   quaternion* q = checkquaternion( L, 1 );
   q->w = luaL_checknumber( L, 2 );
   q->x = luaL_checknumber( L, 3 );
   q->y = luaL_checknumber( L, 4 );
   q->z = luaL_checknumber( L, 5 );
   return 0;
}

static int copy( lua_State* L ) {
   quaternion* q = checkquaternion( L, 1 );
   lua_pushnumber( L, q->w );
   lua_pushnumber( L, q->x );
   lua_pushnumber( L, q->y );
   lua_pushnumber( L, q->z );
   return newQuaternion( L );
}

static int mul( lua_State* L ) {
   quaternion* q1 = checkquaternion( L, 1 );
   quaternion* q2 = checkquaternion( L, 2 );
   q1->w = (q1->w * q2->w) - (q1->x * q2->x) - (q1->y * q2->y) - (q1->z * q2->z);
   q1->x = (q1->w * q2->x) + (q1->x * q2->w) + (q1->y * q2->z) - (q1->z * q2->y);
   q1->y = (q1->w * q2->y) - (q1->x * q2->z) + (q1->y * q2->w) + (q1->z * q2->x);
   q1->z = (q1->w * q2->z) + (q1->x * q2->y) - (q1->y * q2->x) + (q1->z * q2->w);
   return 0;
}

static int fromAxis( lua_State* L ) {
   quaternion* q = checkquaternion( L, 1 );
   double angle = luaL_checknumber( L, 2 );
   double x = luaL_checknumber( L, 3 );
   double y = luaL_checknumber( L, 4 );
   double z = luaL_checknumber( L, 5 );
   double s = sin( angle / 2 );
   q->w = cos( angle / 2 );
   q->x = x * s;
   q->y = y * s;
   q->z = z * s;
   return 0;
}

// Returns 4 numbers: the angle, and the x, y, and z of the vector/axis
static int toAxis( lua_State* L ) {
   quaternion* q = checkquaternion( L, 1 );
   double scale = sqrt( (q->x * q->x) + (q->y * q->y) + (q->z * q->z) );
   if( scale == 0 ) {
      lua_pushnumber( L, 0 );

      lua_createtable( L, 3, 0 );

      lua_pushstring( L, "x" ); 
      lua_pushnumber( L, 1 );
      lua_settable( L, -3 );

      lua_pushstring( L, "y" ); 
      lua_pushnumber( L, 1 );
      lua_settable( L, -3 );

      lua_pushstring( L, "z" ); 
      lua_pushnumber( L, 1 );
      lua_settable( L, -3 );
   } else {
      // w cannot be > 1, but occasionally is due to floating point error
      if( q->w > 1 ) q->w = 1;

      double vx = q->x*scale;
      double vy = q->y*scale;
      double vz = q->z*scale;
      // C uses radians, opengl uses degrees
      // From this it is obvious that C was made by math people, and OpenGL by
      // engineers/physicists.
      double angle = (2 * acos( q->w )) * (180.0 / M_PI);
      lua_pushnumber( L, angle );

      //lua_createtable( L, 3, 0 );
      lua_newtable( L );

      lua_pushstring( L, "x" );
      lua_pushnumber( L, vx );
      lua_settable( L, -3 );

      lua_pushstring( L, "y" );
      lua_pushnumber( L, vy );
      lua_settable( L, -3 );

      lua_pushstring( L, "z" );
      lua_pushnumber( L, vz );
      lua_settable( L, -3 );
   } 
   return 2;
}


// Returns 3 Lua tables with x, y, and z values, as rows of a matrix.
// | x1 y1 z1 |
// | x2 y2 z2 |
// | x3 y3 z3 |
// -> {x1, y1, z1}, {x2, y2, z2}, {x3, y3, z3}
// I could use vectors, but life is easier when C doesn't touch other C...
static int toMatrix( lua_State* L ) {
   quaternion* q = checkquaternion( L, 1 );
   double x1, y1, z1, x2, y2, z2, x3, y3, z3 = 0.0;

   double xx = q->x * q->x;
   double xy = q->x * q->y;
   double xz = q->x * q->z;
   double xw = q->x * q->w;

   double yy = q->y * q->y;
   double yz = q->y * q->z;
   double yw = q->y * q->w;

   double zz = q->z * q->z;
   double zw = q->z * q->w;

   x1 = 1 - (2 * (yy + zz));
   x2 =     (2 * (xy - zw));
   x3 =     (2 * (xz + yw));

   y1 =     (2 * (xy + zw));
   y2 = 1 - (2 * (xx + zz));
   y3 =     (2 * (yz - xw));

   z1 =     (2 * (xz - yw));
   z2 =     (2 * (yz + xw));
   z3 = 1 - (2 * (xx + yy));

   lua_createtable( L, 3, 0 );
   lua_pushstring( L, "x" ); 
   lua_pushnumber( L, x1 );
   lua_settable( L, -3 );

   lua_pushstring( L, "y" ); 
   lua_pushnumber( L, y1 );
   lua_settable( L, -3 );

   lua_pushstring( L, "z" ); 
   lua_pushnumber( L, z1 );
   lua_settable( L, -3 );

   lua_createtable( L, 3, 0 );
   lua_pushstring( L, "x" ); 
   lua_pushnumber( L, x2 );
   lua_settable( L, -3 );

   lua_pushstring( L, "y" ); 
   lua_pushnumber( L, y2 );
   lua_settable( L, -3 );

   lua_pushstring( L, "z" ); 
   lua_pushnumber( L, z2 );
   lua_settable( L, -3 );

   lua_createtable( L, 3, 0 );
   lua_pushstring( L, "x" ); 
   lua_pushnumber( L, x3 );
   lua_settable( L, -3 );

   lua_pushstring( L, "y" ); 
   lua_pushnumber( L, y3 );
   lua_settable( L, -3 );

   lua_pushstring( L, "z" ); 
   lua_pushnumber( L, z3 );
   lua_settable( L, -3 );

   return 3; 
}

static const struct luaL_reg quaternionlib[] = {
   {"new", newQuaternion},
   {NULL, NULL}
};

static void setMetatables( lua_State* L ) { 
   luaL_newmetatable( L, MT_NAME ); 

   lua_pushstring( L, "__index" );
   lua_pushcfunction( L, getItem );
   lua_rawset( L, -3 );

   lua_pushstring( L, "__newindex" );
   lua_pushcfunction( L, setItem );
   lua_rawset( L, -3 );

   lua_pushstring( L, "__tostring" );
   lua_pushcfunction( L, quaternion2string );
   lua_rawset( L, -3 );

   lua_pushstring( L, "magnitude" );
   lua_pushcfunction( L, magnitude );
   lua_rawset( L, -3 );

   lua_pushstring( L, "normalize" );
   lua_pushcfunction( L, normalize );
   lua_rawset( L, -3 );

   lua_pushstring( L, "set" );
   lua_pushcfunction( L, set );
   lua_rawset( L, -3 );

   lua_pushstring( L, "copy" );
   lua_pushcfunction( L, copy );
   lua_rawset( L, -3 );

   lua_pushstring( L, "mul" );
   lua_pushcfunction( L, mul );
   lua_rawset( L, -3 );

   lua_pushstring( L, "fromAxis" );
   lua_pushcfunction( L, fromAxis );
   lua_rawset( L, -3 );

   lua_pushstring( L, "toAxis" );
   lua_pushcfunction( L, toAxis );
   lua_rawset( L, -3 );

   lua_pushstring( L, "toMatrix" );
   lua_pushcfunction( L, toMatrix );
   lua_rawset( L, -3 );
}


int luaopen_wanderer_quaternion( lua_State* L ) {
   setMetatables( L ); 
   luaL_register( L, "quaternion", quaternionlib );
   return 1;
}

