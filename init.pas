unit init;
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
   Initialization unit for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

interface

implementation

uses dos;

procedure ovrerrhandler(err: integer);
var s: string;
begin
// case err of
//  -1: s:='Overlay Manager Error.';
//  -3: s:='Insufficient Memory.';
//  -5: s:='No EMS Found.';
//  -6: s:='Insufficient EMS Memory.';
//  else s:='Unknown Error.';
 //end;
 //writeln('Overlay Error: '+s);
// halt(4);
end;

procedure initialize;
var ovrerr,i,j: integer;
begin
 //ovrinit(paramstr(0));
 //ovrerr:=ovrresult;
 //if ovrerr<>0 then ovrerrhandler(ovrerr);
 //ovrsetretry(ovrgetbuf div 3);
 //ovrinitems;
 //i:=ovrresult;
end;

begin
 initialize;
end.
