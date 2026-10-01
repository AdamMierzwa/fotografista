unit frmPerformanceDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  uPrefs, uI18n, uTitleBar;

type
  TPerformanceDlg = class(TFotoForm)
    rgMaxResolution: TRadioGroup;
    chkSmoothPreview: TCheckBox;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
  private
    function GetMaxResolution: string;
  end;

function ShowPerformanceDlg: Boolean;

implementation

{$R *.dfm}

procedure TPerformanceDlg.FormCreate(Sender: TObject);
begin
  rgMaxResolution.Items.Add(T('Original'));
  rgMaxResolution.Items.Add(T('4K (3840×2160)'));
  rgMaxResolution.Items.Add(T('Full HD (1920×1080)'));
  rgMaxResolution.Items.Add(T('SVGA (800×600)'));
end;

function ShowPerformanceDlg: Boolean;
var
  Dlg: TPerformanceDlg;
begin
  Result := False;
  Dlg := TPerformanceDlg.Create(Application);
  try
    if Prefs.MaxResolution = '4k' then
      Dlg.rgMaxResolution.ItemIndex := 1
    else if Prefs.MaxResolution = 'fhd' then
      Dlg.rgMaxResolution.ItemIndex := 2
    else if Prefs.MaxResolution = 'svga' then
      Dlg.rgMaxResolution.ItemIndex := 3
    else
      Dlg.rgMaxResolution.ItemIndex := 0;
    Dlg.chkSmoothPreview.Checked := Prefs.SmoothPreview;
    if Dlg.ShowModal = mrOk then
    begin
      Prefs.MaxResolution := Dlg.GetMaxResolution;
      Prefs.SmoothPreview := Dlg.chkSmoothPreview.Checked;
      SavePrefs;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TPerformanceDlg }

function TPerformanceDlg.GetMaxResolution: string;
begin
  case rgMaxResolution.ItemIndex of
    1: Result := '4k';
    2: Result := 'fhd';
    3: Result := 'svga';
  else
    Result := 'original';
  end;
end;

end.
