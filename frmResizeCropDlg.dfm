object ResizeCropDlg: TResizeCropDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Fit to size with crop'
  ClientHeight = 280
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poMainFormCenter
  Scaled = True
  OnCreate = FormCreate
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 420
    Height = 90
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblWidth: TLabel
      Left = 14
      Top = 10
      Width = 83
      Height = 15
      Caption = 'Width (px):'
      StyleElements = [seClient, seBorder]
    end
    object edWidth: TEdit
      Left = 110
      Top = 7
      Width = 70
      Height = 23
      TabOrder = 0
    end
    object lblHeight: TLabel
      Left = 14
      Top = 38
      Width = 79
      Height = 15
      Caption = 'Height (px):'
      StyleElements = [seClient, seBorder]
    end
    object edHeight: TEdit
      Left = 110
      Top = 35
      Width = 70
      Height = 23
      TabOrder = 1
    end
    object btnFullHD: TButton
      Left = 200
      Top = 7
      Width = 130
      Height = 50
      Caption = 'Full HD 1920×1080'
      TabOrder = 2
      OnClick = btnFullHDClick
      Constraints.MinWidth = 130
    end
  end
  object pnlAnchor: TPanel
    Left = 0
    Top = 90
    Width = 420
    Height = 140
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object lblAnchor: TLabel
      Left = 14
      Top = 8
      Width = 75
      Height = 15
      Caption = 'Anchor:'
      StyleElements = [seClient, seBorder]
    end
    object rgCorner: TRadioGroup
      Left = 14
      Top = 28
      Width = 220
      Height = 100
      Columns = 2
      TabOrder = 0
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 240
    Width = 420
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    Padding.Left = 8
    Padding.Top = 8
    Padding.Right = 8
    Padding.Bottom = 8
    object btnCancel: TButton
      Left = 234
      Top = 8
      Width = 85
      Height = 25
      Align = alRight
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 0
    end
    object btnOK: TButton
      Left = 319
      Top = 8
      Width = 85
      Height = 25
      Align = alRight
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 1
    end
  end
end
