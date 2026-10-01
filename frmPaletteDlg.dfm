object PaletteDlg: TPaletteDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Palette'
  ClientHeight = 410
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
  object rgDither: TRadioGroup
    Left = 15
    Top = 331
    Width = 400
    Height = 65
    Caption = 'Dithering'
    Columns = 1
    Items.Strings = (
      'Enabled'
      'Disabled')
    ItemIndex = 0
    TabOrder = 0
  end
  object btnOK: TButton
    Left = 240
    Top = 391
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 331
    Top = 391
    Width = 85
    Height = 25
    Caption = 'Cancel'
    Cancel = True
    ModalResult = 2
    TabOrder = 2
  end
end
