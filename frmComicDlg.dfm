object ComicDlg: TComicDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Comic'
  ClientHeight = 666
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
    Height = 300
    OnMouseMove = pboxPreviewMouseMove
    OnPaint = pboxPreviewPaint
  end
  object pboxZoom: TPaintBox
    Left = 445
    Top = 15
    Width = 400
    Height = 300
    OnPaint = pboxZoomPaint
  end
  object lblColors: TLabel
    Left = 15
    Top = 429
    Width = 45
    Height = 15
    Caption = 'Colors'
    StyleElements = [seClient, seBorder]
  end
  object tbColors: TTrackBar
    Left = 15
    Top = 446
    Width = 400
    Height = 25
    Max = 16
    Min = 2
    Position = 8
    TabOrder = 1
    OnChange = tbColorsChange
  end
  object lblCValue: TLabel
    Left = 15
    Top = 474
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '8'
    StyleElements = [seClient, seBorder]
  end
  object rgStyle: TRadioGroup
    Left = 15
    Top = 331
    Width = 400
    Height = 92
    Caption = 'Style'
    Columns = 2
    TabOrder = 0
    OnClick = rgStyleClick
  end
  object rgAccent: TRadioGroup
    Left = 445
    Top = 331
    Width = 400
    Height = 92
    Caption = 'Ink color'
    Columns = 2
    TabOrder = 6
    OnClick = rgAccentClick
  end
  object lblEdge: TLabel
    Left = 15
    Top = 498
    Width = 133
    Height = 15
    Caption = 'Edge sensitivity:'
    StyleElements = [seClient, seBorder]
  end
  object tbEdge: TTrackBar
    Left = 15
    Top = 515
    Width = 400
    Height = 25
    Max = 100
    Min = 1
    Position = 50
    TabOrder = 2
    OnChange = tbEdgeChange
  end
  object lblEValue: TLabel
    Left = 15
    Top = 543
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object lblThick: TLabel
    Left = 15
    Top = 567
    Width = 133
    Height = 15
    Caption = 'Thickness'
    StyleElements = [seClient, seBorder]
  end
  object tbThick: TTrackBar
    Left = 15
    Top = 584
    Width = 400
    Height = 25
    Max = 100
    Min = 1
    Position = 50
    TabOrder = 3
    OnChange = tbThickChange
  end
  object lblTValue: TLabel
    Left = 15
    Top = 612
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '50'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 641
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object btnCancel: TButton
    Left = 331
    Top = 641
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
end
