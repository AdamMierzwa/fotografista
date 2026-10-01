object ResizeDlg: TResizeDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Resize'
  ClientHeight = 280
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poMainFormCenter
  Scaled = True
  TextHeight = 15
  object pnlRadio: TPanel
    Left = 0
    Top = 0
    Width = 420
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblMethod: TLabel
      Left = 14
      Top = 2
      Width = 76
      Height = 15
      Caption = 'Scaling method:'
      StyleElements = [seClient, seBorder]
    end
    object rbManual: TRadioButton
      Left = 14
      Top = 22
      Width = 80
      Height = 17
      Caption = 'Manual'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = rbManualClick
    end
    object rbAutoPct: TRadioButton
      Left = 100
      Top = 22
      Width = 220
      Height = 17
      Caption = 'Automatic'
      TabOrder = 1
      OnClick = rbAutoPctClick
    end
  end
  object pnlInput: TPanel
    Left = 0
    Top = 50
    Width = 420
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object lblWidth: TLabel
      Left = 14
      Top = 6
      Width = 83
      Height = 15
      Caption = 'Width (px):'
      StyleElements = [seClient, seBorder]
    end
    object edWidth: TEdit
      Left = 110
      Top = 3
      Width = 80
      Height = 23
      TabOrder = 0
      OnChange = edWidthChange
    end
    object lblHeight: TLabel
      Left = 14
      Top = 34
      Width = 79
      Height = 15
      Caption = 'Height (px):'
      StyleElements = [seClient, seBorder]
    end
    object edHeight: TEdit
      Left = 110
      Top = 31
      Width = 80
      Height = 23
      TabOrder = 1
      OnChange = edHeightChange
    end
  end
  object chkAspect: TCheckBox
    Left = 14
    Top = 114
    Width = 200
    Height = 17
    Caption = 'Keep aspect ratio'
    TabOrder = 2
    OnClick = chkAspectClick
  end
  object lblPercent: TLabel
    Left = 14
    Top = 138
    Width = 50
    Height = 15
    Caption = 'Scale (%):'
    StyleElements = [seClient, seBorder]
  end
  object tbPercent: TTrackBar
    Left = 14
    Top = 158
    Width = 390
    Height = 33
    Enabled = False
    Max = 500
    Min = 1
    Frequency = 25
    Position = 100
    TabOrder = 3
    OnChange = tbPercentChange
  end
  object lblPctValue: TLabel
    Left = 170
    Top = 194
    Width = 60
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '100%'
    StyleElements = [seClient, seBorder]
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 230
    Width = 420
    Height = 36
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    Padding.Left = 8
    Padding.Top = 8
    Padding.Right = 8
    Padding.Bottom = 8
    object btnCancel: TButton
      Left = 232
      Top = 6
      Width = 85
      Height = 25
      Align = alRight
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 0
    end
    object btnOK: TButton
      Left = 317
      Top = 6
      Width = 85
      Height = 25
      Align = alRight
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 1
    end
  end
end
