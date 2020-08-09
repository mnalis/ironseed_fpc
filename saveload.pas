unit saveload;

{***************************
   Save/Load Game and Utility Unit for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

{$O+}
{$I-}
interface

function loadgamedata(tofadein: boolean): boolean;
function savegamedata(alt,text: integer): boolean;
function yesnorequest(s: string; alt,text: integer): boolean;
procedure button(x1,y1,x2,y2,alt: integer);
procedure encodecrew(tc: integer);
procedure decodecrew;
procedure printinfo;
procedure printcargo;
procedure loadgame(num: integer);

implementation

uses crt, utils_, gmouse, data, journey, usecode, utils, weird, modplay, version, crewtick;
{$PACKRECORDS 1}
type
 nametype= string[20];
 scrtype=array[40..140,74..245] of byte;
 savedirtype=
  record
   name: nametype;
   yearstamp,monthstamp: integer;
  end;
 namearray= array[1..8] of savedirtype;
var
 tempscr: ^scrtype;
 a,i,j,cursor,lastx,lasty,calt: integer;
 names: ^namearray;
 encoding,done: boolean;
 ft: text;
 s: ^screentype;
 p: pointer;
{$PACKRECORDS DEFAULT}
procedure button(x1,y1,x2,y2,alt: integer);
begin
 setfillstyle(1,35+alt);
 bar(x1,y1,x2,y2);
 setcolor(32+alt);
 line(x2,y1,x2,y2);
 line(x1,y2,x2,y2);
 setcolor(38+alt);
 line(x1,y1,x2,y1);
 line(x1,y1,x1,y2);
 screen[y1,x2]:=36+alt;
 screen[y2,x1]:=36+alt;
end;

procedure displayfilenames;
var str1,str2: string[5];
begin
 printxy(85, 131, versionstring);
 bkcolor:=37+calt;
 for a:=1 to 8 do
  begin
   str(names^[a].yearstamp:5,str2);
   str(names^[a].monthstamp:2,str1);
   printxy(85,41+a*10,names^[a].name);
   printxy(187,41+a*10,str1+'/'+str2);
  end;
 printxy(187,131,'Cancel');
end;

procedure savefilenames;
var namefile: file of namearray;
begin
 assign(namefile,'data/savegame.dir');
 rewrite(namefile);
 if ioresult<>0 then errorhandler('data/savegame.dir',1);
 write(namefile,names^);
 if ioresult<>0 then errorhandler('data/savegame.dir',5);
 close(namefile);
end;

procedure initializenames;
begin
 for j:=1 to 8 do
  with names^[j] do
  begin
   name:='Quick Start         ';
   yearstamp:=3784;
   monthstamp:=2;
  end;
end;

procedure loadfilenames;
var namefile: file of namearray;
begin
 assign(namefile,'data/savegame.dir');
 reset(namefile);
 if ioresult<>0 then
  begin
   initializenames;
   savefilenames;
   reset(namefile);
   if ioresult<>0 then errorhandler('data/savegame.dir',1);
  end;
 read(namefile,names^);
 if ioresult<>0 then errorhandler('data/savegame.dir',5);
 close(namefile);
end;

procedure saveplanetinfo;
var planfile: file of planarray;
    srcfile,tarfile: file of alientype;
    err: boolean;
    temp: alientype;
begin
 assign(planfile,'save'+chr(curfilenum+48)+'/PLANETS.DTA');
 rewrite(planfile);
 write(planfile,tempplan^);
 if ioresult<>0 then errorhandler('PLANETS.DTA',5);
 close(planfile);
 assign(tarfile,'save'+chr(curfilenum+48)+'/CONTACTS.DTA');
 rewrite(tarfile);
 if ioresult<>0 then errorhandler('save'+chr(curfilenum+48)+'/CONTACTS.DTA',1);
 assign(srcfile,tempdir+'/contacts.dta');
 reset(srcfile);
 err:=false;
 repeat
  read(srcfile,temp);
  if ioresult<>0 then err:=true;
  if not err then
   begin
    write(tarfile,temp);
    if ioresult<>0 then errorhandler('CONTACTS.DTA',5);
   end;
 until err;
 close(tarfile);
 close(srcfile);
end;

procedure savegame(num: integer);
var shipfile : file of shiptype;
    systfile : file of systemarray;
   eventfile : file of eventarray;
   logsfile : file of logarray;
   logpendingfile : file of logpendingarray;
begin
   assign(shipfile,'save'+chr(num+48)+'/SHIP.DTA');
   rewrite(shipfile);
   if ioresult<>0 then errorhandler('SHIP.DTA',1);
   write(shipfile,ship);
   if ioresult<>0 then errorhandler('SHIP.DTA',5);
   close(shipfile);

   assign(systfile,'save'+chr(num+48)+'/SYSTEMS.DTA');
   rewrite(systfile);
   if ioresult<>0 then errorhandler('SYSTEMS.DTA',1);
   write(systfile,systems);
   if ioresult<>0 then errorhandler('SYSTEMS.DTA',5);
   close(systfile);
   
   assign(eventfile,'save'+chr(num+48)+'/EVENTS.DTA');
   rewrite(eventfile);
   if ioresult<>0 then errorhandler('EVENTS.DTA',1);
   write(eventfile,events);
   if ioresult<>0 then errorhandler('EVENTS.DTA',5);
   close(eventfile);

   assign(logsfile,'save'+chr(num+48)+'/LOGS.DTA');
   rewrite(logsfile);
   if ioresult<>0 then errorhandler('LOGS.DTA',1);
   write(logsfile,logs);
   if ioresult<>0 then errorhandler('LOGS.DTA',5);
   close(logsfile);

   assign(logpendingfile,'save'+chr(num+48)+'/PENDING.DTA');
   rewrite(logpendingfile);
   if ioresult<>0 then errorhandler('PENDING.DTA',1);
   write(logpendingfile,logpending);
   if ioresult<>0 then errorhandler('PENDING.DTA',5);
   close(logpendingfile);
   
   curfilenum:=num;
   saveplanetinfo;
end;

procedure loadplanetinfo;
var planfile: file of planarray;
    srcfile,tarfile: file of alientype;
    err: boolean;
    temp: alientype;
begin
 assign(planfile,'save'+chr(curfilenum+48)+'/PLANETS.DTA');
 reset(planfile);
 if ioresult<>0 then errorhandler('PLANETS.DTA',1);
 read(planfile,tempplan^);
 if ioresult<>0 then errorhandler('PLANETS.DTA',5);
 close(planfile);
 assign(tarfile,tempdir+'/contacts.dta');
 rewrite(tarfile);
 if ioresult<>0 then errorhandler(tempdir+'/contacts.dta',1);
 assign(srcfile,'save'+chr(curfilenum+48)+'/CONTACTS.DTA');
 reset(srcfile);
 if ioresult<>0 then errorhandler('CONTACTS.DTA',1);
 err:=false;
 repeat
  read(srcfile,temp);
  if ioresult<>0 then err:=true;
  if (not err) and ((temp.id>1000) or (tempplan^[temp.id].notes and 2>0)) then
   begin
    write(tarfile,temp);
    if ioresult<>0 then errorhandler(tempdir+'/contacts.dta',5);
   end;
 until err;
 close(tarfile);
 close(srcfile);
end;

procedure convertevents;
var
   i, j, k : Integer;
begin
   for i := 0 to 1023 do
      events[i] := 0;
   for i := 0 to 127 do
      logpending[i].log := -1;
   for i := 0 to 255 do
      logs[i] := -1;

   j := 0;
   for i := 0 to 49 do
   begin
      if ship.events[i] <= 50 then
      begin
	 logs[j] := ship.events[i];
	 k := logs[j];
	 inc(j);
	 events[k shr 3] := events[k shr 3] or (1 shl (k and 7));
      end;
   end;
   for i := 50 to (64 - 50) * 8 + 50 do
   begin
      j := (ship.events[50 + ((i - 50) shr 3)] shr ((i - 50) and 7)) and 1;
      events[i shr 3] := events[i shr 3] or (j shl (i and 7));
   end;
end;

procedure loadgame(num: integer);
var shipfile: file of shiptype;
    systfile: file of systemarray;
   eventfile : file of eventarray;
   logsfile : file of logarray;
   logpendingfile : file of logpendingarray;
begin
   assign(shipfile,'save'+chr(num+48)+'/SHIP.DTA');
   reset(shipfile);
   if ioresult<>0 then errorhandler('SHIP.DTA',1);
   read(shipfile,ship);
   if ioresult<>0 then errorhandler('SHIP.DTA',5);
   close(shipfile);
   
   assign(systfile,'save'+chr(num+48)+'/SYSTEMS.DTA');
   reset(systfile);
   if ioresult<>0 then errorhandler('SYSTEMS.DTA',1);
   read(systfile,systems);
   if ioresult<>0 then errorhandler('SYSTEMS.DTA',5);
   close(systfile);

   assign(eventfile,'save'+chr(num+48)+'/EVENTS.DTA');
   reset(eventfile);
   if ioresult<>0 then
      convertevents
   else begin
      read(eventfile,events);
      if ioresult<>0 then errorhandler('EVENTS.DTA',5);
      close(eventfile);
      
      assign(logsfile,'save'+chr(num+48)+'/LOGS.DTA');
      reset(logsfile);
      if ioresult<>0 then errorhandler('LOGS.DTA',1);
      read(logsfile,logs);
      if ioresult<>0 then errorhandler('LOGS.DTA',5);
      close(logsfile);

      assign(logpendingfile,'save'+chr(num+48)+'/PENDING.DTA');
      reset(logpendingfile);
      if ioresult<>0 then errorhandler('PENDING.DTA',1);
      read(logpendingfile,logpending);
      if ioresult<>0 then errorhandler('PENDING.DTA',5);
      close(logpendingfile);
   end;
   
   curfilenum:=num;
   loadplanetinfo;
   tslice:=ship.options[2];
   RebuildCargoReserve;
   ResetCrew;
end;

procedure undocursor;
begin
 if cursor=0 then exit;
 mousehide;
 if cursor<9 then plainfadearea(85,40+cursor*10,235,47+cursor*10,-3)
  else plainfadearea(185,130,225,138,-3);
 mouseshow;
end;

procedure drawcursor;
begin
 if cursor=0 then exit;
 mousehide;
 if cursor<9 then plainfadearea(85,40+cursor*10,235,47+cursor*10,3)
  else plainfadearea(185,130,225,138,3);
 mouseshow;
end;

procedure processkey;
var ans: char;
begin
 undocursor;
 ans:=readkey_utf8;
 case ans of
   #0: begin
        ans:=readkey;
        case ans of
         #72:if cursor=0 then cursor:=1
              else if cursor>1 then dec(cursor)
              else cursor:=9;
         #80:if cursor<9 then inc(cursor) else cursor:=1;
        end;
       end;
  '1': cursor:=1;
  '2': cursor:=2;
  '3': cursor:=3;
  '4': cursor:=4;
  '5': cursor:=5;
  '6': cursor:=6;
  '7': cursor:=7;
  '8': cursor:=8;
  'C','c': cursor:=9;
  #13: if cursor<>0 then done:=true;
  #27: begin
        cursor:=9;
        done:=true;
       end;
 end;
 drawcursor;
 lastx:=mouse.x;
 lasty:=mouse.y;
end;

procedure findmouse;
var button: boolean;
    newcursor: integer;
begin
 if mouse.getstatus then button:=true else button:=false;
 if (not button) and (mouse.x=lastx) or (mouse.y=lasty) then exit;
 case mouse.y of
    50..58: if (mouse.x>84) and (mouse.x<236) then newcursor:=1 else newcursor:=0;
    60..68: if (mouse.x>84) and (mouse.x<236) then newcursor:=2 else newcursor:=0;
    70..78: if (mouse.x>84) and (mouse.x<236) then newcursor:=3 else newcursor:=0;
    80..88: if (mouse.x>84) and (mouse.x<236) then newcursor:=4 else newcursor:=0;
    90..98: if (mouse.x>84) and (mouse.x<236) then newcursor:=5 else newcursor:=0;
  100..108: if (mouse.x>84) and (mouse.x<236) then newcursor:=6 else newcursor:=0;
  110..118: if (mouse.x>84) and (mouse.x<236) then newcursor:=7 else newcursor:=0;
  120..128: if (mouse.x>84) and (mouse.x<236) then newcursor:=8 else newcursor:=0;
  130..138: if (mouse.x>184) and (mouse.x<226) then newcursor:=9 else newcursor:=0;
  else newcursor:=0;
 end;
 if newcursor<>cursor then
  begin
   undocursor;
   cursor:=newcursor;
   drawcursor;
  end;
 if (cursor<>0) and (button) then done:=true;
end;

function mainloop(stars: boolean): integer;
var k: word;
    k2,k3,mode,b: integer;
begin
 done:=false;
 mouseshow;
 cursor:=curfilenum;
 drawcursor;
 lastx:=mouse.x;
 lasty:=mouse.y;
 k:=random(320);
 k2:=1;
 mode:=0;
 b:=tslice*2;
 if stars then fadein;
 repeat
  findmouse;
  if fastkeypressed then processkey;
  if stars then
   begin
    dec(k2);
    if k2=0 then
     begin
      k2:=15;
      inc(mode);
      if mode=8 then mode:=0;
      case mode of
       0: k3:=-320;
       1: k3:=-319;
       2: k3:=1;
       3: k3:=321;
       4: k3:=320;
       5: k3:=319;
       6: k3:=-1;
       7: k3:=-321;
      end;
     end;
    k:=k+k3;
    if k>65000 then k:=k+64000     else
     if k>64000 then k:=k-64000;
    mousehide;
    for i:=40 to 140 do
     mymove(screen[i,74],tempscr^[i,74],43);
    mouseshow;
{    asm
     push es
     push ds
     mov ax, [k]
     les di, [s]
     mov bx, di
     lds si, [backgr]
     mov cx, 64000
     sub cx, ax
     add di, ax
     cld
     rep movsb
     mov cx, ax
     mov di, bx
     rep movsb
     pop ds
     pop es
    end;
}

    p:=(@s^);
    move(backgr^,(p+k)^,64000-k);
    p:=@(backgr^);
    move((p+64000-k)^,s^,k);
   
    for i:=40 to 140 do
     mymove(tempscr^[i,74],s^[i,74],43);
    mousehide;
 {   asm
     push es
     push ds
     mov ax, 0A000h
     mov es, ax
     xor di, di
     mov cx, 32000
     lds si, [s]
     rep movsw
     pop ds
     pop es
    end;
}
    move(s^,screen,64000);
    mouseshow;
    delay(b);
   end;

 until done;
 mainloop:=cursor;
end;

function loadgamedata(tofadein: boolean): boolean;
var result: integer;
begin
 calt:=0;
 new(names);
 new(tempscr);
 tcolor:=26;
 mousehide;
 for i:=40 to 140 do
  mymove(screen[i,74],tempscr^[i,74],43);
 button(75,40,244,140,0);
 for a:=1 to 8 do button(85,40+a*10,235,48+a*10,2);
 button(185,130,225,138,2);
 loadfilenames;
 bkcolor:=35;
 printxy(130,41,'Load Game');
 displayfilenames;
 if tofadein then
  begin
   new(s);
   for i:=40 to 140 do
    mymove(screen[i,74],tempscr^[i,74],43);
   loadscreen('data/cloud',@screen);
   mymove(screen,backgr^,16000);
   for i:=40 to 140 do
    mymove(tempscr^[i,74],screen[i,74],43);
  end;
 result:=mainloop(tofadein);
 if result=9 then loadgamedata:=false else
  begin
   loadgamedata:=true;
   loadgame(result);
  end;
 mousehide;
 if tofadein then dispose(s)
  else for i:=40 to 140 do
   mymove(tempscr^[i,74],screen[i,74],43);
 mouseshow;
 dispose(tempscr);
 dispose(names);
 bkcolor:=3;
 if result<9 then
 begin
    event(10);
    if chevent(12) then event(1001);
 end;
end;

function readname: boolean;
var namecur: integer;
    ans: char;
    done: boolean;
begin
 namecur:=20;
 while names^[cursor].name[namecur]=' ' do dec(namecur);
 if namecur<20 then inc(namecur);
 done:=false;
 mousehide;
 ans:=' ';
 repeat
  bkcolor:=40+calt;
  printxy(85,41+10*cursor,names^[cursor].name);
  bkcolor:=82;
  printxy(80+5*namecur,41+10*cursor,names^[cursor].name[namecur]);
  delay(tslice*2);
  if fastkeypressed then
   begin
    ans:=readkey_utf8;
    case upcase(ans) of
     #0:
      begin
       ans:=readkey;
       case ans of
        #77:if namecur<20 then inc(namecur);
        #75:if namecur>1 then dec(namecur);
        #83:begin
             for j:=namecur to 19 do
             names^[cursor].name[j]:=names^[cursor].name[j+1];
             names^[cursor].name[20]:=' ';
            end;
       end;
      end;
     #8:
      begin
       if namecur>1 then dec(namecur);
       for j:=namecur to 19 do
        names^[cursor].name[j]:=names^[cursor].name[j+1];
       names^[cursor].name[20]:=' ';
      end;
      ' ' ..'"',''''..'?','A' ..'Z','%','a'..'z':
      begin
       for j:=20 downto namecur+1 do
        names^[cursor].name[j]:=names^[cursor].name[j-1];
       names^[cursor].name[namecur]:=ans;
       if namecur<20 then inc(namecur);
      end;
     #27: done:=true;
    end;
   end;
 until (ans=#13) or (done);
 if not done then readname:=true else readname:=false;
 bkcolor:=40;
end;

function savegamedata(alt,text: integer): boolean;
var result: integer;
label redo;
begin
 new(tempscr);
 new(names);
 mousehide;
 for i:=40 to 140 do
  mymove(screen[i,74],tempscr^[i,74],43);
 tcolor:=text;
 button(75,40,244,140,alt);
 for a:=1 to 8 do button(85,40+a*10,235,48+a*10,2+alt);
 button(185,130,225,138,2+alt);
 bkcolor:=35+alt;
 printxy(130,41,'Save Game');
 calt:=alt;
 tcolor:=text-5;
redo:
 loadfilenames;
 displayfilenames;
 result:=mainloop(false);
 if result=9 then savegamedata:=false
 else
  begin
   if not readname then
    begin
     undocursor;
     goto redo;
    end;
   mouseshow;
   names^[result].yearstamp:=ship.stardate[3];
   names^[result].monthstamp:=ship.stardate[1];
   savefilenames;
   savegamedata:=true;
   savegame(result);
  end;
 mousehide;
 for i:=40 to 140 do
  mymove(tempscr^[i,74],screen[i,74],43);
 dispose(names);
 dispose(tempscr);
 mouseshow;
 bkcolor:=3;
end;

procedure undocursor2;
begin
 if cursor=0 then exit;
 if cursor=1 then plainfadearea(110,78,150,92,-3)
  else plainfadearea(169,78,209,92,-3);
end;

procedure drawcursor2;
begin
 if cursor=0 then exit;
 if cursor=1 then plainfadearea(110,78,150,92,3)
  else plainfadearea(169,78,209,92,3);
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
        cursor:=2;
        done:=true;
       end;
  'Y': begin
        cursor:=1;
        done:=true;
       end;
  'N': begin
        cursor:=2;
        done:=true;
       end;
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
           110..150: newcursor:=1;
           169..209: newcursor:=2;
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

function mainloop2: boolean;
begin
 done:=false;
 lastx:=0;
 lasty:=0;
 cursor:=0;
 mouseshow;
 repeat
  findmouse2;
  if fastkeypressed then processkey2;
    delay(tslice);
    fadestep(8);
 until done;
 if cursor=1 then mainloop2:=true else mainloop2:=false;
end;

function yesnorequest(s: string; alt,text: integer): boolean;
var result: boolean;
begin
 new(tempscr);
 mousehide;
 tcolor:=text;
 for i:=60 to 102 do
  mymove(screen[i,74],tempscr^[i,74],43);
 tcolor:=text-5;
 bkcolor:=35+alt;
 button(74,60,245,102,alt);
 button(110,78,150,92,2+alt);
 button(169,78,209,92,2+alt);
 printxy(156-round(length(s)*2.5),65,s);
 bkcolor:=37+alt;
 printxy(118,82,'Yes');
 printxy(179,82,'No');
 result:=mainloop2;
 mousehide;
 for i:=60 to 102 do
  mymove(tempscr^[i,74],screen[i,74],43);
 dispose(tempscr);
 yesnorequest:=result;
 bkcolor:=3;
 mouseshow;
// mouse.x:=0;
// mouse.y:=0;
move_mouse(0,0);
end;

procedure displayencodes;
var str1: string[8];
begin
 for a:=1 to 6 do
  begin
   printxy(50,35+a*15,ship.encodes[a].name);
   str(ship.encodes[a].phy:2,str1);
   printxy(153,35+a*15,str1+'/');
   str(ship.encodes[a].men:2,str1);
   printxy(168,35+a*15,str1+'/');
   str(ship.encodes[a].emo:2,str1);
   printxy(183,35+a*15,str1);
   str(ship.encodes[a].xp:8,str1);
   printxy(200,35+a*15,str1);
   printxy(241,35+a*15,'XP');
  end;
 printxy(221,140,'Cancel');
end;

procedure displaycrew;
var str1: string[8];
begin
 for a:=1 to 6 do
  begin
   printxy(50,35+a*15,ship.crew[a].name);
   str(ship.crew[a].phy:2,str1);
   printxy(153,35+a*15,str1+'/');
   str(ship.crew[a].men:2,str1);
   printxy(168,35+a*15,str1+'/');
   str(ship.crew[a].emo:2,str1);
   printxy(183,35+a*15,str1);
   str(ship.crew[a].xp:8,str1);
   printxy(200,35+a*15,str1);
   printxy(241,35+a*15,'XP');
  end;
 printxy(221,140,'Cancel');
 printxy(51,140,'Encode All');
end;

procedure undoenccursor;
begin
 if cursor=0 then exit;
 mousehide;
 if cursor<7 then plainfadearea(50,33+cursor*15,260,44+cursor*15,-3)
  else if cursor=7 then plainfadearea(220,138,260,149,-3)
  else if cursor=8 then plainfadearea(50,138,110,149,-3);
 mouseshow;
end;

procedure drawenccursor;
begin
 if cursor=0 then exit;
 mousehide;
 if cursor<7 then plainfadearea(50,33+cursor*15,260,44+cursor*15,3)
  else if cursor=7 then plainfadearea(220,138,260,149,3)
  else if cursor=8 then plainfadearea(50,138,110,149,3);
 mouseshow;
end;

procedure processenckey;
var ans: char;
begin
 undoenccursor;
 ans:=readkey_utf8;
 case upcase(ans) of
   #0: begin
        ans:=readkey;
        case ans of
         #72:if cursor=0 then cursor:=1
              else if cursor>1 then dec(cursor)
              else cursor:=6;
         #80:if cursor<6 then inc(cursor) else cursor:=1;
        end;
       end;
  '1'..'6': cursor:=ord(ans)-48;
  '7': if encoding then cursor:=8;
  'C': cursor:=7;
  #13: if cursor<>0 then done:=true;
  #27: begin
        cursor:=7;
        done:=true;
       end;
 end;
 drawenccursor;
 lastx:=mouse.x;
 lasty:=mouse.y;
end;

procedure findencmouse;
var button: boolean;
    newcursor: integer;
begin
 if mouse.getstatus then button:=true else button:=false;
 if (not button) and (mouse.x=lastx) or (mouse.y=lasty) then exit;
 case mouse.y of
     48..59: if (mouse.x>49) and (mouse.x<261) then newcursor:=1 else newcursor:=0;
     63..74: if (mouse.x>49) and (mouse.x<261) then newcursor:=2 else newcursor:=0;
     78..89: if (mouse.x>49) and (mouse.x<261) then newcursor:=3 else newcursor:=0;
    93..104: if (mouse.x>49) and (mouse.x<261) then newcursor:=4 else newcursor:=0;
   108..119: if (mouse.x>49) and (mouse.x<261) then newcursor:=5 else newcursor:=0;
   123..134: if (mouse.x>49) and (mouse.x<261) then newcursor:=6 else newcursor:=0;
   138..149: case mouse.x of
              220..260: newcursor:=7;
               50..110: if encoding then newcursor:=8;
              else newcursor:=0;
             end;
  else newcursor:=0;
 end;
 if newcursor<>cursor then
  begin
   undoenccursor;
   cursor:=newcursor;
   drawenccursor;
  end;
 if tcolor=181 then i:=38 else i:=0;

 if (newcursor<>0) and (button) then { if we clicked on one of 8 buttons }
  begin
   if newcursor=8 then
    begin
     if yesnorequest('Encode All?',i,tcolor) then newcursor:=8 else newcursor:=7; { if answered "no", simulate as "cancel" has been pressed }
    end;
    done:=true;
    cursor:=newcursor;
  end;
end;

function mainencloop: integer;
begin
 done:=false;
 cursor:=0;
 lastx:=0;
 lasty:=0;
 mouseshow;
 repeat
  findencmouse;
  if fastkeypressed then processenckey;
 until done;
 mainencloop:=cursor;
end;

procedure encodecrew(tc: integer);
var src,t,b,alt: integer;
begin
 t:=tcolor;
 b:=bkcolor;
 encoding:=true;
 mousehide;
 compressfile(tempdir+'/current2',@screen);
 tcolor:=tc;
 if tc>31 then alt:=38 else alt:=0;
 button(42,30,270,152,alt);
 for a:=1 to 6 do button(50,33+a*15,260,44+a*15,2+alt);
 button(220,138,260,149,2+alt);
 button(50,138,110,149,2+alt);
 bkcolor:=35+alt;
 printxy(107,37,'Encode Crew Member:');
 bkcolor:=37+alt;
 displaycrew;
 src:=mainencloop;
 if src<7 then
  begin
   undoenccursor;
   bkcolor:=35+alt;
   printxy(107,37,'  Encode to Chip:  ');
   bkcolor:=37+alt;
   delay(tslice*10);
   mousehide;
   displayencodes;
   if mainencloop<7 then
    ship.encodes[cursor]:=ship.crew[src];
  end;
 if src=8 then
  begin
   for j:=1 to 6 do ship.encodes[j]:=ship.crew[j];
  end;
 mousehide;
 loadscreen(tempdir+'/current2',@screen);
 mouseshow;
 tcolor:=t;
 bkcolor:=b;
end;

procedure decodecrew;
begin
 encoding:=false;
 mousehide;
 compressfile(tempdir+'/current',@screen);
 tcolor:=26;
 button(42,30,270,152,0);
 for a:=1 to 6 do button(50,33+a*15,260,44+a*15,2);
 button(220,138,260,149,2);
 bkcolor:=35;
 printxy(107,37,'Decode Crew Member:');
 bkcolor:=37;
 displayencodes;
 if mainencloop<7 then
  begin
   for j:=1 to 6 do if ship.encodes[cursor].name=ship.crew[j].name then
    begin
     ship.crew[j]:=ship.encodes[cursor];
     j:=6;
    end;
  end;
 mousehide;
 loadscreen(tempdir+'/current',@screen);
 mouseshow;
end;

procedure showbotstuff(curplan: integer);
var index,j,max,total: integer;
    str1: string[10];
    amounts: array[0..16] of byte;
    temp: ^scantype;
    scanfile: file of scantype;
begin
 new(temp);
 assign(scanfile,'data/scan.dta');
 reset(scanfile);
 if ioresult<>0 then errorhandler('scan.dta',1);
 read(scanfile,temp^);
 if ioresult<>0 then errorhandler('scan.dta',5);
 close(scanfile);
 for j:=0 to 16 do amounts[j]:=temp^[j,tempplan^[curplan].state];
 total:=0;
 for j:=0 to 16 do total:=total+amounts[j];
 y:=0;
 repeat
  inc(y);
  max:=amounts[0];
  index:=0;
  for j:=0 to 16 do
   if amounts[j]>max then
    begin
     max:=amounts[j];
     index:=j;
    end;
  if max>0 then
   begin
    x1:=max/total*100;
    write(ft,chr(65+index));
    amounts[index]:=0;
   end;
 until (y=5) or (max=0);
 if (max=0) and (y<5) then
  for j:=y to 5 do write(ft,' ');
 dispose(temp);
end;

procedure printinfo;
var s: string[12];
    str1,str4: string[20];
    line,techlvl,last,sec,a,b: integer;
begin
 assign(ft,'LPT1');
 rewrite(ft);
 if ioresult<>0 then exit;
 if ioresult<>0 then exit;
 new(tempscr);
 mousehide;
 for i:=85 to 105 do
  mymove(screen[i,75],tempscr^[i,75],43);
 graybutton(75,85,245,105);
 revgraybutton(84,89,236,101);
 last:=0;
 line:=0;
 for sec:=0 to 7 do
  begin
   b:=0;
   for j:=1 to 1000 do
    begin
     if systems[tempplan^[j].system].x>1250 then a:=1 else a:=0;
     if systems[tempplan^[j].system].y>1250 then a:=a+2;
     if systems[tempplan^[j].system].z>1250 then a:=a+4;
     if (tempplan^[j].visits>0) and (a=sec) then with tempplan^[j] do
      begin
       if b=0 then
        begin
         write(ft,'IRONSEED PLANETARY FILE FOR ');
         case sec of
          0: write(ft,'ALPHA');
          1: write(ft,'BETA');
          2: write(ft,'GAMMA');
          3: write(ft,'DELTA');
          4: write(ft,'EPSILON');
          5: write(ft,'ZETA');
          6: write(ft,'ETA');
          7: write(ft,'THETA');
         end;
         writeln(ft,' SECTOR');
         writeln(ft);
         writeln(ft,'  SIZE   STATE  ROBOTS CSH      SCANS    CONTACT ELEM. ALIEN LIFEFORM FOUND');
         writeln(ft,'______ _______ _______ ___ __________ __________ _____ ____________________');
         line:=4;
        end;
       inc(b);
       inc(line);
       if system<>last then
        begin
         writeln(ft);
         last:=system;
         if line>54 then
          begin
           writeln(ft,'');
           writeln(ft,'  SIZE   STATE  ROBOTS CSH      SCANS    CONTACT ELEM. ALIEN LIFEFORM FOUND');
           writeln(ft,'______ _______ _______ ___ __________ __________ _____ ____________________');
           line:=2;
          end;
         write(ft,systems[system].name);
         write(ft,' (',(systems[system].x/10):0:1);
         write(ft,',',(systems[system].y/10):0:1);
         writeln(ft,',',(systems[system].z/10):0:1,')');
         inc(line,2);
        end;
       if orbit=0 then
        case mode of
         1: s:=' Giant';
         2: s:=' Large';
         3: s:='  Tiny';
        end
       else
        case psize of
         0: s:='  Tiny';
         1: s:=' Small';
         2: s:='Medium';
         3: s:=' Large';
         4: s:=' Giant';
        end;
       write(ft,s);
       case state of
        0: s:=' Gaseous';
        1: s:='  Active';
        2: s:='  Stable';
        3: s:=' Ea.Life';
        4: s:=' Ad.Life';
        5: s:='   Dying';
        6: s:='    Dead';
        7: s:='    Star';
       end;
       write(ft,s);
       case bots of
        0: s:='    None';
        1: s:=' Minebot';
        2: s:=' Factory';
       end;
       write(ft,s);
       if orbit>0 then
        begin
         a:=0;
         for i:=1 to 7 do if cache[i]>0 then inc(a);
         s:=' '+char(a+48)+'/7';
        end
       else s:='    ';
       write(ft,s);
       if (orbit=0) or (notes and 1>0) then write(ft,'   Complete')
        else write(ft,' Incomplete');
       if notes and 2>0 then write(ft,'  Contacted ')
        else write(ft,'       None ');
       if (orbit>0) and (notes and 1>0) then showbotstuff(j)
        else if orbit=0 then write(ft,'    ')
        else write(ft,'Unkn.');
       if (notes and 2>0) or (notes and 32>0) then
        begin
         str4:='';
         case tempplan^[a].system of
           93: str1:='Sengzhac';
          138: str1:='D''phak';
           45: if not chevent(27) then str1:='Ermigen';
          221: str1:='Titarian';
           78: str1:='Quai Pa''loi';
          171: str1:='Icon';
          191: str1:='The Guild';
         else if (state=6) and (mode=2) then str1:='Void Dwellers'
         else
          begin
           techlvl:=-2;
           case state of
            2: case mode of
                2: techlvl:=-1;
                3: techlvl:=0;
               end;
            3: techlvl:=mode-1;
            4: techlvl:=mode+2;
            5: case mode of
                1: techlvl:=0;
                2: techlvl:=-1;
               end;
           end;
           case techlvl of
            -2: str1:='None';
            -1: begin
                 randseed:=seed;
                 a:=random(word(state+mode+seed)) mod 3;
                 case a of
                  0: if random(2)=0 then str1:='Short Chain Proteins'
                      else str1:='Long Chain Proteins';
                  1: if random(2)=0 then str1:='Simple Protoplasms'
                      else str1:='Complex Protoplasms';
                  2: begin
                      case random(3) of
                       0: str4:='Chaosms';
                       1: str4:='Communes';
                       2: str4:='Heirarchies';
                      end;
                      str1:='Singlecelled';
                     end;
                 end;
                end;
            0..5: begin
                   randseed:=seed;
                   str4:=alientypes[random(11)];
                   case random(5) of
                    0: str1:='Carnivorous';
                    1: str1:='Herbivorous';
                    2: str1:='Omnivorous';
                    3: str1:='Cannibalistic';
                    4: str1:='Photosynthetic';
                   end;
                  end;
           end;
          end;
         end;
        if (str4<>'') and (length(str1)+length(str4)+1>20) then str4[0]:=chr(19-length(str1));
        write(ft,' ',str1,' ',str4);
       end else if orbit>0 then write(ft,' Unknown');
       writeln(ft);
      end;
     for i:=90 to 100 do
      screen[i,round(j*0.15+85)]:=44;
    end;
   if b>0 then writeln(ft,'');
  end;
 delay(tslice*3);
 close(ft);
 dispose(tempscr);
 for i:=85 to 105 do
  mymove(tempscr^[i,75],screen[i,75],43);
 mouseshow;
 if ioresult<>0 then printbox('Printer Error!');
end;

procedure printpartof(rangemin,rangemax: integer);
var c,d: integer;
begin
 c:=0;
 d:=0;
 writeln(ft,'NUM         NAME         SIZE EACH TOTAL SIZE');
 writeln(ft,'___ ____________________ _________ __________');
 for j:=1 to 250 do
  if (ship.cargo[j]>rangemin) and (ship.cargo[j]<rangemax) then
   begin
    write(ft,ship.numcargo[j]:3);
    if ship.cargo[j]>5999 then
     begin
      getartifactname(ship.cargo[j]);
      a:=maxcargo;
     end
    else
     begin
      a:=1;
      while (cargo[a].index<>ship.cargo[j]) and (a<maxcargo) do inc(a);
     end;
    write(ft,' ',cargo[a].name);
    write(ft,(cargo[a].size/10):10:1);
    calt:=cargo[a].size*ship.numcargo[j];
    d:=d+calt;
    i:=i+calt;
    writeln(ft,(calt/10):11:1);
    inc(lastx);
    lasty:=lasty+ship.numcargo[j];
    c:=c+ship.numcargo[j];
  end;
 writeln(ft,'TOTAL: ',c,'   TOTAL SIZE:',(d/10):0:1);
 writeln(ft);
 writeln(ft);
end;

procedure printcargo;
begin
 mousehide;
 new(tempscr);
 for i:=85 to 105 do
  mymove(screen[i,105],tempscr^[i,105],28);
 graybutton(105,85,215,105);
 tcolor:=191;
 i:=0;
 lastx:=0;
 lasty:=0;
 bkcolor:=5;
 printxy(132,92,'PRINTING...');
 assign(ft,'LPT1');
 rewrite(ft);
 writeln(ft,'IRONSEED CARGO FILE:');
 writeln(ft);
 writeln(ft,'WEAPONS:');
 printpartof(999,1499);
 writeln(ft,'SHIELDS:');
 printpartof(1499,1999);
 writeln(ft,'DEVICES:');
 printpartof(1999,2999);
 writeln(ft,'COMPONENTS:');
 printpartof(2999,3999);
 writeln(ft,'MATERIALS:');
 printpartof(3999,4999);
 writeln(ft,'ELEMENTS:');
 printpartof(4999,5999);
 writeln(ft,'ARTIFACTS:');
 printpartof(5999,6999);
 writeln(ft,'     NET CARGO SIZE: ',(i/10):0:1,' CUBIC METERS');
 writeln(ft,' CARGO SLOTS FILLED: ',lastx,'/250');
 writeln(ft,' TOTAL NUMBER ITEMS: ',lasty);
 writeln(ft);
 close(ft);
 dispose(tempscr);
 for i:=85 to 105 do
  mymove(tempscr^[i,105],screen[i,105],28);
 mouseshow;
 bkcolor:=3;
 if ioresult<>0 then printbox('Printer Error!');
end;

begin
 curfilenum:=0;
end.
