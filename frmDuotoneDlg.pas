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
    procedure RefitButtons; override;
  end;

function ShowDuotoneDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
function ShowTritoneDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
function ShowQuadToneDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

{$R *.dfm}

uses
  uDuotone, uMacros;

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
  gMacroPending.Code := '';
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
      // kolory jako TColor (liczby), od cieni do swiatel
      case AMode of
        dmDuotone:
        begin
          gMacroPending.Code := 'DUOTONE';
          gMacroPending.Params := IntToStr(Integer(Dlg.FColors[0])) + '|' +
            IntToStr(Integer(Dlg.FColors[1]));
        end;
        dmTritone:
        begin
          gMacroPending.Code := 'TRITONE';
          gMacroPending.Params := IntToStr(Integer(Dlg.FColors[0])) + '|' +
            IntToStr(Integer(Dlg.FColors[1])) + '|' + IntToStr(Integer(Dlg.FColors[2]));
        end;
        dmQuadTone:
        begin
          gMacroPending.Code := 'QUADTONE';
          gMacroPending.Params := IntToStr(Integer(Dlg.FColors[0])) + '|' +
            IntToStr(Integer(Dlg.FColors[1])) + '|' + IntToStr(Integer(Dlg.FColors[2])) + '|' +
            IntToStr(Integer(Dlg.FColors[3]));
        end;
      end;
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
  btnColor1.Caption := T('Color 1 (shadows)');
  btnColor2.Caption := T('Color 2 (highlights)');
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
        btnColor2.Caption := T('Color 2 (midtones)');
        btnColor3.Caption := T('Color 3 (highlights)');
        Caption := T('Tritone');
      end;
    dmQuadTone:
      begin
        btnColor1.Visible := True;  sw1.Visible := True;
        btnColor2.Visible := True;  sw2.Visible := True;
        btnColor3.Visible := True;  sw3.Visible := True;
        btnColor4.Visible := True;  sw4.Visible := True;
        btnColor2.Caption := T('Color 2 (midtones)');
        btnColor3.Caption := T('Color 3 (highlights)');
        btnColor4.Caption := T('Color 4 (extreme highlights)');
        Caption := T('Quad-tone');
      end;
  end;
  FitColorButtons;
end;

procedure TDuotoneDlg.FitColorButtons;
// Dwie kolumny par plakietka + przycisk koloru (2026-10-22; wczesniej
// przyciski obcinane do stalej szerokosci okna, a plakietki sw2/sw4 staly
// na Left z .dfm i zaslanial je przycisk lewej kolumny). Szerokosc przycisku
// z napisu (FitButton, min. 130 jak Constraints w .dfm), w kolumnie wspolna;
// plakietka zawsze tuz przed swoim przyciskiem. Gdy kolumny sie nie mieszcza,
// okno jest szersze (nie wyzsze - wysokosc ogranicza ekran); podglad
// wysrodkowuje potem FitPreviewToDialog. Klucz-cache z captionow unika
// przeliczania bez zmiany.
var
  Key: string;
  Margin, Gap, ColGap, Col1W, Col2W, X: Integer;

  procedure PlacePair(Sw: TShape; B: TButton; ALeft, AWidth: Integer);
  begin
    Sw.Left := ALeft;
    B.Left := ALeft + Sw.Width + Gap;
    B.Width := AWidth;
  end;

