unit frmResizeDlg;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uTitleBar, uI18n;

type
  TResizeDlg = class(TFotoForm)
    pnlRadio: TPanel;
    pnlInput: TPanel;
    pnlBottom: TPanel;
    rbManual: TRadioButton;
    rbAutoPct: TRadioButton;
    lblMethod: TLabel;
    lblWidth: TLabel;
    lblHeight: TLabel;
    edWidth: TEdit;
    edHeight: TEdit;
    chkAspect: TCheckBox;
    lblPercent: TLabel;
    tbPercent: TTrackBar;
    lblPctValue: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure rbManualClick(Sender: TObject);
    procedure rbAutoPctClick(Sender: TObject);
    procedure edWidthChange(Sender: TObject);
    procedure edHeightChange(Sender: TObject);
    procedure tbPercentChange(Sender: TObject);
    procedure chkAspectClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FOrigW, FOrigH: Integer;
    FUpdating: Boolean;
    procedure SetMode(IsAuto: Boolean);
    procedure SyncFromPercent;
    procedure SyncAspectFromWidth;
    procedure SyncAspectFromHeight;
  public
    procedure LayoutDialog;
    property OrigWidth: Integer read FOrigW write FOrigW;
    property OrigHeight: Integer read FOrigH write FOrigH;
  end;

var
  ResizeSourceBmp: TBitmap = nil;

function ShowResizeDlg(out NewW, NewH: Integer): Boolean;

implementation

{$R *.dfm}

procedure TResizeDlg.FormCreate(Sender: TObject);
begin
  { Podmiana napisow musi sie odbyc przed LayoutDialog - tam sa mierzone
    szerokosci. Wzorzec: frmAmigaBGDlg, frmLauncherDlg. }
  TranslateForm(Self);
end;

{ Jawny layout liczony z fontu, wzorzec frmStereogramDlg.LayoutDialog.
  Panele nie maja Align - inaczej FitToContent mierzylby panel rozciagniety
  do ClientWidth i okno roslo by o margines przy kazdym wywolaniu. }
procedure TResizeDlg.LayoutDialog;
var
  Margin, ColLeft, ColW, LblColW, PadT, W: Integer;
begin
  Margin := CtrlGap * 3;
  ColLeft := Margin;
  PadT := CtrlGap * 2;

  { Radio i checkbox nie skaluja sie automatycznie - liczymy szerokosc
    z przetlumaczonego captiona plus ButtonPad na kółko i odstep. }
  Self.Canvas.Font.Assign(rbManual.Font);
  rbManual.Width := Self.Canvas.TextWidth(rbManual.Caption) + ButtonPad;
  Self.Canvas.Font.Assign(rbAutoPct.Font);
  rbAutoPct.Width := Self.Canvas.TextWidth(rbAutoPct.Caption) + ButtonPad;
  Self.Canvas.Font.Assign(chkAspect.Font);
  chkAspect.Width := Self.Canvas.TextWidth(chkAspect.Caption) + ButtonPad;

  FitButtonGroup([btnOK, btnCancel]);

  { TLabel ma AutoSize = True, wiec po TranslateForm jego Width jest juz
    zmierzone przez VCL - tutaj tylko czytamy. }
  LblColW := Max(lblWidth.Width, lblHeight.Width);

  ColW := LblColW + CtrlGap * 2 + edWidth.Width;
  W := rbManual.Width + CtrlGap * 2 + rbAutoPct.Width;
  if W > ColW then ColW := W;
  if chkAspect.Width > ColW then ColW := chkAspect.Width;
  if lblPercent.Width > ColW then ColW := lblPercent.Width;

  pnlRadio.Left := 0;
  pnlRadio.Top := 0;
  pnlRadio.Width := ColLeft + ColW;
  lblMethod.Left := ColLeft;
  lblMethod.Top := PadT;
  rbManual.Left := ColLeft;
  rbManual.Top := StackBelow(lblMethod, RowGap);
  rbAutoPct.Left := ColLeft + rbManual.Width + CtrlGap * 2;
  rbAutoPct.Top := rbManual.Top;
  pnlRadio.Height := StackBelow(rbManual, PadT);

  pnlInput.Left := 0;
  pnlInput.Top := pnlRadio.Height;
  pnlInput.Width := ColLeft + ColW;
  edWidth.Left := ColLeft + LblColW + CtrlGap * 2;
  edHeight.Left := edWidth.Left;
  lblWidth.Left := ColLeft;
  lblHeight.Left := ColLeft;
  edWidth.Top := PadT;
  edHeight.Top := PadT + edWidth.Height + RowGap;
  lblWidth.Top := PadT + (edWidth.Height - lblWidth.Height) div 2;
  lblHeight.Top := PadT + edWidth.Height + RowGap + (edHeight.Height - lblHeight.Height) div 2;
  pnlInput.Height := StackBelow(edHeight, PadT);

  chkAspect.Left := ColLeft;
  chkAspect.Top := StackBelow(pnlInput, SectionGap);
  lblPercent.Left := ColLeft;
  lblPercent.Top := StackBelow(chkAspect, RowGap);
  tbPercent.Left := ColLeft;
  tbPercent.Top := StackBelow(lblPercent, RowGap);
  tbPercent.Width := ColW;
  lblPctValue.Left := ColLeft + (ColW - lblPctValue.Width) div 2;
  lblPctValue.Top := StackBelow(tbPercent, RowGap);

  pnlBottom.Left := 0;
  pnlBottom.Top := StackBelow(lblPctValue, SectionGap);
  pnlBottom.Width := ColLeft + ColW;
  btnCancel.Top := PadT;
  btnOK.Top := PadT;
  pnlBottom.Height := StackBelow(btnOK, PadT);

  FitToContent(CtrlGap * 3, CtrlGap * 3);
  AlignButtonsRight([btnOK, btnCancel], CtrlGap * 3);
  FitHeight(CtrlGap * 3);
