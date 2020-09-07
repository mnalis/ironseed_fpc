unit weird;
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
   CatchAll unit for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}


interface

const
 maxeventsystems= 11;
 eventsystems: array[0..maxeventsystems] of byte =
  (211,129,182, 31, 98,138,229, 28,182,119,182, 14);
 eventstorun: array[0..maxeventsystems] of integer =
  ( 12, 13, 15, 14, 16, 17, 20, 24,14,10000,10002,25);

{sys event        place
 --- ----- -------------------
 211  202 satellite from is2
 119  203 phaedor moch 1
 129  206 hallifax     (&260)
 182  220 trojan gate
  31  220 lix
 123  223 aria
 169  229 aard ship
 205  234 titerian worshipers     <- check 265 again!
  98  235 monks
 138  241 derelict
 164      nova
 229  248 shuntship
  28  265 temple
  33      derrack
  14      derrack base
 241      ermigen
  23      scav system
 247      god's eye
 129  260 hallifax 2
}

function skillcheck(n: integer): boolean;
procedure sanitycheck(n: integer);
{$IFNDEF DEMO}
procedure easteregg2;
procedure easteregg3;
procedure easteregg4;
procedure easteregg5;
{$ENDIF}
procedure bossmode;
procedure deathsequence(n: integer);
procedure event(n: integer);
procedure clearevent(n: integer);
procedure screensaver;
procedure lifesupportfailure;
procedure addpending(n, t : integer);
procedure tickpending(ticks : integer; background : boolean);
procedure blast(c1,c2,c3: integer);

implementation

uses utils_, data, utils, gmouse, journey, comm2, comm, combat, modplay, utils2, ending;

{$IFNDEF DEMO}
var
 done: boolean;
{$ENDIF}

procedure blast(c1,c2,c3: integer);
var a,b,j: integer;
    temppal: paltype;
begin
 temppal[0,1]:=0;		// to turn off warnings, variables are actually correctly initialized by function below
 move(colors,temppal,sizeof(paltype));
 b:=tslice*4;
 for a:=1 to 63 do
  begin
   for j:=0 to 255 do
    begin
     colors[j,1]:=colors[j,1] + round(a*(c1-colors[j,1])/63);
     colors[j,2]:=colors[j,2] + round(a*(c2-colors[j,2])/63);
     colors[j,3]:=colors[j,3] + round(a*(c3-colors[j,3])/63);
    end;
   set256colors(colors);
   delay(b);
  end;
 set256colors(colors);
 move(temppal,colors,sizeof(paltype));
end;

{ add event "n" to happen in some time "t" in the future }
procedure addpending(n, t : integer);
var
   i : integer;
begin
   for i := 0 to 127 do
   begin
      if logpending[i].log = n then
      begin
	 if logpending[i].time > t then
	    logpending[i].time := t;
	 exit;
      end;
      if logpending[i].log < 0 then
      begin
	 logpending[i].log := n;
	 logpending[i].time := t;
	 exit;
      end;
   end;
end; { addpending }

