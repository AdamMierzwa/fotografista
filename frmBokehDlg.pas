unit frmBokehDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uPreviewFit, uTitleBar;

type
  TBokehDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lblStrength: TLabel;
    tbStrength: TTrackBar;
    lblValStrength: TLabel;
    lblCx: TLabel;
    tbCx: TTrackBar;
    lblValCx: TLabel;
    lblCy: TLabel;
    tbCy: TTrackBar;
    lblValCy: TLabel;
    lblRadius: TLabel;
    tbRadius: TTrackBar;
    lblValRadius: TLabel;
    lblFalloff: TLabel;
    tbFalloff: TTrackBar;
    lblValFalloff: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure tbStrengthChange(Sender: TObject);
    procedure tbCxChange(Sender: TObject);
    procedure tbCyChange(Sender: TObject);
    procedure tbRadiusChange(Sender: TObject);
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

function ShowBokehDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
procedure DoBokeh(Bitmap: TBitmap; Strength, CxPct, CyPct, RadPct, FalloffPct: Integer);

implementation

uses
  uConvolution, uMacros;

{$R *.dfm}

procedure DoBokeh(Bitmap: TBitmap; Strength, CxPct, CyPct, RadPct, FalloffPct: Integer);
// Wrapper: suwaki -> znormalizowane parametry graduated blur (shape=0, radialny).
// RenderGraduatedBlur skaluje promień bluru do szerokości obrazu, więc podgląd
// 400px i pełny oryginał dają spójny efekt względny.
begin
  RenderGraduatedBlur(Bitmap, Strength, 0,
    CxPct / 100.0, CyPct / 100.0, RadPct / 100.0, FalloffPct / 100.0, 0.5);
end;

function ShowBokehDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TBokehDlg;
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
    Dlg := TBokehDlg.Create(Application);
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
      gMacroPending.Code := 'BOKEH';
      gMacroPending.Params := IntToStr(Dlg.tbStrength.Position) + '|' + IntToStr(Dlg.tbCx.Position) + '|' + IntToStr(Dlg.tbCy.Position) + '|' + IntToStr(Dlg.tbRadius.Position) + '|' + IntToStr(Dlg.tbFalloff.Position);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TBokehDlg }

procedure TBokehDlg.FormCreate(Sender: TObject);
begin
  tbStrength.Position := 50;
  tbCx.Position := 50;
  tbCy.Position := 50;
  tbRadius.Position := 30;
  tbFalloff.Position := 50;
  lblValStrength.Caption := IntToStr(tbStrength.Position);
  lblValCx.Caption := IntToStr(tbCx.Position);
  lblValCy.Caption := IntToStr(tbCy.Position);
  lblValRadius.Caption := IntToStr(tbRadius.Position);
  lblValFalloff.Caption := IntToStr(tbFalloff.Position);
end;

procedure TBokehDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TBokehDlg.tbStrengthChange(Sender: TObject);
begin
  lblValStrength.Caption := IntToStr(tbStrength.Position);
  ApplyPreview;
end;

procedure TBokehDlg.tbCxChange(Sender: TObject);
begin
  lblValCx.Caption := IntToStr(tbCx.Position);
  ApplyPreview;
end;

procedure TBokehDlg.tbCyChange(Sender: TObject);
begin
  lblValCy.Caption := IntToStr(tbCy.Position);
  ApplyPreview;
end;

procedure TBokehDlg.tbRadiusChange(Sender: TObject);
begin
  lblValRadius.Caption := IntToStr(tbRadius.Position);
  ApplyPreview;
end;

procedure TBokehDlg.tbFalloffChange(Sender: TObject);
begin
  lblValFalloff.Caption := IntToStr(tbFalloff.Position);
  ApplyPreview;
end;

procedure TBokehDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  DoBokeh(FWorkingPreview, tbStrength.Position, tbCx.Position, tbCy.Position,
    tbRadius.Position, tbFalloff.Position);
  pboxPreview.Invalidate;
end;

procedure TBokehDlg.ApplyFull;
begin
  DoBokeh(FSourceBmp, tbStrength.Position, tbCx.Position, tbCy.Position,
    tbRadius.Position, tbFalloff.Position);
end;

procedure TBokehDlg.pboxPreviewPaint(Sender: TObject);
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
