unit divext;

{ extensions to and related to DIVE, from pmwin.dll }

{ constants     }
{ func/proc     }
{ dll interface }

{ 20261005 cre }
{ 20261110 upd }

interface

uses os2def;

const
  wm_VrnDisabled                = $007E; // from os2_os2_vp21/os2pmapi.pas
  wm_VrnEnabled                 = $007F; // from os2_os2_vp21/os2pmapi.pas

{ pmwin }
function WinQueryVisibleRegion(wnd: cardinal; rgn: cardinal): ULong; cdecl;
function WinSetVisibleRegionNotify(hClient: cardinal; select: longbool): longbool; cdecl;

implementation

{ pmwin }
{ [20261005] From toolkit: inc/bseord.inc: }
const
  ORD_WIN32QUERYVISIBLEREGION = 1000;
  ORD_WIN32SETVISIBLEREGIONNOTIFY = 1001;

{ VP: os2_os2_vp21/os2pmapi.pas: function WinQueryVisibleRegion(Wnd: HWnd; Rgn: HRgn): ULong;}
function WinQueryVisibleRegion(wnd: cardinal; rgn: cardinal): ULong; cdecl;
external 'PMWIN' index ORD_WIN32QUERYVISIBLEREGION;

{ VP: os2_os2_vp21/os2pmapi.pas:function WinSetVisibleRegionNotify(Wnd: HWnd; fEnable: Bool): Bool;}
function  WinSetVisibleRegionNotify(hClient: cardinal; select: longbool): longbool; cdecl;
external 'PMWIN' index ORD_WIN32SETVISIBLEREGIONNOTIFY;

end.

