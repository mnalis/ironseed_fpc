program scr2cpr;
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
   Data Generator: converts Ironseed uncompressed .scr format to Ironseed compressed .cpr format

   Copyright:
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

uses data2, sysutils;

var basename, s: String;
    flags: byte;
    w,h: word;

begin
 basename := paramstr(1);
 if basename = '' then
  begin
    writeln ('Usage: scr2cpr <BASENAME> [flags] [width height]');
    writeln (' opens uncompressed BASENAME.scr and BASENAME.pal, and creates compressed BASENAME.cpr');
    writeln (' default flags=1 include PAL in SCR, flags=0 does not.');
    errorhandler('Wrong cmdline usage',6)
  end;

 flags := 1;
 w := 320;
 h := 200;

 if paramcount > 1 then
  begin
    s := paramstr(2);
    flags := StrToInt(s);
  end;

 if paramcount > 2 then
  begin
    s := paramstr(3);
    w := StrToInt(s);
    s := paramstr(4);
    h := StrToInt(s);
  end;

 fillchar(screen,sizeof(screen),0);

(* if flags and 1>0 then
  begin			// has embedded palette *)
    writeln ('Loading uncompressed files ', basename, '.scr and ', basename, '.pal');
    quickloadscreen(basename, @screen, true);
(*  end
 else
  begin			// no palette
    writeln ('Loading uncompressed file ', basename, '.scr');
    quickloadscreen(basename, @screen, false);
  end;
*)

 writeln ('Saving compressed file ', basename, '.cpr with flags=', flags,' w=',w,' h=',h);
 compressfile (basename, @screen,w,h,flags);

 writeln ('Done!');
end.
