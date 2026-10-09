object PerspectiveDlg: TPerspectiveDlg
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Perspective correction'
  ClientHeight = 420
  ClientWidth = 700
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = True
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pboxSrc: TPaintBox
    Left = 12
    Top = 12
    Width = 340
    Height = 300
    OnMouseDown = pboxSrcMouseDown
    OnMouseMove = pboxSrcMouseMove
    OnMouseUp = pboxSrcMouseUp
    OnPaint = pboxSrcPaint
  end
  object pboxDst: TPaintBox
    Left = 368
    Top = 12
    Width = 340
    Height = 300
    OnPaint = pboxDstPaint
  end
  object lblHint: TLabel
    Left = 12
    Top = 322
    Width = 696
    Height = 30
    AutoSize = False
    Caption = 'Drag the four corners onto the rectangle edges'
    StyleElements = [seClient, seBorder]
    WordWrap = True
  end
  object btnOK: TButton
    Left = 528
    Top = 372
    Width = 85
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object btnCancel: TButton
    Left = 620
    Top = 372
    Width = 85
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
end
