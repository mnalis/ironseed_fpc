unit utils2;
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
   Overlayable Utilites for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

{$O+}
{$I-}
interface

procedure adjustplanets(t: integer);
procedure adjustsystem;
procedure redoscreen(x,y,z: integer);
procedure createplanet(xc,yc: integer);
procedure readyplanet;
procedure createstar(c,xc,yc: integer);
procedure readystar;
procedure removedata;
procedure dothatartifactthing(n: integer);
procedure reloadbackground;
procedure makeastoroidfield;
procedure makecloud;
procedure drawastoroid;
procedure getname(n: integer);
procedure addgunnode;
procedure addstuff(n, limit: integer);
procedure getstuffamounts(
const state	: Integer;
var ele	: array{[0..16]} of integer;
var mat	: array{[0..20]} of Integer;
var cmp	: array{[0..22]} of Integer);

function getplanetorbit(planet : Integer): Integer;
function getplanetbyorbit(sys, orbit : Integer): Integer;
procedure planettravel(sys, index : Integer);
procedure gotoorbit(sys, n : Integer);
function GetTechnologyLevel(plan : Integer) : Integer;

implementation

uses utils_, data, journey, gmouse, usecode, display, saveload, comm, utils, weird;

type
 scandatatype= array[0..11] of byte;
 scantype= array[0..16] of scandatatype;
var
 a,b,j,i,index: integer;

function GetTechnologyLevel(plan : Integer) : Integer;
var
   i,techlvl : integer;
begin
 if tempplan^[plan].orbit=0 then
  begin
   GetTechnologyLevel:=0;
   exit;
  end;
 techlvl:=-2;
 case tempplan^[plan].system of
  93,138,78,191,171,221:
    begin
     GetTechnologyLevel:=6*256;
     exit;
    end;
  45: if chevent(27) then
    begin
     GetTechnologyLevel:=0;
     exit;
    end
   else
    begin
     GetTechnologyLevel:=6*256;
     exit;
    end;
 end;
 case tempplan^[plan].state of
  2: case tempplan^[plan].mode of
      2: techlvl:=-1;
      3: techlvl:=tempplan^[plan].age div 15000000;
     end;
  3: begin
      techlvl:=(tempplan^[plan].mode-1)*256;
      case tempplan^[plan].mode of
       1: techlvl:=techlvl+(tempplan^[plan].age div 1500000);
       2: techlvl:=techlvl+(tempplan^[plan].age div 1000);
       3: techlvl:=techlvl+(tempplan^[plan].age div 800);
      end;
     end;
  4: begin
      techlvl:=(tempplan^[plan].mode+2)*256;
      case tempplan^[plan].mode of
       1: techlvl:=techlvl+(tempplan^[plan].age div 400);
       2: techlvl:=techlvl+(tempplan^[plan].age div 200);
      end;
     end;
  5: case tempplan^[plan].mode of
      1: begin
          i:=tempplan^[plan].age div 100000000;
          if i>9 then i:=9;
          techlvl:=techlvl+i;
         end;
      2: techlvl:=-1;
     end;
  6: if tempplan^[curplan].mode=2 then techlvl:=6*256;   {void dwellers}
 end; { case }
   GetTechnologyLevel := techlvl;
end;

procedure reloadbackground;
var temp: pscreentype;
begin
 new(temp);
 backgrx:=random(320);
 backgry:=random(200);
 loadscreen('data/main',temp);
 loadscreen('data/cloud',backgr);
 for j:=0 to 319 do
  begin
   x:=j+backgrx;
   if x>319 then x:=x-320;
   for i:=0 to 199 do
    begin
     y:=i+backgry;
     if y>199 then y:=y-200;
     if temp^[i,j]=255 then screen[i,j]:=backgr^[y,x];
    end;
  end;
 dispose(temp);
end;


function getsubamount(item : Integer; ele : array{[0..16]} of Integer; mat : array{[0..20]} of Integer) : Integer;
var
   i, j, n    : Integer;
   tt	      : Integer;
begin
   getsubamount := 0;
   for i := 1 to maxcargo do
   begin
      if cargo[i].index = item then
      begin
	 tt := 99;
	 for j := 1 to 3 do
	 begin
	    n := prtcargo[i, j];
	    case n of
	      ID_FIRST_ELEMENT..ID_LAST_ELEMENT: begin
		 n := ele[(n - ID_FIRST_ELEMENT) div 10];
	      end;
	      ID_UNKNOWN_MATERIAL..4999: begin
		 n := mat[n - ID_UNKNOWN_MATERIAL];
	      end;
	      ID_UNKNOWN_COMPONENT..3999: begin
		 n := getsubamount(n, ele, mat);
	      end;
	    end; { case }
	    if n < tt then tt := n;
	 end;
	 getsubamount := tt;
	 exit;
      end;
   end;
end; { getsubamounts }


procedure getstuffamounts(
const state	: Integer;
var ele	: array{[0..16]} of integer;
var mat	: array{[0..20]} of Integer;
var cmp	: array{[0..22]} of Integer);
var
   scanfile	: file of scantype;
   temp		: ^scantype;
   i, j, k, n	: Integer;
   tly, tt, cub	: Integer;
begin
   {load scan data}
   new(temp);
   assign(scanfile,'data/scan.dta');
   reset(scanfile);
   if ioresult<>0 then errorhandler('scan.dta',1);
   read(scanfile,temp^);
   if ioresult<>0 then errorhandler('scan.dta',5);
   close(scanfile);

   {copy element amounts}
   for i:=0 to 16 do
      ele[i] := temp^[i,state];
   dispose(temp);

   {compute material amounts}
   for i:=1 to 19 do
   begin
      mat[i] := 0;
      n := i + ID_UNKNOWN_MATERIAL;
      for j:=1 to maxcargo do
	 if cargo[j].index = n then
	 begin
	    tt := 99;
	    tly := 0;
	    cub := 1;
	    for k := 1 to 3 do
	    begin
	       n := ele[(prtcargo[j,k] - ID_FIRST_ELEMENT) div 10];
	       inc(tly, n);
	       if n < tt then
		  tt := n;
	       cub := cub * n;
	    end;
	    if tt > 0 then
	       mat[i] := tly
	    else
	       mat[i] := 0;
	    break;
	 end;
   end;
   mat[0] := 0;
   mat[20] := 0;

   {compute component counts}
   for i := 1 to 20 do
      cmp[i] := getsubamount(i + ID_UNKNOWN_COMPONENT, ele, mat);
   cmp[0] := 0;
   cmp[21] := 0;
   cmp[22] := 0;
end; { getamounts }

procedure addstuff(n, limit: integer);
var
   ele	   : array[0..16] of integer;
   mat	   : array[0..20] of Integer;
   cmp	   : array[0..22] of Integer;
   i, j, r : Integer;
   lim	   : Integer;
   total   : Integer;
   {s	   : string[10];}
