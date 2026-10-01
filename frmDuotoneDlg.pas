unit frmDuotoneDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, uPreviewFit, uI18n, uPrefs, uTitleBar;

type
  TDuotoneMode = (dmDuotone, dmTritone, dmQuadTone);

  TDuotoneDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    sw1: TShape;
    btnColor1: TButton;
    sw2: TShape;
    btnColor2: TButton;
    sw3: TShape;
    btnColor3: TButton;
    sw4: TShape;
    btnColor4: TButton;
    btnOK: TButton;
    btnCancel: TButton;
    btnSavePreset: TButton;
    btnLoadPreset: TButton;
    procedure btnSavePresetClick(Sender: TObject);
    procedure btnLoadPresetClick(Sender: TObject);
    procedure pboxPreviewPaint(Sender: TObject);
    procedure btnColor1Click(Sender: TObject);
    procedure btnColor2Click(Sender: TObject);
    procedure btnColor3Click(Sender: TObject);
    procedure btnColor4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FMode: TDuotoneMode;
    FColors: array[0..3] of TColor;
    FPresetList: TListBox;
    FLastColorFitKey: string;
    procedure ApplyPreview;
    procedure ApplyFull;
    procedure UpdateColorButtons;
    procedure UpdateSwatch(Idx: Integer);
    procedure FitColorButtons;
    procedure PresetDeleteClick(Sender: TObject);
  public
    property Mode: TDuotoneMode read FMode write FMode;
  end;

function ShowDuotoneDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
function ShowTritoneDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
function ShowQuadToneDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

{$R *.dfm}

uses
  uDuotone;

function DoShowDuotoneDlg(Bitmap: TBitmap; AMode: TDuotoneMode; out ElapsedSec: Double): Boolean;
var
  Dlg: TDuotoneDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
  Defaults: TArray<TColor>;
  I, NColors: Integer;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := nil;
  try
    Dlg := TDuotoneDlg.Create(Application);
    Dlg.FSourceBmp := Bitmap;
    Dlg.FMode := AMode;

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

    NColors := 0;
    case AMode of
      dmDuotone: NColors := 2;
      dmTritone: NColors := 3;
      dmQuadTone: NColors := 4;
    end;
    Defaults := PhotoDefaultColors(Dlg.FOriginalPreview, NColors);
    for I := 0 to Min(Length(Defaults), NColors) - 1 do
    begin
      Dlg.FColors[I] := Defaults[I];
      Dlg.UpdateSwatch(I);
    end;

    Dlg.UpdateColorButtons;
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

function ShowDuotoneDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
begin
  Result := DoShowDuotoneDlg(Bitmap, dmDuotone, ElapsedSec);
end;

function ShowTritoneDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
begin
  Result := DoShowDuotoneDlg(Bitmap, dmTritone, ElapsedSec);
end;

function ShowQuadToneDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
begin
  Result := DoShowDuotoneDlg(Bitmap, dmQuadTone, ElapsedSec);
end;

{ TDuotoneDlg }

procedure TDuotoneDlg.FormCreate(Sender: TObject);
begin
  FColors[0] := RGB(0, 0, 0);
  FColors[1] := RGB(255, 255, 255);
  FColors[2] := RGB(128, 128, 128);
  FColors[3] := RGB(255, 255, 255);
  UpdateSwatch(0);
  UpdateSwatch(1);
  UpdateSwatch(2);
  UpdateSwatch(3);
end;

procedure TDuotoneDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TDuotoneDlg.UpdateSwatch(Idx: Integer);
begin
  case Idx of
    0: sw1.Brush.Color := FColors[0];
    1: sw2.Brush.Color := FColors[1];
    2: sw3.Brush.Color := FColors[2];
    3: sw4.Brush.Color := FColors[3];
  end;
end;

procedure TDuotoneDlg.UpdateColorButtons;
begin
  btnColor1.Caption := T('Color 1 (shadows):');
  btnColor2.Caption := T('Color 2 (highlights):');
  btnSavePreset.Caption := T('Save Duotone preset');
  btnLoadPreset.Caption := T('Load Duotone preset');

  case FMode of
    dmDuotone:
      begin
        btnColor1.Visible := True;  sw1.Visible := True;
        btnColor2.Visible := True;  sw2.Visible := True;
        btnColor3.Visible := False; sw3.Visible := False;
        btnColor4.Visible := False; sw4.Visible := False;
        Caption := T('Duotone');
      end;
    dmTritone:
      begin
        btnColor1.Visible := True;  sw1.Visible := True;
        btnColor2.Visible := True;  sw2.Visible := True;
        btnColor3.Visible := True;  sw3.Visible := True;
        btnColor4.Visible := False; sw4.Visible := False;
        btnColor2.Caption := T('Color 2 (midtones):');
        btnColor3.Caption := T('Color 3 (highlights):');
        Caption := T('Tritone');
      end;
    dmQuadTone:
      begin
        btnColor1.Visible := True;  sw1.Visible := True;
        btnColor2.Visible := True;  sw2.Visible := True;
        btnColor3.Visible := True;  sw3.Visible := True;
        btnColor4.Visible := True;  sw4.Visible := True;
        btnColor2.Caption := T('Color 2 (midtones):');
        btnColor3.Caption := T('Color 3 (highlights):');
        btnColor4.Caption := T('Color 4 (extreme highlights):');
        Caption := T('Quad-tone');
      end;
  end;
  FitColorButtons;
