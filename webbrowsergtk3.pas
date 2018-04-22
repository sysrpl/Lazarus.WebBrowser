unit WebBrowserGtk3;

{$i webbrowser.inc}

interface

{$ifdef lclgtk3}
uses
  Classes, SysUtils, Controls, WSLCLClasses, WebBrowserIntf;

function WebBrowserAvaiable: Boolean;
function WebBrowserNew(Control: IWebBrowserControl): IWebBrowser;
function WebBrowserWSClass: TWSLCLComponentClass;

implementation

uses
  WebkitGtk, LCLType, WSControls, GLib2, LazGdk3, LazGtk3, Gtk3Widgets;

type
  TWebHitTest = set of (htLink, htImage, htMedia, htSelection, htEditable);

  TGtk3WebKitWebView = class(TGtk3Widget)
  protected
    function CreateWidget(const Params: TCreateParams): PGtkWidget; override;
    procedure DestroyWidget; override;
  public
    Control: IWebBrowserControl;
    CoreWidget: PGtkWidget;
    ClientWidget: PWebKitWebView;
  end;

  TGtk3WSWebKitWebView = class(TWSCustomControl)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
  end;

{ Signals }

function WebBrowserError(Widget: PGtkWidget; Frame: PWebKitWebFrame; Uri: PChar;
  Error: PGError; Control: IWebBrowserControl): GBoolean; cdecl;
var
  Handled: Boolean;
begin
  Handled := False;
  Control.DoError(Uri, Error.code, Error.message, Handled);
  Result := Handled;
end;

function WebBrowserDraw(Widget: PGtkWidget; Cairo: Pointer; Control: IWebBrowserControl): GBoolean; cdecl;
begin
  g_signal_handlers_disconnect_by_func(Widget, @WebBrowserDraw, Pointer(Control));
  webkit_web_view_set_view_source_mode(PWebKitWebView(Widget), Control.WebBrowser.SourceView);
  Control.DoReady;
  Result := False;
end;

function WebBrowserMotion(Widget: PWebKitWebView; Event: PGdkEventMotion;
  Control: IWebBrowserControl): GBoolean; cdecl;
var
  HitTest: TWebHitTest;
  Link, Media: string;
  R: PWebKitHitTestResult;
  H: LongWord;
  L, I, M: PChar;
begin
  H := 0;
  R := webkit_web_view_get_hit_test_result(Widget, Event);
  g_object_get(R, 'context', @H, 'link-uri', @L, 'image-uri', @I,
    'media-uri', @M, nil);
  Link := L;
  Media := I;
  if Media = '' then
    Media := M;
  g_object_unref(R);
  HitTest := [];
  if H and WEBKIT_HIT_TEST_RESULT_CONTEXT_LINK = WEBKIT_HIT_TEST_RESULT_CONTEXT_LINK then
    Include(HitTest, htLink);
  if H and WEBKIT_HIT_TEST_RESULT_CONTEXT_IMAGE = WEBKIT_HIT_TEST_RESULT_CONTEXT_IMAGE then
    Include(HitTest, htImage);
  if H and WEBKIT_HIT_TEST_RESULT_CONTEXT_MEDIA = WEBKIT_HIT_TEST_RESULT_CONTEXT_MEDIA then
    Include(HitTest, htMedia);
  if H and WEBKIT_HIT_TEST_RESULT_CONTEXT_SELECTION = WEBKIT_HIT_TEST_RESULT_CONTEXT_SELECTION then
    Include(HitTest, htSelection);
  if H and WEBKIT_HIT_TEST_RESULT_CONTEXT_EDITABLE = WEBKIT_HIT_TEST_RESULT_CONTEXT_EDITABLE then
    Include(HitTest, htEditable);
  Control.DoHitTest(Round(Event.x), Round(Event.y), TypeToOrd<TWebHitTest>(HitTest), Link, Media);
  Result := False;
end;

function WebBrowserNavigate(WebView: PWebKitWebView; Frame: PWebKitNetworkRequest;
  Request: PWebKitNetworkRequest; Control: IWebBrowserControl): TWebKitNavigationResponse; cdecl;