begin
   if (tempplan^[n].bots and 7) = 0 then
      exit;
   ele[0]:=0; mat[0]:=0; cmp[0]:=0;	// to turn off warnings, variables are actually correctly initialized by function below
   getstuffamounts(tempplan^[n].state, ele, mat, cmp);
   total := 0;
   lim := limit;
   {for i := 0 to 16 do
   begin
      str(ele[i], s);
      printxy(0, i * 6, s);
   end;
   for i := 0 to 20 do
   begin
      str(mat[i], s);
      printxy(16, i * 6, s);
   end;
   for i := 0 to 20 do
   begin
      str(cmp[i], s);
      printxy(32, i * 6, s);
   end;}
   case (tempplan^[n].bots and 7) of
     1 : begin {elements}
	    for i := 0 to 16 do
	       inc(total, ele[i]);
	    for i := 1 to 7 do
	    begin
	       if tempplan^[n].cache[i] = 0 then
	       begin
		  r := random(total);
		  j := 0;
		  while (j < 16) and (r >= ele[j]) do
		  begin
		     dec(r, ele[j]);
		     inc(j);
		  end;
		  tempplan^[n].cache[i] := ID_FIRST_ELEMENT + j * 10;
		  dec(lim);
		  if lim <= 0 then
		     break;
	       end;
	    end;
	 end;
     2, 5 : begin {materials}
	    for i := 0 to 20 do
	    begin
	       mat[i] := mat[i] * 2;
	       inc(total, mat[i]);
	    end;
	    inc(mat[0]); {unknown material}
	    inc(mat[20]); {worthless junk}
	    inc(total, 2);
	    for i := 1 to 7 do
	    begin
	       if (tempplan^[n].cache[i] = 0) or ((tempplan^[n].cache[i] = ID_WORTHLESS_JUNK) and (random(2) = 0)) then
	       begin
		  r := random(total);
		  j := 0;
		  while (j < 20) and (r >= mat[j]) do
		  begin
		     dec(r, mat[j]);
		     inc(j);
		  end;
		  tempplan^[n].cache[i] := ID_UNKNOWN_MATERIAL + j;
		  dec(lim);
		  if lim <= 0 then
		     break;
	       end;
	    end;
	 end;
     3..4 : begin {components}
	    for i := 0 to 22 do
	    begin
	       cmp[i] := cmp[i] * 2;
	       inc(total, cmp[i]);
	    end;
	    inc(cmp[0]); {unknown component}
	    inc(cmp[22]); {worthless junk}
	    inc(total, 2);
	    for i := 1 to 7 do
	    begin
	       if (tempplan^[n].cache[i] = 0) or ((tempplan^[n].cache[i] = ID_WORTHLESS_JUNK) and (random(2) = 0))  then
	       begin
		  r := random(total);
		  j := 0;
		  while (j < 22) and (r >= cmp[j]) do
		  begin
		     dec(r, cmp[j]);
		     inc(j);
		  end;
		  if j = 22 then
		     tempplan^[n].cache[i] := ID_WORTHLESS_JUNK
		  else
		     tempplan^[n].cache[i] := ID_UNKNOWN_COMPONENT + j;
		  dec(lim);
		  if lim <= 0 then
		     break;
	       end;
	    end;
	 end;
   end; { case }
end;
(*var scanfile		     : file of scantype;
    temp		     : ^scantype;
    a,total,b,c,t,tt,tly,cnt : integer;
    tempcreate		     : ^creationtype;
    creafile		     : file of creationtype;
   amounts		     : array[0..20] of Integer;
   lim			     : Integer;
   {s			     : string[10];}
begin
   new(temp);
   assign(scanfile,'data/scan.dta');
   reset(scanfile);
   if ioresult<>0 then errorhandler('scan.dta',1);
   read(scanfile,temp^);
   if ioresult<>0 then errorhandler('scan.dta',5);
   close(scanfile);
   lim := limit;
   if (tempplan^[n].bots and 7)=1 then
   begin
      total:=0;
      for a:=0 to 16 do inc(total,temp^[a,tempplan^[n].state]);
      for c:=1 to 7 do
	 if tempplan^[n].cache[c]=0 then
	 begin
	    b:=random(total);
	    a:=0;
	    repeat
	       dec(b,temp^[a,tempplan^[n].state]);
	       inc(a);
	    until (b<0) or (a=17);
	    a:=(a-1)*10+ID_FIRST_ELEMENT;
	    tempplan^[n].cache[c]:=a;
	    dec(lim);
	    if lim <= 0 then break;
	 end;
   end
   else if (tempplan^[n].bots and 7)=2 then
   begin
      new(tempcreate);
      assign(creafile,'data/creation.dta');
      reset(creafile);
      if ioresult<>0 then errorhandler('creation.dta',1);
      total:=0;
      for j:=0 to 20 do
	 amounts[j] := 0;
      for j:=1 to totalcreation do
      begin
	 read(creafile,tempcreate^);
	 if ioresult<>0 then errorhandler('creation.dta',5);
	 if(tempcreate^.index >= ID_UNKNOWN_MATERIAL) and (tempcreate^.index <= ID_WORTHLESS_JUNK) then
	 begin
	    tt:=99;
	    tly:=0;
	    for i:=1 to 3 do
	       if (tempcreate^.parts[i]>=ID_FIRST_ELEMENT) then
	       begin
		  cnt := temp^[(tempcreate^.parts[i]-ID_FIRST_ELEMENT) div 10,tempplan^[n].state];
		  if tt > cnt then tt := cnt;
		  inc(tly, cnt);
	       end;
	    if tt = 99 then
	       tt := 0;
	    if tt > 0 then
	    begin
	       inc(total, tly + tly);
	       amounts[tempcreate^.index - ID_UNKNOWN_MATERIAL] := tly + tly;
	    end else
	       amounts[tempcreate^.index - ID_UNKNOWN_MATERIAL] := 0;
	    {str(tempcreate^.index, s);
	    printxy(0,(tempcreate^.index - ID_UNKNOWN_MATERIAL) * 6, s);
	    str(tt, s);
	    printxy(40,(tempcreate^.index - ID_UNKNOWN_MATERIAL) * 6, s);
	    str(tly, s);
	    printxy(60,(tempcreate^.index - ID_UNKNOWN_MATERIAL) * 6, s);}
	 end;
      end;
      {give a chance for unkowns and worthless junk}
      inc(amounts[0]);
      inc(amounts[20]);
      inc(total, 2);
      if total > 0 then
	 for c:=1 to 7 do
	    if (tempplan^[n].cache[c]=0) or (tempplan^[n].cache[c]=ID_WORTHLESS_JUNK) then
	    begin
	       t := random(total);
	       for j := 0 to 20 do
	       begin
		  if t < amounts[j] then
		  begin
		     tempplan^[n].cache[c] := j + ID_UNKNOWN_MATERIAL;
		     break;
		  end;
		  dec(t, amounts[j]);
	       end;
	       dec(lim);
	       if lim <= 0 then break;
	    end;
      close(creafile);
      dispose(tempcreate);
   end;
   dispose(temp);
end;*)

