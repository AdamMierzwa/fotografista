unit frmInterfaceDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.Samples.Spin, Vcl.ExtCtrls, Vcl.Themes, uTitleBar, uI18n;

type
  TInterfacePreviewProc = procedure(AColor: TColor; AFontSize: Integer) of object;

  TInterfaceDlg = class(TFotoForm)
    lblCanvasBG: TLabel;
    btnCanvasBG: TButton;
    chkRememberWin: TCheckBox;
    lblFontSize: TLabel;
    spinFontSize: TSpinEdit;
    lblRecentCount: TLabel;
    spinRecentCount: TSpinEdit;
    lblTheme: TLabel;
    cmbTheme: TComboBox;
    lblBrushCursor: TLabel;
    cmbBrushCursor: TComboBox;
    chkBrushCrosshairCenter: TCheckBox;
    btnOK: TButton;
    btnCancel: TButton;
    procedure btnCanvasBGClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure spinFontSizeChange(Sender: TObject);
    procedure cmbBrushCursorChange(Sender: TObject);
  public
    procedure RefitButtons; override;
  private
    FCanvasBG: TColor;
    FTheme: string;
    FBaseFont: Integer;
    FOnPreview: TInterfacePreviewProc;
    procedure DoPreview;
  public
    property CanvasBG: TColor read FCanvasBG write FCanvasBG;
    property Theme: string read FTheme write FTheme;
    property OnPreview: TInterfacePreviewProc read FOnPreview write FOnPreview;
  end;

function ShowInterfaceDlg(var ACanvasBG: TColor;
  out ARememberWin: Boolean; out AFontSize, ARecentCount: Integer;
  var ATheme: string; var ABrushCursorMode: Integer;
  var ABrushCrosshairCenter: Boolean;
  AOnPreview: TInterfacePreviewProc = nil): Boolean;

implementation

{$R *.dfm}

uses
  Vcl.ColorGrd,
  uPrefs;

procedure TInterfaceDlg.FormCreate(Sender: TObject);
var
  S: string;
begin
  FCanvasBG := RGB(80, 80, 80);
  for S in TStyleManager.StyleNames do
    cmbTheme.Items.Add(S);
  cmbTheme.ItemIndex := 0;
  cmbBrushCursor.Items.Add(T('Circle outline'));
  cmbBrushCursor.Items.Add(T('Crosshair (precise)'));
end;

// Uklad z zawartosci (2026-10-21; wczesniej sztywne 340x484, sekcje na stalych
// Top co ~64 px, pola wyboru 300x17). Pionowy stos bez zmian wygladu; szerokosc
// kolumny z najdluzszego tekstu (etykiety, pola wyboru, pozycje list), opis
// koloru tla zawijany w tej szerokosci. Przeliczane takze przy zmianie
// czcionki z tego okna (podglad -> CMParentFontChanged -> RefitButtons).
procedure TInterfaceDlg.RefitButtons;
var
  Margin, W, Y, TH, Check, I: Integer;

  procedure Section(L: TLabel; C: TControl);
  begin
    L.Left := Margin;
    L.Top := Y;
    Inc(Y, L.Height + CtrlGap);
    C.Left := Margin;
    C.Top := Y;
    Inc(Y, C.Height + SectionGap);
  end;

  procedure Check1(C: TCheckBox);
  begin
    C.SetBounds(Margin, Y, Canvas.TextWidth(C.Caption) + Check, TH + 4);
    Inc(Y, C.Height + SectionGap);
  end;

