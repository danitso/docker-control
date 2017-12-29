program dockerctl;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

uses
  {$IFDEF UNIX}
    {$IFDEF UseCThreads}
    cthreads,
    {$ENDIF}
  {$ENDIF}
  ControllerInterface,
  {$IFDEF MSWINDOWS}
  Tray,
  TrayButton,
  WindowsController,
  {$ENDIF}
  Classes,
  CustApp,
  SysUtils;

const
  COMMAND_RESTART = 'restart';
  COMMAND_START = 'start';
  COMMAND_STOP = 'stop';

type
  { TDockerControl }
  TDockerControl = class(TCustomApplication)
  protected
    procedure DoRun; override;
    procedure WriteUsageString;
  public

  end;

{ TDockerControl }

procedure TDockerControl.DoRun;
var
  Command: string;
  Controller: IControllerInterface;
begin
  // Print the usage string, if more or less than one command line argument has
  // been specified.
  if ParamCount <> 1 then
  begin
    WriteUsageString;
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

  // Perform the specified command, if possible.
  Command := ParamStr(1);

  if Command = COMMAND_RESTART then
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
  else
  begin
    WriteLn(Format('ERROR: Unknown command ''%s''', [Command]));
    WriteUsageString;
    Terminate(1);
    Exit;
  end;

  // Always terminate and indicate success at the end of this method as we will
  // always call Terminate with exit code 1, if something goes wrong before this
  // statement is reached.
  Terminate;
end;

procedure TDockerControl.WriteUsageString;
begin
  WriteLn(Format('Usage: %s <%s|%s|%s>', [
    ExtractFileName(ParamStr(0)),
    COMMAND_START,
    COMMAND_STOP,
    COMMAND_RESTART
  ]));
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

