unit frmScreenPrintDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uPixelEngine, uTitleBar, uMacros;

type
  TScreenPrintDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    pboxZoom: TPaintBox;
    swInk: TShape;
    btnInk: TButton;
    swPaper: TShape;
    btnPaper: TButton;
    lblThresh: TLabel;
    tbThresh: TTrackBar;
    lblThreshVal: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pboxZoomPaint(Sender: TObject);
    procedure btnInkClick(Sender: TObject);
    procedure btnPaperClick(Sender: TObject);
    procedure tbThreshChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FInk: TColor;
    FPaper: TColor;
    FNavW, FNavH: Integer;
    FZoomW, FZoomH: Integer;
    FZoomX, FZoomY: Integer;
    FZoomBmp: TBitmap;
    FZoomTimer: TTimer;
    FZoomDirty: Boolean;
    procedure UpdateSwatches;
    procedure ApplyPreview;
    procedure ApplyFull;
    procedure RenderFragment;
    procedure RebuildZoom(X, Y: Integer);
    procedure ZoomTimerTick(Sender: TObject);
    function CursorRect: TRect;
    procedure InvalidateNavRect(aRect: TRect);
  end;

function ShowScreenPrintDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoScreenPrint(Bitmap: TBitmap; Ink, Paper: TColor; Threshold: Integer);

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

// Sitodruk jednokolorowy (p_RenderScreenPrint z image_fx_effects.hws:1415):
// grayscale + raster radialny (d2/Dmax2, Cell >= 2) -> piksel w kolorze tuszu albo papieru.
// Rdzeń działa na dowolnym bitmapie; Cell i fazę rastra (OffX/OffY) podaje
// wywołujący, żeby podgląd 1:1 mógł użyć parametrów z PEŁNEGO obrazu. Raster
// jest funkcją punktową (X, Y), więc wycinek z OffX/OffY daje wynik identyczny
// z pełnym obrazem (bez marginesu).
procedure ApplyScreenPrint(Bitmap: TBitmap; Ink, Paper: TColor;
  Threshold, Cell, OffX, OffY: Integer);
var
  W, H, X, Y, T: Integer;
  Ir, Ig, Ib, Pr, Pg, Pb: Integer;
  Lum, Coverage: Double;
  Tile: TScreenTile;
  Lines: array of PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  if Cell < 1 then Cell := 1;
  T := 4 * Cell;
  Tile := InitScreenTile(T);

  // TColor: $00BBGGRR -> składowe R/G/B
  Ir := (Ink and $0000FF);
  Ig := (Ink shr 8) and $FF;
  Ib := (Ink shr 16) and $FF;
  Pr := (Paper and $0000FF);
  Pg := (Paper shr 8) and $FF;
  Pb := (Paper shr 16) and $FF;

  SetLength(Lines, H);
  for Y := 0 to H - 1 do
    Lines[Y] := Bitmap.ScanLine[Y];

  for Y := 0 to H - 1 do
  begin
    for X := 0 to W - 1 do
    begin
      Lum := (Lines[Y][X].R * 299 + Lines[Y][X].G * 587 + Lines[Y][X].B * 114) / 1000.0;
      Lum := Lum + Threshold;
      if Lum < 0 then Lum := 0;
      if Lum > 255 then Lum := 255;
      Coverage := 1.0 - Lum / 255.0;
      if Coverage >= ScreenThresh(Tile, X + OffX, Y + OffY) then
      begin
        Lines[Y][X].R := Byte(Ir);
        Lines[Y][X].G := Byte(Ig);
        Lines[Y][X].B := Byte(Ib);
      end
      else
      begin
        Lines[Y][X].R := Byte(Pr);
        Lines[Y][X].G := Byte(Pg);
        Lines[Y][X].B := Byte(Pb);
      end;
    end;
  end;
end;

procedure DoScreenPrint(Bitmap: TBitmap; Ink, Paper: TColor; Threshold: Integer);
var
  W, H, Cell: Integer;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Cell := Max(2, Round(Sqrt(W * H) / 700.0));
  ApplyScreenPrint(Bitmap, Ink, Paper, Threshold, Cell, 0, 0);
end;

function ShowScreenPrintDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TScreenPrintDlg;
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
  Dlg := TScreenPrintDlg.Create(Application);
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
    Delta := Bottom - Dlg.swInk.Top;
    if Delta > 0 then
    begin
      Dlg.swInk.Top := Dlg.swInk.Top + Delta;
      Dlg.btnInk.Top := Dlg.btnInk.Top + Delta;
      Dlg.swPaper.Top := Dlg.swPaper.Top + Delta;
      Dlg.btnPaper.Top := Dlg.btnPaper.Top + Delta;
      Dlg.lblThresh.Top := Dlg.lblThresh.Top + Delta;
      Dlg.tbThresh.Top := Dlg.tbThresh.Top + Delta;
      Dlg.lblThreshVal.Top := Dlg.lblThreshVal.Top + Delta;
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
      gMacroPending.Code := 'SCREENPRINT';
      gMacroPending.Params := IntToStr(Integer(Dlg.FInk)) + '|' + IntToStr(Integer(Dlg.FPaper)) + '|' + IntToStr(Dlg.tbThresh.Position);
      Dlg.ApplyFull;
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TScreenPrintDlg }

