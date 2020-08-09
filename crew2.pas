unit crew2;

{***************************
   Crew Manipulation unit 2 for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

{$O+}

interface

procedure psyche;

implementation

uses crt, utils_, gmouse, data, utils, utils2, weird, saveload, modplay, crewtick, heapchk;

const
 jobs: array[1..6] of string[13] = ('Psychometry','Engineering','  Science  ',' Security ','Astrogation','  Medical  ');
 maxbubbles=50;
type
 bubblearray= array[0..maxbubbles,1..2] of integer;
var
 psychemode,graphindex,a,crewindex,r,g,b,i,j: integer;
 bubbles: ^bubblearray;

procedure showportrait(n: integer);
var s: string[2];
    portrait: ^portraittype;
begin
 new(portrait);
 str(n:2,s);
 if n<10 then s[1]:='0';
 loadscreen('data/image'+s+'',portrait);
 for i:=0 to 69 do
  move(portrait^[i],screen[i+110,210],70);
 dispose(portrait);
end;

procedure erasebubbles;
begin
 mousehide;
 for i:=0 to maxbubbles do
  if bubbles^[i,1]<>0 then inc(screen[bubbles^[i,1],bubbles^[i,2]],3);
 fillchar(bubbles^,sizeof(bubblearray),0);
 mouseshow;
end;

procedure movebubbles;
begin
 mousehide;
 for i:=0 to maxbubbles do
  begin
   if bubbles^[i,1]<>0 then inc(screen[bubbles^[i,1],bubbles^[i,2]],3);
   if random(90)=0 then
    begin
     bubbles^[i,1]:=159+random(6);
     bubbles^[i,2]:=45+random(32);
    end
   else
    begin
     dec(bubbles^[i,1]);
     if (random(2)=0) and (bubbles^[i,2]<76) then inc(bubbles^[i,2])
      else if (bubbles^[i,2]>45) then dec(bubbles^[i,2]);
     if bubbles^[i,1]<=85 then
      begin
       bubbles^[i,1]:=129+random(36);
       bubbles^[i,2]:=45+random(32);
      end;
    end;
   dec(screen[bubbles^[i,1],bubbles^[i,2]],3);
  end;
 mouseshow;
end;

procedure newbubbles;
begin
 fillchar(bubbles^,sizeof(bubblearray),0);
 movebubbles;
end;

procedure gradientbar(x, y, w, h, c, cr, b, l :Integer);
var
   m	  : Integer;
   xx, yy : Integer;
   cc	  : Integer;
begin
   m := b * w div l;
   m := max2(0, min2(m, w));
   if m > 0 then
      for xx := 0 to m - 1 do
      begin
	 if m > 1 then
	    cc := c + xx * cr div (m - 1)
	 else
	    cc := c + cr;
	 for yy := 0 to h - 1 do
	 begin
	    screen[y + yy, x + xx] := cc;
	 end;
      end;
   if m < w then
      for xx := m to w - 1 do
	 for yy := 0 to h - 1 do
	    screen[y + yy, x + xx] := 0;
end;

procedure drawgraphs;
var
   iski, iper, isan : Integer;
   rski, rper, rsan : Integer;
   i		    : Integer;
{   stmp		    : String[8];}
begin
   randseed:=crewindex*crewindex*crewindex;
   
   iski:=ComputeSkill(crewindex);
   rski:=ship.crew[crewindex].skill;
   iski:=max2(min2(99,iski),1);
   rski:=max2(min2(99,rski),1);
   gradientbar(179, 20, 241 - 179 + 1, 2, 137, 22, iski, 99);
   gradientbar(179, 22, 241 - 179 + 1, 1, 105, 22, rski, 99);
   
   iper:=ComputePerformance(crewindex);
   rper:=ship.crew[crewindex].perf;
   iper:=max2(min2(99,iper),1);
   rper:=max2(min2(99,rper),1);
   gradientbar(179, 28, 241 - 179 + 1, 2, 137, 22, iper, 99);
   gradientbar(179, 30, 241 - 179 + 1, 1, 105, 22, rper, 99);

   isan:=ComputeSanity(crewindex);
   rsan:=ship.crew[crewindex].san;
   isan:=max2(min2(99,isan),1);
   rsan:=max2(min2(99,rsan),1);
   gradientbar(179, 36, 241 - 179 + 1, 2, 137, 22, isan, 99);
   gradientbar(179, 38, 241 - 179 + 1, 1, 105, 22, rsan, 99);
   
   for i:=96 to 127 do
   begin
      colors[i,1]:=(rski * ((i - 96) * 2 + 1) div 99);
      colors[i,2]:=(rper * ((i - 96) * 2 + 1) div 99);
      colors[i,3]:=(rsan * ((i - 96) * 2 + 1) div 99);
   end;
   {for i:=128 to 159 do
   begin
      colors[i,1]:=(iski * ((i - 128) * 2 + 1) div 99);
      colors[i,2]:=(iper * ((i - 128) * 2 + 1) div 99);
      colors[i,3]:=(isan * ((i - 128) * 2 + 1) div 99);
   end;}
   {str(ship.crew[crewindex].status, stmp);
   printxy(160, 194, stmp);}
end;

procedure displayblips;
begin
 for j:=1 to 3 do
  begin
   if crewindex=j then a:=63 else a:=104;
   screen[j*4+159,289]:=a;
   screen[j*4+159,290]:=a;
  end;
 for j:=4 to 6 do
  begin
   if crewindex=j then a:=63 else a:=104;
   screen[j*4+147,294]:=a;
   screen[j*4+147,295]:=a;
  end;
end;

procedure drawprimarystats(num : integer);
var
   a,b,c,d,y,i : integer;
   part,col,cs : real;
begin
   a:=ship.crew[num].phy;
   b:=ship.crew[num].men;
   c:=ship.crew[num].emo;
   d:=ship.crew[num].status;
   part:=34/100;
   for y:=111 to 145 do
      fillchar(screen[y,297],7,0);
   col := 95;
   if a > 0 then cs := 23/(part*a) else cs := 1;
   for y := 145-round(part*a) to 145 do
   begin
      screen[y, 297] := round(col);
      col := col - cs;
   end;
   col := 63;
   if b > 0 then cs := 14/(part*b) else cs := 1;
   for y := 145-round(part*b) to 145 do
   begin
      screen[y, 299] := round(col);
      col := col - cs;
   end;
   col := 207;
   if c > 0 then cs := 14/(part*c) else cs := 1;
   for y := 145-round(part*c) to 145 do
   begin
      screen[y, 301] := round(col);
      col := col - cs;
   end;
   col := 31;
   if d > 0 then cs := 23/(part*d) else cs := 1;
   for y := 145-round(part*d) to 145 do
   begin
      screen[y, 303] := round(col);
      col := col - cs;
   end;
end; { drawprimarystats }

procedure redraw1;
var s: string[20];
begin
 mousehide;
 showportrait(ship.crew[crewindex].index);
 for i:=81 to 88 do
  fillchar(screen[i,210],71,0);
 printxy(241-round(length(jobs[crewindex])*2.5),81,jobs[crewindex]);
 drawgraphs;
 with ship.crew[crewindex] do
  begin
   s:=ship.crew[crewindex].name;
   if (index=18) or (index=25) or (index=26) then
    i:=6 else i:=1;
  end;
 j:=i;
 while s[j]<>' ' do inc(j);
 s:=copy(s,i,j-i);
 tcolor:=95;
 bkcolor:=255;
 printxy(241-round(length(s)*2.5),111,s);
 tcolor:=191;
 bkcolor:=0;
 displayblips;
   drawprimarystats(crewindex);
 mouseshow;
end;

procedure drawstats(num: integer);
var b,c,d,y,ylast: integer;
    part: real;
begin {120,37,294,112}
 a:=ship.crew[num].phy;
 b:=ship.crew[num].men;
 c:=ship.crew[num].emo;
 {d:=ship.crew[num].status;}
 ylast:=50;
 part:=34/100;
 {for i:=111 to 145 do
  fillchar(screen[i,299],3,0);
 for j:=299 to 301 do
  begin
   screen[145-round(part*a),j]:=95;
   screen[145-round(part*b),j]:=63;
   screen[145-round(part*c),j]:=207;
   screen[145-round(part*d),j]:=31;
  end;}
 moveto(145,145);
 for j:=145 to 285 do
  begin
   inc(j,2);
   if j>285 then exit;
   {setcolor((j-16) mod 32+128);}
    d:=random(6);
    case d of
     0:i:=round(a*part);
     1:i:=round(b*part);
     2:i:=round(c*part);
     3:i:=-round(a*part);
     4:i:=-round(b*part);
     5:i:=-round(c*part);
    end;
    lineto(j,i+145);
    ylast:=i+145;
  end;
end;

procedure redraw2;
begin
 mousehide;
 for i:=110 to 180 do
  fillchar(screen[i,145],141,0);
 for i:=81 to 88 do
  fillchar(screen[i,210],71,0);
 printxy(241-round(length(jobs[crewindex])*2.5),81,jobs[crewindex]);
 drawgraphs;
 displayblips;
   drawprimarystats(crewindex);
   drawstats(crewindex);
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

procedure closedisplay;
begin
 for i:=110 to 180 do
  fillchar(screen[i,145],141,0);
 for a:=60 downto 1 do
  begin
   for i:=99 to 190 do
    for j:=217-a downto 194-a do
     screen[i,j]:=screen[i,j-1];
   delay(tslice div 5);
  end;
 redraw1;
end;

procedure opendisplay;
begin
 for i:=110 to 180 do
  fillchar(screen[i,210],71,0);
 for a:=1 to 60 do
  begin
   for i:=99 to 190 do
    for j:=194-a to 217-a do
     screen[i,j]:=screen[i,j+1];
   delay(tslice div 5);
  end;
 redraw2;
end;

procedure drawcursor;
var c: integer;
begin
 if psychemode=0 then c:=63 else c:=95;
 mousehide;
 for i:=0 to 3 do
  screen[i+43,176]:=c;
 if psychemode=1 then c:=63 else c:=95;
 for i:=0 to 3 do
  screen[i+43,243]:=c;
 mouseshow;
end;

procedure altphy(alt: integer);
begin
   if alt=1 then
   begin
      if (ship.crew[crewindex].men<2) or (ship.crew[crewindex].emo=99)
	 or (ship.crew[crewindex].phy=99) then exit;
      dec(ship.crew[crewindex].men,2);
      inc(ship.crew[crewindex].phy);
      inc(ship.crew[crewindex].emo);
   end
   else
   begin
      if (ship.crew[crewindex].men>97) or (ship.crew[crewindex].emo=0)
	 or (ship.crew[crewindex].phy=0) then exit;
      inc(ship.crew[crewindex].men,2);
      if ship.crew[crewindex].phy>0 then dec(ship.crew[crewindex].phy);
      if ship.crew[crewindex].emo>0 then dec(ship.crew[crewindex].emo);
   end;
end;

procedure altmen(alt: integer);
begin
   if alt=1 then
   begin
      if (ship.crew[crewindex].emo<2) or (ship.crew[crewindex].phy=99)
	 or (ship.crew[crewindex].men=99) then exit;
      dec(ship.crew[crewindex].emo,2);
      inc(ship.crew[crewindex].phy);
      inc(ship.crew[crewindex].men);
   end
   else
   begin
      if (ship.crew[crewindex].emo>97) or (ship.crew[crewindex].phy=0)
	 or (ship.crew[crewindex].men=0) then exit;
      inc(ship.crew[crewindex].emo,2);
      if ship.crew[crewindex].phy>0 then dec(ship.crew[crewindex].phy);
      if ship.crew[crewindex].men>0 then dec(ship.crew[crewindex].men);
   end;
end;

procedure altemo(alt: integer);
begin
   if alt=1 then
   begin
      if (ship.crew[crewindex].phy<2) or (ship.crew[crewindex].emo=99)
	 or (ship.crew[crewindex].men=99) then exit;
      dec(ship.crew[crewindex].phy,2);
      inc(ship.crew[crewindex].emo);
      inc(ship.crew[crewindex].men);
   end
   else
   begin
      if (ship.crew[crewindex].phy>97) or (ship.crew[crewindex].emo=0)
	 or (ship.crew[crewindex].men=0) then exit;
      inc(ship.crew[crewindex].phy,2);
      if ship.crew[crewindex].emo>0 then dec(ship.crew[crewindex].emo);
      if ship.crew[crewindex].men>0 then dec(ship.crew[crewindex].men);
   end;
end;

procedure readydata;
begin
   oldt1:=t1;
   mousehide;
   compressfile(tempdir+'/current',@screen);
   {fading;}
   fadestopmod(-8, 20);
   playmod(true,'sound/PSYEVAL.MOD');
   loadscreen('data/psyche',@screen);
   new(bubbles);
   newbubbles;
   graphindex:=31;
   psychemode:=0;
   crewindex:=1;
   tcolor:=191;
   bkcolor:=0;
   drawcursor;
   adjustgraph;
   redraw1;
   {fadein;}
   mouseshow;
   done:=false;
end;

procedure processkey;
var ans: char;
begin
 ans:=upcase(readkey_utf8);
 case ans of
  #0: begin
       ans:=readkey;
       case ans of
        #72: begin
              erasebubbles;
              if crewindex=1 then crewindex:=6 else dec(crewindex);
              if psychemode=0 then redraw1 else redraw2;
              newbubbles;
             end;
        #80: begin
              erasebubbles;
              if crewindex=6 then crewindex:=1 else inc(crewindex);
              if psychemode=0 then redraw1 else redraw2;
              newbubbles;
             end;
       end;
      end;
  '1': if psychemode=1 then
        begin
         psychemode:=0;
         drawcursor;
         closedisplay;
         mousehide;
         for i:=111 to 145 do
         fillchar(screen[i,299],3,0);
         mouseshow;
        end
       else
        begin
         psychemode:=1;
         drawcursor;
         opendisplay;
        end;
  #27: done:=true;
  '`': bossmode;
  #10: printbigbox(GetHeapStats1,GetHeapStats2);
 end;
 idletime:=0;
end;

procedure findmouse;
begin
 if not mouse.getstatus then exit;
 case mouse.y of
  157..175: if (mouse.x>295) and (mouse.x<307) then done:=true;
    18..24: case mouse.x of
             250..259: begin
                        altmen(1);
                        if psychemode=0 then redraw1 else redraw2;
                       end;
             307..316: begin
                        altmen(-1);
                        if psychemode=0 then redraw1 else redraw2;
                       end;
            end;
    26..32: case mouse.x of
             250..259: begin
                        altphy(1);
                        if psychemode=0 then redraw1 else redraw2;
                       end;
             307..316: begin
                        altphy(-1);
                        if psychemode=0 then redraw1 else redraw2;
                       end;
            end;
    34..40: case mouse.x of
             250..259: begin
                        altemo(1);
                        if psychemode=0 then redraw1 else redraw2;
                       end;
             307..316: begin
                        altemo(-1);
                        if psychemode=0 then redraw1 else redraw2;
                       end;
            end;
    41..48: case mouse.x of
             179..205: if psychemode<>0 then
                        begin
                         psychemode:=0;
                         drawcursor;
                         closedisplay;
                         mousehide;
                         for i:=111 to 145 do
                          fillchar(screen[i,299],3,0);
                         mouseshow;
                        end;
             207..241: if psychemode<>1 then
                        begin
                         psychemode:=1;
                         drawcursor;
                         opendisplay;
                        end;
             262..280: begin
                        erasebubbles;
                        if crewindex=1 then crewindex:=6 else dec(crewindex);
                        if psychemode=0 then redraw1 else redraw2;
                        newbubbles;
                       end;
             286..304: begin
                        erasebubbles;
                        if crewindex=6 then crewindex:=1 else inc(crewindex);
                        if psychemode=0 then redraw1 else redraw2;
                        newbubbles;
                       end;
            end;
    end;
    case mouse.y of
    22..60: if (mouse.x<20) and (mouse.x>11) then
             begin
              if ship.damages[5]>39 then lifesupportfailure
               else encodecrew(181);
             end;
 end;
 idletime:=0;
end;

procedure mainloop;
begin
 repeat
    palettedirty := true;
    fadestep(8);
    PushRand;
    findmouse;
    PopRand;
    if fastkeypressed then processkey;
    inc(idletime);
    if idletime=maxidle then screensaver;
    PushRand;
    adjustgraph;
    PopRand;
    {set256colors(colors);}
    if batindex<8 then inc(batindex) else
    begin
       batindex:=0;
       addtime2;
       PushRand;
       mousehide;
       drawprimarystats(crewindex);
       drawgraphs;
       mouseshow;
       PopRand;
    end;
    delay(tslice*6);
    movebubbles;
 until done;
end;

procedure psyche;
begin
   PushRand;
   readydata;
   PopRand;
   mainloop;
   PushRand;
   {stopmod;}
   dispose(bubbles);
   removedata;
   PopRand;
end;

begin
end.
