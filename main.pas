program main;
{$M 6500,335000,655360} (*390000*)
{$S-,L-,D-}

{***************************
   Outer Shell/Initialization for IronSeed

   Channel 7
   Destiny: Virtual


   Copyright 1994

***************************}

uses init, gmouse, starter, data,heapchk;

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
