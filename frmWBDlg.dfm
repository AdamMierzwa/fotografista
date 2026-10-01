object WBDlg: TWBDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'White balance'
  ClientHeight = 560
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
    Cursor = crCross
    Hint = 'Click the preview to set the white point'
    ShowHint = True
    OnMouseDown = pboxPreviewMouseDown
    OnMouseLeave = pboxPreviewMouseLeave
    OnMouseMove = pboxPreviewMouseMove
    OnPaint = pboxPreviewPaint
  end
  object lblR: TLabel
    Left = 15
    Top = 331
    Width = 145
    Height = 15
    Caption = 'Red (100 = no change):'
    StyleElements = [seClient, seBorder]
  end
  object tbR: TTrackBar
    Left = 15
    Top = 348
    Width = 340
    Height = 25
    Min = 1
    Max = 300
    Position = 100
    TabOrder = 0
    OnChange = tbRChange
  end
  object lblValR: TLabel
    Left = 361
    Top = 352
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '100'
    StyleElements = [seClient, seBorder]
  end
  object lblG: TLabel
    Left = 15
    Top = 379
    Width = 130
    Height = 15
    Caption = 'Green (100 = no change):'
    StyleElements = [seClient, seBorder]
  end
  object tbG: TTrackBar
    Left = 15
    Top = 396
    Width = 340
    Height = 25
    Min = 1
    Max = 300
    Position = 100
    TabOrder = 1
    OnChange = tbGChange
  end
  object lblValG: TLabel
    Left = 361
    Top = 400
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '100'
    StyleElements = [seClient, seBorder]
  end
  object lblB: TLabel
    Left = 15
    Top = 427
    Width = 133
    Height = 15
    Caption = 'Blue (100 = no change):'
    StyleElements = [seClient, seBorder]
  end
  object tbB: TTrackBar
    Left = 15
    Top = 444
    Width = 340
    Height = 25
    Min = 1
    Max = 300
    Position = 100
    TabOrder = 2
    OnChange = tbBChange
  end
  object lblValB: TLabel
    Left = 361
    Top = 448
    Width = 48
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '100'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 510
    Width = 80
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object btnCancel: TButton
    Left = 326
    Top = 510
    Width = 80
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
end
