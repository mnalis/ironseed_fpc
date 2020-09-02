program intro;
(********************************************************************
    This file is part of Ironseed.

    Ironseed is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Ironseed is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Ironseed.  If not, see <http://www.gnu.org/licenses/>.
********************************************************************)

//{$M 5500,436000,436000}
//{$S-,D-}

{***************************

  Introduction Sequence for IronSeed

  Channel 7
  Destiny: Virtual

  Copyright 1994

***************************}

uses utils_, sysutils, gmouse, modplay, version, math;
//var   sdl_scr: PSDL_Surface;
{* begin
  SDL_Init(SDL_INIT_VIDEO); // Initialize the video SDL subsystem
  scr:=SDL_SetVideoMode(640, 480, 8, SDL_SWSURFACE); // Create a software window of 640x480x8 and assign to scr

  SDL_Quit; // close the subsystems and SDL
*}

const
 CPR_NONE=0;                    {   0 no compresion            }
// CPR_NOPAL=1;                   {   1 no palette, compressed   }
// CPR_PAL=2;                     {   2 palette, compressed      }
// CPR_HEADERINCL=3;              {   3 header included          }
 CPR_ERROR=255;                 { global error                 }
// CPR_CURRENT=CPR_HEADERINCL;    { current version              }
 CPR_BUFFSIZE=8192;             { adjustable buffer size       }

{$PACKRECORDS 1}
type
 CPR_HEADER=
  record
   signature: word;             {RWM, no version. RM, version  }
   version: byte;
   width,height: word;
   flags,headersize: byte;
  end;
 pCPR_HEADER= ^CPR_HEADER;
type
// paltype=array[0..255,1..3] of byte;
 fonttype= array[0..2] of byte;
 plantype= array[1..120,1..120] of byte;
 landtype= array[1..240,1..120] of byte;
 pscreentype= ^screentype;
 bigfonttype= array[0..7] of byte;
{$PACKRECORDS DEFAULT}
const
 font: array[1..84] of fonttype=
  ((0,0,0),(34,32,32),(85,0,0),(34,0,0),(36,68,32),
   (66,34,64),(9,105,0),(2,114,0),(0,2,36),(0,240,0),
   (0,0,32),(1,36,128),(107,221,96),(38,34,112),(241,248,240),
   (241,113,240),(170,175,32),(248,241,240),(248,249,240),(241,17,16),
   (249,105,240),(249,241,240),(2,2,0),(2,2,36),(18,66,16),
   (15,15,0),(132,36,128),(249,48,32),(249,249,144),(249,233,240),
   (249,137,240),(233,153,224),(248,232,240),(248,232,128),(248,185,240),
   (153,249,144),(114,34,112),(241,25,240),(158,153,144),(136,136,240),
   (159,153,144),(157,185,144),(249,153,240),(249,248,128),(249,155,240),
   (249,233,144),(120,97,224),(242,34,32),(153,153,240),(153,149,32),
   (153,187,96),(153,105,144),(153,241,240),(242,72,240),(9,36,144),
   (8,66,16),(15,155,208),(143,153,240),(15,136,240),(31,153,240),
   (15,188,240),(249,200,128),(15,151,159),(143,153,144),(32,34,32),
   (16,17,159),(137,233,144),(34,34,32),(9,249,144),(14,153,144),
   (15,153,240),(15,153,248),(15,153,241),(15,152,128),(7,66,224),
   (39,34,32),(9,153,240),(9,149,32),(9,155,96),(9,105,144),
   (9,159,31),(15,36,240),(53,170,83),(202,17,172));
 bigfont: array[1..82] of bigfonttype=
  ((0,0,0,0,0,0,0,0),(48,48,48,16,0,48,48,0),(40,40,0,0,0,0,0,0),(8,8,0,0,0,0,0,0),
   (8,16,16,16,16,8,0,0),(32,16,16,16,16,32,0,0),(0,84,16,124,16,84,0,0),(0,16,16,124,16,16,0,0),
   (0,0,0,0,48,48,96,0),(0,0,0,254,254,0,0,0),(0,0,0,0,48,48,0,0),(2,4,8,16,32,64,0,0),
   (124,134,138,146,162,124,0,0),(24,56,8,8,8,126,0,0),(124,130,4,56,64,254,0,0),(124,130,60,2,130,124,0,0),
   (6,10,18,34,126,2,0,0),(254,128,124,2,130,124,0,0),(124,128,188,130,130,124,0,0),(254,2,4,8,8,8,0,0),
   (124,130,124,130,130,124,0,0),(124,130,126,2,130,124,0,0),(0,48,48,0,48,48,0,0),(0,48,48,0,48,48,96,0),
   (2,4,8,8,4,2,0,0),(0,0,124,0,124,0,0,0),(64,32,16,16,32,64,0,0),(56,68,4,24,0,16,0,0),
   (60,66,158,130,130,130,0,0),(252,130,252,130,130,252,0,0),(124,130,128,128,130,124,0,0),(252,130,130,130,130,252,0,0),
   (254,0,248,128,128,254,0,0),(254,128,248,128,128,128,0,0),(124,130,128,134,130,124,0,0),(130,130,130,254,130,130,0,0),
   (254,16,16,16,16,254,0,0),(254,2,2,2,130,124,0,0),(130,130,252,130,130,130,0,0),(128,128,128,128,128,254,0,0),
   (198,170,146,130,130,130,0,0),(248,132,130,130,130,130,0,0),(124,130,130,130,130,124,0,0),(252,130,130,252,128,128,0,0),
   (124,130,130,138,134,124,2,0),(252,130,130,252,130,130,0,0),(124,130,124,2,130,124,0,0),(254,16,16,16,16,16,0,0),
   (130,130,130,130,130,124,0,0),(130,130,130,68,40,16,0,0),(130,130,130,146,170,68,0,0),(130,68,56,68,130,130,0,0),
   (130,130,126,2,130,124,0,0),(124,8,16,32,64,124,0,0),(98,100,8,16,38,70,0,0),(64,32,16,8,4,2,0,0),
   (0,60,66,158,130,130,0,0),(0,254,130,252,130,254,0,0),(0,124,130,128,130,124,0,0),(0,252,130,130,130,252,0,0),
   (0,254,0,224,128,254,0,0),(0,254,128,224,128,128,0,0),(0,124,128,134,130,124,0,0),(0,130,130,254,130,130,0,0),
   (0,254,16,16,16,254,0,0),(0,254,2,2,130,124,0,0),(0,130,130,252,130,130,0,0),(0,128,128,128,128,254,0,0),
   (0,198,170,146,130,130,0,0),(0,248,132,130,130,130,0,0),(0,124,130,130,130,124,0,0),(0,252,130,252,128,128,0,0),
   (0,124,130,138,134,124,2,0),(0,252,130,252,130,130,0,0),(0,126,128,124,2,252,0,0),(0,254,16,16,16,16,0,0),
   (0,130,130,130,130,124,0,0),(0,130,130,68,40,16,0,0),(0,130,130,146,170,68,0,0),(0,130,68,56,68,130,0,0),
   (0,130,130,126,2,252,0,0),(0,124,8,16,32,124,0,0));
