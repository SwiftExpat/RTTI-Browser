unit frmRttiObjectInfo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Rtti, Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TMSFNCTypes, FMX.TMSFNCUtils, FMX.TMSFNCGraphics,
  FMX.TMSFNCGraphicsTypes, FMX.TMSFNCToolBar, FMX.TMSFNCTreeViewBase, FMX.TMSFNCTreeViewData, FMX.TMSFNCCustomTreeView,
  FMX.TMSFNCTreeView, FMX.TMSFNCStatusBar, FMX.TMSFNCCustomControl, System.TypInfo;

type
  TfrmRttiObjInfo = class(TForm)
    TMSFNCToolBar1: TTMSFNCToolBar;
    TMSFNCStatusBar1: TTMSFNCStatusBar;
    tv: TTMSFNCTreeView;
    btnObjInfo: TTMSFNCToolBarButton;
    procedure btnObjInfoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  strict private
    FTypeRootNode: TTMSFNCTreeViewNode;
    FNodeFields, FNodeProperties, FNodeMethods: TTMSFNCTreeViewNode;
    function PropertyKey(AProperty: TRttiProperty): string;
    procedure LoadFields(const ARttiType: TRttiType; const AObject: TObject);
    procedure LoadMethods(const ARttiType: TRttiType; const AObject: TObject);
    procedure LoadProperties(const ARttiType: TRttiType; const AObject: TObject);
    procedure AddAttributes(const ARttiObject: TRttiObject; const ANode: TTMSFNCTreeViewNode; const AObject: TObject);
  private
    FContext: TRttiContext;
    function DisplayVisibility(AVisibility: TMemberVisibility): string;
    function DisplayMethodKind(AMethodKind: TMethodKind): string;
  public
    { Public declarations }
  end;

var
  frmRttiObjInfo: TfrmRttiObjInfo;

implementation

uses RttiTestModelU;

{$R *.fmx}

