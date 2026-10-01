unit frmLevelsDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TLevelsDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblBlack: TLabel;
    tbBlack: TTrackBar;
    lblBlackVal: TLabel;
    lblGamma: TLabel;
    tbGamma: TTrackBar;
    lblGammaVal: TLabel;
    lblWhite: TLabel;
    tbWhite: TTrackBar;
    lblWhiteVal: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure tbBlackChange(Sender: TObject);
    procedure tbGammaChange(Sender: TObject);
    procedure tbWhiteChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowLevelsDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoLevels(Bitmap: TBitmap; Black, White, GammaPct: Integer);

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

procedure DoLevels(Bitmap: TBitmap; Black, White, GammaPct: Integer);
var
  LUT: array[0..255] of Byte;
  W, H, X, Y: Integer;
  Row: PRGBTripleArray;
  Gamma, RangeF, N: Double;
begin
  W := Bitmap.Width;
  H := Bitmap.Height;
  if (W = 0) or (H = 0) then Exit;

  if White <= Black then White := Black + 1;
  Gamma := GammaPct / 100.0;
  RangeF := White - Black;

  for X := 0 to 255 do
  begin
    if X <= Black then
      LUT[X] := 0
    else if X >= White then
      LUT[X] := 255
    else
    begin
      N := (X - Black) / RangeF;
      LUT[X] := Byte(Max(0, Min(255, Round(255 * Power(N, 1.0 / Gamma)))));
    end;
  end;

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

function ShowLevelsDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TLevelsDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := TLevelsDlg.Create(Application);
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
      gMacroPending.Code := 'LEVELS';
      gMacroPending.Params := IntToStr(Dlg.tbBlack.Position) + '|'
        + IntToStr(Dlg.tbWhite.Position) + '|' + IntToStr(Dlg.tbGamma.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TLevelsDlg }

procedure TLevelsDlg.FormCreate(Sender: TObject);
begin
  tbBlack.Min := 0;
  tbBlack.Max := 255;
  tbBlack.Position := 0;
  lblBlackVal.Caption := '0';

  tbGamma.Min := 10;
  tbGamma.Max := 500;
  tbGamma.Position := 100;
  lblGammaVal.Caption := '100';

  tbWhite.Min := 0;
  tbWhite.Max := 255;
  tbWhite.Position := 255;
  lblWhiteVal.Caption := '255';
end;

procedure TLevelsDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TLevelsDlg.tbBlackChange(Sender: TObject);
begin
  lblBlackVal.Caption := IntToStr(tbBlack.Position);
  ApplyPreview;
end;

procedure TLevelsDlg.tbGammaChange(Sender: TObject);
begin
  lblGammaVal.Caption := IntToStr(tbGamma.Position);
  ApplyPreview;
end;

procedure TLevelsDlg.tbWhiteChange(Sender: TObject);
begin
  lblWhiteVal.Caption := IntToStr(tbWhite.Position);
  ApplyPreview;
end;

procedure TLevelsDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoLevels(FWorkingPreview, tbBlack.Position, tbWhite.Position, tbGamma.Position);
  pboxPreview.Invalidate;
end;

procedure TLevelsDlg.ApplyFull;
begin
  DoLevels(FSourceBmp, tbBlack.Position, tbWhite.Position, tbGamma.Position);
end;

procedure TLevelsDlg.pboxPreviewPaint(Sender: TObject);
var
  SrcW, SrcH, NewW, NewH: Integer;
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
