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
      Width = 105
      Height = 15
      Caption = 'Width (px):'
      StyleElements = [seClient, seBorder]
    end
    object edWidth: TEdit
      Left = 132
      Top = 5
      Width = 70
      Height = 23
      TabOrder = 0
    end
    object lblHeight: TLabel
      Left = 14
      Top = 36
      Width = 105
      Height = 15
      Caption = 'Height (px):'
      StyleElements = [seClient, seBorder]
    end
    object edHeight: TEdit
      Left = 132
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
      Left = 241
      Top = 8
      Width = 85
      Height = 25
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
    object btnOK: TButton
      Left = 150
      Top = 8
      Width = 85
      Height = 25
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
  end
end
