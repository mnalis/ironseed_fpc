unit crewinfo;
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
   Crew Manipulation unit for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

{$O+}

interface

procedure crewstats;

implementation

uses data, utils_, gmouse, utils2, weird, modplay;

type
 hologramtype= array[35..63,84..120] of byte;
 msgarraytype= array[0..8,0..8,0..39] of byte;
 littlemsgarraytype= array[0..7,0..4,0..15] of byte;
 mousecursors= array[0..6] of mouseicontype;
var
 crewindex,i,j,a,graphindex,msgindex,mouseindex: integer;
 holo: ^hologramtype;
 msgs: ^msgarraytype;
 littlemsgs: ^littlemsgarraytype;
 mcursor: ^mousecursors;

procedure showportrait(n: integer);
var s: string[2];
    portrait: ^portraittype;
begin
 new(portrait);
 str(n:2,s);
 if n<10 then s[1]:='0';
 loadscreen(loc_data()+'image'+s,portrait);
 for i:=0 to 69 do
  scrto_move(portrait^[i],screen[i+16,220],70);
 dispose(portrait);
end;

procedure displaylevel(x: integer);
begin
 y:=309;
 for i:=1 to 5 do
  begin
   y:=y-8;
   if x mod 2=1 then screen[101,y]:=92 else screen[101,y]:=124;
   x:=x div 2;
  end;
end;

procedure drawstats(num: integer);
var b,c,d: integer;
    part: real;
begin {120,37,294,112}
 a:=ship.crew[num].phy;
 b:=ship.crew[num].men;
 c:=ship.crew[num].emo;
 part:=36/100;
 for i:=14 to 88 do
  scr_fillchar(screen[i,16],185,0);
 for i:=35 to 63 do
  scrto_move(holo^[i,84],screen[i,84],9*4);
 moveto(16,50);
 for j:=17 to 200 do
 begin
  inc(j,2);
  if j>200 then exit;
   setcolor((j-16) mod 32+128);
   d:=random(6);
   case d of
    0:i:=round(a*part);
    1:i:=round(b*part);
    2:i:=round(c*part);
    3:i:=-round(a*part);
    4:i:=-round(b*part);
    5:i:=-round(c*part);
   end;
   lineto(j,i+51);
 end;
end;

procedure displaycursor;
begin
 for j:=1 to 3 do
  begin
   if crewindex=j then a:=63 else a:=104;
   screen[j*3+139,303]:=a;
   screen[j*3+139,304]:=a;
  end;
 for j:=4 to 6 do
  begin
   if crewindex=j then a:=63 else a:=104;
   screen[j*3+130,310]:=a;
   screen[j*3+130,311]:=a;
  end;
end;

procedure redraw;
var
    s: string[20];
    crewfile: file of crewdatatype;
    crewdata: crewdatatype;
begin
 mousehide;
 drawstats(crewindex);
 assign(crewfile,loc_data()+'crew.dta');
 reset(crewfile);
 if ioresult<>0 then errorhandler('crew.dta',1);
 seek(crewfile,ship.crew[crewindex].index-1);
 if ioresult<>0 then errorhandler('crew.dta',5);
 read(crewfile,crewdata);
 if ioresult<>0 then errorhandler('crew.dta',5);
 close(crewfile);
 showportrait(ship.crew[crewindex].index);
 s:=crewdata.name;
 i:=20;
 while (i>1) and (s[i]=' ') do dec(i);
 s[0]:=chr(i);
 for i:=103 to 108 do
  scr_fillchar(screen[i,121],119,0);
 printxy(121+(120-length(s)*6) div 2,103,s);
 for a:=0 to 9 do
  printxy(0,130+a*6,crewdata.desc[a]);
 str(ship.crew[crewindex].xp:10,s);
 for i:=1 to 7 do if s[i]=' ' then s[i]:='0';
 printxy(198,120,s);
 str(ship.crew[crewindex].level:2,s);
 displaylevel(ship.crew[crewindex].level);
 printxy(154,120,s);
 j:=ship.crew[crewindex].san;
 if j=0 then j:=1;
 if j>100 then j:=100 else if j<1 then j:=0;
 t1:=25/(j*0.68);
 for i:=26 to 26+round(j*0.68) do
  begin
   screen[i,309]:=round((i-26)*t1)+70;
   screen[i,310]:=round((i-26)*t1)+70;
  end;
 if j<100 then
  for i:=27+round(j*0.67) to 94 do
   begin
    screen[i,309]:=0;
    screen[i,310]:=0;
   end;
 displaycursor;
 mouseshow;
