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
      NumbersOnly = True
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
      NumbersOnly = True
    end
    object btnFullHD: TButton
      Left = 216
      Top = 5
      Width = 130
      Height = 51
      Caption = 'Full HD 1920×1080'
      TabOrder = 2
      OnClick = btnFullHDClick
    end
    object grpTile: TGroupBox
      Left = 14
      Top = 64
      Width = 220
      Height = 100
      Caption = 'Tile size'
      TabOrder = 3
      object rbTileOrig: TRadioButton
        Left = 8
        Top = 20
        Width = 150
        Height = 19
        Caption = 'Original'
        TabOrder = 0
        OnClick = rbTileClick
      end
      object rbTileScale: TRadioButton
        Left = 8
        Top = 44
        Width = 150
        Height = 19
        Caption = 'Scale (%):'
        TabOrder = 1
        OnClick = rbTileClick
      end
      object edTileScale: TEdit
        Left = 160
        Top = 42
        Width = 50
        Height = 23
        TabOrder = 2
        NumbersOnly = True
      end
      object rbTileCount: TRadioButton
        Left = 8
        Top = 70
        Width = 150
        Height = 19
        Caption = 'Tiles horizontally:'
        TabOrder = 3
        OnClick = rbTileClick
      end
      object edTileCount: TEdit
        Left = 160
        Top = 68
        Width = 50
        Height = 23
        TabOrder = 4
        NumbersOnly = True
      end
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
