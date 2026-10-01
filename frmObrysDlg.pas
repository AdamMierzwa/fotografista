unit frmObrysDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TObrysDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    pboxZoom: TPaintBox;
    lblLabel: TLabel;
    tbAmount: TTrackBar;
    lblValue: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pboxZoomPaint(Sender: TObject);
    procedure tbAmountChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FEpsilon: Double;
    FNavW, FNavH: Integer;
    FZoomW, FZoomH: Integer;
    FZoomX, FZoomY: Integer;
    FZoomBmp: TBitmap;
    FEffBmp: TBitmap;
    FEffX, FEffY, FEffW, FEffH: Integer;
    FEffValid: Boolean;
    FZoomTimer: TTimer;
    FZoomDirty: Boolean;
    procedure ApplyPreview;
    procedure ApplyFull;
    procedure RenderFragment;
    procedure RebuildZoom(X, Y: Integer);
    procedure ZoomTimerTick(Sender: TObject);
    function CursorRect: TRect;
    procedure InvalidateNavRect(aRect: TRect);
  end;

function ShowObrysDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

uses
  uConvolution;

{$R *.dfm}

type
  PRGBTriple = ^TRGBTriple;
  TRGBTriple = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..MaxInt div SizeOf(TRGBTriple) - 1] of TRGBTriple;

const
  // Parametry XDoG (Winnemöller, Kyprianidis, Olsen — CAG 2012):
  //   S = (1+p)·G1 − p·G2 (Eq.7), miękki próg tanh (Eq.5),
  //   ε adaptacyjne = średnia luminancji obrazu; p = Pct·0.6 (suwak 1..100).
  OBRYS_R1      = 2;     // σ1: drobne rozmycie gaussowskie (krawędzie)
  OBRYS_R2      = 8;     // σ2: szerokie rozmycie (kontekst), k = σ2/σ1 = 4
  OBRYS_PHI     = 0.04;  // ϕ: stromość miękkiego progu tanh (skala 0..255)
  OBRYS_P_MIN   = 15;    // Pct=1   -> p=15  (dolna granica, poniżej zanika kreska)
  OBRYS_P_MAX   = 85;    // Pct=100 -> p=45  (wartość robocza, do doprecyzowania testem)

procedure ApplyObrysEffect(Src, Dst: TBitmap; P, Epsilon: Double);
// Pipeline XDoG (Winnemöller, Kyprianidis, Olsen — CAG 2012):
//   S = (1+p)·G1 − p·G2            — wyostrzony DoG (Eq.7)
//   out = 255                       dla S ≥ ε     — papier
//   out = 255·(1 + tanh(ϕ·(S−ε)))   dla S < ε     — obrys (Eq.5)
//   ε adaptacyjne = średnia luminancji obrazu; p z suwaka (Pct·0.6).
//   Epsilon jest parametrem (liczonym raz ze źródła przez MeanLuma), a nie
//   średnią tego konkretnego bitmapu — dzięki temu wycinek 1:1 używa tej samej
//   ε co pełny obraz.
//   W płaskich obszarach G1≈G2≈L, więc S≈L — XDoG łączy cieniowanie
//   tonalne i ostre linie krawędzi w jednym przebiegu.
var
  W, H, X, Y, L, S: Integer;
  TmpBmp, BlurFine, BlurWide: TBitmap;
  SrcLines, TmpLines, BlurFineLines, BlurWideLines, DstLines: array of PRGBTripleArray;
