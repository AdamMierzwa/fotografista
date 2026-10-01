object AmigaBGDlg: TAmigaBGDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Amiga background'
  ClientHeight = 170
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
  object lblColor: TLabel
    Left = 15
    Top = 65
    Width = 142
    Height = 15
    Caption = 'Background color (MagicWB palette):'
    StyleElements = [seClient, seBorder]
  end
  object cbColor: TComboBox
    Left = 15
    Top = 82
    Width = 400
    Height = 23
    Style = csDropDownList
    TabOrder = 1
  end
  object btnCustomColor: TButton
    Left = 15
    Top = 115
    Width = 110
    Height = 25
    Caption = 'Other color...'
    TabOrder = 2
    OnClick = btnCustomColorClick
  end
  object btnOK: TButton
    Left = 240
    Top = 135
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 331
    Top = 135
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
