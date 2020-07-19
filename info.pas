unit info;

{***************************
   Information unit for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

{$O+}

interface

procedure sectorinfo;

implementation

uses crt, utils_, data, gmouse, utils, display, utils2, usecode, modplay,
 weird, journey, heapchk;

type
 nearsectype= array[1..37] of nearbytype;
var
 cenx,ceny,cenz,i,j,sector,index,shipsector,infoindex,sysindex,glowindex,
  tarx,tary,tarz,rotatemode: integer;
 nearsec: ^nearsectype;
 tarxr,taryr,tarzr,n2: real;
 engaging: boolean;

procedure displaytargets;
var str1: string[3];
begin
 mousehide;
 str((tarx div 10):3,str1);
 printxy(42,172,str1);
 str((tary div 10):3,str1);
 printxy(42,180,str1);
 str((tarz div 10):3,str1);
 printxy(42,188,str1);
 if infoindex=0 then
  begin
   setcolor(47);
   setwritemode(xorput);
   x:=tarx-cenx;
   y:=tary-ceny;
   x:=round(x/10)+230;
   y:=round(y/20)+55;
   line(x,20,x,88);
   line(x,91,x,158);
   line(160,y,300,y);
   y:=tarz-cenz;
   y:=round(y/20)+125;
   line(160,y,300,y);
   setwritemode(copyput);
  end;
 mouseshow;
end;

procedure readysector;
var sec: integer;
begin
 sec:=sector;
 if sec>4 then
  begin
   sec:=sec-4;
   cenz:=1875;
  end
 else cenz:=625;
 if sec>2 then
  begin
   sec:=sec-2;
   ceny:=1875;
  end
 else ceny:=625;
 if sec>1 then cenx:=1875 else cenx:=625;
 for j:=1 to 37 do nearsec^[j].index:=0;
 index:=0;
 for i:=1 to 250 do
  begin
   if systems[i].x>1250 then j:=2 else j:=1;
   if systems[i].y>1250 then j:=j+2;
   if systems[i].z>1250 then j:=j+4;
{$IFDEF DEMO}
   if j=sector then
{$ELSE}
   if (j=sector) and (systems[i].notes and 1>0) then
{$ENDIF}
    begin
     inc(index);
     if index=38 then errorhandler('Invalid NearSec value.',6);
     nearsec^[index].index:=i;
     nearsec^[index].x:=(systems[i].x-cenx)/10;
     nearsec^[index].y:=(systems[i].y-ceny)/10;
     nearsec^[index].z:=(systems[i].z-cenz)/10;
    end;
  end;
 tarxr:=(tarx-cenx)/10;
 taryr:=(tary-ceny)/10;
 tarzr:=(tarz-cenz)/10;
end;

procedure displaysector;
begin
 if ship.damages[7]>59 then
  begin
   mousehide;
   index:=glowindex mod 2;
   for i:=0 to 52 do
    begin
     for j:=27 to 142 do
      screen[i*2+43+index,j]:=random(16);
     fillchar(screen[i*2+44-index,27],115,0);
    end;
   mouseshow;
   exit;
  end
 else if ship.damages[7]>(20+random(40)) then
  begin
   mousehide;
   index:=glowindex mod 2;
   for i:=0 to 52 do
    begin
     for j:=27 to 142 do
      screen[i*2+43+index,j]:=random(16);
     fillchar(screen[i*2+44-index,27],115,0);
    end;
   mouseshow;
   exit;
  end;
 fillchar(starmapscreen^,sizeof(templatetype2),0);
 for j:=1 to 37 do if nearsec^[j].index<>0 then
  begin
   x1:=nearsec^[j].x;
   y1:=nearsec^[j].z;
   if rotatemode=-1 then
    begin
     nearsec^[j].x:=0.987700794*x1-0.156355812*y1;
     nearsec^[j].z:=0.156355812*x1+0.987700794*y1;
    end
   else if rotatemode=1 then
    begin
     nearsec^[j].x:= 0.987700794*x1+0.156355812*y1;
     nearsec^[j].z:=-0.156355812*x1+0.987700794*y1;
    end;
   x1:=85+(nearsec^[j].x*250/(500-nearsec^[j].z));
   y1:=70+(nearsec^[j].y*250/(500-nearsec^[j].z));
   x:=round(x1);
   y:=round(y1);
   if infoindex=0 then
    case systems[nearsec^[j].index].mode of
     1: i:=127;
     2: i:=95;
     3: i:=31;
    end
   else
    if systems[nearsec^[j].index].visits>0 then i:=31 else i:=95;
   starmapscreen^[y,x]:=i;
  end;
 mousehide;
 for i:=18 to 123 do
  mymove(starmapscreen^[i],screen[i+25,27],29);
 x1:=tarxr;
 y1:=tarzr;
 if rotatemode=-1 then
  begin
   tarxr:=0.987700794*x1-0.156355812*y1;
   tarzr:=0.156355812*x1+0.987700794*y1;
  end
 else if rotatemode=1 then
  begin
   tarxr:= 0.987700794*x1+0.156355812*y1;
   tarzr:=-0.156355812*x1+0.987700794*y1;
  end;
 x1:=85+(tarxr*250/(500-tarzr));
 y1:=70+(taryr*250/(500-tarzr));
 x:=round(x1);
 y:=round(y1);
 setcolor(44);
 circle(x,y+25,4);
 mouseshow;
end;

procedure displaysideview;
var c1: integer;
begin
 mousehide;
 for i:=20 to 88 do
  fillchar(screen[i,160],141,5);
 for i:=91 to 158 do
  fillchar(screen[i,160],141,5);
 setcolor(3);
 for j:=1 to 6 do
  begin
   line(j*20+160,20,j*20+160,88);
   line(j*20+160,91,j*20+160,158);
  end;
 for i:=1 to 6 do
  begin
   line(160,19+i*10,300,19+i*10);
   line(160,90+i*10,300,90+i*10);
  end;
 for j:=1 to 37 do
  if nearsec^[j].index<>0 then
   begin
    x:=systems[nearsec^[j].index].x - cenx;
    y:=systems[nearsec^[j].index].y - ceny;
    x:=round(x/10) + 230;
    y:=round(y/20) + 55;
    case systems[nearsec^[j].index].mode of
     1: c1:=127;
     2: c1:=95;
     3: c1:=31;
    end;
    screen[y,x]:=c1;
    x:=systems[nearsec^[j].index].x - cenx;
    y:=systems[nearsec^[j].index].z - cenz;
    x:=round(x/10) + 230;
    y:=round(y/20) + 125;
    case systems[nearsec^[j].index].mode of
     1: c1:=127;
     2: c1:=95;
     3: c1:=31;
    end;
    screen[y,x]:=c1;
   end;
 tcolor:=31;
 bkcolor:=0;
 displaytargets;
 mouseshow;
end;

procedure readyhistoryview;
var str1: string[7];
    planets,stars,a,exploredplanets,exploredstars,scansdone: integer;
begin
 bkcolor:=5;
 tcolor:=211;
 mousehide;
 graybutton(159,34,301,149);
 for i:=12 to 33 do
  fillchar(screen[i,159],143,0);
 for i:=150 to 166 do
  fillchar(screen[i,159],143,0);
 for i:=74 to 85 do
  fillchar(screen[i,179],101,0);
 for i:=100 to 111 do
  fillchar(screen[i,179],101,0);
 for i:=127 to 138 do
  fillchar(screen[i,179],101,0);
 case sector of
  1: str1:='ALPHA';
  2: str1:='BETA';
  3: str1:='GAMMA';
  4: str1:='DELTA';
  5: str1:='EPSILON';
  6: str1:='ZETA';
  7: str1:='ETA';
  8: str1:='THETA';
 end;
 printxy(207-round(length(str1)*2.5),37,str1+' SECTOR');
 printxy(185,49,'Stars');
 printxy(180,55,'Planets');
 printxy(194,64,'Stars Explored');
 revgraybutton(179,74,280,85);
 printxy(189,90,'Planets Explored');
 revgraybutton(179,100,280,111);
 printxy(191,117,'Scans Completed');
 revgraybutton(179,127,280,138);
 stars:=0;
 planets:=0;
 exploredplanets:=0;
 exploredstars:=0;
 scansdone:=0;
 for i:=1 to 37 do if nearsec^[i].index>0 then
  begin
   j:=findfirstplanet(nearsec^[i].index);
   while (tempplan^[j].system=nearsec^[i].index) and (j<1001) do
    begin
     if (tempplan^[j].visits>0) and (tempplan^[j].orbit>0)
      then inc(exploredplanets)
     else if (tempplan^[j].visits>0) then inc(exploredstars);
     if (tempplan^[j].notes and 1>0) then inc(scansdone);
     inc(j);
     inc(planets);
    end;
   inc(stars);
  end;
 str(stars:3,str1);
 printxy(250,49,str1);
 str(planets:3,str1);
 printxy(250,55,str1);
 if stars>0 then a:=round(exploredstars/stars*100)
  else a:=100;
 for i:=0 to 9 do
  begin
   if i>2 then j:=89-i
    else j:=83+i;
   fillchar(screen[i+75,180],a,j);
  end;
 if planets>0 then a:=round(exploredplanets/planets*100)
  else a:=100;
 for i:=0 to 9 do
  begin
   if i>2 then j:=89-i
    else j:=83+i;
   fillchar(screen[i+101,180],a,j);
  end;
 if planets>0 then a:=round(scansdone/planets*100)
  else a:=100;
 for i:=0 to 9 do
  begin
   if i>2 then j:=89-i
    else j:=83+i;
   fillchar(screen[i+128,180],a,j);
  end;
 tcolor:=31;
 bkcolor:=0;
 mouseshow;
 displaytargets;
end;

procedure readysideview;
begin
 graybutton(159,19,301,89);
 graybutton(159,90,301,159);
 printxy(170,12,'X-Y  Side View');
 printxy(170,160,'X-Z  Top View');
 displaysideview;
end;

procedure undocursor;
begin
 if sector>4 then i:=2 else i:=1;
 j:=(sector-1) mod 4;
 plainfadearea(66+j*19,167+i*10,82+j*19,175+i*10,-5);
end;

procedure drawcursor;
begin
 if sector>4 then i:=2 else i:=1;
 j:=(sector-1) mod 4;
 plainfadearea(66+j*19,167+i*10,82+j*19,175+i*10,5);
end;

procedure rotateit(mode: integer);
begin
 rotatemode:=0;
 case mode of
  0: for j:=1 to 37 do if nearsec^[j].index>0 then
      begin
       x1:=nearsec^[j].y;
       y1:=nearsec^[j].z;
       nearsec^[j].y:=0.987700794*x1-0.156355812*y1;
       nearsec^[j].z:=0.156355812*x1+0.987700794*y1;
      end;
  1: for j:=1 to 37 do if nearsec^[j].index>0 then
      begin
       x1:=nearsec^[j].y;
       y1:=nearsec^[j].z;
       nearsec^[j].y:= 0.987700794*x1+0.156355812*y1;
       nearsec^[j].z:=-0.156355812*x1+0.987700794*y1;
      end;
  2: for j:=1 to 37 do if nearsec^[j].index>0 then
      begin
       x1:=nearsec^[j].x;
       y1:=nearsec^[j].z;
       nearsec^[j].x:=0.987700794*x1-0.156355812*y1;
       nearsec^[j].z:=0.156355812*x1+0.987700794*y1;
      end;
  3: for j:=1 to 37 do if nearsec^[j].index>0 then
      begin
       x1:=nearsec^[j].x;
       y1:=nearsec^[j].z;
       nearsec^[j].x:= 0.987700794*x1+0.156355812*y1;
       nearsec^[j].z:=-0.156355812*x1+0.987700794*y1;
      end;
 end;
 case mode of
  0: begin
      x1:=taryr;
      y1:=tarzr;
      taryr:=0.987700794*x1-0.156355812*y1;
      tarzr:=0.156355812*x1+0.987700794*y1;
     end;
  1: begin
      x1:=taryr;
      y1:=tarzr;
      taryr:= 0.987700794*x1+0.156355812*y1;
      tarzr:=-0.156355812*x1+0.987700794*y1;
     end;
  2: begin
      x1:=tarxr;
      y1:=tarzr;
      tarxr:=0.987700794*x1-0.156355812*y1;
      tarzr:=0.156355812*x1+0.987700794*y1;
     end;
  3: begin
      x1:=tarxr;
      y1:=tarzr;
      tarxr:= 0.987700794*x1+0.156355812*y1;
      tarzr:=-0.156355812*x1+0.987700794*y1;
     end;
 end;
 displaysector;
end;

procedure processkey;
var ans: char;
    i: byte;
begin
 ans:=readkey;
 case upcase(ans) of
  #0: begin
       ans:=readkey;
       case ans of
        #72: rotateit(0);
        #80: rotateit(1);
        #75: rotateit(2);
        #77: rotateit(3);
        #71: rotatemode:=-1;
        #79: rotatemode:=1;
       end;
      end;
  '1'..'8': begin
             i:=ord(ans)-48;
             if i<>sector then
              begin
               undocursor;
               sector:=i;
               drawcursor;
               readysector;
               tarxr:=0;
               taryr:=0;
               tarzr:=0;
               tarx:=cenx;
               tary:=ceny;
               tarz:=cenz;
               if infoindex=0 then displaysideview else readyhistoryview;
              end;
            end;
  '+': if infoindex<>0 then
        begin
         infoindex:=0;
         plainfadearea(145,177,197,185,5);
         plainfadearea(145,187,197,195,-5);
         readysideview;
        end;
  '-': if infoindex<>1 then
        begin
         infoindex:=1;
         plainfadearea(145,177,197,185,-5);
         plainfadearea(145,187,197,195,5);
         readyhistoryview;
        end;
  #27: done:=true;
  ' ': rotatemode:=0;
  '`': bossmode;
  #10: printbigbox(GetHeapStats1,GetHeapStats2);
 end;
 idletime:=0;
end;

procedure findtarget;
var minx, miny: integer;
    str1: string[12];
begin
 if infoindex=1 then exit;
 setcolor(47);
 setwritemode(xorput);
 x:=tarx-cenx;
 y:=tary-ceny;
 x:=round(x/10)+230;
 y:=round(y/20)+55;
 mousehide;
 line(x,20,x,88);
 line(x,91,x,158);
 line(160,y,300,y);
 y:=tarz-cenz;
 y:=round(y/20)+125;
 line(160,y,300,y);
 if mouse.y<89 then
  begin
   tarx:=(mouse.x-230)*10+cenx;
   tary:=(mouse.y-55)*20+ceny;
   minx:=2500;
   miny:=2500;
   index:=1;
   for j:=1 to 37 do
    if nearsec^[j].index>0 then
     begin
      x:=systems[nearsec^[j].index].x;
      y:=systems[nearsec^[j].index].y;
      if (abs(tarx-x) + abs(tary-y)) < (abs(minx) + abs(miny)) then
       begin
        minx:=tarx-x;
        miny:=tary-y;
        index:=j;
       end;
     end;
   tarx:=systems[nearsec^[index].index].x;
   tary:=systems[nearsec^[index].index].y;
   tarz:=systems[nearsec^[index].index].z;
   tarxr:=nearsec^[index].x;
   taryr:=nearsec^[index].y;
   tarzr:=nearsec^[index].z;
  end
 else if mouse.y>90 then
  begin
   tarx:=(mouse.x-230)*10+cenx;
   tarz:=(mouse.y-125)*20+cenz;
   minx:=2500;
   miny:=2500;
   index:=1;
   for j:=1 to 37 do
    if nearsec^[j].index>0 then
     begin
      x:=systems[nearsec^[j].index].x;
      y:=systems[nearsec^[j].index].z;
      if (abs(tarx-x) + abs(tarz-y)) < (abs(minx) + abs(miny)) then
       begin
        minx:=tarx-x;
        miny:=tarz-y;
        index:=j;
       end;
     end;
   tarx:=systems[nearsec^[index].index].x;
   tary:=systems[nearsec^[index].index].y;
   tarz:=systems[nearsec^[index].index].z;
   tarxr:=nearsec^[index].x;
   taryr:=nearsec^[index].y;
   tarzr:=nearsec^[index].z;
  end;
 for i:=24 to 30 do
  fillchar(screen[i,40],90,0);
 str1:=systems[nearsec^[index].index].name;
 i:=11;
 while str1[i]=' ' do dec(i);
 str1[0]:=chr(i);
 printxy(74-round(i*2.5),24,str1);
 displaytargets;
 mouseshow;
end;

procedure editx;
var temp: string[3];
    curx,value,error: integer;
    ans: char;
begin
 curx:=1;
 tcolor:=31;
 temp:='   ';
 writeln('/mn/ start editx');
 mousehide;
 repeat
  for j:=1 to 3 do
   begin
    if curx=j then bkcolor:=88 else bkcolor:=0;
    printxy(37+j*5,172,temp[j]);
   end;
  ans:='@'; if fastkeypressed then ans:=readkey else delay(tslice*2); { /mn/ 20200719 kludge so we can set position manually as readkey returns immediately without waiting for new key! }
  case ans of
   '0'..'9',' ': begin
                  temp[curx]:=ans;
                  if curx<3 then inc(curx);
                 end;
   #8: begin
        temp[curx]:=' ';
        if curx>1 then dec(curx);
       end;
  end;
 until (ans=#13) or (ans=#27);
 bkcolor:=0;
 if ans=#13 then
  begin
   while temp[ord(temp[0])]=' ' do dec(temp[0]);
   val(temp,value,error);
   if error=0 then
    begin
     tarx:=value*10;
     if tarx>2500 then tarx:=2500;
     undocursor;
     sector:=1;
     if tarx>1250 then sector:=2;
     if tary>1250 then sector:=sector+2;
     if tarz>1250 then sector:=sector+4;
     drawcursor;
     readysector;
     if infoindex=0 then displaysideview else readyhistoryview;
    end;
   end
 else
  begin
   displaytargets;
   displaytargets;
  end;
 for i:=24 to 30 do
  fillchar(screen[i,40],90,0);
 mouseshow;
 writeln('/mn/ end editx ans=', ord(ans), ' temp=>', temp, '<, value=', value, ', error=', error);
end;

procedure edity;
var temp: string[3];
    curx,value,error: integer;
    ans: char;
begin
 curx:=1;
 tcolor:=31;
 temp:='   ';
 writeln('/mn/ start edity');
 mousehide;
 repeat
  for j:=1 to 3 do
   begin
    if curx=j then bkcolor:=88 else bkcolor:=0;
    printxy(37+j*5,180,temp[j]);
   end;
  ans:='@'; if fastkeypressed then ans:=readkey else delay(tslice*2); { /mn/ 20200719 kludge so we can set position manually as readkey returns immediately without waiting for new key! }
  case ans of
   '0'..'9',' ': begin
                  temp[curx]:=ans;
                  if curx<3 then inc(curx);
                 end;
   #8: begin
        temp[curx]:=' ';
        if curx>1 then dec(curx);
       end;
  end;
 until (ans=#13) or (ans=#27);
 bkcolor:=0;
 if ans=#13 then
  begin
   while temp[ord(temp[0])]=' ' do dec(temp[0]);
   val(temp,value,error);
   if error=0 then
    begin
     tary:=value*10;
     if tary>2500 then tary:=2500;
     undocursor;
     sector:=1;
     if tarx>1250 then sector:=2;
     if tary>1250 then sector:=sector+2;
     if tarz>1250 then sector:=sector+4;
     drawcursor;
     readysector;
     if infoindex=0 then displaysideview else readyhistoryview;
    end;
   end
 else
  begin
   displaytargets;
   displaytargets;
  end;
 for i:=24 to 30 do
  fillchar(screen[i,40],90,0);
 mouseshow;
 writeln('/mn/ end edity ans=', ord(ans), ' temp=>', temp, '<, value=', value, ', error=', error);
end;

procedure editz;
var temp: string[3];
    curx,value,error: integer;
    ans: char;
begin
 curx:=1;
 tcolor:=31;
 temp:='   ';
 writeln('/mn/ start editz');
 mousehide;
 repeat
  for j:=1 to 3 do
   begin
    if curx=j then bkcolor:=88 else bkcolor:=0;
    printxy(37+j*5,188,temp[j]);
   end;
  ans:='@'; if fastkeypressed then ans:=readkey else delay(tslice*2); { /mn/ 20200719 kludge so we can set position manually as readkey returns immediately without waiting for new key! }
  case ans of
   '0'..'9',' ': begin
                  temp[curx]:=ans;
                  if curx<3 then inc(curx);
                 end;
   #8: begin
        temp[curx]:=' ';
        if curx>1 then dec(curx);
       end;
  end;
 until (ans=#13) or (ans=#27);
 bkcolor:=0;
 if ans=#13 then
  begin
   while temp[ord(temp[0])]=' ' do dec(temp[0]);
   val(temp,value,error);
   if error=0 then
    begin
     tarz:=value*10;
     if tarz>2500 then tarz:=2500;
     undocursor;
     sector:=1;
     if tarx>1250 then sector:=2;
     if tary>1250 then sector:=sector+2;
     if tarz>1250 then sector:=sector+4;
     drawcursor;
     readysector;
     if infoindex=0 then displaysideview else readyhistoryview;
    end;
   end
 else
  begin
   displaytargets;
   displaytargets;
  end;
 for i:=24 to 30 do
  fillchar(screen[i,40],90,0);
 mouseshow;
 writeln('/mn/ end editz ans=', ord(ans), ' temp=>', temp, '<, value=', value, ', error=', error);
end;

procedure newsec(n: integer);
begin
 undocursor;
 sector:=n;
 drawcursor;
 readysector;
 tarxr:=0; taryr:=0; tarzr:=0;
 tarx:=cenx; tary:=ceny; tarz:=cenz;
 if infoindex=0 then displaysideview else readyhistoryview;
 mousehide;
 for i:=24 to 30 do
  fillchar(screen[i,40],90,0);
 mouseshow;
end;

procedure findhome;
var str1: string[12];
begin
 undocursor;
 if ship.posx>1250 then sector:=2 else sector:=1;
 if ship.posy>1250 then sector:=sector+2;
 if ship.posz>1250 then sector:=sector+4;
 shipsector:=sector;
 tarx:=ship.posx;
 tary:=ship.posy;
 tarz:=ship.posz;
 readysector;
 if infoindex=0 then displaysideview else readyhistoryview;
 displaytargets;
 displaytargets;
 drawcursor;
 mousehide;
 index:=0;
 for i:=1 to 38 do
  if (curplan>0) and (nearsec^[i].index=tempplan^[curplan].system)
   then
    begin
     index:=i;
     i:=38;
    end;
 for i:=24 to 30 do
  fillchar(screen[i,40],90,0);
 if (curplan>0) and (index<>0) then str1:=systems[nearsec^[index].index].name
  else str1:='UNKNOWN     ';
 i:=12;
 while str1[i]=' ' do dec(i);
 str1[0]:=chr(i);
 printxy(74-round(i*2.5),24,str1);
 for i:=24 to 30 do
  fillchar(screen[i,40],90,0);
 str1:=systems[nearsec^[index].index].name;
 i:=11;
 while str1[i]=' ' do dec(i);
 str1[0]:=chr(i);
 printxy(74-round(i*2.5),24,str1);
 mouseshow;
end;

procedure findtarget2;
var str1: string[12];
begin
 if infoindex=0 then
  begin
   setcolor(47);
   setwritemode(xorput);
   x:=tarx-cenx;
   y:=tary-ceny;
   x:=round(x/10)+230;
   y:=round(y/20)+55;
   mousehide;
   line(x,20,x,88);
   line(x,91,x,158);
   line(160,y,300,y);
   y:=tarz-cenz;
   y:=round(y/20)+125;
   line(160,y,300,y);
   mouseshow;
  end;
 for j:=1 to 37 do if nearsec^[j].index<>0 then
  begin
   x1:=85+(nearsec^[j].x*250/(500-nearsec^[j].z));
   y1:=70+(nearsec^[j].y*250/(500-nearsec^[j].z));
   x:=round(x1);
   y:=round(y1)+25;
   if (abs(x-mouse.x)<4) and (abs(y-mouse.y)<4) then
    begin
     tarx:=systems[nearsec^[j].index].x;
     tary:=systems[nearsec^[j].index].y;
     tarz:=systems[nearsec^[j].index].z;
     tarxr:=nearsec^[j].x;
     taryr:=nearsec^[j].y;
     tarzr:=nearsec^[j].z;
     index:=j;
    end;
  end;
 for i:=24 to 30 do
  fillchar(screen[i,40],90,0);
 str1:=systems[nearsec^[index].index].name;
 i:=11;
 while str1[i]=' ' do dec(i);
 str1[0]:=chr(i);
 printxy(74-round(i*2.5),24,str1);
 displaytargets;
end;

procedure findmouse;
begin
 if not mouse.getstatus then exit;
 case mouse.x of
    43..62: case mouse.y of
             172..178: editx;
             180..186: edity;
             188..194: editz;
              43..147: findtarget2;
            end;
    66..82: case mouse.y of
             177..185: newsec(1);
             187..195: newsec(5);
              43..147: findtarget2;
            end;
   85..101: case mouse.y of
             177..185: newsec(2);
             187..195: newsec(6);
              43..147: findtarget2;
            end;
  104..120: case mouse.y of
             177..185: newsec(3);
             187..195: newsec(7);
              43..147: findtarget2;
            end;
  123..139: case mouse.y of
             177..185: newsec(4);
             187..195: newsec(8);
              43..147: findtarget2;
            end;
//   end;
//   case mouse.x of
   27..42,63..65,83,84,102,103,121,122,140..142: if (mouse.y<148) and (mouse.y>42) then findtarget2;
  145..159: case mouse.y of
             177..185: if infoindex<>0 then
                        begin
                         infoindex:=0;
                         plainfadearea(145,177,197,185,5);
                         plainfadearea(145,187,197,195,-5);
                         readysideview;
                        end;
             187..195: if infoindex<>1 then
                        begin
                         infoindex:=1;
                         plainfadearea(145,177,197,185,-5);
                         plainfadearea(145,187,197,195,5);
                         readyhistoryview;
                        end;
            end;
  160..197: case mouse.y of
              20..160: findtarget;
             177..185: if infoindex<>0 then
                        begin
                         infoindex:=0;
                         plainfadearea(145,177,197,185,5);
                         plainfadearea(145,187,197,195,-5);
                         readysideview;
                        end;
             187..195: if infoindex<>1 then
                        begin
                         infoindex:=1;
                         plainfadearea(145,177,197,185,-5);
                         plainfadearea(145,187,197,195,5);
                         readyhistoryview;
                        end;
            end;
  205..221: case mouse.y of
              21..158: findtarget;
             177..185: rotatemode:=-1;
            end;
  223..233: case mouse.y of
              21..158: findtarget;
             177..185: rotateit(2);
            end;
  235..244: case mouse.y of
              21..158: findtarget;
             170..176: rotateit(0);
             178..186: rotatemode:=0;
             188..194: rotateit(1);
            end;
  246..256: case mouse.y of
              21..158: findtarget;
             177..185: rotateit(3);
            end;
  258..274: case mouse.y of
              21..158: findtarget;
             177..185: rotatemode:=1;
            end;
  282..292: case mouse.y of
             178..195: begin
                        engaging:=true;
                        done:=true;
                        targetready:=true;
                       end;
              21..158: findtarget;
            end;
  300..310: case mouse.y of
              21..158: findtarget;
             177..195: done:=true;
            end;
     2..10: if (mouse.y>162) and (mouse.y<198) then findhome;
//   end;
//   case mouse.x of  
//  198..310: if (mouse.y<159) and (mouse.y>20) then findtarget;
 end;
 idletime:=0;
end;

procedure mainloop;
begin
   repeat
      fadestep(8);
      displaysector;
      if batindex<8 then inc(batindex) else
      begin
	 batindex:=0;
	 addtime2;
      end;
      delay(tslice*8);
      if fastkeypressed then processkey;
      findmouse;
      if idletime=maxidle then screensaver;
   until done;
end;

procedure readydata;
begin
   mousehide;
   compressfile(tempdir+'/current',@screen);
   {fading;}
   fadestopmod(-8, 20);
   playmod(true,'sound/GENER1.MOD');
   loadscreen('data/sector',@screen);
   {fadein;}
   new(nearsec);
   done:=false;
   sysindex:=1;
   bkcolor:=0;
   tcolor:=31;
   oldt1:=t1;
   drawcursor;
   infoindex:=0;
   rotatemode:=1;
   engaging:=false;
   findhome;
   plainfadearea(145,177,197,185,5);
   readysideview;
   mouseshow;
end;

procedure removedata;
begin
   mousehide;
   {fading;}
   fadestopmod(-8, 20);
   mouse.setmousecursor(random(3));
   loadscreen(tempdir+'/current',@screen);
   bkcolor:=3;
   displaytextbox(false);
   textindex:=25;
   if viewmode2=4 then readylongscan;
   fadein;
   mouseshow;
   anychange:=true;
   t1:=oldt1;
end;

procedure sectorinfo;
begin
 readydata;
 mainloop;
 t1:=oldt1;
 dispose(nearsec);
 {stopmod;}
 removedata;
 if engaging then
  begin
   engage(tarx,tary,tarz);
  end;
end;

begin
end.
