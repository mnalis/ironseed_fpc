unit starter;
(********************************************************************
    This file is part of Ironseed.

    Ironseed is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Ironseed is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Ironseed.  If not, see <https://www.gnu.org/licenses/>.
********************************************************************)

{*********************************************
   Initialization for IronSeed

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2013 y-salnikov
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

{$I-}
{$O+}

interface

procedure cleartextdisplay;
procedure journeyon;
procedure checkparams;
procedure readydata;

implementation

uses utils_, data, gmouse, saveload, usecode, journey, display, utils, utils2, weird {$IFNDEF DEMO}, ending{$ENDIF};

procedure showcube;
var i,j: word;
begin
 setcolor(45);
 setwritemode(xorput);
 for j:=0 to 50 do
  for i:=0 to 44 do
   begin
    assert (j+215 < 320);
    assert (i+145 < 200);
    line(240,167,word(j+215),word(i+145));
    assert (tslice > 0);
    delay(word(tslice div 32));
    line(240,167,word(j+215),word(i+145));
    screen[i+145,j+215]:=cubetar^[i,j];
   end;
 setwritemode(copyput);
end;

procedure checkparams;
begin
 if (paramstr(1)<>'/playseed') and (paramstr(1)<>'/killseed') then
  begin
   //textmode(co80);
   writeln('Do not run this program separately.  Please run "is".');
   halt(4);
  end;
 tslice:=10;
{$IFNDEF DEMO}
 if paramstr(1)='/killseed' then
  begin
   ship.options[OPT_SOUND]:=1;
   ship.options[OPT_VOLUME]:=63;
   endgame;
  end;
{$ENDIF}
 init_dirs;
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
   assign(creafile,loc_data()+'creation.dta');
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
   assign(iconfile,loc_data()+'icons.vga');
   reset(iconfile);
   if ioresult<>0 then errorhandler('icons',1);
   read(iconfile,icons^);
   if ioresult<>0 then errorhandler('icons',5);
   close(iconfile);
   assign(weapfile,loc_data()+'weapon.dta');
   reset(weapfile);
   if ioresult<>0 then errorhandler('weapon.dta',1);
   read(weapfile,weapons);
   if ioresult<>0 then errorhandler('weapon.dta',5);
   close(weapfile);
   assign(cargfile,loc_data()+'cargo.dta');
   reset(cargfile);
   if ioresult<>0 then errorhandler('cargo.dta',1);
   read(cargfile,cargo);
   if ioresult<>0 then errorhandler('cargo.dta',5);
   close(cargfile);
   assign(artfile,loc_data()+'artifact.dta');
   reset(artfile);
   if ioresult<>0 then errorhandler('artifact.dta',1);
   read(artfile,artifacts^);
   if ioresult<>0 then errorhandler('artifact.dta',5);
   close(artfile);
   assign(planfile,loc_data()+'planicon.dta');
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
 temp[0]:=chr(30);
 fillchar(temp[1],30,ord(' '));
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
  scrfrom_move(screen[i,215],back2[i-190],13*4);
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
var j,index: integer;
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

{ this is always called after game is (re-)loaded }
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
 fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);
 palettedirty := true;
 fadestep(-64);
 loadscreen(loc_data()+'main',@screen);
 reloadbackground;
 showtime;
 quit:=false;
 viewmode2:=0;
 viewmode:=0;
 batindex:=0;
 idletime:=0;
 action:=WNDACT_NONE;
 tcolor:=31;
 bkcolor:=3;
 if (ship.shield=0) then
  begin
    writeln('FIXUP shield from 0 to ID_NOSHIELD');
    ship.shield:=ID_NOSHIELD;
  end;
 if ship.shield=ID_NOSHIELD then ship.shieldlevel:=0
  else if ship.shield=ID_REFLECTIVEHULL then ship.shieldlevel:=100; { fixup shield status only if we are sure what they must be }
 { alert is not saved in savegame. Try to calculate it }
 { NB: game will upgrade from REST to ALERT and vice versa if any subsystems are damaged automatically -  by periodically calling checkstats() }
 alert:=ALRT_COMBAT;	 { NB: main.png has panic button in RED color. So every game must start with ALERT in RED (COMBAT) or color changes won't be working correctly }

 if (ship.armed) or ((ship.shieldlevel=ship.shieldopt[SHLD_COMBAT_WANT]) and (ship.shieldopt[SHLD_COMBAT_WANT]>ship.shieldopt[SHLD_LOWERED_WANT])) then
    setalertmode(ALRT_COMBAT, false)
  else if (ship.shieldlevel=ship.shieldopt[SHLD_ALERT_WANT]) and (ship.shieldopt[SHLD_ALERT_WANT]>ship.shieldopt[SHLD_LOWERED_WANT]) then
    setalertmode(ALRT_ALERT, false)
  else
    setalertmode(ALRT_REST, false);

 showresearchlights;
end;

{ load game from commandline non-interactively }
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
 begin						{ some savegame was loaded }
    event(10);
    if chevent(12) then event(1001);
 end;
end;

procedure journeyon;
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
 fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);
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
 tcolor:=45;
 bkcolor:=0;
 printxy(208,128,cubefaces[cube]);
 bkcolor:=3;
 mouseshow;
 if not showplanet then readystarmap(1);
 checkpendingevent;
 readystatus;
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

