object LanguageDlg: TLanguageDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Language'
  ClientHeight = 320
  ClientWidth = 280
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poMainFormCenter
  TextHeight = 15
  object rgLanguage: TRadioGroup
    Left = 15
    Top = 15
    Width = 250
    Height = 265
    TabOrder = 0
  end
  object btnOK: TButton
    Left = 70
    Top = 290
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 165
    Top = 290
    Width = 85
    Height = 25
    Caption = 'Cancel'
    Cancel = True
    ModalResult = 2
    TabOrder = 2
  end
end
