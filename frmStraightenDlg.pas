unit frmStraightenDlg;

interface

uses
  Winapi.Windows, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls, uTitleBar;

type
  TStraightenDlg = class(TFotoForm)
    imgPreview: TImage;
    tbAngle: TTrackBar;
    btnOK: TButton;
    btnCancel: TButton;
    lblAngle: TLabel;
    lblAngleValue: TLabel;
    procedure tbAngleChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FSourcePreview: TBitmap;
    FTransformedPreview: TBitmap;
    FSrcGP: TGPBitmap;
    procedure InitGdiPlus;
    procedure FreeGdiPlus;
    procedure SizePreview;
    procedure UpdatePreview;
  end;

var
  StraightenSourceBmp: TBitmap = nil;

function ShowStraightenDlg(out Angle: Integer): Boolean;

implementation

{$R *.dfm}

uses
  System.Math;

function ShowStraightenDlg(out Angle: Integer): Boolean;
var
  Dlg: TStraightenDlg;
begin
  Result := False;
  if StraightenSourceBmp = nil then Exit;
  Dlg := TStraightenDlg.Create(Application);
  try
    Result := Dlg.ShowModal = mrOk;
    if Result then
      Angle := Dlg.tbAngle.Position;
  finally
    Dlg.Free;
  end;
end;

var
  GdiPlusToken: ULONG_PTR = 0;

procedure TStraightenDlg.FormCreate(Sender: TObject);
var
  SI: TGDIPlusStartupInput;
begin
  if GdiPlusToken = 0 then
  begin
    SI.GdiplusVersion := 1;
    SI.DebugEventCallback := nil;
    SI.SuppressBackgroundThread := False;
    SI.SuppressExternalCodecs := False;
    GdiplusStartup(GdiPlusToken, @SI, nil);
  end;
  SizePreview;
  InitGdiPlus;
  UpdatePreview;
end;

procedure TStraightenDlg.FormDestroy(Sender: TObject);
begin
  FreeGdiPlus;
  FSourcePreview.Free;
  FTransformedPreview.Free;
end;

procedure TStraightenDlg.SizePreview;
var
  PW, PH, Margin: Integer;
  SrcW, SrcH: Integer;
const
  MAX_DIM = 400;
begin
  if (StraightenSourceBmp = nil) or (StraightenSourceBmp.Width = 0) then
    Exit;

  Margin := CtrlGap * 3;

  SrcW := StraightenSourceBmp.Width;
  SrcH := StraightenSourceBmp.Height;
  if SrcW >= SrcH then
  begin
    PW := MAX_DIM;
    PH := Max(1, Round(SrcH / SrcW * MAX_DIM));
  end else
  begin
    PH := MAX_DIM;
    PW := Max(1, Round(SrcW / SrcH * MAX_DIM));
  end;

  imgPreview.Width := PW;
  imgPreview.Height := PH;
  imgPreview.Left := Margin;
  imgPreview.Top := Margin;
  ClientWidth := Max(PW + Margin * 2, lblAngle.Left + lblAngle.Width + Margin);
  CenterHorizontally(imgPreview);

  lblAngle.Left := Margin;
  lblAngle.Top := imgPreview.Top + PH + RowGap;

  tbAngle.Left := Margin;
  tbAngle.Top := lblAngle.Top + lblAngle.Height + RowGap;
  tbAngle.Width := ClientWidth - Margin * 2;

  lblAngleValue.Left := (ClientWidth - lblAngleValue.Width) div 2;
  lblAngleValue.Top := tbAngle.Top + tbAngle.Height;

  // OK/Cancel standardowo w prawym dolnym rogu okna
  btnOK.Top := lblAngleValue.Top + lblAngleValue.Height + CtrlGap * 2;
  btnOK.Left := ClientWidth - btnOK.Width - btnCancel.Width - CtrlGap - Margin;
  btnCancel.Top := btnOK.Top;
  btnCancel.Left := ClientWidth - btnCancel.Width - Margin;
  ClientHeight := btnOK.Top + btnOK.Height + CtrlGap;

  FSourcePreview := TBitmap.Create;
  FSourcePreview.PixelFormat := pf24bit;
  FSourcePreview.SetSize(PW, PH);
  SetStretchBltMode(FSourcePreview.Canvas.Handle, HALFTONE);
  FSourcePreview.Canvas.StretchDraw(Rect(0, 0, PW, PH), StraightenSourceBmp);

  FTransformedPreview := TBitmap.Create;
  FTransformedPreview.PixelFormat := pf24bit;
  FTransformedPreview.SetSize(PW, PH);
end;

procedure TStraightenDlg.InitGdiPlus;
begin
  if FSourcePreview = nil then Exit;
  FSrcGP := TGPBitmap.Create(FSourcePreview.Handle, FSourcePreview.Palette);
end;

procedure TStraightenDlg.FreeGdiPlus;
begin
  FreeAndNil(FSrcGP);
end;

procedure TStraightenDlg.UpdatePreview;
var
  Angle: Double;
  G: TGPGraphics;
  RotM: TGPMatrix;
begin
  if (FSourcePreview = nil) or (FSrcGP = nil) then Exit;

  Angle := tbAngle.Position;
  if Angle = 0 then
  begin
    imgPreview.Picture.Bitmap.Assign(FSourcePreview);
    Exit;
  end;

  // Rysowanie GDI+ bezpośrednio na płótno VCL – zero wycieków HBITMAP!
  G := TGPGraphics.Create(FTransformedPreview.Canvas.Handle);
  try
    G.SetInterpolationMode(InterpolationModeBilinear);
    G.Clear(MakeColor(255, 240, 240, 240)); // Czyszczenie tła

    RotM := TGPMatrix.Create;
    try
      RotM.RotateAt(Angle, MakePoint(FSourcePreview.Width / 2.0, FSourcePreview.Height / 2.0));
      G.SetTransform(RotM);
      G.DrawImage(FSrcGP, 0, 0, FSourcePreview.Width, FSourcePreview.Height);
    finally
      RotM.Free;
    end;
  finally
    G.Free;
  end;

  imgPreview.Picture.Bitmap.Assign(FTransformedPreview);
end;

procedure TStraightenDlg.tbAngleChange(Sender: TObject);
begin
  lblAngleValue.Caption := IntToStr(tbAngle.Position) + '°';
  UpdatePreview;
end;

end.
