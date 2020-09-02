unit combat;
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
   Battle/Combat unit for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

{$O+}
{$I-}
{$PACKRECORDS 1}
interface

procedure initiatecombat;

implementation

uses  utils_, data, gmouse, utils, utils2, modplay, weird, saveload, usecode, crewtick, math;

const
 maxships = 25;
 maxformations = 3;
 shipclass : array[0..14] of string[14] =
  ('Shuttle       ','Scout         ','Fighter       ','Assault Scout ',
   'Patrol Craft  ','Corvette      ','Frigate       ','Lt. Destroyer ',
   'Hv. Destroyer ','Lt. Cruiser   ','Hv. Cruiser   ','Battle Cruiser',
   'Flagship      ','Battleship    ','Dreadnaught   ');
 formation : array[0..maxformations-1,0..4,1..3] of integer =
  (
   ((0,0,0),(-3000,0,0),(3000,0,0),(0,-3000,0),(0,3000,0)),               { planar plus }
   ((0,0,0),(-3000,-3000,0),(3000,3000,0),(-3000,3000,0),(3000,-3000,0)), { planar cross}
   ((0,0,0),(1000,0,1000),(2000,0,2000),(3000,0,3000),(4000,0,4000))      { 3d slash }
   );
type
 alienshiparray= array[1..maxships] of alienshiptype;
 statpictype= array[0..1,0..11] of byte;
 alienshipdisplay= array[125..189,6..98] of byte;
 shieldpictype= array[0..6,0..3] of byte;
 msgtype= array[0..9,0..9] of byte;
 msgarray= array[0..3] of msgtype;
 {$PACKRECORDS DEFAULT}
var
 oldshddmg,i,a,b,nships,targetindex,fireweapon,moveindex,picy: integer;
 range: longint;
 scanning,autofire,engaging,alienpicmode,dead,done_: boolean;
 poweredup: array[1..10] of integer;
 userpowerup: array[1..10] of boolean;
 ships: ^alienshiparray;
 statpic,blank: ^statpictype;
 stats: array[1..3] of byte;
 part,r: real;
 asdisplay: ^alienshipdisplay;
 str1: string[10];
 shieldpic,shieldpic2: ^shieldpictype;
 alienname: string[12];
 shipdir,shipdir2: integer;
 msgs: ^msgarray;
 learnchance:Integer;

{*******************************************************************************}

procedure displaystats;
var i: integer;
begin
 if done_ then exit;
 mousehide;
 part:=102/ship.hullmax*ship.hullintegrity;
 if round(part)<>stats[1] then
  begin
   for i:=0 to 1 do
    move(blank^[i],screen[117-stats[1]+i,269],10);
   stats[1]:=round(part);
   y:=117-round(part);
   for i:=0 to 1 do
    move(statpic^[i],screen[y+i,269],10);
   end;
 part:=102/32000*ship.battery;
 if round(part)<>stats[2] then
  begin
   for i:=0 to 1 do
    move(blank^[i],screen[117-stats[2]+i,285],10);
   stats[2]:=round(part);
   y:=117-round(part);
   for i:=0 to 1 do
    move(statpic^[i],screen[y+i,285],10);
  end;
 part:=102/100*ship.shieldlevel;
 if round(part)<>stats[3] then
  begin
   for i:=0 to 1 do
    move(blank^[i],screen[117-stats[3]+i,301],10);
   stats[3]:=round(part);
   y:=117-round(part);
   for i:=0 to 1 do
    move(statpic^[i],screen[y+i,301],10);
  end;
 mouseshow;
end;

// set shield to n% (or to the maximum the shield subsystem damages allow, if n% is too much) and display levels
procedure displayshieldpic(n: integer);
begin
 mousehide;
 if ship.shield<=ID_NOSHIELD then { no shield is installed, do not allow moving it }
  begin
    n := 0;
    ship.shieldopt[SHLD_COMBAT_WANT] := 0;
  end
 else if ship.shield=ID_REFLECTIVEHULL then n:=100-ship.damages[DMG_SHIELD];	{ reflective hull always uses max the shield damages allow }

 part:=102/100*ship.shieldopt[SHLD_COMBAT_WANT];
 for i:=0 to 6 do
  scr_fillchar(screen[114-round(part)+i,312],4,0);
 if n>100-ship.damages[DMG_SHIELD] then n:=100-ship.damages[DMG_SHIELD];
 ship.shieldopt[SHLD_COMBAT_WANT]:=n;
 part:=102/100*n;
 for i:=0 to 6 do
  move(shieldpic^[i],screen[114-round(part)+i,312],1*4);
 mouseshow;
end;

procedure displaytargetinfo2;
var str1 : string[8];
   j	 : Integer;
begin
 mousehide;
 with ships^[targetindex] do
  begin
   printxy(4,125,alienname);
   b:=ships^[targetindex].maxhull;
   if b<1000 then b:=b div 100
   else b:=((b-1000) div 1600) + 9;
   printxy(4,131,shipclass[b]+' '+chr(64+targetindex));
   str(r:8:1,str1);
   printxy(4,137,'Range: '+str1+' KM');
   printxy(4,143,'Tech Level: '+chr(hi(techlevel)+48)+'.'+chr(lo(techlevel)+48));
   str(ships^[targetindex].accelmax,str1);
   printxy(4,149,'Accel: '+str1);
   if picx>139 then j:=10 else j:=5;
   if picy>=179 then a:=19 else a:=20;
   for i:=0 to a do
    move(backgr^[i+picy,picx],screen[161+i,14],j*4);
   if j=5 then
    for i:=0 to 19 do
     scr_fillchar(screen[161+i,34],20,0);
   for j:=0 to 1 do
    begin
     a:=random(2);
     for i:=0 to 9 do
      move(msgs^[a,i],screen[162+i+j*10,60],10);
    end;
   for j:=0 to 1 do
    begin
     a:=random(2);
     for i:=0 to 9 do
      move(msgs^[a,i],screen[162+i+j*10,70],10);
    end;
   for j:=0 to 1 do
    begin
     a:=random(2)+2;
     for i:=0 to 9 do
      move(msgs^[a,i],screen[162+i+j*10,80],10);
    end;
  end;
 mouseshow;
end;

{ n=damage type: 1=Psionic, 2=Particle, 3=Intertial, 4=Energy; 5=SPECIAL damage shield subsystem only;  d=amount of damage inflicted }
procedure givedamage(n,d: integer);
var j: integer;
begin
 d:=round(d/100*(100-ship.damages[DMG_WEAPONS]));
 if d<1 then d:=1;
 with ships^[targetindex] do				// givedamage() always works on current "targetindex" ship
  begin
   case n of
    DMGTYP_PSIONIC: inc(damages[DMG_LIFESUPPORT],d);
    DMGTYP_PARTICLE: dec(hullintegrity,d);
    DMGTYP_INERTIAL: dec(hullintegrity,d div 2);
    DMGTYP_ENERGY: case random(8) of
        0: inc(damages[DMG_POWER],d);
        1: inc(damages[DMG_SHIELD],d);
        2: inc(damages[DMG_WEAPONS],d);
        3: inc(damages[DMG_ENGINES],d);
        4: inc(damages[DMG_COMM],d);
        5: inc(damages[DMG_CPU],d);
        6,7: dec(hullintegrity,d);
       end;
    DMGTYP_FAKE_SHLD: inc(damages[DMG_SHIELD],d);
   end;
   if hullintegrity<0 then hullintegrity:=0;
   for j:=1 to 7 do if damages[j]>100 then damages[j]:=100;
   if shieldlevel<0 then shieldlevel:=0;
   if shield=ID_REFLECTIVEHULL then shieldlevel:=100-damages[DMG_SHIELD];	// reflective hull always has same value as shield subsystem integrity (100%-damage%)
   assert (shieldlevel >= 0, 'alien shieldlevel is negative');
   assert (shieldlevel <= 100, 'alien shieldlevel is too big');
   if damages[DMG_LIFESUPPORT]=100 then hullintegrity:=0;
   //writeln ('  givedamage() type',n,' = ',d,' GJ to alien',targetindex,' result: hullintegrity=', hullintegrity, ' shield', shield, ' level = ', shieldlevel,'%, damages: power=', damages[DMG_POWER], ' shield=', damages[DMG_SHIELD], ' weapons=', damages[DMG_WEAPONS], ' engines=', damages[DMG_ENGINES], ' life=', damages[DMG_LIFESUPPORT], ' comm=', damages[DMG_COMM], ' cpu=', damages[DMG_CPU]);
  end;
