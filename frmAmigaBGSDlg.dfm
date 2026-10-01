object AmigaBGSDlg: TAmigaBGSDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Amiga background (stretched, MagicWB)'
  ClientHeight = 110
  ClientWidth = 430
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object lblRes: TLabel
    Left = 15
    Top = 15
    Width = 128
    Height = 15
    Caption = 'Target resolution:'
    StyleElements = [seClient, seBorder]
  end
  object cbRes: TComboBox
    Left = 15
    Top = 32
    Width = 400
    Height = 23
    Style = csDropDownList
    TabOrder = 0
  end
  object btnOK: TButton
    Left = 240
    Top = 75
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 331
    Top = 75
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
