unit usecode;
{$I-}
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
    along with Ironseed.  If not, see <http://www.gnu.org/licenses/>.
********************************************************************)

{***************************
   Ship Display Initialization unit for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

{$O+}

interface

procedure readystarmap(mode: integer);
procedure removesystem(erase: boolean);
procedure readystatus;
procedure readyshipinfo;
procedure processcube(face: integer);
procedure targetstar(tarx,tary: integer);
procedure addlotstime(background, dayticks :Boolean; t: integer);
procedure showbotstuff;
procedure armweapons;
procedure powerdownweapons;
procedure raiseshields;
procedure lowershields;
procedure readytarget;
procedure engage(x,y,z: integer);
procedure removestarmap;
procedure cleanright(erasepanel: boolean);
procedure showresearchlights;
procedure readysysteminfo;
procedure readylongscan;
procedure readyconfigure;
procedure readybots;

implementation

uses utils_, data, gmouse, journey, explore, saveload, display, utils, cargtool, crewinfo, info, comm, utils2, crew2, weird, comm2, crewtick;

const
 optbut: buttype = (21,20,12);
 shdbut: buttype = (9,12,12);
 logbut: buttype = (23,25,6);
 sysbut: buttype = (24,13,26);
 sys2but: buttype = (13,22,27);
 {conbut: buttype = (10,7,12);}
 botbut: buttype = (14,15,16);
 dmgbut: buttype = (17,18,19);
 nonebut: buttype = (12,12,12);

var
 i,j,a,index: integer;

procedure cleanright(erasepanel: boolean);
begin
 if viewmode=0 then exit;
 if (viewmode>7) and (viewmode<11) then removesystem(erasepanel)
  else removerightside(erasepanel);
end;

procedure readyoptions;
begin
 genericrightside(optbut);
 viewindex:=1;
 viewlevel:=1;
 viewmode:=6;
 mousehide;
 tcolor:=191;
 bkcolor:=5;
 printxy(168,27,'General Game Options');
 printxy(168,37,'Screen Saver');
 printxy(173,46,'Time Slice');
 printxy(186,55,'Sound');
 printxy(173,64,'Difficulty');
 printxy(168,73,'General Msgs');
 printxy(175,82,'Animation');
 printxy(173,91,'Font Style');
 printxy(175,100,'Auto-Save');
 printxy(183,109,'Volume');
 setcolor(2);
 line(238,36,238,116);
 setcolor(10);
 line(239,36,239,116);
 screen[36,238]:=6;
 screen[117,239]:=6;
 mouseshow;
 displayoptions(0);
end;


function getanger: integer;
begin;
 getanger := calc_anger (alien.anger, alien.congeniality);
end;

procedure checkrandommonster;
var j: integer;
begin
 if ship.wandering.alienid<16000 then exit;
 i:=random(200);
 case i of
   0..30: begin
           getspecial(7,1007);		{ 15% chance of Scavengers }
           addtofile;
           if getanger=1 then i:=WNDORDER_RETREAT { afraid }
            else if getanger<4 then i:=WNDORDER_NONE { indifferent/friendly }
            else i:=WNDORDER_ATTACK; { angry/violent }
           createwandering(i);
         end;
  31..100: begin			{ 35% chance of random alien }
           j:=random(10)+1;
           if (j<>8) then
            begin
             getspecial(j,1000+j);
             addtofile;
             if getanger=1 then i:=WNDORDER_RETREAT { afraid }
              else if getanger<4 then i:=WNDORDER_NONE { indifferent/friendly }
              else i:=WNDORDER_ATTACK; { angry/violent }
             createwandering(i);
            end;
          end;
 end;
end;

procedure restcrew;
begin
   for j:=1 to 2000 do
   begin
      addtime;
      showtime;
//      delay(tslice div 5);
   end;
   for j:=1 to 6 do
      with ship.crew[j] do
      begin
	 perf:=ComputePerformance(j);
	 skill:=ComputeSkill(j);
	 san:=ComputeSanity(j);
      end;
   checkrandommonster;
   anychange:=true;
end;

procedure readydamagecontrol;
begin
 genericrightside(dmgbut);
 viewindex:=1;
 viewlevel:=2;
 viewmode:=5;
 displaydamagecontrol(1);
end;

procedure readyconfigure;
begin
 mousehide;
 graybutton(15,25,279,115);
 revgraybutton(59,32,234,108);
 mouseshow;
 viewlevel:=1;
 viewmode:=10;
 if ship.shiptype[SHPTYP_HEAVYNESS]=SHPTYPE_HEAVY{1} then viewindex:=2 else viewindex:=1;
 displayconfigure(6);
end;

procedure showbotstuff;
var
   ele	 : array[0..16] of integer;
   mat	 : array[0..20] of Integer;
   cmp	 : array[0..22] of Integer;
   i, j	 : Integer;
   mx	 : Integer;
   total : Integer;
   s	 : string[10];
   y	 : Integer;
begin
   y := 0;
   if tempplan^[curplan].state <> 7 then
   begin
      if incargo(ID_MINEBOT)>0 then inc(y);
      if incargo(ID_MANUFACTORY)>0 then inc(y);
      if incargo(ID_FABRICATOR)>0 then inc(y);
   end else begin
      if incargo(ID_STARMINER)>0 then inc(y);
   end;
   for i:=37 +1 + y * 6 to 114 do
      scr_fillchar(screen[i,166],113,5);
   if tempplan^[curplan].notes and 1=0 then
   begin
      printxy(170,37+y*6,'No info available');
      exit;
   end;
   ele[0]:=0; mat[0]:=0; cmp[0]:=0;  // to turn off warnings, variables are actually correctly initialized by function below
   getstuffamounts(tempplan^[curplan].state, ele, mat, cmp);
   total:=0;
   case viewindex2 of
     1 : begin
	    for i := 0 to 16 do
	       inc(total, ele[i]);
	    while y < 13 do
	    begin
	       mx := 0;
	       j := 0;
	       for i := 0 to 16 do
	       begin
		  if ele[i] > mx then
		  begin
		     mx := ele[i];
		     j := i
		  end;
	       end;
	       ele[j] := 0;
	       if mx > 0 then
	       begin
		  str(mx * 1000 div total:3, s);
		  inc(s[0], 2);
		  s[4] := s[3];
		  s[3] := '.';
		  s[5] := '%';
		  printxy(170-7, 37 + y * 6, CargoName(ID_FIRST_ELEMENT + j * 10));
		  printxy(170-2+16*5, 37 + y * 6, s);
	       end;
	       inc(y);
	    end;
	 end;
     2,5 : begin
	    for i := 0 to 20 do
	       inc(total, mat[i]);
	    while y < 13 do
	    begin
	       mx := 0;
	       j := 0;
	       for i := 0 to 20 do
	       begin
		  if mat[i] > mx then
		  begin
		     mx := mat[i];
		     j := i
		  end;
	       end;
	       mat[j] := 0;
	       if mx > 0 then
	       begin
		  str(mx * 1000 div total:3, s);
		  inc(s[0], 2);
		  s[4] := s[3];
		  s[3] := '.';
		  s[5] := '%';
		  printxy(170-7, 37 + y * 6, CargoName(ID_UNKNOWN_MATERIAL + j));
		  printxy(170-2+16*5, 37 + y * 6, s);
	       end;
	       inc(y);
	    end;
	 end;
     3..4: begin
	    for i := 0 to 20 do
	       inc(total, cmp[i]);
	    while y < 13 do
	    begin
	       mx := 0;
	       j := 0;
	       for i := 0 to 20 do
	       begin
		  if cmp[i] > mx then
		  begin
		     mx := cmp[i];
		     j := i
		  end;
	       end;
	       cmp[j] := 0;
	       if mx > 0 then
	       begin
		  str(mx * 1000 div total:3, s);
		  inc(s[0], 2);
		  s[4] := s[3];
		  s[3] := '.';
		  s[5] := '%';
		  printxy(170-7, 37 + y * 6, CargoName(ID_UNKNOWN_COMPONENT + j));
		  if mx = total then
		     printxy(170-2+16*5, 37 + y * 6, ' 100%')
		  else
		     printxy(170-2+16*5, 37 + y * 6, s);
	       end;
	       inc(y);
	    end;
         end;
   end;
end; { showbotstuff }
(*var j,tt,tly,cnt,max,cargindex,total: integer;
    str1: string[10];
    amounts: array[0..20] of byte;
    temp: ^scantype;
    scanfile: file of scantype;
    tempcreate: ^creationtype;
    creafile: file of creationtype;
begin
   if tempplan^[curplan].notes and 1=0 then
   begin
      y:=0;
      if incargo(ID_MINEBOT)>0 then
      begin
	 printxy(170,43+y*6,'No info available');
	 y:=6;
      end;
      if viewindex2=2 then bkcolor:=179 else bkcolor:=5;
      if incargo(ID_MANUFACTORY)>0 then printxy(170,43+y*6,'No info available');
      exit;
   end;
   y:=0;
   new(temp);
   assign(scanfile,'data/scan.dta');
   reset(scanfile);
   if ioresult<>0 then errorhandler('scan.dta',1);
   read(scanfile,temp^);
   if ioresult<>0 then errorhandler('scan.dta',5);
   close(scanfile);
   for j:=0 to 16 do amounts[j]:=temp^[j,tempplan^[curplan].state];
   if incargo(ID_MINEBOT)>0 then
   begin
      cargindex:=1;
      while (cargo[cargindex].index<ID_FIRST_ELEMENT) do inc(cargindex);
      total:=0;
      for j:=0 to 16 do total:=total+amounts[j];
      repeat
	 inc(y);
	 max:=amounts[0];
	 index:=0;
	 for j:=0 to 16 do if amounts[j]>max then
	 begin
	    max:=amounts[j];
	    index:=j;
	 end;
	 if max>0 then
	 begin
	    x1:=max/total*100;
	    str(x1:5:2,str1);
	    printxy(170,38+y*6,cargo[cargindex+index].name);
	    amounts[index]:=0;
	 end;
      until y=4;
      y:=6;
   end;
   if incargo(ID_MANUFACTORY)>0 then
   begin
      new(tempcreate);
      assign(creafile,'data/creation.dta');
      reset(creafile);
      if ioresult<>0 then errorhandler('creation.dta',1);
      x:=0;

      for j:=1 to totalcreation do
      begin
	 read(creafile,tempcreate^);
	 if ioresult<>0 then errorhandler('creation.dta',5);
	 index := tempcreate^.index;
	 if(index >= ID_UNKNOWN_MATERIAL) and (index <= ID_WORTHLESS_JUNK) then
	 begin
	    tt:=99;
	    tly:=0;
	    for i:=1 to 3 do
	       if (tempcreate^.parts[i]>=ID_FIRST_ELEMENT) then
	       begin
		  cnt := temp^[(tempcreate^.parts[i]-ID_FIRST_ELEMENT) div 10,tempplan^[curplan].state];
		  if tt > cnt then tt := cnt;
		  inc(tly, cnt);
	       end;
	    if tt > 0 then
	       amounts[index - ID_UNKNOWN_MATERIAL] := tly
	    else
	       amounts[index - ID_UNKNOWN_MATERIAL] := 0;
	    {str(index, str1);
	    printxy(0,(index - ID_UNKNOWN_MATERIAL) * 6, str1);
	    str(tly, str1);
	    printxy(40,(index - ID_UNKNOWN_MATERIAL) * 6, str1);
	    str(tt, str1);
	    printxy(60,(index - ID_UNKNOWN_MATERIAL) * 6, str1);}
	 end;
      end;
      repeat
	 max := 0;
	 for j := 1 to 19 do
	    if amounts[j] > max then
	    begin
	       max := amounts[j];
	       index := j;
	    end;
	 if max > 0 then
	 begin
	    amounts[index] := 0;
	    for j := 1 to maxcargo do
	       if cargo[j].index = ID_UNKNOWN_MATERIAL + index then
	       begin
		  inc(y);
		  inc(x);
		  printxy(170,40+y*6,cargo[j].name);
		  break;
	       end;
	 end;
      until (max = 0) or (x = 5);
      close(creafile);
      dispose(tempcreate);
   end;
   dispose(temp);
end;*)

procedure readybots;
begin
 if not showplanet then
  begin
   tcolor:=94;
   println;
   print('ENGINEERING: Not near a planet.');
   exit;
  end;
 cleanright(false);
 genericrightside(botbut);
 tcolor:=191;
 bkcolor:=5;
 mousehide;
 printxy(183,27,'Cache Contents');
 mouseshow;
 viewlevel:=0;
 viewmode:=11;
 viewindex:=1;
 while(tempplan^[curplan].cache[viewindex]=0) and (viewindex<8) do inc(viewindex);
 if viewindex=8 then viewindex:=0;
 displaybotinfo(0);
end;

procedure readyshieldopts;
begin
 genericrightside(shdbut);
 viewlevel:=1;
 viewindex:=1;
 viewmode:=4;
 displayshieldopts(6);
end;

procedure addlotstime(background, dayticks :Boolean; t: integer);
begin
   if ship.shield>ID_REFLECTIVEHULL then
      ship.battery:=ship.battery-round(weapons[ship.shield-ID_SHIELDS_OFFSET].energy*ship.shieldlevel/100);
   if ship.battery<31960 then ship.battery:=ship.battery+40 else ship.battery:=32000;
   if ship.battery<0 then
   begin
      tcolor:=94;
      println;
      print('COMPUTER: Secondary power failure...Shields powering down...');
      ship.shieldlevel:=0;
      ship.battery:=0;
   end;
   inc(ship.stardate[5],t);
   if ship.stardate[5]>99 then
   begin
      inc(ship.stardate[4],ship.stardate[5] div 100);
      ship.stardate[5]:=ship.stardate[5] mod 100;
      if ship.stardate[4]>19 then
      begin
	 if dayticks then
	    DayTick(background);
	 inc(ship.stardate[2],ship.stardate[4] div 20);
	 ship.stardate[4]:=ship.stardate[4] mod 20;
	 if ship.stardate[2]>19 then
	 begin
	    inc(ship.stardate[1],ship.stardate[2] div 20);
	    ship.stardate[2]:=ship.stardate[2] mod 20;
	    if ship.stardate[1]>19 then
	    begin
	       inc(ship.stardate[3],ship.stardate[1] div 20);
	       ship.stardate[1]:=ship.stardate[1] mod 20;
	    end;
	 end;
      end;
   end;
   mousehide;
   showtime;
   mouseshow;
   anychange:=true;
end;

procedure engage(x,y,z: integer);
var dist: real;
begin
   if not checkweight(false) then exit;
   if not chevent(11) then
   begin
      tcolor:=94;
      println;
      print('SCIENCE: Sir, that would not be wise. I suggest we first scan this planet.');
      exit;
   end;
   event(21);
   event(22);
   event(26);
   event(27);
   if (tempplan^[curplan].system=33) then event(25);
   if ship.damages[DMG_ENGINES]>25 then
   begin
      tcolor:=94;
      println;
      print('COMPUTER: Warning! Ship engines have sustained damage.');
      if not yesnorequest('Continue countdown?',0,31) then exit;
   end;
   if not targetready then
   begin
      tcolor:=94;
      println;
      print('NAVIGATION: No target computed!');
      exit;
   end;
   dist:=sqr((x-ship.posx)/10);
   dist:=dist + sqr((y-ship.posy)/10);
   dist:=dist + sqr((z-ship.posz)/10);
   dist:=sqrt(dist);
   if round(dist)<10 then dist:=10;
   if round(dist)>ship.fuel then
   begin
      println;
      tcolor:=94;
      print('NAVIGATION: Insufficient fuel!');
      exit;
   end;
   {$IFDEF DEMO}
   if (x>1249) or (y>1249) or (z>1249) then
   begin
      tcolor:=94;
      println;
      print('Outside Demo bounds, Alpha sector only.');
      exit;
   end;
   {$ENDIF}
   ship.fuel:=ship.fuel - round(dist);
   if viewmode2>0 then removestarmap;
   cleanright(true);
   tcolor:=31;
   setalertmode(ALRT_ALERT, true);
   println;
   print('ENGINEERING: Engaging..');
   redoscreen(x,y,z);
   setalertmode(ALRT_REST, true);
end;

procedure readyweaponinfo;
begin
 j:=0;
 for i:=1 to 10 do
  if ship.gunnodes[i]>0 then inc(j);
 if j=0 then
  begin
   removepanel;
   tcolor:=94;
   println;
   print('SECURITY: No weapons installed.');
   exit;
  end;
 genericrightside(nonebut);
 viewlevel:=0;
 viewindex:=1;
 while (viewindex<11) and (ship.gunnodes[viewindex]=0) do inc(viewindex);
 if viewindex=11 then viewindex:=0;
 viewmode:=2;
 tcolor:=191;
 bkcolor:=5;
 printxy(168,27,'Gun Node Information');
 displayweaponinfo(0);
end;

procedure readylongscan;
begin
 setfillstyle(1,0);
 setcolor(0);
 mousehide;
 pieslice(85,86,0,360,40);
 setcolor(12);
 circle(85,86,40);
 revgraybutton(35,24,135,44);
 for i:=25 to 43 do
  scr_fillchar(screen[i,36],99,0);
 randseed:=tempplan^[curplan].seed;
 if showplanet then
  begin
   x1:=random(628)/100;
   i:=random(20)+8;
   x:=round(cos(x1)*i)+85;
   y:=round(sin(x1)*i)+86;
   for j:=0 to 35 do
    begin
     x1:=random(628)/100;
     i:=random(7);
     screen[round(i*sin(x1))+y,round(i*cos(x1))+x]:=random(31);
    end;
  end;
 for j:=0 to random(45)+15 do
  begin
   x1:=random(628)/100;
   i:=random(35);
   screen[round(i*sin(x1))+86,round(i*cos(x1))+85]:=random(31);
  end;
 viewindex3:=135;
 randomize;
 for i:=18 to 123 do
  move(screen[i,27],starmapscreen^[i,27],29*4);
 mouseshow;
 displaylongscan;
end;

procedure removesystem(erase: boolean);
begin
 if (showplanet) and (sphere<>3) then sprinkle2(15,25,280,116,19)
  else sprinkle(15,25,280,116,19);
 if (panelon) and (erase) then removepanel;
 viewmode:=0;
 glowindex:=0;
end;

procedure readysystem;
begin
 viewindex2:=0;
 cx:=142;
 cy:=65;
 for j:=1 to nearbymax do
  if (systems[nearby[j].index].x=ship.posx) and
     (systems[nearby[j].index].y=ship.posy) and
     (systems[nearby[j].index].z=ship.posz) then
    begin
     viewindex2:=j;
     j:=nearbymax;
    end;
 if viewindex2=0 then
  begin
   println;
   tcolor:=94;
   print('NAVIGATION: Not near a system.');
   exit;
  end;
 cleanright(false);
 if (viewmode2>0) then removestarmap;
 mousehide;
 graybutton(15,25,279,115);
 showpanel(sys2but);
 viewmode:=8;
 viewindex:=ship.orbiting;
 viewlevel:=2;
 viewindex2:=nearby[viewindex2].index;
 tcolor:=191;
 bkcolor:=5;
 printxy(12,26,'System:');
 printxy(12,32,systems[viewindex2].name);
 printxy(13,102,'Planet:');
 printxy(238,102,'Target:');
 printplanet(13,108,viewindex2,ship.orbiting);
 printplanet(233,108,viewindex2,viewindex);
 mouseshow;
 displaysystem(0);
end;

procedure readylogs;
begin
 genericrightside(logbut);
 viewlevel:=0;
 viewmode:=7;
 viewindex:=1;
 viewindex3:=0;
 if showplanet then viewindex:=tempplan^[curplan].system
  else
   begin
    while (systems[viewindex].visits=0) and (viewindex<251) do inc(viewindex);
    if viewindex=251 then viewindex:=0;
   end;
 bkcolor:=5;
 tcolor:=191;
 printxy(166,27,' Ship Logs: Systems  ');
 displaylogs(0);
end;

procedure graypalin;
var a: real;
    b: integer;
    temppal,colors2: paltype;
begin
 for j:=0 to 255 do
  begin
   a:=colors[j,1]*0.30 + colors[j,2]*0.59 + colors[j,3]*0.11;
   for i:=1 to 3 do temppal[j,i]:=round(a);
  end;
 colors2[0,1]:=0;       // to turn off warnings, variables are actually correctly initialized by function below
 move(colors,colors2,sizeof(paltype));
 for b:=1 to 15 do
  begin
   for j:=0 to 255 do
    for i:=1 to 3 do
     colors2[j,i]:=colors[j,i]+round((temppal[j,i]-colors[j,i])/15*b);
   set256colors(colors2);
   delay(tslice*3);
  end;
end;

procedure graypalout;
var a: real;
    b: integer;
    temppal,colors2: paltype;
begin
 for j:=0 to 255 do
  begin
   a:=colors[j,1]*0.30 + colors[j,2]*0.59 + colors[j,3]*0.11;
   for i:=1 to 3 do temppal[j,i]:=round(a);
  end;
 colors2[0,1]:=0;       // to turn off warnings, variables are actually correctly initialized by function below
 move(temppal,colors2,sizeof(paltype));
 for b:=1 to 15 do
  begin
   for j:=0 to 255 do
    for i:=1 to 3 do
     colors2[j,i]:=temppal[j,i]+round((colors[j,i]-temppal[j,i])/15*b);
   set256colors(colors2);
   delay(tslice*2);
  end;
 set256colors(colors);
end;

procedure lowershields;
begin
 if ship.shield<=ID_REFLECTIVEHULL then exit;	{ only makes sense for powered shields }
 println;
 tcolor:=63;
 print('SECURITY: Lowering shields...');
 graypalin;
 setalertmode(ALRT_ALERT, true);
 if viewmode=1 then displaystatus else checkstats;
 delay(tslice*3);
 graypalout;
 if ship.shieldlevel=ship.shieldopt[SHLD_ALERT_WANT] then
  begin
   tcolor:=63;
   print('Complete.');
  end;
end;

procedure raiseshields;
begin
 println;
 tcolor:=94;
 if ship.shield<=ID_REFLECTIVEHULL then
  begin
   print('SECURITY: No shield to raise.');
   exit;
  end;
 if ship.damages[DMG_SHIELD]>59 then
  begin
   print('Shield integrity compromised...needs repair.');
   ship.shieldlevel:=0;
   if viewmode=1 then displaystatus else checkstats;
   exit;
  end
 else if ship.damages[DMG_SHIELD]>25 then
  begin
   print('SECURITY: Shield unstable...');
   if (random(40)+20)<ship.damages[DMG_SHIELD] then
    begin
     print('Failed to raise shield.');
     ship.shieldlevel:=0;
     if viewmode=1 then displaystatus else checkstats;
     exit;
    end;
  end;
 print('SECURITY: Raising shields...');
 graypalin;
 setalertmode(ALRT_COMBAT, true);
 if viewmode=1 then displaystatus else checkstats;
 delay(tslice*3);
 graypalout;
 print('Ready.');
 println;
 print('Combat mode activated.');
 println;
 tcolor:=31;
 print('Crew standing by.');
end;

procedure powerdownweapons;
begin
 if not ship.armed then exit;
 println;
 ship.armed:=false;
 tcolor:=63;
 print('SECURITY: Powering down weapons...');
 graypalin;
 setalertmode(ALRT_ALERT, false);
 for j:=1 to 10 do
  if ship.gunnodes[j]>0 then
   begin
    inc(ship.battery,weapons[ship.gunnodes[j]].energy);
    if (ship.battery>32000) or (ship.battery<0) then ship.battery:=32000;
   end;
 if viewmode=1 then displaystatus else checkstats;
 delay(tslice*3);
 graypalout;
 print('Complete.');
end;

procedure armweapons;
begin
 tcolor:=94;
 println;
 if ship.damages[DMG_WEAPONS]>59 then
  begin
   print('Weapon control compromised...needs repair');
   ship.armed:=false;
   if viewmode=1 then displaystatus else checkstats;
   exit;
  end
 else if ship.damages[DMG_WEAPONS]>25 then
  begin
   print('SECURITY: Weapon control unstable...');
   if (random(40)+20)<ship.damages[DMG_SHIELD] then
    begin
     print('Failed to arm weapons.');
     ship.armed:=false;
     if viewmode=1 then displaystatus else checkstats;
     exit;
    end;
  end;
 j:=0;
 for i:=1 to 10 do
  if ship.gunnodes[i]>0 then inc(j);
 if j=0 then
  begin
   print('SECURITY: No weapons installed!');
   exit;
  end;
 print('SECURITY: Arming weapons...');
 graypalin;
 setalertmode(ALRT_COMBAT, false);
 ship.armed:=true;
 for j:=1 to 10 do
  if (ship.gunnodes[j]>0) and (ship.battery>=weapons[ship.gunnodes[j]].energy) then
   dec(ship.battery,weapons[ship.gunnodes[j]].energy);
 if ship.battery<0 then
  begin
   ship.armed:=false;
   tcolor:=94;
   println;
   print('COMPUTER: Secondary power failure...Weapons powering down...');
   ship.shieldlevel:=0;
   ship.battery:=0;
   exit;
  end;
 if viewmode=1 then displaystatus else checkstats;
 delay(tslice*3);
 graypalout;
 print('Ready.');
 println;
 print('Combat mode activated.');
 println;
 tcolor:=31;
 print('Crew standing by.');
end;

procedure removestarmap;
begin
 viewmode2:=0;
 mousehide;
 for j:=1 to 5 do
  begin
   plainfadearea(27,11,143,123,-1);
   delay(tslice*2);
  end;
 if (not showplanet) or (sphere=3) then sprinkle(24,9,149,126,17)
  else sprinkle2(24,9,148,133,13);
 mouseshow;
 glowindex:=0;
end;

procedure readystarmap(mode: integer);
begin
 mousehide;
 setcolor(0);
 line(146,39,146,96);
 line(147,49,147,86);
 line(148,59,148,76);
 for i:=10 to 125 do
  scr_fillchar(screen[i,25],119,5);
 setcolor(10);
 line(25,9,145,9);
 line(25,9,25,126);
 setcolor(9);
 line(26,10,144,10);
 line(26,10,26,124);
 setcolor(1);
 line(145,9,145,126);
 line(25,126,145,126);
 setcolor(2);
 line(144,10,144,125);
 line(26,125,144,125);
 setcolor(5);
 line(27,124,143,124);
 tcolor:=191;
 bkcolor:=5;
 case mode of
  1: printxy(58,11,'Star Map');
  2: printxy(33,11,'Direction of Travel');
  3: printxy(40,11,'Short Range Scan');
  4: printxy(43,11,'Long Range Scan');
 end;
 bkcolor:=3;
 viewmode2:=mode;
 fillchar(starmapscreen^,sizeof(starmapscreen^),5);
 mouseshow;
 t1:=6.28;
end;

procedure readystatus;
begin
 viewmode:=1;
 mousehide;
 for j:=1 to 5 do
  begin
   plainfadearea(165,25,279,117,1);
   delay(tslice*2);
  end;
 for i:=25 to 117 do
  scr_fillchar(screen[i,165],115,5);
 setcolor(2);
 line(279,25,279,117);
 line(165,117,279,117);
 line(165,35,278,35);
 setcolor(10);
 line(165,25,279,25);
 line(165,25,165,117);
 line(165,36,279,36);
 screen[35,165]:=2;
 screen[25,279]:=6;
 screen[117,165]:=6;
 screen[35,165]:=6;
 screen[36,279]:=6;
 tcolor:=191;
 bkcolor:=5;
 printxy(192,27,'Ship Stats');
 for j:=0 to 3 do
  revgraybutton(172,45+j*20,272,55+j*20);
 printxy(181,38,'Hull Integrity');
 printxy(184,58,'Primary Power');
 printxy(179,78,'Secondary Power');
 printxy(187,98,'Shield Level');
 mouseshow;
 displaystatus;
 bkcolor:=3;
end;

procedure readyshipinfo;
begin
 mousehide;
 graybutton(15,25,279,115);
 revgraybutton(16,26,191,102);
 revgraybutton(196,77+6,274,113-1);
 setcolor(2);
 line(220,26,220,69+6);
 line(191,69+6,278,69+6);
 setcolor(10);
 line(221,26,221,69+6);
 line(192,70+6,279,70+6);
 screen[69+6,191]:=6;
 screen[70+6,279]:=6;
 screen[69+6,221]:=6;
 viewmode:=9;
 displayship2(17,27);
 tcolor:=191;
 bkcolor:=5;
 printxy(13,106,'Model:'+shipnames[ship.shiptype[SHPTYP_HEAVYNESS]-1]+' '+
  shipnames[ship.shiptype[SHPTYP_PURPOSE]+2]+' '+shipnames[ship.shiptype[SHPTYP_VESSEL]+5]);
 printxy(189,26,'X Loc');
 printxy(189,32,'Y Loc');
 printxy(189,38,'Z Loc');
 printxy(192,44,'Hull');
 printxy(192,50,'Fuel');
 printxy(192,56,'Batt');
 printxy(189,62,'Cargo');
 printxy(189,68,'Accel');
 printxy(216,70+6,'Damage');
 mouseshow;
 displayshipinfo;
end;

procedure readysysteminfo;
begin
 genericrightside(sysbut);
 viewlevel:=1;
 viewmode:=3;
 displaysysteminfo(1);
end;

procedure readyhistory;
var x: nearbytype;
begin
 for j:=1 to nearbymax do
  for i:=j to nearbymax do
   if ((nearby[j].index=0) or (systems[nearby[i].index].datey<systems[nearby[j].index].datey))
    and (nearby[i].index<>0)
   then
    begin
     x:=nearby[i];
     nearby[i]:=nearby[j];
     nearby[j]:=x;
     x:=nearbybackup[i];
     nearbybackup[i]:=nearbybackup[j];
     nearbybackup[j]:=x;
    end;
 readystarmap(2);
 t1:=6.28;
 displayhistorymap;
 anychange:=true;
end;

procedure targetstar(tarx,tary: integer);
begin
 targetready:=false;
 target:=0;
 for j:=1 to nearbymax do if nearby[j].index<>0 then
  begin
   x1:=85+(nearby[j].x*480/(500-nearby[j].z));
   y1:=70+(nearby[j].y*480/(500-nearby[j].z));
   x:=round(x1);
   y:=round(y1);
   if (abs(x-tarx)<8) and (abs(y-tary)<8) then
      begin
       target:=j;
       j:=nearbymax;
      end;
  end;
 if viewmode=3 then displaysysteminfo(0);
end;

procedure plotstars;
begin
 for j:=1 to nearbymax do
  if nearby[j].index<>0 then
   begin
    x:=systems[nearby[j].index].x - ship.posx;
    y:=systems[nearby[j].index].y - ship.posy;
    x:=(x div 12) + 82;
    y:=(y div 12) + 70;
    screen[y,x]:=31;
    screen[y+1,x]:=170;
    screen[y-1,x]:=170;
    screen[y,x+1]:=170;
    screen[y,x-1]:=170;
   end;
 screen[70,82]:=94;
 screen[70,81]:=84;
 screen[70,83]:=84;
 screen[69,82]:=84;
 screen[71,82]:=84;
 for j:=1 to nearbymax do
  if nearby[j].index<>0 then
   begin
    x:=systems[nearby[j].index].x - ship.posx;
    y:=systems[nearby[j].index].z - ship.posz;
    x:=(x div 12) + 222;
    y:=(y div 12) + 70;
    screen[y,x]:=31;
    screen[y+1,x]:=170;
    screen[y-1,x]:=170;
    screen[y,x+1]:=170;
    screen[y,x-1]:=170;
   end;
 screen[70,222]:=94;
 screen[70,221]:=84;
 screen[70,223]:=84;
 screen[69,222]:=84;
 screen[71,222]:=84;
end;

procedure removestars;
begin
 setwritemode(xorput);
 setcolor(120);
 index:=tslice div 8;
 for j:=110 downto 1 do
  begin
   line(167+j,27,167+j,113);
   line(27+j,27,27+j,113);
   delay(index);
   line(167+j,27,167+j,113);
   line(27+j,27,27+j,113);
  end;
 setwritemode(copyput);
 for j:=1 to 110 do
  begin
   setcolor(118);
   line(167+j,27,167+j,113);
   line(27+j,27,27+j,113);
   setcolor(4);
   delay(index);
   line(167+j,27,167+j,113);
   line(27+j,27,27+j,113);
   if j=56 then
    begin
     screen[70,82]:=94;
     screen[70,81]:=84;
     screen[70,83]:=84;
     screen[69,82]:=84;
     screen[71,82]:=84;
     screen[70,222]:=94;
     screen[70,221]:=84;
     screen[70,223]:=84;
     screen[69,222]:=84;
     screen[71,222]:=84;
    end;
   x:=systems[nearby[target].index].x-ship.posx;
   x:=(x div 12) + 82;
   if (x=j+26) then
    begin
     y:=systems[nearby[target].index].y-ship.posy;
     y:=(y div 12) + 70;
     screen[y,x]:=31;
     screen[y+1,x]:=170;
     screen[y-1,x]:=170;
     screen[y,x+1]:=170;
     screen[y,x-1]:=170;
     y:=systems[nearby[target].index].z-ship.posz;
     x:=x+140;
     y:=(y div 12) + 70;
     screen[y,x]:=31;
     screen[y+1,x]:=170;
     screen[y-1,x]:=170;
     screen[y,x+1]:=170;
     screen[y,x-1]:=170;
    end;
   printxy(29,105,'Side');
   printxy(169,105,'Top');
  end;
end;

procedure setuptarget;
var c,lx,ly,rx,ry,x1,x2,y1,y2,done: integer;
begin
 c:=tslice*2;
 x1:=systems[nearby[target].index].x-ship.posx;
 x1:=(x1 div 12) + 82;
 x2:=x1+140;
 y1:=systems[nearby[target].index].y-ship.posy;
 y1:=(y1 div 12) + 70;
 y2:=systems[nearby[target].index].z-ship.posz;
 y2:=(y2 div 12) + 70;
 lx:=82; rx:=222;
 ly:=70; ry:=70;
 setwritemode(xorput);
 setcolor(120);
 repeat
  done:=0;
  if rx<x2 then inc(rx)
   else if rx>x2 then dec(rx)
   else inc(done);
  if lx<x1 then inc(lx)
   else if lx>x1 then dec(lx)
   else inc(done);
  if ry<y2 then inc(ry)
   else if ry>y2 then dec(ry)
   else inc(done);
  if ly<y1 then inc(ly)
   else if ly>y1 then dec(ly)
   else inc(done);
  line(rx,27,rx,113);
  line(lx,27,lx,113);
  line(27,ly,137,ly);
  line(167,ry,277,ry);
  delay(c);
  line(rx,27,rx,113);
  line(lx,27,lx,113);
  line(27,ly,137,ly);
  line(167,ry,277,ry);
 until done=4;
 for j:=1 to 10 do
  begin
   line(rx,27,rx,113);
   line(lx,27,lx,113);
   line(27,ly,137,ly);
   line(167,ry,277,ry);
   delay(tslice*5);
  end;
 for i:=1 to 2 do
  begin
   for j:=8 downto 1 do
    begin
     screen[y1-j,x1-j]:=13+j*3;
     screen[y1+j,x1-j]:=13+j*3;
     screen[y1-j,x1+j]:=13+j*3;
     screen[y1+j,x1+j]:=13+j*3;
     screen[y2-j,x2-j]:=13+j*3;
     screen[y2+j,x2-j]:=13+j*3;
     screen[y2-j,x2+j]:=13+j*3;
     screen[y2+j,x2+j]:=13+j*3;
     delay(tslice*4);
     screen[y1-j,x1-j]:=4;
     screen[y1+j,x1-j]:=4;
     screen[y1-j,x1+j]:=4;
     screen[y1+j,x1+j]:=4;
     screen[y2-j,x2-j]:=4;
     screen[y2+j,x2-j]:=4;
     screen[y2-j,x2+j]:=4;
     screen[y2+j,x2+j]:=4;
    end;
 end;
 setwritemode(copyput);
end;

procedure readytarget;
begin
 if target=0 then
  begin
   tcolor:=94;
   println;
   print('No target selected!');
   exit;
  end;
 if (viewmode2>0) then removestarmap;
 cleanright(true);
 println;
 tcolor:=31;
 print('Targeting..');
 mousehide;
 for i:=1 to 6 do
  begin
   plainfadearea(167,26,277,113,1);
   plainfadearea(27,26,137,113,1);
   delay(tslice*3);
  end;
 tcolor:=31;
 bkcolor:=6;
 printxy(29,105,'Side');
 printxy(169,105,'Top');
 plotstars;
 delay(tslice*40);
 bkcolor:=4;
 removestars;
 delay(tslice*20);
 setuptarget;
 delay(tslice*40);
 tcolor:=31;
 bkcolor:=3;
 print('LOCKED');
 for i:=24 to 116 do
  begin
   y:=i+backgry;
   if y>199 then y:=y-199;
   for j:=24 to 27 do
    begin
     x:=j+backgrx;
     if x>319 then x:=x-319;
     screen[i,j]:=backgr^[y,x];
    end;
   if (showplanet) and (sphere<>3) then
    for j:=28 to 141 do
     screen[i,j]:=planet^[i-12,j-27]
    else
     for j:=28 to 141 do
      begin
       x:=j+backgrx;
       if x>319 then x:=x-319;
       screen[i,j]:=backgr^[y,x];
      end;
  end;
 for i:=24 to 116 do
  begin
   y:=i+backgry;
   if y>199 then y:=y-199;
   for j:=164 to 281 do
    begin
     x:=j+backgrx;
     if x>319 then x:=x-319;
     screen[i,j]:=backgr^[y,x];
    end;
  end;
 mouseshow;
 targetready:=true;
end;

procedure showresearchlights;
begin
 for j:=1 to 3 do
  if ship.research and (1 shl j)>0 then
   begin
    screen[141+j*12,181]:=63;
    screen[142+j*12,181]:=63;
   end
  else
   begin
    screen[141+j*12,181]:=95;
    screen[142+j*12,181]:=95;
   end;
 for j:=4 to 6 do
  if ship.research and (1 shl j)>0 then
   begin
    screen[105+j*12,299]:=63;
    screen[106+j*12,299]:=63;
   end
  else
   begin
    screen[105+j*12,299]:=95;
    screen[106+j*12,299]:=95;
   end;
end;

procedure ToggleResearch(face: integer);
begin
   ship.research := ship.research xor (1 shl face);
   tcolor:=63;
   println;
   if ship.research and (1 shl face)<>0 then
      print(crewtitles[face]+': Initiating research.')
   else
      print(crewtitles[face]+': Cancelling research.');
   showresearchlights;
end;

procedure contactfailure;
begin
 println;
 tcolor:=94;
 print('SCIENCE: Communications too damaged!');
end;

procedure processcube(face: integer);
var
   i, j : Integer;
begin
 {145,215}
 case face of
  19,20,22,23: plainfadearea(232,145,265,174,1);
  32,35: plainfadearea(249,160,265,189,1);
  1,2: plainfadearea(232,145,265,159,1);
  0,3: plainfadearea(215,145,231,174,1);
  4,5,40,41: plainfadearea(232,160,265,174,1);
  27,28: plainfadearea(215,145,248,159,1);
  else
   begin
    a:=face mod 9;
    j:=a mod 3;
    i:=a div 3;
    plainfadearea(215+j*17,145+i*15,231+j*17,159+i*15,1);
   end;
 end;
 case face of
   {psy}
   0,3: psyche;
   1,2: if ship.damages[DMG_COMM]>39 then contactfailure
         else continuecontact(false);
   4,5: if ship.damages[DMG_COMM]>39 then contactfailure
         else continuecontact(true);
   6: crewstats;
   7: ToggleResearch(1);
   8: conversewithcrew;
   {eng}
   9: if viewmode<>5 then
       begin
        cleanright(false);
        readydamagecontrol;
       end;
  10: if viewmode<>10 then
       begin
        if viewmode2>0 then removestarmap;
        cleanright(false);
        readyconfigure;
       end;
  11: if viewmode<>11 then readybots;
  12: if viewmode<>4 then
       begin
        cleanright(false);
        readyshieldopts;
       end;
  13: computerlogs(255);
  14: {if checkweight then} creation;
  15: if viewmode<>2 then
       begin
        cleanright(false);
        readyweaponinfo;
       end;
  16: ToggleResearch(2);
  17: inventory;
  {sci}
  18: if viewmode2<>3 then
       begin
        if (viewmode>7) and (viewmode<>11) then removesystem(true);
        if viewmode2>0 then removestarmap;
        readystarmap(3);
        displayshortscan;
       end;
  19,20,22,23:
       if (showplanet) then
       begin
	  if (tempplan^[curplan].state <> 7) then
	  begin
	     if (incargo(ID_PROBOT)>0) then
		exploreplanet
	     else begin
		tcolor:=94;
		println;
		print('SCIENCE: We have no probots.');
	     end;
	  end else begin
	     if (incargo(ID_STARDIVER)>0) then
		exploreplanet
	     else begin
		tcolor:=94;
		println;
		print('SCIENCE: We have no probots that can withstand a star.');
	     end;
	  end;
       end else begin
	  tcolor:=94;
	  println;
	  print('SCIENCE: We are not near a planet.');
       end;
  21: if viewmode2<>4 then
       begin
        if (viewmode>7) and (viewmode<>11) then removesystem(true);
        if viewmode2>0 then removestarmap;
        readystarmap(4);
        readylongscan;
       end;
  24: if viewmode<>8 then readysystem;
  25: ToggleResearch(3);
  26: if viewmode<>7 then
       begin
        cleanright(false);
        readylogs;
       end;
  {sec}
  27,28: if (ship.wandering.alienid<16000) and (action<>WNDACT_RETREAT) and			{ retreat }
       ((abs(ship.wandering.relx)<8000) or (abs(ship.wandering.rely)<8000) or
       (abs(ship.wandering.relz)<8000)) then
       begin
        tcolor:=31;
        action:=WNDACT_RETREAT;
        println;
        print('SECURITY: Attempting to evade aliens.');
       end
      else if (action<>WNDACT_RETREAT) then
       begin
        tcolor:=94;
        action:=WNDACT_NONE;
        println;
        print('SECURITY: No aliens on our scopes.');
       end;
  29: begin											{ launch drones }
	 j := 0;
	 for i := 1 to 10 do
	 begin
	    if ship.gunnodes[i] > 0 then
	    begin
	       inc(j);
	    end;
	 end;
	 if j <= 0 then
	 begin
	    tcolor:=31;
	    action:=WNDACT_RETREAT;
	    println;
	    print('SECURITY: We have no weapons installed!');
	 end else if ship.wandering.alienid < 16000 then
	 begin
	    tcolor:=31;
	    action:=WNDACT_RETREAT;
	    println;
	    print('SECURITY: There is an alien vessel nearby. This is not the time for war exercises.');
	 end else if yesnorequest('Launch Combat Drones?',0,31) then
	 begin
	    getspecial(13,1013);
	    createwandering(WNDORDER_ATTACK);
	    ship.wandering.relx:=400;
	    ship.wandering.rely:=400;
	    ship.wandering.relz:=400;
	 end;
      end;
  32,35: if (ship.wandering.alienid<16000) and (action<>WNDACT_ATTACK) and			{ attack }
             ((abs(ship.wandering.relx)<8000) or (abs(ship.wandering.rely)<8000) or
              (abs(ship.wandering.relz)<8000)) then
       begin
        tcolor:=31;
        action:=WNDACT_ATTACK;
        println;
        print('SECURITY: Attempting to close and attack aliens.');
       end
      else if (action<>WNDACT_ATTACK) then
       begin
        tcolor:=94;
        action:=WNDACT_NONE;
        println;
        print('SECURITY: No aliens on our scopes.');
       end;
  30: if (ship.shieldlevel=ship.shieldopt[SHLD_COMBAT_WANT]) and (alert=ALRT_COMBAT) then lowershields	{ raise/lower shields }
       else raiseshields;
  31: if (ship.wandering.alienid<16000) and (action<>WNDACT_MASKING) and			{ masking }
       ((abs(ship.wandering.relx)<8000) or (abs(ship.wandering.rely)<8000) or
        (abs(ship.wandering.relz)<8000)) then
       begin
        tcolor:=31;
        action:=WNDACT_MASKING;
        println;
        print('SECURITY: Attempting to mask ship.');
       end
      else if (action<>WNDACT_MASKING) then
       begin
        tcolor:=94;
        action:=WNDACT_NONE;
        println;
        print('SECURITY: No aliens on our scopes.');
       end;
  33: if ship.armed then powerdownweapons else armweapons;					{ arm/disarm weapons }
  34: ToggleResearch(4);									{ research }
  {ast}
  36: if viewmode2<>1 then
        begin
         if (viewmode>7) and (viewmode<>11) then removesystem(true);
         if viewmode2>0 then removestarmap;
         readystarmap(1);
         displaystarmap;
        end;
  37: if viewmode<>1 then
       begin
        cleanright(true);
        readystatus;
       end;
  38: if viewmode<>9 then
       begin
        if viewmode2>0 then removestarmap;
        cleanright(true);
        readyshipinfo;
       end;
  39: if chevent(11) then sectorinfo
       else
        begin
         println;
         tcolor:=94;
         print('NAVIGATION: Sir, we know nothing about this part of the galaxy.');
        end;
  40,41: begin
       readytarget;
      end;
  42: if viewmode2<>2 then
       begin
        if (viewmode>7) and (viewmode<>11) then removesystem(true);
        if viewmode2>0 then removestarmap;
        readyhistory;
       end;
  43: ToggleResearch(5);
  44: if viewmode<>3 then
       begin
        cleanright(false);
        readysysteminfo;
       end;
  {med}
  45: if viewmode<>6 then
       begin
        cleanright(false);
        readyoptions;
       end;
  46: savegamedata(0,31);
  47: if ship.damages[DMG_LIFESUPPORT]>39 then lifesupportfailure
       else encodecrew(26);
  48:  if yesnorequest('Initiate Time Burst?',0,31) then restcrew;
  49: if loadgamedata(false) then
       begin
        reloading:=true;
        quit:=true;
        fillchar(colors,sizeof(paltype),0);
        set256colors(colors);
       end;
  50: if ship.damages[DMG_LIFESUPPORT]>39 then lifesupportfailure
       else decodecrew;
  51: begin
       if viewmode2>0 then removestarmap;
       cleanright(true);
      end;
  52: ToggleResearch(6);
  53: if yesnorequest('Do you want to quit?',0,31) then quit:=true;
 end;
 case face of
  19,20,22,23: plainfadearea(232,145,265,174,-1);
  32,35: plainfadearea(249,160,265,189,-1);
  1,2: plainfadearea(232,145,265,159,-1);
  0,3: plainfadearea(215,145,231,174,-1);
  4,5,40,41: plainfadearea(232,160,265,174,-1);
  27,28: plainfadearea(215,145,248,159,-1);
  else
   begin
    a:=face mod 9;
    j:=a mod 3;
    i:=a div 3;
    plainfadearea(215+j*17,145+i*15,231+j*17,159+i*15,-1);
   end;
 end;
end;

begin
end.