end;

procedure displaymap; forward;

 { this is counterpart to impact(), but with us firing weapons at aliens }
procedure firingweapon(n: integer);
var j,i,a,b,c,d: integer;
begin
 c:=ship.gunnodes[n];					// c = our current weapon index
 case weapons[c].dmgtypes[DMGTYP_ENERGY] of
   0..23: if weapons[c].dmgtypes[DMGTYP_PARTICLE]>weapons[c].dmgtypes[DMGTYP_INERTIAL] then soundeffect('gun4.sam',7000)
           else soundeffect('gun1.sam',7000);
   24..34: soundeffect('laser1.sam',7000);
   35..45: soundeffect('laser2.sam',7000);
   46..56: soundeffect('laser3.sam',7000);
   57..67: soundeffect('laser4.sam',7000);
   68..78: soundeffect('laser5.sam',7000);
   79..89: soundeffect('laser6.sam',7000);
   90..100: soundeffect('laser7.sam',7000);
 end;
 delay(tslice);
 {if (skillcheck(4)) or ((scanning) and (random(100)<20)) then}
 if SkillTest(True, 4, ships^[targetindex].skill - (ord(scanning) * 20), learnchance) then
  begin
   b:=ships^[targetindex].shield-ID_SHIELDS_OFFSET;	// b = alien's shield index
   assert (b>0);					// aliens always have *some* shield, see Data_Generators/makedata/alienshp.txt
   for j:=1 to 4 do if weapons[c].dmgtypes[j]>0 then	// j = our weapon damage types: 1=Psionic, 2=Particle, 3=Intertial, 4=Energy
    begin
     i:=round(weapons[c].dmgtypes[j]/100*weapons[c].damage*5);	// i = maximum damage our weapon can deal (for this dmgtype "j")
     //writeln ('successfully firing weapon',c,'(node',n,') with dmgtype',j,' and maxdamage i=',i,' GJ on alien',targetindex, ' with shield', ships^[targetindex].shield, ' at ', ships^[targetindex].shieldlevel ,'%');
     if ships^[targetindex].shieldlevel=0 then givedamage(j,i)	// alien ship has not shields, let it take full damage "i"
     else
      begin							// alien ship has some shield installed
       a:=round(weapons[b].dmgtypes[j]/100*weapons[b].damage*ships^[targetindex].shieldlevel/100);	// a = current maximum shield damage absorption
       //writeln ('  alien',targetindex,' has shield',b, ' with resistance ', weapons[b].dmgtypes[j], '% to dmgtype',j,', and shieldlevel ', ships^[targetindex].shieldlevel, '%. Max current damage absorption = ', a, ' GJ');
       if a<i then
        begin							// alien ship receiving more damage than their shields can handle
         givedamage(j,i-a);					// let them take residual damage...
         ships^[targetindex].shieldlevel:=1;			// ... and collapse shields (NB: should be 0, but we are dividing by it!)
         if (ships^[targetindex].shield=ID_REFLECTIVEHULL) and (j>1) then ships^[targetindex].damages[DMG_SHIELD]:=100;	// psionic damage passes through reflective hull, and thus cannot destroy it
         //writeln ('  alien shield', ships^[targetindex].shield, ' is collapsing! shield subsystem damages=', ships^[targetindex].damages[DMG_SHIELD]);
        end
       else
        begin							// alien ship receiving less damage than their shields can handle
         part:=i/ships^[targetindex].shieldlevel;		//   NB: This calculations looks strange... but is the same as for our ship - see "we've taken LESS damage than our shield can handle" part of the code
         part:=part*(1/weapons[b].damage);
         part:=part*100;
         a:=round(part*100);					//   a = by how many percent will we reduce shield level
         d:=ships^[targetindex].shieldlevel-a;			//   d = new shield level in percent
         //writeln ('  alien shield is holding, reducing shieldlevel by ',a,'% to ',d, '%');
         if d<0 then
          begin							// alien shield has collapsed!
           givedamage(DMGTYP_FAKE_SHLD,random(4)+1);		//   this always cases damage to shield subsystem for 1-5
           if (ships^[targetindex].shield=ID_REFLECTIVEHULL) and (j>1) then	// psionic damage passes through reflective hull, and thus cannot destroy it
            ships^[targetindex].damages[DMG_SHIELD]:=100;
           ships^[targetindex].shieldlevel:=1;			//   ... and collapse shields (NB: should be 0, but we are dividing by it!)
          end
         else
          begin							// alien shield still holding
           ships^[targetindex].shieldlevel:=d;
           if (ships^[targetindex].shield=ID_REFLECTIVEHULL) and (j>1) then	// psionic damage passes through reflective hull, and thus cannot damage it
            ships^[targetindex].damages[DMG_SHIELD]:=100-d;
          end;
        end;
      end;
    end;
  end;
 if ships^[targetindex].hullintegrity=0 then
  begin
   //writeln ('  alien', targetindex, ' has been destroyed');
   ships^[targetindex].hullintegrity:=1;
   displaymap;
   ships^[targetindex].hullintegrity:=0;
   targetindex:=1;
   while (targetindex<=nships) and (ships^[targetindex].hullintegrity=0) do inc(targetindex);
   if targetindex>nships then
   begin
     done_:=true;
    end;
   with ships^[targetindex] do
    begin
     r:=sqr(relx/10);
     r:=r+sqr(rely/10);
     r:=r+sqr(relz/10);
     r:=sqrt(r)*100;
    end;
   displaymap;
  end;
 poweredup[n]:=0;
 fireweapon:=0;
end;

procedure powerup;
var i,j: integer;
begin
 for j:=1 to 10 do
  if (poweredup[j]>-1) and (poweredup[j]<100) then
   begin
    if (userpowerup[j]) and (poweredup[j]=0) and (ship.battery>=weapons[ship.gunnodes[j]].energy) then
     begin
      dec(ship.battery,weapons[ship.gunnodes[j]].energy);
      poweredup[j]:=1;
     end
    else if poweredup[j]>0 then inc(poweredup[j]);
    i:=round(poweredup[j]*0.31);
    if i<16 then setcolor(80+i) else setcolor(32+i);
    x:=((j-1) mod 5)*23+105;
    y:=((j-1) div 5)*31+131;
    mousehide;
    rectangle(x,y,x+20,y+20);
    mouseshow;
   end
  else if poweredup[j]=100 then
    begin
     part:=weapons[ship.gunnodes[j]].range;
     if part>=r then setcolor(47) else setcolor(63);
     x:=((j-1) mod 5)*23+105;
     y:=((j-1) div 5)*31+131;
     mousehide;
     rectangle(x,y,x+20,y+20);
     mouseshow;
     if (part>=r) and ((autofire) or (fireweapon=j)) then firingweapon(j);
   end;
 if (ship.battery>0) and (ship.shieldlevel<ship.shieldopt[SHLD_COMBAT_WANT]) then inc(ship.shieldlevel)
  else if (ship.battery=0) and (ship.shieldlevel>0) then dec(ship.shieldlevel)
  else if (Ship.shieldlevel>ship.shieldopt[SHLD_COMBAT_WANT]) then dec(ship.shieldlevel);
 for j:=1 to nships do
  with ships^[j] do
   begin
    if shield>ID_REFLECTIVEHULL then
     begin
      r:=sqr(relx/10);
      r:=r+sqr(rely/10);
      r:=r+sqr(relz/10);
      r:=sqrt(r)*100;
      i:=round(weapons[shield-ID_SHIELDS_OFFSET].energy*shieldlevel/100);
      if (battery>0) and (abs(r)<390000) and (shieldlevel<(100-damages[DMG_SHIELD])) then inc(shieldlevel)
       else if ((battery=0) or (abs(r)>400000)) and (shieldlevel>0) then dec(shieldlevel)
       else if shieldlevel>(100-damages[DMG_SHIELD]) then dec(shieldlevel);
      if (abs(r)>230000) and (abs(r)<400000) and (i>round(regen*(100-damages[DMG_POWER])/100))
       and (shieldlevel>2) then dec(shieldlevel,3);
     end;
    for i:=1 to 20 do
       if charges[i]<100 then
       begin
	  if (charges[i]=0) and (battery>=weapons[maxweapons].energy) then
	  begin
	     dec(battery,weapons[maxweapons].energy);
	     charges[i]:=1;
	  end
	  else if charges[i]>0 then inc(charges[i]);
       end;
   end;
