unit frmPaletteDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  uI18n, uPreviewFit, uTitleBar;

type
  TApplyPaletteProc = procedure(Bitmap: TBitmap; Dither: Boolean);

  TPaletteDlg = class(TFotoForm)
    pboxPreview: TPaintBox;
    rgDither: TRadioGroup;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure rgDitherClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FApplyProc: TApplyPaletteProc;
    procedure ApplyPreview;
  end;

function ShowPaletteDlg(const ATitle: string; Bitmap: TBitmap;
  ApplyProc: TApplyPaletteProc; out UseDither: Boolean): Boolean;

implementation

{$R *.dfm}

procedure TPaletteDlg.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to rgDither.Items.Count - 1 do
    rgDither.Items[I] := T(rgDither.Items[I]);
  rgDither.ItemIndex := 0;
  rgDither.OnClick := rgDitherClick;
end;

procedure TPaletteDlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

procedure TPaletteDlg.rgDitherClick(Sender: TObject);
begin
  ApplyPreview;
end;

procedure TPaletteDlg.ApplyPreview;
begin
  if not Assigned(FOriginalPreview) then Exit;
  FWorkingPreview.Assign(FOriginalPreview);
  // ApplyProc changes pixel format to palette — ignore errors on preview
  try
    FApplyProc(FWorkingPreview, rgDither.ItemIndex = 0);
  except
  end;
  pboxPreview.Invalidate;
end;

procedure TPaletteDlg.pboxPreviewPaint(Sender: TObject);
var
  SrcW, SrcH, NewW, NewH, TargetW, TargetH: Integer;
  Scale: Double;
  DestRect: TRect;
begin
  with pboxPreview.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxPreview.ClientRect);
    if Assigned(FWorkingPreview) and (FWorkingPreview.Width > 0) then
    begin
      SrcW := FWorkingPreview.Width;
      SrcH := FWorkingPreview.Height;
      TargetW := pboxPreview.ClientWidth;
      TargetH := pboxPreview.ClientHeight;
      Scale := Min(TargetW / SrcW, TargetH / SrcH);
      NewW := Round(SrcW * Scale);
      NewH := Round(SrcH * Scale);
      DestRect := Rect(
        (TargetW - NewW) div 2, (TargetH - NewH) div 2,
        (TargetW - NewW) div 2 + NewW, (TargetH - NewH) div 2 + NewH);
      StretchDraw(DestRect, FWorkingPreview);
    end;
  end;
end;

function ShowPaletteDlg(const ATitle: string; Bitmap: TBitmap;
  ApplyProc: TApplyPaletteProc; out UseDither: Boolean): Boolean;
var
  Dlg: TPaletteDlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
begin
  Result := False;
  UseDither := True;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TPaletteDlg.Create(Application);
  try
    Dlg.Caption := ATitle;

    Scale := Min(400.0 / Bitmap.Width, 400.0 / Bitmap.Height);
    if Scale > 1.0 then Scale := 1.0;
    pw := Max(1, Round(Bitmap.Width * Scale));
    ph := Max(1, Round(Bitmap.Height * Scale));

    Scaled := TBitmap.Create;
    try
      Scaled.PixelFormat := pf24bit;
      Scaled.SetSize(pw, ph);
      Scaled.Canvas.StretchDraw(Rect(0, 0, pw, ph), Bitmap);

      Dlg.FOriginalPreview := TBitmap.Create;
      Dlg.FOriginalPreview.PixelFormat := pf24bit;
      Dlg.FOriginalPreview.SetSize(pw, ph);
      Dlg.FOriginalPreview.Canvas.Draw(0, 0, Scaled);

      Dlg.FWorkingPreview := TBitmap.Create;
      Dlg.FWorkingPreview.PixelFormat := pf24bit;
      Dlg.FWorkingPreview.SetSize(pw, ph);
    finally
      Scaled.Free;
    end;

    FitPreviewToDialog(Dlg, Dlg.pboxPreview, pw, ph);

    Dlg.rgDither.ItemIndex := 0;
    Dlg.FApplyProc := ApplyProc;
    Dlg.ApplyPreview;

    if Dlg.ShowModal = mrOk then
    begin
      UseDither := (Dlg.rgDither.ItemIndex = 0);
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
