Unit utils_;

{$L c_utils.o}

Interface

 type
 screentype= array[0..199,0..319] of byte;
 paltype=array[0..255,1..3] of byte;
const
	Pan_Surround=0;
	xorput=1;
	copyput=0;






procedure delay(const MS:Word); cdecl ; external;
procedure setcolor(const Color: Word); cdecl ; external;
procedure rectangle(const x1: word; y1:word; x2: word; y2:word);cdecl ; external;
procedure circle(const x,y,r:word); cdecl ; external;
procedure SDL_init_video(var scr:screentype); cdecl ; external;
procedure set256colors(var pal : paltype); cdecl; external;	// NB: pal is actually constref, but fpc still gives "Hint: (3187) C arrays are passed by reference" then in fpc 3.0.4+dfsg-22 :(
procedure setrgb256(const palnum,r,g,b: byte); cdecl ; external; // set palette
procedure getrgb256(const palnum: byte; var r,g,b:byte); // get palette
procedure stop_video_thread; cdecl ; external;
procedure upscroll(var img:screentype);cdecl ; external;
procedure scale_img(const x0s, y0s, widths, heights, x0d, y0d, widthd, heightd: word; var s, d:screentype);cdecl ; external;	// NB: s is actually constref
function fastkeypressed: boolean;   // not so fast anymore
function key_pressed : byte;cdecl ; external;
function readkey : char;cdecl ; external;
function readkey_utf8 : char;cdecl ; external;
function readkey_nomap : char;cdecl ; external;
procedure all_done;cdecl ; external;
procedure closegraph;   // close video
procedure move_mouse(const x,y:word);cdecl ; external;
procedure setfillstyle(const style,color:word);cdecl ; external;
procedure bar(const x1,y1,x2,y2:word);cdecl ; external;
procedure line(const x1,y1,x2,y2:word);cdecl ; external;
procedure lineto(const x1,y1:word);cdecl ; external;
procedure moveto(const x1,y1:word);cdecl ; external;
procedure pieslice(const x1,y1,phi0,phi1,r: word);cdecl ; external;
procedure setwritemode(const mode: byte); cdecl ; external;

implementation

procedure getrgb256_(const palnum: byte; r,g,b: pointer);  cdecl ; external;// get palette

procedure closegraph;   // close video
begin
    all_done;
//    SDL_Quit();

end;
procedure getrgb256(const palnum: byte; var r,g,b:byte); // get palette
var rp,gp,bp:byte;
begin
	getrgb256_(palnum,@rp,@gp,@bp);
	r:=rp; g:=gp; b:=bp;
end;

function fastkeypressed: boolean;   // not so fast anymore
begin
 fastkeypressed:=boolean(key_pressed);
end;


begin

end.

