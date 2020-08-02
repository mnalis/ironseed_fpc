unit data;
{$I-}
{***************************
   Data unit for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

interface
{$PACKRECORDS 1}
uses utils_;
const
 maxicons= 80;
 maxcargo= 145;
 nearbymax= 20;
 maxweapons= 72;
 maxconverse= 127;{90;}
 maxidle= 750;
 totalcreation= 123;
 shipnames: array[0..8] of string[9]=
  ('Heavy','Light','Strategic','Shuttle','Assault','Storm','Transport','Frigate','Cruiser');
 probetext : array[0..8] of string[9] =
  ('   Docked',' Deployed',' Orbiting','Gathering', 'Analyzing','Returning','Refueling','Destroyed', '   Docked');
 scantypes : array[1..5] of string[13] =
  ('Lithosphere..','Hydrosphere..','Atmosphere...','Biosphere....','Anomaly......');
 activity: array[1..5] of string[8] =
  ('    Calm','    Mild','Moderate','   Heavy',' Massive');
 repairname: array[1..8] of string = 
  ('Power Supply','Shield Control','Weapons Control','Engine'
  ,'Life Support ','Communications','Computer AI','Hull Damage');
 teamdata:array[0..15] of string[13] =
  ('Idle         ','Power Supply ','Shield Crtl ','Weapons Crtl','Engine       '
  ,'Life Support ','Comm.        ','Computer AI ','Hull Damage ','Shield       '
  ,'Weapon       ','Device       ','Component   ','Material    ','Artifact    '
  ,'Other        ');
   crewtitles:array[0..6] of String[11] =
   ('COMPUTER', 'PSYCHOMETRY','ENGINEERING','SCIENCE','SECURITY','ASTROGATION', 'MEDICAL');
 cubefaces:array[0..5] of string[11] =
  ('Psychometry','Engineering','  Science  ',' Security  ','Astrogation',
   '  Medical  ');
 alientypes: array[0..10] of string[12] =
  ('Avian','Monoped','Biped','Triped','Quadraped','Octaped','Aquatics','Fungi',
   'Carniferns','Crystalline','Symbiots');
 menunames: array[0..53] of string[11] =
  (' Psy Eval  ','Planet Comm','Planet Comm',' Psy Eval  ',' Ship Hail ',
   ' Ship Hail ','Crew Status',' Research  ','Crew Comm  ',
   ' Dmg Ctrl  ',' Configure ','Bot Control','  Shields  ',' Ship Logs ',
   ' Creation  ','  Weapons  ',' Research  ','   Cargo   ',
   'Short Range','Planet Scan','Planet Scan','Long Range ','Planet Scan',
   'Planet Scan','System Info',' Research  ',' Star Logs ',
   '  Retreat  ','  Retreat  ','  Drones   ','  Shields  ','  Masking  ',
   '  Attack   ','  Weapons  ',' Research  ','  Attack   ',
   ' Star Map  ','Quick Stats','Ship Status','Sector Map ','  Target   ',
   '  Target   ','History Map',' Research  ','Local Info ',
   '  Options  ',' Save Game ','  Encode   ','Time Burst ',' Load Game ',
   '  Decode   ','Clear Scrn ',' Research  ','Quit to DOS');
type
   buttontype = record
		   x, y, w, h : Integer;
		   c1, c2     : char;
		end;	      
 portraittype= array[0..69,0..69] of byte;
 scandatatype= array[0..11] of byte;
 scantype= array[0..16] of scandatatype;
 scrtype2=array[40..132,70..251] of byte;
 scrtype4=array[8..134,70..251] of byte;
 smallbuffer= array[1..8000] of byte;
 landtype= array[1..240,1..120] of byte;
 planicontype= array[0..9,0..319] of byte;
 weaponicontype= array[0..19,0..19] of byte;
 planettype=
  record
   system,orbit,psize,water,state,mode,bots,notes,datem: byte;
   datey,visits: word;
   seed: word;
   cache: array[1..7] of word;
   age: longint;
  end;
 planarray= array[1..1000] of planettype;
 fonttype= array[0..2] of byte;
 colortype= array[1..3] of byte;
// paltype= array[0..255] of colortype;
// screentype= array[0..199,0..319] of byte;
 icontype= array[0..16,0..14] of byte;
 systemtype=
  record
   name: string[12];
   x,y,z,datey,visits: integer;
   numplanets,notes,datem,mode: byte;
  end;
 crewtype=
  record
   name: string[20];
   phy,men,emo,status,level,index,skill,perf,san: byte;
   xp: longint;
  end;
 weapontype=
  record
   damage,energy: integer;
   dmgtypes: array[1..4] of byte;
   range: longint;
  end;
 cargotype=
  record
   name: string[20];
   size,index: word;
  end;
 onealientype=
  record                                {relative positions in km}
   relx,rely,relz,techlevel,orders,congeniality,anger,alienid: integer;
  end;
 teamtype=
  record
   job,timeleft,jobtype,extra: integer;
  end;
 shiptype=
  record
   wandering: onealientype;
   crew: array[1..6] of crewtype;
   encodes: array[1..6] of crewtype;
   gunnodes: array[1..10] of byte;      {installation positions}
   armed: boolean;
   fuel,fuelmax,battery,hulldamage: integer;
   cargomax: word;
   hullmax,accelmax,gunmax,shieldlevel,shield,posx,posy,posz,orbiting: integer;                  {kilograms, gigawatts}
   cargo: array[1..250] of integer;     {items => m3}
   numcargo: array[1..250] of word;     {number of each item}
   engrteam: array[1..3] of teamtype;
   damages: array[1..7] of byte;        {0=none, 100=destroyed}
   shieldopt: array[1..3] of byte;
   options: array[1..10] of byte;
   research: byte;
   shiptype: array[1..3] of byte;
   events: array[0..64] of byte;        {event bits }
   stardate: array[1..5] of word;       {month day year  hour minute}
  end;                                  {00    00  00    00   00    }
 plantype= array[1..120,1..120] of byte;
 templatetype2= array[18..123,27..143] of byte;
 shipdistype= array[0..57,0..74] of byte;
 creationtype=
  record
   index: integer;
   name: string[20];
   parts: array[1..3] of integer;
   levels: array[1..6] of byte;
  end;
 createarray= array[1..totalcreation] of creationtype;
 crewdatatype=
  record
   name: string[20];
   phy,men,emo,level,jobtype: integer;
   desc: array[0..9] of string[52];
  end;
 alientype=
  record
   name: string[15];
   techmin,techmax,anger,congeniality,victory,id,conindex: integer;
   war: boolean;
  end;
 alienshiptype=
  record
   relx,rely,relz,range: int32;
   techlevel,skill,shield,battery,shieldlevel,hulldamage,
    dx,dy,dz,maxhull,accelmax,regen,picx: SmallInt;
   damages: array[1..7] of byte;
   gunnodes: array[1..5] of byte;
   charges: array[1..20] of byte;
  end;
 cargoarray= array[1..maxcargo] of cargotype;
 weaponarray= array[1..maxweapons] of weapontype;
 systemarray= array[1..250] of systemtype;
 nearbytype= record
   index: word;
   x,y,z: real;
  end;
 artifacttype= array[1..60] of string[10];
 nearbyarraytype= array[1..nearbymax] of nearbytype;
 iconarray= array[0..maxicons] of icontype;
 converseindex=record
   event,runevent,rcode,index: integer;
   keyword: string[75];
  end;
 responsetype=record
   index: integer;
   response: string[255];
  end;
 conversearray= array[1..maxconverse] of converseindex;
 responsearray= array[1..maxconverse] of responsetype;
 linetype= string[30];
 linetype2= array[1..30] of byte;
 startype= array[1..4] of integer;
 colordisplaytype= array[0..30] of linetype2;
 textdisplaytype= array[0..30] of linetype;
 displaytype= array[0..192,0..93] of byte;
 backtype= array[0..12,0..51] of byte;
 cubetype= array[0..44,0..50] of byte;
 scrtype3= array[151..192,11..160] of byte;
 pscreentype= ^screentype;

logpendingtype =
   record
      time, log	: Integer;
   end;		

eventarray = array[0..1023] of byte;
logarray = array[0..255] of Integer;
logpendingarray = array[0..127] of logpendingtype;

const
 font: array[0..2,1..82] of fonttype=
  (((0,0,0),(102,96,96),(85,0,0),(34,0,0),(36,68,32),
   (66,34,64),(9,105,0),(4,228,0),(0,2,36),(0,240,0),
   (0,0,32),(1,36,128),(107,221,96),(98,34,240),(241,104,240),
   (241,33,224),(153,241,16),(248,113,224),(248,249,240),(241,17,16),
   (249,105,240),(249,241,16),(102,6,96),(102,6,98),(18,66,16),
   (15,15,0),(132,36,128),(105,32,32),(121,185,144),(249,169,240),
   (248,136,240),(233,153,224),(240,200,240),(248,232,128),(248,153,240),
   (153,249,144),(114,34,112),(241,25,96),(158,153,144),(136,136,240),
   (159,153,144),(233,153,144),(249,153,240),(249,184,128),(105,154,80),
   (249,169,144),(132,33,224),(114,34,32),(153,153,240),(153,149,32),
   (153,187,96),(153,105,144),(153,113,16),(242,72,240),(9,36,144),
   (8,66,16),(7,155,144),(15,169,240),(15,136,240),(14,153,224),
   (14,12,224),(15,140,128),(15,137,240),(9,159,144),(7,34,112),
   (15,25,96),(9,233,144),(8,136,240),(9,249,144),(14,153,144),
   (15,153,240),(15,155,128),(15,155,240),(15,154,144),(4,33,224),
   (15,34,32),(9,153,96),(9,149,32),(9,155,96),(9,105,144),
   (9,151,16),(15,36,240)),

   ((0,0,0),(102,96,96),(85,0,0),(34,0,0),(36,68,32),
   (66,34,64),(9,105,0),(4,228,0),(0,2,36),(0,240,0),
   (0,0,32),(1,36,128),(107,221,96),(98,34,240),(105,104,240),
   (105,41,96),(19,95,16),(248,225,224),(104,233,96),(241,36,128),
   (105,105,96),(105,113,96),(2,2,0),(2,2,36),(18,66,16),
   (15,15,0),(132,36,128),(105,32,32),(105,249,144),(233,233,224),
   (105,137,96),(233,153,224),(248,232,240),(248,232,128),(104,185,96),
   (153,249,144),(114,34,112),(241,25,96),(158,153,144),(136,136,240),
   (159,153,144),(233,153,144),(105,153,96),(233,232,128),(105,155,112),
   (233,233,144),(120,97,224),(242,34,32),(153,153,96),(153,149,32),
   (153,187,96),(153,105,144),(153,113,96),(242,72,240),(9,36,144),
   (8,66,16),(6,153,112),(142,153,224),(7,136,112),(23,153,112),
   (6,158,112),(105,200,128),(6,151,150),(142,153,144),(32,34,32),
   (16,17,150),(137,233,144),(34,34,32),(9,249,144),(14,153,144),
   (6,153,96),(14,153,232),(6,153,113),(6,152,128),(7,66,224),
   (39,34,32),(9,153,96),(9,149,32),(9,155,96),(9,105,144),
   (9,151,22),(15,36,240)),

   ((0,0,0),(34,32,32),(85,0,0),(34,0,0),(36,68,32),
   (66,34,64),(9,105,0),(2,114,0),(0,2,36),(0,240,0),
   (0,0,32),(1,36,128),(107,221,96),(38,34,112),(241,248,240),
   (241,113,240),(170,175,32),(248,241,240),(248,249,240),(241,17,16),
   (249,105,240),(249,241,240),(2,2,0),(2,2,36),(18,66,16),
   (15,15,0),(132,36,128),(249,48,32),(249,249,144),(249,233,240),
   (249,137,240),(233,153,224),(248,232,240),(248,232,128),(248,185,240),
   (153,249,144),(114,34,112),(241,25,240),(158,153,144),(136,136,240),
   (159,153,144),(157,185,144),(249,153,240),(249,248,128),(249,155,240),
   (249,233,144),(120,97,224),(242,34,32),(153,153,240),(153,149,32),
   (153,187,96),(153,105,144),(153,241,240),(242,72,240),(9,36,144),
   (8,66,16),(15,155,208),(143,153,240),(15,136,240),(31,153,240),
   (15,188,240),(249,200,128),(15,151,159),(143,153,144),(32,34,32),
   (16,17,159),(137,233,144),(34,34,32),(9,249,144),(14,153,144),
   (15,153,240),(15,153,248),(15,153,241),(15,152,128),(7,66,224),
   (39,34,32),(9,153,240),(9,149,32),(9,155,96),(9,105,144),
   (9,159,31),(15,36,240)));

const
   MAXCANARY_=8192;
   CANARY_QW=6148914691236517205; { 'UUUUUUUU' }

var
 colors: paltype;
 icons: ^iconarray;
 screen: screentype; // !!!!
 canary_: array[0..MAXCANARY_] of qword;
 systems: systemarray;
 weapons: weaponarray;
 cargo: cargoarray;
 bldcargo: array[1..maxcargo] of word;     {build time of each item}
 prtcargo: array[1..maxcargo,1..3] of Integer;{sub parts of each item}
 lvlcargo: array[1..maxcargo,1..6] of Integer;{level requirements}
 rescargo: array[1..250] of word;     {number of each item reserved}
 ship: shiptype;
 quit,anychange,panelon,targetready,showplanet,reloading: boolean;
 viewmode,viewmode2,viewlevel,viewindex,viewindex2,alert,curfilenum,cube,cx,cy,
  target,sphere,tc,x,y,z,c,radius,backgrx,backgry,r2,offset,water,waterindex,
  t,curplan,tcolor,bkcolor,tslice,glowindex,lightindex,batindex,action,ecl,
  textindex,idletime,cursorx,command,viewindex3,viewindex4,maxspherei,spherei,
  xw: integer;
 landform: ^landtype;
 planet: ^plantype;
 backgr: pscreentype;
 starmapscreen: ^templatetype2;
 c2,t1,t2,ar,br,x1,y1,x2,y2,oldt1: real;
 statcolors: array[1..4] of byte;
 nearby,nearbybackup: nearbyarraytype;
 tempplan: ^planarray;
 done: boolean;
 artifacts: ^artifacttype;
 tempicon: ^weaponicontype;
 planicons: ^planicontype;
 tempdir: string[80];
 textdisplay: ^textdisplaytype;
 colordisplay: ^colordisplaytype;
 cubesrc,cubetar: ^cubetype;
 screen2: ^scrtype3;
 back1,back2,back3,back4: backtype;
 spcindex: array[0..5] of byte;
 spcindex2: array[0..5] of byte;
 colorlookup: array[0..255] of byte;
 defaultsong: string[12];
 ppart: array[6..120] of real;
 pm: array[6..120] of integer;
 alien: alientype;

   logpending:logpendingarray;
   events:eventarray;
   logs:logarray;

   fadelevel :Integer;
   palettedirty :Boolean;

procedure errorhandler(s: string;errtype: integer);
//procedure setrgb256(palnum,r,g,b: byte);
//procedure set256colors(pal : paltype);
procedure printxy(x1,y1: integer; s: string);
procedure fading;
procedure fadein;
procedure fadestep(step : Integer);
procedure fadefull(step, slice : Integer);
procedure fadestopmod(step, slice : Integer);
procedure loadscreen(s: string; ts:pointer);
procedure compressfile(s: string; ts: pscreentype);
procedure loadpal(s: string);
//function fastkeypressed : boolean;
procedure mymove(var src,tar; count: word);
//procedure fillchar(var src; count: word; databyte: byte);
//procedure move(var src,tar; count: word);
procedure checkcanary;
procedure checkcanary2;

procedure quicksavescreen(s : String; scr : pscreentype; savepal : Boolean);
procedure quickloadscreen(s : String; scr : pscreentype; loadpal : Boolean);

implementation

uses crt,  gmouse, utils,modplay;

const                           { compression constants        }
 CPR_VER4=4;                    {   4 new header               }
 CPR_ERROR=255;                 { global error                 }
 CPR_CURRENT=CPR_VER4;          { current version              }
 CPR_BUFFSIZE= 8192;            { adjustable buffer size       }
type
 CPR_HEADER=
  record
   signature: word;             {RWM, no version. RM, version  }
   version: byte;
   width,height: word;
   flags: byte;
   headersize: byte;
  end;
 pCPR_HEADER= ^CPR_HEADER;
var
 i,j: integer;


{$PACKRECORDS DEFAULT}


procedure mymove(var src,tar; count: word);
begin
    move(src,tar,count*4);
end;
//procedure move; external;
//procedure fillchar; external;



procedure uncompressfile(s: string; ts: pscreentype; h: pCPR_HEADER);
type
 buftype= array[0..CPR_BUFFSIZE] of byte;
var
 f: file;
 err,num,count,databyte,index,x: word;
 total,totalsize,j: longint;
 buffer: ^buftype;

 procedure handleerror;
 begin
  h^.version:=CPR_ERROR;
  if buffer<>nil then dispose(buffer);
  buffer:=nil;
  close(f);
  j:=ioresult;
 end;

 procedure getbuffer;
 begin
  if total>CPR_BUFFSIZE then num:=CPR_BUFFSIZE else num:=total;
  blockread(f,buffer^,num,err);
  if (err<num) or (ioresult<>0) then
   begin
    handleerror;
    exit;
   end;
  total:=total-num;
  index:=0;
 end;

 function handleversion(n: integer): boolean;
 begin
  handleversion:=false;
  if n<>4 then exit;
  if h^.flags and 1>0 then
   begin
    num:=768;
    seek(f,h^.headersize);
    blockread(f,colors,num,err);
    if (ioresult<>0) or (num<>err) then exit;
    total:=filesize(f)-768-h^.headersize;
   end
  else total:=filesize(f)-h^.headersize;
  seek(f,filesize(f)-total);
  if ioresult<>0 then exit;
  handleversion:=true;
 end;

 function checkversion: boolean;
 begin
  checkversion:=false;
  num:=sizeof(CPR_HEADER);
  blockread(f,h^,num,err);
  if (err<num) or (ioresult<>0) or (h^.signature<>19794)
   or (not handleversion(h^.version)) then exit;
  checkversion:=true;
 end;

 function decode: boolean;
 begin
  decode:=false;
  getbuffer;
  j:=0;
  totalsize:=h^.width;
  totalsize:=totalsize*h^.height;
//  writeln(h^.width,' ',h^.height);
  x:=0;
  repeat
   if buffer^[index]=255 then
    begin
     inc(index);
     if index=CPR_BUFFSIZE then getbuffer;
     count:=buffer^[index];
     inc(index);
     if index=CPR_BUFFSIZE then getbuffer;
     databyte:=buffer^[index];
     if j+count>totalsize then count:=totalsize-j;
     j:=j+count;
     while count>0 do
      begin
       ts^[0,x]:=databyte;
       inc(x);
       dec(count);
      end;
    end
   else
    begin
     databyte:=buffer^[index];
     ts^[0,x]:=databyte;
     inc(j);
     inc(x);
    end;
   inc(index);
   if index=CPR_BUFFSIZE then getbuffer;
  until j=totalsize;
  decode:=true;
 end;

begin
 new(buffer);
 assign(f,s);
 reset(f,1);
 if (ioresult<>0) or (not checkversion) or (not decode) then
  begin
   handleerror;
   exit;
  end;
 close(f);
 if buffer<>nil then dispose(buffer);
end;

procedure loadscreen(s: string; ts: pointer);
var ftype: CPR_HEADER;
    s2: string[30];
begin
 uncompressfile(s+'.cpr',ts,@ftype);
 if ftype.version=CPR_ERROR then errorhandler(s,5);
end;

procedure compressfile(s: string; ts: pscreentype);
type
 buftype= array[0..CPR_BUFFSIZE] of byte;
var
 f: file;
 err,num,count,databyte,j,x,index: word;
 buf: ^buftype;
 h: CPR_HEADER;

 procedure handleerror;
 begin
  if buf<>nil then dispose(buf);
  buf:=nil;
  close(f);
  j:=ioresult;
 end;

 procedure setheader;
 begin
  with h do
   begin
    signature:=19794;
    version:=CPR_CURRENT;
    headersize:=sizeof(CPR_HEADER);
    width:=320;
    height:=200;
    flags:=1;
   end;
  num:=sizeof(CPR_HEADER);
  blockwrite(f,h,num,err);
  if (err<num) or (ioresult<>0) then errorhandler(s,5);
  num:=768;
  blockwrite(f,colors,num,err);
  if (ioresult<>0) or (err<num) then errorhandler(s,5);
 end;

 procedure saveindex;
 begin
  num:=index;
  blockwrite(f,buf^,num,err);
  if (ioresult<>0) or (num<>err) then
   begin
    handleerror;
    exit;
   end;
  index:=0;
 end;

begin
 new(buf);
 assign(f,s+'.cpr');
 rewrite(f,1);
 if ioresult<>0 then errorhandler(s,1);
 setheader;
 databyte:=ts^[0,0];
 count:=0;
 index:=0;
 x:=0;
 repeat
  count:=0;
  databyte:=ts^[0,x];
  while (ts^[0,x]=databyte) and (x<64000) do
   begin
    inc(count);
    inc(x);
   end;
  if (count<4) and (databyte<255) then
   for j:=1 to count do
    begin
     buf^[index]:=databyte;
     inc(index);
     if index=CPR_BUFFSIZE then saveindex;
    end
  else
   begin
    while count>255 do
     begin
      buf^[index]:=255;
      inc(index);
      if index=CPR_BUFFSIZE then saveindex;
      buf^[index]:=255;
      inc(index);
      if index=CPR_BUFFSIZE then saveindex;
      buf^[index]:=databyte;
      inc(index);
      if index=CPR_BUFFSIZE then saveindex;
      dec(count,255);
     end;
    if (count<4) and (databyte<255) then
     for j:=1 to count do
      begin
       buf^[index]:=databyte;
       inc(index);
       if index=CPR_BUFFSIZE then saveindex;
      end
    else
     begin
      buf^[index]:=255;
      inc(index);
      if index=CPR_BUFFSIZE then saveindex;
      buf^[index]:=count;
      inc(index);
      if index=CPR_BUFFSIZE then saveindex;
      buf^[index]:=databyte;
      inc(index);
      if index=CPR_BUFFSIZE then saveindex;
     end;
   end;
 until x=64000;
 saveindex;
 close(f);
 if buf<>nil then dispose(buf);
end;

procedure loadpal(s: string);
var palfile: file of paltype;
begin
 assign(palfile,s);
 reset(palfile);
 if ioresult<>0 then errorhandler(s,1);
 read(palfile,colors);
 if ioresult<>0 then errorhandler(s,5);
 close(palfile);
end;

procedure quicksavescreen(s : String; scr : pscreentype; savepal : Boolean);
var
   fs : file of screentype;
   fp : file of paltype;
begin
   assign(fs, s + '.scr');
   rewrite(fs);
   if ioresult<>0 then errorhandler(s + '.scr', 1);
   write(fs, scr^);
   if ioresult<>0 then errorhandler(s + '.scr', 5);
   close(fs);
   if savepal then
   begin
      assign(fp, s + '.pal');
      rewrite(fp);
      if ioresult<>0 then errorhandler(s + '.pal', 1);
      write(fp, colors);
      if ioresult<>0 then errorhandler(s + '.pal', 5);
      close(fp);
   end;
end;
					    
procedure quickloadscreen(s : String; scr : pscreentype; loadpal : Boolean);
var
   fs : file of screentype;
   fp : file of paltype;
begin
   assign(fs, s + '.scr');
   reset(fs);
   if ioresult<>0 then errorhandler(s + '.scr', 1);
   read(fs, scr^);
   if ioresult<>0 then errorhandler(s + '.scr', 5);
   close(fs);
   if loadpal then
   begin
      assign(fp, s + '.pal');
      reset(fp);
      if ioresult<>0 then errorhandler(s + '.pal', 1);
      read(fp, colors);
      if ioresult<>0 then errorhandler(s + '.pal', 5);
      close(fp);
   end;
end;
					    


procedure printxy(x1,y1: integer; s: string);
var letter,a,x,y,t: integer;
begin
 t:=tcolor;
 x1:=x1+4;
 for j:=1 to length(s) do
  begin
   tcolor:=t;
   case s[j] of
     'a'..'z': letter:=ord(s[j])-40;
    'A' ..'Z': letter:=ord(s[j])-36;
    ' ' ..'"': letter:=ord(s[j])-31;
    ''''..'?': letter:=ord(s[j])-35;
    '%': letter:=55;
    else letter:=1;
   end;
   y:=y1;
   for i:=0 to 5 do
    begin
     x:=x1;  { this stupid offset is pissing me off!!!!}
     inc(y);
     for a:=7 downto 4 do
      begin
       inc(x);
       if font[ship.options[7],letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor
        else if bkcolor<255 then screen[y,x]:=bkcolor;
      end;
     dec(tcolor,2);
     x:=x1;
     inc(y);
     inc(i);
     for a:=3 downto 0 do
      begin
       inc(x);
       if font[ship.options[7],letter,i div 2] and (1 shl a)>0 then screen[y,x]:=tcolor
        else if bkcolor<255 then screen[y,x]:=bkcolor;
      end;
     dec(tcolor,2);
    end;
   x1:=x1+5;
   if bkcolor<255 then for i:=1 to 6 do screen[y1+i,x1]:=bkcolor;
  end;
 tcolor:=t;
end;

procedure errorhandler(s: string; errtype: integer);
begin
 closegraph;
 writeln;
 case errtype of
  1: writeln('Open File Error: ',s);
  2: writeln('Mouse Error: ',s);
  3: writeln('Sound Error: ',s);
  4: writeln('EMS Error: ',s);
  5: writeln('Fatal File Error: ',s);
  6: writeln('Program Error: ',s);
  7: writeln('Music Error: ',s);
 end;
 halt(4);
end;


function testit : integer;
begin
testit:=1;
end;


procedure readygraph;
var testdriver,driver,mode,errcode: integer;
begin
  SDL_init_video(screen);
 loadpal('data/main.pal');
 set256colors(colors);
end;

procedure fading;
var
   a,b	     : integer;
   temppal   : paltype;
   px,dx,pdx : array[1..768] of shortint;
begin
   mymove(colors,temppal,192);
   fillchar(dx,768,48);
   for j:=1 to 768 do
   begin
      px[j]:=colors[0,j] div 48;
      pdx[j]:=colors[0,j] mod 48;
   end;
   b:=tslice div 2;
   for a:=47 downto 1 do
   begin
      for j:=1 to 768 do
      begin
	 dec(temppal[0,j],px[j]);
	 dec(dx[j],pdx[j]);
	 if (dx[j]<=0) then
	 begin
	    inc(dx[j],48);
	    dec(temppal[0,j]);
	 end;
      end;
      set256colors(temppal);
      if not fastkeypressed then delay(b);
   end;
   fillchar(temppal,768,0);
   set256colors(temppal);
   fadelevel := 0;
end;

procedure fadein;
var
   a,b	     : integer;
   temppal   : paltype;
   px,dx,pdx : array[1..768] of shortint;
begin
   b:=tslice div 2;
   fillchar(temppal,768,0);
   fillchar(dx,768,0);
   for j:=1 to 768 do
   begin
      px[j]:=colors[0,j] div 48;
      pdx[j]:=colors[0,j] mod 48;
   end;
   for a:=1 to 47 do
   begin
      for j:=1 to 768 do
      begin
	 inc(temppal[0,j],px[j]);
	 inc(dx[j],pdx[j]);
	 if (dx[j]>=48) then
	 begin
	    inc(temppal[0,j]);
	    dec(dx[j],48);
	 end;
      end;
      set256colors(temppal);
      if not fastkeypressed then delay(b);
   end;
   set256colors(colors);
   fadelevel := 64;
end;

procedure fadestep(step	: Integer);
var
   i : Integer;
   temppal   : paltype;
begin
   (*if the palette is not dirty then exit if there would be no change to brightness*)
   if not palettedirty then
   begin
      if step = 0 then exit;
      if (step < 0) and (fadelevel = 0) then exit;
      if (step > 0) and (fadelevel = 64) then exit;
   end;
   inc(fadelevel, step);
   if fadelevel < 0 then fadelevel := 0;
   if fadelevel > 64 then fadelevel := 64;
   for i := 1 to 768 do
      temppal[0,i] := (colors[0,i] * fadelevel) shr 6;
   set256colors(temppal);
   palettedirty := false;
end;

procedure fadefull(step, slice : Integer);
var
   i : integer;
begin
   if step < 0 then
      while fadelevel > 0 do
      begin
	 fadestep(step);
	 delay(slice);
      end
   else
      while fadelevel < 64 do
      begin
	 fadestep(step);
	 delay(slice);
      end;
end;

procedure fadestopmod(step, slice : Integer);
var
   i : integer;
begin
   step := -abs(step);
   while fadelevel > 0 do
   begin
      fadestep(step);
      setmodvolumeto((fadelevel * ship.options[9]) shr 6);
      delay(slice);
   end;
   haltmod;
end;

procedure initializecanary;
var
   i : integer;
begin
   for i:=0 to MAXCANARY_ do
      canary_[i] := CANARY_QW;
end;

procedure dumpcanary;
var
   i : integer;
begin
   writeln('WARNING: MEMORY OVERFLOW DETECTED. Cannary dump follows (corrupted entries only):');
   for i:=0 to MAXCANARY_ do
   begin
      if canary_[i] <> CANARY_QW then
         writeln (i, ': ', canary_[i]);
   end;
   if canary_[MAXCANARY_] = CANARY_QW then writeln ('[...]');
   writeln (MAXCANARY_, ': END.');
end;

procedure checkcanary;
var
   i : integer;
begin
   checkcanary2;
   for i:=0 to MAXCANARY_ do
    begin
      if canary_[i] <> CANARY_QW then dumpcanary;
      assert (canary_[i] = CANARY_QW, 'full check canary failed: memory may be corrupted, but not fatal');
    end;
end;

procedure checkcanary2;
begin
      if canary_[MAXCANARY_] <> CANARY_QW then 
       begin
         dumpcanary;
         writeln ('FATAL ERROR: memory surely corrupted - quick canary check failed, ', canary_[MAXCANARY_], ' != ', CANARY_QW);
         errorhandler('SYSTEM MEMORY CORRUPTION' ,6);
       end;
end;

begin 
   initializecanary;
   initializemod;
   checkbreak:=false;
   readygraph;
   tcolor:=22;
   bkcolor:=0;
   new(planicons);
   new(tempplan);
   defaultsong:='SECTOR.MOD';
   checkcanary;
end.
