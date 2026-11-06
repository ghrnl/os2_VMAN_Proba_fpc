Program GMIS;

{ 2026 for FPC 3.2.2 G. H. Renkema }

{$APPTYPE GUI}
{$MODE DELPHI}

uses os2def, doscalls, pmwin, pmgpi, mmbase, GRADD, DIVE, divext, sysutils;

{-------------------------------------------------------------------}

{$i pmgpi.inc}
{$i dive.inc}

{-------------------------------------------------------------------}

type apiret=cardinal;
var logfile: text;

var cmdfile: text;

{-------------------------------------------------------------------}

var hmodVMAN:longint;            // Handle of loaded VMAN.DLL module
    VMIEntry:FNVMIENTRY;         // The entry of VMAN.DLL
    NumVideoModes:longint;       // Number of supported video modes
    ModeInfo:pGDDModeInfo;       // List of all supported video modes
    DesktopModeInfo:GDDModeInfo; // One video mode, that is used as desktop
    NewModeInfo:pGDDModeInfo;    // New video mode for fullscreen

const AppTitle:pchar='VMAN and FSDIVE Test Application: GRADD caps';
      FULLSCREENWIDTH:longint=640;      // Parameters of the fullscreen mode we want to use
      FULLSCREENHEIGHT:longint=480;
      FULLSCREENBPP:longint=32;
      SRCBUFFERWIDTH:longint=640;       // Parameters of the source buffer
      SRCBUFFERHEIGHT:longint=480;
      SRCBUFFERFOURCC:ulong=ord('L') +
                            ord('U') shl 8 +
                            ord('T') shl 16 +
                            ord('8') shl 24;

var ab:HAB;                   // Anchor block
    mq:HMQ;                   // Message queue
    hFrame, hClient:HWND;     // Window handle of frame and client
    hDiveInst: hDive;         // Dive instance number
    ulImage:ulong;            // Handle of image buffer allocated by Dive
    
// ----------------------------------------- VMAN --------------------------------------

///////////////////////////////////////
// UnloadVMAN
//
// Unloads VMAN.DLL
//
function UnloadVMAN:boolean;
begin
  result:=(DosFreeModule(hmodVMAN)=no_error);
  Writeln(logfile,'VMAN Unloaded!');
end;
///////////////////////////////////////
// LoadVMAN
//
// Loads VMAN.DLL and queries its entry
// point into VMIEntry variable
//
function LoadVMAN:boolean;
var rc:apiret;
// var pVMIEntry: ^FNVMIENTRY;
begin
  rc:=DosLoadModule(Nil, 0, 'VMAN.DLL', hmodVMAN);                   // Load VMAN.DLL
  if rc<>no_error then
  begin  // No VMAN.DLL... Maybe no GRADD driver installed???
    writeln(logfile,'Could not load VMAN! rc=',rc);
    result:=false;
    exit;
  end;
  // rc:=DosQueryProcAddr(hmodVMAN, 0, 'VMIEntry', {pfn(} @VMIEntry {)}); // Query entry point address
  rc:=DosQueryProcAddr(hmodVMAN, 0, 'VMIEntry', pointer(@VMIEntry)); // Query entry point address
  if rc<>no_error then
  begin
    writeln(logfile,'Could not query VMIEntry address! rc=',rc);
    UnloadVMAN;
  end;
  result:=(rc=no_error);
end;

///////////////////////////////////////
// InitVMIEntry
//
// Sends a INITPROC command to VMAN, so
// informs VMAN that a new process is
// about to use its services
//
function InitVMIEntry:boolean;
var rc:apiret;
    ipo:INITPROCOUT;
begin
  rc:=VMIEntry(0, VMI_CMD_INITPROC, nil, @ipo);
  if rc<>no_error then
  begin
    writeln(logfile,'VMI_CMD_INITPROC rc=',rc);
  end;
  result:=rc=no_error;
end;

