unit frmToolsDlg;

interface

uses
  System.SysUtils, System.Classes, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  uTitleBar;

type
  // Panel Retusz: selektor rodziny narzędzia (combo) + para radio zależna od
  // rodziny (gumka: Erase/Restore, jasność: Dodge/Burn, ostrość: Sharpen/Blur)
  // + wspólne suwaki (rozmiar, siła) oraz tolerancja dla wiaderka i różdżki.
  // Stan narzędzi mieszka w frmMain - dialog czyta go przy każdym FormShow i
  // zapisuje przez publiczne akcesory.
  TRetouchFamily = (rfEraser, rfPaint, rfClone, rfBright, rfFocus,
    rfColorReplace, rfBucket, rfSample, rfProtect);

  TToolsDlg = class(TFotoForm)
    cmbTool: TComboBox;
    rbErase: TRadioButton;
    rbRestore: TRadioButton;
    lblBrushSize: TLabel;
    tbrBrush: TTrackBar;
    lblBrushVal: TLabel;
    lblStrength: TLabel;
    tbrStrength: TTrackBar;
    lblStrengthVal: TLabel;
    lblTolerance: TLabel;
    tbrTolerance: TTrackBar;
    lblToleranceVal: TLabel;
    lblColor: TLabel;
    pboxColor: TShape;
    btnColorChoose: TButton;
    lblColor2: TLabel;
    pboxColor2: TShape;
    btnColorChoose2: TButton;
    chkRetainShading: TCheckBox;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure cmbToolChange(Sender: TObject);
    procedure rbModeClick(Sender: TObject);
    procedure tbrBrushChange(Sender: TObject);
    procedure tbrStrengthChange(Sender: TObject);
    procedure tbrToleranceChange(Sender: TObject);
    procedure btnColorChooseClick(Sender: TObject);
    procedure btnColorChoose2Click(Sender: TObject);
    procedure chkRetainShadingClick(Sender: TObject);
  public
    procedure RefitButtons; override;
  private
    FUpdating: Boolean;
    FActiveFam: TRetouchFamily;
    // Zapamiętana siła (suwak) dla każdej rodziny narzędzia - przełączanie
    // combo przywraca wartość tej rodziny zamiast wspólnego globala. Pędzel
    // jasności (dodge/burn) startuje domyślnie z 10 (przy 100 jeden stempel
    // bieli przeciągnięcie), pozostałe rodziny z 100.
    FStrengthInited: Boolean;
    FStrengthByFam: array[TRetouchFamily] of Integer;
    procedure FillTools;
    procedure SyncFamily;
    procedure SyncSwatch;
    procedure LayoutDialog;
    procedure ApplyFamily;
    function FamilyFromState: TRetouchFamily;
  public
    procedure RefreshForeColor;
    procedure RefreshToleranceVisibility;
    // Gdy pasek opcji różdżki (fMain) zmienia tolerancję, dialog Retusz
    // otwarty na wiaderku musi odzwierciedlić tę samą wartość.
    procedure SyncToleranceSlider(AValue: Integer);
  end;

implementation

uses
  fMain, uSelection, uI18n, Vcl.Dialogs;

{$R *.dfm}

function TToolsDlg.FamilyFromState: TRetouchFamily;
begin
  case frmMain.GetActiveToolKind of
    tkEraser:     Result := rfEraser;
    tkBucket:     Result := rfBucket;
    tkEyedropper: Result := rfSample;
    tkProtect:    Result := rfProtect;
    tkBrush:
      case frmMain.GetRetouchBrushMode of
        bmPaint: Result := rfPaint;
        bmClone: Result := rfClone;
        bmDodge, bmBurn:   Result := rfBright;
        bmSharpen, bmBlur: Result := rfFocus;
        bmColorReplace:    Result := rfColorReplace;
      else
        Result := rfPaint;
      end;
  else
    Result := rfEraser;
  end;
end;

