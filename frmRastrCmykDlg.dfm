object RastrCmykDlg: TRastrCmykDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Raster CMYK...'
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
    Left = 15
    Top = 15
    Width = 400
    Height = 300
    OnPaint = pboxZoomPaint
  end
  object lblGrid: TLabel
    Left = 15
    Top = 330
    Width = 169
    Height = 15
    Caption = 'Cell size (1-32 px):'
    StyleElements = [seClient, seBorder]
  end
  object tbGrid: TTrackBar
    Left = 15
    Top = 348
    Width = 400
    Height = 25
    Max = 32
    Min = 1
    Position = 8
    TabOrder = 0
    OnChange = tbGridChange
  end
  object lblGridVal: TLabel
    Left = 15
    Top = 376
    Width = 400
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '8'
    StyleElements = [seClient, seBorder]
  end
  object lblScale: TLabel
    Left = 15
    Top = 402
    Width = 169
    Height = 15
    Caption = 'Dot scale [%]:'
    StyleElements = [seClient, seBorder]
  end
  object tbScale: TTrackBar
    Left = 15
    Top = 420
    Width = 400
    Height = 25
    Max = 300
    Min = 25
    Position = 100
    TabOrder = 1
    OnChange = tbScaleChange
  end
  object lblScaleVal: TLabel
    Left = 15
    Top = 448
    Width = 400
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '100 %'
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
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 331
    Top = 490
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end