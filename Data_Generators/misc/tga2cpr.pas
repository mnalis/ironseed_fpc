program tga2cpr;
{ Matija Nalis <mnalis-git@voyager.hr>, GPLv3+ started 2020/09 
  Converts .TGA back to .CPR (while preserving palette) - https://en.wikipedia.org/wiki/Truevision_TGA
}


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
 writeln ('Saving compressed file ', basename, '.cpr with flags=', flags,' w=',w,' h=',h);
 compressfile (basename, @screen,w,h,flags);

 writeln ('Done!');
end.
