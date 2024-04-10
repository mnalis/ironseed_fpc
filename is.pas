program ironseed;
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
   Outermost Shell for IronSeed

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2013 y-salnikov
    2018 Nuke Bloodaxe
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

uses dos, version, utils_;

const
 p: array[0..4] of string[6]=
  ('/make','/play','/show','/done ','seed ');
 s: array[0..2] of string[21]=
  ('Executable not found.','Insufficient memory.','General failure.');
var
 code: word;
 str1: string[64];

procedure getdoserror;
var j: integer;
begin
 case doserror of
  1,2,5,8,9,13,16,21,26: j:=0;	{ EPERM, ENOENT, EIO, ENOEXEC, EBADF, EACCES, EBUSY, EISDIR, ETXTBUSY }
  12, 7, 14, 23, 24, 27: j:=1;	{ ENOMEM, E2BIG, EFAULT, ENFILE, EMFILE, EFBIG }
  else j:=2;
 end;
 writeln('OS Error(',doserror,'): ',s[j]);
 if j=0 then writeln('Program directory ', loc_exe(), ' does not contain the proper IS files.');
end;

begin
 init_dirs();
{$IFDEF DEMO}
 writeln('IronSeed ' + versionstring + ' Demo');
{$ELSE}
 writeln('IronSeed ' + versionstring);
{$ENDIF}
 {Write out copyright lines, which were lacking previously}
 writeln('ironseed      Copyright (C) 1994  Channel 7');
 writeln('ironseed_fpc  Copyright (C) 2013  y-salnikov');
 writeln('ironseed_fpc  Copyright (C) 2016  Nuke Bloodaxe');
 writeln('ironseed_fpc  Copyright (C) 2020-2024 Matija Nalis');

 str1:=paramstr(1)+' '+paramstr(2)+' '+paramstr(3)+' '+paramstr(4);
 code:=5;
 repeat
  case code of
   1: exec(loc_exe()+'crewgen',p[0]+p[4]+str1);
   2: exec(loc_exe()+'main',p[1]+p[4]+str1);
   3: exec(loc_exe()+'intro',p[2]+p[4]+p[3]+str1);
   4:;
   5: exec(loc_exe()+'intro',p[2]+p[4]+str1);
   49..56: exec(loc_exe()+'main',p[1]+p[4]+' '+chr(Lo(code))+' '+str1);
   else
   begin
      str(code, str1);
      writeln('Fatal Run Error! ' + str1);
      code:=4;
      exit;
    end;
  end;
  code:=dosexitcode;
 until (code=4) or (doserror<>0) or (code=0);
 if doserror<>0 then getdoserror;
end.

