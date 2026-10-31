unit frmReliefDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TReliefDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    pboxZoom: TPaintBox;
    lblMaterial: TLabel;
    cbMaterial: TComboBox;
    lblDepth: TLabel;
    tbDepth: TTrackBar;
    lblDepthValue: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxZoomPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure cbMaterialChange(Sender: TObject);
    procedure tbDepthChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  public
    procedure RefitButtons; override;
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    // Podglad 100% (2026-10-23): fragment wyniku liczony na pelnej
    // rozdzielczosci - miniatura 400 px pokazuje relief w innej skali.
    FZoomBmp: TBitmap;
    FZoomX, FZoomY, FZoomW, FZoomH: Integer;
    FNavW, FNavH: Integer;
    procedure ApplyPreview;
    procedure ApplyFull;
    procedure LayoutPreviews;
    procedure FitMaterialList;
    function CursorRect: TRect;
    procedure RebuildZoom(X, Y: Integer);
    procedure RenderFragment;
  end;

function ShowReliefDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoRelief(Bitmap: TBitmap; DepthPct, Material: Integer);
// Nazwa materialu (pozycja listy Material w oknie); '' poza zakresem.
function ReliefMaterialName(Index: Integer): string;

implementation

uses
  uMacros, uI18n;

{$R *.dfm}

const
  // pozycje listy Material (jedno zrodlo dla okna i opisu kroku makra) -
  // klucze EN dla T() (i18n ID 601-605, tlumaczenia we wszystkich 9 jezykach).
  // Do 2026-10-22 nazwy byly wpisane w kod po polsku, bez T(), wiec w kazdym
  // jezyku byly po polsku, choc klucze juz istnialy.
  cReliefMaterials: array[0..4] of string = (
    'Plaster / white stone',
    'White marble',
    'Gray stone',
    'Bronze / medal',
    'Sandstone');

function ReliefMaterialName(Index: Integer): string;
begin
  if (Index < Low(cReliefMaterials)) or (Index > High(cReliefMaterials)) then
    Exit('');
  Result := T(cReliefMaterials[Index]);
end;

type
  PRGBTriple = ^TRGBTriple;
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;
  PByteArray = ^TByteArray;
  TByteArray = array[0..MaxInt div SizeOf(Byte) - 1] of Byte;

function ClampByte(V: Integer): Byte; inline;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := Byte(V);
end;

function ClampTone(V: Double): Double; inline;
begin
  if V < 0.18 then Result := 0.18
  else if V > 1.35 then Result := 1.35
  else Result := V;
end;

