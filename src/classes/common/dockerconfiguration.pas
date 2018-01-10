unit DockerConfiguration;

{$MODE DELPHI}

interface

uses
  Classes,
  ConfigurationInterface,
  FpJson,
  JsonConf,
  SysUtils;

type
  { TDockerConfiguration }
  TDockerConfiguration = class(TInterfacedObject, IConfigurationInterface)
  protected const
    OPTION_ADVANCED_DISK_IMAGE = 'advanced.disk_image';
    OPTION_ADVANCED_MEMORY = 'advanced.memory';
    OPTION_ADVANCED_PROCESSORS = 'advanced.processors';
    OPTION_GENERAL_AUTOSTART = 'general.autostart';
    OPTION_GENERAL_AUTOUPDATE = 'general.autoupdate';
    OPTION_GENERAL_TRACKING = 'general.tracking';
    OPTION_NETWORK_SUBNET_ADDRESS = 'network.subnet_address';
    OPTION_PROXIES_EXCLUDED_HOSTNAMES = 'proxies.excluded_hostnames';
    OPTION_PROXIES_INSECURE_SERVER = 'proxies.insecure_server';
    OPTION_PROXIES_SECURE_SERVER = 'proxies.secure_server';
    OPTION_PROXIES_USE_PROXY = 'proxies.use_proxy';
    OPTION_SHARING_DIRECTORIES = 'sharing.directories';
  protected
    FConfig: TJSONConfig;

    function GetAutoStart: Boolean; virtual; abstract;
    function GetAutoUpdate: Boolean; virtual; abstract;
    function GetDiskImage: String; virtual; abstract;
    function GetExcludedProxyHostnames: String; virtual; abstract;
    function GetInsecureProxyServer: String; virtual; abstract;
    function GetMemory: Integer; virtual; abstract;
    function GetProcessors: Integer; virtual; abstract;
    function GetSecureProxyServer: String; virtual; abstract;
    function GetSubnetAddress: String; virtual; abstract;
    function GetTracking: Boolean; virtual; abstract;
    function GetUseProxy: Boolean; virtual; abstract;

    procedure SetAutoStart(const Value: Boolean); virtual; abstract;
    procedure SetAutoUpdate(const Value: Boolean); virtual; abstract;
    procedure SetDiskImage(const Value: String); virtual; abstract;
    procedure SetExcludedProxyHostnames(const Value: String); virtual; abstract;
    procedure SetInsecureProxyServer(const Value: String); virtual; abstract;
    procedure SetMemory(const Value: Integer); virtual; abstract;
    procedure SetProcessors(const Value: Integer); virtual; abstract;
    procedure SetSecureProxyServer(const Value: String); virtual; abstract;
    procedure SetSubnetAddress(const Value: String); virtual; abstract;
    procedure SetTracking(const Value: Boolean); virtual; abstract;
    procedure SetUseProxy(const Value: Boolean); virtual; abstract;
  public
    constructor Create(const FileName: String);
    destructor Destroy; override;

    function GetOption(const Name: string): String; virtual;
    procedure SetOption(const Name, Value: String); virtual;

    property AutoStart: Boolean read GetAutoStart write SetAutoStart;
    property AutoUpdate: Boolean read GetAutoUpdate write SetAutoUpdate;
    property DiskImage: String read GetDiskImage write SetDiskImage;
    property ExcludedProxyHostnames: String read GetExcludedProxyHostnames
      write SetExcludedProxyHostnames;
    property InsecureProxyServer: String read GetInsecureProxyServer
      write SetInsecureProxyServer;
    property Memory: Integer read GetMemory write SetMemory;
    property Processors: Integer read GetProcessors write SetProcessors;
    property SecureProxyServer: String read GetSecureProxyServer
      write SetSecureProxyServer;
    property SubnetAddress: String read GetSubnetAddress write SetSubnetAddress;
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
      FConfig.Free;
      raise E;
    end;
  end;
end;

destructor TDockerConfiguration.Destroy;
begin
  FreeAndNil(FConfig);

  inherited;
end;

function TDockerConfiguration.GetOption(const Name: string): String;
begin
  Result := '';

  // Advanced
  if Name = OPTION_ADVANCED_DISK_IMAGE then
    Result := DiskImage
  else if Name = OPTION_ADVANCED_MEMORY then
    Result := IntToStr(Memory)
  else if Name = OPTION_ADVANCED_PROCESSORS then
    Result := IntToStr(Processors)

  // General
  else if Name = OPTION_GENERAL_AUTOSTART then
    Result := LowerCase(BoolToStr(AutoStart, True))
  else if Name = OPTION_GENERAL_AUTOUPDATE then
    Result := LowerCase(BoolToStr(AutoUpdate, True))
  else if Name = OPTION_GENERAL_TRACKING then
    Result := LowerCase(BoolToStr(Tracking, True))

  // Network
  else if Name = OPTION_NETWORK_SUBNET_ADDRESS then
    Result := SubnetAddress

  // Proxies
  else if Name = OPTION_PROXIES_EXCLUDED_HOSTNAMES then
    Result := ExcludedProxyHostnames
  else if Name = OPTION_PROXIES_INSECURE_SERVER then
    Result := InsecureProxyServer
  else if Name = OPTION_PROXIES_SECURE_SERVER then
    Result := SecureProxyServer
  else if Name = OPTION_PROXIES_USE_PROXY then
    Result := LowerCase(BoolToStr(UseProxy, True))

  // Raise an exception in case the name is invalid.
  else
    raise Exception.Create(Format('Invalid option ''%s''', [Name]));
end;

procedure TDockerConfiguration.SetOption(const Name, Value: String);
var
  I: Cardinal;
begin
  // Advanced
  if Name = OPTION_ADVANCED_DISK_IMAGE then
    DiskImage := Value
  else if Name = OPTION_ADVANCED_MEMORY then
  begin
    I := StrToInt(Value);

    if (I mod 256 <> 0) then
      raise Exception.Create(
        'The virtual machine''s memory allocation must be a multiple of 256 MB')
    else if (I < 1024) then
      raise Exception.Create(
        'The virtual machine requires at least 1024 MB of memory');

    Memory := I;
  end
  else if Name = OPTION_ADVANCED_PROCESSORS then
  begin
    I := StrToInt(Value);

    if (I < 1) then
      raise Exception.Create(
        'The virtual machine requires at least one processors')
    else if (I > GetCPUCount) then
      raise Exception.Create(Format('The system only has %d processor(s)',
        [GetCPUCount]));

    Processors := I;
  end

  // General
  else if Name = OPTION_GENERAL_AUTOSTART then
    AutoStart := StrToBool(Value)
  else if Name = OPTION_GENERAL_AUTOUPDATE then
    AutoUpdate := StrToBool(Value)
  else if Name = OPTION_GENERAL_TRACKING then
    Tracking := StrToBool(Value)

  // Network
  else if Name = OPTION_NETWORK_SUBNET_ADDRESS then
    SubnetAddress := Value

  // Proxies
  else if Name = OPTION_PROXIES_EXCLUDED_HOSTNAMES then
    ExcludedProxyHostnames := Value
  else if Name = OPTION_PROXIES_INSECURE_SERVER then
    InsecureProxyServer := Value
  else if Name = OPTION_PROXIES_SECURE_SERVER then
    SecureProxyServer := Value
  else if Name = OPTION_PROXIES_USE_PROXY then
    UseProxy := StrToBool(Value)

  // Raise an exception in case the name is invalid.
  else
    raise Exception.Create(Format('Invalid option ''%s''', [Name]));
end;

end.

