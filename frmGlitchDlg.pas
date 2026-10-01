unit frmGlitchDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TGlitchDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblShift: TLabel;
    lblShiftVal: TLabel;
    tbShift: TTrackBar;
    lblJitter: TLabel;
    lblJitterVal: TLabel;
    tbJitter: TTrackBar;
    lblNoise: TLabel;
    lblNoiseVal: TLabel;
    tbNoise: TTrackBar;
    lblScanlines: TLabel;
    lblScanVal: TLabel;
    tbScanlines: TTrackBar;
    lblBlock: TLabel;
    lblBlockVal: TLabel;
    tbBlock: TTrackBar;
    lblTracking: TLabel;
    lblTrackVal: TLabel;
    tbTracking: TTrackBar;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure tbShiftChange(Sender: TObject);
    procedure tbJitterChange(Sender: TObject);
    procedure tbNoiseChange(Sender: TObject);
    procedure tbScanlinesChange(Sender: TObject);
    procedure tbBlockChange(Sender: TObject);
    procedure tbTrackingChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FPreviewScale: Double;
    procedure ApplyPreview;
    procedure ApplyFull;
    procedure UpdateLabels;
  end;

function ShowGlitchDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

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

  TGlitchParams = record
    RGBShift: Integer;
    Jitter: Integer;
    Noise: Integer;
    Scanlines: Integer;
    BlockLoss: Integer;
    Tracking: Integer;
  end;

function ClampByte(V: Integer): Byte; inline;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := Byte(V);
end;