procedure adjustplanets(t: integer);
var j,olds: integer;
begin
 randomize;
 for j:=1 to 1000 do
  begin
   if tempplan^[j].bots >0 then
   begin
      {clear depletion stat}
      tempplan^[j].bots := tempplan^[j].bots and 7;
      if tempplan^[j].bots>0 then
	 addstuff(j, 7);
   end;
   with tempplan^[j] do
    begin
     age:=age+t;
     olds:=state;
     case state of
      0:case mode of
         1,2:if age>=1000000000 then
            begin
             age:=0;
             inc(mode);
            end;
         3: if age>=500000000 then
             begin
              age:=0;
              mode:=1;
              state:=1;
             end;
        end;
      1:case mode of
         1: if age>=500000000 then
             begin
              age:=0;
              mode:=2;
             end;
         2: if age>=400000000 then
             begin
              age:=0;
              mode:=3;
             end;
         3: if age>=300000000 then
             begin
              age:=0;
              mode:=1;
              state:=2;
             end;
       end;
      2:case mode of
         1: if age>=200000000 then
             begin
              age:=0;
              mode:=2;
             end;
         2: if age>=150000000 then
             begin
              age:=0;
              mode:=3;
             end;
         3: begin
             if age>=150000000 then
              begin
               age:=0;
               mode:=1;
               state:=3;
              end;
             if random(40)=0 then
              begin
               age:=0;
               state:=5;
               mode:=2;
              end;
            end;
       end;
      3:case mode of
         1: begin
             if age>=15000000 then
              begin
               age:=0;
               mode:=2;
              end;
             if random(40)=0 then
              begin
               age:=0;
               state:=5;
               mode:=2;
              end;
            end;
         2: if age>=10000 then
             begin
              age:=0;
              mode:=3;
             end;
         3: if age>=8000 then
             begin
              age:=0;
              mode:=1;
              state:=4;
             end;
       end;
      4:case mode of
         1: if age>=4000 then
             begin
              age:=0;
              mode:=2;
             end;
         2: begin
             if age>=2000 then
              begin
               age:=0;
               mode:=3;
              end;
             if random(40)=0 then
              begin
               if random(2)=0 then mode:=1
                else mode:=2;
               state:=6;
               age:=0;
              end;
            end;
         3: begin
             if age>=4000 then
              begin
               age:=0;
               mode:=1;
               state:=5;
              end;
             if random(40)=0 then
              begin
               if random(2)=0 then mode:=1
                else mode:=2;
               state:=6;
               age:=0;
              end;
            end;
       end;
      5:case mode of
         1: if age>=3000 then
             begin
              age:=0;
              mode:=2;
             end;
         2: begin
             if age>=8000 then
              begin
               age:=0;
               mode:=3;
              end;
             if random(40)=0 then
              begin
               age:=0;
               state:=2;
               mode:=3;
              end;
            end;
         3:;
       end;
      6:if (mode=1) and (age>=100000) then
         begin
          age:=0;
          mode:=2;
         end;
     end;
    if (olds<>state) then
     begin
      fillchar(cache,sizeof(cache),0);
      bots:=0;
      notes:=0;
     end;
    end;
  end;
end;

procedure getname(n: integer);
type nametype= string[12];
var str1: nametype;
    f: file of nametype;
begin
 assign(f,'data/sysname.dta');
 reset(f);
 if ioresult<>0 then errorhandler('data/sysname.txt',1);
 seek(f,n-1);
 if ioresult<>0 then errorhandler('data/sysname.txt',6);
 read(f,str1);
 if ioresult<>0 then errorhandler('data/sysname.txt',6);
 systems[n].name:=str1;
 close(f);
end;

procedure adjustsystem;
begin
 if systems[tempplan^[curplan].system].visits=0 then
  getname(tempplan^[curplan].system);
 inc(systems[tempplan^[curplan].system].visits);
 systems[tempplan^[curplan].system].datey:=ship.stardate[3];
 systems[tempplan^[curplan].system].datem:=ship.stardate[1];
 if systems[tempplan^[curplan].system].visits<255 then inc(tempplan^[j].visits);
 tempplan^[j].datey:=ship.stardate[3];
 tempplan^[j].datem:=ship.stardate[1];
end;

procedure redoscreen(x,y,z: integer);
var dist: real;
    index,time: integer;
    str1: string[4];
begin
 dist:=sqr((x-ship.posx)/10);
 dist:=dist + sqr((y-ship.posy)/10);
 dist:=dist + sqr((z-ship.posz)/10);
 dist:=sqrt(dist);
 if (random(85)+15)<ship.damages[DMG_ENGINES] then
  begin
   tcolor:=94;
   println;
   print('NAVIGATION: Ship off course!');
   ship.posx:=x-3+random(7);
   ship.posy:=y-3+random(7);
   ship.posz:=z-3+random(7);
  end
 else
  begin
   ship.posx:=x;
   ship.posy:=y;
   ship.posz:=z;
  end;
 targetready:=false;
 ship.battery:=32000;
 checkstats;
 showplanet:=false;
 for j:=1 to nearbymax do nearby[j].index:=0;
 i:=0;
 for j:=1 to 250 do
  begin
   x:=systems[j].x-ship.posx;
   y:=systems[j].y-ship.posy;
   z:=systems[j].z-ship.posz;
   if (abs(x)<400) and (abs(y)<400)
    and (abs(z)<400) then
     begin
      inc(i);
      if i>nearbymax then errorhandler('NEARBY STRUCTURE OVERFLOW #1.',6);
      nearby[i].index:=j;
      nearby[i].x:=x/10;
      nearby[i].y:=y/10;
      nearby[i].z:=z/10;
      systems[j].notes:=systems[j].notes or 1;
     end;
  end;
 move(nearby,nearbybackup,sizeof(nearbyarraytype));
 mousehide;
 compressfile(tempdir+'/current',@screen);
 scr_fillchar(screen,sizeof(screen),0);
 tcolor:=47;
 bkcolor:=0;
 time:=round(dist*2)+1;
 printxy(42,187,'Acceleration to near light speed...');
 mouseshow;
 for j:=0 to round(dist*2) do
  begin
   addlotstime(false, false, random(4000)+4000);
   dec(time);
   str(time,str1);
   if length(str1)<4 then for i:=length(str1)+1 to 4 do str1[i]:=#20;
   str1[0]:=#4;
   bkcolor:=0;
   printxy(222,187,str1);
  end;
 bkcolor:=3;
 tcolor:=31;
 {fading;}
 fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);
 mousehide;
 loadscreen(tempdir+'/current',@screen);
 showtime;
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
   ship.stardate[3]:=ship.stardate[3]+round(dist);
   j:=findfirstplanet(nearby[index].index);
   ship.orbiting:=0;
   curplan:=j;
   showtime;
   adjustsystem;
   adjustplanets(round(dist));
   readystar;
  end
 else
  begin
   curplan:=0;
   ship.orbiting:=0;
   reloadbackground;
   fadein;
  end;
 mouseshow;
 if ship.options[OPT_AUTOSAVE]=1 then savegamedata(0,31);
 target:=0;
 for j:=1 to random(4)+1 do
  begin
   i:=random(7)+1;
   if ship.damages[i]<90 then inc(ship.damages[i]);
  end;
 if index<>0 then
  begin
   for j:=0 to maxeventsystems do
    if eventsystems[j]=nearby[index].index then event(eventstorun[j]);
  end;