// Rdzen DoRelief. OffX/OffY = polozenie Bitmap w pelnym obrazie (podglad 100%
// liczy wycinek): ziarno materialu zalezy od wspolrzednych piksela, wiec
// wycinek dostaje te same wspolrzedne co w calym obrazie. Przy 0, 0 = DoRelief.
procedure ReliefCore(Bitmap: TBitmap; DepthPct, Material, OffX, OffY: Integer);
// Płaskorzeźba materiałowa — algorytm wg Hollywood (p_RenderRelief).
// Luminancja -> smooth 3x3 -> wektor normalny z gradientu,
// oświetlenie lx=-0.55, ly=-0.65, lz=0.52 (znormalizowane),
// light = 0.58 + dot*0.52, plane = (smooth-128)/255*0.18,
// ziarno zależne od materiału, ton w zakresie 0.18..1.35,
// kolor bazowy materiału * ton.
var
  W, H, X, Y, XX, YY, Sum, Cnt, S: Integer;
  Depth, lx, ly, lz, lLen, sx, sy, nz, len, dot, light, plane, grain, tone: Double;
  Br, Bg, Bb: Integer;
  HeightArr, SmoothArr: array of Integer;
  Lines: array of PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  if Bitmap.PixelFormat <> pf24bit then
    Bitmap.PixelFormat := pf24bit;

  if Material < 0 then Material := 0;
  if Material > 4 then Material := 4;
  DepthPct := Max(1, Min(100, DepthPct));

  Br := 224; Bg := 222; Bb := 214;
  case Material of
    1: begin Br := 238; Bg := 238; Bb := 232; end;
    2: begin Br := 158; Bg := 154; Bb := 145; end;
    3: begin Br := 174; Bg := 118; Bb := 58; end;
    4: begin Br := 203; Bg := 174; Bb := 124; end;
  end;

  Depth := 1.0 + DepthPct / 100.0 * 7.0;
  lx := -0.55; ly := -0.65; lz := 0.52;
  lLen := Sqrt(lx * lx + ly * ly + lz * lz);
  lx := lx / lLen; ly := ly / lLen; lz := lz / lLen;

  SetLength(HeightArr, W * H);
  SetLength(SmoothArr, W * H);
  SetLength(Lines, H);
  for Y := 0 to H - 1 do
    Lines[Y] := Bitmap.ScanLine[Y];

  // Luminancja (299/587/114)
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
      HeightArr[Y * W + X] :=
        (299 * Lines[Y][X].R + 587 * Lines[Y][X].G + 114 * Lines[Y][X].B) div 1000;

  // Smooth 3x3 (średnia, brzegi pomijane)
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      Sum := 0; Cnt := 0;
      for YY := Y - 1 to Y + 1 do
        if (YY >= 0) and (YY < H) then
          for XX := X - 1 to X + 1 do
            if (XX >= 0) and (XX < W) then
            begin
              Sum := Sum + HeightArr[YY * W + XX];
              Inc(Cnt);
            end;
      SmoothArr[Y * W + X] := Sum div Cnt;
    end;

  // Normalne + oświetlenie + materiał
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      S := SmoothArr[Y * W + X];
      sx := (SmoothArr[Y * W + Max(0, X - 1)] - SmoothArr[Y * W + Min(W - 1, X + 1)]) * Depth;
      sy := (SmoothArr[Max(0, Y - 1) * W + X] - SmoothArr[Min(H - 1, Y + 1) * W + X]) * Depth;
      nz := 96.0;
      len := Sqrt(sx * sx + sy * sy + nz * nz);
      dot := (sx * lx + sy * ly + nz * lz) / len;
      if dot < -1.0 then dot := -1.0;
      if dot > 1.0 then dot := 1.0;
      light := 0.58 + dot * 0.52;
      plane := (S - 128) / 255.0 * 0.18;
      grain := 0.0;
      if Material = 1 then
      begin
        if (((X + OffX) * 13 + (Y + OffY) * 7 + S) mod 41) < 2 then grain := -0.10;
      end
      else if (Material = 2) or (Material = 4) then
        grain := ((((X + OffX) * 17 + (Y + OffY) * 31) mod 23) - 11) / 255.0;

      tone := ClampTone(light + plane + grain);
      Lines[Y][X].R := ClampByte(Round(Br * tone));
      Lines[Y][X].G := ClampByte(Round(Bg * tone));
      Lines[Y][X].B := ClampByte(Round(Bb * tone));
    end;
end;

procedure DoRelief(Bitmap: TBitmap; DepthPct: Integer; Material: Integer);
begin
  ReliefCore(Bitmap, DepthPct, Material, 0, 0);
end;

function ShowReliefDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TReliefDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := nil;
  try
    Dlg := TReliefDlg.Create(Application);
    Dlg.FSourceBmp := Bitmap;

    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));

    Scaled := TBitmap.Create;
    try
      Scaled.PixelFormat := pf24bit;
      Scaled.SetSize(pw, ph);
      Scaled.Canvas.StretchDraw(Rect(0, 0, pw, ph), Bitmap);

      Dlg.FOriginalPreview := TBitmap.Create;
      Dlg.FOriginalPreview.PixelFormat := pf24bit;
      Dlg.FOriginalPreview.SetSize(pw, ph);
      Dlg.FOriginalPreview.Canvas.Draw(0, 0, Scaled);

      Dlg.FWorkingPreview := TBitmap.Create;
      Dlg.FWorkingPreview.PixelFormat := pf24bit;
      Dlg.FWorkingPreview.SetSize(pw, ph);
    finally
      Scaled.Free;
    end;

    // Podglad 100%: wymiary jak nawigator, fragment 1:1 pikseli wyniku.
    Dlg.FNavW := pw;
    Dlg.FNavH := ph;
    Dlg.FZoomW := Min(pw, Bitmap.Width);
    Dlg.FZoomH := Min(ph, Bitmap.Height);
    Dlg.FZoomBmp := TBitmap.Create;
    Dlg.FZoomBmp.PixelFormat := pf24bit;
    Dlg.FZoomBmp.SetSize(Dlg.FZoomW, Dlg.FZoomH);
    Dlg.FZoomX := (Bitmap.Width - Dlg.FZoomW) div 2;
    Dlg.FZoomY := (Bitmap.Height - Dlg.FZoomH) div 2;
    Dlg.LayoutPreviews;

    Dlg.ApplyPreview;

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      gMacroPending.Code := 'RELIEF';
      gMacroPending.Params := IntToStr(Dlg.tbDepth.Position) + '|'
        + IntToStr(Dlg.cbMaterial.ItemIndex);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TReliefDlg }

