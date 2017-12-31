program docker_control;

{$MODE DELPHI}

uses
  {$IFDEF UNIX}
    {$IFDEF UseCThreads}
    cthreads,
    {$ENDIF}
  {$ENDIF}
  ControllerInterface,
  DockerConfiguration,
  {$IFDEF MSWINDOWS}
  Tray,
  TrayButton,
  WindowsController,
  WinPEImageReader,
  {$ENDIF}
  CustApp,
  FileInfo,
  SysUtils;

type
  { TDockerControl }
  TDockerControl = class(TCustomApplication)
  private const
    COMMAND_CONFIG = 'config';
    COMMAND_RESTART = 'restart';
    COMMAND_START = 'start';
    COMMAND_STOP = 'stop';
    COMMAND_VERSION = 'version';
    OPTION_VERSION_LONG = '--version';
    OPTION_VERSION_SHORT = '-v';
  protected
    procedure DoRun; override;
    procedure WriteUsageString(const Args: array of String);
    procedure WriteVersionString;
  end;

{ TDockerControl }

procedure TDockerControl.DoRun;
var
  Command: string;
  Controller: IControllerInterface;
begin
  // Print the usage string, if more or less than one command line argument has
  // been specified.
  if ParamCount < 1 then
  begin
    WriteUsageString([]);
    Terminate(1);
    Exit;
  end;

  // Create a new Docker controller class instance which supports the current
  // operating system.
  {$IFDEF MSWINDOWS}
  Controller := TWindowsController.Create;
  {$ENDIF}

  if not Assigned(Controller) then
  begin
    WriteLn('ERROR: Unsupported operating system');
    Terminate(1);
    Exit;
  end;

  // Perform the specified command, if a valid command is specified and output
  // an error message in case the command fails.
  Command := ParamStr(1);

  if Command = COMMAND_CONFIG then
  begin
    if ParamCount < 3 then
    begin
      WriteUsageString(['<get|set>', '<name>']);
      Terminate(1);
      Exit;
    end;

    if ParamStr(2) = 'get' then
    begin
      try
        WriteLn(Controller.GetOption(ParamStr(3)));
      except
        on E: exception do
        begin
          WriteLn(Format('ERROR: %s', [E.Message]));
          Terminate(1);
          Exit;
        end;
      end;
    end
    else if ParamStr(2) = 'set' then
    begin
      if ParamCount < 4 then
      begin
        WriteUsageString([ParamStr(2), '<name>', '<value>']);
        Terminate(1);
        Exit;
      end;

      try
        Controller.SetOption(ParamStr(3), ParamStr(4));
      except
        on E: exception do
        begin
          WriteLn(Format('ERROR: %s', [E.Message]));
          Terminate(1);
          Exit;
        end;
      end;
    end
    else
    begin
      WriteUsageString(['<get|set> <name>']);
      Terminate(1);
      Exit;
    end;
  end
  else if Command = COMMAND_RESTART then
  begin
    WriteLn('Restarting the Docker service');

    if not Controller.Restart then
    begin
      WriteLn(Format('ERROR: %s', [Controller.GetErrorMessage]));
      Terminate(1);
      Exit;
    end;
  end
  else if Command = COMMAND_START then
  begin
    WriteLn('Starting the Docker service');

    if not Controller.Start then
    begin
      WriteLn(Format('ERROR: %s', [Controller.GetErrorMessage]));
      Terminate(1);
      Exit;
    end;
  end
  else if Command = COMMAND_STOP then
  begin
    WriteLn('Stopping the Docker service');

    if not Controller.Stop then
    begin
      WriteLn(Format('ERROR: %s', [Controller.GetErrorMessage]));
      Terminate(1);
      Exit;
    end;
  end
  else if (Command = COMMAND_VERSION) or
          (Command = OPTION_VERSION_LONG) or
          (Command = OPTION_VERSION_SHORT) then
  begin
    WriteVersionString;
  end
  else
  begin
    WriteLn(Format('ERROR: Unknown command ''%s''', [Command]));
    WriteUsageString([]);
    Terminate(1);
    Exit;
  end;

  // Always terminate and indicate success at the end of this method as we will
  // always call Terminate with exit code 1, if something goes wrong before this
  // statement is reached.
  Terminate;
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
    Write(Format('Usage: %s %s', [
      Command,
      ParamStr(1)
    ]));

    for Index := 0 to High(Args) do
    begin
      Write(' ' + Args[Index]);
    end;

    WriteLn;
  end
  else
  begin
    WriteLn(Format('Usage: %s <%s|%s|%s|%s|%s>', [
      Command,
      COMMAND_CONFIG,
      COMMAND_START,
      COMMAND_STOP,
      COMMAND_RESTART,
      COMMAND_VERSION
    ]));
  end;
end;

procedure TDockerControl.WriteVersionString;
var
  FileVerInfo: TFileVersionInfo;
begin
  FileVerInfo:=TFileVersionInfo.Create(nil);

  try
    // Read the version information from the binary instead of using hardcoded
    // values such as constants.
    FileVerInfo.ReadFileInfo;

    // Write the version information string to the standard output stream.
    WriteLn(Format('%s version %s', [
      FileVerInfo.VersionStrings.Values['ProductName'],
      Copy(
        FileVerInfo.VersionStrings.Values['FileVersion'],
        1,
        LastDelimiter('.', FileVerInfo.VersionStrings.Values['FileVersion']) - 1
      )
    ]));
  finally
    FileVerInfo.Free;
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

