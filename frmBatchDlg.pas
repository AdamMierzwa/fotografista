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

procedure TBatchDlg.btnSrcClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edSrc.Text;
  if SelectDirectory(T('Select source folder'), '', Dir, [sdNewUI]) then
    edSrc.Text := Dir;
end;

procedure TBatchDlg.btnDstClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edDst.Text;
  if SelectDirectory(T('Select output folder'), '', Dir, [sdNewUI]) then
    edDst.Text := Dir;
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

end.
