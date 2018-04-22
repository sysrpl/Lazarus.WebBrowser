unit WebBrowserRegister;

{$mode delphi}

interface

uses
  Classes, ComponentEditors, WebBrowserCtrls, WebBrowserEditors;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Internet', [TWebBrowser, TWebInspector]);
  RegisterComponentEditor(TWebBrowser, TWebBrowserEditor);
end;

{ procedure AddUsesUnit(Instance: TObject; const UnitName: string);
var
  Component: TComponent;
  Form: TCustomForm;
  Project: TLazProjectFile;
  Buffer: TCodeBuffer;
  Tool: TCodeTool;
  Cache: TSourceChangeCache;
  S: string;
begin
  if LazarusIDE = nil then
    Exit;
  if not (Instance is TComponent) then
    Exit;
  Component := Instance as TComponent;
  if not (Component.Owner is TCustomForm) then
    Exit;
  Form := Component.Owner as TCustomForm;
  if Form.Designer = nil then
    Exit;
  Project := LazarusIDE.GetProjectFileWithDesigner(Form.Designer);
  if Project = nil then
    Exit;
  S := Project.GetSourceText;
  Buffer := CodeToolBoss.CreateFile('________a.pas');
  Buffer.Source := S;
  if not CodeToolBoss.Explore(Buffer, Tool, False, True) then
    Exit;
  Cache := CodeToolBoss.SourceChangeCache;
  Cache.MainScanner := Tool.Scanner;
  CodeToolBoss.AddUnitToMainUsesSection(Buffer, UnitName, '');
  if Buffer.Source <> S then
    Project.SetSourceText(Buffer.Source);
end; }

end.
