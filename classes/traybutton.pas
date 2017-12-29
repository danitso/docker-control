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
  Tray := FParent as TTray;

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

  WindowRect.Create(0, 0, 0, 0);

  if not GetWindowRect(WindowHandle, WindowRect) then
    raise Exception.Create('Failed to determine the tray window position');

  if FOverflow then
  begin
    ShowWindow(WindowHandle, SW_SHOWNOACTIVATE);
    BringWindowToTop(WindowHandle);
  end;

  Cols := WindowRect.Width div TrayButtonWidth;
  Rows := 1;

  while (Cols * Rows < TrayButtonCount) do
    Inc(Rows);

  TrayButtonX := TrayButtonWidth div 2 + ((FButtonIndex mod Cols) *
    TrayButtonWidth);
  TrayButtonY := TrayButtonHeight div 2 + ((ButtonIndex div Cols) *
    TrayButtonHeight);

  GetCursorPos(CursorPostion);
  SetCursorPos(WindowRect.Left + TrayButtonX, WindowRect.Top + TrayButtonY);
  mouse_event(MOUSEEVENTF_ABSOLUTE or MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
  SetCursorPos(CursorPostion.x, CursorPostion.y);

  if FOverflow then
    ShowWindow(WindowHandle, SW_HIDE);
end;

end.