procedure TToolsDlg.FillTools;
begin
  // Kolejność Items pokrywa się z porządkiem TRetouchFamily - indeks combo = rodzina.
  cmbTool.Items.Clear;
  cmbTool.Items.Add(T('Eraser'));
  cmbTool.Items.Add(T('Paint brush'));
  cmbTool.Items.Add(T('Clone brush'));
  cmbTool.Items.Add(T('Brightness brush'));
  cmbTool.Items.Add(T('Focus brush'));
  cmbTool.Items.Add(T('Color replacement brush'));
  cmbTool.Items.Add(T('Bucket'));
  cmbTool.Items.Add(T('Eyedropper'));
  cmbTool.Items.Add(T('Protection mask'));
  FActiveFam := FamilyFromState;
  cmbTool.ItemIndex := Ord(FActiveFam);
end;

procedure TToolsDlg.SyncFamily;
var
  Mode: TBrushMode;
begin
  if frmMain = nil then Exit;
  Mode := frmMain.GetRetouchBrushMode;
  case FActiveFam of
    rfEraser:
    begin
      rbErase.Caption := T('Erase');
      rbRestore.Caption := T('Restore');
      rbErase.Checked := frmMain.GetRetouchEraseMode;
      rbRestore.Checked := not frmMain.GetRetouchEraseMode;
    end;
    rfBright:
    begin
      rbErase.Caption := T('Dodge');
      rbRestore.Caption := T('Burn');
      rbErase.Checked := Mode = bmDodge;
      rbRestore.Checked := Mode = bmBurn;
    end;
    rfFocus:
    begin
      rbErase.Caption := T('Sharpen');
      rbRestore.Caption := T('Blur');
      rbErase.Checked := Mode = bmSharpen;
      rbRestore.Checked := Mode = bmBlur;
    end;
    rfProtect:
    begin
      rbErase.Caption := T('Cover');
      rbRestore.Caption := T('Uncover');
      rbErase.Checked := frmMain.GetRetouchProtectMode;
      rbRestore.Checked := not frmMain.GetRetouchProtectMode;
    end;
  else
    rbErase.Caption := '';
    rbRestore.Caption := '';
  end;

  rbErase.Visible := FActiveFam in [rfEraser, rfBright, rfFocus, rfProtect];
  rbRestore.Visible := rbErase.Visible;
  // Rozmiar: wszystkie pędzle + gumka (nie wiaderko, nie próbnik).
  lblBrushSize.Visible := FActiveFam in [rfEraser, rfPaint, rfClone, rfBright,
    rfFocus, rfColorReplace, rfProtect];
  tbrBrush.Visible := lblBrushSize.Visible;
  lblBrushVal.Visible := lblBrushSize.Visible;
  // Siła: tylko tryby pędzla, które z niej korzystają (nie gumka - TEraserTool
  // czyta wyłącznie rozmiar i tryb erase/restore). W malowaniu/klonie/jasności
  // Siła to krycie farby. Dla zamiany koloru (bmColorReplace) Siła skaluje
  // promień malowanego dysku: 0 = nic, 100 = pełny pędzel, a pas kolorów
  // wybiera wyłącznie Tolerancja, więc oba suwaki działają niezależnie.
  // Zachowanie modelunku cieni to osobna opcja (chkRetainShading).
  lblStrength.Visible := FActiveFam in [rfPaint, rfClone, rfBright, rfFocus,
    rfColorReplace];
  tbrStrength.Visible := lblStrength.Visible;
  lblStrengthVal.Visible := lblStrength.Visible;
  // Tolerancja: wiaderko i pędzel zamiany koloru (zakres dopasowania koloru
  // pierwotnego). Różdżka ma własny pasek opcji w fMain.
  lblTolerance.Visible := (FActiveFam in [rfBucket, rfColorReplace]);
  tbrTolerance.Visible := lblTolerance.Visible;
  lblToleranceVal.Visible := lblTolerance.Visible;
  // Kolor do zamiany: tam, gdzie kolor ma znaczenie (malowanie, wiaderko,
  // próbnik jako odczyt, zamiana koloru). Gumka/klon/jasność/ostrość malują
  // bezbarwnie. Przycisk "Wybierz..." tylko tam, gdzie kolor wybieramy z
  // palety - dla zamiany koloru pierwotny pochodzi WYŁĄCZNIE z obrazu
  // (zakraplacz), więc pierwszy wiersz jest tylko podglądem.
  lblColor.Visible := FActiveFam in [rfPaint, rfBucket, rfSample, rfColorReplace];
  pboxColor.Visible := lblColor.Visible;
  btnColorChoose.Visible := lblColor.Visible and (FActiveFam <> rfColorReplace);
  // Kolor nowy: wyłącznie dla zamiany koloru (drugi wiersz - czym zastąpić).
  lblColor2.Visible := (FActiveFam = rfColorReplace);
  pboxColor2.Visible := lblColor2.Visible;
  btnColorChoose2.Visible := lblColor2.Visible;
  // Caption wiersza koloru zależny od rodziny: dla zamiany koloru pierwszy
  // wiersz pokazuje kolor pierwotny (do podmiany), w pozostałych "Fill color".
  if FActiveFam = rfColorReplace then
    lblColor.Caption := T('Color to replace')
  else
    lblColor.Caption := T('Fill color');
  lblColor2.Caption := T('Replacement color');
  // Zachowanie modelunku cieni: tylko zamiana koloru. Odznaczone = pełna
  // podmiana na płaski kolor nowy, zaznaczone = ta sama barwa przeskalowana
  // luminancją oryginału (cienie/światła zostają w nowej barwie).
  chkRetainShading.Visible := (FActiveFam = rfColorReplace);
  if chkRetainShading.Visible then
  begin
    chkRetainShading.Caption := T('Retain shading');
    chkRetainShading.Checked := frmMain.GetReplaceRetainShading;
  end;
