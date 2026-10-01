unit frmOleoDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TOleoDlg = class(TFotoForm)
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

function ShowOleoDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoOilPaint(Bitmap: TBitmap; Radius: Integer);

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
  OIL_LEVELS = 8;
  REFERENCE_WIDTH = 1000;

function ScaledRadius(SliderValue, ImageWidth: Integer): Integer;
begin
  Result := Max(1, Round(SliderValue * ImageWidth / REFERENCE_WIDTH));
end;

procedure DoOilPaint(Bitmap: TBitmap; Radius: Integer);
var
  W, H, X, Y, Col, YBot: Integer;
  Row: PRGBTripleArray;
  Src: TBitmap;
  SrcLines: array of PRGBTripleArray;
  ColCount: array of array[0..OIL_LEVELS - 1] of Integer;
  ColSumR, ColSumG, ColSumB: array of array[0..OIL_LEVELS - 1] of Integer;
  WinCount: array[0..OIL_LEVELS - 1] of Integer;
  WinSumR, WinSumG, WinSumB: array[0..OIL_LEVELS - 1] of Integer;
  Bucket, Best, Cnt, Left, Right, Lum: Integer;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  if Radius < 1 then Radius := 1;

  Src := TBitmap.Create;
  try
    Src.Assign(Bitmap);
    Src.PixelFormat := pf24bit;
    SetLength(SrcLines, H);
    for Y := 0 to H - 1 do
      SrcLines[Y] := Src.ScanLine[Y];

    SetLength(ColCount, W);
    SetLength(ColSumR, W);
    SetLength(ColSumG, W);
    SetLength(ColSumB, W);
    for X := 0 to W - 1 do
    begin
      FillChar(ColCount[X], SizeOf(ColCount[X]), 0);
      FillChar(ColSumR[X], SizeOf(ColSumR[X]), 0);
      FillChar(ColSumG[X], SizeOf(ColSumG[X]), 0);
      FillChar(ColSumB[X], SizeOf(ColSumB[X]), 0);
    end;

    // Wiersze 0..min(R, H-1): pionowe okna dla pierwszego wiersza
    YBot := Min(Radius, H - 1);
    for Y := 0 to YBot do
    begin
      Row := SrcLines[Y];
      for X := 0 to W - 1 do
      begin
        Lum := (Row[X].R + Row[X].G + Row[X].B) div 3;
        Bucket := Lum * OIL_LEVELS div 256;
        Inc(ColCount[X][Bucket]);
        Inc(ColSumR[X][Bucket], Row[X].R);
        Inc(ColSumG[X][Bucket], Row[X].G);
        Inc(ColSumB[X][Bucket], Row[X].B);
      end;
    end;

    for Y := 0 to H - 1 do
    begin
      // Przesuw pionowy: usuń wiersz Y-R-1, dodaj wiersz Y+R
      if Y > 0 then
      begin
        if (Y - Radius - 1) >= 0 then
        begin
          Row := SrcLines[Y - Radius - 1];
          for X := 0 to W - 1 do
          begin
            Lum := (Row[X].R + Row[X].G + Row[X].B) div 3;
            Bucket := Lum * OIL_LEVELS div 256;
            Dec(ColCount[X][Bucket]);
            Dec(ColSumR[X][Bucket], Row[X].R);
            Dec(ColSumG[X][Bucket], Row[X].G);
            Dec(ColSumB[X][Bucket], Row[X].B);
          end;
        end;
        if (Y + Radius) < H then
        begin
          Row := SrcLines[Y + Radius];
          for X := 0 to W - 1 do
          begin
            Lum := (Row[X].R + Row[X].G + Row[X].B) div 3;
            Bucket := Lum * OIL_LEVELS div 256;
            Inc(ColCount[X][Bucket]);
            Inc(ColSumR[X][Bucket], Row[X].R);
            Inc(ColSumG[X][Bucket], Row[X].G);
            Inc(ColSumB[X][Bucket], Row[X].B);
          end;
        end;
      end;

      // Poziome okno: kolumny 0..min(R, W-1)
      Left := 0;
      Right := Min(Radius, W - 1);
      FillChar(WinCount, SizeOf(WinCount), 0);
      FillChar(WinSumR, SizeOf(WinSumR), 0);
      FillChar(WinSumG, SizeOf(WinSumG), 0);
      FillChar(WinSumB, SizeOf(WinSumB), 0);
      for Col := Left to Right do
        for Bucket := 0 to OIL_LEVELS - 1 do
        begin
          Inc(WinCount[Bucket], ColCount[Col][Bucket]);
          Inc(WinSumR[Bucket], ColSumR[Col][Bucket]);
          Inc(WinSumG[Bucket], ColSumG[Col][Bucket]);
          Inc(WinSumB[Bucket], ColSumB[Col][Bucket]);
        end;

      Row := Bitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Best := 0;
        for Bucket := 1 to OIL_LEVELS - 1 do
          if WinCount[Bucket] > WinCount[Best] then Best := Bucket;
        Cnt := WinCount[Best];
        if Cnt > 0 then
        begin
          Row[X].R := Byte(WinSumR[Best] div Cnt);
          Row[X].G := Byte(WinSumG[Best] div Cnt);
          Row[X].B := Byte(WinSumB[Best] div Cnt);
        end;

        // Przesuw poziomy: usuń kolumnę X-R, dodaj kolumnę X+R+1
        if X < W - 1 then
        begin
          if (X - Radius) >= 0 then
            for Bucket := 0 to OIL_LEVELS - 1 do
            begin
              Dec(WinCount[Bucket], ColCount[X - Radius][Bucket]);
              Dec(WinSumR[Bucket], ColSumR[X - Radius][Bucket]);
              Dec(WinSumG[Bucket], ColSumG[X - Radius][Bucket]);
              Dec(WinSumB[Bucket], ColSumB[X - Radius][Bucket]);
            end;
          if (X + Radius + 1) < W then
            for Bucket := 0 to OIL_LEVELS - 1 do
            begin
              Inc(WinCount[Bucket], ColCount[X + Radius + 1][Bucket]);
              Inc(WinSumR[Bucket], ColSumR[X + Radius + 1][Bucket]);
              Inc(WinSumG[Bucket], ColSumG[X + Radius + 1][Bucket]);
              Inc(WinSumB[Bucket], ColSumB[X + Radius + 1][Bucket]);
            end;
        end;
      end;
    end;
  finally
    Src.Free;
  end;
