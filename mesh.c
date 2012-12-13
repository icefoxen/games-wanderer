// XXX: These functions are a bit brittle in terms of argument checking.
#include "common.h"
#include <malloc.h>
#include <GL/gl.h>
#include <GL/glu.h>

#define MT_NAME "cmesh"

typedef struct {
   double x;
   double y;
   double z;
} vertex;

typedef struct {
   double x;
   double y;
   double z;
} normal;

typedef struct {
   double u;
   double v;
} uv;

typedef struct {
   int vertex;
   int uv;
   int normal;
} faceSegment;

typedef faceSegment face[3];

typedef struct {
   int nVertices;
   int nUvs;
   int nNormals;
   int nFaces;
   vertex* vertices;
   normal* normals;
   uv* uvs;
   face* faces;
} mesh;

static int newMesh( lua_State* L ) {
   int nv = luaL_checkint( L, 1 );
   int nn = luaL_checkint( L, 2 );
   int nuv = luaL_checkint( L, 3 );
   int nf = luaL_checkint( L, 4 ); 
   mesh* m = (mesh*) lua_newuserdata( L, sizeof( mesh ) );
   m->nVertices = nv;
   m->nNormals = nn;
   m->nUvs = nuv;
   m->nFaces = nf;

   m->vertices = (vertex*) malloc( sizeof( vertex ) * m->nVertices );
   m->uvs = (uv*) malloc( sizeof( uv ) * m->nUvs );
   m->normals = (normal*) malloc( sizeof( normal ) * m->nNormals );
   m->faces = (face*) malloc( sizeof( face ) * m->nFaces );

   luaL_getmetatable( L, MT_NAME );
   lua_setmetatable( L, -2 );

   return 1;
}

static mesh* checkmesh( lua_State* L, int idx ) {
   void* userdat = (void*) luaL_checkudata( L, idx, MT_NAME );
   luaL_argcheck( L, userdat != NULL, 1, "'mesh' expected" );
   return (mesh*) userdat;
}


static int freeMesh( lua_State* L ) {
   mesh* m = checkmesh( L, 1 );
   free( m->vertices );
   free( m->uvs );
   free( m->normals );
   free( m->faces );
   return 0;
}

static int addVertex( lua_State* L ) {
   mesh* m = checkmesh( L, 1 );
   int i = luaL_checkint( L, 2 );
   if( i >= m->nVertices ) {
      luaL_error( L, "Too many vertices in mesh!" );
   }
   m->vertices[i].x = luaL_checknumber( L, 3 );
   m->vertices[i].y = luaL_checknumber( L, 4 );
   m->vertices[i].z = luaL_checknumber( L, 5 );
   return 0;
}

static int addUV( lua_State* L ) {
   mesh* m = checkmesh( L, 1 );
   int i = luaL_checkint( L, 2 );
   if( i >= m->nUvs ) {
      printf( "%d, %d\n", i, m->nUvs );
      luaL_error( L, "Too many UV's in mesh!" );
   }
   m->uvs[i].u = luaL_checknumber( L, 3 );
   m->uvs[i].v = luaL_checknumber( L, 4 );
   return 0;
}

static int addNormal( lua_State* L ) {
   mesh* m = checkmesh( L, 1 );
   int i = luaL_checkint( L, 2 );
   if( i >= m->nNormals ) {
      printf( "%d, %d\n", i, m->nNormals );
      luaL_error( L, "Too many normals in mesh!" );
   }
   m->normals[i].x = luaL_checknumber( L, 3 );
   m->normals[i].y = luaL_checknumber( L, 4 );
   m->normals[i].z = luaL_checknumber( L, 5 );
   return 0;
}

static int addFace( lua_State* L ) {
   mesh* m = checkmesh( L, 1 );
   int i = luaL_checkint( L, 2 );
   if( i >= m->nFaces ) {
      luaL_error( L, "Too many faces in mesh!" );
   }
   m->faces[i][0].vertex = luaL_checkint( L, 3 );
   m->faces[i][0].uv = luaL_checkint( L, 4 );
   m->faces[i][0].normal = luaL_checkint( L, 5 );

   m->faces[i][1].vertex = luaL_checkint( L, 6 );
   m->faces[i][1].uv = luaL_checkint( L, 7 );
   m->faces[i][1].normal = luaL_checkint( L, 8 );

   m->faces[i][2].vertex = luaL_checkint( L, 9 );
   m->faces[i][2].uv = luaL_checkint( L, 10 );
   m->faces[i][2].normal = luaL_checkint( L, 11 );
   return 0;
}

