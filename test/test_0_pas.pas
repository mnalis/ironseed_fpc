program main;

uses crt, sysutils;

{$L c_utils.o}

type screentype = array[0..199,0..319] of byte;


procedure setrgb256(palnum,r,g,b: byte); cdecl ; external;
procedure SDL_init_video(scr:screentype); cdecl ; external;
procedure line(x1: word; y1:word; x2: word; y2:word);cdecl ; external;

var pas_screen: screentype;
var count, x1,x2,y1,y2: integer;

begin
        writeln ('pascal start');
        pas_screen[10,30] := 31;
        
        setrgb256(31,60,10,20);
	SDL_init_video(pas_screen);
	writeln ('pascal after SDL_init_video');

	for count := 1 to 10 do
	 begin
		Delay(1000);
		x1 := random(320); x2 := random(320); y1 := random(200); y2 := random(200);
		writeln ('line', count,' from ', x1, ',', y1, ' to ', x2, ',', y2);
		line (x1, y1, x2, y2);
         end;
	
	writeln ('pascal end, scr[10,30]=', pas_screen[10,30]);
end.