begin
  Key := btnColor1.Caption + #1 + btnColor2.Caption + #1 + btnColor3.Caption + #1 + btnColor4.Caption
       + #1 + btnSavePreset.Caption + #1 + btnLoadPreset.Caption;
  if Key = FLastColorFitKey then Exit;
  FLastColorFitKey := Key;

  Margin := sw1.Left;          // lewy margines z .dfm (jak podglad)
  Gap := CtrlGap;
  ColGap := CtrlGap * 4;

  FitButton(btnColor1, 130);
  FitButton(btnColor2, 130);
  FitButton(btnColor3, 130);
  FitButton(btnColor4, 130);
  Col1W := btnColor1.Width;
  if btnColor3.Visible then Col1W := Max(Col1W, btnColor3.Width);
  Col2W := btnColor2.Width;
  if btnColor4.Visible then Col2W := Max(Col2W, btnColor4.Width);

  PlacePair(sw1, btnColor1, Margin, Col1W);
  PlacePair(sw3, btnColor3, Margin, Col1W);
  X := btnColor1.Left + Col1W + ColGap;
  PlacePair(sw2, btnColor2, X, Col2W);
  PlacePair(sw4, btnColor4, X, Col2W);

  if btnColor2.Left + Col2W + Margin > ClientWidth then
    ClientWidth := btnColor2.Left + Col2W + Margin;

  // Save/Load preset — wspolna szerokosc z napisow, wysrodkowane w poziomie
  FitButtonGroup([btnSavePreset, btnLoadPreset]);
  btnSavePreset.Left := (ClientWidth - btnSavePreset.Width) div 2;
  btnLoadPreset.Left := btnSavePreset.Left;
end;

// Po tlumaczeniu okna i zmianie czcionki (szerokosci OK/Anuluj sa wtedy juz
// ostateczne, inherited je poszerza): kolumny kolorow od nowa, podglad na
// srodku okna, OK/Anuluj do prawej z tym samym marginesem co wiersze kolorow.
// Wczesniej wyrownanie bylo w FitColorButtons, przed tlumaczeniem - DE
// „Abbrechen” poszerzal potem Anuluj w prawo (ok. 5 px od krawedzi), a
// podglad byl liczony z nieprzeliczonej szerokosci panelu tresci.
procedure TDuotoneDlg.RefitButtons;
var
  Y: Integer;

  // napis przycisku koloru do lewej, przy plakietce - styl VCL rysuje tekst
  // wg BS_LEFT/BS_RIGHT/BS_CENTER (TButtonStyleHook.DrawButton,
  // Vcl.StdCtrls.pas:11541-11546); TButton nie ma wlasciwosci wyrownania
  procedure LeftText(B: TButton);
  begin
    if not B.HandleAllocated then Exit;
    SetWindowLong(B.Handle, GWL_STYLE,
      (GetWindowLong(B.Handle, GWL_STYLE) and not BS_CENTER) or BS_LEFT);
    B.Invalidate;
  end;

  // wiersz par plakietka + przycisk od Y; plakietka wysrodkowana pionowo
  procedure PlaceRow(SwL, SwR: TShape; BL, BR: TButton);
  begin
    BL.Top := Y;
    BR.Top := Y;
    SwL.Top := Y + (BL.Height - SwL.Height) div 2;
    SwR.Top := SwL.Top;
    Y := Y + BL.Height;
  end;

begin
  inherited;
  FLastColorFitKey := '';
  FitColorButtons;
  pboxPreview.Left := (ClientWidth - pboxPreview.Width) div 2;
  LeftText(btnColor1);
  LeftText(btnColor2);
  LeftText(btnColor3);
  LeftText(btnColor4);

  // pionowo (wczesniej pozycje z .dfm, odstep nad OK/Anuluj taki sam jak
  // wewnatrz grup): grupy oddzielone SectionGap, wiersze w grupie RowGap
  Y := pboxPreview.Top + pboxPreview.Height + SectionGap;
  PlaceRow(sw1, sw2, btnColor1, btnColor2);
  if btnColor3.Visible then
  begin
    Inc(Y, RowGap);
    PlaceRow(sw3, sw4, btnColor3, btnColor4);
  end;
  Inc(Y, SectionGap);
  btnSavePreset.Top := Y;
  btnLoadPreset.Top := btnSavePreset.Top + btnSavePreset.Height + RowGap;
  btnOK.Top := btnLoadPreset.Top + btnLoadPreset.Height + SectionGap;
  btnCancel.Top := btnOK.Top;
  AlignButtonsRight([btnOK, btnCancel], sw1.Left);
  FitHeight(sw1.Left);
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
  I, Idx, TH, Margin, Gap, BtnW, BtnH: Integer;
