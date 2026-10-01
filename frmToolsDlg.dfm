object ToolsDlg: TToolsDlg
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Retouch'
  ClientHeight = 190
  ClientWidth = 250
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
  object cmbTool: TComboBox
    Left = 44
    Top = 8
    Width = 110
    Height = 23
    Style = csDropDownList
    TabOrder = 0
    OnChange = cmbToolChange
  end
  object rbErase: TRadioButton
    Left = 12
    Top = 46
    Width = 90
    Height = 17
    Caption = 'Erase'
    Checked = True
    TabOrder = 1
    TabStop = True
    OnClick = rbModeClick
  end
  object rbRestore: TRadioButton
    Left = 150
    Top = 46
    Width = 90
    Height = 17
    Caption = 'Restore'
    TabOrder = 3
    OnClick = rbModeClick
  end
  object lblBrushSize: TLabel
    Left = 12
    Top = 76
    Width = 60
    Height = 15
    Caption = 'Brush size:'
    StyleElements = [seClient, seBorder]
  end
  object tbrBrush: TTrackBar
    Left = 12
    Top = 94
    Width = 170
    Height = 25
    Max = 100
    Min = 1
    Position = 10
    TabOrder = 4
    OnChange = tbrBrushChange
  end
  object lblBrushVal: TLabel
    Left = 188
    Top = 96
    Width = 24
    Height = 15
    Alignment = taCenter
    AutoSize = True
    Caption = '10'
    StyleElements = [seClient, seBorder]
  end
  object lblStrength: TLabel
    Left = 12
    Top = 122
    Width = 47
    Height = 15
    Caption = 'Strength'
    StyleElements = [seClient, seBorder]
  end
  object tbrStrength: TTrackBar
    Left = 12
    Top = 140
    Width = 170
    Height = 25
    Max = 100
    Min = 0
    Position = 100
    TabOrder = 5
    OnChange = tbrStrengthChange
  end
  object lblStrengthVal: TLabel
    Left = 188
    Top = 142
    Width = 24
    Height = 15
    Alignment = taCenter
    AutoSize = True
    Caption = '100'
    StyleElements = [seClient, seBorder]
  end
  object lblTolerance: TLabel
    Left = 12
    Top = 168
    Width = 53
    Height = 15
    Caption = 'Tolerance'
    StyleElements = [seClient, seBorder]
  end
  object tbrTolerance: TTrackBar
    Left = 12
    Top = 186
    Width = 170
    Height = 25
    Max = 100
    Position = 20
    TabOrder = 6
    OnChange = tbrToleranceChange
  end
  object lblToleranceVal: TLabel
    Left = 188
    Top = 188
    Width = 24
    Height = 15
    Alignment = taCenter
    AutoSize = True
    Caption = '20'
    StyleElements = [seClient, seBorder]
  end
  object lblColor: TLabel
    Left = 12
    Top = 168
    Width = 51
    Height = 15
    Caption = 'Fill color'
    StyleElements = [seClient, seBorder]
  end
  object pboxColor: TShape
    Left = 12
    Top = 186
    Width = 24
    Height = 24
    Brush.Color = clBlack
    Pen.Color = clGrayText
  end
  object btnColorChoose: TButton
    Left = 44
    Top = 186
    Width = 90
    Height = 25
    Caption = 'Choose...'
    TabOrder = 7
    OnClick = btnColorChooseClick
  end
  object lblColor2: TLabel
    Left = 12
    Top = 218
    Width = 109
    Height = 15
    Caption = 'Replacement color'
    StyleElements = [seClient, seBorder]
  end
  object pboxColor2: TShape
    Left = 12
    Top = 236
    Width = 24
    Height = 24
    Brush.Color = clYellow
    Pen.Color = clGrayText
  end
  object btnColorChoose2: TButton
    Left = 44
    Top = 236
    Width = 90
    Height = 25
    Caption = 'Choose...'
    TabOrder = 8
    OnClick = btnColorChoose2Click
  end
  object chkRetainShading: TCheckBox
    Left = 12
    Top = 268
    Width = 130
    Height = 17
    Caption = 'Retain shading'
    Checked = True
    TabOrder = 9
    OnClick = chkRetainShadingClick
  end
end