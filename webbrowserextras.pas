unit WebBrowserExtras;

{$mode delphi}

interface

uses
  SysUtils, Classes, Graphics, Controls;

type
  TWebAddressBar = class(TCustomControl)

  end;

{ TWebStatusIndicator }

  TWebStatusIndicator = class(TGraphicControl)
  private
    FLink: string;
    FProgress: Integer;
    FUri: string;
    procedure SetLink(Value: string);
    procedure SetProgress(Value: Integer);
    procedure SetUri(Value: string);
  published
    property Uri: string read FUri write SetUri;
    property Link: string read FLink write SetLink;
    property Progress: Integer read FProgress write SetProgress;
  end;

implementation

{ TWebStatusIndicator }

procedure TWebStatusIndicator.SetLink(Value: string);
begin
  if FLink = Value then Exit;
  FLink := Value;
end;

procedure TWebStatusIndicator.SetProgress(Value: Integer);
begin
  if FProgress = Value then Exit;
  FProgress := Value;
end;

procedure TWebStatusIndicator.SetUri(Value: string);
begin
  if FUri = Value then Exit;
  FUri := Value;
end;

end.