end;

procedure TDuotoneDlg.FitColorButtons;
// Dopasowuje szerokosc przyciskow kolorow, a takze Save/Load preset,
// do ich wlasnego captionu (Canvas.TextWidth + 24). Przyciski w prawej
// kolumnie (btnColor2, btnColor4) dosuwane sa w prawo, by nie nachodzic
// na lewego sasiada. Klucz-cache z captionow unika przeliczania bez zmiany.
var
  Bmp: TBitmap;
  Key: string;
  Left2, Left4: Integer;
begin
  Key := btnColor1.Caption + #1 + btnColor2.Caption + #1 + btnColor3.Caption + #1 + btnColor4.Caption
       + #1 + btnSavePreset.Caption + #1 + btnLoadPreset.Caption;
  if Key = FLastColorFitKey then Exit;
  FLastColorFitKey := Key;

  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font := btnColor1.Font;

    btnColor1.Width := Bmp.Canvas.TextWidth(btnColor1.Caption) + 24;
    btnColor2.Width := Bmp.Canvas.TextWidth(btnColor2.Caption) + 24;
    btnColor3.Width := Bmp.Canvas.TextWidth(btnColor3.Caption) + 24;
    btnColor4.Width := Bmp.Canvas.TextWidth(btnColor4.Caption) + 24;

    // nie przekraczaj szerokosci okna, zostawiajac margines 10px
    btnColor1.Width := Min(btnColor1.Width, ClientWidth - btnColor1.Left - 10);
    btnColor2.Width := Min(btnColor2.Width, ClientWidth - btnColor2.Left - 10);
    btnColor3.Width := Min(btnColor3.Width, ClientWidth - btnColor3.Left - 10);
    btnColor4.Width := Min(btnColor4.Width, ClientWidth - btnColor4.Left - 10);

    // dosun przycisk prawej kolumny, by nie nachodzil na lewego sasiada (przerwa min 4px)
    Left2 := btnColor1.Left + btnColor1.Width + 4;
    if Left2 > btnColor2.Left then btnColor2.Left := Left2;
    Left4 := btnColor3.Left + btnColor3.Width + 4;
    if Left4 > btnColor4.Left then btnColor4.Left := Left4;

    // Save/Load preset — wspolna szerokosc = najszerszy caption z obu,
    // clamp do szerokosci okna, wysrodkowane w poziomie
    btnSavePreset.Width := Max(Bmp.Canvas.TextWidth(btnSavePreset.Caption),
                               Bmp.Canvas.TextWidth(btnLoadPreset.Caption)) + 24;
    btnSavePreset.Width := Min(btnSavePreset.Width, ClientWidth - 20);
    btnSavePreset.Left := (ClientWidth - btnSavePreset.Width) div 2;
    btnLoadPreset.Width := btnSavePreset.Width;
    btnLoadPreset.Left := btnSavePreset.Left;
  finally
    Bmp.Free;
  end;
end;