end;

procedure TToolsDlg.RefreshForeColor;
begin
  SyncSwatch;
end;

procedure TToolsDlg.SyncToleranceSlider(AValue: Integer);
begin
  // Sync z paska opcji różdżki; guard FUpdating zapobiega pętli
  // (OnChange suwaka -> SetRetouchTolerance -> ponowny wpis tutaj).
  if FUpdating then Exit;
  FUpdating := True;
  try
    tbrTolerance.Position := AValue;
    lblToleranceVal.Caption := IntToStr(AValue);
  finally
    FUpdating := False;
  end;
end;

procedure TToolsDlg.RefreshToleranceVisibility;
begin
  // Przebudowa widoczności suwaka tolerancji bez zmiany rodziny - wołane
  // z frmMain.SetSelectionShape, gdy kształtem zaznaczenia staje się różdżka.
  SyncFamily;
  LayoutDialog;
end;

procedure TToolsDlg.SyncSwatch;
begin
  if frmMain = nil then Exit;
  pboxColor.Brush.Color := frmMain.GetForeColor;
  pboxColor.Invalidate;
  pboxColor2.Brush.Color := frmMain.GetReplaceColor;
  pboxColor2.Invalidate;
end;

procedure TToolsDlg.LayoutDialog;
// Układ liczony z zawartości (wzorzec frmStereogramDlg.LayoutDialog): margines
// i odstępy z helperów fontowych (CtrlGap/RowGap/SectionGap), szerokości radio
// z pomiaru przetłumaczonego captionu. Zero sztywnych pikseli - okno rośnie
// z fontem 8-12pt i długimi tłumaczeniami. Kolejność wierszy zależy od tego,
// która rodzina jest aktywna (radio / suwaki pędzla / tolerancja), a kolumna
// ma stałą szerokość ColW.
var
  ColLeft, ColW, W1, W2, MaxR, RowTop, WVal, I, MaxW: Integer;
