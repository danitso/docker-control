unit ConfigurationInterface;

{$MODE DELPHI}

interface

type
  { IConfigurationInterface }
  IConfigurationInterface = interface
    ['{FBD4A317-82F0-4AAA-8F99-7A2C2959C6E3}']
    function GetOption(const Name: String): String;
    procedure SetOption(const Name, Value: String);
  end;

implementation

end.

