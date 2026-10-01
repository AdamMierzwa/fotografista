unit frmBlendDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit,
  uConvolution, uAmiga, uI18n, uTitleBar;

type
  TBlendDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblEffectA: TLabel;
    cbEffectA: TComboBox;
    lblEffectB: TLabel;
    cbEffectB: TComboBox;
    lblMix: TLabel;
    tbMix: TTrackBar;
    lblMixVal: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure cbEffectAChange(Sender: TObject);
    procedure cbEffectBChange(Sender: TObject);
    procedure tbMixChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowBlendDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoGray(Bitmap: TBitmap);
procedure DoInvert(Bitmap: TBitmap);

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

const
  // Indeksy efektow wg blend.hws g_blend_fx (0 = Oryginal).
  FX_ORIGINAL   = 0;
  FX_GRAY       = 1;
  FX_INVERT     = 2;
  FX_CYANOTYPE  = 3;
  FX_SALTPRINT  = 4;
  FX_XRAY       = 5;
  FX_INFRARED   = 6;
  FX_NIGHTVISION = 7;
  FX_THERMAL    = 8;
  FX_ORTON      = 9;
  FX_WORKBENCH1 = 10;
  FX_WORKBENCH2 = 11;
  FX_MAGICWB    = 12;

function LumOf(R, G, B: Byte): Integer; inline;
begin
  Result := (R * 299 + G * 587 + B * 114) div 1000;
end;

procedure DoGray(Bitmap: TBitmap);
var
  W, H, X, Y, Lum: Integer;
  Row: PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Lum := LumOf(Row[X].R, Row[X].G, Row[X].B);
      Row[X].R := Byte(Lum);
      Row[X].G := Byte(Lum);
      Row[X].B := Byte(Lum);
    end;
  end;
end;

procedure DoInvert(Bitmap: TBitmap);
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Row[X].R := Byte(255 - Row[X].R);
      Row[X].G := Byte(255 - Row[X].G);
      Row[X].B := Byte(255 - Row[X].B);
    end;
  end;
end;

procedure DoTint(Bitmap: TBitmap; TcR, TcG, TcB, Level: Integer);
// TintBrush wg blend.hws: crossfade w kierunku koloru, Level 0-255.
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  T: Double;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  T := Level / 255.0;
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Row[X].R := Byte(Max(0, Min(255, Round(Row[X].R + (TcR - Row[X].R) * T))));
      Row[X].G := Byte(Max(0, Min(255, Round(Row[X].G + (TcG - Row[X].G) * T))));
      Row[X].B := Byte(Max(0, Min(255, Round(Row[X].B + (TcB - Row[X].B) * T))));
    end;
  end;
end;

procedure DoGamma(Bitmap: TBitmap; G: Double);
// GammaBrush: 1.0 = brak zmian, >1 rozjasnia (LUT 255*(x/255)^(1/G)).
var
  W, H, X, Y, I: Integer;
  Row: PRGBTripleArray;
  LUT: array[0..255] of Byte;
  Inv: Double;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Inv := 1.0 / G;
  for I := 0 to 255 do
    LUT[I] := Byte(Max(0, Min(255, Round(255 * Power(I / 255.0, Inv)))));
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Row[X].R := LUT[Row[X].R];
      Row[X].G := LUT[Row[X].G];
      Row[X].B := LUT[Row[X].B];
    end;
  end;
end;

procedure DoSwapRG(Bitmap: TBitmap);
// Podczerwien: zamiana kanalow R i G (blend.hws Case "infrared").
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  Tmp: Byte;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Tmp := Row[X].R;
      Row[X].R := Row[X].G;
      Row[X].G := Tmp;
    end;
  end;
end;

procedure DoNightVision(Bitmap: TBitmap);
var
  W, H, X, Y, Lum: Integer;
  Row: PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Lum := LumOf(Row[X].R, Row[X].G, Row[X].B);
      Row[X].R := Byte(Max(0, Min(255, Round(Lum * 0.15))));
      Row[X].G := Byte(Lum);
      Row[X].B := Byte(Max(0, Min(255, Round(Lum * 0.15))));
    end;
  end;
end;

