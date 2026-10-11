unit frmRasterKrzyzowyDlg;

// Raster krzyzowy: dwa zestawy linii pod katami ustawianymi suwakami.
// Ton brany z komorki (Cell x Cell), linie liczone per piksel w ukladzie
// obroconym, wiec sa ciagle przez granice komorek. Krzyzyk = suma dwoch
// zestawow: piksel czarny, gdy trafia w ktorykolwiek z nich.
// Stary Crosshatch (frmCrosshatchDlg) pozostaje bez zmian.

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uTitleBar;

type
  TRasterKrzyzowyDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    pboxZoom: TPaintBox;
    lblCell: TLabel;
    tbCell: TTrackBar;
    lblCellVal: TLabel;
    lblThick: TLabel;
    tbThick: TTrackBar;
    lblThickVal: TLabel;
    lblAngle1: TLabel;
    tbAngle1: TTrackBar;
    lblAngle1Val: TLabel;
    lblAngle2: TLabel;
    tbAngle2: TTrackBar;
    lblAngle2Val: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxZoomPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure tbCellChange(Sender: TObject);
    procedure tbThickChange(Sender: TObject);
    procedure tbAngleChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FMapBmp: TBitmap;
    FMapCell: Integer;
    FZoomBmp: TBitmap;
    FCell: Integer;
    FThick: Integer;
    FAngle1: Integer;
    FAngle2: Integer;
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

function ShowRasterKrzyzowyDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoRasterKrzyzowy(Bitmap: TBitmap; CellSize, MaxThick, Angle1, Angle2: Integer);

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
  RK_LEVELS = 16;   // poziomy tonalne (0 = biale, 15 = najciemniejsze)

type
  TRasterParams = record
    Cell: Integer;
    Thick: array[0..RK_LEVELS - 1] of Integer;
    C1, S1, C2, S2: Double;
  end;

// Parametry dla danego rozmiaru komorki, maksymalnej grubosci i dwoch katow.
// Grubosc poziomu lv = Round(lv * MaxThick / (RK_LEVELS - 1)), ograniczona do Cell.
function MakeRasterParams(CellSize, MaxThick, Angle1, Angle2: Integer): TRasterParams;
var
  lv: Integer;
begin
  Result.Cell := Max(1, CellSize);
  for lv := 0 to RK_LEVELS - 1 do
    Result.Thick[lv] := Min(Result.Cell, Round(lv * MaxThick / (RK_LEVELS - 1)));
  Result.C1 := Cos(DegToRad(Angle1));
  Result.S1 := Sin(DegToRad(Angle1));
  Result.C2 := Cos(DegToRad(Angle2));
  Result.S2 := Sin(DegToRad(Angle2));
end;

// Poziom tonalny z koloru komorki (jasne = 0, ciemne = RK_LEVELS - 1).
function ToneLevel(R, G, B: Byte): Integer;
var
  gray: Integer;
begin
  gray := (Integer(R) * 299 + Integer(G) * 587 + Integer(B) * 114) div 1000;
  Result := Trunc((255 - gray) * RK_LEVELS / 256);
  if Result < 0 then Result := 0;
  if Result > RK_LEVELS - 1 then Result := RK_LEVELS - 1;
end;

// Piksel globalny (gx, gy) jest czarny, gdy lezy na linii ktoregokolwiek zestawu.
// Linia zestawu: u = -gx*S + gy*C (normalna do kierunku linii), p = u mod Cell,
// czarny gdy p < grubosc. Tak liczone, ze linie ciagnie sie przez granice komorek.
function RasterBlack(const P: TRasterParams; gx, gy, lv: Integer): Boolean;
var
  t: Integer;
  u, ph: Double;
begin
  t := P.Thick[lv];
  if t <= 0 then
  begin
    Result := False;
    Exit;
  end;
  u := -gx * P.S1 + gy * P.C1;
  ph := u - P.Cell * Floor(u / P.Cell);
  Result := ph < t;
  if not Result then
  begin
    u := -gx * P.S2 + gy * P.C2;
    ph := u - P.Cell * Floor(u / P.Cell);
    Result := ph < t;
  end;
