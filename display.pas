unit display;
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

{*********************************************
   Ship Display Control unit for IronSeed

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2013 y-salnikov
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

interface

procedure displayoptions(com: integer);
procedure displaystarmap;
procedure displaystatus;
procedure displaysysteminfo(com: integer);
procedure displayshieldopts(com: integer);
procedure displayweaponinfo(com: integer);
procedure displaydamagecontrol(com: integer);
procedure displaylogs(com: integer);
procedure displaysystem(com: integer);
procedure displayship2(x1,y1: integer);
procedure displayshipinfo;
procedure checkstats;
procedure targetplanet(xt,yt: integer);
procedure displayconfigure(com: integer);
procedure findgunnode(x,y:integer);
procedure displaybotinfo(com: integer);
procedure displayhistorymap;
procedure displayshortscan;
procedure displaylongscan;
function checkloc(l: integer): boolean;

implementation

uses utils_, data, gmouse, journey, utils, usecode, saveload, utils2, comm, modplay, math;

const
 batmax=32000;
 shdbut2: buttype = (11,7,8);
 shdbut: buttype = (9,12,12);
 shdbut3: buttype = (11,8,12);
 conbut: buttype= (10,7,12);
 conbut2: buttype= (11,8,12);
 botbut0: buttype= (14,15,16);
 botbut1: buttype= (11,14,12);
 botbut2: buttype= (11,16,12);
 logbut1: buttype= (23,25,12);
 logbut2: buttype= (23,25,6);
var
 a,b,i,j,index,c1,c2: integer;

procedure displayoptions(com: integer);
var s: string[5];
begin
 case com of
  0:;
  1,6: case viewindex of
        2: begin
            if ship.options[OPT_TIMESLICE]>1 then dec(ship.options[OPT_TIMESLICE]);
            tslice:=ship.options[OPT_TIMESLICE];
           end;
        3: begin
            ship.options[OPT_SOUND]:=0;
            stopmod;
           end;
        9: begin
            if ship.options[OPT_VOLUME]>1 then dec(ship.options[OPT_VOLUME]);
            setmodvolume;
           end;
        else if ship.options[viewindex]>0 then dec(ship.options[viewindex]);
       end;
  2,7: case viewindex of
      1: if ship.options[OPT_SCREENSAVER]<1 then inc(ship.options[OPT_SCREENSAVER]);
      2: begin
          if ship.options[OPT_TIMESLICE]<250 then inc(ship.options[OPT_TIMESLICE]);
          tslice:=ship.options[OPT_TIMESLICE];
         end;
      4: if ship.options[OPT_DIFFICULTY]<2 then inc(ship.options[OPT_DIFFICULTY]);
      5: if ship.options[OPT_MSGS]<2 then inc(ship.options[OPT_MSGS]);
      7: if ship.options[OPT_FONT]<2 then inc(ship.options[OPT_FONT]);
      9: begin
          if ship.options[OPT_VOLUME]<64 then inc(ship.options[OPT_VOLUME]);
          setmodvolume;
         end;
      else if ship.options[viewindex]=0 then ship.options[viewindex]:=1;
     end;
  3: if viewindex=1 then viewindex:=9 else dec(viewindex);
  4: if viewindex=9 then viewindex:=1 else inc(viewindex);
  5: begin
      removerightside(true);
      exit;
     end;
 end;
 tcolor:=191;
 mousehide;
 if viewindex=1 then bkcolor:=179 else bkcolor:=5;
 if ship.options[OPT_SCREENSAVER]=0 then printxy(251,37,'Off') else printxy(251,37,' On');
 if viewindex=2 then bkcolor:=179 else bkcolor:=5;
 str(ship.options[OPT_TIMESLICE]:3,s);
 printxy(251,46,s);
 if viewindex=3 then bkcolor:=179 else bkcolor:=5;
 if ship.options[OPT_SOUND]=1 then printxy(251,55,' On') else printxy(251,55,'Off');
 if viewindex=4 then bkcolor:=179 else bkcolor:=5;
 case ship.options[OPT_DIFFICULTY] of
  0: s:='Min';
  1: s:='Avg';
  2: s:='Max';
 end;
 printxy(251,64,s);
 if viewindex=5 then bkcolor:=179 else bkcolor:=5;
 case ship.options[OPT_MSGS] of
  2: s:=' All';
  1: s:='Some';
  0: s:='None';
 end;
 printxy(246,73,s);
 if viewindex=6 then bkcolor:=179 else bkcolor:=5;
 if ship.options[OPT_ANIMATION]=1 then printxy(251,82,' On') else printxy(251,82,'Off');
 if viewindex=7 then bkcolor:=179 else bkcolor:=5;
 case ship.options[OPT_FONT] of
  0: s:=' Iron';
  1: s:='Clean';
  2: s:='Block';
 end;
 printxy(241,91,s);
 if viewindex=8 then bkcolor:=179 else bkcolor:=5;
 if ship.options[OPT_AUTOSAVE]=1 then printxy(251,100,' On') else printxy(251,100,'Off');
 str(ship.options[OPT_VOLUME]:3,s);
 if viewindex=9 then bkcolor:=179 else bkcolor:=5;
 printxy(251,109,s);
 mouseshow;
 bkcolor:=3;
end;

procedure displaydamagecontrol(com: integer);
var s: string[11];
begin
 mousehide;
 case com of
  0:;
  1: if viewlevel=2 then
      begin
       viewlevel:=1;
       for i:=37 to 114 do
        scr_fillchar(screen[i,166],113,5);
       screen[44,165]:=10;
       screen[45,279]:=2;
       setcolor(2);
       line(166,63,278,63);
       line(166,90,278,90);
       setcolor(10);
       line(166,64,278,64);
       line(166,91,278,91);
       screen[63,165]:=6;
       screen[90,165]:=6;
       screen[64,279]:=6;
       screen[91,279]:=6;
       with ship.engrteam[viewindex] do
        begin
         case job of
             0:;
          1..7: if ship.damages[job]=0 then job:=0;
             8: if ship.hullintegrity=ship.hullmax then job:=0;
         end;
         if job=0 then timeleft:=0;
        end;
       tcolor:=191;
       bkcolor:=5;
       printxy(168,27,'Damage Control Teams');
      end;
  2: if (viewlevel=1) and (ship.engrteam[viewindex].job<9) then
      begin
       viewlevel:=2;
       for i:=37 to 114 do
        scr_fillchar(screen[i,166],113,5);
       screen[63,165]:=10;
       screen[90,165]:=10;
       screen[64,279]:=2;
       screen[91,279]:=2;
       setcolor(10);
       line(166,45,278,45);
       setcolor(2);
       line(165,44,278,44);
       screen[44,165]:=6;
       screen[45,279]:=6;
       bkcolor:=5;
       tcolor:=191;
       printxy(186,109,teamdata[15]);
       str(viewindex:2,s);
       printxy(168,27,'Engineering Team '+s+' ');
       tcolor:=186;
       printxy(243,37,'Damage');
       printxy(161,37,'Team');
       printxy(186,37,'Option');
      end;
  3: if viewlevel=1 then
       begin
        if viewindex=1 then viewindex:=3 else dec(viewindex);
       end
     else if ship.engrteam[viewindex].jobtype=JOBTYPE_REPAIR then
      begin
       i:=ship.engrteam[viewindex].job;
       bkcolor:=5;
       printxy(159+6*viewindex,46+i*7,' ');
       if ship.engrteam[viewindex].job=0 then ship.engrteam[viewindex].job:=8
        else dec(ship.engrteam[viewindex].job);
       with ship.engrteam[viewindex] do
        case job of
            0: timeleft:=0;
         1..7: if ship.damages[job]>0 then timeleft:=ship.damages[job]*70+random(30);
            8: if ship.hullintegrity<ship.hullmax then timeleft:=(ship.hullmax-ship.hullintegrity)*30+random(40);
        end;
      end;
  4: if viewlevel=1 then
      begin
       if viewindex=3 then viewindex:=1 else inc(viewindex);
      end
     else if ship.engrteam[viewindex].jobtype=JOBTYPE_REPAIR then
      begin
       i:=ship.engrteam[viewindex].job;
       bkcolor:=5;
       printxy(159+6*viewindex,46+i*7,' ');
       if ship.engrteam[viewindex].job=8 then ship.engrteam[viewindex].job:=0
        else inc(ship.engrteam[viewindex].job);
       with ship.engrteam[viewindex] do
        case job of
            0: timeleft:=0;
         1..7: if ship.damages[job]>0 then timeleft:=ship.damages[job]*70+random(30);
            8: if ship.hullintegrity<ship.hullmax then timeleft:=(ship.hullmax-ship.hullintegrity)*30+random(40);
        end;
      end;
  5: begin
      removerightside(true);
      mouseshow;
      exit;
     end;
  6,7,8: begin
          if viewlevel=1 then
           begin
            viewindex:=com-5;
            viewlevel:=2;
            for i:=37 to 114 do
             scr_fillchar(screen[i,166],113,5);
            screen[63,165]:=10;
            screen[90,165]:=10;
            screen[64,279]:=2;
            screen[91,279]:=2;
            setcolor(10);
            line(166,45,278,45);
            setcolor(2);
            line(165,44,278,44);
            screen[44,165]:=6;
            screen[45,279]:=6;
            bkcolor:=5;
            tcolor:=191;
            printxy(186,109,teamdata[15]);
            str(viewindex:2,s);
            printxy(168,27,'Engineering Team '+s+' ');
            tcolor:=186;
            printxy(243,37,'Damage');
            printxy(161,37,'Team');
            printxy(186,37,'Option');
           end
          else if viewlevel=2 then
           begin
            bkcolor:=5;
            tcolor:=191;
            printxy(186,109,teamdata[15]);
            str((com-5):2,s);
            printxy(168,27,'Engineering Team '+s+' ');
            with ship.engrteam[viewindex] do
             begin
              case job of
                  0:;
               1..7: if ship.damages[job]=0 then job:=0;
                  8: if ship.hullintegrity=ship.hullmax then job:=0;
              end;
              if job=0 then timeleft:=0;
             end;
            viewindex:=com-5;
           end;
         end;
 end;
 tcolor:=191;
 bkcolor:=5;
 case viewlevel of
  1: begin
      if viewindex=1 then bkcolor:=179 else bkcolor:=5;
      printxy(163,39,'Engineering Team 1');
      if viewindex=2 then bkcolor:=179 else bkcolor:=5;
      printxy(163,66,'Engineering Team 2');
      if viewindex=3 then bkcolor:=179 else bkcolor:=5;
      printxy(163,93,'Engineering Team 3');
      setcolor(184);
      for j:=1 to 3 do
       line(168,20+27*j,258,20+27*j);
      bkcolor:=5;
      for j:=1 to 3 do
       with ship.engrteam[j] do
       begin
        if job=0 then printxy(169,22+j*27,teamdata[0]+'        ')
         else
          begin
           case jobtype of
            JOBTYPE_REPAIR:	s:='Repair ';
            JOBTYPE_INSTALL:	s:='Install ';
            JOBTYPE_REMOVE:	s:='Remove ';
            JOBTYPE_CREATE:	s:='Create ';
            JOBTYPE_DECOMPOSE:	s:='Disjoin ';
            JOBTYPE_RESEARCH:	s:='Research ';
           end;
           case job of
                0..100: i:=job;
            ID_DIRK..1499: i:=10;		{ weapons }
            ID_REFLECTIVEHULL..1999: i:=9;	{ shields }
            ID_NOTHING..2999: i:=11;		{ devices }
            ID_UNKNOWN_COMPONENT..3999: i:=12;	{ components }
            ID_UNKNOWN_MATERIAL..4999: i:=13;	{ materials }
            ID_ARTIFACT_OFFSET..ID_LAST_ARTIFACT: i:=14;	{ artifacts }
           end;
           printxy(169,22+j*27,s+teamdata[i]);
          end;
        if timeleft=0 then
         begin
          s:='Completed  ';
          printxy(175,28+j*27,s);
         end
         else if timeleft<0 then
          begin
           tcolor:=94;
           printxy(175,28+j*27,'Overdue    ');
           tcolor:=191;
          end
         else
          begin
           str(timeleft:6,s);
	   {str(extra div 256,s2);}
           printxy(175,28+j*27,s+' Mins'{+s2});
          end;
        end;
     end;
  2: begin
      if ship.engrteam[viewindex].job=0 then bkcolor:=179 else
       bkcolor:=5;
      printxy(186,46,teamdata[0]);
      for j:=1 to 7 do
       begin
        if ship.engrteam[viewindex].job=j then bkcolor:=179
         else bkcolor:=5;
        str(ship.damages[j]:3,s);
        printxy(186,46+j*7,teamdata[j]);
        printxy(258,46+j*7,s);
       end;
      if ship.engrteam[viewindex].job=8 then bkcolor:=179 else
       bkcolor:=5;
      str(ship.hullmax-ship.hullintegrity:4,s);
      printxy(186,102,teamdata[8]);
      printxy(253,102,s);
      for i:=46 to 114 do
       scr_fillchar(screen[i,170],17,5);
      for j:=1 to 3 do
       begin
        if ship.engrteam[j].jobtype>JOBTYPE_REPAIR then i:=9
         else i:=ship.engrteam[j].job;
        tcolor:=61;
        bkcolor:=5;
        printxy(159+6*j,46+i*7,chr(j+48));
       end;
     end;
 end;
 mouseshow;
 bkcolor:=3;
end;

procedure showshdicon(shd: integer);
begin
 assert (shd >= ID_NOSHIELD);
 case shd of
  ID_NOSHIELD: begin
      for i:=0 to 19 do
       scr_fillchar(screen[89+i,172],20,0);
     end;
  ID_REFLECTIVEHULL..1519:
     begin
      readweaicon(shd-ID_SHIELDS_OFFSET-2);	{ NOSHIELD / noweapon do not have icons, so -2  }
      for i:=0 to 19 do
       scrto_move(tempicon^[i],screen[89+i,172],5*4);
     end;
 end;
end;

procedure setupshieldinfo(shd: integer);
begin
 assert (shd >= ID_NOSHIELD);
 for i:=37 to 114 do
  scr_fillchar(screen[i,166],113,5);
 setcolor(184);
 line(168,44,232,44);
 revgraybutton(171,88,192,109);
 setcolor(10);
 line(166,53,278,53);
 line(166,83,278,83);
 line(220,53,220,81);
 setcolor(2);
 line(166,52,278,52);
 line(166,82,278,82);
 line(219,54,219,82);
 screen[53,279]:=6;
 screen[83,279]:=6;
 screen[52,165]:=6;
 screen[82,165]:=6;
 screen[82,220]:=6;
 screen[53,219]:=6;
 revgraybutton(204,86,271,111);
 if viewlevel<3 then
  printxy(163,37,'Active Shield')
   else printxy(163,37,'Target Shield');
 printxy(163,54,'Sys Damage');
 printxy(163,61,'Max Energy');
 printxy(163,68,'Protection');
 printxy(163,75,'Cargo Size');
 printxy(194,87,'P');
 printxy(194,93,'P');
 printxy(193,99,'I');
 printxy(194,105,'E');
 showshdicon(shd);
end;

procedure displayshieldinfo(shd: integer);
var str1: string[5];
begin
 tcolor:=31;
 if shd>ID_NOSHIELD then printxy(174,45,cargo[shd-ID_SHIELDS_OFFSET].name)
  else printxy(174,45,'None                ');

 if ship.damages[DMG_SHIELD]>0 then
  begin
   str(ship.damages[DMG_SHIELD]:5,str1);
   printxy(218,54,str1+'%   ');
  end
 else printxy(218,54,'      None');

 if shd>ID_NOSHIELD then
  begin
   str(weapons[shd-ID_SHIELDS_OFFSET].energy:5,str1);
   printxy(218,61,str1+' GW   ');
   str(weapons[shd-ID_SHIELDS_OFFSET].damage:5,str1);
   printxy(218,68,str1+' GJ   ');
   for j:=1 to 4 do
    begin
     y:=round(weapons[shd-ID_SHIELDS_OFFSET].dmgtypes[j]*0.66);
     for i:=-2 to 3 do
      begin
       if i>0 then x:=100-i
        else x:=100+i;
       scr_fillchar(screen[83+i+j*6,205],y,x);
       if y<66 then
        scr_fillchar(screen[83+i+j*6,205+y],66-y,0);
      end;
    end;
  end
 else
  begin
   printxy(218,61,'      None');
   printxy(218,68,'      None');
   for i:=87 to 110 do
    scr_fillchar(screen[i,205],65,2);
  end;

 if shd>ID_REFLECTIVEHULL then	{ some energy&space-using shield installed }
  begin
   j:=1;
   while cargo[j].index<>shd
    do inc(j);
   if j<114 then
    begin
     i:=cargo[j].size div 10;
     str(i:5,str1);
     printxy(218,75,str1+' Cu.M');
    end;
  end
 else printxy(218,75,'      None');
end;

procedure removeshieldinfo;
begin
 for i:=37 to 114 do
  scr_fillchar(screen[i,166],113,5);
 screen[52,165]:=10;
 screen[82,165]:=10;
 screen[53,279]:=2;
 screen[83,279]:=2;
 showpanel(shdbut);
 printxy(168,27,'Shield Configuration');
 printxy(163,37,'Active Shield');
 setcolor(184);
 line(168,44,232,44);
 tcolor:=31;
 if ship.shield>ID_NOSHIELD then printxy(174,45,cargo[ship.shield-ID_SHIELDS_OFFSET].name)
  else printxy(174,45,'None                ');
 tcolor:=191;
 for j:=1 to 3 do
  begin
   setcolor(2);
   line(172,51+j*18,274,51+j*18);
   line(172,51+j*18,172,57+j*18);
   setcolor(10);
   line(172,57+j*18,273,57+j*18);
   line(274,51+j*18,274,57+j*18);
   screen[51+j*18,274]:=4;
   screen[57+j*18,172]:=4;
  end;
end;

procedure displayshieldopts(com: integer);
var str1: string[5];
begin
 tcolor:=191;
 bkcolor:=5;
 mousehide;
 if ship.shield=ID_REFLECTIVEHULL then
  for i:=1 to 3 do ship.shieldopt[i]:=100-ship.damages[DMG_SHIELD];
 if ship.shield<=ID_NOSHIELD then
  for i:=1 to 3 do ship.shieldopt[i]:=0;

 case com of
  0:;
  1: if viewlevel=0 then	{ left }
      begin
       if ship.shield>ID_REFLECTIVEHULL then dec(ship.shieldopt[viewindex],min(5, ship.shieldopt[viewindex]))
      end
     else if viewlevel=3 then
      begin
       viewlevel:=2;
       for i:=37 to 114 do
        scr_fillchar(screen[i,166],113,5);
       showpanel(shdbut3);
       screen[52,165]:=10;
       screen[82,165]:=10;
       screen[53,279]:=2;
       screen[83,279]:=2;
       printxy(170,27,'Installable Shields');
      end;
  2: if viewlevel=0 then	{ right }
      begin
       if ship.shield>ID_REFLECTIVEHULL then inc(ship.shieldopt[viewindex],min(5, 100-ship.shieldopt[viewindex]))
      end
     else if (viewlevel=2) and (viewindex2>0) then
      begin
       viewlevel:=3;
       setupshieldinfo(ship.cargo[viewindex2]);
      end;
  3: if viewlevel>1 then	{ up }
       begin
        dec(viewindex2);
        while (viewindex2>0) and ((ship.cargo[viewindex2]<ID_NOSHIELD) or (ship.cargo[viewindex2]>ID_LAST_SHIELD)) do dec(viewindex2);
        if viewindex2=0 then viewindex2:=250;
        while (viewindex2>0) and ((ship.cargo[viewindex2]<ID_NOSHIELD) or (ship.cargo[viewindex2]>ID_LAST_SHIELD)) do dec(viewindex2);
        if (viewindex2>0) and (viewlevel=3) then showshdicon(ship.cargo[viewindex2]);
       end
     else if viewindex=1 then viewindex:=3 else dec(viewindex);
  4: if viewlevel>1 then	{ down }
       begin
        inc(viewindex2);
        while (viewindex2<251) and ((ship.cargo[viewindex2]<ID_NOSHIELD) or (ship.cargo[viewindex2]>ID_LAST_SHIELD)) do inc(viewindex2);
        if viewindex2=251 then viewindex2:=1;
        while (viewindex2<251) and ((ship.cargo[viewindex2]<ID_NOSHIELD) or (ship.cargo[viewindex2]>ID_LAST_SHIELD)) do inc(viewindex2);
        if viewindex2=251 then viewindex2:=0;
        if (viewindex2>0) and (viewlevel=3) then showshdicon(ship.cargo[viewindex2]);
       end
     else if viewindex=3 then viewindex:=1 else inc(viewindex);
  5: begin
      mouseshow;
      removerightside(true);
      exit;
     end;
  6: case viewlevel of
      0: begin
          viewlevel:=1;
          printxy(165,27,'  Shield Statistics  ');
          setupshieldinfo(ship.shield);
          showpanel(shdbut2);
         end;
      1,2,3:
         begin
          viewlevel:=0;
          removeshieldinfo;
         end;
     end;
  7: begin
     i:=0;
     for j:=1 to 3 do
      if ((ship.engrteam[j].jobtype>=JOBTYPE_INSTALL) and (ship.engrteam[j].jobtype<=JOBTYPE_REMOVE)
      and (ship.engrteam[j].job>=ID_NOSHIELD) and (ship.engrteam[j].job<=ID_LAST_SHIELD)) then i:=1;
     if i=1 then
      begin
       tcolor:=94;
       bkcolor:=3;
       println;
       print('ENGINEERING: Already working on a shield.');
      end
     else if (viewlevel=1) and (ship.shield>ID_REFLECTIVEHULL) then	{ noshield and reflective hull can't be removed }
       begin		{ want to remove shield }
        mouseshow;
        if yesnorequest('Remove this shield?',0,31) then
         begin
          j:=1;
          while (ship.engrteam[j].job<>0) and (j<4) do inc(j);
          if j=4 then
           begin
            println;
            tcolor:=94;
            print('ENGINEERING: No team available.');
           end
          else
           begin	{ there is engineering team available, start removing shield }
            addcargo(ship.shield, true);
            ship.engrteam[j].job:=ship.shield;
            ship.engrteam[j].jobtype:=JOBTYPE_REMOVE;
            ship.engrteam[j].timeleft:=1000;
            ship.shield:=ID_REFLECTIVEHULL;	// NB not fair but simple - we get reflective hull even if didn't have it before, if we remove any other shield... oh well..
            mousehide;
            showshdicon(ship.shield);
            mouseshow;
            for i:=1 to 3 do ship.shieldopt[i]:=0;
           end;
         end;
        mousehide;
       end
      else if (viewlevel>1) and (ship.shield<=ID_REFLECTIVEHULL) and (viewindex2>0) then
       begin		{ want to install shield }
        mouseshow;
        if yesnorequest('Install this shield?',0,31) then
         begin
          j:=1;
          while (ship.engrteam[j].job<>0) and (j<4) do inc(j);
          if j=4 then
           begin
            println;
            tcolor:=94;
            print('ENGINEERING: No team available.');
           end
          else
           begin	{ there is engineering team available, start installing shield }
            ship.engrteam[j].job:=ship.cargo[viewindex2];
            removecargo(ship.cargo[viewindex2]);
            ship.engrteam[j].jobtype:=JOBTYPE_INSTALL;
            ship.engrteam[j].timeleft:=1000;
           end;
         end;
        mousehide;
       end
      else if (viewlevel>1) and (viewindex2>0) then
       begin
        tcolor:=94;
        bkcolor:=3;
        println;
        print('ENGINEERING: We must remove the old shield first.');
       end;
      bkcolor:=5;
      tcolor:=191;
     end;
  8: if viewlevel=1 then
      begin
       viewlevel:=2;
       for i:=37 to 114 do
        scr_fillchar(screen[i,166],113,5);
       showpanel(shdbut3);
       screen[52,165]:=10;
       screen[82,165]:=10;
       screen[53,279]:=2;
       screen[83,279]:=2;
       printxy(170,27,'Installable Shields');
       viewindex2:=1;
       while (viewindex2<251) and ((ship.cargo[viewindex2]<ID_NOSHIELD) or (ship.cargo[viewindex2]>ID_LAST_SHIELD)) do inc(viewindex2);
       if viewindex2=251 then viewindex2:=0;
      end;
 end;
 case viewlevel of
  0: begin
      tcolor:=31;
      if ship.shield>ID_NOSHIELD then printxy(174,45,cargo[ship.shield-ID_SHIELDS_OFFSET].name)
       else printxy(174,45,'None                ');
      tcolor:=191;
      str(ship.damages[DMG_SHIELD]:3,str1);
      printxy(163,53,'System Damage:'+str1+'%');
      if viewindex=1 then bkcolor:=179 else bkcolor:=5;
      printxy(163,61,'Rest Mode');
      if viewindex=2 then bkcolor:=179 else bkcolor:=5;
      printxy(163,79,'Alert Mode');
      if viewindex=3 then bkcolor:=179 else bkcolor:=5;
      printxy(163,97,'Combat Mode');
      for j:=1 to 3 do
       for i:=-2 to 2 do
        begin
         if i>0 then setcolor(40-i)
          else setcolor(40+i);
         line(173,54+i+j*18,173+ship.shieldopt[j],54+i+j*18);
        end;
      setfillstyle(1,2);
      for j:=1 to 3 do
       if ship.shieldopt[j]<100 then
        bar(174+ship.shieldopt[j],52+j*18,274,57+j*18);
     end;
  1: displayshieldinfo(ship.shield);
  2: begin
      if (viewindex2>0) and ((ship.cargo[viewindex2]<ID_NOSHIELD) or (ship.cargo[viewindex2]>=ID_NOTHING)) then
       displayshieldopts(4);
      x:=viewindex2+1;
      y:=7;
      repeat
       while (x<251) and ((ship.cargo[x]<ID_NOSHIELD) or (ship.cargo[x]>ID_LAST_SHIELD)) do inc(x);
       if x<251 then
        begin
         inc(y);
         printxy(167,31+y*6,cargo[ship.cargo[x]-ID_SHIELDS_OFFSET].name);
        end;
       inc(x);
      until (y=13) or (x>250);
      if y<13 then
       for j:=38+y*6 to 116 do
        scr_fillchar(screen[j,166],113,5);
      x:=viewindex2;
      y:=8;
      repeat
       while (x>0) and ((ship.cargo[x]<ID_NOSHIELD) or (ship.cargo[x]>ID_LAST_SHIELD)) do dec(x);
       if x=viewindex2 then bkcolor:=179 else bkcolor:=5;
       if x>0 then
        begin
         dec(y);
         printxy(167,31+y*6,cargo[ship.cargo[x]-ID_SHIELDS_OFFSET].name);
        end;
       dec(x);
      until (y=1) or (x<1);
      if y>1 then
       for j:=37 to 31+y*6 do
        scr_fillchar(screen[j,166],113,5);
     end;
  3: begin
      if (ship.cargo[viewindex2]<ID_NOSHIELD) or (ship.cargo[viewindex2]>=ID_NOTHING) then
       displayshieldopts(4);
      if viewindex2>0 then displayshieldinfo(ship.cargo[viewindex2]);
     end;
 end;
 mouseshow;
 bkcolor:=3;
 { engineering / shield display checks }
 if ship.shield<=ID_REFLECTIVEHULL then exit;
 if ship.damages[DMG_SHIELD]>25 then
  begin
   tcolor:=94;
   println;
   ship.shieldlevel:=0;
   if ship.damages[DMG_SHIELD]>59 then
    begin
     print('COMPUTER: Shield integrity compromised...needs repair.');
     exit;
    end
   else
    begin
     print('Shield unstable...');
     if (random(40)+20)<ship.damages[DMG_SHIELD] then
      begin
       print('COMPUTER: Failed to adjust shield.');
       exit;
      end;
    end;
  end;

 if alert=ALRT_REST then
  ship.shieldlevel:=ship.shieldopt[SHLD_LOWERED_WANT]
 else if alert=ALRT_ALERT then
  ship.shieldlevel:=ship.shieldopt[SHLD_ALERT_WANT]
 else if alert=ALRT_COMBAT then
  ship.shieldlevel:=ship.shieldopt[SHLD_COMBAT_WANT];
end;

procedure setupweaponinfo;
begin
 for i:=37 to 114 do
  scr_fillchar(screen[i,166],113,5);
 revgraybutton(171,88,192,109);
 setcolor(10);
 line(166,53,278,53);
 line(166,83,278,83);
 line(220,53,220,81);
 setcolor(2);
 line(166,52,278,52);
 line(166,82,278,82);
 line(219,54,219,82);
 screen[53,279]:=6;
 screen[83,279]:=6;
 screen[52,165]:=6;
 screen[82,165]:=6;
 screen[82,220]:=6;
 screen[53,219]:=6;
 revgraybutton(204,86,271,111);
 if viewlevel<3 then
  printxy(163,37,'Active Weapon')
   else printxy(163,37,'Target Shield');
 printxy(175,54,'Range');
 printxy(163,61,'Max Energy');
 printxy(173,68,'Damage');
 printxy(163,75,'Cargo Size');
 printxy(194,87,'P');
 printxy(194,93,'P');
 printxy(193,99,'I');
 printxy(194,105,'E');
end;

procedure displayweaponstats(weap: integer);
var str1: string[5];
begin
 tcolor:=31;
 if weap>0 then printxy(174,45,cargo[weap].name)
  else printxy(174,45,cargo[58].name);
 if weap>0 then
  begin
   str((weapons[weap].range div 1000):3,str1);
   printxy(228,54,str1+' KKM  ');
   str(weapons[weap].energy:5,str1);
   printxy(218,61,str1+' GW   ');
   str(weapons[weap].damage:4,str1);
   printxy(223,68,str1+' GJ   ');
   j:=1;
   while cargo[j].index<>(weap+ID_DIRK-1)
    do inc(j);
   if j<114 then
    begin
     i:=cargo[j].size div 10;
     str(i:5,str1);
     printxy(218,75,str1+' Cu.M');
    end;
    for j:=1 to 4 do
     begin
      y:=round(weapons[weap].dmgtypes[j]*0.66);
      for i:=-2 to 3 do
       begin
        if i>0 then x:=100-i
         else x:=100+i;
        scr_fillchar(screen[83+i+j*6,205],y,x);
        if y<66 then
         scr_fillchar(screen[83+i+j*6,205+y],66-y,0);
       end;
     end;
  end
 else
  begin
   printxy(218,54,'       None');
   printxy(218,61,'       None');
   printxy(218,68,'       None');
   printxy(218,75,'       None');
   for i:=87 to 110 do
    scr_fillchar(screen[i,205],66,2);
  end;
end;

procedure getweaponicons(x1,y1,weap,node: integer);
var j: integer;
begin;
 b:=-1;
 for j:=1 to 3 do
  if (ship.engrteam[j].job>=ID_DIRK) and (ship.engrteam[j].job<ID_NOSHIELD-1) and
    (ship.engrteam[j].jobtype=JOBTYPE_INSTALL) and ((ship.engrteam[j].extra and 15)=node) then
   begin
    for i:=0 to 19 do
     scr_fillchar(screen[y1+i,x1],20,84);
    exit;
   end;
 if weap=0 then
  begin
   for i:=0 to 19 do
    scr_fillchar(screen[y1+i,x1],20,5);
   exit;
  end;
 b:=1;
 readweaicon(weap-1);
end;

procedure showweaponicon(x1,y1,weap,node: integer);
begin
 getweaponicons(x1,y1,weap,node);
 if b<0 then exit;
 for i:=0 to 19 do
  scrto_move(tempicon^[i],screen[y1+i,x1],5*4);
end;

procedure sideshowweaponicon(x1,y1,weap,node: integer);
var j: integer;
begin
 getweaponicons(x1,y1,weap,node);
 if b<0 then exit;
 for i:=0 to 19 do
  for j:=0 to 19 do
   screen[y1+j,x1+i]:=tempicon^[i,j];
end;

procedure backshowweaponicon(x1,y1,weap,node: integer);
var j: integer;
begin
 getweaponicons(x1,y1,weap,node);
 if b<0 then exit;
 for i:=0 to 19 do
  for j:=0 to 19 do
   screen[y1+j,x1+19-i]:=tempicon^[i,j];
end;

procedure revshowweaponicon(x1,y1,weap,node: integer);
begin
 getweaponicons(x1,y1,weap,node);
 if b<0 then exit;
 for i:=0 to 19 do
  scrto_move(tempicon^[19-i],screen[y1+i,x1],5*4);
end;

procedure displayweaponinfo(com: integer);
begin
 tcolor:=191;
 bkcolor:=5;
 mousehide;
 case com of
  0:;
  1: if viewlevel=1 then
      begin
       printxy(168,27,'Gun Node Information');
       viewlevel:=0;
       for i:=37 to 114 do
        scr_fillchar(screen[i,166],113,5);
       screen[52,165]:=10;
       screen[82,165]:=10;
       screen[53,279]:=2;
       screen[83,279]:=2;
      end;
  2: if (viewlevel=0) and (viewindex>0) then
      begin
       setupweaponinfo;
       showweaponicon(172,89,ship.gunnodes[viewindex],viewindex);
       printxy(165,27,' Weapons Information ');
       viewlevel:=1;
      end;
  3: if viewindex>0 then
      begin
       dec(viewindex);
       while (viewindex>0) and (ship.gunnodes[viewindex]=0) do dec(viewindex);
       if viewindex=0 then
        begin
         viewindex:=10;
         while (viewindex>0) and (ship.gunnodes[viewindex]=0) do dec(viewindex);
        end;
       if (viewlevel=1) and (viewindex>0) then showweaponicon(172,89,ship.gunnodes[viewindex],viewindex);
      end;
  4: if viewindex>0 then
      begin
       inc(viewindex);
       while (viewindex<11) and (ship.gunnodes[viewindex]=0) do inc(viewindex);
       if viewindex=11 then
        begin
         viewindex:=1;
         while (viewindex<11) and (ship.gunnodes[viewindex]=0) do inc(viewindex);
         if viewindex=11 then viewindex:=0;
        end;
       if (viewlevel=1) and (viewindex>0) then showweaponicon(172,89,ship.gunnodes[viewindex],viewindex);
      end;
  5: begin
      removerightside(true);
      mouseshow;
      exit;
     end;
 end;
 case viewlevel of
  0: begin
      y:=1;
      for j:=1 to 10 do
       begin
        if viewindex=j then bkcolor:=179 else bkcolor:=5;
        if ship.gunnodes[j]>0 then
         begin
          printxy(167,31+7*y,cargo[ship.gunnodes[j]].name);
          inc(y);
         end;
       end;
     end;
  1: displayweaponstats(ship.gunnodes[viewindex]);
 end;
 mouseshow;
 bkcolor:=3;
end;

function checkscandamages: boolean;
begin
 if ship.damages[DMG_CPU]>59 then
  begin
   mousehide;
   a:=glowindex mod 2;
   for i:=0 to 52 do
    begin
     for j:=28 to 142 do
      screen[i*2+18+a,j]:=random(16);
     scr_fillchar(screen[i*2+19-a,28],115,5);
    end;
   mouseshow;
   checkscandamages:=false;
  end
 else if ship.damages[DMG_CPU]>(20+random(40)) then
  begin
   mousehide;
   a:=glowindex mod 2;
   for i:=0 to 52 do
    begin
     for j:=28 to 142 do
      screen[i*2+18+a,j]:=random(16);
     scr_fillchar(screen[i*2+19-a,28],115,5);
    end;
   mouseshow;
   checkscandamages:=false;
  end
 else checkscandamages:=true;
end;

procedure displaystarmap;
begin
 if (ship.damages[DMG_CPU]>0) and (not checkscandamages) then exit;
 fillchar(starmapscreen^,sizeof(templatetype2),5);
 if t1<0 then t1:=0;
 t1:=t1+0.049;
 if t1>6.28 then
  begin
   t1:=t1-6.28;
   move(nearbybackup,nearby,sizeof(nearbyarraytype));
  end;
 for j:=1 to nearbymax do if nearby[j].index<>0 then
  begin
   x1:=nearby[j].x;
   y1:=nearby[j].z;
   nearby[j].x:=(0.99879974)*x1-(0.048980394)*y1;
   nearby[j].z:=(0.048980394)*x1+(0.99879974)*y1;
   x1:=85+(nearby[j].x*480/(500-nearby[j].z));
   y1:=70+(nearby[j].y*480/(500-nearby[j].z));
   x:=round(x1);
   y:=round(y1);
   case systems[nearby[j].index].mode of
    1: begin c1:=127; c2:=118; end;
    2: begin c1:=95; c2:=86; end;
    3: begin c1:=31; c2:=12; end;
   end;
   starmapscreen^[y,x]:=c1;
   starmapscreen^[y+1,x]:=c2; {12,169,170}
   starmapscreen^[y-1,x]:=c2;
   starmapscreen^[y,x+1]:=c2;
   starmapscreen^[y,x-1]:=c2;
  end;
 mousehide;
 for i:=18 to 123 do
  scrto_move(starmapscreen^[i,27],screen[i,27],29*4);
 if target>0 then
  begin
   if index<0 then index:=0;
   if index>7 then index:=0 else inc(index);
   x1:=85+(nearby[target].x*480/(500-nearby[target].z));
   y1:=70+(nearby[target].y*480/(500-nearby[target].z));
   x:=round(x1);
   y:=round(y1);
   setcolor(80+index);
   circle(x,y,6);
  end;
 mouseshow;
end;

{ shows quick ship stats: hull/primary/secondary/shield right-side display }
procedure displaystatus;
var part: real;
    str1: string[5];
    oldt,c: integer;
begin
 oldt:=tcolor;
 tcolor:=191;
 bkcolor:=255;
 a:=round(ship.hullintegrity/ship.hullmax*98);
 mousehide;
 if a=0 then part:=0 else part:=31/a;
 for j:=0 to a do
  begin
   c:=round(j*part);
   for i:=46 to 54 do
    screen[i,j+173]:=c;
  end;
 if a<98 then
  for i:=46 to 54 do
   scr_fillchar(screen[i,174+a],98-a,0);
 str(ship.hullintegrity,str1);
 printxy(219-round(length(str1)*2.5),47,str1);
 a:=round(ship.fuel/ship.fuelmax*98);
 if a=0 then part:=0 else part:=31/a;
 for j:=0 to a do
  begin
   c:=round(j*part);
   for i:=66 to 74 do
    screen[i,j+173]:=c;
  end;
 if a<98 then
  for i:=66 to 74 do
   scr_fillchar(screen[i,174+a],98-a,0);
 str(ship.fuel,str1);
 printxy(219-round(length(str1)*2.5),67,str1);
 a:=round(ship.battery/32000*98);
 if a=0 then part:=0 else part:=31/a;
 for j:=0 to a do
  begin
   c:=round(j*part);
   for i:=86 to 94 do
    screen[i,j+173]:=c;
  end;
 if a<98 then
  for i:=86 to 94 do
   scr_fillchar(screen[i,174+a],98-a,0);
 str(ship.battery,str1);
 printxy(219-round(length(str1)*2.5),87,str1);
 a:=round(ship.shieldlevel/100*98);
 if a=0 then part:=0 else part:=31/a;
 for j:=0 to a do
  begin
   c:=round(j*part);
   for i:=106 to 114 do
    screen[i,j+173]:=c;
  end;
 if a<98 then
  for i:=106 to 114 do
   scr_fillchar(screen[i,174+a],98-a,0);
 str(ship.shieldlevel,str1);
 printxy(219-round(length(str1)*2.5),107,str1);
 mouseshow;
 bkcolor:=3;
 tcolor:=oldt;
end;

procedure genericsysinfo(n: integer);
var str1,str2,str3: string[4];
    str4: string[7];
    z1,r: real;
begin
 x:=systems[n].x;
 y:=systems[n].y;
 z:=systems[n].z;
 x1:=x/10;
 y1:=y/10;
 z1:=z/10;
 str(x1:3:0,str1);
 str(y1:3:0,str2);
 str(z1:3:0,str3);
 x:=x-ship.posx;
 y:=y-ship.posy;
 z:=z-ship.posz;
 r:=sqr(x/10)+sqr(y/10)+sqr(z/10);
 r:=sqrt(r);
 if r=0 then str4:='  0.00'
  else str(r:6:2,str4);
 printxy(167,37,'Location');
 printxy(214,37,str1+','+str2+','+str3);
 printxy(167,43,'Distance');
 printxy(164,49,'Star Type');
 printxy(162,55,'Last Visit');
 printxy(172,61,'Visits');
 printxy(169,67,'Planets');
 printxy(172,73,'Sector');
 printxy(163,83,'Notes:');
 printxy(239,43,str4);
 case systems[n].mode of
  1: printxy(215,49,' Earth Type');
  2: printxy(215,49,'  Red Giant');
  3: printxy(215,49,'White Dwarf');
 end;
 if systems[n].datey=0 then printxy(230,55,'   Never')
 else
  begin
   str(systems[n].datem:2,str1);
   if str1[1]=' ' then str1[1]:='0';
   str(systems[n].datey:5,str4);
   if systems[n].datey<10000 then str4[1]:='0';
   printxy(230,55,str1+'/'+str4);
  end;
 if systems[n].visits=0 then printxy(250,61,'None')
 else
  begin
   str(systems[n].visits:3,str1);
   printxy(255,61,str1);
  end;
 if systems[n].visits>0 then
  begin
   i:=systems[n].numplanets-1;
   str(i:3,str1);
   printxy(255,67,str1);
  end
  else
   printxy(235,67,'Unknown');
 j:=1;
 if systems[n].x>1250 then j:=j+1;
 if systems[n].y>1250 then j:=j+2;
 if systems[n].z>1250 then j:=j+4;
 case j of
  1: str4:='  ALPHA';
  2: str4:='   BETA';
  3: str4:='  GAMMA';
  4: str4:='  DELTA';
  5: str4:='EPSILON';
  6: str4:='   ZETA';
  7: str4:='    ETA';
  8: str4:='  THETA';
 end;
 printxy(270-length(str4)*5,73,str4);
 setcolor(2);
 line(217,37,217,79);
 line(166,80,278,80);
 setcolor(10);
 line(218,37,218,79);
 line(166,81,278,81);
 screen[36,217]:=6;
 screen[80,165]:=6;
 screen[80,218]:=6;
 screen[81,279]:=6;
end;

procedure displaysysteminfo(com: integer);
var str4: string[6];
    r: real;
    y2: integer;
begin
 mousehide;
 if (target=0) and (viewlevel=1) then com:=1;
 case com of
   0:;
   1:if viewlevel>0 then
      begin
       for i:=37 to 114 do
        scr_fillchar(screen[i,166],113,5);
       screen[80,165]:=10;
       screen[81,279]:=2;
       screen[36,217]:=10;
       dec(viewlevel);
       tcolor:=191;
       bkcolor:=5;
       printxy(166,27,'  System        Dist');
      end;
   2:if (viewlevel=0) and (target>0) then
      begin
       inc(viewlevel);
       for i:=37 to 114 do
        scr_fillchar(screen[i,166],113,5);
       tcolor:=191;
       bkcolor:=5;
       printxy(166,27,' System Information ');
      end;
   3: if target>0 then
       begin
        if target=1 then
         begin
          target:=nearbymax+1;
          repeat
           dec(target);
          until nearby[target].index<>0;
         end
        else dec(target);
        if viewlevel=1 then
         for i:=37 to 114 do
          scr_fillchar(screen[i,166],113,5);
       end
      else target:=1;
   4: if target>0 then
       begin
        inc(target);
        if (target>nearbymax) or (nearby[target].index=0) then target:=1;
        if viewlevel=1 then
         for i:=37 to 114 do
          scr_fillchar(screen[i,166],113,5);
       end
      else target:=1;
   5: begin
       removerightside(true);
       mouseshow;
       exit;
      end;
   6: if target>0 then
       begin
        readytarget;
        readysysteminfo;
       end;
   7: if targetready then
       begin
        mouseshow;
        engage(systems[nearby[target].index].x,systems[nearby[target].index].y,systems[nearby[target].index].z);
        exit;
       end;
   8: begin
       mouseshow;
       if yesnorequest('Print all planet info?',0,31) then printinfo;
       mousehide;
      end;
  end;
 tcolor:=191;
 bkcolor:=5;
 case viewlevel of
  0: begin
      if target=0 then target:=1;
      index:=target+1;
      y:=7;
      repeat
       if nearby[index].index>0 then
        begin
         inc(y);
         if target=index then bkcolor:=179 else bkcolor:=5;
         x:=systems[nearby[index].index].x;
         y2:=systems[nearby[index].index].y;
         z:=systems[nearby[index].index].z;
         x:=x-ship.posx;
         y2:=y2-ship.posy;
         z:=z-ship.posz;
         r:=sqr(x/10)+sqr(y2/10)+sqr(z/10);
         r:=sqrt(r);
         str(r:6:2,str4);
         printxy(163,31+y*6,systems[nearby[index].index].name);
         if r>ship.fuel then tcolor:=16 else tcolor:=31;
         bkcolor:=5;
         printxy(239,31+y*6,str4);
         tcolor:=191;
        end;
        inc(index);
      until (index>nearbymax) or (y=13);
      if y<13 then
       for j:=38+y*6 to 116 do
        scr_fillchar(screen[j,166],113,5);
      index:=target;
      y:=8;
      repeat
       if nearby[index].index>0 then
        begin
         dec(y);
         if target=index then bkcolor:=179 else bkcolor:=5;
         x:=systems[nearby[index].index].x;
         y2:=systems[nearby[index].index].y;
         z:=systems[nearby[index].index].z;
         x:=x-ship.posx;
         y2:=y2-ship.posy;
         z:=z-ship.posz;
         r:=sqr(x/10)+sqr(y2/10)+sqr(z/10);
         r:=sqrt(r);
         str(r:6:2,str4);
         printxy(163,31+y*6,systems[nearby[index].index].name);
         if r>ship.fuel then tcolor:=16 else tcolor:=31;
         bkcolor:=5;
         printxy(239,31+y*6,str4);
         tcolor:=191;
        end;
        dec(index);
      until (index<1) or (y=1);
      if y>1 then
       for j:=37 to 31+y*6 do
        scr_fillchar(screen[j,166],113,5);
     end;
  1: genericsysinfo(nearby[target].index);
  end;
 mouseshow;
 bkcolor:=3;
end;


{ colors dpg/pwr/aux/shd status buttons (at top far right), and updates Alert status ALERT<->REST depending on subsystems damage }
procedure checkstats;
begin
 if alert<ALRT_COMBAT then	{ if we not in COMBAT mode, automatically put us ALERT mode if damaged, or REST mode if not }
  begin
   i:=ALRT_REST;
   for j:=1 to 7 do if ship.damages[j]<>0 then i:=ALRT_ALERT;
   setalertmode(i, true);
  end;
 if ship.hullintegrity<250 then tc:=80
  else if ship.hullintegrity<500 then tc:=112
  else tc:=48;
 if statcolors[1]<>tc then colorarea(300,29,313,39,tc,1);
 a:=round(ship.fuel/ship.fuelmax*100);
 if a<26 then tc:=80
  else if a<51 then tc:=112
  else tc:=48;
 if statcolors[2]<>tc then colorarea(300,49,313,59,tc,2);
 a:=round(ship.battery/batmax*100);
 if a<26 then tc:=80
  else if a<51 then tc:=112
  else tc:=48;
 if statcolors[3]<>tc then colorarea(300,69,313,79,tc,3);
 if ship.shieldlevel<26 then tc:=80
  else if ship.shieldlevel<51 then tc:=112
  else tc:=48;
 if statcolors[4]<>tc then colorarea(300,89,313,99,tc,4);
end;

procedure genericplanetinfo;
var s: string[7];
    str1: string[20];
    str4: string[11];
    techlvl: integer;
begin
 printxy(167,37,'Location');
 printxy(177,43,'Size');
 printxy(174,49,'State');
 printxy(167,55,'Lastdate');
 printxy(173,61,'Visits');
 printxy(178,67,'Bots');
 j:=findfirstplanet(viewindex);
 a:=j;
 while tempplan^[a].orbit<>viewindex2 do inc(a);
 tcolor:=61;
 printplanet(229,37,viewindex,a-j);
 tcolor:=191;
 if tempplan^[a].visits>0 then
  begin
   if tempplan^[a].orbit=0 then
    case tempplan^[a].mode of
     1: s:='  Giant';
     2: s:='  Large';
     3: s:='   Tiny';
    end
   else
    case tempplan^[a].psize of
     0: s:='   Tiny';
     1: s:='  Small';
     2: s:=' Medium';
     3: s:='  Large';
     4: s:='  Giant';
    end;
  end
 else s:='Unknown';
 printxy(234,43,s);
 if tempplan^[a].visits>0 then
  case tempplan^[a].state of
   0: s:='Gaseous';
   1: s:=' Active';
   2: s:=' Stable';
   3: s:='Ea.Life';
   4: s:='Ad.Life';
   5: s:='  Dying';
   6: s:='   Dead';
   7: s:='   Star';
  end else s:='Unknown';
 printxy(234,49,s);
 if tempplan^[a].datey=0 then printxy(229,55,'   Never')
 else
  begin
   str(tempplan^[a].datem:2,str1);
   if str1[1]=' ' then str1[1]:='0';
   str(tempplan^[a].datey:5,str4);
   if tempplan^[a].datey<10000 then str4[1]:='0';
   printxy(229,55,str1+'/'+str4);
  end;
 if tempplan^[a].visits=0 then printxy(249,61,'None')
 else
  begin
   str(tempplan^[a].visits:4,str4);
   printxy(249,61,str4);
  end;
 if (tempplan^[a].bots and 7)=0 then printxy(234,67,'   None')
  else if (tempplan^[a].bots and 7)=1 then printxy(234,67,'Minebot')
  else if (tempplan^[a].bots and 7)=2 then printxy(234,67,'Factory')
  else if (tempplan^[a].bots and 7)=4 then printxy(234,67,'Fabrctr')
  else if (tempplan^[a].bots and 7)=5 then printxy(234,67,'Strmine');
 if tempplan^[a].orbit>0 then
  begin
   j:=0;
   for i:=1 to 7 do if tempplan^[a].cache[i]>0 then inc(j);
   printxy(167,78,'Cache = '+chr(j+48)+'/7')
  end
 else printxy(167,78,'           ');
 if (tempplan^[a].notes and 1>0) and (tempplan^[a].orbit>0) then
  printxy(167,84,'Scans Complete  ')
 else if tempplan^[a].orbit=0 then
  printxy(167,84,'                ')
 else printxy(167,84,'Scans Incomplete');
 str4[0]:=chr(11);
 fillchar(str4[1],11,ord(' '));
 str1[0]:=chr(20);
 fillchar(str1[1],20,ord(' '));
 if (tempplan^[a].notes and 2>0) or (tempplan^[a].notes and 32>0) then
  begin
   case tempplan^[a].system of
     93: str1:='Sengzhac            ';
    138: str1:='D''phak             ';
     45: if not chevent(27) then str1:='Ermigen             ';
    221: str1:='Titarian            ';
     78: str1:='Quai Pa''loi         ';
    171: str1:='Icon                ';
    191: str1:='The Guild           ';
   else if (tempplan^[a].state=6) and (tempplan^[a].mode=2) then str1:='Void Dwellers       '
   else
    begin
     techlvl:=-2;
     case tempplan^[a].state of
      2: case tempplan^[a].mode of
          2: techlvl:=-1;
          3: techlvl:=0;
         end;
      3: techlvl:=tempplan^[a].mode-1;
      4: techlvl:=tempplan^[a].mode+2;
      5: case tempplan^[a].mode of
          1: techlvl:=0;
          2: techlvl:=-1;
         end;
     end;
     case techlvl of
      -2: str1:='No Life             ';
      -1: begin
           randseed:=tempplan^[a].seed;
           j:=random(word(tempplan^[a].state+tempplan^[a].mode+tempplan^[a].seed)) mod 3;
           case j of
            0: if random(2)=0 then str1:='Short Chain Proteins'
                else str1:='Long Chain Proteins ';
            1: if random(2)=0 then str1:='Simple Protoplasms  '
                else str1:='Complex Protoplasms ';
            2: begin
                case random(3) of
                 0: str4:='Chaosms    ';
                 1: str4:='Communes   ';
                 2: str4:='Heirarchies';
                end;
                str1:='Singlecelled        ';
               end;
           end;
          end;
    0..5: begin
           randseed:=tempplan^[a].seed;
           str4:=alientypes[random(11)];
           case random(5) of
            0: str1:='Carnivorous         ';
            1: str1:='Herbivorous         ';
            2: str1:='Omnivorous          ';
            3: str1:='Cannibalistic       ';
            4: str1:='Photosynthetic      ';
           end;
          end;
     end;
    end;
   end;
  end;
 printxy(167,90,str1);
 printxy(170,96,str4);
 if tempplan^[a].notes and 2>0 then
  printxy(167,104,'Contact Established')
 else
  for i:=104 to 110 do
   scr_fillchar(screen[i,171],95,5);
 setcolor(2);
 line(217,37,217,73);
 line(165,74,278,74);
 setcolor(10);
 line(218,37,218,73);
 line(166,75,279,75);
 screen[74,218]:=6;
 screen[75,279]:=6;
 screen[36,217]:=6;
 screen[74,165]:=6;
end;

procedure displaylogs(com: integer);
var done: boolean;

 function testmode(index: word): boolean;
 begin
  assert ((index>=1) and (index<=1000), 'testmode index out of range');
  testmode:=false;
  if (systems[index].visits=0) then exit;
  case viewindex3 of
   0: testmode:=true;					{ ALL Systems }
   1: begin						{ with Cache ONLY }
       a:=findfirstplanet(index);
       for j:=1 to systems[index].numplanets do
        for b:=1 to 7 do
         if tempplan^[j+a].cache[b]>0 then
          begin
           testmode:=true;
           exit;
          end;
      end;
   2: begin						{ with Contacts ONLY }
       a:=findfirstplanet(index);
       for j:=1 to systems[index].numplanets do
         if tempplan^[j+a].notes and 2>0 then
          begin
           testmode:=true;
           exit;
          end;
      end;
   3: begin						{ WITHOUT ALL completed Scans }
       a:=findfirstplanet(index);
       for j:=1 to systems[index].numplanets do
         if (tempplan^[j+a].notes and 254=0) and (tempplan^[j+a].orbit<>0) then
          begin
           testmode:=true;
           exit;
          end;
      end;
  end;
 end;

begin
 mousehide;
 tcolor:=191;
 bkcolor:=5;
 case com of
  0:;
  1: if (viewindex>0) and (viewlevel>0) then	{ left }
      begin
       dec(viewlevel);
       if viewlevel=0 then
        begin
         bkcolor:=5;
         tcolor:=191;
         case viewindex3 of
          0: printxy(166,27,' Ship Logs: Systems  ');
          1: printxy(166,27,' Ship Logs: Cache    ');
          2: printxy(166,27,' Ship Logs: Contacts ');
          3: printxy(166,27,' Ship Logs: Scans    ');
         end;
         showpanel(logbut2);
        end;
       for i:=37 to 114 do
        scr_fillchar(screen[i,166],113,5);
       screen[80,165]:=10;
       screen[81,279]:=2;
       screen[74,165]:=10;
       screen[75,279]:=2;
       screen[36,217]:=10;
      end;
  2: if (viewindex>0) and (viewlevel<3) then	{ right }
      begin
       if viewlevel=0 then
        begin
         viewindex2:=0;
         showpanel(logbut1);
        end;
       inc(viewlevel);
       for i:=37 to 114 do
        scr_fillchar(screen[i,166],113,5);
       screen[80,165]:=10;
       screen[81,279]:=2;
       screen[74,165]:=10;
       screen[75,279]:=2;
       screen[36,217]:=10;
      end;
  3: if viewlevel<2 then			{ up }
      begin
       viewindex2:=0;
       dec(viewindex);
       while (viewindex>0) and (not testmode(viewindex)) do dec(viewindex);
       if viewindex<=0 then
        begin
         viewindex:=250;
         while (viewindex>0) and (not testmode(viewindex)) do dec(viewindex);
        end;
        assert (viewindex>=0, 'viewindex has gone negative1');
        assert (viewindex<251, 'viewindex is too big1');
      end else
      begin
       j:=findfirstplanet(viewindex);
       done:=false;
       repeat
        if viewindex2=0 then viewindex2:=7 else dec(viewindex2);
        for i:=0 to 7 do
         if (tempplan^[j+i].orbit=viewindex2) and (tempplan^[j+i].system=viewindex) then done:=true;
       until done;
      end;
  4: if viewlevel<2 then			{ down }
      begin
       viewindex2:=0;
       inc(viewindex);
       assert (viewindex>=0, 'viewindex has gone negative2');
       while (viewindex<251) and (not testmode(viewindex)) do inc(viewindex);
       if viewindex>250 then
        begin
         viewindex:=0;
         inc(viewindex);
         while (viewindex<251) and (not testmode(viewindex)) do inc(viewindex);
         if viewindex=251 then viewindex:=0;
        end;
        assert (viewindex<251, 'viewindex is too big2');
       end
     else
      begin
       j:=findfirstplanet(viewindex);
       done:=false;
       repeat
        if viewindex2=7 then viewindex2:=0 else inc(viewindex2);
        for i:=0 to 7 do
         if (tempplan^[j+i].orbit=viewindex2) and (tempplan^[j+i].system=viewindex) then done:=true;
       until done;
      end;
  5: begin
      removerightside(true);
      mouseshow;
      exit;
     end;
  6: begin					{ '1' }
      if (viewindex>0) and (viewlevel<>3) then
       begin
        if viewlevel=0 then
         begin
          viewindex2:=0;
          showpanel(logbut1);
         end;
        for i:=37 to 114 do
         scr_fillchar(screen[i,166],113,5);
        screen[80,165]:=10;
        screen[81,279]:=2;
        screen[74,165]:=10;
        screen[75,279]:=2;
        screen[36,217]:=10;
       end;
      viewlevel:=3;
     end;
  7: if showplanet then viewindex:=tempplan^[curplan].system;	{ '2' }
  8: if viewlevel=0 then			{ '3' }
      begin
       if viewindex3<3 then inc(viewindex3) else viewindex3:=0;
       case viewindex3 of
        0: printxy(166,27,' Ship Logs: Systems  ');
        1: printxy(166,27,' Ship Logs: Cache    ');
        2: printxy(166,27,' Ship Logs: Contacts ');
        3: printxy(166,27,' Ship Logs: Scans    ');
       end;
      end;
 end;

 if viewindex = 0 then		{ scrolling through empty lists or some similar action has destroyed our position. Reset to current system so SOMETHING gets displayed }
  if showplanet then viewindex:=tempplan^[curplan].system else viewindex:=1;

 case viewlevel of
  0: if viewindex>0 then	{ viewlevel=0 is a scrollable list of systems, filtered by testmode(index) using viewindex3 (0=no filter, 1=cache, 2=contacts, 3=scans) }
      begin			{ viewindex is index in systems[], of currently selected system in list, modified above by com=3(up)/4(down) }
       { firstly, print all systems AFTER our selected system }
       index:=viewindex+1;
       y:=7;			{ y is middle row on screen for printxy(163, 31+y*6, system[index].name) }
       repeat
        if (index <= 250) and testmode(index) then	{ if this is the system we need to display, eg. it matches filter }
         begin
          inc(y);
          if viewindex=index then bkcolor:=179 else bkcolor:=5;
          assert ((index >=1) and (index <= 250), 'system index out of range1');
          printxy(163,31+y*6,systems[index].name)
         end;
         inc(index);
       until (index>250) or (y=13);
       if y<13 then
        for j:=38+y*6 to 116 do
         scr_fillchar(screen[j,166],113,5);

       { secondly, print our selected system (in different color), and all systems BEFORE it in normal color }
       index:=viewindex;
       y:=8;
       repeat
        if testmode(index) then
         begin
          dec(y);
          if viewindex=index then bkcolor:=179 else bkcolor:=5;
          assert ((index >=1) and (index <= 250), 'system index out of range2');
          printxy(163,31+y*6,systems[index].name)
         end;
         dec(index);
       until (index<1) or (y=1);
       if y>1 then
        for j:=37 to 31+y*6 do
         scr_fillchar(screen[j,166],113,5);
      end;
  1: begin
      printxy(166,27,'Ship Logs:System Info');
      genericsysinfo(viewindex);
     end;
  2: begin
      printxy(166,27,' Ship Logs: Planets  ');
      j:=findfirstplanet(viewindex);
      i:=0;
      repeat
       if viewindex2=tempplan^[j].orbit then setcolor(90) else setcolor(16);
       circle(222,75,tempplan^[j].orbit*6);
       inc(j);
       inc(i);
       assert ((viewindex >=1) and (viewindex <= 250), 'system index out of range3');
      until i=systems[viewindex].numplanets;
     end;
  3: begin
      printxy(166,27,'Ship Logs:Planet Info');
      genericplanetinfo;
     end;
  end;
 mouseshow;
 bkcolor:=3;
end;

procedure displaysystem(com: integer);
var
    x,z,ang: real;
    s: string[7];
    str1: string[20];
    str4: string[11];
begin
 tcolor:=191;
 bkcolor:=5;
 c:=viewindex;
 case com of
  0:;
  1: begin
      if viewindex=0 then viewindex:=systems[viewindex2].numplanets-1
       else dec(viewindex);
      printplanet(233,108,viewindex2,viewindex);
     end;
  2: begin
      inc(viewindex);
      if viewindex=systems[viewindex2].numplanets then viewindex:=0;
      printplanet(233,108,viewindex2,viewindex);
     end;
  3..4:;
  5: begin
      removesystem(true);
      exit;
     end;
  6: if not chevent(11) then
      begin
       tcolor:=94;
       bkcolor:=3;
       println;
       print('SCIENCE: Sir, that would not be wise. I suggest we first scan this planet.');
       bkcolor:=5;
      end else
      begin
	 {removesystem(true);
	 planettravel(viewindex2, viewindex);}
	  j:=findfirstplanet(viewindex2)+viewindex;
	  curplan:=j;
	  if tempplan^[j].visits<255 then inc(tempplan^[j].visits);

        tempplan^[j].datey:=ship.stardate[3];
        tempplan^[j].datem:=ship.stardate[1];
        ship.orbiting:=viewindex;
        removesystem(true);
        mousehide;
        compressfile(loc_tmp()+'current',@screen);
        scr_fillchar(screen,sizeof(screen),0);
        mouseshow;
        for j:=1 to random(40)+60 do addlotstime(false, true, 100+random(100));
        {fading;}
	fadefull(-FADEFULL_STEP, FADEFULL_DELAY);
        mousehide;
        loadscreen(loc_tmp()+'current',@screen);
        mouseshow;
        if viewindex>0 then readyplanet else readystar;
        checkwandering;
        exit;
       end;
   7: if (viewlevel and 1=0) then inc(viewlevel)
       else
        begin
         dec(viewlevel);
         mousehide;
         for i:=37 to 74 do
          scr_fillchar(screen[i,166],113,5);
         mouseshow;
        end;
   8: if viewlevel<2 then inc(viewlevel,2)
       else
        begin
         dec(viewlevel,2);
         mousehide;
         for i:=37 to 74 do
          scr_fillchar(screen[i,166],113,5);
         mouseshow;
        end;
 end;
 if index<0 then index:=0;
 if index>7 then index:=0 else inc(index);
 if viewlevel and 2>0 then
  begin
   t1:=t1+0.0025;
   if t1>6.28 then t1:=t1-6.28;
  end;
 y:=0;
 j:=findfirstplanet(viewindex2);
 setcolor(5);
 mousehide;
 circle(cx,cy,6);
 setcolor(80+index);
 repeat
  i:=tempplan^[j].seed mod 628;
  if (i=0) or (i=314) or (i=157) or (i=471) then inc(i);
  t2:=i/100;
  x:=cos(t2)*tempplan^[j].orbit;
  z:=sin(t2)*tempplan^[j].orbit;
  if (z<>0) and (x<>0) then
   begin
    ar:=(x/sin(arctan(x/z)))*14;
    br:=ar*5/14;
    t2:=arctan(z/(2*x));
    ang:=t2+t1*(8-tempplan^[j].orbit);
    x1:=142+cos(ang)*ar;
    y1:=65+sin(ang)*br;
   end
  else
   begin
    x1:=142;
    y1:=65;
   end;
  randseed:=tempplan^[j].seed;
  case tempplan^[j].state of
   0: case tempplan^[j].mode of
         1: a:=random(3)*10;
       2,3: case tempplan^[j].psize of
             0,1: a:=170;
             2,3: a:=random(3)*10+250;
               4: a:=random(2)*10+150;
            end;
      end;
   1..5: case tempplan^[j].psize of
          0,1: if tempplan^[j].water>25 then a:=180 else a:=190;
          2,3: a:=240-(tempplan^[j].water div 10)*10;
            4: a:=140-(tempplan^[j].water div 7)*10;
         end;
   6: if tempplan^[j].mode=1 then
       case tempplan^[j].psize of
        0,1: a:=180;
        2,3: a:=200;
          4: a:=80;
       end
       else a:=random(3)*10;
   7: case tempplan^[j].mode of
       1: a:=60;
       2: a:=50;
       3: a:=70;
      end;
   else a:=0;
  end;
  if viewindex=y then
   begin
    cx:=round(x1)+5;
    cy:=round(y1)+5;
    circle(cx,cy,6);
   end;
  for i:=0 to 9 do
   for b:=0 to 9 do
    if planicons^[i,a+b]<>0 then
     screen[round(y1)+i,round(x1)+b]:=planicons^[i,a+b];
  inc(j);
  inc(y);
 until (y=systems[viewindex2].numplanets);
 if viewlevel and 1>0 then
  begin
   printxy(167,37,'Location');
   printxy(177,43,'Size');
   printxy(174,49,'State');
   printxy(167,55,'Lastdate');
   printxy(173,61,'Visits');
   printxy(178,67,'Bots');
   a:=findfirstplanet(viewindex2)+viewindex;
   printplanet(229,37,viewindex2,viewindex);
   if tempplan^[a].visits>0 then
    begin
     if tempplan^[a].orbit=0 then
      case tempplan^[a].mode of
       1: s:='  Giant';
       2: s:='  Large';
       3: s:='   Tiny';
      end
     else
      case tempplan^[a].psize of
       0: s:='   Tiny';
       1: s:='  Small';
       2: s:=' Medium';
       3: s:='  Large';
       4: s:='  Giant';
      end;
    end
   else s:='Unknown';
   printxy(234,43,s);
   if tempplan^[a].visits>0 then
    case tempplan^[a].state of
     0: s:='Gaseous';
     1: s:=' Active';
     2: s:=' Stable';
     3: s:='Ea.Life';
     4: s:='Aa.Life';
     5: s:='  Dying';
     6: s:='   Dead';
     7: s:='   Star';
    end else s:='Unknown';
   printxy(234,49,s);
   if tempplan^[a].datey=0 then printxy(229,55,'   Never')
   else
    begin
     str(tempplan^[a].datem:2,str1);
     if str1[1]=' ' then str1[1]:='0';
     str(tempplan^[a].datey:5,str4);
     if tempplan^[a].datey<10000 then str4[1]:='0';
     printxy(229,55,str1+'/'+str4);
    end;
   if tempplan^[a].visits=0 then printxy(249,61,'None')
   else
    begin
     str(tempplan^[a].visits:4,str4);
     printxy(249,61,str4);
    end;
   if (tempplan^[a].bots and 7)=0 then printxy(234,67,'   None')
    else if (tempplan^[a].bots and 7)=1 then printxy(234,67,'Minebot')
    else if (tempplan^[a].bots and 7)=2 then printxy(234,67,'Factory')
    else if (tempplan^[a].bots and 7)=4 then printxy(234,67,'Fabrctr')
    else if (tempplan^[a].bots and 7)=5 then printxy(234,67,'Strmine');
  end;
 mouseshow;
 anychange:=true;
 bkcolor:=3;
end;


procedure targetplanet(xt,yt: integer);
var done: boolean;
    x,z,ang: real;
begin
 j:=findfirstplanet(viewindex2)+viewindex;
 mousehide;
 i:=tempplan^[j].seed mod 628;
 if (i=0) or (i=314) or (i=157) or (i=471) then inc(i);
 t2:=i/100;
 x:=cos(t2)*tempplan^[j].orbit;
 z:=sin(t2)*tempplan^[j].orbit;
 if (z<>0) and (x<>0) then
  begin
   ar:=(x/sin(arctan(x/z)))*14;
   br:=ar*5/14;
   t2:=arctan(z/(2*x));
   ang:=t2+t1*(8-tempplan^[j].orbit);
   x1:=142+cos(ang)*ar;
   y1:=65+sin(ang)*br;
  end
 else
  begin
   x1:=142;
   y1:=65;
  end;
 for i:=1 to 13 do
  scr_fillchar(screen[round(y1)-2+i,round(x1)-2],15,5);
 scr_fillchar(screen[round(y1)+12,round(x1)+3],5,5);
 mouseshow;
 j:=findfirstplanet(viewindex2);
 y:=-1;
 done:=false;
 repeat
  inc(y);
  i:=tempplan^[j].seed mod 628;
  t2:=i/100;
  x:=cos(t2)*tempplan^[j].orbit;
  z:=sin(t2)*tempplan^[j].orbit;
  if (z<>0) and (x<>0) then
   begin
    ar:=(x/sin(arctan(x/z)))*14;
    br:=ar*5/14;
    t2:=arctan(z/(2*x));
    ang:=t2+t1*(8-tempplan^[j].orbit);
    x1:=142+cos(ang)*ar;
    y1:=65+sin(ang)*br;
   end
  else
   begin
    x1:=142;
    y1:=65;
   end;
  inc(j);
  if (abs(x1-xt+5)<8) and (abs(y1-yt+5)<8) then done:=true;
 until (y=systems[viewindex2].numplanets) or (done);
 if done then
  begin
   tcolor:=191;
   bkcolor:=5;
   viewindex:=y;
   printplanet(233,108,viewindex2,y);
   bkcolor:=3;
  end;
end;

procedure loadshipdisplay2(index,x1,y1: integer);
var shipfile: file of shipdistype;
    temp: ^shipdistype;
    x2: integer;
begin
 new(temp);
 assign(shipfile,loc_data()+'shippix.dta');
 reset(shipfile);
 if ioresult<>0 then errorhandler('data/shippix.dta',1);
 seek(shipfile,index);
 if ioresult<>0 then errorhandler('data/shippix.dta',5);
 read(shipfile,temp^);
 if ioresult<>0 then errorhandler('data/shippix.dta',5);
 close(shipfile);
 case index div 3 of
  0: x2:=x1;
  1: x2:=58+x1;
  2: x2:=116+x1;
 end;
 for j:=x2 to x2+57 do
  for i:=0 to 74 do
   screen[y1+i,j]:=temp^[j-x2,i];
 dispose(temp);
end;

procedure displayship2(x1,y1: integer);
begin
 loadshipdisplay2(ship.shiptype[SHPTYP_HEAVYNESS]-1,x1,y1);
 loadshipdisplay2(2+ship.shiptype[SHPTYP_PURPOSE],x1,y1);
 loadshipdisplay2(5+ship.shiptype[SHPTYP_VESSEL],x1,y1);
end;

procedure displayshipinfo;
var str1,str2: string[5];
    cargo_used: word;
begin
 tcolor:=191;
 bkcolor:=5;
 mousehide;
 ar:=ship.posx/10;
 str(ar:5:1,str1);
 printxy(228,26,str1);
 ar:=ship.posy/10;
 str(ar:5:1,str1);
 printxy(228,32,str1);
 ar:=ship.posz/10;
 str(ar:5:1,str1);
 printxy(228,38,str1);
 str(ship.hullintegrity:4,str1);
 str(ship.hullmax:4,str2);
 printxy(223,44,str1+'/'+str2);
 str(ship.fuel:4,str1);
 str(ship.fuelmax:4,str2);
 printxy(223,50,str1+'/'+str2);
 str(ship.battery:5,str1);
 printxy(218,56,str1+'/32000');
 cargo_used:=0;
 for j:=1 to 250 do
  begin
   if ship.cargo[j]>ID_ARTIFACT_OFFSET then
    begin
     i:=maxcargo;
     getartifactname(ship.cargo[j]);
    end
   else if ship.cargo[j]>0 then
    begin
     i:=1;
     while cargo[i].index<>ship.cargo[j] do inc(i);
    end;
   if i<=maxcargo then cargo_used:=cargo_used+cargo[i].size*ship.numcargo[j];
  end;
 str(cargo_used:5,str1);
 str(ship.cargomax:4,str2);
 printxy(218,62,str1+'/'+str2+'0');

 str(ship.accelmax:4,str1);
 printxy(218,68,str1);
 for j:=1 to 7 do
  begin
   y:=round((100-ship.damages[j])*0.77);
   for i:=-1 to 2 do
    begin
     if i>0 then x:=100-i
      else x:=100+i;      {164}
     scr_fillchar(screen[74+7+i+j*4,197],y,x);
     if y<77 then
      scr_fillchar(screen[74+7+i+j*4,197+y],77-y,2);
    end;
  end;
 mouseshow;
 bkcolor:=3;
end;

procedure configcursor;
begin
 setcolor(90);
 case viewindex of
   1: rectangle(30,60,49,79);
   2: rectangle(65,29,84,48);
   3: rectangle(65,91,84,110);
   4: rectangle(108,29,127,48);
   5: rectangle(108,91,127,110);
   6: rectangle(150,29,169,48);
   7: rectangle(150,91,169,110);
   8: rectangle(128,60,147,79);
   9: rectangle(231,29,250,48);
  10: rectangle(231,91,250,110);
 end;
end;

{ check if this gunnode location exists in our ship }
function checkloc(l: integer): boolean;
begin
 checkloc:=false;
 case l of
   1: if ship.shiptype[SHPTYP_HEAVYNESS]<>SHPTYPE_HEAVY{1} then checkloc:=true;
   2,3: if ship.shiptype[SHPTYP_HEAVYNESS]<>SHPTYPE_LIGHT{2} then checkloc:=true;
   4,5: if ship.shiptype[SHPTYP_PURPOSE]<>SHPTYPE_SHUTTLE{1} then checkloc:=true;
   6,7: checkloc:=true;
   8: if ship.shiptype[SHPTYP_PURPOSE]<>SHPTYPE_ASSAULT{2} then checkloc:=true;
   9: if ship.shiptype[SHPTYP_VESSEL]<>SHPTYPE_TRANSPORT{1} then checkloc:=true;
  10: if ship.shiptype[SHPTYP_VESSEL]=SHPTYPE_CRUISER{3} then checkloc:=true;
 end;
end;

procedure findgunnode(x,y: integer);
begin
 case y of
   29..48: case x of
              65..85: i:=2;
            108..128: i:=4;
            150..170: i:=6;
            230..250: i:=9;
           end;
   60..79: case x of
              30..50: i:=1;
            128..148: i:=8;
           end;
  91..110: case x of
              65..85: i:=3;
            108..128: i:=5;
            150..170: i:=7;
            230..250: i:=10;
           end;
 end;
 if (i>0) and (checkloc(i)) then viewindex:=i;
end;

procedure displayconfigure(com: integer);
var str1: string[20];
begin
 tcolor:=191;
 bkcolor:=5;
 mousehide;
 if viewlevel=0 then configcursor;
 case com of
  1: if viewlevel=0 then
      begin
       repeat
        dec(viewindex);
        if viewindex<1 then viewindex:=10;
       until checkloc(viewindex);
      end;
  2: if viewlevel=0 then
      begin
       repeat
        inc(viewindex);
        if viewindex>10 then viewindex:=0;
       until checkloc(viewindex);
      end;
  3: if viewlevel=0 then
      begin
       inc(viewindex,5);
       viewindex:=viewindex div 10;
       repeat
        inc(viewindex);
        if viewindex>10 then viewindex:=0;
       until checkloc(viewindex);
      end
     else
      begin
       dec(viewindex2);
       while (viewindex2>0) and ((ship.cargo[viewindex2]<ID_DIRK) or (ship.cargo[viewindex2]>=ID_NOSHIELD)) do dec(viewindex2);
       if viewindex2<1 then
        begin
         viewindex2:=250;
         while (viewindex2>0) and ((ship.cargo[viewindex2]<ID_DIRK) or (ship.cargo[viewindex2]>=ID_NOSHIELD)) do dec(viewindex2);
        end;
      end;
  4: if viewlevel=0 then
      begin
       dec(viewindex,5);
       viewindex:=viewindex div 10;
       repeat
        inc(viewindex);
        if viewindex<1 then viewindex:=10;
       until checkloc(viewindex);
      end
     else
      begin
       inc(viewindex2);
       while (viewindex2<251) and ((ship.cargo[viewindex2]<ID_DIRK) or (ship.cargo[viewindex2]>=ID_NOSHIELD)) do inc(viewindex2);
       if viewindex2=251 then
        begin
         viewindex2:=1;
         while (viewindex2<251) and ((ship.cargo[viewindex2]<ID_DIRK) or (ship.cargo[viewindex2]>=ID_NOSHIELD)) do inc(viewindex2);
         if viewindex2=251 then viewindex2:=0;
        end;
      end;
  5: begin
      removesystem(true);
      mouseshow;
      exit;
     end;
  6: if viewlevel=1 then					{ install weapon }
      begin
       viewlevel:=0;
       for i:=26 to 114 do
        scr_fillchar(screen[i,16],263,5);
       screen[53,279]:=2;
       screen[83,279]:=2;
       screen[25,164]:=10;
       screen[115,165]:=2;
       showpanel(conbut);
       displayship2(60,33);
       if ship.shiptype[SHPTYP_HEAVYNESS]<>SHPTYPE_HEAVY{1} then graybutton(29,59,50,80);
       if ship.shiptype[SHPTYP_HEAVYNESS]<>SHPTYPE_LIGHT{2} then
         begin
          graybutton(64,28,85,49);
          graybutton(64,90,85,111);
         end;
       if ship.shiptype[SHPTYP_PURPOSE]<>SHPTYPE_SHUTTLE{1} then
         begin
          graybutton(107,28,128,49);
          graybutton(107,90,128,111);
         end;
       graybutton(149,28,170,49);
       graybutton(149,90,170,111);
       if ship.shiptype[SHPTYP_PURPOSE]<>SHPTYPE_ASSAULT{2} then graybutton(127,59,148,80);
       if ship.shiptype[SHPTYP_VESSEL]<>SHPTYPE_TRANSPORT{1} then graybutton(230,28,251,49);
       if ship.shiptype[SHPTYP_VESSEL]=SHPTYPE_CRUISER{3} then graybutton(230,90,251,111);
      end
     else if ship.gunnodes[viewindex]=0 then
      begin
       i:=0;
       for j:=1 to 3 do
        if ((ship.engrteam[j].extra and 15)=viewindex) and (ship.engrteam[j].jobtype=JOBTYPE_INSTALL)
        and (ship.engrteam[j].job>=ID_DIRK) and (ship.engrteam[j].job<ID_NOSHIELD-1) then i:=1;
       if i=0 then
        begin
         viewlevel:=1;
         viewindex2:=1;
         while (viewindex2<251) and ((ship.cargo[viewindex2]<ID_DIRK) or (ship.cargo[viewindex2]>=ID_NOSHIELD)) do inc(viewindex2);
         if viewindex2=251 then viewindex2:=0;
         for i:=26 to 114 do
          scr_fillchar(screen[i,16],263,5);
         setcolor(10);
         line(165,25,165,114);
         setcolor(2);
         line(164,25,164,115);
         screen[115,165]:=6;
         screen[25,164]:=6;
         printxy(30,27,'Installable Weapons');
         setupweaponinfo;
         showpanel(conbut2);
       end else if i=1 then
        begin
         tcolor:=94;
         bkcolor:=3;
         println;
         print('ENGINEERING: Already installing a weapon at that node.');
        end;
       end
      else
       begin
        tcolor:=94;
        bkcolor:=3;
        println;
        print('ENGINEERING: We must remove the old weapon first.');
       end;
  7: begin							{ remove weapon }
      if (viewlevel=0) and (ship.gunnodes[viewindex]>0) then
       begin
        mouseshow;
        i:=0;
        while (i<maxcargo) and (cargo[i].index<>ship.gunnodes[viewindex]+ID_DIRK-1) do inc(i);
        str1:=cargo[i].name;
        while str1[length(str1)]=' ' do dec(str1[0]);
        if yesnorequest('Remove '+str1+'?',0,31) then
         begin
          j:=1;
          while (ship.engrteam[j].job<>0) and (j<4) do inc(j);
          if j=4 then
           begin
            println;
            tcolor:=94;
            print('ENGINEERING: No team available.');
           end
          else
           begin
            addcargo(ship.gunnodes[viewindex]+ID_DIRK-1, true);
            ship.engrteam[j].job:=ship.gunnodes[viewindex]+ID_DIRK-1;
            ship.engrteam[j].jobtype:=JOBTYPE_REMOVE;
            ship.engrteam[j].timeleft:=1000;
            ship.gunnodes[viewindex]:=0;
           end;
         end;
        mousehide;
       end
      else if (viewlevel=1) and (viewindex2>0) then
       begin
        mouseshow;
        if yesnorequest('Install this weapon?',0,31) then
         begin
          j:=1;
          while (ship.engrteam[j].job<>0) and (j<4) do inc(j);
          if j=4 then
           begin
            println;
            tcolor:=94;
            print('ENGINEERING: No team available.');
           end
          else
           begin
            ship.engrteam[j].job:=ship.cargo[viewindex2];
            if ship.numcargo[viewindex2]>1 then
             dec(ship.numcargo[viewindex2])
            else
             begin
              ship.cargo[viewindex2]:=0;
              ship.numcargo[viewindex2]:=0;
             end;
            ship.engrteam[j].jobtype:=JOBTYPE_INSTALL;
            ship.engrteam[j].extra:=viewindex;
            ship.engrteam[j].timeleft:=1000;
            displayconfigure(6);
            exit;
           end;
         end;
        mousehide;
       end;
      bkcolor:=5;
      tcolor:=191;
     end;
 end;
 case viewlevel of
  0: for j:=1 to 10 do
      begin
       case j of
         1: if ship.shiptype[SHPTYP_HEAVYNESS]<>SHPTYPE_HEAVY{1} then
             sideshowweaponicon(30,60,ship.gunnodes[j],j);
         2: if ship.shiptype[SHPTYP_HEAVYNESS]<>SHPTYPE_LIGHT{2} then
             sideshowweaponicon(65,29,ship.gunnodes[j],j);
         3: if ship.shiptype[SHPTYP_HEAVYNESS]<>SHPTYPE_LIGHT{2} then
             sideshowweaponicon(65,91,ship.gunnodes[j],j);
         4: if ship.shiptype[SHPTYP_PURPOSE]<>SHPTYPE_SHUTTLE{1} then
             showweaponicon(108,29,ship.gunnodes[j],j);
         5: if ship.shiptype[SHPTYP_PURPOSE]<>SHPTYPE_SHUTTLE{1} then
             revshowweaponicon(108,91,ship.gunnodes[j],j);
         6: showweaponicon(150,29,ship.gunnodes[j],j);
         7: revshowweaponicon(150,91,ship.gunnodes[j],j);
         8: if ship.shiptype[SHPTYP_PURPOSE]<>SHPTYPE_ASSAULT{2} then
             sideshowweaponicon(128,60,ship.gunnodes[j],j);
         9: if ship.shiptype[SHPTYP_VESSEL]<>SHPTYPE_TRANSPORT{1} then
             backshowweaponicon(231,29,ship.gunnodes[j],j);
        10: if ship.shiptype[SHPTYP_VESSEL]=SHPTYPE_CRUISER{3} then
             backshowweaponicon(231,91,ship.gunnodes[j],j);
       end;
       configcursor;
     end;
   1: if viewindex2>0 then
      begin
       if (ship.cargo[viewindex2]<ID_DIRK) or (ship.cargo[viewindex2]>=ID_NOSHIELD) then
        displayconfigure(4);
       if viewindex2>0 then
        begin
         displayweaponstats(ship.cargo[viewindex2]-ID_DIRK+1);
         showweaponicon(172,89,ship.cargo[viewindex2]-ID_DIRK+1,0);
        end
       else
        begin
         displayweaponstats(0);
         showweaponicon(172,89,0,0);
        end;
       x:=viewindex2+1;
       y:=6;
       repeat
        while (x<251) and ((ship.cargo[x]<ID_DIRK) or (ship.cargo[x]>=ID_NOSHIELD)) do inc(x);
        if x=viewindex2 then bkcolor:=179 else bkcolor:=5;
        if x<251 then
         begin
          inc(y);
          printxy(30,31+y*6,cargo[ship.cargo[x]-ID_DIRK+1].name);
         end;
        inc(x);
       until (y=12) or (x>250);
       if y<12 then
        for j:=38+y*6 to 114 do
         scr_fillchar(screen[j,30],113,5);
       x:=viewindex2;
       y:=7;
       repeat
        while (x>0) and ((ship.cargo[x]<ID_DIRK) or (ship.cargo[x]>=ID_NOSHIELD)) do dec(x);
        if x=viewindex2 then bkcolor:=179 else bkcolor:=5;
        if x>0 then
         begin
          dec(y);
          printxy(30,31+y*6,cargo[ship.cargo[x]-ID_DIRK+1].name);
         end;
        dec(x);
       until (y=1) or (x<1);
       if y>1 then
        for j:=37 to 31+y*6 do
         scr_fillchar(screen[j,30],113,5);
      end;
 end;
 mouseshow;
 bkcolor:=3;
end;

procedure displaybotinfo(com: integer);
var s: string[12];
    i,j: integer;
begin
 tcolor:=191;
 bkcolor:=5;
 mousehide;
 case com of
  0..2: ;
  3: if viewlevel=0 then
      begin
       dec(viewindex);
       while (tempplan^[curplan].cache[viewindex]=0) and (viewindex>0) do dec(viewindex);
       if viewindex<1 then
        begin
         viewindex:=1;
         while (tempplan^[curplan].cache[viewindex]=0) and (viewindex<8) do inc(viewindex);
         if viewindex>7 then viewindex:=0;
        end;
      end
     else if viewlevel=2 then
     begin
	if tempplan^[curplan].state <> 7 then
	begin
	   case viewindex2 of
	     1 : begin
		    if (incargo(ID_FABRICATOR)>0) then viewindex2:=4
		    else if (incargo(ID_MANUFACTORY)>0) then viewindex2:=2;
		 end;
	     2 : begin
		    if (incargo(ID_MINEBOT)>0) then viewindex2:=1
		    else if (incargo(ID_FABRICATOR)>0) then viewindex2:=4;
		 end;
	   else begin
	      if (incargo(ID_MANUFACTORY)>0) then viewindex2:=2
	      else if (incargo(ID_MINEBOT)>0) then viewindex2:=1;
	   end;
	   end;
	end else begin
	   if (incargo(ID_STARMINER)>0) then viewindex2:=5;
	end;
	showbotstuff;
     end
     else
      begin
       dec(viewindex2);
       while (viewindex2>0) and (ship.cargo[viewindex2]=0) do dec(viewindex2);
       if viewindex2=0 then
        begin
         viewindex2:=250;
         while (viewindex2>0) and (ship.cargo[viewindex2]=0) do dec(viewindex2);
        end;
      end;
  4: if viewlevel=0 then
      begin
       inc(viewindex);
       while(tempplan^[curplan].cache[viewindex]=0) and (viewindex<8) do inc(viewindex);
       if viewindex>7 then
        begin
         viewindex:=7;
         while(tempplan^[curplan].cache[viewindex]=0) and (viewindex>0) do dec(viewindex);
        end;
      end
     else if viewlevel=2 then
     begin
	if tempplan^[curplan].state <> 7 then
	begin
	   case viewindex2 of
	     1 : begin
		     if (incargo(ID_MANUFACTORY)>0) then viewindex2:=2
		     else if (incargo(ID_FABRICATOR)>0) then viewindex2:=4;
		  end;
	     2 : begin
		     if (incargo(ID_FABRICATOR)>0) then viewindex2:=4
		     else if (incargo(ID_MINEBOT)>0) then viewindex2:=1;
		  end;
	   else begin
		    if (incargo(ID_MINEBOT)>0) then viewindex2:=1
		    else if (incargo(ID_MANUFACTORY)>0) then viewindex2:=2;
	   end;
	   end;
	end else begin
	   if (incargo(ID_STARMINER)>0) then viewindex2:=5;
	end;
       showbotstuff;
      end
     else
      begin
       inc(viewindex2);
       while (viewindex2<251) and (ship.cargo[viewindex2]=0) do inc(viewindex2);
       if viewindex2=251 then
        begin
         viewindex2:=1;
         while (viewindex2<251) and (ship.cargo[viewindex2]=0) do inc(viewindex2);
         if viewindex2=251 then viewindex2:=0;
        end;
      end;
  5: begin
      removerightside(true);
      mouseshow;
      exit;
     end;
  6: if (viewlevel=0) then
      begin
       i:=1;
       while (tempplan^[curplan].cache[i]>0) and (i<8) do inc(i);
       if i>7 then
        begin
         tcolor:=94;
         bkcolor:=3;
         println;
         print('ENGINEERING: Cache full.');
         tcolor:=191;
         bkcolor:=5;
        end
       else
        begin
         viewindex:=i;
         viewindex2:=1;
         while (viewindex2<251) and (ship.cargo[viewindex2]=0) do inc(viewindex2);
         if viewindex2=251 then
          begin
           tcolor:=94;
           bkcolor:=3;
           println;
           print('ENGINEERING: Nothing in cargo.');
           tcolor:=191;
           bkcolor:=5;
           viewlevel:=0;
          end else
           begin
            printxy(168,27,'    Add to Cache     ');
            viewlevel:=1;
            for i:=37 to 115 do
             scr_fillchar(screen[i,166],113,5);
            showpanel(botbut1);
           end;
        end;
      end
     else
      begin
       printxy(169,27,'   Cache Contents    ');
       for i:=37 to 115 do
        scr_fillchar(screen[i,166],113,5);
       viewlevel:=0;
       showpanel(botbut0);
       viewindex:=1;
       while (viewindex<8) and (tempplan^[curplan].cache[viewindex]=0) do inc(viewindex);
       if viewindex=8 then viewindex:=1;
      end;
  7: if (viewlevel=0) and (viewindex>0) and (tempplan^[curplan].cache[viewindex]>0) then
      begin
       bkcolor:=3;
       if addcargo(tempplan^[curplan].cache[viewindex], false) then
        tempplan^[curplan].cache[viewindex]:=0;
       displaybotinfo(3);
       tcolor:=191;
      end
     else if (viewlevel=1) then
      begin
       printxy(169,27,'   Cache Contents    ');
       for i:=37 to 115 do
        scr_fillchar(screen[i,166],113,5);
       viewlevel:=0;
       if ship.cargo[viewindex2]>ID_ARTIFACT_OFFSET then
        begin
         getartifactname(ship.cargo[viewindex2]);
         i:=maxcargo;
        end
       else
        begin
         i:=1;
         while (cargo[i].index<>ship.cargo[viewindex2]) do inc(i);
        end;
       tempplan^[curplan].cache[viewindex]:=cargo[i].index;
       removecargo(cargo[i].index);
       showpanel(botbut0);
      end
     else if (viewlevel=2) then
      begin
       mouseshow;
       case viewindex2 of
	 1			 : s:='minebot';
	 2			 : s:='manufactuary';
	 4			 : s:='fabricator';
	 5			 : s:='starminer';
       end;
       if yesnorequest('Send '+s+'?',0,31) then
       begin
	  tempplan^[curplan].bots:=(tempplan^[curplan].bots and (255 - 7)) or viewindex2;
	  removecargo(ID_PROBOT+viewindex2);
	  for i:=37 to 115 do
	     scr_fillchar(screen[i,166],113,5);
	  viewlevel:=0;
	  showpanel(botbut0);
       end;
	 tcolor :=191;
	 bkcolor :=5;
	 mousehide;
      end;
  8				 : if (viewlevel=0) and ((tempplan^[curplan].bots and 7)=0) then
      begin
	if tempplan^[curplan].state <> 7 then
	begin
	   if (incargo(ID_MINEBOT)>0) or (incargo(ID_MANUFACTORY)>0) or (incargo(ID_FABRICATOR)>0)  then
	   begin
	      printxy(164,27,'       Bot Info      ');
	      for i:=37 to 114 do
		 scr_fillchar(screen[i,166],113,5);
	      if incargo(ID_MINEBOT)>0 then viewindex2:=1
	      else if incargo(ID_MANUFACTORY)>0 then viewindex2:=2
	      else viewindex2:=4;
	      viewlevel:=2;
	      showbotstuff;
	      showpanel(botbut2);
	   end else begin
	      tcolor:=94;
	      bkcolor:=3;
	      println;
	      print('ENGINEERING: No bots available.');
	      tcolor:=191;
	      bkcolor:=5;
	   end;
	end else begin
	   if (incargo(ID_STARMINER)>0) then
	   begin
	      printxy(164,27,'       Bot Info      ');
	      for i:=37 to 114 do
		 scr_fillchar(screen[i,166],113,5);
	      viewindex2:=5;
	      viewlevel:=2;
	      showbotstuff;
	      showpanel(botbut2);
	   end else begin
	      tcolor:=94;
	      bkcolor:=3;
	      println;
	      print('ENGINEERING: No bots available.');
	      tcolor:=191;
	      bkcolor:=5;
	   end;
	end;
      end
     else if (viewlevel=0) and ((tempplan^[curplan].bots and 7)>0) then
      begin
       mouseshow;
       case (tempplan^[curplan].bots and 7) of
	 1 : s:='minebot';
	 2 : s:='manufactuary';
	 4 : s:='fabricator';
	 5 : s:='starminer';
       end;
       if (yesnorequest('Recall '+s+'?',0,31)) and (addcargo((tempplan^[curplan].bots and 7)+ID_PROBOT,false))
         then tempplan^[curplan].bots:=tempplan^[curplan].bots and (255 - 7);
       tcolor:=191;
       bkcolor:=5;
       mousehide;
      end
 end;
 case viewlevel of
  0: begin
      y:=0;
      for j:=1 to 7 do
       begin
        if viewindex=j then bkcolor:=179 else bkcolor:=5;
        if tempplan^[curplan].cache[j]>0 then
         begin
          inc(y);
          if tempplan^[curplan].cache[j]>ID_ARTIFACT_OFFSET then
           begin
            getartifactname(tempplan^[curplan].cache[j]);
            i:=maxcargo;
           end
          else
           begin
            i:=1;
            while (cargo[i].index<>tempplan^[curplan].cache[j]) do inc(i);
           end;
          printxy(167,32+y*10,cargo[i].name);
         end
       end;
      if y<7 then
       for i:=42+y*10 to 114 do
        scr_fillchar(screen[i,166],113,5);
     end;
  1: begin
      x:=viewindex2+1;
      y:=6;
      repeat
       while (x<251) and (ship.cargo[x]=0) do inc(x);
       if x=viewindex2 then bkcolor:=179 else bkcolor:=5;
       if x<251 then
        begin
         inc(y);
         if ship.cargo[x]>ID_ARTIFACT_OFFSET then
          begin
           getartifactname(ship.cargo[x]);
           i:=maxcargo;
          end
         else
          begin
           i:=1;
           while (cargo[i].index<>ship.cargo[x]) do inc(i);
          end;
         printxy(167,37+y*6,cargo[i].name);
        end;
       inc(x);
      until (y=12) or (x>250);
      if y<12 then
       for j:=43+y*6 to 116 do
        scr_fillchar(screen[j,166],113,5);
      x:=viewindex2;
      y:=7;
      repeat
       while (x>0) and (ship.cargo[x]=0) do dec(x);
       if x=viewindex2 then bkcolor:=179 else bkcolor:=5;
       if x>0 then
        begin
         dec(y);
         if ship.cargo[x]>ID_ARTIFACT_OFFSET then
          begin
           getartifactname(ship.cargo[x]);
           i:=maxcargo;
          end
         else
          begin
           i:=1;
           while (cargo[i].index<>ship.cargo[x]) do inc(i);
          end;
         if i>1000 then errorhandler('Invalid Planet Num.',6);
         printxy(167,37+y*6,cargo[i].name);
        end;
       dec(x);
      until (y=0) or (x<1);
      if y>0 then
       for j:=37 to 37+y*6 do
        scr_fillchar(screen[j,166],113,5);
     end;
  2: begin
	y:=0;
	if tempplan^[curplan].state <> 7 then
	begin
	   if incargo(ID_MINEBOT)>0 then
	   begin
	      if viewindex2=1 then bkcolor:=179 else bkcolor:=5;
	      printxy(167,37+y*6,'Drop Minebot');
	      inc(y);
	   end;
	   if incargo(ID_MANUFACTORY)>0 then
	   begin
	      if viewindex2=2 then bkcolor:=179 else bkcolor:=5;
	      printxy(167,37+y*6,'Drop Manufactory');
	      inc(y);
	   end;
	   if incargo(ID_FABRICATOR)>0 then
	   begin
	      if viewindex2=4 then bkcolor:=179 else bkcolor:=5;
	      printxy(167,37+y*6,'Drop Fabricator');
	      inc(y);
	   end;
	end else begin
	   if incargo(ID_STARMINER)>0 then
	   begin
	      if viewindex2=5 then bkcolor:=179 else bkcolor:=5;
	      printxy(167,37+y*6,'Drop Starmine');
	      inc(y);
	   end;
	end;
     end;
 end;
 mouseshow;
 bkcolor:=3;
end;

procedure displayhistorymap;
begin
 if (ship.damages[DMG_CPU]>0) and (not checkscandamages) then exit;
 if index<0 then index:=0;
 if index>7 then index:=0 else inc(index);
 if t1<0 then t1:=0;
 t1:=t1+0.049;
 if t1>6.28 then
  begin
   t1:=t1-6.28;
   move(nearbybackup,nearby,sizeof(nearbyarraytype));
  end;
 mousehide;
 for i:=18 to 123 do
  scr_fillchar(screen[i,27],116,5);
 i:=0;
 for j:=1 to nearbymax do if nearby[j].index<>0 then
  begin
   x1:=nearby[j].x;
   y1:=nearby[j].z;
   nearby[j].x:=(0.99879974)*x1-(0.048980394)*y1;
   nearby[j].z:=(0.048980394)*x1+(0.99879974)*y1;
   x1:=85+(nearby[j].x*480/(500-nearby[j].z));
   y1:=70+(nearby[j].y*480/(500-nearby[j].z));
   x:=round(x1);
   y:=round(y1);
   if systems[nearby[j].index].visits>0 then
    begin
     setcolor(index+80);
     if i=0 then
      begin
       moveto(x,y);
       i:=1;
      end
     else lineto(x,y);
    end;
   screen[y,x]:=22;
  end;
 if target>0 then
  begin
   x1:=85+(nearby[target].x*480/(500-nearby[target].z));
   y1:=70+(nearby[target].y*480/(500-nearby[target].z));
   x:=round(x1);
   y:=round(y1);
   setcolor(80+index);
   circle(x,y,6);
  end;
 mouseshow;
end;

procedure displayshortscan;
label error;
begin
 if (ship.damages[DMG_CPU]>0) and (not checkscandamages) then exit;
 t1:=t1+0.02;
 if t1>6.28 then t1:=0;
 mousehide;
 for i:=18 to 123 do
  scr_fillchar(screen[i,27],117,5);
 if showplanet then
  begin
   j:=curplan;
   x:=(tempplan^[j].psize+1)*2000;
   y:=0;
   z:=(tempplan^[j].orbit+1)*2000;
   ar:=x/sin(arctan(x/z));
   br:=ar/2;
   t2:=arctan(z/(2*x));
   x1:=85+(ar*cos(t1+t2))/370;
   y1:=70+(br*sin(t1+t2)+y)/514;
   x:=round(x1);
   y:=round(y1);
   randseed:=tempplan^[j].seed;
   case tempplan^[j].state of
    0: case tempplan^[j].mode of
          1: a:=random(3)*10;
        2,3: case tempplan^[j].psize of
              0,1: a:=170;
              2,3: a:=random(3)*10+250;
                4: a:=random(2)*10+150;
             end;
       end;
    1..5: case tempplan^[j].psize of
           0,1: if tempplan^[j].water>25 then a:=180 else a:=190;
           2,3: a:=240-(tempplan^[j].water div 10)*10;
             4: a:=140-(tempplan^[j].water div 7)*10;
          end;
    6: if tempplan^[j].mode=1 then
        case tempplan^[j].psize of
         0,1: a:=180;
         2,3: a:=200;
           4: a:=80;
        end
        else a:=random(3)*10;
    7: case tempplan^[j].mode of
        1: a:=60;
        2: a:=50;
        3: a:=70;
       end;
    else a:=0;
   end;
   for i:=0 to 9 do
    for b:=0 to 9 do
     if planicons^[i,a+b]<>0 then
      screen[y+i,x+b]:=planicons^[i,a+b];
  end;
 j:=39;
 if (ship.wandering.alienid<16000) then
  begin
   x:=ship.wandering.relx;
   y:=ship.wandering.rely;
   z:=ship.wandering.relz;
   if (abs(x)>8000) or (abs(y)>8000) or (abs(z)>8000) then goto error;
   if (abs(x)<3000) and (abs(y)<3000) and (abs(z)<3000) then j:=88;
   if z=0 then goto error;
   ar:=x/sin(arctan(x/z));
   br:=ar/2;
   if x=0 then goto error;
   t2:=arctan(z/(2*x));
   x1:=85+(ar*cos(t1+t2))/380;
   y1:=70+(br*sin(t1+t2)+y)/514;
   x:=round(x1);
   y:=round(y1);
   screen[y,x]:=95;
   screen[y-2,x-1]:=63;
   screen[y-1,x-2]:=63;
   screen[y-2,x-2]:=63;
   screen[y+1,x+2]:=63;
   screen[y+2,x+1]:=63;
   screen[y+2,x+2]:=63;
error:
  end;
 if index<0 then index:=0;
 if index>7 then index:=0 else inc(index);
 setcolor(j+index);
 x:=5000;
 y:=0;
 z:=5000;
 ar:=x/sin(arctan(x/z));
 br:=ar/2;
 t2:=arctan(z/(2*x));
 x1:=85+(ar*cos(t1+t2))/360;
 x:=round(x1);
 circle(85,70,abs(round(round(x1)-85)));
 mouseshow;
 bkcolor:=3;
end;

procedure computegraph;
var dist,tech,signaly,signalx,noise: integer;
begin
 if ship.wandering.alienid<16000 then
  begin
   dist:=ship.wandering.relx;
   if ship.wandering.rely>dist then dist:=ship.wandering.rely;
   if ship.wandering.relz>dist then dist:=ship.wandering.relz;
   dist:=round(dist/2560);
  end
 else dist:=9;
 tech:=hi(ship.wandering.techlevel)*10+lo(ship.wandering.techlevel);
 signaly:=round((round((tech/30)*(tech/30)))*((9-dist)/7)*ship.crew[3].level);
 if showplanet then
  begin
   if tempplan^[curplan].orbit=0 then noise:=18
    else noise:=round((exp(abs(tempplan^[curplan].orbit-6)))/10)
  end
  else noise:=0;
 if signaly>9 then signaly:=9;
 signalx:=round((tech-40)/30*98);
 if signalx>98 then signalx:=98;
 for j:=36 to 134 do
  screen[34-random(noise)+round(noise/2),j]:=28;
 if ship.wandering.alienid<16000 then screen[34-signaly,signalx+36]:=31;
end;

procedure displaylongscan;
label error;
begin
 if (ship.damages[DMG_CPU]>0) and (not checkscandamages) then exit;
 mousehide;
 for i:=18 to 123 do
  scrto_move(starmapscreen^[i,27],screen[i,27],29*4);
 computegraph;
 mouseshow;
 for i:=1 to 3 do
  begin
   x:=random(23000);
   y:=random(23000);
   z:=random(23000);
   x:=round((x+z)*0.0006);
   y:=round((y+z)*0.0006);
   screen[86+y,85+x]:=random(8)+5;
  end;
 if (ship.wandering.alienid<16000) then
  begin
   x:=ship.wandering.relx;
   y:=ship.wandering.rely;
   z:=ship.wandering.relz;
   x:=round((x+z)*0.0007);
   y:=round((y+z)*0.0007);
   starmapscreen^[86+y,85+x]:=random(8)+7;
 error:
  end;
end;

begin
end.
