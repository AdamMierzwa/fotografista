unit frmQualityDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
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
    procedure LayoutGroups;
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
  LayoutGroups;
end;

// ReflowTrackBarRows patrzy tylko na bezposrednie dzieci hosta, a trzy suwaki
// tego okna siedza w TGroupBox (gbJPEG/gbWebP/gbTIFF) — w wywolaniu z
// TFotoForm.AfterConstruction Host = Self, wiec N = 0 i procedura wychodzi
// zanim cokolwiek policzy. Dlatego reflow idzie tu pojedynczo na kazda grupe
// (kazda ma plaski uklad, wiec algorytm helpera ma zastosowanie).
// Wysokosc kazdej grupy liczona jest z realnego konturu jej ostatniego
// dziecka, a Top kolejnych grup akumulatorem: Poprzedni.Top + Poprzedni.Height
// + SectionGap. Zero stalych 105/198 — przy innej czcionce i innych
// tlumaczeniach wszystko wynika z tresci.
procedure TQualityDlg.LayoutGroups;
var
  I, J, Y, Bottom, Shift: Integer;
  Groups: array[0..2] of TGroupBox;
  Radios: array[0..2] of TRadioButton;
begin
  Groups[0] := gbJPEG;
  Groups[1] := gbWebP;
  Groups[2] := gbTIFF;

  // lblTIFFCompression ma AutoSize, wiec przy wiekszej czcionce jego dolna
  // krawedz dochodzi do Top rbLZW i oba wiersze sie kleja (0 px przy 12 pt).
  // ReflowTrackBarRows tego nie rusza: druga seria (uTitleBar.pas:474) przesuwa
  // tylko kontrolki z Top > LastLabelOrigTop, a radia sa wyzej niz ostatnia
  // etykieta. Przesuwamy caly blok radia o brakujacy odstep liczony z tresci -
  // ta sama idematma co CumShift (uTitleBar.pas:479). Dolna granica grupy
  // wyznacza i tak czytnik suwaka (178-184 px vs 100-104 px radia), wiec
  // Height grupy i ClientHeight pozostaja bez zmian.
  Radios[0] := rbLZW;
  Radios[1] := rbNone;
  Radios[2] := rbJPEG;
  Shift := Max(0, lblTIFFCompression.Top + lblTIFFCompression.Height +
    RowGap - rbLZW.Top);
  for I := Low(Radios) to High(Radios) do
    Radios[I].Top := Radios[I].Top + Shift;

  for I := Low(Groups) to High(Groups) do
  begin
    ReflowTrackBarRows(Groups[I]);
    Bottom := 0;
    for J := 0 to Groups[I].ControlCount - 1 do
      Bottom := Max(Bottom, Groups[I].Controls[J].Top + Groups[I].Controls[J].Height);
    Groups[I].Height := Bottom + CtrlGap * 2;
  end;

  Y := Groups[0].Left;
  for I := Low(Groups) to High(Groups) do
  begin
    Groups[I].Top := Y;
    Inc(Y, Groups[I].Height + SectionGap);
  end;

  btnOK.Top := Y;
  btnCancel.Top := Y;
  AlignButtonsRight([btnOK, btnCancel], CtrlGap * 3);
  FitHeight(CtrlGap * 3);
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
