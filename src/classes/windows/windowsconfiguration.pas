unit WindowsConfiguration;

{$MODE DELPHI}

interface

uses
  Classes,
  DockerConfiguration,
  JwaWinCred,
  JwaWinCrypt,
  StringFunctions,
  SysUtils,
  Windows,
  WindowsShares;

type
  { TWindowsConfiguration }
  TWindowsConfiguration = class(TDockerConfiguration)
  private const
    CREDENTIALS_TARGET = 'Docker Host Filesystem Access';
    JSON_PATH_AUTOSTART = '/StartAtLogin';
    JSON_PATH_AUTOUPDATE = '/AutoUpdateEnabled';
    JSON_PATH_DISK_IMAGE = '/MobyVhdPathOverride';
    JSON_PATH_DNS = '/NameServer';
    JSON_PATH_EXCLUDED_PROXY_HOSTNAMES = '/ProxyExclude';
    JSON_PATH_EXPOSE = '/ExposeTcp';
    JSON_PATH_FORWARD_DNS = '/UseDnsForwarder';
    JSON_PATH_INSECURE_PROXY = '/ProxyHttp';
    JSON_PATH_MEMORY = '/VmMemory';
    JSON_PATH_PROCESSORS = '/VmCpus';
    JSON_PATH_SECURE_PROXY = '/ProxyHttps';
    JSON_PATH_SHARED_DRIVES = '/SharedDrives';
    JSON_PATH_SUBNET_MASK_SIZE = '/SubnetMaskSize';
    JSON_PATH_TRACKING = '/IsTracking';
    JSON_PATH_USE_PROXY = '/UseHttpProxy';
    OPTION_GENERAL_EXPOSE_DAEMON = 'general.expose_daemon';
    OPTION_NETWORK_DNS_FORWARDING = 'network.dns_forwarding';
    OPTION_NETWORK_DNS_SERVER = 'network.dns_server';
    OPTION_NETWORK_SUBNET_MASK_SIZE = 'network.subnet_mask_size';
    OPTION_SHARED_DRIVES_CREDENTIALS = 'shared_drives.credentials';
    OPTION_SHARED_DRIVES_LETTERS = 'shared_drives.letters';
  protected
    function GetAutoStart: Boolean; override;
    function GetAutoUpdate: Boolean; override;
    function GetDiskImage: String; override;
    function GetDns: String;
    function GetExcludedProxyHostnames: String; override;
    function GetExpose: Boolean;
    function GetForwardDns: Boolean;
    function GetInsecureProxyServer: String; override;
    function GetMemory: Integer; override;
    function GetProcessors: Integer; override;
    function GetSecureProxyServer: String; override;
    function GetSharedCredentials: TWindowsCredentials;
    function GetSharedDrives: TWindowsDriveLetters;
    function GetSubnetAddress: String;
    function GetSubnetMaskSize: Byte;
    function GetTracking: Boolean; override;
    function GetUseProxy: Boolean; override;

    procedure SetAutoStart(const Value: Boolean); override;
    procedure SetAutoUpdate(const Value: Boolean); override;
    procedure SetDiskImage(const Value: String); override;
    procedure SetDns(const Value: String);
    procedure SetExcludedProxyHostnames(const Value: String); override;
    procedure SetExpose(const Value: Boolean);
    procedure SetForwardDns(const Value: Boolean);
    procedure SetInsecureProxyServer(const Value: String); override;
    procedure SetMemory(const Value: Integer); override;
    procedure SetProcessors(const Value: Integer); override;
    procedure SetSecureProxyServer(const Value: String); override;
    procedure SetSharedCredentials(const Value: TWindowsCredentials);
    procedure SetSharedDrives(const Value: TWindowsDriveLetters);
    procedure SetSubnetAddress(const Value: String);
    procedure SetSubnetMaskSize(const Value: Byte);
    procedure SetTracking(const Value: Boolean); override;
    procedure SetUseProxy(const Value: Boolean); override;
  public
    function GetOption(const Name: string): String; override;
    procedure SetOption(const Name, Value: String); override;

    property Dns: String read GetDns write SetDns;
    property Expose: Boolean read GetExpose write SetExpose;
    property ForwardDns: Boolean read GetForwardDns write SetForwardDns;
    property SharedCredentials: TWindowsCredentials read GetSharedCredentials
      write SetSharedCredentials;
    property SharedDrives: TWindowsDriveLetters read GetSharedDrives
      write SetSharedDrives;
    property SubnetMaskSize: Byte read GetSubnetMaskSize
      write SetSubnetMaskSize;
  end;