end;

procedure showweaponicon(x1,y1,weap,node: integer);
var j,i: integer;
begin
 if weap=0 then
  begin
   for i:=0 to 19 do
    scr_fillchar(screen[y1+i,x1],20,3);
   exit;
  end;
 readweaicon(weap-1);
 node:=4;
 case node of
  1,2,3,8: for i:=0 to 19 do
            for j:=0 to 19 do
             screen[y1+j,x1+i]:=tempicon^[i,j];
  4,6: for i:=0 to 19 do
        move(tempicon^[i],screen[y1+i,x1],5*4);
  5,7: for i:=0 to 19 do
        move(tempicon^[19-i],screen[y1+i,x1],5*4);
  9,10: for i:=0 to 19 do
         for j:=0 to 19 do
          screen[y1+j,x1+20-i]:=tempicon^[i,j];
 end;
end;

procedure displayweapons;
var
   j : Integer;
begin
 mousehide;
 for j:=1 to 10 do
   begin
    x:=((j-1) mod 5)*23+105;
    y:=((j-1) div 5)*31+131;
    showweaponicon(x,y,ship.gunnodes[j],j);
    if ship.gunnodes[j]>0 then
     begin
      a:=round(poweredup[j]*0.31);
      if a<16 then setcolor(80+a) else setcolor(32+a);
      rectangle(x,y,x+20,y+20);
     end;
   end;
 mouseshow;
end;

procedure displaydamage;
var a,b,i,j: integer;
begin
 if (done_) or (dead) then exit;
 mousehide;
 for a:=1 to 7 do
  begin
   b:=round((100-ship.damages[a])/100*49);
   if b<=0 then b:=1;
   part:=31/b;
   for j:=0 to b do
    begin
     screen[a*9+127,267+j]:=round(j*part);
     screen[a*9+128,267+j]:=round(j*part);
    end;
   if b<51 then
    begin
     scr_fillchar(screen[a*9+127,268+b],49-b,0);
     scr_fillchar(screen[a*9+128,268+b],49-b,0);
    end;
  end;
 if 100-ship.damages[DMG_SHIELD]<ship.shieldopt[SHLD_COMBAT_WANT] then displayshieldpic(100-ship.damages[DMG_SHIELD]);
 part:=114-(102/100*(100-ship.damages[DMG_SHIELD]));
 if round(part)<>oldshddmg then
  begin
   for i:=0 to 6 do
    scr_fillchar(screen[oldshddmg+i,296],4,0);
   for i:=0 to 6 do
    move(shieldpic2^[i],screen[round(part)+i,296],1*4);
   oldshddmg:=round(part);
  end;
 mouseshow;
end;

procedure suckpower;
var
   j : Integer;
begin
 if ship.shield>ID_REFLECTIVEHULL then
  ship.battery:=ship.battery-round(weapons[ship.shield-ID_SHIELDS_OFFSET].energy/100*ship.shieldlevel);
 i:=round((100-ship.damages[DMG_POWER])/4);
 if i=0 then i:=1;
 ship.battery:=ship.battery+i;
 if ship.battery<0 then ship.battery:=0
  else if ship.battery>32000 then ship.battery:=32000;
 for j:=1 to nships do if ships^[j].hullintegrity>0 then
  with ships^[j] do
   begin
    if shield>ID_REFLECTIVEHULL then dec(battery,round(weapons[shield-ID_SHIELDS_OFFSET].energy/100*shieldlevel));
    inc(battery,round(regen*(100-damages[DMG_POWER])/100));
    if battery<0 then battery:=0
     else if battery>32000 then battery:=32000;
    if (battery=0) and (shield>ID_REFLECTIVEHULL) and (damages[DMG_SHIELD]<99) then inc(damages[DMG_SHIELD],2);
   end;
end;

procedure displaytargetinfo;
var b : integer;
   j  : Integer;
begin
 if done_ then exit;
 with ships^[targetindex] do
  begin
   r:=sqr(relx/10);
   r:=r+sqr(rely/10);
   r:=r+sqr(relz/10);
   r:=sqrt(r)*100;
  end;
 if alienpicmode then
  begin
   displaytargetinfo2;
   exit;
  end;
 mousehide;
 with ships^[targetindex] do
  begin
   r:=sqr(relx/10);
   r:=r+sqr(rely/10);
   r:=r+sqr(relz/10);
   r:=sqrt(r)*100;
   b:=maxhull;
   if b<1000 then b:=b div 100
   else b:=((b-1000) div 1600) + 9;
   printxy(4,126,shipclass[b]+' '+chr(64+targetindex));
   b:=round(hullintegrity/maxhull*49);	{ hull integrity }
   if b<=0 then b:=1;
   part:=31/b;
   for i:=0 to b do
    scr_fillchar(screen[i+138,8],8,round(i*part));
   if b<49 then
    for i:=b+1 to 49 do
     scr_fillchar(screen[i+138,8],8,0);
   b:=round((100-damages[DMG_LIFESUPPORT])/100*49);	{ life support }
   if b<=0 then b:=1;
   part:=31/b;
   for i:=0 to b do
    scr_fillchar(screen[i+138,23],8,round(i*part));
   if b<49 then
    for i:=b+1 to 49 do
     scr_fillchar(screen[i+138,23],8,0);
   b:=round(battery/32000*49);		{ power / batt level }
   if b<=0 then b:=1;
   part:=31/b;
   for i:=0 to b do
    scr_fillchar(screen[i+138,38],9,round(i*part));
   if b<49 then
    for i:=b+1 to 49 do
     scr_fillchar(screen[i+138,38],9,0);
   b:=round(shieldlevel/100*49);	{ shield level }
   if b<=0 then b:=1;
   part:=31/b;
   for i:=0 to b do
    scr_fillchar(screen[i+138,54],8,round(i*part));
   if b<49 then
    for i:=b+1 to 49 do
     scr_fillchar(screen[i+138,54],8,0);
   for j:=1 to 7 do			{ subsystem integrity: 1=power, 2=shield, 3=weapons, 4=engines, 5=life support, 6=comm, 7=cpu }
    begin
     b:=round((100-damages[j])/100*49);
     if b<=0 then b:=1;
     part:=31/b;
     for i:=0 to b do
      screen[i+138,62+5*j]:=round(i*part);
     if b<49 then
      for i:=b+1 to 49 do
       screen[i+138,62+5*j]:=0;
    end;
  end;
 mouseshow;
end;

procedure displaymap;
var
   j : Integer;