end;

// Pelne przetworzenie bitmapy. Ton z komorek (StretchDraw do cols x rows),
// piksele wyniku: 0 = czarny, 255 = bialy.
procedure DoRasterKrzyzowy(Bitmap: TBitmap; CellSize, MaxThick, Angle1, Angle2: Integer);
var
  W, H, cols, rows, X, Y, cx, cy: Integer;
  P: TRasterParams;
  small: TBitmap;
  smallLines: array of PRGBTripleArray;
  outLines: array of PRGBTripleArray;
  C: Byte;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;

  P := MakeRasterParams(CellSize, MaxThick, Angle1, Angle2);
  // Sufit: czesciowa komorka przy krawedzi jest renderowana w calosci.
  cols := (W + P.Cell - 1) div P.Cell;
  rows := (H + P.Cell - 1) div P.Cell;

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

    for Y := 0 to H - 1 do
    begin
      cy := Y div P.Cell;
      for X := 0 to W - 1 do
      begin
        cx := X div P.Cell;
        if RasterBlack(P, X, Y, ToneLevel(smallLines[cy][cx].R,
          smallLines[cy][cx].G, smallLines[cy][cx].B)) then
          C := 0
        else
          C := 255;
        outLines[Y][X].R := C;
        outLines[Y][X].G := C;
        outLines[Y][X].B := C;
      end;
    end;
  finally
    small.Free;
  end;
end;

function ShowRasterKrzyzowyDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TRasterKrzyzowyDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
  Bottom: Integer;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := TRasterKrzyzowyDlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;

    // Nawigator: caly obraz skalowany do 400 px.
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

    // Kolumna kontrolek pod podgladami, ulozona od dolu podgladow.
    Bottom := Dlg.pboxPreview.Top + Max(Dlg.pboxPreview.Height, Dlg.pboxZoom.Height);
    Dlg.lblCell.Top := Bottom + Dlg.RowGap * 2;
    Dlg.tbCell.Top := Dlg.lblCell.Top + Dlg.lblCell.Height + Dlg.RowGap;
    Dlg.lblCellVal.Top := Dlg.tbCell.Top + Dlg.tbCell.Height + Dlg.RowGap;
    Dlg.lblThick.Top := Dlg.lblCellVal.Top + Dlg.lblCellVal.Height + Dlg.RowGap * 2;
    Dlg.tbThick.Top := Dlg.lblThick.Top + Dlg.lblThick.Height + Dlg.RowGap;
    Dlg.lblThickVal.Top := Dlg.tbThick.Top + Dlg.tbThick.Height + Dlg.RowGap;
    Dlg.lblAngle1.Top := Dlg.lblThickVal.Top + Dlg.lblThickVal.Height + Dlg.RowGap * 2;
    Dlg.tbAngle1.Top := Dlg.lblAngle1.Top + Dlg.lblAngle1.Height + Dlg.RowGap;
    Dlg.lblAngle1Val.Top := Dlg.tbAngle1.Top + Dlg.tbAngle1.Height + Dlg.RowGap;
    Dlg.lblAngle2.Top := Dlg.lblAngle1Val.Top + Dlg.lblAngle1Val.Height + Dlg.RowGap * 2;
    Dlg.tbAngle2.Top := Dlg.lblAngle2.Top + Dlg.lblAngle2.Height + Dlg.RowGap;
    Dlg.lblAngle2Val.Top := Dlg.tbAngle2.Top + Dlg.tbAngle2.Height + Dlg.RowGap;
    Dlg.btnOK.Top := Dlg.lblAngle2Val.Top + Dlg.lblAngle2Val.Height + Dlg.RowGap * 3;
    Dlg.btnCancel.Top := Dlg.btnOK.Top;

    Dlg.FCell := Dlg.tbCell.Position;
    Dlg.FThick := Dlg.tbThick.Position;
    Dlg.FAngle1 := Dlg.tbAngle1.Position;
    Dlg.FAngle2 := Dlg.tbAngle2.Position;
    Dlg.ApplyPreview;

    Dlg.FitToContent(Dlg.CtrlGap * 2, Dlg.CtrlGap * 3);

    // Para podgladow wycentrowana w szerokosci okna.
    Dlg.pboxPreview.Left := (Dlg.ClientWidth - (pw + Dlg.CtrlGap * 2 + pw)) div 2;
    if Dlg.pboxPreview.Left < Dlg.CtrlGap then
      Dlg.pboxPreview.Left := Dlg.CtrlGap;
    Dlg.pboxZoom.Left := Dlg.pboxPreview.Left + pw + Dlg.CtrlGap * 2;

    // Suwaki i wartosci: lewa krawedz i szerokosc jak para podgladow.
    Dlg.lblCell.Left := Dlg.pboxPreview.Left;
    Dlg.tbCell.Left := Dlg.pboxPreview.Left;
    Dlg.tbCell.Width := Dlg.pboxZoom.Left + Dlg.pboxZoom.Width - Dlg.pboxPreview.Left;
    Dlg.lblCellVal.Left := Dlg.pboxPreview.Left;
    Dlg.lblCellVal.Width := Dlg.tbCell.Width;
    Dlg.lblThick.Left := Dlg.pboxPreview.Left;
    Dlg.tbThick.Left := Dlg.pboxPreview.Left;
    Dlg.tbThick.Width := Dlg.tbCell.Width;
    Dlg.lblThickVal.Left := Dlg.pboxPreview.Left;
    Dlg.lblThickVal.Width := Dlg.tbCell.Width;
    Dlg.lblAngle1.Left := Dlg.pboxPreview.Left;
    Dlg.tbAngle1.Left := Dlg.pboxPreview.Left;
    Dlg.tbAngle1.Width := Dlg.tbCell.Width;
    Dlg.lblAngle1Val.Left := Dlg.pboxPreview.Left;
    Dlg.lblAngle1Val.Width := Dlg.tbCell.Width;
    Dlg.lblAngle2.Left := Dlg.pboxPreview.Left;
    Dlg.tbAngle2.Left := Dlg.pboxPreview.Left;
    Dlg.tbAngle2.Width := Dlg.tbCell.Width;
    Dlg.lblAngle2Val.Left := Dlg.pboxPreview.Left;
    Dlg.lblAngle2Val.Width := Dlg.tbCell.Width;

    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      gMacroPending.Code := 'RASTERKRZ';
      gMacroPending.Params := IntToStr(Dlg.FCell) + '|' + IntToStr(Dlg.FThick) + '|' +
        IntToStr(Dlg.FAngle1) + '|' + IntToStr(Dlg.FAngle2);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TRasterKrzyzowyDlg }

procedure TRasterKrzyzowyDlg.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  tbCell.Position := 8;
  tbThick.Position := 4;
  tbAngle1.Position := 45;
  tbAngle2.Position := 135;
  lblCellVal.Caption := IntToStr(tbCell.Position);
  lblThickVal.Caption := IntToStr(tbThick.Position);
  lblAngle1Val.Caption := IntToStr(tbAngle1.Position);
  lblAngle2Val.Caption := IntToStr(tbAngle2.Position);
  FCell := tbCell.Position;
  FThick := tbThick.Position;
  FAngle1 := tbAngle1.Position;
  FAngle2 := tbAngle2.Position;
end;

procedure TRasterKrzyzowyDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FMapBmp.Free;
end;

procedure TRasterKrzyzowyDlg.tbCellChange(Sender: TObject);
begin
  lblCellVal.Caption := IntToStr(tbCell.Position);
  FCell := tbCell.Position;
  if FSourceBmp = nil then Exit;
  ApplyPreview;
end;

procedure TRasterKrzyzowyDlg.tbThickChange(Sender: TObject);
begin
  lblThickVal.Caption := IntToStr(tbThick.Position);
  FThick := tbThick.Position;
  if FSourceBmp = nil then Exit;
  ApplyPreview;
