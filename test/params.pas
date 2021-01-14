program test_params;

uses utils_;

procedure checkparams;
begin
 if (paramstr(1)<>'/playseed') and (paramstr(1)<>'/killseed') then
  begin
   writeln('Do not run this program separately.  Please run "is".');
   halt(4);
  end;
 init_dirs;
end;

begin
 checkparams;
end.
