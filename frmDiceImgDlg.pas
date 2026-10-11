unit frmDiceImgDlg;

// Obraz z kostek do gry: mozaika kostek 1-6 oczek (6 poziomow jasnosci).
// Rozmiar komorki z suwaka: 24..40 px, krok 2 (jedna kostka, bez wyboru rozmiaru).
// Komorka = sciana kostki + 1 px biala przerwa. Wzorzec oczka jest jeden
// (maska stamp), wstawiany w calkowitych wspolrzednych - wszystkie oczka
// jednej kostki maja identyczny ksztalt. Kalkulator: liczba kostek = kolumny x wiersze.

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, uTitleBar;

type
  TDiceImgTile = array of Byte;               // Cell*Cell: 0 = czarne, 255 = biale
  TDiceImgTileMap = array of TDiceImgTile;    // [lv]

  TDiceImgDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    pboxZoom: TPaintBox;
    lblCell: TLabel;
    tbCell: TTrackBar;
    lblCellVal: TLabel;
    lblCount: TLabel;
    lblCountVal: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxZoomPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure tbCellChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FMapBmp: TBitmap;
    FZoomBmp: TBitmap;
    FTiles: TDiceImgTileMap;
    FTileSize: Integer;
    FCell: Integer;
    FNavW, FNavH: Integer;
    FZoomX, FZoomY, FZoomW, FZoomH: Integer;
    procedure ApplyPreview;
    procedure ApplyFull;
    procedure UpdateCount;
    function CursorRect: TRect;
    procedure InvalidateNavRect(aRect: TRect);
    procedure RebuildZoom(X, Y: Integer);
    procedure RebuildZoomCache;
    procedure RenderFragment;
  end;

function ShowDiceImgDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoDiceImage(Bitmap: TBitmap; CellSize: Integer);
function DiceImgCount(W, H, CellSize: Integer): Int64;

implementation

uses
  uMacros, uI18n;

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
  DICE_IMG_LEVELS = 6;   // poziomy jasnosci = 1..6 oczek
  DICE_IMG_LARGE = 32;   // domyslna komorka (suwak: 24..64 px, krok 2)

// Liczba kostek = kolumny x wiersze (sufit: czesciowa kostka przy krawedzi tez sie liczy).
function DiceImgCount(W, H, CellSize: Integer): Int64;
begin
  Result := Int64((W + CellSize - 1) div CellSize) * Int64((H + CellSize - 1) div CellSize);
end;

// Wzorzec oczka dla rozmiaru komorki (cell = sciana + 1 px przerwa).
// Sciana F = Cell - 1, srodek M = (F - 1) div 2 (dla parzystych Cell, czyli
// nieparzystego F, srodek wzoru lezy dokladnie na pikselu).
// R = Round(F / 11), zmniejszane tak, by oczka mialy co najmniej 3 px marginesu od
// krawedzi sciany (odstep miedzy oczkami sasiednich kostek = 2*3+1 = 7 px).
// Od 24 px wzwyz; mniejsze komorki wymagalyby krzyzykow (R=1) lub mniejszego marginesu.
// Thr = R*R + R div 2 (kolo); odstep srodkow D = 2R + 2 (1 px przerwy).
// Dla 24 i 32 px: R = 2 / 3, Thr = 5 / 10, D = 6 / 8.
procedure DiceImgPipParams(CellSize: Integer; out Thr, R, D: Integer);
var
  F, M: Integer;
begin
  F := CellSize - 1;
  M := (F - 1) div 2;
  R := Max(1, Round(F / 11));
  while (R > 1) and (M - (2 * R + 2) - R < 3) do
    Dec(R);
  Thr := R * R + R div 2;
  D := 2 * R + 2;
end;

