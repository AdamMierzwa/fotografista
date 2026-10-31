unit frmDistortDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uDistort, uPreviewFit, uI18n, uTitleBar;

type
  // Podglad i przyciski wspolne dla okien zniekształceń; lbPresets niewidoczna,
  // wyznacza lewa krawedz i szerokosc rzedow suwakow.
  TDistortDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lbPresets: TListBox;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  protected
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure ApplyPreview; virtual; abstract;
    procedure ApplyFull; virtual; abstract;
    function TrackLabelTop(Bar: TTrackBar; Lbl: TLabel): Integer;
  end;

  // Dystorsja: suwak zamiast listy wariantow (podglad i przyciski z TDistortDlg)
  TLensDistortDlg = class(TDistortDlg)
  private
    tbAmount: TTrackBar;
    lblBarrel, lblPincushion, lblValue: TLabel;
    procedure tbAmountChange(Sender: TObject);
    procedure LayoutSlider;
  protected
    procedure ApplyPreview; override;
    procedure ApplyFull; override;
  public
    procedure BuildSlider;
  end;

  // Luk: suwak Kat zamiast listy; pelne kolo zostaje Dystorsji biegunowej,
  // stad kat do 180.
  TArcDlg = class(TDistortDlg)
  private
    tbAngle: TTrackBar;
    lblAngle, lblAngleVal: TLabel;
    procedure SliderChange(Sender: TObject);
    procedure LayoutSlider;
  protected
    procedure ApplyPreview; override;
    procedure ApplyFull; override;
  public
    procedure BuildSlider;
  end;

  // Wir: suwaki Kat i Promien zamiast listy katow
  TSwirlDlg = class(TDistortDlg)
  private
    tbAngle, tbRadius: TTrackBar;
    lblAngle, lblRadius, lblAngleVal, lblRadiusVal: TLabel;
    procedure SliderChange(Sender: TObject);
    procedure LayoutSliders;
  protected
    procedure ApplyPreview; override;
    procedure ApplyFull; override;
  public
    procedure BuildSliders;
  end;

  // Biegunowa: suwaki Kat, Promien, Otwor, Obrot i kratka zamiast listy wariantow
  TPolarDlg = class(TDistortDlg)
  private
    tbAngle, tbRadius, tbHole, tbRotation: TTrackBar;
    lblAngle, lblRadius, lblHole, lblRotation: TLabel;
    lblAngleVal, lblRadiusVal, lblHoleVal, lblRotationVal: TLabel;
    chkInsideOut: TCheckBox;
    procedure ControlChange(Sender: TObject);
    procedure LayoutControls;
  protected
    procedure ApplyPreview; override;
    procedure ApplyFull; override;
  public
    procedure BuildControls;
  end;

  // Rybie oko: suwak Sila i kratka Kolo
  TFisheyeDlg = class(TDistortDlg)
  private
    tbStrength: TTrackBar;
    lblStrength, lblStrengthVal: TLabel;
    chkCircle: TCheckBox;
    procedure ControlChange(Sender: TObject);
    procedure LayoutControls;
  protected
    procedure ApplyPreview; override;
    procedure ApplyFull; override;
  public
    procedure BuildControls;
  end;

function ShowPolarDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
function ShowFisheyeDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
function ShowLensDistortDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
function ShowArcDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
function ShowSwirlDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

uses
  Winapi.CommCtrl, uMacros;

