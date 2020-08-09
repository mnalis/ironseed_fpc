unit utils;
{$I-}
{***************************
   General Utilities for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

interface

type
 buttype= array[0..2] of byte;

procedure showpanel(buttons: buttype);
procedure removepanel;
procedure sprinkle(x1,y1,x2,y2,seed: integer);
procedure sprinkle2(x1,y1,x2,y2,seed: integer);
procedure colorarea(x1,y1,x2,y2,alt,index: integer);
procedure removerightside(erasepanel: boolean);
procedure genericrightside(buttons: buttype);
function addcargo(item: integer; force : boolean): boolean;
function incargoindex(item: integer): integer;
function incargo(item: integer): integer;
function incargoreal(item: integer): integer;
function incargores(item: integer): integer;
procedure removecargo(item: integer);
function CargoName(item	: Integer): String;
procedure RebuildCargoReserve;
procedure printplanet(x1,y1,sys,num: integer);
procedure graybutton(x1,y1,x2,y2: integer);
procedure revgraybutton(x1,y1,x2,y2: integer);
procedure addxp(crewnum: integer; amount: longint; drawmode: integer);
procedure addtime2;
procedure printbox(s: string);
procedure printbigbox(s1,s2: string);
function findfirstplanet(sys: integer): integer;
procedure wait(s: integer);
procedure getartifactname(n: integer);
function addcargo2(item: integer; force : boolean): boolean;
procedure plainfadearea(x1,y1,x2,y2,alt: integer);
procedure readweaicon(n: integer);
function chevent(n: integer): boolean;
procedure showchar(n: integer; s1: string);
function checkweight(background	: boolean): boolean;
function max2(a, b : Integer) : Integer;
function min2(a, b : Integer) : Integer;
procedure PushRand;
procedure PopRand;

implementation

uses data, journey, gmouse, usecode, display, saveload, utils2, combat, weird, modplay, crewtick, utils_;

type
 scandatatype= array[0..11] of byte;
 scantype= array[0..16] of scandatatype;
var
 a,b,j,i,index : integer;
   randsave    : longint;

function chevent(n: integer): boolean;
var i,j: integer;
begin
   if (n<0) or (n>19999) then
   begin
      chevent:=true;
      exit;
   end;
   if (n >= 8192) then
   begin
      chevent := false
   end else begin
      chevent := (events[n shr 3] and (1 shl (n and 7))) <> 0;
   end;
{   if n<50 then
   begin
      i:=0;
      while (ship.events[i]<>n) and (i<50) do inc(i);
      if i=50 then chevent:=false else chevent:=true;
   end
   else
   begin
      n:=n-50;
      i:=50+(n div 8);
      j:=n mod 8;
      if ship.events[i] and (1 shl j)>0 then chevent:=true else chevent:=false;
   end;}
end;

procedure plainfadearea(x1,y1,x2,y2,alt: integer);
var i,j: integer;
begin
 mousehide;
 for j:=x1 to x2 do
  for i:=y1 to y2 do
   screen[i,j]:=screen[i,j]+alt;
 mouseshow;
end;

procedure graybutton(x1,y1,x2,y2: integer);
begin
 x:=x2-x1+1;
 for i:=y1 to y2 do
  fillchar(screen[i,x1],x,5);
 fillchar(screen[y2,x1],x,2);
 fillchar(screen[y1,x1],x,10);
 setcolor(2);
 line(x2,y1,x2,y2);
 setcolor(10);
 line(x1,y1,x1,y2);
 screen[y1,x2]:=6;
 screen[y2,x1]:=6;
end;

procedure revgraybutton(x1,y1,x2,y2: integer);
begin
 x:=x2-x1+1;
 fillchar(screen[y2,x1],x,10);
 fillchar(screen[y1,x1],x,2);
 setcolor(10);
 line(x2,y1,x2,y2);
 setcolor(2);
 line(x1,y1,x1,y2);
 screen[y1,x2]:=4;
 screen[y2,x1]:=4;
end;

procedure showpanel(buttons: buttype);
begin
 mousehide;
 for a:=1 to 5 do
  for j:=0 to 16 do
   for i:=0 to 14 do
    screen[i+9,j+137+a*17]:=icons^[53+a,j,i];
 for a:=0 to 2 do
  for j:=0 to 16 do
   for i:=0 to 14 do
    screen[i+9,j+239+a*17]:=icons^[53+buttons[a],j,i];
 panelon:=true;
 mouseshow;
end;

procedure removepanel;
begin
 if not panelon then exit;
 mousehide;
 sprinkle(153,9,290,24,7);
 panelon:=false;
 mouseshow;
end;

procedure sprinkle(x1,y1,x2,y2,seed: integer);
var max: word;
begin
 max:=(x2-x1)*(y2-y1);
 index:=0;
 j:=0;
 mousehide;
 repeat
  inc(index);
  j:=j+seed;
  if j>max then j:=j-max;
  y:=y1+j div (x2-x1);
  x:=x1+j mod (x2-x1);
  a:=x+backgrx;
  if a>319 then a:=a-320;
  b:=y+backgry;
  if b>199 then b:=b-200;
  screen[y,x]:=backgr^[b,a];
  if index mod 100=0 then delay(tslice div 10);
 until index>max;
 mouseshow;
end;

procedure sprinkle2(x1,y1,x2,y2,seed: integer);
var max: word;
    dx,dy: integer;
begin
 max:=(x2-x1)*(y2-y1);
 index:=0;
 j:=0;
 mousehide;
 repeat
  inc(index);
  j:=j+seed;
  if j>max then j:=j-max;
  y:=y1+j div (x2-x1);
  x:=x1+j mod (x2-x1);
  if (x<28) or (y<13) or (x>147) or (y>133) then
   begin
    a:=x+backgrx;
    if a>319 then a:=a-320;
    b:=y+backgry;
    if b>199 then b:=b-200;
    screen[y,x]:=backgr^[b,a];
   end
   else screen[y,x]:=planet^[y-12,x-27];
  if index mod 100=0 then delay(tslice div 10);
 until index>max;
 mouseshow;
end;

procedure colorarea(x1,y1,x2,y2,alt,index: integer);
var i,j: integer;
begin
 mousehide;
 for j:=x1 to x2 do
  for i:=y1 to y2 do
   if screen[i,j]<>0 then screen[i,j]:=screen[i,j]-statcolors[index]+alt;
 mouseshow;
 statcolors[index]:=alt;
end;

procedure removerightside(erasepanel: boolean);
begin
 mousehide;
 if (panelon) and (erasepanel) then removepanel;
 viewmode:=0;
 for j:=1 to 5 do
  begin
   plainfadearea(165,25,279,117,-1);
   delay(tslice*2);
  end;
 sprinkle(164,24,281,118,17);
 mouseshow;
end;

procedure genericrightside(buttons: buttype);
begin
 showpanel(buttons);
 mousehide;
 for j:=1 to 5 do
  begin
   plainfadearea(165,25,279,117,1);
   delay(tslice*2);
  end;
 for i:=25 to 117 do
  fillchar(screen[i,165],115,5);
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
 mouseshow;
end;

procedure sortcargo;
var changed: boolean;
begin
 repeat
  changed:=false;
  for j:=1 to 249 do
   if ship.cargo[j]>ship.cargo[j+1] then
    begin
     i:=ship.cargo[j];
     ship.cargo[j]:=ship.cargo[j+1];
     ship.cargo[j+1]:=i;
     i:=ship.numcargo[j];
     ship.numcargo[j]:=ship.numcargo[j+1];
     ship.numcargo[j+1]:=i;
     changed:=true;
    end;
 until not changed;
end;

function checkweight(background	: boolean): boolean;
var weight : longint;
    i,j	   : integer;
    str1   : string[4];
   str2	   : string[5];
begin
 weight:=0;
 for j:=1 to 250 do
  if ship.cargo[j]>0 then
   begin
    if ship.cargo[j]>6000 then
     begin
      i:=maxcargo;
      getartifactname(ship.cargo[j]);
     end
    else
     begin
      i:=1;
      while (cargo[i].index<>ship.cargo[j]) and (i<maxcargo) do inc(i);
     end;
    weight:=weight+cargo[i].size*ship.numcargo[j];
   end;
 weight:=weight div 10;
 if weight>ship.cargomax then
 begin
    if background then
    begin
       str(weight,str1);
       str(ship.cargomax,str2);
       printbigbox('Cargo full! '+str1+'/'+str2+' used.', 'Must Jettison Cargo.');
       checkweight:=false;
    end else begin
       println;
       tcolor:=94;
       print('Cargo Full! ');
       str(weight,str1);
       print(str1+'/');
       str(ship.cargomax,str1);
       print(str1+' Used.');
       println;
       print('Must jettison cargo.');
       checkweight:=false;
    end;
  end
 else checkweight:=true;
end;

function addcargo(item: integer; force : boolean): boolean;
var weight: longint;
    i,j: integer;
    str1: string[4];
begin
   weight:=0;
   for j:=1 to 250 do
      if ship.cargo[j]>0 then
      begin
	 if ship.cargo[j]>6000 then
	 begin
	    i:=maxcargo;
	    getartifactname(ship.cargo[j]);
	 end
	 else
	 begin
	    i:=1;
	    while (cargo[i].index<>ship.cargo[j]) and (i<maxcargo) do inc(i);
	 end;
	 weight:=weight+cargo[i].size*ship.numcargo[j];
      end;
   if item>6000 then
   begin
      i:=maxcargo;
      getartifactname(item);
   end
   else
   begin
      i:=1;
      while (cargo[i].index<>item) and (i<maxcargo) do inc(i);
   end;
   weight:=weight+cargo[i].size;
   weight:=weight div 10;
   if (weight>ship.cargomax) and (item < 6000) and not force then
   begin
      println;
      tcolor:=94;
      print('Cargo Full! ');
      str(weight,str1);
      print(str1+'/');
      str(ship.cargomax,str1);
      print(str1+' Used.');
      addcargo:=false;
      exit;
   end;
   j:=1;
   while (j<251) and (ship.cargo[j]<>item) and (ship.numcargo[j]<255) do inc(j);
   if j>250 then
   begin
      j:=1;
      while (ship.numcargo[j]<>0) and (j<251) do inc(j);
      if j=251 then
      begin
	 println;
	 tcolor:=94;
	 print('No cargo slot available.  Some cargo dumped.');
	 weight:=ship.cargomax+1;
	 j:=random(50)+100;
	 exit;
      end;
      ship.cargo[j]:=item;
      ship.numcargo[j]:=1;
   end
   else inc(ship.numcargo[j]);
   if weight>ship.cargomax then addcargo:=false else addcargo:=true;
   sortcargo;
end;

function incargoindex(item: integer): integer;
var i: integer;
begin
 i:=1;
 while (i<251) and (ship.cargo[i]<>item) do inc(i);
 if i=251 then incargoindex:=0 else incargoindex:=i;
end;

function incargoreal(item: integer): integer;
var i: integer;
begin
   i:=incargoindex(item);
   if i > 0 then incargoreal := ship.numcargo[i] else incargoreal := 0;
end;

function incargo(item: integer): integer;
var i: integer;
begin
   i:=incargoindex(item);
   if i > 0 then incargo := ship.numcargo[i] - rescargo[i] else incargo := 0;
end; { incargo }

function incargores(item: integer): integer;
var i: integer;
begin
   i:=incargoindex(item);
   if i > 0 then incargores := rescargo[i] else incargores := 0;
end; { incargores }

function CargoName(item	: Integer): String;
var
   i : Integer;
   s : String[20];
begin
   for i := 1 to maxcargo do
      if cargo[i].index = item then
      begin
	 s := cargo[i].name;
	 while (length(s) > 0) and (s[length(s)] = ' ') do dec(s[0]);
	 CargoName := s;
	 exit;
      end;
   str(item, s);
   CargoName := '??' + s + '??';
end;

procedure removecargo(item: integer);
var i,j: integer;
begin
 j:=1;
 while (j<250) and (ship.cargo[j]<>item) do inc(j);
 if (j<251) and (ship.numcargo[j]>254) then j:=251;
 if j>251 then exit;
 dec(ship.numcargo[j]);
 if ship.numcargo[j]=0 then ship.cargo[j]:=0;
end;

function AddCargoReserves(item, team : Integer; first : Boolean): Integer;
var
   i, j	: Integer;
begin
   if item = 0 then {no stock!}
   begin
      AddCargoReserves := -1;
      exit;
   end;
   if (team > 0) and (ship.engrteam[team].job = item) then {this team is working on it}
   begin
      AddCargoReserves := 0;
      exit;
   end;
   if (not first) and (InCargo(item) > 0) then {in stock}
   begin
      inc(rescargo[InCargoIndex(item)]);
      AddCargoReserves := team;
      exit;
   end;
   i := 1;
   while (i <= maxcargo) and (cargo[i].index <> item) do inc(i);
   if i > maxcargo then {doesn't exist!}
   begin
      AddCargoReserves := -1;
      exit;
   end;
   for j := 1 to 3 do {reserve sub parts}
      team := AddCargoReserves(prtcargo[i, j], team, False);
   AddCargoReserves := team;
end;

procedure RebuildCargoReserve;
var
   i : Integer;
begin
   for i := 1 to 250 do
      rescargo[i] := 0;
   begin
   for i := 1 to 3 do
      if (ship.engrteam[i].jobtype = 3) and not
	 ((ship.engrteam[i].job = ship.engrteam[i].extra) or (ship.engrteam[i].extra = 0)) then
      begin
	 AddCargoReserves(ship.engrteam[i].extra, i, True);
      end;
   end;
end;

procedure printplanet(x1,y1,sys,num: integer);
var s: string[8];
    a,j,i: integer;
begin
 j:=findfirstplanet(sys);
 i:=0;
 a:=0;
 repeat
  if tempplan^[j+a].orbit<tempplan^[j+num].orbit then inc(i);
  inc(a);
 until a=systems[sys].numplanets;
 case i of
  0: s:='    Star';
  1: s:='Primus  ';
  2: s:='Secundus';
  3: s:='Tertius ';
  4: s:='Quartus ';
  5: s:='Pentius ';
  6: s:='Quintus ';
  7: s:='Septius ';
 end;
 printxy(x1,y1,s);
end;

procedure addxp(crewnum: integer; amount: longint; drawmode: integer);
var oldlvl,i,oldt: integer;
    s: string[11];
begin
 if ship.crew[crewnum].xp>25000000 then exit;
 oldt:=tcolor;
 ship.crew[crewnum].xp:=ship.crew[crewnum].xp+amount;
 oldlvl:=ship.crew[crewnum].level;
 i:=oldlvl;
 if oldlvl<>20 then
  begin
   with ship.crew[crewnum] do
    if xp<1000 then i:=0
     else if xp<3000 then i:=1
     else if xp<4000 then i:=2
     else if xp<7000 then i:=3
     else if xp<11000 then i:=4
     else if xp<18000 then i:=5
     else if xp<29000 then i:=6
     else if xp<47000 then i:=7
     else if xp<76000 then i:=8
     else if xp<123000 then i:=9
     else if xp<200000 then i:=10
     else if xp<350000 then i:=11
     else if xp<500000 then i:=12
     else if xp<650000 then i:=13
     else if xp<800000 then i:=14
     else if xp<950000 then i:=15
     else if xp<1100000 then i:=16
     else if xp<1250000 then i:=17
     else if xp<1400000 then i:=18
     else if xp<1550000 then i:=19
     else i:=20;
  end;
 if i<>oldlvl then
  begin
   ship.crew[crewnum].level:=i;
   tcolor:=31;
   if drawmode=1 then println;
   case crewnum of
    1: s:='PSYCHOMETRY';
    2: s:='ENGINEERING';
    3: s:='SCIENCE';
    4: s:='SECURITY';
    5: s:='ASTROGATION';
    6: s:='MEDICAL';
    else errorhandler('Invalid Crew value.',6);
   end;
   if drawmode=1 then print(s+': Increased knowledge base.')
    else showchar(crewnum,'Increased knowledge base.');
   if ship.crew[crewnum].men<99 then inc(ship.crew[crewnum].men);
   if ship.crew[crewnum].emo<99 then inc(ship.crew[crewnum].emo);
   if ship.crew[crewnum].phy<99 then inc(ship.crew[crewnum].phy);
  end;
{$IFDEF DEMO}
 if ship.crew[crewnum].level>7 then
  begin
   mousehide;
   playmod(true,'sound/VICTORY.MOD');
   fading;
   loadscreen('data/demoscrn',@screen);
   fadein;
   repeat until (mouse.getstatus) or (fastkeypressed);
   while fastkeypressed do readkey;
   fading;
   loadscreen('data/demoscr2',@screen);
   fadein;
   repeat until (mouse.getstatus) or (fastkeypressed);
   while fastkeypressed do readkey;
   fading;
   closegraph;
   halt(1);
  end;
{$ENDIF}
 tcolor:=oldt;
end;

procedure printbox(s: string);
var tempscr: ^scrtype2;
    oldt,t,c,ofsc: integer;
    done: boolean;
    ans: char;
begin
 if ship.options[5]=0 then exit;
 oldt:=tcolor;
 tcolor:=31;
 shadowprintln;
 shadowprint(s);
 tcolor:=oldt;
 if ship.options[5]=1 then exit;
 if (colors[31,3]=63) or (colors[32,2]=63) then t:=26
  else if colors[32,1]=0 then t:=197
  else t:=182;
 new(tempscr);
 mousehide;
 for i:=50 to 102 do
  mymove(screen[i,75],tempscr^[i,75],43);
 if colors[32,2]=63 then ofsc:=-26
  else if colors[32,1]=0 then ofsc:=0
  else ofsc:=74;
 button(75,60,244,102,ofsc);
 if colors[32,2]=63 then ofsc:=-24
  else if colors[32,1]=0 then ofsc:=2
  else ofsc:=78;
 button(139,78,179,92,ofsc);
 tcolor:=t;
 if colors[32,2]=63 then bkcolor:=9
  else if colors[32,1]=0 then bkcolor:=35
  else bkcolor:=109;
 printxy(round((170-length(s)*5)/2)+70,65,s);
 if colors[32,2]=63 then bkcolor:=11
  else if colors[32,1]=0 then bkcolor:=37
  else bkcolor:=115;
 printxy(149,82,'OK');
 mouseshow;
 while fastkeypressed do readkey;
 c:=0;
 ans:=' ';
 repeat
  done:=mouse.getstatus;
  if (c=0) and (mouse.y>77) and (mouse.y<93) and (mouse.x>138) and (mouse.x<180) then
   begin
    c:=1;
    mousehide;
    plainfadearea(139,78,179,92,3);
    mouseshow;
   end
  else if (c=1) and ((mouse.y<78) or (mouse.y>92) or (mouse.x<139) or (mouse.x>179)) then
   begin
    c:=0;
    mousehide;
    plainfadearea(139,78,179,92,-3);
    mouseshow;
   end;
  if fastkeypressed then ans:=readkey;
    delay(tslice);
    fadestep(8);
 until ((done) and (c=1)) or (ans=#27) or (ans=#13);
 mousehide;
 for i:=60 to 102 do
  mymove(tempscr^[i,75],screen[i,75],43);
 mouseshow;
 dispose(tempscr);
 tcolor:=oldt;
 bkcolor:=0;
 setcolor(82);
end;

function addcargo2(item	: integer; force : boolean): boolean;
var weight: longint;
    i,j: integer;
    str1,str2: string[4];
begin
 weight:=0;
 for j:=1 to 250 do
  if ship.cargo[j]>0 then
   begin
    if ship.cargo[j]>6000 then
     begin
      i:=maxcargo;
      getartifactname(ship.cargo[j]);
     end
    else
     begin
      i:=1;
      while (cargo[i].index<>ship.cargo[j]) and (i<maxcargo) do inc(i);
     end;
    weight:=weight+cargo[i].size*ship.numcargo[j];
   end;
 if item>6000 then
  begin
   i:=maxcargo;
   getartifactname(item);
  end
 else
  begin
   i:=1;
   while (cargo[i].index<>item) and (i<maxcargo) do inc(i);
  end;
 weight:=weight+cargo[i].size;
 weight:=weight div 10;
 if (weight>ship.cargomax) and (item < 6000) and not force then
  begin
   str(weight,str1);
   str(ship.cargomax,str2);
   printbox('Cargo full! '+str1+'/'+str2+' used.');
     addcargo2:=false;
     exit;
  end;
 j:=1;
 while (j<251) and (ship.cargo[j]<>item) do inc(j);
 if (j<251) and (ship.numcargo[j]>254) then j:=251;
 if j>250 then
  begin
   j:=1;
   while (ship.numcargo[j]<>0) and (j<251) do inc(j);
   if j=251 then
    begin
     printbigbox('No cargo slot available.','Some Cargo dumped.');
     j:=100+random(50);
     weight:=ship.cargomax+1;
    end;
    ship.cargo[j]:=item;
    ship.numcargo[j]:=1;
  end
 else inc(ship.numcargo[j]);
 if weight>ship.cargomax then addcargo2:=false else addcargo2:=true;
 sortcargo;
end;

{procedure disassemble2(item: integer);
var cfile: file of createarray;
    temp: ^createarray;
    j,i: integer;
begin
 new(temp);
 assign(cfile,'data/creation.dta');
 reset(cfile);
 if ioresult<>0 then errorhandler('creation.dta',1);
 read(cfile,temp^);
 if ioresult<>0 then errorhandler('creation.dta',5);
 close(cfile);
 i:=1;
 while (temp^[i].index<>item) and (i<=totalcreation) do inc(i);
 if i>totalcreation then errorhandler('Disassemble error!',6);
 for j:=1 to 3 do
  if not skillcheck(2) then addcargo(4020)
   else addcargo2(temp^[i].parts[j]);
 dispose(temp);
end;}

procedure adjustwanderer(ofs: integer);
begin
 with ship.wandering do
  begin
   if alienid>16000 then exit;
   if (abs(relx)>499) and (relx<0) then relx:=relx+ofs
    else if abs(relx)>499 then relx:=relx-ofs;
   if (abs(rely)>499) and (rely<0) then rely:=rely+ofs
    else if abs(rely)>499 then rely:=rely-ofs;
   if (abs(relz)>499) and (relz<0) then relz:=relz+ofs
    else if abs(relz)>499 then relz:=relz-ofs;
   if (abs(relx)<500) and (abs(rely)<500) and (abs(relz)<500) then
    begin
     done:=true;
     exit;
    end;
   if (abs(relx)>23000) or (abs(rely)>23000) or (abs(relz)>23000) then
    begin
     ship.wandering.alienid:=20000;
     if action=1 then showchar(4,'Evasion successful!');
     action:=0;
    end;
  end;
end;

procedure movewandering;
begin
 case action of
  0:;
  1: adjustwanderer(round((-ship.accelmax div 4)*(100-ship.damages[4])/100));
  2: adjustwanderer(round((ship.accelmax div 4)*(100-ship.damages[4])/100));
 end;
 case ship.wandering.orders of
  0: if action=3 then adjustwanderer(30) else adjustwanderer(2);
  1: if action=3 then adjustwanderer(-50) else adjustwanderer(-70);
 end;
end;

procedure addtime2;
begin
   if ship.wandering.alienid<16000 then movewandering;
   GameTick(True, 1);
end;

{procedure messagebox(s : String; shadow : Boolean);
begin
   quicksavescreen(tempdir+'\message',@screen, false);
   if shadow then
   begin
      shadowprintln;
      shadowprint(s1+' '+s2);
   end;
   
   quickloadscreen(tempdir+'/current',@screen, false);
end;}

procedure printbigbox(s1,s2: string);
var
   tempscr	 : ^scrtype2;
   oldt,t,c,ofsc : integer;
   done		 : boolean;
   ans		 : char;
begin		 
   oldt:=tcolor;
   if ship.options[5]=0 then exit;
   tcolor:=31;
   shadowprintln;
   shadowprint(s1+' '+s2);
   tcolor:=oldt;
   if ship.options[5]=1 then exit;
   if (colors[31,3]=63) or (colors[32,2]=63) then t:=26
   else if colors[32,1]=0 then t:=197
   else t:=182;
   new(tempscr);
   mousehide;
   for i:=50 to 102 do
      mymove(screen[i,70],tempscr^[i,70],45);
   if colors[32,2]=63 then ofsc:=-26
   else if colors[32,1]=0 then ofsc:=0
   else ofsc:=74;
   button(70,50,249,102,ofsc);
   if colors[32,2]=63 then ofsc:=-24
   else if colors[32,1]=0 then ofsc:=2
   else ofsc:=78;
   button(139,78,179,92,ofsc);
   tcolor:=t;
   if colors[32,2]=63 then bkcolor:=9
   else if colors[32,1]=0 then bkcolor:=35
   else bkcolor:=109;
   printxy(round((170-length(s1)*5)/2)+70,55,s1);
   printxy(round((170-length(s2)*5)/2)+70,61,s2);
   if colors[32,2]=63 then bkcolor:=11
   else if colors[32,1]=0 then bkcolor:=37
   else bkcolor:=115;
   printxy(149,82,'OK');
   mouseshow;
   while fastkeypressed do readkey;
   ans:=' ';
   c:=0;
   repeat
      done:=mouse.getstatus;
      if (c=0) and (mouse.y>77) and (mouse.y<93) and (mouse.x>138) and (mouse.x<180) then
      begin
	 c:=1;
	 mousehide;
	 plainfadearea(139,78,179,92,3);
	 mouseshow;
      end
      else if (c=1) and ((mouse.y<78) or (mouse.y>92) or (mouse.x<139) or (mouse.x>179)) then
      begin
	 c:=0;
	 mousehide;
	 plainfadearea(139,78,179,92,-3);
	 mouseshow;
      end;
      if fastkeypressed then ans:=readkey;
      delay(tslice);
      fadestep(8);
   until ((done) and (c=1)) or (ans=#27) or (ans=#13);
   mousehide;
   for i:=50 to 102 do
      mymove(tempscr^[i,70],screen[i,70],45);
   mouseshow;
   dispose(tempscr);
   tcolor:=oldt;
   bkcolor:=0;
   setcolor(82);
end;

procedure showchar(n: integer; s1: string);
var oldt,t,c,ofsc: integer;
    done: boolean;
    ans: char;
    s: string[12];
    portrait: ^portraittype;
    s2: string[100];
begin
 oldt:=tcolor;
 if ship.options[5]=0 then exit;
 tcolor:=31;
 shadowprintln;
 case n of
  0:s:='COMPUTER:';
  1:s:='PSYCHOMETRY:';
  2:s:='ENGINEERING:';
  3:s:='SCIENCE:';
  4:s:='SECURITY:';
  5:s:='ASTROGATION:';
  6:s:='MEDIC:';
 end;
 shadowprint(s);
 shadowprint(' '+s1);
 if (length(s1)>30) then
  begin
   i:=30;
   while (s1[i]<>' ') and (s1[i]<>'.') and (s1[i]<>'?') do dec(i);
   s2:=copy(s1,i+1,length(s1)-i);
   s1:=copy(s1,1,i);
  end
 else s2:='';
 tcolor:=oldt;
 if ship.options[5]=1 then exit;
 mousehide;
 compressfile(tempdir+'/current3',@screen);
 if (colors[31,3]=63) or (colors[32,2]=63) then t:=26
  else if colors[32,1]=0 then t:=197
  else t:=182;
 if colors[32,2]=63 then ofsc:=-26
  else if colors[32,1]=0 then ofsc:=0
  else ofsc:=74;
 button(70,82,249,134,ofsc);
 if n > 0 then
 begin
    button(123,8,196,81,ofsc);
    new(portrait);
    n:=ship.crew[n].index;
    str(n:2,s);
    if n<10 then s[1]:='0';
    loadscreen('data/image'+s,portrait);
    x:=125;
    y:=10;
    if t=197 then
       for j:=0 to 69 do
	  for i:=0 to 69 do
	  begin
	     a:=portrait^[i,j];
	     if a<32 then screen[i+y,j+x]:=a
	     else screen[i+y,j+x]:=a+16;
	  end
    else if t=26 then
       for j:=0 to 69 do
	  for i:=0 to 69 do
	  begin
	     a:=portrait^[i,j];
	     if a<32 then screen[i+y,j+x]:=(a div 2)
	     else screen[i+y,j+x]:=(((a mod 32)+32) div 2);
	  end
    else
       for i:=0 to 69 do
	  move(portrait^[i],screen[i+y,x],70);
    dispose(portrait);
 end;
 if colors[32,2]=63 then ofsc:=-24
  else if colors[32,1]=0 then ofsc:=2
  else ofsc:=78;
 button(139,110,179,124,ofsc);
 tcolor:=t;
 if colors[32,2]=63 then bkcolor:=9
  else if colors[32,1]=0 then bkcolor:=35
  else bkcolor:=109;
 printxy(round((170-length(s1)*5)/2)+70,87,s1);
 printxy(round((170-length(s2)*5)/2)+70,93,s2);
 if colors[32,2]=63 then bkcolor:=11
  else if colors[32,1]=0 then bkcolor:=37
  else bkcolor:=115;
 printxy(149,114,'OK');
 mouseshow;
 while fastkeypressed do readkey;
 ans:=' ';
 c:=0;
 repeat
  delay(tslice);
  fadestep(8);
  done:=mouse.getstatus;
  if (c=0) and (mouse.y>109) and (mouse.y<125) and (mouse.x>138) and (mouse.x<180) then
   begin
    c:=1;
    mousehide;
    plainfadearea(139,110,179,124,3);
    mouseshow;
   end
  else if (c=1) and ((mouse.y<110) or (mouse.y>124) or (mouse.x<139) or (mouse.x>179)) then
   begin
    c:=0;
    mousehide;
    plainfadearea(139,110,179,124,-3);
    mouseshow;
   end;
  if fastkeypressed then ans:=readkey;
 until ((done) and (c=1)) or (ans=#27) or (ans=#13);
 mousehide;
 loadscreen(tempdir+'/current3',@screen);
 mouseshow;
 tcolor:=oldt;
 bkcolor:=0;
 setcolor(82);
end;

function findfirstplanet(sys: integer): integer;
var done: boolean;
    j: integer;
begin
 done:=false;
 j:=0;
 inc(j);
 while (tempplan^[j].system<>sys) and (j<1000) do inc(j);
 findfirstplanet:=j;
end;

procedure wait(s: integer);
begin
    delay(s*1000);
end;

procedure getartifactname(n: integer);
var j: integer;
begin
 if n<6900 then
  begin
   if n>6500 then
    cargo[maxcargo].name:=artifacts^[((n-6501) div 10)+41]+' '+artifacts^[((n-6501) mod 10)+51]
   else cargo[maxcargo].name:=artifacts^[(n-6001) div 20+1]+' '+artifacts^[(n-6001) mod 20+21];
   if ord(cargo[maxcargo].name[0])<20 then
    for j:=ord(cargo[maxcargo].name[0])+1 to 20 do cargo[maxcargo].name[j]:=' ';
     cargo[maxcargo].name[0]:=#20;
   cargo[maxcargo].size:=(n mod 40)+1;
   cargo[maxcargo].index:=n;
  end
 else
  begin
   case n of
    6900: cargo[maxcargo].name:='Shunt Drive         ';
    6901: cargo[maxcargo].name:='Channeler           ';
    6902: cargo[maxcargo].name:='Iron Seed           ';
    6903: cargo[maxcargo].name:='Homing Device       ';
    6904: cargo[maxcargo].name:='Detonator           ';
    6905: cargo[maxcargo].name:='Thermal Plating     ';
    6906: cargo[maxcargo].name:='Ermigen Data Tapes  ';
    6907: cargo[maxcargo].name:='Glyptic Scythe      ';
    6908: cargo[maxcargo].name:='Multi-Imager        ';
    6909: cargo[maxcargo].name:='Ylinth Mutagenics   ';
    6910: cargo[maxcargo].name:='Goolas              ';
   end;
   cargo[maxcargo].size:=0;
   cargo[maxcargo].index:=n;
  end;
end;

procedure readweaicon(n: integer);
var f: file of weaponicontype;
begin
 assign(f,'data/weapicon.dta');
 reset(f);
 if ioresult<>0 then errorhandler('weapicon.dta',1);
 seek(f,n);
 if ioresult<>0 then errorhandler('weapicon.dta',5);
 read(f,tempicon^);
 if ioresult<>0 then errorhandler('weapicon.dta',5);
 close(f);
end;

function max2(a, b : Integer) : Integer;
begin
   if a > b then
      max2 := a
   else
      max2 := b;
end;

function min2(a, b : Integer) : Integer;
begin
   if a < b then
      min2 := a
   else
      min2 := b;
end;

procedure PushRand;
begin
   RandSave := RandSeed;
end; { PushRand }

procedure PopRand;
begin
   RandSeed := RandSave;
end; { PopRand }

begin
 new(tempicon);
end.
