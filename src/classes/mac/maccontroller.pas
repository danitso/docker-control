unit MacController;

{$MODE DELPHI}

interface

uses
  Classes,
  ConfigurationInterface,
  DockerController,
  MacConfiguration,
  Process,
  SysUtils;

type
  { TMacController }
  TMacController = class(TDockerController)
  private const
    DOCKER_CLI_APP_NAME = 'docker';
    DOCKER_UI_APP_NAME = 'Docker';
    DOCKER_VM_APP_NAME = 'com.docker.hyperkit';
  protected
    function GetDockerUIConfigObject: IConfigurationInterface;
    function GetDockerUIConfigPath: String;

    function IsDockerServiceRunning: Boolean;
    function IsDockerUIRunning: Boolean;
    function IsDockerVMRunning: Boolean;

    function WaitForDockerService(const Timeout: Integer): Boolean;
  public
    function GetOption(const Name: String): String; override;
    procedure SetOption(const Name, Value: String); override;

    function Reset: Boolean; override;
    function Restart: Boolean; override;
    function Start: Boolean; override;
    function Stop: Boolean; override;
  end;

implementation

function TMacController.GetDockerUIConfigObject: IConfigurationInterface;
begin
  Result := TMacConfiguration.Create(GetDockerUIConfigPath);
end;

function TMacController.GetDockerUIConfigPath: String;
begin
  Result := GetUserDir +
    '/Library/Group Containers/group.com.docker/settings.json';
end;

function TMacController.GetOption(const Name: String): String;
var
  Config: IConfigurationInterface;
begin
  Config := GetDockerUIConfigObject;
  Result := Config.GetOption(Name);
end;

function TMacController.IsDockerServiceRunning: Boolean;
var
  Output: String;
begin
  Result := RunCommand(DOCKER_CLI_APP_NAME, ['ps'], Output,
    [poWaitOnExit, poUsePipes]);
end;

function TMacController.IsDockerUIRunning: Boolean;
var
  Output: String;
begin
  Result := RunCommand('pgrep', [DOCKER_UI_APP_NAME], Output,
    [poWaitOnExit, poUsePipes]);
end;

function TMacController.IsDockerVMRunning: Boolean;
var
  Output: String;
begin
  Result := RunCommand('pgrep', [DOCKER_VM_APP_NAME], Output,
    [poWaitOnExit, poUsePipes]);
end;

procedure TMacController.SetOption(const Name, Value: String);
var
  Config: IConfigurationInterface;
begin
  Config := GetDockerUIConfigObject;
  Config.SetOption(Name, Value);
end;

function TMacController.Reset: Boolean;
var
  ConfigFile: String;
begin
  Result := False;
  ConfigFile := GetDockerUIConfigPath;

  if FileExists(ConfigFile) and not DeleteFile(ConfigFile) then
  begin
    FErrorMessage := 'Failed to delete the settings file';
    Exit;
  end;

  Result := Restart;
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
  Output: String;
begin
  Result := False;

  // Start the Docker UI application.
  if not RunCommand('open', [
      '--background',
      '--hide',
      '-a',
      DOCKER_UI_APP_NAME
    ], Output, [poWaitOnExit, poUsePipes]) then
  begin
    FErrorMessage := 'Failed to start the Docker UI application';
    Exit;
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
  Output: String;
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
  if not RunCommand('pkill', [DOCKER_UI_APP_NAME], Output,
    [poWaitOnExit, poUsePipes]) then
  begin
    FErrorMessage := 'Failed to terminate the Docker UI application';
    Exit;
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

