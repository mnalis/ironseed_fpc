program ironseed;
//{$M 2600,0,0}
//{S-,D-,L-}

{***************************
   Outermost Shell for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

uses dos;

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
 {Write out copyright lines, which were lacking previously}
 writeln('ironseed      Copyright (C) 1994  Channel 7');
 writeln('ironseed_fpc  Copyright (C) 2013  y-salnikov');
 writeln('ironseed_fpc  Copyright (C) 2016  Nuke Bloodaxe');
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

