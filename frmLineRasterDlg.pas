unit frmLineRasterDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uTitleBar;

type
  TLineRasterDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    pboxZoom: TPaintBox;
    lblAngle: TLabel;
    tbAngle: TTrackBar;
    lblAngleVal: TLabel;
    lblCell: TLabel;
    tbCell: TTrackBar;
    lblCellVal: TLabel;
    lblThick: TLabel;
    tbThick: TTrackBar;
    lblThickVal: TLabel;
    lblFollow: TLabel;
    tbFollow: TTrackBar;
    lblFollowVal: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxZoomPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure tbAngleChange(Sender: TObject);
    procedure tbCellChange(Sender: TObject);
    procedure tbThickChange(Sender: TObject);
    procedure tbFollowChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FZoomBmp: TBitmap;
    FSize: Integer;
    FAngle: Integer;
    FThick: Integer;
    FFollow: Integer;
    FStretchLo, FStretchHi: Integer;
    FNavW, FNavH: Integer;
    FZoomX, FZoomY, FZoomW, FZoomH: Integer;
    procedure ApplyPreview;
    procedure ApplyFull;
    function CursorRect: TRect;
    procedure InvalidateNavRect(aRect: TRect);
    procedure RebuildZoom(X, Y: Integer);
    procedure RenderFragment;
  end;

function ShowLineRasterDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoLineRaster(Bitmap: TBitmap; Angle, CellSize, MaxThick, Follow: Integer);

implementation

uses
  uMacros;

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

// === Silnik grawerski (równoległe linie z przesunięciem fazy) ===============
// Równoległe, ciągłe linie pod kątem z suwaka, w odstępie CellSize:
//  - grayscale + rozciągnięcie histogramu (obetnij 2% z obu końców); zakres
//    może być podany z zewnątrz, żeby podgląd fragmentu zgadzał się z całością,
//  - ton: ciemność = 1 - rozmycie(σ≈0.7*odstęp), wzmocniona x1.25; pole
//    przesunięcia D = rozmycie jasności (σ≈4*odstęp),
//  - przy krawędziach (gradient jasności) grubość z tonu piksela z ostrą krzywą
//    zamiast tonu z osi linii (obrys bez poszatkowania),
//  - współrzędna prostopadła do linii U jest przesuwana o
//    (Follow/100)*odstęp*6*(D-0.5) -> linie wyginają się wg jasności,
//  - połowa grubości linii = 0.1*MaxThick*odstęp*ciemność, ciemność próbkowana
//    na OSI linii (grubość stała w poprzek linii), AA 1 px, cienkie linie
//    wygaszane (w światłach linie znikają).
// Deterministyczne, bez losowości, jedno przejście po pikselach.

function LineRasterRadius(Sigma: Double): Integer;
begin
  Result := Round(Sigma - 0.5);
  if Result < 1 then Result := 1;
end;

// 3×skrzynkowy blur przybliżający gaussiana o σ≈Rad (krawędzie replikowane).
function BoxBlurSingle(Src: TArray<Single>; W, H, Rad: Integer): TArray<Single>;
var
  Cur, Tmp: TArray<Single>;
  Pass, X, Y, I, Lo, Hi: Integer;
  Sum, Den: Single;
begin
  Den := 2 * Rad + 1;
  SetLength(Cur, W * H);
  Move(Src[0], Cur[0], W * H * SizeOf(Single));
  SetLength(Tmp, W * H);
  for Pass := 1 to 3 do
  begin
    for Y := 0 to H - 1 do
    begin
      Sum := 0;
      for I := -Rad to Rad do
      begin
        X := I;
        if X < 0 then X := 0 else if X > W - 1 then X := W - 1;
        Sum := Sum + Cur[Y * W + X];
      end;
      for X := 0 to W - 1 do
      begin
        Tmp[Y * W + X] := Sum / Den;
        Lo := X - Rad;
        if Lo < 0 then Lo := 0;
        Sum := Sum - Cur[Y * W + Lo];
        Hi := X + Rad + 1;
        if Hi > W - 1 then Hi := W - 1;
        Sum := Sum + Cur[Y * W + Hi];
      end;
    end;
    for X := 0 to W - 1 do
    begin
      Sum := 0;
      for I := -Rad to Rad do
      begin
        Y := I;
        if Y < 0 then Y := 0 else if Y > H - 1 then Y := H - 1;
        Sum := Sum + Tmp[Y * W + X];
      end;
      for Y := 0 to H - 1 do
      begin
        Cur[Y * W + X] := Sum / Den;
        Lo := Y - Rad;
        if Lo < 0 then Lo := 0;
        Sum := Sum - Tmp[Lo * W + X];
        Hi := Y + Rad + 1;
        if Hi > H - 1 then Hi := H - 1;
        Sum := Sum + Tmp[Hi * W + X];
      end;
    end;
  end;
  Result := Cur;
