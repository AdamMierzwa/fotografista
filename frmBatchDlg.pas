unit frmBatchDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.FileCtrl,
  uMacros, uI18n, uTitleBar;

type
  TBatchOptions = record
    SrcDir: string;
    DstDir: string;
    MacroIndex: Integer;
    NoMacro: Boolean;
    Scale: Boolean;
    TargetEdge: Integer;
  end;

  TBatchDlg = class(TFotoForm)
    lblSrc: TLabel;
    edSrc: TEdit;
    btnSrc: TButton;
    lblDst: TLabel;
    edDst: TEdit;
    btnDst: TButton;
    lblMacro: TLabel;
    cbMacro: TComboBox;
    chkNoMacro: TCheckBox;
    chkScale: TCheckBox;
    edEdge: TEdit;
    btnStart: TButton;
    btnClose: TButton;
    procedure btnSrcClick(Sender: TObject);
    procedure btnDstClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure chkScaleClick(Sender: TObject);
  private
    FOpts: TBatchOptions;
  public
    procedure RefitButtons; override;
  end;

function ShowBatchDlg(out Opts: TBatchOptions): Boolean;

implementation

{$R *.dfm}

function ShowBatchDlg(out Opts: TBatchOptions): Boolean;
var
  Dlg: TBatchDlg;
  i: Integer;
begin
  Result := False;
  Dlg := TBatchDlg.Create(Application);
  try
    for i := 0 to MacrosCount - 1 do
      Dlg.cbMacro.Items.Add(MacrosGet(i).Name);
    if Dlg.cbMacro.Items.Count > 0 then
      Dlg.cbMacro.ItemIndex := 0;
    Dlg.edEdge.Text := '1920';
    Dlg.chkScaleClick(nil);
    if Dlg.ShowModal = mrOk then
    begin
      Opts := Dlg.FOpts;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

// Po wybraniu folderu pole pokazuje koniec sciezki (nazwe folderu), a nie
// poczatek: kursor na koncu tekstu przewija pole (wymaga fokusu).
procedure ShowPathEnd(E: TEdit);
begin
  if E.CanFocus then
    E.SetFocus;
  E.SelStart := Length(E.Text);
  E.SelLength := 0;
end;

procedure TBatchDlg.btnSrcClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edSrc.Text;
  if SelectDirectory(T('Select source folder'), '', Dir, [sdNewUI]) then
  begin
    edSrc.Text := Dir;
    ShowPathEnd(edSrc);
  end;
end;

procedure TBatchDlg.btnDstClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edDst.Text;
  if SelectDirectory(T('Select output folder'), '', Dir, [sdNewUI]) then
  begin
    edDst.Text := Dir;
    ShowPathEnd(edDst);
  end;
end;

procedure TBatchDlg.chkScaleClick(Sender: TObject);
begin
  edEdge.Enabled := chkScale.Checked;
end;

procedure TBatchDlg.btnStartClick(Sender: TObject);
var
  EdgeVal: Integer;
  i: Integer;
  M: TMacro;
  HasResize: Boolean;
begin
  if (Trim(edSrc.Text) = '') or (Trim(edDst.Text) = '') then
  begin
    MessageDlg(T('Fill in all fields.'), mtWarning, [mbOK], 0);
    Exit;
  end;
  if cbMacro.ItemIndex < 0 then
  begin
    MessageDlg(T('Fill in all fields.'), mtWarning, [mbOK], 0);
    Exit;
  end;

  FOpts.SrcDir := Trim(edSrc.Text);
  FOpts.DstDir := Trim(edDst.Text);
  FOpts.MacroIndex := cbMacro.ItemIndex;
  FOpts.NoMacro := chkNoMacro.Checked;
  FOpts.Scale := chkScale.Checked;
  FOpts.TargetEdge := 1920;
  if FOpts.Scale then
  begin
    EdgeVal := StrToIntDef(Trim(edEdge.Text), 0);
    if EdgeVal > 0 then
      FOpts.TargetEdge := EdgeVal;
  end;

  if FOpts.Scale and (not FOpts.NoMacro) then
  begin
    M := MacrosGet(FOpts.MacroIndex);
    HasResize := False;
    for i := 0 to High(M.Steps) do
    begin
      if SameText(M.Steps[i].Code, 'RESIZE') or SameText(M.Steps[i].Code, 'RESIZECROP') then
      begin
        HasResize := True;
        Break;
      end;
    end;
    if HasResize then
    begin
      if MessageDlg(T('Macro contains a resize step. Combining it with batch scaling may give unexpected results.'),
          mtWarning, [mbYes, mbNo], 0) <> mrYes then
        Exit;
    end;
  end;

  ModalResult := mrOk;
