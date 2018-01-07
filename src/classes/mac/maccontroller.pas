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
    function IsDockerServiceRunning: Boolean;
    function WaitForDockerService(const Timeout: Integer): Boolean;
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

function TMacController.IsDockerServiceRunning: Boolean;
var
  Process: TProcess;
begin
  Result := False;

  try
    Process := TProcess.Create(nil);
    Process.Executable := 'docker';
    Process.Parameters.Append('ps');
    Process.Options := [poWaitOnExit, poUsePipes];
    Process.Execute;

    if Process.ExitCode = 0 then
      Result := True;
  finally
    Process.Free;
  end;
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
const
  TIMEOUT_START = 120;
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
    Process.Free;
  end;

  // Wait for the Docker service to start responding.
  if not WaitForDockerService(TIMEOUT_START) then
  begin
    FErrorMessage := 'Failed to query the Docker service';
    Exit;
  end;

  // Since the Docker service has begun responding, we assume that it is ready.
  Result := True;
end;

function TMacController.Stop: Boolean;
const
  TIMEOUT_STOP = 120;
var
  I: Integer;
  ProcessId: Cardinal;
begin
  Result := False;

  // Determine if the Docker UI application is not running in which case we can
  // just indicate success.
  ProcessId := GetDockerUIProcessId;

  if ProcessId = 0 then
  begin
    Result := True;
    Exit;
  end;

  // Stop the Docker UI application by sending a KILL signal.
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

  // Wait for the Docker UI application to terminate.
  for I := 1 to TIMEOUT_STOP do
  begin
    ProcessId := GetDockerUIProcessId;

    if ProcessId = 0 then
      Break;

    Sleep(1000);
  end;

  // Verify that the Docker UI application has been terminated.
  if ProcessId <> 0 then
  begin
    FErrorMessage := 'Failed to stop the Docker UI application';
    Exit;
  end;

  Result := True;
end;

function TMacController.WaitForDockerService(const Timeout: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;

  // Wait for the Docker service to start responding but do not wait forever.
  for I := 1 to Timeout do
  begin
    if IsDockerServiceRunning then
    begin
      Result := True;
      Break;
    end;

    Sleep(1000);
  end;
end;

end.