{ move logpending[] to events[]/logs[] when it's time happens }
procedure tickpending(ticks : integer; background : boolean);
var
   i, j : integer;
begin
   i := 0;
   while i < 128 do
   begin
      if logpending[i].log < 0 then
	 break;
      dec(logpending[i].time, ticks);
      if logpending[i].time <= 0 then
      begin
	 if background then
	 begin
	    logpending[i].time := 0;
	 end else begin
	    event(logpending[i].log);
	    for j:= i + 1 to 127 do
	    begin
	       logpending[j - 1] := logpending[j];
	       if logpending[j].log < 0 then
		  break;
	    end;
	    logpending[127].log := -1;
	    dec(i);
	 end;
      end;
      inc(i);
   end;
end; { tickpending }

{ just sets the bit in events[] bitmap (and in ship.events bitmap for events 50-500) }
procedure setevent(n: integer);
var i,j: word;
begin
   assert (n < 8192, 'event index out of bounds2');
   if n >= 8192 then
      exit;
   events[n shr 3] := events[n shr 3] or (1 shl (n and 7));

   if (n<50) or (n>=500) then exit;
   n:=n-50;
   i:=50+(n div 8);	{ same as 50+(n shr 3) ? }
   j:=n mod 8;		{ same as (n and 7) ? }
   assert (i<=64, 'ship.events index out of bounds1');
   ship.events[i]:=ship.events[i] or (1 shl j);
end;

{ just clears the bit in events[] bitmap (and in ship.events bitmap for events 50-500) }
procedure clearevent(n: integer);
var i,j: word;
begin
   assert (n < 8192, 'event index out of bounds3');
   if n >= 8192 then
      exit;
   events[n shr 3] := events[n shr 3] and not (1 shl (n and 7));

   if (n<50) or (n>=500) then exit;
   n:=n-50;
   i:=50+(n div 8);
   j:=n mod 8;
   assert (i<=64, 'ship.events index out of bounds2');
   ship.events[i]:=ship.events[i] and not (1 shl j);
end;

{ add and display a log "n" to first unused (-1) space in logs[256].
  Also sets an event "n".
  For events < 50, also add compatibility to ship.events[] }
procedure addlog(n: integer);
var i: integer;
begin
   setevent(n);
   i:=0;
   while logs[i] <> -1 do
      inc(i);
   assert (i<=255, 'logs index out of bounds');
   logs[i] := n;
   if n < 50 then
   begin
      {Set old style log/events.}
      i:=0;
      while ship.events[i]<>255 do inc(i);
      assert (i<50, 'ship.events (non-bitmapped) index out of bounds');
      ship.events[i]:=n;
   end;
   computerlogs(n);
end;

procedure startphaedormoch;
begin
 getspecial(10,1010);
 addtofile;
 createwandering(WNDORDER_RETREAT);
end;

procedure startarmada;
begin
 getspecial(7,1007);
 addtofile;
 createwandering(WNDORDER_ATTACK);
 initiatecombat;
end;

{ this handles all associated things that happen related to that event (like cargo/systems update, endgame etc.)
  It might add a log for that event (but not always)
  and it might mark that event as happened via setevent() (but not for events 0-50 nor 1000-1999 !)
}
procedure event(n: integer);
var i,j: integer;
//    p:^byte;
begin
    if (n=10)then
    begin
//        p^:=0;
    end;
   if chevent(n) then exit;
   {Don't set log events. Some logs won't activate unless another event has been activated.}
   if not (((n >= 0) and (n < 50)) or ((n >= 1000) and (n <= 1999))) then
   begin
      setevent(n);
   end;

 case n of

   0..9 : addlog(n);       { alien races: 0=Sengzhac 1=D'phak 2=Aard 3=Ermigen 4=Titarian 5=Quai_Paloi 6=Scavengers 7=Icon 8=The_Guild 9=Void_Dwellers  }
   11	: addlog(11);      { sector codex }
   12	: begin            { second buoy  }
	     systems[145].notes:=systems[145].notes or 1;
	     systems[211].notes:=systems[211].notes or 1;
	     systems[115].notes:=systems[115].notes or 1;
	     systems[ 18].notes:=systems[ 18].notes or 1;
	     systems[199].notes:=systems[199].notes or 1;
	     systems[103].notes:=systems[103].notes or 1;
	     systems[216].notes:=systems[216].notes or 1;
	     systems[105].notes:=systems[105].notes or 1;
	     systems[ 93].notes:=systems[ 93].notes or 1;
	     addlog(12);
	     event(1001);
	  end;
   13	: addlog(13);      { hallifax     }
   14	: begin            { trojan gate  }
	     addlog(14);
	     redoscreen(2389,1695,1314);
	  end;
   15	: addlog(15);      { planets dest }
   16	: addlog(16);      { monks        }
   17	: begin            { derelict     }
	     addcargo(ID_ART_THERMAL_PLATING, true);
	     for j:=0 to 3 do addcargo(ID_UNKNOWN_COMPONENT, true);
	     addcargo(ID_UNKNOWN_MATERIAL, true);
	     addlog(17);
	  end;
   18	: addlog(18);      { thermoplast  }
   19	: begin            { nova         }
	     blast(63,63,63);
	     addlog(19);
	  end;
   20	: begin            { shunt ship   }
	     addcargo(ID_ART_SHUNT_DRIVE, true);
	     addlog(20);
	  end;
   21	: if chevent(36) then addlog(21); { malzatoir    }
   22	: if chevent(21) then addlog(22); { icon data    }
   24	: if (incargo(ID_ART_DETONATOR)>0) and (chevent(42)) then
	  begin           { in temple    }
	     removecargo(ID_ART_DETONATOR);
	     addcargo(ID_ART_CHANNELER, true);
	     addcargo(ID_ART_IRON_SEED, true);
	     addcargo(ID_ART_HOMING_DEVICE, true);
	     addlog(24);
	  end;
   25	: if (incargo(ID_ART_HOMING_DEVICE)>0) and (chevent(24)) then
	  begin          { pirate base }
	     removecargo(ID_STASIS_GENERATOR);
	     removecargo(ID_ART_HOMING_DEVICE);
	     addcargo(ID_ART_SHUNT_DRIVE, true);
	     for j:=1 to random(3) do
		if random(2)=0 then addcargo(random(400)+1+ID_ARTIFACT_OFFSET, true)
		else addcargo(random(100)+1+ID_ARTIFACT2_OFFSET, true);
	     for j:=1 to 3 do addcargo(ID_UNKNOWN_COMPONENT, true);
	     addlog(25);
	  end;
   26	: if chevent(24) then
	  begin           { piracy       }
	     removecargo(ID_ART_SHUNT_DRIVE);
	     addlog(26);
	  end;
   27	: if chevent(25) then addlog(27); { icon trans }
   28	: if chevent(30) then
	  begin           { find ermigen data tapes }
	     addcargo(ID_ART_ERMIGEN_DATA_TAPES, true);
	     addlog(28);
	     {erase notes on star}
	     for i := 1 to 1000 do
		if (tempplan^[i].system = 45) and (tempplan^[i].orbit = 0) then
		   tempplan^[i].notes := 0;
	  end;
   29	: errorhandler('Log #29 ain''t suppose to happen!',7); { kill this! blank!!! }
   36	: begin            { research drv }
	     addcargo(ID_ART_SHUNT_DRIVE, true);
	     addlog(36);
	  end;
   39	: begin
	     addcargo(ID_ART_DETONATOR, true);
	     addlog(39);
	  end;
   40	: begin            { glyptic scythe }			{FIXME: from logs.txt Phaedor_Moch LOG is #40, but it seem to be handled by event40 GLYPTIC SCYTHE here - but shouldn't that be log @1101? what if we don't give them items for repair?? would we get log of them at all?)  however it did seem to work previously, so I won't be touchinh this unless it turns out to be a problem}
	     addcargo(ID_ART_GLYPTIC_SCYTHE, true);
	     addlog(40);
	  end;
   42	: addlog(42);      { temple found }
   43	: begin            { guild get genes }
	     removecargo(ID_ART_YLINTH_MUTAGENICS);
	     addlog(43);
	  end;
   45	: begin            { doom gate    }
	     addcargo(ID_DOOM_GATE, true);
	     addlog(45);
	  end;
   46	: begin            { thaumaturge  }
	     addcargo(ID_THAUMATURGE, true);
	     addlog(46);
	  end;
   47	: begin            { titarian like shuntdrive }
	     removecargo(ID_ART_SHUNT_DRIVE);
	     addlog(47);
	  end;
   48	: begin            { quai pa'loi join }
	     addcargo(ID_ART_MULTI_IMAGER, true);
	     addlog(48);
	  end;
   49	: begin            { find genes }
	     addcargo(ID_ART_YLINTH_MUTAGENICS, true);
	     addlog(49);
	  end;
   1103	: begin {Recovery of the Cargan (Ermigen flagship)}
	     addlog(1103);
	  end;
//    end;
 //case n of
   10,23,30..35,37,38,41,44: addlog(n);    { catch the other logs too }
   1000..1102,1104..1999: addlog(n);    { catch the new logs also }
   10000      : begin
		   println;
		   tcolor:=94;
		   print('SECURITY: Scanners detect alien ship.');
		   startphaedormoch;
		   tcolor:=94;
		   println;
		   print('SCIENCE: Perhaps we should initiate contact, Laird.');
		end;
   10001      : removecargo(ID_ART_MULTI_IMAGER); { remove multi-imager }
   10002      : begin              { scavenger armada }
		   if (chevent(45)) and (chevent(46)) and (chevent(31))
		      and ((chevent(34)) or (chevent(30)))
		      and (chevent(47)) and (chevent(48)) and (chevent(21))
		      and (chevent(23))
		      then
		   begin
		      startarmada;
		      endgame;
		   end;
		   repeat
		      startarmada;
		   until quit;
		end;
 end; { case }
end;

procedure tempinsanity(n: integer);
var i: integer;
    s: string[80];
begin
 set256colors(colors);
 if (random(5)>0) then exit;
 i:=random(19);
 case i of
   0: s:='Out of memory error on brain '+chr(n+64)+'.';
   1: s:='Brain '+chr(n+64)+' not a supported device.';
   2: s:='Read error on brain '+chr(n+64)+' incompatible media.';
   3: s:='CRC checksum error on brain '+chr(n+64)+'.';
   4: s:='Brain '+chr(n+64)+' has been upgraded to patch level 3.';
   5: s:='Segmentation error on brain '+chr(n+64)+'. Reboot?';
   6: s:='Mentation error, corpse dumped.';
   7: s:='Network error on brain '+chr(n+64)+'. Abandom, Retry, Apologize?';
   8: s:='Brain '+chr(n+64)+' is not a system brain.';
   9: s:='Runtime error in LIFE.BIN.';
  10: s:='Runtime error 226 in LIFE.BIN exceeded 10.';
  11: s:='Divide by zero error in brain '+chr(n+64)+'.';
  12: s:='Write protection fault on core sector 02AF'+chr(n+64)+'.';
  13: s:='Runtime error 1 in program CHECKING.BIN.';
  14: s:='Underflow error in CHECKING.EXE.';
  15: s:='Overflow in TOWELETBOWEL.EXE. Flush stack?';
  16: s:='Interrupt vector table restored.';
  17: s:='Default settings.';
  18: s:='Power fluxuation detected on brain '+chr(n+64)+'.';
 end;
 showchar(n,s);
end;

procedure sanitycheck(n: integer);
var i: integer;
begin
 with ship.crew[n] do
  begin
   if san>0 then dec(san);
   if emo>1 then dec(emo,2) else emo:=0;
   if men>0 then dec(men);
   if phy<99 then inc(phy);
   if san=0 then
    begin
     tempinsanity(n);
     exit;
    end;
   i:=random(80);
   if i>san then
    begin
     tempinsanity(n);
     exit;
    end;
  end;
end;

function skillcheck(n: integer): boolean;
var i: integer;
begin
 i:=random(80);
 with ship.crew[n] do
  begin
   if i>skill then
    begin
     skillcheck:=false;
     i:=random(80);
     if i>perf then
      begin
       if perf>0 then dec(perf);
       if men>1 then dec(men,2) else men:=0;
       if phy>0 then dec(phy);
       if emo<99 then inc(emo);
      end;
     if perf=0 then
      begin
       sanitycheck(n);
       if skill>0 then dec(skill);
       if phy>1 then dec(phy,2) else phy:=0;
       if emo>0 then dec(emo);
       if men<99 then inc(men);
      end;
    end
   else skillcheck:=true;
  end;
end;

{$IFNDEF DEMO}
procedure easteregg2;
var
    c,i,j: integer;
    portrait: ^portraittype;
begin
 mousehide;
 compressfile(tempdir+'/current2',@screen);
 bkcolor:=5;
 fading;
 scr_fillchar(screen,sizeof(screen),0);
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=random(16)+200+(i mod 2)*16;
 graybutton(40,53,280,153);
 tcolor:=47;
 graybutton(110,25,210,61);
 printxy(134,30,'Channel 7');
 printxy(116,50,'Destiny: Virtual');
 tcolor:=188;
 printxy(139,70,'Welcome');
 printxy(141,80,'To The');
 printxy(134,90,'Channel 7');
 printxy(134,100,'Easteregg');
 printxy(144,110,'Hunt!');
 tcolor:=92;
 graybutton(80,146,240,160);
 revgraybutton(49,68,120,139);
 revgraybutton(200,68,271,139);
 printxy(91,150,'DON''T TOUCH THIS BUTTON!!!');
 new(portrait);
 loadscreen('data/image31',portrait);
 for i:=0 to 69 do
  for j:=0 to 69 do
   if portrait^[i,j]<32 then portrait^[i,j]:=portrait^[i,j] div 2
   else portrait^[i,j]:=(portrait^[i,j]-128) div 2;
 for i:=0 to 69 do
  scrto_move(portrait^[i],screen[i+69,50],70);
 loadscreen('data/image32',portrait);
 for i:=0 to 69 do
  for j:=0 to 69 do
   if portrait^[i,j]<32 then portrait^[i,j]:=portrait^[i,j] div 2
   else portrait^[i,j]:=(portrait^[i,j]-128) div 2;
 for i:=0 to 69 do
  scrto_move(portrait^[i],screen[i+69,201],70);
 dispose(portrait);
 mouseshow;
 c:=0;
 set256colors(colors);
 repeat
  for i:=200 to 215 do
   colors[i]:=colors[random(22)];
  for i:=216 to 231 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 2);
  done:=mouse.getstatus;
  if (c=0) and (mouse.y>145) and (mouse.y<161) and (mouse.x>79) and (mouse.x<241) then
   begin
    c:=1;
    mousehide;
    plainfadearea(80,146,240,160,3);
    mouseshow;
   end
  else if (c=1) and ((mouse.y<146) or (mouse.y>160) or (mouse.x<80) or (mouse.x>240)) then
   begin
    c:=0;
    mousehide;
    plainfadearea(80,146,240,160,-3);
    mouseshow;
   end;
  if fastkeypressed then readkey;
  for i:=216 to 231 do
   colors[i]:=colors[random(16)];
  for i:=200 to 215 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 2+7);
 until (done) and (c=1);
 fading;
 mousehide;
 loadscreen(tempdir+'/current2',@screen);
 set256colors(colors);
 bkcolor:=3;
 mouseshow;
end;

procedure easteregg3;
var
    j,c: integer;
    s: string[12];
    s2: string[3];
begin
 mousehide;
 compressfile(tempdir+'/current',@screen);
 tcolor:=92;
 bkcolor:=5;
 graybutton(0,0,319,199);
 graybutton(80,166,240,180);
 printxy(91,170,'DON''T TOUCH THIS BUTTON!!!');
 printxy(113,5,'Set Default Song');
 for j:=0 to 3 do
  begin
   graybutton(5,35+j*34,105,47+j*34);
   graybutton(109,35+j*34,209,47+j*34);
   graybutton(213,35+j*34,313,47+j*34);
  end;
 tcolor:=22;
 printxy(30,38,'Sengzhac');
 printxy(35,72,'D''Pahk');
 printxy(40,106,'Aard');
 printxy(33,140,'Ermigen');
 printxy(134,38,'Titarian');
 printxy(125,72,'Quai Pa''Loi');
 printxy(130,106,'Scavengers');
 printxy(144,140,'Icon');
 printxy(236,38,'The Guild');
 printxy(229,72,'Phaedor Moch');
 printxy(226,106,'Void Dwellers');
 printxy(241,140,'Generic');
 tcolor:=188;
 printxy(56,183,'Welcome To The Channel 7 Easteregg Hunt!');
 c:=0;
 s2:='  ';
 printxy(130,155,'/'+s2);
 printxy(175,155,'/63');
 mouseshow;
 repeat
  s2:='  ';
  printxy(120,155,s2);
  s2:='  ';
  printxy(165,155,s2);
  done:=mouse.getstatus;
  if (c=0) and (mouse.y>165) and (mouse.y<181) and (mouse.x>79) and (mouse.x<241) then
   begin
    c:=1;
    mousehide;
    plainfadearea(80,166,240,180,3);
    mouseshow;
   end
  else if (c=1) and ((mouse.y<166) or (mouse.y>180) or (mouse.x<80) or (mouse.x>240)) then
   begin
    c:=0;
    mousehide;
    plainfadearea(80,166,240,180,-3);
    mouseshow;
   end;
  if done then
   begin
    s:='';
    case mouse.x of
       5..105: case mouse.y of
                  35..47: s:='SENGZHAC.MOD';
                  69..81: s:='DPAK.MOD';
                103..115: s:='AARD.MOD';
                137..149: s:='ERMIGEN.MOD';
               end;
     109..209: case mouse.y of
                  35..47: s:='TITARIAN.MOD';
                  69..81: s:='QUAI.MOD';
                103..115: s:='SCAVENG.MOD';
                137..149: s:='ICON.MOD';
               end;
     213..313: case mouse.y of
                  35..47: s:='GUILD.MOD';
                  69..81: s:='PHADOR.MOD';
                103..115: s:='VOID.MOD';
                137..149: s:='SECTOR.MOD';
               end;
    end;
   if s<>'' then
    begin
     playmod(true,'sound/'+s);
     s2:='  ';
     mousehide;
     printxy(130,155,'/'+s2);
     mouseshow;
     defaultsong:=s;
    end;
  end;
  if fastkeypressed then readkey;
 until (done) and (c=1);
 fading;
 mousehide;
 loadscreen(tempdir+'/current',@screen);
 set256colors(colors);
 mouseshow;
end;

procedure easteregg4;
var i,j,c: integer;
begin
 mousehide;
 compressfile(tempdir+'/current2',@screen);
 bkcolor:=5;
 fading;
 scr_fillchar(screen,sizeof(screen),0);
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=random(16)+200+(i mod 2)*16;
 graybutton(40,53,280,153);
 tcolor:=47;
 graybutton(110,25,210,61);
 printxy(134,30,'Channel 7');
 printxy(116,50,'Destiny: Virtual');
 tcolor:=188;
 printxy(56,130,'Welcome To The Channel 7 Easteregg Hunt!');
 tcolor:=92;
 graybutton(80,146,240,160);
 printxy(91,150,'DON''T TOUCH THIS BUTTON!!!');
 graybutton(56,80,156,95);
 graybutton(163,80,263,95);
 graybutton(56,100,156,115);
 graybutton(163,100,263,115);
 printxy(57,84,'Repair Hull Damage');
 printxy(67,104,'Fill Fuel Tank');
 printxy(174,84,'Repair Damages');
 printxy(169,104,'Recharge Battery');
 mouseshow;
 c:=0;
 set256colors(colors);
 repeat
  for i:=200 to 215 do
   colors[i]:=colors[random(22)];
  for i:=216 to 231 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 2);
  done:=mouse.getstatus;
  if (c=0) and (mouse.y>145) and (mouse.y<161) and (mouse.x>79) and (mouse.x<241) then
   begin
    c:=1;
    mousehide;
    plainfadearea(80,146,240,160,3);
    mouseshow;
   end
  else if (c=1) and ((mouse.y<146) or (mouse.y>160) or (mouse.x<80) or (mouse.x>240)) then
   begin
    c:=0;
    mousehide;
    plainfadearea(80,146,240,160,-3);
    mouseshow;
   end;
  if done then
   case mouse.x of
     56..156: case mouse.y of
                 80..95: ship.hullintegrity:=ship.hullmax;
               100..115: ship.fuel:=ship.fuelmax;
              end;
    163..263: case mouse.y of
                 80..95: for j:=1 to 7 do ship.damages[j]:=0;
               100..115: ship.battery:=32000;
              end;
   end;
  if fastkeypressed then readkey;
  for i:=216 to 231 do
   colors[i]:=colors[random(16)];
  for i:=200 to 215 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 2+7);
 until (done) and (c=1);
 fading;
 mousehide;
 loadscreen(tempdir+'/current2',@screen);
 set256colors(colors);
 bkcolor:=3;
 mouseshow;