begin
  ColLeft := CtrlGap * 3;
  RowTop := ColLeft;

  // Wiersz 1: combo selektora rodziny. Szerokość combo z najdłuższej
  // przetłumaczonej nazwy rodziny (+ strzałka i ramki).
  Self.Canvas.Font.Assign(cmbTool.Font);
  MaxW := 0;
  for I := 0 to cmbTool.Items.Count - 1 do
    MaxW := Max(MaxW, Self.Canvas.TextWidth(cmbTool.Items[I]));
  cmbTool.Left := ColLeft;
  cmbTool.Top := RowTop;
  cmbTool.Width := MaxW + 32;
  RowTop := StackBelow(cmbTool, SectionGap);

  // Wiersz radio: para zależna od rodziny (gumka, jasność, ostrość). Najmniejsza
  // wspólna szerokość z najszerszego tłumaczenia (+ miejsce na kółko).
  MaxR := 0;
  if rbErase.Visible then
  begin
    Self.Canvas.Font.Assign(rbErase.Font);
    W1 := Self.Canvas.TextWidth(rbErase.Caption);
    W2 := Self.Canvas.TextWidth(rbRestore.Caption);
    MaxR := Max(W1, W2) + 30;
    rbErase.Left := ColLeft;
    rbErase.Top := RowTop;
    rbErase.Width := MaxR;
    rbRestore.Left := rbErase.Left + MaxR + CtrlGap * 2;
    rbRestore.Top := RowTop;
    rbRestore.Width := MaxR;
    RowTop := StackBelow(rbErase, SectionGap);
  end;

  // Szerokość kolumny: radio (jeśli widoczne) albo combo.
  if rbErase.Visible then
    ColW := rbRestore.Left + MaxR - ColLeft
  else
    ColW := cmbTool.Left + cmbTool.Width - ColLeft;

  Self.Canvas.Font.Assign(lblBrushVal.Font);
  WVal := Self.Canvas.TextWidth('100');

  // Rozmiar pędzla + siła: opis w osobnym wierszu, wartość OBOK suwaka.
  if lblBrushSize.Visible then
  begin
    lblBrushSize.Left := ColLeft;
    lblBrushSize.Top := RowTop;
    tbrBrush.Top := StackBelow(lblBrushSize, RowGap);
    tbrBrush.Left := ColLeft;
    tbrBrush.Width := ColW - CtrlGap - WVal;
    lblBrushVal.Top := tbrBrush.Top + (tbrBrush.Height - lblBrushVal.Height) div 2;
    lblBrushVal.Left := tbrBrush.Left + tbrBrush.Width + CtrlGap;

    lblStrength.Left := ColLeft;
    lblStrength.Top := StackBelow(tbrBrush, SectionGap);
    tbrStrength.Top := StackBelow(lblStrength, RowGap);
    tbrStrength.Left := ColLeft;
    tbrStrength.Width := ColW - CtrlGap - WVal;
    lblStrengthVal.Top := tbrStrength.Top + (tbrStrength.Height - lblStrengthVal.Height) div 2;
    lblStrengthVal.Left := tbrStrength.Left + tbrStrength.Width + CtrlGap;
    RowTop := StackBelow(tbrStrength, SectionGap);
  end;

  // Suwak tolerancji (wiaderko / różdżka): opis i wartość analogicznie do strength.
  if lblTolerance.Visible then
  begin
    lblTolerance.Left := ColLeft;
    lblTolerance.Top := RowTop;
    tbrTolerance.Top := StackBelow(lblTolerance, RowGap);
    tbrTolerance.Left := ColLeft;
    tbrTolerance.Width := ColW - CtrlGap - WVal;
    lblToleranceVal.Top := tbrTolerance.Top + (tbrTolerance.Height - lblToleranceVal.Height) div 2;
    lblToleranceVal.Left := tbrTolerance.Left + tbrTolerance.Width + CtrlGap;
    RowTop := StackBelow(tbrTolerance, SectionGap);
  end;

  // Kolor rysowania: wiersz zawsze na końcu, pod ostatnim aktywnym blokiem.
  lblColor.Left := ColLeft;
  lblColor.Top := RowTop;
  pboxColor.Left := ColLeft;
  pboxColor.Top := StackBelow(lblColor, RowGap);
  pboxColor.Width := pboxColor.Height;
  btnColorChoose.Left := pboxColor.Left + pboxColor.Width + CtrlGap * 2;
  btnColorChoose.Top := pboxColor.Top + (pboxColor.Height - btnColorChoose.Height) div 2;

  // Kolor nowy (zamiana koloru): drugi wiersz pod pierwszym, widoczny tylko
  // dla rodziny rfColorReplace. Bazujemy na pboxColor (nie na btnColorChoose,
  // który przy rfColorReplace jest ukryty - kolor pierwotny tylko z zakraplacza).
  if lblColor2.Visible then
  begin
    lblColor2.Left := ColLeft;
    lblColor2.Top := StackBelow(pboxColor, SectionGap);
    pboxColor2.Left := ColLeft;
    pboxColor2.Top := StackBelow(lblColor2, RowGap);
    pboxColor2.Width := pboxColor2.Height;
    btnColorChoose2.Left := pboxColor2.Left + pboxColor2.Width + CtrlGap * 2;
    btnColorChoose2.Top := pboxColor2.Top + (pboxColor2.Height - btnColorChoose2.Height) div 2;
  end;

  // Checkbox zachowania cieni (tylko zamiana koloru). Szerokość z pomiaru
  // przetłumaczonego captionu + zapas na kółko, żeby długie tłumaczenia
  // (np. "Schattierungen beibehalten") nie były ucinane.
  if chkRetainShading.Visible then
  begin
    Self.Canvas.Font.Assign(chkRetainShading.Font);
    // VCL rysuje napis TCheckBox za kolumną z kółkiem (~2 wiersze tekstu) -
    // bez jej doliczenia koniec napisu wychodzi poza kontrolkę.
    chkRetainShading.Width := SectionGap * 2 +
      Self.Canvas.TextWidth(chkRetainShading.Caption) + CtrlGap;
    chkRetainShading.Height := Self.Canvas.TextHeight(chkRetainShading.Caption) + RowGap;
    chkRetainShading.Left := ColLeft;
    chkRetainShading.Top := StackBelow(pboxColor2, SectionGap);
  end;

  FitToContent(CtrlGap * 3, CtrlGap * 3);
