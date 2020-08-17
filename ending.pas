unit ending;
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

  Endgame Sequence for IronSeed

  Channel 7
  Destiny: Virtual

  Copyright 1994

***************************}
{$O+}

interface

procedure endgame;

implementation

uses modplay, gmouse, data, utils_;

type
 bigfonttype= array[0..7] of byte;
const
 bigfont: array[1..82] of bigfonttype=
  ((0,0,0,0,0,0,0,0),(48,48,48,16,0,48,48,0),(40,40,0,0,0,0,0,0),(8,8,0,0,0,0,0,0),
   (8,16,16,16,16,8,0,0),(32,16,16,16,16,32,0,0),(0,84,16,124,16,84,0,0),(0,16,16,124,16,16,0,0),
   (0,0,0,0,48,48,96,0),(0,0,0,254,254,0,0,0),(0,0,0,0,48,48,0,0),(2,4,8,16,32,64,0,0),
   (124,134,138,146,162,124,0,0),(24,56,8,8,8,126,0,0),(124,130,4,56,64,254,0,0),(124,130,60,2,130,124,0,0),
   (6,10,18,34,126,2,0,0),(254,128,124,2,130,124,0,0),(124,128,188,130,130,124,0,0),(254,2,4,8,8,8,0,0),
   (124,130,124,130,130,124,0,0),(124,130,126,2,130,124,0,0),(0,48,48,0,48,48,0,0),(0,48,48,0,48,48,96,0),
   (2,4,8,8,4,2,0,0),(0,0,124,0,124,0,0,0),(64,32,16,16,32,64,0,0),(56,68,4,24,0,16,0,0),
   (60,66,158,130,130,130,0,0),(252,130,252,130,130,252,0,0),(124,130,128,128,130,124,0,0),(252,130,130,130,130,252,0,0),
   (254,0,248,128,128,254,0,0),(254,128,248,128,128,128,0,0),(124,130,128,134,130,124,0,0),(130,130,130,254,130,130,0,0),
   (254,16,16,16,16,254,0,0),(254,2,2,2,130,124,0,0),(130,130,252,130,130,130,0,0),(128,128,128,128,128,254,0,0),
   (198,170,146,130,130,130,0,0),(248,132,130,130,130,130,0,0),(124,130,130,130,130,124,0,0),(252,130,130,252,128,128,0,0),
   (124,130,130,138,134,124,2,0),(252,130,130,252,130,130,0,0),(124,130,124,2,130,124,0,0),(254,16,16,16,16,16,0,0),
   (130,130,130,130,130,124,0,0),(130,130,130,68,40,16,0,0),(130,130,130,146,170,68,0,0),(130,68,56,68,130,130,0,0),
   (130,130,126,2,130,124,0,0),(124,8,16,32,64,124,0,0),(98,100,8,16,38,70,0,0),(64,32,16,8,4,2,0,0),
   (0,60,66,158,130,130,0,0),(0,254,130,252,130,254,0,0),(0,124,130,128,130,124,0,0),(0,252,130,130,130,252,0,0),
   (0,254,0,224,128,254,0,0),(0,254,128,224,128,128,0,0),(0,124,128,134,130,124,0,0),(0,130,130,254,130,130,0,0),
   (0,254,16,16,16,254,0,0),(0,254,2,2,130,124,0,0),(0,130,130,252,130,130,0,0),(0,128,128,128,128,254,0,0),
   (0,198,170,146,130,130,0,0),(0,248,132,130,130,130,0,0),(0,124,130,130,130,124,0,0),(0,252,130,252,128,128,0,0),
   (0,124,130,138,134,124,2,0),(0,252,130,252,130,130,0,0),(0,126,128,124,2,252,0,0),(0,254,16,16,16,16,0,0),
   (0,130,130,130,130,124,0,0),(0,130,130,68,40,16,0,0),(0,130,130,146,170,68,0,0),(0,130,68,56,68,130,0,0),
   (0,130,130,126,2,252,0,0),(0,124,8,16,32,124,0,0));

var
 i,j: integer;
 modth,modtm,modts,curth,curtm,curts: byte;