end;

{Creates a planet by having a 'cursor' randomly wander over the planet in single pixel steps raise the terrain below it.}
procedure createplanet(xc,yc: integer);
var x1,y1 : integer;
    a	  : longint;
    str1  : string[3];
   tl, i  : Integer;
begin
   i:=0;
   x1:=xc;
   y1:=yc;
   randseed:=tempplan^[curplan].seed;
   for a:=1 to 75000 do
   begin
      inc(i);
      x1:=x1-1+random(3);
      y1:=y1-1+random(3);
      if x1>240 then x1:=1 else if x1<1 then x1:=240;
      if y1>120 then y1:=1 else if y1<1 then y1:=120;
      if landform^[x1,y1]<240 then landform^[x1,y1]:=landform^[x1,y1]+7;
      if i=1125 then
      begin
	 inc(index);
	 str((200-index):3,str1);
	 printxy(90,170,str1);
	 i:=0;
      end;
   end;
   tl := GetTechnologyLevel(curplan);
   if tl > 0 then
   begin
      tl := hi(tl) * 10 + lo(tl);
      tl := tl * tl div 10;
      for a:=1 to tl do
      begin
	 {for i := 1 to 5 do}
	    x1 := random(240);
	    y1 := random(120);
	    if landform^[x1,y1] > water then
	    begin
	       landform^[x1,y1] := 255;
	       {inc(x1);
	       if x1 > 240 then x1 := 1;
	       landform^[x1,y1] := 255;}
	    end;
      end;
   end;
end;

procedure makeswirl(x, y, sz : Integer);
var
   c : byte;
begin
   if y <= 60 then
      case sz of
	2 : begin
	       c := landform^[x,y-1];
	       landform^[x,y-1] := landform^[x+1,y] - random(3);
	       landform^[x+1,y] := c - random(3);
	    end;
	3 : begin
	       c := landform^[x,y-1];
	       landform^[x,y-1] := landform^[x+2,y] - random(3);
	       landform^[x+2,y] := c - random(3);
	       c := landform^[x+1,y-1];
	       landform^[x+1,y-1] := landform^[x+1,y] - random(3);
	       landform^[x+1,y] := c - random(3);
	    end;
	4 : begin
	       c := landform^[x,y-1];
	       landform^[x,y-1] := landform^[x+3,y] - random(3);
	       landform^[x+3,y] := c - random(3);
	       c := landform^[x+1,y-1];
	       landform^[x+1,y-1] := landform^[x+2,y] - random(3);
	       landform^[x+2,y] := c - random(3);
	       c := landform^[x+2,y-2];
	       landform^[x+2,y-2] := landform^[x+1,y+1] - random(3);
	       landform^[x+1,y+1] := c - random(3);
	       c := landform^[x+1,y-2];
	       landform^[x+1,y-2] := landform^[x+2,y+1] - random(3);
	       landform^[x+2,y+1] := c - random(3);
	    end;
      end { case }
   else
      case sz of
	2 : begin
	       c := landform^[x+1,y-1];
	       landform^[x+1,y-1] := landform^[x,y] - random(3);
	       landform^[x,y] := c - random(3);
	    end;
	3 : begin
	       c := landform^[x,y];
	       landform^[x,y] := landform^[x+2,y-1] - random(3);
	       landform^[x+2,y-1] := c - random(3);
	       c := landform^[x+1,y-1];
	       landform^[x+1,y-1] := landform^[x+1,y] - random(3);
	       landform^[x+1,y] := c - random(3);
	    end;
	4 : begin
	       c := landform^[x,y];
	       landform^[x,y] := landform^[x+3,y-1] - random(3);
	       landform^[x+3,y-1] := c - random(3);
	       c := landform^[x+1,y];
	       landform^[x+1,y] := landform^[x+2,y-1] - random(3);
	       landform^[x+2,y-1] := c - random(3);
	       c := landform^[x+2,y-2];
	       landform^[x+2,y-2] := landform^[x+1,y+1] - random(3);
	       landform^[x+1,y+1] := c - random(3);
	       c := landform^[x+1,y-2];
	       landform^[x+1,y-2] := landform^[x+2,y+1] - random(3);
	       landform^[x+2,y+1] := c - random(3);
	    end;
      end; { case }
end;

procedure creategasplanet;
var x1,y1      : integer;
    a,b,c      : integer;
   c1, c2, c3  : Integer;
   sz,sz2,sz21 : Integer;
   sz22        : Integer;
   cnt,d,d2    : Integer;
   x, y	       : Integer;
   xx          : Integer;