end;

// Zakres rozciągnięcia histogramu: obetnij 2% najciemniejszych i najjaśniejszych.
procedure GrayStretchRange(const Gray: TArray<Byte>; Total: Integer; out Lo, Hi: Integer);
var
  Hist: array[0..255] of Integer;
  I, Cnt: Integer;
begin
  for I := 0 to 255 do
    Hist[I] := 0;
  for I := 0 to Total - 1 do
    Inc(Hist[Gray[I]]);
  Lo := 0;
  Cnt := 0;
  while (Lo < 255) and (Cnt + Hist[Lo] < Round(Total * 0.02)) do
  begin
    Inc(Cnt, Hist[Lo]);
    Inc(Lo);
  end;
  Hi := 255;
  Cnt := 0;
  while (Hi > 0) and (Cnt + Hist[Hi] < Round(Total * 0.02)) do
  begin
    Inc(Cnt, Hist[Hi]);
    Dec(Hi);
  end;
  if Hi <= Lo then
  begin
    Lo := 0;
    Hi := 255;
  end;
end;

procedure BitmapToGray(Bitmap: TBitmap; out Gray: TArray<Byte>);
var
  W, H, X, Y: Integer;
  Line: PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  SetLength(Gray, W * H);
  for Y := 0 to H - 1 do
  begin
    Line := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
      Gray[Y * W + X] := (Line[X].R * 299 + Line[X].G * 587 + Line[X].B * 114) div 1000;
  end;
end;

// Zakres rozciągnięcia dla całego obrazu (podgląd fragmentu używa go zamiast
// własnego, żeby wyglądał tak samo jak wynik końcowy).
procedure LineRasterRange(Bitmap: TBitmap; out Lo, Hi: Integer);
var
  Gray: TArray<Byte>;
begin
  Lo := -1;
  Hi := -1;
  if (Bitmap = nil) or (Bitmap.Width < 2) or (Bitmap.Height < 2) then Exit;
  Bitmap.PixelFormat := pf24bit;
  BitmapToGray(Bitmap, Gray);
  GrayStretchRange(Gray, Bitmap.Width * Bitmap.Height, Lo, Hi);
end;

function SampleSingle(const A: TArray<Single>; W, H: Integer; PX, PY: Double): Single;
var
  X0, Y0, X1, Y1: Integer;
  FX, FY: Double;
begin
  if PX < 0 then PX := 0 else if PX > W - 1 then PX := W - 1;
  if PY < 0 then PY := 0 else if PY > H - 1 then PY := H - 1;
  X0 := Trunc(PX);
  Y0 := Trunc(PY);
  X1 := X0 + 1;
  if X1 > W - 1 then X1 := W - 1;
  Y1 := Y0 + 1;
  if Y1 > H - 1 then Y1 := H - 1;
  FX := PX - X0;
  FY := PY - Y0;
  Result := A[Y0 * W + X0] * (1 - FX) * (1 - FY) + A[Y0 * W + X1] * FX * (1 - FY)
    + A[Y1 * W + X0] * (1 - FX) * FY + A[Y1 * W + X1] * FX * FY;
end;

// OffX/OffY: położenie bitmapy w obrazie źródłowym (faza linii zgodna z
// całością). Lo/Hi: zakres rozciągnięcia (<0 = policz z tej bitmapy).
procedure LineRasterBitmap(Bitmap: TBitmap; Angle, CellSize, MaxThick, Follow,
  OffX, OffY, Lo, Hi: Integer);
