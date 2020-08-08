unit starter;

{***************************
   Initialization for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}
{$O+}
{$I-}
interface

procedure cleartextdisplay;
procedure journeyon;
procedure checkparams;
procedure readydata;

implementation

uses crt, utils_, dos, data, gmouse, saveload, usecode, journey, display,
 utils, utils2, weird, ending, heapchk;

procedure showcube;
var i,j: integer;
begin
 setcolor(45);
 setwritemode(xorput);
 for j:=0 to 50 do
  for i:=0 to 44 do
   begin
    line(240,167,j+215,i+145);
    delay(tslice div 32);
    line(240,167,j+215,i+145);
    screen[i+145,j+215]:=cubetar^[i,j];
   end;
 setwritemode(copyput);
end;

procedure checkparams;
var i,j: integer;
    curdir: string[60];
    diskfreespace: longint;
begin
 if (paramstr(1)<>'/playseed') and (paramstr(1)<>'/killseed') then
  begin
   //textmode(co80);
   writeln('Do not run this program separately.  Please run IS.EXE.');
   halt(4);
  end;
 tslice:=10;
{$IFNDEF DEMO}
 if paramstr(1)='/killseed' then
  begin
   ship.options[3]:=1;
   ship.options[9]:=63;
   endgame;
  end;
{$ENDIF}
 tempdir:=getenv('TEMP');
 if tempdir[length(tempdir)]='\' then dec(tempdir[0]);
 if tempdir='' then tempdir:='TEMP';
 getdir(0,curdir);
 chdir(tempdir);
 if ioresult<>0 then tempdir:='TEMP';
 chdir(curdir);
 if ioresult<>0 then errorhandler('Changing directory error,'+curdir,5);
 tempdir:=fexpand(tempdir);
 diskfreespace:=diskfree(ord(tempdir[1])-64);
 if ioresult<>0 then errorhandler('Failure accessing drive '+tempdir[1],5);
 if diskfreespace<128000 then tempdir:='TEMP';
 chdir(tempdir);
 if ioresult<>0 then
  begin
   mkdir(tempdir);
   if ioresult<>0 then errorhandler('Creating directory error,'+tempdir,5);
  end;
 chdir(curdir);
 if ioresult<>0 then errorhandler('Changing directory error,'+curdir,5);
 if tempdir[length(tempdir)]='\' then dec(tempdir[0]);
end;

procedure readybuildtimes;
var
   tempcreate : ^creationtype;
   creafile   : file of creationtype;
   i, j, k    : Integer;
begin
   for i:=1 to maxcargo do
   begin
      bldcargo[i] := 30000;
      for j := 1 to 3 do
	 prtcargo[i, j] := 0;
      for j := 1 to 6 do
	 lvlcargo[i, j] := 1;
   end;
   new(tempcreate);
   assign(creafile,'data/creation.dta');
   reset(creafile);
   if ioresult<>0 then errorhandler('creation.dta',1);
   for j:=1 to totalcreation do
   begin
      read(creafile,tempcreate^);
      if ioresult<>0 then errorhandler('creation.dta',5);
      for i:=1 to maxcargo do
      begin
	 if tempcreate^.index = cargo[i].index then
	 begin
	    bldcargo[i] := 0;
	    for k := 1 to 6 do
	       inc(bldcargo[i], tempcreate^.levels[k]);
	    for k := 1 to 3 do
	       prtcargo[i, k] := tempcreate^.parts[k];
	    for k := 1 to 6 do
	       lvlcargo[i, k] := tempcreate^.levels[k];
	    break;
	 end;
      end;
   end;
   close(creafile);
   dispose(tempcreate);
end;

procedure readydata;
var iconfile: file of iconarray;
    weapfile: file of weaponarray;
    cargfile: file of cargoarray;
    artfile: file of artifacttype;
    planfile: file of planicontype;
begin
 new(artifacts);
 if (paramstr(1)='/playseed') or (paramstr(1)='/killseed') then
  begin
   assign(iconfile,'data/icons.vga');
   reset(iconfile);
   if ioresult<>0 then errorhandler('icons',1);
   read(iconfile,icons^);
   if ioresult<>0 then errorhandler('icons',5);
   close(iconfile);
   assign(weapfile,'data/weapon.dta');
   reset(weapfile);
   if ioresult<>0 then errorhandler('weapon.dta',1);
   read(weapfile,weapons);
   if ioresult<>0 then errorhandler('weapon.dta',5);
   close(weapfile);
   assign(cargfile,'data/cargo.dta');
   reset(cargfile);
   if ioresult<>0 then errorhandler('cargo.dta',1);
   read(cargfile,cargo);
   if ioresult<>0 then errorhandler('cargo.dta',5);
   close(cargfile);
   assign(artfile,'data/artifact.dta');
   reset(artfile);
   if ioresult<>0 then errorhandler('artifact.dta',1);
   read(artfile,artifacts^);
   if ioresult<>0 then errorhandler('artifact.dta',5);
   close(artfile);
   assign(planfile,'data/planicon.dta');
   reset(planfile);
   if ioresult<>0 then errorhandler('planicon.dta',1);
   read(planfile,planicons^);
   if ioresult<>0 then errorhandler('planicon.dta',5);
   close(planfile);
   readybuildtimes;
  end;
end;

procedure setcube;
var a,b,i,j: integer;
begin
 for a:=0 to 2 do
  for b:=0 to 2 do
   for j:=0 to 16 do
    for i:=0 to 14 do
     cubesrc^[b*15+i,a*17+j]:=icons^[a*3+b,j,i];
 for a:=0 to 2 do
  for b:=0 to 2 do
   for j:=0 to 16 do
    for i:=0 to 14 do
     cubetar^[b*15+i,a*17+j]:=icons^[a*3+b,j,i];
