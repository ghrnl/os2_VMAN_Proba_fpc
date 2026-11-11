{ workarounds for pmgpi unit issues }

function GpiCreateRegion(hps : cardinal;lCount : longint; arclRectangles : pRECTL) : cardinal; cdecl; external 'pmgpi' index 370;
function GpiQueryRegionRects(hps,hrgn : cardinal; prclBound : pRECTL;var prgnrcControl : RGNRECT;var prclRect : RECTL) : longbool; cdecl; external 'pmgpi' index 587;

