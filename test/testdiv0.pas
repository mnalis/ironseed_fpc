{
see https://github.com/mnalis/ironseed_fpc/issues/26
compile with:
fpc -Mtp -g -C3 -Ci -Co -CO  -O- -gl -gw -godwarfsets  -gt -gv -vw  -Sa testdiv0.pas
}

program testdiv0;

var a, b, c: integer;
var r, s, t: real;

begin
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