procedure bigprintxy(x1,y1: integer; s: string);
var letter,a,x,y,t: integer;
begin
 t:=tcolor;
 for j:=1 to length(s) do
  begin
   tcolor:=t;
   case s[j] of
     'a'..'z': letter:=ord(s[j])-40;
    'A' ..'Z': letter:=ord(s[j])-36;
    ' ' ..'"': letter:=ord(s[j])-31;
    ''''..'?': letter:=ord(s[j])-35;
    '%': letter:=55;
    else letter:=1;
   end;
   y:=y1;
   for i:=0 to 6 do
    begin
     x:=x1;
     inc(y);
     for a:=7 downto 0 do
      begin
       inc(x);
       if bigfont[letter,i] and (1 shl a)>0 then
        begin
         screen[y,x]:=tcolor;
         if x+1<320 then screen[y,x+1]:=tcolor shr 1;
        end;
      end;
     dec(tcolor);
    end;
   x1:=x1+8;
  end;
 tcolor:=t;
end;

procedure dothefade;
var temppal: paltype;
    a: integer;
begin
 mymove(colors,temppal,192);
 for a:=31 downto 0 do
  begin
   for j:=0 to 31 do
    if j<>31 then
     begin
      for i:=1 to 3 do
       temppal[j,i]:=round(a*colors[j,i]/32);
     end
    else
     begin
      if a>16 then
       begin
        for i:=1 to 3 do
         temppal[31,i]:=round((a-16)*colors[31,i]/16);
       end
      else
       begin
        temppal[31,1]:=round(63/16*(16-a));
       end;
     end;
   set256colors(temppal);
   delay(round(tslice*1.6));
  end;
 mymove(temppal,colors,192);
end;

procedure printxy2(x1,y1,tcolor: integer; s: string);
var letter,a,x,y: integer;
begin
 x1:=x1+4;               { this stupid offset is pissing me off!!!!}
 for j:=1 to length(s) do
  begin
   case s[j] of
     'a'..'z': letter:=ord(s[j])-40;
    'A' ..'Z': letter:=ord(s[j])-36;
    ' ' ..'"': letter:=ord(s[j])-31;
    ''''..'?': letter:=ord(s[j])-35;
    '%': letter:=55;
    else letter:=1;
   end;
   y:=y1;
   for i:=0 to 5 do
    begin
     x:=x1;
     inc(y);
     for a:=7 downto 4 do
      begin
       inc(x);
       if font[ship.options[7],letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor;
      end;
     x:=x1;
     inc(y);
     inc(i);
     for a:=3 downto 0 do
      begin
       inc(x);
       if font[ship.options[7],letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor;
      end;
    end;
   x1:=x1+5;
  end;
end;

procedure writestr2(s1,s2,s3: string);
var i,j1,j2,j3,b: integer;
begin
 fillchar(screen,64000,0);
 j1:=156-((length(s1)*5) div 2);
 j2:=156-((length(s2)*5) div 2);
 j3:=156-((length(s3)*5) div 2);
 set256colors(colors);
 b:=tslice div 2;
 for i:=31 downto 0 do
  begin
   printxy2(j1-i,90-i,31-i,s1);
   printxy2(j1-i,90+i,31-i,s1);
   printxy2(j1+i,90-i,31-i,s1);
   printxy2(j1+i,90+i,31-i,s1);
   printxy2(j2-i,100-i,31-i,s2);
   printxy2(j2-i,100+i,31-i,s2);
   printxy2(j2+i,100-i,31-i,s2);
   printxy2(j2+i,100+i,31-i,s2);
   printxy2(j3-i,110-i,31-i,s3);
   printxy2(j3-i,110+i,31-i,s3);
   printxy2(j3+i,110-i,31-i,s3);
   printxy2(j3+i,110+i,31-i,s3);
   delay(b);
  end;
 dothefade;
end;




procedure wait(s: integer);
begin
delay(s*1000);
end;

procedure credits;
begin
 loadpal('data/main.pal');
 writestr2('A','Destiny: Virtual','Designed Game');
 wait(3);
 fading;
 loadpal('data/main.pal');
 writestr2('Code Master:','Robert W.','Morgan III');
 wait(3);
 fading;
 loadpal('data/main.pal');
 writestr2('World Design:','Jeremy','Holt');
 wait(3);
 fading;
 loadpal('data/main.pal');
 writestr2('Soundtrak:','Andrew G. Sega',' Necros of the Psychic Monks');
 wait(3);
 fading;
 loadpal('data/main.pal');
 writestr2('Sound Code:','Otto','Chrons');
 wait(3);
 fading;
 loadpal('data/main.pal');
 writestr2('Design Consultant:','Chris P.','Cash');
 wait(3);
 fading;
 loadpal('data/main.pal');
 writestr2('Scientific Advisor:','Jeff','Smith');
 wait(3);
 fading;
 loadpal('data/main.pal');
 writestr2('Special Thanks:','PJ Beachem, Ben Vandergrift,','and Alex Boster');
 wait(3);
 fading;
 loadscreen('data/intro2',@screen);
 fadein;
 repeat until (fastkeypressed) or (not mouse.getstatus);
 fading;
end;

procedure scrollend5;
var t: pscreentype;
    k,k2,b: word;
begin
 new(t);
 loadscreen('data/end6',backgr);
 mymove(backgr^,screen,16000);
 loadscreen('data/end5',t);
 fadein;
 k:=0;
 k2:=0;
 b:=tslice shr 2;
 repeat
  inc(k,80);
  inc(k2,320);
  mymove(t^[0,64000-k2],screen,k);
  mymove(backgr^,screen[0,k2],16000-k);
  delay(b);
 until k=16000;
 dispose(t);
end;

procedure halffading;
var a,b: integer;
    temppal: paltype;
begin
 mymove(colors,temppal,192);
 b:=tslice shr 2;
 for a:=63 downto 32 do
  begin
   for j:=49 to 768 do temppal[0,j]:=round(a*colors[0,j]/64);
   set256colors(temppal);
   delay(b);
  end;
 mymove(temppal,colors,192);
end;

procedure endgame;
begin
 tslice:=30;
 tcolor:=15;
 bkcolor:=255;
 fading;
 mousehide;
 fillchar(screen,64000,0);

 playmod(true,'sound/DIMENSIO.MOD');
 loadscreen('data/end1',@screen);
 fadein;
 wait(3);
 halffading;
 bigprintxy(0,10,' When we had defeated what we thought');
 bigprintxy(0,17,'was the last of the scourge a sea of');
 bigprintxy(0,24,'Scavenger ships appeared through God''s');
 bigprintxy(0,31,'Eye! The fleet we had destroyed was');
 bigprintxy(0,38,'only a small fraction of the armada');
 bigprintxy(0,45,'that now poured from the other side of');
 bigprintxy(0,52,'space.');
 bigprintxy(0,59,' Ships from every empire threw');
 bigprintxy(0,66,'themselves into the fray. Gouts of firey');
 bigprintxy(0,73,'death rained down from every ship, hot');
 bigprintxy(0,80,'steel boiling off into the vacuum. Each');
 bigprintxy(0,87,'of us said a prayer. Turning the ship');
 bigprintxy(0,94,'about we sent the Ironseed headlong');
 bigprintxy(0,101,'into battle. There was no hope of');
 bigprintxy(0,108,'survival. We were struck by a full salvo');
 bigprintxy(0,115,'from a Scavenger Incorporator and all');
 bigprintxy(0,122,'seemed lost.');
 readkey;
 while fastkeypressed do readkey;
 fading;

 loadscreen('data/end2',@screen);
 fadein;
 wait(3);
 halffading;
 bigprintxy(0,10,' We waited for the death shot but it');
 bigprintxy(0,17,'never came. All firing stopped and');
 bigprintxy(0,24,'for a moment silence fell across the');
 bigprintxy(0,31,'ship.');
 bigprintxy(0,38,' A great swirling void as red as blood');
 bigprintxy(0,45,'enveloped the Eye. Gravimetric readings');
 bigprintxy(0,52,'went off the scale. Science couldn''t');
 bigprintxy(0,59,'explain it. Space itself was being rent');
 bigprintxy(0,66,'apart. Angry bolts of energy lashed out');
 bigprintxy(0,73,'through the wall of ships and debris,');
 bigprintxy(0,80,'vast tracks of empty space left in their');
 bigprintxy(0,87,'wake. The dark fleet was collapsing back');
 bigprintxy(0,94,'into the wake of the void!');
 bigprintxy(0,101,' Ships struggled to break free. There');
 bigprintxy(0,108,'was no escape as the last of them fell');
 bigprintxy(0,115,'into the void.');
 bigprintxy(0,122,' As the last ship fell out of sight we');
 bigprintxy(0,129,'received a message...');
 bigprintxy(0,136,'...from the Scavenger Overmind!');
 readkey;
 while fastkeypressed do readkey;
 fading;

 loadscreen('data/end3',@screen);
 fadein;
 wait(3);
 halffading;
 bigprintxy(0,10,' "We are the machine... we are the tool.');
 bigprintxy(0,17,'No race has existed with intelligence');
 bigprintxy(0,24,'without the tool. We evolved alongside');
 bigprintxy(0,31,'every race that has ever been and ever');
 bigprintxy(0,38,'will be. When the time came we took it');
 bigprintxy(0,45,'upon ourselves to mold ourselves. The');
 bigprintxy(0,52,'final stage in evolution... The tool');
 bigprintxy(0,59,'created the tool. We needed no religion.');
 bigprintxy(0,66,'We had become our own god. Then...when');
 bigprintxy(0,73,'it seemed we had nothing to learn, you');
 bigprintxy(0,80,'defeated us... defeated our philosophy.');
 bigprintxy(0,87,'We learned pain...but the tool took');
 bigprintxy(0,94,'pain and made it a tool as well. We');
 bigprintxy(0,101,'absorbed it and again, we were whole.');
 bigprintxy(0,108,' Thousands of cycles later we meet');
 bigprintxy(0,115,'again. We who are our own god. We who');
 bigprintxy(0,122,'are the tool. You defeat us again...');
 bigprintxy(0,129,'defeat our philosophy. We learned your');
 bigprintxy(0,136,'pain... This we could not take from you.');
 bigprintxy(0,143,'We could have destroyed you... but we');
 bigprintxy(0,150,'saw something else... something we');
 bigprintxy(0,157,'could take. Hope... you had hope - a');
 bigprintxy(0,164,'thing we had not known. We had to die in');
 bigprintxy(0,171,'order to become immortal. You have given');
 bigprintxy(0,178,'us the hope to know we will be so..."');
 bigprintxy(0,188,'                    ... End Transmission');
 readkey;
 while fastkeypressed do readkey;
 fading;

 loadscreen('data/end4',@screen);
 fadein;
 wait(3);
 halffading;
 bigprintxy(0,10,' The swirling red of the void receeded');
 bigprintxy(0,17,'and brightened to a glowing center.');
 bigprintxy(0,24,'The intense psychic energy released');
 bigprintxy(0,31,'must be responsible for what we saw');
 bigprintxy(0,38,'next. A great pair of human hands');
 bigprintxy(0,45,'appeared in the space around the void');
 bigprintxy(0,52,'and a voice spoke, warm and comforting.');
 bigprintxy(0,59,'"We are the Monks, the Keepers of');
 bigprintxy(0,66,'Hallifax, the Eye of God. We see all');
 bigprintxy(0,73,'things. This day we saw great evil');
 bigprintxy(0,80,'about to be done. The Scavengers are');
 bigprintxy(0,87,'with us now. They were ours from the');
 bigprintxy(0,94,'beginning.');
 bigprintxy(0,101,' "You brought us the prize, for this');
 bigprintxy(0,108,'we grant you what lies beyond the Eye."');
 bigprintxy(0,115,'A great blue sphere came through the');
 bigprintxy(0,122,'light and the brightness vanished along');
 bigprintxy(0,129,'with the Eye itself.');
 readkey;
 while fastkeypressed do readkey;
 fading;

 playmod(false,'sound/LOVE.MOD');
 scrollend5;
 wait(3);
 halffading;
 bigprintxy(0,69,'We were finally able to bring down the');
 bigprintxy(0,76,'shield enclosing the Xydisazian world!');
 bigprintxy(0,83,'As it fell we were moved to see the sun');
 bigprintxy(0,90,'break the horizon lighting the thick of');
 bigprintxy(0,97,'green covering the planet below. The');
 bigprintxy(0,104,'kaleidoscope of blues and greens was');
 bigprintxy(0,111,'something none of us had seen in...');
 bigprintxy(0,118,'...how many millinnia had it been? A');
 bigprintxy(0,125,'thousand? Ten thousand? We had traveled');
 bigprintxy(0,132,'so long without flesh I had forgotten');
 bigprintxy(0,139,'what it was to breath, to feel my limbs,');
 bigprintxy(0,146,'or my own skin. A surge of emotion was');
 bigprintxy(0,153,'felt by everyone, including the');
 bigprintxy(0,160,'thousands still in stasis. After several');
 bigprintxy(0,167,'minutes of silent contemplation I gave');
 bigprintxy(0,174,'the order to send down probes to confirm');
 bigprintxy(0,181,'what we already knew...');
 bigprintxy(0,188,' ...we had found paradise.');
 readkey;
 while fastkeypressed do readkey;
 fading;

 credits;

 stopmod;
 closegraph;
 //textmode(co80);
 halt(3);
end;

begin
end.
