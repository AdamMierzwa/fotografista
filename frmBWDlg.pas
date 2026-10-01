unit frmBWDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uI18n, uTitleBar;

type
  TBWDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    pboxZoom: TPaintBox;
    lblBrightness: TLabel;
    tbBrightness: TTrackBar;
    lblBValue: TLabel;
    lblContrast: TLabel;
    tbContrast: TTrackBar;
    lblCValue: TLabel;
    rgDither: TRadioGroup;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pboxZoomPaint(Sender: TObject);
    procedure tbBrightnessChange(Sender: TObject);
    procedure tbContrastChange(Sender: TObject);
    procedure rgDitherClick(Sender: TObject);
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

function ShowBWDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoBlackWhite(Bitmap: TBitmap; BrightnessPct, ContrastRepeat: Integer; Dither: Boolean);

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

procedure DoBlackWhite(Bitmap: TBitmap; BrightnessPct, ContrastRepeat: Integer; Dither: Boolean);
var
  W, H, X, Y, I: Integer;
  Row: PRGBTripleArray;
  Factor: Double;
  Gray, NewVal, QErr: Integer;
  ErrLine, ErrNext: array of Integer;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  if BrightnessPct <> 100 then
  begin
    Factor := BrightnessPct / 100.0;
    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Row[X].R := Byte(Max(0, Min(255, Round(Row[X].R * Factor))));
        Row[X].G := Byte(Max(0, Min(255, Round(Row[X].G * Factor))));
        Row[X].B := Byte(Max(0, Min(255, Round(Row[X].B * Factor))));
      end;
    end;
  end;

  if ContrastRepeat > 0 then
  begin
    Factor := Power(1.1, ContrastRepeat);
    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Row[X].R := Byte(Max(0, Min(255, Round((Row[X].R - 128) * Factor + 128))));
        Row[X].G := Byte(Max(0, Min(255, Round((Row[X].G - 128) * Factor + 128))));
        Row[X].B := Byte(Max(0, Min(255, Round((Row[X].B - 128) * Factor + 128))));
      end;
    end;
  end;

  if Dither then
  begin
    SetLength(ErrLine, W + 2);
    SetLength(ErrNext, W + 2);
    for I := 0 to W + 1 do
    begin
      ErrLine[I] := 0;
      ErrNext[I] := 0;
    end;

    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Gray := Round(Row[X].R * 0.299 + Row[X].G * 0.587 + Row[X].B * 0.114)
              + ErrLine[X] div 16;
        if Gray < 0 then Gray := 0
        else if Gray > 255 then Gray := 255;

        NewVal := 255;
        if Gray < 128 then NewVal := 0;
        QErr := Gray - NewVal;

        Row[X].R := NewVal;
        Row[X].G := NewVal;
        Row[X].B := NewVal;

        ErrLine[X + 1] := ErrLine[X + 1] + QErr * 7;
        if X > 0 then ErrNext[X - 1] := ErrNext[X - 1] + QErr * 3;
        ErrNext[X] := ErrNext[X] + QErr * 5;
        ErrNext[X + 1] := ErrNext[X + 1] + QErr;
      end;
      for I := 0 to W + 1 do
      begin
        ErrLine[I] := ErrNext[I];
        ErrNext[I] := 0;
      end;
    end;
  end
  else
  begin
    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Gray := Round(Row[X].R * 0.299 + Row[X].G * 0.587 + Row[X].B * 0.114);
        NewVal := 255;
        if Gray < 128 then NewVal := 0;
        Row[X].R := NewVal;
        Row[X].G := NewVal;
        Row[X].B := NewVal;
      end;
    end;
  end;
end;

function ShowBWDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TBWDlg;
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
    Dlg := TBWDlg.Create(Application);
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
    Delta := Bottom - Dlg.lblBrightness.Top;
    if Delta > 0 then
    begin
      Dlg.lblBrightness.Top := Dlg.lblBrightness.Top + Delta;
      Dlg.tbBrightness.Top := Dlg.tbBrightness.Top + Delta;
      Dlg.lblBValue.Top := Dlg.lblBValue.Top + Delta;
      Dlg.lblContrast.Top := Dlg.lblContrast.Top + Delta;
      Dlg.tbContrast.Top := Dlg.tbContrast.Top + Delta;
      Dlg.lblCValue.Top := Dlg.lblCValue.Top + Delta;
      Dlg.rgDither.Top := Dlg.rgDither.Top + Delta;
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
      gMacroPending.Code := 'BW';
      gMacroPending.Params := IntToStr(Dlg.tbBrightness.Position) + '|'
        + IntToStr(Dlg.tbContrast.Position) + '|'
        + IntToStr(Ord(Dlg.rgDither.ItemIndex = 0));
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TBWDlg }

procedure TBWDlg.FormCreate(Sender: TObject);
begin
  // Bufor ekranu formy — bez tego podglądy (TPaintBox) migoczą przy każdej zmianie.
  DoubleBuffered := True;
  FZoomTimer := TTimer.Create(Self);
  FZoomTimer.Interval := 60;
  FZoomTimer.Enabled := False;
  FZoomTimer.OnTimer := ZoomTimerTick;
  rgDither.Items.Add(T('With dither (better quality)'));
  rgDither.Items.Add(T('Without dither'));
  rgDither.ItemIndex := 0;
  tbBrightness.Position := 100;
  tbContrast.Position := 0;
  lblBValue.Caption := IntToStr(tbBrightness.Position);
  lblCValue.Caption := IntToStr(tbContrast.Position);
end;

procedure TBWDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FEffBmp.Free;
end;

procedure TBWDlg.tbBrightnessChange(Sender: TObject);
begin
  lblBValue.Caption := IntToStr(tbBrightness.Position);
  ApplyPreview;
end;

procedure TBWDlg.tbContrastChange(Sender: TObject);
begin
  lblCValue.Caption := IntToStr(tbContrast.Position);
  ApplyPreview;
end;

procedure TBWDlg.rgDitherClick(Sender: TObject);
begin
  ApplyPreview;
end;

procedure TBWDlg.ApplyPreview;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) or (FSourceBmp = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  DoBlackWhite(FWorkingPreview, tbBrightness.Position, tbContrast.Position,
    rgDither.ItemIndex = 0);
  FEffValid := False;   // zmiana parametrów — region podglądu 100% do przeliczenia
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TBWDlg.ApplyFull;
begin
  DoBlackWhite(FSourceBmp, tbBrightness.Position, tbContrast.Position,
    rgDither.ItemIndex = 0);
end;

// Brightness/kontrast sa punktowe, wiec bez ditheringu wycinek 1:1 (margines 0)
// jest bit-identyczny z pelnym obrazem. Dither Floyd-Steinberg propaguje blad
// wzdluz wiersza i w dol — fragment nie jest wtedy bit-identyczny, ale margines
// >= 64 px daje rozbieg rozprzestrzeniania, wiec widoczne ziarno jest
// reprezentatywne. Region cache'owany w FEffBmp.
procedure TBWDlg.RenderFragment;
var
  Margin, X0, Y0, X1, Y1, CW, CH, dstX, dstY: Integer;
  SrcRegion: TBitmap;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  if rgDither.ItemIndex = 0 then
  begin
    Margin := 32;
    if Margin < 64 then Margin := 64;
  end
  else
    Margin := 0;
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
      DoBlackWhite(SrcRegion, tbBrightness.Position, tbContrast.Position,
        rgDither.ItemIndex = 0);
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
  FZoomDirty := False;
end;

procedure TBWDlg.RebuildZoom(X, Y: Integer);
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

procedure TBWDlg.ZoomTimerTick(Sender: TObject);
begin
  FZoomTimer.Enabled := False;
  if FZoomDirty and (FZoomBmp <> nil) then
  begin
    RenderFragment;
    pboxZoom.Invalidate;
  end;
end;

// Pozycja ramki podglądu 100% w pikselach nawigatora (proporcje miniaturki).
function TBWDlg.CursorRect: TRect;
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
procedure TBWDlg.InvalidateNavRect(aRect: TRect);
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

procedure TBWDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState;
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

procedure TBWDlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

procedure TBWDlg.pboxPreviewPaint(Sender: TObject);
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
