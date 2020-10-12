unit gmouse;
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

{*********************************************
   Mouse Utilities unit for IronSeed

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2013 y-salnikov
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

{$L c_utils.o}

interface

type
 mouseicontype = array[0..15,0..15] of byte;
 mousetype =
  object
   error: boolean;
    function x:Integer;
    function y:integer;
   procedure setmousecursor(n: integer);
   function getstatus : boolean;
  end;
var

 mouse: mousetype;
 oldmouseexitproc: pointer;
 mdefault: mouseicontype;

procedure mousehide;cdecl; external;
procedure mousesetcursor(var i: mouseicontype); cdecl; external;	// NB. var should be constref
procedure mouseshow; cdecl; external;

implementation

uses utils_;

function mouse_get_status: char;cdecl ; external;
function mouse_get_x: dword;cdecl ; external;
function mouse_get_y: dword;cdecl ; external;

function mousetype.getstatus:boolean;
begin
	getstatus:=boolean(mouse_get_status);
end;




function mousetype.x:integer;
begin
	x:=integer(mouse_get_x);
end;

function mousetype.y:integer;
begin
	y:=integer(mouse_get_y);
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

procedure mousetype.setmousecursor(n: integer);
type
    weaponicontype= array[0..19,0..19] of byte;
var i: integer;
    f: file of weaponicontype;
    tempicon: ^weaponicontype;
begin
 new(tempicon);
 assign(f,loc_data()+'weapicon.dta');
 reset(f);
 if ioresult<>0 then errorhandler('weapicon.dta',1);
 seek(f,n+87);
 if ioresult<>0 then errorhandler('weapicon.dta',5);
 read(f,tempicon^);
 if ioresult<>0 then errorhandler('weapicon.dta',5);
 close(f);
 for i:=0 to 15 do
  move(tempicon^[i],mdefault[i],16);
 mousesetcursor(mdefault);
 dispose(tempicon);
end;

begin
    mouse.setmousecursor(0);

end.
