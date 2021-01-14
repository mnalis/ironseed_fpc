program makeanimationforchar;
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
   Data Generator: Crewgen ball animation

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

uses data, utils_;
type
 aniscrtype= array[0..34,0..48] of byte;
 aniarray= array[0..30] of aniscrtype;
var
 ani: aniscrtype;
 anifile: file of aniscrtype;
 index,i,j: integer;
 allani: ^aniarray;

begin
 if paramstr(1)='/test' then
 begin
  init_everything;
  loadscreen('data/char',@screen);
  if ioresult<>0 then errorhandler('data/char',1);
  while not fastkeypressed do delay(1);
  readkey;
 end;
 loadscreen('Data_Generators/makedata/charani',@screen);
 if ioresult<>0 then errorhandler('Data_Generators/makedata/charani',1);
 assign(anifile,'data/charani.dta');
 if ioresult<>0 then errorhandler('data/charani.dta',1);
 rewrite(anifile);
 ani[0,0]:=0;		{ move() will initialize it, this is just so compiler does not warn }
 for index:=0 to 29 do
  begin
   for i:=0 to 34 do
     move(screen[i+(index div 6)*35,(index mod 6)*50],ani[i],49);
   write(anifile,ani);
  end;
 index:=0;
  for i:=0 to 34 do
   move(screen[i+(index div 6)*35,(index mod 6)*50],ani[i],49);
  for j:=12 to 35 do
   for i:=1 to 20 do
    ani[i,j]:=0;
 write(anifile,ani);
 reset(anifile);
 new(allani);
 for j:=0 to 30 do
  read(anifile,allani^[j]);
 close(anifile);
 if paramstr(1)='/test' then
 begin
  j:=0;
  repeat
   inc(j);
   if j=31 then j:=0;
   for i:=0 to 34 do
    move(allani^[j,i],screen[i],49);
   delay(150);
  until fastkeypressed;
 end;
 dispose(allani);
end.
