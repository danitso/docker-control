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
    JSON_PATH_AUTOSTART = '/autoStart';
    JSON_PATH_AUTOUPDATE = '/checkForUpdates';
    JSON_PATH_DISK_IMAGE = '/diskPath';
    JSON_PATH_EXCLUDED_PROXY_HOSTNAMES = '/overrideProxyExclude';
    JSON_PATH_INSECURE_PROXY = '/overrideProxyHttp';
    JSON_PATH_MEMORY = '/memoryMiB';
    JSON_PATH_PROCESSORS = '/cpus';
    JSON_PATH_SECURE_PROXY = '/overrideProxyHttps';
    JSON_PATH_SHARED_DIRECTORIES = '/filesharingDirectories';
    JSON_PATH_SUBNET_ADDRESS = '/hyperkitIpRange';
    JSON_PATH_TRACKING = '/analyticsEnabled';
    JSON_PATH_USE_PROXY = '/proxyHttpMode';
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

  // File Sharing
  if Name = OPTION_SHARING_DIRECTORIES then
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
  Directories: TStringList;
  I: Integer;
begin
  SetLength(Result, 0);
  Directories := TStringList.Create;

  try
    FConfig.GetValue(JSON_PATH_SHARED_DIRECTORIES, Directories, '');
    SetLength(Result, Directories.Count);

    for I := 0 to Directories.Count - 1 do
      Result[I] := Directories[I];
  finally
    Directories.Free;
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
  // File Sharing
  if Name = OPTION_SHARING_DIRECTORIES then
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
  Directories: TStringList;
  I: Integer;
begin
  Directories := TStringList.Create;

  for I := 0 to High(Value) do
    Directories.Add(Value[I]);

  try
    FConfig.SetValue(JSON_PATH_SHARED_DIRECTORIES, Directories);
  finally
    Directories.Free;
  end;
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

