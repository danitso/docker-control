unit Tray;

{$MODE DELPHI}

interface

uses
  Classes,
  StrUtils,
  SysUtils,
  TrayButton,
  Windows;

type
  { TTray }
  TTray = class
  protected
    FOverflowButtons: TTrayButtonList;
    FOverflowToolBar: HWND;
    FOverflowWindow: HWND;
    FTrayButtons: TTrayButtonList;
    FTrayToolBar: HWND;
    FTrayWindow: HWND;

    function FindOverflowToolBar: HWND;
    function FindOverflowWindow: HWND;

    function FindTrayToolBar: HWND;
    function FindTrayWindow: HWND;

    function GetButtonCount(const ToolBarWindow: HWND): Integer;

    function GetOverflowButton(const AIndex: Integer): TTrayButton;
    function GetOverflowButtonCount: Integer;

    function GetTrayButton(const AIndex: Integer): TTrayButton;
    function GetTrayButtonCount: Integer;

    procedure LoadButton(
      const ProcessHandle: HANDLE;
      const ToolBarWindow: HWND;
      const Index: Integer;
      const ButtonList: TTrayButtonList;
      const Overflow: Boolean = False
    );
    procedure LoadButtons(
      const ToolBarWindow: HWND;
      const ButtonList: TTrayButtonList;
      const Overflow: Boolean = False
    );
  public
    constructor Create;
    destructor Destroy; override;

    procedure Reset;

    property OverflowButton[const AIndex: INteger]: TTrayButton
      read GetOverflowButton;
    property OverflowButtonCount: Integer read GetOverflowButtonCount;
    property OverflowToolBar: HWND read FOverflowToolBar;
    property OverflowWindow: HWND read FOverflowWindow;

    property TrayButton[const AIndex: INteger]: TTrayButton
      read GetTrayButton;
    property TrayButtonCount: Integer read GetTrayButtonCount;
    property TrayToolBar: HWND read FTrayToolBar;
    property TrayWindow: HWND read FTrayWindow;
  end;

implementation

constructor TTray.Create;
begin
  inherited;

  FOverflowButtons := TTrayButtonList.Create(True);
  FTrayButtons := TTrayButtonList.Create(True);

  Reset;
end;

destructor TTray.Destroy;
begin
  FOverflowButtons.Free;
  FTrayButtons.Free;

  inherited;
end;

function TTray.FindOverflowToolBar: HWND;
begin
  Result := FindOverflowWindow;

  if Result <> 0 then
    Result := FindWindowEx(Result, 0, 'ToolbarWindow32', nil);
end;

function TTray.FindOverflowWindow: HWND;
begin
  Result := FindWindow('NotifyIconOverflowWindow', nil);
end;

function TTray.FindTrayToolBar: HWND;
begin
  Result := FindTrayWindow;

  if Result <> 0 then
    Result := FindWindowEx(Result, 0, 'ToolbarWindow32', nil);
end;

function TTray.FindTrayWindow: HWND;
begin
  Result := FindWindow('Shell_TrayWnd', nil);

  if Result <> 0 then
  begin
    Result := FindWindowEx(Result, 0, 'TrayNotifyWnd', nil);

    if Result <> 0 then
      Result := FindWindowEx(Result, 0, 'SysPager', nil);
  end;
end;

function TTray.GetButtonCount(const ToolBarWindow: HWND): Integer;
begin
  Result := SendMessage(ToolBarWindow, TB_BUTTONCOUNT, 0, 0);
end;

function TTray.GetOverflowButton(const AIndex: Integer): TTrayButton;
begin
  Result := FOverflowButtons.Items[AIndex];
end;

function TTray.GetOverflowButtonCount: Integer;
begin
  Result := FOverflowButtons.Count;
end;

function TTray.GetTrayButton(const AIndex: Integer): TTrayButton;
begin
  Result := FTrayButtons.Items[AIndex];
end;

function TTray.GetTrayButtonCount: Integer;
begin
  Result := FTrayButtons.Count;
end;

procedure TTray.LoadButton(
  const ProcessHandle: HANDLE;
  const ToolBarWindow: HWND;
  const Index: Integer;
  const ButtonList: TTrayButtonList;
  const Overflow: Boolean = False
);
var
  BytesRead: QWord;
  I: Integer;
  RawButton: Pointer;
  RawResult: Boolean;
  ToolButton: TBBUTTON;
  ToolCaption: AnsiString;
  TrayButton: TTrayButton;
