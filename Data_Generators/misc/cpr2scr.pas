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
