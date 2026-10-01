unit frmWBDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TWBDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblR: TLabel;
    lblG: TLabel;
    lblB: TLabel;
    tbR: TTrackBar;
    tbG: TTrackBar;
    tbB: TTrackBar;
    lblValR: TLabel;
    lblValG: TLabel;
    lblValB: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure pboxPreviewMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure pboxPreviewMouseLeave(Sender: TObject);
    procedure tbRChange(Sender: TObject);
    procedure tbGChange(Sender: TObject);
    procedure tbBChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FPreviewScale: Double;
    FZoomX: Integer;
    FZoomY: Integer;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowWBDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

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

procedure DoWhiteBalance(Bitmap: TBitmap; R, G, B: Integer);
var
  LUTR, LUTG, LUTB: array[0..255] of Byte;
  GammaR, GammaG, GammaB: Double;
  Row: PRGBTripleArray;
  W, H, X, Y: Integer;
begin
  if (R = 100) and (G = 100) and (B = 100) then Exit;

  GammaR := 1.0 / (R / 100.0);
  GammaG := 1.0 / (G / 100.0);
  GammaB := 1.0 / (B / 100.0);

  for X := 0 to 255 do
  begin
    LUTR[X] := Byte(Max(0, Min(255, Round(255 * Power(X / 255.0, GammaR)))));
    LUTG[X] := Byte(Max(0, Min(255, Round(255 * Power(X / 255.0, GammaG)))));
    LUTB[X] := Byte(Max(0, Min(255, Round(255 * Power(X / 255.0, GammaB)))));
  end;

  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Row[X].R := LUTR[Row[X].R];
      Row[X].G := LUTG[Row[X].G];
      Row[X].B := LUTB[Row[X].B];
    end;
  end;
end;

function ShowWBDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TWBDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := TWBDlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;

    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    Dlg.FPreviewScale := Scale;

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

    FitPreviewToDialog(Dlg, Dlg.pboxPreview, pw, ph);

    Dlg.ApplyPreview;

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TWBDlg }

procedure TWBDlg.FormCreate(Sender: TObject);
begin
  tbR.Min := 1;
  tbR.Max := 300;
  tbR.Position := 100;
  tbG.Min := 1;
  tbG.Max := 300;
  tbG.Position := 100;
  tbB.Min := 1;
  tbB.Max := 300;
  tbB.Position := 100;
  lblValR.Caption := '100';
  lblValG.Caption := '100';
  lblValB.Caption := '100';
  FZoomX := -1;
  FZoomY := -1;
end;

procedure TWBDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TWBDlg.pboxPreviewMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  FZoomX := X;
  FZoomY := Y;
  pboxPreview.Invalidate;
end;

procedure TWBDlg.pboxPreviewMouseLeave(Sender: TObject);
begin
  FZoomX := -1;
  FZoomY := -1;
  pboxPreview.Invalidate;
end;

procedure TWBDlg.tbRChange(Sender: TObject);
begin
  lblValR.Caption := IntToStr(tbR.Position);
  ApplyPreview;
end;

procedure TWBDlg.tbGChange(Sender: TObject);
begin
  lblValG.Caption := IntToStr(tbG.Position);
  ApplyPreview;
end;

procedure TWBDlg.tbBChange(Sender: TObject);
begin
  lblValB.Caption := IntToStr(tbB.Position);
  ApplyPreview;
end;

procedure TWBDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoWhiteBalance(FWorkingPreview, tbR.Position, tbG.Position, tbB.Position);
  pboxPreview.Invalidate;
end;

procedure TWBDlg.ApplyFull;
begin
  DoWhiteBalance(FSourceBmp, tbR.Position, tbG.Position, tbB.Position);
end;

procedure TWBDlg.pboxPreviewMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
const
  cWBDamping = 0.8;
var
  Pw, Ph, TargetW, TargetH, NewW, NewH, IX, IY: Integer;
  Scale: Double;
  DestLeft, DestTop: Integer;
  Row: PRGBTripleArray;
  R, G, B, T, DX, DY, CX, CY, Count: Integer;
  SR, SG, SB: Integer;

  function SliderVal(Chan, Target: Integer): Integer;
  var
    D: Double;
  begin
    if (Chan = Target) or (Chan < 2) or (Chan > 253) or (Target < 2) then
      Exit(100);
    D := 100.0 * Ln(Chan / 255.0) / Ln(Target / 255.0);
    Result := Round(D);
    if Result < 1 then Result := 1;
    if Result > 300 then Result := 300;
  end;

begin
  if Button <> mbLeft then Exit;
  if not Assigned(FSourceBmp) then Exit;
  if not Assigned(FOriginalPreview) then Exit;
  if FPreviewScale <= 0 then Exit;
  if FSourceBmp.Width = 0 then Exit;

  Pw := FOriginalPreview.Width;
  Ph := FOriginalPreview.Height;
  if (Pw = 0) or (Ph = 0) then Exit;

  TargetW := pboxPreview.ClientWidth;
  TargetH := pboxPreview.ClientHeight;

  Scale := Min(TargetW / Pw, TargetH / Ph);
  NewW := Round(Pw * Scale);
  NewH := Round(Ph * Scale);
  DestLeft := (TargetW - NewW) div 2;
  DestTop := (TargetH - NewH) div 2;

  IX := Round((X - DestLeft) / Scale / FPreviewScale);
  IY := Round((Y - DestTop) / Scale / FPreviewScale);
  if IX < 0 then IX := 0;
  if IY < 0 then IY := 0;
  if IX >= FSourceBmp.Width then IX := FSourceBmp.Width - 1;
  if IY >= FSourceBmp.Height then IY := FSourceBmp.Height - 1;

  SR := 0;
  SG := 0;
  SB := 0;
  Count := 0;
  for DY := -2 to 2 do
  begin
    CY := IY + DY;
    if CY < 0 then CY := 0;
    if CY >= FSourceBmp.Height then CY := FSourceBmp.Height - 1;
    Row := FSourceBmp.ScanLine[CY];
    for DX := -2 to 2 do
    begin
      CX := IX + DX;
      if CX < 0 then CX := 0;
      if CX >= FSourceBmp.Width then CX := FSourceBmp.Width - 1;
      Inc(SR, Row[CX].R);
      Inc(SG, Row[CX].G);
      Inc(SB, Row[CX].B);
      Inc(Count);
    end;
  end;
  R := SR div Count;
  G := SG div Count;
  B := SB div Count;

  T := Min(Max(R, Max(G, B)), 253);
  if T < 2 then Exit;

  tbR.Position := SliderVal(R, Round(R + (T - R) * cWBDamping));
  tbG.Position := SliderVal(G, Round(G + (T - G) * cWBDamping));
  tbB.Position := SliderVal(B, Round(B + (T - B) * cWBDamping));
