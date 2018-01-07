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
    DOCKER_UI_APP_NAME = 'Docker';
    DOCKER_VM_APP_NAME = 'com.docker.hyperkit';
  protected
    FErrorMessage: String;

    function IsDockerServiceRunning: Boolean;
    function IsDockerUIRunning: Boolean;
    function IsDockerVMRunning: Boolean;
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
    Process.Executable := '/usr/local/bin/docker';
    Process.Parameters.Append('ps');
    Process.Options := [poWaitOnExit, poUsePipes];
    Process.Execute;

    if Process.ExitStatus = 0 then
      Result := True;
  finally
    Process.Free;
  end;
end;

function TMacController.IsDockerUIRunning: Boolean;
var
  Process: TProcess;
begin
  Result := False;

  try
    Process := TProcess.Create(nil);
    Process.Executable := '/usr/bin/pgrep';
    Process.Parameters.Append(DOCKER_UI_APP_NAME);
    Process.Options := [poWaitOnExit, poUsePipes];
    Process.Execute;

    if Process.ExitStatus = 0 then
      Result := True;
  finally
    Process.Free;
  end;
end;

function TMacController.IsDockerVMRunning: Boolean;
var
  Process: TProcess;
begin
  Result := False;

  try
    Process := TProcess.Create(nil);
    Process.Executable := '/usr/bin/pgrep';
    Process.Parameters.Append(DOCKER_VM_APP_NAME);
    Process.Options := [poWaitOnExit, poUsePipes];
    Process.Execute;

    if Process.ExitStatus = 0 then
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
    Process.Executable := '/usr/bin/open';

    Process.Parameters.Append('--background');
    Process.Parameters.Append('--hide');
    Process.Parameters.Append('-a');
    Process.Parameters.Append(DOCKER_UI_APP_NAME);

    Process.Options := [poWaitOnExit, poUsePipes];
    Process.Execute;

    if Process.ExitStatus <> 0 then
    begin
      FErrorMessage := 'Failed to start the Docker UI application';
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
  Process: TProcess;
begin
  Result := False;

  // Determine if the Docker UI application is not running in which case we can
  // just indicate success.
  if not IsDockerUIRunning then
  begin
    Result := True;
    Exit;
  end;

  // Terminate the Docker UI application by sending a KILL signal.
  try
    Process := TProcess.Create(nil);
    Process.Executable := '/usr/bin/pkill';
    Process.Parameters.Append(DOCKER_UI_APP_NAME);
    Process.Options := [poWaitOnExit, poUsePipes];
    Process.Execute;

    if Process.ExitStatus <> 0 then
    begin
      FErrorMessage := 'Failed to terminate the Docker UI application';
      Exit;
    end;
  finally
    Process.Free;
  end;

  // Wait for the Docker VM to terminate.
  for I := 1 to TIMEOUT_STOP do
  begin
    if not IsDockerVMRunning then
      Break;

    Sleep(1000);
  end;

  // Verify that the Docker VM has been terminated.
  if IsDockerVMRunning then
  begin
    FErrorMessage := 'Failed to terminate the Docker VM';
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

