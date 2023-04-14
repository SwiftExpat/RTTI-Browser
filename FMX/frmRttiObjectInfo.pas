unit frmRttiObjectInfo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Rtti, Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TMSFNCTypes, FMX.TMSFNCUtils, FMX.TMSFNCGraphics,
  FMX.TMSFNCGraphicsTypes, FMX.TMSFNCToolBar, FMX.TMSFNCTreeViewBase, FMX.TMSFNCTreeViewData, FMX.TMSFNCCustomTreeView,
  FMX.TMSFNCTreeView, FMX.TMSFNCStatusBar, FMX.TMSFNCCustomControl, System.TypInfo, FMX.TMSFNCPanel,
  FMX.TMSFNCNavigationPanel, FMX.TMSFNCCustomComponent, FMX.TMSFNCBitmapContainer;

type
  TfrmRttiObjInfo = class(TForm)
    TMSFNCToolBar1: TTMSFNCToolBar;
    TMSFNCStatusBar1: TTMSFNCStatusBar;
    tvFields: TTMSFNCTreeView;
    btnObjInfo: TTMSFNCToolBarButton;
    navpnlRtti: TTMSFNCNavigationPanel;
    TMSFNCNavigationPanel1Panel0: TTMSFNCNavigationPanelContainer;
    TMSFNCNavigationPanel1Panel1: TTMSFNCNavigationPanelContainer;
    TMSFNCNavigationPanel1Panel2: TTMSFNCNavigationPanelContainer;
    tvProperties: TTMSFNCTreeView;
    tvMethods: TTMSFNCTreeView;
    bmc: TTMSFNCBitmapContainer;
    procedure btnObjInfoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    procedure tvFieldsBeforeDrawNode(Sender: TObject; AGraphics: TTMSFNCGraphics; ARect: TRectF;
      ANode: TTMSFNCTreeViewVirtualNode; var AAllow, ADefaultDraw: Boolean);
  strict private
    // FTypeRootNode: TTMSFNCTreeViewNode;
    // FNodeProperties, FNodeMethods: TTMSFNCTreeViewNode; // FNodeFields,
    function DisplayHeaderText(const AText: string): string; inline;
    function PropertyKey(AProperty: TRttiProperty): string;
    procedure LoadFields(const ARttiType: TRttiType; const AObject: TObject);
    procedure LoadMethods(const ARttiType: TRttiType; const AObject: TObject);
    procedure LoadProperties(const ARttiType: TRttiType; const AObject: TObject);
    procedure AddAttributes(const ARttiObject: TRttiObject; const ANode: TTMSFNCTreeViewNode; const AObject: TObject);
    procedure LoadRootNodes;
    procedure SetTypeIcon(const AType: string; const ANode: TTMSFNCTreeViewNode);
  private
    FContext: TRttiContext;
    FBitmaps: TObjectList<TTMSFNCBitmap>;
    procedure CreateIcons;
    function DisplayVisibility(AVisibility: TMemberVisibility): string;
    function DisplayMethodKind(AMethodKind: TMethodKind): string;
  public
    { Public declarations }
  end;

var
  frmRttiObjInfo: TfrmRttiObjInfo;

implementation

{$R *.fmx}

uses RttiTestModelU;

const
  rowid_attribute_header = 'AttribHeader';
  rowid_properties_header = 'PropertyHeader';
  rowid_methods_header = 'MethodsHeader';
  rowid_fields_header = 'FieldsHeader';

