unit frmDistortDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uDistort, uPreviewFit, uI18n, uTitleBar;

type
  TDistortProc = procedure(Bmp: TBitmap; Preset: Integer);

  TDistortDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    lbPresets: TListBox;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure lbPresetsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FEffectProc: TDistortProc;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowDistortDlg(const Title: string; const Items: array of string; EffectProc: TDistortProc; Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

function ShowDistortDlg(const Title: string; const Items: array of string; EffectProc: TDistortProc; Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TDistortDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
  I: Integer;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TDistortDlg.CreateNew(Application);
  Dlg.FormCreate(Dlg);
  try
    Dlg.Caption := Title;
    Dlg.FSourceBmp := Bitmap;
    Dlg.FEffectProc := EffectProc;

    Dlg.lbPresets.Clear;
    for I := Low(Items) to High(Items) do
      Dlg.lbPresets.Items.Add(Items[I]);
    if Dlg.lbPresets.Items.Count > 0 then
      Dlg.lbPresets.ItemIndex := 0;

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

    Dlg.lbPresets.ItemHeight := Dlg.lbPresets.Canvas.TextHeight('Wg') + 2;
    Dlg.lbPresets.Height := Dlg.lbPresets.Items.Count * Dlg.lbPresets.ItemHeight + 8;
    Dlg.FitToContent;

    Dlg.btnOK.Top := Dlg.lbPresets.Top + Dlg.lbPresets.Height + Dlg.CtrlGap * 3;
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

{ TDistortDlg }

procedure TDistortDlg.FormCreate(Sender: TObject);
begin
  Font.Assign(Application.DefaultFont);
  BorderStyle := bsDialog;
  Position := poOwnerFormCenter;

  pboxPreview := TPaintBox.Create(Self);
  pboxPreview.Parent := Self;
  pboxPreview.Left := 15;
  pboxPreview.Top := 15;
  pboxPreview.Width := 400;
  pboxPreview.Height := 300;
  pboxPreview.OnPaint := pboxPreviewPaint;

  lbPresets := TListBox.Create(Self);
  lbPresets.Parent := Self;
  lbPresets.Left := 15;
  lbPresets.Top := 330;
  lbPresets.Width := 400;
  lbPresets.Height := 110;
  lbPresets.OnClick := lbPresetsClick;

  btnOK := TButton.Create(Self);
  btnOK.Parent := Self;
  btnOK.Left := 240;
  btnOK.Top := 452;
  btnOK.Width := 85;
  btnOK.Height := 25;
  btnOK.Caption := T('OK');
  btnOK.Default := True;
  btnOK.ModalResult := mrOk;

  btnCancel := TButton.Create(Self);
  btnCancel.Parent := Self;
  btnCancel.Left := 331;
  btnCancel.Top := 452;
  btnCancel.Width := 85;
  btnCancel.Height := 25;
  btnCancel.Caption := T('Cancel');
  btnCancel.Cancel := True;
  btnCancel.ModalResult := mrCancel;

  FitToContent;
end;

procedure TDistortDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TDistortDlg.pboxPreviewPaint(Sender: TObject);
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

procedure TDistortDlg.lbPresetsClick(Sender: TObject);
begin
  ApplyPreview;
end;

procedure TDistortDlg.ApplyPreview;
var
  Preset: Integer;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  Preset := Max(0, lbPresets.ItemIndex);
  if Assigned(FEffectProc) then
    FEffectProc(FWorkingPreview, Preset);
  pboxPreview.Invalidate;
end;

procedure TDistortDlg.ApplyFull;
var
  Preset: Integer;
begin
  Preset := Max(0, lbPresets.ItemIndex);
  if Assigned(FEffectProc) then
    FEffectProc(FSourceBmp, Preset);
end;

end.