///////////////////////////////////////
// UninitVMIEntry
//
// Sends a TERMPROC command to VMAN, so
// informs VMAN that this process has
// stopped using its services
//
function UninitVMIEntry:boolean;
var rc:apiret;
begin
  rc:=VMIEntry(0, VMI_CMD_TERMPROC, nil, nil);
  if rc<>no_error then
  begin
    writeln(logfile,'VMI_CMD_TERMPROC rc=',rc);
  end;
  result:=rc=no_error;
end;

///////////////////////////////////////
// QueryModeInfo
//
// Queries the number of available video
// modes to NumVideoModes, allocates memory
// for information of all the video modes,
// and queries video mode informations into
// ModeInfo.
//
function QueryModeInfo:boolean;
var rc:apiret;
    ModeOperation:longint;
begin
  result:=false;

  ModeOperation:=QUERYMODE_NUM_MODES;
  rc:=VMIEntry(0, VMI_CMD_QUERYMODES, @ModeOperation, @NumVideoModes);
  if rc<>no_error then
  begin
    NumVideoModes:=0;
    writeln(logfile,'VMI_CMD_QUERYMODES rc=',rc);
    exit;
  end;
  getmem(ModeInfo,NumVideoModes*sizeof(GDDModeInfo));
  if ModeInfo=Nil then
  begin
    Writeln(logfile,'Could not allocate memory for ModeInfo list!');
    NumVideoModes:=0;
    exit;
  end;

  ModeOperation:=QUERYMODE_MODE_DATA;
  rc:=VMIEntry(0, VMI_CMD_QUERYMODES, @ModeOperation, ModeInfo);
  if rc<>no_error then
  begin
    writeln(logfile,'Could not query ModeInfo list! rc=',rc);
    freemem(ModeInfo); ModeInfo:=Nil;
    NumVideoModes:=0;
    exit;
  end;
  result:=true;
end;

///////////////////////////////////////
// FreeModeInfo
//
// Frees the memory allocated by
// QueryModeInfo
//
function FreeModeInfo:boolean;
begin
  freemem(ModeInfo); ModeInfo:=Nil;
  NumVideoModes:=0;
  result:=true;
end;

////////////////////////////////////////
// Some helper functions/procedures
//
function FourCCToString(fcc:ulong):string;
begin
  if fcc=0 then result:='' else
  result:=chr((fcc and $FF))+
          chr((fcc and $FF00) shr 8)+
          chr((fcc and $FF0000) shr 16)+
          chr((fcc and $FF000000) shr 24);
end;

procedure WriteModeInfo(OneModeInfo:pGDDModeInfo);
begin
  with OneModeInfo^ do
  begin
    writeln(logfile,'Mode ID: ',ulModeID);
    writeln(logfile,'  ',ulHorizResolution,'x',ulVertResolution,'/',ulBpp,'  (',ulRefreshRate,' Hz)');
    writeln(logfile,'  Num of colors: ',cColors,' FourCC: ',FourCCToString(fccColorEncoding));
  end;
end;

procedure WriteModeInfoCmd(OneModeInfo:pGDDModeInfo);
// writes  CMD file for vman_proba based on the caps found here
// fmt progname xresxyesxcdeth xresxyesxFOURCC
const
  progname = 'vman_proba';
  // scmdfile = 'tryit.cmd';
var
  // cmdfile: text;
  s0,s1,s2: string;
begin
  // assign(cmdfile,scmdfile); rewrite
  with OneModeInfo^ do
  begin
    write(cmdfile,'REM Mode ID: ',ulModeID);
    writeln(cmdfile,'  ',ulHorizResolution,'x',ulVertResolution,'/',ulBpp,'  (',ulRefreshRate,' Hz)');
    // writeln(logfile,'  Num of colors: ',cColors,' FourCC: ',FourCCToString(fccColorEncoding));
    s0:=inttostr(ulHorizResolution)+'x'+inttostr(ulVertResolution)+'x';
    s1:=s0+inttostr(ulBpp);
    s2:=s0+FourCCToString(fccColorEncoding);
    writeln(cmdfile,progname,' ',s1,' ',s2);
  end;
  // close(cmdfile);