end;

procedure easteregg5;
var i,j,c: integer;
begin
 mousehide;
 compressfile(tempdir+'/current2',@screen);
 bkcolor:=5;
 fading;
 scr_fillchar(screen,sizeof(screen),0);
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=random(16)+200+(i mod 2)*16;
 graybutton(40,53,280,153);
 tcolor:=47;
 graybutton(110,25,210,61);
 printxy(134,30,'Channel 7');
 printxy(116,50,'Destiny: Virtual');
 tcolor:=188;
 printxy(56,130,'Welcome To The Channel 7 Easteregg Hunt!');
 tcolor:=92;
 graybutton(80,146,240,160);
 printxy(91,150,'DON''T TOUCH THIS BUTTON!!!');
 graybutton(56,80,156,95);
 graybutton(163,80,263,95);
 graybutton(56,100,156,115);
 graybutton(163,100,263,115);
 printxy(77,84,'Add a Dirk');
 printxy(54,104,'Add Reflective Hull');
 printxy(177,84,'Add Component');
 printxy(179,104,'Add Material');
 mouseshow;
 c:=0;
 set256colors(colors);
 repeat
  for i:=200 to 215 do
   colors[i]:=colors[random(22)];
  for i:=216 to 231 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 2);
  done:=mouse.getstatus;
  if (c=0) and (mouse.y>145) and (mouse.y<161) and (mouse.x>79) and (mouse.x<241) then
   begin
    c:=1;
    mousehide;
    plainfadearea(80,146,240,160,3);
    mouseshow;
   end
  else if (c=1) and ((mouse.y<146) or (mouse.y>160) or (mouse.x<80) or (mouse.x>240)) then
   begin
    c:=0;
    mousehide;
    plainfadearea(80,146,240,160,-3);
    mouseshow;
   end;
  if done then
   case mouse.x of
     56..156: case mouse.y of
                 80..95: if incargo(ID_DIRK)<5 then addcargo2(ID_DIRK, true);
               100..115: if incargo(ID_REFLECTIVEHULL)<5 then addcargo2(ID_REFLECTIVEHULL, true);
              end;
    163..263: case mouse.y of
                 80..95: if incargo(ID_UNKNOWN_COMPONENT)<16 then addcargo2(ID_UNKNOWN_COMPONENT, true);
               100..115: if incargo(ID_UNKNOWN_MATERIAL)<16 then addcargo2(ID_UNKNOWN_MATERIAL, true);
              end;
   end;
  if fastkeypressed then readkey;
  for i:=216 to 231 do
   colors[i]:=colors[random(16)];
  for i:=200 to 215 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 2+7);
 until (done) and (c=1);
 fading;
 mousehide;
 loadscreen(tempdir+'/current2',@screen);
 set256colors(colors);
 bkcolor:=0;
 mouseshow;
