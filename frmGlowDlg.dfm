object GlowDlg: TGlowDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Glow'
  ClientHeight = 430
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
  object lblRadius: TLabel
    Left = 15
    Top = 331
    Width = 101
    Height = 15
    Caption = 'Glow radius (1-20):'
    StyleElements = [seClient, seBorder]
  end
  object lblValue: TLabel
    Left = 15
    Top = 378
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '5'
    StyleElements = [seClient, seBorder]
  end
  object tbRadius: TTrackBar
    Left = 15
    Top = 350
    Width = 400
    Height = 25
    Max = 20
    Min = 1
    Position = 5
    TabOrder = 0
    OnChange = tbRadiusChange
  end
  object btnOK: TButton
    Left = 240
    Top = 400
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 331
    Top = 400
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
