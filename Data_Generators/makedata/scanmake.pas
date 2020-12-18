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
   Data Generator: scandata.txt

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

{$PACKRECORDS 1}

type
 scantype= array[1..12] of byte;
var
 f: file of scantype;
 ft: text;
 j,i: integer;
 scan: scantype;

begin
 {assign(f,'data/scan.dta');
 reset(f);
 assign(ft,'Data_Generators/makedata/scandata.txt');
 reset(ft);}
 assign(f,'data/scan.dta');
 rewrite(f);
 assign(ft,'Data_Generators/makedata/scandata.txt');
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