procedure TScreenPrintDlg.FormCreate(Sender: TObject);
begin
  // Bufor ekranu formy — bez tego podglądy (TPaintBox) migoczą przy każdej zmianie.
  DoubleBuffered := True;
  FZoomTimer := TTimer.Create(Self);
  FZoomTimer.Interval := 60;
  FZoomTimer.Enabled := False;
  FZoomTimer.OnTimer := ZoomTimerTick;
  FInk := RGB(0, 0, 0);
  FPaper := RGB(255, 248, 240);
  tbThresh.Position := 0;
  lblThreshVal.Caption := IntToStr(tbThresh.Position);
  UpdateSwatches;
end;

procedure TScreenPrintDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
end;

procedure TScreenPrintDlg.UpdateSwatches;
begin
  swInk.Brush.Color := FInk;
  swPaper.Brush.Color := FPaper;
end;

procedure TScreenPrintDlg.btnInkClick(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FInk;
    if Dlg.Execute then
    begin
      FInk := Dlg.Color;
      UpdateSwatches;
      ApplyPreview;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TScreenPrintDlg.btnPaperClick(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FPaper;
    if Dlg.Execute then
    begin
      FPaper := Dlg.Color;
      UpdateSwatches;
      ApplyPreview;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TScreenPrintDlg.tbThreshChange(Sender: TObject);
begin
  lblThreshVal.Caption := IntToStr(tbThresh.Position);
  ApplyPreview;
end;

procedure TScreenPrintDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) or (FSourceBmp = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  DoScreenPrint(FWorkingPreview, FInk, FPaper, tbThresh.Position);
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TScreenPrintDlg.ApplyFull;
begin
  DoScreenPrint(FSourceBmp, FInk, FPaper, tbThresh.Position);
end;

procedure TScreenPrintDlg.pboxPreviewPaint(Sender: TObject);
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
function TScreenPrintDlg.CursorRect: TRect;
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
procedure TScreenPrintDlg.InvalidateNavRect(aRect: TRect);
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

procedure TScreenPrintDlg.RebuildZoom(X, Y: Integer);
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

// Podgląd 100% — raster jest funkcją punktową (X, Y), więc wycinek z Cell i fazą
// rastra (OffX/OffY) liczoną z PEŁNEGO obrazu daje wynik identyczny z pełnym
// obrazem, bez marginesu.
procedure TScreenPrintDlg.RenderFragment;
var
  X0, Y0, X1, Y1, CW, CH, Cell: Integer;
  SrcRegion: TBitmap;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  X0 := FZoomX;
  if X0 < 0 then X0 := 0;
  Y0 := FZoomY;
  if Y0 < 0 then Y0 := 0;
  X1 := FZoomX + FZoomW;
  if X1 > FSourceBmp.Width then X1 := FSourceBmp.Width;
  Y1 := FZoomY + FZoomH;
  if Y1 > FSourceBmp.Height then Y1 := FSourceBmp.Height;
  CW := X1 - X0;
  CH := Y1 - Y0;
  if (CW <= 0) or (CH <= 0) then Exit;
  Cell := Max(2, Round(Sqrt(FSourceBmp.Width * FSourceBmp.Height) / 700.0));
  SrcRegion := TBitmap.Create;
  try
    SrcRegion.PixelFormat := pf24bit;
    SrcRegion.SetSize(CW, CH);
    SrcRegion.Canvas.CopyRect(Rect(0, 0, CW, CH), FSourceBmp.Canvas,
      Rect(X0, Y0, X0 + CW, Y0 + CH));
    ApplyScreenPrint(SrcRegion, FInk, FPaper, tbThresh.Position, Cell, X0, Y0);
    FZoomBmp.Canvas.CopyRect(Rect(0, 0, CW, CH), SrcRegion.Canvas,
      Rect(0, 0, CW, CH));
  finally
    SrcRegion.Free;
  end;
  FZoomDirty := False;
end;

procedure TScreenPrintDlg.ZoomTimerTick(Sender: TObject);
begin
  FZoomTimer.Enabled := False;
  if FZoomDirty and (FZoomBmp <> nil) then
  begin
    RenderFragment;
    pboxZoom.Invalidate;
  end;
end;

procedure TScreenPrintDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  // X, Y w pikselach pboxPreview => mapa do pikseli oryginału.
  ImgX := Round(X * FSourceBmp.Width / FNavW);
  ImgY := Round(Y * FSourceBmp.Height / FNavH);
  // Środek kursora = środek podglądu 100%.
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TScreenPrintDlg.pboxZoomPaint(Sender: TObject);
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