implementation

function TWindowsConfiguration.GetAutoStart: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_AUTOSTART, True);
end;

function TWindowsConfiguration.GetAutoUpdate: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_AUTOUPDATE, True);
end;

function TWindowsConfiguration.GetDiskImage: String;
const
  DEFAULT_VALUE =
    'C:\Users\Public\Documents\Hyper-V\Virtual Hard Disks\MobyLinuxVM.vhdx';
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

function TWindowsConfiguration.GetDns: String;
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

function TWindowsConfiguration.GetExcludedProxyHostnames: String;
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

function TWindowsConfiguration.GetExpose: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_EXPOSE, False);
end;

function TWindowsConfiguration.GetForwardDns: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_FORWARD_DNS, True);
end;

function TWindowsConfiguration.GetInsecureProxyServer: String;
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

function TWindowsConfiguration.GetMemory: Integer;
begin
  Result := FConfig.GetValue(JSON_PATH_MEMORY, 2048);
end;

function TWindowsConfiguration.GetOption(const Name: string): String;
var
  I: Integer;
  SharedCredentials: TWindowsCredentials;
  SharedDrives: TWindowsDriveLetters;
begin
  Result := '';

  // General
  if Name = OPTION_GENERAL_EXPOSE_DAEMON then
    Result := LowerCase(BoolToStr(Expose, True))

  // Network
  else if Name = OPTION_NETWORK_DNS_FORWARDING then
    Result := LowerCase(BoolToStr(ForwardDns, True))
  else if Name = OPTION_NETWORK_DNS_SERVER then
    Result := Dns
  else if Name = OPTION_NETWORK_SUBNET_MASK_SIZE then
    Result := IntToStr(SubnetMaskSize)

  // Shared Drives
  else if Name = OPTION_SHARED_DRIVES_CREDENTIALS then
  begin
    SharedCredentials := GetSharedCredentials;

    if Length(SharedCredentials.Username) > 0 then
    begin
      if Length(SharedCredentials.Computer) > 0 then
        Result := SharedCredentials.Computer + '\';

      Result := Result + SharedCredentials.Username + ':' +
        SharedCredentials.Password;
    end;
  end
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

  // Allow the base class to retrieve common options.
  else
    Result := inherited;
end;

function TWindowsConfiguration.GetProcessors: Integer;
begin
  Result := FConfig.GetValue(JSON_PATH_PROCESSORS, 2);
end;

function TWindowsConfiguration.GetSecureProxyServer: String;
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

function TWindowsConfiguration.GetSharedCredentials: TWindowsCredentials;
var
  Credentials: PCREDENTIAL;
  DecryptedDataBlob: DATA_BLOB;
  EncryptedData: String;
  EncryptedDataBlob: DATA_BLOB;
  Index: Integer;
  Success: BOOL;
begin
  Result.Computer := '';
  Result.Username := '';
  Result.Password := '';

  try
    // Retrieve the credentials using the Windows Credential API.
    Success := CredRead(CREDENTIALS_TARGET, CRED_TYPE_GENERIC, 0, Credentials);

    if not Success then
    begin
      if GetLastError <> 1168 then
        raise Exception.Create('Failed to retrieve the credentials');

      Exit;
    end;

    // Extract the username which is simply stored as plain text.
    Result.Username := Credentials^.UserName;
    Index := Pos('\', Result.Username);

    if Index <> 0 then
    begin
      Result.Computer := Copy(Result.Username, 0, Index - 1);
      Result.Username := Copy(Result.Username, Index + 1, Length(
        Result.Username));
    end;

    // Extract the encrypted credentials blob by copying the byte array.
    SetLength(EncryptedData, Credentials^.CredentialBlobSize);
    CopyMemory(@EncryptedData[1], Credentials^.CredentialBlob,
      Credentials^.CredentialBlobSize);

    // Decrypt the credentials using the Windows Cryptography API.
    DecryptedDataBlob.cbData := 0;
    DecryptedDataBlob.pbData := nil;
    EncryptedDataBlob.cbData := Length(EncryptedData);
    EncryptedDataBlob.pbData := @EncryptedData[1];

    Success := CryptUnprotectData(@EncryptedDataBlob, nil, nil, nil, nil, 0,
      @DecryptedDataBlob);

    if not Success then
      raise Exception.Create('Failed to decrypt the credentials');

    SetLength(Result.Password, DecryptedDataBlob.cbData);
    CopyMemory(@Result.Password[1], DecryptedDataBlob.pbData,
      DecryptedDataBlob.cbData);
  finally
    if Assigned(Credentials) then
      CredFree(Credentials);
  end;
end;

function TWindowsConfiguration.GetSharedDrives: TWindowsDriveLetters;
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
      {$WARNINGS ON}
    end;
  finally
    DriveLetters.Free;
  end;
end;

function TWindowsConfiguration.GetSubnetAddress: String;
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

function TWindowsConfiguration.GetSubnetMaskSize: Byte;
begin
  Result := FConfig.GetValue(JSON_PATH_SUBNET_MASK_SIZE, 24);
end;

function TWindowsConfiguration.GetTracking: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_TRACKING, True);
end;

