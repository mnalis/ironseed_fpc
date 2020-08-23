program test;
{$PACKRECORDS 1}

var
    data: array[0..9] of integer = (10,20,30,40,50,60,71,80,90,91);
begin
    writeln('size');
    writeln(sizeof(data));
end.    