procedure TfrmRttiObjInfo.AddAttributes(const ARttiObject: TRttiObject; const ANode: TTMSFNCTreeViewNode;
  const AObject: TObject);
  function AddLabelProperties(const ANode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
  begin
    result := tv.AddNode(ANode);
    result.Text[0] := 'Properties';
    result.Extended := true;
  end;
  procedure AddPropertyDetail(const AProperty: TRttiProperty; const ANode: TTMSFNCTreeViewNode; const AObject: TObject);
  var
    pn, vn: TTMSFNCTreeViewNode;
  begin
    pn := tv.AddNode(ANode);
    pn.Text[0] := 'PropName = ' + AProperty.Name;
    if AProperty.IsReadable then
    begin
      pn.Text[1] := 'Readable';
      vn := tv.AddNode(ANode);
      try
        vn.Text[0] := 'Value = ' + AProperty.GetValue(AObject).ToString;
      except
        on E: Exception do

      end;
    end
    else
      pn.Text[1] := '<> Readable';

    if AProperty.IsWritable then
      pn.Text[2] := 'Writable'
    else
      pn.Text[2] := '<> Writable'

  end;
  procedure LoadAttrProps(const ARttiType: TRttiType; const ANode: TTMSFNCTreeViewNode; const AObject: TObject);
  var
    LProperty: TRttiProperty;
    ln: TTMSFNCTreeViewNode;
    props: TArray<TRttiProperty>;
  begin
    ln := nil;
    props := ARttiType.GetDeclaredProperties;
    if Length(props) > 0 then
    begin
      ln := AddLabelProperties(ANode);
      for LProperty in props do
      begin
        AddPropertyDetail(LProperty, ln, AObject);
      end;
    end;
    props := ARttiType.GetProperties;
    if Length(props) > 0 then
    begin
      if ln = nil then
        ln := AddLabelProperties(ANode);
      for LProperty in props do
      begin
        AddPropertyDetail(LProperty, ln, AObject);
      end;
    end;
  end;

var
  an, dn: TTMSFNCTreeViewNode;
  a: TCustomAttribute;
  attribs: TArray<TCustomAttribute>;
  AType: TRttiType;
begin
  attribs := ARttiObject.GetAttributes;
  if Length(attribs) = 0 then
    exit;

  an := tv.AddNode(ANode);
  an.Text[0] := 'Attributes';
  an.Extended := true;
  for a in attribs do
  begin
    dn := tv.AddNode(an);
    dn.Text[0] := a.ClassName;
    dn.Text[3] := a.QualifiedClassName;
    AType := FContext.GetType(a.ClassType);
    LoadAttrProps(AType, dn, a);

  end;
end;

procedure TfrmRttiObjInfo.btnObjInfoClick(Sender: TObject);
var
  c: TObject;
  rType: TRttiType;
begin
  // c := FindGlobalComponent('RttiTestModel');
  c := RttiTestModel;
  // c.Name := 'RttiTestModel';
  if c = nil then
    exit
  else
    tv.ClearNodes;

  FTypeRootNode := tv.AddNode(nil);
  FTypeRootNode.Text[0] := 'RttiTestModel';
  rType := FContext.GetType(c.ClassType);
  LoadFields(rType, c);
  LoadMethods(rType, c);
  LoadProperties(rType, c);
  tv.ExpandAll;
end;

function TfrmRttiObjInfo.DisplayMethodKind(AMethodKind: TMethodKind): string;
begin
  case AMethodKind of
    mkProcedure:
      result := 'Procedure';
    mkFunction:
      result := 'Function';
    mkConstructor:
      result := 'Constructor';
    mkDestructor:
      result := 'Destructor';
    mkClassProcedure:
      result := 'Class Procedure';
    mkClassFunction:
      result := 'Class Function';
    mkClassConstructor:
      result := 'Class Constructor';
    mkClassDestructor:
      result := 'Class Destructor';
    mkOperatorOverload:
      result := 'Operator Overload';
    mkSafeProcedure:
      result := 'Safe Procedure';
    mkSafeFunction:
      result := 'Safe Function';
  end;
end;

function TfrmRttiObjInfo.DisplayVisibility(AVisibility: TMemberVisibility): string;
begin
  case AVisibility of
    mvPrivate:
      result := 'Private';
    mvProtected:
      result := 'Protected';
    mvPublic:
      result := 'Public';
    mvPublished:
      result := 'Published';
  end;
end;

procedure TfrmRttiObjInfo.FormCreate(Sender: TObject);
begin
  FContext.Create;
  FContext.KeepContext;
end;

procedure TfrmRttiObjInfo.LoadFields(const ARttiType: TRttiType; const AObject: TObject);
  function FieldKey(const AField: TRttiField): string; inline;
  begin
    result := AField.Name + '|~' + AField.Parent.QualifiedName;
  end;
  function FieldExists(const AField: TRttiField): boolean;
  var
    tn: TTMSFNCTreeViewNode;
    mk: string;
  begin
    result := false;
    mk := FieldKey(AField);
    for tn in FNodeFields.Nodes do
    begin
      result := tn.DataString = mk;
      if result then
        exit(true);
    end;
  end;
  function AddField(const AField: TRttiField; const AObject: TObject): TTMSFNCTreeViewNode;
  var
    ft: TRttiType;
  begin
    result := tv.AddNode(FNodeFields);
    result.Text[0] := AField.Name;
    result.Text[2] := DisplayVisibility(AField.Visibility);
    result.DataString := FieldKey(AField);
    ft := AField.FieldType;
    result.Text[1] := ft.ToString;
    result.Text[2] := AField.GetValue(AObject).ToString;
    AddAttributes(AField, result, AObject);
  end;

var
  rField: TRttiField;
  fn: TTMSFNCTreeViewNode;
begin
  FNodeFields := tv.AddNode(FTypeRootNode);
  FNodeFields.Text[0] := 'Fields';
  for rField in ARttiType.GetDeclaredFields do
  begin
    fn := AddField(rField, AObject);
    fn.Text[3] := 'Declared';
  end;

  for rField in ARttiType.GetFields do
  begin
    if FieldExists(rField) then
      continue
    else
    begin
      fn := AddField(rField, AObject);
      fn.Text[3] := rField.Parent.QualifiedName;
    end;
  end;

end;

procedure TfrmRttiObjInfo.LoadMethods(const ARttiType: TRttiType; const AObject: TObject);
  function MethodKey(AMethod: TRttiMethod): string;
  begin
    result := AMethod.Name + '|~' + AMethod.Parent.QualifiedName;
  end;
  function MethodExists(AMethod: TRttiMethod): boolean;
  var
    tn: TTMSFNCTreeViewNode;
    mk: string;
  begin
    result := false;
    mk := MethodKey(AMethod);
    for tn in FNodeMethods.Nodes do
    begin
      result := tn.DataString = mk;
      if result then
        exit(true);
    end;
  end;

  function AddMethod(AMethod: TRttiMethod; const AObject: TObject): TTMSFNCTreeViewNode;
  begin
    result := tv.AddNode(FNodeMethods);
    result.Text[0] := AMethod.Name;
    result.Text[2] := DisplayVisibility(AMethod.Visibility);
    result.Text[1] := DisplayMethodKind(AMethod.MethodKind);
    result.DataString := MethodKey(AMethod);
    AddAttributes(AMethod, result, AObject);
  end;

var
  rMethod: TRttiMethod;
  mn: TTMSFNCTreeViewNode;
begin
  FNodeMethods := tv.AddNode(FTypeRootNode);
  FNodeMethods.Text[0] := 'Methods';
  for rMethod in ARttiType.GetDeclaredMethods do
  begin
    mn := AddMethod(rMethod, AObject);
    mn.Text[3] := 'Declared';
  end;
  for rMethod in ARttiType.GetMethods do
  begin
    if MethodExists(rMethod) then
      continue
    else
    begin
      mn := AddMethod(rMethod, AObject);
      mn.Text[3] := rMethod.Parent.QualifiedName;
    end;
  end;
end;

procedure TfrmRttiObjInfo.LoadProperties(const ARttiType: TRttiType; const AObject: TObject);
  function PropertyExists(AProperty: TRttiProperty): boolean;
  var
    tn: TTMSFNCTreeViewNode;
    mk: string;
  begin
    result := false;
    mk := PropertyKey(AProperty);
    for tn in FNodeProperties.Nodes do
    begin
      result := tn.DataString = mk;
      if result then
        exit(true);
    end;
  end;
  function AddProperty(AProperty: TRttiProperty; const AObject: TObject): TTMSFNCTreeViewNode;
  var
    pt: TRttiType;
  begin
    result := tv.AddNode(FNodeProperties);
    result.Text[0] := AProperty.Name;
    result.Text[3] := DisplayVisibility(AProperty.Visibility);
    result.DataString := PropertyKey(AProperty);
    pt := AProperty.PropertyType;
    result.Text[1] := pt.ToString;
    AddAttributes(AProperty, result, AObject);
  end;

var
  rProperty: TRttiProperty;
  pn: TTMSFNCTreeViewNode;
begin
  FNodeProperties := tv.AddNode(FTypeRootNode);
  FNodeProperties.Text[0] := 'Properties';
  for rProperty in ARttiType.GetDeclaredProperties do
  begin
    pn := AddProperty(rProperty, AObject);
    pn.Text[2] := 'Declared';
  end;

  for rProperty in ARttiType.GetProperties do
  begin
    if PropertyExists(rProperty) then
      continue
    else
    begin
      pn := AddProperty(rProperty, AObject);
      pn.Text[2] := rProperty.Parent.QualifiedName;
    end;
  end;

end;

function TfrmRttiObjInfo.PropertyKey(AProperty: TRttiProperty): string;
begin
  result := AProperty.Name + '|~' + AProperty.Parent.QualifiedName;
end;

end.
