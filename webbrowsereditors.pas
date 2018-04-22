unit WebBrowserEditors;

{$mode delphi}

interface

uses
  Classes, SysUtils, ComponentEditors, WebBrowserCtrls, WebBrowserDlg;

{ TWebBrowserEditor }

type
  TWebBrowserEditor = class(TComponentEditor)
  public
    function GetVerbCount: Integer; override;
    function GetVerb(Index: Integer): string; override;
    procedure ExecuteVerb(Index: Integer); override;
  end;

implementation

{ TWebBrowserEditor }

function TWebBrowserEditor.GetVerbCount: Integer;
begin
  Result := 1;
end;

function TWebBrowserEditor.GetVerb(Index: Integer): string;
begin
  Result := 'Edit';
end;

procedure TWebBrowserEditor.ExecuteVerb(Index: Integer);
begin
  if WebBrowserEdit(Component as TWebBrowser) then
    Modified;
end;

end.

