program tga2cpr;
(********************************************************************
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    On Debian systems, the complete text of the GNU General Public
    License, version 3, can be found in /usr/share/common-licenses/GPL-3.
********************************************************************)

{*********************************************
   Data Generator: Converts .TGA back to .CPR (while preserving palette)
   see https://en.wikipedia.org/wiki/Truevision_TGA for Targa format

   Copyright:
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

uses data2, sysutils;

const COLOR_FACTOR = 4;

var basename: String;
    i,j: word;
    temppal: paltype;
    flags: byte;
    w,h: word;

begin
 basename := paramstr(1);
 if basename = '' then
  begin
    writeln ('Usage: tga2cpr <BASENAME>');
    writeln (' opens somewhat standard BASENAME.tga and creates compressed BASENAME.cpr');
    errorhandler('Wrong cmdline usage',6)
  end;

 flags := 1;
 w := 320;
 h := 200;
 fillchar(screen,sizeof(screen),0);
 fillchar(colors,sizeof(colors),0);

 writeln ('Loading uncompressed file ', basename, '.tga');
 loadtga(basename+'.tga');
 w := tga_head.width;
 h := tga_head.height;

 { update brightness and fix TGA R/G/B little-endian ordering }
 temppal[0,1] := 0;	{ move will initialize it, this is just to keep compiler warnings happy }
 move(colors,temppal,sizeof(paltype));
 
 for i:=0 to 255 do
   for j:=1 to 3 do
     colors[i,j] := temppal[i,4-j] div COLOR_FACTOR;

 { write CPR to disk }
 writeln ('Saving ', w,'x', h,' compressed file ', basename, '.cpr with flags=', flags);
 compressfile (basename, @screen,w,h,flags);

 writeln ('Done!');
end.

