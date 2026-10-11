unit frmRasterPunktowyDlg;

// Raster punktowy: siatka punktow obrocona o wybrany kat (kat rastra).
// Dla kazdego piksela wyniku: komorka siatki obrocona, ton pobrany ze zrodla
// w srodku tej komorki, promien punktu zalezy od tonu (krzywa tonalna).
// Linie/krawedzie punktow wygladzane (suwak), linie liczone per piksel,
// wiec punkty przechodza przez granice komorek bez artefaktow.
// Stary Halftone (frmHalftoneDlg) pozostaje bez zmian.

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uTitleBar;

type
  TRasterPunktowyDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    pboxZoom: TPaintBox;
    lblCell: TLabel;
    tbCell: TTrackBar;
    lblCellVal: TLabel;
    lblAngle: TLabel;
    tbAngle: TTrackBar;
    lblAngleVal: TLabel;
    lblRad: TLabel;
    tbRad: TTrackBar;
    lblRadVal: TLabel;
    lblGamma: TLabel;
    tbGamma: TTrackBar;
    lblGammaVal: TLabel;
    lblSoft: TLabel;
    tbSoft: TTrackBar;
    lblSoftVal: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxZoomPaint(Sender: TObject);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure tbParamChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FSrcCopy: TBitmap;
    FZoomBmp: TBitmap;
    FCell: Integer;
    FAngle: Integer;
    FRad: Integer;
    FGamma: Integer;
    FSoft: Integer;
    FNavW, FNavH: Integer;
    FZoomX, FZoomY, FZoomW, FZoomH: Integer;
    procedure ApplyPreview;
    procedure ApplyFull;
    function CursorRect: TRect;
    procedure InvalidateNavRect(aRect: TRect);
    procedure RebuildZoom(X, Y: Integer);
    procedure RenderFragment;
  end;

function ShowRasterPunktowyDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoRasterPunktowy(Bitmap: TBitmap; CellSize, AngleDeg, RadPct, GammaPct, SoftTenths: Integer);

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

type
  TPunktParams = record
    Cell: Double;     // rozmiar komorki siatki (px)
    C, S: Double;     // cos / sin kata rastra
    RadMax: Double;   // promien punktu przy tonie 100% (px)
    Gam: Double;      // krzywa tonalna (wykladnik)
    Soft: Double;     // szerokosc wygladzenia krawedzi (px), 0 = ostra
  end;

// Parametry: kat w stopniach, maksymalny rozmiar punktu w % polowy komorki,
// krzywa tonalna w setnych (100 = liniowa), wygladzenie w dziesiatych px.
// RadMax = RadPct/100 * Cell/2 * sqrt(2): przy 100% punkt w rogu komorki
// siega dokladnie do narozy (pelne krycie przy ciemnym tonie).
function MakePunktParams(CellSize, AngleDeg, RadPct, GammaPct, SoftTenths: Integer): TPunktParams;
begin
  Result.Cell := Max(1, CellSize);
  Result.C := Cos(DegToRad(AngleDeg));
  Result.S := Sin(DegToRad(AngleDeg));
  Result.RadMax := RadPct / 100.0 * Result.Cell / 2.0 * Sqrt(2.0);
  Result.Gam := GammaPct / 100.0;
  Result.Soft := SoftTenths / 10.0;
end;

// Wartosc piksela wyniku (0 = czarny, 255 = bialy) dla pikselu (x, y) siatki obroconej.
// Ton z lokalnego srodka komorki w ukladzie zrodla; przy Soft > 0 krawedz miekka.
function PunktPixel(const Pr: TPunktParams; const SrcLines: array of PRGBTripleArray;
  W, H, x, y: Integer): Byte;
var
  u, v, uc, vc, xc, yc, dd, r, dist, cov: Double;
  i, j, sx, sy, gray: Integer;
  px: TRGBTriple;
