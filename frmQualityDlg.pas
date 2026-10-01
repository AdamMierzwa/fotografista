unit frmQualityDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  uPrefs, uTitleBar;

type
  TQualityDlg = class(TFotoForm)
    gbJPEG: TGroupBox;
    lblJPGQuality: TLabel;
    tbJPGQuality: TTrackBar;
    lblJPGValue: TLabel;

    gbWebP: TGroupBox;
    lblWebPQuality: TLabel;
    tbWebPQuality: TTrackBar;
    lblWebPValue: TLabel;

    gbTIFF: TGroupBox;
    lblTIFFCompression: TLabel;
    rbLZW: TRadioButton;
    rbNone: TRadioButton;
    rbJPEG: TRadioButton;
    lblTIFFJPEG: TLabel;
    tbTIFFJPEGQuality: TTrackBar;
    lblTIFFJPEGValue: TLabel;

    btnOK: TButton;
    btnCancel: TButton;
    procedure tbJPGQualityChange(Sender: TObject);
    procedure tbWebPQualityChange(Sender: TObject);
    procedure tbTIFFJPEGQualityChange(Sender: TObject);
    procedure rbTIFFCompressionClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    function GetTIFFCompression: Integer;
    procedure UpdateJPGDisplay;
    procedure UpdateWebPDisplay;
    procedure UpdateTIFFJPEGDisplay;
    procedure UpdateTIFFJPEGState;
  end;

function ShowQualityDlg: Boolean;

implementation

{$R *.dfm}

function ShowQualityDlg: Boolean;
var
  Dlg: TQualityDlg;
begin
  Result := False;
  Dlg := TQualityDlg.Create(Application);
  try
    Dlg.tbJPGQuality.Position := Prefs.JPGQuality;
    Dlg.tbWebPQuality.Position := Prefs.WebPQuality;
    Dlg.tbTIFFJPEGQuality.Position := Prefs.TIFFJPEGQuality;
    case Prefs.TIFFCompression of
      0: Dlg.rbLZW.Checked := True;
      1: Dlg.rbNone.Checked := True;
      2: Dlg.rbJPEG.Checked := True;
    else
      Dlg.rbLZW.Checked := True;
    end;
    Dlg.UpdateTIFFJPEGState;
    Dlg.UpdateJPGDisplay;
    Dlg.UpdateWebPDisplay;
    Dlg.UpdateTIFFJPEGDisplay;
    if Dlg.ShowModal = mrOk then
    begin
      Prefs.JPGQuality := Dlg.tbJPGQuality.Position;
      Prefs.WebPQuality := Dlg.tbWebPQuality.Position;
      Prefs.TIFFCompression := Dlg.GetTIFFCompression;
      Prefs.TIFFJPEGQuality := Dlg.tbTIFFJPEGQuality.Position;
      SavePrefs;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TQualityDlg }

function TQualityDlg.GetTIFFCompression: Integer;
begin
  if rbLZW.Checked then Result := 0
  else if rbNone.Checked then Result := 1
  else Result := 2;
end;

procedure TQualityDlg.FormCreate(Sender: TObject);
begin
  tbJPGQuality.Min := 1;
  tbJPGQuality.Max := 100;
  tbWebPQuality.Min := 1;
  tbWebPQuality.Max := 100;
  tbTIFFJPEGQuality.Min := 1;
  tbTIFFJPEGQuality.Max := 100;
end;

procedure TQualityDlg.UpdateJPGDisplay;
begin
  lblJPGValue.Caption := IntToStr(tbJPGQuality.Position);
end;

procedure TQualityDlg.UpdateWebPDisplay;
begin
  lblWebPValue.Caption := IntToStr(tbWebPQuality.Position);
end;

procedure TQualityDlg.UpdateTIFFJPEGDisplay;
begin
  lblTIFFJPEGValue.Caption := IntToStr(tbTIFFJPEGQuality.Position);
end;

procedure TQualityDlg.UpdateTIFFJPEGState;
var
  Enab: Boolean;
begin
  Enab := rbJPEG.Checked;
  lblTIFFJPEG.Enabled := Enab;
  tbTIFFJPEGQuality.Enabled := Enab;
  lblTIFFJPEGValue.Enabled := Enab;
end;

procedure TQualityDlg.tbJPGQualityChange(Sender: TObject);
begin
  UpdateJPGDisplay;
end;

procedure TQualityDlg.tbWebPQualityChange(Sender: TObject);
begin
  UpdateWebPDisplay;
end;

procedure TQualityDlg.tbTIFFJPEGQualityChange(Sender: TObject);
begin
  UpdateTIFFJPEGDisplay;
end;

procedure TQualityDlg.rbTIFFCompressionClick(Sender: TObject);
begin
  UpdateTIFFJPEGState;
end;

end.