procedure DoThermal(Bitmap: TBitmap);
var
  W, H, X, Y, Lum, Tr, Tg, Tb: Integer;
  Row: PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Lum := LumOf(Row[X].R, Row[X].G, Row[X].B);
      if Lum < 64 then
      begin
        Tr := 0;
        Tg := 0;
        Tb := Lum * 4;
      end
      else if Lum < 128 then
      begin
        Tr := 0;
        Tg := (Lum - 64) * 4;
        Tb := 255;
      end
      else if Lum < 192 then
      begin
        Tr := (Lum - 128) * 4;
        Tg := 255;
        Tb := 255 - (Lum - 128) * 4;
      end
      else
      begin
        Tr := 255;
        Tg := 255 - (Lum - 192) * 4;
        Tb := 0;
      end;
      Row[X].R := Byte(Max(0, Min(255, Tr)));
      Row[X].G := Byte(Max(0, Min(255, Tg)));
      Row[X].B := Byte(Max(0, Min(255, Tb)));
    end;
  end;
end;

procedure DoOrton(Bitmap: TBitmap);
// Orton wg blend.hws: rozmycie o r = max(1, min(w,h)/20),
// potem rout = (rd+rs-rd*rs)*0.5 + rd*0.5 na kazdym kanale.
var
  W, H, X, Y, Radius: Integer;
  Row, BlurRow: PRGBTripleArray;
  Blurred: TBitmap;
  Rd, Gd, Bd, Rs, Gs, Bs, Ro, Go, Bo: Double;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;
  Radius := Max(1, Min(W, H) div 20);
  Blurred := TBitmap.Create;
  try
    Blurred.PixelFormat := pf24bit;
    Blurred.SetSize(W, H);
    BoxBlur(Bitmap, Blurred, Radius);
    for Y := 0 to H - 1 do
    begin
      Row := Bitmap.ScanLine[Y];
      BlurRow := Blurred.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        Rd := Row[X].R / 255.0;
        Gd := Row[X].G / 255.0;
        Bd := Row[X].B / 255.0;
        Rs := BlurRow[X].R / 255.0;
        Gs := BlurRow[X].G / 255.0;
        Bs := BlurRow[X].B / 255.0;
        Ro := (Rd + Rs - Rd * Rs) * 0.5 + Rd * 0.5;
        Go := (Gd + Gs - Gd * Gs) * 0.5 + Gd * 0.5;
        Bo := (Bd + Bs - Bd * Bs) * 0.5 + Bd * 0.5;
        Row[X].R := Byte(Max(0, Min(255, Round(Ro * 255))));
        Row[X].G := Byte(Max(0, Min(255, Round(Go * 255))));
        Row[X].B := Byte(Max(0, Min(255, Round(Bo * 255))));
      end;
    end;
  finally
    Blurred.Free;
  end;
end;

procedure ApplyBlendEffect(Bitmap: TBitmap; FxIndex: Integer);
// Stosuje efekt bezparametrowy na bitmapie (wg blend.hws p_BlendApplyFxToId).
begin
  case FxIndex of
    FX_ORIGINAL: ;
    FX_GRAY: DoGray(Bitmap);
    FX_INVERT: DoInvert(Bitmap);
    FX_CYANOTYPE:
      begin
        DoGray(Bitmap);
        DoTint(Bitmap, 0, 48, 96, 80);
      end;
    FX_SALTPRINT:
      begin
        DoGray(Bitmap);
        DoTint(Bitmap, 139, 90, 43, 60);
      end;
    FX_XRAY:
      begin
        DoGray(Bitmap);
        DoInvert(Bitmap);
        DoGamma(Bitmap, 1.5);
      end;
    FX_INFRARED: DoSwapRG(Bitmap);
    FX_NIGHTVISION: DoNightVision(Bitmap);
    FX_THERMAL: DoThermal(Bitmap);
    FX_ORTON: DoOrton(Bitmap);
    FX_WORKBENCH1: ApplyWorkbench1(Bitmap);
    FX_WORKBENCH2: ApplyWorkbench2(Bitmap);
    FX_MAGICWB: ApplyMagicWB(Bitmap, True);
  end;
end;

procedure BlendTwo(SrcA, SrcB, Dst: TBitmap; T: Double);
// Blend per-pixel: out = A + (B - A) * T (wg blend.hws).
var
  W, H, X, Y: Integer;
  RowA, RowB, RowD: PRGBTripleArray;
  Ro, Go, Bo: Integer;