end;

procedure TToolsDlg.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
  frmMain.ActivateTool(tkSelection);
end;

procedure TToolsDlg.FormShow(Sender: TObject);
var
  Fam: TRetouchFamily;
begin
  if frmMain = nil then Exit;
  Self.Caption := T('Retouch');
  if not FStrengthInited then
  begin
    for Fam := Low(TRetouchFamily) to High(TRetouchFamily) do
      FStrengthByFam[Fam] := 100;
    FStrengthByFam[rfBright] := 10;
    FStrengthInited := True;
  end;
  FUpdating := True;
  try
    FillTools;
    tbrBrush.Position := frmMain.GetRetouchBrushSize;
    lblBrushVal.Caption := IntToStr(tbrBrush.Position);
    tbrStrength.Position := FStrengthByFam[FActiveFam];
    lblStrengthVal.Caption := IntToStr(tbrStrength.Position);
    tbrTolerance.Position := frmMain.GetRetouchTolerance;
    lblToleranceVal.Caption := IntToStr(tbrTolerance.Position);
    SyncSwatch;
  finally
    FUpdating := False;
  end;
  ApplyFamily;
end;

procedure TToolsDlg.cmbToolChange(Sender: TObject);
begin
  if FUpdating then Exit;
  if cmbTool.ItemIndex < 0 then Exit;
  FActiveFam := TRetouchFamily(cmbTool.ItemIndex);
  ApplyFamily;
end;

