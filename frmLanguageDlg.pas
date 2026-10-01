unit frmLanguageDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls,
  uI18n, uTitleBar;

type
  TLanguageDlg = class(TFotoForm)
    rgLanguage: TRadioGroup;
    btnOK: TButton;
    btnCancel: TButton;
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
    for I := 0 to Ord(High(cLanguageKeys)) do
      Dlg.rgLanguage.Items.Add(T(cLanguageKeys[TLanguage(I)]));
    if Ord(ALang) <= Ord(High(cLanguageKeys)) then
      Dlg.rgLanguage.ItemIndex := Ord(ALang);
    if Dlg.ShowModal = mrOk then
    begin
      if (Dlg.rgLanguage.ItemIndex >= 0) and
        (Dlg.rgLanguage.ItemIndex <= Ord(High(cLanguageKeys))) then
      begin
        ALang := TLanguage(Dlg.rgLanguage.ItemIndex);
        Result := True;
      end;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