function TWindowsConfiguration.GetUseProxy: Boolean;
begin
  Result := FConfig.GetValue(JSON_PATH_USE_PROXY, False);
end;

procedure TWindowsConfiguration.SetAutoStart(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_AUTOSTART, Value);
end;

procedure TWindowsConfiguration.SetAutoUpdate(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_AUTOUPDATE, Value);
end;

procedure TWindowsConfiguration.SetDiskImage(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_DISK_IMAGE, Value);
  {$WARNINGS ON}
end;

procedure TWindowsConfiguration.SetDns(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_DNS, Value);
  {$WARNINGS ON}
end;

procedure TWindowsConfiguration.SetExcludedProxyHostnames(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_EXCLUDED_PROXY_HOSTNAMES, Value);
  {$WARNINGS ON}
end;

procedure TWindowsConfiguration.SetExpose(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_EXPOSE, Value);
end;

procedure TWindowsConfiguration.SetForwardDns(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_FORWARD_DNS, Value);
end;

procedure TWindowsConfiguration.SetInsecureProxyServer(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_INSECURE_PROXY, Value);
  {$WARNINGS ON}
end;

procedure TWindowsConfiguration.SetMemory(const Value: Integer);
begin
  FConfig.SetValue(JSON_PATH_MEMORY, Value);
end;

procedure TWindowsConfiguration.SetOption(const Name, Value: String);
var
  Credentials: TWindowsCredentials;
  DriveLetter: String;
  DriveLetters: TWindowsDriveLetters;
  Values: TStringArray;
  I: Integer;