begin
 if dead then exit;
 mousehide;
 for j:=1 to nships do
  begin
   y:=round(ships^[j].rely/range*26.66);
   x:=round(ships^[j].relx/range*119);
   z:=round(ships^[j].relz/range*26);
   //writeln ('displaymap ship',j, ' y=',y, ' x=',x, ' z=', z);
   if (abs(x)<119) and (abs(y)<26) and (abs(z)<35) then
    begin
     assert (x+132+2 < 320, 'x too big');
     assert (x+132-2 >= 0, 'x too small');
     assert (y+62+2 < 200, 'y too big1');
     assert (y+62-z+2 < 200, 'y too big2');
     assert (y+62-2 >= 0, 'y too small1');
     assert (y+62-z-2 >= 0, 'y too small2');
     if z<0 then
      for i:=y+62 to y+62-z do
       screen[i,x+132]:=screen[i,x+132] xor 6
     else
      for i:=y+62 downto y+62-z do
       screen[i,x+132]:=screen[i,x+132] xor 6;
     screen[y+62,x+132]:=screen[y+62,x+132] xor 85;
     if ships^[j].hullintegrity=0 then i:=12 else i:=31;
     screen[y+62-z,x+132]:=screen[y+62-z,x+132] xor i;
     if j=targetindex then
      begin
       screen[y+62-z-2,x+132-2]:=screen[y+62-z-2,x+132-2] xor 60;
       screen[y+62-z-2,x+132-1]:=screen[y+62-z-2,x+132-1] xor 60;
       screen[y+62-z-1,x+132-2]:=screen[y+62-z-1,x+132-2] xor 60;
       screen[y+62-z+2,x+132+1]:=screen[y+62-z+2,x+132+1] xor 60;
       screen[y+62-z+2,x+132+2]:=screen[y+62-z+2,x+132+2] xor 60;
       screen[y+62-z+1,x+132+2]:=screen[y+62-z+1,x+132+2] xor 60;
      end;
    end;
  end;
 mouseshow;
end;

procedure drawdirection(c: integer);
begin
 x:=((shipdir-1) mod 3)*12+225;
 y:=((shipdir-1) div 3)*10+88;
 setcolor(c);
 mousehide;
 rectangle(x,y,x+12,y+10);
 if shipdir2=1 then rectangle(249,68,261,78)
  else if shipdir2=2 then rectangle(249,78,261,88);
 mouseshow;
end;


{ n=damage type: 1=Psionic, 2=Particle, 3=Intertial, 4=Energy; 5=SPECIAL damage shield subsystem only;  d=amount of damage received }
procedure takedamage(n,d: integer);
var j: integer;
begin
 //writeln ('    takedamage(type=',n,', damage=', d, ')');
 if dead then exit;
 soundeffect('explode'+chr(49+random(2))+'.sam',9000);
 delay(tslice div 2);
 if d<1 then d:=1;
 case n of
  DMGTYP_PSIONIC: inc(ship.damages[DMG_LIFESUPPORT],d);		{ n=1 Psionioc inflicts damage to damages[DMG_LIFESUPPORT] = Lifesupport }
  DMGTYP_PARTICLE: dec(ship.hullintegrity,d);		{ n=2 Particle damage damages hull }
  DMGTYP_INERTIAL: dec(ship.hullintegrity,d div 2);	{ n=3 Intertial damage damages hull more slowly }
  DMGTYP_ENERGY: case random(8) of			{ n=4 Energy damage }
      0: inc(ship.damages[DMG_POWER],d);	{ damages[DMG_POWER] = Power subsystem }
      1: begin
          if ship.damages[DMG_SHIELD]+d>135 then ship.shield:=ID_NOSHIELD;	{ uninstalls / permanently destroys shield if shield subsystem > 135% damage }
          inc(ship.damages[DMG_SHIELD],d);	{ damages[DMG_SHIELD] = Shield subsystem }
         end;
      2: begin
          inc(ship.damages[DMG_ENGINES],d);	{ damages[DMG_ENGINES] = Engines subsystem }
          if ship.damages[DMG_ENGINES]>89 then drawdirection(95);
         end;
      3: begin
          if ship.damages[DMG_WEAPONS]+d>120 then	{ uninstalles / permanently destroys random weapon if weapons subsystems > 120% damage }
           begin
            j:=random(10)+1;
            if ship.gunnodes[j]>0 then
             begin
              ship.gunnodes[j]:=0;
              poweredup[j]:=-1;
              displayweapons;
             end;
           end;
          inc(ship.damages[DMG_WEAPONS],d);	{ damages[DMG_WEAPONS] = Weapons subsystem }
         end;
      4: inc(ship.damages[DMG_COMM],d);		{ damages[DMG_COMM] = Communications subsystem }
      5: inc(ship.damages[DMG_CPU],d);		{ damages[DMG_CPU] = CPU subsystem }
      6,7: dec(ship.hullintegrity,d);
     end;
  DMGTYP_FAKE_SHLD: inc(ship.damages[DMG_SHIELD],d);		{ damages[DMG_SHIELD] = Shield subsystem }
 end;
 for j:=1 to 7 do if ship.damages[j]>100 then ship.damages[j]:=100;
 if ship.hullintegrity<0 then ship.hullintegrity:=0;
 displaydamage;
 //writeln ('      hull=', ship.hullintegrity, ' shieldid=', ship.shield, ' damages: power=', ship.damages[DMG_POWER], ' shield=', ship.damages[DMG_SHIELD], ' weapons=', ship.damages[DMG_WEAPONS], ' engines=', ship.damages[DMG_ENGINES], ' life=', ship.damages[DMG_LIFESUPPORT], ' comm=', ship.damages[DMG_COMM], ' cpu=', ship.damages[DMG_CPU]);
 if ship.hullintegrity=0 then		{ hull breach - we're dead }
  begin
    if ship.wandering.alienid = 1013 then
    begin
       stopmod;
       blast(63,0,0);
       fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);
    end else begin
       deathsequence(0);
    end;
   done_:=true;
   dead:=true;
   {quit:=true;}
  end
 else if ship.damages[DMG_LIFESUPPORT]=100 then	{ damages [5] = Life support - we're dead }
  begin
    if ship.wandering.alienid = 1013 then
    begin
       stopmod;
       blast(63,0,0);
       fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);
    end else begin
       deathsequence(1);
    end;
   done_:=true;
   dead:=true;
   {quit:=true;}
  end;
 if ship.shield=ID_REFLECTIVEHULL then
  begin	// FIXME: shouldn't we do that for all shields if we are losing shield (shieldlevel > ship.damages[DMG_SHIELD])? otherwise we could have shield which has level higher than damaged subsystem allows!
     ship.shieldlevel := 100 - ship.damages[DMG_SHIELD]; { damages[DMG_SHIELD] is shield subsystem, drop shield level immedately if reflective hull }
     //writeln ('      reflective hull damage sets shieldlevel to ', ship.shieldlevel);
  end;
end;

