program displaysystems;
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


uses crt;

type
 nametype= string[12];
type
 oldsystype= record
   x,y,z,lastdate,visits,numplanets: integer;
  end;
var
 a,i,j,index: integer;
 f: file of nametype;
 ft: text;
 t: array[1..250] of nametype;
 f2: file of oldsystype;
 s: array[1..250] of oldsystype;
 tempt: nametype;
 temps: oldsystype;

procedure display;
begin
 assign(f,'data/sysname.dta');
 reset(f);
 assign(f2,'data/sysset.dta');
 reset(f2);
 assign(ft,'other/sysdata.txt');
 rewrite(ft);
 for a:=1 to 250 do
  begin
   read(f,t[a]);
   read(f2,s[a]);
  end;

 for i:=1 to 250 do
  begin
   index:=i;
   for j:=i to 250 do if t[j]<t[index] then index:=j;

   tempt:=t[index];
   t[index]:=t[i];
   t[i]:=tempt;

   temps:=s[index];
   s[index]:=s[i];
   s[i]:=temps;

  end;

 for a:=1 to 250 do
   writeln(ft,t[a],#9'(',(s[a].x/10):0:1,',',(s[a].y/10):0:1,',',(s[a].z/10):0:1,')');

 close(ft);
 close(f);
 close(f2);
end;


begin
 assign(ft,'makedata/names.txt');
 reset(ft);
 assign(f,'data/sysname.dta');
 rewrite(f);
 textmode(co80);
 for a:=1 to 250 do
  begin
   readln(ft,t[1]);
   if length(t[1])<12 then
    for j:=length(t[1])+1 to 12 do t[1][j]:=' ';
   t[1][0]:=#12;
   write(f,t[1]);
   writeln(t[1]);
  end;
 close(ft);
 close(f);

 display;
 exit;
end.