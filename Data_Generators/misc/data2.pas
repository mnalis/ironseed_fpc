unit data2;
{ Matija Nalis <mnalis-git@voyager.hr>, GPLv3+ started 2020/09
  CPR bits mostly copied from data.pas and utils_.pas, TARGA code is by Matija Nalis }

{$I-}

interface
{$PACKRECORDS 1}


const                           { compression constants        }
 CPR_VER4=4;                    {   4 new header               }
 CPR_ERROR=255;                 { global error                 }
 CPR_CURRENT=CPR_VER4;          { current version              }
 CPR_BUFFSIZE= 8192;            { adjustable buffer size       }

type
 CPR_HEADER=
  record
   signature: word;             {RWM, no version. RM, version  }
   version: byte;
   width,height: word;
   flags: byte;
   headersize: byte;
  end;
 pCPR_HEADER= ^CPR_HEADER;

type
 TGA_HEADER=
  record
   id_len: byte;
   cmap_type: byte;
   img_type: byte;
   cmap_ofs: word;
   cmap_len: word;
   cmap_esize: byte;
   x_org, y_org: word;
   width, height: word;
   pixel_depth: byte;
   img_descriptor_b: byte;
   img_id: dword;
  end;
 pTGA_HEADER= ^TGA_HEADER;

type
 screentype= array[0..199,0..319] of byte;
 paltype=array[0..255,1..3] of byte;
 pscreentype= ^screentype;

var
 colors: paltype;
 screen: screentype;
 has_pal: boolean;
 cpr_head: CPR_HEADER;
 tga_head: TGA_HEADER;

procedure quicksavescreen(s : String; scr : pscreentype; savepal : Boolean);
procedure quickloadscreen(s : String; scr : pscreentype; loadpal : Boolean);
procedure loadscreen(s: string; ts: pointer);
procedure compressfile(s: string; ts: pscreentype; w2,h2:word; fl: byte);
procedure errorhandler(s: string; errtype: integer);
procedure loadpal(s: string);
procedure savetga(s: string; ts: pscreentype);
procedure loadtga(s: string);


implementation

uses sysutils;

procedure errorhandler(s: string; errtype: integer);
begin
 writeln;
 case errtype of
  1: writeln(StdErr, 'Open File Error: ',s,' (ioresult=',ioresult,')');
  2: writeln(StdErr, 'Mouse Error: ',s);
  3: writeln(StdErr, 'Sound Error: ',s);
  4: writeln(StdErr, 'EMS Error: ',s);
  5: writeln(StdErr, 'Fatal File Error: ',s,' (ioresult=',ioresult,')');
  6: writeln(StdErr, 'Program Error: ',s);
  7: writeln(StdErr, 'Music Error: ',s);
 end;
 halt(4);
end;

procedure uncompressfile(s: string; ts: pscreentype; h: pCPR_HEADER);
type
 buftype= array[0..CPR_BUFFSIZE] of byte;
var
 f: file;
 err,num,count,databyte,index,x: word;
 total,totalsize,j: longint;
 buffer: ^buftype;

 procedure handleerror(s:string);
 begin
  writeln (StdErr, 'handleerror: '+s);
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
  if (err<num) or (ioresult<>0) then
   begin
    handleerror('getbuffer');
    exit;
   end;
  total:=total-num;
  index:=0;
 end;

 function handleversion(n: integer): boolean;
 begin
  handleversion:=false;
  writeln ('  file using sig=',chr(lo(h^.signature)), chr(hi(h^.signature)), ' v=',h^.version, ' width=',h^.width, ' height=', h^.height, ' flags=', h^.flags);
  if n<>4 then exit;
  has_pal := false;
  if h^.flags and 1>0 then
   begin
    has_pal := true;
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
//  writeln(h^.width,' ',h^.height);
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
  until j=totalsize;
  decode:=true;
 end;

begin
 new(buffer);
 assign(f,s);
 reset(f,1);
 if ioresult<>0 then
  begin
   handleerror('open');
   exit;
  end;
 if not checkversion then
  begin
   handleerror('checkversion');
   exit;
  end;
 if not decode then
  begin
   handleerror('decode');
   exit;
  end;
 close(f);
 if buffer<>nil then dispose(buffer);
end;

procedure loadscreen(s: string; ts: pointer);
begin
 uncompressfile(s+'.cpr',ts,@cpr_head);
 if cpr_head.version=CPR_ERROR then errorhandler(s+'.cpr CPR_ERROR',5);
end;