begin
  // Create a new TTrayButton instance and populate it with the values retrieved
  // so far.
  TrayButton := TTrayButton.Create;
  TrayButton.ButtonIndex := Index;
  TrayButton.Overflow := Overflow;
  TrayButton.Parent := Self;

  // Initialize the local variables in order to avoid issues when passing them
  // as references.
  BytesRead := 0;
  RawButton := nil;
  RawResult := False;

  try
    // Allocate memory for a TBBUTTON structure in the application which owns
    // the toolbar window.
    RawButton := Pointer(VirtualAllocEx(
      ProcessHandle,
      nil,
      SizeOf(RawButton),
      MEM_COMMIT,
      PAGE_READWRITE
    ));

    // Tell the external application to copy the TBBUTTON structure to the newly
    // allocated space.
    {$HINTS OFF}
    RawResult := SendMessage(
      ToolBarWindow,
      TB_GETBUTTON,
      Index,
      NativeInt(RawButton)
    ) <> 0;
    {$HINTS ON}

    if not RawResult then
      raise Exception.Create('Failed to retrieve TBBUTTON pointer');

    // Copy the TBBUTTON structure from the external application into the memory
    // space for this application in order to access it.
    RawResult := ReadProcessMemory(
      ProcessHandle,
      RawButton,
      @ToolButton,
      SizeOf(ToolButton),
      BytesRead
    );

    if not RawResult then
      raise Exception.Create('Failed to retrieve TBBUTTON struct');

    // Extract the image index from the TBBUTTON structure and store it in the
    // wrapper class instance.
    TrayButton.ImageIndex := ToolButton.iBitmap;

    // Extract the button's caption and while these may actually be indexes, we
    // simply assume that they are not, which is usually the case. We also
    // ignore the fact that the caption is UTF-16 so we simply strip away any
    // NULL characters which are not used as a string terminator.
    SetLength(ToolCaption, 1024);
    I := 0;

    while I < Length(ToolCaption) do
    begin
      {$HINTS OFF}
      RawResult := ReadProcessMemory(
        ProcessHandle,
        Pointer(ToolButton.iString) + I,
        @ToolCaption[I + 1],
        2,
        BytesRead
      );
      {$HINTS ON}

      if not RawResult then
        raise Exception.Create('Failed to retrieve TBBUTTON caption');

      if (ToolCaption[I] = #0) and (ToolCaption[I + 1] = #0) then
      begin
        SetLength(ToolCaption, I);
        Break;
      end;

      Inc(I, 2);
    end;

    TrayButton.Caption := Trim(AnsiReplaceStr(ToolCaption, #0, ''));
    ButtonList.Add(TrayButton);
  except
    on E: exception do
    begin
      TrayButton.Free;
      raise E;
    end;
  end;

  if RawButton <> nil then
  begin
    if not VirtualFreeEx(ProcessHandle, RawButton, 0, MEM_RELEASE) then
      raise Exception.Create('Failed to free TBBUTTON pointer');
  end;
end;

procedure TTray.LoadButtons(
  const ToolBarWindow: HWND;
  const ButtonList: TTrayButtonList;
  const Overflow: Boolean = False
);
var
  ButtonCount: Int64;
  I: Integer;
  OwnerProcessHandle: HANDLE;
  OwnerProcessId: DWORD;
begin
  // Ensure that the list is empty to avoid duplicate buttons.
  ButtonList.Clear;

  // Determine the id of the process which the tray toolbar belongs to.
  OwnerProcessId := 0;

  if GetWindowThreadProcessId(ToolBarWindow, OwnerProcessId) = 0 then
    raise Exception.Create('Failed to find tray owner window handle');

  // Create new TTrayButton instances based on the tool button structures.
  try
    ButtonCount := GetButtonCount(ToolBarWindow);
    OwnerProcessHandle := OpenProcess(
      PROCESS_VM_OPERATION or
      PROCESS_VM_READ or
      PROCESS_VM_WRITE or
      PROCESS_QUERY_INFORMATION,
      False,
      OwnerProcessId
    );

    for I := 0 to ButtonCount - 1 do
      LoadButton(OwnerProcessHandle, ToolBarWindow, I, ButtonList, Overflow);
  finally
    if OwnerProcessHandle <> 0 then
      CloseHandle(OwnerProcessHandle);
  end;
end;

procedure TTray.Reset;
begin
  FOverflowToolBar := FindOverflowToolBar;
  FOverflowWindow := FindOverflowWindow;

  FTrayToolBar := FindTrayToolBar;
  FTrayWindow := FindTrayWindow;

  LoadButtons(FOverflowToolBar, FOverflowButtons, True);
  LoadButtons(FTrayToolBar, FTrayButtons);
end;

end.

