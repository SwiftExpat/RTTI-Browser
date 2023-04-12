unit frmRttiBrowserU;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,  frmRttiObjectInfo,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TMSFNCTypes, FMX.TMSFNCUtils, FMX.TMSFNCGraphics,
  FMX.TMSFNCGraphicsTypes, FMX.Memo.Types, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.TMSFNCToolBar,
  FMX.TMSFNCCustomControl;

type
  TfrmRttiBrowser = class(TForm)
    TMSFNCToolBar1: TTMSFNCToolBar;
    btnTypes: TTMSFNCToolBarButton;
    btnValues: TTMSFNCToolBarButton;
    Memo1: TMemo;
    procedure btnValuesClick(Sender: TObject);
  private
    FRttiObjInfo: TfrmRttiObjInfo;
  public
    { Public declarations }
  end;

var
  frmRttiBrowser: TfrmRttiBrowser;

implementation

{$R *.fmx}

procedure TfrmRttiBrowser.btnValuesClick(Sender: TObject);
begin
  if FRttiObjInfo = nil then
  begin
    FRttiObjInfo := TfrmRttiObjInfo.Create(self);
    FRttiObjInfo.Show;
  end;
end;

end.
