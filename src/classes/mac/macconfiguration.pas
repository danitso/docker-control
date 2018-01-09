unit MacConfiguration;

{$MODE DELPHI}

interface

uses
  Classes,
  DockerConfiguration,
  Process,
  StringFunctions,
  SysUtils;

type
  { TMacConfiguration }
  TMacConfiguration = class(TDockerConfiguration)
  private const
    DOCKER_DATABASE_MOUNTS = 'com.docker.driver.amd64-linux/mounts';
    JSON_PATH_AUTOSTART = '/autoStart';
    JSON_PATH_AUTOUPDATE = '/checkForUpdates';
    JSON_PATH_DISK_IMAGE = '/diskPath';
    JSON_PATH_EXCLUDED_PROXY_HOSTNAMES = '/overrideProxyExclude';
    JSON_PATH_INSECURE_PROXY = '/overrideProxyHttp';
    JSON_PATH_MEMORY = '/memoryMiB';
    JSON_PATH_PROCESSORS = '/cpus';
    JSON_PATH_SECURE_PROXY = '/overrideProxyHttps';
    JSON_PATH_SUBNET_ADDRESS = '/hyperkitIpRange';
    JSON_PATH_TRACKING = '/analyticsEnabled';
    JSON_PATH_USE_PROXY = '/proxyHttpMode';
    OPTION_SHARED_DIRECTORIES = 'file_sharing.directories';
  protected
    function GetAutoStart: Boolean; override;
    function GetAutoUpdate: Boolean; override;
    function GetDiskImage: String; override;
    function GetDockerDatabasePath: String;
    function GetExcludedProxyHostnames: String; override;
    function GetInsecureProxyServer: String; override;
    function GetMemory: Integer; override;
    function GetProcessors: Integer; override;
    function GetSecureProxyServer: String; override;
    function GetSharedDirectories: TStringArray;
    function GetSubnetAddress: String; override;
    function GetTracking: Boolean; override;
    function GetUseProxy: Boolean; override;

    procedure SetAutoStart(const Value: Boolean); override;
    procedure SetAutoUpdate(const Value: Boolean); override;
    procedure SetDiskImage(const Value: String); override;
    procedure SetExcludedProxyHostnames(const Value: String); override;
    procedure SetInsecureProxyServer(const Value: String); override;
    procedure SetMemory(const Value: Integer); override;
    procedure SetProcessors(const Value: Integer); override;
    procedure SetSecureProxyServer(const Value: String); override;
    procedure SetSharedDirectories(const Value: TStringArray);
    procedure SetSubnetAddress(const Value: String); override;
    procedure SetTracking(const Value: Boolean); override;
    procedure SetUseProxy(const Value: Boolean); override;
  public
    function GetOption(const Name: string): String; override;
    procedure SetOption(const Name, Value: String); override;

    property SharedDirectories: TStringArray read GetSharedDirectories
      write SetSharedDirectories;
  end;

implementation

function TMacConfiguration.GetAutoStart: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_AUTOSTART, True);
end;

function TMacConfiguration.GetAutoUpdate: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_AUTOUPDATE, True);
end;

function TMacConfiguration.GetDiskImage: String;
const
  DEFAULT_VALUE = '';
begin
  {$WARNINGS OFF}
  try
    Result := FConfig.GetValue(JSON_PATH_DISK_IMAGE, DEFAULT_VALUE);
  except
    on exception do
      Result := DEFAULT_VALUE;
  end;
  {$WARNINGS ON}
end;

function TMacConfiguration.GetDockerDatabasePath: String;
begin
  Result := GetUserDir + '/Library/Containers/com.docker.docker/Data/database';
end;

function TMacConfiguration.GetExcludedProxyHostnames: String;
const
  DEFAULT_VALUE = '';
begin
  {$WARNINGS OFF}
  try
    Result := FConfig.GetValue(JSON_PATH_EXCLUDED_PROXY_HOSTNAMES,
      DEFAULT_VALUE);
  except
    on exception do
      Result := DEFAULT_VALUE;
  end;
  {$WARNINGS ON}
end;

function TMacConfiguration.GetInsecureProxyServer: String;
const
  DEFAULT_VALUE = '';
begin
  {$WARNINGS OFF}
  try
    Result := FConfig.GetValue(JSON_PATH_INSECURE_PROXY, DEFAULT_VALUE);
  except
    on exception do
      Result := DEFAULT_VALUE;
  end;
  {$WARNINGS ON}
end;

function TMacConfiguration.GetMemory: Integer;
begin
  Result := FConfig.GetValue(JSON_PATH_MEMORY, 2048);
end;

function TMacConfiguration.GetOption(const Name: string): String;
var
  I: Integer;
  Values: TStringArray;
begin
  Result := '';

  // General
  if Name = OPTION_SHARED_DIRECTORIES then
  begin
    Values := SharedDirectories;

    for I := 0 to High(Values) do
    begin
      if I > 0 then
        Result := Result + ',' + Values[I]
      else
        Result := Values[I];
    end;
  end

  // Allow the base class to retrieve common options.
  else
    Result := inherited;
end;

function TMacConfiguration.GetProcessors: Integer;
begin
  Result := FConfig.GetValue(JSON_PATH_PROCESSORS, 2);
