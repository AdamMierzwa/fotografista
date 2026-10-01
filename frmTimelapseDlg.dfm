object TimelapseDlg: TTimelapseDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Timelapse'
  ClientHeight = 380
  ClientWidth = 470
  Color = clBtnFace
  ParentFont = True
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  DesignSize = (
    470
    380)
  TextHeight = 15
  object lblSrc: TLabel
    Left = 15
    Top = 20
    Width = 73
    Height = 15
    Caption = 'Source folder:'
    StyleElements = [seClient, seBorder]
  end
  object lblSrcPath: TLabel
    Left = 140
    Top = 20
    Width = 220
    Height = 15
    AutoSize = False
    Caption = '...'
    EllipsisPosition = epPathEllipsis
    ShowAccelChar = False
    StyleElements = [seClient, seBorder]
  end
  object lblDst: TLabel
    Left = 15
    Top = 104
    Width = 75
    Height = 15
    Caption = 'Output folder:'
    StyleElements = [seClient, seBorder]
  end
  object lblDstPath: TLabel
    Left = 140
    Top = 104
    Width = 220
    Height = 15
    AutoSize = False
    Caption = '...'
    EllipsisPosition = epPathEllipsis
    ShowAccelChar = False
    StyleElements = [seClient, seBorder]
  end
  object lblFileName: TLabel
    Left = 15
    Top = 140
    Width = 66
    Height = 15
    Caption = 'File name:'
    StyleElements = [seClient, seBorder]
  end
  object lblFps: TLabel
    Left = 15
    Top = 174
    Width = 85
    Height = 15
    Caption = 'Frames per second:'
    StyleElements = [seClient, seBorder]
  end
  object lblHoldFirst: TLabel
    Left = 15
    Top = 208
    Width = 100
    Height = 15
    Caption = 'Hold first frame [s]:'
    StyleElements = [seClient, seBorder]
  end
  object lblHoldLast: TLabel
    Left = 15
    Top = 242
    Width = 95
    Height = 15
    Caption = 'Hold last frame [s]:'
    StyleElements = [seClient, seBorder]
  end
  object lblRes: TLabel
    Left = 15
    Top = 282
    Width = 92
    Height = 15
    Caption = 'Target resolution:'
    StyleElements = [seClient, seBorder]
  end
  object btnSrcChoice: TButton
    Left = 365
    Top = 16
    Width = 90
    Height = 25
    Caption = 'Choose...'
    TabOrder = 0
    OnClick = btnSrcChoiceClick
  end
  object pnlSort: TPanel
    Left = 15
    Top = 48
    Width = 170
    Height = 40
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 1
    object rbSortAlpha: TRadioButton
      Left = 0
      Top = 0
      Width = 170
      Height = 17
      Caption = 'Alphabetically'
      Checked = True
      TabOrder = 0
      TabStop = True
    end
    object rbSortDate: TRadioButton
      Left = 0
      Top = 21
      Width = 170
      Height = 17
      Caption = 'By creation date'
      TabOrder = 1
    end
  end
  object btnDstChoice: TButton
    Left = 365
    Top = 100
    Width = 90
    Height = 25
    Caption = 'Choose...'
    TabOrder = 2
    OnClick = btnDstChoiceClick
  end
  object edFileName: TEdit
    Left = 140
    Top = 136
    Width = 220
    Height = 23
    TabOrder = 3
    Text = 'timelapse.mp4'
  end
  object edFps: TEdit
    Left = 200
    Top = 170
    Width = 60
    Height = 23
    TabOrder = 4
    Text = '25'
  end
  object edHoldFirst: TEdit
    Left = 200
    Top = 204
    Width = 60
    Height = 23
    TabOrder = 5
    Text = '0'
  end
  object edHoldLast: TEdit
    Left = 200
    Top = 238
    Width = 60
    Height = 23
    TabOrder = 6
    Text = '0'
  end
  object cmbRes: TComboBox
    Left = 140
    Top = 278
    Width = 180
    Height = 23
    Style = csDropDownList
    TabOrder = 7
  end
  object pnlMode: TPanel
    Left = 15
    Top = 280
    Width = 180
    Height = 40
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 8
    object rbSave: TRadioButton
      Left = 0
      Top = 0
      Width = 180
      Height = 17
      Caption = 'Save to file'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = rbSaveClick
    end
    object rbPresent: TRadioButton
      Left = 0
      Top = 21
      Width = 180
      Height = 17
      Caption = 'Show as presentation'
      TabOrder = 1
      OnClick = rbPresentClick
    end
  end
  object pnlView: TPanel
    Left = 15
    Top = 320
    Width = 180
    Height = 40
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 9
    Visible = False
    object rbWindow: TRadioButton
      Left = 0
      Top = 0
      Width = 180
      Height = 17
      Caption = 'In window'
      TabOrder = 0
    end
    object rbFullscreen: TRadioButton
      Left = 0
      Top = 21
      Width = 180
      Height = 17
      Caption = 'Full screen'
      Checked = True
      TabOrder = 1
      TabStop = True
    end
  end
  object btnStart: TButton
    Left = 15
    Top = 374
    Width = 85
    Height = 25
    Caption = 'Start'
    TabOrder = 10
    OnClick = btnStartClick
  end
  object btnClose: TButton
    Left = 370
    Top = 374
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Close'
    TabOrder = 11
    OnClick = btnCloseClick
  end
end