begin
  W := Src.Width;
  H := Src.Height;
  if (W = 0) or (H = 0) then Exit;

  // Wymuś pf24bit dla Src — ScanLine czytany jako 3 bajty/piksel (PRGBTripleArray).
  // Bez tego inne PixelFormat (pf32bit/pf8bit) dałyby błędny stride i skorumpowany
  // wynik na pełnym obrazie (FSourceBmp przychodzi z zewnątrz, patrz DoObrys).
  if Src.PixelFormat <> pf24bit then
    Src.PixelFormat := pf24bit;

  Dst.PixelFormat := pf24bit;
  Dst.SetSize(W, H);

  TmpBmp := TBitmap.Create;
  BlurFine := TBitmap.Create;
  BlurWide := TBitmap.Create;
  try
    TmpBmp.PixelFormat := pf24bit;
    TmpBmp.SetSize(W, H);
    BlurFine.PixelFormat := pf24bit;
    BlurFine.SetSize(W, H);
    BlurWide.PixelFormat := pf24bit;
    BlurWide.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(TmpLines, H);
    SetLength(BlurFineLines, H);
    SetLength(BlurWideLines, H);
    SetLength(DstLines, H);

    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Src.ScanLine[Y];
      TmpLines[Y] := TmpBmp.ScanLine[Y];
    end;

    // Luminancja L (R=G=B=L) do wspólnego TmpBmp
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        L := (299 * SrcLines[Y][X].R + 587 * SrcLines[Y][X].G + 114 * SrcLines[Y][X].B) div 1000;
        TmpLines[Y][X].R := L;
        TmpLines[Y][X].G := L;
        TmpLines[Y][X].B := L;
      end;

    // Dwa rozmycia gaussowskie -> G1 (σ1) i G2 (σ2); XDoG = (1+p)·G1 − p·G2
    BoxBlur(TmpBmp, BlurFine, OBRYS_R1);
    BoxBlur(TmpBmp, BlurWide, OBRYS_R2);

    for Y := 0 to H - 1 do
    begin
      BlurFineLines[Y] := BlurFine.ScanLine[Y];
      BlurWideLines[Y] := BlurWide.ScanLine[Y];
      DstLines[Y] := Dst.ScanLine[Y];
    end;

    // XDoG: miękki próg tanh (Eq.5) na wyostrzonym DoG (Eq.7)
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        S := Round((1 + P) * BlurFineLines[Y][X].R - P * BlurWideLines[Y][X].R);
        if S >= Epsilon then
          L := 255
        else
          L := Round(255 * (1 + Tanh(OBRYS_PHI * (S - Epsilon))));
        if L < 0 then L := 0;
        if L > 255 then L := 255;
        DstLines[Y][X].R := Byte(L);
        DstLines[Y][X].G := Byte(L);
        DstLines[Y][X].B := Byte(L);
      end;
  finally
    TmpBmp.Free;
    BlurFine.Free;
    BlurWide.Free;
  end;
end;

// Średnia luminancja obrazu — adaptacyjny próg ε XDoG. Liczona raz ze źródła
// (pełny obraz), a nie z wycinka 1:1, żeby podgląd zgadzał się z ApplyFull.
function MeanLuma(Bmp: TBitmap): Double;
var
  W, H, X, Y: Integer;
  Sum: Int64;
  Lines: array of PRGBTripleArray;
begin
  Result := 128;
  if (Bmp = nil) or (Bmp.Width = 0) or (Bmp.Height = 0) then Exit;
  if Bmp.PixelFormat <> pf24bit then
    Bmp.PixelFormat := pf24bit;
  W := Bmp.Width;
  H := Bmp.Height;
  SetLength(Lines, H);
  for Y := 0 to H - 1 do
    Lines[Y] := Bmp.ScanLine[Y];
  Sum := 0;
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
      Inc(Sum, (299 * Lines[Y][X].R + 587 * Lines[Y][X].G + 114 * Lines[Y][X].B) div 1000);
  Result := Sum / (W * H);
end;

procedure DoObrys(Bitmap: TBitmap; Pct: Integer);
// Wrapper: suwak 1..100 -> p (wzmocnienie krawędzi XDoG, Eq.7); p = Pct·0.6.
var
  Tmp: TBitmap;
  P: Double;
