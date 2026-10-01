unit frmRisoV3Dlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, uPreviewFit, uRiso, uTitleBar;

type
  TRisoV3Dlg = class(TFotoForm)
    lblLayers: TLabel;
    cmbLayers: TComboBox;
    sw0: TShape;
    btnColor0: TButton;
    lblRgb0: TLabel;
    sw1: TShape;
    btnColor1: TButton;
    lblRgb1: TLabel;
    sw2: TShape;
    btnColor2: TButton;
    lblRgb2: TLabel;
    sw3: TShape;
    btnColor3: TButton;
    lblRgb3: TLabel;
    sw4: TShape;
    btnColor4: TButton;
    lblRgb4: TLabel;
    pboxPreview: TPaintBox;
    btnOK: TButton;
    btnCancel: TButton;
    procedure pboxPreviewPaint(Sender: TObject);
    procedure cmbLayersChange(Sender: TObject);
    procedure btnColor0Click(Sender: TObject);
    procedure btnColor1Click(Sender: TObject);
    procedure btnColor2Click(Sender: TObject);
    procedure btnColor3Click(Sender: TObject);
    procedure btnColor4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FOriginalPreview: TBitmap;
    FWorkingPreview: TBitmap;
    FSourceBmp: TBitmap;
    FColors: array[0..4] of TColor;
    function ColorRgbStr(C: TColor): string;
    procedure UpdateSwatches;
    procedure UpdateVisibility;
    procedure ApplyPreview;
    procedure ApplyFull;
  end;

function ShowRisoV3Dlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

{$R *.dfm}

function ShowRisoV3Dlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TRisoV3Dlg;
  Scale: Double;
  pw, ph: Integer;
  Scaled: TBitmap;
  SW: TStopwatch;
begin
  ElapsedSec := 0;
  Result := False;
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;
  Dlg := TRisoV3Dlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;

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

    Dlg.ApplyPreview;

    if Dlg.ShowModal = mrOk then
    begin
      SW := TStopwatch.StartNew;
      Dlg.ApplyFull;
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TRisoV3Dlg }

procedure TRisoV3Dlg.FormCreate(Sender: TObject);
begin
  FColors[0] := RGB(200, 55, 70);
  FColors[1] := RGB(30, 30, 35);
  FColors[2] := RGB(240, 200, 20);
  FColors[3] := RGB(0, 165, 195);
  FColors[4] := RGB(70, 170, 80);

  cmbLayers.Items.Add('2');
  cmbLayers.Items.Add('3');
  cmbLayers.Items.Add('4');
  cmbLayers.Items.Add('5');
  cmbLayers.ItemIndex := 0;

  UpdateSwatches;
  UpdateVisibility;
end;

procedure TRisoV3Dlg.FormDestroy(Sender: TObject);
begin
  FOriginalPreview.Free;
  FWorkingPreview.Free;
end;

function TRisoV3Dlg.ColorRgbStr(C: TColor): string;
begin
  Result := Format('R=%d G=%d B=%d',
    [Byte(C and $FF), Byte((C shr 8) and $FF), Byte((C shr 16) and $FF)]);
end;

procedure TRisoV3Dlg.UpdateSwatches;
begin
  sw0.Brush.Color := FColors[0];
  sw1.Brush.Color := FColors[1];
  sw2.Brush.Color := FColors[2];
  sw3.Brush.Color := FColors[3];
  sw4.Brush.Color := FColors[4];

  lblRgb0.Caption := ColorRgbStr(FColors[0]);
  lblRgb1.Caption := ColorRgbStr(FColors[1]);
  lblRgb2.Caption := ColorRgbStr(FColors[2]);
  lblRgb3.Caption := ColorRgbStr(FColors[3]);
  lblRgb4.Caption := ColorRgbStr(FColors[4]);
end;

procedure TRisoV3Dlg.UpdateVisibility;
var
  Num: Integer;
