unit DockerConfiguration;

{$MODE DELPHI}

interface

uses
  FpJson,
  JsonConf,
  SysUtils;

type
  { TDockerConfiguration }
  TDockerConfiguration = class
  private const
    JSON_PATH_AUTOSTART = '/StartAtLogin';
    JSON_PATH_AUTOUPDATE = '/AutoUpdateEnabled';
    JSON_PATH_DNS = '/NameServer';
    JSON_PATH_EXCLUDED_PROXY_HOSTNAMES = '/ProxyExclude';
    JSON_PATH_EXPOSE = '/ExposeTcp';
    JSON_PATH_FORWARD_DNS = '/UseDnsForwarder';
    JSON_PATH_INSECURE_PROXY = '/ProxyHttp';
    JSON_PATH_MEMORY = '/VmMemory';
    JSON_PATH_PROCESSORS = '/VmCpus';
    JSON_PATH_SECURE_PROXY = '/ProxyHttps';
    JSON_PATH_SUBNET_ADDRESS = '/SubnetAddress';
    JSON_PATH_SUBNET_MASK_SIZE = '/SubnetMaskSize';
    JSON_PATH_TRACKING = '/IsTracking';
    JSON_PATH_USE_PROXY = '/UseHttpProxy';
  protected
    FConfig: TJSONConfig;

    function GetAutoStart: Boolean;
    function GetAutoUpdate: Boolean;
    function GetDns: String;
    function GetExcludedProxyHostnames: String;
    function GetExpose: Boolean;
    function GetForwardDns: Boolean;
    function GetInsecureProxy: String;
    function GetMemory: Integer;
    function GetProcessors: Integer;
    function GetSecureProxy: String;
    function GetSubnetAddress: String;
    function GetSubnetMaskSize: Byte;
    function GetTracking: Boolean;
    function GetUseProxy: Boolean;

    procedure SetAutoStart(const Value: Boolean);
    procedure SetAutoUpdate(const Value: Boolean);
    procedure SetDns(const Value: String);
    procedure SetExcludedProxyHostnames(const Value: String);
    procedure SetExpose(const Value: Boolean);
    procedure SetForwardDns(const Value: Boolean);
    procedure SetInsecureProxy(const Value: String);
    procedure SetMemory(const Value: Integer);
    procedure SetProcessors(const Value: Integer);
    procedure SetSecureProxy(const Value: String);
    procedure SetSubnetAddress(const Value: String);
    procedure SetSubnetMaskSize(const Value: Byte);
    procedure SetTracking(const Value: Boolean);
    procedure SetUseProxy(const Value: Boolean);
  public
    constructor Create(const FileName: String);
    destructor Destroy; override;

    property AutoStart: Boolean read GetAutoStart write SetAutoStart;
    property AutoUpdate: Boolean read GetAutoUpdate write SetAutoUpdate;
    property Dns: String read GetDns write SetDns;
    property ExcludedProxyHostnames: String read GetExcludedProxyHostnames
      write SetExcludedProxyHostnames;
    property Expose: Boolean read GetExpose write SetExpose;
    property ForwardDns: Boolean read GetForwardDns write SetForwardDns;
    property InsecureProxy: String read GetInsecureProxy write SetInsecureProxy;
    property Memory: Integer read GetMemory write SetMemory;
    property Processors: Integer read GetProcessors write SetProcessors;
    property SecureProxy: String read GetSecureProxy write SetSecureProxy;
    property SubnetAddress: String read GetSubnetAddress write SetSubnetAddress;
    property SubnetMaskSize: Byte read GetSubnetMaskSize
      write SetSubnetMaskSize;
    property Tracking: Boolean read GetTracking write SetTracking;
    property UseProxy: Boolean read GetUseProxy write SetUseProxy;
  end;

implementation

constructor TDockerConfiguration.Create(const FileName: String);
begin
  inherited Create;

  // Create a new TJSONConfig instance and load the Docker configuration.
  FConfig := TJSONConfig.Create(nil);

  try
    FConfig.FileName := FileName;
    FConfig.Formatted := True;
    FConfig.FormatOptions := [
      foSingleLineArray,
      foSingleLineObject,
      foSkipWhiteSpace
    ];
  except
    on E: exception do
    begin
      FreeAndNil(FConfig);
      raise E;
    end;
  end;
