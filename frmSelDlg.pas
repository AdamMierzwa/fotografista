unit frmSelDlg;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.Buttons, uI18n, uSelection, uTitleBar;

type
  // Panel Zaznaczenia - wzorzec 1:1 panelu Retusz (frmToolsDlg): combo kształtu,
  // radio kontur/maska oraz suwak tolerancji różdżki. Stan mieszka w frmMain
  // (FSelection, FSelectionView), dialog czyta go przy FormShow i zapisuje przez
  // publiczne akcesory; wzajemny sync chroni guard FUpdating.
  TSelDlg = class(TFotoForm)
    cmbSelShape: TComboBox;
    rbSelOutline: TRadioButton;
    rbSelMask: TRadioButton;
    lblSelTol: TLabel;
    tbrSelTol: TTrackBar;
    lblSelTolVal: TLabel;
    btnProtect: TSpeedButton;
    btnUnprotect: TSpeedButton;
    btnProtToSel: TButton;
    chkShowProt: TCheckBox;
    btnClearProt: TSpeedButton;
    btnDeselect: TSpeedButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure cmbSelShapeChange(Sender: TObject);
    procedure rbSelOutlineClick(Sender: TObject);
    procedure rbSelMaskClick(Sender: TObject);
    procedure tbrSelTolChange(Sender: TObject);
    procedure tbrSelTolKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnProtectClick(Sender: TObject);
    procedure btnUnprotectClick(Sender: TObject);
    procedure btnProtToSelClick(Sender: TObject);
    procedure chkShowProtClick(Sender: TObject);
    procedure btnClearProtClick(Sender: TObject);
    procedure btnDeselectClick(Sender: TObject);
  private
    FUpdating: Boolean;
    procedure FillShapes;
    procedure ResyncView;
    procedure LayoutDialog;
    function DebounceDelay: Integer;
  public
    procedure SyncStatus;   // wołane z frmMain po załadowaniu obrazu / zmianie tolerancji
    // stan przyciskow ochrony i pola Pokaz - z frmMain po zmianie zaznaczenia
    // i maski ochronnej (lekkie, bez ResyncView)
    procedure UpdateProtControls;
    class procedure ShowSelection;
  end;

var
  SelDlgInst: TSelDlg;

implementation

{$R *.dfm}

uses
  fMain, Vcl.Menus, Winapi.Windows;

procedure TSelDlg.FillShapes;
begin
  FUpdating := True;
  try
    cmbSelShape.Items.Clear;
    cmbSelShape.Items.Add(T('Rectangular selection'));
    cmbSelShape.Items.Add(T('Elliptical selection'));
    cmbSelShape.Items.Add(T('Lasso'));
    cmbSelShape.Items.Add(T('Magic wand'));
    cmbSelShape.ItemIndex := Ord(frmMain.FSelection.Shape);
  finally
    FUpdating := False;
  end;
end;

procedure TSelDlg.ResyncView;
begin
  FUpdating := True;
  try
    // ksztalt moze zmienic sie spoza panelu (menu Narzedzia)
    cmbSelShape.ItemIndex := Ord(frmMain.FSelection.Shape);
    rbSelOutline.Checked := (frmMain.FSelectionView = svOutline);
    rbSelMask.Checked := (frmMain.FSelectionView = svMask);
    // Suwak tolerancji widoczny tylko dla różdżki (jak pasek wiaderka w Retuszu).
    tbrSelTol.Visible := (frmMain.FSelection.Shape = hsWand);
    lblSelTol.Visible := tbrSelTol.Visible;
    lblSelTolVal.Visible := tbrSelTol.Visible;
    if tbrSelTol.Visible then
    begin
      tbrSelTol.Position := frmMain.GetRetouchTolerance;
      lblSelTolVal.Caption := IntToStr(tbrSelTol.Position);
    end;
  finally
    FUpdating := False;
  end;
  UpdateProtControls;
end;

// Chron: tylko przy istniejacym zaznaczeniu; Odwolaj: zaznaczenie i cos
// chronionego (te same warunki, przy ktorych handlery menu cokolwiek robia,
// fMain.mnuProtFromSelClick / mnuProtUnprotSelClick).
procedure TSelDlg.UpdateProtControls;
begin
  if frmMain = nil then Exit;
  FUpdating := True;
  try
    btnProtect.Enabled := frmMain.FSelection.IsValid;
    // Odwolaj: zawsze gdy maska istnieje - bez zaznaczenia maska wraca jako
    // zaznaczenie, z zaznaczeniem ochrona zdejmowana w zaznaczeniu
    btnUnprotect.Enabled := frmMain.ProtMaskCovered;
    // Zaznacz obszar chroniony / Pokaz: tylko gdy maska istnieje (bez maski
    // pole Pokaz niczego nie pokazuje i sugeruje, ze maska jest)
    btnProtToSel.Enabled := frmMain.ProtMaskCovered;
    chkShowProt.Enabled := frmMain.ProtMaskCovered;
    chkShowProt.Checked := frmMain.ProtMaskShown;
    btnClearProt.Enabled := frmMain.ProtMaskCovered;
    btnDeselect.Enabled := frmMain.FSelection.Active;
  finally
    FUpdating := False;
  end;
