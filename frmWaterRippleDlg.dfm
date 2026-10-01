object WaterRippleDlg: TWaterRippleDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Water ripple'
  ClientHeight = 490
  ClientWidth = 700
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
  object pnlPreview: TPanel
    Left = 15
    Top = 15
    Width = 400
    Height = 420
    BevelOuter = bvNone
    ParentBackground = True
    TabOrder = 0
    object pboxPreview: TPaintBox
      Left = 0
      Top = 0
      Width = 370
      Height = 300
      OnPaint = pboxPreviewPaint
    end
    object lbPresets: TListBox
      Left = 0
      Top = 315
      Width = 370
      Height = 72
      TabOrder = 0
      OnClick = lbPresetsClick
    end
  end
  object pnlSliders: TPanel
    Left = 430
    Top = 15
    Width = 255
    Height = 170
    BevelOuter = bvNone
    ParentBackground = True
    TabOrder = 1
    object lblStrength: TLabel
      Left = 15
      Top = 15
      Width = 46
      Height = 15
      Caption = 'Strength'
      StyleElements = [seClient, seBorder]
    end
    object trkStrength: TTrackBar
      Left = 15
      Top = 35
      Width = 225
      Height = 25
      Max = 300
      Position = 100
      TabOrder = 0
      OnChange = trkSliderChange
    end
    object lblStrengthVal: TLabel
      Left = 15
      Top = 62
      Width = 225
      Height = 18
      Alignment = taCenter
      AutoSize = False
      Caption = '100'
      StyleElements = [seClient, seBorder]
    end
    object lblDensity: TLabel
      Left = 15
      Top = 90
      Width = 77
      Height = 15
      Caption = 'Wave density'
      StyleElements = [seClient, seBorder]
    end
    object trkDensity: TTrackBar
      Left = 15
      Top = 110
      Width = 225
      Height = 25
      Max = 400
      Min = 25
      Position = 100
      TabOrder = 1
      OnChange = trkSliderChange
    end
    object lblDensityVal: TLabel
      Left = 15
      Top = 137
      Width = 225
      Height = 18
      Alignment = taCenter
      AutoSize = False
      Caption = '100'
      StyleElements = [seClient, seBorder]
    end
  end
  object btnOK: TButton
    Left = 510
    Top = 205
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 605
    Top = 205
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