begin
   randseed:=tempplan^[curplan].seed;
   {decide on colours}
   if random(2) > 0 then
   begin
      c1 := 32;
      c2 := 48;
      c3 := 64;
   end else begin
      c1 := 112;
      c2 := 128;
      c3 := 96;
   end;
   {create bands}
   b := 0;
   a := 1;
   for y1 := 60 downto 1 do
   begin
      dec(a);
      if a = 0 then
      begin
	 a := (60 - abs(y1 - 60)) div 10;
	 a := a + 6 + random(a + 5);
	 if (a < y1) and ((a + 5) > y1) then
	    a := y1 shr 1;
	 b := (b + random(2) + 1) mod 3;
	 case b of
	   0 : c := c1 + 8 + random(5);
	   1 : c := c2 + 8 + random(5);
	   2 : c := c3 + 8 + random(5);
	 end; { case }
      end;
      for x1 := 1 to 240 do
      begin
	 landform^[x1, y1] := c + random(2);
	 landform^[x1, 121 - y1] := c + random(2);
      end;
   end;
   {border turbulence}
   for y1 := 3 to 119 do
      if (landform^[1, y1] and $f0) <> (landform^[1, y1 - 1] and $f0) then
      begin
	 x1 := 1;
	 while x1 <= 240 do
	 begin
	    b := random(4) + 1;
	    if b + x1 > 241 then
	       b := 241 - x1;
	    makeswirl(x1, y1, b);
	    inc(x1, b);
	 end;
	 inc(y1,2);
      end;
   {Spots}
   cnt := 6 + random(5);
   for i := 1 to cnt do
   begin
      case random(3) of
	0 : c := c1 + 2 + random(4);
	1 : c := c2 + 2 + random(4);
	2 : c := c3 + 2 + random(4);
      end; { case }
      if i = 1 then
	 sz := 15 + random(5)
      else
	 sz := 2 + random(6);
      sz2 := sz * sz;
      sz21 := (sz - 1) * (sz - 1);
      sz22 := (sz - 2) * (sz - 2);
      x := random(240);
      y := random(110 - sz - sz) + 5 + sz;
      for x1 := -sz to sz do
      begin
	 xx := x1 + x;
	 if xx < 1 then inc(xx, 240) else if xx > 240 then dec(xx, 240);
	 d := round(sqrt(sz2 - x1 * x1));
	 for y1 := -d to d do
	 begin
	    d2 := (x1 * x1) + (y1 * y1);
	    if d2 > (sz21) then
	       inc(landform^[xx,y1+y], 1 + random(2))
	    else if d2 > (sz22) then
	       landform^[xx,y1+y] := c - 1 - random(2)
	    else
	       landform^[xx,y1+y] := c + random(2);
	 end;
      end
   end;

   randomize;
{  a:=1;
   c:=112;
   randseed:=tempplan^[curplan].seed;
   for j:=1 to 240 do
      for i:=1 to 120 do
      begin
	 dec(a);
	 if a<1 then
	 begin
	    a:=random(5)*30;
	    c:=c-1;
	    if c<0 then c:=0+random(4)
	    else if c>255 then c:=255-random(4)
	    else c:=c+random(3);
	 end;
	 landform^[j,i]:=c;
      end;
   for a:=2 to 120 do
      for i:=a to 120 do
      begin
	 b:=landform^[240,i];
	 for j:=240 downto 2 do
	    landform^[j,i]:=landform^[j-1,i];
	 landform^[1,i]:=b;
      end;
   for j:=1 to 240 do
      for i:=2 to 120 do
      begin
	 if j=1 then c:=landform^[240,i-1]+landform^[240,i]
	 else c:=landform^[j-1,i-1]+landform^[j-1,i];
	 if j=240 then c:=c+landform^[1,i-1]
	 else c:=c+landform^[j+1,i-1];
	 c:=c+landform^[j,i-1]+landform^[j,i];
	 c:=c div 5;
	 landform^[j,i]:=c;
      end;
   }
end;

procedure makeastoroidfield;
var t3: real;
begin
 randseed:=tempplan^[curplan].seed;
 for b:=0 to 100+random(50) do
  begin
   a:=random(6);
   readweaicon(a+80);
   x:=random(300)+10;
   y:=random(70)+25;
   if random(5)=0 then y:=y-20+random(40);
   t3:=(random(190)+10)/200;
   for i:=0 to 19 do
    for j:=0 to 19 do
     if tempicon^[i,a+j]<>0 then backgr^[y+round(i*t3),x+round(j*t3)]:=tempicon^[i,j];
  end;
 for i:=1 to 120 do
  for j:=1 to 240 do
  landform^[j,i]:=backgr^[i,j+40];
 randomize;
end;

function inter2(c1, c2 : Integer) : Integer;
var
   c : Integer;
begin
   if (c1 and $f0) = (c2 and $f0) then
      inter2 := (c1 + c2) shr 1
   else
   begin
      c := 15 - (c1 and $f) - 1 + (c2 and $f);
      if c < 0 then
	 inter2 := -c + (c1 and $f0)
      else
	 inter2 := (c2 and $f0) + c;
   end;
end; { inter2 }

function inter4(c1, c2, c3, c4 : Integer) : Integer;
{var
   c : Integer;}
begin
   {c := (c1 and $f) + (c2 and $f) + (c3 and $f) + (c4 and $f);}
   inter4 := (c1 + c2 + c3 + c4) shr 2;
end; { inter4 }



procedure makecloud;
var
   x, y	      : Integer;
   y1         : Integer;
   x2, y2     : Integer;
   xx, yy     : Integer;
   i,c,count  : Integer;
   sz,b,bl    : Integer;
begin
   randseed:=tempplan^[curplan].seed;

   count := random(25) + 50;
   for i := 1 to count do
   begin
      if i = 1 then
      begin
	 sz := 50 + random(50);
	 x := 160;
	 y := 70;
      end else begin
	 sz := 25 + random(50);
	 x := sz + 30 + random(260 - sz - sz);
	 y := sz shr 1 + 10 + random(120 - sz);
      end;
      {c := random(random(112) + 32) and $f0;}
      c := (random(48) + 32) and $f0;
      {c := 0;}
      for xx := -sz to sz do
      begin
	 bl := $7 * (sz - abs(xx)) div sz;
	 y1 := round(cos(xx * 1.57 / sz) * (sz shr 1));
	 for yy := -y1 to y1 do
	 begin
	    if y1 > 0 then

	       b := (bl * (y1 - abs(yy)) * (y1 - abs(yy))) div y1 div y1
	    else
	       b := 0;
	    x2 := x + xx;
	    y2 := y + yy;
	    if (backgr^[y2,x2] > 143) or (random(7) < b) {or (backgr^[y2,x2] < 32)} then
	       backgr^[y2,x2] := c or b
	    else if (backgr^[y2,x2] and $f) < b then
	       backgr^[y2,x2] := (backgr^[y2,x2] and $f0) or b;
	 end;
      end;
   end;

   for i:=1 to 120 do
      for j:=1 to 240 do
	 landform^[j,i]:=backgr^[i+10,j+40];
   randomize;
