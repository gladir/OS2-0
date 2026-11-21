{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Clone de l'application Sample Accounting, pour le
                Presentation Manager d'OS/2-0 (dossier Productivite)

  Portage vers OS/2-0 (OS2PC -COS2) de SIMPLY.PAS du depot OFFICE-0 :
  toute la comptabilite est conservee. Pour OS/2 : fenetre de
  Presentation Manager (la barre de titre et la barre des taches
  dessinees par la version DOS sont celles d'OS/2), barre de menus d'OS/2
  construite a partir des neuf menus d'origine, dessin dans une image
  en memoire montree par GpiDrawBits, boites de dialogue de PM.
}

{$IFDEF FPC}
 {$MODE TP}
{$ENDIF}

Program SIMPLY;

{$IFNDEF FPC}
 {$M 16384,0,655360}
{$ENDIF}


{ ====================================================================== }
{                              CONSTANTES                                }
{ ====================================================================== }

Const
 VERSION_TEXT = '1.00';
 SCR_W        = 640;
 SCR_H        = 480;
 MENU_H       = 18;
 NMENU        = 9;

 { Couleurs VGA }
 cBlk=0; cNavy=1; cGrn=2; cCyn=3; cRed=4; cMag=5; cBrn=6; cLGr=7;
 cDGr=8; cLBl=9; cLGn=10; cLCy=11; cLRd=12; cLMg=13; cYel=14; cWht=15;

 { Codes de touches : caractere = ord ; etendue = 256 + code }
 K_ESC    = 27;
 K_ENTER  = 13;
 K_BKSP   = 8;
 K_TAB    = 9;
 K_UP     = 328;
 K_DOWN   = 336;
 K_LEFT   = 331;
 K_RIGHT  = 333;
 K_HOME   = 327;
 K_END    = 335;
 K_PGUP   = 329;
 K_PGDN   = 337;
 K_INS    = 338;
 K_DEL    = 339;
 K_F1     = 315;
 K_F2     = 316;
 K_F4     = 318;
 K_F10    = 324;
 K_STAB   = 271;

 { Limites des donnees }
 MAXACC = 150;
 MAXVEN = 60;
 MAXCUS = 60;
 MAXEMP = 30;
 MAXITM = 80;
 MAXPRJ = 20;
 MAXINV = 400;
 MAXJL  = 1200;
 MAXPL  = 200;
 RMAX   = 500;
 MAXL   = 21000000;       { montant maximal en cents }

 { Genres de comptes }
 K_ASSET = 1; K_LIAB = 2; K_EQUITY = 3; K_REV = 4; K_COGS = 5; K_EXP = 6;

 { Comptes d'integration }
 LK_AP=1; LK_AR=2; LK_GSTPD=3; LK_GSTCL=4; LK_WAGE=5; LK_TAXPAY=6;
 LK_PENPAY=7; LK_UIPAY=8; LK_FRTEXP=9; LK_FRTREV=10; LK_PDISC=11;
 LK_SDISC=12; LK_ADJ=13; LK_RET=14; LK_BANK=15;
 NLINK = 15;

 { Controles }
 ckLabel=1; ckEdit=2; ckCheck=3; ckButton=4; ckCombo=5; ckGrid=6;
 ckBox=7; ckText=8; ckGraph=9; ckRadio=10; ckRule=11;

 { Evenements des fenetres }
 evInit=1; evButton=2; evChange=3; evCell=4; evClose=5; evLookup=6;
 evDbl=7; evTab=8;

 { Sources de listes }
 srcVend=1; srcCust=2; srcAcct=3; srcBank=4; srcEmp=5; srcItem=6;
 srcType=7; srcPayBy=8; srcPrj=9; srcKind=10; srcRKind=11;

 { Genres de fenetres }
 wkMsg=1; wkInput=2; wkSelect=3; wkList=4; wkAcct=5; wkParty=6; wkEmp=7;
 wkItem=8; wkPrj=9; wkJournal=10; wkInvoice=11; wkPay=12; wkPaych=13;
 wkRun=14; wkRecon=15; wkAdjust=16; wkAssem=17; wkSetup=18; wkRep=19;
 wkGraph=20; wkCalc=21;

 MAXCTL = 80;
 MAXROW = 160;
 MAXCOL = 8;
 RH     = 14;

{ ====================================================================== }
{                                TYPES                                   }
{ ====================================================================== }

Type
 TAcc = Packed Record
  Num: Integer;
  Name: String[30];
  Kind: Byte;
  Bank: Boolean;
  Bal: LongInt;
 End;
 TAccArr = Array[1..MAXACC] Of TAcc;
 PAccArr = ^TAccArr;

 TParty = Packed Record
  Name: String[30];
  Ad1,Ad2: String[30];
  Phone: String[16];
  Contact: String[24];
  Acc: Integer;
  Tax: Boolean;
  DPct,DDays,NDays: Integer;
  Limit: LongInt;
 End;
 TPartyArr = Array[1..MAXVEN] Of TParty;
 PPartyArr = ^TPartyArr;

 TEmp = Packed Record
  Name: String[30];
  Ad1,Ad2: String[30];
  SIN: String[11];
  Rate: LongInt;
  Hrs: LongInt;
  Ytd: LongInt;
 End;
 TEmpArr = Array[1..MAXEMP] Of TEmp;
 PEmpArr = ^TEmpArr;

 TItem = Packed Record
  Code: String[10];
  Desc: String[30];
  Unit_: String[6];
  Price,Cost,Qty: LongInt;     { Qty en centiemes }
  Svc: Boolean;
  AAcc,RAcc,CAcc: Integer;
 End;
 TItemArr = Array[1..MAXITM] Of TItem;
 PItemArr = ^TItemArr;

 TPrj = Packed Record
  Name: String[30];
  Budget: LongInt;
 End;
 TPrjArr = Array[1..MAXPRJ] Of TPrj;
 PPrjArr = ^TPrjArr;

 TInv = Packed Record
  Typ: Byte;
  Party: Integer;
  No: String[12];
  Date: LongInt;
  Amt,Paid: LongInt;
 End;
 TInvArr = Array[1..MAXINV] Of TInv;
 PInvArr = ^TInvArr;

 TJL = Packed Record
  Id: LongInt;
  Dt: LongInt;
  Acc: Integer;
  Dr,Cr: LongInt;
  Src: String[12];
  Cm: String[20];
  Rec: Boolean;
 End;
 TJArr = Array[1..MAXJL] Of TJL;
 PJArr = ^TJArr;

 TRange = Record Lo,Hi: Integer; End;

 TSetup = Record
  Co: String[34];
  Ad1,Ad2: String[34];
  Rng: Array[1..6] Of TRange;
  Msg: Array[1..3] Of String[100];
  Link: Array[1..NLINK] Of Integer;
  Gst,IncT,Pen,UI: Integer;      { pourcentages x100 }
  NextChq,NextRcpt,NextInv: LongInt;
  NextJ: LongInt;
 End;

 TPost = Record
  Acc: Integer;
  Dr,Cr: LongInt;
 End;

 TRepArr = Array[1..RMAX] Of String[78];
 PRepArr = ^TRepArr;

 TEvent = Record
  { 0 rien, 1 touche, 2 bouton bas, 3 bouton haut, 4 mouvement }
  Kind : Byte;
  Key  : Word;
  X,Y,B: LongInt;
 End;

 TCtl = Record
  Kind,Id,Tab: Byte;
  X,Y,W,H: Integer;
  Txt: String[60];
  Max,Num,Src: Byte;
  On,Ena,Bold,Rt,Def: Boolean;
  Sel,Cur: Integer;
 End;

 PWin = ^TWin;
 TWin = Record
  Kind,Res,Aux: Integer;
  Title: String[60];
  X,Y,W,H: Integer;
  NC,Foc,Press,BTab: Integer;
  Done,EnterOK: Boolean;
  NTab,CurTab: Integer;
  TabT: Array[1..5] Of String[24];
  Ctl: Array[1..MAXCTL] Of TCtl;
  GId,GMode,GN,GTop,GVis,GRow,GCol,GNC: Integer;
  GEdit: Boolean;
  GBuf: String[30];
  GColW: Array[1..MAXCOL] Of Integer;
  GKind: Array[1..MAXCOL] Of Byte;
  GHead: Array[1..MAXCOL] Of String[16];
  GLook: Array[1..MAXCOL] Of Boolean;
  GCell: Array[1..MAXROW,1..MAXCOL] Of String[30];
 End;

{ ====================================================================== }
{                              VARIABLES                                 }
{ ====================================================================== }

Var
 Lang      : Integer;                    { 1 francais, 2 anglais, 3 allemand }
 SU        : TSetup;
 Ac        : PAccArr;
 Vn,Cu     : PPartyArr;
 Em        : PEmpArr;
 It        : PItemArr;
 Pj        : PPrjArr;
 Iv        : PInvArr;
 Jl        : PJArr;
 NA,NV,NC_,NE,NI,NP,NIv,NJ : Integer;
 FileN     : String[79];
 Named,Modified : Boolean;
 SessDate  : LongInt;
 PL        : Array[1..MAXPL] Of TPost;
 PN        : Integer;
 ErrMsg    : String[80];

 RL        : PRepArr;
 RN        : Integer;
 RTitle    : String[60];
 GBN       : Integer;
 GBLbl     : Array[1..12] Of String[10];
 GBVal     : Array[1..12] Of LongInt;
 GBTitle   : String[50];

 WS        : Array[1..8] Of PWin;
 WSN       : Integer;
 Dirty,DirtyTop : Boolean;
 Quit      : Boolean;
 ToolBarOn,StatusOn : Boolean;
 MainSel   : Integer;

 MX,MY,MB,LastB : LongInt;
 PrevMX,PrevMY  : LongInt;
 LastClickT,LastClickX,LastClickY : LongInt;
 MenuOpen,MenuHi : Integer;
 Dragging  : Boolean;
 DragOX,DragOY : Integer;
 LastFill  : Integer;
 RcMap     : Array[1..MAXROW] Of Integer;
 RcOn      : Array[1..MAXROW] Of Boolean;

{ ====================================================================== }
{                  GRAPHIQUE / SOURIS (squelette)                        }
{ ====================================================================== }

Const
 CanvasTop = 2 * MENU_H;
 CanvasBot = TASK_Y - 1;

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
 OpenWindow('SIMPLY', 'Sample Accounting');
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

{ ====================================================================== }
{                  LANGUE (FR par defaut, EN, GR)                        }
{ ====================================================================== }

{ Codes d'accents dans les chaines sources : @e=e aigu @g=e grave @c=e circ.
  @a=a grave @q=a circ. @i=i circ. @y=i trema @o=o circ. @u=u grave
  @w=u circ. @k=c cedille @t=e trema @E=E aigu @1=ae @2=oe @3=ue @4=Ae
  @5=Oe @6=Ue @7=sz @@=arobase }
Function Dc(Const S: String): String;
Var I: Integer; R: String; C: Char;
Begin
 R:='';I:=1;
 While I<=Length(S) Do Begin
  If (S[I]='@') And (I<Length(S)) Then Begin
   C:=S[I+1];
   Case C Of
    'e': R:=R+#130;
    'E': R:=R+#144;
    'g': R:=R+#138;
    'c': R:=R+#136;
    'a': R:=R+#133;
    'q': R:=R+#131;
    'i': R:=R+#140;
    'y': R:=R+#139;
    'o': R:=R+#147;
    'u': R:=R+#151;
    'w': R:=R+#150;
    'k': R:=R+#135;
    't': R:=R+#137;
    '1': R:=R+#132;
    '2': R:=R+#148;
    '3': R:=R+#129;
    '4': R:=R+#142;
    '5': R:=R+#153;
    '6': R:=R+#154;
    '7': R:=R+#225;
    '@': R:=R+'@';
    Else R:=R+'@'+C;
   End;
   Inc(I,2);
  End Else Begin
   R:=R+S[I];Inc(I);
  End;
 End;
 Dc:=R;
End;

Function T3(Const F,E,G: String): String;
Begin
 Case Lang Of
  2: T3:=Dc(E);
  3: T3:=Dc(G);
  Else T3:=Dc(F);
 End;
End;

Function Upper(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do S[I]:=UpCase(S[I]);
 Upper:=S;
End;

Procedure DetectLanguage;
Var S: String;
Begin
 S:=Upper(GetEnv('LANGUAGE'));
 Lang:=1;
 If Copy(S,1,2)='EN' Then Lang:=2;
 If (Copy(S,1,2)='GR') Or (Copy(S,1,2)='DE') Then Lang:=3;
End;

{ ====================================================================== }
{                       UTILITAIRES GENERAUX                             }
{ ====================================================================== }

Function IntStr(N: LongInt): String;
Var S: String;
Begin
 Str(N,S);
 IntStr:=S;
End;

Function TrimStr(S: String): String;
Begin
 While (Length(S)>0) And (S[1]=' ') Do Delete(S,1,1);
 While (Length(S)>0) And (S[Length(S)]=' ') Do Delete(S,Length(S),1);
 TrimStr:=S;
End;



Function ValInt(Const S: String; Def: LongInt): LongInt;
Var V: LongInt; Code: Integer; T: String;
Begin
 T:=TrimStr(S);
 Val(T,V,Code);
 If (Code<>0) Or (T='') Then ValInt:=Def Else ValInt:=V;
End;

Function Tick: LongInt;
Var H,M,S,S100: Word;
Begin
 GetTime(H,M,S,S100);
 Tick:=((LongInt(H)*60+M)*60+S)*100+S100;
End;

Function FileExists(Const N: String): Boolean;
Var F: File;
Begin
 {$I-}
 Assign(F,N);
 Reset(F,1);
 {$I+}
 If IOResult=0 Then Begin
  Close(F);
  FileExists:=True;
 End Else FileExists:=False;
End;

Function ShortName(Const N: String): String;
Var I: Integer; S: String;
Begin
 S:=N;
 I:=Length(S);
 While (I>0) And (S[I]<>'\') And (S[I]<>'/') And (S[I]<>':') Do Dec(I);
 ShortName:=Copy(S,I+1,255);
End;

Function AddExt(Const N,Ext: String): String;
Var I: Integer; Dot: Boolean;
Begin
 Dot:=False;
 For I:=1 To Length(N) Do If N[I]='.' Then Dot:=True;
 If Dot Or (N='') Then AddExt:=N Else AddExt:=N+'.'+Ext;
End;

Function ChangeExt(Const N,Ext: String): String;
Var I: Integer;
Begin
 I:=Length(N);
 While (I>0) And (N[I]<>'.') And (N[I]<>'\') And (N[I]<>'/') Do Dec(I);
 If (I>0) And (N[I]='.') Then ChangeExt:=Copy(N,1,I)+Ext
 Else ChangeExt:=N+'.'+Ext;
End;

Function Pad(Const S: String; N: Integer): String;
Var R: String;
Begin
 R:=S;
 If Length(R)>N Then R:=Copy(R,1,N);
 While Length(R)<N Do R:=R+' ';
 Pad:=R;
End;

Function PadL(Const S: String; N: Integer): String;
Var R: String;
Begin
 R:=S;
 If Length(R)>N Then R:=Copy(R,Length(R)-N+1,N);
 While Length(R)<N Do R:=' '+R;
 PadL:=R;
End;

{ ---- argent (cents) ---- }

Function FmtMoney(C: LongInt): String;
Var S,R: String; Neg: Boolean; I,N: Integer; Gs,Dp: Char;
Begin
 Case Lang Of
  2: Begin Gs:=',';Dp:='.';End;
  3: Begin Gs:='.';Dp:=',';End;
  Else Begin Gs:=' ';Dp:=',';End;
 End;
 Neg:=C<0;
 If Neg Then C:=-C;
 Str(C Div 100,S);
 R:='';N:=0;
 For I:=Length(S) DownTo 1 Do Begin
  If (N>0) And (N Mod 3=0) Then R:=Gs+R;
  R:=S[I]+R;
  Inc(N);
 End;
 Str(C Mod 100,S);
 If Length(S)<2 Then S:='0'+S;
 R:=R+Dp+S;
 If Neg Then R:='-'+R;
 FmtMoney:=R;
End;

Function ParseMoney(Const S: String): LongInt;
Var I,J,P,Dg,FracN,Fr: Integer; Neg: Boolean; V: LongInt; C: Char;
Begin
 P:=0;
 For I:=1 To Length(S) Do If (S[I]='.') Or (S[I]=',') Then P:=I;
 If P>0 Then Begin
  Dg:=0;
  For J:=P+1 To Length(S) Do If (S[J]>='0') And (S[J]<='9') Then Inc(Dg);
  If Dg>2 Then P:=0;
 End;
 V:=0;Fr:=0;FracN:=0;Neg:=False;
 For I:=1 To Length(S) Do Begin
  C:=S[I];
  If (C='-') Or (C='(') Then Neg:=True
  Else If (C>='0') And (C<='9') Then Begin
   If (P>0) And (I>P) Then Begin
    If FracN<2 Then Begin Fr:=Fr*10+Ord(C)-48;Inc(FracN);End;
   End Else Begin
    If V<MAXL Div 10 Then V:=V*10+Ord(C)-48 Else V:=MAXL Div 100;
   End;
  End;
 End;
 If FracN=1 Then Fr:=Fr*10;
 V:=V*100+Fr;
 If V>MAXL Then V:=MAXL;
 If Neg Then V:=-V;
 ParseMoney:=V;
End;

{ quantites en centiemes }
Function FmtQty(Q: LongInt): String;
Var S: String; Neg: Boolean;
Begin
 Neg:=Q<0;
 If Neg Then Q:=-Q;
 S:=IntStr(Q Div 100);
 If Q Mod 100<>0 Then Begin
  If Q Mod 10=0 Then S:=S+'.'+IntStr((Q Mod 100) Div 10)
  Else Begin
   S:=S+'.';
   If Q Mod 100<10 Then S:=S+'0';
   S:=S+IntStr(Q Mod 100);
  End;
 End;
 If Neg Then S:='-'+S;
 FmtQty:=S;
End;

Function FmtPct(P: LongInt): String;
Var S: String;
Begin
 S:=IntStr(P Div 100);
 If P Mod 100<>0 Then Begin
  S:=S+'.';
  If P Mod 100<10 Then S:=S+'0';
  S:=S+IntStr(P Mod 100);
  If S[Length(S)]='0' Then Delete(S,Length(S),1);
 End;
 FmtPct:=S;
End;

Function ParsePct(Const S: String): Integer;
Begin
 ParsePct:=Integer(ParseMoney(S));
End;

Function MulQ(Q,P: LongInt): LongInt;       { qte centiemes x prix cents }
Var R: Real;
Begin
 R:=Q;
 R:=R*P/100.0;
 If R>MAXL Then R:=MAXL;
 If R<-MAXL Then R:=-MAXL;
 MulQ:=Round(R);
End;

Function PctOf(A: LongInt; P: Integer): LongInt;  { P en centiemes de %  }
Var R: Real;
Begin
 R:=A;
 R:=R*P/10000.0;
 PctOf:=Round(R);
End;

{ ---- dates (AAAAMMJJ) ---- }

Function DayNum(D: LongInt): LongInt;
Var Y,M,Dd: LongInt;
Begin
 Y:=D Div 10000;M:=(D Div 100) Mod 100;Dd:=D Mod 100;
 If M<=2 Then Begin Dec(Y);M:=M+12;End;
 DayNum:=365*Y+Y Div 4-Y Div 100+Y Div 400+(153*(M-3)+2) Div 5+Dd;
End;

Function DayToDate(N: LongInt): LongInt;
Var Y,M,D: LongInt;
Begin
 Y:=(N-1) Div 365;
 While DayNum(Y*10000+101)>N Do Dec(Y);
 While DayNum((Y+1)*10000+101)<=N Do Inc(Y);
 M:=1;
 While (M<12) And (DayNum(Y*10000+(M+1)*100+1)<=N) Do Inc(M);
 D:=N-DayNum(Y*10000+M*100+1)+1;
 DayToDate:=Y*10000+M*100+D;
End;

Function ValidDate(D: LongInt): Boolean;
Var Y,M,Dd: LongInt;
Begin
 Y:=D Div 10000;M:=(D Div 100) Mod 100;Dd:=D Mod 100;
 ValidDate:=False;
 If (Y<1900) Or (Y>2999) Or (M<1) Or (M>12) Or (Dd<1) Then Exit;
 If DayToDate(DayNum(D))<>D Then Exit;
 ValidDate:=True;
End;

Function Two(N: LongInt): String;
Begin
 If N<10 Then Two:='0'+IntStr(N) Else Two:=IntStr(N);
End;

Function FmtDate(D: LongInt): String;
Var Y,M,Dd: LongInt;
Begin
 Y:=D Div 10000;M:=(D Div 100) Mod 100;Dd:=D Mod 100;
 Case Lang Of
  2: FmtDate:=IntStr(M)+'/'+IntStr(Dd)+'/'+IntStr(Y);
  3: FmtDate:=Two(Dd)+'.'+Two(M)+'.'+IntStr(Y);
  Else FmtDate:=Two(Dd)+'/'+Two(M)+'/'+IntStr(Y);
 End;
End;

Function ParseDate(Const S: String; Var D: LongInt): Boolean;
Var N: Array[1..3] Of LongInt; L: Array[1..3] Of Integer; Cnt,I: Integer;
    InNum: Boolean; Y,M,Dd: LongInt; T: LongInt;
Begin
 ParseDate:=False;
 Cnt:=0;InNum:=False;
 For I:=1 To 3 Do Begin N[I]:=0;L[I]:=0;End;
 For I:=1 To Length(S) Do Begin
  If (S[I]>='0') And (S[I]<='9') Then Begin
   If Not InNum Then Begin
    Inc(Cnt);InNum:=True;
    If Cnt>3 Then Exit;
   End;
   N[Cnt]:=N[Cnt]*10+Ord(S[I])-48;
   Inc(L[Cnt]);
   If L[Cnt]>8 Then Exit;
  End Else InNum:=False;
 End;
 If Cnt=0 Then Exit;
 If (Cnt=1) And (L[1]=8) Then Begin
  T:=N[1];
  If Lang=2 Then Begin
    M:=T Div 1000000;Dd:=(T Div 10000) Mod 100;Y:=T Mod 10000;End
  Else Begin Dd:=T Div 1000000;M:=(T Div 10000) Mod 100;Y:=T Mod 10000;End;
  If (Y<1900) Then Begin
    Y:=T Div 10000;M:=(T Div 100) Mod 100;Dd:=T Mod 100;End;
 End Else If Cnt=3 Then Begin
  If L[1]>=3 Then Begin Y:=N[1];M:=N[2];Dd:=N[3];End
  Else If Lang=2 Then Begin M:=N[1];Dd:=N[2];Y:=N[3];End
  Else Begin Dd:=N[1];M:=N[2];Y:=N[3];End;
 End Else Exit;
 If Y<100 Then Begin If Y<50 Then Y:=Y+2000 Else Y:=Y+1900;End;
 D:=Y*10000+M*100+Dd;
 ParseDate:=ValidDate(D);
End;

Function TodayDate: LongInt;
Var Y,M,D,W: Word;
Begin
 GetDate(Y,M,D,W);
 TodayDate:=LongInt(Y)*10000+M*100+D;
End;

Function DateOrToday(Const S: String): LongInt;
Var D: LongInt;
Begin
 If ParseDate(S,D) Then DateOrToday:=D Else DateOrToday:=SessDate;
End;

{ ====================================================================== }
{                        DONNEES DE LA SOCIETE                           }
{ ====================================================================== }

Function FindAcc(Num: Integer): Integer;
Var I: Integer;
Begin
 FindAcc:=0;
 For I:=1 To NA Do If Ac^[I].Num=Num Then Begin FindAcc:=I;Exit;End;
End;

Function AccName(Num: Integer): String;
Var I: Integer;
Begin
 I:=FindAcc(Num);
 If I=0 Then AccName:='' Else AccName:=Ac^[I].Name;
End;

Function LinkAcc(L: Integer): Integer;
Begin
 LinkAcc:=SU.Link[L];
End;

Function KindName(K: Integer): String;
Begin
 Case K Of
  1: KindName:=T3('Actif','Asset','Aktiva');
  2: KindName:=T3('Passif','Liability','Passiva');
  3: KindName:=T3('Capital','Equity','Eigenkapital');
  4: KindName:=T3('Revenus','Revenue','Ertr@1ge');
  5: KindName:=T3('Co@uts directs','Direct costs','Warenkosten');
  6: KindName:=T3('D@epenses','Expenses','Aufwand');
  Else KindName:='?';
 End;
End;

{ genre selon la numerotation }
Function KindOfNum(N: Integer): Integer;
Var K: Integer;
Begin
 KindOfNum:=0;
 For K:=1 To 6 Do If (N>=SU.Rng[K].Lo) And (N<=SU.Rng[K].Hi) Then KindOfNum:=K;
End;

Function DispBal(I: Integer): LongInt;     { solde affiche (sens naturel) }
Begin
 If Ac^[I].Kind In [K_ASSET,K_COGS,K_EXP] Then DispBal:=Ac^[I].Bal
 Else DispBal:=-Ac^[I].Bal;
End;

Procedure Recalc;
Var I,J: Integer;
Begin
 For I:=1 To NA Do Ac^[I].Bal:=0;
 For J:=1 To NJ Do Begin
  I:=FindAcc(Jl^[J].Acc);
  If I>0 Then Ac^[I].Bal:=Ac^[I].Bal+Jl^[J].Dr-Jl^[J].Cr;
 End;
End;

Function InsertAcc(Num: Integer; Const Nm: String; K: Integer; Bk: Boolean):
    Integer;
Var I,P: Integer;
Begin
 InsertAcc:=0;
 If NA>=MAXACC Then Exit;
 P:=1;
 While (P<=NA) And (Ac^[P].Num<Num) Do Inc(P);
 For I:=NA DownTo P Do Ac^[I+1]:=Ac^[I];
 Inc(NA);
 Ac^[P].Num:=Num;Ac^[P].Name:=Nm;Ac^[P].Kind:=K;Ac^[P].Bank:=Bk;Ac^[P].Bal:=0;
 InsertAcc:=P;
End;

Procedure AddA(Num: Integer; Const Nm: String; Bk: Boolean);
Var P: Integer;
Begin
 P:=InsertAcc(Num,Nm,KindOfNum(Num),Bk);
 If P=0 Then Exit;
End;

{ ---- ecriture comptable ---- }

Procedure PClear;
Begin
 PN:=0;
End;

Procedure PAdd(Acc: Integer; Dr,Cr: LongInt);
Var I: Integer;
Begin
 If (Dr=0) And (Cr=0) Then Exit;
 If Dr<0 Then Begin Cr:=Cr-Dr;Dr:=0;End;
 If Cr<0 Then Begin Dr:=Dr-Cr;Cr:=0;End;
 For I:=1 To PN Do
  If (PL[I].Acc=Acc) And (((PL[I].Dr<>0) And (Dr<>0)) Or ((PL[I].Cr<>0)
      And (Cr<>0))) Then Begin
   PL[I].Dr:=PL[I].Dr+Dr;PL[I].Cr:=PL[I].Cr+Cr;Exit;
  End;
 If PN>=MAXPL Then Exit;
 Inc(PN);
 PL[PN].Acc:=Acc;PL[PN].Dr:=Dr;PL[PN].Cr:=Cr;
End;

Procedure PDr(Acc: Integer; A: LongInt);
Begin
 PAdd(Acc,A,0);
End;

Procedure PCr(Acc: Integer; A: LongInt);
Begin
 PAdd(Acc,0,A);
End;

Function PSumDr: LongInt;
Var I: Integer; S: LongInt;
Begin
 S:=0;
 For I:=1 To PN Do S:=S+PL[I].Dr;
 PSumDr:=S;
End;

Function PSumCr: LongInt;
Var I: Integer; S: LongInt;
Begin
 S:=0;
 For I:=1 To PN Do S:=S+PL[I].Cr;
 PSumCr:=S;
End;

Function Commit(D: LongInt; Const Src,Cmt: String): Boolean;
Var I: Integer;
Begin
 Commit:=False;
 ErrMsg:='';
 If PN=0 Then Exit;
 For I:=1 To PN Do
  If FindAcc(PL[I].Acc)=0 Then Begin
   ErrMsg:=T3('Compte inexistant : ','Account does not exist: ',
       'Konto existiert nicht: ')+IntStr(PL[I].Acc);
   Exit;
  End;
 If PSumDr<>PSumCr Then Begin
  ErrMsg:=T3('L''@ecriture n''est pas @equilibr@ee.',
      'The entry is out of balance.','Die Buchung ist nicht ausgeglichen.');
  Exit;
 End;
 If NJ+PN>MAXJL Then Begin
  ErrMsg:=T3('Le journal est plein.','The journal is full.',
      'Das Journal ist voll.');
  Exit;
 End;
 Inc(SU.NextJ);
 For I:=1 To PN Do Begin
  Inc(NJ);
  Jl^[NJ].Id:=SU.NextJ;Jl^[NJ].Dt:=D;Jl^[NJ].Acc:=PL[I].Acc;
  Jl^[NJ].Dr:=PL[I].Dr;Jl^[NJ].Cr:=PL[I].Cr;
  Jl^[NJ].Src:=Copy(Src,1,12);Jl^[NJ].Cm:=Copy(Cmt,1,20);Jl^[NJ].Rec:=False;
 End;
 Recalc;
 Modified:=True;
 Commit:=True;
End;

Function AddInv(Typ,Party: Integer; Const No: String; D,Amt: LongInt): Boolean;
Begin
 AddInv:=False;
 If NIv>=MAXINV Then Begin
  ErrMsg:=T3('Trop de factures.','Too many invoices.','Zu viele Rechnungen.');
  Exit;
 End;
 Inc(NIv);
 Iv^[NIv].Typ:=Typ;Iv^[NIv].Party:=Party;Iv^[NIv].No:=Copy(No,1,12);
 Iv^[NIv].Date:=D;Iv^[NIv].Amt:=Amt;Iv^[NIv].Paid:=0;
 AddInv:=True;
End;

Function Owing(I: Integer): LongInt;
Begin
 Owing:=Iv^[I].Amt-Iv^[I].Paid;
End;

Function PartyBal(Typ,P: Integer): LongInt;
Var I: Integer; S: LongInt;
Begin
 S:=0;
 For I:=1 To NIv Do
  If (Iv^[I].Typ=Typ) And (Iv^[I].Party=P) Then S:=S+Owing(I);
 PartyBal:=S;
End;

Function DueDate(I: Integer): LongInt;
Var P: PPartyArr;
Begin
 If Iv^[I].Typ=1 Then P:=Vn Else P:=Cu;
 DueDate:=DayToDate(DayNum(Iv^[I].Date)+P^[Iv^[I].Party].NDays);
End;

Function FindItem(Const Code: String): Integer;
Var I: Integer; U: String;
Begin
 FindItem:=0;
 U:=Upper(TrimStr(Code));
 If U='' Then Exit;
 For I:=1 To NI Do If Upper(It^[I].Code)=U Then Begin FindItem:=I;Exit;End;
End;

{ ---- donnees par defaut ---- }

Procedure DefaultSetup;
Var I: Integer;
Begin
 FillChar(SU,SizeOf(SU),0);
 SU.Rng[1].Lo:=1000;SU.Rng[1].Hi:=1999;
 SU.Rng[2].Lo:=2000;SU.Rng[2].Hi:=2999;
 SU.Rng[3].Lo:=3000;SU.Rng[3].Hi:=3999;
 SU.Rng[4].Lo:=4000;SU.Rng[4].Hi:=4999;
 SU.Rng[5].Lo:=5000;SU.Rng[5].Hi:=5999;
 SU.Rng[6].Lo:=6000;SU.Rng[6].Hi:=6999;
 SU.Msg[1]:=Dc('Paiement sur r@eception S.V.P. Frais d''administration de '+
     '1.5% par mois apr@es 30 jours.');
 SU.Msg[2]:='Payment upon receipt please. 1.5% administration charges per '+
     'month after 30 days.';
 SU.Msg[3]:=Dc('Zahlung bei Erhalt bitte. 1,5% Verwaltungsgeb@3hr pro Monat '+
     'nach 30 Tagen.');
 SU.Link[LK_AP]:=2200;SU.Link[LK_AR]:=1200;SU.Link[LK_GSTPD]:=1310;
 SU.Link[LK_GSTCL]:=2310;SU.Link[LK_WAGE]:=6500;SU.Link[LK_TAXPAY]:=2320;
 SU.Link[LK_PENPAY]:=2330;SU.Link[LK_UIPAY]:=2340;SU.Link[LK_FRTEXP]:=6100;
 SU.Link[LK_FRTREV]:=4300;SU.Link[LK_PDISC]:=5100;SU.Link[LK_SDISC]:=4900;
 SU.Link[LK_ADJ]:=5200;SU.Link[LK_RET]:=3500;SU.Link[LK_BANK]:=1080;
 SU.Gst:=500;SU.IncT:=1500;SU.Pen:=495;SU.UI:=188;
 SU.NextChq:=301;SU.NextRcpt:=1;SU.NextInv:=1001;SU.NextJ:=0;
 For I:=1 To 3 Do If SU.Msg[I]='' Then SU.Msg[I]:='';
End;

Procedure ClearData;
Begin
 NA:=0;NV:=0;NC_:=0;NE:=0;NI:=0;NP:=0;NIv:=0;NJ:=0;PN:=0;
 FillChar(Ac^,SizeOf(TAccArr),0);
 FillChar(Vn^,SizeOf(TPartyArr),0);
 FillChar(Cu^,SizeOf(TPartyArr),0);
 FillChar(Em^,SizeOf(TEmpArr),0);
 FillChar(It^,SizeOf(TItemArr),0);
 FillChar(Pj^,SizeOf(TPrjArr),0);
 FillChar(Iv^,SizeOf(TInvArr),0);
 FillChar(Jl^,SizeOf(TJArr),0);
End;

Procedure DefaultChart;
Begin
 AddA(1000,T3('Petite caisse','Petty Cash','Kleine Kasse'),False);
 AddA(1080,T3('Banque : Compte courant','Bank: Current','Bank: Girokonto'),
     True);
 AddA(1090,T3('Banque : Compte d''@epargne','Bank: Savings','Bank: Sparkonto'),
     True);
 AddA(1200,T3('Comptes clients','Accounts Receivable','Forderungen'),False);
 AddA(1300,T3('Inventaire','Inventory','Warenbestand'),False);
 AddA(1310,T3('TPS pay@ee sur achats','GST Paid on Purchases','Vorsteuer'),
     False);
 AddA(1320,T3('Frais pay@es d''avance','Prepaid Expenses','Aktive Abgrenzung'),
     False);
 AddA(1500,T3('V@ehicules','Vehicles','Fahrzeuge'),False);
 AddA(1510,T3('Amort. cumul@e : V@ehicules','Accum Deprec: Vehicles',
     'Kum. Abschr.: Fahrzeuge'),False);
 AddA(1520,T3('Mobilier et @equipement','Furniture and Equipment',
     'B@3roausstattung'),False);
 AddA(1530,T3('Amort. cumul@e : Mobilier','Accum Deprec: Furn & Equip',
     'Kum. Abschr.: Ausstattung'),False);
 AddA(1540,T3('Mat@eriel informatique','Computer Hardware','Computer-Hardware'),
     False);
 AddA(2200,T3('Comptes fournisseurs','Accounts Payable','Verbindlichkeiten'),
     False);
 AddA(2310,T3('TPS perc@ue sur ventes','GST Charged on Sales','Umsatzsteuer'),
     False);
 AddA(2320,T3('Imp@ots retenus @a payer','Income Tax Payable','Lohnsteuer'),
     False);
 AddA(2330,T3('R@egime de pension @a payer','Pension Plan Payable',
     'Rentenvers. zu zahlen'),False);
 AddA(2340,T3('Assurance-emploi @a payer','Unemployment Ins Payable',
     'Arbeitslosenv. zu zahlen'),False);
 AddA(2700,T3('Emprunt bancaire','Bank Loan','Bankdarlehen'),False);
 AddA(3000,T3('Capital-actions','Capital Stock','Stammkapital'),False);
 AddA(3500,T3('B@en@efices non r@epartis','Retained Earnings','Gewinnvortrag'),
     False);
 AddA(4100,T3('Ventes','Sales','Umsatzerl@2se'),False);
 AddA(4200,T3('Revenus de services','Service Revenue','Dienstleistungserl@2se'),
     False);
 AddA(4300,T3('Revenus de transport','Freight Revenue','Frachterl@2se'),False);
 AddA(4900,T3('Escomptes sur ventes','Sales Discounts','Erl@2sschm@1lerungen'),
     False);
 AddA(5000,T3('Co@ut des marchandises vendues','Cost of Goods Sold',
     'Wareneinsatz'),False);
 AddA(5100,T3('Escomptes sur achats','Purchase Discounts',
     'Skonti auf Eink@1ufe'),False);
 AddA(5200,T3('Ajustements d''inventaire','Inventory Adjustments',
     'Bestandskorrekturen'),False);
 AddA(6000,T3('Publicit@e','Advertising','Werbung'),False);
 AddA(6100,T3('Frais de transport','Freight Expense','Frachtkosten'),False);
 AddA(6200,T3('Fournitures de bureau','Office Supplies','B@3romaterial'),False);
 AddA(6300,T3('Loyer','Rent','Miete'),False);
 AddA(6400,T3('T@el@ephone','Telephone','Telefon'),False);
 AddA(6500,T3('Salaires et gages','Wages and Salaries','L@2hne und Geh@1lter'),
     False);
 AddA(6700,T3('Frais bancaires','Bank Charges','Bankgeb@3hren'),False);
 AddA(6800,T3('Services publics','Utilities','Nebenkosten'),False);
End;

Procedure InitNewCompany;
Begin
 ClearData;
 DefaultSetup;
 SU.Co:=T3('Nouvelle soci@et@e','New Company','Neue Firma');
 DefaultChart;
 Recalc;
 Named:=False;Modified:=False;
 FileN:='';
End;

Procedure AddVend(Const Nm,A1,A2,Ph: String; Acc: Integer);
Begin
 Inc(NV);
 FillChar(Vn^[NV],SizeOf(TParty),0);
 Vn^[NV].Name:=Dc(Nm);Vn^[NV].Ad1:=Dc(A1);Vn^[NV].Ad2:=Dc(A2);Vn^[NV].Phone:=Ph;
 Vn^[NV].Acc:=Acc;Vn^[NV].Tax:=True;Vn^[NV].DPct:=2;Vn^[NV].DDays:=10;
 Vn^[NV].NDays:=30;
End;

Procedure AddCust(Const Nm,A1,A2,Ph: String; Acc: Integer);
Begin
 Inc(NC_);
 FillChar(Cu^[NC_],SizeOf(TParty),0);
 Cu^[NC_].Name:=Dc(Nm);Cu^[NC_].Ad1:=Dc(A1);Cu^[NC_].Ad2:=Dc(A2);
 Cu^[NC_].Phone:=Ph;
 Cu^[NC_].Acc:=Acc;Cu^[NC_].Tax:=True;Cu^[NC_].DPct:=2;Cu^[NC_].DDays:=10;
 Cu^[NC_].NDays:=30;Cu^[NC_].Limit:=1000000;
End;

Procedure AddItemRec(Const Cd,Ds,Un: String; Pr,Co,Q: LongInt; Svc: Boolean);
Begin
 Inc(NI);
 FillChar(It^[NI],SizeOf(TItem),0);
 It^[NI].Code:=Cd;It^[NI].Desc:=Dc(Ds);It^[NI].Unit_:=Un;
 It^[NI].Price:=Pr;It^[NI].Cost:=Co;It^[NI].Qty:=Q;It^[NI].Svc:=Svc;
 It^[NI].AAcc:=1300;It^[NI].CAcc:=5000;
 If Svc Then It^[NI].RAcc:=4200 Else It^[NI].RAcc:=4100;
End;

Procedure SampleInvoice(Typ,P: Integer; Const No: String; D,
    Net: LongInt; Acc: Integer);
Var Tx: LongInt; Cmt: String;
Begin
 Tx:=PctOf(Net,SU.Gst);
 PClear;
 If Typ=1 Then Begin
  PDr(Acc,Net);PDr(LinkAcc(LK_GSTPD),Tx);PCr(LinkAcc(LK_AP),Net+Tx);
  Cmt:=Vn^[P].Name;
 End Else Begin
  PDr(LinkAcc(LK_AR),Net+Tx);PCr(Acc,Net);PCr(LinkAcc(LK_GSTCL),Tx);
  Cmt:=Cu^[P].Name;
 End;
 If Commit(D,No,Cmt) Then AddInv(Typ,P,No,D,Net+Tx);
End;

Procedure InitSampleCompany;
Var D0,D1: LongInt;
Begin
 InitNewCompany;
 SU.Co:=T3('CONSTRUCTION UNIVERSELLE','UNIVERSAL CONSTRUCTION','UNIVERSAL BAU');
 SU.Ad1:='1234 Main Street';SU.Ad2:='Montreal, QC  H3A 1B2';
 FileN:='UNIVERSL.SDB';
 D0:=DayToDate(DayNum(SessDate)-90);
 PClear;
 PDr(1080,2500000);PDr(1000,50000);PDr(1090,1000000);PDr(1500,3000000);
 PDr(1520,800000);
 PDr(1300,420000);
 PCr(2700,1500000);PCr(3000,5000000);PCr(3500,1270000);
 Commit(D0,'OUV-01',T3('Soldes d''ouverture','Opening balances',
     'Er@2ffnungssalden'));
 AddVend('Papeterie Centrale','45 rue Saint-Denis','Montr@eal, QC',
     '514-555-0101',6200);
 AddVend('Quincaillerie Bolduc','789 Industrial Blvd','Laval, QC',
     '450-555-0188',1300);
 AddVend('Bell Canada','1 Carrefour Alexander-Graham-Bell','Verdun, QC',
     '514-555-0142',6400);
 AddCust('Les Entreprises Tremblay','12 chemin des Pins','Qu@ebec, QC',
     '418-555-0123',4100);
 AddCust('Maison Dufresne Inc.','88 avenue du Parc','Montr@eal, QC',
     '514-555-0177',4100);
 AddCust('Habitations Lavoie','5 rue de la Gare','Sherbrooke, QC',
     '819-555-0160',4200);
 AddItemRec('2X4-8','Montant 2x4 - 8 pieds','ea',650,400,50000,False);
 AddItemRec('CLOU-1','Clous 3 pouces (boite)','box',1295,700,12000,False);
 AddItemRec('PLYW-4','Contreplaque 4x8','ea',3995,2500,8000,False);
 AddItemRec('MO-HR','Main-d''oeuvre (heure)','hr',4500,0,0,True);
 Em^[1].Name:='Marie Gagnon';Em^[1].Ad1:='22 rue Principale';
 Em^[1].Ad2:='Laval, QC';
 Em^[1].SIN:='123-456-789';Em^[1].Rate:=2200;Em^[1].Hrs:=8000;
 Em^[2].Name:='Jean Roy';Em^[2].Ad1:='9 boul. Industriel';
 Em^[2].Ad2:=Dc('Montr@eal, QC');
 Em^[2].SIN:='987-654-321';Em^[2].Rate:=1850;Em^[2].Hrs:=8000;
 NE:=2;
 Pj^[1].Name:=T3('R@enovation Tremblay','Tremblay Renovation','Umbau Tremblay');
 Pj^[1].Budget:=2500000;
 Pj^[2].Name:=T3('Maison Dufresne','Dufresne House','Haus Dufresne');
 Pj^[2].Budget:=4200000;
 NP:=2;
 D1:=DayNum(SessDate);
 SampleInvoice(1,1,'PC-4417',DayToDate(D1-50),32000,6200);
 SampleInvoice(1,2,'QB-8821',DayToDate(D1-45),145000,1300);
 SampleInvoice(1,3,'BC-0305',DayToDate(D1-5),18500,6400);
 SampleInvoice(2,1,'1001',DayToDate(D1-40),285000,4100);
 SampleInvoice(2,2,'1002',DayToDate(D1-35),520000,4100);
 SampleInvoice(2,3,'1003',DayToDate(D1-4),96000,4200);
 SU.NextInv:=1004;
 Recalc;
 Modified:=False;
End;

{ ---- fichier de la societe ---- }

Const
 MAGIC = 'SIMPLY01';

Procedure WrBlk(Var F: File; Var Buf; N: LongInt);
Begin
 If N>0 Then BlockWrite(F,Buf,Word(N));
End;

Function SaveCo(Const FN: String): Boolean;
Var F: File; M: String[8];
Begin
 SaveCo:=False;
 Assign(F,FN);
 {$I-}
 Rewrite(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 M:=MAGIC;
 {$I-}
 BlockWrite(F,M,SizeOf(M));
 BlockWrite(F,SU,SizeOf(SU));
 BlockWrite(F,NA,2);BlockWrite(F,NV,2);BlockWrite(F,NC_,2);BlockWrite(F,NE,2);
 BlockWrite(F,NI,2);BlockWrite(F,NP,2);BlockWrite(F,NIv,2);BlockWrite(F,NJ,2);
 WrBlk(F,Ac^,LongInt(NA)*SizeOf(TAcc));
 WrBlk(F,Vn^,LongInt(NV)*SizeOf(TParty));
 WrBlk(F,Cu^,LongInt(NC_)*SizeOf(TParty));
 WrBlk(F,Em^,LongInt(NE)*SizeOf(TEmp));
 WrBlk(F,It^,LongInt(NI)*SizeOf(TItem));
 WrBlk(F,Pj^,LongInt(NP)*SizeOf(TPrj));
 WrBlk(F,Iv^,LongInt(NIv)*SizeOf(TInv));
 WrBlk(F,Jl^,LongInt(NJ)*SizeOf(TJL));
 Close(F);
 {$I+}
 SaveCo:=IOResult=0;
End;

Function LoadCo(Const FN: String): Boolean;
Var F: File; M: String[8]; Rd: Word; OK: Boolean;
    A,B,C,D,E,G,H,J: Integer;
 Procedure Rb(Var Buf; Cnt: LongInt);
 Begin
  If Cnt>0 Then Begin
   {$I-}
   BlockRead(F,Buf,Word(Cnt),Rd);
   {$I+}
   If (IOResult<>0) Or (LongInt(Rd)<>Cnt) Then OK:=False;
  End;
 End;
Begin
 LoadCo:=False;
 Assign(F,FN);
 {$I-}
 Reset(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 OK:=True;
 Rb(M,SizeOf(M));
 If OK And (M<>MAGIC) Then OK:=False;
 If OK Then Begin
  ClearData;
  Rb(SU,SizeOf(SU));
  Rb(A,2);Rb(B,2);Rb(C,2);Rb(D,2);Rb(E,2);Rb(G,2);Rb(H,2);Rb(J,2);
  If OK And ((A>MAXACC) Or (B>MAXVEN) Or (C>MAXCUS) Or (D>MAXEMP) Or (E>MAXITM)
   Or (G>MAXPRJ) Or (H>MAXINV) Or (J>MAXJL) Or (A<0) Or (B<0) Or (C<0) Or (D<0)
   Or (E<0) Or (G<0) Or (H<0) Or (J<0)) Then OK:=False;
 End;
 If OK Then Begin
  NA:=A;NV:=B;NC_:=C;NE:=D;NI:=E;NP:=G;NIv:=H;NJ:=J;
  Rb(Ac^,LongInt(NA)*SizeOf(TAcc));
  Rb(Vn^,LongInt(NV)*SizeOf(TParty));
  Rb(Cu^,LongInt(NC_)*SizeOf(TParty));
  Rb(Em^,LongInt(NE)*SizeOf(TEmp));
  Rb(It^,LongInt(NI)*SizeOf(TItem));
  Rb(Pj^,LongInt(NP)*SizeOf(TPrj));
  Rb(Iv^,LongInt(NIv)*SizeOf(TInv));
  Rb(Jl^,LongInt(NJ)*SizeOf(TJL));
 End;
 Close(F);
 If OK Then Begin Recalc;FileN:=FN;Named:=True;Modified:=False;End
 Else InitNewCompany;
 LoadCo:=OK;
End;

Procedure AllocData;
Begin
 New(Ac);New(Vn);New(Cu);New(Em);New(It);New(Pj);New(Iv);New(Jl);New(RL);
End;

{ ====================================================================== }
{                  PRIMITIVES DE DESSIN (style Windows 95)               }
{ ====================================================================== }

Procedure Bx(X1,Y1,X2,Y2,C: Integer);
Begin
 If (X2<X1) Or (Y2<Y1) Then Exit;
 SetFillStyle(SolidFill,C);
 Bar(X1,Y1,X2,Y2);
End;

Procedure Ln(X1,Y1,X2,Y2,C: Integer);
Begin
 SetColor(C);
 SetLineStyle(SolidLn,0,1);
 Line(X1,Y1,X2,Y2);
End;

Procedure Raised(X1,Y1,X2,Y2: Integer);
Begin
 Bx(X1,Y1,X2,Y2,cLGr);
 Ln(X1,Y1,X2-1,Y1,cWht);Ln(X1,Y1,X1,Y2-1,cWht);
 Ln(X1,Y2,X2,Y2,cBlk);Ln(X2,Y1,X2,Y2,cBlk);
 Ln(X1+1,Y2-1,X2-1,Y2-1,cDGr);Ln(X2-1,Y1+1,X2-1,Y2-1,cDGr);
End;

Procedure Sunken(X1,Y1,X2,Y2,C: Integer);
Begin
 Bx(X1,Y1,X2,Y2,C);
 Ln(X1,Y1,X2-1,Y1,cDGr);Ln(X1,Y1,X1,Y2-1,cDGr);
 Ln(X1+1,Y1+1,X2-2,Y1+1,cBlk);Ln(X1+1,Y1+1,X1+1,Y2-2,cBlk);
 Ln(X1,Y2,X2,Y2,cWht);Ln(X2,Y1,X2,Y2,cWht);
 Ln(X1+1,Y2-1,X2-1,Y2-1,cLGr);Ln(X2-1,Y1+1,X2-1,Y2-1,cLGr);
End;

Procedure Etched(X1,Y1,X2,Y2: Integer);
Begin
 SetLineStyle(SolidLn,0,1);
 SetColor(cDGr);Rectangle(X1,Y1,X2-1,Y2-1);
 SetColor(cWht);Rectangle(X1+1,Y1+1,X2,Y2);
End;

Procedure Dither(X1,Y1,X2,Y2,C1,C2: Integer);
Var Y: Integer;
Begin
 Bx(X1,Y1,X2,Y2,C1);
 SetColor(C2);
 For Y:=Y1 To Y2 Do Begin
  If Odd(Y) Then SetLineStyle(UserBitLn,$AAAA,1) Else
    SetLineStyle(UserBitLn,$5555,1);
  Line(X1,Y,X2,Y);
 End;
 SetLineStyle(SolidLn,0,1);
End;

Procedure SFocusRect(X1,Y1,X2,Y2: Integer);
Begin
 SetColor(cBlk);
 SetLineStyle(UserBitLn,$AAAA,1);
 Rectangle(X1,Y1,X2,Y2);
 SetLineStyle(SolidLn,0,1);
End;

Procedure Arw(CX,CY,Dir,C: Integer);
Var I: Integer;
Begin
 SetColor(C);
 SetLineStyle(SolidLn,0,1);
 Case Dir Of
  1: For I:=0 To 3 Do Line(CX-I,CY-2+I,CX+I,CY-2+I);
  2: For I:=0 To 3 Do Line(CX-I,CY+2-I,CX+I,CY+2-I);
  3: For I:=0 To 3 Do Line(CX-2+I,CY-I,CX-2+I,CY+I);
  4: For I:=0 To 3 Do Line(CX+2-I,CY-I,CX+2-I,CY+I);
 End;
End;

Procedure Tx(X,Y: Integer; Const S: String; C: Integer);
Begin
 SetColor(C);
 OutTextXY(X,Y,S);
End;

Procedure TxB(X,Y: Integer; Const S: String; C: Integer);
Begin
 SetColor(C);
 OutTextXY(X,Y,S);
 OutTextXY(X+1,Y,S);
End;

Function TextW(Const S: String): Integer;
Var I,N: Integer;
Begin
 N:=0;
 For I:=1 To Length(S) Do If S[I]<>'&' Then Inc(N);
 TextW:=N*8;
End;

{ Texte avec lettre soulignee : '&' precede la lettre }
Procedure UTx(X,Y: Integer; Const S: String; C: Integer);
Var I,P: Integer; Mark: Boolean;
Begin
 SetColor(C);
 P:=0;Mark:=False;
 For I:=1 To Length(S) Do Begin
  If (S[I]='&') And Not Mark Then Mark:=True
  Else Begin
   OutTextXY(X+P*8,Y,S[I]);
   If Mark Then Begin
    SetLineStyle(SolidLn,0,1);
    Line(X+P*8,Y+9,X+P*8+7,Y+9);
    Mark:=False;
   End;
   Inc(P);
  End;
 End;
End;

Function StripAmp(Const S: String): String;
Var I: Integer; R: String;
Begin
 R:='';
 For I:=1 To Length(S) Do If S[I]<>'&' Then R:=R+S[I];
 StripAmp:=R;
End;

Function InBox(X,Y,X1,Y1,X2,Y2: LongInt): Boolean;
Begin
 InBox:=(X>=X1) And (X<=X2) And (Y>=Y1) And (Y<=Y2);
End;

{ ====================================================================== }
{                  EVENEMENTS (clavier / souris)                         }
{ ====================================================================== }

Procedure PollEvent(Var E: TEvent);
Var Ch: Char; K: Word;
Begin
 E.Kind:=0;E.Key:=0;E.X:=MX;E.Y:=MY;E.B:=MB;
 If KeyPressed Then Begin
  Ch:=ReadKey;
  If Ch=#0 Then K:=256+Ord(ReadKey) Else K:=Ord(Ch);
  E.Kind:=1;E.Key:=K;
  Exit;
 End;
 PrevMX:=MX;PrevMY:=MY;LastB:=MB;
 GetMouseState(MX,MY,MB);
 E.X:=MX;E.Y:=MY;E.B:=MB;
 If ((MB And 1)<>0) And ((LastB And 1)=0) Then E.Kind:=2
 Else If ((MB And 1)=0) And ((LastB And 1)<>0) Then E.Kind:=3
 Else If (MX<>PrevMX) Or (MY<>PrevMY) Then E.Kind:=4
 Else Delay(4);
End;

Function IsDouble(X,Y: LongInt): Boolean;
Var T: LongInt;
Begin
 T:=Tick;
 IsDouble:=(Abs(T-LastClickT)<45) And (Abs(X-LastClickX)<5)
     And (Abs(Y-LastClickY)<5);
 LastClickT:=T;LastClickX:=X;LastClickY:=Y;
End;

{ ====================================================================== }
{                       SOURCES DE LISTES                                }
{ ====================================================================== }

Function BankCount: Integer;
Var I,C: Integer;
Begin
 C:=0;
 For I:=1 To NA Do If Ac^[I].Bank Then Inc(C);
 BankCount:=C;
End;

Function NthBank(N: Integer): Integer;
Var I,C: Integer;
Begin
 NthBank:=0;C:=0;
 For I:=1 To NA Do If Ac^[I].Bank Then Begin
  Inc(C);
  If C=N Then Begin NthBank:=I;Exit;End;
 End;
End;

Function PayByName(I: Integer): String;
Begin
 Case I Of
  1: PayByName:=T3('Ch@eque','Cheque','Scheck');
  2: PayByName:=T3('Comptant','Cash','Bargeld');
  3: PayByName:=T3('Carte de d@ebit','Debit card','EC-Karte');
  Else PayByName:='';
 End;
End;

Function ListCount(S: Integer): Integer;
Begin
 Case S Of
  srcVend: ListCount:=NV;
  srcCust: ListCount:=NC_;
  srcAcct: ListCount:=NA;
  srcBank: ListCount:=BankCount;
  srcEmp: ListCount:=NE;
  srcItem: ListCount:=NI;
  srcType: ListCount:=6;
  srcPayBy: ListCount:=3;
  srcPrj: ListCount:=NP;
  srcKind,srcRKind: ListCount:=1;
  Else ListCount:=0;
 End;
End;

Function ListRec(S,I: Integer): Integer;
Begin
 If S=srcBank Then ListRec:=NthBank(I) Else ListRec:=I;
End;

Function ListText(S,I: Integer): String;
Var R: Integer;
Begin
 ListText:='';
 If (I<1) Or (I>ListCount(S)) Then Exit;
 R:=ListRec(S,I);
 Case S Of
  srcVend: ListText:=Vn^[R].Name;
  srcCust: ListText:=Cu^[R].Name;
  srcAcct,srcBank: ListText:=IntStr(Ac^[R].Num)+'  '+Ac^[R].Name;
  srcEmp: ListText:=Em^[R].Name;
  srcItem: ListText:=It^[R].Code+'  '+It^[R].Desc;
  srcType: ListText:=KindName(I);
  srcPayBy: ListText:=PayByName(I);
  srcPrj: ListText:=Pj^[R].Name;
  srcKind: ListText:=T3('Payer les factures fournisseurs','Pay Vendor Invoices',
      'Lieferantenrechnungen zahlen');
  srcRKind: ListText:=T3('Recevoir paiements clients',
      'Receive Customer Payments','Kundenzahlungen erhalten');
 End;
End;

{ ====================================================================== }
{                        MOTEUR DE FENETRES                              }
{ ====================================================================== }

Procedure Dispatch(P: PWin; Ev,A,B: Integer); Forward;
Procedure DrawAll; Forward;
Procedure DrawMain; Forward;
Procedure DrawTop; Forward;
Procedure DrawRepText(P: PWin; I,AX,AY: Integer); Forward;
Procedure DrawChart(AX,AY,Wd,Ht: Integer); Forward;
Function SelectList(Const Ti: String; Src,Cur: Integer): Integer; Forward;

Function NewWin(K: Integer; Const Ti: String; Wd,Ht: Integer): PWin;
Var P: PWin; X,Y: Integer;
Begin
 New(P);
 FillChar(P^,SizeOf(TWin),0);
 P^.Kind:=K;P^.Title:=Ti;P^.W:=Wd;P^.H:=Ht;
 X:=(SCR_W-Wd) Div 2+WSN*14;
 Y:=(SCR_H-24-Ht) Div 2+WSN*12;
 If X+Wd>SCR_W Then X:=SCR_W-Wd;
 If X<0 Then X:=0;
 If Y+Ht>SCR_H-24 Then Y:=SCR_H-24-Ht;
 If Y<0 Then Y:=0;
 P^.X:=X;P^.Y:=Y;
 P^.CurTab:=1;P^.Foc:=0;P^.Press:=0;P^.GId:=0;
 NewWin:=P;
End;

Function AddCtl(P: PWin; K,Idn,Cx,Cy,Wd,Ht: Integer; Const T: String): Integer;
Var N: Integer;
Begin
 Inc(P^.NC);
 N:=P^.NC;
 P^.Ctl[N].Kind:=K;P^.Ctl[N].Id:=Idn;P^.Ctl[N].X:=Cx;P^.Ctl[N].Y:=Cy;
 P^.Ctl[N].W:=Wd;P^.Ctl[N].H:=Ht;P^.Ctl[N].Txt:=T;
 P^.Ctl[N].Tab:=P^.BTab;P^.Ctl[N].Ena:=True;P^.Ctl[N].Max:=40;P^.Ctl[N].Num:=0;
 P^.Ctl[N].Src:=0;P^.Ctl[N].Sel:=0;P^.Ctl[N].Cur:=Length(T);
 P^.Ctl[N].On:=False;P^.Ctl[N].Bold:=False;P^.Ctl[N].Rt:=False;
 P^.Ctl[N].Def:=False;
 AddCtl:=N;
End;

Procedure NewTab(P: PWin; Const T: String);
Begin
 Inc(P^.NTab);
 P^.TabT[P^.NTab]:=T;
 P^.BTab:=P^.NTab;
End;

Function Ix(P: PWin; Id: Integer): Integer;
Var I: Integer;
Begin
 Ix:=0;
 For I:=1 To P^.NC Do If P^.Ctl[I].Id=Id Then Begin Ix:=I;Exit;End;
End;

Procedure AddLbl(P: PWin; Id,X,Y: Integer; Const T: String);
Begin
 AddCtl(P,ckLabel,Id,X,Y,Length(T)*8,8,T);
End;

Procedure AddLblW(P: PWin; Id,X,Y,Wd: Integer; Const T: String; Rt,Bd: Boolean);
Var I: Integer;
Begin
 I:=AddCtl(P,ckLabel,Id,X,Y,Wd,8,T);
 P^.Ctl[I].Rt:=Rt;P^.Ctl[I].Bold:=Bd;
End;

Procedure AddEdit(P: PWin; Id,X,Y,Wd,Mx,Num: Integer; Const T: String);
Var I: Integer;
Begin
 I:=AddCtl(P,ckEdit,Id,X,Y,Wd,18,T);
 P^.Ctl[I].Max:=Mx;P^.Ctl[I].Num:=Num;
 If Num In [1,4,5] Then P^.Ctl[I].Rt:=True;
End;

Procedure AddChk(P: PWin; Id,X,Y: Integer; Const T: String; On: Boolean);
Var I: Integer;
Begin
 I:=AddCtl(P,ckCheck,Id,X,Y,Length(T)*8+22,14,T);
 P^.Ctl[I].On:=On;
End;

Procedure AddRadio(P: PWin; Id,X,Y,Grp: Integer; Const T: String; On: Boolean);
Var I: Integer;
Begin
 I:=AddCtl(P,ckRadio,Id,X,Y,Length(T)*8+22,14,T);
 P^.Ctl[I].On:=On;P^.Ctl[I].Sel:=Grp;
End;

Procedure AddBtn(P: PWin; Id,X,Y,Wd: Integer; Const T: String; Def: Boolean);
Var I: Integer;
Begin
 I:=AddCtl(P,ckButton,Id,X,Y,Wd,22,T);
 P^.Ctl[I].Def:=Def;
End;

Procedure AddCombo(P: PWin; Id,X,Y,Wd,Src: Integer);
Var I: Integer;
Begin
 I:=AddCtl(P,ckCombo,Id,X,Y,Wd,18,'');
 P^.Ctl[I].Src:=Src;
End;

Procedure AddBox(P: PWin; X,Y,Wd,Ht: Integer; Const T: String);
Begin
 AddCtl(P,ckBox,0,X,Y,Wd,Ht,T);
End;

Procedure AddRule(P: PWin; X,Y,Wd: Integer);
Begin
 AddCtl(P,ckRule,0,X,Y,Wd,2,'');
End;

{ Grille : Vis rangees visibles ; Mode 0 saisie, 1 liste, 2 liste a cocher }
Function AddGrid(P: PWin; Id,X,Y,Vis,Mode,NRows: Integer): Integer;
Var I: Integer;
Begin
 I:=AddCtl(P,ckGrid,Id,X,Y,16,18+Vis*RH,'');
 P^.GId:=I;P^.GVis:=Vis;P^.GMode:=Mode;P^.GN:=NRows;P^.GTop:=0;
 P^.GRow:=1;P^.GCol:=1;P^.GNC:=0;P^.GEdit:=False;
 AddGrid:=I;
End;

Procedure GridCol(P: PWin; Wd,Knd: Integer; Const Hd: String; Look: Boolean);
Begin
 Inc(P^.GNC);
 P^.GColW[P^.GNC]:=Wd;P^.GKind[P^.GNC]:=Knd;P^.GHead[P^.GNC]:=Hd;
 P^.GLook[P^.GNC]:=Look;
 P^.Ctl[P^.GId].W:=P^.Ctl[P^.GId].W+Wd;
End;

Procedure GridClear(P: PWin; NRows: Integer);
Var R,C: Integer;
Begin
 For R:=1 To MAXROW Do For C:=1 To MAXCOL Do P^.GCell[R,C]:='';
 P^.GN:=NRows;P^.GTop:=0;P^.GRow:=1;P^.GCol:=1;P^.GEdit:=False;
End;

Function Cell(P: PWin; R,C: Integer): String;
Begin
 Cell:=P^.GCell[R,C];
End;

Procedure SetCell(P: PWin; R,C: Integer; Const S: String);
Begin
 P^.GCell[R,C]:=S;
End;

{ acces par identifiant }
Function GT(P: PWin; Id: Integer): String;
Var I: Integer;
Begin
 I:=Ix(P,Id);
 If I>0 Then GT:=P^.Ctl[I].Txt Else GT:='';
End;

Procedure ST(P: PWin; Id: Integer; Const S: String);
Var I: Integer;
Begin
 I:=Ix(P,Id);
 If I>0 Then Begin
   P^.Ctl[I].Txt:=S;P^.Ctl[I].Cur:=Length(S);P^.Ctl[I].Sel:=0;End;
End;

Function GV(P: PWin; Id: Integer): Boolean;
Var I: Integer;
Begin
 I:=Ix(P,Id);
 If I>0 Then GV:=P^.Ctl[I].On Else GV:=False;
End;

Procedure SV(P: PWin; Id: Integer; B: Boolean);
Var I: Integer;
Begin
 I:=Ix(P,Id);
 If I>0 Then P^.Ctl[I].On:=B;
End;

Function GS(P: PWin; Id: Integer): Integer;
Var I: Integer;
Begin
 I:=Ix(P,Id);
 If I>0 Then GS:=P^.Ctl[I].Sel Else GS:=0;
End;

Procedure SS(P: PWin; Id,N: Integer);
Var I: Integer;
Begin
 I:=Ix(P,Id);
 If I>0 Then P^.Ctl[I].Sel:=N;
End;

Procedure SEna(P: PWin; Id: Integer; B: Boolean);
Var I: Integer;
Begin
 I:=Ix(P,Id);
 If I>0 Then P^.Ctl[I].Ena:=B;
End;

{ Valeurs numeriques d'un champ }
Function GMoney(P: PWin; Id: Integer): LongInt;
Begin
 GMoney:=ParseMoney(GT(P,Id));
End;

Procedure SMoney(P: PWin; Id: Integer; V: LongInt);
Begin
 ST(P,Id,FmtMoney(V));
End;

Procedure SDate(P: PWin; Id: Integer; D: LongInt);
Begin
 ST(P,Id,FmtDate(D));
End;

{ Mise en forme d'un champ a la sortie }
Procedure Normalize(P: PWin; I: Integer);
Var D: LongInt; S: String;
Begin
 With P^.Ctl[I] Do Begin
  If Kind<>ckEdit Then Exit;
  S:=TrimStr(Txt);
  If S='' Then Exit;
  Case Num Of
   1: Txt:=FmtMoney(ParseMoney(S));
   2: If ParseDate(S,D) Then Txt:=FmtDate(D);
   4: Txt:=FmtPct(ParsePct(S));
   5: Txt:=FmtQty(ParseMoney(S));
  End;
  Cur:=Length(Txt);
 End;
End;

Function Focusable(P: PWin; I: Integer): Boolean;
Begin
 With P^.Ctl[I] Do
  Focusable:=Ena
      And (Kind In [ckEdit,ckCheck,ckButton,ckCombo,ckGrid,ckRadio,ckText])
   And ((Tab=0) Or (Tab=P^.CurTab));
End;

Procedure SetFocus(P: PWin; I: Integer);
Var Old: Integer;
Begin
 Old:=P^.Foc;
 If (Old>0) And (Old<=P^.NC) And (Old<>I) Then Begin
  If P^.Ctl[Old].Kind=ckGrid Then Begin
   If P^.GEdit Then Begin
    P^.GCell[P^.GRow,P^.GCol]:=P^.GBuf;P^.GEdit:=False;
    Dispatch(P,evCell,P^.GRow,P^.GCol);
   End;
  End;
  If P^.Ctl[Old].Kind=ckEdit Then Begin
   Normalize(P,Old);
   Dispatch(P,evChange,P^.Ctl[Old].Id,0);
  End;
 End;
 P^.Foc:=I;
 If (I>0) And (P^.Ctl[I].Kind=ckEdit) Then Begin
  P^.Ctl[I].Cur:=Length(P^.Ctl[I].Txt);
  P^.Ctl[I].Sel:=1;
 End;
 DirtyTop:=True;
End;

Procedure MoveFocus(P: PWin; Dir: Integer);
Var I,N,Cnt: Integer;
Begin
 N:=P^.NC;I:=P^.Foc;
 If N=0 Then Exit;
 For Cnt:=1 To N Do Begin
  I:=I+Dir;
  If I<1 Then I:=N;
  If I>N Then I:=1;
  If Focusable(P,I) Then Begin SetFocus(P,I);Exit;End;
 End;
End;

Procedure FirstFocus(P: PWin);
Var I: Integer;
Begin
 For I:=1 To P^.NC Do
  If Focusable(P,I) And (P^.Ctl[I].Kind<>ckButton) Then Begin
    SetFocus(P,I);Exit;End;
 For I:=1 To P^.NC Do If Focusable(P,I) Then Begin SetFocus(P,I);Exit;End;
End;

{ ---- dessin d'une fenetre ---- }

Procedure SDrawVScroll(X1,Y1,X2,Y2,Top,Vis,N: Integer);
Var TH,TY,TL,Rg: Integer;
Begin
 Raised(X1,Y1,X2,Y1+15);Arw((X1+X2) Div 2,Y1+8,1,cBlk);
 Raised(X1,Y2-15,X2,Y2);Arw((X1+X2) Div 2,Y2-7,2,cBlk);
 Dither(X1,Y1+16,X2,Y2-16,cWht,cLGr);
 If N>Vis Then Begin
  TL:=Y2-16-(Y1+16)+1;
  TH:=Integer(LongInt(TL)*Vis Div N);
  If TH<14 Then TH:=14;
  Rg:=N-Vis;
  TY:=Y1+16+Integer(LongInt(TL-TH)*Top Div Rg);
  Raised(X1,TY,X2,TY+TH-1);
 End;
End;

Procedure DrawGrid(P: PWin; I,AX,AY: Integer);
Var C,R,Rw,X,Y,GW,Mx,Off: Integer; S: String; Sl: Boolean; Fc: Boolean;
Begin
 GW:=P^.Ctl[I].W-16;
 Fc:=(P^.Foc=I);
 X:=AX;
 For C:=1 To P^.GNC Do Begin
  Raised(X,AY,X+P^.GColW[C]-1,AY+15);
  S:=P^.GHead[C];
  Mx:=(P^.GColW[C]-6) Div 8;
  If Length(S)>Mx Then S:=Copy(S,1,Mx);
  If P^.GKind[C] In [1,3] Then Tx(X+P^.GColW[C]-4-Length(S)*8,AY+4,S,cBlk)
  Else Tx(X+4,AY+4,S,cBlk);
  X:=X+P^.GColW[C];
 End;
 If X<AX+GW Then Raised(X,AY,AX+GW-1,AY+15);
 Bx(AX,AY+16,AX+GW-1,AY+17+P^.GVis*RH-1,cWht);
 For R:=1 To P^.GVis Do Begin
  Rw:=P^.GTop+R;
  Y:=AY+16+(R-1)*RH;
  If Rw<=P^.GN Then Begin
   Sl:=(P^.GMode>=1) And (Rw=P^.GRow);
   If Sl Then Bx(AX,Y,AX+GW-1,Y+RH-1,cNavy);
   X:=AX;
   For C:=1 To P^.GNC Do Begin
    S:=P^.GCell[Rw,C];
    If P^.GEdit And (Rw=P^.GRow) And (C=P^.GCol) And (P^.GMode=0) Then Begin
     Bx(X+1,Y+1,X+P^.GColW[C]-2,Y+RH-1,cWht);
     S:=P^.GBuf+'_';
    End;
    Mx:=(P^.GColW[C]-4) Div 8;
    If Length(S)>Mx Then Begin
     If P^.GEdit And (Rw=P^.GRow) And (C=P^.GCol) Then
       S:=Copy(S,Length(S)-Mx+1,Mx) Else S:=Copy(S,1,Mx);
    End;
    If Sl Then Begin
     If (P^.GMode=2) And (C=1) Then Tx(X+2,Y+3,S,cWht)
     Else If P^.GKind[C] In [1,3] Then
       Tx(X+P^.GColW[C]-3-Length(S)*8,Y+3,S,cWht)
     Else Tx(X+3,Y+3,S,cWht);
    End Else Begin
     If P^.GKind[C] In [1,3] Then Tx(X+P^.GColW[C]-3-Length(S)*8,Y+3,S,cBlk)
     Else Tx(X+3,Y+3,S,cBlk);
    End;
    X:=X+P^.GColW[C];
   End;
  End;
 End;
 { quadrillage }
 SetLineStyle(SolidLn,0,1);
 X:=AX;
 For C:=1 To P^.GNC Do Begin
  X:=X+P^.GColW[C];
  If P^.GMode=0 Then Ln(X-1,AY+16,X-1,AY+17+P^.GVis*RH-1,cLGr);
 End;
 If P^.GMode=0 Then
  For R:=1 To P^.GVis Do Ln(AX,AY+16+R*RH-1,AX+GW-1,AY+16+R*RH-1,cLGr);
 { cellule courante }
 If (P^.GMode=0) And (P^.GN>0) And (P^.GRow>P^.GTop)
     And (P^.GRow<=P^.GTop+P^.GVis) And (P^.GNC>0) Then Begin
  Off:=0;
  For C:=1 To P^.GCol-1 Do Off:=Off+P^.GColW[C];
  Y:=AY+16+(P^.GRow-P^.GTop-1)*RH;
  SetColor(cBlk);SetLineStyle(SolidLn,0,1);
  Rectangle(AX+Off,Y,AX+Off+P^.GColW[P^.GCol]-1,Y+RH-1);
  If Fc Then Rectangle(AX+Off+1,Y+1,AX+Off+P^.GColW[P^.GCol]-2,Y+RH-2);
 End;
 Ln(AX,AY+16,AX+GW-1,AY+16,cDGr);
 SDrawVScroll(AX+GW,AY,AX+GW+15,AY+17+P^.GVis*RH-1,P^.GTop,P^.GVis,P^.GN);
End;

Procedure DrawCtl(P: PWin; I,OX,OY: Integer);
Var AX,AY,X2,Y2,Vis,Off,Tw,Bx0,Cc: Integer; S: String; Fc,Pr: Boolean;
Begin
 With P^.Ctl[I] Do Begin
  AX:=OX+X;AY:=OY+Y;X2:=AX+W-1;Y2:=AY+H-1;
  Fc:=(P^.Foc=I);
  Pr:=(P^.Press=I);
  If Ena Then Cc:=cBlk Else Cc:=cDGr;
  Case Kind Of
   ckLabel: Begin
    S:=Txt;
    If Rt Then AX:=AX+W-Length(S)*8;
    If Bold Then TxB(AX,AY,S,Cc) Else Tx(AX,AY,S,Cc);
   End;
   ckEdit: Begin
    If Ena Then Sunken(AX,AY,X2,Y2,cWht) Else Sunken(AX,AY,X2,Y2,cLGr);
    Vis:=(W-8) Div 8;
    Off:=0;
    If (Fc And (Cur>Vis)) Then Off:=Cur-Vis;
    If (Not Fc) And (Length(Txt)>Vis) Then Off:=0;
    S:=Copy(Txt,Off+1,Vis);
    If Fc And (Sel=1) And (Length(Txt)>0) Then Begin
     Bx(AX+3,AY+3,AX+3+Length(S)*8,AY+14,cNavy);
     Tx(AX+4,AY+5,S,cWht);
    End Else Begin
     If Rt And Not Fc Then Tx(X2-3-Length(S)*8,AY+5,S,Cc) Else
       Tx(AX+4,AY+5,S,Cc);
     If Fc And Ena Then Ln(AX+4+(Cur-Off)*8,AY+3,AX+4+(Cur-Off)*8,AY+14,cBlk);
    End;
   End;
   ckCheck: Begin
    Sunken(AX,AY,AX+12,AY+12,cWht);
    If On Then Begin
     Ln(AX+3,AY+5,AX+5,AY+7,Cc);Ln(AX+3,AY+6,AX+5,AY+8,Cc);
     Ln(AX+5,AY+7,AX+9,AY+3,Cc);Ln(AX+5,AY+8,AX+9,AY+4,Cc);
    End;
    Tx(AX+20,AY+3,StripAmp(Txt),Cc);
    If Fc Then SFocusRect(AX+18,AY+1,X2,AY+12);
   End;
   ckRadio: Begin
    SetColor(cDGr);Circle(AX+6,AY+6,6);
    SetColor(cWht);Arc(AX+6,AY+6,200,20,5);
    SetFillStyle(SolidFill,cWht);FillEllipse(AX+6,AY+6,4,4);
    If On Then Begin
      SetFillStyle(SolidFill,cBlk);FillEllipse(AX+6,AY+6,2,2);End;
    Tx(AX+20,AY+3,StripAmp(Txt),Cc);
    If Fc Then SFocusRect(AX+18,AY+1,X2,AY+12);
   End;
   ckButton: Begin
    If Def Then Begin
      SetColor(cBlk);SetLineStyle(SolidLn,0,1);Rectangle(AX-1,AY-1,X2+1,Y2+1);
      End;
    If Pr Then Begin
     Bx(AX,AY,X2,Y2,cLGr);
     SetColor(cDGr);Rectangle(AX,AY,X2,Y2);
    End Else Raised(AX,AY,X2,Y2);
    Tw:=TextW(Txt);
    Bx0:=0;If Pr Then Bx0:=1;
    If Ena Then UTx(AX+(W-Tw) Div 2+Bx0,AY+(H-8) Div 2+Bx0,Txt,cBlk)
    Else Begin
     UTx(AX+(W-Tw) Div 2+1,AY+(H-8) Div 2+1,Txt,cWht);
     UTx(AX+(W-Tw) Div 2,AY+(H-8) Div 2,Txt,cDGr);
    End;
    If Fc Then SFocusRect(AX+4,AY+4,X2-4,Y2-4);
   End;
   ckCombo: Begin
    Sunken(AX,AY,X2,Y2,cWht);
    S:=ListText(Src,Sel);
    Vis:=(W-26) Div 8;
    If Length(S)>Vis Then S:=Copy(S,1,Vis);
    If Fc Then Begin
     Bx(AX+3,AY+3,AX+3+Length(S)*8+1,AY+14,cNavy);
     Tx(AX+4,AY+5,S,cWht);
    End Else Tx(AX+4,AY+5,S,Cc);
    Raised(X2-17,AY+2,X2-2,Y2-2);
    Arw(X2-10,AY+8,2,cBlk);
   End;
   ckBox: Begin
    Etched(AX,AY+4,X2,Y2);
    S:=Txt;
    If S<>'' Then Begin
     Bx(AX+6,AY,AX+10+Length(S)*8,AY+8,cLGr);
     Tx(AX+8,AY,S,cBlk);
    End;
   End;
   ckRule: Begin
    Ln(AX,AY,X2,AY,cDGr);Ln(AX,AY+1,X2,AY+1,cWht);
   End;
   ckGrid: DrawGrid(P,I,AX,AY);
   ckText: DrawRepText(P,I,AX,AY);
   ckGraph: DrawChart(AX,AY,W,H);
  End;
 End;
End;

Procedure DrawWin(P: PWin; Active: Boolean);
Var X1,Y1,X2,Y2,OX,OY,I,T,TbX,TW: Integer;
Begin
 X1:=P^.X;Y1:=P^.Y;X2:=X1+P^.W-1;Y2:=Y1+P^.H-1;
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 Raised(X1,Y1,X2,Y2);
 If Active Then Bx(X1+3,Y1+3,X2-3,Y1+20,cNavy) Else
   Bx(X1+3,Y1+3,X2-3,Y1+20,cDGr);
 TxB(X1+8,Y1+8,P^.Title,cWht);
 Raised(X2-20,Y1+5,X2-5,Y1+18);
 Ln(X2-16,Y1+8,X2-9,Y1+15,cBlk);Ln(X2-15,Y1+8,X2-8,Y1+15,cBlk);
 Ln(X2-9,Y1+8,X2-16,Y1+15,cBlk);Ln(X2-8,Y1+8,X2-15,Y1+15,cBlk);
 OX:=X1+3;OY:=Y1+22;
 Bx(OX,OY,X2-3,Y2-3,cLGr);
 If P^.NTab>0 Then Begin
  TbX:=OX+4;
  For T:=1 To P^.NTab Do Begin
   TW:=Length(P^.TabT[T])*8+16;
   If T=P^.CurTab Then Begin
    Bx(TbX-2,OY+2,TbX+TW+1,OY+22,cLGr);
    Ln(TbX-2,OY+3,TbX-2,OY+22,cWht);Ln(TbX-2,OY+3,TbX+2,OY+1,cWht);
    Ln(TbX+2,OY+1,TbX+TW-3,OY+1,cWht);
    Ln(TbX+TW+1,OY+3,TbX+TW+1,OY+21,cBlk);
    Tx(TbX+8,OY+7,P^.TabT[T],cBlk);
   End Else Begin
    Ln(TbX,OY+5,TbX,OY+22,cWht);Ln(TbX,OY+5,TbX+TW-1,OY+5,cWht);
    Ln(TbX+TW-1,OY+5,TbX+TW-1,OY+22,cBlk);
    Ln(TbX+1,OY+22,TbX+TW-1,OY+22,cWht);
    Tx(TbX+8,OY+9,P^.TabT[T],cBlk);
   End;
   TbX:=TbX+TW;
  End;
  Ln(OX+2,OY+22,TbX-4,OY+22,cLGr);
  Ln(TbX-2,OY+22,X2-5,OY+22,cWht);
  Ln(OX+2,OY+22,OX+2,Y2-5,cWht);
  Ln(X2-5,OY+22,X2-5,Y2-5,cBlk);Ln(OX+2,Y2-5,X2-5,Y2-5,cBlk);
  Ln(X2-6,OY+23,X2-6,Y2-6,cDGr);Ln(OX+3,Y2-6,X2-6,Y2-6,cDGr);
 End;
 For I:=1 To P^.NC Do
  If (P^.Ctl[I].Tab=0) Or (P^.Ctl[I].Tab=P^.CurTab) Then DrawCtl(P,I,OX,OY);
End;

{ ---- gestion des evenements d'une fenetre ---- }

Procedure ClampGrid(P: PWin);
Begin
 If P^.GRow<1 Then P^.GRow:=1;
 If P^.GRow>P^.GN Then P^.GRow:=P^.GN;
 If P^.GRow<1 Then P^.GRow:=1;
 If P^.GRow<=P^.GTop Then P^.GTop:=P^.GRow-1;
 If P^.GRow>P^.GTop+P^.GVis Then P^.GTop:=P^.GRow-P^.GVis;
 If P^.GTop<0 Then P^.GTop:=0;
 If P^.GTop>P^.GN-P^.GVis Then P^.GTop:=P^.GN-P^.GVis;
 If P^.GTop<0 Then P^.GTop:=0;
End;

Procedure GridCommit(P: PWin);
Begin
 If P^.GEdit Then Begin
  P^.GCell[P^.GRow,P^.GCol]:=P^.GBuf;
  P^.GEdit:=False;
  Dispatch(P,evCell,P^.GRow,P^.GCol);
 End;
End;

Function GridEditable(P: PWin; C: Integer): Boolean;
Begin
 GridEditable:=(P^.GMode=0) And (P^.GKind[C] In [0,1]);
End;

Procedure GridMove(P: PWin; DR,DC: Integer);
Var C,N: Integer;
Begin
 GridCommit(P);
 If DC<>0 Then Begin
  C:=P^.GCol;N:=0;
  Repeat
   C:=C+DC;
   If C>P^.GNC Then Begin C:=1;Inc(P^.GRow);End;
   If C<1 Then Begin C:=P^.GNC;Dec(P^.GRow);End;
   Inc(N);
  Until GridEditable(P,C) Or (N>P^.GNC+1);
  P^.GCol:=C;
 End;
 P^.GRow:=P^.GRow+DR;
 ClampGrid(P);
 DirtyTop:=True;
End;


Function RepKey(P: PWin; K: Word): Boolean; Forward;
Procedure RepMouse(P: PWin; I,X,Y: Integer); Forward;

Function GridFirstEd(P: PWin): Integer;
Var C: Integer;
Begin
 GridFirstEd:=1;
 For C:=P^.GNC DownTo 1 Do If GridEditable(P,C) Then GridFirstEd:=C;
End;

Function GridLastEd(P: PWin): Integer;
Var C: Integer;
Begin
 GridLastEd:=P^.GNC;
 For C:=1 To P^.GNC Do If GridEditable(P,C) Then GridLastEd:=C;
End;

{ retourne True si la touche a ete traitee }
Function GridKey(P: PWin; K: Word): Boolean;
Var Ch: Char; Mx,R: Integer; Ok: Boolean;
Begin
 GridKey:=True;
 If P^.GN<1 Then Begin GridKey:=False;Exit;End;
 If P^.GMode=0 Then Begin
  Case K Of
   K_UP: GridMove(P,-1,0);
   K_DOWN: GridMove(P,1,0);
   K_LEFT: GridMove(P,0,-1);
   K_RIGHT: GridMove(P,0,1);
   K_PGUP: GridMove(P,-P^.GVis,0);
   K_PGDN: GridMove(P,P^.GVis,0);
   K_HOME: Begin GridCommit(P);P^.GCol:=GridFirstEd(P);DirtyTop:=True;End;
   K_END: Begin GridCommit(P);P^.GCol:=GridLastEd(P);DirtyTop:=True;End;
   K_ENTER,K_TAB:
    If (P^.GRow>=P^.GN) And (P^.GCol>=GridLastEd(P)) Then Begin
     GridCommit(P);MoveFocus(P,1);
    End Else GridMove(P,0,1);
   K_STAB:
    If (P^.GRow<=1) And (P^.GCol<=GridFirstEd(P)) Then Begin
     GridCommit(P);MoveFocus(P,-1);
    End Else GridMove(P,0,-1);
   K_F2: If GridEditable(P,P^.GCol) Then Begin
     P^.GEdit:=True;P^.GBuf:=P^.GCell[P^.GRow,P^.GCol];DirtyTop:=True;
    End;
   K_F4: If P^.GLook[P^.GCol] Then Begin
     GridCommit(P);Dispatch(P,evLookup,P^.GRow,P^.GCol);DirtyTop:=True;
    End;
   K_DEL: If GridEditable(P,P^.GCol) Then Begin
     P^.GEdit:=False;P^.GCell[P^.GRow,P^.GCol]:='';
     Dispatch(P,evCell,P^.GRow,P^.GCol);DirtyTop:=True;
    End;
   K_BKSP: If GridEditable(P,P^.GCol) Then Begin
     If Not P^.GEdit Then Begin
      P^.GEdit:=True;P^.GBuf:=P^.GCell[P^.GRow,P^.GCol];
     End;
     If Length(P^.GBuf)>0 Then Delete(P^.GBuf,Length(P^.GBuf),1);
     DirtyTop:=True;
    End;
   K_ESC: If P^.GEdit Then Begin P^.GEdit:=False;DirtyTop:=True;End
          Else GridKey:=False;
   32..255: Begin
     If GridEditable(P,P^.GCol) Then Begin
      Ch:=Chr(K);
      Ok:=True;
      If P^.GKind[P^.GCol]=1 Then Ok:=(Ch In ['0'..'9','.',',','-',' ']);
      If Ok Then Begin
       If Not P^.GEdit Then Begin P^.GEdit:=True;P^.GBuf:='';End;
       If Length(P^.GBuf)<26 Then P^.GBuf:=P^.GBuf+Ch;
       DirtyTop:=True;
      End;
     End Else GridKey:=False;
    End;
   Else GridKey:=False;
  End;
 End Else Begin
  Case K Of
   K_UP: Begin Dec(P^.GRow);ClampGrid(P);End;
   K_DOWN: Begin Inc(P^.GRow);ClampGrid(P);End;
   K_PGUP: Begin P^.GRow:=P^.GRow-P^.GVis;ClampGrid(P);End;
   K_PGDN: Begin P^.GRow:=P^.GRow+P^.GVis;ClampGrid(P);End;
   K_HOME: Begin P^.GRow:=1;ClampGrid(P);End;
   K_END: Begin P^.GRow:=P^.GN;ClampGrid(P);End;
   K_ENTER: If P^.GMode=1 Then Dispatch(P,evDbl,P^.GRow,P^.GCol) Else
     GridKey:=False;
   32: If P^.GMode=2 Then Dispatch(P,evDbl,P^.GRow,1) Else GridKey:=False;
   33..255: Begin
     Ch:=UpCase(Chr(K));
     If P^.GMode=1 Then Begin
      R:=P^.GRow;Mx:=0;Ok:=False;
      Repeat
       Inc(R);Inc(Mx);
       If R>P^.GN Then R:=1;
       Ok:=(Length(P^.GCell[R,1])>0) And (UpCase(P^.GCell[R,1][1])=Ch);
      Until Ok Or (Mx>P^.GN);
      If Ok Then Begin P^.GRow:=R;ClampGrid(P);End;
     End Else GridKey:=False;
    End;
   Else GridKey:=False;
  End;
  DirtyTop:=True;
 End;
End;

Procedure GridMouse(P: PWin; I: Integer; X,Y: LongInt; Dbl: Boolean);
Var AX,AY,GW,GH,R,C,Off,N: Integer;
Begin
 AX:=P^.X+3+P^.Ctl[I].X;AY:=P^.Y+22+P^.Ctl[I].Y;
 GW:=P^.Ctl[I].W-16;GH:=18+P^.GVis*RH;
 If X>=AX+GW Then Begin
  GridCommit(P);
  If Y<AY+16 Then Dec(P^.GTop)
  Else If Y>=AY+GH-16 Then Inc(P^.GTop)
  Else If Y<AY+16+LongInt(GH-32)*P^.GTop Div Max2(1,P^.GN) Then
    P^.GTop:=P^.GTop-P^.GVis
  Else P^.GTop:=P^.GTop+P^.GVis;
  If P^.GTop>P^.GN-P^.GVis Then P^.GTop:=P^.GN-P^.GVis;
  If P^.GTop<0 Then P^.GTop:=0;
  DirtyTop:=True;
  Exit;
 End;
 If Y<AY+16 Then Exit;
 R:=P^.GTop+(Y-AY-16) Div RH+1;
 If (R<1) Or (R>P^.GN) Then Exit;
 Off:=0;C:=0;
 For N:=1 To P^.GNC Do Begin
  If (X>=AX+Off) And (X<AX+Off+P^.GColW[N]) Then C:=N;
  Off:=Off+P^.GColW[N];
 End;
 If C=0 Then Exit;
 GridCommit(P);
 P^.GRow:=R;P^.GCol:=C;
 DirtyTop:=True;
 If P^.GMode=2 Then Dispatch(P,evDbl,R,C)
 Else If Dbl Then Begin
  If P^.GMode=1 Then Dispatch(P,evDbl,R,C)
  Else If P^.GLook[C] Then Dispatch(P,evLookup,R,C);
 End;
End;

Function SelTitle(Src: Integer): String;
Begin
 Case Src Of
  srcVend: SelTitle:=T3('Choisir un fournisseur','Select Vendor',
      'Lieferant w@1hlen');
  srcCust: SelTitle:=T3('Choisir un client','Select Customer','Kunde w@1hlen');
  srcAcct,srcBank: SelTitle:=T3('Choisir un compte','Select Account',
      'Konto w@1hlen');
  srcEmp: SelTitle:=T3('Choisir un employ@e','Select Employee',
      'Mitarbeiter w@1hlen');
  srcItem: SelTitle:=T3('Choisir un article','Select Item','Artikel w@1hlen');
  srcPrj: SelTitle:=T3('Choisir un projet','Select Project','Projekt w@1hlen');
  Else SelTitle:=T3('Choisir','Select','Ausw@1hlen');
 End;
End;

Procedure OpenCombo(P: PWin; I: Integer);
Var N: Integer;
Begin
 If Not P^.Ctl[I].Ena Then Exit;
 N:=SelectList(SelTitle(P^.Ctl[I].Src),P^.Ctl[I].Src,P^.Ctl[I].Sel);
 If N>0 Then Begin
  P^.Ctl[I].Sel:=N;
  Dispatch(P,evChange,P^.Ctl[I].Id,N);
 End;
 Dirty:=True;
End;

Procedure PressBtn(P: PWin; I: Integer);
Begin
 If (I>0) And P^.Ctl[I].Ena Then Dispatch(P,evButton,P^.Ctl[I].Id,0);
 DirtyTop:=True;
End;

Procedure PressDefault(P: PWin);
Var I: Integer;
Begin
 For I:=1 To P^.NC Do
  If (P^.Ctl[I].Kind=ckButton) And P^.Ctl[I].Def And P^.Ctl[I].Ena Then Begin
   If P^.Foc>0 Then Begin
    If P^.Ctl[P^.Foc].Kind=ckEdit Then Begin
     Normalize(P,P^.Foc);
     Dispatch(P,evChange,P^.Ctl[P^.Foc].Id,0);
    End;
   End;
   PressBtn(P,I);Exit;
  End;
End;

Procedure WinClose(P: PWin);
Begin
 P^.Done:=True;
 Dispatch(P,evClose,0,0);
 DirtyTop:=True;
End;

Procedure ToggleRadio(P: PWin; I: Integer);
Var J: Integer;
Begin
 For J:=1 To P^.NC Do
  If (P^.Ctl[J].Kind=ckRadio) And (P^.Ctl[J].Sel=P^.Ctl[I].Sel) Then
    P^.Ctl[J].On:=False;
 P^.Ctl[I].On:=True;
End;

Procedure EditKey(P: PWin; I: Integer; K: Word);
Var Ch: Char; Ok: Boolean;
Begin
 Case K Of
  K_BKSP: With P^.Ctl[I] Do Begin
    If Sel=1 Then Begin Txt:='';Cur:=0;Sel:=0;End
    Else If Cur>0 Then Begin Delete(Txt,Cur,1);Dec(Cur);End;
   End;
  K_DEL: With P^.Ctl[I] Do Begin
    If Sel=1 Then Begin Txt:='';Cur:=0;Sel:=0;End
    Else If Cur<Length(Txt) Then Delete(Txt,Cur+1,1);
   End;
  K_LEFT: With P^.Ctl[I] Do Begin Sel:=0;If Cur>0 Then Dec(Cur);End;
  K_RIGHT: With P^.Ctl[I] Do Begin Sel:=0;If Cur<Length(Txt) Then Inc(Cur);End;
  K_HOME: With P^.Ctl[I] Do Begin Sel:=0;Cur:=0;End;
  K_END: With P^.Ctl[I] Do Begin Sel:=0;Cur:=Length(Txt);End;
  K_ENTER: If P^.EnterOK Then PressDefault(P) Else MoveFocus(P,1);
  K_UP: MoveFocus(P,-1);
  K_DOWN: MoveFocus(P,1);
  32..255: With P^.Ctl[I] Do Begin
    Ch:=Chr(K);
    Ok:=True;
    Case Num Of
     1,4,5: Ok:=(Ch In ['0'..'9','.',',','-',' ','(',')']);
     2: Ok:=(Ch In ['0'..'9','/','-','.',' ']);
     3: Ok:=(Ch In ['0'..'9']);
    End;
    If Ok Then Begin
     If Sel=1 Then Begin Txt:='';Cur:=0;Sel:=0;End;
     If Length(Txt)<Max Then Begin Insert(Ch,Txt,Cur+1);Inc(Cur);End;
    End;
   End;
 End;
End;

Procedure SwitchTab(P: PWin; T: Integer);
Begin
 If (T<1) Or (T>P^.NTab) Or (T=P^.CurTab) Then Exit;
 If P^.Foc>0 Then SetFocus(P,0);
 P^.CurTab:=T;
 Dispatch(P,evTab,T,0);
 FirstFocus(P);
 Dirty:=True;
End;

Procedure WinKey(P: PWin; K: Word);
Var F: Integer;
Begin
 F:=P^.Foc;
 DirtyTop:=True;
 If (F>0) Then Begin
  If P^.Ctl[F].Kind=ckGrid Then Begin
   If GridKey(P,K) Then Exit;
  End;
  If P^.Ctl[F].Kind=ckText Then Begin
   If RepKey(P,K) Then Exit;
  End;
 End;
 Case K Of
  K_ESC: WinClose(P);
  K_TAB: MoveFocus(P,1);
  K_STAB: MoveFocus(P,-1);
  374: SwitchTab(P,P^.CurTab+1);
  388: SwitchTab(P,P^.CurTab-1);
  Else Begin
   If F>0 Then Begin
    Case P^.Ctl[F].Kind Of
     ckEdit: EditKey(P,F,K);
     ckButton: Case K Of
       K_ENTER,32: PressBtn(P,F);
       K_UP,K_LEFT: MoveFocus(P,-1);
       K_DOWN,K_RIGHT: MoveFocus(P,1);
      End;
     ckCheck,ckRadio: Case K Of
       32: Begin
         If P^.Ctl[F].Kind=ckRadio Then ToggleRadio(P,F)
         Else P^.Ctl[F].On:=Not P^.Ctl[F].On;
         Dispatch(P,evChange,P^.Ctl[F].Id,0);
        End;
       K_ENTER: If P^.EnterOK Then PressDefault(P) Else MoveFocus(P,1);
       K_UP,K_LEFT: MoveFocus(P,-1);
       K_DOWN,K_RIGHT: MoveFocus(P,1);
      End;
     ckCombo: Case K Of
       K_DOWN,K_F4,32: OpenCombo(P,F);
       K_ENTER: If P^.EnterOK Then PressDefault(P) Else MoveFocus(P,1);
       K_UP: MoveFocus(P,-1);
      End;
    End;
   End Else If K=K_ENTER Then PressDefault(P);
  End;
 End;
End;

Procedure WinDown(P: PWin; X,Y: LongInt; Dbl: Boolean);
Var OX,OY,I,T,TbX,TW,AX,AY,X2: Integer; Hit: Boolean;
Begin
 If Not InBox(X,Y,P^.X,P^.Y,P^.X+P^.W-1,P^.Y+P^.H-1) Then Exit;
 X2:=P^.X+P^.W-1;
 OX:=P^.X+3;OY:=P^.Y+22;
 DirtyTop:=True;
 If (Y>=P^.Y+3) And (Y<=P^.Y+20) Then Begin
  If (X>=X2-20) And (X<=X2-5) Then WinClose(P)
  Else Begin
   Dragging:=True;DragOX:=X-P^.X;DragOY:=Y-P^.Y;
  End;
  Exit;
 End;
 If (P^.NTab>0) And (Y>=OY+2) And (Y<=OY+22) Then Begin
  TbX:=OX+4;
  For T:=1 To P^.NTab Do Begin
   TW:=Length(P^.TabT[T])*8+16;
   If (X>=TbX) And (X<TbX+TW) Then SwitchTab(P,T);
   TbX:=TbX+TW;
  End;
  Exit;
 End;
 For I:=P^.NC DownTo 1 Do Begin
  AX:=OX+P^.Ctl[I].X;AY:=OY+P^.Ctl[I].Y;
  Hit:=P^.Ctl[I].Ena And ((P^.Ctl[I].Tab=0) Or (P^.Ctl[I].Tab=P^.CurTab))
   And (P^.Ctl[I].Kind<>ckLabel) And (P^.Ctl[I].Kind<>ckBox)
       And (P^.Ctl[I].Kind<>ckRule)
   And InBox(X,Y,AX,AY,AX+P^.Ctl[I].W-1,AY+P^.Ctl[I].H-1);
  If Hit Then Begin
   If P^.Foc<>I Then SetFocus(P,I);
   Case P^.Ctl[I].Kind Of
    ckEdit: Begin
      P^.Ctl[I].Sel:=0;
      T:=(X-AX-4) Div 8;
      If T<0 Then T:=0;
      If T>Length(P^.Ctl[I].Txt) Then T:=Length(P^.Ctl[I].Txt);
      P^.Ctl[I].Cur:=T;
     End;
    ckCheck: Begin
      P^.Ctl[I].On:=Not P^.Ctl[I].On;
      Dispatch(P,evChange,P^.Ctl[I].Id,0);
     End;
    ckRadio: Begin
      ToggleRadio(P,I);
      Dispatch(P,evChange,P^.Ctl[I].Id,0);
     End;
    ckButton: P^.Press:=I;
    ckCombo: OpenCombo(P,I);
    ckGrid: GridMouse(P,I,X,Y,Dbl);
    ckText: RepMouse(P,I,X,Y);
   End;
   Exit;
  End;
 End;
End;

Procedure WinUp(P: PWin; X,Y: LongInt);
Var I,AX,AY: Integer;
Begin
 Dragging:=False;
 If P^.Press>0 Then Begin
  I:=P^.Press;P^.Press:=0;
  AX:=P^.X+3+P^.Ctl[I].X;AY:=P^.Y+22+P^.Ctl[I].Y;
  If InBox(X,Y,AX,AY,AX+P^.Ctl[I].W-1,AY+P^.Ctl[I].H-1) Then PressBtn(P,I);
  DirtyTop:=True;
 End;
End;

Procedure WinMove(P: PWin; X,Y: LongInt);
Var NX,NY: Integer;
Begin
 If Dragging Then Begin
  NX:=X-DragOX;NY:=Y-DragOY;
  If NX<0 Then NX:=0;
  If NX+P^.W>SCR_W Then NX:=SCR_W-P^.W;
  If NY<0 Then NY:=0;
  If NY+30>SCR_H-24 Then NY:=SCR_H-24-30;
  If (NX<>P^.X) Or (NY<>P^.Y) Then Begin P^.X:=NX;P^.Y:=NY;Dirty:=True;End;
 End;
End;

Procedure DrawAll;
Var I: Integer;
Begin
 HideMouse;
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 DrawMain;
 For I:=1 To WSN Do DrawWin(WS[I],I=WSN);
 ShowMouse;
 Dirty:=False;DirtyTop:=False;
End;

Procedure DrawTop;
Begin
 If WSN=0 Then Begin DrawAll;Exit;End;
 HideMouse;
 DrawWin(WS[WSN],True);
 ShowMouse;
 DirtyTop:=False;
End;

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
{ OS/2-0 : FENETRES DE SAMPLE ACCOUNTING EN CONTROLES DE PM            }
{ ================================================================== }
{ La version DOS dessine ses fenetres (cadre, etiquettes, champs,      }
{ cases, boutons, listes deroulantes, grilles, onglets) et les mene    }
{ par sa propre boucle (RunWin). Ici chaque fenetre est une vraie      }
{ fenetre de Presentation Manager : etiquettes (WC_STATIC), champs de  }
{ saisie (WC_ENTRYFIELD), cases a cocher et boutons radio, boutons     }
{ (WC_BUTTON), listes deroulantes (WC_COMBOBOX), cadres de groupe ;    }
{ seules les grilles, les onglets, les etats et les graphiques restent }
{ dessines (dans la zone client, avec la souris et le clavier de la    }
{ version DOS). Les valeurs restent dans la fenetre de la version DOS  }
{ (TWin) : les evenements de PM appellent ses procedures (Dispatch,    }
{ PressBtn, Normalize...), puis les controles de PM sont remis a jour. }

Const
 WC_COMBOBOX = $FFFF0002; CBS_DROPDOWNLIST = 4;
 BS_AUTOCHECKBOX = 2; BS_AUTORADIOBUTTON = 4;
 SS_TEXT = 1; SS_GROUPBOX = 2; DT_RIGHT = $0200; DT_VCENTER = $0400;
 BM_QUERYCHECK = $0124; BM_SETCHECK = $0125;
 EN_SETFOCUS = 1; EN_KILLFOCUS = 2; EN_CHANGE = 4; BN_CLICKED = 1; CBN_LBSELECT = 3;
 ID_SCTL = 1000;

Function WinShowWindow(H, Show : LongInt) : LongInt; External 'PMWIN';
Function WinQueryFocus(HD : LongInt) : LongInt; External 'PMWIN';
Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; External 'PMWIN';

Type
 PSdState = ^TSdState;
 TSdState = Record
  P : PWin;
  Prev : PSdState;                           { fenetre qui l'a ouverte }
  Fr, Cl : LongInt;
  H : Array[1..MAXCTL] Of LongInt;           { controle de PM (0 : dessine) }
  Txt : Array[1..MAXCTL] Of String[60];      { texte montre }
  On, Ena, Vis : Array[1..MAXCTL] Of Boolean;
  Sel, Cnt : Array[1..MAXCTL] Of Integer;
  Foc : Integer;
  { zone montree par la zone client : rectangle de l'image, parties
    dessinees ; copie de l'image quand une autre fenetre la recouvre }
  GX0, GY0, GW, GH, GN : LongInt;
  GEx : Array[0..63, 0..3] Of LongInt;
  Snap : Pointer;
  { etat de la fenetre secondaire de la couche OS/2 (fenetres imbriquees) }
  SFr, SCl, SX0, SY0, SW, SH, SN, SMode, STop : LongInt;
  SEx : Array[0..63, 0..3] Of LongInt;
 End;

Var
 Sd : PSdState;
 SdBusy : Boolean;                 { mise a jour par le programme }
 SdClsDone : Boolean;

Function SdVisible(P: PWin; I: Integer): Boolean;
Begin
 SdVisible:=(P^.Ctl[I].Tab=0) Or (P^.Ctl[I].Tab=P^.CurTab);
End;

Function SdText(H: LongInt): String;
Var Buf: Array[0..259] Of Byte; N, K: LongInt; S: String;
Begin
 N:=WinQueryWindowText(H,250,LongInt(@Buf));
 S:='';
 K:=0;
 While (K<N) And (Buf[K]<>0) Do Begin S:=S+Chr(Buf[K]);Inc(K);End;
 SdText:=S;
End;

{ libelle de PM : '&' de la version DOS -> '~' }
Function SdLabel(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do If S[I]='&' Then S[I]:='~';
 SdLabel:=S;
End;

{ rectangles dessines de la fenetre (grilles, etats, graphiques, onglets,
  filets) : les seuls que la zone client recopie de l'image }
Procedure SdAreas;
Var P: PWin; I, OX, OY, X2, Y2, AX, AY: Integer;

 Procedure Add(A1, B1, A2, B2: Integer);
 Begin
  If CatNEx>63 Then Exit;
  CatEx[CatNEx,0]:=A1;CatEx[CatNEx,1]:=B1;CatEx[CatNEx,2]:=A2;CatEx[CatNEx,3]:=B2;
  Inc(CatNEx);
 End;

Begin
 P:=Sd^.P;
 CatNEx:=0;
 OX:=P^.X+3;OY:=P^.Y+22;X2:=P^.X+P^.W-1-3;Y2:=P^.Y+P^.H-1-3;
 If P^.NTab>0 Then Begin
  Add(OX,OY,X2,OY+23);
  Add(OX,OY+22,OX+4,Y2);
  Add(X2-7,OY+22,X2,Y2);
  Add(OX,Y2-7,X2,Y2);
 End;
 For I:=1 To P^.NC Do
  If SdVisible(P,I) Then
   With P^.Ctl[I] Do Begin
    AX:=OX+X;AY:=OY+Y;
    Case Kind Of
     ckGrid, ckText, ckGraph : Add(AX,AY,AX+W-1,AY+H-1);
     ckRule : Add(AX,AY,AX+W-1,AY+1);
    End;
   End;
 Sd^.GN:=CatNEx;
 Move(CatEx,Sd^.GEx,SizeOf(CatEx));
End;

{ controles de PM <- valeurs de la fenetre de la version DOS }
Procedure SdPush;
Var P: PWin; I, J, N: Integer; V: Boolean; Hw: LongInt;
Begin
 P:=Sd^.P;
 SdBusy:=True;
 For I:=1 To P^.NC Do Begin
  Hw:=Sd^.H[I];
  If Hw<>0 Then With P^.Ctl[I] Do Begin
   V:=SdVisible(P,I);
   If V<>Sd^.Vis[I] Then Begin
    Dummy:=WinShowWindow(Hw,Ord(V));
    Sd^.Vis[I]:=V;
   End;
   If Ena<>Sd^.Ena[I] Then Begin
    Dummy:=WinEnableWindow(Hw,Ord(Ena));
    Sd^.Ena[I]:=Ena;
   End;
   Case Kind Of
    ckLabel, ckEdit, ckButton, ckBox :
     If Txt<>Sd^.Txt[I] Then Begin
      If Kind=ckEdit Then Dummy:=WinSetWindowText(Hw,OsZ(Txt))
      Else Dummy:=WinSetWindowText(Hw,OsZ(SdLabel(Txt)));
      Sd^.Txt[I]:=Txt;
     End;
    ckCheck, ckRadio :
     If On<>Sd^.On[I] Then Begin
      Dummy:=WinSendMsg(Hw,BM_SETCHECK,Ord(On),0);
      Sd^.On[I]:=On;
     End;
    ckCombo : Begin
      N:=ListCount(Src);
      If N<>Sd^.Cnt[I] Then Begin
       Dummy:=WinSendMsg(Hw,LM_DELETEALL,0,0);
       For J:=1 To N Do Dummy:=WinSendMsg(Hw,LM_INSERTITEM,-1,OsZ(ListText(Src,J)));
       Sd^.Cnt[I]:=N;
       Sd^.Sel[I]:=-1;
      End;
      If Sel<>Sd^.Sel[I] Then Begin
       If (Sel>=1) And (Sel<=N) Then Dummy:=WinSendMsg(Hw,LM_SELECTITEM,Sel-1,1)
       Else Dummy:=WinSetWindowText(Hw,OsZ(''));
       Sd^.Sel[I]:=Sel;
      End;
     End;
   End;
  End;
 End;
 { controle courant de la version DOS (Tab, clic sur une grille...) }
 If P^.Foc<>Sd^.Foc Then Begin
  Sd^.Foc:=P^.Foc;
  If (P^.Foc>0) And (P^.Foc<=P^.NC) Then Begin
   If Sd^.H[P^.Foc]<>0 Then Dummy:=WinSetFocus(HWND_DESKTOP,Sd^.H[P^.Foc])
   Else Dummy:=WinSetFocus(HWND_DESKTOP,Sd^.Cl);
  End;
 End;
 SdBusy:=False;
End;

{ dessin de la fenetre dans l'image, controles de PM a jour }
Procedure SdRedraw;
Begin
 DrawWin(Sd^.P,True);
 Dirty:=False;DirtyTop:=False;
 SdAreas;
 SdPush;
End;

{ champ de saisie quitte : mise en forme de la version DOS et evChange }
Procedure SdLeave(I: Integer);
Var P: PWin;
Begin
 P:=Sd^.P;
 If (I<1) Or (I>P^.NC) Or (Sd^.H[I]=0) Or (P^.Ctl[I].Kind<>ckEdit) Then Exit;
 P^.Ctl[I].Txt:=Copy(SdText(Sd^.H[I]),1,P^.Ctl[I].Max);
 Sd^.Txt[I]:=P^.Ctl[I].Txt;
 Normalize(P,I);
 Dispatch(P,evChange,P^.Ctl[I].Id,0);
 Dirty:=True;
End;

Function SdIndex(Id: LongInt): Integer;
Begin
 SdIndex:=0;
 If (Id>ID_SCTL) And (Id<=ID_SCTL+Sd^.P^.NC) Then SdIndex:=Id-ID_SCTL;
End;

Var SvEx : Array[0..63, 0..3] Of LongInt;

Function SdProc(H, Msg, Mp1, Mp2: LongInt): LongInt;
Var I, K, C, Fl, Vk: LongInt; Hps: LongInt; Rc: Array[0..3] Of LongInt; P: PWin;
    T: PSdState; A0, B0, A1, B1, N0: LongInt;
Begin
 SdProc:=0;
 If Sd=Nil Then Begin SdProc:=WinDefWindowProc(H,Msg,Mp1,Mp2);Exit;End;
 P:=Sd^.P;
 Case Msg Of
  WM_PAINT : Begin
    Hps:=WinBeginPaint(H,0,LongInt(@Rc));
    Dummy:=WinQueryWindowRect(H,LongInt(@Rc));
    Dummy:=WinFillRect(Hps,LongInt(@Rc),CLR_PALEGRAY);
    T:=Sd;
    While (T<>Nil) And (T^.Cl<>H) Do T:=T^.Prev;
    If (T=Sd) Or (T=Nil) Then CatBlit(Hps,CatX0,CatY0,CatX0+CatW-1,CatY0+CatH-1)
    Else Begin
     { fenetre recouverte par une autre : sa copie de l'image }
     A0:=CatX0;B0:=CatY0;A1:=CatW;B1:=CatH;N0:=CatNEx;
     Move(CatEx,SvEx,SizeOf(CatEx));
     CatX0:=T^.GX0;CatY0:=T^.GY0;CatW:=T^.GW;CatH:=T^.GH;CatNEx:=T^.GN;
     Move(T^.GEx,CatEx,SizeOf(CatEx));
     CatSrc:=T^.Snap;
     CatBlit(Hps,CatX0,CatY0,CatX0+CatW-1,CatY0+CatH-1);
     CatSrc:=Nil;
     CatX0:=A0;CatY0:=B0;CatW:=A1;CatH:=B1;CatNEx:=N0;
     Move(SvEx,CatEx,SizeOf(CatEx));
    End;
    Dummy:=WinEndPaint(Hps);
   End;
  WM_CONTROL : If Not SdBusy Then Begin
    I:=SdIndex(PmLo(Mp1));
    C:=PmHi(Mp1);
    If I>0 Then Case P^.Ctl[I].Kind Of
     ckEdit : Case C Of
       EN_SETFOCUS : Begin P^.Foc:=I;Sd^.Foc:=I;End;
       EN_KILLFOCUS : SdLeave(I);
       EN_CHANGE : Begin
         P^.Ctl[I].Txt:=Copy(SdText(Sd^.H[I]),1,P^.Ctl[I].Max);
         Sd^.Txt[I]:=P^.Ctl[I].Txt;
        End;
      End;
     ckCheck, ckRadio : If C=BN_CLICKED Then Begin
       P^.Foc:=I;Sd^.Foc:=I;
       If P^.Ctl[I].Kind=ckRadio Then ToggleRadio(P,I)
       Else P^.Ctl[I].On:=WinSendMsg(Sd^.H[I],BM_QUERYCHECK,0,0)<>0;
       Sd^.On[I]:=P^.Ctl[I].On;
       Dispatch(P,evChange,P^.Ctl[I].Id,0);
       Dirty:=True;
      End;
     ckCombo : If C=CBN_LBSELECT Then Begin
       K:=WinSendMsg(Sd^.H[I],LM_QUERYSELECTION,-1,0);
       If K>=0 Then Begin
        P^.Foc:=I;Sd^.Foc:=I;
        P^.Ctl[I].Sel:=K+1;Sd^.Sel[I]:=K+1;
        Dispatch(P,evChange,P^.Ctl[I].Id,K+1);
        Dirty:=True;
       End;
      End;
    End;
   End;
  WM_COMMAND : Begin
    I:=SdIndex(PmLo(Mp1));
    If (I>0) And (P^.Ctl[I].Kind=ckButton) Then Begin
     { le champ courant est d'abord valide }
     If (P^.Foc>0) And (P^.Foc<=P^.NC) And (P^.Ctl[P^.Foc].Kind=ckEdit) Then SdLeave(P^.Foc);
     P^.Foc:=I;Sd^.Foc:=I;
     PressBtn(P,I);
     Dirty:=True;
    End;
   End;
  WM_CHAR : Begin
    Fl:=PmLo(Mp1);Vk:=PmHi(Mp2);
    SdProc:=1;
    If (Fl And KC_KEYUP)<>0 Then Exit;
    If (Fl And KC_VIRTUALKEY)<>0 Then Begin
     If (Vk=VK_ESC) Then Begin WinClose(P);Dirty:=True;Exit;End;
     If (Vk=VK_TAB) Or (Vk=VK_BACKTAB) Then Begin
      If (P^.Foc>0) And (P^.Foc<=P^.NC) And (P^.Ctl[P^.Foc].Kind=ckEdit) Then SdLeave(P^.Foc);
      If (Vk=VK_BACKTAB) Or ((Fl And KC_SHIFT)<>0) Then MoveFocus(P,-1) Else MoveFocus(P,1);
      Dirty:=True;
      Exit;
     End;
     If ((Vk=VK_ENTER) Or (Vk=VK_NEWLINE)) And (WinQueryFocus(HWND_DESKTOP)<>H) Then Begin
      If (P^.Foc>0) And (P^.Foc<=P^.NC) And (P^.Ctl[P^.Foc].Kind=ckEdit) Then SdLeave(P^.Foc);
      If P^.EnterOK Then PressDefault(P) Else MoveFocus(P,1);
      Dirty:=True;
      Exit;
     End;
    End;
    { zone dessinee (grille, etat) : clavier de la version DOS }
    K:=KeyCode(Mp1,Mp2);
    If K>=0 Then KeyPush(K) Else SdProc:=WinDefWindowProc(H,Msg,Mp1,Mp2);
   End;
  WM_MOUSEMOVE : Begin
    EvMX:=CatX0+PmS16(Mp1);EvMY:=CatY0+CatH-1-PmS16(Mp1 Shr 16);
    SdProc:=WinDefWindowProc(H,Msg,Mp1,Mp2);
   End;
  WM_BUTTON1DOWN, WM_BUTTON1DBLCLK : Begin
    EvMX:=CatX0+PmS16(Mp1);EvMY:=CatY0+CatH-1-PmS16(Mp1 Shr 16);
    Dummy:=WinSetFocus(HWND_DESKTOP,H);
    Dummy:=WinSetCapture(HWND_DESKTOP,H);
    If (P^.Foc>0) And (P^.Foc<=P^.NC) And (P^.Ctl[P^.Foc].Kind=ckEdit) Then SdLeave(P^.Foc);
    MBtn:=MBtn Or 1;MLatch:=MLatch Or 1;
    SdProc:=1;
   End;
  WM_BUTTON1UP : Begin
    EvMX:=CatX0+PmS16(Mp1);EvMY:=CatY0+CatH-1-PmS16(Mp1 Shr 16);
    MBtn:=MBtn And Not 1;
    If MBtn=0 Then Dummy:=WinSetCapture(HWND_DESKTOP,0);
    SdProc:=1;
   End;
  WM_CLOSE : Begin WinClose(P);Dirty:=True;End;
 Else
  SdProc:=WinDefWindowProc(H,Msg,Mp1,Mp2);
 End;
End;

{ fenetre de PM de la fenetre P de la version DOS }
Procedure SdOpen(P: PWin);
Var I, CW, CH, XX, YY, WW, HH, St, Clr: LongInt; Cls: LongInt; Lb: String; C: TCtl; S: PSdState;
Begin
 If Not SdClsDone Then Begin
  SdClsDone:=True;
  Dummy:=WinRegisterClass(OsHab,OsZ('SIMPLYDLG'),LongInt(@SdProc),0,0);
 End;
 New(S);
 FillChar(S^,SizeOf(TSdState),0);
 S^.Prev:=Sd;
 { la fenetre recouverte garde une copie de son image }
 If Sd<>Nil Then Begin
  If Sd^.Snap=Nil Then GetMem(Sd^.Snap,FbW*FbH);
  Move(Fb,Sd^.Snap^,FbW*FbH);
 End;
 Sd:=S;
 Sd^.P:=P;
 { etat de la fenetre secondaire precedente (fenetres imbriquees) }
 Sd^.SFr:=CatFr;Sd^.SCl:=CatCl;Sd^.SX0:=CatX0;Sd^.SY0:=CatY0;
 Sd^.SW:=CatW;Sd^.SH:=CatH;Sd^.SN:=CatNEx;Sd^.SMode:=CatMode;
 Move(CatEx,Sd^.SEx,SizeOf(CatEx));
 If PmTopFr=0 Then PmTopFr:=OsFrame;
 Sd^.STop:=PmTopFr;
 FlushScreen;
 If CatCl=0 Then Begin
  { la fenetre principale garde son image }
  If CatSave=Nil Then GetMem(CatSave,FbW*FbH);
  Move(Fb,CatSave^,FbW*FbH);
 End;
 MBtn:=0;MLatch:=0;
 Dummy:=WinSetCapture(HWND_DESKTOP,0);
 Dummy:=WinEnableWindow(PmTopFr,0);
 CW:=P^.W-6;CH:=P^.H-25;
 CatX0:=P^.X+3;CatY0:=P^.Y+22;CatW:=CW;CatH:=CH;CatMode:=1;CatNEx:=0;
 Sd^.GX0:=CatX0;Sd^.GY0:=CatY0;Sd^.GW:=CW;Sd^.GH:=CH;
 CatCl:=0;
 Sd^.Fr:=PmOpenBox('SIMPLYDLG',P^.Title,CW,CH,Sd^.Cl);
 CatFr:=Sd^.Fr;CatCl:=Sd^.Cl;
 PmTopFr:=Sd^.Fr;
 { cadres de groupe d'abord (sous les autres controles) }
 For I:=1 To P^.NC Do Begin
  C:=P^.Ctl[I];
  Sd^.H[I]:=0;
  If C.Kind=ckBox Then
   Sd^.H[I]:=WinCreateWindow(Sd^.Cl,WC_STATIC,OsZ(SdLabel(C.Txt)),WS_VISIBLE Or SS_GROUPBOX,
     C.X,CH-(C.Y+C.H),C.W,C.H,Sd^.Cl,HWND_TOP,ID_SCTL+I,0,0);
 End;
 For I:=1 To P^.NC Do Begin
  C:=P^.Ctl[I];
  XX:=C.X;WW:=C.W;YY:=C.Y;HH:=C.H;
  Cls:=0;St:=WS_VISIBLE;Lb:=SdLabel(C.Txt);
  Case C.Kind Of
   ckLabel : Begin
     Cls:=WC_STATIC;St:=St Or SS_TEXT Or DT_VCENTER;
     If C.Rt Then St:=St Or DT_RIGHT;
     YY:=YY-4;HH:=16;
     If WW<Length(C.Txt)*8 Then WW:=Length(C.Txt)*8;
    End;
   ckEdit : Begin
     Cls:=WC_ENTRYFIELD;St:=St Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN;
     YY:=YY-1;HH:=20;Lb:=C.Txt;
    End;
   ckCheck : Begin Cls:=WC_BUTTON;St:=St Or WS_TABSTOP Or BS_AUTOCHECKBOX;YY:=YY-1;HH:=16;End;
   ckRadio : Begin Cls:=WC_BUTTON;St:=St Or WS_TABSTOP Or BS_AUTORADIOBUTTON;YY:=YY-1;HH:=16;End;
   ckButton : Begin
     Cls:=WC_BUTTON;St:=St Or WS_TABSTOP Or BS_PUSHBUTTON;
     If C.Def Then St:=St Or BS_DEFAULT;
    End;
   ckCombo : Begin
     Cls:=WC_COMBOBOX;St:=St Or WS_TABSTOP Or CBS_DROPDOWNLIST;Lb:='';
     YY:=YY-2;HH:=22;
    End;
  End;
  If Cls<>0 Then Begin
   Sd^.H[I]:=WinCreateWindow(Sd^.Cl,Cls,OsZ(Lb),St,XX,CH-(YY+HH),WW,HH,Sd^.Cl,HWND_TOP,ID_SCTL+I,0,0);
   If C.Kind=ckEdit Then Dummy:=WinSendMsg(Sd^.H[I],EM_SETTEXTLIMIT,C.Max,0);
   If C.Kind In [ckLabel,ckCheck,ckRadio] Then Begin
    Clr:=CLR_PALEGRAY;
    Dummy:=WinSetPresParam(Sd^.H[I],4,4,LongInt(@Clr));
   End;
  End;
  { valeurs deja montrees (les autres sont poussees par SdPush) }
  Sd^.Txt[I]:=C.Txt;Sd^.Vis[I]:=True;Sd^.Ena[I]:=True;
  Sd^.On[I]:=False;Sd^.Sel[I]:=-1;Sd^.Cnt[I]:=-1;
 End;
 Sd^.Foc:=-1;
 SdRedraw;
End;

Procedure SdClose;
Var S: PSdState;
Begin
 S:=Sd;
 { fenetre secondaire precedente (ou fenetre principale) }
 CatFr:=S^.SFr;CatCl:=S^.SCl;CatX0:=S^.SX0;CatY0:=S^.SY0;
 CatW:=S^.SW;CatH:=S^.SH;CatNEx:=S^.SN;CatMode:=S^.SMode;
 Move(S^.SEx,CatEx,SizeOf(CatEx));
 PmTopFr:=S^.STop;
 MBtn:=0;MLatch:=0;
 Dummy:=WinSetCapture(HWND_DESKTOP,0);
 Dummy:=WinEnableWindow(PmTopFr,1);
 Dummy:=WinSetActiveWindow(HWND_DESKTOP,PmTopFr);
 If PmTopFr=OsFrame Then Dummy:=WinSetFocus(HWND_DESKTOP,OsClient)
 Else If CatCl<>0 Then Dummy:=WinSetFocus(HWND_DESKTOP,CatCl);
 Dummy:=WinDestroyWindow(S^.Fr);
 Sd:=S^.Prev;
 If Sd<>Nil Then If Sd^.Snap<>Nil Then Begin
  FreeMem(Sd^.Snap,FbW*FbH);
  Sd^.Snap:=Nil;
 End;
 Dispose(S);
 Dirty:=True;
End;

Function RunWin(P: PWin): Integer;
{ fenetre de PM (sdlg.inc) : controles de PM ; grilles, onglets, etats et
  graphiques dessines, avec la souris et le clavier de la version DOS }
Var E: TEvent; R: Integer;
Begin
 Inc(WSN);WS[WSN]:=P;
 Dragging:=False;
 Dispatch(P,evInit,0,0);
 FirstFocus(P);
 SdOpen(P);
 Repeat
  If Dirty Or DirtyTop Then SdRedraw;
  If Not P^.Done Then Begin
   PollEvent(E);
   Case E.Kind Of
    1: WinKey(P,E.Key);
    2: WinDown(P,E.X,E.Y,IsDouble(E.X,E.Y));
    3: WinUp(P,E.X,E.Y);
   End;
  End;
 Until P^.Done;
 SdClose;
 Dec(WSN);
 R:=P^.Res;
 Dispose(P);
 Dirty:=True;
 Dragging:=False;
 RunWin:=R;
End;

{ ---- boites de dialogue usuelles ---- }

Function MsgBox(Const Msg: String; Btn: Integer): Integer;
{ boite de message de PM ; '|' separe les lignes ; 1 OK ou Oui, 2 Non,
  3 Annuler }
Var T: String; I, R: Integer;
Begin
 T:=Msg;
 For I:=1 To Length(T) Do If T[I]='|' Then T[I]:=#10;
 Case Btn Of
  1: Begin Dummy:=PmBox('Sample Accounting',T,MB_OK Or MB_INFORMATION);R:=1;End;
  2: If PmBox('Sample Accounting',T,MB_YESNO Or MB_ICONQUESTION)=MBID_YES Then R:=1 Else R:=2;
  Else Begin
   I:=PmBox('Sample Accounting',T,3 Or MB_ICONQUESTION);
   If I=MBID_YES Then R:=1 Else If I=7 Then R:=2 Else R:=3;
  End;
 End;
 Dirty:=True;
 MsgBox:=R;
End;

Procedure Info(Const Msg: String);
Begin
 MsgBox(Msg,1);
End;

Function Ask(Const Msg: String): Boolean;
Begin
 Ask:=MsgBox(Msg,2)=1;
End;

Var
 InStr: String[60];

Function InputBox(Const Ti,Prompt: String; Var S: String; MaxL,
    Num: Integer): Boolean;
Var P: PWin;
Begin
 P:=NewWin(wkInput,Ti,360,118);
 P^.EnterOK:=True;
 AddLbl(P,0,12,10,Prompt);
 AddEdit(P,10,12,26,326,MaxL,Num,S);
 AddBtn(P,1,100,56,76,'OK',True);
 AddBtn(P,2,184,56,76,T3('Annuler','Cancel','Abbrechen'),False);
 InStr:=S;
 If RunWin(P)=1 Then Begin S:=InStr;InputBox:=True;End Else InputBox:=False;
End;

Function SelectList(Const Ti: String; Src,Cur: Integer): Integer;
Var P: PWin; N,I: Integer;
Begin
 N:=ListCount(Src);
 If N>MAXROW Then N:=MAXROW;
 If N=0 Then Begin
  Info(T3('La liste est vide.','The list is empty.','Die Liste ist leer.'));
  SelectList:=0;Exit;
 End;
 P:=NewWin(wkSelect,Ti,330,262);
 P^.EnterOK:=True;
 AddGrid(P,100,8,6,12,1,N);
 GridCol(P,288,2,T3('S@electionner','Select','Ausw@1hlen'),False);
 For I:=1 To N Do P^.GCell[I,1]:=ListText(Src,I);
 If (Cur>=1) And (Cur<=N) Then Begin P^.GRow:=Cur;ClampGrid(P);End;
 AddBtn(P,1,90,212,70,'OK',True);
 AddBtn(P,2,170,212,70,T3('Annuler','Cancel','Abbrechen'),False);
 SelectList:=RunWin(P);
End;

{ Selection d'un compte : retourne le numero ou 0 }
Function PickAccount: Integer;
Var N: Integer;
Begin
 N:=SelectList(SelTitle(srcAcct),srcAcct,1);
 If N>0 Then PickAccount:=Ac^[N].Num Else PickAccount:=0;
End;

{ ====================================================================== }
{              FORMULAIRES : COMPTES, TIERS, EMPLOYES, ARTICLES          }
{ ====================================================================== }

Var
 EditIdx : Integer;
 LastNew : Integer;

Procedure ShowReport(Const Ti: String); Forward;
Procedure PostPreview; Forward;

Function AccIdxOfCombo(P: PWin; Id: Integer): Integer;   { index dans Ac^ ou 0 }
Begin
 AccIdxOfCombo:=GS(P,Id);
End;

Procedure SetAcctCombo(P: PWin; Id,Num: Integer);
Begin
 SS(P,Id,FindAcc(Num));
End;

Function AcctComboNum(P: PWin; Id: Integer; Def: Integer): Integer;
Var S: Integer;
Begin
 S:=GS(P,Id);
 If (S>=1) And (S<=NA) Then AcctComboNum:=Ac^[S].Num Else AcctComboNum:=Def;
End;

Procedure SetBankCombo(P: PWin; Id,Num: Integer);
Var I,C: Integer;
Begin
 C:=0;
 For I:=1 To NA Do If Ac^[I].Bank Then Begin
  Inc(C);
  If Ac^[I].Num=Num Then Begin SS(P,Id,C);Exit;End;
 End;
 If C>0 Then SS(P,Id,1);
End;

Function BankComboNum(P: PWin; Id: Integer): Integer;
Var S,R: Integer;
Begin
 S:=GS(P,Id);
 R:=NthBank(S);
 If R>0 Then BankComboNum:=Ac^[R].Num Else BankComboNum:=0;
End;

{ ---- compte ---- }

Procedure UpdateAcctType(P: PWin);
Var K: Integer;
Begin
 K:=KindOfNum(ValInt(GT(P,10),0));
 If K=0 Then
   ST(P,12,T3('Type : (hors plage)','Type: (out of range)','Typ: (au@7erhalb)'))
 Else ST(P,12,T3('Type : ','Type: ','Typ: ')+KindName(K));
End;

Procedure HAcct(P: PWin; Ev,A,B: Integer);
Var N,I,K: Integer; S: String;
Begin
 Case Ev Of
  evInit: Begin
   If EditIdx>0 Then Begin
    ST(P,10,IntStr(Ac^[EditIdx].Num));ST(P,11,Ac^[EditIdx].Name);
    SV(P,13,Ac^[EditIdx].Bank);SEna(P,10,False);
   End;
   UpdateAcctType(P);
  End;
  evChange: If A=10 Then UpdateAcctType(P);
  evButton: Case A Of
   1: Begin
     N:=ValInt(GT(P,10),0);
     S:=TrimStr(GT(P,11));
     K:=KindOfNum(N);
     If (N<1) Or (N>9999) Then
       Info(T3('Num@ero de compte invalide.','Invalid account number.',
         'Ung@3ltige Kontonummer.'))
     Else If (EditIdx=0) And (FindAcc(N)>0) Then
      Info(T3('Ce num@ero de compte existe d@ej@a.',
          'This account number already exists.',
          'Diese Kontonummer existiert bereits.'))
     Else If K=0 Then
      Info(T3('Le num@ero est hors des plages d@efinies|dans la '+
          'num@erotation des comptes.',
          'The number is outside the ranges|defined in the account numbering.',
          'Die Nummer liegt au@7erhalb der|definierten Kontenbereiche.'))
     Else If S='' Then
       Info(T3('Le nom du compte est obligatoire.',
         'The account name is required.','Der Kontoname ist erforderlich.'))
     Else Begin
      If EditIdx=0 Then Begin
       I:=InsertAcc(N,S,K,GV(P,13));
       If I=0 Then
         Info(T3('Trop de comptes.','Too many accounts.','Zu viele Konten.'))
       Else Begin P^.Res:=1;P^.Done:=True;Modified:=True;LastNew:=N;End;
      End Else Begin
       Ac^[EditIdx].Name:=S;Ac^[EditIdx].Bank:=GV(P,13);
       P^.Res:=1;P^.Done:=True;Modified:=True;
      End;
     End;
    End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Function EditAccount(Idx: Integer): Boolean;
Var P: PWin;
Begin
 EditIdx:=Idx;
 P:=NewWin(wkAcct,T3('Compte','Account','Konto'),380,200);
 AddLbl(P,0,12,14,T3('Num@ero :','Number:','Nummer:'));
 AddEdit(P,10,100,10,80,4,3,'');
 AddLbl(P,0,12,40,T3('Nom :','Name:','Name:'));
 AddEdit(P,11,100,36,250,30,0,'');
 AddLblW(P,12,100,66,250,'',False,True);
 AddChk(P,13,100,86,T3('Compte bancaire','Bank account','Bankkonto'),False);
 AddBtn(P,1,100,120,80,'OK',True);
 AddBtn(P,2,190,120,80,T3('Annuler','Cancel','Abbrechen'),False);
 EditAccount:=RunWin(P)=1;
End;

{ ---- fournisseur / client ---- }

Procedure HParty(P: PWin; Ev,A,B: Integer);
Var PA: PPartyArr; S: String; N: Integer;
Begin
 If P^.Aux=1 Then PA:=Vn Else PA:=Cu;
 Case Ev Of
  evInit: Begin
   If EditIdx>0 Then Begin
    With PA^[EditIdx] Do Begin
     ST(P,10,Name);ST(P,11,Ad1);ST(P,12,Ad2);ST(P,13,Phone);ST(P,14,Contact);
     SetAcctCombo(P,15,Acc);SV(P,16,Tax);
     ST(P,17,IntStr(DPct));ST(P,18,IntStr(DDays));ST(P,19,IntStr(NDays));
     If P^.Aux=2 Then SMoney(P,20,Limit);
    End;
   End Else Begin
    If P^.Aux=1 Then SetAcctCombo(P,15,6200) Else SetAcctCombo(P,15,4100);
    SV(P,16,True);ST(P,17,'0');ST(P,18,'0');ST(P,19,'30');
    If P^.Aux=2 Then SMoney(P,20,0);
   End;
  End;
  evButton: Case A Of
   1: Begin
     S:=TrimStr(GT(P,10));
     If S='' Then
       Info(T3('Le nom est obligatoire.','The name is required.',
         'Der Name ist erforderlich.'))
     Else Begin
      If EditIdx=0 Then Begin
       If P^.Aux=1 Then Begin
        If NV>=MAXVEN Then Begin
          Info(T3('Trop de fournisseurs.','Too many vendors.',
            'Zu viele Lieferanten.'));Exit;End;
        Inc(NV);N:=NV;
       End Else Begin
        If NC_>=MAXCUS Then Begin
          Info(T3('Trop de clients.','Too many customers.','Zu viele Kunden.'));
          Exit;End;
        Inc(NC_);N:=NC_;
       End;
       FillChar(PA^[N],SizeOf(TParty),0);
      End Else N:=EditIdx;
      With PA^[N] Do Begin
       Name:=S;Ad1:=TrimStr(GT(P,11));Ad2:=TrimStr(GT(P,12));
       Phone:=TrimStr(GT(P,13));
       Contact:=TrimStr(GT(P,14));Acc:=AcctComboNum(P,15,0);Tax:=GV(P,16);
       DPct:=ValInt(GT(P,17),0);DDays:=ValInt(GT(P,18),0);
       NDays:=ValInt(GT(P,19),30);
       If DPct>100 Then DPct:=100;
       If P^.Aux=2 Then Limit:=GMoney(P,20);
      End;
      Modified:=True;P^.Res:=1;P^.Done:=True;
     End;
    End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Function EditParty(Side,Idx: Integer): Boolean;
Var P: PWin; Ti: String; Y,Ht: Integer;
Begin
 EditIdx:=Idx;
 If Side=1 Then Ti:=T3('Fournisseur','Vendor','Lieferant') Else
   Ti:=T3('Client','Customer','Kunde');
 If Side=1 Then Ht:=294 Else Ht:=322;
 P:=NewWin(wkParty,Ti,420,Ht);
 P^.Aux:=Side;
 AddLbl(P,0,12,14,T3('Nom :','Name:','Name:'));AddEdit(P,10,130,10,260,30,0,'');
 AddLbl(P,0,12,38,T3('Adresse :','Address:','Adresse:'));
 AddEdit(P,11,130,34,260,30,0,'');
 AddEdit(P,12,130,58,260,30,0,'');
 AddLbl(P,0,12,86,T3('T@el@ephone :','Phone:','Telefon:'));
 AddEdit(P,13,130,82,130,16,0,'');
 AddLbl(P,0,12,110,T3('Contact :','Contact:','Kontakt:'));
 AddEdit(P,14,130,106,260,24,0,'');
 If Side=1 Then
   AddLbl(P,0,12,134,T3('Compte de d@epense :','Expense account:',
     'Aufwandskonto:'))
 Else
   AddLbl(P,0,12,134,T3('Compte de revenus :','Revenue account:',
     'Ertragskonto:'));
 AddCombo(P,15,130,130,260,srcAcct);
 AddLbl(P,0,12,158,T3('Escompte (%) :','Discount (%):','Skonto (%):'));
 AddEdit(P,17,130,154,50,3,3,'');
 AddLbl(P,0,196,158,T3('si pay@e en','if paid in','bei Zahlung in'));
 AddEdit(P,18,300,154,40,3,3,'');
 AddLbl(P,0,346,158,T3('j.','days','Tg.'));
 AddLbl(P,0,12,182,T3('Net (jours) :','Net days:','Netto (Tage):'));
 AddEdit(P,19,130,178,50,3,3,'');
 Y:=206;
 If Side=2 Then Begin
  AddLbl(P,0,12,Y+4,T3('Limite de cr@edit :','Credit limit:','Kreditlimit:'));
  AddEdit(P,20,130,Y,110,12,1,'');
  Y:=Y+28;
 End;
 AddChk(P,16,130,Y+2,T3('Taxable (TPS)','Taxable (GST)',
     'Steuerpflichtig (USt)'),True);
 AddBtn(P,1,130,Y+30,80,'OK',True);
 AddBtn(P,2,220,Y+30,80,T3('Annuler','Cancel','Abbrechen'),False);
 EditParty:=RunWin(P)=1;
End;

{ ---- employe ---- }

Procedure HEmp(P: PWin; Ev,A,B: Integer);
Var S: String; N: Integer;
Begin
 Case Ev Of
  evInit: If EditIdx>0 Then Begin
    With Em^[EditIdx] Do Begin
     ST(P,10,Name);ST(P,11,Ad1);ST(P,12,Ad2);ST(P,13,SIN);
     SMoney(P,14,Rate);ST(P,15,FmtQty(Hrs));SMoney(P,16,Ytd);
    End;
   End Else Begin SMoney(P,14,0);ST(P,15,'80');End;
  evButton: Case A Of
   1: Begin
     S:=TrimStr(GT(P,10));
     If S='' Then
       Info(T3('Le nom est obligatoire.','The name is required.',
         'Der Name ist erforderlich.'))
     Else Begin
      If EditIdx=0 Then Begin
       If NE>=MAXEMP Then Begin
         Info(T3('Trop d''employ@es.','Too many employees.',
           'Zu viele Mitarbeiter.'));Exit;End;
       Inc(NE);N:=NE;FillChar(Em^[N],SizeOf(TEmp),0);
      End Else N:=EditIdx;
      With Em^[N] Do Begin
       Name:=S;Ad1:=TrimStr(GT(P,11));Ad2:=TrimStr(GT(P,12));
       SIN:=TrimStr(GT(P,13));
       Rate:=GMoney(P,14);Hrs:=ParseMoney(GT(P,15));
      End;
      Modified:=True;P^.Res:=1;P^.Done:=True;
     End;
    End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Function EditEmp(Idx: Integer): Boolean;
Var P: PWin;
Begin
 EditIdx:=Idx;
 P:=NewWin(wkEmp,T3('Employ@e','Employee','Mitarbeiter'),410,246);
 AddLbl(P,0,12,14,T3('Nom :','Name:','Name:'));AddEdit(P,10,130,10,250,30,0,'');
 AddLbl(P,0,12,38,T3('Adresse :','Address:','Adresse:'));
 AddEdit(P,11,130,34,250,30,0,'');
 AddEdit(P,12,130,58,250,30,0,'');
 AddLbl(P,0,12,86,T3('N.A.S. :','SIN:','Sozialvers.-Nr.:'));
 AddEdit(P,13,130,82,120,11,0,'');
 AddLbl(P,0,12,110,T3('Taux horaire :','Hourly rate:','Stundensatz:'));
 AddEdit(P,14,130,106,100,12,1,'');
 AddLbl(P,0,12,134,T3('Heures / p@eriode :','Hours / period:',
     'Std. / Periode:'));AddEdit(P,15,130,130,100,8,5,'');
 AddLbl(P,0,12,158,T3('Cumul annuel :','Year to date:','Jahressumme:'));
 AddEdit(P,16,130,154,100,12,1,'');
 SEna(P,16,False);
 AddBtn(P,1,130,184,80,'OK',True);
 AddBtn(P,2,220,184,80,T3('Annuler','Cancel','Abbrechen'),False);
 EditEmp:=RunWin(P)=1;
End;

{ ---- article d'inventaire ---- }

Procedure ItemEna(P: PWin);
Var Svc: Boolean;
Begin
 Svc:=GV(P,16);
 SEna(P,17,Not Svc);SEna(P,18,Not Svc);SEna(P,20,Not Svc);
 If (EditIdx>0) Then SEna(P,17,False);
End;

Procedure HItem(P: PWin; Ev,A,B: Integer);
Var S: String; N: Integer;
Begin
 Case Ev Of
  evInit: Begin
   If EditIdx>0 Then Begin
    With It^[EditIdx] Do Begin
     ST(P,10,Code);ST(P,11,Desc);ST(P,12,Unit_);SMoney(P,13,Price);
     SMoney(P,14,Cost);
     ST(P,17,FmtQty(Qty));SV(P,16,Svc);
     SetAcctCombo(P,18,AAcc);SetAcctCombo(P,19,RAcc);SetAcctCombo(P,20,CAcc);
    End;
    SEna(P,10,False);
   End Else Begin
    SMoney(P,13,0);SMoney(P,14,0);ST(P,17,'0');
    SetAcctCombo(P,18,1300);SetAcctCombo(P,19,4100);SetAcctCombo(P,20,5000);
   End;
   ItemEna(P);
  End;
  evChange: If A=16 Then ItemEna(P);
  evButton: Case A Of
   1: Begin
     S:=TrimStr(GT(P,10));
     If S='' Then
       Info(T3('Le code est obligatoire.','The item code is required.',
         'Der Artikelcode ist erforderlich.'))
     Else If (EditIdx=0) And (FindItem(S)>0) Then
      Info(T3('Ce code d''article existe d@ej@a.',
          'This item code already exists.',
          'Dieser Artikelcode existiert bereits.'))
     Else Begin
      If EditIdx=0 Then Begin
       If NI>=MAXITM Then Begin
         Info(T3('Trop d''articles.','Too many items.','Zu viele Artikel.'));
         Exit;End;
       Inc(NI);N:=NI;FillChar(It^[N],SizeOf(TItem),0);
       It^[N].Code:=S;It^[N].Qty:=ParseMoney(GT(P,17));
      End Else N:=EditIdx;
      With It^[N] Do Begin
       Desc:=TrimStr(GT(P,11));Unit_:=TrimStr(GT(P,12));Price:=GMoney(P,13);
       Cost:=GMoney(P,14);
       Svc:=GV(P,16);
       AAcc:=AcctComboNum(P,18,1300);RAcc:=AcctComboNum(P,19,4100);
       CAcc:=AcctComboNum(P,20,5000);
       If Svc Then Qty:=0;
      End;
      Modified:=True;P^.Res:=1;P^.Done:=True;
     End;
    End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Function EditItem(Idx: Integer): Boolean;
Var P: PWin;
Begin
 EditIdx:=Idx;
 P:=NewWin(wkItem,T3('Article / Service','Item / Service','Artikel / Dienst'),
     430,330);
 AddLbl(P,0,12,14,T3('Code :','Code:','Code:'));
 AddEdit(P,10,150,10,100,10,0,'');
 AddLbl(P,0,12,38,T3('Description :','Description:','Beschreibung:'));
 AddEdit(P,11,150,34,260,30,0,'');
 AddLbl(P,0,12,62,T3('Unit@e :','Unit:','Einheit:'));
 AddEdit(P,12,150,58,60,6,0,'');
 AddLbl(P,0,12,86,T3('Prix de vente :','Selling price:','Verkaufspreis:'));
 AddEdit(P,13,150,82,110,12,1,'');
 AddLbl(P,0,12,110,T3('Co@ut unitaire :','Unit cost:','St@3ckkosten:'));
 AddEdit(P,14,150,106,110,12,1,'');
 AddChk(P,16,150,132,T3('Service (non inventori@e)','Service (not stocked)',
     'Dienstleistung (ohne Lager)'),False);
 AddLbl(P,0,12,158,T3('Quantit@e en stock :','Quantity on hand:',
     'Lagerbestand:'));AddEdit(P,17,150,154,100,10,5,'');
 AddLbl(P,0,12,182,T3('Compte d''actif :','Asset account:','Bestandskonto:'));
 AddCombo(P,18,150,178,260,srcAcct);
 AddLbl(P,0,12,206,T3('Compte de revenus :','Revenue account:',
     'Ertragskonto:'));AddCombo(P,19,150,202,260,srcAcct);
 AddLbl(P,0,12,230,T3('Compte de co@ut :','COGS account:',
     'Wareneinsatzkonto:'));AddCombo(P,20,150,226,260,srcAcct);
 AddBtn(P,1,150,262,80,'OK',True);
 AddBtn(P,2,240,262,80,T3('Annuler','Cancel','Abbrechen'),False);
 EditItem:=RunWin(P)=1;
End;

{ ---- projet ---- }

Procedure HPrj(P: PWin; Ev,A,B: Integer);
Var S: String; N: Integer;
Begin
 Case Ev Of
  evInit: If EditIdx>0 Then Begin
    ST(P,10,Pj^[EditIdx].Name);SMoney(P,11,Pj^[EditIdx].Budget);
   End Else SMoney(P,11,0);
  evButton: Case A Of
   1: Begin
     S:=TrimStr(GT(P,10));
     If S='' Then
       Info(T3('Le nom est obligatoire.','The name is required.',
         'Der Name ist erforderlich.'))
     Else Begin
      If EditIdx=0 Then Begin
       If NP>=MAXPRJ Then Begin
         Info(T3('Trop de projets.','Too many projects.','Zu viele Projekte.'));
         Exit;End;
       Inc(NP);N:=NP;
      End Else N:=EditIdx;
      Pj^[N].Name:=S;Pj^[N].Budget:=GMoney(P,11);
      Modified:=True;P^.Res:=1;P^.Done:=True;
     End;
    End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Function EditPrj(Idx: Integer): Boolean;
Var P: PWin;
Begin
 EditIdx:=Idx;
 P:=NewWin(wkPrj,T3('Projet','Project','Projekt'),380,150);
 AddLbl(P,0,12,14,T3('Nom :','Name:','Name:'));AddEdit(P,10,100,10,250,30,0,'');
 AddLbl(P,0,12,38,T3('Budget :','Budget:','Budget:'));
 AddEdit(P,11,100,34,110,12,1,'');
 AddBtn(P,1,100,68,80,'OK',True);
 AddBtn(P,2,190,68,80,T3('Annuler','Cancel','Abbrechen'),False);
 EditPrj:=RunWin(P)=1;
End;

{ ====================================================================== }
{                     LISTES D'ENREGISTREMENTS                           }
{ ====================================================================== }

Function ListCountE(E: Integer): Integer;
Begin
 Case E Of
  1: ListCountE:=NA;
  2: ListCountE:=NV;
  3: ListCountE:=NC_;
  4: ListCountE:=NE;
  5: ListCountE:=NI;
  6: ListCountE:=NP;
  Else ListCountE:=0;
 End;
End;

Procedure FillList(P: PWin; Keep: Integer);
Var E,I,N: Integer;
Begin
 E:=P^.Aux;
 N:=ListCountE(E);
 If N>MAXROW Then N:=MAXROW;
 GridClear(P,N);
 For I:=1 To N Do Begin
  Case E Of
   1: Begin
     P^.GCell[I,1]:=IntStr(Ac^[I].Num);P^.GCell[I,2]:=Ac^[I].Name;
     P^.GCell[I,3]:=KindName(Ac^[I].Kind);P^.GCell[I,4]:=FmtMoney(DispBal(I));
    End;
   2: Begin
     P^.GCell[I,1]:=Vn^[I].Name;P^.GCell[I,2]:=Vn^[I].Phone;
     P^.GCell[I,3]:=FmtMoney(PartyBal(1,I));
    End;
   3: Begin
     P^.GCell[I,1]:=Cu^[I].Name;P^.GCell[I,2]:=Cu^[I].Phone;
     P^.GCell[I,3]:=FmtMoney(PartyBal(2,I));
    End;
   4: Begin
     P^.GCell[I,1]:=Em^[I].Name;P^.GCell[I,2]:=FmtMoney(Em^[I].Rate);
     P^.GCell[I,3]:=FmtMoney(Em^[I].Ytd);
    End;
   5: Begin
     P^.GCell[I,1]:=It^[I].Code;P^.GCell[I,2]:=It^[I].Desc;
     If It^[I].Svc Then P^.GCell[I,3]:='-' Else
       P^.GCell[I,3]:=FmtQty(It^[I].Qty);
     P^.GCell[I,4]:=FmtMoney(It^[I].Price);
    End;
   6: Begin
     P^.GCell[I,1]:=Pj^[I].Name;P^.GCell[I,2]:=FmtMoney(Pj^[I].Budget);
    End;
  End;
 End;
 If Keep>0 Then Begin P^.GRow:=Keep;ClampGrid(P);End;
End;

Function EditRec(E,Idx: Integer): Boolean;
Begin
 Case E Of
  1: EditRec:=EditAccount(Idx);
  2: EditRec:=EditParty(1,Idx);
  3: EditRec:=EditParty(2,Idx);
  4: EditRec:=EditEmp(Idx);
  5: EditRec:=EditItem(Idx);
  6: EditRec:=EditPrj(Idx);
  Else EditRec:=False;
 End;
End;

Function IsLinked(Num: Integer): Boolean;
Var L: Integer;
Begin
 IsLinked:=False;
 For L:=1 To NLINK Do If SU.Link[L]=Num Then IsLinked:=True;
End;

Procedure DeleteRec(E,Idx: Integer);
Var I,J: Integer;
Begin
 Case E Of
  1: Begin
    For J:=1 To NJ Do If Jl^[J].Acc=Ac^[Idx].Num Then Begin
     Info(T3('Ce compte contient des transactions.|Il ne peut pas @etre '+
         'supprim@e.','This account has transactions.|It cannot be deleted.',
         'Dieses Konto hat Buchungen.|Es kann nicht gel@2scht werden.'));
     Exit;
    End;
    If IsLinked(Ac^[Idx].Num) Then Begin
     Info(T3('Ce compte est un compte d''int@egration.',
         'This is a linked account.','Dies ist ein Integrationskonto.'));Exit;
    End;
    For I:=Idx To NA-1 Do Ac^[I]:=Ac^[I+1];
    Dec(NA);
   End;
  2,3: Begin
    For J:=1 To NIv Do If (Iv^[J].Typ=E-1) And (Iv^[J].Party=Idx) Then Begin
     Info(T3('Ce tiers a des factures.|Il ne peut pas @etre supprim@e.',
         'This record has invoices.|It cannot be deleted.',
         'Dieser Eintrag hat Rechnungen.|Er kann nicht gel@2scht werden.'));
     Exit;
    End;
    If E=2 Then Begin For I:=Idx To NV-1 Do Vn^[I]:=Vn^[I+1];Dec(NV);End
    Else Begin For I:=Idx To NC_-1 Do Cu^[I]:=Cu^[I+1];Dec(NC_);End;
    For J:=1 To NIv Do
     If (Iv^[J].Typ=E-1) And (Iv^[J].Party>Idx) Then Dec(Iv^[J].Party);
   End;
  4: Begin For I:=Idx To NE-1 Do Em^[I]:=Em^[I+1];Dec(NE);End;
  5: Begin For I:=Idx To NI-1 Do It^[I]:=It^[I+1];Dec(NI);End;
  6: Begin For I:=Idx To NP-1 Do Pj^[I]:=Pj^[I+1];Dec(NP);End;
 End;
 Modified:=True;
End;

Procedure HList(P: PWin; Ev,A,B: Integer);
Var E,Idx,N: Integer;
Begin
 E:=P^.Aux;
 Case Ev Of
  evInit: FillList(P,0);
  evDbl: If P^.GN>0 Then Begin
    If EditRec(E,P^.GRow) Then FillList(P,P^.GRow);
    Dirty:=True;
   End;
  evButton: Case A Of
   11: Begin
     If EditRec(E,0) Then Begin
      If E=1 Then FillList(P,FindAcc(LastNew)) Else FillList(P,ListCountE(E));
     End;
     Dirty:=True;
    End;
   12: If P^.GN>0 Then Begin
     If EditRec(E,P^.GRow) Then FillList(P,P^.GRow);
     Dirty:=True;
    End;
   13: If P^.GN>0 Then Begin
     Idx:=P^.GRow;
     If Ask(T3('Supprimer cet enregistrement ?','Delete this record?',
         'Diesen Eintrag l@2schen?')) Then Begin
      DeleteRec(E,Idx);
      N:=Idx;If N>ListCountE(E) Then N:=ListCountE(E);
      FillList(P,N);
     End;
     Dirty:=True;
    End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Procedure OpenList(E: Integer);
Var P: PWin; Ti: String;
Begin
 Case E Of
  1: Ti:=T3('Comptes','Accounts','Konten');
  2: Ti:=T3('Fournisseurs','Vendors','Lieferanten');
  3: Ti:=T3('Clients','Customers','Kunden');
  4: Ti:=T3('Employ@es','Employees','Mitarbeiter');
  5: Ti:=T3('Inventaire et services','Inventory & Services',
      'Lager und Dienste');
  6: Ti:=T3('Projets','Projects','Projekte');
 End;
 P:=NewWin(wkList,Ti,500,270);
 P^.Aux:=E;
 AddGrid(P,100,8,6,12,1,0);
 Case E Of
  1: Begin
    GridCol(P,56,3,T3('Compte','Account','Konto'),False);
    GridCol(P,200,2,T3('Nom','Name','Name'),False);
    GridCol(P,100,2,T3('Type','Type','Typ'),False);
    GridCol(P,104,3,T3('Solde','Balance','Saldo'),False);
   End;
  2,3: Begin
    GridCol(P,200,2,T3('Nom','Name','Name'),False);
    GridCol(P,130,2,T3('T@el@ephone','Phone','Telefon'),False);
    GridCol(P,126,3,T3('Solde','Balance','Saldo'),False);
   End;
  4: Begin
    GridCol(P,200,2,T3('Nom','Name','Name'),False);
    GridCol(P,120,3,T3('Taux horaire','Hourly rate','Stundensatz'),False);
    GridCol(P,136,3,T3('Cumul annuel','Year to date','Jahressumme'),False);
   End;
  5: Begin
    GridCol(P,80,2,T3('Code','Code','Code'),False);
    GridCol(P,200,2,T3('Description','Description','Beschreibung'),False);
    GridCol(P,70,3,T3('Qt@e','Qty','Menge'),False);
    GridCol(P,106,3,T3('Prix','Price','Preis'),False);
   End;
  6: Begin
    GridCol(P,260,2,T3('Nom','Name','Name'),False);
    GridCol(P,196,3,'Budget',False);
   End;
 End;
 AddBtn(P,11,8,208,90,T3('Nouveau','New','Neu'),False);
 AddBtn(P,12,106,208,90,T3('Modifier','Modify','@4ndern'),True);
 AddBtn(P,13,204,208,90,T3('Supprimer','Delete','L@2schen'),False);
 AddBtn(P,2,392,208,90,T3('Fermer','Close','Schlie@7en'),False);
 RunWin(P);
End;

{ ====================================================================== }
{                 JOURNAL GENERAL (transactions diverses)                }
{ ====================================================================== }

Procedure JournalTotals(P: PWin);
Var R: Integer; D,C: LongInt;
Begin
 D:=0;C:=0;
 For R:=1 To P^.GN Do Begin
  D:=D+ParseMoney(P^.GCell[R,3]);C:=C+ParseMoney(P^.GCell[R,4]);
 End;
 ST(P,20,FmtMoney(D));ST(P,21,FmtMoney(C));ST(P,22,FmtMoney(D-C));
End;

Procedure JournalReset(P: PWin);
Begin
 GridClear(P,24);
 ST(P,10,'J'+IntStr(SU.NextJ+1));
 ST(P,12,'');
 JournalTotals(P);
End;

Procedure HJournal(P: PWin; Ev,A,B: Integer);
Var N,I,R: Integer; V,D: LongInt; Dt: LongInt; Cnt: Integer;
Begin
 Case Ev Of
  evInit: Begin
    SDate(P,11,SessDate);
    JournalReset(P);
   End;
  evCell: Begin
    Case B Of
     1: Begin
       N:=ValInt(P^.GCell[A,1],0);I:=FindAcc(N);
       If (N<>0) And (I=0) Then Begin
        Info(T3('Ce compte n''existe pas.','This account does not exist.',
            'Dieses Konto existiert nicht.'));
        P^.GCell[A,1]:='';P^.GCell[A,2]:='';
       End Else If I>0 Then Begin
         P^.GCell[A,1]:=IntStr(N);P^.GCell[A,2]:=Ac^[I].Name;End
       Else P^.GCell[A,2]:='';
      End;
     3: Begin
       If TrimStr(P^.GCell[A,3])<>'' Then Begin
        V:=ParseMoney(P^.GCell[A,3]);
        If V=0 Then P^.GCell[A,3]:='' Else Begin
          P^.GCell[A,3]:=FmtMoney(V);P^.GCell[A,4]:='';End;
       End;
      End;
     4: Begin
       If TrimStr(P^.GCell[A,4])<>'' Then Begin
        V:=ParseMoney(P^.GCell[A,4]);
        If V=0 Then P^.GCell[A,4]:='' Else Begin
          P^.GCell[A,4]:=FmtMoney(V);P^.GCell[A,3]:='';End;
       End;
      End;
    End;
    JournalTotals(P);
   End;
  evLookup: If B=1 Then Begin
    N:=PickAccount;
    If N>0 Then Begin P^.GCell[A,1]:=IntStr(N);P^.GCell[A,2]:=AccName(N);End;
    JournalTotals(P);
   End;
  evButton: Case A Of
   31: Begin
     If Not ParseDate(GT(P,11),Dt) Then Begin
      Info(T3('Date invalide.','Invalid date.','Ung@3ltiges Datum.'));Exit;
     End;
     PClear;Cnt:=0;
     For R:=1 To P^.GN Do Begin
      D:=ParseMoney(P^.GCell[R,3]);V:=ParseMoney(P^.GCell[R,4]);
      If (D<>0) Or (V<>0) Then Begin
       N:=ValInt(P^.GCell[R,1],0);
       If FindAcc(N)=0 Then Begin
        Info(T3('Compte manquant @a la ligne ','Missing account on line ',
            'Konto fehlt in Zeile ')+IntStr(R));Exit;
       End;
       PAdd(N,D,V);Inc(Cnt);
      End;
     End;
     If Cnt<2 Then Begin
      Info(T3('Une @ecriture requiert au moins deux lignes.',
          'An entry needs at least two lines.',
          'Eine Buchung braucht mindestens zwei Zeilen.'));Exit;
     End;
     If PSumDr<>PSumCr Then Begin
      Info(T3('L''@ecriture n''est pas @equilibr@ee.|Diff@erence : ',
          'The entry is out of balance.|Difference: ',
          'Die Buchung ist nicht ausgeglichen.|Differenz: ')+FmtMoney(PSumDr-
          PSumCr));
      Exit;
     End;
     If Commit(Dt,TrimStr(GT(P,10)),TrimStr(GT(P,12))) Then Begin
      Info(T3('@Ecriture no ','Entry no. ',
          'Buchung Nr. ')+IntStr(SU.NextJ)+T3(' enregistr@ee.',' recorded.',
          ' gebucht.'));
      JournalReset(P);
     End Else Info(ErrMsg);
    End;
   32: Begin JournalReset(P);End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Procedure OpenJournal;
Var P: PWin;
Begin
 P:=NewWin(wkJournal,T3('Transactions diverses (Journal g@en@eral)',
     'Miscellaneous Transactions (General Journal)',
     'Sonstige Buchungen (Hauptjournal)'),584,330);
 AddLbl(P,0,8,12,'Source');AddEdit(P,10,70,8,110,12,0,'');
 AddLbl(P,0,200,12,'Date');AddEdit(P,11,240,8,100,12,2,'');
 AddLbl(P,0,8,38,T3('Commentaire','Comment','Kommentar'));
 AddEdit(P,12,100,34,200,20,0,'');
 AddGrid(P,100,8,62,10,0,24);
 GridCol(P,70,0,T3('Compte','Account','Konto'),True);
 GridCol(P,250,2,T3('Nom du compte','Account name','Kontoname'),False);
 GridCol(P,110,1,T3('D@ebit','Debit','Soll'),False);
 GridCol(P,110,1,T3('Cr@edit','Credit','Haben'),False);
 AddLbl(P,0,300,230,T3('Totaux :','Totals:','Summen:'));
 AddLblW(P,20,330,230,108,'',True,True);AddLblW(P,21,440,230,108,'',True,True);
 AddLbl(P,0,300,246,T3('Diff@erence :','Difference:','Differenz:'));
 AddLblW(P,22,330,246,108,'',True,True);
 AddBtn(P,31,8,272,110,T3('Enregistrer','Post','Buchen'),True);
 AddBtn(P,32,126,272,110,T3('Effacer','Clear','L@2schen'),False);
 AddBtn(P,2,438,272,110,T3('Fermer','Close','Schlie@7en'),False);
 RunWin(P);
End;

{ ====================================================================== }
{                  ACHATS / VENTES (journal de factures)                 }
{ ====================================================================== }

Var
 SaN: Integer;
 SaItem: Array[1..MAXROW] Of Integer;
 SaQ,SaAmt: Array[1..MAXROW] Of LongInt;

Procedure PrintInv(P: PWin); Forward;

Procedure InvRecalc(P: PWin);
Var R: Integer; Sub,Frt,Tax: LongInt; Pt: Integer; PA: PPartyArr;
Begin
 Sub:=0;
 For R:=1 To P^.GN Do Sub:=Sub+ParseMoney(P^.GCell[R,6]);
 Frt:=GMoney(P,20);
 Tax:=0;
 Pt:=GS(P,10);
 If P^.Aux=1 Then PA:=Vn Else PA:=Cu;
 If (Pt>=1) And (Pt<=ListCount(srcVend+P^.Aux-1)) Then
  If PA^[Pt].Tax Then Tax:=PctOf(Sub+Frt,SU.Gst);
 ST(P,21,FmtMoney(Sub));ST(P,22,FmtMoney(Tax));ST(P,23,FmtMoney(Sub+Frt+Tax));
End;

Procedure InvRowCalc(P: PWin; R: Integer);
Begin
 If (TrimStr(P^.GCell[R,2])<>'') And (TrimStr(P^.GCell[R,5])<>'') Then
  P^.GCell[R,6]:=FmtMoney(MulQ(ParseMoney(P^.GCell[R,2]),ParseMoney(P^.GCell[R,
      5])));
End;

Procedure InvFillItem(P: PWin; R,It_: Integer);
Begin
 With It^[It_] Do Begin
  P^.GCell[R,1]:=Code;P^.GCell[R,3]:=Unit_;P^.GCell[R,4]:=Desc;
  If TrimStr(P^.GCell[R,2])='' Then P^.GCell[R,2]:='1';
  P^.GCell[R,2]:=FmtQty(ParseMoney(P^.GCell[R,2]));
  If P^.Aux=1 Then Begin
   P^.GCell[R,5]:=FmtMoney(Cost);
   If Svc Then P^.GCell[R,7]:=IntStr(CAcc) Else P^.GCell[R,7]:=IntStr(AAcc);
  End Else Begin
   P^.GCell[R,5]:=FmtMoney(Price);P^.GCell[R,7]:=IntStr(RAcc);
  End;
 End;
 InvRowCalc(P,R);
End;

Procedure InvAddress(P: PWin);
Var Pt: Integer; PA: PPartyArr;
Begin
 If P^.Aux=1 Then PA:=Vn Else PA:=Cu;
 Pt:=GS(P,10);
 If (Pt>=1) And (Pt<=ListCount(srcVend+P^.Aux-1)) Then Begin
  ST(P,14,PA^[Pt].Name);ST(P,15,PA^[Pt].Ad1);ST(P,16,PA^[Pt].Ad2);
 End Else Begin ST(P,14,'');ST(P,15,'');ST(P,16,'');End;
End;

Procedure InvReset(P: PWin);
Begin
 GridClear(P,40);
 SS(P,10,0);InvAddress(P);
 SV(P,11,False);SEna(P,17,False);
 ST(P,20,FmtMoney(0));
 If P^.Aux=2 Then ST(P,12,IntStr(SU.NextInv)) Else ST(P,12,'');
 InvRecalc(P);
End;

Function BuildInv(P: PWin; Var D,Total: LongInt; Var Party: Integer): Boolean;
Var R,Acc,It_,Bk: Integer; Amt,Sub,Frt,Tax,Q,Cst: LongInt; PA: PPartyArr;
Typ: Integer;
Begin
 BuildInv:=False;
 ErrMsg:='';
 Typ:=P^.Aux;
 Party:=GS(P,10);
 If Typ=1 Then PA:=Vn Else PA:=Cu;
 If (Party<1) Or (Party>ListCount(srcVend+Typ-1)) Then Begin
  If Typ=1 Then
    ErrMsg:=T3('Choisissez un fournisseur.','Select a vendor.',
      'W@1hlen Sie einen Lieferanten.')
  Else
    ErrMsg:=T3('Choisissez un client.','Select a customer.',
      'W@1hlen Sie einen Kunden.');
  Exit;
 End;
 If Not ParseDate(GT(P,13),D) Then Begin
   ErrMsg:=T3('Date invalide.','Invalid date.','Ung@3ltiges Datum.');Exit;End;
 If TrimStr(GT(P,12))='' Then Begin
  ErrMsg:=T3('Le num@ero de facture est obligatoire.',
      'The invoice number is required.',
      'Die Rechnungsnummer ist erforderlich.');Exit;
 End;
 PClear;SaN:=0;Sub:=0;
 For R:=1 To P^.GN Do Begin
  Amt:=ParseMoney(P^.GCell[R,6]);
  If Amt<>0 Then Begin
   Acc:=ValInt(P^.GCell[R,7],0);
   If Acc=0 Then Acc:=PA^[Party].Acc;
   If FindAcc(Acc)=0 Then Begin
    ErrMsg:=T3('Compte invalide @a la ligne ','Invalid account on line ',
        'Ung@3ltiges Konto in Zeile ')+IntStr(R);Exit;
   End;
   Sub:=Sub+Amt;
   If Typ=1 Then PDr(Acc,Amt) Else PCr(Acc,Amt);
   It_:=FindItem(P^.GCell[R,1]);
   If (It_>0) And (Not It^[It_].Svc) Then Begin
    Q:=ParseMoney(P^.GCell[R,2]);
    If Typ=1 Then Begin
     Inc(SaN);SaItem[SaN]:=It_;SaQ[SaN]:=Q;SaAmt[SaN]:=Amt;
    End Else Begin
     If It^[It_].Qty<Q Then Begin
      ErrMsg:=T3('Stock insuffisant : ','Insufficient stock: ',
          'Lagerbestand unzureichend: ')+It^[It_].Code;Exit;
     End;
     Cst:=MulQ(Q,It^[It_].Cost);
     PDr(It^[It_].CAcc,Cst);PCr(It^[It_].AAcc,Cst);
     Inc(SaN);SaItem[SaN]:=It_;SaQ[SaN]:=-Q;SaAmt[SaN]:=Cst;
    End;
   End;
  End;
 End;
 If Sub=0 Then Begin
  ErrMsg:=T3('La facture ne contient aucune ligne.','The invoice has no lines.',
      'Die Rechnung hat keine Zeilen.');Exit;
 End;
 Frt:=GMoney(P,20);
 Tax:=0;
 If PA^[Party].Tax Then Tax:=PctOf(Sub+Frt,SU.Gst);
 Total:=Sub+Frt+Tax;
 If Typ=1 Then Begin
  PDr(LinkAcc(LK_FRTEXP),Frt);PDr(LinkAcc(LK_GSTPD),Tax);
 End Else Begin
  PCr(LinkAcc(LK_FRTREV),Frt);PCr(LinkAcc(LK_GSTCL),Tax);
 End;
 If GV(P,11) Then Begin
  Bk:=BankComboNum(P,17);
  If Bk=0 Then Begin
    ErrMsg:=T3('Choisissez un compte bancaire.','Select a bank account.',
      'W@1hlen Sie ein Bankkonto.');Exit;End;
  If Typ=1 Then PCr(Bk,Total) Else PDr(Bk,Total);
 End Else Begin
  If Typ=1 Then PCr(LinkAcc(LK_AP),Total) Else PDr(LinkAcc(LK_AR),Total);
 End;
 BuildInv:=True;
End;

Procedure ApplyStock;
Var I: Integer; V: Real; NQ: LongInt;
Begin
 For I:=1 To SaN Do Begin
  With It^[SaItem[I]] Do Begin
   If SaQ[I]>0 Then Begin
    NQ:=Qty+SaQ[I];
    If NQ>0 Then Begin
     V:=Qty;V:=V/100.0*Cost+SaAmt[I];
     Cost:=Round(V/(NQ/100.0));
    End;
    Qty:=NQ;
   End Else Qty:=Qty+SaQ[I];
  End;
 End;
 SaN:=0;
End;

Function InvExists(Typ,Party: Integer; Const No: String): Boolean;
Var I: Integer;
Begin
 InvExists:=False;
 For I:=1 To NIv Do
  If (Iv^[I].Typ=Typ) And (Iv^[I].Party=Party)
      And (Upper(Iv^[I].No)=Upper(No)) Then InvExists:=True;
End;

Procedure HInvoice(P: PWin; Ev,A,B: Integer);
Var N,I,Pt: Integer; D,Tot: LongInt; S: String;
Begin
 Case Ev Of
  evInit: Begin
    SDate(P,13,SessDate);
    If BankCount>0 Then SetBankCombo(P,17,LinkAcc(LK_BANK));
    InvReset(P);
   End;
  evChange: Begin
    If A=10 Then Begin InvAddress(P);InvRecalc(P);End;
    If A=11 Then SEna(P,17,GV(P,11));
    If A=20 Then InvRecalc(P);
   End;
  evCell: Begin
    Case B Of
     1: Begin
       S:=TrimStr(P^.GCell[A,1]);
       If S<>'' Then Begin I:=FindItem(S);If I>0 Then InvFillItem(P,A,I);End;
      End;
     2: Begin
       If TrimStr(P^.GCell[A,2])<>'' Then
         P^.GCell[A,2]:=FmtQty(ParseMoney(P^.GCell[A,2]));
       InvRowCalc(P,A);
      End;
     5: Begin
       If TrimStr(P^.GCell[A,5])<>'' Then
         P^.GCell[A,5]:=FmtMoney(ParseMoney(P^.GCell[A,5]));
       InvRowCalc(P,A);
      End;
     6: If TrimStr(P^.GCell[A,6])<>'' Then Begin
       D:=ParseMoney(P^.GCell[A,6]);
       If D=0 Then P^.GCell[A,6]:='' Else P^.GCell[A,6]:=FmtMoney(D);
      End;
     7: Begin
       N:=ValInt(P^.GCell[A,7],0);
       If (N<>0) And (FindAcc(N)=0) Then Begin
        Info(T3('Ce compte n''existe pas.','This account does not exist.',
            'Dieses Konto existiert nicht.'));
        P^.GCell[A,7]:='';
       End;
      End;
    End;
    InvRecalc(P);
   End;
  evLookup: Begin
    If B=1 Then Begin
     N:=SelectList(SelTitle(srcItem),srcItem,1);
     If N>0 Then InvFillItem(P,A,N);
    End Else If B=7 Then Begin
     N:=PickAccount;
     If N>0 Then P^.GCell[A,7]:=IntStr(N);
    End;
    InvRecalc(P);
   End;
  evButton: Case A Of
   31: Begin
     If BuildInv(P,D,Tot,Pt) Then PostPreview Else Info(ErrMsg);
    End;
   32: Begin
     If Not BuildInv(P,D,Tot,Pt) Then Begin Info(ErrMsg);Exit;End;
     S:=TrimStr(GT(P,12));
     If (Not GV(P,11)) And InvExists(P^.Aux,Pt,S) Then Begin
      Info(T3('Ce num@ero de facture existe d@ej@a.',
          'This invoice number already exists.',
          'Diese Rechnungsnummer existiert bereits.'));Exit;
     End;
     If Commit(D,S,ListText(srcVend+P^.Aux-1,Pt)) Then Begin
      If Not GV(P,11) Then AddInv(P^.Aux,Pt,S,D,Tot);
      ApplyStock;
      If (P^.Aux=2) And (S=IntStr(SU.NextInv)) Then Inc(SU.NextInv);
      Info(T3('Facture enregistr@ee. Total : ','Invoice recorded. Total: ',
          'Rechnung gebucht. Summe: ')+FmtMoney(Tot));
      InvReset(P);
     End Else Info(ErrMsg);
    End;
   33: If P^.Aux=2 Then PrintInv(P);
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Procedure OpenInvoice(Typ: Integer);
Var P: PWin; Ti: String;
Begin
 If Typ=1 Then
   Ti:=T3('Journal des achats','Purchases Journal','Einkaufsjournal')
 Else Ti:=T3('Journal des ventes','Sales Journal','Verkaufsjournal');
 P:=NewWin(wkInvoice,Ti,552,396);
 P^.Aux:=Typ;
 If Typ=1 Then
   AddLbl(P,0,8,8,T3('Achet@e de','Purchased from','Eingekauft bei'))
 Else AddLbl(P,0,8,8,T3('Vendu @a','Sold to','Verkauft an'));
 AddCombo(P,10,8,20,300,srcVend+Typ-1);
 AddBox(P,8,42,300,50,'');
 AddLblW(P,14,16,50,284,'',False,True);AddLblW(P,15,16,62,284,'',False,False);
 AddLblW(P,16,16,74,284,'',False,False);
 If Typ=1 Then
   AddChk(P,11,330,10,T3('Achat comptant','Cash purchase','Barkauf'),False)
 Else AddChk(P,11,330,10,T3('Vente comptant','Cash sale','Barverkauf'),False);
 AddLbl(P,0,330,36,T3('Facture','Invoice','Rechnung'));
 AddEdit(P,12,410,32,110,12,0,'');
 AddLbl(P,0,330,60,'Date');AddEdit(P,13,410,56,110,12,2,'');
 If Typ=1 Then AddLbl(P,0,8,100,T3('Pay@e de :','Paid from:','Bezahlt von:'))
 Else AddLbl(P,0,8,100,T3('D@epos@e dans :','Deposit to:','Einzahlung auf:'));
 AddCombo(P,17,110,96,300,srcBank);
 AddGrid(P,100,8,120,8,0,40);
 GridCol(P,64,0,T3('Article','Item','Artikel'),True);
 GridCol(P,48,1,T3('Qt@e','Qty','Menge'),False);
 GridCol(P,40,0,T3('Unit@e','Unit','Einh.'),False);
 GridCol(P,148,0,T3('Description','Description','Beschreibung'),False);
 GridCol(P,76,1,T3('Prix','Price','Preis'),False);
 GridCol(P,80,1,T3('Montant','Amount','Betrag'),False);
 GridCol(P,56,0,T3('Compte','Acct','Konto'),True);
 AddLbl(P,0,300,256,T3('Transport','Freight','Fracht'));
 AddEdit(P,20,400,252,124,12,1,'');
 AddLbl(P,0,300,280,T3('Sous-total','Subtotal','Zwischensumme'));
 AddLblW(P,21,400,280,124,'',True,False);
 AddLbl(P,0,300,294,T3('Taxe (TPS)','Tax (GST)','Steuer (USt)'));
 AddLblW(P,22,400,294,124,'',True,False);
 AddLbl(P,0,300,310,'Total');AddLblW(P,23,400,310,124,'',True,True);
 AddBtn(P,31,8,334,110,T3('Distribuer','Distribute','Verteilen'),False);
 AddBtn(P,32,126,334,110,T3('Enregistrer','Record','Buchen'),True);
 If Typ=2 Then AddBtn(P,33,244,334,110,T3('Imprimer','Print','Drucken'),False);
 AddBtn(P,2,414,334,110,T3('Fermer','Close','Schlie@7en'),False);
 RunWin(P);
End;

{ ====================================================================== }
{                  PAIEMENTS FOURNISSEURS / RECUS CLIENTS                }
{ ====================================================================== }

Var
 PayMap : Array[1..MAXROW] Of Integer;

Function PayDisc(Inv: Integer; D: LongInt): LongInt;
Var PA: PPartyArr; Pt: Integer; O: LongInt;
Begin
 PayDisc:=0;
 O:=Owing(Inv);
 If O<=0 Then Exit;
 If Iv^[Inv].Typ=1 Then PA:=Vn Else PA:=Cu;
 Pt:=Iv^[Inv].Party;
 If (PA^[Pt].DPct>0) And (DayNum(D)<=DayNum(Iv^[Inv].Date)+PA^[Pt].DDays) Then
  PayDisc:=PctOf(O,PA^[Pt].DPct*100);
End;

Procedure PayTotals(P: PWin);
Var R: Integer; T: LongInt; S,Dots: String;
Begin
 T:=0;
 For R:=1 To P^.GN Do T:=T+ParseMoney(P^.GCell[R,6]);
 T:=T+GMoney(P,18);
 ST(P,19,FmtMoney(T));
 ST(P,16,FmtMoney(T));
 If P^.Aux=1 Then Begin
  S:=IntStr(T Mod 100);
  If Length(S)<2 Then S:='0'+S;
  Dots:='............................';
  ST(P,21,T3('Payer ','Pay ','Zahlen ')+Dots+S+'/100');
 End;
End;

Procedure PayAddress(P: PWin);
Var Pt: Integer; PA: PPartyArr;
Begin
 If P^.Aux=1 Then PA:=Vn Else PA:=Cu;
 Pt:=GS(P,15);
 If (Pt>=1) And (Pt<=ListCount(P^.Aux)) Then Begin
  ST(P,24,PA^[Pt].Ad1);
 End Else ST(P,24,'');
End;

Procedure FillPay(P: PWin);
Var I,N,Pt: Integer; D: LongInt;
Begin
 GridClear(P,0);
 Pt:=GS(P,15);D:=DateOrToday(GT(P,14));N:=0;
 If (Pt>0) And (Pt<=ListCount(P^.Aux)) Then
  For I:=1 To NIv Do
   If (Iv^[I].Typ=P^.Aux) And (Iv^[I].Party=Pt) And (Owing(I)<>0)
       And (N<MAXROW) Then Begin
    Inc(N);PayMap[N]:=I;
    P^.GCell[N,1]:=Iv^[I].No;P^.GCell[N,2]:=FmtMoney(Iv^[I].Amt);
    P^.GCell[N,3]:=FmtMoney(Owing(I));P^.GCell[N,4]:=FmtMoney(PayDisc(I,D));
   End;
 P^.GN:=N;
 PayAddress(P);
 PayTotals(P);
End;

Procedure PayFull(P: PWin; R: Integer);
Var Inv: Integer; O,Ds: LongInt;
Begin
 If (R<1) Or (R>P^.GN) Then Exit;
 Inv:=PayMap[R];O:=Owing(Inv);
 Ds:=ParseMoney(P^.GCell[R,4]);
 If Ds<>0 Then P^.GCell[R,5]:=FmtMoney(Ds) Else P^.GCell[R,5]:='';
 P^.GCell[R,6]:=FmtMoney(O-Ds);
End;

Procedure PayReset(P: PWin);
Begin
 SS(P,15,0);
 If P^.Aux=1 Then ST(P,13,IntStr(SU.NextChq)) Else ST(P,13,IntStr(SU.NextRcpt));
 ST(P,17,GT(P,13));SMoney(P,18,0);ST(P,20,'');
 FillPay(P);
End;

Procedure HPay(P: PWin; Ev,A,B: Integer);
Var R,Pt,Bk,Inv,Side: Integer; D,V,Ds,O,SumP,SumD,Pre: LongInt; S: String;
Bad: Boolean;
Begin
 Side:=P^.Aux;
 Case Ev Of
  evInit: Begin
    SS(P,10,1);SS(P,11,1);SDate(P,14,SessDate);
    SetBankCombo(P,12,LinkAcc(LK_BANK));
    PayReset(P);
   End;
  evChange: Begin
    If (A=15) Or (A=14) Then FillPay(P);
    If A=13 Then ST(P,17,GT(P,13));
    If A=18 Then PayTotals(P);
   End;
  evCell: Begin
    If B=5 Then Begin
     V:=ParseMoney(P^.GCell[A,5]);
     If V=0 Then P^.GCell[A,5]:='' Else Begin
      P^.GCell[A,5]:=FmtMoney(V);
      If TrimStr(P^.GCell[A,6])='' Then
        P^.GCell[A,6]:=FmtMoney(Owing(PayMap[A])-V);
     End;
    End;
    If B=6 Then Begin
     V:=ParseMoney(P^.GCell[A,6]);
     If V=0 Then P^.GCell[A,6]:='' Else P^.GCell[A,6]:=FmtMoney(V);
    End;
    PayTotals(P);
   End;
  evLookup: Begin PayFull(P,A);PayTotals(P);End;
  evButton: Case A Of
   32: Begin
     For R:=1 To P^.GN Do PayFull(P,R);
     PayTotals(P);
    End;
   31: Begin
     Pt:=GS(P,15);Bk:=BankComboNum(P,12);
     If (Pt<1) Or (Pt>ListCount(Side)) Then Begin
      If Side=1 Then
        Info(T3('Choisissez un fournisseur.','Select a vendor.',
          'W@1hlen Sie einen Lieferanten.'))
      Else
        Info(T3('Choisissez un client.','Select a customer.',
          'W@1hlen Sie einen Kunden.'));
      Exit;
     End;
     If Bk=0 Then Begin
       Info(T3('Choisissez un compte bancaire.','Select a bank account.',
         'W@1hlen Sie ein Bankkonto.'));Exit;End;
     If Not ParseDate(GT(P,14),D) Then Begin
       Info(T3('Date invalide.','Invalid date.','Ung@3ltiges Datum.'));Exit;End;
     S:=TrimStr(GT(P,13));
     If S='' Then Begin
       Info(T3('Le num@ero est obligatoire.','The number is required.',
         'Die Nummer ist erforderlich.'));Exit;End;
     SumP:=0;SumD:=0;Bad:=False;
     For R:=1 To P^.GN Do Begin
      V:=ParseMoney(P^.GCell[R,6]);Ds:=ParseMoney(P^.GCell[R,5]);
      O:=Owing(PayMap[R]);
      If (V<>0) Or (Ds<>0) Then Begin
       If ((O>0) And ((V+Ds>O) Or (V<0) Or (Ds<0))) Or ((O<0) And ((V+Ds<O)
           Or (V>0) Or (Ds>0))) Then Begin
        Info(T3('Montant trop @elev@e @a la ligne ','Amount too large on line ',
            'Betrag zu hoch in Zeile ')+IntStr(R));Exit;
       End;
       SumP:=SumP+V;SumD:=SumD+Ds;
      End;
     End;
     Pre:=GMoney(P,18);
     If Pre<0 Then Begin
       Info(T3('Pr@epaiement invalide.','Invalid prepayment.',
         'Ung@3ltige Vorauszahlung.'));Exit;End;
     If (SumP+Pre=0) And (SumD=0) Then Begin
      Info(T3('Aucun montant @a traiter.','Nothing to process.',
          'Nichts zu verarbeiten.'));Exit;
     End;
     PClear;
     If Side=1 Then Begin
      PDr(LinkAcc(LK_AP),SumP+SumD+Pre);PCr(Bk,SumP+Pre);
      PCr(LinkAcc(LK_PDISC),SumD);
     End Else Begin
      PDr(Bk,SumP+Pre);PDr(LinkAcc(LK_SDISC),SumD);
      PCr(LinkAcc(LK_AR),SumP+SumD+Pre);
     End;
     If Commit(D,S,ListText(Side,Pt)) Then Begin
      For R:=1 To P^.GN Do Begin
       Inv:=PayMap[R];
       Iv^[Inv].Paid:=Iv^[Inv].Paid+ParseMoney(P^.GCell[R,
           6])+ParseMoney(P^.GCell[R,5]);
      End;
      If Pre>0 Then AddInv(Side,Pt,'PP'+TrimStr(GT(P,17)),D,-Pre);
      If (Side=1) And (S=IntStr(SU.NextChq)) Then Inc(SU.NextChq);
      If (Side=2) And (S=IntStr(SU.NextRcpt)) Then Inc(SU.NextRcpt);
      Info(T3('Transaction enregistr@ee : ','Transaction recorded: ',
          'Buchung erfasst: ')+FmtMoney(SumP+Pre));
      PayReset(P);
     End Else Info(ErrMsg);
    End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Procedure OpenPay(Side: Integer);
Var P: PWin; Ti: String;
Begin
 If Side=1 Then Ti:=T3('Paiements','Payments','Zahlungen') Else
   Ti:=T3('Encaissements','Receipts','Zahlungseing@1nge');
 P:=NewWin(wkPay,Ti,600,398);
 P^.Aux:=Side;
 If Side=1 Then AddCombo(P,10,8,8,280,srcKind) Else
   AddCombo(P,10,8,8,280,srcRKind);
 AddLbl(P,0,298,12,T3('Par','By','Per'));AddCombo(P,11,328,8,110,srcPayBy);
 If Side=1 Then AddLbl(P,0,8,36,T3('De','From','Von')) Else
   AddLbl(P,0,8,36,T3('Vers','To','Auf'));
 AddCombo(P,12,50,32,344,srcBank);
 AddBox(P,8,54,570,94,'');
 AddLblW(P,0,18,62,300,SU.Co,False,True);
 If Side=1 Then AddLbl(P,0,396,62,'No.') Else
   AddLbl(P,0,396,62,T3('Re@ku no','Receipt','Beleg'));
 AddEdit(P,13,440,58,100,12,3,'');
 If Side=1 Then AddLblW(P,21,18,84,360,'',False,False);
 AddLbl(P,0,396,86,'Date');AddEdit(P,14,440,82,100,12,2,'');
 If Side=1 Then
   AddLbl(P,0,18,108,T3('A l''ordre de','To the order of','Zahlbar an'))
 Else AddLbl(P,0,18,108,T3('Re@ku de','Received from','Erhalten von'));
 AddCombo(P,15,130,104,250,srcVend+Side-1);
 AddLblW(P,16,396,112,150,'',True,True);
 AddLblW(P,24,130,126,250,'',False,False);
 AddGrid(P,100,8,160,6,0,0);
 GridCol(P,100,2,T3('Facture/PP','Invoice/PP','Rechn./VZ'),False);
 GridCol(P,92,3,T3('Mnt orig.','Orig. Amt.','Urspr.Betr.'),False);
 GridCol(P,92,3,T3('Mnt d@u','Owing','Offen'),False);
 GridCol(P,96,3,T3('Escpt dispo','Disc. Avail','Skonto frei'),False);
 GridCol(P,96,1,T3('Escpt pris','Disc. Taken','Skonto gen.'),True);
 GridCol(P,92,1,T3('Paiement','Payment','Zahlung'),True);
 AddLbl(P,0,8,268,T3('R@ef. pr@epaiement','Prepayment Ref.','Vorausz.-Ref.'));
 AddEdit(P,17,152,264,90,12,0,'');
 AddLbl(P,0,260,268,T3('Mnt pr@epaiement','Prepayment Amt','Vorausz.-Betrag'));
 AddEdit(P,18,420,264,120,12,1,'');
 AddLbl(P,0,300,296,'Total');AddLblW(P,19,420,296,120,'',True,True);
 AddLbl(P,0,8,300,T3('Commentaire','Comment','Kommentar'));
 AddEdit(P,20,100,296,190,40,0,'');
 AddBtn(P,32,8,338,110,T3('Tout payer','Pay all','Alle zahlen'),False);
 AddBtn(P,31,396,338,104,T3('Traiter','Process','Verarbeiten'),True);
 AddBtn(P,2,508,338,84,T3('Fermer','Close','Schlie@7en'),False);
 RunWin(P);
End;

{ ====================================================================== }
{                              PAIE                                      }
{ ====================================================================== }

Var
 PayG,PayT,PayP,PayU,PayN: LongInt;

Procedure CalcPay(H,Rate: LongInt);
Begin
 PayG:=MulQ(H,Rate);
 PayT:=PctOf(PayG,SU.IncT);PayP:=PctOf(PayG,SU.Pen);PayU:=PctOf(PayG,SU.UI);
 PayN:=PayG-PayT-PayP-PayU;
End;

Procedure PostPaycheque(E: Integer; H: LongInt; D: LongInt; Bk: Integer; Const
    No: String);
Begin
 CalcPay(H,Em^[E].Rate);
 PClear;
 PDr(LinkAcc(LK_WAGE),PayG);PCr(LinkAcc(LK_TAXPAY),PayT);
 PCr(LinkAcc(LK_PENPAY),PayP);
 PCr(LinkAcc(LK_UIPAY),PayU);PCr(Bk,PayN);
End;

Procedure PaychUpdate(P: PWin);
Var E: Integer;
Begin
 E:=GS(P,10);
 If (E>=1) And (E<=NE) Then Begin
  ST(P,13,FmtMoney(Em^[E].Rate));
  CalcPay(ParseMoney(GT(P,12)),Em^[E].Rate);
 End Else Begin ST(P,13,'');PayG:=0;PayT:=0;PayP:=0;PayU:=0;PayN:=0;End;
 ST(P,20,FmtMoney(PayG));ST(P,21,FmtMoney(-PayT));ST(P,22,FmtMoney(-PayP));
 ST(P,23,FmtMoney(-PayU));ST(P,24,FmtMoney(PayN));
End;

Procedure HPaych(P: PWin; Ev,A,B: Integer);
Var E,Bk: Integer; D,H: LongInt; S: String;
Begin
 Case Ev Of
  evInit: Begin
    SDate(P,11,SessDate);ST(P,14,IntStr(SU.NextChq));
    SetBankCombo(P,15,LinkAcc(LK_BANK));
    ST(P,12,'0');PaychUpdate(P);
   End;
  evChange: Begin
    If A=10 Then Begin
     E:=GS(P,10);
     If (E>=1) And (E<=NE) Then ST(P,12,FmtQty(Em^[E].Hrs));
    End;
    If (A=10) Or (A=12) Then PaychUpdate(P);
   End;
  evButton: Case A Of
   31: Begin
     E:=GS(P,10);Bk:=BankComboNum(P,15);
     If (E<1) Or (E>NE) Then Begin
       Info(T3('Choisissez un employ@e.','Select an employee.',
         'W@1hlen Sie einen Mitarbeiter.'));Exit;End;
     If Bk=0 Then Begin
       Info(T3('Choisissez un compte bancaire.','Select a bank account.',
         'W@1hlen Sie ein Bankkonto.'));Exit;End;
     If Not ParseDate(GT(P,11),D) Then Begin
       Info(T3('Date invalide.','Invalid date.','Ung@3ltiges Datum.'));Exit;End;
     H:=ParseMoney(GT(P,12));
     If H<=0 Then Begin
       Info(T3('Les heures doivent @etre positives.','Hours must be positive.',
         'Stunden m@3ssen positiv sein.'));Exit;End;
     S:=TrimStr(GT(P,14));
     PostPaycheque(E,H,D,Bk,S);
     If Commit(D,S,Em^[E].Name) Then Begin
      Em^[E].Ytd:=Em^[E].Ytd+PayG;
      If S=IntStr(SU.NextChq) Then Inc(SU.NextChq);
      Info(T3('Ch@eque de paie enregistr@e. Net : ','Paycheque recorded. Net: ',
          'Gehaltsscheck gebucht. Netto: ')+FmtMoney(PayN));
      ST(P,14,IntStr(SU.NextChq));SS(P,10,0);ST(P,12,'0');PaychUpdate(P);
     End Else Info(ErrMsg);
    End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Procedure OpenPaych;
Var P: PWin;
Begin
 If NE=0 Then Begin
   Info(T3('Aucun employ@e n''est d@efini.','No employee is defined.',
     'Kein Mitarbeiter definiert.'));Exit;End;
 P:=NewWin(wkPaych,T3('Ch@eques de paie','Paycheques','Gehaltsschecks'),420,
     300);
 AddLbl(P,0,8,14,T3('Employ@e','Employee','Mitarbeiter'));
 AddCombo(P,10,110,10,290,srcEmp);
 AddLbl(P,0,8,40,'Date');AddEdit(P,11,110,36,100,12,2,'');
 AddLbl(P,0,230,40,T3('Ch@eque','Cheque','Scheck'));
 AddEdit(P,14,300,36,100,10,3,'');
 AddLbl(P,0,8,66,T3('Banque','Bank','Bank'));AddCombo(P,15,110,62,290,srcBank);
 AddLbl(P,0,8,92,T3('Heures','Hours','Stunden'));
 AddEdit(P,12,110,88,90,10,5,'');
 AddLbl(P,0,230,92,T3('Taux','Rate','Satz'));
 AddLblW(P,13,290,92,110,'',True,False);
 AddBox(P,8,116,392,110,T3('Talon de paie','Pay slip','Gehaltsabrechnung'));
 AddLbl(P,0,20,136,T3('Salaire brut','Gross wages','Bruttolohn'));
 AddLblW(P,20,230,136,150,'',True,False);
 AddLbl(P,0,20,152,T3('Imp@ot sur le revenu','Income tax','Lohnsteuer'));
 AddLblW(P,21,230,152,150,'',True,False);
 AddLbl(P,0,20,168,T3('R@egime de pension','Pension plan',
     'Rentenversicherung'));AddLblW(P,22,230,168,150,'',True,False);
 AddLbl(P,0,20,184,T3('Assurance-emploi','Unemployment ins.',
     'Arbeitslosenvers.'));AddLblW(P,23,230,184,150,'',True,False);
 AddRule(P,20,200,360);
 AddLbl(P,0,20,208,T3('Net @a payer','Net pay','Nettolohn'));
 AddLblW(P,24,230,208,150,'',True,True);
 AddBtn(P,31,200,240,96,T3('Traiter','Process','Verarbeiten'),True);
 AddBtn(P,2,304,240,96,T3('Fermer','Close','Schlie@7en'),False);
 RunWin(P);
End;

Procedure RunRows(P: PWin; R: Integer);
Var H: LongInt;
Begin
 H:=ParseMoney(P^.GCell[R,2]);
 CalcPay(H,Em^[R].Rate);
 P^.GCell[R,3]:=FmtMoney(PayG);P^.GCell[R,4]:=FmtMoney(PayN);
End;

Procedure HRun(P: PWin; Ev,A,B: Integer);
Var R,Bk,Cnt: Integer; D,Tot: LongInt; H: LongInt; S: String;
Begin
 Case Ev Of
  evInit: Begin
    SDate(P,10,SessDate);SetBankCombo(P,11,LinkAcc(LK_BANK));
    GridClear(P,NE);
    For R:=1 To NE Do Begin
     P^.GCell[R,1]:=Em^[R].Name;P^.GCell[R,2]:=FmtQty(Em^[R].Hrs);
     RunRows(P,R);
    End;
   End;
  evCell: If B=2 Then Begin
    P^.GCell[A,2]:=FmtQty(ParseMoney(P^.GCell[A,2]));
    RunRows(P,A);
   End;
  evButton: Case A Of
   31: Begin
     Bk:=BankComboNum(P,11);
     If Bk=0 Then Begin
       Info(T3('Choisissez un compte bancaire.','Select a bank account.',
         'W@1hlen Sie ein Bankkonto.'));Exit;End;
     If Not ParseDate(GT(P,10),D) Then Begin
       Info(T3('Date invalide.','Invalid date.','Ung@3ltiges Datum.'));Exit;End;
     Cnt:=0;Tot:=0;R:=1;
     While R<=NE Do Begin
      H:=ParseMoney(P^.GCell[R,2]);
      If H>0 Then Begin
       S:=IntStr(SU.NextChq);
       PostPaycheque(R,H,D,Bk,S);
       If Commit(D,S,Em^[R].Name) Then Begin
        Em^[R].Ytd:=Em^[R].Ytd+PayG;Inc(SU.NextChq);Inc(Cnt);Tot:=Tot+PayN;
       End Else Begin Info(ErrMsg);R:=NE;End;
      End;
      Inc(R);
     End;
     If Cnt>0 Then Begin
      Info(IntStr(Cnt)+T3(' ch@eque(s) de paie trait@e(s).|Total net : ',
          ' paycheque(s) processed.|Total net: ',
          ' Gehaltsscheck(s) verarbeitet.|Summe netto: ')+FmtMoney(Tot));
      P^.Res:=1;P^.Done:=True;
     End Else
       Info(T3('Aucune heure saisie.','No hours entered.',
         'Keine Stunden erfasst.'));
    End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Procedure OpenRun;
Var P: PWin;
Begin
 If NE=0 Then Begin
   Info(T3('Aucun employ@e n''est d@efini.','No employee is defined.',
     'Kein Mitarbeiter definiert.'));Exit;End;
 P:=NewWin(wkRun,T3('Passage de la paie','Payroll Cheque Run','Gehaltslauf'),
     500,300);
 AddLbl(P,0,8,14,'Date');AddEdit(P,10,60,10,100,12,2,'');
 AddLbl(P,0,180,14,T3('Banque','Bank','Bank'));
 AddCombo(P,11,236,10,244,srcBank);
 AddGrid(P,100,8,40,8,0,NE);
 GridCol(P,170,2,T3('Employ@e','Employee','Mitarbeiter'),False);
 GridCol(P,90,1,T3('Heures','Hours','Stunden'),False);
 GridCol(P,100,3,T3('Brut','Gross','Brutto'),False);
 GridCol(P,100,3,'Net',False);
 AddBtn(P,31,260,196,110,T3('Traiter tout','Process all','Alle verarb.'),True);
 AddBtn(P,2,376,196,104,T3('Fermer','Close','Schlie@7en'),False);
 RunWin(P);
End;

{ ====================================================================== }
{                       RAPPROCHEMENT BANCAIRE                           }
{ ====================================================================== }

Procedure ReconTotals(P: PWin);
Var J,R,Bn: Integer; Base,Clr: LongInt;
Begin
 Bn:=BankComboNum(P,10);
 Base:=0;
 For J:=1 To NJ Do If (Jl^[J].Acc=Bn) And Jl^[J].Rec Then
   Base:=Base+Jl^[J].Dr-Jl^[J].Cr;
 Clr:=Base;
 For R:=1 To P^.GN Do If RcOn[R] Then
   Clr:=Clr+Jl^[RcMap[R]].Dr-Jl^[RcMap[R]].Cr;
 ST(P,20,FmtMoney(Base));ST(P,21,FmtMoney(Clr));
 ST(P,22,FmtMoney(GMoney(P,12)-Clr));
End;

Procedure ReconFill(P: PWin);
Var J,N,Bn: Integer; D: LongInt;
Begin
 GridClear(P,0);
 Bn:=BankComboNum(P,10);D:=DateOrToday(GT(P,11));N:=0;
 If Bn<>0 Then
  For J:=1 To NJ Do
   If (Jl^[J].Acc=Bn) And (Not Jl^[J].Rec) And (Jl^[J].Dt<=D)
       And (N<MAXROW) Then Begin
    Inc(N);RcMap[N]:=J;RcOn[N]:=False;
    P^.GCell[N,1]:=' ';P^.GCell[N,2]:=FmtDate(Jl^[J].Dt);
    P^.GCell[N,3]:=Jl^[J].Src;
    P^.GCell[N,4]:=Jl^[J].Cm;
    If Jl^[J].Dr<>0 Then P^.GCell[N,5]:=FmtMoney(Jl^[J].Dr) Else
      P^.GCell[N,5]:='';
    If Jl^[J].Cr<>0 Then P^.GCell[N,6]:=FmtMoney(Jl^[J].Cr) Else
      P^.GCell[N,6]:='';
   End;
 P^.GN:=N;
 ReconTotals(P);
End;

Procedure ReconMark(P: PWin; R: Integer);
Begin
 If RcOn[R] Then P^.GCell[R,1]:=#251 Else P^.GCell[R,1]:=' ';
End;

Procedure HRecon(P: PWin; Ev,A,B: Integer);
Var R,J: Integer; Diff: LongInt;
Begin
 Case Ev Of
  evInit: Begin
    SetBankCombo(P,10,LinkAcc(LK_BANK));SDate(P,11,SessDate);SMoney(P,12,0);
    ReconFill(P);
   End;
  evChange: If (A=10) Or (A=11) Then ReconFill(P) Else ReconTotals(P);
  evDbl: If (A>=1) And (A<=P^.GN) Then Begin
    RcOn[A]:=Not RcOn[A];ReconMark(P,A);ReconTotals(P);
   End;
  evButton: Case A Of
   32: Begin For R:=1 To P^.GN Do Begin
     RcOn[R]:=True;ReconMark(P,R);End;ReconTotals(P);End;
   33: Begin For R:=1 To P^.GN Do Begin
     RcOn[R]:=False;ReconMark(P,R);End;ReconTotals(P);End;
   31: Begin
     Diff:=GMoney(P,12)-ParseMoney(GT(P,21));
     If Diff<>0 Then
      Info(T3('Le rapprochement ne balance pas.|Diff@erence : ',
          'The reconciliation does not balance.|Difference: ',
          'Der Abgleich stimmt nicht.|Differenz: ')+FmtMoney(Diff))
     Else Begin
      For R:=1 To P^.GN Do If RcOn[R] Then Jl^[RcMap[R]].Rec:=True;
      Modified:=True;
      Info(T3('Rapprochement termin@e.','Reconciliation completed.',
          'Kontoabstimmung abgeschlossen.'));
      ReconFill(P);
     End;
    End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Procedure OpenRecon;
Var P: PWin;
Begin
 If BankCount=0 Then Begin
   Info(T3('Aucun compte bancaire n''est d@efini.',
     'No bank account is defined.','Kein Bankkonto definiert.'));Exit;End;
 P:=NewWin(wkRecon,T3('Rapprochement bancaire','Account Reconciliation',
     'Kontoabstimmung'),600,372);
 AddLbl(P,0,8,14,T3('Compte','Account','Konto'));
 AddCombo(P,10,70,10,300,srcBank);
 AddLbl(P,0,384,14,T3('Relev@e au','Statement','Auszug'));
 AddEdit(P,11,470,10,100,12,2,'');
 AddLbl(P,0,8,40,T3('Solde du relev@e :','Statement balance:',
     'Kontoauszugssaldo:'));AddEdit(P,12,160,36,110,14,1,'');
 AddGrid(P,100,8,64,10,2,0);
 GridCol(P,30,2,'',False);
 GridCol(P,88,2,'Date',False);
 GridCol(P,90,2,'Source',False);
 GridCol(P,150,2,T3('Description','Description','Beschreibung'),False);
 GridCol(P,100,3,T3('D@ebit','Debit','Soll'),False);
 GridCol(P,100,3,T3('Cr@edit','Credit','Haben'),False);
 AddLbl(P,0,300,232,T3('Solde rapproch@e pr@ec@edent','Previously reconciled',
     'Zuvor abgestimmt'));AddLblW(P,20,460,232,110,'',True,False);
 AddLbl(P,0,300,246,T3('Solde point@e','Cleared balance','Abgestimmter Saldo'));
 AddLblW(P,21,460,246,110,'',True,False);
 AddLbl(P,0,300,260,T3('Diff@erence','Difference','Differenz'));
 AddLblW(P,22,460,260,110,'',True,True);
 AddBtn(P,32,8,282,110,T3('Tout pointer','Select all','Alle w@1hlen'),False);
 AddBtn(P,33,126,282,110,T3('Tout d@epointer','Clear all','Alle l@2schen'),
     False);
 AddBtn(P,31,368,282,110,T3('Rapprocher','Reconcile','Abstimmen'),True);
 AddBtn(P,2,486,282,100,T3('Fermer','Close','Schlie@7en'),False);
 RunWin(P);
End;

{ ====================================================================== }
{                  AJUSTEMENTS ET ASSEMBLAGE D'INVENTAIRE                }
{ ====================================================================== }

Procedure HAdjust(P: PWin; Ev,A,B: Integer);
Var I,Ac_: Integer; D,Q,NQ,Cst,Val_: LongInt; S: String; V: Real;
Begin
 Case Ev Of
  evInit: Begin
    SDate(P,15,SessDate);SetAcctCombo(P,14,LinkAcc(LK_ADJ));
    ST(P,12,'0');SMoney(P,13,0);ST(P,11,'');
   End;
  evChange: If A=10 Then Begin
    I:=GS(P,10);
    If (I>=1) And (I<=NI) Then Begin
     If It^[I].Svc Then ST(P,11,T3('(service)','(service)','(Dienst)')) Else
       ST(P,11,FmtQty(It^[I].Qty));
     SMoney(P,13,It^[I].Cost);
    End;
   End;
  evButton: Case A Of
   31: Begin
     I:=GS(P,10);
     If (I<1) Or (I>NI) Then Begin
       Info(T3('Choisissez un article.','Select an item.',
         'W@1hlen Sie einen Artikel.'));Exit;End;
     If It^[I].Svc Then Begin
       Info(T3('Un service n''a pas de stock.','A service has no stock.',
         'Eine Dienstleistung hat keinen Bestand.'));Exit;End;
     If Not ParseDate(GT(P,15),D) Then Begin
       Info(T3('Date invalide.','Invalid date.','Ung@3ltiges Datum.'));Exit;End;
     Q:=ParseMoney(GT(P,12));
     If Q=0 Then Begin
       Info(T3('Quantit@e nulle.','Zero quantity.','Menge null.'));Exit;End;
     NQ:=It^[I].Qty+Q;
     If NQ<0 Then Begin
       Info(T3('Le stock ne peut pas @etre n@egatif.',
         'Stock cannot be negative.','Der Bestand kann nicht negativ sein.'));
         Exit;End;
     Ac_:=AcctComboNum(P,14,LinkAcc(LK_ADJ));
     PClear;
     If Q>0 Then Begin
      Cst:=GMoney(P,13);If Cst=0 Then Cst:=It^[I].Cost;
      Val_:=MulQ(Q,Cst);
      PDr(It^[I].AAcc,Val_);PCr(Ac_,Val_);
     End Else Begin
      Val_:=MulQ(-Q,It^[I].Cost);
      PDr(Ac_,Val_);PCr(It^[I].AAcc,Val_);
     End;
     S:=TrimStr(GT(P,16));If S='' Then S:='ADJ';
     If Commit(D,S,It^[I].Code) Then Begin
      If Q>0 Then Begin
       V:=It^[I].Qty;V:=V/100.0*It^[I].Cost+Val_;
       If NQ>0 Then It^[I].Cost:=Round(V/(NQ/100.0));
      End;
      It^[I].Qty:=NQ;
      Info(T3('Ajustement enregistr@e. Nouveau stock : ',
          'Adjustment recorded. New stock: ',
          'Anpassung gebucht. Neuer Bestand: ')+FmtQty(NQ));
      ST(P,11,FmtQty(NQ));ST(P,12,'0');
     End Else Info(ErrMsg);
    End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Procedure OpenAdjust;
Var P: PWin;
Begin
 If NI=0 Then Begin
   Info(T3('Aucun article n''est d@efini.','No item is defined.',
     'Kein Artikel definiert.'));Exit;End;
 P:=NewWin(wkAdjust,T3('Ajustements d''inventaire','Inventory Adjustments',
     'Bestandskorrekturen'),460,262);
 AddLbl(P,0,8,14,T3('Article','Item','Artikel'));
 AddCombo(P,10,150,10,290,srcItem);
 AddLbl(P,0,8,40,T3('Stock actuel','Quantity on hand','Aktueller Bestand'));
 AddLblW(P,11,150,40,120,'',False,True);
 AddLbl(P,0,8,64,T3('Variation (+/-)','Adjustment (+/-)','Anpassung (+/-)'));
 AddEdit(P,12,150,60,100,10,5,'');
 AddLbl(P,0,8,88,T3('Co@ut unitaire','Unit cost','St@3ckkosten'));
 AddEdit(P,13,150,84,100,12,1,'');
 AddLbl(P,0,8,112,T3('Compte d''ajust.','Adjustment acct','Korrekturkonto'));
 AddCombo(P,14,150,108,290,srcAcct);
 AddLbl(P,0,8,136,'Date');AddEdit(P,15,150,132,100,12,2,'');
 AddLbl(P,0,8,160,'Source');AddEdit(P,16,150,156,120,12,0,'');
 AddBtn(P,31,240,190,96,T3('Traiter','Process','Verarbeiten'),True);
 AddBtn(P,2,344,190,96,T3('Fermer','Close','Schlie@7en'),False);
 RunWin(P);
End;

Procedure HAssem(P: PWin; Ev,A,B: Integer);
Var F,R,C,N,Cnt: Integer; Bq,Need,Tot,Cst: LongInt; D: LongInt; V: Real;
S: String;
    CI: Array[1..6] Of Integer; CQ: Array[1..6] Of LongInt;
Begin
 Case Ev Of
  evInit: Begin SDate(P,12,SessDate);ST(P,11,'1');GridClear(P,6);End;
  evCell: If B=1 Then Begin
    C:=FindItem(P^.GCell[A,1]);
    If C>0 Then Begin P^.GCell[A,1]:=It^[C].Code;P^.GCell[A,3]:=It^[C].Desc;
     If TrimStr(P^.GCell[A,2])='' Then P^.GCell[A,2]:='1.00';End
    Else Begin P^.GCell[A,3]:='';End;
   End Else If B=2 Then P^.GCell[A,2]:=FmtQty(ParseMoney(P^.GCell[A,2]));
  evLookup: If B=1 Then Begin
    N:=SelectList(SelTitle(srcItem),srcItem,1);
    If N>0 Then Begin P^.GCell[A,1]:=It^[N].Code;P^.GCell[A,3]:=It^[N].Desc;
     If TrimStr(P^.GCell[A,2])='' Then P^.GCell[A,2]:='1.00';End;
   End;
  evButton: Case A Of
   31: Begin
     F:=GS(P,10);
     If (F<1) Or (F>NI) Or It^[F].Svc Then Begin
       Info(T3('Choisissez l''article assembl@e.','Select the assembled item.',
         'W@1hlen Sie den Baugruppenartikel.'));Exit;End;
     Bq:=ParseMoney(GT(P,11));
     If Bq<=0 Then Begin
       Info(T3('Quantit@e invalide.','Invalid quantity.','Ung@3ltige Menge.'));
       Exit;End;
     If Not ParseDate(GT(P,12),D) Then Begin
       Info(T3('Date invalide.','Invalid date.','Ung@3ltiges Datum.'));Exit;End;
     Cnt:=0;Tot:=0;PClear;
     For R:=1 To 6 Do Begin
      C:=FindItem(P^.GCell[R,1]);
      If C>0 Then Begin
       If (C=F) Or It^[C].Svc Then Begin
         Info(T3('Composant invalide : ','Invalid component: ',
           'Ung@3ltige Komponente: ')+It^[C].Code);Exit;End;
       V:=ParseMoney(P^.GCell[R,2]);V:=V*Bq/100.0;Need:=Round(V);
       If It^[C].Qty<Need Then Begin
         Info(T3('Stock insuffisant : ','Insufficient stock: ',
           'Bestand unzureichend: ')+It^[C].Code);Exit;End;
       Inc(Cnt);CI[Cnt]:=C;CQ[Cnt]:=Need;
       Cst:=MulQ(Need,It^[C].Cost);Tot:=Tot+Cst;
       PCr(It^[C].AAcc,Cst);
      End;
     End;
     If Cnt=0 Then Begin
       Info(T3('Aucun composant.','No components.','Keine Komponenten.'));Exit;
       End;
     PDr(It^[F].AAcc,Tot);
     If PN>0 Then Begin
      S:='ASM-'+It^[F].Code;
      If Not Commit(D,S,It^[F].Desc) Then Begin Info(ErrMsg);Exit;End;
     End;
     For R:=1 To Cnt Do It^[CI[R]].Qty:=It^[CI[R]].Qty-CQ[R];
     V:=It^[F].Qty;V:=V/100.0*It^[F].Cost+Tot;
     It^[F].Qty:=It^[F].Qty+Bq;
     It^[F].Cost:=Round(V/(It^[F].Qty/100.0));
     Modified:=True;
     Info(T3('Assemblage termin@e.','Assembly completed.',
         'Montage abgeschlossen.'));
     P^.Res:=1;P^.Done:=True;
    End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Procedure OpenAssem;
Var P: PWin;
Begin
 If NI=0 Then Begin
   Info(T3('Aucun article n''est d@efini.','No item is defined.',
     'Kein Artikel definiert.'));Exit;End;
 P:=NewWin(wkAssem,T3('Assemblage d''articles','Item Assembly',
     'Artikelmontage'),430,306);
 AddLbl(P,0,8,14,T3('Article assembl@e','Assembled item','Baugruppe'));
 AddCombo(P,10,140,10,270,srcItem);
 AddLbl(P,0,8,40,T3('Quantit@e @a produire','Quantity to build',
     'Zu fertigende Menge'));AddEdit(P,11,200,36,100,10,5,'');
 AddLbl(P,0,8,64,'Date');AddEdit(P,12,200,60,100,12,2,'');
 AddGrid(P,100,8,90,6,0,6);
 GridCol(P,110,0,T3('Composant','Component','Komponente'),True);
 GridCol(P,90,1,T3('Qt@e/unit@e','Qty/unit','Menge/Einh.'),False);
 GridCol(P,190,2,'Description',False);
 AddBtn(P,31,200,214,96,T3('Assembler','Build','Montieren'),True);
 AddBtn(P,2,304,214,96,T3('Fermer','Close','Schlie@7en'),False);
 RunWin(P);
End;

{ ====================================================================== }
{                      CONFIGURATION DE LA SOCIETE                       }
{ ====================================================================== }

Function LinkLabel(L: Integer): String;
Begin
 Case L Of
  LK_AP: LinkLabel:=T3('Fournisseurs','Accts Payable','Verbindlichk.');
  LK_AR: LinkLabel:=T3('Clients','Accts Recv.','Forderungen');
  LK_GSTPD: LinkLabel:=T3('TPS pay@ee','GST paid','Vorsteuer');
  LK_GSTCL: LinkLabel:=T3('TPS perc@ue','GST charged','Umsatzsteuer');
  LK_WAGE: LinkLabel:=T3('Salaires','Wages expense','Lohnaufwand');
  LK_TAXPAY: LinkLabel:=T3('Imp@ot @a payer','Inc. tax pay.','Lohnsteuer');
  LK_PENPAY: LinkLabel:=T3('R@eg. pension','Pension pay.','Rentenv.');
  LK_UIPAY: LinkLabel:=T3('Ass.-emploi','UI payable','Arbeitslosenv.');
  LK_FRTEXP: LinkLabel:=T3('Transp. d@ep.','Freight exp.','Frachtaufwand');
  LK_FRTREV: LinkLabel:=T3('Transp. rev.','Freight rev.','Frachtertrag');
  LK_PDISC: LinkLabel:=T3('Esc. achats','Purch. disc.','Einkaufsskonto');
  LK_SDISC: LinkLabel:=T3('Esc. ventes','Sales disc.','Verkaufsskonto');
  LK_ADJ: LinkLabel:=T3('Ajust. inv.','Inv. adjust.','Bestandskorr.');
  LK_RET: LinkLabel:=T3('B@en. non r@ep.','Retained earn.','Gewinnvortrag');
  LK_BANK: LinkLabel:=T3('Banque d@efaut','Default bank','Standardbank');
  Else LinkLabel:='';
 End;
End;

Procedure HSetup(P: PWin; Ev,A,B: Integer);
Var K,L,Lo,Hi,PrevHi,I: Integer; Ok: Boolean;
Begin
 Case Ev Of
  evInit: Begin
    For K:=1 To 6 Do Begin
     ST(P,10+K,IntStr(SU.Rng[K].Lo));ST(P,20+K,IntStr(SU.Rng[K].Hi));
    End;
    For K:=1 To 3 Do ST(P,30+K,SU.Msg[K]);
    For L:=1 To NLINK Do SetAcctCombo(P,40+L,SU.Link[L]);
    ST(P,61,FmtPct(SU.Gst));ST(P,62,FmtPct(SU.IncT));ST(P,63,FmtPct(SU.Pen));
    ST(P,64,FmtPct(SU.UI));
    ST(P,71,SU.Co);ST(P,72,SU.Ad1);ST(P,73,SU.Ad2);
    P^.CurTab:=P^.Aux;
   End;
  evButton: Case A Of
   1: Begin
     Ok:=True;PrevHi:=0;
     For K:=1 To 6 Do Begin
      Lo:=ValInt(GT(P,10+K),0);Hi:=ValInt(GT(P,20+K),0);
      If (Lo<1) Or (Hi<Lo) Or (Hi>9999) Or (Lo<=PrevHi) Then Ok:=False;
      PrevHi:=Hi;
     End;
     If Not Ok Then Begin
      Info(T3('Les plages de num@eros sont invalides.|Elles doivent @etre '+
          'croissantes et distinctes.',
          'The number ranges are invalid.|They must be ascending and distinct.',
          'Die Nummernbereiche sind ung@3ltig.|Sie m@3ssen aufsteigend und '+
          'getrennt sein.'));
      Exit;
     End;
     For K:=1 To 6 Do Begin
      SU.Rng[K].Lo:=ValInt(GT(P,10+K),0);SU.Rng[K].Hi:=ValInt(GT(P,20+K),0);
     End;
     For K:=1 To 3 Do SU.Msg[K]:=GT(P,30+K);
     For L:=1 To NLINK Do SU.Link[L]:=AcctComboNum(P,40+L,SU.Link[L]);
     SU.Gst:=ParsePct(GT(P,61));SU.IncT:=ParsePct(GT(P,62));
     SU.Pen:=ParsePct(GT(P,63));SU.UI:=ParsePct(GT(P,64));
     SU.Co:=TrimStr(GT(P,71));SU.Ad1:=TrimStr(GT(P,72));
     SU.Ad2:=TrimStr(GT(P,73));
     For I:=1 To NA Do Begin
      K:=KindOfNum(Ac^[I].Num);
      If K>0 Then Ac^[I].Kind:=K;
     End;
     Recalc;
     Modified:=True;
     P^.Res:=1;P^.Done:=True;
    End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Procedure OpenSetup(Tab: Integer);
Var P: PWin; K,L,Col,Row: Integer;
Begin
 P:=NewWin(wkSetup,T3('Param@etres de la soci@et@e','Company Settings',
     'Firmeneinstellungen'),600,372);
 P^.Aux:=Tab;
 NewTab(P,T3('Num@eros de compte','Account Numbers','Kontonummern'));
 AddLbl(P,0,16,34,T3('Plage de num@eros pour chaque cat@egorie.',
     'Number range for each account category.',
     'Nummernbereich je Kontoklasse.'));
 For K:=1 To 6 Do Begin
  AddLbl(P,0,16,62+(K-1)*24,KindName(K));
  AddEdit(P,10+K,150,58+(K-1)*24,60,4,3,'');
  AddLbl(P,0,218,62+(K-1)*24,'-');
  AddEdit(P,20+K,236,58+(K-1)*24,60,4,3,'');
 End;
 AddBox(P,8,212,578,92,T3('Message au bas des factures',
     'Message at the bottom of invoices','Meldung am Ende der Rechnungen'));
 AddLbl(P,0,16,232,'F');AddEdit(P,31,34,228,530,100,0,'');
 AddLbl(P,0,16,256,'A');AddEdit(P,32,34,252,530,100,0,'');
 AddLbl(P,0,16,280,'D');AddEdit(P,33,34,276,530,100,0,'');
 NewTab(P,T3('Comptes d''int@egration','Linked Accounts','Verkn@3pfte Konten'));
 For L:=1 To NLINK Do Begin
  If L<=8 Then Begin Col:=0;Row:=L-1;End Else Begin Col:=1;Row:=L-9;End;
  AddLbl(P,0,12+Col*292,42+Row*26,LinkLabel(L));
  AddCombo(P,40+L,126+Col*292,38+Row*26,170,srcAcct);
 End;
 NewTab(P,T3('Taxes et paie','Taxes and Payroll','Steuern und Lohn'));
 AddLbl(P,0,16,44,T3('Taux de TPS / taxe de vente (%)',
     'GST / sales tax rate (%)','Umsatzsteuersatz (%)'));
     AddEdit(P,61,330,40,80,8,4,'');
 AddLbl(P,0,16,72,T3('Imp@ot sur le revenu retenu (%)',
     'Income tax withheld (%)','Einbehaltene Lohnsteuer (%)'));
     AddEdit(P,62,330,68,80,8,4,'');
 AddLbl(P,0,16,100,T3('R@egime de pension (%)','Pension plan (%)',
     'Rentenversicherung (%)'));AddEdit(P,63,330,96,80,8,4,'');
 AddLbl(P,0,16,128,T3('Assurance-emploi (%)','Unemployment insurance (%)',
     'Arbeitslosenvers. (%)'));AddEdit(P,64,330,124,80,8,4,'');
 NewTab(P,T3('Soci@et@e','Company','Firma'));
 AddLbl(P,0,16,44,T3('Nom :','Name:','Name:'));AddEdit(P,71,120,40,300,34,0,'');
 AddLbl(P,0,16,72,T3('Adresse :','Address:','Adresse:'));
 AddEdit(P,72,120,68,300,34,0,'');
 AddEdit(P,73,120,92,300,34,0,'');
 P^.BTab:=0;
 AddBtn(P,1,400,306,86,'OK',True);
 AddBtn(P,2,494,306,86,T3('Annuler','Cancel','Abbrechen'),False);
 RunWin(P);
End;

{ ====================================================================== }
{                            CALCULATRICE                                }
{ ====================================================================== }

Var
 CalcAcc: Real;
 CalcOp: Char;
 CalcStr: String[20];
 CalcFresh: Boolean;

Function RealStr(R: Real): String;
Var S: String;
Begin
 Str(R:0:6,S);
 If Pos('.',S)>0 Then Begin
  While S[Length(S)]='0' Do Delete(S,Length(S),1);
  If S[Length(S)]='.' Then Delete(S,Length(S),1);
 End;
 If Length(S)>16 Then S:='Err';
 If Lang<>2 Then Begin
  If Pos('.',S)>0 Then S[Pos('.',S)]:=',';
 End;
 RealStr:=S;
End;

Function StrReal(S: String): Real;
Var R: Real; C: Integer;
Begin
 If Pos(',',S)>0 Then S[Pos(',',S)]:='.';
 Val(S,R,C);
 If C<>0 Then R:=0;
 StrReal:=R;
End;

Procedure CalcApply;
Var V: Real;
Begin
 V:=StrReal(CalcStr);
 Case CalcOp Of
  '+': CalcAcc:=CalcAcc+V;
  '-': CalcAcc:=CalcAcc-V;
  '*': CalcAcc:=CalcAcc*V;
  '/': If V=0 Then Begin CalcAcc:=0;CalcStr:='Err';Exit;End Else
    CalcAcc:=CalcAcc/V;
  Else CalcAcc:=V;
 End;
 CalcStr:=RealStr(CalcAcc);
End;

Procedure HCalc(P: PWin; Ev,A,B: Integer);
Var Op: Char;
Begin
 Case Ev Of
  evInit: Begin
    CalcAcc:=0;CalcOp:=' ';CalcStr:='0';CalcFresh:=True;ST(P,10,'0');End;
  evButton: Begin
    Case A Of
     100..109: Begin
       If CalcFresh Or (CalcStr='0') Or (CalcStr='Err') Then CalcStr:='';
       CalcFresh:=False;
       If Length(CalcStr)<14 Then CalcStr:=CalcStr+Chr(48+A-100);
      End;
     110: Begin
       If CalcFresh Then Begin CalcStr:='0';CalcFresh:=False;End;
       If (Pos(',',CalcStr)=0) And (Pos('.',CalcStr)=0) Then Begin
        If Lang=2 Then CalcStr:=CalcStr+'.' Else CalcStr:=CalcStr+',';
       End;
      End;
     111..114: Begin
       Case A Of 111: Op:='+'; 112: Op:='-'; 113: Op:='*'; Else Op:='/'; End;
       If CalcFresh And (CalcOp<>' ') Then CalcOp:=Op
       Else Begin CalcApply;CalcOp:=Op;End;
       CalcFresh:=True;
      End;
     115: Begin
       If CalcOp<>' ' Then CalcApply;
       CalcOp:=' ';CalcFresh:=True;
      End;
     116: Begin CalcAcc:=0;CalcOp:=' ';CalcStr:='0';CalcFresh:=True;End;
     117: Begin
       If Copy(CalcStr,1,1)='-' Then Delete(CalcStr,1,1)
       Else If (CalcStr<>'0') And (CalcStr<>'') Then CalcStr:='-'+CalcStr;
      End;
     2: Begin P^.Res:=0;P^.Done:=True;End;
    End;
    ST(P,10,CalcStr);
   End;
  evClose: P^.Res:=0;
 End;
End;

Procedure OpenCalc;
Var P: PWin;
Begin
 P:=NewWin(wkCalc,T3('Calculatrice','Calculator','Rechner'),214,262);
 AddLblW(P,10,12,12,180,'0',True,True);
 AddRule(P,8,26,190);
 { rangee 1 : C, +/-, /, * }
 AddBtn(P,116,8,36,44,'C',False);AddBtn(P,117,56,36,44,'+/-',False);
 AddBtn(P,114,104,36,44,'/',False);AddBtn(P,113,152,36,44,'*',False);
 AddBtn(P,107,8,68,44,'7',False);AddBtn(P,108,56,68,44,'8',False);
 AddBtn(P,109,104,68,44,'9',False);AddBtn(P,112,152,68,44,'-',False);
 AddBtn(P,104,8,100,44,'4',False);AddBtn(P,105,56,100,44,'5',False);
 AddBtn(P,106,104,100,44,'6',False);AddBtn(P,111,152,100,44,'+',False);
 AddBtn(P,101,8,132,44,'1',False);AddBtn(P,102,56,132,44,'2',False);
 AddBtn(P,103,104,132,44,'3',False);AddBtn(P,115,152,132,44,'=',True);
 AddBtn(P,100,8,164,92,'0',False);AddBtn(P,110,104,164,44,'.',False);
 AddBtn(P,2,152,164,44,'Esc',False);
 RunWin(P);
End;

{ ====================================================================== }
{                       REPARTITION DES EVENEMENTS                       }
{ ====================================================================== }

Procedure HRep(P: PWin; Ev,A,B: Integer); Forward;
Procedure HGraph(P: PWin; Ev,A,B: Integer); Forward;

Procedure Dispatch(P: PWin; Ev,A,B: Integer);
Begin
 Case P^.Kind Of
  wkMsg: Case Ev Of
    evButton: Begin P^.Res:=A;P^.Done:=True;End;
    evClose: P^.Res:=P^.Aux;
   End;
  wkInput: Case Ev Of
    evButton: Begin
      If A=1 Then Begin
       Normalize(P,Ix(P,10));InStr:=GT(P,10);P^.Res:=1;
      End Else P^.Res:=0;
      P^.Done:=True;
     End;
    evClose: P^.Res:=0;
   End;
  wkSelect: Case Ev Of
    evButton: Begin
      If A=1 Then P^.Res:=P^.GRow Else P^.Res:=0;
      P^.Done:=True;
     End;
    evDbl: Begin P^.Res:=A;P^.Done:=True;End;
    evClose: P^.Res:=0;
   End;
  wkList: HList(P,Ev,A,B);
  wkAcct: HAcct(P,Ev,A,B);
  wkParty: HParty(P,Ev,A,B);
  wkEmp: HEmp(P,Ev,A,B);
  wkItem: HItem(P,Ev,A,B);
  wkPrj: HPrj(P,Ev,A,B);
  wkJournal: HJournal(P,Ev,A,B);
  wkInvoice: HInvoice(P,Ev,A,B);
  wkPay: HPay(P,Ev,A,B);
  wkPaych: HPaych(P,Ev,A,B);
  wkRun: HRun(P,Ev,A,B);
  wkRecon: HRecon(P,Ev,A,B);
  wkAdjust: HAdjust(P,Ev,A,B);
  wkAssem: HAssem(P,Ev,A,B);
  wkSetup: HSetup(P,Ev,A,B);
  wkRep: HRep(P,Ev,A,B);
  wkGraph: HGraph(P,Ev,A,B);
  wkCalc: HCalc(P,Ev,A,B);
 End;
End;

{ ====================================================================== }
{                RAPPORTS, GRAPHIQUES ET VISIONNEUSE                     }
{ ====================================================================== }

Procedure RAdd(Bold: Boolean; Const S: String);
Var T: String;
Begin
 If RN>=RMAX Then Exit;
 If Bold Then T:='*'+S Else T:=' '+S;
 Inc(RN);
 RL^[RN]:=T;
End;

Procedure RRule;
Begin
 If RN>=RMAX Then Exit;
 Inc(RN);
 RL^[RN]:='-';
End;

{ Ligne a deux colonnes de montants (col. 38..51 et 52..67) }
Procedure RRow(Bold: Boolean; Const Nm: String; Sh1,Sh2: Boolean; A1,
    A2: LongInt);
Var S: String;
Begin
 S:=Pad(Nm,38);
 If Sh1 Then S:=S+PadL(FmtMoney(A1),14) Else S:=S+'              ';
 If Sh2 Then S:=S+PadL(FmtMoney(A2),16);
 RAdd(Bold,S);
End;

Procedure RHeader(Const Ti: String);
Begin
 RN:=0;
 RTitle:=Ti;
 RAdd(True,SU.Co);
 RAdd(False,Ti+'  -  '+T3('au ','as at ','zum ')+FmtDate(SessDate));
 RAdd(False,'');
End;

Function MidNum(K: Integer): Integer;
Begin
 MidNum:=(SU.Rng[K].Lo+SU.Rng[K].Hi+1) Div 2;
End;

Function NetIncome: LongInt;
Var I: Integer; S: LongInt;
Begin
 S:=0;
 For I:=1 To NA Do Begin
  If Ac^[I].Kind=K_REV Then S:=S+DispBal(I);
  If Ac^[I].Kind In [K_COGS,K_EXP] Then S:=S-DispBal(I);
 End;
 NetIncome:=S;
End;

{ liste des comptes d'un genre dans une plage ; retourne le total }
Function RAccGroup(K,Lo,Hi: Integer): LongInt;
Var I: Integer; S: LongInt;
Begin
 S:=0;
 For I:=1 To NA Do
  If (Ac^[I].Kind=K) And (Ac^[I].Num>=Lo) And (Ac^[I].Num<=Hi) Then Begin
   RRow(False,'    '+IntStr(Ac^[I].Num)+' '+Ac^[I].Name,True,False,DispBal(I),
       0);
   S:=S+DispBal(I);
  End;
 RAccGroup:=S;
End;

Procedure RepBalance;
Var T1,T2,TA,TL,TE,Ne: LongInt; M: Integer;
Begin
 RHeader(T3('Bilan','Balance Sheet','Bilanz'));
 RAdd(True,T3('ACTIF','ASSETS','AKTIVA'));
 M:=MidNum(K_ASSET);
 RAdd(True,'  '+T3('ACTIF A COURT TERME','CURRENT ASSETS','UMLAUFVERM@2GEN'));
 T1:=RAccGroup(K_ASSET,0,M-1);
 RRow(True,'  '+T3('TOTAL ACTIF A COURT TERME','TOTAL CURRENT ASSETS',
     'SUMME UMLAUFVERM@2GEN'),False,True,0,T1);
 RAdd(False,'');
 RAdd(True,'  '+T3('IMMOBILISATIONS','FIXED ASSETS','ANLAGEVERM@2GEN'));
 T2:=RAccGroup(K_ASSET,M,9999);
 RRow(True,'  '+T3('TOTAL IMMOBILISATIONS','TOTAL FIXED ASSETS',
     'SUMME ANLAGEVERM@2GEN'),False,True,0,T2);
 RAdd(False,'');
 TA:=T1+T2;
 RRow(True,T3('TOTAL ACTIF','TOTAL ASSETS','SUMME AKTIVA'),False,True,0,TA);
 RAdd(False,'');
 RAdd(True,T3('PASSIF','LIABILITIES','PASSIVA'));
 M:=MidNum(K_LIAB);
 RAdd(True,'  '+T3('PASSIF A COURT TERME','CURRENT LIABILITIES',
     'KURZFR. VERBINDLICHKEITEN'));
 T1:=RAccGroup(K_LIAB,0,M-1);
 RRow(True,'  '+T3('TOTAL PASSIF A COURT TERME','TOTAL CURRENT LIABILITIES',
     'SUMME KURZFR. VERB.'),False,True,0,T1);
 RAdd(True,'  '+T3('PASSIF A LONG TERME','LONG TERM LIABILITIES',
     'LANGFR. VERBINDLICHKEITEN'));
 T2:=RAccGroup(K_LIAB,M,9999);
 RRow(True,'  '+T3('TOTAL PASSIF A LONG TERME','TOTAL LONG TERM LIABILITIES',
     'SUMME LANGFR. VERB.'),False,True,0,T2);
 TL:=T1+T2;
 RRow(True,T3('TOTAL PASSIF','TOTAL LIABILITIES','SUMME PASSIVA'),False,True,0,
     TL);
 RAdd(False,'');
 RAdd(True,T3('CAPITAL','EQUITY','EIGENKAPITAL'));
 TE:=RAccGroup(K_EQUITY,0,9999);
 Ne:=NetIncome;
 RRow(False,'    '+T3('B@en@efice de l''exercice','Current earnings',
     'Laufender Gewinn'),True,False,Ne,0);
 TE:=TE+Ne;
 RRow(True,T3('TOTAL CAPITAL','TOTAL EQUITY','SUMME EIGENKAPITAL'),False,True,0,
     TE);
 RAdd(False,'');
 RRow(True,T3('TOTAL PASSIF ET CAPITAL','TOTAL LIABILITIES AND EQUITY',
     'SUMME PASSIVA UND EIGENKAPITAL'),False,True,0,TL+TE);
End;

Procedure RepIncome;
Var TR,TC,TE: LongInt;
Begin
 RHeader(T3('@Etat des r@esultats','Income Statement',
     'Gewinn- und Verlustrechnung'));
 RAdd(True,T3('REVENUS','REVENUE','ERTR@1GE'));
 TR:=RAccGroup(K_REV,0,9999);
 RRow(True,T3('TOTAL REVENUS','TOTAL REVENUE','SUMME ERTR@1GE'),False,True,0,
     TR);
 RAdd(False,'');
 RAdd(True,T3('COUTS DIRECTS','DIRECT COSTS','WARENKOSTEN'));
 TC:=RAccGroup(K_COGS,0,9999);
 RRow(True,T3('TOTAL COUTS DIRECTS','TOTAL DIRECT COSTS','SUMME WARENKOSTEN'),
     False,True,0,TC);
 RAdd(False,'');
 RRow(True,T3('B@EN@EFICE BRUT','GROSS PROFIT','ROHGEWINN'),False,True,0,TR-TC);
 RAdd(False,'');
 RAdd(True,T3('D@EPENSES','EXPENSES','AUFWAND'));
 TE:=RAccGroup(K_EXP,0,9999);
 RRow(True,T3('TOTAL D@EPENSES','TOTAL EXPENSES','SUMME AUFWAND'),False,True,0,
     TE);
 RAdd(False,'');
 RRow(True,T3('B@EN@EFICE NET','NET INCOME','REINGEWINN'),False,True,0,
     TR-TC-TE);
End;

Procedure RepTrial;
Var I: Integer; TD,TC: LongInt; S: String;
Begin
 RHeader(T3('Balance de v@erification','Trial Balance','Saldenbilanz'));
 RAdd(True,Pad(T3('Compte','Account','Konto'),6)+Pad(' '+T3('Nom','Name',
     'Name'),34)+PadL(T3('D@ebit','Debit','Soll'),14)+PadL(T3('Cr@edit',
     'Credit','Haben'),14));
 RRule;
 TD:=0;TC:=0;
 For I:=1 To NA Do Begin
  S:=Pad(IntStr(Ac^[I].Num),6)+Pad(' '+Ac^[I].Name,34);
  If Ac^[I].Bal>=0 Then Begin
    S:=S+PadL(FmtMoney(Ac^[I].Bal),14);TD:=TD+Ac^[I].Bal;End
  Else Begin
    S:=S+'              '+PadL(FmtMoney(-Ac^[I].Bal),14);TC:=TC-Ac^[I].Bal;End;
  RAdd(False,S);
 End;
 RRule;
 RAdd(True,Pad('',40)+PadL(FmtMoney(TD),14)+PadL(FmtMoney(TC),14));
End;

Procedure RepJournal;
Var J,Last: Integer; Id: LongInt; S: String;
Begin
 RHeader(T3('Journal g@en@eral','General Journal Entries','Hauptjournal'));
 Id:=-1;
 For J:=1 To NJ Do Begin
  If Jl^[J].Id<>Id Then Begin
   Id:=Jl^[J].Id;
   RAdd(True,
       '#'+IntStr(Id)+'  '+FmtDate(Jl^[J].Dt)+'  '+Jl^[J].Src+'  '+Jl^[J].Cm);
  End;
  S:='   '+Pad(IntStr(Jl^[J].Acc),6)+Pad(AccName(Jl^[J].Acc),30);
  If Jl^[J].Dr<>0 Then S:=S+PadL(FmtMoney(Jl^[J].Dr),14) Else
    S:=S+'              ';
  If Jl^[J].Cr<>0 Then S:=S+PadL(FmtMoney(Jl^[J].Cr),14);
  RAdd(False,S);
 End;
 If NJ=0 Then
   RAdd(False,T3('(aucune @ecriture)','(no entries)','(keine Buchungen)'));
End;

Procedure RepChart;
Var I: Integer;
Begin
 RHeader(T3('Plan comptable','Chart of Accounts','Kontenplan'));
 RAdd(True,Pad(T3('Compte','Account','Konto'),8)+Pad(T3('Nom','Name','Name'),
     34)+Pad('Type',12)+PadL(T3('Solde','Balance','Saldo'),14));
 RRule;
 For I:=1 To NA Do
  RAdd(False,Pad(IntStr(Ac^[I].Num),8)+Pad(Ac^[I].Name,
      34)+Pad(KindName(Ac^[I].Kind),12)+PadL(FmtMoney(DispBal(I)),14));
End;

Function AgeBucket(I: Integer): Integer;
Var Late: LongInt;
Begin
 Late:=DayNum(SessDate)-DayNum(DueDate(I));
 If Late<=0 Then AgeBucket:=1
 Else If Late<=30 Then AgeBucket:=2
 Else If Late<=60 Then AgeBucket:=3
 Else AgeBucket:=4;
End;

Procedure RepAged(Typ: Integer);
Var P,I,B,N: Integer; Tot: Array[1..4] Of LongInt; GT_: Array[1..4] Of
  LongInt; S: String;
    PA: PPartyArr; Any: Boolean; O: LongInt;
Begin
 If Typ=1 Then Begin
  RHeader(T3('Fournisseurs - factures impay@ees','Aged Payables Detail',
      'Offene Lieferantenrechnungen'));PA:=Vn;N:=NV;
 End Else Begin
  RHeader(T3('Clients - factures impay@ees','Aged Receivables Detail',
      'Offene Kundenrechnungen'));PA:=Cu;N:=NC_;
 End;
 RAdd(True,Pad(T3('Facture','Invoice','Rechnung'),12)+Pad('Date',
     11)+PadL(T3('Courant','Current','Aktuell'),11)
  +PadL('1-30',11)+PadL('31-60',11)+PadL('61+',11));
 RRule;
 For B:=1 To 4 Do GT_[B]:=0;
 For P:=1 To N Do Begin
  Any:=False;
  For B:=1 To 4 Do Tot[B]:=0;
  For I:=1 To NIv Do
   If (Iv^[I].Typ=Typ) And (Iv^[I].Party=P) And (Owing(I)<>0) Then Begin
    If Not Any Then Begin RAdd(True,PA^[P].Name);Any:=True;End;
    B:=AgeBucket(I);O:=Owing(I);
    S:='  '+Pad(Iv^[I].No,10)+Pad(FmtDate(Iv^[I].Date),11);
    S:=S+Pad('',(B-1)*11)+PadL(FmtMoney(O),11);
    RAdd(False,S);
    Tot[B]:=Tot[B]+O;GT_[B]:=GT_[B]+O;
   End;
  If Any Then
   RAdd(True,'  '+Pad(T3('Total','Total','Summe'),21)+PadL(FmtMoney(Tot[1]),
       11)+PadL(FmtMoney(Tot[2]),11)+PadL(FmtMoney(Tot[3]),
       11)+PadL(FmtMoney(Tot[4]),11));
 End;
 RRule;
 RAdd(True,Pad(T3('TOTAL G@EN@ERAL','GRAND TOTAL','GESAMTSUMME'),
     23)+PadL(FmtMoney(GT_[1]),11)+PadL(FmtMoney(GT_[2]),
     11)+PadL(FmtMoney(GT_[3]),11)+PadL(FmtMoney(GT_[4]),11));
End;

Procedure RepEmployees;
Var I: Integer;
Begin
 RHeader(T3('Liste des employ@es','Employee List','Mitarbeiterliste'));
 RAdd(True,Pad(T3('Nom','Name','Name'),32)+PadL(T3('Taux','Rate','Satz'),
     12)+PadL(T3('Heures','Hours','Stunden'),10)+PadL(T3('Cumul','YTD','Summe'),
     14));
 RRule;
 For I:=1 To NE Do
  RAdd(False,Pad(Em^[I].Name,32)+PadL(FmtMoney(Em^[I].Rate),
      12)+PadL(FmtQty(Em^[I].Hrs),10)+PadL(FmtMoney(Em^[I].Ytd),14));
End;

Procedure RepInventory;
Var I: Integer; V,T: LongInt;
Begin
 RHeader(T3('Liste d''inventaire','Inventory List','Lagerliste'));
 RAdd(True,Pad(T3('Code','Code','Code'),11)+Pad('Description',
     25)+PadL(T3('Qt@e','Qty','Menge'),9)+PadL(T3('Co@ut','Cost','Kosten'),
     11)+PadL(T3('Valeur','Value','Wert'),12));
 RRule;
 T:=0;
 For I:=1 To NI Do Begin
  If It^[I].Svc Then
   RAdd(False,Pad(It^[I].Code,11)+Pad(It^[I].Desc,25)+PadL('-',
       9)+PadL(FmtMoney(It^[I].Price),11)+PadL('',12))
  Else Begin
   V:=MulQ(It^[I].Qty,It^[I].Cost);T:=T+V;
   RAdd(False,Pad(It^[I].Code,11)+Pad(It^[I].Desc,25)+PadL(FmtQty(It^[I].Qty),
       9)+PadL(FmtMoney(It^[I].Cost),11)+PadL(FmtMoney(V),12));
  End;
 End;
 RRule;
 RAdd(True,Pad(T3('Valeur totale','Total value','Gesamtwert'),45)+PadL('',
     9)+PadL(FmtMoney(T),23));
End;

Procedure RepSummary;
Var I: Integer; Ar,Ap: LongInt; N,Od: Integer;
Begin
 RHeader(T3('R@esum@e de la soci@et@e','Company Summary','Firmen@3bersicht'));
 RAdd(True,T3('Comptes bancaires','Bank accounts','Bankkonten'));
 For I:=1 To NA Do If Ac^[I].Bank Then
  RAdd(False,'  '+Pad(IntStr(Ac^[I].Num)+' '+Ac^[I].Name,
      40)+PadL(FmtMoney(DispBal(I)),16));
 Ar:=0;Ap:=0;Od:=0;
 For I:=1 To NIv Do Begin
  If Iv^[I].Typ=2 Then Ar:=Ar+Owing(I) Else Ap:=Ap+Owing(I);
  If (Owing(I)>0) And (DueDate(I)<SessDate) Then Inc(Od);
 End;
 RAdd(False,'');
 RAdd(False,Pad(T3('Comptes clients','Receivables','Forderungen'),
     42)+PadL(FmtMoney(Ar),16));
 RAdd(False,Pad(T3('Comptes fournisseurs','Payables','Verbindlichkeiten'),
     42)+PadL(FmtMoney(Ap),16));
 RAdd(False,Pad(T3('B@en@efice net de l''exercice','Net income to date',
     'Reingewinn bisher'),42)+PadL(FmtMoney(NetIncome),16));
 Ar:=0;
 For I:=1 To NI Do If Not It^[I].Svc Then Ar:=Ar+MulQ(It^[I].Qty,It^[I].Cost);
 RAdd(False,Pad(T3('Valeur de l''inventaire','Inventory value','Lagerwert'),
     42)+PadL(FmtMoney(Ar),16));
 RAdd(False,'');
 RAdd(False,Pad(T3('Factures en retard','Overdue invoices',
     'F@1llige Rechnungen'),42)+PadL(IntStr(Od),16));
 RAdd(False,Pad(T3('Nombre d''@ecritures','Journal entries','Buchungen'),
     42)+PadL(IntStr(SU.NextJ),16));
End;

Procedure RepReminders;
Var I,Cnt: Integer; S: String;
Begin
 RHeader(T3('Rappels','Reminders','Erinnerungen'));
 Cnt:=0;
 For I:=1 To NIv Do
  If (Owing(I)>0) And (DayNum(DueDate(I))<=DayNum(SessDate)+7) Then Begin
   If Iv^[I].Typ=1 Then S:=T3('Payer ','Pay ','Zahlen: ')+Vn^[Iv^[I].Party].Name
   Else S:=T3('Relancer ','Collect from ','Mahnen: ')+Cu^[Iv^[I].Party].Name;
   RAdd(False,Pad(S,40)+Pad(Iv^[I].No,10)+Pad(FmtDate(DueDate(I)),
       12)+PadL(FmtMoney(Owing(I)),12));
   Inc(Cnt);
  End;
 If Cnt=0 Then
   RAdd(False,T3('Aucun rappel.','No reminders.','Keine Erinnerungen.'));
End;

Procedure RepVerify;
Var J,I: Integer; D,C,Sv: LongInt;
Begin
 RHeader(T3('V@erification des donn@ees','Data Integrity Check',
     'Datenpr@3fung'));
 D:=0;C:=0;
 For J:=1 To NJ Do Begin D:=D+Jl^[J].Dr;C:=C+Jl^[J].Cr;End;
 If D=C Then
   RAdd(False,'OK  '+T3('Le journal est @equilibr@e : ',
     'The journal is balanced: ','Das Journal ist ausgeglichen: ')+FmtMoney(D))
 Else
   RAdd(True,'ERR '+T3('Journal d@es@equilibr@e : ','Journal out of balance: ',
     'Journal nicht ausgeglichen: ')+FmtMoney(D-C));
 Sv:=0;For I:=1 To NIv Do If Iv^[I].Typ=1 Then Sv:=Sv+Owing(I);
 I:=FindAcc(LinkAcc(LK_AP));
 If (I>0) And (DispBal(I)=Sv) Then
   RAdd(False,'OK  '+T3('Fournisseurs = compte g@en@eral',
     'Vendors = general ledger','Lieferanten = Hauptbuch'))
 Else
   RAdd(True,'ERR '+T3('Fournisseurs @ differ@e du compte g@en@eral',
     'Vendors differ from general ledger',
     'Lieferanten weichen vom Hauptbuch ab'));
 Sv:=0;For I:=1 To NIv Do If Iv^[I].Typ=2 Then Sv:=Sv+Owing(I);
 I:=FindAcc(LinkAcc(LK_AR));
 If (I>0) And (DispBal(I)=Sv) Then
   RAdd(False,'OK  '+T3('Clients = compte g@en@eral',
     'Customers = general ledger','Kunden = Hauptbuch'))
 Else
   RAdd(True,'ERR '+T3('Clients diff@erent du compte g@en@eral',
     'Customers differ from general ledger','Kunden weichen vom Hauptbuch ab'));
 C:=0;
 For I:=1 To NI Do If Not It^[I].Svc Then C:=C+MulQ(It^[I].Qty,It^[I].Cost);
 RAdd(False,'    '+T3('Valeur de l''inventaire (info) : ',
     'Inventory value (info): ','Lagerwert (Info): ')+FmtMoney(C));
 RAdd(False,'    '+IntStr(NA)+' '+T3('comptes, ','accounts, ',
     'Konten, ')+IntStr(NJ)+' '+T3('lignes de journal','journal lines',
     'Journalzeilen'));
End;

Procedure RepHelp;
Begin
 RN:=0;
 RTitle:=T3('Aide','Help','Hilfe');
 RAdd(True,'Sample Accounting - '+T3('Aide','Help','Hilfe'));
 RAdd(False,'');
 RAdd(False,
     T3('Cliquez sur une ic@one de la fen@etre principale pour ouvrir un '+
     'module.','Click an icon in the main window to open a module.',
     'Klicken Sie auf ein Symbol im Hauptfenster, um ein Modul zu @2ffnen.'));
 RAdd(False,'');
 RAdd(True,T3('Clavier','Keyboard','Tastatur'));
 RAdd(False,T3('  Alt+lettre / F10  Ouvre un menu',
     '  Alt+letter / F10  Opens a menu',
     '  Alt+Buchstabe / F10  @5ffnet ein Men@3'));
 RAdd(False,T3('  Fl@eches / Entr@ee Se d@eplacer dans les ic@ones',
     '  Arrows / Enter    Move through the icons',
     '  Pfeile / Eingabe     In den Symbolen navigieren'));
 RAdd(False,T3('  Tab / Maj+Tab     Champ suivant / pr@ec@edent',
     '  Tab / Shift+Tab   Next / previous field',
     '  Tab / Umschalt+Tab   N@1chstes / voriges Feld'));
 RAdd(False,T3('  F4 ou double-clic Liste de choix (compte, article)',
     '  F4 or double-click  Lookup (account, item)',
     '  F4 oder Doppelklick  Auswahl (Konto, Artikel)'));
 RAdd(False,T3('  F2                Modifier la cellule',
     '  F2                Edit the cell',
     '  F2                Zelle bearbeiten'));
 RAdd(False,T3('  Ctrl+S / Ctrl+O   Enregistrer / Ouvrir',
     '  Ctrl+S / Ctrl+O   Save / Open',
     '  Strg+S / Strg+O   Speichern / @5ffnen'));
 RAdd(False,'');
 RAdd(True,T3('Comptabilit@e','Accounting','Buchhaltung'));
 RAdd(False,T3('  Toute transaction passe par le journal g@en@eral : chaque',
     '  Every transaction goes through the general journal: each',
     '  Jede Buchung l@1uft @3ber das Hauptjournal: jede'));
 RAdd(False,T3('  @ecriture doit @etre @equilibr@ee (d@ebits = cr@edits).',
     '  entry must balance (debits = credits).',
     '  Buchung muss ausgeglichen sein (Soll = Haben).'));
 RAdd(False,T3('  Les factures cr@eent des soldes de fournisseurs/clients',
     '  Invoices create vendor/customer balances that are',
     '  Rechnungen erzeugen Lieferanten-/Kundensalden, die'));
 RAdd(False,T3('  r@egl@es par les modules Paiements et Encaissements.',
     '  settled by the Payments and Receipts modules.',
     '  durch Zahlungen und Zahlungseing@1nge beglichen werden.'));
 RAdd(False,T3('  Les comptes d''int@egration se r@eglent dans Param@etres.',
     '  Linked accounts are set up in Setup.',
     '  Verkn@3pfte Konten werden in den Einstellungen festgelegt.'));
End;

{ apercu de l'ecriture (bouton Distribuer) }
Procedure PostPreview;
Var I: Integer; S: String;
Begin
 RN:=0;
 RTitle:=T3('Distribution','Distribution','Verteilung');
 RAdd(True,T3('Distribution de la transaction','Transaction distribution',
     'Verteilung der Buchung'));
 RAdd(False,'');
 RAdd(True,Pad(T3('Compte','Account','Konto'),8)+Pad(T3('Nom','Name','Name'),
     30)+PadL(T3('D@ebit','Debit','Soll'),14)+PadL(T3('Cr@edit','Credit',
     'Haben'),14));
 RRule;
 For I:=1 To PN Do Begin
  S:=Pad(IntStr(PL[I].Acc),8)+Pad(AccName(PL[I].Acc),30);
  If PL[I].Dr<>0 Then S:=S+PadL(FmtMoney(PL[I].Dr),14) Else
    S:=S+'              ';
  If PL[I].Cr<>0 Then S:=S+PadL(FmtMoney(PL[I].Cr),14);
  RAdd(False,S);
 End;
 RRule;
 RAdd(True,Pad('',38)+PadL(FmtMoney(PSumDr),14)+PadL(FmtMoney(PSumCr),14));
 ShowReport(RTitle);
End;

Procedure RWrap(Const S: String; W: Integer);
Var T: String; K: Integer;
Begin
 T:=S;
 While Length(T)>W Do Begin
  K:=W;
  While (K>10) And (T[K]<>' ') Do Dec(K);
  RAdd(False,Copy(T,1,K));
  Delete(T,1,K);
 End;
 If T<>'' Then RAdd(False,T);
End;

Procedure PrintInv(P: PWin);
Var D,Tot: LongInt; Pt,R: Integer; S: String; Sub,Frt,Tax: LongInt;
Begin
 Pt:=GS(P,10);
 If (Pt<1) Or (Pt>NC_) Then Begin
   Info(T3('Choisissez un client.','Select a customer.',
     'W@1hlen Sie einen Kunden.'));Exit;End;
 D:=DateOrToday(GT(P,13));
 RN:=0;RTitle:=T3('Facture','Invoice','Rechnung');
 RAdd(True,SU.Co);RAdd(False,SU.Ad1);RAdd(False,SU.Ad2);RAdd(False,'');
 RAdd(True,T3('FACTURE no ','INVOICE No. ','RECHNUNG Nr. ')+GT(P,
     12)+'     '+FmtDate(D));
 RAdd(False,'');
 RAdd(False,T3('Factur@e @a :','Bill to:','Rechnung an:'));
 RAdd(False,'  '+Cu^[Pt].Name);RAdd(False,'  '+Cu^[Pt].Ad1);
 RAdd(False,'  '+Cu^[Pt].Ad2);
 RAdd(False,'');
 RAdd(True,Pad(T3('Article','Item','Artikel'),10)+PadL(T3('Qt@e','Qty','Menge'),
     8)+' '+Pad('Description',26)+PadL(T3('Prix','Price','Preis'),
     10)+PadL(T3('Montant','Amount','Betrag'),12));
 RRule;
 Sub:=0;
 For R:=1 To P^.GN Do
  If ParseMoney(P^.GCell[R,6])<>0 Then Begin
   RAdd(False,Pad(P^.GCell[R,1],10)+PadL(P^.GCell[R,2],8)+' '+Pad(P^.GCell[R,4],
       26)+PadL(P^.GCell[R,5],10)+PadL(P^.GCell[R,6],12));
   Sub:=Sub+ParseMoney(P^.GCell[R,6]);
  End;
 RRule;
 Frt:=GMoney(P,20);Tax:=0;
 If Cu^[Pt].Tax Then Tax:=PctOf(Sub+Frt,SU.Gst);
 Tot:=Sub+Frt+Tax;
 RAdd(False,Pad(T3('Sous-total','Subtotal','Zwischensumme'),
     50)+PadL(FmtMoney(Sub),16));
 RAdd(False,Pad(T3('Transport','Freight','Fracht'),50)+PadL(FmtMoney(Frt),16));
 RAdd(False,Pad(T3('TPS','GST','USt'),50)+PadL(FmtMoney(Tax),16));
 RAdd(True,Pad('Total',50)+PadL(FmtMoney(Tot),16));
 RAdd(False,'');
 S:=SU.Msg[Lang];
 If S<>'' Then Begin
  RWrap(S,66);
 End;
 ShowReport(RTitle);
End;

{ ---- visionneuse ---- }

Procedure DrawRepText(P: PWin; I,AX,AY: Integer);
Var W,H,Vis,L,N,Ch: Integer; S: String;
Begin
 W:=P^.Ctl[I].W;H:=P^.Ctl[I].H;
 Sunken(AX,AY,AX+W-1,AY+H-1,cWht);
 Vis:=(H-6) Div 10;
 Ch:=(W-16-10) Div 8;
 For L:=1 To Vis Do Begin
  N:=P^.GTop+L;
  If N<=RN Then Begin
   S:=RL^[N];
   If S='-' Then Ln(AX+6,AY+6+(L-1)*10,AX+W-22,AY+6+(L-1)*10,cDGr)
   Else Begin
    If Length(S)>Ch+1 Then S:=Copy(S,1,Ch+1);
    If S[1]='*' Then TxB(AX+6,AY+3+(L-1)*10,Copy(S,2,255),cBlk)
    Else Tx(AX+6,AY+3+(L-1)*10,Copy(S,2,255),cBlk);
   End;
  End;
 End;
 SDrawVScroll(AX+W-17,AY+2,AX+W-2,AY+H-3,P^.GTop,Vis,RN);
End;

Procedure RepClamp(P: PWin; Vis: Integer);
Begin
 If P^.GTop>RN-Vis Then P^.GTop:=RN-Vis;
 If P^.GTop<0 Then P^.GTop:=0;
 DirtyTop:=True;
End;

Function RepKey(P: PWin; K: Word): Boolean;
Var Vis: Integer;
Begin
 RepKey:=True;
 Vis:=(P^.Ctl[P^.Foc].H-6) Div 10;
 Case K Of
  K_UP: Dec(P^.GTop);
  K_DOWN: Inc(P^.GTop);
  K_PGUP: P^.GTop:=P^.GTop-Vis;
  K_PGDN: P^.GTop:=P^.GTop+Vis;
  K_HOME: P^.GTop:=0;
  K_END: P^.GTop:=RN;
  Else RepKey:=False;
 End;
 RepClamp(P,Vis);
End;

Procedure RepMouse(P: PWin; I,X,Y: Integer);
Var AX,AY,W,H,Vis: Integer;
Begin
 AX:=P^.X+3+P^.Ctl[I].X;AY:=P^.Y+22+P^.Ctl[I].Y;
 W:=P^.Ctl[I].W;H:=P^.Ctl[I].H;
 Vis:=(H-6) Div 10;
 If X>=AX+W-17 Then Begin
  If Y<AY+18 Then Dec(P^.GTop)
  Else If Y>AY+H-19 Then Inc(P^.GTop)
  Else If Y<AY+18+LongInt(H-36)*P^.GTop Div Max2(1,RN) Then P^.GTop:=P^.GTop-Vis
  Else P^.GTop:=P^.GTop+Vis;
  RepClamp(P,Vis);
 End;
End;

Procedure HRep(P: PWin; Ev,A,B: Integer);
Var F: Text; I: Integer; S: String; Ok: Boolean;
Begin
 Case Ev Of
  evButton: Case A Of
   31: Begin
     S:='REPORT.TXT';
     If InputBox(T3('Enregistrer le rapport','Save report','Bericht speichern'),
         T3('Nom du fichier texte :','Text file name:','Name der Textdatei:'),S,
         40,0) Then Begin
      Assign(F,S);
      {$I-}
      Rewrite(F);
      {$I+}
      Ok:=IOResult=0;
      If Ok Then Begin
       For I:=1 To RN Do Begin
        If RL^[I]='-' Then
          WriteLn(F,
            '---------------------------------'+
            '---------------------------------')
        Else WriteLn(F,Copy(RL^[I],2,255));
       End;
       Close(F);
       Info(T3('Rapport enregistr@e dans ','Report saved to ',
           'Bericht gespeichert in ')+S);
      End Else
        Info(T3('Impossible d''@ecrire le fichier.','Cannot write the file.',
          'Datei kann nicht geschrieben werden.'));
     End;
    End;
   2: Begin P^.Res:=0;P^.Done:=True;End;
  End;
  evClose: P^.Res:=0;
 End;
End;

Procedure ShowReport(Const Ti: String);
Var P: PWin; I: Integer;
Begin
 P:=NewWin(wkRep,Ti,616,440);
 I:=AddCtl(P,ckText,10,8,8,586,350,'');
 AddBtn(P,31,8,364,270,T3('Enregistrer en fichier texte...',
     'Save as text file...','Als Textdatei speichern...'),False);
 AddBtn(P,2,494,364,100,T3('Fermer','Close','Schlie@7en'),True);
 RunWin(P);
End;

{ ---- graphiques ---- }

Procedure DrawChart(AX,AY,Wd,Ht: Integer);
Var I,BW,Gap,PTop,PBot,PH,Y0,X,H,N,LX,LY: Integer; Mx,Mn,Rg,V: Real; S: String;
Const Cols: Array[1..12] Of Byte = (9,12,10,14,11,13,3,4,2,5,6,1);
Begin
 Sunken(AX,AY,AX+Wd-1,AY+Ht-1,cWht);
 TxB(AX+10,AY+8,GBTitle,cBlk);
 If GBN<1 Then Begin
  Tx(AX+10,AY+40,T3('Aucune donn@ee @a afficher.','No data to display.',
      'Keine Daten vorhanden.'),cDGr);Exit;
 End;
 Mx:=0;Mn:=0;
 For I:=1 To GBN Do Begin
  V:=GBVal[I];
  If V>Mx Then Mx:=V;
  If V<Mn Then Mn:=V;
 End;
 Rg:=Mx-Mn;
 If Rg<1 Then Rg:=1;
 PTop:=AY+30;PBot:=AY+Ht-36;PH:=PBot-PTop;
 V:=Mx;Y0:=PTop+Round(V*PH/Rg);
 Ln(AX+14,PTop-4,AX+14,PBot+4,cDGr);
 Ln(AX+14,Y0,AX+14+360,Y0,cBlk);
 N:=GBN;
 BW:=330 Div N;
 If BW>56 Then BW:=56;
 Gap:=BW Div 6;
 If Gap<2 Then Gap:=2;
 For I:=1 To GBN Do Begin
  X:=AX+20+(I-1)*BW;
  V:=GBVal[I];
  H:=Round(Abs(V)*PH/Rg);
  If V>=0 Then Begin
   Bx(X,Y0-H,X+BW-Gap-1,Y0,Cols[I]);
   SetColor(cBlk);Rectangle(X,Y0-H,X+BW-Gap-1,Y0);
  End Else Begin
   Bx(X,Y0,X+BW-Gap-1,Y0+H,Cols[I]);
   SetColor(cBlk);Rectangle(X,Y0,X+BW-Gap-1,Y0+H);
  End;
  S:=IntStr(I);
  Tx(X+(BW-Gap-Length(S)*8) Div 2,PBot+12,S,cBlk);
 End;
 LX:=AX+400;LY:=AY+34;
 For I:=1 To GBN Do Begin
  Bx(LX,LY,LX+10,LY+10,Cols[I]);
  SetColor(cBlk);Rectangle(LX,LY,LX+10,LY+10);
  Tx(LX+16,LY+1,IntStr(I)+' '+GBLbl[I],cBlk);
  S:=FmtMoney(GBVal[I]);
  Tx(LX+16,LY+12,PadL(S,20),cDGr);
  LY:=LY+26;
 End;
End;

Procedure HGraph(P: PWin; Ev,A,B: Integer);
Begin
 If (Ev=evButton) Or (Ev=evClose) Then Begin P^.Res:=0;P^.Done:=True;End;
End;

Procedure ShowGraph(Const Ti: String);
Var P: PWin;
Begin
 GBTitle:=Ti;
 P:=NewWin(wkGraph,Ti,616,420);
 AddCtl(P,ckGraph,10,8,8,586,340,'');
 AddBtn(P,2,494,354,100,T3('Fermer','Close','Schlie@7en'),True);
 RunWin(P);
End;

Procedure GraphRevExp;
Var I: Integer; R,C,E: LongInt;
Begin
 R:=0;C:=0;E:=0;
 For I:=1 To NA Do Begin
  If Ac^[I].Kind=K_REV Then R:=R+DispBal(I);
  If Ac^[I].Kind=K_COGS Then C:=C+DispBal(I);
  If Ac^[I].Kind=K_EXP Then E:=E+DispBal(I);
 End;
 GBN:=4;
 GBLbl[1]:=Copy(KindName(K_REV),1,10);GBVal[1]:=R;
 GBLbl[2]:=Copy(KindName(K_COGS),1,10);GBVal[2]:=C;
 GBLbl[3]:=Copy(KindName(K_EXP),1,10);GBVal[3]:=E;
 GBLbl[4]:=Copy(T3('B@en@efice','Net income','Gewinn'),1,10);GBVal[4]:=R-C-E;
 ShowGraph(T3('Revenus et d@epenses','Revenues and Expenses',
     'Ertr@1ge und Aufwand'));
End;

Procedure GraphByKind(Kd1,Kd2: Integer; Const Ti: String);
Var I,J,K,Best: Integer; Used: Array[1..MAXACC] Of Boolean; V,Bv: LongInt;
Begin
 FillChar(Used,SizeOf(Used),0);
 GBN:=0;
 For K:=1 To 10 Do Begin
  Best:=0;Bv:=0;
  For I:=1 To NA Do
   If (Not Used[I]) And ((Ac^[I].Kind=Kd1) Or (Ac^[I].Kind=Kd2))
       And (DispBal(I)>Bv) Then Begin
    Best:=I;Bv:=DispBal(I);
   End;
  If Best>0 Then Begin
   Used[Best]:=True;Inc(GBN);GBLbl[GBN]:=Copy(Ac^[Best].Name,1,10);
   GBVal[GBN]:=Bv;
  End;
 End;
 ShowGraph(Ti);
End;

Procedure ShowReportNow;
Begin
 ShowReport(RTitle);
End;

{ ====================================================================== }
{                   FENETRE PRINCIPALE ET ICONES                         }
{ ====================================================================== }

Const
 TOOL_Y   = 36;
 TASK_Y   = 456;
 STAT_Y   = 438;
 PCOLW    = 102;
 PROWH    = 84;

Var
 MT    : Array[1..NMENU] Of String[24];
 MLb   : Array[1..NMENU,1..14] Of String[36];
 MCm   : Array[1..NMENU,1..14] Of Integer;
 MCnt  : Array[1..NMENU] Of Integer;

Procedure MAdd(M: Integer; Const Lb: String; Cm: Integer);
Begin
 Inc(MCnt[M]);
 MLb[M,MCnt[M]]:=Lb;
 MCm[M,MCnt[M]]:=Cm;
End;

Procedure BuildMenus;
Begin
 FillChar(MCnt,SizeOf(MCnt),0);
 MT[1]:=T3('&Fichier','&File','&Datei');
 MT[2]:=T3('&Edition','Edi&t','&Bearbeiten');
 MT[3]:=T3('&Vue','&View','&Ansicht');
 MT[4]:=T3('&Param@etres','&Setup','&Setup');
 MT[5]:=T3('&Assistant','&Business Assistant','Assi&stent');
 MT[6]:=T3('En&tretien','&Maintenance','&Wartung');
 MT[7]:=T3('&Graphiques','&Graphs','&Grafiken');
 MT[8]:=T3('&Rapports','&Reports','Be&richte');
 MT[9]:=T3('Ai&de','&Help','&Hilfe');
 MAdd(1,T3('Nouvelle soci@et@e...','New company...','Neue Firma...'),1);
 MAdd(1,T3('Ouvrir...|Ctrl+O','Open...|Ctrl+O','@5ffnen...|Strg+O'),2);
 MAdd(1,T3('Enregistrer|Ctrl+S','Save|Ctrl+S','Speichern|Strg+S'),3);
 MAdd(1,T3('Enregistrer sous...','Save as...','Speichern unter...'),4);
 MAdd(1,T3('Copie de s@ecurit@e (.BAK)','Backup copy (.BAK)',
     'Sicherungskopie (.BAK)'),5);
 MAdd(1,'-',0);
 MAdd(1,T3('Quitter','Exit','Beenden'),6);
 MAdd(2,T3('Comptes...','Accounts...','Konten...'),10);
 MAdd(2,T3('Fournisseurs...','Vendors...','Lieferanten...'),13);
 MAdd(2,T3('Clients...','Customers...','Kunden...'),16);
 MAdd(2,T3('Employ@es...','Employees...','Mitarbeiter...'),19);
 MAdd(2,T3('Inventaire et services...','Inventory & Services...',
     'Lager und Dienste...'),22);
 MAdd(2,T3('Projets...','Projects...','Projekte...'),25);
 MAdd(3,T3('Barre d''outils','Toolbar','Symbolleiste'),30);
 MAdd(3,T3('Barre d''@etat','Status bar','Statusleiste'),31);
 MAdd(3,'-',0);
 MAdd(3,T3('Date de session...','Session date...','Sitzungsdatum...'),32);
 MAdd(4,T3('Num@eros de compte...','Account numbers...','Kontonummern...'),40);
 MAdd(4,T3('Comptes d''int@egration...','Linked accounts...',
     'Verkn@3pfte Konten...'),41);
 MAdd(4,T3('Taxes et paie...','Taxes and payroll...','Steuern und Lohn...'),42);
 MAdd(4,T3('Soci@et@e...','Company...','Firma...'),43);
 MAdd(5,T3('R@esum@e de la soci@et@e','Company summary','Firmen@3bersicht'),50);
 MAdd(5,T3('Rappels','Reminders','Erinnerungen'),52);
 MAdd(5,T3('Calculatrice','Calculator','Rechner'),51);
 MAdd(6,T3('V@erifier les donn@ees','Check data integrity','Daten pr@3fen'),60);
 MAdd(6,T3('Cl@oturer l''exercice...','Close fiscal year...',
     'Gesch@1ftsjahr abschlie@7en...'),61);
 MAdd(6,'-',0);
 MAdd(6,T3('Copie de s@ecurit@e (.BAK)','Backup copy (.BAK)',
     'Sicherungskopie (.BAK)'),5);
 MAdd(7,T3('Revenus et d@epenses','Revenues and expenses',
     'Ertr@1ge und Aufwand'),70);
 MAdd(7,T3('D@epenses par compte','Expenses by account','Aufwand je Konto'),71);
 MAdd(7,T3('Actif par compte','Assets by account','Aktiva je Konto'),72);
 MAdd(8,T3('Bilan','Balance Sheet','Bilanz'),80);
 MAdd(8,T3('@Etat des r@esultats','Income Statement','GuV-Rechnung'),81);
 MAdd(8,T3('Balance de v@erification','Trial Balance','Saldenbilanz'),82);
 MAdd(8,T3('Journal g@en@eral','General Journal','Hauptjournal'),83);
 MAdd(8,T3('Plan comptable','Chart of Accounts','Kontenplan'),84);
 MAdd(8,'-',0);
 MAdd(8,T3('Fournisseurs impay@es','Aged Payables','Offene Lieferanten'),85);
 MAdd(8,T3('Clients impay@es','Aged Receivables','Offene Kunden'),86);
 MAdd(8,'-',0);
 MAdd(8,T3('Liste des employ@es','Employee list','Mitarbeiterliste'),87);
 MAdd(8,T3('Liste d''inventaire','Inventory list','Lagerliste'),88);
 MAdd(9,T3('Aide|F1','Contents|F1','Inhalt|F1'),90);
 MAdd(9,T3('Raccourcis clavier','Keyboard shortcuts','Tastenk@3rzel'),90);
 MAdd(9,'-',0);
 MAdd(9,T3('A propos de Sample Accounting...','About Sample Accounting...',
     '@3ber Sample Accounting...'),92);
End;

Function MenuChecked(Cm: Integer): Boolean;
Begin
 MenuChecked:=False;
 If Cm=30 Then MenuChecked:=ToolBarOn;
 If Cm=31 Then MenuChecked:=StatusOn;
End;

Function MenuMnem(M: Integer): Char;
Var P: Integer;
Begin
 P:=Pos('&',MT[M]);
 If (P>0) And (P<Length(MT[M])) Then MenuMnem:=UpCase(MT[M][P+1]) Else
   MenuMnem:=#0;
End;

{ libelle de PM : '&' -> '~', '|raccourci' -> tabulation }
Function PmMenuText(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do If S[I]='&' Then S[I]:='~';
 I:=Pos('|',S);
 If I>0 Then S[I]:=#9;
 PmMenuText:=S;
End;

{ barre de menus de PM construite a partir des menus d'origine : choix I
  du menu M = identificateur 100 + 16 * M + I ; sous-menu M = 900 + M }
Procedure BuildMenuBar;
Var M,I,H0,H1: Integer;
Begin
 MenuLen:=0;
 MnemoKeys:='';
 H0:=MnOpen;
 For M:=1 To NMENU Do Begin
  MnemoKeys:=MnemoKeys+MenuMnem(M);
  MnItem(MIS_TEXT Or MIS_SUBMENU,0,900+M,PmMenuText(MT[M]));
  H1:=MnOpen;
  For I:=1 To MCnt[M] Do
   If MLb[M,I]='-' Then MnItem(MIS_SEPARATOR,0,100+16*M+I,'')
   Else MnItem(MIS_TEXT,0,100+16*M+I,PmMenuText(MLb[M,I]));
  MnClose(H1,MCnt[M]);
 End;
 MnClose(H0,NMENU);
 OsMenu:=WinCreateMenu(OsFrame,LongInt(@MenuT));
End;

{ ouverture d'un menu : coches de la version DOS }
Procedure MenuInit(M: LongInt);
Var I: Integer;
Begin
 M:=M-900;
 If (M<1) Or (M>NMENU) Then Exit;
 For I:=1 To MCnt[M] Do
  If MLb[M,I]<>'-' Then MnAttr(100+16*M+I,MIA_CHECKED,MenuChecked(MCm[M,I]));
End;

Function MenuX(M: Integer): Integer;
Var I,X: Integer;
Begin
 X:=10;
 For I:=1 To M-1 Do X:=X+TextW(MT[I])+10;
 MenuX:=X;
End;

Function ItemH(M,I: Integer): Integer;
Begin
 If MLb[M,I]='-' Then ItemH:=8 Else ItemH:=18;
End;

Function ItemY(M,I: Integer): Integer;
Var K,Y: Integer;
Begin
 Y:=MENU_H+MENU_H+3;
 For K:=1 To I-1 Do Y:=Y+ItemH(M,K);
 ItemY:=Y;
End;

Procedure DropRect(M: Integer; Var X1,Y1,X2,Y2: Integer);
Var I,W,L,P: Integer; S: String;
Begin
 W:=0;Y2:=MENU_H+MENU_H+3;
 For I:=1 To MCnt[M] Do Begin
  S:=MLb[M,I];
  P:=Pos('|',S);
  If P>0 Then L:=(P-1)*8+32+(Length(S)-P)*8 Else L:=Length(S)*8;
  If L>W Then W:=L;
  Y2:=Y2+ItemH(M,I);
 End;
 X1:=MenuX(M)-6;
 X2:=X1+W+40;
 If X2>SCR_W-2 Then Begin X1:=X1-(X2-(SCR_W-2));X2:=SCR_W-2;End;
 Y1:=MENU_H+MENU_H-1;
 Y2:=Y2+3;
End;

Function DropHit(M: Integer; X,Y: LongInt): Integer;
Var X1,Y1,X2,Y2,I: Integer;
Begin
 DropHit:=0;
 DropRect(M,X1,Y1,X2,Y2);
 If Not InBox(X,Y,X1,Y1,X2,Y2) Then Exit;
 For I:=1 To MCnt[M] Do
  If (Y>=ItemY(M,I)) And (Y<ItemY(M,I)+ItemH(M,I)) Then DropHit:=I;
End;

Function TitleHit(X,Y: LongInt): Integer;
Var M: Integer;
Begin
 TitleHit:=0;
 If (Y<MENU_H) Or (Y>=MENU_H+MENU_H) Then Exit;
 For M:=1 To NMENU Do
  If (X>=MenuX(M)-6) And (X<=MenuX(M)+TextW(MT[M])+7) Then TitleHit:=M;
End;

Procedure DrawMenuBar;
Var M: Integer;
Begin
 Bx(0,MENU_H,SCR_W-1,MENU_H+MENU_H-1,cLGr);
 Ln(0,MENU_H+MENU_H-1,SCR_W-1,MENU_H+MENU_H-1,cDGr);
 Ln(0,MENU_H,SCR_W-1,MENU_H,cWht);
 For M:=1 To NMENU Do Begin
  If M=MenuOpen Then Begin
   Bx(MenuX(M)-6,MENU_H+1,MenuX(M)+TextW(MT[M])+5,MENU_H+MENU_H-2,cNavy);
   UTx(MenuX(M),MENU_H+5,MT[M],cWht);
  End Else UTx(MenuX(M),MENU_H+5,MT[M],cBlk);
 End;
End;

Procedure DrawDropDown;
Var X1,Y1,X2,Y2,I,Y,P: Integer; S,Lb,Sc: String; Hi: Boolean;
Begin
 If MenuOpen=0 Then Exit;
 DropRect(MenuOpen,X1,Y1,X2,Y2);
 Raised(X1,Y1,X2,Y2);
 For I:=1 To MCnt[MenuOpen] Do Begin
  S:=MLb[MenuOpen,I];
  Y:=ItemY(MenuOpen,I);
  If S='-' Then Begin
   Ln(X1+3,Y+3,X2-3,Y+3,cDGr);Ln(X1+3,Y+4,X2-3,Y+4,cWht);
  End Else Begin
   P:=Pos('|',S);
   If P>0 Then Begin Lb:=Copy(S,1,P-1);Sc:=Copy(S,P+1,20);End Else Begin
     Lb:=S;Sc:='';End;
   Hi:=(I=MenuHi);
   If Hi Then Bx(X1+3,Y,X2-3,Y+17,cNavy);
   If MenuChecked(MCm[MenuOpen,I]) Then Begin
    If Hi Then Tx(X1+8,Y+5,#251,cWht) Else Tx(X1+8,Y+5,#251,cBlk);
   End;
   If Hi Then Begin
    Tx(X1+24,Y+5,Lb,cWht);
    If Sc<>'' Then Tx(X2-10-Length(Sc)*8,Y+5,Sc,cWht);
   End Else Begin
    Tx(X1+24,Y+5,Lb,cBlk);
    If Sc<>'' Then Tx(X2-10-Length(Sc)*8,Y+5,Sc,cBlk);
   End;
  End;
 End;
End;

{ ---- icones 32x32 ---- }

Procedure DrawIcon(Cm,X,Y: Integer);
Var Pt: Array[1..4] Of PointType; I: Integer;
Begin
 SetLineStyle(SolidLn,0,1);
 Case Cm Of
  10: Begin
    Bx(X+2,Y+21,X+30,Y+28,cBrn);Bx(X+2,Y+21,X+5,Y+28,cDGr);
    Bx(X+5,Y+14,X+27,Y+21,cRed);Bx(X+5,Y+14,X+8,Y+21,cDGr);
    Bx(X+3,Y+7,X+25,Y+14,cNavy);Bx(X+3,Y+7,X+6,Y+14,cBlk);
    Ln(X+10,Y+24,X+26,Y+24,cYel);Ln(X+12,Y+17,X+24,Y+17,cYel);
   End;
  11: Begin
    Bx(X+2,Y+8,X+15,Y+27,cWht);Bx(X+16,Y+8,X+30,Y+27,cWht);
    SetColor(cBlk);Rectangle(X+2,Y+8,X+15,Y+27);Rectangle(X+16,Y+8,X+30,Y+27);
    For I:=0 To 3 Do Begin
      Ln(X+4,Y+12+I*4,X+13,Y+12+I*4,cDGr);Ln(X+18,Y+12+I*4,X+28,Y+12+I*4,cDGr);
      End;
    Ln(X+6,Y+6,X+24,Y+4,cRed);Ln(X+24,Y+4,X+20,Y+1,cRed);
    Ln(X+24,Y+4,X+20,Y+8,cRed);
   End;
  12: Begin
    Pt[1].X:=X+16;Pt[1].Y:=Y+3;Pt[2].X:=X+2;Pt[2].Y:=Y+12;Pt[3].X:=X+30;
    Pt[3].Y:=Y+12;
    SetFillStyle(SolidFill,cRed);SetColor(cBlk);FillPoly(3,Pt);
    For I:=0 To 3 Do Bx(X+4+I*7,Y+14,X+8+I*7,Y+24,cLGr);
    Bx(X+2,Y+25,X+30,Y+29,cBrn);
   End;
  13: Begin
    Bx(X+6,Y+2,X+25,Y+28,cWht);SetColor(cBlk);Rectangle(X+6,Y+2,X+25,Y+28);
    Bx(X+6,Y+2,X+25,Y+8,cMag);
    For I:=0 To 3 Do Ln(X+9,Y+12+I*4,X+22,Y+12+I*4,cDGr);
   End;
  14: Begin
    Ln(X+2,Y+5,X+7,Y+5,cBlk);Ln(X+7,Y+5,X+10,Y+20,cBlk);
    Ln(X+10,Y+20,X+27,Y+20,cBlk);
    Bx(X+9,Y+8,X+28,Y+17,cLBl);Bx(X+9,Y+8,X+28,Y+9,cWht);
    SetFillStyle(SolidFill,cBlk);FillEllipse(X+13,Y+25,3,3);
    FillEllipse(X+24,Y+25,3,3);
    Tx(X+15,Y+10,'$',cYel);
   End;
  15: Begin
    Bx(X+2,Y+9,X+30,Y+25,cLBl);SetColor(cBlk);Rectangle(X+2,Y+9,X+30,Y+25);
    Ln(X+5,Y+14,X+18,Y+14,cBlk);Ln(X+5,Y+18,X+14,Y+18,cBlk);
    Bx(X+20,Y+17,X+27,Y+22,cYel);
    Ln(X+8,Y+3,X+24,Y+6,cRed);Ln(X+24,Y+6,X+20,Y+2,cRed);
    Ln(X+24,Y+6,X+19,Y+8,cRed);
   End;
  16: Begin
    For I:=0 To 3 Do Begin
     SetFillStyle(SolidFill,cYel);SetColor(cBrn);
     FillEllipse(X+16,Y+25-I*5,12,4);
     Bx(X+4,Y+21-I*5,X+28,Y+25-I*5,cYel);
     Ln(X+4,Y+21-I*5,X+4,Y+25-I*5,cBrn);Ln(X+28,Y+21-I*5,X+28,Y+25-I*5,cBrn);
    End;
    SetFillStyle(SolidFill,cYel);SetColor(cBrn);FillEllipse(X+16,Y+6,12,4);
   End;
  17: Begin
    Bx(X+3,Y+14,X+29,Y+28,cDGr);Bx(X+3,Y+14,X+29,Y+16,cLGr);
    Bx(X+8,Y+4,X+24,Y+13,cLCy);SetColor(cBlk);Rectangle(X+8,Y+4,X+24,Y+13);
    For I:=0 To 3 Do Begin
      Bx(X+6+I*6,Y+19,X+9+I*6,Y+21,cWht);Bx(X+6+I*6,Y+23,X+9+I*6,Y+25,cWht);End;
   End;
  18: Begin
    Bx(X+2,Y+9,X+30,Y+25,cLCy);SetColor(cBlk);Rectangle(X+2,Y+9,X+30,Y+25);
    Ln(X+5,Y+14,X+18,Y+14,cBlk);Ln(X+5,Y+18,X+14,Y+18,cBlk);
    Bx(X+20,Y+17,X+27,Y+22,cYel);
    Ln(X+24,Y+3,X+8,Y+6,cGrn);Ln(X+8,Y+6,X+12,Y+2,cGrn);
    Ln(X+8,Y+6,X+13,Y+8,cGrn);
   End;
  19: Begin
    Bx(X+1,Y+2,X+31,Y+28,cWht);SetColor(cRed);Rectangle(X+1,Y+2,X+31,Y+28);
    For I:=0 To 2 Do Begin
     SetFillStyle(SolidFill,cBrn);SetColor(cBlk);FillEllipse(X+8+I*8,Y+11,3,3);
     Bx(X+4+I*8,Y+15,X+12+I*8,Y+26,cLBl);
    End;
   End;
  20: Begin
    Bx(X+3,Y+4,X+29,Y+28,cWht);SetColor(cBlk);Rectangle(X+3,Y+4,X+29,Y+28);
    SetFillStyle(SolidFill,cBrn);FillEllipse(X+10,Y+12,3,3);
    Bx(X+6,Y+16,X+14,Y+24,cLBl);
    For I:=0 To 3 Do Ln(X+17,Y+9+I*5,X+27,Y+9+I*5,cDGr);
   End;
  21: Begin
    For I:=0 To 2 Do Begin
     Bx(X+2+I*3,Y+4+I*5,X+24+I*3,Y+14+I*5,cWht);SetColor(cBlk);
     Rectangle(X+2+I*3,Y+4+I*5,X+24+I*3,Y+14+I*5);
     Ln(X+5+I*3,Y+9+I*5,X+20+I*3,Y+9+I*5,cDGr);
    End;
   End;
  22: Begin
    Bx(X+3,Y+2,X+17,Y+26,cBrn);Bx(X+5,Y+5,X+15,Y+24,cWht);
    For I:=0 To 3 Do Ln(X+7,Y+9+I*4,X+13,Y+9+I*4,cDGr);
    Bx(X+17,Y+14,X+30,Y+28,cYel);SetColor(cBrn);Rectangle(X+17,Y+14,X+30,Y+28);
    Ln(X+17,Y+20,X+30,Y+20,cBrn);
   End;
  23: Begin
    Bx(X+8,Y+10,X+24,Y+26,cYel);SetColor(cBrn);Rectangle(X+8,Y+10,X+24,Y+26);
    Ln(X+8,Y+16,X+24,Y+16,cBrn);
    Arw(X+16,Y+4,2,cRed);Arw(X+4,Y+18,4,cRed);Arw(X+28,Y+18,3,cRed);
   End;
  24: Begin
    Ln(X+16,Y+4,X+16,Y+26,cBlk);Ln(X+5,Y+8,X+27,Y+8,cBlk);
    Bx(X+8,Y+26,X+24,Y+28,cBlk);
    Ln(X+5,Y+8,X+2,Y+18,cBlk);Ln(X+5,Y+8,X+8,Y+18,cBlk);
    Ln(X+2,Y+18,X+8,Y+18,cBlk);
    Ln(X+27,Y+8,X+24,Y+18,cBlk);Ln(X+27,Y+8,X+30,Y+18,cBlk);
    Ln(X+24,Y+18,X+30,Y+18,cBlk);
    Bx(X+2,Y+19,X+8,Y+21,cBrn);Bx(X+24,Y+19,X+30,Y+21,cBrn);
   End;
  25: Begin
    Bx(X+3,Y+7,X+14,Y+11,cRed);Bx(X+3,Y+10,X+29,Y+27,cRed);
    Bx(X+5,Y+13,X+27,Y+25,cLRd);SetColor(cBlk);Rectangle(X+3,Y+10,X+29,Y+27);
   End;
 End;
End;

Function IconLabel(Cm: Integer): String;
Begin
 Case Cm Of
  10: IconLabel:=T3('Comptes','Accounts','Konten');
  11: IconLabel:=T3('Transactions|diverses','Miscellaneous|Transactions',
      'Sonstige|Buchungen');
  12: IconLabel:=T3('Conciliation|bancaire','Account|Reconcile',
      'Konto-|abstimmung');
  13: IconLabel:=T3('Fournisseurs','Vendors','Lieferanten');
  14: IconLabel:=T3('Achats,|commandes','Purchases,|Orders & Quotes',
      'Eink@1ufe,|Bestellungen');
  15: IconLabel:=T3('Paiements','Payments','Zahlungen');
  16: IconLabel:=T3('Clients','Customers','Kunden');
  17: IconLabel:=T3('Ventes,|commandes','Sales, Orders|& Quotes',
      'Verk@1ufe,|Auftr@1ge');
  18: IconLabel:=T3('Encaissements','Receipts','Zahlungs-|eing@1nge');
  19: IconLabel:=T3('Employ@es','Employees','Mitarbeiter');
  20: IconLabel:=T3('Ch@eques|de paie','Paycheques','Gehalts-|schecks');
  21: IconLabel:=T3('Passage|de la paie','Payroll|Cheque Run','Gehaltslauf');
  22: IconLabel:=T3('Inventaire|et services','Inventory &|Services',
      'Lager und|Dienste');
  23: IconLabel:=T3('Assemblage|d''articles','Item|Assembly',
      'Artikel-|montage');
  24: IconLabel:=T3('Ajustements','Adjustments','Korrekturen');
  25: IconLabel:=T3('Projet','Project','Projekt');
  Else IconLabel:='';
 End;
End;

Function HeadLabel(C: Integer): String;
Begin
 Case C Of
  1: HeadLabel:=T3('G@en@eral','General','Allgemein');
  2: HeadLabel:=T3('Fournisseurs|et achats','Vendors &|Purchases',
      'Lieferanten|& Eink@1ufe');
  3: HeadLabel:=T3('Clients|et ventes','Customers|& Sales',
      'Kunden|& Verk@1ufe');
  4: HeadLabel:=T3('Paie','Payroll','Lohn');
  5: HeadLabel:=T3('Inventaire|et services','Inventory|& Services',
      'Lager &|Dienste');
  6: HeadLabel:=T3('Projet','Project','Projekt');
  Else HeadLabel:='';
 End;
End;

Function IconCmd(C,R: Integer): Integer;       { C,R base 1 }
Begin
 IconCmd:=0;
 If (C<1) Or (C>6) Or (R<1) Or (R>3) Then Exit;
 If C=6 Then Begin
  If R=1 Then IconCmd:=25;
  Exit;
 End;
 IconCmd:=10+(C-1)*3+(R-1);
End;

Function PanelTop: Integer;
Begin
 If ToolBarOn Then PanelTop:=TOOL_Y+26+22 Else PanelTop:=TOOL_Y+22;
End;

Procedure CenterLines(CX,
    Y: Integer; Const S: String; Col: Integer; Bold: Boolean);
Var P: Integer; L,R: String;
Begin
 P:=Pos('|',S);
 If P=0 Then Begin
  If Bold Then TxB(CX-Length(S)*4,Y,S,Col) Else Tx(CX-Length(S)*4,Y,S,Col);
 End Else Begin
  L:=Copy(S,1,P-1);R:=Copy(S,P+1,60);
  CenterLines(CX,Y,L,Col,Bold);
  CenterLines(CX,Y+10,R,Col,Bold);
 End;
End;

Procedure DrawPanel;
Var PT,C,R,X1,Y1,Idx,Cm: Integer; S: String;
Begin
 PT:=PanelTop;
 Bx(8,PT,SCR_W-9,PT+6+30+3*PROWH+8,cGrn);
 SetColor(cLGn);Rectangle(8,PT,SCR_W-9,PT+6+30+3*PROWH+8);
 For C:=1 To 6 Do Begin
  X1:=14+(C-1)*PCOLW;
  Bx(X1,PT+6,X1+PCOLW-2,PT+35,cGrn);
  Ln(X1,PT+6,X1+PCOLW-2,PT+6,cLGn);
  Ln(X1,PT+34,X1+PCOLW-2,PT+34,cLGn);
  S:=HeadLabel(C);
  If Pos('|',S)>0 Then CenterLines(X1+PCOLW Div 2,PT+10,S,cWht,True)
  Else CenterLines(X1+PCOLW Div 2,PT+16,S,cWht,True);
  For R:=1 To 3 Do Begin
   Y1:=PT+36+(R-1)*PROWH;
   If R=1 Then Bx(X1,Y1,X1+PCOLW-2,Y1+PROWH-1,cLGr) Else
     Bx(X1,Y1,X1+PCOLW-2,Y1+PROWH-1,cWht);
   Ln(X1+PCOLW-1,Y1,X1+PCOLW-1,Y1+PROWH-1,cDGr);
   Cm:=IconCmd(C,R);
   If Cm>0 Then Begin
    DrawIcon(Cm,X1+(PCOLW-34) Div 2,Y1+8);
    Idx:=(C-1)*3+R;
    S:=IconLabel(Cm);
    If MainSel=Idx Then Begin
     If Pos('|',S)>0 Then Bx(X1+2,Y1+44,X1+PCOLW-4,Y1+PROWH-4,cNavy)
     Else Bx(X1+2,Y1+44,X1+PCOLW-4,Y1+54,cNavy);
     CenterLines(X1+PCOLW Div 2,Y1+46,S,cWht,False);
    End Else CenterLines(X1+PCOLW Div 2,Y1+46,S,cBlk,False);
   End;
  End;
 End;
End;

Procedure DrawTbIcon(K,X,Y: Integer);
Begin
 Case K Of
  1: Begin
    Bx(X+2,Y+6,X+14,Y+14,cYel);Bx(X+2,Y+4,X+7,Y+7,cYel);SetColor(cBrn);
    Rectangle(X+2,Y+6,X+14,Y+14);End;
  2: Begin
    Bx(X+2,Y+2,X+14,Y+14,cNavy);Bx(X+5,Y+2,X+11,Y+6,cWht);
    Bx(X+5,Y+9,X+11,Y+14,cLGr);End;
  3: Begin
    Bx(X+3,Y+2,X+13,Y+14,cWht);SetColor(cBlk);Rectangle(X+3,Y+2,X+13,Y+14);
     Ln(X+5,Y+5,X+11,Y+5,cDGr);Ln(X+5,Y+8,X+11,Y+8,cDGr);
     Ln(X+5,Y+11,X+11,Y+11,cDGr);End;
  4: Begin
    Bx(X+2,Y+9,X+5,Y+14,cRed);Bx(X+7,Y+5,X+10,Y+14,cLBl);
    Bx(X+12,Y+2,X+15,Y+14,cGrn);End;
  5: Begin
    Bx(X+2,Y+2,X+14,Y+14,cLGr);SetColor(cBlk);Rectangle(X+2,Y+2,X+14,Y+14);
     Bx(X+4,Y+4,X+12,Y+6,cLCy);Bx(X+4,Y+8,X+6,Y+10,cBlk);
     Bx(X+8,Y+8,X+10,Y+10,cBlk);Bx(X+4,Y+11,X+6,Y+13,cBlk);
     Bx(X+8,Y+11,X+10,Y+13,cBlk);End;
  6: Begin
    Bx(X+2,Y+2,X+14,Y+14,cLBl);SetColor(cBlk);Rectangle(X+2,Y+2,X+14,Y+14);
     Tx(X+5,Y+5,'?',cWht);End;
 End;
End;

Const
 TbCmd  : Array[1..8] Of Integer = (2,3,11,80,81,51,50,90);
 TbIcon : Array[1..8] Of Integer = (1,2,3,4,3,5,4,6);
 TbX    : Array[1..8] Of Integer = (4,28,62,86,110,144,168,200);

Procedure DrawToolbar;
Var I: Integer;
Begin
 Bx(0,TOOL_Y,SCR_W-1,TOOL_Y+25,cLGr);
 Ln(0,TOOL_Y+25,SCR_W-1,TOOL_Y+25,cDGr);
 For I:=1 To 8 Do Begin
  Raised(TbX[I],TOOL_Y+2,TbX[I]+21,TOOL_Y+23);
  DrawTbIcon(TbIcon[I],TbX[I]+3,TOOL_Y+4);
 End;
 Ln(TbX[2]+25,TOOL_Y+4,TbX[2]+25,TOOL_Y+22,cDGr);
 Ln(TbX[2]+26,TOOL_Y+4,TbX[2]+26,TOOL_Y+22,cWht);
 Ln(TbX[5]+25,TOOL_Y+4,TbX[5]+25,TOOL_Y+22,cDGr);
 Ln(TbX[5]+26,TOOL_Y+4,TbX[5]+26,TOOL_Y+22,cWht);
 TxB(SCR_W-22,TOOL_Y+9,'?',cRed);
End;

Function ToolHit(X,Y: LongInt): Integer;
Var I: Integer;
Begin
 ToolHit:=0;
 If Not ToolBarOn Then Exit;
 For I:=1 To 8 Do
  If InBox(X,Y,TbX[I],TOOL_Y+2,TbX[I]+21,TOOL_Y+23) Then ToolHit:=TbCmd[I];
 If InBox(X,Y,SCR_W-30,TOOL_Y+2,SCR_W-4,TOOL_Y+23) Then ToolHit:=90;
End;

Function TimeStr: String;
Var H,M,S,S1: Word; R: String;
Begin
 GetTime(H,M,S,S1);
 If Lang=2 Then Begin
  R:=IntStr((H+11) Mod 12+1)+':'+Two(M);
  If H>=12 Then R:=R+' PM' Else R:=R+' AM';
 End Else R:=Two(H)+':'+Two(M);
 TimeStr:=R;
End;

Procedure DrawMain;
Var DY1,Y2,I: Integer; S: String;
Begin
 { fond du bureau }
 If ToolBarOn Then DY1:=TOOL_Y+26 Else DY1:=TOOL_Y;
 If StatusOn Then Y2:=STAT_Y-1 Else Y2:=TASK_Y-1;
 Dither(0,DY1,SCR_W-1,Y2,cLCy,cLGr);
 { barre de titre }
 Bx(0,0,SCR_W-1,MENU_H-1,cNavy);
 Bx(3,3,13,14,cWht);Bx(4,4,12,8,cLRd);Ln(4,10,12,10,cDGr);
 If Named Or (FileN<>'') Then S:=ShortName(FileN) Else
   S:=T3('(sans titre)','(untitled)','(unbenannt)');
 TxB(22,5,'Sample Accounting - '+Upper(S),cWht);
 Raised(SCR_W-52,2,SCR_W-38,15);Raised(SCR_W-37,2,SCR_W-23,15);
 Raised(SCR_W-20,2,SCR_W-4,15);
 Ln(SCR_W-49,12,SCR_W-42,12,cBlk);Rectangle(SCR_W-34,5,SCR_W-27,12);
 Ln(SCR_W-16,5,SCR_W-8,12,cBlk);Ln(SCR_W-16,12,SCR_W-8,5,cBlk);
 DrawMenuBar;
 If ToolBarOn Then DrawToolbar;
 DrawPanel;
 { barre d'etat }
 If StatusOn Then Begin
  Bx(0,STAT_Y,SCR_W-1,TASK_Y-1,cLGr);
  Sunken(2,STAT_Y+1,SCR_W-110,TASK_Y-2,cLGr);
  Sunken(SCR_W-108,STAT_Y+1,SCR_W-3,TASK_Y-2,cLGr);
  If Modified Then S:=T3('Modifi@e','Modified','Ge@1ndert') Else S:='';
  Tx(8,STAT_Y+5,SU.Co+'   '+FmtDate(SessDate)+'   '+S,cBlk);
  Tx(SCR_W-100,STAT_Y+5,'sysadmin',cBlk);
 End;
 { barre des taches }
 Bx(0,TASK_Y,SCR_W-1,SCR_H-1,cLGr);
 Ln(0,TASK_Y,SCR_W-1,TASK_Y,cWht);
 Raised(2,TASK_Y+3,70,SCR_H-3);
 Bx(7,TASK_Y+7,15,TASK_Y+14,cLRd);Bx(16,TASK_Y+7,24,TASK_Y+14,cLGn);
 Bx(7,TASK_Y+15,15,TASK_Y+20,cLBl);Bx(16,TASK_Y+15,24,TASK_Y+20,cYel);
 TxB(28,TASK_Y+9,'Start',cBlk);
 Sunken(76,TASK_Y+3,244,SCR_H-3,cLGr);
 Dither(77,TASK_Y+4,243,SCR_H-4,cWht,cLGr);
 TxB(98,TASK_Y+9,'Sample Accounting',cBlk);
 Bx(82,TASK_Y+7,92,TASK_Y+17,cWht);Bx(83,TASK_Y+8,91,TASK_Y+11,cLRd);
 Sunken(SCR_W-90,TASK_Y+3,SCR_W-3,SCR_H-3,cLGr);
 Tx(SCR_W-80,TASK_Y+9,TimeStr,cBlk);
 DrawDropDown;
End;

{ ====================================================================== }
{                     COMMANDES DE L'APPLICATION                         }
{ ====================================================================== }

Function ConfirmSave: Integer;     { 1 oui, 2 non, 3 annuler }
Begin
 If Not Modified Then Begin ConfirmSave:=2;Exit;End;
 ConfirmSave:=MsgBox(T3('Enregistrer les modifications ?','Save changes?',
     '@4nderungen speichern?'),3);
End;

Function DoSaveAs: Boolean;
Var S: String;
Begin
 DoSaveAs:=False;
 If FileN<>'' Then S:=FileN Else S:='UNIVERSL.SDB';
 If InputBox(T3('Enregistrer sous','Save as','Speichern unter'),
     T3('Nom du fichier :','File name:','Dateiname:'),S,40,0) Then Begin
  S:=AddExt(TrimStr(S),'SDB');
  If SaveCo(S) Then Begin
   FileN:=S;Named:=True;Modified:=False;DoSaveAs:=True;
  End Else
    Info(T3('Impossible d''enregistrer le fichier.','Cannot save the file.',
      'Datei kann nicht gespeichert werden.'));
 End;
End;

Function DoSave: Boolean;
Begin
 If (Not Named) Or (FileN='') Then DoSave:=DoSaveAs
 Else If SaveCo(FileN) Then Begin Modified:=False;DoSave:=True;End
 Else Begin
  Info(T3('Impossible d''enregistrer le fichier.','Cannot save the file.',
      'Datei kann nicht gespeichert werden.'));
  DoSave:=False;
 End;
End;

Procedure CmdNew;
Var C: Integer; S: String;
Begin
 C:=ConfirmSave;
 If C=3 Then Exit;
 If C=1 Then If Not DoSave Then Exit;
 S:='';
 If InputBox(T3('Nouvelle soci@et@e','New company','Neue Firma'),
     T3('Nom de la soci@et@e :','Company name:','Firmenname:'),S,34,0) Then
   Begin
  If TrimStr(S)='' Then Exit;
  InitNewCompany;
  SU.Co:=TrimStr(S);
  FileN:='';Modified:=True;
 End;
End;

Procedure CmdOpen;
Var C: Integer; S: String;
Begin
 C:=ConfirmSave;
 If C=3 Then Exit;
 If C=1 Then If Not DoSave Then Exit;
 S:='UNIVERSL.SDB';
 If InputBox(T3('Ouvrir','Open','@5ffnen'),T3('Nom du fichier :','File name:',
     'Dateiname:'),S,40,0) Then Begin
  S:=AddExt(TrimStr(S),'SDB');
  If Not FileExists(S) Then
    Info(T3('Fichier introuvable.','File not found.','Datei nicht gefunden.'))
  Else If Not LoadCo(S) Then Begin
   Info(T3('Fichier invalide ou endommag@e.','Invalid or damaged file.',
       'Ung@3ltige oder besch@1digte Datei.'));
   InitNewCompany;
  End;
 End;
End;

Procedure CmdQuit;
Var C: Integer;
Begin
 C:=ConfirmSave;
 If C=3 Then Exit;
 If C=1 Then If Not DoSave Then Exit;
 Quit:=True;
End;

Procedure CmdBackup;
Var S: String;
Begin
 If FileN='' Then S:='UNIVERSL.BAK' Else S:=ChangeExt(FileN,'BAK');
 If SaveCo(S) Then
   Info(T3('Copie de s@ecurit@e cr@e@ee : ','Backup created: ',
     'Sicherung erstellt: ')+S)
 Else
   Info(T3('Impossible de cr@eer la copie.','Cannot create the backup.',
     'Sicherung kann nicht erstellt werden.'));
End;

Procedure CmdSessDate;
Var S: String; D: LongInt;
Begin
 S:=FmtDate(SessDate);
 If InputBox(T3('Date de session','Session date','Sitzungsdatum'),
     T3('Nouvelle date :','New date:','Neues Datum:'),S,12,2) Then Begin
  If ParseDate(S,D) Then SessDate:=D Else
    Info(T3('Date invalide.','Invalid date.','Ung@3ltiges Datum.'));
 End;
End;

Procedure CmdCloseYear;
Var I: Integer; Net: LongInt;
Begin
 If Not
     Ask(T3('Cl@oturer l''exercice ?|Les comptes de revenus et de d@epenses '+
     'seront|ramen@es @a z@ero dans les b@en@efices non r@epartis.',
     'Close the fiscal year?|Revenue and expense accounts will be|reset to '+
     'zero into retained earnings.',
     'Gesch@1ftsjahr abschlie@7en?|Ertrags- und Aufwandskonten werden auf|'+
     'den Gewinnvortrag gebucht.')) Then Exit;
 PClear;
 For I:=1 To NA Do
  If (Ac^[I].Kind In [K_REV,K_COGS,K_EXP]) And (Ac^[I].Bal<>0) Then
    PAdd(Ac^[I].Num,-Ac^[I].Bal,0);
 If PN=0 Then Begin
   Info(T3('Rien @a cl@oturer.','Nothing to close.','Nichts abzuschlie@7en.'));
   Exit;End;
 Net:=PSumDr-PSumCr;
 If Net>0 Then PCr(LinkAcc(LK_RET),Net) Else If Net<0 Then
   PDr(LinkAcc(LK_RET),-Net);
 If Commit(SessDate,'CLOT',T3('Cl@oture de l''exercice','Year-end closing',
     'Jahresabschluss')) Then
  Info(T3('Exercice cl@otur@e.','Fiscal year closed.',
      'Gesch@1ftsjahr abgeschlossen.'))
 Else Info(ErrMsg);
End;

Procedure DoCmd(C: Integer);
Begin
 Case C Of
  1: CmdNew;
  2: CmdOpen;
  3: DoSave;
  4: DoSaveAs;
  5: CmdBackup;
  6: CmdQuit;
  10: OpenList(1);
  11: OpenJournal;
  12: OpenRecon;
  13: OpenList(2);
  14: OpenInvoice(1);
  15: OpenPay(1);
  16: OpenList(3);
  17: OpenInvoice(2);
  18: OpenPay(2);
  19: OpenList(4);
  20: OpenPaych;
  21: OpenRun;
  22: OpenList(5);
  23: OpenAssem;
  24: OpenAdjust;
  25: OpenList(6);
  30: ToolBarOn:=Not ToolBarOn;
  31: StatusOn:=Not StatusOn;
  32: CmdSessDate;
  40: OpenSetup(1);
  41: OpenSetup(2);
  42: OpenSetup(3);
  43: OpenSetup(4);
  50: Begin RepSummary;ShowReportNow;End;
  51: OpenCalc;
  52: Begin RepReminders;ShowReportNow;End;
  60: Begin RepVerify;ShowReportNow;End;
  61: CmdCloseYear;
  70: GraphRevExp;
  71: GraphByKind(K_EXP,K_COGS,T3('D@epenses par compte','Expenses by account',
      'Aufwand je Konto'));
  72: GraphByKind(K_ASSET,K_ASSET,T3('Actif par compte','Assets by account',
      'Aktiva je Konto'));
  80: Begin RepBalance;ShowReportNow;End;
  81: Begin RepIncome;ShowReportNow;End;
  82: Begin RepTrial;ShowReportNow;End;
  83: Begin RepJournal;ShowReportNow;End;
  84: Begin RepChart;ShowReportNow;End;
  85: Begin RepAged(1);ShowReportNow;End;
  86: Begin RepAged(2);ShowReportNow;End;
  87: Begin RepEmployees;ShowReportNow;End;
  88: Begin RepInventory;ShowReportNow;End;
  90: Begin RepHelp;ShowReportNow;End;
  92: Info('Sample Accounting - '+T3('clone','clone',
      'Klon')+' v'+VERSION_TEXT+'|'+T3('Programme de comptabilit@e en Pascal',
      'Accounting program in Pascal',
      'Buchhaltungsprogramm in Pascal')+
      '|OFFICE-0 - https://www.gladir.com/office-0');
 End;
 Dirty:=True;
End;

{ ====================================================================== }
{                       MENUS DEROULANTS (PAPYRUS)                       }
{ ====================================================================== }

Function NextItem(M,From,Dir: Integer): Integer;
Var I,N: Integer;
Begin
 N:=MCnt[M];
 I:=From;
 Repeat
  I:=I+Dir;
  If I<1 Then I:=N;
  If I>N Then I:=1;
  If MLb[M,I]<>'-' Then Begin NextItem:=I;Exit;End;
 Until I=From;
 NextItem:=From;
End;

Procedure RunMenu(StartM: Integer; ByMouse: Boolean);
Var M,Hi,H,T: Integer; E: TEvent; Done,Pick,Redraw: Boolean;
Begin
 M:=StartM;Hi:=0;
 If Not ByMouse Then Hi:=NextItem(M,0,1);
 MenuOpen:=M;MenuHi:=Hi;
 DrawAll;
 Done:=False;Pick:=False;
 Repeat
  PollEvent(E);
  Redraw:=False;
  Case E.Kind Of
   4,2: Begin
         T:=TitleHit(E.X,E.Y);
         If (T>0) And (T<>M) Then Begin M:=T;Hi:=0;Redraw:=True;End
         Else Begin
          H:=DropHit(M,E.X,E.Y);
          If (H<>0) And (MLb[M,H]='-') Then H:=0;
          If H<>Hi Then Begin Hi:=H;Redraw:=True;End;
         End;
         If E.Kind=2 Then Begin
          If DropHit(M,E.X,E.Y)=0 Then Begin
           If TitleHit(E.X,E.Y)=0 Then Done:=True;
          End Else If Hi<>0 Then Begin Pick:=True;Done:=True;End;
         End;
        End;
   3: Begin
       H:=DropHit(M,E.X,E.Y);
       If (H<>0) And (Hi=H) And (MLb[M,H]<>'-') Then Begin
         Pick:=True;Done:=True;End;
      End;
   1: Case E.Key Of
       K_ESC: Done:=True;
       K_LEFT: Begin Dec(M);If M<1 Then
         M:=NMENU;Hi:=NextItem(M,0,1);Redraw:=True;End;
       K_RIGHT: Begin Inc(M);If M>NMENU Then
         M:=1;Hi:=NextItem(M,0,1);Redraw:=True;End;
       K_UP: Begin Hi:=NextItem(M,Hi,-1);Redraw:=True;End;
       K_DOWN: Begin Hi:=NextItem(M,Hi,1);Redraw:=True;End;
       K_ENTER: If Hi<>0 Then Begin Pick:=True;Done:=True;End;
      End;
  End;
  If Redraw Then Begin MenuOpen:=M;MenuHi:=Hi;DrawAll;End;
 Until Done;
 MenuOpen:=0;MenuHi:=0;
 DrawAll;
 If Pick And (Hi>0) Then DoCmd(MCm[M,Hi]);
End;

Function AltLetter(K: Word): Integer;
Const
 RowQ : String[10] = 'QWERTYUIOP';
 RowA : String[9] = 'ASDFGHJKL';
 RowZ : String[7] = 'ZXCVBNM';
Var Sc: Integer;
Begin
 AltLetter:=-1;
 If K<256 Then Exit;
 Sc:=K-256;
 Case Sc Of
  16..25: AltLetter:=Ord(RowQ[Sc-15])-65;
  30..38: AltLetter:=Ord(RowA[Sc-29])-65;
  44..50: AltLetter:=Ord(RowZ[Sc-43])-65;
 End;
End;

Procedure MenuByLetter(L: Integer);
Var M: Integer;
Begin
 For M:=1 To NMENU Do
  If MenuMnem(M)=Chr(L+65) Then Begin RunMenu(M,False);Exit;End;
End;

{ ====================================================================== }
{                          BOUCLE PRINCIPALE                             }
{ ====================================================================== }

Procedure IconAt(X,Y: LongInt; Var C,R: Integer);
Var PT: Integer;
Begin
 C:=0;R:=0;
 PT:=PanelTop;
 If (X<14) Or (X>=14+6*PCOLW) Then Exit;
 If (Y<PT+36) Or (Y>=PT+36+3*PROWH) Then Exit;
 C:=(X-14) Div PCOLW+1;
 R:=(Y-PT-36) Div PROWH+1;
End;

Procedure MoveSel(DC,DR: Integer);
Var C,R: Integer;
Begin
 If MainSel=0 Then MainSel:=1
 Else Begin
  C:=(MainSel-1) Div 3+1;R:=(MainSel-1) Mod 3+1;
  C:=C+DC;R:=R+DR;
  If C<1 Then C:=6;
  If C>6 Then C:=1;
  If R<1 Then R:=3;
  If R>3 Then R:=1;
  If IconCmd(C,R)=0 Then R:=1;
  MainSel:=(C-1)*3+R;
 End;
End;

Procedure HandleKey(K: Word);
Var L: Integer; C,R: Integer;
Begin
 If K>=256 Then Begin
  L:=AltLetter(K);
  If L>=0 Then Exit;
 End;
 Case K Of
  K_F1: DoCmd(90);
  19: DoCmd(3);
  15: DoCmd(2);
  14: DoCmd(1);
  K_LEFT: Begin MoveSel(-1,0);Dirty:=True;End;
  K_RIGHT: Begin MoveSel(1,0);Dirty:=True;End;
  K_UP: Begin MoveSel(0,-1);Dirty:=True;End;
  K_DOWN: Begin MoveSel(0,1);Dirty:=True;End;
  K_ENTER: If MainSel>0 Then Begin
    C:=(MainSel-1) Div 3+1;R:=(MainSel-1) Mod 3+1;
    DoCmd(IconCmd(C,R));
   End;
  K_ESC: MainSel:=0;
 End;
End;

Procedure MouseDown(X,Y: LongInt);
Var T,C,R,Cm: Integer;
Begin
 T:=TitleHit(X,Y);
 If T>0 Then Begin RunMenu(T,True);Exit;End;
 If (Y<MENU_H) And (X>=SCR_W-20) Then Begin CmdQuit;Exit;End;
 Cm:=ToolHit(X,Y);
 If Cm>0 Then Begin DoCmd(Cm);Exit;End;
 IconAt(X,Y,C,R);
 If C>0 Then Begin
  Cm:=IconCmd(C,R);
  If Cm>0 Then Begin MainSel:=(C-1)*3+R;DrawAll;DoCmd(Cm);End;
 End;
End;

Procedure MainLoop;
Var E: TEvent; C: LongInt;
Begin
 Repeat
  If Dirty Then DrawAll;
  { barre de menus de PM }
  While PollCmd(C) And Not Quit Do Begin
   If C=CMD_CLOSE Then CmdQuit
   Else If (C>=116) And (C<100+16*(NMENU+1)) Then
    If ((C-100) Mod 16>=1) And ((C-100) Mod 16<=MCnt[(C-100) Div 16]) Then
     DoCmd(MCm[(C-100) Div 16,(C-100) Mod 16]);
   Dirty:=True;
  End;
  If Quit Then Exit;
  PollEvent(E);
  Case E.Kind Of
   1: HandleKey(E.Key);
   2: MouseDown(E.X,E.Y);
  End;
 Until Quit;
End;

Procedure ShowHelpLine;
Begin
 WriteLn('SIMPLY - Clone graphique de Sample Accounting (comptabilit@e).');
 WriteLn;
 WriteLn('Utilisation : SIMPLY [fichier.SDB] [/?]');
 WriteLn;
 WriteLn('  fichier.SDB  Fichier de societe a ouvrir (defaut : UNIVERSL.SDB).');
 WriteLn('  /?           Affiche cette aide.');
 WriteLn;
 WriteLn('Langue : variable LANGUAGE=EN (anglais), LANGUAGE=GR (allemand),');
 WriteLn('         francais par defaut.');
End;

Procedure LoadStart;
Var F: String;
Begin
 If ParamCount>=1 Then F:=AddExt(ParamStr(1),'SDB') Else F:='UNIVERSL.SDB';
 If FileExists(F) Then Begin
  If LoadCo(F) Then Exit;
 End;
 InitSampleCompany;
End;

BEGIN
 If (ParamCount>=1) And ((ParamStr(1)='/?') Or (ParamStr(1)='-h') Or
    (ParamStr(1)='--help')) Then Begin
  ShowHelpLine;
  Halt(0);
 End;
 DetectLanguage;
 AllocData;
 WSN:=0;Dirty:=True;DirtyTop:=False;Quit:=False;
 ToolBarOn:=True;StatusOn:=True;MainSel:=0;MenuOpen:=0;MenuHi:=0;
 MX:=0;MY:=0;MB:=0;LastB:=0;LastClickT:=0;LastClickX:=0;LastClickY:=0;
 SessDate:=TodayDate;
 BuildMenus;
 LoadStart;
 InitializeGraphics;
 If MouseDriverFound Then ShowMouse;
 MainLoop;
 Dummy := WinDestroyWindow(OsFrame);
END.