// Kafle kostek: dla kazdego poziomu lv (n = 6 - lv oczek) tablica Cell*Cell.
// Ostatnia kolumna i wiersz komorki = biala przerwa (255).
procedure BuildDiceImgTiles(CellSize: Integer; out Tiles: TDiceImgTileMap);
var
  Face, Thr, R, D, M, lv, n: Integer;
  Tl: TDiceImgTile;
  ti, tj: Integer;

  procedure Stamp(CX, CY: Integer);
  var
    sx, sy: Integer;
  begin
    for sy := -R to R do
      for sx := -R to R do
        if sx * sx + sy * sy <= Thr then
          Tl[(CY + sy) * CellSize + (CX + sx)] := 255;
  end;

  procedure Pips(N: Integer);
  begin
    case N of
      1: Stamp(M, M);
      2: begin Stamp(M + D, M - D); Stamp(M - D, M + D); end;
      3: begin Stamp(M + D, M - D); Stamp(M, M); Stamp(M - D, M + D); end;
      4: begin Stamp(M - D, M - D); Stamp(M + D, M - D); Stamp(M - D, M + D); Stamp(M + D, M + D); end;
      5: begin Stamp(M - D, M - D); Stamp(M + D, M - D); Stamp(M, M); Stamp(M - D, M + D); Stamp(M + D, M + D); end;
      6: begin Stamp(M - D, M - D); Stamp(M - D, M); Stamp(M - D, M + D);
           Stamp(M + D, M - D); Stamp(M + D, M); Stamp(M + D, M + D); end;
    end;
  end;

begin
  DiceImgPipParams(CellSize, Thr, R, D);
  Face := CellSize - 1;
  M := (Face - 1) div 2;
  SetLength(Tiles, DICE_IMG_LEVELS);
  for lv := 0 to DICE_IMG_LEVELS - 1 do
  begin
    n := DICE_IMG_LEVELS - lv;
    SetLength(Tl, CellSize * CellSize);
    for tj := 0 to CellSize - 1 do
      for ti := 0 to CellSize - 1 do
        if (ti = Face) or (tj = Face) then
          Tl[tj * CellSize + ti] := 255
        else
          Tl[tj * CellSize + ti] := 0;
    Pips(n);
    Tiles[lv] := Copy(Tl, 0, Length(Tl));
  end;
end;

procedure DoDiceImage(Bitmap: TBitmap; CellSize: Integer);
var
  W, H, cols, rows, lv, ti, tj, ti2, tj2, X, Y, gray: Integer;
  tiles: TDiceImgTileMap;
  small: TBitmap;
  smallLines: array of PRGBTripleArray;
  outLines: array of PRGBTripleArray;
  C: Byte;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  BuildDiceImgTiles(CellSize, tiles);

  // Sufit: czesciowa kostka przy krawedzi jest renderowana w calosci.
  cols := (W + CellSize - 1) div CellSize;
  rows := (H + CellSize - 1) div CellSize;

  small := TBitmap.Create;
  try
    small.PixelFormat := pf24bit;
    small.SetSize(cols, rows);
    SetStretchBltMode(small.Canvas.Handle, HALFTONE);
    SetBrushOrgEx(small.Canvas.Handle, 0, 0, nil);
    small.Canvas.StretchDraw(Rect(0, 0, cols, rows), Bitmap);

    SetLength(smallLines, rows);
    for Y := 0 to rows - 1 do
      smallLines[Y] := small.ScanLine[Y];

    SetLength(outLines, H);
    for Y := 0 to H - 1 do
      outLines[Y] := Bitmap.ScanLine[Y];

    for tj2 := 0 to rows - 1 do
      for ti2 := 0 to cols - 1 do
      begin
        gray := (smallLines[tj2][ti2].R * 299 + smallLines[tj2][ti2].G * 587
          + smallLines[tj2][ti2].B * 114) div 1000;
        lv := Trunc((255 - gray) * DICE_IMG_LEVELS / 256);
        if lv < 0 then lv := 0;
        if lv > DICE_IMG_LEVELS - 1 then lv := DICE_IMG_LEVELS - 1;

        for tj := 0 to CellSize - 1 do
        begin
          Y := tj2 * CellSize + tj;
          if Y >= H then Break;
          for ti := 0 to CellSize - 1 do
          begin
            X := ti2 * CellSize + ti;
            if X >= W then Break;
            C := tiles[lv][tj * CellSize + ti];
            outLines[Y][X].R := C;
            outLines[Y][X].G := C;
            outLines[Y][X].B := C;
          end;
        end;
      end;
  finally
    small.Free;
  end;
end;

function ShowDiceImgDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TDiceImgDlg;
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
  Dlg := TDiceImgDlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;

    // Nawigator: caly obraz skalowany do 400 px (jak w ShowDiceDlg).
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
      SetStretchBltMode(Scaled.Canvas.Handle, HALFTONE);
      SetBrushOrgEx(Scaled.Canvas.Handle, 0, 0, nil);
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

    // Podglad 100%: wymiary jak nawigator, fragment 1:1 pikseli wyniku.
    Dlg.FZoomW := pw;
    Dlg.FZoomH := ph;
    Dlg.FZoomBmp := TBitmap.Create;
    Dlg.FZoomBmp.PixelFormat := pf24bit;
    Dlg.FZoomBmp.SetSize(pw, ph);

    Dlg.FZoomX := (Bitmap.Width - pw) div 2;
    Dlg.FZoomY := (Bitmap.Height - ph) div 2;

    Dlg.pboxPreview.Width := pw;
    Dlg.pboxPreview.Height := ph;
    Dlg.pboxPreview.Left := Dlg.CtrlGap;
    Dlg.pboxPreview.Top := Dlg.TitleBarGap + Dlg.CtrlGap;
    Dlg.pboxZoom.Left := Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2;
    Dlg.pboxZoom.Top := Dlg.pboxPreview.Top;
    Dlg.pboxZoom.Width := Dlg.FZoomW;
    Dlg.pboxZoom.Height := Dlg.FZoomH;

    // Kolumna kontrolek pod podgladami: dociskana w dol, gdy podglady sa wyzsze niz w DFM.
    // Pod podgladami: suwak rozmiaru, wartosc, liczba kostek, przyciski.
    // Pozycje wzgledem rzeczywistego dolu kontrolek (bez stalych z DFM).
    Bottom := Dlg.pboxPreview.Top + Max(Dlg.pboxPreview.Height, Dlg.pboxZoom.Height);
    Dlg.lblCell.Top := Bottom + Dlg.RowGap * 2;
    Dlg.tbCell.Top := Dlg.lblCell.Top + Dlg.lblCell.Height + Dlg.RowGap;
    Dlg.lblCellVal.Top := Dlg.tbCell.Top + Dlg.tbCell.Height + Dlg.RowGap;
    Dlg.lblCount.Top := Dlg.lblCellVal.Top + Dlg.lblCellVal.Height + Dlg.RowGap * 2;
    Dlg.lblCountVal.Top := Dlg.lblCount.Top + Dlg.lblCount.Height + Dlg.RowGap;
    Dlg.btnOK.Top := Dlg.lblCountVal.Top + Dlg.lblCountVal.Height + Dlg.RowGap * 3;
    Dlg.btnCancel.Top := Dlg.btnOK.Top;

    Dlg.FCell := Dlg.tbCell.Position * 2;
    Dlg.UpdateCount;
    Dlg.ApplyPreview;

    Dlg.FitToContent(Dlg.CtrlGap * 2, Dlg.CtrlGap * 3);

    Dlg.pboxPreview.Left := (Dlg.ClientWidth - (pw + Dlg.CtrlGap * 2 + pw)) div 2;
    if Dlg.pboxPreview.Left < Dlg.CtrlGap then
      Dlg.pboxPreview.Left := Dlg.CtrlGap;
    Dlg.pboxZoom.Left := Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2;

    // Suwak, wartosc i liczba kostek: lewa krawedz i szerokosc jak para podgladow.
    Dlg.lblCell.Left := Dlg.pboxPreview.Left;
    Dlg.tbCell.Left := Dlg.pboxPreview.Left;
    Dlg.tbCell.Width := Dlg.pboxZoom.Left + Dlg.pboxZoom.Width - Dlg.pboxPreview.Left;
    Dlg.lblCellVal.Left := Dlg.pboxPreview.Left;
    Dlg.lblCellVal.Width := Dlg.tbCell.Width;
    Dlg.lblCount.Left := Dlg.pboxPreview.Left;
    Dlg.lblCountVal.Left := Dlg.pboxPreview.Left;
    Dlg.lblCountVal.Width := Dlg.tbCell.Width;

    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      gMacroPending.Code := 'DICEIMG';
      gMacroPending.Params := IntToStr(Dlg.FCell);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TDiceImgDlg }

procedure TDiceImgDlg.FormCreate(Sender: TObject);
begin
  // Bufor ekranu formy (podglady bez migania) - jak w TDiceDlg.
  DoubleBuffered := True;
  FCell := DICE_IMG_LARGE;
  tbCell.Position := DICE_IMG_LARGE div 2;   // OnChange przy FSourceBmp = nil nic nie robi
  lblCellVal.Caption := IntToStr(FCell);
end;

procedure TDiceImgDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FMapBmp.Free;
end;