begin
  if (Bitmap = nil) or (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;

  P := OBRYS_P_MIN + (OBRYS_P_MAX - OBRYS_P_MIN) * Pct / 100;

  Tmp := TBitmap.Create;
  try
    ApplyObrysEffect(Bitmap, Tmp, P, MeanLuma(Bitmap));
    Bitmap.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

function ShowObrysDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TObrysDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
  Bottom, Delta: Integer;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := nil;
  try
    Dlg := TObrysDlg.Create(Application);
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

    // Adaptacyjny próg XDoG liczony RAZ z pełnego obrazu (nie z wycinka 1:1) —
    // ten sam dla podglądu 100% i dla ApplyFull.
    Dlg.FEpsilon := MeanLuma(Bitmap);

    // Podgląd 100%: te same wymiary co nawigator (orientacja zdjęcia,
    // dłuższy bok 400 px). Fragment = 1:1 pikseli oryginału.
    Dlg.FNavW := pw;
    Dlg.FNavH := ph;
    Dlg.FZoomW := pw;
    Dlg.FZoomH := ph;
    Dlg.FZoomBmp := TBitmap.Create;
    Dlg.FZoomBmp.PixelFormat := pf24bit;
    Dlg.FZoomBmp.SetSize(pw, ph);

    // Początkowy środek podglądu = środek obrazu.
    Dlg.FZoomX := (Bitmap.Width - pw) div 2;
    Dlg.FZoomY := (Bitmap.Height - ph) div 2;

    // Layout: nawigator po lewej, podgląd 100% obok.
    Dlg.pboxPreview.Width := pw;
    Dlg.pboxPreview.Height := ph;
    Dlg.pboxPreview.Left := Dlg.CtrlGap;
    Dlg.pboxPreview.Top := Dlg.TitleBarGap + Dlg.CtrlGap;
    Dlg.pboxZoom.Left := Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2;
    Dlg.pboxZoom.Top := Dlg.pboxPreview.Top;
    Dlg.pboxZoom.Width := Dlg.FZoomW;
    Dlg.pboxZoom.Height := Dlg.FZoomH;

    Bottom := Dlg.pboxPreview.Top + Max(Dlg.pboxPreview.Height, Dlg.pboxZoom.Height)
      + Dlg.RowGap * 2;
    Delta := Bottom - Dlg.lblLabel.Top;
    if Delta > 0 then
    begin
      Dlg.lblLabel.Top := Dlg.lblLabel.Top + Delta;
      Dlg.tbAmount.Top := Dlg.tbAmount.Top + Delta;
      Dlg.lblValue.Top := Dlg.lblValue.Top + Delta;
      Dlg.btnOK.Top := Dlg.btnOK.Top + Delta;
      Dlg.btnCancel.Top := Dlg.btnCancel.Top + Delta;
    end;

    Dlg.ApplyPreview;

    Dlg.FitToContent(Dlg.CtrlGap * 2, Dlg.CtrlGap * 3);

    // Wyśrodkowanie pary podglądów w szerokości okna.
    Dlg.pboxPreview.Left := (Dlg.ClientWidth - (pw + Dlg.CtrlGap * 2 + pw)) div 2;
    if Dlg.pboxPreview.Left < Dlg.CtrlGap then
      Dlg.pboxPreview.Left := Dlg.CtrlGap;
    Dlg.pboxZoom.Left := Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2;

    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TObrysDlg }

procedure TObrysDlg.FormCreate(Sender: TObject);
begin
  // Bufor ekranu formy — bez tego podglądy (TPaintBox) migoczą przy każdej zmianie.
  DoubleBuffered := True;
  FZoomTimer := TTimer.Create(Self);
  FZoomTimer.Interval := 60;
  FZoomTimer.Enabled := False;
  FZoomTimer.OnTimer := ZoomTimerTick;
  tbAmount.Min := 1;
  tbAmount.Max := 100;
  tbAmount.Position := 30;
  lblValue.Caption := IntToStr(tbAmount.Position);
end;

procedure TObrysDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FEffBmp.Free;
end;

procedure TObrysDlg.tbAmountChange(Sender: TObject);
begin
  lblValue.Caption := IntToStr(tbAmount.Position);
  ApplyPreview;
end;

