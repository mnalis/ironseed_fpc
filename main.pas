program main;
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

{$M 6500,335000,655360} (*390000*)
{$S-,L-,D-}

{***************************
   Outer Shell/Initialization for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

uses starter, data;

{$O cargtool}
{$O comm}
{$O comm2}
{$O combat}
{$O crewinfo}
{$O crew2}
{$O explore}
{$O info}
{$O saveload}
{$O usecode}
{$O utils2}
{$O weird}
{$O starter}
{$O ending}
{$O modplay}
{O crewtick}


{$O detgus}
{$O det_aria}
{$O det_pas}
{$O det_sb}
{$O loaders}
{$O modload}
{$O getcpu}


begin
 init_everything;
// HeapError := @HeapFunc;
 checkparams;
 readydata;
 journeyon;
end.
