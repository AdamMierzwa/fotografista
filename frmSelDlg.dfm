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
  object btnProtect: TSpeedButton
    Left = 14
    Top = 72
    Width = 85
    Height = 25
    Caption = 'Protect selection'
    OnClick = btnProtectClick
  end
  object btnUnprotect: TSpeedButton
    Left = 106
    Top = 72
    Width = 85
    Height = 25
    Caption = 'Unprotect'
    OnClick = btnUnprotectClick
  end
  object btnProtToSel: TButton
    Left = 14
    Top = 100
    Width = 85
    Height = 25
    Caption = 'Select protected area'
    TabOrder = 5
    Visible = False
    OnClick = btnProtToSelClick
  end
  object chkShowProt: TCheckBox
    Left = 14
    Top = 104
    Width = 180
    Height = 17
    Caption = 'Show protection mask'
    TabOrder = 6
    OnClick = chkShowProtClick
  end
  object btnClearProt: TSpeedButton
    Left = 14
    Top = 126
    Width = 85
    Height = 25
    Caption = 'Clear protection mask'
    OnClick = btnClearProtClick
  end
  object btnDeselect: TSpeedButton
    Left = 14
    Top = 72
    Width = 85
    Height = 25
    Caption = 'Deselect'
    OnClick = btnDeselectClick
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
    TabOrder = 8
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