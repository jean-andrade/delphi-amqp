unit DelphiAMQP.Connections.AMQPConnection;

interface

uses
  DelphiAMQP.ConnectionIntf, DelphiAMQP.Frames.ConnectionStart,
  DelphiAMQP.AMQPTypes, DelphiAMQP.AMQPValue;

type
  TAMQPConnection = class
  private
    FCon: IAMQPTCPConnection;
    FPort: Integer;
    FPassword: string;
    FHost: string;
    FUser: string;
    FVirtualHost: string;

  private
    FReadTimeOut: Integer;

    procedure ReplyConnectionStart(const AStartFrame: TAMQPConnectionStartFrame);
    procedure HandleConnectionStart();

    function BuildShortStringAqmpField(const AValue: string): TAMQPValueType;
  public
    constructor Create(const AConnection: IAMQPTCPConnection);

    procedure Open;

    function SetHost(const AHost: string): TAMQPConnection;
    function SetPort(const APort: Integer): TAMQPConnection;
    function SetConnectionString(const AConnectionString: string): TAMQPConnection;
    function SetUser(const AUser: string): TAMQPConnection;
    function SetPassword(const APassword: string): TAMQPConnection;

    property TCPConnection: IAMQPTCPConnection read FCon;
    property ReadTimeOut: Integer read FReadTimeOut write FReadTimeOut;
  end;

implementation

uses
  DelphiAMQP.Frames.ConnectionStartOk, System.SysUtils,
  DelphiAMQP.Util.Functions, DelphiAMQP.Constants,
  DelphiAMQP.Frames.BasicFrame;

{ TAMQPConnection }

function TAMQPConnection.BuildShortStringAqmpField(const AValue: string): TAMQPValueType;
begin
  Result := TAMQPValueType.Create(TAMQPValueType.LongString);
  try
    Result.AsString := AValue;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

constructor TAMQPConnection.Create(const AConnection: IAMQPTCPConnection);
begin
  FCon := AConnection;
  FReadTimeOut := 5000;
end;

procedure TAMQPConnection.HandleConnectionStart;
var
  oFrame: TAMQPConnectionStartFrame;
  Frame: TAMQPBasicFrame;
begin
  oFrame := FCon.Receive(FReadTimeOut) as TAMQPConnectionStartFrame;
  ReplyConnectionStart(oFrame);
  Frame := FCon.Receive(FReadTimeOut);
end;

procedure TAMQPConnection.Open;
begin
  FCon.Open;
  HandleConnectionStart();
end;

procedure TAMQPConnection.ReplyConnectionStart(const AStartFrame: TAMQPConnectionStartFrame);
var
  Reply: TAMQPConnectionStartOkFrame;
begin
  Reply := TAMQPConnectionStartOkFrame.Create;
  try
    Reply.ClientProperties.AsAMQPTable.Add('product', BuildShortStringAqmpField('delphi-amqp'));
    Reply.ClientProperties.AsAMQPTable.Add('version', BuildShortStringAqmpField('DELPHI_AMQP_VERSION'));
    {$IFDEF LINUX64}
    Reply.ClientProperties.AsAMQPTable.Add('platform', BuildShortStringAqmpField('linux'));
    {$ELSE}
    Reply.ClientProperties.AsAMQPTable.Add('platform', BuildShortStringAqmpField('windows'));
    {$ENDIF}


    Reply.Locale.AsString := 'en_US';
    Reply.Mechanism.AsString := LOGIN_TYPE_PLAIN;
    Reply.Response.AsString := getAMQPSecurityRespose(Reply.Mechanism.AsString, FUser, FPassword);
    FCon.Send(Reply);
  finally
    FreeAndNil(Reply);
  end;
end;

function TAMQPConnection.SetConnectionString(const AConnectionString: string): TAMQPConnection;
begin
  FCon.SetConnectionString(AConnectionString);
  Result := Self;
end;

function TAMQPConnection.SetHost(const AHost: string): TAMQPConnection;
begin
  FCon.SetHost(AHost);
  Result := Self;
end;

function TAMQPConnection.SetPassword(const APassword: string): TAMQPConnection;
begin
  FPassword := APassword;
  FCon.SetPassword(APassword);
  Result := Self;
end;

function TAMQPConnection.SetPort(const APort: Integer): TAMQPConnection;
begin
  FCon.SetPort(APort);
  Result := Self;
end;

function TAMQPConnection.SetUser(const AUSer: string): TAMQPConnection;
begin
  FUser := AUser;
  FCon.SetUser(AUSer);
  Result := Self;
end;

end.
