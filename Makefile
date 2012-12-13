CC=gcc
CLFAGS=-c -Wall -I ./include `sdl-config --cflags` \
       `pkg-config --cflags lua5.1` -fPIC
LDFLAGS=-shared `sdl-config --libs` -lSDL_image -lSDL_ttf \
	`pkg-config --libs lua5.1` \
	-lGL -lGLU -ldl

SOURCE=misc.c quaternion.c vector.c mesh.c
OBJECTS=misc.o quaternion.o vector.o mesh.o
LIBRARY=wanderer.so

all: $(LIBRARY)

clean:
	rm -f $(OBJECTS) *~

$(LIBRARY): $(OBJECTS)
	$(CC) -o $(LIBRARY) $(LDFLAGS) $(OBJECTS) 

$(OBJECTS): $(SOURCE)
	$(CC) $(CLFAGS) -c $(SOURCE)