end;

function ShowResizeDlg(out NewW, NewH: Integer): Boolean;
var
  Dlg: TResizeDlg;
begin
  Result := False;
  if ResizeSourceBmp = nil then Exit;
  Dlg := TResizeDlg.Create(Application);
  try
    Dlg.FOrigW := ResizeSourceBmp.Width;
    Dlg.FOrigH := ResizeSourceBmp.Height;
    Dlg.edWidth.Text := IntToStr(Dlg.FOrigW);
    Dlg.edHeight.Text := IntToStr(Dlg.FOrigH);
    Dlg.chkAspect.Checked := True;
    Dlg.tbPercent.Position := 100;
    Dlg.lblPctValue.Caption := '100%';
    Dlg.rbManual.Checked := True;
    Dlg.SetMode(False);
    Dlg.LayoutDialog;
    Result := Dlg.ShowModal = mrOk;
    if Result then
    begin
      NewW := StrToIntDef(Dlg.edWidth.Text, Dlg.FOrigW);
      NewH := StrToIntDef(Dlg.edHeight.Text, Dlg.FOrigH);
      if NewW < 1 then NewW := 1;
      if NewH < 1 then NewH := 1;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TResizeDlg.SetMode(IsAuto: Boolean);
begin
  edWidth.Enabled := not IsAuto;
  edHeight.Enabled := not IsAuto;
  chkAspect.Enabled := not IsAuto;
  tbPercent.Enabled := IsAuto;
end;

procedure TResizeDlg.rbManualClick(Sender: TObject);
begin
  SetMode(False);
end;

procedure TResizeDlg.rbAutoPctClick(Sender: TObject);
begin
  SetMode(True);
  SyncFromPercent;
end;

procedure TResizeDlg.SyncFromPercent;
var
  Pct: Double;
begin
  Pct := tbPercent.Position / 100.0;
  edWidth.Text := IntToStr(Max(1, Round(FOrigW * Pct)));
  edHeight.Text := IntToStr(Max(1, Round(FOrigH * Pct)));
end;

procedure TResizeDlg.tbPercentChange(Sender: TObject);
begin
  if not tbPercent.Enabled then Exit;
  lblPctValue.Caption := IntToStr(tbPercent.Position) + '%';
  SyncFromPercent;
end;

procedure TResizeDlg.SyncAspectFromWidth;
var
  W, H: Integer;
begin
  if FUpdating then Exit;
  FUpdating := True;
  try
    W := StrToIntDef(edWidth.Text, 0);
    if W > 0 then
    begin
      H := Max(1, Round(W * (FOrigH / FOrigW)));
      edHeight.Text := IntToStr(H);
    end;
  finally
    FUpdating := False;
  end;
end;

procedure TResizeDlg.SyncAspectFromHeight;
var
  W, H: Integer;
begin
  if FUpdating then Exit;
  FUpdating := True;
  try
    H := StrToIntDef(edHeight.Text, 0);
    if H > 0 then
    begin
      W := Max(1, Round(H * (FOrigW / FOrigH)));
      edWidth.Text := IntToStr(W);
    end;
  finally
    FUpdating := False;
  end;
end;

procedure TResizeDlg.edWidthChange(Sender: TObject);
begin
  if edWidth.Enabled and chkAspect.Checked then
    SyncAspectFromWidth;
end;

procedure TResizeDlg.edHeightChange(Sender: TObject);
begin
  if edHeight.Enabled and chkAspect.Checked then
    SyncAspectFromHeight;
end;

procedure TResizeDlg.chkAspectClick(Sender: TObject);
begin
  if chkAspect.Checked then
    SyncAspectFromWidth;
end;

end.
