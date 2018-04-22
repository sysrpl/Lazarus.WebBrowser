unit WebBrowserGtk2;

{$i webbrowser.inc}

interface

{$ifdef lclgtk2}
uses
  Classes, SysUtils, Graphics, Controls, WSLCLClasses, WebSystem,
  WebBrowserIntf;

function WebControlsAvaiable: Boolean;
function WebInspectorNew(Control: IWebInspectorControl): IWebInspector;
function WebInspectorWSClass: TWSLCLComponentClass;
function WebBrowserNew(Control: IWebBrowserControl): IWebBrowser;
function WebBrowserWSClass: TWSLCLComponentClass;

implementation

{ TODO: Add “download-requested” signal handler and write IWebDownload
  interface }

uses
  LCLType, WSControls, GLib2, Gdk2, Gdk2Pixbuf, Cairo, Gtk2, Gtk2Def,
  Gtk2Proc, Gtk2WSControls, WebkitGtk;

{$region IWebInspector}
{ TWebInspector }

type
  TWebInspector = class(TInterfacedObject, IWidget, IWebInspector)
  private
    FActive: Boolean;
    FWebBrowser: IWebBrowser;
    FControl: IWebInspectorControl;
    FInfo: PWidgetInfo;
  protected
    function GetInfo: Pointer;
    procedure SetInfo(Value: Pointer);
    procedure Shutdown;
    function GetActive: Boolean;
    procedure SetActive(Value: Boolean);
    procedure Connect(Widget: IWidget);
    property Active: Boolean read GetActive write SetActive;
  public
    constructor Create(Control: IWebInspectorControl);
  end;

constructor TWebInspector.Create(Control: IWebInspectorControl);
begin
  inherited Create;
  FControl := Control;
end;

function TWebInspector.GetInfo: Pointer;
begin
  Result := FInfo;
end;

procedure TWebInspector.SetInfo(Value: Pointer);
begin
  if Value = nil then
    Exit;
  if FInfo = nil then
    FInfo := Value;
end;

function TWebInspector.GetActive: Boolean;
begin
  Result := FActive;
end;

procedure TWebInspector.Shutdown;
begin
  FActive := True;
  SetActive(False);
  FInfo := nil;
end;

function WebInspectorShow(Inspector: PWebKitWebInspector; WebView: PWebKitWebView;
  InspectView: PWebKitWebView): PWebKitWebView;
begin
  Result := InspectView;
  g_signal_handlers_disconnect_by_func(Inspector, @WebInspectorShow, InspectView);
end;

procedure TWebInspector.SetActive(Value: Boolean);
var
  Info: PWidgetInfo;
  WebView, InspectView: PWebKitWebView;
  Inspector: PWebKitWebInspector;
  Control: TControl;
begin
  FActive := Value;
  if FInfo = nil then
    Exit;
  if FWebBrowser = nil then
    Exit;
  Info := FWebBrowser.Info;
  if Info = nil then
    Exit;
  WebView := PWebKitWebView(Info.ClientWidget);
  Inspector := webkit_web_view_get_inspector(WebView);
  if FActive then
  begin
    Control := FInfo.LCLObject as TControl;
    if csDesigning in Control.ComponentState then
      g_signal_handlers_disconnect_matched(FInfo.CoreWidget, G_SIGNAL_MATCH_DATA,
        0, 0, nil, nil, Control);
    gtk_widget_destroy(FInfo.ClientWidget);
    InspectView := webkit_web_view_new;
    FInfo.ClientWidget := PgtkWidget(InspectView);
    gtk_container_add(GTK_CONTAINER(FInfo.CoreWidget), FInfo.ClientWidget);
    g_object_set_data(PGObject(FInfo.ClientWidget), 'widgetinfo', FInfo);
    g_signal_connect(Inspector, 'inspect-web-view', G_CALLBACK(@WebInspectorShow), InspectView);
    webkit_web_inspector_show(Inspector);
    if csDesigning in Control.ComponentState then
      TGtk2WSWinControl.SetCallbacks(PGtkObject(FInfo.CoreWidget), Control);
  end
  else
  begin
    InspectView :=  PWebKitWebView(FInfo.ClientWidget);
    webkit_web_inspector_close(Inspector);
    webkit_web_view_load_uri(InspectView, 'about:blank');
  end;
end;

procedure TWebInspector.Connect(Widget: IWidget);
var
  WasActive: Boolean;
  B: IWebBrowser;
