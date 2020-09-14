program makeanimationforchar;


uses crt, data;
type
 aniscrtype= array[0..34,0..48] of byte;
 aniarray= array[0..30] of aniscrtype;
var
 ani: aniscrtype;
 anifile: file of aniscrtype;
 index,i,j: integer;
 allani: ^aniarray;

begin
 loadscreen('makedata\charani.vga');
 assign(anifile,'data\charani.dta');
 rewrite(anifile);
 for index:=0 to 29 do
  begin
   for i:=0 to 34 do
    move(screen[i+(index div 6)*35,(index mod 6)*50],ani[i],49);
   write(anifile,ani);
  end;
 index:=0;
  for i:=0 to 34 do
   move(screen[i+(index div 6)*35,(index mod 6)*50],ani[i],49);
  for j:=12 to 35 do
   for i:=1 to 20 do
    ani[i,j]:=0;
 write(anifile,ani);
 reset(anifile);
 new(allani);
 for j:=0 to 30 do
  read(anifile,allani^[j]);
 close(anifile);
 j:=0;
 repeat
  inc(j);
  if j=31 then j:=0;
  for i:=0 to 34 do
   move(allani^[j,i],screen[i],49);
  delay(150);
 until fastkeypressed;
 dispose(allani);
end.