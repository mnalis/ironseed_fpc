unit cargtool;
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
   Cargo/Creation unit for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

{$O+}
{$I-}
interface

procedure inventory;
procedure creation;
function StartBuild(background : Boolean; root, item, team : Integer) :Integer;

implementation

uses data, gmouse, utils, weird, saveload, modplay, journey, display, usecode, heapchk, utils_;
{$PACKRECORDS 1}
type
 cargobuttontype= array[110..126,92..228] of byte;
 iteminfotype=
  record
   index: integer;
   info: array[0..3] of string[28];
  end;
{$PACKRECORDS DEFAULT}
var
 drawit,qmode,colorcode					    : boolean;
 i,j,a,b,cargoindex,cargomode,viewteam,maxcreation,lastinfo : integer;
   teamjob						    : integer;
 cargobuttons						    : ^cargobuttontype;
 filters						    : array[1..3] of byte;
 filters2						    : array[1..4] of byte;
 createinfo						    : ^createarray;
 iteminfo						    : ^iteminfotype;
   res2cargo						    : array[1..250] of Integer;
   history						    : array[1..32] of Integer;
   historyindex						    : Integer;
							     
function GetBuildTime(item : Integer):Integer;
var
   i : Integer;
begin
   for i:= 1 to maxcargo do
      if cargo[i].index = item then
      begin
         { special artifacts with id>6000 like "Glyptic Scythe" do not have entry creation.dta, so they default to 30000 
           while their timeleft in go2() is initialized to timeleft:=6000+random(5)*100, which causes progress bar to break.
           So initialize to worst case 6500 so we have something more reasonable for progressbar. }
         if bldcargo[i]=30000 then bldcargo[i] := 65;
	 GetBuildTime := bldcargo[i] * 100;
	 exit;
      end;
      GetBuildTime := 6500;
end;

function StartBuild(background : Boolean; root, item, team : Integer) :Integer;
var
   i, j, k : Integer;
