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
    OPTION_ADVANCED_CPUS = 'advanced.cpus';
    OPTION_ADVANCED_DISK_IMAGE = 'advanced.disk_image';
    OPTION_ADVANCED_MEMORY = 'advanced.memory';
    OPTION_GENERAL_AUTOSTART = 'general.autostart';
    OPTION_GENERAL_AUTOUPDATE = 'general.autoupdate';
    OPTION_GENERAL_TRACKING = 'general.tracking';
    OPTION_PROXIES_ENABLED = 'proxies.enabled';
    OPTION_PROXIES_EXCLUDED_HOSTNAMES = 'proxies.excluded_hostnames';
    OPTION_PROXIES_INSECURE_SERVER = 'proxies.insecure_server';
    OPTION_PROXIES_SECURE_SERVER = 'proxies.secure_server';
  protected
    FConfig: TJSONConfig;
  public
    constructor Create(const FileName: String);
    destructor Destroy; override;

    function GetOption(const Name: string): String; virtual; abstract;
    procedure SetOption(const Name, Value: String); virtual; abstract;
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

end.

