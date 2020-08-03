compiler:= fpc
c_compiler:= gcc
flags:= -Mtp -g
#-Aas -ap
#debug:= -C3 -Ci -Co -CO  -O- -gl -gw -godwarfsets  -gt -gv -vw  -Sa
# -Cr -CR -Ct   -gh  -gc
p_link:=-k-lSDL_mixer -k-lSDL -k-lm  -k-lGL -k-lGLU
cflags:= -O2 -g -W -Wall -pedantic  -Wno-implicit-function-declaration -Wno-unused-parameter
# -Wconversion -Werror -DNO_OGL
includes=`sdl-config --cflags` -I /usr/X11R6/include
libdir=`sdl-config --libs` -L /usr/X11R6/lib


all: is

is:	 crewgen intro main
		$(compiler) $(flags) $(debug)  is.pas

c_utils.o: c_utils.c
	$(c_compiler) $(includes) $(libdir) $(cflags) -c c_utils.c

intro: c_utils.o
	$(compiler) $(flags) $(debug) $(p_link) intro.pas

crewgen: c_utils.o
	$(compiler) $(flags) $(debug) $(p_link) crewgen.pas

main: c_utils.o
	$(compiler) $(flags) $(debug) $(p_link) main.pas


clean:
	rm -f intro crewgen is main *.o *.ppu *.s
