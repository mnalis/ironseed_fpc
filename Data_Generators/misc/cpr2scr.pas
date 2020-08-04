program cpr2scr;
{ Matija Nalis <mnalis-git@voyager.hr>, GPLv3+ started 2020/08 }

uses data2;

var basename: String;

begin
 basename := paramstr(1);
 if basename = '' then
  begin
    writeln ('Usage: cpr2scr <BASENAME>');
    writeln (' opens compressed BASENAME.cpr and creates uncompressed BASENAME.scr and BASENAME.pal, on which scr2ppm.pl can be used');
    halt(10);
  end;
 
 writeln ('Loading compressed file ', basename, '.cpr');
 loadscreen(basename, @screen);

 writeln ('Saving uncompressed files ', basename, '.scr and ', basename, '.pal');
 quicksavescreen (basename, @screen, true);

 writeln ('Done!');
end.
