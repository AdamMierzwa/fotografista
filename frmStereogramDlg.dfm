object StereogramDlg: TStereogramDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Stereogram'
  ClientHeight = 410
  ClientWidth = 620
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
    Left = 225
    Top = 15
    Width = 380
    Height = 380
    OnPaint = pboxPreviewPaint
  end
  object rgMode: TRadioGroup
    Left = 15
    Top = 15
    Width = 200
    Height = 70
    Caption = 'Output mode:'
    Items.Strings = (
      'Autostereogram (SIRDS)'
      'Anaglyph (red-cyan glasses)')
    ItemIndex = 0
    TabOrder = 0
    OnClick = rgModeClick
  end
  object lblPeriod: TLabel
    Left = 15
    Top = 96
    Width = 73
    Height = 15
    Caption = 'Period (px):'
    StyleElements = [seClient, seBorder]
  end
  object lblPeriodVal: TLabel
    Left = 180
    Top = 96
    Width = 35
    Height = 15
    Alignment = taCenter
    AutoSize = True
    Caption = '64'
    StyleElements = [seClient, seBorder]
  end
  object tbPeriod: TTrackBar
    Left = 15
    Top = 113
    Width = 200
    Height = 25
    Min = 40
    Max = 100
    Frequency = 1
    Position = 64
    TabOrder = 1
    OnChange = tbPeriodChange
  end
  object lblDepth: TLabel
    Left = 15
    Top = 144
    Width = 67
    Height = 15
    Caption = 'Depth (px):'
    StyleElements = [seClient, seBorder]
  end
  object lblDepthVal: TLabel
    Left = 180
    Top = 144
    Width = 35
    Height = 15
    Alignment = taCenter
    AutoSize = True
    Caption = '12'
    StyleElements = [seClient, seBorder]
  end
  object tbDepth: TTrackBar
    Left = 15
    Top = 161
    Width = 200
    Height = 25
    Min = 0
    Max = 30
    Frequency = 1
    Position = 12
    TabOrder = 2
    OnChange = tbDepthChange
  end
  object chkRandomSeed: TCheckBox
    Left = 15
    Top = 192
    Width = 130
    Height = 17
    Caption = 'Random seed'
    Checked = True
    State = cbChecked
    TabOrder = 3
    OnClick = chkRandomSeedClick
  end
  object edSeed: TEdit
    Left = 140
    Top = 189
    Width = 75
    Height = 23
    Enabled = False
    TabOrder = 4
    Text = '0'
  end
  object btnOK: TButton
    Left = 15
    Top = 360
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 5
  end
  object btnCancel: TButton
    Left = 106
    Top = 360
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
  end
end
