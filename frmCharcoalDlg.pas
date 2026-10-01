unit frmCharcoalDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TCharcoalDlg = class(TFotoForm)
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

function ShowCharcoalDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoCharcoal(Bitmap: TBitmap; Pct: Integer);

implementation

uses
  uConvolution, uMacros;

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

// Architektura "Węgiel" v3: klasyczny przepis charcoal wg otwartych źródeł:
//   - ImageMagick CharcoalImage (MagickCore/visual-effects.c):
//       EdgeImage -> ClampImage -> BlurImage -> NormalizeImage -> NegateImage
//       -> GrayscaleImage.
//   - digiKam CharcoalFilter (core/libs/dimg/filters/fx/charcoalfilter.cpp):
//       edge Laplacian -> Gaussian blur -> stretch contrast -> invert
//       -> monochrome mixer (wagi Rec.601 0.3/0.59/0.11).
// Pipeline portu (bez color dodge — to mit z GIMP, nie ma go w żadnym z tych kodów):
//   1. EDGE: kernel Laplacjan (2R+1)x(2R+1): wszystkie wpisy -1, środek N-1
//      (N = (2R+1)^2, suma kernela = 0). Tożsamość: edge = N*center - winSum.
//      winSum liczone przez summed-area table (SAT) z paddingiem clamp-to-edge
//      (replikacja brzegów, jak ImageMagick ConvolveImage) -> O(1) na piksel,
//      wynik matematycznie identyczny z pełną konwolucją. Wynik clamp do 0..255.
//   2. BLUR: Gaussian blur (BoxBlur/GR32) o promieniu = R (ImageMagick:
//      BlurImage(edge, radius, sigma) — ten sam radius).
//   3. NORMALIZE: stretch min->0, max->255 per-kanał.
//   4. NEGATE: v = 255 - v.
//   5. GRAYSCALE: Rec.601 L = 0.3*R + 0.59*G + 0.11*B (wagi digiKam).

const
  REFERENCE_WIDTH = 1000;

function ScaledRadius(SliderValue, ImageWidth: Integer): Integer;
// Wzorzec jak frmBlurDlg: promień skaluje się do szerokości obrazu, więc podgląd
// (400px) i pełny oryginał dają spójny efekt względny. Hollywood (stały 1..30)
// jest tu tylko punktem odniesienia, nie wzorcem.
begin
  Result := Max(1, Round(SliderValue * ImageWidth / REFERENCE_WIDTH));
end;

function ClampInt(V, Lo, Hi: Integer): Integer; inline;
begin
  if V < Lo then Result := Lo
  else if V > Hi then Result := Hi
  else Result := V;
end;

function ClampByte(V: Integer): Byte; inline;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := Byte(V);
end;

function ChannelValue(const P: TRGBTriple; ch: Integer): Byte; inline;
begin
  case ch of
    0: Result := P.R;
    1: Result := P.G;
  else
    Result := P.B;
  end;
end;

procedure ApplyCharcoalEffect(Src, Dst: TBitmap; Radius, BlurRadius: Integer);
var
  W, H, X, Y, R, N, ch, C, EdgeVal: Integer;
  PW, PH, px, py, sx, sy: Integer;
  WinSum: Int64;
  SAT: array of array of Int64;
  SrcLines, EdgeLines, BlurLines, DstLines: array of PRGBTripleArray;
  EdgeBmp, BlurBmp: TBitmap;
  MinV, MaxV: array[0..2] of Integer;
  NR, NG, NB, L: Integer;
