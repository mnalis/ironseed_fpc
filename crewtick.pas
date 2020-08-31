unit crewtick;
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

{$O+}
{$I-}
interface
procedure GameTick(background : Boolean; ticks : Integer);
function SkillTest(background : Boolean; crew, difficulty, learn : Integer): Boolean;
function SkillRange(background : Boolean; crew, difficulty, learn : Integer): Integer;
function PerformanceRange(background : Boolean; crew, difficulty : Integer): Integer;
function SanityTest(background : Boolean; crew, difficulty : Integer): Boolean;
function ComputeSkill(crew : Integer): Integer;
function ComputePerformance(crew : Integer): Integer;
function ComputeSanity(crew : Integer): Integer;
procedure DayTick(background	: Boolean);
procedure ResetCrew;

implementation
uses data, utils, utils2, journey, weird, cargtool, utils_;
var
   lastalienid : Integer;
   
   Function Sign(value: Integer):Integer;
   begin
      if value < 0 then
	 Sign := -1
      else if value > 0 then
	 Sign := 1
      else
	 Sign := 0;
   end;


   procedure tempinsanity(n: integer);
   var
      i	: integer;
      s	: string[80];
   begin
      set256colors(colors);
      if (random(5)>0) then exit;
      i:=random(19);
      case i of
	0  : s:='Out of memory error on brain '+chr(n+64)+'.';
	1  : s:='Brain '+chr(n+64)+' not a supported device.';
	2  : s:='Read error on brain '+chr(n+64)+' incompatible media.';
	3  : s:='CRC checksum error on brain '+chr(n+64)+'.';
	4  : s:='Brain '+chr(n+64)+' has been upgraded to patch level 3.';
	5  : s:='Segmentation error on brain '+chr(n+64)+'. Reboot?';
	6  : s:='Mentation error, corpse dumped.';
	7  : s:='Network error on brain '+chr(n+64)+'. Abandom, Retry, Apologize?';
	8  : s:='Brain '+chr(n+64)+' is not a system brain.';
	9  : s:='Runtime error in LIFE.BIN.';
	10 : s:='Runtime error 226 in LIFE.BIN exceeded 10.';
	11 : s:='Divide by zero error in brain '+chr(n+64)+'.';
	12 : s:='Write protection fault on core sector 02AF'+chr(n+64)+'.';
	13 : s:='Runtime error 1 in program CHECKING.BIN.';
	14 : s:='Underflow error in CHECKING.EXE.';
	15 : s:='Overflow in TOWELETBOWEL.EXE. Flush stack?';
	16 : s:='Interrupt vector table restored.';
	17 : s:='Default settings.';
	18 : s:='Power fluxuation detected on brain '+chr(n+64)+'.';
      end; 
      showchar(n,s);
   end; { tempinsanity }

   procedure SanityFailure(background : Boolean; crew : Integer);
   var
      i	: Integer;
   begin
      assert(background or not background);	{ just ignore warnings }
      with ship.crew[crew] do
      begin
	 if (men < 10) or (emo < 10) or (phy < 10) then
	    tempinsanity(crew);
	 i := random(8);
	 if ((i and 1) > 0) and (men > 0) then
	    dec(men);
	 if ((i and 2) > 0) and (phy > 0) then
	    dec(phy);
	 if ((i and 4) > 0) and (emo > 0) then
	    dec(emo);
      end;
   end;

   procedure CrewStress(background : Boolean; crew, difficulty : Integer);
   var
      dif : Integer;
   begin
      with ship.crew[crew] do
      begin
	 dif := difficulty - perf;
	 if not SanityTest(background, crew, dif) then
	 begin
	    if status < 99 then
	       inc(status);
	 end;
      end;
   end; { CrewStress }

   function SanityTest(background : Boolean; crew, difficulty : Integer): Boolean;
   var
      snt, dif : Integer;
   begin
      assert(background or not background);	{ just ignore warnings }
      with ship.crew[crew] do
	 begin
	    snt := san;
	    dif := difficulty;
	    if snt <= 5 then
	       snt := 5;
	    if dif <= 0 then
	       dif := 1;
	 if random(snt + dif) < snt then
	    SanityTest := True
	 else
	    SanityTest := False;
	 end;
   end; { SanityTest }

   function PerformanceTest(background : Boolean; crew, difficulty : Integer): Boolean;
   var
      per, dif : Integer;
   begin
      assert(background or not background);	{ just ignore warnings }
      with ship.crew[crew] do
      begin
	 per := perf;
	 dif := difficulty;
	 if per <= 5 then
	    per := 5;
	 if dif <= 0 then
	    dif := 1;
	 if random(per + dif) < per then
	    PerformanceTest := True
	 else
	    PerformanceTest := False;
      end;
   end; { PerformanceTest }

   function PerformanceRange(background : Boolean; crew, difficulty : Integer): Integer;
   var
      per, dif : Integer;
   begin
      assert(background or not background);	{ just ignore warnings }
      with ship.crew[crew] do
      begin
	 per := perf;
	 dif := difficulty;
	 if per <= 5 then
	    per := 5;
	 if dif <= 0 then
	    dif := 1;
	 PerformanceRange := random(per) - random(dif);
      end;
   end; { PerformanceRange }

   function SkillTest(background : Boolean; crew, difficulty, learn : Integer): Boolean;
   var
      ski, dif : Integer;
   begin
      with ship.crew[crew] do
	 begin
	    ski := skill;
	    dif := difficulty;
	    if ski <= 5 then
	       ski := 5;
	    if dif <= 0 then
	       dif := 1;
	    if random(ski + dif) < ski then
	    begin
	       SkillTest := True;
	       CrewStress(background, crew, 0);
	    end else begin
	       SkillTest := False;
	       CrewStress(background, crew, abs(dif - ski));
	    end;
	 end;
      if random(1000) < learn then
	 addxp(crew, difficulty, ord(not background));
   end; { SkillTest }

   function SkillRange(background : Boolean; crew, difficulty, learn : Integer): Integer;
   var
      ski, dif : Integer;
   begin
      with ship.crew[crew] do
      begin
	 ski := skill;
	 dif := difficulty;
	 if ski <= 5 then
	    ski := 5;
	 if dif <= 0 then
	    dif := 1;
	 SkillRange := random(ski) - random(dif);
      end;
      CrewStress(background, crew, 100 * dif div ski);
      if random(1000) < learn then
	 addxp(crew, difficulty, ord(not background));
   end; { SkillTest }


   procedure CrewMessage(background : Boolean; colour, crew : Integer; msg : String);
   var
      oldcolour	: Integer;
   begin
      if background then
      begin
	 oldcolour := tcolor;
	 tcolor := colour;
	 showchar(crew, msg);
	 tcolor := oldcolour;
      end else begin
	 oldcolour := tcolor;
	 tcolor := colour;
	 println;
	 print(crewtitles[crew] + ': ' + msg);
	 tcolor := oldcolour;
      end;
      
	 
   end; { CrewMessage }

   procedure ShipTick(background : Boolean);
   begin
      if ship.shield>ID_REFLECTIVEHULL then
	 ship.battery:=ship.battery-round(weapons[ship.shield-ID_SHIELDS_OFFSET].energy/100*ship.shieldlevel);
      if ship.battery<31980 then ship.battery:=ship.battery+round((100-ship.damages[DMG_POWER])/4)
      else ship.battery:=32000;
      if ship.battery<0 then
      begin
	 CrewMessage(background, 94, 0, 'Secondary power failure...Shields powering down...');
	 ship.shieldlevel:=0;
	 ship.battery:=0;
      end;
   end; { ShipTick }

   procedure PsyTick(background : Boolean);
   var
      i, d : Integer;
   begin
      for i := 1 to 6 do
	 with ship.crew[i] do
	 begin
	    d := 0 - status;
	    if (d <> 0) and (random(2) = 0) and SkillTest(background, 1, 99 - abs(d), 10) then
	       status := status + Sign(d);
	 end;
   end; { PsyTick }

   procedure EngBuildFinish(background : Boolean; team : Integer);
   var
      a, b, i: Integer;
      s: String[20];
   begin
      with ship.engrteam[team] do
      begin
	 dec(timeleft,5);
	 if SkillTest(background, 2, 40, 10) then
	    if SkillTest(background, 2, 40, 10) then
	       dec(timeleft, 10)
	    else
	       dec(timeleft, 5);
	 {if (random(10) = 0) and SkillTest(background, 2, 40, 10) then
	    inc(extra, 256);
	 if (extra shr 8) > (extra and 255) then}
	 if (timeleft < 1) then
	 begin
	    RebuildCargoReserve;
	    case job of
	      ID_FUEL_NODULES : ship.fuel:=ship.fuelmax;
	      ID_REINFORCE_HULL : begin
			     i:=ship.hullmax+25;
			     if i>5000 then
				if background then
				   addcargo2(ID_REINFORCE_HULL, true)
				else
				   addcargo(ID_REINFORCE_HULL, true)
			     else begin
				inc(ship.hullmax,15);
				CrewMessage(background, 31, 2,'	Hull reinforced.');
			     end;
			  end;
	      ID_INCREASE_THRUST : begin
			     i:=ship.accelmax+10;
			     if i>1100 then
				if background then
				   addcargo2(ID_INCREASE_THRUST, true)
				else
				   addcargo(ID_INCREASE_THRUST, true)
			     else begin
				inc(ship.accelmax,10);
				CrewMessage(background, 31, 2,'Acceleration increased.');
			     end;
			  end;
	      ID_ADD_CARGO_SPACE : begin
			     i:=ship.cargomax+75;
			if i>20000 then
			   if background then
			      addcargo2(ID_ADD_CARGO_SPACE, true)
			   else
			      addcargo(ID_ADD_CARGO_SPACE, true)
			else begin
			   inc(ship.cargomax,75);
			   CrewMessage(background, 31, 2,'Cargo space increased.');
			end;
		     end;
	      ID_INSTALL_GUN_NODE : begin
			addgunnode;
			CrewMessage(background, 31, 2,'Weapon Node Assembled.');
		     end;
	      ID_MIND_ENHANCERS : begin
			a:=ship.crew[1].men;
			b:=1;
			for i:=1 to 6 do
			begin
			   if ship.crew[i].emo<a then
			   begin
			      a:=ship.crew[i].emo;
			      b:=i;
			   end;
			   if ship.crew[i].phy<a then
			   begin
			      a:=ship.crew[i].phy;
			      b:=i;
			   end;
			   if ship.crew[i].men<a then
			   begin
			      a:=ship.crew[i].men;
			      b:=i;
			   end;
			end;
			if ship.crew[b].emo=a then
			begin
			   inc(ship.crew[b].emo,15);
			   if ship.crew[b].emo>99 then ship.crew[b].emo:=99;
			end
			else if ship.crew[b].phy=a then
			begin
			   inc(ship.crew[b].phy,15);
			   if ship.crew[b].phy>99 then ship.crew[b].phy:=99;
			end
			else if ship.crew[b].men=a then
			begin
			   inc(ship.crew[b].men,15);
			   if ship.crew[b].men>99 then ship.crew[b].men:=99;
			end;
			s:=ship.crew[b].name;
			while (s[length(s)]=' ') do dec(s[0]);
			CrewMessage(background, 31, b,'Mind Drugs administered to '+s+'.');
		     end;
	    else begin
	       if background then
		  addcargo2(job, true)
	       else
		  addcargo(job, true);
	       if not ((extra = 0) or (job = extra)) then
	       begin
		  jobtype := JOBTYPE_REPAIR;
		  timeleft := 0;
		  job := 0;
		  RebuildCargoReserve;
		  i := StartBuild(background, extra, extra, team);
		  case i of
		    0  : CrewMessage(background, 31, 2, 'Insufficent parts to continue ' + CargoName(extra) + '.');
		    -1,-3 : CrewMessage(background, 31, 2, 'Insufficent expertise to finish ' + CargoName(extra) + '.');
		    -2 : CrewMessage(background, 31, 2, 'Internal error trying to build: ' + CargoName(extra) + '.');
		  end;
		  exit;
	       end
	    end;
	    end;
	    jobtype:=JOBTYPE_REPAIR;
	    timeleft:=0;
	    if job<>ID_MIND_ENHANCERS then CrewMessage(background, 31, 2,'Synthesis of '+CargoName(job)+' completed, sir!');
	    job:=0;
	 end
	 else if timeleft=0 then timeleft:=5;
      end;
   end; { EngBuildFinish }

   procedure EngDisassembleFinish(background : Boolean; item : Integer);
   var cfile : file of createarray;
      temp   : ^createarray;
      j,i    : integer;
   begin     
      new(temp);
      assign(cfile,'data/creation.dta');
      reset(cfile);
      if ioresult<>0 then errorhandler('creation.dta',1);
      read(cfile,temp^);
      if ioresult<>0 then errorhandler('creation.dta',5);
      close(cfile);
      i:=1;
      while (temp^[i].index<>item) and (i<=totalcreation) do inc(i);
      if i>totalcreation then errorhandler('Disassemble error!',6);
      for j:=1 to 3 do
	 {if not skillcheck(2) then addcargo(ID_WORTHLESS_JUNK)
	 else}
	 if background then
	    addcargo2(temp^[i].parts[j], true)
	 else
	    addcargo(temp^[i].parts[j], true);
      dispose(temp);
   end; { EngDisassembleFinish }

   procedure EngTick(background : Boolean);
   var
      i, j, a		: integer;
      nextjob, nexttime	: integer;
   begin
      for j:=1 to 3 do
	 with ship.engrteam[j] do
	    case jobtype of
	      JOBTYPE_REPAIR :
		 if (job<8) and (job>0) then
		 begin
		    dec(timeleft, 5);
		    {if random(17)=0 then}
		    if (random(4) = 0) and SkillTest(background, 2, 40, 10) and SkillTest(background, 2, 40, 10) then
		    begin
		       if ship.damages[job]>0 then
		       begin
			  dec(ship.damages[job]);
			  if timeleft>5 then dec(timeleft,5);
		       end;
		       if ship.damages[job]=0 then
		       begin
			  nextjob := 0;
			  nexttime := 0;
			  for i := 1 to 8 do
			  begin
			     if (i = 8) and (ship.hullintegrity < ship.hullmax) then
			     begin
				nextjob := 8;
				nexttime := (ship.hullmax - ship.hullintegrity) * 30;
			     end
			     else
				if ship.damages[i] > 0 then
				begin
				   nextjob := i;
				   nexttime := ship.damages[i] * 70;
				   break;
				end;
			  end;
			  for i:=1 to 3 do
			     if (i<>j) and (ship.engrteam[i].jobtype=JOBTYPE_REPAIR) and (ship.engrteam[i].job=job) then
			     begin
				ship.engrteam[i].timeleft:=nexttime;
				ship.engrteam[i].job:=nextjob;
			     end;
			  timeleft := nexttime;
			  CrewMessage(background, 31, 2, repairname[job]+' repaired, sir!');
			  job := nextjob;
		       end;
		    end;
		 end
		 else if job=8 then
		 begin
		    dec(timeleft,5);
		    {if random(8)=0 then}
		    if (random(2) = 0) and SkillTest(background, 2, 40, 10) and SkillTest(background, 2, 40, 10) then
		    begin
		       if ship.hullintegrity<ship.hullmax then
		       begin
			  inc(ship.hullintegrity);
			  if timeleft>5 then dec(timeleft,5);
		       end;
		       if ship.hullintegrity=ship.hullmax then
		       begin
			  nextjob := 0;
			  nexttime := 0;
			  for i := 1 to 7 do
			  begin
			     if ship.damages[i] > 0 then
			     begin
				nextjob := i;
				nexttime := ship.damages[i] * 70;
				break;
			     end;
			  end;
			  for i:=1 to 3 do
			     if (i<>j) and (ship.engrteam[i].jobtype=JOBTYPE_REPAIR) and (ship.engrteam[i].job=job) then
			     begin
				ship.engrteam[i].timeleft:=nexttime;
				ship.engrteam[i].job:=nextjob;
			     end;
			  CrewMessage(background, 31, 2,'Hull damage repaired, sir!');
			  job:=nextjob;
			  timeleft:=nexttime;
		       end;
		    end;
		 end;
	      JOBTYPE_INSTALL, JOBTYPE_REMOVE :
	         if job<ID_NOSHIELD then
		 begin
		    dec(timeleft,5);
		    if (random(2) = 0) and SkillTest(background, 2, 40, 10) then
		       inc(extra, 16);
		    {if random(220)=0 then}
		    if extra >= 110 * 16 then
		    begin
		       timeleft:=0;
		       if jobtype=JOBTYPE_INSTALL then ship.gunnodes[extra and 15]:=job-ID_DIRK+1;
		       if jobtype=JOBTYPE_REMOVE  then CrewMessage(background, 31, 2, 'Weapon removed, sir!')
		       else CrewMessage(background, 31, 2,'weapon installed, sir!');
		       job:=0;
		       jobtype:=JOBTYPE_REPAIR;
		    end;
		 end
		 else begin
		    dec(timeleft,5);
		    if random(220)=0 then
		    begin
		       timeleft:=0;
		       if jobtype=JOBTYPE_INSTALL then ship.shield:=job;
		       if jobtype=JOBTYPE_REMOVE then CrewMessage(background, 31, 2, 'Shield removed, sir!')
		       else
		       begin
			  CrewMessage(background, 31, 2,'Shield installed, sir!');
			  if job>ID_REFLECTIVEHULL then
			  begin
			     ship.shieldopt[SHLD_COMBAT_WANT]:=100;
			     ship.shieldopt[SHLD_ALERT_WANT]:=40;
			     ship.shieldopt[SHLD_LOWERED_WANT]:=10;
			  end
			  else for a:=1 to 3 do ship.shieldopt[a]:=100-ship.damages[DMG_SHIELD];
		       end;
		       job:=0;
		       jobtype:=JOBTYPE_REPAIR;
		    end;
		 end;
	      JOBTYPE_CREATE	  :
		   EngBuildFinish(background, j);
	      JOBTYPE_DECOMPOSE	  : begin
		       dec(timeleft,5);
		       if SkillTest(background, 2, 40, 10) then
			  if SkillTest(background, 2, 40, 10) then
			     dec(timeleft, 10)
			  else
			     dec(timeleft, 5);
		       {if (random(10) = 0) and SkillTest(background, 2, 40, 10) then
			  inc(extra, 256);
		       if (extra shr 8) > (extra and 255) then}
		       if (timeleft<1) then
		       begin
			  EngDisassembleFinish(background, job);
			  timeleft:=0;
			  job:=0;
			  jobtype:=JOBTYPE_REPAIR;
			  CrewMessage(background, 31, 2,'Disassmebling completed, sir!');
		       end;
		    end;
	      JOBTYPE_RESEARCH	  : begin
		       dec(timeleft,5);
		       if SkillTest(background, 2, 40, 10) then
			  if SkillTest(background, 2, 40, 10) then
			     dec(timeleft, 10)
			  else
			     dec(timeleft, 5);
		       {if (random(10) = 0) and SkillTest(background, 2, 40, 10) then
			  inc(extra, 256);
		       if ((extra shr 8) > (extra and 255)) and (job<>ID_ART_SHUNT_DRIVE) then}
		       {job ID_ART_SHUNT_DRIVE (the shunt drive) needs to be defered until the main screen is up.}
		       if (timeleft<1) and ((job<>ID_ART_SHUNT_DRIVE) or (not background)) then
		       begin
			  timeleft:=0;
			  jobtype:=JOBTYPE_REPAIR;
			  CrewMessage(background, 31, 2,'Artifact research completed, sir!');
			  dothatartifactthing(job);
			  job:=0;
		       end;
		    end;
	    end;  
      
   end; { EngTick }

   procedure SecTick(background : Boolean);
   begin
      if lastalienid <> ship.wandering.alienid then
      begin
	 lastalienid := ship.wandering.alienid;
	 if ship.wandering.alienid < 16000 then
	    CrewMessage(background, 191, 4, 'Alien vessel sighted on scanners!');
      end;
   end; { SecTick }

   procedure SciTick(background : Boolean);
   begin
      assert(background or not background);	{ just ignore warnings }
   end; { SciTick }

   procedure AstTick(background : Boolean);
   begin
      assert(background or not background);	{ just ignore warnings }
   end; { AstTick }

   procedure MedTick(background : Boolean);
   var
      i, d : Integer;
   begin   
      for i := 1 to 6 do
	 with ship.crew[i] do
	 begin
	    d := ComputeSanity(i) - san;
	    if (d <> 0) and (random(2) = 0) and SkillTest(background, 6, 99 - abs(d), 10) then
	       san := san + Sign(d);
	    d := ComputePerformance(i) - perf;
	    if (d <> 0) and (random(2) = 0) and SkillTest(background, 6, 99 - abs(d), 10) then
	       perf := perf + Sign(d);
	    d := ComputeSkill(i) - skill;
	    if (d <> 0) and (random(2) = 0) and SkillTest(background, 6, 99 - abs(d), 10) then
	       skill := skill + Sign(d);
	 end;
   end; { MedTick }

   procedure ResearchTick(background : Boolean);
   var
      i, d : Integer;
   begin   
      for i := 1 to 6 do
	 with ship.crew[i] do
	    if (ship.research and (1 shl i)) > 0 then
	       addxp(i, 5 + PerformanceRange(background, i, 5), ord(not background))
	    else
	    begin
	       for d := 1 to 5 do
		  if (status > 0) and PerformanceTest(background, i, 99 - status) then
		     dec(status);
	       d := ComputeSanity(i);
	       if (san < d) and PerformanceTest(background, i, 99 - status) then
		  inc(san);
	    end;
   end; { ResearchTick }

   procedure SanityTick(background : Boolean);
   var
      i : Integer;
   begin
      for i := 1 to 6 do
	 with ship.crew[i] do
	    if not SanityTest(background, i, status) then
	       if san > 0 then
		  dec(san)
	       else
	       begin
		  if perf > 0 then
		     dec(perf);
		  if skill > 0 then
		     dec(skill);
		  if (perf = 0) or (skill = 0) then
		     SanityFailure(background, i);
	       end;
   end; { SanityTick }

   procedure DayTick(background	: Boolean);
   var i, s : Integer ;
      j, c, d  : byte;
   begin
      assert(background or not background);	{ just ignore warnings }
      s := tempplan^[curplan].system;
      for i := 1 to 1000 do
	 if (tempplan^[i].system = s) and (tempplan^[i].bots > 0) then
	 begin
	    c := 0;
	    for j := 1 to 7 do
	       if tempplan^[i].cache[j] <> 0 then {todo: consider: don't count wortless junk either?}
		  inc(c);
	    ;
	    d := (tempplan^[i].bots shr 3);
	    if (c < 7) and ((tempplan^[i].bots and 7) > 0) and (random(200) < (40 - d)) then
	    begin
	       AddStuff(i, 1);
	       case (tempplan^[i].bots and 7) of
		 1 : inc(d); {minebots}
		 2 : inc(d,2); {manufactories}
		 4 : inc(d,4); {fabricators}
		 5 : inc(d); {starminer}
	       end; { case }
	       if d > 31 then d := 31;
	    end else begin
	       if (d > 0) and (random(100) < 5) then dec(d);
	    end;
	    tempplan^[i].bots := (tempplan^[i].bots and 7) or (d shl 3);
	 end;
   end;

   procedure GameTick(background : Boolean; ticks: Integer);
   begin
      TickPending(ticks, background);
      while ticks > 0 do
      begin
	 dec(ticks, 1);
	 ShipTick(background);
	 EngTick(background);
	 SciTick(background);
	 SecTick(background);
	 AstTick(background);
	 inc(ship.stardate[5],5);
	 if ship.stardate[5]>99 then
	 begin
	    ResearchTick(background);
	    SanityTick(background);
	    PsyTick(background);
	    MedTick(background);
	    inc(ship.stardate[4],ship.stardate[5] div 100);
	    ship.stardate[5]:=ship.stardate[5] mod 100;
	    if ship.stardate[4]>19 then
	    begin
	       DayTick(background);
	       inc(ship.stardate[2],ship.stardate[4] div 20);
	       ship.stardate[4]:=ship.stardate[4] mod 20;
	       if ship.stardate[2]>19 then
	       begin
		  inc(ship.stardate[1],ship.stardate[2] div 20);
		  ship.stardate[2]:=ship.stardate[2] mod 20;
		  if ship.stardate[1]>19 then
		  begin
		     inc(ship.stardate[3],ship.stardate[1] div 20);
		     ship.stardate[1]:=ship.stardate[1] mod 20;
		  end;
	       end;
	    end;
	 end;
      end;
   end; { GameTick }

function ComputeSkill(crew : Integer): Integer;
begin
   ComputeSkill := max2(0, min2(99, round(0.40*ship.crew[crew].phy-0.20*ship.crew[crew].emo+0.60*ship.crew[crew].men)));
   {ComputeSkill := round(0.60*ship.crew[crew].phy+0.40*ship.crew[crew].emo-0.20*ship.crew[crew].men);}
end; { ComputeSkill }

function ComputePerformance(crew : Integer): Integer;
begin
   ComputePerformance := max2(0, min2(99, round(0.60*ship.crew[crew].phy+0.40*ship.crew[crew].emo-0.20*ship.crew[crew].men)));
   {ComputePerformance := round(0.60*ship.crew[crew].men+0.40*ship.crew[crew].phy-0.20*ship.crew[crew].emo);}
end; { ComputePerformance }

function ComputeSanity(crew : Integer): Integer;
begin
   ComputeSanity := max2(0, min2(99, round(-0.20*ship.crew[crew].phy+0.60*ship.crew[crew].emo+0.40*ship.crew[crew].men)));
   {ComputeSanity := round(0.60*ship.crew[crew].emo+0.40*ship.crew[crew].men-0.20*ship.crew[crew].phy);}
end; { ComputeSanity }


(* Reset the crew tick module to start defaults.*)
procedure ResetCrew;
begin
   lastalienid := -1
end;

begin
   ResetCrew;
end.
