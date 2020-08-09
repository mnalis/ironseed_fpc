unit gmouse;
{$L c_utils.o}
{***************************
   Mouse Utilities unit for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

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
procedure mousesetcursor(i: mouseicontype); cdecl; external;
procedure mouseshow; cdecl; external;

implementation


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
 assign(f,'data/weapicon.dta');
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
