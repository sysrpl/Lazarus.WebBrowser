unit WebBrowserIntf;

{$i webbrowser.inc}

interface

uses
  Graphics;

type
  TWebHitTest = set of (
    { Mouse is over a hyper link }
    htLink,
    { Mouse is over an image element }
    htImage,
    { Mouse is over an audio or video element }
    htMedia,
    { Mouse is over selected text or other selected elements }
    htSelection,
    { Mouse is over an area where the user can type }
    htEditable);

  TWebNavigateAction = (
    { Allow the browser to view or download content generated from a navigation }
    naAllow,
    { Block the browser from following a link or downloading content }
    naDeny,
    { Force the content to be downloaded rather than viewed }
    naDownload);

  TWebLoadStatus = (
    { Load started but may fail }
    lsProvisional,
    { Load has received the first resposne }
    lsCommited,
    { Load is complete }
    lsComplete,
    { Load has received the first layout information }
    lsLayout,
    { Load stopped with an error }
    lsFailed);

  TWebScriptDialog = (
    { Javascript asked to display an alert message }
    sdAlert,
    { Javascript asked to to confirmation an action }
    sdConfirm,
    { Javascript asked to prompt for a value }
    sdPrompt
  );

{ IWidget }

  IWidget = interface
  ['{0BE18663-CC04-46E6-8AC9-3866183E2B20}']
    function GetInfo: Pointer;
    procedure SetInfo(Value: Pointer);
    procedure Shutdown;
    property Info: Pointer read GetInfo write SetInfo;
  end;

{ IControl<T> }

  IControl<T> = interface
  ['{2070A053-5566-4C45-9071-42CB2DBCCDCD}']
    function GetWidget: T;
    property Widget: T read GetWidget;
  end;

{ IWebInspector }

  IWebInspector = interface(IWidget)
  ['{5C7427B4-C256-49F5-98CC-4E240FFDB099}']
    function GetActive: Boolean;
    procedure SetActive(Value: Boolean);
    procedure Connect(Widget: IWidget);
    property Active: Boolean read GetActive write SetActive;
  end;

{ IWebInspectorControl }

  IWebInspectorControl = interface(IControl<IWebInspector>)
  ['{CF06164C-631D-4923-9CC3-DAA1A92B08D9}']
  end;

{ IWebBrowser }

  IWebBrowser = interface(IWidget)
  ['{69D2B830-4F14-4371-8A59-828BEA1373DA}']
    function GetDesignMode: Boolean;
    procedure SetDesignMode(Value: Boolean);
    function GetLocation: string;
    function GetSourceView: Boolean;
    procedure SetSourceView(Value: Boolean);
    function GetLoadStatus: TWebLoadStatus;
    function GetTitle: string;
    procedure Load(const Uri: string);
    procedure LoadHtml(const Html: string);
    function GetZoomContent: Boolean;
    procedure SetZoomContent(Value: Boolean);
    function GetZoomFactor: Single;
    procedure SetZoomFactor(Value: Single);
    procedure Stop;
    procedure Reload;
    procedure ExecuteScript(Script: string);
    function Snapshot: TGraphic;
    procedure BackOrForward(Steps: Integer);
    function BackOrForwardExists(Steps: Integer): Boolean;
    property DesignMode: Boolean read GetDesignMode write SetDesignMode;
    property Location: string read GetLocation;
    property SourceView: Boolean read GetSourceView write SetSourceView;
    property LoadStatus: TWebLoadStatus read GetLoadStatus;
    property Title: string read GetTitle;
    property ZoomContent: Boolean read GetZoomContent write SetZoomContent;
    property ZoomFactor: Single read GetZoomFactor write SetZoomFactor;
  end;

{ IWebBrowserEvents }

  IWebBrowserEvents = interface
  ['{10ABB5BE-E8E9-447A-9EF8-4357FA25C329}']
    procedure DoError(const Uri: string; ErrorCode: LongWord; const ErrorMessage: string; var Handled: Boolean);
    procedure DoReady;
    procedure DoRequest(var Uri: string);
    procedure DoContextMenu(X, Y: Integer; HitTest: TWebHitTest; const Link, Media: string; var Handled: Boolean);
    procedure DoHitTest(X, Y: Integer; HitTest: TWebHitTest; const Link, Media: string);
    procedure DoLoadStatusChange;
    procedure DoLocationChange;
    procedure DoNavigate(const Uri: string; var Action: TWebNavigateAction);
    procedure DoProgress(Progress: Integer);
    procedure DoFavicon(Icon: TGraphic);
    procedure DoConsoleMessage(const Message, Source: string; Line: Integer);
    procedure DoScriptDialog(Dialog: TWebScriptDialog; const Message: string;
      var Input: string; var Accepted: Boolean; var Handled: Boolean);
  end;

{ IWebBrowserControl }

  IWebBrowserControl = interface(IControl<IWebBrowser>)
  ['{E2074F6A-DE6F-4D5C-8CB1-CD4CFF8A150F}']
    function GetEvents: IWebBrowserEvents;
    procedure AddNotification(Notify: IWebBrowserEvents);
    procedure RemoveNotification(Notify: IWebBrowserEvents);
    property Events: IWebBrowserEvents read GetEvents;
  end;

implementation

end.

