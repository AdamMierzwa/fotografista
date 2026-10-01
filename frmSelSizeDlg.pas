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
    if Result then
    begin
      W := Dlg.SelW;
      H := Dlg.SelH;
    end;
  finally
    Dlg.Free;
  end;
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
