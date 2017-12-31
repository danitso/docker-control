unit WindowsController;

{$MODE DELPHI}

interface

uses
  Classes,
  ControllerInterface,
  FpJson,
  JsonConf,
  JwaTlHelp32,
  Process,
  Registry,
  SysUtils,
  Tray,
  TrayButton,
  Windows;

type
  { TWindowsController }
  TWindowsController = class(TInterfacedObject, IControllerInterface)
  private const
    DOCKER_UI_EXE_NAME = 'Docker for Windows.exe';
  protected class var
    FWindowHandles: array of THandle;
    FWindowProcessHandles: array of THandle;
  protected
    FErrorMessage: string;

    function GetDockerUIConfigObject: TJSONConfig;
    function GetDockerUIConfigPath: String;
    function GetDockerUIPath: String;
    function GetDockerUIProcessId: Cardinal;
    function GetDockerUITrayButton(const Tray: TTray): TTrayButton;
    function IsDockerServiceRunning: Boolean;
    function IsDockerUIStarting: Boolean;
    function ShowDockerUITrayMenu: HWND;
    function WaitForDockerUIStartup(const Timeout: Integer): Boolean;
    function WaitForDockerUITrayButton(const Timeout: Integer): Boolean;
  public
    function GetErrorMessage: String;

    function GetOption(const Name: String): String;
    function GetOptionCategoryAndName(
      const Name: String;
      var OptionCategory,OptionName: String
    ): Boolean;
    function GetOptionDaemon(const Name: String): String;
    function GetOptionVM(const Name: String): String;

    procedure SetOption(const Name, Value: String);
    procedure SetOptionDaemon(const Name, Value: String);
    procedure SetOptionVM(const Name, Value: String);

    function Restart: Boolean;
    function Start: Boolean;
    function Stop: Boolean;
  end;

implementation

function TWindowsController.GetDockerUIConfigObject: TJSONConfig;
begin
  Result := TJSONConfig.Create(nil);
  Result.FileName := GetDockerUIConfigPath;
  Result.Formatted := True;
  Result.FormatOptions := [
    foSingleLineArray,
    foSingleLineObject,
    foSkipWhiteSpace
  ];
end;

function TWindowsController.GetDockerUIConfigPath: String;
begin
  Result := SysUtils.GetEnvironmentVariable('appdata') +
    '\Docker\settings.json';
end;

function TWindowsController.GetDockerUIPath: String;
var
  Registry: TRegistry;
begin
  Result := '';

  // Determine the path to the Docker UI's application directory by reading it
  // from the Windows Registry.
  try
    Registry := TRegistry.Create;
    Registry.RootKey := HKEY_LOCAL_MACHINE;

    if Registry.OpenKeyReadOnly('\SOFTWARE\Docker Inc.\Docker\1.0') then
      Result := Registry.ReadString('AppPath') + '\' + DOCKER_UI_EXE_NAME;
  finally
    FreeAndNil(Registry);
  end;
end;

function TWindowsController.GetDockerUIProcessId: Cardinal;
var
  PE: TProcessEntry32;
  Snapshot: THandle;
begin
  // Determine the process id for the Docker UI application which is responsible
  // for the Linux VM in Windows 10.
  Result := 0;
  Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0);

  try
    PE.dwSize := SizeOf(PE);

    if Process32First(Snapshot, PE) then
    begin
      while Process32Next(Snapshot, PE) do
      begin
        if CompareText(PE.szExeFile, DOCKER_UI_EXE_NAME) = 0 then
        begin
          Result := PE.th32ProcessID;
          Break;
        end;
      end;
    end;
  finally
    CloseHandle(Snapshot);
  end;
end;

function TWindowsController.GetDockerUITrayButton(
  const Tray: TTray
): TTrayButton;
const
  CAPTION_PARTIAL = 'Docker';
var
  I: Integer;
begin
  Result := nil;

  // Scan the visible tray button list for the button which belongs to the
  // Docker UI.
  for I := 0 to Tray.TrayButtonCount - 1 do
  begin
    if Pos(CAPTION_PARTIAL, Tray.TrayButton[I].Caption) > 0 then
    begin
      Result := Tray.TrayButton[I];
      Exit;
    end;
  end;

  // Scan the overflowing tray button list for the button which belongs to the
  // Docker UI.
  for I := 0 to Tray.OverflowButtonCount - 1 do
  begin
    if Pos(CAPTION_PARTIAL, Tray.OverflowButton[I].Caption) > 0 then
    begin
      Result := Tray.OverflowButton[I];
      Exit;
    end;
  end;
end;

function TWindowsController.GetErrorMessage: String;
begin
  Result := FErrorMessage;
end;