begin
   i := 1;
   while (i <= maxcargo) and (cargo[i].index <> item) do inc(i);
   if i > maxcargo then {doesn't exist!}
   begin
      StartBuild := -2;
      exit;
   end;
   if prtcargo[i,1] = 0 then {can't be assembled}
   begin
      StartBuild := 0;
      exit;
   end;
   if (item = 3021) and (not chevent(18)) then {thermoplast can only be made after it's discovery}
   begin
      StartBuild := -3;
      exit;
   end;
   for j := 1 to 6 do {high enough level?}
      if lvlcargo[i,j] > ship.crew[j].level then
      begin
	 StartBuild := -1;
	 exit;
      end;
   k := 1; {how many of the first part are needed?}
   for j := 2 to 3 do
      if prtcargo[i,1] = prtcargo[i,j] then
	 inc(k);
   if InCargo(prtcargo[i,1]) < k then {check first part}
   begin
      if prtcargo[i,1] = item then
	 StartBuild := 0 {stop infinite recursion}
      else
	 StartBuild := StartBuild(background, root, prtcargo[i,1], team);
      exit;
   end;
   for j := 2 to 3 do
      if InCargo(prtcargo[i,j]) < 1 then
      begin
	 if prtcargo[i,j] = item then
	    StartBuild := 0 {stop infinite recursion}
	 else
	    StartBuild := StartBuild(background, root, prtcargo[i,j], team);
	 exit;
      end;
   ship.engrteam[team].job := item;
   ship.engrteam[team].extra := root;
   ship.engrteam[team].jobtype := 3;
   ship.engrteam[team].timeleft := GetBuildTime(item);
   for j := 1 to 3 do
      RemoveCargo(prtcargo[i,j]);
   RebuildCargoReserve;
   StartBuild := 1;
   for j := 1 to 6 do
      addxp(j, lvlcargo[i,j], ord(not background));
   teamjob := 0;
end;

function CheckBuildSubStock(item : Integer) :Integer;
var
   i, j, k, l : Integer;
begin
   i := InCargoIndex(item);
   if (i <> 0) and (ship.numcargo[i] - rescargo[i] - res2cargo[i] > 0) then
   begin {in stock}
      inc(res2cargo[i]);
      CheckBuildSubStock := 1;
      exit;
   end;
   i := 1;
   while (i <= maxcargo) and (cargo[i].index <> item) do inc(i);
   if i > maxcargo then {doesn't exist!}
   begin
      CheckBuildSubStock := -2;
      exit;
   end;
   for j := 1 to 6 do {high enough level?}
      if lvlcargo[i,j] > ship.crew[j].level then
      begin
	 CheckBuildSubStock := -1;
	 exit;
      end;
   if prtcargo[i,j] = 0 then
   begin
      CheckBuildSubStock := 0;
      exit;
   end;
   l := 2;
   for j := 1 to 3 do
   begin
      if prtcargo[i,j] = item then
	 k := 0 {stop infinite recursion}
      else
	 k := CheckBuildSubStock(prtcargo[i,j]);
      case k of
	-2 : l := -2;
	-1 : if l > -1 then l := -1;
	0  : if l > 0 then l := 0;
	{1..2: donothing;}
      end;
   end;
   CheckBuildSubStock := l;
end;

function CheckBuildStock(item : Integer):Integer;
var
   i, j, k, l : Integer;
begin
   for i := 1 to 250 do
      res2cargo[i] := 0;
   i := 1;
   while (i <= maxcargo) and (cargo[i].index <> item) do inc(i);
   if i > maxcargo then {doesn't exist!}
   begin
      CheckBuildStock := -2;
      exit;
   end;
   if prtcargo[i, 1] = 0 then {not a buildable item}
      CheckBuildStock := -2;
   for j := 1 to 6 do {high enough level?}
      if lvlcargo[i,j] > ship.crew[j].level then
      begin
	 CheckBuildStock := -1;
	 exit;
      end;
   l := 0;
   for j := 1 to 3 do
   begin
      k := CheckBuildSubStock(prtcargo[i,j]);
      case k of
	-2    : l := -2;
	-1..0: l := l or 0;
	1     : l := l or (1 shl (j + j - 2));
	2     : l := l or (2 shl (j + j - 2));
	{1..2: donothing;}
      end;
   end;
   CheckBuildStock := l;
end;

procedure HistoryClear;
var
   i : Integer;
begin
   for i := 1 to 32 do
      History[i] := 0;
   HistoryIndex := 0;
end; { HistoryClear }

procedure HistoryPush(index : Integer);
var
   i : Integer;
begin
   if HistoryIndex >= 32 then
   begin
      for i := 1 to 31 do
	 History[i] := History[i + 1];
      History[32] := index;
   end else begin
      inc(HistoryIndex);
      History[HistoryIndex] := index;
   end;
end; { HistoryAdd }

function HistoryPop: Integer;
begin
   if HistoryIndex <= 0 then
   begin
      HistoryPop := 0;
      exit;
   end;
   HistoryPop := History[HistoryIndex];
   dec(HistoryIndex);
end; { HistoryPop }

procedure opendoors;
begin
   if ship.options[OPT_ANIMATION]=0 then
   begin
      fadestep(1);
      for i:=20 to 130 do
	 fillchar(screen[i,90],144,0);
      for i:=110 to 126 do
	 move(cargobuttons^[i,92],screen[i,92],34*4);
   end
   else
      for a:=0 to 109 do
      begin
	 fadestep(1);
	 delay(tslice div 4);
	 for i:=20 to 130-a do
	    move(screen[i+1,90],screen[i,90],36*4);
	 if ((131-a)<127) and ((131-a)>109) then
	    move(cargobuttons^[131-a,92],screen[131-a,92],34*4);
      end;
   plainfadearea(38,78,40,82,-12);
   plainfadearea(44,78,46,82,12);
end;

procedure closedoors;
var temp: pscreentype;
begin
 if ship.options[OPT_ANIMATION]=0 then exit;
 mousehide;
 new(temp);
 loadscreen('data/cargo',temp);
 for i:=110 to 126 do
  fillchar(temp^[i,94],133,0);
 for a:=1 to 110 do
  begin
   delay(tslice div 4);
   for i:=20 to 20+a do
    move(temp^[110-a+i,90],screen[i,90],36*4);
  end;
 dispose(temp);
 mouseshow;
 plainfadearea(38,78,40,82,12);
 plainfadearea(44,78,46,82,-12);
end;

procedure newcursor(start: integer);
var finished: boolean;
begin
 cargoindex:=start;
 finished:=false;
 if cargoindex=251 then exit;
 repeat
  inc(cargoindex);
  case ship.cargo[cargoindex] of
   1000..1499: if filters2[1]=1 then finished:=true;
   1500..1999: if filters2[2]=1 then finished:=true;
   2000..3999: if filters2[4]=1 then finished:=true;
   4000..5999: if filters2[3]=1 then finished:=true;
   6000..6999: if filters2[4]=1 then finished:=true;
  end;
 until (finished) or (cargoindex=251);
end;

procedure revnewcursor(start: integer);
var finished: boolean;
begin
 cargoindex:=start;
 finished:=false;
 if cargoindex<1 then exit;
 repeat
  dec(cargoindex);
  case ship.cargo[cargoindex] of
   1000..1499: if filters2[1]=1 then finished:=true else dec(cargoindex);
   1500..1999: if filters2[2]=1 then finished:=true else dec(cargoindex);
   2000..3999,6000..6999: if filters2[4]=1 then finished:=true else dec(cargoindex);
   4000..5999: if filters2[3]=1 then finished:=true else dec(cargoindex);
  end;
 until (finished) or (cargoindex<1);
end;

procedure drawfilters;
var a,b: integer;
begin
 for a:=1 to 2 do
  for b:=0 to 1 do
   for i:=72+a*5 to 74+a*5 do
    for j:=269+b*9 to 276+b*9 do
     screen[i,j]:=48+filters2[a+b*2]*8;
end;

procedure readydata;
begin
   mousehide;
   {compressfile(tempdir+'/current',@screen);}
   quicksavescreen(tempdir+'/current',@screen, true);
   {fading;}
   fadefull(-8, 20);
   playmod(true,'sound/CARGO.MOD');
   loadscreen('data/cargo',@screen);
   new(cargobuttons);
   for i:=110 to 126 do
   begin
      move(screen[i,92],cargobuttons^[i,92],34*4);
      fillchar(screen[i,94],133,0);
   end;
   plainfadearea(38,78,40,82,12);
   drawfilters;
   fadein;
   opendoors;
   dispose(cargobuttons);
   mouseshow;
   done:=false;
   newcursor(0);
   cargomode:=0;
   lightindex:=232;
   bkcolor:=0;
   oldt1:=t1;
end;

procedure checklist(down: boolean);
var str1: string[3];
var str2: string[3];
begin
 if (x<1) or (x>250) then exit;
 str(rescargo[x]:3,str2);
 case ship.cargo[x] of
            0: ;
   1000..1499: if filters2[1]=1 then
                begin
                 if down then dec(y) else inc(y);
                 str(ship.numcargo[x]:3,str1);
                 j:=1;
                 while cargo[j].index<>ship.cargo[x] do inc(j);
                 printxy(96-10,16+y*6,str1+'('+str2+')'+cargo[j].name);
                end;
   1500..1999: if filters2[2]=1 then
                begin
                 if down then dec(y) else inc(y);
                 str(ship.numcargo[x]:3,str1);
                 j:=1;
                 while cargo[j].index<>ship.cargo[x] do inc(j);
                 printxy(96-10,16+y*6,str1+'('+str2+')'+cargo[j].name);
                end;
   2000..3999: if filters2[4]=1 then
                begin
                 if down then dec(y) else inc(y);
                 str(ship.numcargo[x]:3,str1);
                 j:=1;
                 while cargo[j].index<>ship.cargo[x] do inc(j);
                 printxy(96-10,16+y*6,str1+'('+str2+')'+cargo[j].name);
                end;
   4000..5999: if filters2[3]=1 then
                begin
                 if down then dec(y) else inc(y);
                 str(ship.numcargo[x]:3,str1);
                 j:=1;
                 while cargo[j].index<>ship.cargo[x] do inc(j);
                 printxy(96-10,16+y*6,str1+'('+str2+')'+cargo[j].name);
                end;
   6000..6999: if filters2[4]=1 then
                begin
                 if down then dec(y) else inc(y);
                 getartifactname(ship.cargo[x]);
                 str(ship.numcargo[x]:3,str1);
                 printxy(96-10,16+y*6,str1+'     '+cargo[maxcargo].name);
                end;
  end;
end;

procedure displaylist;
begin
 if ship.cargo[cargoindex]=0 then
  begin
   newcursor(cargoindex);
   if cargoindex=251 then revnewcursor(cargoindex);
  end;
 tcolor:=28;
 bkcolor:=0;
 x:=cargoindex-1;
 mousehide;
 y:=7;
 repeat
  checklist(true);
  dec(x);
 until (y=1) or (x<1);
 if y>1 then
  for i:=23 to 16+y*6 do
   fillchar(screen[i,92],133,0);
 bkcolor:=6;
 x:=cargoindex;
 y:=6;
 repeat
  checklist(false);
  bkcolor:=0;
  inc(x);
 until (y=14) or (x>251);
 if y<14 then
  for i:=23+y*6 to 106 do
   fillchar(screen[i,92],133,0);
 mouseshow;
end;

procedure displayinfo;
var s: string[9];
    draw: boolean;
begin
 if ship.cargo[cargoindex]=0 then
  begin
   newcursor(cargoindex);
   if cargoindex=251 then newcursor(0);
  end;
 if cargoindex=0 then exit;
 x:=cargoindex;
 tcolor:=28;
 bkcolor:=6;
 y:=0;
 mousehide;
 repeat
  while (x<251) and (ship.cargo[x]=0) do inc(x);
  draw:=false;
  case ship.cargo[x] of
   1000..1499: if filters2[1]=1 then draw:=true;
   1500..1999: if filters2[2]=1 then draw:=true;
   2000..3999,6000..6999: if filters2[4]=1 then draw:=true;
   4000..5999: if filters2[3]=1 then draw:=true;
  end;
  if (x<251) and (draw) then
   begin
    if ship.cargo[x]>6000 then
     begin
      j:=maxcargo;
      getartifactname(ship.cargo[x]);
     end
    else
     begin
      j:=1;
      while ship.cargo[x]<>cargo[j].index do inc(j);
     end;
    inc(y);
    printxy(92,2+y*20,cargo[j].name);
    if y>0 then bkcolor:=0;
    case ship.cargo[x] of
     1000..1499: s:='Weapon   ';
     1500..1999: s:='Shield   ';
     2000..2999: s:='Device   ';
     3000..3999: s:='Component';
     4000..5999: s:='Material ';
     6000..6999: s:='Artifact ';
     else s:='         ';
    end;
    printxy(100,8+y*20,'Type: '+s);
    x1:=cargo[j].size/10;
    str(x1:7:1,s);
    printxy(100,14+y*20,'Size:'+s);
    str(ship.numcargo[x]:3,s);
    printxy(175,14+y*20,'Num:'+s);
   end;
  inc(x);
 until (y=4) or (x>250);
 if y<4 then
  for i:=22+y*20 to 106 do
   fillchar(screen[i,92],133,0);
 mouseshow;
end;

function request(s: string; alt,text: integer): integer;
type
 scrtype=array[40..140,74..245] of byte;
var
 cursor,lastx,lasty,result: integer;
 tempscr: ^scrtype;
 done: boolean;

 procedure undocursor2;
 begin
  case cursor of
   0: exit;
   1: plainfadearea(78,78,128,92,-3);
   2: plainfadearea(135,78,185,92,-3);
   3: plainfadearea(192,78,242,92,-3);
  end;
 end;

 procedure drawcursor2;
 begin
  case cursor of
   0: exit;
   1: plainfadearea(78,78,128,92,3);
   2: plainfadearea(135,78,185,92,3);
   3: plainfadearea(192,78,242,92,3);
  end;
 end;

 procedure processkey2;
 var ans: char;
 begin
  undocursor2;
  ans:=readkey_utf8;
  case upcase(ans) of
    #0:begin
        ans:=readkey;
        case ans of
         #75,#77:if cursor=1 then cursor:=2 else cursor:=1;
        end;
       end;
   #13:if cursor<>0 then done:=true;
   #27: begin
         cursor:=4;
         done:=true;
        end;
   'A': begin
         cursor:=1;
         done:=true;
        end;
   'H': begin
         cursor:=2;
         done:=true;
        end;
   'O','1': begin
             cursor:=3;
             done:=true;
            end;
  #10: printbigbox(GetHeapStats1,GetHeapStats2);
  end;
  drawcursor2;
  lastx:=mouse.x;
  lasty:=mouse.y;
 end;

 procedure findmouse2;
 var button: boolean;
     newcursor: integer;
 begin
  if mouse.getstatus then button:=true else button:=false;
  if (not button) and (mouse.x=lastx) or (mouse.y=lasty) then exit;
  case mouse.y of
   78..92: case mouse.x of
             78..128: newcursor:=1;
            135..185: newcursor:=2;
            192..242: newcursor:=3;
            else newcursor:=0;
           end;
   else newcursor:=0;
  end;
  if newcursor<>cursor then
   begin
    undocursor2;
    cursor:=newcursor;
    drawcursor2;
   end;
  if (cursor<>0) and (button) then done:=true;
 end;

 function mainloop2: integer;
 begin
  done:=false;
  lastx:=0;
  lasty:=0;
  cursor:=0;
  mouseshow;
  repeat
   findmouse2;
   if fastkeypressed then processkey2;
  until done;
  mainloop2:=cursor;
 end;

begin
 new(tempscr);
 mousehide;
 tcolor:=text;
 for i:=60 to 102 do
  move(screen[i,74],tempscr^[i,74],43*4);
 tcolor:=text-5;
 bkcolor:=35+alt;
 button(75,60,245,102,alt);
 button(78,78,128,92,2+alt);
 button(135,78,185,92,2+alt);
 button(192,78,242,92,2+alt);
 printxy(156-round(length(s)*2.5),65,s);
 bkcolor:=37+alt;
 printxy(92,82,'All');
 printxy(146,82,'Half');
 printxy(206,82,'One');
 result:=mainloop2;
 mousehide;
 for i:=60 to 102 do
  move(tempscr^[i,74],screen[i,74],43*4);
 dispose(tempscr);
 request:=result;
 bkcolor:=3;
 mouseshow;
// mouse.x:=0;
// mouse.y:=0;
    move_mouse(0,0);
end;

procedure dropit;
var s: string[20];
begin
   if (cargoindex=0) or (cargoindex=251) then exit;
   if (ship.cargo[cargoindex]=1056) or (ship.cargo[cargoindex]>6899) then
   begin
      a:=ship.options[OPT_MSGS];
      ship.options[OPT_MSGS]:=2;
      printbigbox('That item is too vital','to jettison!');
      ship.options[OPT_MSGS]:=a;
      exit;
   end;
   if rescargo[cargoindex] >= ship.numcargo[cargoindex] then
   begin
      a:=ship.options[OPT_MSGS];
      ship.options[OPT_MSGS]:=2;
      printbigbox('Can''t jettison that!','It''s needed for building.');
      ship.options[OPT_MSGS]:=a;
      exit;
   end;
   j:=1;
   while cargo[j].index<>ship.cargo[cargoindex] do inc(j);
   s:=cargo[j].name;
   i:=20;
   while (cargo[j].name[i]=' ') do dec(i);
   s[0]:=chr(i);
   j:=request('Jettison '+s+'?',0,31);
   case j of
     1 : begin
	    ship.numcargo[cargoindex]:=0;
	    ship.cargo[cargoindex]:=0;
	    revnewcursor(cargoindex);
	    if cargoindex<1 then newcursor(1);
	 end;
     2 : begin
	    dec(ship.numcargo[cargoindex],ship.numcargo[cargoindex] div 2);
	    if ship.numcargo[cargoindex]=0 then
	    begin
	       ship.cargo[cargoindex]:=0;
	       revnewcursor(cargoindex);
	       if cargoindex<1 then newcursor(1);
	    end;
	 end;
     3 : begin
	    if ship.numcargo[cargoindex]=1 then
	    begin
	       ship.numcargo[cargoindex]:=0;
	       ship.cargo[cargoindex]:=0;
	       revnewcursor(cargoindex);
	       if cargoindex<1 then newcursor(1);
	    end
	    else dec(ship.numcargo[cargoindex]);
	 end;
   end;
   bkcolor:=0;
end;

procedure findcargcursor;
begin
 if cargomode=0 then y:=((mouse.y-22) div 6)-6
  else y:=(mouse.y-22) div 20;
 if y=0 then exit;
 while (y>0) and (cargoindex<251) do
  begin
   newcursor(cargoindex);
   dec(y);
  end;
 while (y<0) and (cargoindex>0) do
  begin
   revnewcursor(cargoindex);
   inc(y);
  end;
 if cargoindex>250 then revnewcursor(251);
 if cargoindex<=0 then newcursor(0);
end;

procedure findmouse;
begin
 if not mouse.getstatus then exit;
 case mouse.x of
  94..102: case mouse.y of
              22..106: findcargcursor;
             110..126: done:=true;
            end;
  104..113: case mouse.y of
              22..106: findcargcursor;
             110..126: dropit;
            end;
  115..159: case mouse.y of
              22..106: findcargcursor;
             110..117: begin
                        if filters2[1]=0 then filters2[1]:=1 else filters2[1]:=0;
                        newcursor(0);
                        drawfilters;
                       end;
             119..126: begin
                        if filters2[2]=0 then filters2[2]:=1 else filters2[2]:=0;
                        newcursor(0);
                        drawfilters;
                       end;
            end;
  161..204: case mouse.y of
              22..106: findcargcursor;
             110..117: begin
                        if filters2[3]=0 then filters2[3]:=1 else filters2[3]:=0;
                        newcursor(0);
                        drawfilters;
                       end;
             119..126: begin
                        if filters2[4]=0 then filters2[4]:=1 else filters2[4]:=0;
                        newcursor(0);
                        drawfilters;
                       end;
            end;
  206..215: case mouse.y of
              22..106: findcargcursor;
             110..126: begin
                        if cargomode=1 then cargomode:=0 else cargomode:=1;
                        for i:=22 to 106 do
                         fillchar(screen[i,90],140,0);
                        newcursor(0);
                       end;
            end;
  217..226: case mouse.y of
              22..106: findcargcursor;
             110..117: begin
                        if cargoindex>1 then revnewcursor(cargoindex)
                         else revnewcursor(251);
                        if cargoindex=0 then newcursor(0);
                       end;
             119..126: begin
                        newcursor(cargoindex);
                        if cargoindex=251 then revnewcursor(251);
                       end;
            end;
  236..250: if (mouse.y>71) and (mouse.y<91) and yesnorequest('PRINT CARGO?',0,31) then printcargo;
 end;
 if cargoindex>250 then
  begin
   cargoindex:=0;
   mousehide;
   for i:=22 to 106 do
    fillchar(screen[i,90],140,0);
   mouseshow;
  end;
 if cargomode=0 then displaylist else displayinfo;
 idletime:=0;
end;

procedure processkey;
var ans: char;
begin
 ans:=readkey_utf8;
 case upcase(ans) of
  #27,'Q': done:=true;
  #0: begin
       ans:=readkey;
       case ans of
        #72:begin
             if cargoindex>1 then revnewcursor(cargoindex)
              else revnewcursor(251);
             if cargoindex=0 then newcursor(0);
            end;
        #80: begin
              newcursor(cargoindex);
              if cargoindex=251 then revnewcursor(251);
             end;
        #81: begin
              move_mouse(mouse.x,98);
              findcargcursor;
             end;
        #73: begin
              move_mouse(mouse.x,22);
              findcargcursor;
             end;
       end;
      end;
  '1': begin
        if filters2[1]=0 then filters2[1]:=1 else filters2[1]:=0;
        newcursor(1);
        drawfilters;
       end;
  '2': begin
        if filters2[2]=0 then filters2[2]:=1 else filters2[2]:=0;
        newcursor(1);
        drawfilters;
       end;
  '3': begin
        if filters2[3]=0 then filters2[3]:=1 else filters2[3]:=0;
        newcursor(1);
        drawfilters;
       end;
  '4': begin
        if filters2[4]=0 then filters2[4]:=1 else filters2[4]:=0;
        newcursor(1);
        drawfilters;
       end;
  'D': dropit;
  '`': bossmode;
  '/','?': begin
            if cargomode=1 then cargomode:=0 else cargomode:=1;
            for i:=22 to 106 do
             fillchar(screen[i,90],140,0);
            newcursor(0);
           end;
  #10: printbigbox(GetHeapStats1,GetHeapStats2);
 end;
 if cargoindex>250 then
  begin
   cargoindex:=0;
   mousehide;
   for i:=22 to 106 do
    fillchar(screen[i,90],140,0);
   mouseshow;
  end;
 if cargomode=0 then displaylist else displayinfo;
 idletime:=0;
end;

procedure animation;
begin
 setrgb256(lightindex,0,0,0);
 inc(lightindex);
 if lightindex=240 then lightindex:=232;
 setrgb256(lightindex,0,0,48);
 mousehide;
 for i:=77 to 78 do
  for j:=240 to 246 do
   if random(2)=0 then screen[i,j]:=63 else screen[i,j]:=0;
 mouseshow;
end;

procedure mainloop;
begin
 repeat
  fadestep(8);
  findmouse;
  if fastkeypressed then processkey;
  inc(idletime);
  if idletime=maxidle then screensaver;
  animation;
  if batindex<8 then inc(batindex) else
   begin
    batindex:=0;
    addtime2;
    if cargomode=0 then displaylist else displayinfo;
   end;
  delay(tslice*4);
 until done;
end;

procedure removedata;
begin
   mousehide;
   {fading;}
   {fadefull(-8, 20);}
   fadestopmod(-8, 20);
   mouse.setmousecursor(random(3));
   {loadscreen(tempdir+'/current',@screen);}
   quickloadscreen(tempdir+'/current',@screen, true);
   showresearchlights;
   bkcolor:=3;
   displaytextbox(false);
   textindex:=25;
   if (viewmode=11) and (viewlevel=2) then displaybotinfo(6);
   {fadein;}
   mouseshow;
   anychange:=true;
   t1:=oldt1;
end;

procedure inventory;
begin
 readydata;
 displaylist;
 mainloop;
 closedoors;
 {stopmod;}
 removedata;
end;

{***************************************************************************}

procedure inccursor;
begin
 drawit:=false;
 if cargomode=0 then
 repeat
  inc(cargoindex);
  i:=0;
  for j:=1 to 6 do if ship.crew[j].level>=createinfo^[cargoindex].levels[j] then inc(i);
  case createinfo^[cargoindex].index of
      0..2999: if filters[3]=1 then drawit:=true;
   3000..3999: if filters[2]=1 then drawit:=true;
   4000..4999: if filters[1]=1 then drawit:=true;
  end;
 until ((i=6) and (drawit)) or (cargoindex>maxcreation)
 else
  repeat
   inc(cargoindex);
   while (cargoindex<251) and (ship.numcargo[cargoindex]=0) do inc(cargoindex);
   case ship.cargo[cargoindex] of
      0..2999,6000..6999: if filters[3]=1 then drawit:=true;
   3000..3999: if filters[2]=1 then drawit:=true;
   4000..4999: if filters[1]=1 then drawit:=true;
  end;
  until (drawit) or (cargoindex>250);
 if (qmode) and (viewteam>0) then
  begin
   viewteam:=0;
   for i:=77 to 80 do
    fillchar(screen[i,222],77,0);
  end;
 anychange:=true;
end;

procedure deccursor;
begin
 drawit:=false;
 if cargomode=0 then
 repeat
  dec(cargoindex);
  i:=0;
  for j:=1 to 6 do if ship.crew[j].level>=createinfo^[cargoindex].levels[j] then inc(i);
  case createinfo^[cargoindex].index of
      0..2999: if filters[3]=1 then drawit:=true;
   3000..3999: if filters[2]=1 then drawit:=true;
   4000..4999: if filters[1]=1 then drawit:=true;
  end;
 until ((i=6) and (drawit)) or (cargoindex<1)
 else
  repeat
   dec(cargoindex);
   while (cargoindex>0) and (ship.numcargo[cargoindex]=0) do dec(cargoindex);
   case ship.cargo[cargoindex] of
      0..2999,6000..6999: if filters[3]=1 then drawit:=true;
   3000..3999: if filters[2]=1 then drawit:=true;
   4000..4999: if filters[1]=1 then drawit:=true;
  end;
  until (drawit) or (cargoindex<1);
 if (qmode) and (viewteam>0) then
  begin
   viewteam:=0;
   for i:=77 to 80 do
    fillchar(screen[i,222],77,0);
  end;
 anychange:=true;
end;

procedure adjustteams;
var a: integer;
begin
 mousehide;
 for a:=1 to 3 do
  begin
   if (ship.engrteam[a].job=0) and (screen[114+a*10,204]=95) then anychange:=true;
   if ship.engrteam[a].job=0 then i:=60 else i:=95;
    for j:=204 to 207 do
     screen[114+a*10,j]:=i;
  end;
{ if ship.research and 4>0 then
  begin
   i:=0;
   for j:=1 to 3 do if ship.engrteam[j].job>0 then inc(i);
   if i>1 then
    begin
     dec(ship.research,4);
     mouseshow;
     showchar(2,'Cancelling research.  Teams too busy.');
     mousehide;
    end;
  end;}
 mouseshow;
end;

procedure drawfilters2;
var b: integer;
begin
 mousehide;
 for b:=1 to 3 do
  begin
   if filters[b]=1 then i:=60 else i:=95;
   for j:=51 to 54 do
    screen[114+b*11,j]:=i;
  end;
 mouseshow;
end;

procedure opendoors2;
var a,b: integer;
    temppal: paltype;
begin
 temppal[0,1]:=0;             // to turn off warnings, variables are actually correctly initialized by function below
 fillchar(temppal,sizeof(paltype),0);
 for j:=112 to 159 do
  temppal[j]:=colors[j];
 set256colors(temppal);
 delay(tslice*18);
 b:=tslice div 3;
 for a:=1 to 31 do
  begin
   for i:=1 to 3 do
    begin
     for j:=0 to 111 do
      temppal[j,i]:=round(a*colors[j,i]/31);
     for j:=160 to 255 do
      temppal[j,i]:=round(a*colors[j,i]/31);
    end;
   set256colors(temppal);
   delay(b);
  end;
end;

procedure readycreationdata;
var crfile: file of createarray;
begin
   if not chevent(18) then maxcreation:=totalcreation-1 else maxcreation:=totalcreation;
   mousehide;
   {compressfile(tempdir+'/current',@screen);}
   quicksavescreen(tempdir+'/current',@screen, true);
   {fading;}
   {fadefull(-8, 20);}
   fadestopmod(-8, 20);
   playmod(true,'sound/COMPONT.MOD');
   loadscreen('data/tech1',@screen);
   drawfilters2;
   new(iteminfo);
   done:=false;
   bkcolor:=0;
   lastinfo:=0;
   cargomode:=0;
   cargoindex:=0;
   oldt1:=t1;
   tcolor:=31;
   new(createinfo);
   assign(crfile,'data/creation.dta');
   reset(crfile);
   if ioresult<>0 then errorhandler('creation.dta',1);
   read(crfile,createinfo^);
   if ioresult<>0 then errorhandler('creation.dta',5);
   close(crfile);
   for j:=95 to 98 do
   begin
      screen[6,j]:=63;
      screen[14,j]:=95;
   end;
   if qmode then
      for i:=6 to 14 do
      begin
	 screen[i,34]:=63;
	 screen[i,33]:=63;
      end
      else
	 for i:=6 to 14 do
	 begin
	    screen[i,34]:=95;
	    screen[i,33]:=95;
	 end;
   if colorcode then fillchar(screen[125,69],4,63);
   viewteam:=0;
   {if ship.options[OPT_ANIMATION]=1 then opendoors2 else fadein;}
   inccursor;
   mouseshow;
end;

procedure displaybreakdown(item: integer);
var s1,s2: string[15];
    s: string[19];
    k: integer;
begin
   if item=0 then exit;
   lastinfo:=item;
   mousehide;
   tcolor:=28;
   if item>6000 then
   begin
      getartifactname(item);
      s:=cargo[maxcargo].name;
   end
   else
   begin
      a:=1;
      while (createinfo^[a].index<>item) and (a<totalcreation{maxcreation}) do inc(a);
      str(item,s1);
      if (a=totalcreation{maxcreation}) and (createinfo^[a].index<>item) then
	 errorhandler('creation array overflow: '+s1,6);
      s:=createinfo^[a].name;
   end;
   i:=1;
   while (i<19) and (s[i]<>' ') do inc(i);
   s1:=copy(s,0,i-1);
   s2:=copy(s,i+1,19-i);
   i:=length(s2);
   while (i>1) and (s2[i]=' ') do dec(i);
   s2[0]:=chr(i);
   printxy(217+round((78-length(s1)*5)/2),59,s1);
   printxy(217+round((78-length(s2)*5)/2),65,s2);
   if item<6000 then
   begin
      if (cargomode=0) and (viewteam=0) then
	 k := CheckBuildStock(item);
      for j:=1 to 3 do
      begin
	 i:=createinfo^[a].parts[j];
	 if (cargomode=0) and (viewteam=0) then
	 begin
	    if k >= 0 then
	    begin
	       case ((k shr (j + j - 2)) and 3) of
		 0 : tcolor := 95;
		 1 : tcolor := 63;
		 2 : tcolor := 127;
	       end;
	    end else
	       tcolor:=95;
	    {
	    k:=1;
	    if createinfo^[a].parts[2]=createinfo^[a].parts[1] then inc(k);
	    if createinfo^[a].parts[3]=createinfo^[a].parts[1] then inc(k);
	    if (j<=k) and (incargo(createinfo^[a].parts[1])>=j) then tcolor:=63
	       else if (j>k) and (incargo(createinfo^[a].parts[j])>0) then tcolor:=63
	       else tcolor:=95;
	    }
	 end else tcolor:=26;
	 b:=1;
	 while (cargo[b].index<>i) do inc(b);
	 s:=cargo[b].name;
	 i:=1;
	 while (i<19) and (s[i]<>' ') do inc(i);
	 s1:=copy(s,0,i-1);
	 s2:=copy(s,i+1,19-i);
	 i:=length(s2);
	 while (i>1) and (s2[i]=' ') do dec(i);
	 s2[0]:=chr(i);
	 printxy(127+round((78-length(s1)*5)/2),j*21+19,s1);
	 printxy(127+round((78-length(s2)*5)/2),j*21+25,s2);
      end;
   end
   else
   begin
      printxy(146,61,'Research');
      printxy(146,67,'Artifact');
   end;
   mouseshow;
end;

procedure weaponinfo(n: integer);
var str1: string[5];
begin
 tcolor:=31;
 bkcolor:=1;
 printxy(127,2,cargo[n].name);
 tcolor:=95;
 str((weapons[n].range div 1000):3,str1);
 printxy(127,11,' Range: '+str1+' KKM');
 str(weapons[n].energy:4,str1);
 printxy(127,17,'Energy:'+str1+' GW');
 str(weapons[n].damage:4,str1);
 printxy(127,23,'Damage:'+str1+' GJ');
 printxy(230,5, 'PSION');
 printxy(230,11,'PRTCL');
 printxy(230,17,'INTRL');
 printxy(230,23,'ENRGY');
 for j:=1 to 4 do
  begin
   x:=round(weapons[n].dmgtypes[j]/2);
   for i:=-1 to 4 do
    begin
     if i>0 then y:=100-i
      else y:=100+i;
     fillchar(screen[1+i+j*6,260],x,y);
     if x<50 then
      fillchar(screen[1+i+j*6,260+x],50-x,0);
    end;
  end;
 if n<59 then readweaicon(n-1) else readweaicon(n-2);
 for i:=0 to 19 do
  move(tempicon^[i],screen[9+i,210],5*4);
 bkcolor:=0;
end;

procedure getinfo;
var f	 : file of iteminfotype;
   index : integer;
{   s	 : String;}
begin
 if cargoindex=0 then exit;
 assign(f,'data/iteminfo.dta');
 reset(f);
 if ioresult<>0 then errorhandler('iteminfo.dta',1);
 if cargomode=0 then index:=createinfo^[cargoindex].index
  else
   begin
    index:=ship.cargo[cargoindex];
    if index>6000 then getartifactname(ship.cargo[cargoindex]);
    if (index=3000) or (index=4000) then
     begin
      ship.cargo[cargoindex]:=0;
      i:=ship.numcargo[cargoindex];
      ship.numcargo[cargoindex]:=0;
      for j:=1 to i do addcargo(index+random(20)+1, true);
      index:=ship.cargo[cargoindex];
      anychange:=true;
      dec(cargoindex);
      inccursor;
      if ((cargomode=0) and (cargoindex>maxcreation)) or
       ((cargomode=1) and (cargoindex>250)) then
        begin
         cargoindex:=0;
         inccursor;
         if ((cargomode=0) and (cargoindex>maxcreation)) or
          ((cargomode=1) and (cargoindex>250)) then cargoindex:=0;
        end;
     end;
   end;
 i:=0;
 if index>0 then
  repeat
   inc(i);
   read(f,iteminfo^);
//   writeln('ioresult=',ioresult,' \n');
   if ioresult<>0 then errorhandler('iteminfo.dta @ cargtool.pas:1249',5);
  until (iteminfo^.index=index) or (i=totalcreation);
 close(f);
 tcolor:=24;
 bkcolor:=165;
 mousehide;
 if cargomode=0 then printxy(1,160,createinfo^[cargoindex].name)
  else
   begin
    if ship.cargo[cargoindex]>6000 then j:=maxcargo
    else
     begin
      j:=1;
      while (cargo[j].index<>ship.cargo[cargoindex]) do inc(j);
     end;
    printxy(1,160,cargo[j].name);
   end;
 tcolor:=18;
 bkcolor:=2;
 if (i=totalcreation) and (iteminfo^.index<>index) then
  begin
   for i:=175 to 195 do
    fillchar(screen[i,6],140,2);
   if index<6000 then printxy(1,169,'Fabricated Material        ')
    else printxy(1,169,'Unknown Alien Artifact     ');
  end
 else
  for j:=0 to 3 do
   printxy(1,169+j*6,iteminfo^.info[j]);
 bkcolor:=0;
 if viewteam=0 then
  begin
   for j:=0 to 2 do
    for i:=0 to 13 do
     fillchar(screen[j*21+40+i,131],79,0);
   for i:=59 to 72 do
    fillchar(screen[i,221],79,0);
   displaybreakdown(index);
     {str(GetBuildTime(index),s);
     printxy(5,5,s);}
  end;
 if (index>999) and (index<1500) then weaponinfo(index-999)
  else if (index>1499) and (index<2000) then weaponinfo(index-1442)
  else for i:=3 to 29 do
        fillchar(screen[i,132],180,1);
 mouseshow;
end;

procedure displaydevices;
var k: integer;
begin
 anychange:=false;
 if (qmode) and (cargoindex>0) then getinfo;
 x:=cargoindex;
 y:=9;
 mousehide;
 if x>0 then
  repeat
   drawit:=false;
   i:=0;
   for j:=1 to 6 do if ship.crew[j].level>=createinfo^[x].levels[j] then inc(i);
   case createinfo^[x].index of
       0..2999: begin
                 if filters[3]=1 then drawit:=true;
                 tcolor:=47;
                end;
    3000..3999: begin
                 if filters[2]=1 then drawit:=true;
                 tcolor:=79;
                end;
    4000..4999: begin
                 if filters[1]=1 then drawit:=true;
                 tcolor:=143;
                end;
   end;
   if (i=6) and (drawit) then
    begin
     dec(y);
     if y=8 then bkcolor:=6 else bkcolor:=0;
     k:=0;
     for j:=1 to 3 do if createinfo^[x].parts[j]=createinfo^[x].parts[1] then inc(k);
     if (incargo(createinfo^[x].parts[1])<k) or
        (incargo(createinfo^[x].parts[2])=0) or
        (incargo(createinfo^[x].parts[3])=0)
       then begin if not colorcode then tcolor:=16; end else tcolor:=31;
     printxy(6,16+y*6,createinfo^[x].name);
    end;
   dec(x);
  until (y=1) or (x<1);
 if y>1 then
  for i:=22 to y*6+16 do
   fillchar(screen[i,11],100,0);
 x:=cargoindex+1;
 y:=8;
 bkcolor:=0;
 repeat
  drawit:=false;
  i:=0;
  for j:=1 to 6 do if ship.crew[j].level>=createinfo^[x].levels[j] then inc(i);
  case createinfo^[x].index of
       0..2999: begin
                 if filters[3]=1 then drawit:=true;
                 tcolor:=47;
                end;
    3000..3999: begin
                 if filters[2]=1 then drawit:=true;
                 tcolor:=79;
                end;
    4000..4999: begin
                 if filters[1]=1 then drawit:=true;
                 tcolor:=143;
                end;
  end;
  if (i=6) and (drawit) and (x<=maxcreation) then
   begin
    inc(y);
    k:=0;
    for j:=1 to 3 do if createinfo^[x].parts[j]=createinfo^[x].parts[1] then inc(k);
    if (incargo(createinfo^[x].parts[1])<k) or
       (incargo(createinfo^[x].parts[2])=0) or
       (incargo(createinfo^[x].parts[3])=0)
      then begin if not colorcode then tcolor:=16; end else tcolor:=31;
    printxy(6,16+y*6,createinfo^[x].name);
   end;
  inc(x);
 until (y=16) or (x>maxcreation);
 if y<16 then
  for i:=y*6+23 to 118 do
   fillchar(screen[i,11],100,0);
 mouseshow;
end;

procedure displaycargo;
begin
 anychange:=false;
 if ship.cargo[cargoindex]=0 then inccursor;
 if (qmode) and (cargoindex>0) then getinfo;
 if cargoindex=0 then
  begin
   for i:=22 to 118 do
    fillchar(screen[i,11],100,0);
   exit;
  end;
 y:=9;
 x:=cargoindex;
 tcolor:=31;
 mousehide;
 repeat
  drawit:=false;
  while (x>0) and (ship.numcargo[x]=0) do dec(x);
  if x>0 then
   case ship.cargo[x] of
       0..2999,6000..6999:
                begin
                 if filters[3]=1 then drawit:=true;
                 tcolor:=47;
                end;
    3000..3999: begin
                 if filters[2]=1 then drawit:=true;
                 tcolor:=79;
                end;
    4000..4999: begin
                 if filters[1]=1 then drawit:=true;
                 tcolor:=143;
                end;
   end;
  if not colorcode then tcolor:=31;
  if drawit then
   begin
    if ship.cargo[x]>6000 then
     begin
      getartifactname(ship.cargo[x]);
      i:=maxcargo;
     end
    else
     begin
      i:=1;
      while (cargo[i].index<>ship.cargo[x]) do inc(i);
     end;
    dec(y);
    if y=8 then bkcolor:=6 else bkcolor:=0;
    printxy(6,16+y*6,cargo[i].name);
   end;
  dec(x);
 until (y=1) or (x<1);
 if y>1 then
  for i:=22 to 16+y*6 do
   fillchar(screen[i,11],100,0);
 x:=cargoindex+1;
 y:=8;
 bkcolor:=0;
 repeat
  drawit:=false;
  while (x<251) and (ship.numcargo[x]=0) do inc(x);
  case ship.cargo[x] of
       0..2999,6000..6999:
                begin
                 if filters[3]=1 then drawit:=true;
                 tcolor:=47;
                end;
    3000..3999: begin
                 if filters[2]=1 then drawit:=true;
                 tcolor:=79;
                end;
    4000..4999: begin
                 if filters[1]=1 then drawit:=true;
                 tcolor:=143;
                end;
  end;
  if not colorcode then tcolor:=31;
  if (drawit) and (x<251) then
   begin
    if ship.cargo[x]>6000 then
     begin
      getartifactname(ship.cargo[x]);
      i:=maxcargo;
     end
    else
     begin
      i:=1;
      while (cargo[i].index<>ship.cargo[x]) do inc(i);
     end;
    inc(y);
    printxy(6,16+y*6,cargo[i].name);
   end;
  inc(x);
 until (y=16) or (x>250);
 if y<16 then
  for i:=y*6+23 to 118 do
   fillchar(screen[i,11],100,0);
 mouseshow;
end;

procedure displayteaminfo(team: integer);
var b : integer;
begin
   tcolor:=31;
   adjustteams;
   if ship.engrteam[team].job=0 then
   begin
      mousehide;
      for j:=0 to 2 do
	 for i:=0 to 13 do
	    fillchar(screen[j*21+40+i,131],79,0);
      for i:=59 to 72 do
	 fillchar(screen[i,221],79,0);
      for i:=77 to 80 do
	 fillchar(screen[i,222],77,0);
      viewteam:=0;
      mouseshow;
      exit;
   end;
   mousehide;
   if teamjob <> ship.engrteam[team].job then
   begin
      for j:=0 to 2 do
	 for i:=0 to 13 do
	    fillchar(screen[j*21+40+i,131],79,0);
      for i:=59 to 72 do
	 fillchar(screen[i,221],79,0);
      for i:=77 to 80 do
	 fillchar(screen[i,222],77,0);
      teamjob := ship.engrteam[team].job;
   end;
   case ship.engrteam[team].jobtype of
     0 : printxy(233,62,'Repairing');
     1: printxy(231,62,'Installing');
     2: printxy(236,62,'Removing');
  5: printxy(236,62,'	Research');
   end;
   if ship.engrteam[team].jobtype<3 then
   begin
      for i:=77 to 80 do
	 fillchar(screen[i,222],77,0);
      mouseshow;
      exit;
   end;
   if ship.engrteam[team].jobtype<5 then displaybreakdown(ship.engrteam[team].job);
   b:=76-round(ship.engrteam[team].timeleft/GetBuildTime(ship.engrteam[team].job)*76);
   assert ((b>=0) and (b<=76), 'engineering team gradient progressbar out of bounds');
   {b:=round((ship.engrteam[team].extra shr 8) * 76/
   (ship.engrteam[team].extra and 255));}
   if b=0 then b:=1;
   for j:=0 to b do
   begin
      a:=round(15/b*j+48);
      for i:=77 to 80 do
	 screen[i,j+222]:=a;
   end;
   if b<76 then
      for i:=77 to 80 do
	 fillchar(screen[i,b+223],75-b,0);
   mouseshow;
   anychange:=true;
end;

procedure go2(team: integer);
begin
 if (ship.cargo[cargoindex]=3000) or (ship.cargo[cargoindex]=4000) then
  begin
   getinfo;
   displaycargo;
   exit;
  end;
 if ship.cargo[cargoindex]<6000 then
  displaybreakdown(ship.cargo[cargoindex]);
 with ship.engrteam[team] do
  begin
   job:=ship.cargo[cargoindex];
   if job<6000 then jobtype:=4 else jobtype:=5;
   timeleft:=0;
   if job<6000 then
    begin
     i:=1;
     while createinfo^[i].index<>job do inc(i);
     for j:=1 to 6 do timeleft:=timeleft+100*createinfo^[i].levels[j];
    end else timeleft:=6000+random(5)*100;
   dec(ship.numcargo[cargoindex]);
   if ship.numcargo[cargoindex]=0 then
    begin
     ship.cargo[cargoindex]:=0;
     deccursor;
     if cargoindex<1 then inccursor;
     if cargoindex>250 then cargoindex:=0;
    end;
   {extra:=timeleft div 100;}
  end;
 teamjob := 0;
 viewteam:=team;
 adjustteams;
end;

procedure go(team: integer);
begin
 if cargoindex=0 then exit;
 mousehide;
 tcolor:=31;
 for j:=0 to 2 do
  for i:=0 to 13 do
   fillchar(screen[j*21+40+i,131],79,0);
 for i:=59 to 72 do
  fillchar(screen[i,221],79,0);
 mouseshow;
 if ship.engrteam[team].job>0 then
  begin
   viewteam:=team;
   exit;
  end;
 viewteam:=0;
 if cargomode=1 then
  begin
   go2(team);
   exit;
  end;
   
   case createinfo^[cargoindex].index of
     2004,2015..2017,1019,3000..5999 : ;
   else
      if not checkweight(true) then exit;
   end;
 displaybreakdown(createinfo^[cargoindex].index);
   i := CheckBuildStock(createinfo^[cargoindex].index);
   if (i and $03 = 0) or (i and $0c = 0) or (i and $30 = 0) then
      i := 0
   else if i >=0 then
      i := StartBuild(True, createinfo^[cargoindex].index, createinfo^[cargoindex].index, team);
      
   case i of
     0	: begin
	     tcolor:=92;
	     for i:=59 to 72 do
		fillchar(screen[i,221],79,0);
	     for i:=77 to 80 do
		fillchar(screen[i,222],77,0);
	     printxy(226,59,'Insufficient');
	     printxy(244,65,'Parts');
	     exit;
	  end;
     -1	: begin
	tcolor:=92;
	for i:=59 to 72 do
	   fillchar(screen[i,221],79,0);
	for i:=77 to 80 do
	   fillchar(screen[i,222],77,0);
	printxy(226,59,'Insufficient');
	printxy(244,65,'Level');
	exit;
     end;
     -2	: begin
	tcolor:=92;
	for i:=59 to 72 do
	   fillchar(screen[i,221],79,0);
	for i:=77 to 80 do
	   fillchar(screen[i,222],77,0);
	printxy(226,59,'  Internal  ');
	printxy(244,65,'Error');
	exit;
     end;
     -3	: begin
	tcolor:=92;
	for i:=59 to 72 do
	   fillchar(screen[i,221],79,0);
	for i:=77 to 80 do
	   fillchar(screen[i,222],77,0);
	printxy(226,59,'Insufficient');
	printxy(228,65,' Knowledge ');
	exit;
     end;
   end;
     {	
 i:=0;
 for j:=1 to 3 do if createinfo^[cargoindex].parts[j]=createinfo^[cargoindex].parts[1] then inc(i);
 if (incargo(createinfo^[cargoindex].parts[1])<i) or
  (incargo(createinfo^[cargoindex].parts[2])=0) or
  (incargo(createinfo^[cargoindex].parts[3])=0) then
  begin
   tcolor:=92;
   for i:=59 to 72 do
    fillchar(screen[i,221],79,0);
   for i:=77 to 80 do
    fillchar(screen[i,222],77,0);
   printxy(226,59,'Insufficient');
   printxy(244,65,'Parts');
   exit;
  end;
 for j:=1 to 6 do if createinfo^[cargoindex].levels[j]>ship.crew[j].level then
  begin
   tcolor:=92;
   for i:=59 to 72 do
    fillchar(screen[i,221],79,0);
   for i:=77 to 80 do
    fillchar(screen[i,222],77,0);
   printxy(226,59,'Insufficient');
   printxy(244,65,'Level');
   exit;
  end;}
 viewteam:=team;
 {with ship.engrteam[team] do
  begin
   job:=createinfo^[cargoindex].index;
   jobtype:=3;
   timeleft:=0;
   for j:=1 to 6 do timeleft:=timeleft+100*createinfo^[cargoindex].levels[j];
   for j:=1 to 6 do addxp(j,25*createinfo^[cargoindex].levels[j],0);
   (*extra:=timeleft div 100;*)
   for j:=1 to 3 do removecargo(createinfo^[cargoindex].parts[j]);
  end;}
 adjustteams;
 anychange:=true;
end;

procedure findcursor;
begin
 y:=(mouse.y-16) div 6;
 if y=8 then exit;
 HistoryClear;
 y:=y-8;
 repeat
  if y<0 then
   begin
    deccursor;
    if cargoindex<1 then inccursor;
    inc(y);
   end
  else
   begin
    inccursor;
    dec(y);
   end;
  if ((cargomode=0) and (cargoindex>maxcreation)) or
   ((cargomode=1) and (cargoindex>250)) then
    begin
     deccursor;
     y:=0;
    end;
 until (y=0) or (cargoindex<1);
end;

procedure setfilter(n: integer);
begin
 if filters[n]=0 then filters[n]:=1 else filters[n]:=0;
 if cargoindex>0 then dec(cargoindex);
 inccursor;
 if ((cargomode=0) and (cargoindex>maxcreation)) or
  ((cargomode=1) and (cargoindex>250)) then
  begin
   cargoindex:=0;
   inccursor;
   if ((cargomode=0) and (cargoindex>maxcreation)) or
    ((cargomode=1) and (cargoindex>250)) then cargoindex:=0;
  end;
 drawfilters2;
 anychange:=true;
end;

procedure setdevicemode;
var a: integer;
begin
 if cargomode<>0 then
  begin
   mousehide;
   for j:=95 to 98 do
    begin
     screen[6,j]:=63;
     screen[14,j]:=95;
    end;
   mouseshow;
   cargomode:=0;
   cargoindex:=0;
   inccursor;
   if cargoindex>maxcreation then deccursor;
  end
 else if cargoindex<>0 then
  begin
   a:=0;
   repeat
    inc(a);
   until (ship.engrteam[a].job=0) or (a=4);
   if a<4 then go(a);
  end;
end;

procedure setcargomode;
begin
 if cargomode<>1 then
  begin
   mousehide;
   for j:=95 to 98 do
    begin
     screen[6,j]:=95;
     screen[14,j]:=63;
    end;
   mouseshow;
   cargomode:=1;
   cargoindex:=0;
   inccursor;
   if cargoindex>250 then deccursor;
  end
 else if cargoindex<>0 then
  begin
   a:=0;
   repeat
    inc(a);
   until (ship.engrteam[a].job=0) or (a=4);
   if a<4 then go(a);
  end;
end;

procedure setcolorcode;
begin
 mousehide;
 if colorcode then
  begin
   fillchar(screen[125,69],4,95);
   colorcode:=false;
  end
 else
  begin
   fillchar(screen[125,69],4,63);
   colorcode:=true;
  end;
 mouseshow;
 anychange:=true;
end;

procedure clearkbbuffer;
begin
 
end;

procedure setpartcursor(index : integer);
var
   j : Integer;
begin
   if index = 0 then
      exit;
   j := 1;
   while (j<=maxcreation) and (createinfo^[j].index<>index) do inc(j);
   if j > maxcreation then
      exit;
   cargoindex:=j;
   anychange:=true;
end; { setpart }

procedure setinfocursor(part: integer);
var
   i : Integer;
begin
   if (cargomode=1) or (cargoindex=0) or (lastinfo=0) then exit;
   i:=1;
   while (i<maxcreation) and (createinfo^[i].index<>lastinfo) do inc(i);
   if createinfo^[i].parts[part]>4999 then exit;
   HistoryPush(lastinfo);
   setpartcursor(createinfo^[i].parts[part])
 {j:=1;
 while (j<maxcreation) and (createinfo^[j].index<>createinfo^[i].parts[part]) do inc(j);
 cargoindex:=j;
 anychange:=true;}
end; { setinfocursor }

procedure findcreationmouse;
begin
 if not mouse.getstatus then exit;
 case mouse.x of
    10..19: case mouse.y of
              3..10: begin
                      deccursor;
                      if cargoindex<1 then inccursor;
                     end;
             11..18: if cargomode=0 then
                      begin
                       inccursor;
                       if cargoindex>maxcreation then deccursor;
                      end
                     else
                      begin
                       inccursor;
                       if cargoindex>250 then deccursor;
                      end;
              22..118: findcursor;
             122..129: setfilter(1);
             133..140: setfilter(2);
             144..151: setfilter(3);
            end;
    20..31: case mouse.y of
                3..18: if qmode then
                        begin
                         qmode:=false;
                         mousehide;
                         for i:=6 to 14 do
                          begin
                           screen[i,34]:=95;
                           screen[i,33]:=95;
                          end;
                         mouseshow;
                        end
                       else
                        begin
                         qmode:=true;
                         mousehide;
                         for i:=6 to 14 do
                          begin
                           screen[i,34]:=63;
                           screen[i,33]:=63;
                          end;
                         mouseshow;
                         anychange:=true;
                        end;
              22..118: findcursor;
             123..129: setfilter(1);
             133..140: setfilter(2);
             144..151: setfilter(3);
            end;
    32..37: case mouse.y of
              22..118: findcursor;
             122..129: setfilter(1);
             133..140: setfilter(2);
             144..151: setfilter(3);
            end;
    38..48: case mouse.y of
              3..10: setdevicemode;
              11..18: setcargomode;
              22..118: findcursor;
             122..129: setfilter(1);
             133..140: setfilter(2);
             144..151: setfilter(3);
            end;
    49..92: case mouse.y of
                3..10: setdevicemode;
               11..18: setcargomode;
              22..118: findcursor;
             122..129: if (mouse.x>70) then setcolorcode;
            end;
    93..99: case mouse.y of
              22..118: findcursor;
             122..129: setcolorcode;
            end;
  100..110: case mouse.y of
                3..18: done:=true;
              22..118: findcursor;
             122..129: setcolorcode;
            end;
  120..125: case mouse.y of
             44..49: setinfocursor(1);
             65..70: setinfocursor(2);
             86..91: setinfocursor(3);
            end;
  130..151: case mouse.y of
    40..53: setinfocursor(1);
    61..74: setinfocursor(2);
    82..95: setinfocursor(3);
  end;	   
  152..212: case mouse.y of
    40..53: setinfocursor(1);
    61..74: setinfocursor(2);
    82..95: setinfocursor(3);
             120..128: go(1);
             130..138: go(2);
             140..148: go(3);
            end;
  221..299: case mouse.y of
    59..72: setpartcursor(HistoryPop);
  end;
 end;
 idletime:=0;
end;

procedure processcreationkey;
var ans: char;
begin
 ans:=readkey_nomap;
 case upcase(ans) of
  #0: begin
       ans:=readkey;
       case ans of
        #80: if cargomode=0 then
              begin
               inccursor;
               if cargoindex>maxcreation then deccursor;
              end
             else
              begin
               inccursor;
               if cargoindex>250 then deccursor;
              end;
        #72: begin
              deccursor;
              if cargoindex<1 then inccursor;
             end;
        #81: begin {pgdn}
              move_mouse(mouse.x,113);
              findcursor;
             end;
        #73: begin {pgup}
              move_mouse(mouse.x,22);
              findcursor;
             end;
        #59: setdevicemode;
        #60: setcargomode;
       end;
      end;
  '1': setfilter(1);
  '2': setfilter(2);
  '3': setfilter(3);
  '?','/': if qmode then
        begin
         qmode:=false;
         mousehide;
         for i:=6 to 14 do
          begin
           screen[i,34]:=95;
           screen[i,33]:=95;
          end;
         mouseshow;
        end
       else
        begin
         qmode:=true;
         mousehide;
         for i:=6 to 14 do
          begin
           screen[i,34]:=63;
           screen[i,33]:=63;
          end;
         mouseshow;
         anychange:=true;
        end;
  #27: done:=true;
  'Q': go(1);
  'W': go(2);
  'E': go(3);
  '`': bossmode;
  'C': setcolorcode;
  #13: if cargomode=0 then setdevicemode else setcargomode;
  #10: printbigbox(GetHeapStats1,GetHeapStats2);
 end;
 clearkbbuffer;
 idletime:=0;
end;

procedure adjuststatlights;
begin
 t1:=t1+0.45;
 if t1=6.28 then t1:=0;
 mousehide;
 for a:=0 to 4 do
  begin
   j:=abs(round(5*sin(t1+a/2)));
   x:=31-a;
   for i:=0 to j do
    begin
     dec(x,2);
     screen[134-i,a*3+219]:=x;
     screen[134-i,a*3+220]:=x;
    end;
   if j<5 then for
    i:=j to 5 do
     begin
      screen[134-i,a*3+219]:=0;
      screen[134-i,a*3+220]:=0;
     end;
  end;
 mouseshow;
end;

procedure maincreationloop;
begin
   repeat
      fadestep(8);
      findcreationmouse;
      if fastkeypressed then processcreationkey;
      inc(idletime);
      if idletime=maxidle then screensaver;
      if batindex<8 then inc(batindex) else
      begin
	 batindex:=0;
	 addtime2;
      end;
      adjuststatlights;
      if viewteam>0 then displayteaminfo(viewteam) else adjustteams;
      if anychange then
      begin
	 if cargomode=0 then displaydevices else displaycargo;
      end;
      delay(tslice*2);
   until done=true;
end;

procedure creation;
begin
   if (filters[1] = 0) and (filters[2] = 0) and (filters[3] = 0) then
   begin
      for j:=1 to 3 do filters[j]:=1;
   end;
   readycreationdata;
   displaydevices;
   maincreationloop;
   dispose(createinfo);
   dispose(iteminfo);
   {stopmod;}
   removedata;
end;

begin
 for j:=1 to 4 do filters2[j]:=1;
 qmode:=true;
 for j:=1 to 3 do filters[j]:=1;
 colorcode:=true;
end.