(*
   x := 8;
   repeat
      y := 8;
      repeat
	 landform^[x,y]:=random(112) + 32;
	 {landform^[x,y]:=random(16) + 64;}
	 inc(y, 8);
      until y > 120;
      inc(x, 8);
   until x > 240;

   stride := 8;
   repeat
   begin
      s2 := stride shr 1;
      x := 0;
      repeat
      begin
	 if x = 0 then x1 := 240 else x1 := x;
	 x2 := x + stride;
	 xx := x + s2;
	 y := 0;
	 repeat
	 begin
	    if y = 0 then y1 := 120 else y1 := y;
	    y2 := y + stride;
	    yy := y + s2;
	    landform^[xx,y1]:=inter2(landform^[x1,y1],landform^[x2,y1]);
	    landform^[xx,y2]:=inter2(landform^[x1,y2],landform^[x2,y2]);
	    landform^[x1,yy]:=inter2(landform^[x1,y1],landform^[x1,y2]);
	    landform^[x2,yy]:=inter2(landform^[x2,y1],landform^[x2,y2]);
	    landform^[xx,yy]:=inter4(landform^[x2,y1],landform^[x2,y1],
				     landform^[x2,y2],landform^[x1,y1]);
	    inc(y, stride);
	 end;
	 until y = 120;
	 inc(x, stride);
      end;
      until x = 240;
      stride := s2;
   end;
   until stride <= 1;

   for y:=1 to 120 do
      for x:=1 to 240 do
	 backgr^[y+10,x+40] := landform^[x,y];
*)
   {for b:=0 to 700+random(400) do
   begin
      case random(3) of
	0 : a:=random(12)+112;
	1 : a:=random(14)+128;
	2 : a:=random(6) +160;
      end;
      x:=random(628);
      y:=random(150)+5;
      backgr^[round(sin(x/100)*y*0.4)+70,round(cos(x/100)*y)+160]:=a;
   end;
   for i:=1 to 120 do
      for j:=1 to 240 do
	 landform^[j,i]:=backgr^[i+10,j+40];
   randomize;}
end;

procedure drawastoroid;
var temp: pscreentype;
begin
 new(temp);
 loadscreen('data/main',temp);
 for j:=0 to 319 do
  begin
   x:=j+backgrx;
   if x>319 then x:=x-320;
   for i:=0 to 199 do
    begin
     y:=i+backgry;
     if y>199 then y:=y-200;
     if temp^[i,j]=255 then screen[i,j]:=backgr^[y,x];
    end;
  end;
 dispose(temp);
end;

procedure readyplanet;
var
    t: pscreentype;
    tpal: paltype;
    part2: real;
    str1: string[3];
    y: real;
begin
 glowindex:=4;
 mousehide;
 reloadbackground;
 showplanet:=true;
 randseed:=tempplan^[curplan].seed;
 i:=tempplan^[curplan].water+20;
 fillchar(landform^,28800,i);
 case tempplan^[curplan].psize of
  0,1: radius:=900;
  2,3: radius:=2000;
    4: radius:=3025;
 end;
 if radius<901 then c2:=1.20
  else if radius>2000 then c2:=1.09
  else c2:=1.16;
 randomize;
 case random(4) of
  0: ecl:=random(25)+30;
  1: ecl:=80-random(25);
  2: ecl:=200+random(25);
  3: ecl:=250-random(25);
 end;
 r2:=round(sqrt(radius));
 offset:=55-r2;
 maxspherei:=2*r2+4;
 spherei:=maxspherei div 2;
 xw:=2*r2+10;
 if (tempplan^[curplan].state=0) and (tempplan^[curplan].mode>1) then
  begin
   creategasplanet;
   new(t);
   scrfrom_move(screen,t^,sizeof(screen));
   scr_fillchar(screen,sizeof(screen),0);
   set256colors(colors);
   tcolor:=47;
   bkcolor:=0;
   printxy(30,160,'Approaching planet...');
   printxy(30,170,'ETA T Minus     hrs');
   for i:=1 to 200 do
    begin
     str((200-i):3,str1);
     printxy(90,170,str1);
     delay(tslice);
    end;
   for i:=6 to maxspherei do
    begin
     y:=sqrt(radius-sqr(i-r2-5));
     pm[i]:=round((r2-y)*c2);
     ppart[i]:=r2/y;
    end;
   sphere:=2;
   tpal[0,1]:=0;	// to turn off warnings, variables are actually correctly initialized by function below
   fillchar(tpal,sizeof(paltype),0);
   set256colors(tpal);
   move(t^,screen,sizeof(screen));
   dispose(t);
   for i:=1 to 120 do
    scrfrom_move(screen[i+12,28],planet^[i],30*4);
   makegasplanet;
  end
 else if ((tempplan^[curplan].state=6) and (tempplan^[curplan].mode=2)) then
  begin
   fillchar(planet^,14400,0);
   backgrx:=0;
   backgry:=0;
   makeastoroidfield;
   new(t);
   scrfrom_move(screen,t^,sizeof(screen));
   scr_fillchar(screen,sizeof(screen),0);
   set256colors(colors);
   tcolor:=47;
   bkcolor:=0;
   printxy(30,160,'Approaching planet...');
   printxy(30,170,'ETA T Minus     hrs');
   for i:=1 to 200 do
    begin
     str((200-i):3,str1);
     printxy(90,170,str1);
     delay(tslice);
    end;
   sphere:=3;
   fillchar(tpal,sizeof(paltype),0);
   set256colors(tpal);
   move(t^,screen,sizeof(screen));
   dispose(t);
   drawastoroid;
 end
 else if (tempplan^[curplan].state=0) then
  begin
   fillchar(planet^,14400,0);
   backgrx:=0;
   backgry:=0;
   makecloud;
   new(t);
   scrfrom_move(screen,t^,sizeof(screen));
   scr_fillchar(screen,sizeof(screen),0);
   set256colors(colors);
   tcolor:=47;
   bkcolor:=0;
   printxy(30,160,'Approaching planet...');
   printxy(30,170,'ETA T Minus     hrs');
   for i:=1 to 200 do
    begin
     str((200-i):3,str1);
     printxy(90,170,str1);
     delay(tslice);
    end;
   for i:=1 to 120 do
    scrfrom_move(screen[i+12,28],planet^[i],30*4);
   sphere:=3;
   fillchar(tpal,sizeof(paltype),0);
   set256colors(tpal);
   move(t^,screen,sizeof(screen));
   dispose(t);
   drawastoroid;
  end
 else
  begin
   new(t);
   scrfrom_move(screen,t^,sizeof(screen));
   scr_fillchar(screen,sizeof(screen),0);
   set256colors(colors);
   tcolor:=47;
   bkcolor:=0;
   printxy(30,160,'Approaching planet...');
   printxy(30,170,'ETA T Minus     hrs');
   index:=0;
   i:=0;
   createplanet(200,90);
   createplanet(30,30);
   createplanet(120,60);
   fillchar(tpal,sizeof(paltype),0);
   set256colors(tpal);
   move(t^,screen,sizeof(screen));
   dispose(t);
   water:=50;
   case tempplan^[curplan].state of
    1: begin
        waterindex:=80;
        for j:=0 to 3 do spcindex[j]:=83-j;
        spcindex[5]:=81;
        spcindex[4]:=82;
       end;
    2: begin
        waterindex:=32;
        case tempplan^[curplan].mode of
         1: for j:=0 to 5 do spcindex[j]:=1;
         2: begin
             for j:=0 to 3 do spcindex[j]:=1;
             spcindex[4]:=48;
             spcindex[5]:=49;
            end;
         3: begin
             for j:=0 to 3 do spcindex[j]:=48+j;
             spcindex[4]:=128;
             spcindex[5]:=130;
            end;
        end;
       end;
    3: begin
        waterindex:=33;
        for j:=0 to 3 do spcindex[j]:=48+j;
        spcindex[4]:=128;
        spcindex[5]:=129;
       end;
    4: begin
        waterindex:=32;
        water:=40;
        for j:=0 to 3 do spcindex[j]:=48+j;
        spcindex[4]:=128;
        spcindex[5]:=129;
       end;
    5: begin
        waterindex:=32;
        for j:=0 to 5 do spcindex[j]:=1;
        if tempplan^[curplan].mode=3 then water:=0
         else water:=30;
       end;
    6: begin
        waterindex:=32;
        water:=0;
        for j:=0 to 5 do spcindex[j]:=1;
       end;
   end;
   part2:=28/(255-water);
   for j:=0 to 5 do spcindex2[j]:=spcindex[j] mod 16;
   if water>0 then for j:=0 to water-1 do colorlookup[j]:=waterindex+6;
   for j:=water to 246 do colorlookup[j]:=round((j-water)*part2);
   for j:=247 to 255 do colorlookup[j]:=j;
   for i:=6 to maxspherei do
    begin
     y:=sqrt(radius-sqr(i-r2-5));
     pm[i]:=round((r2-y)*c2);
     ppart[i]:=r2/y;
    end;
   for i:=1 to 120 do
    scrfrom_move(screen[i+12,28],planet^[i],30*4);
   makesphere;
   sphere:=1;
  end;
 checkstats;
 showtime;
 mouseshow;
 fadein;
 tcolor:=31;
 bkcolor:=3;
 println;
 print('Orbit achieved...');
 randomize;
 checkwandering;