end;

(* NO SPACE!!!
procedure easteregg6;
begin
 while fastkeypressed do readkey;
 fading;
 mousehide;
 loadscreen('data/intro3',@screen);
 soundeffect('explode3.sam',9500);
 fadein;
 mouseshow;
 repeat
  if mouse.getstatus then soundeffect('explode3.sam',9500);
 until fastkeypressed;
 stopmod;
 fading;
 closegraph;
 halt(3);
end;*)
{$ENDIF}

procedure bossmode;
{type
 texttype= array[0..24,0..79] of integer;}
var
{ textscreen: texttype absolute $B800:0000;
 f: file of texttype;
 s: string[13];}
 temppal: paltype;
begin
{ mousehide;
 compressfile(tempdir+'/current3',@screen);
 //textmode(co80);
 case random(2) of
  0: begin
      s:='boss1.dta';
      gotoxy(2,3);
     end;
  1: begin
      s:='boss2.dta';
      gotoxy(10,25);
     end;
 end;
 assign(f,'data/'+s);
 reset(f);
 if ioresult<>0 then errorhandler('data/boss1.dta',1);
 read(f,textscreen);
 if ioresult<>0 then errorhandler('data/boss1.dta',5);
 close(f);}
 pausemod;
 temppal[0,1]:=0;		// to turn off warnings, variables are actually correctly initialized by function below
 fillchar(temppal,sizeof(paltype),0);
 set256colors(temppal);
 repeat until (fastkeypressed) or (mouse.getstatus);
 while fastkeypressed do readkey;
{ setgraphmode(0);
 asm
  mov ax, 0013h
  int 10h
 end; }
 set256colors(colors);
 continuemod;
{ loadscreen(tempdir+'/current3',@screen);
 mouseshow;}