end;

function TMacConfiguration.GetSecureProxyServer: String;
const
  DEFAULT_VALUE = '';
begin
  {$WARNINGS OFF}
  try
    Result := FConfig.GetValue(JSON_PATH_SECURE_PROXY, DEFAULT_VALUE);
  except
    on exception do
      Result := DEFAULT_VALUE;
  end;
  {$WARNINGS ON}
end;

function TMacConfiguration.GetSharedDirectories: TStringArray;
var
  I: Integer;
  Strings: TStringList;
  Values: TStringArray;
begin
  SetLength(Result, 0);
  Strings := TStringList.Create;

  try
    Strings.LoadFromFile(GetDockerDatabasePath + '/' + DOCKER_DATABASE_MOUNTS);
    SetLength(Result, Strings.Count);

    for I := 0 to Strings.Count - 1 do
    begin
      Values := TStringFunctions.Explode(':', Strings[I]);
      Result[I] := Values[0];
    end;
  finally
    Strings.Free;
  end;
end;

function TMacConfiguration.GetSubnetAddress: String;
const
  DEFAULT_VALUE = '';
begin
  {$WARNINGS OFF}
  try
    Result := FConfig.GetValue(JSON_PATH_SUBNET_ADDRESS, DEFAULT_VALUE);
  except
    on exception do
      Result := DEFAULT_VALUE;
  end;
  {$WARNINGS ON}
end;

function TMacConfiguration.GetTracking: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_TRACKING, True);
end;

function TMacConfiguration.GetUseProxy: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_USE_PROXY, 'system') = 'manual';
end;

procedure TMacConfiguration.SetAutoStart(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_AUTOSTART, Value);
end;

procedure TMacConfiguration.SetAutoUpdate(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_AUTOUPDATE, Value);
end;

procedure TMacConfiguration.SetDiskImage(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_DISK_IMAGE, Value);
  {$WARNINGS ON}
end;

procedure TMacConfiguration.SetExcludedProxyHostnames(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_EXCLUDED_PROXY_HOSTNAMES, Value);
  {$WARNINGS ON}
end;

procedure TMacConfiguration.SetInsecureProxyServer(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_INSECURE_PROXY, Value);
  {$WARNINGS ON}
end;

procedure TMacConfiguration.SetMemory(const Value: Integer);
begin
  FConfig.SetValue(JSON_PATH_MEMORY, Value);
end;

procedure TMacConfiguration.SetOption(const Name, Value: String);
var
  I: Integer;
  Values: TStringArray;
begin
  // General
  if Name = OPTION_SHARED_DIRECTORIES then
  begin
    Values := TStringFunctions.Explode(',', Value);

    for I := 0 to High(Values) do
    begin
      if not DirectoryExists(Values[I]) then
        raise Exception.Create(Format('Invalid directory "%s"', [Values[I]]));
    end;

    SharedDirectories := Values;
  end

  // Allow the base class to set common options.
  else
    inherited;
end;

procedure TMacConfiguration.SetProcessors(const Value: Integer);
begin
  FConfig.SetValue(JSON_PATH_PROCESSORS, Value);
end;

procedure TMacConfiguration.SetSecureProxyServer(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_SECURE_PROXY, Value);
  {$WARNINGS ON}
end;

procedure TMacConfiguration.SetSharedDirectories(const Value: TStringArray);
var
  DatabasePath: String;
  F: TextFile;
  I: Integer;
  Options: TProcessOptions;
  Output: String;
  MountsPath: String;
begin
  DatabasePath := GetDockerDatabasePath;
  MountsPath := GetDockerDatabasePath + '/' + DOCKER_DATABASE_MOUNTS;
  Options := [poWaitOnExit, poUsePipes];

  // Reset the database just in case manual changes have not been committed.
  if not RunCommand('git', [
      '-C',
      DatabasePath,
      'reset',
      '--hard'
    ], Output, Options) then
    raise Exception.Create('Failed to reset git database');

  // Write the list of directories to the file.
  AssignFile(F, MountsPath);
  Rewrite(F);

  for I := 0 to High(Value) do
    WriteLn(F, Format('%s:%s', [Value[I], Value[I]]));

  CloseFile(F);

  // Commit the changes in order to apply them upon restart of the service.
  if not RunCommand('git', [
      '-C',
      DatabasePath,
      'add',
      DOCKER_DATABASE_MOUNTS
    ], Output, Options) then
    raise Exception.Create('Failed to add files for commit');

  if not RunCommand('git', [
      '-C',
      DatabasePath,
      'commit',
      '--author="datakit <datakit@mobyproject.org>"',
      '-m',
      'setshareddirectories'
    ], Output, Options) then
    raise Exception.Create('Failed to commit changes to git database');
end;

procedure TMacConfiguration.SetSubnetAddress(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_SUBNET_ADDRESS, Value);
  {$WARNINGS ON}
end;

procedure TMacConfiguration.SetTracking(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_TRACKING, Value);
end;

procedure TMacConfiguration.SetUseProxy(const Value: Boolean);
begin
  if Value then
    FConfig.SetValue(JSON_PATH_USE_PROXY, 'manual')
  else
    FConfig.SetValue(JSON_PATH_USE_PROXY, 'system');
end;

end.

