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
    JSON_PATH_VHD_PATH = '/MobyVhdPathOverride';
    OPTION_ADVANCED_CPUS = 'advanced.cpus';
    OPTION_ADVANCED_MEMORY = 'advanced.memory';
    OPTION_ADVANCED_VHD_PATH = 'advanced.vhd_path';
    OPTION_GENERAL_AUTOSTART = 'general.autostart';
    OPTION_GENERAL_AUTOUPDATE = 'general.autoupdate';
    OPTION_GENERAL_EXPOSE_DAEMON = 'general.expose_daemon';
    OPTION_GENERAL_TRACKING = 'general.tracking';
    OPTION_NETWORK_DNS_FORWARDING = 'network.dns_forwarding';
    OPTION_NETWORK_DNS_SERVER = 'network.dns_server';
    OPTION_NETWORK_SUBNET_ADDRESS = 'network.subnet_address';
    OPTION_NETWORK_SUBNET_MASK_SIZE = 'network.subnet_mask_size';
    OPTION_PROXIES_ENABLED = 'proxies.enabled';
    OPTION_PROXIES_EXCLUDED_HOSTNAMES = 'proxies.excluded_hostnames';
    OPTION_PROXIES_SECURE_WEB_SERVER = 'proxies.secure_web_server';
    OPTION_PROXIES_WEB_SERVER = 'proxies.web_server';
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
    function GetVhdPath: String;

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
    procedure SetVhdPath(const Value: String);
  public
    constructor Create(const FileName: String);
    destructor Destroy; override;

    function GetOption(const Name: string): String;
    procedure SetOption(const Name,Value: String);

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
    property VhdPath: String read GetVhdPath write SetVhdPath;
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

function TDockerConfiguration.GetOption(const Name: string): String;
begin
  Result := '';

  // Advanced
  if Name = OPTION_ADVANCED_CPUS then
    Result := IntToStr(Processors)
  else if Name = OPTION_ADVANCED_MEMORY then
    Result := IntToStr(Memory)
  else if Name = OPTION_ADVANCED_VHD_PATH then
    Result := VhdPath

  // General
  else if Name = OPTION_GENERAL_AUTOSTART then
    Result := LowerCase(BoolToStr(AutoStart, True))
  else if Name = OPTION_GENERAL_AUTOUPDATE then
    Result := LowerCase(BoolToStr(AutoUpdate, True))
  else if Name = OPTION_GENERAL_EXPOSE_DAEMON then
    Result := LowerCase(BoolToStr(Expose, True))
  else if Name = OPTION_GENERAL_TRACKING then
    Result := LowerCase(BoolToStr(Tracking, True))

  // Network
  else if Name = OPTION_NETWORK_DNS_FORWARDING then
    Result := LowerCase(BoolToStr(ForwardDns, True))
  else if Name = OPTION_NETWORK_DNS_SERVER then
    Result := Dns
  else if Name = OPTION_NETWORK_SUBNET_ADDRESS then
    Result := SubnetAddress
  else if Name = OPTION_NETWORK_SUBNET_MASK_SIZE then
    Result := IntToStr(SubnetMaskSize)

  // Proxies
  else if Name = OPTION_PROXIES_ENABLED then
    Result := LowerCase(BoolToStr(UseProxy, True))
  else if Name = OPTION_PROXIES_EXCLUDED_HOSTNAMES then
    Result := ExcludedProxyHostnames
  else if Name = OPTION_PROXIES_SECURE_WEB_SERVER then
    Result := SecureProxy
  else if Name = OPTION_PROXIES_WEB_SERVER then
    Result := InsecureProxy

  // Raise an exception in case the option name is invalid.
  else
    raise Exception.Create(Format('Invalid option ''%s''', [Name]));
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

function TDockerConfiguration.GetVhdPath: String;
begin
  {$WARNINGS OFF}
  Result := FConfig.GetValue(JSON_PATH_VHD_PATH, '');
  {$WARNINGS ON}
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

procedure TDockerConfiguration.SetOption(const Name,Value: String);
var
  I: Integer;
begin
  // Advanced
  if Name = OPTION_ADVANCED_CPUS then
  begin
    I := StrToInt(Value);

    if (I < 1) then
      raise Exception.Create('The virtual machine requires at least one CPU')
    else if (I > GetCPUCount) then
      raise Exception.Create(Format('The system only has %d CPU(s)',
        [GetCPUCount]));

    Processors := I;
  end
  else if Name = OPTION_ADVANCED_MEMORY then
  begin
    I := StrToInt(Value);

    if (I mod 256 <> 0) then
      raise Exception.Create(
        'The virtual machine''s memory allocation must be a multiple of 256')
    else if (I < 1024) then
      raise Exception.Create(
        'The virtual machine requires at least 1024 MB of memory');

    Memory := I;
  end
  else if Name = OPTION_ADVANCED_VHD_PATH then
  begin
    VhdPath := Value;
  end

  // General
  else if Name = OPTION_GENERAL_AUTOSTART then
    AutoStart := StrToBool(Value)
  else if Name = OPTION_GENERAL_AUTOUPDATE then
    AutoUpdate := StrToBool(Value)
  else if Name = OPTION_GENERAL_EXPOSE_DAEMON then
    Expose := StrToBool(Value)
  else if Name = OPTION_GENERAL_TRACKING then
    Tracking := StrToBool(Value)

  // Network
  else if Name = OPTION_NETWORK_DNS_FORWARDING then
    ForwardDns := StrToBool(Value)
  else if Name = OPTION_NETWORK_DNS_SERVER then
    Dns := Value
  else if Name = OPTION_NETWORK_SUBNET_ADDRESS then
    SubnetAddress := Value
  else if Name = OPTION_NETWORK_SUBNET_MASK_SIZE then
  begin
    I := StrToInt(Value);

    if (I < 0) or (I > 32) then
      raise Exception.Create('Invalid subnet mask size');

    SubnetMaskSize := I;
  end

  // Proxies
  else if Name = OPTION_PROXIES_ENABLED then
    UseProxy := StrToBool(Value)
  else if Name = OPTION_PROXIES_EXCLUDED_HOSTNAMES then
    ExcludedProxyHostnames := Value
  else if Name = OPTION_PROXIES_SECURE_WEB_SERVER then
    SecureProxy := Value
  else if Name = OPTION_PROXIES_WEB_SERVER then
    InsecureProxy := Value

  // Raise an exception in case the option name is invalid.
  else
    raise Exception.Create(Format('Invalid option ''%s''', [Name]));
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

procedure TDockerConfiguration.SetVhdPath(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_VHD_PATH, Value);
  {$WARNINGS ON}
end;

end.