function TWindowsController.GetOption(const Name: String): String;
var
  OptionCategory: String;
  OptionName: String;
begin
  Result := '';

  // Split the option name into a lowercase category and name.
  if not GetOptionCategoryAndName(Name, OptionCategory, OptionName) then
    raise Exception.Create(Format('Invalid option ''%s''', [LowerCase(Name)]));

  // Read the option based on the category.
  if OptionCategory = 'daemon' then
    Result := GetOptionDaemon(OptionName)
  else if OptionCategory = 'vm' then
    Result := GetOptionVM(OptionName)
  else
    raise Exception.Create(Format('Invalid option ''%s.%s''', [
      OptionCategory,
      OptionName
    ]));
end;

function TWindowsController.GetOptionCategoryAndName(
  const Name: String;
  var OptionCategory,OptionName: String
): Boolean;
var
  Index: Integer;
begin
  Result := False;
  Index := Pos('.', Name);

  if Index <> 0 then
  begin
    OptionCategory := LowerCase(Copy(Name, 1, Index - 1));
    OptionName := LowerCase(Copy(Name, Index + 1, Length(Name)));
    Result := True;
  end;
end;

function TWindowsController.GetOptionDaemon(const Name: String): String;
const
  CATEGORY = 'daemon';
var
  DataConfig: TJSONConfig;
begin
  try
    DataConfig := GetDockerUIConfigObject;

    if Name = 'autostart' then
      Result := LowerCase(DataConfig.GetValue('/StartAtLogin', True).ToString(
        TUseBoolStrs.True))
    else if Name = 'autoupdate' then
      Result := LowerCase(DataConfig.GetValue('/AutoUpdateEnabled',
        True).ToString(TUseBoolStrs.True))
    else if Name = 'dns' then
      Result := String(DataConfig.GetValue('/NameServer', '8.8.8.8'))
    else if Name = 'expose' then
      Result := LowerCase(DataConfig.GetValue('/ExposeTcp', False).ToString(
        TUseBoolStrs.True))
    else if Name = 'forward_dns' then
      Result := LowerCase(DataConfig.GetValue('/UseDnsForwarder',
        False).ToString(TUseBoolStrs.True))
    else if Name = 'tracking' then
      Result := LowerCase(DataConfig.GetValue('/IsTracking', True).ToString(
        TUseBoolStrs.True))
    else
      raise Exception.Create(Format('Invalid option ''%s.%s''', [
        CATEGORY,
        Name
      ]));
  finally
    FreeAndNil(DataConfig);
  end;
end;

function TWindowsController.GetOptionVM(const Name: String): String;
const
  CATEGORY = 'vm';
var
  DataConfig: TJSONConfig;
begin
  try
    DataConfig := GetDockerUIConfigObject;

    if Name = 'cpus' then
      Result := DataConfig.GetValue('/VmCpus', 2).ToString
    else if Name = 'memory' then
      Result := DataConfig.GetValue('/VmMemory', 2048).ToString
    else
      raise Exception.Create(Format('Invalid option ''%s.%s''', [
        CATEGORY,
        Name
      ]));
  finally
    FreeAndNil(DataConfig);
  end;
end;

function TWindowsController.IsDockerServiceRunning: Boolean;
var
  Process: TProcess;
begin
  Result := False;

  // Invoke the 'docker ps' command in order to determine if the Docker service
  // is running.
  try
    Process := TProcess.Create(nil);
    Process.Executable := 'docker';
    Process.Parameters.Append('ps');
    Process.Options := [poWaitOnExit, poUsePipes];
    Process.Execute;

    if Process.ExitCode = 0 then
      Result := True;
  finally
    FreeAndNil(Process);
  end;
end;

function TWindowsController.IsDockerUIStarting: Boolean;
var
  Tray: TTray;
  TrayButton: TTrayButton;
begin
  try
    Tray := TTray.Create;
    TrayButton := GetDockerUITrayButton(Tray);
    Result := Assigned(TrayButton) and
              (Pos('starting', TrayButton.Caption) > 0);
  finally
    FreeAndNil(Tray);
  end;
end;

function TWindowsController.Restart: Boolean;
begin
  Result := Self.Stop;

  if not Result then
    Exit;

  Result := Self.Start;
end;

procedure TWindowsController.SetOption(const Name, Value: String);
var
  OptionCategory: String;
  OptionName: String;
begin
  // Split the option name into a lowercase category and name.
  if not GetOptionCategoryAndName(Name, OptionCategory, OptionName) then
    raise Exception.Create(Format('Invalid option ''%s''', [LowerCase(Name)]));

  // Read the option based on the category.
  if OptionCategory = 'daemon' then
    SetOptionDaemon(OptionName, Value)
  else if OptionCategory = 'vm' then
    SetOptionVM(OptionName, Value)
  else
    raise Exception.Create(Format('Invalid option ''%s.%s''', [
      OptionCategory,
      OptionName
    ]));
