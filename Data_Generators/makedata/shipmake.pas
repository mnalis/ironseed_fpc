program getshipdata;
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
 alienshiptype=
  record
   relx,rely,relz,techlevel,skill,shield,battery,shieldlevel,hulldamage,
   maxhull,accelmax: integer;
   damages: array[1..7] of byte;
   gunnodes: array[1..10] of byte;
   charges: array[1..20] of byte;
  end;
var
 ft: text;
 temp: alienshiptype;
 i,j: integer;

begin
 assign(ft,'makedata\alienship.txt');
 reset(ft);
 readln(ft);
 readln(ft);
 for j:=1 to 88 do
  begin
   read(ft,i);
   temp.techlevel:=i;
   read(ft,i);
   temp.techlevel:=temp.techlevel*256+i;
   read(ft,temp.skill);
   read(ft,temp.shieldlevel);
   read(ft,temp.maxhull);
   temp.hulldamage:=temp.maxhull;
   read(ft,temp.accelmax);




  end;
 close(ft);
end.