begin
  u := (x + 0.5) * Pr.C + (y + 0.5) * Pr.S;
  v := -(x + 0.5) * Pr.S + (y + 0.5) * Pr.C;
  i := Floor(u / Pr.Cell);
  j := Floor(v / Pr.Cell);
  uc := (i + 0.5) * Pr.Cell;
  vc := (j + 0.5) * Pr.Cell;
  xc := uc * Pr.C - vc * Pr.S;
  yc := uc * Pr.S + vc * Pr.C;
  sx := EnsureRange(Floor(xc), 0, W - 1);
  sy := EnsureRange(Floor(yc), 0, H - 1);
  px := SrcLines[sy][sx];
  gray := (Integer(px.R) * 299 + Integer(px.G) * 587 + Integer(px.B) * 114) div 1000;
  dd := Power(1.0 - gray / 255.0, Pr.Gam);
  r := Pr.RadMax * Sqrt(dd);
  dist := Sqrt(Sqr(u - uc) + Sqr(v - vc));
  if Pr.Soft <= 0 then
  begin
    if dist <= r then cov := 1.0 else cov := 0.0;
  end
  else
    cov := EnsureRange(0.5 + (r - dist) / Pr.Soft, 0.0, 1.0);
  Result := Round(255 * (1.0 - cov));
end;

// Przetwarza cala bitmape. Zrodlo = kopia wejscia (ton), wynik zapisywany w Bitmap.
procedure DoRasterPunktowy(Bitmap: TBitmap; CellSize, AngleDeg, RadPct, GammaPct, SoftTenths: Integer);
var
  W, H, X, Y: Integer;
  Pr: TPunktParams;
  src: TBitmap;
  srcLines: array of PRGBTripleArray;
  outLines: array of PRGBTripleArray;
  C: Byte;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Bitmap.PixelFormat := pf24bit;
  Pr := MakePunktParams(CellSize, AngleDeg, RadPct, GammaPct, SoftTenths);

  src := TBitmap.Create;
  try
    src.PixelFormat := pf24bit;
    src.Assign(Bitmap);

    SetLength(srcLines, H);
    for Y := 0 to H - 1 do
      srcLines[Y] := src.ScanLine[Y];

    SetLength(outLines, H);
    for Y := 0 to H - 1 do
      outLines[Y] := Bitmap.ScanLine[Y];

    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        C := PunktPixel(Pr, srcLines, W, H, X, Y);
        outLines[Y][X].R := C;
        outLines[Y][X].G := C;
        outLines[Y][X].B := C;
      end;
  finally
    src.Free;
  end;
end;

function ShowRasterPunktowyDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TRasterPunktowyDlg;
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
  Dlg := TRasterPunktowyDlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;

    // Pelny obraz (pf24bit) do podgladu 100%: ton brany z oryginalu.
    Dlg.FSrcCopy := TBitmap.Create;
    Dlg.FSrcCopy.PixelFormat := pf24bit;
    Dlg.FSrcCopy.Assign(Bitmap);

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
    Dlg.lblAngle.Top := Dlg.lblCellVal.Top + Dlg.lblCellVal.Height + Dlg.RowGap * 2;
    Dlg.tbAngle.Top := Dlg.lblAngle.Top + Dlg.lblAngle.Height + Dlg.RowGap;
    Dlg.lblAngleVal.Top := Dlg.tbAngle.Top + Dlg.tbAngle.Height + Dlg.RowGap;
    Dlg.lblRad.Top := Dlg.lblAngleVal.Top + Dlg.lblAngleVal.Height + Dlg.RowGap * 2;
    Dlg.tbRad.Top := Dlg.lblRad.Top + Dlg.lblRad.Height + Dlg.RowGap;
    Dlg.lblRadVal.Top := Dlg.tbRad.Top + Dlg.tbRad.Height + Dlg.RowGap;
    Dlg.lblGamma.Top := Dlg.lblRadVal.Top + Dlg.lblRadVal.Height + Dlg.RowGap * 2;
    Dlg.tbGamma.Top := Dlg.lblGamma.Top + Dlg.lblGamma.Height + Dlg.RowGap;
    Dlg.lblGammaVal.Top := Dlg.tbGamma.Top + Dlg.tbGamma.Height + Dlg.RowGap;
    Dlg.lblSoft.Top := Dlg.lblGammaVal.Top + Dlg.lblGammaVal.Height + Dlg.RowGap * 2;
    Dlg.tbSoft.Top := Dlg.lblSoft.Top + Dlg.lblSoft.Height + Dlg.RowGap;
    Dlg.lblSoftVal.Top := Dlg.tbSoft.Top + Dlg.tbSoft.Height + Dlg.RowGap;
    Dlg.btnOK.Top := Dlg.lblSoftVal.Top + Dlg.lblSoftVal.Height + Dlg.RowGap * 3;
    Dlg.btnCancel.Top := Dlg.btnOK.Top;

    Dlg.FCell := Dlg.tbCell.Position;
    Dlg.FAngle := Dlg.tbAngle.Position;
    Dlg.FRad := Dlg.tbRad.Position;
    Dlg.FGamma := Dlg.tbGamma.Position;
    Dlg.FSoft := Dlg.tbSoft.Position;
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
    Dlg.lblAngle.Left := Dlg.pboxPreview.Left;
    Dlg.tbAngle.Left := Dlg.pboxPreview.Left;
    Dlg.tbAngle.Width := Dlg.tbCell.Width;
    Dlg.lblAngleVal.Left := Dlg.pboxPreview.Left;
    Dlg.lblAngleVal.Width := Dlg.tbCell.Width;
    Dlg.lblRad.Left := Dlg.pboxPreview.Left;
    Dlg.tbRad.Left := Dlg.pboxPreview.Left;
    Dlg.tbRad.Width := Dlg.tbCell.Width;
    Dlg.lblRadVal.Left := Dlg.pboxPreview.Left;
    Dlg.lblRadVal.Width := Dlg.tbCell.Width;
    Dlg.lblGamma.Left := Dlg.pboxPreview.Left;
    Dlg.tbGamma.Left := Dlg.pboxPreview.Left;
    Dlg.tbGamma.Width := Dlg.tbCell.Width;
    Dlg.lblGammaVal.Left := Dlg.pboxPreview.Left;
    Dlg.lblGammaVal.Width := Dlg.tbCell.Width;
    Dlg.lblSoft.Left := Dlg.pboxPreview.Left;
    Dlg.tbSoft.Left := Dlg.pboxPreview.Left;
    Dlg.tbSoft.Width := Dlg.tbCell.Width;
    Dlg.lblSoftVal.Left := Dlg.pboxPreview.Left;
    Dlg.lblSoftVal.Width := Dlg.tbCell.Width;

    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      gMacroPending.Code := 'RASTERPUNKT';
      gMacroPending.Params := IntToStr(Dlg.FCell) + '|' + IntToStr(Dlg.FAngle) + '|' +
        IntToStr(Dlg.FRad) + '|' + IntToStr(Dlg.FGamma) + '|' + IntToStr(Dlg.FSoft);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TRasterPunktowyDlg }

procedure TRasterPunktowyDlg.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  tbCell.Position := 8;
  tbAngle.Position := 45;
  tbRad.Position := 70;
  tbGamma.Position := 100;
  tbSoft.Position := 10;
  tbParamChange(Sender);
end;

procedure TRasterPunktowyDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
  FZoomBmp.Free;
  FSrcCopy.Free;
end;

// Jedna procedura dla wszystkich suwakow: etykiety, wartosci i podglad.
procedure TRasterPunktowyDlg.tbParamChange(Sender: TObject);
begin
  lblCellVal.Caption := IntToStr(tbCell.Position);
  lblAngleVal.Caption := IntToStr(tbAngle.Position);
  lblRadVal.Caption := IntToStr(tbRad.Position);
  lblGammaVal.Caption := IntToStr(tbGamma.Position);
  lblSoftVal.Caption := FormatFloat('0.0', tbSoft.Position / 10.0);
  FCell := tbCell.Position;
  FAngle := tbAngle.Position;
  FRad := tbRad.Position;
  FGamma := tbGamma.Position;
  FSoft := tbSoft.Position;
  if FSourceBmp = nil then Exit;
  ApplyPreview;
