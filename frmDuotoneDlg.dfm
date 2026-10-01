object DuotoneDlg: TDuotoneDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Duotone'
  ClientHeight = 494
  ClientWidth = 430
  Color = clBtnFace
  ParentFont = True
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pboxPreview: TPaintBox
    Left = 15
    Top = 15
    Width = 400
    Height = 300
    OnPaint = pboxPreviewPaint
  end
  object sw1: TShape
    Left = 15
    Top = 330
    Width = 24
    Height = 24
    Brush.Color = clBlack
    Pen.Style = psClear
  end
  object sw2: TShape
    Left = 187
    Top = 330
    Width = 24
    Height = 24
    Pen.Style = psClear
  end
  object sw3: TShape
    Left = 15
    Top = 362
    Width = 24
    Height = 24
    Brush.Color = clGray
    Pen.Style = psClear
    Visible = False
  end
  object sw4: TShape
    Left = 187
    Top = 362
    Width = 24
    Height = 24
    Pen.Style = psClear
    Visible = False
  end
  object btnColor1: TButton
    Left = 43
    Top = 330
    Width = 130
    Height = 25
    Caption = 'Color 1 (shadows):'
    TabOrder = 0
    OnClick = btnColor1Click
    Constraints.MinWidth = 130
  end
  object btnColor2: TButton
    Left = 215
    Top = 330
    Width = 130
    Height = 25
    Caption = 'Color 2 (midtones):'
    TabOrder = 1
    OnClick = btnColor2Click
    Constraints.MinWidth = 130
  end
  object btnColor3: TButton
    Left = 43
    Top = 362
    Width = 130
    Height = 25
    Caption = 'Color 3 (highlights):'
    TabOrder = 2
    Visible = False
    OnClick = btnColor3Click
    Constraints.MinWidth = 130
  end
  object btnColor4: TButton
    Left = 215
    Top = 362
    Width = 130
    Height = 25
    Caption = 'Color 4 (extreme highlights):'
    TabOrder = 3
    Visible = False
    OnClick = btnColor4Click
    Constraints.MinWidth = 130
  end
  object btnOK: TButton
    Left = 240
    Top = 460
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object btnCancel: TButton
    Left = 331
    Top = 460
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
  object btnSavePreset: TButton
    Left = 15
    Top = 396
    Width = 400
    Height = 25
    Caption = 'Save preset'
    TabOrder = 6
    OnClick = btnSavePresetClick
  end
  object btnLoadPreset: TButton
    Left = 15
    Top = 428
    Width = 400
    Height = 25
    Caption = 'Load preset'
    TabOrder = 7
    OnClick = btnLoadPresetClick
  end
end