procedure TfrmRttiObjInfo.AddAttributes(const ARttiObject: TRttiObject; const ANode: TTMSFNCTreeViewNode;
  const AObject: TObject);
  function AttribKey: string;
  begin
    result := '';
  end;
  function AddLabelProperties(const ANode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
  begin
    result := tvFields.AddNode(ANode);
    result.Text[0] := DisplayHeaderText('Property Name');
    result.Text[1] := DisplayHeaderText('Value');
    result.Text[2] := DisplayHeaderText('Read / Write');
    result.DataString := rowid_properties_header;
  end;
  procedure AddPropertyDetail(const AProperty: TRttiProperty; const ANode: TTMSFNCTreeViewNode; const AObject: TObject);
  var
    pn: TTMSFNCTreeViewNode;
  begin
    pn := tvFields.AddNode(ANode);
    pn.Text[0] := 'PropName = ' + AProperty.Name;
    if AProperty.IsReadable then
    begin
      pn.Text[2] := 'R /';
      try
        pn.Text[1] := AProperty.GetValue(AObject).ToString;
      except
        on E: Exception do
          pn.Text[1] := 'Ex ' + E.Message
      end;
    end
    else
      pn.Text[2] := '<R>';

    if AProperty.IsWritable then
      pn.Text[2] := pn.Text[2] + ' W'
    else
      pn.Text[2] := pn.Text[2] + '<W>'

  end;
  procedure LoadAttrProps(const ARttiType: TRttiType; const ANode: TTMSFNCTreeViewNode; const AObject: TObject);
  var
    LProperty: TRttiProperty;
    ln: TTMSFNCTreeViewNode;
    props: TArray<TRttiProperty>;
  begin
    ln := nil;
    // props := ARttiType.GetDeclaredProperties;
    // if Length(props) > 0 then
    // begin
    // ln := AddLabelProperties(ANode);
    // for LProperty in props do
    // begin
    // AddPropertyDetail(LProperty, ln, AObject);
    // end;
    // end;
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

  an := tvFields.AddNode(ANode);
  an.DataString := rowid_attribute_header;
  an.Text[0] := 'Attributes';
  an.Extended := true;
  for a in attribs do
  begin
    dn := tvFields.AddNode(an);
    dn.Text[0] := a.ClassName;
    dn.Text[3] := a.QualifiedClassName;
    dn.CollapsedIconNames[0, false] := 'attribute';
    dn.ExpandedIconNames[0, false] := 'attribute';
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
    exit;

  LoadRootNodes;
  // tv.Columns[0].Text := 'RttiTestModel';
  rType := FContext.GetType(c.ClassType);
  LoadFields(rType, c);
  LoadProperties(rType, c);
  LoadMethods(rType, c);
  // tv.ExpandAll;
end;

procedure TfrmRttiObjInfo.CreateIcons;
  procedure AddIcon(ALetter: string; AItemName: string);
  var
    r: TRectF;
    bmi: TTMSFNCBitmapItem;
    bmp: TTMSFNCBitmap;
  begin
    bmi := bmc.Items.Add;
    bmp := TTMSFNCBitmap.Create(20, 20);
    FBitmaps.Add(bmp);
    bmi.Name := AItemName;
    r := TRectF.Create(0.5, 0.5, 19.5, 19.5);
    bmp.Canvas.BeginScene();
    bmp.Canvas.Stroke.Color := gcTeal;
    bmp.Canvas.Stroke.Thickness := 1.5;
    bmp.Canvas.DrawRect(r, 2, 2, AllCorners, 90, TcornerType.bevel);
    bmp.Canvas.Fill.Color := gcBlack;
    bmp.Canvas.Fill.Kind := TBrushKind.Solid;
    bmp.Canvas.Font.Family := 'Consolas';
    bmp.Canvas.Font.Size := 20;
    bmp.Canvas.FillText(bmp.BoundsF, ALetter, false, 1, [], TTextAlign.Center, TTextAlign.Center);
    bmp.Canvas.EndScene;
    bmi.Bitmap := bmp;
  end;

begin
  AddIcon('S', 'string');
  AddIcon('B', 'boolean');
  AddIcon('F', 'field');
  AddIcon('A', 'attribute');
  AddIcon('?', 'unknown');

end;

function TfrmRttiObjInfo.DisplayHeaderText(const AText: string): string;
begin
  result := '<p align="center"><b>' + AText + '</b></p>';
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
  FBitmaps := TObjectList<TTMSFNCBitmap>.Create(true);
  CreateIcons;
  btnObjInfoClick(self);
end;

procedure TfrmRttiObjInfo.LoadFields(const ARttiType: TRttiType; const AObject: TObject);
  function FieldKey(const AField: TRttiField): string; inline;
  begin
    result := AField.Name + '|~' + AField.Parent.QualifiedName;
  end;
  function FieldExists(const AField: TRttiField): Boolean;
  var
    tn: TTMSFNCTreeViewNode;
    mk: string;
  begin
    result := false;
    mk := FieldKey(AField);
    for tn in tvFields.Nodes do
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
    result := tvFields.AddNode(nil);
    result.Text[0] := AField.Name;
    result.Text[2] := DisplayVisibility(AField.Visibility);
    result.DataString := FieldKey(AField);
    ft := AField.FieldType;
    result.Text[1] := AField.GetValue(AObject).ToString;
    SetTypeIcon(ft.ToString, result);

    result.Text[2] := AField.GetValue(AObject).ToString;
    AddAttributes(AField, result, AObject);
    result.CollapsedIconNames[0, false] := 'field';
    result.ExpandedIconNames[0, false] := 'field';
  end;

var
  rField: TRttiField;
  fn: TTMSFNCTreeViewNode;
begin

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
  function MethodExists(AMethod: TRttiMethod): Boolean;
  var
    tn: TTMSFNCTreeViewNode;
    mk: string;
  begin
    result := false;
    mk := MethodKey(AMethod);
    for tn in tvMethods.Nodes do
    begin
      result := tn.DataString = mk;
      if result then
        exit(true);
    end;
  end;

  function AddMethod(AMethod: TRttiMethod; const AObject: TObject): TTMSFNCTreeViewNode;
  begin
    result := tvMethods.AddNode(nil);
    result.Text[0] := AMethod.Name;
    result.Text[2] := DisplayVisibility(AMethod.Visibility);
    result.Text[1] := DisplayMethodKind(AMethod.MethodKind);
    result.DataString := MethodKey(AMethod);
    AddAttributes(AMethod, result, AObject);
  end;

{ Procedure load Methods }
var
  rMethod: TRttiMethod;
  mn: TTMSFNCTreeViewNode;
begin
  for rMethod in ARttiType.GetDeclaredMethods do
  begin
    mn := AddMethod(rMethod, AObject);
    mn.Text[3] := 'Declared';
  end;
  for rMethod in ARttiType.GetMethods do
  begin
    if MethodExists(rMethod) then
      continue
    else if rMethod.Parent.QualifiedName = TObject.QualifiedClassName then
      continue
    else
    begin
      mn := AddMethod(rMethod, AObject);
      mn.Text[3] := rMethod.Parent.QualifiedName;
    end;
  end;
end;

procedure TfrmRttiObjInfo.LoadProperties(const ARttiType: TRttiType; const AObject: TObject);
  function PropertyExists(AProperty: TRttiProperty): Boolean;
  var
    tn: TTMSFNCTreeViewNode;
    mk: string;
  begin
    result := false;
    mk := PropertyKey(AProperty);
    for tn in tvProperties.Nodes do
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
    result := tvProperties.AddNode(nil);
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

procedure TfrmRttiObjInfo.LoadRootNodes;
var
  c: TTMSFNCTreeViewColumn;
begin
  tvFields.Nodes.ClearAndResetID;
  tvFields.Columns.ClearAndResetID;
  { c 1 }
  c := tvFields.Columns.Add;
  c.Text := 'Field Name';
  c.Width := C.Width *2;
  { c 2 }
  c := tvFields.Columns.Add;
  c.Text := 'type';
  { c 3 }
  c := tvFields.Columns.Add;
  c.Text := 'Visibility';
  { c 4 }
  c := tvFields.Columns.Add;
  c.Text := 'Inherited';
  tvFields.ColumnsAppearance.StretchColumn := 1;
  // FNodeFields.Text[0] := DisplayHeaderText('Fields');
  // FNodeFields.DataString := rowid_fields_header;
  // FNodeFields.Text[1] := DisplayHeaderText('Type');
  // FNodeFields.Text[2] := DisplayHeaderText('Visibility');
  // FNodeFields.Text[3] := DisplayHeaderText('Inherited');

  tvProperties.Nodes.ClearAndResetID;
  tvProperties.Columns.ClearAndResetID;
  { c 1 }
  c := tvProperties.Columns.Add;
  c.Text := 'Property Name';
  { c 2 }
  c := tvProperties.Columns.Add;
  c.Text := 'Type';
  { c 3 }
  c := tvProperties.Columns.Add;
  c.Text := 'Visibility';
  { c 4 }
  c := tvProperties.Columns.Add;
  c.Text := 'Inherited';
  // FNodeProperties := tvProperties.AddNode(FTypeRootNode);
  // FNodeProperties.Text[0] := 'Properties';
  // FNodeProperties.DataString := rowid_properties_header;
  // FNodeProperties.Text[1] := DisplayHeaderText('Type');
  // FNodeProperties.Text[2] := DisplayHeaderText('Visibility');
  // FNodeProperties.Text[3] := DisplayHeaderText('Inherited');

  tvMethods.Nodes.ClearAndResetID;
  tvMethods.Columns.ClearAndResetID;
  { c 1 }
  c := tvMethods.Columns.Add;
  c.Text := 'Method Name';
  { c 2 }
  c := tvMethods.Columns.Add;
  c.Text := 'Type';
  { c 3 }
  c := tvMethods.Columns.Add;
  c.Text := 'Visibility';
  { c 4 }
  c := tvMethods.Columns.Add;
  c.Text := 'Inherited';
  // FNodeMethods := tvMethods.AddNode(FTypeRootNode);
  // FNodeMethods.Text[0] := DisplayHeaderText('Methods');
  // FNodeMethods.DataString := rowid_methods_header;
  // FNodeMethods.Text[1] := DisplayHeaderText('Type');
  // FNodeMethods.Text[2] := DisplayHeaderText('Visibility');
  // FNodeMethods.Text[3] := DisplayHeaderText('Inherited');

end;

function TfrmRttiObjInfo.PropertyKey(AProperty: TRttiProperty): string;
begin
  result := AProperty.Name + '|~' + AProperty.Parent.QualifiedName;
end;

procedure TfrmRttiObjInfo.SetTypeIcon(const AType: string; const ANode: TTMSFNCTreeViewNode);
  procedure SetIcon(AIconName: string);
  begin
    ANode.CollapsedIconNames[1, false] := AIconName;
    ANode.ExpandedIconNames[1, false] := AIconName;
  end;
begin
  if AType.ToLower = 'string' then
    SetIcon('string')
  else if AType.ToLower = 'boolean' then
    SetIcon('boolean')
  else
    SetIcon('unknonw')
end;

procedure TfrmRttiObjInfo.tvFieldsBeforeDrawNode(Sender: TObject; AGraphics: TTMSFNCGraphics; ARect: TRectF;
  ANode: TTMSFNCTreeViewVirtualNode; var AAllow, ADefaultDraw: Boolean);
begin

  if ANode.Node.DataString = rowid_attribute_header then
    AGraphics.Fill.Color := gcLightCyan
  else if ANode.Node.DataString = rowid_fields_header then
    AGraphics.Fill.Color := gcAquaMarine
  else if ANode.Node.DataString = rowid_methods_header then
    AGraphics.Fill.Color := gcCyan
  else if ANode.Node.DataString = rowid_properties_header then
    AGraphics.Fill.Color := gcTurquoise

end;

end.
