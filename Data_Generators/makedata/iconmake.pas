program convertplanicons;
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

uses crt, data;

type
 weaponicontype= array[0..19,0..19] of byte;

var
 ft: file of smallbuffer;
 fw: file of weaponicontype;
 t: ^smallbuffer;
 s: pscreentype;
 w: ^weaponicontype;
 i,j,a: integer;

begin
 new(t);
 new(w);
 set256colors(colors);
 new(s);
 loadscreen('makedata\planicon',s);

 assign(ft,'data\planicon.dta');
 rewrite(ft);
 move(s^,t^,sizeof(smallbuffer));
 write(ft,t^);
 close(ft);

 assign(fw,'data\weapicon.dta');
 rewrite(fw);
 for a:=0 to 80 do
  begin
   for i:=0 to 19 do
    move(s^[i+10+(a div 15)*20,(a mod 15)*20],w^[i],20);
   write(fw,w^);
   for i:=0 to 19 do
    move(w^[i],screen[i],20);
  end;
 for a:=0 to 5 do
  begin
   for i:=0 to 19 do
    move(s^[i+110,a*20],w^[i],20);
   write(fw,w^);
   for i:=0 to 19 do
    move(w^[i],screen[i],20);
  end;
 for a:=0 to 2 do
  begin
   for i:=0 to 19 do
    move(s^[i+130,a*16],w^[i],20);
   write(fw,w^);
   for i:=0 to 19 do
    move(w^[i],screen[i],20);
  end;
 close(fw);
 dispose(s);
end.