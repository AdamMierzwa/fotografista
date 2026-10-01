object CrossProcessDlg: TCrossProcessDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Incorrect development'
  ClientHeight = 485
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
  OnDestroy = FormDestroy
  TextHeight = 15
  object pboxPreview: TPaintBox
    Left = 15
    Top = 15
    Width = 400
    Height = 300
    OnPaint = pboxPreviewPaint
  end
  object rgPreset: TRadioGroup
    Left = 15
    Top = 330
    Width = 400
    Height = 115
    Caption = 'Preset:'
    Columns = 2
    Items.Strings = (
      'E-6 in C-41'
      'C-41 in E-6'
      'Kodak in Fuji developer'
      'Fuji in Kodak developer'
      'ECN-2 in C-41')
    ItemIndex = 0
    TabOrder = 0
    OnClick = rgPresetClick
  end
  object btnOK: TButton
    Left = 240
    Top = 455
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 331
    Top = 455
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