end;

procedure TWindowsController.SetOptionDaemon(const Name, Value: String);
const
  CATEGORY = 'daemon';
var
  DataConfig: TJSONConfig;
  DataValue: String;
begin
  try
    DataConfig := GetDockerUIConfigObject;

    if Name = 'autostart' then
    begin
      DataConfig.SetValue('/StartAtLogin', StrToBool(Value));
      DataValue := LowerCase(DataConfig.GetValue('/StartAtLogin',
        True).ToString(TUseBoolStrs.True));
    end
    else if Name = 'autoupdate' then
    begin
      DataConfig.SetValue('/AutoUpdateEnabled', StrToBool(Value));
      DataValue := LowerCase(DataConfig.GetValue('/AutoUpdateEnabled',
        True).ToString(TUseBoolStrs.True));
    end
    else if Name = 'dns' then
    begin
      {$WARNINGS OFF}
      DataConfig.SetValue('/NameServer', Value);
      {$WARNINGS ON}
      DataValue := Value;
    end
    else if Name = 'expose' then
    begin
      DataConfig.SetValue('/ExposeTcp', StrToBool(Value));
      DataValue := LowerCase(DataConfig.GetValue('/ExposeTcp',
        False).ToString(TUseBoolStrs.True));
    end
    else if Name = 'forward_dns' then
    begin
      DataConfig.SetValue('/UseDnsForwarder', StrToBool(Value));
      DataValue := LowerCase(DataConfig.GetValue('/UseDnsForwarder',
        True).ToString(TUseBoolStrs.True));
    end
    else if Name = 'tracking' then
    begin
      DataConfig.SetValue('/IsTracking', StrToBool(Value));
      DataValue := LowerCase(DataConfig.GetValue('/IsTracking',
        True).ToString(TUseBoolStrs.True));
    end
    else
    begin
      raise Exception.Create(Format('Invalid option ''%s.%s''', [
        CATEGORY,
        Name
      ]));
    end;

    WriteLn(Format('Changed %s.%s to ''%s''', [CATEGORY, Name, DataValue]));
  finally
    FreeAndNil(DataConfig);
  end;
end;

procedure TWindowsController.SetOptionVM(const Name, Value: String);
const
  CATEGORY = 'vm';
var
  DataConfig: TJSONConfig;
  DataValue: String;
begin
  try
    DataConfig := GetDockerUIConfigObject;

    if Name = 'cpus' then
    begin
      DataConfig.SetValue('/VmCpus', StrToInt(Value));
      DataValue := DataConfig.GetValue('/VmCpus', 2).ToString;
    end
    else if Name = 'memory' then
    begin
      DataConfig.SetValue('/VmMemory', StrToInt(Value));
      DataValue := DataConfig.GetValue('/VmMemory', 2048).ToString;
    end
    else
    begin
      raise Exception.Create(Format('Invalid option ''%s.%s''', [
        CATEGORY,
        Name
      ]));
    end;

    WriteLn(Format('Changed %s.%s to ''%s''', [CATEGORY, Name, DataValue]));
  finally
    FreeAndNil(DataConfig);
  end;
end;

function TWindowsController.ShowDockerUITrayMenu: HWND;
var
  Tray: TTray;
  TrayButton: TTrayButton;
begin
  Result := 0;

  try
    Tray := TTray.Create;
    TrayButton := GetDockerUITrayButton(Tray);

    if Assigned(TrayButton) then
      Result := TrayButton.Popup;
  finally
    FreeAndNil(Tray);
  end;
end;

function TWindowsController.Start: Boolean;
const
  TIMEOUT_EXECUTE = 5;
  TIMEOUT_STARTUP = 120;
var
  Path: String;
  Process: TProcess;
  ProcessId: Cardinal;
begin
  Result := False;

  // Determine if Docker UI is already running in which case we do not need to
  // try to start it.
  ProcessId := GetDockerUIProcessId;

  if ProcessId <> 0 then
  begin
    Result := True;
    Exit;
  end;

  // Determine the path to the Docker for Windows executable by reading it from
  // the Windows Registry and run it, if it exists.
  Path := GetDockerUIPath;

  if Path = '' then
  begin
    FErrorMessage := 'Failed to determine the path to the Docker UI executable';
    Exit;
  end
  else if not FileExists(Path) then
  begin
    FErrorMessage := 'The Docker UI executable is missing';
    Exit;
  end;

  try
    Process := TProcess.Create(nil);
    Process.Executable := Path;
    Process.Options := [];
    Process.Execute;
  finally
    Process.Free;
  end;

  // Wait for the Docker UI to begin its startup phase.
  if not WaitForDockerUITrayButton(TIMEOUT_EXECUTE) then
  begin
    FErrorMessage := 'Timeout exceeded for Docker UI execution';
    Exit;
  end;

  // Wait for the Docker UI to complete its startup phase.
  if not WaitForDockerUIStartup(TIMEOUT_STARTUP) then
  begin
    FErrorMessage := 'Timeout exceeded for Docker UI startup phase';
    Exit;
  end;

  // Verify that the Docker service is in fact running and responding.
  if not IsDockerServiceRunning then
  begin
    FErrorMessage := 'Failed to communicate with the Docker service';
    Exit;
  end;

  Result := True;
