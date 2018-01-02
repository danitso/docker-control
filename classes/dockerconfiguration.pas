unit DockerConfiguration;

{$MODE DELPHI}

interface

uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  Classes,
  FpJson,
  JsonConf,
  SysUtils;

type
  { TExplodeArray }
  TExplodeArray = array of String;

  { TSharedDrives }
  TSharedDrives = array of Char;

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
    JSON_PATH_SHARED_DRIVES = '/SharedDrives';
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
    OPTION_PROXIES_INSECURE_SERVER = 'proxies.insecure_server';
    OPTION_PROXIES_SECURE_SERVER = 'proxies.secure_server';
    OPTION_SHARED_DRIVES_CREDENTIALS = 'shared_drives.credentials';
    OPTION_SHARED_DRIVES_LETTERS = 'shared_drives.letters';
  protected
    FConfig: TJSONConfig;

    function Explode(const Delimiter: String; Value: String): TExplodeArray;

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
    function GetSharedDrives: TSharedDrives;
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
    procedure SetSharedDrives(const Value: TSharedDrives);
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
    property SharedDrives: TSharedDrives read GetSharedDrives
      write SetSharedDrives;
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

function TDockerConfiguration.Explode(
  const Delimiter: String;
  Value: String
): TExplodeArray;
var
  Index: Integer;
begin
  SetLength(Result, 0);
  Index := Pos(Delimiter, Value);

  while Index <> 0 do
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Copy(Value, 1, Index - 1);

    Value := Copy(Value, Index + Length(Delimiter), Length(Value));
    Index := Pos(Delimiter, Value);
  end;

  if Value <> '' then
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := Value;
  end;
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
const
  DEFAULT_VALUE = '8.8.8.8';
begin
  {$WARNINGS OFF}
  try
    Result := FConfig.GetValue(JSON_PATH_DNS, DEFAULT_VALUE);
  except
    on exception do
      Result := DEFAULT_VALUE;
  end;
  {$WARNINGS ON}
end;

function TDockerConfiguration.GetExcludedProxyHostnames: String;
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

function TDockerConfiguration.GetExpose: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_EXPOSE, False);
end;

function TDockerConfiguration.GetForwardDns: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_FORWARD_DNS, True);
end;

function TDockerConfiguration.GetInsecureProxy: String;
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

function TDockerConfiguration.GetMemory: Integer;
begin
  Result := FConfig.GetValue(JSON_PATH_MEMORY, 2048);
end;

function TDockerConfiguration.GetOption(const Name: string): String;
var
  I: Integer;
  SharedDrives: TSharedDrives;
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
  else if Name = OPTION_PROXIES_INSECURE_SERVER then
    Result := InsecureProxy
  else if Name = OPTION_PROXIES_SECURE_SERVER then
    Result := SecureProxy

  // Shared Drives
  else if Name = OPTION_SHARED_DRIVES_CREDENTIALS then
    raise ENotImplemented.Create('Configuration value not implemented')
  else if Name = OPTION_SHARED_DRIVES_LETTERS then
  begin
    Result := '';
    SharedDrives := GetSharedDrives;

    for I := 0 to High(SharedDrives) do
    begin
      if (I > 0) then
        Result := Result + ',' + SharedDrives[I]
      else
        Result := SharedDrives[I];
    end;
  end

  // Raise an exception in case the option name is invalid.
  else
    raise Exception.Create(Format('Invalid option ''%s''', [Name]));
end;

function TDockerConfiguration.GetProcessors: Integer;
begin
  Result := FConfig.GetValue(JSON_PATH_PROCESSORS, 2);
end;

function TDockerConfiguration.GetSecureProxy: String;
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

function TDockerConfiguration.GetSharedDrives: TSharedDrives;
var
  DriveKey: String;
  DriveLetters: TStringList;
  I: Integer;
begin
  SetLength(Result, 0);

  try
    DriveLetters := TStringList.Create;
    FConfig.EnumValues(JSON_PATH_SHARED_DRIVES, DriveLetters);

    for I := 0 to DriveLetters.Count - 1 do
    begin
      DriveKey := JSON_PATH_SHARED_DRIVES + '/' + DriveLetters[I];

      {$WARNINGS OFF}
      if FConfig.GetValue(DriveKey, False) then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := DriveLetters.Strings[I][1];
      end;
    end;
    {$WARNINGS ON}
  finally
    DriveLetters.Free;
  end;
end;

function TDockerConfiguration.GetSubnetAddress: String;
const
  DEFAULT_VALUE = '10.0.75.0';
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
const
  DEFAULT_VALUE =
    'C:\Users\Public\Documents\Hyper-V\Virtual Hard Disks\MobyLinuxVM.vhdx';
begin
  {$WARNINGS OFF}
  try
    Result := FConfig.GetValue(JSON_PATH_VHD_PATH, DEFAULT_VALUE);
  except
    on exception do
      Result := DEFAULT_VALUE;
  end;
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
  DriveLetter: String;
  DriveLetters: TSharedDrives;
  Values: TExplodeArray;
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
  else if Name = OPTION_PROXIES_INSECURE_SERVER then
    InsecureProxy := Value
  else if Name = OPTION_PROXIES_SECURE_SERVER then
    SecureProxy := Value

  // Shared Drives
  else if Name = OPTION_SHARED_DRIVES_CREDENTIALS then
    raise ENotImplemented.Create('Configuration value not implemented')
  else if Name = OPTION_SHARED_DRIVES_LETTERS then
  begin
    SetLength(DriveLetters, 0);
    Values := Explode(',', Value);

    for I := 0 to High(Values) do
    begin
      DriveLetter := Values[I] + ':\';

      case GetDriveType(PChar(DriveLetter)) of
        DRIVE_FIXED,
        DRIVE_RAMDISK,
        DRIVE_REMOTE:
        begin
          // Nothing wrong with these device types.
        end;

        DRIVE_CDROM, DRIVE_REMOVABLE:
        begin
          raise Exception.Create(Format('Unsupported drive letter ''%s''', [
            Values[I]
          ]));
        end;
      else
        raise Exception.Create(Format('Invalid drive letter ''%s''', [
          Values[I]
        ]));
      end;

      SetLength(DriveLetters, Length(DriveLetters) + 1);
      DriveLetters[High(DriveLetters)] := Values[I][1];
    end;

    SharedDrives := DriveLetters;
  end

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

procedure TDockerConfiguration.SetSharedDrives(const Value: TSharedDrives);
var
  DriveLetters: TStringList;
  I: Integer;
begin
  try
    DriveLetters := TStringList.Create;
    FConfig.DeleteValue(JSON_PATH_SHARED_DRIVES);

    for I := 0 to High(Value) do
    begin
      {$WARNINGS OFF}
      FConfig.SetValue(JSON_PATH_SHARED_DRIVES + '/' + Value[I], True);
      {$WARNINGS ON}
    end;
  finally
    DriveLetters.Free;
  end;
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

