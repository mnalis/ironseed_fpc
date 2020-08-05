compiler:= fpc
flags:= -Mtp -g -gl
#-Aas -ap
debug:= -C3 -Ci -Co -CO  -O- -gw -godwarfsets  -gt -gv -vw  -Sa
# -Cr -CR -Ct   -gh  -gc

all: clean build cleantmp

build: cpr2scr scr2cpr

scr2cpr: Makefile scr2cpr.pas data2.pas
	$(compiler) $(flags) $(debug) scr2cpr.pas

cpr2scr: Makefile cpr2scr.pas data2.pas
	$(compiler) $(flags) $(debug) cpr2scr.pas

cleantmp:
	rm -f *.ppu *.s *.o

clean: cleantmp
	rm -f  cpr2scr scr2cpr

.PHONY: all build cleantmp clean

