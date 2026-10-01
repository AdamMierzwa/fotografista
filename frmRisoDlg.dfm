object RisoDlg: TRisoDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Risograph'
  ClientHeight = 465
  ClientWidth = 640
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
  object lstPalettes: TListBox
    Left = 15
    Top = 15
    Width = 230
    Height = 395
    ItemHeight = 15
    TabOrder = 0
    OnClick = lstPalettesClick
  end
  object pboxPreview: TPaintBox
    Left = 260
    Top = 15
    Width = 365
    Height = 395
    OnPaint = pboxPreviewPaint
  end
  object btnOK: TButton
    Left = 450
    Top = 430
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 541
    Top = 430
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