var
  W, H, X, Y, I, S, K: Integer;
  Gray: TArray<Byte>;
  G, Dark, D, Fine, EdgeSrc, EdgeT: TArray<Single>;
  Line: PRGBTripleArray;
  Th, Nx, Ny, WMax, ShiftAmp, Rng, V, U, Off, XC, YC, Dk, HW, Cov, Sol, Fade, Gx, Gy, Tt: Double;
  Idx: Integer;
  B: Byte;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W < 2) or (H < 2) then Exit;
  S := CellSize;
  if S < 4 then S := 4;
  if S > 16 then S := 16;
  if MaxThick < 1 then MaxThick := 1;
  if MaxThick > 8 then MaxThick := 8;
  if Follow < 0 then Follow := 0;
  if Follow > 100 then Follow := 100;

  Bitmap.PixelFormat := pf24bit;
  BitmapToGray(Bitmap, Gray);
  if (Lo < 0) or (Hi <= Lo) then
    GrayStretchRange(Gray, W * H, Lo, Hi);
  Rng := Hi - Lo;
  if Rng < 1 then Rng := 1;
  SetLength(G, W * H);
  for I := 0 to W * H - 1 do
  begin
    V := (Gray[I] - Lo) / Rng;
    if V < 0 then V := 0
    else if V > 1 then V := 1;
    G[I] := V;
  end;
  Gray := nil;

  Dark := BoxBlurSingle(G, W, H, LineRasterRadius(0.7 * S));
  for I := 0 to W * H - 1 do
    Dark[I] := 1.0 - Dark[I];
  // Ton drobny z ostrą krzywą - używany tylko przy krawędziach (zamiast tonu
  // z osi linii), żeby obrys nie był poszatkowany klinami linii.
  Fine := BoxBlurSingle(G, W, H, LineRasterRadius(0.3 * S));
  for I := 0 to W * H - 1 do
  begin
    V := (1.0 - Fine[I] - 0.3) / 0.4;
    if V < 0 then V := 0
    else if V > 1 then V := 1;
    Fine[I] := V * V * (3.0 - 2.0 * V);
  end;
  // Siła krawędzi: gradient (Sobel/8) jasności rozmytej σ≈0.5*odstęp.
  EdgeSrc := BoxBlurSingle(G, W, H, LineRasterRadius(0.5 * S));
  SetLength(EdgeT, W * H);
  for Y := 1 to H - 2 do
    for X := 1 to W - 2 do
    begin
      Gx := ((EdgeSrc[(Y - 1) * W + X + 1] + 2 * EdgeSrc[Y * W + X + 1] + EdgeSrc[(Y + 1) * W + X + 1])
        - (EdgeSrc[(Y - 1) * W + X - 1] + 2 * EdgeSrc[Y * W + X - 1] + EdgeSrc[(Y + 1) * W + X - 1])) / 8.0;
      Gy := ((EdgeSrc[(Y + 1) * W + X - 1] + 2 * EdgeSrc[(Y + 1) * W + X] + EdgeSrc[(Y + 1) * W + X + 1])
        - (EdgeSrc[(Y - 1) * W + X - 1] + 2 * EdgeSrc[(Y - 1) * W + X] + EdgeSrc[(Y - 1) * W + X + 1])) / 8.0;
      Tt := (Sqrt(Gx * Gx + Gy * Gy) * S - 0.1) / 0.2;
      if Tt < 0 then Tt := 0
      else if Tt > 1 then Tt := 1;
      EdgeT[Y * W + X] := Tt;
    end;
  EdgeSrc := nil;
  D := BoxBlurSingle(G, W, H, LineRasterRadius(4.0 * S));
  G := nil;

  Th := Angle * Pi / 180.0;
  Nx := -Sin(Th);
  Ny := Cos(Th);
  WMax := 0.1 * MaxThick;
  ShiftAmp := (Follow / 100.0) * S * 6.0;

  for Y := 0 to H - 1 do
  begin
    Line := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      U := (X + OffX) * Nx + (Y + OffY) * Ny + ShiftAmp * (D[Y * W + X] - 0.5);
      K := Floor(U / S + 0.5);
      Off := U - K * S;
      XC := X - Off * Nx;
      YC := Y - Off * Ny;
      Idx := Y * W + X;
      Dk := ((1.0 - EdgeT[Idx]) * SampleSingle(Dark, W, H, XC, YC)
        + EdgeT[Idx] * Fine[Idx]) * 1.25;
      if Dk < 0 then Dk := 0
      else if Dk > 1 then Dk := 1;
      HW := WMax * S * Dk;
      Cov := HW - Abs(Off) + 0.5;
      if Cov < 0 then Cov := 0
      else if Cov > 1 then Cov := 1;
      // Ciemne miejsca: linie zlewają się w pełną czerń (bez szczelin 0.5 px).
      Sol := (HW - 0.4 * S) / (0.1 * S);
      if Sol > 1 then Sol := 1;
      if Sol > Cov then Cov := Sol;
      Fade := (HW - 0.15) / 0.2;
      if Fade < 0 then Fade := 0
      else if Fade > 1 then Fade := 1;
      Cov := Cov * Fade;
      B := Byte(255 - Round(Cov * 255.0));
      Line[X].R := B;
      Line[X].G := B;
      Line[X].B := B;
    end;
  end;
end;

procedure DoLineRaster(Bitmap: TBitmap; Angle, CellSize, MaxThick, Follow: Integer);
begin
  LineRasterBitmap(Bitmap, Angle, CellSize, MaxThick, Follow, 0, 0, -1, -1);
