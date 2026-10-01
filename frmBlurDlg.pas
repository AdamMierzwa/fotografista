unit frmBlurDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TBlurDlg = class(TFotoForm)
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

function ShowBlurDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoBlur(Bitmap: TBitmap; Pct: Integer);

implementation

uses
  uConvolution, uMacros;

{$R *.dfm}

const
  REFERENCE_WIDTH = 1000;

function ScaledRadius(SliderValue, ImageWidth: Integer): Integer;
begin
  Result := Max(1, Round(SliderValue * ImageWidth / REFERENCE_WIDTH));
end;

procedure DoBlur(Bitmap: TBitmap; Pct: Integer);
// Wrapper: suwak 1..100 -> radius 1..30 w przeliczeniu na szerokość 1000px
// (wzorzec Hollywood: BlurBrush(level/100*30)). Radius skaluje się do szerokości
// obrazu, więc podgląd (400px) wygląda tak samo względnie jak oryginał.
var
  Radius: Integer;
  Tmp: TBitmap;
begin
  if (Bitmap.Width = 0) or (Bitmap.Height = 0) then Exit;

  Pct := Max(1, Min(100, Pct));
  Radius := ScaledRadius(Round(Pct / 100 * 30), Bitmap.Width);

  Tmp := TBitmap.Create;
  try
    BoxBlur(Bitmap, Tmp, Radius);
    Bitmap.Assign(Tmp);
  finally
    Tmp.Free;
  end;
end;

function ShowBlurDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TBlurDlg;
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
    Dlg := TBlurDlg.Create(Application);
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
      gMacroPending.Code := 'BLUR';
      gMacroPending.Params := IntToStr(Dlg.tbAmount.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TBlurDlg }

procedure TBlurDlg.FormCreate(Sender: TObject);
begin
  tbAmount.Min := 1;
  tbAmount.Max := 100;
  tbAmount.Position := 20;
  lblValue.Caption := IntToStr(tbAmount.Position);
end;

procedure TBlurDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TBlurDlg.tbAmountChange(Sender: TObject);
begin
  lblValue.Caption := IntToStr(tbAmount.Position);
  ApplyPreview;
end;

procedure TBlurDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoBlur(FWorkingPreview, tbAmount.Position);
  pboxPreview.Invalidate;
end;

procedure TBlurDlg.ApplyFull;
begin
  DoBlur(FSourceBmp, tbAmount.Position);
end;

procedure TBlurDlg.pboxPreviewPaint(Sender: TObject);
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
