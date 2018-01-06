unit ControllerInterface;

{$MODE DELPHI}

interface

uses
  ConfigurationInterface;

type
  { IControllerInterface }
  IControllerInterface = interface(IConfigurationInterface)
    ['{218ABF29-7798-481B-8534-3B18A721229A}']
    function GetErrorMessage: String;

    function Reset: Boolean;
    function Restart: Boolean;
    function Start: Boolean;
    function Stop: Boolean;
  end;

implementation

end.

