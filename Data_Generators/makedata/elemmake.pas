program generatecargodata;
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
   Data Generator: Element names

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

{$PACKRECORDS 1}

type
 elemtype= string[24];
var
 f: file of elemtype;
 ft: text;
 index,j,i: integer;
 c: char;
 elem: elemtype;

begin
 assign(f,'data/elements.dta');
 rewrite(f);
 assign(ft,'Data_Generators/makedata/element.txt');
 reset(ft);
 read(ft,index);
 repeat
  for j:=1 to 4 do read(ft,c);
  elem:='                        ';
  readln(ft,elem);
  elem[0]:=chr(24);
  i:=25;
  repeat
   dec(i);
  until elem[i]<>' ';
  if i<24 then for j:=i+1 to 24 do elem[j]:=' ';
  for j:=1 to 24 do elem[j]:=upcase(elem[j]);
  write(f,elem);
  writeln(elem);
  read(ft,index);
 until index=0;
 close(f);
 close(ft);
end.