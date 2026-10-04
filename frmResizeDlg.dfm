object ResizeDlg: TResizeDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Resize'
  ClientHeight = 307
  ClientWidth = 290
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poMainFormCenter
  OnCreate = FormCreate
  Scaled = True
  TextHeight = 15
  object pnlRadio: TPanel
    Left = 0
    Top = 0
    Width = 290
    Height = 56
    BevelOuter = bvNone
    TabOrder = 0
    object lblMethod: TLabel
      Left = 14
      Top = 8
      Width = 140
      Height = 15
      Caption = 'Scaling method:'
      StyleElements = [seClient, seBorder]
    end
    object rbManual: TRadioButton
      Left = 14
      Top = 37
      Width = 85
      Height = 17
      Caption = 'Manual'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = rbManualClick
    end
    object rbAutoPct: TRadioButton
      Left = 110
      Top = 37
      Width = 145
      Height = 17
      Caption = 'Automatic'
      TabOrder = 1
      OnClick = rbAutoPctClick
    end
  end
  object pnlInput: TPanel
    Left = 0
    Top = 56
    Width = 290
    Height = 62
    BevelOuter = bvNone
    TabOrder = 1
    object lblWidth: TLabel
      Left = 14
      Top = 7
      Width = 105
      Height = 15
      Caption = 'Width (px):'
      StyleElements = [seClient, seBorder]
    end
    object edWidth: TEdit
      Left = 132
      Top = 3
      Width = 80
      Height = 23
      TabOrder = 0
      OnChange = edWidthChange
    end
    object lblHeight: TLabel
      Left = 14
      Top = 40
      Width = 105
      Height = 15
      Caption = 'Height (px):'
      StyleElements = [seClient, seBorder]
    end
    object edHeight: TEdit
      Left = 132
      Top = 36
      Width = 80
      Height = 23
      TabOrder = 1
      OnChange = edHeightChange
    end
  end
  object chkAspect: TCheckBox
    Left = 14
    Top = 131
    Width = 160
    Height = 17
    Caption = 'Keep aspect ratio'
    TabOrder = 2
    OnClick = chkAspectClick
  end
  object lblPercent: TLabel
    Left = 14
    Top = 161
    Width = 95
    Height = 15
    Caption = 'Scale (%):'
    StyleElements = [seClient, seBorder]
  end
  object tbPercent: TTrackBar
    Left = 14
    Top = 189
    Width = 262
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
    Left = 115
    Top = 235
    Width = 60
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '100%'
    StyleElements = [seClient, seBorder]
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 266
    Width = 290
    Height = 41
    BevelOuter = bvNone
    TabOrder = 4
    Padding.Left = 8
    Padding.Top = 8
    Padding.Right = 8
    Padding.Bottom = 8
    object btnCancel: TButton
      Left = 191
      Top = 8
      Width = 85
      Height = 25
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
    object btnOK: TButton
      Left = 100
      Top = 8
      Width = 85
      Height = 25
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
  end
end
