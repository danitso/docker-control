unit WindowsController;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

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
  protected class var
    FWindowHandles: array of THandle;
    FWindowProcessHandles: array of THandle;
  protected
    FErrorMessage: string;

    function GetProcessId: Cardinal;
    function GetTrayWindowHandle(const ProcessId: Cardinal): Cardinal;
  public
    function GetErrorMessage: String;
    function Restart: Boolean;
    function Start: Boolean;
    function Stop: Boolean;
  end;

implementation

function TWindowsController.GetErrorMessage: String;
begin
  Result := FErrorMessage;
end;

function TWindowsController.GetProcessId: Cardinal;
const
  EXE_NAME = 'Docker for Windows.exe';
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
        if CompareText(PE.szExeFile, EXE_NAME) = 0 then
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

function TWindowsController.GetTrayWindowHandle(
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

function TWindowsController.Restart: Boolean;
begin
  Result := Self.Stop;
  if not Result then Exit;
  Result := Self.Start;
end;

function TWindowsController.Start: Boolean;
const
  TIMEOUT = 120;
var
  I: Integer;
  Path: String;
  Process: TProcess;
  ProcessId: Cardinal;
  Registry: TRegistry;
begin
  Result := False;
  FErrorMessage := 'Unhandled error';

  // Determine if Docker UI is already running in which case we do not need to
  // try to start it.
  ProcessId := GetProcessId;

  if ProcessId <> 0 then
  begin
    Result := True;
    Exit;
  end;

  // Determine the path to the Docker for Windows executable by reading it from
  // the Windows Registry and run it, if it exists.
  Registry := TRegistry.Create;

  try
    Registry.RootKey := HKEY_LOCAL_MACHINE;

    if Registry.OpenKeyReadOnly('\SOFTWARE\Docker Inc.\Docker\1.0') then
      Path := Registry.ReadString('AppPath');
  finally
    Registry.Free;
  end;

  if Path = '' then
  begin
    FErrorMessage := 'Failed to determine the path to the Docker UI executable';
    Exit;
  end;

  Path := Path + '\Docker for Windows.exe';

  if not FileExists(Path) then
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
    try
      Process := TProcess.Create(nil);
      Process.Executable := 'docker';
      Process.Parameters.Append('ps');
      Process.Options := [poWaitOnExit, poUsePipes];
      Process.Execute;

      if Process.ExitCode = 0 then
      begin
        Result := True;
        Exit;
      end;
    finally
      Process.Free;
    end;

    Sleep(1000);
  end;

  FErrorMessage := 'Failed to start the Docker service';
end;

function TWindowsController.Stop: Boolean;
const
  TIMEOUT = 120;
  TIMEOUT_WINDOW = 10;
var
  CursorPostion: TPoint;
  I: Integer;
  ProcessId: Cardinal;
  Tray: TTray;
  TrayClicked: Boolean;
  WindowHandle: Cardinal;
  WindowRect: TRect;
begin
  Result := False;
  FErrorMessage := 'Unhandled error';

  // Determine if Docker UI is not running in which case we do not need to try
  // to stop it.
  ProcessId := GetProcessId;

  if ProcessId = 0 then
  begin
    Result := True;
    Exit;
  end;

  // Simulate a right-click on the tray icon for the Docker UI application as we
  // need to make the popup menu (window) visible.
  Tray := TTray.Create;
  TrayClicked := False;

  for I := 0 to Tray.TrayButtonCount - 1 do
  begin
    if Pos('Docker', Tray.TrayButton[I].Caption) > 0 then
    begin
      Tray.TrayButton[I].Popup;
      TrayClicked := True;
      Break;
    end;
  end;

  if not TrayClicked then
  begin
    for I := 0 to Tray.OverflowButtonCount - 1 do
    begin
      if Pos('Docker', Tray.OverflowButton[I].Caption) > 0 then
      begin
        Tray.OverflowButton[I].Popup;
        TrayClicked := True;
        Break;
      end;
    end;
  end;

  Tray.Free;

  if not TrayClicked then
  begin
    FErrorMessage := 'Failed to trigger the Docker UI''s tray popup menu';
    Exit;
  end;

  // Determine the handle for the Docker UI tray menu window.
  for I := 1 to TIMEOUT_WINDOW * 10 do
  begin
    WindowHandle := GetTrayWindowHandle(ProcessId);

    if WindowHandle <> 0 then
      Break;

    Sleep(100);
  end;

  if WindowHandle = 0 then
  begin
    FErrorMessage := 'Failed to find the Docker UI tray window';
    Exit;
  end;

  // Simulate a mouse click on the 'Quit' menu item.
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
  // released.
  for I := 1 to TIMEOUT do
  begin
    ProcessId := GetProcessId;

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

