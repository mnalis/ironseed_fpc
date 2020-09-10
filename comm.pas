unit comm;
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

{***************************
   Communication unit for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

{$O+}
{$I-}

interface

uses data, utils_;

procedure conversewithcrew;
procedure continuecontact(hail: boolean);
procedure getspecial(n,contactindex: integer);
procedure addtofile;
procedure createwandering(order: integer);
procedure getinfo;
procedure checkwandering;
procedure animatealien;
procedure gettechlevel(plan: integer);
function calc_anger (anger, congeniality: integer): integer;

implementation

uses gmouse, utils, utils2, weird, modplay, comm2, journey, saveload, heapchk;

const
 numback= 19;
type
 eventtype=
  record
   want,give: integer;
   msg: string[255];
  end;
 eventarray= array[0..9] of eventtype;
var
 i,j,techlvl,eattype,contactindex,cursorx,indexa,indexb,indexc,oldcontactindex: integer;
 brighter,infomode,shipflag,eventflag: boolean;
 str1, str2: ^string;
 question: string[20];
 c: ^conversearray;
 r: ^responsearray;
 tmpm: ^mouseicontype;
 aliens: pscreentype;
 p: ^paltype;

procedure createwandering(order: integer);
var x,y: integer;                     { order = 0 > attack  }
begin                                 {       = 1 > retreat }
 with ship.wandering do               {       = 2 > nothing }
  begin
   orders:=order;
   x:=hi(alien.techmin);
   y:=lo(alien.techmin);
   techlevel:=alien.techmin;
   i:=5+random(4);
   repeat
    inc(y);
    if y>9 then
     begin
      inc(x);
      y:=0;
      if x>6 then
       begin
        x:=6;
        y:=0;
       end;
     end;
    dec(i);
   until (i=0) or (techlevel=alien.techmax);
   techlevel:=x*256+y;
   congeniality:=abs(alien.congeniality+random(11)-5);
   anger:=abs(alien.anger+random(11)-5);
   alienid:=alien.id;
   case orders of
    WNDORDER_ATTACK: begin
        relx:=3000+random(10000);
        if random(2)=1 then relx:=-relx;
        rely:=3000+random(10000);
        if random(2)=1 then rely:=-rely;
        relz:=3000+random(10000);
        if random(2)=1 then relz:=-relz;
       end;
    WNDORDER_RETREAT: begin
        relx:=5000+random(12000);
        if random(2)=1 then relx:=-relx;
        rely:=5000+random(12000);
        if random(2)=1 then rely:=-rely;
        relz:=5000+random(12000);
        if random(2)=1 then relz:=-relz;
       end;
    WNDORDER_NONE: begin
        relx:=3000+random(2000);
        if random(2)=1 then relx:=-relx;
        rely:=3000+random(2000);
        if random(2)=1 then rely:=-rely;
        relz:=3000+random(2000);
        if random(2)=1 then relz:=-relz;
       end;
   end;
 end;
end;

procedure checkwandering;
var confile: file of alientype;
begin
 if ship.wandering.alienid<16000 then exit;
 assign(confile,tempdir+'/contacts.dta');
 reset(confile);
 if ioresult<>0 then errorhandler('contacts.dta',1);
 repeat
  read(confile,alien);
 until (alien.id=curplan) or (ioresult<>0);
 close(confile);
 if (alien.id=curplan) and (alien.anger>0) and (alien.congeniality/alien.anger<0.7) then createwandering(WNDORDER_ATTACK);
end;

procedure gettechlevel(plan: integer);
var i: integer;
begin
 if tempplan^[plan].orbit=0 then
  begin
   techlvl:=0;
   exit;
  end;
 techlvl:=-2;
 case tempplan^[plan].system of
  93,138,78,191,171,221:
    begin
     techlvl:=6*256;
     exit;
    end;
  45: if chevent(27) then
    begin
     techlvl:=0;
     exit;
    end
   else
    begin
     techlvl:=6*256;
     exit;
    end;
 end;
 case tempplan^[plan].state of
  2: case tempplan^[plan].mode of
      2: techlvl:=-1;
      3: techlvl:=tempplan^[plan].age div 15000000;
     end;
  3: begin
      techlvl:=(tempplan^[plan].mode-1)*256;
      case tempplan^[plan].mode of
       1: techlvl:=techlvl+(tempplan^[plan].age div 1500000);
       2: techlvl:=techlvl+(tempplan^[plan].age div 1000);
       3: techlvl:=techlvl+(tempplan^[plan].age div 800);
      end;
     end;
  4: begin
      techlvl:=(tempplan^[plan].mode+2)*256;
      case tempplan^[plan].mode of
       1: techlvl:=techlvl+(tempplan^[plan].age div 400);
       2: techlvl:=techlvl+(tempplan^[plan].age div 200);
      end;
     end;
  5: case tempplan^[plan].mode of
      1: begin
          i:=tempplan^[plan].age div 100000000;
          if i>9 then i:=9;
          techlvl:=techlvl+i;
         end;
      2: techlvl:=-1;
     end;
  6: if tempplan^[curplan].mode=2 then techlvl:=6*256;   {void dwellers}
 end;
 i:=random(9);                              { junk first random number }
 eattype:=random(3);
 randomize;
end;

procedure getname(n: integer);
type nametype= string[15];
var str1: nametype;
    f: file of nametype;
begin
 n:=n-tempplan^[n].system;
 assign(f,'data/planname.txt');
 reset(f);
 if ioresult<>0 then errorhandler('data/planname.txt',1);
 seek(f,n);
 if ioresult<>0 then errorhandler('data/planname.txt',6);
 read(f,str1);
 if ioresult<>0 then errorhandler('data/planname.txt',6);
 alien.name:=str1;
 close(f);
end;

procedure addtofile;
var confile: file of alientype;
    err,already: boolean;
    temp: alientype;
    index: integer;
begin
 assign(confile,tempdir+'/contacts.dta');
 reset(confile);
 if ioresult<>0 then errorhandler('contacts.dta (adding new alien)',1);
 err:=false;
 already:=false;
 index:=-1;
 repeat
  inc(index);
  read(confile,temp);
  if ioresult<>0 then err:=true;
  if temp.id=alien.id then already:=true;
 until (err) or (already);
 if err then                       { add to end }
  begin
   seek(confile,index);
   if ioresult<>0 then errorhandler(tempdir+'/contacts.dta (appending alien)',5);
   write(confile,alien);
   if ioresult<>0 then errorhandler(tempdir+'/contacts.dta (appending alien)',5);
  end;
 close(confile);
end;

{ fills alien structure with gamedata from file for alien "n" (unless n=13), and sets index to "contactindex" }
procedure getspecial(n,contactindex: integer);
var f: file of alientype;
begin
 if n=13 then
  begin
   alien.id:=contactindex;
   exit;
  end;
 assign(f,'data/contact0.dta');
 reset(f);
 if ioresult<>0 then errorhandler('data/contact0.dta',1);
 seek(f,n-1);
 if ioresult<>0 then errorhandler('data/contact0.dta',5);
 read(f,alien);
 if ioresult<>0 then errorhandler('data/contact0.dta',5);
 alien.id:=contactindex;
 close(f);
end;

procedure setalienstructure(starting: integer);
begin
 case tempplan^[contactindex].system of
   93: getspecial(1,contactindex);
  138: getspecial(2,contactindex);
   45: if not chevent(27) then getspecial(4,contactindex);
  221: getspecial(5,contactindex);
   78: getspecial(6,contactindex);
  171: getspecial(8,contactindex);
  191: getspecial(9,contactindex);
  else
   if (tempplan^[contactindex].mode=2) and (tempplan^[contactindex].state=6)
     then getspecial(11,contactindex)
  else
   begin
    case hi(techlvl) of
     3: x:=1;
     4: x:=2;
     5: x:=3;
     else x:=0;
    end;
    alien.conindex:=30+x;
    getname(contactindex);
    x:=hi(techlvl);
    y:=lo(techlvl);
    with alien do
     begin
      y:=y-5;
      if y<0 then
       begin
        dec(x);
        y:=10+y;
       end;
      if x<0 then
       begin
        x:=0;
        y:=0;
       end;
      techmin:=x*256+y;
      y:=lo(techlvl);
      y:=y+5;
      if y>9 then
       begin
        inc(x);
        y:=y-10;
       end;
      if x>5 then
       begin
        x:=5;
        y:=0;
       end;
      techmax:=x*256+y;
      id:=contactindex;
      victory:=random(40);
      war:=false;
      case starting of
       1: begin
           if random(3)=0 then war:=true;
           congeniality:=15;
           anger:=30;
           createwandering(WNDORDER_ATTACK);
          end;
       2: begin
           congeniality:=20;
           anger:=10;
          end;
       3: begin
           congeniality:=40;
           anger:=0;
          end;
       4: begin
           congeniality:=20;
           anger:=15;
          end;
       5: begin
           congeniality:=5;
           anger:=0;
           createwandering(WNDORDER_RETREAT);
          end;
      end;
     end;
   end;
 end;
 addtofile;
end;

procedure clearconvflags;
var
   i : Integer;
begin
   for i := 500 to 599 do
      clearevent(i);
end; { clearconvflags }

procedure contactsequence(plan,com: integer);
var contactmade: integer;
begin
 mousehide;
 if plan=0 then techlvl:=alien.techmax
  else if (plan>-1) and (plan<1000) then gettechlevel(plan)
  else if plan>1000 then techlvl:=1280
  else techlvl:=0;
 if techlvl<1 then
  begin
   printxy(12,135,'Unintelligible Cypher');
   printxy(12,145,'Contact Failure');
   mouseshow;
   exit;
  end;
 contactmade:=0;
 if (hi(techlvl)<4) then
  case eattype of
   0: contactmade:=1;
   1: case com of
       0: contactmade:=5;
       1: contactmade:=3;
       2: contactmade:=2;
      end;
   2: contactmade:=random(5);
   end
  else
   case eattype of
    0: case com of
        0: if random(2)=0 then contactmade:=1 else contactmade:=3;
        1: contactmade:=2+random(2);
        2: contactmade:=2;
       end;
    1: case com of
        0: contactmade:=4;
        1: contactmade:=2+random(2);
	2: contactmade:=2;
       end;
    2: contactmade:=random(5);
   end;
 if (contactmade>0) and (contactindex=-1) then
  begin
   contactindex:=plan;
   tempplan^[contactindex].notes:=tempplan^[contactindex].notes or 2;
   setalienstructure(contactmade);
  end;
 printxy(12,135,'Cypher Acknowledged');
 printxy(12,145,'Awaiting Response');
 if contactmade>0 then printxy(12,155,'Contact Established')
  else contactindex:=-1;
 mouseshow;
end;

{***************************************************************************}

procedure loadconversation;
var fc: file of converseindex;
    fr: file of responsetype;
    str1: string[4];
begin
   fillchar(r^,sizeof(responsearray),0);
   fillchar(c^,sizeof(conversearray),0);
   str((contactindex+1):4,str1);
   if contactindex<1000 then str1[1]:='0';
   if contactindex<100 then str1[2]:='0';
   if contactindex<10 then str1[3]:='0';
   assign(fc,'data/conv'+str1+'.ind');
   reset(fc);
   if ioresult<>0 then errorhandler('data/conv'+str1+'.ind',1);
   i:=0;
   repeat
      inc(i);
      read(fc,c^[i]);
   until ioresult<>0;
   close(fc);
   assign(fr,'data/conv'+str1+'.dta');
   reset(fr);
   if ioresult<>0 then errorhandler('data/conv'+str1+'.dta',1);
   i:=0;
   repeat
      inc(i);
      read(fr,r^[i]);
   until ioresult<>0;
   close(fr);
end;

procedure showportrait(n: integer);
var s: string[2];
    portrait: ^portraittype;
begin
 new(portrait);
 str(n:2,s);
 if n<10 then s[1]:='0';
 loadscreen('data/image'+s,portrait);
 for i:=0 to 34 do
  begin
   scrto_move(portrait^[i*2],screen[i*2+41,126],70);
   delay(tslice div 5);
  end;
 for i:=0 to 34 do
  begin
   scrto_move(portrait^[i*2+1],screen[i*2+42,126],70);
   delay(tslice div 5);
  end;
 dispose(portrait);
end;

procedure drawcursor;
begin
 for i:=(contactindex mod 3)*30+37 to (contactindex mod 3)*30+42 do
  for j:=(contactindex div 3)*138+89 to (contactindex div 3)*138+93 do
   if screen[i,j] div 16=3 then screen[i,j]:=screen[i,j]+32;
 showportrait(ship.crew[contactindex+1].index);
end;

procedure erasecursor;
begin
 for i:=(contactindex mod 3)*30+37 to (contactindex mod 3)*30+42 do
  for j:=(contactindex div 3)*138+89 to (contactindex div 3)*138+93 do
   if screen[i,j] div 16=5 then screen[i,j]:=screen[i,j]-32;
end;

procedure displaycrewnames;
var a,b: integer;
begin
 t1:=22/36;
 for a:=0 to 5 do
  begin
   if (ship.crew[a+1].index=18) or (ship.crew[a+1].index=25) or (ship.crew[a+1].index=26)
    then i:=6 else i:=1;
   b:=1;
   repeat
    printxy((a div 3)*230+12+b*5,(a mod 3)*30+37,ship.crew[a+1].name[i]);
    inc(i);
    inc(b);
   until ship.crew[a+1].name[i]=' ';
   j:=round((0.40*ship.crew[a+1].men+0.60*ship.crew[a+1].emo-0.20*ship.crew[a+1].phy)*0.36);
   if j>36 then j:=36
   else if j<1 then j:=0;
   for b:=0 to j do
    begin
     screen[(a mod 3)*30+48,(a div 3)*258+b+13]:=round(t1*b)+73;
     screen[(a mod 3)*30+49,(a div 3)*258+b+13]:=round(t1*b)+73;
    end;
   if j<34 then
    for b:=j+1 to 36 do
     begin
     screen[(a mod 3)*30+48,(a div 3)*258+b+13]:=0;
     screen[(a mod 3)*30+49,(a div 3)*258+b+13]:=0;
    end;
  end;
end;

procedure checkstring(p,q,s: integer); forward;

procedure command2(n: integer);
begin
 mousehide;
 for i:=135 to 189 do
  scr_fillchar(screen[i,15],278,0);
 printxy(12,182,'Subject:');
 if contactindex>-1 then erasecursor;
 contactindex:=n;
 drawcursor;
 showportrait(ship.crew[contactindex+1].index);
 mouseshow;
 loadconversation;
 question:='HI';
   {checkstring(95,176,170);}
   checkstring(95,42,170);
end;

procedure findmouse2;
begin
 if not mouse.getstatus then exit;
 case mouse.y of
    30..50: case mouse.x of
                9..85: if contactindex<>0 then command2(0);
             235..311: if contactindex<>3 then command2(3);
            end;
    60..80: case mouse.x of
                9..85: if contactindex<>1 then command2(1);
             235..311: if contactindex<>4 then command2(4);
            end;
   90..110: case mouse.x of
                9..85: if contactindex<>2 then command2(2);
             235..311: if contactindex<>5 then command2(5);
            end;
  154..170: if mouse.x>309 then done:=true;
 end;
 idletime:=0;
end;

procedure printxy2(x1,y1,m,n,o: integer; s: string);
var letter,j2,a,x,y,t : integer;
label skipit;
begin
   t:=tcolor;
   brighter:=false;
   j2:=0;
   x1:=x1+4;
   for j:=1 to length(s) do
   begin
      if s[j]=#200 then
      begin
	 if brighter then brighter:=false else brighter:=true;
	 goto skipit;
      end;
      letter:=ord(s[j]);
      if brighter then
	 tcolor := n
      else
      {if (brighter) then
      case ship.options[OPT_DIFFICULTY] of
      0: tcolor:=m;
      1: tcolor:=n;
      2: tcolor:=o;
    end
    else} tcolor:=o;
      bkcolor:=m;
      inc(j2);
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
	 dec(tcolor,1);
	 x:=x1;
	 inc(y);
	 inc(i);
	 for a:=3 downto 0 do
	 begin
	    inc(x);
	    if font[ship.options[OPT_FONT],letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor
	    else if bkcolor<255 then screen[y,x]:=bkcolor;
	 end;
	 dec(tcolor,2);
      end;
      for i:=1 to 6 do screen[y1+i,x1+5]:=bkcolor;
      delay(tslice div 3);
      bkcolor:=0;
      if brighter then
	 tcolor := n
      else
      {   if (brighter) then
      case ship.options[OPT_DIFFICULTY] of
      0: tcolor:=m;
      1: tcolor:=n;
      2: tcolor:=o;
    end
    else} tcolor:=o;
      y:=y1;
      for i:=0 to 5 do
      begin
	 x:=x1;
	 inc(y);
	 for a:=7 downto 4 do
	 begin
	    inc(x);
	    if font[ship.options[OPT_FONT],letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor
	    else if bkcolor<255 then screen[y,x]:=bkcolor;
	 end;
	 dec(tcolor,1);
	 inc(i);
	 inc(y);
	 x:=x1;
	 for a:=3 downto 0 do
	 begin
	    inc(x);
	    if font[ship.options[OPT_FONT],letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor
	    else if bkcolor<255 then screen[y,x]:=bkcolor;
	 end;
	 dec(tcolor,2);
      end;
      for i:=1 to 6 do screen[y1+i,x1+5]:=bkcolor;
      x1:=x1+5;
skipit:
   end;
   tcolor:=t;
end;

function parsestatement(y,n,p,q,s: integer): integer;
var done: boolean;
    a,b,c,i2,letter: integer;
begin
   str1^:=r^[n].response;
   i:=1;
   j:=1;
   {copy response string, inserting crew names if needed}
   repeat
      if str1^[i]=#201 then
      begin
	 inc(i);
	 a:=ord(str1^[i])+35-48;
	 b:=20;
	 while ship.crew[a].name[b]=' ' do dec(b);
	 for c:=1 to b do
	 begin
	    letter:=ord(ship.crew[a].name[c]);
	    case chr(letter) of
	      ' ' ..'"': letter:=letter-31;
	      ''''..'?': letter:=letter-35;
	      'A' ..'Z': letter:=letter-36;
	      'a' ..'z': letter:=letter-40;
	    else letter:=1;
	    end;
	    str2^[j]:=chr(letter);
	    inc(j);
	 end;
	 dec(j);
      end
      else str2^[j]:=str1^[i];
      inc(j);
      inc(i);
   until i>ord(str1^[0]);
   str2^[0]:=chr(j-1);
   done:=false;
   repeat
      str1^:=str2^;
      i:=56;
      if ord(str1^[0])>56 then
      begin
	 while str1^[i]<>#1 do dec(i);
	 str2^:=copy(str1^,i+1,ord(str1^[0])-i);
	 str1^[0]:=chr(i-1);
      end else done:=true;
      printxy2(12,135+y*6,p,q,s,str1^);
      inc(y);
      if y=8 then
      begin
	 for j:=184 to 188 do
	    scr_fillchar(screen[j,15],288,0);
	 tcolor:=47;
	 printxy(146,191,'MORE');
	 i2:=47;
	 mouseshow;
	 repeat
	    fadestep(FADESTEP_STEP);
	    tcolor:=i2;
	    printxy(146,191,'MORE');
	    dec(i2);
	    if i2=41 then i2:=47;
	    animatealien;
	    delay(tslice*FADE_TSLICE_MUL_COMM);
	 until (fastkeypressed) or (mouse.getstatus);
	 while fastkeypressed do readkey;
	 mousehide;
	 for j:=141 to 188 do
	    scr_fillchar(screen[j,15],288,0);
	 printxy(146,191,'    ');
	 tcolor:=s;
	 y:=1;
      end;
   until done;
   parsestatement:=y;
end;

{ 2000x events set while conversing with some race, in Data_Generators/makedata/*con*.txt }
procedure run20000event(n: integer);
begin
 case n of
  20000: begin {good bye}
          for i:=182 to 188 do
           scr_fillchar(screen[i,12],200,0);
          contactindex:=-1;
         end;
  20001: begin {trade}
          if alien.war then
           begin
            for i:=141 to 181 do
             scr_fillchar(screen[i,12],288,0);
            printxy(12,141,'WE ARE AT WAR!');
           end
          else trade;
         end;
  20002: begin {attack!}
          for i:=182 to 188 do
           scr_fillchar(screen[i,12],200,0);
          contactindex:=-1;
          createwandering(WNDORDER_ATTACK);
          ship.wandering.relx:=500+random(100);
          ship.wandering.rely:=500+random(100);
          ship.wandering.relz:=500+random(100);
         end;
  20003: begin {increase anger by 1} // FIXME: not used in *con*.txt ?
          if alien.anger<100 then inc(alien.anger);
          if infomode then
           begin
            getinfo;
            getinfo;
           end;
         end;
  20004: begin {increase anger by 5} // FIXME: not used in *con*.txt ?
          inc(alien.anger,5);
          if alien.anger>100 then alien.anger:=100;
           begin
            getinfo;
            getinfo;
           end;
         end;
  20005: begin {increase congeniality by 1} // FIXME: not used in *con*.txt ?
          if alien.congeniality<100 then inc(alien.congeniality);
          if infomode then
           begin
            getinfo;
            getinfo;
           end;
         end;
  20006: begin {increase congeniality by 5} // FIXME: not used in *con*.txt ?
          inc(alien.congeniality,5);
          if alien.congeniality>100 then alien.congeniality:=100;
           begin
            getinfo;
            getinfo;
           end;
         end;
 end;
end;

function run21000event(n, p,q,s: integer) : Boolean;
var result : boolean;
begin
   run21000event := false;
   assert ((p <> -1) and (q <> - 1));	{ just to get rid of warning, really not used }
   case n of
     21001 : begin {Phaedor Moch: Coolant + Radioactive}
		if (incargo(ID_COOLANTS) >= 1) and (incargo(ID_RADIOACTIVES) >= 1) then
		begin
		   bkcolor := 0;
		   tcolor := s;
		   printxy(12,135+(1)*6,'Give the Phaedor Moch a radioactive and a coolant?');
		   mouseshow;
		   result := yesnorequest('Give supplies?',0,31);
		   mousehide;
		   if result then
		   begin
		      removecargo(ID_COOLANTS);
		      removecargo(ID_RADIOACTIVES);
		      addcargo(ID_ART_GLYPTIC_SCYTHE, true);
		      run21000event := true;
		      addpending(1101, 0);
		      event(500);
		   end else begin
		      printxy(12,135+(2)*6,'No.');
		   end;
		end else begin
		   bkcolor := 0;
		   tcolor := s;
		   printxy(12,135+(1)*6,'(Eng: We have no radioactives and coolants to spare.)');
		end;
	     end;
     21002 : begin {Aard: Stratamount}
		if (incargo(ID_STRATAMOUNT) >= 1) then
		begin
		   printxy(12,135+(1)*6,'Give the Aard a stratamount?');
		   mouseshow;
		   result := yesnorequest('Give supplies?',0,31);
		   mousehide;
		   if result then
		   begin
		      removecargo(ID_STRATAMOUNT);
		      addcargo(ID_BALLISTA, true);
		      run21000event := true;
		      addpending(1102, 0);
		      event(500);
		   end else begin
		      printxy(12,135+(2)*6,'No.');
		   end;
		end else begin
		   bkcolor := 0;
		   tcolor := s;
		   printxy(12,135+(1)*6,'(Eng: We have no stratamounts to spare.)');
		end;
	     end;
   end;
end;

procedure checkstring(p,q,s: integer);
var index,index2,i,i2: integer;
begin
   mousehide;
   for i:=135 to 181 do
      scr_fillchar(screen[i,15],288,0);
   for i:=182 to 187 do
      scr_fillchar(screen[i,61],100,0);
   tcolor:=s;
   printxy(12,135,question);
   i:=20;
   while question[i]=' ' do dec(i);
   if i=0 then
   begin
      mouseshow;
      exit;
   end;
   question[0]:=chr(i);
   for j:=1 to i do
      case question[j] of
	' ' ..'"': question[j]:=chr(ord(question[j])-31);
	''''..'?': question[j]:=chr(ord(question[j])-35);
	'A' ..'Z': question[j]:=chr(ord(question[j])-36);
	'a' ..'z': question[j]:=chr(ord(question[j])-40);
	'%'	  : question[j]:=#55;
      else question[j]:=#1;
      end;
   index:=0;
   {i:=1;}
   repeat
      inc(index);
      j:=pos(#1+question+#1,c^[index].keyword);
      {if j > 0 then
      begin
	 str(index,str1^);
	 str(ord(chevent(c^[index].event)),str2^);
	 str1^ := str1^ + ',' + str2^;
	 str(c^[index].event,str2^);
	 printxy(1, i * 6, str1^ + ',' + str2^ + '  ');
	 inc(i);
	 printxy(1, i * 6, '  ');
      end;}
      if (c^[index].event <> -1) and not chevent(c^[index].event) then
	 j := 0;
   until (j>0) or (c^[index].rcode=0);
   fillchar(question,21,ord(' '));
   question[0]:=#20;
   cursorx:=1;
   if j=0 then
   begin
      mouseshow;
      exit;
   end;
   i:=1;
   while (r^[i].index<>c^[index].index) and (i<=maxconverse) do inc(i);
   if i>maxconverse then
   begin
      str(c^[index].index,str1^);
      errorhandler('index:'+str1^+' keyword:'+question+' not found.',6);
   end;
   if (c^[index].runevent<21000) or run21000event(c^[index].runevent,p,q,s) then
   begin
      case c^[index].rcode of
	1 : parsestatement(1,i,p,q,s);
	2 : begin
	       j:=1;
	       while r^[i+j].index=c^[index].index do inc(j);
	       parsestatement(1,i+random(j),p,q,s);
	    end;
	3 : begin
	       index2:=i;
	       i2:=1;
	       repeat
		  i2:=parsestatement(i2,index2,p,q,s);
		  inc(index2);
	       until r^[i].index<>r^[index2].index;
	       printxy(12,182,'Subject:');
	    end;
      end; { case }
   end;
   if (c^[index].runevent>19999) and (c^[index].runevent<21000) then
      run20000event(c^[index].runevent);
   mouseshow;
end;

procedure processkey2;
var ans: char;
    old: integer;
begin
//	    writeln('comm.pas:917  processkey2');
//	    p^:=0;
 ans:=upcase(readkey_utf8);
// ans:=readkey;
// writeln('key= ',ord(ans));
 tcolor:=31;
 case ans of
  'A'..'Z',' ','0'..'9','''','-': if contactindex>-1 then
        begin

         if cursorx<20 then
          begin
           for j:=20 downto cursorx do question[j]:=question[j-1];
           question[cursorx]:=ans;
           inc(cursorx);
          end else question[cursorx]:=ans;
         mousehide;
         printxy(57,182,question);
         mouseshow;
        end;
   #8: if contactindex>-1 then
        begin
         if cursorx>1 then dec(cursorx);
         for j:=cursorx to 19 do question[j]:=question[j+1];
         question[20]:=' ';
         mousehide;
         printxy(57,182,question);
         mouseshow;
        end;
   #0: if contactindex>-1 then
        begin
         ans:=readkey;
         case ans of
          #77: if cursorx<20 then inc(cursorx);
          #75: if cursorx>1 then dec(cursorx);
          #83: begin
                for j:=cursorx to 19 do question[j]:=question[j+1];
                mousehide;
                printxy(57,182,question);
                mouseshow;
               end;
          #59: command2(0);
          #60: command2(1);
          #61: command2(2);
          #62: command2(3);
          #63: command2(4);
          #64: command2(5);
         end;
        end
        else
         begin
          ans:=readkey;
          if (ans>#58) and (ans<#65) then command2(ord(ans)-59);
         end;
  #13: if contactindex>-1 then
        begin
         old:=contactindex;
         {checkstring(95,176,170);}
	   checkstring(95,42,170);
         if contactindex=-1 then
          begin
           i:=old;
           old:=contactindex;
           contactindex:=i;
           erasecursor;
           contactindex:=old;
          end;
        end;
  #27: done:=true;
  '`': bossmode;
 end;
 idletime:=0;
end;

procedure delay_blink;
var c: Integer;
begin
   for c := 1 to FADE_TSLICE_MUL_BLINK do
   begin
      if fastkeypressed then exit;
      delay(tslice);
   end;
end;

procedure mainloop2;
begin
 repeat
  fadestep(FADESTEP_STEP);
  if fastkeypressed then
   begin
    processkey2;
   end;
  findmouse2;
  if batindex<8 then inc(batindex) else
   begin
    batindex:=0;
    addtime2;
   end;
  inc(idletime);
  if idletime=maxidle then screensaver;
  if contactindex>-1 then
   begin
    bkcolor:=95;
    printxy(cursorx*5+52,182,question[cursorx]);
    delay_blink();
    bkcolor:=0;
    printxy(cursorx*5+52,182,question[cursorx]);
    delay_blink();
   end
  else delay_blink();
 until done;
end;

procedure readycrewdata;
begin
 mousehide;
 compressfile(tempdir+'/current',@screen);
 {fading;}
 fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);
 playmod(true,'sound/CREWCOMM.MOD');
 loadscreen('data/charcom',@screen);
 oldt1:=t1;
 bkcolor:=0;
 tcolor:=170;
 printxy(12,182,'Converse with crew member:');
 done:=false;
 contactindex:=-1;
 alien.conindex:=-1;
 fillchar(question,21,ord(' '));
 question[0]:=#20;
 new(str1);
 new(str2);
 new(c);
 new(r);
 cursorx:=1;
 displaycrewnames;
 {fadein;}
 mouseshow;
end;

procedure conversewithcrew;
begin
   clearconvflags;
   readycrewdata;
   mainloop2;
   dispose(str2);
   dispose(str1);
   dispose(c);
   dispose(r);
   {stopmod;}
   removedata; {this one calls removedata in utils2}
   {haltmod;}
end;

{*****************************************************************************}

procedure loadbackground(n: integer);
var str1: string[2];
begin
 str(((n-1) div 2)+1,str1);
 loadscreen('data/back'+str1,backgr);
 {new(p);}
 move(colors,p^,sizeof(paltype));
 y:=(n-1) mod 2;
 if y=1 then move(backgr^[100],backgr^,8000*4);
 mousehide;
 for i:=11 to 110 do
  for j:=0 to 319 do
   if (screen[i,j]=255) then screen[i,j]:=backgr^[i-11,j];
 mouseshow;
end;

procedure loadalienpic(n: integer);
var str1: string[2];
begin
 new(aliens);
 str(n,str1);
 loadscreen('data/alien'+str1,aliens);
 for j:=0 to 159 do colors[j]:=p^[j];
 {dispose(p);}
 if n=10 then exit;
 mousehide;
 for i:=11 to 110 do
  for j:=0 to 159 do
   if aliens^[i-11,j]>0 then screen[i,j+20]:=aliens^[i-11,j];
 mouseshow;
end;


{ returns alien anger level:
  1 = Afraid'
  2 = Indifferent'
  3 = Friendly
  4 = Angry
  5 = Violent
}
function calc_anger (anger, congeniality: integer): integer;
var r: real;
begin
 if anger=0 then
  begin
   if congeniality>20 then calc_anger:=3
    else calc_anger:=1;
  end
 else
  begin
   r:=congeniality/anger;
   if r<0.3 then calc_anger:=5
   else if r<0.7 then calc_anger:=4
   else if round(r)=1 then calc_anger:=2
   else calc_anger:=3;
  end;
end;


procedure getshipinfo;
var confile: file of alientype;
    done: boolean;
    temp: alientype;
    str1: string[11];
begin
 assign(confile,tempdir+'/contacts.dta');
 reset(confile);
 if ioresult<>0 then errorhandler(tempdir+'/contacts.dta',1);
 done:=false;
 repeat
  read(confile,temp);
  if ioresult<>0 then done:=true;
  if (not done) and (temp.id>0) and (temp.id=ship.wandering.alienid) then done:=true;
 until done;
 close(confile);
 printxy(217,20,temp.name);
 printxy(217,20,temp.name);
 printxy(217,30,'Vidcom');
 if temp.id>1000 then printxy(217,40,'Unknown')
  else printxy(217,40,systems[tempplan^[temp.id].system].name);
 str1:=chr(hi(temp.techmin)+48)+'.'+chr(lo(temp.techmin)+48);
 printxy(217,50,'Min Tech: '+str1);
 str1:=chr(hi(temp.techmax)+48)+'.'+chr(lo(temp.techmax)+48);
 printxy(217,60,'Max Tech: '+str1);
 printxy(217,70,'Status:');
 if temp.war then printxy(252,70,'War')
  else printxy(252,70,'Peace');
 i:=calc_anger(temp.anger, temp.congeniality);
 case i of
  1: str1:='Afraid';
  2: str1:='Indifferent';
  3: str1:='Friendly';
  4: str1:='Angry';
  5: str1:='Violent';
 end;
 printxy(217,80,str1);
end;

procedure getcontactindex;
var i: integer;
    s: string[14];
begin
 i:=0;
 if alien.conindex>29 then
  begin
   i:=1069+alien.conindex;
   randseed:=alien.conindex;
   loadbackground(random(numback)+1);
   playmod(true,'sound/PROBE.MOD');
  end
 else
  begin
   i:=alien.conindex;
   randseed:=alien.conindex*1131;
   case i of
     1: s:='SENGZHAC.MOD';
     2: s:='DPAK.MOD';
     3: s:='AARD.MOD';
     4: s:='ERMIGEN.MOD';
     5: s:='TITARIAN.MOD';
     6: s:='QUAI.MOD';
     7: s:='SCAVENG.MOD';
     8: s:='ICON.MOD';
     9: s:='GUILD.MOD';
    10: s:='PHADOR.MOD';
    11: s:='VOID.MOD';
   else s:='';
   end;
   {if ioresult<>0 then printxy(217,20,'sound/'+s);}
   if s<>'' then playmod(true,'sound/'+s);
   {if checkerror then printxy(217,20,'checkerror');
   if not playing then printxy(217,20,'not playing');
   if ModuleError = MERR_MEMORY then printxy(217,20,'MERR_MEMORY');
   if ModuleError = MERR_FILE then printxy(217,20,'MERR_FILE');
   if ModuleError = MERR_TYPE then printxy(217,20,'MERR_TYPE');
   if ModuleError = MERR_CORRUPT then printxy(217,20,'MERR_CORRUPT');}
   case i of
     1: j:=7;
     2: j:=18;
     3: j:=9;
     4: j:=15;
     5: j:=22;
     6: j:=17;
     7: j:=4;
     8: j:=14;
     9: j:=2;
    10: j:=21;
    11: j:=19;
   end;
   loadbackground(j);
   if i<11 then loadalienpic(i);
   animatealien;
   i:=i+999;
  end;
 randomize;
 contactindex:=i;
end;

procedure getinfo;
var str1: string[11];
begin
 if infomode then
  begin
   infomode:=false;
   mousehide;
   for i:=20 to 101 do
    scrto_move(backgr^[i-11,222],screen[i,222],19*4);
   mouseshow;
   exit;
  end;
 if contactindex=-1 then exit;
 infomode:=true;
 tcolor:=31;
 bkcolor:=255;
 if shipflag then getshipinfo
 else begin
  printxy(217,20,alien.name);
  if curplan=alien.id then
   begin
    if hi(alien.techmax)>=3 then printxy(217,30,'Radio')
     else printxy(217,30,'Visual');
   end
  else printxy(217,30,'Subspace');
  printxy(217,40,systems[tempplan^[curplan].system].name);
  str1:=chr(hi(alien.techmin)+48)+'.'+chr(lo(alien.techmin)+48);
  printxy(217,50,'Min Tech: '+str1);
  str1:=chr(hi(alien.techmax)+48)+'.'+chr(lo(alien.techmax)+48);
  printxy(217,60,'Max Tech: '+str1);
  printxy(217,70,'Status:');
  if alien.war then printxy(252,70,'War')
   else printxy(252,70,'Peace');
  i:=calc_anger(alien.anger, alien.congeniality);
  case i of
   1: str1:='Afraid';
   2: str1:='Indifferent';
   3: str1:='Friendly';
   4: str1:='Angry';
   5: str1:='Violent';
  end;
  printxy(217,80,str1);
 end;
end;

procedure findmouse3;
begin
 if not mouse.getstatus then exit;
 case mouse.x of
  308..317: if (mouse.y>142) and (mouse.y<169) then done:=true;
  247..267: if (mouse.y>104) and (mouse.y<111) then getinfo;
 end;
 idletime:=0;
end;

procedure processkey3;
var ans: char;
begin
 ans:=upcase(readkey_utf8);
 tcolor:=26;
 case ans of
  'A'..'Z',' ','0'..'9','''','-': if contactindex>-1 then
        begin
         if cursorx<20 then
          begin
           for j:=20 downto cursorx do question[j]:=question[j-1];
           question[cursorx]:=ans;
           inc(cursorx);
          end else question[cursorx]:=ans;
         mousehide;
         printxy(57,182,question);
         mouseshow;
        end;
   #8: if contactindex>-1 then
        begin
         if cursorx>1 then dec(cursorx);
         for j:=cursorx to 19 do question[j]:=question[j+1];
         question[20]:=' ';
         mousehide;
         printxy(57,182,question);
         mouseshow;
        end;
   #0: if contactindex>-1 then
        begin
         ans:=readkey;
         case ans of
          #77: if cursorx<20 then inc(cursorx);
          #75: if cursorx>1 then dec(cursorx);
          #83: begin
                for j:=cursorx to 19 do question[j]:=question[j+1];
                mousehide;
                printxy(57,182,question);
                mouseshow;
               end;
         end;
        end;
  #13: if contactindex>-1 then checkstring(47,55,28);{checkstring(47,31,28);}
  '?','/': getinfo;
  #27: done:=true;
  '`': bossmode;
  #10: printbigbox(GetHeapStats1,GetHeapStats2);
 end;
 idletime:=0;
end;

procedure animatealien;
begin
 mousehide;
 case alien.conindex of
  1: begin
      if indexa<>255 then
       begin
        if indexa<6 then inc(indexa) else indexa:=255;
        if (indexa<>255) then
         begin
          for i:=0 to 9 do
           for j:=0 to 32 do
            if aliens^[i+indexa*11,j+220]>0 then screen[i+37,j+85]:=aliens^[i+indexa*11,j+220]
             else screen[i+37,j+85]:=backgr^[i+26,j+85];
         end;
       end
      else if random(20)=0 then indexa:=0;
      if indexb<14 then inc(indexb) else indexb:=0;
      if indexb=0 then
       begin
        for i:=0 to 18 do
         for j:=0 to 22 do
          if aliens^[i+77,j+9]>0 then screen[i+88,j+29]:=aliens^[i+77,j+9]
           else screen[i+88,j+29]:=backgr^[i+77,j+29];
       end
      else
       for i:=0 to 18 do
        for j:=0 to 22 do
         if aliens^[i+((indexb-1) mod 7)*20,((indexb-1) div 7)*24+j+160]>0
          then screen[i+88,j+29]:=aliens^[i+((indexb-1) mod 7)*20,((indexb-1) div 7)*24+j+160]
          else screen[i+88,j+29]:=backgr^[i+77,j+29];
      if random(20)=0 then
       begin
        if indexc<7 then inc(indexc) else indexc:=0;
        for i:=0 to 21 do
         for j:=0 to 42 do
          if aliens^[i+indexc*23,260+j]>0 then screen[i+89,j+139]:=aliens^[i+indexc*23,260+j]
           else screen[i+89,j+139]:=backgr^[i+78,j+139];
       end;
     end;
  2: if ((random(200)=0) and (indexa=0)) or ((indexa<>255) and (indexa<>0)) then
      begin
       if indexb>0 then dec(indexb) else
        begin
         indexb:=3;
         if indexa<12 then inc(indexa) else
          begin
           indexa:=255;
           mouseshow;
           exit;
          end;
        end;
       dec(indexa);
       for i:=0 to 54 do
        for j:=0 to 34 do
         if aliens^[i+(indexa mod 3)*59+2,(indexa div 3)*38+j+164]>0
          then screen[i+16,j+140]:=aliens^[i+(indexa mod 3)*59+2,(indexa div 3)*38+j+164]
           else screen[i+16,j+140]:=backgr^[i+5,j+140];
       inc(indexa);
      end;
  3: if indexa=0 then
      begin
       randomize;
       indexa:=random(1000);
       indexb:=random(5);
       indexa:=1;
       for i:=0 to 23 do
        for j:=0 to 23 do
         if aliens^[i+indexb*30,j+170]>0 then screen[i+20,j+90]:=aliens^[i+indexb*30,j+170]
          else screen[i+20,j+90]:=backgr^[i+9,j+90];
      end;
  4: if indexa<>255 then
      begin
       for i:=0 to 11 do
        for j:=0 to 56 do
         if aliens^[i+indexa*13,170+j]>0 then screen[i+23,j+91]:=aliens^[i+indexa*13,170+j]
          else screen[i+23,j+91]:=backgr^[i+12,j+91];
       if indexa<9 then inc(indexa) else indexa:=255;
      end
     else if random(20)=0 then indexa:=0;
  5: begin
      if indexa<5 then inc(indexa) else indexa:=0;
      for i:=0 to 10 do
       scrto_move(aliens^[i+indexa*12,170],screen[29+i,94],49);
      if random(20)=0 then
       begin
        if indexb<4 then inc(indexb) else indexb:=0;
        for i:=0 to 27 do
         for j:=0 to 25 do
          if aliens^[i+indexb*28,220+j]>0 then screen[i+41,j+57]:=aliens^[i+indexb*28,220+j]
           else screen[i+41,j+57]:=backgr^[i+30,j+57];
       end;
      if random(20)=0 then
       begin
        if indexc<4 then inc(indexc) else indexc:=0;
        for i:=0 to 27 do
         for j:=0 to 25 do
          if aliens^[i+indexb*28,250+j]>0 then screen[i+41,j+155]:=aliens^[i+indexb*28,250+j]
           else screen[i+41,j+155]:=backgr^[i+30,j+155];
       end;
     end;
  6: begin
      if indexa<8 then inc(indexa) else indexa:=0;
      for i:=0 to 19 do
       for j:=0 to 37 do
        if aliens^[i+indexa*20,j+170]>0 then screen[i+40,j+81]:=aliens^[i+indexa*20,j+170]
         else screen[i+40,j+81]:=backgr^[i+19,j+81];
     end;
  7: begin
      if indexa<18 then inc(indexa) else indexa:=0;
      for i:=0 to 2 do
       scrto_move(aliens^[i+indexa*4,180],screen[i+27,88],21);
      if indexb<6 then inc(indexb) else indexb:=0;
      for i:=0 to 33 do
       for j:=0 to 20 do
        if aliens^[i+120,j+indexb*21]>0 then screen[i+77,j+88]:=aliens^[i+120,j+indexb*21]
         else screen[i+77,j+88]:=backgr^[i+66,j+88];
     end;
  8: if indexa<>255 then
      begin
       if indexa<8 then inc(indexa) else indexa:=255;
       if (indexa<>255) then
        begin
         for i:=0 to 19 do
          for j:=0 to 52 do
           if aliens^[i+indexa*20,j+250]>0 then screen[i+57,j+77]:=aliens^[i+indexa*20,j+250]
            else screen[i+57,j+77]:=backgr^[i+46,j+77];
         end;
      end
     else if random(30)=0 then indexa:=0;
  9: begin
      if random(15)=0 then
       begin
        if indexa<7 then inc(indexa) else indexa:=0;
        if indexa=0 then
         begin
          for i:=0 to 21 do
           for j:=0 to 32 do
            if aliens^[i+74,j+33]>0 then screen[i+85,j+53]:=aliens^[i+74,j+33]
             else screen[i+85,j+53]:=backgr^[i+74,j+53];
         end
        else
         for i:=0 to 21 do
          for j:=0 to 32 do
           if aliens^[i+indexa*25-24,j+162]>0 then screen[i+85,j+53]:=aliens^[i+indexa*25-24,j+162]
            else screen[i+85,j+53]:=backgr^[i+74,j+53];
       end
      else if random(15)=0 then
       begin
        if indexb<5 then inc(indexb) else indexb:=0;
        if indexb=0 then
         begin
          for i:=0 to 22 do
           for j:=0 to 12 do
            if aliens^[i+51,j+136]>0 then screen[i+62,j+156]:=aliens^[i+51,j+136]
             else screen[i+62,j+156]:=backgr^[i+51,j+156];
         end
        else
         for i:=0 to 22 do
          for j:=0 to 12 do
           if aliens^[i+indexb*26-26,j+200]>0 then screen[i+62,j+156]:=aliens^[i+indexb*26-26,j+200]
            else screen[i+62,j+156]:=backgr^[i+51,j+156];
       end;
     end;
  10: begin
        if random(30)=0 then indexa:=random(9);
        if indexb>0 then dec(indexb) else
         begin
          indexb:=20;
          if indexa<8 then inc(indexa) else indexa:=0;
         end;
        for i:=0 to 8 do
         scrto_move(aliens^[i+indexa*10+101],screen[i+51,111],50);
       end;
 end;
 mouseshow;
end;

procedure mainloop3;
begin
 repeat
  fadestep(FADESTEP_STEP);
  findmouse3;
  if fastkeypressed then processkey3;
  if batindex<8 then inc(batindex) else
   begin
    batindex:=0;
    addtime2;
   end;
  inc(idletime);
  if idletime=maxidle then screensaver;
  if contactindex>-1 then
   begin
    bkcolor:=47;
    printxy(cursorx*5+52,182,question[cursorx]);
    delay_blink();
    bkcolor:=0;
    printxy(cursorx*5+52,182,question[cursorx]);
    delay_blink();
   end
  else delay_blink();
  animatealien;
 until done;
end;

{ contact aliens on planet }
procedure getlocals;
var confile: file of alientype;
    done: boolean;
begin
 if not showplanet then
  begin
   contactindex:=-1;
   exit;
  end;
 assign(confile,tempdir+'/contacts.dta');
 reset(confile);
 if ioresult<>0 then errorhandler(tempdir+'/contacts.dta',1);
 done:=false;
 repeat
  read(confile,alien);
  if ioresult<>0 then done:=true;
 until (done) or ((alien.id>0) and (alien.id=curplan));
 close(confile);
 if done then contactindex:=-1 else contactindex:=curplan;
 if (tempplan^[curplan].system=45) and (chevent(27)) then
  begin
   contactindex:=-1;
   tempplan^[curplan].notes:=tempplan^[curplan].notes and not 2;
  end;
 contactsequence(curplan,random(3));
end;

{ contact alien ship }
procedure getship;
var confile: file of alientype;
    done: boolean;
begin
 if ship.wandering.alienid>19999 then
  begin
   contactindex:=-1;
   contactsequence(-1,random(3));
   exit;
  end;
 assign(confile,tempdir+'/contacts.dta');
 reset(confile);
 if ioresult<>0 then errorhandler(tempdir+'/contacts.dta',1);
 done:=false;
 repeat
  read(confile,alien);
  if ioresult<>0 then done:=true;
 until (done) or ((alien.id>0) and (alien.id=ship.wandering.alienid));
 close(confile);
 if done then contactindex:=-1 else contactindex:=alien.id;
 shipflag:=true;
 contactsequence(alien.id,random(3));
end;

procedure checkotherevents2;
var t	 : ^eventarray;
    f	 : file of eventarray;
    n,i	 : integer;

   procedure printstatement;
   var done : boolean;
      j	    : integer;
   begin
      mousehide;
      for j:=127 to 179 do
	 scr_fillchar(screen[j,5],300,0);
      str2^:=t^[i].msg;
      done:=false;
      y:=0;
      repeat
	 str1^:=str2^;
	 j:=56;
	 if ord(str1^[0])>56 then
	 begin
	    while str1^[j]<>' ' do dec(j);
	    str2^:=copy(str1^,j+1,ord(str1^[0])-j);
	    str1^[0]:=chr(j-1);
	 end else done:=true;
	 printxy(12,135+y*6,str1^);
	 inc(y);
      until done;
      if n<10 then i:=9 else i:=0;
      mouseshow;
      eventflag:=true;
   end;

begin
   if contactindex=-1 then exit;
   n:=alien.conindex-1;
   if n>10 then exit;
   new(t);
   assign(f,'data/event.dta');
   reset(f);
   if ioresult<>0 then errorhandler('data/event.dta',1);
   seek(f,n);
   if ioresult<>0 then errorhandler('data/event.dta',5);
   read(f,t^);
   if ioresult<>0 then errorhandler('data/event.dta',5);
   close(f);
   if (n<10) then
   begin
      for i:=0 to 9 do if not chevent(n*10+50+i) then
      begin
	 if t^[i].want>20000 then
	 begin
	    if chevent(t^[i].want-20000) then printstatement;
	 end
	 else if (t^[i].want>0) then
	 begin
	    if incargo(t^[i].want)>0 then printstatement;
	 end
	 else if (t^[i].want=0) and (t^[i].give>0) then printstatement;
      end;
   end
   else
   begin
      for i:=9 downto 0 do if not chevent(n*10+50+i) then
      begin
	 if t^[i].want>20000 then
	 begin
	    if chevent(t^[i].want-20000) then printstatement;
	 end
     else if (t^[i].want>0) then
     begin
	if incargo(t^[i].want)>0 then printstatement;
     end
     else if (t^[i].want=0) and (t^[i].give>0) then printstatement;
      end;
   end;
   dispose(t);
end;

procedure readydata3(hail: boolean);
begin
   mousehide;
   compressfile(tempdir+'/current',@screen);
   {fading;}
   fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);
   loadscreen('data/com',@screen);
   {fadein;}
   new(tmpm);
   for i:=0 to 15 do
   begin
      scrfrom_move(screen[i+130,20],tmpm^[i],4*4);
      scr_fillchar(screen[i+130,20],16,0);
   end;
   mousesetcursor(tmpm^);
   dispose(tmpm);
   done:=false;
   bkcolor:=0;
   tcolor:=28;
   infomode:=false;
   fillchar(question,21,ord(' '));
   question[0]:=#20;
   oldt1:=t1;
   cursorx:=1;
   indexa:=0;
   indexb:=0;
   oldcontactindex:=-1;
   shipflag:=false;
   eventflag:=false;
   aliens:=nil;
   new(str1);
   new(str2);
   new(c);
   new(r);
   new(p);
   {$IFDEF DEMO}
   contactindex:=-1;
   if hail then;	// ignore warning if demo
   {$ELSE}
   if hail then getship
   else getlocals;
   {$ENDIF}
   mouseshow;
   if contactindex=-1 then
   begin
      mousehide;
      for i:=10 to 110 do
	 for j:=0 to 319 do
	    if (screen[i,j]=255) and (i mod 2=0) then screen[i,j]:=random(32)+64
	    else if (screen[i,j]=255) then screen[i,j]:=random(32)+96;
      {fadein;}
      tcolor:=28;
      bkcolor:=0;
{$IFDEF DEMO}
      printxy(12,140,'Wouldn''t it be cool to talk to aliens?');
      printxy(12,150,'Buy the game and you can...');
      printxy(12,160,'11 Alien races... 11 awesome songs...');
      printxy(12,170,'You gotta buy the game!');
{$ELSE}
      printxy(12,170,'No response...');
{$ENDIF}
      mouseshow;
      repeat
	 findmouse3;
	 for i:=64 to 95 do
	    colors[i]:=colors[random(32)];
	 fillchar(colors[96],96,0);
	 palettedirty := true;
	 fadestep(FADESTEP_STEP);
	 {set256colors(colors);}
	 delay(FADE_TSLICE_ALIENS);
	 for i:=96 to 128 do
	    colors[i]:=colors[random(32)];
	 fillchar(colors[64],96,0);
	 palettedirty := true;
	 fadestep(0);
	 {set256colors(colors);}
      until (fastkeypressed) or (done);
      while fastkeypressed do readkey;
      fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);
      done:=true;
   end
   else
   begin
      oldcontactindex:=contactindex;
      mousehide;
      printxy(12,182,'Subject:');
      mouseshow;
      getcontactindex;
      loadconversation;
      {fadein;}
      checkotherevents2;
      if not eventflag then
      begin
	 question:='HI';
	 if contactindex>-1 then checkstring(47,55,28); {checkstring(47,31,28);}
      end;
   end;
end;

procedure checkotherevents(n: integer);
var t: ^eventarray;
    f: file of eventarray;
begin
   new(t);
   assign(f,'data/event.dta');
   reset(f);
   if ioresult<>0 then errorhandler('data/event.dta',1);
   seek(f,n);
   if ioresult<>0 then errorhandler('data/event.dta',5);
   read(f,t^);
   if ioresult<>0 then errorhandler('data/event.dta',5);
   close(f);
   if (n<10) then
   begin
      for i:=0 to 9 do if not chevent(n*10+50+i) then
      begin
	 if t^[i].want>20000 then
	 begin
	    if chevent(t^[i].want-20000) then
	    begin
	       if t^[i].give>20000 then event(t^[i].give-20000)
	       else if t^[i].give>0 then addcargo(t^[i].give, true);
	       event(n*10+50+i);
	       i:=9;
	    end;
	 end
	 else if (t^[i].want>0) then
	 begin
	    if incargo(t^[i].want)>0 then
	    begin
	       if (t^[i].give>20000) and (t^[i].give<30000) then event(t^[i].give-20000)
	       else if (t^[i].give>0) and (t^[i].give<30000) then addcargo(t^[i].give, true);
	       event(n*10+50+i);
	       removecargo(t^[i].want);
	       i:=9;
	    end;
	 end
	 else if (t^[i].want=0) and (t^[i].give>0) then
	 begin
	    if (t^[i].give>20000) and (t^[i].give<30000) then event(t^[i].give-20000)
	    else if (t^[i].give>0) and (t^[i].give<30000) then addcargo(t^[i].give, true);
	    event(n*10+50+i);
	    i:=9;
	 end;
      end;
   end
   else
   begin
      for i:=9 downto 0 do if not chevent(n*10+50+i) then
      begin
	 if t^[i].want>20000 then
	 begin
	    if chevent(t^[i].want-20000) then
	    begin
	       if t^[i].give>20000 then event(t^[i].give-20000)
	       else if t^[i].give>0 then addcargo(t^[i].give, true);
	       event(n*10+50+i);
	       i:=0;
	    end;
	 end
	 else if (t^[i].want>0) then
	 begin
	    if incargo(t^[i].want)>0 then
	    begin
	       if (t^[i].give>20000) and (t^[i].give<30000) then event(t^[i].give-20000)
	       else if (t^[i].give>0) and (t^[i].give<30000) then addcargo(t^[i].give, true);
	       event(n*10+50+i);
	       removecargo(t^[i].want);
	       i:=0;
	    end;
	 end
	 else if (t^[i].want=0) and (t^[i].give>0) then
	 begin
	    if (t^[i].give>20000) and (t^[i].give<30000) then event(t^[i].give-20000)
	    else if (t^[i].give>0) and (t^[i].give<30000) then addcargo(t^[i].give, true);
	    event(n*10+50+i);
	    i:=0;
	 end;
      end;
   end;
   dispose(t);
end;

procedure removedata;
var n: integer;
begin
 n:=alien.conindex-1;
 if aliens<>nil then dispose(aliens);
 dispose(str2);
 dispose(str1);
 dispose(c);
 dispose(r);
 dispose(p);
 {stopmod;}
 {fading;}
 fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);

 loadscreen('data/cloud',backgr);
 if showplanet then
  begin
   if ((tempplan^[curplan].state=6) and (tempplan^[curplan].mode=2)) then makeastoroidfield
    else if (tempplan^[curplan].state=0) and (tempplan^[curplan].mode=1) then makecloud;
  end;
 mousehide;
 mouse.setmousecursor(random(3));
 loadscreen(tempdir+'/current',@screen);
 bkcolor:=3;
 displaytextbox(false);
 textindex:=25;
 {fadein;}
 mouseshow;
 anychange:=true;
 t1:=oldt1;
 if (oldcontactindex<>-1) and (n>-1) and (n<11) then
  begin
   if n<9 then event(n);
   if n=10 then event(9);
   checkotherevents(n);
  end;
end;

procedure continuecontact(hail: boolean);
begin
 clearconvflags;
 readydata3(hail);
 if contactindex<>-1 then mainloop3;
 removedata;
end;

begin
end.
