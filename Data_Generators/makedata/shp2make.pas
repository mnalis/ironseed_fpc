program shp2make;
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

{*********************************************
   Data Generator: Ship picture parts

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

uses data;

var shipfile: file of shipdistype;
    k: integer;

procedure saveship(index,x1,y1: integer);
var temp: ^shipdistype;
    i,j: integer;
begin
 //writeln ('saving ship ', index);
 new(temp);
 for j:=x1 to x1+57 do
  for i:=0 to 74 do
   temp^[j-x1,i]:=screen[y1+i,j];
 assign(shipfile,'data/shippix.dta');
 reset(shipfile);
 if ioresult<>0 then errorhandler('data/shippix.dta',1);
 seek(shipfile,index);
 if ioresult<>0 then errorhandler('data/shippix.dta',5);
 write(shipfile,temp^);
 if ioresult<>0 then errorhandler('data/shippix.dta',5);
 close(shipfile);
 dispose(temp);
end;

begin
 assign(shipfile,'data/shippix.dta');
 rewrite(shipfile);
 if ioresult<>0 then errorhandler('data/shippix.dta',1);
 
 loadscreen('Data_Generators/makedata/shippart', @screen);
 if ioresult<>0 then errorhandler('Data_Generators/makedata/shippart',1);
 for k:=0 to 8 do
  saveship(k,(k mod 5)*61+3,(k div 5)*77+3);
end.
