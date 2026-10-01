unit frmGlowDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit,
  uConvolution, uTitleBar;

type
  TGlowDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    pboxZoom: TPaintBox;
    lblRadius: TLabel;
    tbRadius: TTrackBar;
    lblValue: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pboxZoomPaint(Sender: TObject);
    procedure tbRadiusChange(Sender: TObject);
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

function ShowGlowDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoGlow(Bitmap: TBitmap; Radius: Integer);

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

procedure DoGlow(Bitmap: TBitmap; Radius: Integer);
// Blask (NeonGlow) wg Hollywood p_FxNeonGlow:
// 1. Maska: tylko jasne (lum>128) lub nasycone (sat>80) piksele, reszta czarna.
// 2. Rozmycie maski o promieniu Radius (rozchodzenie się światła).
// 3. Blend addytywny: out = min(255, orig + glow*0.8).
var
  W, H, X, Y, Lum, MaxC, MinC, Sat: Integer;
  Row, MaskRow: PRGBTripleArray;
  Mask, Blurred: TBitmap;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  if Bitmap.PixelFormat <> pf24bit then
    Bitmap.PixelFormat := pf24bit;

  Radius := Max(1, Min(20, Radius));

  // 1. Maska
  Mask := TBitmap.Create;
  Blurred := TBitmap.Create;
  try
    Mask.PixelFormat := pf24bit;
    Mask.SetSize(W, H);
    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      MaskRow := Mask.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Lum := (Row[X].R * 299 + Row[X].G * 587 + Row[X].B * 114) div 1000;
        MaxC := Max(Row[X].R, Max(Row[X].G, Row[X].B));
        MinC := Min(Row[X].R, Min(Row[X].G, Row[X].B));
        Sat := MaxC - MinC;
        if (Lum > 128) or (Sat > 80) then
        begin
          MaskRow[X].R := Row[X].R;
          MaskRow[X].G := Row[X].G;
          MaskRow[X].B := Row[X].B;
        end
        else
        begin
          MaskRow[X].R := 0;
          MaskRow[X].G := 0;
          MaskRow[X].B := 0;
        end;
      end;
    end;

    // 2. Rozmycie maski
    Blurred.PixelFormat := pf24bit;
    Blurred.SetSize(W, H);
    BoxBlur(Mask, Blurred, Radius);

    // 3. Blend addytywny
    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      MaskRow := Blurred.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Row[X].R := Byte(Min(255, Row[X].R + (MaskRow[X].R * 8 div 10)));
        Row[X].G := Byte(Min(255, Row[X].G + (MaskRow[X].G * 8 div 10)));
        Row[X].B := Byte(Min(255, Row[X].B + (MaskRow[X].B * 8 div 10)));
      end;
    end;
  finally
    Mask.Free;
    Blurred.Free;
  end;
end;

function ShowGlowDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TGlowDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
  Delta, Bottom: Integer;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := nil;
  try
    Dlg := TGlowDlg.Create(Application);
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
    Delta := Bottom - Dlg.lblRadius.Top;
    if Delta > 0 then
    begin
      Dlg.lblRadius.Top := Dlg.lblRadius.Top + Delta;
      Dlg.tbRadius.Top := Dlg.tbRadius.Top + Delta;
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
      gMacroPending.Code := 'GLOW';
      gMacroPending.Params := IntToStr(Dlg.tbRadius.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TGlowDlg }

procedure TGlowDlg.FormCreate(Sender: TObject);
begin
  // Bufor ekranu formy — bez tego podglądy (TPaintBox) migoczą przy każdej zmianie.
  DoubleBuffered := True;
  FZoomTimer := TTimer.Create(Self);
  FZoomTimer.Interval := 60;
  FZoomTimer.Enabled := False;
  FZoomTimer.OnTimer := ZoomTimerTick;
  tbRadius.Min := 1;
  tbRadius.Max := 20;
  tbRadius.Position := 5;
  lblValue.Caption := IntToStr(tbRadius.Position);
end;

procedure TGlowDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FEffBmp.Free;
end;

procedure TGlowDlg.tbRadiusChange(Sender: TObject);
begin
  lblValue.Caption := IntToStr(tbRadius.Position);
  ApplyPreview;
end;

procedure TGlowDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) or (FSourceBmp = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  DoGlow(FWorkingPreview, tbRadius.Position);
  FEffValid := False;   // zmiana parametrów — region podglądu 100% do przeliczenia
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TGlowDlg.ApplyFull;
begin
  DoGlow(FSourceBmp, tbRadius.Position);
end;

// Pipeline Blasku jest lokalny (maska per-piksel + rozmycie maski o promieniu
// Radius, potem addycyjny blend), więc wycinek z marginesem > Radius daje w
// oknie wynik zgodny z pełnym obrazem. Region cache'owany w FEffBmp.
procedure TGlowDlg.RenderFragment;
var
  Margin, X0, Y0, X1, Y1, CW, CH, dstX, dstY: Integer;
  SrcRegion: TBitmap;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  Margin := 20 + 32;
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
    try
      SrcRegion.PixelFormat := pf24bit;
      SrcRegion.SetSize(CW, CH);
      SrcRegion.Canvas.CopyRect(Rect(0, 0, CW, CH), FSourceBmp.Canvas,
        Rect(X0, Y0, X1 + 1, Y1 + 1));
      DoGlow(SrcRegion, tbRadius.Position);
      FEffBmp.Canvas.Draw(0, 0, SrcRegion);
    finally
      SrcRegion.Free;
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
end;

procedure TGlowDlg.RebuildZoom(X, Y: Integer);
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

procedure TGlowDlg.ZoomTimerTick(Sender: TObject);
begin
  FZoomTimer.Enabled := False;
  if FZoomDirty and (FZoomBmp <> nil) then
  begin
    RenderFragment;
    pboxZoom.Invalidate;
  end;
end;

// Pozycja ramki podglądu 100% w pikselach nawigatora (proporcje miniaturki).
function TGlowDlg.CursorRect: TRect;
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
procedure TGlowDlg.InvalidateNavRect(aRect: TRect);
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

procedure TGlowDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  // X, Y w pikselach pboxPreview => mapa do pikseli oryginału.
  ImgX := Round(X * FSourceBmp.Width / FNavW);
  ImgY := Round(Y * FSourceBmp.Height / FNavH);
  // Środek kursora = środek podglądu 100%.
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TGlowDlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

procedure TGlowDlg.pboxPreviewPaint(Sender: TObject);
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
