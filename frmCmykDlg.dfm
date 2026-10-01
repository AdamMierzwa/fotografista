object CmykDlg: TCmykDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'CMYK misregistration'
  ClientHeight = 530
  ClientWidth = 430
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poMainFormCenter
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
  object lblC: TLabel
    Left = 15
    Top = 333
    Width = 26
    Height = 15
    Caption = 'C:'
    StyleElements = [seClient, seBorder]
  end
  object tbC: TTrackBar
    Left = 50
    Top = 325
    Width = 365
    Height = 30
    Max = 100
    Position = 50
    TabOrder = 0
    OnChange = tbCChange
  end
  object lblCVal: TLabel
    Left = 50
    Top = 358
    Width = 365
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object lblM: TLabel
    Left = 15
    Top = 388
    Width = 28
    Height = 15
    Caption = 'M:'
    StyleElements = [seClient, seBorder]
  end
  object tbM: TTrackBar
    Left = 50
    Top = 380
    Width = 365
    Height = 30
    Max = 100
    Position = 50
    TabOrder = 1
    OnChange = tbMChange
  end
  object lblMVal: TLabel
    Left = 50
    Top = 413
    Width = 365
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object lblY: TLabel
    Left = 15
    Top = 443
    Width = 25
    Height = 15
    Caption = 'Y (px):'
    StyleElements = [seClient, seBorder]
  end
  object tbY: TTrackBar
    Left = 50
    Top = 435
    Width = 365
    Height = 30
    Max = 100
    Position = 50
    TabOrder = 2
    OnChange = tbYChange
  end
  object lblYVal: TLabel
    Left = 50
    Top = 468
    Width = 365
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 495
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 331
    Top = 495
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
