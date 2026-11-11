{ mmbase internal :: dirty(or not) :: copy from unit mmbase where this one is not exported}
{ Function mmioFOURCC(ch0,ch1,ch2,ch3:Char): Cardinal; }

{ mmbase internal :: dirty(or not) :: copy from unit mmbase where this one is not exported}
Function mmioFOURCC(ch0,ch1,ch2,ch3:Char): Cardinal;
begin
  mmioFOURCC:=Cardinal(ord(ch0)) or (Cardinal(ord(ch1)) shl 8) or
              (Cardinal(ord(ch2)) shl 16) or (Cardinal(ord(ch3)) shl 24);
end; {mmioFOURCC}

