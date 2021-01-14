program cpr2tga;
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
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

    On Debian systems, the complete text of the GNU General Public
    License, version 3, can be found in /usr/share/common-licenses/GPL-3.
********************************************************************)

{*********************************************
   Data Generator: Converts .CPR to .TGA (while preserving palette),
   on which we can use ImageMagick convert(1) or netpm tga2ppm(1) etc. to convert further - https://en.wikipedia.org/wiki/Truevision_TGA

   Copyright:
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

uses data2, sysutils;

const COLOR_FACTOR = 4;

var basename, palname: String;
    i,j: word;
    temppal: paltype;
    has_palette: boolean;

begin
 basename := paramstr(1);
 if basename = '' then
  begin
    writeln ('Usage: cpr2tga <BASENAME>');
    writeln (' opens compressed BASENAME.cpr (and optionally BASENAME.pal if it exists) and creates uncompressed BASENAME.tga');
    errorhandler('Wrong cmdline usage',6)
  end;

 has_palette := false;
 fillchar(screen,sizeof(screen),0);
 fillchar(colors,sizeof(colors),0);
 palname := basename + '.pal';
 if FileExists(palname) then
  begin
    writeln ('Loading default palette from ', palname);
    loadpal (palname);  { load default palette if it exists }
    has_palette := true;
  end;

 writeln ('Loading compressed file ', basename, '.cpr');
 loadscreen(basename, @screen);
 if (cpr_head.flags and 1)=1 then has_palette:=true;

 if not has_palette then errorhandler(basename+'.cpr does not have palette, and .pal does not exist',5);

 { update brightness and fix TGA R/G/B little-endian ordering }
 temppal[0,1] := 0;	{ move will initialize it, this is just to keep compiler warnings happy }
 move(colors,temppal,sizeof(paltype));
 for i:=0 to 255 do
   for j:=1 to 3 do
     begin
       assert (colors[i,j] * COLOR_FACTOR <= 255, 'pal value too big');
       colors[i,j] := temppal[i,4-j] * COLOR_FACTOR;
     end;

 { write TARGA to disk }
 writeln ('Outputing ', cpr_head.width,'x', cpr_head.height,' uncompressed indexed TGA file to ', basename, '.tga');
 savetga(basename, @screen);

 writeln ('Done!');
end.
