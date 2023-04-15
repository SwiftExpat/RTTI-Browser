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
    navpnlRttiPanel3: TTMSFNCNavigationPanelContainer;
    tvAttributes: TTMSFNCTreeView;
    procedure btnObjInfoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    procedure tvFieldsBeforeDrawNode(Sender: TObject; AGraphics: TTMSFNCGraphics; ARect: TRectF;
      ANode: TTMSFNCTreeViewVirtualNode; var AAllow, ADefaultDraw: Boolean);
  strict private
    FNodeProperties, FNodeMethods, FNodeFields, FNodeAttributes: TTMSFNCTreeViewNode;
    function DisplayHeaderText(const AText: string): string; inline;
    function PropertyKey(AProperty: TRttiProperty): string; inline;
    function FieldKey(const AField: TRttiField): string; inline;
    function MethodKey(const AMethod: TRttiMethod): string; inline;
    procedure LoadAttributes(const ARttiType: TRttiType; const AObject: TObject; const ARootNode: TTMSFNCTreeViewNode);
    procedure LoadFields(const ARttiType: TRttiType; const AObject: TObject; const ARootNode: TTMSFNCTreeViewNode);
    procedure LoadMethods(const ARttiType: TRttiType; const AObject: TObject; const ARootNode: TTMSFNCTreeViewNode);
    procedure LoadProperties(const ARttiType: TRttiType; const AObject: TObject; const ARootNode: TTMSFNCTreeViewNode);
    procedure AddAttributes(const ARttiObject: TRttiObject; const ANode: TTMSFNCTreeViewNode; const AObject: TObject);
    function AddAttributeNode(ACustomAttribute: TCustomAttribute; const AObject: TObject;
      const ARootNode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
    function AddFieldNode(const AField: TRttiField; const AObject: TObject; const ARootNode: TTMSFNCTreeViewNode)
      : TTMSFNCTreeViewNode;
    function AddMethodNode(AMethod: TRttiMethod; const AObject: TObject; const ARootNode: TTMSFNCTreeViewNode)
      : TTMSFNCTreeViewNode;
    procedure AddPropertyDetail(const AProperty: TRttiProperty; const APropertyNode: TTMSFNCTreeViewNode;
      const AObject: TObject);
    function AddPropertyNode(AProperty: TRttiProperty; const AObject: TObject; const ARootNode: TTMSFNCTreeViewNode)
      : TTMSFNCTreeViewNode;
    procedure LoadRootNodes;

    { header rows }
    function AddLabelAttributes(const ANode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
    function AddLabelProperties(const ANode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
    function AddLabelMethods(const ANode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
    function AddLabelFields(const ANode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
    procedure SetTypeIcon(const AType: string; const ANode: TTMSFNCTreeViewNode);
    procedure SetItemIcon(const AType: string; const ANode: TTMSFNCTreeViewNode);
    function FindIconName(const ALookupName: string): string;
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

uses RttiTestModelU, System.Character;

const
  rowid_attributes_header = 'AttribHeader';
  rowid_properties_header = 'PropertyHeader';
  rowid_methods_header = 'MethodsHeader';
  rowid_fields_header = 'FieldsHeader';
  ico_unknown = 'icounknown';
  ico_attribute = 'attribute';
  lbl_procedure = 'procedure';
  lbl_function = 'function';
  lbl_constructor = 'constructor';
  lbl_destructor = 'destructor';
  lbl_class_procedure = 'class procedure';
  lbl_class_function = 'class function';
  lbl_class_constructor = 'class constructor';
  lbl_class_destructor = 'class destructor';
  lbl_operator_overload = 'operator overload';
  lbl_safe_procedure = 'safe procedure';
  lbl_safe_function = 'safe function';

procedure TfrmRttiObjInfo.FormCreate(Sender: TObject);
begin
  FContext.Create;
  FContext.KeepContext;
  FBitmaps := TObjectList<TTMSFNCBitmap>.Create(true);
  CreateIcons;
  btnObjInfoClick(self);
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

  rType := FContext.GetType(c.ClassType);
  LoadFields(rType, c, FNodeFields);
  FNodeFields.Text[0] := 'Fields Info - RttiTestModel';
  FNodeFields.Expand(false);
  LoadProperties(rType, c, FNodeProperties);
  FNodeProperties.Text[0] := 'Property Info - RttiTestModel';
  FNodeProperties.Expand(false);
  LoadMethods(rType, c, FNodeMethods);
  FNodeMethods.Text[0] := 'Method Info - RttiTestModel';
  FNodeMethods.Expand(false);
  LoadAttributes(rType, c, FNodeAttributes);
  FNodeAttributes.Text[0] := 'Attribute Info - RttiTestModel';
  FNodeAttributes.Expand(false);

end;

function TfrmRttiObjInfo.AddAttributeNode(ACustomAttribute: TCustomAttribute; const AObject: TObject;
  const ARootNode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
var
  AType: TRttiType;
begin
  result := ARootNode.TreeView.AddNode(ARootNode);
  result.Text[0] := ACustomAttribute.ClassName;
  result.Text[3] := ACustomAttribute.QualifiedClassName;
  SetItemIcon(ico_attribute, result);
  AType := FContext.GetType(ACustomAttribute.ClassType);
  LoadProperties(AType, ACustomAttribute, result);
end;

procedure TfrmRttiObjInfo.AddAttributes(const ARttiObject: TRttiObject; const ANode: TTMSFNCTreeViewNode;
  const AObject: TObject);
  procedure LoadAttrProps(const ARttiType: TRttiType; const ANode: TTMSFNCTreeViewNode; const AObject: TObject);
  var
    LProperty: TRttiProperty;
    ln: TTMSFNCTreeViewNode;
    props: TArray<TRttiProperty>;
  begin
    ln := nil;
    props := ARttiType.GetProperties;
    if Length(props) > 0 then
    begin
      if ln = nil then
        ln := AddLabelProperties(ANode);
      for LProperty in props do
        AddPropertyNode(LProperty, AObject, ln);
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

  an := AddLabelAttributes(ANode);
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

procedure TfrmRttiObjInfo.AddPropertyDetail(const AProperty: TRttiProperty; const APropertyNode: TTMSFNCTreeViewNode;
  const AObject: TObject);
begin
  SetItemIcon(AProperty.PropertyType.Name, APropertyNode);
  if AProperty.IsReadable then
  begin
    APropertyNode.Text[2] := 'R /';
    try
      APropertyNode.Text[1] := AProperty.GetValue(AObject).ToString;
    except
      on E: Exception do
        APropertyNode.Text[1] := 'Ex ' + E.Message
    end;
  end
  else
    APropertyNode.Text[2] := '<R>';

  if AProperty.IsWritable then
    APropertyNode.Text[2] := APropertyNode.Text[2] + ' W'
  else
    APropertyNode.Text[2] := APropertyNode.Text[2] + '<W>'

end;

function TfrmRttiObjInfo.AddPropertyNode(AProperty: TRttiProperty; const AObject: TObject;
  const ARootNode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
begin
  result := ARootNode.TreeView.AddNode(ARootNode);
  result.Text[0] := AProperty.Name;
  result.Text[3] := DisplayVisibility(AProperty.Visibility);
  result.DataString := PropertyKey(AProperty);
  AddPropertyDetail(AProperty, result, AObject);
  AddAttributes(AProperty, result, AObject);
end;

procedure TfrmRttiObjInfo.LoadAttributes(const ARttiType: TRttiType; const AObject: TObject;
  const ARootNode: TTMSFNCTreeViewNode);
var
  an: TTMSFNCTreeViewNode;
  a: TCustomAttribute;
  attribs: TArray<TCustomAttribute>;
begin
  attribs := ARttiType.GetAttributes;
  if Length(attribs) = 0 then
  begin
    // navPnlRtti.Panels  create the panels, so that i can make invisible
    an := ARootNode.TreeView.AddNode(ARootNode);
    an.Text[0] := 'No attributes found';
    exit;
  end;

  for a in attribs do
    AddAttributeNode(a, AObject, ARootNode);
end;

function TfrmRttiObjInfo.AddFieldNode(const AField: TRttiField; const AObject: TObject;
  const ARootNode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
    var
    ft: TRttiType;
  begin
    result := ARootNode.TreeView.AddNode(ARootNode);
    result.Text[0] := AField.Name;
    result.Text[2] := DisplayVisibility(AField.Visibility);
    result.DataString := FieldKey(AField);
    ft := AField.FieldType;
    result.Text[1] := AField.GetValue(AObject).ToString;
    SetTypeIcon(ft.ToString, result);

    result.Text[2] := DisplayVisibility(AField.Visibility);
    AddAttributes(AField, result, AObject);
    SetItemIcon('field', result);
end;

procedure TfrmRttiObjInfo.LoadFields(const ARttiType: TRttiType; const AObject: TObject;
  const ARootNode: TTMSFNCTreeViewNode);
  function FieldExists(const AField: TRttiField): Boolean;
  var
    tn: TTMSFNCTreeViewNode;
    mk: string;
  begin
    result := false;
    mk := FieldKey(AField);
    for tn in ARootNode.Nodes do
    begin
      result := tn.DataString = mk;
      if result then
        exit(true);
    end;
  end;
var
  rField: TRttiField;
  fn, ln, rn: TTMSFNCTreeViewNode;
begin

  ln := ARootNode.GetParent;
  if ln = nil then
    rn := ARootNode
  else
  begin
    ln := AddLabelProperties(ARootNode);
    rn := ln;
  end;
  for rField in ARttiType.GetDeclaredFields do
  begin
    fn := AddFieldNode(rField, AObject, rn);
    fn.Text[3] := 'Declared';
  end;
  for rField in ARttiType.GetFields do
  begin
    if FieldExists(rField) then
      continue
    else
    begin
      fn := AddFieldNode(rField, AObject, rn);
      fn.Text[3] := rField.Parent.QualifiedName;
    end;
  end;
end;

function TfrmRttiObjInfo.AddMethodNode(AMethod: TRttiMethod; const AObject: TObject;
  const ARootNode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
begin
  result := ARootNode.TreeView.AddNode(ARootNode);
  result.Text[0] := AMethod.Name;
  result.Text[2] := DisplayVisibility(AMethod.Visibility);
  result.Text[1] := DisplayMethodKind(AMethod.MethodKind);
  SetTypeIcon(DisplayMethodKind(AMethod.MethodKind), result);
  result.DataString := MethodKey(AMethod);
  AddAttributes(AMethod, result, AObject);
end;

procedure TfrmRttiObjInfo.LoadMethods(const ARttiType: TRttiType; const AObject: TObject;
  const ARootNode: TTMSFNCTreeViewNode);
  function MethodExists(AMethod: TRttiMethod): Boolean;
  var
    tn: TTMSFNCTreeViewNode;
    mk: string;
  begin
    result := false;
    mk := MethodKey(AMethod);
    for tn in ARootNode.Nodes do
    begin
      result := tn.DataString = mk;
      if result then
        exit(true);
    end;
  end;

var
  rMethod: TRttiMethod;
  mn, ln, rn: TTMSFNCTreeViewNode;
begin
  ln := ARootNode.GetParent;
  if ln = nil then
    rn := ARootNode
  else
  begin
    ln := AddLabelMethods(ARootNode);
    rn := ln;
  end;

  for rMethod in ARttiType.GetDeclaredMethods do
  begin
    mn := AddMethodNode(rMethod, AObject, rn);
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
      mn := AddMethodNode(rMethod, AObject, rn);
      mn.Text[3] := rMethod.Parent.QualifiedName;
    end;
  end;
end;

procedure TfrmRttiObjInfo.LoadProperties(const ARttiType: TRttiType; const AObject: TObject;
  const ARootNode: TTMSFNCTreeViewNode);
  function PropertyExists(AProperty: TRttiProperty): Boolean;
  var
    tn: TTMSFNCTreeViewNode;
    mk: string;
  begin
    result := false;
    mk := PropertyKey(AProperty);
    for tn in ARootNode.Nodes do
    begin
      result := tn.DataString = mk;
      if result then
        exit(true);
    end;
  end;

var
  rProperty: TRttiProperty;
  pn, ln, rn: TTMSFNCTreeViewNode;
begin
  ln := ARootNode.GetParent;
  if ln = nil then
    rn := ARootNode
  else
  begin
    ln := AddLabelProperties(ARootNode);
    rn := ln;
  end;

  for rProperty in ARttiType.GetDeclaredProperties do
  begin
    pn := AddPropertyNode(rProperty, AObject, rn);
    pn.Text[2] := 'Declared';
  end;

  for rProperty in ARttiType.GetProperties do
  begin
    if PropertyExists(rProperty) then
      continue
    else
    begin
      pn := AddPropertyNode(rProperty, AObject, rn);
      pn.Text[2] := rProperty.Parent.QualifiedName;
    end;
  end;

end;

function TfrmRttiObjInfo.MethodKey(const AMethod: TRttiMethod): string;
begin
  result := AMethod.Name + '|~' + AMethod.Parent.QualifiedName;
end;

function TfrmRttiObjInfo.FieldKey(const AField: TRttiField): string;
begin
  result := AField.Name + '|~' + AField.Parent.QualifiedName;
end;

function TfrmRttiObjInfo.PropertyKey(AProperty: TRttiProperty): string;
begin
  result := AProperty.Name + '|~' + AProperty.Parent.QualifiedName;
end;

function TfrmRttiObjInfo.DisplayHeaderText(const AText: string): string;
begin
  result := '<p align="center"><b>' + AText + '</b></p>';
end;

function TfrmRttiObjInfo.DisplayMethodKind(AMethodKind: TMethodKind): string;
begin
  case AMethodKind of
    mkProcedure:
      result := lbl_procedure;
    mkFunction:
      result := lbl_function;
    mkConstructor:
      result := lbl_constructor;
    mkDestructor:
      result := lbl_destructor;
    mkClassProcedure:
      result := lbl_class_procedure;
    mkClassFunction:
      result := lbl_class_function;
    mkClassConstructor:
      result := lbl_class_constructor;
    mkClassDestructor:
      result := lbl_class_destructor;
    mkOperatorOverload:
      result := lbl_operator_overload;
    mkSafeProcedure:
      result := lbl_safe_procedure;
    mkSafeFunction:
      result := lbl_safe_function;
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

procedure TfrmRttiObjInfo.LoadRootNodes;
var
  c1, c2, c3, c4: TTMSFNCTreeViewColumn;
begin
  tvFields.Nodes.ClearAndResetID;
  tvFields.Columns.ClearAndResetID;

  c1 := tvFields.Columns.Add;
  c1.Text := 'Field Name';
  c1.Width := c1.Width * 2;
  c2 := tvFields.Columns.Add;
  c2.Text := 'Field Value';
  c3 := tvFields.Columns.Add;
  c3.Text := 'Visibility';
  c4 := tvFields.Columns.Add;
  c4.Text := 'Inherited';
  tvFields.ColumnsAppearance.StretchColumn := 1;
  FNodeFields := tvFields.AddNode(nil);
  FNodeFields.Extended := true;

  tvProperties.Nodes.ClearAndResetID;
  tvProperties.Columns.ClearAndResetID;
  c1 := tvProperties.Columns.Add;
  c1.Text := 'Property Name';
  c1.Width := c1.Width * 2;
  c2 := tvProperties.Columns.Add;
  c2.Text := 'Type';
  c3 := tvProperties.Columns.Add;
  c3.Text := 'Visibility';
  c4 := tvProperties.Columns.Add;
  c4.Text := 'Inherited';
  tvProperties.ColumnsAppearance.StretchColumn := 1;
  FNodeProperties := tvProperties.AddNode(nil);
  FNodeProperties.Extended := true;

  tvMethods.Nodes.ClearAndResetID;
  tvMethods.Columns.ClearAndResetID;
  c1 := tvMethods.Columns.Add;
  c1.Text := 'Method Name';
  c1.Width := c1.Width * 2;
  c2 := tvMethods.Columns.Add;
  c2.Text := 'Type';
  c3 := tvMethods.Columns.Add;
  c3.Text := 'Visibility';
  c4 := tvMethods.Columns.Add;
  c4.Text := 'Inherited';
  tvMethods.ColumnsAppearance.StretchColumn := 1;
  FNodeMethods := tvMethods.AddNode(nil);
  FNodeMethods.Extended := true;

  tvAttributes.Nodes.ClearAndResetID;

  FNodeAttributes := tvAttributes.AddNode(nil);
  FNodeAttributes.Extended := true;

end;

function TfrmRttiObjInfo.AddLabelAttributes(const ANode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
begin
  result := ANode.TreeView.AddNode(ANode);
  result.Text[0] := DisplayHeaderText('Attribute Class');
  result.Text[3] := DisplayHeaderText('Inherited');
  result.DataString := rowid_attributes_header;
end;

function TfrmRttiObjInfo.AddLabelFields(const ANode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
begin
  result := ANode.TreeView.AddNode(ANode);
  result.Text[0] := DisplayHeaderText('Property Name');
  result.Text[1] := DisplayHeaderText('Value');
  result.Text[2] := DisplayHeaderText('Read / Write');
  result.DataString := rowid_fields_header;
end;

function TfrmRttiObjInfo.AddLabelMethods(const ANode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
begin
  result := ANode.TreeView.AddNode(ANode);
  result.Text[0] := DisplayHeaderText('Method Name');
  result.Text[1] := DisplayHeaderText('Type');
  result.Text[2] := DisplayHeaderText('Visibility');
  result.Text[2] := DisplayHeaderText('Inherited');
  result.DataString := rowid_methods_header;
end;

function TfrmRttiObjInfo.AddLabelProperties(const ANode: TTMSFNCTreeViewNode): TTMSFNCTreeViewNode;
begin
  result := ANode.TreeView.AddNode(ANode);
  result.Text[0] := DisplayHeaderText('Property Name');
  result.Text[1] := DisplayHeaderText('Value');
  result.Text[2] := DisplayHeaderText('Visibility');
  result.Text[2] := DisplayHeaderText('Inherited');
  result.DataString := rowid_properties_header;
end;

{$REGION 'Icon Functions'}

procedure TfrmRttiObjInfo.CreateIcons;
  function IconWidth(AText: string): integer;
  var
    j: integer;
  begin
    result := 0;
    for j := 0 to AText.Length - 1 do
      if AText.Chars[j].IsUpper then
        result := result + 18
      else
        result := result + 14
  end;
  procedure AddIcon(ALetter: string; AItemName: string);
  var
    r: TRectF;
    bmi: TTMSFNCBitmapItem;
    bmp: TTMSFNCBitmap;
    w: integer;
  begin
    bmi := bmc.Items.Add;
    w := IconWidth(ALetter);
    bmp := TTMSFNCBitmap.Create(w, 20);
    FBitmaps.Add(bmp);
    bmi.Name := AItemName;
    r := TRectF.Create(0.5, 0.5, (w - 0.5), 19.5);
    bmp.Canvas.BeginScene;
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
  AddIcon('A', ico_attribute);
  AddIcon('?', ico_unknown);
  AddIcon('Proc', lbl_procedure);
  AddIcon('Func', lbl_function);
  AddIcon('Ctor', lbl_constructor);
  AddIcon('Dtor', lbl_destructor);
  AddIcon('C Proc', lbl_class_procedure);
  AddIcon('C Func', lbl_class_function);
  AddIcon('CC', lbl_class_constructor);
  AddIcon('CD', lbl_class_destructor);
  AddIcon('OO', lbl_operator_overload);
  AddIcon('SP', lbl_safe_procedure);
  AddIcon('SF', lbl_safe_function);

end;

function TfrmRttiObjInfo.FindIconName(const ALookupName: string): string;
var
  bmi: TTMSFNCBitmapItem;
  i: integer;
  n: string;
begin
  n := ALookupName.ToLower;
  for i := 0 to bmc.ItemCount - 1 do
  begin
    bmi := bmc.Items[i];
    if bmi.Name = n then
      exit(bmi.Name)
  end;
  result := ico_unknown;
end;

procedure TfrmRttiObjInfo.SetItemIcon(const AType: string; const ANode: TTMSFNCTreeViewNode);
  procedure SetIcon(AIconName: string);
  begin
    ANode.CollapsedIconNames[0, false] := AIconName;
    ANode.ExpandedIconNames[0, false] := AIconName;
  end;

begin
  SetIcon(FindIconName(AType))
end;

procedure TfrmRttiObjInfo.SetTypeIcon(const AType: string; const ANode: TTMSFNCTreeViewNode);
  procedure SetIcon(AIconName: string);
  begin
    ANode.CollapsedIconNames[1, false] := AIconName;
    ANode.ExpandedIconNames[1, false] := AIconName;
  end;

begin
  SetIcon(FindIconName(AType))
end;
{$ENDREGION}

procedure TfrmRttiObjInfo.tvFieldsBeforeDrawNode(Sender: TObject; AGraphics: TTMSFNCGraphics; ARect: TRectF;
  ANode: TTMSFNCTreeViewVirtualNode; var AAllow, ADefaultDraw: Boolean);
begin

  if ANode.Node.DataString = rowid_attributes_header then
    AGraphics.Fill.Color := gcLightCyan
  else if ANode.Node.DataString = rowid_fields_header then
    AGraphics.Fill.Color := gcAquaMarine
  else if ANode.Node.DataString = rowid_methods_header then
    AGraphics.Fill.Color := gcCyan
  else if ANode.Node.DataString = rowid_properties_header then
    AGraphics.Fill.Color := gcTurquoise

end;

end.
