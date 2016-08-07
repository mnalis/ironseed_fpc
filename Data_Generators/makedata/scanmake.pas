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

type
 cargotype=
  record
   name: string[20];
   size,index: integer;
  end;
 scantype= array[1..12] of byte;
var
 cargo: cargotype;
 f: file of scantype;
 ft: text;
 index,j,i: integer;
 c: char;
 scan: scantype;

begin
 {assign(f,'\ironseed\data\scan.dta');
 reset(f);
 assign(ft,'\ironseed\makedata\scandata.txt');
 reset(ft);}
 assign(f,'data/scan.dta');
 rewrite(f);
 assign(ft,'makedata/scandata.txt');
 reset(ft);
 for i:=1 to 17 do
  begin
   for j:=1 to 11 do read(ft,scan[j]);
   readln(ft,scan[12]);
   write(f,scan);
  end;
 close(f);
 close(ft);
end.
