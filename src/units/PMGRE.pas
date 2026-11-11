// ------------------------------------
//  Some Gre* functions from PMGRE.DLL
// ------------------------------------
unit PMGRE;
interface

{ we need cdecl here }

uses os2def;

type HDC=cardinal;
type long=longint;

function GreDeath(_hdc:HDC):ulong; cdecl;
function GreResurrection(_hdc:HDC; b:long; c:pointer):ulong; cdecl;

implementation

function Gre32Entry3(a:ulong; b:ulong; c:ulong):ulong;cdecl;
external 'PMGRE' index 63;

function Gre32Entry5(a:ulong; b:ulong; c:ulong; d:ulong; e:ulong):ulong;cdecl;
external 'PMGRE' index 65;

function GreDeath(_hdc:HDC):ulong;cdecl;
begin
  GreDeath:=Gre32Entry3(ulong(_hdc), 0, $000040B7)
end;

function GreResurrection(_hdc:HDC; b:long; c:pointer):ulong;cdecl;
begin
  GreResurrection:=Gre32Entry5(ulong(_hdc), ulong(b), ulong(c), 0, $000040B8)
end;

end.