end;

procedure TRasterKrzyzowyDlg.tbAngleChange(Sender: TObject);
begin
  lblAngle1Val.Caption := IntToStr(tbAngle1.Position);
  lblAngle2Val.Caption := IntToStr(tbAngle2.Position);
  FAngle1 := tbAngle1.Position;
  FAngle2 := tbAngle2.Position;
  if FSourceBmp = nil then Exit;
  ApplyPreview;
end;

procedure TRasterKrzyzowyDlg.ApplyPreview;
begin
  if FSourceBmp = nil then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  DoRasterKrzyzowy(FWorkingPreview, FCell, FThick, FAngle1, FAngle2);
  RebuildZoomCache;
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TRasterKrzyzowyDlg.ApplyFull;
begin
  DoRasterKrzyzowy(FSourceBmp, FCell, FThick, FAngle1, FAngle2);
end;

// Pozycja ramki podgladu 100% w pikselach nawigatora.
function TRasterKrzyzowyDlg.CursorRect: TRect;
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

procedure TRasterKrzyzowyDlg.InvalidateNavRect(aRect: TRect);
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

procedure TRasterKrzyzowyDlg.RebuildZoom(X, Y: Integer);
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

// Mapa tonu (oryginal probkowany w skali komorki) przebudowywana tylko przy
// zmianie rozmiaru komorki. Kreski liczone sa w RenderFragment z katow i grubosci.
procedure TRasterKrzyzowyDlg.RebuildZoomCache;
var
  sW, sH: Integer;
begin
  if FSourceBmp = nil then Exit;
  if (FMapBmp <> nil) and (FMapCell = FCell) then Exit;
  sW := FSourceBmp.Width;
  sH := FSourceBmp.Height;
  if FMapBmp = nil then
    FMapBmp := TBitmap.Create;
  FMapBmp.PixelFormat := pf24bit;
  FMapBmp.SetSize((sW + FCell - 1) div FCell, (sH + FCell - 1) div FCell);
  SetStretchBltMode(FMapBmp.Canvas.Handle, HALFTONE);
  SetBrushOrgEx(FMapBmp.Canvas.Handle, 0, 0, nil);
  FMapBmp.Canvas.StretchDraw(Rect(0, 0, FMapBmp.Width, FMapBmp.Height), FSourceBmp);
  FMapCell := FCell;
end;

// Fragment FZoomBmp (1:1) z offsetem FZoomX/FZoomY w obrazie wynikowym.
// Poza obrazem - bialo. Wspolrzedne globalne, wiec linie zgadzaja sie z pelnym wynikiem.
procedure TRasterKrzyzowyDlg.RenderFragment;
var
  P: TRasterParams;
  W, H, X, Y, gx, gy, cx, cy: Integer;
  C: Byte;
  mapLines: array of PRGBTripleArray;
  outLines: array of PRGBTripleArray;
begin
  if (FZoomBmp = nil) or (FMapBmp = nil) or (FSourceBmp = nil) then Exit;
  P := MakeRasterParams(FCell, FThick, FAngle1, FAngle2);
  W := FZoomBmp.Width;
  H := FZoomBmp.Height;
  SetLength(mapLines, FMapBmp.Height);
  for Y := 0 to FMapBmp.Height - 1 do
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
        cx := gx div P.Cell;
        cy := gy div P.Cell;
        if RasterBlack(P, gx, gy, ToneLevel(mapLines[cy][cx].R,
          mapLines[cy][cx].G, mapLines[cy][cx].B)) then
          C := 0
        else
          C := 255;
      end;
      outLines[Y][X].R := C;
      outLines[Y][X].G := C;
      outLines[Y][X].B := C;
    end;
  end;
end;

procedure TRasterKrzyzowyDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  ImgX := Round(X * FSourceBmp.Width / FNavW);
  ImgY := Round(Y * FSourceBmp.Height / FNavH);
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TRasterKrzyzowyDlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

procedure TRasterKrzyzowyDlg.pboxPreviewPaint(Sender: TObject);
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
