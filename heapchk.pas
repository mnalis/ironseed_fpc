unit heapchk;
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

interface
procedure WriteHexWord(w: Word);
procedure HeapStats;
function GetHeapStats:String;
function GetHeapStats1:String;
function GetHeapStats2:String;

implementation
procedure WriteHexWord(w: Word);
const
 hexChars: array [0..$F] of Char =
   '0123456789ABCDEF';
begin
 Write(hexChars[Hi(w) shr 4],
       hexChars[Hi(w) and $F],
       hexChars[Lo(w) shr 4],
       hexChars[Lo(w) and $F]);
end;
procedure HeapStats;
begin
    writeln('heap status - good :)');
end;

function GetHeapStats1:String;

begin 
   GetHeapStats1 := 'heap: TotalSize(' + '10050' + ')';
end;

function GetHeapStats2:String;

begin
    GetHeapStats2 := 'MaxAvail(' + '10050000' + ') MemAvail(' + '1005000' + ')';
end;

function GetHeapStats:String;
begin
   GetHeapStats := 'heap: TotalSize(' + '10050000' + ') MaxAvail(' + '1005000' + ') MemAvail(' + '1005000' + ')';
end;

end.
