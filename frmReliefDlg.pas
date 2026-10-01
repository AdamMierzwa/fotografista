unit frmReliefDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TReliefDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblMaterial: TLabel;
    cbMaterial: TComboBox;
    lblDepth: TLabel;
    tbDepth: TTrackBar;
    lblDepthValue: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure cbMaterialChange(Sender: TObject);
    procedure tbDepthChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowReliefDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoRelief(Bitmap: TBitmap; DepthPct, Material: Integer);

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
  PByteArray = ^TByteArray;
  TByteArray = array[0..MaxInt div SizeOf(Byte) - 1] of Byte;

function ClampByte(V: Integer): Byte; inline;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := Byte(V);
end;

function ClampTone(V: Double): Double; inline;
begin
  if V < 0.18 then Result := 0.18
  else if V > 1.35 then Result := 1.35
  else Result := V;
end;

procedure DoRelief(Bitmap: TBitmap; DepthPct: Integer; Material: Integer);
// Płaskorzeźba materiałowa — algorytm wg Hollywood (p_RenderRelief).
// Luminancja -> smooth 3x3 -> wektor normalny z gradientu,
// oświetlenie lx=-0.55, ly=-0.65, lz=0.52 (znormalizowane),
// light = 0.58 + dot*0.52, plane = (smooth-128)/255*0.18,
// ziarno zależne od materiału, ton w zakresie 0.18..1.35,
// kolor bazowy materiału * ton.
var
  W, H, X, Y, XX, YY, Sum, Cnt, S: Integer;
  Depth, lx, ly, lz, lLen, sx, sy, nz, len, dot, light, plane, grain, tone: Double;
  Br, Bg, Bb: Integer;
  HeightArr, SmoothArr: array of Integer;
  Lines: array of PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  if Bitmap.PixelFormat <> pf24bit then
    Bitmap.PixelFormat := pf24bit;

  if Material < 0 then Material := 0;
  if Material > 4 then Material := 4;
  DepthPct := Max(1, Min(100, DepthPct));

  Br := 224; Bg := 222; Bb := 214;
  case Material of
    1: begin Br := 238; Bg := 238; Bb := 232; end;
    2: begin Br := 158; Bg := 154; Bb := 145; end;
    3: begin Br := 174; Bg := 118; Bb := 58; end;
    4: begin Br := 203; Bg := 174; Bb := 124; end;
  end;

  Depth := 1.0 + DepthPct / 100.0 * 7.0;
  lx := -0.55; ly := -0.65; lz := 0.52;
  lLen := Sqrt(lx * lx + ly * ly + lz * lz);
  lx := lx / lLen; ly := ly / lLen; lz := lz / lLen;

  SetLength(HeightArr, W * H);
  SetLength(SmoothArr, W * H);
  SetLength(Lines, H);
  for Y := 0 to H - 1 do
    Lines[Y] := Bitmap.ScanLine[Y];

  // Luminancja (299/587/114)
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
      HeightArr[Y * W + X] :=
        (299 * Lines[Y][X].R + 587 * Lines[Y][X].G + 114 * Lines[Y][X].B) div 1000;

  // Smooth 3x3 (średnia, brzegi pomijane)
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      Sum := 0; Cnt := 0;
      for YY := Y - 1 to Y + 1 do
        if (YY >= 0) and (YY < H) then
          for XX := X - 1 to X + 1 do
            if (XX >= 0) and (XX < W) then
            begin
              Sum := Sum + HeightArr[YY * W + XX];
              Inc(Cnt);
            end;
      SmoothArr[Y * W + X] := Sum div Cnt;
    end;

  // Normalne + oświetlenie + materiał
  for Y := 0 to H - 1 do
    for X := 0 to W - 1 do
    begin
      S := SmoothArr[Y * W + X];
      sx := (SmoothArr[Y * W + Max(0, X - 1)] - SmoothArr[Y * W + Min(W - 1, X + 1)]) * Depth;
      sy := (SmoothArr[Max(0, Y - 1) * W + X] - SmoothArr[Min(H - 1, Y + 1) * W + X]) * Depth;
      nz := 96.0;
      len := Sqrt(sx * sx + sy * sy + nz * nz);
      dot := (sx * lx + sy * ly + nz * lz) / len;
      if dot < -1.0 then dot := -1.0;
      if dot > 1.0 then dot := 1.0;
      light := 0.58 + dot * 0.52;
      plane := (S - 128) / 255.0 * 0.18;
      grain := 0.0;
      if Material = 1 then
      begin
        if ((X * 13 + Y * 7 + S) mod 41) < 2 then grain := -0.10;
      end
      else if (Material = 2) or (Material = 4) then
        grain := (((X * 17 + Y * 31) mod 23) - 11) / 255.0;

      tone := ClampTone(light + plane + grain);
      Lines[Y][X].R := ClampByte(Round(Br * tone));
      Lines[Y][X].G := ClampByte(Round(Bg * tone));
      Lines[Y][X].B := ClampByte(Round(Bb * tone));
    end;
end;

function ShowReliefDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TReliefDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := nil;
  try
    Dlg := TReliefDlg.Create(Application);
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
      gMacroPending.Code := 'RELIEF';
      gMacroPending.Params := IntToStr(Dlg.tbDepth.Position) + '|'
        + IntToStr(Dlg.cbMaterial.ItemIndex);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TReliefDlg }

procedure TReliefDlg.FormCreate(Sender: TObject);
begin
  cbMaterial.Items.Add('Gips / bia'#322'y kamie'#324);
  cbMaterial.Items.Add('Bia'#322'y marmur');
  cbMaterial.Items.Add('Szary kamie'#324);
  cbMaterial.Items.Add('Br'#261'z / medal');
  cbMaterial.Items.Add('Piaskowiec');
  cbMaterial.ItemIndex := 0;
  tbDepth.Min := 1;
  tbDepth.Max := 100;
  tbDepth.Position := 35;
  lblDepthValue.Caption := IntToStr(tbDepth.Position);
end;

procedure TReliefDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TReliefDlg.cbMaterialChange(Sender: TObject);
begin
  ApplyPreview;
end;

procedure TReliefDlg.tbDepthChange(Sender: TObject);
begin
  lblDepthValue.Caption := IntToStr(tbDepth.Position);
  ApplyPreview;
end;

procedure TReliefDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoRelief(FWorkingPreview, tbDepth.Position, cbMaterial.ItemIndex);
  pboxPreview.Invalidate;
end;

procedure TReliefDlg.ApplyFull;
begin
  DoRelief(FSourceBmp, tbDepth.Position, cbMaterial.ItemIndex);
end;

procedure TReliefDlg.pboxPreviewPaint(Sender: TObject);
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