end;

procedure cleartextdisplay;
var temp: linetype;
    i,j: integer;
begin
 fillchar(temp[1],30,ord(' '));
 temp[0]:=chr(30);
 for j:=0 to 30 do
  begin
   textdisplay^[j]:=temp;
   for i:=1 to 30 do colordisplay^[j,i]:=0;
  end;
end;

procedure getback2;
var i,j: integer;
begin
 for j:=202 to 214 do
  for i:=145 to 189 do
   back3[j-202,i-145]:=screen[i,j];
 for j:=266 to 278 do
  for i:=145 to 189 do
   back4[j-266,i-145]:=screen[i,j];
 for i:=190 to 199 do
  mymove(screen[i,215],back2[i-190],13);
end;

procedure loaddata;
var i,j,index: integer;
begin
 for j:=1 to nearbymax do nearby[j].index:=0;
 i:=0;
 showplanet:=false;
 for j:=1 to 250 do
  begin
   x:=systems[j].x-ship.posx;
   y:=systems[j].y-ship.posy;
   z:=systems[j].z-ship.posz;
   if (abs(x)<400) and (abs(y)<400)
    and (abs(z)<400) then
     begin
      inc(i);
      if i>nearbymax then errorhandler('NEARBY STRUCTURE OVERFLOW.',6);
      nearby[i].index:=j;
      nearby[i].x:=x/10;
      nearby[i].y:=y/10;
      nearby[i].z:=z/10;
      systems[j].notes:=systems[j].notes or 1;
     end;
  end;
 move(nearby,nearbybackup,sizeof(nearbyarraytype));
 index:=0;
 for j:=1 to nearbymax do
  if (systems[nearby[j].index].x=ship.posx) and
     (systems[nearby[j].index].y=ship.posy) and
     (systems[nearby[j].index].z=ship.posz) then
    begin
     index:=j;
     j:=nearbymax;
    end;
 if index<>0 then
  begin
   j:=findfirstplanet(nearby[index].index)+ship.orbiting;
   curplan:=j;
   if ship.orbiting=0 then readystar else readyplanet;
  end;
end;

procedure checkpendingevent;
var i,j,index: integer;
begin
 index:=0;
 for j:=1 to nearbymax do
  if (systems[nearby[j].index].x=ship.posx) and
     (systems[nearby[j].index].y=ship.posy) and
     (systems[nearby[j].index].z=ship.posz) then
    begin
     index:=j;
     j:=nearbymax;
    end;
 if (index<>0) and (ship.orbiting=0) then
  begin
   for j:=0 to maxeventsystems do
    if eventsystems[j]=nearby[index].index then event(eventstorun[j]);
  end;
end;

procedure initializedata;
var j: integer;
begin
 targetready:=false;
 panelon:=false;
 showplanet:=false;
 backgrx:=0;
 backgry:=0;
 target:=0;
 t1:=0;
 t2:=0;
 textindex:=25;
 for j:=1 to 4 do statcolors[j]:=0;
 reloading:=false;
 lightindex:=0;
 batindex:=0;
 glowindex:=1;
 {fading;}
 fadestopmod(-8, 20);
 palettedirty := true;
 fadestep(-64);
 loadscreen('data/main',@screen);
 reloadbackground;
 showtime;
 quit:=false;
 viewmode2:=0;
 viewmode:=0;
 batindex:=0;
 idletime:=0;
 action:=0;
 tcolor:=31;
 alert:=2;
 if (ship.armed) or ((ship.shieldlevel=ship.shieldopt[3]) and (ship.shieldopt[3]>ship.shieldopt[1])) then setalertmode(2)
  else setalertmode(0);
 bkcolor:=3;
 if ship.shield<60 then ship.shieldlevel:=0
  else ship.shieldlevel:=ship.shieldopt[1];
 showresearchlights;
end;

procedure loadspecial;
var t: string[10];
    j: integer;
begin
 t:=paramstr(2);
 if (t='') or (t[1]='/') then exit;
 j:=ord(t[1])-48;
 if (j>8) or (j<1) then exit;
 curfilenum:=0;
 loadgame(j);
 if curfilenum<>0 then
 begin
    event(10);
    if chevent(12) then event(1001);
 end;
end;

procedure journeyon;
var
 i: word;
label reload;
begin
 new(landform);
 new(cubetar);
 new(cubesrc);
 new(screen2);
 fillchar(screen2^,sizeof(screen2^),3);
 new(planet);
 new(tempplan);
 new(textdisplay);
 new(colordisplay);
 {HeapStats;}
 {fading;}
 fadestopmod(-8, 20);
 palettedirty := true;
 fadestep(-64);
 mouseshow;
 if paramstr(2)<>'' then loadspecial;
 if (curfilenum=0) and (not loadgamedata(true)) then
 begin
      //textmode(co80);
      closegraph;
      halt(3);
 end;
 {HeapStats;}
 {halt(4);}
reload:
 mousehide;
 initializedata;
 getback2;
 showtime;
 setcube;
 cube:=0;
 c:=0;
 ecl:=0;
 cursorx:=1;
 command:=0;
 done:=true;
 cleartextdisplay;
 loaddata;
 if not showplanet then
  begin
   checkstats;
   {fadein;}
  end;
 showcube;
 readystatus;
 tcolor:=45;
 bkcolor:=0;
 printxy(208,128,cubefaces[cube]);
 bkcolor:=3;
 mouseshow;
 if not showplanet then readystarmap(1);
 checkpendingevent;
 mainloop;
 if reloading then goto reload;
 //textmode(co80);
 while fastkeypressed do readkey;
 closegraph;
 halt(4);
end;

begin
 new(starmapscreen);
 new(backgr);
 new(icons);
end.

