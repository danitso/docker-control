program DockerControl;

{$MODE DELPHI}

uses
  {$IFDEF UNIX}
    {$IFDEF UseCThreads}
    cthreads,
    {$ENDIF}
  {$ENDIF}
  {$IFDEF DARWIN}
  MacConfiguration,
  MacController,
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  Tray,
  TrayButton,
  WindowsConfiguration,
  WindowsController,
  WindowsShares,
  WinPEImageReader,
  {$ENDIF}
  ConfigurationInterface,
  ControllerInterface,
  CustApp,
  DockerConfiguration,
  DockerController,
  FileInfo,
  StringFunctions,
  SysUtils;

type
  { TDockerControl }
  TDockerControl = class(TCustomApplication)
  private const
    COMMAND_CONFIG = 'config';
    COMMAND_RESET = 'reset';
    COMMAND_RESTART = 'restart';
    COMMAND_START = 'start';
    COMMAND_STOP = 'stop';
    COMMAND_VERSION = 'version';
    EXIT_CODE_ERROR = 1;
    OPTION_VERSION_LONG = '--version';
    OPTION_VERSION_SHORT = '-v';
  protected
    FController: IControllerInterface;

    procedure DoRun; override;

    procedure ExecuteConfig;
    procedure ExecuteReset;
    procedure ExecuteRestart;
    procedure ExecuteStart;
    procedure ExecuteStop;
    procedure ExecuteVersion;

    procedure WriteErrorString(const Message: String);
    procedure WriteUsageString(const Args: array of String);
  end;

{ TDockerControl }

procedure TDockerControl.DoRun;
var
  Command: string;
begin
  // Print the usage string, if more or less than one command line argument has
  // been specified.
  if ParamCount < 1 then
  begin
    WriteUsageString([]);
    Terminate(EXIT_CODE_ERROR);
    Exit;
  end;

  // Create a new controller class instance which supports the current operating
  // system.
  {$IFDEF MSWINDOWS}
  FController := TWindowsController.Create;
  {$ELSE}
    {$IFDEF DARWIN}
    FController := TMacController.Create;
    {$ELSE}
    WriteErrorString('Unsupported operating system');
    Terminate(EXIT_CODE_ERROR);
    Exit;
    {$ENDIF}
  {$ENDIF}

  // Perform the specified command, if it is valid.
  Command := ParamStr(1);

  if Command = COMMAND_CONFIG then
    ExecuteConfig
  else if Command = COMMAND_RESET then
    ExecuteReset
  else if Command = COMMAND_RESTART then
    ExecuteRestart
  else if Command = COMMAND_START then
    ExecuteStart
  else if Command = COMMAND_STOP then
    ExecuteStop
  else if (Command = COMMAND_VERSION) or
          (Command = OPTION_VERSION_LONG) or
          (Command = OPTION_VERSION_SHORT) then
    ExecuteVersion
  else
  begin
    WriteErrorString(Format('Unknown command ''%s''', [Command]));
    WriteUsageString([]);
    Terminate(EXIT_CODE_ERROR);
  end;

  // Ensure that the program is always terminated at this point.
  if not Terminated then
    Terminate;
end;

procedure TDockerControl.ExecuteConfig;
const
  PARAMETER_GET = 'get';
  PARAMETER_SET = 'set';
var
  I: Integer;
begin
  if ParamCount < 3 then
  begin
    WriteUsageString([
      Format('<%s|%s>', [PARAMETER_GET, PARAMETER_SET]),
      '<name>'
    ]);
    Terminate(EXIT_CODE_ERROR);
  end
  else if ParamStr(2) = PARAMETER_GET then
  begin
    try
      for I := 3 to ParamCount do
        WriteLn(FController.GetOption(ParamStr(I)));
    except
      on E: exception do
      begin
        WriteErrorString(E.Message);
        Terminate(EXIT_CODE_ERROR);
      end;
    end;
  end
  else if ParamStr(2) = PARAMETER_SET then
  begin
    if ParamCount < 4 then
    begin
      WriteUsageString([ParamStr(2), '<name>', '<value>']);
      Terminate(EXIT_CODE_ERROR);
    end
    else
    begin
      I := 3;

      while (I < ParamCount) do
      begin
        try
          FController.SetOption(ParamStr(I), ParamStr(I + 1));
          WriteLn(Format('Changed %s to ''%s''', [
            ParamStr(I),
            FController.GetOption(ParamStr(I))
          ]));
        except
          on E: exception do
          begin
            WriteErrorString(E.Message);
            Terminate(EXIT_CODE_ERROR);
            Exit;
          end;
        end;

        Inc(I, 2);
      end;
    end;
  end
  else
  begin
    WriteUsageString([
      Format('<%s|%s>', [PARAMETER_GET, PARAMETER_SET]),
      '<name>'
    ]);
    Terminate(EXIT_CODE_ERROR);
  end;
