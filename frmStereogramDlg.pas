unit frmStereogramDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uTitleBar, uI18n;

type
  TStereogramDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    rgMode: TRadioGroup;
    lblPeriod: TLabel;
    lblPeriodVal: TLabel;
    tbPeriod: TTrackBar;
    lblDepth: TLabel;
    lblDepthVal: TLabel;
    tbDepth: TTrackBar;
    chkRandomSeed: TCheckBox;
    edSeed: TEdit;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure rgModeClick(Sender: TObject);
    procedure tbPeriodChange(Sender: TObject);
    procedure tbDepthChange(Sender: TObject);
    procedure chkRandomSeedClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    procedure LayoutDialog(pw, ph: Integer);
    procedure ApplyPreview;
    procedure ApplyFull;
    procedure UpdateSliderState;
  end;

function ShowStereogramDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

uses
  uStereogram, uMacros;

{$R *.dfm}

function ShowStereogramDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TStereogramDlg;
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
    Dlg := TStereogramDlg.Create(Application);
    Dlg.FSourceBmp := Bitmap;

    Scale := Min(380.0 / Bitmap.Width, 380.0 / Bitmap.Height);
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

    Dlg.LayoutDialog(pw, ph);
    Dlg.UpdateSliderState;
    Dlg.ApplyPreview;
    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      gMacroPending.Code := 'STEREOGRAM';
      gMacroPending.Params := Format('%d|%d|%d|%d', [
        Dlg.rgMode.ItemIndex, Dlg.tbPeriod.Position,
        Dlg.tbDepth.Position, StrToIntDef(Dlg.edSeed.Text, 0)]);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TStereogramDlg }

procedure TStereogramDlg.FormCreate(Sender: TObject);
begin
  rgMode.Items[0] := T('Autostereogram (SIRDS)');
  rgMode.Items[1] := T('Anaglyph (red-cyan glasses)');
  rgMode.ItemIndex := 0;
  tbPeriod.Min := 40;
  tbPeriod.Max := 100;
  tbPeriod.Position := 64;
  lblPeriodVal.Caption := '64';
  tbDepth.Min := 0;
  tbDepth.Max := 30;
  tbDepth.Position := 12;
  lblDepthVal.Caption := '12';
  edSeed.Text := '0';
end;

procedure TStereogramDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TStereogramDlg.LayoutDialog(pw, ph: Integer);
// Jawny layout runtime — wołany po Create, bo TFotoForm.AfterConstruction
// (ReflowTrackBarRows w uTitleBar) centruje TPaintBox poziomo i psiuje
// układ boczny. Wzorzec: frmTshirtDlg.LayoutDialog.
var
  Scale: Double;
  PrevW, PrevH, ColW, ColH, ColLeft, ColTop, RowTop, ButtonTop, Margin: Integer;
  MaxW, W, I, RadioPadding: Integer;
  S: string;