var
  tcolor,bkcolor,i,j,z,cursor,permx,permy,code,j2,m,index,alt,ecl,
  r2,c,radius,m1,m2,m3,m4,tslice,water,waterindex,x,ofsx,ofsy: integer;
 keymode: boolean;
 key: char;
 modth,modtm,modts,curth,curtm,curts: byte;
 y,part,part2,c2: real;
 planet: ^plantype;
 landform: ^landtype;
 screen: screentype;
 colors: paltype;
 s1,s2,s3: pscreentype;
 k: word;
// module: pmodule;
 spcindex: array[0..5] of integer;

//{$L mover2}
//{$L mover}
//{$L vga256}
//{$L scroller}
//{$F+}


procedure errorhandler(s: string; errtype: integer);
begin
 closegraph;
 writeln;
 case errtype of
  1: writeln('Open File Error: ',s);
  2: writeln('Mouse Error: ',s);
  3: writeln('Sound Error: ',s);
  4: writeln('EMS Error: ',s);
  5: writeln('Fatal File Error: ',s);
  6: writeln('Program Error: ',s);
  7: writeln('Music Error: ',s);
 end;
 halt(4);
end;


procedure gettime;
var     hh,mm,ss,ms:Word;
begin
  DecodeTime(Now,hh,mm,ss,ms);
  modth:=byte(hh);//h;
  modtm:=byte(mm);//m;
  modts:=byte(ss);//s;
end;

procedure getcurtime;  // get current time
var     hh,mm,ss,ms:Word;
begin
DecodeTime(Now,hh,mm,ss,ms);
curth:=byte(hh);
curtm:=byte(mm);;
curts:=byte(ss);;
end;



procedure wait(s: integer); //wait  s seconds?
var     hh,mm,ss,ms,ss2,mm2,hh2:Word;
        t2:word;
begin
    DecodeTime(Now,hh,mm,ss,ms);
    repeat
        DecodeTime(Now,hh2,mm2,ss2,ms);
        t2:=abs(ss-ss2)+60*abs(mm-mm2)+3600*abs(hh-hh2);
    until(t2>=s);
end;







procedure uncompressfile(s: string; ts: pscreentype; h: pCPR_HEADER);
type
   buftype = array[0..CPR_BUFFSIZE] of byte;
var
   f				  : file;
   err,num,count,databyte,index,x : word;
   total,totalsize,j		  : longint;
   buffer			  : ^buftype;

   procedure handleerror;
   begin
      h^.version:=CPR_ERROR;
      if buffer<>nil then dispose(buffer);
      buffer:=nil;
      close(f);
      j:=ioresult;
   end;

   procedure getbuffer;
   begin
      if total>CPR_BUFFSIZE then num:=CPR_BUFFSIZE else num:=total;
      blockread(f,buffer^,num,err);
//      writeln('readed ',num);
      if (err<num) or (ioresult<>0) then
      begin
	 handleerror;
	 exit;
      end;
      total:=total-num;
      index:=0;
   end;

   function handleversion(n: integer): boolean;
   begin
      handleversion:=false;
      if n<>4 then exit;
      if h^.flags and 1>0 then
      begin
	 num:=768;
	 seek(f,h^.headersize);
	 blockread(f,colors,num,err);
	 if (ioresult<>0) or (num<>err) then exit;
	 total:=filesize(f)-768-h^.headersize;
      end
      else total:=filesize(f)-h^.headersize;
      seek(f,filesize(f)-total);
      if ioresult<>0 then exit;
      handleversion:=true;
   end;

   function checkversion: boolean;
   begin
      checkversion:=false;
      num:=sizeof(CPR_HEADER);
      blockread(f,h^,num,err);
      if (err<num) or (ioresult<>0) or (h^.signature<>19794)
	 or (not handleversion(h^.version)) then exit;
      checkversion:=true;
   end;

   function decode: boolean;
   begin
      decode:=false;
      getbuffer;
      j:=0;
      totalsize:=h^.width;
      totalsize:=totalsize*h^.height;
//      writeln(h^.width,' x ',h^.height,'  = ',totalsize);
      x:=0;
      repeat
	 if buffer^[index]=255 then
	 begin
	    inc(index);
	    if index=CPR_BUFFSIZE then getbuffer;
	    count:=buffer^[index];
	    inc(index);
	    if index=CPR_BUFFSIZE then getbuffer;
	    databyte:=buffer^[index];
	    if j+count>totalsize then count:=totalsize-j;
	    j:=j+count;
	    while count>0 do
	    begin
	       ts^[0,x]:=databyte;
	       inc(x);
	       dec(count);
	    end;
	 end
	 else
	 begin
	    databyte:=buffer^[index];
	    ts^[0,x]:=databyte;
	    inc(j);
	    inc(x);
	 end;
	 inc(index);
	 if index=CPR_BUFFSIZE then getbuffer;
      until j>=totalsize;
      decode:=true;
   end;

begin
   new(buffer);
   assign(f,s);
   reset(f,1);
   if (ioresult<>0) or (not checkversion) then
   begin
      handleerror;
      exit;
   end;
   if h^.version=CPR_NONE then exit;
   if not decode then
   begin
      handleerror;
      exit;
   end;
   close(f);
   if buffer<>nil then dispose(buffer);
end;

procedure loadpalette(s: string);
var palfile: file of paltype;
begin
 assign(palfile,s);
 reset(palfile);
 if ioresult<>0 then errorhandler(s,1);
 read(palfile,colors);
 if ioresult<>0 then errorhandler(s,5);
 close(palfile);
end;

procedure loadscreen(s: string; ts: pointer);
var ftype: CPR_HEADER;
begin
 uncompressfile(s+'.cpr',ts,@ftype);
// writeln('uncompressed');
 if ftype.version=CPR_ERROR then errorhandler(s,5);
end;



