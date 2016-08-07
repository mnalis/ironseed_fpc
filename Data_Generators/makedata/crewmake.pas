program makecrew;
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

uses crt;

type
 crewtype=
  record
   name: string[20];
   phy,men,emo,level,jobtype: integer;
   desc: array[0..9] of string[52];
  end;
var
 fs: text;
 ft: file of crewtype;
 i,j,a,b: integer;
 crew: crewtype;
 buffer: array[1..640] of char;
 done: boolean;
 c: char;

procedure breakupbuffer(size: integer);
var head,tail,index: integer;
begin
 head:=1;
 for index:=0 to 10 do
  begin
   crew.desc[index,0]:=chr(52);
   fillchar(crew.desc[index,1],52,ord(' '));
   tail:=head+51;
   if tail>size then tail:=size;
   while (buffer[tail]<>' ') and (buffer[tail]<>'.') do dec(tail);
   move(buffer[head],crew.desc[index,1],tail-head+1);
   writeln(crew.desc[index]);
   head:=tail+1;
  end;
end;

begin
 assign(fs,'makedata\crew.txt');
 reset(fs);
 assign(ft,'data\crew.dta');
 rewrite(ft);
 clrscr;
 for a:=1 to 30 do
  begin
   done:=false;
   readln(fs,crew.name); writeln(crew.name);
   if length(crew.name)<20 then
    fillchar(crew.name[length(crew.name)+1],20-length(crew.name),ord(' '));
   crew.name[0]:=chr(20);
   read(fs,crew.phy); read(fs,crew.men);
   read(fs,crew.emo);
   read(fs,crew.level); crew.level:=1;
   read(fs,c);
   j:=128;
   b:=0;
   for i:=0 to 7 do
    begin
     read(fs,c);
     if c='1' then b:=b+j;
     j:=j div 2;
    end;
   crew.jobtype:=b;
   readln(fs);
   writeln(crew.phy:3,crew.men:3,crew.emo:3,crew.level:3,crew.jobtype:3);
   i:=0;
   repeat
    readln(fs,crew.desc[i]);
    if length(crew.desc[i])=0 then done:=true;
    if length(crew.desc[i])<52 then
     for j:=length(crew.desc[i])+1 to 52 do
      crew.desc[i,j]:=' ';
    crew.desc[i,0]:=chr(52);
    writeln(crew.desc[i]);
    inc(i);
   until done;
   if i<10 then
    for j:=i to 9 do
     begin
      crew.desc[j]:='                                                    ';
      writeln(crew.desc[j]);
     end;
   write(ft,crew);
  end;
 close(fs);
 close(ft);
end.