begin
  // General
  if Name = OPTION_GENERAL_EXPOSE_DAEMON then
    Expose := StrToBool(Value)

  // Network
  else if Name = OPTION_NETWORK_DNS_FORWARDING then
    ForwardDns := StrToBool(Value)
  else if Name = OPTION_NETWORK_DNS_SERVER then
    Dns := Value
  else if Name = OPTION_NETWORK_SUBNET_MASK_SIZE then
  begin
    I := StrToInt(Value);

    if (I < 0) or (I > 32) then
      raise Exception.Create('Invalid subnet mask size');

    SubnetMaskSize := I;
  end

  // Shared Drives
  else if Name = OPTION_SHARED_DRIVES_CREDENTIALS then
  begin
    I := Pos(':', Value);

    if I = 0 then
      raise Exception.Create('The credentials must be specified as ' +
        '''username:password''');

    Credentials.Username := Copy(Value, 1, I - 1);
    Credentials.Password := Copy(Value, I + 1, Length(Value));

    I := Pos('\', Credentials.Username);

    if I <> 0 then
    begin
      Credentials.Computer := Copy(Credentials.Username, 1, I - 1);
      Credentials.Username := Copy(Credentials.Username, I + 1, Length(
        Credentials.Username));
    end
    else
      Credentials.Computer := SysUtils.GetEnvironmentVariable('COMPUTERNAME');

    SharedCredentials := Credentials;
  end
  else if Name = OPTION_SHARED_DRIVES_LETTERS then
  begin
    SetLength(DriveLetters, 0);
    Values := TStringFunctions.Explode(',', Value);

    for I := 0 to High(Values) do
    begin
      DriveLetter := Values[I] + ':\';

      case GetDriveType(PChar(DriveLetter)) of
        DRIVE_FIXED,
        DRIVE_REMOTE:
        begin
          // Nothing wrong with these device types.
        end;

        DRIVE_CDROM,
        DRIVE_RAMDISK,
        DRIVE_REMOVABLE:
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

  // Allow the base class to set common options.
  else
    inherited;
end;

procedure TWindowsConfiguration.SetProcessors(const Value: Integer);
begin
  FConfig.SetValue(JSON_PATH_PROCESSORS, Value);
end;

procedure TWindowsConfiguration.SetSecureProxyServer(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_SECURE_PROXY, Value);
  {$WARNINGS ON}
end;

procedure TWindowsConfiguration.SetSharedCredentials(
  const Value: TWindowsCredentials
);
var
  Credentials: CREDENTIAL;
  DataBlob: DATA_BLOB;
  EncryptedDataBlob: DATA_BLOB;
  Success: BOOL;
  Username: String;
begin
  // Prefix the username with the computer name.
  Username := Value.Computer + '\' + Value.Username;

  // Encrypt the credentials using the Windows Cryptography API.
  DataBlob.cbData := Length(Value.Password);
  DataBlob.pbData := @Value.Password[1];

  EncryptedDataBlob.cbData := 0;
  EncryptedDataBlob.pbData := nil;

  Success := CryptProtectData(@DataBlob, nil, nil, nil, nil, 0,
    @EncryptedDataBlob);

  if not Success then
    raise Exception.Create('Failed to encrypt the credentials');

  // Write the credentials using the Windows Credential API.
  Credentials.AttributeCount := 0;
  Credentials.Attributes := nil;
  Credentials.CredentialBlob := EncryptedDataBlob.pbData;
  Credentials.CredentialBlobSize := EncryptedDataBlob.cbData;
  Credentials.Flags := 0;
  Credentials.Persist := CRED_PERSIST_ENTERPRISE;
  Credentials.TargetName := CREDENTIALS_TARGET;
  Credentials.Type_ := CRED_TYPE_GENERIC;
  Credentials.UserName := PChar(Username);

  Success := CredWrite(@Credentials, 0);

  if not Success then
    raise Exception.Create('Failed to save the credentials');
end;

procedure TWindowsConfiguration.SetSharedDrives(
  const Value: TWindowsDriveLetters
);
var
  Credentials: TWindowsCredentials;
  CurrentDriveLetters: TWindowsDriveLetters;
  I: Integer;
begin
  // Unshare the current drives even though Docker for Windows does not do this.
  CurrentDriveLetters := GetSharedDrives;

  for I := 0 to High(CurrentDriveLetters) do
    TWindowsShares.UnshareDrive(CurrentDriveLetters[I]);

  // Reset the shared drives object in the configuration file.
  FConfig.DeleteValue(JSON_PATH_SHARED_DRIVES);

  // Retrieve the stored credentials which will be used by the virtual machine
  // when accessing the shared drives.
  Credentials := GetSharedCredentials;

  // Share the new list of drives.
  for I := 0 to High(Value) do
  begin
    TWindowsShares.UnshareDrive(CurrentDriveLetters[I]);
    TWindowsShares.ShareDrive(Value[I], Credentials);
    {$WARNINGS OFF}
    FConfig.SetValue(JSON_PATH_SHARED_DRIVES + '/' + Value[I], True);
    {$WARNINGS ON}
  end;
end;

procedure TWindowsConfiguration.SetSubnetAddress(const Value: String);
begin
  {$WARNINGS OFF}
  FConfig.SetValue(JSON_PATH_SUBNET_ADDRESS, Value);
  {$WARNINGS ON}
end;

procedure TWindowsConfiguration.SetSubnetMaskSize(const Value: Byte);
begin
  FConfig.SetValue(JSON_PATH_SUBNET_MASK_SIZE, Value);
end;

procedure TWindowsConfiguration.SetTracking(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_TRACKING, Value);
end;

procedure TWindowsConfiguration.SetUseProxy(const Value: Boolean);
begin
  FConfig.SetValue(JSON_PATH_USE_PROXY, Value);
end;

end.

