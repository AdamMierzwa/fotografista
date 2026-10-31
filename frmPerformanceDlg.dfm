object PerformanceDlg: TPerformanceDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Performance'
  ClientHeight = 210
  ClientWidth = 380
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object rgMaxResolution: TRadioGroup
    Left = 12
    Top = 12
    Width = 356
    Height = 115
    Caption = 'Downscale photos on opening to:'
    TabOrder = 0
  end
  object rgUndoLimit: TRadioGroup
    Left = 12
    Top = 138
    Width = 356
    Height = 115
    Caption = 'Undo steps:'
    TabOrder = 1
  end
  object chkUseGPU: TCheckBox
    Left = 24
    Top = 262
    Width = 300
    Height = 17
    Caption = 'Use the graphics card where possible'
    TabOrder = 2
    OnClick = chkUseGPUClick
  end
  object lblGPUInfo: TLabel
    Left = 40
    Top = 282
    Width = 300
    Height = 15
    Caption = ''
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 192
    Top = 176
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 284
    Top = 176
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