procedure DoGlitch(Bitmap: TBitmap; const P: TGlitchParams; PreviewScale: Double);
// Cyfrowe zaklucenia wg Hollywood p_ApplyGlitch (image_fx_glitch.hws:4-149).
// Random(N) = Rnd(N) (0..N-1), Trunc = Int, PreviewScale = g_preview_scale.
var
  W, H, X, Y, I, S: Integer;
  Scale, Dark: Double;
  NV, ScanStep: Integer;
  IsScanline: Boolean;
  JEff, TEff, MaxOff, Shift, MaxShift, AShift: Integer;
  NBlocks, Blk, Bw, Bh, Bx, By, Bx2, By2: Integer;
  NSlices, Sl, Sy, Sh, Sy2: Integer;
  EdgeR, EdgeG, EdgeB: Byte;
  SrcArr, DstArr: array of TRGBTriple;
  Row: PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  if Bitmap.PixelFormat <> pf24bit then
    Bitmap.PixelFormat := pf24bit;

  // Deterministiczny RNG: ten sam zestaw parametrow daje ten sam uklad pasm.
  // Zmiana samego RGB shift (nie zuzywa Random) nie przemieszcza pasm.
  RandSeed := $12345678;

  Scale := W / 720.0;

  SetLength(SrcArr, W * H);
  SetLength(DstArr, W * H);

  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
      SrcArr[Y * W + X] := Row[X];
  end;

  // --- 1. RGB Shift (czyta SrcArr, pisze DstArr) ---
  if P.RGBShift > 0 then
  begin
    S := Max(1, Trunc(P.RGBShift * Scale));
    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        I := Y * W + X;
        DstArr[I].R := SrcArr[Y * W + Min(X + S, W - 1)].R;
        DstArr[I].G := SrcArr[Y * W + X].G;
        DstArr[I].B := SrcArr[Y * W + Max(X - S, 0)].B;
      end;
  end
  else
  begin
    for I := 0 to W * H - 1 do
      DstArr[I] := SrcArr[I];
  end;

  // --- 2. Szum + linie kineskopu (na DstArr) ---
  if (P.Noise > 0) or (P.Scanlines > 0) then
  begin
    if P.Scanlines > 0 then
      ScanStep := Max(2, Trunc(H / 288 + 0.5))
    else
      ScanStep := 0;
    for Y := 0 to H - 1 do
    begin
      if P.Scanlines > 0 then
        IsScanline := (Y mod ScanStep) = 0
      else
        IsScanline := False;
      for X := 0 to W - 1 do
      begin
        I := Y * W + X;
        if P.Noise > 0 then
        begin
          NV := Trunc((Random(257) - 128) * P.Noise / 100);
          DstArr[I].R := ClampByte(DstArr[I].R + NV);
          DstArr[I].G := ClampByte(DstArr[I].G + NV);
          DstArr[I].B := ClampByte(DstArr[I].B + NV);
        end;
        if IsScanline then
        begin
          Dark := 1.0 - P.Scanlines / 100.0 * 0.6;
          DstArr[I].R := Byte(Trunc(DstArr[I].R * Dark));
          DstArr[I].G := Byte(Trunc(DstArr[I].G * Dark));
          DstArr[I].B := Byte(Trunc(DstArr[I].B * Dark));
        end;
      end;
    end;
  end;

  // --- 3. Drzenie linii ---
  JEff := P.Jitter;
  if PreviewScale < 1.0 then
    JEff := Max(1, Trunc(P.Jitter * PreviewScale));
  if JEff > 0 then
  begin
    for Y := 0 to H - 1 do
    begin
      if Random(100) < JEff then
      begin
        MaxOff := Max(1, Trunc(JEff / 5 * Scale));
        Shift := Random(MaxOff * 2 + 1) - MaxOff;
        if Shift > 0 then
        begin
          for X := W - 1 downto Shift do
            DstArr[Y * W + X] := DstArr[Y * W + X - Shift];
        end
        else if Shift < 0 then
        begin
          for X := 0 to W + Shift - 1 do
            DstArr[Y * W + X] := DstArr[Y * W + X - Shift];
        end;
      end;
    end;
  end;

  // --- 4. Utrata blokow ---
  if P.BlockLoss > 0 then
  begin
    NBlocks := Trunc(P.BlockLoss / 8) + 1;
    for Blk := 0 to NBlocks - 1 do
    begin
      Bx := Random(W);
      By := Random(H);
      Bw := Random(Max(1, Trunc(25 * Scale))) + Max(1, Trunc(8 * Scale));
      Bh := Random(Max(1, Trunc(10 * Scale))) + Max(1, Trunc(4 * Scale));
      Bx2 := Min(Bx + Bw, W - 1);
      By2 := Min(By + Bh, H - 1);
      for Y := By to By2 do
        for X := Bx to Bx2 do
        begin
          I := Y * W + X;
          DstArr[I].R := Random(256);
          DstArr[I].G := Random(256);
          DstArr[I].B := Random(256);
        end;
    end;
  end;

  // --- 5. Przesuniecia pasm poziomych ---
  TEff := P.Tracking;
  if PreviewScale < 1.0 then
    TEff := Max(1, Trunc(P.Tracking * PreviewScale));
  if TEff > 0 then
  begin
    NSlices := Trunc(TEff / 8) + 1;
    MaxShift := Max(1, Trunc(120 * Scale * TEff / 100));
    for Sl := 0 to NSlices - 1 do
    begin
      Sy := Random(H);
      Sh := Random(Max(1, Trunc(50 * Scale))) + Max(1, Trunc(6 * Scale));
      Sy2 := Min(Sy + Sh - 1, H - 1);
      Shift := Random(MaxShift * 2 + 1) - MaxShift;
      if Shift <> 0 then
        for Y := Sy to Sy2 do
        begin
          if Shift > 0 then
          begin
            EdgeR := DstArr[Y * W].R;
            EdgeG := DstArr[Y * W].G;
            EdgeB := DstArr[Y * W].B;
            for X := W - 1 downto Shift do
              DstArr[Y * W + X] := DstArr[Y * W + X - Shift];
            for X := 0 to Shift - 1 do
            begin
              DstArr[Y * W + X].R := EdgeR;
              DstArr[Y * W + X].G := EdgeG;
              DstArr[Y * W + X].B := EdgeB;
            end;
          end
          else
          begin
            AShift := -Shift;
            EdgeR := DstArr[Y * W + W - 1].R;
            EdgeG := DstArr[Y * W + W - 1].G;
            EdgeB := DstArr[Y * W + W - 1].B;
            for X := 0 to W - AShift - 1 do
              DstArr[Y * W + X] := DstArr[Y * W + X + AShift];
            for X := W - AShift to W - 1 do
            begin
              DstArr[Y * W + X].R := EdgeR;
              DstArr[Y * W + X].G := EdgeG;
              DstArr[Y * W + X].B := EdgeB;
            end;
          end;
        end;
    end;
  end;

  // Zapis wynikow
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
      Row[X] := DstArr[Y * W + X];
  end;
