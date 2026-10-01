object TileDlg: TTileDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Tiling'
  ClientHeight = 130
  ClientWidth = 340
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poMainFormCenter
  Scaled = True
  TextHeight = 15
  object pnlInput: TPanel
    Left = 0
    Top = 0
    Width = 340
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblWidth: TLabel
      Left = 14
      Top = 8
      Width = 83
      Height = 15
      Caption = 'Width (px):'
      StyleElements = [seClient, seBorder]
    end
    object edWidth: TEdit
      Left = 110
      Top = 5
      Width = 70
      Height = 23
      TabOrder = 0
    end
    object lblHeight: TLabel
      Left = 14
      Top = 36
      Width = 79
      Height = 15
      Caption = 'Height (px):'
      StyleElements = [seClient, seBorder]
    end
    object edHeight: TEdit
      Left = 110
      Top = 33
      Width = 70
      Height = 23
      TabOrder = 1
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 90
    Width = 340
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    Padding.Left = 8
    Padding.Top = 8
    Padding.Right = 8
    Padding.Bottom = 8
    object btnCancel: TButton
      Left = 154
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
      Left = 239
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
