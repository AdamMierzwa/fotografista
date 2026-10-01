unit frmRastrCmykDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uRastrCMYK, uTitleBar;

type
  TRastrCmykDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    pboxZoom: TPaintBox;
    lblGrid: TLabel;
    tbGrid: TTrackBar;
    lblGridVal: TLabel;
    lblScale: TLabel;
    tbScale: TTrackBar;
    lblScaleVal: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxZoomPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure tbGridChange(Sender: TObject);
    procedure tbScaleChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FZoomBmp: TBitmap;
    FSize: Integer;
    FScale: Integer;
    FNavW, FNavH: Integer;
    FZoomX, FZoomY, FZoomW, FZoomH: Integer;
    FEffBmp: TBitmap;
    FEffValid: Boolean;
    FEffX, FEffY, FEffW, FEffH: Integer;
    procedure UpdateReadouts;
    procedure ApplyPreview;
    procedure ApplyFull;
    function CursorRect: TRect;
    procedure InvalidateNavRect(aRect: TRect);
    procedure RebuildZoom(X, Y: Integer);
    procedure RenderFragment;
  end;

function ShowRastrCmykDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

uses
  uMacros;

{$R *.dfm}

// Ustawienia sesji (jak g_rc_grid/g_rc_scale w Hollywood — nie zapisywane).
var
  RcGrid: Integer = 8;
  RcScale: Integer = 100;

function ShowRastrCmykDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TRastrCmykDlg;
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
  // Grid domyślny wg rozdzielczości wejścia (~240 komórek w poprzek, jak
  // Cell w uPixelEngine): małe zdjęcia dostają mniejszą komórkę, duże większą.
  RcGrid := Min(32, Max(1, Round(Sqrt(Bitmap.Width * Bitmap.Height) / 700.0) * 4));
  Dlg := TRastrCmykDlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;

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

    // Layout: nawigator po lewej, podgląd 100% obok. Dwa wiersze kontrolek
    // (komórka, skala) są dociskane w dół, gdy podglądy są wyższe niż w DFM.
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
    Delta := Bottom - Dlg.lblGrid.Top;
    if Delta > 0 then
    begin
      Dlg.lblGrid.Top := Dlg.lblGrid.Top + Delta;
      Dlg.tbGrid.Top := Dlg.tbGrid.Top + Delta;
      Dlg.lblGridVal.Top := Dlg.lblGridVal.Top + Delta;
      Dlg.lblScale.Top := Dlg.lblScale.Top + Delta;
      Dlg.tbScale.Top := Dlg.tbScale.Top + Delta;
      Dlg.lblScaleVal.Top := Dlg.lblScaleVal.Top + Delta;
      Dlg.btnOK.Top := Dlg.btnOK.Top + Delta;
      Dlg.btnCancel.Top := Dlg.btnCancel.Top + Delta;
    end;

    // Pola ustawiane jawnie — NIE polegać na OnChange z FormCreate, bo
    // SetPosition nie odpala zdarzenia gdy wartość równa się już wartości
    // z DFM (Vcl.ComCtrls.pas:13862), a wtedy FScale zostałoby 0 i rdzeń
    // nie postawiłby żadnej kropki (biały obraz).
    Dlg.FSize := Dlg.tbGrid.Position;
    Dlg.FScale := Dlg.tbScale.Position;
    Dlg.ApplyPreview;

    Dlg.FitToContent(Dlg.CtrlGap * 2, Dlg.CtrlGap * 3);

    // Wyśrodkowanie pary podglądów w szerokości okna. Szerokość okna wyznacza
    // najszerszy element (tbGrid/tbScale) — bez centrowania para leży przy
    // lewej krawędzi, a po prawej zostaje pas pustego tła.
    Dlg.pboxPreview.Left := (Dlg.ClientWidth - (pw + Dlg.CtrlGap * 2 + pw)) div 2;
    if Dlg.pboxPreview.Left < Dlg.CtrlGap then
      Dlg.pboxPreview.Left := Dlg.CtrlGap;
    Dlg.pboxZoom.Left := Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2;

    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      gMacroPending.Code := 'RASTRCMYK';
      gMacroPending.Params := IntToStr(Dlg.tbGrid.Position) + '|' + IntToStr(Dlg.tbScale.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TRastrCmykDlg }

