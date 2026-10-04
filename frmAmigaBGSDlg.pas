unit frmAmigaBGSDlg;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.Diagnostics,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, uAmiga, uI18n, uMacros;

type
  TAmigaBGSDlg = class(TForm)
    lblRes: TLabel;
    cbRes: TComboBox;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
  private
    FSourceBmp: TBitmap;
    procedure ApplyFull(Tw, Th: Integer);
  end;

function ShowAmigaBGSDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;

implementation

{$R *.dfm}

const
  ResW: array[0..4] of Integer = (320, 640, 640, 800, 1024);
  ResH: array[0..4] of Integer = (256, 256, 512, 600, 768);

function ShowAmigaBGSDlg(Bitmap: TBitmap; out ElapsedSec: Double): Boolean;
var
  Dlg: TAmigaBGSDlg;
  SW: TStopwatch;
  Idx, Tw, Th: Integer;
begin
  ElapsedSec := 0;
  Result := False;
  gMacroPending.Code := '';
  if (Bitmap = nil) or (Bitmap.Width = 0) then Exit;

  Dlg := TAmigaBGSDlg.Create(Application);
  try
    Dlg.FSourceBmp := Bitmap;

    if Dlg.ShowModal = mrOk then
    begin
      Idx := Dlg.cbRes.ItemIndex;
      if Idx < 0 then Idx := 0;
      Tw := ResW[Idx];
      Th := ResH[Idx];
      SW := TStopwatch.StartNew;
      gMacroPending.Code := 'AMIGABGS';
      gMacroPending.Params := IntToStr(Tw) + '|' + IntToStr(Th);
      Dlg.ApplyFull(Tw, Th);
      ElapsedSec := SW.Elapsed.TotalSeconds;
      Result := True;
    end;
  finally
    Dlg.Free;
  end;
end;

{ TAmigaBGSDlg }

procedure TAmigaBGSDlg.FormCreate(Sender: TObject);
var
  I, MaxItemW, ComboW, ContentW, Gap, SectionGap, Margin, Pad: Integer;
begin
  cbRes.Items.Clear;
  cbRes.Items.Add('320 x 256 (OCS/ECS PAL Lo-Res)');
  cbRes.Items.Add('640 x 256 (OCS/ECS PAL Hi-Res)');
  cbRes.Items.Add('640 x 512 (OCS/ECS PAL Interlace)');
  cbRes.Items.Add('800 x 600 (AGA/RTG)');
  cbRes.Items.Add('1024 x 768 (AGA/RTG)');
  cbRes.ItemIndex := 0;

  TranslateForm(Self);

  Margin := 15;
  Gap := Canvas.TextHeight('Wg') div 3;
  SectionGap := Canvas.TextHeight('Wg');
  Pad := 2 * Canvas.TextWidth('W');

  MaxItemW := 0;
  for I := 0 to cbRes.Items.Count - 1 do
    if Canvas.TextWidth(cbRes.Items[I]) > MaxItemW then
      MaxItemW := Canvas.TextWidth(cbRes.Items[I]);

  btnOK.Width := Max(85, Canvas.TextWidth(btnOK.Caption) + Pad);
  btnCancel.Width := Max(85, Canvas.TextWidth(btnCancel.Caption) + Pad);

  ComboW := MaxItemW + SectionGap * 2 + 8;
  cbRes.Width := ComboW;

  ContentW := Max(lblRes.Width, ComboW);
  if btnOK.Width + Gap + btnCancel.Width > ContentW then
    ContentW := btnOK.Width + Gap + btnCancel.Width;
  ClientWidth := ContentW + 2 * Margin;

  lblRes.Left := Margin;
  lblRes.Top := Margin;
  cbRes.Left := Margin;
  cbRes.Top := lblRes.Top + lblRes.Height + Gap;

  btnCancel.Left := ClientWidth - Margin - btnCancel.Width;
  btnOK.Left := btnCancel.Left - Gap - btnOK.Width;
  btnOK.Top := cbRes.Top + cbRes.Height + SectionGap;
  btnCancel.Top := btnOK.Top;

  ClientHeight := btnOK.Top + btnOK.Height + Margin;
end;

procedure TAmigaBGSDlg.ApplyFull(Tw, Th: Integer);
begin
  ApplyAmigaBackgroundStretch(FSourceBmp, Tw, Th);
end;

end.