// Biegunowa: zawsze zmienia obraz. Krok makra POLAR = kat|promien|otwor|obrot|na lewa strone.
function ShowPolarDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TPolarDlg;
  Scale: Double;
  pw, ph: Integer;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TPolarDlg.CreateNew(Application);
  try
    Dlg.FormCreate(Dlg);
    Dlg.BuildControls;
    Dlg.Caption := T('Polar distortion');
    Dlg.FSourceBmp := Bitmap;

    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));

    Dlg.FOriginalPreview := TBitmap.Create;
    Dlg.FOriginalPreview.PixelFormat := pf24bit;
    Dlg.FOriginalPreview.SetSize(pw, ph);
    Dlg.FOriginalPreview.Canvas.StretchDraw(Rect(0, 0, pw, ph), Bitmap);

    Dlg.FWorkingPreview := TBitmap.Create;
    Dlg.FWorkingPreview.PixelFormat := pf24bit;
    Dlg.FWorkingPreview.SetSize(pw, ph);

    FitPreviewToDialog(Dlg, Dlg.pboxPreview, pw, ph);
    Dlg.LayoutControls;
    Dlg.FitToContent;
    Dlg.btnOK.Top := Dlg.chkInsideOut.Top + Dlg.chkInsideOut.Height + Dlg.CtrlGap * 3;
    Dlg.btnCancel.Top := Dlg.btnOK.Top;
    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);
    Dlg.FitHeight(Dlg.CtrlGap * 3);

    Dlg.ApplyPreview;

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      gMacroPending.Code := 'POLAR';
      gMacroPending.Params := IntToStr(Dlg.tbAngle.Position) + '|' + IntToStr(Dlg.tbRadius.Position) + '|' +
        IntToStr(Dlg.tbHole.Position) + '|' + IntToStr(Dlg.tbRotation.Position) + '|' +
        IntToStr(Ord(Dlg.chkInsideOut.Checked));
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.FOriginalPreview.Free;
    Dlg.FWorkingPreview.Free;
    Dlg.FOriginalPreview := nil;
    Dlg.FWorkingPreview := nil;
    Dlg.Free;
  end;
end;

// Rybie oko: Sila 0 bez kola = obraz bez zmian, OK jak Anuluj. Krok makra FISHEYE = sila|kolo.
function ShowFisheyeDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TFisheyeDlg;
  Scale: Double;
  pw, ph: Integer;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TFisheyeDlg.CreateNew(Application);
  try
    Dlg.FormCreate(Dlg);
    Dlg.BuildControls;
    Dlg.Caption := T('Fisheye');
    Dlg.FSourceBmp := Bitmap;

    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));

    Dlg.FOriginalPreview := TBitmap.Create;
    Dlg.FOriginalPreview.PixelFormat := pf24bit;
    Dlg.FOriginalPreview.SetSize(pw, ph);
    Dlg.FOriginalPreview.Canvas.StretchDraw(Rect(0, 0, pw, ph), Bitmap);

    Dlg.FWorkingPreview := TBitmap.Create;
    Dlg.FWorkingPreview.PixelFormat := pf24bit;
    Dlg.FWorkingPreview.SetSize(pw, ph);

    FitPreviewToDialog(Dlg, Dlg.pboxPreview, pw, ph);
    Dlg.LayoutControls;
    Dlg.FitToContent;
    Dlg.btnOK.Top := Dlg.chkCircle.Top + Dlg.chkCircle.Height + Dlg.CtrlGap * 3;
    Dlg.btnCancel.Top := Dlg.btnOK.Top;
    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);
    Dlg.FitHeight(Dlg.CtrlGap * 3);

    Dlg.ApplyPreview;

    if (Dlg.ShowModal = mrOk) and ((Dlg.tbStrength.Position <> 0) or Dlg.chkCircle.Checked) then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      gMacroPending.Code := 'FISHEYE';
      gMacroPending.Params := IntToStr(Dlg.tbStrength.Position) + '|' + IntToStr(Ord(Dlg.chkCircle.Checked));
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.FOriginalPreview.Free;
    Dlg.FWorkingPreview.Free;
    Dlg.FOriginalPreview := nil;
    Dlg.FWorkingPreview := nil;
    Dlg.Free;
  end;
end;

// Gorna krawedz etykiety na wysokosci toru suwaka. Polozenie toru podaje Windows,
// wedlug tego samego prostokata rysuje go styl VCL (TTrackBarStyleHook.Paint).
function TDistortDlg.TrackLabelTop(Bar: TTrackBar; Lbl: TLabel): Integer;
var
  R: TRect;
