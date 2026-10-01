object StippleDlg: TStippleDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Stipple'
  ClientHeight = 470
  ClientWidth = 604
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
    Width = 220
    Height = 220
    OnMouseMove = pboxPreviewMouseMove
    OnPaint = pboxPreviewPaint
  end
  object pboxZoom: TPaintBox
    Left = 249
    Top = 15
    Width = 340
    Height = 220
    OnPaint = pboxZoomPaint
  end
  object lblDot: TLabel
    Left = 15
    Top = 251
    Width = 163
    Height = 15
    Caption = 'Dot sub-cell size (3-8 px):'
    StyleElements = [seClient, seBorder]
  end
  object tbDot: TTrackBar
    Left = 15
    Top = 270
    Width = 574
    Height = 25
    Min = 3
    Max = 8
    Position = 5
    TabOrder = 0
    OnChange = tbDotChange
  end
  object lblDotVal: TLabel
    Left = 15
    Top = 299
    Width = 574
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '5'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 432
    Top = 360
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 523
    Top = 360
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