end;

procedure createstar(c,xc,yc: integer);
var x1,y1: integer;
    a: longint;
    str1: string[3];
begin
 x1:=xc;
 y1:=yc;
 xw:=2*r2+10;
 for a:=1 to 75000 do
  begin
  inc(i);
   x1:=x1-1+random(3);
   y1:=y1-1+random(3);
   if x1>240 then x1:=1 else if x1<1 then x1:=240;
   if y1>120 then y1:=1 else if y1<1 then y1:=120;
   if landform^[x1,y1]<c then landform^[x1,y1]:=landform^[x1,y1]+1;
   if i=1125 then
    begin
     inc(index);
     str((200-index):3,str1);
     printxy(90,170,str1);
     i:=0;
    end;
  end;
end;

procedure readystar;
var y: real;
    tpal: paltype;
    t: pscreentype;
    i2: integer;
begin
 mousehide;
 reloadbackground;
 showplanet:=true;
 randseed:=tempplan^[curplan].seed;
 compressfile(tempdir+'/current',@screen);
 index:=0;
 case tempplan^[curplan].mode of
  1: begin radius:=2000; i:=120; end;
  2: begin radius:=3025; i:=83; end;
  3: begin radius:=900; i:=16; end;
 end;
 if radius<901 then c2:=1.20
  else if radius>2000 then c2:=1.09
  else c2:=1.16;
 r2:=round(sqrt(radius));
 offset:=55-r2;
 fillchar(landform^,28800,i);
 fillchar(planet^,14400,0);
 i2:=i+6;
 new(t);
 scrfrom_move(screen,t^,sizeof(screen));
 scr_fillchar(screen,sizeof(screen),0);
 set256colors(colors);
 tcolor:=47;
 bkcolor:=0;
 printxy(30,160,'Approaching star...');
 printxy(30,170,'ETA T Minus     hrs');
 index:=0;
 i:=0;
 createstar(i2,200,90);
 createstar(i2,30,30);
 createstar(i2,120,60);
 tpal[0,1]:=0;	// to turn off warnings, variables are actually correctly initialized by function below
 fillchar(tpal,sizeof(paltype),0);
 set256colors(tpal);
 move(t^,screen,sizeof(screen));
 dispose(t);
 loadscreen(tempdir+'/current',@screen);
 showtime;
 for i:=6 to 2*r2+4 do
  begin
   y:=sqrt(radius-sqr(i-r2-5));
   pm[i]:=round((r2-y)*c2);
   ppart[i]:=r2/y;
  end;
 for i:=1 to 120 do
  scrfrom_move(screen[i+12,28],planet^[i],30*4);
 makestar;
 checkstats;
 mouseshow;
 fadein;
 tcolor:=31;
 println;
 print('Orbit achieved...');
 sphere:=1;
 randomize;
end;

procedure removedata;
begin
   mousehide;
   {fading;}
   fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);
   mouse.setmousecursor(random(3));
   loadscreen(tempdir+'/current',@screen);
   showresearchlights;
   bkcolor:=3;
   displaytextbox(false);
   textindex:=25;
   {fadein;}
   mouseshow;
   anychange:=true;
   t1:=oldt1;
end;

procedure dothatartifactthing(n: integer);
var i: integer;
    t: longint;
begin
 if n<ID_ART_SHUNT_DRIVE then
  begin
   a:=random(1000);
   case a of
      50..99: begin
               ship.fuelmax:=ship.fuelmax+(random(5)+1)*10;
               if ship.fuelmax>1500 then ship.fuelmax:=1500;
               showchar(2,'We have improved fuel capacity.');
              end;
    100..699: begin
               t:=ship.crew[a div 100].xp;
               i:=random(15)+6;
               t:=t*i;
               t:=round(t/100);
               addxp(a div 100,t,2);
               showchar(a div 100,'The artifact analysis has been insightful.');
              end;
           1: begin
               ship.accelmax:=ship.accelmax+(random(20)+1)*5;
               if ship.accelmax>1100 then ship.accelmax:=1100;
               showchar(2,'We have improved thrust efficency.');
              end;
           2: begin
               ship.hullmax:=ship.hullmax+(random(40)+11)*10;
               if ship.hullmax>30000 then ship.hullmax:=30000;
               showchar(2,'We have improved hull distribution.');
              end;
   else begin
        showchar(2,'Nothing new learned.');
   end;
   end;
  end
 else
  begin
   case n of
    ID_ART_SHUNT_DRIVE: begin   { shunt drive }
           if not chevent(36) then
            begin
             addcargo(ID_ART_SHUNT_DRIVE, true);
             viewmode:=0;
             viewmode2:=0;
             n:=ship.options[OPT_AUTOSAVE];
             ship.options[OPT_AUTOSAVE]:=0;
             redoscreen(random(2500),random(2500),random(2500));
             ship.options[OPT_AUTOSAVE]:=n;
             n:=ship.options[OPT_MSGS];
             ship.options[OPT_MSGS]:=2;
             showchar(2,'Whoops! Didn''t know the Shunt Drive would do that!');
             ship.options[OPT_MSGS]:=n;
             event(36);
            end;
          end;
    ID_ART_THERMAL_PLATING: begin   { thermal plating tapes }
           n:=ship.options[OPT_MSGS];
           ship.options[OPT_MSGS]:=2;
           showchar(2,'We can create Thermal ThermoPlast!');
           ship.options[OPT_MSGS]:=n;
           event(18);
          end;
    ID_ART_ERMIGEN_DATA_TAPES: event(30); {ermigen data tapes }
    else if n>ID_ART_SHUNT_DRIVE then
          begin
           addcargo(n,true);
           i:=ship.options[OPT_MSGS];
           ship.options[OPT_MSGS]:=2;
           showchar(2,'No new information from the artifact.');
           ship.options[OPT_MSGS]:=i;
          end;
   end;
  end;
