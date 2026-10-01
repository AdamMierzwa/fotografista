object StraightenDlg: TStraightenDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Straighten scan'
  ClientHeight = 370
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object imgPreview: TImage
    Left = 10
    Top = 10
    Width = 400
    Height = 300
    Center = True
  end
  object lblAngle: TLabel
    Left = 10
    Top = 320
    Width = 210
    Height = 15
    Caption = 'Straightening angle (-10 to +10 degrees):'
    StyleElements = [seClient, seBorder]
  end
  object tbAngle: TTrackBar
    Left = 10
    Top = 340
    Width = 400
    Height = 33
    Max = 10
    Min = -10
    Frequency = 2
    Position = 0
    TabOrder = 0
    OnChange = tbAngleChange
  end
  object lblAngleValue: TLabel
    Left = 160
    Top = 376
    Width = 100
    Height = 18
    Alignment = taCenter
    AutoSize = False
    Caption = '0°'
    StyleElements = [seClient, seBorder]
  end
  object btnOK: TButton
    Left = 214
    Top = 400
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 308
    Top = 400
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