begin
  if Length(Prefs.DuotonePresets) = 0 then
    Exit;
  F := TForm.Create(nil);
  try
    // Uklad z zawartosci (2026-10-21; wczesniej sztywne 320x220, lista 304x160,
    // przyciski po 90 px, czcionka systemowa): czcionka programu (ParentFont),
    // lista ok. 10 wierszy i szerokosc z najdluzszej nazwy (min. 30 znakow),
    // [Wczytaj] [Usun] z lewej, [Zamknij] z prawej; odstepy z wysokosci tekstu.
    // czcionka programu: samo ParentFont := True nic nie daje formie bez
    // rodzica (Vcl.Controls.pas:6979-6980), stad Font.Assign
    F.Font.Assign(Application.DefaultFont);
    F.ParentFont := True;
    F.BorderStyle := bsDialog;
    F.Position := poOwnerFormCenter;
    F.Caption := T('Load Duotone preset');
    F.Canvas.Font.Assign(F.Font);
    TH := F.Canvas.TextHeight('Wg');
    Margin := TH * 2 div 3;
    Gap := TH div 3;

    FPresetList := TListBox.Create(F);
    FPresetList.Parent := F;
    for I := 0 to Length(Prefs.DuotonePresets) - 1 do
      FPresetList.Items.Add(Prefs.DuotonePresets[I].Name);
    if FPresetList.Items.Count > 0 then
      FPresetList.ItemIndex := 0;

    BtnLoad := TButton.Create(F);
    BtnLoad.Parent := F;
    BtnLoad.Caption := T('Load');
    BtnLoad.Default := True;
    BtnLoad.ModalResult := mrOk;

    BtnDelete := TButton.Create(F);
    BtnDelete.Parent := F;
    BtnDelete.Caption := T('Delete');
    BtnDelete.OnClick := PresetDeleteClick;

    BtnClose := TButton.Create(F);
    BtnClose.Parent := F;
    BtnClose.Caption := T('Close');
    BtnClose.Cancel := True;
    BtnClose.ModalResult := mrCancel;

    // przyciski: wspolna szerokosc jak FitButtonGroup (tekst + 2 x 'W', min. 85),
    // wysokosc domyslna przycisku - jak we wszystkich oknach
    BtnW := 85;
    BtnW := Max(BtnW, F.Canvas.TextWidth(BtnLoad.Caption) + 2 * F.Canvas.TextWidth('W'));
    BtnW := Max(BtnW, F.Canvas.TextWidth(BtnDelete.Caption) + 2 * F.Canvas.TextWidth('W'));
    BtnW := Max(BtnW, F.Canvas.TextWidth(BtnClose.Caption) + 2 * F.Canvas.TextWidth('W'));
    BtnH := BtnLoad.Height;

    // lista: szerokosc z najdluzszej nazwy (min. 30 znakow, co najmniej na
    // trzy przyciski), ok. 10 wierszy
    I := F.Canvas.TextWidth('0') * 30;
    for Idx := 0 to FPresetList.Items.Count - 1 do
      I := Max(I, F.Canvas.TextWidth(FPresetList.Items[Idx]) + GetSystemMetrics(SM_CXVSCROLL) + Gap * 2);
    I := Max(I, BtnW * 3 + Margin * 2);
    FPresetList.SetBounds(Margin, Margin, I, TH);
    FPresetList.ClientHeight := TH * 10;

    BtnLoad.SetBounds(Margin, FPresetList.Top + FPresetList.Height + Margin, BtnW, BtnH);
    BtnDelete.SetBounds(BtnLoad.Left + BtnW + Gap * 2, BtnLoad.Top, BtnW, BtnH);
    BtnClose.SetBounds(FPresetList.Left + FPresetList.Width - BtnW, BtnLoad.Top, BtnW, BtnH);
    F.ClientWidth := FPresetList.Left + FPresetList.Width + Margin;
    F.ClientHeight := BtnLoad.Top + BtnH + Margin;

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
