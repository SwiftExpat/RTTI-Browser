unit frmRttiTypeInfoU;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Rtti, Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TMSFNCTypes, FMX.TMSFNCUtils, FMX.TMSFNCGraphics,
  FMX.TMSFNCGraphicsTypes, FMX.TMSFNCToolBar, FMX.TMSFNCStatusBar, FMX.TMSFNCCustomControl, FMX.TMSFNCTreeViewBase,
  FMX.TMSFNCTreeViewData, FMX.TMSFNCCustomTreeView, FMX.TMSFNCTreeView, FMX.Layouts, FMX.TreeView, FMX.TMSFNCSplitter;

type

  TSERTTKRttiItem = class
  public
    Categories: TDictionary<string, TTMSFNCTreeViewNode>;
    TreeNode: TTMSFNCTreeViewNode;
  end;

  TSERTTKRepoRtti = class
  public
    Packages: TDictionary<TRTTIPackage, string>;
    Units: TDictionary<String, string>;
    ObjectMap: TDictionary<TObject, TTMSFNCTreeViewNode>;
    RootCategories: TDictionary<string, TTMSFNCTreeViewNode>;
    constructor Create;
    destructor Destroy; override;
  end;

  TfrmRTTIBrowser = class(TForm)
    tv: TTMSFNCTreeView;
    TMSFNCStatusBar1: TTMSFNCStatusBar;
    TMSFNCToolBar1: TTMSFNCToolBar;
    TMSFNCToolBarButton1: TTMSFNCToolBarButton;
    Timer1: TTimer;
    TMSFNCSplitter1: TTMSFNCSplitter;
    tvDetail: TTMSFNCTreeView;
    procedure FormCreate(Sender: TObject);
    procedure TMSFNCToolBarButton1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tvNodeClick(Sender: TObject; ANode: TTMSFNCTreeViewVirtualNode);
  private
    FObject: TObject;
    FContext: TRttiContext;
    FMap: TDictionary<TObject, TTMSFNCTreeViewNode>;
    FRootCategories: TDictionary<string, TTMSFNCTreeViewNode>;
    FRepoRtti: TSERTTKRepoRtti;
  public
    procedure LoadObject;
    procedure LoadPackages;
  end;

var
  frmRTTIBrowser: TfrmRTTIBrowser;

implementation

{$R *.fmx}

uses FMX.SEFNC.Logger;

procedure TfrmRTTIBrowser.FormCreate(Sender: TObject);
begin
  FObject := Timer1;
  FMap := TDictionary<TObject, TTMSFNCTreeViewNode>.Create;
  FRootCategories := TDictionary<string, TTMSFNCTreeViewNode>.Create;
  FRepoRtti := TSERTTKRepoRtti.Create;
end;

procedure TfrmRTTIBrowser.FormDestroy(Sender: TObject);
begin
  FMap.Free;
  FRootCategories.Free;
  FRepoRtti.Free;
end;

procedure TfrmRTTIBrowser.LoadObject;
  function UnitName(AQualifiedName: string): string;
  begin
    if AQualifiedName.Contains('<') then
      result := AQualifiedName.Substring(0, AQualifiedName.IndexOf('<')).Substring(0, AQualifiedName.LastIndexOf('.'))
    else
      result := AQualifiedName.Substring(0, AQualifiedName.LastIndexOf('.'));
  end;

function AddType(Typ: TRttiType): TTMSFNCTreeViewNode; forward;

  function GetRootCategoryNode(const Category: string): TTMSFNCTreeViewNode;
  begin
    if FRootCategories.TryGetValue(Category, result) = false then
    begin
      result := tv.AddNode(nil);
      result.Text[0] := Category;
      result.DataString := Category;
      FRootCategories.Add(Category, result);
    end;
  end;

  function GetCategoryNode(Parent: TTMSFNCTreeViewNode; const Category: string): TTMSFNCTreeViewNode;
  begin
    if Parent = nil then
      result := GetRootCategoryNode(Category)
    else
    begin
      result := Parent.getFirstChild;
      Logger.Debug(Parent.Text[0] + ' ChildCount = ' + Parent.GetChildCount.ToString, self);
      if result = nil then
        Logger.Warn('Failed to get first child for ' + Parent.Text[0])
      else
        Logger.Info('first child for ' + Parent.Text[0] + ' is ' + result.Text[0]);
      while result <> nil do
      begin
        Logger.Info('Evaluate sibling ' + result.Text[0]);
        if (result.DataObject = nil) and (result.DataString = Category) then
          Exit;
        result := result.getNextSibling;
      end;

      result := tv.AddNode(Parent);
      result.Text[0] := Category;
      result.DataString := Category;
      result.DataObject := nil;
      Logger.Info('Added Child category node ' + result.Text[0] + ' to ' + Parent.Text[0])
    end;
  end;

