object GameBoyDlg: TGameBoyDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Game Boy — DMG / Pocket'
  ClientHeight = 456
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
  object rgPal: TRadioGroup
    Left = 15
    Top = 331
    Width = 400
    Height = 45
    Caption = 'Palette:'
    Columns = 2
    Items.Strings = (
      'DMG (green)'
      'Pocket (gray)')
    ItemIndex = 0
    TabOrder = 0
    OnClick = rgPalClick
  end
  object rgDither: TRadioGroup
    Left = 15
    Top = 386
    Width = 400
    Height = 45
    Caption = 'Dithering'
    Columns = 2
    Items.Strings = (
      'Enabled'
      'Disabled')
    ItemIndex = 0
    TabOrder = 1
    OnClick = rgDitherClick
  end
  object btnOK: TButton
    Left = 240
    Top = 431
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 331
    Top = 431
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
