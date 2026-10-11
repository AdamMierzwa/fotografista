object DiceImgDlg: TDiceImgDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Image from dice'
  ClientHeight = 470
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
  object lblCell: TLabel
    Left = 15
    Top = 331
    Caption = 'Cell size (24-64 px):'
    StyleElements = [seClient, seBorder]
  end
  object tbCell: TTrackBar
    Left = 15
    Top = 350
    Width = 400
    Height = 25
    Min = 12
    Max = 32
    Position = 16
    TabOrder = 0
    OnChange = tbCellChange
  end
  object lblCellVal: TLabel
    Left = 15
    Top = 380
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '32'
    StyleElements = [seClient, seBorder]
  end
  object lblCount: TLabel
    Left = 15
    Top = 331
    Caption = 'Number of dice:'
    StyleElements = [seClient, seBorder]
  end
  object lblCountVal: TLabel
    Left = 15
    Top = 349
    Width = 400
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '0'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 380
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 331
    Top = 380
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
