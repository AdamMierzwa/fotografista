unit frmSelSizeDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, uTitleBar;

type
  TSelSizeDlg = class(TFotoForm)
    lblWidth: TLabel;
    lblHeight: TLabel;
    edtWidth: TEdit;
    edtHeight: TEdit;
    btnOK: TButton;
    btnCancel: TButton;
    procedure edtWidthKeyPress(Sender: TObject; var Key: Char);
    procedure edtHeightKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
  public
    SelW, SelH: Integer;
    procedure RefitButtons; override;
  end;

function ShowSelSizeDlg(var W, H: Integer): Boolean;

implementation

{$R *.dfm}

function ShowSelSizeDlg(var W, H: Integer): Boolean;
var
  Dlg: TSelSizeDlg;
begin
  Dlg := TSelSizeDlg.Create(Application);
  try
    Dlg.SelW := W;
    Dlg.SelH := H;
    Result := Dlg.ShowModal = mrOk;
    { Wartosci z pol, nie SelW/SelH: te ustawia tylko Enter w KeyPress,
      a btnOK (ModalResult = mrOk) zamyka okno bez ich aktualizacji. }
    if Result then
    begin
      W := StrToIntDef(Dlg.edtWidth.Text, 0);
      H := StrToIntDef(Dlg.edtHeight.Text, 0);
    end;
  finally
    Dlg.Free;
  end;
end;

// Uklad z zawartosci (2026-10-21; wczesniej sztywne 300x160 i pola na stalym
// Top = 38 - przy 12 pt etykieta wchodzila na pole). Dwie kolumny: etykieta,
// pod nia pole; szerokosc kolumny z dluzszej etykiety (min. na 6 cyfr);
// OK/Anuluj do prawej. Odstepy z czcionki, bez stalych w pikselach.
procedure TSelSizeDlg.RefitButtons;
var
  Margin, ColW: Integer;
begin
  inherited;
  Margin := CtrlGap * 3;
  ColW := Max(Canvas.TextWidth(lblWidth.Caption), Canvas.TextWidth(lblHeight.Caption));
  ColW := Max(ColW, Canvas.TextWidth('000000') + CtrlGap * 4);

  lblWidth.Left := Margin;
  lblWidth.Top := Margin;
  edtWidth.SetBounds(Margin, lblWidth.Top + Canvas.TextHeight('Wg') + CtrlGap,
    ColW, edtWidth.Height);

  lblHeight.Left := Margin + ColW + SectionGap;
  lblHeight.Top := lblWidth.Top;
  edtHeight.SetBounds(lblHeight.Left, edtWidth.Top, ColW, edtHeight.Height);

  btnOK.Top := edtWidth.Top + edtWidth.Height + SectionGap;
  btnCancel.Top := btnOK.Top;
  FitToContent(SectionGap, Margin);
  // okno co najmniej na pare przyciskow
  if ClientWidth < btnOK.Width + btnCancel.Width + CtrlGap * 2 + Margin * 2 then
    ClientWidth := btnOK.Width + btnCancel.Width + CtrlGap * 2 + Margin * 2;
  AlignButtonsRight([btnOK, btnCancel], Margin);
end;

procedure TSelSizeDlg.FormShow(Sender: TObject);
begin
  edtWidth.Text := IntToStr(SelW);
  edtHeight.Text := IntToStr(SelH);
  edtWidth.SelectAll;
  edtWidth.SetFocus;
end;

procedure TSelSizeDlg.edtWidthKeyPress(Sender: TObject; var Key: Char);
begin
  if not CharInSet(Key, ['0'..'9', #8, #9, #13, #27]) then
    Key := #0
  else if Key = #13 then
  begin
    SelW := StrToIntDef(edtWidth.Text, 1);
    SelH := StrToIntDef(edtHeight.Text, 1);
    if (SelW > 0) and (SelH > 0) then
      ModalResult := mrOk;
  end;
end;

procedure TSelSizeDlg.edtHeightKeyPress(Sender: TObject; var Key: Char);
begin
  if not CharInSet(Key, ['0'..'9', #8, #9, #13, #27]) then
    Key := #0
  else if Key = #13 then
  begin
    SelW := StrToIntDef(edtWidth.Text, 1);
    SelH := StrToIntDef(edtHeight.Text, 1);
    if (SelW > 0) and (SelH > 0) then
      ModalResult := mrOk;
  end;
end;

end.
