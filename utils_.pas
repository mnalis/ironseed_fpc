Unit utils_;
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
    along with Ironseed.  If not, see <https://www.gnu.org/licenses/>.
********************************************************************)

{*********************************************
   SDL on GNU/Linux, porting Utilities for IronSeed

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2013 y-salnikov
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

{$L c_utils.o}
{$I-}

Interface

 type
 screentype= array[0..199,0..319] of byte;
 paltype=array[0..255,1..3] of byte;

 const
	Pan_Surround=0;
	xorput=1;
	copyput=0;

 var use_audio: boolean;

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
procedure init_dirs;
function loc_tmp:string;
function loc_data:string;
function loc_sound:string;
function loc_savenames:string;
function loc_savegame (const num:byte):string;
function loc_prn:string;
function loc_exe:string;

implementation

uses sysutils, dos, users, baseunix, _paths_;


procedure getrgb256_(const palnum: byte; r,g,b: pointer);  cdecl ; external;// get palette
procedure SDL_init_video(var scr:screentype; const use_audio: boolean); cdecl ; external;

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


procedure errorhandler(s: string; errtype: integer);
begin
 writeln;
 case errtype of
  1: writeln('File Error: ',s);
  2: writeln('Mouse Error: ',s);
  3: writeln('Sound Error: ',s);
  4: writeln('EMS Error: ',s);
  5: writeln('Fatal File Error: ',s);
  6: writeln('Program Error: ',s);
  7: writeln('Music Error: ',s);
 end;
 halt(4);
end;


type addr_type = qword;		// NB: word should be enough to hold memory address ?! https://www.tutorialspoint.com/pascal/pascal_pointers.htm
				// it is at least dword on i386 and qword on x86_64, so we go with bigger value
const screen_size = 320*200;
var screen_addr: addr_type;

function _address (const someaddress: pointer): addr_type;
begin
  _address := {$warnings-}{$hints-}addr_type(someaddress);{$hints+}{$warnings+}		// NB: get rid of "Hint: (4055) Conversion between ordinals and pointers is not portable" and "Warning: (4056) Conversion between ordinals and pointers is not portable" unless we find better way to compare memory addresses. We should be using FarAddr (fpc 3.2.0+) instead of "@"/addr() anyway
end;

{ bounds checking fillchar(), when dest is screen[] }
procedure scr_fillchar(var dest; count: SizeInt; Value: Byte);
var dest_addr: addr_type;
begin
 dest_addr := _address(@dest);
 //writeln('dest_addr=', inttohex(dest_addr,16), ' to ', inttohex(dest_addr+count,16), ', screen_addr=', inttohex(screen_addr,16), ' to ', inttohex(screen_addr+screen_size,16));
 assert (count >= 0, 'scr_fillchar: count is negative');
 assert (dest_addr >= screen_addr, 'scr_fillchar: screen destination below 0');
 assert (dest_addr + addr_type(count) <= screen_addr+screen_size, 'scr_fillchar: screen destination beyond end');
 fillchar(dest, count, value);
end;

{ bounds checking move(), when dest is screen[] }
procedure scrto_move(const source; var dest; count: SizeInt);
var dest_addr: addr_type;
begin
 dest_addr := _address(@dest);
 //writeln('dest_addr=', inttohex(dest_addr,16), ' to ', inttohex(dest_addr+count,16), ', screen_addr=', inttohex(screen_addr,16), ' to ', inttohex(screen_addr+screen_size,16));
 assert (count >= 0, 'scrto_move: count is negative');
 assert (dest_addr >= screen_addr, 'scrto_move: screen destination below 0');
 assert (dest_addr + addr_type(count) <= screen_addr+screen_size, 'scrto_move: screen destination beyond end');
 move (source, dest, count);
end;

{ bounds checking move(), when source is screen[] }
procedure scrfrom_move(const source; var dest; count: SizeInt);
var src_addr: addr_type;
begin
 src_addr := _address(@source);
 //writeln('src_addr=', inttohex(src_addr,16), ' to ', inttohex(src_addr+count,16), ', screen_addr=', inttohex(screen_addr,16), ' to ', inttohex(screen_addr+screen_size,16));
 assert (count >= 0, 'scrfrom_move: count is negative');
 assert (src_addr >= screen_addr, 'scrfrom_move: screen source below 0');
 assert (src_addr + addr_type(count) <= screen_addr+screen_size, 'scrfrom_move: screen source beyond end');
 move (source, dest, count);
end;

{ bounds checking move(), when source is screen[] }
procedure scrfromto_move(const source; var dest; count: SizeInt);
var src_addr, dest_addr: addr_type;
begin
 src_addr := _address(@source);
 dest_addr := _address(@dest);
 //writeln('src_addr=', inttohex(src_addr,16), ' to ', inttohex(src_addr+count,16), ', screen_addr=', inttohex(screen_addr,16), ' to ', inttohex(screen_addr+screen_size,16));
 assert (count >= 0, 'scrfromto_move: count is negative');
 assert (src_addr >= screen_addr, 'scrfromto_move: screen source below 0');
 assert (src_addr + addr_type(count) <= screen_addr+screen_size, 'scrfromto_move: screen source beyond end');
 assert (dest_addr >= screen_addr, 'scrto_move: screen destination below 0');
 assert (dest_addr + addr_type(count) <= screen_addr+screen_size, 'scrto_move: screen destination beyond end');
 move (source, dest, count);
end;

procedure init_video(var scr:screentype);
begin
  screen_addr := _address(@scr);
  SDL_init_video(scr, use_audio);
end;


var tempdir: string[255];	// NB: hopefully long enough
    savedir: string[255];	// NB: hopefully long enough


function UserName: string;
// Get Operating System user name
var s: string;
begin
  s := '';
  s := GetUserName(fpgetuid);
  if s='' then s := getenv('USER'); //fallback or other unixes which export $USER and don't support GetUserName
  UserName := s;
end;

function try_tmpdir(t:string):boolean;
var
  diskfreespace: Int64;
  curdir: string[255];		// NB: hopefully long enough
  subdir: string[255];		// NB: hopefully long enough
begin
  try_tmpdir := false;
  if (t='') then exit;
  subdir := 'ironseed';

  curdir := '.';
  getdir(0,curdir);
  //writeln ('currently in curdir=', curdir, ', trying tempdir=', t, ' user=', UserName());

  { handle '~' in PATH }
  if (t[1]='~') and (t[2]='/') then
   begin			{ tempdir in user $HOME }
     //tempdir := StringReplace(t, '~/', getenv('HOME')+'/', []);
     tempdir := fexpand(t);
     //writeln ('  homedir reference found, new tempdir=',tempdir);
   end
  else				{ tempdir not in $HOME }
   begin
     tempdir := fexpand(t);
     subdir := subdir + '-' + UserName();
   end;

  if tempdir[length(tempdir)]='/' then dec(tempdir[0]);
  chdir(tempdir);
  if ioresult=0 then
   begin			{ if directory exists }
     diskfreespace:=diskfree(0);
     if ioresult<>0 then errorhandler('Failure accessing tempdir '+t,5);
     if diskfreespace>128000 then
      begin			{ ... and has more than 128KiB free, then it looks OK }
        chdir (subdir);
        if (ioresult<>0) then
         begin
           chdir(tempdir);
           mkdir (subdir);
           chdir (subdir);
           if ioresult<>0 then exit;	{ can't chdir nor mkdir our 'ironseed' subdir, abort }
         end;
        tempdir := tempdir + '/' + subdir;
        try_tmpdir := true;
{$IFDEF Trace}
        writeln ('  OK, using final tempdir=', tempdir);
{$ENDIF}
      end
     else
      begin
        writeln ('not enough free space (', diskfreespace, ') in tempdir ', tempdir, ' - skipping');
      end;
   end;

  chdir(curdir);		{ restore previous current directory }
  if ioresult<>0 then errorhandler('Changing directory error,'+curdir,5);
end;


function try_savedir(s,subdir:string):boolean;
var
  diskfreespace: Int64;
  curdir: string[255];		// NB: hopefully long enough
begin
  try_savedir := false;
  if (s='') then exit;

  curdir := '.';
  getdir(0,curdir);
  //writeln ('currently in curdir=', curdir, ', trying savedir=', s, ' user=', UserName());

  savedir := fexpand(s);	{ handle '~' in PATH }
  if savedir[length(savedir)]='/' then dec(savedir[0]);

  chdir(savedir);
  if ioresult=0 then
   begin			{ if directory exists }
     diskfreespace:=diskfree(0);
     if ioresult<>0 then errorhandler('Failure accessing savedir '+s,5);
     if diskfreespace>600000 then
      begin			{ ... and has more than 8 * 73 KiB free, then it looks OK }
        if subdir<>'' then
         begin
           chdir (subdir);
           if (ioresult<>0) then
            begin
              chdir(savedir);
              mkdir (subdir);
              chdir (subdir);
              if ioresult<>0 then exit;	{ can't chdir nor mkdir our 'ironseed' subdir, abort }
            end;
           savedir := savedir + '/' + subdir;
         end;
         try_savedir := true;
{$IFDEF Trace}
         writeln ('  OK, using final savedir=', savedir);
{$ENDIF}
      end
     else
      begin
        writeln ('not enough free space (', diskfreespace, ') in savedir ', savedir, ' - skipping');
      end;
   end;

  chdir(curdir);		{ restore previous current directory }
  if ioresult<>0 then errorhandler('Changing directory error,'+curdir,5);
end;

procedure init_tmpdir;
begin
  if try_tmpdir(getenv('TMPDIR')) then exit;
  if try_tmpdir('~/.cache') then exit;
  if try_tmpdir('~/.local/share/Trash') then exit;
  if try_tmpdir(getenv('TEMP')) then exit;
  if try_tmpdir('/tmp') then exit;
  if try_tmpdir('./TEMP') then exit;

  { nothing seems to work, try to create our own TEMP dir as everything else failed }
  mkdir('./TEMP');
  if try_tmpdir('./TEMP') then exit;
  errorhandler('Failed to find usable tempdir',5);
end;

function detect_savedir(path:string):boolean;
begin
  savedir := fexpand(path);
  detect_savedir := FileExists (savedir+'/save1/SHIP.DTA') or
                    FileExists (savedir+'/save2/SHIP.DTA') or
                    FileExists (savedir+'/save3/SHIP.DTA') or
                    FileExists (savedir+'/save4/SHIP.DTA') or
                    FileExists (savedir+'/save5/SHIP.DTA') or
                    FileExists (savedir+'/save6/SHIP.DTA') or
                    FileExists (savedir+'/save7/SHIP.DTA') or
                    FileExists (savedir+'/save8/SHIP.DTA');
end;

procedure init_savedirs;
begin
  { first try if we have existing savegames in home }
  if detect_savedir ('~/.local/share/ironseed') then exit;
  if detect_savedir ('~/.ironseed') then exit;

  { no existing savegames under $HOME, try to create a new place for them }
  if try_savedir('~/.local/share', 'ironseed') then exit;
  if try_savedir('~', '.ironseed') then exit;

  errorhandler('Failed to find usable savedir',5);
end;

procedure init_dirs;
begin
  init_savedirs;
  init_tmpdir;
  if getenv('DEBUG')='1' then
   begin
    writeln;
    if not use_audio then writeln('SOUND: Disabled via environment variable NOSOUND=1');
    writeln('Using paths:');
    writeln('P_LIB='#9, prog_libdir());
    writeln('P_SHR='#9, prog_sharedir());
    writeln('EXE='#9, loc_exe());
    writeln('DATA='#9, loc_data());
    writeln('SOUND='#9, loc_sound());
    writeln('SAVENA='#9, loc_savenames());
    writeln('SAVE1='#9, loc_savegame(1));
    writeln('TMP='#9, loc_tmp());
    writeln('PRN='#9, loc_prn());
    writeln;
   end;
end;


function loc_tmp:string;
begin
  FileMode := 2; { Read/Write }
  loc_tmp := tempdir + '/';
end;

function loc_data:string;
var s:string;
begin
  FileMode := 0; { Read-only }
  s := prog_sharedir() + '/data/';
  loc_data := s;
  if FileExists(s + 'weapicon.dta') then exit;
  loc_data := './' + 'data' + '/';			{ fall back to running game in current directory, where it is in ./data/ }
end;

function loc_sound:string;
var s:string;
begin
  FileMode := 0; { Read-only }
  s := prog_sharedir() + '/sound/';
  loc_sound := s;
  if FileExists(s + 'LASER5.SAM') then exit;
  loc_sound := './' + 'sound' + '/';			{ fall back to running game in current directory, where it is in ./sound/ }
end;


function loc_savenames:string;
begin
  FileMode := 2; { Read/Write }
  loc_savenames := savedir + '/savegame.dir';
end;

function loc_savegame (const num:byte):string;
begin
  FileMode := 2; { Read/Write }
  loc_savegame := savedir + '/save' + chr(48+num) + '/';
end;

function loc_prn:string;
begin
  FileMode := 2; { Read/Write }
  loc_prn := loc_tmp() + 'LPT1';
end;

function loc_exe:string;
var s:string;
begin
  FileMode := 0; { Read-only }
  s := prog_libdir() + '/';
  loc_exe := s;
  if FileExists(s + 'crewgen') then exit;
  loc_exe := '.' + '/';					{ fall back to current dir if no executables in $libdir }
end;

begin
  use_audio := True;
  if getenv('NOSOUND')='1' then use_audio := False;
end.