end;

procedure TSelDlg.LayoutDialog;
var
  ColLeft, ColW, W1, W2, MaxR, RowTop, WVal, MaxW, BtnW, BtnLeft: Integer;
  SB: TSpeedButton;
  Btns: TArray<TSpeedButton>;
begin
  ColLeft := CtrlGap * 3;
  RowTop := ColLeft;

  // Wiersz 1: combo kształtu zaznaczenia.
  Self.Canvas.Font.Assign(cmbSelShape.Font);
  MaxW := Self.Canvas.TextWidth(cmbSelShape.Items[0]);
  cmbSelShape.Left := ColLeft;
  cmbSelShape.Top := RowTop;
  cmbSelShape.Width := MaxW + 32;
  RowTop := StackBelow(cmbSelShape, SectionGap);

  // Wiersz radio: kontur / maska.
  Self.Canvas.Font.Assign(rbSelOutline.Font);
  W1 := Self.Canvas.TextWidth(rbSelOutline.Caption);
  W2 := Self.Canvas.TextWidth(rbSelMask.Caption);
  MaxR := Max(W1, W2) + 30;
  rbSelOutline.Left := ColLeft;
  rbSelOutline.Top := RowTop;
  rbSelOutline.Width := MaxR;
  rbSelMask.Left := rbSelOutline.Left + MaxR + CtrlGap * 2;
  rbSelMask.Top := RowTop;
  rbSelMask.Width := MaxR;
  // wysokosc z czcionki jak w Timelapse / Wydajnosci (TH + 4) - 17 px z .dfm
  // obcinalo przy 12 pt dol liter
  rbSelOutline.Height := Self.Canvas.TextHeight('Wg') + 4;
  rbSelMask.Height := rbSelOutline.Height;
  RowTop := StackBelow(rbSelOutline, SectionGap);

  // Przyciski: TSpeedButton, bo Margin wyrownuje napis do lewej.
  // Usun zaznaczenie pod radio (lewa kolumna dotyczy zaznaczenia).
  Self.Canvas.Font.Assign(btnDeselect.Font);
  btnDeselect.Width := Max(85, Self.Canvas.TextWidth(btnDeselect.Caption) + ButtonPad);
  btnDeselect.Margin := ButtonPad div 2;
  btnDeselect.Left := ColLeft;
  btnDeselect.Top := RowTop;
  RowTop := StackBelow(btnDeselect, SectionGap);

  // Maska ochronna: kolumna jednej szerokosci na prawo od listy ksztaltow,
  // kolejnosc jak w podmenu, rowne odstepy, napisy od lewej; Pokaz maske
  // to pole do zaznaczenia.
  // Zaznacz obszar chroniony ukryty (Visible = False w .dfm, decyzja
  // wlasciciela 2026-10-24 - moze wroci do innego dzialania).
  Self.Canvas.Font.Assign(btnProtect.Font);
  Btns := [btnProtect, btnUnprotect, btnClearProt];
  chkShowProt.Height := Self.Canvas.TextHeight('Wg') + 4;
  chkShowProt.Width := Self.Canvas.TextWidth(chkShowProt.Caption) +
    GetSystemMetrics(SM_CXMENUCHECK) + CtrlGap * 3;
  BtnW := Max(85, chkShowProt.Width);
  for SB in Btns do
    BtnW := Max(BtnW, Self.Canvas.TextWidth(SB.Caption) + ButtonPad);
  for SB in Btns do
  begin
    SB.Width := BtnW;
    SB.Margin := ButtonPad div 2;
  end;
  BtnLeft := cmbSelShape.Left + cmbSelShape.Width + CtrlGap * 2;
  btnProtect.Left := BtnLeft;
  btnProtect.Top := cmbSelShape.Top;
  btnUnprotect.Left := BtnLeft;
  btnUnprotect.Top := StackBelow(btnProtect, RowGap);
  chkShowProt.Left := BtnLeft;
  chkShowProt.Top := StackBelow(btnUnprotect, RowGap);
  btnClearProt.Left := BtnLeft;
  btnClearProt.Top := StackBelow(chkShowProt, RowGap);
  RowTop := Max(RowTop, StackBelow(btnClearProt, SectionGap));

  // Szerokość kolumny: lewa kolumna (combo, para radio) plus kolumna
  // przyciskow maski, żeby suwak tolerancji sięgał prawej krawędzi.
  ColW := Max(cmbSelShape.Width, rbSelMask.Left + MaxR - ColLeft);
  ColW := Max(ColW, BtnLeft + BtnW - ColLeft);

  // Suwak tolerancji (tylko różdżka).
  if tbrSelTol.Visible then
  begin
    Self.Canvas.Font.Assign(lblSelTolVal.Font);
    WVal := Self.Canvas.TextWidth('100');
    lblSelTol.Left := ColLeft;
    lblSelTol.Top := RowTop;
    tbrSelTol.Top := StackBelow(lblSelTol, RowGap);
    tbrSelTol.Left := ColLeft;
    tbrSelTol.Width := ColW - CtrlGap - WVal;
    lblSelTolVal.Top := tbrSelTol.Top + (tbrSelTol.Height - lblSelTolVal.Height) div 2;
    lblSelTolVal.Left := tbrSelTol.Left + tbrSelTol.Width + CtrlGap;
  end;

  FitToContent(CtrlGap * 3, CtrlGap * 3);
