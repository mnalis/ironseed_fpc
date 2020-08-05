compiler:= fpc
c_compiler:= gcc
flags:= -Mtp -g -gl
#-Aas -ap
#debug:= -C3 -Ci -Co -CO  -O- -gw -godwarfsets  -gt -gv -vw  -Sa
# -Cr -CR -Ct   -gh  -gc
p_link:=-k-lSDL_mixer -k-lSDL -k-lm  -k-lGL -k-lGLU
cflags:= -O -g -Wall -W -pedantic -Wno-unused-parameter
# -Wconversion -Werror -DNO_OGL -O0
includes=`sdl-config --cflags` -I /usr/X11R6/include

all: clean build cleantmp

build: is crewgen intro main

c_utils.o: Makefile c_utils.c
	$(c_compiler) $(includes) $(cflags) -c c_utils.c

is: Makefile is.pas version.pas
	$(compiler) $(flags) $(debug) is.pas

intro: Makefile c_utils.o *.pas
	$(compiler) $(flags) $(debug) $(p_link) intro.pas

crewgen: Makefile c_utils.o *.pas
	$(compiler) $(flags) $(debug) $(p_link) crewgen.pas

main: Makefile c_utils.o *.pas
	$(compiler) $(flags) $(debug) $(p_link) main.pas


cleantmp:
	rm -f *.ppu *.s

clean: cleantmp
	rm -f is intro crewgen  main *.o

.PHONY: all build cleantmp clean