end;

procedure adjustgraph;
begin
 dec(graphindex);
 if graphindex=0 then graphindex:=31;
 i:=graphindex;
 for j:=0 to 31 do
  begin
   inc(i);
   if i>31 then i:=0;
   colors[j+128]:=colors[64+i];
  end;
end;

procedure readydata;
begin
 oldt1:=t1;
 mousehide;
 compressfile(loc_tmp()+'current',@screen);
 {fading;}
 fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);
 playmod(true,'sound/CREWCOMM.MOD');
 loadscreen(loc_data()+'char2',@screen);
 new(holo);
 new(msgs);
 new(mcursor);
 new(littlemsgs);
 for a:=0 to 8 do
  for i:=0 to 8 do
   scrfrom_move(screen[(a div 3)*10+145+i,(a mod 3)*40+10],msgs^[a,i],10*4);
 for a:=0 to 7 do
  for i:=0 to 4 do
   scrfrom_move(screen[(a div 2)*10+145+i,(a mod 2)*20+130],littlemsgs^[a,i],4*4);
 for a:=0 to 6 do
  for i:=0 to 15 do
   scrfrom_move(screen[i+180,10+a*17],mcursor^[a,i],4*4);
 for i:=130 to 196 do
  scr_fillchar(screen[i,4],262,0);
 for i:=35 to 63 do
  scrfrom_move(screen[i,84],holo^[i,84],9*4);
 graphindex:=1;
 adjustgraph;
 crewindex:=1;
 mouseindex:=0;
 displaycursor;
 tcolor:=170;
 bkcolor:=0;
 redraw;
 {fadein;}
 mouseshow;
 done:=false;
 msgindex:=32;
end;

procedure findmouse;
var before: integer;
begin
 if not mouse.getstatus then exit;
 before:=crewindex;
 case mouse.x of
  280..297: case mouse.y of
             146..160: if crewindex=1 then crewindex:=6 else dec(crewindex);
             162..176: if crewindex=6 then crewindex:=1 else inc(crewindex);
            end;
  302..311: if (mouse.y>154) and (mouse.y<170) then done:=true;
 end;
 if before<>crewindex then redraw;
 idletime:=0;
end;

procedure processkey;
var ans: char;
    before: integer;
begin
 ans:=readkey;
 before:=crewindex;
 case ans of
  #27: done:=true;
   #0: begin
        ans:=readkey;
        case ans of
         #72: if crewindex=1 then crewindex:=6 else dec(crewindex);
         #80: if crewindex=6 then crewindex:=1 else inc(crewindex);
        end;
       end;
  '`': bossmode;
 end;
 if before<>crewindex then redraw;
 idletime:=0;
end;

procedure displaymsg;
begin
 a:=random(9);
 mousehide;
 for i:=0 to 8 do
  scrto_move(msgs^[a,i],screen[122+i,273],10*4);
 mouseshow;
end;

procedure displaylittlemsgs;
begin
 a:=random(8);
 mousehide;
 if msgindex mod 2=0 then
  begin
   for i:=0 to 4 do
    scrto_move(littlemsgs^[a,i],screen[133+i,273],4*4);
  end
 else
  begin
   for i:=0 to 4 do
    scrto_move(littlemsgs^[a,i],screen[133+i,296],4*4);
  end;
 mouseshow;
end;

procedure mainloop;
begin
 repeat
  palettedirty := true;
  fadestep(FADESTEP_STEP);
  findmouse;
  if fastkeypressed then processkey;
  inc(idletime);
  if idletime=maxidle then screensaver;
  adjustgraph;
  {set256colors(colors);}
  if mouseindex<6 then inc(mouseindex) else mouseindex:=0;
  mousehide;
  mousesetcursor(mcursor^[mouseindex]);
  mouseshow;
  if msgindex<32 then inc(msgindex) else msgindex:=0;
  if msgindex=0 then displaymsg
  else displaylittlemsgs;
  delay(tslice*FADE_TSLICE_MUL_CREWINFO);
 until done;
end;

procedure crewstats;
begin
 readydata;
 mainloop;
 dispose(mcursor);
 dispose(holo);
 dispose(msgs);
 dispose(littlemsgs);
 {stopmod;}
 removedata;
end;

begin
end.
