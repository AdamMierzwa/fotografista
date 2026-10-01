unit frmQuantizeDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uQuantize, uI18n, uTitleBar, uMacros;

type
  TQuantizeDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblColors: TLabel;
    tbColors: TTrackBar;
    lblCValue: TLabel;
    rgDither: TRadioGroup;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure tbColorsChange(Sender: TObject);
    procedure rgDitherClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowQuantizeDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

{$R *.dfm}

function ShowQuantizeDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TQuantizeDlg;
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
    Dlg := TQuantizeDlg.Create(Application);
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
      gMacroPending.Code := 'QUANTIZE';
      gMacroPending.Params := IntToStr(Dlg.tbColors.Position) + '|' + IntToStr(Ord(Dlg.rgDither.ItemIndex = 0));
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TQuantizeDlg }

procedure TQuantizeDlg.FormCreate(Sender: TObject);
begin
  tbColors.Min := 2;
  tbColors.Max := 64;
  tbColors.Position := 8;
  lblCValue.Caption := IntToStr(tbColors.Position);
  rgDither.Items.Add(T('With dither'));
  rgDither.Items.Add(T('Without dither'));
  rgDither.ItemIndex := 0;
end;

procedure TQuantizeDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TQuantizeDlg.tbColorsChange(Sender: TObject);
begin
  lblCValue.Caption := IntToStr(tbColors.Position);
  ApplyPreview;
end;

procedure TQuantizeDlg.rgDitherClick(Sender: TObject);
begin
  ApplyPreview;
end;

procedure TQuantizeDlg.ApplyPreview;
begin
  if not Assigned(FOriginalPreview) or not Assigned(FWorkingPreview) then Exit;
  FWorkingPreview.Canvas.Draw(0, 0, FOriginalPreview);
  DoQuantize(FWorkingPreview, tbColors.Position, rgDither.ItemIndex = 0);
  pboxPreview.Invalidate;
end;

procedure TQuantizeDlg.ApplyFull;
begin
  DoQuantize(FSourceBmp, tbColors.Position, rgDither.ItemIndex = 0);
end;

procedure TQuantizeDlg.pboxPreviewPaint(Sender: TObject);
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
