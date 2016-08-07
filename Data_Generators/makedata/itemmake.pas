program getiteminfostuff;
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

type
 iteminfotype=
  record
   index: integer;
   info: array[0..3] of string[28];
  end;
var
 iteminfo: iteminfotype;
 f: file of iteminfotype;
 ft: text;
 i,j,count: integer;

begin
 assign(ft,'makedata\iteminfo.txt');
 reset(ft);
 assign(f,'data\iteminfo.dta');
 rewrite(f);
 readln(ft,iteminfo.index);
 count:=0;
 repeat
  for i:=0 to 3 do
   begin
    readln(ft,iteminfo.info[i]);
    if iteminfo.info[i,0]<chr(28) then
     for j:=length(iteminfo.info[i])+1 to 28 do
      iteminfo.info[i,j]:=' ';
    iteminfo.info[i,0]:=chr(28);
   end;
  inc(count);
  writeln(count,':',iteminfo.index);
{  for i:=0 to 3 do
   for j:=1 to 28 do
    iteminfo.info[i,j]:=upcase(iteminfo.info[i,j]); }
  for i:=0 to 3 do writeln(iteminfo.info[i]);
  readln(ft);
  write(f,iteminfo);
  readln(ft,iteminfo.index);
  writeln;
 until iteminfo.index=0;
 close(ft);
 close(f);
end.