procedure printxy(x1,y1: integer; s: string);
var letter,a,x,y,t: integer;
begin
 t:=tcolor;
 x1:=x1+4;               { this stupid offset is pissing me off!!!!}
 for j:=1 to length(s) do
  begin
   tcolor:=t;
   case s[j] of
     'a'..'z': letter:=ord(s[j])-40;
    'A' ..'Z': letter:=ord(s[j])-36;
    ' ' ..'"': letter:=ord(s[j])-31;
    ''''..'?': letter:=ord(s[j])-35;
    '%': letter:=55;
    #1: letter:=83;
    #2: begin
         letter:=84;
         dec(x1);
        end;
    else letter:=1;
   end;
   y:=y1;
   for i:=0 to 5 do
    begin
     x:=x1;
     inc(y);
     for a:=7 downto 4 do
      begin
       inc(x);
       //writeln ('y=', y, ' x=', x, ' mem=', y*320+x, ' c=', s[j]);
       assert (y*320+x < 320*200, 'printxy memory overflow1');
       if font[letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor
        else if bkcolor<255 then screen[y,x]:=bkcolor;
      end;
     dec(tcolor,2);
     x:=x1;
     inc(y);
     inc(i);
     for a:=3 downto 0 do
      begin
       inc(x);
       //assert ((x>=0) and (x<320) and (y>=0) and (y<200), 'printxy coords out of range');
       assert (y*320+x < 320*200, 'printxy memory overflow2');
       if font[letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor
        else if bkcolor<255 then screen[y,x]:=bkcolor;
      end;
     dec(tcolor,2);
    end;
   x1:=x1+5;
   assert ((y1+i)*320+x1 < 320*200, 'printxy memory overflow3');
   if bkcolor<255 then for i:=1 to 6 do screen[y1+i,x1]:=bkcolor;
  end;
 tcolor:=t;
end;

procedure bigprintxy(x1,y1: integer; s: string);
var letter,a,x,y,t: integer;
begin
 t:=tcolor;
 for j:=1 to length(s) do
  begin
   tcolor:=t;
   case s[j] of
     'a'..'z': letter:=ord(s[j])-40;
    'A' ..'Z': letter:=ord(s[j])-36;
    ' ' ..'"': letter:=ord(s[j])-31;
    ''''..'?': letter:=ord(s[j])-35;
    '%': letter:=55;
    else letter:=1;
   end;
   y:=y1;
   for i:=0 to 7 do
    begin
     x:=x1;
     inc(y);
     for a:=7 downto 0 do
      begin
       inc(x);
       assert (y*320+x < 320*200, 'bigprintxy memory overflow');
       if bigfont[letter,i] and (1 shl a)>0 then screen[y,x]:=tcolor
        else if bkcolor<255 then screen[y,x]:=bkcolor;
      end;
     dec(tcolor);
    end;
   x1:=x1+8;
  end;
 tcolor:=t;
end;



procedure readygraph;       // init video
begin
 SetExceptionMask([exInvalidOp, exDenormalized, exPrecision]);   // fix for EDivByZero error in software OpenGL, see https://github.com/mnalis/ironseed_fpc/issues/26
 SDL_init_video(screen);
 loadpalette('data/main.pal');
 set256colors(colors);
end;

procedure fading;
var a,b: integer;
    temppal: paltype;
    px,dx,pdx: array[1..768] of shortint;
begin
 temppal[0,1]:=0;		// to turn off warnings, variables are actually correctly initialized by function below
 move(colors,temppal,sizeof(paltype));
 dx[1]:=0;			// to turn off warnings, variables are actually correctly initialized by function below
 fillchar(dx,sizeof(paltype),48);
 for j:=1 to 768 do
  begin
   px[j]:=colors[0,j] div 48;
   pdx[j]:=colors[0,j] mod 48;
  end;
 b:=tslice shr 1;
 for a:=47 downto 1 do
  begin
   for j:=1 to 768 do
    begin
     dec(temppal[0,j],px[j]);
     dec(dx[j],pdx[j]);
     if (dx[j]<=0) then
      begin
       inc(dx[j],48);
       dec(temppal[0,j]);
      end;
    end;
   set256colors(temppal);
   delay(b);
  end;
 fillchar(temppal,sizeof(paltype),0);
 set256colors(temppal);
end;

procedure fadein;
var a,b: integer;
    temppal: paltype;
    px,dx,pdx: array[1..768] of shortint;
begin
 b:=tslice shr 2;
 temppal[0,1]:=0;       // to turn off warnings, variables are actually correctly initialized by function below
 fillchar(temppal,sizeof(paltype),0);
 dx[1]:=0; 		// to turn off warnings, variables are actually correctly initialized by function below
 fillchar(dx,sizeof(paltype),0);
 for j:=1 to 768 do
  begin
   px[j]:=colors[0,j] div 48;
   pdx[j]:=colors[0,j] mod 48;
  end;
 for a:=1 to 47 do
  begin
   for j:=1 to 768 do
    begin
     inc(temppal[0,j],px[j]);
     inc(dx[j],pdx[j]);
     if (dx[j]>=48) then
      begin
       inc(temppal[0,j]);
       dec(dx[j],48);
      end;
    end;
   set256colors(temppal);
   delay(b);
  end;
 set256colors(colors);
end;

procedure runintro; forward;

procedure blast(c1,c2,c3: integer);
var a,b: integer;
begin
 b:=tslice div 2;
 for a:=1 to 31 do
  begin
   for j:=0 to 255 do
    begin
     colors[j,1]:=colors[j,1] + round(a*(c1-colors[j,1])/31);
     colors[j,2]:=colors[j,2] + round(a*(c2-colors[j,2])/31);
     colors[j,3]:=colors[j,3] + round(a*(c3-colors[j,3])/31);
    end;
   set256colors(colors);
   delay(b);
  end;
 set256colors(colors);
end;

procedure loadstarfield;
begin
 new(s1);
 new(s2);
 new(s3);
 mousehide;
 scrfrom_move(screen,s2^,sizeof(screen));
 mouseshow;
 loadscreen('data/cloud',s1);
end;

procedure startit;
begin
 case cursor of
  1: code:=1;
  2: begin
      dispose(s1);
      dispose(s2);
      dispose(s3);
      fading;
      mousehide;
      scr_fillchar(screen,sizeof(screen),0);
      stopmod;
      runintro;
      playmod(true,'sound/INTRO2.MOD');
      loadstarfield;
      setcolor(207);
     end;
  3: code:=2;
  4: code:=4;
 end;
end;

procedure drawcursor;
begin
 if cursor=0 then exit;
 mousehide;
 case cursor of
  1:rectangle(25,148,159,167);
  2:rectangle(43,168,159,187);
  3:rectangle(159,148,283,167);
  4:rectangle(159,168,267,187);
 end;
 mouseshow;
end;