end;

function ShowLineRasterDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TLineRasterDlg;
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
  Dlg := TLineRasterDlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;
    LineRasterRange(Bitmap, Dlg.FStretchLo, Dlg.FStretchHi);

    // Nawigator: cały obraz skalowany do 400 px (jak pozostałe dialogi).
    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));
    Dlg.FNavW := pw;
    Dlg.FNavH := ph;

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

    // Podgląd 100%: te same wymiary co nawigator (pw x ph, orientacja zdjęcia).
    // Fragment = 1:1 pikseli oryginału.
    Dlg.FZoomW := pw;
    Dlg.FZoomH := ph;
    Dlg.FZoomBmp := TBitmap.Create;
    Dlg.FZoomBmp.PixelFormat := pf24bit;
    Dlg.FZoomBmp.SetSize(pw, ph);

    // Początkowy środek podglądu = środek obrazu.
    Dlg.FZoomX := (Bitmap.Width - pw) div 2;
    Dlg.FZoomY := (Bitmap.Height - ph) div 2;

    // Layout: nawigator po lewej, podgląd 100% obok. Cztery wiersze kontrolek
    // (kąt, rozmiar komórki, grubość, podążanie za kształtem) są dociskane w
    // dół, gdy podglądy są wyższe niż w DFM.
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
    Delta := Bottom - Dlg.lblAngle.Top;
    if Delta > 0 then
    begin
      Dlg.lblAngle.Top := Dlg.lblAngle.Top + Delta;
      Dlg.tbAngle.Top := Dlg.tbAngle.Top + Delta;
      Dlg.lblAngleVal.Top := Dlg.lblAngleVal.Top + Delta;
      Dlg.lblCell.Top := Dlg.lblCell.Top + Delta;
      Dlg.tbCell.Top := Dlg.tbCell.Top + Delta;
      Dlg.lblCellVal.Top := Dlg.lblCellVal.Top + Delta;
      Dlg.lblThick.Top := Dlg.lblThick.Top + Delta;
      Dlg.tbThick.Top := Dlg.tbThick.Top + Delta;
      Dlg.lblThickVal.Top := Dlg.lblThickVal.Top + Delta;
      Dlg.lblFollow.Top := Dlg.lblFollow.Top + Delta;
      Dlg.tbFollow.Top := Dlg.tbFollow.Top + Delta;
      Dlg.lblFollowVal.Top := Dlg.lblFollowVal.Top + Delta;
      Dlg.btnOK.Top := Dlg.btnOK.Top + Delta;
      Dlg.btnCancel.Top := Dlg.btnCancel.Top + Delta;
    end;

    Dlg.FAngle := Dlg.tbAngle.Position;
    Dlg.FSize := Dlg.tbCell.Position;
    Dlg.FThick := Dlg.tbThick.Position;
    Dlg.FFollow := Dlg.tbFollow.Position;
    Dlg.ApplyPreview;

    Dlg.FitToContent(Dlg.CtrlGap * 2, Dlg.CtrlGap * 3);

    // Wyśrodkowanie pary podglądów w szerokości okna. Szerokość okna wyznacza
    // najszerszy element (tbAngle/tbCell/tbThick) — bez centrowania para leży
    // przy lewej krawędzi, a po prawej zostaje pas pustego tła.
    Dlg.pboxPreview.Left := (Dlg.ClientWidth - (pw + Dlg.CtrlGap * 2 + pw)) div 2;
    if Dlg.pboxPreview.Left < Dlg.CtrlGap then
      Dlg.pboxPreview.Left := Dlg.CtrlGap;
    Dlg.pboxZoom.Left := Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2;

    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      gMacroPending.Code := 'LINERASTER';
      gMacroPending.Params := IntToStr(Dlg.tbAngle.Position) + '|' + IntToStr(Dlg.tbCell.Position) + '|' + IntToStr(Dlg.tbThick.Position) + '|' + IntToStr(Dlg.tbFollow.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TLineRasterDlg }

procedure TLineRasterDlg.FormCreate(Sender: TObject);
begin
  // Bufor ekranu formy — bez tego podglądy (TPaintBox) migoczą przy każdej
  // zmianie. To ustawienie robił dawniej FitPreviewToDialog (uPreviewFit.pas:38),
  // usunięty przy porcie wzorca podglądu.
  DoubleBuffered := True;
  tbAngle.Position := 45;
  tbCell.Position := 10;
  tbThick.Position := 5;
  tbFollow.Position := 40;
  lblAngleVal.Caption := IntToStr(tbAngle.Position);
  lblCellVal.Caption := IntToStr(tbCell.Position);
  lblThickVal.Caption := IntToStr(tbThick.Position);
  lblFollowVal.Caption := IntToStr(tbFollow.Position);
