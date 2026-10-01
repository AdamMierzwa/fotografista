unit frmEngravingDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uTitleBar;

type
  TEngravingTileMap = array of array of Byte;

  TEngravingDlg = class(TFotoForm)
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
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxZoomPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure tbAngleChange(Sender: TObject);
    procedure tbCellChange(Sender: TObject);
    procedure tbThickChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FMapBmp: TBitmap;
    FZoomBmp: TBitmap;
    FTiles: TEngravingTileMap;
    FTileSize: Integer;
    FAngleSize: Integer;
    FThickSize: Integer;
    FSize: Integer;
    FAngle: Integer;
    FThick: Integer;
    FNavW, FNavH: Integer;
    FZoomX, FZoomY, FZoomW, FZoomH: Integer;
    procedure ApplyPreview;
    procedure ApplyFull;
    function CursorRect: TRect;
    procedure InvalidateNavRect(aRect: TRect);
    procedure RebuildZoom(X, Y: Integer);
    procedure RebuildZoomCache;
    procedure RenderFragment;
  end;

function ShowEngravingDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoEngraving(Bitmap: TBitmap; Angle, CellSize, MaxThick: Integer);

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

// Ryt grawerski (p_EngravingCore + p_ApplyTiles z image_fx_effects.hws:488).
// Buduje N=SIZE kafli SIZE×SIZE — kreski pod kątem angle, grubość =
// Int(lv*max_thick/Max(1,N-1)). 0 = czarny, 255 = biały. Wspólne dla
// DoEngraving (miniaturka / pełny obraz) i cache podglądu 100%.
procedure BuildEngravingTiles(Angle, CellSize, MaxThick: Integer; out SIZE: Integer;
  out tiles: TEngravingTileMap);
var
  N, lv, ti, tj, phase, raw, thickness: Integer;
  alpha, sin_a, cos_a: Double;
begin
  SIZE := CellSize;
  if SIZE < 4 then SIZE := 4;
  if SIZE > 16 then SIZE := 16;
  N := SIZE;
  if MaxThick < 1 then MaxThick := 1;
  if MaxThick > 8 then MaxThick := 8;

  alpha := Angle * Pi / 180.0;
  sin_a := Sin(alpha);
  cos_a := Cos(alpha);

  SetLength(tiles, N);
  for lv := 0 to N - 1 do
  begin
    SetLength(tiles[lv], SIZE * SIZE);
    thickness := Trunc(lv * MaxThick / Max(1, N - 1));
    for tj := 0 to SIZE - 1 do
      for ti := 0 to SIZE - 1 do
      begin
        raw := Trunc(ti * sin_a - tj * cos_a + 1000.0 * SIZE);
        phase := raw mod SIZE;
        if phase < 0 then phase := phase + SIZE;
        if phase < thickness then
          tiles[lv][tj * SIZE + ti] := 0
        else
          tiles[lv][tj * SIZE + ti] := 255;
      end;
  end;
end;

procedure DoEngraving(Bitmap: TBitmap; Angle, CellSize, MaxThick: Integer);
var
  W, H, SIZE, NTiles, cols, rows, lv, ti, tj, ti2, tj2: Integer;
  tiles: TEngravingTileMap;
  small: TBitmap;
  smallLines: array of PRGBTripleArray;
  outLines: array of PRGBTripleArray;
  gray, px: Integer;
  X, Y: Integer;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  BuildEngravingTiles(Angle, CellSize, MaxThick, SIZE, tiles);
  NTiles := Length(tiles);

  // Sufit (nie podłoga): częściowy kafelek przy krawędzi jest renderowany
  // w całości — inaczej na krawędzi obrazu zostaje biały pasek.
  cols := (W + SIZE - 1) div SIZE;
  rows := (H + SIZE - 1) div SIZE;

  // Downscale źródła do siatki cols×rows (ScaleBrush(small, cols, rows, True))
  small := TBitmap.Create;
  try
    small.PixelFormat := pf24bit;
    small.SetSize(cols, rows);
    small.Canvas.StretchDraw(Rect(0, 0, cols, rows), Bitmap);

    SetLength(smallLines, rows);
    for Y := 0 to rows - 1 do
      smallLines[Y] := small.ScanLine[Y];

    SetLength(outLines, H);
    for Y := 0 to H - 1 do
      outLines[Y] := Bitmap.ScanLine[Y];

    // Tło białe (p_ApplyTiles: bg_color = $FFFFFF)
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        outLines[Y][X].R := 255;
        outLines[Y][X].G := 255;
        outLines[Y][X].B := 255;
      end;

    // Każda komórka dostaje kafel wg luminancji
    for tj2 := 0 to rows - 1 do
      for ti2 := 0 to cols - 1 do
      begin
        px := smallLines[tj2][ti2].R;
        gray := (px * 299 + smallLines[tj2][ti2].G * 587 + smallLines[tj2][ti2].B * 114) div 1000;
        lv := Trunc((255 - gray) * NTiles / 256);
        if lv < 0 then lv := 0;
        if lv > NTiles - 1 then lv := NTiles - 1;

        for tj := 0 to SIZE - 1 do
        begin
          Y := tj2 * SIZE + tj;
          if Y >= H then Break;
          for ti := 0 to SIZE - 1 do
          begin
            X := ti2 * SIZE + ti;
            if X >= W then Break;
            if tiles[lv][tj * SIZE + ti] = 0 then
            begin
              outLines[Y][X].R := 0;
              outLines[Y][X].G := 0;
              outLines[Y][X].B := 0;
            end;
          end;
        end;
      end;
  finally
    small.Free;
  end;
