object QualityDlg: TQualityDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Export quality'
  ClientHeight = 437
  ClientWidth = 380
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
  object gbJPEG: TGroupBox
    Left = 12
    Top = 12
    Width = 356
    Height = 85
    Caption = 'JPEG'
    TabOrder = 0
    object lblJPGQuality: TLabel
      Left = 12
      Top = 20
      Width = 171
      Height = 15
      Caption = 'JPEG compression quality (0-100):'
      StyleElements = [seClient, seBorder]
    end
    object tbJPGQuality: TTrackBar
      Left = 12
      Top = 36
      Width = 332
      Height = 25
      Max = 100
      Position = 90
      TabOrder = 0
      OnChange = tbJPGQualityChange
    end
    object lblJPGValue: TLabel
      Left = 140
      Top = 63
      Width = 80
      Height = 18
      Alignment = taCenter
      AutoSize = False
      Caption = '90'
      StyleElements = [seClient, seBorder]
    end
  end
  object gbWebP: TGroupBox
    Left = 12
    Top = 105
    Width = 356
    Height = 85
    Caption = 'WebP'
    TabOrder = 1
    object lblWebPQuality: TLabel
      Left = 12
      Top = 20
      Width = 177
      Height = 15
      Caption = 'WebP compression quality (0-100):'
      StyleElements = [seClient, seBorder]
    end
    object tbWebPQuality: TTrackBar
      Left = 12
      Top = 36
      Width = 332
      Height = 25
      Max = 100
      Position = 90
      TabOrder = 0
      OnChange = tbWebPQualityChange
    end
    object lblWebPValue: TLabel
      Left = 140
      Top = 63
      Width = 80
      Height = 18
      Alignment = taCenter
      AutoSize = False
      Caption = '90'
      StyleElements = [seClient, seBorder]
    end
  end
  object gbTIFF: TGroupBox
    Left = 12
    Top = 198
    Width = 356
    Height = 195
    Caption = 'TIFF'
    TabOrder = 2
    object lblTIFFCompression: TLabel
      Left = 12
      Top = 16
      Width = 85
      Height = 15
      Caption = 'TIFF compression:'
      StyleElements = [seClient, seBorder]
    end
    object rbLZW: TRadioButton
      Left = 24
      Top = 34
      Width = 310
      Height = 20
      Caption = 'LZW'
      Checked = True
      TabOrder = 0
      TabStop = True
      OnClick = rbTIFFCompressionClick
    end
    object rbNone: TRadioButton
      Left = 24
      Top = 56
      Width = 310
      Height = 20
      Caption = 'No compression'
      TabOrder = 1
      OnClick = rbTIFFCompressionClick
    end
    object rbJPEG: TRadioButton
      Left = 24
      Top = 78
      Width = 310
      Height = 20
      Caption = 'JPEG'
      TabOrder = 2
      OnClick = rbTIFFCompressionClick
    end
    object lblTIFFJPEG: TLabel
      Left = 12
      Top = 108
      Width = 121
      Height = 15
      Caption = 'JPEG quality in TIFF:'
      StyleElements = [seClient, seBorder]
      Enabled = False
    end
    object tbTIFFJPEGQuality: TTrackBar
      Left = 12
      Top = 124
      Width = 332
      Height = 25
      Enabled = False
      Max = 100
      Position = 85
      TabOrder = 3
      OnChange = tbTIFFJPEGQualityChange
    end
    object lblTIFFJPEGValue: TLabel
      Left = 140
      Top = 151
      Width = 80
      Height = 18
      Alignment = taCenter
      AutoSize = False
      Caption = '85'
      StyleElements = [seClient, seBorder]
      Enabled = False
    end
  end
  object btnOK: TButton
    Left = 192
    Top = 403
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 284
    Top = 403
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
