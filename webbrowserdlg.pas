unit WebBrowserDlg;

{$mode delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  WebBrowserCtrls;

{ TWebBrowserDialog }

type
 TWebBrowserDialog = class(TForm)
    OKButton: TButton;
    CancelButton: TButton;
    UriEdit: TEdit;
    CaptionLabel: TLabel;
    HtmlMemo: TMemo;
    UriRadio: TRadioButton;
    HtmlRadio: TRadioButton;
    procedure FormCreate(Sender: TObject);
  end;

function WebBrowserEdit(Browser: TWebBrowser): Boolean;

implementation

{$R *.lfm}

function WebBrowserEdit(Browser: TWebBrowser): Boolean;
var
  F: TWebBrowserDialog;
begin
  F := TWebBrowserDialog.Create(Application);
  try
    F.UriRadio.Checked := not Browser.HtmlDefined;
    F.UriEdit.Text := Browser.Location;
    F.HtmlRadio.Checked := Browser.HtmlDefined;
    F.HtmlMemo.Text := Browser.Html;
    Result := F.ShowModal = mrOK;
    if Result then
      if F.UriRadio.Checked then
        Browser.Load(F.UriEdit.Text)
      else
        Browser.LoadHtml(F.HtmlMemo.Text);
  finally
    F.Free;
  end;
end;

{ TWebBrowserDialog }

procedure TWebBrowserDialog.FormCreate(Sender: TObject);
begin
  ClientWidth := CancelButton.Left + CancelButton.Width + 8;
  ClientHeight := CancelButton.Top + CancelButton.Height + 8;
end;

end.