procedure TObrysDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) or (FSourceBmp = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  DoObrys(FWorkingPreview, tbAmount.Position);
  FEffValid := False;   // zmiana parametrów — region podglądu 100% do przeliczenia
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TObrysDlg.ApplyFull;
begin
  DoObrys(FSourceBmp, tbAmount.Position);
end;

procedure TObrysDlg.pboxPreviewPaint(Sender: TObject);
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
      // Ramka obszaru podglądu 100%.
      R := CursorRect;
      Brush.Style := bsClear;
      Pen.Style := psSolid;
      Pen.Color := clBlack;
      Pen.Width := 1;
      Rectangle(R);
      Pen.Color := clWhite;
      FrameRect(Rect(R.Left - 1, R.Top - 1, R.Right + 1, R.Bottom + 1));
      Pen.Width := 1;
      Brush.Style := bsSolid;
    end;
  end;
end;

// Pozycja ramki podglądu 100% w pikselach nawigatora (proporcje miniaturki).
function TObrysDlg.CursorRect: TRect;
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

// Odświeża tylko obszar objęty aRect (współrzędne nawigatora).
procedure TObrysDlg.InvalidateNavRect(aRect: TRect);
var
  P: TWinControl;
begin
  P := pboxPreview.Parent;
  if (P = nil) or (P.Handle = 0) then Exit;
  InflateRect(aRect, 1, 1);
  if aRect.Left < 0 then aRect.Left := 0;
  if aRect.Top < 0 then aRect.Top := 0;
  if aRect.Right > FNavW then aRect.Right := FNavW;
  if aRect.Bottom > FNavH then aRect.Bottom := FNavH;
  OffsetRect(aRect, pboxPreview.Left, pboxPreview.Top);
  InvalidateRect(P.Handle, @aRect, False);
end;

procedure TObrysDlg.RebuildZoom(X, Y: Integer);
var
  MaxX, MaxY: Integer;
  R, C, UR: TRect;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  MaxX := FSourceBmp.Width - FZoomW;
  MaxY := FSourceBmp.Height - FZoomH;
  if MaxX < 0 then MaxX := 0;
  if MaxY < 0 then MaxY := 0;
  if X < 0 then X := 0;
  if Y < 0 then Y := 0;
  if X > MaxX then X := MaxX;
  if Y > MaxY then Y := MaxY;
  if (FZoomX = X) and (FZoomY = Y) then Exit;
  R := CursorRect;   // stara pozycja ramki
  FZoomX := X;
  FZoomY := Y;
  // Ramka rusza się natychmiast (tanie). Ciężki render 100% idzie przez
  // FZoomTimer, żeby szybki ruch myszy nie odpalał przeliczenia na każdy piksel.
  C := CursorRect;
  UR := Rect(Min(R.Left, C.Left), Min(R.Top, C.Top),
    Max(R.Right, C.Right), Max(R.Bottom, C.Bottom));
  InvalidateNavRect(UR);
  FZoomDirty := True;
  if (FZoomTimer <> nil) and (not FZoomTimer.Enabled) then
    FZoomTimer.Enabled := True;
end;

// Podgląd 100% — XDoG jest filtrem lokalnym (dwa rozmycia Gaussa, zasięg rzędu
// kilku px), a ε jest stałe dla obrazu. Wycinek z marginesem 64 px daje więc w
// oknie podglądu wynik zgodny z pełnym obrazem: piksele wewnątrz okna nie
// zależą od pikseli spoza wycinka. Region cache'owany w FEffBmp.
procedure TObrysDlg.RenderFragment;
var
  Margin, X0, Y0, X1, Y1, CW, CH, dstX, dstY: Integer;
  P: Double;
  SrcRegion, DstRegion: TBitmap;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  P := OBRYS_P_MIN + (OBRYS_P_MAX - OBRYS_P_MIN) * tbAmount.Position / 100;
  Margin := 64;
  if (not FEffValid) or (FEffBmp = nil)
    or (FZoomX < FEffX) or (FZoomY < FEffY)
    or (FZoomX + FZoomW > FEffX + FEffW)
    or (FZoomY + FZoomH > FEffY + FEffH) then
  begin
    X0 := FZoomX - Margin;
    if X0 < 0 then X0 := 0;
    Y0 := FZoomY - Margin;
    if Y0 < 0 then Y0 := 0;
    X1 := FZoomX + FZoomW + Margin;
    if X1 > FSourceBmp.Width - 1 then X1 := FSourceBmp.Width - 1;
    Y1 := FZoomY + FZoomH + Margin;
    if Y1 > FSourceBmp.Height - 1 then Y1 := FSourceBmp.Height - 1;
    CW := X1 - X0 + 1;
    CH := Y1 - Y0 + 1;
    if (CW <= 0) or (CH <= 0) then Exit;
    if FEffBmp = nil then
      FEffBmp := TBitmap.Create;
    FEffBmp.PixelFormat := pf24bit;
    FEffBmp.SetSize(CW, CH);
    SrcRegion := TBitmap.Create;
    DstRegion := TBitmap.Create;
    try
      SrcRegion.PixelFormat := pf24bit;
      SrcRegion.SetSize(CW, CH);
      SrcRegion.Canvas.CopyRect(Rect(0, 0, CW, CH), FSourceBmp.Canvas,
        Rect(X0, Y0, X1 + 1, Y1 + 1));
      ApplyObrysEffect(SrcRegion, DstRegion, P, FEpsilon);
      FEffBmp.Canvas.Draw(0, 0, DstRegion);
    finally
      SrcRegion.Free;
      DstRegion.Free;
    end;
    FEffX := X0;
    FEffY := Y0;
    FEffW := CW;
    FEffH := CH;
    FEffValid := True;
  end;
  dstX := FZoomX - FEffX;
  dstY := FZoomY - FEffY;
  FZoomBmp.Canvas.CopyRect(Rect(0, 0, FZoomW, FZoomH), FEffBmp.Canvas,
    Rect(dstX, dstY, dstX + FZoomW, dstY + FZoomH));
  FZoomDirty := False;
end;

procedure TObrysDlg.ZoomTimerTick(Sender: TObject);
begin
  FZoomTimer.Enabled := False;
  if FZoomDirty and (FZoomBmp <> nil) then
  begin
    RenderFragment;
    pboxZoom.Invalidate;
  end;
end;

procedure TObrysDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  // X, Y w pikselach pboxPreview => mapa do pikseli oryginału.
  ImgX := Round(X * FSourceBmp.Width / FNavW);
  ImgY := Round(Y * FSourceBmp.Height / FNavH);
  // Środek kursora = środek podglądu 100%.
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TObrysDlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

end.