static int numFaces( lua_State *L ) {
   mesh* m = checkmesh( L, 1 );
   lua_pushinteger( L, m->nFaces );
   return 1;
}

// I bloody hate pointers.
static void drawFace( mesh* m, int n ) {
   face* f = &m->faces[n];
   int vi = 0;
   int ui = 0;
   int ni = 0;
   vertex* vert;
   uv* uv;
   normal* norm;
   int i = 0;

   for( i = 0; i < 3; i++ ) {
      vi = (*f)[i].vertex - 1;
      ui = (*f)[i].uv - 1;
      ni = (*f)[i].normal - 1;
      //printf( "Drawing point %d %d: %d %d %d\n", n, i, vi, ui, ni );
      vert = &m->vertices[vi];
      uv = &m->uvs[ui];
      norm = &m->normals[ni];

      //printf( "Drawing face %d, vertex %d: %f, %f, %f\n", n, vi, vert->x, vert->y, vert->z );

      glNormal3d( norm->x, norm->y, norm->z );
      glTexCoord2d( uv->u, uv->v );
      //printf( "Face %d, vert %d: %f, %f, %f\n", n, i, vert->x, vert->y, vert->z );
      glVertex3d( vert->x, vert->y, vert->z );
   }
}

// Takes four arguments: a mesh, pos vector, angle, and rotation vector
// Most of the trouble here is getting the arguments out of the vectors.  :-P
// One COULD just treat them as actual C vector datatypes, from vector.c...
// But then you couldn't just pass in Lua tables with the appropriate
// x, y, and z values set.  Whee!

// XXX: Check for presence of tables
static int drawMesh( lua_State* L ) {
   mesh* m = checkmesh( L, 1 );
   lua_pushstring( L, "x" );
   lua_gettable( L, 2 );
   lua_pushstring( L, "y" );
   lua_gettable( L, 2 );
   lua_pushstring( L, "z" );
   lua_gettable( L, 2 );
   double x = luaL_checknumber( L, -3 );
   double y = luaL_checknumber( L, -2 );
   double z = luaL_checknumber( L, -1 );
   lua_pop( L, 3 );

   double angle = luaL_checknumber( L, 3 );

   lua_pushstring( L, "x" );
   lua_gettable( L, 4 );
   lua_pushstring( L, "y" );
   lua_gettable( L, 4 );
   lua_pushstring( L, "z" );
   lua_gettable( L, 4 );

   double rx = luaL_checknumber( L, -3 );
   double ry = luaL_checknumber( L, -2 );
   double rz = luaL_checknumber( L, -1 );
   lua_pop( L, 3 );

   double scale = luaL_checknumber( L, 5 );

   int i = 0;
   glPushMatrix();
   glTranslated( x, y, z );
   glRotated( angle, rx, ry, rz );
   glScaled( scale, scale, scale );

   glBegin( GL_TRIANGLES ); 
   for( i = 0; i < m->nFaces; i++ ) {
      drawFace( m, i );
   }
   glEnd(); 

   glPopMatrix();

   return 0;
}

static const struct luaL_reg meshlib[] = {
   {"new", newMesh},
   {NULL, NULL}
};


static void setMetatables( lua_State* L ) {
   luaL_newmetatable( L, MT_NAME );

   lua_pushstring( L, "__index" );
   lua_pushvalue( L, -2 );
   lua_rawset( L, -3 );

   lua_pushstring( L, "addVertex" );
   lua_pushcfunction( L, addVertex );
   lua_rawset( L, -3 );

   lua_pushstring( L, "addUV" );
   lua_pushcfunction( L, addUV );
   lua_rawset( L, -3 );

   lua_pushstring( L, "addNormal" );
   lua_pushcfunction( L, addNormal );
   lua_rawset( L, -3 );

   lua_pushstring( L, "addFace" );
   lua_pushcfunction( L, addFace );
   lua_rawset( L, -3 ); 

   lua_pushstring( L, "numFaces" );
   lua_pushcfunction( L, numFaces );
   lua_rawset( L, -3 ); 

   lua_pushstring( L, "draw" );
   lua_pushcfunction( L, drawMesh );
   lua_rawset( L, -3 );

   lua_pushstring( L, "__gc" );
   lua_pushcfunction( L, freeMesh );
   lua_rawset( L, -3 );

   lua_pop( L, 1 );
}

int luaopen_wanderer_cmesh( lua_State* L ) {
   setMetatables( L );
   luaL_register( L, "cmesh", meshlib );
   return 1;
}
