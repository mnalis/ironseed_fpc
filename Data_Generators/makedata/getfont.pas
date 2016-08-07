program getfontfromfile;
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

uses crt,graftool;

var
 ft: text;

procedure getfont(y1: integer);
var a,x,i,j,b: integer;
    d: array[0..2] of byte;
begin
 write(ft,'(');
 b:=-1;
 for a:=0 to 83 do
  begin
   inc(b);
   if b=5 then
    begin
     writeln(ft);
     b:=0;
    end;
   if a=56 then inc(y1,10);
   if a<56 then x:=a*5
    else x:=(a-56)*5;
   d[0]:=0; d[1]:=0; d[2]:=0;
   for i:=0 to 5 do
    for j:=0 to 3 do
     begin
      if screen[i+y1,x+j]=31 then
       d[i div 2]:=d[i div 2] or (1 shl (7-(j+(i mod 2)*4)));
     end;
   write(ft,'(',d[0],',',d[1],',',d[2],')');
   if a<83 then write(ft,',');
  end;
 writeln(ft,')');
end;

procedure getfont2(y1: integer);
var a,x,i,j,b: integer;
    d: array[0..7] of byte;
begin
 write(ft,'(');
 b:=-1;
 for a:=0 to 83 do
  begin
   inc(b);
   if b=4 then
    begin
     writeln(ft);
     b:=0;
    end;
   if (a mod 28=0) and (a>0) then inc(y1,10);
   if a<28 then x:=a*9
    else if a<56 then x:=(a-28)*9
    else x:=(a-56)*9;
   fillchar(d,8,0);
   for i:=0 to 7 do
    for j:=0 to 7 do
     begin
      if screen[i+y1,x+j]=31 then
       d[i]:=d[i] or (1 shl (7-j));
     end;
   write(ft,'(',d[0],',',d[1],',',d[2],',',d[3],',',d[4],',',d[5],',',d[6],',',d[7],')');
   if a<83 then write(ft,',');
  end;
 writeln(ft,')');
end;

begin
 setvidmode($13);
 loadscreen('font0',@screen);
 set256colors(colors);
 assign(ft,'fontdata');
 rewrite(ft);
 getfont(0);
 writeln(ft);
 getfont(20);
 writeln(ft);
 getfont(40);
 writeln(ft);
 getfont2(60);
 writeln(ft);
 getfont2(90);
 close(ft);
 readkey;
 setvidmode($03);
end.