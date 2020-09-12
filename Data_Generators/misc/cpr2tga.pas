program cpr2tga;
{ Matija Nalis <mnalis-git@voyager.hr>, GPLv3+ started 2020/09 
  Converts .CPR to .TGA (while preserving palette), on which we can use ImageMagick convert(1) or netpm tga2ppm(1) etc. to convert further - https://en.wikipedia.org/wiki/Truevision_TGA
}

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
    halt(10);
  end;

 has_palette := false;
 fillchar(screen,sizeof(screen),0);
 fillchar(colors,sizeof(colors),0);
 palname := basename + '.pal';
 if FileExists(palname) then
  begin
    writeln ('Loading default pallete from ', palname);
    loadpal (palname);  { load default pallete if it exists }
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
 writeln ('Outputing uncompressed indexed TGA file to ', basename, '.tga');
 savetga(basename, @screen);

 writeln ('Done!');
end.
