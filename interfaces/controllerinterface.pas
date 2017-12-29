unit ControllerInterface;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

type
  { IControllerInterface }
  IControllerInterface = interface
    ['{218ABF29-7798-481B-8534-3B18A721229A}']
    function GetErrorMessage: String;
    function Restart: Boolean;
    function Start: Boolean;
    function Stop: Boolean;
  end;

implementation

end.