end;

procedure addgunnode;
var old: array[1..10] of byte;
    t: word;
begin
 t:=tcolor;
 old[1]:=0;	// to turn off warnings, variables are actually correctly initialized by function below
 move(ship.gunnodes,old,10);
 with ship do
  begin
   if shiptype[SHPTYP_HEAVYNESS]=SHPTYPE_STATEGIC{3} then
    begin
     if shiptype[SHPTYP_PURPOSE]=SHPTYPE_STORM{3} then
      begin
       if shiptype[SHPTYP_VESSEL]=SHPTYPE_CRUISER{3} then
        begin
         addcargo2(ID_INSTALL_GUN_NODE,true);	{ we are at maximum 10 gunnodes already, cannot add more }
         exit;
        end
       else inc(shiptype[SHPTYP_VESSEL]);
      end
     else inc(shiptype[SHPTYP_PURPOSE]);
    end
   else if shiptype[SHPTYP_HEAVYNESS]=SHPTYPE_LIGHT{2} then shiptype[SHPTYP_HEAVYNESS]:=SHPTYPE_HEAVY{1}
   else shiptype[SHPTYP_HEAVYNESS]:=SHPTYPE_STATEGIC{3};
  end;
 fillchar(ship.gunnodes,10,0);
 j:=0;
 for i:=1 to 10 do if old[i]>0 then
  begin
   repeat
    inc(j);
   until checkloc(j);
   ship.gunnodes[j]:=old[i];
  end;
 if (viewmode=10) and (done) then
  begin
   cleanright(false);
   readyconfigure;
  end;
 tcolor:=t;
end;

{
Gets orbit number by counting planets from the star.
}
function getplanetorbit(planet : Integer): Integer;
var
   sys	  : Integer;
   i, j	  : Integer;
   orbits : array[0..7] of Integer;
begin
   for i := 0 to 7 do orbits[i] := 0;
   sys := tempplan^[planet].system;
   i := findfirstplanet(sys);
   while (tempplan^[i].system = sys) and (i <= 1000) do
   begin
      orbits[tempplan^[i].orbit] := i;
      inc(i);
   end;
   j := 0;
   for i := 0 to 7 do
   begin
      if orbits[i] = planet then
	 break;
      if orbits[i] > 0 then
	 inc(j);
   end;
   getplanetorbit := j;
end; { getplanetorbit }

{
Gets which planet is in orbit n from the star. Returns 0 if not found.
}
function getplanetbyorbit(sys, orbit : Integer): Integer;
var
   i, j	      : Integer;
   orbits     : array[0..7] of Integer;
   {str1, str2 : string[10];}
begin
   if orbit < 0 then
   begin
      getplanetbyorbit := 0;
      exit;
   end;
   for i := 0 to 7 do orbits[i] := 0;
   i := findfirstplanet(sys);
   j := 0;
   while (tempplan^[i].system = sys) and (i <= 1000) do
   begin
      {str(tempplan^[i].orbit, str1);
      str(i, str2);
      printxy(0,j *6, str2 + ':' + str1);
      inc(j);}
      orbits[tempplan^[i].orbit] := i;
      inc(i);
   end;
   j := orbit;
   {str(j, str2);
   printxy(0,0, str2);}
   for i := 0 to 7 do
   begin
      if orbits[i] > 0 then
      begin
	 if j <= 0 then
	 begin
	    {str(i, str1);
	    str(orbits[i], str2);
	    printxy(0,60 + j * 6, str1 + ':' + str2);}
	    getplanetbyorbit := orbits[i];
	    exit;
	 end;
	 dec(j);
      end;
   end;
   getplanetbyorbit := 0;
end; { getplanetbyorbit }

{
}
procedure planettravel(sys, index : Integer);
var
   j, sy	     : Integer;
   {str1,str2,str3,str4,str5,str6 : string;}
begin
   {str(sys, str1);
   str(index, str2);}
   if sys >= 0 then
   begin
      j:=findfirstplanet(sys)+index;
      sy := sys;
   end else begin
      sy := tempplan^[index].system;
      j:=index;
      while (j > 0) and (tempplan^[j].system = sy) do
	 dec(j);
      inc(j);
      {str(j, str1);
      str(index, str2);
      printxy(0,0, str2 + ':' + str1);}
      index := index - j;
      inc(j, index);
   end;

   if viewmode2>0 then removestarmap;
   cleanright(true);
   {str(curplan, str3);
   str(j, str4);
   str(sy, str5);
   str(index, str6);
   if not yesnorequest(str1 + ':' + str2 + ' ' + str5 + ':' + str6 + ' ' + str3 + '->' + str4, 0, 31) then
      exit;}
   curplan:=j;
   if tempplan^[j].visits<255 then inc(tempplan^[j].visits);
   tempplan^[j].datey:=ship.stardate[3];
   tempplan^[j].datem:=ship.stardate[1];
   ship.orbiting:=index;
   mousehide;
   compressfile(tempdir+'/current',@screen);
   scr_fillchar(screen,sizeof(screen),0);
   mouseshow;
   for j:=1 to random(40)+60 do addlotstime(false, true, 100+random(100));
   {fading;}
   fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);
   mousehide;
   loadscreen(tempdir+'/current',@screen);
   mouseshow;
   if index>0 then readyplanet else readystar;
   checkwandering;
end;

procedure gotoorbit(sys, n : Integer);
var
   i : Integer;
begin
   i := getplanetbyorbit(sys, n);
   if i = 0 then
   begin
      println;
      tcolor := 94;
      print('NAVIGATION: There''s no orbit to go to.');
      exit;
   end;
   planettravel(-1, i);
end;

begin
end.
