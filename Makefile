fpc_compiler:= fpc
c_compiler:= gcc
d_compiler = gdc -g -o $@
#d_compiler = ldc2 -g -check-printf-calls

fpc_flags:= -Mtp -g -gl -gv
#-Aas -ap
fpc_debug:= -C3 -Ci -Co -CO  -O- -gw -godwarfsets  -gt -vewnhiq   -Sa -Sy -Sewnh -vm4049 -dTrace
# -Cr -CR -Ct   -gh  -gc -dDEBUG
p_link:= -k-lSDL_mixer -k-lSDL -k-lm
cflags:= -g -Wall -W -pedantic -Wno-unused-parameter -Wconversion
includes=`sdl-config --cflags` -I /usr/X11R6/include

# default target to build, best is debug_ogl (NOT "release_xxx" AKA "no-checks" versions!)
all: clean debug_ogl

cleanbuild: clean build cleantmp

# OpenGL no-checks version
release_ogl debug_ogl1: p_link += -k-lGL -k-lGLU

release_ogl: cflags += -O -DNDEBUG
release_ogl: cleanbuild

# OpenGL debug version
debug_ogl:   clean debug_ogl1 cleantmp
debug_ogl1:  tags
debug_ogl1:  cflags += -O0 -Werror
debug_ogl1:  fpc_flags  += $(fpc_debug)
debug_ogl1:  build

# SDL no-checks version
release_sdl: cflags += -O -DNDEBUG -DNO_OGL
release_sdl: cleanbuild

# SDL debug version
debug_sdl1 demo_sdl1: tags
debug_sdl1 demo_sdl1 data_build: cflags += -O0 -DNO_OGL -Werror

debug_sdl:   clean debug_sdl1 cleantmp
debug_sdl1:  fpc_flags  += $(fpc_debug)
debug_sdl1:  build

# DEMO SDL debug version
demo_sdl:    clean demo_sdl1 cleantmp
demo_sdl1:   fpc_flags  += $(fpc_debug) -dDEMO
demo_sdl1:   build

PROG_FILES = is crewgen intro main
DATA_TOOLS_D = Data_Generators/makedata/convmake Data_Generators/makedata/logmake
DATA_TOOLS_P = Data_Generators/makedata/aliemake Data_Generators/makedata/artimake Data_Generators/makedata/cargmake Data_Generators/makedata/creamake Data_Generators/makedata/crewmake Data_Generators/makedata/elemmake Data_Generators/makedata/eventmak Data_Generators/makedata/itemmake Data_Generators/makedata/makename Data_Generators/makedata/scanmake Data_Generators/makedata/shipmake Data_Generators/makedata/sysmake Data_Generators/makedata/weapmake  Data_Generators/makedata/iconmake Data_Generators/makedata/getfont Data_Generators/makedata/namemake Data_Generators/misc/scr2cpr Data_Generators/misc/cpr2scr Data_Generators/misc/cpr2tga Data_Generators/misc/tga2cpr

CREWCONVS := data/conv0001.dta data/conv0002.dta data/conv0003.dta data/conv0004.dta data/conv0005.dta data/conv0006.dta
RACECONVS := data/conv1001.dta data/conv1002.dta data/conv1003.dta data/conv1004.dta data/conv1005.dta data/conv1006.dta data/conv1007.dta data/conv1008.dta data/conv1009.dta data/conv1010.dta data/conv1011.dta
SPECCONVS := data/conv1100.dta data/conv1101.dta data/conv1102.dta data/conv1103.dta data/conv1000.dta
CPR_CREW0 := data/image01.cpr data/image02.cpr data/image03.cpr data/image04.cpr data/image05.cpr data/image06.cpr data/image07.cpr data/image08.cpr data/image09.cpr data/image10.cpr data/image11.cpr data/image12.cpr data/image13.cpr data/image14.cpr data/image15.cpr data/image16.cpr data/image17.cpr data/image18.cpr data/image19.cpr data/image20.cpr data/image21.cpr data/image22.cpr data/image23.cpr data/image24.cpr data/image25.cpr data/image26.cpr data/image27.cpr data/image28.cpr data/image29.cpr data/image30.cpr data/image31.cpr data/image32.cpr
CPR_MISC0 := data/trade.cpr data/end6.cpr
CPR_SELFPAL1 := data/main.cpr data/main3.cpr data/end1.cpr data/end2.cpr data/end3.cpr data/end4.cpr data/end5.cpr data/alien.cpr data/alien1.cpr data/alien2.cpr data/alien3.cpr data/alien4.cpr data/alien5.cpr data/alien6.cpr data/alien7.cpr data/alien8.cpr data/alien9.cpr data/alien10.cpr

