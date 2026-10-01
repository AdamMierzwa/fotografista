unit frmMakietaDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TMakietaDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblStrength: TLabel;
    tbStrength: TTrackBar;
    lblValStrength: TLabel;
    lblBandY: TLabel;
    tbBandY: TTrackBar;
    lblValBandY: TLabel;
    lblBandSize: TLabel;
    tbBandSize: TTrackBar;
    lblValBandSize: TLabel;
    lblFalloff: TLabel;
    tbFalloff: TTrackBar;
    lblValFalloff: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure tbStrengthChange(Sender: TObject);
    procedure tbBandYChange(Sender: TObject);
    procedure tbBandSizeChange(Sender: TObject);
    procedure tbFalloffChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowMakietaDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoMakieta(Bitmap: TBitmap; Strength, BandYPct, BandSizePct, FalloffPct: Integer);

implementation

uses
  uConvolution, uMacros;

{$R *.dfm}

procedure DoMakieta(Bitmap: TBitmap; Strength, BandYPct, BandSizePct, FalloffPct: Integer);
// Wrapper: suwaki -> znormalizowane parametry graduated blur (shape=1, pas poziomy).
// RenderGraduatedBlur skaluje promień bluru do szerokości obrazu, więc podgląd
// 400px i pełny oryginał dają spójny efekt względny.
begin
  RenderGraduatedBlur(Bitmap, Strength, 1,
    0.5, 0.5, BandSizePct / 100.0, FalloffPct / 100.0, BandYPct / 100.0);
end;

function ShowMakietaDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TMakietaDlg;
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
    Dlg := TMakietaDlg.Create(Application);
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
      gMacroPending.Code := 'MAKIETA';
      gMacroPending.Params := IntToStr(Dlg.tbStrength.Position) + '|' + IntToStr(Dlg.tbBandY.Position) + '|' + IntToStr(Dlg.tbBandSize.Position) + '|' + IntToStr(Dlg.tbFalloff.Position);
      Dlg.ApplyFull;
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TMakietaDlg }

procedure TMakietaDlg.FormCreate(Sender: TObject);
begin
  tbStrength.Position := 50;
  tbBandY.Position := 50;
  tbBandSize.Position := 30;
  tbFalloff.Position := 50;
  lblValStrength.Caption := IntToStr(tbStrength.Position);
  lblValBandY.Caption := IntToStr(tbBandY.Position);
  lblValBandSize.Caption := IntToStr(tbBandSize.Position);
  lblValFalloff.Caption := IntToStr(tbFalloff.Position);
end;

procedure TMakietaDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TMakietaDlg.tbStrengthChange(Sender: TObject);
begin
  lblValStrength.Caption := IntToStr(tbStrength.Position);
  ApplyPreview;
end;

procedure TMakietaDlg.tbBandYChange(Sender: TObject);
begin
  lblValBandY.Caption := IntToStr(tbBandY.Position);
  ApplyPreview;
end;

procedure TMakietaDlg.tbBandSizeChange(Sender: TObject);
begin
  lblValBandSize.Caption := IntToStr(tbBandSize.Position);
  ApplyPreview;
end;

procedure TMakietaDlg.tbFalloffChange(Sender: TObject);
begin
  lblValFalloff.Caption := IntToStr(tbFalloff.Position);
  ApplyPreview;
end;

procedure TMakietaDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoMakieta(FWorkingPreview, tbStrength.Position, tbBandY.Position,
    tbBandSize.Position, tbFalloff.Position);
  pboxPreview.Invalidate;
end;

procedure TMakietaDlg.ApplyFull;
begin
  DoMakieta(FSourceBmp, tbStrength.Position, tbBandY.Position,
    tbBandSize.Position, tbFalloff.Position);
end;

procedure TMakietaDlg.pboxPreviewPaint(Sender: TObject);
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
