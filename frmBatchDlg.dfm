object BatchDlg: TBatchDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Batch processing'
  ClientHeight = 225
  ClientWidth = 470
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poOwnerFormCenter
  TextHeight = 15
  object lblSrc: TLabel
    Left = 15
    Top = 22
    Width = 105
    Height = 15
    Caption = 'Source folder:'
    StyleElements = [seClient, seBorder]
  end
  object lblDst: TLabel
    Left = 15
    Top = 58
    Width = 107
    Height = 15
    Caption = 'Destination folder:'
    StyleElements = [seClient, seBorder]
  end
  object lblMacro: TLabel
    Left = 15
    Top = 94
    Width = 38
    Height = 15
    Caption = 'Macro:'
    StyleElements = [seClient, seBorder]
  end
  object edSrc: TEdit
    Left = 130
    Top = 19
    Width = 230
    Height = 23
    TabOrder = 0
  end
  object btnSrc: TButton
    Left = 370
    Top = 17
    Width = 85
    Height = 25
    Caption = 'Choose...'
    TabOrder = 1
    OnClick = btnSrcClick
  end
  object edDst: TEdit
    Left = 130
    Top = 55
    Width = 230
    Height = 23
    TabOrder = 2
  end
  object btnDst: TButton
    Left = 370
    Top = 53
    Width = 85
    Height = 25
    Caption = 'Choose...'
    TabOrder = 3
    OnClick = btnDstClick
  end
  object cbMacro: TComboBox
    Left = 130
    Top = 91
    Width = 325
    Height = 23
    Style = csDropDownList
    TabOrder = 4
  end
  object chkNoMacro: TCheckBox
    Left = 130
    Top = 122
    Width = 200
    Height = 17
    Caption = 'Without running the macro'
    TabOrder = 5
  end
  object chkScale: TCheckBox
    Left = 130
    Top = 150
    Width = 200
    Height = 17
    Caption = 'Scale to long side, px:'
    TabOrder = 6
    OnClick = chkScaleClick
  end
  object edEdge: TEdit
    Left = 336
    Top = 147
    Width = 60
    Height = 23
    TabOrder = 7
    Text = '1920'
  end
  object btnStart: TButton
    Left = 300
    Top = 190
    Width = 85
    Height = 25
    Caption = 'Start'
    Default = True
    TabOrder = 8
    OnClick = btnStartClick
  end
  object btnClose: TButton
    Left = 385
    Top = 190
    Width = 85
    Height = 25
    Caption = 'Close'
    TabOrder = 9
    OnClick = btnCloseClick
  end
end
