unit TrayButton;

{$MODE DELPHI}

interface

uses
  Classes,
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
    FButtonIndex: Integer;
    FCaption: AnsiString;
    FImageIndex: Integer;
    FOverflow: Boolean;
    FParent: TObject;
    FSize: TSize;
  public
    procedure Popup;

    property ButtonIndex: Integer read FButtonIndex write FButtonIndex;
    property Caption: AnsiString read FCaption write FCaption;
    property ImageIndex: Integer read FImageIndex write FImageIndex;
    property Overflow: Boolean read FOverflow write FOverflow;
    property Parent: TObject read FParent write FParent;
    property Size: TSize read FSize write FSize;
  end;

implementation

uses
  Tray;

procedure TTrayButton.Popup;
const
  TIMEOUT = 10;
var
  Cols: Integer;
  CursorPostion: TPoint;
  I: Integer;
  PopupWindowHandle: HWND;
  PopupWindowPoint: POINT;
  Tray: TTray;
  TrayButtonCount: Integer;
  TrayButtonX: Integer;
  TrayButtonY: Integer;
  WindowHandle: HWND;
  WindowRect: TRect;
  Rows: Integer;
begin
  // Typecast the Tray object to TTray to avoid having to use 'as' multiple
  // times.
  Tray := FParent as TTray;

  // Determine if we are dealing with a button in the overflow tray window or in
  // the visible tray window, and specify the dimensions according to this. Once
  // the tray class is fully implemented, it should be possible to simply use
  // the dimensions queried from the ToolbarWindow32 class.
  if FOverflow then
  begin
    TrayButtonCount := Tray.OverflowButtonCount;
    WindowHandle := Tray.OverflowWindow;
  end
  else
  begin
    TrayButtonCount := Tray.TrayButtonCount;
    WindowHandle := Tray.TrayWindow;
  end;

  // In case we are dealing with the overflow tray window, we need to ensure
  // that it is visible and the top most window at its location.
  if FOverflow then
  begin
    ShowWindow(WindowHandle, SW_SHOW);
    BringWindowToTop(WindowHandle);
  end;

  // Determine the dimensions of the tray window and calculate the number of
  // columns and rows based on the button dimensions.
  WindowRect.Create(0, 0, 0, 0);

  if not GetWindowRect(WindowHandle, WindowRect) then
    raise Exception.Create('Failed to determine the tray window position');

  Cols := WindowRect.Width div Self.Size.Width;
  Rows := 1;

  while (Cols * Rows < TrayButtonCount) do
    Inc(Rows);

  // Calculate the desktop coordinates for the tray icon (the tool button).
  TrayButtonX := Self.Size.Width div 2 + ((FButtonIndex mod Cols) *
    Self.Size.Width);
  TrayButtonY := Self.Size.Height div 2 + ((ButtonIndex div Cols) *
    Self.Size.Height);

  // Determine the window handle for the window which is currently visible at
  // the location we expect the popup menu to appear.
  PopupWindowPoint.Create(
    WindowRect.Left + TrayButtonX - 16,
    WindowRect.Top + TrayButtonY - 16
  );
  PopupWindowHandle := WindowFromPoint(PopupWindowPoint);

  // Move the cursor to the middle of the tool button and simulate a right click
  // on it in order to trigger the popup menu. While we would prefer to do this
  // without moving the mouse and instead use PostMessage(), it has become clear
  // that we cannot target the correct event listener.
  GetCursorPos(CursorPostion);
  SetCursorPos(WindowRect.Left + TrayButtonX, WindowRect.Top + TrayButtonY);

  mouse_event(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0);
  mouse_event(MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);

  // Wait for the popup menu to appear before hiding the tray window and moving
  // the cursor back to its previous location.
  for I := 1 to TIMEOUT * 100 do
  begin
    if WindowFromPoint(PopupWindowPoint) <> PopupWindowHandle then
      Break;

    Sleep(10);
  end;

  if FOverflow then
    ShowWindow(WindowHandle, SW_HIDE);

  SetCursorPos(CursorPostion.x, CursorPostion.y);
end;

end.

