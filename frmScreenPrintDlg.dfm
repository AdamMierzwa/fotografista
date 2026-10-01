object ScreenPrintDlg: TScreenPrintDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Screen print'
  ClientHeight = 520
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
    Left = 430
    Top = 15
    Width = 400
    Height = 300
    OnPaint = pboxZoomPaint
  end
  object swInk: TShape
    Left = 15
    Top = 330
    Width = 24
    Height = 24
    Brush.Color = clBlack
    Pen.Style = psClear
    Shape = stRectangle
  end
  object btnInk: TButton
    Left = 43
    Top = 330
    Width = 180
    Height = 25
    Caption = 'Ink color'
    TabOrder = 0
    OnClick = btnInkClick
  end
  object swPaper: TShape
    Left = 15
    Top = 365
    Width = 24
    Height = 24
    Brush.Color = clCream
    Pen.Style = psClear
    Shape = stRectangle
  end
  object btnPaper: TButton
    Left = 43
    Top = 365
    Width = 180
    Height = 25
    Caption = 'Paper color'
    TabOrder = 1
    OnClick = btnPaperClick
  end
  object lblThresh: TLabel
    Left = 15
    Top = 405
    Width = 169
    Height = 15
    Caption = 'Ink amount (lighter = less):'
    StyleElements = [seClient, seBorder]
  end
  object tbThresh: TTrackBar
    Left = 15
    Top = 424
    Width = 400
    Height = 25
    Max = 128
    Min = -128
    Position = 0
    TabOrder = 2
    OnChange = tbThreshChange
  end
  object lblThreshVal: TLabel
    Left = 15
    Top = 453
    Width = 400
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '0'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 490
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 331
    Top = 490
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