IMG_FILES := data/main.pal $(CPR_SELFPAL1) $(CPR_CREW0) $(CPR_MISC0)
DATA_FILES := data/log.dta  data/titles.dta $(CREWCONVS) $(RACECONVS) $(SPECCONVS) $(IMG_FILES) data/iteminfo.dta  data/cargo.dta data/creation.dta data/scan.dta data/sysname.dta data/contact0.dta data/crew.dta data/artifact.dta data/elements.dta data/event.dta data/weapon.dta data/weapicon.dta data/planicon.dta data/ships.dta data/planname.txt data/icons.vga

build:  $(PROG_FILES) $(DATA_FILES)

c_utils.o: Makefile c_utils.c
	$(c_compiler) $(includes) $(cflags) -c c_utils.c

is: Makefile is.pas version.pas
	$(fpc_compiler) $(fpc_flags) is.pas

intro crewgen main: Makefile c_utils.o *.pas
	$(fpc_compiler) $(fpc_flags) $(p_link) $@.pas

test/test_0_c: clean Makefile c_utils.c test/test_0_c.c
	$(c_compiler) $(includes) $(cflags) -O0 -Werror `sdl-config --libs` -lSDL_mixer -lm -lGL -lGLU test/test_0_c.c -o test/test_0_c

test/test_0_pas: cflags += -O0 -Werror
test/test_0_pas: fpc_flags  += $(fpc_debug)
test/test_0_pas: p_link += -k-lGL -k-lGLU
test/test_0_pas: clean Makefile c_utils.o test/test_0_pas.pas
	$(fpc_compiler) $(fpc_flags) $(p_link) test/test_0_pas.pas


cleantmp:
	find . -iname "*.ppu" -print0 | xargs -0r rm -f
	find . -iname "*.s" -print0 | xargs -0r rm -f

clean: cleantmp
	rm -f $(PROG_FILES)
	rm -f link.res
	find . -iname "*.o" -print0 | xargs -0r rm -f

cleanbak:
	find . -iname "*~" -print0 | xargs -0r rm -f
	find . -iname "*.bak" -print0 | xargs -0r rm -f

reallyclean: clean cleanbak
	rm -f $(DATA_TOOLS_D) $(DATA_TOOLS_P) tags
	rm -f test/test_0_c test/test_0_pas test/testdiv0 test/testkey1 test/testsize test/test_write test/filename

