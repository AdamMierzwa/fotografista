object SelSizeDlg: TSelSizeDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Selection size'
  ClientHeight = 160
  ClientWidth = 300
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poMainFormCenter
  OnShow = FormShow
  TextHeight = 15
  object lblWidth: TLabel
    Left = 20
    Top = 20
    Width = 92
    Height = 15
    Caption = 'Width (px):'
    StyleElements = [seClient, seBorder]
  end
  object edtWidth: TEdit
    Left = 20
    Top = 38
    Width = 120
    Height = 23
    TabOrder = 0
    OnKeyPress = edtWidthKeyPress
  end
  object lblHeight: TLabel
    Left = 160
    Top = 20
    Width = 89
    Height = 15
    Caption = 'Height (px):'
    StyleElements = [seClient, seBorder]
  end
  object edtHeight: TEdit
    Left = 160
    Top = 38
    Width = 120
    Height = 23
    TabOrder = 1
    OnKeyPress = edtHeightKeyPress
  end
  object btnOK: TButton
    Left = 60
    Top = 90
    Width = 80
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 160
    Top = 90
    Width = 80
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
