object LauncherDlg: TLauncherDlg
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Launcher'
  ClientHeight = 230
  ClientWidth = 172
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
  OnCreate = FormCreate
  TextHeight = 15
  object ToolBar: TToolBar
    Left = 0
    Top = 0
    Width = 172
    Height = 29
    AutoSize = True
    BorderWidth = 1
    EdgeBorders = [ebBottom]
    TabOrder = 0
    object sbOpen: TSpeedButton
      Left = 2
      Top = 2
      Width = 24
      Height = 24
      Hint = 'Open an image file'
      Flat = True
      OnClick = sbOpenClick
    end
    object sbSave: TSpeedButton
      Left = 27
      Top = 2
      Width = 24
      Height = 24
      Hint = 'Save image under a new name'
      Flat = True
      OnClick = sbSaveClick
    end
    object sbCopy: TSpeedButton
      Left = 52
      Top = 2
      Width = 24
      Height = 24
      Hint = 'Copy image to clipboard'
      Flat = True
      OnClick = sbCopyClick
    end
    object sbPaste: TSpeedButton
      Left = 77
      Top = 2
      Width = 24
      Height = 24
      Hint = 'Paste image from clipboard as new layer'
      Flat = True
      OnClick = sbPasteClick
    end
    object sbMacro: TSpeedButton
      Left = 102
      Top = 2
      Width = 24
      Height = 24
      Hint = 'Play, rename or delete macros'
      Flat = True
      OnClick = sbMacroClick
    end
    object sbCompare: TSpeedButton
      Left = 127
      Top = 2
      Width = 24
      Height = 24
      Hint = 'Export image comparison — side-by-side with original'
      Flat = True
      OnClick = sbCompareClick
    end
  end
  object grpZoom: TGroupBox
    Left = 6
    Top = 40
    Width = 160
    Height = 74
    Caption = 'Zoom'
    TabOrder = 1
    object btnZoomOut: TButton
      Left = 8
      Top = 18
      Width = 28
      Height = 25
      Caption = '-'
      TabOrder = 0
      OnClick = btnZoomOutClick
    end
    object lblZoom: TLabel
      Left = 42
      Top = 23
      Width = 76
      Height = 18
      Alignment = taCenter
      AutoSize = False
      Caption = '100%'
      StyleElements = [seClient, seBorder]
    end
    object btnZoomIn: TButton
      Left = 124
      Top = 18
      Width = 28
      Height = 25
      Caption = '+'
      TabOrder = 1
      OnClick = btnZoomInClick
    end
    object btnZoomFit: TButton
      Left = 8
      Top = 44
      Height = 25
      Caption = 'Fit to window'
      Constraints.MinWidth = 144
      TabOrder = 2
      OnClick = btnZoomFitClick
    end
  end
  object grpEdit: TGroupBox
    Left = 6
    Top = 130
    Width = 160
    Height = 88
    Caption = 'Edit'
    TabOrder = 2
    object btnUndo: TButton
      Left = 8
      Top = 18
      Height = 25
      Caption = 'Undo'
      Constraints.MinWidth = 144
      TabOrder = 0
      OnClick = btnUndoClick
    end
    object btnRevert: TButton
      Left = 8
      Top = 48
      Height = 25
      Caption = 'Restore original'
      Constraints.MinWidth = 144
      TabOrder = 1
      OnClick = btnRevertClick
    end
  end
  object Timer: TTimer
    Interval = 250
    OnTimer = TimerTimer
    Left = 160
    Top = 120
  end
end