end;

procedure TLineRasterDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
end;

procedure TLineRasterDlg.tbAngleChange(Sender: TObject);
begin
  lblAngleVal.Caption := IntToStr(tbAngle.Position);
  FAngle := tbAngle.Position;
  ApplyPreview;
end;

procedure TLineRasterDlg.tbCellChange(Sender: TObject);
begin
  lblCellVal.Caption := IntToStr(tbCell.Position);
  FSize := tbCell.Position;
  ApplyPreview;
end;

procedure TLineRasterDlg.tbThickChange(Sender: TObject);
begin
  lblThickVal.Caption := IntToStr(tbThick.Position);
  FThick := tbThick.Position;
  ApplyPreview;
end;

procedure TLineRasterDlg.tbFollowChange(Sender: TObject);
begin
  lblFollowVal.Caption := IntToStr(tbFollow.Position);
  FFollow := tbFollow.Position;
  ApplyPreview;
end;

procedure TLineRasterDlg.ApplyPreview;
begin
  if FSourceBmp = nil then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  LineRasterBitmap(FWorkingPreview, FAngle, FSize, FThick, FFollow, 0, 0,
    FStretchLo, FStretchHi);
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TLineRasterDlg.ApplyFull;
begin
  DoLineRaster(FSourceBmp, tbAngle.Position, tbCell.Position, tbThick.Position, tbFollow.Position);
end;

// Pozycja ramki podglądu 100% w pikselach nawigatora (proporcje miniaturki).
function TLineRasterDlg.CursorRect: TRect;
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
procedure TLineRasterDlg.InvalidateNavRect(aRect: TRect);
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

procedure TLineRasterDlg.RebuildZoom(X, Y: Integer);
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
  // Pozycja bez zmian (kursor w tym samym pikselu) — nie przeliczamy niczego.
  if (FZoomX = X) and (FZoomY = Y) then Exit;
  R := CursorRect;   // stara pozycja ramki
  FZoomX := X;
  FZoomY := Y;
  RenderFragment;
  // Na nawigatorze odświeżamy tylko sumę starej i nowej pozycji ramki.
  C := CursorRect;
  UR := Rect(Min(R.Left, C.Left), Min(R.Top, C.Top),
    Max(R.Right, C.Right), Max(R.Bottom, C.Bottom));
  InvalidateNavRect(UR);
  pboxZoom.Invalidate;
end;

// Renderuje fragment podglądu 100%: wycinek Regionu źródła (FZoomX/Y/W/H),
// silnik grawerski 1:1 na wycinku, wynik na FZoomBmp.
procedure TLineRasterDlg.RenderFragment;
var
  RegX, RegY, RegW, RegH: Integer;
  Tmp: TBitmap;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  RegW := FZoomW;
  RegH := FZoomH;
  if RegW > FSourceBmp.Width then RegW := FSourceBmp.Width;
  if RegH > FSourceBmp.Height then RegH := FSourceBmp.Height;
  if (RegW <= 0) or (RegH <= 0) then Exit;
  RegX := FZoomX;
  RegY := FZoomY;
  if RegX < 0 then RegX := 0;
  if RegY < 0 then RegY := 0;
  if RegX + RegW > FSourceBmp.Width then RegW := FSourceBmp.Width - RegX;
  if RegY + RegH > FSourceBmp.Height then RegH := FSourceBmp.Height - RegY;

  FZoomBmp.Canvas.Brush.Color := clWhite;
  FZoomBmp.Canvas.FillRect(Rect(0, 0, FZoomBmp.Width, FZoomBmp.Height));

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(RegW, RegH);
    Tmp.Canvas.CopyRect(Rect(0, 0, RegW, RegH), FSourceBmp.Canvas,
      Rect(RegX, RegY, RegX + RegW, RegY + RegH));
    LineRasterBitmap(Tmp, FAngle, FSize, FThick, FFollow, RegX, RegY,
      FStretchLo, FStretchHi);
    FZoomBmp.Canvas.Draw(0, 0, Tmp);
  finally
    Tmp.Free;
  end;
end;

procedure TLineRasterDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  // X, Y w pikselach pboxPreview => mapa do pikseli oryginału.
  ImgX := Round(X * FSourceBmp.Width / FNavW);
  ImgY := Round(Y * FSourceBmp.Height / FNavH);
  // Środek kursora = środek podglądu 100%.
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TLineRasterDlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

procedure TLineRasterDlg.pboxPreviewPaint(Sender: TObject);
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

end.
