program scr2cpr;
{ Matija Nalis <mnalis-git@voyager.hr>, GPLv3+ started 2020/08 }

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
    halt(10);
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
  begin			// has embedded pallete *)
    writeln ('Loading uncompressed files ', basename, '.scr and ', basename, '.pal');
    quickloadscreen(basename, @screen, true);
(*  end
 else
  begin			// no pallete
    writeln ('Loading uncompressed file ', basename, '.scr');
    quickloadscreen(basename, @screen, false);
  end;
*)

 writeln ('Saving compressed file ', basename, '.cpr with flags=', flags,' w=',w,' h=',h);
 compressfile (basename, @screen,w,h,flags);

 writeln ('Done!');
end.
