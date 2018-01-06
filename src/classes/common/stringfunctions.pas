unit StringFunctions;

{$MODE DELPHI}

interface

uses
  SysUtils;

type
  { TStringFunctions }
  TStringFunctions = class
  public
    class function Explode(const Substr: String; Str: String): TStringArray;
      static;
  end;

implementation

class function TStringFunctions.Explode(
  const Substr: String;
  Str: String
): TStringArray;
var
  Index: Integer;
begin
  SetLength(Result, 0);
  Index := Pos(Substr, Str);

  while Index <> 0 do
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Copy(Str, 1, Index - 1);

    Str := Copy(Str, Index + Length(Substr), Length(Str));
    Index := Pos(Substr, Str);
  end;

  if Str <> '' then
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Str;
  end;
end;

end.

