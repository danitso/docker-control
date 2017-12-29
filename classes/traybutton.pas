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
  public
    procedure Popup;

    property ButtonIndex: Integer read FButtonIndex write FButtonIndex;
    property Caption: AnsiString read FCaption write FCaption;
    property ImageIndex: Integer read FImageIndex write FImageIndex;
    property Overflow: Boolean read FOverflow write FOverflow;
    property Parent: TObject read FParent write FParent;
  end;

implementation

uses
  Tray;

procedure TTrayButton.Popup;
var
  Cols: Integer;
  CursorPostion: TPoint;
  Tray: TTray;
  TrayButtonCount: Integer;
  TrayButtonHeight: Integer;
  TrayButtonWidth: Integer;
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
    TrayButtonHeight := 40;
    TrayButtonWidth := 40;
    WindowHandle := Tray.OverflowWindow;
  end
  else
  begin
    TrayButtonCount := Tray.TrayButtonCount;
    TrayButtonHeight := 40;
    TrayButtonWidth := 24;
    WindowHandle := Tray.TrayWindow;
  end;

  // Determine the dimensions of the tray window and calculate the number of
  // columns and rows based on the button dimensions.
  WindowRect.Create(0, 0, 0, 0);

  if not GetWindowRect(WindowHandle, WindowRect) then
    raise Exception.Create('Failed to determine the tray window position');

  Cols := WindowRect.Width div TrayButtonWidth;
  Rows := 1;

  while (Cols * Rows < TrayButtonCount) do
    Inc(Rows);

  // Calculate the desktop coordinates for the tray icon (the tool button).
  TrayButtonX := TrayButtonWidth div 2 + ((FButtonIndex mod Cols) *
    TrayButtonWidth);
  TrayButtonY := TrayButtonHeight div 2 + ((ButtonIndex div Cols) *
    TrayButtonHeight);

  // In case we are dealing with the overflow tray window, we need to ensure
  // that it is visible and the top most window at its location.
  if FOverflow then
  begin
    ShowWindow(WindowHandle, SW_SHOWNOACTIVATE);
    BringWindowToTop(WindowHandle);
  end;

  // Move the cursor to the middle of the tool button and simulate a right click
  // on it in order to trigger the popup menu. While we would prefer to do this
  // without moving the mouse and instead use PostMessage(), it has become clear
  // that we cannot target the correct event listener.
  GetCursorPos(CursorPostion);
  SetCursorPos(WindowRect.Left + TrayButtonX, WindowRect.Top + TrayButtonY);
  mouse_event(MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
  Sleep(1);
  SetCursorPos(CursorPostion.x, CursorPostion.y);

  // Hide the tray window again in case we are dealing with an overflowing
  // button.
  if FOverflow then
    ShowWindow(WindowHandle, SW_HIDE);
end;

end.