// Assumes parent is already in tree
  function AddObjectNode(Parent, Obj: TObject; const Category: string): TTMSFNCTreeViewNode;
  var
    parentNode: TTMSFNCTreeViewNode;
  begin
    if FMap.TryGetValue(Obj, result) then
      Exit;

    if Parent = nil then
      parentNode := nil
    else if not FMap.TryGetValue(Parent, parentNode) then
      parentNode := nil;

    if Category <> '' then
      if parentNode = nil then // valid for TObject
        parentNode := GetRootCategoryNode(Category)
      else
        parentNode := GetCategoryNode(parentNode, Category);
    Logger.Warn('Adding child node for ' + Obj.ToString + ' to parent ' + parentNode.Text[0]);
    result := tv.AddNode(parentNode);
    result.Text[0] := Obj.ToString;
    FMap.Add(Obj, result);
    result.DataObject := Obj;
    result.DataString := Category;
  end;

  function AddRttiNode(Parent, Obj: TRttiObject; const Category: string): TTMSFNCTreeViewNode;
  var
    attr: TCustomAttribute;
  begin
    result := AddObjectNode(Parent, Obj, Category);
    for attr in Obj.GetAttributes do
      AddObjectNode(Obj, attr, 'Attributes');
  end;

// Adds parent to tree if it's not there already
  function AddTypeNode(Parent: TRttiType; Typ: TRttiType; const Category: string = ''): TTMSFNCTreeViewNode;
  var
    parentNode: TTMSFNCTreeViewNode;
  begin
    if FMap.TryGetValue(Typ, result) then
      Exit;

    if Parent = nil then
      result := AddRttiNode(nil, Typ, Category);

    if (Parent <> nil) and (not FMap.ContainsKey(Parent)) then
      AddType(Parent);

    if Parent <> nil then
      result := AddRttiNode(Parent, Typ, '') // 'Descendants')
    else
      result := AddRttiNode(nil, Typ, Category);
    result.Text[2] := UnitName(Typ.QualifiedName);
    // result.Text[1] := Typ.AsInstance.DeclaringUnitName;
  end;

  function AddProperty(Prop: TRttiProperty): TTMSFNCTreeViewNode;
  begin
    result := AddRttiNode(Prop.Parent, Prop, 'Properties');
  end;

  function AddMethod(Meth: TRttiMethod): TTMSFNCTreeViewNode;
  var
    param: TRttiParameter;
  begin
    result := AddRttiNode(Meth.Parent, Meth, 'Methods');
    for param in Meth.GetParameters do
      AddRttiNode(Meth, param, '');
  end;

  function AddField(Field: TRttiField): TTMSFNCTreeViewNode;
  begin
    result := AddRttiNode(Field.Parent, Field, 'Fields');
  end;

  function AddInstance(Inst: TRttiInstanceType): TTMSFNCTreeViewNode;
  var
    Meth: TRttiMethod;
    Field: TRttiField;
    Prop: TRttiProperty;
  begin
    result := AddTypeNode(Inst.BaseType, Inst, 'Classes');
    // for Meth in Inst.GetMethods do
    // AddMethod(Meth);
    // for Field in Inst.GetFields do
    // AddField(Field);
    // for Prop in Inst.GetProperties do
    // AddProperty(Prop);
  end;

  function AddRecord(Rec: TRttiRecordType): TTMSFNCTreeViewNode;
  var
    Field: TRttiField;
  begin
    result := AddTypeNode(nil, Rec, 'Records');
    for Field in Rec.GetFields do
      AddField(Field);
  end;

  function AddOrdinal(Ord: TRttiOrdinalType): TTMSFNCTreeViewNode;
  begin
    result := AddTypeNode(nil, Ord, 'Ordinals');
  end;

  function AddInteger(Ord: TRttiOrdinalType): TTMSFNCTreeViewNode;
  begin
    result := AddTypeNode(nil, Ord, 'Integers');
  end;

  function AddType(Typ: TRttiType): TTMSFNCTreeViewNode;
  begin
    case Typ.TypeKind of
      tkClass:
        result := AddInstance(Typ.AsInstance);
      tkRecord:
        result := AddRecord(Typ.AsRecord);
      tkSet:
        result := AddTypeNode(nil, Typ.AsSet, 'Sets');
      tkInteger:
        result := AddInteger(Typ.AsOrdinal);
      tkString:
        result := AddTypeNode(nil, Typ, 'Strings');
      tkFloat:
        result := AddTypeNode(nil, Typ, 'Floats');
      tkEnumeration:
        result := AddTypeNode(nil, Typ, 'Enums');
      tkInterface:
        result := AddTypeNode(nil, Typ, 'Interfaces');
      tkDynArray:
        result := AddTypeNode(nil, Typ, 'Dyn Array');
      tkMRecord:
        result := AddTypeNode(nil, Typ, 'MRecord');
      tkChar:
        result := AddTypeNode(nil, Typ, 'Char');
      tkMethod:
        result := AddTypeNode(nil, Typ, 'method');
      tkWChar:
        result := AddTypeNode(nil, Typ, 'WChar');
      tkLString:
        result := AddTypeNode(nil, Typ, 'LString');
      tkWString:
        result := AddTypeNode(nil, Typ, 'WString');
      tkVariant:
        result := AddTypeNode(nil, Typ, 'Variant');
      tkArray:
        result := AddTypeNode(nil, Typ, 'Array');
      tkInt64:
        result := AddTypeNode(nil, Typ, 'Int64');
      tkUString:
        result := AddTypeNode(nil, Typ, 'Ustring');
      tkClassRef:
        result := AddTypeNode(nil, Typ, 'ClassRef');
      tkPointer:
        result := AddTypeNode(nil, Typ, 'Pointer');
      tkProcedure:
        result := AddTypeNode(nil, Typ, 'Procedure');
    else
      if Typ.IsOrdinal then
        result := AddOrdinal(Typ.AsOrdinal)
      else
        result := AddTypeNode(nil, Typ, 'Other');
    end;
  end;