begin
  SendMessage(Bar.Handle, TBM_GETCHANNELRECT, 0, IntPtr(@R));
  Result := Bar.Top + (R.Top + R.Bottom - Lbl.Height) div 2;
end;

{ TFisheyeDlg }

procedure TFisheyeDlg.BuildControls;
begin
  lbPresets.Visible := False;

  lblStrength := TLabel.Create(Self);
  lblStrength.Parent := Self;
  lblStrength.Caption := T('Strength');
  lblStrength.StyleElements := [seClient, seBorder];

  lblStrengthVal := TLabel.Create(Self);
  lblStrengthVal.Parent := Self;
  lblStrengthVal.Caption := '0%';
  lblStrengthVal.StyleElements := [seClient, seBorder];
  lblStrengthVal.AutoSize := False;
  lblStrengthVal.Alignment := taRightJustify;

  tbStrength := TTrackBar.Create(Self);
  tbStrength.Parent := Self;
  tbStrength.Min := 0;
  tbStrength.Max := 100;
  tbStrength.Position := 0;
  tbStrength.PageSize := 10;
  tbStrength.TickStyle := tsNone;
  tbStrength.OnChange := ControlChange;

  chkCircle := TCheckBox.Create(Self);
  chkCircle.Parent := Self;
  chkCircle.Caption := T('Circle');
  chkCircle.OnClick := ControlChange;
end;

// Rzad etykieta | suwak | wartosc w szerokosci listy z TDistortDlg.
procedure TFisheyeDlg.LayoutControls;
var
  X0, RowW, ValW: Integer;
begin
  X0 := lbPresets.Left;
  RowW := lbPresets.Width;
  ValW := Canvas.TextWidth('100%');
  tbStrength.Left := X0 + lblStrength.Width + CtrlGap;
  tbStrength.Width := RowW - lblStrength.Width - ValW - 2 * CtrlGap;
  tbStrength.Height := Canvas.TextHeight('Wg') * 2;   // tor biegnie w gornej czesci kontrolki
  tbStrength.Top := pboxPreview.Top + pboxPreview.Height + SectionGap;
  lblStrength.Left := X0;
  lblStrength.Top := TrackLabelTop(tbStrength, lblStrength);
  lblStrengthVal.Left := X0 + RowW - ValW;
  lblStrengthVal.Width := ValW;
  lblStrengthVal.Top := lblStrength.Top;
  chkCircle.Left := X0;
  chkCircle.Top := tbStrength.Top + tbStrength.Height + CtrlGap;
  chkCircle.Width := RowW;
  chkCircle.Height := Canvas.TextHeight('Wg') + CtrlGap;
end;

procedure TFisheyeDlg.ControlChange(Sender: TObject);
begin
  lblStrengthVal.Caption := IntToStr(tbStrength.Position) + '%';
  ApplyPreview;
end;

procedure TFisheyeDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  ApplyFisheye(FWorkingPreview, tbStrength.Position, chkCircle.Checked);
  pboxPreview.Invalidate;
end;

procedure TFisheyeDlg.ApplyFull;
begin
  ApplyFisheye(FSourceBmp, tbStrength.Position, chkCircle.Checked);
end;

{ TPolarDlg }

procedure TPolarDlg.BuildControls;

  function NewLabel(const ACaption: string): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := Self;
    Result.Caption := ACaption;
    Result.StyleElements := [seClient, seBorder];
  end;

  function NewSlider(AMin, AMax, APos: Integer): TTrackBar;
  begin
    Result := TTrackBar.Create(Self);
    Result.Parent := Self;
    Result.Min := AMin;
    Result.Max := AMax;
    Result.Position := APos;
    Result.PageSize := 10;
    Result.TickStyle := tsNone;
    Result.OnChange := ControlChange;
  end;

