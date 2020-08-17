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
    along with Ironseed.  If not, see <http://www.gnu.org/licenses/>.
********************************************************************)

//{$M 2600,0,0}
//{S-,D-,L-}

{***************************
   Outermost Shell for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

uses dos, version;

const
 p: array[0..4] of string[6]=
  ('/make','/play','/show','/done ','seed ');
 s: array[0..2] of string[21]=
  ('Executable not found.','Insufficient memory.','General failure.');
var
 code: integer;
 str1: string[64];

procedure getdoserror;
var j: integer;
begin
 case doserror of
  2,18,3: j:=0;
  8: j:=1;
  else j:=2;
 end;
 writeln('DOS Error: ',s[j]);
 if j=0 then writeln('Current directory does not contain the proper IS files.');
end;

begin
{$IFDEF DEMO}
 writeln('IronSeed ' + versionstring + ' Demo');
{$ELSE}
 writeln('IronSeed ' + versionstring);
{$ENDIF}
 {Write out copyright lines, which were lacking previously}
 writeln('ironseed      Copyright (C) 1994  Channel 7');
 writeln('ironseed_fpc  Copyright (C) 2013  y-salnikov');
 writeln('ironseed_fpc  Copyright (C) 2016  Nuke Bloodaxe');
 writeln('ironseed_fpc  Copyright (C) 2020  Matija Nalis');
 str1:=paramstr(1)+' '+paramstr(2)+' '+paramstr(3)+' '+paramstr(4);
 code:=5;
 repeat
  case code of
   1: exec('crewgen',p[0]+p[4]+str1);
   2: exec('main',p[1]+p[4]+str1);
   3: exec('intro',p[2]+p[4]+p[3]+str1);
   4:;
   5: exec('intro',p[2]+p[4]+str1);
   49..56: exec('main',p[1]+p[4]+' '+chr(code)+' '+str1);
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

