program scr2cpr;
{ Matija Nalis <mnalis-git@voyager.hr>, GPLv3+ started 2020/08 }

uses data2;

var basename: String;

begin
 basename := paramstr(1);
 if basename = '' then
  begin
    writeln ('Usage: scr2cpr <BASENAME>');
    writeln (' opens uncompressed BASENAME.scr and BASENAME.pal, and creates compressed BASENAME.cpr');
    halt(10);
  end;
 
 writeln ('Loading uncompressed files ', basename, '.scr and ', basename, '.pal');
 quickloadscreen(basename, @screen, true);

 writeln ('Saving compressed file ', basename, '.cpr');
 compressfile (basename, @screen);

 writeln ('Done!');
end.
