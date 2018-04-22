unit WebkitGtk;

{$i webbrowser.inc}

interface

{$ifdef lclgtkall}
{$Z4}
type
  gint = Integer;
  gfloat = Single;
  gdouble = Double;
  gboolean = LongBool;
  PCairoSurface = Pointer;

  PWebKitWebView = ^TWebKitWebView;
  TWebKitWebView = record  end;

  PWebKitWebFrame = ^TWebKitWebFrame;
  TWebKitWebFrame = record end;

  PWebKitDOMDocument = ^TWebKitDOMDocument;
  TWebKitDOMDocument = record end;

  PWebKitWebInspector = ^TWebKitWebInspector;
  TWebKitWebInspector = record end;

  PWebKitWebSettings = ^TWebKitWebSettings;
  TWebKitWebSettings = record end;

  PWebKitHitTestResult = ^TWebKitHitTestResult;
  TWebKitHitTestResult = record  end;

  PWebKitNetworkRequest = ^TWebKitNetworkRequest;
  TWebKitNetworkRequest = record end;

  PWebKitNetworkResponse = ^TWebKitNetworkResponse;
  TWebKitNetworkResponse = record end;

  PWebKitWebResource = ^TWebKitWebResource;
  TWebKitWebResource = record end;

  TWebKitLoadStatus = (
    WEBKIT_LOAD_PROVISIONAL,
    WEBKIT_LOAD_COMMITTED,
    WEBKIT_LOAD_FINISHED,
    WEBKIT_LOAD_FIRST_VISUALLY_NON_EMPTY_LAYOUT,
    WEBKIT_LOAD_FAILED
  );

  TWebKitNavigationResponse = (
    WEBKIT_NAVIGATION_RESPONSE_ACCEPT,
    WEBKIT_NAVIGATION_RESPONSE_IGNORE,
    WEBKIT_NAVIGATION_RESPONSE_DOWNLOAD
  );

  TWebKitWebViewTargetInfo = (
    WEBKIT_WEB_VIEW_TARGET_INFO_HTML,
    WEBKIT_WEB_VIEW_TARGET_INFO_TEXT,
    WEBKIT_WEB_VIEW_TARGET_INFO_IMAGE,
    WEBKIT_WEB_VIEW_TARGET_INFO_URI_LIST,
    WEBKIT_WEB_VIEW_TARGET_INFO_NETSCAPE_URL
  );

  TWebKitWebViewViewMode = (
    WEBKIT_WEB_VIEW_VIEW_MODE_WINDOWED,
    WEBKIT_WEB_VIEW_VIEW_MODE_FLOATING,
    WEBKIT_WEB_VIEW_VIEW_MODE_FULLSCREEN,
    WEBKIT_WEB_VIEW_VIEW_MODE_MAXIMIZED,
    WEBKIT_WEB_VIEW_VIEW_MODE_MINIMIZED
  );

  TWebKitSelectionAffinity = (
    WEBKIT_SELECTION_AFFINITY_UPSTREAM,
    WEBKIT_SELECTION_AFFINITY_DOWNSTREAM
  );

  TWebKitInsertAction = (
    WEBKIT_INSERT_ACTION_TYPED,
    WEBKIT_INSERT_ACTION_PASTED,
    WEBKIT_INSERT_ACTION_DROPPED
  );

const
  WEBKIT_HIT_TEST_RESULT_CONTEXT_DOCUMENT   = $2;
  WEBKIT_HIT_TEST_RESULT_CONTEXT_LINK       = $4;
  WEBKIT_HIT_TEST_RESULT_CONTEXT_IMAGE      = $8;
  WEBKIT_HIT_TEST_RESULT_CONTEXT_MEDIA      = $10;
  WEBKIT_HIT_TEST_RESULT_CONTEXT_SELECTION  = $20;
  WEBKIT_HIT_TEST_RESULT_CONTEXT_EDITABLE   = $40;

var
  webkit_web_view_new: function: PWebKitWebView; cdecl;
  webkit_web_view_get_uri: function(web_view: PWebKitWebView): PChar; cdecl;
  webkit_web_view_get_title: function(web_view: PWebKitWebView): PChar; cdecl;
  webkit_web_view_load_uri: procedure(web_view: PWebKitWebView; uri: PChar); cdecl;
  webkit_web_view_load_string: procedure(web_view: PWebKitWebView; const content, mime_type, encoding, base_uri: PChar); cdecl;
  webkit_web_view_get_load_status: function(web_view: PWebKitWebView): TWebKitLoadStatus; cdecl;
  webkit_web_view_stop_loading: procedure(web_view: PWebKitWebView); cdecl;
  webkit_web_view_reload: procedure(web_view: PWebKitWebView); cdecl;
  webkit_web_view_can_go_back_or_forward: function(web_view: PWebKitWebView; steps: gint): gboolean; cdecl;
  webkit_web_view_go_back_or_forward: procedure(web_view: PWebKitWebView; steps: gint); cdecl;
  webkit_web_view_go_back: procedure(web_view: PWebKitWebView); cdecl;
  webkit_web_view_go_forward: procedure(web_view: PWebKitWebView); cdecl;
  webkit_web_view_get_editable: function(web_view: PWebKitWebView): Gboolean; cdecl;
  webkit_web_view_set_editable: procedure(web_view: PWebKitWebView; flag: Gboolean); cdecl;
  webkit_web_view_execute_script: procedure(web_view: PWebKitWebView; script: PChar); cdecl;
  webkit_web_view_set_view_mode: procedure(web_view: PWebKitWebView; mode: TWebKitWebViewViewMode); cdecl;
  webkit_web_view_set_view_source_mode: procedure(web_view: PWebKitWebView; view_source_mode: gboolean); cdecl;
  webkit_web_view_get_inspector: function(web_view: PWebKitWebView): PWebKitWebInspector; cdecl;
  webkit_web_inspector_show: procedure(web_inspector: PWebKitWebInspector); cdecl;
  webkit_web_inspector_close: procedure(web_inspector: PWebKitWebInspector); cdecl;
  webkit_web_inspector_inspect_coordinates: procedure(web_inspector: PWebKitWebInspector; x, y: gdouble); cdecl;
  webkit_web_view_get_hit_test_result: function(web_view: PWebKitWebView; event: Pointer): PWebKitHitTestResult; cdecl;
  webkit_network_request_get_uri: function(request: PWebKitNetworkRequest): PChar; cdecl;
  webkit_network_request_set_uri: procedure(request: PWebKitNetworkRequest; uri: PChar); cdecl;
  webkit_web_view_get_full_content_zoom: function(web_view: PWebKitWebView): gboolean; cdecl;
  webkit_web_view_set_full_content_zoom: procedure(web_view: PWebKitWebView; full_content_zoom: gboolean); cdecl;
  webkit_web_view_get_zoom_level: function(web_view: PWebKitWebView): gfloat; cdecl;
  webkit_web_view_set_zoom_level: procedure(web_view: PWebKitWebView; zoom_level: gfloat); cdecl;
  webkit_web_view_get_icon_pixbuf: function(web_view: PWebKitWebView): Pointer; cdecl;
  webkit_web_view_try_get_favicon_pixbuf: function(web_view: PWebKitWebView; width, height: gfloat): Pointer; cdecl;
  webkit_web_view_get_snapshot: function(web_view: PWebKitWebView): PCairoSurface; cdecl;
  webkit_web_view_get_settings: function(web_view: PWebKitWebView): PWebKitWebSettings; cdecl;
  webkit_web_settings_get_user_agent: function(web_settings: PWebKitWebSettings): PChar; cdecl;

