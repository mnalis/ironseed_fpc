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

all: is crewgen intro main cleantmp

c_utils.o: c_utils.c
	$(c_compiler) $(includes) $(cflags) -c c_utils.c

# find dependencies with ex.: sed -ne 's/uses //;T;s/[,;]/.pas /g;p' intro.pas

is: is.pas version.pas
	$(compiler) $(flags) $(debug) is.pas

intro: c_utils.o intro.pas  utils_.pas gmouse.pas modplay.pas version.pas
	$(compiler) $(flags) $(debug) $(p_link) intro.pas

crewgen: c_utils.o crewgen.pas  data.pas  gmouse.pas  utils_.pas  saveload.pas  display.pas  utils.pas  modplay.pas
	$(compiler) $(flags) $(debug) $(p_link) crewgen.pas

main: c_utils.o main.pas  init.pas  gmouse.pas  starter.pas  data.pas heapchk.pas
	$(compiler) $(flags) $(debug) $(p_link) main.pas


cleantmp:
	rm -f *.ppu *.s

clean: cleantmp
	rm -f is intro crewgen  main *.o

.PHONY: all cleantmp clean