end;

procedure TWBDlg.pboxPreviewPaint(Sender: TObject);
const
  cLoupeSz = 120;
var
  SrcW, SrcH: Integer;
  NewW, NewH: Integer;
  TargetW, TargetH: Integer;
  Scale: Double;
  DestRect: TRect;
  PicX, PicY: Integer;
  LOffset, TOffset, LSize, TSize: Integer;
  Lrx, Lry: Integer;
  MX, MY, CX, CY: Integer;
begin
  with pboxPreview.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxPreview.ClientRect);

    if Assigned(FWorkingPreview) then
    begin
      SrcW := FWorkingPreview.Width;
      SrcH := FWorkingPreview.Height;
      if (SrcW = 0) or (SrcH = 0) then Exit;

      TargetW := pboxPreview.ClientWidth;
      TargetH := pboxPreview.ClientHeight;

      Scale := Min(TargetW / SrcW, TargetH / SrcH);
      NewW := Round(SrcW * Scale);
      NewH := Round(SrcH * Scale);

      DestRect := Rect(
        (TargetW - NewW) div 2,
        (TargetH - NewH) div 2,
        (TargetW - NewW) div 2 + NewW,
        (TargetH - NewH) div 2 + NewH
      );

      StretchDraw(DestRect, FWorkingPreview);

      if (FZoomX >= 0) and (FZoomY >= 0) and (Scale > 0) and
        (FPreviewScale > 0) and Assigned(FSourceBmp) and
        (FSourceBmp.Width >= cLoupeSz) and (FSourceBmp.Height >= cLoupeSz) then
      begin
        PicX := Round((FZoomX - DestRect.Left) / Scale / FPreviewScale);
        PicY := Round((FZoomY - DestRect.Top) / Scale / FPreviewScale);
        if PicX < 0 then PicX := 0;
        if PicY < 0 then PicY := 0;
        if PicX >= FSourceBmp.Width then PicX := FSourceBmp.Width - 1;
        if PicY >= FSourceBmp.Height then PicY := FSourceBmp.Height - 1;
        LSize := cLoupeSz;
        TSize := cLoupeSz;
        LOffset := PicX - LSize div 2;
        TOffset := PicY - TSize div 2;
        if LOffset < 0 then LOffset := 0;
        if TOffset < 0 then TOffset := 0;
        if LOffset + LSize > FSourceBmp.Width then
          LOffset := FSourceBmp.Width - LSize;
        if TOffset + TSize > FSourceBmp.Height then
          TOffset := FSourceBmp.Height - TSize;
        Lrx := FZoomX - cLoupeSz div 2;
        Lry := FZoomY - cLoupeSz div 2;
        if Lrx < 0 then Lrx := 0;
        if Lry < 0 then Lry := 0;
        if Lrx + cLoupeSz > TargetW then Lrx := TargetW - cLoupeSz;
        if Lry + cLoupeSz > TargetH then Lry := TargetH - cLoupeSz;
        if (Lrx >= 0) and (Lry >= 0) and
          (Lrx + cLoupeSz <= TargetW) and (Lry + cLoupeSz <= TargetH) then
        begin
          CopyRect(
            Rect(Lrx, Lry, Lrx + cLoupeSz, Lry + cLoupeSz),
            FSourceBmp.Canvas,
            Rect(LOffset, TOffset, LOffset + LSize, TOffset + TSize));
          MX := Lrx + (PicX - LOffset);
          MY := Lry + (PicY - TOffset);
          Pen.Color := clBlack;
          Brush.Style := bsClear;
          Rectangle(Lrx, Lry, Lrx + cLoupeSz, Lry + cLoupeSz);
          Pen.Color := clWhite;
          Rectangle(MX - 3, MY - 3, MX + 4, MY + 4);
          Pen.Color := clBlack;
          Rectangle(MX - 2, MY - 2, MX + 3, MY + 3);
          CX := MX;
          CY := MY;
          Pen.Color := clBlack;
          MoveTo(CX - 8, CY); LineTo(CX + 8, CY);
          MoveTo(CX, CY - 8); LineTo(CX, CY + 8);
          Pen.Color := clWhite;
          MoveTo(CX - 7, CY); LineTo(CX - 1, CY);
          MoveTo(CX + 1, CY); LineTo(CX + 7, CY);
          MoveTo(CX, CY - 7); LineTo(CX, CY - 1);
          MoveTo(CX, CY + 1); LineTo(CX, CY + 7);
          Brush.Style := bsSolid;
        end;
      end;
    end;
  end;
end;

end.
