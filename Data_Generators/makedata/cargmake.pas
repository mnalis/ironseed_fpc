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

const
 maxcargo= 145;
type
 cargotype=
  record
   name: string[20];
   size,index: integer;
  end;
var
 cargo: cargotype;
 f: file of cargotype;
 ft: text;
 index,j,i: integer;
 c: char;

begin
 assign(f,'data/cargo.dta');
 rewrite(f);
 assign(ft,'makedata/cargo.txt');
 reset(ft);
 readln(ft);
 for i:=1 to maxcargo do
  begin
   read(ft,cargo.index);
   for j:=1 to 5 do read(ft,c);
   read(ft,cargo.name);
   readln(ft,cargo.size);
   write(f,cargo);
   writeln(cargo.name,'/',cargo.index,'/',cargo.size);
  end;
 close(f);
 close(ft);
end.