procedure findmouse;
var button: boolean;
begin
//    writeln(mouse.x,' ',mouse.y, ' ',mouse.getstatus );
 if mouse.getstatus then button:=true else button:=false;
 if (permx<>mouse.x) or (permy<>mouse.y) then keymode:=false;
 if (keymode) and (not button) then exit;
 case mouse.y of
  148..167: case mouse.x of
           25..159: cursor:=1;
           160..283: cursor:=3;
           else cursor:=0;
          end;
  168..187: case mouse.x of
           43..159: cursor:=2;
           160..267: cursor:=4;
           else cursor:=0;
          end;
  else if not keymode then cursor:=0;
 end;
 if (button) and (cursor>0) then startit;
end;

procedure checkkey(c: char);
begin
case c of
  #72: if cursor=0 then cursor:=1
       else if cursor=1 then cursor:=4 else dec(cursor);
  #80: if cursor=0 then cursor:=1
       else if cursor=4 then cursor:=1 else inc(cursor);
  #75: if cursor>2 then cursor:=cursor-2
       else cursor:=cursor+2;
  #77: if cursor>2 then cursor:=cursor-2
       else cursor:=cursor+2;
 end;
end;

procedure mainloop;
var p:pointer;
    ps2,ps3,ps2_,ps3_: ^byte;
    si,di:word;

begin
// writeln('wtf?');
 code:=0;
 cursor:=0;
 keymode:=false;
 playmod(true,'sound/INTRO2.MOD');
 loadstarfield;
 k:=random(32000);
 setcolor(207);
 repeat
  dec(k);
  if k>64000 then k:=k-64000;
{  asm                                // scroll?
   push es
   push ds
   mov ax, [k]
   les di, [s3]
   mov bx, di
   lds si, [s1]
   mov cx, 64000
   sub cx, ax
   add di, ax
   cld
   rep movsb
   mov cx, ax
   mov di, bx
   rep movsb
   pop ds
   push ds
   les si, [s2]
   lds di, [s3]
   mov si, 51453
   mov di, 7210
   xor bl, bl
  @@loopit:
   cmp bl, [es: di]
   je @@black
   mov al, [es: di]
   mov [ds: di], al
  @@black:
   inc di
   dec si
   jnz @@loopit
   pop ds
   pop es
  end;
}