var
  Uri: string;
  Action: LongWord;
begin
  Uri := webkit_network_request_get_uri(Request);
  Action := 0;
  Control.DoNavigate(Uri, Action);
  Result := TWebKitNavigationResponse(Action);
end;

procedure WebBrowserLoadProgress(WebView: PWebKitWebView; Progress: Integer; Control: IWebBrowserControl); cdecl;
begin
  Control.DoProgress(Progress);
end;

{ TGtk3WebKitWebView }

function TGtk3WebKitWebView.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  Allocation: TGTKAllocation;
  Client: PGtkWidget;
begin
  Control := LCLObject as IWebBrowserControl;
  Control.WebBrowser.SetInfo(Self);
  CoreWidget := gtk_scrolled_window_new(nil, nil);
  gtk_scrolled_window_set_policy(PGtkScrolledWindow(CoreWidget), GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
  ClientWidget := webkit_web_view_new;
  Client := PGtkWidget(ClientWidget);
  gtk_widget_add_events(Client, GDK_POINTER_MOTION_MASK);
  g_signal_connect(Client, 'load-error', G_CALLBACK(@WebBrowserError), Control);
  g_signal_connect(Client, 'draw', G_CALLBACK(@WebBrowserDraw), Control);
  g_signal_connect(Client, 'motion-notify-event', G_CALLBACK(@WebBrowserMotion), Control);
  g_signal_connect(Client, 'navigation-requested', G_CALLBACK(@WebBrowserNavigate), Control);
  g_signal_connect(Client, 'load-progress-changed', G_CALLBACK(@WebBrowserLoadProgress), Control);
  gtk_container_add(PGtkContainer(CoreWidget), Client);
  Allocation.X := Params.X;
  Allocation.Y := Params.Y;
  Allocation.Width := Params.Width;
  Allocation.Height := Params.Height;
  gtk_widget_size_allocate(CoreWidget, @Allocation);
  Result := CoreWidget;
end;

procedure TGtk3WebKitWebView.DestroyWidget;
var
  Client: PGtkWidget;
begin
  Client := PGtkWidget(ClientWidget);
  g_signal_handlers_disconnect_by_func(Client, @WebBrowserError, Control);
  g_signal_handlers_disconnect_by_func(Client, @WebBrowserMotion, Control);
  g_signal_handlers_disconnect_by_func(Client, @WebBrowserNavigate, Control);
  g_signal_handlers_disconnect_by_func(Client, @WebBrowserLoadProgress, Control);
  Client^.destroy_;
  Control.WebBrowser.Shutdown;
  inherited DestroyWidget;
end;

class function TGtk3WSWebKitWebView.CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle;
var
  WebView: TGtk3WebKitWebView;
begin
  WebView := TGtk3WebKitWebView.Create(AWinControl, AParams);
  Result := TLCLIntfHandle(WebView);
end;

{ TWebBrowser }

type
  TWebBrowser = class(TInterfacedObject, IWidget, IWebBrowser)
  private
    FControl: IWebBrowserControl;
    FInfo: TGtk3WebKitWebView;
    FSourceView: Boolean;
  public
    constructor Create(Control: IWebBrowserControl);
    function GetInfo: Pointer;
    procedure SetInfo(Value: Pointer);
    procedure Shutdown;
    function GetLocation: string;
    function GetSourceView: Boolean;
    procedure SetSourceView(Value: Boolean);
    function GetStatus: LongWord;
    function GetTitle: string;
    procedure Load(const Uri: string);
    procedure LoadHtml(const Html: string);
    procedure Stop;
    procedure Reload;
    procedure ViewInspector(Enabled: Boolean);
    procedure Inspect(X, Y: Integer);
    procedure BackOrForward(Direction: Integer);
    function BackOrForwardExists(Direction: Integer): Boolean;
  end;

constructor TWebBrowser.Create(Control: IWebBrowserControl);
begin
  inherited Create;
  FControl := Control;
end;

function TWebBrowser.GetInfo: Pointer;
begin
  Result := FInfo;
end;

procedure TWebBrowser.SetInfo(Value: Pointer);
begin
  if Value = nil then
    Exit;
  if FInfo = nil then
    FInfo := Value;
end;

procedure TWebBrowser.Shutdown;
begin
  FInfo := nil;
end;

function TWebBrowser.GetLocation: string;
begin
  Result := '';
  if FInfo = nil then
    Exit;
  Result := webkit_web_view_get_uri(PWebKitWebView(FInfo.ClientWidget));
end;

function TWebBrowser.GetSourceView: Boolean;
begin
  Result := FSourceView;
end;

procedure TWebBrowser.SetSourceView(Value: Boolean);
begin
  if FInfo = nil then
  begin
    FSourceView := Value;
    Exit;
  end;
  if Value <> FSourceView then
  begin
    FSourceView := Value;
    webkit_web_view_set_view_source_mode(PWebKitWebView(FInfo.ClientWidget), FSourceView);
    Reload;
  end;
end;

function TWebBrowser.GetStatus: LongWord;
begin
  Result := 0;
  if FInfo = nil then
    Exit;
  Result := Ord(webkit_web_view_get_load_status(PWebKitWebView(FInfo.ClientWidget)));
end;

function TWebBrowser.GetTitle: string;
begin
  Result := '';
  if FInfo = nil then
    Exit;
  Result := webkit_web_view_get_title(PWebKitWebView(FInfo.ClientWidget));
end;

procedure TWebBrowser.Load(const Uri: string);
begin
  if FInfo = nil then
    Exit;
  FControl.DoProgress(0);
  webkit_web_view_load_uri(PWebKitWebView(FInfo.ClientWidget), PChar(Uri));
end;

procedure TWebBrowser.LoadHtml(const Html: string);
begin
  if FInfo = nil then
    Exit;
  FControl.DoProgress(0);
  webkit_web_view_load_string(PWebKitWebView(FInfo.ClientWidget), PChar(Html),
    nil, nil, nil);
end;

procedure TWebBrowser.Stop;
begin
  if FInfo = nil then
    Exit;
  webkit_web_view_stop_loading(PWebKitWebView(FInfo.ClientWidget));
  FControl.DoProgress(100);
end;

procedure TWebBrowser.Reload;
begin
  if FInfo = nil then
    Exit;
  FControl.DoProgress(0);
  webkit_web_view_reload(PWebKitWebView(FInfo.ClientWidget));
end;

procedure TWebBrowser.ViewInspector(Enabled: Boolean);
var
  I: PWebKitWebInspector;
begin
  if FInfo = nil then
    Exit;
  I := webkit_web_view_get_inspector(PWebKitWebView(FInfo.ClientWidget));
  if Enabled then
    webkit_web_inspector_show(I)
  else
    webkit_web_inspector_close(I);
end;

procedure TWebBrowser.Inspect(X, Y: Integer);
var
  I: PWebKitWebInspector;
begin
  if FInfo = nil then
    Exit;
  I := webkit_web_view_get_inspector(PWebKitWebView(FInfo.ClientWidget));
  webkit_web_inspector_show(I);
  webkit_web_inspector_inspect_coordinates(I, X, Y);
end;

procedure TWebBrowser.BackOrForward(Direction: Integer);
begin
  if FInfo = nil then
    Exit;
  webkit_web_view_go_back_or_forward(PWebKitWebView(FInfo.ClientWidget), Direction);
end;

function TWebBrowser.BackOrForwardExists(Direction: Integer): Boolean;
begin
  Result := False;
  if FInfo = nil then
    Exit;
  Result := webkit_web_view_can_go_back_or_forward(PWebKitWebView(FInfo.ClientWidget), Direction);
end;

function WebBrowserAvaiable: Boolean;
begin
  Result := WebBrowserLoad;
end;

function WebBrowserNew(Control: IWebBrowserControl): IWebBrowser;
begin
  Result := TWebBrowser.Create(Control);
end;

function WebBrowserWSClass: TWSLCLComponentClass;
begin
  Result := TGtk3WSWebKitWebView;
end;

{$else}
implementation
{$endif}

end.

