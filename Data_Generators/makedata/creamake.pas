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
    along with Ironseed.  If not, see <http://www.gnu.org/licenses/>.
********************************************************************)

uses crt;

const
 maxcreation= 123;
 maxcargo= 145;

type
 creationtype=
  record
   index: integer;
   name: string[20];
   parts: array[1..3] of integer;
   levels: array[1..6] of byte;
  end;
 createarraytype=array[1..maxcreation] of creationtype;
 cargotype=
  record
   name: string[20];
   size,index: integer;
  end;
 cargoarray= array[1..maxcargo] of cargotype;
var
 f: file of creationtype;
 create: creationtype;
 ft: text;
 index,j,total: integer;
 c: char;
 ca: ^createarraytype;
 cr: ^cargoarray;

function getworth(item: integer): integer;
var i,j,worth: integer;
begin
 i:=0;
 worth:=0;
 case item of
        3000: worth:=27;
        4000: worth:=9;
        4020: worth:=1;
  5000..5999: worth:=3;
  1000..1499: begin i:=1; worth:=4; end;
  1500..1599: begin i:=1; worth:=6; end;
  2000..2999: begin i:=1; worth:=4; end;
  3001..3999: begin i:=1; worth:=3; end;
  4000..4999: begin i:=1; worth:=2; end;
 end;
 if i=1 then
  begin
   while ca^[i].index<>item do inc(i);
   for j:=1 to 3 do
    if ca^[i].parts[j]>4999 then inc(worth)
    else worth:=worth+getworth(ca^[i].parts[j]);
  end;
 getworth:=worth;
end;

procedure getlist;
var f: file of createarraytype;
    f2: file of cargoarray;
    j,i,a,b: integer;
    ft: text;
begin
 new(ca);
 new(cr);
 assign(f,'data\creation.dta');
 reset(f);
 read(f,ca^);
 close(f);
 assign(f2,'data\cargo.dta');
 reset(f2);
 read(f2,cr^);
 close(f2);
 assign(ft,'other\itemdata.txt');
 rewrite(ft);
 writeln(ft,'    ITEM TO CREATE             PART #1             PART #2              PART#3 WORTH LEVELS            ');
 writeln(ft,'------------------ ------------------- ------------------- ------------------- ----- ------------------');
 for j:=1 to maxcreation do
  begin
{   i:=1;
   while (i<7) and (ca^[j].levels[i]<6) do inc(i);
   if i=7 then
    begin}
     write(ft,ca^[j].name,#9);
     for i:=1 to 3 do
      begin
       a:=1;
       while (cr^[a].index<>ca^[j].parts[i]) and (a<maxcargo-1) do inc(a);
       write(ft,cr^[a].name,#9);
      end;
     a:=getworth(ca^[j].index);
     write(ft,a,#9);
     for i:=1 to 6 do
      write(ft,ca^[j].levels[i],#9);
     writeln(ft);
   end;
{  end;}
 dispose(cr);
 dispose(ca);
 close(ft);
end;

begin
 assign(f,'data\creation.dta');
 rewrite(f);
 assign(ft,'makedata\creation.txt');
 reset(ft);
 total:=0;
 repeat
  inc(total);
  read(ft,create.index);
  for j:=1 to 5 do read(ft,c);
  read(ft,create.name);
  for j:=1 to 3 do read(ft,create.parts[j]);
  for j:=1 to 5 do read(ft,create.levels[j]);
  writeln(create.name);
  readln(ft,create.levels[6]);
  write(f,create);
 until total=maxcreation;
 close(f);
 close(ft);
{}
 getlist;
end.