end;

function ShowOleoDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TOleoDlg;
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
    Dlg := TOleoDlg.Create(Application);
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
      gMacroPending.Code := 'OILPAINT';
      gMacroPending.Params := IntToStr(ScaledRadius(Dlg.tbAmount.Position, Bitmap.Width));
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TOleoDlg }

procedure TOleoDlg.FormCreate(Sender: TObject);
begin
  // Bufor ekranu formy — bez tego podglądy (TPaintBox) migoczą przy każdej zmianie.
  DoubleBuffered := True;
  FZoomTimer := TTimer.Create(Self);
  FZoomTimer.Interval := 60;
  FZoomTimer.Enabled := False;
  FZoomTimer.OnTimer := ZoomTimerTick;
  tbAmount.Min := 1;
  tbAmount.Max := 10;
  tbAmount.Position := 3;
  lblValue.Caption := IntToStr(tbAmount.Position);
end;

procedure TOleoDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FEffBmp.Free;
end;

procedure TOleoDlg.tbAmountChange(Sender: TObject);
begin
  lblValue.Caption := IntToStr(tbAmount.Position);
  ApplyPreview;
end;

procedure TOleoDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) or (FSourceBmp = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  DoOilPaint(FWorkingPreview, ScaledRadius(tbAmount.Position, FWorkingPreview.Width));
  FEffValid := False;   // zmiana parametrów — region podglądu 100% do przeliczenia
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TOleoDlg.ApplyFull;
begin
  DoOilPaint(FSourceBmp, ScaledRadius(tbAmount.Position, FSourceBmp.Width));
end;

procedure TOleoDlg.pboxPreviewPaint(Sender: TObject);
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
function TOleoDlg.CursorRect: TRect;
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
procedure TOleoDlg.InvalidateNavRect(aRect: TRect);
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

procedure TOleoDlg.RebuildZoom(X, Y: Integer);
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

// Podgląd 100% — efekt oleju to okno (2R+1)^2 (suma przesuwna), więc wierny
// 1:1 robimy uruchamiając realny rdzeń (DoOilPaint) na regionie źródła
// powiększonym o margines = promień. Wszystkie odczyty są lokalne, a okno jest
// obcinane (nie replikowane) na brzegu, więc z marginesem wnętrze fragmentu
// jest identyczne z pełnym przeliczeniem. Region jest większy od okna i
// cache'owany w FEffBmp: dopóki okno mieści się w zapamiętanym regionie, robimy
// tylko tani CopyRect.
procedure TOleoDlg.RenderFragment;
var
  Margin, X0, Y0, X1, Y1, CW, CH, dstX, dstY, Radius: Integer;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  Radius := ScaledRadius(tbAmount.Position, FSourceBmp.Width);
  Margin := Radius + 6;
  if Margin < 64 then Margin := 64;
  if (not FEffValid) or (FEffBmp = nil)
    or (FZoomX < FEffX) or (FZoomY < FEffY)
    or (FZoomX + FZoomW > FEffX + FEffW)
    or (FZoomY + FZoomH > FEffY + FEffH) then
  begin
    X0 := FZoomX - Margin;
    Y0 := FZoomY - Margin;
    X1 := FZoomX + FZoomW + Margin;
    Y1 := FZoomY + FZoomH + Margin;
    if X0 < 0 then X0 := 0;
    if Y0 < 0 then Y0 := 0;
    if X1 > FSourceBmp.Width - 1 then X1 := FSourceBmp.Width - 1;
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
    DoOilPaint(FEffBmp, Radius);
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

procedure TOleoDlg.ZoomTimerTick(Sender: TObject);
begin
  FZoomTimer.Enabled := False;
  if FZoomDirty and (FZoomBmp <> nil) then
  begin
    RenderFragment;
    pboxZoom.Invalidate;
  end;
end;

procedure TOleoDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  // X, Y w pikselach pboxPreview => mapa do pikseli oryginału.
  ImgX := Round(X * FSourceBmp.Width / FNavW);
  ImgY := Round(Y * FSourceBmp.Height / FNavH);
  // Środek kursora = środek podglądu 100%.
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TOleoDlg.pboxZoomPaint(Sender: TObject);
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
