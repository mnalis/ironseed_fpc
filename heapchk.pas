unit heapchk;

interface
procedure WriteHexWord(w: Word);
procedure HeapStats;
function HeapFunc (Size: Word): Integer; 
function GetHeapStats:String;
function GetHeapStats1:String;
function GetHeapStats2:String;

procedure HeapShow;

implementation
uses saveload;
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

function HeapFunc (Size: Word): Integer;
begin
end;
procedure HeapShow;
var s1,s2:string[11];
begin
end;
end.
