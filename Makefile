compiler:= fpc
c_compiler:= gcc
flags:= -Mtp -g -Aas -a 
debug:= -C3 -Ci -Co -CO  -O- -gh -gl -gw -godwarfsets  -gt -gv -vw  -Sa
# -Cr -CR -Ct  -gc
p_link:=-k-lSDL_mixer -k-lSDL -k-lm -k-lGL -k-lGLU
cflags:= -O2 -g -W -Wall -pedantic  -Wno-implicit-function-declaration -Wno-unused-parameter 
# -Wconversion -Werror
includes=`sdl-config --cflags` -I /usr/X11R6/include
libdir=`sdl-config --libs` -L /usr/X11R6/lib 
link:= -lSDL_mixer -lm -lGL -lGLU

target:=


all:	is

is:	 crewgen intro main
		$(compiler) $(flags) $(debug)  is.pas

intro:
	$(c_compiler) $(includes) $(libdir) $(cflags)  $(link) -c c_utils.c
#	$(compiler) $(flags) $(debug) utils_
	$(compiler) $(flags) $(debug) $(p_link) intro.pas

crewgen:
		$(c_compiler) $(includes) $(libdir) $(cflags) $(link) -c c_utils.c
		$(compiler) $(flags) $(debug)  $(p_link) crewgen.pas

main:
		$(c_compiler) $(includes) $(libdir) $(cflags) $(link) -c c_utils.c
		$(compiler) $(flags) $(debug)  $(p_link) main.pas


clean:
	rm -f intro crewgen is main *.o *.ppu *.s
