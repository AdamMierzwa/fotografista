object frmShortcutsDlg: TfrmShortcutsDlg
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Keyboard shortcuts'
  ClientHeight = 300
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object btnOK: TButton
    Left = 303
    Top = 263
    Width = 85
    Height = 25
    Caption = 'Close'
    Default = True
    Cancel = True
    TabOrder = 0
    OnClick = btnOKClick
  end
end
