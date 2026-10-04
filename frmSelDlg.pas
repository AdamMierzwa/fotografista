unit frmSelDlg;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  uI18n, uSelection, uTitleBar;

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
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure cmbSelShapeChange(Sender: TObject);
    procedure rbSelOutlineClick(Sender: TObject);
    procedure rbSelMaskClick(Sender: TObject);
    procedure tbrSelTolChange(Sender: TObject);
    procedure tbrSelTolKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FUpdating: Boolean;
    procedure FillShapes;
    procedure ResyncView;
    procedure LayoutDialog;
    function DebounceDelay: Integer;
  public
    procedure SyncStatus;   // wołane z frmMain po załadowaniu obrazu / zmianie tolerancji
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
end;

procedure TSelDlg.LayoutDialog;
var
  ColLeft, ColW, W1, W2, MaxR, RowTop, WVal, MaxW: Integer;
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
  RowTop := StackBelow(rbSelOutline, SectionGap);

  // Szerokość kolumny: najszerszy wiersz (combo albo para radio), żeby suwak
  // tolerancji sięgał końca kolumny przy kombo szerszym niż radio.
  ColW := Max(cmbSelShape.Width, rbSelMask.Left + MaxR - ColLeft);

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
    ResyncView;
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
