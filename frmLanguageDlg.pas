unit frmLanguageDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls,
  uI18n, uTitleBar;

type
  TLanguageDlg = class(TFotoForm)
    grpLanguage: TGroupBox;
    btnOK: TButton;
    btnCancel: TButton;
  private
    FRadios: array of TRadioButton;   // po jednym na jezyk, kolejnosc = TLanguage
  public
    procedure RefitButtons; override;
  end;

function ShowLanguageDlg(var ALang: TLanguage): Boolean;

implementation

{$R *.dfm}

function ShowLanguageDlg(var ALang: TLanguage): Boolean;
var
  Dlg: TLanguageDlg;
  I: Integer;
begin
  Result := False;
  Dlg := TLanguageDlg.Create(Application);
  try
    SetLength(Dlg.FRadios, Ord(High(cLanguageKeys)) + 1);
    for I := 0 to High(Dlg.FRadios) do
    begin
      Dlg.FRadios[I] := TRadioButton.Create(Dlg);
      Dlg.FRadios[I].Parent := Dlg.grpLanguage;
      Dlg.FRadios[I].Caption := T(cLanguageKeys[TLanguage(I)]);
      Dlg.FRadios[I].TabOrder := I;
      Dlg.FRadios[I].Checked := I = Ord(ALang);
    end;
    if Dlg.ShowModal = mrOk then
      for I := 0 to High(Dlg.FRadios) do
        if Dlg.FRadios[I].Checked then
        begin
          ALang := TLanguage(I);
          Result := True;
          Break;
        end;
  finally
    Dlg.Free;
  end;
end;

// Uklad z zawartosci (2026-10-21; wczesniej sztywne 280x320 i TRadioGroup,
// ktora dzieli cala wysokosc miedzy pozycje i zawsze rezerwuje pas na tytul u
// gory - Vcl.ExtCtrls.pas:6389-6393 - wiec nie dalo sie uzyskac rownych
// marginesow). TGroupBox bez tytulu rysuje ramke od samej gory
// (Vcl.StdCtrls.pas:2232), przelaczniki rozmieszczane tutaj: margines u gory
// = margines u dolu, szerokosc z najdluzszej widocznej nazwy. Wszystko z
// czcionki (CtrlGap/RowGap/TextHeight), bez stalych w pikselach.
procedure TLanguageDlg.RefitButtons;
var
  I, W, Y, TH, ItemH, Pad, Check, Margin: Integer;
begin
  inherited;
  Margin := CtrlGap * 3;
  TH := Canvas.TextHeight('Wg');
  ItemH := TH + RowGap * 2;
  Pad := RowGap * 2;
  Check := GetSystemMetrics(SM_CXMENUCHECK) + CtrlGap * 2;
  W := 0;
  for I := 0 to High(FRadios) do
    W := Max(W, Canvas.TextWidth(FRadios[I].Caption));
  Y := Pad;
  for I := 0 to High(FRadios) do
  begin
    FRadios[I].SetBounds(Margin, Y, Check + W, ItemH);
    Inc(Y, ItemH);
  end;
  grpLanguage.SetBounds(Margin, Margin, Margin + Check + W + Margin, Y + Pad);
  btnOK.Top := grpLanguage.Top + grpLanguage.Height + SectionGap;
  btnCancel.Top := btnOK.Top;
  FitToContent(SectionGap, Margin);
  // okno co najmniej na pare przyciskow
  if ClientWidth < btnOK.Width + btnCancel.Width + CtrlGap * 2 + Margin * 2 then
    ClientWidth := btnOK.Width + btnCancel.Width + CtrlGap * 2 + Margin * 2;
  // ramka na cala szerokosc okna (rowny margines z obu stron), gdy okno
  // poszerzyla para przyciskow
  grpLanguage.Width := ClientWidth - Margin * 2;
  AlignButtonsRight([btnOK, btnCancel], Margin);
end;

end.