procedure TReliefDlg.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  for I := Low(cReliefMaterials) to High(cReliefMaterials) do
    cbMaterial.Items.Add(ReliefMaterialName(I));
  cbMaterial.ItemIndex := 0;
  tbDepth.Min := 1;
  tbDepth.Max := 100;
  tbDepth.Position := 35;
  lblDepthValue.Caption := IntToStr(tbDepth.Position);
end;

procedure TReliefDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
end;

// Uklad jak w oknie Rastra punktowego: nawigator i podglad 100% obok siebie,
// pod nimi Material i Glebokosc na szerokosc pary podgladow; rozmiar okna
// z zawartosci (FitToContent).
procedure TReliefDlg.LayoutPreviews;
var
  Bottom, PairW: Integer;
begin
  pboxPreview.SetBounds(CtrlGap, TitleBarGap + CtrlGap, FNavW, FNavH);
  pboxZoom.SetBounds(pboxPreview.Left + FNavW + CtrlGap * 2, pboxPreview.Top,
    FZoomW, FZoomH);
  Bottom := pboxPreview.Top + Max(FNavH, FZoomH);
  cbMaterial.Top := Bottom + RowGap * 2;
  lblMaterial.Top := cbMaterial.Top + (cbMaterial.Height - lblMaterial.Height) div 2;
  lblDepth.Top := cbMaterial.Top + cbMaterial.Height + RowGap * 2;
  tbDepth.Top := lblDepth.Top + lblDepth.Height + RowGap;
  lblDepthValue.Top := tbDepth.Top + tbDepth.Height + RowGap;
  btnOK.Top := lblDepthValue.Top + lblDepthValue.Height + RowGap * 3;
  btnCancel.Top := btnOK.Top;

  ButtonsToLeft([btnOK, btnCancel], CtrlGap * 3);
  FitToContent(CtrlGap * 2, CtrlGap * 3);

  PairW := FNavW + CtrlGap * 2 + FZoomW;
  pboxPreview.Left := Max(CtrlGap, (ClientWidth - PairW) div 2);
  pboxZoom.Left := pboxPreview.Left + FNavW + CtrlGap * 2;

  lblMaterial.Left := pboxPreview.Left;
  FitMaterialList;
  lblDepth.Left := pboxPreview.Left;
  tbDepth.Left := pboxPreview.Left;
  tbDepth.Width := PairW;
  lblDepthValue.Left := pboxPreview.Left;
  lblDepthValue.Width := PairW;

  AlignButtonsRight([btnOK, btnCancel], CtrlGap * 3);
end;

// Lista Material zaraz za napisem, szerokosc z najdluzszej nazwy materialu we
// wszystkich 9 jezykach (TAllLanguages) + strzalka - okno nie zmienia sie po
// przelaczeniu jezyka. Wolane z ukladu i z RefitButtons (po tlumaczeniu okna
// i zmianie czcionki - wtedy napis „Material:” ma juz docelowa szerokosc).
procedure TReliefDlg.FitMaterialList;
var
  I, MaxW: Integer;
  S: string;
begin
  Canvas.Font := cbMaterial.Font;
  MaxW := 0;
  for I := Low(cReliefMaterials) to High(cReliefMaterials) do
    for S in TAllLanguages(cReliefMaterials[I]) do
      MaxW := Max(MaxW, Canvas.TextWidth(S));
  cbMaterial.Left := lblMaterial.Left + lblMaterial.Width + CtrlGap;
  cbMaterial.Width := MaxW + GetSystemMetrics(SM_CXVSCROLL) + CtrlGap * 2;
end;

procedure TReliefDlg.RefitButtons;
begin
  inherited;
  FitMaterialList;