end;

function ShowGlitchDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TGlitchDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := nil;
  try
    Dlg := TGlitchDlg.Create(Application);
    Dlg.FSourceBmp := Bitmap;

    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));
    Dlg.FPreviewScale := Scale;

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

{ TGlitchDlg }

procedure TGlitchDlg.FormCreate(Sender: TObject);
begin
  tbShift.Min := 0;
  tbShift.Max := 30;
  tbShift.Position := 0;
  tbJitter.Min := 0;
  tbJitter.Max := 100;
  tbJitter.Position := 0;
  tbNoise.Min := 0;
  tbNoise.Max := 100;
  tbNoise.Position := 0;
  tbScanlines.Min := 0;
  tbScanlines.Max := 100;
  tbScanlines.Position := 0;
  tbBlock.Min := 0;
  tbBlock.Max := 100;
  tbBlock.Position := 0;
  tbTracking.Min := 0;
  tbTracking.Max := 100;
  tbTracking.Position := 0;
  UpdateLabels;
end;

procedure TGlitchDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TGlitchDlg.UpdateLabels;
begin
  lblShiftVal.Caption := IntToStr(tbShift.Position);
  lblJitterVal.Caption := IntToStr(tbJitter.Position);
  lblNoiseVal.Caption := IntToStr(tbNoise.Position);
  lblScanVal.Caption := IntToStr(tbScanlines.Position);
  lblBlockVal.Caption := IntToStr(tbBlock.Position);
  lblTrackVal.Caption := IntToStr(tbTracking.Position);
end;

procedure TGlitchDlg.tbShiftChange(Sender: TObject);
begin
  UpdateLabels;
  ApplyPreview;
end;

procedure TGlitchDlg.tbJitterChange(Sender: TObject);
begin
  UpdateLabels;
  ApplyPreview;
end;

procedure TGlitchDlg.tbNoiseChange(Sender: TObject);
begin
  UpdateLabels;
  ApplyPreview;
end;

procedure TGlitchDlg.tbScanlinesChange(Sender: TObject);
begin
  UpdateLabels;
  ApplyPreview;
end;

procedure TGlitchDlg.tbBlockChange(Sender: TObject);
begin
  UpdateLabels;
  ApplyPreview;
end;

procedure TGlitchDlg.tbTrackingChange(Sender: TObject);
begin
  UpdateLabels;
  ApplyPreview;
end;

procedure TGlitchDlg.ApplyPreview;
var
  P: TGlitchParams;
begin
  P.RGBShift := tbShift.Position;
  P.Jitter := tbJitter.Position;
  P.Noise := tbNoise.Position;
  P.Scanlines := tbScanlines.Position;
  P.BlockLoss := tbBlock.Position;
  P.Tracking := tbTracking.Position;
  FWorkingPreview.Assign(FOriginalPreview);
  DoGlitch(FWorkingPreview, P, FPreviewScale);
  pboxPreview.Invalidate;
end;

procedure TGlitchDlg.ApplyFull;
var
  P: TGlitchParams;
begin
  P.RGBShift := tbShift.Position;
  P.Jitter := tbJitter.Position;
  P.Noise := tbNoise.Position;
  P.Scanlines := tbScanlines.Position;
  P.BlockLoss := tbBlock.Position;
  P.Tracking := tbTracking.Position;
  DoGlitch(FSourceBmp, P, 1.0);
end;

procedure TGlitchDlg.pboxPreviewPaint(Sender: TObject);
var
  SrcW, SrcH, NewW, NewH, TargetW, TargetH: Integer;
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
