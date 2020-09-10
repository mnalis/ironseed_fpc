unit data2;
{ mostly copied from data.pas and utils_.pas }

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
 screentype= array[0..199,0..319] of byte;
 paltype=array[0..255,1..3] of byte;
 pscreentype= ^screentype;

var
 colors: paltype;
 screen: screentype;
 has_pal: boolean;

procedure quicksavescreen(s : String; scr : pscreentype; savepal : Boolean);
procedure quickloadscreen(s : String; scr : pscreentype; loadpal : Boolean);
procedure loadscreen(s: string; ts: pointer);
procedure compressfile(s: string; ts: pscreentype; fl: byte);
procedure errorhandler(s: string; errtype: integer);


implementation

procedure errorhandler(s: string; errtype: integer);
begin
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

procedure uncompressfile(s: string; ts: pscreentype; h: pCPR_HEADER);
type
 buftype= array[0..CPR_BUFFSIZE] of byte;
var
 f: file;
 err,num,count,databyte,index,x: word;
 total,totalsize,j: longint;
 buffer: ^buftype;

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
 if (ioresult<>0) or (not checkversion) or (not decode) then
  begin
   handleerror;
   exit;
  end;
 close(f);
 if buffer<>nil then dispose(buffer);
end;

procedure loadscreen(s: string; ts: pointer);
var ftype: CPR_HEADER;
begin
 uncompressfile(s+'.cpr',ts,@ftype);
 if ftype.version=CPR_ERROR then errorhandler(s,5);
end;

procedure compressfile(s: string; ts: pscreentype; fl: byte);
type
 buftype= array[0..CPR_BUFFSIZE] of byte;
var
 f: file;
 err,num,count,databyte,j,x,index: word;
 buf: ^buftype;
 h: CPR_HEADER;

 procedure handleerror;
 begin
  if buf<>nil then dispose(buf);
  buf:=nil;
  close(f);
  j:=ioresult;
 end;

 procedure setheader(fl:byte);
 begin
  with h do
   begin
    signature:=19794;
    version:=CPR_CURRENT;
    headersize:=sizeof(CPR_HEADER);
    width:=320;
    height:=200;
    flags:=fl;
   end;
  num:=sizeof(CPR_HEADER);
  blockwrite(f,h,num,err);
  if (err<num) or (ioresult<>0) then errorhandler(s,5);
  if h.flags and 1>0 then
   begin
    num:=768;
    blockwrite(f,colors,num,err);
    if (ioresult<>0) or (err<num) then errorhandler(s,5);
   end;
 end;

 procedure saveindex;
 begin
  num:=index;
  blockwrite(f,buf^,num,err);
  if (ioresult<>0) or (num<>err) then
   begin
    handleerror;
    exit;
   end;
  index:=0;
 end;

begin
 new(buf);
 assign(f,s+'.cpr');
 rewrite(f,1);
 if ioresult<>0 then errorhandler(s,1);
 setheader(fl);
 databyte:=ts^[0,0];
 count:=0;
 index:=0;
 x:=0;
 repeat
  count:=0;
  databyte:=ts^[0,x];
  while (ts^[0,x]=databyte) and (x<64000) do
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
 until x=64000;
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


begin
end.
