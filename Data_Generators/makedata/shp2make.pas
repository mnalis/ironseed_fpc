program huh;

uses data;

var
 i,j: integer;

procedure saveship(index,x1,y1: integer);
var shipfile: file of shipdistype;
    temp: ^shipdistype;
    i,j: integer;
begin
 new(temp);
 for j:=x1 to x1+57 do
  for i:=0 to 74 do
   temp^[j-x1,i]:=screen[y1+i,j];
 assign(shipfile,'data\shippix.dta');
 reset(shipfile);
 if ioresult<>0 then errorhandler('data\shippix.dta',1);
 seek(shipfile,index);
 if ioresult<>0 then errorhandler('data\shippix.dta',5);
 write(shipfile,temp^);
 if ioresult<>0 then errorhandler('data\shippix.dta',5);
 close(shipfile);
 dispose(temp);
end;

begin
 loadscreen('makedata\shippart.vga');
 for j:=0 to 8 do
  saveship(j,(j mod 5)*61+3,(j div 5)*77+3);
end.