procedure TDiceImgDlg.tbCellChange(Sender: TObject);
begin
  FCell := tbCell.Position * 2;
  lblCellVal.Caption := IntToStr(FCell);
  if FSourceBmp = nil then Exit;
  UpdateCount;
  ApplyPreview;
end;

procedure TDiceImgDlg.UpdateCount;
begin
  lblCountVal.Caption := IntToStr(DiceImgCount(FSourceBmp.Width, FSourceBmp.Height, FCell));
end;

procedure TDiceImgDlg.ApplyPreview;
begin
  if FWorkingPreview = nil then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  DoDiceImage(FWorkingPreview, FCell);
  RebuildZoomCache;
  RenderFragment;
  pboxZoom.Invalidate;
  pboxPreview.Invalidate;
end;

procedure TDiceImgDlg.ApplyFull;
begin
  DoDiceImage(FSourceBmp, FCell);
end;

// Pozycja ramki podgladu 100% w pikselach nawigatora.
function TDiceImgDlg.CursorRect: TRect;
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

procedure TDiceImgDlg.InvalidateNavRect(aRect: TRect);
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

procedure TDiceImgDlg.RebuildZoom(X, Y: Integer);
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
  R := CursorRect;
  FZoomX := X;
  FZoomY := Y;
  RenderFragment;
  C := CursorRect;
  UR := Rect(Min(R.Left, C.Left), Min(R.Top, C.Top),
    Max(R.Right, C.Right), Max(R.Bottom, C.Bottom));
  InvalidateNavRect(UR);
  pboxZoom.Invalidate;
end;

// Mapa (oryginal w skali komorki) i kafle przebudowywane tylko przy zmianie rozmiaru kostki.
procedure TDiceImgDlg.RebuildZoomCache;
var
  sW, sH: Integer;
begin
  if FSourceBmp = nil then Exit;
  if (FMapBmp <> nil) and (FTileSize = FCell) then Exit;
  sW := FSourceBmp.Width;
  sH := FSourceBmp.Height;
  BuildDiceImgTiles(FCell, FTiles);
  FTileSize := FCell;
  if FMapBmp = nil then
    FMapBmp := TBitmap.Create;
  FMapBmp.PixelFormat := pf24bit;
  FMapBmp.SetSize((sW + FTileSize - 1) div FTileSize, (sH + FTileSize - 1) div FTileSize);
  SetStretchBltMode(FMapBmp.Canvas.Handle, HALFTONE);
  SetBrushOrgEx(FMapBmp.Canvas.Handle, 0, 0, nil);
  FMapBmp.Canvas.StretchDraw(Rect(0, 0, FMapBmp.Width, FMapBmp.Height), FSourceBmp);
end;

// Fragment FZoomBmp (1:1) z offsetem FZoomX/FZoomY w obrazie wynikowym.
// Poza obrazem - bialo.
procedure TDiceImgDlg.RenderFragment;
var
  W, H, SIZE, cols, rows, lv, ti2, tj2, tx, ty, nTiles: Integer;
  C: Byte;
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
    for X := 0 to W - 1 do
    begin
      gx := FZoomX + X;
      if (gx < 0) or (gx >= FSourceBmp.Width) or (gy < 0) or (gy >= FSourceBmp.Height) then
        C := 255
      else
      begin
        ti2 := gx div SIZE;
        tj2 := gy div SIZE;
        if (ti2 >= cols) or (tj2 >= rows) then
          C := 255
        else
        begin
          px := mapLines[tj2][ti2].R;
          gray := (px * 299 + mapLines[tj2][ti2].G * 587 + mapLines[tj2][ti2].B * 114) div 1000;
          lv := Trunc((255 - gray) * nTiles / 256);
          if lv < 0 then lv := 0;
          if lv > nTiles - 1 then lv := nTiles - 1;
          tx := gx - ti2 * SIZE;
          ty := gy - tj2 * SIZE;
          C := FTiles[lv][ty * SIZE + tx];
        end;
      end;
      outLines[Y][X].R := C;
      outLines[Y][X].G := C;
      outLines[Y][X].B := C;
    end;
  end;
end;

procedure TDiceImgDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  ImgX := Round(X * FSourceBmp.Width / FNavW);
  ImgY := Round(Y * FSourceBmp.Height / FNavH);
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TDiceImgDlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

procedure TDiceImgDlg.pboxPreviewPaint(Sender: TObject);
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