{we should probably typecast this to work under "-Sy" instead of disabling it? see https://wiki.freepascal.org/local_compiler_directives}
{$T-}

    p:=@(s3^);
    move(s1^,(p+k)^,64000-k);
    p:=@(s1^);
    move((p+64000-k)^,s3^,k);
    si:=51453; di:=7210;
    ps2:=@(s2^);
    ps3:=@(s3^);
    repeat
        ps2_:=(@ps2^)+di;
        ps3_:=(@ps3^)+di;
        if(ps2_^>0) then
        begin
            ps3_^:=ps2_^;
        end;
        inc(di);
        dec(si);
    until(si=0);
{$T+}


  mousehide;
  scrto_move(s3^,screen,sizeof(screen));
  mouseshow;
  drawcursor;
  findmouse;
  if fastkeypressed then
   begin
    keymode:=true;
    permx:=mouse.x;
    permy:=mouse.y;
    key:=readkey;
    if key=#0 then checkkey(readkey);
    if key=#13 then startit;
   end;
  delay(tslice);
 until code>0;
 dispose(s1);
 dispose(s2);
 dispose(s3);
 stopmod;
 fading;
 mousehide;

// textmode(co80);
end;

procedure showmars;
var temp: pscreentype;
begin
 fillchar(colors,sizeof(paltype),0);
 set256colors(colors);
 loadscreen('data/cloud',@screen);
 new(temp);
 loadscreen('data/world',temp);
 colors[29]:=colors[0];
 colors[30]:=colors[0];
 set256colors(colors);
 upscroll(temp^);
 dispose(temp);
end;



{function timewait(t: integer): boolean;  // true if t sec. passed since gettime
var i:dword ;
begin
    getcurtime;
    i:=abs(curth-modth)*3600+abs(curtm-modtm)*60+abs(curts-modts);
    if(i>=t) then timewait:=true else timewait:=false;
end;}

procedure dothefade;
var temppal: paltype;
    a: integer;
begin
 temppal[0,1]:=0;		// to turn off warnings, variables are actually correctly initialized by function below
 move(colors,temppal,sizeof(paltype));
 for a:=31 downto 0 do
  begin
   for j:=0 to 31 do
    if j<>31 then
     begin
      for i:=1 to 3 do
       temppal[j,i]:=round(a*colors[j,i]/32);
     end
    else
     begin
      if a>16 then
       begin
        for i:=1 to 3 do
         temppal[31,i]:=round((a-16)*colors[31,i]/16);
       end
      else
       begin
        temppal[31,1]:=round(63/16*(16-a));
       end;
     end;
   set256colors(temppal);
   delay(tslice);
  end;
 move(temppal,colors,sizeof(paltype));
end;

procedure printxy2(x1,y1,tcolor: integer; s: string);
var letter,a,x,y: integer;
begin
 x1:=x1+4;               { this stupid offset is pissing me off!!!!}
 for j:=1 to length(s) do
  begin
   case s[j] of
     'a'..'z': letter:=ord(s[j])-40;
    'A' ..'Z': letter:=ord(s[j])-36;
    ' ' ..'"': letter:=ord(s[j])-31;
    ''''..'?': letter:=ord(s[j])-35;
    '%': letter:=55;
    else letter:=1;
   end;
   y:=y1;
   for i:=0 to 5 do
    begin
     x:=x1;
     inc(y);
     for a:=7 downto 4 do
      begin
       inc(x);
       if font[letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor;
      end;
     x:=x1;
     inc(y);
     inc(i);
     for a:=3 downto 0 do
      begin
       inc(x);
       if font[letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor;
      end;
    end;
   x1:=x1+5;
  end;
end;

procedure writestr2(s1,s2,s3: string);
var i,j1,j2,j3,b: integer;
begin
 scr_fillchar(screen,sizeof(screen),0);
 j1:=156-((length(s1)*5) div 2);
 j2:=156-((length(s2)*5) div 2);
 j3:=156-((length(s3)*5) div 2);
 set256colors(colors);
 b:=tslice div 2;
 for i:=31 downto 0 do
  begin
   printxy2(j1-i,90-i,31-i,s1);
   printxy2(j1-i,90+i,31-i,s1);
   printxy2(j1+i,90-i,31-i,s1);
   printxy2(j1+i,90+i,31-i,s1);
   printxy2(j2-i,100-i,31-i,s2);
   printxy2(j2-i,100+i,31-i,s2);
   printxy2(j2+i,100-i,31-i,s2);
   printxy2(j2+i,100+i,31-i,s2);
   printxy2(j3-i,110-i,31-i,s3);
   printxy2(j3-i,110+i,31-i,s3);
   printxy2(j3+i,110-i,31-i,s3);
   printxy2(j3+i,110+i,31-i,s3);
   delay(b);
  end;
 dothefade;
end;

(*
procedure domainscreen;
var backgr: pscreentype;
begin
 loadscreen('data/main',@screen);
 new(backgr);
 loadscreen('data/cloud',backgr);
{ asm                      // mix 2 images 255 - mask color
  push es
  push ds
  les si, [backgr]
  mov ax, $A000
  mov ds, ax
  xor si, si
 @@loopit:
  mov al, [ds: si]
  cmp al, 255
  jne @@nodraw
  mov al, [es: si]
  mov [ds: si], al
 @@nodraw:
  inc si
  cmp si, 64000
  jne @@loopit
  pop ds
  pop es
 end;
 * }
 dispose(backgr);
end;

procedure scrollmainscreen;
var temp,backgr: pscreentype;
    y1,a,b,t: integer;
begin
 new(temp);
 new(backgr);
 loadscreen('data/main',temp);
 loadscreen('data/cloud',backgr);
 set256colors(colors);
 for i:=1 to 120 do
  move(planet^[i],backgr^[i+12,28],30*4);
 for y1:=0 to 4 do
  for b:=6 to 138 do
   for a:=10 to 303 do
    if temp^[b,a]=255 then screen[b,a]:=backgr^[b+y1,a+y1];
 t:=tslice div 4;
 for y1:=0 to 36 do
  begin
   for j:=0 to 255 do
    begin
     colors[j,1]:=colors[j,1] + round((63-colors[j,1])/30);
     colors[j,2]:=colors[j,2] - round(colors[j,2]/30);
     colors[j,3]:=colors[j,3] - round(colors[j,3]/30);
    end;
   set256colors(colors);
   delay(t);
  end;
 dispose(backgr);
 dispose(temp);
end;
*)

procedure powerupencodes;
var a,b,t: integer;
    part: real;
begin
 setcolor(31);
 part:=31/36;
 //t:=tslice div 4;
 t:=tslice;
 for a:=0 to 5 do
  for b:=0 to 36 do
   begin
    screen[(a mod 3)*30+48,(a div 3)*258+b+13]:=round(b*part)+64;
    screen[(a mod 3)*30+49,(a div 3)*258+b+13]:=round(b*part)+64;
    for i:=128 to 143 do
     colors[i]:=colors[random(22)];
    for i:=144 to 159 do
     colors[i]:=colors[0];
    set256colors(colors);
    delay(t);
    for i:=144 to 159 do
     colors[i]:=colors[random(16)];
    for i:=128 to 143 do
     colors[i]:=colors[0];
    set256colors(colors);
    for i:=(a mod 3)*30+37 to (a mod 3)*30+42 do
     for j:=(a div 3)*138+89 to (a div 3)*138+93 do
      if screen[i,j] div 16=3 then screen[i,j]:=screen[i,j]+32;
   end;
end;

(*
procedure createplanet(xc,yc: integer);
var x1,y1: integer;
    a: longint;
begin
 x1:=xc;
 y1:=yc;
 for a:=1 to 75000 do
  begin
   x1:=x1-1+random(3);
   y1:=y1-1+random(3);
   if x1>240 then x1:=1 else if x1<1 then x1:=240;
   if y1>120 then y1:=1 else if y1<1 then y1:=120;
   if landform^[x1,y1]<240 then landform^[x1,y1]:=landform^[x1,y1]+5;
  end;
end;
*)
procedure generateplanet;
var f: file of landtype;
begin
 randomize;
 assign(f,'data/plan1.dta');
 reset(f);
 if ioresult<>0 then errorhandler('data/plan1.dta',1);
 read(f,landform^);
 if ioresult<>0 then errorhandler('data/plan1.dta',5);
 close(f);
 fillchar(planet^,14400,0);
 water:=50;
 part2:=28/(255-water);
 c:=0;
 ecl:=180;
 radius:=3025;
 c2:=1.09;
 r2:=round(sqrt(radius));
 waterindex:=33;
 for j:=0 to 3 do spcindex[j]:=48+j;
 spcindex[4]:=128;
 spcindex[5]:=129;
end;



procedure makeplanet(t: integer; eclipse: boolean);
//var modth,modtm,modts,curth,curtm,curts: byte;
label endcheck;
begin
 {asm
  mov ah, 2Ch
   int 21h
  mov modth, ch
  mov modtm, cl
  mov modts, dh
 end;}
 gettime;
 repeat
  inc(c,1);
  if c>240 then c:=c-240;
  if (eclipse) and (c mod 2=0) then
   begin
    inc(ecl);
    if ecl>340 then ecl:=ecl-340;
   end;
  x:=2*r2+10;
  ofsy:=0;
  for i:=6 to 2*r2+4 do
    begin
     y:=sqrt(radius-sqr(i-r2-5));
     m:=round((r2-y)*c2);
     part:=r2/y;
     inc(ofsy);
     ofsx:=m;
     for j:=1 to x do
      begin
       index:=round(j*part);
       if index>x then goto endcheck;
       inc(ofsx);
       if ecl>170 then
        begin
         if j=1 then alt:=10
          else alt:=(index-ecl+186) div 2;
        end
        else if ecl<171 then
         begin
          if index=x then alt:=10
           else alt:=(ecl-index) div 2
         end
        else alt:=0;
       if alt<0 then alt:=0;
       if (index+c)>240 then j2:=index+c-240
        else j2:=index+c;
       if (alt<6) and (landform^[j2,i]<water) then planet^[ofsy,ofsx]:=waterindex+6-alt
        else if landform^[j2,i]<water then planet^[ofsy,ofsx]:=waterindex
        else
         begin
          z:=round((landform^[j2,i]-water)*part2);
          case z of
           6..31: if z>alt then z:=z-alt else z:=1;
           0..5: if alt>spcindex[z] mod 16 then z:=1 else z:=spcindex[z]-alt;
          end;
          planet^[ofsy,ofsx]:=z;
         end;
 endcheck:
      end;
    end;
  for i:=1 to 120 do
   scrto_move(planet^[i],screen[i+12,28],30*4);
//  delay(tslice);
    delay(tslice*3);
getcurtime;
  i:=abs(curth-modth)*3600+abs(curtm-modtm)*60+curts-modts;
 until i>t;

end;

procedure readyencode;
begin
 for i:=128 to 143 do
  colors[i]:=colors[random(22)];
 for i:=144 to 159 do
  colors[i]:=colors[0];
 set256colors(colors);
 for i:=0 to 69 do
  for j:=0 to 68 do
   screen[i+40,j+126]:=random(16)+128+(i mod 2)*16;
end;

procedure charcomstuff(t: integer);
//var modth,modtm,modts,curth,curtm,b,curts: byte;
var b:byte;
begin
gettime;
 b:=tslice div 2;
 repeat
  for i:=128 to 143 do
   colors[i]:=colors[random(22)];
  for i:=144 to 159 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(b);
  for i:=144 to 159 do
   colors[i]:=colors[random(16)];
  for i:=128 to 143 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(b);
getcurtime;
  i:=abs(curth-modth)*3600+abs(curtm-modtm)*60+curts-modts;
  delay(tslice div 5);
 until i>t;
end;

procedure fadecharcom;
var a,b: integer;
    temppal: paltype;
begin
 index:=0;
 a:=24;
 temppal[0,1]:=0;		// to turn off warnings, variables are actually correctly initialized by function below
 move(colors,temppal,sizeof(paltype));
 b:=tslice div 2;
 repeat
  inc(index);
  if a>0 then
   for j:=0 to 255 do
    for i:=1 to 3 do
     colors[j,i]:=round(a*temppal[j,i]/24);
  for i:=128 to 143 do
   colors[i]:=colors[random(22)];
  for i:=144 to 159 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(b);
  for i:=144 to 159 do
   colors[i]:=colors[random(16)];
  for i:=128 to 143 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(b+2);
  dec(a);
 until a=0;
end;

procedure c7logo;
var t: pscreentype;
    y,x,a,b,seed,j,index,max,t2: word;
    temppal: paltype;
label ending;
begin
 new(t);
 tslice:=tslice div 2;
 fillchar(colors,sizeof(paltype),0);
 set256colors(colors);
 loadscreen('data/channel7',t);
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=random(16)+200+(i mod 2)*16;
 max:=38000;
 //t2:=tslice div 2;
 t2:=tslice;
 index:=0;
 j:=0;
 seed:=159;
 if fastkeypressed then begin dispose(t); exit; end;
// b:=tslice div 4;
 b:=round(tslice * 1.8);
 repeat
  for i:=200 to 215 do
   colors[i]:=colors[random(22)];
  for i:=216 to 231 do
   colors[i]:=colors[0];
  set256colors(colors);
  for i:=1 to 70+(120-tslice) do
   begin
    inc(index);
    j:=j+seed;
    if j>max then j:=j-max;
    y:=(j div 300)+30;
    x:=j mod 300+20;
    if t^[y,x]>0 then screen[y,x]:=t^[y,x];
   end;
  for i:=216 to 231 do
   colors[i]:=colors[random(16)];
  for i:=200 to 215 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(b);
 until index>max;
 a:=31;
 index:=0;
 if fastkeypressed then goto ending;
 repeat
  inc(index);
  for i:=200 to 215 do
   colors[i]:=colors[random(22)];
  for i:=216 to 231 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice);
  for i:=216 to 231 do
   colors[i]:=colors[random(16)];
  for i:=200 to 215 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(b);
 until index=75;
 index:=0;
 a:=24;
 temppal[0,1]:=0;		// to turn off warnings, variables are actually correctly initialized by function below
 move(colors,temppal,sizeof(paltype));
 if fastkeypressed then goto ending;
 repeat
  inc(index);
  if a>0 then
   for j:=0 to 199 do
    for i:=1 to 3 do
//        colors[j,i]:=round(colors[j,i]);
     colors[j,i]:=round(a/24.0*temppal[j,i]);
  for i:=200 to 215 do
   colors[i]:=colors[random(22)];
  for i:=216 to 231 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(t2*2);
  for i:=216 to 231 do
   colors[i]:=colors[random(16)];
  for i:=200 to 215 do
   colors[i]:=colors[0];
  set256colors(colors);
//  delay(t2 div 2);
  delay(t2);
  if index and 1=0 then dec(a);
 until a=0;
 dispose(t);
 tslice:=tslice*2;
 exit;
ending:
 dispose(t);
 fillchar(colors,sizeof(paltype),0);
 set256colors(colors);
end;

//procedure scale(startx,starty,sizex,sizey,newx,newy: integer; var s,t);
//var sety, py, pdy, px, pdx, dcx, dcy, ofsy: integer;
//begin
// asm
//  push ds
//  push es
//  les si, [s]         { es: si is our source location }
//  mov [ofsy], si
//  lds di, [t]         { ds: di is our destination }
//  imul di, [starty], 320
//  mov [sety], di
//
//  add di, [startx]
//
//  mov ax, [sizex]
//  xor dx, dx
//  mov cx, [newx]
//  div cx
//  mov [px], ax
//  mov [pdx], dx       { set up py and pdy }

//  mov ax, [sizey]
//  xor dx, dx
//  mov cx, [newy]
//  div cx
//  mov [py], ax
//  mov [pdy], dx       { set up py and pdy }

//  xor cx, cx
//  mov [dcx], cx
//  mov [dcy], cx
//  mov dx, [newy]

// @@iloop:
//  add cx, [py]

//  mov ax, [pdy]
//  add [dcy], ax
//  mov ax, [dcy]

//  cmp ax, [newy]
//  jl @@nodcychange
//  inc cx
//  sub ax, [newy]
//  mov [dcy], ax

// @@nodcychange:

//  imul si, cx, 320
//  add si, [ofsy]

//  mov bx, [newx]

// @@jloop:
//  add si, [px]

//  mov ax, [pdx]
//  add [dcx], ax
//  mov ax, [dcx]
//  cmp ax, [newx]
//  jl @@nodcxchange
//
//  inc si
//  sub ax, [newx]
//  mov [dcx], ax

// @@nodcxchange:

//  mov al, [es: si]
//  mov [ds: di], al     { finally draw it! }

//  inc di
//  dec bx
//  jnz @@jloop

//  add [sety], 320
//  mov di, [sety]
//  add di, [startx]

//  dec dx
//  jnz @@iloop

//  pop es
//  pop ds
// end;
//end;

procedure shrinkalienscreen;
var t: pscreentype;
    partx,party: real;
    a,startx,max,starty: integer;
    temppal: paltype;
begin

 temppal[0,1]:=0;		// to turn off warnings, variables are actually correctly initialized by function below
 fillchar(temppal,sizeof(paltype),0);
 for i:=0 to 31 do
  temppal[i]:=colors[i];
 for i:=240 to 255 do
  temppal[i]:=colors[i];
 new(t);
// fillchar(t^,sizeof(screen),0);
 if t=nil then writeln('Out of memory !!!');
 scrfrom_move(screen,t^,sizeof(t^));
 max:=25;
 for a:=1 to max-1 do
  begin
   partx:=306-234/max*a;
   party:=177-142/max*a;
   starty:=171-round(party);
   startx:=305-round(partx);
   delay(30);
   //scale(startx,starty,305,176,320-startx,200-starty,t^,screen);
   scale_img(10,0,200,106,startx,starty,round(partx),round(party),t^,screen);
  end;
 for i:=142 to 176 do
  scrfrom_move(screen[i,234],t^[i,234],18*4);
 set256colors(temppal);
 loadscreen('data/alien',@screen);
 for i:=142 to 176 do
  scrto_move(t^[i,234],screen[i,234],18*4);
 dispose(t);
end;

procedure fadeinalienscreen;
var a: integer;
    temppal: paltype;
begin
 for i:=240 to 255 do temppal[i]:=colors[i];
 for i:=0 to 31 do temppal[i]:=colors[i];
 for a:=1 to 24 do
  begin
   for j:=32 to 239 do
    for i:=1 to 3 do
     temppal[j,i]:=round(a*colors[j,i]/24);
   set256colors(temppal);
   delay(tslice);
  end;
end;

procedure alienscreenwait;
var //modth,modtm,modts,curth,curtm,curts: byte;
    x1,y1,x2,y2: integer;
begin
gettime;
 x1:=183;
 y1:=131;
 x2:=62;
 y2:=148;
 screen[y1,x1]:=screen[y1,x1] xor 31;
 screen[y2,x2]:=screen[y2,x2] xor 31;
 for j:=1 to 7 do
  begin
   screen[y1,x1]:=screen[y1,x1] xor 31;
   screen[y2,x2]:=screen[y2,x2] xor 31;
   dec(x1);
   inc(y1);
   inc(y2);
   screen[y1,x1]:=screen[y1,x1] xor 31;
   screen[y2,x2]:=screen[y2,x2] xor 31;
   repeat
  getcurtime;
    i:=abs(curth-modth)*3600+abs(curtm-modtm)*60+curts-modts;
   until i>j;
  end;
 for j:=3 downto 1 do
  begin
   setcolor(175-j*2);
   circle(x1,y1,j*3+1);
   circle(x2,y2,j*3+1);
   delay(tslice*8);
  end;
end;

procedure fadearea(x1,y1,x2,y2,alt: integer);
begin
 for i:=y1 to y2 do
  for j:=x1 to x2 do
   if screen[i,j]>0 then screen[i,j]:=screen[i,j]+alt;
end;

procedure getbackgroundforis2;
var backgr: pscreentype;
begin
 new(backgr);
 loadscreen('data/cloud',backgr);
 loadscreen('data/main3',@screen);
 for j:=0 to 319 do
  for i:=0 to 199 do
   if screen[i,j]=255 then screen[i,j]:=backgr^[i,j];
 for i:=1 to 120 do
  scrfrom_move(screen[i+12,28],planet^[i],30*4);
 radius:=400;
 c2:=1.30;
 r2:=round(sqrt(radius));
 c:=random(120);
 ecl:=50;
 makeplanet(0,false);
 m1:=291;
 m2:=201;
 m3:=234;
 m4:=280;
 fadearea(186,35,290,45,32);
 fadearea(186,55,200,65,32);
 fadearea(186,75,233,85,32);
 fadearea(186,95,279,105,32);
 dispose(backgr);
end;

procedure is2wait(alt1,alt2,alt3,alt4: integer);
begin
 gettime;
 repeat
  if m1>190 then
   begin
    fadearea(m1+alt1,35,m1-1,45,-32);
    m1:=m1+alt1;
   end;
  if m2>190 then
   begin
    fadearea(m2+alt2,55,m2-1,65,-32);
    m2:=m2+alt2;
   end;
  if m3>190 then
   begin
    fadearea(m3+alt3,75,m3-1,85,-32);
    m3:=m3+alt3;
   end;
  if m4>190 then
   begin
    fadearea(m4+alt4,95,m4-1,105,-32);
    m4:=m4+alt4;
   end;
  delay(tslice*7);
getcurtime;
  i:=abs(curth-modth)*3600+abs(curtm-modtm)*60+curts-modts;
 until i>1;
end;

(*
procedure staticscreen;
begin
 for i:=0 to 199 do
  for j:=0 to 319 do
   screen[i,j]:=random(16)+200+(i mod 2)*16;
 repeat
  for i:=200 to 215 do
   colors[i]:=colors[random(22)];
  for i:=216 to 231 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice);
  for i:=216 to 231 do
   colors[i]:=colors[random(16)];
  for i:=200 to 215 do
   colors[i]:=colors[0];
  set256colors(colors);
  delay(tslice div 4);
 until fastkeypressed;
end;
*)

procedure runintro;
var a: integer;

label continue,skip,skip2;
begin
 bkcolor:=0;
 tcolor:=22;
 a:=5;
 printxy(5, a, #1#2'1994 Channel 7, Destiny: Virtual'); a:=a+10;
 printxy(5, a, 'Released Under GPL V3.0 in 2013 by Jeremy D Stanton'); a:=a+10;
 printxy(15,a, ' of IronSeed.net'); a:=a+10;
 printxy(5, a, #1#2'2013 y-salnikov - Converted IronSeed to FreePascal'); a:=a+10;
 printxy(15,a, ' and GNU/Linux'); a:=a+10;
 printxy(5, a, #1#2'2016 Nuke Bloodaxe'); a:=a+10;
 printxy(5, a, #1#2'2020 Matija Nalis'); a:=a+10;
 a:=a+10;
 printxy(5, a, 'Some rights reserved.'); a:=a+20;
{$IFDEF DEMO}
 printxy(5, a,'IronSeed ' + versionstring + ' Demo'); a:=a+10;
{$ELSE}
 printxy(5, a,'IronSeed ' + versionstring); a:=a+10;
{$ENDIF}
 wait(3);
 new(planet);
 new(landform);
 if fastkeypressed then goto continue;
 generateplanet;
 if fastkeypressed then goto continue;
 playmod(true,'sound/INTRO1.MOD');
 mouse.setmousecursor(1);
// goto skip2;
 if fastkeypressed then goto continue;
{PART I. *********************************************************************}
{#1.1}
 c7logo;
{#1.2}
 if fastkeypressed then goto continue;
 loadpalette('data/main.pal');
 writestr2('A','Destiny: Virtual','Designed Game');
 if fastkeypressed then goto continue;
 wait(2);
 fading;
 if fastkeypressed then goto continue;
{#1.3}
 showmars;
 printxy2(145,30,29,'Mars');
 printxy2(133,40,30,'3784 A.D.');
 for a:=0 to 63 do
  begin
   setrgb256(29,a,0,0);
   delay(tslice);
  end;
 for a:=0 to 63 do
  begin
   setrgb256(30,a,0,0);
   delay(tslice);
  end;
 colors[29,1]:=63;
 colors[29,2]:=0;
 colors[29,3]:=0;
 colors[30]:=colors[29];
 if fastkeypressed then goto continue;
 wait(2);
 fading;
 if fastkeypressed then goto continue;
{#1.4}
 loadpalette('data/main.pal');
 loadscreen('data/cloud',@screen);
 for i:=1 to 120 do
  scrfrom_move(screen[i+12,28],planet^[i],30*4);
 sleep(0);
 makeplanet(0,false);
 tcolor:=22;
 bkcolor:=255;
 bigprintxy(0,159,'Escaping the iron fist of a fanatic');
 bigprintxy(0,167,'theocracy, the members of the Ironseed');
 bigprintxy(0,175,'Movement launch into space and are set');
 bigprintxy(0,183,'adrift after suffering a computer');
 bigprintxy(0,191,'malfunction.');
 fadein;
 makeplanet(12,true);
 fading;
{**************}
 loadscreen('data/charcom',@screen);
 fadein;
 readyencode;
 tcolor:=191;
 printxy(20,153,'Ship IRONSEED to Relay Point:');
 charcomstuff(1);
 printxy(170,153,'Link Established.');
 charcomstuff(1);
 printxy(20,159,'Receiving Encode Variants.');
 powerupencodes;
 charcomstuff(1);
 printxy(20,165,'Wiping Source Encodes.');
 charcomstuff(1);
 printxy(20,171,'Terminating Transmission.');
 charcomstuff(1);
 printxy(20,177,'Control Protocol Transfered to Human Encode "PRIME".');
 charcomstuff(1);
 fadecharcom;
 if fastkeypressed then goto continue;
{*************}
 loadscreen('data/battle1',@screen);
 for i:=1 to 120 do
  for j:=1 to 240 do
   landform^[j,i]:=255-landform^[j,i];
 radius:=2000;
 c2:=1.16;
 r2:=round(sqrt(radius));
 c:=random(120);
 ecl:=105;
 tcolor:=22;
 bkcolor:=255;
 bigprintxy(0,175,'As captain, you awaken along with the');
 bigprintxy(0,183,'crew some thousand years later and are');
 bigprintxy(0,191,'confronted by an alien horde...');
 for i:=1 to 120 do
  scrfrom_move(screen[i+12,28],planet^[i],30*4);
 makeplanet(0,false);
 fadein;
 makeplanet(10,false);
{**************}
skip:
 loadscreen('data/ship1',@screen);
 set256colors(colors);
 tcolor:=255;
//goto skip2;
 wait(2);
 printxy(50,125,'Orders: Approach and Destroy.');
 wait(2);
 printxy(50,135,'Jamming all Emissions.');
 wait(2);
 printxy(50,145,'Targeting...');
 wait(2);
 printxy(50,155,'Locked and Loading...');
 wait(2);
 printxy(50,165,'Closing for Fire...');
 wait(2);
 if fastkeypressed then goto continue;
{**************}
skip2:
 shrinkalienscreen;
 fadeinalienscreen;
 alienscreenwait;
 fading;
 if fastkeypressed then goto continue;
{**************}

 getbackgroundforis2;
 fadein;
 tcolor:=26;
 printxy(13,160,'Enemy Closing Rapidly..');
 wait(2);
 printxy(13,167,'Shields Imploding...');
 is2wait(-1,0,0,-2);
 wait(1);
 printxy(13,174,'Destruction Imminent.');
 is2wait(-3,0,-1,-1);
 wait(1);
 printxy(13,182,'Attempting Crash Landing.');
 is2wait(-1,-1,0,0);
 wait(1);
 blast(63,0,0);
 fading;
 if fastkeypressed then goto continue;
{**************}
 loadpalette('data/main.pal');
 loadscreen('data/cloud',@screen);
 water:=50;
 part2:=28/(255-water);
 c:=0;
 ecl:=190;
 radius:=3025;
 c2:=1.09;
 r2:=round(sqrt(radius));
 waterindex:=33;
 for j:=0 to 3 do spcindex[j]:=48+j;
 spcindex[4]:=128;
 spcindex[5]:=129;
 for i:=1 to 120 do
  scrfrom_move(screen[i+12,28],planet^[i],30*4);
 makeplanet(0,false);
 tcolor:=22;
 bkcolor:=255;
 bigprintxy(0,159,'They threaten to devour all life in');
 bigprintxy(0,167,'their path...your only hope of defeating');
 bigprintxy(0,175,'the Scavengers is to reunite the Kendar,');
 bigprintxy(0,183,'an ancient alliance among the free');
 bigprintxy(0,191,'worlds.');
 fadein;
 makeplanet(12,false);
 fading;
{$IFNDEF DEMO}
 loadscreen('data/intro5',@screen);
{$ELSE}
 loadscreen('data/intro6',@screen);
{$ENDIF}
 fadein;
 while fastkeypressed do readkey;
{FINAL********************************************************************}
continue:
 stopmod;
 dispose(landform);
 dispose(planet);
 if fastkeypressed then
  begin

   while fastkeypressed do readkey;

   fillchar(colors,sizeof(paltype),0);
   set256colors(colors);
{$IFNDEF DEMO}
   loadscreen('data/intro5',@screen);
{$ELSE}
   loadscreen('data/intro6',@screen);
{$ENDIF}
   fadein;
  end;
 mouseshow;
end;

procedure checkparams;
var i : Integer;
begin
 if (paramstr(1)<>'/showseed') then
  begin
   closegraph;
     for i := 1 to paramcount do
	writeln(paramstr(i));
   writeln('Do not run this program separately.  Please run is.');
   halt(4);
  end;
 if (paramstr(2)='/done') then
  begin
   fillchar(colors,sizeof(paltype),0);
   set256colors(colors);
{$IFNDEF DEMO}
   loadscreen('data/intro5',@screen);
{$ELSE}
   loadscreen('data/intro6',@screen);
{$ENDIF}
   fadein;
   mouseshow;
   mainloop;
  end
 else
  begin
   runintro;
   mainloop;
  end;
end;

begin
 readygraph;
 initializemod;
 tslice:=25;
 checkparams;
 closegraph;
 halt(code);
end.
