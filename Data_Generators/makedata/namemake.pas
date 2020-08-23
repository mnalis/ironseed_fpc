program namemake;
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
 nametype= string[15];
var
 i,j: integer;
 name: nametype;
 ft: text;
 f: file of nametype;

begin
 assign(ft,'Data_Generators/makedata/newnames.txt');
 reset(ft);
 assign(f,'data/planname.txt');
 rewrite(f);
 for i:=1 to 750 do
  begin
   readln(ft,name);
   if length(name)<15 then
    for j:=length(name)+1 to 15 do name[j]:=' ';
   name[0]:=#12;
   write(f,name);
   writeln(name);
  end;
 close(ft);
 close(f);
end.

