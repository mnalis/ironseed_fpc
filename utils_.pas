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
procedure init_video(var scr:screentype);
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
procedure scr_fillchar(var dest; count: SizeInt; Value: Byte);
procedure scrfrom_move(const source; var dest; count: SizeInt);
procedure scrto_move(const source; var dest; count: SizeInt);
procedure scrfromto_move(const source; var dest; count: SizeInt);

implementation
uses sysutils;

procedure getrgb256_(const palnum: byte; r,g,b: pointer);  cdecl ; external;// get palette
procedure SDL_init_video(var scr:screentype); cdecl ; external;

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

type addr_type = qword;		// NB: word should be enough to hold memory address ?! https://www.tutorialspoint.com/pascal/pascal_pointers.htm
const screen_size = 320*200;
var screen_addr: addr_type;

function _address (const someaddress: pointer): addr_type;
begin
  _address := {$hints-}addr_type(someaddress);{$hints+}		// NB: get rid of "Hint: (4055) Conversion between ordinals and pointers is not portable" unless we find better way to compare memory addresses. We shoud be using FarAddr (fpc 3.2.0+) instaed of "@"/addr() anyway
end;

{ bounds checking fillchar(), when dest is screen[] }
procedure scr_fillchar(var dest; count: SizeInt; Value: Byte);
var dest_addr: addr_type;
begin
 dest_addr := _address(@dest);
 //writeln('dest_addr=', inttohex(dest_addr,16), ' to ', inttohex(dest_addr+count,16), ', screen_addr=', inttohex(screen_addr,16), ' to ', inttohex(screen_addr+screen_size,16));
 assert (dest_addr >= screen_addr, 'scr_fillchar: screen destination below 0');
 assert (dest_addr + count <= screen_addr+screen_size, 'scr_fillchar: screen destination beyond end');
 fillchar(dest, count, value);
end;

{ bounds checking move(), when dest is screen[] }
procedure scrto_move(const source; var dest; count: SizeInt);
var dest_addr: addr_type;
begin
 dest_addr := _address(@dest);
 //writeln('dest_addr=', inttohex(dest_addr,16), ' to ', inttohex(dest_addr+count,16), ', screen_addr=', inttohex(screen_addr,16), ' to ', inttohex(screen_addr+screen_size,16));
 assert (dest_addr >= screen_addr, 'scrto_move: screen destination below 0');
 assert (dest_addr + count <= screen_addr+screen_size, 'scrto_move: screen destination beyond end');
 move (source, dest, count);
end;

{ bounds checking move(), when source is screen[] }
procedure scrfrom_move(const source; var dest; count: SizeInt);
var src_addr: addr_type;
begin
 src_addr := _address(@source);
 //writeln('src_addr=', inttohex(src_addr,16), ' to ', inttohex(src_addr+count,16), ', screen_addr=', inttohex(screen_addr,16), ' to ', inttohex(screen_addr+screen_size,16));
 assert (src_addr >= screen_addr, 'scrfrom_move: screen source below 0');
 assert (src_addr + count <= screen_addr+screen_size, 'scrfrom_move: screen source beyond end');
 move (source, dest, count);
end;

{ bounds checking move(), when source is screen[] }
procedure scrfromto_move(const source; var dest; count: SizeInt);
var src_addr, dest_addr: addr_type;
begin
 src_addr := _address(@source);
 dest_addr := _address(@dest);
 //writeln('src_addr=', inttohex(src_addr,16), ' to ', inttohex(src_addr+count,16), ', screen_addr=', inttohex(screen_addr,16), ' to ', inttohex(screen_addr+screen_size,16));
 assert (src_addr >= screen_addr, 'scrfromto_move: screen source below 0');
 assert (src_addr + count <= screen_addr+screen_size, 'scrfromto_move: screen source beyond end');
 assert (dest_addr >= screen_addr, 'scrto_move: screen destination below 0');
 assert (dest_addr + count <= screen_addr+screen_size, 'scrto_move: screen destination beyond end');
 move (source, dest, count);
end;

procedure init_video(var scr:screentype);
begin
  screen_addr := _address(@scr);
  SDL_init_video(scr);
end;

begin

end.

