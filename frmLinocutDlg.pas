unit frmLinocutDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uConvolution, uTitleBar, uMacros;

type
  TLinocutDlg = class(TFotoForm)
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

function ShowLinocutDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoLinocut(Bitmap: TBitmap; Threshold: Integer);

implementation

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

// Unsharp mask z ustalonym promieniem (odpowiednik Hollywood SharpenBrush(tmp, 6)).
procedure SharpenFixedRadius(Bitmap: TBitmap; Radius: Integer);
var
  W, H, X, Y: Integer;
  Blurred: TBitmap;
  OrigLines, BlurLines: array of PRGBTripleArray;
begin
  if (Bitmap.Width = 0) or (Bitmap.Height = 0) or (Radius < 1) then Exit;

  Blurred := TBitmap.Create;
  try
    BoxBlur(Bitmap, Blurred, Radius);

    W := Bitmap.Width;
    H := Bitmap.Height;

    SetLength(OrigLines, H);
    SetLength(BlurLines, H);
    for Y := 0 to H - 1 do
    begin
      OrigLines[Y] := Bitmap.ScanLine[Y];
      BlurLines[Y] := Blurred.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        OrigLines[Y][X].R := Byte(Max(0, Min(255, OrigLines[Y][X].R + (OrigLines[Y][X].R - BlurLines[Y][X].R))));
        OrigLines[Y][X].G := Byte(Max(0, Min(255, OrigLines[Y][X].G + (OrigLines[Y][X].G - BlurLines[Y][X].G))));
        OrigLines[Y][X].B := Byte(Max(0, Min(255, OrigLines[Y][X].B + (OrigLines[Y][X].B - BlurLines[Y][X].B))));
      end;
  finally
    Blurred.Free;
  end;
end;

// Linoryt (p_LinocutCore z image_fx_effects.hws:793):
// grayscale -> Blur(3) -> Sharpen(6) -> próg > threshold*2 -> czerń/biel
procedure DoLinocut(Bitmap: TBitmap; Threshold: Integer);
var
  W, H, X, Y, Lum: Integer;
  Tmp, Blurred: TBitmap;
  Lines, TmpLines: array of PRGBTripleArray;
  Cut: Integer;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  Cut := Threshold * 2;

  Tmp := TBitmap.Create;
  try
    Tmp.Assign(Bitmap);
    Tmp.PixelFormat := pf24bit;

    // Grayscale (luma wg Hollywood BrushToGray)
    SetLength(Lines, H);
    for Y := 0 to H - 1 do
    begin
      Lines[Y] := Tmp.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Lum := (Lines[Y][X].R * 299 + Lines[Y][X].G * 587 + Lines[Y][X].B * 114) div 1000;
        Lines[Y][X].R := Byte(Lum);
        Lines[Y][X].G := Byte(Lum);
        Lines[Y][X].B := Byte(Lum);
      end;
    end;

    // Silne rozmycie usuwa drobne detale (BlurBrush(tmp, 3))
    Blurred := TBitmap.Create;
    try
      BoxBlur(Tmp, Blurred, 3);
      Tmp.Assign(Blurred);
    finally
      Blurred.Free;
    end;

    // Szerokie wyostrzenie = rowki dłuta na granicach płaszczyzn (SharpenBrush(tmp, 6))
    SharpenFixedRadius(Tmp, 6);

    // Kwantyzacja do 2 kolorów
    SetLength(TmpLines, H);
    for Y := 0 to H - 1 do
    begin
      TmpLines[Y] := Tmp.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        if TmpLines[Y][X].R > Cut then
        begin
          TmpLines[Y][X].R := 255;
          TmpLines[Y][X].G := 255;
          TmpLines[Y][X].B := 255;
        end
        else
        begin
          TmpLines[Y][X].R := 0;
          TmpLines[Y][X].G := 0;
          TmpLines[Y][X].B := 0;
        end;
      end;
    end;

    Bitmap.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

function ShowLinocutDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TLinocutDlg;
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
  Dlg := TLinocutDlg.Create(Application);
  try
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
      gMacroPending.Code := 'LINOCUT';
      gMacroPending.Params := IntToStr(Dlg.tbAmount.Position);
      Dlg.ApplyFull;
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TLinocutDlg }

procedure TLinocutDlg.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  tbAmount.Min := 1;
  tbAmount.Max := 100;
  tbAmount.Position := 50;
  lblValue.Caption := '50';
  FZoomTimer := TTimer.Create(Self);
  FZoomTimer.Interval := 60;
  FZoomTimer.Enabled := False;
  FZoomTimer.OnTimer := ZoomTimerTick;
end;

procedure TLinocutDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FEffBmp.Free;
end;

procedure TLinocutDlg.tbAmountChange(Sender: TObject);
begin
  lblValue.Caption := IntToStr(tbAmount.Position);
  ApplyPreview;
end;

// Pipeline Linorytu: BoxBlur(3) + unsharp o promieniu 6 + próg liczony z pary
// (Cut := Threshold*2, bez statystyk globalnych), wiec wycinek z marginesem
// wiekszym niz sumaryczny zasieg rozmyc daje wynik zgodny z pelnym obrazem.
procedure TLinocutDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) or (FSourceBmp = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  DoLinocut(FWorkingPreview, tbAmount.Position);
  FEffValid := False;
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TLinocutDlg.ApplyFull;
begin
  DoLinocut(FSourceBmp, tbAmount.Position);
end;

procedure TLinocutDlg.RenderFragment;
var
  Margin, X0, Y0, X1, Y1, CW, CH, dstX, dstY: Integer;
  SrcRegion: TBitmap;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  Margin := 3 + 6 + 32;
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
      DoLinocut(SrcRegion, tbAmount.Position);
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

procedure TLinocutDlg.RebuildZoom(X, Y: Integer);
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

procedure TLinocutDlg.ZoomTimerTick(Sender: TObject);
begin
  FZoomTimer.Enabled := False;
  if FZoomDirty and (FZoomBmp <> nil) then
  begin
    RenderFragment;
    pboxZoom.Invalidate;
  end;
end;

// Pozycja ramki podglądu 100% w pikselach nawigatora (proporcje miniaturki).
function TLinocutDlg.CursorRect: TRect;
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
procedure TLinocutDlg.InvalidateNavRect(aRect: TRect);
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

procedure TLinocutDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState;
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

procedure TLinocutDlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

procedure TLinocutDlg.pboxPreviewPaint(Sender: TObject);
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
