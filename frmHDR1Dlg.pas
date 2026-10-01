unit frmHDR1Dlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  THDR1Dlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblStrength: TLabel;
    lblSat: TLabel;
    lblContrast: TLabel;
    lblCurve: TLabel;
    tbStrength: TTrackBar;
    tbSat: TTrackBar;
    tbContrast: TTrackBar;
    tbCurve: TTrackBar;
    lblValStrength: TLabel;
    lblValSat: TLabel;
    lblValContrast: TLabel;
    lblValCurve: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure tbStrengthChange(Sender: TObject);
    procedure tbSatChange(Sender: TObject);
    procedure tbContrastChange(Sender: TObject);
    procedure tbCurveChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowHDR1Dlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoHDR1(Bitmap: TBitmap; Strength, SatBoost, ContrastBoost, CurveVal: Integer);

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

function ClampByte(V: Integer): Byte; inline;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := Byte(V);
end;

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
  if Max <> 0 then S := Delta / Max else S := 0;
  if Delta = 0 then H := 0
  else if Max = rr then H := 60.0 * (gg - bb) / Delta
  else if Max = gg then H := 60.0 * (bb - rr) / Delta + 120.0
  else H := 60.0 * (rr - gg) / Delta + 240.0;
  if H < 0 then H := H + 360.0;
  if H >= 360.0 then H := H - 360.0;
end;

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

procedure DoModulateHSB(Bitmap: TBitmap; Bri, Sat: Double);
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  Hdeg, S, B: Double;
begin
  if (Bri = 1.0) and (Sat = 1.0) then Exit;
  W := Bitmap.Width;
  H := Bitmap.Height;
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      RgbToHsb(Row[X].R, Row[X].G, Row[X].B, Hdeg, S, B);
      B := B * Bri; if B > 1.0 then B := 1.0;
      S := S * Sat; if S > 1.0 then S := 1.0;
      Row[X] := HsbToRgb(Hdeg, S, B);
    end;
  end;
end;

procedure DoContrastRepeat(Bitmap: TBitmap; Reps: Integer);
var
  W, H, X, Y, r: Integer;
  Row: PRGBTripleArray;
  Factor: Double;
