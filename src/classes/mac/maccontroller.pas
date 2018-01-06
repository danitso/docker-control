unit MacController;

{$MODE DELPHI}

interface

uses
  Classes,
  ControllerInterface,
  Process,
  SysUtils;

type
  { TMacController }
  TMacController = class(TInterfacedObject, IControllerInterface)
  private const
    DOCKER_UI_EXE_NAME = 'Docker';
  protected
    FErrorMessage: String;

    function GetDockerUIProcessId: Cardinal;
  public
    function GetErrorMessage: String;

    function GetOption(const Name: String): String;
    procedure SetOption(const Name, Value: String);

    function Reset: Boolean;
    function Restart: Boolean;
    function Start: Boolean;
    function Stop: Boolean;
  end;

implementation

function TMacController.GetDockerUIProcessId: Cardinal;
var
  Output: TStringList;
  Process: TProcess;
begin
  RunCommand();
  Result := 0;

  // Retrieve the process id for the Docker UI application.
  try
    Process := TProcess.Create(nil);
    Process.Executable := 'pgrep';
    Process.Parameters.Append(DOCKER_UI_EXE_NAME);
    Process.Options := [poWaitOnExit, poUsePipes];
    Process.Execute;

    if Process.ExitCode = 0 then
    begin
      Output := TStringList.Create;
      Output.LoadFromStream(Process.Output);

      Result := StrToInt(Trim(Output.Text));
    end;
  finally
    if Assigned(Output) then
      Output.Free;

    if Assigned(Process) then
      Process.Free;
  end;
end;

function TMacController.GetErrorMessage: String;
begin
  Result := FErrorMessage;
end;

function TMacController.GetOption(const Name: String): String;
begin
  raise ENotImplemented.Create('Not implemented');
end;

procedure TMacController.SetOption(const Name, Value: String);
begin
  raise ENotImplemented.Create('Not implemented');
end;

function TMacController.Reset: Boolean;
begin
  Result := False;
  raise ENotImplemented.Create('Not implemented');
end;

function TMacController.Restart: Boolean;
begin
  Result := Self.Stop;

  if not Result then
    Exit;

  Result := Self.Start;
end;

function TMacController.Start: Boolean;
var
  Process: TProcess;
begin
  Result := False;

  // Start the Docker UI application.
  try
    Process := TProcess.Create(nil);
    Process.Executable := 'open';

    Process.Parameters.Append('--background');
    Process.Parameters.Append('--hide');
    Process.Parameters.Append('--a');
    Process.Parameters.Append(DOCKER_UI_EXE_NAME);

    Process.Options := [poWaitOnExit, poUsePipes];
    Process.Execute;

    if Process.ExitCode <> 0 then
    begin
      FErrorMessage := 'Failed to open the Docker UI application';
      Exit;
    end;
  finally
    FreeAndNil(Process);
  end;
end;

function TMacController.Stop: Boolean;
var
  ProcessId: Cardinal;
begin
  Result := False;

  // Retrieve the process id, if possible. Otherwise, indicate success.
  ProcessId := GetDockerUIProcessId;

  if ProcessId = 0 then
  begin
    Result := True;
    Exit;
  end;

  // Stop the Docker UI application.
  try
    Process := TProcess.Create(nil);
    Process.Executable := 'kill';
    Process.Parameters.Append(IntToStr(ProcessId));
    Process.Options := [poWaitOnExit, poUsePipes];
    Process.Execute;

    if Process.ExitCode <> 0 then
    begin
      FErrorMessage := 'Failed to stop the Docker UI application';
      Exit;
    end;
  finally
    Process.Free;
  end;
end;

end.

