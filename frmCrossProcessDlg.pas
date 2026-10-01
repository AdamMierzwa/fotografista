unit frmCrossProcessDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, uPreviewFit, uI18n, uTitleBar;

type
  TCrossProcessDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    rgPreset: TRadioGroup;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure rgPresetClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowCrossProcessDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoCrossProcess(Bitmap: TBitmap; Preset: Integer);

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
  TLUT = array[0..255] of Byte;

const
  // Punkty węzłowe krzywych: {x0,y0, x1,y1, ...} — pary (wejście, wyjście).
  // Dokładnie jak w Hollywood p_FxCrossProcessPreset (image_fx_effects.hws:1918-1938).
  PTS: array[0..4, 0..2, 0..9] of Integer = (
    // 0: E-6 w C-41
    ((0,30,  64,110, 128,165, 192,210, 255,255),
     (0,0,   64,80,  128,148, 192,200, 255,230),
     (0,60,  64,90,  128,110, 192,130, 255,160)),
    // 1: C-41 w E-6
    ((0,0,   64,50,  128,110, 192,170, 255,210),
     (0,20,  64,80,  128,150, 192,205, 255,240),
     (0,40,  64,100, 128,160, 192,210, 255,255)),
    // 2: Kodak w wywoływaczu Fuji
    ((0,10,  64,100, 128,170, 192,220, 255,255),
     (0,0,   64,70,  128,140, 192,195, 255,225),
     (0,0,   64,50,  128,100, 192,150, 255,185)),
    // 3: Fuji w wywoływaczu Kodak
    ((0,20,  64,90,  128,150, 192,200, 255,240),
     (0,30,  64,100, 128,165, 192,215, 255,250),
     (0,0,   64,40,  128,90,  192,145, 255,190)),
    // 4: ECN-2 w C-41
    ((0,50,  64,110, 128,175, 192,220, 255,245),
     (0,0,   64,55,  128,120, 192,180, 255,215),
     (0,70,  64,120, 128,155, 192,185, 255,205))
  );

function ClampByte(V: Integer): Byte; inline;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := Byte(V);
end;

procedure BuildLUT(const Pts: array of Integer; var Lut: TLUT);
// Interpolacja segmentowa punktów węzłowych (co 2: x,y). Wzorzec z Hollywood.
var
  V, I, X0, Y0, X1, Y1: Integer;
  T: Double;
begin
  for V := 0 to 255 do
  begin
    I := 0;
    while (I < Length(Pts) - 4) and (Pts[I + 2] <= V) do
      Inc(I, 2);
    X0 := Pts[I];
    Y0 := Pts[I + 1];
    X1 := Pts[I + 2];
    Y1 := Pts[I + 3];
    T := 0.0;
    if X1 > X0 then T := (V - X0) / (X1 - X0);
    Lut[V] := ClampByte(Round(Y0 + T * (Y1 - Y0)));
  end;
end;

procedure DoCrossProcess(Bitmap: TBitmap; Preset: Integer);
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  LutR, LutG, LutB: TLUT;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  if Bitmap.PixelFormat <> pf24bit then
    Bitmap.PixelFormat := pf24bit;

  if Preset < 0 then Preset := 0;
  if Preset > 4 then Preset := 4;

  BuildLUT(PTS[Preset, 0], LutR);
  BuildLUT(PTS[Preset, 1], LutG);
  BuildLUT(PTS[Preset, 2], LutB);

  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Row[X].R := LutR[Row[X].R];
      Row[X].G := LutG[Row[X].G];
      Row[X].B := LutB[Row[X].B];
    end;
  end;
end;

function ShowCrossProcessDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TCrossProcessDlg;
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
    Dlg := TCrossProcessDlg.Create(Application);
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
      gMacroPending.Code := 'CROSSPROCESS';
      gMacroPending.Params := IntToStr(Dlg.rgPreset.ItemIndex);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TCrossProcessDlg }

procedure TCrossProcessDlg.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to rgPreset.Items.Count - 1 do
    rgPreset.Items[I] := T(rgPreset.Items[I]);
  rgPreset.ItemIndex := 0;
end;

procedure TCrossProcessDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TCrossProcessDlg.rgPresetClick(Sender: TObject);
begin
  ApplyPreview;
end;

procedure TCrossProcessDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoCrossProcess(FWorkingPreview, rgPreset.ItemIndex);
  pboxPreview.Invalidate;
end;

procedure TCrossProcessDlg.ApplyFull;
begin
  DoCrossProcess(FSourceBmp, rgPreset.ItemIndex);
end;

procedure TCrossProcessDlg.pboxPreviewPaint(Sender: TObject);
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
