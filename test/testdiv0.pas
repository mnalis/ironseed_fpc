{
see https://github.com/mnalis/ironseed_fpc/issues/26
compile with:
fpc -Mtp -g -C3 -Ci -Co -CO  -O- -gl -gw -godwarfsets  -gt -gv -vw  -Sa testdiv0.pas
}

program testdiv0;

// runtime error 200 if not using SysUtils, EDivByZero if we use SysUtils
uses sysutils, math;

var a, b, c: integer;
var r, s, t: real;

begin
//    SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);	// https://delphi.fandom.com/wiki/SetExceptionMask_Routine
    SetExceptionMask([exInvalidOp, exDenormalized, exPrecision]);    		// this helps agains floating point division by zero (but not integer one)
    a:=0;
    b:=0;
    r:=0;
    s:=0;
    writeln('start');
    t:=r/s;
    writeln('real t=',t);
    c:=a div b;
    writeln('int c=',c);
end.