end;

procedure TRasterPunktowyDlg.ApplyPreview;
begin
  if FSourceBmp = nil then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  DoRasterPunktowy(FWorkingPreview, FCell, FAngle, FRad, FGamma, FSoft);
  RenderFragment;
  pboxPreview.Invalidate;
  pboxZoom.Invalidate;
end;

procedure TRasterPunktowyDlg.ApplyFull;
begin
  DoRasterPunktowy(FSourceBmp, FCell, FAngle, FRad, FGamma, FSoft);
end;

// Pozycja ramki podgladu 100% w pikselach nawigatora.
function TRasterPunktowyDlg.CursorRect: TRect;
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

procedure TRasterPunktowyDlg.InvalidateNavRect(aRect: TRect);
var
  PW: TWinControl;
begin
  PW := pboxPreview.Parent;
  if (PW = nil) or (PW.Handle = 0) then Exit;
  InflateRect(aRect, 1, 1);
  if aRect.Left < 0 then aRect.Left := 0;
  if aRect.Top < 0 then aRect.Top := 0;
  if aRect.Right > FNavW then aRect.Right := FNavW;
  if aRect.Bottom > FNavH then aRect.Bottom := FNavH;
  OffsetRect(aRect, pboxPreview.Left, pboxPreview.Top);
  InvalidateRect(PW.Handle, @aRect, False);
end;

procedure TRasterPunktowyDlg.RebuildZoom(X, Y: Integer);
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

// Fragment FZoomBmp (1:1) z offsetem FZoomX/FZoomY, ton z pelnego obrazu (FSrcCopy).
// Poza obrazem - bialo.
procedure TRasterPunktowyDlg.RenderFragment;
var
  Pr: TPunktParams;
  W, H, X, Y, gx, gy, SW, SH: Integer;
  C: Byte;
  srcLines: array of PRGBTripleArray;
  outLines: array of PRGBTripleArray;
begin
  if (FZoomBmp = nil) or (FSrcCopy = nil) then Exit;
  Pr := MakePunktParams(FCell, FAngle, FRad, FGamma, FSoft);
  W := FZoomBmp.Width;
  H := FZoomBmp.Height;
  SW := FSrcCopy.Width;
  SH := FSrcCopy.Height;
  SetLength(srcLines, SH);
  for Y := 0 to SH - 1 do
    srcLines[Y] := FSrcCopy.ScanLine[Y];
  SetLength(outLines, H);
  for Y := 0 to H - 1 do
    outLines[Y] := FZoomBmp.ScanLine[Y];
  for Y := 0 to H - 1 do
  begin
    gy := FZoomY + Y;
    for X := 0 to W - 1 do
    begin
      gx := FZoomX + X;
      if (gx < 0) or (gx >= SW) or (gy < 0) or (gy >= SH) then
        C := 255
      else
        C := PunktPixel(Pr, srcLines, SW, SH, gx, gy);
      outLines[Y][X].R := C;
      outLines[Y][X].G := C;
      outLines[Y][X].B := C;
    end;
  end;
end;

procedure TRasterPunktowyDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  ImgX, ImgY: Integer;
begin
  ImgX := Round(X * FSourceBmp.Width / FNavW);
  ImgY := Round(Y * FSourceBmp.Height / FNavH);
  RebuildZoom(ImgX - FZoomW div 2, ImgY - FZoomH div 2);
end;

procedure TRasterPunktowyDlg.pboxZoomPaint(Sender: TObject);
begin
  with pboxZoom.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxZoom.ClientRect);
    if Assigned(FZoomBmp) then
      Draw(0, 0, FZoomBmp);
  end;
end;

procedure TRasterPunktowyDlg.pboxPreviewPaint(Sender: TObject);
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
