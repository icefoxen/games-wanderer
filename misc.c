#include "common.h"
#include <SDL.h>
#include <SDL_image.h>
#include <SDL_ttf.h>
#include <GL/gl.h>
#include <GL/glu.h>

// GRAPHICS //

static SDL_Surface* screen;

// We hang onto the lua_State* for error-doing.
static void initSDL( lua_State* L, int x, int y, int bpp ) {
   int flags = SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_OPENGL; 

   printf( "***Initializing SDL... " ); 

   SDL_Init( SDL_INIT_EVERYTHING );
   if( TTF_Init() == -1 ) {
      printf( "SDL: TTF_Init: %s\n", TTF_GetError() );
      luaL_error( L, "Could not initialize TTF" );
   }

   screen = SDL_SetVideoMode( x, y, bpp, flags );
   if( screen == NULL ) {
      luaL_error( L, "Could not set video mode" );
   }
   printf( "Done\n" );
}

/* Doesn't work.
static int putText( lua_State* L ) {
   const char* str = luaL_checkstring( L, 1 );
   //int x = luaL_checkint( L, 2 );
   //int y = luaL_checkint( L, 3 );
   SDL_Surface* text_surface = NULL;
   SDL_Color color;
   TTF_Font* font = TTF_OpenFont( "data/Arial.ttf", 32 );
   // XXX: Error checking for font existance

   color.r = 128;
   color.g = 128;
   color.b = 128;

   if( !(text_surface = TTF_RenderText_Solid( font, str, color )) ) {
      luaL_error( L, "Could not render text" );
   } else {
      SDL_BlitSurface(text_surface,NULL,screen,NULL);
      SDL_FreeSurface(text_surface);
   } 
   TTF_CloseFont( font );

   return 0;
}
*/

static GLfloat aspect = 0;

static int initGL( int x, int y ) {
   glEnable( GL_TEXTURE_2D );
   aspect = (GLfloat) x / (GLfloat) y;
   glShadeModel( GL_SMOOTH );
   glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );
   glClearDepth( 1.0f );
   glEnable( GL_DEPTH_TEST );
   glDepthFunc( GL_LEQUAL );
   glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );


   glViewport( 0, 0, x, y );

   return 0;
}

static int initGraphics( lua_State* L ) {
   int x = luaL_checkint( L, 1 );
   int y = luaL_checkint( L, 2 );
   int bpp = luaL_checkint( L, 3 );

   initSDL( L, x, y, bpp );
   initGL( x, y ); 

   return 0;
}

static int quitGraphics( lua_State* L ) {
   printf( "Quitting SDL... " );
   SDL_Quit();
   printf( "Done\n" );
   return 0;
}

static int startFrame( lua_State* L ) {
   // Get "eye" vector
   lua_pushstring( L, "x" );
   lua_gettable( L, 1 );
   double ex = luaL_checknumber( L, -1 );
   lua_pushstring( L, "y" );
   lua_gettable( L, 1 );
   double ey = luaL_checknumber( L, -1 );
   lua_pushstring( L, "z" );
   lua_gettable( L, 1 );
   double ez = luaL_checknumber( L, -1 );

   // Get "center" vector
   lua_pushstring( L, "x" );
   lua_gettable( L, 2 );
   double cx = luaL_checknumber( L, -1 );
   lua_pushstring( L, "y" );
   lua_gettable( L, 2 );
   double cy = luaL_checknumber( L, -1 );
   lua_pushstring( L, "z" );
   lua_gettable( L, 2 );
   double cz = luaL_checknumber( L, -1 );

   // Get "up" vector
   lua_pushstring( L, "x" );
   lua_gettable( L, 3 );
   double ux = luaL_checknumber( L, -1 );
   lua_pushstring( L, "y" );
   lua_gettable( L, 3 );
   double uy = luaL_checknumber( L, -1 );
   lua_pushstring( L, "z" );
   lua_gettable( L, 3 );
   double uz = luaL_checknumber( L, -1 );
   
   /* XXX: Shouldn't have to do the gluPerspective each time...? */
   glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
   glMatrixMode( GL_PROJECTION );
   glLoadIdentity();
   gluPerspective( 60.0f, aspect, 0.1f, 10000.0f );
   gluLookAt( ex, ey, ez, cx, cy, cz, ux, uy, uz );
   glMatrixMode( GL_MODELVIEW );
   glLoadIdentity();

   /* Lighting
   glEnable( GL_LIGHTING );
   glEnable( GL_LIGHT0 );
   GLfloat light1[4] = {0.8, 0.8, 0.8, 0.8};
   GLfloat light2[4] = {1.0, 1.0, 1.0, 1.0};
   GLfloat light[4] = {0.5, 0.5, 0.5, 0.5};
   glLightfv( GL_LIGHT0, GL_AMBIENT, light1 );
   glLightfv( GL_LIGHT0, GL_DIFFUSE, light );
   glLightfv( GL_LIGHT0, GL_SPECULAR, light2 );
   glLightfv( GL_LIGHT0, GL_POSITION, light );

   glMaterialfv( GL_FRONT, GL_SPECULAR, light );
   */

   /* Fog
   glClearColor( 0.5, 0.5, 0.5, 1.0 );
   GLfloat fog[4] = {0.5, 0.5, 0.5, 1.0};
   glFogf( GL_FOG_MODE, GL_LINEAR );
   glFogf( GL_FOG_START, 100.0 );
   glFogf( GL_FOG_END, 1000.0 );
   glFogfv( GL_FOG_COLOR, fog );
   glEnable( GL_FOG );
   */
    	
		

   /* Transparency
   glColor4f(1.0f,1.0f,1.0f,0.5f);
   glBlendFunc(GL_SRC_ALPHA,GL_ONE); 
   glEnable(GL_BLEND);
   glDisable(GL_DEPTH_TEST);
   */


   return 0;
}

