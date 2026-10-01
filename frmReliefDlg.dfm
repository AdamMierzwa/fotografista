object ReliefDlg: TReliefDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Relief'
  ClientHeight = 475
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
  object lblMaterial: TLabel
    Left = 15
    Top = 331
    Width = 48
    Height = 15
    Caption = 'Material:'
    StyleElements = [seClient, seBorder]
  end
  object cbMaterial: TComboBox
    Left = 70
    Top = 327
    Width = 345
    Height = 23
    Style = csDropDownList
    TabOrder = 0
    OnChange = cbMaterialChange
  end
  object lblDepth: TLabel
    Left = 15
    Top = 366
    Width = 220
    Height = 15
    Caption = 'Depth (1-100):'
    StyleElements = [seClient, seBorder]
  end
  object lblDepthValue: TLabel
    Left = 15
    Top = 413
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '35'
    StyleElements = [seClient, seBorder]
  end
  object tbDepth: TTrackBar
    Left = 15
    Top = 385
    Width = 400
    Height = 25
    Min = 1
    Max = 100
    Position = 35
    TabOrder = 1
    OnChange = tbDepthChange
  end
  object btnOK: TButton
    Left = 240
    Top = 440
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 331
    Top = 440
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
