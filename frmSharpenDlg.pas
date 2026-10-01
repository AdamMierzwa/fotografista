unit frmSharpenDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TSharpenDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblIntensity: TLabel;
    tbAmount: TTrackBar;
    lblValue: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure tbAmountChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowSharpenDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoSharpen(Bitmap: TBitmap; Level: Integer);

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

function ClampByte(V: Integer): Byte; inline;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := Byte(V);
end;
function ClampInt(V, Lo, Hi: Integer): Integer; inline;
begin
  if V < Lo then Result := Lo
  else if V > Hi then Result := Hi
  else Result := V;
end;

const
  REFERENCE_WIDTH = 1000;

function ScaledRadius(SliderValue, ImageWidth: Integer): Integer;
begin
  Result := Max(1, Round(SliderValue * ImageWidth / REFERENCE_WIDTH));
end;

// Box blur (separable, horizontal then vertical, sliding window with edge clamping)
// All array accesses are bounds-safe with {$R+}
procedure BoxBlur(const Src: TBitmap; Dst: TBitmap; Radius: Integer);
var
  W, H, Y, X, Yi, Yc, Xi, Xc: Integer;
  SumR, SumG, SumB, Count: Integer;
  SrcRow, DstRow: PRGBTripleArray;
  Tmp: TBitmap;
  TmpLines, DstLines: array of PRGBTripleArray;
begin
  if (Radius < 1) or (Src.Width < 1) or (Src.Height < 1) then
  begin
    Dst.Assign(Src);
    Exit;
  end;

  W := Src.Width;
  H := Src.Height;

  Dst.PixelFormat := pf24bit;
  Dst.SetSize(W, H);

  Tmp := TBitmap.Create;
  try
    Tmp.PixelFormat := pf24bit;
    Tmp.SetSize(W, H);

    // Cache scanlines
    SetLength(TmpLines, H);
    SetLength(DstLines, H);
    for Y := 0 to H - 1 do
    begin
      TmpLines[Y] := Tmp.ScanLine[Y];
      DstLines[Y] := Dst.ScanLine[Y];
    end;

    // Horizontal pass: Src -> Tmp (sliding window, edge clamp)
    Count := 2 * Radius + 1;
    for Y := 0 to H - 1 do
    begin
      SrcRow := Src.ScanLine[Y];
      DstRow := TmpLines[Y];

      // Initialize window for X=0
      SumR := 0; SumG := 0; SumB := 0;
      for Xi := -Radius to Radius do
      begin
        Xc := ClampInt(Xi, 0, W - 1);
        Inc(SumR, SrcRow[Xc].R);
        Inc(SumG, SrcRow[Xc].G);
        Inc(SumB, SrcRow[Xc].B);
      end;
      DstRow[0].R := SumR div Count;
      DstRow[0].G := SumG div Count;
      DstRow[0].B := SumB div Count;

      // Slide window for X=1..W-1
      for X := 1 to W - 1 do
      begin
        Xi := X - Radius - 1;
        Xc := ClampInt(Xi, 0, W - 1);
        Dec(SumR, SrcRow[Xc].R);
        Dec(SumG, SrcRow[Xc].G);
        Dec(SumB, SrcRow[Xc].B);

        Xi := X + Radius;
        Xc := ClampInt(Xi, 0, W - 1);
        Inc(SumR, SrcRow[Xc].R);
        Inc(SumG, SrcRow[Xc].G);
        Inc(SumB, SrcRow[Xc].B);

        DstRow[X].R := SumR div Count;
        DstRow[X].G := SumG div Count;
        DstRow[X].B := SumB div Count;
      end;
    end;

    // Vertical pass: Tmp -> Dst (sliding window, edge clamp)
    for X := 0 to W - 1 do
    begin
      // Initialize window for Y=0
      SumR := 0; SumG := 0; SumB := 0;
      for Yi := -Radius to Radius do
      begin
        Yc := ClampInt(Yi, 0, H - 1);
        Inc(SumR, TmpLines[Yc][X].R);
        Inc(SumG, TmpLines[Yc][X].G);
        Inc(SumB, TmpLines[Yc][X].B);
      end;
      DstLines[0][X].R := SumR div Count;
      DstLines[0][X].G := SumG div Count;
      DstLines[0][X].B := SumB div Count;

      // Slide window for Y=1..H-1
      for Y := 1 to H - 1 do
      begin
        Yi := Y - Radius - 1;
        Yc := ClampInt(Yi, 0, H - 1);
        Dec(SumR, TmpLines[Yc][X].R);
        Dec(SumG, TmpLines[Yc][X].G);
        Dec(SumB, TmpLines[Yc][X].B);

        Yi := Y + Radius;
        Yc := ClampInt(Yi, 0, H - 1);
        Inc(SumR, TmpLines[Yc][X].R);
        Inc(SumG, TmpLines[Yc][X].G);
        Inc(SumB, TmpLines[Yc][X].B);

        DstLines[Y][X].R := SumR div Count;
        DstLines[Y][X].G := SumG div Count;
        DstLines[Y][X].B := SumB div Count;
      end;
    end;
  finally
    Tmp.Free;
  end;
end;

// Unsharp mask: result = original + (original - blurred)
procedure DoSharpen(Bitmap: TBitmap; Level: Integer);
var
  W, H, X, Y, Radius: Integer;
  Blurred: TBitmap;
  OrigLines, BlurLines: array of PRGBTripleArray;
begin
  if (Level < 1) or (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;

  Radius := ScaledRadius(Round(Level / 100.0 * 30), Bitmap.Width);

  Blurred := TBitmap.Create;
  try
    BoxBlur(Bitmap, Blurred, Radius);

    W := Bitmap.Width;
    H := Bitmap.Height;

    SetLength(OrigLines, H);
    SetLength(BlurLines, H);
    for Y := 0 to H - 1 do
    begin
      OrigLines[Y] := Bitmap.ScanLine[Y];
      BlurLines[Y] := Blurred.ScanLine[Y];
    end;

    for Y := 0 to H - 1 do
      for X := 0 to W - 1 do
      begin
        OrigLines[Y][X].R := ClampByte(OrigLines[Y][X].R + (OrigLines[Y][X].R - BlurLines[Y][X].R));
        OrigLines[Y][X].G := ClampByte(OrigLines[Y][X].G + (OrigLines[Y][X].G - BlurLines[Y][X].G));
        OrigLines[Y][X].B := ClampByte(OrigLines[Y][X].B + (OrigLines[Y][X].B - BlurLines[Y][X].B));
      end;
  finally
    Blurred.Free;
  end;
end;

function ShowSharpenDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TSharpenDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := TSharpenDlg.Create(Application);
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
      gMacroPending.Code := 'SHARPEN';
      gMacroPending.Params := IntToStr(Dlg.tbAmount.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TSharpenDlg }

procedure TSharpenDlg.FormCreate(Sender: TObject);
begin
  tbAmount.Min := 1;
  tbAmount.Max := 100;
  tbAmount.Position := 20;
  lblValue.Caption := '20';
end;

procedure TSharpenDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TSharpenDlg.tbAmountChange(Sender: TObject);
begin
  lblValue.Caption := IntToStr(tbAmount.Position);
  ApplyPreview;
end;

procedure TSharpenDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoSharpen(FWorkingPreview, tbAmount.Position);
  pboxPreview.Invalidate;
end;

procedure TSharpenDlg.ApplyFull;
begin
  DoSharpen(FSourceBmp, tbAmount.Position);
end;

procedure TSharpenDlg.pboxPreviewPaint(Sender: TObject);
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
