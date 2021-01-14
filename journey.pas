unit journey;
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
    along with Ironseed.  If not, see <https://www.gnu.org/licenses/>.
********************************************************************)

{*********************************************
   Main Control unit for IronSeed

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2013 y-salnikov
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

{$I-}

interface

procedure print(s: string);
procedure println;
procedure showtime;
procedure addtime;
procedure setalertmode(mode: integer; do_shields: boolean);
procedure makesphere;
procedure makegasplanet;
procedure makestar;
procedure shadowprint(s: string);
procedure shadowprintln;
procedure displaytextbox(scrollit: boolean);
procedure mainloop;

implementation

uses utils_, gmouse, usecode, data, saveload, utils, display, combat, utils2, weird, modplay, comm, crewtick, heapchk;

const
asintab :array[0..1024] of byte =
(0,0,0,0,0,1,1,1,1,1,1,1,1,1,2,2,
2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3, {fudged}
{2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,} {proper}
4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,
5,5,6,6,6,6,6,6,6,6,6,7,7,7,7,7,
7,7,7,8,8,8,8,8,8,8,8,8,9,9,9,9,
9,9,9,9,9,10,10,10,10,10,10,10,10,10,11,11,
11,11,11,11,11,11,11,12,12,12,12,12,12,12,12,12,
13,13,13,13,13,13,13,13,13,14,14,14,14,14,14,14,
14,14,15,15,15,15,15,15,15,15,15,16,16,16,16,16,
16,16,16,17,17,17,17,17,17,17,17,17,18,18,18,18,
18,18,18,18,18,19,19,19,19,19,19,19,19,19,20,20,
20,20,20,20,20,20,20,21,21,21,21,21,21,21,21,21,
22,22,22,22,22,22,22,22,23,23,23,23,23,23,23,23,
23,24,24,24,24,24,24,24,24,24,25,25,25,25,25,25,
25,25,26,26,26,26,26,26,26,26,26,27,27,27,27,27,
27,27,27,27,28,28,28,28,28,28,28,28,28,29,29,29,
29,29,29,29,29,30,30,30,30,30,30,30,30,30,31,31,
31,31,31,31,31,31,32,32,32,32,32,32,32,32,32,33,
33,33,33,33,33,33,33,33,34,34,34,34,34,34,34,34,
35,35,35,35,35,35,35,35,35,36,36,36,36,36,36,36,
36,37,37,37,37,37,37,37,37,37,38,38,38,38,38,38,
38,38,39,39,39,39,39,39,39,39,39,40,40,40,40,40,
40,40,40,41,41,41,41,41,41,41,41,42,42,42,42,42,
42,42,42,42,43,43,43,43,43,43,43,43,44,44,44,44,
44,44,44,44,45,45,45,45,45,45,45,45,46,46,46,46,
46,46,46,46,46,47,47,47,47,47,47,47,47,48,48,48,
48,48,48,48,48,49,49,49,49,49,49,49,49,50,50,50,
50,50,50,50,50,51,51,51,51,51,51,51,51,52,52,52,
52,52,52,52,52,53,53,53,53,53,53,53,53,54,54,54,
54,54,54,54,54,55,55,55,55,55,55,55,55,56,56,56,
56,56,56,56,56,57,57,57,57,57,57,57,57,58,58,58,
58,58,58,58,58,59,59,59,59,59,59,59,59,60,60,60,
60,60,60,60,61,61,61,61,61,61,61,61,62,62,62,62,
62,62,62,62,63,63,63,63,63,63,63,64,64,64,64,64,
64,64,64,65,65,65,65,65,65,65,66,66,66,66,66,66,
66,66,67,67,67,67,67,67,67,68,68,68,68,68,68,68,
68,69,69,69,69,69,69,69,70,70,70,70,70,70,70,71,
71,71,71,71,71,71,71,72,72,72,72,72,72,72,73,73,
73,73,73,73,73,74,74,74,74,74,74,74,75,75,75,75,
75,75,75,76,76,76,76,76,76,76,77,77,77,77,77,77,
77,78,78,78,78,78,78,78,79,79,79,79,79,79,79,80,
80,80,80,80,80,80,81,81,81,81,81,81,81,82,82,82,
82,82,82,82,83,83,83,83,83,83,84,84,84,84,84,84,
84,85,85,85,85,85,85,85,86,86,86,86,86,86,87,87,
87,87,87,87,87,88,88,88,88,88,88,89,89,89,89,89,
89,90,90,90,90,90,90,90,91,91,91,91,91,91,92,92,
92,92,92,92,93,93,93,93,93,93,94,94,94,94,94,94,
95,95,95,95,95,95,96,96,96,96,96,96,97,97,97,97,
97,97,98,98,98,98,98,98,99,99,99,99,99,99,100,100,
100,100,100,100,101,101,101,101,101,102,102,102,102,102,102,103,
103,103,103,103,103,104,104,104,104,104,105,105,105,105,105,105,
106,106,106,106,106,107,107,107,107,107,108,108,108,108,108,108,
109,109,109,109,109,110,110,110,110,110,111,111,111,111,111,112,
112,112,112,112,113,113,113,113,113,114,114,114,114,114,115,115,
115,115,115,116,116,116,116,117,117,117,117,117,118,118,118,118,
118,119,119,119,119,120,120,120,120,120,121,121,121,121,122,122,
122,122,123,123,123,123,123,124,124,124,124,125,125,125,125,126,
126,126,126,127,127,127,127,128,128,128,128,129,129,129,129,130,
130,130,131,131,131,131,132,132,132,132,133,133,133,134,134,134,
134,135,135,135,136,136,136,136,137,137,137,138,138,138,139,139,
139,140,140,140,141,141,141,142,142,142,143,143,143,144,144,144,
145,145,146,146,146,147,147,147,148,148,149,149,150,150,150,151,
151,152,152,153,153,154,154,155,155,156,156,157,157,158,158,159,
160,160,161,162,162,163,164,165,166,167,168,169,170,171,173,175,
180);

var
 alt, i,j,q,m,index,a,b,j2,ofsx,ofsy,clickcode: integer;
 part: real;
 part4: real;
 s: string[30];
 msg,oldcube: integer;

procedure printstring(x1,y1: integer; snum: byte);
var letter,x,y: integer;
    color: byte;
begin
 color:=tcolor;
 s:=textdisplay^[snum];
 x1:=x1+4;
 for j:=1 to 30 do
 begin
  tcolor:=colordisplay^[snum,j];
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
    inc(y);
    x:=x1;
    for a:=7 downto 4 do
     begin
      inc(x);
      if font[ship.options[OPT_FONT],letter,i shr 1] and (1 shl a)>0 then screen2^[y,x]:=tcolor
       else if bkcolor<255 then screen2^[y,x]:=bkcolor;
     end;
    inc(y);
    x:=x1;
    inc(i);
    dec(tcolor,2);
    for a:=3 downto 0 do
     begin
      inc(x);
      if font[ship.options[OPT_FONT],letter,i shr 1] and (1 shl a)>0 then screen2^[y,x]:=tcolor
       else if bkcolor<255 then screen2^[y,x]:=bkcolor;
     end;
    dec(tcolor,2);
   end;
   x1:=x1+5;
   for i:=1 to 6 do screen2^[i+y1,x1]:=bkcolor;
 end;
 tcolor:=color;
end;

procedure displaytextbox(scrollit: boolean);
var i2: integer;
begin
 if cursorx>1 then
  begin
   for i2:=textindex to textindex+5 do printstring(9,(i2-textindex)*6+150,i2);
   mousehide;
   for i:=151 to 186 do scrto_move(screen2^[i,11],screen[i,11],150);
  end
 else
  begin
   for i2:=textindex-1 to textindex+5 do
    printstring(9,(i2-textindex+1)*6+150,i2);
   mousehide;
   if scrollit then
    for i2:=0 to 6 do
     begin
      for i:=151 to 186 do scrto_move(screen2^[i+i2,11],screen[i,11],150);
      delay(tslice div 3);
     end
   else
    for i:=151 to 186 do scrto_move(screen2^[i,11],screen[i,11],150);
  end;
 for i:=158 to 182 do
  scr_fillchar(screen[i,163],6,2);
 for j:=163 to 168 do
  screen[157+textindex,j]:=86;
 mouseshow;
end;

procedure println;
begin
 cursorx:=1;
 for j:=0 to 29 do
  move(textdisplay^[j+1],textdisplay^[j],30);
 fillchar(textdisplay^[30],ord(' '),30);
 for j:=0 to 29 do
  move(colordisplay^[j+1],colordisplay^[j],30);
 fillchar(colordisplay^[30],30,0);
 displaytextbox(true);
end;

procedure print(s: string);
var maxsize: byte;
    s1: string[30];
    s2: string[100];
    color: byte;
begin
 textindex:=25;
 color:=tcolor;
 if (length(s)+cursorx)>30 then
  begin
   maxsize:=31-cursorx;
   repeat
    dec(maxsize);
   until (s[maxsize]=' ') or (s[maxsize]='.') or
    (s[maxsize]=',') or (maxsize=0);
   if maxsize=0 then begin println; print(s); end
   else
    begin
     s1:=copy(s,1,maxsize);
     s2:=copy(s,maxsize+1,length(s));
     print(s1);
     println;
     tcolor:=color;
     print(s2);
    end;
  end
 else
  begin
   for j:=1 to length(s) do
    begin
     textdisplay^[30,cursorx+j-1]:=s[j];
     colordisplay^[30,cursorx+j-1]:=tcolor;
    end;
   cursorx:=cursorx+length(s);
  end;
 displaytextbox(true);
end;

procedure shadowprintln;
begin
 cursorx:=1;
 for j:=0 to 29 do
  move(textdisplay^[j+1],textdisplay^[j],30);
 fillchar(textdisplay^[30],ord(' '),30);
 for j:=0 to 29 do
  move(colordisplay^[j+1],colordisplay^[j],30);
 fillchar(colordisplay^[30],30,0);
end;

procedure shadowprint(s: string);
var maxsize: byte;
    s1,s2: ^string;
    color: byte;
begin
 new(s1);
 new(s2);
 textindex:=25;
 color:=tcolor;
 if (length(s)+cursorx)>30 then
  begin
   maxsize:=31-cursorx;
   repeat
    dec(maxsize);
   until (s[maxsize]=' ') or (s[maxsize]='.') or
    (s[maxsize]=',') or (maxsize=0);
   if maxsize=0 then
    begin
     shadowprintln;
     shadowprint(s);
    end
   else
    begin
     s1^:=copy(s,1,maxsize);
     s2^:=copy(s,maxsize+1,length(s));
     shadowprint(s1^);
     shadowprintln;
     tcolor:=color;
     shadowprint(s2^);
    end;
  end
 else
  begin
   for j:=1 to length(s) do
    begin
     textdisplay^[30,cursorx+j-1]:=s[j];
     colordisplay^[30,cursorx+j-1]:=tcolor;
    end;
   cursorx:=cursorx+length(s);
  end;
 dispose(s1);
 dispose(s2);
end;

procedure getcube(src,tar: byte);
begin
 assert ((src<=9*9) and (tar<=9*9));	// to turn off warnings, we don't really use those variables here
 move(cubetar^,cubesrc^,sizeof(cubetype));
 for a:=0 to 2 do
  for b:=0 to 2 do
   for j:=0 to 16 do
    for i:=0 to 14 do
     cubetar^[b*15+i,a*17+j]:=icons^[tar*9+a*3+b,j,i];
end;

procedure rotatecube2(src,tar: byte; fkey: boolean);
label skip1;
begin  {215,145}
 getcube(src,tar);
 if (ship.options[OPT_ANIMATION]=0) or (fkey) then
  begin
   mousehide;
   for i:=0 to 44 do
    scrto_move(cubetar^[i,0],screen[i+145,215],51);
   mouseshow;
   cube:=tar;
   exit;
  end;
 b:=tslice div 4;
 mousehide;
 for t:=1 to 21 do
  begin
   m:=round(10.5624*sin(3*t/20));
   q:=round(sin(3*t/40)*51);
   part:=51/q;
   for j:=0 to q-1 do
    begin
     index:=round(j*part);
     if index<51 then
      for i:=145 to 189 do
       screen[i,j+215-m]:=cubetar^[i-145,index];
    end;
   if (51+2*m-q)=0 then goto skip1;
   part:=51/(51+2*m-q);
   for j:=215-m+q to 266+m do
    begin
     index:=round((j-215+m-q)*part);
     if index<51 then
      for i:=145 to 189 do
       screen[i,j]:=cubesrc^[i-145,index];
    end;
 skip1:
    for i:=145 to 189 do
     begin
      for j:=266+m to 278 do screen[i,j]:=back4[j-266,i-145];
      for j:=202 to 214-m do screen[i,j]:=back3[j-202,i-145];
     end;
    mouseshow;
    delay(b);
    mousehide;
   end;
 for i:=0 to 44 do
  scrto_move(cubetar^[i,0],screen[i+145,215],51);
 mouseshow;
 cube:=tar;
end;

procedure rotatecube(src,tar: byte; fkey: boolean);
label skip1;
begin  {215,145}
 if tar+src=5 then
  begin
   if (tar=2) or (tar=3) then rotatecube2(src,tar-2,fkey)
   else if (tar>0) then rotatecube2(src,tar-1,fkey)
   else rotatecube2(src,tar+1,fkey);
  end;
 if random(4)=0 then
  begin
   rotatecube2(src,tar,fkey);
   exit;
  end;
 getcube(src,tar);
 if (ship.options[OPT_ANIMATION]=0) or (fkey) then
  begin
   mousehide;
   for i:=0 to 44 do
    scrto_move(cubetar^[i,0],screen[i+145,215],51);
   mouseshow;
   cube:=tar;
   exit;
  end;
 mousehide;
 for i:=133 to 144 do
  scrfrom_move(screen[i,215],back1[i-133],13*4);
 b:=tslice div 4;
 for t:=1 to 20 do
  begin
  m:=round(10.5624*sin(3*t/20));
  q:=round(sin(3*t/40)*45);
  part:=45/q;
  for j:=0 to q-1 do
   begin
    index:=round(j*part);
    if index<46 then
     for i:=215 to 265 do
      screen[j+145-m,i]:=cubetar^[index,i-215];
   end;
  if (45+2*m-q)=0 then goto skip1;
  part:=45/(45+2*m-q);
  for j:=145-m+q to 188+m do
   begin
    index:=round((j-145+m-q)*part);
    if index<46 then
     for i:=215 to 265 do
      screen[j,i]:=cubesrc^[index,i-215];
   end;
skip1:
   for j:=133 to 145-m do
    scrto_move(back1[j-133],screen[j,215],13*4);
   for j:=190+m to 199 do
    scrto_move(back2[j-190],screen[j,215],13*4);
   mouseshow;
   delay(b);
   mousehide;
  end;
 for i:=0 to 44 do
  scrto_move(cubetar^[i],screen[i+145,215],51);
 scrto_move(back2,screen[190,215],13*4);
 mouseshow;
 cube:=tar;
end;

function asin(x	: Real) : Real;
begin
   asin := ArcTan(x / sqrt(1 - sqr(x)));
end;

function fmod(x, y : Real) : Real;
begin
   fmod := x - Int(x / y) * y;
end;

procedure rendersphere(xx, yy, radius : Integer; angle : Real; eclipse: Boolean; ecl : Real);
var
   x, y	      : Integer;
   sx, sy     : Integer;
   ax         : Integer;
   e1, e2, ed : Integer;
   radius2    : Integer;
   radius1    : Real;
   radiusx    : Integer;
   c	      : Integer;
   ox	      : Integer;
begin
   e1 := round(ecl) mod 360;
   {e2 := fmod(ecl + 210, 360);}
   e2 := 240;{fmod(240, 360);}
   Radius2 := radius * radius;
   ox := round(angle * 240 / 360) mod 240;
   for y := -radius to radius do
   begin
      if ((yy + y) >= 1) and ((yy + y) < 120) then
      begin
	 {ay := round(asin(y / radius) / PI * 180);
	 sy := 120 * (ay + 90) / 181; }{proper y source value*/}
	 sy := round(120 * (y + radius) / (Radius * 2 + 1)); {cheating y source, looks better}
	 radius1 := sqrt(radius2 - y * y);
	 radiusx := round(radius1 + 1);
	 for x := -Radiusx to Radiusx do
	 begin
	    if (x * x + y * y < Radius2) and ((xx + x) >= 1) and ((xx + x) <= 120) then
	    begin
	       {ax := Round(angle + asin(x / Radius1) / PI * 180);
	       sx := ((120 * (ax + 90) div 181) + 239) mod 240 + 1;}
	       if x < 0 then
	       begin
		  ax := -asintab[round(1024 / Radius1 * -x)];
	       end else begin
		  ax := asintab[round(1024 / Radius1 * x)];
	       end;
	       sx := (90 + ox + ax div 3) mod 240 + 1;
	       ax := ax shr 1;
	       c := colorlookup[landform^[sx, sy]];
	       if c < 6 then
		  c := spcindex[c];
	       if (c > 246) and eclipse then
		  c := 116
	       else if eclipse then
	       begin
		  ax := (ax + 360 - e1) mod 360;
		  if (ax > 0) and (ax < e2) then
		  begin
		     if(abs(ax - 0) < abs(ax - e2)) then
			ed := abs(ax - 0)
		     else
			ed := abs(ax - e2);
		     if (ed > 60) then
			ed := 60;
		     if c < 32 then
			c := c * (80 - ed) div 60
		     else
			c := (c and $f0) or ((c and $0f) * ((60 - ed) div 60));
		  end;
	       end;
	       planet^[yy + y, xx + x] := c;
	    end;
	 end;
      end;
   end;
end;

procedure makegasplanet;
label endcheck;
var
   ii : Integer;
begin
 for i:=6 to 2*r2+4 do
 begin
    ii := 119 * (i - 6) div (2 * r2 -2) + 1;
   alt:=0;
   ofsy:=i+offset;
   ofsx:=pm[i]+offset;
   part4:=0;
   for j:=1 to xw do
    begin
     part4:=part4+ppart[i];
     index:=round(part4);
     if index>xw then goto endcheck;
     inc(ofsx);
     if ecl>170 then
       begin
        if j=1 then alt:=6
         else alt:=(index-ecl+186) div 2;
       end
       else if ecl<171 then
        begin
         if index=xw then alt:=6
          else alt:=(ecl-index) div 2
        end
       else alt:=0;
     if alt<0 then alt:=0;
     if (index+c)>240 then j2:=index+c-240
      else j2:=index+c;
     if alt>(landform^[j2,ii] mod 16) then planet^[ofsy,ofsx]:=1
      else planet^[ofsy,ofsx]:=landform^[j2,ii]-alt;
endcheck:
    end;
  end;
 mousehide;
 for i:=1 to 120 do
  scrto_move(planet^[i],screen[i+12,28],30*4);
 mouseshow;
 inc(c);
 if c>240 then c:=c-240;
end;

procedure makesphere1;
label endcheck;
var
   ii : Integer;
begin
   ofsy:=5+offset;
   for i:=6 to spherei do
   begin
      ii := 60 * i div spherei;
      inc(ofsy);
      ofsx:=pm[i]+offset;
      part4:=0;
      for j:=1 to xw do
      begin
	 part4:=part4+ppart[i];
	 index:=round(part4);
	 if index>xw then goto endcheck;
	 inc(ofsx);
	 if ecl>170 then
	 begin
	    if j=1 then alt:=10
	    else alt:=(index-ecl+186) div 2;
	 end
	 else if ecl<171 then
	 begin
	    if index=xw then alt:=10
	    else alt:=(ecl-index) div 2;
	 end
	 else alt:=0;
	 if alt<0 then alt:=0;
	 j2:=index+c;
	 if j2>240 then j2:=j2-240;
	 z:=colorlookup[landform^[j2,ii]];
	 if (z=waterindex) and (alt<6) then planet^[ofsy,ofsx]:=waterindex+6-alt
	 else if z=waterindex then planet^[ofsy,ofsx]:=waterindex
	 else if z >= 247 then
	    planet^[ofsy,ofsx] := 116
	 else
	 begin
	    if z<6 then
	    begin
	       if alt>spcindex2[z] then z:=1 else z:=spcindex[z]-alt;
	    end
	    else if z<32 then
	    begin
	       if z>alt then z:=z-alt else z:=1;
	    end;
	    planet^[ofsy,ofsx]:=z;
	 end;
endcheck:
      end;
   end;
end;

procedure makesphere2;
label endcheck;
var
   ii : Integer;
begin
 ofsy:=spherei+offset;
 for i:=spherei+1 to maxspherei do
   begin
    ii := 60 * i div spherei;
    inc(ofsy);
    ofsx:=pm[i]+offset;
    part4:=0;
    for j:=1 to xw do
     begin
      part4:=part4+ppart[i];
      index:=round(part4);
      if index>xw then goto endcheck;
      inc(ofsx);
      if ecl>170 then
       begin
        if j=1 then alt:=10
         else alt:=(index-ecl+186) div 2;
       end
       else if ecl<171 then
        begin
         if index=xw then alt:=10
          else alt:=(ecl-index) div 2
        end
       else alt:=0;
      if alt<0 then alt:=0;
      j2:=index+c;
      if j2>240 then j2:=j2-240;
      z:=colorlookup[landform^[j2,ii]];
      if (z=waterindex) and (alt<6) then planet^[ofsy,ofsx]:=waterindex+6-alt
       else if z=waterindex then planet^[ofsy,ofsx]:=waterindex
       else if z >= 247 then
	  planet^[ofsy,ofsx] := 116
       else
        begin
         if z<6 then
          begin
           if alt>spcindex2[z] then z:=1 else z:=spcindex[z]-alt;
          end
         else if z<32 then
          begin
           if z>alt then z:=z-alt else z:=1;
          end;
         planet^[ofsy,ofsx]:=z;
        end;
endcheck:
     end;
   end;
end;

procedure makesphere3;
begin
 mousehide;
 for i:=1 to 120 do
  scrto_move(planet^[i],screen[i+12,28],30*4);
 mouseshow;
 inc(c);
 if c>240 then c:=c-240;
end;

procedure makesphere;
begin
   makesphere1;
   makesphere2;
   {rendersphere(60, 60, spherei, c * 360.0 / 240, true, ecl * 360.0 / 240);}
   makesphere3;
end;

procedure makestar;
label endcheck;
begin
 for i:=6 to 2*r2+4 do
  begin
   ofsy:=i+offset;
   ofsx:=pm[i]+offset;
   part4:=0;
   for j:=1 to xw do
    begin
     part4:=part4+ppart[i];
     index:=round(part4);
     if index>xw then goto endcheck;
     inc(ofsx);
     if (index+c)>240 then j2:=index+c-240
      else j2:=index+c;
     if j=1 then alt:=6
      else if index=xw then alt:=6
     else alt:=0;
     if alt>(landform^[j2,i] mod 16) then planet^[ofsy,ofsx]:=landform^[j2,i] div 16
      else planet^[ofsy,ofsx]:=landform^[j2,i]-alt;
    end;
endcheck:
   end;
 mousehide;
 for i:=1 to 120 do
  scrto_move(planet^[i],screen[i+12,28],30*4);
 mouseshow;
 inc(c);
 if c>240 then c:=c-240;
end;

procedure msg1(m: word);
begin
 if msg=100+m then exit;
 tcolor:=45;
 bkcolor:=0;
 mousehide;
 printxy(208,128,menunames[m]);
 mouseshow;
 bkcolor:=3;
 msg:=100+m;
end;

procedure msg2;
begin
 if cube=msg then exit;
 tcolor:=45;
 bkcolor:=0;
 mousehide;
 printxy(208,128,cubefaces[cube]);
 mouseshow;
 bkcolor:=3;
 msg:=cube;
end;

procedure findmouse;
var
   y : Integer;
{   s : string[4];}
begin
 if not mouse.getstatus then
  begin
   case mouse.x of
    215..231: case mouse.y of
               145..159: msg1(cube*9);
               160..174: msg1(cube*9+3);
               175..189: msg1(cube*9+6);
               else if cube<>msg then msg2;
              end;
    232..248: case mouse.y of
               145..159: msg1(cube*9+1);
               160..174: msg1(cube*9+4);
               175..189: msg1(cube*9+7);
               else if cube<>msg then msg2;
              end;
    249..265: case mouse.y of
               145..159: msg1(cube*9+2);
               160..174: msg1(cube*9+5);
               175..189: msg1(cube*9+8);
               else if cube<>msg then msg2;
              end;
    else if cube<>msg then msg2;
   end;
   exit;
  end;
 oldcube:=cube;
 case mouse.x of
   27..143: if ((viewmode2=1) or (viewmode2=2)) and (mouse.y<124) and (mouse.y>16) then
             targetstar(mouse.x,mouse.y);
  184..202: case mouse.y of
             149..159: if cube<>0 then rotatecube(cube,0,false);
             161..171: if cube<>1 then rotatecube(cube,1,false);
             173..183: if cube<>2 then rotatecube(cube,2,false);
            end;
  276..294: case mouse.y of
             149..159: if cube<>3 then rotatecube(cube,3,false);
             161..171: if cube<>4 then rotatecube(cube,4,false);
             173..183: if cube<>5 then rotatecube(cube,5,false);
            end;
  215..231: case mouse.y of
             145..159: processcube(cube*9);
             160..174: processcube(cube*9+3);
             175..189: processcube(cube*9+6);
            end;
  232..248: case mouse.y of
             145..159: processcube(cube*9+1);
             160..174: processcube(cube*9+4);
             175..189: processcube(cube*9+7);
            end;
  249..265: case mouse.y of
             145..159: processcube(cube*9+2);
             160..174: processcube(cube*9+5);
             175..189: processcube(cube*9+8);
            end;
  161..171: case mouse.y of
             148..156: begin
                        if textindex>1 then dec(textindex);
                        displaytextbox(false);
                       end;
             158..182: begin
                        textindex:=mouse.y-157;
                        displaytextbox(false);
                       end;
             185..192: begin
                        if textindex<25 then inc(textindex);
                        displaytextbox(false);
                       end;
            end;
     0..8: if mouse.y>182 then
            begin
             if alert<ALRT_COMBAT then
              begin
               armweapons;
               raiseshields;
              end
             else
              begin
               powerdownweapons;
               lowershields;
              end;
            end;
  300..313: case mouse.y of
             19..38: if viewmode<>1 then
                      begin
                       cleanright(true);
                       readystatus;
                       if clickcode=3 then
                        begin
                         clickcode:=0;
                         {$IFNDEF DEMO}
                         easteregg5;
                         {$ENDIF}
                        end;
                      end;
             49..58: if viewmode<>1 then
                      begin
                       cleanright(true);
                       readystatus;
                       if clickcode=2 then clickcode:=3 else clickcode:=0;
                      end;
             69..78: if viewmode<>1 then
                      begin
                       cleanright(true);
                       readystatus;
                       if clickcode=1 then clickcode:=2 else clickcode:=0;
                      end;
             89..98: if viewmode<>1 then
                      begin
                       cleanright(true);
                       readystatus;
                       if clickcode=0 then clickcode:=1;
                      end;
             else clickcode:=0;
            end;
  else clickcode:=0;
 end;
 if panelon then
  begin
   if (mouse.y>8) and (mouse.y<24) and (mouse.x>153) and (mouse.x<291)
    then command:=(mouse.x-137) div 17
   else
   case viewmode of
     2: if (viewlevel=0) and (mouse.x>165) and (mouse.x<279) and (mouse.y>31) and (mouse.y<116) then
         begin
          i:=((mouse.y-32) div 7);
          j:=1;
          repeat
           if ship.gunnodes[j]>0 then dec(i);
           inc(j);
          until (j>10) or (i<1);
          if j<11 then viewindex:=j-1;
         end;
     3: if (viewlevel=0) and (mouse.x>165) and (mouse.x<279) and (mouse.y>37)
         and (mouse.y<116) then
         begin
          if mouse.y<74 then i:=-6+((mouse.y-38) div 6)
           else i:=((mouse.y-74) div 6);
          if i<0 then
           begin
            repeat
             dec(target);
             if nearby[target].index>0 then inc(i);
            until (target<1) or (i=0);
            if target<1 then
             begin
              target:=1;
              while nearby[target].index=0 do inc(target);
             end;
           end
          else if i>0 then
           begin
            repeat
             inc(target);
             if nearby[target].index>0 then dec(i);
            until (target>nearbymax) or (i=0);
            if target>nearbymax then
             begin
              target:=nearbymax;
              while nearby[target].index=0 do dec(target);
             end;
           end;
         end;
     4: if viewlevel=0 then
         begin
          case mouse.y of
             61..68: viewindex:=1;
             70..74: if (mouse.x>172) and (mouse.x<274) then
                      begin
                       viewindex:=1;
                       ship.shieldopt[SHLD_LOWERED_WANT]:=mouse.x-173;
                      end;
             79..86: viewindex:=2;
             88..92: if (mouse.x>172) and (mouse.x<274) then
                      begin
                       viewindex:=2;
                       ship.shieldopt[SHLD_ALERT_WANT]:=mouse.x-173;
                      end;
            97..104: viewindex:=3;
           106..110: if (mouse.x>172) and (mouse.x<274) then
                      begin
                       viewindex:=3;
                       ship.shieldopt[SHLD_COMBAT_WANT]:=mouse.x-173;
                      end;
          end;
         end
        else if (viewlevel=2) and (viewindex2>0) and (mouse.x>165) and (mouse.x<279) and (mouse.y>37)
         and (mouse.y<116) then
         begin
          if mouse.y<74 then i:=-6+((mouse.y-38) div 6)
           else i:=((mouse.y-74) div 6);
          if i<0 then
           begin
            repeat
             dec(viewindex2);
             if (ship.cargo[viewindex2]>=ID_NOSHIELD) and (ship.cargo[viewindex2]<ID_NOTHING-1) then inc(i);
            until (viewindex2<1) or (i=0);
            if viewindex2<1 then
             begin
              viewindex2:=1;
              while (ship.cargo[viewindex2]<ID_NOSHIELD) or (ship.cargo[viewindex2]>=ID_NOTHING) do inc(viewindex2);
             end;
           end
          else if i>0 then
           begin
            repeat
             inc(viewindex2);
             if (ship.cargo[viewindex2]>=ID_NOSHIELD) and (ship.cargo[viewindex2]<ID_NOTHING-1) then dec(i);
            until (viewindex2>250) or (i=0);
            if viewindex2>250 then
             begin
              viewindex2:=250;
              while (ship.cargo[viewindex2]<ID_NOSHIELD) or (ship.cargo[viewindex2]>=ID_NOTHING) do dec(viewindex2);
             end;
           end;
        end;
     5: if (mouse.x>165) and (mouse.x<279) and (mouse.y>31) then
         begin
          if viewlevel=1 then
           case mouse.y of
            36..49: viewindex:=1;
            63..76: viewindex:=2;
            90..103: viewindex:=3;
           end
          else if viewlevel=2 then
           begin
            i:=((mouse.y-46) div 7);
            if (ship.engrteam[viewindex].jobtype=JOBTYPE_REPAIR) and (i<9) then
             begin
              j:=ship.engrteam[viewindex].job;
              bkcolor:=5;
              printxy(159+6*viewindex,46+j*7,' ');
              ship.engrteam[viewindex].job:=i;
              with ship.engrteam[viewindex] do
               case job of
                   0: timeleft:=0;
                1..7: if ship.damages[job]>0 then timeleft:=ship.damages[job]*70+random(30);
                   8: if ship.hullintegrity<ship.hullmax then timeleft:=(ship.hullmax-ship.hullintegrity)*30+random(40);
               end;
             end;
           end;
         end;
     6: if (mouse.x>165) and (mouse.x<279) and (mouse.y>37) and (mouse.y<116) then
          viewindex:=(mouse.y-27) div 9;
     7: if (viewlevel=0) and (viewindex>0) and (mouse.x>165) and (mouse.x<279) and (mouse.y>37)
         and (mouse.y<116) then
         begin
          if mouse.y<74 then i:=-6+((mouse.y-38) div 6)
           else i:=((mouse.y-74) div 6);
          if i<0 then
           begin
            repeat
             dec(viewindex);
             if systems[viewindex].visits>0 then inc(i);
            until (viewindex<1) or (i=0);
            if viewindex<1 then
             begin
              viewindex:=1;
              while (systems[viewindex].visits=0) do inc(viewindex);
             end;
           end
          else if i>0 then
           begin
            repeat
             inc(viewindex);
             if systems[viewindex].visits>0 then dec(i);
            until (viewindex>250) or (i=0);
            if viewindex>250 then
             begin
              viewindex:=250;
              while (systems[viewindex].visits=0) do dec(viewindex);
             end;
           end;
         end;
     8: targetplanet(mouse.x,mouse.y);
    10: if viewlevel=0 then
         findgunnode(mouse.x,mouse.y)
        else if (mouse.x>34) and (mouse.x<136) and (mouse.y>31) and (mouse.y<114) then
         begin
          if mouse.y<68 then i:=-5+((mouse.y-38) div 6)
           else i:=((mouse.y-68) div 6);
          if i<0 then
           begin
            repeat
             dec(viewindex2);
             if (ship.cargo[viewindex2]>=ID_DIRK) and (ship.cargo[viewindex2]<ID_NOSHIELD-1) then inc(i);
            until (viewindex2<1) or (i=0);
            if viewindex2<1 then
             begin
              viewindex2:=1;
              while (viewindex2<251) and ((ship.cargo[viewindex2]<ID_DIRK) or (ship.cargo[viewindex2]>=ID_NOSHIELD)) do inc(viewindex2);
              if viewindex2=251 then viewindex2:=0;
             end;
           end
          else if i>0 then
           begin
            repeat
             inc(viewindex2);
             if (ship.cargo[viewindex2]>=ID_DIRK) and (ship.cargo[viewindex2]<ID_NOSHIELD-1) then dec(i);
            until (viewindex2>250) or (i=0);
            if viewindex2>250 then
             begin
              viewindex2:=250;
              while (viewindex2>0) and ((ship.cargo[viewindex2]<ID_DIRK) or (ship.cargo[viewindex2]>=ID_NOSHIELD)) do dec(viewindex2);
             end;
           end;
         end;
    11: if (mouse.x>165) and (mouse.x<279) and (mouse.y>37) and (mouse.y<116) then
         begin
          if viewlevel=0 then
           begin
            i:=(mouse.y-31) div 10;
            viewindex:=0;
            repeat
             inc(viewindex);
             if tempplan^[curplan].cache[viewindex]>0 then dec(i);
            until (i<1) or (viewindex=7);
            if (viewindex=7) and (tempplan^[curplan].cache[viewindex]=0) then
             while (viewindex>0) and (tempplan^[curplan].cache[viewindex]=0) do dec(viewindex);
           end
          else if viewlevel=1 then
           begin
            if mouse.y<74 then i:=-6+((mouse.y-38) div 6)
             else i:=((mouse.y-74) div 6);
            if i<0 then
             begin
              repeat
               dec(viewindex2);
               if ship.cargo[viewindex2]>0 then inc(i);
              until (viewindex2<1) or (i=0);
              if viewindex2<1 then
               begin
                viewindex2:=1;
                while ship.cargo[viewindex2]=0 do inc(viewindex2);
               end;
             end
            else if i>0 then
             begin
              repeat
               inc(viewindex2);
               if ship.cargo[viewindex2]>0 then dec(i);
              until (viewindex2>250) or (i=0);
              if viewindex2>250 then
               begin
                viewindex2:=250;
                while ship.cargo[viewindex2]=0 do dec(viewindex2);
               end;
             end;
           end
          else
	  begin
	     y:=(mouse.y-38) div 6;
	     {str(y,s);
	     printxy(0,0,s);}
	     if tempplan^[curplan].state <> 7 then
	     begin
		if incargo(ID_MINEBOT) > 0 then
		   dec(y);
		if y < 0 then begin
		   viewindex2:=1;
		   y:=99;
		end;
		if incargo(ID_MANUFACTORY) > 0 then
		   dec(y);
		if y < 0 then begin
		   viewindex2:=2;
		   y:=99;
		end;
		if incargo(ID_FABRICATOR) > 0 then
		   dec(y);
		if y < 0 then begin
		   viewindex2:=4;
		   y:=99;
		end;
	     end else begin
		if incargo(ID_STARMINER) > 0 then
		   dec(y);
		if y < 0 then begin
		   viewindex2:=5;
		   y:=99;
		end;
	     end;
	     if y > 90 then
	     begin
		mousehide;
		tcolor:=191;
		bkcolor:=5;
		showbotstuff;
		mouseshow;
	     end;
            {if (mouse.y<74) and (incargo(ID_MINEBOT)>0) then viewindex2:=1
             else if (mouse.y<74) then viewindex2:=2
             else if (mouse.y>73) and (incargo(ID_MANUFACTORY)>0) then viewindex2:=2;}
           end;
        end;
   end;
   anychange:=true;
  end;
 if cube<>oldcube then msg2;
 idletime:=0;
end;

{ change alert mode - which really ONLY sets ship.shieldlevel (besides doing checks and displaying messages and changes panic button color) }
procedure setalertmode(mode: integer; do_shields: boolean);
var alt,new, shield_wanted: integer;
begin
 shield_wanted := 0;
 if ship.shield<=ID_NOSHIELD then ship.shieldlevel:=0
 else if mode=ALRT_REST then
  shield_wanted:=ship.shieldopt[SHLD_LOWERED_WANT]
 else if mode=ALRT_ALERT then
  shield_wanted:=ship.shieldopt[SHLD_ALERT_WANT]
 else if mode=ALRT_COMBAT then
  shield_wanted:=ship.shieldopt[SHLD_COMBAT_WANT];

 if ship.armed then mode:=ALRT_COMBAT; { if weapons are still armed, do not drop out of COMBAT mode, even if we drop shields }
 if (not do_shields) and (ship.shieldlevel=ship.shieldopt[SHLD_COMBAT_WANT]) then mode:=ALRT_COMBAT; { if we are powering down weapons, but shields are still in COMBAT mode, remain in COMBAT alert status }

 case alert of
  ALRT_REST: alt:=48;
  ALRT_ALERT: alt:=112;
  ALRT_COMBAT: alt:=80;
 end;
 case mode of
  ALRT_REST: new:=48;
  ALRT_ALERT: new:=112;
  ALRT_COMBAT: new:=80;
 end;
 if alert<>mode then
  plainfadearea(0,184,7,199,new-alt);	{ modifies the color of the panic button in lower left corner of the screen }
 alert:=mode;

 if not do_shields then exit;		{ only set "alert" variable  and panic button color unless do_Shields is true }


 if ship.shieldlevel = shield_wanted then exit;

 if ship.damages[DMG_SHIELD]>25 then
  begin
   tcolor:=94;
   println;
   ship.shieldlevel:=0;
   if ship.damages[DMG_SHIELD]>59 then
    begin
     print('SECURITY: Shield integrity compromised...needs repair');
     exit;
    end
   else
    begin
     print('SECURITY: Shield unstable...');
     if (random(40)+20)<ship.damages[DMG_SHIELD] then
      begin
       print('Failed to adjust shield.');
       exit;
      end;
    end;
  end;

 ship.shieldlevel := shield_wanted;
end;

procedure processkey;
var temp : byte;
    ans	 : char;
   i	 : Integer;
begin
 idletime:=0;
 temp:=0;
 ans:=readkey_nomap;
 case upcase(ans) of
   #0: begin
        ans:=readkey;
        case ans of
         #72		 : command:=3;	{ up }
         #75		 : command:=1;	{ left }
         #77		 : command:=2;	{ right }
         #80		 : command:=4;	{ down }
         #59..#64: begin		{ F1-F6 }
                    temp :=ord(ans)-59;
                    if cube<>temp then
                     begin
                      rotatecube(cube,temp,true);
                      msg2;
                     end;
                    temp :=0;
                   end;
         #16,#45	 : if yesnorequest('Do you want to quit?',0,31) then quit:=true;
{$IFNDEF DEMO}
         #117		 : easteregg4;
         #103		 : easteregg3;
         #126		 : easteregg2; {alt-7}
{$ENDIF}
         #120..#123,#129: begin {alt-1 to 4 and alt-0}
	    if showplanet then
	    begin
	       if ans = #129 then
		  i := 0
	       else
		  i := ord(ans) - 119;
	       GotoOrbit(tempplan^[curplan].system, i);
	    end else begin
	       println;
	       tcolor := 94;
	       print('NAVIGATION: Not near a system.');
	    end;
	 end;
         #49, #25: begin {alt-n and alt-p}
	    if showplanet then
	    begin
	       i := getplanetorbit(curplan);
	       if ans = #49 then
		  inc(i)
	       else
		  dec(i);
	       GotoOrbit(tempplan^[curplan].system, i);
	    end else begin
	       println;
	       tcolor := 94;
	       print('NAVIGATION: Not near a system.');
	    end;
	 end;
	 #48: begin {alt-b} {bot control}
	    rotatecube(cube,1,true);
	    processcube(11);
	 end;
	  #31: begin{alt-s}{planet scan}
	     rotatecube(cube,2,true);
	     processcube(20);
	  end;
	  #22: begin {alt-u}
	     event(42);
	     addcargo(ID_ART_DETONATOR, true);
	     event(24);
	     addcargo(ID_ART_HOMING_DEVICE, true);
	     event(25);
	     event(27);
	     event(30);
	     event(28);
	  end;
          (*#23: begin {alt-i}
	     str(tempplan^[curplan].bots shr 3, s);
	     printxy(0,0,s);
	  end;*)
          (*#22: begin {alt-u}
	     addcargo(ID_STARDIVER, true);
	     addcargo(ID_STARMINER, true);
	  end;*)
          (*#23: begin {alt-i}
	     if yesnorequest('Install fabricator?',0,31) then
		tempplan^[curplan].bots := 4;
	  end;
          #22: begin {alt-u}
	     if yesnorequest('Un-install fabricator?',0,31) then
		tempplan^[curplan].bots := 2;
	  end;*)
        end;
       end;
  '1': command:=6;
  '2': command:=7;
  '3': command:=8;
  '`': bossmode;
  ' ': cleanright(true);
  #10: begin
     tcolor := 47;
     print(GetHeapStats);
  end;
  #27: begin
        if viewmode2>0 then removestarmap;
        cleanright(true);
       end;
  'Q': if cube<>0 then rotatecube(cube,0,true);
  'A': if cube<>1 then rotatecube(cube,1,true);
  'Z': if cube<>2 then rotatecube(cube,2,true);
  'W': processcube(cube*9);
  'E': processcube(cube*9+1);
  'R': processcube(cube*9+2);
  'S': processcube(cube*9+3);
  'D': processcube(cube*9+4);
  'F': processcube(cube*9+5);
  'X': processcube(cube*9+6);
  'C': processcube(cube*9+7);
  'V': processcube(cube*9+8);
  'T': if cube<>3 then rotatecube(cube,3,true);
  'G': if cube<>4 then rotatecube(cube,4,true);
  'B': if cube<>5 then rotatecube(cube,5,true);
  'P': begin
        if alert<ALRT_COMBAT then
         begin
          armweapons;
          raiseshields;
         end
        else
         begin
          powerdownweapons;
          lowershields;
         end;
       end;
 end;
end;

procedure showtime;
var strs: array[1..5] of string[5];
begin
 for j:=1 to 5 do
  begin
   if j=3 then
    begin
     str(ship.stardate[j]:5,strs[j]);
     if ship.stardate[j]<10000 then strs[j,1]:='0';
    end
   else
    begin
     str(ship.stardate[j]:2,strs[j]);
     if ship.stardate[j]<10 then strs[j,1]:='0';
    end;
  end;
 tcolor:=44;
 bkcolor:=0;
 printxy(42,193,strs[3]+'/'+strs[1]+'/'+strs[2]+' '+strs[4]+':'+strs[5]);
 bkcolor:=3;
end;

{procedure disassemble(item: integer);
var cfile: file of createarray;
    temp: ^createarray;
    j,i: integer;
begin
 new(temp);
 assign(cfile,loc_data()+'creation.dta');
 reset(cfile);
 if ioresult<>0 then errorhandler('creation.dta',1);
 read(cfile,temp^);
 if ioresult<>0 then errorhandler('creation.dta',5);
 close(cfile);
 i:=1;
 while (temp^[i].index<>item) and (i<=totalcreation) do inc(i);
 if i>totalcreation then errorhandler('Disassemble error!',6);
 for j:=1 to 3 do
  if not skillcheck(2) then addcargo(ID_WORTHLESS_JUNK)
   else addcargo(temp^[i].parts[j]);
 dispose(temp);
end;}

procedure addtime;
begin
   GameTick(False, 1);
   showtime;
   anychange:=true;
end;

{ NB: almost same duplicate in utils.pas ?? but it seems to work... }
{ adjust wandering aliens relative ship position. Negative "ofs" move them away from us, positive "ofs" bring them closer to us }
procedure adjustwanderer(ofs: integer);
var
   damages : array[1..7] of byte;
   hull	   : Integer;
   i	   : Integer;
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
   if (abs(relx)<500) and (abs(rely)<500) and (abs(relz)<500) and 	{ if ships are close enough... }
      ((action=WNDACT_ATTACK) or (ship.wandering.orders=WNDORDER_ATTACK) or (calc_anger(ship.wandering.anger, ship.wandering.congeniality) > 3)) then	{ ...and there is a reason for fight to happen }
   begin
      if ship.wandering.alienid = 1013 then	{ drones - save state }
      begin
	 for i := 1 to 7 do
	    damages[i] := ship.damages[i];
	 hull := ship.hullintegrity;
      end;
      initiatecombat;
      if ship.wandering.alienid = 1013 then	{ drones - restore state }
      begin
	 for i := 1 to 7 do
	    ship.damages[i] := damages[i];
	 ship.hullintegrity := hull;
      end;
     ship.armed:=true;				{ drop down from COMBAT to ALERT mode after fight, but with weapons armed - we did have them on in battle, and they presumeably charged up. FIXME - unfortunate(?) side effect is that you would have to manually turn disarm weapons to be able to drop out of COMBAT mode. Perhaps better do here the same as in disarm - return energy to batteries and disarm? }
     setalertmode(ALRT_ALERT, true);
     ship.wandering.alienid:=20000;
     checkwandering;
     action:=WNDACT_NONE;
    end;
   if (abs(relx)>23000) or (abs(rely)>23000) or (abs(relz)>23000) then
    begin
     ship.wandering.alienid:=20000;
     if action=WNDACT_RETREAT then
      begin
       println;
       tcolor:=63;
       print('SECURITY: Evasion successful!');
      end;
     action:=WNDACT_NONE;
    end;
  end;
end;

{ NB: almost same duplicate in utils.pas ?? but it seems to work... }
procedure movewandering;
begin
 case action of
  WNDACT_NONE:;
  WNDACT_RETREAT: adjustwanderer(round(-(ship.accelmax div 4)*(100-ship.damages[DMG_ENGINES])/100));	{ negative values = move away }
  WNDACT_ATTACK: adjustwanderer(round((ship.accelmax div 4)*(100-ship.damages[DMG_ENGINES])/100));	{ positive values = move closer }
 end;
 case ship.wandering.orders of
  WNDORDER_ATTACK: if action=WNDACT_MASKING then adjustwanderer(5-random(12)) else adjustwanderer(30);	{ if masking, probably slowly move away, but might be getting closer too: from -6 to +5  }
  WNDORDER_RETREAT: if action=WNDACT_MASKING then adjustwanderer(-50) else adjustwanderer(-70);		{ running away from us is somewhat slower if they don't know where we are }
  WNDORDER_NONE: adjustwanderer(-30);									{ slowly drift away }
 end;
end;

procedure mainloop;
begin
 repeat
  fadestep(FADESTEP_STEP);
  findmouse;
  if fastkeypressed then processkey;
  if not playing then playmod(true,loc_sound()+defaultsong);
  inc(idletime);
  if idletime=2*maxidle then screensaver;
  if ship.wandering.alienid<16000 then movewandering;
  case viewmode2 of
   0: if (showplanet) and (ship.options[OPT_ANIMATION]=1) and (ship.orbiting=0) and ((viewmode<8) or (viewmode>10)) then makestar
       else if (showplanet) and (ship.options[OPT_ANIMATION]=1) and ((viewmode<8) or (viewmode>10)) then
        case sphere of
         1: case glowindex of
	     {1: rendersphere(60, 60, spherei, c * 360.0 / 240, true, ecl * 360.0 / 240);}
             1: makesphere1;
             2: makesphere2;
             3: makesphere3;
            end;
         2: if glowindex=1 then makegasplanet;
        end;
   1: displaystarmap;
   2: displayhistorymap;
   3: displayshortscan;
   4: displaylongscan;
   else errorhandler('invalid viewmode2.',6);
  end;
  if (anychange) or (command>0) then
   begin
    anychange:=false;
    case viewmode of
      0: begin
          delay(tslice);
          anychange:=true;
         end;
      1: displaystatus;
      2: displayweaponinfo(command);
      3: displaysysteminfo(command);
      4: displayshieldopts(command);
      5: displaydamagecontrol(command);
      6: displayoptions(command);
      7: displaylogs(command);
      8: displaysystem(command);
      9: displayshipinfo;
     10: displayconfigure(command);
     11: displaybotinfo(command);
     else errorhandler('invalid viewmode.',6);
    end;
    command:=0;
    checkstats;
   end;
  if batindex<10 then inc(batindex) else
   begin
    batindex:=0;
    addtime;
   end;
  if glowindex<4 then inc(glowindex) else glowindex:=1;
  delay(tslice*FADE_TSLICE_MUL_JOURNEY);
 until quit;
 stopmod;
end;

begin
 clickcode:=0;
 msg:=500;
end.






{

  findmouse
    if not click exit
    process click


  processkey
    get keystroke
    if control key then process control key
     else process key


  mainloop
    repeat
     if keypress do processkey
     findmouse
      .
      .
     processes
      .
      .
     delay
    until quit (done);


  readydata
    initialize

  removedata
    deinitialize


  begin
   readydata
   mainloop
   removedata
  end

}