begin
  inherited;
  FitButton(btnCanvasBG);
  Margin := CtrlGap * 4;
  TH := Canvas.TextHeight('Wg');
  Check := GetSystemMetrics(SM_CXMENUCHECK) + CtrlGap * 3;

  // szerokosc kolumny: najdluzszy tekst jednowierszowy (opis koloru tla sie
  // zawija, wiec liczy sie tylko minimalnie)
  W := Canvas.TextWidth('0') * 30;
  W := Max(W, Canvas.TextWidth(lblFontSize.Caption));
  W := Max(W, Canvas.TextWidth(lblRecentCount.Caption));
  W := Max(W, Canvas.TextWidth(lblTheme.Caption));
  W := Max(W, Canvas.TextWidth(lblBrushCursor.Caption));
  W := Max(W, Canvas.TextWidth(chkRememberWin.Caption) + Check);
  W := Max(W, Canvas.TextWidth(chkBrushCrosshairCenter.Caption) + Check);
  for I := 0 to cmbTheme.Items.Count - 1 do
    W := Max(W, Canvas.TextWidth(cmbTheme.Items[I]) + GetSystemMetrics(SM_CXVSCROLL) + CtrlGap * 3);
  for I := 0 to cmbBrushCursor.Items.Count - 1 do
    W := Max(W, Canvas.TextWidth(cmbBrushCursor.Items[I]) + GetSystemMetrics(SM_CXVSCROLL) + CtrlGap * 3);

  Y := Margin;
  // kolor tla: opis zawijany w szerokosci kolumny (AutoSize + WordWrap -> wysokosc)
  // AutoSize wylaczany i wlaczany ponownie, zeby wysokosc przeliczyla sie dla
  // nowej szerokosci (setter AutoSize przelicza tylko przy zmianie wartosci)
  lblCanvasBG.AutoSize := False;
  lblCanvasBG.SetBounds(Margin, Y, W, TH);
  lblCanvasBG.AutoSize := True;
  Inc(Y, lblCanvasBG.Height + CtrlGap);
  btnCanvasBG.Left := Margin;
  btnCanvasBG.Top := Y;
  Inc(Y, btnCanvasBG.Height + RowGap * 2);
  Check1(chkRememberWin);

  spinFontSize.Width := Canvas.TextWidth('000') + GetSystemMetrics(SM_CXVSCROLL) + CtrlGap * 4;
  spinRecentCount.Width := spinFontSize.Width;
  Section(lblFontSize, spinFontSize);
  Section(lblRecentCount, spinRecentCount);
  cmbTheme.Width := W;
  cmbBrushCursor.Width := W;
  Section(lblTheme, cmbTheme);
  lblBrushCursor.Left := Margin;
  lblBrushCursor.Top := Y;
  Inc(Y, lblBrushCursor.Height + CtrlGap);
  cmbBrushCursor.Left := Margin;
  cmbBrushCursor.Top := Y;
  Inc(Y, cmbBrushCursor.Height + RowGap * 2);
  Check1(chkBrushCrosshairCenter);

  btnOK.Top := Y;
  btnCancel.Top := Y;
  FitToContent(SectionGap, Margin);
  if ClientWidth < btnOK.Width + btnCancel.Width + CtrlGap * 2 + Margin * 2 then
    ClientWidth := btnOK.Width + btnCancel.Width + CtrlGap * 2 + Margin * 2;
  AlignButtonsRight([btnOK, btnCancel], Margin);
end;

procedure TInterfaceDlg.DoPreview;
begin
  if Assigned(FOnPreview) then
    FOnPreview(FCanvasBG, spinFontSize.Value - FBaseFont);
end;

procedure TInterfaceDlg.btnCanvasBGClick(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FCanvasBG;
    Dlg.Options := [cdFullOpen];
    if Dlg.Execute then
    begin
      FCanvasBG := Dlg.Color;
      DoPreview;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TInterfaceDlg.spinFontSizeChange(Sender: TObject);
begin
  DoPreview;
end;

procedure TInterfaceDlg.cmbBrushCursorChange(Sender: TObject);
begin
  chkBrushCrosshairCenter.Enabled := (cmbBrushCursor.ItemIndex = 0);
end;

function ShowInterfaceDlg(var ACanvasBG: TColor;
  out ARememberWin: Boolean; out AFontSize, ARecentCount: Integer;
  var ATheme: string; var ABrushCursorMode: Integer;
  var ABrushCrosshairCenter: Boolean;
  AOnPreview: TInterfacePreviewProc): Boolean;
var
  Dlg: TInterfaceDlg;
  Idx: Integer;
begin
  Result := False;
  Dlg := TInterfaceDlg.Create(Application);
  try
    Dlg.FBaseFont := Application.DefaultFont.Size - Prefs.UIFontSize;
    Dlg.CanvasBG := ACanvasBG;
    Dlg.spinFontSize.MinValue := 8;
    Dlg.spinFontSize.MaxValue := 12;
    Dlg.spinFontSize.Value := Dlg.FBaseFont + AFontSize;
    Dlg.spinRecentCount.Value := ARecentCount;
    Dlg.chkRememberWin.Checked := ARememberWin;
    Dlg.Theme := ATheme;
    Idx := Dlg.cmbTheme.Items.IndexOf(Dlg.Theme);
    if Idx >= 0 then
      Dlg.cmbTheme.ItemIndex := Idx;
    Dlg.cmbBrushCursor.ItemIndex := ABrushCursorMode;
    Dlg.chkBrushCrosshairCenter.Checked := ABrushCrosshairCenter;
    Dlg.cmbBrushCursorChange(Dlg.cmbBrushCursor);
    Dlg.OnPreview := AOnPreview;
    if Dlg.ShowModal = mrOk then
    begin
      ACanvasBG := Dlg.CanvasBG;
      ARememberWin := Dlg.chkRememberWin.Checked;
      AFontSize := Dlg.spinFontSize.Value - Dlg.FBaseFont;
      ARecentCount := Dlg.spinRecentCount.Value;
      if Dlg.cmbTheme.ItemIndex >= 0 then
        ATheme := Dlg.cmbTheme.Items[Dlg.cmbTheme.ItemIndex];
      ABrushCursorMode := Dlg.cmbBrushCursor.ItemIndex;
      ABrushCrosshairCenter := Dlg.chkBrushCrosshairCenter.Checked;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
