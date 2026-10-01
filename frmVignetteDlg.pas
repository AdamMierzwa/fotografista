unit frmVignetteDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TVignetteDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblLabel: TLabel;
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

function ShowVignetteDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoVignette(Bitmap: TBitmap; Intensity: Integer);

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

procedure DoVignette(Bitmap: TBitmap; Intensity: Integer);
// Winietowanie (wzorzec z Hollywood p_FxVignette): przyciemnienie krawędzi.
// Per-pixel (odpowiednik elips warstwowych rysowanych od środka ku rogom):
//   t  = sqrt(((x-cx)/cx)^2 + ((y-cy)/cy)^2)  — znormalizowana odległość od środka
//   t2 = (t - 0.4) / 0.6                       — próg: nic poniżej 40% promienia
//   sm = 3*t2^2 - 2*t2^3                       — smoothstep
//   alfa = round(sm * alpha_max), alpha_max = intensity*2.55
//   out = oryginał * (255 - alfa) / 255        — środek alfa=0, rogi alfa=alpha_max
// Wynik zależy tylko od rozmiaru obrazu (żadnego parametru przestrzennego),
// więc podgląd 400px i pełny oryginał są spójne bez kompensacji skali.
var
  W, H, X, Y: Integer;
  cx, cy, dx, dy, t, t2, sm: Double;
  AlphaMax, Alpha: Integer;
  Factor: Double;
  Row: PRGBTripleArray;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  Intensity := Max(1, Min(100, Intensity));
  AlphaMax := Round(Intensity * 2.55);
  if AlphaMax <= 0 then Exit;

  cx := W / 2.0;
  cy := H / 2.0;

  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      dx := (X - cx) / cx;
      dy := (Y - cy) / cy;
      t := Sqrt(dx * dx + dy * dy);
      t2 := (t - 0.4) / 0.6;
      if t2 < 0.0 then t2 := 0.0
      else if t2 > 1.0 then t2 := 1.0;
      sm := (3.0 - 2.0 * t2) * t2 * t2;
      Alpha := Round(sm * AlphaMax);
      Factor := (255 - Alpha) / 255.0;
      Row[X].R := ClampByte(Round(Row[X].R * Factor));
      Row[X].G := ClampByte(Round(Row[X].G * Factor));
      Row[X].B := ClampByte(Round(Row[X].B * Factor));
    end;
  end;
end;

function ShowVignetteDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TVignetteDlg;
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
    Dlg := TVignetteDlg.Create(Application);
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
      gMacroPending.Code := 'VIGNETTE';
      gMacroPending.Params := IntToStr(Dlg.tbAmount.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TVignetteDlg }

procedure TVignetteDlg.FormCreate(Sender: TObject);
begin
  tbAmount.Min := 1;
  tbAmount.Max := 100;
  tbAmount.Position := 40;
  lblValue.Caption := IntToStr(tbAmount.Position);
end;

procedure TVignetteDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TVignetteDlg.tbAmountChange(Sender: TObject);
begin
  lblValue.Caption := IntToStr(tbAmount.Position);
  ApplyPreview;
end;

procedure TVignetteDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoVignette(FWorkingPreview, tbAmount.Position);
  pboxPreview.Invalidate;
end;

procedure TVignetteDlg.ApplyFull;
begin
  DoVignette(FSourceBmp, tbAmount.Position);
end;

procedure TVignetteDlg.pboxPreviewPaint(Sender: TObject);
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