begin
  if (Reps < 1) or (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;
  Factor := Power(1.1, 3);
  W := Bitmap.Width;
  H := Bitmap.Height;
  for r := 1 to Reps do
    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Row[X].R := ClampByte(Round((Row[X].R - 128) * Factor + 128));
        Row[X].G := ClampByte(Round((Row[X].G - 128) * Factor + 128));
        Row[X].B := ClampByte(Round((Row[X].B - 128) * Factor + 128));
      end;
    end;
end;

procedure DoHDR1(Bitmap: TBitmap; Strength, SatBoost, ContrastBoost, CurveVal: Integer);
var
  W, H, X, Y: Integer;
  OrigLines, VividLines: array of PRGBTripleArray;
  Vivid: TBitmap;
  LUT: array[0..255] of Double;
  CurveNorm: Double;
  Sat: Double;
  Reps: Integer;
  TotalReps: Integer;
  ro, go, bo, rv, gv, bv: Byte;
  lum_i, sw256, sat_o, sat_v, sat_w256, w256, s256: Integer;
  nr, ng, nb: Integer;
begin
  if (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;

  CurveNorm := 0.5 + CurveVal * 0.4;
  for X := 0 to 255 do
    LUT[X] := Power(1.0 - X / 255.0, CurveNorm);

  Vivid := TBitmap.Create;
  try
    Vivid.PixelFormat := pf24bit;
    Vivid.SetSize(Bitmap.Width, Bitmap.Height);
    Vivid.Canvas.Draw(0, 0, Bitmap);

    // 1. Modulate: brightness 1.2x, saturation boost
    Sat := 1.0 + (SatBoost / 100.0) * 3.0;
    DoModulateHSB(Vivid, 1.2, Sat);

    // 2. Contrast boost
    Reps := Max(1, ContrastBoost div 15);
    TotalReps := Reps * 5;
    if TotalReps > 0 then
      DoContrastRepeat(Vivid, TotalReps);

    // 3. Blend original + vivid
    W := Bitmap.Width;
    H := Bitmap.Height;
    SetLength(OrigLines, H);
    SetLength(VividLines, H);
    for Y := 0 to H - 1 do
    begin
      OrigLines[Y] := Bitmap.ScanLine[Y];
      VividLines[Y] := Vivid.ScanLine[Y];
    end;

    s256 := Strength * 256 div 100;

    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        ro := OrigLines[Y][X].R;
        go := OrigLines[Y][X].G;
        bo := OrigLines[Y][X].B;
        rv := VividLines[Y][X].R;
        gv := VividLines[Y][X].G;
        bv := VividLines[Y][X].B;

        lum_i := (77 * ro + 150 * go + 29 * bo) shr 8;
        sw256 := Round(LUT[lum_i] * 256.0);

        sat_o := Abs(ro - lum_i) + Abs(go - lum_i) + Abs(bo - lum_i);
        sat_v := Abs(rv - lum_i) + Abs(gv - lum_i) + Abs(bv - lum_i);
        sat_w256 := 256;
        if sat_o > 0 then
          sat_w256 := Min(512, (sat_v * 256) div sat_o);

        w256 := ((sw256 + sat_w256) * s256) shr 9;
        if w256 > 256 then w256 := 256;

        nr := (ro * (256 - w256) + rv * w256) shr 8;
        ng := (go * (256 - w256) + gv * w256) shr 8;
        nb := (bo * (256 - w256) + bv * w256) shr 8;
        if nr > 255 then nr := 255;
        if ng > 255 then ng := 255;
        if nb > 255 then nb := 255;

        OrigLines[Y][X].R := nr;
        OrigLines[Y][X].G := ng;
        OrigLines[Y][X].B := nb;
      end;
  finally
    Vivid.Free;
  end;
end;

function ShowHDR1Dlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: THDR1Dlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := THDR1Dlg.Create(Application);
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

{ THDR1Dlg }

procedure THDR1Dlg.FormCreate(Sender: TObject);
begin
  tbStrength.Min := 0; tbStrength.Max := 100; tbStrength.Position := 60;
  tbSat.Min := 0; tbSat.Max := 100; tbSat.Position := 50;
  tbContrast.Min := 0; tbContrast.Max := 100; tbContrast.Position := 40;
  tbCurve.Min := 1; tbCurve.Max := 5; tbCurve.Position := 2;
  lblValStrength.Caption := '60';
  lblValSat.Caption := '50';
  lblValContrast.Caption := '40';
  lblValCurve.Caption := '2';
end;

procedure THDR1Dlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure THDR1Dlg.tbStrengthChange(Sender: TObject);
begin
  lblValStrength.Caption := IntToStr(tbStrength.Position);
  ApplyPreview;
end;

procedure THDR1Dlg.tbSatChange(Sender: TObject);
begin
  lblValSat.Caption := IntToStr(tbSat.Position);
  ApplyPreview;
end;

procedure THDR1Dlg.tbContrastChange(Sender: TObject);
begin
  lblValContrast.Caption := IntToStr(tbContrast.Position);
  ApplyPreview;
end;

procedure THDR1Dlg.tbCurveChange(Sender: TObject);
begin
  lblValCurve.Caption := IntToStr(tbCurve.Position);
  ApplyPreview;
end;

procedure THDR1Dlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoHDR1(FWorkingPreview, tbStrength.Position, tbSat.Position,
    tbContrast.Position, tbCurve.Position);
  pboxPreview.Invalidate;
end;

procedure THDR1Dlg.ApplyFull;
begin
  DoHDR1(FSourceBmp, tbStrength.Position, tbSat.Position,
    tbContrast.Position, tbCurve.Position);
end;

procedure THDR1Dlg.pboxPreviewPaint(Sender: TObject);
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
        (TargetW - NewW) div 2, (TargetH - NewH) div 2,
        (TargetW - NewW) div 2 + NewW, (TargetH - NewH) div 2 + NewH);
      StretchDraw(DestRect, FWorkingPreview);
    end;
  end;
end;

end.
