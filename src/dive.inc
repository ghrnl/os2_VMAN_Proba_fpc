{ workarounds for dive unit issues }

type
      { * Stuff for DiveQueryCaps() * }
      TDIVE_CAPS_ = Record
        ulStructLen   : cardinal;  { * SizeOf(TDIVE_CAPS)       * }
        ulPlaneCount  : cardinal;  { * Number of defined planes * }

        { * Following info applies to ulPlaneID * }
        fScreenDirect : longbool; // was Boolean;  { * Direct screen access (was type BOOL in C) * }
        fBankSwitched : longbool; // was Boolean;  { * VRAM bank-switched? (was type BOOL in C) * }
        ulDepth       : cardinal;  { * Number of bits per pixel * }
        ulHorizontalResolution : cardinal;
        ulVerticalResolution   : cardinal;
        ulScanLineBytes        : cardinal;
        fccColorEncoding       : FourCC;
        ulApertureSize         : cardinal;

        ulInputFormats   : cardinal;   { * Number of input color formats * }
        ulOutputFormats  : cardinal;
        ulFormatLength   : cardinal;   { * Length of format buffer * }
        pFormatData      : Pointer; { * Pointer to format buffer of FOURCC's * }
       End;

      PDIVE_CAPS = ^TDIVE_CAPS_;


Function DiveAllocImageBuffer(hDiveInst       : cardinal;
                          Var ulBufferNumber  : cardinal;
                              fccColorSpace   : FourCC;
                              ulWidth         : cardinal;
                              ulHeight        : cardinal;
                              ulLineSizeBytes : cardinal;
                          {Var} bImageBuffer    : Pointer) : cardinal; cdecl;
External 'DIVE' Index 12;

Function DiveSetDestinationPalette(hDiveInst    : cardinal;
                                   ulStartIndex : cardinal;
                                   ulNumEntries : cardinal;
                               {Var} bRGB2Entries : Pointer) : cardinal; cdecl;
External 'DIVE' Index 9;

Function DiveSetSourcePalette(hDiveInst    : cardinal;
                              ulStartIndex : cardinal;
                              ulNumEntries : cardinal;
                          {Var} bRGB2Entries : Pointer) : cardinal; cdecl;
External 'DIVE' Index 10;
