unit frmHSBDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  THSBDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblHue: TLabel;
    lblSat: TLabel;
    lblBri: TLabel;
    tbHue: TTrackBar;
    tbSat: TTrackBar;
    tbBri: TTrackBar;
    lblValHue: TLabel;
    lblValSat: TLabel;
    lblValBri: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure tbHueChange(Sender: TObject);
    procedure tbSatChange(Sender: TObject);
    procedure tbBriChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowHSBDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

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

// RGB -> HSB
procedure RgbToHsb(R, G, B: Byte; out H, S, Bn: Double);
var
  Max, Min, Delta: Double;
  rr, gg, bb: Double;
begin
  rr := R / 255.0;
  gg := G / 255.0;
  bb := B / 255.0;

  Max := rr;
  if gg > Max then Max := gg;
  if bb > Max then Max := bb;

  Min := rr;
  if gg < Min then Min := gg;
  if bb < Min then Min := bb;

  Bn := Max;
  Delta := Max - Min;

  if Max <> 0 then
    S := Delta / Max
  else
    S := 0;

  if Delta = 0 then
    H := 0
  else if Max = rr then
    H := 60.0 * (gg - bb) / Delta
  else if Max = gg then
    H := 60.0 * (bb - rr) / Delta + 120.0
  else
    H := 60.0 * (rr - gg) / Delta + 240.0;

  if H < 0 then H := H + 360.0;
  if H >= 360.0 then H := H - 360.0;
end;

// HSB -> RGB
function HsbToRgb(H, S, Bn: Double): TRGBTriple;
var
  Hi: Integer;
  F, P, Q, T: Double;
begin
  if S = 0 then
  begin
    Result.R := Round(Bn * 255);
    Result.G := Round(Bn * 255);
    Result.B := Round(Bn * 255);
    Exit;
  end;

  H := H / 60.0;
  Hi := Floor(H) mod 6;
  F := H - Floor(H);

  P := Bn * (1.0 - S);
  Q := Bn * (1.0 - S * F);
  T := Bn * (1.0 - S * (1.0 - F));

  case Hi of
    0: begin Result.R := Round(Bn * 255); Result.G := Round(T * 255); Result.B := Round(P * 255); end;
    1: begin Result.R := Round(Q * 255); Result.G := Round(Bn * 255); Result.B := Round(P * 255); end;
    2: begin Result.R := Round(P * 255); Result.G := Round(Bn * 255); Result.B := Round(T * 255); end;
    3: begin Result.R := Round(P * 255); Result.G := Round(Q * 255); Result.B := Round(Bn * 255); end;
    4: begin Result.R := Round(T * 255); Result.G := Round(P * 255); Result.B := Round(Bn * 255); end;
    5: begin Result.R := Round(Bn * 255); Result.G := Round(P * 255); Result.B := Round(Q * 255); end;
  end;
end;

function ClampByte(V: Double): Byte;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := Round(V);
end;

procedure DoHSB(Bitmap: TBitmap; HueVal, SatVal, BriVal: Integer);
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  Sf, Bf: Double;
  Hdeg, S, Bn: Double;
  Pixel: TRGBTriple;
begin
  if (HueVal = 100) and (SatVal = 100) and (BriVal = 100) then Exit;

  Sf := SatVal / 100.0;
  Bf := BriVal / 100.0;

  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Pixel := Row[X];
      RgbToHsb(Pixel.R, Pixel.G, Pixel.B, Hdeg, S, Bn);

      Hdeg := Hdeg + (HueVal - 100) * 2.0;
      while Hdeg >= 360.0 do Hdeg := Hdeg - 360.0;
      while Hdeg < 0.0 do Hdeg := Hdeg + 360.0;

      S := S * Sf;
      if S > 1.0 then S := 1.0;
      if S < 0.0 then S := 0.0;

      Bn := Bn * Bf;
      if Bn > 1.0 then Bn := 1.0;
      if Bn < 0.0 then Bn := 0.0;

      Row[X] := HsbToRgb(Hdeg, S, Bn);
    end;
  end;
end;

function ShowHSBDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: THSBDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := THSBDlg.Create(Application);
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

{ THSBDlg }

procedure THSBDlg.FormCreate(Sender: TObject);
begin
  tbHue.Min := 0;
  tbHue.Max := 200;
  tbHue.Position := 100;
  tbSat.Min := 0;
  tbSat.Max := 200;
  tbSat.Position := 100;
  tbBri.Min := 0;
  tbBri.Max := 200;
  tbBri.Position := 100;
  lblValHue.Caption := '100';
  lblValSat.Caption := '100';
  lblValBri.Caption := '100';
end;

procedure THSBDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure THSBDlg.tbHueChange(Sender: TObject);
begin
  lblValHue.Caption := IntToStr(tbHue.Position);
  ApplyPreview;
end;

procedure THSBDlg.tbSatChange(Sender: TObject);
begin
  lblValSat.Caption := IntToStr(tbSat.Position);
  ApplyPreview;
end;

procedure THSBDlg.tbBriChange(Sender: TObject);
begin
  lblValBri.Caption := IntToStr(tbBri.Position);
  ApplyPreview;
end;

procedure THSBDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoHSB(FWorkingPreview, tbHue.Position, tbSat.Position, tbBri.Position);
  pboxPreview.Invalidate;
end;

procedure THSBDlg.ApplyFull;
begin
  DoHSB(FSourceBmp, tbHue.Position, tbSat.Position, tbBri.Position);
end;

procedure THSBDlg.pboxPreviewPaint(Sender: TObject);
var
  SrcW, SrcH: Integer;
  NewW, NewH: Integer;
  TargetW, TargetH: Integer;
  Scale: Double;
  DestRect: TRect;
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
    end;
  end;
end;

end.