begin
  W := Src.Width;
  H := Src.Height;
  if (W = 0) or (H = 0) then Exit;
  if Src.PixelFormat <> pf24bit then Src.PixelFormat := pf24bit;

  R := Max(1, Radius);
  if BlurRadius < 1 then BlurRadius := 1;
  N := (2 * R + 1) * (2 * R + 1);

  Dst.PixelFormat := pf24bit;
  Dst.SetSize(W, H);

  SetLength(SrcLines, H);
  SetLength(DstLines, H);
  for Y := 0 to H - 1 do
  begin
    SrcLines[Y] := Src.ScanLine[Y];
    DstLines[Y] := Dst.ScanLine[Y];
  end;

  EdgeBmp := TBitmap.Create;
  BlurBmp := TBitmap.Create;
  try
    EdgeBmp.PixelFormat := pf24bit;
    EdgeBmp.SetSize(W, H);
    BlurBmp.PixelFormat := pf24bit;
    BlurBmp.SetSize(W, H);

    SetLength(EdgeLines, H);
    for Y := 0 to H - 1 do
      EdgeLines[Y] := EdgeBmp.ScanLine[Y];

    // 1. EDGE per-kanał.
    // SAT budujemy nad obrazem dopełnionym R pikselami clamp-to-edge (replikacja
    // brzegów — to samo robi ImageMagick ConvolveImage). Wtedy okno (2R+1)x(2R+1)
    // ma pełne N pikseli także przy brzegach, a edge = N*center - winSum jest
    // identyczny z pełną konwolucją. O(1) na piksel zamiast O(N).
    PW := W + 2 * R;
    PH := H + 2 * R;
    SetLength(SAT, PH + 1);
    for Y := 0 to PH do
      SetLength(SAT[Y], PW + 1);

    for ch := 0 to 2 do
    begin
      for py := 0 to PH - 1 do
      begin
        sy := ClampInt(py - R, 0, H - 1);
        SAT[py + 1][0] := 0;
        for px := 0 to PW - 1 do
        begin
          sx := ClampInt(px - R, 0, W - 1);
          SAT[py + 1][px + 1] := SAT[py][px + 1] + SAT[py + 1][px] - SAT[py][px]
            + ChannelValue(SrcLines[sy][sx], ch);
        end;
      end;

      for Y := 0 to H - 1 do
        for X := 0 to W - 1 do
        begin
          WinSum := SAT[Y + 2*R + 1][X + 2*R + 1]
                  - SAT[Y][X + 2*R + 1]
                  - SAT[Y + 2*R + 1][X]
                  + SAT[Y][X];
          C := ChannelValue(SrcLines[Y][X], ch);
          EdgeVal := ClampByte(N * C - Integer(WinSum));
          case ch of
            0: EdgeLines[Y][X].R := Byte(EdgeVal);
            1: EdgeLines[Y][X].G := Byte(EdgeVal);
          else
            EdgeLines[Y][X].B := Byte(EdgeVal);
          end;
        end;
    end;

    for Y := 0 to PH do
      SetLength(SAT[Y], 0);
    SetLength(SAT, 0);

    // 2. BLUR — łagodne rozmycie, STAŁE względem rozmiaru obrazu, niezależne od
    // suwaka. Suwak steruje tylko kernelem krawędzi (intensywność węgla), nie
    // rozmyciem — w przeciwnym razie rosnący suwak rozmywałby obraz (to był błąd).
    // BlurRadius jest parametrem (liczonym z szerokości PEŁNEGO obrazu), żeby
    // wycinek 1:1 rozmywał tak samo jak pełny obraz.
    BoxBlur(EdgeBmp, BlurBmp, BlurRadius);
    SetLength(BlurLines, H);
    for Y := 0 to H - 1 do
      BlurLines[Y] := BlurBmp.ScanLine[Y];

    // 3. NORMALIZE per-kanał
    MinV[0] := 255; MaxV[0] := 0;
    MinV[1] := 255; MaxV[1] := 0;
    MinV[2] := 255; MaxV[2] := 0;
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        if BlurLines[Y][X].R < MinV[0] then MinV[0] := BlurLines[Y][X].R;
        if BlurLines[Y][X].R > MaxV[0] then MaxV[0] := BlurLines[Y][X].R;
        if BlurLines[Y][X].G < MinV[1] then MinV[1] := BlurLines[Y][X].G;
        if BlurLines[Y][X].G > MaxV[1] then MaxV[1] := BlurLines[Y][X].G;
        if BlurLines[Y][X].B < MinV[2] then MinV[2] := BlurLines[Y][X].B;
        if BlurLines[Y][X].B > MaxV[2] then MaxV[2] := BlurLines[Y][X].B;
      end;

    // 4+5. NEGATE + GRAYSCALE Rec.601
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        NR := 255 - ClampByte(Round((BlurLines[Y][X].R - MinV[0]) * 255.0
          / Max(MaxV[0] - MinV[0], 1)));
        NG := 255 - ClampByte(Round((BlurLines[Y][X].G - MinV[1]) * 255.0
          / Max(MaxV[1] - MinV[1], 1)));
        NB := 255 - ClampByte(Round((BlurLines[Y][X].B - MinV[2]) * 255.0
          / Max(MaxV[2] - MinV[2], 1)));
        L := (299 * NR + 587 * NG + 114 * NB) div 1000;
        DstLines[Y][X].R := Byte(L);
        DstLines[Y][X].G := Byte(L);
        DstLines[Y][X].B := Byte(L);
      end;
  finally
    EdgeBmp.Free;
    BlurBmp.Free;
  end;
