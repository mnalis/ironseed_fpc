program crewgen;

{***************************
   Crew Generation unit for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

uses data, gmouse, utils_, saveload, display, utils, modplay;
{$PACKRECORDS 1}

type
 displaytype= array[0..193,0..93] of byte;
 shipdistype= array[0..57,0..74] of byte;
 shipdatatype= record
   guns,cargo: byte;
   maxfuel,mass,accel,hullmax:integer;
  end;
 oldsystype= record
   x,y,z,lastdate,visits,numplanets: integer;
  end;
 crewdatatype2= array[1..30] of crewdatatype;
 anitype= array[0..34,0..48] of byte;
 aniarraytype= array[0..30] of anitype;
 planarray= array[1..1000] of planettype;
 portraittype= array[0..69,0..69] of byte;
 oldsysarray= array[1..250] of oldsystype;
{$PACKRECORDS DEFAULT}
var
 i,i2,j,a,cursor,code,crewnum,inputlevel,anihandle: integer;
 quit,crewmode,toggle: boolean;
 shipdata: shipdatatype;
 planets: ^planarray;
 oldsys: ^oldsysarray;
 radii: array[1..7] of byte;
 crewdata: ^crewdatatype2;
 ani: ^aniarraytype;
 s: string[30];
 birdpic: ^portraittype;

procedure easteregg1;
var c		  : integer;
   done		  : boolean;
   ans		  : char;
   str1,str2,str3 : string[3];
   i, j, k, x, y  : Integer;
begin
   mousehide;
   compressfile(tempdir+'/current',@screen);
   bkcolor:=5;
   fading;
   loadpal('data/main.pal');
   fillchar(screen,64000,0);
   for i:=0 to 199 do
      for j:=0 to 319 do
	 screen[i,j]:=random(16)+200+(i mod 2)*16;
   graybutton(5,23,315,153+12);
   graybutton(80,146+12,240,160+12);
   tcolor:=188;
   printxy(53,130+12,'Welcome to the Channel 7 Easter Egg Hunt!');
   tcolor:=92;
   printxy(91,150+12,'DON''T TOUCH THIS BUTTON!!!');
   tcolor:=22;
   {
   for i:=1 to 15 do
   begin
      printxy(7,20+i*6,crewdata^[i].name);
      str(crewdata^[i].phy,str1);
      str(crewdata^[i].men,str2);
      str(crewdata^[i].emo,str3);
      printxy(102,20+i*6,str1+'/'+str2+'/'+str3);
   end;
   for i:=16 to 30 do
   begin
      printxy(160,i*6-70,crewdata^[i].name);
      str(crewdata^[i].phy,str1);
      str(crewdata^[i].men,str2);
      str(crewdata^[i].emo,str3);
      printxy(255,i*6-70,str1+'/'+str2+'/'+str3);
   end;
   }
   i := 1;
   for j := 1 to 6 do
   begin
      if j = 4 then
	 i := 1;
      tcolor:=92;
      if j < 4 then
	 printxy(7, 20 + i * 6, crewtitles[j])
      else
	 printxy(160, 20 + i * 6, crewtitles[j]);
      tcolor:=22;
      inc(i);
      for k := 1 to 30 do
      begin
	 if crewdata^[k].jobtype and (1 shl (7 - j)) > 0 then
	 begin
	    str(crewdata^[k].phy,str1);
	    str(crewdata^[k].men,str2);
	    str(crewdata^[k].emo,str3);
	    if j < 4 then
	    begin
	       x := 7;
	       y := 20 + i * 6;
	    end else begin
	       x := 160;
	       y := 20 + i * 6;
	    end;
	    printxy(x + 6, y, crewdata^[k].name);
	    printxy(x + 101, y, str1+'/'+str2+'/'+str3);
	    inc(i);
	 end;
      end;
   end;
   mouseshow;
   c:=0;
   ans:=' ';
   done:=false;
   set256colors(colors);
   repeat
      for i:=200 to 215 do
	 colors[i]:=colors[random(22)];
      for i:=216 to 231 do
	 colors[i]:=colors[0];
      set256colors(colors);
      delay(tslice div 2);
      done:=mouse.getstatus;
      if (c=0) and (mouse.y>145+12) and (mouse.y<161+12) and (mouse.x>79) and (mouse.x<241) then
      begin
	 c:=1;
	 mousehide;
	 plainfadearea(80,146+12,240,160+12,3);
	 mouseshow;
      end
      else if (c=1) and ((mouse.y<146+12) or (mouse.y>160+12) or (mouse.x<80) or (mouse.x>240)) then
      begin
	 c:=0;
	 mousehide;
	 plainfadearea(80,146+12,240,160+12,-3);
	 mouseshow;
      end;
      if fastkeypressed then ans:=readkey;
      for i:=216 to 231 do
	 colors[i]:=colors[random(16)];
      for i:=200 to 215 do
	 colors[i]:=colors[0];
      set256colors(colors);
      delay(tslice div 2+5);
   until (done) and (c=1);
   mousehide;
   loadscreen(tempdir+'/current',@screen);
   set256colors(colors);
   bkcolor:=3;
   tcolor:=191;
   mouseshow;
end;

procedure showportrait(n: integer);
var s: string[2];
    portrait: ^portraittype;
begin
 new(portrait);
 str(n:2,s);
 if n<10 then s[1]:='0';
 loadscreen('data/image'+s+'',portrait);
 for i:=0 to 34 do
  begin
   move(portrait^[i*2],screen[i*2+7,13],70);
   delay(tslice div 7);
  end;
 for i:=0 to 34 do
  begin
   move(portrait^[i*2+1],screen[i*2+8,13],70);
   delay(tslice div 7);
  end;
 dispose(portrait);
end;

procedure drawstats(num: integer);
var b,c,d,y,ylast: integer;
    part: real;
begin {120,37,294,112}
 a:=ship.crew[num].phy;
 b:=ship.crew[num].men;
 c:=ship.crew[num].emo;
 ylast:=50;
 part:=36/100;
 for i:=14 to 88 do
  fillchar(screen[i,121],175,0);
 moveto(121,50);
 for j:=121 to 295 do
 begin
  inc(j,2);
   if j>295 then exit;
  setcolor((j-16) mod 32+128);
   d:=random(6);
   case d of
    0:i:=round(a*part);
    1:i:=round(b*part);
    2:i:=round(c*part);
    3:i:=-round(a*part);
    4:i:=-round(b*part);
    5:i:=-round(c*part);
   end;
   lineto(j,i+51);
   ylast:=i+51;
 end;
end;

procedure lowerball;
begin
 mousehide;
 for j:=0 to 30 do
  begin
   for i:=0 to 34 do
    mymove(ani^[j,i],screen[i+81,22],12);
   delay(tslice);
  end;
 mouseshow;
end;

procedure raiseball;
begin
 mousehide;
 for j:=30 downto 0 do
  begin
   for i:=0 to 34 do
    mymove(ani^[j,i],screen[i+81,22],12);
   delay(tslice);
  end;
 mouseshow;
end;

function getxp(l: integer): longint;
var x: longint;
begin
 case l of
  0: x:=0;
  1: x:=1000;
  2: x:=3000;
  3: x:=4000;
  4: x:=7000;
  5: x:=11000;
  6: x:=18000;
 end;
 getxp:=x+random(500);
end;

procedure sublevel; forward;

procedure savedata;
var
   planfile	  : file of planarray;
   nums		  : string[1];
   confile	  : file of alientype;
   eventfile	  : file of eventarray;
   logsfile	  : file of logarray;
   logpendingfile : file of logpendingarray;
   i, j		  : Integer;
begin
   with ship do
   begin
      fuelmax:=shipdata.maxfuel;
      fuel:=100+random(20);
      gunmax:=shipdata.guns;
      accelmax:=shipdata.accel;
      battery:=0;
      hullmax:=shipdata.hullmax;
      cargomax:=shipdata.cargo*10;
      hulldamage:=round(ship.hullmax*0.9);
   end;
   for j:=1 to 6 do
      with ship.crew[j] do
      begin
	 xp:=getxp(ship.crew[j].level);
	 perf:=round(men*0.60+phy*0.40-emo*0.20);
	 skill:=round(phy*0.60+emo*0.40-men*0.20);
	 san:=round(emo*0.60+men*0.40-phy*0.20);
	 ship.encodes[j]:=ship.crew[j];
      end;
   assign(confile,tempdir+'/contacts.dta');
   rewrite(confile);
   if ioresult<>0 then errorhandler(tempdir+'/contacts.dta',1);
   close(confile);
   
   if not savegamedata(160,191) then
   begin
       sublevel;
      exit;
   end;
   
   quit:=true;
   code:=curfilenum+48;
   str(curfilenum,nums);
   assign(planfile,'save'+nums+'/PLANETS.DTA');
   rewrite(planfile);
   if ioresult<>0 then errorhandler('PLANETS.DTA',1);
   write(planfile,planets^);
   if ioresult<>0 then errorhandler('PLANETS.DTA',5);
   close(planfile);
   
   assign(confile,'save'+nums+'/CONTACTS.DTA');
   rewrite(confile);
   if ioresult<>0 then errorhandler('save'+nums+'/CONTACTS.DTA',1);
   close(confile);

   for i := 0 to 1023 do
      events[i] := 0;
   for i := 0 to 127 do
      logpending[i].log := -1;
   for i := 0 to 255 do
      logs[i] := -1;

   assign(eventfile,'save'+nums+'/EVENTS.DTA');
   rewrite(eventfile);
   if ioresult<>0 then errorhandler('EVENTS.DTA',1);
   write(eventfile,events);
   if ioresult<>0 then errorhandler('EVENTS.DTA',5);
   close(eventfile);

   assign(logsfile,'save'+nums+'/LOGS.DTA');
   rewrite(logsfile);
   if ioresult<>0 then errorhandler('LOGS.DTA',1);
   write(logsfile,logs);
   if ioresult<>0 then errorhandler('LOGS.DTA',5);
   close(logsfile);

   assign(logpendingfile,'save'+nums+'/PENDING.DTA');
   rewrite(logpendingfile);
   if ioresult<>0 then errorhandler('PENDING.DTA',1);
   write(logpendingfile,logpending);
   if ioresult<>0 then errorhandler('PENDING.DTA',5);
   close(logpendingfile);
   
end;

procedure drawcrew;
begin
 mousehide;
 ship.crew[inputlevel].index:=crewnum;
 ship.crew[inputlevel].name:=crewdata^[crewnum].name;
 ship.crew[inputlevel].phy:=crewdata^[crewnum].phy;
 ship.crew[inputlevel].men:=crewdata^[crewnum].men;
 ship.crew[inputlevel].emo:=crewdata^[crewnum].emo;
 ship.crew[inputlevel].level:=crewdata^[crewnum].level;
 tcolor:=191;
 bkcolor:=0;
 printxy(0,120,crewdata^[crewnum].name);
 for a:=0 to 9 do
  printxy(0,130+a*6,crewdata^[crewnum].desc[a]);
 drawstats(inputlevel);
 showportrait(crewnum);
 mouseshow;
end;

procedure calculateship;
begin
 with shipdata do
  begin
   cargo:=0;
   accel:=0;
   case ship.shiptype[1] of
    1:begin
         guns:=2;
         mass:=334;
         maxfuel:=200;
         hullmax:=200;
        end;
    2:begin
         guns:=1;
         mass:=334;
         maxfuel:=250;
         cargo:=cargo+50;
         hullmax:=150;
        end;
    3:begin
         guns:=3;
         mass:=501;
         maxfuel:=200;
         hullmax:=100;
        end;
   end;
   case ship.shiptype[2] of
    1:begin
         guns:=guns+3;
         mass:=mass+501;
         maxfuel:=maxfuel+350;
         cargo:=cargo+50;
         hullmax:=hullmax+700;
        end;
    2:begin
         guns:=guns+4;
         mass:=mass+668;
         maxfuel:=maxfuel+300;
         cargo:=cargo+100;
         hullmax:=hullmax+600;
        end;
    3:begin
         guns:=guns+5;
         mass:=mass+835;
         maxfuel:=maxfuel+300;
         cargo:=cargo+50;
         hullmax:=hullmax+600;
        end;
   end;
   case ship.shiptype[3] of
    1:begin
         guns:=guns+0;
         hullmax:=hullmax+100;
         cargo:=cargo+100;
        end;
    2:begin
         guns:=guns+1;
         mass:=mass+167;
         hullmax:=hullmax+100;
         cargo:=cargo+50;
        end;
    3:begin
         guns:=guns+2;
         mass:=mass+330;
         cargo:=cargo+50;
        end;
   end;
   accel:=270000 div mass;
  end;
end;

procedure drawship;
var strln: string[4];
begin
 mousehide;
 calculateship;
 with ship do
  begin
   for i:=0 to 5 do
    fillchar(screen[i+122,30],231,0);
   s:=shipnames[shiptype[1]-1]+' '+shipnames[shiptype[2]+2]+' '+shipnames[shiptype[3]+5];
   printxy(131-round(length(s)*2.5),122,s);
   str(shipdata.guns:2,strln);
   printxy(20,132,'Gun Emplacements');
   printxy(230,132,strln);
   str(shipdata.maxfuel:4,strln);
   printxy(30,143,'Maximum Fuel');
   printxy(205,143,strln+' Kg');
   str(shipdata.cargo:4,strln);
   printxy(25,154,'Cargo Capacity');
   printxy(190,154,strln+' Units');
   str(shipdata.mass:4,strln);
   printxy(35,165,'Ship Mass');
   printxy(205,165,strln+' Mt');
   str(shipdata.accel:4,strln);
   printxy(20,176,'Max Acceleration');
   printxy(180,176,strln+' M/S Sqr');
   printxy(15,187,'Maximum Hull Points');
   str(shipdata.hullmax:4,strln);
   printxy(200,187,strln+' Pts');
  end;
 mouseshow;
end;

procedure addship;
begin
 with ship do
  begin
   i:=(shiptype[1]-1)*9+(shiptype[2]-1)*3+shiptype[3]-1;
   inc(i);
   if i>26 then i:=0;
   shiptype[1]:=1+(i div 9);
   i:=i-(shiptype[1]-1)*9;
   shiptype[2]:=1+(i div 3);
   i:=i-(shiptype[2]-1)*3;
   shiptype[3]:=1+i;
  end;
 drawship;
 mousehide;
 displayship2(121,13);
 mouseshow;
end;

procedure subship;
begin
 with ship do
  begin
   i:=(shiptype[1]-1)*9+(shiptype[2]-1)*3+shiptype[3]-1;
   dec(i);
   if i<0 then i:=26;
   shiptype[1]:=1+(i div 9);
   i:=i-(shiptype[1]-1)*9;
   shiptype[2]:=1+(i div 3);
   i:=i-(shiptype[2]-1)*3;
   shiptype[3]:=1+i;
  end;
 drawship;
 mousehide;
 displayship2(121,13);
 mouseshow;
end;

procedure addcursor;
var found,quit: boolean;
begin
 case inputlevel of
  0: addship;
  1..7: begin
         found:=false;
         quit:=false;
         repeat
          inc(crewnum);
          while (crewnum<31) and (crewdata^[crewnum].jobtype and (1 shl (7-inputlevel))=0) do inc(crewnum);
          found:=true;
          for j:=1 to inputlevel do if ship.crew[j].index=crewnum then found:=false;
          if crewnum=31 then
           begin
            crewnum:=1;
            while (crewnum<31) and (crewdata^[crewnum].jobtype and (1 shl (7-inputlevel))=0) do inc(crewnum);
            found:=true;
            for j:=1 to inputlevel do if ship.crew[j].index=crewnum then found:=false;
           end;
         until found;
         drawcrew;
        end;
 end;
end;

procedure subcursor;
var found: boolean;
begin
 case inputlevel of
  0: subship;
  1..7: begin
         found:=false;
         repeat
          dec(crewnum);
          while (crewnum>0) and (crewdata^[crewnum].jobtype and (1 shl (7-inputlevel))=0) do dec(crewnum);
          found:=true;
          for j:=1 to inputlevel do if ship.crew[j].index=crewnum then found:=false;
          if crewnum<1 then
           begin
            crewnum:=30;
            while (crewnum>0) and (crewdata^[crewnum].jobtype and (1 shl (7-inputlevel))=0) do dec(crewnum);
            found:=true;
            for j:=1 to inputlevel do if ship.crew[j].index=crewnum then found:=false;
           end;
         until found;
         drawcrew;
        end;
 end;
end;

procedure showtitle;
var s: string[11];
begin
 mousehide;
 if inputlevel=0 then
  printxy(141,100,'Ship Selection')
 else printxy(141,100,'Crew Selection');
 case inputlevel of
  0: s:='           ';
  1: s:='Psychometry';
  2: s:='Engineering';
  3: s:='  Science  ';
  4: s:=' Security  ';
  5: s:='Navigation ';
  6: s:='  Medical  ';
 end;
 printxy(149,106,s);
 mouseshow;
end;

procedure addlevel;
var s: string[11];
begin
 lowerball;
 mousehide;
 for i:=120 to 196 do
  fillchar(screen[i,4],260,0);
 mouseshow;
 inc(inputlevel);
 if inputlevel=7 then
  begin
   savedata;
   exit;
  end;
 crewnum:=0;
 addcursor;
 showtitle;
 raiseball;
end;

procedure sublevel;
begin
 if inputlevel=0 then
  begin
   quit:=true;
   exit;
  end
 else if inputlevel=1 then
  begin
   lowerball;
   mousehide;
   for i:=0 to 34 do
    begin
     move(birdpic^[i*2],screen[i*2+7,13],70);
     delay(tslice div 7);
    end;
   for i:=0 to 34 do
    begin
     move(birdpic^[i*2+1],screen[i*2+8,13],70);
     delay(tslice div 7);
    end;
   for i:=120 to 196 do
    fillchar(screen[i,4],260,0);
   mouseshow;
   inputlevel:=0;
   raiseball;
  end
 else if inputlevel>1 then
  begin
   lowerball;
   mousehide;
   for i:=120 to 196 do
    fillchar(screen[i,4],260,0);
   mouseshow;
   dec(inputlevel);
   raiseball;
  end;
 crewnum:=31;
 subcursor;
 showtitle;
end;

procedure toggleswitch;
begin
 if toggle then
  begin
   toggle:=false;
   plainfadearea(247,107,253,112,144);
  end
 else
  begin
   toggle:=true;
   plainfadearea(247,107,253,112,-144);
  end;
end;

procedure findmouse;
begin
 if not mouse.getstatus then exit;
 case mouse.y of
  132..138: if (mouse.x>279) and (mouse.x<311) then addlevel;
  140..146: if (mouse.x>279) and (mouse.x<311) then sublevel;
  150..160: if (mouse.x>281) and (mouse.x<296) then subcursor;
  162..172: if (mouse.x>281) and (mouse.x<296) then addcursor;
  107..112: if (mouse.x>246) and (mouse.x<254) then toggleswitch;
 end;
end;

procedure processkey;
var ans: char;
begin
 ans:=readkey;
 case ans of
   #0: begin
        ans:=readkey;
        case ans of
         #59,#16: quit:=true;
         #80: addcursor;
         #72: subcursor;
         #84: if toggle then easteregg1;  {shift-F1}
        end;
       end;
  #13: addlevel;
  #27: sublevel;
 end;
end;

procedure mainloop;
begin
 i2:=0;
 calculateship;
 repeat
  dec(i2);
  if i2<1 then i2:=31;
  i:=i2;
  for j:=0 to 31 do
   begin
    inc(i);
    if i>31 then i:=0;
    colors[j+128]:=colors[i*2+64];
   end;
  set256colors(colors);
  delay(tslice*3);
  findmouse;
  if fastkeypressed then processkey;
 until quit;
end;

procedure setstate(n,spot: integer);
begin
 if spot=1 then
  with planets^[n] do
   begin
    age:=random(7);
    case age of
     0..3: mode:=1;
     4..5: mode:=2;
     else mode:=3;
    end;
    state:=7;
    exit;
   end;
 with planets^[n] do
  begin
   state:=random(7);
   case state of
    0:with planets^[n] do
       begin
        age:=random(5);
        case age of
         0..1: mode:=1;
         2..3: mode:=2;
         else mode:=3;
        end;
       end;
    1:with planets^[n] do
       begin
        age:=random(11);
         case age of
          0..4: mode:=1;
          5..8: mode:=2;
         else mode:=3;
        end;
       end;
    2:with planets^[n] do
       begin
        age:=random(64000)*7812;
        if age>350000000 then mode:=3
        else if age>200000000 then mode:=2
        else mode:=1;
       end;
    3:with planets^[n] do
       begin
        age:=random(15001)*1000;
        if age>150005000 then mode:=3
        else if age>150000000 then mode:=2
        else mode:=1;
       end;
    4:with planets^[n] do
       begin
        age:=random(5000);
        if age>3000 then mode:=3
        else if age>2000 then mode:=2
        else mode:=1;
       end;
    5:with planets^[n] do
       begin
        age:=random(5000);
        if age>5500 then mode:=3
        else if age>1500 then mode:=2
        else mode:=1;
       end;
    6:with planets^[n] do
       begin
        age:=random(100)*1000;
        if age>100000 then
         begin
          mode:=2;
         end
        else if random(2)=0 then mode:=3;
        mode:=1;
       end;
   end;
  age:=random(2000);
 end;
end;

procedure initcrew;
var curplan: integer;
    systfile: file of oldsystype;
label planerror;
begin
   cursor:=0;
   quit:=false;
   crewmode:=true;
   crewnum:=0;
   curplan:=0;
   inputlevel:=0;
   tcolor:=191;
   bkcolor:=0;
   new(oldsys);
   for j:=1 to 6 do with ship.crew[j] do
   begin
      fillchar(name,20,ord(' '));
      phy:=50;
      men:=50;
      emo:=50;
      status:=0;
      xp:=0;
      level:=0;
      index:=0;
      san:=0;
      perf:=0;
      skill:=0;
   end;
   with ship do
   begin
      shiptype[1]:=1;
      shiptype[2]:=1;
      shiptype[3]:=1;
      for j:=1 to 10 do gunnodes[j]:=0;
      fillchar(cargo,500,0);
      fillchar(numcargo,500,0);
      fillchar(engrteam,sizeof(teamtype)*3,0);
      damages[1]:=25;
      damages[2]:=15;
      damages[3]:=2;
      damages[4]:=3;
      damages[5]:=16;
      damages[6]:=55;
      damages[7]:=22;
      with engrteam[1] do
      begin
	 timeleft:=ship.damages[7]*70+random(30);
	 job:=7;
	 jobtype:=0;
      end;
      fillchar(events,50,255);
      fillchar(events[50],15,0);
      research:=0;
      cargo[1]:=2001;
      numcargo[1]:=2;
      ship.cargo[2]:=2002;
      numcargo[2]:=1;
      cargo[3]:=2003;
      numcargo[3]:=1;
      cargo[4]:=1000;
      numcargo[4]:=1;
      options[1]:=1;
      options[2]:=20;
      options[3]:=1;
      options[4]:=1;
      options[5]:=2;
      options[6]:=1;
      options[7]:=0;
      options[8]:=1;
      options[9]:=64;
      options[10]:=0; {nothing yet!!}
      posx:=166;
      posy:=226;
      posz:=33;
      orbiting:=1;
      shieldlevel:=15;
      shield:=0;
      stardate[3]:=3784;
      stardate[1]:=2;
      stardate[2]:=3;
      stardate[4]:=8;
      stardate[5]:=75;
      for j:=1 to 3 do shieldopt[j]:=0;
      armed:=false;
      wandering.alienid:=32000;
   end;
   assign(systfile,'data/sysset.dta');
   reset(systfile);
   if ioresult<>0 then errorhandler('sysset.dta',1);
   for j:=1 to 250 do read(systfile,oldsys^[j]);
   if ioresult<>0 then errorhandler('sysset.dta',5);
   close(systfile);
   new(planets);
   repeat
      fillchar(planets^,sizeof(planarray),0);
      curplan:=0;
      for j:=1 to 250 do
	 with systems[j] do
	 begin
	    name:='UNKNOWN     ';
	    x:=oldsys^[j].x;
	    y:=oldsys^[j].y;
	    z:=oldsys^[j].z;
	    numplanets:=random(3)+3;
	    if j = 145 then {Oban}
	    begin
	       numplanets := 3;
	    end;
	    visits:=0;
	    datey:=0;
	    datem:=0;
	    notes:=0;
	    fillchar(radii[1],7,0);
	    for i:=1 to numplanets do
	    begin
	       inc(curplan);
	       if curplan>1000 then goto planerror;
	       with planets^[curplan] do
	       begin
		  if i=1 then orbit:=0 else
		  begin
		     repeat
			a:=random(7)+1;
		     until radii[a]=0;
		     radii[a]:=1;
		     orbit:=a;
		  end;
		  system:=j;
		  water:=random(50);
		  seed:=random(64000);
		  psize:=random(5);
		  bots:=0;
		  for a:=1 to 7 do cache[a]:=0;
		  datey:=0;
		  datem:=0;
		  visits:=0;
		  notes:=0;
		  if (j = 145) and (i > 1) then {Oban}
		  begin
		     if i = 2 then
		     begin
			state := 5;
			mode := 3;
			orbit := 4;
			age := 2000;
		     end else begin
			state := 2;
			mode := 3;
			orbit := 2;
			age := 2000;
		     end;
		  end else 
		     setstate(curplan,i);
		  if i=1 then systems[j].mode:=planets^[curplan].mode;
	       end;
	    end;
	 end;
planerror:
      until (curplan>400) and (curplan<1001);
   with systems[145] do
   begin
      name:='OBAN        ';
      datey:=3784;
      datem:=2;
      visits:=1;
   end;
   dispose(oldsys);
end;

procedure readydata;
var crewfile: file of crewdatatype2;
    anifile: file of aniarraytype;
    mcursor: ^mouseicontype;
begin
 new(ani);
 new(birdpic);
 toggle:=false;
 initcrew;
 fading;
 playmod(true,'sound/CHARGEN.MOD');
 loadscreen('data/char',@screen);
 for i:=0 to 69 do
  move(screen[i+7,13],birdpic^[i],70);
 assign(anifile,'data/charani.dta');
 reset(anifile);
 if ioresult<>0 then errorhandler('charani.dta',1);
 read(anifile,ani^);
 if ioresult<>0 then errorhandler('charani.dta',5);
 close(anifile);
 for i:=0 to 34 do
  mymove(ani^[30,i],screen[i+81,22],12);
 new(mcursor);
 for i:=131 to 146 do
  mymove(screen[i,11],mcursor^[i-131],4);
 for i:=131 to 146 do
  fillchar(screen[i,11],16,0);
 mousesetcursor(mcursor^);
 dispose(mcursor);
 showtitle;
 raiseball;
 drawship;
 displayship2(121,13);
 new(crewdata);
 assign(crewfile,'data/crew.dta');
 reset(crewfile);
 if ioresult<>0 then errorhandler('crew.dta',1);
 read(crewfile,crewdata^);
 if ioresult<>0 then errorhandler('crew.dta',5);
 close(crewfile);
 fadein;
 mouseshow;
end;

procedure checkparams;
var i,j: integer;
    diskfreespace: longint;
    curdir: string[60];
begin
 if (paramstr(1)<>'/makeseed') then
  begin
   closegraph();
   writeln('Do not run this program separately.  Please run IS.EXE.');
   halt(4);
  end;
 tempdir:='';
 if tempdir='' then tempdir:='TEMP';
 getdir(0,curdir);
 chdir(tempdir);
 if ioresult<>0 then tempdir:='TEMP';
 chdir(curdir);
 if ioresult<>0 then errorhandler('Changing directory error,'+curdir,5);
 //tempdir:=fexpand(tempdir);
 //diskfreespace:=diskfree(ord(tempdir[1])-64);
 if ioresult<>0 then errorhandler('Failure accessing drive '+tempdir[1],5);
 //if diskfreespace<128000 then tempdir:='TEMP';
 chdir(tempdir);
 if ioresult<>0 then
  begin
   mkdir(tempdir);
   if ioresult<>0 then errorhandler('Creating directory error,'+tempdir,5);
  end;
 chdir(curdir);
 if ioresult<>0 then errorhandler('Changing directory error,'+curdir,5);
 if tempdir[length(tempdir)]='\' then dec(tempdir[0]);
end;

procedure demostuff;
var
 mode: word;
 done: boolean;
 ans: char;

 procedure processkey;
 begin
  ans:=readkey;
  case ans of
    #0: begin
         ans:=readkey;
         case ans of
          #72: if mode=1 then
                begin
                 mode:=0;
                 mousehide;
                 loadscreen('data/demoscr3',@screen);
                 mouseshow;
                end;
          #80: if mode=0 then
                begin
                 mode:=1;
                 mousehide;
                 loadscreen('data/demoscr4',@screen);
                 mouseshow;
                end;
         end;
        end;
   #27: if mode=1 then done:=true;
  end;
 end;

 procedure findmouse;
 begin
  if not mouse.getstatus then exit;
  case mouse.x of
   261..282: case mouse.y of
              92..100: if mode=1 then
                        begin
                         mode:=0;
                         mousehide;
                         loadscreen('data/demoscr3',@screen);
                         mouseshow;
                        end
                       else
                        begin
                         mode:=1;
                         mousehide;
                         loadscreen('data/demoscr4',@screen);
                         mouseshow;
                        end;
             end;
   306..316: case mouse.y of
              14..33: if mode=1 then done:=true;
             end;
  end;
 end;

 procedure mainloop;
 begin
  repeat
   if fastkeypressed then processkey;
   findmouse;
  until done;
 end;


begin
 mode:=0;
 done:=false;
 fillchar(colors,768,0);
 set256colors(colors);
 playmod(true,'sound/CHARGEN.MOD');
 loadscreen('data/demoscr3',@screen);
 mouseshow;
 fadein;
 mainloop;
end;


begin
 init_everything;
 code:=3;
 tslice:=10;
 randomize;
 checkparams;
{$IFDEF DEMO}
 demostuff;
{$ELSE}
 readydata;
 mainloop;
{$ENDIF}
 stopmod;
 fading;
 mousehide;
 closegraph;
{$IFNDEF DEMO}
 dispose(ani);
 dispose(birdpic);
 halt(code);
{$ELSE}
 halt(3);
{$ENDIF}
end.
