compiler:= fpc
c_compiler:= gcc
flags:= -Mtp -g -gl
#-Aas -ap
debug:= -C3 -Ci -Co -CO  -O- -gw -godwarfsets  -gt -gv -vw  -Sa
# -Cr -CR -Ct   -gh  -gc
p_link:= -k-lSDL_mixer -k-lSDL -k-lm
cflags:= -g -Wall -W -pedantic -Wno-unused-parameter -Wconversion
includes=`sdl-config --cflags` -I /usr/X11R6/include

# default target to build, best is debug_ogl (NOT "release_xxx" AKA "no-checks" versions!)
all: clean debug_ogl

cleanbuild: clean build cleantmp

# SDL no-checks version
release_sdl: cflags += -O -DNDEBUG -DNO_OGL
release_sdl: cleanbuild

# OpenGL no-checks version
release_ogl: cflags += -O -DNDEBUG
release_ogl: p_link += -k-lGL -k-lGLU
release_ogl: cleanbuild

# SDL debug version
debug_sdl:   clean debug_sdl1 cleantmp
debug_sdl1:  cflags += -O0 -DNO_OGL -Werror
debug_sdl1:  flags  += $(debug)
debug_sdl1:  build

# OpenGL debug version
debug_ogl:   clean debug_ogl1 cleantmp
debug_ogl1:  cflags += -O0 -Werror
debug_ogl1:  flags  += $(debug)
debug_ogl1:  p_link += -k-lGL -k-lGLU
debug_ogl1:  build

# DEMO SDL debug version
demo_sdl:   clean demo_sdl1 cleantmp
demo_sdl1:  cflags += -O0 -DNO_OGL -Werror
demo_sdl1:  flags  += $(debug) -dDEMO
demo_sdl1:  build

build: is crewgen intro main

c_utils.o: Makefile c_utils.c
	$(c_compiler) $(includes) $(cflags) -c c_utils.c

is: Makefile is.pas version.pas
	$(compiler) $(flags) is.pas

intro: Makefile c_utils.o *.pas
	$(compiler) $(flags) $(p_link) intro.pas

crewgen: Makefile c_utils.o *.pas
	$(compiler) $(flags) $(p_link) crewgen.pas

main: Makefile c_utils.o *.pas
	$(compiler) $(flags) $(p_link) main.pas

test/test_0_c: clean Makefile c_utils.c test/test_0_c.c
	$(c_compiler) $(includes) $(cflags) -O0 -Werror `sdl-config --libs` -lSDL_mixer -lm -lGL -lGLU test/test_0_c.c -o test/test_0_c

test/test_0_pas: cflags += -O0 -Werror
test/test_0_pas: flags  += $(debug)
test/test_0_pas: p_link += -k-lGL -k-lGLU
test/test_0_pas: clean Makefile c_utils.o test/test_0_pas.pas
	$(compiler) $(flags) $(p_link) test/test_0_pas.pas


cleantmp:
	rm -f *.ppu *.s

clean: cleantmp
	rm -f is intro crewgen  main *.o

.PHONY: all build cleanbuild cleantmp clean release_sdl release_ogl debug_sdl debug_sdl1 debug_ogl debug_ogl1