static int endFrame( lua_State* L ) {
   SDL_GL_SwapBuffers();
   return 0;
}


// TEXTURES //

static int loadTexture( lua_State* L ) {
   const char* texname = luaL_checkstring( L, 1 );
   SDL_Surface* image = IMG_Load( texname );
   GLuint texture = (GLuint) 0;
   if( image == NULL ) {
      luaL_error( L, "Could not load texture!" );
   }
   glGenTextures( 1, &texture );
   glBindTexture( GL_TEXTURE_2D, texture );
   glTexImage2D( GL_TEXTURE_2D, 0, 3, image->w, image->h, 0, GL_RGBA,
         GL_UNSIGNED_BYTE, image->pixels );
   glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
   glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
   SDL_FreeSurface( image );

   lua_pushinteger( L, texture );
   return 1;
}

static int bindTexture( lua_State* L ) {
   GLuint texture = luaL_checkint( L, 1 );
   glBindTexture( GL_TEXTURE_2D, texture );
   return 0;
}





// MISC //

static int startInput( lua_State* L ) {
   SDL_PumpEvents();
   return 0;
}

static int getKeystate( lua_State* L ) {
   int numkeys = 0;
   int i = 0;

   Uint8 *keystate = SDL_GetKeyState( &numkeys );

   lua_createtable( L, numkeys, 0 );
   for( i = 0; i < numkeys; i++ ) {
      lua_pushinteger( L, i );
      lua_pushboolean( L, keystate[i] );
      lua_settable( L, 1 );
   }

   return 1;
}

static int getRelativeMouseState( lua_State* L ) {
   int x, y, buttons;
   buttons = SDL_GetRelativeMouseState( &x, &y );

   lua_pushnumber( L, x );
   lua_pushnumber( L, y );
   lua_pushnumber( L, buttons );
   return 3; 
}

/*
static int warpMouse( lua_State* L ) {
   int x = luaL_checkint( L, 1 );
   int y = luaL_checkint( L, 2 );
   SDL_WarpMouse( x, y );

   return 0;
}
*/



// This returns two arrays; one of key-down values, one of key-up values
static int getKeyEvents( lua_State* L ) {
   SDL_Event e;
   int keydowns = 0;
   int keyups = 0;
   lua_newtable( L );
   lua_newtable( L );
   while( SDL_PollEvent( &e ) ) {
      switch( e.type ){
         case SDL_KEYDOWN:
            lua_pushinteger( L, keydowns ); 
            lua_pushinteger( L, (int) e.key.keysym.sym ); 
            lua_settable( L, 1 );

            keydowns += 1;
            break;
         case SDL_KEYUP:
            lua_pushinteger( L, keydowns ); 
            lua_pushinteger( L, (int) e.key.keysym.sym ); 
            lua_settable( L, 2 );

            keyups += 1;
            break;
      }
   }
   return 2;
}

static int getTicks( lua_State* L ) {
   int ticks = SDL_GetTicks();
   lua_pushinteger( L, ticks );
   return 1;
}

static const struct luaL_reg libstruct[] = {
   {"initGraphics", initGraphics},
   {"quitGraphics", quitGraphics},
   {"loadTexture", loadTexture},
   {"bindTexture", bindTexture},
   {"getKeystate", getKeystate},
   {"getKeyEvents", getKeyEvents},
   {"getTicks", getTicks},
   {"startInput", startInput},
   {"getRelativeMouseState", getRelativeMouseState},
//   {"warpMouse", warpMouse},
//   {"lookAt", lookAt},
//   {"swapBuffers", swapBuffers},
//
   {"startFrame", startFrame}, 
   {"endFrame", endFrame},
//   {"putText", putText},
   {NULL, NULL}
};

int luaopen_wanderer_misc( lua_State* L ) {
   luaL_register( L, "misc", libstruct );
   return 1;
}