begin
  W := SrcA.Width;
  H := SrcA.Height;
  if (W = 0) or (H = 0) then Exit;
  for Y := 0 to H - 1 do
  begin
    RowA := SrcA.ScanLine[Y];
    RowB := SrcB.ScanLine[Y];
    RowD := Dst.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Ro := RowA[X].R + Round((RowB[X].R - RowA[X].R) * T);
      Go := RowA[X].G + Round((RowB[X].G - RowA[X].G) * T);
      Bo := RowA[X].B + Round((RowB[X].B - RowA[X].B) * T);
      RowD[X].R := Byte(Max(0, Min(255, Ro)));
      RowD[X].G := Byte(Max(0, Min(255, Go)));
      RowD[X].B := Byte(Max(0, Min(255, Bo)));
    end;
  end;
end;

function ShowBlendDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TBlendDlg;
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
    Dlg := TBlendDlg.Create(Application);
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

{ TBlendDlg }

procedure TBlendDlg.FormCreate(Sender: TObject);
begin
  cbEffectA.Items.Add(T('Original'));
  cbEffectA.Items.Add(T('Grayscale'));
  cbEffectA.Items.Add(T('Negative'));
  cbEffectA.Items.Add(T('Cyanotype'));
  cbEffectA.Items.Add(T('Salt print'));
  cbEffectA.Items.Add(T('X-Ray'));
  cbEffectA.Items.Add(T('False-color IR'));
  cbEffectA.Items.Add(T('Night vision'));
  cbEffectA.Items.Add(T('Thermal'));
  cbEffectA.Items.Add(T('Orton'));
  cbEffectA.Items.Add(T('WB 1.x'));
  cbEffectA.Items.Add(T('WB 2.x'));
  cbEffectA.Items.Add(T('MagicWB'));
  cbEffectB.Items.Assign(cbEffectA.Items);
  cbEffectA.ItemIndex := FX_ORIGINAL;
  cbEffectB.ItemIndex := FX_GRAY;   // domyslnie: oryginal vs szarosc
  tbMix.Min := 0;
  tbMix.Max := 100;
  tbMix.Position := 50;
  lblMixVal.Caption := IntToStr(tbMix.Position);
end;

procedure TBlendDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TBlendDlg.cbEffectAChange(Sender: TObject);
begin
  ApplyPreview;
end;

procedure TBlendDlg.cbEffectBChange(Sender: TObject);
begin
  ApplyPreview;
end;

procedure TBlendDlg.tbMixChange(Sender: TObject);
begin
  lblMixVal.Caption := IntToStr(tbMix.Position);
  ApplyPreview;
end;

procedure TBlendDlg.ApplyPreview;
var
  T: Double;
  TmpA, TmpB: TBitmap;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) then Exit;
  T := tbMix.Position / 100.0;
  TmpA := TBitmap.Create;
  TmpB := TBitmap.Create;
  try
    TmpA.PixelFormat := pf24bit;
    TmpA.Assign(FOriginalPreview);
    ApplyBlendEffect(TmpA, cbEffectA.ItemIndex);
    TmpB.PixelFormat := pf24bit;
    TmpB.Assign(FOriginalPreview);
    ApplyBlendEffect(TmpB, cbEffectB.ItemIndex);
    BlendTwo(TmpA, TmpB, FWorkingPreview, T);
  finally
    TmpA.Free;
    TmpB.Free;
  end;
  pboxPreview.Invalidate;
end;

procedure TBlendDlg.ApplyFull;
var
  T: Double;
  TmpA, TmpB: TBitmap;
begin
  T := tbMix.Position / 100.0;
  TmpA := TBitmap.Create;
  TmpB := TBitmap.Create;
  try
    TmpA.PixelFormat := pf24bit;
    TmpA.Assign(FSourceBmp);
    ApplyBlendEffect(TmpA, cbEffectA.ItemIndex);
    TmpB.PixelFormat := pf24bit;
    TmpB.Assign(FSourceBmp);
    ApplyBlendEffect(TmpB, cbEffectB.ItemIndex);
    BlendTwo(TmpA, TmpB, FSourceBmp, T);
  finally
    TmpA.Free;
    TmpB.Free;
  end;
end;

procedure TBlendDlg.pboxPreviewPaint(Sender: TObject);
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