end;

function ShowEngravingDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TEngravingDlg;
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
  Dlg := TEngravingDlg.Create(Application);
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

    // Layout: nawigator po lewej, podgląd 100% obok. Trzy wiersze kontrolek
    // (kąt, rozmiar komórki, grubość) są dociskane w dół, gdy podglądy są
    // wyższe niż w DFM.
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
      Dlg.btnOK.Top := Dlg.btnOK.Top + Delta;
      Dlg.btnCancel.Top := Dlg.btnCancel.Top + Delta;
    end;

    Dlg.FAngle := Dlg.tbAngle.Position;
    Dlg.FSize := Dlg.tbCell.Position;
    Dlg.FThick := Dlg.tbThick.Position;
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
      gMacroPending.Code := 'ENGRAVING';
      gMacroPending.Params := IntToStr(Dlg.tbAngle.Position) + '|' + IntToStr(Dlg.tbCell.Position) + '|' + IntToStr(Dlg.tbThick.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TEngravingDlg }

procedure TEngravingDlg.FormCreate(Sender: TObject);
begin
  // Bufor ekranu formy — bez tego podglądy (TPaintBox) migoczą przy każdej
  // zmianie. To ustawienie robił dawniej FitPreviewToDialog (uPreviewFit.pas:38),
  // usunięty przy porcie wzorca podglądu.
  DoubleBuffered := True;
  tbAngle.Position := 45;
  tbCell.Position := 8;
  tbThick.Position := 5;
  lblAngleVal.Caption := IntToStr(tbAngle.Position);
  lblCellVal.Caption := IntToStr(tbCell.Position);
  lblThickVal.Caption := IntToStr(tbThick.Position);
end;

procedure TEngravingDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FMapBmp.Free;
end;

procedure TEngravingDlg.tbAngleChange(Sender: TObject);
begin
  lblAngleVal.Caption := IntToStr(tbAngle.Position);
  FAngle := tbAngle.Position;
  ApplyPreview;
end;

procedure TEngravingDlg.tbCellChange(Sender: TObject);
begin
  lblCellVal.Caption := IntToStr(tbCell.Position);
  FSize := tbCell.Position;
  ApplyPreview;
end;

procedure TEngravingDlg.tbThickChange(Sender: TObject);
begin
  lblThickVal.Caption := IntToStr(tbThick.Position);
  FThick := tbThick.Position;
  ApplyPreview;
end;

procedure TEngravingDlg.ApplyPreview;
begin
  if FSourceBmp = nil then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  DoEngraving(FWorkingPreview, FAngle, FSize, FThick);
  RebuildZoomCache;
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TEngravingDlg.ApplyFull;
begin
  DoEngraving(FSourceBmp, tbAngle.Position, tbCell.Position, tbThick.Position);
end;

// Pozycja ramki podglądu 100% w pikselach nawigatora (proporcje miniaturki).
function TEngravingDlg.CursorRect: TRect;
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
procedure TEngravingDlg.InvalidateNavRect(aRect: TRect);
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

procedure TEngravingDlg.RebuildZoom(X, Y: Integer);
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

