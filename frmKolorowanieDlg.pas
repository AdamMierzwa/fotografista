unit frmKolorowanieDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TKolorowanieDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblColor: TLabel;
    btnPickColor: TButton;
    lblIntensity: TLabel;
    tbIntensity: TTrackBar;
    lblValIntensity: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure tbIntensityChange(Sender: TObject);
    procedure btnPickColorClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FTintColor: TColor;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowKolorowanieDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoTint(Bitmap: TBitmap; TintColor: TColor; Percent: Integer);

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

function ClampByte(V: Double): Byte;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := Round(V);
end;

procedure DoTint(Bitmap: TBitmap; TintColor: TColor; Percent: Integer);
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  sr, sg, sb: Byte;
  t, gray, tr, tg, tb: Double;
  Pixel: TRGBTriple;
begin
  if Percent = 0 then Exit;

  sr := GetRValue(TintColor);
  sg := GetGValue(TintColor);
  sb := GetBValue(TintColor);
  t := Percent / 100.0;

  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      Pixel := Row[X];
      gray := Pixel.R * 0.299 + Pixel.G * 0.587 + Pixel.B * 0.114;

      tr := sr * gray / 255.0;
      tg := sg * gray / 255.0;
      tb := sb * gray / 255.0;

      Row[X].R := ClampByte((1.0 - t) * gray + t * tr);
      Row[X].G := ClampByte((1.0 - t) * gray + t * tg);
      Row[X].B := ClampByte((1.0 - t) * gray + t * tb);
    end;
  end;
end;

function ShowKolorowanieDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TKolorowanieDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := TKolorowanieDlg.Create(Application);
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
      gMacroPending.Code := 'COLORIZE';
      gMacroPending.Params := IntToStr(Integer(Dlg.FTintColor)) + '|' + IntToStr(Dlg.tbIntensity.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TKolorowanieDlg }

procedure TKolorowanieDlg.FormCreate(Sender: TObject);
begin
  FTintColor := RGB(255, 0, 0);
  tbIntensity.Min := 0;
  tbIntensity.Max := 100;
  tbIntensity.Position := 50;
  lblValIntensity.Caption := '50';
end;

procedure TKolorowanieDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TKolorowanieDlg.tbIntensityChange(Sender: TObject);
begin
  lblValIntensity.Caption := IntToStr(tbIntensity.Position);
  ApplyPreview;
end;

procedure TKolorowanieDlg.btnPickColorClick(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FTintColor;
    if Dlg.Execute then
    begin
      FTintColor := Dlg.Color;
      ApplyPreview;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TKolorowanieDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoTint(FWorkingPreview, FTintColor, tbIntensity.Position);
  pboxPreview.Invalidate;
end;

procedure TKolorowanieDlg.ApplyFull;
begin
  DoTint(FSourceBmp, FTintColor, tbIntensity.Position);
end;

procedure TKolorowanieDlg.pboxPreviewPaint(Sender: TObject);
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
