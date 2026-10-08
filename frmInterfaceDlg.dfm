object InterfaceDlg: TInterfaceDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Interface'
  ClientHeight = 484
  ClientWidth = 340
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
  object lblCanvasBG: TLabel
    Left = 16
    Top = 16
    Width = 300
    Height = 48
    AutoSize = False
    Caption = 'Canvas background color (only with standard Windows theme):'
    StyleElements = [seClient, seBorder]
    WordWrap = True
  end
  object lblFontSize: TLabel
    Left = 16
    Top = 148
    Width = 220
    Height = 15
    Caption = 'Interface font size (pt):'
    StyleElements = [seClient, seBorder]
  end
  object lblRecentCount: TLabel
    Left = 16
    Top = 212
    Width = 126
    Height = 15
    Caption = 'Number of recent files:'
    StyleElements = [seClient, seBorder]
  end
  object lblTheme: TLabel
    Left = 16
    Top = 276
    Width = 82
    Height = 15
    Caption = 'Choose theme:'
    StyleElements = [seClient, seBorder]
  end
  object lblBrushCursor: TLabel
    Left = 16
    Top = 340
    Width = 90
    Height = 15
    Caption = 'Brush cursor:'
    StyleElements = [seClient, seBorder]
  end
  object btnCanvasBG: TButton
    Left = 16
    Top = 72
    Width = 160
    Height = 25
    Caption = 'Choose color...'
    TabOrder = 0
    OnClick = btnCanvasBGClick
  end
  object chkRememberWin: TCheckBox
    Left = 16
    Top = 108
    Width = 300
    Height = 17
    Caption = 'Remember window size and position'
    TabOrder = 1
  end
  object spinFontSize: TSpinEdit
    Left = 16
    Top = 172
    Width = 80
    Height = 24
    MaxValue = 12
    MinValue = 8
    TabOrder = 2
    Value = 9
    OnChange = spinFontSizeChange
  end
  object spinRecentCount: TSpinEdit
    Left = 16
    Top = 236
    Width = 80
    Height = 24
    MaxValue = 20
    MinValue = 0
    TabOrder = 3
    Value = 5
  end
  object cmbTheme: TComboBox
    Left = 16
    Top = 300
    Width = 224
    Height = 23
    AutoDropDownWidth = True
    Style = csDropDownList
    TabOrder = 4
  end
  object cmbBrushCursor: TComboBox
    Left = 16
    Top = 364
    Width = 224
    Height = 23
    AutoDropDownWidth = True
    Style = csDropDownList
    TabOrder = 5
    OnChange = cmbBrushCursorChange
  end
  object chkBrushCrosshairCenter: TCheckBox
    Left = 16
    Top = 398
    Width = 300
    Height = 17
    Caption = 'Show crosshair in brush outline'
    TabOrder = 6
  end
  object btnOK: TButton
    Left = 150
    Top = 440
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 7
  end
  object btnCancel: TButton
    Left = 242
    Top = 440
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 8
  end
end
