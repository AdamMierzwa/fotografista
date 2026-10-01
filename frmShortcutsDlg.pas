unit frmShortcutsDlg;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, uI18n, uTitleBar;

type
  TShortcutItem = record
    Key: string;
    Cmd: string;
  end;

  TShortcutSection = record
    Title: string;
    Items: array of TShortcutItem;
  end;

  TfrmShortcutsDlg = class(TFotoForm)
    btnOK: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    FSections: array of TShortcutSection;
    procedure LoadData;
    procedure BuildLayout;
  public
  end;

implementation

{$R *.dfm}

// '##Xxx' = nowa sekcja (wytluszczony naglowek wpiety w krawedz ramki),
// kolejne pary = skrot, polecenie. Skroty zgodne z realnym MainMenu
// (w tym porcie Dopasuj do okna to Ctrl+0, nie Ctrl+O).
// Dane w bazie EN (klucze i18n); T() w LoadData podmienia na aktywny jezyk.
const
  DATA: array[0..38] of string = (
    '##File',
    'Ctrl+O', 'Open...',
    'Ctrl+S', 'Save as...',
    'Ctrl+W', 'Close',
    'Ctrl+Q', 'Quit',
    '##Edit',
    'Ctrl+Z', 'Undo',
    'Ctrl+Y', 'Redo',
    'Ctrl+C', 'Copy',
    'Ctrl+V', 'Paste',
    '##View',
    'Ctrl+P', 'Zoom in',
    'Ctrl+M', 'Zoom out',
    'Ctrl+0', 'Fit to window',
    'Ctrl+1', '100%',
    'Space + LMB', 'Move image',
    'or MMB', '',
    '##Image',
    'Ctrl+Shift+R', 'Selection size...',
    'Ctrl+X', 'Crop to selection',
    '##Tools',
    'W', 'Launcher');

procedure TfrmShortcutsDlg.LoadData;
var
  I: Integer;
begin
  SetLength(FSections, 0);
  I := 0;
  while I <= High(DATA) do
  begin
    if Copy(DATA[I], 1, 2) = '##' then
    begin
      SetLength(FSections, Length(FSections) + 1);
      FSections[High(FSections)].Title := T(Copy(DATA[I], 3, MaxInt));
    end
    else
    begin
      with FSections[High(FSections)] do
      begin
        SetLength(Items, Length(Items) + 1);
        Items[High(Items)].Key := T(DATA[I]);
        Items[High(Items)].Cmd := T(DATA[I + 1]);
      end;
      Inc(I);
    end;
    Inc(I);
  end;
end;

// Okno jest budowane dynamicznie i dopasowane do tresci - niczego nie
// trzeba przewijac, nic nie mozna zaznaczyc (same TLabel). Kazda sekcja
// to TGroupBox: ramka z wytluszczona nazwa wpieta w gorna krawedz,
// jak w Hollywood.
procedure TfrmShortcutsDlg.BuildLayout;
const
  Margin = 12;      // od krawedzi okna do grup
  Gap = 10;         // odstep pionowy miedzy grupami
  PadX = 10;        // wewnetrzny margines poziomy grup
  ColGap = 14;      // odstep miedzy kolumna skrotu a poleceniem
  RowPad = 2;       // nadmiar wysokosci wiersza
var
  Bmp: TBitmap;
  MaxKeyW, MaxCmdW, MaxTitleW, GrpW, GrpH: Integer;
  SecTop, RowH, I, J, Y: Integer;
  Grp: TGroupBox;
  Lbl: TLabel;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font := Self.Font;
    RowH := Bmp.Canvas.TextHeight('X') + RowPad;
    MaxKeyW := 0; MaxCmdW := 0; MaxTitleW := 0;
    for I := 0 to High(FSections) do
    begin
      Bmp.Canvas.Font.Style := [fsBold];
      MaxTitleW := Max(MaxTitleW, Bmp.Canvas.TextWidth(FSections[I].Title));
      Bmp.Canvas.Font.Style := [];
      for J := 0 to High(FSections[I].Items) do
      begin
        MaxKeyW := Max(MaxKeyW, Bmp.Canvas.TextWidth(FSections[I].Items[J].Key));
        MaxCmdW := Max(MaxCmdW, Bmp.Canvas.TextWidth(FSections[I].Items[J].Cmd));
      end;
    end;
    GrpW := Max(2 * PadX + MaxKeyW + ColGap + MaxCmdW,
      2 * PadX + MaxTitleW);

    SecTop := Margin;
    for I := 0 to High(FSections) do
    begin
      GrpH := 16 + (Length(FSections[I].Items)) * RowH + 4;
      Grp := TGroupBox.Create(Self);
      Grp.Parent := Self;
      Grp.Left := Margin;
      Grp.Top := SecTop;
      Grp.Width := GrpW;
      Grp.Height := GrpH;
      Grp.Caption := FSections[I].Title;
      Grp.Font.Style := [fsBold];       // wytluszczona nazwa sekcji
      Y := 16;
      for J := 0 to High(FSections[I].Items) do
      begin
        Lbl := TLabel.Create(Grp);
        Lbl.Parent := Grp;
        Lbl.Font.Style := [];
        Lbl.Left := PadX;
        Lbl.Top := Y;
        Lbl.Caption := FSections[I].Items[J].Key;
        Lbl.AutoSize := True;
        Lbl := TLabel.Create(Grp);
        Lbl.Parent := Grp;
        Lbl.Font.Style := [];
        Lbl.Left := PadX + MaxKeyW + ColGap;
        Lbl.Top := Y;
        Lbl.Caption := FSections[I].Items[J].Cmd;
        Lbl.AutoSize := True;
        Inc(Y, RowH);
      end;
      SecTop := SecTop + GrpH + Gap;
    end;
  finally
    Bmp.Free;
  end;

  ClientWidth := GrpW + 2 * Margin;
  ClientHeight := (SecTop - Gap) + 14 + btnOK.Height + 12;
  btnOK.Left := ClientWidth - 12 - btnOK.Width;
  btnOK.Top := ClientHeight - 12 - btnOK.Height;
end;

procedure TfrmShortcutsDlg.FormCreate(Sender: TObject);
begin
  LoadData;
  BuildLayout;
end;

procedure TfrmShortcutsDlg.btnOKClick(Sender: TObject);
begin
  Close;
end;

end.
