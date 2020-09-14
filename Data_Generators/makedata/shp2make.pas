program shp2make;

uses data;

var shipfile: file of shipdistype;
    k: integer;

procedure saveship(index,x1,y1: integer);
var temp: ^shipdistype;
    i,j: integer;
begin
 writeln ('saving ship ', index);
 new(temp);
 for j:=x1 to x1+57 do
  for i:=0 to 74 do
   temp^[j-x1,i]:=screen[y1+i,j];
 assign(shipfile,'data/shippix.dta');
 reset(shipfile);
 if ioresult<>0 then errorhandler('data/shippix.dta',1);
 seek(shipfile,index);
 if ioresult<>0 then errorhandler('data/shippix.dta',5);
 write(shipfile,temp^);
 if ioresult<>0 then errorhandler('data/shippix.dta',5);
 close(shipfile);
 dispose(temp);
end;

begin
 assign(shipfile,'data/shippix.dta');
 rewrite(shipfile);
 if ioresult<>0 then errorhandler('data/shippix.dta',1);
 
 loadscreen('Data_Generators/makedata/shippart', @screen);
 if ioresult<>0 then errorhandler('Data_Generators/makedata/shippart',1);
 for k:=0 to 8 do
  saveship(k,(k mod 5)*61+3,(k div 5)*77+3);
end.