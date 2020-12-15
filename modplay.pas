unit modplay;
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
   High Level Mod Playing Routines for IronSeed

   Copyright:
    1994 Channel 7, Destiny: Virtual
    2013 y-salnikov
    2020 Matija Nalis <mnalis-git@voyager.hr>
**********************************************}

{$L c_utils.o}

interface

	procedure setmodvolumeto(const vol:word);cdecl ; external;
	procedure haltmod;cdecl ; external;
	procedure initializemod;
	procedure stopmod;       // stop music + unload
	procedure playmod(const looping: boolean; const s: string);  // load & play mod
	procedure soundeffect(const s: string; const rate: word);
	procedure pausemod;cdecl ; external;
	procedure continuemod;cdecl ; external;
	procedure setmodvolume;
	function playing: boolean;cdecl ; external;

implementation

uses strings, data, dos, utils_;

	procedure sdl_mixer_init;cdecl ; external;
	procedure musicDone;cdecl ; external;
	procedure play_mod(const loop:byte; const filename:pchar);cdecl ; external;
	procedure play_sound(const filename:pchar; const rate:word);cdecl ; external;

procedure playmod(const looping: boolean; const s: string);  // load & play mod
Var p : Pchar;
begin
    if ship.options[OPT_SOUND]=0 then exit;
    p:=StrAlloc (length(s)+1);
    StrPCopy (P,s);
    play_mod(byte(looping),P);
    StrDispose(P);
    setmodvolumeto(ship.options[OPT_VOLUME]);
end;



procedure initializemod;  //SDL mod
begin
    if use_audio then sdl_mixer_init;
end;

procedure stopmod;       // stop music + unload
var i: word;
begin
 for i:=ship.options[OPT_VOLUME] downto 0 do
  begin
   setmodvolumeto(i);
   delay(10);
  end;
 musicDone;
end;




procedure soundeffect(const s: string; const rate: word);
Var p : Pchar;
begin
    if ship.options[OPT_SOUND]=0 then exit;

    p:=StrAlloc (length(s)+1);
    StrPCopy (P,s);
    play_sound(P,rate);
    StrDispose(P);
end;

procedure setmodvolume;
begin
	//if (not playing) then exit;
	setmodvolumeto(ship.options[OPT_VOLUME])
end;

end.
