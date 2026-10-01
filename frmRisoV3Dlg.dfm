object RisoV3Dlg: TRisoV3Dlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Risograph v3'
  ClientHeight = 500
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
  object lblLayers: TLabel
    Left = 15
    Top = 17
    Width = 79
    Height = 15
    Caption = 'Number of layers:'
    StyleElements = [seClient, seBorder]
  end
  object cmbLayers: TComboBox
    Left = 100
    Top = 13
    Width = 60
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 0
    OnChange = cmbLayersChange
  end
  object sw0: TShape
    Left = 15
    Top = 47
    Width = 24
    Height = 24
    Brush.Color = clMaroon
    Pen.Style = psClear
    Shape = stRectangle
  end
  object btnColor0: TButton
    Left = 43
    Top = 46
    Width = 130
    Height = 25
    Caption = 'Layer 1...'
    TabOrder = 1
    OnClick = btnColor0Click
  end
  object lblRgb0: TLabel
    Left = 180
    Top = 51
    Width = 140
    Height = 15
    Caption = 'R=200 G=55 B=70'
    StyleElements = [seClient, seBorder]
  end
  object sw1: TShape
    Left = 15
    Top = 82
    Width = 24
    Height = 24
    Brush.Color = clBlack
    Pen.Style = psClear
    Shape = stRectangle
  end
  object btnColor1: TButton
    Left = 43
    Top = 81
    Width = 130
    Height = 25
    Caption = 'Layer 2...'
    TabOrder = 2
    OnClick = btnColor1Click
  end
  object lblRgb1: TLabel
    Left = 180
    Top = 86
    Width = 140
    Height = 15
    Caption = 'R=30 G=30 B=35'
    StyleElements = [seClient, seBorder]
  end
  object sw2: TShape
    Left = 15
    Top = 117
    Width = 24
    Height = 24
    Brush.Color = clOlive
    Pen.Style = psClear
    Shape = stRectangle
  end
  object btnColor2: TButton
    Left = 43
    Top = 116
    Width = 130
    Height = 25
    Caption = 'Layer 3...'
    TabOrder = 3
    OnClick = btnColor2Click
  end
  object lblRgb2: TLabel
    Left = 180
    Top = 121
    Width = 140
    Height = 15
    Caption = 'R=240 G=200 B=20'
    StyleElements = [seClient, seBorder]
  end
  object sw3: TShape
    Left = 15
    Top = 152
    Width = 24
    Height = 24
    Brush.Color = clTeal
    Pen.Style = psClear
    Shape = stRectangle
  end
  object btnColor3: TButton
    Left = 43
    Top = 151
    Width = 130
    Height = 25
    Caption = 'Layer 4...'
    TabOrder = 4
    OnClick = btnColor3Click
  end
  object lblRgb3: TLabel
    Left = 180
    Top = 156
    Width = 140
    Height = 15
    Caption = 'R=0 G=165 B=195'
    StyleElements = [seClient, seBorder]
  end
  object sw4: TShape
    Left = 15
    Top = 187
    Width = 24
    Height = 24
    Brush.Color = clGreen
    Pen.Style = psClear
    Shape = stRectangle
  end
  object btnColor4: TButton
    Left = 43
    Top = 186
    Width = 130
    Height = 25
    Caption = 'Layer 5...'
    TabOrder = 5
    OnClick = btnColor4Click
  end
  object lblRgb4: TLabel
    Left = 180
    Top = 191
    Width = 140
    Height = 15
    Caption = 'R=70 G=170 B=80'
    StyleElements = [seClient, seBorder]
  end
  object pboxPreview: TPaintBox
    Left = 15
    Top = 220
    Width = 400
    Height = 230
    OnPaint = pboxPreviewPaint
  end
  object btnOK: TButton
    Left = 240
    Top = 465
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 6
  end
  object btnCancel: TButton
    Left = 331
    Top = 465
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 7
  end
end
