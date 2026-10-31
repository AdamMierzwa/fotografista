object UsunTloDlg: TUsunTloDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Remove background'
  ClientHeight = 560
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
    OnPaint = pboxPreviewPaint
  end
  object lblCorner: TLabel
    Left = 15
    Top = 331
    Width = 200
    Height = 15
    Caption = 'Corner from which to remove background:'
    StyleElements = [seClient, seBorder]
  end
  object rgCorner: TRadioGroup
    Left = 15
    Top = 350
    Width = 400
    Height = 96
    Columns = 2
    TabOrder = 0
    OnClick = rgCornerClick
  end
  object chkSample: TCheckBox
    Left = 15
    Top = 450
    Width = 400
    Height = 17
    Caption = 'Sample away from the corner'
    TabOrder = 1
    OnClick = chkSampleClick
  end
  object lblDistance: TLabel
    Left = 15
    Top = 470
    Width = 60
    Height = 15
    Caption = 'Distance:'
    Enabled = False
    StyleElements = [seClient, seBorder]
  end
  object tbDistance: TTrackBar
    Left = 15
    Top = 489
    Width = 400
    Height = 25
    Enabled = False
    Max = 25
    Min = 1
    Position = 5
    TabOrder = 2
    OnChange = tbDistanceChange
  end
  object lblDistValue: TLabel
    Left = 15
    Top = 517
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '5%'
    Enabled = False
    StyleElements = [seClient, seBorder]
  end
  object lblTolerance: TLabel
    Left = 15
    Top = 460
    Width = 60
    Height = 15
    Caption = 'Tolerance'
    StyleElements = [seClient, seBorder]
  end
  object tbTolerance: TTrackBar
    Left = 15
    Top = 479
    Width = 400
    Height = 25
    Max = 100
    Min = 0
    Position = 32
    TabOrder = 3
    OnChange = tbToleranceChange
  end
  object lblTolValue: TLabel
    Left = 15
    Top = 507
    Width = 400
    Height = 18
    AutoSize = False
    Alignment = taCenter
    Caption = '32'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 240
    Top = 540
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object btnCancel: TButton
    Left = 331
    Top = 540
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
end