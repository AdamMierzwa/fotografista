object SelDlg: TSelDlg
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Selection'
  ClientHeight = 168
  ClientWidth = 280
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  FormStyle = fsStayOnTop
  Position = poMainFormCenter
  ShowHint = True
  OnClose = FormClose
  OnShow = FormShow
  TextHeight = 15
  object cmbSelShape: TComboBox
    Left = 86
    Top = 8
    Width = 182
    Height = 23
    Style = csDropDownList
    TabOrder = 0
    OnChange = cmbSelShapeChange
  end
  object rbSelOutline: TRadioButton
    Left = 14
    Top = 46
    Width = 90
    Height = 17
    Caption = 'Outline'
    Checked = True
    TabOrder = 1
    TabStop = True
    OnClick = rbSelOutlineClick
  end
  object rbSelMask: TRadioButton
    Left = 118
    Top = 46
    Width = 90
    Height = 17
    Caption = 'Mask'
    TabOrder = 2
    OnClick = rbSelMaskClick
  end
  object lblSelTol: TLabel
    Left = 14
    Top = 80
    Width = 53
    Height = 15
    Caption = 'Tolerance'
    StyleElements = [seClient, seBorder]
  end
  object tbrSelTol: TTrackBar
    Left = 14
    Top = 98
    Width = 170
    Height = 25
    Max = 100
    Position = 20
    TabOrder = 3
OnChange = tbrSelTolChange
      OnKeyUp = tbrSelTolKeyUp
  end
  object lblSelTolVal: TLabel
    Left = 190
    Top = 100
    Width = 22
    Height = 15
    Alignment = taCenter
    AutoSize = True
    Caption = '20'
    StyleElements = [seClient, seBorder]
  end
end