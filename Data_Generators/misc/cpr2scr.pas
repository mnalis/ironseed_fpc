program cpr2scr;
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
   Data Generator: converts Ironseed compressed .cpr format to Ironseed uncompressed .scr format

   Copyright:
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

uses data2;

var basename: String;

begin
 basename := paramstr(1);
 if basename = '' then
  begin
    writeln ('Usage: cpr2scr <BASENAME>');
    writeln (' opens compressed BASENAME.cpr and creates uncompressed BASENAME.scr and BASENAME.pal, on which scr2ppm.pl can be used');
    errorhandler('Wrong cmdline usage',6)
  end;
 
 fillchar(screen,sizeof(screen),0);

 writeln ('Loading compressed file ', basename, '.cpr');
 loadscreen(basename, @screen);

 if has_pal
 then
  begin
    writeln ('Saving uncompressed files ', basename, '.scr and ', basename, '.pal');
    quicksavescreen (basename, @screen, true);
  end
 else
  begin
    writeln ('Saving uncompressed file ', basename, '.scr');
    quicksavescreen (basename, @screen, false);
  end;

 writeln ('Done!');
end.