end; {WriteModeInfoCmd}


///////////////////////////////////////
// FindNewModeInfo
//
// Searches for
// FULLSCREENWIDTH x FULLSCREENHEIGHT x FULLSCREENBPP
// videomode in ModeInfo structure, and
// sets the NewModeInfo pointer to point
// to that part of ModeInfo, if found.
//
function FindNewModeInfo:boolean;
var l:longint;
    OneModeInfo:pGDDModeInfo;
begin
  result:=false;
  writeln(logfile,'Available GRADD Video Modes: ',NumVideoModes);
  NewModeInfo:=Nil;
  if ModeInfo=Nil then begin writeln(logfile,'Going to exit...'); exit; end;
  OneModeInfo:=ModeInfo;
  for l:=1 to NumVideoModes do
  begin
    WriteModeInfo(OneModeInfo);
    WriteModeInfoCmd(OneModeInfo);
    if (OneModeInfo^.ulHorizResolution=FULLSCREENWIDTH) and
       (OneModeInfo^.ulVertResolution=FULLSCREENHEIGHT) and
       (OneModeInfo^.ulBpp=FULLSCREENBPP) then NewModeInfo:=OneModeInfo;
    // longint(OneModeInfo):=longint(OneModeInfo)+Sizeof(GDDModeInfo);
    longword(OneModeInfo):=longword(OneModeInfo)+Sizeof(GDDModeInfo);
  end;
  result:=NewModeInfo<>nil;
end;

///////////////////////////////////////
// QueryCurrentMode
//
// Queries the current video mode, and
// stores it in DesktopModeInfo
//
function QueryCurrentMode:boolean;
var rc:apiret;
begin
  rc:=VMIEntry(0, VMI_CMD_QUERYCURRENTMODE, Nil, @DesktopModeInfo);
  if rc<>no_error then
  begin
    writeln(logfile,'Could not query DesktopModeInfo! rc=',rc);
  end;
  result:=rc=no_error;
end;

///////////////////////////////////////
// VMANCleanUpExitProc
//
// ExitProc, to cleanup VMAN resources
// at application termination.
//
procedure VMANCleanUpExitProc;
begin
  // Restore desktop mode if the program left in FS mode!
  //
  // Note that in this case, there will be problems with future DIVE applications
  // until the desktop is restarted, because SwitchBackToDesktop uses
  // DiveFullScreenTerm, which must be called before closing Dive (and Dive is already
  // closed when the execution gets here), but at least the desktop will be in its
  // original video mode!

  FreeModeInfo;
  UninitVMIEntry;
  UnloadVMAN;
end;


// -------------------------------------- Window procedure -----------------------------

function WndProc (Wnd: cardinal; Msg: cardinal; Mp1, Mp2: pointer): pointer; cdecl;

begin
   result:=WinDefWindowProc(Wnd, Msg, Mp1, Mp2);
end;

// ------------------------ Procedures for simple PM usage -----------------------------

///////////////////////////////////////
// InitPM
//
// Initializes PM, creates a message queue,
// and creates the main window.
//
procedure InitPM;
var fcf:ulong;
begin
  ab:=WinInitialize(0);
  mq:=WinCreateMsgQueue(ab,0);
  if mq=0 then
  begin
    Writeln(logfile,'Could not create message queue!');
  end;
  WinRegisterClass( ab, 'MainDIVEWindowClass', {@}WndProc, CS_SIZEREDRAW, 0);
  fcf:=FCF_TITLEBAR or
       FCF_SYSMENU or
       FCF_MINBUTTON or
       FCF_MAXBUTTON or
       FCF_SIZEBORDER or
       FCF_TASKLIST;
  hFrame:=WinCreateStdWindow( HWND_DESKTOP, 0, @fcf,
                              'MainDIVEWindowClass', AppTitle, 0,//WS_CLIPCHILDREN or WS_CLIPSIBLINGS,
                              0, 0, @hClient);
end;

