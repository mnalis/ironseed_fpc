program makeship;
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
{$PACKRECORDS 1}

type
 alienshiptype=
  record
   relx,rely,relz,range: longint;
   techlevel,skill,shield,battery,shieldlevel,hulldamage,
    dx,dy,dz,maxhull,accelmax,regen,picx: integer;
   damages: array[1..7] of byte;
   gunnodes: array[1..5] of byte;
   charges: array[1..20] of byte;
  end;
var
 ship: alienshiptype;
 ft: text;
 i,j,a,b: integer;
 f: file of alienshiptype;

procedure display;
begin
 assign(f,'data/ships.dta');
 reset(f);
 assign(ft,'Data_Generators/other/shipdata.txt');
 rewrite(ft);
 for b:=0 to 10 do
  begin
   for a:=1 to 11 do
    begin
     read(f,ship);
     with ship do
      begin
       i:=gunnodes[1]+gunnodes[2]+gunnodes[3]+gunnodes[4];
       writeln(ft,skill,#9,maxhull,#9,shield-1500,#9,accelmax,#9,i);
      end;
    end;
   writeln(ft);
  end;
 close(ft);
 close(f);
end;

begin
 assign(ft,'Data_Generators/makedata/alienshp.txt');
 reset(ft);
 assign(f,'data/ships.dta');
 rewrite(f);
 readln(ft);
 readln(ft);
 readln(ft);
 for b:=0 to 10 do
  begin
   for a:=1 to 11 do
    begin
     read(ft,i);
     ship.techlevel:=i*256;
     read(ft,i);
     ship.techlevel:=ship.techlevel+i;
     read(ft,ship.skill);
     read(ft,ship.shieldlevel);
     read(ft,ship.hulldamage);
     read(ft,ship.accelmax);
     read(ft,ship.regen);
     read(ft,ship.shield);
     for j:=1 to 5 do read(ft,ship.gunnodes[j]);
     fillchar(ship.charges,20,255);
     for i:=0 to 3 do
      for j:=1 to ship.gunnodes[i+1] do
       ship.charges[i*5+j]:=ship.shieldlevel;
     readln(ft,ship.range);
     ship.battery:=32000;
     fillchar(ship.damages,7,0);
     ship.dx:=0;
     ship.maxhull:=ship.hulldamage;
     ship.dy:=0;
     ship.dz:=0;
     write(f,ship);
     writeln(ship.range);
   end;
   readln(ft);
  end;
 close(ft);
 close(f);

 display;

end.
