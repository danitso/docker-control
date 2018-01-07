unit MacConfiguration;

{$MODE DELPHI}

interface

uses
  Classes,
  DockerConfiguration,
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
    JSON_PATH_SUBNET_ADDRESS = '/hyperkitIpRange';
    JSON_PATH_TRACKING = '/analyticsEnabled';
    JSON_PATH_USE_PROXY = '/proxyHttpMode';
  protected
    function GetAutoStart: Boolean; override;
    function GetAutoUpdate: Boolean; override;
    function GetDiskImage: String; override;
    function GetExcludedProxyHostnames: String; override;
    function GetInsecureProxyServer: String; override;
    function GetMemory: Integer; override;
    function GetProcessors: Integer; override;
    function GetSecureProxyServer: String; override;
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
    procedure SetSubnetAddress(const Value: String); override;
    procedure SetTracking(const Value: Boolean); override;
    procedure SetUseProxy(const Value: Boolean); override;
  public
    function GetOption(const Name: string): String; override;
    procedure SetOption(const Name, Value: String); override;
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
begin
  Result := '';

  // General
  if False then
    Exit

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
begin
  // General
  if False then
    Exit

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

