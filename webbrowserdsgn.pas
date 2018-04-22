{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit WebBrowserDsgn;

{$warn 5023 off : no warning about unused units}
interface

uses
  WebBrowserRegister, WebBrowserDlg, WebBrowserEditors, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('WebBrowserRegister', @WebBrowserRegister.Register);
end;

initialization
  RegisterPackage('WebBrowserDsgn', @Register);
end.
