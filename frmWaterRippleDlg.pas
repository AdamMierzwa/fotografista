unit frmWaterRippleDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uDistort, uI18n, uTitleBar, uPreviewFit;

type
  TDistortProcEx = procedure(Bmp: TBitmap; Preset: Integer; Strength, Density: Double);

  TWaterRippleDlg = class(TFotoForm)
    pnlPreview: TPanel;
    pnlSliders: TPanel;
    pboxPreview: TPaintBox;
    lbPresets: TListBox;
    lblStrength: TLabel;
    trkStrength: TTrackBar;
    lblStrengthVal: TLabel;
    lblDensity: TLabel;
    trkDensity: TTrackBar;
    lblDensityVal: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure lbPresetsClick(Sender: TObject);
    procedure trkSliderChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FEffectProc: TDistortProcEx;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowWaterRippleDlg(const Title: string; const Items: array of string; EffectProc: TDistortProcEx; Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

{$R *.dfm}

function ShowWaterRippleDlg(const Title: string; const Items: array of string; EffectProc: TDistortProcEx; Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TWaterRippleDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
  I: Integer;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TWaterRippleDlg.Create(Application);
  try
    Dlg.Caption := Title;
    Dlg.FSourceBmp := Bitmap;
    Dlg.FEffectProc := EffectProc;

    Dlg.lbPresets.Clear;
    for I := Low(Items) to High(Items) do
      Dlg.lbPresets.Items.Add(Items[I]);
    if Dlg.lbPresets.Items.Count > 0 then
      Dlg.lbPresets.ItemIndex := 0;

    Scale := Min(370.0 / Bitmap.Width, 300.0 / Bitmap.Height);
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

    FitPreviewToDialog(Dlg, Dlg.pnlPreview, Dlg.pboxPreview, pw, ph);

    Dlg.lbPresets.ItemHeight := Dlg.lbPresets.Canvas.TextHeight('Wg') + 2;
    Dlg.lbPresets.Top := Dlg.pboxPreview.Top + Dlg.pboxPreview.Height + Dlg.CtrlGap;
    Dlg.lbPresets.Height := Dlg.lbPresets.Items.Count * Dlg.lbPresets.ItemHeight + 8;
    Dlg.pnlPreview.Height := Dlg.lbPresets.Top + Dlg.lbPresets.Height + Dlg.CtrlGap + 2;
    Dlg.ReflowTrackBarRows(Dlg.pnlSliders);
    Dlg.pnlSliders.Height := Dlg.lblDensityVal.Top + Dlg.lblDensityVal.Height + Dlg.CtrlGap;
    Dlg.btnOK.Top := Max(Dlg.pnlPreview.Top + Dlg.pnlPreview.Height,
                         Dlg.pnlSliders.Top + Dlg.pnlSliders.Height) + Dlg.CtrlGap * 3;
    Dlg.btnCancel.Top := Dlg.btnOK.Top;
    Dlg.AlignButtonsRight([Dlg.btnOK, Dlg.btnCancel], Dlg.CtrlGap * 3);
    Dlg.FitHeight(Dlg.CtrlGap * 3);

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

{ TWaterRippleDlg }

procedure TWaterRippleDlg.FormCreate(Sender: TObject);
begin
  trkStrength.Position := 100;
  trkDensity.Position := 100;
  lblStrengthVal.Caption := IntToStr(trkStrength.Position);
  lblDensityVal.Caption := IntToStr(trkDensity.Position);
end;

procedure TWaterRippleDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TWaterRippleDlg.trkSliderChange(Sender: TObject);
begin
  lblStrengthVal.Caption := IntToStr(trkStrength.Position);
  lblDensityVal.Caption := IntToStr(trkDensity.Position);
  ApplyPreview;
end;

procedure TWaterRippleDlg.pboxPreviewPaint(Sender: TObject);
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

procedure TWaterRippleDlg.lbPresetsClick(Sender: TObject);
begin
  ApplyPreview;
end;

procedure TWaterRippleDlg.ApplyPreview;
var
  Preset: Integer;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  Preset := Max(0, lbPresets.ItemIndex);
  if Assigned(FEffectProc) then
    FEffectProc(FWorkingPreview, Preset, trkStrength.Position / 100.0, trkDensity.Position / 100.0);
  pboxPreview.Invalidate;
end;

procedure TWaterRippleDlg.ApplyFull;
var
  Preset: Integer;
begin
  Preset := Max(0, lbPresets.ItemIndex);
  if Assigned(FEffectProc) then
    FEffectProc(FSourceBmp, Preset, trkStrength.Position / 100.0, trkDensity.Position / 100.0);
end;

end.