end;

procedure TDockerControl.ExecuteReset;
begin
  WriteLn('Resetting the Docker service');

  try
    if not FController.Reset then
    begin
      WriteErrorString(FController.GetErrorMessage);
      Terminate(EXIT_CODE_ERROR);
    end;
  except
    on E: exception do
      WriteErrorString(E.Message);
  end;
end;

procedure TDockerControl.ExecuteRestart;
begin
  WriteLn('Restarting the Docker service');

  try
    if not FController.Restart then
    begin
      WriteErrorString(FController.GetErrorMessage);
      Terminate(EXIT_CODE_ERROR);
    end;
  except
    on E: exception do
      WriteErrorString(E.Message);
  end;
end;

procedure TDockerControl.ExecuteStart;
begin
  WriteLn('Starting the Docker service');

  try
    if not FController.Start then
    begin
      WriteErrorString(FController.GetErrorMessage);
      Terminate(EXIT_CODE_ERROR);
    end;
  except
    on E: exception do
      WriteErrorString(E.Message);
  end;
end;

procedure TDockerControl.ExecuteStop;
begin
  WriteLn('Stopping the Docker service');

  try
    if not FController.Stop then
    begin
      WriteErrorString(FController.GetErrorMessage);
      Terminate(EXIT_CODE_ERROR);
    end;
  except
    on E: exception do
      WriteErrorString(E.Message);
  end;
end;

procedure TDockerControl.ExecuteVersion;
var
  FileVerInfo: TFileVersionInfo;
begin
  FileVerInfo := TFileVersionInfo.Create(nil);

  try
    // Read the version information from the binary instead of using hardcoded
    // values such as constants.
    FileVerInfo.ReadFileInfo;

    // Write the version information string to the standard output stream.
    WriteLn(Format('%s version %s (%s)', [
      FileVerInfo.VersionStrings.Values['ProductName'],
      Copy(
        FileVerInfo.VersionStrings.Values['FileVersion'],
        1,
        LastDelimiter('.', FileVerInfo.VersionStrings.Values['FileVersion']) - 1
      ),
      {$I %FPCTARGETOS%}
    ]));
  except
    on E: exception do
      WriteErrorString(E.Message);
  end;

  FileVerInfo.Free;
end;

procedure TDockerControl.WriteErrorString(const Message: String);
begin
  WriteLn(Format('ERROR: %s', [Message]));
end;

procedure TDockerControl.WriteUsageString(const Args: array of String);
var
  Command: String;
  Index: Integer;
begin
  // Remove the path to the executable as well as the extension and use that as
  // the command.
  Command := ExtractFileName(ParamStr(0));
  Index := LastDelimiter('.', Command);

  if Index > 0 then
    Command := Copy(Command, 1, Index - 1);

  // Write the usage string to the standard output stream.
  if ParamCount > 0 then
  begin
    Write(Format('Usage: %s %s', [Command, ParamStr(1)]));

    for Index := 0 to High(Args) do
      Write(' ' + Args[Index]);

    WriteLn;
  end
  else
  begin
    WriteLn(Format('Usage: %s <%s|%s|%s|%s|%s|%s>', [
      Command,
      COMMAND_CONFIG,
      COMMAND_RESET,
      COMMAND_RESTART,
      COMMAND_START,
      COMMAND_STOP,
      COMMAND_VERSION
    ]));
  end;
end;

var
  Application: TDockerControl;

{$R *.res}

begin
  Application:=TDockerControl.Create(nil);
  Application.Title:='Docker Control';
  Application.Run;
  Application.Free;
end.