begin
  lbPresets.Visible := False;
  lblAngle := NewLabel(T('Angle'));
  lblRadius := NewLabel(T('Radius'));
  lblHole := NewLabel(T('Hole'));
  lblRotation := NewLabel(T('Rotation'));
  lblAngleVal := NewLabel('180°');
  lblRadiusVal := NewLabel('100%');
  lblHoleVal := NewLabel('0%');
  lblRotationVal := NewLabel('0°');
  tbAngle := NewSlider(15, 720, 180);
  tbRadius := NewSlider(10, 200, 100);
  tbHole := NewSlider(0, 90, 0);
  tbRotation := NewSlider(-180, 180, 0);
  chkInsideOut := TCheckBox.Create(Self);
  chkInsideOut.Parent := Self;
  chkInsideOut.Caption := T('Inside out');
  chkInsideOut.OnClick := ControlChange;
end;

// Rzedy etykieta | suwak | wartosc w szerokosci listy z TDistortDlg; kolumny
// z tlumaczen i z najszerszej wartosci.
procedure TPolarDlg.LayoutControls;
var
  X0, RowW, LblW, ValW, Y: Integer;

  procedure PlaceRow(Lbl: TLabel; Bar: TTrackBar; Value: TLabel);
  begin
    Bar.Left := X0 + LblW + CtrlGap;
    Bar.Width := RowW - LblW - ValW - 2 * CtrlGap;
    Bar.Height := Canvas.TextHeight('Wg') * 2;   // tor biegnie w gornej czesci kontrolki
    Bar.Top := Y;
    Lbl.Left := X0;
    Lbl.Top := TrackLabelTop(Bar, Lbl);
    Value.AutoSize := False;
    Value.Alignment := taRightJustify;
    Value.Left := X0 + RowW - ValW;
    Value.Width := ValW;
    Value.Top := Lbl.Top;
    Y := Y + Bar.Height + CtrlGap;
  end;

begin
  X0 := lbPresets.Left;
  RowW := lbPresets.Width;
  LblW := Max(Max(lblAngle.Width, lblRadius.Width), Max(lblHole.Width, lblRotation.Width));
  ValW := Canvas.TextWidth('-180°');
  Y := pboxPreview.Top + pboxPreview.Height + SectionGap;
  PlaceRow(lblAngle, tbAngle, lblAngleVal);
  PlaceRow(lblRadius, tbRadius, lblRadiusVal);
  PlaceRow(lblHole, tbHole, lblHoleVal);
  PlaceRow(lblRotation, tbRotation, lblRotationVal);
  chkInsideOut.Left := X0;
  chkInsideOut.Top := Y + CtrlGap;
  chkInsideOut.Width := RowW;
  chkInsideOut.Height := Canvas.TextHeight('Wg') + CtrlGap;
end;

procedure TPolarDlg.ControlChange(Sender: TObject);
begin
  lblAngleVal.Caption := IntToStr(tbAngle.Position) + '°';
  lblRadiusVal.Caption := IntToStr(tbRadius.Position) + '%';
  lblHoleVal.Caption := IntToStr(tbHole.Position) + '%';
  lblRotationVal.Caption := IntToStr(tbRotation.Position) + '°';
  ApplyPreview;
end;

procedure TPolarDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  ApplyPolar(FWorkingPreview, tbAngle.Position, tbRadius.Position, tbHole.Position,
    tbRotation.Position, chkInsideOut.Checked);
  pboxPreview.Invalidate;
end;

procedure TPolarDlg.ApplyFull;
begin
  ApplyPolar(FSourceBmp, tbAngle.Position, tbRadius.Position, tbHole.Position,
    tbRotation.Position, chkInsideOut.Checked);
end;