procedure compressfile(s: string; ts: pscreentype; w2,h2:word; fl: byte);
type
 buftype= array[0..CPR_BUFFSIZE] of byte;
var
 f: file;
 err,num,count,databyte,j,x,index: word;
 buf: ^buftype;
 h: CPR_HEADER;

 procedure handleerror(s:string);
 begin
  writeln (StdErr, 'handleerror: '+s);
  if buf<>nil then dispose(buf);
  buf:=nil;
  close(f);
  j:=ioresult;
 end;

 procedure setheader(w2,h2:word; fl:byte);
 begin
  with h do
   begin
    signature:=19794;
    version:=CPR_CURRENT;
    headersize:=sizeof(CPR_HEADER);
    width:=w2;
    height:=h2;
    flags:=fl;
   end;
  num:=sizeof(CPR_HEADER);
  blockwrite(f,h,num,err);
  if (err<num) or (ioresult<>0) then errorhandler(s+'.cpr setheader',5);
  if h.flags and 1>0 then
   begin
    num:=768;
    blockwrite(f,colors,num,err);
    if (ioresult<>0) or (err<num) then errorhandler(s+'.cpr palette',5);
   end;
 end;

 procedure saveindex;
 begin
  num:=index;
  blockwrite(f,buf^,num,err);
  if (ioresult<>0) or (num<>err) then
   begin
    handleerror('saveindex');
    exit;
   end;
  index:=0;
 end;

begin
 new(buf);
 assign(f,s+'.cpr');
 rewrite(f,1);
 if ioresult<>0 then errorhandler(s+'.cpr',1);
 setheader(w2,h2,fl);
 databyte:=ts^[0,0];
 count:=0;
 index:=0;
 x:=0;
 repeat
  count:=0;
  databyte:=ts^[0,x];
  while (ts^[0,x]=databyte) and (x<w2*h2) do
   begin
    inc(count);
    inc(x);
   end;
  if (count<4) and (databyte<255) then
   for j:=1 to count do
    begin
     buf^[index]:=databyte;
     inc(index);
     if index=CPR_BUFFSIZE then saveindex;
    end
  else
   begin
    while count>255 do
     begin
      buf^[index]:=255;
      inc(index);
      if index=CPR_BUFFSIZE then saveindex;
      buf^[index]:=255;
      inc(index);
      if index=CPR_BUFFSIZE then saveindex;
      buf^[index]:=databyte;
      inc(index);
      if index=CPR_BUFFSIZE then saveindex;
      dec(count,255);
     end;
    if (count<4) and (databyte<255) then
     for j:=1 to count do
      begin
       buf^[index]:=databyte;
       inc(index);
       if index=CPR_BUFFSIZE then saveindex;
      end
    else
     begin
      buf^[index]:=255;
      inc(index);
      if index=CPR_BUFFSIZE then saveindex;
      buf^[index]:=count;
      inc(index);
      if index=CPR_BUFFSIZE then saveindex;
      buf^[index]:=databyte;
      inc(index);
      if index=CPR_BUFFSIZE then saveindex;
     end;
   end;
 until x=w2*h2;
 saveindex;
 close(f);
 if buf<>nil then dispose(buf);
end;

procedure loadpal(s: string);
var palfile: file of paltype;
begin
 assign(palfile,s);
 reset(palfile);
 if ioresult<>0 then errorhandler(s,1);
 read(palfile,colors);
 if ioresult<>0 then errorhandler(s,5);
 close(palfile);
end;

procedure quicksavescreen(s : String; scr : pscreentype; savepal : Boolean);
var
   fs : file of screentype;
   fp : file of paltype;
begin
   assign(fs, s + '.scr');
   rewrite(fs);
   if ioresult<>0 then errorhandler(s + '.scr', 1);
   write(fs, scr^);
   if ioresult<>0 then errorhandler(s + '.scr', 5);
   close(fs);
   if savepal then
   begin
      assign(fp, s + '.pal');
      rewrite(fp);
      if ioresult<>0 then errorhandler(s + '.pal', 1);
      write(fp, colors);
      if ioresult<>0 then errorhandler(s + '.pal', 5);
      close(fp);
   end;
end;
					    
procedure quickloadscreen(s : String; scr : pscreentype; loadpal : Boolean);
var
   fs : file of screentype;
   fp : file of paltype;
begin
   assign(fs, s + '.scr');
   reset(fs);
   if ioresult<>0 then errorhandler(s + '.scr', 1);
   read(fs, scr^);
   if ioresult<>0 then errorhandler(s + '.scr', 5);
   close(fs);
   if loadpal then
   begin
      assign(fp, s + '.pal');
      reset(fp);
      if ioresult<>0 then errorhandler(s + '.pal', 1);
      read(fp, colors);
      if ioresult<>0 then errorhandler(s + '.pal', 5);
      close(fp);
   end;
