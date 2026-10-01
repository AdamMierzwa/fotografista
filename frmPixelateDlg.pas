unit frmPixelateDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TPixelateDlg = class(TFotoForm)
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

function ShowPixelateDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoPixelate(Bitmap: TBitmap; Pct: Integer);

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

const
  REFERENCE_WIDTH = 1000;

function ScaledRadius(SliderValue, ImageWidth: Integer): Integer;
begin
  Result := Max(1, Round(SliderValue * ImageWidth / REFERENCE_WIDTH));
end;

// Rdzen pikselizacji: blokowa srednia o zadanym rozmiarze komorki (w px),
// siatka zakotwiczona w (0,0). Cell jest absolutny, a nie liczony z szerokosci
// przekazanej bitmapy — wycinek z tym samym Cell i przyciety do wielokrotnosci
// Cell ma identyczna faze siatki jak pelny obraz.
procedure ApplyPixelate(Bitmap: TBitmap; Cell: Integer);
var
  W, H, X, Y, BX, BY, MaxX, MaxY, Count: Integer;
  SumR, SumG, SumB: Int64;
  Tmp: TBitmap;
  SrcLines, DstLines: array of PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  if Cell < 1 then Cell := 1;

  // ScanLine czytany jako 3 bajty/piksel (PRGBTripleArray) — wymus pf24bit.
  if Bitmap.PixelFormat <> pf24bit then
    Bitmap.PixelFormat := pf24bit;

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(W, H);

    SetLength(SrcLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      SrcLines[Y] := Bitmap.ScanLine[Y];
      DstLines[Y] := Tmp.ScanLine[Y];
    end;

    Y := 0;
    while Y < H do
    begin
      MaxY := Min(Y + Cell, H) - 1;
      X := 0;
      while X < W do
      begin
        MaxX := Min(X + Cell, W) - 1;
        SumR := 0; SumG := 0; SumB := 0; Count := 0;
        for BY := Y to MaxY do
          for BX := X to MaxX do
          begin
            Inc(SumR, SrcLines[BY][BX].R);
            Inc(SumG, SrcLines[BY][BX].G);
            Inc(SumB, SrcLines[BY][BX].B);
            Inc(Count);
          end;
        SumR := SumR div Count;
        SumG := SumG div Count;
        SumB := SumB div Count;
        for BY := Y to MaxY do
          for BX := X to MaxX do
          begin
            DstLines[BY][BX].R := Byte(SumR);
            DstLines[BY][BX].G := Byte(SumG);
            DstLines[BY][BX].B := Byte(SumB);
          end;
        X := MaxX + 1;
      end;
      Y := MaxY + 1;
    end;

    Bitmap.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

procedure DoPixelate(Bitmap: TBitmap; Pct: Integer);
// Pikselizacja: suwak 1..100 -> komorka 2..50 px w przeliczeniu na szerokosc
// 1000px. Komorka skaluje sie do szerokosci obrazu, wiec podglad (400px)
// wyglada tak samo wzglednie jak oryginal. Siatka od lewego-gornego rogu;
// ostatnie komorki przy krawedzi moga byc czesciowe.
begin
  if (Bitmap = nil) or (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;
  Pct := Max(1, Min(100, Pct));
  ApplyPixelate(Bitmap, Max(2, ScaledRadius(Pct div 2, Bitmap.Width)));
end;

function ShowPixelateDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TPixelateDlg;
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
    Dlg := TPixelateDlg.Create(Application);
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
      gMacroPending.Code := 'PIXELATE';
      gMacroPending.Params := IntToStr(Dlg.tbAmount.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TPixelateDlg }

procedure TPixelateDlg.FormCreate(Sender: TObject);
begin
  // Bufor ekranu formy — bez tego podglądy (TPaintBox) migoczą przy każdej zmianie.
  DoubleBuffered := True;
  FZoomTimer := TTimer.Create(Self);
  FZoomTimer.Interval := 60;
  FZoomTimer.Enabled := False;
  FZoomTimer.OnTimer := ZoomTimerTick;
  tbAmount.Min := 1;
  tbAmount.Max := 100;
  tbAmount.Position := 20;
  lblValue.Caption := IntToStr(tbAmount.Position);
end;

procedure TPixelateDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FEffBmp.Free;
end;

procedure TPixelateDlg.tbAmountChange(Sender: TObject);
begin
  lblValue.Caption := IntToStr(tbAmount.Position);
  ApplyPreview;
end;

procedure TPixelateDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) or (FSourceBmp = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  DoPixelate(FWorkingPreview, tbAmount.Position);
  FEffValid := False;   // zmiana parametrów — region podglądu 100% do przeliczenia
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TPixelateDlg.ApplyFull;
begin
  DoPixelate(FSourceBmp, tbAmount.Position);
end;

procedure TPixelateDlg.pboxPreviewPaint(Sender: TObject);
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
function TPixelateDlg.CursorRect: TRect;
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
procedure TPixelateDlg.InvalidateNavRect(aRect: TRect);
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

procedure TPixelateDlg.RebuildZoom(X, Y: Integer);
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

// Podgląd 100% — pikselizacja jest lokalna i deterministyczna względem siatki
// zakotwiczonej w (0,0) obrazu. Wycinek przycięty do wielokrotności Cell ma
// identyczną fazę siatki, więc ApplyPixelate na wycinku daje wynik zgodny z
// pełnym obrazem. Region (z zapasem) cache'owany w FEffBmp.
procedure TPixelateDlg.RenderFragment;
var
  Cell, Margin, X0, Y0, X1, Y1, CW, CH, dstX, dstY: Integer;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  Cell := Max(2, ScaledRadius(tbAmount.Position div 2, FSourceBmp.Width));
  Margin := Cell * 2;
  if Margin < 64 then Margin := 64;
  if (not FEffValid) or (FEffBmp = nil)
    or (FZoomX < FEffX) or (FZoomY < FEffY)
    or (FZoomX + FZoomW > FEffX + FEffW)
    or (FZoomY + FZoomH > FEffY + FEffH) then
  begin
    // Lewy/górny brzeg regionu przycięty do wielokrotności Cell — inaczej faza
    // siatki w wycinku rozjechałaby się z pełnym obrazem. Prawy/dolny brzeg ma
    // zapas >= 2*Cell, więc częściowe komórki przy nim są poza oknem podglądu.
    X0 := FZoomX - Margin;
    if X0 < 0 then X0 := 0;
    X0 := (X0 div Cell) * Cell;
    Y0 := FZoomY - Margin;
    if Y0 < 0 then Y0 := 0;
    Y0 := (Y0 div Cell) * Cell;
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
    FEffBmp.Canvas.CopyRect(Rect(0, 0, CW, CH), FSourceBmp.Canvas,
      Rect(X0, Y0, X1 + 1, Y1 + 1));
    ApplyPixelate(FEffBmp, Cell);
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

procedure TPixelateDlg.ZoomTimerTick(Sender: TObject);
begin
  FZoomTimer.Enabled := False;
  if FZoomDirty and (FZoomBmp <> nil) then
  begin
    RenderFragment;
    pboxZoom.Invalidate;
  end;
end;

procedure TPixelateDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  // X, Y w pikselach pboxPreview => mapa do pikseli oryginału.
  ImgX := Round(X * FSourceBmp.Width / FNavW);
  ImgY := Round(Y * FSourceBmp.Height / FNavH);
  // Środek kursora = środek podglądu 100%.
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TPixelateDlg.pboxZoomPaint(Sender: TObject);
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
