object WatermarkDlg: TWatermarkDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Watermark'
  ClientHeight = 520
  ClientWidth = 720
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
    Left = 300
    Top = 12
    Width = 400
    Height = 300
    OnPaint = pboxPreviewPaint
  end
  object lblLogoFile: TLabel
    Left = 120
    Top = 150
    Width = 160
    Height = 15
    AutoSize = False
    Caption = ''
    StyleElements = [seClient, seBorder]
  end
  object lblPosition: TLabel
    Left = 12
    Top = 190
    Width = 50
    Height = 15
    Caption = 'Position:'
    StyleElements = [seClient, seBorder]
  end
  object lblSize: TLabel
    Left = 12
    Top = 320
    Width = 30
    Height = 15
    Caption = 'Size:'
    StyleElements = [seClient, seBorder]
  end
  object lblSizeVal: TLabel
    Left = 240
    Top = 340
    Width = 40
    Height = 18
    Alignment = taRightJustify
    AutoSize = False
    Caption = '5%'
    StyleElements = [seClient, seBorder]
  end
  object lblMargin: TLabel
    Left = 12
    Top = 370
    Width = 45
    Height = 15
    Caption = 'Margin:'
    StyleElements = [seClient, seBorder]
  end
  object lblMarginVal: TLabel
    Left = 240
    Top = 390
    Width = 40
    Height = 18
    Alignment = taRightJustify
    AutoSize = False
    Caption = '3%'
    StyleElements = [seClient, seBorder]
  end
  object lblOpacity: TLabel
    Left = 12
    Top = 420
    Width = 50
    Height = 15
    Caption = 'Opacity:'
    StyleElements = [seClient, seBorder]
  end
  object lblOpacityVal: TLabel
    Left = 240
    Top = 440
    Width = 40
    Height = 18
    Alignment = taRightJustify
    AutoSize = False
    Caption = '60%'
    StyleElements = [seClient, seBorder]
  end
  object rbText: TRadioButton
    Left = 12
    Top = 12
    Width = 200
    Height = 19
    Caption = 'Text'
    Checked = True
    TabOrder = 0
    TabStop = True
    OnClick = ControlChanged
  end
  object edText: TEdit
    Left = 24
    Top = 36
    Width = 256
    Height = 23
    TabOrder = 1
    OnChange = ControlChanged
  end
  object btnFont: TButton
    Left = 24
    Top = 66
    Width = 85
    Height = 25
    Caption = 'Font...'
    TabOrder = 2
    OnClick = btnFontClick
  end
  object btnColor: TButton
    Left = 116
    Top = 66
    Width = 85
    Height = 25
    Caption = 'Text color...'
    TabOrder = 3
    OnClick = btnColorClick
  end
  object chkShadow: TCheckBox
    Left = 24
    Top = 98
    Width = 200
    Height = 19
    Caption = 'Shadow under text'
    TabOrder = 4
    OnClick = ControlChanged
  end
  object rbLogo: TRadioButton
    Left = 12
    Top = 124
    Width = 200
    Height = 19
    Caption = 'Logo (PNG image)'
    TabOrder = 5
    OnClick = ControlChanged
  end
  object btnBrowse: TButton
    Left = 24
    Top = 146
    Width = 85
    Height = 25
    Caption = 'Browse...'
    TabOrder = 6
    OnClick = btnBrowseClick
  end
  object pnlAnchor: TPanel
    Left = 24
    Top = 210
    Width = 75
    Height = 75
    BevelOuter = bvNone
    TabOrder = 7
  end
  object chkTiled: TCheckBox
    Left = 12
    Top = 292
    Width = 250
    Height = 19
    Caption = 'Repeat across the whole photo'
    TabOrder = 8
    OnClick = ControlChanged
  end
  object tbSize: TTrackBar
    Left = 12
    Top = 338
    Width = 220
    Height = 25
    Max = 30
    Min = 1
    Position = 5
    TabOrder = 9
    OnChange = ControlChanged
  end
  object tbMargin: TTrackBar
    Left = 12
    Top = 388
    Width = 220
    Height = 25
    Max = 20
    Position = 3
    TabOrder = 10
    OnChange = ControlChanged
  end
  object tbOpacity: TTrackBar
    Left = 12
    Top = 438
    Width = 220
    Height = 25
    Max = 100
    Min = 10
    Position = 60
    TabOrder = 11
    OnChange = ControlChanged
  end
  object btnOK: TButton
    Left = 540
    Top = 480
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 12
  end
  object btnCancel: TButton
    Left = 632
    Top = 480
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 13
  end
end
