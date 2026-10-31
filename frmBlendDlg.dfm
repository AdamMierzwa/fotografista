object BlendDlg: TBlendDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Effect Blend'
  ClientHeight = 560
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
  object lblEffectA: TLabel
    Left = 15
    Top = 327
    Width = 49
    Height = 15
    Caption = 'Effect A:'
    StyleElements = [seClient, seBorder]
  end
  object cbEffectA: TComboBox
    Left = 95
    Top = 324
    Width = 310
    Height = 23
    Style = csDropDownList
    TabOrder = 0
    OnChange = cbEffectAChange
  end
  object lblEffectB: TLabel
    Left = 15
    Top = 357
    Width = 49
    Height = 15
    Caption = 'Effect B:'
    StyleElements = [seClient, seBorder]
  end
  object cbEffectB: TComboBox
    Left = 95
    Top = 354
    Width = 310
    Height = 23
    Style = csDropDownList
    TabOrder = 1
    OnChange = cbEffectBChange
  end
  object btnSwap: TButton
    Left = 290
    Top = 384
    Width = 115
    Height = 25
    Caption = 'Swap A and B'
    TabOrder = 2
    OnClick = btnSwapClick
  end
  object lblMode: TLabel
    Left = 15
    Top = 417
    Width = 34
    Height = 15
    Caption = 'Mode:'
    StyleElements = [seClient, seBorder]
  end
  object cbMode: TComboBox
    Left = 95
    Top = 414
    Width = 310
    Height = 23
    Style = csDropDownList
    TabOrder = 3
    OnChange = cbModeChange
  end
  object lblMix: TLabel
    Left = 15
    Top = 448
    Width = 131
    Height = 15
    Caption = 'Blend (0=A, 100=B):'
    StyleElements = [seClient, seBorder]
  end
  object lblMixVal: TLabel
    Left = 15
    Top = 493
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object tbMix: TTrackBar
    Left = 15
    Top = 465
    Width = 400
    Height = 25
    Max = 100
    Position = 50
    TabOrder = 4
    OnChange = tbMixChange
  end
  object btnOK: TButton
    Left = 240
    Top = 520
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 5
  end
  object btnCancel: TButton
    Left = 331
    Top = 520
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
  end
end