end;

procedure TSelDlg.FormShow(Sender: TObject);
begin
  if frmMain = nil then Exit;
  Self.Caption := T('Selection');
  FUpdating := True;
  try
    FillShapes;
    ResyncView;
  finally
    FUpdating := False;
  end;
  LayoutDialog;
end;

procedure TSelDlg.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
  frmMain.ActivateTool(tkSelection);
end;

procedure TSelDlg.cmbSelShapeChange(Sender: TObject);
begin
  if FUpdating then Exit;
  if cmbSelShape.ItemIndex < 0 then Exit;
  frmMain.DoSetSelectionShape(THitShape(cmbSelShape.ItemIndex));
  // Suwak tolerancji jest widoczny tylko dla różdżki. Po zmianie kształtu
  // przelicz widoczność i wysokość okna (wzorzec Retusz: SyncFamily + LayoutDialog).
  ResyncView;
  LayoutDialog;
end;

// Przyciski i pole ochrony wolaja handlery fMain.mnuProt*Click (dawne
// podmenu Narzedzia > Maska ochronna, usuniete 2026-10-24 - dublowalo panel).
procedure TSelDlg.btnProtectClick(Sender: TObject);
begin
  if FUpdating then Exit;
  frmMain.mnuProtFromSelClick(Self);
  UpdateProtControls;
end;

procedure TSelDlg.btnUnprotectClick(Sender: TObject);
begin
  if FUpdating then Exit;
  frmMain.mnuProtUnprotSelClick(Self);
  UpdateProtControls;
end;

procedure TSelDlg.btnProtToSelClick(Sender: TObject);
begin
  if FUpdating then Exit;
  frmMain.MaskToSelection;   // przycisk zostaje na razie (decyzja wlasciciela)
  UpdateProtControls;
end;

procedure TSelDlg.chkShowProtClick(Sender: TObject);
begin
  if FUpdating then Exit;
  if chkShowProt.Checked <> frmMain.ProtMaskShown then
    frmMain.mnuProtShowClick(Self);   // przelacza podglad maski
end;

procedure TSelDlg.btnClearProtClick(Sender: TObject);
begin
  if FUpdating then Exit;
  frmMain.mnuProtClearClick(Self);
  UpdateProtControls;
end;

procedure TSelDlg.btnDeselectClick(Sender: TObject);
begin
  if FUpdating then Exit;
  frmMain.ClearSelection;   // to samo co Del / PPM na obrazie
  UpdateProtControls;
end;

procedure TSelDlg.rbSelOutlineClick(Sender: TObject);
begin
  if FUpdating then Exit;
  frmMain.SetSelectionView(svOutline);
end;

procedure TSelDlg.rbSelMaskClick(Sender: TObject);
begin
  if FUpdating then Exit;
  frmMain.SetSelectionView(svMask);
end;

procedure TSelDlg.tbrSelTolChange(Sender: TObject);
begin
  if FUpdating then Exit;
  if not tbrSelTol.Visible then Exit;
  lblSelTolVal.Caption := IntToStr(tbrSelTol.Position);
  frmMain.SetRetouchTolerance(tbrSelTol.Position);
  frmMain.DebouncedWandFromSeed(DebounceDelay);
end;

procedure TSelDlg.tbrSelTolKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if tbrSelTol.Visible then
    frmMain.DebouncedWandFromSeed(DebounceDelay);
end;

function TSelDlg.DebounceDelay: Integer;
begin
  Result := 200; // ms - patrz AGENTS.md: live z debounce dla różdżki.
end;

procedure TSelDlg.SyncStatus;
begin
  if Visible and not FUpdating then
  begin
    ResyncView;
    LayoutDialog;   // suwak tolerancji znika/pojawia sie przy zmianie ksztaltu
  end;
end;

class procedure TSelDlg.ShowSelection;
begin
  if SelDlgInst = nil then
    SelDlgInst := TSelDlg.Create(Application);
  frmMain.DoSetSelectionShape(
    frmMain.FSelection.Shape);
  SelDlgInst.Show;
end;

end.
