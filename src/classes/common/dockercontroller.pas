unit DockerController;

{$MODE DELPHI}

interface

uses
  Classes,
  ControllerInterface,
  SysUtils;

type
  { TDockerController }
  TDockerController = class(TInterfacedObject, IControllerInterface)
  protected
    FErrorMessage: String;
  public
    function GetErrorMessage: String;

    function GetOption(const Name: String): String; virtual; abstract;
    procedure SetOption(const Name, Value: String); virtual; abstract;

    function Reset: Boolean; virtual; abstract;
    function Restart: Boolean; virtual; abstract;
    function Start: Boolean; virtual; abstract;
    function Stop: Boolean; virtual; abstract;
  end;

implementation

function TDockerController.GetErrorMessage: String;
begin
  Result := FErrorMessage;
end;

end.