end;

procedure savepal;
var f: file of paltype;
begin
 assign(f,tempdir+'/current.pal');
 rewrite(f);
 if ioresult<>0 then errorhandler(tempdir+'/current.pal',1);
 write(f,colors);
 if ioresult<>0 then errorhandler(tempdir+'/current.pal',5);
 close(f);
end;

(*
procedure loopscale(startx,starty,sizex,sizey,newx,newy: word; var s,t);
var sety, py, pdy, px, pdx, dcx, dcy, ofsy: word;
begin
// asm
//  push ds
//  push es
//  les si, [s]         { es: si is our source location }
//  mov [ofsy], si
//  lds di, [t]
//  imul di, [starty], 320
//  mov [sety], di
//  add di, [startx]
//
//  mov ax, [sizex]
//  xor dx, dx
//  mov cx, [newx]
//  div cx
//  mov [px], ax
//  mov [pdx], dx       { set up py and pdy }
//
//  mov ax, [sizey]
//  xor dx, dx
//  mov cx, [newy]
//  div cx
//  mov [py], ax
//  mov [pdy], dx       { set up py and pdy }
//
//  xor cx, cx
//  mov [dcx], cx
//  mov [dcy], cx
//
//  mov dx, [sizey]
//
//@@iloop:
//  add cx, [py]
//
//  mov ax, [pdy]
//  add [dcy], ax
//  mov ax, [newy]
//  cmp ax, [dcy]
//  jg @@nodcychange
//
//  inc cx
//  sub [dcy], ax
//
 //@@nodcychange:
//
//  cmp cx, [sizey]
//  jb @@noloopy
//  xor cx, cx
//
 //@@noloopy:
//
//  imul si, cx, 320
//  add si, [ofsy]
//
//  mov bx, [sizex]
//
//  mov [dcx], 0
//
 //@@jloop:
// add si, [px]
//
//  mov ax, [pdx]
//  add [dcx], ax
//  mov ax, [newx]
//  cmp ax, [dcx]
//  jg @@nodcxchange
//
//  inc si
//  sub [dcx], ax
//
 //@@nodcxchange:
//
//  mov al, [es: si]
//  mov [ds: di], al     { finally draw it! }
//
//  inc di
//  dec bx
//  jnz @@jloop
//
//  add [sety], 320
//  mov di, [sety]
//  add di, [startx]
//
//  dec dx
//  jnz @@iloop
//
//  pop es
//  pop ds
 //end;
end;

procedure scale(startx,starty,sizex,sizey,newx,newy: integer; var s,t);
var sety, py, pdy, px, pdx, dcx, dcy, ofsy: integer;
begin
// asm
//  push ds
//  push es
//  les si, [s]         { es: si is our source location }
//  mov [ofsy], si
//  lds di, [t]         { ds: di is our destination }
//  imul di, [starty], 320
//  mov [sety], di
//
//  add di, [startx]
//
//  mov ax, [sizex]
//  xor dx, dx
//  mov cx, [newx]
//  div cx
//  mov [px], ax
//  mov [pdx], dx       { set up py and pdy }
//
//  mov ax, [sizey]
//  xor dx, dx
//  mov cx, [newy]
//  div cx
//  mov [py], ax
//  mov [pdy], dx       { set up py and pdy }
//
//  xor cx, cx
//  mov [dcx], cx
//  mov [dcy], cx
//  mov dx, [newy]
//
 // @@iloop:
// add cx, [py]

//  mov ax, [pdy]
//  add [dcy], ax
//  mov ax, [dcy]
//
//  cmp ax, [newy]
//  jl @@nodcychange
//  inc cx
//  sub ax, [newy]
 // mov [dcy], ax

// @@nodcychange:

//  imul si, cx, 320
//  add si, [ofsy]

//  mov bx, [newx]

//  mov [dcx], 0

 //@@jloop:
//  add si, [px]

//  mov ax, [pdx]
//  add [dcx], ax
//  mov ax, [dcx]
//  cmp ax, [newx]
//  jl @@nodcxchange
//
//  inc si
//  sub ax, [newx]
//  mov [dcx], ax
//
// @@nodcxchange:

//  mov al, [es: si]
//  mov [ds: di], al     { finally draw it! }

//  inc di
//  dec bx
//  jnz @@jloop

//  add [sety], 320
//  mov di, [sety]
//  add di, [startx]

//  dec dx
//  jnz @@iloop

//  pop es
//  pop ds
// end;
end;
*)