end;

procedure DoCharcoal(Bitmap: TBitmap; Pct: Integer);
// Promień skaluje się do szerokości obrazu (REFERENCE_WIDTH = 1000px).
var
  Radius, BlurRadius: Integer;
  Tmp: TBitmap;
begin
  if (Bitmap = nil) or (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;

  Pct := Max(1, Min(100, Pct));
  Radius := ScaledRadius(Round(Pct / 100 * 30), Bitmap.Width);
  BlurRadius := Max(1, Round(2 * Bitmap.Width / REFERENCE_WIDTH));

  Tmp := TBitmap.Create;
  try
    ApplyCharcoalEffect(Bitmap, Tmp, Radius, BlurRadius);
    Bitmap.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

function ShowCharcoalDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TCharcoalDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
  Bottom, Delta: Integer;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := nil;
  try
    Dlg := TCharcoalDlg.Create(Application);
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
      gMacroPending.Code := 'CHARCOAL';
      gMacroPending.Params := IntToStr(Dlg.tbAmount.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TCharcoalDlg }

procedure TCharcoalDlg.FormCreate(Sender: TObject);
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

procedure TCharcoalDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FEffBmp.Free;
end;

procedure TCharcoalDlg.tbAmountChange(Sender: TObject);
begin
  lblValue.Caption := IntToStr(tbAmount.Position);
  ApplyPreview;
end;

procedure TCharcoalDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) or (FSourceBmp = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  // Radius skaluje się do szerokości podglądu, więc podgląd (400px) wygląda
  // tak samo względnie jak pełny oryginał.
  DoCharcoal(FWorkingPreview, tbAmount.Position);
  FEffValid := False;   // zmiana parametrów — region podglądu 100% do przeliczenia
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TCharcoalDlg.ApplyFull;
begin
  DoCharcoal(FSourceBmp, tbAmount.Position);
end;

procedure TCharcoalDlg.pboxPreviewPaint(Sender: TObject);
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
function TCharcoalDlg.CursorRect: TRect;
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
procedure TCharcoalDlg.InvalidateNavRect(aRect: TRect);
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

procedure TCharcoalDlg.RebuildZoom(X, Y: Integer);
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

// Podgląd 100% — pipeline Węgla jest lokalny (Laplacjan o promieniu Radius
// + rozmycie o promieniu BlurRadius), więc wycinek z marginesem >= Radius +
// BlurRadius daje w oknie wynik zgodny z pełnym obrazem aż do normalizacji
// min/max, która jest GLOBALNA — w 1:1 liczona lokalnie (świadomy kompromis:
// struktura/kreska 1:1, kontrast może się minimalnie różnić od ApplyFull).
// BlurRadius i Radius liczone z szerokości PEŁNEGO obrazu, nie wycinka.
// Region cache'owany w FEffBmp.
procedure TCharcoalDlg.RenderFragment;
var
  Margin, X0, Y0, X1, Y1, CW, CH, dstX, dstY, Radius, BlurRadius: Integer;
  SrcRegion, DstRegion: TBitmap;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  Radius := ScaledRadius(Round(tbAmount.Position / 100 * 30), FSourceBmp.Width);
  BlurRadius := Max(1, Round(2 * FSourceBmp.Width / REFERENCE_WIDTH));
  Margin := Radius + BlurRadius + 32;
  if Margin < 64 then Margin := 64;
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
      ApplyCharcoalEffect(SrcRegion, DstRegion, Radius, BlurRadius);
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

procedure TCharcoalDlg.ZoomTimerTick(Sender: TObject);
begin
  FZoomTimer.Enabled := False;
  if FZoomDirty and (FZoomBmp <> nil) then
  begin
    RenderFragment;
    pboxZoom.Invalidate;
  end;
end;

procedure TCharcoalDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  // X, Y w pikselach pboxPreview => mapa do pikseli oryginału.
  ImgX := Round(X * FSourceBmp.Width / FNavW);
  ImgY := Round(Y * FSourceBmp.Height / FNavH);
  // Środek kursora = środek podglądu 100%.
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TCharcoalDlg.pboxZoomPaint(Sender: TObject);
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