end;

destructor TDockerConfiguration.Destroy;
begin
  FreeAndNil(FConfig);

  inherited;
end;

function TDockerConfiguration.GetAutoStart: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_AUTOSTART, True);
end;

function TDockerConfiguration.GetAutoUpdate: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_AUTOUPDATE, True);
end;

function TDockerConfiguration.GetDns: String;
begin
  {$WARNINGS OFF}
  Result := FConfig.GetValue(JSON_PATH_DNS, '8.8.8.8');
  {$WARNINGS ON}
end;

function TDockerConfiguration.GetExcludedProxyHostnames: String;
begin
  {$WARNINGS OFF}
  Result := FConfig.GetValue(JSON_PATH_EXCLUDED_PROXY_HOSTNAMES, '');
  {$WARNINGS ON}
end;

function TDockerConfiguration.GetExpose: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_EXPOSE, False);
end;

function TDockerConfiguration.GetForwardDns: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_FORWARD_DNS, True);
end;

function TDockerConfiguration.GetInsecureProxy: String;
begin
  {$WARNINGS OFF}
  Result := FConfig.GetValue(JSON_PATH_INSECURE_PROXY, '');
  {$WARNINGS ON}
end;

function TDockerConfiguration.GetMemory: Integer;
begin
  Result := FConfig.GetValue(JSON_PATH_MEMORY, 2048);
end;

function TDockerConfiguration.GetProcessors: Integer;
begin
  Result := FConfig.GetValue(JSON_PATH_PROCESSORS, 2);
end;

function TDockerConfiguration.GetSecureProxy: String;
begin
  {$WARNINGS OFF}
  Result := FConfig.GetValue(JSON_PATH_SECURE_PROXY, '');
  {$WARNINGS ON}
end;

function TDockerConfiguration.GetSubnetAddress: String;
begin
  {$WARNINGS OFF}
  Result := FConfig.GetValue(JSON_PATH_SUBNET_ADDRESS, '10.0.75.0');
  {$WARNINGS ON}
end;

function TDockerConfiguration.GetSubnetMaskSize: Byte;
begin
  Result := FConfig.GetValue(JSON_PATH_SUBNET_MASK_SIZE, 24);
end;

function TDockerConfiguration.GetTracking: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_TRACKING, True);
end;

function TDockerConfiguration.GetUseProxy: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_USE_PROXY, False);
end;

procedure TDockerConfiguration.SetAutoStart(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_AUTOSTART, Value);
end;

procedure TDockerConfiguration.SetAutoUpdate(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_AUTOUPDATE, Value);
end;

procedure TDockerConfiguration.SetDns(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_DNS, Value);
  {$WARNINGS ON}
end;

procedure TDockerConfiguration.SetExcludedProxyHostnames(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_EXCLUDED_PROXY_HOSTNAMES, Value);
  {$WARNINGS ON}
end;

procedure TDockerConfiguration.SetExpose(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_EXPOSE, Value);
end;

procedure TDockerConfiguration.SetForwardDns(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_FORWARD_DNS, Value);
end;

procedure TDockerConfiguration.SetInsecureProxy(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_INSECURE_PROXY, Value);
  {$WARNINGS ON}
end;

procedure TDockerConfiguration.SetMemory(const Value: Integer);
begin
  FConfig.SetValue(JSON_PATH_MEMORY, Value);
end;

procedure TDockerConfiguration.SetProcessors(const Value: Integer);
begin
  FConfig.SetValue(JSON_PATH_PROCESSORS, Value);
end;

procedure TDockerConfiguration.SetSecureProxy(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_SECURE_PROXY, Value);
  {$WARNINGS ON}
end;

procedure TDockerConfiguration.SetSubnetAddress(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_SUBNET_ADDRESS, Value);
  {$WARNINGS ON}
end;

procedure TDockerConfiguration.SetSubnetMaskSize(const Value: Byte);
begin
  FConfig.SetValue(JSON_PATH_SUBNET_MASK_SIZE, Value);
end;

procedure TDockerConfiguration.SetTracking(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_TRACKING, Value);
end;

procedure TDockerConfiguration.SetUseProxy(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_USE_PROXY, Value);
end;

end.

