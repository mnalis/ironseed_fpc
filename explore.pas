unit explore;
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
    along with Ironseed.  If not, see <https://www.gnu.org/licenses/>.
********************************************************************)

{*********************************************
   Planet Exploration unit for IronSeed

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2013 y-salnikov
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

{$O+}
//{$R+}

interface

procedure exploreplanet;

implementation

uses utils_, data, gmouse, journey, utils, utils2, weird, display, modplay, crewtick, heapchk;
{$PACKRECORDS 1}

type
 zoomscrtype= array[1..60,1..60] of byte;
 landtype2= array[13..133,28..268] of byte;
 probetype= record
   curx,cury,tarx,tary: integer;
   status,timeleft,fuel: integer;
   togather: integer;
  end;
 probeicontype=array[1..4,1..26,1..32] of byte;
 msgtype=array[0..7,0..15] of byte;
 elementnames= string[24];
 elementlist= array[0..170] of elementnames;
 planscantype= record
   name: string[24];
   state: byte;
  end;
 planetscan=array[1..52] of planscantype;
 msgsarray=array[1..7] of msgtype;
 amounttype= array[0..16] of byte;
 itemloctype= array[1..7,1..2] of byte;
{$PACKRECORDS DEFAULT}
var
 zoomscr,tempzoom: ^zoomscrtype;
 colorchange,donescan,showscan,doneano: boolean;
 zoomx,zoomy,zoommode,zoomoffset,batindex,que,gindex,g2index,explorelevel,
 explorecur,waterindex,water,numprobes{,i,j,a,b},index: integer;
 techlvl, tl2, biostuff: integer;
 pop: longint;
 probes: array[1..4] of probetype;
 datagathered: array[1..5,1..2] of Integer;
 landcolors,summarypic: ^landtype2;
 probeicons: ^probeicontype;
 msgs: ^msgsarray;
 scaninfo: ^planetscan;
 amounts: amounttype;
 itemloc: itemloctype;

procedure createano;
var
   j, i, a : Integer;
begin
   if (not doneano) and (datagathered[5,2]>=1000) then
   begin
      if (tempplan^[curplan].system = 45) and (tempplan^[curplan].orbit = 0) and chevent(28) then
      begin
	 tempplan^[curplan].cache[1]:=ID_TEMPORAL_ANCHOR;
	 tempplan^[curplan].cache[2]:=ID_HEAVY_CORSE_GRENADE;
	 tempplan^[curplan].cache[3]:=ID_HEAVY_CORSE_GRENADE;
	 tempplan^[curplan].cache[4]:=ID_SLING_OF_DAVID;
	 tempplan^[curplan].cache[5]:=ID_SLING_OF_DAVID;
	 tempplan^[curplan].cache[6]:=ID_THYNNE_VORTEX;
	 tempplan^[curplan].cache[7]:=ID_THYNNE_VORTEX;
	 exit;
      end;
      {printxy(160,182,'Anom!');}
      RandSeed := tempplan^[curplan].seed;
      for j:=1 to 7 do
	 if tempplan^[curplan].cache[j]=0 then
	 begin
	    i:=random(100);
	    a:=0;
	    case tempplan^[curplan].state of
	      0	  : if i<25 then a:=4000+random(21); {material}
	      1,2 : if i<76 then a:=(random(17)+500)*10; {element}
	      3: case i of
		   0..50: a:=(random(17)+500)*10; {element}
		   51..75: a:=(random(2)+3)*1000;{Unknown material or component}
		 end;
	      4: case i of
		   0..40: a:=(random(17)+500)*10; {element}
		   41..70: a:=(random(2)+3)*1000; {Unknown material or component}
		   74..75: begin {artifact}
		      a	  :=random(500);
		      if a>400 then a:=6101+a
		      else a:=6001+a;
		   end;
		 end;
	      5: case i of
		   0..65: a:=(random(2)+3)*1000; {Unknown material or component}
		   73..75: begin {artifact}
		      a	:=random(500);
		      if a>400 then a:=6101+a
		      else a:=6001+a;
		   end;
		 end;
	      6: if i<6 then {artifact}
		 begin
		    a:=random(500);
		    if a>400 then a:=6101+a
		    else a:=6001+a;
		 end;
            end;
	    tempplan^[curplan].cache[j]:=a;
	    if a>0 then
	    begin
	       itemloc[j,1]:=random(60)+30;
	       itemloc[j,2]:=random(180)+30;
	       landcolors^[itemloc[j,1]+12,itemloc[j,2]+27]:=235;
	       screen[itemloc[j,1]+12,itemloc[j,2]+27]:=235;
	    end;
	 end
	 else
	 begin
	    itemloc[j,1]:=random(60)+30;
	    itemloc[j,2]:=random(180)+30;
	    landcolors^[itemloc[j,1]+12,itemloc[j,2]+27]:=235;
	    screen[itemloc[j,1]+12,itemloc[j,2]+27]:=235;
	 end;
      doneano:=true;
   end;
end;


procedure computebiostuff;
var i, j: integer;
begin
   biostuff:=0;
   if(landcolors<>nil) then
   begin
   for j:=28 to 267 do
      for i:=13 to 132 do
      	begin
	    if (landcolors^[i,j]>47) and (landcolors^[i,j]<64) then inc(biostuff);
//   	    write(i,' ',j);
//	    writeln('   done ');
	end;
    end;
   techlvl:=-2;

   case tempplan^[curplan].system of
     93,138,78,191,171,221 :
     if (tempplan^[curplan].orbit <> 0) then
     begin
	techlvl:=6;
	tl2:=0;
	exit;
     end;
     45			   :
	  if (tempplan^[curplan].orbit <> 0) and not chevent(27) then
	  begin
	     techlvl:=6;
	     tl2:=0;
	     exit;
	  end else begin
	     techlvl:=-2;
	     exit;
	  end;
   end;
   case tempplan^[curplan].state of
     2: case tempplan^[curplan].mode of
	  2: techlvl:=-1;
	  3: begin
		techlvl:=0;
		tl2:=tempplan^[curplan].age div 15000000;
	     end;
	end;
     3: begin
	   techlvl:=tempplan^[curplan].mode-1;
	   case tempplan^[curplan].mode of
	     1: tl2:=tempplan^[curplan].age div 1500000;
	     2: tl2:=tempplan^[curplan].age div 1000;
	     3: tl2:=tempplan^[curplan].age div 800;
	   end;
	end;
     4: begin
	   techlvl:=tempplan^[curplan].mode+2;
	   case tempplan^[curplan].mode of
	     1: tl2:=tempplan^[curplan].age div 400;
	     2: tl2:=tempplan^[curplan].age div 200;
	     3: tl2:=0;
	   end;
	end;
     5: case tempplan^[curplan].mode of
	  1: begin
		techlvl:=0;
		tl2:=tempplan^[curplan].age div 100000000;
		if tl2>9 then tl2:=9;
	     end;
	  2: techlvl:=-1;
	end;
     7: begin
	   techlvl:=-2;
	   biostuff:=0;
	end;
   end;
end;

procedure generatescanlist;
var scanfile : file of scantype;
    temp     : ^scantype;
    elemfile : file of elementlist;
    namelist : ^elementlist;
    already  : array[0..9] of byte;
   j, i, a   : Integer;
begin
 {if tempplan^[curplan].state=7 then exit;}
 new(temp);
 new(namelist);
 assign(scanfile,loc_data()+'scan.dta');
 reset(scanfile);
 if ioresult<>0 then errorhandler('scan.dta',1);
 read(scanfile,temp^);
 if ioresult<>0 then errorhandler('scan.dta',5);
 close(scanfile);
 assign(elemfile,loc_data()+'elements.dta');
 reset(elemfile);
 if ioresult<>0 then errorhandler('elements.dta',1);
 read(elemfile,namelist^);
 if ioresult<>0 then errorhandler('elements.dta',5);
 close(elemfile);
 for j:=1 to 52 do
  begin
   scaninfo^[j].name:='';
   scaninfo^[j].state:=4;
  end;
 index:=1;
 randseed:=tempplan^[curplan].seed;
 for j:=0 to 16 do
  begin
   amounts[j]:=temp^[j,tempplan^[curplan].state];
   already[0]:=0;	// to turn off warnings, variables are actually correctly initialized by function below
   fillchar(already,10,0);
   if temp^[j,tempplan^[curplan].state]>0 then
    for i:=1 to temp^[j,tempplan^[curplan].state] do
     begin
      repeat
       a:=random(10);
      until already[a]=0;
      already[a]:=1;
      scaninfo^[index].name:=namelist^[a+1+j*10];
      case tempplan^[curplan].state of
       0: scaninfo^[index].state:=temp^[j,7];
       1: scaninfo^[index].state:=temp^[j,8];
       2,3,4: scaninfo^[index].state:=temp^[j,9];
       5: scaninfo^[index].state:=temp^[j,10];
       6: scaninfo^[index].state:=temp^[j,11];
      end;
      inc(index);
    end;
  end;
 dispose(temp);
 dispose(namelist);
end;

procedure setcolors;
begin
 water:=50;
 colorchange:=true;
 case tempplan^[curplan].state of
  0: colorchange:=false;
  1: begin
      gindex:=0;
      g2index:=144;
      waterindex:=80;
     end;
  2: begin
      gindex:=0;
      g2index:=144;
      waterindex:=33;
     end;
  3: begin
      gindex:=0;
      g2index:=144;
      waterindex:=32;
     end;
  4: begin
      gindex:=0;
      g2index:=144;
      waterindex:=32;
      water:=40;
     end;
  5: begin
      gindex:=0;
      g2index:=144;
      waterindex:=32;
      if tempplan^[curplan].mode=3 then
       begin
        water:=0;
       end
      else
       begin
        water:=30;
       end;
     end;
  6: begin
      if tempplan^[curplan].mode=2 then colorchange:=false;
      gindex:=0;
      g2index:=144;
      waterindex:=32;
      water:=0;
     end;
  7: colorchange:=false;
 end;
end;

procedure zoom3x(x1,y1: integer);
var temp      : shortint;
   a, b, i, j : Integer;
begin
 rectangle(x1+28,y1+13,x1+48,y1+33);
 for a:=0 to 20 do
  for b:=0 to 20 do
   for i:=-1 to 1 do
    for j:=-1 to 1 do
     if ((a*3+j)<61) and ((a*3+j)>0) and ((b*3+i)<61) and ((b*3+i)>0) then
      begin
       temp:=round((landform^[x1+a+j,y1+b+i]-landform^[x1+a,y1+b])/3);
       if landcolors^[y1+b+12,x1+a+27]=235 then zoomscr^[a*3+j,b*3+i]:=255
        else zoomscr^[a*3+j,b*3+i]:=landform^[x1+a,y1+b]+temp;
      end;
end;

procedure zoom2x(x1,y1: integer);
var temp : shortint;
   a, b	 : Integer;
begin
 rectangle(x1+28,y1+13,x1+58,y1+43);
 if colorchange then
  for a:=0 to 29 do
   for b:=0 to 29 do
    begin
     zoomscr^[a*2+1,b*2+1]:=landform^[x1+a,y1+b];
     temp:=round((landform^[x1+a+1,y1+b]-landform^[x1+a,y1+b])/2);
     zoomscr^[a*2+2,b*2+1]:=landform^[x1+a,y1+b]+temp;
     temp:=round((landform^[x1+a,y1+b+1]-landform^[x1+a,y1+b])/2);
     zoomscr^[a*2+1,b*2+2]:=landform^[x1+a,y1+b]+temp;
     temp:=round((landform^[x1+a+1,y1+b+1]-landform^[x1+a,y1+b])/2);
     zoomscr^[a*2+2,b*2+2]:=landform^[x1+a,y1+b]+temp;
     if landcolors^[y1+b+12,x1+a+27]=235 then
      zoomscr^[a*2+1,b*2+1]:=255;
    end
 else
  for a:=0 to 29 do
   for b:=0 to 29 do
    begin
     temp:=landform^[x1+a,y1+b];
     zoomscr^[a*2+1,b*2+1]:=temp;
     zoomscr^[a*2+2,b*2+1]:=temp;
     zoomscr^[a*2+1,b*2+2]:=temp;
     zoomscr^[a*2+2,b*2+2]:=temp;
    end;
end;

procedure zoom1x(x1,y1: integer);
var
   a	 : Integer;
begin
 rectangle(x1+28,y1+13,x1+88,y1+73);
 for a:=1 to 60 do
  move(landform^[x1+a,y1],zoomscr^[a,1],15*4);
end;

procedure undozoom;
var
   i, j : Integer;
begin
 for i:=0 to 60 do
  for j:=0 to 60 do
   if ((zoomy+i)<120) and ((zoomx+j)<240) then
    screen[zoomy+i+13,zoomx+j+28]:=landcolors^[zoomy+i+13,zoomx+j+28];
end;

procedure showzoom;
var part,part2 : real;
   i, j, a, b  : Integer;
begin
 part:=73/(255-water);
 if water>0 then part2:=5/water else part2:=0;
 if colorchange then
  for j:=1 to 60 do
   for i:=1 to 60 do
    begin
     if zoomscr^[j,i]=255 then tempzoom^[i,j]:=95
     else if zoomscr^[j,i]<water then
      tempzoom^[i,j]:=waterindex+round(part2*zoomscr^[j,i])
     else
      begin
       index:=round((zoomscr^[j,i]-water)*part);
       case index of
        42..73: index:=g2index+index-10;
        11..41: index:=gindex+index-10;
        0..10: index:=spcindex[index div 2];
	end;
        if index=64 then index:=95;

       tempzoom^[i,j]:=index;
      end;
    end
 else
  for i:=1 to 60 do
   for j:=1 to 60 do
    tempzoom^[i,j]:=zoomscr^[j,i];
 if random(2)=0 then
  begin
   a:=random(7)+1;
   for b:=0 to 15 do
    for i:=0 to 7 do
     if msgs^[a,i,b]<>0 then tempzoom^[i+52,b+43]:=msgs^[a,i,b];
  end;
 if random(2)=0 then
  begin
   a:=random(7)+1;
   for b:=0 to 15 do
    for i:=0 to 7 do
     if msgs^[a,i,b]<>0 then tempzoom^[i+8,b+4]:=msgs^[a,i,b];
  end;
 for j:=1 to 7 do if tempplan^[curplan].cache[j]>0 then
  case zoommode of
   2: if (abs(itemloc[j,1]-zoomy-15)<3) and (abs(itemloc[j,2]-zoomx-14)<4) then
       begin
        a:=random(7)+1;
        for b:=0 to 15 do
         for i:=0 to 7 do
          if msgs^[a,i,b]<>0 then
           begin
            tempzoom^[i+8,b+43]:=msgs^[a,i,b]+32;
            tempzoom^[i+52,b+4]:=msgs^[a,i,b]+32;
           end;
       end;
   3: if (abs(itemloc[j,1]-zoomy-11)<4) and (abs(itemloc[j,2]-zoomx-10)<4) then
       begin
        a:=random(7)+1;
        for b:=0 to 15 do
         for i:=0 to 7 do
          if msgs^[a,i,b]<>0 then
           begin
            tempzoom^[i+8,b+43]:=msgs^[a,i,b]+32;
            tempzoom^[i+52,b+4]:=msgs^[a,i,b]+32;
           end;
       end;
  end;
 setcolor(47);
 mousehide;
 for i:=1 to 60 do
  scrto_move(tempzoom^[i],screen[i+138,206],15*4);
 circle(236,169,8*zoommode);
 circle(236,169,4*zoommode);
 mouseshow;
end;

procedure landsprinkle(seed: integer);
var index  : integer;
   x, y, j : Integer;
begin
 mousehide;
 index:=-1;
 j:=0;
 repeat
  inc(index);
  j:=j+seed;
  if j>28799 then j:=j-28800;
  y:=13+(j div 240);
  x:=28+(j mod 240);
  screen[y,x]:=landcolors^[y,x];
  if index mod 50=0 then
   begin
    if not fastkeypressed then delay(tslice div 9);
   end;
 until index=28799;
 mouseshow;
end;

procedure summarysprinkle(seed: integer);
var index : integer;
   j	  : Integer;
begin
 mousehide;
 index:=-1;
 j:=0;
 repeat
  inc(index);
  j:=j+seed;
  if j>28799 then j:=j-28800;
  y:=13+(j div 240);
  x:=28+(j mod 240);
  screen[y,x]:=summarypic^[y,x];
  if index mod 50=0 then delay(tslice div 9);
 until index=28799;
 mouseshow;
end;

procedure displaylandform;
var part,part2 : real;
   {part:scales what is above the water level to 0 to 31}
   {part2:scales what is pelow the water level to 0 to 5}
    index  : integer;
    i, j   : Integer;
begin
   part:=31/(255-water);
   if water>0 then part2:=5/water else part2:=0;
   if colorchange then
      for i:=1 to 120 do
	 for j:=1 to 240 do
	 begin
	    {if landform^[j,i]=255 then landform^[j,i]:=254;}
	    if landform^[j,i]<water then
	       landcolors^[i+12,j+27]:=round(landform^[j,i]*part2)+waterindex
	    else if landform^[j,i] <= 246 then
	    begin
	       index:=round((landform^[j,i]-water)*part);
	       case index of
		 16..31: index:=index*2+g2index;
		 6..15:index:=index*2+gindex;
		 0..5: index:=spcindex[index];
	       end;
	       landcolors^[i+12,j+27]:=index;
	    end;
	 end
	 else
	    for i:=1 to 120 do
	       for j:=1 to 240 do
		  landcolors^[i+12,j+27]:=landform^[j,i];
   if datagathered[5,2]>=1000 then
   begin
      doneano:=true;
      for j:=1 to 7 do if tempplan^[curplan].cache[j]>0 then
      begin
	 itemloc[j,1]:=random(60)+30;
	 itemloc[j,2]:=random(180)+30;
	 landcolors^[itemloc[j,1]+12,itemloc[j,2]+27]:=235;
	 screen[itemloc[j,1]+12,itemloc[j,2]+27]:=235;
      end;
   end;
   landsprinkle(19);
end;

procedure moveprobe(num: integer);
var
   a, i : Integer;
begin
 with probes[num] do
  begin
   dec(fuel);
   screen[cury+12,curx+27]:=landcolors^[cury+12,curx+27];
   if curx<tarx then inc(curx)
    else if curx>tarx then dec(curx);
   if cury<tary then inc(cury)
    else if cury>tary then dec(cury);
   if (curx=tarx) and (cury=tary) then
    begin
     status:=4;
     timeleft:=80+random(50);
     exit;
    end;
   screen[cury+12,curx+27]:=90+random(6);
   a:=num*40-26;
   for i:=1 to 26 do
    scrfromto_move(screen[cury-1+i,curx+11],screen[i+a,281],8*4);
  end;
end;

procedure showplanet(num: integer);
var indexi,indexj,i,j,a: integer;
begin
 for i:=1 to 26 do
  scr_fillchar(screen[i+num*40-26,276],36,0);
 for a:=30 downto 4 do
  begin
   indexi:=0;
   i:=num*40-31;
   repeat
    inc(indexi,a);
    inc(i);
    indexj:=0;
    j:=276;
    repeat
     inc(indexj,a);
     inc(j);
     if (indexi<121) and (indexj<121) then screen[i+a,j+a]:=planet^[indexi,indexj];
    until (indexj>119);
   until (indexi>119);
   delay(tslice);
  end;
end;

procedure printxy2(x1,y1: integer; s: string);
var j,i,letter,x,y,a: integer;
begin
 x1:=x1+4;
 for j:=1 to length(s) do
  begin
   case s[j] of
     'a'..'z': letter:=ord(s[j])-40;
    ' ' ..'"': letter:=ord(s[j])-31;
    ''''..'?': letter:=ord(s[j])-35;
    'A' ..'Z': letter:=ord(s[j])-36;
    '%': letter:=55;
    else letter:=1;
   end;
   y:=y1;
   for i:=0 to 5 do
    begin
     inc(y);
     x:=x1;
     for a:=7 downto 4 do
      begin
       inc(x);
       if font[ship.options[OPT_FONT],letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor
        else if bkcolor<255 then screen[y,x]:=bkcolor;
      end;
     inc(i);
     inc(y);
     x:=x1;
     for a:=3 downto 0 do
      begin
       inc(x);
       if font[ship.options[OPT_FONT],letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor
        else if bkcolor<255 then screen[y,x]:=bkcolor;
      end;
    end;
    x1:=x1+5;
    for i:=1 to 6 do screen[y1+i,x1]:=bkcolor;
  end;
end;

procedure printhighest;
var j,max,cargindex,total: integer;
    str1: string[10];
    angle: real;
    amounts2: amounttype;
begin
 y:=0;
 cargindex:=1;
 while (cargo[cargindex].index<ID_FIRST_ELEMENT) do inc(cargindex);
 total:=0;
 angle:=0;
 amounts2:=amounts;
 for j:=0 to 16 do total:=total+amounts2[j];
 setcolor(80);
 setfillstyle(1,80);
 pieslice(63,114,0,360,20);
 repeat
  max:=amounts2[0];
  index:=0;
  for j:=0 to 16 do if amounts2[j]>max then
   begin
    max:=amounts2[j];
    index:=j;
   end;
  if max>0 then
   begin
    x1:=max/total*100;
    str(x1:5:2,str1);
    tcolor:=95 - y*3;
    printxy2(120,101+y*6,str1+'% '+cargo[cargindex+index].name);
    setcolor(tcolor);
    setfillstyle(1,tcolor);
    if round(x1*3.6+angle+5)>360 then pieslice(63,114,round(angle),360,20)
     else pieslice(63,114,round(angle),round(x1*3.6+angle+5),20);
    angle:=x1*3.6+angle;
    amounts2[index]:=0;
   end;
  inc(y);
 until y=4;
 tcolor:=80;
 max:=0;
 for j:=0 to 16 do max:=max+amounts2[j];
 if max>0 then
  begin
   x1:=max/total;
   str((x1*100):5:2,str1);
   printxy2(120,125,str1+'% Other');
  end;
 tcolor:=31;
end;

procedure printslice(angle1 : real; angle2 : real; row : word; val : real; str0 : String);
var
   str1	: string[10];
begin
   str(val:5:2,str1);
   tcolor:=95 - row*3;
   printxy2(120,101+row*6,str1+'% '+str0);
   setcolor(tcolor);
   setfillstyle(1,tcolor);
   if round(angle2+5)>360 then pieslice(63,114,round(angle1),360,20)
   else pieslice(63,114,round(angle1),round(angle2+5),20);
end;

procedure printhigheststar;
var
   hydrogen : word;
   helium   : word;
   other    : word;
begin
   other := random(200) + 1;
   helium := random(500) + 2300;
   hydrogen := 10000 - other - helium;
   setcolor(80);
   setfillstyle(1,80);
   pieslice(63,114,0,360,20);

   printslice(0, hydrogen*0.036, 0, hydrogen / 100, 'Hydrogen');
   printslice(hydrogen*0.036, (Int64(hydrogen) + Int64(helium))*0.036, 1, helium / 100, 'Helium');
   printslice((Int64(hydrogen) + Int64(helium))*0.036, 360, 2, other / 100, 'Other');
   tcolor:=31;
end;

procedure summaryinfo;
var str1     : string[15];
    grav,atm : real;
   i, j	     : Integer;
begin
 if donescan then
  begin
   summarysprinkle(109);
   showscan:=true;
   exit;
  end;
 mousehide;
 for i:=13 to 133 do
  scr_fillchar(screen[i,28],240,0);
 for i:=147 to 196 do
  scr_fillchar(screen[i,6],125,0);
 randseed:=tempplan^[curplan].seed;
 tcolor:=207;
 if tempplan^[curplan].state <> 7 then
    printxy(113,14,'Planet Summary')
 else
    printxy(118,14,'Star Summary');
 tcolor:=192;
 printxy(50,21,'Seismic Activity');
 printxy(40,27,'Atmospheric Activity');
 printxy(40,33,'Atmospheric Pressure');
 printxy(50,39,'Relative Gravity');
 printxy(55,45,'Per Cent Hydro');
 printxy(60,51,'Per Cent Bio');
 printxy(65,57,'Life Forms');
 printxy(65,63,'Population');
 printxy(49,69,'Technology Level');
 printxy(62,75,'Temperature');
 printxy(52,81,'Surface Radiation');
 if tempplan^[curplan].state <> 7 then
    printxy(60,87,'Planet State')
 else
    printxy(45,87,'Star Classification');
 tcolor:=207;
 printxy(95,94,'Most Common Compounds');
 tcolor:=31;
 if tempplan^[curplan].state <> 7 then
    printhighest
 else
    printhigheststar;
 case tempplan^[curplan].state of
    0: str1:='None';
  1,7: if random(2)=0 then str1:='Heavy' else str1:='Massive';
  2,3: if random(2)=0 then str1:='Mild' else str1:='Moderate';
    4: if random(2)=0 then str1:='Calm' else str1:='Mild';
  5,6: if random(2)=0 then str1:='None' else str1:='Calm';
 end;
 printxy(240-length(str1)*5,21,str1);
 x1:=abs(tempplan^[curplan].orbit-7)*(tempplan^[curplan].psize+1) + tempplan^[curplan].water;
 j:=(round(x1) mod 5) + 1;
 printxy(200,27,activity[j]);
 grav:=(tempplan^[curplan].psize+1)*((random(30)+1)/15);
 case tempplan^[curplan].state of
  0: i:=17;
  1: i:=12;
  2: i:=3;
  3: i:=4;
  4: i:=3;
  5: i:=3;
  6: i:=2;
  7: begin
	i:=10;
	grav := grav * 10 + random(10);
     end;
 end;
 atm:=grav*(i/(tempplan^[curplan].psize+1));
 str(atm:5:2,str1);
 printxy(195,33,str1+' Atm');
 str(grav:5:2,str1);
 printxy(205,39,str1+' G');
 x:=0;
 for j:=28 to 267 do{268}
  for i:=13 to 132 do{138}
   if (landcolors^[i,j]>31) and (landcolors^[i,j]<48) then inc(x,2)
   else if (landcolors^[i,j]<63) and (landcolors^[i,j]>47) then inc(x);
 str((x/58322*100):5:2,str1);
 printxy(210,45,str1+'%');
 x1:=(abs(tempplan^[curplan].orbit-7)*atm+(50-tempplan^[curplan].water) mod 7)/2;
 if x1<0 then x1:=0;
 case round(x1) of
  0: str1:='Subarctic';
  1: str1:='Arctic';
  2: str1:='Cold';
  3: str1:='Cool';
  4: str1:='Moderate';
  5: str1:='Warm';
  6: str1:='Tropical';
  7: str1:='Searing';
  else str1:='Infernal';
 end;
 printxy(240-length(str1)*5,75,str1);
 x1:=abs(tempplan^[curplan].orbit-7)/atm*5;
 str(x1:7:2,str1);
 printxy(170,81,str1+' RAD/Yr');
 case tempplan^[curplan].state of
  0: printxy(205,87,'Gaseous');
  1: printxy(210,87,'Active');
  2: printxy(210,87,'Stable');
  3: printxy(190,87,'Early Life');
  4: printxy(175,87,'Advanced Life');
  5: printxy(215,87,'Dying');
  6: printxy(220,87,'Dead');
  7: begin
	case tempplan^[curplan].mode of
	  1: printxy(200,87,'Red Star');
	  2: printxy(185,87,'Yellow Star');
	  3: printxy(190,87,'White Star');
	end;
     end;
 end;
 str((biostuff/29161*100):5:2,str1);
 printxy(210,51,str1+'%');
 if (tempplan^[curplan].state=6) and (tempplan^[curplan].mode=2) then
  begin
   printxy(169,57,'Void Dwellers');
   printxy(205,63,'Unknown');
   printxy(225,69,'6.0');
  end
 else
 case techlvl of
    -2: begin
         printxy(205,57,'No Life');
         printxy(220,63,'None');
         printxy(220,69,'None');
        end;
    -1: begin
         randseed:=tempplan^[curplan].seed;
         j:=random(word(tempplan^[curplan].state+tempplan^[curplan].mode+tempplan^[curplan].seed)) mod 3;
         case j of
          0: if random(2)=0 then printxy(140,57,'Short Chain Proteins')
              else printxy(145,57,'Long Chain Proteins');
          1: if random(2)=0 then printxy(150,57,'Simple Protoplasms')
              else printxy(145,57,'Complex Protoplasms');
          2: begin
              case random(3) of
               0: str1:='Chaosms';
               1: str1:='Communes';
               2: str1:='Hierarchies';
              end;
              printxy(175 - length(str1)*5,57,'Singlecelled '+str1);
             end;
         end;
         printxy(180,63,'Uncomputable');
         printxy(165,69,'No Intelligence');
        end;
  0..5: begin
         if techlvl>0 then
          begin
           pop:=2000;
           for j:=0 to techlvl do pop:=pop*10;
          end
         else pop:=10;
         randseed:=tempplan^[curplan].seed;
         pop:=round(pop/10*tl2)+pop+random(pop div 1000);
         str(pop,str1);
         case length(str1) of
            0..3: printxy(225-length(str1)*5,63,str1+'000');
            4..6: begin
                   str1[0]:=chr(ord(str1[0])-3);
                   printxy(200-length(str1)*5,63,str1+' Million');
                  end;
            7..9: begin
                   str1[0]:=chr(ord(str1[0])-6);
                   printxy(200-length(str1)*5,63,str1+' Billion');
                  end;
          10..12: begin
                   str1[0]:=chr(ord(str1[0])-9);
                   printxy(195-length(str1)*5,63,str1+' Trillion');
                  end;
         end;
         randseed:=tempplan^[curplan].seed;
         str1:=alientypes[random(11)];
         case random(5) of
          0: printxy(180-length(str1)*5,57,'Carnivorous '+str1);
          1: printxy(180-length(str1)*5,57,'Herbivorous '+str1);
          2: printxy(185-length(str1)*5,57,'Omnivorous '+str1);
          3: printxy(170-length(str1)*5,57,'Cannibalistic '+str1);
          4: printxy(165-length(str1)*5,57,'Photosynthetic '+str1);
         end;
         str1[0]:=chr(3);
         str1[1]:=chr(techlvl+48);
         str1[2]:='.';
         str1[3]:=chr(tl2+48);
         printxy(225,69,str1);
        end;
 end;
 for i:=13 to 132 do
  scrfrom_move(screen[i,28],summarypic^[i,28],240);
 mouseshow;
 donescan:=true;
 showscan:=true;
 tempplan^[curplan].notes:=tempplan^[curplan].notes or 1;
 setcolor(47);
 tcolor:=207;
end;

procedure refreshinfogathered(force : boolean) ;
var
   strs	: string[5];
   j	: Integer;
begin
   for j:=1 to 5 do
      if force or (datagathered[j,1] <> datagathered[j,2]) then
      begin
	 datagathered[j,1] := datagathered[j,2];
	 str(datagathered[j,2] : 3, strs);
	 inc(strs[0]);
	 strs[4] := strs[3];
	 strs[3] := '.';
	 if datagathered[j,2] < 10 then
	    strs[2] := '0';
	 if datagathered[j,2] < 1000 then printxy(10 + 5*13,152+j*7,strs+'%')
	 else printxy(10 + 5*13,152+j*7,'Completed.');
      end;
end;

procedure displayinfogathered;
var
    a, j, i: integer;
begin
   mousehide;
   if explorelevel <> 0 then
   begin
      for i:=147 to 196 do
	 scr_fillchar(screen[i,5],128,0);
      refreshinfogathered(true);
   end else
      refreshinfogathered(false);

   printxy(6,148,'Information Gathered');
   for j:=1 to 5 do
   begin
      printxy(10,152+j*7,scantypes[j]);
   end;
   mouseshow;
   explorelevel:=0;
   a:=0;
   for j:=1 to 5 do
      if datagathered[j,2]>=1000 then
      begin
	 tempplan^[curplan].notes:=tempplan^[curplan].notes or (1 shl (j+1));
	 inc(a);
      end;
   {str(numprobes,strs);
   printxy(160,194,strs);}
   for j := 1 to numprobes do
      if probes[j].status <> 0 then
	 a := 0;
   if a=5 then
   begin
      if not donescan then summaryinfo;
      exit;
   end;
   {str(numprobes,strs);
   printxy(160,188,strs);}
end;

procedure SetScan(nextscan : Integer);
var
   i, y, x, c	:Integer ;
begin
   if (nextscan <> 0) and (abs(nextscan) <= 5) and (datagathered[abs(nextscan),2] < 1000) then
      que := nextscan;
   for i := 1 to 5 do
   begin
      if i = que then
	 c := 127 and 240
      else if datagathered[i,2] < 1000 then
	 c := 95 and 240
      else
	 c := 63 and 240;
      for y := 2 to 5 do
	 for x := 2 to 20 do
	 begin
	    if screen[9 * i + 21 - 9 + y, x] >= 32 then
	       screen[9 * i + 21 - 9 + y, x] := (screen[9 * i + 21 - 9 + y, x] and 15) or c;
	 end;
      {for y := 3 to 4 do
      begin
	 screen[9 * i + 21 - 9 + y, 22] := c;
      end;
      }
   end;
end;


procedure controlprobes;
var
   a, b, i, j : Integer;
   dirty      : Boolean;
begin
 mousehide;
 dirty:=false;
 for j:=1 to numprobes do
  with probes[j] do
   begin
    case status of
     3: begin {moving/gathering}
	   if (datagathered[1,2] < 1000) or
              (datagathered[2,2] < 1000) or
              (datagathered[3,2] < 1000) or
              (datagathered[4,2] < 1000) or
              (datagathered[5,2] < 1000)
	      then
	      moveprobe(j)
	   else
	   begin
	      screen[tary+12,tarx+27]:=landcolors^[tary+12,tarx+27];
	      for i:=1 to 26 do
		 scrto_move(probeicons^[4,i],screen[i+j*40-26,281],8*4);
	      timeleft:=70;
	      status:=5;
	   end;
	   {i := random(10) + 1;
	   if (i <= 5) and (datagathered[i,2] < 1000) and SkillTest(True, 3, 50, 10) then
	   begin
	      inc(datagathered[i,2], 2);
	      if explorelevel = 0 then
		 displayinfogathered;
	   end;}
	end;
     4: begin {analysing}
	   dec(timeleft);
	   if (timeleft=0) and (fuel>0) and (
	      (datagathered[1,2] < 1000) or
              (datagathered[2,2] < 1000) or
              (datagathered[3,2] < 1000) or
              (datagathered[4,2] < 1000) or
              (datagathered[5,2] < 1000))
	      then
	   begin {begin move to next location}
	      status:=3;
	      tarx:=random(200)+20;
	      tary:=random(80)+20;
	   end
	   else if timeleft=0 then
	   begin {begin return to craft}
	      screen[tary+12,tarx+27]:=landcolors^[tary+12,tarx+27];
	      for i:=1 to 26 do
		 scrto_move(probeicons^[4,i],screen[i+j*40-26,281],8*4);
	      timeleft:=70;
	      status:=5;
	   end
	   else
	   begin {perform scan}
	      if que <> 0 then
	      begin
		 {i := random(11);}
		 i := (SkillRange(True, 3, 5, 10) + 20) * 10 div 100;
		 inc(datagathered[abs(que),2],i);
		 if datagathered[abs(que),2] >= 1000 then
		 begin
		    createano;
		    datagathered[abs(que),2] := 1000;
		    if que > 0 then
		    begin
		       que := 0;
		       SetScan(0);
		       for i := 1 to 5 do
		       begin
			  if datagathered[i,2] < 1000 then
			  begin
			     SetScan(i);
			     break;
			  end;
		       end;
		    end else begin
		       que := 0;
		       SetScan(0);
		    end;
		 end;
		 dirty := true;
		 {if explorelevel = 0 then
		    displayinfogathered;}
	      end;
	      (*i := random(10) + 1;
	      if i > 5 then
		 i := que;
	      if (i <= 5) and (datagathered[i,2] < 1000) and SkillTest(True, 3, 5, 10) then
	      begin
		 inc(datagathered[i,2],5);
		 {a := 10;
		 while (datagathered[i,2] < 1000) and (SkillTest(True, 3, a, 0)) do
		 begin
		    inc(a, 20);
		    inc(datagathered[i,2]);
		 end;}
		 if datagathered[i,2] > 1000 then
		    datagathered[i,2] := 1000;
		 if explorelevel = 0 then
		    displayinfogathered;
	      end;*)
	      screen[cury+12,curx+27]:=90+random(6);
	      for i:=1 to 26 do
		 scrfromto_move(screen[cury-1+i,curx+12],screen[i+j*40-26,281],8*4);
	      for b:=1 to 26 do
		 for a:=1 to 31 do
		    if probeicons^[1,b,a]<>0 then screen[j*40-26+b,280+a]:=probeicons^[1,b,a];
	      a:=random(7)+1;
	      for b:=0 to 15 do
		 for i:=0 to 7 do
		    if msgs^[a,i,b]<>0 then screen[j*40-7+i,297+b]:=msgs^[a,i,b];
	   end;
	end;
     0: if que>0 then {launch probe}
	begin
	   if (datagathered[1,2] < 1000) or
              (datagathered[2,2] < 1000) or
              (datagathered[3,2] < 1000) or
              (datagathered[4,2] < 1000) or
              (datagathered[5,2] < 1000) then
           {if datagathered[que,1]<1000 then}
	   begin
	      {inc(datagathered[que,1]);}
	      togather:=abs(que);
	      status:=1;
	      timeleft:=20;
	      showplanet(j);
	      {if tempplan^[curplan].orbit=0 then
	      begin
		 status:=7;
		 removecargo(ID_PROBOT);
		 que := -abs(que);
		 SetScan(0);
	      end;}
	      if ((techlvl>=4) and (random(100)<25)) or ((techlvl=3) and (random(100)<5)) then
	      begin
		 status:=7;
		 removecargo(ID_PROBOT);
		 que := -abs(que);
		 SetScan(0);
		 {dec(datagathered[que,1]);}
	      end;
	      if (ship.options[OPT_DIFFICULTY]=0) and (que<>0) then tempplan^[curplan].notes:=tempplan^[curplan].notes or (1 shl (abs(que)+1));
	      if datagathered[abs(que),2] >= 1000 then
	      begin
		 createano;
		 if que > 0 then
		 begin
		    que := 0;
		    for i := 1 to 5 do
		       if datagathered[i,2] < 1000 then
		       begin
			  que := i;
			  break;
		       end;
		 end else begin
		    que := 0;
		 end;
		 SetScan(0);
              end;
	   end
	   else que := 0;
	end;
     7: for b:=1 to 27 do {destroyed}
         for a:=1 to 31 do
          screen[j*40-26+b,280+a]:=random(16)+16;
    else
     begin
      dec(timeleft);
      if timeleft=0 then
       case status of
        1: begin {landing}
	      timeleft:=40;
	      status:=2;
	      fuel:=50;
	      for b:=1 to 26 do
		 for a:=1 to 31 do
		    if probeicons^[4,b,a]<>0 then screen[j*40-26+b,281+a]:=probeicons^[4,b,a];
	   end;
        2: begin {landed}
	      curx:=random(180)+30;
	      cury:=random(60)+30;
	      tarx:=random(180)+30;
	      tary:=random(60)+30;
	      scr_fillchar(screen[j*40+1,281],30,0);
	      status:=3;
	      for i:=1 to 30 do
		 scr_fillchar(screen[j*40-26+i,281],32,0);
	   end;
        5: begin {returning}
	      for i:=1 to 26 do
		 scrto_move(probeicons^[3,i],screen[i+j*40-26,281],8*4);
	      timeleft:=40;
	      status:=6;
	   end;
        6: begin {refueling}
	      status := 8;
	      timeleft:=10;
	      for i := 1 to 26 do
		 scrto_move(probeicons^[2,i],screen[i+j*40-26,281],8*4);
	      dirty := true;
	      {if explorelevel = 0 then
		 displayinfogathered;}
	      {inc(datagathered[togather,2]);
	      if (datagathered[togather,2]=2) or (explorelevel=0)
	      then displayinfogathered;}
	   end;
       8: begin {cool down}
	     status := 0;
	     dirty := true;
	     {if explorelevel = 0 then
		displayinfogathered
	     else }
		if (datagathered[1,2] >= 1000) and
		   (datagathered[2,2] >= 1000) and
		   (datagathered[3,2] >= 1000) and
		   (datagathered[4,2] >= 1000) and
		   (datagathered[5,2] >= 1000) then
		begin
		   dirty := false;
		   displayinfogathered;
		end;
	  end;
       end;
    end;
   end;
   printxy(269,4+j*40,probetext[status]);
  end;
 if dirty and (explorelevel = 0) then
    displayinfogathered;

 if not showscan then
  case zoommode of
   1: rectangle(zoomx+28,zoomy+13,zoomx+88,zoomy+73);
   2: rectangle(zoomx+28,zoomy+13,zoomx+58,zoomy+43);
   3: rectangle(zoomx+28,zoomy+13,zoomx+48,zoomy+33)
  end;
 mouseshow;
end;

procedure undo;
begin
 mousehide;
 undozoom;
 mouseshow;
end;

procedure redraw;
begin
 mousehide;
 case zoommode of
  1: zoom1x(zoomx,zoomy);
  2: zoom2x(zoomx,zoomy);
  3: zoom3x(zoomx,zoomy);
  end;
 mouseshow;
end;

procedure displayatmoinfo;
var
   x, y, i : Integer;
begin
 y:=0;
 x:=explorecur;
 repeat
  while (x<53) and (scaninfo^[x].state<>0) do inc(x);
  if x<53 then
   begin
    printxy(8,155+y*6,scaninfo^[x].name);
    inc(y);
   end;
  inc(x);
 until (y=7) or (x>52);
 if y<7 then
  for i:=(y+1)*6+149 to 197 do
   scr_fillchar(screen[i,5],128,0);
end;

procedure displayhydroinfo;
var
   x, y, i : Integer;
begin
 y:=0;
 x:=explorecur;
 repeat
  while (x<53) and (scaninfo^[x].state<>1) do inc(x);
  if x<53 then
   begin
    printxy(8,155+y*6,scaninfo^[x].name);
    inc(y);
   end;
  inc(x);
 until (y=7) or (x>52);
 if y<7 then
  for i:=(y+1)*6+149 to 197 do
   scr_fillchar(screen[i,5],128,0);
end;

procedure displaylithoinfo;
var
   x, y, i : Integer;
begin
 y:=0;
 x:=explorecur;
 repeat
  while (x<53) and (scaninfo^[x].state<>2) do inc(x);
  if x<53 then
   begin
    printxy(8,155+y*6,scaninfo^[x].name);
    inc(y);
   end;
  inc(x);
 until (y=7) or (x>52);
 if y<7 then
  for i:=(y+1)*6+149 to 197 do
   scr_fillchar(screen[i,5],128,0);
end;

procedure displaybioinfo;
var str1 : string[12];
   j	 : Integer;
begin
 computebiostuff;
 printxy(9,155,'% Bio:');
 str((biostuff/29161*100):5:2,str1);
 printxy(44,155,str1+'%');
 if (tempplan^[curplan].state=6) and (tempplan^[curplan].mode=2) then
  begin
   printxy(9,163,'Sapient Life');
   printxy(14,169,'Void');
   printxy(14,175,'Dwellers');
   printxy(9,183,'Pop.: Unknown');
   printxy(9,189,'Tech Level: 6.0');
  end
 else
 case techlvl of
    -2: printxy(9,163,'No Life');
    -1: begin
         printxy(9,163,'Dominant Life Form');
         randseed:=tempplan^[curplan].seed;
         j:=random(word(tempplan^[curplan].state+tempplan^[curplan].mode+tempplan^[curplan].seed)) mod 3;
         case j of
          0: begin
              if random(2)=0 then printxy(14,169,'Short Chain')
               else printxy(14,169,'Long Chain');
              printxy(14,175,'Proteins');
             end;
          1: begin
              if random(2)=0 then printxy(14,169,'Simple')
               else printxy(14,169,'Complex');
              printxy(14,175,'Protoplasms');
             end;
          2: begin
              printxy(14,169,'Singlecelled');
              case random(3) of
               0: printxy(14,175,'Chaosms');
               1: printxy(14,175,'Communes');
               2: printxy(14,175,'Hierarchies');
              end;
             end;
         end;
        end;
  0..5: begin
         printxy(9,163,'Sapient Life');
         if techlvl>0 then
          begin
           pop:=2000;
           for j:=0 to techlvl do pop:=pop*10;
          end
         else pop:=10;
         randseed:=tempplan^[curplan].seed;
         pop:=round(pop/10*tl2)+pop+random(pop div 1000);
         randseed:=tempplan^[curplan].seed;
         str1:=alientypes[random(11)];
         printxy(14,175,str1);
         case random(5) of
          0: printxy(14,169,'Carnivorous');
          1: printxy(14,169,'Herbivorous');
          2: printxy(14,169,'Omnivorous');
          3: printxy(14,169,'Cannibalistic');
          4: printxy(14,169,'Photosynthetic');
         end;
         printxy(9,183,'Pop.:');
         str(pop,str1);
         printxy(39,183,str1+'000');
         printxy(9,189,'Tech Level:');
         str1[0]:=chr(3);
         str1[1]:=chr(techlvl+48);
         str1[2]:='.';
         str1[3]:=chr(tl2+48);
         printxy(69,189,str1);
        end;
 end;
end;

procedure readyatmoinfo;
var
   i : Integer;
begin
 if (donescan) and (not showscan) then summaryinfo;
 explorelevel:=3;
 explorecur:=1;
 while (explorecur<53) and (scaninfo^[explorecur].state<>0) do inc(explorecur);
 if explorecur=53 then explorecur:=0;
 mousehide;
 for i:=147 to 196 do
  scr_fillchar(screen[i,5],128,0);
 printxy(6,148,'Atmosphere Data');
 displayatmoinfo;
 mouseshow;
end;

procedure readyhydroinfo;
var
   i : Integer;
begin
 if (donescan) and (not showscan) then summaryinfo;
 explorelevel:=2;
 explorecur:=1;
 while (explorecur<53) and (scaninfo^[explorecur].state<>1) do inc(explorecur);
 if explorecur=53 then explorecur:=0;
 mousehide;
 for i:=147 to 196 do
  scr_fillchar(screen[i,5],128,0);
 printxy(6,148,'Hydrosphere Data');
 displayhydroinfo;
 mouseshow;
end;

procedure readylithoinfo;
var
   i : Integer;
begin
 if (donescan) and (not showscan) then summaryinfo;
 explorelevel:=1;
 explorecur:=1;
 while (explorecur<53) and (scaninfo^[explorecur].state<>2) do inc(explorecur);
 if explorecur=53 then explorecur:=0;
 mousehide;
 for i:=147 to 196 do
  scr_fillchar(screen[i,5],128,0);
 printxy(6,148,'Lithosphere Data');
 displaylithoinfo;
 mouseshow;
end;

procedure readybioinfo;
var
   i : Integer;
begin
 if (donescan) and (not showscan) then summaryinfo;
 explorelevel:=4;
 mousehide;
 for i:=147 to 196 do
  scr_fillchar(screen[i,5],128,0);
 printxy(6,148,'Biosphere Data');
 displaybioinfo;
 mouseshow;
end;

procedure readyanoinfo;
var
   i, j, a, y : Integer;
begin
   explorelevel:=5;
   createano;
   mousehide;
   for i:=147 to 196 do
      scr_fillchar(screen[i,5],128,0);
   printxy(6,148,'Anomaly Data');
   y:=0;
   for j:=1 to 7 do if tempplan^[curplan].cache[j]>0 then
   begin
      a:=tempplan^[curplan].cache[j];
      if a>ID_ARTIFACT_OFFSET then
      begin
	 getartifactname(a);
	 i:=maxcargo;
      end
      else
      begin
	 i:=1;
	 while (i <= maxcargo) and (cargo[i].index<>a) do inc(i);
	 if i > maxcargo then
	    i := maxcargo;
      end;
      inc(y);
      printxy(11,148+y*6,cargo[i].name);
   end;
   if showscan then
   begin
      landsprinkle(19);
      showscan:=false;
   end;
   mouseshow;
end;

procedure newzoom(x, y : Integer);
begin
 if showscan then exit;
 if (x>28) and (y>13) and (x<268) and (y<132) then
  begin
   undo;
   zoomx:=x-28;
   zoomy:=y-13;
   case zoommode of
    1: begin
        zoomx:=zoomx-29;
        zoomy:=zoomy-29;
	  zoomoffset:=29;
       end;
    2: begin
        zoomx:=zoomx-14;
        zoomy:=zoomy-14;
	  zoomoffset:=14;
       end;
    3: begin
        zoomx:=zoomx-9;
        zoomy:=zoomy-9;
	  zoomoffset:=9;
       end;
   end;
  end
 else exit;
 case zoommode of
  1: begin
      if zoomx>178 then zoomx:=178
       else if zoomx<=0 then zoomx:=1;
      if zoomy>58 then zoomy:=58
       else if zoomy<=0 then zoomy:=1;
     end;
  2: begin
      if zoomx>207 then zoomx:=208
       else if zoomx<=0 then zoomx:=1;
      if zoomy>88 then zoomy:=88
       else if zoomy<=0 then zoomy:=1;
     end;
  3: begin
      if zoomx>217 then zoomx:=217
       else if zoomx<=0 then zoomx:=1;
      if zoomy>98 then zoomy:=98
       else if zoomy<=0 then zoomy:=1;
     end;
 end;
 redraw;
end;

procedure decexplorecursor;
begin
 mousehide;
 case explorelevel of
  4:;
  3: begin
      dec(explorecur);
      while (explorecur>0) and (scaninfo^[explorecur].state<>0) do dec(explorecur);
      if explorecur<1 then
       begin
        explorecur:=52;
        while (explorecur>0) and (scaninfo^[explorecur].state<>0) do dec(explorecur);
       end;
      displayatmoinfo;
     end;
  2: begin
      dec(explorecur);
      while (explorecur>0) and (scaninfo^[explorecur].state<>1) do dec(explorecur);
      if explorecur<1 then
       begin
        explorecur:=52;
        while (explorecur>0) and (scaninfo^[explorecur].state<>1) do dec(explorecur);
       end;
      displayhydroinfo;
     end;
  1: begin
      dec(explorecur);
      while (explorecur>0) and (scaninfo^[explorecur].state<>2) do dec(explorecur);
      if explorecur<1 then
       begin
        explorecur:=52;
        while (explorecur>0) and (scaninfo^[explorecur].state<>2) do dec(explorecur);
       end;
      displaylithoinfo;
     end;
 end;
 mouseshow;
end;

procedure incexplorecursor;
begin
 mousehide;
 case explorelevel of
  4:;
  3: begin
      inc(explorecur);
      while (explorecur<53) and (scaninfo^[explorecur].state<>0) do inc(explorecur);
      if explorecur=53 then
       begin
        explorecur:=1;
        while (explorecur<53) and (scaninfo^[explorecur].state<>0) do inc(explorecur);
        if explorecur=53 then explorecur:=0;
       end;
      displayatmoinfo;
     end;
  2: begin
      inc(explorecur);
      while (explorecur<53) and (scaninfo^[explorecur].state<>1) do inc(explorecur);
      if explorecur=53 then
       begin
        explorecur:=1;
        while (explorecur<53) and (scaninfo^[explorecur].state<>1) do inc(explorecur);
        if explorecur=53 then explorecur:=0;
       end;
      displayhydroinfo;
     end;
  1: begin
      inc(explorecur);
      while (explorecur<53) and (scaninfo^[explorecur].state<>2) do inc(explorecur);
      if explorecur=53 then
       begin
        explorecur:=1;
        while (explorecur<53) and (scaninfo^[explorecur].state<>2) do inc(explorecur);
        if explorecur=53 then explorecur:=0;
       end;
      displaylithoinfo;
     end;
 end;
 mouseshow;
end;

procedure retrieve;
var
   a, j : Integer;
begin
 index:=0;
 for j:=1 to 7 do if tempplan^[curplan].cache[j]>0 then
  case zoommode of
   2: if (abs(itemloc[j,1]-zoomy-15)<3) and (abs(itemloc[j,2]-zoomx-14)<4) then
       begin
        index:=j;
        j:=7;
       end;
   3: if (abs(itemloc[j,1]-zoomy-11)<4) and (abs(itemloc[j,2]-zoomx-10)<4) then
       begin
        index:=j;
        j:=7;
       end;
  end;
 mousehide;
 if (index>0) and (addcargo2(tempplan^[curplan].cache[index],false)) then
  begin
   a:=landcolors^[itemloc[index,1]+11,itemloc[index,2]+27];
   landcolors^[itemloc[index,1]+12,itemloc[index,2]+27]:=a;
   screen[itemloc[index,1]+12,itemloc[index,2]+27]:=a;
   tempplan^[curplan].cache[index]:=0;
  end;
 mouseshow;
 readyanoinfo;
 redraw;
 showzoom;
end;

procedure findmouse;
var
   y, i, j : Integer;
begin
 if not mouse.getstatus then exit;
  case mouse.x of
   1..21: case mouse.y of
           21..28: if (datagathered[1,2]<1000) then
                    begin
		       mousehide;
		       SetScan(1);
		       displayinfogathered;
		       mouseshow;
		    end
		    else if (datagathered[1,2]>=1000) and (explorelevel<>1) then readylithoinfo;
           30..37: if (datagathered[2,2]<1000) then
                    begin
		       mousehide;
		       SetScan(2);
		       displayinfogathered;
		       mouseshow;
		    end
		    else if (datagathered[2,2]>=1000) and (explorelevel<>2) then readyhydroinfo;
           39..46: if (datagathered[3,2]<1000) then
                    begin
		       mousehide;
		       SetScan(3);
		       displayinfogathered;
		       mouseshow;
                    end
                   else if (datagathered[3,2]>=1000) and (explorelevel<>3) then readyatmoinfo;
           48..55: if (datagathered[4,2]<1000) then
                    begin
		       mousehide;
		       SetScan(4);
		       displayinfogathered;
		       mouseshow;
                    end
                   else if (datagathered[4,2]>=1000) and (explorelevel<>4) then readybioinfo;
           57..64: if (datagathered[5,2]<1000) then
                    begin
		       mousehide;
		       SetScan(5);
		       displayinfogathered;
		       mouseshow;
                    end
                   else if (datagathered[5,2]>=1000) and (explorelevel<>5) then readyanoinfo;
           66..85: done:=true;
         end;
  133..145: case mouse.y of
             144..163: decexplorecursor;
             164..179: displayinfogathered;
             180..198: incexplorecursor;
             else newzoom(mouse.x, mouse.y);
            end;
  195..203: case mouse.y of
             177..185: if not showscan then
                        begin
                         undo;
                         case zoommode of
                          1: begin
                              zoommode:=2;
                              zoomx:=zoomx+15;
                              zoomy:=zoomy+15;
                             end;
                          2: if colorchange then
                              begin
                               zoommode:=3;
                               zoomx:=zoomx+5;
                               zoomy:=zoomy+5;
                              end;
                         end;
                         redraw;
                        end;
             187..195: if not showscan then
                        begin
                         undo;
                         case zoommode of
                          2: begin
                              zoomx:=zoomx-15;
                              zoomy:=zoomy-15;
                              if zoomx>178 then zoomx:=178
                               else if zoomx<1 then zoomx:=1;
                              if zoomy>58 then zoomy:=58
                               else if zoomy<1 then zoomy:=1;
                              zoommode:=1;
                             end;
                          3: begin
                              zoomx:=zoomx-5;
                              zoomy:=zoomy-5;
                              if zoomx>208 then zoomx:=208
                               else if zoomx<1 then zoomx:=1;
                              if zoomy>88 then zoomy:=88
                               else if zoomy<1 then zoomy:=1;
                              zoommode:=2;
                             end;
                         end;
                         redraw;
                        end;
             else newzoom(mouse.x, mouse.y);
            end;
  206..265: case mouse.y of
             139..198: if not showscan then
                        begin
                         undo;
                         j:=round((mouse.x-235)/3);
                         i:=round((mouse.y-168)/3);
                         zoomx:=zoomx+j;
                         zoomy:=zoomy+i;
                         if zoomx<2 then zoomx:=2;
                         if zoomy<2 then zoomy:=2;
                         case zoommode of
                          1: if zoomx>178 then zoomx:=178
                              else if zoomy>58 then zoomy:=58;
                          2: if zoomx>207 then zoomx:=208
                              else if zoomy>88 then zoomy:=88;
                          3: if zoomx>218 then zoomx:=218
                              else if zoomy>98 then zoomy:=98;
                         end;
                         redraw;
                       end;
            else newzoom(mouse.x, mouse.y);
            end;
  270..318: if mouse.y>172 then retrieve;
  else newzoom(mouse.x, mouse.y);
  end; { case }
   if (explorelevel = 5) and doneano then
      if (mouse.x >= 5) and (mouse.x <= 132) then
	 if (mouse.y >= 148) and (mouse.y <= 196) then
	 begin
	    y := (mouse.y - 148) div 6;
	    i := 0;
	    for j := 1 to 7 do
	    begin
	       if tempplan^[curplan].cache[j] > 0 then
	       begin
		  inc(i);
		  if i = y then
		  begin
		     if zoommode = 1 then
		     begin
			zoommode:=2;
		     end;
		     newzoom(itemloc[j,2] + 27, itemloc[j,1] + 12);
		     break;
		  end;
	       end;
	    end;
	 end;
end;

procedure processkey;
var ans	: char;
   j	: Integer;
begin
 ans:=readkey;
 case upcase(ans) of
  #0: begin
       ans:=readkey;
       case ans of
        #75: if not showscan then begin
	   undo;
	   newzoom(zoomx - 2 + 28 + zoomoffset, zoomy + 13 + zoomoffset);
	end;
        #77: if not showscan then begin
	   undo;
	   newzoom(zoomx + 2 + 28 + zoomoffset, zoomy + 13 + zoomoffset);
	end;
        #72: if not showscan then begin
	   undo;
	   newzoom(zoomx + 28 + zoomoffset, zoomy - 2 + 13 + zoomoffset);
	end;
        #80: if not showscan then begin
	   undo;
	   newzoom(zoomx + 28 + zoomoffset, zoomy + 2 + 13 + zoomoffset);
	end;
        #73: decexplorecursor;
        #81: incexplorecursor;
       end;
      end;
  '+': if not showscan then
        begin
         undo;
         case zoommode of
          1: begin
              zoommode:=2;
              zoomx:=zoomx+15;
              zoomy:=zoomy+15;
             end;
          2: if colorchange then
              begin
               zoommode:=3;
               zoomx:=zoomx+5;
               zoomy:=zoomy+5;
              end;
         end;
         redraw;
        end;
  '-': if not showscan then
        begin
         undo;
         case zoommode of
          2: begin
              zoommode:=1;
              zoomx:=zoomx-15;
              zoomy:=zoomy-15;
              if zoomx>178 then zoomx:=178
               else if zoomx<1 then zoomx:=1;
              if zoomy>58 then zoomy:=58
               else if zoomy<1 then zoomy:=1;
             end;
          3: begin
              zoommode:=2;
              zoomx:=zoomx-5;
              zoomy:=zoomy-5;
              if zoomx>208 then zoomx:=208
               else if zoomx<1 then zoomx:=1;
              if zoomy>88 then zoomy:=88
               else if zoomy<1 then zoomy:=1;
             end;
         end;
         redraw;
        end;
  '1'..'5': begin
             j:=ord(ans)-48;
             if (datagathered[j,2]<1000) then
	     begin
		mousehide;
		SetScan(j);
		displayinfogathered;
		mouseshow;
	     end
	     else if (datagathered[j,2]>=1000) and (explorelevel<>j) then
		case j of
                1: readylithoinfo;
                2: readyhydroinfo;
                3: readyatmoinfo;
                4: readybioinfo;
                5: readyanoinfo;
                end;
            end;
  'Q',#27,'X': done:=true;
  #13: retrieve;
  '`': bossmode;
  #10: printbigbox(GetHeapStats1,GetHeapStats2);
 end;
end;

procedure mainloop;
var green: byte;
begin
 mouseshow;
 displayinfogathered;
 repeat
  fadestep(FADESTEP_STEP);
  findmouse;
  if fastkeypressed then processkey;
  controlprobes;
  if batindex<8 then inc(batindex) else
   begin
    batindex:=0;
    addtime2;
   end;
  green := batindex shl 3;
  if green > 63 then green := 63;
  setrgb256(235,0,green,0);
  showzoom;
  controlprobes;
  delay(tslice*FADE_TSLICE_MUL_EXPLORE);
 until done;
 anychange:=true;
end;

procedure readydata;
var
   i, j, a  : Integer;
begin
 {dispose(backgr);}
 explorelevel:=-1;
 {backgr := nil;}
 setcolor(47);
 done:=false;
 donescan:=false;
 showscan:=false;
 doneano:=false;
 tcolor:=207;
 bkcolor:=0;
 batindex:=0;
 if tempplan^[curplan].state <> 7 then
    numprobes:=incargo(ID_PROBOT)
 else
    numprobes:=incargo(ID_STARDIVER);

 if numprobes>4 then numprobes:=4;
 compressfile(loc_tmp()+'current',@screen);
 {fading;}
 fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);
 loadscreen(loc_data()+'landform',@screen);
 new(summarypic);
// new(landcolors);
 new(scaninfo);
 new(tempzoom);
 new(zoomscr);
 new(msgs);
 new(probeicons);
 playmod(true,loc_sound()+'PROBE.MOD');
 setcolors;
 generatescanlist;
 for j:=1 to 7 do
  begin
   itemloc[j,1]:=random(60)+30;
   itemloc[j,2]:=random(180)+30;
  end;
 for j:=1 to 4 do probes[j].status:=0;
 for j:=1 to 5 do
  begin
   if tempplan^[curplan].notes and (1 shl (j+1))>0 then datagathered[j,2]:=1000
    else datagathered[j,2]:=0;
   datagathered[j,1]:=datagathered[j,2];
  end;
 if datagathered[5,2]>=1000 then doneano:=true;
 for j:=1 to 4 do
  for i:=1 to 26 do
   scrfrom_move(screen[i+j*40-26,281],probeicons^[j,i],8*4);
 for j:=1 to numprobes do
  for i:=1 to 26 do
   scrto_move(probeicons^[2,i],screen[i+j*40-26,281],8*4);
 if j<4 then
  for a:=j+1 to 4 do
   for i:=1 to 26 do
    scr_fillchar(screen[i+a*40-26,281],31,0);
 for j:=1 to 7 do
  for i:=20 to 27 do
   scrfrom_move(screen[i,j*20+10],msgs^[j,i-20],4*4);
 que:=0;
 SetScan(0);
 for i:=13 to 133 do
  scr_fillchar(screen[i,28],240,0);
 if (not colorchange) and (zoommode=3) then
  begin
   zoommode:=2;
   zoomx:=zoomx-5;
   zoomy:=zoomy-5;
   if zoomx>208 then zoomx:=208
    else if zoomx<1 then zoomx:=1;
   if zoomy>88 then zoomy:=88
    else if zoomy<1 then zoomy:=1;
  end;
 fadein;
 displaylandform;
 redraw;
 showzoom;
end;

procedure removedata;
begin
 mousehide;
 dispose(probeicons);
 dispose(msgs);
 dispose(zoomscr);
 dispose(tempzoom);
 dispose(scaninfo);
// dispose(landcolors);
 dispose(summarypic);
 {if backgr <> nil then dispose(backgr);
 new(backgr);}
 {fading;}
 fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);
 loadscreen(loc_data()+'cloud',backgr);
 loadscreen(loc_tmp()+'current',@screen);
 if ((tempplan^[curplan].state=6) and (tempplan^[curplan].mode=2)) then makeasteroidfield
  else if (tempplan^[curplan].state=0) and (tempplan^[curplan].mode=1) then makecloud;
 anychange:=true;
 showtime;
 displaytextbox(false);
 if (viewmode=11) and (viewlevel=2) then displaybotinfo(6);
 {fadein;}
end;

procedure exploreplanet;
begin
 computebiostuff;
 if ((techlvl=4) and (tl2>=2)) or (techlvl>4) then
  begin
   println;
   tcolor:=95;
   print('SCIENCE: Probes cannot penetrate planetary shield.');
   exit;
  end;
 mousehide;
 readydata;
 mainloop;
 {stopmod;}
 removedata;
 mouseshow;
 if tempplan^[curplan].notes and 125>0 then
  begin
   if not chevent(11) then event(11)
    else if tempplan^[curplan].system=164 then event(19)
    else if (tempplan^[curplan].system=45) and (tempplan^[curplan].orbit <> 0) then event(28)
    else if tempplan^[curplan].system=31 then event(15)
    else if tempplan^[curplan].system=28 then event(42)
    else if tempplan^[curplan].system=123 then event(49)
    else if (tempplan^[curplan].system=45) and (tempplan^[curplan].orbit = 0) and chevent(28) then event(1103);
  end;
end;

begin
 zoommode:=1;
 zoomx:=1;
 zoomy:=1;
 new(landcolors);

end.
