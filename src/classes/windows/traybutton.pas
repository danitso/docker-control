unit TrayButton;

{$MODE DELPHI}

interface

uses
  FGL,
  SysUtils,
  Windows;

type
  { TTrayButton }
  TTrayButton = class;

  { TTrayButtonArray }
  TTrayButtonList = TFPGObjectList<TTrayButton>;

  { TTrayButton }
  TTrayButton = class
  protected
    FBoundingRect: TRect;
    FButtonIndex: Integer;
    FCaption: AnsiString;
    FCommand: Integer;
    FImageIndex: Integer;
    FOverflow: Boolean;
    FParent: TObject;
  public
    function Popup: HWND;

    property BoundingRect: TRect read FBoundingRect write FBoundingRect;
    property ButtonIndex: Integer read FButtonIndex write FButtonIndex;
    property Caption: AnsiString read FCaption write FCaption;
    property Command: Integer read FCommand write FCommand;
    property ImageIndex: Integer read FImageIndex write FImageIndex;
    property Overflow: Boolean read FOverflow write FOverflow;
    property Parent: TObject read FParent write FParent;
  end;

implementation

uses
  Tray;

function TTrayButton.Popup: HWND;
const
  TIMEOUT = 5;
var
  CursorPostion: TPoint;
  I: Integer;
  PopupWindowHandle: HWND;
  PopupWindowHandleNew: HWND;
  PopupWindowPoint: POINT;
  Tray: TTray;
  TrayButtonX: Integer;
  TrayButtonY: Integer;
  WindowHandle: HWND;
  WindowRect: TRect;
begin
  Result := 0;

  // Typecast the Tray object to TTray to avoid having to use 'as' multiple
  // times.
  Tray := FParent as TTray;

  // Determine if we are dealing with a button in the overflow tray window or in
  // the visible tray window, and specify the dimensions according to this. Once
  // the tray class is fully implemented, it should be possible to simply use
  // the dimensions queried from the ToolbarWindow32 class.
  if FOverflow then
    WindowHandle := Tray.OverflowWindow
  else
    WindowHandle := Tray.TrayWindow;

  // In case we are dealing with the overflow tray window, we need to ensure
  // that it is visible and is the top most window at its location.
  if FOverflow then
  begin
    ShowWindow(WindowHandle, SW_SHOWNOACTIVATE);

    I := 0;

    for I := 1 to TIMEOUT * 1000 do
    begin
      if IsWindowVisible(WindowHandle) then
        Break;

      Sleep(1);
    end;

    if IsWindowVisible(WindowHandle) then
      BringWindowToTop(WindowHandle)
    else
      Exit;
  end;

  // Determine the dimensions of the tray window and calculate the number of
  // columns based on the button dimensions.
  WindowRect.Create(0, 0, 0, 0);

  if not GetWindowRect(WindowHandle, WindowRect) then
    raise Exception.Create('Failed to determine the tray window position');

  // Calculate the position of the tray button relative to the screen.
  TrayButtonX := WindowRect.Left + FBoundingRect.Left +
    (FBoundingRect.Width div 2);
  TrayButtonY := WindowRect.Top + FBoundingRect.Top +
    (FBoundingRect.Height div 2);

  // Determine the window handle for the window which is currently visible at
  // the location we expect the popup menu to appear.
  PopupWindowPoint.Create(
    TrayButtonX - FBoundingRect.Width,
    TrayButtonY - FBoundingRect.Height
  );
  PopupWindowHandle := WindowFromPoint(PopupWindowPoint);

  // Move the cursor to the middle of the tool button and simulate a right click
  // on it in order to trigger the popup menu. While we would prefer to do this
  // without moving the mouse and instead use PostMessage(), it has become clear
  // that we cannot target the correct event listener.
  GetCursorPos(CursorPostion);
  SetCursorPos(TrayButtonX, TrayButtonY);

  Mouse_Event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0);
  Mouse_Event(MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);

  // Wait for the popup menu to appear before hiding the tray window.
  for I := 1 to TIMEOUT * 1000 do
  begin
    PopupWindowHandleNew := WindowFromPoint(PopupWindowPoint);

    if (PopupWindowHandleNew <> PopupWindowHandle) and
      IsWindowVisible(PopupWindowHandleNew) and
      (GetWindowLongPtr(PopupWindowHandleNew, GWL_STYLE) and WS_POPUP <> 0) then
    begin
      Result := PopupWindowHandleNew;
      Break;
    end;

    Sleep(1);
  end;

  // Move the cursor back to its original position, if the user has not moved it
  // in the meantime.
  SetCursorPos(CursorPostion.x, CursorPostion.y);

  // Hide the overflow window again in case we had to make it visible.
  if FOverflow then
    ShowWindow(WindowHandle, SW_HIDE);

  // Bring the popup window to the top of the screen.
  if Result <> 0 then
    BringWindowToTop(Result);
end;

end.