// Dystorsja: Amount 0 = obraz bez zmian, OK jak Anuluj. Krok makra LENSDIST = sila.
function ShowLensDistortDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TLensDistortDlg;
  Scale: Double;
  pw, ph: Integer;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TLensDistortDlg.CreateNew(Application);
  try
    Dlg.FormCreate(Dlg);
    Dlg.BuildSlider;
    Dlg.Caption := T('Barrel distortion');
    Dlg.FSourceBmp := Bitmap;

    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));

    Dlg.FOriginalPreview := TBitmap.Create;
    Dlg.FOriginalPreview.PixelFormat := pf24bit;
    Dlg.FOriginalPreview.SetSize(pw, ph);
    Dlg.FOriginalPreview.Canvas.StretchDraw(Rect(0, 0, pw, ph), Bitmap);

    Dlg.FWorkingPreview := TBitmap.Create;
    Dlg.FWorkingPreview.PixelFormat := pf24bit;
    Dlg.FWorkingPreview.SetSize(pw, ph);

    FitPreviewToDialog(Dlg, Dlg.pboxPreview, pw, ph);
    Dlg.LayoutSlider;
    Dlg.FitToContent;
    Dlg.btnOK.Top := Dlg.lblValue.Top + Dlg.lblValue.Height + Dlg.CtrlGap * 3;
    Dlg.btnCancel.Top := Dlg.btnOK.Top;
    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);
    Dlg.FitHeight(Dlg.CtrlGap * 3);

    Dlg.ApplyPreview;

    if (Dlg.ShowModal = mrOk) and (Dlg.tbAmount.Position <> 0) then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      gMacroPending.Code := 'LENSDIST';
      gMacroPending.Params := IntToStr(Dlg.tbAmount.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.FOriginalPreview.Free;
    Dlg.FWorkingPreview.Free;
    Dlg.FOriginalPreview := nil;
    Dlg.FWorkingPreview := nil;
    Dlg.Free;
  end;
end;

// Luk: Kat 0 = obraz bez zmian, OK jak Anuluj. Krok makra ARC2 = kat.
function ShowArcDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TArcDlg;
  Scale: Double;
  pw, ph: Integer;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TArcDlg.CreateNew(Application);
  try
    Dlg.FormCreate(Dlg);
    Dlg.BuildSlider;
    Dlg.Caption := T('Arc distortion');
    Dlg.FSourceBmp := Bitmap;

    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));

    Dlg.FOriginalPreview := TBitmap.Create;
    Dlg.FOriginalPreview.PixelFormat := pf24bit;
    Dlg.FOriginalPreview.SetSize(pw, ph);
    Dlg.FOriginalPreview.Canvas.StretchDraw(Rect(0, 0, pw, ph), Bitmap);

    Dlg.FWorkingPreview := TBitmap.Create;
    Dlg.FWorkingPreview.PixelFormat := pf24bit;
    Dlg.FWorkingPreview.SetSize(pw, ph);

    FitPreviewToDialog(Dlg, Dlg.pboxPreview, pw, ph);
    Dlg.LayoutSlider;
    Dlg.FitToContent;
    Dlg.btnOK.Top := Dlg.tbAngle.Top + Dlg.tbAngle.Height + Dlg.CtrlGap * 3;
    Dlg.btnCancel.Top := Dlg.btnOK.Top;
    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);
    Dlg.FitHeight(Dlg.CtrlGap * 3);

    Dlg.ApplyPreview;

    if (Dlg.ShowModal = mrOk) and (Dlg.tbAngle.Position <> 0) then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      gMacroPending.Code := 'ARC2';
      gMacroPending.Params := IntToStr(Dlg.tbAngle.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.FOriginalPreview.Free;
    Dlg.FWorkingPreview.Free;
    Dlg.FOriginalPreview := nil;
    Dlg.FWorkingPreview := nil;
    Dlg.Free;
  end;
end;

// Wir: Kat 0 = obraz bez zmian, OK jak Anuluj. Krok makra SWIRL2 = kat|promien.
function ShowSwirlDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TSwirlDlg;
  Scale: Double;
  pw, ph: Integer;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TSwirlDlg.CreateNew(Application);
  try
    Dlg.FormCreate(Dlg);
    Dlg.BuildSliders;
    Dlg.Caption := T('Swirl');
    Dlg.FSourceBmp := Bitmap;

    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));

    Dlg.FOriginalPreview := TBitmap.Create;
    Dlg.FOriginalPreview.PixelFormat := pf24bit;
    Dlg.FOriginalPreview.SetSize(pw, ph);
    Dlg.FOriginalPreview.Canvas.StretchDraw(Rect(0, 0, pw, ph), Bitmap);

    Dlg.FWorkingPreview := TBitmap.Create;
    Dlg.FWorkingPreview.PixelFormat := pf24bit;
    Dlg.FWorkingPreview.SetSize(pw, ph);

    FitPreviewToDialog(Dlg, Dlg.pboxPreview, pw, ph);
    Dlg.LayoutSliders;
    Dlg.FitToContent;
    Dlg.btnOK.Top := Dlg.tbRadius.Top + Dlg.tbRadius.Height + Dlg.CtrlGap * 3;
    Dlg.btnCancel.Top := Dlg.btnOK.Top;
    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);
    Dlg.FitHeight(Dlg.CtrlGap * 3);

    Dlg.ApplyPreview;

    if (Dlg.ShowModal = mrOk) and (Dlg.tbAngle.Position <> 0) then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      gMacroPending.Code := 'SWIRL2';
      gMacroPending.Params := IntToStr(Dlg.tbAngle.Position) + '|' + IntToStr(Dlg.tbRadius.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.FOriginalPreview.Free;
    Dlg.FWorkingPreview.Free;
    Dlg.FOriginalPreview := nil;
    Dlg.FWorkingPreview := nil;
    Dlg.Free;
  end;
end;

{ TSwirlDlg }

procedure TSwirlDlg.BuildSliders;

  function NewLabel(const ACaption: string): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := Self;
    Result.Caption := ACaption;
    Result.StyleElements := [seClient, seBorder];
  end;

  function NewSlider(AMin, AMax, APos: Integer): TTrackBar;
  begin
    Result := TTrackBar.Create(Self);
    Result.Parent := Self;
    Result.Min := AMin;
    Result.Max := AMax;
    Result.Position := APos;
    Result.PageSize := 10;
    Result.TickStyle := tsNone;
    Result.OnChange := SliderChange;
  end;

begin
  lbPresets.Visible := False;
  lblAngle := NewLabel(T('Angle'));
  lblRadius := NewLabel(T('Radius'));
  lblAngleVal := NewLabel('0°');
  lblRadiusVal := NewLabel('100%');
  tbAngle := NewSlider(-360, 360, 0);
  tbRadius := NewSlider(10, 300, 100);
end;

// Rzedy etykieta | suwak | wartosc w szerokosci listy z TDistortDlg; kolumny
// z tlumaczen i z najszerszej wartosci.
procedure TSwirlDlg.LayoutSliders;
var
  X0, RowW, LblW, ValW: Integer;

  procedure PlaceRow(Lbl: TLabel; Bar: TTrackBar; Value: TLabel; ATop: Integer);
  begin
    Bar.Left := X0 + LblW + CtrlGap;
    Bar.Width := RowW - LblW - ValW - 2 * CtrlGap;
    Bar.Height := Canvas.TextHeight('Wg') * 2;   // tor biegnie w gornej czesci kontrolki
    Bar.Top := ATop;
    Lbl.Left := X0;
    Lbl.Top := TrackLabelTop(Bar, Lbl);
    Value.AutoSize := False;
    Value.Alignment := taRightJustify;
    Value.Left := X0 + RowW - ValW;
    Value.Width := ValW;
    Value.Top := Lbl.Top;
  end;

begin
  X0 := lbPresets.Left;
  RowW := lbPresets.Width;
  LblW := Max(lblAngle.Width, lblRadius.Width);
  ValW := Max(Canvas.TextWidth('-360°'), Canvas.TextWidth('300%'));
  PlaceRow(lblAngle, tbAngle, lblAngleVal, pboxPreview.Top + pboxPreview.Height + SectionGap);
  PlaceRow(lblRadius, tbRadius, lblRadiusVal, tbAngle.Top + tbAngle.Height + CtrlGap);
end;

procedure TSwirlDlg.SliderChange(Sender: TObject);
begin
  lblAngleVal.Caption := IntToStr(tbAngle.Position) + '°';
  lblRadiusVal.Caption := IntToStr(tbRadius.Position) + '%';
  ApplyPreview;
end;

procedure TSwirlDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  ApplySwirlEx(FWorkingPreview, tbAngle.Position, tbRadius.Position);
  pboxPreview.Invalidate;
end;

procedure TSwirlDlg.ApplyFull;
begin
  ApplySwirlEx(FSourceBmp, tbAngle.Position, tbRadius.Position);
end;

{ TArcDlg }

procedure TArcDlg.BuildSlider;
begin
  lbPresets.Visible := False;

  lblAngle := TLabel.Create(Self);
  lblAngle.Parent := Self;
  lblAngle.Caption := T('Angle');
  lblAngle.StyleElements := [seClient, seBorder];

  lblAngleVal := TLabel.Create(Self);
  lblAngleVal.Parent := Self;
  lblAngleVal.Caption := '0°';
  lblAngleVal.StyleElements := [seClient, seBorder];
  lblAngleVal.AutoSize := False;
  lblAngleVal.Alignment := taRightJustify;

  tbAngle := TTrackBar.Create(Self);
  tbAngle.Parent := Self;
  tbAngle.Min := -180;
  tbAngle.Max := 180;
  tbAngle.Position := 0;
  tbAngle.PageSize := 10;
  tbAngle.TickStyle := tsNone;
  tbAngle.OnChange := SliderChange;
end;

// Rzad etykieta | suwak | wartosc w szerokosci listy z TDistortDlg.
procedure TArcDlg.LayoutSlider;
var
  X0, RowW, ValW: Integer;
begin
  X0 := lbPresets.Left;
  RowW := lbPresets.Width;
  ValW := Canvas.TextWidth('-180°');
  tbAngle.Left := X0 + lblAngle.Width + CtrlGap;
  tbAngle.Width := RowW - lblAngle.Width - ValW - 2 * CtrlGap;
  tbAngle.Height := Canvas.TextHeight('Wg') * 2;   // tor biegnie w gornej czesci kontrolki
  tbAngle.Top := pboxPreview.Top + pboxPreview.Height + SectionGap;
  lblAngle.Left := X0;
  lblAngle.Top := TrackLabelTop(tbAngle, lblAngle);
  lblAngleVal.Left := X0 + RowW - ValW;
  lblAngleVal.Width := ValW;
  lblAngleVal.Top := lblAngle.Top;
end;

procedure TArcDlg.SliderChange(Sender: TObject);
begin
  lblAngleVal.Caption := IntToStr(tbAngle.Position) + '°';
  ApplyPreview;
end;

procedure TArcDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  ApplyArcFit(FWorkingPreview, tbAngle.Position);
  pboxPreview.Invalidate;
end;

procedure TArcDlg.ApplyFull;
begin
  ApplyArcFit(FSourceBmp, tbAngle.Position);
end;

{ TLensDistortDlg }

procedure TLensDistortDlg.BuildSlider;

  function NewLabel(const ACaption: string): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := Self;
    Result.Caption := ACaption;
    Result.StyleElements := [seClient, seBorder];
  end;

begin
  lbPresets.Visible := False;
  lblBarrel := NewLabel(T('Barrel'));
  lblPincushion := NewLabel(T('Pincushion'));
  lblValue := NewLabel('0');
  lblValue.AutoSize := False;
  lblValue.Alignment := taCenter;

  tbAmount := TTrackBar.Create(Self);
  tbAmount.Parent := Self;
  tbAmount.Min := -100;
  tbAmount.Max := 100;
  tbAmount.Position := 0;
  tbAmount.PageSize := 10;
  tbAmount.TickStyle := tsNone;
  tbAmount.OnChange := tbAmountChange;
end;

// Szerokosc rzedu = szerokosc listy wariantow z TDistortDlg; konce z tlumaczen.
procedure TLensDistortDlg.LayoutSlider;
var
  X0, RowW, Y: Integer;
begin
  X0 := lbPresets.Left;
  RowW := lbPresets.Width;
  Y := pboxPreview.Top + pboxPreview.Height + SectionGap;
  lblBarrel.Left := X0;
  lblPincushion.Left := X0 + RowW - lblPincushion.Width;
  tbAmount.Left := lblBarrel.Left + lblBarrel.Width + CtrlGap;
  tbAmount.Width := lblPincushion.Left - CtrlGap - tbAmount.Left;
  tbAmount.Height := Canvas.TextHeight('Wg') * 2;   // tor biegnie w gornej czesci kontrolki
  tbAmount.Top := Y;
  lblBarrel.Top := TrackLabelTop(tbAmount, lblBarrel);
  lblPincushion.Top := lblBarrel.Top;
  lblValue.Left := tbAmount.Left;
  lblValue.Width := tbAmount.Width;
  lblValue.Height := Canvas.TextHeight('Wg') + CtrlGap;
  lblValue.Top := tbAmount.Top + tbAmount.Height + CtrlGap;
end;

procedure TLensDistortDlg.tbAmountChange(Sender: TObject);
begin
  lblValue.Caption := IntToStr(tbAmount.Position);
  ApplyPreview;
end;

procedure TLensDistortDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  ApplyLensDistort(FWorkingPreview, tbAmount.Position);
  pboxPreview.Invalidate;
end;

procedure TLensDistortDlg.ApplyFull;
begin
  ApplyLensDistort(FSourceBmp, tbAmount.Position);
end;

{ TDistortDlg }

procedure TDistortDlg.FormCreate(Sender: TObject);
begin
  Font.Assign(Application.DefaultFont);
  BorderStyle := bsDialog;
  Position := poOwnerFormCenter;

  pboxPreview := TPaintBox.Create(Self);
  pboxPreview.Parent := Self;
  pboxPreview.Left := 15;
  pboxPreview.Top := 15;
  pboxPreview.Width := 400;
  pboxPreview.Height := 300;
  pboxPreview.OnPaint := pboxPreviewPaint;

  lbPresets := TListBox.Create(Self);
  lbPresets.Parent := Self;
  lbPresets.Left := 15;
  lbPresets.Top := 330;
  lbPresets.Width := 400;
  lbPresets.Height := 110;

  btnOK := TButton.Create(Self);
  btnOK.Parent := Self;
  btnOK.Left := 240;
  btnOK.Top := 452;
  btnOK.Width := 85;
  btnOK.Height := 25;
  btnOK.Caption := T('OK');
  btnOK.Default := True;
  btnOK.ModalResult := mrOk;

  btnCancel := TButton.Create(Self);
  btnCancel.Parent := Self;
  btnCancel.Left := 331;
  btnCancel.Top := 452;
  btnCancel.Width := 85;
  btnCancel.Height := 25;
  btnCancel.Caption := T('Cancel');
  btnCancel.Cancel := True;
  btnCancel.ModalResult := mrCancel;

  FitToContent;
end;

procedure TDistortDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TDistortDlg.pboxPreviewPaint(Sender: TObject);
var
  SrcW, SrcH, NewW, NewH, TargetW, TargetH: Integer;
  Scale: Double;
  DestRect: TRect;
begin
  with pboxPreview.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxPreview.ClientRect);
    if Assigned(FWorkingPreview) then
    begin
      SrcW := FWorkingPreview.Width;
      SrcH := FWorkingPreview.Height;
      if (SrcW = 0) or (SrcH = 0) then Exit;
      TargetW := pboxPreview.ClientWidth;
      TargetH := pboxPreview.ClientHeight;
      Scale := Min(TargetW / SrcW, TargetH / SrcH);
      NewW := Round(SrcW * Scale);
      NewH := Round(SrcH * Scale);
      DestRect := Rect(
        (TargetW - NewW) div 2, (TargetH - NewH) div 2,
        (TargetW - NewW) div 2 + NewW, (TargetH - NewH) div 2 + NewH);
      StretchDraw(DestRect, FWorkingPreview);
    end;
  end;
end;

end.