end;

function TWindowsController.Stop: Boolean;
const
  TIMEOUT_TERMINATE = 120;
  TIMEOUT_WINDOW = 5;
var
  ActiveWindowHandle: HWND;
  CursorPostion: TPoint;
  I: Integer;
  PopupWindowHandle: HWND;
  PopupWindowRect: TRect;
  ProcessId: Cardinal;
begin
  Result := False;

  // Determine if Docker UI is not running in which case we do not need to try
  // to stop it.
  ProcessId := GetDockerUIProcessId;

  if ProcessId = 0 then
  begin
    Result := True;
    Exit;
  end;

  // Determine if the Docker service is in fact active as we otherwise need to
  // assume that the virtual machine is booting in which case we should not try
  // to terminate the Docker UI.
  if not IsDockerServiceRunning then
  begin
    FErrorMessage := 'The Docker service is not running';
    Exit;
  end;

  // Determine the handle for the window which has the focus right now.
  ActiveWindowHandle := GetForegroundWindow;

  // Simulate a right-click on the tray icon for the Docker UI application as we
  // need to trigger its tray menu.
  PopupWindowHandle := ShowDockerUITrayMenu;

  if PopupWindowHandle = 0 then
  begin
    SetForegroundWindow(ActiveWindowHandle);
    FErrorMessage := 'Failed to trigger the Docker UI''s tray menu';
    Exit;
  end;

  // Determine the tray menu window's dimensions.
  PopupWindowRect.Create(0, 0, 0, 0);

  if not GetWindowRect(PopupWindowHandle, PopupWindowRect) then
  begin
    SetForegroundWindow(ActiveWindowHandle);
    FErrorMessage := 'Failed to determine the Docker UI tray window placement';
    Exit;
  end;

  // Simulate a left click on the 'Quit Docker' tray menu item.
  GetCursorPos(CursorPostion);
  SetCursorPos(
    PopupWindowRect.Left + 8,
    PopupWindowRect.Top + PopupWindowRect.Height - 8
  );

  Mouse_Event(MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);

  // Wait for the tray menu to disappear before returning the cursor to its
  // previous location and re-activating the previous window.
  for I := 1 to TIMEOUT_WINDOW * 1000 do
  begin
    if not IsWindowVisible(PopupWindowHandle) then
      Break;

    Sleep(1);
  end;

  if IsWindowVisible(PopupWindowHandle) then
  begin
    SetForegroundWindow(ActiveWindowHandle);
    SetCursorPos(CursorPostion.x, CursorPostion.y);

    FErrorMessage := 'Failed to simulate a left click on the tray menu item';
    Exit;
  end;

  SetCursorPos(CursorPostion.x, CursorPostion.y);
  SetForegroundWindow(ActiveWindowHandle);

  // Wait for the Docker UI process to terminate but do not wait for too long as
  // this entire approach can easily fail, if a new version of the Docker UI is
  // released with a re-organized tray menu.
  for I := 1 to TIMEOUT_TERMINATE do
  begin
    ProcessId := GetDockerUIProcessId;

    if ProcessId = 0 then
    begin
      Result := True;
      Exit;
    end;

    Sleep(1000);
  end;

  FErrorMessage := 'Timeout exceeded for the Docker UI termination phase';
end;

function TWindowsController.WaitForDockerUIStartup(
  const Timeout: Integer
): Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := 1 to Timeout do
  begin
    if not IsDockerUIStarting then
    begin
      Result := True;
      Break;
    end;

    Sleep(1000);
  end;
end;

function TWindowsController.WaitForDockerUITrayButton(
  const Timeout: Integer
): Boolean;
var
  I: Integer;
  Tray: TTray;
begin
  Result := False;

  for I := 1 to Timeout do
  begin
    try
      Tray := TTray.Create;

      if GetDockerUITrayButton(Tray) <> nil then
      begin
        Result := True;
        Break;
      end;
    finally
      FreeAndNil(Tray);
    end;

    Sleep(1000);
  end;
end;

end.