end;

// Pozycja ramki podgladu 100% w pikselach nawigatora.
function TReliefDlg.CursorRect: TRect;
var
  Sx, Sy: Double;
begin
  Sx := FNavW / FSourceBmp.Width;
  Sy := FNavH / FSourceBmp.Height;
  Result.Left := Max(0, Round(FZoomX * Sx));
  Result.Top := Max(0, Round(FZoomY * Sy));
  Result.Right := Min(FNavW, Round((FZoomX + FZoomW) * Sx));
  Result.Bottom := Min(FNavH, Round((FZoomY + FZoomH) * Sy));
end;

procedure TReliefDlg.RebuildZoom(X, Y: Integer);
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  X := EnsureRange(X, 0, Max(0, FSourceBmp.Width - FZoomW));
  Y := EnsureRange(Y, 0, Max(0, FSourceBmp.Height - FZoomH));
  if (FZoomX = X) and (FZoomY = Y) then Exit;
  FZoomX := X;
  FZoomY := Y;
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

// Fragment 1:1 wyniku: wycinek pelnego obrazu z marginesem 2 px (wygladzanie
// 3x3 i gradient siegaja po 1 px kazdy), ReliefCore z polozeniem wycinka,
// potem wnetrze bez marginesu do FZoomBmp. Wynik = ten sam fragment po OK.
procedure TReliefDlg.RenderFragment;
const
  M = 2;
var
  R: TRect;
  Crop: TBitmap;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  R := Rect(Max(0, FZoomX - M), Max(0, FZoomY - M),
    Min(FSourceBmp.Width, FZoomX + FZoomW + M),
    Min(FSourceBmp.Height, FZoomY + FZoomH + M));
  Crop := TBitmap.Create;
  try
    Crop.PixelFormat := pf24bit;
    Crop.SetSize(R.Right - R.Left, R.Bottom - R.Top);
    Crop.Canvas.CopyRect(Rect(0, 0, Crop.Width, Crop.Height), FSourceBmp.Canvas, R);
    ReliefCore(Crop, tbDepth.Position, cbMaterial.ItemIndex, R.Left, R.Top);
    FZoomBmp.Canvas.CopyRect(Rect(0, 0, FZoomW, FZoomH), Crop.Canvas,
      Rect(FZoomX - R.Left, FZoomY - R.Top, FZoomX - R.Left + FZoomW,
        FZoomY - R.Top + FZoomH));
  finally
    Crop.Free;
  end;
end;

procedure TReliefDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if (FSourceBmp = nil) or (FNavW = 0) or (FNavH = 0) then Exit;
  RebuildZoom(Round(X * FSourceBmp.Width / FNavW) - FZoomW div 2,
    Round(Y * FSourceBmp.Height / FNavH) - FZoomH div 2);
end;

procedure TReliefDlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

procedure TReliefDlg.cbMaterialChange(Sender: TObject);
begin
  ApplyPreview;
end;

procedure TReliefDlg.tbDepthChange(Sender: TObject);
begin
  lblDepthValue.Caption := IntToStr(tbDepth.Position);
  ApplyPreview;
end;

procedure TReliefDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoRelief(FWorkingPreview, tbDepth.Position, cbMaterial.ItemIndex);
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TReliefDlg.ApplyFull;
begin
  DoRelief(FSourceBmp, tbDepth.Position, cbMaterial.ItemIndex);
end;

// Nawigator (pboxPreview ma wymiary miniatury) z ramka fragmentu podgladu 100%.
procedure TReliefDlg.pboxPreviewPaint(Sender: TObject);
var
  R: TRect;
begin
  with pboxPreview.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxPreview.ClientRect);
    if Assigned(FWorkingPreview) then
      Draw(0, 0, FWorkingPreview);
    if (FSourceBmp <> nil) and (FZoomW > 0) and (FZoomH > 0) then
    begin
      R := CursorRect;
      Brush.Style := bsClear;
      Pen.Style := psSolid;
      Pen.Color := clBlack;
      Pen.Width := 1;
      Rectangle(R);
      Pen.Color := clWhite;
      FrameRect(Rect(R.Left - 1, R.Top - 1, R.Right + 1, R.Bottom + 1));
      Brush.Style := bsSolid;
    end;
  end;
end;

end.