procedure TRastrCmykDlg.FormCreate(Sender: TObject);
begin
  // Bufor ekranu formy — bez tego podglądy (TPaintBox) migoczą przy każdej
  // zmianie. To ustawienie robił dawniej FitPreviewToDialog (uPreviewFit.pas:38),
  // usunięty przy porcie wzorca podglądu.
  DoubleBuffered := True;
  tbGrid.Position := RcGrid;
  tbScale.Position := RcScale;
  UpdateReadouts;
end;

procedure TRastrCmykDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FEffBmp.Free;
end;

procedure TRastrCmykDlg.UpdateReadouts;
begin
  lblGridVal.Caption := IntToStr(tbGrid.Position);
  lblScaleVal.Caption := IntToStr(tbScale.Position) + ' %';
end;

procedure TRastrCmykDlg.tbGridChange(Sender: TObject);
begin
  UpdateReadouts;
  FSize := tbGrid.Position;
  ApplyPreview;
end;

procedure TRastrCmykDlg.tbScaleChange(Sender: TObject);
begin
  UpdateReadouts;
  FScale := tbScale.Position;
  ApplyPreview;
end;

procedure TRastrCmykDlg.ApplyPreview;
begin
  // OnChange z FormCreate (tbGrid.Position := RcGrid) odpala się PRZED
  // utworzeniem bitmap -> guard jak w innych dialogach.
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) or (FSourceBmp = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  DoRastrCmyk(FWorkingPreview, FSize, FScale);
  FEffValid := False;   // zmiana parametrów — region podglądu 100% do przeliczenia
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TRastrCmykDlg.ApplyFull;
begin
  DoRastrCmyk(FSourceBmp, tbGrid.Position, tbScale.Position);
  RcGrid := tbGrid.Position;
  RcScale := tbScale.Position;
end;

// Pozycja ramki podglądu 100% w pikselach nawigatora (proporcje miniaturki).
function TRastrCmykDlg.CursorRect: TRect;
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
procedure TRastrCmykDlg.InvalidateNavRect(aRect: TRect);
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

procedure TRastrCmykDlg.RebuildZoom(X, Y: Integer);
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

// Podgląd 100% — efekt Raster CMYK nie redukuje się do per-pikselowego LUT
// jak kafelki 45° (obrócone siatki, średnia okna GxG, corner-fill), więc
// wierny 1:1 robimy uruchamiając realny rdzeń (DoRastrCmyk) na regionie źródła
// powiększonym o margines = Rmax + Grid. Żeby jazda myszą nie przeliczała
// efektu od zera, region jest większy od okna (zapas) i cache'owany w FEffBmp:
// dopóki okno mieści się w zapamiętanym regionie, robimy tylko tani CopyRect;
// pełne przeliczenie startuje dopiero gdy okno wyjdzie poza region.
procedure TRastrCmykDlg.RenderFragment;
var
  Margin, X0, Y0, X1, Y1, CW, CH, dstX, dstY: Integer;
  Rmax: Double;
begin
  if (FZoomBmp = nil) or (FSourceBmp = nil) then Exit;
  Rmax := (FSize / 2.0) * Sqrt(2.0) * (FScale / 100.0);
  Margin := Trunc(Rmax) + FSize + 2;
  // Poza marginesem efektu zapas na ruch myszy (region cache), aby okno
  // zdążyło się przesunąć bez przeliczania efektu od nowa.
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
    DoRastrCmyk(FEffBmp, FSize, FScale);
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

procedure TRastrCmykDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  // X, Y w pikselach pboxPreview => mapa do pikseli oryginału.
  ImgX := Round(X * FSourceBmp.Width / FNavW);
  ImgY := Round(Y * FSourceBmp.Height / FNavH);
  // Środek kursora = środek podglądu 100%.
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TRastrCmykDlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

procedure TRastrCmykDlg.pboxPreviewPaint(Sender: TObject);
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