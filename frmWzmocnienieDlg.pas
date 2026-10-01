unit frmWzmocnienieDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TWzmocnienieDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblStrength: TLabel;
    lblSC: TLabel;
    tbStrength: TTrackBar;
    tbSC: TTrackBar;
    lblValStrength: TLabel;
    lblValSC: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure tbStrengthChange(Sender: TObject);
    procedure tbSCChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowWzmocnienieDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

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

procedure DoGammaRGB(Bitmap: TBitmap; GammaR, GammaG, GammaB: Double);
var
  LUTR: array[0..255] of Byte;
  LUTG: array[0..255] of Byte;
  LUTB: array[0..255] of Byte;
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  i: Integer;
begin
  if (GammaR = 1.0) and (GammaG = 1.0) and (GammaB = 1.0) then Exit;
  for i := 0 to 255 do
  begin
    LUTR[i] := ClampByte(Round(255.0 * Power(i / 255.0, 1.0 / GammaR)));
    LUTG[i] := ClampByte(Round(255.0 * Power(i / 255.0, 1.0 / GammaG)));
    LUTB[i] := ClampByte(Round(255.0 * Power(i / 255.0, 1.0 / GammaB)));
  end;
  W := Bitmap.Width;
  H := Bitmap.Height;
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

procedure DoWzmocnienie(Bitmap: TBitmap; Strength, ScAmount: Integer);
var
  W, H, X, Y: Integer;
  OrigLines, VividLines: array of PRGBTripleArray;
  Vivid: TBitmap;
  sc: Double;
  s: Double;
  ro, go, bo, rv, gv, bv: Byte;
  screen_r, screen_g, screen_b: Integer;
  nr, ng, nb: Integer;
begin
  if (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;

  sc := ScAmount / 100.0;
  s := Strength / 100.0;

  Vivid := TBitmap.Create;
  try
    Vivid.PixelFormat := pf24bit;
    Vivid.SetSize(Bitmap.Width, Bitmap.Height);
    Vivid.Canvas.Draw(0, 0, Bitmap);

    // Smart Curves: per-channel gamma (Kodak-style)
    DoGammaRGB(Vivid,
      1.0 - sc * 0.40,   // R: darken slightly
      1.0 - sc * 0.30,   // G: darken slightly less
      1.0 + sc * 0.30);  // B: lighten

    // Modulate: brightness + saturation boost
    DoModulateHSB(Vivid,
      1.0 + sc * 0.30,   // brightness boost
      1.0 + sc * 0.60);  // saturation boost

    // Screen blend: original x vivid
    W := Bitmap.Width;
    H := Bitmap.Height;
    SetLength(OrigLines, H);
    SetLength(VividLines, H);
    for Y := 0 to H - 1 do
    begin
      OrigLines[Y] := Bitmap.ScanLine[Y];
      VividLines[Y] := Vivid.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        ro := OrigLines[Y][X].R;
        go := OrigLines[Y][X].G;
        bo := OrigLines[Y][X].B;
        rv := VividLines[Y][X].R;
        gv := VividLines[Y][X].G;
        bv := VividLines[Y][X].B;

        // Screen blend: 255 - (255-ro)*(255-rv)/255
        screen_r := 255 - ((255 - ro) * (255 - rv)) div 255;
        screen_g := 255 - ((255 - go) * (255 - gv)) div 255;
        screen_b := 255 - ((255 - bo) * (255 - bv)) div 255;

        // Lerp original -> screen by strength
        nr := ClampByte(Round(ro * (1.0 - s) + screen_r * s));
        ng := ClampByte(Round(go * (1.0 - s) + screen_g * s));
        nb := ClampByte(Round(bo * (1.0 - s) + screen_b * s));

        OrigLines[Y][X].R := nr;
        OrigLines[Y][X].G := ng;
        OrigLines[Y][X].B := nb;
      end;
  finally
    Vivid.Free;
  end;
end;

function ShowWzmocnienieDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TWzmocnienieDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TWzmocnienieDlg.Create(Application);
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

{ TWzmocnienieDlg }

procedure TWzmocnienieDlg.FormCreate(Sender: TObject);
begin
  tbStrength.Min := 0; tbStrength.Max := 100; tbStrength.Position := 60;
  tbSC.Min := 0; tbSC.Max := 100; tbSC.Position := 50;
  lblValStrength.Caption := '60';
  lblValSC.Caption := '50';
end;

procedure TWzmocnienieDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TWzmocnienieDlg.tbStrengthChange(Sender: TObject);
begin
  lblValStrength.Caption := IntToStr(tbStrength.Position);
  ApplyPreview;
end;

procedure TWzmocnienieDlg.tbSCChange(Sender: TObject);
begin
  lblValSC.Caption := IntToStr(tbSC.Position);
  ApplyPreview;
end;

procedure TWzmocnienieDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoWzmocnienie(FWorkingPreview, tbStrength.Position, tbSC.Position);
  pboxPreview.Invalidate;
end;

procedure TWzmocnienieDlg.ApplyFull;
begin
  DoWzmocnienie(FSourceBmp, tbStrength.Position, tbSC.Position);
end;

procedure TWzmocnienieDlg.pboxPreviewPaint(Sender: TObject);
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