procedure screensaver;
{var s,s2: pscreentype;
    i,j,a,max: integer;
    temp: byte;
    partx,party: real;
    debug: string[6];
    quit: boolean;}
begin
{ if (ship.options[OPT_SCREENSAVER]=0) or (memavail<74000) or (ship.options[OPT_ANIMATION]=0) then exit;
 mousehide;
 compressfile(tempdir+'/current3',@screen);
 if memavail<140000 then i:=random(2) else i:=random(3);
 new(s);
 savepal;
 quit:=false;
 if i=0 then
  begin
   scrfrom_move(screen,s^,sizeof(screen));
   max:=60;
   repeat
    for a:=5 to max do
     begin
      partx:=320/max*a;
      party:=200/max*a;
      loopscale(0,0,320,200,round(partx),round(party),s^,screen);
      if (fastkeypressed) or (mouse.getstatus) then
       begin
        a:=max;
        quit:=true;
       end;
     end;
    if not quit then
     for a:=max downto 4 do
      begin
       partx:=320/max*a;
       party:=200/max*a;
       loopscale(0,0,320,200,round(partx),round(party),s^,screen);
       if (fastkeypressed) or (mouse.getstatus) then
        begin
         a:=4;
         quit:=true;
        end;
      end;
   until quit;
  end
 else if i=1 then
  begin
   scrfrom_move(screen,s^,sizeof(screen));
   max:=60;
   for i:=0 to 199 do
    for j:=0 to 319 do
     if i mod 2=0 then backgr^[i,j]:=random(32)+32
      else backgr^[i,j]:=random(32)+64;
   fillchar(colors[32],672,0);
   setcolor(0);
   for a:=max downto 1 do
    begin
     partx:=320/max*a;
     party:=200/max*a;
     scale(160-(round(partx) shr 1),100-(round(party) shr 1),320,200,round(partx),round(party),s^,screen);
     rectangle(160-(round(partx) shr 1),100-(round(party) shr 1),
      160+(round(partx) shr 1),100+(round(party) shr 1));
     delay(5);
     if (fastkeypressed) or (mouse.getstatus) then
      begin
       a:=1;
       quit:=true;
      end;
    end;
   if not quit then
    begin
     scrto_move(backgr^,screen,sizeof(screen));
     repeat
      for i:=32 to 63 do
       colors[i]:=colors[random(32)];
      fillchar(colors[64],96,0);
      set256colors(colors);
      delay(5);
      for i:=64 to 95 do
       colors[i]:=colors[random(32)];
      fillchar(colors[32],96,0);
      set256colors(colors);
      if (fastkeypressed) or (mouse.getstatus) then quit:=true;
     until quit;
    end;
  end
 else if i=2 then
  begin
   new(s2);
   loadscreen('data/saver',s2);
   scr_fillchar(screen,sizeof(screen),0);
   set256colors(colors);
   for i:=0 to 199 do
    for j:=0 to 319 do
     s^[i,j]:=random(85)+95;
   repeat
    fillchar(s^[199],320,40);
    for j:=0 to 319 do
     s^[198,j]:=random(200);
    for j:=50 to 269 do
     s^[199,j]:=random(160)+50;
    ASM
      mov   cx, 64000
      mov   bx, 320
      les   di, [s]
      mov   si, di
      add   di, bx
      mov   ah, 12
      mov   [temp], ah
      xor   ah, ah
  @@1:
      mov   dl, [es:di-1]
      mov   al, [es:di]
      add   dx, ax
      mov   al, [es:di+1]
      add   dx, ax
      mov   al, [es:di+bx]
      add   dx, ax
      shr   dx, 2
      jz    @@3
      dec   [temp]
      jz    @@2
      jmp   @@3
  @@2:
      mov   al, 12
      mov   [temp], al
      dec   dl
  @@3:
      mov   [byte ptr es:si], dl
      inc   di
      inc   si
      dec   cx
      jnz   @@1
    END;
    if (fastkeypressed) or (mouse.getstatus) then quit:=true;
    if not quit then
     begin
      move(s^,backgr^,sizeof(screen));
      asm
       push es
       push ds
       les si, [s2]
       lds di, [backgr]
       mov si, 64000
    @@loopit4:
       cmp di, [es: si]
       je @@blackspot4
       mov al, [es: si]
       add [ds: si], al
    @@blackspot4:
       dec si
       jnz @@loopit4
       pop ds
       pop es
      end;
      if (fastkeypressed) or (mouse.getstatus) then quit:=true;
      if not quit then scrto_move(backgr^[1],screen,15600*4);
     end;
   until quit;
   dispose(s2);
  end;
 while fastkeypressed do readkey;
 dispose(s);
 fading;
 loadscreen('data/cloud',backgr);
 if showplanet then
  begin
   if ((tempplan^[curplan].state=6) and (tempplan^[curplan].mode=2)) then makeastoroidfield
    else if (tempplan^[curplan].state=0) and (tempplan^[curplan].mode=1) then makecloud;
  end;
 loadscreen(tempdir+'/current3',@screen);
 fadein;
 mouseshow;
}
idletime:=0;
end;


procedure deathsequence(n: integer);
begin
 assert (n<2); { just to ignore warning, variable really not used }
 stopmod;
 blast(63,0,0);
 closegraph;
 halt(3);
end;

procedure lifesupportfailure;
var j: integer;
begin
 showchar(6,'Life support damage, backup encodes corrupted!');
 for j:=1 to 6 do
  begin
   ship.encodes[j].men:=0;
   ship.encodes[j].phy:=0;
   ship.encodes[j].emo:=0;
  end;
end;

begin
end.
