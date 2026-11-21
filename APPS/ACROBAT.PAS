{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/clonedraw)
  @website(https://www.gladir.com/office-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Clone de l'application Acrodoc (ACROBAT.PAS), pour le
                Presentation Manager d'OS/2-0 (dossier Productivite)

  Portage vers OS/2-0 (OS2PC -COS2) de ACROBAT.PAS du depot OFFICE-0 :
  tout le lecteur et l'editeur PDF sont conserves (filtres, polices,
  images JPEG, JPEG 2000, JBIG2, CCITT, degrades, annotations, pages,
  enregistrement incremental). Pour OS/2 : fenetre de Presentation
  Manager, barre de menus d'OS/2 construite a partir des six menus
  d'origine (coches et choix grises mis a jour a l'ouverture), rendu dans
  une image de 256 couleurs (cube 6 x 6 x 6 et gris) montree par
  GpiDrawBits, formulaires faits de controles de PM (champs, listes
  deroulantes, cases a cocher, couleurs), boite de fichiers de PM, boites
  de message de PM, selecteur de couleurs et boites d'information dans
  des fenetres de PM a part avec de vrais boutons.

  Visionneuse / éditeur de documents PDF en mode graphique :
   - Ouverture de fichiers PDF (flux Flate, ASCIIHex, ASCII85, flux d'objets,
     texte, graphiques vectoriels, annotations simples, images JPEG / Flate /
     CCITT G3-G4, JPEG 2000, JBIG2, images en ligne, calques (OCG),
     espaces Lab / ICC / Separation / DeviceN (fonctions types 0, 2, 3, 4), polices Type 3, découpe rectangulaire,
     dégradés axiaux et radiaux, motifs de pavage, transparence constante)
   - Aucune limite fixe de pages ou d'objets : listes chaînées dans le tas
   - Création de documents, pages, rotation, recadrage, filigrane, numérotation
   - Commentaires : texte, note, surlignage, soulignement, barré, crayon,
     ligne, flèche, rectangle, ovale, tampon, signature, biffure
   - Recherche de texte, vignettes, panneau des commentaires, zoom, défilement
   - Enregistrement incrémental (le fichier d'origine, ses polices incorporées,
     liens, champs de formulaire et signets sont conservés) ou réécriture
     complète compressée (Flate) ; exportation en texte et en image BMP
   - Non pris en charge : PDF chiffrés, maillages de dégradé (types 4 à 7)
   - Annuler / Rétablir

  Tout le code est contenu dans ce seul fichier (aucun $I, aucune unité
  externe autre que DOS, Crt et le module graphique).
}

Program ACROBAT;

{$IFDEF FPC}
 {$MODE OBJFPC}
 {$H-}
 {$Q-}
 {$R-}
 {$OVERFLOWCHECKS OFF}
{$ELSE}
 {$R-,Q-,S-}
 {$M 32768,0,655360}
{$ENDIF}


Const
 { Disposition de l'écran }
 MENU_H   = 20;
 TOOL_H   = 26;
 STATUS_H = 18;
 NAV_W    = 108;
 SBAR     = 16;

 {$IFDEF FPC}
 OBLK      = 256;
 PGBLK     = 64;
 PLBLK     = 2048;
 IMBLK     = 16;
 MAXIMG    = 65000;
 MAXPDFOBJ = 16000000;
 UNDO_MAX  = 24;
 UNDO_MEM  = 8000000;
 BUFSZ     = 500000;
 {$ELSE}
 OBLK      = 32;
 PGBLK     = 16;
 PLBLK     = 512;
 IMBLK     = 4;
 MAXIMG    = 1;
 MAXPDFOBJ = 3000;
 UNDO_MAX  = 6;
 UNDO_MEM  = 150000;
 BUFSZ     = 30000;
 {$ENDIF}

 { Types d'objets }
 K_TEXT   = 1;  K_LINE   = 2;  K_RECT   = 3;  K_OVAL   = 4;
 K_POLY   = 5;  K_INK    = 6;  K_IMAGE  = 7;  K_STAMP  = 8;
 K_REDACT = 9;  K_HILITE = 10; K_UNDER  = 11; K_STRIKE = 12;
 K_NOTE   = 13; K_ARROW  = 14; K_GRAD   = 15;

 { Outils }
 TL_SELECT = 0; TL_HAND   = 1; TL_ZOOM   = 2; TL_TEXT   = 3;
 TL_NOTE   = 4; TL_HILITE = 5; TL_UNDER  = 6; TL_STRIKE = 7;
 TL_PENCIL = 8; TL_LINE   = 9; TL_ARROW  = 10; TL_RECT  = 11;
 TL_OVAL   = 12; TL_STAMP = 13; TL_SIGN  = 14; TL_REDACT = 15;
 TL_COUNT  = 16;

 { Menus }
 MN_FILE = 0; MN_EDIT = 1; MN_VIEW = 2; MN_PAGE = 3; MN_TOOLS = 4; MN_HELP = 5;
 MN_COUNT = 6;

 { Commandes }
 CM_NONE=0;    CM_NEW=1;      CM_OPEN=2;     CM_SAVE=3;     CM_SAVEAS=4;
 CM_EXPTXT=5;  CM_EXPBMP=6;   CM_INSFILE=7;  CM_PROPS=8;    CM_QUIT=9;
 CM_UNDO=10;   CM_REDO=11;    CM_DELETE=12;  CM_DUP=13;     CM_COPY=14;
 CM_PASTE=15;  CM_CUT=16;     CM_DESEL=17;   CM_EDITTXT=18; CM_OBJPROPS=19;
 CM_FIND=20;   CM_FINDNEXT=21; CM_COLOR=22;  CM_WIDTH=23;
 CM_ZOOMIN=30; CM_ZOOMOUT=31; CM_FITW=32;    CM_FITP=33;    CM_Z100=34;
 CM_ZOOMSET=35; CM_CONT=36;   CM_NAV=37;     CM_FULL=38;    CM_PREV=39;
 CM_NEXT=40;   CM_FIRST=41;   CM_LAST=42;    CM_GOTO=43;    CM_NAVMODE=44;
 CM_PGINS=50;  CM_PGDEL=51;   CM_PGDUP=52;   CM_ROTR=53;    CM_ROTL=54;
 CM_PGUP=55;   CM_PGDOWN=56;  CM_CROP=57;    CM_PGSIZE=58;  CM_NUMBER=59;
 CM_WATER=60;  CM_EXTRACT=61;
 CM_TOOL0=70;  { 70..85 : outils }
 CM_APPLYRED=90; CM_FLATTEN=91; CM_CLEARALL=92;
 CM_HELP=100;  CM_ABOUT=101;  CM_KEYS=102;

Type
 TImgRec = Record
  W, H: Integer;            { dimensions réduites }
  Pix: Pointer;             { RVB 5-6-5 (Word), W*H ; Nil pour un masque }
  Alpha: Pointer;           { Byte, W*H ou Nil }
  Raw: Pointer;             { flux d'origine (encore encodé) }
  RawLen: LongInt;
  OW, OH: LongInt;          { dimensions d'origine }
  CS, BPC: Byte;            { 1 gris, 3 RVB, 4 CMJN, 5 indexé }
  NF: Byte;
  Flt: Array[0..3] Of String[24];
  Pred, Cols, Clr: Integer;
  Pal: Pointer;
  PalN: Integer;
  PalBase: Byte;
  Mask, IsSM, Keep: Boolean;
  SMIdx: Integer;
  Decode: String[48];
  SrcObj: LongInt;          { n° d'objet PDF d'origine de l'image }
 End;
 PImgRec = ^TImgRec;
 PImgBlock = ^TImgBlock;
 TImgBlock = Record
  Next: PImgBlock;
  Items: Array[0..IMBLK - 1] Of TImgRec;
 End;

 TObjRec = Record
  Kind: Byte;
  Page: LongInt;
  X1, Y1, X2, Y2: Integer;
  Rgb, Rgb2: LongInt;
  Wd, Size, Style, Fill: Byte;
  Alpha: Byte;              { transparence du remplissage (0 ou 255 : opaque) }
  Layer: Word;              { calque (OCG) : 0 aucun, indice + 1, $FFFF toujours masqué }
  P0, PN: LongInt;
  Src: Byte;                { 0 nouveau, 1 contenu d'origine, 2 annotation d'origine, 3 aperçu seul }
  SrcNum: LongInt;          { n° d'objet PDF d'origine (annotations) }
  SrcCnt: Integer;          { nombre d'éléments issus de la même annotation }
  Sum: LongInt;             { somme de contrôle à l'import (détection des modifications) }
  Txt: String[119];
 End;
 PObjRec = ^TObjRec;

 { Calques (groupes de contenu optionnel) }
 TLayer = Record
  Num: LongInt;
  Name: String[40];
  On: Boolean;
 End;
 PLayer = ^TLayer;
 TLayerArr = Array[0..1000000] Of TLayer;
 PLayerArr = ^TLayerArr;

 { Listes chaînées de blocs allouées dans le tas : aucune limite fixe. }
 PObjBlock = ^TObjBlock;
 TObjBlock = Record
  Next: PObjBlock;
  Items: Array[0..OBLK - 1] Of TObjRec;
 End;

 TPageRec = Record
  W, H: Integer;
  Rot: Byte;
  Top: LongInt;
  SrcPage: LongInt;         { n° d'objet de la page d'origine (0 : page nouvelle) }
  SrcCount: LongInt;        { nombre d'objets de contenu importés }
  OrigW, OrigH, OrigRot: Integer;
  MbX0, MbY1: Real;         { origine de la boîte de la page d'origine }
  SrcAnnObjs: LongInt;      { nombre d'objets issus des annotations d'origine }
 End;
 PPageRec = ^TPageRec;
 PPageBlock = ^TPageBlock;
 TPageBlock = Record
  Next: PPageBlock;
  Items: Array[0..PGBLK - 1] Of TPageRec;
 End;

 PPoolBlock = ^TPoolBlock;
 TPoolBlock = Record
  Next: PPoolBlock;
  X, Y: Array[0..PLBLK - 1] Of SmallInt;
 End;

 TMenuItem = Record
  Caption: String[40];
  Shortcut: String[12];
  Cmd: Integer;
  Separator: Boolean;
  Checked: Boolean;
 End;
 TMenu = Record
  Title: String[14];
  Items: Array[0..22] Of TMenuItem;
  ItemCount: Integer;
  X, Width: Integer;
 End;

 TUndoRec = Record
  Objs: Pointer;
  Pgs: Pointer;
  Cnt, PgCnt, Cur: Integer;
  Mem: LongInt;
 End;

 TField = Record
  Kind: Byte;        { 0 texte, 1 nombre, 2 choix, 3 couleur, 4 case, 9 étiquette }
  Lbl: String[30];
  Val: String[119];
  Choices: String[120];
  Mn, Mx: LongInt;
  Cur: Integer;
 End;

 TByteBuf = Array[0..{$IFDEF FPC}134217727{$ELSE}BUFSZ+16{$ENDIF}] Of Byte;
 PByteBuf = ^TByteBuf;
 TLArr = Array[0..{$IFDEF FPC}134217727{$ELSE}8000{$ENDIF}] Of LongInt;
 PLArr = ^TLArr;
 TXArr = Array[0..{$IFDEF FPC}134217727{$ELSE}8000{$ENDIF}] Of LongInt;
 PXArr = ^TXArr;
 TWArr = Array[0..{$IFDEF FPC}134217727{$ELSE}8000{$ENDIF}] Of Word;
 PWArr = ^TWArr;

Var
 { Document }
 ObjHead, ObjCurBlk: PObjBlock;
 ObjCurNo, ObjBlocks: LongInt;
 ImgHead, ImgCurBlk: PImgBlock;
 ImgCurNo, ImgBlocks: LongInt;
 ImgCount: LongInt;
 ObjCount: LongInt;
 PgHead, PgCurBlk: PPageBlock;
 PgCurNo, PgBlocks: LongInt;
 PageCount, CurPage: LongInt;
 PoolHead, PoolCurBlk: PPoolBlock;
 PoolCurNo, PoolBlocks: LongInt;
 PoolCount: LongInt;
 DocName: String;
 DocTitle, DocAuthor, DocSubject, DocKeywords, DocCreator: String[79];
 Modified: Boolean;
 DocEncrypted: Boolean;
 SrcFile: String;           { fichier PDF d'origine (mise à jour incrémentale) }
 SrcValid, InfoDirty, NeedFullRewrite: Boolean;
 SrcSize: LongInt;
 OrigOrder: PLArr;          { n° d'objets des pages d'origine, dans l'ordre }
 OrigPageCnt: LongInt;
 LoadNotice: String;

 { Vue }
 Zoom, FitMode: Integer;
 Scale: LongInt;
 ScrollX, ScrollY: LongInt;
 DocW, DocH: LongInt;
 ViewL, ViewT, ViewR, ViewB, ViewW, ViewH: Integer;
 Continuous, NavVisible, ToolbarVisible, NavTab: Integer;
 NavScroll: Integer;
 FullScreen: Boolean;

 { Sélection / outils }
 CurTool: Integer;
 SelObj: Integer;
 FindObj: Integer;
 FindText: String[79];
 FindCase: Boolean;
 ToolRgb: Array[0..TL_COUNT-1] Of LongInt;
 CurWidth, CurSize, CurFam, CurStyle, CurAngle: Integer;
 Clip: TObjRec;
 ClipValid: Boolean;
 ClipPts: Array[0..199] Of Integer;
 ClipPtCount: Integer;

 { Édition de texte en ligne }
 Editing: Boolean;
 EditObj, EditCaret: Integer;
 EditBlink: LongInt;

 { Souris / clavier }
 MX_, MY_, MB_, OMX, OMY, OMB: LongInt;
 Running: Boolean;
 MaxScreen: Boolean;
 MaxColors: Boolean;        { -maxcolors : nombre maximal de couleurs (couleurs directes) }
 TrueMode: Boolean;         { mode graphique en couleurs directes (RVB) }
 UiRgbTab: Array[0..15] Of LongInt;
 Pal256: Boolean;           { palette indexée de 256 couleurs (mode -maxscreen) }
 ImgMaxDim: LongInt;
 MouseOK: Boolean;
 LastClickT: LongInt;
 LastClickX, LastClickY: LongInt;

 { Menus }
 Menus: Array[0..MN_COUNT-1] Of TMenu;
 MenuActive: Boolean;
 ActiveMenu, ActiveItem: Integer;
 UnderBuf: Pointer;
 UnderSize: LongInt;
 UnderX, UnderY, UnderW, UnderH: Integer;
 UnderValid: Boolean;

 { Annuler / rétablir }
 UndoStack: Array[0..UNDO_MAX-1] Of TUndoRec;
 UndoTop: Integer;
 RedoStack: Array[0..UNDO_MAX-1] Of TUndoRec;
 RedoTop: Integer;

 { Formulaires }
 Fields: Array[0..11] Of TField;
 NFields: Integer;

 { État du dernier survol (barre d'état) }
 HintText: String;
 StatusMsg: String;

 { Géométrie du contexte de page courant }
 GPg: Integer;
 GOX, GOY, GSc: LongInt;
 GRot: Integer;
 GPW, GPH: LongInt;

 { Pages -> écran }
 DragMode: Integer;
 DragX0, DragY0, DragX1, DragY1: LongInt;
 DragObj: Integer;
 DragHandle: Integer;
 DragPg: Integer;
 DragOX, DragOY: LongInt;
 InkCount0: Integer;
 PreviewOn: Boolean;
 PrevX1, PrevY1, PrevX2, PrevY2: LongInt;
 SBDragKind, SBDragOfs: LongInt;

{ ---------------------------------------------------------------------- }
{ Squelette : graphique et souris                                         }
{ ---------------------------------------------------------------------- }

Const
 ScrVga: Array[0..15, 0..2] Of Byte = (
  (0,0,0), (0,0,170), (0,170,0), (0,170,170),
  (170,0,0), (170,0,170), (170,85,0), (170,170,170),
  (85,85,85), (85,85,255), (85,255,85), (85,255,255),
  (255,85,85), (255,85,255), (255,255,85), (255,255,255));


{ Les seize couleurs de l'interface restent identiques dans le pilote D8bit ;
  les indices 16..231 forment un cube 6x6x6 et 232..255 une rampe de gris. }
Var
 ReturnNilIfGrowHeapFails : Boolean;

{ decalage arithmetique a droite (intrinseques de Free Pascal) }
Function SarLongInt(V: LongInt; N: Byte): LongInt;
Begin
 If V >= 0 Then SarLongInt := V Shr N
 Else SarLongInt := Not ((Not V) Shr N);
End;

Function SarInt64(V: Int64; N: Byte): Int64;
Begin
 If V >= 0 Then SarInt64 := V Shr N
 Else SarInt64 := Not ((Not V) Shr N);
End;

{ palette de l'image de PM (256 couleurs) }
Function GetMaxColor: Word;
Begin
 GetMaxColor := 255;
End;

Procedure SetRGBPalette(I, R, G, B: Integer);
Begin
 SetPalEntry(I, (LongInt(R And 255) Shl 16) Or (LongInt(G And 255) Shl 8) Or (B And 255));
End;

Procedure InitializeScreenPalette;
{$IFDEF FPC}
Var
 I: Integer;
{$ENDIF}
Begin
 Pal256 := False;
 TrueMode := False;
 {$IFDEF FPC}
 For I := 0 To 15 Do
  UiRgbTab[I] := (LongInt(ScrVga[I, 0]) Shl 16) Or (LongInt(ScrVga[I, 1]) Shl 8) Or ScrVga[I, 2];
 If GetMaxColor > 255 Then Begin
  { couleurs directes : rendu riche (mélanges réels, sans tramage) }
  TrueMode := True;
  Pal256 := True;
 End
 Else If GetMaxColor > 15 Then Begin
  For I := 0 To 15 Do SetRGBPalette(I, ScrVga[I, 0], ScrVga[I, 1], ScrVga[I, 2]);
  If GetMaxColor >= 255 Then Begin
   For I := 16 To 231 Do
    SetRGBPalette(I, ((I - 16) Div 36) * 51, (((I - 16) Div 6) Mod 6) * 51, ((I - 16) Mod 6) * 51);
   For I := 232 To 255 Do SetRGBPalette(I, 8 + (I - 232) * 10, 8 + (I - 232) * 10, 8 + (I - 232) * 10);
   Pal256 := True;
  End;
 End;
 {$ENDIF}
End;

Const
 CanvasTop = MENU_H;
 CanvasBot = MENU_H + 413;

{ ================================================================== }
{ OS/2-0 : PRESENTATION MANAGER, GRAPH ET CRT EMULES                  }
{ ================================================================== }
{ La version DOS dessine avec l'unite Graph du BGI (640 x 480, 16     }
{ couleurs) et lit le clavier et la souris dans sa propre boucle.     }
{ Ici :                                                               }
{  - le dessin va dans une image en memoire de 640 x 480 (un octet    }
{    par point), montree dans la zone client d'une fenetre de PM par  }
{    GpiDrawBits (seules les zones modifiees sont recopiees) ;        }
{  - les lignes 0 a MENU_H - 1 de la version DOS (barre de menus      }
{    dessinee par le programme) sont remplacees par la barre de       }
{    titre et la barre de menus de PM, construites a partir des       }
{    tables de menus d'origine (dans la langue choisie) ;             }
{  - les routines de Graph utilisees (Line, Rectangle, Bar, Circle,   }
{    Arc, FillEllipse, PieSlice, PutPixel, OutTextXY agrandi par      }
{    SetTextStyle, styles de trait et de remplissage) sont ecrites    }
{    ici ;                                                            }
{  - la file de messages de PM (WinPeekMsg) est videe dans une file   }
{    d'evenements : touches (WM_CHAR, en codes du BIOS de la version  }
{    DOS), clics (WM_BUTTON1DOWN), commandes des menus (WM_COMMAND) ; }
{  - les messages et les questions passent par WinMessageBox.         }
{ Palette de l'image : couleurs 0 a 15 du BGI, puis 16 a 31 : memes   }
{ couleurs foncees, lisibles sur le fond blanc des pages de texte.    }

Const
 NormalPut = 0;
 ClipOn = True; ClipOff = False;
 WM_SIZE = $0007; WM_COMMAND = $0020; WM_SYSCOMMAND = $0021; WM_PAINT = $0023;
 WM_CLOSE = $0029; WM_MENUEND = $0035; WM_QUIT = $002A; WM_INITMENU = $0033; WM_MOUSEMOVE = $0070;
 WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073;
 WM_BUTTON2DOWN = $0074; WM_CHAR = $007A;
 FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100;
 FCF_TASKLIST = $800;
 HWND_DESKTOP = 1; HWND_TOP = 3;
 SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
 MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000;
 MIA_DISABLED = $4000; MM_SETITEMATTR = $0192;
 MB_OK = 0; MB_YESNO = 4; MB_ICONQUESTION = $10; MB_ICONEXCLAMATION = $20;
 MB_INFORMATION = $30; MB_MOVEABLE = $4000; MBID_YES = 6;
 KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SCANCODE = 4; KC_SHIFT = 8; KC_CTRL = $10;
 KC_ALT = $20; KC_KEYUP = $40;
 VK_BACKSPACE = $05; VK_TAB = $06; VK_BACKTAB = $07; VK_NEWLINE = $08;
 VK_ESC = $0F; VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14;
 VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_INSERT = $1A;
 VK_DELETE = $1B; VK_ENTER = $1E; VK_F1 = $20;
 SC_APPMENU = $8006; CMDSRC_ACCELERATOR = 3;
 PM_REMOVE = 1;
 FbW = 640; FbH = 480;
 EvQMax = 64;
 { evenements : 1 touche, 2 clic, 5 commande de menu (9999 = fermer) }
 EV_KEY = 1; EV_CLICK = 2; EV_CMD = 5; CMD_CLOSE = 9999;

Type
 PointType = Record
  X, Y : Integer;
 End;
 FillPatternType = Array[1..8] Of Byte;

Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinPeekMsg(Hab, P, HF, First, Last, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSysClassProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WINSYSCLASSPROC';
Function WinSubclassWindow(H, Proc : LongInt) : LongInt; External 'PMWIN';
Function WinBeginPaint(H, Hps, P : LongInt) : LongInt; External 'PMWIN';
Function WinEndPaint(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryCapture(HD : LongInt) : LongInt; External 'PMWIN';
Function WinQueryActiveWindow(HD : LongInt) : LongInt; External 'PMWIN';
Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';

{ police 8 x 8 (256 caracteres, page de codes 437) : police du BGI }
Const
  Font8 : Array[0..2047] Of Byte = (
    $00,$00,$00,$00,$00,$00,$00,$00,$7E,$81,$A5,$81,$BD,$99,$81,$7E,
    $7E,$FF,$DB,$FF,$C3,$E7,$FF,$7E,$6C,$FE,$FE,$FE,$7C,$38,$10,$00,
    $10,$38,$7C,$FE,$7C,$38,$10,$00,$38,$7C,$38,$FE,$FE,$7C,$38,$7C,
    $10,$10,$38,$7C,$FE,$7C,$38,$7C,$00,$00,$18,$3C,$3C,$18,$00,$00,
    $FF,$FF,$E7,$C3,$C3,$E7,$FF,$FF,$00,$3C,$66,$42,$42,$66,$3C,$00,
    $FF,$C3,$99,$BD,$BD,$99,$C3,$FF,$0F,$07,$0F,$7D,$CC,$CC,$CC,$78,
    $3C,$66,$66,$66,$3C,$18,$7E,$18,$3F,$33,$3F,$30,$30,$70,$F0,$E0,
    $7F,$63,$7F,$63,$63,$67,$E6,$C0,$99,$5A,$3C,$E7,$E7,$3C,$5A,$99,
    $80,$E0,$F8,$FE,$F8,$E0,$80,$00,$02,$0E,$3E,$FE,$3E,$0E,$02,$00,
    $18,$3C,$7E,$18,$18,$7E,$3C,$18,$66,$66,$66,$66,$66,$00,$66,$00,
    $7F,$DB,$DB,$7B,$1B,$1B,$1B,$00,$3E,$63,$38,$6C,$6C,$38,$CC,$78,
    $00,$00,$00,$00,$7E,$7E,$7E,$00,$18,$3C,$7E,$18,$7E,$3C,$18,$FF,
    $18,$3C,$7E,$18,$18,$18,$18,$00,$18,$18,$18,$18,$7E,$3C,$18,$00,
    $00,$18,$0C,$FE,$0C,$18,$00,$00,$00,$30,$60,$FE,$60,$30,$00,$00,
    $00,$00,$C0,$C0,$C0,$FE,$00,$00,$00,$24,$66,$FF,$66,$24,$00,$00,
    $00,$18,$3C,$7E,$FF,$FF,$00,$00,$00,$FF,$FF,$7E,$3C,$18,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$30,$78,$78,$78,$30,$00,$30,$00,
    $6C,$6C,$6C,$00,$00,$00,$00,$00,$6C,$6C,$FE,$6C,$FE,$6C,$6C,$00,
    $30,$7C,$C0,$78,$0C,$F8,$30,$00,$00,$C6,$CC,$18,$30,$66,$C6,$00,
    $38,$6C,$38,$76,$DC,$CC,$76,$00,$60,$60,$C0,$00,$00,$00,$00,$00,
    $18,$30,$60,$60,$60,$30,$18,$00,$60,$30,$18,$18,$18,$30,$60,$00,
    $00,$66,$3C,$FF,$3C,$66,$00,$00,$00,$30,$30,$FC,$30,$30,$00,$00,
    $00,$00,$00,$00,$00,$30,$30,$60,$00,$00,$00,$FC,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$30,$30,$00,$06,$0C,$18,$30,$60,$C0,$80,$00,
    $7C,$C6,$C6,$C6,$C6,$C6,$7C,$00,$30,$70,$30,$30,$30,$30,$FC,$00,
    $78,$CC,$0C,$38,$60,$CC,$FC,$00,$78,$CC,$0C,$38,$0C,$CC,$78,$00,
    $1C,$3C,$6C,$CC,$FE,$0C,$1E,$00,$FC,$C0,$F8,$0C,$0C,$CC,$78,$00,
    $38,$60,$C0,$F8,$CC,$CC,$78,$00,$FC,$CC,$0C,$18,$30,$30,$30,$00,
    $78,$CC,$CC,$78,$CC,$CC,$78,$00,$78,$CC,$CC,$7C,$0C,$18,$70,$00,
    $00,$30,$30,$00,$00,$30,$30,$00,$00,$30,$30,$00,$00,$30,$30,$60,
    $18,$30,$60,$C0,$60,$30,$18,$00,$00,$00,$FC,$00,$00,$FC,$00,$00,
    $60,$30,$18,$0C,$18,$30,$60,$00,$78,$CC,$0C,$18,$30,$00,$30,$00,
    $7C,$C6,$DE,$DE,$DE,$C0,$78,$00,$38,$6C,$C6,$C6,$FE,$C6,$C6,$00,
    $FC,$C6,$C6,$FC,$C6,$C6,$FC,$00,$7C,$C6,$C6,$C0,$C0,$C6,$7C,$00,
    $F8,$CC,$C6,$C6,$C6,$CC,$F8,$00,$FE,$C0,$C0,$FC,$C0,$C0,$FE,$00,
    $FE,$C0,$C0,$FC,$C0,$C0,$C0,$00,$7C,$C6,$C0,$CE,$C6,$C6,$7E,$00,
    $C6,$C6,$C6,$FE,$C6,$C6,$C6,$00,$78,$30,$30,$30,$30,$30,$78,$00,
    $1E,$06,$06,$06,$C6,$C6,$7C,$00,$C6,$CC,$D8,$F0,$D8,$CC,$C6,$00,
    $C0,$C0,$C0,$C0,$C0,$C0,$FE,$00,$C6,$EE,$FE,$D6,$C6,$C6,$C6,$00,
    $C6,$E6,$F6,$DE,$CE,$C6,$C6,$00,$7C,$C6,$C6,$C6,$C6,$C6,$7C,$00,
    $FC,$C6,$C6,$FC,$C0,$C0,$C0,$00,$7C,$C6,$C6,$C6,$C6,$C6,$7C,$06,
    $FC,$C6,$C6,$FC,$C6,$C6,$C6,$00,$78,$CC,$60,$30,$18,$CC,$78,$00,
    $FC,$30,$30,$30,$30,$30,$30,$00,$C6,$C6,$C6,$C6,$C6,$C6,$7C,$00,
    $C6,$C6,$C6,$C6,$C6,$6C,$38,$00,$C6,$C6,$C6,$D6,$FE,$EE,$C6,$00,
    $C6,$C6,$6C,$38,$6C,$C6,$C6,$00,$C3,$C3,$66,$3C,$18,$18,$18,$00,
    $FE,$0C,$18,$30,$60,$C0,$FE,$00,$3C,$30,$30,$30,$30,$30,$3C,$00,
    $C0,$60,$30,$18,$0C,$06,$03,$00,$3C,$0C,$0C,$0C,$0C,$0C,$3C,$00,
    $00,$38,$6C,$C6,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,
    $30,$30,$18,$00,$00,$00,$00,$00,$00,$00,$7C,$06,$7E,$C6,$7E,$00,
    $C0,$C0,$FC,$C6,$C6,$E6,$DC,$00,$00,$00,$7C,$C6,$C0,$C0,$7E,$00,
    $06,$06,$7E,$C6,$C6,$CE,$76,$00,$00,$00,$7C,$C6,$FE,$C0,$7E,$00,
    $1E,$30,$7C,$30,$30,$30,$30,$00,$00,$00,$7E,$C6,$CE,$76,$06,$7C,
    $C0,$C0,$FC,$C6,$C6,$C6,$C6,$00,$18,$00,$38,$18,$18,$18,$3C,$00,
    $18,$00,$38,$18,$18,$18,$18,$F0,$C0,$C0,$CC,$D8,$F0,$D8,$CC,$00,
    $38,$18,$18,$18,$18,$18,$3C,$00,$00,$00,$CC,$FE,$D6,$C6,$C6,$00,
    $00,$00,$FC,$C6,$C6,$C6,$C6,$00,$00,$00,$7C,$C6,$C6,$C6,$7C,$00,
    $00,$00,$FC,$C6,$C6,$E6,$DC,$C0,$00,$00,$7E,$C6,$C6,$CE,$76,$06,
    $00,$00,$6E,$70,$60,$60,$60,$00,$00,$00,$7C,$C0,$7C,$06,$FC,$00,
    $30,$30,$7C,$30,$30,$30,$1C,$00,$00,$00,$C6,$C6,$C6,$C6,$7E,$00,
    $00,$00,$C6,$C6,$C6,$6C,$38,$00,$00,$00,$C6,$C6,$D6,$FE,$6C,$00,
    $00,$00,$C6,$6C,$38,$6C,$C6,$00,$00,$00,$C6,$C6,$CE,$76,$06,$7C,
    $00,$00,$FC,$18,$30,$60,$FC,$00,$1C,$30,$30,$E0,$30,$30,$1C,$00,
    $18,$18,$18,$00,$18,$18,$18,$00,$E0,$30,$30,$1C,$30,$30,$E0,$00,
    $76,$DC,$00,$00,$00,$00,$00,$00,$00,$10,$38,$6C,$C6,$C6,$FE,$00,
    $78,$CC,$C0,$CC,$78,$18,$0C,$78,$00,$CC,$00,$CC,$CC,$CC,$7E,$00,
    $1C,$00,$78,$CC,$FC,$C0,$78,$00,$7E,$C3,$3C,$06,$3E,$66,$3F,$00,
    $CC,$00,$78,$0C,$7C,$CC,$7E,$00,$E0,$00,$78,$0C,$7C,$CC,$7E,$00,
    $30,$30,$78,$0C,$7C,$CC,$7E,$00,$00,$00,$78,$C0,$C0,$78,$0C,$38,
    $7E,$C3,$3C,$66,$7E,$60,$3C,$00,$CC,$00,$78,$CC,$FC,$C0,$78,$00,
    $E0,$00,$78,$CC,$FC,$C0,$78,$00,$CC,$00,$70,$30,$30,$30,$78,$00,
    $7C,$C6,$38,$18,$18,$18,$3C,$00,$E0,$00,$70,$30,$30,$30,$78,$00,
    $C6,$38,$6C,$C6,$FE,$C6,$C6,$00,$30,$30,$00,$78,$CC,$FC,$CC,$00,
    $1C,$00,$FC,$60,$78,$60,$FC,$00,$00,$00,$7F,$0C,$7F,$CC,$7F,$00,
    $3E,$6C,$CC,$FE,$CC,$CC,$CE,$00,$78,$CC,$00,$78,$CC,$CC,$78,$00,
    $00,$CC,$00,$78,$CC,$CC,$78,$00,$00,$E0,$00,$78,$CC,$CC,$78,$00,
    $78,$CC,$00,$CC,$CC,$CC,$7E,$00,$00,$E0,$00,$CC,$CC,$CC,$7E,$00,
    $00,$CC,$00,$CC,$CC,$7C,$0C,$F8,$C3,$18,$3C,$66,$66,$3C,$18,$00,
    $CC,$00,$CC,$CC,$CC,$CC,$78,$00,$18,$18,$7E,$C0,$C0,$7E,$18,$18,
    $38,$6C,$64,$F0,$60,$E6,$FC,$00,$CC,$CC,$78,$FC,$30,$FC,$30,$30,
    $F8,$CC,$CC,$FA,$C6,$CF,$C6,$C7,$0E,$1B,$18,$3C,$18,$18,$D8,$70,
    $1C,$00,$78,$0C,$7C,$CC,$7E,$00,$38,$00,$70,$30,$30,$30,$78,$00,
    $00,$1C,$00,$78,$CC,$CC,$78,$00,$00,$1C,$00,$CC,$CC,$CC,$7E,$00,
    $00,$F8,$00,$F8,$CC,$CC,$CC,$00,$FC,$00,$CC,$EC,$FC,$DC,$CC,$00,
    $3C,$6C,$6C,$3E,$00,$7E,$00,$00,$38,$6C,$6C,$38,$00,$7C,$00,$00,
    $30,$00,$30,$60,$C0,$CC,$78,$00,$00,$00,$00,$FC,$C0,$C0,$00,$00,
    $00,$00,$00,$FC,$0C,$0C,$00,$00,$C3,$C6,$CC,$DE,$33,$66,$CC,$0F,
    $C3,$C6,$CC,$DB,$37,$6F,$CF,$03,$18,$18,$00,$18,$18,$18,$18,$00,
    $00,$33,$66,$CC,$66,$33,$00,$00,$00,$CC,$66,$33,$66,$CC,$00,$00,
    $22,$88,$22,$88,$22,$88,$22,$88,$55,$AA,$55,$AA,$55,$AA,$55,$AA,
    $DB,$77,$DB,$EE,$DB,$77,$DB,$EE,$18,$18,$18,$18,$18,$18,$18,$18,
    $18,$18,$18,$18,$F8,$18,$18,$18,$18,$18,$F8,$18,$F8,$18,$18,$18,
    $36,$36,$36,$36,$F6,$36,$36,$36,$00,$00,$00,$00,$FE,$36,$36,$36,
    $00,$00,$F8,$18,$F8,$18,$18,$18,$36,$36,$F6,$06,$F6,$36,$36,$36,
    $36,$36,$36,$36,$36,$36,$36,$36,$00,$00,$FE,$06,$F6,$36,$36,$36,
    $36,$36,$F6,$06,$FE,$00,$00,$00,$36,$36,$36,$36,$FE,$00,$00,$00,
    $18,$18,$F8,$18,$F8,$00,$00,$00,$00,$00,$00,$00,$F8,$18,$18,$18,
    $18,$18,$18,$18,$1F,$00,$00,$00,$18,$18,$18,$18,$FF,$00,$00,$00,
    $00,$00,$00,$00,$FF,$18,$18,$18,$18,$18,$18,$18,$1F,$18,$18,$18,
    $00,$00,$00,$00,$FF,$00,$00,$00,$18,$18,$18,$18,$FF,$18,$18,$18,
    $18,$18,$1F,$18,$1F,$18,$18,$18,$36,$36,$36,$36,$37,$36,$36,$36,
    $36,$36,$37,$30,$3F,$00,$00,$00,$00,$00,$3F,$30,$37,$36,$36,$36,
    $36,$36,$F7,$00,$FF,$00,$00,$00,$00,$00,$FF,$00,$F7,$36,$36,$36,
    $36,$36,$37,$30,$37,$36,$36,$36,$00,$00,$FF,$00,$FF,$00,$00,$00,
    $36,$36,$F7,$00,$F7,$36,$36,$36,$18,$18,$FF,$00,$FF,$00,$00,$00,
    $36,$36,$36,$36,$FF,$00,$00,$00,$00,$00,$FF,$00,$FF,$18,$18,$18,
    $00,$00,$00,$00,$FF,$36,$36,$36,$36,$36,$36,$36,$3F,$00,$00,$00,
    $18,$18,$1F,$18,$1F,$00,$00,$00,$00,$00,$1F,$18,$1F,$18,$18,$18,
    $00,$00,$00,$00,$3F,$36,$36,$36,$36,$36,$36,$36,$FF,$36,$36,$36,
    $18,$18,$FF,$18,$FF,$18,$18,$18,$18,$18,$18,$18,$F8,$00,$00,$00,
    $00,$00,$00,$00,$1F,$18,$18,$18,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,
    $00,$00,$00,$00,$FF,$FF,$FF,$FF,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,
    $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$FF,$FF,$FF,$FF,$00,$00,$00,$00,
    $00,$00,$76,$DC,$C8,$DC,$76,$00,$00,$78,$CC,$F8,$CC,$F8,$C0,$C0,
    $00,$FC,$CC,$C0,$C0,$C0,$C0,$00,$00,$FE,$6C,$6C,$6C,$6C,$6C,$00,
    $FC,$CC,$60,$30,$60,$CC,$FC,$00,$00,$00,$7E,$D8,$D8,$D8,$70,$00,
    $00,$66,$66,$66,$66,$7C,$60,$C0,$00,$76,$DC,$18,$18,$18,$18,$00,
    $FC,$30,$78,$CC,$CC,$78,$30,$FC,$38,$6C,$C6,$FE,$C6,$6C,$38,$00,
    $38,$6C,$C6,$C6,$6C,$6C,$EE,$00,$1C,$30,$18,$7C,$CC,$CC,$78,$00,
    $00,$00,$7E,$DB,$DB,$7E,$00,$00,$06,$0C,$7E,$DB,$DB,$7E,$60,$C0,
    $38,$60,$C0,$F8,$C0,$60,$38,$00,$78,$CC,$CC,$CC,$CC,$CC,$CC,$00,
    $00,$FC,$00,$FC,$00,$FC,$00,$00,$30,$30,$FC,$30,$30,$00,$FC,$00,
    $60,$30,$18,$30,$60,$00,$FC,$00,$18,$30,$60,$30,$18,$00,$FC,$00,
    $0E,$1B,$1B,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$D8,$D8,$70,
    $30,$30,$00,$FC,$00,$30,$30,$00,$00,$76,$DC,$00,$76,$DC,$00,$00,
    $38,$6C,$6C,$38,$00,$00,$00,$00,$00,$00,$00,$18,$18,$00,$00,$00,
    $00,$00,$00,$00,$18,$00,$00,$00,$0F,$0C,$0C,$0C,$EC,$6C,$3C,$1C,
    $78,$6C,$6C,$6C,$6C,$00,$00,$00,$70,$18,$30,$60,$78,$00,$00,$00,
    $00,$00,$3C,$3C,$3C,$3C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);

Var
 OsHab, OsHmq, OsFrame, OsClient, Dummy, OsMenu : LongInt;
 Fb : Array[0..FbW * FbH - 1] Of Byte;     { image, lignes de bas en haut }
 Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;   { BITMAPINFO2 et palette }
 DirtyX1, DirtyY1, DirtyX2, DirtyY2 : LongInt;
 GColor, GBk, GFillStyle, GFillColor, GLineStyle, GThick, GWrite : LongInt;
 GLinePat, GTextSz, GJustH, GJustV : LongInt;
 EvMX, EvMY, EvMB : LongInt;
 EvKind, EvKey, EvX, EvY : Array[0..EvQMax - 1] Of LongInt;
 EvHead, EvTail : LongInt;
 NameZ, NameZ2 : Array[0..1023] Of Byte;
 TxtBuf : Array[0..4095] Of Byte;
 MenuT : Array[0..16383] Of Byte;
 MenuLen : LongInt;
 Qmsg : Array[0..7] Of LongInt;
 OsTitle : String;
 MnemoKeys : String;                         { lettres des titres de menus }
 PaperMode : Boolean;                        { page sur fond blanc }
 { fenetre de Graph (SetViewPort) : origine et rectangle de decoupe }
 VOX, VOY, ClipX1, ClipY1, ClipX2, ClipY2 : LongInt;
 GFillPat : Array[1..8] Of Byte;
 { Crt emule : touches (codes du BIOS), commandes des menus, souris }
 KeyQ : Array[0..127] Of LongInt;
 KeyH, KeyT, PendScan : LongInt;
 CmdQ : Array[0..31] Of LongInt;
 CmdH, CmdT : LongInt;
 MBtn, MLatch : LongInt;
 MenuUp, MenuStale, WasActive : LongInt;

{ --- utilitaires --- }

Procedure WrB(A, V : LongInt);
Type PByte1 = ^Byte;
Var Q : PByte1;
Begin
 Q := Pointer(A);
 Q^ := V;
End;

Procedure WrW(A, V : LongInt);
Begin
 WrB(A, V And 255);
 WrB(A + 1, (V Shr 8) And 255);
End;

Procedure WrL(A, V : LongInt);
Begin
 WrW(A, V And $FFFF);
 WrW(A + 2, (V Shr 16) And $FFFF);
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
 For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
 WrB(A + Length(S), 0);
End;

Function OsZ(S : String) : LongInt;
Begin
 PutZ(LongInt(@NameZ), S);
 OsZ := LongInt(@NameZ);
End;

Function OsZ2(S : String) : LongInt;
Begin
 PutZ(LongInt(@NameZ2), S);
 OsZ2 := LongInt(@NameZ2);
End;

Function Lo16(V : LongInt) : LongInt;
Begin
 Lo16 := V And $FFFF;
End;

Function Hi16(V : LongInt) : LongInt;
Begin
 Hi16 := (V Shr 16) And $FFFF;
End;

Function S16(V : LongInt) : LongInt;
Begin
 V := V And $FFFF;
 If V >= $8000 Then V := V - $10000;
 S16 := V;
End;

Function Min2(A, B : LongInt) : LongInt;
Begin
 If A < B Then Min2 := A Else Min2 := B;
End;

Function Max2(A, B : LongInt) : LongInt;
Begin
 If A > B Then Max2 := A Else Max2 := B;
End;

{ --- image et zones modifiees --- }

Procedure GTouch(X1, Y1, X2, Y2 : LongInt);
Begin
 If X1 < 0 Then X1 := 0;
 If Y1 < 0 Then Y1 := 0;
 If X2 > FbW - 1 Then X2 := FbW - 1;
 If Y2 > FbH - 1 Then Y2 := FbH - 1;
 If (X2 < X1) Or (Y2 < Y1) Then Exit;
 If DirtyX1 < 0 Then
 Begin
  DirtyX1 := X1; DirtyY1 := Y1; DirtyX2 := X2; DirtyY2 := Y2;
 End
 Else
 Begin
  If X1 < DirtyX1 Then DirtyX1 := X1;
  If Y1 < DirtyY1 Then DirtyY1 := Y1;
  If X2 > DirtyX2 Then DirtyX2 := X2;
  If Y2 > DirtyY2 Then DirtyY2 := Y2;
 End;
End;

Procedure Plot(X, Y, C : LongInt);
Var A : LongInt;
Begin
 If (X < ClipX1) Or (Y < ClipY1) Or (X > ClipX2) Or (Y > ClipY2) Then Exit;
 A := (FbH - 1 - Y) * FbW + X;
 If GWrite = XORPut Then Fb[A] := (Fb[A] Xor C) And 255 Else Fb[A] := C And 255;
End;

Procedure HSpan(X1, X2, Y, C : LongInt);
Var A, X : LongInt;
Begin
 If (Y < ClipY1) Or (Y > ClipY2) Then Exit;
 If X1 < ClipX1 Then X1 := ClipX1;
 If X2 > ClipX2 Then X2 := ClipX2;
 If X2 < X1 Then Exit;
 A := (FbH - 1 - Y) * FbW;
 If GWrite = XORPut Then
  For X := X1 To X2 Do Fb[A + X] := (Fb[A + X] Xor C) And 255
 Else
  For X := X1 To X2 Do Fb[A + X] := C And 255;
End;

{ motif de remplissage : bit du point (X, Y) }
Function FillBit(X, Y : LongInt) : Boolean;
Var B : LongInt;
Begin
 Case GFillStyle Of
  EmptyFill : B := 0;
  SolidFill : B := $FF;
  LineFill : If (Y And 7) < 2 Then B := $FF Else B := 0;
  LtSlashFill, SlashFill : B := $80 Shr ((X + Y) And 7);
  BkSlashFill, LtBkSlashFill : B := $01 Shl ((X + Y) And 7);
  HatchFill : If (Y And 7) = 0 Then B := $FF Else B := $80;
  XHatchFill : B := ($80 Shr ((X + Y) And 7)) Or ($01 Shl ((X + Y) And 7));
  InterleaveFill : If (Y And 1) = 0 Then B := $CC Else B := $33;
  WideDotFill : If (Y And 7) = 0 Then B := $80 Else B := 0;
  CloseDotFill : If (Y And 1) = 0 Then B := $88 Else B := 0;
  UserFill : B := GFillPat[(Y And 7) + 1];
 Else
  B := $FF;
 End;
 FillBit := (B And ($80 Shr (X And 7))) <> 0;
End;

{ ligne horizontale remplie selon le motif (bits a 0 : couleur de fond) }
Procedure FillSpan(X1, X2, Y : LongInt);
Var X : LongInt;
Begin
 If GFillStyle = SolidFill Then
 Begin
  HSpan(X1, X2, Y, GFillColor);
  Exit;
 End;
 For X := X1 To X2 Do
  If FillBit(X, Y) Then Plot(X, Y, GFillColor) Else Plot(X, Y, GBk);
End;

{ --- Graph : etat --- }

{ sur une page a fond blanc (PaperMode), les traits et le texte prennent
  la version foncee de leur couleur (blanc -> noir) ; les remplissages
  gardent leurs couleurs }
Procedure SetColor(C : Integer);
Begin
 C := C And 255;
 If PaperMode And (C > 0) And (C < 16) Then C := 16 + C;
 GColor := C;
End;

Function GetColor : Integer;
Begin
 GetColor := GColor;
End;

Procedure SetLineStyle(Style : Integer; Pattern : Word; Thick : Integer);
Begin
 GLineStyle := Style;
 Case Style Of
  DottedLn : GLinePat := $CCCC;
  CenterLn : GLinePat := $FC78;
  DashedLn : GLinePat := $F8F8;
  UserBitLn : GLinePat := Pattern;
 Else
  GLinePat := $FFFF;
 End;
 If Thick >= 3 Then GThick := 3 Else GThick := 1;
End;

Procedure SetFillStyle(Pattern : Integer; Color : Integer);
Begin
 GFillStyle := Pattern;
 GFillColor := Color And 255;
End;

Procedure SetTextStyle(Font, Dir, Size : Integer);
Begin
 If Size < 1 Then Size := 1;
 If Size > 10 Then Size := 10;
 GTextSz := Size;
End;

Procedure SetTextJustify(H, V : Integer);
Begin
 GJustH := H;
 GJustV := V;
End;

{ --- Graph : traits --- }

Procedure LineThin(X1, Y1, X2, Y2 : LongInt);
Var Dx, Dy, Sx, Sy, E, E2, N : LongInt;
Begin
 Dx := Abs(X2 - X1); Dy := -Abs(Y2 - Y1);
 If X1 < X2 Then Sx := 1 Else Sx := -1;
 If Y1 < Y2 Then Sy := 1 Else Sy := -1;
 E := Dx + Dy; N := 0;
 While True Do
 Begin
  If (GLinePat And ($8000 Shr (N And 15))) <> 0 Then Plot(X1, Y1, GColor);
  Inc(N);
  If (X1 = X2) And (Y1 = Y2) Then Exit;
  E2 := 2 * E;
  If E2 >= Dy Then
  Begin
   E := E + Dy; X1 := X1 + Sx;
  End;
  If E2 <= Dx Then
  Begin
   E := E + Dx; Y1 := Y1 + Sy;
  End;
 End;
End;

Procedure LineA(X1, Y1, X2, Y2 : Integer);
Begin
 GTouch(Min2(X1, X2) - 1, Min2(Y1, Y2) - 1, Max2(X1, X2) + 1, Max2(Y1, Y2) + 1);
 If GThick = 3 Then
 Begin
  If Abs(X2 - X1) >= Abs(Y2 - Y1) Then
  Begin
   LineThin(X1, Y1 - 1, X2, Y2 - 1); LineThin(X1, Y1, X2, Y2); LineThin(X1, Y1 + 1, X2, Y2 + 1);
  End
  Else
  Begin
   LineThin(X1 - 1, Y1, X2 - 1, Y2); LineThin(X1, Y1, X2, Y2); LineThin(X1 + 1, Y1, X2 + 1, Y2);
  End;
 End
 Else LineThin(X1, Y1, X2, Y2);
End;

Procedure RectangleA(X1, Y1, X2, Y2 : Integer);
Begin
 LineA(X1, Y1, X2, Y1); LineA(X2, Y1, X2, Y2);
 LineA(X2, Y2, X1, Y2); LineA(X1, Y2, X1, Y1);
End;

Procedure BarA(X1, Y1, X2, Y2 : Integer);
Var Y, T : LongInt;
Begin
 If X1 > X2 Then
 Begin
  T := X1; X1 := X2; X2 := T;
 End;
 If Y1 > Y2 Then
 Begin
  T := Y1; Y1 := Y2; Y2 := T;
 End;
 GTouch(X1, Y1, X2, Y2);
 For Y := Y1 To Y2 Do FillSpan(X1, X2, Y);
End;

Procedure PutPixelA(X, Y : Integer; C : Word);
Begin
 GTouch(X, Y, X, Y);
 Plot(X, Y, C);
End;

Function GetPixelA(X, Y : Integer) : Word;
Begin
 If (X < 0) Or (Y < 0) Or (X >= FbW) Or (Y >= FbH) Then GetPixelA := 0
 Else GetPixelA := Fb[(FbH - 1 - Y) * FbW + X];
End;

{ --- Graph : remplissage d'une region bornee par la couleur Border
  (FloodFill du BGI : lignes de balayage, pile de germes) --- }
Type TFloodMap = Array[0..FbW * FbH - 1] Of Byte;
Var FloodMap : ^TFloodMap;

Procedure FloodFill(X, Y : Integer; Border : Word);
Var Sx, Sy : Array[0..4095] Of Integer; N, L, R, I, Cx, Cy, Dy, Ny : LongInt; Run : Boolean;

 Function Inside(A, B : LongInt) : Boolean;
 Begin
  Inside := (A >= ClipX1) And (A <= ClipX2) And (B >= ClipY1) And (B <= ClipY2) And
   (FloodMap^[B * FbW + A] = 0) And (GetPixelA(A, B) <> (Border And 255));
 End;

Begin
 If FloodMap = Nil Then GetMem(FloodMap, FbW * FbH);
 FillChar(FloodMap^, FbW * FbH, 0);
 N := 0;
 Sx[0] := X + VOX; Sy[0] := Y + VOY; N := 1;
 While N > 0 Do
 Begin
  Dec(N); Cx := Sx[N]; Cy := Sy[N];
  If Inside(Cx, Cy) Then
  Begin
   L := Cx; R := Cx;
   While Inside(L - 1, Cy) Do Dec(L);
   While Inside(R + 1, Cy) Do Inc(R);
   For I := L To R Do FloodMap^[Cy * FbW + I] := 1;
   FillSpan(L, R, Cy);
   For Dy := -1 To 1 Do
    If Dy <> 0 Then
    Begin
     Ny := Cy + Dy; Run := False;
     For I := L To R Do
      If Inside(I, Ny) Then
      Begin
       If (Not Run) And (N <= 4095) Then
       Begin
        Sx[N] := I; Sy[N] := Ny; Inc(N);
       End;
       Run := True;
      End
      Else Run := False;
    End;
  End;
 End;
End;

Procedure CloseGraph;
Begin
End;

{ --- Graph : ellipses (angles en degres, sens trigonometrique) --- }

Procedure EllipseA(X, Y : Integer; StAngle, EndAngle : Word; XR, YR : Word);
Var A, A2, Steps, K, Px, Py, Qx, Qy : LongInt; T : Double;
Begin
 If (XR = 0) And (YR = 0) Then
 Begin
  PutPixelA(X, Y, GColor);
  Exit;
 End;
 A := StAngle; A2 := EndAngle;
 If A2 <= A Then A2 := A2 + 360;
 If (StAngle = 0) And (EndAngle = 360) Then A2 := 360;
 Steps := ((A2 - A) * (XR + YR)) Div 60 + 8;
 If Steps > 720 Then Steps := 720;
 GTouch(X - XR - 2, Y - YR - 2, X + XR + 2, Y + YR + 2);
 T := A * Pi / 180;
 Px := X + Round(XR * Cos(T)); Py := Y - Round(YR * Sin(T));
 For K := 1 To Steps Do
 Begin
  T := (A + (A2 - A) * K / Steps) * Pi / 180;
  Qx := X + Round(XR * Cos(T)); Qy := Y - Round(YR * Sin(T));
  If (Qx <> Px) Or (Qy <> Py) Then
  Begin
   If GThick = 3 Then LineA(Px, Py, Qx, Qy) Else LineThin(Px, Py, Qx, Qy);
   Px := Qx; Py := Qy;
  End;
 End;
End;

Procedure FillEllipseA(X, Y : Integer; XR, YR : Word);
Var Dy, W : LongInt; T : Double;
Begin
 GTouch(X - XR - 1, Y - YR - 1, X + XR + 1, Y + YR + 1);
 For Dy := -YR To YR Do
 Begin
  If YR = 0 Then W := XR
  Else
  Begin
   T := 1 - (Dy * Dy) / (YR * 1.0 * YR);
   If T < 0 Then T := 0;
   W := Round(XR * Sqrt(T));
  End;
  FillSpan(X - W, X + W, Y + Dy);
 End;
 EllipseA(X, Y, 0, 360, XR, YR);
End;

Procedure ArcA(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Begin
 EllipseA(X, Y, StAngle, EndAngle, Radius, Radius);
End;

Procedure CircleA(X, Y : Integer; Radius : Word);
Begin
 EllipseA(X, Y, 0, 360, Radius, Radius);
End;

{ secteur plein de StAngle a EndAngle (degres), puis son contour }
Procedure PieSliceA(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Var Dx, Dy, R2, A0, A1 : LongInt; Ang : Double; Inside : Boolean;
Begin
 A0 := StAngle; A1 := EndAngle;
 If A1 < A0 Then A1 := A1 + 360;
 R2 := LongInt(Radius) * Radius;
 GTouch(X - Radius - 1, Y - Radius - 1, X + Radius + 1, Y + Radius + 1);
 For Dy := -Radius To Radius Do
  For Dx := -Radius To Radius Do
   If Dx * Dx + Dy * Dy <= R2 Then
   Begin
    If (Dx = 0) And (Dy = 0) Then Ang := 0
    Else
    Begin
     If Dx = 0 Then
     Begin
      If Dy < 0 Then Ang := 90 Else Ang := 270;
     End
     Else
     Begin
      Ang := ArcTan(-Dy / Dx) * 180 / Pi;
      If Dx < 0 Then Ang := Ang + 180
      Else If -Dy < 0 Then Ang := Ang + 360;
     End;
    End;
    Inside := (Ang >= A0) And (Ang <= A1);
    If (Not Inside) And (A1 > 360) Then Inside := Ang + 360 <= A1;
    If Inside Then
    Begin
     If FillBit(X + Dx, Y + Dy) Then Plot(X + Dx, Y + Dy, GFillColor)
     Else Plot(X + Dx, Y + Dy, GBk);
    End;
   End;
 { contour : couleur du trait ; si c'est la version foncee (page blanche)
   de la couleur de remplissage, la couleur de remplissage (comme le BGI,
   ou le secteur et son contour sont de la meme couleur) }
 If GColor = 16 + GFillColor Then GColor := GFillColor;
 EllipseA(X, Y, StAngle, EndAngle, Radius, Radius);
 LineA(X, Y, X + Round(Radius * Cos(A0 * Pi / 180)), Y - Round(Radius * Sin(A0 * Pi / 180)));
 LineA(X, Y, X + Round(Radius * Cos(A1 * Pi / 180)), Y - Round(Radius * Sin(A1 * Pi / 180)));
End;

{ --- Graph : texte (police 8 x 8 agrandie GTextSz fois, fond transparent) --- }

Procedure OutTextXYA(X, Y : Integer; S : String);
Var I, R, K, B, C, Sz, W, Cx, R0 : LongInt; Hat : Boolean;
Begin
 If S = '' Then Exit;
 Sz := GTextSz;
 W := Length(S) * 8 * Sz;
 If GJustH = CenterText Then X := X - W Div 2
 Else If GJustH = RightText Then X := X - W;
 If GJustV = CenterText Then Y := Y - 4 * Sz
 Else If GJustV = BottomText Then Y := Y - 8 * Sz;
 GTouch(X, Y - Sz, X + W - 1, Y + 8 * Sz - 1);
 For I := 1 To Length(S) Do
 Begin
  C := Ord(S[I]);
  { a, e, i, o, u circonflexes : dans la police 8 x 8, l'accent colle a
    la lettre ; on dessine la lettre de base puis l'accent au-dessus }
  Hat := True;
  Case C Of
   131 : C := Ord('a');
   136 : C := Ord('e');
   140 : C := Ord('i');
   147 : C := Ord('o');
   150 : C := Ord('u');
  Else Hat := False;
  End;
  If Hat Then R0 := 2 Else R0 := 0;
  Cx := X + (I - 1) * 8 * Sz;
  For R := R0 To 7 Do
  Begin
   B := Font8[C * 8 + R];
   If B <> 0 Then
    For K := 0 To 7 Do
     If (B And ($80 Shr K)) <> 0 Then
     Begin
      If Sz = 1 Then Plot(Cx + K, Y + R, GColor)
      Else For W := 0 To Sz - 1 Do
       HSpan(Cx + K * Sz, Cx + (K + 1) * Sz - 1, Y + R * Sz + W, GColor);
     End;
  End;
  If Hat Then
   For W := 0 To Sz - 1 Do
   Begin
    HSpan(Cx + 3 * Sz, Cx + 5 * Sz - 1, Y - Sz + W, GColor);
    HSpan(Cx + 2 * Sz, Cx + 3 * Sz - 1, Y + W, GColor);
    HSpan(Cx + 5 * Sz, Cx + 6 * Sz - 1, Y + W, GColor);
   End;
 End;
End;

Procedure ClearDevice;
Var K : LongInt;
Begin
 For K := 0 To FbW * FbH - 1 Do Fb[K] := GBk;
 GTouch(0, 0, FbW - 1, FbH - 1);
End;

{ --- Graph : fenetre (SetViewPort), fonctions publiques (coordonnees
  relatives a la fenetre courante) --- }

Procedure SetViewPort(X1, Y1, X2, Y2 : Integer; Clip : Boolean);
Begin
 VOX := X1; VOY := Y1;
 If Clip Then
 Begin
  ClipX1 := Max2(X1, 0); ClipY1 := Max2(Y1, 0);
  ClipX2 := Min2(X2, FbW - 1); ClipY2 := Min2(Y2, FbH - 1);
 End
 Else
 Begin
  ClipX1 := 0; ClipY1 := 0; ClipX2 := FbW - 1; ClipY2 := FbH - 1;
 End;
End;

Procedure ClearViewPort;
Var Y : LongInt;
Begin
 GTouch(ClipX1, ClipY1, ClipX2, ClipY2);
 For Y := ClipY1 To ClipY2 Do HSpan(ClipX1, ClipX2, Y, GBk);
End;

Function GetMaxX : Integer;
Begin
 GetMaxX := FbW - 1;
End;

Function GetMaxY : Integer;
Begin
 GetMaxY := CanvasBot;
End;

Function GraphResult : Integer;
Begin
 GraphResult := 0;
End;

Procedure SetBkColor(C : Integer);
Begin
 GBk := C And 255;
End;

Procedure SetWriteMode(M : Integer);
Begin
 If M = XORPut Then GWrite := XORPut Else GWrite := NormalPut;
End;

Procedure SetFillPattern(Pat : FillPatternType; Color : Integer);
Var I : Integer;
Begin
 For I := 1 To 8 Do GFillPat[I] := Pat[I];
 GFillStyle := UserFill;
 GFillColor := Color And 255;
End;

Function TextWidth(S : String) : Integer;
Begin
 TextWidth := Length(S) * 8 * GTextSz;
End;

Function TextHeight(S : String) : Integer;
Begin
 TextHeight := 8 * GTextSz;
End;

Procedure Line(X1, Y1, X2, Y2 : Integer);
Begin
 LineA(X1 + VOX, Y1 + VOY, X2 + VOX, Y2 + VOY);
End;

Procedure Rectangle(X1, Y1, X2, Y2 : Integer);
Begin
 RectangleA(X1 + VOX, Y1 + VOY, X2 + VOX, Y2 + VOY);
End;

Procedure Bar(X1, Y1, X2, Y2 : Integer);
Begin
 BarA(X1 + VOX, Y1 + VOY, X2 + VOX, Y2 + VOY);
End;

Procedure PutPixel(X, Y : Integer; C : Word);
Begin
 PutPixelA(X + VOX, Y + VOY, C);
End;

Function GetPixel(X, Y : Integer) : Word;
Begin
 GetPixel := GetPixelA(X + VOX, Y + VOY);
End;

Procedure Ellipse(X, Y : Integer; StAngle, EndAngle : Word; XR, YR : Word);
Begin
 EllipseA(X + VOX, Y + VOY, StAngle, EndAngle, XR, YR);
End;

Procedure FillEllipse(X, Y : Integer; XR, YR : Word);
Begin
 FillEllipseA(X + VOX, Y + VOY, XR, YR);
End;

Procedure Arc(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Begin
 ArcA(X + VOX, Y + VOY, StAngle, EndAngle, Radius);
End;

Procedure Circle(X, Y : Integer; Radius : Word);
Begin
 CircleA(X + VOX, Y + VOY, Radius);
End;

Procedure PieSlice(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Begin
 PieSliceA(X + VOX, Y + VOY, StAngle, EndAngle, Radius);
End;

Procedure OutTextXY(X, Y : Integer; S : String);
Begin
 OutTextXYA(X + VOX, Y + VOY, S);
End;

{ polygone plein (regle pair-impair), puis son contour }
Procedure FillPoly(N : Integer; Var Pts);
Type TPts = Array[1..512] Of PointType;
Var P : ^TPts; I, J, Y, Y1, Y2, K, Cnt, T, Xa, Ya, Xb, Yb : LongInt; Xs : Array[0..127] Of LongInt;
Begin
 P := @Pts;
 If (N < 2) Or (N > 512) Then Exit;
 Y1 := P^[1].Y; Y2 := P^[1].Y;
 For I := 2 To N Do
 Begin
  If P^[I].Y < Y1 Then Y1 := P^[I].Y;
  If P^[I].Y > Y2 Then Y2 := P^[I].Y;
 End;
 For Y := Y1 To Y2 Do
 Begin
  Cnt := 0;
  For I := 1 To N Do
  Begin
   J := I + 1;
   If J > N Then J := 1;
   Xa := P^[I].X; Ya := P^[I].Y; Xb := P^[J].X; Yb := P^[J].Y;
   If ((Ya <= Y) And (Yb > Y)) Or ((Yb <= Y) And (Ya > Y)) Then
    If Cnt < 128 Then
    Begin
     Xs[Cnt] := Xa + ((Y - Ya) * (Xb - Xa)) Div (Yb - Ya);
     Inc(Cnt);
    End;
  End;
  For I := 1 To Cnt - 1 Do
  Begin
   T := Xs[I]; K := I - 1;
   While (K >= 0) And (Xs[K] > T) Do
   Begin
    Xs[K + 1] := Xs[K];
    Dec(K);
   End;
   Xs[K + 1] := T;
  End;
  I := 0;
  While I + 1 < Cnt Do
  Begin
   GTouch(Xs[I] + VOX, Y + VOY, Xs[I + 1] + VOX, Y + VOY);
   FillSpan(Xs[I] + VOX, Xs[I + 1] + VOX, Y + VOY);
   I := I + 2;
  End;
 End;
 For I := 1 To N Do
 Begin
  J := I + 1;
  If J > N Then J := 1;
  Line(P^[I].X, P^[I].Y, P^[J].X, P^[J].Y);
 End;
End;

Procedure DrawPoly(N : Integer; Var Pts);
Type TPtsD = Array[1..512] Of PointType;
Var P : ^TPtsD; I : LongInt;
Begin
 P := @Pts;
 For I := 1 To N - 1 Do Line(P^[I].X, P^[I].Y, P^[I + 1].X, P^[I + 1].Y);
End;

{ images : largeur, hauteur (2 mots) puis un octet par point }
Function ImageSize(X1, Y1, X2, Y2 : Integer) : Word;
Begin
 ImageSize := (Abs(X2 - X1) + 1) * (Abs(Y2 - Y1) + 1) + 4;
End;

Procedure GetImage(X1, Y1, X2, Y2 : Integer; Var BitMap);
Type TBy64K = Array[0..65535] Of Byte;
Var P : ^TBy64K; X, Y, W, H, K : LongInt;
Begin
 P := @BitMap;
 W := X2 - X1 + 1; H := Y2 - Y1 + 1;
 P^[0] := W And 255; P^[1] := W Shr 8; P^[2] := H And 255; P^[3] := H Shr 8;
 K := 4;
 For Y := Y1 To Y2 Do
  For X := X1 To X2 Do
  Begin
   P^[K] := GetPixel(X, Y);
   Inc(K);
  End;
End;

Procedure PutImage(X1, Y1 : Integer; Var BitMap; Op : Word);
Type TBP = Array[0..65535] Of Byte;
Var P : ^TBP; X, Y, W, H, K, Old : LongInt;
Begin
 P := @BitMap;
 W := P^[0] + P^[1] * 256; H := P^[2] + P^[3] * 256;
 Old := GWrite;
 If Op = XORPut Then GWrite := XORPut Else GWrite := NormalPut;
 GTouch(X1 + VOX, Y1 + VOY, X1 + VOX + W - 1, Y1 + VOY + H - 1);
 K := 4;
 For Y := 0 To H - 1 Do
  For X := 0 To W - 1 Do
  Begin
   Plot(X1 + VOX + X, Y1 + VOY + Y, P^[K]);
   Inc(K);
  End;
 GWrite := Old;
End;

{ --- palette de l'image (BITMAPINFO2 de 8 bits) --- }

Procedure InitBmi;
Const
 Pal : Array[0..31] Of LongInt = (
  $000000, $0000AA, $00AA00, $00AAAA, $AA0000, $AA00AA, $AA5500, $AAAAAA,
  $555555, $5555FF, $55FF55, $55FFFF, $FF5555, $FF55FF, $FFFF55, $FFFFFF,
  { couleurs foncees pour le fond blanc (16 + couleur du BGI) }
  $000000, $00008C, $00782A, $006E78, $A00000, $820082, $8C4600, $505050,
  $969696, $1E46C8, $00963C, $0082A0, $D21E1E, $B400B4, $A07800, $000000);
Var I, A : LongInt;
Begin
 FillChar(Bmi, SizeOf(Bmi), 0);
 WrL(LongInt(@Bmi), 16);
 WrL(LongInt(@Bmi) + 4, FbW);
 WrL(LongInt(@Bmi) + 8, FbH);
 WrW(LongInt(@Bmi) + 12, 1);
 WrW(LongInt(@Bmi) + 14, 8);
 For I := 0 To 31 Do
 Begin
  A := LongInt(@Bmi) + 16 + I * 4;
  WrB(A, Pal[I] And 255);
  WrB(A + 1, (Pal[I] Shr 8) And 255);
  WrB(A + 2, (Pal[I] Shr 16) And 255);
 End;
 GColor := White; GBk := Black; GFillStyle := SolidFill; GFillColor := White;
 GLineStyle := SolidLn; GLinePat := $FFFF; GThick := 1; GWrite := NormalPut;
 GTextSz := 1; GJustH := LeftText; GJustV := TopText; PaperMode := False;
 VOX := 0; VOY := 0; ClipX1 := 0; ClipY1 := 0; ClipX2 := FbW - 1; ClipY2 := FbH - 1;
 KeyH := 0; KeyT := 0; PendScan := -1; MenuUp := 0; MenuStale := 0; WasActive := 1; CmdH := 0; CmdT := 0; MBtn := 0; MLatch := 0;
 DirtyX1 := -1;
End;

{ couleur I de la palette de l'image (32 a 255 : couleurs du programme),
  RGB = $RRGGBB }
Procedure SetPalEntry(I, RGB : LongInt);
Var A : LongInt;
Begin
 A := LongInt(@Bmi) + 16 + I * 4;
 WrB(A, RGB And 255);
 WrB(A + 1, (RGB Shr 8) And 255);
 WrB(A + 2, (RGB Shr 16) And 255);
End;

{ couleur foncee (lisible sur fond blanc) d'une couleur du BGI }
Function DocCol(C : Integer) : Integer;
Begin
 DocCol := 16 + (C And 15);
End;

{ --- affichage dans la zone client --- }

{ montrer la zone X1..X2, Y1..Y2 de l'image (Y vers le bas) dans la zone
  client : seules les lignes CanvasTop a CanvasBot de l'image sont
  montrees ; la ligne Y de l'image est la ligne CanvasBot - Y du client }
{ fenetre secondaire de PM (vue graphique dans sa propre fenetre) : elle
  montre le rectangle CatX0, CatY0, CatW x CatH de l'image, sauf les
  rectangles de ses controles (PMWIN ne decoupe pas le dessin du parent
  autour de ses fenetres filles) }
Var
 CatFr, CatCl, CatX0, CatY0, CatW, CatH, CatNEx : LongInt;
 CatMode : LongInt;                  { 0 : rectangles exclus ; 1 : seuls ceux-ci sont montres }
 CatSrc : Pointer;                   { image montree (Nil : Fb) }
 CatSave : Pointer;                  { image de la fenetre principale figee }
 CatEx : Array[0..63, 0..3] Of LongInt;

Procedure CatBlitK(Hps, X1, Y1, X2, Y2, K : LongInt);
Var P : Array[0..7] Of LongInt; A1, B1, A2, B2 : LongInt;
Begin
 If (X2 < X1) Or (Y2 < Y1) Then Exit;
 If K < CatNEx Then
 Begin
  A1 := CatEx[K, 0]; B1 := CatEx[K, 1]; A2 := CatEx[K, 2]; B2 := CatEx[K, 3];
  If (A1 > X2) Or (A2 < X1) Or (B1 > Y2) Or (B2 < Y1) Then
   CatBlitK(Hps, X1, Y1, X2, Y2, K + 1)
  Else
  Begin
   If B1 > Y1 Then CatBlitK(Hps, X1, Y1, X2, B1 - 1, K + 1);
   If B2 < Y2 Then CatBlitK(Hps, X1, B2 + 1, X2, Y2, K + 1);
   If B1 > Y1 Then Y1 := B1;
   If B2 < Y2 Then Y2 := B2;
   If A1 > X1 Then CatBlitK(Hps, X1, Y1, A1 - 1, Y2, K + 1);
   If A2 < X2 Then CatBlitK(Hps, A2 + 1, Y1, X2, Y2, K + 1);
  End;
  Exit;
 End;
 P[0] := X1 - CatX0; P[1] := CatY0 + CatH - 1 - Y2;
 P[2] := X2 + 1 - CatX0; P[3] := CatY0 + CatH - Y1;
 P[4] := X1; P[5] := FbH - 1 - Y2; P[6] := X2 + 1; P[7] := FbH - Y1;
 If CatSrc <> Nil Then Dummy := GpiDrawBits(Hps, LongInt(CatSrc), LongInt(@Bmi), 4, LongInt(@P), $CC, 0)
 Else Dummy := GpiDrawBits(Hps, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

Procedure CatBlit(Hps, X1, Y1, X2, Y2 : LongInt);
Var K, N, A1, B1, A2, B2 : LongInt;
Begin
 If X1 < CatX0 Then X1 := CatX0;
 If Y1 < CatY0 Then Y1 := CatY0;
 If X2 > CatX0 + CatW - 1 Then X2 := CatX0 + CatW - 1;
 If Y2 > CatY0 + CatH - 1 Then Y2 := CatY0 + CatH - 1;
 If CatMode = 0 Then
 Begin
  CatBlitK(Hps, X1, Y1, X2, Y2, 0);
  Exit;
 End;
 { seuls les rectangles de la liste (parties dessinees) sont montres }
 N := CatNEx; CatNEx := 0;
 For K := 0 To N - 1 Do
 Begin
  A1 := CatEx[K, 0]; B1 := CatEx[K, 1]; A2 := CatEx[K, 2]; B2 := CatEx[K, 3];
  If A1 < X1 Then A1 := X1;
  If B1 < Y1 Then B1 := Y1;
  If A2 > X2 Then A2 := X2;
  If B2 > Y2 Then B2 := Y2;
  If (A1 <= A2) And (B1 <= B2) Then CatBlitK(Hps, A1, B1, A2, B2, 0);
 End;
 CatNEx := N;
End;

Procedure Blit(Hps, X1, Y1, X2, Y2 : LongInt);
Var P : Array[0..7] Of LongInt; Src : LongInt;
Begin
 Src := LongInt(@Fb);
 If (CatCl <> 0) And (CatSave <> Nil) Then Src := LongInt(CatSave);
 If Y1 < CanvasTop Then Y1 := CanvasTop;
 If Y2 > CanvasBot Then Y2 := CanvasBot;
 If (X2 < X1) Or (Y2 < Y1) Then Exit;
 P[0] := X1; P[1] := CanvasBot - Y2; P[2] := X2 + 1; P[3] := CanvasBot - Y1 + 1;
 P[4] := X1; P[5] := FbH - 1 - Y2; P[6] := X2 + 1; P[7] := FbH - Y1;
 Dummy := GpiDrawBits(Hps, Src, LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

{ envoyer a l'ecran ce qui a change depuis le dernier appel }
Procedure FlushScreen;
Var Hps, Cap : LongInt;
Begin
 If OsClient = 0 Then Exit;
 { PM ne decoupe pas le dessin par les fenetres qui recouvrent celle-ci :
   rien n'est montre hors de WM_PAINT quand un menu est ouvert ou que la
   fenetre n'est pas active ; tout est remontre au retour }
 Cap := WinQueryCapture(HWND_DESKTOP);
 If (MenuUp <> 0) And (Cap = 0) Then
 Begin
  Inc(MenuStale);
  If MenuStale > 5 Then MenuUp := 0;
 End
 Else MenuStale := 0;
 { vue graphique dans une fenetre a part : seule celle-ci est mise a jour }
 If CatCl <> 0 Then
 Begin
  WasActive := 0;
  If (MenuUp = 0) And (DirtyX1 >= 0) And (WinQueryActiveWindow(HWND_DESKTOP) = CatFr) Then
  Begin
   Hps := WinGetPS(CatCl);
   If Hps <> 0 Then
   Begin
    CatBlit(Hps, DirtyX1, DirtyY1, DirtyX2, DirtyY2);
    Dummy := WinReleasePS(Hps);
   End;
   DirtyX1 := -1;
  End;
  Exit;
 End;
 If (MenuUp <> 0) Or ((Cap <> 0) And (Cap <> OsClient)) Or
    (WinQueryActiveWindow(HWND_DESKTOP) <> OsFrame) Then
 Begin
  WasActive := 0;
  Exit;
 End;
 If WasActive = 0 Then
 Begin
  GTouch(0, 0, FbW - 1, FbH - 1);
  WasActive := 1;
 End;
 If DirtyX1 < 0 Then Exit;
 Hps := WinGetPS(OsClient);
 If Hps <> 0 Then
 Begin
  Blit(Hps, DirtyX1, DirtyY1, DirtyX2, DirtyY2);
  Dummy := WinReleasePS(Hps);
 End;
 DirtyX1 := -1;
End;

{ --- file d'evenements (remplie par la procedure de fenetre) --- }

Procedure EvPush(K, Key, X, Y : LongInt);
Var N : LongInt;
Begin
 N := (EvTail + 1) Mod EvQMax;
 If N = EvHead Then Exit;
 EvKind[EvTail] := K; EvKey[EvTail] := Key; EvX[EvTail] := X; EvY[EvTail] := Y;
 EvTail := N;
End;

{ Alt + lettre -> code de balayage du clavier du PC }
Function AltScan(C : Char) : LongInt;
Const
 R1 : String[10] = 'QWERTYUIOP';
 R2 : String[9] = 'ASDFGHJKL';
 R3 : String[7] = 'ZXCVBNM';
Begin
 AltScan := 0;
 C := UpCase(C);
 If Pos(C, R1) > 0 Then AltScan := 15 + Pos(C, R1);
 If Pos(C, R2) > 0 Then AltScan := 29 + Pos(C, R2);
 If Pos(C, R3) > 0 Then AltScan := 43 + Pos(C, R3);
End;

{ touche de PM (WM_CHAR) -> code de la version DOS : caractere = Ord,
  touche etendue = 256 + code de balayage du BIOS }
Function KeyCode(Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Ch, Vk, K : LongInt;
Begin
 KeyCode := -1;
 Fl := Lo16(Mp1); Ch := Lo16(Mp2); Vk := Hi16(Mp2);
 If (Fl And KC_KEYUP) <> 0 Then Exit;
 K := -1;
 If (Fl And KC_VIRTUALKEY) <> 0 Then
 Begin
  Case Vk Of
   VK_ESC : K := 27;
   VK_NEWLINE, VK_ENTER : K := 13;
   VK_BACKSPACE : K := 8;
   VK_TAB : If (Fl And KC_SHIFT) <> 0 Then K := 271 Else K := 9;
   VK_BACKTAB : K := 271;
   VK_UP : K := 328;
   VK_DOWN : K := 336;
   VK_LEFT : If (Fl And KC_CTRL) <> 0 Then K := 371 Else K := 331;
   VK_RIGHT : If (Fl And KC_CTRL) <> 0 Then K := 372 Else K := 333;
   VK_HOME : If (Fl And KC_CTRL) <> 0 Then K := 375 Else K := 327;
   VK_END : If (Fl And KC_CTRL) <> 0 Then K := 373 Else K := 335;
   VK_PAGEUP : If (Fl And KC_CTRL) <> 0 Then K := 388 Else K := 329;
   VK_PAGEDOWN : If (Fl And KC_CTRL) <> 0 Then K := 374 Else K := 337;
   VK_INSERT : K := 338;
   VK_DELETE : K := 339;
  End;
  If (Vk >= VK_F1) And (Vk <= VK_F1 + 9) And ((Fl And (KC_ALT Or KC_CTRL Or KC_SHIFT)) = 0) Then
   K := 315 + Vk - VK_F1;
 End;
 If (K < 0) And ((Fl And KC_ALT) <> 0) And (Ch > 0) And (Ch < 256) Then
 Begin
  { Alt + lettre d'un titre de menu : laissee a la barre de menus de PM }
  If (AltScan(Chr(Ch)) > 0) And (Pos(UpCase(Chr(Ch)), MnemoKeys) = 0) Then
   K := 256 + AltScan(Chr(Ch));
 End
 Else If (K < 0) And ((Fl And KC_CHAR) <> 0) And (Ch > 0) And (Ch < 256) Then
 Begin
  K := Ch;
  If ((Fl And KC_CTRL) <> 0) And (UpCase(Chr(Ch)) >= 'A') And (UpCase(Chr(Ch)) <= 'Z') Then
   K := Ord(UpCase(Chr(Ch))) - 64;
 End;
 { Ctrl + lettre sans KC_CHAR }
 If (K < 0) And ((Fl And KC_CTRL) <> 0) And ((Fl And KC_ALT) = 0) And (Ch > 0) And (Ch < 256) Then
  If (UpCase(Chr(Ch)) >= 'A') And (UpCase(Chr(Ch)) <= 'Z') Then K := Ord(UpCase(Chr(Ch))) - 64;
 KeyCode := K;
End;

Procedure MenuInit(M : LongInt); Forward;
Procedure BuildMenuBar; Forward;

Procedure KeyPush(K : LongInt);
Var N : LongInt;
Begin
 N := (KeyT + 1) And 127;
 If N = KeyH Then Exit;
 KeyQ[KeyT] := K;
 KeyT := N;
End;

Procedure CmdPush(C : LongInt);
Var N : LongInt;
Begin
 N := (CmdT + 1) And 31;
 If N = CmdH Then Exit;
 CmdQ[CmdT] := C;
 CmdT := N;
End;

{ procedure de la zone client : touches (file des touches, codes du BIOS),
  souris (position, boutons ; un clic bref reste vu une fois par
  GetMouseState) et commandes des menus (file des commandes) }
Function ClientProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, K, X, Y : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 ClientProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, LongInt(@Rc));
    Blit(Hps, 0, CanvasTop, FbW - 1, CanvasBot);
    Dummy := WinEndPaint(Hps);
   End;
  WM_CHAR :
   Begin
    K := KeyCode(Mp1, Mp2);
    If K >= 0 Then
    Begin
     KeyPush(K);
     ClientProc := 1;
    End
    Else ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_MOUSEMOVE :
   Begin
    EvMX := S16(Mp1); EvMY := CanvasBot - S16(Mp1 Shr 16);
    ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_BUTTON1DOWN, WM_BUTTON1DBLCLK, WM_BUTTON2DOWN, $0076 :
   Begin
    EvMX := S16(Mp1); EvMY := CanvasBot - S16(Mp1 Shr 16);
    Dummy := WinSetFocus(HWND_DESKTOP, H);
    Dummy := WinSetCapture(HWND_DESKTOP, H);
    If (Msg = WM_BUTTON1DOWN) Or (Msg = WM_BUTTON1DBLCLK) Then K := 1 Else K := 2;
    MBtn := MBtn Or K; MLatch := MLatch Or K;
    EvPush(EV_CLICK, K, EvMX, EvMY);
    ClientProc := 1;
   End;
  WM_BUTTON1UP, $0075 :
   Begin
    EvMX := S16(Mp1); EvMY := CanvasBot - S16(Mp1 Shr 16);
    If Msg = WM_BUTTON1UP Then MBtn := MBtn And Not 1 Else MBtn := MBtn And Not 2;
    If MBtn = 0 Then Dummy := WinSetCapture(HWND_DESKTOP, 0);
    ClientProc := 1;
   End;
  WM_COMMAND : CmdPush(Lo16(Mp1));
  WM_INITMENU : Begin MenuUp := 1; MenuInit(Lo16(Mp1)); End;
  WM_MENUEND : MenuUp := 0;
  WM_CLOSE : CmdPush(CMD_CLOSE);
 Else
  ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

Procedure PumpMessages;
Begin
 While WinPeekMsg(OsHab, LongInt(@Qmsg), 0, 0, 0, PM_REMOVE) <> 0 Do
 Begin
  If Qmsg[1] = WM_QUIT Then CmdPush(CMD_CLOSE)
  Else Dummy := WinDispatchMsg(OsHab, LongInt(@Qmsg));
 End;
End;

{ --- Crt et souris emules --- }

Function KeyPressed : Boolean;
Begin
 FlushScreen;
 PumpMessages;
 If (KeyH = KeyT) And (PendScan < 0) Then Dummy := DosSleep(1);
 KeyPressed := (KeyH <> KeyT) Or (PendScan >= 0);
End;

{ touche etendue (code >= 256) : #0 puis le code de balayage }
Function ReadKey : Char;
Var K : LongInt;
Begin
 If PendScan >= 0 Then
 Begin
  ReadKey := Chr(PendScan);
  PendScan := -1;
  Exit;
 End;
 While KeyH = KeyT Do
 Begin
  FlushScreen;
  PumpMessages;
  If KeyH = KeyT Then Dummy := DosSleep(10);
 End;
 K := KeyQ[KeyH];
 KeyH := (KeyH + 1) And 127;
 If K >= 256 Then
 Begin
  PendScan := K - 256;
  ReadKey := #0;
 End
 Else ReadKey := Chr(K);
End;

Procedure Delay(Ms : Word);
Begin
 FlushScreen;
 PumpMessages;
 Dummy := DosSleep(Ms);
End;

Procedure GetMouseState(Var X, Y, Button : LongInt);
Begin
 FlushScreen;
 PumpMessages;
 X := EvMX; Y := EvMY;
 Button := MBtn Or MLatch;
 MLatch := 0;
End;

{ commande de la barre de menus en attente (CMD_CLOSE : fermeture) }
Function PollCmd(Var C : LongInt) : Boolean;
Begin
 PumpMessages;
 PollCmd := CmdH <> CmdT;
 If CmdH <> CmdT Then
 Begin
  C := CmdQ[CmdH];
  CmdH := (CmdH + 1) And 31;
 End;
End;

{ --- gabarit de la barre de menus (MENUTEMPLATE) --- }

Procedure MnB(V : LongInt);
Begin
 MenuT[MenuLen] := V And 255;
 Inc(MenuLen);
End;

Procedure MnW(V : LongInt);
Begin
 MnB(V And 255);
 MnB((V Shr 8) And 255);
End;

Function MnOpen : LongInt;
Begin
 MnOpen := MenuLen;
 MnW(0); MnW(0); MnW(0);
End;

Procedure MnClose(H, Count : LongInt);
Begin
 WrW(LongInt(@MenuT) + H, MenuLen - H);
 WrW(LongInt(@MenuT) + H + 4, Count);
End;

Procedure MnItem(Style, Attr, Id : LongInt; S : String);
Var K : LongInt;
Begin
 MnW(Style); MnW(Attr); MnW(Id);
 If (Style And MIS_SEPARATOR) = 0 Then
 Begin
  For K := 1 To Length(S) Do MnB(Ord(S[K]));
  MnB(0);
 End;
End;

Procedure MnAttr(Id, Attr : LongInt; On : Boolean);
Var V : LongInt;
Begin
 If On Then V := Attr Else V := 0;
 Dummy := WinSendMsg(OsMenu, MM_SETITEMATTR, Id Or $10000, Attr Or (V Shl 16));
End;

{ libelle de la version DOS ('&Fichier') -> libelle de PM ('~Fichier') }
Function PmLabel(S : String) : String;
Var I : Integer;
Begin
 For I := 1 To Length(S) Do If S[I] = '&' Then S[I] := '~';
 PmLabel := S;
End;

{ --- boites de message d'OS/2 --- }

Function PmBox(Title, Txt : String; Fl : LongInt) : LongInt;
Begin
 FlushScreen;
 PutZ(LongInt(@TxtBuf), Txt);
 PmBox := WinMessageBox(HWND_DESKTOP, OsFrame, LongInt(@TxtBuf), OsZ(Title), 0, Fl Or MB_MOVEABLE);
End;

{ titre de la fenetre (change seulement s'il differe) }
Procedure SetTitle(S : String);
Begin
 If (S = OsTitle) Or (OsFrame = 0) Then Exit;
 OsTitle := S;
 Dummy := WinSetWindowText(OsFrame, OsZ(S));
End;

{ fenetre principale : zone client de 640 x (CanvasBot + 1 - CanvasTop) }
Procedure OpenWindow(Cls, Title : String);
Var Fl, W, H, X, Y, Sw, Sh : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 OsHab := WinInitialize(0);
 OsHmq := WinCreateMsgQueue(OsHab, 64);
 Dummy := WinRegisterClass(OsHab, OsZ(Cls), LongInt(@ClientProc), 0, 0);
 Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_TASKLIST Or FCF_DLGBORDER;
 OsClient := 0;
 OsFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), OsZ(Cls),
   OsZ2(Title), 0, 0, 0, LongInt(@OsClient));
 OsTitle := Title;
 BuildMenuBar;
 Rc[0] := 0; Rc[1] := 0; Rc[2] := FbW; Rc[3] := CanvasBot + 1 - CanvasTop;
 Dummy := WinCalcFrameRect(OsFrame, LongInt(@Rc), 0);
 W := Rc[2] - Rc[0]; H := Rc[3] - Rc[1];
 Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
 X := (Sw - W) Div 2; Y := (Sh - H) Div 2;
 If X < 0 Then X := 0;
 { ecran trop petit : barre de titre en haut de l'ecran }
 If Y < 0 Then Y := Sh - H;
 Dummy := WinSetWindowPos(OsFrame, HWND_TOP, X, Y, W, H,
   SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
 Dummy := WinSetFocus(HWND_DESKTOP, OsClient);
End;

{ --- elements d'interface dessines dans le style d'OS/2 --- }

{ relief : clair en haut a gauche, sombre en bas a droite (ou l'inverse) }
Procedure Bevel(X1, Y1, X2, Y2 : Integer; Sunken : Boolean);
Begin
 If Sunken Then SetColor(DarkGray) Else SetColor(White);
 Line(X1, Y1, X2, Y1);
 Line(X1, Y1, X1, Y2);
 If Sunken Then SetColor(White) Else SetColor(DarkGray);
 Line(X1, Y2, X2, Y2);
 Line(X2, Y1, X2, Y2);
End;

{ rectangle pointille (focus d'OS/2) }
Procedure FocusRect(X1, Y1, X2, Y2 : Integer);
Begin
 SetLineStyle(DottedLn, 0, 1);
 SetColor(Black);
 Rectangle(X1, Y1, X2, Y2);
 SetLineStyle(SolidLn, 0, 1);
End;

{ barre de defilement verticale d'OS/2 (fleches, glissiere, curseur) }
Procedure DrawVScroll(X1, Y1, X2, Y2 : Integer; Top, N, Vis : LongInt);
Var Ty, Th, Cx, R : LongInt;
Begin
 SetFillStyle(SolidFill, LightGray);
 Bar(X1, Y1, X2, Y2);
 For Ty := Y1 + 14 To Y2 - 14 Do
  For Cx := X1 To X2 Do
   If ((Cx + Ty) And 1) = 0 Then Plot(Cx, Ty, White);
 Bar(X1, Y1, X2, Y1 + 13);
 Bevel(X1, Y1, X2, Y1 + 13, False);
 Bar(X1, Y2 - 13, X2, Y2);
 Bevel(X1, Y2 - 13, X2, Y2, False);
 Cx := (X1 + X2) Div 2;
 SetColor(Black);
 For R := 0 To 3 Do
 Begin
  Line(Cx - R, Y1 + 5 + R, Cx + R, Y1 + 5 + R);
  Line(Cx - R, Y2 - 5 - R, Cx + R, Y2 - 5 - R);
 End;
 If (N <= Vis) Or (N <= 0) Then Exit;
 Th := (Y2 - Y1 - 28) * Vis Div N;
 If Th < 12 Then Th := 12;
 Ty := Y1 + 14 + (Y2 - Y1 - 28 - Th) * Top Div (N - Vis);
 Bar(X1, Ty, X2, Ty + Th);
 Bevel(X1, Ty, X2, Ty + Th, False);
End;

Procedure InitializeGraphics;
Begin
 InitBmi;
 OsFrame := 0; OsClient := 0;
 OpenWindow('ACROBAT', 'Acrodoc');
 InitializeScreenPalette;
 SetColor(White);
 SetLineStyle(0,0,1);
End;

{ souris de PM (couche OS/2) : le pointeur est celui du systeme }
Function MouseDriverFound: Boolean;
Begin
 MouseDriverFound := True;
End;

Procedure ShowMouse;
Begin
End;

Procedure HideMouse;
Begin
End;

{ ---------------------------------------------------------------------- }
{ Utilitaires                                                              }
{ ---------------------------------------------------------------------- }

Var
 Layers: PLayerArr;
 LayerCount, LayerCap: Integer;

Function LayerOn(L: Integer): Boolean;
Begin
 If L = 0 Then LayerOn := True
 Else If (L = $FFFF) Or (L > LayerCount) Or (Layers = Nil) Then LayerOn := L = 0
 Else LayerOn := Layers^[L - 1].On;
End;

Function LayerAdd(Num: LongInt; Const Name: String; On: Boolean): Integer;
Var
 P: Pointer;
 NewCap: Integer;
Begin
 LayerAdd := -1;
 If LayerCount >= LayerCap Then Begin
  NewCap := LayerCap * 2 + 16;
  If NewCap > 60000 Then Exit;
  P := Layers;
  ReAllocMem(P, NewCap * SizeOf(TLayer));
  If P = Nil Then Exit;
  Layers := P;
  LayerCap := NewCap;
 End;
 Layers^[LayerCount].Num := Num;
 Layers^[LayerCount].Name := Name;
 Layers^[LayerCount].On := On;
 Inc(LayerCount);
 LayerAdd := LayerCount - 1;
End;

Function LayerFind(Num: LongInt): Integer;
Var
 I: Integer;
Begin
 LayerFind := -1;
 For I := 0 To LayerCount - 1 Do
  If Layers^[I].Num = Num Then Begin LayerFind := I; Exit; End;
End;

Function IMin(A, B: LongInt): LongInt;
Begin
 If A < B Then IMin := A Else IMin := B;
End;

Function IMax(A, B: LongInt): LongInt;
Begin
 If A > B Then IMax := A Else IMax := B;
End;

Function IAbs(A: LongInt): LongInt;
Begin
 If A < 0 Then IAbs := -A Else IAbs := A;
End;

Function C16(V: LongInt): Integer;
Begin
 If V < -30000 Then V := -30000;
 If V > 30000 Then V := 30000;
 C16 := V;
End;

Function IStr(N: LongInt): String;
Var
 S: String;
Begin
 Str(N, S);
 IStr := S;
End;

Function StrInt(Const S: String; Def: LongInt): LongInt;
Var
 V: LongInt;
 Code: Integer;
Begin
 Val(S, V, Code);
 If Code <> 0 Then StrInt := Def Else StrInt := V;
End;

Function UpStr(S: String): String;
Var
 I: Integer;
Begin
 For I := 1 To Length(S) Do
  If (S[I] >= 'a') And (S[I] <= 'z') Then S[I] := Chr(Ord(S[I]) - 32);
 UpStr := S;
End;

Function Pad2(N: LongInt): String;
Begin
 If N < 10 Then Pad2 := '0' + IStr(N) Else Pad2 := IStr(N);
End;

{ Réel -> texte PDF (2 décimales au maximum) }
Function RStr(R: Real): String;
Var
 S: String;
 L: LongInt;
 Neg: Boolean;
 F: LongInt;
Begin
 Neg := R < 0;
 If Neg Then R := -R;
 L := Trunc(R);
 F := Round((R - L) * 100);
 If F >= 100 Then Begin Inc(L); F := 0; End;
 S := IStr(L);
 If F > 0 Then Begin
  If F < 10 Then S := S + '.0' + IStr(F)
  Else Begin
   S := S + '.' + IStr(F);
   If S[Length(S)] = '0' Then Delete(S, Length(S), 1);
  End;
 End;
 If Neg And (S <> '0') Then S := '-' + S;
 RStr := S;
End;

{ Réel -> texte PDF avec 4 décimales (matrices de rotation) }
Function RStr4(R: Real): String;
Var
 L, F: LongInt;
 Neg: Boolean;
 S, T: String;
Begin
 Neg := R < 0;
 If Neg Then R := -R;
 L := Trunc(R);
 F := Round((R - L) * 10000);
 If F >= 10000 Then Begin Inc(L); F := 0; End;
 S := IStr(L);
 If F > 0 Then Begin
  T := IStr(F);
  While Length(T) < 4 Do T := '0' + T;
  While T[Length(T)] = '0' Do Delete(T, Length(T), 1);
  S := S + '.' + T;
 End;
 If Neg And (S <> '0') Then S := '-' + S;
 RStr4 := S;
End;

Function FileExists(Const Name: String): Boolean;
Var
 F: File;
 Attr: Word;
Begin
 Assign(F, Name);
 GetFAttr(F, Attr);
 FileExists := (DosError = 0) And ((Attr And Directory) = 0);
End;

Function ExtOf(Const Name: String): String;
Var
 I: Integer;
Begin
 I := Length(Name);
 While (I > 0) And (Name[I] <> '.') And (Name[I] <> '\') And (Name[I] <> '/') Do Dec(I);
 If (I > 0) And (Name[I] = '.') Then ExtOf := UpStr(Copy(Name, I, 255)) Else ExtOf := '';
End;

Function BaseName(Const Name: String): String;
Var
 I: Integer;
Begin
 I := Length(Name);
 While (I > 0) And (Name[I] <> '\') And (Name[I] <> '/') Do Dec(I);
 BaseName := Copy(Name, I + 1, 255);
End;

Function NowMs: LongInt;
Var
 H, M, S, S100: Word;
Begin
 GetTime(H, M, S, S100);
 NowMs := ((LongInt(H) * 60 + M) * 60 + S) * 1000 + S100 * 10;
End;

{ Conversion WinAnsi -> glyphe CP437 de la police 8x8 }
Function Win2Glyph(C: Integer): Integer;
Begin
 Win2Glyph := C;
 If C < 128 Then Exit;
 Case C Of
  199: Win2Glyph := 128; 252: Win2Glyph := 129; 233: Win2Glyph := 130;
  226: Win2Glyph := 131; 228: Win2Glyph := 132; 224: Win2Glyph := 133;
  229: Win2Glyph := 134; 231: Win2Glyph := 135; 234: Win2Glyph := 136;
  235: Win2Glyph := 137; 232: Win2Glyph := 138; 239: Win2Glyph := 139;
  238: Win2Glyph := 140; 236: Win2Glyph := 141; 196: Win2Glyph := 142;
  197: Win2Glyph := 143; 201: Win2Glyph := 144; 230: Win2Glyph := 145;
  198: Win2Glyph := 146; 244: Win2Glyph := 147; 246: Win2Glyph := 148;
  242: Win2Glyph := 149; 251: Win2Glyph := 150; 249: Win2Glyph := 151;
  255: Win2Glyph := 152; 214: Win2Glyph := 153; 220: Win2Glyph := 154;
  162: Win2Glyph := 155; 163: Win2Glyph := 156; 165: Win2Glyph := 157;
  131: Win2Glyph := 159; 225: Win2Glyph := 160; 237: Win2Glyph := 161;
  243: Win2Glyph := 162; 250: Win2Glyph := 163; 241: Win2Glyph := 164;
  209: Win2Glyph := 165; 170: Win2Glyph := 166; 186: Win2Glyph := 167;
  191: Win2Glyph := 168; 172: Win2Glyph := 170; 189: Win2Glyph := 171;
  188: Win2Glyph := 172; 161: Win2Glyph := 173; 171: Win2Glyph := 174;
  187: Win2Glyph := 175; 223: Win2Glyph := 225; 181: Win2Glyph := 230;
  177: Win2Glyph := 241; 247: Win2Glyph := 246; 176: Win2Glyph := 248;
  183: Win2Glyph := 250; 178: Win2Glyph := 253;
  192,193,194,195: Win2Glyph := Ord('A');
  200,202,203: Win2Glyph := Ord('E');
  204,205,206,207: Win2Glyph := Ord('I');
  210,211,212,213: Win2Glyph := Ord('O');
  217,218,219: Win2Glyph := Ord('U');
  145,146,130: Win2Glyph := Ord('''');
  147,148,132: Win2Glyph := Ord('"');
  150,151: Win2Glyph := Ord('-');
  149: Win2Glyph := 7;
  133: Win2Glyph := Ord('.');
  128: Win2Glyph := Ord('E');
  160: Win2Glyph := 32;
 Else
  Win2Glyph := Ord('?');
 End;
End;

{ CP437 (clavier) -> WinAnsi (document) }
Function Dos2Win(C: Integer): Integer;
Var
 I: Integer;
Begin
 Dos2Win := C;
 If C < 128 Then Exit;
 For I := 160 To 255 Do
  If (Win2Glyph(I) = C) And (Not (I In [192..195, 200, 202..207, 210..213, 217..219, 160])) Then Begin
   Dos2Win := I;
   Exit;
  End;
 Dos2Win := Ord('?');
End;

{ UTF-8 (source) -> CP437 pour l'interface }
Function U2C(Const S: String): String;
Var
 I: Integer;
 R: String;
 C: Integer;
Begin
 R := '';
 I := 1;
 While I <= Length(S) Do Begin
  C := Ord(S[I]);
  If (C = $C3) And (I < Length(S)) Then Begin
   R := R + Chr(Win2Glyph(Ord(S[I + 1]) + 64));
   Inc(I, 2);
  End
  Else If (C = $C2) And (I < Length(S)) Then Begin
   R := R + Chr(Win2Glyph(Ord(S[I + 1])));
   Inc(I, 2);
  End
  Else If (C = $E2) And (I + 2 <= Length(S)) Then Begin
   R := R + '-';
   Inc(I, 3);
  End
  Else Begin
   R := R + S[I];
   Inc(I);
  End;
 End;
 U2C := R;
End;

{ UTF-8 (source) -> WinAnsi pour le document }
Function U2W(Const S: String): String;
Var
 I: Integer;
 R: String;
 C: Integer;
Begin
 R := '';
 I := 1;
 While I <= Length(S) Do Begin
  C := Ord(S[I]);
  If (C = $C3) And (I < Length(S)) Then Begin
   R := R + Chr(Ord(S[I + 1]) + 64);
   Inc(I, 2);
  End
  Else If (C = $C2) And (I < Length(S)) Then Begin
   R := R + S[I + 1];
   Inc(I, 2);
  End
  Else Begin
   R := R + S[I];
   Inc(I);
  End;
 End;
 U2W := R;
End;

Function TW(Const S: String): Integer;
Begin
 TW := Length(U2C(S)) * 8;
End;

Procedure DS(X, Y: Integer; Const S: String);
Begin
 OutTextXY(X, Y, U2C(S));
End;

Procedure DSC(X, Y, W: Integer; Const S: String);
Begin
 DS(X + (W - TW(S)) Div 2, Y, S);
End;

Procedure DSA(X, Y: Integer; Const S: String; ACol: Integer);
Begin
 SetColor(ACol);
 DS(X, Y, S);
End;

{ ---------------------------------------------------------------------- }
{ Listes chaînées de blocs (tas) : objets, pages, points de tracé, images  }
{ L'accès par indice parcourt la chaîne ; un curseur mémorise le dernier   }
{ bloc atteint, ce qui rend les boucles séquentielles très rapides.        }
{ ---------------------------------------------------------------------- }

Function NewObjBlock: PObjBlock;
Var
 B: PObjBlock;
Begin
 GetMem(B, SizeOf(TObjBlock));
 If B <> Nil Then Begin
  FillChar(B^, SizeOf(TObjBlock), 0);
  B^.Next := Nil;
 End;
 NewObjBlock := B;
End;

{ S'assure que l'indice I existe ; retourne False si le tas est épuisé }
Function ObjEnsure(I: LongInt): Boolean;
Var
 B, T: PObjBlock;
Begin
 ObjEnsure := True;
 While I >= ObjBlocks * OBLK Do Begin
  B := NewObjBlock;
  If B = Nil Then Begin ObjEnsure := False; Exit; End;
  If ObjHead = Nil Then ObjHead := B
  Else Begin
   T := ObjHead;
   If ObjCurBlk <> Nil Then If ObjCurNo = ObjBlocks - 1 Then T := ObjCurBlk Else T := ObjHead;
   While T^.Next <> Nil Do T := T^.Next;
   T^.Next := B;
  End;
  Inc(ObjBlocks);
 End;
End;

Function ObjP(I: LongInt): PObjRec;
Var
 BNo, K: LongInt;
 B: PObjBlock;
Begin
 BNo := I Div OBLK;
 If (ObjCurBlk <> Nil) And (BNo >= ObjCurNo) Then Begin B := ObjCurBlk; K := ObjCurNo; End
 Else Begin B := ObjHead; K := 0; End;
 While (K < BNo) And (B <> Nil) Do Begin B := B^.Next; Inc(K); End;
 If B = Nil Then B := ObjHead;
 ObjCurBlk := B; ObjCurNo := BNo;
 ObjP := @B^.Items[I Mod OBLK];
End;

Procedure ObjsFree;
Var
 B, N: PObjBlock;
Begin
 B := ObjHead;
 While B <> Nil Do Begin N := B^.Next; FreeMem(B, SizeOf(TObjBlock)); B := N; End;
 ObjHead := Nil; ObjCurBlk := Nil; ObjCurNo := 0; ObjBlocks := 0; ObjCount := 0;
End;

Function PgEnsure(I: LongInt): Boolean;
Var
 B, T: PPageBlock;
Begin
 PgEnsure := True;
 While I > PgBlocks * PGBLK Do Begin
  GetMem(B, SizeOf(TPageBlock));
  If B = Nil Then Begin PgEnsure := False; Exit; End;
  FillChar(B^, SizeOf(TPageBlock), 0);
  If PgHead = Nil Then PgHead := B
  Else Begin
   T := PgHead;
   While T^.Next <> Nil Do T := T^.Next;
   T^.Next := B;
  End;
  Inc(PgBlocks);
 End;
End;

{ Pages numérotées à partir de 1 }
Function PgP(I: LongInt): PPageRec;
Var
 BNo, K: LongInt;
 B: PPageBlock;
Begin
 BNo := (I - 1) Div PGBLK;
 If (PgCurBlk <> Nil) And (BNo >= PgCurNo) Then Begin B := PgCurBlk; K := PgCurNo; End
 Else Begin B := PgHead; K := 0; End;
 While (K < BNo) And (B <> Nil) Do Begin B := B^.Next; Inc(K); End;
 If B = Nil Then B := PgHead;
 PgCurBlk := B; PgCurNo := BNo;
 PgP := @B^.Items[(I - 1) Mod PGBLK];
End;

Procedure PgsFree;
Var
 B, N: PPageBlock;
Begin
 B := PgHead;
 While B <> Nil Do Begin N := B^.Next; FreeMem(B, SizeOf(TPageBlock)); B := N; End;
 PgHead := Nil; PgCurBlk := Nil; PgCurNo := 0; PgBlocks := 0; PageCount := 0;
End;

Function PoolEnsure(I: LongInt): Boolean;
Var
 B, T: PPoolBlock;
Begin
 PoolEnsure := True;
 While I > PoolBlocks * PLBLK Do Begin
  GetMem(B, SizeOf(TPoolBlock));
  If B = Nil Then Begin PoolEnsure := False; Exit; End;
  FillChar(B^, SizeOf(TPoolBlock), 0);
  If PoolHead = Nil Then PoolHead := B
  Else Begin
   T := PoolHead;
   While T^.Next <> Nil Do T := T^.Next;
   T^.Next := B;
  End;
  Inc(PoolBlocks);
 End;
End;

Function PoolBlk(I: LongInt): PPoolBlock;
Var
 BNo, K: LongInt;
 B: PPoolBlock;
Begin
 BNo := I Div PLBLK;
 If (PoolCurBlk <> Nil) And (BNo >= PoolCurNo) Then Begin B := PoolCurBlk; K := PoolCurNo; End
 Else Begin B := PoolHead; K := 0; End;
 While (K < BNo) And (B <> Nil) Do Begin B := B^.Next; Inc(K); End;
 If B = Nil Then B := PoolHead;
 PoolCurBlk := B; PoolCurNo := BNo;
 PoolBlk := B;
End;

Function PoolXP(I: LongInt): PSmallInt;
Begin
 PoolXP := @PoolBlk(I)^.X[I Mod PLBLK];
End;

Function PoolYP(I: LongInt): PSmallInt;
Begin
 PoolYP := @PoolBlk(I)^.Y[I Mod PLBLK];
End;

Procedure PoolFree;
Var
 B, N: PPoolBlock;
Begin
 B := PoolHead;
 While B <> Nil Do Begin N := B^.Next; FreeMem(B, SizeOf(TPoolBlock)); B := N; End;
 PoolHead := Nil; PoolCurBlk := Nil; PoolCurNo := 0; PoolBlocks := 0; PoolCount := 0;
End;

Function ImgEnsure(I: LongInt): Boolean;
Var
 B, T: PImgBlock;
Begin
 ImgEnsure := True;
 While I > ImgBlocks * IMBLK Do Begin
  GetMem(B, SizeOf(TImgBlock));
  If B = Nil Then Begin ImgEnsure := False; Exit; End;
  FillChar(B^, SizeOf(TImgBlock), 0);
  If ImgHead = Nil Then ImgHead := B
  Else Begin
   T := ImgHead;
   While T^.Next <> Nil Do T := T^.Next;
   T^.Next := B;
  End;
  Inc(ImgBlocks);
 End;
End;

{ Images numérotées à partir de 1 }
Function ImgP(I: LongInt): PImgRec;
Var
 BNo, K: LongInt;
 B: PImgBlock;
Begin
 BNo := (I - 1) Div IMBLK;
 If (ImgCurBlk <> Nil) And (BNo >= ImgCurNo) Then Begin B := ImgCurBlk; K := ImgCurNo; End
 Else Begin B := ImgHead; K := 0; End;
 While (K < BNo) And (B <> Nil) Do Begin B := B^.Next; Inc(K); End;
 If B = Nil Then B := ImgHead;
 ImgCurBlk := B; ImgCurNo := BNo;
 ImgP := @B^.Items[(I - 1) Mod IMBLK];
End;

Procedure ImgListFree;
Var
 B, N: PImgBlock;
Begin
 B := ImgHead;
 While B <> Nil Do Begin N := B^.Next; FreeMem(B, SizeOf(TImgBlock)); B := N; End;
 ImgHead := Nil; ImgCurBlk := Nil; ImgCurNo := 0; ImgBlocks := 0; ImgCount := 0;
End;

{ Tables de la compression deflate (RFC 1951) }
Const
 LBase: Array[0..28] Of Word = (3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258);
 LExtra: Array[0..28] Of Byte = (0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0);
 DBase: Array[0..29] Of Word = (1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577);
 DExtra: Array[0..29] Of Byte = (0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13);
 CLOrder: Array[0..18] Of Byte = (16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15);

{ ---------------------------------------------------------------------- }
{ Couleurs                                                                 }
{ ---------------------------------------------------------------------- }

Const
 PalRgb: Array[0..15] Of LongInt = (
  $000000,$0000C0,$00A000,$00A0A0,$C00000,$A000A0,$A05000,$B0B0B0,
  $606060,$4040FF,$40E040,$40E0E0,$FF4040,$FF40FF,$FFFF00,$FFFFFF);

Function RGBOf(R, G, B: LongInt): LongInt;
Begin
 If R < 0 Then R := 0; If R > 255 Then R := 255;
 If G < 0 Then G := 0; If G > 255 Then G := 255;
 If B < 0 Then B := 0; If B > 255 Then B := 255;
 RGBOf := (R Shl 16) Or (G Shl 8) Or B;
End;

Function Nearest16(Rgb: LongInt): Integer;
Var
 I, Best: Integer;
 D, BD, DR, DG, DB: LongInt;
Begin
 Best := 0;
 BD := MaxLongInt;
 For I := 0 To 15 Do Begin
  DR := ((Rgb Shr 16) And 255) - ((PalRgb[I] Shr 16) And 255);
  DG := ((Rgb Shr 8) And 255) - ((PalRgb[I] Shr 8) And 255);
  DB := (Rgb And 255) - (PalRgb[I] And 255);
  D := DR * DR * 3 + DG * DG * 4 + DB * DB * 2;
  If D < BD Then Begin BD := D; Best := I; End;
 End;
 Nearest16 := Best;
End;

{ RVB d'un indice de la palette écran }
Function IdxRgb(I: LongInt): LongInt;
Begin
 If TrueMode Then Begin IdxRgb := I And $FFFFFF; Exit; End;
 If I < 16 Then IdxRgb := (LongInt(ScrVga[I, 0]) Shl 16) Or (LongInt(ScrVga[I, 1]) Shl 8) Or ScrVga[I, 2]
 Else If I < 232 Then
  IdxRgb := (LongInt(((I - 16) Div 36) * 51) Shl 16) Or (LongInt((((I - 16) Div 6) Mod 6) * 51) Shl 8) Or (((I - 16) Mod 6) * 51)
 Else IdxRgb := (LongInt(8 + (I - 232) * 10) Shl 16) Or (LongInt(8 + (I - 232) * 10) Shl 8) Or (8 + (I - 232) * 10);
End;

{ Indice écran le plus proche d'une couleur RVB (palette 256 si disponible) }
Function ScrCol(Rgb: LongInt): LongInt;
Var
 R, G, B, K: Integer;
Begin
 If TrueMode Then Begin
  Rgb := Rgb And $FFFFFF;
  { les valeurs 1..15 désigneraient les couleurs de l'interface }
  If (Rgb > 0) And (Rgb < 16) Then Rgb := Rgb Or 16;
  ScrCol := Rgb;
  Exit;
 End;
 If Not Pal256 Then Begin ScrCol := Nearest16(Rgb); Exit; End;
 R := (Rgb Shr 16) And 255; G := (Rgb Shr 8) And 255; B := Rgb And 255;
 If (R = G) And (G = B) Then Begin
  If R = 0 Then ScrCol := 0
  Else If R = 255 Then ScrCol := 15
  Else Begin
   K := (R - 3) Div 10;
   If K < 0 Then K := 0;
   If K > 23 Then K := 23;
   ScrCol := 232 + K;
  End;
 End
 Else ScrCol := 16 + ((R + 25) Div 51) * 36 + ((G + 25) Div 51) * 6 + ((B + 25) Div 51);
End;

Function LerpRgb(A, B: LongInt; T: Real): LongInt;
Var
 R, G, Bl: Integer;
Begin
 R := Round(((A Shr 16) And 255) + (((B Shr 16) And 255) - ((A Shr 16) And 255)) * T);
 G := Round(((A Shr 8) And 255) + (((B Shr 8) And 255) - ((A Shr 8) And 255)) * T);
 Bl := Round((A And 255) + ((B And 255) - (A And 255)) * T);
 LerpRgb := RGBOf(R, G, Bl);
End;


{ ---------------------------------------------------------------------- }
{ Polices : glyphes 8x8 mis à l'échelle + largeurs Helvetica               }
{ ---------------------------------------------------------------------- }

Const
 HelvW: Array[32..126] Of Word = (
  278,278,355,556,556,889,667,191,333,333,389,584,278,333,278,278,
  556,556,556,556,556,556,556,556,556,556,278,278,584,584,584,556,
  1015,667,667,722,722,667,611,778,722,278,500,667,556,833,722,778,
  667,778,722,667,611,722,667,944,667,667,611,278,278,278,469,556,
  333,556,556,500,556,556,278,556,556,222,222,500,222,833,556,556,
  556,556,333,500,278,556,500,722,500,500,500,334,260,334,584);

Const
 VFirst = 32;
 VLast = 255;
 VFData: Array[32..255] Of String[60] = (
  '0',
  '2 ->l>J -><>>',
  '9 -@l@` -JlJ`',
  'B -F<Ll -R<Xl -@J^J ->\\\',
  '@ ~Z`RfJhBd>^BVLRVNZFV@L>B@<F -L8Ln',
  'D -@<^l ~BlHhBb<hBl ~\HbD\>VD\H',
  'A ~\<DVBbHhNhRbLV@J@BH<P>\L',
  '2 ->l>`',
  '6 ~Fp@d>T@BF6',
  '6 ~>pDdFTDB>6',
  ': -FlFX ->fN^ ->^Nf',
  '@ -@TXT -L`LH',
  '2 ->>>:<4',
  ': ->PNP',
  '2 -><>>',
  '9 -<8Nl',
  '@ ~LlXf\TXBL<@B<T@fLl',
  '9 ->dHlH<',
  '@ ~>bDjLlThX`TVHH>< -><Z<',
  '@ ~>fFlPlXfX^PVHTPRZJZBR<F<>B',
  '@ -T<Tl<J\J',
  '@ -XlBl@V ~@VFZPZXTZJV@N<D<>B',
  '@ ~VhNlFj@`<N@BJ<T@XJTTJXBV<N',
  '@ -<lZlH<',
  '@ ~LlThT`LXD`DhLl ~LXVTZJV@L<B@>JBTLX',
  '@ ~B@J<R>XH\ZXfNlDh@^DTNPVR\Z',
  '2 -><>> ->T>V',
  '2 ->T>V ->>>:<4',
  '= -T\>NT@',
  '> ->XVX ->JVJ',
  '= ->\TN>@',
  '> ~>dDjLlThV`RXJRJJ -J<J>',
  'F ~b@X8L6B>>NB`Nh\ff\fL`FZHZP ~ZVTZNVLNPHVHZV',
  'D -<<Pld< -DN\N',
  '@ -><>l ~>lPlXfX\PV>V ~>VRVZNZDR<><',
  'B ~^bVjNlDh>^>JD@N<V>^F',
  'A -><>l ~>lLlXd\TXDL<><',
  '> -Vl>l><V< ->TRT',
  '= -><>lVl ->TRT',
  'C ~^bVjNlDh>^>JD@N<Z@^J^P -PP^P',
  '@ -><>l -Z<Zl ->TZT',
  '2 -><>l',
  '< ~RlRHN>F<@@<H',
  'A -><>l -Zl>L -FR\<',
  '= ->l><T<',
  'D -><>lPBblb<',
  '@ -><>lZ<Zl',
  'D ~Pl^fbT^BP<BB>TBfPl',
  '? -><>l ~>lPlXfX\PT>T',
  'D ~Pl^fbT^BP<BB>TBfPl -TFb8',
  '@ -><>l ~>lRlZfZ\RT>T -NT\<',
  '@ ~ZdRjJlBh>bBZLTVPZHV@L<B><D',
  '@ -<l\l -LlL<',
  '@ ~>l>JB@L<V@ZJZl',
  'B -<lN<`l',
  'J -<lH<V`d<pl',
  'A -<l^< -<<^l',
  'B -<lNR`l -NRN<',
  '@ ->lZl><Z<',
  '6 -Fp>p>4F4',
  '9 -<lN8',
  '6 ->pFpF4>4',
  ': ->\FhN\',
  '> -<2X2',
  '5 ->lDd',
  '> ~VNRZJ^BZ>NBBJ<RBVN -V^V<',
  '> ->l>< ~>NBZJ^RZVNRBJ<BB>N',
  '= ~VXP^H^@X<N@BH<P<VB',
  '> -VlV< ~VNRZJ^BZ>NBBJ<RBVN',
  '> ~<NXNVXN^H^@Z<N@BH<P<VB',
  '< ~H<HdJjPlTj -@^P^',
  '> ~VNRZJ^BZ>NBBJ<RBVN ~V^V:R2H0@4',
  '= ->l>< ~>RD\L^RZTRT<',
  '2 ->^>< ->f>j',
  '6 ~F^F6D2>0 -FfFj',
  '= ->l>< -T^>H -FNV<',
  '2 ->l><',
  'F ->^>< ~>RB\J^PZRRR< ~RRV\^^dZfRf<',
  '= ->^>< ~>RD\L^RZTRT<',
  '> ~J^TXXNTBJ<@B<N@XJ^',
  '> ->^>0 ~>NBZJ^RZVNRBJ<BB>N',
  '> -V^V0 ~VNRZJ^BZ>NBBJ<RBVN',
  ': ->^>< ~>RB\J^P\',
  '< ~TXN^F^@Z@TFNNJTDR>J<B><D',
  '; -FhFD ~FDH>N<R> ->^P^',
  '= ->^>H ~>H@@H<P@TH -T^T<',
  '> -<^J<X^',
  'F -<^F<RX^<h^',
  '= -<^V< -<<V^',
  '> -<^J< -X^F0',
  '= ->^T^><T<',
  '8 ~JpDlD\>TDLD<J6',
  '2 ->p>4',
  '8 ~>pDlD\JTDLD<>6',
  '< ~<LBTHRNJTR',
  '2 ->^><',
  '@ ~^bVjNlDh>^>JD@N<V>^F -<XRX -<PRP',
  '',
  '2 ->>>:<4',
  '',
  '9 -@l@` -JlJ`',
  '> -><>> -H<H> -R<R>',
  '',
  '',
  '',
  '',
  '@ ~ZdRjJlBh>bBZLTVPZHV@L<B><D -FvLnRv',
  '',
  'P ~Pl^fbT^BP<BB>TBfPl -|ldld<|< -dTxT',
  '',
  '@ ->lZl><Z< -FvLnRv',
  '',
  '',
  '2 ->l>`',
  '2 ->l>`',
  '9 -@l@` -JlJ`',
  '9 -@l@` -JlJ`',
  '8 ~DVJRDN>RDV ~DTFRDPBRDT',
  '> -<PXP',
  'D -<PdP',
  '',
  'F -<pOp -FpFS -SRSj\UejeR',
  '< ~TXN^F^@Z@TFNNJTDR>J<B><D -BhH`Nh',
  '',
  'K ~J^TXXNTBJ<@B<N@XJ^ ~VNrNpXh^b^ZZVNZBb<j<pB',
  '',
  '= ->^T^><T< -ChI`Oh',
  '',
  '0',
  '2 -><>^ ->l>j',
  '= ~VXP^H^@X<N@BH<P<VB -JhJ6',
  '> ~VfPlHlBfBX@H<> -<<V< -<RLR',
  '',
  'B -<lNR`l -NRN< -BRZR -BHZH',
  '2 ->p>V ->N>4',
  '> ~RfLjDhB`JZRTRJJFBH ~JZBTBJJD',
  '8 ->l>j -JlJj',
  'F ~RlbdfRb@R<B@>RBdRl ~ZZT^NZLRNJTHZL',
  '9 ~LbIiDl@i=b@[DWI[Lb -LlLW',
  '@ -L\BPLD -X\NPXD',
  '> ->TVTVH',
  ': ->PNP',
  'F ~RlbdfRb@R<B@>RBdRl -LHL\ ~L\T\XXTRLR -RRXH',
  ': -<lPl',
  '6 ~BlHhBb<hBl',
  '> -@\T\ -JhJP -@DTD',
  '8 ~=n@rEsIqKlIgC_=Y -=YLY',
  '8 ~=pBsGsKpKkGgCfGeL`L\HYBY=\',
  '5 ->dDl',
  '= ->^>H ~>H@@H<P@TH -T^T< ->^>0',
  '',
  '2 ->P>R',
  '5 -@<@8<4',
  '5 -=oCsCY',
  '9 ~DlJhMbJ[DW>[<b>hDl',
  '@ -@\JP@D -L\VPLD',
  'J -=mCrCU -N<^d -j7jT\@o@',
  'J -=mCrCU -N<^d ~]NaSfTjRmMjGc>]7 -]7n7',
  'J ~=nBrHrMnMjHeCdHbN^NYIUBU=Y -N<^d -j7jT\@o@',
  '> ~>DD>L<T@VHRPJVJ^ -JlJj',
  'D -<<Pld< -DN\N -JvRn',
  'D -<<Pld< -DN\N -NnVv',
  'D -<<Pld< -DN\N -JnPvVn',
  'D -<<Pld< -DN\N ~HpLvRrXv',
  'D -<<Pld< -DN\N -JrJt -VrVt',
  'D -<<Pld< -DN\N ~PxTtPpLtPx',
  'P -<<Pld< -DN\N -xl`l`<x< -`TtT',
  'B ~^bVjNlDh>^>JD@N<V>^F -N<N8J4',
  '> -Vl>l><V< ->TRT -DvLn',
  '> -Vl>l><V< ->TRT -HnPv',
  '> -Vl>l><V< ->TRT -DnJvPn',
  '> -Vl>l><V< ->TRT -DrDt -PrPt',
  '2 -><>l -8v@n',
  '2 -><>l -<nDv',
  '2 -><>l -8n>vDn',
  '2 -><>l -8r8t -DrDt',
  '',
  '@ -><>lZ<Zl ~DpHvNrTv',
  'D ~Pl^fbT^BP<BB>TBfPl -JvRn',
  'D ~Pl^fbT^BP<BB>TBfPl -NnVv',
  'D ~Pl^fbT^BP<BB>TBfPl -JnPvVn',
  'D ~Pl^fbT^BP<BB>TBfPl ~HpLvRrXv',
  'D ~Pl^fbT^BP<BB>TBfPl -JrJt -VrVt',
  '> -@\TH -@HT\',
  'D ~Pl^fbT^BP<BB>TBfPl ->:bl',
  '@ ~>l>JB@L<V@ZJZl -FvNn',
  '@ ~>l>JB@L<V@ZJZl -JnRv',
  '@ ~>l>JB@L<V@ZJZl -FnLvRn',
  '@ ~>l>JB@L<V@ZJZl -FrFt -RrRt',
  'B -<lNR`l -NRN< -LnTv',
  '',
  '= -><>h ~>`BjJlRhR`JZRTTHN>D<',
  '> ~VNRZJ^BZ>NBBJ<RBVN -V^V< -DhL`',
  '> ~VNRZJ^BZ>NBBJ<RBVN -V^V< -H`Ph',
  '> ~VNRZJ^BZ>NBBJ<RBVN -V^V< -D`JhP`',
  '> ~VNRZJ^BZ>NBBJ<RBVN -V^V< ~BbFhLdRh',
  '> ~VNRZJ^BZ>NBBJ<RBVN -V^V< -DdDf -PdPf',
  '> ~VNRZJ^BZ>NBBJ<RBVN -V^V< ~JjNfJbFfJj',
  'K ~VNRZJ^BZ>NBBJ<RBVN -V^V< ~VNrNpXh^b^ZZVNZBb<j<pB',
  '= ~VXP^H^@X<N@BH<P<VB -I<I8E4',
  '> ~<NXNVXN^H^@Z<N@BH<P<VB -DhL`',
  '> ~<NXNVXN^H^@Z<N@BH<P<VB -H`Ph',
  '> ~<NXNVXN^H^@Z<N@BH<P<VB -D`JhP`',
  '> ~<NXNVXN^H^@Z<N@BH<P<VB -DdDf -PdPf',
  '2 ->^>< -8h@`',
  '2 ->^>< -<`Dh',
  '2 ->^>< -8`>hD`',
  '2 ->^>< -8d8f -DdDf',
  '',
  '= ->^>< ~>RD\L^RZTRT< ~AbEhKdQh',
  '> ~J^TXXNTBJ<@B<N@XJ^ -DhL`',
  '> ~J^TXXNTBJ<@B<N@XJ^ -H`Ph',
  '> ~J^TXXNTBJ<@B<N@XJ^ -D`JhP`',
  '> ~J^TXXNTBJ<@B<N@XJ^ ~BbFhLdRh',
  '> ~J^TXXNTBJ<@B<N@XJ^ -DdDf -PdPf',
  '> -@RTR -J^J` -JDJF',
  '> ~J^TXXNTBJ<@B<N@XJ^ ->:V`',
  '= ->^>H ~>H@@H<P@TH -T^T< -ChK`',
  '= ->^>H ~>H@@H<P@TH -T^T< -G`Oh',
  '= ->^>H ~>H@@H<P@TH -T^T< -C`IhO`',
  '= ->^>H ~>H@@H<P@TH -T^T< -CdCf -OdOf',
  '> -<^J< -X^F0 -H`Ph',
  '',
  '> -<^J< -X^F0 -DdDf -PdPf');

{ Largeur d'un caractère en 1/1000 d'em }
Function CharW(Fam, Style, C: Integer): Integer;
Var
 W: Integer;
Begin
 If Fam = 2 Then Begin CharW := 600; Exit; End;
 If (C >= 32) And (C <= 126) Then W := HelvW[C]
 Else If C >= 160 Then W := 556
 Else W := 500;
 If Fam = 1 Then W := W * 9 Div 10;
 If (Style And 1) <> 0 Then W := W * 106 Div 100;
 CharW := W;
End;

Function TextLenPts(Const S: String; Size, Fam, Style: Integer): LongInt;
Var
 I: Integer;
 T: LongInt;
Begin
 T := 0;
 For I := 1 To Length(S) Do T := T + CharW(Fam, Style, Ord(S[I]));
 TextLenPts := (T * Size + 999) Div 1000;
End;

{ ---------------------------------------------------------------------- }
{ Géométrie de page                                                         }
{ ---------------------------------------------------------------------- }

Procedure SetCtx(Pg: Integer; OX, OY, Sc: LongInt);
Begin
 GPg := Pg;
 GOX := OX;
 GOY := OY;
 GSc := Sc;
 GRot := PgP(Pg)^.Rot And 3;
 GPW := PgP(Pg)^.W;
 GPH := PgP(Pg)^.H;
End;

Function PU(U: LongInt): LongInt;
Begin
 PU := (U * GSc) Div 1024;
End;

Function MXp(X, Y: LongInt): LongInt;
Var
 U: LongInt;
Begin
 Case GRot Of
  0: U := X;
  1: U := GPH - Y;
  2: U := GPW - X;
 Else U := Y;
 End;
 MXp := GOX + PU(U);
End;

Function MYp(X, Y: LongInt): LongInt;
Var
 V: LongInt;
Begin
 Case GRot Of
  0: V := Y;
  1: V := X;
  2: V := GPH - Y;
 Else V := GPW - X;
 End;
 MYp := GOY + PU(V);
End;

{ Variantes en réels (positions fractionnaires en points) }
Function MXr(X, Y: Real): LongInt;
Var
 U: Real;
Begin
 Case GRot Of
  0: U := X;
  1: U := GPH - Y;
  2: U := GPW - X;
 Else U := Y;
 End;
 MXr := GOX + Round(U * GSc / 1024);
End;

Function MYr(X, Y: Real): LongInt;
Var
 V: Real;
Begin
 Case GRot Of
  0: V := Y;
  1: V := X;
  2: V := GPH - Y;
 Else V := GPW - X;
 End;
 MYr := GOY + Round(V * GSc / 1024);
End;

Procedure Unmap(SX, SY: LongInt; Var X, Y: LongInt);
Var
 U, V: LongInt;
Begin
 If GSc < 1 Then GSc := 1;
 U := ((SX - GOX) * 1024) Div GSc;
 V := ((SY - GOY) * 1024) Div GSc;
 Case GRot Of
  0: Begin X := U; Y := V; End;
  1: Begin Y := GPH - U; X := V; End;
  2: Begin X := GPW - U; Y := GPH - V; End;
 Else
  Begin Y := U; X := GPW - V; End;
 End;
End;

Function DispWOf(Pg: Integer; Sc: LongInt): LongInt;
Begin
 If (PgP(Pg)^.Rot And 1) <> 0 Then DispWOf := (LongInt(PgP(Pg)^.H) * Sc) Div 1024
 Else DispWOf := (LongInt(PgP(Pg)^.W) * Sc) Div 1024;
End;

Function DispHOf(Pg: Integer; Sc: LongInt): LongInt;
Begin
 If (PgP(Pg)^.Rot And 1) <> 0 Then DispHOf := (LongInt(PgP(Pg)^.W) * Sc) Div 1024
 Else DispHOf := (LongInt(PgP(Pg)^.H) * Sc) Div 1024;
End;

{ ---------------------------------------------------------------------- }
{ Primitives de dessin                                                      }
{ ---------------------------------------------------------------------- }

Var
 CullW, CullH: LongInt;

Procedure ThickLine(X1, Y1, X2, Y2, W, Col: LongInt);
Var
 I, O1, O2: LongInt;
Begin
 SetColor(Col);
 If W <= 1 Then Begin
  Line(C16(X1), C16(Y1), C16(X2), C16(Y2));
  Exit;
 End;
 O1 := -((W - 1) Div 2);
 O2 := W Div 2;
 If IAbs(X2 - X1) >= IAbs(Y2 - Y1) Then
  For I := O1 To O2 Do Line(C16(X1), C16(Y1 + I), C16(X2), C16(Y2 + I))
 Else
  For I := O1 To O2 Do Line(C16(X1 + I), C16(Y1), C16(X2 + I), C16(Y2));
End;

Procedure FillMultiply(X1, Y1, X2, Y2, Col, Rgb: LongInt);
Var
 X, Y: LongInt;
 Bg, LastBg, LastRes: Integer;
 C: LongInt;
Begin
 If X1 < 0 Then X1 := 0;
 If Y1 < 0 Then Y1 := 0;
 If X2 > CullW Then X2 := CullW;
 If Y2 > CullH Then Y2 := CullH;
 LastBg := -1; LastRes := 0;
 For Y := Y1 To Y2 Do Begin
  X := X1;
  While X <= X2 Do Begin
   Bg := GetPixel(X, Y);
   If Pal256 Then Begin
    { multiplication réelle des couleurs }
    If Bg <> LastBg Then Begin
     C := IdxRgb(Bg);
     LastRes := ScrCol(RGBOf((((C Shr 16) And 255) * ((Rgb Shr 16) And 255)) Div 255,
                             (((C Shr 8) And 255) * ((Rgb Shr 8) And 255)) Div 255,
                             ((C And 255) * (Rgb And 255)) Div 255));
     LastBg := Bg;
    End;
    PutPixel(X, Y, LastRes);
   End
   Else If Bg = White Then PutPixel(X, Y, Col);
   Inc(X);
  End;
 End;
End;

{ Police vectorielle : traits définis sur une grille de demi-unités
  (ligne de base 6, hauteur des minuscules 23, capitale 30). Les traits
  "lissés" sont arrondis par subdivision de Chaikin au démarrage. }
Const
 {$IFDEF FPC}
 VPOOLMAX = 24000;
 {$ELSE}
 VPOOLMAX = 9000;
 {$ENDIF}
 VSEP = -32768;

Type
 TVPt = Record
  X, Y: SmallInt;
 End;
 TVPool = Array[0..VPOOLMAX - 1] Of TVPt;
 PVPool = ^TVPool;
 TRPt = Record
  X, Y: Real;
 End;

Var
 VPool: PVPool;
 VCount: Integer;
 VStart: Array[0..255] Of Word;
 VLen: Array[0..255] Of Word;
 VW: Array[0..255] Of Byte;
 VCov: Array[0..159, 0..159] Of Byte;

Procedure VAddPoint(X, Y: Real);
Begin
 If VCount >= VPOOLMAX - 2 Then Exit;
 VPool^[VCount].X := Round(X * 16);
 VPool^[VCount].Y := Round(Y * 16);
 Inc(VCount);
End;

Procedure BuildVFont;
Var
 C, I, N, K, It, M: Integer;
 S: String;
 Smooth, Closed: Boolean;
 P, Q: Array[0..399] Of TRPt;
Begin
 GetMem(VPool, SizeOf(TVPool));
 VCount := 0;
 For C := 0 To 255 Do Begin VLen[C] := 0; VW[C] := 0; VStart[C] := 0; End;
 For C := VFirst To VLast Do Begin
  S := VFData[C];
  If S = '' Then Continue;
  VW[C] := Ord(S[1]) - 48;
  VStart[C] := VCount;
  I := 2;
  While I <= Length(S) Do Begin
   If S[I] = ' ' Then Begin
    Smooth := S[I + 1] = '~';
    Inc(I, 2);
    N := 0;
    While (I < Length(S)) And (S[I] <> ' ') And (N < 60) Do Begin
     P[N].X := (Ord(S[I]) - 48 - 12) / 2;
     P[N].Y := (Ord(S[I + 1]) - 48) / 2;
     Inc(N);
     Inc(I, 2);
    End;
    If Smooth And (N >= 3) Then Begin
     Closed := (P[0].X = P[N - 1].X) And (P[0].Y = P[N - 1].Y);
     For It := 1 To 2 Do Begin
      M := 0;
      If Not Closed Then Begin Q[M] := P[0]; Inc(M); End;
      For K := 0 To N - 2 Do Begin
       Q[M].X := 0.75 * P[K].X + 0.25 * P[K + 1].X; Q[M].Y := 0.75 * P[K].Y + 0.25 * P[K + 1].Y; Inc(M);
       Q[M].X := 0.25 * P[K].X + 0.75 * P[K + 1].X; Q[M].Y := 0.25 * P[K].Y + 0.75 * P[K + 1].Y; Inc(M);
      End;
      If Closed Then Begin Q[M] := Q[0]; Inc(M); End
      Else Begin Q[M] := P[N - 1]; Inc(M); End;
      For K := 0 To M - 1 Do P[K] := Q[K];
      N := M;
      If N > 90 Then Break;
     End;
    End;
    For K := 0 To N - 1 Do VAddPoint(P[K].X, P[K].Y);
    If VCount < VPOOLMAX Then Begin
     VPool^[VCount].X := VSEP;
     VPool^[VCount].Y := 0;
     Inc(VCount);
    End;
   End
   Else Inc(I);
  End;
  VLen[C] := VCount - VStart[C];
 End;
End;

{ Projection page -> écran en réels (sans arrondi) }
Procedure MapF(X, Y: Real; Var SX, SY: Real);
Var
 U, V: Real;
Begin
 Case GRot Of
  0: Begin U := X; V := Y; End;
  1: Begin U := GPH - Y; V := X; End;
  2: Begin U := GPW - X; V := GPH - Y; End;
 Else
  Begin U := Y; V := GPW - X; End;
 End;
 SX := GOX + U * GSc / 1024;
 SY := GOY + V * GSc / 1024;
End;

Function WinCode(C: Integer): Integer;
Begin
 WinCode := C;
 If (C < 32) Or (C > 255) Then WinCode := 63;
 If (C >= 127) And (C < 128) Then WinCode := 63;
End;

{ Trace un glyphe. Les points de dessin sont transformés par l'affine
  (écran = O + u*Ax + v*Ay), u et v en points. }
Procedure VGlyph(Code: Integer; CellU, Adv, Size: Real; OX, OY, AXx, AXy, AYx, AYy: Real;
                 Col: Integer; TextRgb: LongInt; Bold, Ital: Boolean);
Const
 MAXP = 220;
Var
 Pt: Array[0..MAXP - 1] Of TRPt;
 Brk: Array[0..MAXP - 1] Of Boolean;
 N, I, K, W: Integer;
 U, V, DX, DY, X, Y: Real;
 MnX, MnY, MxX, MxY: Real;
 HW, D, T, L2, CX, CY, Cv, Sh: Real;
 BX0, BY0, BX1, BY1, PX, PY, YY, XX: Integer;
 SX0, SX1, SY0, SY1: Integer;
 Bg, Lvl: Integer;
 Ci: Integer;
 A, B: TRPt;
 DesignW: Real;
Begin
 If (Code < 0) Or (Code > 255) Then Exit;
 If VLen[Code] = 0 Then Exit;
 DesignW := VW[Code];
 If DesignW < 1 Then DesignW := 1;
 N := 0;
 For I := VStart[Code] To VStart[Code] + VLen[Code] - 1 Do Begin
  If VPool^[I].X = VSEP Then Begin
   If N > 0 Then Brk[N - 1] := True;
  End
  Else If N < MAXP Then Begin
   X := VPool^[I].X / 16;
   Y := VPool^[I].Y / 16;
   U := CellU + Adv * (0.07 + 0.86 * X / DesignW);
   V := Size * (0.8 - (Y - 6) * 0.03);
   If Ital Then U := U + (Size * 0.8 - V) * 0.2;
   Pt[N].X := OX + U * AXx + V * AYx;
   Pt[N].Y := OY + U * AXy + V * AYy;
   Brk[N] := False;
   Inc(N);
  End;
 End;
 If N < 1 Then Exit;
 HW := Size * Sqrt(AXx * AXx + AXy * AXy) * 0.05;
 If Bold Then HW := HW * 1.45;
 If HW < 0.42 Then HW := 0.42;
 MnX := Pt[0].X; MxX := MnX; MnY := Pt[0].Y; MxY := MnY;
 For I := 1 To N - 1 Do Begin
  If Pt[I].X < MnX Then MnX := Pt[I].X;
  If Pt[I].X > MxX Then MxX := Pt[I].X;
  If Pt[I].Y < MnY Then MnY := Pt[I].Y;
  If Pt[I].Y > MxY Then MxY := Pt[I].Y;
 End;
 BX0 := Trunc(MnX - HW - 1); BY0 := Trunc(MnY - HW - 1);
 BX1 := Trunc(MxX + HW + 1); BY1 := Trunc(MxY + HW + 1);
 If (BX1 < 0) Or (BY1 < 0) Or (BX0 > CullW) Or (BY0 > CullH) Then Exit;
 If (BX1 - BX0 >= 160) Or (BY1 - BY0 >= 160) Then Begin
  { très grand glyphe : traits épais directs }
  For I := 0 To N - 2 Do
   If Not Brk[I] Then
    ThickLine(Round(Pt[I].X), Round(Pt[I].Y), Round(Pt[I + 1].X), Round(Pt[I + 1].Y), IMax(1, Round(HW * 2)), Col);
  Exit;
 End;
 For I := 0 To N - 1 Do Begin
  A := Pt[I];
  If (I < N - 1) And (Not Brk[I]) Then B := Pt[I + 1] Else B := A;
  If (I < N - 1) And Brk[I] Then Continue;
  SX0 := Trunc(IMin(Trunc(A.X), Trunc(B.X)) - HW - 1) - BX0;
  SX1 := Trunc(IMax(Trunc(A.X + 1), Trunc(B.X + 1)) + HW + 1) - BX0;
  SY0 := Trunc(IMin(Trunc(A.Y), Trunc(B.Y)) - HW - 1) - BY0;
  SY1 := Trunc(IMax(Trunc(A.Y + 1), Trunc(B.Y + 1)) + HW + 1) - BY0;
  If SX0 < 0 Then SX0 := 0;
  If SY0 < 0 Then SY0 := 0;
  If SX1 > BX1 - BX0 Then SX1 := BX1 - BX0;
  If SY1 > BY1 - BY0 Then SY1 := BY1 - BY0;
  DX := B.X - A.X; DY := B.Y - A.Y;
  L2 := DX * DX + DY * DY;
  For PY := SY0 To SY1 Do
   For PX := SX0 To SX1 Do Begin
    CX := BX0 + PX + 0.5; CY := BY0 + PY + 0.5;
    If L2 < 0.0001 Then T := 0
    Else Begin
     T := ((CX - A.X) * DX + (CY - A.Y) * DY) / L2;
     If T < 0 Then T := 0 Else If T > 1 Then T := 1;
    End;
    X := CX - (A.X + T * DX);
    Y := CY - (A.Y + T * DY);
    D := Sqrt(X * X + Y * Y);
    Cv := HW + 0.5 - D;
    If Cv > 0 Then Begin
     If Cv > 1 Then Cv := 1;
     Ci := Round(Cv * 255);
     If Ci > VCov[PY, PX] Then VCov[PY, PX] := Ci;
    End;
   End;
 End;
 For PY := 0 To BY1 - BY0 Do
  For PX := 0 To BX1 - BX0 Do Begin
   Ci := VCov[PY, PX];
   If Ci = 0 Then Continue;
   VCov[PY, PX] := 0;
   XX := BX0 + PX; YY := BY0 + PY;
   If (XX < 0) Or (YY < 0) Or (XX > CullW) Or (YY > CullH) Then Continue;
   If Pal256 Then Begin
    { anti-crénelage en vraies couleurs : mélange avec ce qui est déjà dessiné }
    Cv := Ci / 255 * 1.2;
    If Cv < 0.04 Then Continue;
    If Cv >= 0.96 Then PutPixel(XX, YY, Col)
    Else PutPixel(XX, YY, ScrCol(LerpRgb(IdxRgb(GetPixel(XX, YY)), TextRgb, Cv)));
    Continue;
   End;
   Cv := Ci / 255 * 1.25;
   If Cv >= 0.78 Then PutPixel(XX, YY, Col)
   Else If Cv >= 0.18 Then Begin
    Bg := GetPixel(XX, YY);
    If Bg = White Then Begin
     If Col = Black Then Begin
      If Cv >= 0.45 Then PutPixel(XX, YY, DarkGray) Else PutPixel(XX, YY, LightGray);
     End
     Else Begin
      If Cv >= 0.45 Then PutPixel(XX, YY, Col) Else PutPixel(XX, YY, LightGray);
     End;
    End
    Else If Cv >= 0.5 Then PutPixel(XX, YY, Col);
   End;
  End;
End;

{ ---- Texte à angle libre -------------------------------------------------
  Pour un K_TEXT : PN = angle en dixièmes de degré (sens anti-horaire),
  P0 = longueur de la ligne (points), Rgb2 = origine (coin supérieur gauche
  de la ligne dans son repère pivoté) emballée, utilisée si PN <> 0.
  X1..Y2 contiennent toujours la boîte englobante alignée sur les axes. }

Function TextLenOf(Const O: TObjRec): LongInt;
Begin
 If (O.Kind = K_TEXT) And (O.P0 > 0) Then TextLenOf := O.P0
 Else TextLenOf := IAbs(O.X2 - O.X1);
End;

Function TextLineH(Const O: TObjRec): LongInt;
Begin
 TextLineH := (LongInt(O.Size) * 6 + 4) Div 5;
End;

Function TextAng(Const O: TObjRec): Integer;
Begin
 If O.Kind = K_TEXT Then TextAng := O.PN Mod 3600 Else TextAng := 0;
End;

Procedure TextDirs(Tenths: Integer; Var Dx, Dy, Vx, Vy: Real);
Var
 A: Real;
Begin
 Tenths := ((Tenths Mod 3600) + 3600) Mod 3600;
 Case Tenths Of
  0: Begin Dx := 1; Dy := 0; End;
  900: Begin Dx := 0; Dy := -1; End;
  1800: Begin Dx := -1; Dy := 0; End;
  2700: Begin Dx := 0; Dy := 1; End;
 Else
  Begin
   A := Tenths * Pi / 1800;
   Dx := Cos(A); Dy := -Sin(A);
  End;
 End;
 { direction "vers le bas" du glyphe : perpendiculaire (rotation de 90° dans le repère page, y vers le bas) }
 Vx := -Dy; Vy := Dx;
End;

Procedure PackOrigin(Var O: TObjRec; Ox, Oy: LongInt);
Begin
 If Ox < -16384 Then Ox := -16384;
 If Ox > 16383 Then Ox := 16383;
 If Oy < -16384 Then Oy := -16384;
 If Oy > 16383 Then Oy := 16383;
 O.Rgb2 := (Ox + 16384) * 32768 + (Oy + 16384);
End;

Procedure TextOrigin(Const O: TObjRec; Var Ox, Oy: Real);
Begin
 If TextAng(O) = 0 Then Begin Ox := O.X1; Oy := O.Y1; End
 Else Begin
  Ox := (O.Rgb2 Div 32768) - 16384;
  Oy := (O.Rgb2 Mod 32768) - 16384;
 End;
End;

{ Coins de la ligne de texte (espace page) : 0 origine, 1 fin de ligne, 2 fin + bas, 3 bas }
Procedure TextCorners(Const O: TObjRec; Var CX, CY: Array Of Real);
Var
 Ox, Oy, Dx, Dy, Vx, Vy, L, H: Real;
Begin
 TextOrigin(O, Ox, Oy);
 TextDirs(TextAng(O), Dx, Dy, Vx, Vy);
 L := TextLenOf(O); H := TextLineH(O);
 CX[0] := Ox; CY[0] := Oy;
 CX[1] := Ox + L * Dx; CY[1] := Oy + L * Dy;
 CX[2] := CX[1] + H * Vx; CY[2] := CY[1] + H * Vy;
 CX[3] := Ox + H * Vx; CY[3] := Oy + H * Vy;
End;

{ Recalcule la boîte englobante d'un texte à partir de son origine }
Procedure SetTextBox(Var O: TObjRec; Ox, Oy: Real);
Var
 CX, CY: Array[0..3] Of Real;
 Dx, Dy, Vx, Vy, L, H: Real;
 I: Integer;
 MnX, MxX, MnY, MxY: Real;
Begin
 TextDirs(TextAng(O), Dx, Dy, Vx, Vy);
 L := TextLenOf(O); H := TextLineH(O);
 CX[0] := Ox; CY[0] := Oy;
 CX[1] := Ox + L * Dx; CY[1] := Oy + L * Dy;
 CX[2] := CX[1] + H * Vx; CY[2] := CY[1] + H * Vy;
 CX[3] := Ox + H * Vx; CY[3] := Oy + H * Vy;
 MnX := CX[0]; MxX := MnX; MnY := CY[0]; MxY := MnY;
 For I := 1 To 3 Do Begin
  If CX[I] < MnX Then MnX := CX[I];
  If CX[I] > MxX Then MxX := CX[I];
  If CY[I] < MnY Then MnY := CY[I];
  If CY[I] > MxY Then MxY := CY[I];
 End;
 O.X1 := C16(Round(MnX)); O.Y1 := C16(Round(MnY));
 O.X2 := C16(Round(MxX)); O.Y2 := C16(Round(MxY));
 If TextAng(O) = 0 Then Begin O.X1 := C16(Round(Ox)); O.Y1 := C16(Round(Oy)); O.X2 := C16(O.X1 + Round(L)); O.Y2 := C16(O.Y1 + Round(H)); End
 Else PackOrigin(O, Round(Ox), Round(Oy));
End;

{ Dessine une chaîne de document. (XPt, YPt) : coin supérieur gauche de la
  boîte du texte (en points), WPt : longueur imposée le long du texte,
  AngT : angle en dixièmes de degré (anti-horaire). }
Procedure DrawRun(Const S: String; XPt, YPt: Real; WPt: Real; Size, Fam, Style: Integer;
                  Rgb: LongInt; AngT: Integer);
Var
 I, N, C, Em, Col: Integer;
 Sum: LongInt;
 Ratio, Acc, Adv, H: Real;
 OX, OY, ODX, ODY, OAX, OAY, DxX, DxY, DyX, DyY: Real;
 PX0, PY0, PX1, PY1: Real;
 SX0, SY0, SX1, SY1: Real;
 Bold, Ital: Boolean;
Begin
 N := Length(S);
 If N = 0 Then Exit;
 Col := ScrCol(Rgb);
 Bold := (Style And 1) <> 0;
 Ital := (Style And 2) <> 0;
 Em := Round(Size * GSc / 1024.0);
 Sum := 0;
 For I := 1 To N Do Sum := Sum + CharW(Fam, Style, Ord(S[I]));
 If Sum = 0 Then Exit;
 If WPt < 1 Then WPt := Sum * Size / 1000.0;
 H := Size * 1.2;
 Ratio := WPt / (Sum * Size / 1000.0);
 TextDirs(AngT, DxX, DxY, DyX, DyY);
 PX0 := XPt; PY0 := YPt;
 MapF(PX0, PY0, OX, OY);
 MapF(PX0 + DxX, PY0 + DxY, SX0, SY0);
 MapF(PX0 + DyX, PY0 + DyY, SX1, SY1);
 OAX := SX0 - OX; OAY := SY0 - OY;
 ODX := SX1 - OX; ODY := SY1 - OY;
 If Em < 5 Then Begin
  { texte "grisé" : une barre le long de la ligne }
  MapF(PX0 + DyX * Size * 0.45, PY0 + DyY * Size * 0.45, SX0, SY0);
  MapF(PX0 + DyX * Size * 0.45 + DxX * WPt, PY0 + DyY * Size * 0.45 + DxY * WPt, SX1, SY1);
  If Col = 0 Then Col := DarkGray;
  If Em >= 2 Then ThickLine(Round(SX0), Round(SY0), Round(SX1), Round(SY1), 1, Col)
  Else If Col <> White Then Begin
   SetColor(Col);
   Line(C16(Round(SX0)), C16(Round(SY0)), C16(Round(SX1)), C16(Round(SY1)));
  End;
  Exit;
 End;
 Acc := 0;
 For I := 1 To N Do Begin
  C := WinCode(Ord(S[I]));
  If C = 160 Then C := 32;
  Adv := CharW(Fam, Style, Ord(S[I])) * Size / 1000.0 * Ratio;
  If C > 32 Then VGlyph(C, Acc, Adv, Size, OX, OY, OAX, OAY, ODX, ODY, Col, Rgb, Bold, Ital);
  Acc := Acc + Adv;
 End;
End;

Procedure NormBox(Const O: TObjRec; Var X1, Y1, X2, Y2: LongInt);
Begin
 X1 := IMin(O.X1, O.X2); X2 := IMax(O.X1, O.X2);
 Y1 := IMin(O.Y1, O.Y2); Y2 := IMax(O.Y1, O.Y2);
End;

{ Boîte écran normalisée d'un objet }
Procedure ScrBox(Const O: TObjRec; Var SX1, SY1, SX2, SY2: LongInt);
Var
 A, B, C, D: LongInt;
Begin
 NormBox(O, A, B, C, D);
 SX1 := IMin(MXp(A, B), MXp(C, D)); SX2 := IMax(MXp(A, B), MXp(C, D));
 SY1 := IMin(MYp(A, B), MYp(C, D)); SY2 := IMax(MYp(A, B), MYp(C, D));
End;

Procedure DrawArrowHead(X1, Y1, X2, Y2, W, Col: LongInt);
Var
 DX, DY, L: Real;
 HL: Real;
 PX, PY: Real;
Begin
 DX := X2 - X1; DY := Y2 - Y1;
 L := Sqrt(DX * DX + DY * DY);
 If L < 1 Then Exit;
 DX := DX / L; DY := DY / L;
 HL := 5 + W * 2;
 PX := X2 - DX * HL; PY := Y2 - DY * HL;
 ThickLine(X2, Y2, Round(PX - DY * HL * 0.45), Round(PY + DX * HL * 0.45), W, Col);
 ThickLine(X2, Y2, Round(PX + DY * HL * 0.45), Round(PY - DX * HL * 0.45), W, Col);
End;

Type
 TPolyPts = Array[0..255] Of PointType;

Procedure DrawPolyObj(Const O: TObjRec; FillIt, Outline, Closed: Boolean; Col, FCol, W: LongInt);
Var
 Pts: TPolyPts;
 N, I, Step: Integer;
 Base: Integer;
 PX, PY: LongInt;
 LX, LY: LongInt;
Begin
 If (O.PN < 2) Or (PoolHead = Nil) Then Exit;
 Step := 1;
 If O.PN > 250 Then Step := (O.PN + 249) Div 250;
 N := 0;
 I := 0;
 While I < O.PN Do Begin
  Base := O.P0 + I;
  PX := MXp(PoolXP(Base)^, PoolYP(Base)^);
  PY := MYp(PoolXP(Base)^, PoolYP(Base)^);
  If N < 255 Then Begin
   Pts[N].X := C16(PX); Pts[N].Y := C16(PY);
   Inc(N);
  End;
  Inc(I, Step);
 End;
 If N < 2 Then Exit;
 If FillIt And (N >= 3) Then Begin
  SetFillStyle(SolidFill, FCol);
  SetColor(FCol);
  FillPoly(N, Pts);
 End;
 If Outline Then Begin
  For I := 0 To N - 2 Do
   ThickLine(Pts[I].X, Pts[I].Y, Pts[I + 1].X, Pts[I + 1].Y, W, Col);
  If Closed Then ThickLine(Pts[N - 1].X, Pts[N - 1].Y, Pts[0].X, Pts[0].Y, W, Col);
 End;
End;


Type
 TWordPix = Array[0..67108863] Of Word;
 PWordPix = ^TWordPix;
 TBytePix = Array[0..134217727] Of Byte;
 PBytePix = ^TBytePix;

Const
 Bayer4: Array[0..3, 0..3] Of Byte = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5));

Var
 DLut: Array[0..4095] Of Byte;
 DLutReady: Boolean;

Procedure InitDLut;
Var
 R, G, B: Integer;
Begin
 For R := 0 To 15 Do
  For G := 0 To 15 Do
   For B := 0 To 15 Do
    DLut[(R Shl 8) Or (G Shl 4) Or B] := Nearest16(RGBOf(R * 17, G * 17, B * 17));
 DLutReady := True;
End;

Function ImageDrawable(I: Integer): Boolean;
Begin
 ImageDrawable := (I > 0) And (I <= ImgCount) And ((ImgP(I)^.Pix <> Nil) Or (ImgP(I)^.Mask And (ImgP(I)^.Alpha <> Nil)));
End;


{ Trace un pixel RVB avec tramage vers la palette courante }
Procedure PlotRgb(X, Y, R, G, B: LongInt);
Var
 Off: LongInt;
Begin
 If TrueMode Then Begin PutPixel(X, Y, ScrCol(RGBOf(R, G, B))); Exit; End;
 If Not DLutReady Then InitDLut;
 If Pal256 Then Begin
  If (Abs(R - G) < 8) And (Abs(G - B) < 8) Then Begin
   Off := Bayer4[Y And 3, X And 3] - 8;
   R := (R + G + B) Div 3 + Off;
   If R < 0 Then R := 0; If R > 255 Then R := 255;
   PutPixel(X, Y, ScrCol(RGBOf(R, R, R)));
  End
  Else Begin
   Off := Bayer4[Y And 3, X And 3] * 3 - 22;
   R := R + Off; G := G + Off; B := B + Off;
   If R < 0 Then R := 0; If R > 255 Then R := 255;
   If G < 0 Then G := 0; If G > 255 Then G := 255;
   If B < 0 Then B := 0; If B > 255 Then B := 255;
   PutPixel(X, Y, 16 + ((R + 25) Div 51) * 36 + ((G + 25) Div 51) * 6 + ((B + 25) Div 51));
  End;
 End
 Else Begin
  Off := Bayer4[Y And 3, X And 3] * 5 - 38;
  R := R + Off; G := G + Off; B := B + Off;
  If R < 0 Then R := 0; If R > 255 Then R := 255;
  If G < 0 Then G := 0; If G > 255 Then G := 255;
  If B < 0 Then B := 0; If B > 255 Then B := 255;
  PutPixel(X, Y, DLut[((R Shr 4) Shl 8) Or ((G Shr 4) Shl 4) Or (B Shr 4)]);
 End;
End;

{ Idem avec transparence A (0..255) : mélange réel en 256 couleurs, tramage en 16 couleurs }
Procedure PlotRgbA(X, Y, R, G, B, A: LongInt);
Var
 C: LongInt;
Begin
 If A >= 255 Then Begin PlotRgb(X, Y, R, G, B); Exit; End;
 If A <= 0 Then Exit;
 If Pal256 Then Begin
  C := IdxRgb(GetPixel(X, Y));
  R := (((C Shr 16) And 255) * (255 - A) + R * A) Div 255;
  G := (((C Shr 8) And 255) * (255 - A) + G * A) Div 255;
  B := ((C And 255) * (255 - A) + B * A) Div 255;
  PlotRgb(X, Y, R, G, B);
 End
 Else If Bayer4[Y And 3, X And 3] * 16 + 8 < A Then PlotRgb(X, Y, R, G, B);
End;

{ ---- Dégradés (K_GRAD) : paramètres rangés dans Txt, relatifs à la boîte ---- }
Const
 GMAXST = 9;

Var
 GdType, GdNSt: Integer;
 GdX0, GdY0, GdX1, GdY1, GdR0, GdR1: Real;
 GdPos: Array[0..GMAXST - 1] Of Integer;
 GdR, GdG, GdB: Array[0..GMAXST - 1] Of Integer;
 GdPW, GdPH: Real;
 GdSX1, GdSY1, GdDW, GdDH: LongInt;
 GdDenom: Real;
 PtMode, PtA: Integer;
 PtR, PtG, PtB: LongInt;

Function GdInt16(Const S: String; P: Integer): Integer;
Var
 V: LongInt;
Begin
 V := Ord(S[P]) + Ord(S[P + 1]) * 256;
 If V >= 32768 Then V := V - 65536;
 GdInt16 := V;
End;

Function GdPutInt16(V: LongInt): String;
Begin
 If V > 32767 Then V := 32767;
 If V < -32768 Then V := -32768;
 If V < 0 Then V := V + 65536;
 GdPutInt16 := Chr(V And 255) + Chr(V Shr 8);
End;

{ Lit les paramètres du dégradé de l'objet O (dimensions de la boîte en unités page) }
Procedure GradParse(Const O: TObjRec);
Var
 I, M: Integer;
 BW, BH, Mx: Real;
 S: String;
Begin
 S := O.Txt;
 GdNSt := 0;
 If Length(S) < 18 Then Exit;
 BW := IAbs(O.X2 - O.X1); If BW < 1 Then BW := 1;
 BH := IAbs(O.Y2 - O.Y1); If BH < 1 Then BH := 1;
 GdPW := BW; GdPH := BH;
 If BW > BH Then Mx := BW Else Mx := BH;
 GdType := Ord(S[1]);
 GdX0 := GdInt16(S, 2) * BW / 1024; GdY0 := GdInt16(S, 4) * BH / 1024;
 GdX1 := GdInt16(S, 6) * BW / 1024; GdY1 := GdInt16(S, 8) * BH / 1024;
 GdR0 := GdInt16(S, 10) * Mx / 1024; GdR1 := GdInt16(S, 12) * Mx / 1024;
 M := Ord(S[14]);
 If M > GMAXST Then M := GMAXST;
 For I := 0 To M - 1 Do
  If 14 + I * 4 + 4 <= Length(S) Then Begin
   GdPos[I] := Ord(S[15 + I * 4]);
   GdR[I] := Ord(S[16 + I * 4]); GdG[I] := Ord(S[17 + I * 4]); GdB[I] := Ord(S[18 + I * 4]);
   GdNSt := I + 1;
  End;
 GdDenom := (GdX1 - GdX0) * (GdX1 - GdX0) + (GdY1 - GdY0) * (GdY1 - GdY0);
End;

{ Couleur du dégradé au paramètre T (0..1) }
Procedure GradColor(T: Real; Var R, G, B: LongInt);
Var
 I: Integer;
 P, F: Real;
Begin
 If T < 0 Then T := 0;
 If T > 1 Then T := 1;
 P := T * 255;
 If GdNSt < 1 Then Begin R := 128; G := 128; B := 128; Exit; End;
 If P <= GdPos[0] Then Begin R := GdR[0]; G := GdG[0]; B := GdB[0]; Exit; End;
 For I := 1 To GdNSt - 1 Do
  If P <= GdPos[I] Then Begin
   If GdPos[I] = GdPos[I - 1] Then F := 1 Else F := (P - GdPos[I - 1]) / (GdPos[I] - GdPos[I - 1]);
   R := Round(GdR[I - 1] + (GdR[I] - GdR[I - 1]) * F);
   G := Round(GdG[I - 1] + (GdG[I] - GdG[I - 1]) * F);
   B := Round(GdB[I - 1] + (GdB[I] - GdB[I - 1]) * F);
   Exit;
  End;
 R := GdR[GdNSt - 1]; G := GdG[GdNSt - 1]; B := GdB[GdNSt - 1];
End;

{ Paramètre T du dégradé au point (X, Y) de la boîte (unités page) ; faux si hors dégradé }
Function GradParam(X, Y: Real; Var T: Real): Boolean;
Var
 PdX, PdY, CdX, CdY, Dr, A, B, C, Disc, S1, S2, S: Real;
Begin
 GradParam := True;
 If GdType = 0 Then Begin
  If GdDenom < 0.000001 Then T := 0
  Else T := ((X - GdX0) * (GdX1 - GdX0) + (Y - GdY0) * (GdY1 - GdY0)) / GdDenom;
  Exit;
 End;
 PdX := X - GdX0; PdY := Y - GdY0;
 CdX := GdX1 - GdX0; CdY := GdY1 - GdY0; Dr := GdR1 - GdR0;
 A := CdX * CdX + CdY * CdY - Dr * Dr;
 B := PdX * CdX + PdY * CdY + GdR0 * Dr;
 C := PdX * PdX + PdY * PdY - GdR0 * GdR0;
 If Abs(A) < 0.000001 Then Begin
  If Abs(B) < 0.000001 Then Begin GradParam := False; Exit; End;
  S := C / (2 * B);
 End
 Else Begin
  Disc := B * B - A * C;
  If Disc < 0 Then Begin GradParam := False; Exit; End;
  Disc := Sqrt(Disc);
  S1 := (B + Disc) / A; S2 := (B - Disc) / A;
  If S1 < S2 Then Begin S := S1; S1 := S2; S2 := S; End;
  If GdR0 + S1 * Dr >= 0 Then S := S1
  Else If GdR0 + S2 * Dr >= 0 Then S := S2
  Else Begin GradParam := False; Exit; End;
 End;
 T := S;
End;

Procedure PaintSpan(Y, XA, XB: LongInt);
Var
 X, U, V, PU_, PV_, BW, BH: LongInt;
 T: Real;
 R, G, B: LongInt;
Begin
 If XA < 0 Then XA := 0;
 If XB > CullW Then XB := CullW;
 For X := XA To XB Do Begin
  If PtMode = 0 Then PlotRgbA(X, Y, PtR, PtG, PtB, PtA)
  Else Begin
   U := X - GdSX1; V := Y - GdSY1;
   Case GRot Of
    0: Begin PU_ := U; PV_ := V; BW := GdDW; BH := GdDH; End;
    1: Begin PU_ := V; PV_ := GdDW - 1 - U; BW := GdDH; BH := GdDW; End;
    2: Begin PU_ := GdDW - 1 - U; PV_ := GdDH - 1 - V; BW := GdDW; BH := GdDH; End;
   Else
    Begin PU_ := GdDH - 1 - V; PV_ := U; BW := GdDH; BH := GdDW; End;
   End;
   If BW < 1 Then BW := 1;
   If BH < 1 Then BH := 1;
   If GradParam((PU_ + 0.5) * GdPW / BW, (PV_ + 0.5) * GdPH / BH, T) Then Begin
    GradColor(T, R, G, B);
    PlotRgb(X, Y, R, G, B);
   End;
  End;
 End;
End;

Type
 TScrPts = Array[0..255] Of LongInt;

{ Remplissage par balayage (parité) d'un polygone en coordonnées écran }
Procedure ScanPoly(Const Px, Py: TScrPts; N: Integer);
Var
 Y, YMin, YMax, NC, K, J, I: LongInt;
 Xs: Array[0..127] Of LongInt;
 Tmp: LongInt;
 Xf: Real;
Begin
 If N < 3 Then Exit;
 YMin := Py[0]; YMax := Py[0];
 For I := 1 To N - 1 Do Begin
  If Py[I] < YMin Then YMin := Py[I];
  If Py[I] > YMax Then YMax := Py[I];
 End;
 If YMin < 0 Then YMin := 0;
 If YMax > CullH Then YMax := CullH;
 For Y := YMin To YMax Do Begin
  NC := 0;
  For I := 0 To N - 1 Do Begin
   J := I + 1; If J >= N Then J := 0;
   If (Py[I] <= Y) <> (Py[J] <= Y) Then Begin
    Xf := Px[I] + (Y - Py[I]) * (Px[J] - Px[I]) / (Py[J] - Py[I]);
    If NC < 128 Then Begin Xs[NC] := Round(Xf); Inc(NC); End;
   End;
  End;
  For I := 1 To NC - 1 Do Begin
   Tmp := Xs[I]; K := I - 1;
   While (K >= 0) And (Xs[K] > Tmp) Do Begin Xs[K + 1] := Xs[K]; Dec(K); End;
   Xs[K + 1] := Tmp;
  End;
  K := 0;
  While K + 1 < NC Do Begin
   PaintSpan(Y, Xs[K], Xs[K + 1]);
   Inc(K, 2);
  End;
 End;
End;

{ Polygone ou ellipse ou rectangle rempli avec transparence A }
Procedure FillAlphaPts(Const Px, Py: TScrPts; N: Integer; Rgb: LongInt; A: Integer);
Begin
 PtMode := 0; PtA := A;
 PtR := (Rgb Shr 16) And 255; PtG := (Rgb Shr 8) And 255; PtB := Rgb And 255;
 ScanPoly(Px, Py, N);
End;

Procedure DrawGradObj(Const O: TObjRec; SX1, SY1, SX2, SY2: LongInt);
Var
 Px, Py: TScrPts;
 N, I, Step: Integer;
 Base: LongInt;
Begin
 GradParse(O);
 If GdNSt < 2 Then Exit;
 PtMode := 1;
 GdSX1 := SX1; GdSY1 := SY1; GdDW := SX2 - SX1 + 1; GdDH := SY2 - SY1 + 1;
 N := 0;
 If (O.PN >= 3) And (PoolHead <> Nil) Then Begin
  Step := 1;
  If O.PN > 250 Then Step := (O.PN + 249) Div 250;
  I := 0;
  While (I < O.PN) And (N < 255) Do Begin
   Base := O.P0 + I;
   Px[N] := MXp(PoolXP(Base)^, PoolYP(Base)^);
   Py[N] := MYp(PoolXP(Base)^, PoolYP(Base)^);
   Inc(N);
   Inc(I, Step);
  End;
 End
 Else Begin
  Px[0] := SX1; Py[0] := SY1; Px[1] := SX2; Py[1] := SY1;
  Px[2] := SX2; Py[2] := SY2; Px[3] := SX1; Py[3] := SY2;
  N := 4;
 End;
 ScanPoly(Px, Py, N);
End;

{ Dessine l'image réduite dans le rectangle écran (X1,Y1)-(X2,Y2) avec
  tramage ordonné vers les 16 couleurs. }
Procedure DrawImageData(Const O: TObjRec; X1, Y1, X2, Y2: LongInt);
Var
 I, DW, DH, X, Y, XA, XB, YA, YB, SX, SY, U, V, IW_, IH_, R, G, B, Off: LongInt;
 PU_, PV_, BW, BH: LongInt;
 Pw: PWordPix;
 Al: PBytePix;
 HF, VF: Boolean;
 MaskCol: Integer;
 Vv: Word;
Begin
 If Not DLutReady Then InitDLut;
 I := O.P0;
 DW := X2 - X1 + 1;
 DH := Y2 - Y1 + 1;
 If (DW < 1) Or (DH < 1) Then Exit;
 IW_ := ImgP(I)^.W; IH_ := ImgP(I)^.H;
 Pw := PWordPix(ImgP(I)^.Pix);
 Al := PBytePix(ImgP(I)^.Alpha);
 HF := (O.Style And 1) <> 0;
 VF := (O.Style And 2) <> 0;
 MaskCol := ScrCol(O.Rgb);
 XA := IMax(X1, 0); XB := IMin(X2, CullW);
 YA := IMax(Y1, 0); YB := IMin(Y2, CullH);
 For Y := YA To YB Do
  For X := XA To XB Do Begin
   U := X - X1; V := Y - Y1;
   { coordonnées dans l'espace page (compensation de la rotation de la page) }
   Case GRot Of
    0: Begin PU_ := U; PV_ := V; BW := DW; BH := DH; End;
    1: Begin PU_ := V; PV_ := DW - 1 - U; BW := DH; BH := DW; End;
    2: Begin PU_ := DW - 1 - U; PV_ := DH - 1 - V; BW := DW; BH := DH; End;
   Else
    Begin PU_ := DH - 1 - V; PV_ := U; BW := DH; BH := DW; End;
   End;
   If (O.Style And 4) = 0 Then Begin
    SX := (PU_ * IW_) Div BW; SY := (PV_ * IH_) Div BH;
   End
   Else Begin
    SX := (PV_ * IW_) Div BH; SY := (PU_ * IH_) Div BW;
   End;
   If HF Then SX := IW_ - 1 - SX;
   If VF Then SY := IH_ - 1 - SY;
   If SX < 0 Then SX := 0;
   If SX >= IW_ Then SX := IW_ - 1;
   If SY < 0 Then SY := 0;
   If SY >= IH_ Then SY := IH_ - 1;
   If Al <> Nil Then If Al^[SY * IW_ + SX] < 128 Then Continue;
   If Pw = Nil Then PutPixel(X, Y, MaskCol)
   Else Begin
    Vv := Pw^[SY * IW_ + SX];
    R := ((Vv Shr 11) And 31) * 255 Div 31;
    G := ((Vv Shr 5) And 63) * 255 Div 63;
    B := (Vv And 31) * 255 Div 31;
    If (O.Alpha > 0) And (O.Alpha < 255) Then PlotRgbA(X, Y, R, G, B, O.Alpha) Else PlotRgb(X, Y, R, G, B);
   End;
  End;
End;

Procedure DrawObj(Const O: TObjRec; Pass: Integer);
Var
 SX1, SY1, SX2, SY2: LongInt;
 Col, FCol: Integer;
 W: LongInt;
 CX, CY, RX, RY, I: LongInt;
 NX1, NY1, NX2, NY2: LongInt;
 Sz: Integer;
 TW_: Real;
 TOx, TOy: Real;
 PxA, PyA: TScrPts;
 NA: Integer;
Begin
 ScrBox(O, SX1, SY1, SX2, SY2);
 If (SX2 < -4) Or (SY2 < -4) Or (SX1 > CullW + 4) Or (SY1 > CullH + 4) Then Exit;
 Col := ScrCol(O.Rgb);
 FCol := ScrCol(O.Rgb2);
 W := (LongInt(O.Wd) * GSc) Div 1024;
 If W < 1 Then W := 1;
 If Pass = 1 Then Begin
  Case O.Kind Of
   K_TEXT:
    begin
     TextOrigin(O, TOx, TOy);
     DrawRun(O.Txt, TOx, TOy, TextLenOf(O), O.Size, O.Style Shr 2, O.Style And 3, O.Rgb, TextAng(O));
    end;
   K_LINE, K_ARROW: Begin
    ThickLine(MXp(O.X1, O.Y1), MYp(O.X1, O.Y1), MXp(O.X2, O.Y2), MYp(O.X2, O.Y2), W, Col);
    If O.Kind = K_ARROW Then
     DrawArrowHead(MXp(O.X1, O.Y1), MYp(O.X1, O.Y1), MXp(O.X2, O.Y2), MYp(O.X2, O.Y2), W, Col);
   End;
   K_RECT: Begin
    If O.Fill <> 0 Then Begin
     SetFillStyle(SolidFill, FCol);
     If (SX2 - SX1 < 1) Then SX2 := SX1;
     If (SY2 - SY1 < 1) Then SY2 := SY1;
     If (O.Alpha > 0) And (O.Alpha < 255) Then Begin
      PxA[0] := SX1; PyA[0] := SY1; PxA[1] := SX2 + 1; PyA[1] := SY1;
      PxA[2] := SX2 + 1; PyA[2] := SY2 + 1; PxA[3] := SX1; PyA[3] := SY2 + 1;
      FillAlphaPts(PxA, PyA, 4, O.Rgb2, O.Alpha);
     End
     Else Bar(C16(SX1), C16(SY1), C16(SX2), C16(SY2));
    End;
    If O.Fill <> 1 Then Begin
     ThickLine(SX1, SY1, SX2, SY1, W, Col);
     ThickLine(SX2, SY1, SX2, SY2, W, Col);
     ThickLine(SX2, SY2, SX1, SY2, W, Col);
     ThickLine(SX1, SY2, SX1, SY1, W, Col);
    End;
   End;
   K_OVAL: Begin
    CX := (SX1 + SX2) Div 2; CY := (SY1 + SY2) Div 2;
    RX := (SX2 - SX1) Div 2; RY := (SY2 - SY1) Div 2;
    If (RX > 0) And (RY > 0) And (RX < 2000) And (RY < 2000) Then Begin
     If O.Fill <> 0 Then Begin
      SetFillStyle(SolidFill, FCol);
      SetColor(FCol);
      If (O.Alpha > 0) And (O.Alpha < 255) Then Begin
       For I := 0 To 47 Do Begin
        PxA[I] := CX + Round(RX * Cos(I * Pi / 24));
        PyA[I] := CY + Round(RY * Sin(I * Pi / 24));
       End;
       FillAlphaPts(PxA, PyA, 48, O.Rgb2, O.Alpha);
      End
      Else FillEllipse(C16(CX), C16(CY), C16(RX), C16(RY));
     End;
     If O.Fill <> 1 Then Begin
      SetColor(Col);
      For I := 0 To W - 1 Do
       If (RX - I > 0) And (RY - I > 0) Then
        Ellipse(C16(CX), C16(CY), 0, 360, C16(RX - I), C16(RY - I));
     End;
    End;
   End;
   K_POLY:
    If (O.Fill <> 0) And (O.Alpha > 0) And (O.Alpha < 255) And (O.PN >= 3) And (PoolHead <> Nil) Then Begin
     NA := 0;
     I := 0;
     Sz := 1;
     If O.PN > 250 Then Sz := (O.PN + 249) Div 250;
     While (I < O.PN) And (NA < 255) Do Begin
      PxA[NA] := MXp(PoolXP(O.P0 + I)^, PoolYP(O.P0 + I)^);
      PyA[NA] := MYp(PoolXP(O.P0 + I)^, PoolYP(O.P0 + I)^);
      Inc(NA); Inc(I, Sz);
     End;
     FillAlphaPts(PxA, PyA, NA, O.Rgb2, O.Alpha);
     If O.Fill <> 1 Then DrawPolyObj(O, False, True, (O.Style And 1) <> 0, Col, FCol, W);
    End
    Else DrawPolyObj(O, O.Fill <> 0, O.Fill <> 1, (O.Style And 1) <> 0, Col, FCol, W);
   K_GRAD: DrawGradObj(O, SX1, SY1, SX2, SY2);
   K_INK:
    DrawPolyObj(O, False, True, False, Col, FCol, W);
   K_IMAGE: If ImageDrawable(O.P0) Then DrawImageData(O, SX1, SY1, SX2, SY2)
   Else Begin
    SetFillStyle(SolidFill, LightGray);
    Bar(C16(SX1), C16(SY1), C16(SX2), C16(SY2));
    SetColor(DarkGray);
    Rectangle(C16(SX1), C16(SY1), C16(SX2), C16(SY2));
    If SX2 - SX1 > 12 Then Begin
     Line(C16(SX1), C16(SY1), C16(SX2), C16(SY2));
     Line(C16(SX1), C16(SY2), C16(SX2), C16(SY1));
    End;
   End;
   K_STAMP: Begin
    ThickLine(SX1, SY1, SX2, SY1, W + 1, Col);
    ThickLine(SX2, SY1, SX2, SY2, W + 1, Col);
    ThickLine(SX2, SY2, SX1, SY2, W + 1, Col);
    ThickLine(SX1, SY2, SX1, SY1, W + 1, Col);
    DrawRun(O.Txt, IMin(O.X1, O.X2) + 6, IMin(O.Y1, O.Y2) + 4, IAbs(O.X2 - O.X1) - 12, O.Size, 0, 1, O.Rgb, 0);
   End;
  End;
 End
 Else If Pass = 2 Then Begin
  If O.Kind = K_HILITE Then FillMultiply(SX1, SY1, SX2, SY2, Col, O.Rgb);
 End
 Else If Pass = 3 Then Begin
  Case O.Kind Of
   K_UNDER: ThickLine(SX1, SY2, SX2, SY2, IMax(1, W Div 2), Col);
   K_STRIKE: ThickLine(SX1, (SY1 + SY2) Div 2, SX2, (SY1 + SY2) Div 2, IMax(1, W Div 2), Col);
   K_NOTE: Begin
    SetFillStyle(SolidFill, Yellow);
    Bar(C16(SX1), C16(SY1), C16(SX2), C16(SY2));
    SetColor(Black);
    Rectangle(C16(SX1), C16(SY1), C16(SX2), C16(SY2));
    If SX2 - SX1 > 8 Then Begin
     Line(C16(SX1 + 3), C16(SY1 + 4), C16(SX2 - 3), C16(SY1 + 4));
     Line(C16(SX1 + 3), C16(SY1 + 7), C16(SX2 - 3), C16(SY1 + 7));
     Line(C16(SX1 + 3), C16(SY1 + 10), C16(SX2 - 6), C16(SY1 + 10));
    End;
   End;
   K_REDACT: Begin
    SetColor(LightRed);
    Rectangle(C16(SX1), C16(SY1), C16(SX2), C16(SY2));
    Rectangle(C16(SX1 + 1), C16(SY1 + 1), C16(SX2 - 1), C16(SY2 - 1));
    If SX2 - SX1 > 20 Then DS(C16(SX1 + 3), C16(SY1 + 3), 'REDACT');
   End;
  End;
 End;
End;

{ Coins d'un objet dans l'espace page : 1=(X1,Y1) 2=(X2,Y1) 3=(X1,Y2) 4=(X2,Y2) }
Procedure CornerOf(Const O: TObjRec; K: Integer; Var X, Y: LongInt);
Var
 A, B, C, D: LongInt;
Begin
 NormBox(O, A, B, C, D);
 If (K = 1) Or (K = 3) Then X := A Else X := C;
 If (K = 1) Or (K = 2) Then Y := B Else Y := D;
End;

Function IsBoxKind(K: Integer): Boolean;
Begin
 IsBoxKind := K In [K_RECT, K_OVAL, K_IMAGE, K_GRAD, K_REDACT, K_HILITE, K_STAMP, K_UNDER, K_STRIKE];
End;

Procedure DrawTextBoxRot(Const O: TObjRec);
Var
 CX, CY: Array[0..3] Of Real;
 I, J: Integer;
Begin
 TextCorners(O, CX, CY);
 SetLineStyle(DashedLn, 0, 1);
 For I := 0 To 3 Do Begin
  J := (I + 1) And 3;
  Line(C16(MXr(CX[I], CY[I])), C16(MYr(CX[I], CY[I])), C16(MXr(CX[J], CY[J])), C16(MYr(CX[J], CY[J])));
 End;
 SetLineStyle(SolidLn, 0, 1);
End;

Procedure DrawSelectionBox(Const O: TObjRec);
Var
 SX1, SY1, SX2, SY2, PX, PY, CX, CY: LongInt;
 I: Integer;
Begin
 SetFillStyle(SolidFill, LightBlue);
 SetColor(Blue);
 If (O.Kind = K_TEXT) And (TextAng(O) <> 0) Then Begin
  DrawTextBoxRot(O);
  Exit;
 End;
 If O.Kind In [K_LINE, K_ARROW] Then Begin
  For I := 1 To 2 Do Begin
   If I = 1 Then Begin CX := O.X1; CY := O.Y1; End Else Begin CX := O.X2; CY := O.Y2; End;
   PX := MXp(CX, CY); PY := MYp(CX, CY);
   Bar(C16(PX - 3), C16(PY - 3), C16(PX + 3), C16(PY + 3));
   Rectangle(C16(PX - 3), C16(PY - 3), C16(PX + 3), C16(PY + 3));
  End;
  Exit;
 End;
 ScrBox(O, SX1, SY1, SX2, SY2);
 SetLineStyle(DashedLn, 0, 1);
 Rectangle(C16(SX1 - 2), C16(SY1 - 2), C16(SX2 + 2), C16(SY2 + 2));
 SetLineStyle(SolidLn, 0, 1);
 If IsBoxKind(O.Kind) Then
  For I := 1 To 4 Do Begin
   CornerOf(O, I, CX, CY);
   PX := MXp(CX, CY); PY := MYp(CX, CY);
   Bar(C16(PX - 3), C16(PY - 3), C16(PX + 3), C16(PY + 3));
   Rectangle(C16(PX - 3), C16(PY - 3), C16(PX + 3), C16(PY + 3));
  End;
End;

{ Dessine une page complète. OX, OY : coin supérieur gauche (coordonnées
  de la fenêtre graphique courante). }
Procedure RenderPage(Pg: Integer; OX, OY, Sc: LongInt; Full: Boolean);
Var
 DW, DH, I: LongInt;
 SX1, SY1, SX2, SY2: LongInt;
Begin
 SetCtx(Pg, OX, OY, Sc);
 DW := DispWOf(Pg, Sc);
 DH := DispHOf(Pg, Sc);
 If Full Then Begin
  SetFillStyle(SolidFill, Black);
  Bar(C16(OX + 3), C16(OY + 3), C16(OX + DW + 3), C16(OY + DH + 3));
 End;
 SetFillStyle(SolidFill, White);
 Bar(C16(OX), C16(OY), C16(OX + DW), C16(OY + DH));
 SetColor(Black);
 Rectangle(C16(OX), C16(OY), C16(OX + DW), C16(OY + DH));
 For I := 1 To 3 Do Begin
  For SX1 := 0 To ObjCount - 1 Do
   If (ObjP(SX1)^.Page = Pg) And LayerOn(ObjP(SX1)^.Layer) Then DrawObj(ObjP(SX1)^, I);
 End;
 If Full Then Begin
  If (FindObj >= 0) And (FindObj < ObjCount) Then
   If ObjP(FindObj)^.Page = Pg Then Begin
    ScrBox(ObjP(FindObj)^, SX1, SY1, SX2, SY2);
    SetColor(LightRed);
    Rectangle(C16(SX1 - 2), C16(SY1 - 2), C16(SX2 + 2), C16(SY2 + 2));
    Rectangle(C16(SX1 - 3), C16(SY1 - 3), C16(SX2 + 3), C16(SY2 + 3));
   End;
  If (SelObj >= 0) And (SelObj < ObjCount) Then
   If ObjP(SelObj)^.Page = Pg Then DrawSelectionBox(ObjP(SelObj)^);
 End;
End;

{ ---------------------------------------------------------------------- }
{ Gestion du document                                                       }
{ ---------------------------------------------------------------------- }

Procedure AllocDoc;
Begin
 LayerCount := 0;
 ObjHead := Nil; ObjCurBlk := Nil; ObjBlocks := 0; ObjCount := 0;
 PgHead := Nil; PgCurBlk := Nil; PgBlocks := 0; PageCount := 0;
 PoolHead := Nil; PoolCurBlk := Nil; PoolBlocks := 0; PoolCount := 0;
 ImgHead := Nil; ImgCurBlk := Nil; ImgBlocks := 0; ImgCount := 0;
 ObjEnsure(0);
 PgEnsure(1);
 PoolEnsure(1);
End;

Procedure FreeUndoRec(Var U: TUndoRec);
Begin
 If U.Objs <> Nil Then FreeMem(U.Objs, U.Cnt * SizeOf(TObjRec));
 If U.Pgs <> Nil Then FreeMem(U.Pgs, U.PgCnt * SizeOf(TPageRec));
 U.Objs := Nil;
 U.Pgs := Nil;
 U.Cnt := 0;
 U.PgCnt := 0;
 U.Mem := 0;
End;

Procedure ClearUndo;
Var
 I: Integer;
Begin
 For I := 0 To UndoTop - 1 Do FreeUndoRec(UndoStack[I]);
 For I := 0 To RedoTop - 1 Do FreeUndoRec(RedoStack[I]);
 UndoTop := 0;
 RedoTop := 0;
End;

Procedure ClearRedo;
Var
 I: Integer;
Begin
 For I := 0 To RedoTop - 1 Do FreeUndoRec(RedoStack[I]);
 RedoTop := 0;
End;

Procedure MakeSnap(Var U: TUndoRec);
Var
 I: LongInt;
Begin
 U.Cnt := ObjCount;
 U.PgCnt := PageCount;
 U.Cur := CurPage;
 U.Objs := Nil;
 U.Pgs := Nil;
 U.Mem := 0;
 If ObjCount > 0 Then Begin
  GetMem(U.Objs, ObjCount * SizeOf(TObjRec));
  For I := 0 To ObjCount - 1 Do Move(ObjP(I)^, Pointer(PtrUInt(U.Objs) + PtrUInt(I) * SizeOf(TObjRec))^, SizeOf(TObjRec));
  U.Mem := ObjCount * SizeOf(TObjRec);
 End;
 If PageCount > 0 Then Begin
  GetMem(U.Pgs, PageCount * SizeOf(TPageRec));
  For I := 1 To PageCount Do Move(PgP(I)^, Pointer(PtrUInt(U.Pgs) + PtrUInt(I - 1) * SizeOf(TPageRec))^, SizeOf(TPageRec));
 End;
End;

Function UndoMemory: LongInt;
Var
 I: Integer;
 T: LongInt;
Begin
 T := 0;
 For I := 0 To UndoTop - 1 Do T := T + UndoStack[I].Mem;
 For I := 0 To RedoTop - 1 Do T := T + RedoStack[I].Mem;
 UndoMemory := T;
End;

{ À appeler avant toute modification du document }
Procedure PushUndo;
Var
 I: Integer;
Begin
 ClearRedo;
 While (UndoTop >= UNDO_MAX) Or ((UndoTop > 0) And (UndoMemory > UNDO_MEM)) Do Begin
  FreeUndoRec(UndoStack[0]);
  For I := 1 To UndoTop - 1 Do UndoStack[I - 1] := UndoStack[I];
  Dec(UndoTop);
 End;
 MakeSnap(UndoStack[UndoTop]);
 Inc(UndoTop);
 Modified := True;
End;

Procedure ApplySnap(Var U: TUndoRec);
Var
 I: LongInt;
Begin
 ObjCount := U.Cnt;
 PageCount := U.PgCnt;
 For I := 0 To U.Cnt - 1 Do Begin
  ObjEnsure(I);
  Move(Pointer(PtrUInt(U.Objs) + PtrUInt(I) * SizeOf(TObjRec))^, ObjP(I)^, SizeOf(TObjRec));
 End;
 PgEnsure(U.PgCnt);
 For I := 1 To U.PgCnt Do Move(Pointer(PtrUInt(U.Pgs) + PtrUInt(I - 1) * SizeOf(TPageRec))^, PgP(I)^, SizeOf(TPageRec));
 CurPage := U.Cur;
 If CurPage > PageCount Then CurPage := PageCount;
 If CurPage < 1 Then CurPage := 1;
 SelObj := -1;
 FindObj := -1;
End;

Function CanUndo: Boolean;
Begin
 CanUndo := UndoTop > 0;
End;

Function CanRedo: Boolean;
Begin
 CanRedo := RedoTop > 0;
End;

Procedure DoUndo;
Begin
 If UndoTop = 0 Then Exit;
 If RedoTop < UNDO_MAX Then Begin
  MakeSnap(RedoStack[RedoTop]);
  Inc(RedoTop);
 End;
 Dec(UndoTop);
 ApplySnap(UndoStack[UndoTop]);
 FreeUndoRec(UndoStack[UndoTop]);
 Modified := True;
End;

Procedure DoRedo;
Begin
 If RedoTop = 0 Then Exit;
 MakeSnap(UndoStack[UndoTop]);
 Inc(UndoTop);
 Dec(RedoTop);
 ApplySnap(RedoStack[RedoTop]);
 FreeUndoRec(RedoStack[RedoTop]);
 Modified := True;
End;

Procedure InitObj(Var O: TObjRec; Kind, Pg: Integer);
Begin
 FillChar(O, SizeOf(O), 0);
 O.Kind := Kind;
 O.Page := Pg;
 O.Wd := 1;
 O.Size := 12;
 O.Rgb := 0;
 O.Rgb2 := $FFFFFF;
End;

{ Somme de contrôle d'un objet (détection des modifications depuis l'import) }
Function ObjSum(Idx: LongInt): LongInt;
Var
 T: TObjRec;
 P: PByteBuf;
 A, B: LongInt;
 I, N: LongInt;
 Procedure Add(V: LongInt);
 Begin
  A := (A + (V And 255) + 1) Mod 65521; B := (B + A) Mod 65521;
  A := (A + ((V Shr 8) And 255)) Mod 65521; B := (B + A) Mod 65521;
 End;
Begin
 T := ObjP(Idx)^;
 T.Sum := 0;
 P := PByteBuf(@T);
 A := 1; B := 0;
 For I := 0 To SizeOf(TObjRec) - 1 Do Begin
  A := (A + P^[I]) Mod 65521;
  B := (B + A) Mod 65521;
 End;
 If T.Kind In [K_POLY, K_INK, K_GRAD] Then
  For I := 0 To T.PN - 1 Do Begin
   Add(PoolXP(T.P0 + I)^);
   Add(PoolYP(T.P0 + I)^);
  End;
 ObjSum := (B Mod 32749) * 65536 + A;
End;

Function NewObj(Kind, Pg: Integer): Integer;
Begin
 If Not ObjEnsure(ObjCount) Then Begin
  NewObj := -1;
  Exit;
 End;
 InitObj(ObjP(ObjCount)^, Kind, Pg);
 NewObj := ObjCount;
 Inc(ObjCount);
End;

Procedure DelObj(I: LongInt);
Var
 J: LongInt;
Begin
 If (I < 0) Or (I >= ObjCount) Then Exit;
 For J := I To ObjCount - 2 Do ObjP(J)^ := ObjP(J + 1)^;
 Dec(ObjCount);
 If SelObj = I Then SelObj := -1 Else If SelObj > I Then Dec(SelObj);
 If FindObj = I Then FindObj := -1 Else If FindObj > I Then Dec(FindObj);
End;

Function PoolAlloc(N: Integer): Integer;
Begin
 If Not PoolEnsure(PoolCount + N) Then PoolAlloc := -1
 Else Begin
  PoolAlloc := PoolCount;
  Inc(PoolCount, N);
 End;
End;

Procedure RecalcBox(Idx: Integer);
Var
 I: Integer;
 Len: LongInt;
 Ox, Oy: Real;
 MnX, MnY, MxX, MxY: Integer;
 O: ^TObjRec;
Begin
 O := @ObjP(Idx)^;
 If O^.Kind = K_TEXT Then Begin
  Len := TextLenPts(O^.Txt, O^.Size, O^.Style Shr 2, O^.Style And 3);
  If Len < 1 Then Len := O^.Size Div 2 + 1;
  O^.P0 := Len;
  TextOrigin(O^, Ox, Oy);
  SetTextBox(O^, Ox, Oy);
 End
 Else If (O^.Kind In [K_POLY, K_INK, K_GRAD]) And (O^.PN > 0) Then Begin
  MnX := 32000; MnY := 32000; MxX := -32000; MxY := -32000;
  For I := O^.P0 To O^.P0 + O^.PN - 1 Do Begin
   If PoolXP(I)^ < MnX Then MnX := PoolXP(I)^;
   If PoolXP(I)^ > MxX Then MxX := PoolXP(I)^;
   If PoolYP(I)^ < MnY Then MnY := PoolYP(I)^;
   If PoolYP(I)^ > MxY Then MxY := PoolYP(I)^;
  End;
  O^.X1 := MnX; O^.Y1 := MnY; O^.X2 := MxX; O^.Y2 := MxY;
 End
 Else If O^.Kind = K_NOTE Then Begin
  O^.X2 := O^.X1 + 16;
  O^.Y2 := O^.Y1 + 16;
 End;
End;

Procedure MoveObj(Idx: Integer; DX, DY: LongInt);
Var
 I: Integer;
Begin
 With ObjP(Idx)^ Do Begin
  X1 := X1 + DX; X2 := X2 + DX;
  Y1 := Y1 + DY; Y2 := Y2 + DY;
  If (Kind = K_TEXT) And (PN Mod 3600 <> 0) Then PackOrigin(ObjP(Idx)^, (Rgb2 Div 32768) - 16384 + DX, (Rgb2 Mod 32768) - 16384 + DY);
  If Kind In [K_POLY, K_INK, K_GRAD] Then
   For I := P0 To P0 + PN - 1 Do Begin
    PoolXP(I)^ := PoolXP(I)^ + DX;
    PoolYP(I)^ := PoolYP(I)^ + DY;
   End;
 End;
End;

{ Change l'angle d'un texte en le faisant pivoter autour du centre de sa ligne }
Procedure SetTextAngle(Idx: Integer; Tenths: Integer);
Var
 Ox, Oy, Dx, Dy, Vx, Vy, L, H, Cx, Cy: Real;
Begin
 With ObjP(Idx)^ Do Begin
  TextOrigin(ObjP(Idx)^, Ox, Oy);
  TextDirs(TextAng(ObjP(Idx)^), Dx, Dy, Vx, Vy);
  L := TextLenOf(ObjP(Idx)^); H := TextLineH(ObjP(Idx)^);
  Cx := Ox + (L * Dx + H * Vx) / 2;
  Cy := Oy + (L * Dy + H * Vy) / 2;
  PN := ((Tenths Mod 3600) + 3600) Mod 3600;
  TextDirs(PN, Dx, Dy, Vx, Vy);
  Ox := Cx - (L * Dx + H * Vx) / 2;
  Oy := Cy - (L * Dy + H * Vy) / 2;
 End;
 SetTextBox(ObjP(Idx)^, Ox, Oy);
End;

{ Redimensionne un polygone / une encre vers une nouvelle boîte }
Procedure ScaleObjTo(Idx: Integer; NX1, NY1, NX2, NY2: LongInt);
Var
 I: Integer;
 OX1, OY1, OW, OH, NW, NH: LongInt;
Begin
 With ObjP(Idx)^ Do Begin
  If (Kind In [K_POLY, K_INK]) Or ((Kind = K_GRAD) And (PN > 0)) Then Begin
   OX1 := X1; OY1 := Y1;
   OW := IMax(1, X2 - X1); OH := IMax(1, Y2 - Y1);
   NW := NX2 - NX1; NH := NY2 - NY1;
   For I := P0 To P0 + PN - 1 Do Begin
    PoolXP(I)^ := NX1 + ((PoolXP(I)^ - OX1) * NW) Div OW;
    PoolYP(I)^ := NY1 + ((PoolYP(I)^ - OY1) * NH) Div OH;
   End;
  End;
  X1 := NX1; Y1 := NY1; X2 := NX2; Y2 := NY2;
 End;
End;

{ ---------------------------------------------------------------------- }
{ Pages                                                                     }
{ ---------------------------------------------------------------------- }

Procedure InsertPageAt(After, W, H: Integer);
Var
 I: Integer;
Begin
 If Not PgEnsure(PageCount + 1) Then Exit;
 For I := 0 To ObjCount - 1 Do
  If ObjP(I)^.Page > After Then Inc(ObjP(I)^.Page);
 For I := PageCount DownTo After + 1 Do PgP(I + 1)^ := PgP(I)^;
 Inc(PageCount);
 FillChar(PgP(After + 1)^, SizeOf(TPageRec), 0);
 PgP(After + 1)^.W := W;
 PgP(After + 1)^.H := H;
 PgP(After + 1)^.Rot := 0;
 PgP(After + 1)^.Top := 0;
End;

Procedure DeletePageAt(P: Integer);
Var
 I, J: Integer;
Begin
 If PageCount <= 1 Then Exit;
 J := 0;
 For I := 0 To ObjCount - 1 Do Begin
  If ObjP(I)^.Page <> P Then Begin
   If ObjP(I)^.Page > P Then Dec(ObjP(I)^.Page);
   If I <> J Then ObjP(J)^ := ObjP(I)^;
   Inc(J);
  End;
 End;
 ObjCount := J;
 For I := P To PageCount - 1 Do PgP(I)^ := PgP(I + 1)^;
 Dec(PageCount);
 If CurPage > PageCount Then CurPage := PageCount;
 SelObj := -1;
 FindObj := -1;
End;

Procedure DupPageAt(P: Integer);
Var
 I, N, J: Integer;
Begin
 InsertPageAt(P, PgP(P)^.W, PgP(P)^.H);
 PgP(P + 1)^.Rot := PgP(P)^.Rot;
 N := ObjCount;
 For I := 0 To N - 1 Do
  If ObjP(I)^.Page = P Then Begin
   J := NewObj(1, P + 1);
   If J < 0 Then Break;
   ObjP(J)^ := ObjP(I)^;
   ObjP(J)^.Page := P + 1;
  End;
End;

Procedure SwapPages(A, B: Integer);
Var
 T: TPageRec;
 I: Integer;
Begin
 T := PgP(A)^; PgP(A)^ := PgP(B)^; PgP(B)^ := T;
 For I := 0 To ObjCount - 1 Do
  If ObjP(I)^.Page = A Then ObjP(I)^.Page := B
  Else If ObjP(I)^.Page = B Then ObjP(I)^.Page := A;
End;

Procedure FreeImages; Forward;

Procedure NewDocument;
Begin
 FreeImages;
 ObjsFree; PgsFree; PoolFree;
 ObjEnsure(0); PgEnsure(1); PoolEnsure(1);
 ObjCount := 0;
 PoolCount := 0;
 PageCount := 1;
 CurPage := 1;
 FillChar(PgP(1)^, SizeOf(TPageRec), 0);
 PgP(1)^.W := 612; PgP(1)^.H := 792; PgP(1)^.Rot := 0;
 SelObj := -1; FindObj := -1;
 DocName := '';
 SrcValid := False; InfoDirty := False; NeedFullRewrite := False; SrcFile := '';
 DocTitle := ''; DocAuthor := ''; DocSubject := ''; DocKeywords := ''; DocCreator := '';
 Modified := False;
 DocEncrypted := False;
 ScrollX := 0; ScrollY := 0;
 ClearUndo;
End;

{ ---------------------------------------------------------------------- }
{ Sélection d'objets                                                        }
{ ---------------------------------------------------------------------- }

Function DistSeg(PX, PY, AX, AY, BX, BY: Real): Real;
Var
 DX, DY, T, L2, CX, CY: Real;
Begin
 DX := BX - AX; DY := BY - AY;
 L2 := DX * DX + DY * DY;
 If L2 < 0.0001 Then T := 0
 Else T := ((PX - AX) * DX + (PY - AY) * DY) / L2;
 If T < 0 Then T := 0;
 If T > 1 Then T := 1;
 CX := AX + T * DX; CY := AY + T * DY;
 DistSeg := Sqrt((PX - CX) * (PX - CX) + (PY - CY) * (PY - CY));
End;

Function HitObj(Pg: Integer; X, Y: LongInt; Tol: Real): Integer;
Var
 I, J: Integer;
 NX1, NY1, NX2, NY2: LongInt;
 Hit: Boolean;
 CX, CY, RX, RY, V, DTmp: Real;
 O: ^TObjRec;
Begin
 HitObj := -1;
 For I := ObjCount - 1 DownTo 0 Do Begin
  O := @ObjP(I)^;
  If O^.Page <> Pg Then Continue;
  If Not LayerOn(O^.Layer) Then Continue;
  NormBox(O^, NX1, NY1, NX2, NY2);
  Hit := False;
  Case O^.Kind Of
   K_TEXT: Begin
    If TextAng(O^) = 0 Then
     Hit := (X >= NX1 - Tol) And (X <= NX2 + Tol) And (Y >= NY1 - Tol) And (Y <= NY2 + Tol)
    Else Begin
     TextOrigin(O^, CX, CY);
     TextDirs(TextAng(O^), RX, RY, V, DTmp);
     { (RX,RY) direction du texte ; (-RY,RX) vers le bas du glyphe }
     DTmp := (X - CX) * RX + (Y - CY) * RY;
     V := (X - CX) * (-RY) + (Y - CY) * RX;
     Hit := (DTmp >= -Tol) And (DTmp <= TextLenOf(O^) + Tol) And (V >= -Tol) And (V <= TextLineH(O^) + Tol);
    End;
   End;
   K_LINE, K_ARROW:
    Hit := DistSeg(X, Y, O^.X1, O^.Y1, O^.X2, O^.Y2) <= Tol + O^.Wd / 2;
   K_RECT:
    If (X >= NX1 - Tol) And (X <= NX2 + Tol) And (Y >= NY1 - Tol) And (Y <= NY2 + Tol) Then Begin
     If O^.Fill <> 0 Then Hit := True
     Else Hit := (X <= NX1 + Tol) Or (X >= NX2 - Tol) Or (Y <= NY1 + Tol) Or (Y >= NY2 - Tol);
    End;
   K_OVAL: Begin
    CX := (NX1 + NX2) / 2; CY := (NY1 + NY2) / 2;
    RX := (NX2 - NX1) / 2 + Tol; RY := (NY2 - NY1) / 2 + Tol;
    If (RX > 0) And (RY > 0) Then Begin
     V := (X - CX) * (X - CX) / (RX * RX) + (Y - CY) * (Y - CY) / (RY * RY);
     If O^.Fill <> 0 Then Hit := V <= 1
     Else Begin
      RX := RX - 2 * Tol; RY := RY - 2 * Tol;
      If (RX <= 0) Or (RY <= 0) Then Hit := V <= 1
      Else Hit := (V <= 1) And ((X - CX) * (X - CX) / (RX * RX) + (Y - CY) * (Y - CY) / (RY * RY) >= 1);
     End;
    End;
   End;
   K_POLY, K_INK: Begin
    If (X >= NX1 - Tol) And (X <= NX2 + Tol) And (Y >= NY1 - Tol) And (Y <= NY2 + Tol) Then Begin
     For J := O^.P0 To O^.P0 + O^.PN - 2 Do
      If DistSeg(X, Y, PoolXP(J)^, PoolYP(J)^, PoolXP(J + 1)^, PoolYP(J + 1)^) <= Tol + O^.Wd / 2 Then Hit := True;
     If (O^.Kind = K_POLY) And (O^.Fill <> 0) Then Hit := True;
    End;
   End;
  Else
   Hit := (X >= NX1 - Tol) And (X <= NX2 + Tol) And (Y >= NY1 - Tol) And (Y <= NY2 + Tol);
  End;
  If Hit Then Begin
   HitObj := I;
   Exit;
  End;
 End;
End;

{ Poignée sous le pointeur (coordonnées écran, contexte de page courant) }
Function HandleAt(Idx: Integer; SX, SY: LongInt): Integer;
Var
 K: Integer;
 CX, CY, PX, PY: LongInt;
Begin
 HandleAt := 0;
 If (Idx < 0) Or (Idx >= ObjCount) Then Exit;
 With ObjP(Idx)^ Do Begin
  If Kind In [K_LINE, K_ARROW] Then Begin
   If (IAbs(SX - MXp(X1, Y1)) <= 5) And (IAbs(SY - MYp(X1, Y1)) <= 5) Then HandleAt := 5
   Else If (IAbs(SX - MXp(X2, Y2)) <= 5) And (IAbs(SY - MYp(X2, Y2)) <= 5) Then HandleAt := 6;
   Exit;
  End;
  If Not IsBoxKind(Kind) Then Exit;
  For K := 1 To 4 Do Begin
   CornerOf(ObjP(Idx)^, K, CX, CY);
   PX := MXp(CX, CY); PY := MYp(CX, CY);
   If (IAbs(SX - PX) <= 5) And (IAbs(SY - PY) <= 5) Then Begin
    HandleAt := K;
    Exit;
   End;
  End;
 End;
End;

{ ---------------------------------------------------------------------- }
{ Écriture PDF                                                              }
{ ---------------------------------------------------------------------- }

Var
 OutF: File;
 OutPos: LongInt;
 OutErr: Boolean;
 XOfs: Array[0..1] Of LongInt;
 XRef: PXArr;

Var
 CapOn: Boolean;
 CapBuf: PByteBuf;
 CapLen, CapSize: LongInt;

{ Écriture dans un tampon (pour compresser un flux avant de l'écrire) }
Procedure CapAppend(Const S: String);
Var
 P: Pointer;
Begin
 If CapLen + Length(S) + 16 > CapSize Then Begin
  CapSize := CapSize * 2 + Length(S) + 4096;
  P := CapBuf;
  ReAllocMem(P, CapSize);
  CapBuf := P;
 End;
 If Length(S) > 0 Then Move(S[1], CapBuf^[CapLen], Length(S));
 CapLen := CapLen + Length(S);
End;

Procedure WS(Const S: String);
Begin
 If CapOn Then Begin CapAppend(S); Exit; End;
 If OutErr Or (Length(S) = 0) Then Exit;
 {$I-}
 BlockWrite(OutF, S[1], Length(S));
 {$I+}
 If IOResult <> 0 Then OutErr := True;
 OutPos := OutPos + Length(S);
End;

Procedure WL(Const S: String);
Begin
 WS(S + #10);
End;

Function PdfStr(Const S: String): String;
Var
 I: Integer;
 R: String;
 C: Integer;
Begin
 R := '(';
 For I := 1 To Length(S) Do Begin
  C := Ord(S[I]);
  If (C = 40) Or (C = 41) Or (C = 92) Then R := R + '\' + S[I]
  Else If (C < 32) Or (C > 126) Then Begin
   R := R + '\' + Chr(48 + (C Shr 6)) + Chr(48 + ((C Shr 3) And 7)) + Chr(48 + (C And 7));
  End
  Else R := R + S[I];
  If Length(R) > 240 Then Break;
 End;
 PdfStr := R + ')';
End;

Function ColStr(Rgb: LongInt): String;
Begin
 ColStr := RStr(((Rgb Shr 16) And 255) / 255) + ' ' + RStr(((Rgb Shr 8) And 255) / 255) + ' ' +
           RStr((Rgb And 255) / 255);
End;

{ ---------------------------------------------------------------------- }
{ Compression Flate (zlib) : LZ77 + codes de Huffman fixes                  }
{ ---------------------------------------------------------------------- }

{$IFDEF FPC}
Var
 DfOut: PByteBuf;
 DfPos: LongInt;
 DfBitBuf: LongWord;
 DfBitCnt: Integer;

Procedure DfPutBits(V: LongWord; N: Integer);
Begin
 DfBitBuf := DfBitBuf Or (V Shl DfBitCnt);
 Inc(DfBitCnt, N);
 While DfBitCnt >= 8 Do Begin
  DfOut^[DfPos] := DfBitBuf And 255;
  Inc(DfPos);
  DfBitBuf := DfBitBuf Shr 8;
  Dec(DfBitCnt, 8);
 End;
End;

Procedure DfPutCode(Code: LongWord; N: Integer);
Var
 R: LongWord;
 I: Integer;
Begin
 R := 0;
 For I := 1 To N Do Begin
  R := (R Shl 1) Or (Code And 1);
  Code := Code Shr 1;
 End;
 DfPutBits(R, N);
End;

Procedure DfLit(Sym: Integer);
Begin
 If Sym < 144 Then DfPutCode($30 + Sym, 8)
 Else If Sym < 256 Then DfPutCode($190 + Sym - 144, 9)
 Else If Sym < 280 Then DfPutCode(Sym - 256, 7)
 Else DfPutCode($C0 + Sym - 280, 8);
End;

{ Compresse Src (SLen octets) ; Dst est alloué ici (à libérer avec FreeMem). }
Function DeflateBuf(Src: PByteBuf; SLen: LongInt; Var Dst: PByteBuf; Var DLen: LongInt): Boolean;
Var
 Head: Array[0..32767] Of LongInt;
 Prev: Array[0..32767] Of LongInt;
 Pos, I, K, Best, BestD, Cand, Tries, L, MaxL, Lim: LongInt;
 A, B: LongWord;
 H: LongInt;
 Cap: LongInt;
 Function Hash3(P: LongInt): LongInt;
 Begin
  Hash3 := ((Src^[P] Shl 10) Xor (Src^[P + 1] Shl 5) Xor Src^[P + 2]) And 32767;
 End;
 Procedure Insert(P: LongInt);
 Var
  HH: LongInt;
 Begin
  If P + 2 < SLen Then Begin
   HH := Hash3(P);
   Prev[P And 32767] := Head[HH];
   Head[HH] := P;
  End;
 End;
Begin
 DeflateBuf := False;
 Dst := Nil; DLen := 0;
 If SLen < 1 Then Exit;
 Cap := SLen + SLen Div 6 + 128;
 GetMem(Dst, Cap);
 If Dst = Nil Then Exit;
 DfOut := Dst; DfPos := 0; DfBitBuf := 0; DfBitCnt := 0;
 DfOut^[0] := $78; DfOut^[1] := $9C; DfPos := 2;
 FillChar(Head, SizeOf(Head), $FF);
 FillChar(Prev, SizeOf(Prev), $FF);
 DfPutBits(1, 1);      { BFINAL }
 DfPutBits(1, 2);      { BTYPE = 01 : Huffman fixe }
 Pos := 0;
 While Pos < SLen Do Begin
  Best := 0; BestD := 0;
  If Pos + 2 < SLen Then Begin
   H := Hash3(Pos);
   Cand := Head[H];
   Tries := 0;
   MaxL := SLen - Pos;
   If MaxL > 258 Then MaxL := 258;
   While (Cand >= 0) And (Pos - Cand <= 32768) And (Tries < 28) Do Begin
    If Src^[Cand + Best] = Src^[Pos + Best] Then Begin
     L := 0;
     While (L < MaxL) And (Src^[Cand + L] = Src^[Pos + L]) Do Inc(L);
     If L > Best Then Begin Best := L; BestD := Pos - Cand; If L >= MaxL Then Break; End;
    End;
    I := Prev[Cand And 32767];
    If (I >= Cand) Then Break;
    Cand := I;
    Inc(Tries);
   End;
  End;
  If Best >= 3 Then Begin
   K := 28;
   While LBase[K] > Best Do Dec(K);
   DfLit(257 + K);
   If LExtra[K] > 0 Then DfPutBits(Best - LBase[K], LExtra[K]);
   K := 29;
   While DBase[K] > BestD Do Dec(K);
   DfPutCode(K, 5);
   If DExtra[K] > 0 Then DfPutBits(BestD - DBase[K], DExtra[K]);
   For I := 0 To Best - 1 Do Insert(Pos + I);
   Inc(Pos, Best);
  End
  Else Begin
   DfLit(Src^[Pos]);
   Insert(Pos);
   Inc(Pos);
  End;
  If DfPos > Cap - 64 Then Begin FreeMem(Dst, Cap); Dst := Nil; Exit; End;
 End;
 DfLit(256);
 If DfBitCnt > 0 Then DfPutBits(0, 8 - DfBitCnt);
 A := 1; B := 0;
 For I := 0 To SLen - 1 Do Begin
  A := (A + Src^[I]) Mod 65521;
  B := (B + A) Mod 65521;
 End;
 DfOut^[DfPos] := (B Shr 8) And 255; Inc(DfPos);
 DfOut^[DfPos] := B And 255; Inc(DfPos);
 DfOut^[DfPos] := (A Shr 8) And 255; Inc(DfPos);
 DfOut^[DfPos] := A And 255; Inc(DfPos);
 DLen := DfPos;
 DeflateBuf := True;
End;
{$ENDIF}

Procedure WriteBytes(P: PByteBuf; N: LongInt);
Var
 K, L16: LongInt;
Begin
 K := 0;
 While (K < N) And (Not OutErr) Do Begin
  If N - K > 16384 Then L16 := 16384 Else L16 := N - K;
  {$I-}
  BlockWrite(OutF, P^[K], L16);
  {$I+}
  If IOResult <> 0 Then OutErr := True;
  OutPos := OutPos + L16;
  Inc(K, L16);
 End;
End;

Var
 IncMode: Boolean;
 XList: PLArr;
 XCnt, XCap: LongInt;

Procedure IncAdd(N, Ofs: LongInt);
Var
 P: Pointer;
Begin
 If XCnt + 2 > XCap Then Begin
  XCap := XCap * 2 + 1024;
  P := XList; ReAllocMem(P, XCap * 2 * SizeOf(LongInt)); XList := P;
 End;
 XList^[XCnt * 2] := N; XList^[XCnt * 2 + 1] := Ofs;
 Inc(XCnt);
End;

Procedure BeginObj(N: Integer);
Begin
 If IncMode Then IncAdd(N, OutPos) Else XRef^[N] := OutPos;
 WL(IStr(N) + ' 0 obj');
End;

Procedure EndObj;
Begin
 WL('endobj');
End;

Function PY_(Pg: Integer; Y: LongInt): String;
Begin
 PY_ := RStr(PgP(Pg)^.H - Y);
End;

Function PdfDate: String;
Var
 Y, M, D, DW, H, Mi, S, S1: Word;
Begin
 GetDate(Y, M, D, DW);
 GetTime(H, Mi, S, S1);
 PdfDate := 'D:' + IStr(Y) + Pad2(M) + Pad2(D) + Pad2(H) + Pad2(Mi) + Pad2(S);
End;

Function ImgKept(I: Integer): Boolean;
Begin
 ImgKept := (I > 0) And (I <= ImgCount) And ImgP(I)^.Keep And (ImgP(I)^.Raw <> Nil);
End;

Var
 CMode: Integer;           { 0 tout, 1 nouveautés avant l'original, 2 nouveautés après }
 CFirstOrig: LongInt;
 CDrop: PLArr;
 CDropN: LongInt;
 FPre, IPre: String[4];

Function InDrop(N: LongInt): Boolean;
Var
 K: LongInt;
Begin
 InDrop := False;
 For K := 0 To CDropN - 1 Do If CDrop^[K] = N Then Begin InDrop := True; Exit; End;
End;

{ Cet objet est-il écrit dans le flux de contenu selon le mode courant ? }
Function ObjEmits(Const O: TObjRec; I: LongInt): Boolean;
Begin
 ObjEmits := False;
 If O.Src = 3 Then Exit;
 If Not LayerOn(O.Layer) Then Exit;
 Case CMode Of
  0: If (O.Src = 2) And (Not InDrop(O.SrcNum)) Then Exit;
  1: If (Not ((O.Src = 0) Or ((O.Src = 2) And InDrop(O.SrcNum)))) Or (I >= CFirstOrig) Then Exit;
  2: If (Not ((O.Src = 0) Or ((O.Src = 2) And InDrop(O.SrcNum)))) Or (I < CFirstOrig) Then Exit;
 End;
 ObjEmits := True;
End;

{ Couleur de remplissage tenant compte de la transparence (aplatie sur fond blanc) }
Function FillTint(Const O: TObjRec): LongInt;
Var
 A: Integer;
 R, G, B: LongInt;
Begin
 FillTint := O.Rgb2;
 If (O.Kind In [K_RECT, K_OVAL, K_POLY]) And (O.Fill <> 0) And (O.Alpha > 0) And (O.Alpha < 255) Then Begin
  A := O.Alpha;
  R := (((O.Rgb2 Shr 16) And 255) * A + 255 * (255 - A)) Div 255;
  G := (((O.Rgb2 Shr 8) And 255) * A + 255 * (255 - A)) Div 255;
  B := ((O.Rgb2 And 255) * A + 255 * (255 - A)) Div 255;
  FillTint := RGBOf(R, G, B);
 End;
End;

Function CircleStr(CX, CY, R: Real): String;
Var
 K: Real;
Begin
 K := R * 0.5523;
 CircleStr := RStr(CX + R) + ' ' + RStr(CY) + ' m ' +
  RStr(CX + R) + ' ' + RStr(CY + K) + ' ' + RStr(CX + K) + ' ' + RStr(CY + R) + ' ' + RStr(CX) + ' ' + RStr(CY + R) + ' c ' +
  RStr(CX - K) + ' ' + RStr(CY + R) + ' ' + RStr(CX - R) + ' ' + RStr(CY + K) + ' ' + RStr(CX - R) + ' ' + RStr(CY) + ' c ' +
  RStr(CX - R) + ' ' + RStr(CY - K) + ' ' + RStr(CX - K) + ' ' + RStr(CY - R) + ' ' + RStr(CX) + ' ' + RStr(CY - R) + ' c ' +
  RStr(CX + K) + ' ' + RStr(CY - R) + ' ' + RStr(CX + R) + ' ' + RStr(CY - K) + ' ' + RStr(CX + R) + ' ' + RStr(CY) + ' c h f';
End;

{ Écrit un dégradé sous forme de bandes unies (sans ressource) }
Procedure WriteGradBands(Const O: TObjRec; X1, Y1, X2, Y2, H: LongInt);
Const
 NB = 32;
Var
 K: Integer;
 T0, T1, Dx, Dy, Len, Ax, Ay, Px, Py, L, TT0, TT1, Sx, Sr, Mid: Real;
 R, G, B: LongInt;
 CS: String;
 Function Pt(X, Y: Real): String;
 Begin
  Pt := RStr(X1 + X) + ' ' + RStr(H - (Y1 + Y));
 End;
Begin
 GradParse(O);
 If GdNSt < 2 Then Exit;
 GradColor(1, R, G, B);
 WL(RStr4(R / 255) + ' ' + RStr4(G / 255) + ' ' + RStr4(B / 255) + ' rg ' + IStr(X1) + ' ' + IStr(H - Y2) + ' ' + IStr(X2 - X1) + ' ' + IStr(Y2 - Y1) + ' re f');
 If GdType = 0 Then Begin
  Dx := GdX1 - GdX0; Dy := GdY1 - GdY0;
  Len := Sqrt(Dx * Dx + Dy * Dy);
  If Len < 0.001 Then Exit;
  L := 4 * (GdPW + GdPH) / Len;
  Px := -Dy * L; Py := Dx * L;
  For K := 0 To NB - 1 Do Begin
   T0 := K / NB; T1 := (K + 1) / NB;
   TT0 := T0; TT1 := T1 + 0.5 / NB;
   If K = 0 Then TT0 := -20;
   If K = NB - 1 Then TT1 := 20;
   GradColor((T0 + T1) / 2, R, G, B);
   WL(RStr4(R / 255) + ' ' + RStr4(G / 255) + ' ' + RStr4(B / 255) + ' rg ' +
      Pt(GdX0 + TT0 * Dx + Px, GdY0 + TT0 * Dy + Py) + ' m ' + Pt(GdX0 + TT1 * Dx + Px, GdY0 + TT1 * Dy + Py) + ' l ' +
      Pt(GdX0 + TT1 * Dx - Px, GdY0 + TT1 * Dy - Py) + ' l ' + Pt(GdX0 + TT0 * Dx - Px, GdY0 + TT0 * Dy - Py) + ' l h f');
  End;
 End
 Else Begin
  Dx := GdX1 - GdX0; Dy := GdY1 - GdY0;
  For K := NB - 1 DownTo 0 Do Begin
   Sx := (K + 1) / NB;
   Sr := GdR0 + Sx * (GdR1 - GdR0);
   If Sr < 0.3 Then Continue;
   Mid := (K + 0.5) / NB;
   GradColor(Mid, R, G, B);
   WL(RStr4(R / 255) + ' ' + RStr4(G / 255) + ' ' + RStr4(B / 255) + ' rg ' +
      CircleStr(X1 + GdX0 + Sx * Dx, H - (Y1 + GdY0 + Sx * Dy), Sr));
  End;
 End;
End;

Procedure ContentOf(Pg: Integer; Var Cnt: LongInt);
Var
 I, J: Integer;
 H: LongInt;
 O: ^TObjRec;
 S: String;
 X1, Y1, X2, Y2: LongInt;
 Nat, Tz: Real;
 K: Real;
 TX, TY, TOx, TOy, TDx, TDy, TVx, TVy: Real;
 BW_, BH_, Sg0, Sg1, Ex, Ey_, Fx, Fy, AX, AY: LongInt;
 Mt: String[40];
 CX, CY, RX, RY: Real;
 Op: String;
Begin
 H := PgP(Pg)^.H;
 For I := 0 To ObjCount - 1 Do Begin
  O := @ObjP(I)^;
  If O^.Page <> Pg Then Continue;
  If Not ObjEmits(O^, I) Then Continue;
  NormBox(O^, X1, Y1, X2, Y2);
  If (O^.Kind = K_IMAGE) And ImgKept(O^.P0) Then Begin
   S := 'q ';
   If ImgP(O^.P0)^.Mask Then S := S + ColStr(O^.Rgb) + ' rg ';
   BW_ := X2 - X1; BH_ := Y2 - Y1;
   If (O^.Style And 1) <> 0 Then Sg0 := -1 Else Sg0 := 1;
   If (O^.Style And 2) <> 0 Then Sg1 := -1 Else Sg1 := 1;
   If (O^.Style And 4) = 0 Then Begin
    Ex := Sg0 * BW_; Ey_ := 0; Fx := 0; Fy := Sg1 * BH_;
   End
   Else Begin
    Ex := 0; Ey_ := Sg0 * BH_; Fx := Sg1 * BW_; Fy := 0;
   End;
   { coin supérieur gauche de l'image dans la page }
   AX := X1; AY := Y1;
   If (Ex < 0) Or (Fx < 0) Then AX := X2;
   If (Ey_ < 0) Or (Fy < 0) Then AY := Y2;
   S := S + IStr(Ex) + ' ' + IStr(-Ey_) + ' ' + IStr(-Fx) + ' ' + IStr(Fy) + ' ' +
        IStr(AX + Fx) + ' ' + IStr(H - (AY + Fy));
   WL(S + ' cm /' + IPre + IStr(O^.P0) + ' Do Q');
   Continue;
  End;
  Case O^.Kind Of
   K_TEXT: Begin
    If O^.Txt = '' Then Continue;
    Nat := TextLenPts(O^.Txt, O^.Size, O^.Style Shr 2, O^.Style And 3);
    Tz := 100;
    If Nat > 0 Then Tz := TextLenOf(O^) * 100.0 / Nat;
    If (Tz < 60) Or (Tz > 160) Then Tz := 100;
    If Abs(Tz - 100) < 3 Then Tz := 100;
       TextOrigin(O^, TOx, TOy);
    TextDirs(TextAng(O^), TDx, TDy, TVx, TVy);
    TX := TOx + TVx * O^.Size * 4 / 5;
    TY := TOy + TVy * O^.Size * 4 / 5;
    Mt := RStr4(TDx) + ' ' + RStr4(-TDy) + ' ' + RStr4(TDy) + ' ' + RStr4(TDx);
    WL('q BT /' + FPre + IStr((O^.Style Shr 2) * 4 + (O^.Style And 3) + 1) + ' ' + IStr(O^.Size) + ' Tf ' +
       ColStr(O^.Rgb) + ' rg ' + RStr(Tz) + ' Tz ' + Mt + ' ' + RStr(TX) + ' ' +
       RStr(H - TY) + ' Tm ' + PdfStr(O^.Txt) + ' Tj ET Q');
   End;
   K_LINE, K_ARROW: Begin
    WL('q ' + ColStr(O^.Rgb) + ' RG ' + IStr(O^.Wd) + ' w 1 J ' + IStr(O^.X1) + ' ' + PY_(Pg, O^.Y1) + ' m ' +
       IStr(O^.X2) + ' ' + PY_(Pg, O^.Y2) + ' l S Q');
    If O^.Kind = K_ARROW Then Begin
     CX := O^.X2 - O^.X1; CY := O^.Y2 - O^.Y1;
     RX := Sqrt(CX * CX + CY * CY);
     If RX > 1 Then Begin
      CX := CX / RX; CY := CY / RX;
      K := 6 + O^.Wd * 2;
      WL('q ' + ColStr(O^.Rgb) + ' RG ' + IStr(O^.Wd) + ' w ' +
         RStr(O^.X2 - CX * K + CY * K * 0.45) + ' ' + RStr(H - (O^.Y2 - CY * K - CX * K * 0.45)) + ' m ' +
         IStr(O^.X2) + ' ' + PY_(Pg, O^.Y2) + ' l ' +
         RStr(O^.X2 - CX * K - CY * K * 0.45) + ' ' + RStr(H - (O^.Y2 - CY * K + CX * K * 0.45)) + ' l S Q');
     End;
    End;
   End;
   K_RECT, K_REDACT, K_IMAGE, K_STAMP: Begin
    S := 'q ';
    If O^.Kind = K_IMAGE Then S := S + '0.8 g 0.4 G 1 w '
    Else If O^.Kind = K_REDACT Then S := S + '1 0 0 RG 1.5 w '
    Else Begin
     S := S + ColStr(FillTint(O^)) + ' rg ' + ColStr(O^.Rgb) + ' RG ' + IStr(O^.Wd) + ' w ';
     If O^.Kind = K_STAMP Then S := S + '2 w ';
    End;
    S := S + IStr(X1) + ' ' + RStr(H - Y2) + ' ' + IStr(X2 - X1) + ' ' + IStr(Y2 - Y1) + ' re ';
    If O^.Kind = K_IMAGE Then S := S + 'B Q'
    Else If O^.Kind = K_REDACT Then S := S + 'S Q'
    Else If O^.Kind = K_STAMP Then S := S + 'S Q'
    Else Case O^.Fill Of
     0: S := S + 'S Q';
     1: S := S + 'f Q';
    Else S := S + 'B Q';
    End;
    WL(S);
    If O^.Kind = K_STAMP Then
     WL('q BT /' + FPre + '2 ' + IStr(O^.Size) + ' Tf ' + ColStr(O^.Rgb) + ' rg 1 0 0 1 ' + IStr(X1 + 6) + ' ' +
        RStr(H - Y1 - 4 - O^.Size * 4 / 5) + ' Tm ' + PdfStr(O^.Txt) + ' Tj ET Q');
   End;
   K_OVAL: Begin
    CX := (X1 + X2) / 2; CY := H - (Y1 + Y2) / 2;
    RX := (X2 - X1) / 2; RY := (Y2 - Y1) / 2;
    S := 'q ' + ColStr(FillTint(O^)) + ' rg ' + ColStr(O^.Rgb) + ' RG ' + IStr(O^.Wd) + ' w ' +
         RStr(CX + RX) + ' ' + RStr(CY) + ' m ' +
         RStr(CX + RX) + ' ' + RStr(CY + RY * 0.5523) + ' ' + RStr(CX + RX * 0.5523) + ' ' + RStr(CY + RY) + ' ' + RStr(CX) + ' ' + RStr(CY + RY) + ' c ' +
         RStr(CX - RX * 0.5523) + ' ' + RStr(CY + RY) + ' ' + RStr(CX - RX) + ' ' + RStr(CY + RY * 0.5523) + ' ' + RStr(CX - RX) + ' ' + RStr(CY) + ' c ';
    WS(S);
    S := RStr(CX - RX) + ' ' + RStr(CY - RY * 0.5523) + ' ' + RStr(CX - RX * 0.5523) + ' ' + RStr(CY - RY) + ' ' + RStr(CX) + ' ' + RStr(CY - RY) + ' c ' +
         RStr(CX + RX * 0.5523) + ' ' + RStr(CY - RY) + ' ' + RStr(CX + RX) + ' ' + RStr(CY - RY * 0.5523) + ' ' + RStr(CX + RX) + ' ' + RStr(CY) + ' c h ';
    Case O^.Fill Of
     0: S := S + 'S Q';
     1: S := S + 'f Q';
    Else S := S + 'B Q';
    End;
    WL(S);
   End;
   K_GRAD: Begin
    GradParse(O^);
    If GdNSt < 2 Then Continue;
    WS('q ');
    If O^.PN >= 3 Then Begin
     For J := 0 To O^.PN - 1 Do Begin
      If J = 0 Then Op := ' m ' Else Op := ' l ';
      WS(IStr(PoolXP(O^.P0 + J)^) + ' ' + IStr(H - PoolYP(O^.P0 + J)^) + Op);
      If (J Mod 8) = 7 Then WL('');
     End;
     WL('h W n');
    End
    Else WL(IStr(X1) + ' ' + IStr(H - Y2) + ' ' + IStr(X2 - X1) + ' ' + IStr(Y2 - Y1) + ' re W n');
    WriteGradBands(O^, X1, Y1, X2, Y2, H);
    WL('Q');
   End;
   K_POLY, K_INK: Begin
    If O^.PN < 2 Then Continue;
    WS('q ' + ColStr(FillTint(O^)) + ' rg ' + ColStr(O^.Rgb) + ' RG ' + IStr(O^.Wd) + ' w 1 J 1 j ');
    For J := 0 To O^.PN - 1 Do Begin
     If J = 0 Then Op := ' m ' Else Op := ' l ';
     WS(IStr(PoolXP(O^.P0 + J)^) + ' ' + IStr(H - PoolYP(O^.P0 + J)^) + Op);
     If (J Mod 8) = 7 Then WL('');
    End;
    If O^.Kind = K_INK Then WL('S Q')
    Else Begin
     If (O^.Style And 1) <> 0 Then WS('h ');
     Case O^.Fill Of
      0: WL('S Q');
      1: WL('f Q');
     Else WL('B Q');
     End;
    End;
   End;
  End;
 End;
End;

Function AnnotOf(Pg, I: Integer): String;
Var
 O: ^TObjRec;
 X1, Y1, X2, Y2, H: LongInt;
 S, Sub: String;
 YT, YB: String;
Begin
 O := @ObjP(I)^;
 H := PgP(Pg)^.H;
 NormBox(O^, X1, Y1, X2, Y2);
 YT := IStr(H - Y1);
 YB := IStr(H - Y2);
 Case O^.Kind Of
  K_HILITE: Sub := 'Highlight';
  K_UNDER: Sub := 'Underline';
  K_STRIKE: Sub := 'StrikeOut';
 Else Sub := 'Text';
 End;
 S := '<< /Type /Annot /Subtype /' + Sub + ' /Rect [' + IStr(X1) + ' ' + YB + ' ' + IStr(X2) + ' ' + YT + '] /F 4 /C [' +
      ColStr(O^.Rgb) + ']';
 If O^.Kind In [K_HILITE, K_UNDER, K_STRIKE] Then
  S := S + ' /QuadPoints [' + IStr(X1) + ' ' + YT + ' ' + IStr(X2) + ' ' + YT + ' ' + IStr(X1) + ' ' + YB + ' ' + IStr(X2) + ' ' + YB + ']'
 Else S := S + ' /Name /Note /Open false';
 If DocAuthor <> '' Then S := S + ' /T ' + PdfStr(DocAuthor);
 If O^.Txt <> '' Then S := S + ' /Contents ' + PdfStr(O^.Txt);
 AnnotOf := S + ' >>';
End;

Function IsAnnot(K: Integer): Boolean;
Begin
 IsAnnot := K In [K_HILITE, K_UNDER, K_STRIKE, K_NOTE];
End;

{ Écrit le XObject image Idx sous le numéro No (SMNo : masque doux ou 0) }
Procedure WriteImageXObj(Idx, No, SMNo: LongInt);
Var
 S, Hx: String;
 K, J2: LongInt;
Begin
 With ImgP(Idx)^ Do Begin
   BeginObj(No);
   S := '<< /Type /XObject /Subtype /Image /Width ' + IStr(OW) + ' /Height ' + IStr(OH);
   If Mask Then S := S + ' /ImageMask true /BitsPerComponent 1'
   Else Begin
    Case CS Of
     1: S := S + ' /ColorSpace /DeviceGray';
     3: S := S + ' /ColorSpace /DeviceRGB';
     4: S := S + ' /ColorSpace /DeviceCMYK';
    End;
    If CS = 5 Then Begin
     S := S + ' /ColorSpace [/Indexed ';
     Case PalBase Of
      1: S := S + '/DeviceGray ';
      4: S := S + '/DeviceCMYK ';
     Else S := S + '/DeviceRGB ';
     End;
     S := S + IStr(PalN Div PalBase - 1) + ' <';
     WS(S);
     S := '';
     For K := 0 To PalN - 1 Do Begin
      Hx := '0123456789ABCDEF';
      S := S + Hx[(PByteBuf(Pal)^[K] Shr 4) + 1] + Hx[(PByteBuf(Pal)^[K] And 15) + 1];
      If Length(S) > 200 Then Begin WS(S); S := ''; End;
     End;
     S := S + '>]';
    End;
    S := S + ' /BitsPerComponent ' + IStr(BPC);
   End;
   If Decode <> '' Then S := S + ' /Decode [' + Decode + ']';
   If NF > 0 Then Begin
    S := S + ' /Filter [';
    For K := 0 To NF - 1 Do S := S + '/' + Flt[K] + ' ';
    S := S + ']';
    S := S + ' /DecodeParms [';
    For K := 0 To NF - 1 Do
     If (Flt[K] = 'FlateDecode') And (Pred > 1) Then
      S := S + '<< /Predictor ' + IStr(Pred) + ' /Columns ' + IStr(Cols) + ' /Colors ' + IStr(Clr) + ' /BitsPerComponent ' + IStr(BPC) + ' >> '
     Else S := S + 'null ';
    S := S + ']';
   End;
   If SMNo > 0 Then S := S + ' /SMask ' + IStr(SMNo) + ' 0 R';
   WL(S + ' /Length ' + IStr(RawLen) + ' >>');
   WL('stream');
   J2 := 0;
   While (J2 < RawLen) And (Not OutErr) Do Begin
    K := RawLen - J2;
    If K > 16384 Then K := 16384;
    {$I-}
    BlockWrite(OutF, PByteBuf(Raw)^[J2], K);
    {$I+}
    If IOResult <> 0 Then OutErr := True;
    OutPos := OutPos + K;
    Inc(J2, K);
   End;
   WL('');
   WL('endstream');
   EndObj;
  End;
End;

Const
 FontNames: Array[0..11] Of String[24] = ('Helvetica', 'Helvetica-Bold', 'Helvetica-Oblique',
  'Helvetica-BoldOblique', 'Times-Roman', 'Times-Bold', 'Times-Italic', 'Times-BoldItalic',
  'Courier', 'Courier-Bold', 'Courier-Oblique', 'Courier-BoldOblique');

Procedure WriteFontObjs(Base: Integer);
Var
 I: Integer;
Begin
 For I := 0 To 11 Do Begin
  BeginObj(Base + I);
  WL('<< /Type /Font /Subtype /Type1 /BaseFont /' + FontNames[I] + ' /Encoding /WinAnsiEncoding >>');
  EndObj;
 End;
End;

Function SaveAsPDF(Const FileName: String): Boolean;
Var
 I, J, Pg, NObj, FirstPage, AnnBase, AnnNext, NAnn: Integer;
 StartLen, Cnt: LongInt;
 S: String;
 XStart: LongInt;
 PagesOff: Integer;
 HasAnn: Boolean;
 ImgNo: PLArr;
 Used: Array[0..19] Of Integer;
 NUsed: Integer;
 K, J2: LongInt;
 Hx: String;
 Comp: PByteBuf;
 CompLen: LongInt;
Begin
 SaveAsPDF := False;
 OutErr := False;
 OutPos := 0;
 IncMode := False; CMode := 0; CDropN := 0; FPre := 'F'; IPre := 'Im';
 NAnn := 0;
 For I := 0 To ObjCount - 1 Do If IsAnnot(ObjP(I)^.Kind) Then Inc(NAnn);
 FirstPage := 16;
 AnnBase := FirstPage + PageCount * 3;
 NObj := AnnBase + NAnn;
 GetMem(ImgNo, (ImgCount + 2) * SizeOf(LongInt));
 FillChar(ImgNo^, (ImgCount + 2) * SizeOf(LongInt), 0);
 FillChar(Used, SizeOf(Used), 0);
 For I := 0 To ObjCount - 1 Do
  If (ObjP(I)^.Kind = K_IMAGE) And ImgKept(ObjP(I)^.P0) Then Begin
   ImgNo^[ObjP(I)^.P0] := 1;
   If ImgP(ObjP(I)^.P0)^.SMIdx > 0 Then ImgNo^[ImgP(ObjP(I)^.P0)^.SMIdx] := 1;
  End;
 For I := 1 To ImgCount Do
  If ImgNo^[I] <> 0 Then Begin ImgNo^[I] := NObj; Inc(NObj); End;
 GetMem(XRef, (NObj + 2) * SizeOf(LongInt));
 FillChar(XRef^, (NObj + 2) * SizeOf(LongInt), 0);
 {$I-}
 Assign(OutF, FileName);
 Rewrite(OutF, 1);
 {$I+}
 If IOResult <> 0 Then Begin
  FreeMem(XRef, (NObj + 2) * SizeOf(LongInt));
  FreeMem(ImgNo, (ImgCount + 2) * SizeOf(LongInt));
  Exit;
 End;
 WL('%PDF-1.4');
 WL('%' + #226#227#207#211);
 BeginObj(1);
 WL('<< /Type /Catalog /Pages 2 0 R >>');
 EndObj;
 BeginObj(2);
 S := '<< /Type /Pages /Count ' + IStr(PageCount) + ' /Kids [';
 WS(S);
 For Pg := 1 To PageCount Do WS(IStr(FirstPage + (Pg - 1) * 3) + ' 0 R ');
 WL('] >>');
 EndObj;
 BeginObj(3);
 S := '<< /Producer (CloneDRAW Acrodoc) /CreationDate (' + PdfDate + ')';
 If DocTitle <> '' Then S := S + ' /Title ' + PdfStr(DocTitle);
 If DocAuthor <> '' Then S := S + ' /Author ' + PdfStr(DocAuthor);
 If DocSubject <> '' Then S := S + ' /Subject ' + PdfStr(DocSubject);
 If DocKeywords <> '' Then S := S + ' /Keywords ' + PdfStr(DocKeywords);
 If DocCreator <> '' Then S := S + ' /Creator ' + PdfStr(DocCreator);
 WL(S + ' >>');
 EndObj;
 WriteFontObjs(4);
 AnnNext := AnnBase;
 For Pg := 1 To PageCount Do Begin
  BeginObj(FirstPage + (Pg - 1) * 3);
  S := '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ' + IStr(PgP(Pg)^.W) + ' ' + IStr(PgP(Pg)^.H) + ']';
  If PgP(Pg)^.Rot <> 0 Then S := S + ' /Rotate ' + IStr((PgP(Pg)^.Rot And 3) * 90);
  S := S + ' /Resources << /Font <<';
  For I := 0 To 11 Do S := S + ' /F' + IStr(I + 1) + ' ' + IStr(4 + I) + ' 0 R';
  S := S + ' >>';
  NUsed := 0;
  For I := 0 To ObjCount - 1 Do
   If (ObjP(I)^.Page = Pg) And (ObjP(I)^.Kind = K_IMAGE) And ImgKept(ObjP(I)^.P0) And (NUsed < 20) Then Begin
    K := 0;
    For J2 := 0 To NUsed - 1 Do If Used[J2] = ObjP(I)^.P0 Then K := 1;
    If K = 0 Then Begin Used[NUsed] := ObjP(I)^.P0; Inc(NUsed); End;
   End;
  If NUsed > 0 Then Begin
   WS(S);
   S := ' /XObject <<';
   For J2 := 0 To NUsed - 1 Do Begin
    S := S + ' /Im' + IStr(Used[J2]) + ' ' + IStr(ImgNo^[Used[J2]]) + ' 0 R';
    If Length(S) > 200 Then Begin WS(S); S := ''; End;
   End;
   S := S + ' >>';
  End;
  S := S + ' >> /Contents ' + IStr(FirstPage + (Pg - 1) * 3 + 1) + ' 0 R';
  WS(S);
  HasAnn := False;
  For I := 0 To ObjCount - 1 Do
   If (ObjP(I)^.Page = Pg) And IsAnnot(ObjP(I)^.Kind) Then Begin
    If Not HasAnn Then Begin WS(' /Annots ['); HasAnn := True; End;
    WS(IStr(AnnNext) + ' 0 R ');
    Inc(AnnNext);
   End;
  If HasAnn Then WS(']');
  WL(' >>');
  EndObj;
  BeginObj(FirstPage + (Pg - 1) * 3 + 1);
  { le contenu est d'abord mis en tampon pour être compressé }
  CapLen := 0;
  If CapBuf = Nil Then Begin CapSize := 65536; GetMem(CapBuf, CapSize); End;
  CapOn := True;
  Cnt := 0;
  ContentOf(Pg, Cnt);
  CapOn := False;
  Comp := Nil; CompLen := 0;
  {$IFDEF FPC}
  If CapLen > 64 Then
   If DeflateBuf(CapBuf, CapLen, Comp, CompLen) Then
    If CompLen >= CapLen Then Begin FreeMem(Comp, CapLen + CapLen Div 6 + 128); Comp := Nil; End;
  {$ENDIF}
  If Comp <> Nil Then Begin
   WL('<< /Length ' + IStr(FirstPage + (Pg - 1) * 3 + 2) + ' 0 R /Filter /FlateDecode >>');
   WL('stream');
   WriteBytes(Comp, CompLen);
   Cnt := CompLen;
   FreeMem(Comp, CapLen + CapLen Div 6 + 128);
  End
  Else Begin
   WL('<< /Length ' + IStr(FirstPage + (Pg - 1) * 3 + 2) + ' 0 R >>');
   WL('stream');
   WriteBytes(CapBuf, CapLen);
   Cnt := CapLen;
  End;
  WL('');
  WL('endstream');
  EndObj;
  BeginObj(FirstPage + (Pg - 1) * 3 + 2);
  WL(IStr(Cnt));
  EndObj;
 End;
 AnnNext := AnnBase;
 For Pg := 1 To PageCount Do
  For I := 0 To ObjCount - 1 Do
   If (ObjP(I)^.Page = Pg) And IsAnnot(ObjP(I)^.Kind) Then Begin
    BeginObj(AnnNext);
    WL(AnnotOf(Pg, I));
    EndObj;
    Inc(AnnNext);
   End;
 For I := 1 To ImgCount Do
  If ImgNo^[I] <> 0 Then Begin
   If (ImgP(I)^.SMIdx > 0) And (ImgNo^[ImgP(I)^.SMIdx] <> 0) Then WriteImageXObj(I, ImgNo^[I], ImgNo^[ImgP(I)^.SMIdx])
   Else WriteImageXObj(I, ImgNo^[I], 0);
  End;
 XStart := OutPos;
 WL('xref');
 WL('0 ' + IStr(NObj));
 WL('0000000000 65535 f ');
 For I := 1 To NObj - 1 Do Begin
  S := IStr(XRef^[I]);
  While Length(S) < 10 Do S := '0' + S;
  WL(S + ' 00000 n ');
 End;
 WL('trailer');
 WL('<< /Size ' + IStr(NObj) + ' /Root 1 0 R /Info 3 0 R >>');
 WL('startxref');
 WL(IStr(XStart));
 WL('%%EOF');
 {$I-}
 Close(OutF);
 {$I+}
 If IOResult <> 0 Then OutErr := True;
 FreeMem(XRef, (NObj + 2) * SizeOf(LongInt));
 FreeMem(ImgNo, (ImgCount + 2) * SizeOf(LongInt));
 If CapBuf <> Nil Then Begin FreeMem(CapBuf, CapSize); CapBuf := Nil; End;
 SaveAsPDF := Not OutErr;
End;

{ ---------------------------------------------------------------------- }
{ Import PDF : couche de lecture                                           }
{ ---------------------------------------------------------------------- }

Const
 T_EOF = 0; T_NUM = 1; T_NAME = 2; T_STR = 3; T_OP = 4;
 T_AB = 5; T_AE = 6; T_DB = 7; T_DE = 8;

Var
 PF: File;
 PFSize: LongInt;
 RBuf: Array[0..4095] Of Byte;
 RBase: LongInt;
 RLen: Integer;
 SrcMode: Integer;       { 0 fichier, 1 flux d'objets, 2 contenu, 3 ToUnicode }
 StmBuf, CBuf, TuBuf, RawBuf, Buf2: PByteBuf;
 StmLen, CLen, TuLen: LongInt;
 StmCacheNum: Integer;
 CBufs: Array[0..3] Of PByteBuf;
 TokS: String;
 StrBuf: Array[0..1023] Of Byte;
 StrLen: Integer;
 DecCap: LongInt;
 TokR: Real;
 TokInt: Boolean;
 ObjPos: PLArr;
 ObjStmNo, ObjStmOff: PWArr;
 PdfCap: LongInt;
 MaxObjNum: Integer;
 RootNum, InfoNum: Integer;
 PdfBuffersReady: Boolean;
 ImgByObj: PWArr;

Function SB(Pos: LongInt): Integer;
Var
 RW: Word;
Begin
 Case SrcMode Of
  0: Begin
   If (Pos < 0) Or (Pos >= PFSize) Then Begin SB := -1; Exit; End;
   If (Pos < RBase) Or (Pos >= RBase + RLen) Then Begin
    RBase := Pos - (Pos Mod 4096);
    Seek(PF, RBase);
    RW := 0;
    BlockRead(PF, RBuf, 4096, RW);
    RLen := RW;
    If Pos >= RBase + RLen Then Begin SB := -1; Exit; End;
   End;
   SB := RBuf[Pos - RBase];
  End;
  1: If (Pos < 0) Or (Pos >= StmLen) Then SB := -1 Else SB := StmBuf^[Pos];
  2: If (Pos < 0) Or (Pos >= CLen) Then SB := -1 Else SB := CBuf^[Pos];
 Else
  If (Pos < 0) Or (Pos >= TuLen) Then SB := -1 Else SB := TuBuf^[Pos];
 End;
End;

Function IsWs(C: Integer): Boolean;
Begin
 IsWs := (C = 32) Or (C = 10) Or (C = 13) Or (C = 9) Or (C = 0) Or (C = 12);
End;

Function IsDelim(C: Integer): Boolean;
Begin
 IsDelim := (C = 40) Or (C = 41) Or (C = 60) Or (C = 62) Or (C = 91) Or (C = 93) Or
            (C = 123) Or (C = 125) Or (C = 47) Or (C = 37);
End;

Function HexVal(C: Integer): Integer;
Begin
 If (C >= 48) And (C <= 57) Then HexVal := C - 48
 Else If (C >= 65) And (C <= 70) Then HexVal := C - 55
 Else If (C >= 97) And (C <= 102) Then HexVal := C - 87
 Else HexVal := -1;
End;

Function NextTok(Var P: LongInt): Integer;
Var
 C, C2, Depth, V, H, N: Integer;
 Neg, Dot: Boolean;
 Scale: Real;
 Digits: Integer;
Begin
 TokS := '';
 NextTok := T_EOF;
 Repeat
  C := SB(P);
  If C = 37 Then Begin
   While (C <> -1) And (C <> 10) And (C <> 13) Do Begin Inc(P); C := SB(P); End;
  End;
  If IsWs(C) Then Inc(P);
 Until Not (IsWs(C) Or (C = 37));
 If C = -1 Then Exit;
 Case C Of
  47: Begin
   Inc(P);
   NextTok := T_NAME;
   While True Do Begin
    C := SB(P);
    If (C = -1) Or IsWs(C) Or IsDelim(C) Then Break;
    If (C = 35) And (HexVal(SB(P + 1)) >= 0) And (HexVal(SB(P + 2)) >= 0) Then Begin
     C := HexVal(SB(P + 1)) * 16 + HexVal(SB(P + 2));
     Inc(P, 2);
    End;
    If Length(TokS) < 255 Then TokS := TokS + Chr(C);
    Inc(P);
   End;
  End;
  40: Begin
   Inc(P);
   NextTok := T_STR;
   StrLen := 0;
   Depth := 1;
   While True Do Begin
    C := SB(P);
    If C = -1 Then Break;
    Inc(P);
    If C = 92 Then Begin
     C2 := SB(P);
     Inc(P);
     Case C2 Of
      110: C := 10; 114: C := 13; 116: C := 9; 98: C := 8; 102: C := 12;
      40, 41, 92: C := C2;
      13: Begin
       If SB(P) = 10 Then Inc(P);
       C := -2;
      End;
      10: C := -2;
      48..55: Begin
       V := C2 - 48;
       C2 := SB(P);
       If (C2 >= 48) And (C2 <= 55) Then Begin
        V := V * 8 + C2 - 48; Inc(P);
        C2 := SB(P);
        If (C2 >= 48) And (C2 <= 55) Then Begin V := V * 8 + C2 - 48; Inc(P); End;
       End;
       C := V And 255;
      End;
     Else C := C2;
     End;
    End
    Else If C = 40 Then Inc(Depth)
    Else If C = 41 Then Begin
     Dec(Depth);
     If Depth = 0 Then Break;
    End;
    If C >= 0 Then Begin
     If Length(TokS) < 255 Then TokS := TokS + Chr(C);
     If StrLen < 1024 Then Begin StrBuf[StrLen] := C; Inc(StrLen); End;
    End;
   End;
  End;
  60: Begin
   If SB(P + 1) = 60 Then Begin
    Inc(P, 2);
    NextTok := T_DB;
   End
   Else Begin
    Inc(P);
    NextTok := T_STR;
    StrLen := 0;
    H := -1;
    While True Do Begin
     C := SB(P);
     If C = -1 Then Break;
     Inc(P);
     If C = 62 Then Break;
     V := HexVal(C);
     If V < 0 Then Continue;
     If H < 0 Then H := V
     Else Begin
      If Length(TokS) < 255 Then TokS := TokS + Chr(H * 16 + V);
      If StrLen < 1024 Then Begin StrBuf[StrLen] := H * 16 + V; Inc(StrLen); End;
      H := -1;
     End;
    End;
    If H >= 0 Then If Length(TokS) < 255 Then TokS := TokS + Chr(H * 16);
   End;
  End;
  62: Begin
   If SB(P + 1) = 62 Then Begin
    Inc(P, 2);
    NextTok := T_DE;
   End
   Else Begin
    Inc(P);
    NextTok := NextTok(P);
   End;
  End;
  91: Begin Inc(P); NextTok := T_AB; End;
  93: Begin Inc(P); NextTok := T_AE; End;
  123, 125: Begin Inc(P); NextTok := T_OP; TokS := Chr(C); End;
  41: Begin Inc(P); NextTok := NextTok(P); End;
  43, 45, 46, 48..57: Begin
   Neg := False; Dot := False; TokR := 0; Scale := 1; Digits := 0;
   While (C = 43) Or (C = 45) Do Begin
    If C = 45 Then Neg := True;
    Inc(P); C := SB(P);
   End;
   While True Do Begin
    If (C >= 48) And (C <= 57) Then Begin
     If Dot Then Begin
      Scale := Scale / 10;
      TokR := TokR + (C - 48) * Scale;
     End
     Else TokR := TokR * 10 + (C - 48);
     Inc(Digits);
    End
    Else If (C = 46) And (Not Dot) Then Dot := True
    Else If C = 45 Then { signe parasite dans le nombre : ignorer }
    Else Break;
    Inc(P);
    C := SB(P);
   End;
   If Neg Then TokR := -TokR;
   TokInt := Not Dot;
   NextTok := T_NUM;
   If Digits = 0 Then Begin TokR := 0; End;
  End;
 Else
  NextTok := T_OP;
  While True Do Begin
   C := SB(P);
   If (C = -1) Or IsWs(C) Or IsDelim(C) Then Break;
   If Length(TokS) < 255 Then TokS := TokS + Chr(C);
   Inc(P);
  End;
  If TokS = '' Then Begin Inc(P); End;
 End;
End;

Procedure SkipValue(Var P: LongInt);
Var
 T: Integer;
 Q, Q2: LongInt;
Begin
 T := NextTok(P);
 Case T Of
  T_AB: Begin
   While True Do Begin
    Q := P;
    T := NextTok(P);
    If (T = T_AE) Or (T = T_EOF) Then Break;
    P := Q;
    SkipValue(P);
   End;
  End;
  T_DB: Begin
   While True Do Begin
    T := NextTok(P);
    If (T = T_DE) Or (T = T_EOF) Then Break;
    If T = T_NAME Then SkipValue(P);
   End;
  End;
  T_NUM: Begin
   If TokInt Then Begin
    Q := P;
    If NextTok(Q) = T_NUM Then
     If TokInt Then Begin
      Q2 := Q;
      If NextTok(Q2) = T_OP Then
       If TokS = 'R' Then P := Q2;
     End;
   End;
  End;
 End;
End;

{ P pointe sur '<<'. Retourne la position de la valeur de la clé, ou -1. }
Function DictFind(P: LongInt; Const Key: String): LongInt;
Var
 T: Integer;
Begin
 DictFind := -1;
 If NextTok(P) <> T_DB Then Exit;
 While True Do Begin
  T := NextTok(P);
  If (T = T_DE) Or (T = T_EOF) Then Exit;
  If T = T_NAME Then Begin
   If TokS = Key Then Begin
    DictFind := P;
    Exit;
   End;
   SkipValue(P);
  End;
 End;
End;

{ Y a-t-il une référence "N G R" en P ? }
Function RefAt(P: LongInt): Integer;
Var
 N: LongInt;
Begin
 RefAt := 0;
 If NextTok(P) <> T_NUM Then Exit;
 If Not TokInt Then Exit;
 If (TokR < 1) Or (TokR > MAXPDFOBJ) Then Exit;
 N := Round(TokR);
 If NextTok(P) <> T_NUM Then Exit;
 If NextTok(P) <> T_OP Then Exit;
 If TokS = 'R' Then RefAt := N;
End;

Type
 TSrcState = Record
  Mode, Stm: Integer;
 End;

Function LoadObjStm(N: Integer): Boolean; Forward;
Function EnterObj(Num: Integer): LongInt; Forward;

Procedure SaveSrc(Var S: TSrcState);
Begin
 S.Mode := SrcMode;
 S.Stm := StmCacheNum;
End;

Procedure RestoreSrc(Const S: TSrcState);
Begin
 If S.Mode = 1 Then Begin
  If StmCacheNum <> S.Stm Then LoadObjStm(S.Stm);
  SrcMode := 1;
 End
 Else SrcMode := S.Mode;
End;

{ Valeur numérique en P (suit les références indirectes) }
Function ValNum(P: LongInt; Def: Real): Real;
Var
 N: Integer;
 S: TSrcState;
 Q: LongInt;
 R: Real;
Begin
 ValNum := Def;
 If P < 0 Then Exit;
 N := RefAt(P);
 If N > 0 Then Begin
  SaveSrc(S);
  Q := EnterObj(N);
  If Q >= 0 Then Begin
   If NextTok(Q) = T_NUM Then R := TokR Else R := Def;
   ValNum := R;
  End;
  RestoreSrc(S);
 End
 Else If NextTok(P) = T_NUM Then ValNum := TokR;
End;

Function ValInt(P: LongInt; Def: LongInt): LongInt;
Var
 R: Real;
Begin
 R := ValNum(P, Def);
 If R > 2000000000.0 Then R := 2000000000.0;
 If R < -2000000000.0 Then R := -2000000000.0;
 ValInt := Round(R);
End;

Function ValName(P: LongInt): String;
Begin
 ValName := '';
 If P < 0 Then Exit;
 If NextTok(P) = T_NAME Then ValName := TokS;
End;

{ Lit n nombres d'un tableau à partir de P. Retourne le nombre lu. }
Function ReadNums(P: LongInt; Var A: Array Of Real; Max: Integer): Integer;
Var
 N: Integer;
 T: Integer;
 Q: LongInt;
Begin
 N := 0;
 ReadNums := 0;
 If P < 0 Then Exit;
 If NextTok(P) <> T_AB Then Exit;
 While N < Max Do Begin
  Q := P;
  T := NextTok(P);
  If T = T_NUM Then Begin
   A[N] := TokR;
   Inc(N);
   { ignorer une éventuelle référence "G R" }
   Q := P;
   If NextTok(Q) = T_NUM Then Begin
    If NextTok(Q) = T_OP Then
     If TokS = 'R' Then Begin Dec(N); P := Q; A[N] := 0; End;
   End;
  End
  Else If T = T_AE Then Break
  Else If T = T_EOF Then Break
  Else Begin P := Q; SkipValue(P); End;
 End;
 ReadNums := N;
End;

{ Décodage d'une chaîne de texte PDF (PDFDocEncoding / UTF-16BE) }
Function PdfText(Const S: String): String;
Var
 I: Integer;
 R: String;
Begin
 If (Length(S) >= 2) And (S[1] = #254) And (S[2] = #255) Then Begin
  R := '';
  I := 3;
  While I < Length(S) Do Begin
   If Ord(S[I]) = 0 Then R := R + S[I + 1]
   Else If (Ord(S[I]) = 32) And (Ord(S[I + 1]) = 19) Then R := R + '-'
   Else R := R + '?';
   Inc(I, 2);
  End;
  PdfText := R;
 End
 Else PdfText := S;
End;

{ ---------------------------------------------------------------------- }
{ Décompression : Flate, ASCIIHex, ASCII85                                  }
{ ---------------------------------------------------------------------- }

Type
 TInflTree = Record
  Counts: Array[0..15] Of Word;
  Syms: Array[0..287] Of Word;
 End;

Var
 IS_: PByteBuf;
 ISLen, ISPos: LongInt;
 ITag: LongInt;
 IBits: Integer;
 IDst: PByteBuf;
 IDLen, IDMax: LongInt;
 IErr: Boolean;
 LTree, DTree: TInflTree;


Function GetBit: Integer;
Begin
 If IBits = 0 Then Begin
  If ISPos >= ISLen Then Begin IErr := True; GetBit := 0; Exit; End;
  ITag := IS_^[ISPos];
  Inc(ISPos);
  IBits := 8;
 End;
 GetBit := ITag And 1;
 ITag := ITag Shr 1;
 Dec(IBits);
End;

Function GetBits(N: Integer): LongInt;
Var
 I: Integer;
 V: LongInt;
Begin
 V := 0;
 For I := 0 To N - 1 Do V := V Or (LongInt(GetBit) Shl I);
 GetBits := V;
End;

Procedure BuildTree(Var T: TInflTree; Const Lens: Array Of Byte; Off, Num: Integer);
Var
 I: Integer;
 Offs: Array[0..16] Of Word;
Begin
 For I := 0 To 15 Do T.Counts[I] := 0;
 For I := 0 To Num - 1 Do Inc(T.Counts[Lens[Off + I]]);
 T.Counts[0] := 0;
 Offs[1] := 0;
 For I := 1 To 15 Do Offs[I + 1] := Offs[I] + T.Counts[I];
 For I := 0 To Num - 1 Do
  If Lens[Off + I] <> 0 Then Begin
   T.Syms[Offs[Lens[Off + I]]] := I;
   Inc(Offs[Lens[Off + I]]);
  End;
End;

Function DecodeSym(Var T: TInflTree): Integer;
Var
 Sum, Cur, Len: LongInt;
Begin
 Sum := 0; Cur := 0; Len := 0;
 Repeat
  Cur := 2 * Cur + GetBit;
  Inc(Len);
  If Len > 15 Then Begin IErr := True; DecodeSym := 0; Exit; End;
  Sum := Sum + T.Counts[Len];
  Cur := Cur - T.Counts[Len];
 Until (Cur < 0) Or IErr;
 If Sum + Cur > 287 Then Begin IErr := True; DecodeSym := 0; Exit; End;
 DecodeSym := T.Syms[Sum + Cur];
End;

Procedure InflateCodes;
Var
 Sym, Len, Dist, I: Integer;
 Src: LongInt;
Begin
 While Not IErr Do Begin
  Sym := DecodeSym(LTree);
  If IErr Then Exit;
  If Sym < 256 Then Begin
   If IDLen >= IDMax Then Begin IErr := True; Exit; End;
   IDst^[IDLen] := Sym;
   Inc(IDLen);
  End
  Else If Sym = 256 Then Exit
  Else Begin
   Sym := Sym - 257;
   If Sym > 28 Then Begin IErr := True; Exit; End;
   Len := LBase[Sym] + GetBits(LExtra[Sym]);
   Dist := DecodeSym(DTree);
   If Dist > 29 Then Begin IErr := True; Exit; End;
   Dist := DBase[Dist] + GetBits(DExtra[Dist]);
   If Dist > IDLen Then Begin IErr := True; Exit; End;
   If IDLen + Len > IDMax Then Begin IErr := True; Exit; End;
   Src := IDLen - Dist;
   For I := 1 To Len Do Begin
    IDst^[IDLen] := IDst^[Src];
    Inc(IDLen);
    Inc(Src);
   End;
  End;
 End;
End;

Procedure FixedTrees;
Var
 L: Array[0..287] Of Byte;
 D: Array[0..29] Of Byte;
 I: Integer;
Begin
 For I := 0 To 143 Do L[I] := 8;
 For I := 144 To 255 Do L[I] := 9;
 For I := 256 To 279 Do L[I] := 7;
 For I := 280 To 287 Do L[I] := 8;
 For I := 0 To 29 Do D[I] := 5;
 BuildTree(LTree, L, 0, 288);
 BuildTree(DTree, D, 0, 30);
End;

Procedure DynamicTrees;
Var
 L: Array[0..319] Of Byte;
 CL: Array[0..18] Of Byte;
 CT: TInflTree;
 HLit, HDist, HCLen, I, Num, Sym, Prev, Rep: Integer;
Begin
 HLit := GetBits(5) + 257;
 HDist := GetBits(5) + 1;
 HCLen := GetBits(4) + 4;
 If (HLit > 286) Or (HDist > 30) Then Begin IErr := True; Exit; End;
 For I := 0 To 18 Do CL[I] := 0;
 For I := 0 To HCLen - 1 Do CL[CLOrder[I]] := GetBits(3);
 BuildTree(CT, CL, 0, 19);
 Num := 0;
 Prev := 0;
 While (Num < HLit + HDist) And (Not IErr) Do Begin
  Sym := DecodeSym(CT);
  If Sym < 16 Then Begin L[Num] := Sym; Prev := Sym; Inc(Num); End
  Else Begin
   If Sym = 16 Then Begin Rep := 3 + GetBits(2); End
   Else If Sym = 17 Then Begin Rep := 3 + GetBits(3); Prev := 0; End
   Else Begin Rep := 11 + GetBits(7); Prev := 0; End;
   If Num + Rep > HLit + HDist Then Begin IErr := True; Exit; End;
   While Rep > 0 Do Begin L[Num] := Prev; Inc(Num); Dec(Rep); End;
  End;
 End;
 If IErr Then Exit;
 BuildTree(LTree, L, 0, HLit);
 BuildTree(DTree, L, HLit, HDist);
End;

Function FlateDec(Src: PByteBuf; SLen: LongInt; Dst: PByteBuf; Var DLen: LongInt): Boolean;
Var
 Final, BType: Integer;
 Len, NLen, I: LongInt;
Begin
 IS_ := Src; ISLen := SLen; ISPos := 0; ITag := 0; IBits := 0;
 IDst := Dst; IDLen := 0; IDMax := DecCap; IErr := False;
 If SLen < 2 Then Begin DLen := 0; FlateDec := False; Exit; End;
 If (Src^[0] And 15) = 8 Then ISPos := 2;
 Repeat
  Final := GetBit;
  BType := GetBits(2);
  If IErr Then Break;
  Case BType Of
   0: Begin
    IBits := 0;
    If ISPos + 4 > ISLen Then Begin IErr := True; Break; End;
    Len := Src^[ISPos] + Src^[ISPos + 1] * 256;
    NLen := Src^[ISPos + 2] + Src^[ISPos + 3] * 256;
    Inc(ISPos, 4);
    If Len <> (NLen Xor $FFFF) Then Begin IErr := True; Break; End;
    For I := 1 To Len Do Begin
     If (ISPos >= ISLen) Or (IDLen >= IDMax) Then Begin IErr := True; Break; End;
     Dst^[IDLen] := Src^[ISPos];
     Inc(IDLen); Inc(ISPos);
    End;
   End;
   1: Begin FixedTrees; InflateCodes; End;
   2: Begin DynamicTrees; If Not IErr Then InflateCodes; End;
  Else IErr := True;
  End;
 Until (Final = 1) Or IErr;
 DLen := IDLen;
 FlateDec := (Not IErr) Or (IDLen > 0);
End;

Function AHexDec(Src: PByteBuf; SLen: LongInt; Dst: PByteBuf; Var DLen: LongInt): Boolean;
Var
 I: LongInt;
 H, V: Integer;
Begin
 DLen := 0; H := -1;
 For I := 0 To SLen - 1 Do Begin
  If Src^[I] = 62 Then Break;
  V := HexVal(Src^[I]);
  If V < 0 Then Continue;
  If H < 0 Then H := V
  Else Begin
   If DLen < DecCap Then Begin Dst^[DLen] := H * 16 + V; Inc(DLen); End;
   H := -1;
  End;
 End;
 If (H >= 0) And (DLen < DecCap) Then Begin Dst^[DLen] := H * 16; Inc(DLen); End;
 AHexDec := True;
End;

Function A85Dec(Src: PByteBuf; SLen: LongInt; Dst: PByteBuf; Var DLen: LongInt): Boolean;
Var
 I: LongInt;
 Grp: Array[0..4] Of Integer;
 N, K: Integer;
 V: LongInt;
 C: Integer;
 Procedure Flush(Cnt: Integer);
 Var
  J: Integer;
  W: Real;
  Q: LongInt;
 Begin
  For J := Cnt To 4 Do Grp[J] := 84;
  W := 0;
  For J := 0 To 4 Do W := W * 85 + Grp[J];
  For J := 0 To Cnt - 2 Do Begin
   Q := Trunc(W / 16777216.0);
   If DLen < DecCap Then Begin Dst^[DLen] := Q And 255; Inc(DLen); End;
   W := W - Q * 16777216.0;
   W := W * 256;
  End;
 End;
Begin
 DLen := 0; N := 0;
 For I := 0 To SLen - 1 Do Begin
  C := Src^[I];
  If C = 126 Then Break;
  If IsWs(C) Then Continue;
  If C = 122 Then Begin
   For K := 1 To 4 Do If DLen < DecCap Then Begin Dst^[DLen] := 0; Inc(DLen); End;
   Continue;
  End;
  If (C < 33) Or (C > 117) Then Continue;
  Grp[N] := C - 33;
  Inc(N);
  If N = 5 Then Begin Flush(5); N := 0; End;
 End;
 If N > 1 Then Flush(N);
 A85Dec := True;
End;

{ ---------------------------------------------------------------------- }
{ Table d'objets                                                            }
{ ---------------------------------------------------------------------- }

Function AllocBuf: PByteBuf;
Var
 P: PByteBuf;
Begin
 GetMem(P, BUFSZ + 17);
 AllocBuf := P;
End;

{ Agrandit les tables d'objets PDF (tas) selon le plus grand numéro rencontré }
Procedure EnsurePdfCap(Need: LongInt);
Var
 NewCap, I: LongInt;
 P: Pointer;
Begin
 If Need < PdfCap Then Exit;
 NewCap := PdfCap * 2;
 If NewCap < Need + 1 Then NewCap := Need + 1;
 If NewCap < 4096 Then NewCap := 4096;
 P := ObjPos; ReAllocMem(P, NewCap * SizeOf(LongInt)); ObjPos := P;
 P := ObjStmNo; ReAllocMem(P, NewCap * SizeOf(Word)); ObjStmNo := P;
 P := ObjStmOff; ReAllocMem(P, NewCap * SizeOf(Word)); ObjStmOff := P;
 P := ImgByObj; ReAllocMem(P, NewCap * SizeOf(Word)); ImgByObj := P;
 For I := PdfCap To NewCap - 1 Do Begin
  ObjPos^[I] := -1; ObjStmNo^[I] := 0; ObjStmOff^[I] := 0; ImgByObj^[I] := 0;
 End;
 PdfCap := NewCap;
End;

Procedure InitPdfBuffers;
Var
 I: Integer;
Begin
 If PdfBuffersReady Then Exit;
 StmBuf := AllocBuf; TuBuf := AllocBuf; RawBuf := AllocBuf; Buf2 := AllocBuf;
 For I := 0 To 3 Do CBufs[I] := AllocBuf;
 PdfCap := 0;
 ObjPos := Nil; ObjStmNo := Nil; ObjStmOff := Nil; ImgByObj := Nil;
 EnsurePdfCap(4096);
 DecCap := BUFSZ;
 PdfBuffersReady := True;
End;

Function FindStreamData(Var DStart: LongInt; Var DLen: LongInt; LenVal: LongInt): Boolean;
Var
 P, Q: LongInt;
 C, K: Integer;
 Probe: LongInt;
Begin
 FindStreamData := False;
 P := DStart;
 { sauter l'EOL après le mot "stream" }
 If SB(P) = 13 Then Begin
  Inc(P);
  If SB(P) = 10 Then Inc(P);
 End
 Else If SB(P) = 10 Then Inc(P);
 DStart := P;
 If LenVal >= 0 Then Begin
  Probe := P + LenVal;
  Q := Probe;
  While IsWs(SB(Q)) And (Q < Probe + 4) Do Inc(Q);
  If (SB(Q) = 101) And (SB(Q + 1) = 110) And (SB(Q + 2) = 100) And (SB(Q + 3) = 115) Then Begin
   DLen := LenVal;
   FindStreamData := True;
   Exit;
  End;
 End;
 { Longueur douteuse : chercher "endstream" }
 Q := P;
 While True Do Begin
  C := SB(Q);
  If C = -1 Then Break;
  If (C = 101) And (SB(Q + 1) = 110) And (SB(Q + 2) = 100) And (SB(Q + 3) = 115) And
     (SB(Q + 4) = 116) And (SB(Q + 5) = 114) Then Begin
   K := 0;
   DLen := Q - P;
   If (DLen > 0) And (SB(P + DLen - 1) = 10) Then Dec(DLen);
   If (DLen > 0) And (SB(P + DLen - 1) = 13) Then Dec(DLen);
   FindStreamData := True;
   Exit;
  End;
  Inc(Q);
 End;
End;

{ Charge et décode le flux de l'objet Num dans Dst. }
Function LoadStream(Num: Integer; Dst: PByteBuf; Var OutLen: LongInt): Boolean;
Var
 P, DictP, V, Q, DStart, RawLen: LongInt;
 LenVal: LongInt;
 Filters: Array[0..3] Of String[24];
 NF, K, T: Integer;
 S: TSrcState;
 Cur, Nxt: PByteBuf;
 CurLen, NxtLen: LongInt;
 Got: Word;
 ToRead, Done: LongInt;
 Ok: Boolean;
Begin
 LoadStream := False;
 OutLen := 0;
 SaveSrc(S);
 P := EnterObj(Num);
 If (P < 0) Or (SrcMode <> 0) Then Begin RestoreSrc(S); Exit; End;
 DictP := P;
 NF := 0;
 V := DictFind(DictP, 'Filter');
 If V >= 0 Then Begin
  Q := V;
  T := NextTok(Q);
  If T = T_NAME Then Begin Filters[0] := TokS; NF := 1; End
  Else If T = T_AB Then Begin
   While NF < 4 Do Begin
    T := NextTok(Q);
    If T = T_NAME Then Begin Filters[NF] := TokS; Inc(NF); End Else Break;
   End;
  End;
 End;
 V := DictFind(DictP, 'Length');
 LenVal := -1;
 If V >= 0 Then LenVal := ValInt(V, -1);
 SrcMode := 0;
 { position après le dictionnaire }
 Q := DictP;
 SkipValue(Q);
 If NextTok(Q) <> T_OP Then Begin RestoreSrc(S); Exit; End;
 If TokS <> 'stream' Then Begin RestoreSrc(S); Exit; End;
 DStart := Q;
 If Not FindStreamData(DStart, RawLen, LenVal) Then Begin RestoreSrc(S); Exit; End;
 If RawLen > BUFSZ Then RawLen := BUFSZ;
 Seek(PF, DStart);
 Done := 0;
 While Done < RawLen Do Begin
  ToRead := RawLen - Done;
  If ToRead > 4096 Then ToRead := 4096;
  Got := 0;
  BlockRead(PF, RawBuf^[Done], ToRead, Got);
  If Got = 0 Then Break;
  Done := Done + Got;
 End;
 RBase := -1; RLen := 0;
 RawLen := Done;
 Cur := RawBuf; CurLen := RawLen;
 Ok := True;
 For K := 0 To NF - 1 Do Begin
  If K = NF - 1 Then Nxt := Dst
  Else If Cur = RawBuf Then Nxt := Buf2 Else Nxt := RawBuf;
  If (Filters[K] = 'FlateDecode') Or (Filters[K] = 'Fl') Then Ok := FlateDec(Cur, CurLen, Nxt, NxtLen)
  Else If (Filters[K] = 'ASCIIHexDecode') Or (Filters[K] = 'AHx') Then Ok := AHexDec(Cur, CurLen, Nxt, NxtLen)
  Else If (Filters[K] = 'ASCII85Decode') Or (Filters[K] = 'A85') Then Ok := A85Dec(Cur, CurLen, Nxt, NxtLen)
  Else Ok := False;
  If Not Ok Then Break;
  Cur := Nxt; CurLen := NxtLen;
 End;
 If Ok Then Begin
  If NF = 0 Then Move(RawBuf^, Dst^, CurLen);
  OutLen := CurLen;
  LoadStream := True;
 End;
 SrcMode := 0;
 RestoreSrc(S);
End;

Function LoadObjStm(N: Integer): Boolean;
Var
 L: LongInt;
Begin
 LoadObjStm := False;
 If StmCacheNum = N Then Begin SrcMode := 1; LoadObjStm := True; Exit; End;
 SrcMode := 0;
 StmCacheNum := 0;
 If LoadStream(N, StmBuf, L) Then Begin
  StmLen := L;
  StmCacheNum := N;
  SrcMode := 1;
  LoadObjStm := True;
 End;
End;

{ Entre dans l'objet Num : retourne la position du corps de l'objet. }
Function EnterObj(Num: Integer): LongInt;
Begin
 EnterObj := -1;
 If (Num <= 0) Or (Num > MaxObjNum) Or (Num >= PdfCap) Then Exit;
 If ObjPos^[Num] >= 0 Then Begin
  SrcMode := 0;
  EnterObj := ObjPos^[Num];
 End
 Else If ObjStmNo^[Num] <> 0 Then Begin
  If LoadObjStm(ObjStmNo^[Num]) Then EnterObj := ObjStmOff^[Num];
 End;
End;

Procedure ShowProgress(Const Msg: String); Forward;

{ ---------------------------------------------------------------------- }
{ Import PDF : analyse du fichier                                           }
{ ---------------------------------------------------------------------- }

Var
 XRefBest: Integer;
 XRefBestPos: LongInt;
 TrPos: Array[0..7] Of LongInt;
 TrCount: Integer;
 StmList: Array[0..255] Of Word;
 StmListN: Integer;

Function IsDigitC(C: Integer): Boolean;
Begin
 IsDigitC := (C >= 48) And (C <= 57);
End;

Procedure TryObjHeader(Q: LongInt);
Var
 C: Integer;
 P, E, S2, E2: LongInt;
 Num: LongInt;
 I: LongInt;
Begin
 If Q > 0 Then If Not IsWs(SB(Q - 1)) Then Exit;
 C := SB(Q + 3);
 If (C <> -1) And (Not IsWs(C)) And (Not IsDelim(C)) Then Exit;
 P := Q - 1;
 While (P > 0) And IsWs(SB(P)) Do Dec(P);
 E := P;
 While (P > 0) And IsDigitC(SB(P)) Do Dec(P);
 If P = E Then Exit;
 S2 := P;
 While (P > 0) And IsWs(SB(P)) Do Dec(P);
 If P = S2 Then Exit;
 E2 := P;
 While (P >= 0) And IsDigitC(SB(P)) Do Dec(P);
 If P = E2 Then Exit;
 If E2 - P > 7 Then Exit;
 C := SB(P);
 If (C <> -1) And (Not IsWs(C)) And (Not IsDelim(C)) Then Exit;
 Num := 0;
 For I := P + 1 To E2 Do Num := Num * 10 + (SB(I) - 48);
 If (Num < 1) Or (Num > MAXPDFOBJ) Then Exit;
 EnsurePdfCap(Num);
 ObjPos^[Num] := Q + 3;
 ObjStmNo^[Num] := 0;
 If Num > MaxObjNum Then MaxObjNum := Num;
End;

Procedure ScanFile;
Var
 Pos: LongInt;
 N, I: LongInt;
 Got: Word;
 Chunk: PByteBuf;
 Lim: LongInt;
 Eof: Boolean;
 Q: LongInt;
Begin
 Chunk := RawBuf;
 Pos := 0;
 TrCount := 0;
 SrcMode := 0;
 Repeat
  Seek(PF, Pos);
  Got := 0;
  BlockRead(PF, Chunk^, 60000, Got);
  N := Got;
  Eof := Pos + N >= PFSize;
  If Eof Then Lim := N - 3 Else Lim := N - 10;
  For I := 0 To Lim - 1 Do Begin
   If Chunk^[I] = 111 Then Begin
    If (Chunk^[I + 1] = 98) And (Chunk^[I + 2] = 106) Then Begin
     RBase := -1; RLen := 0;
     TryObjHeader(Pos + I);
    End;
   End
   Else If Chunk^[I] = 116 Then Begin
    If (Chunk^[I + 1] = 114) And (Chunk^[I + 2] = 97) And (Chunk^[I + 3] = 105) And
       (Chunk^[I + 4] = 108) And (Chunk^[I + 5] = 101) And (Chunk^[I + 6] = 114) Then
     Begin
      If TrCount >= 8 Then Begin
       For Q := 0 To 6 Do TrPos[Q] := TrPos[Q + 1];
       TrCount := 7;
      End;
      TrPos[TrCount] := Pos + I + 7;
      Inc(TrCount);
     End;
   End;
  End;
  If Eof Then Break;
  Pos := Pos + Lim;
 Until False;
 RBase := -1; RLen := 0;
End;

Procedure ProcessObjects;
Var
 N, I, K: Integer;
 P, V: LongInt;
 Nm: String;
 First, Cnt, L, Q: LongInt;
 ON, OO: LongInt;
Begin
 SrcMode := 0;
 StmListN := 0;
 XRefBest := 0; XRefBestPos := -1;
 For I := 0 To TrCount - 1 Do Begin
  V := DictFind(TrPos[I], 'Root');
  If V >= 0 Then Begin N := RefAt(V); If N > 0 Then RootNum := N; End;
  V := DictFind(TrPos[I], 'Info');
  If V >= 0 Then Begin N := RefAt(V); If N > 0 Then InfoNum := N; End;
  If DictFind(TrPos[I], 'Encrypt') >= 0 Then DocEncrypted := True;
 End;
 For N := 1 To MaxObjNum Do Begin
  If ObjPos^[N] < 0 Then Continue;
  P := ObjPos^[N];
  V := DictFind(P, 'Type');
  If V < 0 Then Continue;
  Nm := ValName(V);
  If Nm = 'Catalog' Then RootNum := N
  Else If Nm = 'XRef' Then Begin
   If ObjPos^[N] > XRefBestPos Then Begin XRefBestPos := ObjPos^[N]; XRefBest := N; End;
   V := DictFind(P, 'Root');
   If V >= 0 Then If RefAt(V) > 0 Then RootNum := RefAt(V);
   V := DictFind(P, 'Info');
   If V >= 0 Then If RefAt(V) > 0 Then InfoNum := RefAt(V);
   If DictFind(P, 'Encrypt') >= 0 Then DocEncrypted := True;
  End
  Else If Nm = 'ObjStm' Then Begin
   If StmListN < 256 Then Begin StmList[StmListN] := N; Inc(StmListN); End;
  End;
 End;
 For I := 0 To StmListN - 1 Do Begin
  N := StmList[I];
  SrcMode := 0;
  P := ObjPos^[N];
  First := ValInt(DictFind(P, 'First'), 0);
  Cnt := ValInt(DictFind(P, 'N'), 0);
  StmCacheNum := 0;
  If Not LoadStream(N, StmBuf, L) Then Continue;
  StmLen := L;
  StmCacheNum := N;
  SrcMode := 1;
  Q := 0;
  For K := 1 To Cnt Do Begin
   If NextTok(Q) <> T_NUM Then Break;
   ON := Round(TokR);
   If NextTok(Q) <> T_NUM Then Break;
   OO := Round(TokR);
   If (ON >= 1) And (ON <= MAXPDFOBJ) And (First + OO < 65000) Then Begin
    EnsurePdfCap(ON);
    If ObjPos^[ON] < 0 Then Begin
     ObjStmNo^[ON] := N;
     ObjStmOff^[ON] := First + OO;
     If ON > MaxObjNum Then MaxObjNum := ON;
    End;
   End;
  End;
 End;
 SrcMode := 0;
End;

{ ---------------------------------------------------------------------- }
{ Polices et ressources                                                      }
{ ---------------------------------------------------------------------- }

Const
 FMAX = 28;
 XMAX = 64;

Type
 TRange = Record
  Lo, Hi, Dst, Dst2: Word;
 End;
 TRangeArr = Array[0..299] Of TRange;
 PRangeArr = ^TRangeArr;
 TWdArr = Array[0..255] Of Integer;
 PWdArr = ^TWdArr;
 TT3 = Record
  Num: Integer;
  HasRes: Boolean;
  FM: Array[0..5] Of Real;
  Proc: Array[0..255] Of LongInt;
  Wd: Array[0..255] Of Real;
 End;
 PT3 = ^TT3;
 TFontRec = Record
  Name: String[63];
  Fam, Style: Integer;
  Wide, HasWd: Boolean;
  First: Integer;
  Wd: PWdArr;
  DW: Integer;
  CW: PRangeArr;
  NCW: Integer;
  TU: PRangeArr;
  NTU: Integer;
  T3: PT3;
 End;
 TXObj = Record
  Name: String[63];
  Num: Integer;
  IsForm: Boolean;
 End;

Var
 ResNodes: Array[0..7] Of Integer;
 NRes: Integer;
 Fonts: Array[0..FMAX-1] Of TFontRec;
 NFonts: Integer;
 XObjs: Array[0..XMAX-1] Of TXObj;
 NXObjs: Integer;

Procedure FreeFontsTo(Base: Integer);
Begin
 While NFonts > Base Do Begin
  Dec(NFonts);
  With Fonts[NFonts] Do Begin
   If Wd <> Nil Then FreeMem(Wd, SizeOf(TWdArr));
   If CW <> Nil Then FreeMem(CW, SizeOf(TRangeArr));
   If TU <> Nil Then FreeMem(TU, SizeOf(TRangeArr));
   If T3 <> Nil Then FreeMem(T3, SizeOf(TT3));
   Wd := Nil; CW := Nil; TU := Nil; T3 := Nil;
  End;
 End;
End;

Function W16(V: LongInt): Word;
Begin
 If V < 0 Then V := 0;
 If V > 65535 Then V := 65535;
 W16 := V;
End;

Procedure AddRange(Var Arr: PRangeArr; Var N: Integer; Lo, Hi, D1, D2: LongInt);
Begin
 If Arr = Nil Then GetMem(Arr, SizeOf(TRangeArr));
 If N >= 300 Then Exit;
 Arr^[N].Lo := W16(Lo); Arr^[N].Hi := W16(Hi); Arr^[N].Dst := W16(D1); Arr^[N].Dst2 := W16(D2);
 Inc(N);
End;

Function BEVal(Const S: String): LongInt;
Var
 I: Integer;
 V: LongInt;
Begin
 V := 0;
 For I := 1 To Length(S) Do Begin
  If I > 3 Then Break;
  V := V * 256 + Ord(S[I]);
 End;
 BEVal := V;
End;

Procedure ParseToUnicode(Var F: TFontRec);
Var
 P: LongInt;
 T, T2: Integer;
 Lo, Hi, D1, D2: LongInt;
 K: Integer;
 Procedure DstOf(Const S: String; Var A, B: LongInt);
 Begin
  A := 0; B := 0;
  If Length(S) >= 2 Then A := Ord(S[1]) * 256 + Ord(S[2])
  Else If Length(S) = 1 Then A := Ord(S[1]);
  If (Length(S) >= 4) And ((A < $D800) Or (A > $DBFF)) Then B := Ord(S[3]) * 256 + Ord(S[4]);
 End;
Begin
 SrcMode := 3;
 P := 0;
 While True Do Begin
  T := NextTok(P);
  If T = T_EOF Then Break;
  If T = T_OP Then Begin
   If TokS = 'beginbfchar' Then Begin
    While True Do Begin
     T := NextTok(P);
     If T <> T_STR Then Break;
     Lo := BEVal(TokS);
     T2 := NextTok(P);
     If T2 <> T_STR Then Break;
     DstOf(TokS, D1, D2);
     AddRange(F.TU, F.NTU, Lo, Lo, D1, D2);
    End;
   End
   Else If TokS = 'beginbfrange' Then Begin
    While True Do Begin
     T := NextTok(P);
     If T <> T_STR Then Break;
     Lo := BEVal(TokS);
     If NextTok(P) <> T_STR Then Break;
     Hi := BEVal(TokS);
     T2 := NextTok(P);
     If T2 = T_STR Then Begin
      DstOf(TokS, D1, D2);
      AddRange(F.TU, F.NTU, Lo, Hi, D1, D2);
     End
     Else If T2 = T_AB Then Begin
      K := 0;
      While True Do Begin
       T2 := NextTok(P);
       If T2 <> T_STR Then Break;
       DstOf(TokS, D1, D2);
       AddRange(F.TU, F.NTU, Lo + K, Lo + K, D1, D2);
       Inc(K);
      End;
     End
     Else Break;
    End;
   End;
  End;
 End;
End;

Procedure LoadCIDWidths(Var F: TFontRec; DescNum: Integer);
Var
 P, V, Q: LongInt;
 N: Integer;
 T: Integer;
 C1, C2: LongInt;
 W: LongInt;
 K: Integer;
Begin
 P := EnterObj(DescNum);
 If P < 0 Then Exit;
 F.DW := ValInt(DictFind(P, 'DW'), 1000);
 V := DictFind(P, 'W');
 If V < 0 Then Exit;
 N := RefAt(V);
 If N > 0 Then Begin
  V := EnterObj(N);
  If V < 0 Then Exit;
 End;
 Q := V;
 If NextTok(Q) <> T_AB Then Exit;
 While True Do Begin
  T := NextTok(Q);
  If T <> T_NUM Then Break;
  C1 := Round(TokR);
  T := NextTok(Q);
  If T = T_AB Then Begin
   K := 0;
   While True Do Begin
    T := NextTok(Q);
    If T <> T_NUM Then Break;
    AddRange(F.CW, F.NCW, C1 + K, C1 + K, Round(TokR), 0);
    Inc(K);
   End;
  End
  Else If T = T_NUM Then Begin
   C2 := Round(TokR);
   If NextTok(Q) <> T_NUM Then Break;
   W := Round(TokR);
   AddRange(F.CW, F.NCW, C1, C2, W, 0);
  End
  Else Break;
 End;
End;

{ Police Type 3 : procédures de dessin des glyphes (CharProcs) }
Procedure LoadType3(Var F: TFontRec; Num: Integer);
Var
 S: TSrcState;
 T3: PT3;
 P, V, Q, E, D: LongInt;
 Arr: Array[0..255] Of Real;
 I, N, First, Cnt, T, Code, NPairs: Integer;
 PCode: Array[0..255] Of Integer;
 PName: Array[0..255] Of String[31];
Begin
 GetMem(T3, SizeOf(TT3));
 FillChar(T3^, SizeOf(TT3), 0);
 T3^.Num := Num;
 T3^.FM[0] := 0.001; T3^.FM[3] := 0.001;
 SaveSrc(S);
 SrcMode := 0;
 P := EnterObj(Num);
 If P < 0 Then Begin FreeMem(T3, SizeOf(TT3)); RestoreSrc(S); Exit; End;
 T3^.HasRes := DictFind(P, 'Resources') >= 0;
 V := DictFind(P, 'FontMatrix');
 If V >= 0 Then If ReadNums(V, Arr, 6) = 6 Then
  For I := 0 To 5 Do T3^.FM[I] := Arr[I];
 First := ValInt(DictFind(P, 'FirstChar'), 0);
 V := DictFind(P, 'Widths');
 If V >= 0 Then Begin
  N := RefAt(V);
  If N > 0 Then V := EnterObj(N);
  If V >= 0 Then Begin
   Cnt := ReadNums(V, Arr, 256);
   For I := 0 To Cnt - 1 Do
    If (First + I >= 0) And (First + I <= 255) Then T3^.Wd[First + I] := Arr[I];
  End;
  RestoreSrc(S);
  P := EnterObj(Num);
 End;
 NPairs := 0;
 V := DictFind(P, 'Encoding');
 If V >= 0 Then Begin
  N := RefAt(V);
  If N > 0 Then V := EnterObj(N);
  If V >= 0 Then Begin
   D := DictFind(V, 'Differences');
   If D >= 0 Then Begin
    N := RefAt(D);
    If N > 0 Then D := EnterObj(N);
    If D >= 0 Then Begin
     Q := D;
     If NextTok(Q) = T_AB Then Begin
      Code := 0;
      While NPairs < 256 Do Begin
       T := NextTok(Q);
       If (T = T_AE) Or (T = T_EOF) Then Break;
       If T = T_NUM Then Code := Round(TokR)
       Else If T = T_NAME Then Begin
        If (Code >= 0) And (Code <= 255) Then Begin
         PCode[NPairs] := Code;
         PName[NPairs] := TokS;
         Inc(NPairs);
        End;
        Inc(Code);
       End;
      End;
     End;
    End;
   End;
  End;
 End;
 RestoreSrc(S);
 For I := 0 To NPairs - 1 Do Begin
  SrcMode := 0;
  P := EnterObj(Num);
  If P < 0 Then Break;
  V := DictFind(P, 'CharProcs');
  If V < 0 Then Break;
  N := RefAt(V);
  If N > 0 Then V := EnterObj(N);
  If V < 0 Then Break;
  E := DictFind(V, PName[I]);
  If E >= 0 Then T3^.Proc[PCode[I]] := RefAt(E);
 End;
 RestoreSrc(S);
 F.T3 := T3;
End;

Procedure LoadFont(Const Name: String; Num: Integer);
Var
 S: TSrcState;
 P, V, Q: LongInt;
 Sub, Base, LB: String;
 DescNum, TuNum, N, I, Cnt: Integer;
 Arr: Array[0..255] Of Real;
 TL: LongInt;
 F: ^TFontRec;
Begin
 If NFonts >= FMAX Then Exit;
 SaveSrc(S);
 P := EnterObj(Num);
 If P >= 0 Then Begin
  F := @Fonts[NFonts];
  FillChar(F^, SizeOf(TFontRec), 0);
  F^.Name := Name;
  F^.DW := 1000;
  Sub := ValName(DictFind(P, 'Subtype'));
  Base := ValName(DictFind(P, 'BaseFont'));
  If Sub = 'Type3' Then Begin
   RestoreSrc(S);
   LoadType3(F^, Num);
   Inc(NFonts);
   Exit;
  End;
  LB := Base;
  For I := 1 To Length(LB) Do If (LB[I] >= 'A') And (LB[I] <= 'Z') Then LB[I] := Chr(Ord(LB[I]) + 32);
  If (Length(LB) > 7) And (LB[7] = '+') Then Delete(LB, 1, 7);
  F^.Fam := 0; F^.Style := 0;
  If (Pos('courier', LB) > 0) Or (Pos('mono', LB) > 0) Or (Pos('consol', LB) > 0) Then F^.Fam := 2
  Else If (Pos('times', LB) > 0) Or (Pos('serif', LB) > 0) And (Pos('sans', LB) = 0) Or (Pos('roman', LB) > 0) Or
          (Pos('georgia', LB) > 0) Or (Pos('cambria', LB) > 0) Or (Pos('garamond', LB) > 0) Or
          (Pos('minion', LB) > 0) Or (Pos('palatino', LB) > 0) Then F^.Fam := 1;
  If (Pos('bold', LB) > 0) Or (Pos('black', LB) > 0) Or (Pos('heavy', LB) > 0) Or (Pos('semibold', LB) > 0) Then F^.Style := F^.Style Or 1;
  If (Pos('italic', LB) > 0) Or (Pos('oblique', LB) > 0) Then F^.Style := F^.Style Or 2;
  DescNum := 0;
  TuNum := RefAt(DictFind(P, 'ToUnicode'));
  If Sub = 'Type0' Then Begin
   F^.Wide := True;
   V := DictFind(P, 'DescendantFonts');
   If V >= 0 Then Begin
    N := RefAt(V);
    If N > 0 Then V := EnterObj(N);
    If V >= 0 Then Begin
     Q := V;
     If NextTok(Q) = T_AB Then DescNum := RefAt(Q);
    End;
   End;
  End
  Else Begin
   F^.First := ValInt(DictFind(P, 'FirstChar'), 0);
   V := DictFind(P, 'Widths');
   If V >= 0 Then Begin
    N := RefAt(V);
    If N > 0 Then V := EnterObj(N);
    If V >= 0 Then Begin
     Cnt := ReadNums(V, Arr, 256);
     If Cnt > 0 Then Begin
      GetMem(F^.Wd, SizeOf(TWdArr));
      FillChar(F^.Wd^, SizeOf(TWdArr), 0);
      For I := 0 To Cnt - 1 Do F^.Wd^[I] := Round(Arr[I]);
      F^.HasWd := True;
      F^.DW := Cnt;
     End;
    End;
   End;
  End;
  RestoreSrc(S);
  If DescNum > 0 Then Begin
   LoadCIDWidths(F^, DescNum);
   RestoreSrc(S);
  End;
  If TuNum > 0 Then Begin
   SrcMode := 0;
   If LoadStream(TuNum, TuBuf, TL) Then Begin
    TuLen := TL;
    ParseToUnicode(F^);
   End;
  End;
  Inc(NFonts);
 End;
 RestoreSrc(S);
End;

Function FontIndex(Const Name: String): Integer;
Var
 I: Integer;
Begin
 FontIndex := -1;
 For I := NFonts - 1 DownTo 0 Do
  If Fonts[I].Name = Name Then Begin FontIndex := I; Exit; End;
End;

Function UniToStr(U: LongInt): String;
Begin
 Case U Of
  0..255: UniToStr := Chr(U);
  8216, 8217, 8218: UniToStr := '''';
  8220, 8221, 8222: UniToStr := '"';
  8211, 8212, 8722: UniToStr := '-';
  8226: UniToStr := #149;
  8230: UniToStr := '...';
  8364: UniToStr := #128;
  64256: UniToStr := 'ff';
  64257: UniToStr := 'fi';
  64258: UniToStr := 'fl';
  64259: UniToStr := 'ffi';
  64260: UniToStr := 'ffl';
  352: UniToStr := 'S'; 353: UniToStr := 's';
  338: UniToStr := 'OE'; 339: UniToStr := 'oe';
 Else UniToStr := '?';
 End;
End;

Function MapCode(Var F: TFontRec; Code: LongInt): String;
Var
 I: Integer;
 U: LongInt;
 R: String;
Begin
 If F.Wide Or (F.NTU > 0) Then Begin
  For I := 0 To F.NTU - 1 Do
   If (Code >= F.TU^[I].Lo) And (Code <= F.TU^[I].Hi) Then Begin
    U := F.TU^[I].Dst + (Code - F.TU^[I].Lo);
    R := UniToStr(U);
    If F.TU^[I].Dst2 <> 0 Then R := R + UniToStr(F.TU^[I].Dst2);
    MapCode := R;
    Exit;
   End;
  If F.Wide Then MapCode := '' Else If Code < 32 Then MapCode := '' Else MapCode := Chr(Code And 255);
  Exit;
 End;
 If Code < 32 Then MapCode := '' Else MapCode := Chr(Code And 255);
End;

Function GlyphW(Var F: TFontRec; Code: LongInt): Integer;
Var
 I: Integer;
Begin
 If F.Wide Then Begin
  For I := 0 To F.NCW - 1 Do
   If (Code >= F.CW^[I].Lo) And (Code <= F.CW^[I].Hi) Then Begin
    GlyphW := F.CW^[I].Dst;
    Exit;
   End;
  GlyphW := F.DW;
  Exit;
 End;
 If F.HasWd And (Code >= F.First) And (Code < F.First + F.DW) Then Begin
  If F.Wd^[Code - F.First] > 0 Then Begin GlyphW := F.Wd^[Code - F.First]; Exit; End;
 End;
 GlyphW := CharW(F.Fam, 0, Code And 255);
End;

{ Charge les polices et XObjects de la ressource "Resources" de l'objet Node. }
Function LoadResources(Node: Integer): Boolean;
Var
 S: TSrcState;
 P, V, R, Q, FD: LongInt;
 N, I, NP: Integer;
 Names: Array[0..FMAX-1] Of String[63];
 Nums: Array[0..FMAX-1] Of Integer;
 XNames: Array[0..XMAX-1] Of String[63];
 XNums: Array[0..XMAX-1] Of Integer;
 NX: Integer;
 T: Integer;
 Sub: String;
 SS: TSrcState;
 InRes: TSrcState;
Begin
 LoadResources := False;
 SaveSrc(S);
 P := EnterObj(Node);
 If P < 0 Then Begin RestoreSrc(S); Exit; End;
 V := DictFind(P, 'Resources');
 If V < 0 Then Begin RestoreSrc(S); Exit; End;
 N := RefAt(V);
 If N > 0 Then V := EnterObj(N);
 If V < 0 Then Begin RestoreSrc(S); Exit; End;
 R := V;
 SaveSrc(InRes);
 NP := 0;
 FD := DictFind(R, 'Font');
 If FD >= 0 Then Begin
  N := RefAt(FD);
  If N > 0 Then FD := EnterObj(N);
  If FD >= 0 Then Begin
   Q := FD;
   If NextTok(Q) = T_DB Then
    While NP < FMAX Do Begin
     T := NextTok(Q);
     If T <> T_NAME Then Break;
     Names[NP] := TokS;
     Nums[NP] := RefAt(Q);
     SkipValue(Q);
     If Nums[NP] > 0 Then Inc(NP);
    End;
  End;
 End;
 RestoreSrc(InRes);
 NX := 0;
 FD := DictFind(R, 'XObject');
 If FD >= 0 Then Begin
  N := RefAt(FD);
  If N > 0 Then FD := EnterObj(N);
  If FD >= 0 Then Begin
   Q := FD;
   If NextTok(Q) = T_DB Then
    While NX < XMAX Do Begin
     T := NextTok(Q);
     If T <> T_NAME Then Break;
     XNames[NX] := TokS;
     XNums[NX] := RefAt(Q);
     SkipValue(Q);
     If XNums[NX] > 0 Then Inc(NX);
    End;
  End;
 End;
 RestoreSrc(S);
 For I := 0 To NP - 1 Do LoadFont(Names[I], Nums[I]);
 For I := 0 To NX - 1 Do Begin
  If NXObjs >= XMAX Then Break;
  SaveSrc(SS);
  Q := EnterObj(XNums[I]);
  Sub := '';
  If Q >= 0 Then Sub := ValName(DictFind(Q, 'Subtype'));
  RestoreSrc(SS);
  XObjs[NXObjs].Name := XNames[I];
  XObjs[NXObjs].Num := XNums[I];
  XObjs[NXObjs].IsForm := Sub = 'Form';
  Inc(NXObjs);
 End;
 If NRes < 8 Then Begin ResNodes[NRes] := Node; Inc(NRes); End;
 LoadResources := True;
End;

{ Recherche d'une ressource (catégorie, nom) dans les ressources courantes.
  Retourne la position de la valeur (source positionnée sur son objet) ou -1.
  L'appelant encadre l'appel par SaveSrc / RestoreSrc. }
Function FindRes(Const Cat, Name: String; Var Num: LongInt): LongInt;
Var
 I: Integer;
 P, V, D, N: LongInt;
Begin
 FindRes := -1;
 Num := 0;
 For I := NRes - 1 DownTo 0 Do Begin
  SrcMode := 0;
  P := EnterObj(ResNodes[I]);
  If P < 0 Then Continue;
  V := DictFind(P, 'Resources');
  If V < 0 Then Continue;
  N := RefAt(V);
  If N > 0 Then V := EnterObj(N);
  If V < 0 Then Continue;
  D := DictFind(V, Cat);
  If D < 0 Then Continue;
  N := RefAt(D);
  If N > 0 Then D := EnterObj(N);
  If D < 0 Then Continue;
  V := DictFind(D, Name);
  If V < 0 Then Continue;
  N := RefAt(V);
  If N > 0 Then Begin Num := N; V := EnterObj(N); End;
  If V >= 0 Then Begin FindRes := V; Exit; End;
 End;
End;
{$IFDEF FPC}
Const
 MAX_IMAGE_WIDTH = 12000;
 MAX_IMAGE_HEIGHT = 12000;
{ Decodeur JPEG integre. Structure du flux et decodage Huffman selon
  ITU-T T.81, annexes B, C, F et G (JPEG sequentiel et progressif 8 bits).
  Aucune unite image, bibliotheque externe ou API Windows n'est utilisee.
  Les marqueurs, tables, indices et allocations sont controles avant acces. }
Const
 JDZigZag: Array[0..63] Of Byte =
  (0,1,8,16,9,2,3,10,17,24,32,25,18,11,4,5,
   12,19,26,33,40,48,41,34,27,20,13,6,7,14,21,28,
   35,42,49,56,57,50,43,36,29,22,15,23,30,37,44,51,
   58,59,52,45,38,31,39,46,53,60,61,54,47,55,62,63);
Type
 TJDBytes = Array[0..134217727] Of Byte;
 PJDBytes = ^TJDBytes;
 TJDInts = Array[0..16777215] Of LongInt;
 PJDInts = ^TJDInts;
 TJDImage = Record
  Width,Height: Integer;
  Pixels: PByte; { Triplets R,V,B ; resultat temporaire avant quantification. }
 End;
 TJDHuffman = Record
  Ready: Boolean;
  MinCode,MaxCode,ValueOffset: Array[1..16] Of LongInt;
  Symbols: Array[0..255] Of Byte;
 End;
 TJDComponent = Record
  ID,H,V,TQ,TD,TA: Integer;
  BlockWidth,BlockHeight,RealWidth,RealHeight: LongInt;
  CoefCount,PlaneSize: LongInt;
  Predictor: LongInt;
  Coefficients: PJDInts;
  Plane: PJDBytes;
  Quant: Array[0..63] Of Word;
  Progress: Array[0..63] Of ShortInt;
  QuantReady: Boolean;
 End;
 TJDState = Record
  Data: PJDBytes;
  Size,Position: LongInt;
  Bad,FrameFound,ScanFound,Progressive,Adobe: Boolean;
  Width,Height,Components,MaxH,MaxV,MCUWidth,MCUHeight: Integer;
  AdobeTransform: Integer;
  RestartInterval: LongInt;
  BitsLeft,BitByte: Integer;
  EOBRun: LongInt;
  Quant: Array[0..3,0..63] Of Word;
  QuantReady: Array[0..3] Of Boolean;
  Huffman: Array[0..1,0..3] Of TJDHuffman;
  Component: Array[0..3] Of TJDComponent;
  Basis: Array[0..7,0..7] Of Double;
 End;
 PJDState = ^TJDState;

Function JDAllocate(Size: LongInt): Pointer;
Var P: Pointer;
 {$IFDEF FPC}Previous: Boolean;{$ENDIF}
Begin
 P:=Nil;
 If Size>0 Then Begin
  {$IFDEF FPC}
  Previous:=ReturnNilIfGrowHeapFails; ReturnNilIfGrowHeapFails:=True;
  GetMem(P,Size); ReturnNilIfGrowHeapFails:=Previous;
  {$ELSE}
  If MaxAvail>=Size Then GetMem(P,Size);
  {$ENDIF}
 End;
 JDAllocate:=P;
End;

Function JDByte(Var D: TJDState): Integer;
Begin
 JDByte:=0;
 If D.Bad Then Exit;
 If D.Position>=D.Size Then Begin D.Bad:=True; Exit; End;
 JDByte:=D.Data^[D.Position]; Inc(D.Position);
End;

Function JDWord(Var D: TJDState): LongInt;
Var A: Integer;
Begin
 A:=JDByte(D); JDWord:=LongInt(A)*256+JDByte(D);
End;

Function JDMarker(Var D: TJDState): Integer;
Var M: Integer;
Begin
 JDMarker:=0;
 If JDByte(D)<>255 Then Begin D.Bad:=True; Exit; End;
 Repeat M:=JDByte(D); Until (M<>255) Or D.Bad;
 If M=0 Then D.Bad:=True;
 JDMarker:=M;
End;

Function JDBits(Var D: TJDState; Count: Integer): LongInt;
Var I,B: Integer; V: LongInt;
Begin
 V:=0;
 If (Count<0) Or (Count>16) Then Begin D.Bad:=True; JDBits:=0; Exit; End;
 For I:=1 To Count Do Begin
  If D.BitsLeft=0 Then Begin
   B:=JDByte(D);
   If B=255 Then If JDByte(D)<>0 Then D.Bad:=True;
   D.BitByte:=B; D.BitsLeft:=8;
  End;
  Dec(D.BitsLeft); V:=V*2+((D.BitByte Shr D.BitsLeft) And 1);
 End;
 JDBits:=V;
End;

Function JDExtend(Var D: TJDState; Count: Integer): LongInt;
Var V: LongInt;
Begin
 If Count=0 Then Begin JDExtend:=0; Exit; End;
 V:=JDBits(D,Count);
 If V<(LongInt(1) Shl (Count-1)) Then V:=V-(LongInt(1) Shl Count)+1;
 JDExtend:=V;
End;

Function JDHuff(Var D: TJDState; Kind,Table: Integer): Integer;
Var N: Integer; Code,Index: LongInt;
Begin
 JDHuff:=0;
 If Not D.Huffman[Kind,Table].Ready Then Begin D.Bad:=True; Exit; End;
 Code:=0;
 For N:=1 To 16 Do Begin
  Code:=Code*2+JDBits(D,1);
  With D.Huffman[Kind,Table] Do
   If (MaxCode[N]>=0) And (Code>=MinCode[N]) And (Code<=MaxCode[N]) Then Begin
    Index:=Code+ValueOffset[N];
    If (Index<0) Or (Index>255) Then D.Bad:=True
    Else JDHuff:=Symbols[Index];
    Exit;
   End;
  If D.Bad Then Exit;
 End;
 D.Bad:=True;
End;

Procedure JDReadQuant(Var D: TJDState; Limit: LongInt);
Var Spec,Precision,Table,I,V: Integer;
Begin
 While (D.Position<Limit) And Not D.Bad Do Begin
  Spec:=JDByte(D); Precision:=Spec Shr 4; Table:=Spec And 15;
  If (Precision>1) Or (Table>3) Or (Limit-D.Position<64*(Precision+1)) Then Begin D.Bad:=True; Exit; End;
  For I:=0 To 63 Do Begin
   If Precision=0 Then V:=JDByte(D) Else V:=JDWord(D);
   If V=0 Then D.Bad:=True;
   D.Quant[Table,JDZigZag[I]]:=V;
  End;
  D.QuantReady[Table]:=True;
 End;
End;

Procedure JDReadHuffman(Var D: TJDState; Limit: LongInt);
Var Spec,Kind,Table,N,I,Total: Integer; Code: LongInt;
    Counts: Array[1..16] Of Byte;
Begin
 While (D.Position<Limit) And Not D.Bad Do Begin
  Spec:=JDByte(D); Kind:=Spec Shr 4; Table:=Spec And 15;
  If (Kind>1) Or (Table>3) Or (Limit-D.Position<16) Then Begin D.Bad:=True; Exit; End;
  Total:=0;
  For N:=1 To 16 Do Begin Counts[N]:=JDByte(D); Inc(Total,Counts[N]); End;
  If (Total=0) Or (Total>256) Or (Total>Limit-D.Position) Then Begin D.Bad:=True; Exit; End;
  Code:=0; I:=0;
  With D.Huffman[Kind,Table] Do Begin
   For N:=1 To 16 Do Begin
    MinCode[N]:=Code; MaxCode[N]:=-1; ValueOffset[N]:=I-Code;
    If Counts[N]>0 Then Begin
     MaxCode[N]:=Code+Counts[N]-1;
     If MaxCode[N]>=(LongInt(1) Shl N)-1 Then Begin D.Bad:=True; Exit; End;
    End;
    Inc(Code,Counts[N]); Inc(I,Counts[N]); Code:=Code*2;
   End;
   For I:=0 To Total-1 Do Begin
    Spec:=JDByte(D); Symbols[I]:=Spec;
    If (Kind=0) And (Spec>11) Then D.Bad:=True;
   End;
   Ready:=True;
  End;
 End;
End;

Procedure JDReadFrame(Var D: TJDState; Marker: Integer; Limit: LongInt);
Var I,J,Spec,Blocks: Integer;
Begin
 If D.FrameFound Or (Limit-D.Position<6) Then Begin D.Bad:=True; Exit; End;
 If JDByte(D)<>8 Then Begin D.Bad:=True; Exit; End;
 D.Height:=JDWord(D); D.Width:=JDWord(D); D.Components:=JDByte(D);
 If (D.Width<1) Or (D.Height<1) Or (D.Width>MAX_IMAGE_WIDTH) Or
    (D.Height>MAX_IMAGE_HEIGHT) Or Not (D.Components In [1,3,4]) Or
    (Limit-D.Position<>D.Components*3) Then Begin D.Bad:=True; Exit; End;
 D.Progressive:=Marker=$C2; D.MaxH:=1; D.MaxV:=1; Blocks:=0;
 For I:=0 To D.Components-1 Do With D.Component[I] Do Begin
  ID:=JDByte(D); Spec:=JDByte(D); H:=Spec Shr 4; V:=Spec And 15; TQ:=JDByte(D);
  If (H<1) Or (H>4) Or (V<1) Or (V>4) Or (TQ>3) Then Begin D.Bad:=True; Exit; End;
  For J:=0 To I-1 Do If ID=D.Component[J].ID Then Begin D.Bad:=True; Exit; End;
  Inc(Blocks,H*V); D.MaxH:=IMax(D.MaxH,H); D.MaxV:=IMax(D.MaxV,V);
  FillChar(Progress,SizeOf(Progress),255);
 End;
 If Blocks>10 Then Begin D.Bad:=True; Exit; End;
 D.MCUWidth:=(D.Width+8*D.MaxH-1) Div (8*D.MaxH);
 D.MCUHeight:=(D.Height+8*D.MaxV-1) Div (8*D.MaxV);
 For I:=0 To D.Components-1 Do With D.Component[I] Do Begin
  BlockWidth:=LongInt(D.MCUWidth)*H; BlockHeight:=LongInt(D.MCUHeight)*V;
  RealWidth:=(LongInt(D.Width)*H+D.MaxH-1) Div D.MaxH;
  RealHeight:=(LongInt(D.Height)*V+D.MaxV-1) Div D.MaxV;
  CoefCount:=BlockWidth*BlockHeight*64;
  If (CoefCount<1) Or (CoefCount>16777216) Then Begin D.Bad:=True; Exit; End;
  Coefficients:=PJDInts(JDAllocate(CoefCount*SizeOf(LongInt)));
  If Coefficients=Nil Then Begin D.Bad:=True; Exit; End;
  FillChar(Coefficients^,CoefCount*SizeOf(LongInt),0);
 End;
 D.FrameFound:=True;
End;

Procedure JDRefineValue(Var D: TJDState; Var V: LongInt; BitValue: LongInt);
Begin
 If JDBits(D,1)<>0 Then If (Abs(V) And BitValue)=0 Then Begin
  If V>=0 Then Inc(V,BitValue) Else Dec(V,BitValue);
 End;
End;

Procedure JDDecodeBlock(Var D: TJDState; C: Integer; Block: LongInt;
                        SS,SE,AH,AL: Integer);
Var K,R,S,Symbol: Integer; Base,P1,NewValue,CoefIndex: LongInt; P: PJDInts;
Begin
 If D.Bad Then Exit;
 With D.Component[C] Do Begin
  Base:=Block*64; P:=Coefficients;
  If (Base<0) Or (Base>CoefCount-64) Then Begin D.Bad:=True; Exit; End;
  P1:=LongInt(1) Shl AL;
  If SS=0 Then Begin
   If AH=0 Then Begin
    S:=JDHuff(D,0,TD); If (S>11) Or D.Bad Then Begin D.Bad:=True; Exit; End;
    Predictor:=Predictor+JDExtend(D,S);
    If Abs(Predictor)>32767 Then Begin D.Bad:=True; Exit; End;
    P^[Base]:=Predictor*P1;
   End Else If JDBits(D,1)<>0 Then P^[Base]:=P^[Base] Or P1;
  End;
  K:=SS; If K=0 Then K:=1;
  If K>SE Then Exit;
  If AH=0 Then Begin
   If D.EOBRun>0 Then Begin Dec(D.EOBRun); Exit; End;
   While (K<=SE) And Not D.Bad Do Begin
    Symbol:=JDHuff(D,1,TA); R:=Symbol Shr 4; S:=Symbol And 15;
    If S=0 Then Begin
     If R=15 Then Begin Inc(K,16); If K>SE+1 Then D.Bad:=True; End
     Else Begin
      If Not D.Progressive And (R<>0) Then Begin D.Bad:=True; Exit; End;
      D.EOBRun:=(LongInt(1) Shl R)+JDBits(D,R)-1; Exit;
     End;
    End Else Begin
     If S>10 Then Begin D.Bad:=True; Exit; End;
     Inc(K,R); If K>SE Then Begin D.Bad:=True; Exit; End;
     P^[Base+JDZigZag[K]]:=JDExtend(D,S)*P1; Inc(K);
    End;
   End;
  End Else Begin
   { Scans AC de raffinement : les bits des coefficients deja presents
     sont entrelaces avec les nouvelles valeurs et les suites de zeros. }
   If D.EOBRun=0 Then Begin
    While (K<=SE) And Not D.Bad Do Begin
     Symbol:=JDHuff(D,1,TA); R:=Symbol Shr 4; S:=Symbol And 15; NewValue:=0;
     If S<>0 Then Begin
      If S<>1 Then Begin D.Bad:=True; Exit; End;
      If JDBits(D,1)<>0 Then NewValue:=P1 Else NewValue:=-P1;
     End Else If R<>15 Then Begin
      D.EOBRun:=(LongInt(1) Shl R)+JDBits(D,R); Break;
     End Else R:=16;
     While (K<=SE) And Not D.Bad Do Begin
      CoefIndex:=Base+JDZigZag[K];
      If P^[CoefIndex]<>0 Then JDRefineValue(D,P^[CoefIndex],P1)
      Else Begin
       If R=0 Then Break;
       Dec(R);
       { ZRL termine exactement apres le seizieme zero. Les bits de
         raffinement suivants appartiennent au prochain symbole. }
       If (R=0) And (NewValue=0) Then Begin Inc(K); Break; End;
      End;
      Inc(K);
     End;
     If R<>0 Then Begin D.Bad:=True; Exit; End;
     If NewValue<>0 Then Begin
      If K>SE Then Begin D.Bad:=True; Exit; End;
      P^[Base+JDZigZag[K]]:=NewValue; Inc(K);
     End;
    End;
   End;
   If D.EOBRun>0 Then Begin
    While (K<=SE) And Not D.Bad Do Begin
     CoefIndex:=Base+JDZigZag[K];
     If P^[CoefIndex]<>0 Then JDRefineValue(D,P^[CoefIndex],P1);
     Inc(K);
    End;
    Dec(D.EOBRun);
   End;
  End;
 End;
End;

Procedure JDReadScan(Var D: TJDState; Limit: LongInt);
Var NS,I,J,C,ID,Spec,SS,SE,AH,AL,BX,BY,HX,VY,Restart,Marker: Integer;
    Order: Array[0..3] Of Integer; Found: Boolean;
    Total,MCU,Across,Down,Block: LongInt;
Begin
 FillChar(Order,SizeOf(Order),0);
 If Not D.FrameFound Then Begin D.Bad:=True; Exit; End;
 NS:=JDByte(D);
 If (NS<1) Or (NS>D.Components) Or (Limit-D.Position<>NS*2+3) Then Begin D.Bad:=True; Exit; End;
 For I:=0 To NS-1 Do Begin
  ID:=JDByte(D); Spec:=JDByte(D); Found:=False; C:=0;
  For J:=0 To D.Components-1 Do If D.Component[J].ID=ID Then Begin C:=J; Found:=True; End;
  If Not Found Or ((Spec Shr 4)>3) Or ((Spec And 15)>3) Then Begin D.Bad:=True; Exit; End;
  For J:=0 To I-1 Do If Order[J]=C Then Begin D.Bad:=True; Exit; End;
  Order[I]:=C; D.Component[C].TD:=Spec Shr 4; D.Component[C].TA:=Spec And 15;
 End;
 SS:=JDByte(D); SE:=JDByte(D); Spec:=JDByte(D); AH:=Spec Shr 4; AL:=Spec And 15;
 If (SS>SE) Or (SE>63) Or (AH>13) Or (AL>13) Then Begin D.Bad:=True; Exit; End;
 If D.Progressive Then Begin
  If ((SS=0) And (SE<>0)) Or ((SS>0) And (NS<>1)) Or
     ((AH<>0) And (AH<>AL+1)) Then Begin D.Bad:=True; Exit; End;
 End Else If (SS<>0) Or (SE<>63) Or (AH<>0) Or (AL<>0) Then Begin D.Bad:=True; Exit; End;
 For I:=0 To NS-1 Do With D.Component[Order[I]] Do Begin
  If Not D.QuantReady[TQ] Then Begin D.Bad:=True; Exit; End;
  If Not QuantReady Then Begin Move(D.Quant[TQ],Quant,SizeOf(Quant)); QuantReady:=True; End;
  For J:=SS To SE Do Begin
   If ((AH=0) And (Progress[J]<>-1)) Or ((AH<>0) And (Progress[J]<>AH)) Then Begin D.Bad:=True; Exit; End;
   Progress[J]:=AL;
  End;
 End;
 D.BitsLeft:=0; D.EOBRun:=0; Restart:=0;
 For I:=0 To D.Components-1 Do D.Component[I].Predictor:=0;
 If NS=1 Then Begin
  C:=Order[0]; Across:=(D.Component[C].RealWidth+7) Div 8;
  Down:=(D.Component[C].RealHeight+7) Div 8;
 End Else Begin Across:=D.MCUWidth; Down:=D.MCUHeight; End;
 Total:=Across*Down;
 For MCU:=0 To Total-1 Do Begin
  If (MCU>0) And (D.RestartInterval>0) And ((MCU Mod D.RestartInterval)=0) Then Begin
   If D.EOBRun<>0 Then Begin D.Bad:=True; Exit; End;
   D.BitsLeft:=0; Marker:=JDMarker(D);
   If Marker<>$D0+Restart Then Begin D.Bad:=True; Exit; End;
   Restart:=(Restart+1) And 7;
   For I:=0 To D.Components-1 Do D.Component[I].Predictor:=0;
  End;
  BX:=MCU Mod Across; BY:=MCU Div Across;
  For I:=0 To NS-1 Do Begin
   C:=Order[I];
   If NS=1 Then Begin
    Block:=LongInt(BY)*D.Component[C].BlockWidth+BX;
    JDDecodeBlock(D,C,Block,SS,SE,AH,AL);
   End Else With D.Component[C] Do Begin
    For VY:=0 To V-1 Do For HX:=0 To H-1 Do Begin
     Block:=(LongInt(BY)*V+VY)*BlockWidth+LongInt(BX)*H+HX;
     JDDecodeBlock(D,C,Block,SS,SE,AH,AL);
    End;
   End;
   If D.Bad Then Exit;
  End;
 End;
 If D.EOBRun<>0 Then D.Bad:=True;
 D.BitsLeft:=0; D.ScanFound:=True;
End;

Function JDClamp(V: LongInt): Byte;
Begin
 If V<0 Then JDClamp:=0 Else If V>255 Then JDClamp:=255 Else JDClamp:=V;
End;

Procedure JDInverseDCT(Var D: TJDState; C: Integer);
Var X,Y,IU,IV,I: Integer; BX,BY,Base,Dest,Stride: LongInt;
    Temp: Array[0..7,0..7] Of Double; Sum: Double; OnlyDC: Boolean;
Begin
 With D.Component[C] Do Begin
  Stride:=BlockWidth*8; PlaneSize:=Stride*BlockHeight*8;
  Plane:=PJDBytes(JDAllocate(PlaneSize));
  If Plane=Nil Then Begin D.Bad:=True; Exit; End;
  For BY:=0 To BlockHeight-1 Do For BX:=0 To BlockWidth-1 Do Begin
   Base:=(BY*BlockWidth+BX)*64;
   OnlyDC:=True;
   For I:=1 To 63 Do If Coefficients^[Base+I]<>0 Then Begin OnlyDC:=False; Break; End;
   If OnlyDC Then Begin
    I:=JDClamp(Round((1.0*Coefficients^[Base])*Quant[0]/8)+128);
    For Y:=0 To 7 Do Begin
     Dest:=(BY*8+Y)*Stride+BX*8;
     For X:=0 To 7 Do Plane^[Dest+X]:=I;
    End;
   End Else Begin
    { DCT inverse separable : 2 passes de 8x8x8, base calculee une fois. }
    For IV:=0 To 7 Do For X:=0 To 7 Do Begin
     Sum:=0;
     For IU:=0 To 7 Do Sum:=Sum+(1.0*Coefficients^[Base+IV*8+IU])*Quant[IV*8+IU]*D.Basis[X,IU];
     Temp[IV,X]:=Sum;
    End;
    For Y:=0 To 7 Do For X:=0 To 7 Do Begin
     Sum:=0; For IV:=0 To 7 Do Sum:=Sum+Temp[IV,X]*D.Basis[Y,IV];
     Dest:=(BY*8+Y)*Stride+BX*8+X;
     Plane^[Dest]:=JDClamp(Round(Sum/4)+128);
    End;
   End;
  End;
 End;
End;

Function JDMin(A,B: LongInt): LongInt;
Begin If A<B Then JDMin:=A Else JDMin:=B; End;
Function JDMax(A,B: LongInt): LongInt;
Begin If A>B Then JDMax:=A Else JDMax:=B; End;

Function JDSample(Var D: TJDState; C,X,Y: Integer): Integer;
Var FX,FY,AX,AY,X0,Y0,X1,Y1: LongInt; Stride: LongInt;
Begin
 With D.Component[C] Do Begin
  { Interpolation bilineaire centree des chrominances sous-echantillonnees.
    Les indices sont limites a la partie reelle du plan, pas au remplissage MCU. }
  FX:=((LongInt(X)*2+1)*H*128) Div D.MaxH-128;
  FY:=((LongInt(Y)*2+1)*V*128) Div D.MaxV-128;
  FX:=JDMax(0,JDMin(FX,(RealWidth-1)*256)); FY:=JDMax(0,JDMin(FY,(RealHeight-1)*256));
  X0:=FX Div 256; Y0:=FY Div 256; AX:=FX And 255; AY:=FY And 255;
  X1:=JDMin(X0+1,RealWidth-1); Y1:=JDMin(Y0+1,RealHeight-1); Stride:=BlockWidth*8;
  JDSample:=(LongInt(Plane^[Y0*Stride+X0])*(256-AX)*(256-AY)+
             LongInt(Plane^[Y0*Stride+X1])*AX*(256-AY)+
             LongInt(Plane^[Y1*Stride+X0])*(256-AX)*AY+
             LongInt(Plane^[Y1*Stride+X1])*AX*AY+32768) Div 65536;
 End;
End;

Procedure JDCompose(Var D: TJDState; Var Img: TJDImage);
Var X,Y,I,U,V,A,B,C,K,R,G,Blue: Integer; P: PByte; DirectRGB: Boolean;
Begin
 For X:=0 To 7 Do For U:=0 To 7 Do Begin
  D.Basis[X,U]:=Cos((2*X+1)*U*Pi/16);
  If U=0 Then D.Basis[X,U]:=D.Basis[X,U]/Sqrt(2);
 End;
 For I:=0 To D.Components-1 Do Begin
  If Not D.Component[I].QuantReady Or (D.Component[I].Progress[0]<0) Then Begin D.Bad:=True; Exit; End;
  JDInverseDCT(D,I); If D.Bad Then Exit;
 End;
 Img.Width:=D.Width; Img.Height:=D.Height;
 Img.Pixels:=PByte(JDAllocate(LongInt(D.Width)*D.Height*3));
 If Img.Pixels=Nil Then Begin D.Bad:=True; Exit; End;
 DirectRGB:=(D.Components=3) And
  ((D.Adobe And (D.AdobeTransform=0)) Or
   ((D.Component[0].ID=Ord('R')) And (D.Component[1].ID=Ord('G')) And (D.Component[2].ID=Ord('B'))));
 P:=Img.Pixels;
 For Y:=0 To D.Height-1 Do For X:=0 To D.Width-1 Do Begin
  A:=JDSample(D,0,X,Y); R:=A; G:=A; Blue:=A;
  If D.Components>=3 Then Begin
   B:=JDSample(D,1,X,Y); C:=JDSample(D,2,X,Y);
   If DirectRGB Or ((D.Components=4) And (Not D.Adobe Or (D.AdobeTransform=0))) Then Begin
    R:=A; G:=B; Blue:=C;
   End Else Begin
    U:=B-128; V:=C-128;
    R:=JDClamp(A+Round(1.402*V)); G:=JDClamp(A-Round(0.344136*U+0.714136*V));
    Blue:=JDClamp(A+Round(1.772*U));
   End;
   If D.Components=4 Then Begin
    K:=JDSample(D,3,X,Y);
    If D.Adobe Then Begin
     If D.AdobeTransform=2 Then Begin R:=255-R; G:=255-G; Blue:=255-Blue; End;
     R:=(LongInt(R)*K+127) Div 255; G:=(LongInt(G)*K+127) Div 255;
     Blue:=(LongInt(Blue)*K+127) Div 255;
    End Else Begin
     R:=(LongInt(255-R)*(255-K)+127) Div 255; G:=(LongInt(255-G)*(255-K)+127) Div 255;
     Blue:=(LongInt(255-Blue)*(255-K)+127) Div 255;
    End;
   End;
  End;
  P^:=JDClamp(R); Inc(P); P^:=JDClamp(G); Inc(P); P^:=JDClamp(Blue); Inc(P);
 End;
End;

Function JDDecodeMem(Src: Pointer; SrcSize: LongInt; Var Img: TJDImage): Boolean;
Var D: PJDState; M,I: Integer; L,Limit: LongInt;
    Ended: Boolean;
Begin
 JDDecodeMem:=False; FillChar(Img,SizeOf(Img),0);
 D:=PJDState(JDAllocate(SizeOf(TJDState))); If D=Nil Then Exit;
 FillChar(D^,SizeOf(D^),0); D^.AdobeTransform:=-1; Ended:=False;
 D^.Size:=SrcSize;
 If (D^.Size>=4) And (D^.Size<=134217728) Then Begin
  D^.Data:=PJDBytes(JDAllocate(D^.Size));
  If D^.Data<>Nil Then Move(Src^,D^.Data^,D^.Size) Else D^.Bad:=True;
 End Else D^.Bad:=True;
 If Not D^.Bad Then If JDMarker(D^)<>$D8 Then D^.Bad:=True;
 While Not D^.Bad And Not Ended Do Begin
  M:=JDMarker(D^);
  If D^.Bad Then Break;
  If M=$D9 Then Begin Ended:=True; Break; End;
  If (M=$D8) Or (M In [$D0..$D7]) Then Begin D^.Bad:=True; Break; End;
  If M<>$01 Then Begin
   L:=JDWord(D^);
   If (L<2) Or (L-2>D^.Size-D^.Position) Then Begin D^.Bad:=True; Break; End;
   Limit:=D^.Position+L-2;
   Case M Of
    $DB: JDReadQuant(D^,Limit);
    $C4: JDReadHuffman(D^,Limit);
    $C0,$C1,$C2: JDReadFrame(D^,M,Limit);
    $DD: Begin
     If L<>4 Then D^.Bad:=True Else D^.RestartInterval:=JDWord(D^);
    End;
    $DA: Begin
     JDReadScan(D^,Limit);
     If D^.Bad Then Break;
     Continue; { Position est maintenant a la fin des donnees entropiques. }
    End;
    $EE: Begin
     If L>=14 Then Begin
      With D^ Do If (Data^[Position]=Ord('A')) And (Data^[Position+1]=Ord('d')) And
       (Data^[Position+2]=Ord('o')) And (Data^[Position+3]=Ord('b')) And (Data^[Position+4]=Ord('e')) Then Begin
        Adobe:=True; AdobeTransform:=Data^[Position+11];
        If AdobeTransform>2 Then Bad:=True;
       End;
     End;
    End;
    $E0..$ED,$EF,$FE: ; { APP/JFIF/EXIF/ICC et commentaires non interpretables sont sautes. }
    Else D^.Bad:=True; { JPEG arithmetique, sans perte ou hierarchique non pris en charge. }
   End;
   D^.Position:=Limit;
  End;
 End;
 If Not D^.Bad And Ended And D^.FrameFound And D^.ScanFound Then JDCompose(D^,Img);
 JDDecodeMem:=Not D^.Bad And Ended And D^.FrameFound And D^.ScanFound And (Img.Pixels<>Nil);
 If D^.Bad And (Img.Pixels<>Nil) Then Begin
  FreeMem(Img.Pixels,LongInt(Img.Width)*Img.Height*3); Img.Pixels:=Nil;
 End;
 For I:=0 To 3 Do With D^.Component[I] Do Begin
  If Coefficients<>Nil Then FreeMem(Coefficients,CoefCount*SizeOf(LongInt));
  If Plane<>Nil Then FreeMem(Plane,PlaneSize);
 End;
 If D^.Data<>Nil Then FreeMem(D^.Data,D^.Size);
 FreeMem(D,SizeOf(TJDState));
End;


{$ENDIF}
{ ---------------------------------------------------------------------- }
{ Fonctions PDF (types 0, 2, 3 et 4) et espaces colorimétriques            }
{ ---------------------------------------------------------------------- }

{$IFDEF FPC}
Type
 TBigBytes = Array[0..134217727] Of Byte;
 PBigBytes = ^TBigBytes;

Function FnFloor(X: Real): Real;
Begin
 If X >= 0 Then FnFloor := Int(X)
 Else If Frac(X) = 0 Then FnFloor := X
 Else FnFloor := Int(X) - 1;
End;

Function FnCeil(X: Real): Real;
Begin
 FnCeil := -FnFloor(-X);
End;

Function FnAtan2(Y, X: Real): Real;
Begin
 If X > 0 Then FnAtan2 := ArcTan(Y / X)
 Else If X < 0 Then Begin
  If Y >= 0 Then FnAtan2 := ArcTan(Y / X) + Pi Else FnAtan2 := ArcTan(Y / X) - Pi;
 End
 Else If Y > 0 Then FnAtan2 := Pi / 2
 Else If Y < 0 Then FnAtan2 := -Pi / 2
 Else FnAtan2 := 0;
End;

Const
 PSMAXCODE = 1500;
 PSMAXPROG = 6;
 PSOPS = 'abs add atan ceiling cos cvi cvr div exp floor idiv ln log mod mul neg round sin sqrt sub truncate ' +
         'and bitshift eq false ge gt le lt ne not or true xor copy dup exch index pop roll ';

Type
 TPSIns = Record
  Op: SmallInt;      { 0 empile V, 1.. opérateur, 100 saut si faux, 101 saut, 102 vide }
  V: Real;
 End;
 TPSProg = Record
  Num: LongInt;
  N: Integer;
  Ins: Array[0..PSMAXCODE - 1] Of TPSIns;
 End;
 PPSProg = ^TPSProg;
 TSamp = Record
  Num: LongInt;
  Data: PBigBytes;
  Len: LongInt;
 End;

Var
 PSProgs: Array[0..PSMAXPROG - 1] Of PPSProg;
 PSNProg, PSNext: Integer;
 SampCache: Array[0..3] Of TSamp;
 SampNext: Integer;
 FnBuf: PByteBuf;

{ Lecture d'un tableau de nombres (suit une référence indirecte éventuelle) }
Function ReadNumsR(P: LongInt; Var A: Array Of Real; Max: Integer): Integer;
Var
 N: Integer;
 S: TSrcState;
Begin
 ReadNumsR := 0;
 If P < 0 Then Exit;
 N := RefAt(P);
 If N > 0 Then Begin
  SaveSrc(S);
  P := EnterObj(N);
  If P >= 0 Then ReadNumsR := ReadNums(P, A, Max);
  RestoreSrc(S);
 End
 Else ReadNumsR := ReadNums(P, A, Max);
End;

Procedure PSFreeAll;
Var
 I: Integer;
Begin
 For I := 0 To PSNProg - 1 Do
  If PSProgs[I] <> Nil Then Begin Dispose(PSProgs[I]); PSProgs[I] := Nil; End;
 PSNProg := 0; PSNext := 0;
 For I := 0 To 3 Do
  If SampCache[I].Data <> Nil Then Begin FreeMem(SampCache[I].Data, SampCache[I].Len + 16); SampCache[I].Data := Nil; End;
 For I := 0 To 3 Do SampCache[I].Num := 0;
End;

{ Compile le programme PostScript du flux Num (fonction de type 4) }
Function PSCompile(Num: LongInt): PPSProg;
Var
 L: LongInt;
 Pr: PPSProg;
 I, Slot, Sp, Cp: Integer;
 Pos0: LongInt;
 Tok: String;
 OpenSt, ClosedSt: Array[0..63] Of Integer;
 NO, NC, K, Code: Integer;
 C: Integer;
 V: Real;
 Err: Integer;
 First: Boolean;
Begin
 PSCompile := Nil;
 For I := 0 To PSNProg - 1 Do
  If (PSProgs[I] <> Nil) And (PSProgs[I]^.Num = Num) Then Begin PSCompile := PSProgs[I]; Exit; End;
 If FnBuf = Nil Then GetMem(FnBuf, BUFSZ + 16);
 SrcMode := 0;
 If Not LoadStream(Num, FnBuf, L) Then Exit;
 If L > 30000 Then L := 30000;
 New(Pr);
 Pr^.Num := Num; Pr^.N := 0;
 NO := 0; NC := 0; Pos0 := 0; First := True;
 While Pos0 < L Do Begin
  C := FnBuf^[Pos0];
  If (C <= 32) Then Begin Inc(Pos0); Continue; End;
  If C = 37 Then Begin
   While (Pos0 < L) And (FnBuf^[Pos0] <> 10) And (FnBuf^[Pos0] <> 13) Do Inc(Pos0);
   Continue;
  End;
  If (C = 123) Or (C = 125) Then Begin
   Inc(Pos0);
   If C = 123 Then Begin
    If First Then Begin First := False; Continue; End;
    If (NO >= 64) Or (Pr^.N >= PSMAXCODE - 2) Then Begin Dispose(Pr); Exit; End;
    Pr^.Ins[Pr^.N].Op := 102; OpenSt[NO] := Pr^.N; Inc(NO); Inc(Pr^.N);
   End
   Else Begin
    If NO > 0 Then Begin
     Dec(NO);
     If NC < 64 Then Begin ClosedSt[NC] := OpenSt[NO]; Inc(NC); End;
    End;
   End;
   Continue;
  End;
  Tok := '';
  While (Pos0 < L) And (FnBuf^[Pos0] > 32) And (FnBuf^[Pos0] <> 123) And (FnBuf^[Pos0] <> 125) And (FnBuf^[Pos0] <> 37) Do Begin
   If Length(Tok) < 30 Then Tok := Tok + Chr(FnBuf^[Pos0]);
   Inc(Pos0);
  End;
  If Pr^.N >= PSMAXCODE - 2 Then Begin Dispose(Pr); Exit; End;
  If (Tok = 'if') Or (Tok = 'ifelse') Then Begin
   If Tok = 'if' Then Begin
    If NC < 1 Then Begin Dispose(Pr); Exit; End;
    Dec(NC);
    Pr^.Ins[ClosedSt[NC]].Op := 100;
    Pr^.Ins[ClosedSt[NC]].V := Pr^.N;
   End
   Else Begin
    If NC < 2 Then Begin Dispose(Pr); Exit; End;
    Dec(NC, 2);
    Pr^.Ins[ClosedSt[NC]].Op := 100;
    Pr^.Ins[ClosedSt[NC]].V := ClosedSt[NC + 1] + 1;
    Pr^.Ins[ClosedSt[NC + 1]].Op := 101;
    Pr^.Ins[ClosedSt[NC + 1]].V := Pr^.N;
   End;
   Continue;
  End;
  Code := Pos(' ' + Tok + ' ', ' ' + PSOPS);
  If (Code > 0) And (Tok <> '') Then Begin
   { numéro d'ordre de l'opérateur }
   K := 1;
   K := 0;
   For I := 1 To Code Do If PSOPS[I] = ' ' Then Inc(K);
   Pr^.Ins[Pr^.N].Op := K + 1; Pr^.Ins[Pr^.N].V := 0;
   Inc(Pr^.N);
  End
  Else Begin
   Val(Tok, V, Err);
   If Err <> 0 Then V := 0;
   Pr^.Ins[Pr^.N].Op := 0; Pr^.Ins[Pr^.N].V := V;
   Inc(Pr^.N);
  End;
 End;
 If PSNProg < PSMAXPROG Then Begin Slot := PSNProg; Inc(PSNProg); End
 Else Begin
  Slot := PSNext; PSNext := (PSNext + 1) Mod PSMAXPROG;
  If PSProgs[Slot] <> Nil Then Dispose(PSProgs[Slot]);
 End;
 PSProgs[Slot] := Pr;
 PSCompile := Pr;
End;

Function PSIsInt(V: Real): Boolean;
Begin
 PSIsInt := Abs(V - Round(V)) < 1E-9;
End;

{ Exécute le programme : St en entrée = entrées, en sortie = résultats (SP éléments) }
Function PSRun(Pr: PPSProg; Var St: Array Of Real; Var SP: Integer): Boolean;
Var
 PC, Steps, I, J, N, Sh: Integer;
 A, B, T: Real;
 IA, IB: LongInt;
 Cnt: LongInt;
 Tmp: Array[0..63] Of Real;
Begin
 PSRun := False;
 PC := 0; Steps := 0;
 While PC < Pr^.N Do Begin
  Inc(Steps);
  If Steps > 30000 Then Exit;
  With Pr^.Ins[PC] Do Begin
   Case Op Of
    0: Begin If SP > High(St) Then Exit; St[SP] := V; Inc(SP); End;
    100: Begin
     If SP < 1 Then Exit;
     Dec(SP);
     If St[SP] = 0 Then Begin PC := Round(V); Continue; End;
    End;
    101: Begin PC := Round(V); Continue; End;
    102: ;
   Else
    Begin
     Case Op Of
      1: Begin If SP < 1 Then Exit; St[SP - 1] := Abs(St[SP - 1]); End;
      2: Begin If SP < 2 Then Exit; St[SP - 2] := St[SP - 2] + St[SP - 1]; Dec(SP); End;
      3: Begin
       If SP < 2 Then Exit;
       A := St[SP - 2]; B := St[SP - 1];
       T := FnAtan2(A, B) * 180 / Pi;
       If T < 0 Then T := T + 360;
       St[SP - 2] := T; Dec(SP);
      End;
      4: Begin If SP < 1 Then Exit; St[SP - 1] := FnCeil(St[SP - 1]); End;
      5: Begin If SP < 1 Then Exit; St[SP - 1] := Cos(St[SP - 1] * Pi / 180); End;
      6: Begin If SP < 1 Then Exit; St[SP - 1] := Trunc(St[SP - 1]); End;
      7: ;
      8: Begin
       If SP < 2 Then Exit;
       If St[SP - 1] = 0 Then St[SP - 2] := 0 Else St[SP - 2] := St[SP - 2] / St[SP - 1];
       Dec(SP);
      End;
      9: Begin
       If SP < 2 Then Exit;
       A := St[SP - 2]; B := St[SP - 1];
       If A < 0 Then T := 0 Else If A = 0 Then Begin If B = 0 Then T := 1 Else T := 0; End
       Else T := Exp(B * Ln(A));
       St[SP - 2] := T; Dec(SP);
      End;
      10: Begin If SP < 1 Then Exit; St[SP - 1] := FnFloor(St[SP - 1]); End;
      11: Begin
       If SP < 2 Then Exit;
       IB := Trunc(St[SP - 1]); IA := Trunc(St[SP - 2]);
       If IB = 0 Then St[SP - 2] := 0 Else St[SP - 2] := IA Div IB;
       Dec(SP);
      End;
      12: Begin If SP < 1 Then Exit; If St[SP - 1] > 0 Then St[SP - 1] := Ln(St[SP - 1]) Else St[SP - 1] := 0; End;
      13: Begin If SP < 1 Then Exit; If St[SP - 1] > 0 Then St[SP - 1] := Ln(St[SP - 1]) / Ln(10) Else St[SP - 1] := 0; End;
      14: Begin
       If SP < 2 Then Exit;
       IB := Trunc(St[SP - 1]); IA := Trunc(St[SP - 2]);
       If IB = 0 Then St[SP - 2] := 0 Else St[SP - 2] := IA Mod IB;
       Dec(SP);
      End;
      15: Begin If SP < 2 Then Exit; St[SP - 2] := St[SP - 2] * St[SP - 1]; Dec(SP); End;
      16: Begin If SP < 1 Then Exit; St[SP - 1] := -St[SP - 1]; End;
      17: Begin If SP < 1 Then Exit; St[SP - 1] := FnFloor(St[SP - 1] + 0.5); End;
      18: Begin If SP < 1 Then Exit; St[SP - 1] := Sin(St[SP - 1] * Pi / 180); End;
      19: Begin If SP < 1 Then Exit; If St[SP - 1] > 0 Then St[SP - 1] := Sqrt(St[SP - 1]) Else St[SP - 1] := 0; End;
      20: Begin If SP < 2 Then Exit; St[SP - 2] := St[SP - 2] - St[SP - 1]; Dec(SP); End;
      21: Begin If SP < 1 Then Exit; St[SP - 1] := Trunc(St[SP - 1]); End;
      22, 32, 34: Begin
       If SP < 2 Then Exit;
       A := St[SP - 2]; B := St[SP - 1];
       If PSIsInt(A) And PSIsInt(B) And ((Abs(A) > 1) Or (Abs(B) > 1)) Then Begin
        IA := Round(A); IB := Round(B);
        Case Op Of
         22: IA := IA And IB;
         32: IA := IA Or IB;
        Else IA := IA Xor IB;
        End;
        St[SP - 2] := IA;
       End
       Else Begin
        Case Op Of
         22: If (A <> 0) And (B <> 0) Then T := 1 Else T := 0;
         32: If (A <> 0) Or (B <> 0) Then T := 1 Else T := 0;
        Else If (A <> 0) <> (B <> 0) Then T := 1 Else T := 0;
        End;
        St[SP - 2] := T;
       End;
       Dec(SP);
      End;
      23: Begin
       If SP < 2 Then Exit;
       IA := Round(St[SP - 2]); Sh := Round(St[SP - 1]);
       If (Sh > 0) And (Sh < 31) Then IA := IA Shl Sh Else If (Sh < 0) And (Sh > -31) Then IA := IA Shr (-Sh);
       St[SP - 2] := IA; Dec(SP);
      End;
      24: Begin If SP < 2 Then Exit; If St[SP - 2] = St[SP - 1] Then T := 1 Else T := 0; St[SP - 2] := T; Dec(SP); End;
      25: Begin If SP > High(St) Then Exit; St[SP] := 0; Inc(SP); End;
      26: Begin If SP < 2 Then Exit; If St[SP - 2] >= St[SP - 1] Then T := 1 Else T := 0; St[SP - 2] := T; Dec(SP); End;
      27: Begin If SP < 2 Then Exit; If St[SP - 2] > St[SP - 1] Then T := 1 Else T := 0; St[SP - 2] := T; Dec(SP); End;
      28: Begin If SP < 2 Then Exit; If St[SP - 2] <= St[SP - 1] Then T := 1 Else T := 0; St[SP - 2] := T; Dec(SP); End;
      29: Begin If SP < 2 Then Exit; If St[SP - 2] < St[SP - 1] Then T := 1 Else T := 0; St[SP - 2] := T; Dec(SP); End;
      30: Begin If SP < 2 Then Exit; If St[SP - 2] <> St[SP - 1] Then T := 1 Else T := 0; St[SP - 2] := T; Dec(SP); End;
      31: Begin
       If SP < 1 Then Exit;
       A := St[SP - 1];
       If (A = 0) Or (A = 1) Then St[SP - 1] := 1 - A Else St[SP - 1] := Not Round(A);
      End;
      33: Begin If SP > High(St) Then Exit; St[SP] := 1; Inc(SP); End;
      35: Begin
       If SP < 1 Then Exit;
       N := Round(St[SP - 1]); Dec(SP);
       If (N < 0) Or (N > SP) Or (SP + N > High(St) + 1) Then Exit;
       For I := 0 To N - 1 Do St[SP + I] := St[SP - N + I];
       Inc(SP, N);
      End;
      36: Begin If (SP < 1) Or (SP > High(St)) Then Exit; St[SP] := St[SP - 1]; Inc(SP); End;
      37: Begin If SP < 2 Then Exit; T := St[SP - 1]; St[SP - 1] := St[SP - 2]; St[SP - 2] := T; End;
      38: Begin
       If SP < 1 Then Exit;
       N := Round(St[SP - 1]); Dec(SP);
       If (N < 0) Or (N >= SP) Then Exit;
       St[SP] := St[SP - 1 - N]; Inc(SP);
      End;
      39: Begin If SP < 1 Then Exit; Dec(SP); End;
      40: Begin
       If SP < 2 Then Exit;
       J := Round(St[SP - 1]); N := Round(St[SP - 2]); Dec(SP, 2);
       If (N < 1) Or (N > SP) Or (N > 64) Then Exit;
       J := J Mod N; If J < 0 Then J := J + N;
       For I := 0 To N - 1 Do Tmp[(I + J) Mod N] := St[SP - N + I];
       For I := 0 To N - 1 Do St[SP - N + I] := Tmp[I];
      End;
     Else Exit;
     End;
    End;
   End;
  End;
  Inc(PC);
 End;
 PSRun := True;
End;

{ Charge (avec cache) le flux d'échantillons d'une fonction de type 0 }
Function SampLoad(Num: LongInt; Var Data: PBigBytes; Var Len: LongInt): Boolean;
Var
 I, Slot: Integer;
 L: LongInt;
 Buf: PBigBytes;
Begin
 SampLoad := False;
 For I := 0 To 3 Do
  If (SampCache[I].Num = Num) And (SampCache[I].Data <> Nil) Then Begin
   Data := SampCache[I].Data; Len := SampCache[I].Len; SampLoad := True; Exit;
  End;
 If FnBuf = Nil Then GetMem(FnBuf, BUFSZ + 16);
 SrcMode := 0;
 If Not LoadStream(Num, FnBuf, L) Then Exit;
 If L < 1 Then Exit;
 GetMem(Buf, L + 16);
 If Buf = Nil Then Exit;
 Move(FnBuf^[0], Buf^[0], L);
 Slot := SampNext; SampNext := (SampNext + 1) And 3;
 If SampCache[Slot].Data <> Nil Then FreeMem(SampCache[Slot].Data, SampCache[Slot].Len + 16);
 SampCache[Slot].Num := Num; SampCache[Slot].Data := Buf; SampCache[Slot].Len := L;
 Data := Buf; Len := L;
 SampLoad := True;
End;

{ Évalue une fonction PDF (entrées Inp, NIn valeurs) ; retourne le nombre de sorties (0 : échec) }
Function EvalFnM(P: LongInt; Const Inp: Array Of Real; NIn: Integer; Var Out: Array Of Real; Depth: Integer): Integer;
Var
 S: TSrcState;
 N, I, K, NO, N2, Tok, Typ, NC0, NC1, NB, NE, NFn, M, Bps, Corner, Idx: Integer;
 Q, Pos0: LongInt;
 C0, C1, Bn, En, Dm, Rg, Dc, Ec: Array[0..15] Of Real;
 Sz: Array[0..7] Of Real;
 FPos: Array[0..15] Of LongInt;
 Ex, Lo, Hi, E0, E1, R, T2, T, Wt, Acc, Fr: Real;
 Sub: Array[0..7] Of Real;
 InA: Array[0..7] Of Real;
 Pr: PPSProg;
 St: Array[0..99] Of Real;
 SP: Integer;
 Data: PBigBytes;
 DLen, Off, BitP, Stride: LongInt;
 Fl: Array[0..7] Of LongInt;
 Fw: Array[0..7] Of Real;
 CI: Array[0..3] Of LongInt;
 NumObj: Integer;
 Function SampleAt(Const Ix: Array Of LongInt; O: Integer): Real;
 Var
  II: Integer;
  Pos, Mul: LongInt;
  V, Mx: LongInt;
  BP: Int64;
 Begin
  Pos := 0; Mul := 1;
  For II := 0 To M - 1 Do Begin Pos := Pos + Ix[II] * Mul; Mul := Mul * Round(Sz[II]); End;
  BP := (Int64(Pos) * NO + O) * Bps;
  If (BP Shr 3) + 4 > DLen Then Begin SampleAt := 0; Exit; End;
  Case Bps Of
   8: V := Data^[BP Shr 3];
   16: V := Data^[BP Shr 3] * 256 + Data^[(BP Shr 3) + 1];
   32: V := ((Data^[BP Shr 3] * 256 + Data^[(BP Shr 3) + 1]) * 256 + Data^[(BP Shr 3) + 2]) * 256 + Data^[(BP Shr 3) + 3];
  Else
   V := (Data^[BP Shr 3] Shr (8 - Bps - (BP And 7))) And ((1 Shl Bps) - 1);
  End;
  If Bps = 32 Then Mx := 2147483647 Else Mx := (1 Shl Bps) - 1;
  SampleAt := V / Mx;
 End;
Begin
 EvalFnM := 0;
 If (P < 0) Or (Depth > 4) Then Exit;
 SaveSrc(S);
 NumObj := RefAt(P);
 N := NumObj;
 If N > 0 Then P := EnterObj(N);
 If P < 0 Then Begin RestoreSrc(S); Exit; End;
 Q := P;
 Tok := NextTok(Q);
 If Tok = T_AB Then Begin
  K := 0;
  While K <= High(Out) Do Begin
   Pos0 := Q;
   Tok := NextTok(Q);
   If (Tok = T_AE) Or (Tok = T_EOF) Then Break;
   N2 := EvalFnM(Pos0, Inp, NIn, Sub, Depth + 1);
   If N2 > 0 Then Out[K] := Sub[0] Else Out[K] := 0;
   Inc(K);
   Q := Pos0;
   SkipValue(Q);
  End;
  RestoreSrc(S);
  EvalFnM := K;
  Exit;
 End;
 If Tok <> T_DB Then Begin RestoreSrc(S); Exit; End;
 Typ := ValInt(DictFind(P, 'FunctionType'), -1);
 NC0 := 0; NB := 0; NE := 0;
 FillChar(Dm, SizeOf(Dm), 0);
 NO := ReadNums(DictFind(P, 'Domain'), Dm, 16);
 M := NO Div 2;
 If M < 1 Then Begin Dm[0] := 0; Dm[1] := 1; M := 1; End;
 For I := 0 To NIn - 1 Do
  If I < 8 Then Begin
   InA[I] := Inp[I];
   If I < M Then Begin
    If InA[I] < Dm[2 * I] Then InA[I] := Dm[2 * I];
    If InA[I] > Dm[2 * I + 1] Then InA[I] := Dm[2 * I + 1];
   End;
  End;
 T := InA[0];
 If Typ = 2 Then Begin
  NC0 := ReadNums(DictFind(P, 'C0'), C0, 16);
  If NC0 < 1 Then Begin C0[0] := 0; NC0 := 1; End;
  NC1 := ReadNums(DictFind(P, 'C1'), C1, 16);
  If NC1 < 1 Then Begin C1[0] := 1; NC1 := 1; End;
  Ex := ValNum(DictFind(P, 'N'), 1);
  If T <= 0 Then Begin If Ex = 0 Then R := 1 Else R := 0; End
  Else R := Exp(Ex * Ln(T));
  NO := NC0;
  If NC1 < NO Then NO := NC1;
  If NO > High(Out) + 1 Then NO := High(Out) + 1;
  For I := 0 To NO - 1 Do Out[I] := C0[I] + R * (C1[I] - C0[I]);
  RestoreSrc(S);
  EvalFnM := NO;
  Exit;
 End;
 If Typ = 3 Then Begin
  NFn := 0;
  Q := DictFind(P, 'Functions');
  If Q >= 0 Then Begin
   If NextTok(Q) = T_AB Then
    While NFn < 16 Do Begin
     Pos0 := Q;
     Tok := NextTok(Q);
     If (Tok = T_AE) Or (Tok = T_EOF) Then Break;
     FPos[NFn] := Pos0;
     Inc(NFn);
     Q := Pos0;
     SkipValue(Q);
    End;
  End;
  NB := ReadNums(DictFind(P, 'Bounds'), Bn, 15);
  NE := ReadNums(DictFind(P, 'Encode'), En, 16);
  If NFn < 1 Then Begin RestoreSrc(S); Exit; End;
  K := 0;
  While (K < NB) And (T >= Bn[K]) Do Inc(K);
  If K >= NFn Then K := NFn - 1;
  If K = 0 Then Lo := Dm[0] Else Lo := Bn[K - 1];
  If (K >= NB) Or (K = NFn - 1) Then Hi := Dm[1] Else Hi := Bn[K];
  E0 := 0; E1 := 1;
  If 2 * K + 1 < NE Then Begin E0 := En[2 * K]; E1 := En[2 * K + 1]; End;
  If Hi = Lo Then T2 := E0 Else T2 := E0 + (T - Lo) * (E1 - E0) / (Hi - Lo);
  Sub[0] := T2;
  N2 := EvalFnM(FPos[K], Sub, 1, Out, Depth + 1);
  RestoreSrc(S);
  EvalFnM := N2;
  Exit;
 End;
 If (Typ = 4) Or (Typ = 0) Then Begin
  FillChar(Rg, SizeOf(Rg), 0);
  NO := ReadNums(DictFind(P, 'Range'), Rg, 16) Div 2;
  If (NO < 1) Or (NumObj <= 0) Then Begin RestoreSrc(S); Exit; End;
  If NO > High(Out) + 1 Then NO := High(Out) + 1;
  If Typ = 4 Then Begin
   RestoreSrc(S);
   Pr := PSCompile(NumObj);
   RestoreSrc(S);
   If Pr = Nil Then Exit;
   SP := 0;
   For I := 0 To M - 1 Do Begin St[SP] := InA[I]; Inc(SP); End;
   If Not PSRun(Pr, St, SP) Then Exit;
   If SP < NO Then Exit;
   For I := 0 To NO - 1 Do Begin
    R := St[SP - NO + I];
    If R < Rg[2 * I] Then R := Rg[2 * I];
    If R > Rg[2 * I + 1] Then R := Rg[2 * I + 1];
    Out[I] := R;
   End;
   EvalFnM := NO;
   Exit;
  End;
  { type 0 : échantillonnée, interpolation multilinéaire }
  If M > 4 Then Begin RestoreSrc(S); Exit; End;
  If ReadNums(DictFind(P, 'Size'), Sz, 8) < M Then Begin RestoreSrc(S); Exit; End;
  Bps := ValInt(DictFind(P, 'BitsPerSample'), 8);
  If (Bps <> 1) And (Bps <> 2) And (Bps <> 4) And (Bps <> 8) And (Bps <> 12) And (Bps <> 16) And (Bps <> 24) And (Bps <> 32) Then Begin RestoreSrc(S); Exit; End;
  If (Bps = 12) Or (Bps = 24) Then Begin RestoreSrc(S); Exit; End;
  For I := 0 To M - 1 Do Begin Ec[2 * I] := 0; Ec[2 * I + 1] := Sz[I] - 1; End;
  ReadNums(DictFind(P, 'Encode'), Ec, 2 * M);
  For I := 0 To NO - 1 Do Begin Dc[2 * I] := Rg[2 * I]; Dc[2 * I + 1] := Rg[2 * I + 1]; End;
  ReadNums(DictFind(P, 'Decode'), Dc, 2 * NO);
  RestoreSrc(S);
  If Not SampLoad(NumObj, Data, DLen) Then Begin RestoreSrc(S); Exit; End;
  RestoreSrc(S);
  For I := 0 To M - 1 Do Begin
   If Dm[2 * I + 1] = Dm[2 * I] Then R := Ec[2 * I]
   Else R := Ec[2 * I] + (InA[I] - Dm[2 * I]) * (Ec[2 * I + 1] - Ec[2 * I]) / (Dm[2 * I + 1] - Dm[2 * I]);
   If R < 0 Then R := 0;
   If R > Sz[I] - 1 Then R := Sz[I] - 1;
   Fl[I] := Trunc(R);
   If Fl[I] >= Round(Sz[I]) - 1 Then Fl[I] := IMax(0, Round(Sz[I]) - 2);
   Fw[I] := R - Fl[I];
   If Round(Sz[I]) < 2 Then Begin Fl[I] := 0; Fw[I] := 0; End;
  End;
  For K := 0 To NO - 1 Do Begin
   Acc := 0;
   For Corner := 0 To (1 Shl M) - 1 Do Begin
    Wt := 1;
    For I := 0 To 3 Do CI[I] := 0;
    For I := 0 To M - 1 Do Begin
     If (Corner Shr I) And 1 = 1 Then Begin Wt := Wt * Fw[I]; CI[I] := IMin(Fl[I] + 1, Round(Sz[I]) - 1); End
     Else Begin Wt := Wt * (1 - Fw[I]); CI[I] := Fl[I]; End;
    End;
    If Wt > 0 Then Acc := Acc + Wt * SampleAt(CI, K);
   End;
   R := Dc[2 * K] + Acc * (Dc[2 * K + 1] - Dc[2 * K]);
   If R < Rg[2 * K] Then R := Rg[2 * K];
   If R > Rg[2 * K + 1] Then R := Rg[2 * K + 1];
   Out[K] := R;
  End;
  EvalFnM := NO;
  Exit;
 End;
 RestoreSrc(S);
End;

Function EvalFn(P: LongInt; T: Real; Var Out: Array Of Real; Depth: Integer): Integer;
Var
 A: Array[0..0] Of Real;
Begin
 A[0] := T;
 EvalFn := EvalFnM(P, A, 1, Out, Depth);
End;
{$ENDIF}

{$IFDEF FPC}
Const
 CSMAXC = 40;

Type
 PLongArr = ^TLongArr2;
 TLongArr2 = Array[0..33554431] Of LongInt;
 TCSDesc = Record
  Kind: Integer;       { 1 gris, 3 RVB, 4 CMJN, 5 indexé, 6 Lab, 7 teinte (Separation / DeviceN), 8 motif }
  N: Integer;          { nombre de composantes }
  AltKind: Integer;    { espace de base d'une teinte : 1, 3, 4 ou 6 }
  Hi: Integer;         { indexé : valeur maximale }
  PalN: Integer;       { indexé : octets RVB (3 par entrée) }
  Pal: PBigBytes;
  Xw, Yw, Zw: Real;    { Lab : point blanc }
  Amin, Amax, Bmin, Bmax: Real;
  Lut: PLongArr;       { teinte : table RVB échantillonnée }
  LutG: Integer;       { pas de la table par composante }
  NoPaint: Boolean;    { Separation /None }
 End;

 TCSCacheEnt = Record
  Key: String[80];
  D: TCSDesc;
  Used: Boolean;
 End;

Var
 CSCache: Array[0..CSMAXC - 1] Of TCSCacheEnt;

Procedure CSDescFree(Var D: TCSDesc);
Begin
 If D.Pal <> Nil Then Begin FreeMem(D.Pal, D.PalN + 16); D.Pal := Nil; End;
 If D.Lut <> Nil Then Begin FreeMem(D.Lut, LongInt(D.LutG) * 0 + D.PalN + 16); D.Lut := Nil; End;
End;

Procedure CSCacheFree;
Var
 I: Integer;
Begin
 For I := 0 To CSMAXC - 1 Do
  If CSCache[I].Used Then Begin
   If CSCache[I].D.Pal <> Nil Then FreeMem(CSCache[I].D.Pal, CSCache[I].D.PalN + 16);
   If CSCache[I].D.Lut <> Nil Then FreeMem(CSCache[I].D.Lut, CSCache[I].D.PalN + 16);
   CSCache[I].D.Pal := Nil; CSCache[I].D.Lut := Nil;
   CSCache[I].Used := False;
  End;
End;

Function CsClamp01(V: Real): Real;
Begin
 If V < 0 Then V := 0;
 If V > 1 Then V := 1;
 CsClamp01 := V;
End;

Function CsToByte(V: Real): LongInt;
Begin
 CsToByte := Round(CsClamp01(V) * 255);
End;

Function CsGamma(V: Real): Real;
Begin
 If V <= 0.0031308 Then CsGamma := 12.92 * V
 Else CsGamma := 1.055 * Exp(Ln(V) / 2.4) - 0.055;
End;

{ CMJN -> RVB : approximation polynomiale proche du rendu des profils offset (SWOP) }
Function CmykPoly(C, M, Y, K: Real): LongInt;
Var
 R, G, B: Real;
Begin
 C := CsClamp01(C); M := CsClamp01(M); Y := CsClamp01(Y); K := CsClamp01(K);
 R := 255 + C * (-4.387332384609988 * C + 54.48615194189176 * M + 18.82290502165302 * Y + 212.25662451639585 * K - 285.2331026137004) +
      M * (1.7149763477362134 * M - 5.6096736904047315 * Y - 17.873870861415444 * K - 5.497006427196366) +
      Y * (-2.5217340131683033 * Y - 21.248923337353073 * K + 17.5119270841813) +
      K * (-21.86122147463605 * K - 189.48180835922747);
 G := 255 + C * (8.841041422036149 * C + 60.118027045597366 * M + 6.871425592049007 * Y + 31.159100130055922 * K - 79.2970844816548) +
      M * (-15.310361306967817 * M + 17.575251261109482 * Y + 131.35250912493976 * K - 190.9453302588951) +
      Y * (4.444339102852739 * Y + 9.8632861493405 * K - 24.86741582555878) +
      K * (-20.737325471181034 * K - 187.80453709719578);
 B := 255 + C * (0.8842522430003296 * C + 8.078677503112928 * M + 30.89978309703729 * Y - 0.23883238689178934 * K - 14.183576799673286) +
      M * (10.49593273432072 * M + 63.02378494754052 * Y + 50.606957656360734 * K - 112.23884253719248) +
      Y * (0.03296041114873217 * Y + 115.60384449646641 * K - 193.58209356861505) +
      K * (-22.33816807309886 * K - 180.12613974708367);
 If R < 0 Then R := 0; If R > 255 Then R := 255;
 If G < 0 Then G := 0; If G > 255 Then G := 255;
 If B < 0 Then B := 0; If B > 255 Then B := 255;
 CmykPoly := RGBOf(Round(R), Round(G), Round(B));
End;

Function LabToRgb(L, A, B: Real; Const D: TCSDesc): LongInt;
Var
 Fy, Fx, Fz, X, Y, Z, R, G, Bl: Real;
 Function Gf(T: Real): Real;
 Begin
  If T > 6 / 29 Then Gf := T * T * T Else Gf := 3 * (6 / 29) * (6 / 29) * (T - 4 / 29);
 End;
Begin
 If A < D.Amin Then A := D.Amin;
 If A > D.Amax Then A := D.Amax;
 If B < D.Bmin Then B := D.Bmin;
 If B > D.Bmax Then B := D.Bmax;
 If L < 0 Then L := 0;
 If L > 100 Then L := 100;
 Fy := (L + 16) / 116; Fx := Fy + A / 500; Fz := Fy - B / 200;
 { adaptation vers le blanc D65 par mise à l'échelle }
 X := Gf(Fx) * 0.9505; Y := Gf(Fy); Z := Gf(Fz) * 1.089;
 R := 3.2406 * X - 1.5372 * Y - 0.4986 * Z;
 G := -0.9689 * X + 1.8758 * Y + 0.0415 * Z;
 Bl := 0.0557 * X - 0.2040 * Y + 1.0570 * Z;
 LabToRgb := RGBOf(CsToByte(CsGamma(CsClamp01(R))), CsToByte(CsGamma(CsClamp01(G))), CsToByte(CsGamma(CsClamp01(Bl))));
End;

{ Composantes d'un espace de base (1 gris, 3 RVB, 4 CMJN, 6 Lab) -> RVB }
Function CompToRgb(Kind: Integer; Const C: Array Of Real; Const D: TCSDesc): LongInt;
Begin
 Case Kind Of
  1: CompToRgb := RGBOf(CsToByte(C[0]), CsToByte(C[0]), CsToByte(C[0]));
  3: CompToRgb := RGBOf(CsToByte(C[0]), CsToByte(C[1]), CsToByte(C[2]));
  4: CompToRgb := CmykPoly(C[0], C[1], C[2], C[3]);
  6: CompToRgb := LabToRgb(C[0], C[1], C[2], D);
 Else CompToRgb := 0;
 End;
End;

{ Couleur RVB d'un jeu de composantes dans l'espace D }
Function ColorToRgb(Const D: TCSDesc; Const C: Array Of Real; N: Integer): LongInt;
Var
 I, Idx, G, Mul: LongInt;
 Q: Real;
 Cc: Array[0..3] Of Real;
Begin
 ColorToRgb := 0;
 Case D.Kind Of
  1, 3, 4, 6: Begin
   For I := 0 To 3 Do If I < N Then Cc[I] := C[I] Else Cc[I] := 0;
   ColorToRgb := CompToRgb(D.Kind, Cc, D);
  End;
  5: Begin
   If N < 1 Then Exit;
   Idx := Round(C[0]);
   If Idx < 0 Then Idx := 0;
   If Idx > D.Hi Then Idx := D.Hi;
   If (D.Pal <> Nil) And (Idx * 3 + 2 < D.PalN) Then
    ColorToRgb := RGBOf(D.Pal^[Idx * 3], D.Pal^[Idx * 3 + 1], D.Pal^[Idx * 3 + 2]);
  End;
  7: Begin
   If D.Lut = Nil Then Begin
    { teinte non évaluable : gris proportionnel à la plus forte composante }
    Q := 0;
    For I := 0 To N - 1 Do If C[I] > Q Then Q := C[I];
    ColorToRgb := RGBOf(CsToByte(1 - Q), CsToByte(1 - Q), CsToByte(1 - Q));
    Exit;
   End;
   G := D.LutG; Idx := 0; Mul := 1;
   For I := 0 To D.N - 1 Do Begin
    If I < N Then Q := CsClamp01(C[I]) Else Q := 0;
    Idx := Idx + Round(Q * (G - 1)) * Mul;
    Mul := Mul * G;
   End;
   ColorToRgb := D.Lut^[Idx];
  End;
 End;
End;

{ Lit les paramètres d'un dictionnaire Lab }
Procedure CSLabParams(P: LongInt; Var D: TCSDesc);
Var
 A: Array[0..5] Of Real;
Begin
 D.Xw := 0.9642; D.Yw := 1; D.Zw := 0.8249;
 D.Amin := -100; D.Amax := 100; D.Bmin := -100; D.Bmax := 100;
 If P < 0 Then Exit;
 If ReadNums(DictFind(P, 'WhitePoint'), A, 3) = 3 Then Begin D.Xw := A[0]; D.Yw := A[1]; D.Zw := A[2]; End;
 If ReadNums(DictFind(P, 'Range'), A, 4) = 4 Then Begin D.Amin := A[0]; D.Amax := A[1]; D.Bmin := A[2]; D.Bmax := A[3]; End;
End;

Function ParseCSDesc(V: LongInt; Depth: Integer; Var D: TCSDesc): Boolean;
Var
 S: TSrcState;
 N, T, I, K, NNames, G, Tot, Mul, J: Integer;
 Q, Q2, FnPos, AltPos, P2: LongInt;
 Nm: String;
 Alt: TCSDesc;
 L: LongInt;
 Inp: Array[0..7] Of Real;
 Out: Array[0..7] Of Real;
 NO: Integer;
 Hi: LongInt;
 Rgb: LongInt;
 Base: TCSDesc;
 Idx: LongInt;
 Comp: Array[0..3] Of Real;
Begin
 ParseCSDesc := False;
 FillChar(D, SizeOf(D), 0);
 If (V < 0) Or (Depth > 3) Then Exit;
 SaveSrc(S);
 N := RefAt(V);
 If N > 0 Then V := EnterObj(N);
 If V < 0 Then Begin RestoreSrc(S); Exit; End;
 Q := V;
 T := NextTok(Q);
 If T = T_NAME Then Begin
  Nm := TokS;
  If (Nm = 'DeviceGray') Or (Nm = 'G') Or (Nm = 'CalGray') Then Begin D.Kind := 1; D.N := 1; ParseCSDesc := True; End
  Else If (Nm = 'DeviceRGB') Or (Nm = 'RGB') Or (Nm = 'CalRGB') Then Begin D.Kind := 3; D.N := 3; ParseCSDesc := True; End
  Else If (Nm = 'DeviceCMYK') Or (Nm = 'CMYK') Then Begin D.Kind := 4; D.N := 4; ParseCSDesc := True; End
  Else If Nm = 'Pattern' Then Begin D.Kind := 8; D.N := 0; ParseCSDesc := True; End;
  RestoreSrc(S);
  Exit;
 End;
 If T <> T_AB Then Begin RestoreSrc(S); Exit; End;
 T := NextTok(Q);
 If T <> T_NAME Then Begin RestoreSrc(S); Exit; End;
 Nm := TokS;
 If Nm = 'CalGray' Then Begin D.Kind := 1; D.N := 1; ParseCSDesc := True; End
 Else If Nm = 'CalRGB' Then Begin D.Kind := 3; D.N := 3; ParseCSDesc := True; End
 Else If (Nm = 'DeviceGray') Or (Nm = 'G') Then Begin D.Kind := 1; D.N := 1; ParseCSDesc := True; End
 Else If (Nm = 'DeviceRGB') Or (Nm = 'RGB') Then Begin D.Kind := 3; D.N := 3; ParseCSDesc := True; End
 Else If (Nm = 'DeviceCMYK') Or (Nm = 'CMYK') Then Begin D.Kind := 4; D.N := 4; ParseCSDesc := True; End
 Else If Nm = 'Lab' Then Begin
  D.Kind := 6; D.N := 3;
  Q2 := Q;
  CSLabParams(Q2, D);
  ParseCSDesc := True;
 End
 Else If Nm = 'ICCBased' Then Begin
  N := RefAt(Q);
  K := 3;
  If N > 0 Then Begin
   P2 := EnterObj(N);
   If P2 >= 0 Then K := ValInt(DictFind(P2, 'N'), 3);
  End;
  If K = 1 Then D.Kind := 1 Else If K = 4 Then D.Kind := 4 Else D.Kind := 3;
  D.N := D.Kind;
  ParseCSDesc := True;
 End
 Else If Nm = 'Pattern' Then Begin D.Kind := 8; D.N := 0; ParseCSDesc := True; End
 Else If (Nm = 'Indexed') Or (Nm = 'I') Then Begin
  Q2 := Q;
  If ParseCSDesc(Q2, Depth + 1, Base) Then Begin
   If (Base.Kind = 5) Or (Base.Kind = 8) Then Begin CSDescFree(Base); RestoreSrc(S); Exit; End;
   SkipValue(Q);
   If NextTok(Q) = T_NUM Then Begin
    Hi := Round(TokR);
    If Hi > 255 Then Hi := 255;
    If Hi < 0 Then Hi := 0;
    D.Kind := 5; D.N := 1; D.Hi := Hi;
    D.PalN := (Hi + 1) * 3;
    GetMem(D.Pal, D.PalN + 16);
    FillChar(D.Pal^, D.PalN + 16, 0);
    { table de couleurs : flux ou chaîne }
    N := RefAt(Q);
    L := 0;
    If N > 0 Then Begin
     SrcMode := 0;
     If LoadStream(N, TuBuf, L) Then Else L := 0;
    End
    Else If NextTok(Q) = T_STR Then Begin
     L := StrLen;
     If L > 768 Then L := 768;
     Move(StrBuf[0], TuBuf^[0], L);
    End;
    For I := 0 To Hi Do Begin
     For J := 0 To 3 Do Comp[J] := 0;
     For J := 0 To Base.N - 1 Do
      If I * Base.N + J < L Then Comp[J] := TuBuf^[I * Base.N + J] / 255 Else Comp[J] := 0;
     If Base.Kind = 6 Then Begin
      Comp[0] := Comp[0] * 100;
      Comp[1] := Base.Amin + Comp[1] * (Base.Amax - Base.Amin);
      Comp[2] := Base.Bmin + Comp[2] * (Base.Bmax - Base.Bmin);
     End;
     If Base.Kind = 7 Then Rgb := ColorToRgb(Base, Comp, Base.N)
     Else Rgb := CompToRgb(Base.Kind, Comp, Base);
     D.Pal^[I * 3] := (Rgb Shr 16) And 255; D.Pal^[I * 3 + 1] := (Rgb Shr 8) And 255; D.Pal^[I * 3 + 2] := Rgb And 255;
    End;
    D.AltKind := Base.Kind;
    CSDescFree(Base);
    ParseCSDesc := True;
   End
   Else CSDescFree(Base);
  End;
 End
 Else If (Nm = 'Separation') Or (Nm = 'DeviceN') Then Begin
  NNames := 1;
  If Nm = 'Separation' Then Begin
   If NextTok(Q) = T_NAME Then If TokS = 'None' Then D.NoPaint := True;
  End
  Else Begin
   NNames := 0;
   If NextTok(Q) = T_AB Then
    While NNames < 32 Do Begin
     T := NextTok(Q);
     If T <> T_NAME Then Break;
     Inc(NNames);
    End;
  End;
  If NNames < 1 Then Begin RestoreSrc(S); Exit; End;
  AltPos := Q;
  Q2 := Q;
  SkipValue(Q);
  FnPos := Q;
  If ParseCSDesc(Q2, Depth + 1, Alt) Then Begin
   If Alt.Kind In [1, 3, 4, 6] Then Begin
    D.Kind := 7; D.N := NNames; D.AltKind := Alt.Kind;
    D.Xw := Alt.Xw; D.Yw := Alt.Yw; D.Zw := Alt.Zw;
    D.Amin := Alt.Amin; D.Amax := Alt.Amax; D.Bmin := Alt.Bmin; D.Bmax := Alt.Bmax;
    CSDescFree(Alt);
    ParseCSDesc := True;
    If NNames <= 4 Then Begin
     Case NNames Of 1: G := 256; 2: G := 64; 3: G := 24; Else G := 12; End;
     Tot := 1;
     For I := 1 To NNames Do Tot := Tot * G;
     D.LutG := G;
     D.PalN := Tot * 4;
     GetMem(D.Lut, Tot * 4 + 16);
     If D.Lut <> Nil Then Begin
      For K := 0 To Tot - 1 Do Begin
       Mul := K;
       For I := 0 To NNames - 1 Do Begin
        Inp[I] := (Mul Mod G) / (G - 1);
        Mul := Mul Div G;
       End;
       FillChar(Out, SizeOf(Out), 0);
       NO := EvalFnM(FnPos, Inp, NNames, Out, 0);
       If NO < 1 Then Begin
        { fonction non évaluable : gris proportionnel }
        Out[0] := 1 - Inp[0]; Out[1] := Out[0]; Out[2] := Out[0]; D.AltKind := 3;
       End;
       D.Lut^[K] := CompToRgb(D.AltKind, Out, D);
      End;
     End;
    End;
   End
   Else CSDescFree(Alt);
  End;
 End;
 RestoreSrc(S);
End;

{ Couleur initiale d'un espace de couleurs }
Function CSInitialRgb(Const D: TCSDesc): LongInt;
Var
 C: Array[0..7] Of Real;
 I: Integer;
Begin
 CSInitialRgb := 0;
 If D.Kind = 7 Then Begin
  For I := 0 To 7 Do C[I] := 1;
  CSInitialRgb := ColorToRgb(D, C, D.N);
 End;
End;

{ Espace de couleurs de ressource (ou nom d'appareil) : indice dans CSCache, -1 si échec }
Function CSByName(Const Name: String): Integer;
Var
 I, Free: Integer;
 Key: String;
 S: TSrcState;
 P, Num: LongInt;
 D: TCSDesc;
Begin
 CSByName := -1;
 If NRes > 0 Then Key := Name + '@' + IStr(ResNodes[NRes - 1]) Else Key := Name;
 Free := -1;
 For I := 0 To CSMAXC - 1 Do Begin
  If CSCache[I].Used And (CSCache[I].Key = Key) Then Begin CSByName := I; Exit; End;
  If (Not CSCache[I].Used) And (Free < 0) Then Free := I;
 End;
 If Free < 0 Then Begin CSCacheFree; Free := 0; End;
 SaveSrc(S);
 P := FindRes('ColorSpace', Name, Num);
 If P >= 0 Then Begin
  If ParseCSDesc(P, 0, D) Then Begin
   CSCache[Free].Key := Key;
   CSCache[Free].D := D;
   CSCache[Free].Used := True;
   CSByName := Free;
  End;
 End;
 RestoreSrc(S);
End;
{$ENDIF}
{$IFDEF FPC}
{ ---------------------------------------------------------------------- }
{ Décodeur CCITT : Groupe 3 (1D et 2D) et Groupe 4                         }
{ ---------------------------------------------------------------------- }

Const
 CCWhite: Array[0..63] Of String[8] = (
  '00110101', '000111', '0111', '1000', '1011', '1100', '1110', '1111',
  '10011', '10100', '00111', '01000', '001000', '000011', '110100', '110101',
  '101010', '101011', '0100111', '0001100', '0001000', '0010111', '0000011', '0000100',
  '0101000', '0101011', '0010011', '0100100', '0011000', '00000010', '00000011', '00011010',
  '00011011', '00010010', '00010011', '00010100', '00010101', '00010110', '00010111', '00101000',
  '00101001', '00101010', '00101011', '00101100', '00101101', '00000100', '00000101', '00001010',
  '00001011', '01010010', '01010011', '01010100', '01010101', '00100100', '00100101', '01011000',
  '01011001', '01011010', '01011011', '01001010', '01001011', '00110010', '00110011', '00110100');
 CCWhiteMk: Array[1..27] Of String[9] = (
  '11011', '10010', '010111', '0110111', '00110110', '00110111', '01100100', '01100101',
  '01101000', '01100111', '011001100', '011001101', '011010010', '011010011', '011010100', '011010101',
  '011010110', '011010111', '011011000', '011011001', '011011010', '011011011', '010011000', '010011001',
  '010011010', '011000', '010011011');
 CCBlack: Array[0..63] Of String[12] = (
  '0000110111', '010', '11', '10', '011', '0011', '0010', '00011',
  '000101', '000100', '0000100', '0000101', '0000111', '00000100', '00000111', '000011000',
  '0000010111', '0000011000', '0000001000', '00001100111', '00001101000', '00001101100', '00000110111', '00000101000',
  '00000010111', '00000011000', '000011001010', '000011001011', '000011001100', '000011001101', '000001101000', '000001101001',
  '000001101010', '000001101011', '000011010010', '000011010011', '000011010100', '000011010101', '000011010110', '000011010111',
  '000001101100', '000001101101', '000011011010', '000011011011', '000001010100', '000001010101', '000001010110', '000001010111',
  '000001100100', '000001100101', '000001010010', '000001010011', '000000100100', '000000110111', '000000111000', '000000100111',
  '000000101000', '000001011000', '000001011001', '000000101011', '000000101100', '000001011010', '000001100110', '000001100111');
 CCBlackMk: Array[1..27] Of String[13] = (
  '0000001111', '000011001000', '000011001001', '000001011011', '000000110011', '000000110100', '000000110101', '0000001101100',
  '0000001101101', '0000001001010', '0000001001011', '0000001001100', '0000001001101', '0000001110010', '0000001110011', '0000001110100',
  '0000001110101', '0000001110110', '0000001110111', '0000001010010', '0000001010011', '0000001010100', '0000001010101', '0000001011010',
  '0000001011011', '0000001100100', '0000001100101');
 CCExt: Array[0..12] Of String[12] = (
  '00000001000', '00000001100', '00000001101', '000000010010', '000000010011', '000000010100', '000000010101',
  '000000010110', '000000010111', '000000011100', '000000011101', '000000011110', '000000011111');

Type
 TCCEnt = Record
  Run: SmallInt;
  Len: Byte;
 End;

Var
 CCTab: Array[0..1, 0..8191] Of TCCEnt;
 CC2Mode: Array[0..127] Of ShortInt;
 CC2Len: Array[0..127] Of Byte;
 CCReady: Boolean;
 CCSrc: PBigBytes;
 CCLen: LongInt;
 CCBit: LongInt;

Procedure CCAdd(Col: Integer; Const Bits: String; Run: Integer);
Var
 L, I, V, Base, N: Integer;
Begin
 L := Length(Bits);
 V := 0;
 For I := 1 To L Do V := V * 2 + (Ord(Bits[I]) - 48);
 Base := V Shl (13 - L);
 For N := 0 To (1 Shl (13 - L)) - 1 Do Begin
  CCTab[Col, Base + N].Run := Run;
  CCTab[Col, Base + N].Len := L;
 End;
End;

Procedure CC2Add(Const Bits: String; Mode: Integer);
Var
 L, I, V, Base, N: Integer;
Begin
 L := Length(Bits);
 V := 0;
 For I := 1 To L Do V := V * 2 + (Ord(Bits[I]) - 48);
 Base := V Shl (7 - L);
 For N := 0 To (1 Shl (7 - L)) - 1 Do Begin
  CC2Mode[Base + N] := Mode;
  CC2Len[Base + N] := L;
 End;
End;

Procedure CCInit;
Var
 I: Integer;
Begin
 If CCReady Then Exit;
 FillChar(CCTab, SizeOf(CCTab), 0);
 FillChar(CC2Len, SizeOf(CC2Len), 0);
 For I := 0 To 63 Do Begin CCAdd(0, CCWhite[I], I); CCAdd(1, CCBlack[I], I); End;
 For I := 1 To 27 Do Begin CCAdd(0, CCWhiteMk[I], I * 64); CCAdd(1, CCBlackMk[I], I * 64); End;
 For I := 0 To 12 Do Begin CCAdd(0, CCExt[I], 1792 + I * 64); CCAdd(1, CCExt[I], 1792 + I * 64); End;
 { modes 2D : 0 passage, 1 horizontal, 2..8 vertical (delta = mode - 5) }
 CC2Add('0001', 0); CC2Add('001', 1);
 CC2Add('0000010', 2); CC2Add('000010', 3); CC2Add('010', 4); CC2Add('1', 5);
 CC2Add('011', 6); CC2Add('000011', 7); CC2Add('0000011', 8);
 CCReady := True;
End;

Function CCPeek(N: Integer): LongInt;
Var
 B: LongInt;
 W: Int64;
 Sh: Integer;
 Function G(P: LongInt): Int64;
 Begin
  If P < CCLen Then G := CCSrc^[P] Else G := 0;
 End;
Begin
 B := CCBit Shr 3;
 Sh := CCBit And 7;
 W := (G(B) Shl 24) Or (G(B + 1) Shl 16) Or (G(B + 2) Shl 8) Or G(B + 3);
 CCPeek := (W Shr (32 - Sh - N)) And ((Int64(1) Shl N) - 1);
End;

{ Longueur totale d'une course (0 ou 1 : blanc ou noir), -1 si code invalide }
Function CCRun(Col: Integer): Integer;
Var
 E: TCCEnt;
 Tot: Integer;
Begin
 Tot := 0;
 Repeat
  E := CCTab[Col, CCPeek(13)];
  If E.Len = 0 Then Begin CCRun := -1; Exit; End;
  Inc(CCBit, E.Len);
  Tot := Tot + E.Run;
 Until E.Run < 64;
 CCRun := Tot;
End;

{ Décode CCITT vers Dst (1 bit par pixel, lignes alignées sur l'octet).
  Blanc = 1 sauf si BlackIs1. Retourne le nombre de lignes décodées. }
Function CCITTDecode(Src: PBigBytes; SLen: LongInt; Cols, Rows, K: LongInt; BlackIs1, ByteAlign: Boolean;
                     Dst: PBigBytes): LongInt;
Var
 RowBytes, Rd, A0, A1, A2, B1, B2, N, Bj, J, X, Xs, Xe, M: LongInt;
 Col: Integer;
 Is2D, Err: Boolean;
 Ref, Cur, Tmp: ^LongInt;
 RefA, CurA: PBigBytes;
 R1, R2: Integer;
 Row: PBigBytes;
 Function CcRefAt(I: LongInt): LongInt;
 Begin
  CcRefAt := PLongInt(PByte(RefA) + I * 4)^;
 End;
 Procedure CurSet(I, V: LongInt);
 Begin
  PLongInt(PByte(CurA) + I * 4)^ := V;
 End;
Begin
 CCInit;
 CCSrc := Src; CCLen := SLen; CCBit := 0;
 CCITTDecode := 0;
 If (Cols < 1) Or (Cols > 65000) Or (Rows < 1) Then Exit;
 RowBytes := (Cols + 7) Div 8;
 If BlackIs1 Then FillChar(Dst^, RowBytes * Rows, 0) Else FillChar(Dst^, RowBytes * Rows, 255);
 GetMem(RefA, (Cols + 8) * 4);
 GetMem(CurA, (Cols + 8) * 4);
 For J := 0 To Cols + 7 Do PLongInt(PByte(RefA) + J * 4)^ := Cols;
 Rd := 0;
 While (Rd < Rows) And (CCBit < SLen * 8) Do Begin
  If ByteAlign Then CCBit := (CCBit + 7) And (Not 7);
  Is2D := K < 0;
  If K >= 0 Then Begin
   { remplissage et EOL éventuels }
   While (CCBit < SLen * 8) And (CCPeek(12) <> 1) And (CCPeek(11) = 0) Do Inc(CCBit);
   If CCPeek(12) = 1 Then Begin
    Inc(CCBit, 12);
    If K > 0 Then Begin Is2D := CCPeek(1) = 0; Inc(CCBit); End;
    If CCPeek(12) = 1 Then Break;   { RTC }
   End
   Else If K > 0 Then Begin Is2D := CCPeek(1) = 0; Inc(CCBit); End;
  End
  Else If CCPeek(12) = 1 Then Break;   { EOFB }
  Err := False;
  N := 0;
  If Not Is2D Then Begin
   A0 := 0; Col := 0;
   While A0 < Cols Do Begin
    R1 := CCRun(Col);
    If R1 < 0 Then Begin Err := True; Break; End;
    A0 := A0 + R1;
    If A0 > Cols Then A0 := Cols;
    CurSet(N, A0); Inc(N);
    Col := 1 - Col;
   End;
  End
  Else Begin
   A0 := -1; Col := 0; Bj := 0;
   While A0 < Cols Do Begin
    If Bj >= 2 Then Dec(Bj, 2) Else Bj := 0;
    While (CcRefAt(Bj) <= A0) And (CcRefAt(Bj) < Cols) Do Inc(Bj);
    If (Bj And 1) <> Col Then Inc(Bj);
    B1 := CcRefAt(Bj); B2 := CcRefAt(Bj + 1);
    M := CCPeek(7);
    If CC2Len[M] = 0 Then Begin Err := True; Break; End;
    Inc(CCBit, CC2Len[M]);
    Case CC2Mode[M] Of
     0: A0 := B2;
     1: Begin
      R1 := CCRun(Col);
      If R1 >= 0 Then R2 := CCRun(1 - Col) Else R2 := -1;
      If (R1 < 0) Or (R2 < 0) Then Begin Err := True; Break; End;
      If A0 < 0 Then A0 := 0;
      A1 := A0 + R1; If A1 > Cols Then A1 := Cols;
      A2 := A1 + R2; If A2 > Cols Then A2 := Cols;
      CurSet(N, A1); Inc(N); CurSet(N, A2); Inc(N);
      A0 := A2;
     End;
    Else Begin
      A1 := B1 + (CC2Mode[M] - 5);
      If A1 < 0 Then A1 := 0;
      If A1 > Cols Then A1 := Cols;
      CurSet(N, A1); Inc(N);
      A0 := A1;
      Col := 1 - Col;
     End;
    End;
    If N > Cols + 2 Then Begin Err := True; Break; End;
   End;
  End;
  { pavage de la ligne }
  For J := 0 To 3 Do CurSet(N + J, Cols);
  Row := PBigBytes(PByte(Dst) + Rd * RowBytes);
  J := 0;
  While J < N Do Begin
   Xs := PLongInt(PByte(CurA) + J * 4)^;
   If J + 1 < N Then Xe := PLongInt(PByte(CurA) + (J + 1) * 4)^ Else Xe := Cols;
   If Xe > Cols Then Xe := Cols;
   For X := Xs To Xe - 1 Do
    If BlackIs1 Then Row^[X Shr 3] := Row^[X Shr 3] Or (128 Shr (X And 7))
    Else Row^[X Shr 3] := Row^[X Shr 3] And (Not (128 Shr (X And 7)));
   Inc(J, 2);
  End;
  Inc(Rd);
  If Err Then Begin
   If K < 0 Then Break;
   { Groupe 3 : se resynchroniser sur le prochain EOL }
   While (CCBit < SLen * 8) And (CCPeek(12) <> 1) Do Inc(CCBit);
  End;
  Tmp := Pointer(RefA); RefA := CurA; CurA := PBigBytes(Tmp);
 End;
 FreeMem(RefA, (Cols + 8) * 4);
 FreeMem(CurA, (Cols + 8) * 4);
 CCITTDecode := Rd;
End;
{ ---------------------------------------------------------------------- }
{ Décodeur JPEG 2000 (JPX / JP2 / J2K) - ITU-T T.800 / ISO 15444-1        }
{ Snippet destiné à être inclus dans un bloc IFDEF FPC (pas de unit).     }
{ Point d'entrée : JPXDecode (en fin de snippet).                          }
{ Tous les identifiants globaux commencent par Jx / TJx / PJx / JPX.       }
{                                                                          }
{ Géré : codestream brut (FF4F) ou JP2 (jp2h : colr, pclr, cmap, cdef),    }
{  SIZ COD COC QCD QCC RGN POC SOT SOD SOP EPH EOC (TLM PLM PLT CRG COM    }
{  ignorés), tuiles et parties de tuiles multiples (Psot = 0 inclus),      }
{  5 ordres de progression + POC, précincts, couches, code-blocks         }
{  jusqu'à 64x64 (BYPASS RESET TERMALL VSC PTERM SEGSYM), ROI max-shift,   }
{  quantification (aucune / dérivée / étendue), DWT 5/3 et 9/7, MCT        }
{  RCT/ICT, composantes sous-échantillonnées, palette, alpha ignoré,       }
{  réduction de résolution (MaxDim). Non géré : PPM/PPT (en-têtes de      }
{  paquets déplacés), HTJ2K, précision > 30 bits, plus de 32 composantes.  }
{ Les flux corrompus ou tronqués donnent un décodage partiel ou False.     }
{ ---------------------------------------------------------------------- }

Const
 JxMaxC = 32;            { nombre max de composantes }
 JxMaxPoc = 64;          { nombre max de changements de progression }
 JxMaxSamples = 200000000; { limite largeur*hauteur*composantes }
 JxInf = $3FFFFFFF;
 { drapeaux Tier-1 }
 JxFNE = $0001; JxFSE = $0002; JxFSW = $0004; JxFNW = $0008;
 JxFN = $0010; JxFE = $0020; JxFS = $0040; JxFW = $0080;
 JxFSN = $0100; JxFSE2 = $0200; JxFSS = $0400; JxFSW2 = $0800;
 JxFSig = $1000; JxFRef = $2000; JxFVis = $4000; JxFNVis = $BFFF;
 { styles de code-block }
 JxCbLazy = 1; JxCbReset = 2; JxCbTermAll = 4; JxCbVsc = 8;
 JxCbPterm = 16; JxCbSegSym = 32;
 JxArenaSz = 1048576;

Type
 PJxLArr = ^TJxLArr;
 TJxLArr = Array[0..536870910] Of LongInt;
 PJxSArr = ^TJxSArr;
 TJxSArr = Array[0..536870910] Of Single;
 PJxWArr = ^TJxWArr;
 TJxWArr = Array[0..1073741822] Of Word;
 PJxBArr = ^TJxBArr;
 TJxBArr = Array[0..2147483646] Of Byte;

 { paramètres de codage d'une composante (COD / COC) }
 TJxCod = Record
  NL, XCB, YCB, Sty, Transf: LongInt;
  PPx, PPy: Array[0..32] Of Byte;
 End;
 { paramètres de quantification d'une composante (QCD / QCC) }
 TJxQnt = Record
  Sty, Guard, Cnt: LongInt;
  Eps: Array[0..96] Of Byte;
  Mu: Array[0..96] Of Word;
 End;
 TJxPoc = Record
  RS, CS, LYE, RE, CE, Prog: LongInt;
 End;
 TJxParams = Record
  Prog, Layers, MCT, Scod: LongInt;
  Cod: Array[0..JxMaxC - 1] Of TJxCod;
  Qnt: Array[0..JxMaxC - 1] Of TJxQnt;
  Roi: Array[0..JxMaxC - 1] Of LongInt;
  CodSet, QntSet: Array[0..JxMaxC - 1] Of Boolean;
  NPoc: LongInt;
  PocSeen, HasCod, HasQnt: Boolean;
  Poc: Array[0..JxMaxPoc - 1] Of TJxPoc;
 End;

 { parties de tuile }
 TJxTP = Record
  Tile, Hdr, Data, DEnd, Next: LongInt;
 End;
 PJxTPArr = ^TJxTPArr;
 TJxTPArr = Array[0..4194303] Of TJxTP;

 { structures Tier-2 / Tier-1 }
 TJxSeg = Record
  Len, Passes, MaxPasses: LongInt;
 End;
 PJxSegArr = ^TJxSegArr;
 TJxSegArr = Array[0..1023] Of TJxSeg;
 PJxCblk = ^TJxCblk;
 TJxCblk = Record
  X0, Y0, X1, Y1: LongInt;
  NumBps, NumPasses, LBlock, SegCnt, SegCap, DLen, DCap: LongInt;
  Data: PBigBytes;
  Segs: PJxSegArr;
 End;
 PJxCblkArr = ^TJxCblkArr;
 TJxCblkArr = Array[0..4194303] Of TJxCblk;
 TJxTagNode = Record
  Value, Low: LongInt;
 End;
 PJxTagArr = ^TJxTagArr;
 TJxTagArr = Array[0..16777215] Of TJxTagNode;
 PJxTag = ^TJxTag;
 TJxTag = Record
  W, H: LongInt;
  Nodes: PJxTagArr;
 End;
 TJxPBand = Record
  NCw, NCh: LongInt;
  Cblks: PJxCblkArr;
  Incl, Zbp: PJxTag;
 End;
 TJxPrec = Record
  Bands: Array[0..2] Of TJxPBand;
 End;
 PJxPrecArr = ^TJxPrecArr;
 TJxPrecArr = Array[0..4194303] Of TJxPrec;
 TJxBand = Record
  X0, Y0, X1, Y1, Orient, Mb, OX, OY: LongInt;
  Step: Single;
 End;
 TJxRes = Record
  X0, Y0, X1, Y1, PW, PH, PPx, PPy, NB, PrecBase, W, H: LongInt;
  Bands: Array[0..2] Of TJxBand;
  Precs: PJxPrecArr;
 End;
 PJxResArr = ^TJxResArr;
 TJxResArr = Array[0..32] Of TJxRes;
 TJxTComp = Record
  X0, Y0, X1, Y1, NL, Rk, W, H: LongInt;
  Res: PJxResArr;
  Buf: Pointer;
 End;
 TJxPend = Record
  Cb: PJxCblk;
  Seg, Len: LongInt;
 End;
 PJxPendArr = ^TJxPendArr;
 TJxPendArr = Array[0..16777215] Of TJxPend;
 PJxArena = ^TJxArena;
 TJxArena = Record
  Next: PJxArena;
  Size, Used: PtrInt;
 End;

Var
 { flux }
 JxS: PBigBytes;
 JxSLen: LongInt;
 { SIZ }
 JxXsiz, JxYsiz, JxXOsiz, JxYOsiz, JxXTsiz, JxYTsiz, JxXTOsiz, JxYTOsiz: LongInt;
 JxNC, JxNTX, JxNTY, JxNT: LongInt;
 JxPrecC: Array[0..JxMaxC - 1] Of LongInt;
 JxSgnC: Array[0..JxMaxC - 1] Of Boolean;
 JxXR, JxYR: Array[0..JxMaxC - 1] Of LongInt;
 JxHaveSiz: Boolean;
 { paramètres principaux / de tuile }
 JxMainP, JxTileP: TJxParams;
 { parties de tuile }
 JxTPs: PJxTPArr;
 JxNTP, JxTPCap: LongInt;
 JxTileFirst, JxTileLast: PJxLArr;
 { réduction }
 JxRed: LongInt;
 { arène mémoire de tuile }
 JxAr: PJxArena;
 { tuile courante }
 JxTX0, JxTY0, JxTX1, JxTY1: LongInt;
 JxTC: Array[0..JxMaxC - 1] Of TJxTComp;
 JxTotCblk, JxTotPrec: Int64;
 JxCurTile, JxCurTP: LongInt;
 JxPktPos, JxPktEnd: LongInt;
 JxStop: Boolean;
 JxDone: PByte;
 JxDoneBits: Int64;
 JxPend: PJxPendArr;
 JxPendCap: LongInt;
 { lecteur de bits d'en-tête de paquet }
 JxHPos, JxHEnd, JxHBuf, JxHCt: LongInt;
 JxHErr: Boolean;
 { MQ / Tier-1 }
 JxMqA, JxMqC: Cardinal;
 JxMqCt, JxMqI: LongInt;
 JxMqD: PBigBytes;
 JxRawC, JxRawCt: LongInt;
 JxCtx: Array[0..18] Of Byte;
 JxQe: Array[0..93] Of Word;
 JxNMps, JxNLps: Array[0..93] Of Byte;
 JxZC: Array[0..3, 0..255] Of Byte;
 JxSC: Array[0..255] Of Byte;
 JxFl: Array[0..6399] Of Word;
 JxData: Array[0..4095] Of LongInt;
 JxTabInit: Boolean;
 { JP2 }
 JxEnumCS: LongInt;
 JxHavePal: Boolean;
 JxPalN, JxPalNC: LongInt;
 JxPalDepth: Array[0..7] Of LongInt;
 JxPal: PJxLArr;
 JxNCmap: LongInt;
 JxCmapC, JxCmapT, JxCmapP: Array[0..JxMaxC - 1] Of LongInt;
 JxNCdef: LongInt;
 JxCdefN, JxCdefT, JxCdefA: Array[0..JxMaxC - 1] Of LongInt;
 { sortie }
 JxPlane: Array[0..JxMaxC - 1] Of PJxBArr;
 JxPlaneW, JxPlaneH, JxPlaneX0, JxPlaneY0: Array[0..JxMaxC - 1] Of LongInt;
 JxPlaneWord: Array[0..JxMaxC - 1] Of Boolean;
 JxMemErr: Boolean;

{ ---------------------------------------------------------------------- }
{ Utilitaires                                                              }
{ ---------------------------------------------------------------------- }

Function JxMin(A, B: LongInt): LongInt;
Begin
 If A < B Then JxMin := A Else JxMin := B;
End;

Function JxMax(A, B: LongInt): LongInt;
Begin
 If A > B Then JxMax := A Else JxMax := B;
End;

Function JxMin64(A, B: Int64): Int64;
Begin
 If A < B Then JxMin64 := A Else JxMin64 := B;
End;

Function JxMax64(A, B: Int64): Int64;
Begin
 If A > B Then JxMax64 := A Else JxMax64 := B;
End;

{ Division par 2^N arrondie vers le haut / le bas (valeurs signées) }
Function JxCeilShr(V: Int64; N: LongInt): Int64;
Begin
 JxCeilShr := SarInt64(V + (Int64(1) Shl N) - 1, N);
End;

Function JxFloorShr(V: Int64; N: LongInt): Int64;
Begin
 JxFloorShr := SarInt64(V, N);
End;

Function JxCeilDiv(A, B: Int64): Int64;
Begin
 If B <= 0 Then JxCeilDiv := 0
 Else If A >= 0 Then JxCeilDiv := (A + B - 1) Div B
 Else JxCeilDiv := -((-A) Div B);
End;

Function JxBE16(P: LongInt): LongInt;
Begin
 JxBE16 := (LongInt(JxS^[P]) Shl 8) Or JxS^[P + 1];
End;

Function JxBE32(P: LongInt): Int64;
Begin
 JxBE32 := (Int64(JxS^[P]) Shl 24) Or (Int64(JxS^[P + 1]) Shl 16) Or
           (Int64(JxS^[P + 2]) Shl 8) Or Int64(JxS^[P + 3]);
End;

{ Arène : allocation zéro-initialisée, libérée d'un bloc en fin de tuile }
Function JxAlloc(Sz: PtrInt): Pointer;
Var
 A: PJxArena;
 Cap: PtrInt;
Begin
 JxAlloc := Nil;
 If (Sz < 0) Or (Sz > 1700000000) Then Begin JxMemErr := True; Exit; End;
 Sz := (Sz + 15) And (Not PtrInt(15));
 If (JxAr = Nil) Or (JxAr^.Size - JxAr^.Used < Sz) Then Begin
  Cap := JxArenaSz;
  If Sz > Cap Then Cap := Sz;
  A := Nil;
  GetMem(A, Cap + 32);
  If A = Nil Then Begin JxMemErr := True; Exit; End;
  A^.Next := JxAr;
  A^.Size := Cap;
  A^.Used := 0;
  JxAr := A;
 End;
 JxAlloc := Pointer(PtrUInt(JxAr) + 32 + PtrUInt(JxAr^.Used));
 Inc(JxAr^.Used, Sz);
 If Sz > 0 Then FillChar(JxAlloc^, Sz, 0);
End;

Procedure JxFreeArena;
Var
 A, B: PJxArena;
Begin
 A := JxAr;
 While A <> Nil Do Begin
  B := A^.Next;
  FreeMem(A, A^.Size + 32);
  A := B;
 End;
 JxAr := Nil;
End;

{ Table MQ et tables de contextes Tier-1 }
Procedure JxInitTables;
Const
 QeV: Array[0..46] Of Word = (
  $5601, $3401, $1801, $0AC1, $0521, $0221, $5601, $5401, $4801, $3801,
  $3001, $2401, $1C01, $1601, $5601, $5401, $5101, $4801, $3801, $3401,
  $3001, $2801, $2401, $2201, $1C01, $1801, $1601, $1401, $1201, $1101,
  $0AC1, $09C1, $08A1, $0521, $0441, $02A1, $0221, $0141, $0111, $0085,
  $0049, $0025, $0015, $0009, $0005, $0001, $5601);
 NM: Array[0..46] Of Byte = (
  1, 2, 3, 4, 5, 38, 7, 8, 9, 10, 11, 12, 13, 29, 15, 16, 17, 18, 19, 20,
  21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38,
  39, 40, 41, 42, 43, 44, 45, 45, 46);
 NL: Array[0..46] Of Byte = (
  1, 6, 9, 12, 29, 33, 6, 14, 14, 14, 17, 18, 20, 21, 14, 14, 15, 16, 17,
  18, 19, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
  35, 36, 37, 38, 39, 40, 41, 42, 43, 46);
 SW: Array[0..46] Of Byte = (
  1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
Var
 S, M, O, F, H, V, D, HV, C, X, HC, VC, T: LongInt;
Begin
 If JxTabInit Then Exit;
 For S := 0 To 46 Do
  For M := 0 To 1 Do Begin
   JxQe[S * 2 + M] := QeV[S];
   JxNMps[S * 2 + M] := NM[S] * 2 + M;
   JxNLps[S * 2 + M] := NL[S] * 2 + (M Xor SW[S]);
  End;
 { contextes de zero-coding }
 For O := 0 To 3 Do
  For F := 0 To 255 Do Begin
   H := ((F Shr 5) And 1) + ((F Shr 7) And 1);
   V := ((F Shr 4) And 1) + ((F Shr 6) And 1);
   D := (F And 1) + ((F Shr 1) And 1) + ((F Shr 2) And 1) + ((F Shr 3) And 1);
   If O = 1 Then Begin T := H; H := V; V := T; End;
   If O = 3 Then Begin
    HV := H + V;
    If D >= 3 Then C := 8
    Else If D = 2 Then Begin If HV >= 1 Then C := 7 Else C := 6; End
    Else If D = 1 Then Begin
     If HV >= 2 Then C := 5 Else If HV = 1 Then C := 4 Else C := 3;
    End Else Begin
     If HV >= 2 Then C := 2 Else If HV = 1 Then C := 1 Else C := 0;
    End;
   End Else Begin
    If H = 2 Then C := 8
    Else If H = 1 Then Begin
     If V >= 1 Then C := 7 Else If D >= 1 Then C := 6 Else C := 5;
    End Else Begin
     If V = 2 Then C := 4
     Else If V = 1 Then C := 3
     Else If D >= 2 Then C := 2
     Else If D = 1 Then C := 1
     Else C := 0;
    End;
   End;
   JxZC[O, F] := C;
  End;
 { contextes de signe : index = bits N,E,S,W de signifiance puis de signe }
 For X := 0 To 255 Do Begin
  HC := 0; VC := 0;
  If (X And 2) <> 0 Then Begin If (X And 32) <> 0 Then Dec(HC) Else Inc(HC); End;
  If (X And 8) <> 0 Then Begin If (X And 128) <> 0 Then Dec(HC) Else Inc(HC); End;
  If (X And 1) <> 0 Then Begin If (X And 16) <> 0 Then Dec(VC) Else Inc(VC); End;
  If (X And 4) <> 0 Then Begin If (X And 64) <> 0 Then Dec(VC) Else Inc(VC); End;
  If HC > 1 Then HC := 1;
  If HC < -1 Then HC := -1;
  If VC > 1 Then VC := 1;
  If VC < -1 Then VC := -1;
  C := 9; T := 0;
  If HC = 1 Then Begin
   If VC = 1 Then C := 13 Else If VC = 0 Then C := 12 Else C := 11;
  End Else If HC = 0 Then Begin
   If VC = 1 Then C := 10 Else If VC = 0 Then C := 9 Else Begin C := 10; T := 1; End;
  End Else Begin
   T := 1;
   If VC = 1 Then C := 11 Else If VC = 0 Then C := 12 Else C := 13;
  End;
  JxSC[X] := C + 32 * T;
 End;
 JxTabInit := True;
End;

{ ---------------------------------------------------------------------- }
{ Décodeur arithmétique MQ et décodeur brut (mode BYPASS)                  }
{ ---------------------------------------------------------------------- }

Procedure JxMqByteIn;
Var
 B: LongInt;
Begin
 B := JxMqD^[JxMqI];
 If B = $FF Then Begin
  If JxMqD^[JxMqI + 1] > $8F Then Begin
   JxMqC := JxMqC + $FF00;
   JxMqCt := 8;
  End Else Begin
   Inc(JxMqI);
   JxMqC := JxMqC + (Cardinal(JxMqD^[JxMqI]) Shl 9);
   JxMqCt := 7;
  End;
 End Else Begin
  Inc(JxMqI);
  JxMqC := JxMqC + (Cardinal(JxMqD^[JxMqI]) Shl 8);
  JxMqCt := 8;
 End;
End;

{ D pointe sur le segment, suivi de 2 octets sentinelles $FF }
Procedure JxMqInit(D: PBigBytes);
Begin
 JxMqD := D;
 JxMqI := 0;
 JxMqC := Cardinal(D^[0]) Shl 16;
 JxMqByteIn;
 JxMqC := JxMqC Shl 7;
 JxMqCt := JxMqCt - 7;
 JxMqA := $8000;
End;

Function JxMqDec(Cx: LongInt): LongInt;
Var
 V: LongInt;
 Q: Cardinal;
 Dd: LongInt;
Begin
 V := JxCtx[Cx];
 Q := JxQe[V];
 JxMqA := JxMqA - Q;
 If (JxMqC Shr 16) < Q Then Begin
  If JxMqA < Q Then Begin
   Dd := V And 1;
   JxCtx[Cx] := JxNMps[V];
  End Else Begin
   Dd := 1 - (V And 1);
   JxCtx[Cx] := JxNLps[V];
  End;
  JxMqA := Q;
 End Else Begin
  JxMqC := JxMqC - (Q Shl 16);
  If (JxMqA And $8000) <> 0 Then Begin
   JxMqDec := V And 1;
   Exit;
  End;
  If JxMqA < Q Then Begin
   Dd := 1 - (V And 1);
   JxCtx[Cx] := JxNLps[V];
  End Else Begin
   Dd := V And 1;
   JxCtx[Cx] := JxNMps[V];
  End;
 End;
 Repeat
  If JxMqCt = 0 Then JxMqByteIn;
  JxMqA := JxMqA Shl 1;
  JxMqC := JxMqC Shl 1;
  Dec(JxMqCt);
 Until (JxMqA And $8000) <> 0;
 JxMqDec := Dd;
End;

Procedure JxRawInit(D: PBigBytes);
Begin
 JxMqD := D;
 JxMqI := 0;
 JxRawC := 0;
 JxRawCt := 0;
End;

Function JxRawBit: LongInt;
Begin
 If JxRawCt = 0 Then Begin
  If JxRawC = $FF Then Begin
   If JxMqD^[JxMqI] > $8F Then Begin
    JxRawC := $FF;
    JxRawCt := 8;
   End Else Begin
    JxRawC := JxMqD^[JxMqI];
    Inc(JxMqI);
    JxRawCt := 7;
   End;
  End Else Begin
   JxRawC := JxMqD^[JxMqI];
   Inc(JxMqI);
   JxRawCt := 8;
  End;
 End;
 Dec(JxRawCt);
 JxRawBit := (JxRawC Shr JxRawCt) And 1;
End;

Procedure JxResetCtx;
Begin
 FillChar(JxCtx, SizeOf(JxCtx), 0);
 JxCtx[0] := 8;
 JxCtx[17] := 6;
 JxCtx[18] := 92;
End;

{ ---------------------------------------------------------------------- }
{ Tier-1 : passes de codage EBCOT                                          }
{ ---------------------------------------------------------------------- }

{ met à jour les drapeaux des voisins quand l'échantillon FI devient significatif }
Procedure JxUpdFlags(FI, S, Stride: LongInt; NoNorth: Boolean);
Begin
 If Not NoNorth Then Begin
  JxFl[FI - Stride - 1] := JxFl[FI - Stride - 1] Or JxFSE;
  JxFl[FI - Stride] := JxFl[FI - Stride] Or (JxFS Or (S * JxFSS));
  JxFl[FI - Stride + 1] := JxFl[FI - Stride + 1] Or JxFSW;
 End;
 JxFl[FI - 1] := JxFl[FI - 1] Or (JxFE Or (S * JxFSE2));
 JxFl[FI + 1] := JxFl[FI + 1] Or (JxFW Or (S * JxFSW2));
 JxFl[FI + Stride - 1] := JxFl[FI + Stride - 1] Or JxFNE;
 JxFl[FI + Stride] := JxFl[FI + Stride] Or (JxFN Or (S * JxFSN));
 JxFl[FI + Stride + 1] := JxFl[FI + Stride + 1] Or JxFNW;
 JxFl[FI] := JxFl[FI] Or JxFSig;
End;

Procedure JxT1Sig(W, H, Bp1, Orient, Sty: LongInt; Raw: Boolean);
Var
 Oph, Stride, K, I, J, JM, FI, F, V, S, T: LongInt;
 Vsc: Boolean;
Begin
 Oph := (1 Shl Bp1) Or (1 Shl (Bp1 - 1));
 Stride := W + 2;
 Vsc := (Sty And JxCbVsc) <> 0;
 K := 0;
 While K < H Do Begin
  JM := K + 4;
  If JM > H Then JM := H;
  For I := 0 To W - 1 Do Begin
   FI := (K + 1) * Stride + I + 1;
   For J := K To JM - 1 Do Begin
    F := JxFl[FI];
    If ((F And $FF) <> 0) And ((F And (JxFSig Or JxFVis)) = 0) Then Begin
     If Raw Then V := JxRawBit Else V := JxMqDec(JxZC[Orient, F And $FF]);
     If V <> 0 Then Begin
      T := JxSC[(F Shr 4) And $FF];
      If Raw Then S := JxRawBit Else S := JxMqDec(T And 31) Xor (T Shr 5);
      If S <> 0 Then JxData[J * W + I] := -Oph Else JxData[J * W + I] := Oph;
      JxUpdFlags(FI, S, Stride, Vsc And (J = K));
     End;
     JxFl[FI] := JxFl[FI] Or JxFVis;
    End;
    Inc(FI, Stride);
   End;
  End;
  Inc(K, 4);
 End;
End;

Procedure JxT1Ref(W, H, Bp1: LongInt; Raw: Boolean);
Var
 PosHalf, Stride, K, I, J, JM, FI, F, V, T, Cx, DI: LongInt;
Begin
 PosHalf := 1 Shl (Bp1 - 1);
 Stride := W + 2;
 K := 0;
 While K < H Do Begin
  JM := K + 4;
  If JM > H Then JM := H;
  For I := 0 To W - 1 Do Begin
   FI := (K + 1) * Stride + I + 1;
   For J := K To JM - 1 Do Begin
    F := JxFl[FI];
    If (F And (JxFSig Or JxFVis)) = JxFSig Then Begin
     If Raw Then V := JxRawBit Else Begin
      If (F And JxFRef) <> 0 Then Cx := 16
      Else If (F And $FF) <> 0 Then Cx := 15
      Else Cx := 14;
      V := JxMqDec(Cx);
     End;
     If V <> 0 Then T := PosHalf Else T := -PosHalf;
     DI := J * W + I;
     If JxData[DI] < 0 Then JxData[DI] := JxData[DI] - T
     Else JxData[DI] := JxData[DI] + T;
     JxFl[FI] := F Or JxFRef;
    End;
    Inc(FI, Stride);
   End;
  End;
  Inc(K, 4);
 End;
End;

Procedure JxT1Cup(W, H, Bp1, Orient, Sty: LongInt);
Var
 Oph, Stride, K, I, J, JM, FI, FI0, F, V, S, T, RunLen, JS: LongInt;
 Agg, Vsc: Boolean;
Begin
 Oph := (1 Shl Bp1) Or (1 Shl (Bp1 - 1));
 Stride := W + 2;
 Vsc := (Sty And JxCbVsc) <> 0;
 K := 0;
 While K < H Do Begin
  JM := K + 4;
  If JM > H Then JM := H;
  For I := 0 To W - 1 Do Begin
   FI0 := (K + 1) * Stride + I + 1;
   Agg := False;
   RunLen := 0;
   If K + 3 < H Then
    Agg := ((JxFl[FI0] Or JxFl[FI0 + Stride] Or JxFl[FI0 + 2 * Stride] Or
             JxFl[FI0 + 3 * Stride]) And (JxFSig Or JxFVis Or $FF)) = 0;
   If Agg Then Begin
    If JxMqDec(17) = 0 Then Continue;
    RunLen := JxMqDec(18) Shl 1;
    RunLen := RunLen Or JxMqDec(18);
   End;
   FI := FI0 + RunLen * Stride;
   JS := K + RunLen;
   For J := JS To JM - 1 Do Begin
    F := JxFl[FI];
    V := 0;
    If Agg And (J = JS) Then V := 1
    Else If (F And (JxFSig Or JxFVis)) = 0 Then
     V := JxMqDec(JxZC[Orient, F And $FF]);
    If V <> 0 Then Begin
     T := JxSC[(F Shr 4) And $FF];
     S := JxMqDec(T And 31) Xor (T Shr 5);
     If S <> 0 Then JxData[J * W + I] := -Oph Else JxData[J * W + I] := Oph;
     JxUpdFlags(FI, S, Stride, Vsc And (J = K));
    End;
    JxFl[FI] := JxFl[FI] And JxFNVis;
    Inc(FI, Stride);
   End;
  End;
  Inc(K, 4);
 End;
 If (Sty And JxCbSegSym) <> 0 Then Begin
  V := JxMqDec(18);
  V := JxMqDec(18);
  V := JxMqDec(18);
  V := JxMqDec(18);
 End;
End;

{ Décode un code-block ; résultat dans JxData (avec bit fractionnaire),
  retourne False si rien à décoder }
Function JxDecodeBlock(Cb: PJxCblk; Orient, Sty, RoiShift: LongInt): Boolean;
Var
 W, H, Nb, Bp1, Pt, PassIdx, Off, S, P, I, Mag, Thr: LongInt;
 Raw: Boolean;
 Sv0, Sv1: Byte;
 Seg: TJxSeg;
 D: PBigBytes;
Begin
 JxDecodeBlock := False;
 W := Cb^.X1 - Cb^.X0;
 H := Cb^.Y1 - Cb^.Y0;
 If (W <= 0) Or (H <= 0) Or (W * H > 4096) Or (Cb^.NumPasses <= 0) Or (Cb^.Data = Nil) Then Exit;
 Nb := Cb^.NumBps + RoiShift;
 If (Nb < 1) Or (Nb > 29) Then Exit;
 FillChar(JxData, W * H * 4, 0);
 FillChar(JxFl, (W + 2) * (H + 2) * 2, 0);
 JxResetCtx;
 Bp1 := Nb;
 Pt := 2;
 PassIdx := 0;
 Off := 0;
 For S := 0 To Cb^.SegCnt - 1 Do Begin
  Seg := Cb^.Segs^[S];
  If (Seg.Len < 0) Or (Off + Seg.Len + 2 > Cb^.DCap) Then Break;
  D := PBigBytes(PtrUInt(Cb^.Data) + PtrUInt(Off));
  Sv0 := D^[Seg.Len];
  Sv1 := D^[Seg.Len + 1];
  D^[Seg.Len] := $FF;
  D^[Seg.Len + 1] := $FF;
  Raw := ((Sty And JxCbLazy) <> 0) And (PassIdx >= 10) And (Pt < 2);
  If Raw Then JxRawInit(D) Else JxMqInit(D);
  For P := 1 To Seg.Passes Do Begin
   If Bp1 < 1 Then Break;
   Case Pt Of
    0: JxT1Sig(W, H, Bp1, Orient, Sty, Raw);
    1: JxT1Ref(W, H, Bp1, Raw);
    2: JxT1Cup(W, H, Bp1, Orient, Sty);
   End;
   If ((Sty And JxCbReset) <> 0) And (Not Raw) Then JxResetCtx;
   Inc(Pt);
   If Pt = 3 Then Begin
    Pt := 0;
    Dec(Bp1);
   End;
   Inc(PassIdx);
  End;
  D^[Seg.Len] := Sv0;
  D^[Seg.Len + 1] := Sv1;
  Inc(Off, Seg.Len);
  If Bp1 < 1 Then Break;
 End;
 If RoiShift > 0 Then Begin
  Thr := 1 Shl RoiShift;
  For I := 0 To W * H - 1 Do Begin
   Mag := Abs(JxData[I]);
   If Mag >= Thr Then Begin
    Mag := Mag Shr RoiShift;
    If JxData[I] < 0 Then JxData[I] := -Mag Else JxData[I] := Mag;
   End;
  End;
 End;
 JxDecodeBlock := True;
End;

{ ---------------------------------------------------------------------- }
{ Tier-2 : arbres de tags et lecteur de bits d'en-tête de paquet           }
{ ---------------------------------------------------------------------- }

Procedure JxHByteIn;
Begin
 JxHBuf := (JxHBuf Shl 8) And $FFFF;
 If JxHBuf = $FF00 Then JxHCt := 7 Else JxHCt := 8;
 If JxHPos >= JxHEnd Then JxHErr := True
 Else Begin
  JxHBuf := JxHBuf Or JxS^[JxHPos];
  Inc(JxHPos);
 End;
End;

Function JxHBit: LongInt;
Begin
 If JxHCt = 0 Then JxHByteIn;
 Dec(JxHCt);
 JxHBit := (JxHBuf Shr JxHCt) And 1;
End;

Function JxHBits(N: LongInt): LongInt;
Var
 V, I: LongInt;
Begin
 V := 0;
 If N > 30 Then Begin JxHErr := True; JxHBits := 0; Exit; End;
 For I := 1 To N Do V := (V Shl 1) Or JxHBit;
 JxHBits := V;
End;

Procedure JxHAlign;
Begin
 If (JxHBuf And $FF) = $FF Then JxHByteIn;
 JxHCt := 0;
End;

Function JxTagNew(W, H: LongInt): PJxTag;
Var
 T: PJxTag;
 N, Lw, Lh: Int64;
 I: LongInt; { compteur de boucle : Int64 interdit sous Free Pascal 32 bits }
 Nd: PJxTagArr;
Begin
 JxTagNew := Nil;
 T := JxAlloc(SizeOf(TJxTag));
 If T = Nil Then Exit;
 N := 0; Lw := W; Lh := H;
 While True Do Begin
  N := N + Lw * Lh;
  If (Lw <= 1) And (Lh <= 1) Then Break;
  Lw := (Lw + 1) Shr 1;
  Lh := (Lh + 1) Shr 1;
 End;
 If N > 16000000 Then Begin JxMemErr := True; Exit; End;
 Nd := JxAlloc(N * SizeOf(TJxTagNode));
 If Nd = Nil Then Exit;
 For I := 0 To N - 1 Do Nd^[I].Value := JxInf;
 T^.W := W;
 T^.H := H;
 T^.Nodes := Nd;
 JxTagNew := T;
End;

{ vrai si la valeur de la feuille (X,Y) est < Thr }
Function JxTagDec(T: PJxTag; X, Y, Thr: LongInt): Boolean;
Var
 Path: Array[0..39] Of LongInt;
 Np, Lw, Lh, Off, Low, N, Xx, Yy: LongInt;
 Nd: ^TJxTagNode;
Begin
 Np := 0; Lw := T^.W; Lh := T^.H; Off := 0; Xx := X; Yy := Y;
 While True Do Begin
  Path[Np] := Off + Yy * Lw + Xx;
  Inc(Np);
  If ((Lw <= 1) And (Lh <= 1)) Or (Np >= 38) Then Break;
  Off := Off + Lw * Lh;
  Xx := Xx Shr 1; Yy := Yy Shr 1;
  Lw := (Lw + 1) Shr 1;
  Lh := (Lh + 1) Shr 1;
 End;
 Low := 0;
 Nd := @T^.Nodes^[Path[0]];
 For N := Np - 1 DownTo 0 Do Begin
  Nd := @T^.Nodes^[Path[N]];
  If Low > Nd^.Low Then Nd^.Low := Low Else Low := Nd^.Low;
  While (Low < Thr) And (Low < Nd^.Value) And (Not JxHErr) Do Begin
   If JxHBit <> 0 Then Nd^.Value := Low Else Inc(Low);
  End;
  Nd^.Low := Low;
 End;
 JxTagDec := Nd^.Value < Thr;
End;

{ ---------------------------------------------------------------------- }
{ En-têtes de marqueurs : SIZ, COD, COC, QCD, QCC, RGN, POC                }
{ ---------------------------------------------------------------------- }

Function JxParseSP(Var Cd: TJxCod; Q, N: LongInt; HasPrec: Boolean): Boolean;
Var
 K, B: LongInt;
Begin
 JxParseSP := False;
 If N < 5 Then Exit;
 Cd.NL := JxS^[Q];
 If Cd.NL > 32 Then Exit;
 Cd.XCB := (JxS^[Q + 1] And 15) + 2;
 Cd.YCB := (JxS^[Q + 2] And 15) + 2;
 If (Cd.XCB > 10) Or (Cd.YCB > 10) Or (Cd.XCB + Cd.YCB > 12) Then Exit;
 Cd.Sty := JxS^[Q + 3];
 If (Cd.Sty And $C0) <> 0 Then Exit;   { HTJ2K non géré }
 Cd.Transf := JxS^[Q + 4];
 If Cd.Transf > 1 Then Exit;
 If HasPrec And (N < 5 + Cd.NL + 1) Then Exit;
 For K := 0 To 32 Do Begin
  Cd.PPx[K] := 15;
  Cd.PPy[K] := 15;
 End;
 If HasPrec Then
  For K := 0 To Cd.NL Do Begin
   B := JxS^[Q + 5 + K];
   Cd.PPx[K] := B And 15;
   Cd.PPy[K] := B Shr 4;
   If K > 0 Then Begin
    If Cd.PPx[K] = 0 Then Cd.PPx[K] := 1;
    If Cd.PPy[K] = 0 Then Cd.PPy[K] := 1;
   End;
  End;
 JxParseSP := True;
End;

Function JxParseQ(Var Qt: TJxQnt; Sq, Q, N: LongInt): Boolean;
Var
 I, V: LongInt;
Begin
 JxParseQ := False;
 Qt.Sty := Sq And 31;
 Qt.Guard := Sq Shr 5;
 Qt.Cnt := 0;
 Case Qt.Sty Of
  0: Begin
   If N < 1 Then Exit;
   Qt.Cnt := JxMin(N, 97);
   For I := 0 To Qt.Cnt - 1 Do Begin
    Qt.Eps[I] := JxS^[Q + I] Shr 3;
    Qt.Mu[I] := 0;
   End;
  End;
  1: Begin
   If N < 2 Then Exit;
   V := JxBE16(Q);
   Qt.Cnt := 1;
   Qt.Eps[0] := V Shr 11;
   Qt.Mu[0] := V And $7FF;
  End;
  2: Begin
   If N < 2 Then Exit;
   Qt.Cnt := JxMin(N Div 2, 97);
   For I := 0 To Qt.Cnt - 1 Do Begin
    V := JxBE16(Q + 2 * I);
    Qt.Eps[I] := V Shr 11;
    Qt.Mu[I] := V And $7FF;
   End;
  End;
 Else Exit;
 End;
 JxParseQ := True;
End;

{ applique un segment de marqueur (données en Q, longueur N) }
Function JxApplyMarker(Var P: TJxParams; Mk, Q, N: LongInt): Boolean;
Var
 Cd: TJxCod;
 Qt: TJxQnt;
 C, I, Ne: LongInt;
Begin
 JxApplyMarker := False;
 Case Mk Of
  $FF52: Begin
   If N < 10 Then Exit;
   P.Scod := JxS^[Q];
   If JxS^[Q + 1] > 4 Then Exit;
   P.Prog := JxS^[Q + 1];
   P.Layers := JxBE16(Q + 2);
   If P.Layers < 1 Then Exit;
   P.MCT := JxS^[Q + 4];
   If Not JxParseSP(Cd, Q + 5, N - 5, (P.Scod And 1) <> 0) Then Exit;
   For C := 0 To JxNC - 1 Do
    If Not P.CodSet[C] Then P.Cod[C] := Cd;
   P.HasCod := True;
  End;
  $FF53: Begin
   If N < 7 Then Exit;
   C := JxS^[Q];
   If C >= JxNC Then Begin JxApplyMarker := True; Exit; End;
   If Not JxParseSP(Cd, Q + 2, N - 2, (JxS^[Q + 1] And 1) <> 0) Then Exit;
   P.Cod[C] := Cd;
   P.CodSet[C] := True;
  End;
  $FF5C: Begin
   If N < 2 Then Exit;
   If Not JxParseQ(Qt, JxS^[Q], Q + 1, N - 1) Then Exit;
   For C := 0 To JxNC - 1 Do
    If Not P.QntSet[C] Then P.Qnt[C] := Qt;
   P.HasQnt := True;
  End;
  $FF5D: Begin
   If N < 3 Then Exit;
   C := JxS^[Q];
   If C >= JxNC Then Begin JxApplyMarker := True; Exit; End;
   If Not JxParseQ(Qt, JxS^[Q + 1], Q + 2, N - 2) Then Exit;
   P.Qnt[C] := Qt;
   P.QntSet[C] := True;
  End;
  $FF5E: Begin
   If N < 3 Then Exit;
   C := JxS^[Q];
   If C >= JxNC Then Begin JxApplyMarker := True; Exit; End;
   If JxS^[Q + 1] = 0 Then P.Roi[C] := JxS^[Q + 2];
  End;
  $FF5F: Begin
   If Not P.PocSeen Then Begin
    P.NPoc := 0;
    P.PocSeen := True;
   End;
   Ne := N Div 7;
   For I := 0 To Ne - 1 Do
    If P.NPoc < JxMaxPoc Then Begin
     P.Poc[P.NPoc].RS := JxS^[Q + 7 * I];
     P.Poc[P.NPoc].CS := JxS^[Q + 7 * I + 1];
     P.Poc[P.NPoc].LYE := JxBE16(Q + 7 * I + 2);
     P.Poc[P.NPoc].RE := JxS^[Q + 7 * I + 4];
     C := JxS^[Q + 7 * I + 5];
     If C = 0 Then C := 256;
     P.Poc[P.NPoc].CE := C;
     P.Poc[P.NPoc].Prog := JxS^[Q + 7 * I + 6];
     If P.Poc[P.NPoc].Prog > 4 Then Exit;
     Inc(P.NPoc);
    End;
  End;
  $FF60, $FF61: Exit;   { PPM / PPT : en-têtes de paquets déplacés, non gérés }
 End;
 JxApplyMarker := True;
End;

Function JxParseSiz(Q, N: LongInt): Boolean;
Var
 I, B, Nc: LongInt;
 Cw, Ch, Tot: Int64;
 Ntx, Nty: Int64;
Begin
 JxParseSiz := False;
 If N < 36 Then Exit;
 Nc := JxBE16(Q + 34);
 If (Nc < 1) Or (Nc > JxMaxC) Or (N < 36 + 3 * Nc) Then Exit;
 If (JxBE32(Q + 2) > $7FFFFFF0) Or (JxBE32(Q + 6) > $7FFFFFF0) Or
    (JxBE32(Q + 10) > $7FFFFFF0) Or (JxBE32(Q + 14) > $7FFFFFF0) Or
    (JxBE32(Q + 18) > $7FFFFFF0) Or (JxBE32(Q + 22) > $7FFFFFF0) Or
    (JxBE32(Q + 26) > $7FFFFFF0) Or (JxBE32(Q + 30) > $7FFFFFF0) Then Exit;
 JxXsiz := JxBE32(Q + 2);
 JxYsiz := JxBE32(Q + 6);
 JxXOsiz := JxBE32(Q + 10);
 JxYOsiz := JxBE32(Q + 14);
 JxXTsiz := JxBE32(Q + 18);
 JxYTsiz := JxBE32(Q + 22);
 JxXTOsiz := JxBE32(Q + 26);
 JxYTOsiz := JxBE32(Q + 30);
 If (JxXsiz <= JxXOsiz) Or (JxYsiz <= JxYOsiz) Then Exit;
 If (JxXTsiz < 1) Or (JxYTsiz < 1) Then Exit;
 If (JxXTOsiz > JxXOsiz) Or (JxYTOsiz > JxYOsiz) Then Exit;
 If (Int64(JxXTOsiz) + JxXTsiz <= JxXOsiz) Or (Int64(JxYTOsiz) + JxYTsiz <= JxYOsiz) Then Exit;
 Tot := Int64(JxXsiz - JxXOsiz) * Int64(JxYsiz - JxYOsiz) * Nc;
 If Tot > JxMaxSamples Then Exit;
 Ntx := (Int64(JxXsiz) - JxXTOsiz + JxXTsiz - 1) Div JxXTsiz;
 Nty := (Int64(JxYsiz) - JxYTOsiz + JxYTsiz - 1) Div JxYTsiz;
 If (Ntx < 1) Or (Nty < 1) Or (Ntx * Nty > 65535) Then Exit;
 JxNTX := Ntx; JxNTY := Nty; JxNT := Ntx * Nty;
 For I := 0 To Nc - 1 Do Begin
  B := JxS^[Q + 36 + 3 * I];
  JxSgnC[I] := (B And $80) <> 0;
  JxPrecC[I] := (B And $7F) + 1;
  If JxPrecC[I] > 30 Then Exit;
  JxXR[I] := JxS^[Q + 37 + 3 * I];
  JxYR[I] := JxS^[Q + 38 + 3 * I];
  If (JxXR[I] < 1) Or (JxYR[I] < 1) Then Exit;
  Cw := JxCeilDiv(JxXsiz, JxXR[I]) - JxCeilDiv(JxXOsiz, JxXR[I]);
  Ch := JxCeilDiv(JxYsiz, JxYR[I]) - JxCeilDiv(JxYOsiz, JxYR[I]);
  If (Cw < 1) Or (Ch < 1) Then Exit;
 End;
 JxNC := Nc;
 JxHaveSiz := True;
 JxParseSiz := True;
End;

{ analyse l'en-tête principal ; Pos reçoit la position du premier SOT }
Function JxParseMain(Var Pos: LongInt): Boolean;
Var
 P, Mk, L: LongInt;
Begin
 JxParseMain := False;
 If JxSLen < 4 Then Exit;
 If JxBE16(0) <> $FF4F Then Exit;
 FillChar(JxMainP, SizeOf(JxMainP), 0);
 P := 2;
 While True Do Begin
  If P + 2 > JxSLen Then Exit;
  Mk := JxBE16(P);
  If (Mk = $FF90) Or (Mk = $FFD9) Then Break;
  If (Mk < $FF30) Or (Mk > $FFFE) Then Exit;
  If Mk <= $FF3F Then Begin Inc(P, 2); Continue; End;
  If P + 4 > JxSLen Then Exit;
  L := JxBE16(P + 2);
  If (L < 2) Or (P + 2 + L > JxSLen) Then Exit;
  If Mk = $FF51 Then Begin
   If JxHaveSiz Then Exit;
   If Not JxParseSiz(P + 4, L - 2) Then Exit;
  End Else Begin
   If (Not JxHaveSiz) And (Mk >= $FF52) And (Mk <= $FF5F) Then Exit;
   If JxHaveSiz Then
    If Not JxApplyMarker(JxMainP, Mk, P + 4, L - 2) Then Exit;
  End;
  Inc(P, 2 + L);
 End;
 Pos := P;
 JxParseMain := JxHaveSiz And JxMainP.HasCod And JxMainP.HasQnt;
End;

{ liste des parties de tuiles }
Function JxScanTiles(P0: LongInt): Boolean;
Var
 P, Isot, Hdr, TEnd, Q, L, NewCap, T: LongInt;
 Psot: Int64;
 Found: Boolean;
 NewTPs: PJxTPArr;
Begin
 JxScanTiles := False;
 P := P0;
 While P + 12 <= JxSLen Do Begin
  If (JxS^[P] <> $FF) Or (JxS^[P + 1] <> $90) Then Break;
  If JxBE16(P + 2) <> 10 Then Break;
  Isot := JxBE16(P + 4);
  Psot := JxBE32(P + 6);
  Hdr := P + 12;
  If Psot = 0 Then Begin
   TEnd := JxSLen;
   If (TEnd - 2 >= Hdr) And (JxS^[TEnd - 2] = $FF) And (JxS^[TEnd - 1] = $D9) Then Dec(TEnd, 2);
  End Else Begin
   If Psot < 14 Then Break;
   If P + Psot > JxSLen Then TEnd := JxSLen Else TEnd := P + Psot;
  End;
  If TEnd < Hdr + 2 Then Break;
  Q := Hdr;
  Found := False;
  While Q + 2 <= TEnd Do Begin
   If JxS^[Q] <> $FF Then Break;
   If JxS^[Q + 1] = $93 Then Begin Found := True; Break; End;
   If Q + 4 > TEnd Then Break;
   L := JxBE16(Q + 2);
   If L < 2 Then Break;
   Inc(Q, 2 + L);
  End;
  If Not Found Then Break;
  If Isot < JxNT Then Begin
   If JxNTP >= JxTPCap Then Begin
    NewCap := JxTPCap * 2;
    If NewCap < 64 Then NewCap := 64;
    If NewCap > 4194304 Then Exit;
    NewTPs := Nil;
    GetMem(NewTPs, NewCap * SizeOf(TJxTP));
    If NewTPs = Nil Then Exit;
    If JxTPs <> Nil Then Begin
     Move(JxTPs^, NewTPs^, JxNTP * SizeOf(TJxTP));
     FreeMem(JxTPs, JxTPCap * SizeOf(TJxTP));
    End;
    JxTPs := NewTPs;
    JxTPCap := NewCap;
   End;
   JxTPs^[JxNTP].Tile := Isot;
   JxTPs^[JxNTP].Hdr := Hdr;
   JxTPs^[JxNTP].Data := Q + 2;
   JxTPs^[JxNTP].DEnd := TEnd;
   JxTPs^[JxNTP].Next := -1;
   T := JxTileLast^[Isot];
   If T >= 0 Then JxTPs^[T].Next := JxNTP Else JxTileFirst^[Isot] := JxNTP;
   JxTileLast^[Isot] := JxNTP;
   Inc(JxNTP);
  End;
  P := TEnd;
 End;
 JxScanTiles := True;
End;

{ charge les paramètres de la tuile T (principaux + en-têtes de ses parties) }
Function JxLoadTile(T: LongInt): Boolean;
Var
 Tp, Q, E, Mk, L: LongInt;
Begin
 JxLoadTile := False;
 JxTileP := JxMainP;
 FillChar(JxTileP.CodSet, SizeOf(JxTileP.CodSet), 0);
 FillChar(JxTileP.QntSet, SizeOf(JxTileP.QntSet), 0);
 JxTileP.PocSeen := False;
 Tp := JxTileFirst^[T];
 If Tp < 0 Then Exit;
 While Tp >= 0 Do Begin
  Q := JxTPs^[Tp].Hdr;
  E := JxTPs^[Tp].Data - 2;
  While Q + 4 <= E Do Begin
   Mk := JxBE16(Q);
   L := JxBE16(Q + 2);
   If (L < 2) Or (Q + 2 + L > E) Then Exit;
   If Not JxApplyMarker(JxTileP, Mk, Q + 4, L - 2) Then Exit;
   Inc(Q, 2 + L);
  End;
  Tp := JxTPs^[Tp].Next;
 End;
 JxLoadTile := True;
End;

{ ---------------------------------------------------------------------- }
{ Géométrie de tuile : composantes, résolutions, bandes, précincts,        }
{ code-blocks                                                              }
{ ---------------------------------------------------------------------- }

Function JxPow2(E: LongInt): Double;
Var
 R: Double;
 I: LongInt;
Begin
 R := 1.0;
 If E >= 0 Then Begin
  For I := 1 To JxMin(E, 100) Do R := R * 2.0;
 End Else Begin
  For I := 1 To JxMin(-E, 100) Do R := R * 0.5;
 End;
 JxPow2 := R;
End;

Function JxBuildPBand(Const Cd: TJxCod; Var Rs: TJxRes; Var Bd: TJxBand; Var Pb: TJxPBand;
  Px, Py, K: LongInt): Boolean;
Var
 Sh, Ppw, Pph, Cbw, Cbh, I, J, Ix0, Ix1, Iy0, Iy1: LongInt;
 Gx, Gy, Pbx0, Pbx1, Pby0, Pby1, Cx0, Cx1, Cy0, Cy1: Int64;
 Cb: PJxCblk;
Begin
 JxBuildPBand := False;
 Pb.NCw := 0;
 Pb.NCh := 0;
 If K > 0 Then Sh := 1 Else Sh := 0;
 Ppw := Rs.PPx - Sh;
 Pph := Rs.PPy - Sh;
 Gx := JxFloorShr(Rs.X0, Rs.PPx) + Px;
 Gy := JxFloorShr(Rs.Y0, Rs.PPy) + Py;
 Pbx0 := Gx Shl Ppw;
 Pbx1 := (Gx + 1) Shl Ppw;
 Pby0 := Gy Shl Pph;
 Pby1 := (Gy + 1) Shl Pph;
 Cx0 := Pbx0; If Bd.X0 > Cx0 Then Cx0 := Bd.X0;
 Cx1 := Pbx1; If Bd.X1 < Cx1 Then Cx1 := Bd.X1;
 Cy0 := Pby0; If Bd.Y0 > Cy0 Then Cy0 := Bd.Y0;
 Cy1 := Pby1; If Bd.Y1 < Cy1 Then Cy1 := Bd.Y1;
 If (Cx1 <= Cx0) Or (Cy1 <= Cy0) Then Begin JxBuildPBand := True; Exit; End;
 Cbw := JxMin(Cd.XCB, Ppw);
 Cbh := JxMin(Cd.YCB, Pph);
 Ix0 := JxFloorShr(Cx0, Cbw);
 Ix1 := JxCeilShr(Cx1, Cbw);
 Iy0 := JxFloorShr(Cy0, Cbh);
 Iy1 := JxCeilShr(Cy1, Cbh);
 Pb.NCw := Ix1 - Ix0;
 Pb.NCh := Iy1 - Iy0;
 JxTotCblk := JxTotCblk + Int64(Pb.NCw) * Pb.NCh;
 If (JxTotCblk > 4000000) Or (Int64(Pb.NCw) * Pb.NCh > 4000000) Then Begin
  Pb.NCw := 0; Pb.NCh := 0;
  Exit;
 End;
 Pb.Cblks := JxAlloc(Pb.NCw * Pb.NCh * SizeOf(TJxCblk));
 If Pb.Cblks = Nil Then Exit;
 Pb.Incl := JxTagNew(Pb.NCw, Pb.NCh);
 If Pb.Incl = Nil Then Exit;
 Pb.Zbp := JxTagNew(Pb.NCw, Pb.NCh);
 If Pb.Zbp = Nil Then Exit;
 For J := 0 To Pb.NCh - 1 Do
  For I := 0 To Pb.NCw - 1 Do Begin
   Cb := @Pb.Cblks^[J * Pb.NCw + I];
   Cb^.X0 := JxMax64(Cx0, Int64(Ix0 + I) Shl Cbw);
   Cb^.X1 := JxMin64(Cx1, Int64(Ix0 + I + 1) Shl Cbw);
   Cb^.Y0 := JxMax64(Cy0, Int64(Iy0 + J) Shl Cbh);
   Cb^.Y1 := JxMin64(Cy1, Int64(Iy0 + J + 1) Shl Cbh);
  End;
 JxBuildPBand := True;
End;

Function JxBuildRes(C, K: LongInt): Boolean;
Var
 Tc: ^TJxTComp;
 Rs: ^TJxRes;
 Cd: ^TJxCod;
 Qn: ^TJxQnt;
 Lev, B, Orient, BandIdx, Nb, Xob, Yob, Eps, Mu, Gain, Px, Py, Np: LongInt;
 Rb: LongInt;
Begin
 JxBuildRes := False;
 Tc := @JxTC[C];
 Rs := @Tc^.Res^[K];
 Cd := @JxTileP.Cod[C];
 Qn := @JxTileP.Qnt[C];
 Lev := Tc^.NL - K;
 Rs^.X0 := JxCeilShr(Tc^.X0, Lev);
 Rs^.Y0 := JxCeilShr(Tc^.Y0, Lev);
 Rs^.X1 := JxCeilShr(Tc^.X1, Lev);
 Rs^.Y1 := JxCeilShr(Tc^.Y1, Lev);
 Rs^.W := Rs^.X1 - Rs^.X0;
 Rs^.H := Rs^.Y1 - Rs^.Y0;
 Rs^.PPx := Cd^.PPx[K];
 Rs^.PPy := Cd^.PPy[K];
 Rs^.PW := 0;
 Rs^.PH := 0;
 If (Rs^.X1 > Rs^.X0) And (Rs^.Y1 > Rs^.Y0) Then Begin
  Rs^.PW := JxCeilShr(Rs^.X1, Rs^.PPx) - JxFloorShr(Rs^.X0, Rs^.PPx);
  Rs^.PH := JxCeilShr(Rs^.Y1, Rs^.PPy) - JxFloorShr(Rs^.Y0, Rs^.PPy);
 End;
 If Int64(Rs^.PW) * Rs^.PH + JxTotPrec > 4000000 Then Exit;
 Rs^.PrecBase := JxTotPrec;
 JxTotPrec := JxTotPrec + Int64(Rs^.PW) * Rs^.PH;
 If K = 0 Then Rs^.NB := 1 Else Rs^.NB := 3;
 For B := 0 To Rs^.NB - 1 Do Begin
  If K = 0 Then Begin Orient := 0; BandIdx := 0; End
  Else Begin Orient := B + 1; BandIdx := 3 * (K - 1) + Orient; End;
  Rs^.Bands[B].Orient := Orient;
  If K = 0 Then Begin
   Rs^.Bands[B].X0 := Rs^.X0; Rs^.Bands[B].Y0 := Rs^.Y0;
   Rs^.Bands[B].X1 := Rs^.X1; Rs^.Bands[B].Y1 := Rs^.Y1;
   Rs^.Bands[B].OX := 0; Rs^.Bands[B].OY := 0;
  End Else Begin
   Nb := Lev + 1;
   Xob := Orient And 1;
   Yob := Orient Shr 1;
   Rs^.Bands[B].X0 := JxCeilShr(Int64(Tc^.X0) - (Int64(Xob) Shl (Nb - 1)), Nb);
   Rs^.Bands[B].Y0 := JxCeilShr(Int64(Tc^.Y0) - (Int64(Yob) Shl (Nb - 1)), Nb);
   Rs^.Bands[B].X1 := JxCeilShr(Int64(Tc^.X1) - (Int64(Xob) Shl (Nb - 1)), Nb);
   Rs^.Bands[B].Y1 := JxCeilShr(Int64(Tc^.Y1) - (Int64(Yob) Shl (Nb - 1)), Nb);
   If Xob <> 0 Then Rs^.Bands[B].OX := Tc^.Res^[K - 1].W Else Rs^.Bands[B].OX := 0;
   If Yob <> 0 Then Rs^.Bands[B].OY := Tc^.Res^[K - 1].H Else Rs^.Bands[B].OY := 0;
  End;
  { quantification }
  If Qn^.Sty = 1 Then Begin
   Eps := Qn^.Eps[0];
   Mu := Qn^.Mu[0];
   If BandIdx > 0 Then Eps := Eps - ((BandIdx - 1) Div 3);
   If Eps < 0 Then Eps := 0;
  End Else Begin
   Np := BandIdx;
   If Np >= Qn^.Cnt Then Np := Qn^.Cnt - 1;
   If Np < 0 Then Np := 0;
   Eps := Qn^.Eps[Np];
   Mu := Qn^.Mu[Np];
  End;
  Rs^.Bands[B].Mb := Qn^.Guard + Eps - 1;
  If Orient = 3 Then Gain := 2 Else If Orient = 0 Then Gain := 0 Else Gain := 1;
  Rb := JxPrecC[C] + Gain;
  Rs^.Bands[B].Step := (1.0 + Mu / 2048.0) * JxPow2(Rb - Eps);
 End;
 If Rs^.PW * Rs^.PH > 0 Then Begin
  Rs^.Precs := JxAlloc(Int64(Rs^.PW) * Rs^.PH * SizeOf(TJxPrec));
  If Rs^.Precs = Nil Then Exit;
  For Py := 0 To Rs^.PH - 1 Do
   For Px := 0 To Rs^.PW - 1 Do
    For B := 0 To Rs^.NB - 1 Do
     If Not JxBuildPBand(Cd^, Rs^, Rs^.Bands[B], Rs^.Precs^[Py * Rs^.PW + Px].Bands[B], Px, Py, K) Then Exit;
 End;
 JxBuildRes := True;
End;

Function JxBuildTile(T: LongInt): Boolean;
Var
 Tp, Tq, C, K: LongInt;
 Sz: Int64;
 Tc: ^TJxTComp;
Begin
 JxBuildTile := False;
 Tp := T Mod JxNTX;
 Tq := T Div JxNTX;
 JxTX0 := JxMax64(Int64(JxXTOsiz) + Int64(Tp) * JxXTsiz, JxXOsiz);
 JxTX1 := JxMin64(Int64(JxXTOsiz) + Int64(Tp + 1) * JxXTsiz, JxXsiz);
 JxTY0 := JxMax64(Int64(JxYTOsiz) + Int64(Tq) * JxYTsiz, JxYOsiz);
 JxTY1 := JxMin64(Int64(JxYTOsiz) + Int64(Tq + 1) * JxYTsiz, JxYsiz);
 If (JxTX1 <= JxTX0) Or (JxTY1 <= JxTY0) Then Exit;
 JxTotCblk := 0;
 JxTotPrec := 0;
 For C := 0 To JxNC - 1 Do Begin
  Tc := @JxTC[C];
  Tc^.Buf := Nil;
  Tc^.Res := Nil;
 End;
 For C := 0 To JxNC - 1 Do Begin
  Tc := @JxTC[C];
  Tc^.X0 := JxCeilDiv(JxTX0, JxXR[C]);
  Tc^.Y0 := JxCeilDiv(JxTY0, JxYR[C]);
  Tc^.X1 := JxCeilDiv(JxTX1, JxXR[C]);
  Tc^.Y1 := JxCeilDiv(JxTY1, JxYR[C]);
  Tc^.NL := JxTileP.Cod[C].NL;
  Tc^.Rk := Tc^.NL - JxRed;
  If Tc^.Rk < 0 Then Exit;
  Tc^.Res := JxAlloc(SizeOf(TJxResArr));
  If Tc^.Res = Nil Then Exit;
  For K := 0 To Tc^.NL Do
   If Not JxBuildRes(C, K) Then Exit;
  Tc^.W := Tc^.Res^[Tc^.Rk].W;
  Tc^.H := Tc^.Res^[Tc^.Rk].H;
  Sz := Int64(Tc^.W) * Tc^.H * 4;
  If Sz > 1900000000 Then Exit;
  If Sz > 0 Then Begin
   GetMem(Tc^.Buf, Sz);
   If Tc^.Buf = Nil Then Exit;
   FillChar(Tc^.Buf^, Sz, 0);
  End;
 End;
 JxBuildTile := True;
End;

{ libère les tampons de la tuile courante }
Procedure JxFreeTile;
Var
 C, K, B, P, N: LongInt;
 Tc: ^TJxTComp;
 Rs: ^TJxRes;
 Pb: ^TJxPBand;
 Cb: PJxCblk;
Begin
 For C := 0 To JxNC - 1 Do Begin
  Tc := @JxTC[C];
  If Tc^.Res <> Nil Then
   For K := 0 To Tc^.NL Do Begin
    Rs := @Tc^.Res^[K];
    If Rs^.Precs <> Nil Then
     For P := 0 To Rs^.PW * Rs^.PH - 1 Do
      For B := 0 To Rs^.NB - 1 Do Begin
       Pb := @Rs^.Precs^[P].Bands[B];
       If Pb^.Cblks <> Nil Then
        For N := 0 To Pb^.NCw * Pb^.NCh - 1 Do Begin
         Cb := @Pb^.Cblks^[N];
         If Cb^.Data <> Nil Then Begin FreeMem(Cb^.Data, Cb^.DCap); Cb^.Data := Nil; End;
         If Cb^.Segs <> Nil Then Begin FreeMem(Cb^.Segs, Cb^.SegCap * SizeOf(TJxSeg)); Cb^.Segs := Nil; End;
        End;
      End;
   End;
  If Tc^.Buf <> Nil Then Begin
   FreeMem(Tc^.Buf, Int64(Tc^.W) * Tc^.H * 4);
   Tc^.Buf := Nil;
  End;
  Tc^.Res := Nil;
 End;
 JxFreeArena;
 If JxDone <> Nil Then Begin
  FreeMem(JxDone, (JxDoneBits + 7) Shr 3);
  JxDone := Nil;
 End;
End;

{ ---------------------------------------------------------------------- }
{ Tier-2 : lecture des paquets et ordres de progression                    }
{ ---------------------------------------------------------------------- }

Function JxNextTP: Boolean;
Var
 Tp: LongInt;
Begin
 JxNextTP := False;
 If JxCurTP = -2 Then Exit;
 If JxCurTP = -1 Then Tp := JxTileFirst^[JxCurTile]
 Else Tp := JxTPs^[JxCurTP].Next;
 If Tp < 0 Then Begin JxCurTP := -2; Exit; End;
 JxCurTP := Tp;
 JxPktPos := JxTPs^[Tp].Data;
 JxPktEnd := JxTPs^[Tp].DEnd;
 JxNextTP := True;
End;

Function JxCbAddSeg(Cb: PJxCblk; Sty: LongInt): Boolean;
Var
 NewCap, Mx, Pm: LongInt;
 NS: PJxSegArr;
 Sg: ^TJxSeg;
Begin
 JxCbAddSeg := False;
 If Cb^.SegCnt >= 200 Then Exit;
 If Cb^.SegCnt >= Cb^.SegCap Then Begin
  NewCap := Cb^.SegCap * 2;
  If NewCap < 4 Then NewCap := 4;
  NS := Nil;
  GetMem(NS, NewCap * SizeOf(TJxSeg));
  If NS = Nil Then Begin JxMemErr := True; Exit; End;
  If Cb^.Segs <> Nil Then Begin
   Move(Cb^.Segs^, NS^, Cb^.SegCnt * SizeOf(TJxSeg));
   FreeMem(Cb^.Segs, Cb^.SegCap * SizeOf(TJxSeg));
  End;
  Cb^.Segs := NS;
  Cb^.SegCap := NewCap;
 End;
 If (Sty And JxCbTermAll) <> 0 Then Mx := 1
 Else If (Sty And JxCbLazy) <> 0 Then Begin
  If Cb^.SegCnt = 0 Then Mx := 10
  Else Begin
   Pm := Cb^.Segs^[Cb^.SegCnt - 1].MaxPasses;
   If (Pm = 1) Or (Pm = 10) Then Mx := 2 Else Mx := 1;
  End;
 End Else Mx := 100000;
 Sg := @Cb^.Segs^[Cb^.SegCnt];
 Sg^.Len := 0;
 Sg^.Passes := 0;
 Sg^.MaxPasses := Mx;
 Inc(Cb^.SegCnt);
 JxCbAddSeg := True;
End;

Function JxCbAppend(Cb: PJxCblk; Pos, Len: LongInt): Boolean;
Var
 NewCap: LongInt;
 ND: PBigBytes;
Begin
 JxCbAppend := False;
 If Cb^.DLen + Len + 2 > Cb^.DCap Then Begin
  NewCap := Cb^.DCap * 2;
  If NewCap < Cb^.DLen + Len + 2 Then NewCap := Cb^.DLen + Len + 2;
  If NewCap < 64 Then NewCap := 64;
  ND := Nil;
  GetMem(ND, NewCap);
  If ND = Nil Then Begin JxMemErr := True; Exit; End;
  If Cb^.Data <> Nil Then Begin
   Move(Cb^.Data^, ND^, Cb^.DLen);
   FreeMem(Cb^.Data, Cb^.DCap);
  End;
  Cb^.Data := ND;
  Cb^.DCap := NewCap;
 End;
 If Len > 0 Then Move(JxS^[Pos], Cb^.Data^[Cb^.DLen], Len);
 Inc(Cb^.DLen, Len);
 JxCbAppend := True;
End;

Function JxFloorLog2(V: LongInt): LongInt;
Var
 R: LongInt;
Begin
 R := 0;
 While V > 1 Do Begin V := V Shr 1; Inc(R); End;
 JxFloorLog2 := R;
End;

{ lit un paquet ; retourne False si plus de données exploitables }
Function JxReadPacket(C, R, P, L: LongInt): Boolean;
Var
 Rs: ^TJxRes;
 Pr: ^TJxPrec;
 Pb: ^TJxPBand;
 Cb: PJxCblk;
 Pd: ^TJxPend;
 Sg: ^TJxSeg;
 B, X, Y, I, NP, Sty, NewP, Take, Bits, Ln, Pos, N, Avail, Zb, NewCap, Si: LongInt;
 Incl, Keep, Bad, Trunc: Boolean;
 NPd: PJxPendArr;
Begin
 JxReadPacket := False;
 While JxPktPos >= JxPktEnd Do
  If Not JxNextTP Then Exit;
 Rs := @JxTC[C].Res^[R];
 Pr := @Rs^.Precs^[P];
 Sty := JxTileP.Cod[C].Sty;
 Keep := R <= JxTC[C].Rk;
 { marqueur SOP éventuel }
 If (JxPktPos + 6 <= JxPktEnd) And (JxS^[JxPktPos] = $FF) And (JxS^[JxPktPos + 1] = $91) Then
  Inc(JxPktPos, 6);
 JxHPos := JxPktPos;
 JxHEnd := JxPktEnd;
 JxHBuf := 0;
 JxHCt := 0;
 JxHErr := False;
 Bad := False;
 NP := 0;
 If JxHBit <> 0 Then Begin
  For B := 0 To Rs^.NB - 1 Do Begin
   If Bad Then Break;
   Pb := @Pr^.Bands[B];
   For Y := 0 To Pb^.NCh - 1 Do Begin
    If Bad Then Break;
    For X := 0 To Pb^.NCw - 1 Do Begin
     Cb := @Pb^.Cblks^[Y * Pb^.NCw + X];
     If Cb^.NumPasses = 0 Then Incl := JxTagDec(Pb^.Incl, X, Y, L + 1)
     Else Incl := JxHBit <> 0;
     If JxHErr Then Begin Bad := True; Break; End;
     If Not Incl Then Continue;
     If Cb^.NumPasses = 0 Then Begin
      Zb := 1;
      While Not JxTagDec(Pb^.Zbp, X, Y, Zb) Do Begin
       Inc(Zb);
       If (Zb > 80) Or JxHErr Then Break;
      End;
      If (Zb > 80) Or JxHErr Then Begin Bad := True; Break; End;
      Cb^.NumBps := Rs^.Bands[B].Mb + 1 - Zb;
      Cb^.LBlock := 3;
     End;
     NewP := 1;
     If JxHBit <> 0 Then Begin
      NewP := 2;
      If JxHBit <> 0 Then Begin
       N := JxHBits(2);
       If N <> 3 Then NewP := 3 + N
       Else Begin
        N := JxHBits(5);
        If N <> 31 Then NewP := 6 + N
        Else NewP := 37 + JxHBits(7);
       End;
      End;
     End;
     While (JxHBit <> 0) And (Not JxHErr) Do Begin
      Inc(Cb^.LBlock);
      If Cb^.LBlock > 40 Then Begin JxHErr := True; Break; End;
     End;
     If JxHErr Or (Cb^.NumPasses + NewP > 200) Then Begin Bad := True; Break; End;
     { répartition des passes en segments }
     If Cb^.SegCnt = 0 Then Begin
      If Not JxCbAddSeg(Cb, Sty) Then Begin Bad := True; Break; End;
     End Else If Cb^.Segs^[Cb^.SegCnt - 1].Passes >= Cb^.Segs^[Cb^.SegCnt - 1].MaxPasses Then Begin
      If Not JxCbAddSeg(Cb, Sty) Then Begin Bad := True; Break; End;
     End;
     N := NewP;
     Repeat
      Si := Cb^.SegCnt - 1;
      Sg := @Cb^.Segs^[Si];
      Take := JxMin(Sg^.MaxPasses - Sg^.Passes, N);
      Bits := Cb^.LBlock + JxFloorLog2(Take);
      Ln := JxHBits(Bits);
      If JxHErr Then Begin Bad := True; Break; End;
      If NP >= JxPendCap Then Begin
       NewCap := JxPendCap * 2;
       If NewCap < 256 Then NewCap := 256;
       If NewCap > 16000000 Then Begin Bad := True; Break; End;
       NPd := Nil;
       GetMem(NPd, NewCap * SizeOf(TJxPend));
       If NPd = Nil Then Begin JxMemErr := True; Bad := True; Break; End;
       If JxPend <> Nil Then Begin
        Move(JxPend^, NPd^, NP * SizeOf(TJxPend));
        FreeMem(JxPend, JxPendCap * SizeOf(TJxPend));
       End;
       JxPend := NPd;
       JxPendCap := NewCap;
      End;
      JxPend^[NP].Cb := Cb;
      JxPend^[NP].Seg := Si;
      JxPend^[NP].Len := Ln;
      Inc(NP);
      Inc(Sg^.Passes, Take);
      Dec(N, Take);
      If N > 0 Then
       If Not JxCbAddSeg(Cb, Sty) Then Begin Bad := True; Break; End;
     Until N <= 0;
     If Bad Then Break;
     Inc(Cb^.NumPasses, NewP);
    End;
   End;
  End;
 End;
 If Bad Or JxHErr Then Begin JxStop := True; Exit; End;
 JxHAlign;
 If JxHErr Then Begin JxStop := True; Exit; End;
 Pos := JxHPos;
 { marqueur EPH éventuel }
 If (Pos + 2 <= JxPktEnd) And (JxS^[Pos] = $FF) And (JxS^[Pos + 1] = $92) Then Inc(Pos, 2);
 { corps du paquet }
 Trunc := False;
 For I := 0 To NP - 1 Do Begin
  Pd := @JxPend^[I];
  Avail := JxPktEnd - Pos;
  If Avail < 0 Then Avail := 0;
  Ln := Pd^.Len;
  If Ln > Avail Then Begin Ln := Avail; Trunc := True; End;
  If Keep Then Begin
   If Not JxCbAppend(Pd^.Cb, Pos, Ln) Then Begin JxStop := True; Exit; End;
   Inc(Pd^.Cb^.Segs^[Pd^.Seg].Len, Ln);
  End;
  Inc(Pos, Ln);
  If Trunc Then Break;
 End;
 JxPktPos := Pos;
 If Trunc Then JxStop := True;
 JxReadPacket := True;
End;

{ lit (une seule fois) le paquet (C,R,P,L) }
Function JxPkt(C, R, P, L: LongInt): Boolean;
Var
 Idx: Int64;
Begin
 JxPkt := False;
 If JxStop Then Exit;
 If JxDone <> Nil Then Begin
  Idx := (Int64(JxTC[C].Res^[R].PrecBase) + P) * JxTileP.Layers + L;
  If Idx >= JxDoneBits Then Exit;
  If (PByte(PtrUInt(JxDone) + PtrUInt(Idx Shr 3))^ And (1 Shl (Idx And 7))) <> 0 Then Begin
   JxPkt := True;
   Exit;
  End;
  PByte(PtrUInt(JxDone) + PtrUInt(Idx Shr 3))^ :=
   PByte(PtrUInt(JxDone) + PtrUInt(Idx Shr 3))^ Or (1 Shl (Idx And 7));
 End;
 If Not JxReadPacket(C, R, P, L) Then Begin
  JxStop := True;
  Exit;
 End;
 JxPkt := Not JxStop;
End;

{ indice du précinct de (C,R) couvrant la position de référence (X,Y), ou -1 }
Function JxPrecAt(C, R: LongInt; X, Y: Int64): LongInt;
Var
 Rs: ^TJxRes;
 Lev, Rpx, Rpy: LongInt;
 Pi, Pj: Int64;
Begin
 JxPrecAt := -1;
 Rs := @JxTC[C].Res^[R];
 If (Rs^.PW = 0) Or (Rs^.PH = 0) Then Exit;
 Lev := JxTC[C].NL - R;
 Rpx := Rs^.PPx + Lev;
 Rpy := Rs^.PPy + Lev;
 If Not (((Y Mod (Int64(JxYR[C]) Shl Rpy)) = 0) Or
         ((Y = JxTY0) And (((Int64(Rs^.Y0) Shl Lev) Mod (Int64(1) Shl Rpy)) <> 0))) Then Exit;
 If Not (((X Mod (Int64(JxXR[C]) Shl Rpx)) = 0) Or
         ((X = JxTX0) And (((Int64(Rs^.X0) Shl Lev) Mod (Int64(1) Shl Rpx)) <> 0))) Then Exit;
 Pi := JxFloorShr(JxCeilDiv(X, Int64(JxXR[C]) Shl Lev), Rs^.PPx) - JxFloorShr(Rs^.X0, Rs^.PPx);
 Pj := JxFloorShr(JxCeilDiv(Y, Int64(JxYR[C]) Shl Lev), Rs^.PPy) - JxFloorShr(Rs^.Y0, Rs^.PPy);
 If (Pi < 0) Or (Pi >= Rs^.PW) Or (Pj < 0) Or (Pj >= Rs^.PH) Then Exit;
 JxPrecAt := Pi + Pj * Rs^.PW;
End;

{ exécute un volume de progression }
Procedure JxRunProg(Prog, RS, RE, CS, CE, LE: LongInt);
Var
 L, R, C, P, Np, Pi: LongInt;
 X, Y, Dx, Dy, Sx, Sy: Int64;
Begin
 If RE > 33 Then RE := 33;
 If CE > JxNC Then CE := JxNC;
 If LE > JxTileP.Layers Then LE := JxTileP.Layers;
 Case Prog Of
  0: Begin
   For L := 0 To LE - 1 Do
    For R := RS To RE - 1 Do
     For C := CS To CE - 1 Do
      If R <= JxTC[C].NL Then Begin
       Np := JxTC[C].Res^[R].PW * JxTC[C].Res^[R].PH;
       For P := 0 To Np - 1 Do
        If Not JxPkt(C, R, P, L) Then Exit;
      End;
  End;
  1: Begin
   For R := RS To RE - 1 Do
    For L := 0 To LE - 1 Do
     For C := CS To CE - 1 Do
      If R <= JxTC[C].NL Then Begin
       Np := JxTC[C].Res^[R].PW * JxTC[C].Res^[R].PH;
       For P := 0 To Np - 1 Do
        If Not JxPkt(C, R, P, L) Then Exit;
      End;
  End;
 Else
  { progressions basées sur la position : pas minimal sur la grille de référence }
  Dx := 0; Dy := 0;
  For C := CS To CE - 1 Do
   For R := 0 To JxTC[C].NL Do Begin
    Sx := Int64(JxXR[C]) Shl (JxTC[C].Res^[R].PPx + JxTC[C].NL - R);
    Sy := Int64(JxYR[C]) Shl (JxTC[C].Res^[R].PPy + JxTC[C].NL - R);
    If (Dx = 0) Or (Sx < Dx) Then Dx := Sx;
    If (Dy = 0) Or (Sy < Dy) Then Dy := Sy;
   End;
  If (Dx <= 0) Or (Dy <= 0) Then Exit;
  Case Prog Of
   2: Begin   { RPCL }
    For R := RS To RE - 1 Do Begin
     Y := JxTY0;
     While Y < JxTY1 Do Begin
      X := JxTX0;
      While X < JxTX1 Do Begin
       For C := CS To CE - 1 Do
        If R <= JxTC[C].NL Then Begin
         Pi := JxPrecAt(C, R, X, Y);
         If Pi >= 0 Then
          For L := 0 To LE - 1 Do
           If Not JxPkt(C, R, Pi, L) Then Exit;
        End;
       X := X + (Dx - (X Mod Dx));
      End;
      Y := Y + (Dy - (Y Mod Dy));
     End;
    End;
   End;
   3: Begin   { PCRL }
    Y := JxTY0;
    While Y < JxTY1 Do Begin
     X := JxTX0;
     While X < JxTX1 Do Begin
      For C := CS To CE - 1 Do
       For R := RS To RE - 1 Do
        If R <= JxTC[C].NL Then Begin
         Pi := JxPrecAt(C, R, X, Y);
         If Pi >= 0 Then
          For L := 0 To LE - 1 Do
           If Not JxPkt(C, R, Pi, L) Then Exit;
        End;
      X := X + (Dx - (X Mod Dx));
     End;
     Y := Y + (Dy - (Y Mod Dy));
    End;
   End;
   4: Begin   { CPRL }
    For C := CS To CE - 1 Do Begin
     Y := JxTY0;
     While Y < JxTY1 Do Begin
      X := JxTX0;
      While X < JxTX1 Do Begin
       For R := RS To RE - 1 Do
        If R <= JxTC[C].NL Then Begin
         Pi := JxPrecAt(C, R, X, Y);
         If Pi >= 0 Then
          For L := 0 To LE - 1 Do
           If Not JxPkt(C, R, Pi, L) Then Exit;
        End;
       X := X + (Dx - (X Mod Dx));
      End;
      Y := Y + (Dy - (Y Mod Dy));
     End;
    End;
   End;
  End;
 End;
End;

{ lit tous les paquets de la tuile }
Procedure JxReadPackets;
Var
 I, MaxNL, C: LongInt;
 Sz: Int64;
Begin
 JxCurTP := -1;
 JxPktPos := 0;
 JxPktEnd := 0;
 JxStop := False;
 MaxNL := 0;
 For C := 0 To JxNC - 1 Do
  If JxTC[C].NL > MaxNL Then MaxNL := JxTC[C].NL;
 If JxTileP.NPoc > 0 Then Begin
  Sz := JxTotPrec * JxTileP.Layers;
  If Sz > 400000000 Then Exit;
  JxDoneBits := Sz;
  GetMem(JxDone, (Sz + 7) Shr 3);
  If JxDone = Nil Then Begin JxMemErr := True; Exit; End;
  FillChar(JxDone^, (Sz + 7) Shr 3, 0);
  For I := 0 To JxTileP.NPoc - 1 Do Begin
   JxRunProg(JxTileP.Poc[I].Prog, JxTileP.Poc[I].RS, JxTileP.Poc[I].RE,
             JxTileP.Poc[I].CS, JxTileP.Poc[I].CE, JxTileP.Poc[I].LYE);
   If JxStop Then Break;
  End;
 End Else
  JxRunProg(JxTileP.Prog, 0, MaxNL + 1, 0, JxNC, JxTileP.Layers);
End;

{ ---------------------------------------------------------------------- }
{ Tier-1 sur toute la tuile, déquantification                             }
{ ---------------------------------------------------------------------- }

Procedure JxStoreBlock(Tc: Pointer; Cb: PJxCblk; Var Bd: TJxBand; BW, BH: LongInt; Rev: Boolean);
Var
 T: ^TJxTComp;
 W, H, Dx, Dy, X, Y, V: LongInt;
 Pl: PJxLArr;
 Ps: PJxSArr;
 Sc, F: Single;
Begin
 T := Tc;
 W := Cb^.X1 - Cb^.X0;
 H := Cb^.Y1 - Cb^.Y0;
 Dx := Bd.OX + (Cb^.X0 - Bd.X0);
 Dy := Bd.OY + (Cb^.Y0 - Bd.Y0);
 If (Dx < 0) Or (Dy < 0) Or (Dx + W > T^.W) Or (Dy + H > T^.H) Then Exit;
 If Rev Then Begin
  Pl := T^.Buf;
  For Y := 0 To H - 1 Do
   For X := 0 To W - 1 Do Begin
    V := JxData[Y * W + X] Div 2;
    If V > 67108864 Then V := 67108864 Else If V < -67108864 Then V := -67108864;
    Pl^[(Dy + Y) * T^.W + Dx + X] := V;
   End;
 End Else Begin
  Ps := T^.Buf;
  Sc := Bd.Step * 0.5;
  For Y := 0 To H - 1 Do
   For X := 0 To W - 1 Do Begin
    F := JxData[Y * W + X] * Sc;
    If F > 67108864.0 Then F := 67108864.0 Else If F < -67108864.0 Then F := -67108864.0;
    Ps^[(Dy + Y) * T^.W + Dx + X] := F;
   End;
 End;
End;

Procedure JxT1Comp(C: LongInt);
Var
 Tc: ^TJxTComp;
 Rs: ^TJxRes;
 Pb: ^TJxPBand;
 Cb: PJxCblk;
 K, B, P, N, Sty, Roi: LongInt;
 Rev: Boolean;
Begin
 Tc := @JxTC[C];
 If Tc^.Buf = Nil Then Exit;
 Sty := JxTileP.Cod[C].Sty;
 Roi := JxTileP.Roi[C];
 Rev := JxTileP.Cod[C].Transf = 1;
 For K := 0 To Tc^.Rk Do Begin
  Rs := @Tc^.Res^[K];
  If Rs^.Precs <> Nil Then
   For P := 0 To Rs^.PW * Rs^.PH - 1 Do
    For B := 0 To Rs^.NB - 1 Do Begin
     Pb := @Rs^.Precs^[P].Bands[B];
     If Pb^.Cblks <> Nil Then
      For N := 0 To Pb^.NCw * Pb^.NCh - 1 Do Begin
       Cb := @Pb^.Cblks^[N];
       If JxDecodeBlock(Cb, Rs^.Bands[B].Orient, Sty, Roi) Then
        JxStoreBlock(Tc, Cb, Rs^.Bands[B], 0, 0, Rev);
       If Cb^.Data <> Nil Then Begin FreeMem(Cb^.Data, Cb^.DCap); Cb^.Data := Nil; Cb^.DCap := 0; Cb^.DLen := 0; End;
       If Cb^.Segs <> Nil Then Begin FreeMem(Cb^.Segs, Cb^.SegCap * SizeOf(TJxSeg)); Cb^.Segs := Nil; Cb^.SegCap := 0; Cb^.SegCnt := 0; End;
      End;
    End;
 End;
End;

{ ---------------------------------------------------------------------- }
{ Transformée en ondelettes inverse 5/3 (entière) et 9/7 (flottante)       }
{ ---------------------------------------------------------------------- }

Const
 JxOff = $40000000;
 JxAlpha = -1.586134342059924;
 JxBeta = -0.052980118572961;
 JxGamma = 0.882911075530934;
 JxDelta = 0.443506852043971;
 JxK = 1.230174104914001;

{ filtre 5/3, ligne : T de N éléments entrelacés, Odd = parité de la 1ère coordonnée }
Procedure JxLift53(T: PJxLArr; N, Odd: LongInt);
Var
 J: LongInt;
Begin
 J := Odd;
 If J = 0 Then Begin
  T^[0] := T^[0] - ((T^[1] * 2 + 2 + JxOff) Shr 2 - (JxOff Shr 2));
  J := 2;
 End;
 While J < N - 1 Do Begin
  T^[J] := T^[J] - ((T^[J - 1] + T^[J + 1] + 2 + JxOff) Shr 2 - (JxOff Shr 2));
  Inc(J, 2);
 End;
 If J = N - 1 Then
  T^[J] := T^[J] - ((T^[J - 1] * 2 + 2 + JxOff) Shr 2 - (JxOff Shr 2));
 J := 1 - Odd;
 If J = 0 Then Begin
  T^[0] := T^[0] + T^[1];
  J := 2;
 End;
 While J < N - 1 Do Begin
  T^[J] := T^[J] + ((T^[J - 1] + T^[J + 1] + JxOff) Shr 1 - (JxOff Shr 1));
  Inc(J, 2);
 End;
 If J = N - 1 Then
  T^[J] := T^[J] + T^[J - 1];
End;

Procedure JxLiftF(T: PJxSArr; N, Start: LongInt; Cf: Single);
Var
 J: LongInt;
Begin
 J := Start;
 If J = 0 Then Begin
  T^[0] := T^[0] - Cf * (T^[1] * 2);
  J := 2;
 End;
 While J < N - 1 Do Begin
  T^[J] := T^[J] - Cf * (T^[J - 1] + T^[J + 1]);
  Inc(J, 2);
 End;
 If J = N - 1 Then
  T^[J] := T^[J] - Cf * (T^[J - 1] * 2);
End;

{ idem, colonnes : T contient N lignes de Cw éléments }
Procedure JxLift53C(T: PJxLArr; N, Cw, Odd: LongInt);
Var
 J, A, B, X, Ja, Jb, Jj: LongInt;
Begin
 J := Odd;
 While J < N Do Begin
  A := J - 1; B := J + 1;
  If A < 0 Then A := B;
  If B >= N Then B := A;
  Jj := J * Cw; Ja := A * Cw; Jb := B * Cw;
  For X := 0 To Cw - 1 Do
   T^[Jj + X] := T^[Jj + X] - ((T^[Ja + X] + T^[Jb + X] + 2 + JxOff) Shr 2 - (JxOff Shr 2));
  Inc(J, 2);
 End;
 J := 1 - Odd;
 While J < N Do Begin
  A := J - 1; B := J + 1;
  If A < 0 Then A := B;
  If B >= N Then B := A;
  Jj := J * Cw; Ja := A * Cw; Jb := B * Cw;
  For X := 0 To Cw - 1 Do
   T^[Jj + X] := T^[Jj + X] + ((T^[Ja + X] + T^[Jb + X] + JxOff) Shr 1 - (JxOff Shr 1));
  Inc(J, 2);
 End;
End;

Procedure JxLiftFC(T: PJxSArr; N, Cw, Start: LongInt; Cf: Single);
Var
 J, A, B, X, Ja, Jb, Jj: LongInt;
Begin
 J := Start;
 While J < N Do Begin
  A := J - 1; B := J + 1;
  If A < 0 Then A := B;
  If B >= N Then B := A;
  Jj := J * Cw; Ja := A * Cw; Jb := B * Cw;
  For X := 0 To Cw - 1 Do
   T^[Jj + X] := T^[Jj + X] - Cf * (T^[Ja + X] + T^[Jb + X]);
  Inc(J, 2);
 End;
End;

{ IDWT d'un niveau sur le rectangle W x H du tampon (pas Stride) }
Function JxIdwtLevel(Buf: Pointer; Stride, W, H, Wl, Hl, OddX, OddY: LongInt;
  Rev: Boolean; Tmp: Pointer; TmpN: LongInt): Boolean;
Var
 Y, X, J, Base, Src, Cw, X0, Bw: LongInt;
 Bi, Ti: PJxLArr;
 Bf, Tf: PJxSArr;
 InvK, F: Single;
Begin
 JxIdwtLevel := False;
 If OddX = 0 Then Begin
  If Wl <> (W + 1) Div 2 Then Exit;
 End Else If Wl <> W Div 2 Then Exit;
 If OddY = 0 Then Begin
  If Hl <> (H + 1) Div 2 Then Exit;
 End Else If Hl <> H Div 2 Then Exit;
 Bi := Buf; Ti := Tmp;
 Bf := Buf; Tf := Tmp;
 InvK := 1.0 / JxK;
 { passe horizontale }
 If W < 2 Then Begin
  If (W = 1) And (OddX = 1) Then
   For Y := 0 To H - 1 Do
    If Rev Then Bi^[Y * Stride] := Bi^[Y * Stride] Div 2
    Else Bf^[Y * Stride] := Bf^[Y * Stride] * 0.5;
 End Else Begin
  For Y := 0 To H - 1 Do Begin
   Base := Y * Stride;
   If Rev Then Begin
    For J := 0 To W - 1 Do Begin
     If ((J + OddX) And 1) = 0 Then Ti^[J] := Bi^[Base + (J Shr 1)]
     Else Ti^[J] := Bi^[Base + Wl + (J Shr 1)];
    End;
    JxLift53(Ti, W, OddX);
    For J := 0 To W - 1 Do Begin
     X := Ti^[J];
     If X > 134217728 Then X := 134217728 Else If X < -134217728 Then X := -134217728;
     Bi^[Base + J] := X;
    End;
   End Else Begin
    For J := 0 To W - 1 Do Begin
     If ((J + OddX) And 1) = 0 Then Tf^[J] := Bf^[Base + (J Shr 1)] * JxK
     Else Tf^[J] := Bf^[Base + Wl + (J Shr 1)] * InvK;
    End;
    JxLiftF(Tf, W, OddX, JxDelta);
    JxLiftF(Tf, W, 1 - OddX, JxGamma);
    JxLiftF(Tf, W, OddX, JxBeta);
    JxLiftF(Tf, W, 1 - OddX, JxAlpha);
    For J := 0 To W - 1 Do Begin
     F := Tf^[J];
     If F > 67108864.0 Then F := 67108864.0 Else If F < -67108864.0 Then F := -67108864.0;
     Bf^[Base + J] := F;
    End;
   End;
  End;
 End;
 { passe verticale par blocs de colonnes }
 If H < 2 Then Begin
  If (H = 1) And (OddY = 1) Then
   For X := 0 To W - 1 Do
    If Rev Then Bi^[X] := Bi^[X] Div 2 Else Bf^[X] := Bf^[X] * 0.5;
 End Else Begin
  Cw := TmpN Div H;
  If Cw > 16 Then Cw := 16;
  If Cw < 1 Then Exit;
  X0 := 0;
  While X0 < W Do Begin
   Bw := W - X0;
   If Bw > Cw Then Bw := Cw;
   For J := 0 To H - 1 Do Begin
    If ((J + OddY) And 1) = 0 Then Src := (J Shr 1) Else Src := Hl + (J Shr 1);
    Base := Src * Stride + X0;
    If Rev Then
     For X := 0 To Bw - 1 Do Ti^[J * Bw + X] := Bi^[Base + X]
    Else Begin
     If ((J + OddY) And 1) = 0 Then
      For X := 0 To Bw - 1 Do Tf^[J * Bw + X] := Bf^[Base + X] * JxK
     Else
      For X := 0 To Bw - 1 Do Tf^[J * Bw + X] := Bf^[Base + X] * InvK;
    End;
   End;
   If Rev Then JxLift53C(Ti, H, Bw, OddY)
   Else Begin
    JxLiftFC(Tf, H, Bw, OddY, JxDelta);
    JxLiftFC(Tf, H, Bw, 1 - OddY, JxGamma);
    JxLiftFC(Tf, H, Bw, OddY, JxBeta);
    JxLiftFC(Tf, H, Bw, 1 - OddY, JxAlpha);
   End;
   For J := 0 To H - 1 Do Begin
    Base := J * Stride + X0;
    If Rev Then
     For X := 0 To Bw - 1 Do Begin
      Src := Ti^[J * Bw + X];
      If Src > 134217728 Then Src := 134217728 Else If Src < -134217728 Then Src := -134217728;
      Bi^[Base + X] := Src;
     End
    Else
     For X := 0 To Bw - 1 Do Begin
      F := Tf^[J * Bw + X];
      If F > 67108864.0 Then F := 67108864.0 Else If F < -67108864.0 Then F := -67108864.0;
      Bf^[Base + X] := F;
     End;
   End;
   Inc(X0, Bw);
  End;
 End;
 JxIdwtLevel := True;
End;

Function JxIdwtComp(C: LongInt): Boolean;
Var
 Tc: ^TJxTComp;
 K, MaxW, MaxH, TmpN: LongInt;
 Rev: Boolean;
 Tmp: Pointer;
 Sz: Int64;
Begin
 JxIdwtComp := True;
 Tc := @JxTC[C];
 If (Tc^.Buf = Nil) Or (Tc^.Rk < 1) Then Exit;
 Rev := JxTileP.Cod[C].Transf = 1;
 MaxW := 1; MaxH := 1;
 For K := 1 To Tc^.Rk Do Begin
  MaxW := JxMax(MaxW, Tc^.Res^[K].W);
  MaxH := JxMax(MaxH, Tc^.Res^[K].H);
 End;
 TmpN := 8192 + 16 * MaxH;
 If TmpN < MaxW Then TmpN := MaxW;
 If TmpN < MaxH Then TmpN := MaxH;
 Sz := Int64(TmpN) * 4;
 Tmp := Nil;
 GetMem(Tmp, Sz);
 If Tmp = Nil Then Begin JxIdwtComp := False; JxMemErr := True; Exit; End;
 For K := 1 To Tc^.Rk Do
  If (Tc^.Res^[K].W > 0) And (Tc^.Res^[K].H > 0) Then
   If Not JxIdwtLevel(Tc^.Buf, Tc^.W, Tc^.Res^[K].W, Tc^.Res^[K].H, Tc^.Res^[K - 1].W,
        Tc^.Res^[K - 1].H, Tc^.Res^[K].X0 And 1, Tc^.Res^[K].Y0 And 1, Rev, Tmp, TmpN) Then Break;
 FreeMem(Tmp, Sz);
End;

{ ---------------------------------------------------------------------- }
{ Transformée de composantes inverse, niveau DC, passage en 8 bits         }
{ ---------------------------------------------------------------------- }

Procedure JxInvMCT;
Var
 I, N, Y0, Y1, Y2, G: LongInt;
 A, B, C: PJxLArr;
 Fa, Fb, Fc: PJxSArr;
 Yv, Cb, Cr: Single;
Begin
 If (JxTileP.MCT <> 1) Or (JxNC < 3) Then Exit;
 If (JxTC[0].W <> JxTC[1].W) Or (JxTC[0].W <> JxTC[2].W) Or (JxTC[0].H <> JxTC[1].H) Or
    (JxTC[0].H <> JxTC[2].H) Then Exit;
 If (JxTC[0].Buf = Nil) Or (JxTC[1].Buf = Nil) Or (JxTC[2].Buf = Nil) Then Exit;
 If (JxTileP.Cod[0].Transf <> JxTileP.Cod[1].Transf) Or
    (JxTileP.Cod[0].Transf <> JxTileP.Cod[2].Transf) Then Exit;
 N := JxTC[0].W * JxTC[0].H;
 If JxTileP.Cod[0].Transf = 1 Then Begin
  A := JxTC[0].Buf; B := JxTC[1].Buf; C := JxTC[2].Buf;
  For I := 0 To N - 1 Do Begin
   Y0 := A^[I]; Y1 := B^[I]; Y2 := C^[I];
   G := Y0 - ((Y1 + Y2 + JxOff) Shr 2 - (JxOff Shr 2));
   A^[I] := Y2 + G;
   B^[I] := G;
   C^[I] := Y1 + G;
  End;
 End Else Begin
  Fa := JxTC[0].Buf; Fb := JxTC[1].Buf; Fc := JxTC[2].Buf;
  For I := 0 To N - 1 Do Begin
   Yv := Fa^[I]; Cb := Fb^[I]; Cr := Fc^[I];
   Fa^[I] := Yv + 1.402 * Cr;
   Fb^[I] := Yv - 0.34413 * Cb - 0.71414 * Cr;
   Fc^[I] := Yv + 1.772 * Cb;
  End;
 End;
End;

{ copie la composante C de la tuile dans son plan 8 bits (ou 16 bits si palette) }
Procedure JxPutComp(C: LongInt);
Var
 Tc: ^TJxTComp;
 Rev: Boolean;
 Prec, Shift, MaxV, Px0, Py0, X, Y, V, W, H, Sh8, Pw: LongInt;
 Lut: Array[0..255] Of Byte;
 Il: PJxLArr;
 Fs: PJxSArr;
 Dst: PJxBArr;
 Dw: PJxWArr;
 F, Fsh: Single;
 Isw: Boolean;
Begin
 Tc := @JxTC[C];
 If (Tc^.Buf = Nil) Or (JxPlane[C] = Nil) Then Exit;
 W := Tc^.W; H := Tc^.H;
 Px0 := Tc^.Res^[Tc^.Rk].X0 - JxPlaneX0[C];
 Py0 := Tc^.Res^[Tc^.Rk].Y0 - JxPlaneY0[C];
 Pw := JxPlaneW[C];
 If (Px0 < 0) Or (Py0 < 0) Or (Px0 + W > Pw) Or (Py0 + H > JxPlaneH[C]) Then Exit;
 Rev := JxTileP.Cod[C].Transf = 1;
 Prec := JxPrecC[C];
 Shift := 1 Shl (Prec - 1);
 MaxV := (1 Shl Prec) - 1;
 Isw := JxPlaneWord[C];
 If Prec > 8 Then Sh8 := Prec - 8 Else Sh8 := 0;
 If Prec < 8 Then
  For V := 0 To MaxV Do Lut[V] := (V * 255) Div MaxV;
 Il := Tc^.Buf;
 Fs := Tc^.Buf;
 Fsh := Shift + 0.5;
 For Y := 0 To H - 1 Do Begin
  Dst := PJxBArr(PtrUInt(JxPlane[C]) + PtrUInt(Int64(Py0 + Y) * Pw + Px0));
  Dw := PJxWArr(PtrUInt(JxPlane[C]) + PtrUInt((Int64(Py0 + Y) * Pw + Px0) * 2));
  For X := 0 To W - 1 Do Begin
   If Rev Then Begin
    V := Il^[Y * W + X] + Shift;
    If V < 0 Then V := 0 Else If V > MaxV Then V := MaxV;
   End Else Begin
    F := Fs^[Y * W + X] + Fsh;
    If F <= 0 Then V := 0
    Else If F >= MaxV + 1 Then V := MaxV
    Else V := Trunc(F);
    If V > MaxV Then V := MaxV;
   End;
   If Isw Then Dw^[X] := V
   Else If Prec = 8 Then Dst^[X] := V
   Else If Prec > 8 Then Dst^[X] := V Shr Sh8
   Else Dst^[X] := Lut[V];
  End;
 End;
End;

{ décode la tuile T ; retourne False en cas d'erreur fatale (mémoire) }
Function JxDecodeTile(T: LongInt): Boolean;
Var
 C: LongInt;
 Ok: Boolean;
Begin
 JxDecodeTile := True;
 JxMemErr := False;
 If Not JxLoadTile(T) Then Exit;
 JxCurTile := T;
 Ok := JxBuildTile(T);
 If Ok Then Begin
  JxReadPackets;
  If JxMemErr Then Ok := False;
 End;
 If Ok Then Begin
  For C := 0 To JxNC - 1 Do JxT1Comp(C);
  For C := 0 To JxNC - 1 Do
   If Not JxIdwtComp(C) Then Ok := False;
 End;
 If Ok Then Begin
  JxInvMCT;
  For C := 0 To JxNC - 1 Do JxPutComp(C);
 End;
 JxFreeTile;
 If JxMemErr Then JxDecodeTile := False;
End;

{ ---------------------------------------------------------------------- }
{ Conteneur JP2                                                            }
{ ---------------------------------------------------------------------- }

Procedure JxParseJp2h(A, B: LongInt);
Var
 Pos, H, Q, N, I, E, Nb, D, Ne, Npc: LongInt;
 L, Ty: Int64;
Begin
 Pos := A;
 While Pos + 8 <= B Do Begin
  L := JxBE32(Pos);
  Ty := JxBE32(Pos + 4);
  H := 8;
  If L = 1 Then Begin
   H := 16;
   If Pos + 16 > B Then Break;
   If JxBE32(Pos + 8) <> 0 Then L := B - Pos Else L := JxBE32(Pos + 12);
  End Else If L = 0 Then L := B - Pos;
  If (L < H) Or (Pos + L > B) Then L := B - Pos;
  If L < H Then Break;
  Q := Pos + H;
  N := L - H;
  Case Ty Of
   $636F6C72: Begin   { colr }
    If (JxEnumCS < 0) And (N >= 3) Then Begin
     If (JxS^[Q] = 1) And (N >= 7) Then Begin
      If JxBE32(Q + 3) < 65536 Then JxEnumCS := JxBE32(Q + 3) Else JxEnumCS := 0;
     End Else If JxS^[Q] = 2 Then JxEnumCS := 0;
    End;
   End;
   $70636C72: Begin   { pclr }
    If (Not JxHavePal) And (N >= 4) Then Begin
     Ne := JxBE16(Q);
     Npc := JxS^[Q + 2];
     If (Ne >= 1) And (Ne <= 1024) And (Npc >= 1) And (Npc <= 8) And (N >= 3 + Npc) Then Begin
      Nb := 0;
      For I := 0 To Npc - 1 Do Begin
       JxPalDepth[I] := (JxS^[Q + 3 + I] And $7F) + 1;
       Inc(Nb, (JxPalDepth[I] + 7) Div 8);
       If JxPalDepth[I] > 16 Then Nb := 1000000;
      End;
      If N >= 3 + Npc + Ne * Nb Then Begin
       JxPal := Nil;
       GetMem(JxPal, Ne * Npc * 4);
       If JxPal <> Nil Then Begin
        E := Q + 3 + Npc;
        For I := 0 To Ne - 1 Do
         For D := 0 To Npc - 1 Do Begin
          Nb := (JxPalDepth[D] + 7) Div 8;
          JxPal^[I * Npc + D] := 0;
          While Nb > 0 Do Begin
           JxPal^[I * Npc + D] := (JxPal^[I * Npc + D] Shl 8) Or JxS^[E];
           Inc(E);
           Dec(Nb);
          End;
         End;
        JxPalN := Ne;
        JxPalNC := Npc;
        JxHavePal := True;
       End;
      End;
     End;
    End;
   End;
   $636D6170: Begin   { cmap }
    JxNCmap := JxMin(N Div 4, JxMaxC);
    For I := 0 To JxNCmap - 1 Do Begin
     JxCmapC[I] := JxBE16(Q + 4 * I);
     JxCmapT[I] := JxS^[Q + 4 * I + 2];
     JxCmapP[I] := JxS^[Q + 4 * I + 3];
    End;
   End;
   $63646566: Begin   { cdef }
    If N >= 2 Then Begin
     JxNCdef := JxMin(JxBE16(Q), JxMaxC);
     If JxNCdef * 6 + 2 > N Then JxNCdef := (N - 2) Div 6;
     For I := 0 To JxNCdef - 1 Do Begin
      JxCdefN[I] := JxBE16(Q + 2 + 6 * I);
      JxCdefT[I] := JxBE16(Q + 4 + 6 * I);
      JxCdefA[I] := JxBE16(Q + 6 + 6 * I);
     End;
    End;
   End;
  End;
  Inc(Pos, L);
 End;
End;

{ localise le codestream : brut (FF4F) ou dans une boîte jp2c }
Function JxFindCodestream(Var Cs0, CsLen: LongInt): Boolean;
Var
 Pos, H, I: LongInt;
 L, Ty: Int64;
Begin
 JxFindCodestream := False;
 If (JxS^[0] = $FF) And (JxS^[1] = $4F) Then Begin
  Cs0 := 0; CsLen := JxSLen;
  JxFindCodestream := True;
  Exit;
 End;
 Pos := 0;
 While Pos + 8 <= JxSLen Do Begin
  L := JxBE32(Pos);
  Ty := JxBE32(Pos + 4);
  H := 8;
  If L = 1 Then Begin
   H := 16;
   If Pos + 16 > JxSLen Then Break;
   If JxBE32(Pos + 8) <> 0 Then L := JxSLen - Pos Else L := JxBE32(Pos + 12);
  End Else If L = 0 Then L := JxSLen - Pos;
  If (L < H) Or (Pos + L > JxSLen) Then L := JxSLen - Pos;
  If L < H Then Break;
  If Ty = $6A703268 Then JxParseJp2h(Pos + H, Pos + L)   { jp2h }
  Else If Ty = $6A703263 Then Begin                         { jp2c }
   Cs0 := Pos + H;
   CsLen := L - H;
   JxFindCodestream := CsLen >= 4;
   Exit;
  End;
  Inc(Pos, L);
 End;
 { dernier recours : chercher SOC + SIZ }
 For I := 0 To JxSLen - 6 Do
  If (JxS^[I] = $FF) And (JxS^[I + 1] = $4F) And (JxS^[I + 2] = $FF) And (JxS^[I + 3] = $51) Then Begin
   Cs0 := I; CsLen := JxSLen - I;
   JxFindCodestream := True;
   Exit;
  End;
End;

{ ---------------------------------------------------------------------- }
{ Assemblage final : canaux, palette, ré-échantillonnage, entrelacement     }
{ ---------------------------------------------------------------------- }

Function JxPlaneVal(C, Idx: LongInt): LongInt;
Begin
 If JxPlaneWord[C] Then JxPlaneVal := PJxWArr(JxPlane[C])^[Idx]
 Else JxPlaneVal := JxPlane[C]^[Idx];
End;

Function JxClamp8(V: LongInt): LongInt;
Begin
 If V < 0 Then JxClamp8 := 0 Else If V > 255 Then JxClamp8 := 255 Else JxClamp8 := V;
End;

Function JxScale8(V, Depth: LongInt): LongInt;
Begin
 If Depth = 8 Then JxScale8 := JxClamp8(V)
 Else If Depth > 8 Then JxScale8 := JxClamp8(V Shr (Depth - 8))
 Else JxScale8 := JxClamp8((V * 255) Div ((1 Shl Depth) - 1));
End;

{ construit l'image de sortie 8 bits entrelacée à partir des plans }
Function JxAssemble(Var OutW, OutH, OutComps, ColSpace: LongInt; Var Pix: PBigBytes): Boolean;
Var
 NCh, I, J, K, X, Y, Sy, Nmap, Ncol, Expect: LongInt;
 ChComp, ChMode, ChCol, ChTyp, ChAsoc, Lst: Array[0..JxMaxC - 1] Of LongInt;
 Sel: Array[0..3] Of LongInt;
 XMap: Array[0..3] Of PJxLArr;
 Tot: Int64;
 Row: PJxBArr;
 V, Idx, Dp: LongInt;
 Ok: Boolean;
 R, G, B, Yy, Cb, Cr: LongInt;
Begin
 JxAssemble := False;
 { liste des canaux }
 NCh := 0;
 If JxHavePal And (JxNCmap > 0) Then Begin
  For I := 0 To JxNCmap - 1 Do
   If (JxCmapC[I] < JxNC) And (NCh < JxMaxC) Then Begin
    ChComp[NCh] := JxCmapC[I];
    If (JxCmapT[I] = 1) And (JxCmapP[I] < JxPalNC) Then Begin
     ChMode[NCh] := 1; ChCol[NCh] := JxCmapP[I];
    End Else Begin
     ChMode[NCh] := 0; ChCol[NCh] := 0;
    End;
    ChTyp[NCh] := 0; ChAsoc[NCh] := NCh + 1;
    Inc(NCh);
   End;
 End Else If JxHavePal Then Begin
  For I := 0 To JxPalNC - 1 Do Begin
   ChComp[NCh] := 0; ChMode[NCh] := 1; ChCol[NCh] := I;
   ChTyp[NCh] := 0; ChAsoc[NCh] := NCh + 1;
   Inc(NCh);
  End;
 End Else Begin
  For I := 0 To JxNC - 1 Do Begin
   ChComp[NCh] := I; ChMode[NCh] := 0; ChCol[NCh] := 0;
   ChTyp[NCh] := 0; ChAsoc[NCh] := NCh + 1;
   Inc(NCh);
  End;
 End;
 If NCh = 0 Then Exit;
 { définition des canaux (cdef) }
 For I := 0 To JxNCdef - 1 Do
  If JxCdefN[I] < NCh Then Begin
   ChTyp[JxCdefN[I]] := JxCdefT[I];
   ChAsoc[JxCdefN[I]] := JxCdefA[I];
   If ChAsoc[JxCdefN[I]] = 0 Then ChAsoc[JxCdefN[I]] := 65535;
  End;
 { canaux de couleur (Typ = 0), triés par association croissante }
 FillChar(Lst, SizeOf(Lst), 0);
 Ncol := 0;
 For I := 0 To NCh - 1 Do
  If ChTyp[I] = 0 Then Begin
   J := Ncol;
   While (J > 0) And (ChAsoc[Lst[J - 1]] > ChAsoc[I]) Do Begin
    Lst[J] := Lst[J - 1];
    Dec(J);
   End;
   Lst[J] := I;
   Inc(Ncol);
  End;
 If Ncol = 0 Then Exit;
 { espace couleur attendu }
 Expect := 0;
 Case JxEnumCS Of
  16, 18: Expect := 3;
  17: Expect := 1;
  12: Expect := 4;
 End;
 If Expect > Ncol Then Expect := 0;
 If Expect = 0 Then Begin
  If Ncol >= 4 Then Expect := 4
  Else If Ncol = 3 Then Expect := 3
  Else Expect := 1;
 End;
 Nmap := Expect;
 For K := 0 To Nmap - 1 Do Sel[K] := Lst[K];
 If Nmap < 1 Then Exit;
 OutComps := Nmap;
 If JxEnumCS = 16 Then ColSpace := 3
 Else If JxEnumCS = 18 Then ColSpace := 3
 Else If JxEnumCS = 17 Then ColSpace := 1
 Else If JxEnumCS = 12 Then ColSpace := 4
 Else If OutComps = 1 Then ColSpace := 1
 Else If OutComps = 3 Then ColSpace := 3
 Else ColSpace := 0;
 If ((JxEnumCS = 16) Or (JxEnumCS = 18)) And (OutComps <> 3) Then ColSpace := 0;
 If (JxEnumCS = 17) And (OutComps <> 1) Then ColSpace := 0;
 If (JxEnumCS = 12) And (OutComps <> 4) Then ColSpace := 0;
 { la composante 0 sert de référence de taille }
 OutW := JxPlaneW[0];
 OutH := JxPlaneH[0];
 Tot := Int64(OutW) * OutH * OutComps;
 If (OutW < 1) Or (OutH < 1) Or (Tot > 2000000000) Then Exit;
 Pix := Nil;
 GetMem(Pix, Tot);
 If Pix = Nil Then Exit;
 For K := 0 To 3 Do XMap[K] := Nil;
 Ok := True;
 For K := 0 To OutComps - 1 Do Begin
  GetMem(XMap[K], Int64(OutW) * 4);
  If XMap[K] = Nil Then Ok := False
  Else Begin
   I := ChComp[Sel[K]];
   For X := 0 To OutW - 1 Do Begin
    J := (Int64(2 * X + 1) * JxPlaneW[I]) Div (2 * Int64(OutW));
    If J >= JxPlaneW[I] Then J := JxPlaneW[I] - 1;
    XMap[K]^[X] := J;
   End;
  End;
 End;
 If Not Ok Then Begin
  For K := 0 To 3 Do If XMap[K] <> Nil Then FreeMem(XMap[K], Int64(OutW) * 4);
  FreeMem(Pix, Tot);
  Pix := Nil;
  Exit;
 End;
 For Y := 0 To OutH - 1 Do Begin
  Row := PJxBArr(PtrUInt(Pix) + PtrUInt(Int64(Y) * OutW * OutComps));
  For K := 0 To OutComps - 1 Do Begin
   I := ChComp[Sel[K]];
   Sy := (Int64(2 * Y + 1) * JxPlaneH[I]) Div (2 * Int64(OutH));
   If Sy >= JxPlaneH[I] Then Sy := JxPlaneH[I] - 1;
   Idx := Sy * JxPlaneW[I];
   If ChMode[Sel[K]] = 1 Then Begin
    Dp := JxPalDepth[ChCol[Sel[K]]];
    For X := 0 To OutW - 1 Do Begin
     V := JxPlaneVal(I, Idx + XMap[K]^[X]);
     If V >= JxPalN Then V := JxPalN - 1;
     Row^[X * OutComps + K] := JxScale8(JxPal^[V * JxPalNC + ChCol[Sel[K]]], Dp);
    End;
   End Else If JxPlaneWord[I] Then Begin
    For X := 0 To OutW - 1 Do
     Row^[X * OutComps + K] := JxScale8(JxPlaneVal(I, Idx + XMap[K]^[X]), JxPrecC[I]);
   End Else Begin
    For X := 0 To OutW - 1 Do
     Row^[X * OutComps + K] := JxPlane[I]^[Idx + XMap[K]^[X]];
   End;
  End;
  { sYCC -> RGB }
  If (JxEnumCS = 18) And (OutComps = 3) Then
   For X := 0 To OutW - 1 Do Begin
    Yy := Row^[X * 3];
    Cb := Row^[X * 3 + 1] - 128;
    Cr := Row^[X * 3 + 2] - 128;
    R := Yy + SarLongint(91881 * Cr + 32768, 16);
    G := Yy - SarLongint(22554 * Cb + 46802 * Cr + 32768, 16);
    B := Yy + SarLongint(116130 * Cb + 32768, 16);
    Row^[X * 3] := JxClamp8(R);
    Row^[X * 3 + 1] := JxClamp8(G);
    Row^[X * 3 + 2] := JxClamp8(B);
   End;
 End;
 For K := 0 To 3 Do If XMap[K] <> Nil Then FreeMem(XMap[K], Int64(OutW) * 4);
 JxAssemble := True;
End;

{ ---------------------------------------------------------------------- }
{ Point d'entrée                                                           }
{ ---------------------------------------------------------------------- }

Procedure JxCleanup;
Var
 I: LongInt;
Begin
 JxFreeTile;
 For I := 0 To JxMaxC - 1 Do
  If JxPlane[I] <> Nil Then Begin
   If JxPlaneWord[I] Then FreeMem(JxPlane[I], Int64(JxPlaneW[I]) * JxPlaneH[I] * 2)
   Else FreeMem(JxPlane[I], Int64(JxPlaneW[I]) * JxPlaneH[I]);
   JxPlane[I] := Nil;
  End;
 If JxTPs <> Nil Then Begin FreeMem(JxTPs, JxTPCap * SizeOf(TJxTP)); JxTPs := Nil; End;
 If JxTileFirst <> Nil Then Begin FreeMem(JxTileFirst, JxNT * 4); JxTileFirst := Nil; End;
 If JxTileLast <> Nil Then Begin FreeMem(JxTileLast, JxNT * 4); JxTileLast := Nil; End;
 If JxPend <> Nil Then Begin FreeMem(JxPend, JxPendCap * SizeOf(TJxPend)); JxPend := Nil; End;
 If JxPal <> Nil Then Begin FreeMem(JxPal, JxPalN * JxPalNC * 4); JxPal := Nil; End;
 JxTPCap := 0; JxNTP := 0; JxPendCap := 0;
End;

Function JxDecodeMain(Src: PBigBytes; SLen, MaxDim: LongInt;
  Var OutW, OutH, OutComps, OrigW, OrigH, ColSpace: LongInt; Var Pix: PBigBytes): Boolean;
Var
 Cs0, CsLen, Pos, T, C, MinNL, R, I, NOk: LongInt;
 Zero, Used: Boolean;
 Px0, Px1, Py0, Py1: Int64;
 Sz: Int64;
 Wd, Ht: LongInt;
Begin
 JxDecodeMain := False;
 JxS := Src;
 JxSLen := SLen;
 If (Src = Nil) Or (SLen < 12) Then Exit;
 If Not JxFindCodestream(Cs0, CsLen) Then Exit;
 JxS := PBigBytes(PtrUInt(Src) + PtrUInt(Cs0));
 JxSLen := CsLen;
 If Not JxParseMain(Pos) Then Exit;
 { tables de parties de tuiles }
 GetMem(JxTileFirst, JxNT * 4);
 GetMem(JxTileLast, JxNT * 4);
 If (JxTileFirst = Nil) Or (JxTileLast = Nil) Then Exit;
 For T := 0 To JxNT - 1 Do Begin
  JxTileFirst^[T] := -1;
  JxTileLast^[T] := -1;
 End;
 If Not JxScanTiles(Pos) Then Exit;
 If JxNTP = 0 Then Exit;
 { niveau de décomposition minimal commun à toutes les tuiles }
 MinNL := 99;
 NOk := 0;
 For T := 0 To JxNT - 1 Do
  If JxTileFirst^[T] >= 0 Then
   If JxLoadTile(T) Then Begin
    Inc(NOk);
    For C := 0 To JxNC - 1 Do
     If JxTileP.Cod[C].NL < MinNL Then MinNL := JxTileP.Cod[C].NL;
   End;
 If (NOk = 0) Or (MinNL > 32) Then Exit;
 OrigW := JxXsiz - JxXOsiz;
 OrigH := JxYsiz - JxYOsiz;
 R := 0;
 If MaxDim > 0 Then
  While (R < MinNL) And (JxMax(JxCeilShr(OrigW, R), JxCeilShr(OrigH, R)) > MaxDim) Do Inc(R);
 { plans de sortie : taille réduite de chaque composante }
 While True Do Begin
  Zero := False;
  For C := 0 To JxNC - 1 Do Begin
   Px0 := JxCeilShr(JxCeilDiv(JxXOsiz, JxXR[C]), R);
   Px1 := JxCeilShr(JxCeilDiv(JxXsiz, JxXR[C]), R);
   Py0 := JxCeilShr(JxCeilDiv(JxYOsiz, JxYR[C]), R);
   Py1 := JxCeilShr(JxCeilDiv(JxYsiz, JxYR[C]), R);
   If (Px1 <= Px0) Or (Py1 <= Py0) Then Zero := True;
  End;
  If Not Zero Then Break;
  If R = 0 Then Exit;
  Dec(R);
 End;
 JxRed := R;
 { composantes passant par la palette : plans 16 bits }
 If JxHavePal And (JxNCmap > 0) Then
  For I := 0 To JxNCmap - 1 Do
   If (JxCmapT[I] = 1) And (JxCmapC[I] < JxNC) Then JxPlaneWord[JxCmapC[I]] := True;
 If JxHavePal And (JxNCmap = 0) Then JxPlaneWord[0] := True;
 For C := 0 To JxNC - 1 Do Begin
  Px0 := JxCeilShr(JxCeilDiv(JxXOsiz, JxXR[C]), R);
  Px1 := JxCeilShr(JxCeilDiv(JxXsiz, JxXR[C]), R);
  Py0 := JxCeilShr(JxCeilDiv(JxYOsiz, JxYR[C]), R);
  Py1 := JxCeilShr(JxCeilDiv(JxYsiz, JxYR[C]), R);
  JxPlaneX0[C] := Px0;
  JxPlaneY0[C] := Py0;
  JxPlaneW[C] := Px1 - Px0;
  JxPlaneH[C] := Py1 - Py0;
  Sz := Int64(JxPlaneW[C]) * JxPlaneH[C];
  If JxPlaneWord[C] Then Sz := Sz * 2;
  If Sz > 1900000000 Then Exit;
  GetMem(JxPlane[C], Sz);
  If JxPlane[C] = Nil Then Exit;
  FillChar(JxPlane[C]^, Sz, 0);
 End;
 { décodage des tuiles }
 For T := 0 To JxNT - 1 Do
  If JxTileFirst^[T] >= 0 Then
   If Not JxDecodeTile(T) Then Exit;
 JxDecodeMain := JxAssemble(OutW, OutH, OutComps, ColSpace, Pix);
End;

{ Décode un flux JPEG 2000 (codestream brut ou conteneur JP2).
  MaxDim : dimension maximale souhaitée (niveau de réduction automatique).
  Pix : tampon GetMem de OutW*OutH*OutComps octets, entrelacé 8 bits. }
Function JPXDecode(Src: PBigBytes; SLen: LongInt; MaxDim: LongInt;
  Var OutW, OutH, OutComps, OrigW, OrigH, ColSpace: LongInt; Var Pix: PBigBytes): Boolean;
Var
 Ok: Boolean;
 I: LongInt;
Begin
 Pix := Nil;
 OutW := 0; OutH := 0; OutComps := 0; OrigW := 0; OrigH := 0; ColSpace := 0;
 JxInitTables;
 { remise à zéro de l'état global }
 JxAr := Nil; JxTPs := Nil; JxTileFirst := Nil; JxTileLast := Nil; JxPend := Nil;
 JxTPCap := 0; JxNTP := 0; JxPendCap := 0; JxDone := Nil; JxPal := Nil;
 JxHaveSiz := False; JxHavePal := False; JxEnumCS := -1;
 JxPalN := 0; JxPalNC := 0; JxNCmap := 0; JxNCdef := 0; JxNT := 0; JxNC := 0;
 JxMemErr := False; JxRed := 0;
 For I := 0 To JxMaxC - 1 Do Begin
  JxPlane[I] := Nil;
  JxPlaneWord[I] := False;
  JxPlaneW[I] := 0; JxPlaneH[I] := 0;
  JxTC[I].Res := Nil;
  JxTC[I].Buf := Nil;
  JxTC[I].W := 0; JxTC[I].H := 0; JxTC[I].NL := 0;
 End;
 Ok := JxDecodeMain(Src, SLen, MaxDim, OutW, OutH, OutComps, OrigW, OrigH, ColSpace, Pix);
 JxCleanup;
 JxEnumCS := -1;
 If Not Ok Then Begin
  If Pix <> Nil Then FreeMem(Pix, Int64(OutW) * OutH * OutComps);
  Pix := Nil;
  OutW := 0; OutH := 0; OutComps := 0; OrigW := 0; OrigH := 0; ColSpace := 0;
 End;
 JPXDecode := Ok;
End;
{ ---------------------------------------------------------------------- }
{ Décodeur JBIG2 (ITU-T T.88 / ISO 14492) pour le filtre PDF JBIG2Decode   }
{ Flux « intégré PDF » : segments séquentiels sans en-tête de fichier.    }
{ Dépend de CCITTDecode (MMR) et des types PBigBytes, PByte, PLongInt.    }
{ Tous les identifiants globaux sont préfixés par Jb / JBIG2.             }
{ Convention interne : 1 = noir (JBIG2) ; la sortie est inversée (PDF).   }
{ ---------------------------------------------------------------------- }

Const
 JbMaxPix = 200000000;          { pixels max d'un bitmap (page comprise) }
 JbMaxLive = 700000000;         { octets vivants max alloués par le décodeur }
 JbMaxSyms = 500000;            { symboles max par dictionnaire / région }
 JbMaxSymPix = 16777216;         { pixels max d'un symbole ou d'un symbole raffiné }
 JbMaxDictPix = 100000000;      { pixels max cumulés des symboles d'un dictionnaire }
 JbMaxInst = 20000000;          { instances de symboles max par région de texte }
 JbMaxSegRes = 30000;           { segments à résultat mémorisés max }
 JbMaxWork = 8000000000;        { budget de travail (~ ns) : anti-DoS sur flux corrompus }
 JbSltp: Array[0..3] Of Integer = ($9B25, $0795, $00E5, $0195);
 JbQeV: Array[0..46] Of Word = (
  $5601, $3401, $1801, $0AC1, $0521, $0221, $5601, $5401, $4801, $3801, $3001, $2401,
  $1C01, $1601, $5601, $5401, $5101, $4801, $3801, $3401, $3001, $2801, $2401, $2201,
  $1C01, $1801, $1601, $1401, $1201, $1101, $0AC1, $09C1, $08A1, $0521, $0441, $02A1,
  $0221, $0141, $0111, $0085, $0049, $0025, $0015, $0009, $0005, $0001, $5601);
 JbNMpsV: Array[0..46] Of Byte = (
  1, 2, 3, 4, 5, 38, 7, 8, 9, 10, 11, 12, 13, 29, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
  25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 45, 46);
 JbNLpsV: Array[0..46] Of Byte = (
  1, 6, 9, 12, 29, 33, 6, 14, 14, 14, 17, 18, 20, 21, 14, 14, 15, 16, 17, 18, 19, 19, 20, 21,
  22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 46);
 JbSwV: Array[0..46] Of Byte = (
  1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
 { tables de Huffman standard B.1 à B.15 : (PREFLEN, RANGELEN, RANGELOW, genre)
   genre : 0 normal, 1 borne inférieure, 2 borne supérieure, 3 OOB }
 JbStdN: Array[1..15] Of Integer = (5, 8, 9, 7, 8, 14, 15, 21, 22, 21, 14, 15, 14, 7, 13);
 JbStd1: Array[0..19] Of LongInt = (
  1, 4, 0, 0, 2, 8, 16, 0, 3, 16, 272, 0,
  0, 32, -1, 1, 3, 32, 65808, 2);
 JbStd2: Array[0..31] Of LongInt = (
  1, 0, 0, 0, 2, 0, 1, 0, 3, 0, 2, 0,
  4, 3, 3, 0, 5, 6, 11, 0, 0, 32, -1, 1,
  6, 32, 75, 2, 6, 0, 0, 3);
 JbStd3: Array[0..35] Of LongInt = (
  8, 8, -256, 0, 1, 0, 0, 0, 2, 0, 1, 0,
  3, 0, 2, 0, 4, 3, 3, 0, 5, 6, 11, 0,
  8, 32, -257, 1, 7, 32, 75, 2, 6, 0, 0, 3);
 JbStd4: Array[0..27] Of LongInt = (
  1, 0, 1, 0, 2, 0, 2, 0, 3, 0, 3, 0,
  4, 3, 4, 0, 5, 6, 12, 0, 0, 32, -1, 1,
  5, 32, 76, 2);
 JbStd5: Array[0..31] Of LongInt = (
  7, 8, -255, 0, 1, 0, 1, 0, 2, 0, 2, 0,
  3, 0, 3, 0, 4, 3, 4, 0, 5, 6, 12, 0,
  7, 32, -256, 1, 6, 32, 76, 2);
 JbStd6: Array[0..55] Of LongInt = (
  5, 10, -2048, 0, 4, 9, -1024, 0, 4, 8, -512, 0,
  4, 7, -256, 0, 5, 6, -128, 0, 5, 5, -64, 0,
  4, 5, -32, 0, 2, 7, 0, 0, 3, 7, 128, 0,
  3, 8, 256, 0, 4, 9, 512, 0, 4, 10, 1024, 0,
  6, 32, -2049, 1, 6, 32, 2048, 2);
 JbStd7: Array[0..59] Of LongInt = (
  4, 9, -1024, 0, 3, 8, -512, 0, 4, 7, -256, 0,
  5, 6, -128, 0, 5, 5, -64, 0, 4, 5, -32, 0,
  4, 5, 0, 0, 5, 5, 32, 0, 5, 6, 64, 0,
  4, 7, 128, 0, 3, 8, 256, 0, 3, 9, 512, 0,
  3, 10, 1024, 0, 5, 32, -1025, 1, 5, 32, 2048, 2);
 JbStd8: Array[0..83] Of LongInt = (
  8, 3, -15, 0, 9, 1, -7, 0, 8, 1, -5, 0,
  9, 0, -3, 0, 7, 0, -2, 0, 4, 0, -1, 0,
  2, 1, 0, 0, 5, 0, 2, 0, 6, 0, 3, 0,
  3, 4, 4, 0, 6, 1, 20, 0, 4, 4, 22, 0,
  4, 5, 38, 0, 5, 6, 70, 0, 5, 7, 134, 0,
  6, 7, 262, 0, 7, 8, 390, 0, 6, 10, 646, 0,
  9, 32, -16, 1, 9, 32, 1670, 2, 2, 0, 0, 3);
 JbStd9: Array[0..87] Of LongInt = (
  8, 4, -31, 0, 9, 2, -15, 0, 8, 2, -11, 0,
  9, 1, -7, 0, 7, 1, -5, 0, 4, 1, -3, 0,
  3, 1, -1, 0, 3, 1, 1, 0, 5, 1, 3, 0,
  6, 1, 5, 0, 3, 5, 7, 0, 6, 2, 39, 0,
  4, 5, 43, 0, 4, 6, 75, 0, 5, 7, 139, 0,
  5, 8, 267, 0, 6, 8, 523, 0, 7, 9, 779, 0,
  6, 11, 1291, 0, 9, 32, -32, 1, 9, 32, 3339, 2,
  2, 0, 0, 3);
 JbStd10: Array[0..83] Of LongInt = (
  7, 4, -21, 0, 8, 0, -5, 0, 7, 0, -4, 0,
  5, 0, -3, 0, 2, 2, -2, 0, 5, 0, 2, 0,
  6, 0, 3, 0, 7, 0, 4, 0, 8, 0, 5, 0,
  2, 6, 6, 0, 5, 5, 70, 0, 6, 5, 102, 0,
  6, 6, 134, 0, 6, 7, 198, 0, 6, 8, 326, 0,
  6, 9, 582, 0, 6, 10, 1094, 0, 7, 11, 2118, 0,
  8, 32, -22, 1, 8, 32, 4166, 2, 2, 0, 0, 3);
 JbStd11: Array[0..55] Of LongInt = (
  1, 0, 1, 0, 2, 1, 2, 0, 4, 0, 4, 0,
  4, 1, 5, 0, 5, 1, 7, 0, 5, 2, 9, 0,
  6, 2, 13, 0, 7, 2, 17, 0, 7, 3, 21, 0,
  7, 4, 29, 0, 7, 5, 45, 0, 7, 6, 77, 0,
  0, 32, -1, 1, 7, 32, 141, 2);
 JbStd12: Array[0..59] Of LongInt = (
  1, 0, 1, 0, 2, 0, 2, 0, 3, 1, 3, 0,
  5, 0, 5, 0, 5, 1, 6, 0, 6, 1, 8, 0,
  7, 0, 10, 0, 7, 1, 11, 0, 7, 2, 13, 0,
  7, 3, 17, 0, 7, 4, 25, 0, 8, 5, 41, 0,
  8, 32, 73, 0, 0, 32, -1, 1, 0, 32, 0, 2);
 JbStd13: Array[0..55] Of LongInt = (
  1, 0, 1, 0, 3, 0, 2, 0, 4, 0, 3, 0,
  5, 0, 4, 0, 4, 1, 5, 0, 3, 3, 7, 0,
  6, 1, 15, 0, 6, 2, 17, 0, 6, 3, 21, 0,
  6, 4, 29, 0, 6, 5, 45, 0, 7, 6, 77, 0,
  0, 32, -1, 1, 7, 32, 141, 2);
 JbStd14: Array[0..27] Of LongInt = (
  3, 0, -2, 0, 3, 0, -1, 0, 1, 0, 0, 0,
  3, 0, 1, 0, 3, 0, 2, 0, 0, 32, -1, 1,
  0, 32, 3, 2);
 JbStd15: Array[0..51] Of LongInt = (
  7, 4, -24, 0, 6, 2, -8, 0, 5, 1, -4, 0,
  4, 0, -2, 0, 3, 0, -1, 0, 1, 0, 0, 0,
  3, 0, 1, 0, 4, 0, 2, 0, 5, 1, 3, 0,
  6, 2, 5, 0, 7, 4, 9, 0, 7, 32, -25, 1,
  7, 32, 25, 2);

Type
 PJbBmp = ^TJbBmp;
 TJbBmp = Record
  W, H, RB: LongInt;
  D: PBigBytes;
 End;
 TJbBmpArr = Array[0..16777215] Of PJbBmp;
 PJbBmpArr = ^TJbBmpArr;
 TJbIntArr = Array[0..16777215] Of LongInt;
 PJbIntArr = ^TJbIntArr;
 PJbHdr = ^TJbHdr;
 TJbHdr = Record
  Prev, Next: PJbHdr;
  Sz: Int64;
 End;
 TJbHLine = Record
  PL, RL, Kind: Byte;
  Low: LongInt;
 End;
 TJbHLineArr = Array[0..16777215] Of TJbHLine;
 PJbHLineArr = ^TJbHLineArr;
 PJbHT = ^TJbHT;
 TJbHT = Record
  N, MaxLen: LongInt;
  L: PJbHLineArr;
  Ord: PJbIntArr;
  First: Array[0..33] Of Int64;
  Cnt, Ofs: Array[0..33] Of LongInt;
 End;
 { contextes des décodeurs d'entiers arithmétiques d'une région de texte }
 PJbTCtx = ^TJbTCtx;
 TJbTCtx = Record
  IADT, IAFS, IADS, IAIT, IARI, IARDW, IARDH, IARDX, IARDY: Array[0..511] Of Byte;
  IAID: PBigBytes;
  IDLen: LongInt;
  GR: Array[0..8191] Of Byte;
 End;
 { résultat mémorisé d'un segment }
 TJbSeg = Record
  Num, Typ: LongInt;
  Syms: PJbBmpArr;              { symboles exportés ou motifs }
  NSyms: LongInt;
  GB, GR: PBigBytes;            { contextes conservés (dictionnaire de symboles) }
  Tab: PJbHT;                   { table de Huffman personnalisée }
  Bmp: PJbBmp;                  { région intermédiaire }
  PW, PH: LongInt;
 End;
 PJbSegArr = ^TJbSegArr;
 TJbSegArr = Array[0..1000000] Of TJbSeg;
 { paramètres d'une région générique }
 TJbGP = Record
  Templ: LongInt;
  TPGD: Boolean;
  Skip: PJbBmp;
  AT: Array[0..7] Of LongInt;
 End;
 { paramètres d'une région de texte }
 TJbTP = Record
  Huff, Refine, Transposed, FixedCodes: Boolean;
  W, H, NInst, Strips, LogStrips, NSyms, CodeLen, DefPix, CombOp, RefCorner, DSOff, RTempl: LongInt;
  Syms: PJbBmpArr;
  RAT: Array[0..3] Of LongInt;
  TFS, TDS, TDT, TRDW, TRDH, TRDX, TRDY, TRSIZE, TSym: PJbHT;
 End;

Var
 JbHdrList: PJbHdr;
 JbLive, JbWork: Int64;
 JbQe: Array[0..93] Of Word;
 JbNM, JbNL: Array[0..93] Of Byte;
 JbTabOK: Boolean;
 { décodeur arithmétique MQ }
 JbMA, JbMC: LongWord;
 JbMCT, JbMPos, JbMEnd, JbMOver: LongInt;
 JbMBuf: PBigBytes;
 { lecteur de bits Huffman }
 JbHBuf: PBigBytes;
 JbHLen, JbHPos: LongInt;
 JbHErr: Boolean;
 { tables de Huffman standard construites }
 JbStdT: Array[1..15] Of PJbHT;
 { état du décodage }
 JbSegs: PJbSegArr;
 JbNSegs, JbCapSegs: LongInt;
 JbPage: PJbBmp;
 JbPageDef: LongInt;
 JbPageUnk, JbPageHas, JbDone: Boolean;
 JbPageFinalH: LongInt;
 JbArgW, JbArgH: LongInt;

{ ---- mémoire : toutes les allocations sont chaînées et libérées en bloc ---- }

Function JbAlloc(Sz: Int64): Pointer;
Var
 H: PJbHdr;
Begin
 JbAlloc := Nil;
 If (Sz < 0) Or (Sz > 1500000000) Or (JbLive + Sz > JbMaxLive) Then Exit;
 H := GetMem(Sz + SizeOf(TJbHdr));
 If H = Nil Then Exit;
 FillChar(H^, Sz + SizeOf(TJbHdr), 0);
 H^.Sz := Sz;
 H^.Prev := Nil;
 H^.Next := JbHdrList;
 If JbHdrList <> Nil Then JbHdrList^.Prev := H;
 JbHdrList := H;
 JbLive := JbLive + Sz;
 JbAlloc := PByte(H) + SizeOf(TJbHdr);
End;

Procedure JbFree(P: Pointer);
Var
 H: PJbHdr;
Begin
 If P = Nil Then Exit;
 H := PJbHdr(PByte(P) - SizeOf(TJbHdr));
 If H^.Prev <> Nil Then H^.Prev^.Next := H^.Next Else JbHdrList := H^.Next;
 If H^.Next <> Nil Then H^.Next^.Prev := H^.Prev;
 JbLive := JbLive - H^.Sz;
 FreeMem(H);
End;

Procedure JbFreeAll;
Begin
 While JbHdrList <> Nil Do JbFree(PByte(JbHdrList) + SizeOf(TJbHdr));
 JbLive := 0;
End;

Function JbNewBmp(W, H: LongInt): PJbBmp;
Var
 B: PJbBmp;
Begin
 JbNewBmp := Nil;
 If (W < 0) Or (H < 0) Or (W > JbMaxPix) Or (H > JbMaxPix) Then Exit;
 If Int64(W) * H > JbMaxPix Then Exit;
 B := JbAlloc(SizeOf(TJbBmp));
 If B = Nil Then Exit;
 B^.W := W; B^.H := H; B^.RB := (W + 7) Shr 3;
 B^.D := JbAlloc(Int64(B^.RB) * H + 8);
 If B^.D = Nil Then Begin JbFree(B); Exit; End;
 JbNewBmp := B;
End;

Procedure JbFreeBmp(B: PJbBmp);
Begin
 If B = Nil Then Exit;
 JbFree(B^.D);
 JbFree(B);
End;

Function JbRow(B: PJbBmp; Y: LongInt): PBigBytes;
Begin
 JbRow := PBigBytes(PByte(B^.D) + Int64(Y) * B^.RB);
End;

Function JbGP(B: PJbBmp; X, Y: LongInt): LongInt;
Begin
 If (B = Nil) Or (X < 0) Or (Y < 0) Or (X >= B^.W) Or (Y >= B^.H) Then JbGP := 0
 Else JbGP := (B^.D^[Y * B^.RB + (X Shr 3)] Shr (7 - (X And 7))) And 1;
End;

Procedure JbSP(B: PJbBmp; X, Y, V: LongInt);
Var
 I: LongInt;
Begin
 If (X < 0) Or (Y < 0) Or (X >= B^.W) Or (Y >= B^.H) Then Exit;
 I := Y * B^.RB + (X Shr 3);
 If V <> 0 Then B^.D^[I] := B^.D^[I] Or (128 Shr (X And 7))
 Else B^.D^[I] := B^.D^[I] And (Not (128 Shr (X And 7)));
End;

Procedure JbFillBmp(B: PJbBmp; V: LongInt);
Var
 Y: LongInt;
 R: PBigBytes;
 M: Byte;
Begin
 If (B = Nil) Or (B^.RB = 0) Then Exit;
 If V = 0 Then Begin FillChar(B^.D^, Int64(B^.RB) * B^.H, 0); Exit; End;
 FillChar(B^.D^, Int64(B^.RB) * B^.H, 255);
 If (B^.W And 7) <> 0 Then Begin
  M := Byte(($FF00 Shr (B^.W And 7)) And $FF);
  For Y := 0 To B^.H - 1 Do Begin
   R := JbRow(B, Y);
   R^[B^.RB - 1] := R^[B^.RB - 1] And M;
  End;
 End;
End;

{ Composition de Src sur Dst en (X, Y). Op : 0 OR, 1 AND, 2 XOR, 3 XNOR, 4 REPLACE }
Procedure JbBlit(Dst, Src: PJbBmp; X, Y, Op: LongInt);
Var
 X0, X1, Y0, Y1, SY, DY, DB, B0, B1, P, O, Wd: LongInt;
 SR, DR: PBigBytes;
 M, S, D, MA, MB: LongInt;
Begin
 If (Dst = Nil) Or (Src = Nil) Or (Src^.W = 0) Or (Src^.H = 0) Then Exit;
 If (X > 1073741823) Or (X < -1073741823) Or (Y > 1073741823) Or (Y < -1073741823) Then Exit;
 X0 := X; If X0 < 0 Then X0 := 0;
 X1 := X + Src^.W; If X1 > Dst^.W Then X1 := Dst^.W;
 Y0 := Y; If Y0 < 0 Then Y0 := 0;
 Y1 := Y + Src^.H; If Y1 > Dst^.H Then Y1 := Dst^.H;
 If (X0 >= X1) Or (Y0 >= Y1) Then Exit;
 JbWork := JbWork + Int64(X1 - X0) * (Y1 - Y0) Div 4 + 60;
 If JbWork > JbMaxWork Then Exit;
 B0 := X0 Shr 3;
 B1 := (X1 - 1) Shr 3;
 For DY := Y0 To Y1 - 1 Do Begin
  SY := DY - Y;
  SR := JbRow(Src, SY);
  DR := JbRow(Dst, DY);
  For DB := B0 To B1 Do Begin
   { 8 pixels source alignés sur l'octet destination DB }
   P := DB * 8 - X;
   O := P And 7;
   Wd := (P - O) Div 8;
   S := 0;
   If (Wd >= 0) And (Wd < Src^.RB) Then S := SR^[Wd] Shl 8;
   If (Wd + 1 >= 0) And (Wd + 1 < Src^.RB) Then S := S Or SR^[Wd + 1];
   S := (S Shr (8 - O)) And $FF;
   { masque des pixels destination valides dans cet octet }
   MA := 255;
   If DB = B0 Then MA := 255 Shr (X0 And 7);
   MB := 255;
   If DB = B1 Then MB := (255 Shl (7 - ((X1 - 1) And 7))) And 255;
   M := MA And MB;
   D := DR^[DB];
   Case Op Of
    0: D := D Or (S And M);
    1: D := D And (S Or (255 Xor M));
    2: D := D Xor (S And M);
    3: D := (D And (255 Xor M)) Or ((255 Xor (D Xor S)) And M);
   Else D := (D And (255 Xor M)) Or (S And M);
   End;
   DR^[DB] := D;
  End;
 End;
End;

{ ---- décodeur arithmétique MQ (Annexe E) ---- }

Procedure JbInitTab;
Var
 I: Integer;
Begin
 If JbTabOK Then Exit;
 For I := 0 To 46 Do Begin
  JbQe[I * 2] := JbQeV[I]; JbQe[I * 2 + 1] := JbQeV[I];
  JbNM[I * 2] := JbNMpsV[I] * 2;
  JbNM[I * 2 + 1] := JbNMpsV[I] * 2 + 1;
  JbNL[I * 2] := JbNLpsV[I] * 2 + JbSwV[I];
  JbNL[I * 2 + 1] := JbNLpsV[I] * 2 + (1 - JbSwV[I]);
 End;
 JbTabOK := True;
End;

Function JbBy(P: LongInt): LongWord;
Begin
 If (P >= 0) And (P < JbMEnd) Then JbBy := JbMBuf^[P] Else JbBy := $FF;
End;

Procedure JbMQByteIn;
Var
 B, B1: LongWord;
Begin
 B := JbBy(JbMPos);
 If B = $FF Then Begin
  B1 := JbBy(JbMPos + 1);
  If B1 > $8F Then Begin
   JbMC := JbMC + $FF00;
   JbMCT := 8;
   Inc(JbMOver);
  End Else Begin
   Inc(JbMPos);
   JbMC := JbMC + (B1 Shl 9);
   JbMCT := 7;
  End;
 End Else Begin
  Inc(JbMPos);
  If JbMPos >= JbMEnd Then Inc(JbMOver);
  JbMC := JbMC + (JbBy(JbMPos) Shl 8);
  JbMCT := 8;
 End;
End;

Procedure JbMQInit(P: PBigBytes; Len: LongInt);
Begin
 JbInitTab;
 If Len < 0 Then Len := 0;
 JbMBuf := P; JbMEnd := Len; JbMPos := 0; JbMOver := 0;
 JbMC := JbBy(0) Shl 16;
 JbMQByteIn;
 JbMC := JbMC Shl 7;
 JbMCT := JbMCT - 7;
 JbMA := $8000;
End;

{ Décode un bit avec le contexte Cx (octet : 2 * état + MPS) }
Function JbMQ(Var Cx: Byte): LongInt;
Var
 Q: LongWord;
 I: Byte;
 D: LongInt;
Begin
 I := Cx;
 Q := JbQe[I];
 JbMA := JbMA - Q;
 If (JbMC Shr 16) < Q Then Begin
  If JbMA < Q Then Begin D := I And 1; Cx := JbNM[I]; End
  Else Begin D := 1 - (I And 1); Cx := JbNL[I]; End;
  JbMA := Q;
 End Else Begin
  JbMC := JbMC - (Q Shl 16);
  If (JbMA And $8000) <> 0 Then Begin JbMQ := I And 1; Exit; End;
  If JbMA < Q Then Begin D := 1 - (I And 1); Cx := JbNL[I]; End
  Else Begin D := I And 1; Cx := JbNM[I]; End;
 End;
 Repeat
  If JbMCT = 0 Then JbMQByteIn;
  JbMA := JbMA Shl 1;
  JbMC := JbMC Shl 1;
  Dec(JbMCT);
 Until (JbMA And $8000) <> 0;
 JbMQ := D;
End;

{ Décodeur d'entiers arithmétique (Annexe A.2). Retourne False pour OOB. }
Function JbIntDec(Cx: PBigBytes; Var V: LongInt): Boolean;
Var
 Prev, S, N, I, B, Off: LongInt;
 R: Int64;
 Function Bit: LongInt;
 Var
  D: LongInt;
 Begin
  D := JbMQ(Cx^[Prev]);
  If Prev < 256 Then Prev := (Prev Shl 1) Or D
  Else Prev := (((Prev Shl 1) Or D) And 511) Or 256;
  Bit := D;
 End;
Begin
 Prev := 1;
 S := Bit;
 If Bit = 0 Then Begin N := 2; Off := 0; End
 Else If Bit = 0 Then Begin N := 4; Off := 4; End
 Else If Bit = 0 Then Begin N := 6; Off := 20; End
 Else If Bit = 0 Then Begin N := 8; Off := 84; End
 Else If Bit = 0 Then Begin N := 12; Off := 340; End
 Else Begin N := 32; Off := 4436; End;
 R := 0;
 For I := 1 To N Do Begin
  B := Bit;
  R := R * 2 + B;
 End;
 R := R + Off;
 If R > 1073741823 Then R := 1073741823;
 If S = 0 Then Begin V := R; JbIntDec := True; End
 Else If R > 0 Then Begin V := -R; JbIntDec := True; End
 Else Begin V := 0; JbIntDec := False; End;
End;

{ Décodeur IAID : CodeLen bits, contextes Cx de taille 2^(CodeLen+1) }
Function JbIAID(Cx: PBigBytes; CodeLen: LongInt): LongInt;
Var
 Prev, I: LongInt;
Begin
 Prev := 1;
 For I := 1 To CodeLen Do Prev := (Prev Shl 1) Or JbMQ(Cx^[Prev]);
 JbIAID := Prev - (1 Shl CodeLen);
End;

{ ---- lecteur de bits (Huffman) ---- }

Procedure JbHInit(P: PBigBytes; Len: LongInt);
Begin
 If Len > 250000000 Then Len := 250000000;
 If Len < 0 Then Len := 0;
 JbHBuf := P; JbHLen := Len; JbHPos := 0; JbHErr := False;
End;

Function JbHBit: LongInt;
Begin
 If (JbHPos Shr 3) >= JbHLen Then Begin JbHErr := True; JbHBit := 0; Exit; End;
 JbHBit := (JbHBuf^[JbHPos Shr 3] Shr (7 - (JbHPos And 7))) And 1;
 Inc(JbHPos);
End;

Function JbHBits(N: LongInt): Int64;
Var
 I: LongInt;
 R: Int64;
Begin
 R := 0;
 For I := 1 To N Do R := R * 2 + JbHBit;
 JbHBits := R;
End;

Procedure JbHAlign;
Begin
 JbHPos := (JbHPos + 7) And (Not 7);
End;

{ ---- tables de Huffman (Annexe B) ---- }

{ Calcule les codes canoniques (B.3). Retourne False si invalide. }
Function JbHBuild(T: PJbHT): Boolean;
Var
 I, Len, K: LongInt;
 Fc: Int64;
 Nx: Array[0..33] Of LongInt;
Begin
 JbHBuild := False;
 FillChar(T^.Cnt, SizeOf(T^.Cnt), 0);
 FillChar(T^.Ofs, SizeOf(T^.Ofs), 0);
 FillChar(T^.First, SizeOf(T^.First), 0);
 T^.MaxLen := 0;
 For I := 0 To T^.N - 1 Do Begin
  Len := T^.L^[I].PL;
  If Len > 32 Then Exit;
  If Len > 0 Then Begin
   Inc(T^.Cnt[Len]);
   If Len > T^.MaxLen Then T^.MaxLen := Len;
  End;
 End;
 T^.Ord := JbAlloc(Int64(T^.N + 1) * SizeOf(LongInt));
 If T^.Ord = Nil Then Exit;
 K := 0;
 Fc := 0;
 For Len := 1 To 32 Do Begin
  T^.Ofs[Len] := K;
  Nx[Len] := K;
  K := K + T^.Cnt[Len];
  Fc := (Fc + T^.Cnt[Len - 1]) * 2;
  If Len = 1 Then Fc := 0;
  T^.First[Len] := Fc;
 End;
 For I := 0 To T^.N - 1 Do Begin
  Len := T^.L^[I].PL;
  If Len > 0 Then Begin
   T^.Ord^[Nx[Len]] := I;
   Inc(Nx[Len]);
  End;
 End;
 JbHBuild := True;
End;

{ Table standard B.N (1..15) ; Nil si échec }
Function JbHStd(N: LongInt): PJbHT;
Var
 T: PJbHT;
 I, Cnt: LongInt;
 Src: ^LongInt;
Begin
 JbHStd := Nil;
 If (N < 1) Or (N > 15) Then Exit;
 If JbStdT[N] <> Nil Then Begin JbHStd := JbStdT[N]; Exit; End;
 Cnt := JbStdN[N];
 Case N Of
  1: Src := @JbStd1[0]; 2: Src := @JbStd2[0]; 3: Src := @JbStd3[0]; 4: Src := @JbStd4[0];
  5: Src := @JbStd5[0]; 6: Src := @JbStd6[0]; 7: Src := @JbStd7[0]; 8: Src := @JbStd8[0];
  9: Src := @JbStd9[0]; 10: Src := @JbStd10[0]; 11: Src := @JbStd11[0]; 12: Src := @JbStd12[0];
  13: Src := @JbStd13[0]; 14: Src := @JbStd14[0];
 Else Src := @JbStd15[0];
 End;
 T := JbAlloc(SizeOf(TJbHT));
 If T = Nil Then Exit;
 T^.N := Cnt;
 T^.L := JbAlloc(Int64(Cnt) * SizeOf(TJbHLine));
 If T^.L = Nil Then Exit;
 For I := 0 To Cnt - 1 Do Begin
  T^.L^[I].PL := PLongInt(PByte(Src) + I * 16)^;
  T^.L^[I].RL := PLongInt(PByte(Src) + I * 16 + 4)^;
  T^.L^[I].Low := PLongInt(PByte(Src) + I * 16 + 8)^;
  T^.L^[I].Kind := PLongInt(PByte(Src) + I * 16 + 12)^;
 End;
 If Not JbHBuild(T) Then Exit;
 JbStdT[N] := T;
 JbHStd := T;
End;

{ Décode une valeur : 0 = ok, 1 = OOB, -1 = erreur }
Function JbHGet(T: PJbHT; Var V: LongInt): LongInt;
Var
 Code, Off, R: Int64;
 Len, K: LongInt;
 Ln: ^TJbHLine;
Begin
 JbHGet := -1;
 V := 0;
 If T = Nil Then Exit;
 Code := 0;
 For Len := 1 To T^.MaxLen Do Begin
  Code := Code * 2 + JbHBit;
  If JbHErr Then Exit;
  K := Code - T^.First[Len];
  If (T^.Cnt[Len] > 0) And (K >= 0) And (K < T^.Cnt[Len]) Then Begin
   Ln := @T^.L^[T^.Ord^[T^.Ofs[Len] + K]];
   If Ln^.Kind = 3 Then Begin JbHGet := 1; Exit; End;
   Off := 0;
   If Ln^.RL > 0 Then Off := JbHBits(Ln^.RL);
   If JbHErr Then Exit;
   If Ln^.Kind = 1 Then R := Int64(Ln^.Low) - Off Else R := Int64(Ln^.Low) + Off;
   If R > 1073741823 Then R := 1073741823;
   If R < -1073741823 Then R := -1073741823;
   V := R;
   JbHGet := 0;
   Exit;
  End;
 End;
End;

{ ---- région générique arithmétique (6.2) : modèles 0 à 3 ---- }

{ Décode la région dans B (déjà allouée et mise à zéro) avec le décodeur MQ courant.
  Cx : 65536 contextes. Une troncature du flux laisse le reste de la région à zéro. }
Function JbGeneric(B: PJbBmp; Var P: TJbGP; Cx: PBigBytes): Boolean;
Const
 N0: Array[0..3] Of Integer = (4, 3, 2, 4);
 N1: Array[0..3] Of Integer = (7, 6, 5, 6);
 N2: Array[0..3] Of Integer = (5, 4, 3, 0);
 R1: Array[0..3] Of Integer = (3, 3, 2, 2);
 R2: Array[0..3] Of Integer = (2, 2, 1, 0);
Var
 T, S1, S2, Keep, Ctx, Cx2, Bit, Acc, XM, Lim, BX, NAT, LTP, Sh1, Sh2: LongInt;
 X, Y, RB, W, H, I: LongInt;
 Row0, Row1, Row2, Zero: PBigBytes;
 Reg1, Reg2: LongWord;
 AtBit: Array[0..3] Of LongInt;
 Nom: Array[0..7] Of LongInt;
 Slow, HasSkip, Has2: Boolean;
Begin
 JbGeneric := False;
 If B = Nil Then Exit;
 T := P.Templ;
 If (T < 0) Or (T > 3) Then Exit;
 W := B^.W; H := B^.H; RB := B^.RB;
 If (W = 0) Or (H = 0) Then Begin JbGeneric := True; Exit; End;
 JbWork := JbWork + Int64(W) * H * 30 + 200;
 If JbWork > JbMaxWork Then Exit;
 S1 := N0[T]; S2 := S1 + N1[T];
 Has2 := N2[T] > 0;
 Keep := (1 Shl (S1 - 1)) Or (1 Shl (S2 - 1));
 If Has2 Then Keep := Keep Or (1 Shl (S2 + N2[T] - 1));
 Keep := (Not Keep) And $FFFF;
 Sh1 := 14 - R1[T]; Sh2 := 14 - R2[T];
 { pixels adaptatifs : position nominale ou non }
 FillChar(Nom, SizeOf(Nom), 0);
 If T = 0 Then Begin
  Nom[0] := 3; Nom[1] := -1; Nom[2] := -3; Nom[3] := -1; Nom[4] := 2; Nom[5] := -2; Nom[6] := -2; Nom[7] := -2;
  NAT := 4;
  AtBit[0] := S1; AtBit[1] := S2 - 1; AtBit[2] := S2; AtBit[3] := S2 + N2[0] - 1;
 End Else Begin
  If T = 1 Then Nom[0] := 3 Else Nom[0] := 2;
  Nom[1] := -1;
  NAT := 1;
  AtBit[0] := S1;
 End;
 Slow := False;
 For I := 0 To NAT * 2 - 1 Do If P.AT[I] <> Nom[I] Then Slow := True;
 HasSkip := P.Skip <> Nil;
 Zero := JbAlloc(RB + 4);
 If Zero = Nil Then Exit;
 LTP := 0;
 For Y := 0 To H - 1 Do Begin
  If JbMOver > 300 Then Break;
  Row0 := JbRow(B, Y);
  If P.TPGD Then Begin
   LTP := LTP Xor JbMQ(Cx^[JbSltp[T]]);
   If LTP <> 0 Then Begin
    If Y > 0 Then Move(JbRow(B, Y - 1)^, Row0^, RB);
    Continue;
   End;
  End;
  If Y >= 1 Then Row1 := JbRow(B, Y - 1) Else Row1 := Zero;
  If Y >= 2 Then Row2 := JbRow(B, Y - 2) Else Row2 := Zero;
  Ctx := (Row1^[0] Shr (7 - R1[T])) Shl S1;
  If Has2 Then Ctx := Ctx Or ((Row2^[0] Shr (7 - R2[T])) Shl S2);
  For BX := 0 To RB - 1 Do Begin
   Reg1 := LongWord(Row1^[BX]) Shl 8;
   If BX + 1 < RB Then Reg1 := Reg1 Or Row1^[BX + 1];
   Reg2 := 0;
   If Has2 Then Begin
    Reg2 := LongWord(Row2^[BX]) Shl 8;
    If BX + 1 < RB Then Reg2 := Reg2 Or Row2^[BX + 1];
   End;
   Lim := W - BX * 8;
   If Lim > 8 Then Lim := 8;
   Acc := 0;
   For XM := 0 To Lim - 1 Do Begin
    X := BX * 8 + XM;
    If HasSkip And (JbGP(P.Skip, X, Y) <> 0) Then Bit := 0
    Else If Slow Then Begin
     Cx2 := Ctx;
     For I := 0 To NAT - 1 Do
      Cx2 := (Cx2 And (Not (1 Shl AtBit[I]))) Or (JbGP(B, X + P.AT[I * 2], Y + P.AT[I * 2 + 1]) Shl AtBit[I]);
     Bit := JbMQ(Cx^[Cx2]);
    End Else Bit := JbMQ(Cx^[Ctx]);
    Acc := Acc Or (Bit Shl (7 - XM));
    If Slow Then Row0^[BX] := Acc;
    Ctx := ((Ctx And Keep) Shl 1) Or Bit Or (LongInt((Reg1 Shr (Sh1 - XM)) And 1) Shl S1);
    If Has2 Then Ctx := Ctx Or (LongInt((Reg2 Shr (Sh2 - XM)) And 1) Shl S2);
   End;
   Row0^[BX] := Acc;
  End;
 End;
 JbFree(Zero);
 JbGeneric := True;
End;

{ ---- MMR (réutilise le décodeur CCITT G4) ---- }

Var
 JbMMRBits: LongInt;

{ Décode Len octets MMR en un bitmap W x H (1 = noir). JbMMRBits = bits consommés. }
Function JbMMRDec(Src: PBigBytes; Len, W, H: LongInt): PJbBmp;
Var
 B: PJbBmp;
Begin
 JbMMRDec := Nil;
 JbMMRBits := 0;
 B := JbNewBmp(W, H);
 If B = Nil Then Exit;
 If (W > 0) And (H > 0) And (Len > 0) And (W <= 65000) Then Begin
  JbWork := JbWork + Int64(W) * H * 8 + 200;
  If JbWork <= JbMaxWork Then Begin
   CCITTDecode(Src, Len, W, H, -1, True, False, B^.D);
   JbMMRBits := CCBit;
   If JbMMRBits > Len * 8 Then JbMMRBits := Len * 8;
  End;
 End;
 JbMMRDec := B;
End;

{ ---- région de raffinement (6.3) ---- }

{ pixel X d'une ligne P de largeur W (0 hors limites ou ligne absente) }
Function JbRowBit(P: PBigBytes; X, W: LongInt): LongInt;
Begin
 If (P = Nil) Or (X < 0) Or (X >= W) Then JbRowBit := 0
 Else JbRowBit := (P^[X Shr 3] Shr (7 - (X And 7))) And 1;
End;

{ Décode B (déjà allouée, à zéro) par raffinement de Ref décalée de (DX, DY).
  Contexte T0 : 13 pixels, T1 : 10 pixels ; fenêtres 3x3 glissantes de la référence. }
Function JbRefine(B, Ref: PJbBmp; DX, DY, Templ: LongInt; TPGR: Boolean;
                  A1X, A1Y, A2X, A2Y: LongInt; Cx: PBigBytes): Boolean;
Var
 X, Y, RX, RY, Ctx, Bit, LTP, W, H, WM, W0, WP, WI, Cur, RW, RH: LongInt;
 RowC, RowU, RM, R0, RP: PBigBytes;
 Slow1, Slow2: Boolean;
Begin
 JbRefine := False;
 If (B = Nil) Or (Ref = Nil) Or (Templ < 0) Or (Templ > 1) Then Exit;
 W := B^.W; H := B^.H; RW := Ref^.W; RH := Ref^.H;
 JbWork := JbWork + Int64(W) * H * 45 + 200;
 If JbWork > JbMaxWork Then Exit;
 If (DX > 1073741823) Or (DX < -1073741823) Or (DY > 1073741823) Or (DY < -1073741823) Then Begin
  JbRefine := True; Exit;
 End;
 If Templ = 0 Then Begin
  If (A1X < -128) Or (A1X > 127) Or (A1Y < -128) Or (A1Y > 127) Or (A2X < -128) Or (A2X > 127) Or
     (A2Y < -128) Or (A2Y > 127) Then Exit;
 End;
 Slow1 := (Templ = 0) And ((A1X <> -1) Or (A1Y <> -1));
 Slow2 := (Templ = 0) And ((A2X <> -1) Or (A2Y <> -1));
 LTP := 0;
 For Y := 0 To H - 1 Do Begin
  If JbMOver > 300 Then Break;
  If TPGR Then Begin
   If Templ = 0 Then LTP := LTP Xor JbMQ(Cx^[$100]) Else LTP := LTP Xor JbMQ(Cx^[$80]);
  End;
  RY := Y - DY;
  RowC := JbRow(B, Y);
  If Y > 0 Then RowU := JbRow(B, Y - 1) Else RowU := Nil;
  If (RY - 1 >= 0) And (RY - 1 < RH) Then RM := JbRow(Ref, RY - 1) Else RM := Nil;
  If (RY >= 0) And (RY < RH) Then R0 := JbRow(Ref, RY) Else R0 := Nil;
  If (RY + 1 >= 0) And (RY + 1 < RH) Then RP := JbRow(Ref, RY + 1) Else RP := Nil;
  RX := -DX;
  { fenêtres initiales (pixels RX-1, RX, RX+1) }
  WM := (JbRowBit(RM, RX - 1, RW) Shl 2) Or (JbRowBit(RM, RX, RW) Shl 1) Or JbRowBit(RM, RX + 1, RW);
  W0 := (JbRowBit(R0, RX - 1, RW) Shl 2) Or (JbRowBit(R0, RX, RW) Shl 1) Or JbRowBit(R0, RX + 1, RW);
  WP := (JbRowBit(RP, RX - 1, RW) Shl 2) Or (JbRowBit(RP, RX, RW) Shl 1) Or JbRowBit(RP, RX + 1, RW);
  WI := (JbRowBit(RowU, -1, W) Shl 2) Or (JbRowBit(RowU, 0, W) Shl 1) Or JbRowBit(RowU, 1, W);
  Cur := 0;
  For X := 0 To W - 1 Do Begin
   Bit := -1;
   If LTP <> 0 Then Begin
    { prédiction typique : voisinage 3x3 de la référence uniforme }
    If (WM = 0) And (W0 = 0) And (WP = 0) Then Bit := 0
    Else If (WM = 7) And (W0 = 7) And (WP = 7) Then Bit := 1;
   End;
   If Bit < 0 Then Begin
    If Templ = 0 Then Begin
     Ctx := (WM Shl 10) Or (W0 Shl 7) Or (WP Shl 4) Or (WI Shl 1) Or Cur;
     If Slow1 Then Ctx := (Ctx And (Not 8)) Or (JbGP(B, X + A1X, Y + A1Y) Shl 3);
     If Slow2 Then Ctx := (Ctx And (Not $1000)) Or (JbGP(Ref, RX + A2X, RY + A2Y) Shl 12);
    End Else
     Ctx := (((WM Shr 1) And 1) Shl 9) Or (W0 Shl 6) Or ((WP And 3) Shl 4) Or (WI Shl 1) Or Cur;
    Bit := JbMQ(Cx^[Ctx]);
   End;
   If Bit <> 0 Then RowC^[X Shr 3] := RowC^[X Shr 3] Or (128 Shr (X And 7));
   Cur := Bit;
   { fenêtres suivantes }
   Inc(RX);
   WM := ((WM Shl 1) And 7) Or JbRowBit(RM, RX + 1, RW);
   W0 := ((W0 Shl 1) And 7) Or JbRowBit(R0, RX + 1, RW);
   WP := ((WP Shl 1) And 7) Or JbRowBit(RP, RX + 1, RW);
   WI := ((WI Shl 1) And 7) Or JbRowBit(RowU, X + 2, W);
  End;
 End;
 JbRefine := True;
End;

{ ---- utilitaires de lecture ---- }

Function JbU32(D: PBigBytes; P: LongInt): LongWord;
Begin
 JbU32 := (LongWord(D^[P]) Shl 24) Or (LongWord(D^[P + 1]) Shl 16) Or (LongWord(D^[P + 2]) Shl 8) Or D^[P + 3];
End;

Function JbS32(D: PBigBytes; P: LongInt): LongInt;
Begin
 JbS32 := LongInt(JbU32(D, P));
End;

Function JbU16(D: PBigBytes; P: LongInt): LongInt;
Begin
 JbU16 := (LongInt(D^[P]) Shl 8) Or D^[P + 1];
End;

Function JbS8(D: PBigBytes; P: LongInt): LongInt;
Begin
 If D^[P] > 127 Then JbS8 := LongInt(D^[P]) - 256 Else JbS8 := D^[P];
End;

{ plancher de V / 2 }
Function JbHalf(V: LongInt): LongInt;
Begin
 JbHalf := (V - (V And 1)) Div 2;
End;

Function JbClamp(V: Int64): LongInt;
Begin
 If V > 1073741823 Then V := 1073741823;
 If V < -1073741823 Then V := -1073741823;
 JbClamp := V;
End;

{ ceil(log2(N)) pour N >= 1 }
Function JbLog2Up(N: LongInt): LongInt;
Var
 R: LongInt;
Begin
 R := 0;
 While (R < 31) And ((Int64(1) Shl R) < N) Do Inc(R);
 JbLog2Up := R;
End;

{ Décode un entier : 0 = ok, 1 = OOB, -1 = erreur }
Function JbDecI(Huff: Boolean; T: PJbHT; Cx: PBigBytes; Var V: LongInt): LongInt;
Begin
 If Huff Then JbDecI := JbHGet(T, V)
 Else If JbIntDec(Cx, V) Then JbDecI := 0
 Else JbDecI := 1;
End;

{ ---- région de texte (6.4) ---- }

{ Décode dans Reg (déjà allouée). C : contextes arithmétiques (ignoré en Huffman). }
Function JbTextDec(Var P: TJbTP; C: PJbTCtx; Reg: PJbBmp): Boolean;
Var
 V, Code, ID, RI, RDW, RDH, RDX, RDY, NInst, RSize, WI, HI, Pos, Rem: LongInt;
 StripT, FirstS, CurS, CurT, T, S, X0, Y0, Lft, Top: Int64;
 First, Ok: Boolean;
 IB, Tmp: PJbBmp;
 Huff: Boolean;
 Function DecI(Tb: PJbHT; Cx: PBigBytes): LongInt;
 Begin
  DecI := JbDecI(Huff, Tb, Cx, V);
 End;
Begin
 JbTextDec := False;
 Huff := P.Huff;
 JbFillBmp(Reg, P.DefPix);
 If DecI(P.TDT, PBigBytes(@C^.IADT[0])) <> 0 Then Exit;
 StripT := -Int64(V) * P.Strips;
 FirstS := 0; CurS := 0;
 NInst := 0;
 While NInst < P.NInst Do Begin
  If JbHErr Or (JbMOver > 300) Then Exit;
  If DecI(P.TDT, PBigBytes(@C^.IADT[0])) <> 0 Then Exit;
  StripT := StripT + Int64(V) * P.Strips;
  First := True;
  Repeat
   If First Then Begin
    If DecI(P.TFS, PBigBytes(@C^.IAFS[0])) <> 0 Then Exit;
    FirstS := FirstS + V;
    CurS := FirstS;
    First := False;
   End Else Begin
    Code := DecI(P.TDS, PBigBytes(@C^.IADS[0]));
    If Code = 1 Then Break;
    If Code < 0 Then Exit;
    If NInst >= P.NInst Then Exit;
    CurS := CurS + V + P.DSOff;
   End;
   If JbHErr Or (JbMOver > 300) Then Exit;
   If P.Strips = 1 Then CurT := 0
   Else If Huff Then CurT := JbHBits(P.LogStrips)
   Else Begin
    If DecI(Nil, PBigBytes(@C^.IAIT[0])) <> 0 Then Exit;
    CurT := V;
   End;
   T := StripT + CurT;
   { identifiant du symbole }
   If Not Huff Then ID := JbIAID(C^.IAID, P.CodeLen)
   Else If P.FixedCodes Then ID := JbHBits(P.CodeLen)
   Else Begin
    If JbHGet(P.TSym, ID) <> 0 Then Exit;
   End;
   If JbHErr Then Exit;
   RI := 0;
   If P.Refine Then Begin
    If Huff Then RI := JbHBit
    Else Begin
     If DecI(Nil, PBigBytes(@C^.IARI[0])) <> 0 Then Exit;
     RI := V;
    End;
   End;
   IB := Nil;
   If (ID >= 0) And (ID < P.NSyms) Then IB := P.Syms^[ID];
   Tmp := Nil;
   If RI <> 0 Then Begin
    RSize := 0;
    If Not Huff Then Begin
     If DecI(Nil, PBigBytes(@C^.IARDW[0])) <> 0 Then Exit; RDW := V;
     If DecI(Nil, PBigBytes(@C^.IARDH[0])) <> 0 Then Exit; RDH := V;
     If DecI(Nil, PBigBytes(@C^.IARDX[0])) <> 0 Then Exit; RDX := V;
     If DecI(Nil, PBigBytes(@C^.IARDY[0])) <> 0 Then Exit; RDY := V;
    End Else Begin
     If DecI(P.TRDW, Nil) <> 0 Then Exit; RDW := V;
     If DecI(P.TRDH, Nil) <> 0 Then Exit; RDH := V;
     If DecI(P.TRDX, Nil) <> 0 Then Exit; RDX := V;
     If DecI(P.TRDY, Nil) <> 0 Then Exit; RDY := V;
     If DecI(P.TRSIZE, Nil) <> 0 Then Exit; RSize := V;
     JbHAlign;
    End;
    If IB <> Nil Then Begin
     If (Int64(IB^.W) + RDW < 0) Or (Int64(IB^.H) + RDH < 0) Or
        ((Int64(IB^.W) + RDW) * (Int64(IB^.H) + RDH) > JbMaxSymPix) Then Exit;
     Tmp := JbNewBmp(IB^.W + RDW, IB^.H + RDH);
     If Tmp = Nil Then Exit;
     If Huff Then Begin
      Pos := JbHPos Shr 3;
      Rem := JbHLen - Pos;
      If Rem < 0 Then Rem := 0;
      If (RSize > 0) And (RSize < Rem) Then Rem := RSize;
      JbMQInit(PBigBytes(PByte(JbHBuf) + Pos), Rem);
     End;
     Ok := JbRefine(Tmp, IB, JbClamp(Int64(JbHalf(RDW)) + RDX), JbClamp(Int64(JbHalf(RDH)) + RDY),
                    P.RTempl, False, P.RAT[0], P.RAT[1], P.RAT[2], P.RAT[3], PBigBytes(@C^.GR[0]));
     If Not Ok Then Begin JbFreeBmp(Tmp); Exit; End;
     IB := Tmp;
    End;
    If Huff Then Begin
     If RSize < 0 Then RSize := 0;
     If Int64(RSize) + (JbHPos Shr 3) > JbHLen Then JbHErr := True
     Else JbHPos := JbHPos + RSize * 8;
    End;
   End;
   If IB <> Nil Then Begin WI := IB^.W; HI := IB^.H; End Else Begin WI := 0; HI := 0; End;
   If IB <> Nil Then Begin
    If (Not P.Transposed) And (P.RefCorner > 1) Then CurS := CurS + WI - 1
    Else If P.Transposed And ((P.RefCorner And 1) = 0) Then CurS := CurS + HI - 1;
   End;
   S := CurS;
   If Not P.Transposed Then Begin X0 := S; Y0 := T; End Else Begin X0 := T; Y0 := S; End;
   Lft := X0; Top := Y0;
   If (P.RefCorner And 2) <> 0 Then Lft := X0 - WI + 1;
   If (P.RefCorner And 1) = 0 Then Top := Y0 - HI + 1;
   If IB <> Nil Then JbBlit(Reg, IB, JbClamp(Lft), JbClamp(Top), P.CombOp);
   If IB <> Nil Then Begin
    If (Not P.Transposed) And (P.RefCorner < 2) Then CurS := CurS + WI - 1
    Else If P.Transposed And ((P.RefCorner And 1) <> 0) Then CurS := CurS + HI - 1;
   End;
   If Tmp <> Nil Then JbFreeBmp(Tmp);
   Inc(NInst);
   If NInst > JbMaxInst Then Exit;
   If JbWork > JbMaxWork Then Exit;
  Until False;
 End;
 JbTextDec := True;
End;

{ ---- table de codes des identifiants de symboles (7.4.3.1.7) ---- }

Function JbBuildSymCodes(NSyms: LongInt): PJbHT;
Var
 RT, T: PJbHT;
 I, Idx, Code, V, Rep, Prev: LongInt;
 Lens: PBigBytes;
Begin
 JbBuildSymCodes := Nil;
 RT := JbAlloc(SizeOf(TJbHT));
 If RT = Nil Then Exit;
 RT^.N := 35;
 RT^.L := JbAlloc(35 * SizeOf(TJbHLine));
 If RT^.L = Nil Then Exit;
 For I := 0 To 34 Do Begin
  RT^.L^[I].PL := JbHBits(4);
  RT^.L^[I].RL := 0;
  RT^.L^[I].Low := I;
  RT^.L^[I].Kind := 0;
 End;
 If JbHErr Or Not JbHBuild(RT) Then Exit;
 Lens := JbAlloc(Int64(NSyms) + 8);
 If Lens = Nil Then Exit;
 Idx := 0; Prev := 0;
 While Idx < NSyms Do Begin
  Code := JbHGet(RT, V);
  If (Code <> 0) Or JbHErr Then Exit;
  If V < 32 Then Begin
   Lens^[Idx] := V; Prev := V; Inc(Idx);
  End Else Begin
   If V = 32 Then Begin
    If Idx = 0 Then Exit;
    Rep := JbHBits(2) + 3;
    V := Prev;
   End Else If V = 33 Then Begin
    Rep := JbHBits(3) + 3;
    V := 0;
   End Else Begin
    Rep := JbHBits(7) + 11;
    V := 0;
   End;
   If JbHErr Then Exit;
   If Idx + Rep > NSyms Then Rep := NSyms - Idx;
   For I := 1 To Rep Do Begin Lens^[Idx] := V; Inc(Idx); End;
  End;
 End;
 JbHAlign;
 T := JbAlloc(SizeOf(TJbHT));
 If T = Nil Then Exit;
 T^.N := NSyms;
 T^.L := JbAlloc(Int64(NSyms + 1) * SizeOf(TJbHLine));
 If T^.L = Nil Then Exit;
 For I := 0 To NSyms - 1 Do Begin
  T^.L^[I].PL := Lens^[I];
  T^.L^[I].RL := 0;
  T^.L^[I].Low := I;
  T^.L^[I].Kind := 0;
 End;
 If Not JbHBuild(T) Then Exit;
 JbFree(Lens);
 JbBuildSymCodes := T;
End;

{ ---- état du segment courant ---- }

Var
 JbSD: PBigBytes;               { données du segment courant }
 JbSL: LongInt;                 { longueur des données }
 JbCurNum, JbCurTyp: LongInt;
 JbRef: PJbIntArr;              { numéros des segments référés }
 JbNRef: LongInt;
 JbRW, JbRH, JbRX, JbRY, JbROp: LongInt;   { informations de région }
 JbCT: Array[0..15] Of PJbHT;   { tables personnalisées référées }
 JbNCT, JbTI: LongInt;
 JbUnkRows: Int64;              { nombre de lignes d'une région de longueur inconnue (-1 si inconnu) }

Function JbFindSeg(Num: LongInt): LongInt;
Var
 I: LongInt;
Begin
 JbFindSeg := -1;
 For I := JbNSegs - 1 DownTo 0 Do
  If JbSegs^[I].Num = Num Then Begin JbFindSeg := I; Exit; End;
End;

{ Réserve un nouveau segment à résultat ; retourne son indice ou -1 }
Function JbAddSeg: LongInt;
Var
 NS: PJbSegArr;
 NC: LongInt;
Begin
 JbAddSeg := -1;
 If JbNSegs >= JbMaxSegRes Then Exit;
 If JbNSegs >= JbCapSegs Then Begin
  NC := JbCapSegs * 2 + 16;
  NS := JbAlloc(Int64(NC) * SizeOf(TJbSeg));
  If NS = Nil Then Exit;
  If JbNSegs > 0 Then Move(JbSegs^, NS^, Int64(JbNSegs) * SizeOf(TJbSeg));
  JbFree(JbSegs);
  JbSegs := NS;
  JbCapSegs := NC;
 End;
 FillChar(JbSegs^[JbNSegs], SizeOf(TJbSeg), 0);
 JbSegs^[JbNSegs].Num := JbCurNum;
 JbSegs^[JbNSegs].Typ := JbCurTyp;
 JbAddSeg := JbNSegs;
 Inc(JbNSegs);
End;

{ Lit les informations de région (7.4.1) : retourne False si invalide }
Function JbRegionInfo: Boolean;
Begin
 JbRegionInfo := False;
 If JbSL < 17 Then Exit;
 JbRW := JbS32(JbSD, 0); JbRH := JbS32(JbSD, 4);
 JbRX := JbClamp(JbS32(JbSD, 8)); JbRY := JbClamp(JbS32(JbSD, 12));
 JbROp := JbSD^[16] And 7;
 If JbROp > 4 Then JbROp := 0;
 If (JbRW < 0) Or (JbRH < 0) Or (Int64(JbRW) * JbRH > JbMaxPix) Then Exit;
 JbRegionInfo := True;
End;

{ ---- page ---- }

Procedure JbMakePage(W, H, Def: LongInt; Unk: Boolean);
Begin
 If JbPageHas Then Exit;
 If (W < 1) Or (H < 1) Or (Int64(W) * H > JbMaxPix) Then Begin
  { dimensions invalides : on retombe sur celles du dictionnaire d'image PDF }
  W := JbArgW; H := JbArgH;
  If (W < 1) Or (H < 1) Then Exit;
  If Int64(W) * H > JbMaxPix Then H := JbMaxPix Div W;
  If H < 1 Then Exit;
 End;
 JbPage := JbNewBmp(W, H);
 If JbPage = Nil Then Exit;
 JbPageDef := Def;
 If Def <> 0 Then JbFillBmp(JbPage, 1);
 JbPageHas := True;
 JbPageUnk := Unk;
 JbPageFinalH := 0;
 If Not Unk Then JbPageFinalH := H;
End;

{ Fait croître une page de hauteur inconnue pour qu'elle contienne NH lignes }
Procedure JbPageGrow(NH: Int64);
Var
 NP: PJbBmp;
 Y: LongInt;
Begin
 If (JbPage = Nil) Or (Not JbPageUnk) Or (NH <= JbPage^.H) Then Exit;
 If NH * JbPage^.W > JbMaxPix Then NH := JbMaxPix Div JbPage^.W;
 If NH <= JbPage^.H Then Exit;
 NP := JbNewBmp(JbPage^.W, NH);
 If NP = Nil Then Exit;
 JbFillBmp(NP, JbPageDef);
 For Y := 0 To JbPage^.H - 1 Do Move(JbRow(JbPage, Y)^, JbRow(NP, Y)^, JbPage^.RB);
 JbFreeBmp(JbPage);
 JbPage := NP;
End;

{ Page implicite si le flux ne contient pas de « page information » }
Procedure JbEnsurePage;
Begin
 If Not JbPageHas Then JbMakePage(JbArgW, JbArgH, 0, False);
End;

{ Dispose du bitmap B (libéré ensuite) : région intermédiaire ou composition sur la page }
Procedure JbPutRegion(B: PJbBmp);
Var
 S: LongInt;
Begin
 If B = Nil Then Exit;
 If (JbCurTyp = 4) Or (JbCurTyp = 20) Or (JbCurTyp = 36) Or (JbCurTyp = 40) Then Begin
  S := JbAddSeg;
  If S < 0 Then Begin JbFreeBmp(B); Exit; End;
  JbSegs^[S].Bmp := B;
   Exit;
 End;
 JbEnsurePage;
 If JbPage = Nil Then Begin JbFreeBmp(B); Exit; End;
 If JbPageUnk Then Begin
  JbPageGrow(Int64(JbRY) + B^.H);
  If Int64(JbRY) + B^.H > JbPageFinalH Then JbPageFinalH := JbClamp(Int64(JbRY) + B^.H);
 End;
 JbBlit(JbPage, B, JbRX, JbRY, JbROp);
 JbFreeBmp(B);
End;

{ Région immédiate sur une page connue : retourne False si elle est entièrement hors page ou
  démesurément plus large que la page ; sinon ne conserve que les lignes visibles (les lignes
  suivantes ne peuvent pas influencer les précédentes). }
Function JbCropRows: Boolean;
Var
 NH, PWid, PHei: Int64;
 Inter: Boolean;
Begin
 JbCropRows := True;
 Inter := (JbCurTyp = 4) Or (JbCurTyp = 20) Or (JbCurTyp = 36) Or (JbCurTyp = 40);
 If JbPage <> Nil Then Begin PWid := JbPage^.W; PHei := JbPage^.H; End
 Else Begin PWid := JbArgW; PHei := JbArgH; End;
 { régions démesurées par rapport à la page : flux corrompu }
 If Int64(JbRX) + JbRW > 2 * PWid + 64 Then Begin JbCropRows := False; Exit; End;
 If Inter Then Begin
  If (Not ((JbPage <> Nil) And JbPageUnk)) And (JbRH > 2 * PHei + 64) Then JbCropRows := False;
  Exit;
 End;
 If (JbPage = Nil) Or JbPageUnk Then Exit;
 If (JbRX >= JbPage^.W) Or (JbRY >= JbPage^.H) Then Begin JbCropRows := False; Exit; End;
 If Int64(JbRY) + JbRH > JbPage^.H Then Begin
  NH := Int64(JbPage^.H) - JbRY;
  If NH < 0 Then NH := 0;
  JbRH := NH;
 End;
End;

{ ---- région générique (7.4.6) ---- }

Procedure JbSegGeneric;
Var
 Fl, Pos, I, K: LongInt;
 MMR, Ext: Boolean;
 GP: TJbGP;
 B: PJbBmp;
 Cx: PBigBytes;
 Unk: Boolean;
Begin
 If Not JbRegionInfo Then Exit;
 If JbSL < 18 Then Exit;
 Fl := JbSD^[17];
 Pos := 18;
 MMR := (Fl And 1) <> 0;
 FillChar(GP, SizeOf(GP), 0);
 GP.Templ := (Fl Shr 1) And 3;
 GP.TPGD := (Fl And 8) <> 0;
 Ext := (Fl And 16) <> 0;
 If Not MMR Then Begin
  { EXTTEMPLATE (12 pixels adaptatifs) : seuls les 4 premiers sont pris en compte,
    les 8 autres sont supposés à leur position nominale }
  If GP.Templ = 0 Then I := 4 Else I := 1;
  If (GP.Templ = 0) And Ext Then K := 12 Else K := I;
  If Pos + K * 2 > JbSL Then Exit;
  For Pos := 0 To I * 2 - 1 Do GP.AT[Pos] := JbS8(JbSD, 18 + Pos);
  Pos := 18 + K * 2;
 End;
 { longueur inconnue : le nombre de lignes réel suit les données }
 Unk := JbCurTyp < 0;
 If Unk And (JbUnkRows >= 0) And (JbUnkRows < JbRH) Then JbRH := JbUnkRows;
 If Not JbCropRows Then Exit;
 B := JbNewBmp(JbRW, JbRH);
 If B = Nil Then Exit;
 If MMR Then Begin
  JbFreeBmp(B);
  B := JbMMRDec(PBigBytes(PByte(JbSD) + Pos), JbSL - Pos, JbRW, JbRH);
  If B = Nil Then Exit;
 End Else Begin
  Cx := JbAlloc(65536);
  If Cx = Nil Then Begin JbFreeBmp(B); Exit; End;
  JbMQInit(PBigBytes(PByte(JbSD) + Pos), JbSL - Pos);
  JbGeneric(B, GP, Cx);
  JbFree(Cx);
 End;
 JbPutRegion(B);
End;

{ ---- région de raffinement générique (7.4.7) ---- }

Procedure JbSegRefine;
Var
 Fl, Pos, S: LongInt;
 Ref, B: PJbBmp;
 Cx: PBigBytes;
 AT: Array[0..3] Of LongInt;
 OwnRef: Boolean;
 I: LongInt;
Begin
 If Not JbRegionInfo Then Exit;
 If JbSL < 18 Then Exit;
 Fl := JbSD^[17];
 Pos := 18;
 FillChar(AT, SizeOf(AT), 0);
 If (Fl And 1) = 0 Then Begin
  If JbSL < 22 Then Exit;
  For I := 0 To 3 Do AT[I] := JbS8(JbSD, 18 + I);
  Pos := 22;
 End;
 If Not JbCropRows Then Exit;
 { bitmap de référence : région intermédiaire référée, sinon la page }
 Ref := Nil; OwnRef := False;
 For I := 0 To JbNRef - 1 Do Begin
  S := JbFindSeg(JbRef^[I]);
  If (S >= 0) And (JbSegs^[S].Bmp <> Nil) Then Ref := JbSegs^[S].Bmp;
 End;
 If Ref = Nil Then Begin
  JbEnsurePage;
  If JbPage = Nil Then Exit;
  Ref := JbNewBmp(JbRW, JbRH);
  If Ref = Nil Then Exit;
  OwnRef := True;
  JbBlit(Ref, JbPage, -JbRX, -JbRY, 4);
 End;
 B := JbNewBmp(JbRW, JbRH);
 Cx := JbAlloc(8192);
 If (B = Nil) Or (Cx = Nil) Then Begin
  If OwnRef Then JbFreeBmp(Ref);
  JbFreeBmp(B); JbFree(Cx);
  Exit;
 End;
 JbMQInit(PBigBytes(PByte(JbSD) + Pos), JbSL - Pos);
 JbRefine(B, Ref, 0, 0, Fl And 1, (Fl And 2) <> 0, AT[0], AT[1], AT[2], AT[3], Cx);
 JbFree(Cx);
 If OwnRef Then JbFreeBmp(Ref);
 JbPutRegion(B);
End;

{ ---- tables de Huffman personnalisées (segment 53, Annexe B.2) ---- }

Procedure JbSegTable;
Var
 Fl, PS, RS, N, Cap: LongInt;
 Low, High, Cur: Int64;
 T: PJbHT;
 OOB: Boolean;
 S: LongInt;
Begin
 If JbSL < 9 Then Exit;
 Fl := JbSD^[0];
 OOB := (Fl And 1) <> 0;
 PS := ((Fl Shr 1) And 7) + 1;
 RS := ((Fl Shr 4) And 7) + 1;
 Low := JbS32(JbSD, 1); High := JbS32(JbSD, 5);
 If Low > High Then Exit;
 JbHInit(PBigBytes(PByte(JbSD) + 9), JbSL - 9);
 Cap := JbSL * 4 + 8;
 If Cap > 2000000 Then Cap := 2000000;
 T := JbAlloc(SizeOf(TJbHT));
 If T = Nil Then Exit;
 T^.L := JbAlloc(Int64(Cap + 4) * SizeOf(TJbHLine));
 If T^.L = Nil Then Exit;
 N := 0;
 Cur := Low;
 While Cur < High Do Begin
  If N >= Cap Then Exit;
  T^.L^[N].PL := JbHBits(PS);
  T^.L^[N].RL := JbHBits(RS);
  If JbHErr Or (T^.L^[N].RL > 32) Then Exit;
  T^.L^[N].Low := Cur;
  T^.L^[N].Kind := 0;
  Cur := Cur + (Int64(1) Shl T^.L^[N].RL);
  Inc(N);
 End;
 T^.L^[N].PL := JbHBits(PS); T^.L^[N].RL := 32; T^.L^[N].Low := JbClamp(Low - 1); T^.L^[N].Kind := 1; Inc(N);
 T^.L^[N].PL := JbHBits(PS); T^.L^[N].RL := 32; T^.L^[N].Low := JbS32(JbSD, 5); T^.L^[N].Kind := 2; Inc(N);
 If OOB Then Begin
  T^.L^[N].PL := JbHBits(PS); T^.L^[N].RL := 0; T^.L^[N].Low := 0; T^.L^[N].Kind := 3; Inc(N);
 End;
 If JbHErr Then Exit;
 T^.N := N;
 If Not JbHBuild(T) Then Exit;
 S := JbAddSeg;
 If S < 0 Then Exit;
 JbSegs^[S].Tab := T;
End;

{ ---- sélection des tables de Huffman ---- }

Procedure JbCollectTables;
Var
 I, S: LongInt;
Begin
 JbNCT := 0; JbTI := 0;
 For I := 0 To JbNRef - 1 Do Begin
  S := JbFindSeg(JbRef^[I]);
  If (S >= 0) And (JbSegs^[S].Tab <> Nil) And (JbNCT < 16) Then Begin
   JbCT[JbNCT] := JbSegs^[S].Tab;
   Inc(JbNCT);
  End;
 End;
End;

{ Sel 0 -> table A, 1 -> B, 2 -> C (si > 0), 3 -> table personnalisée suivante }
Function JbPickTab(Sel, A, B, C: LongInt): PJbHT;
Begin
 JbPickTab := Nil;
 If Sel = 3 Then Begin
  If JbTI < JbNCT Then Begin JbPickTab := JbCT[JbTI]; Inc(JbTI); End;
 End Else If Sel = 0 Then JbPickTab := JbHStd(A)
 Else If (Sel = 1) And (B > 0) Then JbPickTab := JbHStd(B)
 Else If (Sel = 2) And (C > 0) Then JbPickTab := JbHStd(C);
End;

{ ---- région de texte (7.4.3) ---- }

Procedure JbSegText;
Var
 P: TJbTP;
 C: PJbTCtx;
 Reg: PJbBmp;
 Fl, HF, Pos, I, J, S, Tot: LongInt;
Begin
 If Not JbRegionInfo Then Exit;
 If JbSL < 21 Then Exit;
 FillChar(P, SizeOf(P), 0);
 Pos := 17;
 Fl := JbU16(JbSD, Pos); Inc(Pos, 2);
 P.Huff := (Fl And 1) <> 0;
 P.Refine := (Fl And 2) <> 0;
 P.LogStrips := (Fl Shr 2) And 3;
 P.Strips := 1 Shl P.LogStrips;
 P.RefCorner := (Fl Shr 4) And 3;
 P.Transposed := (Fl And 64) <> 0;
 P.CombOp := (Fl Shr 7) And 3;
 P.DefPix := (Fl Shr 9) And 1;
 P.DSOff := (Fl Shr 10) And 31;
 If P.DSOff > 15 Then P.DSOff := P.DSOff - 32;
 P.RTempl := (Fl Shr 15) And 1;
 P.W := JbRW; P.H := JbRH;
 HF := 0;
 If P.Huff Then Begin
  If Pos + 2 > JbSL Then Exit;
  HF := JbU16(JbSD, Pos); Inc(Pos, 2);
 End;
 If P.Refine And (P.RTempl = 0) Then Begin
  If Pos + 4 > JbSL Then Exit;
  For I := 0 To 3 Do P.RAT[I] := JbS8(JbSD, Pos + I);
  Inc(Pos, 4);
 End;
 If Pos + 4 > JbSL Then Exit;
 P.NInst := JbClamp(JbU32(JbSD, Pos)); Inc(Pos, 4);
 If P.NInst > JbMaxInst Then Exit;
 { symboles : concaténation des symboles exportés des dictionnaires référés }
 Tot := 0;
 For I := 0 To JbNRef - 1 Do Begin
  S := JbFindSeg(JbRef^[I]);
  If (S >= 0) And (JbSegs^[S].Typ = 0) Then Tot := Tot + JbSegs^[S].NSyms;
  If Tot > JbMaxSyms Then Exit;
 End;
 P.NSyms := Tot;
 P.Syms := JbAlloc(Int64(Tot + 1) * SizeOf(Pointer));
 If P.Syms = Nil Then Exit;
 J := 0;
 For I := 0 To JbNRef - 1 Do Begin
  S := JbFindSeg(JbRef^[I]);
  If (S >= 0) And (JbSegs^[S].Typ = 0) And (JbSegs^[S].NSyms > 0) Then Begin
   Move(JbSegs^[S].Syms^, P.Syms^[J], Int64(JbSegs^[S].NSyms) * SizeOf(Pointer));
   J := J + JbSegs^[S].NSyms;
  End;
 End;
 P.CodeLen := JbLog2Up(P.NSyms);
 C := JbAlloc(SizeOf(TJbTCtx));
 If C = Nil Then Exit;
 If P.Huff Then Begin
  JbCollectTables;
  P.TFS := JbPickTab(HF And 3, 6, 7, 0);
  P.TDS := JbPickTab((HF Shr 2) And 3, 8, 9, 10);
  P.TDT := JbPickTab((HF Shr 4) And 3, 11, 12, 13);
  P.TRDW := JbPickTab((HF Shr 6) And 3, 14, 15, 0);
  P.TRDH := JbPickTab((HF Shr 8) And 3, 14, 15, 0);
  P.TRDX := JbPickTab((HF Shr 10) And 3, 14, 15, 0);
  P.TRDY := JbPickTab((HF Shr 12) And 3, 14, 15, 0);
  P.TRSIZE := JbPickTab(((HF Shr 14) And 1) * 3, 1, 0, 0);
  If (P.TFS = Nil) Or (P.TDS = Nil) Or (P.TDT = Nil) Or (P.TRDW = Nil) Or (P.TRDH = Nil) Or (P.TRDX = Nil) Or
     (P.TRDY = Nil) Or (P.TRSIZE = Nil) Then Exit;
  JbHInit(PBigBytes(PByte(JbSD) + Pos), JbSL - Pos);
  P.TSym := JbBuildSymCodes(P.NSyms);
  If P.TSym = Nil Then Exit;
 End Else Begin
  If P.CodeLen > 24 Then Exit;
  C^.IDLen := P.CodeLen;
  C^.IAID := JbAlloc(Int64(2) Shl P.CodeLen);
  If C^.IAID = Nil Then Exit;
  JbMQInit(PBigBytes(PByte(JbSD) + Pos), JbSL - Pos);
 End;
 Reg := JbNewBmp(JbRW, JbRH);
 If Reg = Nil Then Exit;
 JbTextDec(P, C, Reg);
 JbPutRegion(Reg);
End;

{ ---- dictionnaire de symboles (7.4.2, 6.5) ---- }

Procedure JbSegSymDict;
Var
 Fl, Pos, I, J, NIn, NNew, NDec, SymCodeLen, HCH, SymW, FirstSym, Code, V, Seg, X, AggN, ID, BMSize, RDX, RDY: LongInt;
 TotW, DictPix: Int64;
 Huff, RefAgg: Boolean;
 SDT, SDRT, NAT: LongInt;
 AT: Array[0..7] Of LongInt;
 RAT: Array[0..3] Of LongInt;
 TDH, TDW, TBM, TAGG, TEX: PJbHT;
 All: PJbBmpArr;
 Wd: PJbIntArr;
 GB: PBigBytes;
 C: PJbTCtx;
 GP: TJbGP;
 TP: TJbTP;
 Bmp, Coll: PJbBmp;
 IADH, IADW, IAEX, IAAI: Array[0..511] Of Byte;
 ExF: PBigBytes;
 NEx, Cur, Run, Empty, Rem: LongInt;
 Syms: PJbBmpArr;
 Failed: Boolean;
 SR: LongInt;
Begin
 If JbSL < 10 Then Exit;
 Fl := JbU16(JbSD, 0);
 Pos := 2;
 Huff := (Fl And 1) <> 0;
 RefAgg := (Fl And 2) <> 0;
 SDT := (Fl Shr 10) And 3;
 SDRT := (Fl Shr 12) And 1;
 TDH := Nil; TDW := Nil; TBM := Nil; TAGG := Nil;
 FillChar(AT, SizeOf(AT), 0);
 FillChar(RAT, SizeOf(RAT), 0);
 If Not Huff Then Begin
  If SDT = 0 Then NAT := 4 Else NAT := 1;
  If Pos + NAT * 2 > JbSL Then Exit;
  For I := 0 To NAT * 2 - 1 Do AT[I] := JbS8(JbSD, Pos + I);
  Inc(Pos, NAT * 2);
 End;
 If RefAgg And (SDRT = 0) Then Begin
  If Pos + 4 > JbSL Then Exit;
  For I := 0 To 3 Do RAT[I] := JbS8(JbSD, Pos + I);
  Inc(Pos, 4);
 End;
 If Pos + 8 > JbSL Then Exit;
 NEx := JbClamp(JbU32(JbSD, Pos));
 NNew := JbClamp(JbU32(JbSD, Pos + 4));
 Inc(Pos, 8);
 If (NNew < 0) Or (NNew > JbMaxSyms) Then Exit;
 { symboles d'entrée }
 NIn := 0;
 For I := 0 To JbNRef - 1 Do Begin
  Seg := JbFindSeg(JbRef^[I]);
  If (Seg >= 0) And (JbSegs^[Seg].Typ = 0) Then NIn := NIn + JbSegs^[Seg].NSyms;
  If NIn > JbMaxSyms Then Exit;
 End;
 If NIn + NNew > JbMaxSyms Then Exit;
 All := JbAlloc(Int64(NIn + NNew + 1) * SizeOf(Pointer));
 If All = Nil Then Exit;
 J := 0;
 GB := JbAlloc(65536);
 C := JbAlloc(SizeOf(TJbTCtx));
 If (GB = Nil) Or (C = Nil) Then Exit;
 For I := 0 To JbNRef - 1 Do Begin
  Seg := JbFindSeg(JbRef^[I]);
  If (Seg >= 0) And (JbSegs^[Seg].Typ = 0) And (JbSegs^[Seg].NSyms > 0) Then Begin
   Move(JbSegs^[Seg].Syms^, All^[J], Int64(JbSegs^[Seg].NSyms) * SizeOf(Pointer));
   J := J + JbSegs^[Seg].NSyms;
  End;
 End;
 { contextes réutilisés du dernier dictionnaire référé qui les a conservés }
 If (Fl And 256) <> 0 Then
  For I := 0 To JbNRef - 1 Do Begin
   Seg := JbFindSeg(JbRef^[I]);
   If (Seg >= 0) And (JbSegs^[Seg].Typ = 0) And (JbSegs^[Seg].GB <> Nil) Then Begin
    Move(JbSegs^[Seg].GB^, GB^, 65536);
    Move(JbSegs^[Seg].GR^, C^.GR, 8192);
   End;
  End;
 SymCodeLen := JbLog2Up(NIn + NNew);
 Failed := False;
 DictPix := 0;
 If Huff Then Begin
  JbCollectTables;
  TDH := JbPickTab((Fl Shr 2) And 3, 4, 5, 0);
  TDW := JbPickTab((Fl Shr 4) And 3, 2, 3, 0);
  TBM := JbPickTab(((Fl Shr 6) And 1) * 3, 1, 0, 0);
  TAGG := JbPickTab(((Fl Shr 7) And 1) * 3, 1, 0, 0);
  TEX := JbHStd(1);
  If (TDH = Nil) Or (TDW = Nil) Or (TBM = Nil) Or (TAGG = Nil) Or (TEX = Nil) Then Exit;
  JbHInit(PBigBytes(PByte(JbSD) + Pos), JbSL - Pos);
  If Not RefAgg Then Begin
   Wd := JbAlloc(Int64(NNew + 1) * SizeOf(LongInt));
   If Wd = Nil Then Exit;
  End;
 End Else Begin
  TEX := Nil;
  JbMQInit(PBigBytes(PByte(JbSD) + Pos), JbSL - Pos);
 End;
 If RefAgg Then Begin
  If Not Huff Then Begin
   If SymCodeLen > 24 Then Exit;
   C^.IAID := JbAlloc(Int64(2) Shl SymCodeLen);
   If C^.IAID = Nil Then Exit;
  End;
  FillChar(TP, SizeOf(TP), 0);
  TP.Huff := Huff; TP.Refine := True; TP.W := 0; TP.H := 0; TP.Strips := 1; TP.LogStrips := 0;
  TP.NSyms := NIn + NNew; TP.CodeLen := SymCodeLen; TP.DefPix := 0; TP.CombOp := 0;
  TP.Transposed := False; TP.RefCorner := 1; TP.DSOff := 0; TP.RTempl := SDRT;
  TP.Syms := All; TP.FixedCodes := True;
  For I := 0 To 3 Do TP.RAT[I] := RAT[I];
  If Huff Then Begin
   TP.TFS := JbHStd(6); TP.TDS := JbHStd(8); TP.TDT := JbHStd(11);
   TP.TRDW := JbHStd(15); TP.TRDH := JbHStd(15); TP.TRDX := JbHStd(15); TP.TRDY := JbHStd(15);
   TP.TRSIZE := JbHStd(1);
   If (TP.TFS = Nil) Or (TP.TDS = Nil) Or (TP.TDT = Nil) Or (TP.TRDW = Nil) Or (TP.TRSIZE = Nil) Then Exit;
  End;
 End;
 FillChar(IADH, SizeOf(IADH), 0); FillChar(IADW, SizeOf(IADW), 0);
 FillChar(IAEX, SizeOf(IAEX), 0); FillChar(IAAI, SizeOf(IAAI), 0);
 FillChar(GP, SizeOf(GP), 0);
 GP.Templ := SDT;
 For I := 0 To 7 Do GP.AT[I] := AT[I];
 { boucle principale : classes de hauteur }
 HCH := 0; NDec := 0;
 While (NDec < NNew) And Not Failed Do Begin
  If JbHErr Or (JbMOver > 300) Then Begin Failed := True; Break; End;
  If JbDecI(Huff, TDH, PBigBytes(@IADH[0]), V) <> 0 Then Begin Failed := True; Break; End;
  HCH := JbClamp(Int64(HCH) + V);
  If HCH < 0 Then Begin Failed := True; Break; End;
  SymW := 0; TotW := 0; FirstSym := NDec;
  While True Do Begin
   Code := JbDecI(Huff, TDW, PBigBytes(@IADW[0]), V);
   If Code = 1 Then Break;
   If (Code < 0) Or (NDec >= NNew) Or JbHErr Or (JbMOver > 300) Then Begin Failed := True; Break; End;
   SymW := JbClamp(Int64(SymW) + V);
   If SymW < 0 Then Begin Failed := True; Break; End;
   TotW := TotW + SymW;
   DictPix := DictPix + Int64(SymW) * HCH;
   If (Int64(SymW) * HCH > JbMaxSymPix) Or (DictPix > JbMaxDictPix) Then Begin Failed := True; Break; End;
   If (Not Huff) Or RefAgg Then Begin
    Bmp := JbNewBmp(SymW, HCH);
    If Bmp = Nil Then Begin Failed := True; Break; End;
    If Not RefAgg Then Begin
     JbGeneric(Bmp, GP, GB);
    End Else Begin
     If JbDecI(Huff, TAGG, PBigBytes(@IAAI[0]), AggN) <> 0 Then Begin Failed := True; Break; End;
     If AggN < 1 Then Begin Failed := True; Break; End;
     If AggN > 1 Then Begin
      TP.NInst := AggN;
      TP.W := SymW; TP.H := HCH;
      If Not JbTextDec(TP, C, Bmp) Then Begin Failed := True; Break; End;
     End Else Begin
      BMSize := 0;
      If Huff Then Begin
       ID := JbHBits(SymCodeLen);
       If JbHGet(JbHStd(15), RDX) <> 0 Then Begin Failed := True; Break; End;
       If JbHGet(JbHStd(15), RDY) <> 0 Then Begin Failed := True; Break; End;
       If JbHGet(JbHStd(1), BMSize) <> 0 Then Begin Failed := True; Break; End;
       JbHAlign;
      End Else Begin
       ID := JbIAID(C^.IAID, SymCodeLen);
       If JbIntDec(PBigBytes(@C^.IARDX[0]), RDX) Then Else Begin Failed := True; Break; End;
       If JbIntDec(PBigBytes(@C^.IARDY[0]), RDY) Then Else Begin Failed := True; Break; End;
      End;
      If JbHErr Or (ID < 0) Or (ID >= NIn + NDec) Or (All^[ID] = Nil) Then Begin Failed := True; Break; End;
      If Huff Then Begin
       Rem := JbHLen - (JbHPos Shr 3);
       If Rem < 0 Then Rem := 0;
       If (BMSize > 0) And (BMSize < Rem) Then Rem := BMSize;
       JbMQInit(PBigBytes(PByte(JbHBuf) + (JbHPos Shr 3)), Rem);
      End;
      If Not JbRefine(Bmp, All^[ID], RDX, RDY, SDRT, False, RAT[0], RAT[1], RAT[2], RAT[3], PBigBytes(@C^.GR[0])) Then Begin
       Failed := True; Break;
      End;
      If Huff Then Begin
       If BMSize = 0 Then BMSize := Bmp^.H * Bmp^.RB;
       If Int64(BMSize) + (JbHPos Shr 3) > JbHLen Then Begin Failed := True; Break; End;
       JbHPos := JbHPos + BMSize * 8;
      End;
     End;
    End;
    All^[NIn + NDec] := Bmp;
   End Else Wd^[NDec] := SymW;
   Inc(NDec);
  End;
  If Failed Then Break;
  { bitmap collectif d'une classe (6.5.9) }
  If Huff And Not RefAgg Then Begin
   If JbHGet(TBM, BMSize) <> 0 Then Begin Failed := True; Break; End;
   JbHAlign;
   Pos := JbHPos Shr 3;
   If (JbHErr) Or (BMSize < 0) Or (Pos > JbHLen) Then Begin Failed := True; Break; End;
   If TotW * HCH > 2 * JbMaxSymPix Then Begin Failed := True; Break; End;
   If BMSize = 0 Then Begin
    Coll := JbNewBmp(TotW, HCH);
    If Coll = Nil Then Begin Failed := True; Break; End;
    If Int64(Coll^.RB) * HCH > JbHLen - Pos Then Begin Failed := True; Break; End;
    If Coll^.RB * HCH > 0 Then Move((PByte(JbHBuf) + Pos)^, Coll^.D^, Coll^.RB * HCH);
    JbHPos := (Pos + Coll^.RB * HCH) * 8;
   End Else Begin
    If BMSize > JbHLen - Pos Then Begin Failed := True; Break; End;
    Coll := JbMMRDec(PBigBytes(PByte(JbHBuf) + Pos), BMSize, TotW, HCH);
    If Coll = Nil Then Begin Failed := True; Break; End;
    JbHPos := (Pos + BMSize) * 8;
   End;
   X := 0;
   For I := FirstSym To NDec - 1 Do Begin
    Bmp := JbNewBmp(Wd^[I], HCH);
    If Bmp = Nil Then Begin Failed := True; Break; End;
    JbBlit(Bmp, Coll, -X, 0, 4);
    X := X + Wd^[I];
    All^[NIn + I] := Bmp;
   End;
   JbFreeBmp(Coll);
  End;
 End;
 { indicateurs d'export (6.5.10) }
 ExF := JbAlloc(Int64(NIn + NNew) + 8);
 If ExF = Nil Then Exit;
 Cur := 0; I := 0; Empty := 0; NEx := 0;
 If Not Failed Then
  While I < NIn + NNew Do Begin
   If JbDecI(Huff, TEX, PBigBytes(@IAEX[0]), Run) <> 0 Then Begin Failed := True; Break; End;
   If (Run < 0) Or (Run > NIn + NNew - I) Then Begin Failed := True; Break; End;
   If Run = 0 Then Begin
    Inc(Empty);
    If Empty > 1000 Then Begin Failed := True; Break; End;
   End Else Empty := 0;
   For J := I To I + Run - 1 Do ExF^[J] := Cur;
   I := I + Run;
   Cur := 1 - Cur;
  End;
 If Failed Then Begin
  { flux corrompu : on exporte les symboles nouveaux décodés }
  FillChar(ExF^, NIn + NNew, 0);
  For I := NIn To NIn + NNew - 1 Do ExF^[I] := 1;
 End;
 NEx := 0;
 For I := 0 To NIn + NNew - 1 Do If (ExF^[I] <> 0) And (All^[I] <> Nil) Then Inc(NEx);
 Syms := JbAlloc(Int64(NEx + 1) * SizeOf(Pointer));
 If Syms = Nil Then Exit;
 J := 0;
 For I := 0 To NIn + NNew - 1 Do
  If (ExF^[I] <> 0) And (All^[I] <> Nil) Then Begin Syms^[J] := All^[I]; Inc(J); End;
 SR := JbAddSeg;
 If SR < 0 Then Exit;
 JbSegs^[SR].Syms := Syms;
 JbSegs^[SR].NSyms := NEx;
 If (Fl And 512) <> 0 Then Begin
  JbSegs^[SR].GB := JbAlloc(65536);
  JbSegs^[SR].GR := JbAlloc(8192);
  If (JbSegs^[SR].GB <> Nil) And (JbSegs^[SR].GR <> Nil) Then Begin
   Move(GB^, JbSegs^[SR].GB^, 65536);
   Move(C^.GR, JbSegs^[SR].GR^, 8192);
  End Else Begin
   JbFree(JbSegs^[SR].GB); JbFree(JbSegs^[SR].GR);
   JbSegs^[SR].GB := Nil; JbSegs^[SR].GR := Nil;
  End;
 End;
End;

{ ---- dictionnaire de motifs (7.4.4) et région de demi-teintes (7.4.5) ---- }

Procedure JbSegPattern;
Var
 Fl, PW, PH, I, N, S: LongInt;
 GrayMax: LongWord;
 Coll, Pt: PJbBmp;
 Cx: PBigBytes;
 GP: TJbGP;
 Arr: PJbBmpArr;
Begin
 If JbSL < 7 Then Exit;
 Fl := JbSD^[0];
 PW := JbSD^[1]; PH := JbSD^[2];
 GrayMax := JbU32(JbSD, 3);
 If (PW < 1) Or (PH < 1) Or (GrayMax > 1048575) Then Exit;
 N := GrayMax + 1;
 If Int64(N) * PW > JbMaxPix Then Exit;
 FillChar(GP, SizeOf(GP), 0);
 GP.Templ := (Fl Shr 1) And 3;
 GP.AT[0] := -PW; GP.AT[1] := 0; GP.AT[2] := -3; GP.AT[3] := -1;
 GP.AT[4] := 2; GP.AT[5] := -2; GP.AT[6] := -2; GP.AT[7] := -2;
 If (Fl And 1) <> 0 Then Begin
  Coll := JbMMRDec(PBigBytes(PByte(JbSD) + 7), JbSL - 7, N * PW, PH);
 End Else Begin
  Coll := JbNewBmp(N * PW, PH);
  Cx := JbAlloc(65536);
  If (Coll = Nil) Or (Cx = Nil) Then Exit;
  JbMQInit(PBigBytes(PByte(JbSD) + 7), JbSL - 7);
  JbGeneric(Coll, GP, Cx);
  JbFree(Cx);
 End;
 If Coll = Nil Then Exit;
 Arr := JbAlloc(Int64(N + 1) * SizeOf(Pointer));
 If Arr = Nil Then Exit;
 For I := 0 To N - 1 Do Begin
  Pt := JbNewBmp(PW, PH);
  If Pt = Nil Then Exit;
  JbBlit(Pt, Coll, -I * PW, 0, 4);
  Arr^[I] := Pt;
 End;
 JbFreeBmp(Coll);
 S := JbAddSeg;
 If S < 0 Then Exit;
 JbSegs^[S].Syms := Arr;
 JbSegs^[S].NSyms := N;
 JbSegs^[S].PW := PW; JbSegs^[S].PH := PH;
End;

{ division par 256 avec arrondi vers -infini }
Function JbSar8(V: Int64): Int64;
Begin
 If V >= 0 Then JbSar8 := V Div 256 Else JbSar8 := -((-V + 255) Div 256);
End;

{ vrai si les 24 bits à partir de la position (en bits) Bp valent l'EOFB }
Function JbIsEOFB(D: PBigBytes; Len, Bp: LongInt): Boolean;
Var
 I, V: LongInt;
 Bit: LongInt;
Begin
 JbIsEOFB := False;
 If Bp + 24 > Len * 8 Then Exit;
 V := 0;
 For I := 0 To 23 Do Begin
  Bit := (D^[(Bp + I) Shr 3] Shr (7 - ((Bp + I) And 7))) And 1;
  V := (V Shl 1) Or Bit;
 End;
 JbIsEOFB := V = $001001;
End;

Procedure JbSegHalftone;
Var
 Fl, Pos, HGW, HGH, HRX, HRY, HBPP, J, MG, NG, I, S, PS, NPats, GI, BPos, Bytes, HTemplate: LongInt;
 HGX, HGY, PX, PY: Int64;
 MMR, EnSkip: Boolean;
 HCOp, HDef: LongInt;
 Reg, Skip, Plane, PrevPl: PJbBmp;
 Pats: PJbBmpArr;
 Vals: PJbIntArr;
 Cx: PBigBytes;
 GP: TJbGP;
 PW, PH: LongInt;
 R0: PBigBytes;
Begin
 If Not JbRegionInfo Then Exit;
 If JbSL < 38 Then Exit;
 Fl := JbSD^[17];
 MMR := (Fl And 1) <> 0;
 HTemplate := (Fl Shr 1) And 3;
 EnSkip := (Fl And 8) <> 0;
 HCOp := (Fl Shr 4) And 7;
 If HCOp > 4 Then HCOp := 0;
 HDef := (Fl Shr 7) And 1;
 HGW := JbClamp(JbU32(JbSD, 18)); HGH := JbClamp(JbU32(JbSD, 22));
 HGX := JbS32(JbSD, 26); HGY := JbS32(JbSD, 30);
 HRX := JbU16(JbSD, 34); HRY := JbU16(JbSD, 36);
 Pos := 38;
 If (HGW < 1) Or (HGH < 1) Or (Int64(HGW) * HGH > 16000000) Then Exit;
 { dictionnaire de motifs référé }
 PS := -1;
 For I := 0 To JbNRef - 1 Do Begin
  S := JbFindSeg(JbRef^[I]);
  If (S >= 0) And (JbSegs^[S].Typ = 16) Then PS := S;
 End;
 If PS < 0 Then Exit;
 Pats := JbSegs^[PS].Syms; NPats := JbSegs^[PS].NSyms;
 PW := JbSegs^[PS].PW; PH := JbSegs^[PS].PH;
 If NPats < 1 Then Exit;
 HBPP := JbLog2Up(NPats);
 If Int64(HGW) * HGH * (HBPP + 1) > 400000000 Then Exit;
 Reg := JbNewBmp(JbRW, JbRH);
 If Reg = Nil Then Exit;
 JbFillBmp(Reg, HDef);
 Vals := JbAlloc(Int64(HGW) * HGH * SizeOf(LongInt) + 8);
 If Vals = Nil Then Begin JbFreeBmp(Reg); Exit; End;
 { bitmap de saut (6.6.5.1) }
 Skip := Nil;
 If EnSkip Then Begin
  Skip := JbNewBmp(HGW, HGH);
  If Skip = Nil Then Begin JbFreeBmp(Reg); Exit; End;
  For MG := 0 To HGH - 1 Do
   For NG := 0 To HGW - 1 Do Begin
    PX := JbSar8(HGX + Int64(MG) * HRY + Int64(NG) * HRX);
    PY := JbSar8(HGY + Int64(MG) * HRX - Int64(NG) * HRY);
    If (PX + PW <= 0) Or (PX >= JbRW) Or (PY + PH <= 0) Or (PY >= JbRH) Then JbSP(Skip, NG, MG, 1);
   End;
 End;
 { image en niveaux de gris (Annexe C) }
 Cx := Nil;
 If Not MMR Then Begin
  Cx := JbAlloc(65536);
  If Cx = Nil Then Begin JbFreeBmp(Reg); Exit; End;
  JbMQInit(PBigBytes(PByte(JbSD) + Pos), JbSL - Pos);
 End;
 FillChar(GP, SizeOf(GP), 0);
 GP.Templ := HTemplate;
 GP.Skip := Skip;
 If HTemplate <= 1 Then GP.AT[0] := 3 Else GP.AT[0] := 2;
 GP.AT[1] := -1; GP.AT[2] := -3; GP.AT[3] := -1; GP.AT[4] := 2; GP.AT[5] := -2; GP.AT[6] := -2; GP.AT[7] := -2;
 PrevPl := Nil;
 BPos := Pos;
 For J := HBPP - 1 DownTo 0 Do Begin
  If MMR Then Begin
   If BPos > JbSL Then BPos := JbSL;
   Plane := JbMMRDec(PBigBytes(PByte(JbSD) + BPos), JbSL - BPos, HGW, HGH);
   If Plane <> Nil Then Begin
    I := JbMMRBits;
    If JbIsEOFB(PBigBytes(PByte(JbSD) + BPos), JbSL - BPos, I) Then I := I + 24;
    BPos := BPos + ((I + 7) Shr 3);
   End;
  End Else Begin
   Plane := JbNewBmp(HGW, HGH);
   If Plane <> Nil Then JbGeneric(Plane, GP, Cx);
  End;
  If Plane = Nil Then Begin
   JbFreeBmp(PrevPl); JbFreeBmp(Reg); JbFreeBmp(Skip); JbFree(Cx);
   Exit;
  End;
  If PrevPl <> Nil Then Begin
   { code de Gray : plan J = plan J+1 xor plan J }
   Bytes := Plane^.RB * Plane^.H;
   For I := 0 To Bytes - 1 Do Plane^.D^[I] := Plane^.D^[I] Xor PrevPl^.D^[I];
   JbFreeBmp(PrevPl);
  End;
  For MG := 0 To HGH - 1 Do Begin
   R0 := JbRow(Plane, MG);
   For NG := 0 To HGW - 1 Do
    If ((R0^[NG Shr 3] Shr (7 - (NG And 7))) And 1) <> 0 Then
     Vals^[MG * HGW + NG] := Vals^[MG * HGW + NG] Or (1 Shl J);
  End;
  PrevPl := Plane;
 End;
 JbFreeBmp(PrevPl);
 JbFreeBmp(Skip);
 JbFree(Cx);
 { dessin des motifs (6.6.5.2) }
 For MG := 0 To HGH - 1 Do
  For NG := 0 To HGW - 1 Do Begin
   PX := JbSar8(HGX + Int64(MG) * HRY + Int64(NG) * HRX);
   PY := JbSar8(HGY + Int64(MG) * HRX - Int64(NG) * HRY);
   GI := Vals^[MG * HGW + NG];
   If GI >= NPats Then GI := NPats - 1;
   If (PX + PW > 0) And (PX < JbRW) And (PY + PH > 0) And (PY < JbRH) Then
    JbBlit(Reg, Pats^[GI], JbClamp(PX), JbClamp(PY), HCOp);
   If JbWork > JbMaxWork Then Break;
  End;
 JbFree(Vals);
 JbPutRegion(Reg);
End;

{ ---- page, fin de bande ---- }

Procedure JbSegPage;
Var
 W, H, Fl: LongInt;
 Unk: Boolean;
Begin
 If JbPageHas Then Begin JbDone := True; Exit; End;
 If JbSL < 19 Then Exit;
 W := JbClamp(JbU32(JbSD, 0));
 Unk := JbU32(JbSD, 4) = $FFFFFFFF;
 If Unk Then H := JbArgH Else H := JbClamp(JbU32(JbSD, 4));
 If Unk And (H < 1) Then H := 1;
 If Unk And (Int64(W) * H > JbMaxPix) And (W > 0) Then H := JbMaxPix Div W;
 Fl := JbSD^[16];
 JbMakePage(W, H, (Fl Shr 2) And 1, Unk);
End;

Procedure JbSegStripe;
Var
 Y: Int64;
Begin
 If (JbSL < 4) Or (JbPage = Nil) Then Exit;
 Y := Int64(JbU32(JbSD, 0)) + 1;
 If JbPageUnk Then Begin
  JbPageGrow(Y);
  If Y > JbPageFinalH Then JbPageFinalH := JbClamp(Y);
 End;
End;

{ ---- analyse d'un flux de segments ---- }

Procedure JbParseStream(D: PBigBytes; Len: LongInt);
Var
 Pos, P, Cnt, RS, I, PA, Q: LongInt;
 Num, Typ, Fl, Skip4: LongInt;
 DL: Int64;
 Refs: PJbIntArr;
 Marker: Boolean;
Begin
 Pos := 0;
 While (Pos + 11 <= Len) And Not JbDone Do Begin
  Num := LongInt(JbU32(D, Pos));
  Fl := D^[Pos + 4];
  Typ := Fl And 63;
  P := Pos + 5;
  Cnt := D^[P] Shr 5;
  If Cnt = 7 Then Begin
   If P + 4 > Len Then Break;
   Cnt := LongInt(JbU32(D, P) And $1FFFFFFF);
   If Cnt > 100000 Then Break;
   P := P + 4 + ((Cnt + 8) Shr 3);
  End Else Inc(P);
  If Num <= 256 Then RS := 1 Else If Num <= 65536 Then RS := 2 Else RS := 4;
  If (Num < 0) Then RS := 4;
  If Int64(P) + Int64(Cnt) * RS + 5 > Len Then Break;
  Refs := JbAlloc(Int64(Cnt + 1) * SizeOf(LongInt));
  If Refs = Nil Then Break;
  For I := 0 To Cnt - 1 Do Begin
   If RS = 1 Then Refs^[I] := D^[P]
   Else If RS = 2 Then Refs^[I] := JbU16(D, P)
   Else Refs^[I] := LongInt(JbU32(D, P));
   Inc(P, RS);
  End;
  If (Fl And 64) <> 0 Then PA := 4 Else PA := 1;
  If Int64(P) + PA + 4 > Len Then Begin JbFree(Refs); Break; End;
  Inc(P, PA);
  DL := JbU32(D, P);
  Inc(P, 4);
  { longueur inconnue (région générique immédiate) : recherche du marqueur de fin }
  Skip4 := 0;
  If (DL = $FFFFFFFF) And (Typ = 38) And (P + 19 < Len) Then Begin
   Marker := (D^[P + 17] And 1) <> 0;
   Q := P + 18;
   DL := -1;
   JbUnkRows := -1;
   While Q + 1 < Len Do Begin
    If Marker Then Begin
     If (D^[Q] = 0) And (D^[Q + 1] = 0) Then Begin DL := Q + 2 - P; Break; End;
    End Else If (D^[Q] = $FF) And (D^[Q + 1] = $AC) Then Begin DL := Q + 2 - P; Break; End;
    Inc(Q);
   End;
   If DL < 0 Then DL := Len - P
   Else If Q + 6 <= Len Then Begin JbUnkRows := JbU32(D, Q + 2); Skip4 := 4; End;
   { signale la longueur inconnue au traitement du segment : Typ négatif }
   JbCurTyp := -1;
  End Else Begin
   If DL > Len - P Then DL := Len - P;
   JbCurTyp := Typ;
  End;
  JbSD := PBigBytes(PByte(D) + P);
  JbSL := DL;
  JbCurNum := Num;
  JbRef := Refs; JbNRef := Cnt;
   If JbCurTyp < 0 Then Begin
   JbSegGeneric;
  End Else
   Case Typ Of
    0: JbSegSymDict;
    4, 6, 7: JbSegText;
    16: JbSegPattern;
    20, 22, 23: JbSegHalftone;
    36, 38, 39: JbSegGeneric;
    40, 42, 43: JbSegRefine;
    48: JbSegPage;
    49, 51: JbDone := True;
    50: JbSegStripe;
    53: JbSegTable;
   End;
  JbFree(Refs);
  Pos := P + DL + Skip4;
 End;
End;

{ ---- point d'entrée ---- }

{ Décode un flux JBIG2 « intégré PDF » (segments séquentiels sans en-tête de fichier),
  précédé des segments globaux Glob (ou Nil). Dst : RowBytes * Height octets, 1 bit par pixel,
  convention PDF (0 = noir, 1 = blanc). Retourne False si rien n'a pu être décodé. }
Function JBIG2Decode(Src: PBigBytes; SLen: LongInt; Glob: PBigBytes; GLen: LongInt;
  Width, Height: LongInt; Dst: PBigBytes): Boolean;
Var
 OldRN: Boolean;
 RBD, Y, NR, CB, I: LongInt;
 PS, PD: PByte;
Begin
 JBIG2Decode := False;
 If (Dst = Nil) Or (Width < 1) Or (Height < 1) Then Exit;
 OldRN := ReturnNilIfGrowHeapFails;
 ReturnNilIfGrowHeapFails := True;
 JbHdrList := Nil; JbLive := 0; JbWork := 0;
 JbSegs := Nil; JbNSegs := 0; JbCapSegs := 0;
 JbPage := Nil; JbPageHas := False; JbPageUnk := False; JbPageDef := 0; JbPageFinalH := 0;
 JbDone := False;
 JbArgW := Width; JbArgH := Height;
 JbUnkRows := -1;
 FillChar(JbStdT, SizeOf(JbStdT), 0);
 JbInitTab;
 RBD := (Width + 7) Shr 3;
 If (Glob <> Nil) And (GLen > 0) Then JbParseStream(Glob, GLen);
 JbDone := False;
 If (Src <> Nil) And (SLen > 0) Then JbParseStream(Src, SLen);
 If JbPage <> Nil Then Begin
  { sortie : page recopiée / rognée, bits inversés (1 = blanc) ; hors page = blanc }
  FillChar(Dst^, Int64(RBD) * Height, 255);
  NR := Height;
  If NR > JbPage^.H Then NR := JbPage^.H;
  If NR > JbPageFinalH Then NR := JbPageFinalH;
  CB := RBD;
  If CB > JbPage^.RB Then CB := JbPage^.RB;
  For Y := 0 To NR - 1 Do Begin
   PS := PByte(JbRow(JbPage, Y));
   PD := PByte(Dst) + Int64(Y) * RBD;
   For I := 1 To CB Do Begin
    PD^ := Not PS^;
    Inc(PS); Inc(PD);
   End;
  End;
  JBIG2Decode := True;
 End;
 JbFreeAll;
 JbSegs := Nil; JbPage := Nil;
 ReturnNilIfGrowHeapFails := OldRN;
End;
{$ENDIF}

{ ---------------------------------------------------------------------- }
{ Images : décodage (JPEG, Flate brut, palettes, masques)                   }
{ ---------------------------------------------------------------------- }

{$IFDEF FPC}
Const
 IMGMAXBYTES = 100000000;

Var
 IW, IH, IBpc, ICS, IComps, IPalBase, IRow: LongInt;
 IInv, IMaskImg, IJpeg: Boolean;
 IData: PBigBytes;
 IRGB: PBigBytes;
 IPal: Array[0..767] Of Byte;
 IPalN: Integer;
 IFlt: Array[0..3] Of String[24];
 INF, IPred, ICols, IClr: Integer;
 IK, ICCCols: LongInt;
 IBlackIs1, IByteAlign: Boolean;
 IJbGlob: LongInt;

Var
 IDesc: TCSDesc;
 IDescOn: Boolean;

Procedure IDescClear;
Begin
 If IDescOn Then CSDescFree(IDesc);
 IDescOn := False;
 FillChar(IDesc, SizeOf(IDesc), 0);
End;

{ Convertit un descripteur d'espace en code d'image : 1 gris, 3 RVB, 4 CMJN,
  5 indexé (palette RVB), 7 teinte, 8 Lab. Own : la table appartient à l'image. }
Function CSCodeFromDesc(Var D: TCSDesc; Var CS, Comps, PalBase: LongInt; Own: Boolean): Boolean;
Begin
 CSCodeFromDesc := False;
 IPalN := 0;
 Case D.Kind Of
  1: Begin CS := 1; Comps := 1; CSCodeFromDesc := True; End;
  3: Begin CS := 3; Comps := 3; CSCodeFromDesc := True; End;
  4: Begin CS := 4; Comps := 4; CSCodeFromDesc := True; End;
  5: Begin
   If (D.Pal <> Nil) And (D.PalN <= 768) Then Begin
    Move(D.Pal^[0], IPal[0], D.PalN);
    IPalN := D.PalN;
    CS := 5; Comps := 1; PalBase := 3;
    CSCodeFromDesc := True;
   End;
  End;
  6: Begin
   IDesc := D; IDescOn := False;
   CS := 8; Comps := 3; CSCodeFromDesc := True;
  End;
  7: Begin
   If (D.N >= 1) And (D.N <= 4) And (Not D.NoPaint) Then Begin
    IDesc := D; IDescOn := False;
    CS := 7; Comps := D.N; CSCodeFromDesc := True;
    If Own Then Begin IDescOn := True; Own := False; End;
   End;
  End;
 End;
 If Own Then CSDescFree(D);
End;

{ Analyse d'un espace colorimétrique à la position V (valeur de dictionnaire) }
Function ParseCS(V: LongInt; Depth: Integer; Var CS, Comps, PalBase: LongInt): Boolean;
Var
 D: TCSDesc;
Begin
 IDescClear;
 ParseCS := False;
 If Not ParseCSDesc(V, 0, D) Then Exit;
 ParseCS := CSCodeFromDesc(D, CS, Comps, PalBase, True);
End;

{ Idem pour un nom d'espace défini dans les ressources (images en ligne) }
Function ParseCSRes(V: LongInt; Var CS, Comps, PalBase: LongInt): Boolean;
Var
 Q: LongInt;
 K: Integer;
 Nm: String;
Begin
 ParseCSRes := False;
 If V < 0 Then Exit;
 Q := V;
 If NextTok(Q) <> T_NAME Then Exit;
 Nm := TokS;
 K := CSByName(Nm);
 If K < 0 Then Exit;
 IDescClear;
 ParseCSRes := CSCodeFromDesc(CSCache[K].D, CS, Comps, PalBase, False);
End;

{ Lecture du flux brut (encore encodé) de l'objet en P }
Function ReadRawStream(P: LongInt; Var Raw: Pointer; Var RawLen: LongInt): Boolean;
Var
 V, Q, DStart, Len, Done, ToRead: LongInt;
 LenVal: LongInt;
 Got: Word;
 Buf: PBigBytes;
Begin
 ReadRawStream := False;
 Raw := Nil;
 RawLen := 0;
 SrcMode := 0;
 V := DictFind(P, 'Length');
 LenVal := -1;
 If V >= 0 Then LenVal := ValInt(V, -1);
 SrcMode := 0;
 Q := P;
 SkipValue(Q);
 If NextTok(Q) <> T_OP Then Exit;
 If TokS <> 'stream' Then Exit;
 DStart := Q;
 If Not FindStreamData(DStart, Len, LenVal) Then Exit;
 If (Len < 1) Or (Len > IMGMAXBYTES) Then Exit;
 GetMem(Buf, Len + 16);
 Seek(PF, DStart);
 Done := 0;
 While Done < Len Do Begin
  ToRead := Len - Done;
  If ToRead > 32768 Then ToRead := 32768;
  Got := 0;
  BlockRead(PF, Buf^[Done], ToRead, Got);
  If Got = 0 Then Break;
  Done := Done + Got;
 End;
 RBase := -1; RLen := 0;
 If Done < 1 Then Begin FreeMem(Buf, Len + 16); Exit; End;
 Raw := Buf;
 RawLen := Done;
 ReadRawStream := True;
End;

Procedure ReadFiltersAndParms(P: LongInt);
Var
 V, Q, Pos0, DP: LongInt;
 T: Integer;
Begin
 INF := 0; IPred := 1; ICols := 1; IClr := 1;
 IK := 0; ICCCols := 1728; IBlackIs1 := False; IByteAlign := False; IJbGlob := 0;
 SrcMode := 0;
 V := DictFind(P, 'Filter');
 If V < 0 Then V := DictFind(P, 'F');
 If V >= 0 Then Begin
  Q := V;
  T := NextTok(Q);
  If T = T_NAME Then Begin IFlt[0] := TokS; INF := 1; End
  Else If T = T_AB Then
   While INF < 4 Do Begin
    T := NextTok(Q);
    If T = T_NAME Then Begin IFlt[INF] := TokS; Inc(INF); End Else Break;
   End;
 End;
 V := DictFind(P, 'DecodeParms');
 If V < 0 Then V := DictFind(P, 'DP');
 If V >= 0 Then Begin
  DP := -1;
  Q := V;
  Pos0 := Q;
  T := NextTok(Q);
  If T = T_DB Then DP := Pos0
  Else If T = T_AB Then
   While True Do Begin
    Pos0 := Q;
    T := NextTok(Q);
    If T = T_DB Then Begin DP := Pos0; Q := Pos0; SkipValue(Q); End
    Else If (T = T_AE) Or (T = T_EOF) Then Break;
   End;
  If DP >= 0 Then Begin
   IPred := ValInt(DictFind(DP, 'Predictor'), 1);
   ICols := ValInt(DictFind(DP, 'Columns'), 1);
   IClr := ValInt(DictFind(DP, 'Colors'), 1);
   IK := ValInt(DictFind(DP, 'K'), 0);
   Q := DictFind(DP, 'JBIG2Globals');
   If Q >= 0 Then IJbGlob := RefAt(Q);
   ICCCols := ValInt(DictFind(DP, 'Columns'), 1728);
   Q := DictFind(DP, 'BlackIs1');
   If Q >= 0 Then If NextTok(Q) = T_OP Then IBlackIs1 := TokS = 'true';
   Q := DictFind(DP, 'EncodedByteAlign');
   If Q >= 0 Then If NextTok(Q) = T_OP Then IByteAlign := TokS = 'true';
  End;
 End;
End;

{ Annule le filtre de prédiction PNG : retourne un nouveau tampon }
Function Unpredict(Src: PBigBytes; SLen: LongInt; RowBytes, Rows, Bpp: LongInt): PBigBytes;
Var
 Dst: PBigBytes;
 Y, X, Pos: LongInt;
 Ft, A, B, C, Pa, Pb, Pc, Px: Integer;
Begin
 GetMem(Dst, RowBytes * Rows + 16);
 FillChar(Dst^, RowBytes * Rows, 0);
 Pos := 0;
 For Y := 0 To Rows - 1 Do Begin
  If Pos >= SLen Then Break;
  Ft := Src^[Pos]; Inc(Pos);
  For X := 0 To RowBytes - 1 Do Begin
   If Pos >= SLen Then Break;
   Px := Src^[Pos]; Inc(Pos);
   If X >= Bpp Then A := Dst^[Y * RowBytes + X - Bpp] Else A := 0;
   If Y > 0 Then B := Dst^[(Y - 1) * RowBytes + X] Else B := 0;
   If (Y > 0) And (X >= Bpp) Then C := Dst^[(Y - 1) * RowBytes + X - Bpp] Else C := 0;
   Case Ft Of
    1: Px := Px + A;
    2: Px := Px + B;
    3: Px := Px + (A + B) Div 2;
    4: Begin
     Pa := Abs(B - C); Pb := Abs(A - C); Pc := Abs(A + B - 2 * C);
     If (Pa <= Pb) And (Pa <= Pc) Then Px := Px + A
     Else If Pb <= Pc Then Px := Px + B
     Else Px := Px + C;
    End;
   End;
   Dst^[Y * RowBytes + X] := Px And 255;
  End;
 End;
 Unpredict := Dst;
End;

{ Échantillon brut -> RVB }
Procedure SampleRaw(X, Y: LongInt; Var R, G, B: Integer);
Var
 C: Integer;
 Cf: Array[0..3] Of Real;
 Rg: LongInt;
 V: Array[0..3] Of Integer;
 BitPos, Mx: LongInt;
 Idx: Integer;
Begin
 For C := 0 To IComps - 1 Do Begin
  If IBpc = 8 Then V[C] := IData^[Y * IRow + X * IComps + C]
  Else If IBpc = 16 Then V[C] := IData^[Y * IRow + (X * IComps + C) * 2]
  Else Begin
   BitPos := (X * IComps + C) * IBpc;
   Mx := (1 Shl IBpc) - 1;
   V[C] := (IData^[Y * IRow + (BitPos Shr 3)] Shr (8 - IBpc - (BitPos And 7))) And Mx;
   If ICS <> 5 Then V[C] := V[C] * 255 Div Mx;
  End;
 End;
 If IInv And (ICS <> 5) Then For C := 0 To IComps - 1 Do V[C] := 255 - V[C];
 Case ICS Of
  1: Begin R := V[0]; G := V[0]; B := V[0]; End;
  6: Begin R := 255 - V[0]; G := R; B := R; End;
  3: Begin R := V[0]; G := V[1]; B := V[2]; End;
  7: Begin
   For C := 0 To IComps - 1 Do Cf[C] := V[C] / 255;
   Rg := ColorToRgb(IDesc, Cf, IComps);
   R := (Rg Shr 16) And 255; G := (Rg Shr 8) And 255; B := Rg And 255;
  End;
  8: Begin
   Cf[0] := V[0] / 255 * 100;
   Cf[1] := IDesc.Amin + V[1] / 255 * (IDesc.Amax - IDesc.Amin);
   Cf[2] := IDesc.Bmin + V[2] / 255 * (IDesc.Bmax - IDesc.Bmin);
   Rg := LabToRgb(Cf[0], Cf[1], Cf[2], IDesc);
   R := (Rg Shr 16) And 255; G := (Rg Shr 8) And 255; B := Rg And 255;
  End;
  4: Begin
   Rg := CmykPoly(V[0] / 255, V[1] / 255, V[2] / 255, V[3] / 255);
   R := (Rg Shr 16) And 255; G := (Rg Shr 8) And 255; B := Rg And 255;
  End;
 Else
  Begin
   Idx := V[0];
   If (Idx * IPalBase + IPalBase - 1) < IPalN Then Begin
    If IPalBase = 1 Then Begin R := IPal[Idx]; G := R; B := R; End
    Else If IPalBase = 3 Then Begin R := IPal[Idx * 3]; G := IPal[Idx * 3 + 1]; B := IPal[Idx * 3 + 2]; End
    Else Begin
     R := (255 - IPal[Idx * 4]) * (255 - IPal[Idx * 4 + 3]) Div 255;
     G := (255 - IPal[Idx * 4 + 1]) * (255 - IPal[Idx * 4 + 3]) Div 255;
     B := (255 - IPal[Idx * 4 + 2]) * (255 - IPal[Idx * 4 + 3]) Div 255;
    End;
   End
   Else Begin R := 0; G := 0; B := 0; End;
  End;
 End;
End;

Procedure SampleJpeg(X, Y: LongInt; Var R, G, B: Integer);
Var
 O: LongInt;
Begin
 O := (Y * IW + X) * 3;
 R := IRGB^[O]; G := IRGB^[O + 1]; B := IRGB^[O + 2];
End;


Type
 TWordsBig = Array[0..67108863] Of Word;
 PWordsBig = ^TWordsBig;

Procedure FreeImages;
Var
 I: Integer;
Begin
 For I := 1 To ImgCount Do Begin
  If ImgP(I)^.Pix <> Nil Then FreeMem(ImgP(I)^.Pix, LongInt(ImgP(I)^.W) * ImgP(I)^.H * 2);
  If ImgP(I)^.Alpha <> Nil Then FreeMem(ImgP(I)^.Alpha, LongInt(ImgP(I)^.W) * ImgP(I)^.H);
  If ImgP(I)^.Raw <> Nil Then FreeMem(ImgP(I)^.Raw, ImgP(I)^.RawLen + 16);
  If ImgP(I)^.Pal <> Nil Then FreeMem(ImgP(I)^.Pal, ImgP(I)^.PalN);
 End;
 ImgListFree;
End;

{ Réduit l'image courante (contexte I*) à au plus ImgMaxDim pixels }
Procedure Downsample(Var TW_, TH_: LongInt; Var Pix: PWordsBig; Var Alpha: PBigBytes);
Var
 X, Y, I, J, NX, NY, X0, X1, Y0, Y1, SX, SY, Cnt: LongInt;
 SR, SG, SB: LongInt;
 R, G, B: Integer;
 K: Integer;
Begin
 If IW >= IH Then Begin
  TW_ := IMin(IW, ImgMaxDim);
  TH_ := IMax(1, (IH * TW_) Div IW);
 End
 Else Begin
  TH_ := IMin(IH, ImgMaxDim);
  TW_ := IMax(1, (IW * TH_) Div IH);
 End;
 If (IBpc = 1) And (Not IJpeg) Then K := 6 Else K := 3;
 NX := IMin(K, IMax(1, (IW + TW_ - 1) Div TW_));
 NY := IMin(K, IMax(1, (IH + TH_ - 1) Div TH_));
 Pix := Nil; Alpha := Nil;
 If IMaskImg Then Begin
  GetMem(Alpha, TW_ * TH_);
 End
 Else GetMem(Pix, TW_ * TH_ * 2);
 For Y := 0 To TH_ - 1 Do Begin
  Y0 := (Y * IH) Div TH_;
  Y1 := IMax(Y0, ((Y + 1) * IH) Div TH_ - 1);
  For X := 0 To TW_ - 1 Do Begin
   X0 := (X * IW) Div TW_;
   X1 := IMax(X0, ((X + 1) * IW) Div TW_ - 1);
   SR := 0; SG := 0; SB := 0; Cnt := 0;
   For J := 0 To NY - 1 Do Begin
    SY := Y0 + ((Y1 - Y0 + 1) * J) Div NY;
    For I := 0 To NX - 1 Do Begin
     SX := X0 + ((X1 - X0 + 1) * I) Div NX;
     If IJpeg Then SampleJpeg(SX, SY, R, G, B) Else SampleRaw(SX, SY, R, G, B);
     SR := SR + R; SG := SG + G; SB := SB + B; Inc(Cnt);
    End;
   End;
   If IMaskImg Then Alpha^[Y * TW_ + X] := 255 - SG Div Cnt
   Else Begin
    R := SR Div Cnt; G := SG Div Cnt; B := SB Div Cnt;
    Pix^[Y * TW_ + X] := ((R And $F8) Shl 8) Or ((G And $FC) Shl 3) Or (B Shr 3);
   End;
  End;
 End;
End;

 

Function ImportImageObj(Num: Integer; AsSM: Boolean): Integer; Forward;
Function FinishImage(W, H, Bpc, CS, Comps, PalBase: LongInt; IsMask: Boolean; Const DecStr: String;
                     Raw: Pointer; RawLen: LongInt; Num: Integer; AsSM: Boolean; SMNum: Integer): Integer;
Var
 RowBytes, Exp, CurLen, OutLen, TW_, TH_: LongInt;
 Ok, Unsup, FinalDCT, FinalJPX, Keep, Owned: Boolean;
 JW, JH, JC, JOW, JOH, JCS: LongInt;
 JPix: PBigBytes;
 GBuf: PBigBytes;
 GLen: LongInt;
 GS_: TSrcState;
 K, Idx, M: Integer;
 Cur, Tmp, Pred: PBigBytes;
 Pix: PWordsBig;
 Alpha: PBigBytes;
 Nm: String;
 Ji: TJDImage;
 X, Y: LongInt;
 SW, SH: LongInt;
Begin
 FinishImage := 0;
 If (Bpc <> 1) And (Bpc <> 2) And (Bpc <> 4) And (Bpc <> 8) And (Bpc <> 16) Then Bpc := 8;
 { chaîne de filtres admise pour la réécriture ? }
 Keep := (CS In [1, 3, 4, 5]) Or IsMask;
 If (INF = 1) And (IFlt[0] = 'JPXDecode') Then Keep := True;
 For K := 0 To INF - 1 Do Begin
  Nm := IFlt[K];
  If Not ((Nm = 'FlateDecode') Or (Nm = 'DCTDecode') Or (Nm = 'ASCII85Decode') Or (Nm = 'ASCIIHexDecode') Or (Nm = 'JPXDecode')) Then Keep := False;
 End;
 Cur := PBigBytes(Raw); CurLen := RawLen; Owned := False;
 FinalDCT := False; FinalJPX := False; Unsup := False;
 Pred := Nil;
 For K := 0 To INF - 1 Do Begin
  Nm := IFlt[K];
  If (Nm = 'DCTDecode') Or (Nm = 'DCT') Then Begin FinalDCT := True; Break; End
  Else If Nm = 'JPXDecode' Then Begin FinalJPX := True; Break; End
  Else If Nm = 'JBIG2Decode' Then Begin
   RowBytes := (W + 7) Div 8;
   Exp := RowBytes * H;
   If (Exp > IMGMAXBYTES) Or (Exp < 1) Then Begin Unsup := True; Break; End;
   GetMem(Tmp, Exp + 64);
   GBuf := Nil; GLen := 0;
   If IJbGlob > 0 Then Begin
    SaveSrc(GS_);
    SrcMode := 0;
    GetMem(GBuf, BUFSZ + 16);
    If Not LoadStream(IJbGlob, PByteBuf(GBuf), GLen) Then GLen := 0;
    RestoreSrc(GS_);
   End;
   Ok := JBIG2Decode(Cur, CurLen, GBuf, GLen, W, H, Tmp);
   If GBuf <> Nil Then FreeMem(GBuf, BUFSZ + 16);
   If Owned Then FreeMem(Cur, CurLen + 64);
   If Not Ok Then Begin FreeMem(Tmp, Exp + 64); Cur := Nil; Owned := False; Unsup := True; Break; End;
   Cur := Tmp; CurLen := Exp; Owned := True;
   If CS = 0 Then Begin CS := 1; Comps := 1; End;
   Bpc := 1;
  End
  Else If (Nm = 'FlateDecode') Or (Nm = 'Fl') Then Begin
   If CS = 0 Then Exp := W * H * 4 + H Else Begin
    RowBytes := (W * Comps * Bpc + 7) Div 8;
    Exp := RowBytes * H;
    If IPred >= 10 Then Exp := Exp + H;
   End;
   If Exp > IMGMAXBYTES Then Begin Unsup := True; Break; End;
   GetMem(Tmp, Exp + 64);
   FillChar(Tmp^, Exp + 64, 0);
   DecCap := Exp + 64;
   Ok := FlateDec(PByteBuf(Cur), CurLen, PByteBuf(Tmp), OutLen);
   DecCap := BUFSZ;
   If Owned Then FreeMem(Cur, CurLen + 64);
   If (Not Ok) Or (OutLen < 1) Then Begin FreeMem(Tmp, Exp + 64); Cur := Nil; Owned := False; Unsup := True; Break; End;
   Cur := Tmp; CurLen := Exp; Owned := True;
   { la taille libérée plus tard : on garde CurLen = Exp (+64 à la libération) }
  End
  Else If (Nm = 'CCITTFaxDecode') Or (Nm = 'CCF') Then Begin
   RowBytes := (ICCCols + 7) Div 8;
   Exp := RowBytes * H;
   If (ICCCols <> W) Or (Exp > IMGMAXBYTES) Or (Exp < 1) Then Begin Unsup := True; Break; End;
   GetMem(Tmp, Exp + 64);
   CCITTDecode(PBigBytes(Cur), CurLen, ICCCols, H, IK, IBlackIs1, IByteAlign, Tmp);
   If Owned Then FreeMem(Cur, CurLen + 64);
   Cur := Tmp; CurLen := Exp; Owned := True;
   If CS = 0 Then Begin CS := 1; Comps := 1; End;
   Bpc := 1;
  End
  Else If (Nm = 'ASCII85Decode') Or (Nm = 'A85') Or (Nm = 'ASCIIHexDecode') Or (Nm = 'AHx') Then Begin
   GetMem(Tmp, CurLen + 64);
   DecCap := CurLen + 64;
   If (Nm = 'ASCII85Decode') Or (Nm = 'A85') Then A85Dec(PByteBuf(Cur), CurLen, PByteBuf(Tmp), OutLen)
   Else AHexDec(PByteBuf(Cur), CurLen, PByteBuf(Tmp), OutLen);
   DecCap := BUFSZ;
   If Owned Then FreeMem(Cur, CurLen + 64);
   Cur := Tmp; CurLen := OutLen; Owned := True;
   { rétablir une taille cohérente pour FreeMem : on réalloue exactement }
   If CurLen < 1 Then Begin Unsup := True; Break; End;
  End
  Else Begin Unsup := True; Break; End;
 End;
 TW_ := 0; TH_ := 0; Pix := Nil; Alpha := Nil;
 IJpeg := False; IRGB := Nil; IMaskImg := IsMask;
 If Not Unsup Then Begin
  If FinalDCT Then Begin
   FillChar(Ji, SizeOf(Ji), 0);
   If JDDecodeMem(Cur, CurLen, Ji) And (Ji.Pixels <> Nil) Then Begin
    IW := Ji.Width; IH := Ji.Height;
    IRGB := PBigBytes(Ji.Pixels);
    IJpeg := True;
    IMaskImg := False;
    Downsample(TW_, TH_, Pix, Alpha);
    FreeMem(Ji.Pixels, LongInt(Ji.Width) * Ji.Height * 3);
    IRGB := Nil;
   End
   Else Unsup := True;
  End
  Else If FinalJPX Then Begin
   If JPXDecode(Cur, CurLen, ImgMaxDim, JW, JH, JC, JOW, JOH, JCS, JPix) And (JPix <> Nil) Then Begin
    GetMem(IRGB, JW * JH * 3);
    For Y := 0 To JH - 1 Do
     For X := 0 To JW - 1 Do Begin
      If JC = 1 Then Begin
       IRGB^[(Y * JW + X) * 3] := JPix^[Y * JW + X]; IRGB^[(Y * JW + X) * 3 + 1] := JPix^[Y * JW + X]; IRGB^[(Y * JW + X) * 3 + 2] := JPix^[Y * JW + X];
      End
      Else If JC >= 4 Then Begin
       K := CmykPoly(JPix^[(Y * JW + X) * JC] / 255, JPix^[(Y * JW + X) * JC + 1] / 255, JPix^[(Y * JW + X) * JC + 2] / 255, JPix^[(Y * JW + X) * JC + 3] / 255);
       IRGB^[(Y * JW + X) * 3] := (K Shr 16) And 255; IRGB^[(Y * JW + X) * 3 + 1] := (K Shr 8) And 255; IRGB^[(Y * JW + X) * 3 + 2] := K And 255;
      End
      Else Begin
       IRGB^[(Y * JW + X) * 3] := JPix^[(Y * JW + X) * JC]; IRGB^[(Y * JW + X) * 3 + 1] := JPix^[(Y * JW + X) * JC + 1]; IRGB^[(Y * JW + X) * 3 + 2] := JPix^[(Y * JW + X) * JC + 2];
      End;
     End;
    IW := JW; IH := JH; IJpeg := True; IMaskImg := False;
    Downsample(TW_, TH_, Pix, Alpha);
    FreeMem(IRGB, JW * JH * 3);
    IRGB := Nil;
    FreeMem(JPix, JW * JH * JC);
   End
   Else Unsup := True;
  End
  Else Begin
   If CS = 0 Then Begin
    If Bpc = 8 Then Begin
     If IPred >= 10 Then Comps := (CurLen Div H - 1) Div W Else Comps := CurLen Div (W * H);
     If Comps = 1 Then CS := 1 Else If Comps = 3 Then CS := 3 Else If Comps = 4 Then CS := 4 Else CS := 0;
    End;
   End;
   If CS = 0 Then Unsup := True
   Else Begin
    RowBytes := (W * Comps * Bpc + 7) Div 8;
    If IPred >= 10 Then Begin
     Pred := Unpredict(Cur, CurLen, RowBytes, H, IMax(1, (Comps * Bpc) Div 8));
     IData := Pred;
    End
    Else Begin
     IData := Cur;
     If CurLen < RowBytes * H Then Unsup := True;
    End;
    If Not Unsup Then Begin
     IW := W; IH := H; IBpc := Bpc; ICS := CS; IComps := Comps; IRow := RowBytes; IPalBase := PalBase;
     If IsMask Then ICS := 1;
     If (CS = 5) And (IPalN < 1) Then Unsup := True
     Else Downsample(TW_, TH_, Pix, Alpha);
    End;
   End;
  End;
 End;
 If Owned And (Cur <> Nil) Then FreeMem(Cur, CurLen + 64);
 If Pred <> Nil Then FreeMem(Pred, RowBytes * H + 16);
 If Unsup Then Begin
  { affichage impossible : conserver seulement si la réécriture est possible }
  If Not Keep Then Begin FreeMem(Raw, RawLen + 16); Exit; End;
  TW_ := 0; TH_ := 0;
 End;
 { masque doux }
 If (SMNum > 0) And (Not AsSM) And (Pix <> Nil) Then Begin
  M := ImportImageObj(SMNum, True);
  If M > 0 Then If ImgP(M)^.Pix <> Nil Then Begin
   GetMem(Alpha, TW_ * TH_);
   SW := ImgP(M)^.W; SH := ImgP(M)^.H;
   For Y := 0 To TH_ - 1 Do
    For X := 0 To TW_ - 1 Do
     Alpha^[Y * TW_ + X] := ((PWordsBig(ImgP(M)^.Pix)^[((Y * SH) Div TH_) * SW + (X * SW) Div TW_] Shr 5) And 63) * 4;
  End;
 End
 Else If (SMNum > 0) And (Not AsSM) Then M := ImportImageObj(SMNum, True) Else M := 0;
 If ImgCount >= MAXIMG Then Begin
  If Pix <> Nil Then FreeMem(Pix, TW_ * TH_ * 2);
  If Alpha <> Nil Then FreeMem(Alpha, TW_ * TH_);
  FreeMem(Raw, RawLen + 16);
  Exit;
 End;
 If Not ImgEnsure(ImgCount + 1) Then Begin
  If Pix <> Nil Then FreeMem(Pix, TW_ * TH_ * 2);
  If Alpha <> Nil Then FreeMem(Alpha, TW_ * TH_);
  FreeMem(Raw, RawLen + 16);
  Exit;
 End;
 Inc(ImgCount);
 Idx := ImgCount;
 FillChar(ImgP(Idx)^, SizeOf(TImgRec), 0);
 ImgP(Idx)^.W := TW_; ImgP(Idx)^.H := TH_;
 ImgP(Idx)^.Pix := Pix; ImgP(Idx)^.Alpha := Alpha;
 ImgP(Idx)^.OW := W; ImgP(Idx)^.OH := H;
 If Keep Then Begin ImgP(Idx)^.Raw := Raw; ImgP(Idx)^.RawLen := RawLen; End
 Else FreeMem(Raw, RawLen + 16);
 ImgP(Idx)^.Keep := Keep;
 ImgP(Idx)^.CS := CS; ImgP(Idx)^.BPC := Bpc; ImgP(Idx)^.NF := INF;
 For K := 0 To INF - 1 Do ImgP(Idx)^.Flt[K] := IFlt[K];
 ImgP(Idx)^.Pred := IPred; ImgP(Idx)^.Cols := ICols; ImgP(Idx)^.Clr := IClr;
 ImgP(Idx)^.Mask := IsMask; ImgP(Idx)^.IsSM := AsSM;
 ImgP(Idx)^.SMIdx := M;
 ImgP(Idx)^.Decode := DecStr;
 If (CS = 5) And (IPalN > 0) Then Begin
  GetMem(ImgP(Idx)^.Pal, IPalN);
  Move(IPal[0], ImgP(Idx)^.Pal^, IPalN);
  ImgP(Idx)^.PalN := IPalN;
  ImgP(Idx)^.PalBase := PalBase;
 End;
 If Num > 0 Then ImgByObj^[Num] := Idx;
 IDescClear;
 FinishImage := Idx;
End;

Function ImportImageObj(Num: Integer; AsSM: Boolean): Integer;
Var
 S0: TSrcState;
 P, V: LongInt;
 W, H, Bpc, CS, Comps, PalBase: LongInt;
 IsMask, Ok: Boolean;
 Raw: Pointer;
 RawLen: LongInt;
 Dec: Array[0..7] Of Real;
 ND, K, SMNum: Integer;
 DecStr, Nm: String;
Begin
 ImportImageObj := 0;
 If (Num < 1) Or (Num > MAXPDFOBJ) Then Exit;
 If ImgByObj^[Num] <> 0 Then Begin
  If ImgByObj^[Num] <> 65535 Then ImportImageObj := ImgByObj^[Num];
  Exit;
 End;
 If ImgCount >= MAXIMG Then Exit;
 ImgByObj^[Num] := 65535;
 SaveSrc(S0);
 SrcMode := 0;
 P := EnterObj(Num);
 If (P < 0) Or (SrcMode <> 0) Then Begin RestoreSrc(S0); Exit; End;
 W := ValInt(DictFind(P, 'Width'), 0);
 H := ValInt(DictFind(P, 'Height'), 0);
 If (W < 1) Or (H < 1) Or (W > 30000) Or (H > 30000) Or (W * H > 150000000) Then Begin RestoreSrc(S0); Exit; End;
 IsMask := False;
 V := DictFind(P, 'ImageMask');
 If V >= 0 Then If NextTok(V) = T_OP Then IsMask := TokS = 'true';
 Bpc := ValInt(DictFind(P, 'BitsPerComponent'), 8);
 If IsMask Then Bpc := 1;
 CS := 0; Comps := 0; PalBase := 0; IPalN := 0;
 If IsMask Then Begin CS := 1; Comps := 1; End
 Else If Not ParseCS(DictFind(P, 'ColorSpace'), 0, CS, Comps, PalBase) Then CS := 0;
 SrcMode := 0;
 P := EnterObj(Num);
 ND := ReadNums(DictFind(P, 'Decode'), Dec, 8);
 DecStr := '';
 For K := 0 To ND - 1 Do Begin
  If K > 0 Then DecStr := DecStr + ' ';
  DecStr := DecStr + RStr(Dec[K]);
 End;
 IInv := (ND >= 2) And (Dec[0] > Dec[1]);
 ReadFiltersAndParms(P);
 SMNum := 0;
 V := DictFind(P, 'SMask');
 If V >= 0 Then SMNum := RefAt(V);
 Ok := ReadRawStream(P, Raw, RawLen);
 RestoreSrc(S0);
 If Not Ok Then Exit;
 ImportImageObj := FinishImage(W, H, Bpc, CS, Comps, PalBase, IsMask, DecStr, Raw, RawLen, Num, AsSM, SMNum);
End;

{ Nom de filtre complet à partir de l'abréviation des images en ligne }
Function FullFilter(Const N: String): String;
Begin
 If N = 'Fl' Then FullFilter := 'FlateDecode'
 Else If N = 'DCT' Then FullFilter := 'DCTDecode'
 Else If N = 'A85' Then FullFilter := 'ASCII85Decode'
 Else If N = 'AHx' Then FullFilter := 'ASCIIHexDecode'
 Else If N = 'LZW' Then FullFilter := 'LZWDecode'
 Else If N = 'RL' Then FullFilter := 'RunLengthDecode'
 Else If N = 'CCF' Then FullFilter := 'CCITTFaxDecode'
 Else FullFilter := N;
End;

{ Image en ligne : P est situé juste après BI, retourne l'indice d'image (0 si échec).
  À la sortie P est placé après EI. }
Function InlineImage(Var P: LongInt): Integer;
Var
 T, K, I: Integer;
 Q, VP, WP, HP, BP, CP, FP, DPP, IMP, DCP, DS, DL, Pos0, Cnt: LongInt;
 Key: String;
 W, H, Bpc, CS, Comps, PalBase, RowBytes, Len, Start, Ei: LongInt;
 IsMask, Found: Boolean;
 Raw: PBigBytes;
 Dec: Array[0..7] Of Real;
 ND: Integer;
 DecStr: String;
 C: Integer;
Begin
 InlineImage := 0;
 WP := -1; HP := -1; BP := -1; CP := -1; FP := -1; DPP := -1; IMP := -1; DCP := -1;
 Found := False;
 While True Do Begin
  T := NextTok(P);
  If T = T_EOF Then Exit;
  If (T = T_OP) And (TokS = 'ID') Then Begin Found := True; Break; End;
  If T = T_NAME Then Begin
   Key := TokS;
   VP := P;
   SkipValue(P);
   If (Key = 'W') Or (Key = 'Width') Then WP := VP
   Else If (Key = 'H') Or (Key = 'Height') Then HP := VP
   Else If (Key = 'BPC') Or (Key = 'BitsPerComponent') Then BP := VP
   Else If (Key = 'CS') Or (Key = 'ColorSpace') Then CP := VP
   Else If (Key = 'F') Or (Key = 'Filter') Then FP := VP
   Else If (Key = 'DP') Or (Key = 'DecodeParms') Then DPP := VP
   Else If (Key = 'IM') Or (Key = 'ImageMask') Then IMP := VP
   Else If (Key = 'D') Or (Key = 'Decode') Then DCP := VP;
  End;
 End;
 If Not Found Then Exit;
 { la donnée commence après un seul blanc }
 Start := P + 1;
 If (SB(P) = 13) And (SB(P + 1) = 10) Then Start := P + 2;
 W := 0; H := 0;
 If WP >= 0 Then W := ValInt(WP, 0);
 If HP >= 0 Then H := ValInt(HP, 0);
 IsMask := False;
 If IMP >= 0 Then Begin Q := IMP; If NextTok(Q) = T_OP Then IsMask := TokS = 'true'; End;
 Bpc := 8;
 If BP >= 0 Then Bpc := ValInt(BP, 8);
 If IsMask Then Bpc := 1;
 INF := 0; IPred := 1; ICols := 1; IClr := 1;
 IK := 0; ICCCols := 1728; IBlackIs1 := False; IByteAlign := False; IJbGlob := 0;
 If FP >= 0 Then Begin
  Q := FP;
  T := NextTok(Q);
  If T = T_NAME Then Begin IFlt[0] := FullFilter(TokS); INF := 1; End
  Else If T = T_AB Then
   While INF < 4 Do Begin
    T := NextTok(Q);
    If T = T_NAME Then Begin IFlt[INF] := FullFilter(TokS); Inc(INF); End Else Break;
   End;
 End;
 If DPP >= 0 Then Begin
  Q := DPP;
  Pos0 := Q;
  T := NextTok(Q);
  If T = T_AB Then Begin
   While True Do Begin
    Pos0 := Q;
    T := NextTok(Q);
    If (T = T_DB) Or (T = T_AE) Or (T = T_EOF) Then Break;
   End;
  End;
  If T = T_DB Then Begin
   IPred := ValInt(DictFind(Pos0, 'Predictor'), 1);
   ICols := ValInt(DictFind(Pos0, 'Columns'), 1);
   IClr := ValInt(DictFind(Pos0, 'Colors'), 1);
   IK := ValInt(DictFind(Pos0, 'K'), 0);
   ICCCols := ValInt(DictFind(Pos0, 'Columns'), 1728);
   Q := DictFind(Pos0, 'BlackIs1');
   If Q >= 0 Then If NextTok(Q) = T_OP Then IBlackIs1 := TokS = 'true';
   Q := DictFind(Pos0, 'EncodedByteAlign');
   If Q >= 0 Then If NextTok(Q) = T_OP Then IByteAlign := TokS = 'true';
  End;
 End;
 { fin des données }
 Len := -1;
 If (INF = 0) And (W > 0) And (H > 0) Then Begin
  If IsMask Then RowBytes := (W + 7) Div 8
  Else Begin
   CS := 0; Comps := 0; PalBase := 0; IPalN := 0;
   If CP >= 0 Then If Not ParseCS(CP, 0, CS, Comps, PalBase) Then If Not ParseCSRes(CP, CS, Comps, PalBase) Then CS := 0;
   If CS = 0 Then RowBytes := 0 Else RowBytes := (W * Comps * Bpc + 7) Div 8;
  End;
  If (RowBytes > 0) And (RowBytes * H < IMGMAXBYTES) Then Begin
   Len := RowBytes * H;
   Ei := Start + Len;
   { vérifier qu'EI suit }
   Q := Ei;
   While IsWs(SB(Q)) Do Inc(Q);
   If Not ((SB(Q) = 69) And (SB(Q + 1) = 73)) Then Len := -1
   Else Begin P := Q + 2; End;
  End;
 End;
 If Len < 0 Then Begin
  Q := Start;
  Len := -1;
  While True Do Begin
   C := SB(Q);
   If C = -1 Then Break;
   If (C = 69) And (SB(Q + 1) = 73) And IsWs(SB(Q - 1)) And (IsWs(SB(Q + 2)) Or (SB(Q + 2) = -1)) Then Begin
    { les octets qui suivent doivent ressembler à du texte }
    Cnt := 0;
    K := 3;
    While K < 12 Do Begin
     I := SB(Q + K);
     If I = -1 Then Break;
     If (I > 127) Or ((I < 32) And Not IsWs(I)) Then Inc(Cnt);
     Inc(K);
    End;
    If Cnt = 0 Then Begin Len := Q - 1 - Start; P := Q + 2; Break; End;
   End;
   Inc(Q);
  End;
  If Len < 0 Then Begin P := Q; Exit; End;
 End;
 If (W < 1) Or (H < 1) Or (W > 30000) Or (H > 30000) Or (W * H > 150000000) Then Exit;
 If (Len < 1) Or (Len > IMGMAXBYTES) Then Exit;
 CS := 0; Comps := 0; PalBase := 0; IPalN := 0;
 If IsMask Then Begin CS := 1; Comps := 1; End
 Else If CP >= 0 Then Begin
  If Not ParseCS(CP, 0, CS, Comps, PalBase) Then If Not ParseCSRes(CP, CS, Comps, PalBase) Then CS := 0;
 End;
 ND := 0;
 If DCP >= 0 Then ND := ReadNums(DCP, Dec, 8);
 DecStr := '';
 For K := 0 To ND - 1 Do Begin
  If K > 0 Then DecStr := DecStr + ' ';
  DecStr := DecStr + RStr(Dec[K]);
 End;
 IInv := (ND >= 2) And (Dec[0] > Dec[1]);
 GetMem(Raw, Len + 16);
 For K := 0 To Len - 1 Do Raw^[K] := SB(Start + K);
 InlineImage := FinishImage(W, H, Bpc, CS, Comps, PalBase, IsMask, DecStr, Raw, Len, 0, False, 0);
End;

{$ELSE}
Procedure FreeImages;
Begin
End;

Function ImportImageObj(Num: Integer; AsSM: Boolean): Integer;
Begin
 ImportImageObj := 0;
End;
Function InlineImage(Var P: LongInt): Integer;
Begin
 InlineImage := 0;
End;
{$ENDIF}

{ ---------------------------------------------------------------------- }
{ Import PDF : interprétation des flux de contenu                           }
{ ---------------------------------------------------------------------- }

Const
 GSMAX = 28;
 SUBMAX = 400;
 {$IFDEF FPC}
 PATHMAX = 4000;
 {$ELSE}
 PATHMAX = 300;
 {$ENDIF}

Type
 TMat = Array[0..5] Of Real;
 TGS = Record
  CTM: TMat;
  Stroke, Fill: LongInt;
  LW: Real;
  Tc, Tw, Th, TL, Ts, TSize: Real;
  TFont, TMode: Integer;
  ClipOn: Boolean;
  CX1, CY1, CX2, CY2: LongInt;
  ClipPoly: Integer;        { 0 : aucun, sinon indice + 1 d'un polygone de découpe }
  FillA, StrokeA: Real;
  Blend: Integer;           { 0 normal, 1 produit (Multiply) }
  OverP: Boolean;           { surimpression du remplissage (OP / op) }
  CSPat: Boolean;           { espace colorimétrique de remplissage : Pattern }
  FillPat: LongInt;         { n° d'objet du motif de remplissage (0 : aucun) }
  FillCS, StrokeCS: Integer; { espace colorimétrique courant : indice dans CSCache + 1 (0 : appareil) }
 End;

Const
 {$IFDEF FPC}
 CPMAX = 200;
 CPPTS = 96;
 CLIPBUF = 3300;
 {$ELSE}
 CPMAX = 8;
 CPPTS = 24;
 CLIPBUF = 400;
 {$ENDIF}

Var
 GDepth: Integer;
 CPX, CPY: Array[0..CPMAX - 1, 0..CPPTS - 1] Of LongInt;
 CPN: Array[0..CPMAX - 1] Of Integer;
 NCP: Integer;
 TpX, TpY, CcX, CcY: Array[0..CLIPBUF - 1] Of LongInt;
 ClipPend: Boolean;
 GS: TGS;
 GStack: Array[0..GSMAX-1] Of TGS;
 GSP: Integer;
 TmM, TlmM: TMat;
 PathX, PathY: Array[0..PATHMAX-1] Of Real;
 NPts, NSub: Integer;
 SubStart: Array[0..SUBMAX-1] Of Integer;
 SubClosed, SubRect: Array[0..SUBMAX-1] Of Boolean;
 Opnd: Array[0..39] Of Real;
 NOpnd: Integer;
 LastName, LastStr, PrevName: String;
 MCSt: Array[0..63] Of Word;
 MCSP, MCOver: Integer;
 CurLayer: Word;
 ImpPg: Integer;
 ImpSrcKind: Integer;
 ImpAnnNum: LongInt;
 ImpKeepSrc: Boolean;
 MbX0, MbY1: Real;
 ImpFull: Boolean;
 CLens: Array[0..3] Of LongInt;
 SkippedText: Integer;
 KidStack: Array[0..65535] Of Word;
 KidSP: Integer;

Procedure MatMul(Const A, B: TMat; Var R: TMat);
Var
 T: TMat;
Begin
 T[0] := A[0] * B[0] + A[1] * B[2];
 T[1] := A[0] * B[1] + A[1] * B[3];
 T[2] := A[2] * B[0] + A[3] * B[2];
 T[3] := A[2] * B[1] + A[3] * B[3];
 T[4] := A[4] * B[0] + A[5] * B[2] + B[4];
 T[5] := A[4] * B[1] + A[5] * B[3] + B[5];
 R := T;
End;

Procedure MatIdent(Var M: TMat);
Begin
 M[0] := 1; M[1] := 0; M[2] := 0; M[3] := 1; M[4] := 0; M[5] := 0;
End;

Function RI(R: Real): LongInt;
Begin
 If R > 1000000.0 Then R := 1000000.0;
 If R < -1000000.0 Then R := -1000000.0;
 RI := Round(R);
End;

Function PgX(X: Real): LongInt;
Begin
 PgX := C16(RI(X - MbX0));
End;

Function PgY(Y: Real): LongInt;
Begin
 PgY := C16(RI(MbY1 - Y));
End;

Function GrayRgb(G: Real): LongInt;
Begin
 GrayRgb := RGBOf(RI(G * 255), RI(G * 255), RI(G * 255));
End;

Function CmykRgb(C, M, Y, K: Real): LongInt;
Begin
 {$IFDEF FPC}
 CmykRgb := CmykPoly(C, M, Y, K);
 {$ELSE}
 CmykRgb := RGBOf(RI(255 * (1 - C) * (1 - K)), RI(255 * (1 - M) * (1 - K)), RI(255 * (1 - Y) * (1 - K)));
 {$ENDIF}
End;

Var
 AnnSet: PByteBuf;
 AnnSetCap: LongInt;

{ Ensemble des numéros d'annotations d'origine importées dans le modèle }
Procedure AnnSetMark(N: LongInt);
Var
 P: Pointer;
 NewCap: LongInt;
Begin
 If N + 1 > AnnSetCap Then Begin
  NewCap := AnnSetCap * 2;
  If NewCap < N + 1024 Then NewCap := N + 1024;
  P := AnnSet; ReAllocMem(P, NewCap); AnnSet := P;
  FillChar(AnnSet^[AnnSetCap], NewCap - AnnSetCap, 0);
  AnnSetCap := NewCap;
 End;
 AnnSet^[N] := 1;
End;

Function AnnSetHas(N: LongInt): Boolean;
Begin
 AnnSetHas := (N >= 0) And (N < AnnSetCap) And (AnnSet^[N] <> 0);
End;

Function NewImpObj(Kind: Integer): Integer;
Var
 I: Integer;
Begin
 I := NewObj(Kind, ImpPg);
 If I < 0 Then Begin
  ImpFull := True;
  LoadNotice := 'Document tronqué : mémoire insuffisante.';
 End
 Else Begin
  If ImpKeepSrc Then ObjP(I)^.Src := ImpSrcKind Else ObjP(I)^.Src := 0;
  ObjP(I)^.SrcNum := ImpAnnNum;
  ObjP(I)^.Layer := CurLayer;
 End;
 NewImpObj := I;
End;

Procedure PushGS;
Begin
 If GSP < GSMAX Then Begin
  GStack[GSP] := GS;
  Inc(GSP);
 End;
End;

Procedure PopGS;
Begin
 If GSP > 0 Then Begin
  Dec(GSP);
  GS := GStack[GSP];
 End;
End;

Procedure AddPt(X, Y: Real);
Begin
 If NPts >= PATHMAX Then Exit;
 PathX[NPts] := GS.CTM[0] * X + GS.CTM[2] * Y + GS.CTM[4];
 PathY[NPts] := GS.CTM[1] * X + GS.CTM[3] * Y + GS.CTM[5];
 Inc(NPts);
End;

Procedure NewSub;
Begin
 If NSub >= SUBMAX Then Exit;
 SubStart[NSub] := NPts;
 SubClosed[NSub] := False;
 SubRect[NSub] := False;
 Inc(NSub);
End;

Procedure CurveTo(X1, Y1, X2, Y2, X3, Y3: Real);
Var
 SX, SY, AX, AY, BX, BY, CX, CY, T, U: Real;
 I: Integer;
 P1X, P1Y, P2X, P2Y, P3X, P3Y: Real;
Begin
 If NPts = 0 Then Exit;
 SX := PathX[NPts - 1]; SY := PathY[NPts - 1];
 P1X := GS.CTM[0] * X1 + GS.CTM[2] * Y1 + GS.CTM[4]; P1Y := GS.CTM[1] * X1 + GS.CTM[3] * Y1 + GS.CTM[5];
 P2X := GS.CTM[0] * X2 + GS.CTM[2] * Y2 + GS.CTM[4]; P2Y := GS.CTM[1] * X2 + GS.CTM[3] * Y2 + GS.CTM[5];
 P3X := GS.CTM[0] * X3 + GS.CTM[2] * Y3 + GS.CTM[4]; P3Y := GS.CTM[1] * X3 + GS.CTM[3] * Y3 + GS.CTM[5];
 For I := 1 To 10 Do Begin
  T := I / 10; U := 1 - T;
  AX := U * U * U * SX + 3 * U * U * T * P1X + 3 * U * T * T * P2X + T * T * T * P3X;
  AY := U * U * U * SY + 3 * U * U * T * P1Y + 3 * U * T * T * P2Y + T * T * T * P3Y;
  If NPts < PATHMAX Then Begin PathX[NPts] := AX; PathY[NPts] := AY; Inc(NPts); End;
 End;
End;

Function StrokeW: Integer;
Var
 Det: Real;
 W: LongInt;
Begin
 Det := Abs(GS.CTM[0] * GS.CTM[3] - GS.CTM[1] * GS.CTM[2]);
 W := RI(GS.LW * Sqrt(Det));
 If W < 1 Then W := 1;
 If W > 40 Then W := 40;
 StrokeW := W;
End;

{ ---------------------------------------------------------------------- }
{ Découpe rectangulaire, dégradés, motifs                                  }
{ ---------------------------------------------------------------------- }

Procedure ClipToBox(A, B, C, D: LongInt);
Begin
 If Not GS.ClipOn Then Begin
  GS.ClipOn := True;
  GS.CX1 := A; GS.CY1 := B; GS.CX2 := C; GS.CY2 := D;
 End
 Else Begin
  If A > GS.CX1 Then GS.CX1 := A;
  If B > GS.CY1 Then GS.CY1 := B;
  If C < GS.CX2 Then GS.CX2 := C;
  If D < GS.CY2 Then GS.CY2 := D;
 End;
End;

Function OutsideClip(X1, Y1, X2, Y2: LongInt): Boolean;
Begin
 OutsideClip := GS.ClipOn And ((GS.CX2 < GS.CX1) Or (GS.CY2 < GS.CY1) Or
                (X2 < GS.CX1) Or (X1 > GS.CX2) Or (Y2 < GS.CY1) Or (Y1 > GS.CY2));
End;

Function InsideClip(X1, Y1, X2, Y2: LongInt): Boolean;
Begin
 InsideClip := (Not GS.ClipOn) Or ((X1 >= GS.CX1) And (X2 <= GS.CX2) And (Y1 >= GS.CY1) And (Y2 <= GS.CY2));
End;

Procedure ClampBox(Var X1, Y1, X2, Y2: LongInt);
Begin
 If Not GS.ClipOn Then Exit;
 If X1 < GS.CX1 Then X1 := GS.CX1;
 If Y1 < GS.CY1 Then Y1 := GS.CY1;
 If X2 > GS.CX2 Then X2 := GS.CX2;
 If Y2 > GS.CY2 Then Y2 := GS.CY2;
End;

{ Découpe du segment par la boîte de découpe (Liang-Barsky) }
Function ClipLineBox(Var X1, Y1, X2, Y2: LongInt): Boolean;
Var
 T0, T1, Dx, Dy: Real;
 Ax, Ay: LongInt;
 Function Edge(P, Q: Real): Boolean;
 Var
  R: Real;
 Begin
  Edge := True;
  If P = 0 Then Begin Edge := Q >= 0; Exit; End;
  R := Q / P;
  If P < 0 Then Begin
   If R > T1 Then Begin Edge := False; Exit; End;
   If R > T0 Then T0 := R;
  End
  Else Begin
   If R < T0 Then Begin Edge := False; Exit; End;
   If R < T1 Then T1 := R;
  End;
 End;
Begin
 ClipLineBox := True;
 If Not GS.ClipOn Then Exit;
 T0 := 0; T1 := 1;
 Dx := X2 - X1; Dy := Y2 - Y1;
 If Not (Edge(-Dx, X1 - GS.CX1) And Edge(Dx, GS.CX2 - X1) And Edge(-Dy, Y1 - GS.CY1) And Edge(Dy, GS.CY2 - Y1)) Then Begin
  ClipLineBox := False;
  Exit;
 End;
 Ax := X1; Ay := Y1;
 X1 := Ax + Round(T0 * Dx); Y1 := Ay + Round(T0 * Dy);
 X2 := Ax + Round(T1 * Dx); Y2 := Ay + Round(T1 * Dy);
End;

{ Découpe le polygone TpX/TpY (N points) par un rectangle (Sutherland-Hodgman) }
Function ClipPolyBox(N: Integer; B1, B2, B3, B4: LongInt): Integer;
 Function CpInside(Side: Integer; X, Y: LongInt): Boolean;
 Begin
  Case Side Of
   0: CpInside := X >= B1;
   1: CpInside := X <= B3;
   2: CpInside := Y >= B2;
  Else CpInside := Y <= B4;
  End;
 End;
 Procedure Cross(Side: Integer; Ax, Ay, Bx, By: LongInt; Var Rx, Ry: LongInt);
 Var
  T: Real;
 Begin
  Case Side Of
   0: Begin Rx := B1; If Bx = Ax Then Ry := Ay Else Ry := Ay + Round((B1 - Ax) * (By - Ay) / (Bx - Ax)); End;
   1: Begin Rx := B3; If Bx = Ax Then Ry := Ay Else Ry := Ay + Round((B3 - Ax) * (By - Ay) / (Bx - Ax)); End;
   2: Begin Ry := B2; If By = Ay Then Rx := Ax Else Rx := Ax + Round((B2 - Ay) * (Bx - Ax) / (By - Ay)); End;
  Else Begin Ry := B4; If By = Ay Then Rx := Ax Else Rx := Ax + Round((B4 - Ay) * (Bx - Ax) / (By - Ay)); End;
  End;
 End;
Var
 Side, I, M, Pv: Integer;
 Ax, Ay, Bx, By, Rx, Ry: LongInt;
 InA, InB: Boolean;
Begin
 For Side := 0 To 3 Do Begin
  If N < 1 Then Break;
  M := 0;
  For I := 0 To N - 1 Do Begin
   Pv := I - 1; If Pv < 0 Then Pv := N - 1;
   Ax := TpX[Pv]; Ay := TpY[Pv]; Bx := TpX[I]; By := TpY[I];
   InA := CpInside(Side, Ax, Ay); InB := CpInside(Side, Bx, By);
   If InB Then Begin
    If (Not InA) And (M < CLIPBUF - 2) Then Begin
     Cross(Side, Ax, Ay, Bx, By, Rx, Ry);
     CcX[M] := Rx; CcY[M] := Ry; Inc(M);
    End;
    If M < CLIPBUF - 1 Then Begin CcX[M] := Bx; CcY[M] := By; Inc(M); End;
   End
   Else If InA And (M < CLIPBUF - 1) Then Begin
    Cross(Side, Ax, Ay, Bx, By, Rx, Ry);
    CcX[M] := Rx; CcY[M] := Ry; Inc(M);
   End;
  End;
  For I := 0 To M - 1 Do Begin TpX[I] := CcX[I]; TpY[I] := CcY[I]; End;
  N := M;
 End;
 ClipPolyBox := N;
End;

Type
 TGAbs = Record
  Typ: Integer;
  X0, Y0, X1, Y1, R0, R1: Real;
  NSt: Integer;
  Pos: Array[0..8] Of Integer;
  R, G, B: Array[0..8] Of Integer;
 End;

Var
 GA: TGAbs;

{ Dégradé (types 2 et 3) : coordonnées converties dans l'espace page par la matrice M }
Function ShadingToAbs(ShPos: LongInt; Const M: TMat): Boolean;
Var
 S: TSrcState;
 ShT, K, NO, NC, I: Integer;
 Co: Array[0..5] Of Real;
 Dm: Array[0..1] Of Real;
 Out: Array[0..7] Of Real;
 FnPos, Vp: LongInt;
 HaveD: Boolean;
 ShD: TCSDesc;
 T, Sc: Real;
 R, G, B: LongInt;
 Rgb: LongInt;
 Function Cl(V: Real): LongInt;
 Begin
  If V < 0 Then V := 0;
  If V > 1 Then V := 1;
  Cl := Round(V * 255);
 End;
 Function MX(X, Y: Real): Real;
 Begin
  MX := PgX(M[0] * X + M[2] * Y + M[4]);
 End;
 Function MY(X, Y: Real): Real;
 Begin
  MY := PgY(M[1] * X + M[3] * Y + M[5]);
 End;
Begin
 ShadingToAbs := False;
 If ShPos < 0 Then Exit;
 SaveSrc(S);
 ShT := ValInt(DictFind(ShPos, 'ShadingType'), 0);
 If (ShT <> 2) And (ShT <> 3) Then Begin RestoreSrc(S); Exit; End;
 NC := ReadNums(DictFind(ShPos, 'Coords'), Co, 6);
 If ((ShT = 2) And (NC < 4)) Or ((ShT = 3) And (NC < 6)) Then Begin RestoreSrc(S); Exit; End;
 Dm[0] := 0; Dm[1] := 1;
 ReadNums(DictFind(ShPos, 'Domain'), Dm, 2);
 FnPos := DictFind(ShPos, 'Function');
 If FnPos < 0 Then Begin RestoreSrc(S); Exit; End;
 HaveD := ParseCSDesc(DictFind(ShPos, 'ColorSpace'), 0, ShD);
 RestoreSrc(S);
 GA.Typ := ShT - 2;
 If ShT = 2 Then Begin
  GA.X0 := MX(Co[0], Co[1]); GA.Y0 := MY(Co[0], Co[1]);
  GA.X1 := MX(Co[2], Co[3]); GA.Y1 := MY(Co[2], Co[3]);
  GA.R0 := 0; GA.R1 := 0;
 End
 Else Begin
  Sc := Sqrt(Abs(M[0] * M[3] - M[1] * M[2]));
  GA.X0 := MX(Co[0], Co[1]); GA.Y0 := MY(Co[0], Co[1]); GA.R0 := Co[2] * Sc;
  GA.X1 := MX(Co[3], Co[4]); GA.Y1 := MY(Co[3], Co[4]); GA.R1 := Co[5] * Sc;
 End;
 GA.NSt := 0;
 For K := 0 To 8 Do Begin
  T := Dm[0] + (Dm[1] - Dm[0]) * K / 8;
  NO := EvalFn(FnPos, T, Out, 0);
  If NO < 1 Then Begin CSDescFree(ShD); Exit; End;
  If HaveD And (ShD.Kind In [1, 3, 4, 6, 7]) Then Rgb := ColorToRgb(ShD, Out, NO)
  Else If NO = 1 Then Rgb := RGBOf(Cl(1 - Out[0]), Cl(1 - Out[0]), Cl(1 - Out[0]))
  Else If NO = 3 Then Rgb := RGBOf(Cl(Out[0]), Cl(Out[1]), Cl(Out[2]))
  Else If NO >= 4 Then Rgb := CompToRgb(4, Out, ShD)
  Else Begin CSDescFree(ShD); Exit; End;
  R := (Rgb Shr 16) And 255; G := (Rgb Shr 8) And 255; B := Rgb And 255;
  GA.Pos[K] := K * 255 Div 8;
  GA.R[K] := R; GA.G[K] := G; GA.B[K] := B;
  Inc(GA.NSt);
 End;
 CSDescFree(ShD);
 ShadingToAbs := True;
End;

Function GradTxt(BX1, BY1, BX2, BY2: LongInt): String;
Var
 W, H, Mx: Real;
 S: String;
 K: Integer;
Begin
 W := BX2 - BX1; If W < 1 Then W := 1;
 H := BY2 - BY1; If H < 1 Then H := 1;
 If W > H Then Mx := W Else Mx := H;
 S := Chr(GA.Typ) + GdPutInt16(Round((GA.X0 - BX1) / W * 1024)) + GdPutInt16(Round((GA.Y0 - BY1) / H * 1024)) +
      GdPutInt16(Round((GA.X1 - BX1) / W * 1024)) + GdPutInt16(Round((GA.Y1 - BY1) / H * 1024)) +
      GdPutInt16(Round(GA.R0 / Mx * 1024)) + GdPutInt16(Round(GA.R1 / Mx * 1024)) + Chr(GA.NSt);
 For K := 0 To GA.NSt - 1 Do
  S := S + Chr(GA.Pos[K]) + Chr(GA.R[K]) + Chr(GA.G[K]) + Chr(GA.B[K]);
 GradTxt := S;
End;

{ Crée un objet dégradé : polygone TpX/TpY de N points, ou boîte (N = 0) }
Procedure EmitGradient(N: Integer; BX1, BY1, BX2, BY2: LongInt);
Var
 I, Idx, Pool, Step: Integer;
 MnX, MnY, MxX, MxY: LongInt;
Begin
 If ImpFull Then Exit;
 If N >= 3 Then Begin
  Step := 1;
  If N > 1500 Then Begin
   Step := (N + 1499) Div 1500;
   For I := 0 To N Div Step - 1 Do Begin TpX[I] := TpX[I * Step]; TpY[I] := TpY[I * Step]; End;
   N := N Div Step;
  End;
  MnX := TpX[0]; MxX := MnX; MnY := TpY[0]; MxY := MnY;
  For I := 1 To N - 1 Do Begin
   If TpX[I] < MnX Then MnX := TpX[I];
   If TpX[I] > MxX Then MxX := TpX[I];
   If TpY[I] < MnY Then MnY := TpY[I];
   If TpY[I] > MxY Then MxY := TpY[I];
  End;
  If OutsideClip(MnX, MnY, MxX, MxY) Then Exit;
  Pool := PoolAlloc(N);
  If Pool < 0 Then Begin ImpFull := True; LoadNotice := 'Document tronqué : mémoire des tracés pleine.'; Exit; End;
  Idx := NewImpObj(K_GRAD);
  If Idx < 0 Then Exit;
  For I := 0 To N - 1 Do Begin
   PoolXP(Pool + I)^ := TpX[I];
   PoolYP(Pool + I)^ := TpY[I];
  End;
  With ObjP(Idx)^ Do Begin
   P0 := Pool; PN := N;
   X1 := MnX; Y1 := MnY; X2 := MxX; Y2 := MxY;
   Txt := GradTxt(MnX, MnY, MxX, MxY);
   Rgb := RGBOf(GA.R[0], GA.G[0], GA.B[0]);
   Rgb2 := RGBOf(GA.R[GA.NSt - 1], GA.G[GA.NSt - 1], GA.B[GA.NSt - 1]);
  End;
 End
 Else Begin
  If OutsideClip(BX1, BY1, BX2, BY2) Then Exit;
  ClampBox(BX1, BY1, BX2, BY2);
  If (BX2 < BX1) Or (BY2 < BY1) Then Exit;
  Idx := NewImpObj(K_GRAD);
  If Idx < 0 Then Exit;
  With ObjP(Idx)^ Do Begin
   X1 := BX1; Y1 := BY1; X2 := BX2; Y2 := BY2;
   Txt := GradTxt(BX1, BY1, BX2, BY2);
   Rgb := RGBOf(GA.R[0], GA.G[0], GA.B[0]);
   Rgb2 := RGBOf(GA.R[GA.NSt - 1], GA.G[GA.NSt - 1], GA.B[GA.NSt - 1]);
  End;
 End;
End;

Procedure PaintTiling(Num: LongInt; BX1, BY1, BX2, BY2: LongInt); Forward;

{ Remplit avec le motif courant : polygone TpX/TpY (N points) ou boîte (N = 0) }
Procedure PatternFill(N: Integer; BX1, BY1, BX2, BY2: LongInt);
Var
 S: TSrcState;
 P, V: LongInt;
 PT, I, ShNum: Integer;
 Mat: TMat;
 Arr: Array[0..5] Of Real;
 Ok: Boolean;
Begin
 SaveSrc(S);
 SrcMode := 0;
 P := EnterObj(GS.FillPat);
 If P < 0 Then Begin RestoreSrc(S); Exit; End;
 PT := ValInt(DictFind(P, 'PatternType'), 0);
 If PT = 2 Then Begin
  MatIdent(Mat);
  V := DictFind(P, 'Matrix');
  If V >= 0 Then If ReadNums(V, Arr, 6) = 6 Then
   For I := 0 To 5 Do Mat[I] := Arr[I];
  Ok := False;
  V := DictFind(P, 'Shading');
  If V >= 0 Then Begin
   ShNum := RefAt(V);
   If ShNum > 0 Then V := EnterObj(ShNum);
   If V >= 0 Then Ok := ShadingToAbs(V, Mat);
  End;
  RestoreSrc(S);
  If Ok Then EmitGradient(N, BX1, BY1, BX2, BY2);
 End
 Else Begin
  RestoreSrc(S);
  If PT = 1 Then PaintTiling(GS.FillPat, BX1, BY1, BX2, BY2);
 End;
End;

Function AlphaByte(A: Real): Integer;
Var
 V: Integer;
Begin
 V := Round(A * 255);
 If V < 1 Then V := 1;
 If V > 254 Then V := 0;
 AlphaByte := V;
End;

Procedure EmitPath(DoFill, DoStroke, Close: Boolean);
Var
 K, S, E, N, I, Idx, Pool, Step: Integer;
 MnX, MnY, MxX, MxY: Real;
 IsRect, Closed, Fl, PatFill: Boolean;
 Tol: Real;
 BA, BB, BC, BD, LX1, LY1, LX2, LY2: LongInt;
 RK: Integer;
Begin
 For K := 0 To NSub - 1 Do Begin
  If ImpFull Then Break;
  S := SubStart[K];
  If K < NSub - 1 Then E := SubStart[K + 1] - 1 Else E := NPts - 1;
  N := E - S + 1;
  If N < 2 Then Continue;
  Closed := SubClosed[K] Or Close;
  MnX := PathX[S]; MxX := MnX; MnY := PathY[S]; MxY := MnY;
  For I := S To E Do Begin
   If PathX[I] < MnX Then MnX := PathX[I];
   If PathX[I] > MxX Then MxX := PathX[I];
   If PathY[I] < MnY Then MnY := PathY[I];
   If PathY[I] > MxY Then MxY := PathY[I];
  End;
  BA := PgX(MnX); BC := PgX(MxX); BB := PgY(MxY); BD := PgY(MnY);
  If OutsideClip(BA, BB, BC, BD) Then Continue;
  IsRect := False;
  If SubRect[K] And (N = 4) Then Begin
   Tol := 0.02 * (MxX - MnX + MxY - MnY) + 0.01;
   IsRect := True;
   For I := S To E Do
    If Not (((Abs(PathX[I] - MnX) < Tol) Or (Abs(PathX[I] - MxX) < Tol)) And
            ((Abs(PathY[I] - MnY) < Tol) Or (Abs(PathY[I] - MxY) < Tol))) Then IsRect := False;
  End;
  PatFill := DoFill And (GS.FillPat > 0);
  Fl := DoFill And (Not PatFill);
  If PatFill Then Begin
   If (GS.ClipPoly > 0) And (GS.FillPat > 0) Then Begin
    { motif limité par le polygone de découpe courant }
    N := CPN[GS.ClipPoly - 1];
    For I := 0 To N - 1 Do Begin TpX[I] := CPX[GS.ClipPoly - 1, I]; TpY[I] := CPY[GS.ClipPoly - 1, I]; End;
    N := ClipPolyBox(N, BA, BB, BC, BD);
    If GS.ClipOn Then N := ClipPolyBox(N, GS.CX1, GS.CY1, GS.CX2, GS.CY2);
    If N >= 3 Then PatternFill(N, BA, BB, BC, BD);
    N := E - S + 1;
   End
   Else If IsRect Then PatternFill(0, BA, BB, BC, BD)
   Else Begin
    Step := 1;
    If N > 1500 Then Step := (N + 1499) Div 1500;
    N := 0;
    I := S;
    While I <= E Do Begin
     TpX[N] := PgX(PathX[I]); TpY[N] := PgY(PathY[I]);
     Inc(N); Inc(I, Step);
    End;
    If GS.ClipOn And (Not InsideClip(BA, BB, BC, BD)) Then N := ClipPolyBox(N, GS.CX1, GS.CY1, GS.CX2, GS.CY2);
    If N >= 3 Then PatternFill(N, BA, BB, BC, BD);
    N := E - S + 1;
   End;
   If Not DoStroke Then Continue;
  End;
  If (Not Fl) And (Not DoStroke) Then Continue;
  If IsRect Then Begin
   LX1 := BA; LY1 := BB; LX2 := BC; LY2 := BD;
   If GS.ClipOn Then Begin
    ClampBox(LX1, LY1, LX2, LY2);
    If (LX2 < LX1) Or (LY2 < LY1) Then Continue;
   End;
   If ((GS.Blend = 1) Or GS.OverP) And Fl And (Not DoStroke) Then RK := K_HILITE Else RK := K_RECT;
   Idx := NewImpObj(RK);
   If Idx < 0 Then Exit;
   With ObjP(Idx)^ Do Begin
    X1 := LX1; X2 := LX2; Y1 := LY1; Y2 := LY2;
    If RK = K_HILITE Then Rgb := GS.Fill
    Else Begin
     Wd := StrokeW;
     Rgb := GS.Stroke; Rgb2 := GS.Fill;
     If Fl And DoStroke Then Fill := 2
     Else If Fl Then Begin Fill := 1; Rgb := GS.Fill; End
     Else Fill := 0;
     If Fl And (GS.FillA < 0.995) Then Alpha := AlphaByte(GS.FillA);
    End;
   End;
  End
  Else If (N = 2) And DoStroke And (Not Fl) Then Begin
   LX1 := PgX(PathX[S]); LY1 := PgY(PathY[S]); LX2 := PgX(PathX[E]); LY2 := PgY(PathY[E]);
   If Not ClipLineBox(LX1, LY1, LX2, LY2) Then Continue;
   Idx := NewImpObj(K_LINE);
   If Idx < 0 Then Exit;
   With ObjP(Idx)^ Do Begin
    X1 := LX1; Y1 := LY1; X2 := LX2; Y2 := LY2;
    Wd := StrokeW;
    Rgb := GS.Stroke;
   End;
  End
  Else If (Fl Or DoStroke) Then Begin
   If N > 1500 Then N := 1500;
   Step := 1;
   If (E - S + 1) > 1500 Then Step := ((E - S + 1) + 1499) Div 1500;
   { chemin en coordonnées page, éventuellement découpé (remplissage seul) }
   I := S;
   N := 0;
   While (I <= E) And (N < CLIPBUF Div 2) Do Begin
    TpX[N] := PgX(PathX[I]); TpY[N] := PgY(PathY[I]);
    Inc(N); Inc(I, Step);
   End;
   If GS.ClipOn And Fl And (Not DoStroke) And (Not InsideClip(BA, BB, BC, BD)) Then Begin
    N := ClipPolyBox(N, GS.CX1, GS.CY1, GS.CX2, GS.CY2);
    If N < 3 Then Continue;
   End;
   If N > 1500 Then N := 1500;
   Pool := PoolAlloc(N);
   If Pool < 0 Then Begin ImpFull := True; LoadNotice := 'Document tronqué : mémoire des tracés pleine.'; Exit; End;
   Idx := NewImpObj(K_POLY);
   If Idx < 0 Then Exit;
   For I := 0 To N - 1 Do Begin
    PoolXP(Pool + I)^ := TpX[I];
    PoolYP(Pool + I)^ := TpY[I];
   End;
   With ObjP(Idx)^ Do Begin
    P0 := Pool; PN := N;
    Wd := StrokeW;
    Rgb := GS.Stroke; Rgb2 := GS.Fill;
    If Closed Then Style := 1;
    If Fl And DoStroke Then Fill := 2
    Else If Fl Then Begin Fill := 1; Rgb := GS.Fill; End
    Else Fill := 0;
    If Fl And (GS.FillA < 0.995) Then Alpha := AlphaByte(GS.FillA);
   End;
   RecalcBox(Idx);
  End;
 End;
 NPts := 0;
 NSub := 0;
End;

{ Mémorise la découpe courante : boîte englobante du chemin et polygone éventuel }
Procedure PathOp(Fl, St, Cl: Boolean);
Var
 I, Step, PolyN: Integer;
 MnX, MnY, MxX, MxY: Real;
 A, B, C, D: LongInt;
 Pend, PolyOk: Boolean;
 PX, PY: Array[0..CPPTS - 1] Of LongInt;
Begin
 Pend := ClipPend And (NPts > 0);
 ClipPend := False;
 PolyN := 0; PolyOk := False;
 If Pend Then Begin
  MnX := PathX[0]; MxX := MnX; MnY := PathY[0]; MxY := MnY;
  For I := 1 To NPts - 1 Do Begin
   If PathX[I] < MnX Then MnX := PathX[I];
   If PathX[I] > MxX Then MxX := PathX[I];
   If PathY[I] < MnY Then MnY := PathY[I];
   If PathY[I] > MxY Then MxY := PathY[I];
  End;
  A := PgX(MnX); C := PgX(MxX); B := PgY(MxY); D := PgY(MnY);
  If (NSub = 1) And (NPts >= 3) And (Not (SubRect[0] And (NPts = 4))) And (NCP < CPMAX) Then Begin
   Step := (NPts + CPPTS - 1) Div CPPTS;
   I := 0;
   While (I < NPts) And (PolyN < CPPTS) Do Begin
    PX[PolyN] := PgX(PathX[I]); PY[PolyN] := PgY(PathY[I]);
    Inc(PolyN);
    Inc(I, Step);
   End;
   PolyOk := PolyN >= 3;
  End;
 End;
 EmitPath(Fl, St, Cl);
 If Pend Then Begin
  ClipToBox(A, B, C, D);
  If PolyOk Then Begin
   For I := 0 To PolyN - 1 Do Begin CPX[NCP, I] := PX[I]; CPY[NCP, I] := PY[I]; End;
   CPN[NCP] := PolyN;
   Inc(NCP);
   GS.ClipPoly := NCP;
  End;
 End;
End;

Procedure EmitImage(ImgIdx: Integer);
Var
 I: Integer;
 X, Y: Array[0..3] Of Real;
 MnX, MnY, MxX, MxY: Real;
 Idx: Integer;
Begin
 X[0] := GS.CTM[4]; Y[0] := GS.CTM[5];
 X[1] := GS.CTM[0] + GS.CTM[4]; Y[1] := GS.CTM[1] + GS.CTM[5];
 X[2] := GS.CTM[2] + GS.CTM[4]; Y[2] := GS.CTM[3] + GS.CTM[5];
 X[3] := GS.CTM[0] + GS.CTM[2] + GS.CTM[4]; Y[3] := GS.CTM[1] + GS.CTM[3] + GS.CTM[5];
 MnX := X[0]; MxX := X[0]; MnY := Y[0]; MxY := Y[0];
 For I := 1 To 3 Do Begin
  If X[I] < MnX Then MnX := X[I];
  If X[I] > MxX Then MxX := X[I];
  If Y[I] < MnY Then MnY := Y[I];
  If Y[I] > MxY Then MxY := Y[I];
 End;
 If OutsideClip(PgX(MnX), PgY(MxY), PgX(MxX), PgY(MnY)) Then Exit;
 Idx := NewImpObj(K_IMAGE);
 If Idx < 0 Then Exit;
 With ObjP(Idx)^ Do Begin
  X1 := PgX(MnX); X2 := PgX(MxX); Y1 := PgY(MxY); Y2 := PgY(MnY);
  If GS.FillA < 0.995 Then Alpha := AlphaByte(GS.FillA);
  If ImgIdx > 0 Then Begin
   P0 := ImgIdx;
   Rgb := GS.Fill;
   { axes de l'image dans la page (y vers le bas) : ex = axe horizontal de l'image,
     ey = axe vers le bas de l'image. bit 0/1 : axes inversés, bit 2 : image tournée de 90° }
   Style := 0;
   If Abs(GS.CTM[0]) >= Abs(GS.CTM[1]) Then Begin
    If GS.CTM[0] < 0 Then Style := Style Or 1;
    If GS.CTM[3] < 0 Then Style := Style Or 2;
   End
   Else Begin
    Style := 4;
    If GS.CTM[1] > 0 Then Style := Style Or 1;
    If GS.CTM[2] > 0 Then Style := Style Or 2;
   End;
  End;
 End;
End;

Procedure EmitText(Const Txt: String; Adv: Real);
Var
 M: TMat;
 SY, SXH, PX, PYv, WPt, Ang: Real;
 FSz, K, E, L, I, Idx, Sp, Tn: Integer;
 Part: String;
 F0, F1: Real;
 AnyCh: Boolean;
 Fam, Sty: Integer;
 Dx, Dy, Vx, Vy, Asc: Real;
 BX, BY: Real;
 Len: LongInt;
Begin
 If (Txt = '') Or (GS.TMode = 3) Or (GS.TMode = 7) Then Exit;
 AnyCh := False;
 For I := 1 To Length(Txt) Do If Txt[I] <> ' ' Then AnyCh := True;
 If Not AnyCh Then Exit;
 MatMul(TmM, GS.CTM, M);
 SXH := Sqrt(M[0] * M[0] + M[1] * M[1]);
 SY := Sqrt(M[2] * M[2] + M[3] * M[3]) * GS.TSize;
 { angle du texte (anti-horaire, en dixièmes de degré) }
 If M[0] = 0 Then Begin
  If M[1] >= 0 Then Ang := 90 Else Ang := 270;
 End
 Else Begin
  Ang := ArcTan(M[1] / M[0]) * 180 / Pi;
  If M[0] < 0 Then Ang := Ang + 180;
 End;
 If Ang < 0 Then Ang := Ang + 360;
 Tn := Round(Ang * 10) Mod 3600;
 { accrochage aux angles droits à 0,3° près }
 For I := 0 To 4 Do
  If Abs(Tn - I * 900) <= 3 Then Tn := (I * 900) Mod 3600;
 TextDirs(Tn, Dx, Dy, Vx, Vy);
 FSz := RI(SY);
 If FSz < 1 Then FSz := 1;
 If FSz > 200 Then FSz := 200;
 Asc := FSz * 0.8;
 PX := M[4] + GS.Ts * M[2];
 PYv := M[5] + GS.Ts * M[3];
 WPt := Abs(Adv * SXH);
 BX := PX - MbX0;
 BY := MbY1 - PYv;
 If (BX < -200) Or (BX > PgP(ImpPg)^.W + 200) Or (BY < -200) Or (BY > PgP(ImpPg)^.H + 200) Then Exit;
 If GS.TFont >= 0 Then Begin Fam := Fonts[GS.TFont].Fam; Sty := Fonts[GS.TFont].Style; End
 Else Begin Fam := 0; Sty := 0; End;
 L := Length(Txt);
 K := 1;
 While K <= L Do Begin
  E := K + 117;
  If E >= L Then E := L
  Else Begin
   Sp := E;
   While (Sp > K + 30) And (Txt[Sp] <> ' ') Do Dec(Sp);
   If Txt[Sp] = ' ' Then E := Sp;
  End;
  Part := Copy(Txt, K, E - K + 1);
  F0 := (K - 1) / L;
  F1 := E / L;
  Len := RI(WPt * (F1 - F0));
  If Len < 1 Then Len := 1;
  Idx := NewImpObj(K_TEXT);
  If Idx < 0 Then Exit;
  With ObjP(Idx)^ Do Begin
   Size := FSz;
   Style := Fam * 4 + Sty;
   Rgb := GS.Fill;
   Txt := Part;
   P0 := Len;
   PN := Tn;
  End;
  { origine = début de la ligne de base, remontée de l'ascendante }
  SetTextBox(ObjP(Idx)^, BX + Dx * WPt * F0 - Vx * Asc, BY + Dy * WPt * F0 - Vy * Asc);
  K := E + 1;
 End;
End;

Var
 NoColor: Boolean;

Procedure RunContent(Depth: Integer); Forward;

{ Dessine un glyphe Type 3 en rejouant sa procédure de dessin }
Procedure DrawT3Glyph(Var F: TFontRec; Code: Integer; AdvX: Real);
Var
 Num: LongInt;
 L: LongInt;
 Depth, FBase, XBase, RBase0: Integer;
 A, M2, Tr, SvTm, SvTlm: TMat;
 S: TSrcState;
 P: LongInt;
Begin
 If (Code < 0) Or (Code > 255) Then Exit;
 Num := F.T3^.Proc[Code];
 If Num <= 0 Then Exit;
 Depth := GDepth;
 If Depth >= 3 Then Exit;
 If ImpFull Then Exit;
 SrcMode := 0;
 If Not LoadStream(Num, CBufs[Depth + 1], L) Then Begin SrcMode := 2; Exit; End;
 CLens[Depth + 1] := L;
 FBase := NFonts; XBase := NXObjs; RBase0 := NRes;
 If F.T3^.HasRes Then LoadResources(F.T3^.Num);
 SvTm := TmM; SvTlm := TlmM;
 PushGS;
 M2[0] := GS.TSize * GS.Th; M2[1] := 0; M2[2] := 0; M2[3] := GS.TSize; M2[4] := 0; M2[5] := GS.Ts;
 MatMul(F.T3^.FM, M2, A);
 MatIdent(Tr); Tr[4] := AdvX;
 MatMul(A, Tr, A);
 MatMul(A, TmM, A);
 MatMul(A, GS.CTM, GS.CTM);
 GS.TFont := -1;
 NoColor := False;
 RunContent(Depth + 1);
 GDepth := Depth;
 NoColor := False;
 PopGS;
 FreeFontsTo(FBase);
 NXObjs := XBase;
 NRes := RBase0;
 TmM := SvTm; TlmM := SvTlm;
 { retour au flux de contenu appelant }
 SrcMode := 2;
 CBuf := CBufs[Depth];
 CLen := CLens[Depth];
End;

{ Ajoute les caractères de S (octets d'une chaîne PDF) à Out ; avance Adv. }
Procedure ShowStr(Const S0: String; Var Out: String; Var Adv: Real);
Var
 I, Step: Integer;
 Code: LongInt;
 F: ^TFontRec;
 W: Real;
 Mapped: String;
 S: String;
Begin
 S := S0;
 If GS.TFont >= 0 Then F := @Fonts[GS.TFont] Else F := Nil;
 If (F <> Nil) And (F^.T3 <> Nil) Then Begin
  For I := 1 To Length(S) Do Begin
   Code := Ord(S[I]);
   DrawT3Glyph(F^, Code, Adv);
   Adv := Adv + (F^.T3^.Wd[Code] * F^.T3^.FM[0] * GS.TSize + GS.Tc + (Ord(Code = 32) * GS.Tw)) * GS.Th;
  End;
  Exit;
 End;
 I := 1;
 While I <= Length(S) Do Begin
  If (F <> Nil) And F^.Wide Then Begin
   If I < Length(S) Then Code := Ord(S[I]) * 256 + Ord(S[I + 1]) Else Code := Ord(S[I]);
   Step := 2;
  End
  Else Begin Code := Ord(S[I]); Step := 1; End;
  If F <> Nil Then Begin
   Mapped := MapCode(F^, Code);
   W := GlyphW(F^, Code);
  End
  Else Begin
   If Code < 32 Then Mapped := '' Else Mapped := Chr(Code And 255);
   W := CharW(0, 0, Code And 255);
  End;
  If Length(Out) + Length(Mapped) < 250 Then Out := Out + Mapped;
  Adv := Adv + (W / 1000 * GS.TSize + GS.Tc + ((Ord(Code = 32) And Ord(Step = 1)) * GS.Tw)) * GS.Th;
  Inc(I, Step);
 End;
End;

Procedure TextMove(TX, TY: Real);
Var
 T: TMat;
Begin
 T[0] := 1; T[1] := 0; T[2] := 0; T[3] := 1; T[4] := TX; T[5] := TY;
 MatMul(T, TlmM, TlmM);
 TmM := TlmM;
End;

Procedure ShowAndEmit(Const S: String);
Var
 Out: String;
 Adv: Real;
 T: TMat;
Begin
 Out := '';
 Adv := 0;
 ShowStr(S, Out, Adv);
 EmitText(Out, Adv);
 T[0] := 1; T[1] := 0; T[2] := 0; T[3] := 1; T[4] := Adv; T[5] := 0;
 MatMul(T, TmM, TmM);
End;

Procedure ShowTJ(ArrPos: LongInt);
Var
 P: LongInt;
 T: Integer;
 Out: String;
 Adv: Real;
 M: TMat;
Begin
 P := ArrPos;
 If NextTok(P) <> T_AB Then Exit;
 Out := '';
 Adv := 0;
 While True Do Begin
  T := NextTok(P);
  If (T = T_AE) Or (T = T_EOF) Then Break;
  If T = T_STR Then ShowStr(TokS, Out, Adv)
  Else If T = T_NUM Then Begin
   Adv := Adv - TokR / 1000 * GS.TSize * GS.Th;
   If (TokR <= -250) And (Out <> '') And (Out[Length(Out)] <> ' ') And (Length(Out) < 250) Then Out := Out + ' ';
  End;
 End;
 EmitText(Out, Adv);
 M[0] := 1; M[1] := 0; M[2] := 0; M[3] := 1; M[4] := Adv; M[5] := 0;
 MatMul(M, TmM, TmM);
End;



{ ---- Contenu optionnel (calques) ---- }
Procedure MCRecalc;
Var
 I: Integer;
Begin
 CurLayer := 0;
 For I := MCSP - 1 DownTo 0 Do
  If MCSt[I] <> 0 Then Begin CurLayer := MCSt[I]; Exit; End;
End;

Procedure MCPush(Code: Word);
Begin
 If MCSP < 64 Then Begin MCSt[MCSP] := Code; Inc(MCSP); End Else Inc(MCOver);
 MCRecalc;
End;

Procedure MCPop;
Begin
 If MCOver > 0 Then Dec(MCOver) Else If MCSP > 0 Then Dec(MCSP);
 MCRecalc;
End;

{ Code de calque d'un OCG ou d'un OCMD : indice + 1, $FFFF masqué en permanence, 0 sans effet }
Function OCCode(Num: LongInt): Word;
Var
 S: TSrcState;
 P, V, Q, Pos0: LongInt;
 N, I, Cnt, K, NOn: Integer;
 Refs: Array[0..31] Of Integer;
 Pol: String;
 Vis: Boolean;
Begin
 OCCode := 0;
 K := LayerFind(Num);
 If K >= 0 Then Begin OCCode := K + 1; Exit; End;
 SaveSrc(S);
 SrcMode := 0;
 P := EnterObj(Num);
 If P >= 0 Then If ValName(DictFind(P, 'Type')) = 'OCMD' Then Begin
  V := DictFind(P, 'OCGs');
  Pol := ValName(DictFind(P, 'P'));
  If Pol = '' Then Pol := 'AnyOn';
  Cnt := 0;
  If V >= 0 Then Begin
   N := RefAt(V);
   If N > 0 Then Begin
    Q := EnterObj(N);
    Pos0 := Q;
    If (Q >= 0) And (NextTok(Q) = T_AB) Then Begin
     While Cnt < 32 Do Begin
      I := RefAt(Q);
      If I > 0 Then Begin Refs[Cnt] := I; Inc(Cnt); SkipValue(Q); End Else Break;
     End;
    End
    Else Begin Refs[0] := N; Cnt := 1; End;
   End
   Else Begin
    Q := V;
    If NextTok(Q) = T_AB Then
     While Cnt < 32 Do Begin
      I := RefAt(Q);
      If I > 0 Then Begin Refs[Cnt] := I; Inc(Cnt); SkipValue(Q); End Else Break;
     End;
   End;
  End;
  If Cnt = 1 Then Begin
   K := LayerFind(Refs[0]);
   If K >= 0 Then OCCode := K + 1;
  End
  Else If Cnt > 1 Then Begin
   NOn := 0;
   For I := 0 To Cnt - 1 Do Begin
    K := LayerFind(Refs[I]);
    If (K < 0) Or Layers^[K].On Then Inc(NOn);
   End;
   If Pol = 'AllOn' Then Vis := NOn = Cnt
   Else If Pol = 'AnyOff' Then Vis := NOn < Cnt
   Else If Pol = 'AllOff' Then Vis := NOn = 0
   Else Vis := NOn > 0;
   If Not Vis Then OCCode := $FFFF;
  End;
 End;
 RestoreSrc(S);
End;

{ Calque d'un XObject ou d'une annotation (entrée /OC de son dictionnaire) }
Function XObjLayer(Num: LongInt): Word;
Var
 S: TSrcState;
 P, V: LongInt;
 N: Integer;
Begin
 XObjLayer := 0;
 If LayerCount = 0 Then Exit;
 SaveSrc(S);
 SrcMode := 0;
 P := EnterObj(Num);
 N := 0;
 If P >= 0 Then Begin
  V := DictFind(P, 'OC');
  If V >= 0 Then N := RefAt(V);
 End;
 RestoreSrc(S);
 If N > 0 Then XObjLayer := OCCode(N);
End;

Procedure DoBDC;
Var
 S: TSrcState;
 Num: LongInt;
 Code: Word;
Begin
 Code := 0;
 If (PrevName = 'OC') And (LayerCount > 0) Then Begin
  SaveSrc(S);
  FindRes('Properties', LastName, Num);
  RestoreSrc(S);
  If Num > 0 Then Code := OCCode(Num);
 End;
 MCPush(Code);
End;

Procedure DoXObject0(Const Name: String; Depth: Integer);
Var
 I, Idx: Integer;
 L: LongInt;
 P, V: LongInt;
 Mat: TMat;
 Arr: Array[0..5] Of Real;
 FBase, XBase, Num, RBase0: Integer;
 S: TSrcState;
Begin
 Idx := -1;
 For I := NXObjs - 1 DownTo 0 Do
  If XObjs[I].Name = Name Then Begin Idx := I; Break; End;
 If Idx < 0 Then Exit;
 If Not XObjs[Idx].IsForm Then Begin EmitImage(ImportImageObj(XObjs[Idx].Num, False)); Exit; End;
 If Depth >= 3 Then Exit;
 Num := XObjs[Idx].Num;
 FBase := NFonts; XBase := NXObjs; RBase0 := NRes;
 SrcMode := 0;
 If Not LoadStream(Num, CBufs[Depth + 1], L) Then Exit;
 CLens[Depth + 1] := L;
 MatIdent(Mat);
 SrcMode := 0;
 P := EnterObj(Num);
 If P >= 0 Then Begin
  V := DictFind(P, 'Matrix');
  If V >= 0 Then If ReadNums(V, Arr, 6) = 6 Then
   For I := 0 To 5 Do Mat[I] := Arr[I];
  If DictFind(P, 'Resources') >= 0 Then LoadResources(Num);
 End;
 PushGS;
 MatMul(Mat, GS.CTM, GS.CTM);
 RunContent(Depth + 1);
 PopGS;
 FreeFontsTo(FBase);
 NXObjs := XBase;
 NRes := RBase0;
End;

Procedure DoXObject(Const Name: String; Depth: Integer);
Var
 I, Idx: Integer;
 Lc: Word;
Begin
 Lc := 0;
 If LayerCount > 0 Then Begin
  Idx := -1;
  For I := NXObjs - 1 DownTo 0 Do
   If XObjs[I].Name = Name Then Begin Idx := I; Break; End;
  If Idx >= 0 Then Lc := XObjLayer(XObjs[Idx].Num);
 End;
 If Lc <> 0 Then MCPush(Lc);
 DoXObject0(Name, Depth);
 If Lc <> 0 Then MCPop;
End;

{ Motif de pavage : le contenu de la cellule est rejoué sur la boîte (ou aplat gris si trop de cellules) }
Procedure PaintTiling(Num: LongInt; BX1, BY1, BX2, BY2: LongInt);
Var
 S: TSrcState;
 P, V: LongInt;
 Mat, Inv, Tm: TMat;
 Arr: Array[0..5] Of Real;
 Bb: Array[0..3] Of Real;
 XS, YS, Det, Ux, Uy, Px, Py, Mnx, Mxx, Mny, Mxy: Real;
 PaintType, I, J, K, Depth, FBase, XBase, RBase0, I0, I1, J0, J1: Integer;
 L: LongInt;
 Idx: Integer;
Begin
 Depth := GDepth;
 If Depth >= 3 Then Exit;
 If OutsideClip(BX1, BY1, BX2, BY2) Then Exit;
 ClampBox(BX1, BY1, BX2, BY2);
 If (BX2 < BX1) Or (BY2 < BY1) Then Exit;
 SaveSrc(S);
 SrcMode := 0;
 P := EnterObj(Num);
 If P < 0 Then Begin RestoreSrc(S); Exit; End;
 PaintType := ValInt(DictFind(P, 'PaintType'), 1);
 XS := ValNum(DictFind(P, 'XStep'), 0);
 YS := ValNum(DictFind(P, 'YStep'), 0);
 Bb[0] := 0; Bb[1] := 0; Bb[2] := 1; Bb[3] := 1;
 V := DictFind(P, 'BBox');
 If V >= 0 Then ReadNums(V, Bb, 4);
 MatIdent(Mat);
 V := DictFind(P, 'Matrix');
 If V >= 0 Then If ReadNums(V, Arr, 6) = 6 Then
  For I := 0 To 5 Do Mat[I] := Arr[I];
 If XS = 0 Then XS := Bb[2] - Bb[0];
 If YS = 0 Then YS := Bb[3] - Bb[1];
 Det := Mat[0] * Mat[3] - Mat[1] * Mat[2];
 K := 0;
 If (Abs(XS) < 0.2) Or (Abs(YS) < 0.2) Or (Abs(Det) < 0.0000001) Then K := 1;
 If K = 0 Then Begin
  { boîte en espace motif }
  Mnx := 1E30; Mxx := -1E30; Mny := 1E30; Mxy := -1E30;
  For I := 0 To 3 Do Begin
   If I And 1 = 0 Then Ux := BX1 + MbX0 Else Ux := BX2 + MbX0;
   If I And 2 = 0 Then Uy := MbY1 - BY2 Else Uy := MbY1 - BY1;
   Px := ((Ux - Mat[4]) * Mat[3] - (Uy - Mat[5]) * Mat[2]) / Det;
   Py := ((Uy - Mat[5]) * Mat[0] - (Ux - Mat[4]) * Mat[1]) / Det;
   If Px < Mnx Then Mnx := Px;
   If Px > Mxx Then Mxx := Px;
   If Py < Mny Then Mny := Py;
   If Py > Mxy Then Mxy := Py;
  End;
  XS := Abs(XS); YS := Abs(YS);
  I0 := Trunc((Mnx - Bb[2]) / XS) - 1; I1 := Trunc((Mxx - Bb[0]) / XS) + 1;
  J0 := Trunc((Mny - Bb[3]) / YS) - 1; J1 := Trunc((Mxy - Bb[1]) / YS) + 1;
  If (I1 - I0 + 1) * (J1 - J0 + 1) > 300 Then K := 1;
 End;
 If K <> 0 Then Begin
  RestoreSrc(S);
  { trop de cellules : aplat gris clair }
  Idx := NewImpObj(K_RECT);
  If Idx >= 0 Then
   With ObjP(Idx)^ Do Begin
    X1 := BX1; Y1 := BY1; X2 := BX2; Y2 := BY2;
    Fill := 1; Rgb := RGBOf(200, 200, 200); Rgb2 := Rgb; Wd := 1;
   End;
  Exit;
 End;
 FBase := NFonts; XBase := NXObjs; RBase0 := NRes;
 SrcMode := 0;
 If Not LoadStream(Num, CBufs[Depth + 1], L) Then Begin RestoreSrc(S); Exit; End;
 CLens[Depth + 1] := L;
 SrcMode := 0;
 P := EnterObj(Num);
 If P >= 0 Then If DictFind(P, 'Resources') >= 0 Then LoadResources(Num);
 RestoreSrc(S);
 For J := J0 To J1 Do
  For I := I0 To I1 Do Begin
   If ImpFull Then Break;
   PushGS;
   MatIdent(Tm);
   Tm[4] := I * XS; Tm[5] := J * YS;
   MatMul(Tm, Mat, GS.CTM);
   ClipToBox(BX1, BY1, BX2, BY2);
   GS.FillPat := 0; GS.CSPat := False;
   RunContent(Depth + 1);
   GDepth := Depth;
   PopGS;
  End;
 FreeFontsTo(FBase);
 NXObjs := XBase;
 NRes := RBase0;
End;

Procedure SetPatternByName(Const Name: String);
Var
 S: TSrcState;
 Num: LongInt;
Begin
 SaveSrc(S);
 FindRes('Pattern', Name, Num);
 RestoreSrc(S);
 GS.FillPat := Num;
End;

Procedure SetColorSpaceByName(Const Name: String; Stroke: Boolean);
Var
 K: Integer;
 Rgb: LongInt;
Begin
 K := -1;
 If Not Stroke Then Begin GS.CSPat := Name = 'Pattern'; GS.FillPat := 0; GS.FillCS := 0; End
 Else GS.StrokeCS := 0;
 If Name = 'Pattern' Then Exit;
 If (Name = 'DeviceGray') Or (Name = 'DeviceRGB') Or (Name = 'DeviceCMYK') Or (Name = 'G') Or (Name = 'RGB') Or (Name = 'CMYK') Then Begin
  If Name[1] = 'D' Then K := -2;
  If Not Stroke Then Begin
   If (Name = 'DeviceCMYK') Or (Name = 'CMYK') Then GS.Fill := 0 Else GS.Fill := 0;
  End
  Else GS.Stroke := 0;
  Exit;
 End;
 K := CSByName(Name);
 If K < 0 Then Exit;
 If CSCache[K].D.Kind = 8 Then Begin
  If Not Stroke Then GS.CSPat := True;
  Exit;
 End;
 Rgb := CSInitialRgb(CSCache[K].D);
 If Stroke Then Begin GS.StrokeCS := K + 1; GS.Stroke := Rgb; End
 Else Begin GS.FillCS := K + 1; GS.Fill := Rgb; End;
End;

{ Couleur courante selon l'espace colorimétrique non appareil ; faux si aucun }
Function TrySetColor(Stroke: Boolean): Boolean;
Var
 Idx, N, I: Integer;
 C: Array[0..7] Of Real;
 Rgb: LongInt;
Begin
 TrySetColor := False;
 If Stroke Then Idx := GS.StrokeCS - 1 Else Idx := GS.FillCS - 1;
 If (Idx < 0) Or (Idx >= CSMAXC) Then Exit;
 If Not CSCache[Idx].Used Then Exit;
 N := CSCache[Idx].D.N;
 If (N < 1) Or (N > 8) Or (NOpnd < N) Then Exit;
 For I := 0 To N - 1 Do C[I] := Opnd[NOpnd - N + I];
 Rgb := ColorToRgb(CSCache[Idx].D, C, N);
 If Stroke Then GS.Stroke := Rgb Else GS.Fill := Rgb;
 TrySetColor := True;
End;

Procedure DoShading(Const Name: String);
Var
 S: TSrcState;
 P, Num: LongInt;
 Ok: Boolean;
 N, I: Integer;
Begin
 SaveSrc(S);
 P := FindRes('Shading', Name, Num);
 Ok := False;
 If P >= 0 Then Ok := ShadingToAbs(P, GS.CTM);
 RestoreSrc(S);
 If Not Ok Then Exit;
 If GS.ClipPoly > 0 Then Begin
  N := CPN[GS.ClipPoly - 1];
  For I := 0 To N - 1 Do Begin TpX[I] := CPX[GS.ClipPoly - 1, I]; TpY[I] := CPY[GS.ClipPoly - 1, I]; End;
  If GS.ClipOn Then N := ClipPolyBox(N, GS.CX1, GS.CY1, GS.CX2, GS.CY2);
  If N >= 3 Then EmitGradient(N, 0, 0, 0, 0);
 End
 Else If GS.ClipOn Then EmitGradient(0, GS.CX1, GS.CY1, GS.CX2, GS.CY2)
 Else EmitGradient(0, 0, 0, PgP(ImpPg)^.W, PgP(ImpPg)^.H);
End;

Procedure DoExtGState(Const Name: String);
Var
 S: TSrcState;
 P, Num, V, Q: LongInt;
 R: Real;
 T: Integer;
Begin
 SaveSrc(S);
 P := FindRes('ExtGState', Name, Num);
 If P >= 0 Then Begin
  V := DictFind(P, 'ca');
  If V >= 0 Then Begin R := ValNum(V, 1); If R < 0 Then R := 0; If R > 1 Then R := 1; GS.FillA := R; End;
  V := DictFind(P, 'CA');
  If V >= 0 Then Begin R := ValNum(V, 1); If R < 0 Then R := 0; If R > 1 Then R := 1; GS.StrokeA := R; End;
  V := DictFind(P, 'op');
  If V < 0 Then V := DictFind(P, 'OP');
  If V >= 0 Then Begin Q := V; If NextTok(Q) = T_OP Then GS.OverP := TokS = 'true'; End;
  V := DictFind(P, 'BM');
  If V >= 0 Then Begin
   Q := V;
   T := NextTok(Q);
   If T = T_AB Then T := NextTok(Q);
   If T = T_NAME Then Begin
    If TokS = 'Multiply' Then GS.Blend := 1 Else GS.Blend := 0;
   End;
  End;
 End;
 RestoreSrc(S);
End;

Procedure ExecOp(Const Op: String; Var P: LongInt; ArrPos: LongInt; Depth: Integer);
Var
 C: Char;
 T: TMat;
 I, T2, N: Integer;
 Q: LongInt;
 X, Y, W, H: Real;
 Prev: Char;
Begin
 GDepth := Depth;
 C := Op[1];
 N := NOpnd;
 If Op = 'BDC' Then Begin DoBDC; NOpnd := 0; Exit; End;
 If Op = 'BMC' Then Begin MCPush(0); NOpnd := 0; Exit; End;
 If Op = 'EMC' Then Begin MCPop; NOpnd := 0; Exit; End;
 If NoColor Then
  If (Op = 'g') Or (Op = 'G') Or (Op = 'rg') Or (Op = 'RG') Or (Op = 'k') Or (Op = 'K') Or (Op = 'sc') Or
     (Op = 'SC') Or (Op = 'scn') Or (Op = 'SCN') Or (Op = 'cs') Or (Op = 'CS') Or (Op = 'gs') Then Begin
   NOpnd := 0;
   Exit;
  End;
 If (Op = 'g') Or (Op = 'rg') Or (Op = 'k') Then GS.FillCS := 0;
 If (Op = 'G') Or (Op = 'RG') Or (Op = 'K') Then GS.StrokeCS := 0;
 If (Op = 'sc') Or (Op = 'scn') Then Begin
  If GS.FillCS > 0 Then If TrySetColor(False) Then Begin NOpnd := 0; Exit; End;
 End
 Else If (Op = 'SC') Or (Op = 'SCN') Then Begin
  If GS.StrokeCS > 0 Then If TrySetColor(True) Then Begin NOpnd := 0; Exit; End;
 End;
 Case Length(Op) Of
  1: Case C Of
   'q': PushGS;
   'Q': PopGS;
   'w': If N >= 1 Then GS.LW := Opnd[N - 1];
   'm': If N >= 2 Then Begin NewSub; AddPt(Opnd[N - 2], Opnd[N - 1]); End;
   'l': If N >= 2 Then Begin If NPts = 0 Then NewSub; AddPt(Opnd[N - 2], Opnd[N - 1]); End;
   'c': If (N >= 6) And (NPts > 0) Then CurveTo(Opnd[N - 6], Opnd[N - 5], Opnd[N - 4], Opnd[N - 3], Opnd[N - 2], Opnd[N - 1]);
   'v': If (N >= 4) And (NPts > 0) Then Begin
    X := PathX[NPts - 1]; Y := PathY[NPts - 1];
    { point courant en espace utilisateur approximé : inversion non requise, on utilise le point transformé }
    CurveTo(Opnd[N - 4], Opnd[N - 3], Opnd[N - 4], Opnd[N - 3], Opnd[N - 2], Opnd[N - 1]);
   End;
   'y': If (N >= 4) And (NPts > 0) Then
    CurveTo(Opnd[N - 4], Opnd[N - 3], Opnd[N - 2], Opnd[N - 1], Opnd[N - 2], Opnd[N - 1]);
   'h': If NSub > 0 Then SubClosed[NSub - 1] := True;
   'S': PathOp(False, True, False);
   's': PathOp(False, True, True);
   'f', 'F': PathOp(True, False, False);
   'B': PathOp(True, True, False);
   'b': PathOp(True, True, True);
   'n': PathOp(False, False, False);
   'W': ClipPend := True;
   'g': If N >= 1 Then Begin GS.Fill := GrayRgb(Opnd[N - 1]); GS.FillPat := 0; GS.CSPat := False; End;
   'G': If N >= 1 Then GS.Stroke := GrayRgb(Opnd[N - 1]);
   'k': If N >= 4 Then Begin GS.Fill := CmykRgb(Opnd[N - 4], Opnd[N - 3], Opnd[N - 2], Opnd[N - 1]); GS.FillPat := 0; GS.CSPat := False; End;
   'K': If N >= 4 Then GS.Stroke := CmykRgb(Opnd[N - 4], Opnd[N - 3], Opnd[N - 2], Opnd[N - 1]);
   '''': Begin TextMove(0, -GS.TL); ShowAndEmit(LastStr); End;
   '"': Begin
    If N >= 2 Then Begin GS.Tw := Opnd[N - 2]; GS.Tc := Opnd[N - 1]; End;
    TextMove(0, -GS.TL); ShowAndEmit(LastStr);
   End;
  End;
  2: Begin
   Prev := Op[2];
   If Op = 'cm' Then Begin
    If N >= 6 Then Begin
     For I := 0 To 5 Do T[I] := Opnd[N - 6 + I];
     MatMul(T, GS.CTM, GS.CTM);
    End;
   End
   Else If Op = 're' Then Begin
    If N >= 4 Then Begin
     X := Opnd[N - 4]; Y := Opnd[N - 3]; W := Opnd[N - 2]; H := Opnd[N - 1];
     NewSub;
     If NSub > 0 Then SubRect[NSub - 1] := True;
     AddPt(X, Y); AddPt(X + W, Y); AddPt(X + W, Y + H); AddPt(X, Y + H);
     If NSub > 0 Then SubClosed[NSub - 1] := True;
    End;
   End
   Else If Op = 'f*' Then PathOp(True, False, False)
   Else If Op = 'B*' Then PathOp(True, True, False)
   Else If Op = 'b*' Then PathOp(True, True, True)
   Else If Op = 'W*' Then ClipPend := True
   Else If Op = 'd1' Then NoColor := True
   Else If Op = 'sh' Then DoShading(LastName)
   Else If Op = 'gs' Then DoExtGState(LastName)
   Else If Op = 'cs' Then SetColorSpaceByName(LastName, False)
   Else If Op = 'CS' Then SetColorSpaceByName(LastName, True)
   Else If Op = 'BT' Then Begin MatIdent(TmM); MatIdent(TlmM); End
   Else If Op = 'ET' Then
   Else If Op = 'Tc' Then Begin If N >= 1 Then GS.Tc := Opnd[N - 1]; End
   Else If Op = 'Tw' Then Begin If N >= 1 Then GS.Tw := Opnd[N - 1]; End
   Else If Op = 'Tz' Then Begin If N >= 1 Then GS.Th := Opnd[N - 1] / 100; End
   Else If Op = 'TL' Then Begin If N >= 1 Then GS.TL := Opnd[N - 1]; End
   Else If Op = 'Ts' Then Begin If N >= 1 Then GS.Ts := Opnd[N - 1]; End
   Else If Op = 'Tr' Then Begin If N >= 1 Then GS.TMode := Round(Opnd[N - 1]); End
   Else If Op = 'Tf' Then Begin
    If N >= 1 Then GS.TSize := Opnd[N - 1];
    GS.TFont := FontIndex(LastName);
   End
   Else If Op = 'Td' Then Begin If N >= 2 Then TextMove(Opnd[N - 2], Opnd[N - 1]); End
   Else If Op = 'TD' Then Begin
    If N >= 2 Then Begin GS.TL := -Opnd[N - 1]; TextMove(Opnd[N - 2], Opnd[N - 1]); End;
   End
   Else If Op = 'Tm' Then Begin
    If N >= 6 Then Begin
     For I := 0 To 5 Do TmM[I] := Opnd[N - 6 + I];
     TlmM := TmM;
    End;
   End
   Else If Op = 'T*' Then TextMove(0, -GS.TL)
   Else If Op = 'Tj' Then ShowAndEmit(LastStr)
   Else If Op = 'TJ' Then Begin If ArrPos >= 0 Then ShowTJ(ArrPos); End
   Else If Op = 'rg' Then Begin If N >= 3 Then Begin GS.Fill := RGBOf(RI(Opnd[N - 3] * 255), RI(Opnd[N - 2] * 255), RI(Opnd[N - 1] * 255)); GS.FillPat := 0; GS.CSPat := False; End; End
   Else If Op = 'RG' Then Begin If N >= 3 Then GS.Stroke := RGBOf(RI(Opnd[N - 3] * 255), RI(Opnd[N - 2] * 255), RI(Opnd[N - 1] * 255)); End
   Else If (Op = 'sc') Or (Op = 'SC') Then Begin
    If Op = 'sc' Then GS.FillPat := 0;
    If N = 1 Then Begin If Op = 'sc' Then GS.Fill := GrayRgb(Opnd[0]) Else GS.Stroke := GrayRgb(Opnd[0]); End
    Else If N = 3 Then Begin
     If Op = 'sc' Then GS.Fill := RGBOf(RI(Opnd[0] * 255), RI(Opnd[1] * 255), RI(Opnd[2] * 255))
     Else GS.Stroke := RGBOf(RI(Opnd[0] * 255), RI(Opnd[1] * 255), RI(Opnd[2] * 255));
    End
    Else If N = 4 Then Begin
     If Op = 'sc' Then GS.Fill := CmykRgb(Opnd[0], Opnd[1], Opnd[2], Opnd[3])
     Else GS.Stroke := CmykRgb(Opnd[0], Opnd[1], Opnd[2], Opnd[3]);
    End;
   End
   Else If Op = 'Do' Then DoXObject(LastName, Depth)
   Else If Op = 'BI' Then Begin
    { image en ligne }
    I := InlineImage(P);
    If I > 0 Then EmitImage(I) Else EmitImage(0);
   End;
  End;
 Else
  If (Op = 'scn') Or (Op = 'SCN') Then Begin
   If (Op = 'scn') And GS.CSPat And (LastName <> '') Then SetPatternByName(LastName)
   Else If Op = 'scn' Then GS.FillPat := 0;
   If N = 1 Then Begin If Op = 'scn' Then GS.Fill := GrayRgb(Opnd[0]) Else GS.Stroke := GrayRgb(Opnd[0]); End
   Else If N = 3 Then Begin
    If Op = 'scn' Then GS.Fill := RGBOf(RI(Opnd[0] * 255), RI(Opnd[1] * 255), RI(Opnd[2] * 255))
    Else GS.Stroke := RGBOf(RI(Opnd[0] * 255), RI(Opnd[1] * 255), RI(Opnd[2] * 255));
   End
   Else If N = 4 Then Begin
    If Op = 'scn' Then GS.Fill := CmykRgb(Opnd[0], Opnd[1], Opnd[2], Opnd[3])
    Else GS.Stroke := CmykRgb(Opnd[0], Opnd[1], Opnd[2], Opnd[3]);
   End;
  End;
 End;
 NOpnd := 0;
End;

Procedure RunContent(Depth: Integer);
Var
 P, Q0, ArrPos: LongInt;
 T: Integer;
 Op: String;
 SaveGSP: Integer;
 Count: LongInt;
Begin
 SaveGSP := GSP;
 P := 0;
 NOpnd := 0;
 ArrPos := -1;
 Count := 0;
 While Not ImpFull Do Begin
  SrcMode := 2;
  CBuf := CBufs[Depth];
  CLen := CLens[Depth];
  Q0 := P;
  T := NextTok(P);
  Inc(Count);
  If T = T_EOF Then Break;
  Case T Of
   T_NUM: Begin
    If NOpnd >= 40 Then Begin
     Move(Opnd[1], Opnd[0], 39 * SizeOf(Real));
     NOpnd := 39;
    End;
    Opnd[NOpnd] := TokR;
    Inc(NOpnd);
   End;
   T_NAME: Begin PrevName := LastName; LastName := TokS; End;
   T_STR: LastStr := TokS;
   T_AB: Begin ArrPos := Q0; P := Q0; SkipValue(P); End;
   T_DB: Begin P := Q0; SkipValue(P); End;
   T_OP: Begin
    Op := TokS;
    ExecOp(Op, P, ArrPos, Depth);
    If (Op = 'TJ') Or (Op = 'd') Then ArrPos := -1;
   End;
  End;
  If (Count And 1023) = 0 Then Begin
   If KeyPressed Then If ReadKey = #27 Then Begin ImpFull := True; LoadNotice := 'Chargement interrompu.'; End;
  End;
 End;
 While GSP > SaveGSP Do PopGS;
 SrcMode := 0;
End;

{ ---------------------------------------------------------------------- }
{ Import PDF : pages, annotations                                           }
{ ---------------------------------------------------------------------- }

Function StrAtPos(P: LongInt): String;
Var
 N: Integer;
 S: TSrcState;
 Q: LongInt;
Begin
 StrAtPos := '';
 If P < 0 Then Exit;
 N := RefAt(P);
 If N > 0 Then Begin
  SaveSrc(S);
  Q := EnterObj(N);
  If Q >= 0 Then If NextTok(Q) = T_STR Then StrAtPos := TokS;
  RestoreSrc(S);
 End
 Else If NextTok(P) = T_STR Then StrAtPos := TokS;
End;

Function AnnColor(P: LongInt; Def: LongInt): LongInt;
Var
 A: Array[0..3] Of Real;
 N: Integer;
Begin
 AnnColor := Def;
 If P < 0 Then Exit;
 N := ReadNums(P, A, 4);
 If N = 1 Then AnnColor := GrayRgb(A[0])
 Else If N = 3 Then AnnColor := RGBOf(RI(A[0] * 255), RI(A[1] * 255), RI(A[2] * 255))
 Else If N = 4 Then AnnColor := CmykRgb(A[0], A[1], A[2], A[3]);
End;

Procedure ImportAnnot(Num: Integer);
Var
 P, V, Q: LongInt;
 Sub, ATxt: String;
 R: Array[0..3] Of Real;
 QA: Array[0..31] Of Real;
 LA: Array[0..3] Of Real;
 N, I, K, Idx, Kind, Pool, Cnt: Integer;
 Col, ICol: LongInt;
 AX1, AY1, AX2, AY2: LongInt;
 BW: LongInt;
 T: Integer;
 MnX, MnY, MxX, MxY: Real;
 HasIC: Boolean;
 Px, Py: Array[0..199] Of Integer;
Begin
 SrcMode := 0;
 P := EnterObj(Num);
 If P < 0 Then Exit;
 Sub := ValName(DictFind(P, 'Subtype'));
 If (Sub <> 'Highlight') And (Sub <> 'Underline') And (Sub <> 'StrikeOut') And (Sub <> 'Squiggly') And
    (Sub <> 'Text') And (Sub <> 'FreeText') And (Sub <> 'Square') And (Sub <> 'Circle') And
    (Sub <> 'Line') And (Sub <> 'Ink') Then Exit;
 If ReadNums(DictFind(P, 'Rect'), R, 4) < 4 Then Exit;
 AX1 := PgX(R[0]); AX2 := PgX(R[2]); AY1 := PgY(R[3]); AY2 := PgY(R[1]);
 If AX1 > AX2 Then Begin I := AX1; AX1 := AX2; AX2 := I; End;
 If AY1 > AY2 Then Begin I := AY1; AY1 := AY2; AY2 := I; End;
 ATxt := PdfText(StrAtPos(DictFind(P, 'Contents')));
 If Length(ATxt) > 119 Then ATxt := Copy(ATxt, 1, 119);
 Col := AnnColor(DictFind(P, 'C'), -1);
 V := DictFind(P, 'IC');
 HasIC := V >= 0;
 ICol := AnnColor(V, $FFFFFF);
 BW := 1;
 V := DictFind(P, 'BS');
 If V >= 0 Then BW := ValInt(DictFind(V, 'W'), 1);
 If BW < 1 Then BW := 1;
 If BW > 20 Then BW := 20;
 If (Sub = 'Highlight') Or (Sub = 'Underline') Or (Sub = 'StrikeOut') Or (Sub = 'Squiggly') Then Begin
  If Sub = 'Highlight' Then Begin Kind := K_HILITE; If Col < 0 Then Col := $FFFF00; End
  Else If Sub = 'StrikeOut' Then Begin Kind := K_STRIKE; If Col < 0 Then Col := $FF0000; End
  Else Begin Kind := K_UNDER; If Col < 0 Then Col := $FF0000; End;
  N := ReadNums(DictFind(P, 'QuadPoints'), QA, 32);
  K := N Div 8;
  If K = 0 Then Begin
   Idx := NewImpObj(Kind);
   If Idx < 0 Then Exit;
   With ObjP(Idx)^ Do Begin X1 := AX1; Y1 := AY1; X2 := AX2; Y2 := AY2; Rgb := Col; Txt := ATxt; End;
  End
  Else For I := 0 To K - 1 Do Begin
   MnX := QA[I * 8]; MxX := MnX; MnY := QA[I * 8 + 1]; MxY := MnY;
   For T := 0 To 3 Do Begin
    If QA[I * 8 + T * 2] < MnX Then MnX := QA[I * 8 + T * 2];
    If QA[I * 8 + T * 2] > MxX Then MxX := QA[I * 8 + T * 2];
    If QA[I * 8 + T * 2 + 1] < MnY Then MnY := QA[I * 8 + T * 2 + 1];
    If QA[I * 8 + T * 2 + 1] > MxY Then MxY := QA[I * 8 + T * 2 + 1];
   End;
   Idx := NewImpObj(Kind);
   If Idx < 0 Then Exit;
   With ObjP(Idx)^ Do Begin
    X1 := PgX(MnX); X2 := PgX(MxX); Y1 := PgY(MxY); Y2 := PgY(MnY);
    Rgb := Col;
    If I = 0 Then Txt := ATxt;
   End;
  End;
 End
 Else If Sub = 'Text' Then Begin
  Idx := NewImpObj(K_NOTE);
  If Idx < 0 Then Exit;
  With ObjP(Idx)^ Do Begin X1 := AX1; Y1 := AY1; X2 := AX1 + 16; Y2 := AY1 + 16; Rgb := $FFFF00; Txt := ATxt; End;
 End
 Else If Sub = 'FreeText' Then Begin
  If ATxt = '' Then Exit;
  Idx := NewImpObj(K_TEXT);
  If Idx < 0 Then Exit;
  With ObjP(Idx)^ Do Begin X1 := AX1 + 2; Y1 := AY1 + 2; Size := 12; Rgb := 0; Txt := ATxt; End;
  RecalcBox(Idx);
 End
 Else If (Sub = 'Square') Or (Sub = 'Circle') Then Begin
  If Sub = 'Square' Then Idx := NewImpObj(K_RECT) Else Idx := NewImpObj(K_OVAL);
  If Idx < 0 Then Exit;
  With ObjP(Idx)^ Do Begin
   X1 := AX1; Y1 := AY1; X2 := AX2; Y2 := AY2;
   If Col < 0 Then Col := $FF0000;
   Rgb := Col; Rgb2 := ICol; Wd := BW;
   If HasIC Then Fill := 2 Else Fill := 0;
  End;
 End
 Else If Sub = 'Line' Then Begin
  If ReadNums(DictFind(P, 'L'), LA, 4) < 4 Then Exit;
  Idx := NewImpObj(K_LINE);
  If Idx < 0 Then Exit;
  With ObjP(Idx)^ Do Begin
   X1 := PgX(LA[0]); Y1 := PgY(LA[1]); X2 := PgX(LA[2]); Y2 := PgY(LA[3]);
   If Col < 0 Then Col := $FF0000;
   Rgb := Col; Wd := BW;
  End;
 End
 Else If Sub = 'Ink' Then Begin
  V := DictFind(P, 'InkList');
  If V < 0 Then Exit;
  Q := V;
  If NextTok(Q) <> T_AB Then Exit;
  If NextTok(Q) <> T_AB Then Exit;
  Cnt := 0;
  While Cnt < 100 Do Begin
   If NextTok(Q) <> T_NUM Then Break;
   MnX := TokR;
   If NextTok(Q) <> T_NUM Then Break;
   Px[Cnt] := PgX(MnX); Py[Cnt] := PgY(TokR);
   Inc(Cnt);
  End;
  If Cnt < 2 Then Exit;
  Pool := PoolAlloc(Cnt);
  If Pool < 0 Then Exit;
  Idx := NewImpObj(K_INK);
  If Idx < 0 Then Exit;
  For I := 0 To Cnt - 1 Do Begin PoolXP(Pool + I)^ := Px[I]; PoolYP(Pool + I)^ := Py[I]; End;
  If Col < 0 Then Col := $FF0000;
  With ObjP(Idx)^ Do Begin P0 := Pool; PN := Cnt; Rgb := Col; Wd := BW; End;
  RecalcBox(Idx);
 End;
End;

Procedure ImportAnnots(Node: Integer);
Var
 P, V, Q: LongInt;
 N, NR, I: Integer;
 Refs: Array[0..1999] Of Integer;
 AStart, J: LongInt;
 Lc: Word;
Begin
 SrcMode := 0;
 P := EnterObj(Node);
 If P < 0 Then Exit;
 V := DictFind(P, 'Annots');
 If V < 0 Then Exit;
 N := RefAt(V);
 If N > 0 Then V := EnterObj(N);
 If V < 0 Then Exit;
 Q := V;
 If NextTok(Q) <> T_AB Then Exit;
 NR := 0;
 While NR < 2000 Do Begin
  I := RefAt(Q);
  If I > 0 Then Begin Refs[NR] := I; Inc(NR); SkipValue(Q); End
  Else Break;
 End;
 For I := 0 To NR - 1 Do Begin
  If ImpFull Then Break;
  AStart := ObjCount;
  ImpSrcKind := 2;
  ImpAnnNum := Refs[I];
  Lc := XObjLayer(Refs[I]);
  If Lc <> 0 Then MCPush(Lc);
  ImportAnnot(Refs[I]);
  If Lc <> 0 Then MCPop;
  ImpAnnNum := 0;
  For J := AStart To ObjCount - 1 Do ObjP(J)^.SrcCnt := ObjCount - AStart;
  If ImpKeepSrc And (ObjCount > AStart) Then AnnSetMark(Refs[I]);
 End;
 ImpSrcKind := 1;
End;

Procedure ImportPage(Node: Integer; B0, B1, B2, B3: Real; Rot, ResNode: Integer);
Var
 P, V, Q: LongInt;
 N, I, NC, UseRes, FBase, XBase: Integer;
 Refs: Array[0..255] Of Integer;
 L: LongInt;
 W, H: LongInt;
 PStart, J: LongInt;
 S: TSrcState;
 R: Integer;
Begin
 If Not PgEnsure(PageCount + 1) Then Begin
  ImpFull := True;
  LoadNotice := 'Document tronqué : mémoire insuffisante.';
  Exit;
 End;
 Inc(PageCount);
 ImpPg := PageCount;
 FillChar(PgP(ImpPg)^, SizeOf(TPageRec), 0);
 W := RI(Abs(B2 - B0)); H := RI(Abs(B3 - B1));
 If W < 20 Then W := 612;
 If H < 20 Then H := 792;
 If W > 14400 Then W := 14400;
 If H > 14400 Then H := 14400;
 R := Rot;
 While R < 0 Do R := R + 360;
 R := (R Div 90) And 3;
 PgP(ImpPg)^.W := W; PgP(ImpPg)^.H := H; PgP(ImpPg)^.Rot := R; PgP(ImpPg)^.Top := 0;
 If B0 < B2 Then MbX0 := B0 Else MbX0 := B2;
 If B1 > B3 Then MbY1 := B1 Else MbY1 := B3;
 FBase := NFonts; XBase := NXObjs;
 PStart := ObjCount;
 ImpSrcKind := 1; ImpAnnNum := 0;
 If ImpKeepSrc Then Begin
  PgP(ImpPg)^.SrcPage := Node;
  PgP(ImpPg)^.OrigW := W; PgP(ImpPg)^.OrigH := H; PgP(ImpPg)^.OrigRot := R;
  PgP(ImpPg)^.MbX0 := MbX0; PgP(ImpPg)^.MbY1 := MbY1;
 End;
 SrcMode := 0;
 P := EnterObj(Node);
 If P < 0 Then Exit;
 If DictFind(P, 'Resources') >= 0 Then UseRes := Node Else UseRes := ResNode;
 NC := 0;
 V := DictFind(P, 'Contents');
 If V >= 0 Then Begin
  N := RefAt(V);
  If N > 0 Then Begin
   Q := EnterObj(N);
   If Q >= 0 Then Begin
    V := Q;
    SaveSrc(S);
    If NextTok(Q) = T_AB Then Begin
     While NC < 256 Do Begin
      I := RefAt(Q);
      If I > 0 Then Begin Refs[NC] := I; Inc(NC); SkipValue(Q); End
      Else Break;
     End;
    End
    Else Begin Refs[0] := N; NC := 1; End;
   End;
  End
  Else Begin
   Q := V;
   If NextTok(Q) = T_AB Then
    While NC < 256 Do Begin
     I := RefAt(Q);
     If I > 0 Then Begin Refs[NC] := I; Inc(NC); SkipValue(Q); End
     Else Break;
    End;
  End;
 End;
 SrcMode := 0;
 NRes := 0;
 If UseRes > 0 Then LoadResources(UseRes);
 GS.TFont := -1;
 MatIdent(GS.CTM);
 GS.Stroke := 0; GS.Fill := 0; GS.LW := 1;
 GS.Tc := 0; GS.Tw := 0; GS.Th := 1; GS.TL := 0; GS.Ts := 0; GS.TSize := 12; GS.TMode := 0;
 GS.FillCS := 0; GS.StrokeCS := 0; CSCacheFree;
 GS.ClipOn := False; GS.ClipPoly := 0; GS.FillA := 1; GS.StrokeA := 1; GS.Blend := 0; GS.OverP := False; GS.CSPat := False; GS.FillPat := 0;
 NCP := 0; ClipPend := False;
 MCSP := 0; MCOver := 0; CurLayer := 0; PrevName := '';
 MatIdent(TmM); MatIdent(TlmM);
 GSP := 0; NPts := 0; NSub := 0; NOpnd := 0;
 For I := 0 To NC - 1 Do Begin
  If ImpFull Then Break;
  SrcMode := 0;
  If LoadStream(Refs[I], CBufs[0], L) Then Begin
   CLens[0] := L;
   RunContent(0);
  End;
 End;
 FreeFontsTo(FBase);
 NXObjs := XBase;
 PgP(ImpPg)^.SrcCount := ObjCount - PStart;
 If Not ImpFull Then ImportAnnots(Node);
 PgP(ImpPg)^.SrcAnnObjs := ObjCount - PStart - PgP(ImpPg)^.SrcCount;
 SrcMode := 0;
 If ImpKeepSrc Then
  For J := PStart To ObjCount - 1 Do ObjP(J)^.Sum := ObjSum(J);
End;

Procedure WalkPages(Node, Depth: Integer; B0, B1, B2, B3: Real; HaveBox: Boolean; Rot, ResNode: Integer);
Var
 P, V, Q: LongInt;
 Nm: String;
 A: Array[0..3] Of Real;
 N, Base, EndK, I, Kid: Integer;
Begin
 If (Depth > 14) Or ImpFull Then Exit;
 SrcMode := 0;
 P := EnterObj(Node);
 If P < 0 Then Exit;
 Nm := ValName(DictFind(P, 'Type'));
 V := DictFind(P, 'MediaBox');
 If V >= 0 Then If ReadNums(V, A, 4) = 4 Then Begin
  B0 := A[0]; B1 := A[1]; B2 := A[2]; B3 := A[3]; HaveBox := True;
 End;
 V := DictFind(P, 'Rotate');
 If V >= 0 Then Rot := ValInt(V, 0);
 SrcMode := 0;
 P := EnterObj(Node);
 If DictFind(P, 'Resources') >= 0 Then ResNode := Node;
 V := DictFind(P, 'Kids');
 If (V >= 0) And (Nm <> 'Page') Then Begin
  Base := KidSP;
  N := RefAt(V);
  If N > 0 Then V := EnterObj(N);
  If V >= 0 Then Begin
   Q := V;
   If NextTok(Q) = T_AB Then
    While KidSP < 65535 Do Begin
     I := RefAt(Q);
     If I > 0 Then Begin KidStack[KidSP] := I; Inc(KidSP); SkipValue(Q); End
     Else Break;
    End;
  End;
  EndK := KidSP;
  For I := Base To EndK - 1 Do Begin
   If ImpFull Then Break;
   Kid := KidStack[I];
   WalkPages(Kid, Depth + 1, B0, B1, B2, B3, HaveBox, Rot, ResNode);
  End;
  KidSP := Base;
 End
 Else Begin
  If Not HaveBox Then Begin B0 := 0; B1 := 0; B2 := 612; B3 := 792; End;
  ImportPage(Node, B0, B1, B2, B3, Rot, ResNode);
  If (PageCount Mod 4) = 0 Then ShowProgress('Chargement de la page ' + IStr(PageCount) + '...');
 End;
End;

{ Ouvre un fichier PDF. Si Append est vrai, les pages sont ajoutées à la fin. }
{ Texte PDF (PDFDocEncoding ou UTF-16BE) -> Windows }
Function PdfTextToWin(Const S: String): String;
Var
 I: Integer;
 R: String;
Begin
 If (Length(S) >= 2) And (S[1] = #254) And (S[2] = #255) Then Begin
  R := '';
  I := 3;
  While I + 1 <= Length(S) Do Begin
   If Ord(S[I]) = 0 Then R := R + S[I + 1] Else R := R + '?';
   Inc(I, 2);
  End;
  PdfTextToWin := R;
 End
 Else PdfTextToWin := S;
End;

{ Position du dictionnaire /OCProperties (ou -1) }
Function OCPropsPos: LongInt;
Var
 P, V: LongInt;
 N: Integer;
Begin
 OCPropsPos := -1;
 SrcMode := 0;
 If RootNum <= 0 Then Exit;
 P := EnterObj(RootNum);
 If P < 0 Then Exit;
 V := DictFind(P, 'OCProperties');
 If V < 0 Then Exit;
 N := RefAt(V);
 If N > 0 Then V := EnterObj(N);
 OCPropsPos := V;
End;

Function ReadRefList(V: LongInt; Var A: Array Of Integer): Integer;
Var
 Q: LongInt;
 N, I: Integer;
Begin
 ReadRefList := 0;
 If V < 0 Then Exit;
 N := RefAt(V);
 If N > 0 Then V := EnterObj(N);
 If V < 0 Then Exit;
 Q := V;
 If NextTok(Q) <> T_AB Then Exit;
 N := 0;
 While N <= High(A) Do Begin
  I := RefAt(Q);
  If I > 0 Then Begin A[N] := I; Inc(N); SkipValue(Q); End Else Break;
 End;
 ReadRefList := N;
End;

{ Lit les calques (OCG) et leur état initial dans /OCProperties /D }
Procedure LoadLayers;
Var
 Refs: Array[0..1999] Of Integer;
 Lst: Array[0..1999] Of Integer;
 N, I, J, K, M: Integer;
 V, P: LongInt;
 Base: String;
 AllOn: Boolean;
 Nm: String;
Begin
 LayerCount := 0;
 V := OCPropsPos;
 If V < 0 Then Exit;
 N := ReadRefList(DictFind(V, 'OCGs'), Refs);
 If N < 1 Then Exit;
 For I := 0 To N - 1 Do Begin
  SrcMode := 0;
  P := EnterObj(Refs[I]);
  Nm := '';
  If P >= 0 Then Nm := PdfTextToWin(StrAtPos(DictFind(P, 'Name')));
  If Nm = '' Then Nm := 'Calque ' + IStr(I + 1);
  LayerAdd(Refs[I], Nm, True);
 End;
 V := OCPropsPos;
 If V < 0 Then Exit;
 V := DictFind(V, 'D');
 If V < 0 Then Exit;
 K := RefAt(V);
 If K > 0 Then V := EnterObj(K);
 If V < 0 Then Exit;
 Base := ValName(DictFind(V, 'BaseState'));
 If Base = 'OFF' Then
  For I := 0 To LayerCount - 1 Do Layers^[I].On := False;
 { /ON puis /OFF : on relit le dictionnaire à chaque fois (les positions peuvent changer) }
 V := OCPropsPos;
 If V >= 0 Then V := DictFind(V, 'D');
 If V >= 0 Then Begin
  K := RefAt(V);
  If K > 0 Then V := EnterObj(K);
  M := ReadRefList(DictFind(V, 'ON'), Lst);
  For J := 0 To M - 1 Do Begin
   K := LayerFind(Lst[J]);
   If K >= 0 Then Layers^[K].On := True;
  End;
 End;
 V := OCPropsPos;
 If V >= 0 Then V := DictFind(V, 'D');
 If V >= 0 Then Begin
  K := RefAt(V);
  If K > 0 Then V := EnterObj(K);
  M := ReadRefList(DictFind(V, 'OFF'), Lst);
  For J := 0 To M - 1 Do Begin
   K := LayerFind(Lst[J]);
   If K >= 0 Then Layers^[K].On := False;
  End;
 End;
 SrcMode := 0;
End;

Function ImportPDF(Const Name: String; Append: Boolean; Var Err: String): Boolean;
Var
 I, N: Integer;
 P, V: LongInt;
 PagesNum: Integer;
Begin
 ImportPDF := False;
 Err := '';
 LoadNotice := '';
 InitPdfBuffers;
 {$I-}
 Assign(PF, Name);
 Reset(PF, 1);
 {$I+}
 If IOResult <> 0 Then Begin Err := 'Impossible d''ouvrir le fichier.'; Exit; End;
 PFSize := FileSize(PF);
 For I := 0 To PdfCap - 1 Do Begin ObjPos^[I] := -1; ObjStmNo^[I] := 0; ObjStmOff^[I] := 0; ImgByObj^[I] := 0; End;
 DecCap := BUFSZ;
 MaxObjNum := 0; RootNum := 0; InfoNum := 0; StmCacheNum := 0; RBase := -1; RLen := 0; SrcMode := 0;
 NFonts := 0; NXObjs := 0; KidSP := 0; SkippedText := 0;
 ImpFull := False;
 ImpKeepSrc := Not Append;
 If (Not Append) And (AnnSet <> Nil) Then FillChar(AnnSet^, AnnSetCap, 0);
 ImpSrcKind := 1; ImpAnnNum := 0;
 DocEncrypted := False;
 ShowProgress('Analyse du fichier PDF...');
 ScanFile;
 ProcessObjects;
 If DocEncrypted Then Begin
  Err := 'Document chiffré (protégé) : non pris en charge.';
  Close(PF);
  Exit;
 End;
 If (RootNum = 0) And (MaxObjNum = 0) Then Begin
  Err := 'Fichier PDF invalide ou endommagé (aucun objet trouvé).';
  Close(PF);
  Exit;
 End;
 SrcMode := 0;
 PagesNum := 0;
 If RootNum > 0 Then P := EnterObj(RootNum) Else P := -1;
 If P >= 0 Then Begin
  V := DictFind(P, 'Pages');
  If V >= 0 Then PagesNum := RefAt(V);
 End;
 If (PagesNum = 0) And (RootNum = 0) Then Begin
  { réparation : rechercher les objets /Type /Page dans l'ordre du fichier }
  PagesNum := -1;
 End;
 If PagesNum = 0 Then Begin
  Err := 'Arborescence des pages introuvable.';
  Close(PF);
  Exit;
 End;
 If Not Append Then Begin
  FreeImages;
  ObjsFree; PgsFree; PoolFree;
  ObjEnsure(0); PgEnsure(1); PoolEnsure(1);
  LoadLayers;
 End;
 N := PageCount;
 If PagesNum > 0 Then WalkPages(PagesNum, 0, 0, 0, 612, 792, False, 0, 0)
 Else Begin
  For I := 1 To MaxObjNum Do Begin
   If ImpFull Then Break;
   If ObjPos^[I] < 0 Then Continue;
   SrcMode := 0;
   P := ObjPos^[I];
   If ValName(DictFind(P, 'Type')) = 'Page' Then WalkPages(I, 0, 0, 0, 612, 792, False, 0, 0);
  End;
  If PageCount > N Then LoadNotice := 'Fichier endommagé : structure reconstruite, pages récupérées : ' + IStr(PageCount - N) + '.';
 End;
 If PageCount = N Then Begin
  Err := 'Aucune page lisible dans ce document.';
  Close(PF);
  Exit;
 End;
 If Not Append Then Begin
  SrcFile := FExpand(Name);
  SrcValid := True;
  SrcSize := PFSize;
  InfoDirty := False;
  NeedFullRewrite := False;
  If OrigOrder <> Nil Then FreeMem(OrigOrder, (OrigPageCnt + 1) * SizeOf(LongInt));
  OrigPageCnt := PageCount;
  GetMem(OrigOrder, (OrigPageCnt + 1) * SizeOf(LongInt));
  For I := 1 To PageCount Do OrigOrder^[I - 1] := PgP(I)^.SrcPage;
 End;
 If (Not Append) And (InfoNum > 0) Then Begin
  SrcMode := 0;
  P := EnterObj(InfoNum);
  If P >= 0 Then Begin
   DocTitle := Copy(PdfText(StrAtPos(DictFind(P, 'Title'))), 1, 79);
   DocAuthor := Copy(PdfText(StrAtPos(DictFind(P, 'Author'))), 1, 79);
   DocSubject := Copy(PdfText(StrAtPos(DictFind(P, 'Subject'))), 1, 79);
   DocKeywords := Copy(PdfText(StrAtPos(DictFind(P, 'Keywords'))), 1, 79);
   DocCreator := Copy(PdfText(StrAtPos(DictFind(P, 'Creator'))), 1, 79);
  End;
 End;
 If (SkippedText > 0) And (LoadNotice = '') Then
  LoadNotice := IStr(SkippedText) + ' texte(s) pivoté(s) non affiché(s).';
 Close(PF);
 SrcMode := 0;
 ImportPDF := True;
End;

{ ---------------------------------------------------------------------- }
{ Enregistrement incrémental                                                }
{ Le fichier d'origine est recopié tel quel (polices incorporées, liens,   }
{ formulaires, signets, signatures...) ; seules les modifications sont     }
{ ajoutées à la suite, avec une nouvelle table des références.             }
{ ---------------------------------------------------------------------- }

Type
 TRawEnt = Record
  Key: String[63];
  St: TSrcState;
  A, B: LongInt;
  Ref: LongInt;
 End;
 PRawEnt = ^TRawEnt;
 TRawArr = Array[0..4095] Of TRawEnt;
 PRawArr = ^TRawArr;

Var
 IncNext: LongInt;               { prochain numéro d'objet libre }
 IncFontBase: LongInt;           { numéro des 12 polices ajoutées (0 : aucune) }
 IncImgNo: PLArr;
 IncRoot, IncPagesRoot, IncInfo, IncSize, IncPrev: LongInt;
 IncXStream: Boolean;
 IncTreeChanged: Boolean;
 IncPgNo: PLArr;                 { n° d'objet de chaque page du modèle }
 PgFirst, PgIdx: PLArr;          { objets du modèle regroupés par page }
 IncKeep, IncDrop: Array[0..4095] Of LongInt;
 IncKeepN, IncDropN: Integer;
 IncErr: String;

{ Copie brute des octets A..B-1 d'une source }
Procedure CopyRaw(Const St: TSrcState; A, B: LongInt);
Var
 S0: TSrcState;
 Buf: String;
 C: Integer;
 P: LongInt;
Begin
 SaveSrc(S0);
 RestoreSrc(St);
 Buf := '';
 P := A;
 While P < B Do Begin
  C := SB(P);
  If C < 0 Then Break;
  Buf := Buf + Chr(C);
  Inc(P);
  If Length(Buf) >= 200 Then Begin WS(Buf); Buf := ''; End;
 End;
 If Buf <> '' Then WS(Buf);
 RestoreSrc(S0);
End;

{ Entrées de premier niveau d'un dictionnaire (valeur en ValPos, éventuellement indirecte) }
Function CollectDict(ValPos: LongInt; E: PRawArr; Max: Integer): Integer;
Var
 S0: TSrcState;
 N, Cnt, T: Integer;
 P, Q: LongInt;
Begin
 CollectDict := 0;
 If ValPos < 0 Then Exit;
 SaveSrc(S0);
 N := RefAt(ValPos);
 If N > 0 Then P := EnterObj(N) Else P := ValPos;
 Cnt := 0;
 If P >= 0 Then Begin
  Q := P;
  If NextTok(Q) = T_DB Then
   While Cnt < Max Do Begin
    T := NextTok(Q);
    If T <> T_NAME Then Break;
    E^[Cnt].Key := Copy(TokS, 1, 63);
    SaveSrc(E^[Cnt].St);
    E^[Cnt].A := Q;
    SkipValue(Q);
    E^[Cnt].B := Q;
    E^[Cnt].Ref := 0;
    Inc(Cnt);
   End;
 End;
 RestoreSrc(S0);
 CollectDict := Cnt;
End;

{ Éléments d'un tableau (références ou valeurs directes) }
Function CollectArray(Const St: TSrcState; ValPos: LongInt; E: PRawArr; Max: Integer): Integer;
Var
 S0: TSrcState;
 N, Cnt: Integer;
 P, Q, R0: LongInt;
 T: Integer;
Begin
 CollectArray := 0;
 SaveSrc(S0);
 RestoreSrc(St);
 N := RefAt(ValPos);
 If N > 0 Then P := EnterObj(N) Else P := ValPos;
 Cnt := 0;
 If P >= 0 Then Begin
  Q := P;
  If NextTok(Q) = T_AB Then
   While Cnt < Max Do Begin
    R0 := Q;
    T := NextTok(Q);
    If (T = T_AE) Or (T = T_EOF) Then Break;
    Q := R0;
    E^[Cnt].Key := '';
    SaveSrc(E^[Cnt].St);
    E^[Cnt].A := Q;
    E^[Cnt].Ref := RefAt(Q);
    SkipValue(Q);
    E^[Cnt].B := Q;
    Inc(Cnt);
   End;
 End;
 RestoreSrc(S0);
 CollectArray := Cnt;
End;

{ Valeur héritée (MediaBox, Rotate, Resources...) en remontant l'arbre des pages }
Function FindInh(Node: LongInt; Const Key: String; Var E: TRawEnt): Boolean;
Var
 S0: TSrcState;
 D: Integer;
 Cur, P, V, Q: LongInt;
 Par: Integer;
Begin
 FindInh := False;
 SaveSrc(S0);
 Cur := Node;
 For D := 0 To 24 Do Begin
  SrcMode := 0;
  P := EnterObj(Cur);
  If P < 0 Then Break;
  V := DictFind(P, Key);
  If V >= 0 Then Begin
   E.Key := Key;
   SaveSrc(E.St);
   E.A := V;
   Q := V;
   SkipValue(Q);
   E.B := Q;
   E.Ref := 0;
   FindInh := True;
   Break;
  End;
  V := DictFind(P, 'Parent');
  If V < 0 Then Break;
  Par := RefAt(V);
  If Par <= 0 Then Break;
  Cur := Par;
 End;
 RestoreSrc(S0);
End;

Function ObjSubtypeOf(N: LongInt): String;
Var
 S0: TSrcState;
 P: LongInt;
Begin
 ObjSubtypeOf := '';
 SaveSrc(S0);
 SrcMode := 0;
 P := EnterObj(N);
 If P >= 0 Then ObjSubtypeOf := ValName(DictFind(P, 'Subtype'));
 RestoreSrc(S0);
End;

{ Regroupe les objets du modèle par page (tri par comptage) }
Procedure BuildPageLists;
Var
 I, K, Pg: LongInt;
Begin
 GetMem(PgFirst, (PageCount + 3) * SizeOf(LongInt));
 GetMem(PgIdx, (ObjCount + 2) * SizeOf(LongInt));
 FillChar(PgFirst^, (PageCount + 3) * SizeOf(LongInt), 0);
 For I := 0 To ObjCount - 1 Do Begin
  Pg := ObjP(I)^.Page;
  If (Pg >= 1) And (Pg <= PageCount) Then Inc(PgFirst^[Pg + 1]);
 End;
 For I := 1 To PageCount + 1 Do PgFirst^[I] := PgFirst^[I] + PgFirst^[I - 1];
 { PgFirst[p] = début de la page p (p de 1 à PageCount), PgFirst[p+1] = fin }
 For I := 0 To ObjCount - 1 Do Begin
  Pg := ObjP(I)^.Page;
  If (Pg >= 1) And (Pg <= PageCount) Then Begin
   K := PgFirst^[Pg];
   PgIdx^[K] := I;
   Inc(PgFirst^[Pg]);
  End;
 End;
 { remettre les débuts }
 For I := PageCount + 1 DownTo 1 Do PgFirst^[I] := PgFirst^[I - 1];
 PgFirst^[0] := 0;
End;

Procedure FreePageLists;
Begin
 If PgFirst <> Nil Then FreeMem(PgFirst, (PageCount + 3) * SizeOf(LongInt));
 If PgIdx <> Nil Then FreeMem(PgIdx, (ObjCount + 2) * SizeOf(LongInt));
 PgFirst := Nil; PgIdx := Nil;
End;

{ Décision sur les annotations d'origine d'une page : conservées (inchangées)
  ou à réécrire. Remplit IncKeep / IncDrop. }
Procedure DecideAnnots(Pg: LongInt);
Var
 A, B, K, J, N, C: LongInt;
 AllOk: Boolean;
 O, O2: PObjRec;
Begin
 IncKeepN := 0; IncDropN := 0;
 A := PgFirst^[Pg]; B := PgFirst^[Pg + 1];
 For K := A To B - 1 Do Begin
  O := ObjP(PgIdx^[K]);
  If O^.Src <> 2 Then Continue;
  N := O^.SrcNum;
  For J := 0 To IncKeepN - 1 Do If IncKeep[J] = N Then Begin N := -1; Break; End;
  If N < 0 Then Continue;
  For J := 0 To IncDropN - 1 Do If IncDrop[J] = N Then Begin N := -1; Break; End;
  If N < 0 Then Continue;
  C := 0; AllOk := True;
  For J := A To B - 1 Do Begin
   O2 := ObjP(PgIdx^[J]);
   If (O2^.Src = 2) And (O2^.SrcNum = N) Then Begin
    Inc(C);
    If ObjSum(PgIdx^[J]) <> O2^.Sum Then AllOk := False;
   End;
  End;
  If AllOk And (C = O^.SrcCnt) Then Begin
   If IncKeepN < 4096 Then Begin IncKeep[IncKeepN] := N; Inc(IncKeepN); End;
  End
  Else If IncDropN < 4096 Then Begin IncDrop[IncDropN] := N; Inc(IncDropN); End;
 End;
End;

Function InKeep(N: LongInt): Boolean;
Var
 K: Integer;
Begin
 InKeep := False;
 For K := 0 To IncKeepN - 1 Do If IncKeep[K] = N Then Begin InKeep := True; Exit; End;
End;

{ Image XObject (et son masque doux) écrit à la demande }
Function EnsureImg(I: LongInt): LongInt;
Var
 SM, No: LongInt;
Begin
 EnsureImg := 0;
 If Not ImgKept(I) Then Exit;
 If IncImgNo^[I] = 0 Then Begin
  SM := 0;
  If (ImgP(I)^.SMIdx > 0) And ImgKept(ImgP(I)^.SMIdx) Then SM := EnsureImg(ImgP(I)^.SMIdx);
  No := IncNext; Inc(IncNext);
  WriteImageXObj(I, No, SM);
  IncImgNo^[I] := No;
 End;
 EnsureImg := IncImgNo^[I];
End;

{ Écrit un flux de contenu (compressé) pour la page Pg selon le mode ; 0 si vide }
Function WriteContentObj(Pg, Mode: Integer): LongInt;
Var
 Cnt, CompLen, No: LongInt;
 Comp: PByteBuf;
Begin
 WriteContentObj := 0;
 CMode := Mode;
 CapLen := 0;
 If CapBuf = Nil Then Begin CapSize := 65536; GetMem(CapBuf, CapSize); End;
 CapOn := True;
 Cnt := 0;
 ContentOf(Pg, Cnt);
 CapOn := False;
 If CapLen = 0 Then Exit;
 Comp := Nil; CompLen := 0;
 {$IFDEF FPC}
 If CapLen > 64 Then
  If DeflateBuf(CapBuf, CapLen, Comp, CompLen) Then
   If CompLen >= CapLen Then Begin FreeMem(Comp, CapLen + CapLen Div 6 + 128); Comp := Nil; End;
 {$ENDIF}
 No := IncNext; Inc(IncNext);
 BeginObj(No);
 If Comp <> Nil Then Begin
  WL('<< /Length ' + IStr(CompLen) + ' /Filter /FlateDecode >>');
  WL('stream');
  WriteBytes(Comp, CompLen);
  FreeMem(Comp, CapLen + CapLen Div 6 + 128);
 End
 Else Begin
  WL('<< /Length ' + IStr(CapLen) + ' >>');
  WL('stream');
  WriteBytes(CapBuf, CapLen);
 End;
 WL('');
 WL('endstream');
 EndObj;
 WriteContentObj := No;
End;

{ Images utilisées par le contenu émis dans le mode courant : écrit les XObjects }
Procedure CollectPageImages(Pg: Integer; Mode: Integer; Var L: Array Of LongInt; Var N: Integer);
Var
 K, I, J, Idx, Img: LongInt;
 Dup: Boolean;
Begin
 CMode := Mode;
 For K := PgFirst^[Pg] To PgFirst^[Pg + 1] - 1 Do Begin
  Idx := PgIdx^[K];
  If (ObjP(Idx)^.Kind = K_IMAGE) And ObjEmits(ObjP(Idx)^, Idx) Then Begin
   Img := ObjP(Idx)^.P0;
   If ImgKept(Img) Then Begin
    Dup := False;
    For J := 0 To N - 1 Do If L[J] = Img Then Dup := True;
    If (Not Dup) And (N <= High(L)) Then Begin L[N] := Img; Inc(N); EnsureImg(Img); End;
   End;
  End;
 End;
End;

Procedure NeedFonts;
Begin
 If IncFontBase = 0 Then Begin IncFontBase := IncNext; Inc(IncNext, 12); End;
End;

Procedure WriteOurFonts;
Var
 I: Integer;
Begin
 For I := 0 To 11 Do WS(' /AF' + IStr(I + 1) + ' ' + IStr(IncFontBase + I) + ' 0 R');
End;

Procedure WriteOurImages(Const L: Array Of LongInt; N: Integer);
Var
 I: Integer;
Begin
 For I := 0 To N - 1 Do WS(' /AIm' + IStr(L[I]) + ' ' + IStr(IncImgNo^[L[I]]) + ' 0 R');
End;

{ Contenu d'un tableau /Contents : copie des éléments sans les crochets }
Procedure CopyArrayInner(Const St: TSrcState; A, B: LongInt);
Var
 S0: TSrcState;
 P, L, R: LongInt;
 C: Integer;
 Buf: String;
Begin
 SaveSrc(S0);
 RestoreSrc(St);
 P := A; L := -1;
 While P < B Do Begin
  C := SB(P);
  If C = 91 Then Begin L := P; Break; End;
  Inc(P);
 End;
 R := B - 1;
 While R > P Do Begin
  C := SB(R);
  If C = 93 Then Break;
  Dec(R);
 End;
 RestoreSrc(S0);
 If (L >= 0) And (R > L) Then CopyRaw(St, L + 1, R) Else CopyRaw(St, A, B);
End;

Function EntIndex(E: PRawArr; N: Integer; Const Key: String): Integer;
Var
 I: Integer;
Begin
 EntIndex := -1;
 For I := 0 To N - 1 Do If E^[I].Key = Key Then Begin EntIndex := I; Exit; End;
End;

{ Écrit l'objet page numéro PgNo pour la page Pg du modèle }
Procedure WriteIncPage(Pg: Integer);
Var
 PRec: PPageRec;
 NE, NR, NA, NF, I, J, K: Integer;
 PageObj, A, B, FirstOrig, Idx, Cb, Ca, NewAnnCnt: LongInt;
 Flat, IsNew, GeoCh, RotCh, HasNewContent, Merge: Boolean;
 Ents, ResE, SubE: PRawArr;
 Inh: TRawEnt;
 Imgs: Array[0..63] Of LongInt;
 NImg: Integer;
 NewAnn: PLArr;
 OrigAnn: PRawArr;
 NOA: Integer;
 Sub: String;
 O: PObjRec;
 Alive, AnnAlive: LongInt;
 S0: TSrcState;
 X0, Y1v: Real;
 Own: Boolean;
 Skip: Boolean;
Begin
 PRec := PgP(Pg);
 PageObj := IncPgNo^[Pg];
 IsNew := PRec^.SrcPage = 0;
 NImg := 0;
 Cb := 0; Ca := 0;
 NewAnnCnt := 0;
 GetMem(Ents, SizeOf(TRawArr));
 GetMem(ResE, SizeOf(TRawArr));
 GetMem(SubE, SizeOf(TRawArr));
 GetMem(OrigAnn, SizeOf(TRawArr));
 GetMem(NewAnn, (PgFirst^[Pg + 1] - PgFirst^[Pg] + 2) * SizeOf(LongInt));
 NE := 0;
 SaveSrc(S0);
 If Not IsNew Then Begin
  SrcMode := 0;
  A := EnterObj(PRec^.SrcPage);
  NE := CollectDict(A, Ents, 4096);
 End;
 { --- état du contenu d'origine --- }
 CDropN := 0;
 FirstOrig := 0; Alive := 0; AnnAlive := 0;
 Flat := IsNew;
 HasNewContent := False;
 DecideAnnots(Pg);
 If Not IsNew Then Begin
  FirstOrig := -1;
  For K := PgFirst^[Pg] To PgFirst^[Pg + 1] - 1 Do Begin
   Idx := PgIdx^[K];
   O := ObjP(Idx);
   If O^.Src = 1 Then Begin
    If FirstOrig < 0 Then FirstOrig := Idx;
    Inc(Alive);
    If ObjSum(Idx) <> O^.Sum Then Begin
     Flat := True;
    End;
   End;
  End;
  If Alive <> PRec^.SrcCount Then Flat := True;
  If FirstOrig < 0 Then FirstOrig := 0;
 End;
 CFirstOrig := FirstOrig;
 { annotations d'origine à réécrire comme contenu / nouvelles annotations }
 If IncDropN > 0 Then For K := 0 To IncDropN - 1 Do If CDropN < 4096 Then Begin
  If CDrop = Nil Then GetMem(CDrop, 4100 * SizeOf(LongInt));
  CDrop^[CDropN] := IncDrop[K]; Inc(CDropN);
 End;
 If CDrop = Nil Then GetMem(CDrop, 4100 * SizeOf(LongInt));
 { --- images et flux de contenu --- }
 If Flat Then Begin
  CollectPageImages(Pg, 0, Imgs, NImg);
  Ca := WriteContentObj(Pg, 0);
 End
 Else Begin
  CollectPageImages(Pg, 1, Imgs, NImg);
  CollectPageImages(Pg, 2, Imgs, NImg);
  Cb := WriteContentObj(Pg, 1);
  Ca := WriteContentObj(Pg, 2);
 End;
 HasNewContent := (Cb <> 0) Or (Ca <> 0);
 If Flat Or HasNewContent Then NeedFonts;
 { --- annotations nouvelles ou réécrites --- }
 For K := PgFirst^[Pg] To PgFirst^[Pg + 1] - 1 Do Begin
  Idx := PgIdx^[K];
  O := ObjP(Idx);
  If IsAnnot(O^.Kind) Then Begin
   If (O^.Src = 2) And InKeep(O^.SrcNum) Then Continue;
   If O^.Src = 3 Then Continue;
   NewAnn^[NewAnnCnt] := IncNext;
   BeginObj(IncNext); Inc(IncNext);
   WL(AnnotOf(Pg, Idx));
   EndObj;
   Inc(NewAnnCnt);
  End;
 End;
 { --- géométrie --- }
 GeoCh := (Not IsNew) And ((PRec^.W <> PRec^.OrigW) Or (PRec^.H <> PRec^.OrigH));
 RotCh := (Not IsNew) And (PRec^.Rot <> PRec^.OrigRot);
 { --- dictionnaire de la page --- }
 BeginObj(PageObj);
 WS('<< /Type /Page');
 If IncTreeChanged Or IsNew Then WS(' /Parent ' + IStr(IncPagesRoot) + ' 0 R')
 Else Begin
  J := EntIndex(Ents, NE, 'Parent');
  If J >= 0 Then Begin WS(' /Parent'); CopyRaw(Ents^[J].St, Ents^[J].A, Ents^[J].B); End;
 End;
 { MediaBox }
 If IsNew Or GeoCh Then Begin
  If IsNew Then Begin X0 := 0; Y1v := PRec^.H; End Else Begin X0 := PRec^.MbX0; Y1v := PRec^.MbY1; End;
  WS(' /MediaBox [' + RStr(X0) + ' ' + RStr(Y1v - PRec^.H) + ' ' + RStr(X0 + PRec^.W) + ' ' + RStr(Y1v) + ']');
 End
 Else Begin
  J := EntIndex(Ents, NE, 'MediaBox');
  If J >= 0 Then Begin WS(' /MediaBox'); CopyRaw(Ents^[J].St, Ents^[J].A, Ents^[J].B); End
  Else If FindInh(PRec^.SrcPage, 'MediaBox', Inh) Then Begin WS(' /MediaBox'); CopyRaw(Inh.St, Inh.A, Inh.B); End;
 End;
 { Rotate }
 If IsNew Or RotCh Then Begin
  If PRec^.Rot <> 0 Then WS(' /Rotate ' + IStr((PRec^.Rot And 3) * 90));
  If RotCh And (PRec^.Rot = 0) Then WS(' /Rotate 0');
 End
 Else Begin
  J := EntIndex(Ents, NE, 'Rotate');
  If J >= 0 Then Begin WS(' /Rotate'); CopyRaw(Ents^[J].St, Ents^[J].A, Ents^[J].B); End
  Else If FindInh(PRec^.SrcPage, 'Rotate', Inh) Then Begin WS(' /Rotate'); CopyRaw(Inh.St, Inh.A, Inh.B); End;
 End;
 { Contents }
 If Flat Then Begin
  If Ca <> 0 Then WS(' /Contents ' + IStr(Ca) + ' 0 R');
 End
 Else If HasNewContent Then Begin
  WS(' /Contents [');
  If Cb <> 0 Then WS(' ' + IStr(Cb) + ' 0 R');
  J := EntIndex(Ents, NE, 'Contents');
  If J >= 0 Then Begin
   WS(' ');
   CopyArrayInner(Ents^[J].St, Ents^[J].A, Ents^[J].B);
  End;
  If Ca <> 0 Then WS(' ' + IStr(Ca) + ' 0 R');
  WS(' ]');
 End
 Else Begin
  J := EntIndex(Ents, NE, 'Contents');
  If J >= 0 Then Begin WS(' /Contents'); CopyRaw(Ents^[J].St, Ents^[J].A, Ents^[J].B); End;
 End;
 { Resources }
 If Flat Or IsNew Then Begin
  WS(' /Resources << /Font <<');
  WriteOurFonts;
  WS(' >>');
  If NImg > 0 Then Begin WS(' /XObject <<'); WriteOurImages(Imgs, NImg); WS(' >>'); End;
  WS(' >>');
 End
 Else If HasNewContent Then Begin
  Own := EntIndex(Ents, NE, 'Resources') >= 0;
  NR := 0;
  If Own Then Begin
   J := EntIndex(Ents, NE, 'Resources');
   RestoreSrc(Ents^[J].St);
   NR := CollectDict(Ents^[J].A, ResE, 4096);
  End
  Else If FindInh(PRec^.SrcPage, 'Resources', Inh) Then Begin
   RestoreSrc(Inh.St);
   NR := CollectDict(Inh.A, ResE, 4096);
  End;
  WS(' /Resources <<');
  For J := 0 To NR - 1 Do
   If (ResE^[J].Key <> 'Font') And (ResE^[J].Key <> 'XObject') Then Begin
    WS(' /' + ResE^[J].Key);
    CopyRaw(ResE^[J].St, ResE^[J].A, ResE^[J].B);
   End;
  WS(' /Font <<');
  J := EntIndex(ResE, NR, 'Font');
  If J >= 0 Then Begin
   RestoreSrc(ResE^[J].St);
   NF := CollectDict(ResE^[J].A, SubE, 4096);
   For K := 0 To NF - 1 Do Begin WS(' /' + SubE^[K].Key); CopyRaw(SubE^[K].St, SubE^[K].A, SubE^[K].B); End;
  End;
  WriteOurFonts;
  WS(' >>');
  J := EntIndex(ResE, NR, 'XObject');
  If (J >= 0) Or (NImg > 0) Then Begin
   WS(' /XObject <<');
   If J >= 0 Then Begin
    RestoreSrc(ResE^[J].St);
    NF := CollectDict(ResE^[J].A, SubE, 4096);
    For K := 0 To NF - 1 Do Begin WS(' /' + SubE^[K].Key); CopyRaw(SubE^[K].St, SubE^[K].A, SubE^[K].B); End;
   End;
   WriteOurImages(Imgs, NImg);
   WS(' >>');
  End;
  WS(' >>');
  RestoreSrc(S0);
 End
 Else Begin
  J := EntIndex(Ents, NE, 'Resources');
  If J >= 0 Then Begin WS(' /Resources'); CopyRaw(Ents^[J].St, Ents^[J].A, Ents^[J].B); End
  Else If IncTreeChanged Then
   If FindInh(PRec^.SrcPage, 'Resources', Inh) Then Begin WS(' /Resources'); CopyRaw(Inh.St, Inh.A, Inh.B); End;
 End;
 { Annots }
 NOA := 0;
 J := EntIndex(Ents, NE, 'Annots');
 If J >= 0 Then NOA := CollectArray(Ents^[J].St, Ents^[J].A, OrigAnn, 4096);
 If (NOA > 0) Or (NewAnnCnt > 0) Then Begin
  WS(' /Annots [');
  For K := 0 To NOA - 1 Do Begin
   Skip := False;
   If OrigAnn^[K].Ref > 0 Then
    If AnnSetHas(OrigAnn^[K].Ref) And (Not InKeep(OrigAnn^[K].Ref)) Then Skip := True;
   If Not Skip Then Begin
    WS(' ');
    CopyRaw(OrigAnn^[K].St, OrigAnn^[K].A, OrigAnn^[K].B);
   End;
  End;
  For K := 0 To NewAnnCnt - 1 Do WS(' ' + IStr(NewAnn^[K]) + ' 0 R');
  WS(' ]');
 End;
 { autres entrées d'origine }
 For J := 0 To NE - 1 Do Begin
  If (Ents^[J].Key = 'Type') Or (Ents^[J].Key = 'Parent') Or (Ents^[J].Key = 'MediaBox') Or
     (Ents^[J].Key = 'Rotate') Or (Ents^[J].Key = 'Contents') Or (Ents^[J].Key = 'Resources') Or
     (Ents^[J].Key = 'Annots') Then Continue;
  If GeoCh And (Ents^[J].Key = 'CropBox') Then Continue;
  WS(' /' + Ents^[J].Key);
  CopyRaw(Ents^[J].St, Ents^[J].A, Ents^[J].B);
 End;
 WL(' >>');
 EndObj;
 RestoreSrc(S0);
 FreeMem(Ents, SizeOf(TRawArr));
 FreeMem(ResE, SizeOf(TRawArr));
 FreeMem(SubE, SizeOf(TRawArr));
 FreeMem(OrigAnn, SizeOf(TRawArr));
 FreeMem(NewAnn, (PgFirst^[Pg + 1] - PgFirst^[Pg] + 2) * SizeOf(LongInt));
End;

{ La page a-t-elle besoin d'être réécrite ? }
Function PageNeedsWrite(Pg: Integer): Boolean;
Var
 PRec: PPageRec;
 K, Idx, Alive, AnnAlive: LongInt;
 O: PObjRec;
Begin
 PageNeedsWrite := True;
 PRec := PgP(Pg);
 If PRec^.SrcPage = 0 Then Exit;
 If IncTreeChanged Then Exit;
 If (PRec^.W <> PRec^.OrigW) Or (PRec^.H <> PRec^.OrigH) Or (PRec^.Rot <> PRec^.OrigRot) Then Exit;
 Alive := 0; AnnAlive := 0;
 For K := PgFirst^[Pg] To PgFirst^[Pg + 1] - 1 Do Begin
  Idx := PgIdx^[K];
  O := ObjP(Idx);
  Case O^.Src Of
   0: Exit;
   1: Begin
    Inc(Alive);
    If ObjSum(Idx) <> O^.Sum Then Exit;
   End;
   2: Begin
    Inc(AnnAlive);
    If ObjSum(Idx) <> O^.Sum Then Exit;
   End;
  End;
 End;
 If Alive <> PRec^.SrcCount Then Exit;
 If AnnAlive <> PRec^.SrcAnnObjs Then Exit;
 PageNeedsWrite := False;
End;

Procedure SortXList;
Var
 Gap, I, J: LongInt;
 TN, TO_: LongInt;
Begin
 Gap := XCnt Div 2;
 While Gap > 0 Do Begin
  For I := Gap To XCnt - 1 Do Begin
   TN := XList^[I * 2]; TO_ := XList^[I * 2 + 1];
   J := I;
   While (J >= Gap) And (XList^[(J - Gap) * 2] > TN) Do Begin
    XList^[J * 2] := XList^[(J - Gap) * 2];
    XList^[J * 2 + 1] := XList^[(J - Gap) * 2 + 1];
    Dec(J, Gap);
   End;
   XList^[J * 2] := TN; XList^[J * 2 + 1] := TO_;
  End;
  Gap := Gap Div 2;
 End;
End;

Procedure WriteBE(Var Buf: PByteBuf; Var Len: LongInt; V: LongInt; N: Integer);
Var
 I: Integer;
Begin
 For I := N - 1 DownTo 0 Do Begin
  Buf^[Len] := (V Shr (I * 8)) And 255;
  Inc(Len);
 End;
End;

{ Dernier "startxref" du fichier d'origine ; détecte une table ou un flux de références }
Function ReadStartXref(Var Prev: LongInt; Var IsStream: Boolean): Boolean;
Var
 Buf: Array[0..1499] Of Byte;
 N: Integer;
 Got: Word;
 I, J: Integer;
 V: LongInt;
 Sz: LongInt;
 Found: Boolean;
Begin
 ReadStartXref := False;
 Sz := FileSize(PF);
 If Sz > 1500 Then Seek(PF, Sz - 1500) Else Seek(PF, 0);
 Got := 0;
 BlockRead(PF, Buf, 1500, Got);
 N := Got;
 I := N - 9;
 Found := False;
 While I >= 0 Do Begin
  If (Buf[I] = 115) And (Buf[I + 1] = 116) And (Buf[I + 2] = 97) And (Buf[I + 3] = 114) And (Buf[I + 4] = 116) And
     (Buf[I + 5] = 120) And (Buf[I + 6] = 114) And (Buf[I + 7] = 101) And (Buf[I + 8] = 102) Then Begin Found := True; Break; End;
  Dec(I);
 End;
 If Not Found Then Exit;
 J := I + 9;
 While (J < N) And ((Buf[J] < 48) Or (Buf[J] > 57)) Do Inc(J);
 V := 0;
 While (J < N) And (Buf[J] >= 48) And (Buf[J] <= 57) Do Begin V := V * 10 + (Buf[J] - 48); Inc(J); End;
 Prev := V;
 SrcMode := 0;
 RBase := -1; RLen := 0;
 J := V;
 While IsWs(SB(J)) Do Inc(J);
 IsStream := Not ((SB(J) = 120) And (SB(J + 1) = 114) And (SB(J + 2) = 101) And (SB(J + 3) = 102));
 ReadStartXref := True;
End;

Procedure WriteXrefSection(Var StartPos: LongInt; Const IDRaw: TRawEnt; HasID: Boolean);
Var
 I, RunStart, RunN: LongInt;
 S: String;
 XNo: LongInt;
 Buf: PByteBuf;
 Len: LongInt;
 Last: LongInt;
 SzVal: LongInt;
Begin
 If IncXStream Then Begin
  XNo := IncNext; Inc(IncNext);
  IncAdd(XNo, OutPos);
 End;
 SortXList;
 SzVal := IncNext;
 If IncXStream Then Begin
  GetMem(Buf, XCnt * 7 + 64);
  Len := 0;
  For I := 0 To XCnt - 1 Do Begin
   Buf^[Len] := 1; Inc(Len);
   WriteBE(Buf, Len, XList^[I * 2 + 1], 4);
   WriteBE(Buf, Len, 0, 2);
  End;
  StartPos := OutPos;
  WL(IStr(XNo) + ' 0 obj');
  WS('<< /Type /XRef /Size ' + IStr(SzVal) + ' /W [1 4 2] /Index [');
  I := 0;
  While I < XCnt Do Begin
   RunStart := XList^[I * 2];
   RunN := 1;
   While (I + RunN < XCnt) And (XList^[(I + RunN) * 2] = RunStart + RunN) Do Inc(RunN);
   WS(IStr(RunStart) + ' ' + IStr(RunN) + ' ');
   I := I + RunN;
  End;
  S := '] /Root ' + IStr(IncRoot) + ' 0 R /Prev ' + IStr(IncPrev);
  If IncInfo > 0 Then S := S + ' /Info ' + IStr(IncInfo) + ' 0 R';
  WS(S);
  If HasID Then Begin WS(' /ID'); CopyRaw(IDRaw.St, IDRaw.A, IDRaw.B); End;
  WL(' /Length ' + IStr(Len) + ' >>');
  WL('stream');
  WriteBytes(Buf, Len);
  WL('');
  WL('endstream');
  WL('endobj');
  FreeMem(Buf, XCnt * 7 + 64);
 End
 Else Begin
  StartPos := OutPos;
  WL('xref');
  I := 0;
  While I < XCnt Do Begin
   RunStart := XList^[I * 2];
   RunN := 1;
   While (I + RunN < XCnt) And (XList^[(I + RunN) * 2] = RunStart + RunN) Do Inc(RunN);
   WL(IStr(RunStart) + ' ' + IStr(RunN));
   For Last := 0 To RunN - 1 Do Begin
    S := IStr(XList^[(I + Last) * 2 + 1]);
    While Length(S) < 10 Do S := '0' + S;
    WL(S + ' 00000 n ');
   End;
   I := I + RunN;
  End;
  WL('trailer');
  S := '<< /Size ' + IStr(SzVal) + ' /Root ' + IStr(IncRoot) + ' 0 R /Prev ' + IStr(IncPrev);
  If IncInfo > 0 Then S := S + ' /Info ' + IStr(IncInfo) + ' 0 R';
  WS(S);
  If HasID Then Begin WS(' /ID'); CopyRaw(IDRaw.St, IDRaw.A, IDRaw.B); End;
  WL(' >>');
 End;
End;

Procedure PdfInfoObj(No: LongInt);
Var
 S: String;
Begin
 BeginObj(No);
 S := '<< /Producer (CloneDRAW Acrodoc) /ModDate (' + PdfDate + ')';
 If DocTitle <> '' Then S := S + ' /Title ' + PdfStr(DocTitle);
 If DocAuthor <> '' Then S := S + ' /Author ' + PdfStr(DocAuthor);
 If DocSubject <> '' Then S := S + ' /Subject ' + PdfStr(DocSubject);
 If DocKeywords <> '' Then S := S + ' /Keywords ' + PdfStr(DocKeywords);
 If DocCreator <> '' Then S := S + ' /Creator ' + PdfStr(DocCreator);
 WL(S + ' >>');
 EndObj;
End;

Function SaveIncremental(Const OutName: String; Var Err: String): Boolean;
Var
 I, Pg: LongInt;
 TmpName: String;
 Buf: PByteBuf;
 Got: Word;
 Done: LongInt;
 P, V, Q: LongInt;
 MaxN: LongInt;
 TrP: LongInt;
 IDEnt: TRawEnt;
 HasID: Boolean;
 XStart: LongInt;
 Ok: Boolean;
 PagesNum: LongInt;
 SrcSz: LongInt;
Begin
 SaveIncremental := False;
 Err := '';
 If (Not SrcValid) Or (SrcFile = '') Or (Not FileExists(SrcFile)) Then Begin Err := 'Fichier d''origine introuvable.'; Exit; End;
 InitPdfBuffers;
 {$I-}
 Assign(PF, SrcFile);
 Reset(PF, 1);
 {$I+}
 If IOResult <> 0 Then Begin Err := 'Impossible de relire le fichier d''origine.'; Exit; End;
 PFSize := FileSize(PF);
 If PFSize <> SrcSize Then Begin
  Close(PF);
  Err := 'Le fichier d''origine a été modifié depuis son ouverture.';
  Exit;
 End;
 For I := 0 To PdfCap - 1 Do Begin ObjPos^[I] := -1; ObjStmNo^[I] := 0; ObjStmOff^[I] := 0; End;
 MaxObjNum := 0; RootNum := 0; InfoNum := 0; StmCacheNum := 0; RBase := -1; RLen := 0; SrcMode := 0;
 DocEncrypted := False;
 NFonts := 0; NXObjs := 0;
 ScanFile;
 ProcessObjects;
 If DocEncrypted Or (RootNum = 0) Then Begin Close(PF); Err := 'Structure du fichier d''origine non exploitable.'; Exit; End;
 SrcMode := 0;
 If Not ReadStartXref(IncPrev, IncXStream) Then Begin Close(PF); Err := 'Table des références introuvable.'; Exit; End;
 IncRoot := RootNum;
 { arbre des pages }
 SrcMode := 0;
 P := EnterObj(RootNum);
 IncPagesRoot := 0;
 If P >= 0 Then Begin V := DictFind(P, 'Pages'); If V >= 0 Then IncPagesRoot := RefAt(V); End;
 If IncPagesRoot = 0 Then Begin Close(PF); Err := 'Arbre des pages introuvable.'; Exit; End;
 { trailer d'origine : /Size et /ID }
 HasID := False;
 IncSize := MaxObjNum + 1;
 SrcMode := 0;
 TrP := -1;
 If IncXStream Then Begin If XRefBest > 0 Then TrP := ObjPos^[XRefBest]; End
 Else If TrCount > 0 Then TrP := TrPos[TrCount - 1];
 If TrP >= 0 Then Begin
  V := DictFind(TrP, 'Size');
  If V >= 0 Then Begin I := ValInt(V, 0); If I > IncSize Then IncSize := I; End;
  V := DictFind(TrP, 'ID');
  If V >= 0 Then Begin
   HasID := True;
   IDEnt.Key := 'ID'; SaveSrc(IDEnt.St); IDEnt.A := V; Q := V; SkipValue(Q); IDEnt.B := Q;
  End;
 End;
 IncInfo := InfoNum;
 { préparation }
 BuildPageLists;
 GetMem(IncPgNo, (PageCount + 2) * SizeOf(LongInt));
 GetMem(IncImgNo, (ImgCount + 2) * SizeOf(LongInt));
 FillChar(IncImgNo^, (ImgCount + 2) * SizeOf(LongInt), 0);
 IncNext := IncSize;
 IncFontBase := 0;
 IncTreeChanged := PageCount <> OrigPageCnt;
 For Pg := 1 To PageCount Do
  If (Pg <= OrigPageCnt) And (PgP(Pg)^.SrcPage <> OrigOrder^[Pg - 1]) Then IncTreeChanged := True;
 For Pg := 1 To PageCount Do
  If PgP(Pg)^.SrcPage = 0 Then IncTreeChanged := True;
 For Pg := 1 To PageCount Do
  If PgP(Pg)^.SrcPage > 0 Then IncPgNo^[Pg] := PgP(Pg)^.SrcPage
  Else Begin IncPgNo^[Pg] := IncNext; Inc(IncNext); End;
 { fichier de sortie : copie de l'original dans un fichier temporaire }
 TmpName := OutName + '.tmp';
 {$I-}
 Assign(OutF, TmpName);
 Rewrite(OutF, 1);
 {$I+}
 If IOResult <> 0 Then Begin
  Close(PF); FreePageLists; FreeMem(IncPgNo, (PageCount + 2) * SizeOf(LongInt));
  FreeMem(IncImgNo, (ImgCount + 2) * SizeOf(LongInt));
  Err := 'Impossible de créer le fichier de sortie.'; Exit;
 End;
 OutErr := False; OutPos := 0;
 GetMem(Buf, 32768);
 Seek(PF, 0);
 Done := 0;
 While Done < PFSize Do Begin
  Got := 0;
  BlockRead(PF, Buf^, 32768, Got);
  If Got = 0 Then Break;
  {$I-}
  BlockWrite(OutF, Buf^, Got);
  {$I+}
  If IOResult <> 0 Then OutErr := True;
  Done := Done + Got;
 End;
 FreeMem(Buf, 32768);
 OutPos := Done;
 RBase := -1; RLen := 0;
 IncMode := True;
 XCnt := 0;
 If XList = Nil Then Begin XCap := 1024; GetMem(XList, XCap * 2 * SizeOf(LongInt)); End;
 FPre := 'AF'; IPre := 'AIm';
 If CDrop = Nil Then GetMem(CDrop, 4100 * SizeOf(LongInt));
 { séparateur }
 WL('');
 { pages }
 For Pg := 1 To PageCount Do Begin
  If OutErr Then Break;
  If PageNeedsWrite(Pg) Then WriteIncPage(Pg);
 End;
 { racine de l'arbre des pages }
 If (Not OutErr) And IncTreeChanged Then Begin
  BeginObj(IncPagesRoot);
  WS('<< /Type /Pages /Count ' + IStr(PageCount) + ' /Kids [');
  For Pg := 1 To PageCount Do Begin
   WS(' ' + IStr(IncPgNo^[Pg]) + ' 0 R');
  End;
  WL(' ] >>');
  EndObj;
 End;
 { polices ajoutées }
 If IncFontBase > 0 Then WriteFontObjs(IncFontBase);
 { informations du document }
 If InfoDirty Or (XCnt = 0) Then Begin
  If IncInfo = 0 Then Begin IncInfo := IncNext; Inc(IncNext); End;
  PdfInfoObj(IncInfo);
 End;
 WriteXrefSection(XStart, IDEnt, HasID);
 WL('startxref');
 WL(IStr(XStart));
 WL('%%EOF');
 {$I-}
 Close(OutF);
 {$I+}
 If IOResult <> 0 Then OutErr := True;
 IncMode := False;
 FreePageLists;
 FreeMem(IncPgNo, (PageCount + 2) * SizeOf(LongInt));
 FreeMem(IncImgNo, (ImgCount + 2) * SizeOf(LongInt));
 If CapBuf <> Nil Then Begin FreeMem(CapBuf, CapSize); CapBuf := Nil; End;
 Close(PF);
 CMode := 0; CDropN := 0; FPre := 'F'; IPre := 'Im';
 If OutErr Then Begin
  {$I-} Erase(OutF); {$I+}
  If IOResult <> 0 Then ;
  Err := 'Erreur d''écriture.';
  Exit;
 End;
 { remplacement du fichier de destination }
 If FileExists(OutName) Then Begin
  {$I-}
  Assign(OutF, OutName);
  Erase(OutF);
  {$I+}
  If IOResult <> 0 Then Begin Err := 'Impossible de remplacer le fichier de destination.'; Exit; End;
 End;
 {$I-}
 Assign(OutF, TmpName);
 Rename(OutF, OutName);
 {$I+}
 If IOResult <> 0 Then Begin Err := 'Impossible de renommer le fichier enregistré.'; Exit; End;
 SaveIncremental := True;
End;

{ ---------------------------------------------------------------------- }
{ Interface : primitives                                                    }
{ ---------------------------------------------------------------------- }

Const
 PathSep = {$IFDEF FPC} DirectorySeparator {$ELSE} '\' {$ENDIF};
 ZoomSteps: Array[0..11] Of Integer = (25, 33, 50, 63, 75, 100, 125, 150, 200, 300, 400, 800);

Procedure AcBevel(X1, Y1, X2, Y2: Integer; Raised: Boolean);
Begin
 If Raised Then SetColor(White) Else SetColor(Black);
 Line(X1, Y1, X2 - 1, Y1);
 Line(X1, Y1, X1, Y2 - 1);
 If Raised Then SetColor(Black) Else SetColor(White);
 Line(X2, Y1, X2, Y2);
 Line(X1, Y2, X2, Y2);
 If Raised Then SetColor(DarkGray) Else SetColor(DarkGray);
 If Raised Then Begin
  Line(X2 - 1, Y1 + 1, X2 - 1, Y2 - 1);
  Line(X1 + 1, Y2 - 1, X2 - 1, Y2 - 1);
 End;
End;

Procedure Panel(X1, Y1, X2, Y2: Integer; Raised: Boolean);
Begin
 SetFillStyle(SolidFill, LightGray);
 Bar(X1, Y1, X2, Y2);
 AcBevel(X1, Y1, X2, Y2, Raised);
End;

Procedure Field3D(X1, Y1, X2, Y2: Integer);
Begin
 SetFillStyle(SolidFill, White);
 Bar(X1, Y1, X2, Y2);
 SetColor(DarkGray);
 Line(X1, Y1, X2, Y1);
 Line(X1, Y1, X1, Y2);
 SetColor(Black);
 Line(X1 + 1, Y1 + 1, X2 - 1, Y1 + 1);
 Line(X1 + 1, Y1 + 1, X1 + 1, Y2 - 1);
 SetColor(White);
 Line(X2, Y1, X2, Y2);
 Line(X1, Y2, X2, Y2);
End;

Var
 Dirty : Boolean;

{ ================================================================== }
{ OS/2-0 : BOITES DE DIALOGUE NATIVES DE PRESENTATION MANAGER         }
{ ================================================================== }
{ La version DOS dessinait elle-meme ses boites (cadre, champ de      }
{ saisie, boutons, barres de defilement) et lisait clavier et souris  }
{ dans sa propre boucle. Ici ce sont de vraies fenetres de PM :       }
{  - saisie : boite modale avec un champ de saisie (WC_ENTRYFIELD) et }
{    les boutons OK / Annuler (WC_BUTTON) ;                           }
{  - resultats : fenetre modale dont le texte defile avec deux barres }
{    de defilement de PM (WC_SCROLLBAR), boutons Enregistrer et       }
{    Fermer ;                                                         }
{  - messages et questions : WinMessageBox.                           }
{ Pendant une boite modale, la fenetre qui l'a ouverte est desactivee }
{ (WinEnableWindow) et les messages sont distribues par WinGetMsg.    }

Const
 WC_BUTTON = $FFFF0003; WC_STATIC = $FFFF0005; WC_ENTRYFIELD = $FFFF0006;
 WC_LISTBOX = $FFFF0007; WC_SCROLLBAR = $FFFF0008;
 WS_VISIBLE = $80000000; WS_TABSTOP = $00020000; WS_GROUP = $00010000;
 BS_PUSHBUTTON = 0; BS_DEFAULT = $0400;
 ES_AUTOSCROLL = 4; ES_MARGIN = 8;
 SBS_HORZ = 0; SBS_VERT = 1;
 EM_SETTEXTLIMIT = $0143; EM_SETSEL = $0142;
 SBM_SETSCROLLBAR = $01A0; SBM_SETPOS = $01A1; SBM_SETTHUMBSIZE = $01A6;
 LM_QUERYITEMCOUNT = $0160; LM_INSERTITEM = $0161; LM_SETTOPINDEX = $0162;
 LM_SELECTITEM = $0164; LM_QUERYSELECTION = $0165; LM_QUERYTOPINDEX = $016D;
 LM_DELETEALL = $016E;
 LN_SELECT = 1; LN_ENTER = 5;
 WM_CREATE = $0001; WM_CONTROL = $0030; WM_VSCROLL = $0031; WM_HSCROLL = $0032;
 SB_LINEUP = 1; SB_LINEDOWN = 2; SB_PAGEUP = 3; SB_PAGEDOWN = 4;
 SB_SLIDERTRACK = 5; SB_SLIDERPOSITION = 6;
 CLR_PMWHITE = -2; CLR_PMBLACK = -1; CLR_PMBLUE = 1; CLR_PMDARKBLUE = 9;
 CLR_PALEGRAY = 15;
 ID_POK = 1; ID_PCANCEL = 2; ID_PSAVE = 3; ID_PEF = 20; ID_PVSB = 21; ID_PHSB = 22;
 PmChW = 8; PmChH = 16;

Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External 'PMWIN';
Function WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External 'PMWIN';
Function WinFillRect(Hps, P, C : LongInt) : LongInt; External 'PMWIN';
Function WinDrawText(Hps, Cch, P, PR, Fg, Bg, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';

Var
 PmTopFr : LongInt;                       { fenetre qui recoit la saisie }
 PmLevel : LongInt;                       { profondeur des boites modales }
 PmEnd : Array[0..7] Of LongInt;          { 0 : ouverte, 1 : OK, 2 : annulee }
 PmClsDone, RsClsDone : Boolean;
 { boite de saisie }
 InFr, InCl, InEf : LongInt;
 InP1, InP2, InVal : String;
 InMax : LongInt;
 { fenetre des resultats }
 RsFr, RsCl, RsVsb, RsHsb : LongInt;
 RsTop, RsLeft, RsRows, RsCols, RsMaxLen : LongInt;

Function PmLo(V : LongInt) : LongInt;
Begin
 PmLo := V And $FFFF;
End;

Function PmHi(V : LongInt) : LongInt;
Begin
 PmHi := (V Shr 16) And $FFFF;
End;

Function PmS16(V : LongInt) : LongInt;
Begin
 V := V And $FFFF;
 If V >= $8000 Then V := V - $10000;
 PmS16 := V;
End;

{ texte d'une ligne dans une zone de dessin (Y compte depuis le haut) }
Procedure PmText(Hps, Hh, X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
 If S = '' Then Exit;
 PutZ(LongInt(@TxtBuf), S);
 Rc[0] := X; Rc[1] := Hh - Y - PmChH; Rc[2] := X + Length(S) * PmChW; Rc[3] := Hh - Y;
 Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

{ cadre de fenetre de dialogue de la taille de zone client W x H, centre
  sur la fenetre principale }
Function PmOpenBox(Cls, Title : String; W, H : LongInt; Var Cl : LongInt) : LongInt;
Var Fl, Fr, Sw, Sh, X, Y : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
 Cl := 0;
 Fr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), OsZ(Cls), OsZ2(Title), 0, 0, 0, LongInt(@Cl));
 If Fr <> 0 Then
 Begin
  Rc[0] := 0; Rc[1] := 0; Rc[2] := W; Rc[3] := H;
  Dummy := WinCalcFrameRect(Fr, LongInt(@Rc), 0);
  W := Rc[2] - Rc[0]; H := Rc[3] - Rc[1];
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  X := (Sw - W) Div 2; Y := (Sh - H) Div 2;
  If X < 0 Then X := 0;
  If Y < 0 Then Y := 0;
  Dummy := WinSetWindowPos(Fr, HWND_TOP, X, Y, W, H,
    SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Fr);
 End;
 PmOpenBox := Fr;
End;

{ boucle modale : la fenetre Fr recoit la saisie jusqu'a PmEnd[niveau] }
Function PmModal(Fr, Focus, Ef : LongInt) : LongInt;
Var Prev, Lv, N : LongInt; Buf : Array[0..259] Of Byte;
Begin
 FlushScreen;
 If PmTopFr = 0 Then PmTopFr := OsFrame;
 Prev := PmTopFr;
 Inc(PmLevel); Lv := PmLevel;
 PmEnd[Lv] := 0;
 { la fenetre qui avait la souris (clic en cours) la rend }
 Dummy := WinSetCapture(HWND_DESKTOP, 0);
 MBtn := 0; MLatch := 0;
 Dummy := WinEnableWindow(Prev, 0);
 PmTopFr := Fr;
 If Focus <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, Focus);
 While PmEnd[Lv] = 0 Do
 Begin
  If WinGetMsg(OsHab, LongInt(@Qmsg), 0, 0, 0) = 0 Then
  Begin
   CmdPush(CMD_CLOSE);
   PmEnd[Lv] := 2;
  End
  Else Dummy := WinDispatchMsg(OsHab, LongInt(@Qmsg));
 End;
 PmModal := PmEnd[Lv];
 { texte du champ de saisie, lu avant la destruction de la boite }
 If (Ef <> 0) And (PmEnd[Lv] = 1) Then
 Begin
  N := WinQueryWindowText(Ef, 252, LongInt(@Buf));
  If N < 0 Then N := 0;
  InVal := '';
  While (Length(InVal) < N) And (Buf[Length(InVal)] <> 0) Do InVal := InVal + Chr(Buf[Length(InVal)]);
 End;
 Dec(PmLevel);
 Dummy := WinEnableWindow(Prev, 1);
 PmTopFr := Prev;
 { la fenetre d'origine redevient active (barre de titre) avant que la
   boite disparaisse }
 Dummy := WinSetActiveWindow(HWND_DESKTOP, Prev);
 If Prev = OsFrame Then Dummy := WinSetFocus(HWND_DESKTOP, OsClient);
 Dummy := WinDestroyWindow(Fr);
End;

Procedure PmDone(V : LongInt);
Begin
 If PmLevel > 0 Then PmEnd[PmLevel] := V;
End;

{ Entree et Echap remontes par les controles de la boite }
Function PmDlgKey(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Vk : LongInt;
Begin
 Fl := PmLo(Mp1); Vk := PmHi(Mp2);
 PmDlgKey := 1;
 If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And
    ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then PmDone(1)
 Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then PmDone(2)
 Else PmDlgKey := WinDefWindowProc(H, Msg, Mp1, Mp2);
End;

{ --- boite de saisie --- }

Function InputProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, W, Y : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 InputProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, 0);
    Dummy := WinQueryWindowRect(H, LongInt(@Rc));
    Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
    Y := 8;
    PmText(Hps, Rc[3], 12, Y, InP1, CLR_PMBLACK, CLR_PALEGRAY);
    If InP2 <> '' Then PmText(Hps, Rc[3], 12, Y + PmChH, InP2, CLR_PMBLACK, CLR_PALEGRAY);
    Dummy := WinEndPaint(Hps);
   End;
  WM_COMMAND :
   If PmLo(Mp1) = ID_POK Then PmDone(1) Else If PmLo(Mp1) = ID_PCANCEL Then PmDone(2);
  WM_CHAR : InputProc := PmDlgKey(H, Msg, Mp1, Mp2);
  WM_CLOSE : PmDone(2);
 Else
  InputProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

{ controles de la boite de saisie (zone client W de large) }
Procedure InControls(H, W : LongInt);
Begin
 InEf := WinCreateWindow(H, WC_ENTRYFIELD, 0, WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN,
   12, 44, W - 24, 20, H, HWND_TOP, ID_PEF, 0, 0);
 Dummy := WinSendMsg(InEf, EM_SETTEXTLIMIT, InMax, 0);
 Dummy := WinCreateWindow(H, WC_BUTTON, OsZ('OK'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
   W - 196, 8, 88, 26, H, HWND_TOP, ID_POK, 0, 0);
 Dummy := WinCreateWindow(H, WC_BUTTON, OsZ('Annuler'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
   W - 100, 8, 88, 26, H, HWND_TOP, ID_PCANCEL, 0, 0);
End;

Procedure PmRegister;
Begin
 If PmClsDone Then Exit;
 PmClsDone := True;
 Dummy := WinRegisterClass(OsHab, OsZ('ASTROIN'), LongInt(@InputProc), 0, 0);
End;

{ coupe un texte trop long en deux lignes (a un espace) }
Procedure PmSplit(S : String; Max : LongInt; Var A, B : String);
Var K : LongInt;
Begin
 A := S; B := '';
 If Length(S) <= Max Then Exit;
 K := Max;
 While (K > 1) And (S[K] <> ' ') Do Dec(K);
 If K <= 1 Then K := Max;
 A := Copy(S, 1, K);
 B := Copy(S, K + 1, 255);
 While (B <> '') And (B[1] = ' ') Do Delete(B, 1, 1);
 If Length(B) > Max Then B := Copy(B, 1, Max);
End;

Function PmInput(Title, Prompt : String; Var S : String; MaxLen : LongInt) : Boolean;
Var W, H, L, R : LongInt;
Begin
 PmRegister;
 PmSplit(Prompt, 70, InP1, InP2);
 L := Length(InP1);
 If Length(InP2) > L Then L := Length(InP2);
 W := L * PmChW + 24;
 If W < 380 Then W := 380;
 If W < Length(Title) * PmChW + 80 Then W := Length(Title) * PmChW + 80;
 If W > 600 Then W := 600;
 H := 96;
 If InP2 <> '' Then H := H + PmChH;
 If MaxLen < 1 Then MaxLen := 1;
 If MaxLen > 250 Then MaxLen := 250;
 InMax := MaxLen;
 InFr := PmOpenBox('ASTROIN', Title, W, H, InCl);
 If InFr = 0 Then
 Begin
  PmInput := False;
  Exit;
 End;
 InControls(InCl, W);
 Dummy := WinSetWindowText(InEf, OsZ(S));
 Dummy := WinSendMsg(InEf, EM_SETSEL, Length(S) Shl 16, 0);
 R := PmModal(InFr, InEf, InEf);
 If R = 1 Then S := InVal;
 PmInput := R = 1;
End;


{ ================================================================== }
{ OS/2-0 : BOITE DE FICHIERS DE PRESENTATION MANAGER                  }
{ ================================================================== }
{ Remplace les selecteurs de fichiers dessines par les versions DOS :  }
{ champ du nom (WC_ENTRYFIELD), repertoire courant, liste de PM        }
{ (WC_LISTBOX) des repertoires puis des fichiers du masque (plusieurs  }
{ masques separes par ';'), boutons Ouvrir/Enregistrer et Annuler.     }
{ Double clic (ou Entree) sur un repertoire : on y entre ; sur un      }
{ fichier : il est choisi. Un nom avec * ou ? change le masque.        }

Const
 ID_FLIST = 30; ID_FDIR = 31;

Function FdSetPP(H, Id, Cb, P : LongInt) : LongInt; External 'PMWIN' Name 'WINSETPRESPARAM';

Var
 FdFr, FdCl, FdEf, FdLb, FdDl : LongInt;
 FdDir, FdMask, FdRes : String;
 FdN : Integer;
 FdItem : Array[0..511] Of String[64];
 FdClsDone, FdSave : Boolean;

Function FdUp(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do S[I]:=UpCase(S[I]);
 FdUp:=S;
End;

{ le nom N correspond-il au masque M (* et ?) }
Function FdMatch(N, M: String): Boolean;
Var I, J, SI, SJ: Integer;
Begin
 N:=FdUp(N);M:=FdUp(M);
 I:=1;J:=1;SI:=0;SJ:=0;
 While I<=Length(N) Do Begin
  If (J<=Length(M)) And ((M[J]='?') Or (M[J]=N[I])) Then Begin Inc(I);Inc(J);End
  Else If (J<=Length(M)) And (M[J]='*') Then Begin SJ:=J;SI:=I;Inc(J);End
  Else If SJ>0 Then Begin J:=SJ+1;Inc(SI);I:=SI;End
  Else Begin FdMatch:=False;Exit;End;
 End;
 While (J<=Length(M)) And (M[J]='*') Do Inc(J);
 FdMatch:=J>Length(M);
End;

Function FdMaskOk(N: String): Boolean;
Var M, P: String; K: Integer;
Begin
 FdMaskOk:=False;
 M:=FdMask;
 If M='' Then M:='*.*';
 While M<>'' Do Begin
  K:=Pos(';',M);
  If K=0 Then Begin P:=M;M:='';End Else Begin P:=Copy(M,1,K-1);Delete(M,1,K);End;
  If (P='*.*') Or (P='*') Or FdMatch(N,P) Then Begin FdMaskOk:=True;Exit;End;
 End;
End;

Function FdText(H: LongInt): String;
Var Buf: Array[0..259] Of Byte; N, K: LongInt; S: String;
Begin
 N:=WinQueryWindowText(H,250,LongInt(@Buf));
 S:='';K:=0;
 While (K<N) And (Buf[K]<>0) Do Begin S:=S+Chr(Buf[K]);Inc(K);End;
 FdText:=S;
End;

Procedure FdAdd(S: String);
Begin
 If FdN>511 Then Exit;
 FdItem[FdN]:=S;Inc(FdN);
 Dummy:=WinSendMsg(FdLb,LM_INSERTITEM,-1,OsZ(S));
End;

{ repertoires puis fichiers du masque, tries par ordre alphabetique }
Procedure FdFill;
Var SR: SearchRec; N: String; Pass: Integer;
Begin
 Dummy:=WinSendMsg(FdLb,LM_DELETEALL,0,0);
 FdN:=0;
 If Length(FdDir)>3 Then FdAdd('[..]');
 For Pass:=1 To 2 Do Begin
  FindFirst(FdDir+'*.*',AnyFile,SR);
  While DosError=0 Do Begin
   N:=SR.Name;
   If (N<>'.') And (N<>'..') Then Begin
    If Pass=1 Then Begin
     If (SR.Attr And Directory)<>0 Then FdAdd('['+N+']');
    End Else If ((SR.Attr And Directory)=0) And FdMaskOk(N) Then FdAdd(N);
   End;
   FindNext(SR);
  End;
 End;
 Dummy:=WinSetWindowText(FdDl,OsZ(FdDir+FdMask));
End;

Procedure FdEnter(D: String);
Var K: Integer;
Begin
 If D='..' Then Begin
  K:=Length(FdDir)-1;
  While (K>0) And (FdDir[K]<>'\') Do Dec(K);
  If K>0 Then FdDir:=Copy(FdDir,1,K);
 End Else FdDir:=FdDir+D+'\';
 FdFill;
End;

{ choix du nom S (champ ou liste) : True si la boite est finie }
Function FdChoose(S: String): Boolean;
Var SR: SearchRec;
Begin
 FdChoose:=False;
 While (S<>'') And (S[1]=' ') Do Delete(S,1,1);
 While (S<>'') And (S[Length(S)]=' ') Do Delete(S,Length(S),1);
 If S='' Then Exit;
 If (S[1]='[') And (S[Length(S)]=']') Then Begin
  FdEnter(Copy(S,2,Length(S)-2));Exit;
 End;
 If (Pos('*',S)>0) Or (Pos('?',S)>0) Then Begin
  FdMask:=S;FdFill;Exit;
 End;
 If (Length(S)=2) And (S[2]=':') Then S:=S+'\';
 If (Pos(':',S)=0) And (S[1]<>'\') Then S:=FdDir+S
 Else If S[1]='\' Then S:=Copy(FdDir,1,2)+S;
 If S[Length(S)]='\' Then Begin FdDir:=S;FdFill;Exit;End;
 FindFirst(S,Directory,SR);
 If (DosError=0) And ((SR.Attr And Directory)<>0) Then Begin
  FdDir:=S+'\';FdFill;Exit;
 End;
 FdRes:=S;
 FdChoose:=True;
End;

Function FdProc(H, Msg, Mp1, Mp2: LongInt): LongInt;
Var Hps, I: LongInt; Rc: Array[0..3] Of LongInt;
Begin
 FdProc:=0;
 Case Msg Of
  WM_PAINT : Begin
    Hps:=WinBeginPaint(H,0,0);
    Dummy:=WinQueryWindowRect(H,LongInt(@Rc));
    Dummy:=WinFillRect(Hps,LongInt(@Rc),CLR_PALEGRAY);
    PmText(Hps,Rc[3],10,8,'Nom du fichier :',CLR_PMBLACK,CLR_PALEGRAY);
    PmText(Hps,Rc[3],10,58,'R'#130'pertoire :',CLR_PMBLACK,CLR_PALEGRAY);
    Dummy:=WinEndPaint(Hps);
   End;
  WM_CONTROL :
   If PmLo(Mp1)=ID_FLIST Then Begin
    I:=WinSendMsg(FdLb,LM_QUERYSELECTION,-1,0);
    If (I>=0) And (I<FdN) Then Begin
     If PmHi(Mp1)=LN_ENTER Then Begin
      If FdChoose(FdItem[I]) Then PmDone(1);
     End Else If PmHi(Mp1)=LN_SELECT Then
      If FdItem[I][1]<>'[' Then Dummy:=WinSetWindowText(FdEf,OsZ(FdItem[I]));
    End;
   End;
  WM_COMMAND :
   If PmLo(Mp1)=ID_POK Then Begin
    If FdChoose(FdText(FdEf)) Then PmDone(1);
   End Else If PmLo(Mp1)=ID_PCANCEL Then PmDone(2);
  WM_CHAR : Begin
    If ((PmLo(Mp1) And KC_KEYUP)=0) And ((PmLo(Mp1) And KC_VIRTUALKEY)<>0) And
       ((PmHi(Mp2)=VK_ENTER) Or (PmHi(Mp2)=VK_NEWLINE)) Then Begin
     If FdChoose(FdText(FdEf)) Then PmDone(1);
     FdProc:=1;
    End Else FdProc:=PmDlgKey(H,Msg,Mp1,Mp2);
   End;
  WM_CLOSE : PmDone(2);
 Else
  FdProc:=WinDefWindowProc(H,Msg,Mp1,Mp2);
 End;
End;

{ boite de fichiers de PM : Name recoit le nom complet choisi }
Function PmFileDlg(Title, Mask: String; Var Name: String; Save: Boolean): Boolean;
Var W, H, K: LongInt; S: String;
Begin
 If Not FdClsDone Then Begin
  FdClsDone:=True;
  Dummy:=WinRegisterClass(OsHab,OsZ('PMFILEDLG'),LongInt(@FdProc),0,0);
 End;
 If FdDir='' Then Begin
  GetDir(0,FdDir);
  If (FdDir='') Or (FdDir[Length(FdDir)]<>'\') Then FdDir:=FdDir+'\';
 End;
 FdMask:=Mask;
 If FdMask='' Then FdMask:='*.*';
 FdSave:=Save;
 W:=440;H:=330;
 FdFr:=PmOpenBox('PMFILEDLG',Title,W,H,FdCl);
 If FdFr=0 Then Begin PmFileDlg:=False;Exit;End;
 FdEf:=WinCreateWindow(FdCl,WC_ENTRYFIELD,0,WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN,
   10,H-50,W-20,20,FdCl,HWND_TOP,ID_PEF,0,0);
 Dummy:=WinSendMsg(FdEf,EM_SETTEXTLIMIT,250,0);
 FdDl:=WinCreateWindow(FdCl,WC_STATIC,0,WS_VISIBLE Or 1,
   110,H-74,W-120,16,FdCl,HWND_TOP,ID_FDIR,0,0);
 K:=CLR_PALEGRAY;
 Dummy:=FdSetPP(FdDl,4,4,LongInt(@K));
 FdLb:=WinCreateWindow(FdCl,WC_LISTBOX,0,WS_VISIBLE Or WS_TABSTOP,
   10,44,W-20,H-44-84,FdCl,HWND_TOP,ID_FLIST,0,0);
 If Save Then S:='Enregistrer' Else S:='Ouvrir';
 Dummy:=WinCreateWindow(FdCl,WC_BUTTON,OsZ(S),WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
   W-208,8,96,26,FdCl,HWND_TOP,ID_POK,0,0);
 Dummy:=WinCreateWindow(FdCl,WC_BUTTON,OsZ('Annuler'),WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
   W-104,8,96,26,FdCl,HWND_TOP,ID_PCANCEL,0,0);
 { nom propose : son repertoire devient le repertoire courant }
 S:=Name;
 K:=Length(S);
 While (K>0) And (S[K]<>'\') Do Dec(K);
 If (K>0) And (Pos(':',S)>0) Then Begin FdDir:=Copy(S,1,K);Delete(S,1,K);End;
 FdFill;
 Dummy:=WinSetWindowText(FdEf,OsZ(S));
 Dummy:=WinSendMsg(FdEf,EM_SETSEL,Length(S) Shl 16,0);
 FdRes:='';
 PmFileDlg:=PmModal(FdFr,FdEf,0)=1;
 If FdRes<>'' Then Name:=FdRes;
End;

{ --- boite de liste de PM : choix d'un article (1 = premier ; 0 : annule) --- }

Var
 LdFr, LdCl, LdLb, LdSel : LongInt;
 LdClsDone : Boolean;

Function LdProc(H, Msg, Mp1, Mp2: LongInt): LongInt;
Var Hps: LongInt; Rc: Array[0..3] Of LongInt;
Begin
 LdProc:=0;
 Case Msg Of
  WM_PAINT : Begin
    Hps:=WinBeginPaint(H,0,0);
    Dummy:=WinQueryWindowRect(H,LongInt(@Rc));
    Dummy:=WinFillRect(Hps,LongInt(@Rc),CLR_PALEGRAY);
    Dummy:=WinEndPaint(Hps);
   End;
  WM_CONTROL :
   If (PmLo(Mp1)=ID_FLIST) And (PmHi(Mp1)=LN_ENTER) Then Begin
    LdSel:=WinSendMsg(LdLb,LM_QUERYSELECTION,-1,0)+1;
    If LdSel>0 Then PmDone(1);
   End;
  WM_COMMAND :
   If PmLo(Mp1)=ID_POK Then Begin
    LdSel:=WinSendMsg(LdLb,LM_QUERYSELECTION,-1,0)+1;
    If LdSel>0 Then PmDone(1);
   End Else If PmLo(Mp1)=ID_PCANCEL Then PmDone(2);
  WM_CHAR : LdProc:=PmDlgKey(H,Msg,Mp1,Mp2);
  WM_CLOSE : PmDone(2);
 Else
  LdProc:=WinDefWindowProc(H,Msg,Mp1,Mp2);
 End;
End;

{ Items : articles separes par #10 ; Init : article choisi au depart }
Function PmListDlg(Title, Items: String; Init: Integer): Integer;
Var W, H, N, I, Mx, Rows: LongInt; S: String;
Begin
 If Not LdClsDone Then Begin
  LdClsDone:=True;
  Dummy:=WinRegisterClass(OsHab,OsZ('PMLISTDLG'),LongInt(@LdProc),0,0);
 End;
 N:=0;Mx:=Length(Title);S:='';
 For I:=1 To Length(Items) Do
  If Items[I]=#10 Then Begin Inc(N);If Length(S)>Mx Then Mx:=Length(S);S:='';End
  Else S:=S+Items[I];
 If S<>'' Then Begin Inc(N);If Length(S)>Mx Then Mx:=Length(S);End;
 If N=0 Then Begin PmListDlg:=0;Exit;End;
 Rows:=N;If Rows>14 Then Rows:=14;If Rows<4 Then Rows:=4;
 W:=Mx*8+48;If W<300 Then W:=300;If W>600 Then W:=600;
 H:=Rows*16+4+54;
 LdFr:=PmOpenBox('PMLISTDLG',Title,W,H,LdCl);
 LdLb:=WinCreateWindow(LdCl,WC_LISTBOX,0,WS_VISIBLE Or WS_TABSTOP,
   10,44,W-20,Rows*16+4,LdCl,HWND_TOP,ID_FLIST,0,0);
 Dummy:=WinCreateWindow(LdCl,WC_BUTTON,OsZ('OK'),WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
   W-196,8,88,26,LdCl,HWND_TOP,ID_POK,0,0);
 Dummy:=WinCreateWindow(LdCl,WC_BUTTON,OsZ('Annuler'),WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
   W-100,8,88,26,LdCl,HWND_TOP,ID_PCANCEL,0,0);
 S:='';
 For I:=1 To Length(Items) Do
  If Items[I]=#10 Then Begin Dummy:=WinSendMsg(LdLb,LM_INSERTITEM,-1,OsZ(S));S:='';End
  Else S:=S+Items[I];
 If S<>'' Then Dummy:=WinSendMsg(LdLb,LM_INSERTITEM,-1,OsZ(S));
 If (Init<1) Or (Init>N) Then Init:=1;
 Dummy:=WinSendMsg(LdLb,LM_SELECTITEM,Init-1,1);
 If Init>Rows Then Dummy:=WinSendMsg(LdLb,LM_SETTOPINDEX,Init-Rows,0);
 LdSel:=0;
 If PmModal(LdFr,LdLb,0)=1 Then PmListDlg:=LdSel Else PmListDlg:=0;
End;

{ ================================================================== }
{ OS/2-0 : FENETRES DE PRESENTATION MANAGER COMMUNES (OFFICE-0)        }
{ ================================================================== }
{  - boucle modale qui garde la boite (MxBegin, MxWait, MxEnd) ;       }
{  - vue dessinee dans une fenetre de PM a part : la partie de l'image }
{    dessinee par la version DOS (sa boite sans cadre ni titre) est    }
{    montree dans une fenetre de PM dont les boutons sont de vrais     }
{    boutons de PM (clic transmis au bouton dessine) ;                 }
{  - titre de la fenetre principale.                                   }
{ Le programme declare Dirty (image a redessiner) avant cet include.   }

Const
 BS_AUTOCHECKBOX = 2;
 SS_TEXT = 1; DT_VCENTER = $0400; DT_RIGHT = $0200;
 ES_READONLY = $20;
 BM_QUERYCHECK = $0124; BM_SETCHECK = $0125;
 ID_MLIST = 31; ID_MLSB = 32; ID_MBTN = 40;
 MXF_ROWS = 12;
 VK_F2 = $21; VK_F4 = $23;

Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryFocus(HD : LongInt) : LongInt; External 'PMWIN';
Function WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs : LongInt) : LongInt; External 'PMWIN';
Function WinIsWindowVisible(H : LongInt) : LongInt; External 'PMWIN';

Var
 MxPrev : Array[0..7] Of LongInt;
 { vue dessinee dans une fenetre a part }
 MxCatWant, MxCatOwn, MxCatClsDone : Boolean;
 MxCatPrev : LongInt;
 MxBN : LongInt;
 MxBR : Array[0..11, 0..3] Of LongInt;
 MxBH : Array[0..11] Of LongInt;
 MxBL : Array[0..11] Of String[40];
 { titre de la fenetre principale }
 MxLastTitle : String[80];

Procedure MxGray(H : LongInt);
Var C : LongInt;
Begin
 C := CLR_PALEGRAY;
 Dummy := WinSetPresParam(H, 4, 4, LongInt(@C));
End;

Function MxTilde(S : String) : String;
Var I : Integer;
Begin
 For I := 1 To Length(S) Do If S[I] = '&' Then S[I] := '~';
 MxTilde := S;
End;

Function MxText(H : LongInt) : String;
Var N : LongInt; Buf : Array[0..259] Of Byte; S : String;
Begin
 N := WinQueryWindowText(H, 252, LongInt(@Buf));
 S := '';
 While (Length(S) < N) And (Buf[Length(S)] <> 0) Do S := S + Chr(Buf[Length(S)]);
 MxText := S;
End;

{ --- boucle modale qui ne detruit pas la boite (fiche, visionneuse) --- }

Procedure MxBegin(Fr : LongInt);
Begin
 FlushScreen;
 If PmTopFr = 0 Then PmTopFr := OsFrame;
 Inc(PmLevel);
 MxPrev[PmLevel] := PmTopFr;
 Dummy := WinSetCapture(HWND_DESKTOP, 0);
 MBtn := 0; MLatch := 0;
 Dummy := WinEnableWindow(PmTopFr, 0);
 PmTopFr := Fr;
End;

{ attend une action de la boite (PmDone) et la retourne }
Function MxWait(Focus : LongInt) : LongInt;
Var Lv : LongInt;
Begin
 Lv := PmLevel;
 PmEnd[Lv] := 0;
 Dummy := WinSetActiveWindow(HWND_DESKTOP, PmTopFr);
 If Focus <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, Focus);
 While PmEnd[Lv] = 0 Do
 Begin
  If WinGetMsg(OsHab, LongInt(@Qmsg), 0, 0, 0) = 0 Then
  Begin
   CmdPush(CMD_CLOSE);
   PmEnd[Lv] := 2;
  End
  Else Dummy := WinDispatchMsg(OsHab, LongInt(@Qmsg));
 End;
 MxWait := PmEnd[Lv];
End;

Procedure MxEnd(Fr : LongInt);
Var Prev : LongInt;
Begin
 Prev := MxPrev[PmLevel];
 Dec(PmLevel);
 Dummy := WinEnableWindow(Prev, 1);
 PmTopFr := Prev;
 Dummy := WinSetActiveWindow(HWND_DESKTOP, Prev);
 If Prev = OsFrame Then Dummy := WinSetFocus(HWND_DESKTOP, OsClient);
 Dummy := WinDestroyWindow(Fr);
 Dirty := True;
End;

{ --- vue dessinee dans une fenetre de PM a part --- }

Function MxCatProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, K, B : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 MxCatProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, LongInt(@Rc));
    CatBlit(Hps, CatX0, CatY0, CatX0 + CatW - 1, CatY0 + CatH - 1);
    Dummy := WinEndPaint(Hps);
   End;
  WM_CHAR :
   Begin
    K := KeyCode(Mp1, Mp2);
    If K >= 0 Then
    Begin
     KeyPush(K);
     MxCatProc := 1;
    End
    Else MxCatProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_MOUSEMOVE :
   Begin
    EvMX := CatX0 + PmS16(Mp1); EvMY := CatY0 + CatH - 1 - PmS16(Mp1 Shr 16);
    MxCatProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_BUTTON1DOWN, WM_BUTTON1DBLCLK, WM_BUTTON2DOWN, $0076 :
   Begin
    EvMX := CatX0 + PmS16(Mp1); EvMY := CatY0 + CatH - 1 - PmS16(Mp1 Shr 16);
    Dummy := WinSetFocus(HWND_DESKTOP, H);
    Dummy := WinSetCapture(HWND_DESKTOP, H);
    If (Msg = WM_BUTTON1DOWN) Or (Msg = WM_BUTTON1DBLCLK) Then K := 1 Else K := 2;
    MBtn := MBtn Or K; MLatch := MLatch Or K;
    MxCatProc := 1;
   End;
  WM_BUTTON1UP, $0075 :
   Begin
    EvMX := CatX0 + PmS16(Mp1); EvMY := CatY0 + CatH - 1 - PmS16(Mp1 Shr 16);
    If Msg = WM_BUTTON1UP Then MBtn := MBtn And Not 1 Else MBtn := MBtn And Not 2;
    If MBtn = 0 Then Dummy := WinSetCapture(HWND_DESKTOP, 0);
    MxCatProc := 1;
   End;
  WM_COMMAND :
   Begin
    { bouton de PM : clic au centre du bouton dessine qu'il recouvre }
    B := PmLo(Mp1) - ID_MBTN;
    If (B >= 0) And (B < MxBN) Then
    Begin
     EvMX := (MxBR[B, 0] + MxBR[B, 2]) Div 2;
     EvMY := (MxBR[B, 1] + MxBR[B, 3]) Div 2;
     MLatch := MLatch Or 1;
    End;
    Dummy := WinSetFocus(HWND_DESKTOP, H);
   End;
  WM_CLOSE : KeyPush(27);
 Else
  MxCatProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

Procedure MxCatOpen(Title : String; X1, Y1, X2, Y2 : LongInt);
Begin
 If Not MxCatClsDone Then
 Begin
  MxCatClsDone := True;
  Dummy := WinRegisterClass(OsHab, OsZ('MXCAT'), LongInt(@MxCatProc), 0, 0);
 End;
 FlushScreen;
 If CatSave = Nil Then GetMem(CatSave, FbW * FbH);
 Move(Fb, CatSave^, FbW * FbH);
 CatX0 := X1; CatY0 := Y1; CatW := X2 - X1 + 1; CatH := Y2 - Y1 + 1;
 CatNEx := 0; CatMode := 0; MxBN := 0;
 MBtn := 0; MLatch := 0;
 Dummy := WinSetCapture(HWND_DESKTOP, 0);
 If PmTopFr = 0 Then PmTopFr := OsFrame;
 { la fenetre qui l'ouvre (principale ou boite de PM) est desactivee }
 MxCatPrev := PmTopFr;
 Dummy := WinEnableWindow(MxCatPrev, 0);
 CatFr := PmOpenBox('MXCAT', Title, CatW, CatH, CatCl);
 PmTopFr := CatFr;
 Dummy := WinSetFocus(HWND_DESKTOP, CatCl);
End;

{ bouton de PM sur le bouton dessine X1, Y1, X2, Y2 de la vue }
Procedure MxCatBtn(X1, Y1, X2, Y2 : LongInt; L : String; Dflt : Boolean);
Var I, X, Y, W, H, St : LongInt;
Begin
 If (CatCl = 0) Or Not MxCatOwn Then Exit;
 If (X1 < CatX0) Or (X2 >= CatX0 + CatW) Or (Y1 < CatY0) Or (Y2 >= CatY0 + CatH) Then Exit;
 L := MxTilde(L);
 For I := 0 To MxBN - 1 Do
  If (MxBR[I, 0] = X1) And (MxBR[I, 1] = Y1) And (MxBR[I, 2] = X2) And (MxBR[I, 3] = Y2) Then
  Begin
   If MxBL[I] <> L Then
   Begin
    MxBL[I] := L;
    Dummy := WinSetWindowText(MxBH[I], OsZ(L));
   End;
   Exit;
  End;
 If MxBN > 11 Then Exit;
 W := X2 - X1 + 1; H := Y2 - Y1 + 1;
 If H < 24 Then
 Begin
  Y1 := Y1 - (24 - H) Div 2;
  H := 24;
 End;
 X := X1 - CatX0;
 Y := CatY0 + CatH - Y1 - H;
 St := WS_VISIBLE Or BS_PUSHBUTTON;
 If Dflt Then St := St Or BS_DEFAULT;
 MxBH[MxBN] := WinCreateWindow(CatCl, WC_BUTTON, OsZ(L), St, X, Y, W, H, CatCl, HWND_TOP, ID_MBTN + MxBN, 0, 0);
 MxBR[MxBN, 0] := X1; MxBR[MxBN, 1] := Y1; MxBR[MxBN, 2] := X2; MxBR[MxBN, 3] := Y1 + H - 1;
 MxBL[MxBN] := L;
 If CatNEx <= 63 Then
 Begin
  CatEx[CatNEx, 0] := X1; CatEx[CatNEx, 1] := Y1;
  CatEx[CatNEx, 2] := X2; CatEx[CatNEx, 3] := Y1 + H - 1;
  Inc(CatNEx);
 End;
 Inc(MxBN);
End;

Procedure MxCatClose;
Var Fr : LongInt;
Begin
 Fr := CatFr;
 { l'image d'avant la vue revient dans la fenetre principale }
 If CatSave <> Nil Then Move(CatSave^, Fb, FbW * FbH);
 CatFr := 0; CatCl := 0; CatNEx := 0; MxBN := 0;
 If MxCatPrev = 0 Then MxCatPrev := OsFrame;
 PmTopFr := MxCatPrev;
 MBtn := 0; MLatch := 0;
 Dummy := WinSetCapture(HWND_DESKTOP, 0);
 Dummy := WinEnableWindow(MxCatPrev, 1);
 Dummy := WinSetActiveWindow(HWND_DESKTOP, MxCatPrev);
 If MxCatPrev = OsFrame Then Dummy := WinSetFocus(HWND_DESKTOP, OsClient);
 If Fr <> 0 Then Dummy := WinDestroyWindow(Fr);
 Dirty := True;
End;

{ fin d'une vue dessinee ouverte par MxCatWant }
Procedure MxCatDone;
Begin
 MxCatWant := False;
 If MxCatOwn Then
 Begin
  MxCatOwn := False;
  MxCatClose;
 End;
 Dirty := True;
End;

{ titre de la fenetre principale }
Procedure MxTitle(S : String);
Begin
 If (OsFrame = 0) Or (S = MxLastTitle) Then Exit;
 MxLastTitle := S;
 Dummy := WinSetWindowText(OsFrame, OsZ(S));
End;


{ ================================================================== }
{ ACRODOC : FORMULAIRES DE PRESENTATION MANAGER                       }
{ ================================================================== }
{ Les formulaires de la version DOS (texte, nombre, liste de choix,   }
{ couleur, case a cocher, etiquette) deviennent une boite de PM :     }
{ etiquettes (WC_STATIC), champs de saisie (WC_ENTRYFIELD), listes    }
{ deroulantes (WC_COMBOBOX), cases a cocher et boutons (WC_BUTTON) ;  }
{ l'echantillon d'une couleur est peint par la boite.                 }

Const
 WC_COMBOBOX = $FFFF0002; CBS_DROPDOWNLIST = 4;
 AF_MAX = 12;

Var
 AfFr, AfCl, AfOk, AfCan, AfN : LongInt;
 AfLb, AfH : Array[0..AF_MAX - 1] Of LongInt;
 AfKind : Array[0..AF_MAX - 1] Of Integer;
 AfSwX, AfSwY : Array[0..AF_MAX - 1] Of LongInt;
 AfSwC : Array[0..AF_MAX - 1] Of LongInt;
 AfClsDone : Boolean;

{ couleur du BGI (0..15) -> couleur de PM }
Function AfPmClr(C : Integer) : LongInt;
Const
 T : Array[0..15] Of LongInt = (-1, 9, 12, 13, 10, 11, 14, 15, 8, 1, 4, 5, 2, 3, 6, -2);
Begin
 AfPmClr := T[C And 15];
End;

Function AfProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, I, Id, C, Fl, Vk, F : LongInt; Rc, Rt : Array[0..3] Of LongInt;
Begin
 AfProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, 0);
    Dummy := WinQueryWindowRect(H, LongInt(@Rc));
    Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
    { echantillons des couleurs }
    For I := 0 To AfN - 1 Do
     If AfKind[I] = 3 Then
     Begin
      Rt[0] := AfSwX[I]; Rt[1] := AfSwY[I]; Rt[2] := AfSwX[I] + 40; Rt[3] := AfSwY[I] + 18;
      Dummy := WinFillRect(Hps, LongInt(@Rt), CLR_PMBLACK);
      Rt[0] := AfSwX[I] + 2; Rt[1] := AfSwY[I] + 2; Rt[2] := AfSwX[I] + 38; Rt[3] := AfSwY[I] + 16;
      Dummy := WinFillRect(Hps, LongInt(@Rt), AfPmClr(AfSwC[I]));
     End;
    Dummy := WinEndPaint(Hps);
   End;
  WM_COMMAND :
   Begin
    Id := PmLo(Mp1);
    If Id = ID_POK Then PmDone(1)
    Else If Id = ID_PCANCEL Then PmDone(2)
    Else If (Id >= 260) And (Id < 260 + AF_MAX) Then PmDone(10 + Id - 260);
   End;
  WM_CHAR :
   Begin
    Fl := PmLo(Mp1); Vk := PmHi(Mp2);
    AfProc := 1;
    If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And
       ((Vk = VK_TAB) Or (Vk = VK_BACKTAB)) Then
    Begin
     { controle suivant ou precedent : champs, puis OK et Annuler }
     C := WinQueryFocus(HWND_DESKTOP);
     F := -1;
     For I := 0 To AfN - 1 Do If C = AfH[I] Then F := I;
     If C = AfOk Then F := AfN;
     If C = AfCan Then F := AfN + 1;
     For I := 1 To AfN + 2 Do
     Begin
      If Vk = VK_TAB Then Inc(F) Else Dec(F);
      If F > AfN + 1 Then F := 0;
      If F < 0 Then F := AfN + 1;
      If F = AfN Then Begin Dummy := WinSetFocus(HWND_DESKTOP, AfOk); Break; End;
      If F = AfN + 1 Then Begin Dummy := WinSetFocus(HWND_DESKTOP, AfCan); Break; End;
      If AfH[F] <> 0 Then Begin Dummy := WinSetFocus(HWND_DESKTOP, AfH[F]); Break; End;
     End;
    End
    Else AfProc := PmDlgKey(H, Msg, Mp1, Mp2);
   End;
  WM_CLOSE : PmDone(2);
 Else
  AfProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

Procedure PushButton(X1, Y1, X2, Y2: Integer; Const Cap: String; Down: Boolean);
Begin
 SetFillStyle(SolidFill, LightGray);
 Bar(X1, Y1, X2, Y2);
 If Down Then AcBevel(X1, Y1, X2, Y2, False) Else AcBevel(X1, Y1, X2, Y2, True);
 SetColor(Black);
 If Down Then DSC(X1 + 1, (Y1 + Y2) Div 2 - 3, X2 - X1, Cap) Else DSC(X1, (Y1 + Y2) Div 2 - 4, X2 - X1, Cap);
 { vue dessinee a part : vrai bouton de PM }
 If CatCl <> 0 Then MxCatBtn(X1, Y1, X2, Y2, U2C(Cap), False);
End;

Procedure Tri(X1, Y1, X2, Y2, X3, Y3, Col: Integer);
Var
 P: Array[0..2] Of PointType;
Begin
 P[0].X := X1; P[0].Y := Y1; P[1].X := X2; P[1].Y := Y2; P[2].X := X3; P[2].Y := Y3;
 SetFillStyle(SolidFill, Col);
 SetColor(Col);
 FillPoly(3, P);
End;

Procedure SetFullView;
Begin
 SetViewPort(0, 0, GetMaxX, GetMaxY, True);
End;

Procedure ShowProgress(Const Msg: String);
Begin
 SetFullView;
 SetFillStyle(SolidFill, LightGray);
 Bar(0, GetMaxY - STATUS_H + 1, GetMaxX, GetMaxY);
 SetColor(Black);
 DS(6, GetMaxY - STATUS_H + 6, Msg);
End;

{ ---------------------------------------------------------------------- }
{ Mise en page de la fenêtre                                                }
{ ---------------------------------------------------------------------- }

Procedure CalcLayout;
Begin
 If FullScreen Then Begin
  ViewL := 0;
  ViewT := MENU_H;
 End
 Else Begin
  If NavVisible <> 0 Then ViewL := NAV_W Else ViewL := 0;
  If ToolbarVisible <> 0 Then ViewT := MENU_H + TOOL_H Else ViewT := MENU_H;
 End;
 ViewR := GetMaxX - SBAR;
 ViewB := GetMaxY - STATUS_H - SBAR;
 ViewW := ViewR - ViewL + 1;
 ViewH := ViewB - ViewT + 1;
End;

Function PageHeightPx(I: Integer): LongInt;
Begin
 PageHeightPx := DispHOf(I, Scale);
End;

Procedure Relayout;
Var
 I: Integer;
 Y: LongInt;
 MW, W: LongInt;
 PW, PH: Real;
Begin
 CalcLayout;
 If Zoom < 10 Then Zoom := 10;
 If Zoom > 1600 Then Zoom := 1600;
 Scale := (LongInt(Zoom) * 1024 + 37) Div 75;
 Y := 8;
 MW := 0;
 For I := 1 To PageCount Do Begin
  W := DispWOf(I, Scale);
  If W > MW Then MW := W;
  If Continuous <> 0 Then Begin
   PgP(I)^.Top := Y;
   Y := Y + DispHOf(I, Scale) + 8;
  End
  Else Begin
   PgP(I)^.Top := 8;
  End;
 End;
 If Continuous = 0 Then Y := DispHOf(CurPage, Scale) + 16;
 DocH := Y;
 DocW := MW + 16;
 If ScrollY > DocH - ViewH Then ScrollY := DocH - ViewH;
 If ScrollY < 0 Then ScrollY := 0;
 If ScrollX > DocW - ViewW Then ScrollX := DocW - ViewW;
 If ScrollX < 0 Then ScrollX := 0;
End;

Procedure ApplyFit;
Var
 PW, PH, ZW, ZP: Real;
 R: Integer;
Begin
 CalcLayout;
 If (FitMode = 0) Or (PageCount = 0) Then Exit;
 If (PgP(CurPage)^.Rot And 1) <> 0 Then Begin PW := PgP(CurPage)^.H; PH := PgP(CurPage)^.W; End
 Else Begin PW := PgP(CurPage)^.W; PH := PgP(CurPage)^.H; End;
 ZW := (ViewW - 24) / PW * 75;
 ZP := (ViewH - 20) / PH * 75;
 If FitMode = 1 Then Zoom := Trunc(ZW)
 Else If ZW < ZP Then Zoom := Trunc(ZW)
 Else Zoom := Trunc(ZP);
 If Zoom < 10 Then Zoom := 10;
End;

Procedure ClampScroll;
Begin
 If ScrollY > DocH - ViewH Then ScrollY := DocH - ViewH;
 If ScrollY < 0 Then ScrollY := 0;
 If ScrollX > DocW - ViewW Then ScrollX := DocW - ViewW;
 If ScrollX < 0 Then ScrollX := 0;
End;

{ Origine (dans la fenêtre graphique de la vue) de la page I }
Procedure PageOrigin(I: Integer; Var OX, OY: LongInt);
Var
 W: LongInt;
Begin
 W := DispWOf(I, Scale);
 If DocW > ViewW Then OX := (DocW - W) Div 2 - ScrollX
 Else OX := (ViewW - W) Div 2;
 OY := PgP(I)^.Top - ScrollY;
End;

Function PageVisible(I: Integer): Boolean;
Var
 OX, OY: LongInt;
Begin
 If (Continuous = 0) And (I <> CurPage) Then Begin PageVisible := False; Exit; End;
 PageOrigin(I, OX, OY);
 PageVisible := (OY + DispHOf(I, Scale) >= -4) And (OY <= ViewH + 4);
End;

{ Page sous le pointeur ; configure le contexte (coordonnées d'écran) }
Function PageAt(SX, SY: LongInt; Var Pg: Integer; Var PXp, PYp: LongInt; Strict: Boolean): Boolean;
Var
 I, Best: Integer;
 OX, OY, W, H: LongInt;
 Dist, BD: LongInt;
Begin
 PageAt := False;
 Best := 0;
 BD := MaxLongInt;
 For I := 1 To PageCount Do Begin
  If (Continuous = 0) And (I <> CurPage) Then Continue;
  PageOrigin(I, OX, OY);
  OX := OX + ViewL; OY := OY + ViewT;
  W := DispWOf(I, Scale); H := DispHOf(I, Scale);
  If (SX >= OX) And (SX <= OX + W) And (SY >= OY) And (SY <= OY + H) Then Begin
   Best := I; BD := 0; Break;
  End;
  If SY < OY Then Dist := OY - SY Else If SY > OY + H Then Dist := SY - OY - H Else Dist := 0;
  If Dist < BD Then Begin BD := Dist; Best := I; End;
 End;
 If Best = 0 Then Exit;
 If Strict And (BD <> 0) Then Exit;
 Pg := Best;
 PageOrigin(Best, OX, OY);
 SetCtx(Best, OX + ViewL, OY + ViewT, Scale);
 Unmap(SX, SY, PXp, PYp);
 PageAt := True;
End;

Procedure UpdateCurPage;
Var
 I: Integer;
 Mid: LongInt;
Begin
 If Continuous = 0 Then Exit;
 Mid := ScrollY + ViewH Div 3;
 For I := PageCount DownTo 1 Do
  If PgP(I)^.Top <= Mid Then Begin
   CurPage := I;
   Exit;
  End;
 CurPage := 1;
End;

Procedure GotoPage(N: Integer);
Begin
 If N < 1 Then N := 1;
 If N > PageCount Then N := PageCount;
 CurPage := N;
 If Continuous <> 0 Then Begin
  ScrollY := PgP(N)^.Top - 8;
  Relayout;
 End
 Else Begin
  ScrollY := 0;
  Relayout;
 End;
 If FitMode <> 0 Then Begin
  ApplyFit;
  Relayout;
 End;
End;

Procedure ScrollToObj(I: Integer);
Var
 OX, OY: LongInt;
 SX1, SY1, SX2, SY2: LongInt;
 Pg: Integer;
Begin
 If (I < 0) Or (I >= ObjCount) Then Exit;
 Pg := ObjP(I)^.Page;
 If Continuous = 0 Then CurPage := Pg;
 Relayout;
 PageOrigin(Pg, OX, OY);
 SetCtx(Pg, OX, OY, Scale);
 ScrBox(ObjP(I)^, SX1, SY1, SX2, SY2);
 If (SY1 < 20) Or (SY2 > ViewH - 20) Then ScrollY := ScrollY + SY1 - ViewH Div 3;
 If (SX1 < 10) Or (SX2 > ViewW - 10) Then ScrollX := ScrollX + SX1 - ViewW Div 3;
 ClampScroll;
 If Continuous <> 0 Then UpdateCurPage;
End;

{ ---------------------------------------------------------------------- }
{ Menus                                                                      }
{ ---------------------------------------------------------------------- }

Procedure MItem(M: Integer; Const Cap, Sc: String; Cmd: Integer);
Begin
 With Menus[M] Do Begin
  Items[ItemCount].Caption := Cap;
  Items[ItemCount].Shortcut := Sc;
  Items[ItemCount].Cmd := Cmd;
  Items[ItemCount].Separator := False;
  Items[ItemCount].Checked := False;
  Inc(ItemCount);
 End;
End;

Procedure MSep(M: Integer);
Begin
 With Menus[M] Do Begin
  Items[ItemCount].Caption := '';
  Items[ItemCount].Shortcut := '';
  Items[ItemCount].Cmd := 0;
  Items[ItemCount].Separator := True;
  Items[ItemCount].Checked := False;
  Inc(ItemCount);
 End;
End;

Procedure InitMenus;
Var
 M, I, Need: Integer;
Begin
 FillChar(Menus, SizeOf(Menus), 0);
 Menus[MN_FILE].Title := 'Fichier';
 MItem(MN_FILE, 'Nouveau', 'Ctrl+N', CM_NEW);
 MItem(MN_FILE, 'Ouvrir...', 'Ctrl+O', CM_OPEN);
 MItem(MN_FILE, 'Enregistrer', 'Ctrl+S', CM_SAVE);
 MItem(MN_FILE, 'Enregistrer sous...', 'F2', CM_SAVEAS);
 MSep(MN_FILE);
 MItem(MN_FILE, 'Insérer un fichier PDF...', '', CM_INSFILE);
 MItem(MN_FILE, 'Extraire des pages...', '', CM_EXTRACT);
 MItem(MN_FILE, 'Exporter en texte...', '', CM_EXPTXT);
 MItem(MN_FILE, 'Exporter la page en BMP...', '', CM_EXPBMP);
 MSep(MN_FILE);
 MItem(MN_FILE, 'Propriétés du document...', 'Ctrl+D', CM_PROPS);
 MSep(MN_FILE);
 MItem(MN_FILE, 'Quitter', 'Ctrl+Q', CM_QUIT);

 Menus[MN_EDIT].Title := 'Édition';
 MItem(MN_EDIT, 'Annuler', 'Ctrl+Z', CM_UNDO);
 MItem(MN_EDIT, 'Rétablir', 'Ctrl+Y', CM_REDO);
 MSep(MN_EDIT);
 MItem(MN_EDIT, 'Couper', 'Ctrl+X', CM_CUT);
 MItem(MN_EDIT, 'Copier', 'Ctrl+C', CM_COPY);
 MItem(MN_EDIT, 'Coller', 'Ctrl+V', CM_PASTE);
 MItem(MN_EDIT, 'Supprimer', 'Suppr', CM_DELETE);
 MItem(MN_EDIT, 'Dupliquer', 'Ctrl+J', CM_DUP);
 MItem(MN_EDIT, 'Désélectionner', 'Échap', CM_DESEL);
 MSep(MN_EDIT);
 MItem(MN_EDIT, 'Modifier le texte', 'Entrée', CM_EDITTXT);
 MItem(MN_EDIT, 'Propriétés de l''objet...', 'Ctrl+P', CM_OBJPROPS);
 MItem(MN_EDIT, 'Couleur...', '', CM_COLOR);
 MSep(MN_EDIT);
 MItem(MN_EDIT, 'Rechercher...', 'Ctrl+F', CM_FIND);
 MItem(MN_EDIT, 'Rechercher le suivant', 'F3', CM_FINDNEXT);

 Menus[MN_VIEW].Title := 'Affichage';
 MItem(MN_VIEW, 'Zoom avant', '+', CM_ZOOMIN);
 MItem(MN_VIEW, 'Zoom arrière', '-', CM_ZOOMOUT);
 MItem(MN_VIEW, 'Zoom à 100 %', '1', CM_Z100);
 MItem(MN_VIEW, 'Ajuster à la largeur', '2', CM_FITW);
 MItem(MN_VIEW, 'Page entière', '3', CM_FITP);
 MItem(MN_VIEW, 'Zoom...', '', CM_ZOOMSET);
 MSep(MN_VIEW);
 MItem(MN_VIEW, 'Défilement continu', '', CM_CONT);
 MItem(MN_VIEW, 'Volet de navigation', 'F4', CM_NAV);
 MItem(MN_VIEW, 'Pages / Commentaires', 'F5', CM_NAVMODE);
 MItem(MN_VIEW, 'Plein écran', 'Ctrl+L', CM_FULL);
 MSep(MN_VIEW);
 MItem(MN_VIEW, 'Page précédente', 'PgPréc', CM_PREV);
 MItem(MN_VIEW, 'Page suivante', 'PgSuiv', CM_NEXT);
 MItem(MN_VIEW, 'Première page', 'Début', CM_FIRST);
 MItem(MN_VIEW, 'Dernière page', 'Fin', CM_LAST);
 MItem(MN_VIEW, 'Aller à la page...', 'Ctrl+G', CM_GOTO);

 Menus[MN_PAGE].Title := 'Page';
 MItem(MN_PAGE, 'Insérer une page vierge', '', CM_PGINS);
 MItem(MN_PAGE, 'Dupliquer la page', '', CM_PGDUP);
 MItem(MN_PAGE, 'Supprimer la page', '', CM_PGDEL);
 MSep(MN_PAGE);
 MItem(MN_PAGE, 'Pivoter à droite', '', CM_ROTR);
 MItem(MN_PAGE, 'Pivoter à gauche', '', CM_ROTL);
 MItem(MN_PAGE, 'Déplacer vers le haut', '', CM_PGUP);
 MItem(MN_PAGE, 'Déplacer vers le bas', '', CM_PGDOWN);
 MSep(MN_PAGE);
 MItem(MN_PAGE, 'Recadrer la page...', '', CM_CROP);
 MItem(MN_PAGE, 'Taille de la page...', '', CM_PGSIZE);
 MItem(MN_PAGE, 'Numéroter les pages...', '', CM_NUMBER);
 MItem(MN_PAGE, 'Ajouter un filigrane...', '', CM_WATER);

 Menus[MN_TOOLS].Title := 'Outils';
 MItem(MN_TOOLS, 'Sélection', 'V', CM_TOOL0 + TL_SELECT);
 MItem(MN_TOOLS, 'Main', 'H', CM_TOOL0 + TL_HAND);
 MItem(MN_TOOLS, 'Loupe', 'Z', CM_TOOL0 + TL_ZOOM);
 MSep(MN_TOOLS);
 MItem(MN_TOOLS, 'Ajouter du texte', 'T', CM_TOOL0 + TL_TEXT);
 MItem(MN_TOOLS, 'Note adhésive', 'N', CM_TOOL0 + TL_NOTE);
 MItem(MN_TOOLS, 'Surligner', 'K', CM_TOOL0 + TL_HILITE);
 MItem(MN_TOOLS, 'Souligner', 'U', CM_TOOL0 + TL_UNDER);
 MItem(MN_TOOLS, 'Barrer', 'S', CM_TOOL0 + TL_STRIKE);
 MItem(MN_TOOLS, 'Crayon', 'P', CM_TOOL0 + TL_PENCIL);
 MItem(MN_TOOLS, 'Ligne', 'L', CM_TOOL0 + TL_LINE);
 MItem(MN_TOOLS, 'Flèche', 'A', CM_TOOL0 + TL_ARROW);
 MItem(MN_TOOLS, 'Rectangle', 'R', CM_TOOL0 + TL_RECT);
 MItem(MN_TOOLS, 'Ovale', 'O', CM_TOOL0 + TL_OVAL);
 MItem(MN_TOOLS, 'Tampon', 'M', CM_TOOL0 + TL_STAMP);
 MItem(MN_TOOLS, 'Signer', 'G', CM_TOOL0 + TL_SIGN);
 MItem(MN_TOOLS, 'Biffer', 'X', CM_TOOL0 + TL_REDACT);
 MSep(MN_TOOLS);
 MItem(MN_TOOLS, 'Appliquer les biffures', '', CM_APPLYRED);
 MItem(MN_TOOLS, 'Supprimer les commentaires', '', CM_CLEARALL);
 MItem(MN_TOOLS, 'Épaisseur du trait...', '', CM_WIDTH);

 Menus[MN_HELP].Title := 'Aide';
 MItem(MN_HELP, 'Raccourcis clavier', 'F1', CM_HELP);
 MItem(MN_HELP, 'À propos d''Acrodoc...', '', CM_ABOUT);

 For M := 0 To MN_COUNT - 1 Do Begin
  Menus[M].Width := 120;
  For I := 0 To Menus[M].ItemCount - 1 Do
   If Not Menus[M].Items[I].Separator Then Begin
    Need := 28 + TW(Menus[M].Items[I].Caption);
    If Menus[M].Items[I].Shortcut <> '' Then Need := Need + 20 + TW(Menus[M].Items[I].Shortcut);
    If Need > Menus[M].Width Then Menus[M].Width := Need;
   End;
 End;
End;

Function CmdEnabled(Cmd: Integer): Boolean;
Begin
 Case Cmd Of
  CM_UNDO: CmdEnabled := CanUndo;
  CM_REDO: CmdEnabled := CanRedo;
  CM_DELETE, CM_DUP, CM_COPY, CM_CUT, CM_DESEL, CM_OBJPROPS: CmdEnabled := SelObj >= 0;
  CM_EDITTXT: CmdEnabled := (SelObj >= 0) And (ObjP(SelObj)^.Kind In [K_TEXT, K_NOTE, K_STAMP, K_HILITE, K_UNDER, K_STRIKE]);
  CM_PASTE: CmdEnabled := ClipValid;
  CM_PGDEL: CmdEnabled := PageCount > 1;
  CM_PGUP: CmdEnabled := CurPage > 1;
  CM_PGDOWN: CmdEnabled := CurPage < PageCount;
  CM_FINDNEXT: CmdEnabled := FindText <> '';
 Else CmdEnabled := True;
 End;
End;

Function CmdChecked(Cmd: Integer): Boolean;
Begin
 CmdChecked := False;
 If (Cmd >= CM_TOOL0) And (Cmd < CM_TOOL0 + TL_COUNT) Then CmdChecked := CurTool = Cmd - CM_TOOL0
 Else If Cmd = CM_CONT Then CmdChecked := Continuous <> 0
 Else If Cmd = CM_NAV Then CmdChecked := NavVisible <> 0
 Else If Cmd = CM_FULL Then CmdChecked := FullScreen;
End;

{ barre de menus de PM construite a partir des menus d'origine : choix I
  du menu M = identificateur 100 + 32 * M + I ; sous-menu M = 900 + M ;
  mnemonique : premiere lettre du titre pas encore prise }
Procedure BuildMenuBar;
Var M, I, K, H0, H1: Integer; S, Lb: String; Mn: Boolean;
Begin
 MenuLen := 0;
 MnemoKeys := '';
 H0 := MnOpen;
 For M := 0 To MN_COUNT - 1 Do Begin
  S := U2C(Menus[M].Title); Lb := ''; Mn := False;
  For K := 1 To Length(S) Do Begin
   If (Not Mn) And (UpCase(S[K]) >= 'A') And (UpCase(S[K]) <= 'Z') And
      (Pos(UpCase(S[K]), MnemoKeys) = 0) Then Begin
    Lb := Lb + '~'; MnemoKeys := MnemoKeys + UpCase(S[K]); Mn := True;
   End;
   Lb := Lb + S[K];
  End;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 900 + M, Lb);
  H1 := MnOpen;
  For I := 0 To Menus[M].ItemCount - 1 Do
   If Menus[M].Items[I].Separator Then MnItem(MIS_SEPARATOR, 0, 100 + 32 * M + I, '')
   Else Begin
    S := U2C(Menus[M].Items[I].Caption);
    If Menus[M].Items[I].Shortcut <> '' Then S := S + #9 + U2C(Menus[M].Items[I].Shortcut);
    MnItem(MIS_TEXT, 0, 100 + 32 * M + I, S);
   End;
  MnClose(H1, Menus[M].ItemCount);
 End;
 MnClose(H0, MN_COUNT);
 OsMenu := WinCreateMenu(OsFrame, LongInt(@MenuT));
End;

{ ouverture d'un menu : coches et choix grises de la version DOS }
Procedure MenuInit(M: LongInt);
Var I: Integer;
Begin
 M := M - 900;
 If (M < 0) Or (M >= MN_COUNT) Then Exit;
 For I := 0 To Menus[M].ItemCount - 1 Do
  If Not Menus[M].Items[I].Separator Then Begin
   MnAttr(100 + 32 * M + I, MIA_CHECKED, CmdChecked(Menus[M].Items[I].Cmd));
   MnAttr(100 + 32 * M + I, MIA_DISABLED, Not CmdEnabled(Menus[M].Items[I].Cmd));
  End;
End;

Procedure DrawMenuBar;
Var
 I, X: Integer;
Begin
 SetFullView;
 SetFillStyle(SolidFill, LightGray);
 Bar(0, 0, GetMaxX, MENU_H - 1);
 SetColor(DarkGray);
 Line(0, MENU_H - 1, GetMaxX, MENU_H - 1);
 X := 6;
 For I := 0 To MN_COUNT - 1 Do Begin
  Menus[I].X := X;
  If MenuActive And (ActiveMenu = I) Then Begin
   SetFillStyle(SolidFill, Blue);
   Bar(X - 4, 2, X + TW(Menus[I].Title) + 4, MENU_H - 3);
   SetColor(White);
  End
  Else SetColor(Black);
  DS(X, 6, Menus[I].Title);
  X := X + TW(Menus[I].Title) + 16;
 End;
End;

Procedure DrawDropdown(M: Integer);
Var
 I, X, Y, W, H, IH: Integer;
 En: Boolean;
Begin
 If (M < 0) Or (M >= MN_COUNT) Then Exit;
 SetFullView;
 IH := 18;
 X := Menus[M].X - 4;
 If X + Menus[M].Width > GetMaxX Then X := GetMaxX - Menus[M].Width - 2;
 Menus[M].X := X + 4;
 Y := MENU_H;
 W := Menus[M].Width;
 H := Menus[M].ItemCount * IH + 4;
 SetFillStyle(SolidFill, LightGray);
 Bar(X, Y, X + W, Y + H);
 SetColor(White);
 Line(X, Y, X + W, Y);
 Line(X, Y, X, Y + H);
 SetColor(DarkGray);
 Line(X + W, Y, X + W, Y + H);
 Line(X, Y + H, X + W, Y + H);
 SetColor(Black);
 Line(X + W + 1, Y + 1, X + W + 1, Y + H + 1);
 Line(X + 1, Y + H + 1, X + W + 1, Y + H + 1);
 For I := 0 To Menus[M].ItemCount - 1 Do Begin
  If Menus[M].Items[I].Separator Then Begin
   SetColor(DarkGray);
   Line(X + 3, Y + 2 + I * IH + IH Div 2, X + W - 3, Y + 2 + I * IH + IH Div 2);
   SetColor(White);
   Line(X + 3, Y + 3 + I * IH + IH Div 2, X + W - 3, Y + 3 + I * IH + IH Div 2);
  End
  Else Begin
   En := CmdEnabled(Menus[M].Items[I].Cmd);
   If ActiveItem = I Then Begin
    SetFillStyle(SolidFill, Blue);
    Bar(X + 2, Y + 2 + I * IH, X + W - 2, Y + 1 + (I + 1) * IH);
    If En Then SetColor(White) Else SetColor(LightGray);
   End
   Else If En Then SetColor(Black) Else SetColor(DarkGray);
   If CmdChecked(Menus[M].Items[I].Cmd) Then DS(X + 6, Y + 6 + I * IH, #251);
   DS(X + 20, Y + 6 + I * IH, Menus[M].Items[I].Caption);
   If Menus[M].Items[I].Shortcut <> '' Then
    DS(X + W - TW(Menus[M].Items[I].Shortcut) - 8, Y + 6 + I * IH, Menus[M].Items[I].Shortcut);
  End;
 End;
End;

Function MenuBarHit(MX, MY: LongInt): Integer;
Var
 I: Integer;
Begin
 MenuBarHit := -1;
 If MY >= MENU_H Then Exit;
 For I := 0 To MN_COUNT - 1 Do
  If (MX >= Menus[I].X - 4) And (MX <= Menus[I].X + TW(Menus[I].Title) + 4) Then Begin
   MenuBarHit := I;
   Exit;
  End;
End;

Function MenuItemHit(MX, MY: LongInt; M: Integer): Integer;
Var
 Idx: Integer;
Begin
 MenuItemHit := -1;
 If (M < 0) Or (M >= MN_COUNT) Then Exit;
 If (MX < Menus[M].X - 4) Or (MX > Menus[M].X - 4 + Menus[M].Width) Then Exit;
 If (MY < MENU_H + 2) Or (MY > MENU_H + Menus[M].ItemCount * 18 + 2) Then Exit;
 Idx := (MY - MENU_H - 2) Div 18;
 If (Idx < 0) Or (Idx >= Menus[M].ItemCount) Then Exit;
 If Menus[M].Items[Idx].Separator Then Exit;
 MenuItemHit := Idx;
End;

{ Sauvegarde / restauration de la zone sous un menu déroulant }
Procedure SaveUnder(M: Integer);
Var
 X, Y, W, H: Integer;
Begin
 SetFullView;
 X := Menus[M].X - 4;
 If X + Menus[M].Width > GetMaxX Then X := GetMaxX - Menus[M].Width - 2;
 Y := MENU_H;
 W := Menus[M].Width + 3;
 H := Menus[M].ItemCount * 18 + 8;
 UnderX := X; UnderY := Y; UnderW := W; UnderH := H;
 UnderSize := ImageSize(X, Y, X + W, Y + H);
 If UnderSize > 0 Then Begin
  GetMem(UnderBuf, UnderSize);
  GetImage(X, Y, X + W, Y + H, UnderBuf^);
  UnderValid := True;
 End;
End;

Procedure RestoreUnder;
Begin
 If UnderValid Then Begin
  SetFullView;
  PutImage(UnderX, UnderY, UnderBuf^, NormalPut);
  FreeMem(UnderBuf, UnderSize);
  UnderValid := False;
 End;
End;

Procedure OpenMenu(M: Integer);
Begin
 If UnderValid Then RestoreUnder;
 MenuActive := True;
 ActiveMenu := M;
 ActiveItem := -1;
 HideMouse;
 DrawMenuBar;
 SaveUnder(M);
 DrawDropdown(M);
 ShowMouse;
End;

Procedure CloseMenu;
Begin
 If Not MenuActive Then Exit;
 HideMouse;
 RestoreUnder;
 MenuActive := False;
 ActiveItem := -1;
 DrawMenuBar;
 ShowMouse;
End;

{ ---------------------------------------------------------------------- }
{ Barre d'outils                                                             }
{ ---------------------------------------------------------------------- }

Type
 TTB = Record
  X, W: Integer;
  Cmd, Icon: Integer;
  Hint: String[44];
 End;

Var
 TBar: Array[0..39] Of TTB;
 TBCount: Integer;
 TBPageX1, TBPageX2, TBZoomX1, TBZoomX2: Integer;

Procedure DrawIcon(Id, X, Y: Integer);
Var
 P: Array[0..9] Of PointType;
Begin
 SetColor(Black);
 SetFillStyle(SolidFill, Black);
 Case Id Of
  0: Begin
   SetFillStyle(SolidFill, Yellow);
   Bar(X + 1, Y + 5, X + 14, Y + 13);
   SetColor(Black);
   Rectangle(X + 1, Y + 5, X + 14, Y + 13);
   Line(X + 1, Y + 5, X + 3, Y + 3); Line(X + 3, Y + 3, X + 6, Y + 3); Line(X + 6, Y + 3, X + 7, Y + 5);
  End;
  1: Begin
   SetFillStyle(SolidFill, Blue);
   Bar(X + 2, Y + 2, X + 13, Y + 13);
   SetFillStyle(SolidFill, White);
   Bar(X + 4, Y + 2, X + 11, Y + 6);
   SetFillStyle(SolidFill, LightGray);
   Bar(X + 5, Y + 9, X + 10, Y + 13);
   SetColor(Black);
   Rectangle(X + 2, Y + 2, X + 13, Y + 13);
  End;
  2: Tri(X + 11, Y + 2, X + 11, Y + 13, X + 4, Y + 8, Black);
  3: Tri(X + 4, Y + 2, X + 4, Y + 13, X + 11, Y + 8, Black);
  4, 5, 8: Begin
   SetColor(Black);
   Circle(X + 6, Y + 6, 4);
   Circle(X + 6, Y + 6, 3);
   Line(X + 9, Y + 9, X + 14, Y + 14);
   Line(X + 10, Y + 9, X + 14, Y + 13);
   If Id = 4 Then Line(X + 4, Y + 6, X + 8, Y + 6);
   If Id = 5 Then Begin Line(X + 4, Y + 6, X + 8, Y + 6); Line(X + 6, Y + 4, X + 6, Y + 8); End;
  End;
  6: Begin
   P[0].X := X + 3; P[0].Y := Y + 1; P[1].X := X + 3; P[1].Y := Y + 13; P[2].X := X + 6; P[2].Y := Y + 10;
   P[3].X := X + 9; P[3].Y := Y + 15; P[4].X := X + 11; P[4].Y := Y + 14; P[5].X := X + 8; P[5].Y := Y + 9;
   P[6].X := X + 12; P[6].Y := Y + 9;
   SetFillStyle(SolidFill, White);
   FillPoly(7, P);
   SetColor(Black);
   DrawPoly(7, P);
   Line(X + 12, Y + 9, X + 3, Y + 1);
  End;
  7: Begin
   SetFillStyle(SolidFill, White);
   Bar(X + 4, Y + 7, X + 12, Y + 14);
   SetColor(Black);
   Rectangle(X + 4, Y + 7, X + 12, Y + 14);
   Line(X + 5, Y + 7, X + 5, Y + 2); Line(X + 7, Y + 7, X + 7, Y + 1);
   Line(X + 9, Y + 7, X + 9, Y + 2); Line(X + 11, Y + 7, X + 11, Y + 3);
   Line(X + 2, Y + 8, X + 4, Y + 10);
  End;
  9: Begin
   SetColor(Black);
   Line(X + 3, Y + 3, X + 12, Y + 3); Line(X + 3, Y + 4, X + 12, Y + 4);
   Line(X + 7, Y + 4, X + 7, Y + 13); Line(X + 8, Y + 4, X + 8, Y + 13);
   Line(X + 5, Y + 13, X + 10, Y + 13);
  End;
  10: Begin
   SetFillStyle(SolidFill, Yellow);
   Bar(X + 2, Y + 2, X + 13, Y + 12);
   SetColor(Black);
   Rectangle(X + 2, Y + 2, X + 13, Y + 12);
   Line(X + 4, Y + 5, X + 11, Y + 5); Line(X + 4, Y + 7, X + 11, Y + 7); Line(X + 4, Y + 9, X + 8, Y + 9);
   Line(X + 4, Y + 12, X + 3, Y + 14); Line(X + 3, Y + 14, X + 7, Y + 12);
  End;
  11: Begin
   SetFillStyle(SolidFill, Yellow);
   Bar(X + 1, Y + 4, X + 14, Y + 11);
   SetColor(Black);
   DS(X + 4, Y + 4, 'ab');
  End;
  12: Begin
   DS(X + 4, Y + 2, 'U');
   SetColor(Red);
   Line(X + 2, Y + 13, X + 13, Y + 13);
  End;
  13: Begin
   DS(X + 4, Y + 4, 'S');
   SetColor(Red);
   Line(X + 1, Y + 8, X + 14, Y + 8);
  End;
  14: Begin
   SetColor(Black);
   Line(X + 3, Y + 12, X + 11, Y + 4); Line(X + 4, Y + 13, X + 12, Y + 5);
   Line(X + 11, Y + 4, X + 13, Y + 6); Line(X + 3, Y + 12, X + 2, Y + 14); Line(X + 4, Y + 13, X + 2, Y + 14);
   SetColor(Red);
   Line(X + 1, Y + 15, X + 4, Y + 15);
  End;
  15: Begin
   SetColor(Black);
   Line(X + 2, Y + 13, X + 13, Y + 2); Line(X + 3, Y + 13, X + 14, Y + 2);
  End;
  16: Begin
   SetColor(Black);
   Line(X + 2, Y + 13, X + 12, Y + 3); Line(X + 3, Y + 13, X + 13, Y + 3);
   Tri(X + 14, Y + 1, X + 8, Y + 3, X + 12, Y + 7, Black);
  End;
  17: Begin
   SetColor(Black);
   Rectangle(X + 2, Y + 3, X + 13, Y + 12); Rectangle(X + 3, Y + 4, X + 12, Y + 11);
  End;
  18: Begin
   SetColor(Black);
   Ellipse(X + 8, Y + 8, 0, 360, 6, 5); Ellipse(X + 8, Y + 8, 0, 360, 5, 4);
  End;
  19: Begin
   SetColor(Red);
   Rectangle(X + 1, Y + 3, X + 14, Y + 12); Rectangle(X + 2, Y + 4, X + 13, Y + 11);
   DS(X + 4, Y + 4, 'OK');
  End;
  20: Begin
   SetColor(Blue);
   Line(X + 1, Y + 10, X + 4, Y + 4); Line(X + 4, Y + 4, X + 6, Y + 11); Line(X + 6, Y + 11, X + 9, Y + 5);
   Line(X + 9, Y + 5, X + 11, Y + 10); Line(X + 11, Y + 10, X + 14, Y + 7);
   SetColor(Black);
   Line(X + 1, Y + 13, X + 14, Y + 13);
  End;
  21: Begin
   SetFillStyle(SolidFill, Black);
   Bar(X + 2, Y + 4, X + 13, Y + 11);
   SetColor(LightRed);
   Rectangle(X + 1, Y + 3, X + 14, Y + 12);
  End;
 End;
End;

Function AddTB(Cmd, Icon, W: Integer; Const Hint: String): Integer;
Var
 X: Integer;
Begin
 If TBCount = 0 Then X := 4 Else X := TBar[TBCount - 1].X + TBar[TBCount - 1].W;
 TBar[TBCount].X := X;
 TBar[TBCount].W := W;
 TBar[TBCount].Cmd := Cmd;
 TBar[TBCount].Icon := Icon;
 TBar[TBCount].Hint := Hint;
 Inc(TBCount);
 AddTB := X;
End;

Procedure InitToolbar;
Var
 X: Integer;
Begin
 TBCount := 0;
 AddTB(CM_OPEN, 0, 22, 'Ouvrir un fichier PDF (Ctrl+O)');
 AddTB(CM_SAVE, 1, 22, 'Enregistrer (Ctrl+S)');
 AddTB(-1, -1, 6, '');
 AddTB(CM_PREV, 2, 22, 'Page précédente');
 TBPageX1 := AddTB(CM_GOTO, -2, 66, 'Aller à la page (Ctrl+G)');
 AddTB(CM_NEXT, 3, 22, 'Page suivante');
 AddTB(-1, -1, 6, '');
 AddTB(CM_ZOOMOUT, 4, 22, 'Zoom arrière (-)');
 TBZoomX1 := AddTB(CM_ZOOMSET, -3, 44, 'Niveau de zoom');
 AddTB(CM_ZOOMIN, 5, 22, 'Zoom avant (+)');
 AddTB(-1, -1, 6, '');
 AddTB(CM_TOOL0 + TL_SELECT, 6, 22, 'Outil de sélection (V)');
 AddTB(CM_TOOL0 + TL_HAND, 7, 22, 'Outil main (H)');
 AddTB(CM_TOOL0 + TL_ZOOM, 8, 22, 'Loupe (Z)');
 AddTB(-1, -1, 6, '');
 AddTB(CM_TOOL0 + TL_TEXT, 9, 22, 'Ajouter du texte (T)');
 AddTB(CM_TOOL0 + TL_NOTE, 10, 22, 'Note adhésive (N)');
 AddTB(CM_TOOL0 + TL_HILITE, 11, 22, 'Surligner le texte (K)');
 AddTB(CM_TOOL0 + TL_UNDER, 12, 22, 'Souligner le texte (U)');
 AddTB(CM_TOOL0 + TL_STRIKE, 13, 22, 'Barrer le texte (S)');
 AddTB(CM_TOOL0 + TL_PENCIL, 14, 22, 'Crayon (P)');
 AddTB(CM_TOOL0 + TL_LINE, 15, 22, 'Ligne (L)');
 AddTB(CM_TOOL0 + TL_ARROW, 16, 22, 'Flèche (A)');
 AddTB(CM_TOOL0 + TL_RECT, 17, 22, 'Rectangle (R)');
 AddTB(CM_TOOL0 + TL_OVAL, 18, 22, 'Ovale (O)');
 AddTB(CM_TOOL0 + TL_STAMP, 19, 22, 'Tampon (M)');
 AddTB(CM_TOOL0 + TL_SIGN, 20, 22, 'Signer (G)');
 AddTB(CM_TOOL0 + TL_REDACT, 21, 22, 'Biffer (X)');
 TBPageX2 := TBPageX1 + 66;
 TBZoomX2 := TBZoomX1 + 44;
End;

Procedure DrawToolbar;
Var
 I: Integer;
 X, Y: Integer;
 Active: Boolean;
 S: String;
Begin
 If (ToolbarVisible = 0) Or FullScreen Then Exit;
 SetFullView;
 SetFillStyle(SolidFill, LightGray);
 Bar(0, MENU_H, GetMaxX, MENU_H + TOOL_H - 1);
 SetColor(DarkGray);
 Line(0, MENU_H + TOOL_H - 1, GetMaxX, MENU_H + TOOL_H - 1);
 Y := MENU_H + 2;
 For I := 0 To TBCount - 1 Do Begin
  X := TBar[I].X;
  If TBar[I].Cmd = -1 Then Begin
   SetColor(DarkGray);
   Line(X + 2, Y + 1, X + 2, Y + 20);
   SetColor(White);
   Line(X + 3, Y + 1, X + 3, Y + 20);
  End
  Else If TBar[I].Icon = -2 Then Begin
   Field3D(X, Y + 1, X + TBar[I].W - 2, Y + 20);
   SetColor(Black);
   S := IStr(CurPage) + ' / ' + IStr(PageCount);
   DSC(X, Y + 7, TBar[I].W - 2, S);
  End
  Else If TBar[I].Icon = -3 Then Begin
   Field3D(X, Y + 1, X + TBar[I].W - 2, Y + 20);
   SetColor(Black);
   DSC(X, Y + 7, TBar[I].W - 2, IStr(Zoom) + '%');
  End
  Else Begin
   Active := (TBar[I].Cmd >= CM_TOOL0) And (TBar[I].Cmd < CM_TOOL0 + TL_COUNT) And (CurTool = TBar[I].Cmd - CM_TOOL0);
   If Active Then Begin
    SetFillStyle(SolidFill, White);
    Bar(X, Y, X + TBar[I].W - 2, Y + 21);
    AcBevel(X, Y, X + TBar[I].W - 2, Y + 21, False);
   End
   Else AcBevel(X, Y, X + TBar[I].W - 2, Y + 21, True);
   DrawIcon(TBar[I].Icon, X + 2, Y + 3);
  End;
 End;
End;

Function ToolbarHit(MX, MY: LongInt): Integer;
Var
 I: Integer;
Begin
 ToolbarHit := -1;
 If (ToolbarVisible = 0) Or FullScreen Then Exit;
 If (MY < MENU_H) Or (MY >= MENU_H + TOOL_H) Then Exit;
 For I := 0 To TBCount - 1 Do
  If (TBar[I].Cmd <> -1) And (MX >= TBar[I].X) And (MX < TBar[I].X + TBar[I].W - 1) Then Begin
   ToolbarHit := I;
   Exit;
  End;
End;

{ ---------------------------------------------------------------------- }
{ Barres de défilement génériques                                           }
{ ---------------------------------------------------------------------- }

Procedure SBGeom(X1, Y1, X2, Y2: Integer; Vert: Boolean; Pos, Range, Page: LongInt;
                 Var TrackA, TrackLen, ThumbA, ThumbLen: LongInt);
Var
 Total: LongInt;
Begin
 If Vert Then Total := Y2 - Y1 + 1 Else Total := X2 - X1 + 1;
 TrackLen := Total - 2 * SBAR;
 If TrackLen < 4 Then TrackLen := 4;
 If Vert Then TrackA := Y1 + SBAR Else TrackA := X1 + SBAR;
 If Range <= Page Then Begin
  ThumbLen := TrackLen;
  ThumbA := TrackA;
 End
 Else Begin
  ThumbLen := (TrackLen * Page) Div Range;
  If ThumbLen < 12 Then ThumbLen := 12;
  If ThumbLen > TrackLen Then ThumbLen := TrackLen;
  ThumbA := TrackA + ((TrackLen - ThumbLen) * Pos) Div (Range - Page);
 End;
End;

Procedure DrawSB(X1, Y1, X2, Y2: Integer; Vert: Boolean; Pos, Range, Page: LongInt);
Var
 TrackA, TrackLen, ThumbA, ThumbLen: LongInt;
Begin
 SBGeom(X1, Y1, X2, Y2, Vert, Pos, Range, Page, TrackA, TrackLen, ThumbA, ThumbLen);
 SetFillStyle(SolidFill, LightGray);
 Bar(X1, Y1, X2, Y2);
 If Vert Then Begin
  PushButton(X1, Y1, X2, Y1 + SBAR - 1, '', False);
  Tri(X1 + 4, Y1 + 10, X1 + 11, Y1 + 10, X1 + 8, Y1 + 5, Black);
  PushButton(X1, Y2 - SBAR + 1, X2, Y2, '', False);
  Tri(X1 + 4, Y2 - 10, X1 + 11, Y2 - 10, X1 + 8, Y2 - 5, Black);
  If Range > Page Then Begin
   SetFillStyle(SolidFill, LightGray);
   Bar(X1, ThumbA, X2, ThumbA + ThumbLen - 1);
   AcBevel(X1, ThumbA, X2, ThumbA + ThumbLen - 1, True);
  End;
 End
 Else Begin
  PushButton(X1, Y1, X1 + SBAR - 1, Y2, '', False);
  Tri(X1 + 10, Y1 + 4, X1 + 10, Y1 + 11, X1 + 5, Y1 + 8, Black);
  PushButton(X2 - SBAR + 1, Y1, X2, Y2, '', False);
  Tri(X2 - 10, Y1 + 4, X2 - 10, Y1 + 11, X2 - 5, Y1 + 8, Black);
  If Range > Page Then Begin
   SetFillStyle(SolidFill, LightGray);
   Bar(ThumbA, Y1, ThumbA + ThumbLen - 1, Y2);
   AcBevel(ThumbA, Y1, ThumbA + ThumbLen - 1, Y2, True);
  End;
 End;
End;

{ Retourne : 0 rien, 1 flèche -, 2 flèche +, 3 page -, 4 page +, 5 curseur }
Function SBHit(X1, Y1, X2, Y2: Integer; Vert: Boolean; Pos, Range, Page, MX, MY: LongInt;
               Var Ofs: LongInt): Integer;
Var
 TrackA, TrackLen, ThumbA, ThumbLen, M: LongInt;
Begin
 SBHit := 0;
 If (MX < X1) Or (MX > X2) Or (MY < Y1) Or (MY > Y2) Then Exit;
 SBGeom(X1, Y1, X2, Y2, Vert, Pos, Range, Page, TrackA, TrackLen, ThumbA, ThumbLen);
 If Vert Then M := MY Else M := MX;
 If M < TrackA Then Begin SBHit := 1; Exit; End;
 If M >= TrackA + TrackLen Then Begin SBHit := 2; Exit; End;
 If Range <= Page Then Exit;
 If M < ThumbA Then SBHit := 3
 Else If M >= ThumbA + ThumbLen Then SBHit := 4
 Else Begin SBHit := 5; Ofs := M - ThumbA; End;
End;

Function SBDragPos(X1, Y1, X2, Y2: Integer; Vert: Boolean; Range, Page, MX, MY, Ofs: LongInt): LongInt;
Var
 TrackA, TrackLen, ThumbA, ThumbLen, M, R: LongInt;
Begin
 SBGeom(X1, Y1, X2, Y2, Vert, 0, Range, Page, TrackA, TrackLen, ThumbA, ThumbLen);
 If Vert Then M := MY Else M := MX;
 If TrackLen - ThumbLen <= 0 Then Begin SBDragPos := 0; Exit; End;
 R := ((M - Ofs - TrackA) * (Range - Page)) Div (TrackLen - ThumbLen);
 If R < 0 Then R := 0;
 If R > Range - Page Then R := Range - Page;
 SBDragPos := R;
End;

{ ---------------------------------------------------------------------- }
{ Volet de navigation                                                        }
{ ---------------------------------------------------------------------- }

Var
 NavRowsTotal: Integer;

Function ThumbScale(I: Integer): LongInt;
Var
 W, H: LongInt;
 S1, S2: LongInt;
Begin
 If (PgP(I)^.Rot And 1) <> 0 Then Begin W := PgP(I)^.H; H := PgP(I)^.W; End
 Else Begin W := PgP(I)^.W; H := PgP(I)^.H; End;
 S1 := (74 * 1024) Div W;
 S2 := (92 * 1024) Div H;
 If S1 < S2 Then ThumbScale := S1 Else ThumbScale := S2;
End;

Function ThumbCellH(I: Integer): LongInt;
Begin
 ThumbCellH := DispHOf(I, ThumbScale(I)) + 22;
End;

Function ThumbTop(I: Integer): LongInt;
Var
 J: Integer;
 T: LongInt;
Begin
 T := 4;
 For J := 1 To I - 1 Do T := T + ThumbCellH(J);
 ThumbTop := T;
End;

Function NavDocHeight: LongInt;
Var
 I: Integer;
 T: LongInt;
Begin
 T := 4;
 For I := 1 To PageCount Do T := T + ThumbCellH(I);
 NavDocHeight := T;
End;

Function IsCommentKind(K: Integer): Boolean;
Begin
 IsCommentKind := K In [K_HILITE, K_UNDER, K_STRIKE, K_NOTE, K_STAMP];
End;

Function KindName(K: Integer): String;
Begin
 Case K Of
  K_TEXT: KindName := 'Texte';
  K_LINE: KindName := 'Ligne';
  K_ARROW: KindName := 'Flèche';
  K_RECT: KindName := 'Rectangle';
  K_OVAL: KindName := 'Ovale';
  K_POLY: KindName := 'Tracé';
  K_INK: KindName := 'Crayon';
  K_IMAGE: KindName := 'Image';
  K_GRAD: KindName := 'Dégradé';
  K_STAMP: KindName := 'Tampon';
  K_REDACT: KindName := 'Biffure';
  K_HILITE: KindName := 'Surlignage';
  K_UNDER: KindName := 'Soulignement';
  K_STRIKE: KindName := 'Barré';
  K_NOTE: KindName := 'Note';
 Else KindName := '?';
 End;
End;

{ Texte sous un surlignage / soulignement }
Function TextUnder(Idx: Integer): String;
Var
 I: Integer;
 R: String;
 Cx1, Cx2, Cy1, Cy2: LongInt;
 O: ^TObjRec;
 X1, Y1, X2, Y2: LongInt;
Begin
 R := '';
 NormBox(ObjP(Idx)^, Cx1, Cy1, Cx2, Cy2);
 For I := 0 To ObjCount - 1 Do Begin
  O := @ObjP(I)^;
  If (O^.Page = ObjP(Idx)^.Page) And (O^.Kind = K_TEXT) Then Begin
   NormBox(O^, X1, Y1, X2, Y2);
   If (X1 < Cx2) And (X2 > Cx1) And ((Y1 + Y2) Div 2 >= Cy1) And ((Y1 + Y2) Div 2 <= Cy2) Then Begin
    If Length(R) + Length(O^.Txt) < 60 Then R := R + O^.Txt + ' ';
   End;
  End;
 End;
 TextUnder := R;
End;

Procedure CommentRow(N: Integer; Var Idx: Integer);
Var
 I, C: Integer;
Begin
 Idx := -1;
 C := 0;
 For I := 0 To ObjCount - 1 Do
  If IsCommentKind(ObjP(I)^.Kind) Then Begin
   If C = N Then Begin Idx := I; Exit; End;
   Inc(C);
  End;
End;

Function CommentCount: Integer;
Var
 I, C: Integer;
Begin
 C := 0;
 For I := 0 To ObjCount - 1 Do If IsCommentKind(ObjP(I)^.Kind) Then Inc(C);
 CommentCount := C;
End;

Procedure DrawNav;
Var
 I, Y0, Y1, R, Idx, Rows, N: Integer;
 T, TY, TRun: LongInt;
 Sc: LongInt;
 DW, DH, OX: LongInt;
 S: String;
Begin
 If (NavVisible = 0) Or FullScreen Then Exit;
 SetFullView;
 SetFillStyle(SolidFill, LightGray);
 Bar(0, ViewT, NAV_W - 1, GetMaxY - STATUS_H);
 { onglets }
 If (NavTab = 2) And (LayerCount = 0) Then NavTab := 0;
 If NavTab = 0 Then SetFillStyle(SolidFill, White) Else SetFillStyle(SolidFill, LightGray);
 If LayerCount > 0 Then Bar(0, ViewT, 42, ViewT + 14) Else Bar(0, ViewT, 53, ViewT + 14);
 If NavTab = 1 Then SetFillStyle(SolidFill, White) Else SetFillStyle(SolidFill, LightGray);
 If LayerCount > 0 Then Bar(43, ViewT, 85, ViewT + 14) Else Bar(54, ViewT, NAV_W - 1, ViewT + 14);
 SetColor(Black);
 DS(2, ViewT + 4, 'Pages');
 If LayerCount > 0 Then Begin
  DS(45, ViewT + 4, 'Notes');
  If NavTab = 2 Then SetFillStyle(SolidFill, White) Else SetFillStyle(SolidFill, LightGray);
  Bar(86, ViewT, NAV_W - 1, ViewT + 14);
  SetColor(Black);
  DS(88, ViewT + 4, 'Cal');
  Line(42, ViewT, 42, ViewT + 15);
  Line(85, ViewT, 85, ViewT + 15);
 End
 Else Begin
  DS(58, ViewT + 4, 'Notes');
  Line(53, ViewT, 53, ViewT + 15);
 End;
 Line(0, ViewT + 15, NAV_W - 1, ViewT + 15);
 Y0 := ViewT + 16;
 Y1 := ViewB;
 SetViewPort(0, Y0, NAV_W - SBAR - 1, Y1, True);
 SetFillStyle(SolidFill, DarkGray);
 Bar(0, 0, NAV_W, Y1 - Y0);
 CullW := NAV_W; CullH := Y1 - Y0;
 If NavTab = 0 Then Begin
  TRun := 4;
  For I := 1 To PageCount Do Begin
   T := TRun - NavScroll;
   TRun := TRun + ThumbCellH(I);
   If T > Y1 - Y0 Then Break;
   If T + ThumbCellH(I) < 0 Then Continue;
   Sc := ThumbScale(I);
   DW := DispWOf(I, Sc);
   OX := (NAV_W - SBAR - DW) Div 2;
   If I = CurPage Then Begin
    SetColor(LightRed);
    Rectangle(C16(OX - 3), C16(T - 3), C16(OX + DW + 3), C16(T + DispHOf(I, Sc) + 3));
    Rectangle(C16(OX - 2), C16(T - 2), C16(OX + DW + 2), C16(T + DispHOf(I, Sc) + 2));
   End;
   RenderPage(I, OX, T, Sc, False);
   SetColor(White);
   S := IStr(I);
   DS(C16((NAV_W - SBAR) Div 2 - Length(S) * 4), C16(T + DispHOf(I, Sc) + 7), S);
  End;
 End
 Else If NavTab = 2 Then Begin
  Rows := (Y1 - Y0 + 1) Div 14;
  For R := 0 To Rows - 1 Do Begin
   Idx := NavScroll + R;
   If Idx >= LayerCount Then Break;
   TY := R * 14;
   SetFillStyle(SolidFill, White);
   Bar(3, C16(TY + 2), 12, C16(TY + 11));
   SetColor(Black);
   Rectangle(3, C16(TY + 2), 12, C16(TY + 11));
   If Layers^[Idx].On Then Begin
    Line(5, C16(TY + 6), 7, C16(TY + 9));
    Line(7, C16(TY + 9), 11, C16(TY + 4));
    Line(5, C16(TY + 7), 7, C16(TY + 10));
    Line(7, C16(TY + 10), 11, C16(TY + 5));
   End;
   SetColor(White);
   DS(16, C16(TY + 3), Copy(Layers^[Idx].Name, 1, 9));
  End;
 End
 Else Begin
  Rows := (Y1 - Y0 + 1) Div 24;
  N := CommentCount;
  If N = 0 Then Begin
   SetColor(White);
   DS(4, 6, 'Aucun');
   DS(4, 16, 'commentaire');
  End;
  For R := 0 To Rows - 1 Do Begin
   CommentRow(NavScroll + R, Idx);
   If Idx < 0 Then Break;
   TY := R * 24;
   If Idx = SelObj Then SetFillStyle(SolidFill, Blue) Else SetFillStyle(SolidFill, DarkGray);
   Bar(0, TY, NAV_W - SBAR - 1, TY + 22);
   SetColor(Yellow);
   DS(3, C16(TY + 2), 'p' + IStr(ObjP(Idx)^.Page) + ' ' + KindName(ObjP(Idx)^.Kind));
   SetColor(White);
   S := ObjP(Idx)^.Txt;
   If S = '' Then S := TextUnder(Idx);
   DS(3, C16(TY + 12), Copy(S, 1, 11));
  End;
 End;
 SetFullView;
 If NavTab = 0 Then DrawSB(NAV_W - SBAR, Y0, NAV_W - 1, Y1, True, NavScroll, NavDocHeight, Y1 - Y0 + 1)
 Else If NavTab = 2 Then DrawSB(NAV_W - SBAR, Y0, NAV_W - 1, Y1, True, NavScroll, IMax(LayerCount, 1), (Y1 - Y0 + 1) Div 14)
 Else DrawSB(NAV_W - SBAR, Y0, NAV_W - 1, Y1, True, NavScroll, IMax(CommentCount, 1), (Y1 - Y0 + 1) Div 24);
 SetColor(Black);
 Line(NAV_W - 1, ViewT, NAV_W - 1, GetMaxY - STATUS_H);
End;

{ ---------------------------------------------------------------------- }
{ Vue du document                                                            }
{ ---------------------------------------------------------------------- }

Procedure DrawEditCaret;
Var
 O: ^TObjRec;
 OX, OY, T: LongInt;
 Pg: Integer;
 Ox_, Oy_, Dx, Dy, Vx, Vy, U: Real;
Begin
 If Not Editing Then Exit;
 If (EditObj < 0) Or (EditObj >= ObjCount) Then Exit;
 O := @ObjP(EditObj)^;
 Pg := O^.Page;
 If Not PageVisible(Pg) Then Exit;
 SetViewPort(ViewL, ViewT, ViewR, ViewB, True);
 PageOrigin(Pg, OX, OY);
 SetCtx(Pg, OX, OY, Scale);
 TextOrigin(O^, Ox_, Oy_);
 TextDirs(TextAng(O^), Dx, Dy, Vx, Vy);
 U := TextLenPts(Copy(O^.Txt, 1, EditCaret), O^.Size, O^.Style Shr 2, O^.Style And 3);
 SetColor(Blue);
 Line(C16(MXr(Ox_ + U * Dx + O^.Size * 0.1 * Vx, Oy_ + U * Dy + O^.Size * 0.1 * Vy)),
      C16(MYr(Ox_ + U * Dx + O^.Size * 0.1 * Vx, Oy_ + U * Dy + O^.Size * 0.1 * Vy)),
      C16(MXr(Ox_ + U * Dx + O^.Size * 1.1 * Vx, Oy_ + U * Dy + O^.Size * 1.1 * Vy)),
      C16(MYr(Ox_ + U * Dx + O^.Size * 1.1 * Vx, Oy_ + U * Dy + O^.Size * 1.1 * Vy)));
 SetColor(LightBlue);
 DrawTextBoxRot(O^);
 SetFullView;
End;

Procedure DrawView;
Var
 I: Integer;
 OX, OY: LongInt;
Begin
 SetViewPort(ViewL, ViewT, ViewR, ViewB, True);
 CullW := ViewW - 1; CullH := ViewH - 1;
 SetFillStyle(SolidFill, DarkGray);
 Bar(0, 0, ViewW, ViewH);
 For I := 1 To PageCount Do
  If PageVisible(I) Then Begin
   PageOrigin(I, OX, OY);
   RenderPage(I, OX, OY, Scale, True);
  End;
 SetFullView;
 DrawEditCaret;
End;

Procedure DrawScrollBars;
Begin
 SetFullView;
 DrawSB(ViewR + 1, ViewT, GetMaxX, ViewB, True, ScrollY, DocH, ViewH);
 DrawSB(ViewL, ViewB + 1, ViewR, GetMaxY - STATUS_H, False, ScrollX, DocW, ViewW);
 SetFillStyle(SolidFill, LightGray);
 Bar(ViewR + 1, ViewB + 1, GetMaxX, GetMaxY - STATUS_H);
End;

Procedure DrawStatus;
Var
 S, R: String;
 Y: Integer;
Begin
 SetFullView;
 Y := GetMaxY - STATUS_H + 1;
 SetFillStyle(SolidFill, LightGray);
 Bar(0, Y, GetMaxX, GetMaxY);
 SetColor(DarkGray);
 Line(0, Y, GetMaxX, Y);
 SetColor(White);
 Line(0, Y + 1, GetMaxX, Y + 1);
 SetColor(Black);
 If HintText <> '' Then S := HintText Else If StatusMsg <> '' Then S := StatusMsg
 Else Begin
  S := BaseName(DocName);
  If S = '' Then S := 'Sans titre.pdf';
  If Modified Then S := S + ' *';
 End;
 If Length(S) > 52 Then S := Copy(S, 1, 52);
 DS(6, Y + 6, S);
 R := IStr(PgP(CurPage)^.W) + ' x ' + IStr(PgP(CurPage)^.H) + ' pt   Page ' + IStr(CurPage) + '/' + IStr(PageCount);
 DS(GetMaxX - TW(R) - 8, Y + 6, R);
End;

Procedure RedrawView;
Begin
 HideMouse;
 DrawView;
 DrawScrollBars;
 DrawStatus;
 ShowMouse;
End;

Procedure RedrawAll;
Begin
 If DocName <> '' Then MxTitle('Acrodoc - ' + BaseName(DocName)) Else MxTitle('Acrodoc');
 HideMouse;
 SetFullView;
 If (FitMode <> 0) And (PageCount > 0) Then ApplyFit;
 Relayout;
 SetFillStyle(SolidFill, LightGray);
 Bar(0, 0, GetMaxX, GetMaxY);
 DrawMenuBar;
 DrawToolbar;
 DrawView;
 DrawNav;
 SetFullView;
 DrawScrollBars;
 DrawStatus;
 If MenuActive Then Begin
  If UnderValid Then Begin FreeMem(UnderBuf, UnderSize); UnderValid := False; End;
  SaveUnder(ActiveMenu);
  DrawDropdown(ActiveMenu);
 End;
 ShowMouse;
End;

Procedure SetStatus(Const S: String);
Begin
 StatusMsg := S;
 DrawStatus;
End;

{ ---------------------------------------------------------------------- }
{ Dialogues                                                                 }
{ ---------------------------------------------------------------------- }

Var
 DlgX1, DlgY1, DlgX2, DlgY2: Integer;
 LastDir: String;
 FileMaskAll: Boolean;

Procedure PollMouse;
Begin
 OMX := MX_; OMY := MY_; OMB := MB_;
 GetMouseState(MX_, MY_, MB_);
End;

Function MouseClicked: Boolean;
Begin
 MouseClicked := ((MB_ And 1) <> 0) And ((OMB And 1) = 0);
End;

Function GetKeyEx(Var Ext: Boolean): Integer;
Var
 C: Char;
Begin
 GetKeyEx := -1;
 Ext := False;
 If Not KeyPressed Then Exit;
 C := ReadKey;
 If C = #0 Then Begin
  Ext := True;
  If KeyPressed Then GetKeyEx := Ord(ReadKey) Else GetKeyEx := 0;
 End
 Else GetKeyEx := Ord(C);
End;

Procedure WaitMouseUp;
Begin
 Repeat
  PollMouse;
  Delay(5);
 Until (MB_ And 1) = 0;
 OMB := 0;
End;

Procedure DlgFrame(W, H: Integer; Const Title: String);
Begin
 SetFullView;
 DlgX1 := (GetMaxX + 1 - W) Div 2;
 DlgY1 := (GetMaxY + CanvasTop + 1 - H) Div 2;
 DlgX2 := DlgX1 + W - 1;
 DlgY2 := DlgY1 + H - 1;
 { vue dessinee : fenetre de PM a part (son cadre et sa barre de titre
   remplacent ceux dessines) ; ouverte avant le dessin de la boite }
 If MxCatWant And (CatCl = 0) Then Begin
  MxCatWant := False; MxCatOwn := True;
  MxCatOpen(U2C(Title), DlgX1 + 3, DlgY1 + 19, DlgX2 - 3, DlgY2 - 3);
 End;
 SetFillStyle(SolidFill, Black);
 Bar(DlgX1 + 4, DlgY1 + 4, DlgX2 + 4, DlgY2 + 4);
 Panel(DlgX1, DlgY1, DlgX2, DlgY2, True);
 SetFillStyle(SolidFill, Blue);
 Bar(DlgX1 + 3, DlgY1 + 3, DlgX2 - 3, DlgY1 + 17);
 SetColor(White);
 DS(DlgX1 + 8, DlgY1 + 7, Title);
End;

Function InRect(X, Y, X1, Y1, X2, Y2: LongInt): Boolean;
Begin
 InRect := (X >= X1) And (X <= X2) And (Y >= Y1) And (Y <= Y2);
End;

{ Boîte de message : 0 = OK ; 1 = OK/Annuler ; 2 = Oui/Non/Annuler
  Retour : 1 OK/Oui, 2 Non, 0 Annuler }
Function MsgBox(Const Title, Msg: String; Buttons: Integer): Integer;
{ boite de message de PM : 0 = OK ; 1 = OK/Annuler ; 2 = Oui/Non/Annuler ;
  retour 1 OK/Oui, 2 Non, 0 Annuler ; '|' separe les lignes }
Var T, Ti: String; I, R: Integer;
Begin
 T := U2C(Msg); Ti := U2C(Title);
 For I := 1 To Length(T) Do If T[I] = '|' Then T[I] := #10;
 Case Buttons Of
  0: Begin Dummy := PmBox(Ti, T, MB_OK Or MB_INFORMATION); R := 1; End;
  1: If PmBox(Ti, T, 1 Or MB_ICONQUESTION) = 1 Then R := 1 Else R := 0;
  Else Begin
   I := PmBox(Ti, T, 5 Or MB_ICONQUESTION);
   If I = MBID_YES Then R := 1 Else If I = 7 Then R := 2 Else R := 0;
  End;
 End;
 Dirty := True;
 MsgBox := R;
End;

Procedure Notice(Const Msg: String);
Var
 R: Integer;
Begin
 R := MsgBox('Acrodoc', Msg, 0);
End;

{ ---------------------------------------------------------------------- }
{ Sélecteur de couleur                                                      }
{ ---------------------------------------------------------------------- }

Function PickColorD(Const Title: String; Cur: LongInt): LongInt;
Var
 I, X, Y, Sel: Integer;
 Done, Ext: Boolean;
 K: Integer;
 Res: LongInt;
Begin
 HideMouse;
 DlgFrame(260, 112, Title);
 For I := 0 To 15 Do Begin
  X := DlgX1 + 12 + (I Mod 8) * 30;
  Y := DlgY1 + 28 + (I Div 8) * 30;
  SetFillStyle(SolidFill, I);
  Bar(X, Y, X + 26, Y + 26);
  If Nearest16(Cur) = I Then Begin
   SetColor(White); Rectangle(X - 2, Y - 2, X + 28, Y + 28);
   SetColor(Black); Rectangle(X - 1, Y - 1, X + 27, Y + 27);
  End
  Else Begin SetColor(Black); Rectangle(X, Y, X + 26, Y + 26); End;
 End;
 SetColor(Black);
 DS(DlgX1 + 12, DlgY2 - 20, 'Cliquez sur une couleur - Échap annule');
 ShowMouse;
 Res := -1;
 Done := False;
 PollMouse; OMB := MB_;
 While Not Done Do Begin
  PollMouse;
  If MouseClicked Then Begin
   For I := 0 To 15 Do Begin
    X := DlgX1 + 12 + (I Mod 8) * 30;
    Y := DlgY1 + 28 + (I Div 8) * 30;
    If InRect(MX_, MY_, X, Y, X + 26, Y + 26) Then Begin Res := PalRgb[I]; Done := True; End;
   End;
   If Not InRect(MX_, MY_, DlgX1, DlgY1, DlgX2, DlgY2) Then Done := True;
  End;
  K := GetKeyEx(Ext);
  If (K = 27) And Not Ext Then Done := True;
  Delay(10);
 End;
 WaitMouseUp;
 PickColorD := Res;
End;
Function PickColor(Const Title: String; Cur: LongInt): LongInt;
Begin
 MxCatWant := True; PickColor := PickColorD(Title, Cur); MxCatDone;
End;

{ ---------------------------------------------------------------------- }
{ Formulaires                                                                }
{ ---------------------------------------------------------------------- }

Procedure FldInit;
Begin
 NFields := 0;
 FillChar(Fields, SizeOf(Fields), 0);
End;

Procedure FldText(Const Lbl, Val: String; Max: Integer);
Begin
 Fields[NFields].Kind := 0; Fields[NFields].Lbl := Lbl; Fields[NFields].Val := Val; Fields[NFields].Mx := Max;
 Inc(NFields);
End;

Procedure FldNum(Const Lbl: String; Val, Mn, Mx: LongInt);
Begin
 Fields[NFields].Kind := 1; Fields[NFields].Lbl := Lbl; Fields[NFields].Val := IStr(Val);
 Fields[NFields].Mn := Mn; Fields[NFields].Mx := Mx;
 Inc(NFields);
End;

Procedure FldChoice(Const Lbl, Choices: String; Idx: Integer);
Begin
 Fields[NFields].Kind := 2; Fields[NFields].Lbl := Lbl; Fields[NFields].Choices := Choices;
 Fields[NFields].Cur := Idx;
 Inc(NFields);
End;

Procedure FldColor(Const Lbl: String; Rgb: LongInt);
Begin
 Fields[NFields].Kind := 3; Fields[NFields].Lbl := Lbl; Fields[NFields].Mn := Rgb;
 Inc(NFields);
End;

Procedure FldCheck(Const Lbl: String; On: Boolean);
Begin
 Fields[NFields].Kind := 4; Fields[NFields].Lbl := Lbl;
 If On Then Fields[NFields].Cur := 1 Else Fields[NFields].Cur := 0;
 Inc(NFields);
End;

Procedure FldLabel(Const Txt: String);
Begin
 Fields[NFields].Kind := 9; Fields[NFields].Lbl := Copy(Txt, 1, 30); Fields[NFields].Val := Txt;
 Inc(NFields);
End;

Function FInt(I: Integer): LongInt;
Begin
 Case Fields[I].Kind Of
  1: FInt := StrInt(Fields[I].Val, Fields[I].Mn);
  2, 4: FInt := Fields[I].Cur;
  3: FInt := Fields[I].Mn;
 Else FInt := 0;
 End;
End;

Function ChoiceText(Const Choices: String; Idx: Integer): String;
Var
 S: String;
 I, K: Integer;
Begin
 S := Choices + '|';
 For I := 0 To Idx - 1 Do Begin
  K := Pos('|', S);
  If K = 0 Then Break;
  Delete(S, 1, K);
 End;
 K := Pos('|', S);
 If K = 0 Then ChoiceText := S Else ChoiceText := Copy(S, 1, K - 1);
End;

Function ChoiceCount(Const Choices: String): Integer;
Var
 I, N: Integer;
Begin
 N := 1;
 For I := 1 To Length(Choices) Do If Choices[I] = '|' Then Inc(N);
 ChoiceCount := N;
End;

Var
 FormLblW: Integer;

Procedure DrawFormRow(I, Focus: Integer; Blink: Boolean; ReplaceMode: Boolean);
Var
 Y, X0, W, C: Integer;
 S: String;
Begin
 Y := DlgY1 + 26 + I * 24;
 X0 := DlgX1 + FormLblW;
 W := DlgX2 - X0 - 12;
 SetFillStyle(SolidFill, LightGray);
 Bar(DlgX1 + 4, Y, DlgX2 - 4, Y + 22);
 If Fields[I].Kind = 9 Then Begin
  SetColor(Black);
  DS(DlgX1 + 14, Y + 8, Fields[I].Val);
  Exit;
 End;
 SetColor(Black);
 DS(DlgX1 + 12, Y + 7, Fields[I].Lbl);
 Case Fields[I].Kind Of
  0, 1: Begin
   Field3D(X0, Y + 1, X0 + W, Y + 19);
   S := Fields[I].Val;
   If ReplaceMode And (I = Focus) Then Begin
    SetFillStyle(SolidFill, Blue);
    Bar(X0 + 3, Y + 3, X0 + 3 + TW(S) - 1, Y + 17);
    SetColor(White);
   End
   Else SetColor(Black);
   While TW(S) > W - 8 Do Delete(S, 1, 1);
   DS(X0 + 4, Y + 7, S);
   If (I = Focus) And Blink And Not ReplaceMode Then Begin
    SetColor(Black);
    Line(X0 + 4 + TW(S), Y + 4, X0 + 4 + TW(S), Y + 16);
   End;
  End;
  2: Begin
   Field3D(X0, Y + 1, X0 + W, Y + 19);
   SetColor(Black);
   DS(X0 + 4, Y + 7, ChoiceText(Fields[I].Choices, Fields[I].Cur));
   Tri(X0 + W - 14, Y + 7, X0 + W - 6, Y + 7, X0 + W - 10, Y + 13, Black);
  End;
  3: Begin
   Field3D(X0, Y + 1, X0 + 46, Y + 19);
   SetFillStyle(SolidFill, ScrCol(Fields[I].Mn));
   Bar(X0 + 3, Y + 4, X0 + 43, Y + 16);
   SetColor(Black);
   DS(X0 + 54, Y + 7, 'Cliquer pour changer');
  End;
  4: Begin
   Field3D(X0, Y + 3, X0 + 14, Y + 17);
   If Fields[I].Cur <> 0 Then Begin
    SetColor(Black);
    Line(X0 + 3, Y + 9, X0 + 6, Y + 14); Line(X0 + 6, Y + 14, X0 + 12, Y + 5);
    Line(X0 + 4, Y + 9, X0 + 7, Y + 14); Line(X0 + 7, Y + 14, X0 + 13, Y + 5);
   End;
  End;
 End;
 If I = Focus Then Begin
  SetColor(Blue);
  SetLineStyle(DottedLn, 0, 1);
  Rectangle(DlgX1 + 6, Y, DlgX2 - 6, Y + 22);
  SetLineStyle(SolidLn, 0, 1);
 End;
End;

{ texte du document (WinAnsi) <-> texte de PM }
Function AfToPm(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := S;
 For I := 1 To Length(R) Do If Ord(R[I]) >= 128 Then R[I] := Chr(Win2Glyph(Ord(R[I])));
 AfToPm := R;
End;

Function AfFromPm(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := S;
 For I := 1 To Length(R) Do If Ord(R[I]) >= 128 Then R[I] := Chr(Dos2Win(Ord(R[I])));
 AfFromPm := R;
End;

Function FormDialog(Const Title: String): Boolean;
{ formulaire de PM : une rangee par champ }
Var
 W, H, I, J, Y, X0, Wv, A, C, Foc: LongInt;
 N: LongInt;
 OK: Boolean;
 S, Ch: String;
Begin
 FormDialog := False;
 If Not AfClsDone Then Begin
  AfClsDone := True;
  PmRegister;
  Dummy := WinRegisterClass(OsHab, OsZ('ACFORM'), LongInt(@AfProc), 0, 0);
 End;
 FormLblW := 150;
 For I := 0 To NFields - 1 Do
  If (Fields[I].Kind <> 9) And (TW(Fields[I].Lbl) + 24 > FormLblW) Then FormLblW := TW(Fields[I].Lbl) + 24;
 W := FormLblW + 280;
 If W > 620 Then W := 620;
 AfN := NFields;
 If AfN > AF_MAX Then AfN := AF_MAX;
 H := 14 + AfN * 28 + 48;
 AfFr := PmOpenBox('ACFORM', U2C(Title), W, H, AfCl);
 If AfFr = 0 Then Exit;
 Foc := 0;
 X0 := FormLblW;
 Wv := W - X0 - 12;
 For I := 0 To AfN - 1 Do Begin
  Y := H - 10 - (I + 1) * 28;
  AfKind[I] := Fields[I].Kind; AfH[I] := 0; AfLb[I] := 0;
  If Fields[I].Kind = 9 Then Begin
   AfLb[I] := WinCreateWindow(AfCl, WC_STATIC, OsZ(U2C(Fields[I].Val)), WS_VISIBLE Or SS_TEXT Or DT_VCENTER,
     12, Y + 2, W - 24, 22, AfCl, HWND_TOP, 200 + I, 0, 0);
   MxGray(AfLb[I]);
  End
  Else Begin
   AfLb[I] := WinCreateWindow(AfCl, WC_STATIC, OsZ(U2C(Fields[I].Lbl)), WS_VISIBLE Or SS_TEXT Or DT_VCENTER,
     12, Y + 2, X0 - 20, 22, AfCl, HWND_TOP, 200 + I, 0, 0);
   MxGray(AfLb[I]);
   Case Fields[I].Kind Of
    0, 1: Begin
      AfH[I] := WinCreateWindow(AfCl, WC_ENTRYFIELD, 0, WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN,
        X0, Y + 3, Wv, 20, AfCl, HWND_TOP, 220 + I, 0, 0);
      If Fields[I].Kind = 1 Then N := 7 Else N := Fields[I].Mx;
      If (N <= 0) Or (N > 119) Then N := 119;
      Dummy := WinSendMsg(AfH[I], EM_SETTEXTLIMIT, N, 0);
      Dummy := WinSetWindowText(AfH[I], OsZ(AfToPm(Fields[I].Val)));
      Dummy := WinSendMsg(AfH[I], EM_SETSEL, Length(Fields[I].Val) Shl 16, 0);
     End;
    2: Begin
      AfH[I] := WinCreateWindow(AfCl, WC_COMBOBOX, OsZ(''), WS_VISIBLE Or WS_TABSTOP Or CBS_DROPDOWNLIST,
        X0, Y + 1, Wv, 22, AfCl, HWND_TOP, 220 + I, 0, 0);
      For J := 0 To ChoiceCount(Fields[I].Choices) - 1 Do
       Dummy := WinSendMsg(AfH[I], LM_INSERTITEM, -1, OsZ(U2C(ChoiceText(Fields[I].Choices, J))));
      Dummy := WinSendMsg(AfH[I], LM_SELECTITEM, Fields[I].Cur, 1);
     End;
    3: Begin
      AfSwX[I] := X0; AfSwY[I] := Y + 4; AfSwC[I] := Nearest16(Fields[I].Mn);
      AfH[I] := WinCreateWindow(AfCl, WC_BUTTON, OsZ('Couleur...'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
        X0 + 50, Y + 1, 120, 24, AfCl, HWND_TOP, 260 + I, 0, 0);
     End;
    4: Begin
      AfH[I] := WinCreateWindow(AfCl, WC_BUTTON, OsZ(''), WS_VISIBLE Or WS_TABSTOP Or BS_AUTOCHECKBOX,
        X0, Y + 4, 22, 18, AfCl, HWND_TOP, 220 + I, 0, 0);
      Dummy := WinSendMsg(AfH[I], BM_SETCHECK, Ord(Fields[I].Cur <> 0), 0);
     End;
   End;
   If Foc = 0 Then Foc := AfH[I];
  End;
 End;
 AfOk := WinCreateWindow(AfCl, WC_BUTTON, OsZ('OK'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
   W Div 2 - 96, 8, 88, 26, AfCl, HWND_TOP, ID_POK, 0, 0);
 AfCan := WinCreateWindow(AfCl, WC_BUTTON, OsZ('Annuler'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
   W Div 2 + 8, 8, 88, 26, AfCl, HWND_TOP, ID_PCANCEL, 0, 0);
 If Foc = 0 Then Foc := AfOk;
 OK := False;
 MxBegin(AfFr);
 Repeat
  A := MxWait(Foc);
  If (A >= 10) And (A < 10 + AfN) Then Begin
   { couleur : selecteur de couleurs }
   I := A - 10;
   C := PickColor(Fields[I].Lbl, Fields[I].Mn);
   If C >= 0 Then Fields[I].Mn := C;
   AfSwC[I] := Nearest16(Fields[I].Mn);
   Dummy := WinInvalidateRect(AfCl, 0, 1);
   Foc := AfH[I];
   A := -1;
  End
  Else If A = 1 Then Begin
   For I := 0 To AfN - 1 Do
    Case Fields[I].Kind Of
     0, 1: Fields[I].Val := AfFromPm(Copy(MxText(AfH[I]), 1, 119));
     2: Begin
         C := WinSendMsg(AfH[I], LM_QUERYSELECTION, -1, 0);
         If C >= 0 Then Fields[I].Cur := C;
        End;
     4: If WinSendMsg(AfH[I], BM_QUERYCHECK, 0, 0) <> 0 Then Fields[I].Cur := 1 Else Fields[I].Cur := 0;
    End;
   OK := True;
  End;
 Until A > 0;
 MxEnd(AfFr);
 If OK Then Begin
  For I := 0 To NFields - 1 Do
   If Fields[I].Kind = 1 Then Begin
    N := StrInt(Fields[I].Val, Fields[I].Mn);
    If N < Fields[I].Mn Then N := Fields[I].Mn;
    If N > Fields[I].Mx Then N := Fields[I].Mx;
    Fields[I].Val := IStr(N);
   End;
 End;
 FormDialog := OK;
End;

Function InputBox(Const Title, Prompt: String; Var S: String; Max: Integer): Boolean;
Begin
 FldInit;
 FldText(Prompt, S, Max);
 If FormDialog(Title) Then Begin
  S := Fields[0].Val;
  InputBox := True;
 End
 Else InputBox := False;
End;

{ ---------------------------------------------------------------------- }
{ Sélecteur de fichiers                                                      }
{ ---------------------------------------------------------------------- }

Type
 TFileEnt = Record
  Name: String[60];
  Dir: Boolean;
 End;
 TFileArr = Array[0..399] Of TFileEnt;
 PFileArr = ^TFileArr;

Var
 FEnts: PFileArr;
 FCount: Integer;

Function JoinPath(Const Dir, Name: String): String;
Begin
 If Dir = '' Then JoinPath := Name
 Else If (Dir[Length(Dir)] = '\') Or (Dir[Length(Dir)] = '/') Then JoinPath := Dir + Name
 Else JoinPath := Dir + PathSep + Name;
End;

Function ParentDir(Const Dir: String): String;
Var
 I: Integer;
Begin
 I := Length(Dir);
 If (I > 1) And ((Dir[I] = '\') Or (Dir[I] = '/')) Then Dec(I);
 While (I > 1) And (Dir[I] <> '\') And (Dir[I] <> '/') Do Dec(I);
 If I <= 1 Then ParentDir := Copy(Dir, 1, 1)
 Else If (I = 3) And (Dir[2] = ':') Then ParentDir := Copy(Dir, 1, 3)
 Else ParentDir := Copy(Dir, 1, I - 1);
End;

Function MatchExt(Const Name: String; All: Boolean): Boolean;
Begin
 If All Then MatchExt := True Else MatchExt := ExtOf(Name) = '.PDF';
End;

Procedure ScanDir(Const Dir: String; All: Boolean);
Var
 SR: SearchRec;
 I, J: Integer;
 T: TFileEnt;
 Lower: Boolean;
Begin
 FCount := 0;
 If Length(Dir) > 1 Then Begin
  FEnts^[0].Name := '..'; FEnts^[0].Dir := True; FCount := 1;
 End;
 FindFirst(JoinPath(Dir, '*'), AnyFile, SR);
 While DosError = 0 Do Begin
  If (SR.Name <> '.') And (SR.Name <> '..') And (FCount < 400) Then Begin
   If (SR.Attr And Directory) <> 0 Then Begin
    FEnts^[FCount].Name := SR.Name; FEnts^[FCount].Dir := True; Inc(FCount);
   End
   Else If MatchExt(SR.Name, All) Then Begin
    FEnts^[FCount].Name := SR.Name; FEnts^[FCount].Dir := False; Inc(FCount);
   End;
  End;
  FindNext(SR);
 End;
 {$IFDEF FPC}
 FindClose(SR);
 {$ENDIF}
 For I := 1 To FCount - 1 Do Begin
  T := FEnts^[I];
  J := I - 1;
  While J >= 0 Do Begin
   If FEnts^[J].Name = '..' Then Lower := False
   Else If T.Name = '..' Then Lower := True
   Else If FEnts^[J].Dir <> T.Dir Then Lower := T.Dir
   Else Lower := UpStr(T.Name) < UpStr(FEnts^[J].Name);
   If Not Lower Then Break;
   FEnts^[J + 1] := FEnts^[J];
   Dec(J);
  End;
  FEnts^[J + 1] := T;
 End;
End;

Function FileDialog(Const Title: String; Var FileName: String; Save: Boolean; Const DefExt: String): Boolean;
{ boite de fichiers de PM ; DefExt ('.pdf') : masque et extension ajoutee }
Var N, Mask: String;
Begin
 FileDialog := False;
 If DefExt <> '' Then Mask := '*' + UpStr(DefExt) Else Mask := '*.*';
 N := FileName;
 If Not PmFileDlg(U2C(Title), Mask, N, Save) Then Begin Dirty := True; Exit; End;
 Dirty := True;
 If N = '' Then Exit;
 If Save And (ExtOf(N) = '') Then N := N + DefExt;
 If Save And FileExists(N) Then
  If MsgBox('Enregistrer', BaseName(N) + ' existe d�j�.|Voulez-vous le remplacer ?', 1) = 0 Then Exit;
 If (Not Save) And Not FileExists(N) Then Begin
  Dummy := MsgBox('Ouvrir', 'Fichier introuvable :|' + N, 0);
  Exit;
 End;
 FileName := N;
 FileDialog := True;
End;

{ ---------------------------------------------------------------------- }
{ Dialogues d'information                                                    }
{ ---------------------------------------------------------------------- }

Var
 InfoLines: Array[0..39] Of String[78];
 InfoN: Integer;

Procedure InfoBegin;
Begin
 InfoN := 0;
End;

Procedure InfoAdd(Const S: String);
Begin
 If InfoN < 40 Then Begin
  InfoLines[InfoN] := Copy(U2C(S), 1, 78);
  Inc(InfoN);
 End;
End;

Var
 InfoBannerH: Integer;   { hauteur de l'illustration en tete de InfoDialog (0 = aucune) }

{ Un objet de l'amas de documents : livre (0), dossier (1) ou feuilles (2) }
Procedure BannerItem(X, Y, W, Kind, Tint: Integer);
Const
 BookCols: Array[0..7] Of Integer = (4, 1, 2, 5, 12, 3, 13, 9);
Begin
 Case Kind Of
  0: Begin
   SetFillStyle(SolidFill, BookCols[Tint And 7]);
   Bar(X, Y, X + W, Y + 6);
   SetFillStyle(SolidFill, 14);
   Bar(X + 4, Y + 1, X + 6, Y + 5);
   Bar(X + W - 6, Y + 1, X + W - 4, Y + 5);
   SetColor(15); Line(X + 1, Y + 1, X + W - 1, Y + 1);
  End;
  1: Begin
   If Tint And 1 = 0 Then SetFillStyle(SolidFill, 14) Else SetFillStyle(SolidFill, 6);
   Bar(X, Y, X + W, Y + 6);
   SetFillStyle(SolidFill, 15);
   Bar(X + 2, Y - 1, X + 10, Y);
   SetColor(Black); Rectangle(X + 2, Y - 1, X + 10, Y);
  End;
  Else Begin
   SetFillStyle(SolidFill, 15);
   Bar(X, Y, X + W, Y + 6);
   SetColor(7);
   Line(X + 2, Y + 2, X + W - 2, Y + 2);
   Line(X + 2, Y + 4, X + W - 2, Y + 4);
  End;
 End;
 SetColor(Black);
 Rectangle(X, Y, X + W, Y + 6);
End;

{ Illustration : un bureau entouré de montagnes de feuilles, de dossiers et de livres }
Procedure DrawAboutBanner(X, Y, W, H: Integer);
Const
 LeftN: Array[0..7] Of Integer = (11, 10, 8, 7, 5, 4, 3, 2);
 RightN: Array[0..7] Of Integer = (10, 11, 9, 6, 6, 4, 3, 2);
Var
 I, J, N, BX, BY, BW, T, CX: Integer;
 P: Array[0..3] Of PointType;
Begin
 { mur et plancher }
 SetFillStyle(SolidFill, 11);
 Bar(X, Y, X + W - 1, Y + H - 1);
 SetFillStyle(SolidFill, 8);
 Bar(X, Y + H - 8, X + W - 1, Y + H - 1);
 SetColor(Black); Line(X, Y + H - 8, X + W - 1, Y + H - 8);
 { montagnes de documents, à gauche et à droite du bureau }
 For I := 0 To 7 Do Begin
  For J := 0 To 1 Do Begin
   If J = 0 Then Begin N := LeftN[I]; CX := X + 4 + I * 17; End
   Else Begin N := RightN[I]; CX := X + W - 38 - I * 17; End;
   For T := 0 To N - 1 Do Begin
    BW := 32 - ((I + T) Mod 3) * 4;
    BX := CX + ((I * 5 + T * 3 + J * 2) Mod 5) - 2;
    BY := Y + H - 15 - T * 7;
    BannerItem(BX, BY, BW, (I * 2 + T * 3 + J) Mod 3, I + T * 3 + J);
   End;
  End;
 End;
 { feuilles qui volent }
 P[0].X := X + 126; P[0].Y := Y + 12; P[1].X := X + 148; P[1].Y := Y + 8;
 P[2].X := X + 152; P[2].Y := Y + 24; P[3].X := X + 130; P[3].Y := Y + 28;
 SetFillStyle(SolidFill, 15); FillPoly(4, P);
 SetColor(Black); Line(X + 126, Y + 12, X + 148, Y + 8); Line(X + 148, Y + 8, X + 152, Y + 24);
 Line(X + 152, Y + 24, X + 130, Y + 28); Line(X + 130, Y + 28, X + 126, Y + 12);
 SetColor(7); Line(X + 130, Y + 16, X + 147, Y + 13); Line(X + 131, Y + 21, X + 149, Y + 18);
 P[0].X := X + 318; P[0].Y := Y + 20; P[1].X := X + 338; P[1].Y := Y + 12;
 P[2].X := X + 346; P[2].Y := Y + 26; P[3].X := X + 324; P[3].Y := Y + 34;
 SetFillStyle(SolidFill, 15); FillPoly(4, P);
 SetColor(Black); Line(X + 318, Y + 20, X + 338, Y + 12); Line(X + 338, Y + 12, X + 346, Y + 26);
 Line(X + 346, Y + 26, X + 324, Y + 34); Line(X + 324, Y + 34, X + 318, Y + 20);
 SetColor(7); Line(X + 323, Y + 23, X + 339, Y + 17); Line(X + 326, Y + 28, X + 342, Y + 22);
 { le bureau }
 T := Y + H - 34;
 SetFillStyle(SolidFill, 6);
 Bar(X + 166, T, X + 298, T + 5);
 Bar(X + 172, T + 6, X + 292, Y + H - 9);
 SetColor(14); Line(X + 166, T, X + 298, T);
 SetColor(Black);
 Rectangle(X + 166, T, X + 298, T + 5);
 Rectangle(X + 172, T + 6, X + 292, Y + H - 9);
 Line(X + 232, T + 6, X + 232, Y + H - 9);
 Rectangle(X + 188, T + 11, X + 216, T + 17);
 Rectangle(X + 248, T + 11, X + 276, T + 17);
 { écran avec un document PDF }
 SetFillStyle(SolidFill, 8);
 Bar(X + 227, T - 7, X + 237, T - 1);
 Bar(X + 218, T - 2, X + 246, T - 1);
 SetFillStyle(SolidFill, Black);
 Bar(X + 204, T - 42, X + 260, T - 8);
 SetFillStyle(SolidFill, 9);
 Bar(X + 207, T - 39, X + 257, T - 11);
 SetFillStyle(SolidFill, 15);
 Bar(X + 222, T - 37, X + 242, T - 13);
 SetFillStyle(SolidFill, 4);
 Bar(X + 222, T - 37, X + 242, T - 32);
 SetColor(7);
 Line(X + 225, T - 28, X + 239, T - 28); Line(X + 225, T - 24, X + 239, T - 24);
 Line(X + 225, T - 20, X + 235, T - 20);
 { lampe de bureau et tasse }
 SetColor(8); Line(X + 282, T, X + 278, T - 22); Line(X + 278, T - 22, X + 270, T - 28);
 SetFillStyle(SolidFill, 14); SetColor(Black);
 FillEllipse(X + 268, T - 29, 8, 4);
 SetFillStyle(SolidFill, 15);
 Bar(X + 180, T - 9, X + 188, T - 1);
 Rectangle(X + 180, T - 9, X + 188, T - 1);
 SetFillStyle(SolidFill, 6);
 Bar(X + 181, T - 8, X + 187, T - 6);
 { titre }
 SetTextStyle(DefaultFont, HorizDir, 2);
 SetColor(White);
 OutTextXY(X + W Div 2 - 55, Y + 7, 'Acrodoc');
 SetColor(Blue);
 OutTextXY(X + W Div 2 - 56, Y + 6, 'Acrodoc');
 SetTextStyle(DefaultFont, HorizDir, 1);
 { cadre en creux }
 SetColor(8); Line(X - 1, Y - 1, X + W, Y - 1); Line(X - 1, Y - 1, X - 1, Y + H);
 SetColor(15); Line(X - 1, Y + H, X + W, Y + H); Line(X + W, Y - 1, X + W, Y + H);
End;

Procedure InfoDialogD(Const Title: String; W: Integer);
Var
 I, H, K: Integer;
 Done, Ext: Boolean;
Begin
 H := 70 + InfoN * 11 + InfoBannerH;
 HideMouse;
 DlgFrame(W, H, Title);
 If InfoBannerH > 0 Then DrawAboutBanner(DlgX1 + 8, DlgY1 + 24, W - 16, InfoBannerH - 8);
 SetColor(Black);
 For I := 0 To InfoN - 1 Do
  OutTextXY(DlgX1 + 14, DlgY1 + 26 + InfoBannerH + I * 11, InfoLines[I]);
 PushButton(DlgX1 + W Div 2 - 40, DlgY2 - 28, DlgX1 + W Div 2 + 40, DlgY2 - 8, 'OK', False);
 ShowMouse;
 Done := False;
 PollMouse; OMB := MB_;
 While Not Done Do Begin
  PollMouse;
  If MouseClicked Then
   If InRect(MX_, MY_, DlgX1 + W Div 2 - 40, DlgY2 - 28, DlgX1 + W Div 2 + 40, DlgY2 - 8) Then Done := True;
  K := GetKeyEx(Ext);
  If (K = 13) Or (K = 27) Then Done := True;
  Delay(10);
 End;
 WaitMouseUp;
End;
Procedure InfoDialog(Const Title: String; W: Integer);
Begin
 MxCatWant := True; InfoDialogD(Title, W); MxCatDone;
End;

{ ---------------------------------------------------------------------- }
{ Opérations sur le document                                               }
{ ---------------------------------------------------------------------- }

Var
 Imported: Boolean;
 EditNew: Boolean;
 EditBackup: String;
 SigName: String;
 InkX, InkY: Array[0..399] Of Integer;
 InkN: Integer;
 LastNavPage: Integer;
 SortIdx: PLArr;
 LastHintX, LastHintY: LongInt;
 MoveDX, MoveDY: LongInt;

Const
 StampNames: String = 'APPROUVÉ|REFUSÉ|CONFIDENTIEL|BROUILLON|FINAL|URGENT|COPIE|POUR COMMENTAIRE';
 StampCols: Array[0..7] Of LongInt = ($00A000, $FF0000, $FF0000, $0000C0, $00A000, $FF0000, $0000C0, $0000C0);

Procedure DropUndo;
Begin
 If UndoTop > 0 Then Begin
  Dec(UndoTop);
  FreeUndoRec(UndoStack[UndoTop]);
 End;
End;

Procedure FullRefresh;
Begin
 Relayout;
 RedrawAll;
End;

Procedure ZoomTo(Z: Integer; CX, CY: LongInt);
Var
 FX, FY: Real;
Begin
 If Z < 10 Then Z := 10;
 If Z > 1600 Then Z := 1600;
 FX := (ScrollX + CX) / Scale;
 FY := (ScrollY + CY) / Scale;
 Zoom := Z;
 FitMode := 0;
 Relayout;
 ScrollY := Round(FY * Scale) - CY;
 ScrollX := Round(FX * Scale) - CX;
 ClampScroll;
 If Continuous <> 0 Then UpdateCurPage;
 RedrawAll;
End;

Procedure StepZoom(Dir: Integer);
Var
 I, Z: Integer;
Begin
 Z := Zoom;
 If Dir > 0 Then Begin
  Z := ZoomSteps[11];
  For I := 11 DownTo 0 Do If ZoomSteps[I] > Zoom Then Z := ZoomSteps[I];
  If Zoom >= 800 Then Z := Zoom;
 End
 Else Begin
  Z := ZoomSteps[0];
  For I := 0 To 11 Do If ZoomSteps[I] < Zoom Then Z := ZoomSteps[I];
  If Zoom <= 25 Then Z := Zoom;
 End;
 ZoomTo(Z, ViewW Div 2, ViewH Div 2);
End;

Procedure SetTool(T: Integer);
Begin
 CurTool := T;
 DragMode := 0;
 DrawToolbar;
End;

Function ConfirmDiscard: Boolean;
Forward;

Procedure OpenFileByName(Const Name: String);
Var
 Err: String;
Begin
 ShowProgress('Ouverture de ' + BaseName(Name) + '... (Échap pour interrompre)');
 If ImportPDF(Name, False, Err) Then Begin
  DocName := Name;
  Modified := False;
  Imported := True;
  CurPage := 1;
  SelObj := -1; FindObj := -1;
  ClearUndo;
  ScrollX := 0; ScrollY := 0;
  FitMode := 1;
  NavScroll := 0;
  FullRefresh;
  If LoadNotice <> '' Then Notice(LoadNotice);
 End
 Else Begin
  If PageCount = 0 Then NewDocument;
  FullRefresh;
  Notice(Err);
 End;
End;

{ Enregistre sous Name : mise à jour incrémentale si le document vient d'un
  PDF (le contenu d'origine est conservé), sinon écriture complète. Le
  document est ensuite rechargé depuis le fichier enregistré. }
Function SaveTo(Const Name: String): Boolean;
Var
 Err: String;
 R: Integer;
 SP, SZ, SF: LongInt;
 SSY: LongInt;
 Ok: Boolean;
Begin
 SaveTo := False;
 ShowProgress('Enregistrement...');
 Ok := False;
 If SrcValid And NeedFullRewrite Then Begin
  RedrawAll;
  If MsgBox('Enregistrer', 'Les biffures doivent supprimer définitivement le contenu : le document va être réécrit complètement (les polices incorporées d''origine seront remplacées).', 1) = 0 Then Exit;
  ShowProgress('Enregistrement...');
 End
 Else If SrcValid Then Begin
  Ok := SaveIncremental(Name, Err);
  If Not Ok Then Begin
   RedrawAll;
   R := MsgBox('Enregistrer', Err + '|Réécrire le document complet ? Les polices incorporées d''origine seraient alors remplacées.', 1);
   If R = 0 Then Exit;
   ShowProgress('Enregistrement...');
  End;
 End;
 If Not Ok Then Begin
  If Not SaveAsPDF(Name) Then Begin
   RedrawAll;
   Notice('Impossible d''enregistrer le fichier.');
   Exit;
  End;
 End;
 { rechargement du fichier enregistré en conservant la vue }
 SP := CurPage; SZ := Zoom; SF := FitMode; SSY := ScrollY;
 OpenFileByName(Name);
 If PageCount >= 1 Then Begin
  Zoom := SZ; FitMode := SF;
  Relayout;
  GotoPage(SP);
  If (Continuous <> 0) And (FitMode = 0) Then ScrollY := SSY;
  ClampScroll;
  RedrawAll;
 End;
 SetStatus('Document enregistré : ' + BaseName(Name));
 SaveTo := True;
End;

Function DoSaveAs: Boolean;
Var
 Name: String;
Begin
 DoSaveAs := False;
 Name := DocName;
 If Name = '' Then Name := 'document.pdf';
 FileMaskAll := False;
 If Not FileDialog('Enregistrer sous', Name, True, '.pdf') Then Begin RedrawAll; Exit; End;
 DoSaveAs := SaveTo(Name);
End;

Function DoSave: Boolean;
Begin
 If DocName = '' Then DoSave := DoSaveAs
 Else DoSave := SaveTo(DocName);
End;

Function ConfirmDiscard: Boolean;
Var
 R: Integer;
Begin
 ConfirmDiscard := True;
 If Not Modified Then Exit;
 R := MsgBox('Acrodoc', 'Enregistrer les modifications apportées au document ?', 2);
 If R = 0 Then ConfirmDiscard := False
 Else If R = 1 Then Begin
  If Not DoSave Then ConfirmDiscard := False;
 End;
End;

Function ChangeExt_(Const Name, NewExt: String): String;
Var
 I: Integer;
Begin
 If Name = '' Then Begin ChangeExt_ := 'document' + NewExt; Exit; End;
 I := Length(Name);
 While (I > 0) And (Name[I] <> '.') And (Name[I] <> '\') And (Name[I] <> '/') Do Dec(I);
 If (I > 0) And (Name[I] = '.') Then ChangeExt_ := Copy(Name, 1, I - 1) + NewExt Else ChangeExt_ := Name + NewExt;
End;

Procedure ExportText(Const Name: String);
Var
 T: Text;
 Pg, I, J, N, K: Integer;
 Lower: Boolean;
 LastY: LongInt;
 First: Boolean;
 PrevX2: LongInt;
 A, B: ^TObjRec;
Begin
 GetMem(SortIdx, (ObjCount + 2) * SizeOf(LongInt));
 {$I-}
 Assign(T, Name);
 Rewrite(T);
 {$I+}
 If IOResult <> 0 Then Begin FreeMem(SortIdx, (ObjCount + 2) * SizeOf(LongInt)); Notice('Impossible de créer le fichier.'); Exit; End;
 For Pg := 1 To PageCount Do Begin
  WriteLn(T, '--- Page ', Pg, ' ---');
  N := 0;
  For I := 0 To ObjCount - 1 Do
   If (ObjP(I)^.Page = Pg) And (ObjP(I)^.Kind = K_TEXT) Then Begin
    K := N - 1;
    While K >= 0 Do Begin
     A := @ObjP(SortIdx^[K])^;
     B := @ObjP(I)^;
     If IAbs(A^.Y1 - B^.Y1) <= B^.Size Div 2 Then Lower := B^.X1 < A^.X1 Else Lower := B^.Y1 < A^.Y1;
     If Not Lower Then Break;
     SortIdx^[K + 1] := SortIdx^[K];
     Dec(K);
    End;
    SortIdx^[K + 1] := I;
    Inc(N);
   End;
  First := True;
  LastY := 0; PrevX2 := 0;
  For J := 0 To N - 1 Do Begin
   A := @ObjP(SortIdx^[J])^;
   If Not First Then Begin
    If IAbs(A^.Y1 - LastY) > A^.Size Div 2 + 1 Then WriteLn(T)
    Else If A^.X1 - PrevX2 > 1 Then Write(T, ' ');
   End;
   Write(T, A^.Txt);
   LastY := A^.Y1; PrevX2 := A^.X2;
   First := False;
  End;
  If Not First Then WriteLn(T);
  WriteLn(T);
 End;
 Close(T);
 FreeMem(SortIdx, (ObjCount + 2) * SizeOf(LongInt));
End;

Procedure ExportBMP(Const Name: String);
Var
 F: File;
 W, H, Bands, BandH, B, Y, X, Row, RowBytes, I, Sc: LongInt;
 Hdr: Array[0..53] Of Byte;
 Pal: Array[0..15, 0..3] Of Byte;
 Line_: Array[0..399] Of Byte;
 DW, DH: LongInt;
 FileSz: LongInt;
 SavedZoom: Integer;
 Pix: Array[0..1] Of Byte;
 YY: LongInt;
Begin
 DW := DispWOf(CurPage, 1024);
 DH := DispHOf(CurPage, 1024);
 Sc := (500 * 1024) Div IMax(1, DW);
 If Sc > 2048 Then Sc := 2048;
 W := DispWOf(CurPage, Sc);
 H := DispHOf(CurPage, Sc);
 If W > 500 Then W := 500;
 RowBytes := ((W + 1) Div 2 + 3) And (Not 3);
 FillChar(Hdr, SizeOf(Hdr), 0);
 Hdr[0] := 66; Hdr[1] := 77;
 FileSz := 54 + 64 + RowBytes * H;
 Hdr[2] := FileSz And 255; Hdr[3] := (FileSz Shr 8) And 255; Hdr[4] := (FileSz Shr 16) And 255; Hdr[5] := FileSz Shr 24;
 Hdr[10] := 118; Hdr[14] := 40;
 Hdr[18] := W And 255; Hdr[19] := W Shr 8;
 Hdr[22] := H And 255; Hdr[23] := H Shr 8;
 Hdr[26] := 1; Hdr[28] := 4;
 Hdr[34] := (RowBytes * H) And 255; Hdr[35] := ((RowBytes * H) Shr 8) And 255; Hdr[36] := ((RowBytes * H) Shr 16) And 255;
 Hdr[46] := 16;
 For I := 0 To 15 Do Begin
  Pal[I, 0] := (PalRgb[I] And 255); Pal[I, 1] := (PalRgb[I] Shr 8) And 255; Pal[I, 2] := (PalRgb[I] Shr 16) And 255; Pal[I, 3] := 0;
 End;
 {$I-}
 Assign(F, Name);
 Rewrite(F, 1);
 {$I+}
 If IOResult <> 0 Then Begin Notice('Impossible de créer le fichier.'); Exit; End;
 BlockWrite(F, Hdr, 54);
 BlockWrite(F, Pal, 64);
 BandH := ViewH;
 Bands := (H + BandH - 1) Div BandH;
 For B := Bands - 1 DownTo 0 Do Begin
  HideMouse;
  SetViewPort(ViewL, ViewT, ViewR, ViewB, True);
  CullW := ViewW - 1; CullH := ViewH - 1;
  SetFillStyle(SolidFill, White);
  Bar(0, 0, ViewW, ViewH);
  RenderPage(CurPage, 0, -B * BandH, Sc, False);
  Y := IMin(BandH - 1, H - 1 - B * BandH);
  While Y >= 0 Do Begin
   FillChar(Line_, SizeOf(Line_), 0);
   X := 0;
   While X < W Do Begin
    If Pal256 Then Pix[0] := Nearest16(IdxRgb(GetPixel(X, Y))) Else Pix[0] := GetPixel(X, Y) And 15;
    If X + 1 < W Then Begin
     If Pal256 Then Pix[1] := Nearest16(IdxRgb(GetPixel(X + 1, Y))) Else Pix[1] := GetPixel(X + 1, Y) And 15;
    End
    Else Pix[1] := 0;
    Line_[X Div 2] := (Pix[0] Shl 4) Or Pix[1];
    Inc(X, 2);
   End;
   BlockWrite(F, Line_, RowBytes);
   Dec(Y);
  End;
 End;
 SetFullView;
 Close(F);
 ShowMouse;
 FullRefresh;
End;

{ ---------------------------------------------------------------------- }
{ Création d'objets                                                         }
{ ---------------------------------------------------------------------- }

Function CreateText(Pg: Integer; X, Y: LongInt): Integer;
Var
 I: Integer;
 Tdx, Tdy, Tvx, Tvy: Real;
Begin
 PushUndo;
 I := NewObj(K_TEXT, Pg);
 If I < 0 Then Begin DropUndo; Notice('Limite d''objets atteinte.'); CreateText := -1; Exit; End;
 With ObjP(I)^ Do Begin
  X1 := X; Y1 := Y - CurSize Div 2;
  Size := CurSize;
  Style := CurFam * 4 + CurStyle;
  Rgb := ToolRgb[TL_TEXT];
  Txt := '';
  PN := (CurAngle Mod 360) * 10;
 End;
 { origine : le point cliqué est au milieu du début de la ligne }
 TextDirs(ObjP(I)^.PN, Tdx, Tdy, Tvx, Tvy);
 ObjP(I)^.X1 := Round(X - Tvx * TextLineH(ObjP(I)^) / 2);
 ObjP(I)^.Y1 := Round(Y - Tvy * TextLineH(ObjP(I)^) / 2);
 If ObjP(I)^.PN <> 0 Then PackOrigin(ObjP(I)^, ObjP(I)^.X1, ObjP(I)^.Y1);
 RecalcBox(I);
 CreateText := I;
End;

Procedure StartEdit(Idx: Integer; IsNew: Boolean);
Begin
 Editing := True;
 EditObj := Idx;
 EditNew := IsNew;
 EditBackup := ObjP(Idx)^.Txt;
 EditCaret := Length(ObjP(Idx)^.Txt);
 SelObj := Idx;
 If Not IsNew Then PushUndo;
 RedrawView;
End;

Procedure EndEdit(Commit: Boolean);
Begin
 If Not Editing Then Exit;
 Editing := False;
 If (EditObj >= 0) And (EditObj < ObjCount) Then Begin
  If (Not Commit) Or (ObjP(EditObj)^.Txt = '') Then Begin
   If EditNew Or (ObjP(EditObj)^.Txt = '') Then Begin
    DelObj(EditObj);
    If EditNew Then DropUndo;
   End
   Else Begin
    ObjP(EditObj)^.Txt := EditBackup;
    RecalcBox(EditObj);
    DropUndo;
   End;
  End
  Else RecalcBox(EditObj);
 End;
 EditObj := -1;
 RedrawView;
End;

Procedure EditKey(K: Integer; Ext: Boolean);
Var
 O: ^TObjRec;
Begin
 If (EditObj < 0) Or (EditObj >= ObjCount) Then Begin Editing := False; Exit; End;
 O := @ObjP(EditObj)^;
 If Ext Then Begin
  Case K Of
   75: If EditCaret > 0 Then Dec(EditCaret);
   77: If EditCaret < Length(O^.Txt) Then Inc(EditCaret);
   71: EditCaret := 0;
   79: EditCaret := Length(O^.Txt);
   83: If EditCaret < Length(O^.Txt) Then Delete(O^.Txt, EditCaret + 1, 1);
  End;
 End
 Else Begin
  Case K Of
   13: Begin EndEdit(True); Exit; End;
   27: Begin EndEdit(False); Exit; End;
   8: If EditCaret > 0 Then Begin Delete(O^.Txt, EditCaret, 1); Dec(EditCaret); End;
  Else
   If (K >= 32) And (K <> 127) And (Length(O^.Txt) < 118) Then Begin
    If K >= 128 Then K := Dos2Win(K);
    Insert(Chr(K), O^.Txt, EditCaret + 1);
    Inc(EditCaret);
   End;
  End;
 End;
 RecalcBox(EditObj);
 RedrawView;
End;

Function NewShape(Kind, Pg: Integer; AX1, AY1, AX2, AY2: LongInt; Tool: Integer): Integer;
Var
 I: Integer;
Begin
 I := NewObj(Kind, Pg);
 NewShape := I;
 If I < 0 Then Exit;
 With ObjP(I)^ Do Begin
  X1 := AX1; Y1 := AY1; X2 := AX2; Y2 := AY2;
  Rgb := ToolRgb[Tool];
  Wd := CurWidth;
 End;
End;

{ Marque le texte dans le rectangle (surlignage, soulignement, barré) }
Procedure MarkText(Kind, Pg: Integer; RX1, RY1, RX2, RY2: LongInt; Tool: Integer);
Var
 I, N, J, A, B, L, Idx, Made: Integer;
 TX1, TY1, TX2, TY2, CY: LongInt;
 Tot, Acc, Wc: Real;
 O: ^TObjRec;
 S: LongInt;
 NX1, NX2: LongInt;
Begin
 If RX1 > RX2 Then Begin S := RX1; RX1 := RX2; RX2 := S; End;
 If RY1 > RY2 Then Begin S := RY1; RY1 := RY2; RY2 := S; End;
 PushUndo;
 N := ObjCount;
 Made := 0;
 For I := 0 To N - 1 Do Begin
  O := @ObjP(I)^;
  If (O^.Page <> Pg) Or (O^.Kind <> K_TEXT) Or (TextAng(O^) <> 0) Then Continue;
  NormBox(O^, TX1, TY1, TX2, TY2);
  CY := (TY1 + TY2) Div 2;
  If (CY < RY1) Or (CY > RY2) Or (TX2 <= RX1) Or (TX1 >= RX2) Then Continue;
  L := Length(O^.Txt);
  If L = 0 Then Continue;
  Tot := 0;
  For J := 1 To L Do Tot := Tot + CharW(O^.Style Shr 2, O^.Style And 3, Ord(O^.Txt[J]));
  If Tot < 1 Then Continue;
  A := 0; B := 0;
  Acc := 0;
  For J := 1 To L Do Begin
   Wc := CharW(O^.Style Shr 2, O^.Style And 3, Ord(O^.Txt[J]));
   If (TX1 + (Acc + Wc / 2) / Tot * (TX2 - TX1) >= RX1) And (TX1 + (Acc + Wc / 2) / Tot * (TX2 - TX1) <= RX2) Then Begin
    If A = 0 Then A := J;
    B := J;
   End;
   Acc := Acc + Wc;
  End;
  If A = 0 Then Continue;
  Acc := 0;
  NX1 := TX1; NX2 := TX2;
  For J := 1 To L Do Begin
   Wc := CharW(O^.Style Shr 2, O^.Style And 3, Ord(O^.Txt[J]));
   If J = A Then NX1 := TX1 + Round(Acc / Tot * (TX2 - TX1));
   If J = B Then NX2 := TX1 + Round((Acc + Wc) / Tot * (TX2 - TX1));
   Acc := Acc + Wc;
  End;
  Idx := NewShape(Kind, Pg, NX1, TY1, NX2, TY2, Tool);
  If Idx < 0 Then Break;
  Inc(Made);
  If Made >= 150 Then Break;
 End;
 If Made = 0 Then Begin
  If (RX2 - RX1 < 3) Or (RY2 - RY1 < 3) Then Begin DropUndo; Exit; End;
  Idx := NewShape(Kind, Pg, RX1, RY1, RX2, RY2, Tool);
  If Idx < 0 Then Begin DropUndo; Exit; End;
 End;
 SelObj := ObjCount - 1;
End;

Procedure ChoiceStamp(Pg: Integer; CX, CY: LongInt);
Var
 I, K: Integer;
 Txt: String;
 W, H: LongInt;
Begin
 FldInit;
 FldChoice('Tampon', StampNames, 0);
 If Not FormDialog('Ajouter un tampon') Then Begin RedrawAll; Exit; End;
 K := Fields[0].Cur;
 Txt := U2W(ChoiceText(StampNames, K));
 PushUndo;
 I := NewObj(K_STAMP, Pg);
 If I < 0 Then Begin DropUndo; RedrawAll; Exit; End;
 W := TextLenPts(Txt, 18, 0, 1) + 12;
 H := 32;
 With ObjP(I)^ Do Begin
  X1 := CX - W Div 2; Y1 := CY - H Div 2; X2 := X1 + W; Y2 := Y1 + H;
  Size := 18; Style := 1; Wd := 2;
  Rgb := StampCols[K]; Rgb2 := $FFFFFF;
 End;
 ObjP(I)^.Txt := Txt;
 SelObj := I;
 RedrawAll;
End;

Procedure PlaceSignature(Pg: Integer; CX, CY: LongInt);
Var
 Nm, Reason, S1, S2: String;
 Y, M, D, DW, H, Mi, S, S1_: Word;
 I: Integer;
 W: LongInt;
Begin
 FldInit;
 FldText('Nom du signataire', SigName, 40);
 FldText('Motif (facultatif)', '', 40);
 FldColor('Couleur', $0000C0);
 If Not FormDialog('Signer le document') Then Begin RedrawAll; Exit; End;
 SigName := Fields[0].Val;
 If SigName = '' Then SigName := 'Signataire';
 Nm := U2W(SigName);
 Reason := U2W(Fields[1].Val);
 GetDate(Y, M, D, DW);
 GetTime(H, Mi, S, S1_);
 PushUndo;
 W := TextLenPts(Nm, 22, 1, 3) + 8;
 If W < 120 Then W := 120;
 I := NewObj(K_TEXT, Pg);
 If I >= 0 Then With ObjP(I)^ Do Begin
  X1 := CX - W Div 2 + 4; Y1 := CY - 30; Size := 22; Style := 1 * 4 + 3; Rgb := Fields[2].Mn; Txt := Nm;
  RecalcBox(I);
 End;
 I := NewObj(K_LINE, Pg);
 If I >= 0 Then With ObjP(I)^ Do Begin
  X1 := CX - W Div 2; Y1 := CY + 2; X2 := CX + W Div 2; Y2 := CY + 2; Wd := 1; Rgb := 0;
 End;
 S1 := 'Signé numériquement par ' + SigName;
 S2 := 'Date : ' + IStr(Y) + '.' + Pad2(M) + '.' + Pad2(D) + ' ' + Pad2(H) + ':' + Pad2(Mi) + ':' + Pad2(S);
 I := NewObj(K_TEXT, Pg);
 If I >= 0 Then With ObjP(I)^ Do Begin
  X1 := CX - W Div 2; Y1 := CY + 4; Size := 7; Style := 0; Rgb := $606060; Txt := U2W(S1);
  RecalcBox(I);
 End;
 I := NewObj(K_TEXT, Pg);
 If I >= 0 Then With ObjP(I)^ Do Begin
  X1 := CX - W Div 2; Y1 := CY + 12; Size := 7; Style := 0; Rgb := $606060; Txt := S2;
  RecalcBox(I);
 End;
 If Reason <> '' Then Begin
  I := NewObj(K_TEXT, Pg);
  If I >= 0 Then With ObjP(I)^ Do Begin
   X1 := CX - W Div 2; Y1 := CY + 20; Size := 7; Style := 0; Rgb := $606060; Txt := 'Motif : ' + Reason;
   RecalcBox(I);
  End;
 End;
 SelObj := -1;
 RedrawAll;
End;

Procedure FinishInk(Pg: Integer);
Var
 I, K, Pool: Integer;
Begin
 If InkN < 2 Then Exit;
 PushUndo;
 Pool := PoolAlloc(InkN);
 If Pool < 0 Then Begin DropUndo; Notice('Mémoire des tracés pleine.'); Exit; End;
 I := NewObj(K_INK, Pg);
 If I < 0 Then Begin DropUndo; Exit; End;
 For K := 0 To InkN - 1 Do Begin PoolXP(Pool + K)^ := InkX[K]; PoolYP(Pool + K)^ := InkY[K]; End;
 With ObjP(I)^ Do Begin
  P0 := Pool; PN := InkN; Wd := CurWidth; Rgb := ToolRgb[TL_PENCIL];
 End;
 RecalcBox(I);
 SelObj := I;
End;

{ ---------------------------------------------------------------------- }
{ Presse-papiers interne                                                     }
{ ---------------------------------------------------------------------- }

Procedure DoCopy;
Var
 K, Step: Integer;
Begin
 If (SelObj < 0) Or (SelObj >= ObjCount) Then Exit;
 Clip := ObjP(SelObj)^;
 ClipPtCount := 0;
 If (Clip.Kind In [K_POLY, K_INK]) Or ((Clip.Kind = K_GRAD) And (Clip.PN > 0)) Then Begin
  Step := (Clip.PN + 98) Div 99;
  If Step < 1 Then Step := 1;
  K := 0;
  While (K < Clip.PN) And (ClipPtCount < 99) Do Begin
   ClipPts[ClipPtCount * 2] := PoolXP(Clip.P0 + K)^;
   ClipPts[ClipPtCount * 2 + 1] := PoolYP(Clip.P0 + K)^;
   Inc(ClipPtCount);
   Inc(K, Step);
  End;
 End;
 ClipValid := True;
End;

Procedure DoPaste(DX, DY: LongInt);
Var
 I, K, Pool: Integer;
Begin
 If Not ClipValid Then Exit;
 PushUndo;
 Pool := 0;
 If (Clip.Kind In [K_POLY, K_INK]) Or ((Clip.Kind = K_GRAD) And (Clip.PN > 0)) Then Begin
  Pool := PoolAlloc(ClipPtCount);
  If Pool < 0 Then Begin DropUndo; Exit; End;
 End;
 I := NewObj(Clip.Kind, CurPage);
 If I < 0 Then Begin DropUndo; Exit; End;
 ObjP(I)^ := Clip;
 ObjP(I)^.Page := CurPage;
 If (Clip.Kind In [K_POLY, K_INK]) Or ((Clip.Kind = K_GRAD) And (Clip.PN > 0)) Then Begin
  For K := 0 To ClipPtCount - 1 Do Begin
   PoolXP(Pool + K)^ := ClipPts[K * 2];
   PoolYP(Pool + K)^ := ClipPts[K * 2 + 1];
  End;
  ObjP(I)^.P0 := Pool;
  ObjP(I)^.PN := ClipPtCount;
 End;
 MoveObj(I, DX, DY);
 SelObj := I;
End;

{ ---------------------------------------------------------------------- }
{ Recherche                                                                  }
{ ---------------------------------------------------------------------- }

Function ContainsText(Const Hay, Needle: String; CaseS: Boolean): Boolean;
Begin
 If CaseS Then ContainsText := Pos(Needle, Hay) > 0
 Else ContainsText := Pos(UpStr(Needle), UpStr(Hay)) > 0;
End;

Procedure AcFindNext;
Var
 Start, P, I, Pass, FirstI: Integer;
 Found: Integer;
Begin
 If FindText = '' Then Exit;
 Found := -1;
 If (FindObj >= 0) And (FindObj < ObjCount) Then Begin
  Start := ObjP(FindObj)^.Page; FirstI := FindObj + 1;
 End
 Else Begin Start := CurPage; FirstI := 0; End;
 For Pass := 0 To PageCount Do Begin
  P := ((Start - 1 + Pass) Mod PageCount) + 1;
  For I := 0 To ObjCount - 1 Do Begin
   If ObjP(I)^.Page <> P Then Continue;
   If ObjP(I)^.Kind <> K_TEXT Then Continue;
   If (Pass = 0) And (I < FirstI) Then Continue;
   If (Pass = PageCount) And (I >= FirstI) Then Continue;
   If ContainsText(ObjP(I)^.Txt, FindText, FindCase) Then Begin Found := I; Break; End;
  End;
  If Found >= 0 Then Break;
 End;
 If Found < 0 Then Begin
  FindObj := -1;
  RedrawAll;
  Notice('Aucune occurrence de "' + FindText + '" trouvée.');
  Exit;
 End;
 FindObj := Found;
 ScrollToObj(Found);
 RedrawAll;
End;

{ ---------------------------------------------------------------------- }
{ Propriétés                                                                 }
{ ---------------------------------------------------------------------- }

Procedure DocProperties;
Var
 S: String;
Begin
 FldInit;
 FldText('Titre', DocTitle, 79);
 FldText('Auteur', DocAuthor, 79);
 FldText('Sujet', DocSubject, 79);
 FldText('Mots-clés', DocKeywords, 79);
 FldText('Application', DocCreator, 79);
 FldLabel('Fichier : ' + Copy(BaseName(DocName), 1, 36));
 FldLabel('Pages : ' + IStr(PageCount) + '   Objets : ' + IStr(ObjCount));
 If FormDialog('Propriétés du document') Then Begin
  DocTitle := Fields[0].Val; DocAuthor := Fields[1].Val; DocSubject := Fields[2].Val;
  DocKeywords := Fields[3].Val; DocCreator := Fields[4].Val;
  Modified := True;
  InfoDirty := True;
 End;
 RedrawAll;
End;

Procedure ObjProperties;
Var
 O: ^TObjRec;
 K: Integer;
 Style: Integer;
Begin
 If (SelObj < 0) Or (SelObj >= ObjCount) Then Exit;
 O := @ObjP(SelObj)^;
 K := O^.Kind;
 FldInit;
 FldLabel('Type : ' + KindName(K) + '   Page ' + IStr(O^.Page));
 Case K Of
  K_TEXT: Begin
   FldText('Texte', O^.Txt, 118);
   FldNum('Taille (pt)', O^.Size, 4, 200);
   FldChoice('Police', 'Helvetica|Times|Courier', O^.Style Shr 2);
   FldCheck('Gras', (O^.Style And 1) <> 0);
   FldCheck('Italique', (O^.Style And 2) <> 0);
   FldColor('Couleur', O^.Rgb);
   FldNum('Angle (degrés)', TextAng(O^) Div 10, 0, 359);
  End;
  K_LINE, K_ARROW, K_INK: Begin
   FldNum('Épaisseur (pt)', O^.Wd, 1, 20);
   FldColor('Couleur', O^.Rgb);
  End;
  K_RECT, K_OVAL, K_POLY: Begin
   FldNum('Épaisseur (pt)', O^.Wd, 1, 20);
   FldColor('Couleur du contour', O^.Rgb);
   FldChoice('Remplissage', 'Aucun|Plein|Contour et plein', O^.Fill);
   FldColor('Couleur de remplissage', O^.Rgb2);
  End;
  K_HILITE, K_UNDER, K_STRIKE, K_NOTE: Begin
   FldColor('Couleur', O^.Rgb);
   FldText('Commentaire', O^.Txt, 118);
  End;
  K_STAMP: Begin
   FldText('Texte', O^.Txt, 40);
   FldColor('Couleur', O^.Rgb);
  End;
 Else
  Begin
   FldLabel('Aucune propriété modifiable.');
  End;
 End;
 If FormDialog('Propriétés de l''objet') Then Begin
  PushUndo;
  O := @ObjP(SelObj)^;
  Case K Of
   K_TEXT: Begin
    O^.Txt := U2W(Fields[1].Val); O^.Size := FInt(2);
    O^.Style := FInt(3) * 4 + FInt(4) + FInt(5) * 2;
    O^.Rgb := FInt(6);
    RecalcBox(SelObj);
    SetTextAngle(SelObj, FInt(7) * 10);
   End;
   K_LINE, K_ARROW, K_INK: Begin O^.Wd := FInt(1); O^.Rgb := FInt(2); End;
   K_RECT, K_OVAL, K_POLY: Begin
    O^.Wd := FInt(1); O^.Rgb := FInt(2); O^.Fill := FInt(3); O^.Rgb2 := FInt(4);
    If (O^.Fill = 1) Then O^.Rgb := O^.Rgb2;
   End;
   K_HILITE, K_UNDER, K_STRIKE, K_NOTE: Begin O^.Rgb := FInt(1); O^.Txt := U2W(Fields[2].Val); End;
   K_STAMP: Begin
    O^.Txt := U2W(Fields[1].Val); O^.Rgb := FInt(2);
    O^.X2 := O^.X1 + TextLenPts(O^.Txt, O^.Size, 0, 1) + 12;
   End;
  End;
 End;
 RedrawAll;
End;

Procedure EditSelected;
Var
 S: String;
 K, I: Integer;
Begin
 If (SelObj < 0) Or (SelObj >= ObjCount) Then Exit;
 K := ObjP(SelObj)^.Kind;
 Case K Of
  K_TEXT: StartEdit(SelObj, False);
  K_NOTE, K_HILITE, K_UNDER, K_STRIKE: Begin
   S := ObjP(SelObj)^.Txt;
   If InputBox('Commentaire', 'Texte', S, 118) Then Begin
    PushUndo;
    ObjP(SelObj)^.Txt := U2W(S);
   End;
   RedrawAll;
  End;
  K_STAMP: ObjProperties;
 End;
End;

{ ---------------------------------------------------------------------- }
{ Opérations de pages                                                        }
{ ---------------------------------------------------------------------- }

Procedure InsertObjFirst(Pg: Integer; Var Idx: Integer);
Var
 J: LongInt;
Begin
 Idx := -1;
 If Not ObjEnsure(ObjCount) Then Exit;
 For J := ObjCount DownTo 1 Do ObjP(J)^ := ObjP(J - 1)^;
 Inc(ObjCount);
 InitObj(ObjP(0)^, K_TEXT, Pg);
 If SelObj >= 0 Then Inc(SelObj);
 If FindObj >= 0 Then Inc(FindObj);
 Idx := 0;
End;

Procedure PageNumbering;
Var
 Fmt, T: String;
 Pg, Start, Sz, PosC, I: Integer;
 RgbV: LongInt;
 W, PX, PY: LongInt;
Begin
 FldInit;
 FldText('Format (# = n°, % = total)', 'Page # / %', 40);
 FldChoice('Position', 'Bas centre|Bas droite|Bas gauche|Haut centre|Haut droite|Haut gauche', 0);
 FldNum('Taille (pt)', 10, 5, 40);
 FldNum('Premier numéro', 1, 0, 9999);
 FldColor('Couleur', 0);
 If Not FormDialog('Numérotation des pages') Then Begin RedrawAll; Exit; End;
 Fmt := U2W(Fields[0].Val);
 PosC := Fields[1].Cur; Sz := FInt(2); Start := FInt(3); RgbV := FInt(4);
 PushUndo;
 For Pg := 1 To PageCount Do Begin
  T := '';
  For I := 1 To Length(Fmt) Do
   If Fmt[I] = '#' Then T := T + IStr(Start + Pg - 1)
   Else If Fmt[I] = '%' Then T := T + IStr(PageCount + Start - 1)
   Else T := T + Fmt[I];
  If T = '' Then Continue;
  I := NewObj(K_TEXT, Pg);
  If I < 0 Then Break;
  W := TextLenPts(T, Sz, 0, 0);
  Case PosC Mod 3 Of
   0: PX := (PgP(Pg)^.W - W) Div 2;
   1: PX := PgP(Pg)^.W - W - 36;
  Else PX := 36;
  End;
  If PosC < 3 Then PY := PgP(Pg)^.H - 36 - Sz Else PY := 28;
  ObjP(I)^.X1 := PX;
  ObjP(I)^.Y1 := PY;
  ObjP(I)^.Size := Sz;
  ObjP(I)^.Style := 0;
  ObjP(I)^.Rgb := RgbV;
  ObjP(I)^.Txt := T;
  RecalcBox(I);
 End;
 RedrawAll;
End;

Procedure Watermark;
Var
 T: String;
 Pg, Sz, I, Idx: Integer;
 RgbV, W: LongInt;
Begin
 FldInit;
 FldText('Texte du filigrane', 'CONFIDENTIEL', 40);
 FldNum('Taille (pt)', 60, 10, 200);
 FldColor('Couleur', $B0B0B0);
 FldChoice('Style', 'Normal|Gras', 1);
 If Not FormDialog('Ajouter un filigrane') Then Begin RedrawAll; Exit; End;
 T := U2W(Fields[0].Val);
 If T = '' Then Begin RedrawAll; Exit; End;
 Sz := FInt(1); RgbV := FInt(2);
 PushUndo;
 For Pg := 1 To PageCount Do Begin
  InsertObjFirst(Pg, Idx);
  If Idx < 0 Then Break;
  ObjP(Idx)^.Kind := K_TEXT;
  ObjP(Idx)^.Size := Sz;
  ObjP(Idx)^.Style := Fields[3].Cur;
  ObjP(Idx)^.Rgb := RgbV;
  ObjP(Idx)^.Txt := T;
  W := TextLenPts(T, Sz, 0, Fields[3].Cur);
  ObjP(Idx)^.X1 := (PgP(Pg)^.W - W) Div 2;
  ObjP(Idx)^.Y1 := (PgP(Pg)^.H - Sz) Div 2;
  RecalcBox(Idx);
 End;
 RedrawAll;
End;

Procedure CropPage;
Var
 T, B, L, R, NW, NH: LongInt;
 I: Integer;
Begin
 FldInit;
 FldNum('Marge du haut (pt)', 0, 0, 2000);
 FldNum('Marge du bas (pt)', 0, 0, 2000);
 FldNum('Marge de gauche (pt)', 0, 0, 2000);
 FldNum('Marge de droite (pt)', 0, 0, 2000);
 If Not FormDialog('Recadrer la page') Then Begin RedrawAll; Exit; End;
 T := FInt(0); B := FInt(1); L := FInt(2); R := FInt(3);
 NW := PgP(CurPage)^.W - L - R;
 NH := PgP(CurPage)^.H - T - B;
 If (NW < 36) Or (NH < 36) Then Begin Notice('Les marges sont trop grandes.'); RedrawAll; Exit; End;
 PushUndo;
 For I := 0 To ObjCount - 1 Do
  If ObjP(I)^.Page = CurPage Then MoveObj(I, -L, -T);
 PgP(CurPage)^.W := NW;
 PgP(CurPage)^.H := NH;
 FullRefresh;
End;

Procedure PageSizeDlg;
Const
 SW_: Array[0..4] Of Integer = (612, 595, 612, 842, 420);
 SH_: Array[0..4] Of Integer = (792, 842, 1008, 1191, 595);
Var
 Kd, NW, NH, T, P, Lo, Hi: Integer;
Begin
 FldInit;
 FldChoice('Format', 'Lettre (612 x 792)|A4 (595 x 842)|Légal (612 x 1008)|A3 (842 x 1191)|A5 (420 x 595)|Personnalisé', 0);
 FldNum('Largeur perso (pt)', PgP(CurPage)^.W, 36, 5000);
 FldNum('Hauteur perso (pt)', PgP(CurPage)^.H, 36, 5000);
 FldChoice('Orientation', 'Portrait|Paysage', 0);
 FldChoice('Appliquer à', 'Cette page|Toutes les pages', 0);
 If Not FormDialog('Taille de la page') Then Begin RedrawAll; Exit; End;
 Kd := Fields[0].Cur;
 If Kd < 5 Then Begin NW := SW_[Kd]; NH := SH_[Kd]; End
 Else Begin NW := FInt(1); NH := FInt(2); End;
 If Fields[3].Cur = 1 Then Begin T := NW; NW := NH; NH := T; End;
 PushUndo;
 If Fields[4].Cur = 0 Then Begin Lo := CurPage; Hi := CurPage; End Else Begin Lo := 1; Hi := PageCount; End;
 For P := Lo To Hi Do Begin
  PgP(P)^.W := NW;
  PgP(P)^.H := NH;
 End;
 FullRefresh;
End;

Procedure ExtractPages;
Var
 Lo, Hi, I, P: Integer;
 Name: String;
 Snap: TUndoRec;
 Ok: Boolean;
Begin
 FldInit;
 FldNum('De la page', CurPage, 1, PageCount);
 FldNum('À la page', CurPage, 1, PageCount);
 If Not FormDialog('Extraire des pages') Then Begin RedrawAll; Exit; End;
 Lo := FInt(0); Hi := FInt(1);
 If Lo > Hi Then Begin P := Lo; Lo := Hi; Hi := P; End;
 Name := 'extrait.pdf';
 FileMaskAll := False;
 If Not FileDialog('Enregistrer les pages extraites', Name, True, '.pdf') Then Begin RedrawAll; Exit; End;
 MakeSnap(Snap);
 For P := PageCount DownTo 1 Do
  If (P < Lo) Or (P > Hi) Then DeletePageAt(P);
 Ok := SaveAsPDF(Name);
 ApplySnap(Snap);
 FreeUndoRec(Snap);
 RedrawAll;
 If Ok Then SetStatus('Pages ' + IStr(Lo) + ' à ' + IStr(Hi) + ' extraites vers ' + BaseName(Name))
 Else Notice('Impossible d''enregistrer le fichier.');
End;

Procedure InsertFromFile;
Var
 Name: String;
 Before, Added, Pos_, K, J: Integer;
 Err: String;
 Snap: TUndoRec;
Begin
 Name := '';
 FileMaskAll := False;
 If Not FileDialog('Insérer des pages depuis un fichier PDF', Name, False, '.pdf') Then Begin RedrawAll; Exit; End;
 FldInit;
 FldNum('Insérer après la page', CurPage, 0, PageCount);
 If Not FormDialog('Insérer des pages') Then Begin RedrawAll; Exit; End;
 Pos_ := FInt(0);
 PushUndo;
 Before := PageCount;
 ShowProgress('Importation...');
 If Not ImportPDF(Name, True, Err) Then Begin
  If PageCount <> Before Then ApplySnap(UndoStack[UndoTop - 1]);
  DropUndo;
  RedrawAll;
  Notice(Err);
  Exit;
 End;
 Added := PageCount - Before;
 For K := 1 To Added Do
  For J := Before + K DownTo Pos_ + K + 1 Do SwapPages(J, J - 1);
 CurPage := Pos_ + 1;
 FullRefresh;
 If LoadNotice <> '' Then Notice(LoadNotice);
End;

Procedure ApplyRedactions;
Var
 I, J, N, Cnt: Integer;
 RX1, RY1, RX2, RY2, TX1, TY1, TX2, TY2: LongInt;
 Pg: Integer;
Begin
 Cnt := 0;
 For I := 0 To ObjCount - 1 Do If ObjP(I)^.Kind = K_REDACT Then Inc(Cnt);
 If Cnt = 0 Then Begin Notice('Aucune biffure à appliquer.'); Exit; End;
 If MsgBox('Biffer', 'Appliquer ' + IStr(Cnt) + ' biffure(s) ? Le contenu situé dessous sera supprimé définitivement.', 1) = 0 Then Begin
  RedrawAll; Exit;
 End;
 PushUndo;
 For I := 0 To ObjCount - 1 Do
  If ObjP(I)^.Kind = K_REDACT Then Begin
   Pg := ObjP(I)^.Page;
   NormBox(ObjP(I)^, RX1, RY1, RX2, RY2);
   For J := 0 To ObjCount - 1 Do Begin
    If (J = I) Or (ObjP(J)^.Page <> Pg) Or (ObjP(J)^.Kind = K_REDACT) Then Continue;
    NormBox(ObjP(J)^, TX1, TY1, TX2, TY2);
    If (TX1 < RX2) And (TX2 > RX1) And (TY1 < RY2) And (TY2 > RY1) Then ObjP(J)^.Page := 0;
   End;
  End;
 J := 0;
 For I := 0 To ObjCount - 1 Do
  If ObjP(I)^.Page <> 0 Then Begin
   If I <> J Then ObjP(J)^ := ObjP(I)^;
   Inc(J);
  End;
 ObjCount := J;
 SelObj := -1; FindObj := -1;
 NeedFullRewrite := True;
 For I := 0 To ObjCount - 1 Do
  If ObjP(I)^.Kind = K_REDACT Then Begin
   ObjP(I)^.Kind := K_RECT;
   ObjP(I)^.Fill := 1;
   ObjP(I)^.Rgb := 0;
   ObjP(I)^.Rgb2 := 0;
  End;
 RedrawAll;
 SetStatus(IStr(Cnt) + ' biffure(s) appliquée(s).');
End;

Procedure ClearComments;
Var
 I, J: Integer;
Begin
 If CommentCount = 0 Then Begin Notice('Aucun commentaire à supprimer.'); Exit; End;
 If MsgBox('Supprimer les commentaires', 'Supprimer tous les commentaires (surlignages, notes, tampons) du document ?', 1) = 0 Then Begin
  RedrawAll; Exit;
 End;
 PushUndo;
 J := 0;
 For I := 0 To ObjCount - 1 Do
  If Not IsCommentKind(ObjP(I)^.Kind) Then Begin
   If I <> J Then ObjP(J)^ := ObjP(I)^;
   Inc(J);
  End;
 ObjCount := J;
 SelObj := -1; FindObj := -1;
 RedrawAll;
End;

Procedure ShowHelp;
Begin
 InfoBegin;
 InfoAdd('Fichier   Ctrl+N Nouveau  Ctrl+O Ouvrir  Ctrl+S Enregistrer');
 InfoAdd('          F2 Enregistrer sous  Ctrl+Q Quitter');
 InfoAdd('Édition   Ctrl+Z Annuler  Ctrl+Y Rétablir  Suppr Supprimer');
 InfoAdd('          Ctrl+C / Ctrl+X / Ctrl+V  Copier / Couper / Coller');
 InfoAdd('          Ctrl+J Dupliquer  Entrée Modifier le texte');
 InfoAdd('          Ctrl+P Propriétés  Ctrl+F Rechercher  F3 Suivant');
 InfoAdd('Affichage + / -  Zoom   1 = 100 %   2 Largeur   3 Page entière');
 InfoAdd('          PgPréc / PgSuiv  Page   Début / Fin  Première / dernière');
 InfoAdd('          Flèches  Défilement   Ctrl+G  Aller à la page');
 InfoAdd('          F4 Volet de navigation   F5 Pages / Commentaires');
 InfoAdd('          Ctrl+L Plein écran   Alt+lettre ou F10  Menus');
 InfoAdd('Outils    V Sélection  H Main  Z Loupe  T Texte  N Note');
 InfoAdd('          K Surligner  U Souligner  S Barrer  P Crayon');
 InfoAdd('          L Ligne  A Flèche  R Rectangle  O Ovale');
 InfoAdd('          M Tampon  G Signer  X Biffer');
 InfoAdd('Souris    Glisser pour tracer, surligner, déplacer ou');
 InfoAdd('          redimensionner ; double-clic pour modifier un objet.');
 InfoAdd('          Loupe : clic = zoom avant, clic droit = zoom arrière.');
 InfoDialog('Raccourcis clavier', 620);
End;

Procedure ShowAbout;
Begin
 InfoBegin;
 InfoAdd('Acrodoc - Visionneuse et '+#144+'diteur PDF');
 InfoAdd('Version 1.00 - Free Pascal / Turbo Pascal');
 InfoAdd('');
 InfoAdd('Visionneuse et éditeur de documents PDF en mode graphique :');
 InfoAdd('lecture, annotations, organisation des pages, recherche,');
 InfoAdd('signature visuelle, biffure et exportation.');
 InfoAdd('');
 InfoAdd('Sylvain Maltais (support@gladir.com)');
 InfoAdd('https://www.gladir.com/clonedraw');
 InfoBannerH := 112;
 InfoDialog('À propos d''Acrodoc', 480);
 InfoBannerH := 0;
End;

{ ---------------------------------------------------------------------- }
{ Commandes                                                                  }
{ ---------------------------------------------------------------------- }

Procedure ExecCmd(Cmd: Integer);
Var
 I, R: Integer;
 Name: String;
 Col: LongInt;
Begin
 If (Cmd >= CM_TOOL0) And (Cmd < CM_TOOL0 + TL_COUNT) Then Begin
  If Editing Then EndEdit(True);
  SetTool(Cmd - CM_TOOL0);
  Exit;
 End;
 If Editing Then EndEdit(True);
 Case Cmd Of
  CM_NEW: Begin
   If ConfirmDiscard Then Begin
    NewDocument; Imported := False; FitMode := 1;
    FullRefresh;
   End
   Else RedrawAll;
  End;
  CM_OPEN: Begin
   If ConfirmDiscard Then Begin
    Name := '';
    FileMaskAll := False;
    If FileDialog('Ouvrir', Name, False, '.pdf') Then OpenFileByName(Name) Else RedrawAll;
   End
   Else RedrawAll;
  End;
  CM_SAVE: R := Ord(DoSave);
  CM_SAVEAS: R := Ord(DoSaveAs);
  CM_EXPTXT: Begin
   Name := ChangeExt_(DocName, '.txt');
   FileMaskAll := True;
   If FileDialog('Exporter en texte', Name, True, '.txt') Then Begin ExportText(Name); RedrawAll; SetStatus('Texte exporté : ' + BaseName(Name)); End
   Else RedrawAll;
   FileMaskAll := False;
  End;
  CM_EXPBMP: Begin
   Name := ChangeExt_(DocName, '.bmp');
   FileMaskAll := True;
   If FileDialog('Exporter la page en BMP', Name, True, '.bmp') Then Begin ExportBMP(Name); SetStatus('Image exportée : ' + BaseName(Name)); End
   Else RedrawAll;
   FileMaskAll := False;
  End;
  CM_INSFILE: InsertFromFile;
  CM_EXTRACT: ExtractPages;
  CM_PROPS: DocProperties;
  CM_QUIT: Begin
   If ConfirmDiscard Then Running := False Else RedrawAll;
  End;
  CM_UNDO: Begin DoUndo; FullRefresh; End;
  CM_REDO: Begin DoRedo; FullRefresh; End;
  CM_DELETE: If SelObj >= 0 Then Begin PushUndo; DelObj(SelObj); RedrawAll; End;
  CM_DUP: If SelObj >= 0 Then Begin DoCopy; DoPaste(10, 10); RedrawAll; End;
  CM_COPY: DoCopy;
  CM_CUT: If SelObj >= 0 Then Begin DoCopy; PushUndo; DelObj(SelObj); RedrawAll; End;
  CM_PASTE: Begin DoPaste(12, 12); RedrawAll; End;
  CM_DESEL: Begin SelObj := -1; FindObj := -1; RedrawView; End;
  CM_EDITTXT: EditSelected;
  CM_OBJPROPS: ObjProperties;
  CM_FIND: Begin
   FldInit;
   FldText('Rechercher', FindText, 60);
   FldCheck('Respecter la casse', FindCase);
   If FormDialog('Rechercher') Then Begin
    FindText := Fields[0].Val;
    FindCase := Fields[1].Cur = 1;
    FindObj := -1;
    AcFindNext;
   End
   Else RedrawAll;
  End;
  CM_FINDNEXT: AcFindNext;
  CM_COLOR: Begin
   If SelObj >= 0 Then Col := ObjP(SelObj)^.Rgb Else Col := ToolRgb[CurTool];
   Col := PickColor('Couleur', Col);
   If Col >= 0 Then Begin
    If SelObj >= 0 Then Begin
     PushUndo;
     ObjP(SelObj)^.Rgb := Col;
     If (ObjP(SelObj)^.Kind In [K_RECT, K_OVAL, K_POLY]) And (ObjP(SelObj)^.Fill = 1) Then ObjP(SelObj)^.Rgb2 := Col;
    End
    Else ToolRgb[CurTool] := Col;
   End;
   RedrawAll;
  End;
  CM_WIDTH: Begin
   FldInit;
   FldNum('Épaisseur du trait (pt)', CurWidth, 1, 20);
   FldNum('Taille du texte (pt)', CurSize, 4, 200);
   FldChoice('Police du texte', 'Helvetica|Times|Courier', CurFam);
   FldCheck('Gras', (CurStyle And 1) <> 0);
   FldCheck('Italique', (CurStyle And 2) <> 0);
   FldNum('Angle du texte (degrés)', CurAngle, 0, 359);
   If FormDialog('Attributs des outils') Then Begin
    CurWidth := FInt(0); CurSize := FInt(1); CurFam := FInt(2);
    CurStyle := FInt(3) + FInt(4) * 2;
    CurAngle := FInt(5);
   End;
   RedrawAll;
  End;
  CM_ZOOMIN: StepZoom(1);
  CM_ZOOMOUT: StepZoom(-1);
  CM_Z100: ZoomTo(100, ViewW Div 2, ViewH Div 2);
  CM_FITW: Begin FitMode := 1; ScrollX := 0; GotoPage(CurPage); RedrawAll; End;
  CM_FITP: Begin FitMode := 2; ScrollX := 0; GotoPage(CurPage); RedrawAll; End;
  CM_ZOOMSET: Begin
   FldInit;
   FldNum('Niveau de zoom (%)', Zoom, 10, 1600);
   If FormDialog('Zoom') Then ZoomTo(FInt(0), ViewW Div 2, ViewH Div 2) Else RedrawAll;
  End;
  CM_CONT: Begin Continuous := 1 - Continuous; ScrollX := 0; GotoPage(CurPage); RedrawAll; End;
  CM_NAV: Begin NavVisible := 1 - NavVisible; FullScreen := False; RedrawAll; End;
  CM_NAVMODE: Begin If LayerCount > 0 Then NavTab := (NavTab + 1) Mod 3 Else NavTab := 1 - (NavTab And 1); NavScroll := 0; NavVisible := 1; FullScreen := False; RedrawAll; End;
  CM_FULL: Begin FullScreen := Not FullScreen; RedrawAll; End;
  CM_PREV: Begin GotoPage(CurPage - 1); RedrawAll; End;
  CM_NEXT: Begin GotoPage(CurPage + 1); RedrawAll; End;
  CM_FIRST: Begin GotoPage(1); RedrawAll; End;
  CM_LAST: Begin GotoPage(PageCount); RedrawAll; End;
  CM_GOTO: Begin
   FldInit;
   FldNum('Aller à la page (1-' + IStr(PageCount) + ')', CurPage, 1, PageCount);
   If FormDialog('Aller à la page') Then GotoPage(FInt(0));
   RedrawAll;
  End;
  CM_PGINS: Begin
   PushUndo;
   InsertPageAt(CurPage, PgP(CurPage)^.W, PgP(CurPage)^.H);
   GotoPage(CurPage + 1);
   FullRefresh;
  End;
  CM_PGDUP: Begin
   PushUndo;
   DupPageAt(CurPage);
   GotoPage(CurPage + 1);
   FullRefresh;
  End;
  CM_PGDEL: Begin
   If PageCount > 1 Then
    If MsgBox('Supprimer la page', 'Supprimer la page ' + IStr(CurPage) + ' ?', 1) <> 0 Then Begin
     PushUndo;
     DeletePageAt(CurPage);
     GotoPage(CurPage);
    End;
   FullRefresh;
  End;
  CM_ROTR: Begin PushUndo; PgP(CurPage)^.Rot := (PgP(CurPage)^.Rot + 1) And 3; FullRefresh; End;
  CM_ROTL: Begin PushUndo; PgP(CurPage)^.Rot := (PgP(CurPage)^.Rot + 3) And 3; FullRefresh; End;
  CM_PGUP: If CurPage > 1 Then Begin PushUndo; SwapPages(CurPage, CurPage - 1); GotoPage(CurPage - 1); FullRefresh; End;
  CM_PGDOWN: If CurPage < PageCount Then Begin PushUndo; SwapPages(CurPage, CurPage + 1); GotoPage(CurPage + 1); FullRefresh; End;
  CM_CROP: CropPage;
  CM_PGSIZE: PageSizeDlg;
  CM_NUMBER: PageNumbering;
  CM_WATER: Watermark;
  CM_APPLYRED: ApplyRedactions;
  CM_CLEARALL: ClearComments;
  CM_HELP: Begin ShowHelp; RedrawAll; End;
  CM_ABOUT: Begin ShowAbout; RedrawAll; End;
 End;
End;

{ ---------------------------------------------------------------------- }
{ Aperçus XOR                                                                }
{ ---------------------------------------------------------------------- }

Var
 PrevKind: Integer;

Procedure XorPreview(Kind: Integer; X1, Y1, X2, Y2: LongInt);
Var
 CX, CY, RX, RY: LongInt;
Begin
 SetViewPort(ViewL, ViewT, ViewR, ViewB, True);
 SetWriteMode(XORPut);
 SetColor(White);
 X1 := X1 - ViewL; X2 := X2 - ViewL; Y1 := Y1 - ViewT; Y2 := Y2 - ViewT;
 Case Kind Of
  0: Rectangle(C16(X1), C16(Y1), C16(X2), C16(Y2));
  1: Line(C16(X1), C16(Y1), C16(X2), C16(Y2));
  2: Begin
   CX := (X1 + X2) Div 2; CY := (Y1 + Y2) Div 2;
   RX := IAbs(X2 - X1) Div 2; RY := IAbs(Y2 - Y1) Div 2;
   If (RX > 0) And (RY > 0) Then Ellipse(C16(CX), C16(CY), 0, 360, C16(RX), C16(RY));
  End;
 End;
 SetWriteMode(NormalPut);
 SetFullView;
End;

Procedure ErasePreview;
Begin
 If PreviewOn Then Begin
  HideMouse;
  XorPreview(PrevKind, PrevX1, PrevY1, PrevX2, PrevY2);
  ShowMouse;
  PreviewOn := False;
 End;
End;

Procedure ShowPreview(Kind: Integer; X1, Y1, X2, Y2: LongInt);
Begin
 If PreviewOn And (PrevKind = Kind) And (PrevX1 = X1) And (PrevY1 = Y1) And (PrevX2 = X2) And (PrevY2 = Y2) Then Exit;
 HideMouse;
 If PreviewOn Then XorPreview(PrevKind, PrevX1, PrevY1, PrevX2, PrevY2);
 XorPreview(Kind, X1, Y1, X2, Y2);
 ShowMouse;
 PreviewOn := True;
 PrevKind := Kind; PrevX1 := X1; PrevY1 := Y1; PrevX2 := X2; PrevY2 := Y2;
End;

Procedure RefreshSel;
Begin
 HideMouse;
 DrawView;
 DrawScrollBars;
 DrawNav;
 DrawStatus;
 ShowMouse;
End;

Procedure SyncNav;
Var
 T, H: LongInt;
Begin
 If (NavVisible = 0) Or (NavTab <> 0) Then Exit;
 If LastNavPage = CurPage Then Exit;
 LastNavPage := CurPage;
 H := ViewB - ViewT - 15;
 T := ThumbTop(CurPage);
 If T < NavScroll Then NavScroll := T - 4;
 If T + ThumbCellH(CurPage) > NavScroll + H Then NavScroll := T + ThumbCellH(CurPage) - H;
 If NavScroll < 0 Then NavScroll := 0;
End;

{ ---------------------------------------------------------------------- }
{ Souris                                                                     }
{ ---------------------------------------------------------------------- }

Procedure SetPageCtx(Pg: Integer);
Var
 OX, OY: LongInt;
Begin
 PageOrigin(Pg, OX, OY);
 SetCtx(Pg, OX + ViewL, OY + ViewT, Scale);
End;

Procedure ClampToPage(Pg: Integer; Var X, Y: LongInt);
Begin
 If X < 0 Then X := 0;
 If Y < 0 Then Y := 0;
 If X > PgP(Pg)^.W Then X := PgP(Pg)^.W;
 If Y > PgP(Pg)^.H Then Y := PgP(Pg)^.H;
End;

Procedure HandleViewDown(Dbl: Boolean);
Var
 Pg: Integer;
 PX, PY: LongInt;
 I, H: Integer;
 Tol: Real;
 S: String;
Begin
 Case CurTool Of
  TL_HAND: Begin
   DragMode := 4; DragX0 := MX_; DragY0 := MY_; DragOX := ScrollX; DragOY := ScrollY;
   Exit;
  End;
  TL_ZOOM: Begin
   DragMode := 8; DragX0 := MX_; DragY0 := MY_; PreviewOn := False;
   Exit;
  End;
 End;
 If Not PageAt(MX_, MY_, Pg, PX, PY, True) Then Begin
  If (CurTool = TL_SELECT) And (SelObj >= 0) Then Begin SelObj := -1; RefreshSel; End;
  Exit;
 End;
 Tol := 5 * 1024.0 / Scale;
 Case CurTool Of
  TL_SELECT: Begin
   If (SelObj >= 0) And (SelObj < ObjCount) Then
    If ObjP(SelObj)^.Page = Pg Then Begin
     H := HandleAt(SelObj, MX_, MY_);
     If H <> 0 Then Begin
      DragMode := 3; DragHandle := H; DragObj := SelObj; DragPg := Pg; PreviewOn := False;
      Exit;
     End;
    End;
   I := HitObj(Pg, PX, PY, Tol);
   If I >= 0 Then Begin
    SelObj := I;
    If Continuous <> 0 Then CurPage := Pg;
    If Dbl Then Begin RefreshSel; EditSelected; End
    Else Begin
     DragMode := 2; DragObj := I; DragPg := Pg; DragX0 := PX; DragY0 := PY; PreviewOn := False;
     RefreshSel;
    End;
   End
   Else Begin
    SelObj := -1;
    CurPage := Pg;
    RefreshSel;
   End;
  End;
  TL_TEXT: Begin
   I := HitObj(Pg, PX, PY, Tol);
   If (I >= 0) And (ObjP(I)^.Kind = K_TEXT) Then StartEdit(I, False)
   Else Begin
    I := CreateText(Pg, PX, PY);
    If I >= 0 Then StartEdit(I, True);
   End;
  End;
  TL_NOTE: Begin
   PushUndo;
   I := NewObj(K_NOTE, Pg);
   If I < 0 Then Begin DropUndo; Exit; End;
   ObjP(I)^.X1 := PX; ObjP(I)^.Y1 := PY; ObjP(I)^.Rgb := ToolRgb[TL_NOTE];
   RecalcBox(I);
   S := '';
   If InputBox('Note adhésive', 'Texte de la note', S, 118) And (S <> '') Then Begin
    ObjP(I)^.Txt := U2W(S);
    SelObj := I;
   End
   Else Begin DelObj(I); DropUndo; End;
   RedrawAll;
  End;
  TL_HILITE, TL_UNDER, TL_STRIKE, TL_LINE, TL_ARROW, TL_RECT, TL_OVAL, TL_REDACT: Begin
   DragMode := 1; DragPg := Pg; DragX0 := PX; DragY0 := PY; PreviewOn := False;
  End;
  TL_PENCIL: Begin
   DragMode := 5; DragPg := Pg; InkN := 1; InkX[0] := PX; InkY[0] := PY;
  End;
  TL_STAMP: ChoiceStamp(Pg, PX, PY);
  TL_SIGN: PlaceSignature(Pg, PX, PY);
 End;
End;

Procedure FinishShape(Pg: Integer; PX, PY: LongInt);
Var
 I: Integer;
 DX, DY: LongInt;
Begin
 DX := IAbs(PX - DragX0); DY := IAbs(PY - DragY0);
 Case CurTool Of
  TL_HILITE: MarkText(K_HILITE, Pg, DragX0, DragY0, PX, PY, TL_HILITE);
  TL_UNDER: MarkText(K_UNDER, Pg, DragX0, DragY0, PX, PY, TL_UNDER);
  TL_STRIKE: MarkText(K_STRIKE, Pg, DragX0, DragY0, PX, PY, TL_STRIKE);
  TL_LINE, TL_ARROW: If DX + DY >= 4 Then Begin
   PushUndo;
   If CurTool = TL_LINE Then I := NewShape(K_LINE, Pg, DragX0, DragY0, PX, PY, CurTool)
   Else I := NewShape(K_ARROW, Pg, DragX0, DragY0, PX, PY, CurTool);
   If I < 0 Then DropUndo Else SelObj := I;
  End;
  TL_RECT, TL_OVAL, TL_REDACT: If (DX >= 3) And (DY >= 3) Then Begin
   PushUndo;
   If CurTool = TL_RECT Then I := NewShape(K_RECT, Pg, DragX0, DragY0, PX, PY, CurTool)
   Else If CurTool = TL_OVAL Then I := NewShape(K_OVAL, Pg, DragX0, DragY0, PX, PY, CurTool)
   Else I := NewShape(K_REDACT, Pg, DragX0, DragY0, PX, PY, CurTool);
   If I < 0 Then DropUndo
   Else Begin
    SelObj := I;
    If CurTool = TL_REDACT Then ObjP(I)^.Rgb := $FF4040;
   End;
  End;
 End;
End;

Procedure HandleDrag(Up: Boolean);
Var
 PX, PY, DX, DY, X1, Y1, X2, Y2, CX, CY: LongInt;
 O: TObjRec;
 SX1, SY1, SX2, SY2, NX1, NY1, NX2, NY2: LongInt;
 Kind, I: Integer;
 NZ: Integer;
 RW, RH: Real;
Begin
 Case DragMode Of
  1: Begin
   SetPageCtx(DragPg);
   Unmap(MX_, MY_, PX, PY);
   ClampToPage(DragPg, PX, PY);
   If CurTool In [TL_LINE, TL_ARROW] Then Kind := 1
   Else If CurTool = TL_OVAL Then Kind := 2 Else Kind := 0;
   X1 := MXp(DragX0, DragY0); Y1 := MYp(DragX0, DragY0);
   X2 := MXp(PX, PY); Y2 := MYp(PX, PY);
   If Not Up Then ShowPreview(Kind, X1, Y1, X2, Y2)
   Else Begin
    ErasePreview;
    DragMode := 0;
    FinishShape(DragPg, PX, PY);
    RedrawAll;
   End;
  End;
  2: Begin
   SetPageCtx(DragPg);
   Unmap(MX_, MY_, PX, PY);
   DX := PX - DragX0; DY := PY - DragY0;
   O := ObjP(DragObj)^;
   O.X1 := O.X1 + DX; O.X2 := O.X2 + DX; O.Y1 := O.Y1 + DY; O.Y2 := O.Y2 + DY;
   If Not Up Then Begin
    If (DX <> 0) Or (DY <> 0) Or PreviewOn Then Begin
     If O.Kind In [K_LINE, K_ARROW] Then
      ShowPreview(1, MXp(O.X1, O.Y1), MYp(O.X1, O.Y1), MXp(O.X2, O.Y2), MYp(O.X2, O.Y2))
     Else Begin
      ScrBox(O, SX1, SY1, SX2, SY2);
      ShowPreview(0, SX1 - 2, SY1 - 2, SX2 + 2, SY2 + 2);
     End;
    End;
   End
   Else Begin
    ErasePreview;
    DragMode := 0;
    If (DX <> 0) Or (DY <> 0) Then Begin
     PushUndo;
     MoveObj(DragObj, DX, DY);
    End;
    RedrawAll;
   End;
  End;
  3: Begin
   SetPageCtx(DragPg);
   Unmap(MX_, MY_, PX, PY);
   ClampToPage(DragPg, PX, PY);
   O := ObjP(DragObj)^;
   If DragHandle >= 5 Then Begin
    If DragHandle = 5 Then Begin O.X1 := PX; O.Y1 := PY; End Else Begin O.X2 := PX; O.Y2 := PY; End;
    NX1 := O.X1; NY1 := O.Y1; NX2 := O.X2; NY2 := O.Y2;
    If Not Up Then ShowPreview(1, MXp(O.X1, O.Y1), MYp(O.X1, O.Y1), MXp(O.X2, O.Y2), MYp(O.X2, O.Y2));
   End
   Else Begin
    NormBox(O, NX1, NY1, NX2, NY2);
    Case DragHandle Of
     1: Begin NX1 := PX; NY1 := PY; End;
     2: Begin NX2 := PX; NY1 := PY; End;
     3: Begin NX1 := PX; NY2 := PY; End;
    Else Begin NX2 := PX; NY2 := PY; End;
    End;
    If NX1 > NX2 Then Begin X1 := NX1; NX1 := NX2; NX2 := X1; End;
    If NY1 > NY2 Then Begin Y1 := NY1; NY1 := NY2; NY2 := Y1; End;
    O.X1 := NX1; O.Y1 := NY1; O.X2 := NX2; O.Y2 := NY2;
    If Not Up Then Begin
     ScrBox(O, SX1, SY1, SX2, SY2);
     ShowPreview(0, SX1, SY1, SX2, SY2);
    End;
   End;
   If Up Then Begin
    ErasePreview;
    DragMode := 0;
    PushUndo;
    If DragHandle >= 5 Then Begin
     ObjP(DragObj)^.X1 := O.X1; ObjP(DragObj)^.Y1 := O.Y1; ObjP(DragObj)^.X2 := O.X2; ObjP(DragObj)^.Y2 := O.Y2;
    End
    Else ScaleObjTo(DragObj, NX1, NY1, NX2, NY2);
    RedrawAll;
   End;
  End;
  4: Begin
   ScrollX := DragOX - (MX_ - DragX0);
   ScrollY := DragOY - (MY_ - DragY0);
   ClampScroll;
   If Continuous <> 0 Then UpdateCurPage;
   If Up Then Begin DragMode := 0; RedrawAll; End
   Else If (MX_ <> OMX) Or (MY_ <> OMY) Then Begin
    HideMouse; DrawView; DrawScrollBars; ShowMouse;
   End;
  End;
  5: Begin
   SetPageCtx(DragPg);
   Unmap(MX_, MY_, PX, PY);
   ClampToPage(DragPg, PX, PY);
   If (PX <> InkX[InkN - 1]) Or (PY <> InkY[InkN - 1]) Then Begin
    If InkN < 400 Then Begin
     InkX[InkN] := PX; InkY[InkN] := PY;
     HideMouse;
     SetViewPort(ViewL, ViewT, ViewR, ViewB, True);
     ThickLine(MXp(InkX[InkN - 1], InkY[InkN - 1]) - ViewL, MYp(InkX[InkN - 1], InkY[InkN - 1]) - ViewT,
               MXp(PX, PY) - ViewL, MYp(PX, PY) - ViewT, IMax(1, PU(CurWidth)), ScrCol(ToolRgb[TL_PENCIL]));
     SetFullView;
     ShowMouse;
     Inc(InkN);
    End;
   End;
   If Up Then Begin
    DragMode := 0;
    FinishInk(DragPg);
    RedrawAll;
   End;
  End;
  6: Begin
   ScrollY := SBDragPos(ViewR + 1, ViewT, GetMaxX, ViewB, True, DocH, ViewH, MX_, MY_, SBDragOfs);
   If Continuous <> 0 Then UpdateCurPage;
   If Up Then Begin DragMode := 0; RedrawAll; End
   Else If MY_ <> OMY Then Begin HideMouse; DrawView; DrawScrollBars; ShowMouse; End;
  End;
  7: Begin
   ScrollX := SBDragPos(ViewL, ViewB + 1, ViewR, GetMaxY - STATUS_H, False, DocW, ViewW, MX_, MY_, SBDragOfs);
   If Up Then Begin DragMode := 0; RedrawAll; End
   Else If MX_ <> OMX Then Begin HideMouse; DrawView; DrawScrollBars; ShowMouse; End;
  End;
  8: Begin
   If Not Up Then ShowPreview(0, DragX0, DragY0, MX_, MY_)
   Else Begin
    ErasePreview;
    DragMode := 0;
    DX := IAbs(MX_ - DragX0); DY := IAbs(MY_ - DragY0);
    If (DX < 6) And (DY < 6) Then Begin
     If (MB_ And 2) <> 0 Then StepZoom(-1)
     Else ZoomTo(Zoom * 3 Div 2 + 1, MX_ - ViewL, MY_ - ViewT);
    End
    Else Begin
     RW := ViewW / IMax(1, DX);
     RH := ViewH / IMax(1, DY);
     If RW > RH Then RW := RH;
     NZ := Trunc(Zoom * RW);
     If NZ > 1600 Then NZ := 1600;
     ZoomTo(NZ, (DragX0 + MX_) Div 2 - ViewL, (DragY0 + MY_) Div 2 - ViewT);
    End;
   End;
  End;
  9: Begin
   If NavTab = 0 Then
    NavScroll := SBDragPos(NAV_W - SBAR, ViewT + 16, NAV_W - 1, ViewB, True, NavDocHeight, ViewB - ViewT - 15, MX_, MY_, SBDragOfs)
   Else If NavTab = 2 Then
    NavScroll := SBDragPos(NAV_W - SBAR, ViewT + 16, NAV_W - 1, ViewB, True, IMax(LayerCount, 1), (ViewB - ViewT - 15) Div 14, MX_, MY_, SBDragOfs)
   Else
    NavScroll := SBDragPos(NAV_W - SBAR, ViewT + 16, NAV_W - 1, ViewB, True, IMax(CommentCount, 1), (ViewB - ViewT - 15) Div 24, MX_, MY_, SBDragOfs);
   If Up Then DragMode := 0;
   HideMouse; DrawNav; ShowMouse;
  End;
 Else
  DragMode := 0;
 End;
End;

Procedure NavClick(Dbl: Boolean);
Var
 I, Hit, Rows, Idx: Integer;
 Y: LongInt;
 T: LongInt;
 Y0, Y1: Integer;
 Ofs: LongInt;
 Total, PageSz: LongInt;
Begin
 Ofs := 0;
 Y0 := ViewT + 16; Y1 := ViewB;
 If MY_ < ViewT + 15 Then Begin
  If LayerCount > 0 Then Begin
   If MX_ < 43 Then NavTab := 0 Else If MX_ < 86 Then NavTab := 1 Else NavTab := 2;
  End
  Else If MX_ < 54 Then NavTab := 0 Else NavTab := 1;
  NavScroll := 0;
  LastNavPage := -1;
  SyncNav;
  HideMouse; DrawNav; ShowMouse;
  Exit;
 End;
 If NavTab = 0 Then Begin Total := NavDocHeight; PageSz := Y1 - Y0 + 1; End
 Else If NavTab = 2 Then Begin Total := IMax(LayerCount, 1); PageSz := (Y1 - Y0 + 1) Div 14; End
 Else Begin Total := IMax(CommentCount, 1); PageSz := (Y1 - Y0 + 1) Div 24; End;
 If MX_ >= NAV_W - SBAR Then Begin
  Hit := SBHit(NAV_W - SBAR, Y0, NAV_W - 1, Y1, True, NavScroll, Total, PageSz, MX_, MY_, Ofs);
  Case Hit Of
   1: If NavTab = 0 Then Dec(NavScroll, 30) Else Dec(NavScroll);
   2: If NavTab = 0 Then Inc(NavScroll, 30) Else Inc(NavScroll);
   3: Dec(NavScroll, PageSz);
   4: Inc(NavScroll, PageSz);
   5: Begin DragMode := 9; SBDragOfs := Ofs; End;
  End;
  If NavScroll > Total - PageSz Then NavScroll := Total - PageSz;
  If NavScroll < 0 Then NavScroll := 0;
  HideMouse; DrawNav; ShowMouse;
  Exit;
 End;
 If NavTab = 0 Then Begin
  Y := MY_ - Y0 + NavScroll;
  For I := 1 To PageCount Do Begin
   T := ThumbTop(I);
   If (Y >= T - 4) And (Y < T + ThumbCellH(I) - 4) Then Begin
    GotoPage(I);
    RedrawAll;
    Exit;
   End;
  End;
 End
 Else If NavTab = 2 Then Begin
  Idx := NavScroll + (MY_ - Y0) Div 14;
  If (Idx >= 0) And (Idx < LayerCount) Then Begin
   Layers^[Idx].On := Not Layers^[Idx].On;
   If SelObj >= 0 Then If Not LayerOn(ObjP(SelObj)^.Layer) Then SelObj := -1;
   RedrawAll;
  End;
 End
 Else Begin
  Rows := (MY_ - Y0) Div 24;
  CommentRow(NavScroll + Rows, Idx);
  If Idx >= 0 Then Begin
   SelObj := Idx;
   ScrollToObj(Idx);
   RedrawAll;
   If Dbl Then EditSelected;
  End;
 End;
End;

Procedure MenuRun(M, Item: Integer);
Var
 Cmd: Integer;
Begin
 If (Item < 0) Or (Item >= Menus[M].ItemCount) Then Exit;
 If Menus[M].Items[Item].Separator Then Exit;
 Cmd := Menus[M].Items[Item].Cmd;
 If Not CmdEnabled(Cmd) Then Exit;
 CloseMenu;
 ExecCmd(Cmd);
End;

Procedure HandleMouse;
Var
 Down, Dbl, RDown: Boolean;
 Bar_, Item, TB, Hit: Integer;
 Ofs: LongInt;
 NewHint: String;
Begin
 Ofs := 0;
 PollMouse;
 Down := MouseClicked;
 RDown := ((MB_ And 2) <> 0) And ((OMB And 2) = 0);
 Dbl := False;
 If Down Then Begin
  Dbl := (NowMs - LastClickT < 450) And (IAbs(MX_ - LastClickX) < 5) And (IAbs(MY_ - LastClickY) < 5);
  LastClickT := NowMs; LastClickX := MX_; LastClickY := MY_;
  If Dbl Then LastClickT := 0;
 End;
 If MenuActive Then Begin
  If (MX_ <> OMX) Or (MY_ <> OMY) Then Begin
   Bar_ := MenuBarHit(MX_, MY_);
   If (Bar_ >= 0) And (Bar_ <> ActiveMenu) Then OpenMenu(Bar_)
   Else Begin
    Item := MenuItemHit(MX_, MY_, ActiveMenu);
    If Item <> ActiveItem Then Begin
     ActiveItem := Item;
     HideMouse; DrawDropdown(ActiveMenu); ShowMouse;
    End;
   End;
  End;
  If Down Then Begin
   Bar_ := MenuBarHit(MX_, MY_);
   If Bar_ = ActiveMenu Then CloseMenu
   Else If Bar_ >= 0 Then OpenMenu(Bar_)
   Else Begin
    Item := MenuItemHit(MX_, MY_, ActiveMenu);
    If Item >= 0 Then MenuRun(ActiveMenu, Item) Else CloseMenu;
   End;
  End;
  Exit;
 End;
 If DragMode <> 0 Then Begin
  HandleDrag((MB_ And 1) = 0);
  Exit;
 End;
 If Down Then Begin
  If Editing Then EndEdit(True);
  If MY_ < MENU_H Then Begin
   Bar_ := MenuBarHit(MX_, MY_);
   If Bar_ >= 0 Then OpenMenu(Bar_);
  End
  Else If (ToolbarVisible <> 0) And Not FullScreen And (MY_ < MENU_H + TOOL_H) Then Begin
   TB := ToolbarHit(MX_, MY_);
   If TB >= 0 Then ExecCmd(TBar[TB].Cmd);
  End
  Else If (NavVisible <> 0) And Not FullScreen And (MX_ < NAV_W) And (MY_ >= ViewT) And (MY_ <= ViewB) Then
   NavClick(Dbl)
  Else If (MX_ > ViewR) And (MY_ >= ViewT) And (MY_ <= ViewB) Then Begin
   Hit := SBHit(ViewR + 1, ViewT, GetMaxX, ViewB, True, ScrollY, DocH, ViewH, MX_, MY_, Ofs);
   Case Hit Of
    1: ScrollY := ScrollY - 40;
    2: ScrollY := ScrollY + 40;
    3: ScrollY := ScrollY - ViewH + 20;
    4: ScrollY := ScrollY + ViewH - 20;
    5: Begin DragMode := 6; SBDragOfs := Ofs; End;
   End;
   If Hit <> 0 Then Begin
    ClampScroll;
    If Continuous <> 0 Then UpdateCurPage;
    RedrawAll;
   End;
  End
  Else If (MY_ > ViewB) And (MY_ <= GetMaxY - STATUS_H) And (MX_ >= ViewL) And (MX_ <= ViewR) Then Begin
   Hit := SBHit(ViewL, ViewB + 1, ViewR, GetMaxY - STATUS_H, False, ScrollX, DocW, ViewW, MX_, MY_, Ofs);
   Case Hit Of
    1: ScrollX := ScrollX - 40;
    2: ScrollX := ScrollX + 40;
    3: ScrollX := ScrollX - ViewW + 20;
    4: ScrollX := ScrollX + ViewW - 20;
    5: Begin DragMode := 7; SBDragOfs := Ofs; End;
   End;
   If Hit <> 0 Then Begin ClampScroll; RedrawAll; End;
  End
  Else If (MX_ >= ViewL) And (MX_ <= ViewR) And (MY_ >= ViewT) And (MY_ <= ViewB) Then
   HandleViewDown(Dbl);
 End
 Else If RDown And (CurTool = TL_ZOOM) And (MX_ >= ViewL) And (MX_ <= ViewR) And (MY_ >= ViewT) And (MY_ <= ViewB) Then
  StepZoom(-1);
 If (MX_ <> OMX) Or (MY_ <> OMY) Then Begin
  NewHint := '';
  TB := ToolbarHit(MX_, MY_);
  If TB >= 0 Then NewHint := TBar[TB].Hint;
  If NewHint <> HintText Then Begin
   HintText := NewHint;
   HideMouse; DrawStatus; ShowMouse;
  End;
 End;
End;

{ ---------------------------------------------------------------------- }
{ Clavier                                                                    }
{ ---------------------------------------------------------------------- }

Procedure MenuNextItem(Step: Integer);
Var
 N, I: Integer;
Begin
 N := Menus[ActiveMenu].ItemCount;
 If N <= 0 Then Exit;
 If ActiveItem < 0 Then Begin
  If Step > 0 Then ActiveItem := -1 Else ActiveItem := N;
 End;
 For I := 1 To N Do Begin
  ActiveItem := ActiveItem + Step;
  If ActiveItem < 0 Then ActiveItem := N - 1;
  If ActiveItem >= N Then ActiveItem := 0;
  If Not Menus[ActiveMenu].Items[ActiveItem].Separator Then Break;
 End;
 HideMouse; DrawDropdown(ActiveMenu); ShowMouse;
End;

Procedure ScrollBy(DX, DY: LongInt);
Begin
 ScrollX := ScrollX + DX;
 ScrollY := ScrollY + DY;
 ClampScroll;
 If Continuous <> 0 Then UpdateCurPage;
 RedrawView;
 If Continuous <> 0 Then Begin
  HideMouse;
  SyncNav;
  DrawNav;
  ShowMouse;
 End;
End;

Procedure HandleKeys;
Var
 K: Integer;
 Ext: Boolean;
 C: Char;
Begin
 K := GetKeyEx(Ext);
 If K < 0 Then Exit;
 If Editing Then Begin EditKey(K, Ext); Exit; End;
 If MenuActive Then Begin
  If Ext Then Begin
   Case K Of
    72: MenuNextItem(-1);
    80: MenuNextItem(1);
    75: OpenMenu((ActiveMenu + MN_COUNT - 1) Mod MN_COUNT);
    77: OpenMenu((ActiveMenu + 1) Mod MN_COUNT);
   End;
  End
  Else Begin
   If K = 13 Then MenuRun(ActiveMenu, ActiveItem)
   Else If K = 27 Then CloseMenu;
  End;
  Exit;
 End;
 If Ext Then Begin
  Case K Of
   59: ExecCmd(CM_HELP);
   61: ExecCmd(CM_FINDNEXT);
   62: ExecCmd(CM_NAV);
   63: ExecCmd(CM_NAVMODE);
   60, 134: ExecCmd(CM_SAVEAS);
   107: ExecCmd(CM_QUIT);
   72: ScrollBy(0, -40);
   80: ScrollBy(0, 40);
   75: ScrollBy(-40, 0);
   77: ScrollBy(40, 0);
   73: ExecCmd(CM_PREV);
   81: ExecCmd(CM_NEXT);
   71: ExecCmd(CM_FIRST);
   79: ExecCmd(CM_LAST);
   83: ExecCmd(CM_DELETE);
  End;
  Exit;
 End;
 Case K Of
  14: ExecCmd(CM_NEW);
  15: ExecCmd(CM_OPEN);
  19: ExecCmd(CM_SAVE);
  26: ExecCmd(CM_UNDO);
  25: ExecCmd(CM_REDO);
  6: ExecCmd(CM_FIND);
  7: ExecCmd(CM_GOTO);
  4: ExecCmd(CM_PROPS);
  3: Begin
   { Ctrl+C : copier ; sans sélection, c'est aussi ce que PtcCrt envoie
     quand on ferme la fenêtre : demander la fermeture. }
   If SelObj >= 0 Then ExecCmd(CM_COPY)
   Else If MsgBox('Quitter', 'Voulez-vous quitter Acrodoc ?', 1) <> 0 Then ExecCmd(CM_QUIT)
   Else RedrawAll;
  End;
  22: ExecCmd(CM_PASTE);
  24: ExecCmd(CM_CUT);
  17: ExecCmd(CM_QUIT);
  16: ExecCmd(CM_OBJPROPS);
  12: ExecCmd(CM_FULL);
  10: ExecCmd(CM_DUP);
  27: Begin
   If MenuActive Then CloseMenu
   Else If SelObj >= 0 Then ExecCmd(CM_DESEL)
   Else If FullScreen Then ExecCmd(CM_FULL);
  End;
  13: If SelObj >= 0 Then ExecCmd(CM_EDITTXT);
  43, 61: ExecCmd(CM_ZOOMIN);
  45: ExecCmd(CM_ZOOMOUT);
  49: ExecCmd(CM_Z100);
  50: ExecCmd(CM_FITW);
  51: ExecCmd(CM_FITP);
 Else
  Begin
   C := UpCase(Chr(K));
   Case C Of
    'V': ExecCmd(CM_TOOL0 + TL_SELECT);
    'H': ExecCmd(CM_TOOL0 + TL_HAND);
    'Z': ExecCmd(CM_TOOL0 + TL_ZOOM);
    'T': ExecCmd(CM_TOOL0 + TL_TEXT);
    'N': ExecCmd(CM_TOOL0 + TL_NOTE);
    'K': ExecCmd(CM_TOOL0 + TL_HILITE);
    'U': ExecCmd(CM_TOOL0 + TL_UNDER);
    'S': ExecCmd(CM_TOOL0 + TL_STRIKE);
    'P': ExecCmd(CM_TOOL0 + TL_PENCIL);
    'L': ExecCmd(CM_TOOL0 + TL_LINE);
    'A': ExecCmd(CM_TOOL0 + TL_ARROW);
    'R': ExecCmd(CM_TOOL0 + TL_RECT);
    'O': ExecCmd(CM_TOOL0 + TL_OVAL);
    'M': ExecCmd(CM_TOOL0 + TL_STAMP);
    'G': ExecCmd(CM_TOOL0 + TL_SIGN);
    'X': ExecCmd(CM_TOOL0 + TL_REDACT);
   End;
  End;
 End;
End;

Procedure MainLoop;
Var C, M, I: LongInt;
Begin
 While Running Do Begin
  { barre de menus de PM }
  While PollCmd(C) And Running Do Begin
   If C = CMD_CLOSE Then ExecCmd(CM_QUIT)
   Else If (C >= 100) And (C < 100 + 32 * MN_COUNT) Then Begin
    M := (C - 100) Div 32; I := (C - 100) Mod 32;
    If (I < Menus[M].ItemCount) And Not Menus[M].Items[I].Separator Then
     If CmdEnabled(Menus[M].Items[I].Cmd) Then ExecCmd(Menus[M].Items[I].Cmd);
   End;
  End;
  If Not Running Then Break;
  If Dirty Then Begin Dirty := False; RedrawAll; End;
  HandleMouse;
  HandleKeys;
  Delay(8);
 End;
End;

Procedure InitVars;
Var
 I: Integer;
Begin
 ObjCount := 0; PageCount := 1; CurPage := 1; PoolCount := 0;
 Zoom := 100; FitMode := 1; Continuous := 1; NavVisible := 1; ToolbarVisible := 1; NavTab := 0;
 FullScreen := False;
 NavScroll := 0;
 CurTool := TL_SELECT;
 SelObj := -1; FindObj := -1; FindText := ''; FindCase := False;
 For I := 0 To TL_COUNT - 1 Do ToolRgb[I] := $FF0000;
 ToolRgb[TL_TEXT] := 0;
 ToolRgb[TL_NOTE] := $FFFF00;
 ToolRgb[TL_HILITE] := $FFFF00;
 ToolRgb[TL_REDACT] := 0;
 CurWidth := 2; CurSize := 12; CurFam := 0; CurStyle := 0; CurAngle := 0;
 ClipValid := False;
 Editing := False; EditObj := -1;
 MenuActive := False; ActiveMenu := -1; ActiveItem := -1; UnderValid := False;
 UndoTop := 0; RedoTop := 0;
 DragMode := 0; PreviewOn := False;
 Running := True;
 ImgMaxDim := 640;
 DocName := ''; Modified := False; Imported := False;
 HintText := ''; StatusMsg := '';
 SigName := '';
 LastDir := '';
 FileMaskAll := False;
 FEnts := Nil;
 SortIdx := Nil;
 PdfBuffersReady := False;
 LastClickT := 0; LastClickX := 0; LastClickY := 0;
 MX_ := 0; MY_ := 0; MB_ := 0; OMX := 0; OMY := 0; OMB := 0;
 LastNavPage := -1;
 FillChar(UndoStack, SizeOf(UndoStack), 0);
 FillChar(RedoStack, SizeOf(RedoStack), 0);
End;

Var
 StartFile, Arg, UpArg: String;
 ArgI: Integer;
 WantHelp: Boolean;
 HelpOutput: Text;

BEGIN
 StartFile := '';
 MaxScreen := False;
 MaxColors := False;
 TrueMode := False;
 WantHelp := False;
 For ArgI := 1 To ParamCount Do Begin
  Arg := ParamStr(ArgI);
  UpArg := UpStr(Arg);
  If UpArg = '-MAXSCREEN' Then MaxScreen := True
  Else If UpArg = '-MAXCOLORS' Then MaxColors := True
  Else If (UpArg = '/?') Or (UpArg = '--HELP') Or (UpArg = '-H') Then WantHelp := True
  Else If StartFile = '' Then StartFile := Arg;
 End;
 If WantHelp Then Begin
  { Un flux distinct conserve la sortie console, même avec l'unité Crt. }
  Assign(HelpOutput, '');
  Rewrite(HelpOutput);
  WriteLn(HelpOutput, 'ACROBAT : Cette commande permet de lancer Acrodoc, visionneuse et '+#130+
                      'diteur de documents PDF.');
  WriteLn(HelpOutput);
  WriteLn(HelpOutput, 'Syntaxe : ACROBAT [fichier.pdf] [-maxscreen] [-maxcolors] [/? | -h | --help]');
  WriteLn(HelpOutput);
  WriteLn(HelpOutput, '  Sans option          Lance l''application graphique en 640x480.');
  WriteLn(HelpOutput, '  -h, --help           Affichent '+#130+'galement cette aide.');
  WriteLn(HelpOutput, '  -maxscreen           Utilise la resolution maximale disponible.');
  WriteLn(HelpOutput, '  -maxcolors           Utilise le nombre maximal de couleurs (couleurs vraies).');
  WriteLn(HelpOutput, '  /?                   Affiche cette aide et quitte.');
  WriteLn(HelpOutput);
  WriteLn(HelpOutput, 'Avec -maxcolors (Free Pascal seulement), l''affichage utilise les couleurs vraies :');
  WriteLn(HelpOutput, 'degrades, transparence et images sans tramage. Sous Turbo Pascal, les options sont ignorees.');
  WriteLn(HelpOutput);
  WriteLn(HelpOutput, 'Raccourcis : Ctrl+O Ouvrir, Ctrl+S Enregistrer, Ctrl+Z Annuler, F1 Aide, Ctrl+Q Quitter');
  Close(HelpOutput);
  Halt;
 End;
 {$IFDEF FPC}
 ReturnNilIfGrowHeapFails := True;
 {$ENDIF}
 InitVars;
 Dirty := False; CatCl := 0; CatFr := 0; MxCatWant := False; MxCatOwn := False; MxLastTitle := '';
 InitMenus;
 InitializeGraphics;
 If Pal256 Then ImgMaxDim := 1024;

 SetTextStyle(DefaultFont, HorizDir, 1);
 AllocDoc;
 BuildVFont;
 InitToolbar;
 NewDocument;
 CalcLayout;
 If StartFile <> '' Then Begin
  RedrawAll;
  OpenFileByName(StartFile);
 End
 Else RedrawAll;
 MainLoop;
 Dummy := WinDestroyWindow(OsFrame);
END.