var
  i: integer;
  // Obj: TObject;
  // Prop: TRttiProperty;
  // val: TValue;
  // ex: Exception;
  t: TRttiType;
  Types: TArray<TRttiType>;
begin
  i := 0;
  tv.Nodes.ClearAndResetID;
  tv.BeginUpdate;
  // tv.Nodes.BeginUpdate;
  try
    FContext.Create;
    FContext.KeepContext;
    try
      Types := FContext.GetTypes;
      Logger.Trace(Length(Types).ToString, self);
      for t in Types do
      begin
        AddType(t);
        inc(i);
        // if i > 50 then
        // Exit;
      end
    except
      on E: Exception do
    end;
    tv.Nodes.Sort(0, false)
  finally
    // tv.Nodes.EndUpdate;
    tv.EndUpdate;
    FContext.Free;
  end;
end;

procedure TfrmRTTIBrowser.LoadPackages;
var
  i: integer;
  // Obj: TObject;
  // Prop: TRttiProperty;
  // val: TValue;
  // ex: Exception;
  p: TRTTIPackage;
  // t: TRttiType;
  pn: TTMSFNCTreeViewNode;
begin
  i := 0;
  tv.Nodes.ClearAndResetID;
  tv.BeginUpdate;
  tv.Nodes.BeginUpdate;
  try
    FContext.Create;
    try
      for p in FContext.GetPackages do
      begin
        pn := tv.AddNode(nil);
        pn.Text[0] := p.Name;
        inc(i);
        if i > 50 then
          Exit;
      end;
      // AddType(t);
    except
      on E: Exception do
    end;
  finally
    tv.Nodes.EndUpdate;
    tv.EndUpdate;
    FContext.Free;
  end;
end;

procedure TfrmRTTIBrowser.TMSFNCToolBarButton1Click(Sender: TObject);
begin
  Logger.Info('Object Load start', self);
  // LoadPackages;
  LoadObject;
  Logger.Info('Object Load End', self);
end;

procedure TfrmRTTIBrowser.tvNodeClick(Sender: TObject; ANode: TTMSFNCTreeViewVirtualNode);
var
  //ro: TRttiObject;
  ri: TRttiInstanceType;
  tn, dn: TTMSFNCTreeViewNode;
begin
  if ANode.Node.DataObject = nil then
    Exit
  else
  begin
    if ANode.Node.DataObject is TRttiInstanceType then
      ri := TRttiInstanceType(ANode.Node.DataObject)
//    else if ANode.Node.DataObject is TRttiObject then
//      ro := TRttiObject(ANode.Node.DataObject)
    else
      Exit;

    tn := tv.AddNode(ANode.Node);
    tn.Text[0] := 'clicked';
    tn.DataObject := ri;
    dn := tvDetail.AddNode(nil);
    // if ro is TRttiInstanceType then
    dn.Text[0] := ri.QualifiedName;
    // else
    // dn.Text[0] := ro.ToString;
    dn.DataObject := ri;

  end;
end;

{ TSERTTKRepoRtti }

constructor TSERTTKRepoRtti.Create;
begin
  Packages := TDictionary<TRTTIPackage, string>.Create;
  Units := TDictionary<String, string>.Create;
  ObjectMap := TDictionary<TObject, TTMSFNCTreeViewNode>.Create;
  RootCategories := TDictionary<string, TTMSFNCTreeViewNode>.Create;
end;

destructor TSERTTKRepoRtti.Destroy;
begin
  Packages.Free;
  Units.Free;
  ObjectMap.Free;
  RootCategories.Free;
  inherited;
end;

end.
