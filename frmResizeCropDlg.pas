unit frmResizeCropDlg;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, uI18n, uTitleBar;

type
  TResizeCropDlg = class(TFotoForm)
    pnlTop: TPanel;
    pnlAnchor: TPanel;
    pnlBottom: TPanel;
    lblWidth: TLabel;
    edWidth: TEdit;
    lblHeight: TLabel;
    edHeight: TEdit;
    btnFullHD: TButton;
    lblAnchor: TLabel;
    rgCorner: TRadioGroup;
    btnOK: TButton;
    btnCancel: TButton;
    procedure btnFullHDClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LayoutDialog;
  end;

var
  ResizeCropSourceBmp: TBitmap = nil;

function ShowResizeCropDlg(out NewW, NewH, Corner: Integer): Boolean;

implementation

{$R *.dfm}

procedure TResizeCropDlg.FormCreate(Sender: TObject);
begin
  { Podmiana napisow musi sie odbyc przed LayoutDialog - tam sa mierzone
    szerokosci. Wzorzec: frmResizeDlg, frmStereogramDlg. }
  TranslateForm(Self);

  rgCorner.Items.Add(T('Top-left'));
  rgCorner.Items.Add(T('Bottom-left'));
  rgCorner.Items.Add(T('Top-right'));
  rgCorner.Items.Add(T('Bottom-right'));
end;

{ Jawny layout liczony z fontu, wzorzec frmResizeDlg.LayoutDialog.
  Panele nie maja Align - inaczej FitToContent mierzylby panel rozciagniety
  do ClientWidth i okno roslo by o margines przy kazdym wywolaniu. }
procedure TResizeCropDlg.LayoutDialog;
var
  Margin, ColLeft, PadT, LblColW, EditLeft, ColW, PanelW: Integer;
  ItemW, RowH, ColPitch, Cols, Rows, I: Integer;
begin
  Margin := CtrlGap * 3;
  ColLeft := Margin;
  PadT := CtrlGap * 2;

  FitButton(btnFullHD);
  FitButtonGroup([btnCancel, btnOK]);

  { TLabel ma AutoSize = True, wiec po TranslateForm jego Width jest juz
    zmierzone przez VCL - tutaj tylko czytamy. }
  LblColW := Max(lblWidth.Width, lblHeight.Width);
  EditLeft := ColLeft + LblColW + CtrlGap * 2;
  ColW := EditLeft + edWidth.Width - ColLeft;

  { TRadioGroup sam nie skaluje sie pod captiony - liczymy kolumny z fontu. }
  ItemW := 0;
  Self.Canvas.Font.Assign(rgCorner.Font);
  for I := 0 to rgCorner.Items.Count - 1 do
    if Self.Canvas.TextWidth(rgCorner.Items[I]) > ItemW then
      ItemW := Self.Canvas.TextWidth(rgCorner.Items[I]);
  Inc(ItemW, ButtonPad);
  Cols := rgCorner.Columns;
  if Cols < 1 then Cols := 1;
  RowH := Self.Canvas.TextHeight('Wg') + CtrlGap * 2;
  ColPitch := ItemW + CtrlGap * 3;
  Rows := (rgCorner.Items.Count + Cols - 1) div Cols;
  rgCorner.Width := Cols * ColPitch;
  rgCorner.Height := Rows * RowH + CtrlGap * 2;
  if rgCorner.Width > ColW then ColW := rgCorner.Width;

  PanelW := ColLeft + ColW + CtrlGap * 2 + btnFullHD.Width;

  pnlTop.Left := 0;
  pnlTop.Top := 0;
  pnlTop.Width := PanelW;
  lblWidth.Left := ColLeft;
  lblHeight.Left := ColLeft;
  edWidth.Left := EditLeft;
  edHeight.Left := EditLeft;
  edWidth.Top := PadT;
  edHeight.Top := PadT + edWidth.Height + RowGap;
  lblWidth.Top := PadT + (edWidth.Height - lblWidth.Height) div 2;
  lblHeight.Top := edHeight.Top + (edHeight.Height - lblHeight.Height) div 2;
  btnFullHD.Left := EditLeft + edWidth.Width + CtrlGap * 2;
  btnFullHD.Top := PadT;
  pnlTop.Height := StackBelow(btnFullHD, PadT);

  pnlAnchor.Left := 0;
  pnlAnchor.Top := StackBelow(pnlTop, SectionGap);
  pnlAnchor.Width := PanelW;
  lblAnchor.Left := ColLeft;
  lblAnchor.Top := PadT;
  rgCorner.Left := ColLeft;
  rgCorner.Top := StackBelow(lblAnchor, RowGap);
  pnlAnchor.Height := StackBelow(rgCorner, PadT);

  pnlBottom.Left := 0;
  pnlBottom.Top := StackBelow(pnlAnchor, SectionGap);
  pnlBottom.Width := PanelW;
  btnCancel.Top := PadT;
  btnOK.Top := PadT;
  pnlBottom.Height := StackBelow(btnOK, PadT);

  FitToContent(CtrlGap * 3, CtrlGap * 3);
  AlignButtonsRight([btnOK, btnCancel], CtrlGap * 3);
  FitHeight(CtrlGap * 3);
end;

function ShowResizeCropDlg(out NewW, NewH, Corner: Integer): Boolean;

  function VisualToCorner(Idx: Integer): Integer;
  const
    Map: array[0..3] of Integer = (0, 2, 1, 3);
  begin
    if (Idx >= Low(Map)) and (Idx <= High(Map)) then
      Result := Map[Idx]
    else
      Result := 0;
  end;

var
  Dlg: TResizeCropDlg;
begin
  Result := False;
  if ResizeCropSourceBmp = nil then Exit;
  Dlg := TResizeCropDlg.Create(Application);
  try
    Dlg.edWidth.Text := IntToStr(ResizeCropSourceBmp.Width);
    Dlg.edHeight.Text := IntToStr(ResizeCropSourceBmp.Height);
    Dlg.rgCorner.ItemIndex := 0;
    Dlg.LayoutDialog;
    Result := Dlg.ShowModal = mrOk;
    if Result then
    begin
      NewW := StrToIntDef(Dlg.edWidth.Text, ResizeCropSourceBmp.Width);
      NewH := StrToIntDef(Dlg.edHeight.Text, ResizeCropSourceBmp.Height);
      Corner := VisualToCorner(Dlg.rgCorner.ItemIndex);
      if NewW < 1 then NewW := 1;
      if NewH < 1 then NewH := 1;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TResizeCropDlg.btnFullHDClick(Sender: TObject);
begin
  edWidth.Text := '1920';
  edHeight.Text := '1080';
end;

end.
