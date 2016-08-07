program makenames;
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

var
 i,j,a,b: integer;
 name: string[13];
 last: char;

begin
 RANDOMIZE;
 for j:=1 to 5000 do
  begin
   a:=1;
   b:=random(11) + 3;
   if random(2)=0 then last:='A' else last:='B';
   name[0]:=chr(b);
   repeat
    case last of
     'A','E','I','O','U','Y': last:=chr(random(26)+65);
     'Q': last:='U';
     else
      begin
       last:=' ';
       while last=' ' do
        begin
         last:=chr(random(26)+65);
         case last of
          'A','E','I','O','U','Y':;
           else last:=' ';
         end;
        end;
      end;
    end;
    name[a]:=last;
    inc(a);
   until a=b;
   writeln(name);
  end;
end.