begin
  Num := cmbLayers.ItemIndex + 2;
  sw2.Visible := Num >= 3;
  btnColor2.Visible := Num >= 3;
  lblRgb2.Visible := Num >= 3;
  sw3.Visible := Num >= 4;
  btnColor3.Visible := Num >= 4;
  lblRgb3.Visible := Num >= 4;
  sw4.Visible := Num >= 5;
  btnColor4.Visible := Num >= 5;
  lblRgb4.Visible := Num >= 5;
end;

procedure TRisoV3Dlg.cmbLayersChange(Sender: TObject);
begin
  UpdateVisibility;
  ApplyPreview;
end;

procedure TRisoV3Dlg.btnColor0Click(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FColors[0];
    if Dlg.Execute then
    begin FColors[0] := Dlg.Color; UpdateSwatches; ApplyPreview; end;
  finally
    Dlg.Free;
  end;
end;

procedure TRisoV3Dlg.btnColor1Click(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FColors[1];
    if Dlg.Execute then
    begin FColors[1] := Dlg.Color; UpdateSwatches; ApplyPreview; end;
  finally
    Dlg.Free;
  end;
end;

procedure TRisoV3Dlg.btnColor2Click(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FColors[2];
    if Dlg.Execute then
    begin FColors[2] := Dlg.Color; UpdateSwatches; ApplyPreview; end;
  finally
    Dlg.Free;
  end;
end;

procedure TRisoV3Dlg.btnColor3Click(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FColors[3];
    if Dlg.Execute then
    begin FColors[3] := Dlg.Color; UpdateSwatches; ApplyPreview; end;
  finally
    Dlg.Free;
  end;
end;

procedure TRisoV3Dlg.btnColor4Click(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FColors[4];
    if Dlg.Execute then
    begin FColors[4] := Dlg.Color; UpdateSwatches; ApplyPreview; end;
  finally
    Dlg.Free;
  end;
end;

procedure TRisoV3Dlg.ApplyPreview;
var
  Layers: array of TRisoColor;
  Num, I: Integer;
begin
  Num := cmbLayers.ItemIndex + 2;
  SetLength(Layers, Num);
  for I := 0 to Num - 1 do
  begin
    Layers[I].R := Byte(FColors[I] and $FF);
    Layers[I].G := Byte((FColors[I] shr 8) and $FF);
    Layers[I].B := Byte((FColors[I] shr 16) and $FF);
  end;
  FWorkingPreview.Assign(FOriginalPreview);
  DoRisoV3(FWorkingPreview, Layers);
  pboxPreview.Invalidate;
end;

procedure TRisoV3Dlg.ApplyFull;
var
  Layers: array of TRisoColor;
  Num, I: Integer;
begin
  Num := cmbLayers.ItemIndex + 2;
  SetLength(Layers, Num);
  for I := 0 to Num - 1 do
  begin
    Layers[I].R := Byte(FColors[I] and $FF);
    Layers[I].G := Byte((FColors[I] shr 8) and $FF);
    Layers[I].B := Byte((FColors[I] shr 16) and $FF);
  end;
  DoRisoV3(FSourceBmp, Layers);
end;

procedure TRisoV3Dlg.pboxPreviewPaint(Sender: TObject);
var
  SrcW, SrcH: Integer;
  NewW, NewH: Integer;
  TargetW, TargetH: Integer;
  Scale: Double;
  DestRect: TRect;
begin
  with pboxPreview.Canvas do
  begin
    Brush.Color := clBtnFace;
    FillRect(pboxPreview.ClientRect);

    if Assigned(FWorkingPreview) then
    begin
      SrcW := FWorkingPreview.Width;
      SrcH := FWorkingPreview.Height;
      if (SrcW = 0) or (SrcH = 0) then Exit;

      TargetW := pboxPreview.ClientWidth;
      TargetH := pboxPreview.ClientHeight;

      Scale := Min(TargetW / SrcW, TargetH / SrcH);
      NewW := Round(SrcW * Scale);
      NewH := Round(SrcH * Scale);

      DestRect := Rect(
        (TargetW - NewW) div 2,
        (TargetH - NewH) div 2,
        (TargetW - NewW) div 2 + NewW,
        (TargetH - NewH) div 2 + NewH
      );

      StretchDraw(DestRect, FWorkingPreview);
    end;
  end;
end;

end.
