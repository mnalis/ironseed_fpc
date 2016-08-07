program generateweapondata;
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
 weapontype=
  record
   damage,energy: integer;
   cents: array[1..4] of byte;
   range: longint;
  end;
var
 weapons: weapontype;
 f: file of weapontype;
 ft: text;
 index,j: integer;
 c: char;
 dummy: string[20];

begin
 assign(f,'\ironseed\data\weapon.dta');
 rewrite(f);
 assign(ft,'\ironseed\makedata\weapon.txt');
 reset(ft);
 readln(ft);
 read(ft,index);
 repeat
  for j:=1 to 12 do read(ft,c);
  read(ft,dummy);
{  read(ft,weapons.name);
  for j:=1 to 20 do weapons.name[j]:=upcase(weapons.name[j]);}
  read(ft,weapons.energy);
  read(ft,weapons.damage);
  for j:=1 to 4 do read(ft,weapons.cents[j]);
  readln(ft,weapons.range);
  read(ft,index);
  write(f,weapons);
  writeln(dummy,'/',weapons.energy,'/',weapons.damage,'/',weapons.cents[1],'/',weapons.cents[2],
   '/',weapons.cents[3],'/',weapons.cents[4],':',weapons.range);
 until index=0;
 close(f);
 close(ft);
end.