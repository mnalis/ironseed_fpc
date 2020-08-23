program namemake;

type
 nametype= string[15];
var
 i,j: integer;
 name: nametype;
 ft: text;
 f: file of nametype;

begin
 assign(ft,'makedata\newnames.txt');
 reset(ft);
 assign(f,'data\planname.txt');
 rewrite(f);
 for i:=1 to 750 do
  begin
   readln(ft,name);
   if length(name)<15 then
    for j:=length(name)+1 to 15 do name[j]:=' ';
   name[0]:=#12;
   write(f,name);
   writeln(name);
  end;
 close(ft);
 close(f);
end.

