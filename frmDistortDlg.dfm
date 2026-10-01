object DistortDlg: TDistortDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Distort'
  ClientHeight = 455
  ClientWidth = 700
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pboxPreview: TPaintBox
    Left = 15
    Top = 15
    Width = 370
    Height = 300
    OnPaint = pboxPreviewPaint
  end
  object lbPresets: TListBox
    Left = 15
    Top = 330
    Width = 370
    Height = 110
    TabOrder = 0
    OnClick = lbPresetsClick
  end
  object btnOK: TButton
    Left = 510
    Top = 415
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TButton
    Left = 605
    Top = 415
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