procedure TDuotoneDlg.btnColor1Click(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FColors[0];
    if Dlg.Execute then
    begin FColors[0] := Dlg.Color; UpdateSwatch(0); ApplyPreview; end;
  finally
    Dlg.Free;
  end;
end;

procedure TDuotoneDlg.btnColor2Click(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FColors[1];
    if Dlg.Execute then
    begin FColors[1] := Dlg.Color; UpdateSwatch(1); ApplyPreview; end;
  finally
    Dlg.Free;
  end;
end;

procedure TDuotoneDlg.btnColor3Click(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FColors[2];
    if Dlg.Execute then
    begin FColors[2] := Dlg.Color; UpdateSwatch(2); ApplyPreview; end;
  finally
    Dlg.Free;
  end;
end;

procedure TDuotoneDlg.btnColor4Click(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FColors[3];
    if Dlg.Execute then
    begin FColors[3] := Dlg.Color; UpdateSwatch(3); ApplyPreview; end;
  finally
    Dlg.Free;
  end;
end;

procedure TDuotoneDlg.ApplyPreview;
begin
  FWorkingPreview.Assign(FOriginalPreview);
  case FMode of
    dmDuotone:  DoDuotone(FWorkingPreview, FColors[0], FColors[1]);
    dmTritone:  DoTritone(FWorkingPreview, FColors[0], FColors[1], FColors[2]);
    dmQuadTone: DoQuadTone(FWorkingPreview, FColors[0], FColors[1], FColors[2], FColors[3]);
  end;
  pboxPreview.Invalidate;
end;

procedure TDuotoneDlg.ApplyFull;
begin
  case FMode of
    dmDuotone:  DoDuotone(FSourceBmp, FColors[0], FColors[1]);
    dmTritone:  DoTritone(FSourceBmp, FColors[0], FColors[1], FColors[2]);
    dmQuadTone: DoQuadTone(FSourceBmp, FColors[0], FColors[1], FColors[2], FColors[3]);
  end;
end;

procedure TDuotoneDlg.btnSavePresetClick(Sender: TObject);
var
  Name: string;
  P: TDuotonePreset;
  N: Integer;
begin
  Name := T('Setting') + ' ' + IntToStr(Length(Prefs.DuotonePresets) + 1);
  if not InputQuery(T('Save Duotone preset'), T('Preset name:'), Name) then
    Exit;
  if Trim(Name) = '' then
    Exit;
  P.Name := Trim(Name);
  P.Colors[0] := FColors[0];
  P.Colors[1] := FColors[1];
  P.Colors[2] := FColors[2];
  P.Colors[3] := FColors[3];
  N := Length(Prefs.DuotonePresets);
  SetLength(Prefs.DuotonePresets, N + 1);
  Prefs.DuotonePresets[N] := P;
  SavePrefs;
end;

procedure TDuotoneDlg.btnLoadPresetClick(Sender: TObject);
var
  F: TForm;
  BtnLoad, BtnDelete, BtnClose: TButton;
  I, Idx: Integer;
begin
  if Length(Prefs.DuotonePresets) = 0 then
    Exit;
  F := TForm.Create(nil);
  try
    F.BorderStyle := bsDialog;
    F.Position := poOwnerFormCenter;
    F.Caption := T('Load Duotone preset');
    F.ClientWidth := 320;
    F.ClientHeight := 220;

    FPresetList := TListBox.Create(F);
    FPresetList.Parent := F;
    FPresetList.Left := 8;
    FPresetList.Top := 8;
    FPresetList.Width := 304;
    FPresetList.Height := 160;
    for I := 0 to Length(Prefs.DuotonePresets) - 1 do
      FPresetList.Items.Add(Prefs.DuotonePresets[I].Name);
    if FPresetList.Items.Count > 0 then
      FPresetList.ItemIndex := 0;

    BtnLoad := TButton.Create(F);
    BtnLoad.Parent := F;
    BtnLoad.Left := 8;
    BtnLoad.Top := 178;
    BtnLoad.Width := 90;
    BtnLoad.Height := 25;
    BtnLoad.Caption := T('Load');
    BtnLoad.Default := True;
    BtnLoad.ModalResult := mrOk;

    BtnDelete := TButton.Create(F);
    BtnDelete.Parent := F;
    BtnDelete.Left := 104;
    BtnDelete.Top := 178;
    BtnDelete.Width := 90;
    BtnDelete.Height := 25;
    BtnDelete.Caption := T('Delete');
    BtnDelete.OnClick := PresetDeleteClick;

    BtnClose := TButton.Create(F);
    BtnClose.Parent := F;
    BtnClose.Left := 222;
    BtnClose.Top := 178;
    BtnClose.Width := 90;
    BtnClose.Height := 25;
    BtnClose.Caption := T('Close');
    BtnClose.Cancel := True;
    BtnClose.ModalResult := mrCancel;

    if F.ShowModal = mrOk then
    begin
      Idx := FPresetList.ItemIndex;
      if Idx >= 0 then
      begin
        FColors[0] := Prefs.DuotonePresets[Idx].Colors[0];
        FColors[1] := Prefs.DuotonePresets[Idx].Colors[1];
        FColors[2] := Prefs.DuotonePresets[Idx].Colors[2];
        FColors[3] := Prefs.DuotonePresets[Idx].Colors[3];
        UpdateSwatch(0);
        UpdateSwatch(1);
        UpdateSwatch(2);
        UpdateSwatch(3);
        ApplyPreview;
      end;
    end;
  finally
    FPresetList := nil;
    F.Free;
  end;
end;

procedure TDuotoneDlg.PresetDeleteClick(Sender: TObject);
var
  I, Idx: Integer;
begin
  Idx := FPresetList.ItemIndex;
  if Idx < 0 then
    Exit;
  for I := Idx to Length(Prefs.DuotonePresets) - 2 do
    Prefs.DuotonePresets[I] := Prefs.DuotonePresets[I + 1];
  SetLength(Prefs.DuotonePresets, Length(Prefs.DuotonePresets) - 1);
  SavePrefs;
  FPresetList.Items.Delete(Idx);
  if FPresetList.Items.Count = 0 then
    TForm(TButton(Sender).Owner).ModalResult := mrCancel;
end;


procedure TDuotoneDlg.pboxPreviewPaint(Sender: TObject);
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