begin
  B := nil;
  if Widget <> nil then
    B := Widget as IWebBrowser;
  if B = FWebBrowser then
    Exit;
  WasActive := FActive;
  SetActive(False);
  FWebBrowser := B;
  SetActive(WasActive);
end;

{ TWSWebBrowserControl }

function WebInspectorExpose(Widget: PWebKitWebView; Event: PGdkEventExpose;
  Control: IWebInspectorControl): GBoolean; cdecl;
begin
  g_signal_handlers_disconnect_by_func(Widget, @WebInspectorExpose, Pointer(Control));
  Control.Widget.Active := Control.Widget.Active;
  Result := False;
end;

type
  TWSWebInspectorControl = class(TGtk2WSCustomControl)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
  end;

class function TWSWebInspectorControl.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  Info: PWidgetInfo;
  Allocation: TGTKAllocation;
  Control: IWebInspectorControl;
begin
  { Initialize widget info }
  Info := CreateWidgetInfo(gtk_scrolled_window_new(nil, nil), AWinControl, AParams);
  Info.LCLObject := AWinControl;
  Info.Style := AParams.Style;
  Info.ExStyle := AParams.ExStyle;
  Info.WndProc := PtrUInt(AParams.WindowClass.lpfnWndProc);
  { Configure core and client }
  gtk_scrolled_window_set_policy(PGtkScrolledWindow(Info.CoreWidget), GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
  Info.ClientWidget := GTK_WIDGET(webkit_web_view_new);
  Control := AWinControl as IWebInspectorControl;
  Control.Widget.Info := Info;
  gtk_container_add(GTK_CONTAINER(Info.CoreWidget), Info.ClientWidget);
  g_object_set_data(PGObject(Info.ClientWidget), 'widgetinfo', Info);
  g_signal_connect(Info.ClientWidget, 'expose-event', G_CALLBACK(@WebInspectorExpose), Control);
  gtk_widget_show_all(Info.CoreWidget);
  Allocation.X := AParams.X;
  Allocation.Y := AParams.Y;
  Allocation.Width := AParams.Width;
  Allocation.Height := AParams.Height;
  gtk_widget_size_allocate(Info.CoreWidget, @Allocation);
  if csDesigning in AWinControl.ComponentState then
    TGtk2WSWinControl.SetCallbacks(PGtkObject(Info.CoreWidget), AWinControl);
  Result := TLCLIntfHandle(Info.CoreWidget);
end;

class procedure TWSWebInspectorControl.DestroyHandle(const AWinControl: TWinControl);
var
  Control: IWebInspectorControl;
begin
  Control := AWinControl as IWebInspectorControl;
  Control.Widget.Shutdown;
  TWSWinControlClass(ClassParent).DestroyHandle(AWinControl);
end;
{$endregion}

{$region IWebBrowser}
{ TWebBrowser }

type
  TWebBrowser = class(TInterfacedObject, IWidget, IWebBrowser)
  private
    FControl: IWebBrowserControl;
    FInfo: PWidgetInfo;
    FDesignMode: Boolean;
    FSourceView: Boolean;
    FZoomContent: Boolean;
    FZoomFactor: Single;
    function GetWebView: PWebKitWebView;
  protected
    function GetInfo: Pointer;
    procedure SetInfo(Value: Pointer);
    procedure Shutdown;
    function GetDesignMode: Boolean;
    procedure SetDesignMode(Value: Boolean);
    function GetLocation: string;
    function GetSourceView: Boolean;
    procedure SetSourceView(Value: Boolean);
    function GetLoadStatus: TWebLoadStatus;
    function GetTitle: string;
    function GetZoomContent: Boolean;
    procedure SetZoomContent(Value: Boolean);
    function GetZoomFactor: Single;
    procedure SetZoomFactor(Value: Single);
    procedure Load(const Uri: string);
    procedure LoadHtml(const Html: string);
    procedure Stop;
    procedure Reload;
    procedure ExecuteScript(Script: string);
    function Snapshot: TGraphic;
    procedure BackOrForward(Direction: Integer);
    function BackOrForwardExists(Direction: Integer): Boolean;
    property Location: string read GetLocation;
    property SourceView: Boolean read GetSourceView write SetSourceView;
    property Status: TWebLoadStatus read GetLoadStatus;
    property Title: string read GetTitle;
    property ZoomContent: Boolean read GetZoomContent write SetZoomContent;
    property ZoomFactor: Single read GetZoomFactor write SetZoomFactor;
  public
    constructor Create(Control: IWebBrowserControl);
    property WebView: PWebKitWebView read GetWebView;
  end;

constructor TWebBrowser.Create(Control: IWebBrowserControl);
begin
  inherited Create;
  FControl := Control;
  FZoomFactor := 1;
end;

function TWebBrowser.GetWebView: PWebKitWebView;
begin
  if FInfo = nil then
    Exit(nil);
  Result := PWebKitWebView(FInfo.ClientWidget);
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
  Result := webkit_web_view_get_uri(WebView);
end;

function TWebBrowser.GetDesignMode: Boolean;
begin
  Result := FDesignMode;
  if FInfo = nil then
    Exit;
  Result := webkit_web_view_get_editable(WebView);
end;

procedure TWebBrowser.SetDesignMode(Value: Boolean);
begin
  FDesignMode := Value;
  if FInfo = nil then
    Exit;
  webkit_web_view_set_editable(WebView, FDesignMode);
end;

function TWebBrowser.GetSourceView: Boolean;
begin
  Result := FSourceView;
end;

procedure TWebBrowser.SetSourceView(Value: Boolean);
begin
  FSourceView := Value;
  if FInfo = nil then
    Exit;
  webkit_web_view_set_view_source_mode(WebView, FSourceView);
  Reload;
end;

function TWebBrowser.GetLoadStatus: TWebLoadStatus;
begin
  Result := lsProvisional;
  if FInfo = nil then
    Exit;
  Result := TWebLoadStatus(webkit_web_view_get_load_status(WebView));
end;

function TWebBrowser.GetTitle: string;
begin
  Result := '';
  if FInfo = nil then
    Exit;
  Result := webkit_web_view_get_title(WebView);
end;

function TWebBrowser.GetZoomContent: Boolean;
begin
  Result := FZoomContent;
  if FInfo = nil then
    Exit;
  FZoomContent := webkit_web_view_get_full_content_zoom(WebView);
  Result := FZoomContent;
end;

procedure TWebBrowser.SetZoomContent(Value: Boolean);
begin
  FZoomContent := Value;
  if FInfo = nil then
    Exit;
  webkit_web_view_set_full_content_zoom(WebView, Value);
end;

function TWebBrowser.GetZoomFactor: Single;
begin
  Result := FZoomFactor;
  if FInfo = nil then
    Exit;
  FZoomFactor := webkit_web_view_get_zoom_level(WebView);
  Result := FZoomFactor;
end;

procedure TWebBrowser.SetZoomFactor(Value: Single);
begin
  FZoomFactor := Value;
  if FZoomFactor < 0.1 then
    FZoomFactor := 0.1;
  if FInfo = nil then
    Exit;
  webkit_web_view_set_zoom_level(WebView, FZoomFactor);
end;

procedure TWebBrowser.Load(const Uri: string);
begin
  if FInfo = nil then
    Exit;
  FControl.Events.DoProgress(0);
  webkit_web_view_load_uri(WebView, PChar(Uri));
end;

procedure TWebBrowser.LoadHtml(const Html: string);
begin
  if FInfo = nil then
    Exit;
  FControl.Events.DoProgress(0);
  webkit_web_view_load_string(WebView, PChar(Html),
    nil, nil, nil);
end;

procedure TWebBrowser.Stop;
begin
  if FInfo = nil then
    Exit;
  webkit_web_view_stop_loading(WebView);
  FControl.Events.DoProgress(100);
end;

procedure TWebBrowser.Reload;
begin
  if FInfo = nil then
    Exit;
  FControl.Events.DoProgress(0);
  webkit_web_view_reload(WebView);
end;

procedure TWebBrowser.ExecuteScript(Script: string);
begin
  if FInfo = nil then
    Exit;
  if Script <> '' then
    webkit_web_view_execute_script(WebView, PChar(Script));
end;

function WritePng(closure: Pointer; data: PByte; length: LongWord): cairo_status_t; cdecl;
var
  Stream: TStream absolute closure;
begin
  Stream.Write(data^, length);
  Result := CAIRO_STATUS_SUCCESS;
end;

function TWebBrowser.Snapshot: TGraphic;
var
  Stream: TStream;
  Surface: Pcairo_surface_t;
begin
  if FInfo = nil then
    Exit(TBitmap.Create);
  Stream := TMemoryStream.Create;
  Surface := Pcairo_surface_t(webkit_web_view_get_snapshot(WebView));
  try
    cairo_surface_write_to_png_stream(Surface, WritePng, Stream);
    Result := GraphicFromStream(Stream);
  finally
    g_object_unref(Surface);
    Stream.Free;
  end;
end;

procedure TWebBrowser.BackOrForward(Direction: Integer);
begin
  if FInfo = nil then
    Exit;
  webkit_web_view_go_back_or_forward(PWebKitWebView(FInfo.ClientWidget), Direction);
end;

function TWebBrowser.BackOrForwardExists(Direction: Integer): Boolean;
begin
  if FInfo = nil then
    Exit(False);
  Result := webkit_web_view_can_go_back_or_forward(PWebKitWebView(FInfo.ClientWidget), Direction);
end;

{ IWebBrowserControl Gdk object signals }

procedure WebRequestStarted(Widget: PWebKitWebView; Frame: PWebKitWebFrame;
  Resource: PWebKitWebResource; Request: PWebKitNetworkRequest;
  Response: PWebKitNetworkResponse; Control: IWebBrowserControl); cdecl;
var
  A, B: string;
begin
  A := webkit_network_request_get_uri(Request);
  B := A;
  Control.Events.DoRequest(B);
  if A <> B then
    webkit_network_request_set_uri(Request, PChar(B));
end;

function WebBrowserError(Widget: PGtkWidget; Frame: PWebKitWebFrame; Uri: PChar;
  Error: PGError; Control: IWebBrowserControl): GBoolean; cdecl;
var
  Handled: Boolean;
begin
  Handled := False;
  Control.Events.DoError(Uri, Error.code, Error.message, Handled);
  Result := Handled;
end;

function WebBrowserExpose(Widget: PWebKitWebView; Event: PGdkEventExpose;
  Control: IWebBrowserControl): GBoolean; cdecl;
begin
  g_signal_handlers_disconnect_by_func(Widget, @WebBrowserExpose, Control);
  webkit_web_view_set_view_source_mode(PWebKitWebView(Widget), Control.Widget.SourceView);
  Control.Events.DoReady;
  Result := False;
end;

function HandleHitTest(Control: IWebBrowserControl;
  HitResult: PWebKitHitTestResult; IsContextMenu: Boolean): Boolean;
var
  HitTest: TWebHitTest;
  Link, Media: string;
  Handled: Boolean;
  H: LongWord;
  L, I, M: PChar;
  X, Y: LongInt;
begin
  H := 0;
  g_object_get(HitResult, 'context', @H, 'link-uri', @L, 'image-uri', @I,
    'media-uri', @M, 'x'#0, @X, 'y'#0, @Y, nil);
  Link := L;
  Media := I;
  if Media = '' then
    Media := M;
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
  Handled := False;
  if IsContextMenu then
    Control.Events.DoContextMenu(X, Y,  HitTest, Link, Media,
      Handled)
  else
    Control.Events.DoHitTest(X, Y,  HitTest, Link, Media);
  Result := Handled;
end;

function WebBrowserMotion(Widget: PWebKitWebView; Event: PGdkEventMotion;
  Control: IWebBrowserControl): GBoolean; cdecl;
var
  HitResult: PWebKitHitTestResult;
begin
  HitResult := webkit_web_view_get_hit_test_result(Widget, Event);
  try
    Result := HandleHitTest(Control, HitResult, False);
  finally
    g_object_unref(HitResult);
  end;
end;

function WebBrowserContextMenu(Widget: PWebKitWebView; DefaultMenu: PGtkWidget;
  HitResult: PWebKitHitTestResult; Keyboard: GBoolean; Control: IWebBrowserControl): GBoolean; cdecl;
begin
  Result := HandleHitTest(Control, HitResult, True);
end;

function WebBrowserNavigate(WebView: PWebKitWebView; Frame: PWebKitNetworkRequest;
  Request: PWebKitNetworkRequest; Control: IWebBrowserControl): TWebKitNavigationResponse; cdecl;
var
  Uri: string;
  Action: TWebNavigateAction;
begin
  Uri := webkit_network_request_get_uri(Request);
  Action := naAllow;
  Control.Events.DoNavigate(Uri, Action);
  Result := TWebKitNavigationResponse(Action);
end;

procedure WebBrowserLoadProgress(WebView: PWebKitWebView; Progress: Integer; Control: IWebBrowserControl); cdecl;
begin
  Control.Events.DoProgress(Progress);
end;

type
  TGdkPixbufSaveFunc = function(buffer: PGChar; count: GSize; error: PPGError;
    data: GPointer): GBoolean; cdecl;

function gdk_pixbuf_save_to_callback(pixbuf: PGdkPixbuf; save_func: TGdkPixbufSaveFunc;
  data: gpointer; _type: PGChar; error: PPGError; extra: Pointer): GBoolean; cdecl; external gdkpixbuflib;

function SaveCallback(buffer: PGChar; count: GSize; error: PPGError;
  data: GPointer): GBoolean; cdecl;
var
  Stream: TStream absolute data;
begin
  Stream.Write(buffer^, count);
  Result := True;
end;

procedure WebBrowserIconLoaded(WebView: PWebKitWebView; Uri: PChar; Control: IWebBrowserControl); cdecl;
var
  Graphic: TGraphic;
  Stream: TStream;
  Picture: TPicture;
  Pixbuf, Scalebuf: PGdkPixbuf;
begin
  Stream := TMemoryStream.Create;
  Pixbuf := webkit_web_view_get_icon_pixbuf(WebView);
  try
    if Pixbuf <> nil then
    begin
      { We force all favicons to be 16x16 pixels }
      Scalebuf := gdk_pixbuf_scale_simple(Pixbuf, 16, 16, GDK_INTERP_BILINEAR);
      try
        gdk_pixbuf_save_to_callback(Scalebuf, @SaveCallback, Stream, 'png', nil, nil);
      finally
        g_object_unref(Scalebuf);
      end;
      Stream.Seek(0, 0);
      Picture := TPicture.Create;
      try
        Picture.LoadFromStream(Stream);
        Control.Events.DoFavicon(Picture.Graphic);
      finally
        Picture.Free;
      end;
    end
    else
    begin
      Graphic := TBitmap.Create;
      try
        Control.Events.DoFavicon(Graphic);
      finally
        Graphic.Free;
      end;
    end;
  finally
    if Pixbuf <> nil then
      g_object_unref(Pixbuf);
    Stream.Free;
  end;
end;

function WebBrowserConsoleMessage(WebView: PWebKitWebView; Message: PChar;
  Line: Gint; Source: PChar; Control: IWebBrowserControl): Gboolean; cdecl;
begin
  Control.Events.DoConsoleMessage(Message, Source, Line);
  Result := False;
end;

function WebBrowserScriptAlert(WebView: PWebKitWebView; Frame: PWebKitWebFrame;
  Message: PChar; Control: IWebBrowserControl): Gboolean; cdecl;
var
  Input: string;
  Accepted, Handled: Boolean;
begin
  Input := '';
  Accepted := False;
  Handled := False;
  Control.Events.DoScriptDialog(sdAlert, Message, Input, Accepted, Handled);
  Result := True;
end;

function WebBrowserScriptConfirm(WebView: PWebKitWebView; Frame: PWebKitWebFrame;
  Message: PChar; var Confirmed: Boolean; Control: IWebBrowserControl): Gboolean; cdecl;
var
  Input: string;
  Accepted, Handled: Boolean;
begin
  Input := '';
  Accepted := False;
  Handled := False;
  Control.Events.DoScriptDialog(sdConfirm, Message, Input, Accepted, Handled);
  Confirmed := Accepted;
  Result := True;
end;

function WebBrowserScriptPrompt(WebView: PWebKitWebView; Frame: PWebKitWebFrame;
  Message: PChar; Default: PChar; var Text: Pointer; Control: IWebBrowserControl): Gboolean; cdecl;
var
  Input: string;
  Accepted, Handled: Boolean;
  I: LongWord;
begin
  Input := '';
  Accepted := False;
  Handled := False;
  Input := Default;
  Control.Events.DoScriptDialog(sdPrompt, Message, Input, Accepted, Handled);
  if Accepted and (Input <> '') then
  begin
    I := Length(Input) + 1;
    Text := g_malloc(I);
    Move(PChar(Input)^ , Text^, I);
  end
  else
    Text := nil;
  Result := True;
end;

{ TWSWebBrowserControl }

type
  TWSWebBrowserControl = class(TGtk2WSCustomControl)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
  end;

class function TWSWebBrowserControl.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;

  function CreateWebView: PGtkWidget;
  var
    WebView: PWebKitWebView;
    Settings: PWebKitWebSettings;
    B: LongInt;
  begin
    WebView := webkit_web_view_new;
    Settings := webkit_web_view_get_settings(WebView);
    B := 1;
    g_object_set(Settings, 'enable-developer-extras', B, 'enable-fullscreen', B,
      'enable-webgl', B, 'enable-page-cache', B, 'enable-file-access-from-file-uris', B,
      'javascript-can-access-clipboard', B, nil);
    Result := PGtkWidget(WebView);
  end;

var
  Info: PWidgetInfo;
  Widget: PGtkWidget;
  Allocation: TGTKAllocation;
  Control: IWebBrowserControl;
begin
  { Initialize widget info }
  Info := CreateWidgetInfo(gtk_scrolled_window_new(nil, nil), AWinControl, AParams);
  Info.LCLObject := AWinControl;
  Info.Style := AParams.Style;
  Info.ExStyle := AParams.ExStyle;
  Info.WndProc := PtrUInt(AParams.WindowClass.lpfnWndProc);
  { Configure core and client }
  gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(Info.CoreWidget), GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
  Info.ClientWidget := CreateWebView;
  Control := AWinControl as IWebBrowserControl;
  Control.Widget.Info := Info;
  gtk_container_add(PGtkContainer(Info.CoreWidget), Info.ClientWidget);
  g_object_set_data(PGObject(Info.ClientWidget), 'widgetinfo', Info);
  Widget := Info.ClientWidget;
  gtk_widget_add_events(Widget, GDK_POINTER_MOTION_MASK);
  g_signal_connect(Widget, 'expose-event', G_CALLBACK(@WebBrowserExpose), Control);
  g_signal_connect(Widget, 'load-error', G_CALLBACK(@WebBrowserError), Control);
  g_signal_connect(Widget, 'resource-request-starting', G_CALLBACK(@WebRequestStarted), Control);
  g_signal_connect(Widget, 'context-menu', G_CALLBACK(@WebBrowserContextMenu), Control);
  g_signal_connect(Widget, 'motion-notify-event', G_CALLBACK(@WebBrowserMotion), Control);
  g_signal_connect(Widget, 'navigation-requested', G_CALLBACK(@WebBrowserNavigate), Control);
  g_signal_connect(Widget, 'load-progress-changed', G_CALLBACK(@WebBrowserLoadProgress), Control);
  g_signal_connect(Widget, 'icon-loaded', G_CALLBACK(@WebBrowserIconLoaded), Control);
  g_signal_connect(Widget, 'console-message', G_CALLBACK(@WebBrowserConsoleMessage), Control);
  g_signal_connect(Widget, 'script-alert', G_CALLBACK(@WebBrowserScriptAlert), Control);
  g_signal_connect(Widget, 'script-confirm', G_CALLBACK(@WebBrowserScriptConfirm), Control);
  g_signal_connect(Widget, 'script-prompt', G_CALLBACK(@WebBrowserScriptPrompt), Control);
  gtk_widget_show_all(Info.CoreWidget);
  Allocation.X := AParams.X;
  Allocation.Y := AParams.Y;
  Allocation.Width := AParams.Width;
  Allocation.Height := AParams.Height;
  gtk_widget_size_allocate(Info.CoreWidget, @Allocation);
  if csDesigning in AWinControl.ComponentState then
    TGtk2WSWinControl.SetCallbacks(PGtkObject(Info.CoreWidget), AWinControl);
  Result := TLCLIntfHandle(Info.CoreWidget);
end;

class procedure TWSWebBrowserControl.DestroyHandle(const AWinControl: TWinControl);
var
  Control: IWebBrowserControl;
  Info: PWidgetInfo;
  Widget: PGtkWidget;
begin
  Control := AWinControl as IWebBrowserControl;
  Info := Control.Widget.Info;
  Widget := Info.ClientWidget;
  g_signal_handlers_disconnect_matched(Widget, G_SIGNAL_MATCH_DATA, 0, 0, nil,
    nil, Control);
  Control.Widget.Shutdown;
  TWSWinControlClass(ClassParent).DestroyHandle(AWinControl);
end;
{$endregion}

function WebControlsAvaiable: Boolean;
begin
  Result := WebControlsLoad;
end;

function WebInspectorNew(Control: IWebInspectorControl): IWebInspector;
begin
  Result := TWebInspector.Create(Control);
end;

function WebInspectorWSClass: TWSLCLComponentClass;
begin
  Result := TWSWebInspectorControl;
end;

function WebBrowserNew(Control: IWebBrowserControl): IWebBrowser;
begin
  Result := TWebBrowser.Create(Control);
end;

function WebBrowserWSClass: TWSLCLComponentClass;
begin
  Result := TWSWebBrowserControl;
end;

{$else}
implementation
{$endif}

end.

