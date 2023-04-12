program RttiBrowserFMX;

uses
  System.StartUpCopy,
  FMX.Forms,
  frmRttiBrowserU in 'frmRttiBrowserU.pas' {frmRttiBrowser};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmRttiBrowser, frmRttiBrowser);
  Application.Run;
end.