// Podgląd 100% — bufory podręczne dla RenderFragment. Mapę (próbkowanie
// oryginału przez StretchDraw w skali komórki, po jednej próbce na kafelek)
// i LUT kafli przebudowuje się tylko przy zmianie kąta, rozmiaru komórki lub
// grubości kreski, więc jazda myszą nie przelicza całego obrazu.
procedure TEngravingDlg.RebuildZoomCache;
var
  sW, sH: Integer;
begin
  if FSourceBmp = nil then Exit;
  if (FMapBmp <> nil) and (FTileSize = FSize) and (FAngleSize = FAngle)
    and (FThickSize = FThick) then Exit;
  sW := FSourceBmp.Width;
  sH := FSourceBmp.Height;
  BuildEngravingTiles(FAngle, FSize, FThick, FTileSize, FTiles);
  FAngleSize := FAngle;
  FThickSize := FThick;
  if FMapBmp = nil then
    FMapBmp := TBitmap.Create;
  FMapBmp.PixelFormat := pf24bit;
  // Sufit: częściowy kafelek przy krawędzi obrazu ma próbkę w mapie.
  FMapBmp.SetSize((sW + FTileSize - 1) div FTileSize, (sH + FTileSize - 1) div FTileSize);
  FMapBmp.Canvas.StretchDraw(Rect(0, 0, FMapBmp.Width, FMapBmp.Height), FSourceBmp);
end;

// Renderuje fragment FZoomBmp (1:1, wymiary nawigatora) z globalnym offsetem
// FZoomX/FZoomY w obrazie źródłowym. Obszar poza obrazem — biały.
procedure TEngravingDlg.RenderFragment;
var
  W, H, SIZE, cols, rows, lv, ti2, tj2, tx, ty, nTiles: Integer;
  Black: Boolean;
  mapLines: array of PRGBTripleArray;
  outLines: array of PRGBTripleArray;
  X, Y, gx, gy, px, gray: Integer;
begin
  if (FZoomBmp = nil) or (FMapBmp = nil) or (FSourceBmp = nil) then Exit;
  W := FZoomBmp.Width;
  H := FZoomBmp.Height;
  SIZE := FTileSize;
  if SIZE <= 0 then Exit;
  nTiles := Length(FTiles);
  if nTiles = 0 then Exit;
  cols := FMapBmp.Width;
  rows := FMapBmp.Height;
  SetLength(mapLines, rows);
  for Y := 0 to rows - 1 do
    mapLines[Y] := FMapBmp.ScanLine[Y];
  SetLength(outLines, H);
  for Y := 0 to H - 1 do
    outLines[Y] := FZoomBmp.ScanLine[Y];
  for Y := 0 to H - 1 do
  begin
    gy := FZoomY + Y;
    if (gy >= 0) and (gy < FSourceBmp.Height) then
    begin
      tj2 := gy div SIZE;
      if tj2 < rows then
      begin
        for X := 0 to W - 1 do
        begin
          gx := FZoomX + X;
          Black := False;
          if (gx >= 0) and (gx < FSourceBmp.Width) then
          begin
            ti2 := gx div SIZE;
            if ti2 < cols then
            begin
              px := mapLines[tj2][ti2].R;
              gray := (px * 299 + mapLines[tj2][ti2].G * 587 + mapLines[tj2][ti2].B * 114) div 1000;
              lv := Trunc((255 - gray) * nTiles / 256);
              if lv < 0 then lv := 0;
              if lv > nTiles - 1 then lv := nTiles - 1;
              tx := gx - ti2 * SIZE;
              ty := gy - tj2 * SIZE;
              Black := FTiles[lv][ty * SIZE + tx] = 0;
            end;
          end;
          if Black then
          begin
            outLines[Y][X].R := 0;
            outLines[Y][X].G := 0;
            outLines[Y][X].B := 0;
          end
          else
          begin
            outLines[Y][X].R := 255;
            outLines[Y][X].G := 255;
            outLines[Y][X].B := 255;
          end;
        end;
        Continue;
      end;
    end;
    for X := 0 to W - 1 do
    begin
      outLines[Y][X].R := 255;
      outLines[Y][X].G := 255;
      outLines[Y][X].B := 255;
    end;
  end;
end;

procedure TEngravingDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  // X, Y w pikselach pboxPreview => mapa do pikseli oryginału.
  ImgX := Round(X * FSourceBmp.Width / FNavW);
  ImgY := Round(Y * FSourceBmp.Height / FNavH);
  // Środek kursora = środek podglądu 100%.
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TEngravingDlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

procedure TEngravingDlg.pboxPreviewPaint(Sender: TObject);
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
