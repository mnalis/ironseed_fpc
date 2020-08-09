unit comm2;

{***************************
   Communication unit #2 for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

{$O+}
{$I-}
interface

uses data;

procedure computerlogs(n: integer);
procedure trade;

implementation

uses  gmouse, weird, journey, utils, modplay, comm, heapchk, utils_;

const
 maxlogentries= 256;
type
 mousearray	 = array[0..6] of mouseicontype;
   titlebody	 = record
		      id   : Integer;
		      text : string[49];
		   end;	   
 titletype	 = array[0..maxlogentries-1] of titlebody;
 computerlogtype = array[0..24] of string[49];
 alienstuffarray = array[1..20] of integer;
var
 i,j,index,logindex: integer;
 tmpm: ^mousearray;
 l: ^computerlogtype;
 titles: ^titletype;
 qmode,done: boolean;
 cr: ^createarray;
 alienstuff,tradestuff: ^alienstuffarray;
 trademode,cargoindex,tradeindex,stuffindex,alienworth,tradeworth: integer;
 str1: string[3];

procedure printxy2(x1,y1: integer; s: string);
var i,j,a,x,y,t	: integer;
   bright	: boolean;
begin
   t:=tcolor;
   bright := false;
   x1:=x1+4;
   for j:=1 to length(s) do
   begin
      if bright then
	 tcolor:=31
      else
	 tcolor:=t;
      y:=y1;
      if s[j] = #200 then
      begin
	 bright := not bright;
      end else begin
	 for i:=0 to 5 do
	 begin
	    x:=x1;  { this stupid offset is pissing me off!!!!}
	    inc(y);
	    for a:=7 downto 4 do
	    begin
	       inc(x);
	       if font[ship.options[7],ord(s[j]),i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor
	       else if bkcolor<255 then screen[y,x]:=bkcolor;
	    end;
	    dec(tcolor,2);
	    x:=x1;
	    inc(y);
	    inc(i);
	    for a:=3 downto 0 do
	    begin
	       inc(x);
	       if font[ship.options[7],ord(s[j]),i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor
	       else if bkcolor<255 then screen[y,x]:=bkcolor;
	    end;
	    dec(tcolor,2);
	 end;
	 x1:=x1+5;
	 if bkcolor<255 then for i:=1 to 6 do screen[y1+i,x1]:=bkcolor;
      end;
   end;
   tcolor:=t;
end;

function getlogindex(log : Integer):Integer;
var
   i : Integer;
   s : string[10];
begin
   for i := 0 to maxlogentries - 1 do
   begin
      if titles^[i].id = log then
      begin
	 getlogindex := i;
	 exit;
      end;
   end;
   str(log, s);
   errorhandler('data/titles.dta : ' + s,5);
   getlogindex := -1;
end;

procedure loadlog(n: integer);
var
   f : file of computerlogtype;
   s : string[10];
begin
   str(n, s);
   assign(f,'data/log.dta');
   reset(f);
   if ioresult<>0 then errorhandler('data/log.dta',1);
   seek(f,n);
   read(f,l^);
   if ioresult<>0 then errorhandler('data/log.dta : ' + s,5);
   close(f);
end;

procedure displaylist;
var i: integer;
begin
   mousehide;
   tcolor:=79;
   bkcolor:=0;
   y:=13;
   i:=logindex-1;
   if i>-1 then
      repeat
	 dec(y);
	 printxy2(6,14+y*6,titles^[getlogindex(logs[i])].text);
	 dec(i);
      until (i<0) or (y=0);
   if y>0 then
      for i:=14 to y*6+14 do
	 fillchar(screen[i,8],246,0);
   y:=12;
   i:=logindex;
   repeat
      inc(y);
      if i=logindex then bkcolor:=9 else bkcolor:=0;
      printxy2(6,14+y*6,titles^[getlogindex(logs[i])].text);
      inc(i);
   until (i=maxlogentries) or (y=25) or (logs[i]<0);
   if y<25 then
      for i:=y*6+21 to 170 do
	 fillchar(screen[i,8],246,0);
   mouseshow;
end;

procedure getlog;
begin
   mousehide;
   tcolor:=79;
   bkcolor:=0;
   loadlog(getlogindex(logs[logindex]));
   printxy2(6,15,titles^[getlogindex(logs[logindex])].text);
 for j:=0 to 24 do
    printxy2(6,22+j*6,l^[j]);
 mouseshow;
end;

procedure subcursor;
begin
 if logindex>0 then
  begin
   dec(logindex);
   if not qmode then displaylist else getlog;
  end;
end;

procedure addcursor;
begin
 if (logs[logindex+1]>0) and (logindex<maxlogentries-1) then
  begin
   inc(logindex);
   if not qmode then displaylist else getlog;
  end;
end;

procedure findmouse;
begin
 if not mouse.getstatus then exit;
 case mouse.x of
   11..211: if (not qmode) and (mouse.y>13) and (mouse.y<170) then
             begin
              i:=((mouse.y-14) div 6)-13;
              while i>0 do
               begin
                if (logs[logindex+1]>-1) and (logindex < maxlogentries - 1) then inc(logindex);
                dec(i);
               end;
              while i<0 do
               begin
                if (logindex>-1) and (logindex>0) then dec(logindex);
                inc(i);
               end;
              mousehide;
              for i:=42 to 50 do
               begin
                screen[i,311]:=63;
                screen[i,312]:=63;
               end;
              if not qmode then
               for i:=14 to 173 do
                fillchar(screen[i,8],246,0);
               mouseshow;
              qmode:=true;
              if not qmode then displaylist else getlog;
             end;
  309..316: if (mouse.y<33) and (mouse.y>13) then done:=true;
  262..270: case mouse.y of
             91..101: subcursor;
             105..115: addcursor;
            end;
  306..308: case mouse.y of
             14..32: done:=true;
             39..54: begin
                      if qmode then
                       begin
                        qmode:=false;
                        mousehide;
                        for i:=42 to 50 do
                         begin
                          screen[i,311]:=79;
                          screen[i,312]:=79;
                         end;
                        for i:=14 to 173 do
                         fillchar(screen[i,8],246,0);
                        mouseshow;
                        displaylist;
                       end
                      else
                       begin
                        qmode:=true;
                        mousehide;
                        for i:=42 to 50 do
                         begin
                          screen[i,311]:=63;
                          screen[i,312]:=63;
                         end;
                        for i:=14 to 174 do
                         fillchar(screen[i,8],246,0);
                        mouseshow;
                        getlog;
                       end;
                     end;
           end;
  299..305: if (mouse.y<55) and (mouse.y>38) then
             begin
              if qmode then
               begin
                qmode:=false;
                mousehide;
                for i:=42 to 50 do
                 begin
                  screen[i,311]:=79;
                  screen[i,312]:=79;
                 end;
                for i:=14 to 173 do
                 fillchar(screen[i,8],246,0);
                mouseshow;
                displaylist;
               end
              else
               begin
                qmode:=true;
                mousehide;
                for i:=42 to 50 do
                 begin
                  screen[i,311]:=63;
                  screen[i,312]:=63;
                 end;
                for i:=14 to 173 do
                 fillchar(screen[i,8],246,0);
                mouseshow;
                getlog;
               end;
             end;
 end;
 idletime:=0;
end;

procedure processkey;
var ans: char;
begin
 ans:=readkey;
 case ans of
  #0: begin
       ans:=readkey;
       case ans of
        #72: subcursor;
        #80: addcursor;
       end;
      end;
  '?','/': begin
        if qmode then
         begin
          qmode:=false;
          mousehide;
          for i:=42 to 50 do
           begin
            screen[i,311]:=79;
            screen[i,312]:=79;
           end;
          for i:=14 to 173 do
           fillchar(screen[i,8],246,0);
          mouseshow;
          displaylist;
         end
        else
         begin
          qmode:=true;
          mousehide;
          for i:=42 to 50 do
           begin
            screen[i,311]:=63;
            screen[i,312]:=63;
           end;
          for i:=14 to 173 do
           fillchar(screen[i,8],246,0);
          mouseshow;
          getlog;
         end;
       end;
  #27: done:=true;
  '`': bossmode;
  #10: printbigbox(GetHeapStats1,GetHeapStats2);
 end;
 idletime:=0;
end;

procedure mainloop;
begin
   repeat
      fadestep(8);
  findmouse;
  if fastkeypressed then processkey;
  inc(idletime);
  if idletime=maxidle then screensaver;
  inc(index);
  if index=7 then index:=0;
  mousehide;
  mousesetcursor(tmpm^[index]);
  mouseshow;
  delay(tslice*6);
 until done;
end;

procedure readydata(intialdraw: boolean);
var
   f  : file of paltype;
   f2 : file of titlebody;
   i  : Integer;
begin
 assign(f,tempdir+'/current2.pal');
 rewrite(f);
 if ioresult<>0 then errorhandler(tempdir+'/current2.pal',1);
 write(f,colors);
 if ioresult<>0 then errorhandler(tempdir+'/current2.pal',5);
 close(f);
 mousehide;
 compressfile(tempdir+'/current2',@screen);
 {fading;}
 fadestopmod(-8, 20);
 playmod(true,'sound/CREWEVAL.MOD');
 loadscreen('data/log',@screen);
 index:=0;
 qmode:=false;
 new(tmpm);
 new(l);
 new(titles);
 assign(f2,'data/titles.dta');
 reset(f2);
 if ioresult<>0 then errorhandler('data/titles.dta',1);
   i := 0;
   while (ioresult = 0) and (not eof(f2)) and (i < maxlogentries) do
   begin
      read(f2,titles^[i]);
      inc(i);
   end;
 if (ioresult<>0) or (i=0) then errorhandler('data/titles.dta',5);
 close(f2);
 for j:=0 to 6 do
  for i:=0 to 15 do
   mymove(screen[i+120,j*17+9],tmpm^[j,i],4);
 mousesetcursor(tmpm^[0]);
 for i:=15 to 170 do
  fillchar(screen[i,8],246,0);
 displaylist;
 mouseshow;
 {fadein;}
 if intialdraw then
  begin
   qmode:=true;
   for i:=42 to 50 do
    begin
     screen[i,311]:=63;
     screen[i,312]:=63;
    end;
   for i:=15 to 170 do
    fillchar(screen[i,8],246,0);
   getlog;
  end;
 done:=false;
end;

procedure removedata(n: integer);
begin
 dispose(tmpm);
 dispose(l);
 dispose(titles);
 mousehide;
 {fading;}
 fadestopmod(-8, 20);
 mouse.setmousecursor(random(3));
 loadscreen(tempdir+'/current2',@screen);
 bkcolor:=3;
 if n=0 then
  begin
   displaytextbox(false);
   textindex:=25;
  end;
 {fadein;}
 mouseshow;
 anychange:=true;
end;

procedure computerlogs(n: integer);
var initialdraw: boolean;
begin
   initialdraw:=false;
   if n>0 then
   begin
      i:=0;
      while (logs[i]<>n) and (i < maxlogentries) do inc(i);
      if i >= maxlogentries then
      begin
	 logindex := 0;
      end else begin
	 logindex:=i;
	 initialdraw:=true;
      end;
   end
   else logindex:=0;
   readydata(initialdraw);
   mainloop;
   {stopmod;}
   removedata(n);
end;

{**************************************************************************}

function getworth(item: integer): integer;forward;
procedure displayleftlist;
var str_price: string;
begin
 mousehide;
 if trademode=0 then
  begin
   if tradeindex=0 then
    begin
     for i:=141 to 183 do
      fillchar(screen[i,4],121,0);
     mouseshow;
     exit;
    end;
   x:=tradeindex;
   y:=2;
   repeat
    if alienstuff^[x]>0 then
     begin
      if x=tradeindex then bkcolor:=6 else bkcolor:=0;
      inc(y);
      i:=1;
      while cargo[i].index<>alienstuff^[x] do inc(i);
      printxy(0,140+y*6,'    '+cargo[i].name);
     end;
    inc(x);
   until (y=6) or (x>20);
   if y<6 then
    for i:=147+y*6 to 183 do
     fillchar(screen[i,4],121,0);
   x:=tradeindex-1;
   y:=3;
   bkcolor:=0;
   repeat
    if (alienstuff^[x]>0) and (x>0) then
     begin
      dec(y);
      i:=1;
      while cargo[i].index<>alienstuff^[x] do inc(i);
      printxy(0,140+y*6,'    '+cargo[i].name);
     end;
    dec(x);
   until (y=0) or (x<0);
   if y>0 then
    for i:=141 to 140+y*6 do
     fillchar(screen[i,4],121,0);
  end
 else
  begin
   if cargoindex=0 then
    begin
     for i:=141 to 183 do
      fillchar(screen[i,4],121,0);
     mouseshow;
     exit;
    end;
   x:=cargoindex;
   y:=2;
   repeat
    if (ship.cargo[x]>0) and (ship.cargo[x]<6000) then
     begin
      if x=cargoindex then bkcolor:=6 else bkcolor:=0;
      inc(y);
      i:=1;
      while cargo[i].index<>ship.cargo[x] do inc(i);
      str(ship.numcargo[x]:3,str1);
      str(getworth(cargo[i].index),str_price);
      printxy(0,140+y*6,str1+' '+cargo[i].name);
      printxy(115-5*length(str_price),140+y*6,' '+str_price);
     end;
    inc(x);
   until (y=6) or (x>250);
   if y<6 then
    for i:=147+y*6 to 183 do
     fillchar(screen[i,4],121,0);
   x:=cargoindex-1;
   y:=3;
   bkcolor:=0;
   repeat
    if (ship.cargo[x]>0) and (ship.cargo[x]<6000) and (x>0) then
     begin
      dec(y);
      if ship.cargo[x]>5999 then
       begin
        getartifactname(ship.cargo[x]);
        i:=maxcargo;
       end
      else
       begin
        i:=1;
        while cargo[i].index<>ship.cargo[x] do inc(i);
       end;
      str(ship.numcargo[x]:3,str1);
      printxy(0,140+y*6,str1+' '+cargo[i].name);
      str(getworth(cargo[i].index),str_price);
      printxy(115-5*length(str_price),140+y*6,' '+str_price);
     end;
    dec(x);
   until (y=0) or (x<0);
   if y>0 then
    for i:=141 to 140+y*6 do
     fillchar(screen[i,4],121,0);
  end;
 mouseshow;
end;

procedure displayrightlist;
begin
 mousehide;
 if stuffindex=0 then
  begin
   for i:=141 to 183 do
    fillchar(screen[i,194],101,0);
   mouseshow;
   exit;
  end;
 x:=stuffindex;
 y:=2;
 repeat
  if tradestuff^[x]>0 then
   begin
    if x=stuffindex then bkcolor:=6 else bkcolor:=0;
    inc(y);
    i:=1;
    while cargo[i].index<>tradestuff^[x] do inc(i);
    printxy(190,140+y*6,cargo[i].name);
   end;
  inc(x);
 until (y=6) or (x>20);
 if y<6 then
  for i:=147+y*6 to 183 do
   fillchar(screen[i,194],101,0);
 x:=stuffindex-1;
 y:=3;
 bkcolor:=0;
 repeat
  if (tradestuff^[x]>0) and (x>0) then
   begin
    dec(y);
    i:=1;
    while cargo[i].index<>tradestuff^[x] do inc(i);
    printxy(190,140+y*6,cargo[i].name);
   end;
  dec(x);
 until (y=0) or (x<0);
 if y>0 then
  for i:=141 to 140+y*6 do
   fillchar(screen[i,194],101,0);
 mouseshow;
end;

procedure subcursor2;
begin
 if trademode=0 then
  begin
   dec(tradeindex);
   while (tradeindex>0) and (alienstuff^[tradeindex]=0) do dec(tradeindex);
   if tradeindex<1 then
    begin
     tradeindex:=1;
     while (tradeindex<21) and (alienstuff^[tradeindex]=0) do inc(tradeindex);
     if tradeindex=21 then tradeindex:=0;
    end;
  end
 else
  begin
   dec(cargoindex);
   while (cargoindex>0) and ((ship.cargo[cargoindex]=0) or (ship.cargo[cargoindex]>5999)) do dec(cargoindex);
   if cargoindex<1 then
    begin
     cargoindex:=1;
     while (cargoindex<251) and ((ship.cargo[cargoindex]=0) or (ship.cargo[cargoindex]>5999)) do inc(cargoindex);
     if cargoindex>250 then cargoindex:=0;
    end;
  end;
 displayleftlist;
end;

procedure subcursor3;
begin
 if trademode=0 then exit;
 dec(stuffindex);
 while (stuffindex>0) and (tradestuff^[stuffindex]=0) do dec(stuffindex);
 if stuffindex<1 then
  begin
   stuffindex:=1;
   while (stuffindex<21) and (tradestuff^[stuffindex]=0) do inc(stuffindex);
   if stuffindex=21 then stuffindex:=0;
  end;
 displayrightlist;
end;

procedure addcursor2;
begin
 if trademode=0 then
  begin
   inc(tradeindex);
   while (tradeindex<21) and (alienstuff^[tradeindex]=0) do inc(tradeindex);
   if tradeindex>20 then
    begin
     tradeindex:=20;
     while (tradeindex>0) and (alienstuff^[tradeindex]=0) do dec(tradeindex);
    end;
  end
 else
  begin
   inc(cargoindex);
   while (cargoindex<251) and ((ship.cargo[cargoindex]=0) or (ship.cargo[cargoindex]>5999)) do inc(cargoindex);
   if cargoindex>250 then
    begin
     cargoindex:=250;
     while (cargoindex>0) and ((ship.cargo[cargoindex]=0) or (ship.cargo[cargoindex]>5999)) do dec(cargoindex);
    end;
  end;
 displayleftlist;
end;

procedure addcursor3;
begin
 if trademode=0 then exit;
 inc(stuffindex);
 while (stuffindex<21) and (tradestuff^[stuffindex]=0) do inc(stuffindex);
 if stuffindex>20 then
  begin
   stuffindex:=20;
   while (stuffindex>0) and (tradestuff^[stuffindex]=0) do dec(stuffindex);
  end;
 displayrightlist;
end;

function getworth(item: integer): integer;
var i,j,worth: integer;
begin
 i:=0;
 worth:=0;
   if item=3000 then worth:=27;
   if item=4000 then worth:=9;
    if item=4020 then  worth:=1;
 case item of
  5000..5999: worth:=3;
  1000..1499: begin i:=1; worth:=4; end;
  1500..1599: begin i:=1; worth:=6; end;
  2000..2999: begin i:=1; worth:=4; end;
  3001..3999: begin i:=1; worth:=3; end;
  4001..4019,4021..4999: begin i:=1; worth:=2; end;
 end;
 if i=1 then
  begin
   while cr^[i].index<>item do inc(i);
   for j:=1 to 3 do
    if cr^[i].parts[j]>4999 then inc(worth)
    else worth:=worth+getworth(cr^[i].parts[j]);
  end;
 getworth:=worth;
end;

procedure barterfor;
var r: real;
    item_name,item_price:string;
begin
 if (trademode=1) or (tradeindex=0) then exit;
 trademode:=1;
 if cargoindex=0 then addcursor2;
 i:=1;
 while cargo[i].index<>alienstuff^[tradeindex] do inc(i);
 mousehide;
 item_name:=cargo[i].name;
 displayleftlist;
 mouseshow;
 fillchar(tradestuff^,sizeof(alienstuffarray),0);
 alienworth:=getworth(alienstuff^[tradeindex]);
 if alien.anger=0 then
  begin
   if alien.congeniality>20 then i:=3
    else i:=1;
  end
 else
  begin
   r:=alien.congeniality/alien.anger;
   if r<0.3 then i:=5
   else if r<0.7 then i:=4
   else if round(r)=1 then i:=2
   else i:=3;
  end;
 alienworth:=round(alienworth*0.33*i);
 mousehide;
 str(alienworth,item_price);
 printxy(93,127,item_name+'('+item_price+')');
 mouseshow;
 tradeworth:=0;
end;

procedure rejectoffer;
var j: integer;
begin
 if trademode=0 then exit;
 trademode:=0;
 mousehide;
 for i:=128 to 133 do
  fillchar(screen[i,97],121,0);
 for i:=141 to 183 do
  fillchar(screen[i,194],101,0);
 for j:=1 to 20 do
  if tradestuff^[j]>0 then addcargo2(tradestuff^[j], true);
 for i:=158 to 164 do
  fillchar(screen[i,131],57,0);
 displayleftlist;
 mouseshow;
end;

procedure acceptoffer;
begin
 if (trademode=0) or (tradeworth<alienworth) or (tradeindex=0) then exit;
 case alienstuff^[tradeindex] of
  2015: begin
         addcargo(3012, true);
         addcargo(3007, true);
         addcargo(3018, true);
        end;
  2016: begin
         addcargo(1000, true);
         addcargo(1000, true);
         addcargo(3008, true);
        end;
  2017: begin
         addcargo(3018, true);
         addcargo(3019, true);
         addcargo(3012, true);
        end;
  2018: begin
         addcargo(1506, true);
         addcargo(1506, true);
         addcargo(1034, true);
        end;
  2019: begin
         addcargo(3015, true);
         addcargo(3003, true);
         addcargo(3009, true);
        end;
  else addcargo(alienstuff^[tradeindex], true);
 end;
 alienstuff^[tradeindex]:=0;
 trademode:=0;
 subcursor2;
 mousehide;
 for i:=128 to 133 do
  fillchar(screen[i,97],121,0);
 for i:=141 to 183 do
  fillchar(screen[i,194],101,0);
 for i:=158 to 164 do
  fillchar(screen[i,131],57,0);
 displayleftlist;
 mouseshow;
end;

procedure showworth;
var c,num: integer;
begin
 num:=57;
 if tradeworth<alienworth then
  begin
   c:=37;
   num:=round(tradeworth/alienworth*57);
  end
 else if tradeworth>=2*alienworth then c:=47
 else c:=33;
 mousehide;
 for i:=158 to 164 do
  begin
   fillchar(screen[i,131],num,c);
   if num<57 then fillchar(screen[i,131+num],57-num,0);
  end;
 mouseshow;
end;

procedure addstuff;
var i: integer;
begin
 if (trademode=0) or (cargoindex=0) then exit;
 i:=1;
 while (i<21) and (tradestuff^[i]>0) do inc(i);
 if i=21 then exit;
 tradestuff^[i]:=ship.cargo[cargoindex];
 tradeworth:=tradeworth+getworth(ship.cargo[cargoindex]);
 dec(ship.numcargo[cargoindex]);
 if ship.numcargo[cargoindex]=0 then
  begin
   ship.cargo[cargoindex]:=0;
   subcursor2;
  end;
 stuffindex:=i;
 displayrightlist;
 showworth;
end;

procedure removestuff;
begin
 if (trademode=0) or (stuffindex=0) then exit;
 addcargo(tradestuff^[stuffindex], true);
 tradeworth:=tradeworth-getworth(tradestuff^[stuffindex]);
 tradestuff^[stuffindex]:=0;
 subcursor3;
 if cargoindex=0 then addcursor2;
 displayleftlist;
 showworth;
end;

procedure findleftmouse;
var y,j: integer;
begin
 y:=-3+((mouse.y-141) div 6);
 repeat
  if y<0 then
   begin
    subcursor2;
    inc(y);
   end
  else if y>0 then
   begin
    addcursor2;
    dec(y);
   end;
 until y=0;
end;

procedure findrightmouse;
var y,j: integer;
begin
 y:=-3+((mouse.y-141) div 6);
 repeat
  if y<0 then
   begin
    subcursor3;
    inc(y);
   end
  else if y>0 then
   begin
    addcursor3;
    dec(y);
   end;
 until y=0;
end;

procedure findmouse2;
begin
 if not mouse.getstatus then exit;
 case mouse.x of
    21..90: case mouse.y of
             126..134: if trademode=0 then barterfor;
             138..186: findleftmouse;
 end;//         end;
// case mouse.x of
    4..20,91..124: if (mouse.y>137) and (mouse.y<187) then findleftmouse;
 //end;
 //case mouse.x of
  130..139: case mouse.y of
             172..179: subcursor2;
             180..186: addcursor2;
            end;
  149..171: case mouse.y of
             149..155: addstuff;
             167..173: removestuff;
            end;
  179..188: case mouse.y of
             172..179: subcursor3;
             180..186: addcursor3;
            end;
  229..246: case mouse.y of
             126..134: acceptoffer;
             138..186: findrightmouse;
            end;
  247..261: case mouse.y of
             104..111: getinfo;
             126..134: acceptoffer;
             138..186: findrightmouse;
            end;
  262..265: case mouse.y of
             105..110: getinfo;
             138..186: findrightmouse;
            end;
  266..297: case mouse.y of
             126..134: rejectoffer;
             138..186: findrightmouse;
            end;
//  end;
 // case mouse.x of
  194..228: if (mouse.y>137) and (mouse.y<187) then findrightmouse;
  309..319: if (mouse.y>153) and (mouse.y<171) then done:=true;
 end;
 idletime:=0;
end;

procedure processkey2;
var ans: char;
begin
 ans:=readkey_utf8;
 case upcase(ans) of
   #0: begin
        ans:=readkey;
        case ans of
         #72: subcursor2;
         #80: addcursor2;
         #73: subcursor3;
         #81: addcursor3;
        end;
       end;
  'A': acceptoffer;
  'B': barterfor;
  'R': rejectoffer;
  '+',#13: addstuff;
  '-': removestuff;
  #27: done:=true;
  '`': bossmode;
  #10: printbigbox(GetHeapStats1,GetHeapStats2);
 end;
 idletime:=0;
end;

procedure mainloop2;
begin
 repeat
  findmouse2;
  if fastkeypressed then processkey2;
  if batindex<8 then inc(batindex) else
   begin
    batindex:=0;
    addtime2;
   end;
  inc(idletime);
  if idletime=maxidle then screensaver;
  animatealien;
  delay(tslice*6);
 until done;
 rejectoffer;
end;

procedure readydata2;
var f: file of paltype;
    crfile: file of createarray;
begin
 wait(1);
 assign(f,tempdir+'/current2.pal');
 rewrite(f);
 if ioresult<>0 then errorhandler(tempdir+'/current2.pal',1);
 write(f,colors);
 if ioresult<>0 then errorhandler(tempdir+'/current2.pal',5);
 close(f);
 compressfile(tempdir+'/current2',@screen);
 done:=false;
 compressfile(tempdir+'/current3',backgr);
 loadscreen('data/trade',backgr);
 mymove(backgr^[111],screen[111],7200);
 loadscreen(tempdir+'/current3',backgr);
 mouseshow;
 trademode:=0;
 tradeindex:=1;
 cargoindex:=0;
 new(alienstuff);
 new(tradestuff);
 new(cr);
 assign(crfile,'data/creation.dta');
 reset(crfile);
 if ioresult<>0 then errorhandler('creation.dta',1);
 read(crfile,cr^);
 if ioresult<>0 then errorhandler('creation.dta',5);
 close(crfile);
 fillchar(alienstuff^,sizeof(alienstuffarray),0);
 if alien.id=1007 then
  for j:=1 to 8+random(13) do
   alienstuff^[j]:=4020
 else
 for j:=1 to 8+random(13) do
  if (random(5)=0) and (hi(alien.techmin)>=4) then
    alienstuff^[j]:=3001+random(19)
   else if (alien.conindex=9) and (random(4)=0) then
    alienstuff^[j]:=2015+random(5)
   else alienstuff^[j]:=4001+random(19);
 displayleftlist;
end;

procedure removedata2;
begin
 dispose(alienstuff);
 dispose(tradestuff);
 dispose(cr);
 mousehide;
 compressfile(tempdir+'/current3',backgr);
 loadscreen(tempdir+'/current2',backgr);
 mymove(backgr^[111],screen[111],7200);
 loadscreen(tempdir+'/current3',backgr);
 bkcolor:=3;
end;

procedure trade;
begin
 readydata2;
 mainloop2;
 removedata2;
end;

begin
end.