distclean: reallyclean
	rm -f LPT1 TEMP/*

mrproper: distclean data_destroy

tags: *.c *.pas
	ctags $^


Data_Generators/makedata/convmake: Data_Generators/makedata/convmake.d Data_Generators/makedata/data.d
Data_Generators/makedata/logmake: Data_Generators/makedata/logmake.d Data_Generators/makedata/data.d
$(DATA_TOOLS_D):
	$(d_compiler) $^

Data_Generators/makedata/aliemake: Data_Generators/makedata/aliemake.pas
Data_Generators/makedata/artimake: Data_Generators/makedata/artimake.pas
Data_Generators/makedata/cargmake: Data_Generators/makedata/cargmake.pas
Data_Generators/makedata/creamake: Data_Generators/makedata/creamake.pas
Data_Generators/makedata/crewmake: Data_Generators/makedata/crewmake.pas
Data_Generators/makedata/elemmake: Data_Generators/makedata/elemmake.pas
Data_Generators/makedata/eventmak: Data_Generators/makedata/eventmak.pas
Data_Generators/makedata/getfont: Data_Generators/makedata/getfont.pas
Data_Generators/makedata/itemmake: Data_Generators/makedata/itemmake.pas
Data_Generators/makedata/makename: Data_Generators/makedata/makename.pas
Data_Generators/makedata/scanmake: Data_Generators/makedata/scanmake.pas
Data_Generators/makedata/shipmake: Data_Generators/makedata/shipmake.pas
Data_Generators/makedata/sysmake: Data_Generators/makedata/sysmake.pas
Data_Generators/makedata/weapmake: Data_Generators/makedata/weapmake.pas
Data_Generators/makedata/iconmake: Data_Generators/makedata/iconmake.pas c_utils.o data.pas utils_.pas
Data_Generators/makedata/namemake: Data_Generators/makedata/namemake.pas

Data_Generators/misc/scr2cpr: Data_Generators/misc/scr2cpr.pas Data_Generators/misc/data2.pas
Data_Generators/misc/cpr2scr: Data_Generators/misc/cpr2scr.pas Data_Generators/misc/data2.pas
Data_Generators/misc/cpr2tga: Data_Generators/misc/cpr2tga.pas Data_Generators/misc/data2.pas
Data_Generators/misc/tga2cpr: Data_Generators/misc/tga2cpr.pas Data_Generators/misc/data2.pas

$(DATA_TOOLS_P):
	$(fpc_compiler) $(fpc_flags) $(fpc_debug) $(p_link)  $<

data/log.dta  data/titles.dta: Data_Generators/makedata/logmake Data_Generators/makedata/logs.txt
	Data_Generators/makedata/logmake Data_Generators/makedata/logs.txt data/titles.dta data/log.dta


data/conv%.dta:
	Data_Generators/makedata/convmake $< $(subst .dta,,$@)

data/conv1000.dta:
	touch data/conv1000.dta data/conv1000.ind

data/conv0001.dta: Data_Generators/makedata/crewcon1.txt Data_Generators/makedata/convmake
data/conv0002.dta: Data_Generators/makedata/crewcon2.txt Data_Generators/makedata/convmake
data/conv0003.dta: Data_Generators/makedata/crewcon3.txt Data_Generators/makedata/convmake
data/conv0004.dta: Data_Generators/makedata/crewcon4.txt Data_Generators/makedata/convmake
data/conv0005.dta: Data_Generators/makedata/crewcon5.txt Data_Generators/makedata/convmake
data/conv0006.dta: Data_Generators/makedata/crewcon6.txt Data_Generators/makedata/convmake

data/conv1001.dta: Data_Generators/makedata/sengcon1.txt Data_Generators/makedata/convmake
data/conv1002.dta: Data_Generators/makedata/dpahcon1.txt Data_Generators/makedata/convmake
data/conv1003.dta: Data_Generators/makedata/aardcon1.txt Data_Generators/makedata/convmake
data/conv1004.dta: Data_Generators/makedata/ermicon1.txt Data_Generators/makedata/convmake
data/conv1005.dta: Data_Generators/makedata/titecon1.txt Data_Generators/makedata/convmake
data/conv1006.dta: Data_Generators/makedata/quacon1.txt  Data_Generators/makedata/convmake
data/conv1007.dta: Data_Generators/makedata/scavcon1.txt Data_Generators/makedata/convmake
data/conv1008.dta: Data_Generators/makedata/iconcon1.txt Data_Generators/makedata/convmake
data/conv1009.dta: Data_Generators/makedata/guilcon1.txt Data_Generators/makedata/convmake
data/conv1010.dta: Data_Generators/makedata/mochcon1.txt Data_Generators/makedata/convmake
data/conv1011.dta: Data_Generators/makedata/voidcon1.txt Data_Generators/makedata/convmake

data/conv1100.dta: Data_Generators/makedata/tek2con1.txt Data_Generators/makedata/convmake
data/conv1101.dta: Data_Generators/makedata/tek3con1.txt Data_Generators/makedata/convmake
data/conv1102.dta: Data_Generators/makedata/tek4con1.txt Data_Generators/makedata/convmake
data/conv1103.dta: Data_Generators/makedata/tek5con1.txt Data_Generators/makedata/convmake

data/iteminfo.dta: Data_Generators/makedata/itemmake Data_Generators/makedata/iteminfo.txt
	Data_Generators/makedata/itemmake
data/creation.dta: Data_Generators/makedata/creamake Data_Generators/makedata/creation.txt  data/cargo.dta
	Data_Generators/makedata/creamake
data/cargo.dta:    Data_Generators/makedata/cargmake Data_Generators/makedata/cargo.txt
	Data_Generators/makedata/cargmake
data/scan.dta:     Data_Generators/makedata/scanmake Data_Generators/makedata/scandata.txt
	Data_Generators/makedata/scanmake
data/sysname.dta:  Data_Generators/makedata/sysmake  Data_Generators/makedata/names.txt data/sysset.dta
	Data_Generators/makedata/sysmake
data/contact0.dta: Data_Generators/makedata/aliemake Data_Generators/makedata/contact.txt
	Data_Generators/makedata/aliemake
data/crew.dta:     Data_Generators/makedata/crewmake Data_Generators/makedata/crew.txt
	Data_Generators/makedata/crewmake
data/artifact.dta: Data_Generators/makedata/artimake Data_Generators/makedata/anom.txt
	Data_Generators/makedata/artimake
data/elements.dta: Data_Generators/makedata/elemmake Data_Generators/makedata/element.txt
	Data_Generators/makedata/elemmake
data/event.dta:    Data_Generators/makedata/eventmak Data_Generators/makedata/event.txt
	Data_Generators/makedata/eventmak
data/weapon.dta:   Data_Generators/makedata/weapmake Data_Generators/makedata/weapon.txt
	Data_Generators/makedata/weapmake
data/ships.dta:    Data_Generators/makedata/shipmake Data_Generators/makedata/alienshp.txt
	Data_Generators/makedata/shipmake
data/weapicon.dta data/planicon.dta: Data_Generators/makedata/iconmake Data_Generators/makedata/planicon.cpr Data_Generators/makedata/planicon.pal
	Data_Generators/makedata/iconmake
data/planname.txt: Data_Generators/makedata/namemake Data_Generators/makedata/newnames.txt
	Data_Generators/makedata/namemake
data/icons.vga: Graphics_Assets/icons.png Data_Generators/misc/ppm2icons.pl data/main.pal
	convert $< ppm:- | Data_Generators/misc/ppm2icons.pl  data/main.pal > $@

data/main.pal: data/main.cpr Data_Generators/misc/cpr_extract_pal Data_Generators/misc/cpr2scr
	Data_Generators/misc/cpr_extract_pal $<
	mv -f TEMP/main.pal $@

# canned command sequence -- PNG+PAL=CPR with embedded PAL
#define build-cpr1-via-pal
#Data_Generators/misc/pngpal_to_cpr $(word 2,$^) $< 1
#mv -f TEMP/$(notdir $(basename $@)).cpr $@
#endef
# FIXME - generate both main.cpr and main.pal from main.png instead (and remove Graphics_Assets/main.pal)
#data/main.cpr:	data/main.pal	Graphics_Assets/main.png		Makefile Data_Generators/misc/ppmpal2scr.pl Data_Generators/misc/scr2cpr Data_Generators/misc/cpr2scr Data_Generators/misc/cpr_extract_pal Data_Generators/misc/pngpal_to_cpr Data_Generators/misc/png_to_cprnopal
#	$(build-cpr1-via-pal)

# canned command sequence -- PNG with embedded PAL=CPR with embedded PAL
define build-cpr1-via-self
Data_Generators/misc/png_to_cpr $< $@
endef

# canned command sequence -- PNG+PAL(from CPR w/PAL)=CPR without embedded PAL
define build-cpr0-via-cpr1
Data_Generators/misc/png_to_cprnopal $(word 2,$^) $< $@
endef



data/image%.cpr:	data/char.cpr Graphics_Assets/image%.png	Makefile Data_Generators/misc/ppmpal2scr.pl Data_Generators/misc/scr2cpr Data_Generators/misc/cpr2scr Data_Generators/misc/cpr_extract_pal Data_Generators/misc/pngpal_to_cpr Data_Generators/misc/png_to_cprnopal
	WIDTH=70 HEIGHT=70 $(build-cpr0-via-cpr1)

data/trade.cpr:		data/com.cpr Graphics_Assets/trade.png		Makefile Data_Generators/misc/ppmpal2scr.pl Data_Generators/misc/scr2cpr Data_Generators/misc/cpr2scr Data_Generators/misc/cpr_extract_pal Data_Generators/misc/pngpal_to_cpr Data_Generators/misc/png_to_cprnopal
	$(build-cpr0-via-cpr1)

data/end6.cpr:		data/end5.cpr Graphics_Assets/end6.png		Makefile Data_Generators/misc/ppmpal2scr.pl Data_Generators/misc/scr2cpr Data_Generators/misc/cpr2scr Data_Generators/misc/cpr_extract_pal Data_Generators/misc/pngpal_to_cpr Data_Generators/misc/png_to_cprnopal
	$(build-cpr0-via-cpr1)

# FIXME - end*.cpr should use some common PAL ? which one?

# FIXME: dependencies, need correct rules
data/char.cpr:		Graphics_Assets/char.png ;
data/com.cpr:		Graphics_Assets/com.png ;
data/planicon.cpr:	Graphics_Assets/planicon.png ;

# if none of the above rules for .cpr match, use this one (CPR with it's own independent pallete)
# FIXME - make sure we have if needed separate CORRECT rules for all mentioned CPR in dependencies: char.cpr, com.cpr, plaicon.cpr 
data/%.cpr:	Graphics_Assets/%.png					Makefile Data_Generators/misc/tga2cpr Data_Generators/misc/png_to_cpr
	$(build-cpr1-via-self)

data_destroy:
	rm -f $(DATA_TOOLS_D) $(DATA_TOOLS_P) $(DATA_FILES) data/conv*.ind

data_build:   $(DATA_TOOLS_D) $(DATA_TOOLS_P) $(DATA_FILES)

data_rebuild: data_destroy data_build

.PHONY: all build cleanbuild cleantmp clean reallyclean release_sdl release_ogl debug_sdl debug_sdl1 debug_ogl debug_ogl1 demo_sdl demo_sdl1 data_destroy data_build data_rebuild cleanbak mrproper distclean