procedure TToolsDlg.ApplyFamily;
begin
  case FActiveFam of
    rfEraser: frmMain.ActivateTool(tkEraser);
    rfBucket: frmMain.ActivateTool(tkBucket);
    rfSample: frmMain.ActivateTool(tkEyedropper);
    rfProtect: frmMain.ActivateTool(tkProtect);
  else
    // rfPaint, rfClone, rfBright, rfFocus, rfColorReplace -> pędzel; tryb
    // ustawiany jawnie.
    frmMain.ActivateTool(tkBrush);
    case FActiveFam of
      rfPaint: frmMain.SetRetouchBrushMode(bmPaint);
      rfClone: frmMain.SetRetouchBrushMode(bmClone);
      rfBright:
        if not (frmMain.GetRetouchBrushMode in [bmDodge, bmBurn]) then
          frmMain.SetRetouchBrushMode(bmDodge);
      rfFocus:
        if not (frmMain.GetRetouchBrushMode in [bmSharpen, bmBlur]) then
          frmMain.SetRetouchBrushMode(bmSharpen);
      rfColorReplace:
        frmMain.SetRetouchBrushMode(bmColorReplace);
    end;
  end;
  // Przełączenie rodziny przywraca jej zapamiętaną siłę (jasność startuje
  // z domyślnych 10, reszta z 100) i synchronizuje global frmMain.
  tbrStrength.Position := FStrengthByFam[FActiveFam];
  frmMain.SetRetouchStrength(FStrengthByFam[FActiveFam]);
  SyncFamily;
  LayoutDialog;
end;

procedure TToolsDlg.rbModeClick(Sender: TObject);
begin
  if FUpdating then Exit;
  case FActiveFam of
    rfEraser:
      frmMain.SetRetouchEraseMode(rbErase.Checked);
    rfBright:
      if rbErase.Checked then
        frmMain.SetRetouchBrushMode(bmDodge)
      else
        frmMain.SetRetouchBrushMode(bmBurn);
    rfFocus:
      if rbErase.Checked then
        frmMain.SetRetouchBrushMode(bmSharpen)
      else
        frmMain.SetRetouchBrushMode(bmBlur);
    rfProtect:
      frmMain.SetRetouchProtectMode(rbErase.Checked);
  end;
end;

procedure TToolsDlg.tbrBrushChange(Sender: TObject);
begin
  if FUpdating then Exit;
  lblBrushVal.Caption := IntToStr(tbrBrush.Position);
  frmMain.SetRetouchBrushSize(tbrBrush.Position);
end;

procedure TToolsDlg.tbrStrengthChange(Sender: TObject);
begin
  if FUpdating then Exit;
  lblStrengthVal.Caption := IntToStr(tbrStrength.Position);
  FStrengthByFam[FActiveFam] := tbrStrength.Position;
  frmMain.SetRetouchStrength(tbrStrength.Position);
end;

procedure TToolsDlg.tbrToleranceChange(Sender: TObject);
begin
  if FUpdating then Exit;
  lblToleranceVal.Caption := IntToStr(tbrTolerance.Position);
  frmMain.SetRetouchTolerance(tbrTolerance.Position);
end;

procedure TToolsDlg.btnColorChooseClick(Sender: TObject);
var
  CD: TColorDialog;
begin
  if frmMain = nil then Exit;
  CD := TColorDialog.Create(nil);
  try
    CD.Color := frmMain.GetForeColor;
    CD.Options := CD.Options + [cdFullOpen];
    if CD.Execute then
    begin
      frmMain.SetForeColor(CD.Color);
      SyncSwatch;
    end;
  finally
    CD.Free;
  end;
end;

procedure TToolsDlg.btnColorChoose2Click(Sender: TObject);
var
  CD: TColorDialog;
begin
  if frmMain = nil then Exit;
  CD := TColorDialog.Create(nil);
  try
    CD.Color := frmMain.GetReplaceColor;
    CD.Options := CD.Options + [cdFullOpen];
    if CD.Execute then
    begin
      frmMain.SetReplaceColor(CD.Color);
      SyncSwatch;
    end;
  finally
    CD.Free;
  end;
end;

procedure TToolsDlg.chkRetainShadingClick(Sender: TObject);
begin
  if frmMain = nil then Exit;
  if FUpdating then Exit;
  frmMain.SetReplaceRetainShading(chkRetainShading.Checked);
end;

procedure TToolsDlg.RefitButtons;
begin
  inherited;
  FitButton(btnColorChoose);
  FitButton(btnColorChoose2);
end;

end.