unit divext;

{ extensions to and related to DIVE }

{ constants     }
{ func/proc     }
{ dll interface }

{ 20261005 cre }

interface

uses os2def, mmbase;

const
  wm_VrnDisabled                = $007E; // from os2_os2_vp21/os2pmapi.pas
  wm_VrnEnabled                 = $007F; // os2_os2_vp21/os2pmapi.pas

{ mmbase internal :: dirty(or not) :: copy from unit mmbase where this one is not exported}
Function mmioFOURCC(ch0,ch1,ch2,ch3:Char): Cardinal;

{ pmwin ??? }
function WinQueryVisibleRegion(wnd: cardinal; rgn: cardinal): ULong; cdecl; export;
function WinSetVisibleRegionNotify(hClient: cardinal; select: longbool): longbool; cdecl; export; // boolean or longbool

implementation

{ mmbase internal :: dirty(or not) :: copy from unit mmbase where this one is not exported}
Function mmioFOURCC(ch0,ch1,ch2,ch3:Char): Cardinal;
begin
  mmioFOURCC:=Cardinal(ord(ch0)) or (Cardinal(ord(ch1)) shl 8) or
              (Cardinal(ord(ch2)) shl 16) or (Cardinal(ord(ch3)) shl 24);
end; {mmioFOURCC}

{ pmwin ??? }
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

