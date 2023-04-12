unit RttiTestModelU;

interface

uses System.Classes, Generics.Collections;

type
  AStringAttrBase = class abstract(TCustomAttribute)
  strict private
    FStringValue: string;
  public
    constructor Create(AStringValue: string);
    property StringValue: string read FStringValue;

  end;

  ACustomAttr = class(TCustomAttribute)

  end;

  AProtStringAttr = class(AStringAttrBase)
  strict private
    FEnabled: boolean;
  public
    constructor Create(AStringValue: string; AEnabled: boolean);
    property Enabled: boolean read FEnabled;
  end;

  APubStringAttr = class(AStringAttrBase)
  strict private
    FEnabled: boolean;
  public
    constructor Create(AStringValue: string; AEnabled: boolean);
    property Enabled: boolean read FEnabled;
  end;

  TRttiTestModel = class
  strict private
    procedure WarnSuppress;
  private
    FPrivString: string;
    FPrivBoolean: boolean;
    property PrivString: string read FPrivString;
    [ACustomAttr]
    procedure PrivProcedure(Astring: String);
  protected
    [AProtStringAttr('Protected string', true)]
    FProtString: string;
    [AProtStringAttr('Protected boolean', false)]
    FProtBoolean: boolean;
    [AProtStringAttr('Protected string property', true)]
    property ProtString: string read FProtString;
  public
    [APubStringAttr('Public string', true)]
    FPubString: string;
    [APubStringAttr('Public boolean', false)]
    FPubBoolean: boolean;
    [APubStringAttr('Public string property', false)]
    property PPubString: string read FPubString;
    [APubStringAttr('Public procedure', false)]
    procedure PubProcedure(Astring: String);
    [APubStringAttr('Public function', false)]
    function PubFunction(AReturn: boolean): string;
  public
    constructor Create;
    destructor Destroy; override;
  end;

var
  RttiTestModel: TRttiTestModel;

implementation

uses System.SysUtils, FMX.Forms;

{ TRttiTestModel }

constructor TRttiTestModel.Create;
begin
  WarnSuppress;
end;

destructor TRttiTestModel.Destroy;
begin
  inherited;
end;

procedure TRttiTestModel.PrivProcedure(Astring: String);
begin
  FPrivString := Astring;
end;

function TRttiTestModel.PubFunction(AReturn: boolean): string;
begin
  if AReturn then
    result := FPubString
  else
    result := '';
end;

procedure TRttiTestModel.PubProcedure(Astring: String);
begin
  FPubString := Astring;
end;

procedure TRttiTestModel.WarnSuppress;
var s: string;
begin
  FPubString := 'value = Public string';
  FPrivString := 'value = Private string';
  FProtString := 'value = Protected string';
  FPrivBoolean := true;
  FProtBoolean := true;
  FPubBoolean := true;
  s:= PrivString;
  s:= '';
  PrivProcedure('');
end;

{ AStringAttrBase }

constructor AStringAttrBase.Create(AStringValue: string);
begin
  FStringValue := AStringValue;
end;

{ APubStringAttr }

constructor APubStringAttr.Create(AStringValue: string; AEnabled: boolean);
begin
  inherited Create(AStringValue);
  FEnabled := AEnabled;
end;

{ AProtStringAttr }

constructor AProtStringAttr.Create(AStringValue: string; AEnabled: boolean);
begin
  inherited Create(AStringValue);
  FEnabled := AEnabled;
end;

initialization

begin
  RttiTestModel := TRttiTestModel.Create;
end;

end.
