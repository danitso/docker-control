unit WindowsController;

{$MODE DELPHI}

interface

uses
  Classes,
  ControllerInterface,
  JwaTlHelp32,
  Process,
  Registry,
  SysUtils,
  Tray,
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

    function GetDockerUIPath: String;
    function GetDockerUIProcessId: Cardinal;
    function GetDockerUITrayWindowHandle(const ProcessId: Cardinal): Cardinal;
    function IsDockerServiceRunning: Boolean;
    function ShowDockerUITrayMenu: Boolean;
  public
    function GetErrorMessage: String;
    function Restart: Boolean;
    function Start: Boolean;
    function Stop: Boolean;
  end;

implementation

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

function TWindowsController.GetErrorMessage: String;
begin
  Result := FErrorMessage;
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

function TWindowsController.GetDockerUITrayWindowHandle(
  const ProcessId: Cardinal
): Cardinal;
var
  Styles: Int64;
  StylesExt: Int64;
  WndProcessId: Cardinal;
begin
  Result := FindWindow(nil, nil);

  while Result <> 0 do
  begin
    // Skip any windows which do not appear to be popups.
    Styles := GetWindowLongPtr(Result, GWL_STYLE);

    if Styles and WS_POPUP = 0 then
    begin
      Result := GetWindow(Result, GW_HWNDNEXT);
      Continue;
    end;

    // Skip any windows which do not appear to control a parent window.
    StylesExt := GetWindowLongPtr(Result, GWL_EXSTYLE);

    if StylesExt and WS_EX_CONTROLPARENT = 0 then
    begin
      Result := GetWindow(Result, GW_HWNDNEXT);
      Continue;
    end;

    // Skip any windows which do not belong to the specified process.
    WndProcessId := 0;

    if GetWindowThreadProcessId(Result, WndProcessId) = 0 then
    begin
      Result := GetWindow(Result, GW_HWNDNEXT);
      Continue;
    end
    else if WndProcessId = ProcessId then
    begin
      Break;
    end;

    Result := GetWindow(Result, GW_HWNDNEXT);
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

function TWindowsController.Restart: Boolean;
begin
  Result := Self.Stop;
  if not Result then Exit;
  Result := Self.Start;
end;

function TWindowsController.ShowDockerUITrayMenu: Boolean;
var
  I: Integer;
  Tray: TTray;
begin
  Result := False;
  Tray := TTray.Create;

  // Scan the visible tray button list for the button which belongs to the
  // Docker UI.
  for I := 0 to Tray.TrayButtonCount - 1 do
  begin
    if Pos('Docker', Tray.TrayButton[I].Caption) > 0 then
    begin
      try
        Tray.TrayButton[I].Popup;
        Result := True;
      except
        on exception do
          // Ignore the exception.
      end;

      FreeAndNil(Tray);
      Exit;
    end;
  end;

  // Scan the overflowing tray button list for the button which belongs to the
  // Docker UI.
  for I := 0 to Tray.OverflowButtonCount - 1 do
  begin
    if Pos('Docker', Tray.OverflowButton[I].Caption) > 0 then
    begin
      try
        Tray.OverflowButton[I].Popup;
        Result := True;
      except
        on exception do
          // Ignore the exception.
      end;

      FreeAndNil(Tray);
      Exit;
    end;
  end;

  FreeAndNil(Tray);
end;

function TWindowsController.Start: Boolean;
const
  TIMEOUT = 120;
var
  I: Integer;
  Path: String;
  Process: TProcess;
  ProcessId: Cardinal;
begin
  Result := False;
  FErrorMessage := 'Unhandled error';

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

  // Wait for the Docker service to start responding to commands.
  for I := 1 to TIMEOUT do
  begin
    if IsDockerServiceRunning then
    begin
      Result := True;
      Exit;
    end;

    Sleep(1000);
  end;

  FErrorMessage := 'Failed to start the Docker service';
end;

function TWindowsController.Stop: Boolean;
const
  TIMEOUT = 120;
  TIMEOUT_WINDOW = 5;
var
  CursorPostion: TPoint;
  I: Integer;
  ProcessId: Cardinal;
  WindowHandle: Cardinal;
  WindowRect: TRect;
begin
  Result := False;
  FErrorMessage := 'Unhandled error';

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

  // Simulate a right-click on the tray icon for the Docker UI application as we
  // need to make the popup menu (window) visible.
  if not ShowDockerUITrayMenu then
  begin
    FErrorMessage := 'Failed to trigger the Docker UI''s tray menu';
    Exit;
  end;

  // Determine the handle for the Docker UI tray menu window.
  for I := 1 to TIMEOUT_WINDOW * 100 do
  begin
    WindowHandle := GetDockerUITrayWindowHandle(ProcessId);

    if WindowHandle <> 0 then
      Break;

    Sleep(10);
  end;

  if WindowHandle = 0 then
  begin
    FErrorMessage := 'Failed to find the Docker UI tray window';
    Exit;
  end;

  // Simulate a mouse click on the 'Quit' item in the Docker UI's tray menu.
  ShowWindow(WindowHandle, SW_SHOWNOACTIVATE);
  BringWindowToTop(WindowHandle);

  WindowRect.Create(0, 0, 0, 0);

  if not GetWindowRect(WindowHandle, WindowRect) then
  begin
    FErrorMessage := 'Failed to determine the Docker UI tray window placement';
    Exit;
  end;

  GetCursorPos(CursorPostion);
  SetCursorPos(WindowRect.Left + 10, WindowRect.Top + WindowRect.Height - 10);
  mouse_event(MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
  SetCursorPos(CursorPostion.x, CursorPostion.y);

  // Wait for the Docker UI process to terminate but do not wait for too long as
  // this entire approach can easily fail, if a new version of the Docker UI is
  // released with a re-organized tray menu.
  for I := 1 to TIMEOUT do
  begin
    ProcessId := GetDockerUIProcessId;

    if ProcessId = 0 then
    begin
      Result := True;
      Exit;
    end;

    Sleep(1000);
  end;

  FErrorMessage := 'Failed to terminate the Docker UI process';
end;

end.

