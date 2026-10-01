unit frmEmergoDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TEmergoDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblIntensity: TLabel;
    tbIntensity: TTrackBar;
    lblValIntensity: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure tbIntensityChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowEmergoDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoEmergo(Bitmap: TBitmap; Saturation: Integer);

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
  KodakLUT: array[0..255] of Byte = (
    2,1,3,7,13,20,27,34,39,43,47,50,53,56,59,61,
    63,65,67,69,71,73,75,77,80,82,85,87,89,91,93,95,
    97,99,101,103,105,106,108,109,110,111,112,113,115,117,119,121,
    122,123,124,125,125,126,126,127,128,129,130,131,132,133,134,135,
    135,136,138,139,141,142,143,145,146,147,147,147,144,141,138,137,
    138,139,140,142,143,144,145,147,148,150,151,151,152,153,154,155,
    156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,
    172,173,174,174,175,176,177,177,178,179,180,181,182,183,184,185,
    186,187,188,189,190,191,192,193,194,195,196,196,198,199,200,201,
    202,203,203,204,204,205,205,206,206,207,207,208,209,210,211,212,
    212,213,214,214,215,216,217,217,218,219,220,221,223,224,225,226,
    226,227,227,228,228,229,230,231,232,233,234,235,236,237,239,241,
    243,244,244,245,245,246,248,249,250,251,252,252,252,252,253,253,
    253,253,253,253,253,253,253,254,254,254,254,254,254,254,254,254,
    254,254,254,254,254,254,254,254,254,254,254,254,253,253,252,252,
    252,252,252,252,252,252,252,252,252,252,252,252,252,253,254,255);

function ClampByte(V: Integer): Byte; inline;
begin
  if V < 0 then Result := 0
  else if V > 255 then Result := 255
  else Result := Byte(V);
end;

procedure DoEmergo(Bitmap: TBitmap; Saturation: Integer);
var
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  r, g, b, new_y: Byte;
  yf, cb, cr: Double;
  sf: Double;
  nr, ng, nb: Integer;
begin
  if (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;

  W := Bitmap.Width;
  H := Bitmap.Height;
  sf := 1.0 + Saturation / 100.0;

  for Y := 0 to H - 1 do
  begin
    Row := Bitmap.ScanLine[Y];
    for X := 0 to W - 1 do
    begin
      r := Row[X].R;
      g := Row[X].G;
      b := Row[X].B;

      // RGB -> YCbCr
      yf := 0.299 * r + 0.587 * g + 0.114 * b;
      cb := -0.169 * r - 0.331 * g + 0.500 * b + 128.0;
      cr :=  0.500 * r - 0.419 * g - 0.081 * b + 128.0;

      // Apply Kodak LUT to luma
      new_y := KodakLUT[Max(0, Min(255, Trunc(yf)))];

      // Saturation boost
      if Saturation > 0 then
      begin
        cb := (cb - 128.0) * sf + 128.0;
        cr := (cr - 128.0) * sf + 128.0;
      end;

      // YCbCr -> RGB
      nr := Trunc(new_y + 1.402 * (cr - 128.0));
      ng := Trunc(new_y - 0.344 * (cb - 128.0) - 0.714 * (cr - 128.0));
      nb := Trunc(new_y + 1.773 * (cb - 128.0));

      Row[X].R := ClampByte(nr);
      Row[X].G := ClampByte(ng);
      Row[X].B := ClampByte(nb);
    end;
  end;
end;

function ShowEmergoDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TEmergoDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TEmergoDlg.Create(Application);
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

{ TEmergoDlg }

procedure TEmergoDlg.FormCreate(Sender: TObject);
begin
  tbIntensity.Min := 0; tbIntensity.Max := 100; tbIntensity.Position := 0;
  lblValIntensity.Caption := '0';
end;

procedure TEmergoDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TEmergoDlg.tbIntensityChange(Sender: TObject);
begin
  lblValIntensity.Caption := IntToStr(tbIntensity.Position);
  ApplyPreview;
end;

procedure TEmergoDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoEmergo(FWorkingPreview, tbIntensity.Position);
  pboxPreview.Invalidate;
end;

procedure TEmergoDlg.ApplyFull;
begin
  DoEmergo(FSourceBmp, tbIntensity.Position);
end;

procedure TEmergoDlg.pboxPreviewPaint(Sender: TObject);
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
