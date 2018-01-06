unit WindowsShares;

{$MODE DELPHI}

interface

uses
  Process,
  SysUtils;

type
  { TWindowsCredentials }
  TWindowsCredentials = record
    Computer: String;
    Username: String;
    Password: String;
  end;

  { TWindowsDriveLetters }
  TWindowsDriveLetters = Array of Char;

  { TWindowsShares }
  TWindowsShares = class
  private const
    NET_COMMAND = 'net';
  public
    class procedure ShareDrive(
      const DriveLetter: Char;
      const ShareCredentials: TWindowsCredentials
    ); static;
    class procedure UnshareDrive(const DriveLetter: Char); static;
  end;

implementation

class procedure TWindowsShares.ShareDrive(
  const DriveLetter: Char;
  const ShareCredentials: TWindowsCredentials
);
const
  SHARE_MAX_USERS = 20;
var
  Process: TProcess;
begin
  try
    Process := TProcess.Create(nil);
    Process.Executable := NET_COMMAND;

    Process.Parameters.Append('share');
    Process.Parameters.Append(DriveLetter + '=' + DriveLetter + ':\');
    Process.Parameters.Append('/CACHE:None');
    Process.Parameters.Append(Format('/GRANT:%s\%s,%s', [
      ShareCredentials.Computer,
      ShareCredentials.Username,
      'Full'
    ]));
    Process.Parameters.Append(Format('/USERS:%d', [SHARE_MAX_USERS]));

    Process.Options := [poWaitOnExit, poUsePipes];
    Process.Execute;

    if Process.ExitCode <> 0 then
      raise Exception.Create('Failed to share drive ''' + DriveLetter + '''');
  finally
    FreeAndNil(Process);
  end;
end;

class procedure TWindowsShares.UnshareDrive(const DriveLetter: Char);
var
  Process: TProcess;
begin
  try
    Process := TProcess.Create(nil);
    Process.Executable := NET_COMMAND;

    Process.Parameters.Append('share');
    Process.Parameters.Append(DriveLetter);
    Process.Parameters.Append('/DELETE');

    Process.Options := [poWaitOnExit, poUsePipes];
    Process.Execute;

    if not Process.ExitCode in [0, 2] then
      raise Exception.Create('Failed to unshare drive ''' + DriveLetter + '''');
  finally
    FreeAndNil(Process);
  end;
end;

end.