end;

procedure TBatchDlg.btnCloseClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

// Uklad z zawartosci (2026-10-21; wczesniej sztywne 470x225, pola na stalym
// Left = 130, pola wyboru 200x17, Zamknij dotykal prawej krawedzi okna).
// Uklad bez zmian: etykiety | pole + Wybierz...; makro; pola wyboru; Start/Zamknij
// do prawej. Kolumna etykiet z najdluzszej etykiety, wiersze z wysokosci
// kontrolek, odstepy z czcionki.
procedure TBatchDlg.RefitButtons;
var
  Margin, X1, Y, RowH, TH, Check, EdW: Integer;

  procedure PlaceLabel(L: TLabel; RowTop, RowHeight: Integer);
  begin
    L.Left := Margin;
    L.Top := RowTop + (RowHeight - L.Height) div 2;
  end;

begin
  inherited;
  Margin := CtrlGap * 3;
  TH := Canvas.TextHeight('Wg');
  Check := GetSystemMetrics(SM_CXMENUCHECK) + CtrlGap * 3;
  FitButtonGroup([btnSrc, btnDst]);
  FitButtonGroup([btnStart, btnClose]);

  X1 := Margin + Max(Canvas.TextWidth(lblSrc.Caption),
    Max(Canvas.TextWidth(lblDst.Caption), Canvas.TextWidth(lblMacro.Caption))) + SectionGap;
  EdW := Canvas.TextWidth('0') * 40;   // sciezka ok. 40 znakow
  RowH := Max(edSrc.Height, btnSrc.Height);

  // Folder zrodlowy / docelowy: pole + Wybierz...
  Y := Margin;
  edSrc.SetBounds(X1, Y + (RowH - edSrc.Height) div 2, EdW, edSrc.Height);
  btnSrc.Left := X1 + EdW + CtrlGap * 2;
  btnSrc.Top := Y + (RowH - btnSrc.Height) div 2;
  PlaceLabel(lblSrc, Y, RowH);
  Inc(Y, RowH + RowGap * 2);
  edDst.SetBounds(X1, Y + (RowH - edDst.Height) div 2, EdW, edDst.Height);
  btnDst.Left := btnSrc.Left;
  btnDst.Top := Y + (RowH - btnDst.Height) div 2;
  PlaceLabel(lblDst, Y, RowH);
  Inc(Y, RowH + RowGap * 2);

  // Makro: lista na szerokosc pola + przycisku
  cbMacro.SetBounds(X1, Y, btnSrc.Left + btnSrc.Width - X1, cbMacro.Height);
  PlaceLabel(lblMacro, Y, cbMacro.Height);
  Inc(Y, cbMacro.Height + RowGap * 2);

  // Pola wyboru pod lista
  chkNoMacro.SetBounds(X1, Y, Canvas.TextWidth(chkNoMacro.Caption) + Check, TH + 4);
  Inc(Y, chkNoMacro.Height + RowGap * 2);
  RowH := Max(TH + 4, edEdge.Height);
  chkScale.SetBounds(X1, Y + (RowH - (TH + 4)) div 2,
    Canvas.TextWidth(chkScale.Caption) + Check, TH + 4);
  edEdge.SetBounds(chkScale.Left + chkScale.Width + CtrlGap * 2,
    Y + (RowH - edEdge.Height) div 2, Canvas.TextWidth('00000') + CtrlGap * 4,
    edEdge.Height);
  Inc(Y, RowH);

  btnStart.Top := Y + SectionGap;
  btnClose.Top := btnStart.Top;
  FitToContent(SectionGap, Margin);
  AlignButtonsRight([btnStart, btnClose], Margin);
end;

end.
