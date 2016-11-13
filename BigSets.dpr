program BigSets;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  BigSet in 'BigSet.pas';

var
  head: TBigSet;

begin
  head:= bsCreate;

  bsInclude(head, 1024);
  bsInclude(head, 256);
  bsInclude(head, 0);
  bsInclude(head, 512);
  bsInclude(head, 768);

  bsExclude(head, 512);

  readln;
end.