end;

{ save TARGA file }
procedure savetga(s: string; ts: pscreentype);
var  written,num: LongInt;
     f: file;

 procedure setheader;
 begin
  with tga_head do
   begin
     id_len := 4; 		{ 4 byte ID field }
     cmap_type := 1;		{ we use colormap/palette }
     img_type := 1;		{ 1 = uncompressed color-mapped image }
     cmap_ofs := 0;		{ we start at beginning of palette }
     cmap_len := 256;		{ 256 palette entries... }
     cmap_esize := 24;		{ ...of 3 bytes each }
     x_org := 0;
     y_org := 0;
     width := cpr_head.width;	{ copy width from .CPR ... }
     height := cpr_head.height;	{ ... and height }
     pixel_depth := 8;		{ 8 bpp index }
     img_descriptor_b := 32;	{ bit 5=1, bit 4=0: image origin is top-left }
     img_id := 808603213;	{ ID }
   end;
  num:=sizeof(TGA_HEADER);
  blockwrite(f,tga_head,num,written);
  if (written<num) or (ioresult<>0) then errorhandler(s+'.tga header',5);
 end;

begin
 assign(f,s+'.tga');
 rewrite(f,1);
 if ioresult<>0 then errorhandler(s+'.tga create',1);
 setheader();

 { write palette }
 num:=768;
 blockwrite(f,colors,num,written);
 if (ioresult<>0) or (written<num) then errorhandler(s+'.tga palette',5);

 { write image }
 num:=tga_head.width * tga_head.height; { 64000 for 320x200 image }
 repeat
    blockwrite(f,ts^,num,written);
    if (ioresult<>0) then errorhandler(s+'.tga img write',5);
    dec (num, written);
    inc (ts, written);
 until num=0;
 if (ioresult<>0) or (written<num) then errorhandler(s+'.tga img '+IntToStr(written)+'<>'+IntToStr(num),5);

 { finish }
 close(f);
 if (ioresult<>0) then errorhandler(s+'.tga finish',5);
end;

{ load TARGA file }
procedure loadtga(s: string);
var  err,num,y: LongInt;
     f: file;

 function checkversion: boolean;
 begin
  checkversion:=false;
  num:=18;	// minimum size of used part of TGA_HEADER
  blockread(f,tga_head,num,err);
  if (err<num) or (ioresult<>0)
   or (tga_head.cmap_type<>1) or (tga_head.img_type<>1) or (tga_head.cmap_ofs<>0) or (tga_head.cmap_len<>256) or (tga_head.cmap_esize<>24)
   or (tga_head.x_org<>0) or (tga_head.y_org<>0) or (tga_head.width>320) or (tga_head.height>200) or (tga_head.pixel_depth<>8) or ((tga_head.img_descriptor_b and not (1 shl 5))<>0)
   then exit;
  checkversion:=true;
 end;

 procedure saferead(var f:file; ts:pbyte; num:LongInt);
 begin
  repeat
     blockread(f,ts^,num,err);
     if (ioresult<>0) then errorhandler(s+' img read',5);
     dec (num, err);
     inc (ts, err);
  until num=0;
  if (ioresult<>0) or (err<num) then errorhandler(s+' img read '+IntToStr(err)+'<>'+IntToStr(num),5);
 end;

begin
 assign(f,s);
 reset(f,1);
 if (ioresult<>0) then errorhandler(s+' open',1);
 if not checkversion then errorhandler(s+' must be 256-color 8-bit index-colored 24-bit palette TARGA file',5);

 { read TGA palette }
 seek(f,tga_head.id_len+18);	// skip required header and (optional) variable-sized image_id
 num:=tga_head.cmap_esize div 8 * tga_head.cmap_len;
 assert (num=768, 'palette size mismatch');
 blockread(f,colors,num,err);
 if (ioresult<>0) or (num<>err) then errorhandler (s+' palette read error',5);

 { read image bitmap }
 with tga_head do
  for y := 0 to height-1 do
    if (img_descriptor_b and (1 shl 5))=0
    then		{ bottom left origin }
      saferead(f, @screen[0,(height-1-y)*width], width)
    else		{ top left origin }
      saferead(f, @screen[0,y*width], width);

 close(f);
end;


begin
  //loadpal ('data/main.pal');  { default pallete if not overriden }
end.