{ s=ship attacking us; n=weapontype of ship attacking us }
procedure impact(s,n: integer);
var a,b,c,j,i: integer;
begin
 b:=ship.shield-ID_SHIELDS_OFFSET;	{ weapons[b]=our shield, weapons[n]=attacker's weapon; weapons[] array is generic for some type and readonly }
 assert (b>0);
 for j:=1 to 4 do if weapons[n].dmgtypes[j]>0 then	{ j=damage type: 1=Psionic, 2=Particle, 3=Intertial, 4=Energy }
  begin
   i:=round(weapons[n].dmgtypes[j]/100 * weapons[n].damage * 5); { pct. for this damagetype * total weapon damage in GJ }
       { QUESTION: why *5 ?!
         if some weapon has damage potential of 50GJ and 20% is for 'j' damage type, it should be 10GJ damage for this damage type, isn't it so?)
         yet putting DIRK as example does: impact: attacking weapon1 for dmgtype4=100% and its damage dealing=5GJ; THEIR CURRENT weapon subsystem damage=0 ; their attack total i=25

         ANSWER: Ah, it seems to because real alian weapons are not implemented, and we always do impact(j,maxweapons=72) in moveships().
         But aliens ships^[j].gunnodes has 5 positions, so this just simulates as all 5 weapons of type 72 fired all at once with same chances to hit.
         We could call it 5 times from there, but then we'd have 5 times as much sound effects in takedamage() unless we accounted for it.
       }
   i:=round(i/100*(100-ships^[s].damages[DMG_WEAPONS])); { damages[DMG_WEAPONS] is attacker weapons subsystem. If it is not damaged, 'i' remains as above, or is reduced appropriately }
   //writeln ('impact: attacker',s,' weapon',n, ' for dmgtype',j, '=', weapons[n].dmgtypes[j],'% and its damage dealing=', weapons[n].damage, 'GJ; THEIR CURRENT weapon subsystem damage=', ships^[s].damages[DMG_WEAPONS], '%   ; their attack total i=', i, 'GJ, batt=', ships^[s].battery);
   //writeln ('  our shield', ship.shield, ' has level=', ship.shieldlevel);
   if (ship.shieldlevel=0) or (ship.shield<=ID_NOSHIELD) or (weapons[b].dmgtypes[j]=0) then takedamage(j,i)	{ if no shield installed, or it is down, or that shield does not protect against that damagetype at all (like psi) - take full damage without affecting the shield}
   else
    begin		{ some shield is installed }
     a:=round(weapons[b].dmgtypes[j]/100 * weapons[b].damage * ship.shieldlevel/100); { a=how much damage will we resist in GJ = pct. for that dmgtype * total max shield protection * current shield level percentage }
     //writeln ('  shield', ship.shield, ' resist for dmgtype',j, '=', weapons[b].dmgtypes[j], '% of total shield damage absorption=', weapons[b].damage, 'GJ; OUR CURRENT shield subsystem damage=',ship.damages[DMG_SHIELD],'% current shield level=', ship.shieldlevel,'% (wanted:',ship.shieldopt[SHLD_COMBAT_WANT],')  ; our defense total a=', a, 'GJ');
     if a<i then
      begin		{ we've taken MORE damage than our shield can handle }
       //writeln ('    a<i: shield overload; taking residual damage for dmgtype',j,' = ', i-a, 'GJ');
       takedamage(j,i-a); {if weapon deals 90GJ of damage, and our shield absorbs 80GJ of damage, there will be 10GJ of pass-through damage }
       ship.shieldlevel:=0; { we've taken more damage than shields can handle, so set current level to zero (as it can't be negative). It will automatically slowly recover up to 100% or less if shield subsystem is damaged }
       if (ship.shield=ID_REFLECTIVEHULL) and (j>DMGTYP_PSIONIC) then ship.damages[DMG_SHIELD]:=100;	{ damages[DMG_SHIELD] is as shield subsystem; shield=ID_REFLECTIVEHULL is reflective hull (50GJ, no psionic defence, about 33% for each of the rest; but it does not use energy }
          { psionic damage just passes through reflective hull and inflict damage, but if any of the other damage types physically damages the reflective hull to zero or below, whole reflective hull collapses }
       displaydamage;
      end
     else
      begin		{ we've taken LESS damage than our shield can handle }
       a:=round((i/(ship.shieldlevel/100 *weapons[b].damage)*100));	{ pct current shield level * total shield protection in GJ }
       { what are we actually calculating here in a?! looks strange, but seems to work in practice...

        current_shield_protection = ship.shieldlevel/100 *weapons[b].damage;	// pct current shield level * total shield protection in GJ. But it does not take into account damagetype? because it just wants to move our shield slider which is one type only 0-100%?
        a := round (attacking_damage_in_GJ / current_shield_protection_in_GJ * 100 )
        a is by how much would shield level in PCT be reduced
       }
       c:=ship.shieldlevel-a; 		{ c will be our new ship.shieldlevel in pct }
       //writeln ('    shield still holding; shield protection a=', a, 'GJ, new shield level c=', c, '%');
       if c<0 then
        begin		{ shield would be reduced below zero }
         //writeln ('    Shield passing some damage afterall (total shield malfunction if reflective hull)');
         takedamage(DMGTYP_FAKE_SHLD,random(3)+1);	{ shield subsystem takes 1-3 damage }
         ship.shieldlevel:=0;
         if (ship.shield=ID_REFLECTIVEHULL) and (j>DMGTYP_PSIONIC) then ship.damages[DMG_SHIELD]:=100;
         displaydamage;
        end
       else
        begin		{ shield stays in positive }
         ship.shieldlevel:=c;
         if (ship.shield=ID_REFLECTIVEHULL) and (j>DMGTYP_PSIONIC) then	{ hit to reflective hull actually damages shield subsystem, as it is passive defense }
          begin
           //writeln ('    Shield stays above zero; reflective hull damage shield subsystem set to ', 100-c);
           ship.damages[DMG_SHIELD]:=100-c;
           displaydamage;
          end;
        end;
      end;
    end;
  end;
 displaystats;
end;

procedure moveships;
var r,rt: real;
    a,j: integer;
begin
 for j:=1 to nships do
  with ships^[j] do
  begin
   if (moveindex=5) and (hullintegrity>0) and (damages[DMG_ENGINES]<90) then
    begin
     if (relx<5000) and (relx>0) and (dx<-3000) then inc(dx,accelmax)
      else if (relx>-5000) and (relx<0) and (dx>3000) then dec(dx,accelmax)
      else if (relx>0) and (dx>-1000) then dec(dx,accelmax)
      else if (relx<0) and (dx<1000) then inc(dx,accelmax);
     if (rely<5000) and (rely>0) and (dy<-3000) then inc(dy,accelmax)
      else if (rely>-5000) and (rely<0) and (dy>3000) then dec(dy,accelmax)
      else if (rely>0) and (dy>-1000) then dec(dy,accelmax)
      else if (rely<0) and (dy<1000) then inc(dy,accelmax);
     if (relz<5000) and (relz>0) and (dz<-3000) then inc(dz,accelmax)
      else if (relz>-5000) and (relz<0) and (dz>3000) then dec(dz,accelmax)
      else if (relz>0) and (dz>-1000) then dec(dz,accelmax)
      else if (relz<0) and (dz<1000) then inc(dz,accelmax);
    end;
   if (moveindex=5) and (hullintegrity>0) and (damages[DMG_ENGINES]>90) then
   begin
      dx := round(dx * 0.9);
      dy := round(dy * 0.9);
      dz := round(dz * 0.9);
   end;
   relx:=relx+round(dx/5);
   rely:=rely+round(dy/5);
   relz:=relz+round(dz/5);
   rt:=(relx/10)*(relx/10);
   rt:=rt+(rely/10)*(rely/10);
   rt:=rt+(relz/10)*(relz/10);
   r:=sqrt(rt)*100;
//   writeln('ship ',j,' : ',r);
   a:=ship.accelmax;
   if ship.damages[DMG_ENGINES]>89 then a:=a div 4;
   if shipdir<4 then rely:=rely+a
    else if shipdir>6 then rely:=rely-a;
   if shipdir mod 3=1 then relx:=relx+a
    else if shipdir mod 3=0 then relx:=relx-a;
   if shipdir2=1 then relz:=relz-a
    else if shipdir2=2 then relz:=relz+a;
   part:=ships^[j].range;
   if hullintegrity>0 then
    for a:=1 to 20 do
     if (charges[a]=100) then
      begin
       if part>=r then
        begin
         i:=random(120)-15*ship.options[OPT_DIFFICULTY];
         {if (i<skill) or ((scanning) and (random(100)<20)) then}
	 if not SkillTest(True, 4, skill + (ord(scanning) * 20), learnchance) then
	 begin
           displaymap;
           if (ships^[j].damages[DMG_WEAPONS] < 100) and	{ enemy ship can only fire if it's weapons subsystem is not completely destroyed }
              (ships^[j].battery > 0) then	{ and it's battery is not completely deplated }
             impact(j,maxweapons);		{ j=enemyship, second param is weapon: currently always 72 "Alien weapon - debug" }
           //FIXME: realistically we should cycle through ships^[j].gunnodes[] -- but that would require tracking their energy, using power, AI for firing etc... and would produce 5 times as much sound effects.
           displaymap;
          end;
         charges[a]:=0;
        end;
      end;
   if (abs(r)>1200000) then
   begin
    hullintegrity:=0;
   end;
   if (hullintegrity=0) and (targetindex=j) then
    begin
     targetindex:=1;
     while (targetindex<=nships) and (ships^[targetindex].hullintegrity=0) do inc(targetindex);
     if targetindex>nships then
     begin
      done_:=true;
    end;
    end;
  end;
 if moveindex=5 then moveindex:=0 else inc(moveindex);
end;

procedure previoustarget;
begin
 displaymap;
 dec(targetindex);
 while (targetindex>0) and (ships^[targetindex].hullintegrity=0) do dec(targetindex);
 if (targetindex=0) then
  begin
   targetindex:=nships;
   while (targetindex>0) and (ships^[targetindex].hullintegrity=0) do dec(targetindex);
  end;
 displaymap;
end;

procedure nexttarget;
begin
 displaymap;
 inc(targetindex);
 while (targetindex<=nships) and (ships^[targetindex].hullintegrity=0) do inc(targetindex);
 if (targetindex>nships) or (ships^[targetindex].hullintegrity=0) then
  begin
   targetindex:=1;
   while (targetindex<nships) and (ships^[targetindex].hullintegrity=0) do inc(targetindex);
  end;
 displaymap;
end;

procedure switchalienmode;
begin
 mousehide;
 for i:=125 to 189 do
  scr_fillchar(screen[i,6],93,0);
 if not alienpicmode then
  begin
   for i:=156 to 189 do
    move(asdisplay^[i,6],screen[i,6],93);
   alienpicmode:=true;
  end
 else
  begin
   for i:=125 to 155 do
    move(asdisplay^[i,6],screen[i,6],93);
   alienpicmode:=false;
  end;
 mouseshow;
end;

procedure setdir(d: integer);
begin
 if ship.damages[DMG_ENGINES]>89 then exit;
 drawdirection(0);
 shipdir:=d;
 if d=5 then shipdir2:=0;
 drawdirection(63);
end;

procedure setdir2(d: integer);
begin
 if ship.damages[DMG_ENGINES]>89 then exit;
 drawdirection(0);
 shipdir2:=d;
 drawdirection(63);
end;

procedure findtarget;
var j: integer;
begin
 if (mouse.x<6) or (mouse.x>259) or (mouse.y<6) or (mouse.y>117) then exit;
 for j:=1 to nships do
  begin
   z:=round(ships^[j].relz/range*26);
   y:=62+round(ships^[j].rely/range*26.66)-z;
   x:=132+round(ships^[j].relx/range*119);
   if (abs(mouse.x-x)<5) and (abs(mouse.y-y)<5) and (ships^[j].hullintegrity>0) then
    begin
     displaymap;
     targetindex:=j;
     displaymap;
     displaytargetinfo;
     j:=nships;
    end;
  end;
end;

procedure displaytimedelay;
var
 s: string[3];
begin
 tcolor:=63;
 str(ship.options[OPT_TIMESLICE]:3,s);
 mousehide;
 printxy(277,2,s);
 mouseshow;
 tcolor:=95;
end;

procedure findmouse;
begin
 if not mouse.getstatus then exit;
 case mouse.x of
  105..125: case mouse.y of
             131..151: fireweapon:=1;
             152..156: if (mouse.x>108) and (mouse.x<122) then
                        begin
                         if userpowerup[1] then
                          begin
                           plainfadearea(109,152,121,154,32);
                           userpowerup[1]:=false;
                          end
                         else
                          begin
                           plainfadearea(109,152,121,154,-32);
                           userpowerup[1]:=true;
                          end;
                        end
                       else findtarget;
             157..161: if (mouse.x>108) and (mouse.x<122) then
                        begin
                         if userpowerup[6] then
                          begin
                           plainfadearea(109,159,121,161,32);
                           userpowerup[6]:=false;
                          end
                         else
                          begin
                           plainfadearea(109,159,121,161,-32);
                           userpowerup[6]:=true;
                          end;
                        end
                       else findtarget;
             162..182: fireweapon:=6;
             else findtarget;
            end;
  128..148: case mouse.y of
             131..151: fireweapon:=2;
             152..156: if (mouse.x>131) and (mouse.x<145) then
                        begin
                         if userpowerup[2] then
                          begin
                           plainfadearea(132,152,144,154,32);
                           userpowerup[2]:=false;
                          end
                         else
                          begin
                           plainfadearea(132,152,144,154,-32);
                           userpowerup[2]:=true;
                          end;
                        end
                       else findtarget;
             157..161: if (mouse.x>131) and (mouse.x<145) then
                        begin
                         if userpowerup[7] then
                          begin
                           plainfadearea(132,159,144,161,32);
                           userpowerup[7]:=false;
                          end
                         else
                          begin
                           plainfadearea(132,159,144,161,-32);
                           userpowerup[7]:=true;
                          end;
                        end
                       else findtarget;
             162..182: fireweapon:=7;
             else findtarget;
            end;
  151..171: case mouse.y of
             131..151: fireweapon:=3;
             152..156: if (mouse.x>154) and (mouse.x<168) then
                        begin
                         if userpowerup[3] then
                          begin
                           plainfadearea(155,152,167,154,32);
                           userpowerup[3]:=false;
                          end
                         else
                          begin
                           plainfadearea(155,152,167,154,-32);
                           userpowerup[3]:=true;
                          end;
                        end
                       else findtarget;
             157..161: if (mouse.x>154) and (mouse.x<168) then
                        begin
                         if userpowerup[8] then
                          begin
                           plainfadearea(155,159,167,161,32);
                           userpowerup[8]:=false;
                          end
                         else
                          begin
                           plainfadearea(155,159,167,161,-32);
                           userpowerup[8]:=true;
                          end;
                        end
                       else findtarget;
             162..182: fireweapon:=8;
             else findtarget;
            end;
  174..194: case mouse.y of
             131..151: fireweapon:=4;
             152..156: if (mouse.x>177) and (mouse.x<191) then
                        begin
                         if userpowerup[4] then
                          begin
                           plainfadearea(178,152,190,154,32);
                           userpowerup[4]:=false;
                          end
                         else
                          begin
                           plainfadearea(178,152,190,154,-32);
                           userpowerup[4]:=true;
                          end;
                        end
                       else findtarget;
             157..161: if (mouse.x>177) and (mouse.x<191) then
                        begin
                         if userpowerup[9] then
                          begin
                           plainfadearea(178,159,190,161,32);
                           userpowerup[9]:=false;
                          end
                         else
                          begin
                           plainfadearea(178,159,190,161,-32);
                           userpowerup[9]:=true;
                          end;
                        end
                       else findtarget;
             162..182: fireweapon:=9;
             191..195: if (mouse.x>183) then switchalienmode else findtarget;
             else findtarget;
            end;
  195..196: case mouse.y of
             191..195: switchalienmode;
             else findtarget;
            end;
  197..217: case mouse.y of
             131..151: fireweapon:=5;
             152..156: if (mouse.x>200) and (mouse.x<214) then
                        begin
                         if userpowerup[5] then
                          begin
                           plainfadearea(201,152,213,154,32);
                           userpowerup[5]:=false;
                          end
                         else
                          begin
                           plainfadearea(201,152,213,154,-32);
                           userpowerup[5]:=true;
                          end;
                        end
                       else findtarget;
             157..161: if (mouse.x>200) and (mouse.x<214) then
                        begin
                         if userpowerup[10] then
                          begin
                           plainfadearea(201,159,213,161,32);
                           userpowerup[10]:=false;
                          end
                         else
                          begin
                           plainfadearea(201,159,213,161,-32);
                           userpowerup[10]:=true;
                          end;
                        end
                       else findtarget;
             162..182: fireweapon:=10;
             191..195: if (mouse.x<209) then switchalienmode else findtarget;
             else findtarget;
            end;
  223..225: if (mouse.y>184) and (mouse.y<193) then previoustarget;
  226..242: case mouse.y of
             124..144: if range>5000 then
                        begin
                         displaymap;
                         dec(range,5000);
                         str(range*10:7,str1);
                         printxy(33,110,str1);
                         displaymap;
                        end;
             151..173: if not autofire then
                        begin
                         autofire:=true;
                         mousehide;
                         for i:=125 to 126 do
                          scr_fillchar(screen[i,163],52,63);
                         mouseshow;
                        end
                       else
                        begin
                         autofire:=false;
                         mousehide;
                         for i:=125 to 126 do
                          scr_fillchar(screen[i,163],52,95);
                         mouseshow;
                        end;
             185..192: if (mouse.x<241) then previoustarget;
               89..97: if mouse.x<237 then setdir(1) else setdir(2);
              99..107: if mouse.x<237 then setdir(4) else setdir(5);
             109..117: if mouse.x<237 then setdir(7) else setdir(8);
             else findtarget;
            end;
  244..260: case mouse.y of
             124..144: if range<5000000 then
                        begin
                         displaymap;
                         inc(range,5000);
                         str(range*10:7,str1);
                         printxy(33,110,str1);
                         displaymap;
                        end;
             151..173: if not scanning then
                        begin
                         scanning:=true;
                         mousehide;
                         for i:=187 to 188 do
                          scr_fillchar(screen[i,163],52,63);
                         mouseshow;
                        end
                       else
                        begin
                         scanning:=false;
                         mousehide;
                         for i:=187 to 188 do
                          scr_fillchar(screen[i,163],52,95);
                         mouseshow;
                        end;
             185..192: if (mouse.x>245) then nexttarget;
               69..77: if mouse.x>248 then setdir2(1);
               79..87: if mouse.x>248 then setdir2(2);
               89..97: if mouse.x<249 then setdir(2) else setdir(3);
              99..107: if mouse.x<249 then setdir(5) else setdir(6);
             109..117: if mouse.x<249 then setdir(8) else setdir(9);
             else findtarget;
            end;
  261..263: if (mouse.y>184) and (mouse.y<193) then nexttarget else findtarget;
  271..279: if (mouse.y<10) and (ship.options[OPT_TIMESLICE]>1) then
             begin
              dec(ship.options[OPT_TIMESLICE]);
              tslice:=ship.options[OPT_TIMESLICE];
              displaytimedelay;
             end;
  291..312: case mouse.y of
             11..117: displayshieldpic(round((117-mouse.y)*100/102));
             1..9: if (mouse.x>299) and (mouse.x<309) and (ship.options[OPT_TIMESLICE]<255) then
                    begin
                     inc(ship.options[OPT_TIMESLICE]);
                     tslice:=ship.options[OPT_TIMESLICE];
                     displaytimedelay;
                    end;
            end;
  else findtarget;
 end;
end;

procedure processkey;
var ans: char;
begin
 ans:=readkey_nomap;
 case upcase(ans) of
   #0: begin
        ans:=readkey;
        case ans of
         #71: setdir(1); { home }
         #72: setdir(2); { up }
         #73: setdir(3); { PgUp }
         #75: setdir(4); { left }
         #77: setdir(6); { right }
         #79: setdir(7); { end }
         #80: setdir(8); { down }
         #81: setdir(9); { PgDn}
         #59: if range>5000 then	{ F1 - zoom in}
               begin
                displaymap;
                dec(range,5000);
                str(range*10:7,str1);
                printxy(33,110,str1);
                displaymap;
               end;
         #60: if range<5000000 then	{ F2 - zoom out}
               begin
                displaymap;
                inc(range,5000);
                str(range*10:7,str1);
                printxy(33,110,str1);
                displaymap;
               end;
         #61: if not autofire then	{ F3 - Active Fire (autofire) }
               begin
                autofire:=true;
                mousehide;
                for i:=125 to 126 do
                 scr_fillchar(screen[i,163],52,63);
                mouseshow;
               end
              else
               begin
                autofire:=false;
                mousehide;
                for i:=125 to 126 do
                 scr_fillchar(screen[i,163],52,95);
                mouseshow;
               end;
         #62: if not scanning then	{ F4 - Active Radar}
               begin
                scanning:=true;
                mousehide;
                for i:=187 to 188 do
                 scr_fillchar(screen[i,163],52,63);
                mouseshow;
               end
              else
               begin
                scanning:=false;
                mousehide;
                for i:=187 to 188 do
                 scr_fillchar(screen[i,163],52,95);
                mouseshow;
               end;
         #16,#45: begin
	    if yesnorequest('Do you want to quit?',0,31) then
	    begin
	       quit:=true;
	       done_:=true;
	       {dead:=true;}
	    end;
	    tcolor:=95;
	    bkcolor:=0;
	 end;
	end; { case }
   end;
  '-': setdir2(1);
  '+': setdir2(2);
  '7': setdir(1);
  '8': setdir(2);
  '9': setdir(3);
  '4': setdir(4);
  '5', #13: setdir(5);
  '6': setdir(6);
  '1': setdir(7);
  '2': setdir(8);
  '3': setdir(9);
  'Z': displayshieldpic(max(0, ship.shieldopt[SHLD_COMBAT_WANT] - 10));	{ 'Z' - shield level down }
  'X': displayshieldpic(min(100, ship.shieldopt[SHLD_COMBAT_WANT] + 10));	{ 'X' - shield level up }
  ' ': switchalienmode;
  '<',',': previoustarget;
  '>','.': nexttarget;
  '`': bossmode;
  'Q': fireweapon:=1;
  'W': fireweapon:=2;
  'E': fireweapon:=3;
  'R': fireweapon:=4;
  'T': fireweapon:=5;
  'A': fireweapon:=6;
  'S': fireweapon:=7;
  'D': fireweapon:=8;
  'F': fireweapon:=9;
  'G': fireweapon:=10;
 end;
end;

procedure mainloop;
var index,cindex: integer;
begin
 index:=0;
 cindex:=0;
 displaymap;
 repeat
  fadestep(FADESTEP_STEP);
  findmouse;
  if fastkeypressed then processkey;
  inc(index);
  if index=8 then
   begin
    suckpower;
    index:=0;
    displaymap;
    moveships;
    displaymap;
   end;
  displaystats;
  displaytargetinfo;
  powerup;
  if not done_ then
  begin
     if cindex<16 then i:=cindex+32 else i:=64-cindex;
     setrgb256(i,0,0,colors[i,3]);
     if cindex<31 then inc(cindex) else cindex:=0;
     if cindex<16 then i:=cindex+32 else i:=64-cindex;
     setrgb256(i,0,0,63);
     delay(tslice*FADE_TSLICE_MUL_COMBAT);
  end;
 until done_;
   if not quit then
   begin
      wait(1);
      set256colors(colors);
   end;
end;

procedure getshipinfo(n,j: integer);
var f: file of alienshiptype;
    i: integer;
begin
 case ship.wandering.alienid of
     1..999: i:=0;
  1000..1007: i:=ship.wandering.alienid-1000;
        1009: i:=8;
        1010: i:=9;
        1013: i:=10;  { drones }
  else errorhandler('Invalid alien ship ID.',6);
 end;
 if i=10 then picy:=0 else picy:=i*20;
 assign(f,'data/ships.dta');
 reset(f);
 if ioresult<>0 then errorhandler('ships.dta',1);
 seek(f,j+i*11);
 if ioresult<>0 then errorhandler('ships.dta',5);
 read(f,ships^[n]);
 if ioresult<>0 then errorhandler('ships.dta',5);
 close(f);
 with ships^[n] do
 case j of
   0..6: picx:=j*20;
   7: picx:=140;
   8: picx:=180;
   9: picx:=220;
  10: picx:=260;
 end;
end;

procedure readyships;
var f: file of alientype;
    t: alientype;
    form,index,c: integer;
    basex,basey,basez: longint;
begin
 nships:=0;
   learnchance := 100;
 if ship.wandering.alienid=1013 then
 begin
    learnchance := 5;
   t.name:='Drone';
   t.victory:=(ship.options[OPT_DIFFICULTY]+1)*10;
  end
 else
  begin
   assign(f,tempdir+'/contacts.dta');
   reset(f);
   if ioresult<>0 then errorhandler(tempdir+'/contacts.dta',1);
   repeat
    read(f,t);
    if ioresult<>0 then errorhandler(tempdir+'/contacts.dta',5);
   until t.id=ship.wandering.alienid;
   close(f);
  end;
 tcolor:=95;
 alienname:=t.name;
 printxy(3,10,alienname);
 if (showplanet) and (tempplan^[curplan].system=182) then a:=300 else a:=t.victory;
 if a=0 then a:=1;
 index:=4;
 form:=random(maxformations);
 repeat
  inc(nships);
  with ships^[nships] do
   begin
    if a>75 then c:=10
    else if a<11 then c:=random(a)
     else c:=random(6)+5;
    getshipinfo(nships,c);
    dec(a,c+1);
    if index<4 then inc(index) else
     begin
      basex:=100*random(600);                                //WTF?  too far away  was  basex:=10000*random(6000);
      if random(2)=0 then basex:=-basex;
      basey:=100*random(600);
      if random(2)=0 then basey:=-basey;
      basez:=100*random(600);
      if random(2)=0 then basez:=-basez;
      index:=0;
     end;
    relx:=basex+formation[form,index,1];
    rely:=basey+formation[form,index,2];
    relz:=basez+formation[form,index,3];
    if (shield<=ID_REFLECTIVEHULL) then shieldlevel:=100;
   end;
 until (nships=maxships) or (a=0);
end;

procedure readydata;
var
   j : Integer;
begin
   mousehide;
   compressfile(tempdir+'/current',@screen);
   {fading;}
   fadestopmod(-FADEFULL_STEP, FADEFULL_DELAY);
   playmod(true,'sound/COMBAT.MOD');
   loadscreen('data/fight',@screen);
   loadscreen('data/cloud',backgr);
   done_:=false;
   new(ships);
   new(statpic);
   new(blank);
   new(asdisplay);
   new(shieldpic);
   new(shieldpic2);
   new(msgs);
   for i:=10 to 11 do
      scrfrom_move(screen[i,71],statpic^[i-10],10);
   for i:=26 to 27 do
      scrfrom_move(screen[i,269],blank^[i-26],10);
   for i:=0 to 6 do
      scrfrom_move(screen[i+10,91],shieldpic^[i],1*4);
   for i:=0 to 6 do
      scrfrom_move(screen[i+10,101],shieldpic2^[i],1*4);
   for j:=0 to 3 do
      for i:=0 to 9 do
	 scrfrom_move(screen[i+10,110+j*10],msgs^[j,i],10);
   for i:=9 to 20 do
      scr_fillchar(screen[i,71],177,0);
   displaytimedelay;
   tcolor:=95;
   bkcolor:=0;
   oldt1:=t1;
   targetindex:=1;
   if ship.options[OPT_DIFFICULTY]=0 then
   begin
      autofire:=true;
      scanning:=true;
      for i:=125 to 126 do
	 scr_fillchar(screen[i,163],52,63);
      for i:=187 to 188 do
	 scr_fillchar(screen[i,163],52,63);
   end
   else
   begin
      autofire:=false;
      scanning:=false;
      for i:=125 to 126 do
	 scr_fillchar(screen[i,163],52,95);
      for i:=187 to 188 do
	 scr_fillchar(screen[i,163],52,95);
   end;
   for i:=9 to 117 do
      for j:=6 to 260 do
	 if screen[i,j]=0 then screen[i,j]:=backgr^[i,j];
   loadscreen('data/waricon',backgr);
   stats[1]:=0;
   stats[2]:=0;
   stats[3]:=0;
   oldshddmg:=20;
   shipdir:=5;
   shipdir2:=0;
   fireweapon:=0;
   moveindex:=0;
   engaging:=false;
   alienpicmode:=false;
   dead:=false;
   range:=60000;
   printxy(33,110,' 600000 KM.R.');
   for j:=1 to 10 do
   begin
      poweredup[j]:=-1;
      if ship.armed then poweredup[j]:=99 else poweredup[j]:=0;
      if ship.gunnodes[j]=0 then poweredup[j]:=-1;
   end;
   for i:=125 to 189 do
      scrfrom_move(screen[i,6],asdisplay^[i],93);
   for i:=137 to 189 do
      scr_fillchar(screen[i,6],93,0);
   for j:=1 to 3 do stats[j]:=0;
   displayweapons;
   displaystats;
   displaydamage;
   drawdirection(63);
   displayshieldpic(ship.shieldopt[SHLD_COMBAT_WANT]);
   readyships;
   displaytargetinfo;
   mouseshow;
   for j:=1 to 10 do
      if not userpowerup[j] then
      begin
	 x:=((j-1) mod 5)*23;
	 y:=((j-1) div 5)*7;
	 plainfadearea(109+x,152+y,121+x,154+y,32);
      end;
   {fadein;}
end;

procedure savevictories;
var f : file of alientype;
   t  : alientype;
   j  : Integer;
begin
 assign(f,tempdir+'/contacts.dta');
 reset(f);
 if ioresult<>0 then errorhandler(tempdir+'/contacts.dta',1);
 i:=-1;
 repeat
  inc(i);
  read(f,t);
  if ioresult<>0 then errorhandler(tempdir+'/contacts.dta',4);
 until t.id=ship.wandering.alienid;
 seek(f,i);
 if ioresult<>0 then errorhandler(tempdir+'/contacts.dta',4);
 i:=nships div 4;
 if i=0 then i:=1;
 inc(t.victory,i);
 i:=0;
 for j:=1 to 7 do i:=i+ship.damages[j];
 if i=0 then inc(t.victory,nships);
 if t.anger<200 then inc(t.anger)
 else if t.congeniality>0 then dec(t.congeniality);
 if t.victory>20000 then t.victory:=20000;
 write(f,t);
 if ioresult<>0 then errorhandler(tempdir+'/contacts.dta',4);
 close(f);
end;

procedure aftereffects;
var
   cargoitems : array[0..13] of integer;
   j	      : Integer;
begin
 playmod(true,'sound/VICTORY.MOD');
 mousehide;
 for i:=9 to 117 do
  scr_fillchar(screen[i,6],254,0);
 for i:=125 to 189 do
  scr_fillchar(screen[i,6],93,0);
 tcolor:=95;
 printxy(18,8,'VICTORY!');
 mouseshow;
 if yesnorequest('DEPLOY SCAVENGER BOTS?',0,31) then
  begin
   tcolor:=22;
   bkcolor:=0;
   mousehide;
   printxy(18,18,'SCAVENGER BOTS DEPLOYED...');
   mouseshow;
   tcolor:=28;
   cargoitems[0]:=0;				// to turn off warnings, variables are actually correctly initialized by function below
   fillchar(cargoitems,sizeof(cargoitems),0);
   i:=random(nships);
   if i>13 then i:=13;
   a:=1;
   while cargo[a].index<>ID_UNKNOWN_COMPONENT do inc(a);
   for j:=0 to i do
    begin
     cargoitems[j]:=random(21);
     mousehide;
     printxy(24,28+j*6,cargo[a+cargoitems[j]].name);
     mouseshow;
     addcargo2(cargoitems[j]+ID_UNKNOWN_COMPONENT, true);
    end;
   while fastkeypressed do readkey;
   repeat
   until (fastkeypressed) or (mouse.getstatus);
   while fastkeypressed do readkey;
  end;
 savevictories;
end;

procedure initiatecombat;
begin
 readydata;
 mainloop;
 loadscreen('data/cloud',backgr);
 if ((tempplan^[curplan].state=6) and (tempplan^[curplan].mode=2)) then makeastoroidfield
  else if (tempplan^[curplan].state=0) and (tempplan^[curplan].mode=1) then makecloud;
 dispose(msgs);
 dispose(statpic);
 dispose(blank);
 dispose(ships);
 dispose(asdisplay);
 dispose(shieldpic);
 dispose(shieldpic2);
 if (not engaging) and (not dead) and (ship.wandering.alienid<1013) then aftereffects;
 stopmod;
 removedata;
 if (engaging) and (targetready) then
  engage(systems[nearby[target].index].x,systems[nearby[target].index].y,systems[nearby[target].index].z)
 else if engaging then
  begin
   targetready:=true;
   engage(ship.posx-10+random(20),ship.posy-10+random(20),ship.posz-10+random(20));
  end;
end;
var
   j : Integer;
begin
 for j:=1 to 10 do userpowerup[j]:=true;
end.