begin
  if (pw <= 0) or (ph <= 0) then Exit;

  Scale := Min(380.0 / pw, 380.0 / ph);
  if Scale > 1.0 then Scale := 1.0;
  PrevW := Max(1, Round(pw * Scale));
  PrevH := Max(1, Round(ph * Scale));

  Margin := CtrlGap * 3;
  ColLeft := Margin;

  // Szerokość kolumny z zawartości (wzorzec TRisoDlg.FormCreate) —
  // najszerszy przetłumaczony item radia + zapas na kółko radio,
  // nie mniejsza niż szerokości bazowe kontrolek.
  RadioPadding := 30;
  Self.Canvas.Font.Assign(rgMode.Font);
  MaxW := 0;
  for I := 0 to rgMode.Items.Count - 1 do
  begin
    S := rgMode.Items[I];
    W := Self.Canvas.TextWidth(S);
    if W > MaxW then MaxW := W;
  end;
  ColW := MaxW + RadioPadding;
  if ColW < tbPeriod.Width then ColW := tbPeriod.Width;
  if ColW < tbDepth.Width then ColW := tbDepth.Width;
  if ColW < lblPeriod.Width then ColW := lblPeriod.Width;
  if ColW < lblDepth.Width then ColW := lblDepth.Width;
  if ColW < chkRandomSeed.Width then ColW := chkRandomSeed.Width;
  rgMode.Width := ColW;
  tbPeriod.Width := ColW;
  tbDepth.Width := ColW;

  ColTop := Margin;
  rgMode.Left := ColLeft;
  rgMode.Top := ColTop;

  RowTop := StackBelow(rgMode, SectionGap);

  lblPeriod.Left := ColLeft;
  lblPeriod.Top := RowTop;
  lblPeriodVal.Left := ColLeft + (ColW - lblPeriodVal.Width) div 2;
  lblPeriodVal.Top := RowTop;
  tbPeriod.Left := ColLeft;
  tbPeriod.Top := StackBelow(lblPeriod, RowGap);
  tbPeriod.Width := ColW;
  RowTop := StackBelow(tbPeriod, SectionGap);

  lblDepth.Left := ColLeft;
  lblDepth.Top := RowTop;
  lblDepthVal.Left := ColLeft + (ColW - lblDepthVal.Width) div 2;
  lblDepthVal.Top := RowTop;
  tbDepth.Left := ColLeft;
  tbDepth.Top := StackBelow(lblDepth, RowGap);
  tbDepth.Width := ColW;
  RowTop := StackBelow(tbDepth, SectionGap);

  chkRandomSeed.Left := ColLeft;
  chkRandomSeed.Top := RowTop;
  edSeed.Left := ColLeft + ColW - edSeed.Width;
  edSeed.Top := chkRandomSeed.Top + (chkRandomSeed.Height - edSeed.Height) div 2;
  RowTop := StackBelow(chkRandomSeed, SectionGap);

  ColH := RowTop - ColTop;

  pboxPreview.Width := PrevW;
  pboxPreview.Height := PrevH;
  pboxPreview.Left := ColLeft + ColW + CtrlGap * 3;
  pboxPreview.Top := ColTop + ((ColH - PrevH) div 2);
  if pboxPreview.Top < ColTop then pboxPreview.Top := ColTop;

  ButtonTop := Max(ColTop + ColH + SectionGap, pboxPreview.Top + PrevH + SectionGap);
  btnOK.Top := ButtonTop;
  btnCancel.Top := ButtonTop;
  FitToContent(CtrlGap * 3, CtrlGap * 3);
  AlignButtonsRight([btnOK, btnCancel], CtrlGap * 3);
  FitHeight(CtrlGap * 3);
end;

procedure TStereogramDlg.UpdateSliderState;
var
  IsSIRDS: Boolean;
begin
  IsSIRDS := rgMode.ItemIndex = 0;
  tbPeriod.Enabled := IsSIRDS;
  lblPeriod.Enabled := IsSIRDS;
  lblPeriodVal.Enabled := IsSIRDS;
end;

procedure TStereogramDlg.rgModeClick(Sender: TObject);
begin
  UpdateSliderState;
  ApplyPreview;
end;

procedure TStereogramDlg.tbPeriodChange(Sender: TObject);
begin
  lblPeriodVal.Caption := IntToStr(tbPeriod.Position);
  lblPeriodVal.Left := tbPeriod.Left + (tbPeriod.Width - lblPeriodVal.Width) div 2;
  ApplyPreview;
end;

procedure TStereogramDlg.tbDepthChange(Sender: TObject);
begin
  lblDepthVal.Caption := IntToStr(tbDepth.Position);
  lblDepthVal.Left := tbDepth.Left + (tbDepth.Width - lblDepthVal.Width) div 2;
  ApplyPreview;
end;

procedure TStereogramDlg.chkRandomSeedClick(Sender: TObject);
begin
  edSeed.Enabled := not chkRandomSeed.Checked;
end;

procedure TStereogramDlg.ApplyPreview;
var
  Seed: Integer;
begin
  if (FWorkingPreview = nil) or (FOriginalPreview = nil) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  if chkRandomSeed.Checked then
    Seed := -1
  else
    Seed := StrToIntDef(edSeed.Text, 0);
  DoStereogram(FWorkingPreview, rgMode.ItemIndex, tbPeriod.Position,
    tbDepth.Position, Seed);
  pboxPreview.Invalidate;
end;

procedure TStereogramDlg.ApplyFull;
var
  Seed: Integer;
begin
  if chkRandomSeed.Checked then
    Seed := -1
  else
    Seed := StrToIntDef(edSeed.Text, 0);
  DoStereogram(FSourceBmp, rgMode.ItemIndex, tbPeriod.Position,
    tbDepth.Position, Seed);
end;

procedure TStereogramDlg.pboxPreviewPaint(Sender: TObject);
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