///////////////////////////////////////
// SetupMainWindow
//
// Sets the size/position of the main window,
// and makes it visible.
//
procedure SetupMainWindow;
begin
  WinSetWindowPos( hFrame,
                   HWND_TOP,
                   (WinQuerySysValue (HWND_DESKTOP, SV_CXSCREEN) - SRCBUFFERWIDTH) div 2,
                   (WinQuerySysValue (HWND_DESKTOP, SV_CYSCREEN) - SRCBUFFERHEIGHT) div 2,
                   SRCBUFFERWIDTH,
                   SRCBUFFERHEIGHT + WinQuerySysValue (HWND_DESKTOP, SV_CYTITLEBAR)
                                   + WinQuerySysValue (HWND_DESKTOP, SV_CYDLGFRAME)*2
                                   + 1,
                   SWP_SIZE or SWP_ACTIVATE or SWP_SHOW or SWP_MOVE);
end;

///////////////////////////////////////
// UninitPM
//
// Destroys main window, and uninitializes
// PM.
//
procedure UninitPM;
begin
  WinDestroyWindow(hFrame);
  WinDestroyMsgQueue(mq);
  WinTerminate(ab);
end;

// -------------------------------------------------- DIVE -----------------------------

///////////////////////////////////////
// ShutdownDIVE
//
// Switches back to Windowed mode if
// necessary, then frees allocated
// image buffer, and closes Dive.
//
procedure ShutdownDIVE;
begin
  // We must switch back to windowed mode before closing Dive!
  // (Because switching uses Dive too!)

  DiveFreeImageBuffer( hDiveInst, ulImage );
  DiveClose( hDiveInst );
end;

///////////////////////////////////////
// SetupDIVE
//
// Opens Dive, allocates image buffer,
// and sets VRN, and sets up Dive for
// the first time (WM_VRNENABLED msg.)
//
procedure SetupDIVE;
var pFrameBuffer:pointer;
var bImageBuffer    : Pointer;
begin
  bImageBuffer := nil; {!!!}
  DiveOpen( hDiveInst, 0 {FALSE}, pFrameBuffer );
  DiveAllocImageBuffer
    ( hDiveInst, ulImage, SRCBUFFERFOURCC, SRCBUFFERWIDTH, SRCBUFFERHEIGHT, 0, bImageBuffer) ;
    
end;

// ------------------------------------------------ Main -------------------------------

procedure myhalt(n: integer);
begin
  writeln(logfile,'ending with ',n);
  close(logfile);
  close(cmdfile);
  halt(n)
end; {myhalt}

begin
    
  assign(logfile,'gmis.log');
  rewrite(logfile);
  
  assign(cmdfile,'tryit.cmd');
  rewrite(cmdfile);
  
  // ----------------------  VMAN initialization -----------------
  if not LoadVMAN then myhalt(1) else writeln(logfile,'can load VMAN');  // Load VMAN
  // myhalt(10);
  if not InitVMIEntry then    // Send "Hi! New process is here!" info to VMAN
  begin
    UnloadVMAN;
    myhalt(2);
  end;
  if not QueryModeInfo then   // Query available video modes
  begin
    UninitVMIEntry;
    UnloadVMAN;
    myhalt(3);
  end;
  if not FindNewModeInfo then // Find the fullscreen video mode
  begin
    writeln(logfile,'Could not find video mode: ',FULLSCREENWIDTH,' x ',FULLSCREENHEIGHT,' x ',FULLSCREENBPP,'bpp!');
    FreeModeInfo;
    UninitVMIEntry;
    UnloadVMAN;
    myhalt(4);
  end;
  if not QueryCurrentMode then // Save the actual (desktop) video mode
  begin
    FreeModeInfo;
    UninitVMIEntry;
    UnloadVMAN;
    myhalt(5);
  end;

  // Ok, VMAN has been initialized.
  AddExitProc({@}VMANCleanUpExitProc); // Setup VMAN cleanup-process

  // ----------------------  PM Initialization -------------------
  // ----------------------  VMAN Uninitialization ---------------
  // Done by VMANCleanUpExitProc
  VMANCleanUpExitProc;
  myhalt(0);
end.
