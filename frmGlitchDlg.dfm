object GlitchDlg: TGlitchDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Glitch'
  ClientHeight = 535
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
    Height = 200
    OnPaint = pboxPreviewPaint
  end
  object lblShift: TLabel
    Left = 15
    Top = 224
    Width = 107
    Height = 15
    Caption = 'RGB channel shift (0-30):'
    StyleElements = [seClient, seBorder]
  end
  object lblShiftVal: TLabel
    Left = 15
    Top = 268
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '0'
    StyleElements = [seClient, seBorder]
  end
  object tbShift: TTrackBar
    Left = 15
    Top = 240
    Width = 400
    Height = 25
    Max = 30
    TabOrder = 0
    OnChange = tbShiftChange
  end
  object lblJitter: TLabel
    Left = 15
    Top = 270
    Width = 106
    Height = 15
    Caption = 'Line jitter (0-100):'
    StyleElements = [seClient, seBorder]
  end
  object lblJitterVal: TLabel
    Left = 15
    Top = 314
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '0'
    StyleElements = [seClient, seBorder]
  end
  object tbJitter: TTrackBar
    Left = 15
    Top = 286
    Width = 400
    Height = 25
    Max = 100
    TabOrder = 1
    OnChange = tbJitterChange
  end
  object lblNoise: TLabel
    Left = 15
    Top = 316
    Width = 65
    Height = 15
    Caption = 'Noise (0-100):'
    StyleElements = [seClient, seBorder]
  end
  object lblNoiseVal: TLabel
    Left = 15
    Top = 360
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '0'
    StyleElements = [seClient, seBorder]
  end
  object tbNoise: TTrackBar
    Left = 15
    Top = 332
    Width = 400
    Height = 25
    Max = 100
    TabOrder = 2
    OnChange = tbNoiseChange
  end
  object lblScanlines: TLabel
    Left = 15
    Top = 362
    Width = 115
    Height = 15
    Caption = 'CRT effect (0-100):'
    StyleElements = [seClient, seBorder]
  end
  object lblScanVal: TLabel
    Left = 15
    Top = 406
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '0'
    StyleElements = [seClient, seBorder]
  end
  object tbScanlines: TTrackBar
    Left = 15
    Top = 378
    Width = 400
    Height = 25
    Max = 100
    TabOrder = 3
    OnChange = tbScanlinesChange
  end
  object lblBlock: TLabel
    Left = 15
    Top = 408
    Width = 102
    Height = 15
    Caption = 'Block loss (0-100):'
    StyleElements = [seClient, seBorder]
  end
  object lblBlockVal: TLabel
    Left = 15
    Top = 452
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '0'
    StyleElements = [seClient, seBorder]
  end
  object tbBlock: TTrackBar
    Left = 15
    Top = 424
    Width = 400
    Height = 25
    Max = 100
    TabOrder = 4
    OnChange = tbBlockChange
  end
  object lblTracking: TLabel
    Left = 15
    Top = 454
    Width = 170
    Height = 15
    Caption = 'Horizontal band shifts (0-100):'
    StyleElements = [seClient, seBorder]
  end
  object lblTrackVal: TLabel
    Left = 15
    Top = 498
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '0'
    StyleElements = [seClient, seBorder]
  end
  object tbTracking: TTrackBar
    Left = 15
    Top = 470
    Width = 400
    Height = 25
    Max = 100
    TabOrder = 5
    OnChange = tbTrackingChange
  end
  object btnOK: TButton
    Left = 240
    Top = 500
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 6
  end
  object btnCancel: TButton
    Left = 331
    Top = 500
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 7
  end
end