function WebControlsLoad: Boolean;

implementation

var
  Initialized: Boolean;
  Loaded: Boolean;

function WebControlsLoad: Boolean;
const
  {$ifdef lclgtk2}
  webkit = 'libwebkitgtk-1.0.so.0';
  {$endif}
  {$ifdef lclgtk3}
  webkit = 'libwebkitgtk-3.0.so.0';
  {$endif}
var
  Lib: TLibHandle;

  function Load(const ProcName : string; out Proc: Pointer): Boolean;
  begin
    Proc := GetProcAddress(Lib, ProcName);
    Result := Proc <> nil;
  end;

begin
  if Initialized then
    Exit(Loaded);
  Initialized := True;
  Lib := LoadLibrary(webkit);
  if Lib = 0 then
    Exit(Loaded);
  Loaded :=
    Load('webkit_web_view_new', @webkit_web_view_new) and
    Load('webkit_web_view_get_uri', @webkit_web_view_get_uri) and
    Load('webkit_web_view_get_title', @webkit_web_view_get_title) and
    Load('webkit_web_view_load_uri', @webkit_web_view_load_uri) and
    Load('webkit_web_view_load_string', @webkit_web_view_load_string) and
    Load('webkit_web_view_get_load_status', @webkit_web_view_get_load_status) and
    Load('webkit_web_view_stop_loading', @webkit_web_view_stop_loading) and
    Load('webkit_web_view_reload', @webkit_web_view_reload) and
    Load('webkit_web_view_can_go_back_or_forward', @webkit_web_view_can_go_back_or_forward) and
    Load('webkit_web_view_go_back_or_forward', @webkit_web_view_go_back_or_forward) and
    Load('webkit_web_view_go_back', @webkit_web_view_go_back) and
    Load('webkit_web_view_go_forward', @webkit_web_view_go_forward) and
    Load('webkit_web_view_get_editable', @webkit_web_view_get_editable) and
    Load('webkit_web_view_set_editable', @webkit_web_view_set_editable) and
    Load('webkit_web_view_execute_script', @webkit_web_view_execute_script) and
    Load('webkit_web_view_set_view_mode', @webkit_web_view_set_view_mode) and
    Load('webkit_web_view_set_view_source_mode', @webkit_web_view_set_view_source_mode) and
    Load('webkit_web_view_get_inspector', @webkit_web_view_get_inspector) and
    Load('webkit_web_inspector_show', @webkit_web_inspector_show) and
    Load('webkit_web_inspector_close', @webkit_web_inspector_close) and
    Load('webkit_web_inspector_inspect_coordinates', @webkit_web_inspector_inspect_coordinates) and
    Load('webkit_web_view_get_hit_test_result', @webkit_web_view_get_hit_test_result) and
    Load('webkit_network_request_get_uri', @webkit_network_request_get_uri) and
    Load('webkit_network_request_set_uri', @webkit_network_request_set_uri) and
    Load('webkit_web_view_get_full_content_zoom', @webkit_web_view_get_full_content_zoom) and
    Load('webkit_web_view_set_full_content_zoom', @webkit_web_view_set_full_content_zoom) and
    Load('webkit_web_view_get_zoom_level', @webkit_web_view_get_zoom_level) and
    Load('webkit_web_view_set_zoom_level', @webkit_web_view_set_zoom_level) and
    Load('webkit_web_view_get_icon_pixbuf', @webkit_web_view_get_icon_pixbuf) and
    Load('webkit_web_view_try_get_favicon_pixbuf', @webkit_web_view_try_get_favicon_pixbuf) and
    Load('webkit_web_view_get_snapshot', @webkit_web_view_get_snapshot) and
    Load('webkit_web_view_get_settings', @webkit_web_view_get_settings) and
    Load('webkit_web_settings_get_user_agent', @webkit_web_settings_get_user_agent);
  Result := Loaded;
end;

{$else}
implementation
{$endif}

end.
