{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Clone de l'application Maximizer CRM (Maximilien CRM),
                pour le Presentation Manager d'OS/2-0 (dossier
                Productivite)

  Portage vers OS/2-0 (OS2PC -COS2) de MAXIMIZE.PAS du depot OFFICE-0 :
  tout le CRM est conserve (moteur MyISAM et SQL, carnet d'adresses,
  journee de travail, opportunites, calendrier, courriels, bibliotheque,
  commandes, rapports, publipostage, plans d'action). Pour OS/2 : fenetre
  de Presentation Manager (la barre de titre et la barre de menus
  dessinees par la version DOS sont celles d'OS/2), barre de menus d'OS/2
  construite a partir des neuf menus d'origine, menus contextuels de PM,
  boites de message, de saisie, listes, fiches et visionneuse de rapports
  faites de controles de PM, vues dessinees (tables, editeur, chronometre,
  A propos) dans des fenetres de PM a part avec de vrais boutons.
}

{$IFDEF FPC}
 {$MODE TP}
{$ENDIF}

Program MAXIMIZE;

{$IFNDEF FPC}
 {$M 16384,0,655360}
{$ENDIF}


{ ====================================================================== }
{                              CONSTANTES                                }
{ ====================================================================== }

Const
 APP_NAME     = 'Maximilien CRM';
 VERSION_TEXT = '1.00';
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
 K_F3     = 317;
 K_F4     = 318;
 K_F5     = 319;
 K_F6     = 320;
 K_F9     = 323;
 K_F10    = 324;
 K_STAB   = 271;

 { Moteur MyISAM }
 MAXTBL   = 24;
 MAXFLD   = 44;
 MAXREC   = 1024;
 MAXIDX   = 4000;
 MYI_BLK  = 1024;
 RECREF   = 6;
 KEYREF   = 5;

 { Moteur SQL }
 MAXTOK   = 100;
 MAXNODE  = 130;
 MAXCC    = 8;
 MAXRES   = 150;
 MAXGRP   = 80;
 MAXAGG   = 6;

 { Limites interface }
 MAXLST   = 60;
 MAXTXT   = 400;
 MAXPICK  = 200;

{ ====================================================================== }
{                                TYPES                                   }
{ ====================================================================== }

Type
 TEvent = Record
  { 0 rien, 1 touche, 2 bouton bas, 3 bouton haut, 4 mouvement }
  Kind : Byte;
  Key  : Word;
  X,Y,B: LongInt;
 End;

 TRec = Array[0..MAXREC-1] Of Byte;
 PRec = ^TRec;

 TFld = Record
  Nm  : String[16];
  Typ : Char;                  { I S B C D }
  Len : Integer;               { longueur affichee / CHAR }
  Off : Integer;
  Sz  : Integer;
 End;

 TIdxE = Record
  Id,Slot: LongInt;
 End;
 TIdxArr = Array[1..MAXIDX] Of TIdxE;
 PIdx = ^TIdxArr;

 PTbl = ^TTbl;
 TTbl = Record
  Nm        : String[16];
  NF        : Integer;
  F         : Array[1..MAXFLD] Of TFld;
  RecLen    : Integer;
  Slots,Del : LongInt;
  DelLink   : LongInt;
  AutoInc   : LongInt;
  Upd       : LongInt;
  NIdx      : Integer;
  IxCap     : Integer;
  Ix        : PIdx;
  Dat       : File;
  Opn       : Boolean;
  IxDirty,HdDirty : Boolean;
  Ctime     : LongInt;
 End;

 TTok = Record
  K : Byte;                    { 0 fin 1 ident 2 nombre 3 chaine 4 symbole }
  S : String[80];
 End;

 TVal = Record
  K : Byte;                    { 0 NULL 1 nombre 2 chaine }
  N : Real;
  S : String[80];
 End;

 TNode = Record
  Op   : Byte;
  A,B,C: Integer;
  S    : String[40];
  N    : Real;
  Tb   : Byte;
  Fi   : Integer;
 End;

 TResRow = Array[1..MAXCC] Of String[28];
 PResRows = ^TResArr;
 TResArr = Array[1..MAXRES] Of TResRow;

 TLongArr = Array[1..MAXIDX] Of LongInt;
 PLongArr = ^TLongArr;

 TStrArr = Array[1..MAXPICK] Of String[40];
 PStrArr = ^TStrArr;

 TTxtArr = Array[1..MAXTXT] Of String[78];
 PTxtArr = ^TTxtArr;

{ ====================================================================== }
{                              VARIABLES                                 }
{ ====================================================================== }

Var
 SCR_W,SCR_H : Integer;      { definition de l'ecran }
 MaxScreen : Boolean;
 Lang      : Integer;         { 1 fr, 2 en, 3 de, 4 es, 5 it }
 DbDir     : String[60];
 UserCode  : String[12];
 UserName  : String[30];
 SessDate  : LongInt;
 Quit      : Boolean;

 Tb        : Array[1..MAXTBL] Of PTbl;
 NTb       : Integer;
 RB        : PRec;            { tampon de travail }
 RB2       : PRec;
 RBF       : PRec;            { tampon des formulaires }

 { Resultat SQL }
 SqlErr    : String[80];
 SqlMsg    : String[80];
 SqlAff    : LongInt;
 SqlTbl    : Integer;
 SqlN      : LongInt;
 SqlSl     : PLongArr;
 SqlRows   : PResRows;
 SqlNR,SqlNC : Integer;
 SqlHead   : TResRow;
 SqlIsSlots: Boolean;

 MX,MY,MB,LastB : LongInt;
 PrevMX,PrevMY  : LongInt;
 LastClickT,LastClickX,LastClickY : LongInt;

{ ====================================================================== }
{                  GRAPHIQUE / SOURIS (squelette)                        }
{ ====================================================================== }

{$IFDEF FPC}

{$ENDIF}

Const
 CanvasTop = 36;
 CanvasBot = 449;

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
    $36,$36,$36,$36,$F6,$36,$36,$36,$60,$30,$78,$CC,$FC,$CC,$CC,$00,
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
    $00,$00,$3C,$3C,$3C,$3C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  );

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
 OpenWindow('MAXIMIZE', APP_NAME);
 SetColor(White);
 SetLineStyle(0,0,1);
 SCR_W := 640;
 SCR_H := CanvasBot + 1;
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
{                  LANGUE (FR defaut, EN, GR, SP, IT)                    }
{ ====================================================================== }

{ Codes d'accents dans les chaines sources : @e=e aigu @g=e grave @c=e circ.
  @a=a grave @q=a circ. @i=i circ. @y=i trema @o=o circ. @u=u grave
  @w=u circ. @k=c cedille @t=e trema @E=E aigu @1=ae @2=oe @3=ue @4=Ae
  @5=Oe @6=Ue @7=sz @n=n tilde @N=N tilde @!=! inverse @?=? inverse
  @@=arobase. Les textes multilingues : 'fr~en~de~es~it' }
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
    'A': R:=R+#183;
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
    'n': R:=R+#164;
    'N': R:=R+#165;
    '!': R:=R+#173;
    '?': R:=R+#168;
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

Function Part(Const S: String; N: Integer): String;
Var I,K,B: Integer;
Begin
 K:=1;B:=1;Part:='';
 For I:=1 To Length(S)+1 Do
  If (I>Length(S)) Or (S[I]='~') Then Begin
   If K=N Then Begin Part:=Copy(S,B,I-B);Exit;End;
   Inc(K);B:=I+1;
  End;
End;

{ Texte multilingue : T('fr~en~de~es~it') ; manquant => anglais }
Function T(Const S: String): String;
Var R: String;
Begin
 R:=Part(S,Lang);
 If (R='') And (Lang>1) Then R:=Part(S,2);
 If R='' Then R:=Part(S,1);
 T:=Dc(R);
End;

Function Upper(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do S[I]:=UpCase(S[I]);
 Upper:=S;
End;

Function Lower(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do
  If (S[I]>='A') And (S[I]<='Z') Then S[I]:=Chr(Ord(S[I])+32);
 Lower:=S;
End;

Procedure DetectLanguage;
Var S: String;
Begin
 S:=Upper(GetEnv('LANGUAGE'));
 Lang:=1;
 If Copy(S,1,2)='EN' Then Lang:=2;
 If (Copy(S,1,2)='GR') Or (Copy(S,1,2)='DE') Then Lang:=3;
 If (Copy(S,1,2)='SP') Or (Copy(S,1,2)='ES') Then Lang:=4;
 If Copy(S,1,2)='IT' Then Lang:=5;
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

Function RTrim(S: String): String;
Begin
 While (Length(S)>0) And (S[Length(S)]=' ') Do Dec(S[0]);
 RTrim:=S;
End;



Function ValInt(Const S: String; Def: LongInt): LongInt;
Var V: LongInt; Code: Integer; Q: String;
Begin
 Q:=TrimStr(S);
 Val(Q,V,Code);
 If (Code<>0) Or (Q='') Then ValInt:=Def Else ValInt:=V;
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

Function Rep(C: Char; N: Integer): String;
Var R: String; I: Integer;
Begin
 R:='';
 For I:=1 To N Do R:=R+C;
 Rep:=R;
End;

Function HasStr(Const S,Sub: String): Boolean;
Begin
 HasStr:=Pos(Upper(Sub),Upper(S))>0;
End;

{ ---- argent (cents) ---- }

Function FmtMoney(C: LongInt): String;
Var S,R: String; Neg: Boolean; I,N: Integer; Gs,Dp: Char;
Begin
 Case Lang Of
  2: Begin Gs:=',';Dp:='.';End;
  3,4,5: Begin Gs:='.';Dp:=',';End;
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
    If V<21000000 Div 10 Then V:=V*10+Ord(C)-48 Else V:=210000;
   End;
  End;
 End;
 If FracN=1 Then Fr:=Fr*10;
 V:=V*100+Fr;
 If V>2100000000 Then V:=2100000000;
 If Neg Then V:=-V;
 ParseMoney:=V;
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

Function AddDays(D,N: LongInt): LongInt;
Begin
 AddDays:=DayToDate(DayNum(D)+N);
End;

{ jour de semaine : 0 dimanche .. 6 samedi }
Function WeekDay(D: LongInt): Integer;
Begin
 WeekDay:=Integer((DayNum(D)+2) Mod 7);
End;

Function DaysInMonth(Y,M: Integer): Integer;
Begin
 DaysInMonth:=DayNum(LongInt(Y)*10000+(M Mod 12+1)*100+1)-
   DayNum(LongInt(Y)*10000+M*100+1);
 If M=12 Then DaysInMonth:=31;
End;

Function MonthName(M: Integer): String;
Begin
 Case M Of
  1: MonthName:=T('Janvier~January~Januar~Enero~Gennaio');
  2: MonthName:=T('F@evrier~February~Februar~Febrero~Febbraio');
  3: MonthName:=T('Mars~March~M@1rz~Marzo~Marzo');
  4: MonthName:=T('Avril~April~April~Abril~Aprile');
  5: MonthName:=T('Mai~May~Mai~Mayo~Maggio');
  6: MonthName:=T('Juin~June~Juni~Junio~Giugno');
  7: MonthName:=T('Juillet~July~Juli~Julio~Luglio');
  8: MonthName:=T('Ao@ut~August~August~Agosto~Agosto');
  9: MonthName:=T('Septembre~September~September~Septiembre~Settembre');
  10: MonthName:=T('Octobre~October~Oktober~Octubre~Ottobre');
  11: MonthName:=T('Novembre~November~November~Noviembre~Novembre');
  Else MonthName:=T('D@ecembre~December~Dezember~Diciembre~Dicembre');
 End;
End;

Function DayName(W: Integer): String;
Begin
 Case W Of
  0: DayName:=T('Dimanche~Sunday~Sonntag~Domingo~Domenica');
  1: DayName:=T('Lundi~Monday~Montag~Lunes~Luned@i');
  2: DayName:=T('Mardi~Tuesday~Dienstag~Martes~Marted@i');
  3: DayName:=T('Mercredi~Wednesday~Mittwoch~Mi@ercoles~Mercoled@i');
  4: DayName:=T('Jeudi~Thursday~Donnerstag~Jueves~Gioved@i');
  5: DayName:=T('Vendredi~Friday~Freitag~Viernes~Venerd@i');
  Else DayName:=T('Samedi~Saturday~Samstag~S@qbado~Sabato');
 End;
End;

Function FmtDate(D: LongInt): String;
Var Y,M,Dd: LongInt;
Begin
 If D<=0 Then Begin FmtDate:='';Exit;End;
 Y:=D Div 10000;M:=(D Div 100) Mod 100;Dd:=D Mod 100;
 Case Lang Of
  2: FmtDate:=Two(M)+'/'+Two(Dd)+'/'+IntStr(Y);
  3: FmtDate:=Two(Dd)+'.'+Two(M)+'.'+IntStr(Y);
  Else FmtDate:=Two(Dd)+'/'+Two(M)+'/'+IntStr(Y);
 End;
End;

Function IsoDate(D: LongInt): String;
Begin
 IsoDate:=IntStr(D Div 10000)+'-'+Two((D Div 100) Mod 100)+'-'+Two(D Mod 100);
End;

Function ParseDate(Const S: String; Var D: LongInt): Boolean;
Var N: Array[1..3] Of LongInt; L: Array[1..3] Of Integer; Cnt,I: Integer;
    InNum: Boolean; Y,M,Dd: LongInt;
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
 If Cnt<>3 Then Exit;
 If L[1]>=3 Then Begin Y:=N[1];M:=N[2];Dd:=N[3];End
 Else If Lang=2 Then Begin M:=N[1];Dd:=N[2];Y:=N[3];End
 Else Begin Dd:=N[1];M:=N[2];Y:=N[3];End;
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

Function NowTime: String;
Var H,M,S,S1: Word;
Begin
 GetTime(H,M,S,S1);
 NowTime:=Two(H)+':'+Two(M);
End;

{ heure unix approximative (pour les en-tetes MyISAM) }
Function UnixNow: LongInt;
Var H,M,S,S1: Word; D: LongInt;
Begin
 GetTime(H,M,S,S1);
 D:=DayNum(TodayDate)-DayNum(19700101);
 UnixNow:=D*86400+LongInt(H)*3600+M*60+S;
End;

{ ====================================================================== }
{          MOTEUR DE BASE DE DONNEES MyISAM (.frm .MYD .MYI)             }
{ ====================================================================== }
{ Format compatible MariaDB / MySQL 5.x : table statique (ROW_FORMAT=FIXED),
  cle primaire ID (INT, auto-increment). Les types supportes sont :
  INT, SMALLINT, TINYINT, CHAR(n), DATE.                                  }

Const
 {$IFDEF UNIX}
  DirSep = '/';
 {$ELSE}
  DirSep = '\';
 {$ENDIF}
 FRM_KEYLEN = 505;
 CAP_LEAF   = 100;
 CAP_NODE   = 60;

Type
 TBig = Array[0..8191] Of Byte;
 PBig = ^TBig;

Var
 DbErr   : String[80];
 BigBuf  : PBig;
 PgBuf   : PBig;
 PgNext  : LongInt;
 PgFile  : File;
 PgTbl   : PTbl;
 ScanBuf : PBig;

Procedure PutLE(B: PBig; O: Integer; V: LongInt; N: Integer);
Var I: Integer;
Begin
 For I:=0 To N-1 Do Begin
  B^[O+I]:=Byte(V And 255);
  V:=V Shr 8;
 End;
End;

Procedure PutBE(B: PBig; O,N: Integer; V: LongInt);
Var I: Integer;
Begin
 For I:=N-1 DownTo 0 Do Begin
  B^[O+I]:=Byte(V And 255);
  V:=V Shr 8;
 End;
End;

Function GetLE(B: PBig; O,N: Integer): LongInt;
Var I: Integer; V: LongInt;
Begin
 V:=0;
 For I:=N-1 DownTo 0 Do V:=(V Shl 8) Or B^[O+I];
 GetLE:=V;
End;

Function GetBE(B: PBig; O,N: Integer): LongInt;
Var I: Integer; V: LongInt;
Begin
 V:=0;
 For I:=0 To N-1 Do V:=(V Shl 8) Or B^[O+I];
 GetBE:=V;
End;

Function TblPath(Const Nm,Ext: String): String;
Begin
 TblPath:=DbDir+DirSep+Lower(Nm)+'.'+Ext;
End;

Function DateToMy(D: LongInt): LongInt;
Begin
 If D<=0 Then DateToMy:=0
 Else DateToMy:=(D Div 10000)*512+((D Div 100) Mod 100)*32+D Mod 100;
End;

Function MyToDate(V: LongInt): LongInt;
Begin
 MyToDate:=(V Shr 9)*10000+((V Shr 5) And 15)*100+(V And 31);
End;

{ ---- definition des champs ---- }

Function FldIndex(T: PTbl; Const Nm: String): Integer;
Var I: Integer; U: String;
Begin
 U:=Upper(Nm);
 FldIndex:=0;
 For I:=1 To T^.NF Do If T^.F[I].Nm=U Then Begin FldIndex:=I;Exit;End;
End;

Function AddFld(T: PTbl; Const Nm: String; Typ: Char; Len: Integer): Boolean;
Var I: Integer;
Begin
 AddFld:=False;
 If T^.NF>=MAXFLD Then Begin DbErr:='Too many columns';Exit;End;
 Inc(T^.NF);
 I:=T^.NF;
 T^.F[I].Nm:=Upper(Nm);
 T^.F[I].Typ:=Typ;
 Case Typ Of
  'I': Begin T^.F[I].Sz:=4;T^.F[I].Len:=11;End;
  'S': Begin T^.F[I].Sz:=2;T^.F[I].Len:=6;End;
  'B': Begin T^.F[I].Sz:=1;T^.F[I].Len:=4;End;
  'D': Begin T^.F[I].Sz:=3;T^.F[I].Len:=10;End;
  Else Begin
   If Len<1 Then Len:=1;
   If Len>255 Then Len:=255;
   T^.F[I].Typ:='C';T^.F[I].Sz:=Len;T^.F[I].Len:=Len;
  End;
 End;
 If I=1 Then T^.F[I].Off:=1
 Else T^.F[I].Off:=T^.F[I-1].Off+T^.F[I-1].Sz;
 T^.RecLen:=T^.F[I].Off+T^.F[I].Sz;
 If T^.RecLen>MAXREC Then Begin DbErr:='Row too long';Dec(T^.NF);Exit;End;
 AddFld:=True;
End;

{ spec : 'ID:I,NOM:C40,DATE:D' }
Function ParseSpec(T: PTbl; Const Spec,Spec2: String): Boolean;
Var I,P,N1,N: Integer; Tk,Nm: String; Ty: Char; L: Integer; C: Char;
Begin
 ParseSpec:=False;
 T^.NF:=0;T^.RecLen:=1;
 Tk:='';N1:=Length(Spec);N:=N1+Length(Spec2);
 For I:=1 To N+1 Do Begin
  If I<=N1 Then C:=Spec[I] Else If I<=N Then C:=Spec2[I-N1] Else C:=',';
  If C=',' Then Begin
   P:=Pos(':',Tk);
   If P=0 Then Begin DbErr:='Bad spec';Exit;End;
   Nm:=Copy(Tk,1,P-1);
   Ty:=UpCase(Tk[P+1]);
   L:=ValInt(Copy(Tk,P+2,10),1);
   If Not AddFld(T,Nm,Ty,L) Then Exit;
   Tk:='';
  End Else Tk:=Tk+C;
 End;
 If (T^.NF<1) Or (T^.F[1].Typ<>'I') Or (T^.F[1].Nm<>'ID') Then Begin
  DbErr:='First column must be ID INT';Exit;
 End;
 If T^.RecLen<5 Then T^.RecLen:=5;
 ParseSpec:=True;
End;

{ ---- ecriture du .frm ---- }

Procedure FrmField(B: PBig; O: Integer; Const F: TFld; First: Boolean);
Var Ln,Pf,Ty,Cs: Integer;
Begin
 Cs:=8;Pf:=0;
 Case F.Typ Of
  'I': Begin Ln:=11;Pf:=$1B;Ty:=3;End;
  'S': Begin Ln:=6;Pf:=$13;Ty:=2;End;
  'B': Begin Ln:=4;Pf:=$0B;Ty:=1;End;
  'D': Begin Ln:=10;Pf:=$70;Ty:=$0E;End;
  Else Begin Ln:=F.Len;Pf:=0;Ty:=$FE;Cs:=4;End;
 End;
 PutLE(B,O+3,Ln,2);
 PutLE(B,O+5,F.Off+1,3);
 PutLE(B,O+8,Pf,2);
 If First Then B^[O+10]:=$0F;
 B^[O+13]:=Ty;
 B^[O+14]:=Cs;
End;

Function WriteFrm(T: PTbl): Boolean;
Var B: PBig; I,O,Tot,FPos,NLen,TotLen,KeyOff,RecOff,P: Integer;
    F: File; Nm: String; U: LongInt;
Const Key1 : Array[0..32] Of Byte =
 ($01,$01,$00,$00,$0A,$00,$00,$00,$04,$00,$01,$00,$00,$00,
  $01,$80,$02,$00,$00,$1B,$00,$04,$00,
  $FF,$50,$52,$49,$4D,$41,$52,$59,$FF,$00);
Begin
 WriteFrm:=False;
 B:=BigBuf;
 FillChar(B^,8192,0);
 NLen:=2;TotLen:=0;
 For I:=1 To T^.NF Do Begin
  NLen:=NLen+Length(T^.F[I].Nm)+1;
  TotLen:=TotLen+T^.F[I].Len;
 End;
 KeyOff:=89;
 RecOff:=KeyOff+FRM_KEYLEN;
 FPos:=RecOff+T^.RecLen+16;
 Tot:=FPos+288+17*T^.NF+NLen;
 { en-tete }
 B^[0]:=$FE;B^[1]:=1;B^[2]:=$0A;B^[3]:=9;
 PutLE(B,4,21,2);PutLE(B,6,KeyOff,2);PutLE(B,8,1,2);
 PutLE(B,10,Tot,4);PutLE(B,14,FRM_KEYLEN,2);PutLE(B,16,T^.RecLen,2);
 B^[27]:=2;PutLE(B,28,33,2);PutLE(B,30,8,2);B^[33]:=5;
 B^[38]:=4;B^[40]:=1;PutLE(B,47,FRM_KEYLEN,4);PutLE(B,51,100603,4);
 PutLE(B,55,16,4);
 { extra2 : version de table + indicateurs d'index }
 B^[64]:=0;B^[65]:=16;
 U:=T^.Ctime;
 For I:=0 To 15 Do Begin
  B^[66+I]:=Byte((U Shr ((I Mod 4)*8)) Xor (I*37) Xor Length(T^.Nm));
 End;
 B^[82]:=5;B^[83]:=1;B^[84]:=0;
 PutLE(B,85,FPos,4);
 { cle primaire }
 For I:=0 To 32 Do B^[KeyOff+I]:=Key1[I];
 { enregistrement par defaut }
 B^[RecOff]:=$FF;
 For I:=1 To T^.NF Do
  If T^.F[I].Typ='C' Then
   FillChar(B^[RecOff+T^.F[I].Off],T^.F[I].Sz,' ');
 P:=RecOff+T^.RecLen;
 PutLE(B,P,0,2);PutLE(B,P+2,6,2);
 Move('MyISAM',B^[P+4],6);
 { forminfo }
 O:=FPos;
 PutLE(B,O,NLen+17*T^.NF+288,2);PutLE(B,O+2,NLen+17*T^.NF+288,2);
 PutLE(B,O+258,T^.NF,2);PutLE(B,O+262,TotLen,2);
 PutLE(B,O+266,T^.RecLen,2);PutLE(B,O+268,NLen,2);
 PutLE(B,O+278,80,2);PutLE(B,O+280,22,2);
 { champs }
 O:=FPos+288;
 For I:=1 To T^.NF Do Begin
  FrmField(B,O+(I-1)*17,T^.F[I],I=1);
 End;
 O:=O+17*T^.NF;
 B^[O]:=$FF;Inc(O);
 For I:=1 To T^.NF Do Begin
  Nm:=Lower(T^.F[I].Nm);
  Move(Nm[1],B^[O],Length(Nm));
  O:=O+Length(Nm);
  B^[O]:=$FF;Inc(O);
 End;
 B^[O]:=0;
 {$I-}
 Assign(F,TblPath(T^.Nm,'frm'));
 Rewrite(F,1);
 BlockWrite(F,B^,Tot);
 Close(F);
 {$I+}
 If IOResult<>0 Then Begin DbErr:='Cannot write .frm';Exit;End;
 WriteFrm:=True;
End;

{ ---- lecture du .frm ---- }

Function ReadFrm(T: PTbl): Boolean;
Var B: PBig; F: File; Sz,Got: Word; I,O,E2,FPos,N,NL,P,Ty,Ln: Integer;
    Nm: String; Fl: Char;
Begin
 ReadFrm:=False;
 B:=BigBuf;
 FillChar(B^,8192,0);
 {$I-}
 Assign(F,TblPath(T^.Nm,'frm'));
 Reset(F,1);
 If IOResult<>0 Then Begin DbErr:='No .frm';Exit;End;
 BlockRead(F,B^,8192,Got);
 Close(F);
 {$I+}
 If (Got<400) Or (B^[0]<>$FE) Or (B^[1]<>1) Or (B^[3]<>9) Then Begin
  DbErr:='Not a MyISAM .frm';Exit;
 End;
 T^.RecLen:=GetLE(B,16,2);
 T^.Ctime:=0;
 E2:=GetLE(B,4,2);
 FPos:=GetLE(B,64+E2,4);
 If (FPos<100) Or (FPos+288>Got) Then Begin DbErr:='Bad .frm';Exit;End;
 N:=GetLE(B,FPos+258,2);
 NL:=GetLE(B,FPos+268,2);
 If (N<1) Or (N>MAXFLD) Then Begin DbErr:='Bad column count';Exit;End;
 T^.NF:=N;
 O:=FPos+288;
 P:=O+17*N+1;
 For I:=1 To N Do Begin
  Ty:=B^[O+(I-1)*17+13];
  Ln:=GetLE(B,O+(I-1)*17+3,2);
  Case Ty Of
   3: Fl:='I'; 2: Fl:='S'; 1: Fl:='B'; $0E: Fl:='D'; $FE: Fl:='C';
   Else Begin DbErr:='Unsupported column type';Exit;End;
  End;
  T^.F[I].Typ:=Fl;
  T^.F[I].Off:=GetLE(B,O+(I-1)*17+5,3)-1;
  Case Fl Of
   'I': T^.F[I].Sz:=4;
   'S': T^.F[I].Sz:=2;
   'B': T^.F[I].Sz:=1;
   'D': T^.F[I].Sz:=3;
   Else T^.F[I].Sz:=Ln;
  End;
  T^.F[I].Len:=Ln;
  Nm:='';
  While (P<Got) And (B^[P]<>$FF) And (Length(Nm)<16) Do Begin
   Nm:=Nm+Chr(B^[P]);Inc(P);
  End;
  Inc(P);
  T^.F[I].Nm:=Upper(Nm);
 End;
 If (T^.F[1].Nm<>'ID') Or (T^.F[1].Typ<>'I') Or (T^.F[1].Off<>1) Then Begin
  DbErr:='Unsupported key layout';Exit;
 End;
 ReadFrm:=True;
End;

{ ---- fichier d'index .MYI ---- }

Function PCap(H: Integer): LongInt;
Var I: Integer; C: LongInt;
Begin
 C:=CAP_LEAF;
 For I:=2 To H Do C:=CAP_NODE+(CAP_NODE+1)*C;
 PCap:=C;
End;

Procedure PageFlush(Used: Integer);
Begin
 BlockWrite(PgFile,PgBuf^,MYI_BLK);
 Inc(PgNext,MYI_BLK);
End;

Procedure PutKey(O: Integer; E: Integer);
Begin
 PutBE(PgBuf,O,4,PgTbl^.Ix^[E].Id);
 PutBE(PgBuf,O+4,RECREF,PgTbl^.Ix^[E].Slot);
End;

Function BuildNode(Lo,Hi,H: Integer): LongInt;
Var N,K,I,Pos,Rem,Base,Ext,Sz,O: Integer; Kids: Array[0..CAP_NODE] Of LongInt;
    Cp: LongInt;
Begin
 N:=Hi-Lo+1;
 If H=1 Then Begin
  FillChar(PgBuf^,MYI_BLK,0);
  PutBE(PgBuf,0,2,2+10*N);
  For I:=0 To N-1 Do PutKey(2+10*I,Lo+I);
  BuildNode:=PgNext;
  PageFlush(0);
  Exit;
 End;
 Cp:=PCap(H-1);
 { plus petit K tel que (K+1)*Cp+K >= N }
 K:=1;
 While (K<CAP_NODE) And ((LongInt(K)+1)*Cp+K<N) Do Inc(K);
 Rem:=N-K;
 Base:=Rem Div (K+1);Ext:=Rem Mod (K+1);
 Pos:=Lo;
 For I:=0 To K Do Begin
  Sz:=Base;
  If I<Ext Then Inc(Sz);
  Kids[I]:=BuildNode(Pos,Pos+Sz-1,H-1);
  Pos:=Pos+Sz;
  If I<K Then Inc(Pos);
 End;
 FillChar(PgBuf^,MYI_BLK,0);
 PutBE(PgBuf,0,2,$8000+2+KEYREF*(K+1)+10*K);
 O:=2;
 Pos:=Lo;
 For I:=0 To K Do Begin
  Sz:=Base;
  If I<Ext Then Inc(Sz);
  PutBE(PgBuf,O,KEYREF,Kids[I] Div MYI_BLK);
  Inc(O,KEYREF);
  Pos:=Pos+Sz;
  If I<K Then Begin
   PutKey(O,Pos);
   Inc(O,10);
   Inc(Pos);
  End;
 End;
 BuildNode:=PgNext;
 PageFlush(0);
End;

Function WriteMyi(T: PTbl): Boolean;
Var B: PBig; I,O,H,HL: Integer; Root: LongInt; Recs: LongInt;
Begin
 WriteMyi:=False;
 B:=BigBuf;
 FillChar(B^,8192,0);
 PgTbl:=T;
 Recs:=T^.NIdx;
 HL:=326+7*(T^.NF+1);
 {$I-}
 Assign(PgFile,TblPath(T^.Nm,'MYI'));
 Rewrite(PgFile,1);
 {$I+}
 If IOResult<>0 Then Begin DbErr:='Cannot write .MYI';Exit;End;
 { pages d'index (apres le bloc d'en-tete) }
 FillChar(PgBuf^,MYI_BLK,0);
 BlockWrite(PgFile,PgBuf^,MYI_BLK);
 PgNext:=MYI_BLK;
 Root:=-1;
 If T^.NIdx>0 Then Begin
  H:=1;
  While PCap(H)<T^.NIdx Do Inc(H);
  Root:=BuildNode(1,T^.NIdx,H);
 End;
 { en-tete }
 B^[0]:=$FE;B^[1]:=$FE;B^[2]:=7;B^[3]:=1;
 PutBE(B,6,2,HL);PutBE(B,8,2,176);PutBE(B,10,2,100);PutBE(B,12,2,196);
 PutBE(B,14,2,1);B^[18]:=1;B^[20]:=4;B^[21]:=1;
 B^[26]:=$39;B^[27]:=$FF;
 PutBE(B,28,8,Recs);
 PutBE(B,36,8,T^.Del);
 PutBE(B,44,8,T^.Slots);
 If T^.DelLink<0 Then FillChar(B^[52],8,$FF) Else PutBE(B,52,8,T^.DelLink);
 PutBE(B,60,8,PgNext);
 PutBE(B,68,8,T^.Slots*T^.RecLen);
 PutBE(B,76,8,T^.Del*T^.RecLen);
 PutBE(B,92,8,T^.AutoInc);
 PutBE(B,108,4,1233);PutBE(B,112,4,20);PutBE(B,120,4,T^.Upd);
 If Root<0 Then FillChar(B^[124],8,$FF) Else PutBE(B,124,8,Root);
 FillChar(B^[132],8,$FF);
 PutBE(B,148,4,T^.Ctime);PutBE(B,152,8,1);PutBE(B,160,8,T^.Ctime);
 PutBE(B,184,8,Recs);PutBE(B,192,4,1);
 { base info }
 PutBE(B,196,8,MYI_BLK);
 PutBE(B,240,4,T^.RecLen);PutBE(B,244,4,T^.RecLen);
 PutBE(B,248,4,T^.RecLen);PutBE(B,252,4,T^.RecLen);
 PutBE(B,256,4,20);PutBE(B,260,4,T^.NF+1);
 B^[268]:=RECREF;B^[269]:=KEYREF;B^[270]:=1;B^[271]:=1;
 PutBE(B,276,2,MYI_BLK);PutBE(B,278,2,16);
 { definition de cle }
 B^[296]:=1;B^[297]:=1;PutBE(B,298,2,$11);PutBE(B,300,2,MYI_BLK);
 PutBE(B,302,2,10);PutBE(B,304,2,10);PutBE(B,306,2,10);
 B^[308]:=4;B^[309]:=63;PutBE(B,314,2,$40);PutBE(B,316,2,4);
 PutBE(B,318,4,1);
 { colonnes }
 PutBE(B,328,2,1);
 For I:=1 To T^.NF Do PutBE(B,326+7*I+2,2,T^.F[I].Sz);
 Seek(PgFile,0);
 BlockWrite(PgFile,B^,MYI_BLK);
 Close(PgFile);
 WriteMyi:=IOResult=0;
End;

{ ---- tables ouvertes ---- }

Procedure SortIdx(T: PTbl);
Var Gap,I,J: Integer; X: TIdxE;
Begin
 Gap:=T^.NIdx Div 2;
 While Gap>0 Do Begin
  For I:=Gap+1 To T^.NIdx Do Begin
   X:=T^.Ix^[I];
   J:=I;
   While (J>Gap) And (T^.Ix^[J-Gap].Id>X.Id) Do Begin
    T^.Ix^[J]:=T^.Ix^[J-Gap];
    Dec(J,Gap);
   End;
   T^.Ix^[J]:=X;
  End;
  Gap:=Gap Div 2;
 End;
End;

Function RowGet(I: Integer; Slot: LongInt; B: PRec): Boolean;
Var T: PTbl;
Begin
 T:=Tb[I];
 RowGet:=False;
 If (Slot<0) Or (Slot>=T^.Slots) Then Exit;
 {$I-}
 Seek(T^.Dat,Slot*T^.RecLen);
 BlockRead(T^.Dat,B^,T^.RecLen);
 {$I+}
 If IOResult<>0 Then Exit;
 RowGet:=B^[0]<>0;
End;

Function RowFind(I: Integer; Id: LongInt): LongInt;
Var T: PTbl; Lo,Hi,Md: Integer;
Begin
 T:=Tb[I];
 RowFind:=-1;
 Lo:=1;Hi:=T^.NIdx;
 While Lo<=Hi Do Begin
  Md:=(Lo+Hi) Div 2;
  If T^.Ix^[Md].Id=Id Then Begin RowFind:=T^.Ix^[Md].Slot;Exit;End;
  If T^.Ix^[Md].Id<Id Then Lo:=Md+1 Else Hi:=Md-1;
 End;
End;

Function IdxPos(T: PTbl; Id: LongInt): Integer;
Var Lo,Hi,Md: Integer;
Begin
 Lo:=1;Hi:=T^.NIdx;
 While Lo<=Hi Do Begin
  Md:=(Lo+Hi) Div 2;
  If T^.Ix^[Md].Id<Id Then Lo:=Md+1 Else Hi:=Md-1;
 End;
 IdxPos:=Lo;
End;

Procedure IxGrow(T: PTbl; Cap: Integer);
Var P: PIdx;
Begin
 If Cap>MAXIDX Then Cap:=MAXIDX;
 If Cap<=T^.IxCap Then Exit;
 GetMem(P,Cap*SizeOf(TIdxE));
 Move(T^.Ix^,P^,T^.NIdx*SizeOf(TIdxE));
 FreeMem(T^.Ix,T^.IxCap*SizeOf(TIdxE));
 T^.Ix:=P;T^.IxCap:=Cap;
End;

Procedure ScanTable(T: PTbl);
Var Per,N,I,J: Integer; Got: Word; Base,Id: LongInt; Last: LongInt;
Begin
 T^.NIdx:=0;T^.Del:=0;T^.AutoInc:=0;
 IxGrow(T,Integer(T^.Slots)+Integer(T^.Slots) Div 2+16);
 Per:=8192 Div T^.RecLen;
 If Per<1 Then Per:=1;
 Base:=0;
 Seek(T^.Dat,0);
 While Base<T^.Slots Do Begin
  N:=Per;
  If Base+N>T^.Slots Then N:=T^.Slots-Base;
  BlockRead(T^.Dat,ScanBuf^,N*T^.RecLen,Got);
  For I:=0 To N-1 Do Begin
   J:=I*T^.RecLen;
   If ScanBuf^[J]<>0 Then Begin
    If T^.NIdx<MAXIDX Then Begin
     Inc(T^.NIdx);
     Id:=GetLE(ScanBuf,J+1,4);
     T^.Ix^[T^.NIdx].Id:=Id;
     T^.Ix^[T^.NIdx].Slot:=Base+I;
     If Id>T^.AutoInc Then T^.AutoInc:=Id;
    End;
   End Else Inc(T^.Del);
  End;
  Inc(Base,N);
 End;
 SortIdx(T);
End;

{ relie tous les enregistrements supprimes (chaine DelLink) }
Procedure RelinkDeleted(T: PTbl);
Var S: LongInt; Per,N,I,J: Integer; Got: Word; Base: LongInt;
    Prev: LongInt; B: TRec;
Begin
 T^.DelLink:=-1;
 Prev:=-1;
 For S:=0 To T^.Slots-1 Do Begin
  Seek(T^.Dat,S*T^.RecLen);
  BlockRead(T^.Dat,B,T^.RecLen);
  If B[0]=0 Then Begin
   If T^.DelLink<0 Then T^.DelLink:=S*T^.RecLen
   Else Begin
    { le precedent pointe vers ce slot }
    Seek(T^.Dat,Prev*T^.RecLen+1);
    PutBE(BigBuf,0,RECREF,S);
    BlockWrite(T^.Dat,BigBuf^,RECREF);
   End;
   Prev:=S;
  End;
 End;
 If Prev>=0 Then Begin
  FillChar(BigBuf^,RECREF,$FF);
  Seek(T^.Dat,Prev*T^.RecLen+1);
  BlockWrite(T^.Dat,BigBuf^,RECREF);
 End;
End;

Procedure NewTblRec(Var P: PTbl);
Begin
 New(P);
 FillChar(P^,SizeOf(TTbl),0);
 P^.DelLink:=-1;
 P^.Ctime:=UnixNow;
 P^.IxCap:=64;
 GetMem(P^.Ix,64*SizeOf(TIdxE));
End;

Function TblCreate2(Const Nm,Spec,Spec2: String): Boolean;
Var T: PTbl; F: File;
Begin
 TblCreate2:=False;
 NewTblRec(T);
 T^.Nm:=Lower(Nm);
 If Not ParseSpec(T,Spec,Spec2) Then Begin
  FreeMem(T^.Ix,T^.IxCap*SizeOf(TIdxE));Dispose(T);Exit;
 End;
 If WriteFrm(T) Then Begin
  {$I-}
  Assign(F,TblPath(T^.Nm,'MYD'));
  Rewrite(F,1);
  Close(F);
  {$I+}
  If (IOResult=0) And WriteMyi(T) Then TblCreate2:=True;
 End;
 FreeMem(T^.Ix,T^.IxCap*SizeOf(TIdxE));
 Dispose(T);
End;

Function TblCreate(Const Nm,Spec: String): Boolean;
Begin
 TblCreate:=TblCreate2(Nm,Spec,'');
End;

Function TblOpen(Const Nm: String): Integer;
Var T: PTbl; Sz: LongInt; H: PBig; F: File; Got: Word; HdrOk: Boolean;
    Recs: LongInt;
Begin
 TblOpen:=0;
 If NTb>=MAXTBL Then Begin DbErr:='Too many tables';Exit;End;
 If Not FileExists(TblPath(Nm,'frm')) Then Begin
  DbErr:='Table not found: '+Nm;Exit;
 End;
 NewTblRec(T);
 T^.Nm:=Lower(Nm);
 If Not ReadFrm(T) Then Begin
  FreeMem(T^.Ix,T^.IxCap*SizeOf(TIdxE));Dispose(T);Exit;
 End;
 {$I-}
 Assign(T^.Dat,TblPath(Nm,'MYD'));
 Reset(T^.Dat,1);
 If IOResult<>0 Then Begin
  Rewrite(T^.Dat,1);Close(T^.Dat);Reset(T^.Dat,1);
 End;
 Sz:=FileSize(T^.Dat);
 {$I+}
 If Sz Mod T^.RecLen<>0 Then Begin
  DbErr:='Bad .MYD size';Close(T^.Dat);
  FreeMem(T^.Ix,T^.IxCap*SizeOf(TIdxE));Dispose(T);Exit;
 End;
 T^.Slots:=Sz Div T^.RecLen;
 If T^.Slots>MAXIDX Then Begin
  DbErr:='Table too large';Close(T^.Dat);
  FreeMem(T^.Ix,T^.IxCap*SizeOf(TIdxE));Dispose(T);Exit;
 End;
 ScanTable(T);
 { lecture de l'en-tete .MYI : chaine des supprimes et compteur }
 HdrOk:=False;
 H:=PgBuf;
 If FileExists(TblPath(Nm,'MYI')) Then Begin
  {$I-}
  Assign(F,TblPath(Nm,'MYI'));
  Reset(F,1);
  BlockRead(F,H^,200,Got);
  Close(F);
  {$I+}
  If (Got>=200) And (H^[0]=$FE) And (H^[1]=$FE) Then Begin
   Recs:=GetBE(H,32,4);
   If (Recs=T^.NIdx) And (GetBE(H,40,4)=T^.Del) Then Begin
    If H^[52]=$FF Then T^.DelLink:=-1 Else T^.DelLink:=GetBE(H,56,4);
    T^.Upd:=GetBE(H,120,4);
    T^.Ctime:=GetBE(H,148,4);
    If GetBE(H,96,4)>T^.AutoInc Then T^.AutoInc:=GetBE(H,96,4);
    HdrOk:=True;
   End;
  End;
 End;
 If Not HdrOk Then Begin
  {$I-}
  RelinkDeleted(T);
  {$I+}
  T^.IxDirty:=True;T^.HdDirty:=True;
 End;
 T^.Opn:=True;
 Inc(NTb);
 Tb[NTb]:=T;
 TblOpen:=NTb;
End;

Function TblIdx(Const Nm: String): Integer;
Var I: Integer; U: String;
Begin
 U:=Lower(Nm);
 For I:=1 To NTb Do If Tb[I]^.Nm=U Then Begin TblIdx:=I;Exit;End;
 TblIdx:=TblOpen(Nm);
End;

Procedure TblFlush(I: Integer);
Var T: PTbl;
Begin
 T:=Tb[I];
 If T^.IxDirty Or T^.HdDirty Then Begin
  Inc(T^.Upd);
  WriteMyi(T);
  T^.IxDirty:=False;T^.HdDirty:=False;
 End;
End;

Procedure TblFlushAll;
Var I: Integer;
Begin
 For I:=1 To NTb Do TblFlush(I);
End;

Procedure TblCloseAll;
Var I: Integer;
Begin
 TblFlushAll;
 For I:=1 To NTb Do Begin
  {$I-}
  Close(Tb[I]^.Dat);
  {$I+}
  If IOResult<>0 Then ;
  FreeMem(Tb[I]^.Ix,Tb[I]^.IxCap*SizeOf(TIdxE));
  Dispose(Tb[I]);
 End;
 NTb:=0;
End;

{ ---- operations sur les enregistrements ---- }

Procedure NewRow(I: Integer; B: PRec);
Var T: PTbl; K: Integer;
Begin
 T:=Tb[I];
 FillChar(B^,MAXREC,0);
 B^[0]:=$FF;
 For K:=1 To T^.NF Do
  If T^.F[K].Typ='C' Then FillChar(B^[T^.F[K].Off],T^.F[K].Sz,' ');
End;

Function GetN(I: Integer; B: PRec; F: Integer): LongInt;
Var T: PTbl; V: LongInt; K,O: Integer;
Begin
 T:=Tb[I];
 O:=T^.F[F].Off;
 V:=0;
 Case T^.F[F].Typ Of
  'I': Begin
        V:=B^[O] Or (LongInt(B^[O+1]) Shl 8) Or (LongInt(B^[O+2]) Shl 16)
          Or (LongInt(B^[O+3]) Shl 24);
       End;
  'S': Begin
        V:=B^[O] Or (Integer(B^[O+1]) Shl 8);
        If V>=32768 Then V:=V-65536;
       End;
  'B': Begin
        V:=B^[O];
        If V>=128 Then V:=V-256;
       End;
  'D': Begin
        V:=B^[O] Or (LongInt(B^[O+1]) Shl 8) Or (LongInt(B^[O+2]) Shl 16);
        V:=MyToDate(V);
       End;
 End;
 GetN:=V;
End;

Procedure SetN(I: Integer; B: PRec; F: Integer; V: LongInt);
Var T: PTbl; O,K: Integer;
Begin
 T:=Tb[I];
 O:=T^.F[F].Off;
 If T^.F[F].Typ='D' Then V:=DateToMy(V);
 For K:=0 To T^.F[F].Sz-1 Do Begin
  B^[O+K]:=Byte(V And 255);
  V:=V Shr 8;
 End;
End;

Function GetS(I: Integer; B: PRec; F: Integer): String;
Var T: PTbl; S: String; K,O,N: Integer;
Begin
 T:=Tb[I];
 If T^.F[F].Typ<>'C' Then Begin
  If T^.F[F].Typ='D' Then GetS:=IsoDate(GetN(I,B,F))
  Else GetS:=IntStr(GetN(I,B,F));
  Exit;
 End;
 O:=T^.F[F].Off;N:=T^.F[F].Sz;
 While (N>0) And (B^[O+N-1]=32) Do Dec(N);
 S[0]:=Chr(N);
 For K:=1 To N Do S[K]:=Chr(B^[O+K-1]);
 GetS:=S;
End;

Procedure SetS(I: Integer; B: PRec; F: Integer; Const S: String);
Var T: PTbl; K,O,N: Integer; D: LongInt;
Begin
 T:=Tb[I];
 If T^.F[F].Typ<>'C' Then Begin
  If T^.F[F].Typ='D' Then Begin
   D:=0;
   If Length(S)>=10 Then
    D:=ValInt(Copy(S,1,4),0)*10000+ValInt(Copy(S,6,2),0)*100
      +ValInt(Copy(S,9,2),0);
   SetN(I,B,F,D);
  End Else SetN(I,B,F,ValInt(S,0));
  Exit;
 End;
 O:=T^.F[F].Off;N:=T^.F[F].Sz;
 For K:=1 To N Do
  If K<=Length(S) Then B^[O+K-1]:=Ord(S[K]) Else B^[O+K-1]:=32;
End;

Function RowAdd(I: Integer; B: PRec): LongInt;
Var T: PTbl; Slot,Nx: LongInt; P: Integer; Id: LongInt;
Begin
 T:=Tb[I];
 RowAdd:=0;
 Id:=GetN(I,B,1);
 If Id<=0 Then Begin Id:=T^.AutoInc+1;SetN(I,B,1,Id);End
 Else If RowFind(I,Id)>=0 Then Begin DbErr:='Duplicate key';Exit;End;
 If T^.NIdx>=MAXIDX Then Begin DbErr:='Table full';Exit;End;
 If T^.NIdx>=T^.IxCap Then IxGrow(T,T^.IxCap*2);
 B^[0]:=$FF;
 {$I-}
 If T^.DelLink>=0 Then Begin
  Slot:=T^.DelLink Div T^.RecLen;
  Seek(T^.Dat,T^.DelLink+1);
  BlockRead(T^.Dat,BigBuf^,RECREF);
  If BigBuf^[0]=$FF Then T^.DelLink:=-1
  Else T^.DelLink:=GetBE(BigBuf,2,4)*T^.RecLen;
  Dec(T^.Del);
 End Else Begin
  Slot:=T^.Slots;
  Inc(T^.Slots);
 End;
 Seek(T^.Dat,Slot*T^.RecLen);
 BlockWrite(T^.Dat,B^,T^.RecLen);
 {$I+}
 If IOResult<>0 Then Begin DbErr:='Write error';Exit;End;
 P:=IdxPos(T,Id);
 If P<=T^.NIdx Then Move(T^.Ix^[P],T^.Ix^[P+1],(T^.NIdx-P+1)*SizeOf(TIdxE));
 T^.Ix^[P].Id:=Id;T^.Ix^[P].Slot:=Slot;
 Inc(T^.NIdx);
 If Id>T^.AutoInc Then T^.AutoInc:=Id;
 T^.IxDirty:=True;
 RowAdd:=Id;
End;

Function RowPut(I: Integer; Slot: LongInt; B: PRec): Boolean;
Var T: PTbl;
Begin
 T:=Tb[I];
 RowPut:=False;
 B^[0]:=$FF;
 {$I-}
 Seek(T^.Dat,Slot*T^.RecLen);
 BlockWrite(T^.Dat,B^,T^.RecLen);
 {$I+}
 If IOResult<>0 Then Exit;
 T^.HdDirty:=True;
 RowPut:=True;
End;

Procedure RowDel(I: Integer; Slot: LongInt);
Var T: PTbl; Id: LongInt; P: Integer; B: TRec;
Begin
 T:=Tb[I];
 {$I-}
 Seek(T^.Dat,Slot*T^.RecLen);
 BlockRead(T^.Dat,B,T^.RecLen);
 If B[0]=0 Then Exit;
 Id:=B[1] Or (LongInt(B[2]) Shl 8) Or (LongInt(B[3]) Shl 16)
    Or (LongInt(B[4]) Shl 24);
 B[0]:=0;
 If T^.DelLink<0 Then FillChar(BigBuf^,RECREF,$FF)
 Else PutBE(BigBuf,0,RECREF,T^.DelLink Div T^.RecLen);
 Move(BigBuf^,B[1],RECREF);
 Seek(T^.Dat,Slot*T^.RecLen);
 BlockWrite(T^.Dat,B,T^.RecLen);
 {$I+}
 T^.DelLink:=Slot*T^.RecLen;
 Inc(T^.Del);
 P:=IdxPos(T,Id);
 If (P<=T^.NIdx) And (T^.Ix^[P].Id=Id) Then Begin
  If P<T^.NIdx Then Move(T^.Ix^[P+1],T^.Ix^[P],(T^.NIdx-P)*SizeOf(TIdxE));
  Dec(T^.NIdx);
 End;
 T^.IxDirty:=True;
End;

Procedure DbInit;
Begin
 NTb:=0;
 GetMem(BigBuf,SizeOf(TBig));
 GetMem(PgBuf,SizeOf(TBig));
 GetMem(ScanBuf,SizeOf(TBig));
 GetMem(RB,SizeOf(TRec));
 GetMem(RB2,SizeOf(TRec));
 GetMem(RBF,SizeOf(TRec));
End;

{ ====================================================================== }
{                          MOTEUR SQL (sous-ensemble)                    }
{ ====================================================================== }
{ SELECT (WHERE, JOIN, GROUP BY, ORDER BY, LIMIT, COUNT/SUM/AVG/MIN/MAX),
  INSERT, UPDATE, DELETE, CREATE TABLE, DROP TABLE, SHOW TABLES, DESCRIBE,
  CHECK TABLE, REPAIR TABLE.                                              }

Const
 oNum=1; oStr=2; oNull=3; oCol=4; oAdd=5; oSub=6; oMul=7; oDiv=8; oMod=9;
 oNeg=10; oEq=11; oNe=12; oLt=13; oLe=14; oGt=15; oGe=16; oAnd=17; oOr=18;
 oNot=19; oLike=20; oIsN=21; oFunc=22; oAgg=23;
 KSEG = 1500;

Type
 TAccE = Record
  Cnt : LongInt;
  Sum : Real;
  MnK,MxK : Byte;
  MnN,MxN : Real;
  MnS,MxS : String[16];
 End;
 TAccArr = Array[1..MAXGRP,1..MAXAGG] Of TAccE;
 PAccArr = ^TAccArr;
 TKey = String[16];
 TKeySeg = Array[1..KSEG] Of TKey;
 PKeySeg = ^TKeySeg;

Var
 Toks   : Array[1..MAXTOK] Of TTok;
 NT,TP  : Integer;
 Nd     : Array[1..MAXNODE] Of TNode;
 NN     : Integer;
 CT     : Array[1..2] Of Integer;
 CR     : Array[1..2] Of PRec;
 CA     : Array[1..2] Of String[16];
 NCT    : Integer;
 SelN   : Integer;
 SelE   : Array[1..MAXCC] Of Integer;
 SelNm  : Array[1..MAXCC] Of String[28];
 NAgg   : Integer;
 AggN   : Array[1..MAXAGG] Of Integer;
 AccP   : PAccArr;
 AccCur : Integer;
 KSegs  : Array[0..3] Of PKeySeg;
 GrpS1,GrpS2 : Array[1..MAXGRP] Of LongInt;
 GrpKey : Array[1..MAXGRP] Of String[60];
 NGrp   : Integer;
 P1,P2  : PLongArr;
 PIx    : PLongArr;
 NP     : LongInt;
 WhereN,JoinN,LimN : Integer;
 OrdN   : Array[1..2] Of Integer;
 OrdDesc: Array[1..2] Of Boolean;
 NOrd   : Integer;
 GrpN   : Array[1..2] Of Integer;
 NGrpE  : Integer;
 LimCnt,LimOff : LongInt;
 StarOnly,Distinct,AggMode,SlotMode : Boolean;

{ ---- analyse lexicale ---- }

Function Tokenize(Const S: String): Boolean;
Var I: Integer; C,Q: Char; W: String; Done: Boolean;
Begin
 Tokenize:=False;
 NT:=0;I:=1;
 While I<=Length(S) Do Begin
  C:=S[I];
  If (C=' ') Or (C=#9) Or (C=#13) Or (C=#10) Then Inc(I)
  Else Begin
   If NT>=MAXTOK-1 Then Begin SqlErr:='Statement too long';Exit;End;
   Inc(NT);Toks[NT].S:='';
   If (UpCase(C) In ['A'..'Z','_']) Or (C='`') Then Begin
    Toks[NT].K:=1;
    If C='`' Then Begin
     Inc(I);
     While (I<=Length(S)) And (S[I]<>'`') Do Begin
      Toks[NT].S:=Toks[NT].S+S[I];Inc(I);
     End;
     Inc(I);
    End Else
     While (I<=Length(S)) And (UpCase(S[I]) In ['A'..'Z','_','0'..'9','$'])
      Do Begin Toks[NT].S:=Toks[NT].S+S[I];Inc(I);End;
   End Else If (C>='0') And (C<='9') Then Begin
    Toks[NT].K:=2;
    While (I<=Length(S)) And (S[I] In ['0'..'9','.']) Do Begin
     Toks[NT].S:=Toks[NT].S+S[I];Inc(I);
    End;
   End Else If (C='''') Or (C='"') Then Begin
    Q:=C;Toks[NT].K:=3;Inc(I);Done:=False;
    While (I<=Length(S)) And Not Done Do Begin
     If S[I]=Q Then Begin
      If (I<Length(S)) And (S[I+1]=Q) Then Begin
       Toks[NT].S:=Toks[NT].S+Q;Inc(I,2);
      End Else Begin Done:=True;Inc(I);End;
     End Else Begin Toks[NT].S:=Toks[NT].S+S[I];Inc(I);End;
    End;
   End Else Begin
    Toks[NT].K:=4;Toks[NT].S:=C;Inc(I);
    If I<=Length(S) Then Begin
     W:=C+S[I];
     If (W='<=') Or (W='>=') Or (W='<>') Or (W='!=') Then Begin
      Toks[NT].S:=W;Inc(I);
     End;
    End;
   End;
  End;
 End;
 Inc(NT);Toks[NT].K:=0;Toks[NT].S:='';
 TP:=1;
 Tokenize:=True;
End;

Function IsK(Const K: String): Boolean;
Begin
 IsK:=(Toks[TP].K In [1,4]) And (Upper(Toks[TP].S)=K);
End;

Function IsKAt(N: Integer; Const K: String): Boolean;
Begin
 IsKAt:=(N<=NT) And (Toks[N].K In [1,4]) And (Upper(Toks[N].S)=K);
End;

Function Acc(Const K: String): Boolean;
Begin
 Acc:=IsK(K);
 If IsK(K) Then Inc(TP);
End;

Function Expect(Const K: String): Boolean;
Begin
 Expect:=True;
 If Not Acc(K) Then Begin
  If SqlErr='' Then SqlErr:='Syntax error near '+Toks[TP].S+' (expected '+K+')';
  Expect:=False;
 End;
End;

Function NewNode(Op: Byte): Integer;
Begin
 If NN>=MAXNODE Then Begin
  If SqlErr='' Then SqlErr:='Expression too complex';
  NewNode:=0;Exit;
 End;
 Inc(NN);
 FillChar(Nd[NN],SizeOf(TNode),0);
 Nd[NN].Op:=Op;
 NewNode:=NN;
End;

Function BinNode(Op: Byte; A,B: Integer): Integer;
Var N: Integer;
Begin
 N:=NewNode(Op);
 If N>0 Then Begin Nd[N].A:=A;Nd[N].B:=B;End;
 BinNode:=N;
End;

Function ParseExpr: Integer; Forward;

Function ParsePrim: Integer;
Var N,K: Integer; Nm: String; R: Real; Code: Integer;
Begin
 ParsePrim:=0;
 If SqlErr<>'' Then Exit;
 Case Toks[TP].K Of
  2: Begin
      N:=NewNode(oNum);
      Val(Toks[TP].S,R,Code);
      If N>0 Then Nd[N].N:=R;
      Inc(TP);ParsePrim:=N;
     End;
  3: Begin
      N:=NewNode(oStr);
      If N>0 Then Nd[N].S:=Copy(Toks[TP].S,1,40);
      Inc(TP);ParsePrim:=N;
     End;
  1: Begin
      Nm:=Upper(Toks[TP].S);
      If Nm='NULL' Then Begin Inc(TP);ParsePrim:=NewNode(oNull);Exit;End;
      If IsKAt(TP+1,'(') Then Begin
       Inc(TP,2);
       If (Nm='COUNT') Or (Nm='SUM') Or (Nm='AVG') Or (Nm='MIN') Or (Nm='MAX')
       Then Begin
        N:=NewNode(oAgg);
        If N=0 Then Exit;
        Nd[N].S:=Nm;
        If Acc('*') Then Nd[N].A:=0 Else Nd[N].A:=ParseExpr;
        If NAgg>=MAXAGG Then Begin SqlErr:='Too many aggregates';Exit;End;
        Inc(NAgg);AggN[NAgg]:=N;Nd[N].Fi:=NAgg;
        Expect(')');
        ParsePrim:=N;
       End Else Begin
        N:=NewNode(oFunc);
        If N=0 Then Exit;
        Nd[N].S:=Nm;
        If Not IsK(')') Then Begin
         Nd[N].A:=ParseExpr;
         If Acc(',') Then Nd[N].B:=ParseExpr;
         If Acc(',') Then Nd[N].C:=ParseExpr;
        End;
        Expect(')');
        ParsePrim:=N;
       End;
      End Else Begin
       N:=NewNode(oCol);
       If N=0 Then Exit;
       Nd[N].S:=Toks[TP].S;Inc(TP);
       If IsK('.') Then Begin
        Inc(TP);
        Nd[N].S:=Nd[N].S+'.'+Toks[TP].S;Inc(TP);
       End;
       ParsePrim:=N;
      End;
     End;
  4: If Acc('(') Then Begin
      N:=ParseExpr;Expect(')');ParsePrim:=N;
     End Else If Acc('-') Then Begin
      N:=NewNode(oNeg);
      If N>0 Then Nd[N].A:=ParsePrim;
      ParsePrim:=N;
     End Else SqlErr:='Syntax error near '+Toks[TP].S;
  Else SqlErr:='Unexpected end of statement';
 End;
End;

Function ParseMul: Integer;
Var L,Op: Integer;
Begin
 L:=ParsePrim;
 While (SqlErr='') And (IsK('*') Or IsK('/') Or IsK('%')) Do Begin
  If IsK('*') Then Op:=oMul Else If IsK('/') Then Op:=oDiv Else Op:=oMod;
  Inc(TP);
  L:=BinNode(Op,L,ParsePrim);
 End;
 ParseMul:=L;
End;

Function ParseAdd: Integer;
Var L,Op: Integer;
Begin
 L:=ParseMul;
 While (SqlErr='') And (IsK('+') Or IsK('-')) Do Begin
  If IsK('+') Then Op:=oAdd Else Op:=oSub;
  Inc(TP);
  L:=BinNode(Op,L,ParseMul);
 End;
 ParseAdd:=L;
End;

Function ParseCmp: Integer;
Var L,R,N,Op,Lst: Integer; Neg: Boolean;
Begin
 L:=ParseAdd;
 If SqlErr<>'' Then Begin ParseCmp:=L;Exit;End;
 Op:=0;
 If IsK('=') Then Op:=oEq Else If IsK('<>') Or IsK('!=') Then Op:=oNe
 Else If IsK('<') Then Op:=oLt Else If IsK('<=') Then Op:=oLe
 Else If IsK('>') Then Op:=oGt Else If IsK('>=') Then Op:=oGe;
 If Op>0 Then Begin
  Inc(TP);
  ParseCmp:=BinNode(Op,L,ParseAdd);Exit;
 End;
 Neg:=False;
 If IsK('NOT') And (IsKAt(TP+1,'LIKE') Or IsKAt(TP+1,'IN') Or
    IsKAt(TP+1,'BETWEEN')) Then Begin Neg:=True;Inc(TP);End;
 N:=L;
 If Acc('LIKE') Then N:=BinNode(oLike,L,ParseAdd)
 Else If Acc('IS') Then Begin
  Neg:=Acc('NOT');
  Expect('NULL');
  N:=BinNode(oIsN,L,0);
 End Else If Acc('IN') Then Begin
  Expect('(');
  N:=0;
  Repeat
   R:=BinNode(oEq,L,ParseExpr);
   If N=0 Then N:=R Else N:=BinNode(oOr,N,R);
  Until (SqlErr<>'') Or Not Acc(',');
  Expect(')');
 End Else If Acc('BETWEEN') Then Begin
  R:=BinNode(oGe,L,ParseAdd);
  Expect('AND');
  N:=BinNode(oAnd,R,BinNode(oLe,L,ParseAdd));
 End Else Neg:=False;
 If Neg Then Begin
  If Nd[N].Op=oIsN Then Nd[N].C:=1
  Else Begin R:=NewNode(oNot);If R>0 Then Nd[R].A:=N;N:=R;End;
 End;
 ParseCmp:=N;
End;

Function ParseNot: Integer;
Var N: Integer;
Begin
 If Acc('NOT') Then Begin
  N:=NewNode(oNot);
  If N>0 Then Nd[N].A:=ParseNot;
  ParseNot:=N;
 End Else ParseNot:=ParseCmp;
End;

Function ParseAnd: Integer;
Var L: Integer;
Begin
 L:=ParseNot;
 While (SqlErr='') And Acc('AND') Do L:=BinNode(oAnd,L,ParseNot);
 ParseAnd:=L;
End;

Function ParseExpr: Integer;
Var L: Integer;
Begin
 L:=ParseAnd;
 While (SqlErr='') And Acc('OR') Do L:=BinNode(oOr,L,ParseAnd);
 ParseExpr:=L;
End;

{ ---- resolution des colonnes ---- }

Procedure ResolveCols;
Var I,K,F,P: Integer; Q,Nm: String;
Begin
 For I:=1 To NN Do
  If (Nd[I].Op=oCol) And (Nd[I].Tb=0) Then Begin
   Q:='';Nm:=Upper(Nd[I].S);
   P:=Pos('.',Nm);
   If P>0 Then Begin Q:=Copy(Nm,1,P-1);Nm:=Copy(Nm,P+1,40);End;
   For K:=1 To NCT Do
    If (Nd[I].Tb=0) And ((Q='') Or (Q=Upper(CA[K])) Or
       (Q=Upper(Tb[CT[K]]^.Nm))) Then Begin
     F:=FldIndex(Tb[CT[K]],Nm);
     If F>0 Then Begin Nd[I].Tb:=K;Nd[I].Fi:=F;End;
    End;
   If (Nd[I].Tb=0) And (SqlErr='') Then SqlErr:='Unknown column '+Nd[I].S;
  End;
End;

{ ---- evaluation ---- }

Procedure VNum(R: Real; Var V: TVal);
Begin
 V.K:=1;V.N:=R;V.S:='';
End;

Procedure VStr(Const S: String; Var V: TVal);
Begin
 V.K:=2;V.N:=0;V.S:=Copy(S,1,80);
End;

Procedure VNull(Var V: TVal);
Begin
 V.K:=0;V.N:=0;V.S:='';
End;

Function NumStr(R: Real): String;
Var S: String;
Begin
 If (Abs(R)<1.0E9) And (Abs(R-Round(R))<0.0000001) Then
  NumStr:=IntStr(Round(R))
 Else Begin Str(R:0:2,S);NumStr:=S;End;
End;

Function ToStr(Const V: TVal): String;
Begin
 Case V.K Of
  1: ToStr:=NumStr(V.N);
  2: ToStr:=V.S;
  Else ToStr:='';
 End;
End;

Function ToNum(Const V: TVal): Real;
Var R: Real; C: Integer;
Begin
 If V.K=1 Then ToNum:=V.N
 Else If V.K=2 Then Begin Val(TrimStr(V.S),R,C);If C<>0 Then R:=0;ToNum:=R;End
 Else ToNum:=0;
End;

Function IsNumStr(Const S: String): Boolean;
Var R: Real; C: Integer;
Begin
 Val(TrimStr(S),R,C);
 IsNumStr:=(C=0) And (TrimStr(S)<>'');
End;

{ compare : -2 si NULL }
Function Cmp3(Const A,B: TVal): Integer;
Var X,Y: Real; SA,SB: String;
Begin
 If (A.K=0) Or (B.K=0) Then Begin Cmp3:=-2;Exit;End;
 If (A.K=1) Or (B.K=1) Then Begin
  If ((A.K=1) Or IsNumStr(A.S)) And ((B.K=1) Or IsNumStr(B.S)) Then Begin
   X:=ToNum(A);Y:=ToNum(B);
   If X<Y Then Cmp3:=-1 Else If X>Y Then Cmp3:=1 Else Cmp3:=0;
   Exit;
  End;
 End;
 SA:=Upper(ToStr(A));SB:=Upper(ToStr(B));
 If SA<SB Then Cmp3:=-1 Else If SA>SB Then Cmp3:=1 Else Cmp3:=0;
End;

Function LikeM(Const P,S: String; PI,SI: Integer): Boolean;
Begin
 While PI<=Length(P) Do Begin
  If P[PI]='%' Then Begin
   While (PI<=Length(P)) And (P[PI]='%') Do Inc(PI);
   If PI>Length(P) Then Begin LikeM:=True;Exit;End;
   While SI<=Length(S)+1 Do Begin
    If LikeM(P,S,PI,SI) Then Begin LikeM:=True;Exit;End;
    Inc(SI);
   End;
   LikeM:=False;Exit;
  End;
  If SI>Length(S) Then Begin LikeM:=False;Exit;End;
  If (P[PI]<>'_') And (UpCase(P[PI])<>UpCase(S[SI])) Then Begin
   LikeM:=False;Exit;
  End;
  Inc(PI);Inc(SI);
 End;
 LikeM:=SI>Length(S);
End;

Procedure ColVal(Tk,F: Integer; Var V: TVal);
Var T: Integer; D: LongInt;
Begin
 T:=CT[Tk];
 Case Tb[T]^.F[F].Typ Of
  'C': VStr(GetS(T,CR[Tk],F),V);
  'D': Begin
        D:=GetN(T,CR[Tk],F);
        If D=0 Then VStr('0000-00-00',V) Else VStr(IsoDate(D),V);
       End;
  Else VNum(GetN(T,CR[Tk],F),V);
 End;
End;

Procedure Ev(N: Integer; Var R: TVal);
Var A,B,C: TVal; Op,K: Integer; S: String[16]; Q: String[80]; X: Real;
Begin
 If N=0 Then Begin VNull(R);Exit;End;
 Op:=Nd[N].Op;
 Case Op Of
  oNum: VNum(Nd[N].N,R);
  oStr: VStr(Nd[N].S,R);
  oNull: VNull(R);
  oCol: ColVal(Nd[N].Tb,Nd[N].Fi,R);
  oAdd,oSub,oMul,oDiv,oMod: Begin
    Ev(Nd[N].A,A);Ev(Nd[N].B,B);
    If (A.K=0) Or (B.K=0) Then Begin VNull(R);Exit;End;
    X:=ToNum(B);
    Case Op Of
     oAdd: VNum(ToNum(A)+X,R);
     oSub: VNum(ToNum(A)-X,R);
     oMul: VNum(ToNum(A)*X,R);
     oDiv: If X=0 Then VNull(R) Else VNum(ToNum(A)/X,R);
     Else If Trunc(X)=0 Then VNull(R)
      Else VNum(Trunc(ToNum(A)) Mod Trunc(X),R);
    End;
   End;
  oNeg: Begin Ev(Nd[N].A,A);If A.K=0 Then R:=A Else VNum(-ToNum(A),R);End;
  oEq,oNe,oLt,oLe,oGt,oGe: Begin
    Ev(Nd[N].A,A);Ev(Nd[N].B,B);
    K:=Cmp3(A,B);
    If K=-2 Then VNull(R)
    Else Case Op Of
     oEq: VNum(Ord(K=0),R);
     oNe: VNum(Ord(K<>0),R);
     oLt: VNum(Ord(K<0),R);
     oLe: VNum(Ord(K<=0),R);
     oGt: VNum(Ord(K>0),R);
     Else VNum(Ord(K>=0),R);
    End;
   End;
  oAnd: Begin
    Ev(Nd[N].A,A);
    If (A.K<>0) And (ToNum(A)=0) Then Begin VNum(0,R);Exit;End;
    Ev(Nd[N].B,B);
    If (B.K<>0) And (ToNum(B)=0) Then VNum(0,R)
    Else If (A.K=0) Or (B.K=0) Then VNull(R) Else VNum(1,R);
   End;
  oOr: Begin
    Ev(Nd[N].A,A);
    If (A.K<>0) And (ToNum(A)<>0) Then Begin VNum(1,R);Exit;End;
    Ev(Nd[N].B,B);
    If (B.K<>0) And (ToNum(B)<>0) Then VNum(1,R)
    Else If (A.K=0) Or (B.K=0) Then VNull(R) Else VNum(0,R);
   End;
  oNot: Begin
    Ev(Nd[N].A,A);
    If A.K=0 Then R:=A Else VNum(Ord(ToNum(A)=0),R);
   End;
  oLike: Begin
    Ev(Nd[N].A,A);Ev(Nd[N].B,B);
    If (A.K=0) Or (B.K=0) Then VNull(R)
    Else VNum(Ord(LikeM(ToStr(B),ToStr(A),1,1)),R);
   End;
  oIsN: Begin
    Ev(Nd[N].A,A);
    If Nd[N].C=1 Then VNum(Ord(A.K<>0),R) Else VNum(Ord(A.K=0),R);
   End;
  oAgg: Begin
    K:=Nd[N].Fi;
    With AccP^[AccCur,K] Do Begin
     If Nd[N].S='COUNT' Then VNum(Cnt,R)
     Else If Cnt=0 Then VNull(R)
     Else If Nd[N].S='SUM' Then VNum(Sum,R)
     Else If Nd[N].S='AVG' Then VNum(Sum/Cnt,R)
     Else If Nd[N].S='MIN' Then Begin
      If MnK=1 Then VNum(MnN,R) Else VStr(MnS,R);
     End Else Begin
      If MxK=1 Then VNum(MxN,R) Else VStr(MxS,R);
     End;
    End;
   End;
  oFunc: Begin
    S:=Nd[N].S;
    Ev(Nd[N].A,A);Ev(Nd[N].B,B);Ev(Nd[N].C,C);
    Q:=ToStr(A);
    If (S='CURDATE') Or (S='TODAY') Or (S='CURRENT_DATE') Then
     VStr(IsoDate(TodayDate),R)
    Else If S='NOW' Then VStr(IsoDate(TodayDate)+' '+NowTime,R)
    Else If (S='COALESCE') Or (S='IFNULL') Then Begin
     If A.K<>0 Then R:=A Else R:=B;
    End Else If A.K=0 Then VNull(R)
    Else If S='UPPER' Then VStr(Upper(Q),R)
    Else If S='LOWER' Then VStr(Lower(Q),R)
    Else If S='LENGTH' Then VNum(Length(Q),R)
    Else If S='TRIM' Then VStr(TrimStr(Q),R)
    Else If S='ABS' Then VNum(Abs(ToNum(A)),R)
    Else If S='ROUND' Then VNum(Round(ToNum(A)),R)
    Else If S='LEFT' Then VStr(Copy(Q,1,Trunc(ToNum(B))),R)
    Else If S='RIGHT' Then Begin
     K:=Trunc(ToNum(B));
     If K>Length(Q) Then K:=Length(Q);
     VStr(Copy(Q,Length(Q)-K+1,K),R);
    End
    Else If (S='SUBSTR') Or (S='SUBSTRING') Then Begin
     If C.K=0 Then K:=255 Else K:=Trunc(ToNum(C));
     VStr(Copy(Q,Trunc(ToNum(B)),K),R);
    End
    Else If S='CONCAT' Then VStr(Q+ToStr(B)+ToStr(C),R)
    Else If S='YEAR' Then VNum(ValInt(Copy(Q,1,4),0),R)
    Else If S='MONTH' Then VNum(ValInt(Copy(Q,6,2),0),R)
    Else If S='DAY' Then VNum(ValInt(Copy(Q,9,2),0),R)
    Else If S='DATEDIFF' Then Begin
     If B.K=0 Then VNull(R) Else
      VNum(DayNum(ValInt(Copy(Q,1,4),0)*10000+ValInt(Copy(Q,6,2),0)*100
       +ValInt(Copy(Q,9,2),0))-DayNum(ValInt(Copy(ToStr(B),1,4),0)*10000+
       ValInt(Copy(ToStr(B),6,2),0)*100+ValInt(Copy(ToStr(B),9,2),0)),R);
    End
    Else VNull(R);
   End;
  Else VNull(R);
 End;
End;

Function Truth(N: Integer): Boolean;
Var V: TVal;
Begin
 If N=0 Then Begin Truth:=True;Exit;End;
 Ev(N,V);
 Truth:=(V.K<>0) And (ToNum(V)<>0);
End;

{ ---- cles de tri ---- }

Procedure KeyPut(I: Integer; Const K: TKey);
Var Sg: Integer;
Begin
 Sg:=(I-1) Div KSEG;
 If Sg>3 Then Exit;
 If KSegs[Sg]=Nil Then GetMem(KSegs[Sg],SizeOf(TKeySeg));
 KSegs[Sg]^[(I-1) Mod KSEG+1]:=K;
End;

Function KeyGet(I: Integer): TKey;
Var Sg: Integer;
Begin
 Sg:=(I-1) Div KSEG;
 If (Sg>3) Or (KSegs[Sg]=Nil) Then KeyGet:='' Else
  KeyGet:=KSegs[Sg]^[(I-1) Mod KSEG+1];
End;

Procedure KeysFree;
Var I: Integer;
Begin
 For I:=0 To 3 Do
  If KSegs[I]<>Nil Then Begin FreeMem(KSegs[I],SizeOf(TKeySeg));KSegs[I]:=Nil;
    End;
End;

Function MakeKey: TKey;
Var T,W,I: Integer; V: TVal; S: String; R: Real; K: String;
Begin
 K:='';
 For T:=1 To NOrd Do Begin
  If NOrd=1 Then W:=16 Else If T=1 Then W:=10 Else W:=6;
  Ev(OrdN[T],V);
  If V.K=1 Then Begin
   R:=V.N+1000000000.0;
   If R<0 Then R:=0;
   Str(R:W:0,S);
   For I:=1 To Length(S) Do If S[I]=' ' Then S[I]:='0';
  End Else S:=Pad(Upper(ToStr(V)),W);
  If Length(S)>W Then S:=Copy(S,Length(S)-W+1,W);
  If OrdDesc[T] Then
   For I:=1 To Length(S) Do S[I]:=Chr(255-Ord(S[I]));
  K:=K+S;
 End;
 MakeKey:=Copy(K,1,16);
End;

Procedure SortIx(N: Integer);
Var Gap,I,J,X: Integer; Ok: Boolean; Ka,Kb: TKey;
Begin
 Gap:=N Div 2;
 While Gap>0 Do Begin
  For I:=Gap+1 To N Do Begin
   X:=PIx^[I];J:=I;
   Ok:=True;
   While Ok And (J>Gap) Do Begin
    Ka:=KeyGet(PIx^[J-Gap]);Kb:=KeyGet(X);
    If (Ka>Kb) Or ((Ka=Kb) And (PIx^[J-Gap]>X)) Then Begin
     PIx^[J]:=PIx^[J-Gap];Dec(J,Gap);
    End Else Ok:=False;
   End;
   PIx^[J]:=X;
  End;
  Gap:=Gap Div 2;
 End;
End;

{ ---- accumulation ---- }

Procedure AccAdd(G: Integer);
Var J: Integer; V: TVal; N: Integer;
Begin
 For J:=1 To NAgg Do Begin
  N:=AggN[J];
  With AccP^[G,J] Do Begin
   If Nd[N].A=0 Then Inc(Cnt)
   Else Begin
    Ev(Nd[N].A,V);
    If V.K<>0 Then Begin
     Inc(Cnt);
     Sum:=Sum+ToNum(V);
     If V.K=1 Then Begin
      If (MnK=0) Or (V.N<MnN) Then Begin MnK:=1;MnN:=V.N;End;
      If (MxK=0) Or (V.N>MxN) Then Begin MxK:=1;MxN:=V.N;End;
     End Else Begin
      If (MnK=0) Or (Copy(V.S,1,16)<MnS) Then Begin MnK:=2;
        MnS:=Copy(V.S,1,16);End;
      If (MxK=0) Or (Copy(V.S,1,16)>MxS) Then Begin MxK:=2;
        MxS:=Copy(V.S,1,16);End;
     End;
    End;
   End;
  End;
 End;
End;

Procedure Emit(S1,S2: LongInt);
Var K,G,I: Integer; Key: String; EV_: TVal;
Begin
 If AggMode Then Begin
  Key:='';
  For I:=1 To NGrpE Do Begin Ev(GrpN[I],EV_);Key:=Key+ToStr(EV_)+#1;End;
  G:=0;
  For K:=1 To NGrp Do If GrpKey[K]=Key Then G:=K;
  If G=0 Then Begin
   If NGrp>=MAXGRP Then Begin SqlMsg:='Groups truncated';Exit;End;
   Inc(NGrp);G:=NGrp;
   GrpKey[G]:=Key;GrpS1[G]:=S1;GrpS2[G]:=S2;
   FillChar(AccP^[G],SizeOf(AccP^[G]),0);
  End;
  AccAdd(G);
 End Else Begin
  If NP>=MAXIDX Then Exit;
  Inc(NP);
  P1^[NP]:=S1;P2^[NP]:=S2;
  If NOrd>0 Then KeyPut(NP,MakeKey);
 End;
End;

{ ---- balayage des lignes ---- }

Procedure ScanRows;
Var S1,S2,Sl: LongInt; K,IdSide,Oth: Integer; V: LongInt; Fast: Boolean;
    L,R: Integer; EV_: TVal;
Begin
 If NCT=0 Then Begin Emit(-1,-1);Exit;End;
 If NCT=1 Then Begin
  For S1:=0 To Tb[CT[1]]^.Slots-1 Do
   If RowGet(CT[1],S1,CR[1]) Then
    If Truth(WhereN) Then Emit(S1,-1);
  Exit;
 End;
 { jointure : acces direct par ID si possible }
 Fast:=False;IdSide:=0;L:=0;R:=0;
 If (JoinN>0) And (Nd[JoinN].Op=oEq) Then Begin
  L:=Nd[JoinN].A;R:=Nd[JoinN].B;
  If (Nd[L].Op=oCol) And (Nd[R].Op=oCol) And (Nd[L].Tb<>Nd[R].Tb) Then Begin
   If Nd[L].Fi=1 Then Begin IdSide:=Nd[L].Tb;Oth:=R;Fast:=True;End
   Else If Nd[R].Fi=1 Then Begin IdSide:=Nd[R].Tb;Oth:=L;Fast:=True;End;
  End;
 End;
 If Fast Then Begin
  K:=3-IdSide;
  For S1:=0 To Tb[CT[K]]^.Slots-1 Do
   If RowGet(CT[K],S1,CR[K]) Then Begin
    Ev(Oth,EV_);
    V:=Trunc(ToNum(EV_));
    Sl:=RowFind(CT[IdSide],V);
    If (Sl>=0) And RowGet(CT[IdSide],Sl,CR[IdSide]) Then
     If Truth(WhereN) Then Begin
      If K=1 Then Emit(S1,Sl) Else Emit(Sl,S1);
     End;
   End;
  Exit;
 End;
 For S1:=0 To Tb[CT[1]]^.Slots-1 Do
  If RowGet(CT[1],S1,CR[1]) Then
   For S2:=0 To Tb[CT[2]]^.Slots-1 Do
    If RowGet(CT[2],S2,CR[2]) Then
     If Truth(JoinN) And Truth(WhereN) Then Emit(S1,S2);
End;

Procedure LoadCtx(S1,S2: LongInt);
Begin
 If (NCT>=1) And (S1>=0) Then If RowGet(CT[1],S1,CR[1]) Then ;
 If (NCT>=2) And (S2>=0) Then If RowGet(CT[2],S2,CR[2]) Then ;
End;

{ ---- analyse de l'instruction SELECT ---- }

Function FindTbl(Const Nm: String): Integer;
Var I: Integer;
Begin
 I:=TblIdx(Nm);
 If I=0 Then SqlErr:='Table not found: '+Nm;
 FindTbl:=I;
End;

Function ParseTblRef(K: Integer): Boolean;
Begin
 ParseTblRef:=False;
 If Toks[TP].K<>1 Then Begin SqlErr:='Table name expected';Exit;End;
 CT[K]:=FindTbl(Toks[TP].S);
 If CT[K]=0 Then Exit;
 CA[K]:=Toks[TP].S;
 Inc(TP);
 Acc('AS');
 If (Toks[TP].K=1) And Not (IsK('WHERE') Or IsK('JOIN') Or IsK('INNER') Or
    IsK('LEFT') Or IsK('ORDER') Or IsK('GROUP') Or IsK('LIMIT') Or
    IsK('ON') Or IsK('SET') Or IsK('VALUES')) Then Begin
  CA[K]:=Toks[TP].S;Inc(TP);
 End;
 NCT:=K;
 ParseTblRef:=True;
End;

Function ExprText(N: Integer): String;
Begin
 If N=0 Then ExprText:='?'
 Else Case Nd[N].Op Of
  oCol: ExprText:=Lower(Copy(Nd[N].S,Pos('.',Nd[N].S)+1,28));
  oAgg: If Nd[N].A=0 Then ExprText:=Lower(Nd[N].S)+'(*)'
        Else ExprText:=Lower(Nd[N].S)+'('+ExprText(Nd[N].A)+')';
  oFunc: ExprText:=Lower(Nd[N].S)+'()';
  oStr: ExprText:=Nd[N].S;
  oNum: ExprText:=NumStr(Nd[N].N);
  Else ExprText:='expr';
 End;
End;

Procedure ExpandStar(Q: String);
Var K,F: Integer; N: Integer;
Begin
 For K:=1 To NCT Do
  If (Q='') Or (Q=Upper(CA[K])) Then
   For F:=1 To Tb[CT[K]]^.NF Do
    If SelN<MAXCC Then Begin
     N:=NewNode(oCol);
     If N>0 Then Begin
      Nd[N].Tb:=K;Nd[N].Fi:=F;
      Inc(SelN);SelE[SelN]:=N;SelNm[SelN]:=Lower(Tb[CT[K]]^.F[F].Nm);
     End;
    End;
End;

Function ParseSelect: Boolean;
Var N,I,Save: Integer; Nm: String; StarPos: Array[1..MAXCC] Of String[16];
    NS: Integer; Alias: String; Q: String;
Begin
 ParseSelect:=False;
 SelN:=0;NAgg:=0;NN:=0;NCT:=0;WhereN:=0;JoinN:=0;NOrd:=0;NGrpE:=0;
 LimCnt:=MaxLongInt;LimOff:=0;StarOnly:=False;Distinct:=False;
 NS:=0;
 Acc('SELECT');
 If Acc('DISTINCT') Then Distinct:=True;
 { liste : on memorise les positions, resolution apres FROM }
 Save:=TP;
 N:=0;
 While (Toks[TP].K<>0) And Not IsK('FROM') Do Begin
  If IsK('(') Then Inc(N);
  If IsK(')') Then Dec(N);
  Inc(TP);
 End;
 If Acc('FROM') Then Begin
  If Not ParseTblRef(1) Then Exit;
  If Acc(',') Then Begin
   If Not ParseTblRef(2) Then Exit;
  End Else If IsK('JOIN') Or IsK('INNER') Or IsK('LEFT') Then Begin
   If Not (Acc('JOIN') Or ((Acc('INNER') Or Acc('LEFT')) And Acc('JOIN')))
   Then Begin SqlErr:='JOIN expected';Exit;End;
   If Not ParseTblRef(2) Then Exit;
   If Acc('ON') Then JoinN:=ParseExpr;
  End;
  If Acc('WHERE') Then WhereN:=ParseExpr;
  If IsK('GROUP') Then Begin
   Inc(TP);Expect('BY');
   Repeat
    If NGrpE<2 Then Begin Inc(NGrpE);GrpN[NGrpE]:=ParseExpr;End
    Else ParseExpr;
   Until (SqlErr<>'') Or Not Acc(',');
  End;
  If IsK('ORDER') Then Begin
   Inc(TP);Expect('BY');
   Repeat
    If NOrd<2 Then Begin
     Inc(NOrd);OrdN[NOrd]:=ParseExpr;OrdDesc[NOrd]:=False;
     If Acc('DESC') Then OrdDesc[NOrd]:=True Else Acc('ASC');
    End Else Begin ParseExpr;If Not Acc('DESC') Then Acc('ASC');End;
   Until (SqlErr<>'') Or Not Acc(',');
  End;
  If Acc('LIMIT') Then Begin
   LimCnt:=ValInt(Toks[TP].S,0);Inc(TP);
   If Acc(',') Then Begin LimOff:=LimCnt;LimCnt:=ValInt(Toks[TP].S,0);Inc(TP);
     End
   Else If Acc('OFFSET') Then Begin LimOff:=ValInt(Toks[TP].S,0);Inc(TP);End;
  End;
 End;
 If SqlErr<>'' Then Exit;
 Q:='';
 I:=TP;
 TP:=Save;
 { relecture de la liste }
 If IsK('*') And IsKAt(TP+1,'FROM') Then StarOnly:=True;
 If IsK('*') And (Toks[TP+1].K=0) Then StarOnly:=True;
 While (SqlErr='') And Not IsK('FROM') And (Toks[TP].K<>0) Do Begin
  If IsK('*') Then Begin ExpandStar('');Inc(TP);End
  Else If (Toks[TP].K=1) And IsKAt(TP+1,'.') And IsKAt(TP+2,'*') Then Begin
   ExpandStar(Upper(Toks[TP].S));Inc(TP,3);
  End Else Begin
   N:=ParseExpr;
   If SqlErr='' Then Begin
    If SelN>=MAXCC Then SqlErr:='Too many columns' Else Begin
     Inc(SelN);SelE[SelN]:=N;SelNm[SelN]:=ExprText(N);
     If Acc('AS') Then Begin SelNm[SelN]:=Copy(Toks[TP].S,1,28);Inc(TP);End
     Else If (Toks[TP].K=1) And Not IsK('FROM') Then Begin
      SelNm[SelN]:=Copy(Toks[TP].S,1,28);Inc(TP);
     End;
    End;
   End;
  End;
  If SqlErr='' Then If Not IsK('FROM') And (Toks[TP].K<>0) Then Expect(',');
 End;
 If SqlErr<>'' Then Exit;
 If (NCT>1) Or (NAgg>0) Or (NGrpE>0) Then StarOnly:=False;
 ResolveCols;
 ParseSelect:=SqlErr='';
End;

Procedure CellOut(R,C: Integer; Const V: TVal);
Begin
 If SqlRows<>Nil Then SqlRows^[R][C]:=Copy(ToStr(V),1,28);
End;

Procedure ExecSelect;
Var I,J,G,K,Rw: Integer; S1,S2: LongInt; Lim: LongInt; Tmp: PLongArr;
    Dup: Boolean; A,B: String; EV_: TVal;
Begin
 If Not ParseSelect Then Exit;
 AggMode:=(NAgg>0) Or (NGrpE>0);
 SlotMode:=StarOnly And Not AggMode;
 If SqlRows=Nil Then GetMem(SqlRows,SizeOf(TResArr));
 If AggMode And (AccP=Nil) Then GetMem(AccP,SizeOf(TAccArr));
 NP:=0;NGrp:=0;
 For I:=0 To 3 Do KSegs[I]:=Nil;
 ScanRows;
 SqlNC:=SelN;SqlNR:=0;SqlIsSlots:=SlotMode;SqlTbl:=CT[1];
 For I:=1 To SelN Do SqlHead[I]:=SelNm[I];
 If AggMode Then Begin
  If (NGrp=0) And (NGrpE=0) Then Begin
   NGrp:=1;GrpS1[1]:=-1;GrpS2[1]:=-1;GrpKey[1]:='';
   FillChar(AccP^[1],SizeOf(AccP^[1]),0);
  End;
  NP:=NGrp;
  GetMem(PIx,SizeOf(TLongArr));
  For I:=1 To NP Do Begin
   PIx^[I]:=I;
   If NOrd>0 Then Begin
    AccCur:=I;LoadCtx(GrpS1[I],GrpS2[I]);KeyPut(I,MakeKey);
   End;
  End;
  If NOrd>0 Then SortIx(NP);
  K:=0;
  For I:=1 To NP Do
   If (I>LimOff) And (K<LimCnt) And (K<MAXRES) Then Begin
    G:=PIx^[I];AccCur:=G;
    LoadCtx(GrpS1[G],GrpS2[G]);
    Inc(K);
    For J:=1 To SelN Do Begin Ev(SelE[J],EV_);CellOut(K,J,EV_);End;
   End;
  SqlNR:=K;
  FreeMem(PIx,SizeOf(TLongArr));
 End Else Begin
  GetMem(PIx,SizeOf(TLongArr));
  For I:=1 To NP Do PIx^[I]:=I;
  If NOrd>0 Then SortIx(NP);
  { fenetre LIMIT }
  K:=0;
  If SlotMode Then Begin
   Tmp:=P2;
   For I:=1 To NP Do
    If (I>LimOff) And (K<LimCnt) Then Begin Inc(K);Tmp^[K]:=P1^[PIx^[I]];End;
   Move(Tmp^,P1^,K*SizeOf(LongInt));
   SqlN:=K;SqlNR:=K;
  End Else Begin
   For I:=1 To NP Do
    If (I>LimOff) And (K<LimCnt) And (K<MAXRES) Then Begin
     LoadCtx(P1^[PIx^[I]],P2^[PIx^[I]]);
     Dup:=False;
     If Distinct Then Begin
      A:='';
      For J:=1 To SelN Do Begin Ev(SelE[J],EV_);A:=A+ToStr(EV_)+#1;End;
      For Rw:=1 To K Do Begin
       B:='';
       For J:=1 To SelN Do B:=B+SqlRows^[Rw][J]+#1;
       If A=B Then Dup:=True;
      End;
     End;
     If Not Dup Then Begin
      Inc(K);
      For J:=1 To SelN Do Begin Ev(SelE[J],EV_);CellOut(K,J,EV_);End;
     End;
    End;
   SqlNR:=K;
  End;
  FreeMem(PIx,SizeOf(TLongArr));
 End;
 KeysFree;
 SqlMsg:=IntStr(SqlNR)+' row(s)';
End;

{ ---- INSERT / UPDATE / DELETE ---- }

Procedure AssignVal(T: Integer; B: PRec; F: Integer; Const V: TVal);
Begin
 If V.K=0 Then Begin
  If Tb[T]^.F[F].Typ='C' Then SetS(T,B,F,'') Else SetN(T,B,F,0);
  Exit;
 End;
 Case Tb[T]^.F[F].Typ Of
  'C': SetS(T,B,F,ToStr(V));
  'D': If V.K=1 Then SetN(T,B,F,Round(V.N)) Else SetS(T,B,F,ToStr(V));
  Else SetN(T,B,F,Round(ToNum(V)));
 End;
End;

Procedure ExecInsert;
Var T,F,I,NC: Integer; Cols: Array[1..MAXFLD] Of Integer; V: TVal; Id: LongInt;
    More: Boolean;
Begin
 Acc('INSERT');Acc('INTO');
 NN:=0;NCT:=0;NAgg:=0;
 If Toks[TP].K<>1 Then Begin SqlErr:='Table name expected';Exit;End;
 T:=FindTbl(Toks[TP].S);If T=0 Then Exit;
 Inc(TP);
 NC:=0;
 If Acc('(') Then Begin
  Repeat
   F:=FldIndex(Tb[T],Toks[TP].S);
   If F=0 Then Begin SqlErr:='Unknown column '+Toks[TP].S;Exit;End;
   Inc(NC);Cols[NC]:=F;Inc(TP);
  Until Not Acc(',');
  Expect(')');
 End Else Begin
  For F:=2 To Tb[T]^.NF Do Begin Inc(NC);Cols[NC]:=F;End;
 End;
 Expect('VALUES');
 SqlAff:=0;More:=True;
 While (SqlErr='') And More Do Begin
  Expect('(');
  NewRow(T,RB);
  I:=0;
  Repeat
   NN:=0;
   Ev(ParseExpr,V);
   Inc(I);
   If (SqlErr='') And (I<=NC) Then AssignVal(T,RB,Cols[I],V);
  Until (SqlErr<>'') Or Not Acc(',');
  Expect(')');
  If SqlErr<>'' Then Exit;
  Id:=RowAdd(T,RB);
  If Id=0 Then Begin SqlErr:=DbErr;Exit;End;
  Inc(SqlAff);
  More:=Acc(',');
 End;
 TblFlush(T);
End;

Procedure ExecUpdate;
Var T,I,NS: Integer; S: LongInt; Fs: Array[1..8] Of Integer;
    Ex: Array[1..8] Of Integer; Vs: Array[1..8] Of TVal;
Begin
 Acc('UPDATE');
 NN:=0;NCT:=0;NAgg:=0;WhereN:=0;
 If Not ParseTblRef(1) Then Exit;
 T:=CT[1];
 Expect('SET');
 NS:=0;
 Repeat
  If NS>=8 Then Begin SqlErr:='Too many assignments';Exit;End;
  Inc(NS);
  Fs[NS]:=FldIndex(Tb[T],Toks[TP].S);
  If Fs[NS]=0 Then Begin SqlErr:='Unknown column '+Toks[TP].S;Exit;End;
  If Fs[NS]=1 Then Begin SqlErr:='Cannot modify ID';Exit;End;
  Inc(TP);Expect('=');
  Ex[NS]:=ParseExpr;
 Until (SqlErr<>'') Or Not Acc(',');
 If Acc('WHERE') Then WhereN:=ParseExpr;
 If SqlErr<>'' Then Exit;
 ResolveCols;
 If SqlErr<>'' Then Exit;
 SqlAff:=0;
 For S:=0 To Tb[T]^.Slots-1 Do
  If RowGet(T,S,CR[1]) Then
   If Truth(WhereN) Then Begin
    For I:=1 To NS Do Ev(Ex[I],Vs[I]);
    For I:=1 To NS Do AssignVal(T,CR[1],Fs[I],Vs[I]);
    RowPut(T,S,CR[1]);
    Inc(SqlAff);
   End;
 TblFlush(T);
End;

Procedure ExecDelete;
Var T: Integer; S: LongInt;
Begin
 Acc('DELETE');Acc('FROM');
 NN:=0;NCT:=0;NAgg:=0;WhereN:=0;
 If Not ParseTblRef(1) Then Exit;
 T:=CT[1];
 If Acc('WHERE') Then WhereN:=ParseExpr;
 If SqlErr<>'' Then Exit;
 ResolveCols;
 If SqlErr<>'' Then Exit;
 SqlAff:=0;
 For S:=0 To Tb[T]^.Slots-1 Do
  If RowGet(T,S,CR[1]) Then
   If Truth(WhereN) Then Begin RowDel(T,S);Inc(SqlAff);End;
 TblFlush(T);
End;

{ ---- definition / maintenance ---- }

Procedure EraseFile(Const N: String);
Var F: File;
Begin
 {$I-}
 Assign(F,N);
 Erase(F);
 {$I+}
 If IOResult<>0 Then ;
End;

Procedure TblDrop(Const Nm: String);
Var I,J: Integer; U: String;
Begin
 U:=Lower(Nm);
 I:=1;
 While I<=NTb Do Begin
  If Tb[I]^.Nm=U Then Begin
   {$I-}
   Close(Tb[I]^.Dat);
   {$I+}
   If IOResult<>0 Then ;
   FreeMem(Tb[I]^.Ix,Tb[I]^.IxCap*SizeOf(TIdxE));
   Dispose(Tb[I]);
   For J:=I To NTb-1 Do Tb[J]:=Tb[J+1];
   Dec(NTb);
  End Else Inc(I);
 End;
 EraseFile(TblPath(U,'frm'));
 EraseFile(TblPath(U,'MYD'));
 EraseFile(TblPath(U,'MYI'));
End;

Procedure ExecCreate;
Var Spec,Nm,Ty,TNm: String; Depth,N,Len: Integer; First: Boolean; Ch: Char;
    Skip: Boolean;
Begin
 Acc('CREATE');Expect('TABLE');
 If Acc('IF') Then Begin Expect('NOT');Expect('EXISTS');End;
 TNm:=Toks[TP].S;Inc(TP);
 If FileExists(TblPath(TNm,'frm')) Then Begin SqlErr:='Table exists: '+TNm;
   Exit;End;
 Expect('(');
 Spec:='';First:=True;
 Repeat
  Skip:=IsK('PRIMARY') Or IsK('KEY') Or IsK('UNIQUE') Or IsK('INDEX')
   Or IsK('CONSTRAINT');
  If Not Skip Then Begin
   Nm:=Upper(Toks[TP].S);Inc(TP);
   Ty:=Upper(Toks[TP].S);Inc(TP);
   Len:=0;
   If Acc('(') Then Begin
    Len:=ValInt(Toks[TP].S,1);Inc(TP);
    While Not IsK(')') And (Toks[TP].K<>0) Do Inc(TP);
    Inc(TP);
   End;
   If (Ty='INT') Or (Ty='INTEGER') Or (Ty='MEDIUMINT') Or (Ty='BIGINT')
   Then Ch:='I'
   Else If Ty='SMALLINT' Then Ch:='S'
   Else If (Ty='TINYINT') Or (Ty='BOOL') Or (Ty='BOOLEAN') Then Ch:='B'
   Else If Ty='DATE' Then Ch:='D'
   Else If (Ty='CHAR') Or (Ty='VARCHAR') Then Ch:='C'
   Else If Ty='TEXT' Then Begin Ch:='C';Len:=250;End
   Else Begin SqlErr:='Unsupported type '+Ty;Exit;End;
   If First And ((Ch<>'I') Or (Nm<>'ID')) Then Spec:='ID:I,';
   First:=False;
   Spec:=Spec+Nm+':'+Ch;
   If Ch='C' Then Spec:=Spec+IntStr(Len);
   Spec:=Spec+',';
  End;
  { ignore le reste de la definition jusqu'a la virgule }
  Depth:=0;
  While (Toks[TP].K<>0) And Not ((Depth=0) And (IsK(',') Or IsK(')'))) Do Begin
   If IsK('(') Then Inc(Depth);
   If IsK(')') Then Dec(Depth);
   Inc(TP);
  End;
 Until Not Acc(',');
 Expect(')');
 If SqlErr<>'' Then Exit;
 Delete(Spec,Length(Spec),1);
 If Not TblCreate(TNm,Spec) Then SqlErr:=DbErr;
End;

Procedure ExecDrop;
Begin
 Acc('DROP');Expect('TABLE');
 If Acc('IF') Then Expect('EXISTS');
 If Not FileExists(TblPath(Toks[TP].S,'frm')) Then Begin
  SqlErr:='Table not found: '+Toks[TP].S;Exit;
 End;
 TblDrop(Toks[TP].S);
End;

Procedure ResStart(Const H: String);
Begin
 If SqlRows=Nil Then GetMem(SqlRows,SizeOf(TResArr));
 SqlNR:=0;SqlNC:=1;SqlHead[1]:=H;SqlIsSlots:=False;
End;

Procedure ExecShow;
Var SR: SearchRec; I,J: Integer; N: String;
Begin
 Acc('SHOW');
 ResStart('tables');
 If Not Acc('TABLES') Then Begin SqlErr:='Only SHOW TABLES supported';Exit;End;
 FindFirst(DbDir+DirSep+'*.frm',AnyFile,SR);
 While (DosError=0) And (SqlNR<MAXRES) Do Begin
  N:=SR.Name;
  Inc(SqlNR);
  SqlRows^[SqlNR][1]:=Lower(Copy(N,1,Pos('.',N)-1));
  FindNext(SR);
 End;
 { tri simple }
 For I:=1 To SqlNR-1 Do
  For J:=I+1 To SqlNR Do
   If SqlRows^[J][1]<SqlRows^[I][1] Then Begin
    N:=SqlRows^[I][1];SqlRows^[I][1]:=SqlRows^[J][1];SqlRows^[J][1]:=N;
   End;
End;

Procedure ExecDescribe;
Var T,F: Integer; S: String;
Begin
 If Acc('SHOW') Then Begin Acc('COLUMNS');Expect('FROM');End
 Else Inc(TP);
 T:=FindTbl(Toks[TP].S);If T=0 Then Exit;
 ResStart('field');
 SqlNC:=4;SqlHead[2]:='type';SqlHead[3]:='null';SqlHead[4]:='key';
 For F:=1 To Tb[T]^.NF Do Begin
  Inc(SqlNR);
  SqlRows^[SqlNR][1]:=Lower(Tb[T]^.F[F].Nm);
  Case Tb[T]^.F[F].Typ Of
   'I': S:='int(11)'; 'S': S:='smallint(6)'; 'B': S:='tinyint(4)';
   'D': S:='date';
   Else S:='char('+IntStr(Tb[T]^.F[F].Sz)+')';
  End;
  SqlRows^[SqlNR][2]:=S;SqlRows^[SqlNR][3]:='NO';
  If F=1 Then SqlRows^[SqlNR][4]:='PRI' Else SqlRows^[SqlNR][4]:='';
 End;
End;

Procedure ExecCheck;
Var T: Integer; Live,Del: LongInt; Rep: Boolean;
Begin
 Rep:=IsK('REPAIR') Or IsK('OPTIMIZE');
 Inc(TP);Expect('TABLE');
 T:=FindTbl(Toks[TP].S);If T=0 Then Exit;
 If Rep Then Begin
  {$I-}
  RelinkDeleted(Tb[T]);
  {$I+}
  Tb[T]^.IxDirty:=True;TblFlush(T);
  SqlMsg:='OK (repaired)';
 End Else Begin
  Live:=Tb[T]^.NIdx;Del:=Tb[T]^.Del;
  ScanTable(Tb[T]);
  If (Live=Tb[T]^.NIdx) And (Del=Tb[T]^.Del) Then SqlMsg:='OK'
  Else SqlMsg:='Index rebuilt';
  TblFlush(T);
 End;
End;

{ execute une instruction SQL ; resultat dans Sql* }
Function SqlRun(Const Q: String): Boolean;
Var K: String;
Begin
 SqlErr:='';SqlMsg:='';SqlAff:=0;SqlNR:=0;SqlN:=0;SqlNC:=0;SqlIsSlots:=False;
 DbErr:='';
 If Not Tokenize(Q) Then Begin SqlRun:=False;Exit;End;
 K:=Upper(Toks[1].S);
 If K='SELECT' Then ExecSelect
 Else If K='INSERT' Then ExecInsert
 Else If K='UPDATE' Then ExecUpdate
 Else If K='DELETE' Then ExecDelete
 Else If K='CREATE' Then ExecCreate
 Else If K='DROP' Then ExecDrop
 Else If (K='SHOW') And IsKAt(2,'TABLES') Then ExecShow
 Else If (K='DESCRIBE') Or (K='DESC') Or (K='SHOW') Then ExecDescribe
 Else If (K='CHECK') Or (K='REPAIR') Or (K='OPTIMIZE') Then ExecCheck
 Else If K='' Then SqlMsg:=''
 Else SqlErr:='Unsupported statement: '+K;
 If (SqlErr='') And (K<>'SELECT') And (SqlAff>0) Then
  SqlMsg:=IntStr(SqlAff)+' row(s) affected';
 If (SqlErr='') And (DbErr<>'') And (K<>'SELECT') Then SqlErr:=DbErr;
 SqlRun:=SqlErr='';
End;

Procedure SqlInit;
Begin
 GetMem(P1,SizeOf(TLongArr));
 GetMem(P2,SizeOf(TLongArr));
 GetMem(CR[1],SizeOf(TRec));
 GetMem(CR[2],SizeOf(TRec));
 SqlRows:=Nil;AccP:=Nil;
 FillChar(KSegs,SizeOf(KSegs),0);
End;

{ ====================================================================== }
{                      PRIMITIVES GRAPHIQUES                             }
{ ====================================================================== }

Var
 TX      : PTxtArr;        { zone de texte multi-lignes }
 TXN     : Integer;
 PickIt  : PStrArr;
 PickN   : Integer;
 ToolBarOn,StatusOn : Boolean;
 StatMsg : String[80];
 Dirty   : Boolean;

Procedure DrawAll; Forward;
Procedure Backdrop; Forward;


{ ====================================================================== }
{                          PRESSE-PAPIERS                                }
{ ====================================================================== }
{ Tampon interne (DOS, Linux...) ; sous Windows il est aussi synchronise
  avec le presse-papiers du systeme par les API user32 / kernel32 declarees
  ci-dessous (aucune unite externe). Le texte interne est en jeu OEM.      }

{$IFDEF WINCLIPBOARD}
Function OpenClipboard(hWnd: PtrUInt): LongInt; stdcall;
 external 'user32' name 'OpenClipboard';
Function CloseClipboard: LongInt; stdcall;
 external 'user32' name 'CloseClipboard';
Function EmptyClipboard: LongInt; stdcall;
 external 'user32' name 'EmptyClipboard';
Function GetClipboardData(Fmt: LongWord): PtrUInt; stdcall;
 external 'user32' name 'GetClipboardData';
Function SetClipboardData(Fmt: LongWord; hMem: PtrUInt): PtrUInt; stdcall;
 external 'user32' name 'SetClipboardData';
Function OemToCharBuffA(Src,Dst: Pointer; N: LongWord): LongInt; stdcall;
 external 'user32' name 'OemToCharBuffA';
Function CharToOemBuffA(Src,Dst: Pointer; N: LongWord): LongInt; stdcall;
 external 'user32' name 'CharToOemBuffA';
Function GlobalAlloc(Flg: LongWord; Sz: PtrUInt): PtrUInt; stdcall;
 external 'kernel32' name 'GlobalAlloc';
Function GlobalLock(hMem: PtrUInt): Pointer; stdcall;
 external 'kernel32' name 'GlobalLock';
Function GlobalUnlock(hMem: PtrUInt): LongInt; stdcall;
 external 'kernel32' name 'GlobalUnlock';
Function GlobalSize(hMem: PtrUInt): PtrUInt; stdcall;
 external 'kernel32' name 'GlobalSize';
{$ENDIF}

Var
 ClipP   : PBig;
 ClipLen : Integer;
 NoDbl   : Boolean;

Procedure ClipClear;
Begin
 ClipLen:=0;
End;

Procedure ClipAdd(Const S: String);
Var I: Integer;
Begin
 If ClipLen+Length(S)+2>8000 Then Exit;
 For I:=1 To Length(S) Do Begin ClipP^[ClipLen]:=Ord(S[I]);Inc(ClipLen);End;
 ClipP^[ClipLen]:=13;ClipP^[ClipLen+1]:=10;Inc(ClipLen,2);
End;

{ envoie le tampon au presse-papiers du systeme }
Procedure ClipPush;
{$IFDEF WINCLIPBOARD}
Var H: PtrUInt; P: Pointer;
Begin
 If ClipLen=0 Then Exit;
 If OpenClipboard(0)=0 Then Exit;
 EmptyClipboard;
 H:=GlobalAlloc(2,ClipLen+1);
 If H<>0 Then Begin
  P:=GlobalLock(H);
  If P<>Nil Then Begin
   OemToCharBuffA(ClipP,P,ClipLen);
   PBig(P)^[ClipLen]:=0;
   GlobalUnlock(H);
   If SetClipboardData(1,H)=0 Then ;
  End;
 End;
 CloseClipboard;
End;
{$ELSE}
Begin
End;
{$ENDIF}

{ lit le presse-papiers du systeme dans le tampon (sinon garde l'interne) }
Procedure ClipPull;
{$IFDEF WINCLIPBOARD}
Var H: PtrUInt; P: Pointer; N,L: Integer;
Begin
 If OpenClipboard(0)=0 Then Exit;
 H:=GetClipboardData(1);
 If H<>0 Then Begin
  P:=GlobalLock(H);
  If P<>Nil Then Begin
   N:=Integer(GlobalSize(H));
   If N>8000 Then N:=8000;
   L:=0;
   While (L<N) And (PBig(P)^[L]<>0) Do Inc(L);
   CharToOemBuffA(P,ClipP,L);
   ClipLen:=L;
   GlobalUnlock(H);
  End;
 End;
 CloseClipboard;
End;
{$ELSE}
Begin
End;
{$ENDIF}

{ nombre de lignes du tampon }
Function ClipLines: Integer;
Var I,N: Integer;
Begin
 N:=0;
 If ClipLen>0 Then Begin
  N:=1;
  For I:=0 To ClipLen-1 Do
   If (ClipP^[I]=10) And (I<ClipLen-1) Then Inc(N);
 End;
 ClipLines:=N;
End;

Function ClipLine(N: Integer): String;
Var I,K: Integer; S: String;
Begin
 K:=1;S:='';
 For I:=0 To ClipLen-1 Do Begin
  If ClipP^[I]=10 Then Begin
   If K=N Then Begin ClipLine:=S;Exit;End;
   Inc(K);S:='';
  End Else If (ClipP^[I]<>13) And (Length(S)<78) Then S:=S+Chr(ClipP^[I]);
 End;
 If K=N Then ClipLine:=S Else ClipLine:='';
End;

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

Procedure Rc(X1,Y1,X2,Y2,C: Integer);
Begin
 SetColor(C);
 SetLineStyle(SolidLn,0,1);
 Rectangle(X1,Y1,X2,Y2);
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

Procedure MxFocusRect(X1,Y1,X2,Y2: Integer);
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

Procedure Tx_(X,Y: Integer; Const S: String; C: Integer);
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

{ texte tronque a W pixels }
Procedure TxC(X,Y,W: Integer; Const S: String; C: Integer);
Begin
 If W<8 Then Exit;
 Tx_(X,Y,Copy(S,1,W Div 8),C);
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
{ OS/2-0 : FENETRES DE PRESENTATION MANAGER DE MAXIMILIEN CRM         }
{ ================================================================== }
{ La version DOS dessinait ses boites (cadre, champs, boutons, listes, }
{ menus contextuels) dans l'ecran graphique. Ici :                    }
{  - messages, questions, saisies : WinMessageBox et boite de saisie ;}
{  - listes a choix : liste de PM (WC_LISTBOX) et barre de defilement;}
{  - rapports : fenetre de texte avec barres de defilement de PM ;    }
{  - fiches (formulaires) : etiquettes, champs de saisie, cases a     }
{    cocher et boutons de liste de PM, barre de defilement si la      }
{    fiche a plus de champs que la boite ne peut en montrer ;         }
{  - menus contextuels : menu surgissant de PM (WinPopupMenu), avec   }
{    ses sous-menus ;                                                 }
{  - vues dessinees (tables, editeur de texte, chronometre, A propos) :}
{    fenetre de PM a part, montrant la partie de l'image dessinee par }
{    la version DOS, ses boutons etant de vrais boutons de PM.        }

Var
 MxClsDone : Boolean;
 { liste a choix }
 MlFr, MlCl, MlLb, MlSb, MlSel, MlRows, MlN : LongInt;
 { visionneuse de texte }
 VtFr, VtCl, VtVsb, VtHsb, VtTop, VtLeft, VtRows, VtCols, VtMax : LongInt;
 { fiche }
 FeFr, FeCl, FeSb, FeTopG, FeNF, FeRows : LongInt;
 FeLb, FeEf, FeBt : Array[1..MXF_ROWS] Of LongInt;
 FeOk, FeCan : LongInt;
 { menu contextuel }
 MxPopIds : Array[1..160] Of Integer;
 MxPopN : Integer;

{ --- liste a choix --- }

Procedure MlSync;
Var T, M : LongInt;
Begin
 M := MlN - MlRows; If M < 0 Then M := 0;
 T := WinSendMsg(MlLb, LM_QUERYTOPINDEX, 0, 0);
 If T < 0 Then T := 0;
 Dummy := WinSendMsg(MlSb, SBM_SETTHUMBSIZE, MlRows Or (MlN Shl 16), 0);
 Dummy := WinSendMsg(MlSb, SBM_SETSCROLLBAR, T, M Shl 16);
 Dummy := WinEnableWindow(MlSb, Ord(M > 0));
End;

Function MlProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, T, C : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 MlProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, 0);
    Dummy := WinQueryWindowRect(H, LongInt(@Rc));
    Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
    Dummy := WinEndPaint(Hps);
   End;
  WM_CONTROL :
   If PmLo(Mp1) = ID_MLIST Then
   Begin
    If PmHi(Mp1) = LN_ENTER Then
    Begin
     MlSel := WinSendMsg(MlLb, LM_QUERYSELECTION, -1, 0) + 1;
     If MlSel > 0 Then PmDone(1);
    End
    Else MlSync;
   End;
  WM_VSCROLL :
   Begin
    T := WinSendMsg(MlLb, LM_QUERYTOPINDEX, 0, 0);
    C := PmHi(Mp2);
    Case C Of
     SB_LINEUP : Dec(T);
     SB_LINEDOWN : Inc(T);
     SB_PAGEUP : T := T - (MlRows - 1);
     SB_PAGEDOWN : T := T + (MlRows - 1);
     SB_SLIDERTRACK, SB_SLIDERPOSITION : T := PmS16(Mp2);
    End;
    If T > MlN - MlRows Then T := MlN - MlRows;
    If T < 0 Then T := 0;
    Dummy := WinSendMsg(MlLb, LM_SETTOPINDEX, T, 0);
    MlSync;
   End;
  WM_COMMAND :
   If PmLo(Mp1) = ID_POK Then
   Begin
    MlSel := WinSendMsg(MlLb, LM_QUERYSELECTION, -1, 0) + 1;
    If MlSel > 0 Then PmDone(1);
   End
   Else If PmLo(Mp1) = ID_PCANCEL Then PmDone(2);
  WM_CHAR : MlProc := PmDlgKey(H, Msg, Mp1, Mp2);
  WM_CLOSE : PmDone(2);
 Else
  MlProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

{ --- visionneuse de texte (rapports) --- }

Procedure VtBars;
Var MT, ML : LongInt;
Begin
 MT := TXN - VtRows; If MT < 0 Then MT := 0;
 ML := VtMax - VtCols; If ML < 0 Then ML := 0;
 If VtTop > MT Then VtTop := MT;
 If VtTop < 0 Then VtTop := 0;
 If VtLeft > ML Then VtLeft := ML;
 If VtLeft < 0 Then VtLeft := 0;
 Dummy := WinSendMsg(VtVsb, SBM_SETTHUMBSIZE, VtRows Or (TXN Shl 16), 0);
 Dummy := WinSendMsg(VtVsb, SBM_SETSCROLLBAR, VtTop, MT Shl 16);
 Dummy := WinSendMsg(VtHsb, SBM_SETTHUMBSIZE, VtCols Or (VtMax Shl 16), 0);
 Dummy := WinSendMsg(VtHsb, SBM_SETSCROLLBAR, VtLeft, ML Shl 16);
 Dummy := WinEnableWindow(VtVsb, Ord(MT > 0));
 Dummy := WinEnableWindow(VtHsb, Ord(ML > 0));
End;

Procedure VtScroll(DTop, DLeft : LongInt);
Begin
 VtTop := VtTop + DTop; VtLeft := VtLeft + DLeft;
 VtBars;
 Dummy := WinInvalidateRect(VtCl, 0, 0);
End;

Function VtProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, I, W, Hh, Fl, Vk, C : LongInt; Rc, Rt : Array[0..3] Of LongInt; S : String;
Begin
 VtProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, 0);
    Dummy := WinQueryWindowRect(H, LongInt(@Rc));
    W := Rc[2]; Hh := Rc[3];
    Rt[0] := 0; Rt[1] := 0; Rt[2] := W; Rt[3] := 42;
    Dummy := WinFillRect(Hps, LongInt(@Rt), CLR_PALEGRAY);
    Rt[0] := 0; Rt[1] := 42; Rt[2] := 8; Rt[3] := Hh;
    Dummy := WinFillRect(Hps, LongInt(@Rt), CLR_PALEGRAY);
    Rt[0] := W - 8; Rt[1] := 42; Rt[2] := W; Rt[3] := Hh;
    Dummy := WinFillRect(Hps, LongInt(@Rt), CLR_PALEGRAY);
    Rt[0] := 0; Rt[1] := Hh - 8; Rt[2] := W; Rt[3] := Hh;
    Dummy := WinFillRect(Hps, LongInt(@Rt), CLR_PALEGRAY);
    Rt[0] := W - 8 - 16; Rt[1] := 42; Rt[2] := W - 8; Rt[3] := 42 + 16;
    Dummy := WinFillRect(Hps, LongInt(@Rt), CLR_PALEGRAY);
    Rt[0] := 8; Rt[1] := 42 + 16; Rt[2] := W - 8 - 16; Rt[3] := Hh - 8;
    Dummy := WinFillRect(Hps, LongInt(@Rt), CLR_PMWHITE);
    For I := 0 To VtRows - 1 Do
     If VtTop + I < TXN Then
     Begin
      S := Copy(TX^[VtTop + I + 1], VtLeft + 1, VtCols);
      PmText(Hps, Hh, 12, 10 + I * PmChH, S, CLR_PMBLACK, CLR_PMWHITE);
     End;
    S := IntStr(VtTop + 1) + '/' + IntStr(TXN);
    PmText(Hps, Hh, 12, Hh - 34, S, CLR_PMBLACK, CLR_PALEGRAY);
    Dummy := WinEndPaint(Hps);
   End;
  WM_VSCROLL :
   Begin
    C := PmHi(Mp2);
    Case C Of
     SB_LINEUP : VtScroll(-1, 0);
     SB_LINEDOWN : VtScroll(1, 0);
     SB_PAGEUP : VtScroll(-(VtRows - 1), 0);
     SB_PAGEDOWN : VtScroll(VtRows - 1, 0);
     SB_SLIDERTRACK, SB_SLIDERPOSITION : VtScroll(PmS16(Mp2) - VtTop, 0);
    End;
   End;
  WM_HSCROLL :
   Begin
    C := PmHi(Mp2);
    Case C Of
     SB_LINEUP : VtScroll(0, -1);
     SB_LINEDOWN : VtScroll(0, 1);
     SB_PAGEUP : VtScroll(0, -(VtCols - 4));
     SB_PAGEDOWN : VtScroll(0, VtCols - 4);
     SB_SLIDERTRACK, SB_SLIDERPOSITION : VtScroll(0, PmS16(Mp2) - VtLeft);
    End;
   End;
  WM_COMMAND :
   Case PmLo(Mp1) Of
    ID_PCANCEL : PmDone(1);
    ID_PSAVE : PmDone(3);
   End;
  WM_CHAR :
   Begin
    Fl := PmLo(Mp1); Vk := PmHi(Mp2);
    VtProc := 1;
    If (Fl And KC_KEYUP) <> 0 Then Exit;
    If (Fl And KC_VIRTUALKEY) <> 0 Then
     Case Vk Of
      VK_UP : VtScroll(-1, 0);
      VK_DOWN : VtScroll(1, 0);
      VK_PAGEUP : VtScroll(-(VtRows - 1), 0);
      VK_PAGEDOWN : VtScroll(VtRows - 1, 0);
      VK_LEFT : VtScroll(0, -1);
      VK_RIGHT : VtScroll(0, 1);
      VK_HOME : VtScroll(-VtTop, -VtLeft);
      VK_END : VtScroll(TXN, 0);
      VK_ENTER, VK_NEWLINE, VK_ESC : PmDone(1);
     Else
      VtProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
     End
    Else If (Fl And KC_CHAR) <> 0 Then
    Begin
     C := PmLo(Mp2);
     If (C = Ord('p')) Or (C = Ord('P')) Or (C = Ord('i')) Or (C = Ord('I')) Then PmDone(3)
     Else VtProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    End
    Else VtProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_CLOSE : PmDone(1);
 Else
  VtProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

{ --- fiche --- }

Procedure FeBars;
Var M : LongInt;
Begin
 If FeSb = 0 Then Exit;
 M := FeNF - FeRows; If M < 0 Then M := 0;
 Dummy := WinSendMsg(FeSb, SBM_SETTHUMBSIZE, FeRows Or (FeNF Shl 16), 0);
 Dummy := WinSendMsg(FeSb, SBM_SETSCROLLBAR, FeTopG - 1, M Shl 16);
End;

Function FeProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, T, C, Fl, Vk, Id : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 FeProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, 0);
    Dummy := WinQueryWindowRect(H, LongInt(@Rc));
    Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
    Dummy := WinEndPaint(Hps);
   End;
  WM_COMMAND :
   Begin
    Id := PmLo(Mp1);
    If Id = ID_POK Then PmDone(1)
    Else If Id = ID_PCANCEL Then PmDone(2)
    Else If (Id > 240) And (Id <= 240 + MXF_ROWS) Then PmDone(10 + Id - 240);
   End;
  WM_VSCROLL :
   Begin
    T := FeTopG;
    C := PmHi(Mp2);
    Case C Of
     SB_LINEUP : Dec(T);
     SB_LINEDOWN : Inc(T);
     SB_PAGEUP : T := T - FeRows;
     SB_PAGEDOWN : T := T + FeRows;
     SB_SLIDERTRACK, SB_SLIDERPOSITION : T := PmS16(Mp2) + 1;
    End;
    If T > FeNF - FeRows + 1 Then T := FeNF - FeRows + 1;
    If T < 1 Then T := 1;
    If T <> FeTopG Then PmDone(1000 + T);
   End;
  WM_CHAR :
   Begin
    Fl := PmLo(Mp1); Vk := PmHi(Mp2);
    FeProc := 1;
    If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_F2) Then PmDone(1)
    Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_F4) Then
    Begin
     { liste du champ qui a la saisie }
     C := WinQueryFocus(HWND_DESKTOP);
     For T := 1 To FeRows Do
      If ((C = FeEf[T]) Or (C = FeBt[T])) And (FeBt[T] <> 0) Then PmDone(10 + T);
    End
    Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And
            ((Vk = VK_TAB) Or (Vk = VK_BACKTAB) Or (Vk = VK_DOWN) Or (Vk = VK_UP)) Then
    Begin
     { champ suivant ou precedent (la fiche defile au besoin) }
     C := WinQueryFocus(HWND_DESKTOP);
     Id := 0;
     For T := 1 To FeRows Do If (C = FeEf[T]) Or (C = FeBt[T]) Then Id := T;
     If (Vk = VK_TAB) Or (Vk = VK_DOWN) Then
     Begin
      If C = FeOk Then Dummy := WinSetFocus(HWND_DESKTOP, FeCan)
      Else If C = FeCan Then
      Begin
       If FeTopG > 1 Then PmDone(6000 + 1)
       Else If FeEf[1] <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, FeEf[1]);
      End
      Else If (Id > 0) And (Id < FeRows) And (FeEf[Id + 1] <> 0) Then
       Dummy := WinSetFocus(HWND_DESKTOP, FeEf[Id + 1])
      Else If (Id = FeRows) And (FeTopG + FeRows - 1 < FeNF) Then PmDone(5000 + 1)
      Else Dummy := WinSetFocus(HWND_DESKTOP, FeOk);
     End
     Else
     Begin
      If C = FeCan Then Dummy := WinSetFocus(HWND_DESKTOP, FeOk)
      Else If (Id > 1) And (FeEf[Id - 1] <> 0) Then Dummy := WinSetFocus(HWND_DESKTOP, FeEf[Id - 1])
      Else If (Id = 1) And (FeTopG > 1) Then PmDone(6000 + 1)
      Else If C = FeOk Then
      Begin
       T := FeRows;
       While (T > 1) And (FeEf[T] = 0) Do Dec(T);
       If FeEf[T] <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, FeEf[T]);
      End;
     End;
    End
    Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And
            ((Vk = VK_PAGEDOWN) Or (Vk = VK_PAGEUP)) And (FeSb <> 0) Then
    Begin
     If Vk = VK_PAGEDOWN Then T := FeTopG + FeRows Else T := FeTopG - FeRows;
     If T > FeNF - FeRows + 1 Then T := FeNF - FeRows + 1;
     If T < 1 Then T := 1;
     If T <> FeTopG Then PmDone(1000 + T);
    End
    Else FeProc := PmDlgKey(H, Msg, Mp1, Mp2);
   End;
  WM_CLOSE : PmDone(2);
 Else
  FeProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

Procedure MxRegister;
Begin
 PmRegister;
 If MxClsDone Then Exit;
 MxClsDone := True;
 Dummy := WinRegisterClass(OsHab, OsZ('MXLIST'), LongInt(@MlProc), 0, 0);
 Dummy := WinRegisterClass(OsHab, OsZ('MXVIEW'), LongInt(@VtProc), 0, 0);
 Dummy := WinRegisterClass(OsHab, OsZ('MXFORM'), LongInt(@FeProc), 0, 0);
End;

{ ouvre la vue : rectangle X1, Y1, X2, Y2 de l'image dans une fenetre de PM ;
  la fenetre principale garde l'image d'avant la vue }

Procedure Btn(X1,Y1,X2,Y2: Integer; Const L: String; Dflt: Boolean);
Var W: Integer;
Begin
 Raised(X1,Y1,X2,Y2);
 W:=TextW(L);
 UTx(X1+(X2-X1-W) Div 2,Y1+(Y2-Y1-8) Div 2,L,cBlk);
 If Dflt Then Rc(X1-1,Y1-1,X2+1,Y2+1,cBlk);
 { vue dessinee a part : vrai bouton de PM }
 If CatCl<>0 Then MxCatBtn(X1,Y1,X2,Y2,L,Dflt);
End;

{ ---- evenements ---- }

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
 If ((MB And 2)<>0) And ((LastB And 2)=0) Then E.Kind:=5
 Else If ((MB And 1)<>0) And ((LastB And 1)=0) Then E.Kind:=2
 Else If ((MB And 1)=0) And ((LastB And 1)<>0) Then E.Kind:=3
 Else If (MX<>PrevMX) Or (MY<>PrevMY) Then E.Kind:=4
 Else Delay(4);
End;

Function IsDouble(X,Y: LongInt): Boolean;
Var Tk: LongInt;
Begin
 If NoDbl Then Begin IsDouble:=False;Exit;End;
 Tk:=Tick;
 IsDouble:=(Abs(Tk-LastClickT)<45) And (Abs(X-LastClickX)<5)
     And (Abs(Y-LastClickY)<5);
 LastClickT:=Tk;LastClickX:=X;LastClickY:=Y;
End;

{ ====================================================================== }
{                      BOITES DE DIALOGUE                                }
{ ====================================================================== }

Procedure DlgFrame(X1,Y1,X2,Y2: Integer; Const Title: String);
Begin
 { vue dessinee : fenetre de PM a part (son cadre et sa barre de titre
   remplacent ceux dessines) ; ouverte avant le dessin de la boite }
 If MxCatWant And (CatCl=0) Then Begin
  MxCatWant:=False;MxCatOwn:=True;
  MxCatOpen(Title,X1+3,Y1+21,X2-3,Y2-3);
 End;
 Raised(X1,Y1,X2,Y2);
 Bx(X1+3,Y1+3,X2-3,Y1+19,cNavy);
 TxB(X1+8,Y1+7,Title,cWht);
 Raised(X2-19,Y1+5,X2-5,Y1+17);
 Ln(X2-16,Y1+8,X2-9,Y1+14,cBlk);Ln(X2-16,Y1+14,X2-9,Y1+8,cBlk);
End;

Function MsgBox(Const Msg: String; Kind: Integer): Integer;
{ Kind 0 : OK ; 1 : Oui/Non ; 2 : Oui/Non/Annuler ; retour 1 oui 2 non 3 ann.
  (boite de message de PM) }
Var R: Integer;
Begin
 Case Kind Of
  0: Begin Dummy:=PmBox(APP_NAME,Msg,MB_OK Or MB_INFORMATION);R:=1;End;
  1: If PmBox(APP_NAME,Msg,MB_YESNO Or MB_ICONQUESTION)=MBID_YES Then R:=1
     Else R:=2;
  Else Begin
   R:=PmBox(APP_NAME,Msg,5 Or MB_ICONQUESTION);
   If R=MBID_YES Then R:=1 Else If R=7 Then R:=2 Else R:=3;
  End;
 End;
 Dirty:=True;
 MsgBox:=R;
End;

Procedure Info(Const S: String);
Begin
 If MsgBox(S,0)=0 Then ;
End;

{ edition d'une ligne : retourne True si la touche a ete traitee }
Function LineKey(Var S: String; Max: Integer; Var Cur: Integer; K: Word;
  Var Sel: Boolean): Boolean;
Var I: Integer; V: String;
Begin
 LineKey:=True;
 If K=3 Then Begin ClipClear;ClipAdd(S);ClipPush;Exit;End;
 If K=24 Then Begin ClipClear;ClipAdd(S);ClipPush;S:='';Cur:=0;Sel:=False;
   Exit;End;
 If K=22 Then Begin
  ClipPull;
  V:=ClipLine(1);
  If Sel Then Begin S:='';Cur:=0;Sel:=False;End;
  For I:=1 To Length(V) Do
   If (V[I]>=' ') And (Length(S)<Max) Then Begin
    Insert(V[I],S,Cur+1);Inc(Cur);
   End;
  Exit;
 End;
 If (K>=32) And (K<256) Then Begin
  If Sel Then Begin S:='';Cur:=0;Sel:=False;End;
  If Length(S)<Max Then Begin Insert(Chr(K),S,Cur+1);Inc(Cur);End;
 End Else Case K Of
  K_BKSP: Begin
    If Sel Then Begin S:='';Cur:=0;Sel:=False;End
    Else If Cur>0 Then Begin Delete(S,Cur,1);Dec(Cur);End;
   End;
  K_DEL: Begin
    If Sel Then Begin S:='';Cur:=0;Sel:=False;End
    Else If Cur<Length(S) Then Delete(S,Cur+1,1);
   End;
  K_LEFT: Begin Sel:=False;If Cur>0 Then Dec(Cur);End;
  K_RIGHT: Begin Sel:=False;If Cur<Length(S) Then Inc(Cur);End;
  K_HOME: Begin Sel:=False;Cur:=0;End;
  K_END: Begin Sel:=False;Cur:=Length(S);End;
  Else LineKey:=False;
 End;
End;

Procedure EditBox(X1,Y1,X2: Integer; Const S: String; Cur: Integer;
  Foc,Sel: Boolean);
Var W,Off: Integer; V: String;
Begin
 Sunken(X1,Y1,X2,Y1+17,cWht);
 W:=(X2-X1-8) Div 8;
 Off:=0;
 If Cur>W-1 Then Off:=Cur-W+1;
 V:=Copy(S,Off+1,W);
 If Foc And Sel Then Begin
  Bx(X1+3,Y1+3,X1+3+Length(V)*8,Y1+14,cNavy);
  Tx_(X1+4,Y1+5,V,cWht);
 End Else Tx_(X1+4,Y1+5,V,cBlk);
 If Foc And Not Sel Then Ln(X1+4+(Cur-Off)*8,Y1+3,X1+4+(Cur-Off)*8,Y1+14,cBlk);
End;

Function InputBox(Const Title,Prompt: String; Var S: String;
  Max: Integer): Boolean;
{ boite de saisie de PM : champ de saisie, boutons OK et Annuler }
Begin
 InputBox:=PmInput(Title,Prompt,S,Max);
 Dirty:=True;
End;

{ liste a choix : PickIt^[1..PickN] ; retour de l'indice dans Sel }
Function PickList(Const Title: String; Var Sel: Integer): Boolean;
{ liste de PM : PickIt^[1..PickN] ; retour de l'indice dans Sel }
Var W, H, I, Rows: LongInt;
Begin
 PickList:=False;
 If PickN<1 Then Exit;
 MxRegister;
 W:=Length(Title)*8+60;
 For I:=1 To PickN Do If Length(PickIt^[I])*8+56>W Then W:=Length(PickIt^[I])*8+56;
 If W<300 Then W:=300;
 If W>600 Then W:=600;
 Rows:=PickN;If Rows>16 Then Rows:=16;If Rows<4 Then Rows:=4;
 MlN:=PickN;MlRows:=Rows;
 H:=Rows*16+4+54;
 MlFr:=PmOpenBox('MXLIST',Title,W,H,MlCl);
 If MlFr=0 Then Exit;
 MlLb:=WinCreateWindow(MlCl,WC_LISTBOX,0,WS_VISIBLE Or WS_TABSTOP,
   10,44,W-36,Rows*16+4,MlCl,HWND_TOP,ID_MLIST,0,0);
 MlSb:=WinCreateWindow(MlCl,WC_SCROLLBAR,0,WS_VISIBLE Or SBS_VERT,
   W-26,44,16,Rows*16+4,MlCl,HWND_TOP,ID_MLSB,0,0);
 Dummy:=WinCreateWindow(MlCl,WC_BUTTON,OsZ('OK'),WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
   W-196,8,88,26,MlCl,HWND_TOP,ID_POK,0,0);
 Dummy:=WinCreateWindow(MlCl,WC_BUTTON,OsZ(T('Annuler~Cancel~Abbrechen~Cancelar~Annulla')),
   WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,W-100,8,88,26,MlCl,HWND_TOP,ID_PCANCEL,0,0);
 For I:=1 To PickN Do Dummy:=WinSendMsg(MlLb,LM_INSERTITEM,-1,OsZ(PickIt^[I]));
 If (Sel<1) Or (Sel>PickN) Then Sel:=1;
 Dummy:=WinSendMsg(MlLb,LM_SELECTITEM,Sel-1,1);
 If Sel>Rows Then Dummy:=WinSendMsg(MlLb,LM_SETTOPINDEX,Sel-Rows,0);
 MlSync;
 MlSel:=0;
 If PmModal(MlFr,MlLb,0)=1 Then Begin Sel:=MlSel;PickList:=True;End;
 Dirty:=True;
End;

Procedure PickAdd(Const S: String);
Begin
 If PickN<MAXPICK Then Begin Inc(PickN);PickIt^[PickN]:=Copy(S,1,40);End;
End;

{ ---- visionneuse de texte (rapports) ---- }

Procedure PrintText;
Var F: Text; I: Integer; N: String;
Begin
 N:='REPORT.TXT';
 If Not InputBox(T('Imprimer~Print~Drucken~Imprimir~Stampa'),
   T('Fichier ou PRN :~File or PRN:~Datei oder PRN:~Archivo o PRN:~File o PR'
     +'N:'),
   N,40) Then Exit;
 {$I-}
 Assign(F,N);
 Rewrite(F);
 For I:=1 To TXN Do WriteLn(F,TX^[I]);
 Close(F);
 {$I+}
 If IOResult<>0 Then Info(T('Impression impossible.~Cannot print.~Drucken ni'
   +'cht m@3glich.~No se puede imprimir.~Impossibile stampare.'))
 Else Info(T('Termin@e.~Done.~Fertig.~Terminado.~Fatto.'));
End;

Procedure ViewText(Const Title: String);
{ rapport dans une fenetre de PM : texte qui defile avec les barres de
  defilement de PM, boutons Imprimer et Fermer }
Var I, R, W, H: LongInt;
Begin
 MxRegister;
 VtMax:=1;
 For I:=1 To TXN Do If Length(TX^[I])>VtMax Then VtMax:=Length(TX^[I]);
 VtTop:=0;VtLeft:=0;
 W:=616;H:=390;
 VtFr:=PmOpenBox('MXVIEW',Title,W,H,VtCl);
 If VtFr=0 Then Exit;
 VtVsb:=WinCreateWindow(VtCl,WC_SCROLLBAR,0,WS_VISIBLE Or SBS_VERT,
   W-8-16,42+16,16,H-8-42-16,VtCl,HWND_TOP,ID_PVSB,0,0);
 VtHsb:=WinCreateWindow(VtCl,WC_SCROLLBAR,0,WS_VISIBLE Or SBS_HORZ,
   8,42,W-16-16,16,VtCl,HWND_TOP,ID_PHSB,0,0);
 Dummy:=WinCreateWindow(VtCl,WC_BUTTON,OsZ(MxTilde(T('&Imprimer...~&Print...~&Drucken...~&Imprimir...~&Stampa...'))),
   WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,W-8-96-8-132,8,132,26,VtCl,HWND_TOP,ID_PSAVE,0,0);
 Dummy:=WinCreateWindow(VtCl,WC_BUTTON,OsZ(T('Fermer~Close~Schlie@7en~Cerrar~Chiudi')),
   WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,W-8-96,8,96,26,VtCl,HWND_TOP,ID_PCANCEL,0,0);
 VtCols:=(W-16-16-8) Div PmChW;
 VtRows:=(H-8-42-16-4) Div PmChH;
 VtBars;
 MxBegin(VtFr);
 Repeat
  R:=MxWait(VtCl);
  If R=3 Then PrintText;
 Until R<>3;
 MxEnd(VtFr);
End;

Procedure TxAdd(Const S: String);
Begin
 If TXN<MAXTXT Then Begin Inc(TXN);TX^[TXN]:=Copy(S,1,78);End;
End;

{ ---- editeur de texte multi-lignes ---- }

Function EditTextD(Const Title: String): Boolean;
Var X1,Y1,X2,Y2,Row,Col,Top,Vis,I,N: Integer; E: TEvent; Done,Ok,Redraw:
  Boolean;
    S,Tail: String; Sel: Boolean;
Begin
 If TXN<1 Then Begin TXN:=1;TX^[1]:='';End;
 X1:=8;Y1:=24;X2:=SCR_W-9;Y2:=SCR_H-24;
 Vis:=(Y2-Y1-90) Div 11;
 Row:=1;Col:=0;Top:=1;Done:=False;Ok:=False;Redraw:=True;
 Backdrop;
 Repeat
  If Row<Top Then Top:=Row;
  If Row>=Top+Vis Then Top:=Row-Vis+1;
  If Redraw Then Begin
   DlgFrame(X1,Y1,X2,Y2,Title);
   Sunken(X1+8,Y1+26,X2-8,Y2-44,cWht);
   For I:=0 To Vis-1 Do
    If Top+I<=TXN Then Tx_(X1+12,Y1+30+I*11,Copy(TX^[Top+I],1,72),cBlk);
   I:=X1+12+Col*8;
   Ln(I,Y1+29+(Row-Top)*11,I,Y1+39+(Row-Top)*11,cRed);
   Btn(X1+20,Y2-36,X1+110,Y2-14,T('&OK (F2)~&OK (F2)~&OK (F2)~&OK (F2)~&OK ('
     +'F2)'),True);
   Btn(X1+130,Y2-36,X1+240,Y2-14,
     T('Annuler~Cancel~Abbrechen~Cancelar~Annulla'),False);
   Tx_(X2-200,Y2-30,T('Ligne~Line~Zeile~L@inea~Riga')+' '+IntStr(Row)+'/'
     +IntStr(TXN),cBlk);
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Redraw:=True;
   S:=TX^[Row];
   Case E.Key Of
    K_ESC: Done:=True;
    K_F2: Begin Ok:=True;Done:=True;End;
    K_UP: If Row>1 Then Dec(Row);
    K_DOWN: If Row<TXN Then Inc(Row);
    K_PGUP: Row:=Max2(1,Row-Vis);
    K_PGDN: Row:=Min2(TXN,Row+Vis);
    K_ENTER: If TXN<MAXTXT Then Begin
      For I:=TXN DownTo Row+1 Do TX^[I+1]:=TX^[I];
      Inc(TXN);
      TX^[Row+1]:=Copy(S,Col+1,80);TX^[Row]:=Copy(S,1,Col);
      Inc(Row);Col:=0;
     End;
    K_BKSP: If Col>0 Then Begin Delete(S,Col,1);Dec(Col);TX^[Row]:=S;End
     Else If Row>1 Then Begin
      Col:=Length(TX^[Row-1]);
      TX^[Row-1]:=Copy(TX^[Row-1]+S,1,78);
      For I:=Row To TXN-1 Do TX^[I]:=TX^[I+1];
      Dec(TXN);Dec(Row);
     End;
    K_DEL: If Col<Length(S) Then Begin Delete(S,Col+1,1);TX^[Row]:=S;End
     Else If Row<TXN Then Begin
      TX^[Row]:=Copy(S+TX^[Row+1],1,78);
      For I:=Row+1 To TXN-1 Do TX^[I]:=TX^[I+1];
      Dec(TXN);
     End;
    3: Begin
      ClipClear;
      For I:=1 To TXN Do ClipAdd(TX^[I]);
      ClipPush;
     End;
    24: Begin
      ClipClear;ClipAdd(S);ClipPush;
      For I:=Row To TXN-1 Do TX^[I]:=TX^[I+1];
      If TXN>1 Then Dec(TXN) Else TX^[1]:='';
      If Row>TXN Then Row:=TXN;
     End;
    22: Begin
      ClipPull;
      N:=ClipLines;
      If N>0 Then Begin
       Tail:=Copy(S,Col+1,80);
       If N=1 Then Begin
        TX^[Row]:=Copy(Copy(S,1,Col)+ClipLine(1)+Tail,1,72);
        Col:=Min2(Length(Copy(S,1,Col)+ClipLine(1)),72);
       End Else Begin
        If TXN+N-1>MAXTXT Then N:=MAXTXT-TXN+1;
        For I:=TXN DownTo Row+1 Do TX^[I+N-1]:=TX^[I];
        Inc(TXN,N-1);
        TX^[Row]:=Copy(Copy(S,1,Col)+ClipLine(1),1,72);
        For I:=2 To N-1 Do TX^[Row+I-1]:=ClipLine(I);
        TX^[Row+N-1]:=Copy(ClipLine(N)+Tail,1,72);
        Row:=Row+N-1;Col:=Length(ClipLine(N));
       End;
      End;
     End;
    25: Begin
      For I:=Row To TXN-1 Do TX^[I]:=TX^[I+1];
      If TXN>1 Then Dec(TXN) Else TX^[1]:='';
      If Row>TXN Then Row:=TXN;
     End;
    K_LEFT: If Col>0 Then Dec(Col) Else If Row>1 Then Begin
      Dec(Row);Col:=Length(TX^[Row]);End;
    K_RIGHT: If Col<Length(S) Then Inc(Col) Else If Row<TXN Then Begin
      Inc(Row);Col:=0;End;
    K_HOME: Col:=0;
    K_END: Col:=Length(S);
    Else If (E.Key>=32) And (E.Key<256) Then Begin
      If Length(S)>=72 Then Begin
       { retour automatique }
       If TXN<MAXTXT Then Begin
        For I:=TXN DownTo Row+1 Do TX^[I+1]:=TX^[I];
        Inc(TXN);TX^[Row+1]:='';Inc(Row);Col:=0;S:=TX^[Row];
       End;
      End;
      If Length(S)<72 Then Begin
       Insert(Chr(E.Key),S,Col+1);Inc(Col);TX^[Row]:=S;
      End;
     End Else Redraw:=False;
   End;
   If Col>Length(TX^[Row]) Then Col:=Length(TX^[Row]);
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+20,Y2-36,X1+110,Y2-14) Then Begin Ok:=True;Done:=True;End
   Else If InBox(E.X,E.Y,X1+130,Y2-36,X1+240,Y2-14) Then Done:=True
   Else If InBox(E.X,E.Y,X1+8,Y1+26,X2-8,Y2-44) Then Begin
    I:=Top+(E.Y-Y1-30) Div 11;
    If I<1 Then I:=1;
    If I>TXN Then I:=TXN;
    Row:=I;Col:=Min2((E.X-X1-12+4) Div 8,Length(TX^[Row]));
    If Col<0 Then Col:=0;
    Redraw:=True;
   End;
  End;
 Until Done;
 EditTextD:=Ok;
End;
Function EditText(Const Title: String): Boolean;
Begin
 MxCatWant:=True;EditText:=EditTextD(Title);MxCatDone;
End;

{ ====================================================================== }
{                  SCHEMA ET DONNEES DU CRM                              }
{ ====================================================================== }

Const
 NSCH = 22;

Var
 tAB,tCO,tOP,tNO,tAP,tRE,tDO,tLI,tTX,tPL,tST,tEM,tTL,tOR,tOL,tPR,tLV,tUD,
 tUS,tQR,tTP,tCF : Integer;
 UdfNm  : Array[1..10] Of String[24];
 UdfKd  : Array[1..10] Of Char;
 UdfLs  : Array[1..10] Of String[8];
 Marked : Array[1..400] Of LongInt;       { entrees marquees }
 NMark  : Integer;
 CfgCo  : String[40];

Var SchemaSp2: String;

Procedure SchemaDef(I: Integer; Var Nm,Sp: String);
Begin
 SchemaSp2:='';
 Case I Of
  1: Begin Nm:='abentry';
   Sp:='ID:I,KIND:C1,NAME:C40,SALUT:C16,PHONE:C20,FAX:C20,EMAIL:C40,WEB:C40,'
     +'ADDR1:C36,ADDR2:C36,CITY:C24,STATE:C12,ZIP:C12,COUNTRY:C20,STATUS:C16,'
     +'SOURCE:C16,TERR:C16,DEPT:C20,DIVISION:C20,EMPL:I,REVENUE:I,OWNER:C12,';
   SchemaSp2:='CREATED:D,MODIFIED:D,PERSONAL:B,LINKEDIN:C40,FACEBOOK:C40,'
     +'TWITTER:C40,SKYPE:C24,U1:C24,U2:C24,U3:C24,U4:C24,U5:C24,U6:C24,'
     +'U7:C24,U8:C24,U9:C24,U10:C24';End;
  2: Begin Nm:='contact';
   Sp:='ID:I,ENTRY_ID:I,NAME:C30,TITLE:C24,PHONE:C20,EXT:C6,MOBILE:C20,'
     +'EMAIL:C40,DEPT:C20,SALUT:C16,MAIN:B';End;
  3: Begin Nm:='oppor';
   Sp:='ID:I,ENTRY_ID:I,NAME:C40,STAGE:C16,PROB:S,AMOUNT:I,CLOSEDT:D,'
     +'OWNER:C12,PRODUCT:C24,SOURCE:C16,COMPETIT:C24,STATUS:C8,CREATED:D';End;
  4: Begin Nm:='notes';
   Sp:='ID:I,ENTRY_ID:I,ND:D,NT:C5,KIND:C14,FLAG:B,BODY:C78,CREATOR:C12';End;
  5: Begin Nm:='appt';
   Sp:='ID:I,ENTRY_ID:I,KIND:C1,AD:D,AT:C5,ET:C5,SUBJ:C50,NOTES:C60,PRIO:B,'
     +'DONE:B,OWNER:C12,CONTACT:C24,REMIND:S';End;
  6: Begin Nm:='related';Sp:='ID:I,ENTRY_ID:I,OTHER_ID:I,RELATION:C20';End;
  7: Begin Nm:='docs';
   Sp:='ID:I,ENTRY_ID:I,NAME:C40,PATH:C80,KIND:C1,DD:D,CREATOR:C12';End;
  8: Begin Nm:='library';
   Sp:='ID:I,NAME:C40,CATEGORY:C20,DESCR:C60,DD:D,CREATOR:C12,PATH:C60';End;
  9: Begin Nm:='textln';Sp:='ID:I,OWN:C1,OWNID:I,SEQ:S,LINE:C78';End;
  10: Begin Nm:='plan';Sp:='ID:I,NAME:C30,DESCR:C60';End;
  11: Begin Nm:='planstep';
   Sp:='ID:I,PLAN_ID:I,SEQ:S,DAYS:S,KIND:C1,SUBJ:C50';End;
  12: Begin Nm:='email';
   Sp:='ID:I,ENTRY_ID:I,FOLDER:C1,ED:D,ET:C5,FROMA:C40,TOA:C40,SUBJ:C50,'
     +'FLAG:B,READ:B';End;
  13: Begin Nm:='timelog';
   Sp:='ID:I,ENTRY_ID:I,TD:D,MINUTES:I,TASK:C50,BILL:B,RATE:I,USR:C12';End;
  14: Begin Nm:='orders';
   Sp:='ID:I,ENTRY_ID:I,ORDNO:C12,OD:D,STATUS:C12,TOTAL:I';End;
  15: Begin Nm:='orderln';Sp:='ID:I,ORD_ID:I,PRODUCT:C30,QTY:I,PRICE:I';End;
  16: Begin Nm:='product';Sp:='ID:I,CODE:C12,NAME:C30,PRICE:I';End;
  17: Begin Nm:='listv';Sp:='ID:I,LST:C8,VAL:C24,EXTRA:I';End;
  18: Begin Nm:='udfdef';Sp:='ID:I,SLOT:S,NAME:C24,KIND:C1,LST:C8';End;
  19: Begin Nm:='users';Sp:='ID:I,CODE:C12,NAME:C30,ROLE:C1,EMAIL:C40';End;
  20: Begin Nm:='queries';Sp:='ID:I,NAME:C30,WHERECL:C100';End;
  21: Begin Nm:='template';Sp:='ID:I,NAME:C30,KIND:C1,SUBJ:C50';End;
  Else Begin Nm:='config';Sp:='ID:I,K:C16,V:C60';End;
 End;
End;

Function OpenTables: Boolean;
Var I: Integer; Nm,Sp: String;
Begin
 OpenTables:=False;
 For I:=1 To NSCH Do Begin
  SchemaDef(I,Nm,Sp);
  If Not FileExists(TblPath(Nm,'frm')) Then
   If Not TblCreate2(Nm,Sp,SchemaSp2) Then Begin DbErr:=Nm+': '+DbErr;Exit;End;
  If TblIdx(Nm)=0 Then Begin DbErr:=Nm+': '+DbErr;Exit;End;
 End;
 tAB:=TblIdx('abentry');tCO:=TblIdx('contact');tOP:=TblIdx('oppor');
 tNO:=TblIdx('notes');tAP:=TblIdx('appt');tRE:=TblIdx('related');
 tDO:=TblIdx('docs');tLI:=TblIdx('library');tTX:=TblIdx('textln');
 tPL:=TblIdx('plan');tST:=TblIdx('planstep');tEM:=TblIdx('email');
 tTL:=TblIdx('timelog');tOR:=TblIdx('orders');tOL:=TblIdx('orderln');
 tPR:=TblIdx('product');tLV:=TblIdx('listv');tUD:=TblIdx('udfdef');
 tUS:=TblIdx('users');tQR:=TblIdx('queries');tTP:=TblIdx('template');
   tCF:=TblIdx('config');
 OpenTables:=True;
End;

{ n-ieme element d'une liste separee par des virgules }
Function Part_(Const S: String; N: Integer): String;
Var I,K,B: Integer;
Begin
 K:=1;B:=1;Part_:='';
 For I:=1 To Length(S)+1 Do
  If (I>Length(S)) Or (S[I]=',') Then Begin
   If K=N Then Begin Part_:=Copy(S,B,I-B);Exit;End;
   Inc(K);B:=I+1;
  End;
End;

Function QEsc(Const S: String): String;
Var I: Integer; R: String;
Begin
 R:='';
 For I:=1 To Length(S) Do Begin
  If S[I]='''' Then R:=R+'''''' Else R:=R+S[I];
 End;
 QEsc:=R;
End;

{ ---- legendes des champs ---- }

Function FCap(Const N: String): String;
Begin
 If N='NAME' Then FCap:=T('Nom~Name~Name~Nombre~Nome')
 Else If N='KIND' Then FCap:=T('Type~Type~Typ~Tipo~Tipo')
 Else If N='SALUT' Then FCap:=T('Salutation~Salutation~Anrede~Saludo~Saluto')
 Else If N='PHONE' Then FCap:=T('T@el@ephone~Phone~Telefon~Tel@efono~Telefono')
 Else If N='FAX' Then FCap:=T('T@el@copieur~Fax~Fax~Fax~Fax')
 Else If N='EMAIL' Then FCap:=T('Courriel~Email~E-Mail~Correo~E-mail')
 Else If N='WEB' Then FCap:=T('Site Web~Web site~Webseite~Sitio web~Sito web')
 Else If N='ADDR1' Then FCap:=T('Adresse 1~Address 1~Adresse 1~Direcci@on 1~'
   +'Indirizzo 1')
 Else If N='ADDR2' Then FCap:=T('Adresse 2~Address 2~Adresse 2~Direcci@on 2~'
   +'Indirizzo 2')
 Else If N='CITY' Then FCap:=T('Ville~City~Stadt~Ciudad~Citt@q')
 Else If N='STATE' Then FCap:=T('Province/@Etat~State/Prov.~Bundesland~Estad'
   +'o~Stato')
 Else If N='ZIP' Then FCap:=T('Code postal~Zip/Postal~PLZ~C.P.~CAP')
 Else If N='COUNTRY' Then FCap:=T('Pays~Country~Land~Pa@is~Paese')
 Else If N='STATUS' Then FCap:=T('Statut~Status~Status~Estado~Stato')
 Else If N='SOURCE' Then FCap:=T('Source~Source~Quelle~Origen~Fonte')
 Else If N='TERR' Then FCap:=T('Territoire~Territory~Gebiet~Territorio~Terri'
   +'torio')
 Else If N='DEPT' Then FCap:=T('D@epartement~Department~Abteilung~Departamen'
   +'to~Reparto')
 Else If N='DIVISION' Then FCap:=T('Division~Division~Bereich~Divisi@on~Divi'
   +'sione')
 Else If N='EMPL' Then FCap:=T('Employ@es~Employees~Mitarbeiter~Empleados~Di'
   +'pendenti')
 Else If N='REVENUE' Then FCap:=T('Revenus~Revenue~Umsatz~Ingresos~Ricavi')
 Else If N='OWNER' Then FCap:=T('Responsable~Owner~Betreuer~Responsable~Resp'
   +'onsabile')
 Else If N='CREATED' Then FCap:=T('Cr@e@e le~Created~Erstellt~Creado~Creato')
 Else If N='MODIFIED' Then FCap:=T('Modifi@e le~Modified~Ge@1ndert~Modificad'
   +'o~Modificato')
 Else If N='PERSONAL' Then FCap:=T('Personnel~Personal~Pers@2nlich~Personal~'
   +'Personale')
 Else If N='LINKEDIN' Then FCap:='LinkedIn'
 Else If N='FACEBOOK' Then FCap:='Facebook'
 Else If N='TWITTER' Then FCap:='Twitter'
 Else If N='SKYPE' Then FCap:='Skype'
 Else If N='TITLE' Then FCap:=T('Titre~Title~Titel~T@itulo~Titolo')
 Else If N='EXT' Then FCap:=T('Poste~Ext.~Durchw.~Ext.~Int.')
 Else If N='MOBILE' Then FCap:=T('Cellulaire~Mobile~Handy~M@2vil~Cellulare')
 Else If N='MAIN' Then FCap:=T('Principal~Primary~Haupt~Principal~Principale')
 Else If N='STAGE' Then FCap:=T('@Etape~Stage~Phase~Etapa~Fase')
 Else If N='PROB' Then FCap:=T('Probabilit@e %~Probability %~Wahrsch. %~Prob'
   +'abilidad %~Probabilit@q %')
 Else If N='AMOUNT' Then FCap:=T('Montant~Amount~Betrag~Importe~Importo')
 Else If N='CLOSEDT' Then FCap:=T('Fermeture pr@evue~Close date~Abschluss~Ci'
   +'erre~Chiusura')
 Else If N='PRODUCT' Then FCap:=T('Produit~Product~Produkt~Producto~Prodotto')
 Else If N='COMPETIT' Then FCap:=T('Concurrent~Competitor~Wettbewerber~Compe'
   +'tidor~Concorrente')
 Else If N='ND' Then FCap:=T('Date~Date~Datum~Fecha~Data')
 Else If N='NT' Then FCap:=T('Heure~Time~Zeit~Hora~Ora')
 Else If N='BODY' Then FCap:=T('Texte~Text~Text~Texto~Testo')
 Else If N='FLAG' Then FCap:=T('Important~Flagged~Wichtig~Importante~Importa'
   +'nte')
 Else If N='CREATOR' Then FCap:=T('Cr@eateur~Creator~Ersteller~Creador~Creat'
   +'ore')
 Else If N='AD' Then FCap:=T('Date~Date~Datum~Fecha~Data')
 Else If N='AT' Then FCap:=T('D@ebut~Start~Beginn~Inicio~Inizio')
 Else If N='ET' Then FCap:=T('Fin~End~Ende~Fin~Fine')
 Else If N='SUBJ' Then FCap:=T('Sujet~Subject~Betreff~Asunto~Oggetto')
 Else If N='NOTES' Then FCap:=T('Notes~Notes~Notizen~Notas~Note')
 Else If N='PRIO' Then FCap:=T('Priorit@e~Priority~Priorit@1t~Prioridad~Prio'
   +'rit@q')
 Else If N='DONE' Then FCap:=T('Termin@e~Done~Erledigt~Hecho~Fatto')
 Else If N='CONTACT' Then FCap:=T('Contact~Contact~Kontakt~Contacto~Contatto')
 Else If N='REMIND' Then FCap:=T('Rappel (min)~Reminder (min)~Erinnerung (Mi'
   +'n)~Aviso (min)~Promemoria (min)')
 Else If N='RELATION' Then FCap:=T('Relation~Relationship~Beziehung~Relaci@o'
   +'n~Relazione')
 Else If N='OTHER_ID' Then FCap:=T('Entr@ee li@ee~Related entry~Verkn@3pfter'
   +' Eintrag~Entrada~Voce collegata')
 Else If N='ENTRY_ID' Then FCap:=T('Entr@ee~Entry~Eintrag~Entrada~Voce')
 Else If N='PATH' Then FCap:=T('Chemin / URL~Path / URL~Pfad / URL~Ruta / UR'
   +'L~Percorso / URL')
 Else If N='CATEGORY' Then FCap:=T('Cat@egorie~Category~Kategorie~Categor@ia'
   +'~Categoria')
 Else If N='DESCR' Then FCap:=T('Description~Description~Beschreibung~Descri'
   +'pci@on~Descrizione')
 Else If N='DD' Then FCap:=T('Date~Date~Datum~Fecha~Data')
 Else If N='DAYS' Then FCap:=T('Jours apr@es~Days after~Tage danach~D@ias de'
   +'spu@es~Giorni dopo')
 Else If N='SEQ' Then FCap:=T('S@equence~Sequence~Reihenfolge~Secuencia~Sequ'
   +'enza')
 Else If N='ED' Then FCap:=T('Date~Date~Datum~Fecha~Data')
 Else If N='FROMA' Then FCap:=T('De~From~Von~De~Da')
 Else If N='TOA' Then FCap:=T('@A~To~An~Para~A')
 Else If N='READ' Then FCap:=T('Lu~Read~Gelesen~Le@ido~Letto')
 Else If N='FOLDER' Then FCap:=T('Dossier~Folder~Ordner~Carpeta~Cartella')
 Else If N='TD' Then FCap:=T('Date~Date~Datum~Fecha~Data')
 Else If N='MINUTES' Then FCap:=T('Dur@ee (h:mm)~Time (h:mm)~Dauer (h:mm)~Ti'
   +'empo (h:mm)~Durata (h:mm)')
 Else If N='TASK' Then FCap:=T('T@qche~Task~Aufgabe~Tarea~Attivit@q')
 Else If N='BILL' Then FCap:=T('Facturable~Billable~Abrechenbar~Facturable~F'
   +'atturabile')
 Else If N='RATE' Then FCap:=T('Taux~Rate~Satz~Tarifa~Tariffa')
 Else If N='USR' Then FCap:=T('Utilisateur~User~Benutzer~Usuario~Utente')
 Else If N='ORDNO' Then FCap:=T('N@o commande~Order no.~Auftrag Nr.~N@o pedi'
   +'do~N. ordine')
 Else If N='OD' Then FCap:=T('Date~Date~Datum~Fecha~Data')
 Else If N='TOTAL' Then FCap:=T('Total~Total~Summe~Total~Totale')
 Else If N='QTY' Then FCap:=T('Qt@e~Qty~Menge~Cant.~Qt@q')
 Else If N='PRICE' Then FCap:=T('Prix~Price~Preis~Precio~Prezzo')
 Else If N='CODE' Then FCap:=T('Code~Code~Code~C@odigo~Codice')
 Else If N='LST' Then FCap:=T('Liste~List~Liste~Lista~Lista')
 Else If N='VAL' Then FCap:=T('Valeur~Value~Wert~Valor~Valore')
 Else If N='EXTRA' Then FCap:=T('Valeur num.~Numeric~Zahl~N@3mero~Numero')
 Else If N='SLOT' Then FCap:=T('Champ n@o~Field no.~Feld Nr.~Campo n@o~Campo'
   +' n.')
 Else If N='ROLE' Then FCap:=T('R@ole~Role~Rolle~Rol~Ruolo')
 Else If N='WHERECL' Then FCap:=T('Condition SQL~SQL condition~SQL-Bedingung'
   +'~Condici@on SQL~Condizione SQL')
 Else If N='ORD_ID' Then FCap:=T('Commande~Order~Auftrag~Pedido~Ordine')
 Else If N='PLAN_ID' Then FCap:=T('Plan~Plan~Plan~Plan~Piano')
 Else If N='LINE' Then FCap:=T('Ligne~Line~Zeile~L@inea~Riga')
 Else If (N[1]='U') And (Length(N)<=3) And (ValInt(Copy(N,2,2),0)>0) Then
  FCap:=UdfNm[ValInt(Copy(N,2,2),0)]
 Else FCap:=N;
End;

Function IsMoneyF(Const N: String): Boolean;
Begin
 IsMoneyF:=(N='AMOUNT') Or (N='REVENUE') Or (N='TOTAL') Or (N='PRICE')
  Or (N='RATE');
End;

{ ---- listes de codes ---- }

Function CodeCount(Const K: String): Integer;
Begin
 If K='EK' Then CodeCount:=2 Else If K='AK' Then CodeCount:=4
 Else If K='FD' Then CodeCount:=4 Else If K='DK' Then CodeCount:=3
 Else If K='TK' Then CodeCount:=4 Else If K='RL' Then CodeCount:=2
 Else If K='UK' Then CodeCount:=4 Else If K='PR' Then CodeCount:=3
 Else CodeCount:=0;
End;

Function CodeAt(Const K: String; I: Integer): Char;
Var S: String;
Begin
 If K='EK' Then S:='CI' Else If K='AK' Then S:='MCTA'
 Else If K='FD' Then S:='ISDO' Else If K='DK' Then S:='FLD'
 Else If K='TK' Then S:='LFDE' Else If K='RL' Then S:='AU'
 Else If K='UK' Then S:='TNDL' Else If K='PR' Then S:='123' Else S:=' ';
 CodeAt:=S[I];
End;

Function CodeName(Const K: String; C: Char): String;
Begin
 CodeName:='';
 If K='EK' Then Begin
  If C='I' Then CodeName:=T('Individu~Individual~Einzelperson~Individuo~Indi'
    +'viduo')
  Else CodeName:=T('Entreprise~Company~Firma~Empresa~Azienda');
 End Else If K='AK' Then Begin
  Case C Of
   'M': CodeName:=T('R@eunion~Meeting~Besprechung~Reuni@on~Riunione');
   'C': CodeName:=T('Appel~Phone call~Anruf~Llamada~Chiamata');
   'T': CodeName:=T('@A faire~To-do~Aufgabe~Tarea~Da fare');
   Else CodeName:=T('Plan d''action~Action plan~Aktionsplan~Plan de acci@on~'
     +'Piano d''azione');
  End;
 End Else If K='FD' Then Begin
  Case C Of
   'I': CodeName:=T('R@eception~Inbox~Posteingang~Entrada~Posta in arrivo');
   'S': CodeName:=T('Envoy@es~Sent~Gesendet~Enviados~Inviati');
   'D': CodeName:=T('Brouillons~Drafts~Entw@3rfe~Borradores~Bozze');
   Else CodeName:=T('Bo@ite d''envoi~Outbox~Postausgang~Salida~Posta in usci'
     +'ta');
  End;
 End Else If K='DK' Then Begin
  Case C Of
   'F': CodeName:=T('Fichier~File~Datei~Archivo~File');
   'L': CodeName:=T('Hyperlien~Hyperlink~Hyperlink~Hiperv@inculo~Collegamento');
   Else CodeName:=T('Document~Document~Dokument~Documento~Documento');
  End;
 End Else If K='TK' Then Begin
  Case C Of
   'L': CodeName:=T('Lettre~Letter~Brief~Carta~Lettera');
   'F': CodeName:=T('Fax~Fax~Fax~Fax~Fax');
   'D': CodeName:=T('Document~Document~Dokument~Documento~Documento');
   Else CodeName:=T('Courriel~Email~E-Mail~Correo~E-mail');
  End;
 End Else If K='RL' Then Begin
  If C='A' Then CodeName:=T('Administrateur~Administrator~Administrator~Admi'
    +'nistrador~Amministratore')
  Else CodeName:=T('Utilisateur~User~Benutzer~Usuario~Utente');
 End Else If K='UK' Then Begin
  Case C Of
   'T': CodeName:=T('Texte~Text~Text~Texto~Testo');
   'N': CodeName:=T('Nombre~Number~Zahl~N@3mero~Numero');
   'D': CodeName:=T('Date~Date~Datum~Fecha~Data');
   Else CodeName:=T('Liste~List~Liste~Lista~Lista');
  End;
 End Else If K='PR' Then Begin
  Case C Of
   '1': CodeName:=T('Haute~High~Hoch~Alta~Alta');
   '2': CodeName:=T('Normale~Normal~Normal~Normal~Normale');
   Else CodeName:=T('Basse~Low~Niedrig~Baja~Bassa');
  End;
 End;
End;

{ genre d'un champ : 0 texte 1 entier 2 date 3 argent 4 oui/non 5 liste
  6 code 7 utilisateur ; Key = nom de liste ou de code }
Function FKind(TI,F: Integer; Var Key: String): Integer;
Var TN,FN: String; Ty: Char; U: Integer;
Begin
 TN:=Tb[TI]^.Nm;FN:=Tb[TI]^.F[F].Nm;Ty:=Tb[TI]^.F[F].Typ;Key:='';
 FKind:=0;
 If Ty='D' Then Begin FKind:=2;Exit;End;
 If (FN='PRIO') Then Begin Key:='PR';FKind:=6;Exit;End;
 If Ty='B' Then Begin FKind:=4;Exit;End;
 If Ty In ['I','S'] Then Begin
  If IsMoneyF(FN) Then FKind:=3 Else FKind:=1;
  Exit;
 End;
 If (FN='OWNER') Or (FN='CREATOR') Or (FN='USR') Then Begin FKind:=7;Exit;End;
 If (TN='abentry') And (FN='KIND') Then Begin Key:='EK';FKind:=6;End
 Else If (TN='appt') And (FN='KIND') Then Begin Key:='AK';FKind:=6;End
 Else If (TN='planstep') And (FN='KIND') Then Begin Key:='AK';FKind:=6;End
 Else If (TN='docs') And (FN='KIND') Then Begin Key:='DK';FKind:=6;End
 Else If (TN='template') And (FN='KIND') Then Begin Key:='TK';FKind:=6;End
 Else If (TN='udfdef') And (FN='KIND') Then Begin Key:='UK';FKind:=6;End
 Else If (TN='email') And (FN='FOLDER') Then Begin Key:='FD';FKind:=6;End
 Else If (TN='users') And (FN='ROLE') Then Begin Key:='RL';FKind:=6;End
 Else If (TN='abentry') And (FN='STATUS') Then Begin Key:='STATUS';FKind:=5;End
 Else If (TN='oppor') And (FN='STATUS') Then Begin Key:='OPPST';FKind:=5;End
 Else If (TN='orders') And (FN='STATUS') Then Begin Key:='ORDST';FKind:=5;End
 Else If FN='SOURCE' Then Begin Key:='SOURCE';FKind:=5;End
 Else If FN='TERR' Then Begin Key:='TERR';FKind:=5;End
 Else If FN='STAGE' Then Begin Key:='STAGE';FKind:=5;End
 Else If (TN='notes') And (FN='KIND') Then Begin Key:='NOTET';FKind:=5;End
 Else If FN='SALUT' Then Begin Key:='SALUT';FKind:=5;End
 Else If (TN='abentry') And (FN[1]='U') And (Length(FN)<=3) Then Begin
  U:=ValInt(Copy(FN,2,2),0);
  If (U>=1) And (U<=10) Then Begin
   If UdfKd[U]='D' Then FKind:=2
   Else If UdfKd[U]='N' Then FKind:=1
   Else If UdfKd[U]='L' Then Begin Key:=UdfLs[U];FKind:=5;End;
  End;
 End;
End;

{ ---- acces pratiques ---- }

Function Fx(TI: Integer; Const N: String): Integer;
Begin
 Fx:=FldIndex(Tb[TI],N);
End;

Function SG(TI: Integer; B: PRec; Const N: String): String;
Begin
 SG:=GetS(TI,B,Fx(TI,N));
End;

Function NG(TI: Integer; B: PRec; Const N: String): LongInt;
Begin
 NG:=GetN(TI,B,Fx(TI,N));
End;

Procedure SS(TI: Integer; B: PRec; Const N: String; Const V: String);
Begin
 SetS(TI,B,Fx(TI,N),V);
End;

Procedure SN(TI: Integer; B: PRec; Const N: String; V: LongInt);
Begin
 SetN(TI,B,Fx(TI,N),V);
End;

{ nom d'une entree du carnet d'adresses }
Function EntryName(Id: LongInt): String;
Var S: LongInt;
Begin
 EntryName:='';
 If Id<=0 Then Exit;
 S:=RowFind(tAB,Id);
 If (S>=0) And RowGet(tAB,S,RB2) Then EntryName:=SG(tAB,RB2,'NAME');
End;

Function CurIsAdmin: Boolean;
Begin
 CurIsAdmin:=True;
End;

Procedure UdfLoad;
Var I: Integer; S: LongInt; Sl: Integer; Q: String;
Begin
 For I:=1 To 10 Do Begin UdfNm[I]:=T('Champ~Field~Feld~Campo~Campo')+' '
   +IntStr(I);UdfKd[I]:='T';UdfLs[I]:='';End;
 For S:=0 To Tb[tUD]^.Slots-1 Do
  If RowGet(tUD,S,RB2) Then Begin
   Sl:=NG(tUD,RB2,'SLOT');
   If (Sl>=1) And (Sl<=10) Then Begin
    UdfNm[Sl]:=SG(tUD,RB2,'NAME');
    Q:=SG(tUD,RB2,'KIND');
    If Q='' Then Q:='T';
    UdfKd[Sl]:=Q[1];
    UdfLs[Sl]:=SG(tUD,RB2,'LST');
   End;
  End;
End;

Function UdfDefined(I: Integer): Boolean;
Var S: LongInt;
Begin
 UdfDefined:=False;
 For S:=0 To Tb[tUD]^.Slots-1 Do
  If RowGet(tUD,S,RB2) Then If NG(tUD,RB2,'SLOT')=I Then UdfDefined:=True;
End;

{ liste de valeurs : remplit PickIt }
Procedure LoadList(Const Lst: String);
Var S: LongInt; I: Integer;
Begin
 PickN:=0;
 If SqlRun('SELECT * FROM listv WHERE lst='''+Lst+''' ORDER BY val') Then
  For I:=1 To SqlN Do
   If RowGet(tLV,P1^[I],RB2) Then PickAdd(SG(tLV,RB2,'VAL'));
End;

Procedure LoadUsers;
Var S: LongInt;
Begin
 PickN:=0;
 For S:=0 To Tb[tUS]^.Slots-1 Do
  If RowGet(tUS,S,RB2) Then PickAdd(SG(tUS,RB2,'CODE'));
End;

{ ---- texte multi-lignes lie a un enregistrement ---- }

Procedure TextLoad(Own: Char; Id: LongInt);
Var I: Integer; Q: String;
Begin
 TXN:=0;
 Q:='SELECT * FROM textln WHERE own='''+Own+''' AND ownid='+IntStr(Id)
   +' ORDER BY seq';
 If SqlRun(Q) Then
  For I:=1 To SqlN Do
   If RowGet(tTX,P1^[I],RB2) Then TxAdd(SG(tTX,RB2,'LINE'));
End;

Procedure DelWhere(Const Tn,Cond: String);
Begin
 If SqlRun('DELETE FROM '+Tn+' WHERE '+Cond) Then ;
End;

Procedure TextSave(Own: Char; Id: LongInt);
Var I: Integer;
Begin
 DelWhere('textln','own='''+Own+''' AND ownid='+IntStr(Id));
 For I:=1 To TXN Do Begin
  NewRow(tTX,RB2);
  SS(tTX,RB2,'OWN',Own);SN(tTX,RB2,'OWNID',Id);SN(tTX,RB2,'SEQ',I);
  SS(tTX,RB2,'LINE',TX^[I]);
  If RowAdd(tTX,RB2)=0 Then ;
 End;
 TblFlush(tTX);
End;

{ ---- ajout rapide ---- }

Function AddNote(Entry: LongInt; Const Kind,Body: String; Own: Boolean):
  LongInt;
Var Id: LongInt; I: Integer;
Begin
 NewRow(tNO,RB2);
 SN(tNO,RB2,'ENTRY_ID',Entry);SN(tNO,RB2,'ND',SessDate);
 SS(tNO,RB2,'NT',NowTime);SS(tNO,RB2,'KIND',Kind);
 If TXN>0 Then SS(tNO,RB2,'BODY',TX^[1]) Else SS(tNO,RB2,'BODY',Body);
 SS(tNO,RB2,'CREATOR',UserCode);
 Id:=RowAdd(tNO,RB2);
 If (Id>0) And (TXN>1) Then TextSave('N',Id);
 TblFlush(tNO);
 AddNote:=Id;
End;

Procedure Touch(Id: LongInt);
Var S: LongInt;
Begin
 S:=RowFind(tAB,Id);
 If (S>=0) And RowGet(tAB,S,RB2) Then Begin
  SN(tAB,RB2,'MODIFIED',SessDate);
  If RowPut(tAB,S,RB2) Then ;
 End;
End;

Procedure DeleteEntry(Id: LongInt);
Var S: LongInt; Q: String; I: Integer;
Begin
 Q:='entry_id='+IntStr(Id);
 { textes lies aux notes et courriels }
 If SqlRun('SELECT * FROM notes WHERE '+Q) Then
  For I:=1 To SqlN Do
   If RowGet(tNO,P1^[I],RB2) Then
    DelWhere('textln','own=''N'' AND ownid='+IntStr(GetN(tNO,RB2,1)));
 If SqlRun('SELECT * FROM orders WHERE '+Q) Then
  For I:=1 To SqlN Do
   If RowGet(tOR,P1^[I],RB2) Then
    DelWhere('orderln','ord_id='+IntStr(GetN(tOR,RB2,1)));
 DelWhere('contact',Q);DelWhere('oppor',Q);DelWhere('notes',Q);
 DelWhere('appt',Q);DelWhere('docs',Q);DelWhere('email',Q);
 DelWhere('timelog',Q);DelWhere('orders',Q);
 DelWhere('related',Q+' OR other_id='+IntStr(Id));
 S:=RowFind(tAB,Id);
 If S>=0 Then RowDel(tAB,S);
 TblFlushAll;
End;

Function MarkIdx(Id: LongInt): Integer;
Var I: Integer;
Begin
 MarkIdx:=0;
 For I:=1 To NMark Do If Marked[I]=Id Then MarkIdx:=I;
End;

Procedure ToggleMark(Id: LongInt);
Var I: Integer;
Begin
 I:=MarkIdx(Id);
 If I>0 Then Begin Marked[I]:=Marked[NMark];Dec(NMark);End
 Else If NMark<400 Then Begin Inc(NMark);Marked[NMark]:=Id;End;
End;

{ ---- donnees de demonstration ---- }

Procedure Cfg(Const K,V: String);
Begin
 If SqlRun('INSERT INTO config (k,v) VALUES ('''+K+''','''+V+''')') Then ;
End;

Function PS(Const S: String; N: Integer): String;
Var I,K,B: Integer;
Begin
 K:=1;B:=1;PS:='';
 For I:=1 To Length(S)+1 Do
  If (I>Length(S)) Or (S[I]='|') Then Begin
   If K=N Then Begin PS:=Copy(S,B,I-B);Exit;End;
   Inc(K);B:=I+1;
  End;
End;

{ Nom|Tel|Courriel|Ville|Prov|Adresse|CP|Employes|Revenu }
Function SeedEntry(Const S: String): LongInt;
Begin
 NewRow(tAB,RB2);
 SS(tAB,RB2,'KIND','C');SS(tAB,RB2,'NAME',PS(S,1));SS(tAB,RB2,'PHONE',PS(S,2));
 SS(tAB,RB2,'EMAIL',PS(S,3));SS(tAB,RB2,'CITY',PS(S,4));
 SS(tAB,RB2,'STATE',PS(S,5));SS(tAB,RB2,'ADDR1',PS(S,6));
 SS(tAB,RB2,'ZIP',PS(S,7));SS(tAB,RB2,'OWNER',UserCode);
 SS(tAB,RB2,'COUNTRY',T('Canada~Canada~Kanada'));
 SN(tAB,RB2,'EMPL',ValInt(PS(S,8),0));SN(tAB,RB2,'REVENUE'
   ,ValInt(PS(S,9),0)*100);
 SN(tAB,RB2,'CREATED',AddDays(SessDate,-200));SN(tAB,RB2,'MODIFIED',SessDate);
 SS(tAB,RB2,'WEB','www.'+Lower(Copy(PS(S,1),1,6))+'.com');
 SeedEntry:=RowAdd(tAB,RB2);
End;

{ Entree|Nom|Titre|Tel|Courriel }
Procedure SeedContact(E: LongInt; Const S: String);
Begin
 NewRow(tCO,RB2);
 SN(tCO,RB2,'ENTRY_ID',E);SS(tCO,RB2,'NAME',PS(S,1));SS(tCO,RB2,'TITLE'
   ,PS(S,2));
 SS(tCO,RB2,'PHONE',PS(S,3));SS(tCO,RB2,'EMAIL',PS(S,4));
 If RowAdd(tCO,RB2)=0 Then ;
End;

{ Nom|Etape|Prob|Montant|Jours|Produit }
Procedure SeedOpp(E: LongInt; Const S: String);
Begin
 NewRow(tOP,RB2);
 SN(tOP,RB2,'ENTRY_ID',E);SS(tOP,RB2,'NAME',T(PS(S,1)));SS(tOP,RB2,'STAGE'
   ,T(PS(S,2)));
 SN(tOP,RB2,'PROB',ValInt(PS(S,3),0));SN(tOP,RB2,'AMOUNT'
   ,ValInt(PS(S,4),0)*100);
 SN(tOP,RB2,'CLOSEDT',AddDays(SessDate,ValInt(PS(S,5),0)));SS(tOP,RB2,'OWNER'
   ,UserCode);
 SS(tOP,RB2,'PRODUCT',PS(S,6));SS(tOP,RB2,'STATUS',T('Ouverte~Open~Offen'));
 SN(tOP,RB2,'CREATED',AddDays(SessDate,-30));
 If RowAdd(tOP,RB2)=0 Then ;
End;

{ Type|Jours|Heure|Sujet }
Procedure SeedAppt(E: LongInt; Const S: String);
Begin
 NewRow(tAP,RB2);
 SN(tAP,RB2,'ENTRY_ID',E);SS(tAP,RB2,'KIND',PS(S,1));
 SN(tAP,RB2,'AD',AddDays(SessDate,ValInt(PS(S,2),0)));SS(tAP,RB2,'AT',PS(S,3));
 SS(tAP,RB2,'ET',PS(S,3));SS(tAP,RB2,'SUBJ',T(PS(S,4)));SS(tAP,RB2,'OWNER'
   ,UserCode);
 SN(tAP,RB2,'PRIO',2);
 If RowAdd(tAP,RB2)=0 Then ;
End;

Procedure SeedList(Const L: String; Const Items: String);
Var I: Integer; Tk: String; Ex: LongInt;
Begin
 Tk:='';
 For I:=1 To Length(Items)+1 Do
  If (I>Length(Items)) Or (Items[I]='|') Then Begin
   NewRow(tLV,RB2);
   SS(tLV,RB2,'LST',L);
   Ex:=0;
   If Pos('=',Tk)>0 Then Begin
    Ex:=ValInt(Copy(Tk,Pos('=',Tk)+1,5),0);Tk:=Copy(Tk,1,Pos('=',Tk)-1);
   End;
   SS(tLV,RB2,'VAL',Tk);SN(tLV,RB2,'EXTRA',Ex);
   If RowAdd(tLV,RB2)=0 Then ;
   Tk:='';
  End Else Tk:=Tk+Items[I];
End;

Procedure SeedText(Own: Char; Id: LongInt; Const A,B: String);
Begin
 TXN:=0;
 TxAdd(A);If B<>'' Then TxAdd(B);
 TextSave(Own,Id);
End;

Procedure SeedStep(Pl: LongInt; Sq,Dy: Integer; Const K,Subj: String);
Begin
 NewRow(tST,RB2);SN(tST,RB2,'PLAN_ID',Pl);SN(tST,RB2,'SEQ',Sq);
 SN(tST,RB2,'DAYS',Dy);SS(tST,RB2,'KIND',K);SS(tST,RB2,'SUBJ',T(Subj));
 If RowAdd(tST,RB2)=0 Then ;
End;

Procedure SeedUser(Const C,N,R: String);
Begin
 NewRow(tUS,RB2);SS(tUS,RB2,'CODE',C);SS(tUS,RB2,'NAME',N);SS(tUS,RB2,'ROLE',R);
 SS(tUS,RB2,'EMAIL',Lower(C)+'@maximilien.example');
 If RowAdd(tUS,RB2)=0 Then ;
End;

Procedure SeedProd(Const C,N: String; P: LongInt);
Begin
 NewRow(tPR,RB2);SS(tPR,RB2,'CODE',C);SS(tPR,RB2,'NAME',N);SN(tPR,RB2,'PRICE'
   ,P);
 If RowAdd(tPR,RB2)=0 Then ;
End;

Procedure SeedLine(Ord: LongInt; Const P: String; Q,Pr: LongInt);
Begin
 NewRow(tOL,RB2);SN(tOL,RB2,'ORD_ID',Ord);SS(tOL,RB2,'PRODUCT',P);
 SN(tOL,RB2,'QTY',Q);SN(tOL,RB2,'PRICE',Pr);
 If RowAdd(tOL,RB2)=0 Then ;
End;

Procedure SeedMail(E: LongInt; F: Char; Const Fr,To_,Sj,Body: String);
Var Id: LongInt;
Begin
 NewRow(tEM,RB2);SN(tEM,RB2,'ENTRY_ID',E);SS(tEM,RB2,'FOLDER',F);
 SN(tEM,RB2,'ED',SessDate);SS(tEM,RB2,'ET','09:15');SS(tEM,RB2,'FROMA',Fr);
 SS(tEM,RB2,'TOA',To_);SS(tEM,RB2,'SUBJ',T(Sj));SN(tEM,RB2,'READ',1);
 Id:=RowAdd(tEM,RB2);
 SeedText('E',Id,T(Body),'');
End;

{ donnees de base : societe, utilisateurs, listes de valeurs }
Procedure SeedBase(Const Nm: String; Demo: Boolean);
Begin
 Cfg('COMPANY',Nm);
 Cfg('DBNAME',Nm);
 If Demo Then Begin
  SeedUser('JNAPOLI','Jim Napoli','A');SeedUser('ASMITH','Anna Smith','U');
  SeedUser('ADMIN','Administrator','A');
 End Else SeedUser(UserCode,UserCode,'A');
 SeedList('STATUS',T('Prospect|Client|Ancien client|Piste~Prospect|Customer|'
   +'Former customer|Lead~Interessent|Kunde|Ex-Kunde|Lead'));
 SeedList('SOURCE',T('R@ef@erence|Site Web|Salon|Appel|Publicit@e~Referral|W'
   +'eb site|Trade show|Cold call|Advertisement~Empfehlung|Webseite|Messe|Ka'
   +'ltakquise|Werbung'));
 SeedList('TERR',T('Est|Ouest|Nord|Sud|International~East|West|North|South|I'
   +'nternational~Ost|West|Nord|S@3d|International'));
 SeedList('STAGE',T('Prospection=10|Qualification=25|Proposition=50|N@egocia'
   +'tion=75|Gagn@ee=100|Perdue=0~Prospecting=10|Qualification=25|Proposal=5'
   +'0|Negotiation=75|Closed won=100|Closed lost=0~Akquise=10|Qualifizierung'
   +'=25|Angebot=50|Verhandlung=75|Gewonnen=100|Verloren=0'));
 SeedList('OPPST',T('Ouverte|Gagn@ee|Perdue~Open|Won|Lost~Offen|Gewonnen|Ver'
   +'loren'));
 SeedList('ORDST',T('Ouverte|Exp@edi@ee|Factur@ee|Annul@ee~Open|Shipped|Invo'
   +'iced|Cancelled~Offen|Versandt|Fakturiert|Storniert'));
 SeedList('NOTET',T('Note|Appel|Courriel|R@eunion|Lettre|Fax~Note|Phone call'
   +'|Email|Meeting|Letter|Fax~Notiz|Anruf|E-Mail|Besprechung|Brief|Fax'));
 SeedList('SALUT',T('M.|Mme|Dr~Mr.|Ms.|Dr.~Herr|Frau|Dr.'));
 SeedList('REL',T('Partenaire|Filiale|Concurrent~Partner|Subsidiary|Competit'
   +'or~Partner|Tochter|Wettbewerber'));
End;

Procedure SeedDemo;
Var E1,E2,E3,E4,E5,E6,Id,Pl: LongInt;
Begin
 SessDate:=TodayDate;
 SeedBase(T('Escona Tutoriel~Escona Tutorial~Escona Tutorial'),True);
 E1:=SeedEntry('Edgar Bros.|(604) 601-8000|escona@maximizer.com|Toronto|ON|1'
   +'2 King Street|M5H 1A1|42|8500000');
 E2:=SeedEntry('Erickson Fine Wines|(208) 555-0141|erickson@example.com|Eagl'
   +'e|ID|88 Vine Road|83616|15|1200000');
 E3:=SeedEntry('Fairview Wines & Spirits|(518) 555-0177|fairview@example.com'
   +'|Hudson|NY|5 Warren Street|12534|28|3400000');
 E4:=SeedEntry('Farmer & Co.|(310) 555-0123|farmer@example.com|Los Angeles|C'
   +'A|900 Sunset Blvd|90028|60|9900000');
 E5:=SeedEntry('Ferrari Carano Vineyards|(707) 555-0190|ferrari@example.com|'
   +'Healdsburg|CA|8761 Dry Creek Rd|95448|120|20000000');
 E6:=SeedEntry('For All Occasions|(336) 555-0166|forall@example.com|Burlingt'
   +'on|NC|40 Main Street|27215|9|600000');
 Id:=SeedEntry('Fremont Fresh Market & Wine|(206) 555-0112|fremont@example.c'
   +'om|Seattle|WA|3 Fremont Ave|98103|35|4100000');
 Id:=SeedEntry('Full Circle Management Ltd.|(204) 555-0199|fullcircle@exampl'
   +'e.com|Winnipeg|MB|101 Portage Ave|R3B 2B2|22|2700000');
 Id:=SeedEntry('Galluccio Estate Vineyard|(631) 555-0135|galluccio@example.c'
   +'om|Cutchogue|NY|2 North Road|11935|18|1900000');
 Id:=SeedEntry('Garnet Liquors|(212) 555-0188|garnet@example.com|New York|NY'
   +'|410 Park Avenue|10022|14|2200000');
 Id:=SeedEntry('Grape Expectations|(845) 555-0107|grape@example.com|Blauvelt'
   +'|NY|7 Western Hwy|10913|6|450000');
 Id:=SeedEntry('Isabella''s Imports|(416) 555-0170|isabella@example.com|Toro'
   +'nto|ON|77 Queen Street|M5C 1S5|12|1500000');
 SeedContact(E1,'Chen, Melanie|Buyer|(604) 601-8001|mchen@example.com');
 SeedContact(E1,'Wiley, Kendall Val|Manager|(604) 601-8002|kwiley@example.com');
 SeedContact(E2,'Bennington, Albert|Owner|(208) 555-0142|abenn@example.com');
 SeedContact(E3,'Kline, Winifred|Purchasing|(518) 555-0178|wkline@example.com');
 SeedContact(E4,'Cash, Jefferey Reid|President|(310) 555-0124|jcash@example.'
   +'com');
 SeedContact(E5,'Ferrari, Giulia|Director|(707) 555-0191|gferrari@example.com');
 SeedOpp(E1,'Commande annuelle~Annual order~Jahresbestellung|Proposition~Pro'
   +'posal~Angebot|50|120000|25|Merlot');
 SeedOpp(E4,'Contrat de distribution~Distribution contract~Liefervertrag|N@e'
   +'gociation~Negotiation~Verhandlung|75|480000|12|Chardonnay');
 SeedOpp(E5,'D@egustation~Tasting event~Verkostung|Qualification~Qualificati'
   +'on~Qualifizierung|25|65000|60|Pinot Noir');
 SeedOpp(E3,'Renouvellement~Renewal~Verl@4ngerung|Prospection~Prospecting~Ak'
   +'quise|10|30000|90|Riesling');
 SeedAppt(E1,'M|0|10:00|R@eunion de suivi~Follow-up meeting~Nachfassbesprech'
   +'ung');
 SeedAppt(E4,'C|0|14:30|Appeler pour la proposition~Call about proposal~Anru'
   +'f wegen Angebot');
 SeedAppt(E2,'T|-2|09:00|Envoyer l''@echantillon~Send sample~Muster senden');
 SeedAppt(E5,'M|3|11:00|Visite du vignoble~Vineyard visit~Weinbergbesuch');
 SeedAppt(E6,'T|5|16:00|Pr@eparer le devis~Prepare quote~Angebot vorbereiten');
 TXN:=0;
 TxAdd(T('Premier contact @etabli lors du salon.~First contact made at the t'
   +'rade show.~Erstkontakt auf der Messe.'));
 TxAdd(T('Int@er@et pour la gamme de rouges.~Interested in the red wine rang'
   +'e.~Interesse an Rotweinen.'));
 Id:=AddNote(E1,T('Appel~Phone call~Anruf'),'',False);
 TXN:=0;
 Id:=AddNote(E4,T('Note~Note~Notiz'),T('Veut une remise sur volume.~Wants a '
   +'volume discount.~Will Mengenrabatt.'),False);
 Id:=AddNote(E5,T('R@eunion~Meeting~Besprechung'),T('Visite pr@evue le mois '
   +'prochain.~Visit planned next month.~Besuch n@1chsten Monat.'),False);
 NewRow(tLI,RB2);SS(tLI,RB2,'NAME',T('Guide des produits~Product guide~Produ'
   +'ktf@3hrer'));
 SS(tLI,RB2,'CATEGORY',T('Ventes~Sales~Vertrieb'));SN(tLI,RB2,'DD',SessDate);
 SS(tLI,RB2,'CREATOR',UserCode);
 Id:=RowAdd(tLI,RB2);
 SeedText('L',Id,'GUIDE','Merlot, Chardonnay, Pinot Noir, Riesling.');
 NewRow(tPL,RB2);SS(tPL,RB2,'NAME',T('Accueil nouveau client~New customer we'
   +'lcome~Willkommen Neukunde'));
 Pl:=RowAdd(tPL,RB2);
 SeedStep(Pl,1,1,'C','Appel de bienvenue~Welcome call~Willkommensanruf');
 SeedStep(Pl,2,7,'T','Envoyer la trousse~Send welcome kit~Willkommenspaket s'
   +'enden');
 SeedStep(Pl,3,30,'M','R@eunion de bilan~Review meeting~Auswertungsgespr@1ch');
 NewRow(tTP,RB2);SS(tTP,RB2,'NAME',T('Lettre de remerciement~Thank-you lette'
   +'r~Dankesbrief'));
 SS(tTP,RB2,'KIND','L');SS(tTP,RB2,'SUBJ',T('Merci~Thank you~Danke'));
 Id:=RowAdd(tTP,RB2);
 TXN:=0;
 TxAdd('<<DATE>>');TxAdd('');TxAdd('<<NAME>>');TxAdd('<<ADDR1>>');
 TxAdd('<<CITY>>, <<STATE>> <<ZIP>>');TxAdd('');
 TxAdd(T('Cher(e) <<CONTACT>>,~Dear <<CONTACT>>,~Sehr geehrte(r) <<CONTACT>>'
   +','));
 TxAdd('');
 TxAdd(T('Merci de votre confiance.~Thank you for your business.~Vielen Dank'
   +' f@3r Ihr Vertrauen.'));
 TxAdd('');TxAdd(T('Cordialement,~Sincerely,~Mit freundlichen Gr@3@7en,'));
 TxAdd('<<USER>>');
 TextSave('T',Id);
 SeedProd('MER-750','Merlot 750 ml',1850);SeedProd('CHA-750','Chardonnay 750'
   +' ml',1650);
 SeedProd('PIN-750','Pinot Noir 750 ml',2400);
 NewRow(tOR,RB2);SN(tOR,RB2,'ENTRY_ID',E1);SS(tOR,RB2,'ORDNO','SO-0001');
 SN(tOR,RB2,'OD',AddDays(SessDate,-10));SN(tOR,RB2,'TOTAL',24*1850+12*2400);
 SS(tOR,RB2,'STATUS',T('Exp@edi@ee~Shipped~Versandt'));
 Id:=RowAdd(tOR,RB2);
 SeedLine(Id,'Merlot 750 ml',24,1850);SeedLine(Id,'Pinot Noir 750 ml',12,2400);
 SeedMail(E4,'I','jcash@example.com','jnapoli@maximilien.example',
   'Demande de prix~Price request~Preisanfrage','Bonjour, pouvez-vous nous e'
   +'nvoyer vos prix ?~Hello, could you send us your prices?~Guten Tag, send'
   +'en Sie uns bitte Ihre Preise?');
 SeedMail(E1,'S','jnapoli@maximilien.example','escona@maximizer.com',
   'Confirmation de commande~Order confirmation~Auftragsbest@1tigung',
   'Votre commande SO-0001 est exp@edi@ee.~Your order SO-0001 has shipped.~I'
   +'hr Auftrag SO-0001 wurde versandt.');
 TblFlushAll;
End;

{ ====================================================================== }
{                 FORMULAIRES ET GRILLES GENERIQUES                      }
{ ====================================================================== }

Const
 MAXGC = 8;
 RH    = 14;

Type
 TGrid = Record
  X1,Y1,X2,Y2 : Integer;
  TI    : Integer;
  NC    : Integer;
  CF    : Array[1..MAXGC] Of Integer;
  CWd   : Array[1..MAXGC] Of Integer;
  CHd   : Array[1..MAXGC] Of String[20];
  Sl    : PLongArr;
  Cap   : LongInt;
  N     : LongInt;
  Top,Sel : LongInt;
  SortF : Integer;
  SortD : Boolean;
  Foc   : Boolean;
  Base  : String[200];
  HitCol: Integer;
  Marks : Boolean;
 End;

Var
 MgHook : Integer;

Function PrioName(V: LongInt): String;
Begin
 PrioName:=CodeName('PR',Chr(48+V));
End;

{ texte d'un champ pour l'affichage }
Function FmtFld(TI: Integer; B: PRec; F: Integer): String;
Var Key,FN: String; K: Integer; V: LongInt; S: String;
Begin
 FN:=Tb[TI]^.F[F].Nm;
 K:=FKind(TI,F,Key);
 If (FN='ENTRY_ID') Or (FN='OTHER_ID') Then Begin
  FmtFld:=EntryName(GetN(TI,B,F));Exit;
 End;
 If FN='ORD_ID' Then Begin FmtFld:=IntStr(GetN(TI,B,F));Exit;End;
 If FN='MINUTES' Then Begin
  V:=GetN(TI,B,F);FmtFld:=IntStr(V Div 60)+':'+Two(V Mod 60);Exit;
 End;
 If FN='PROB' Then Begin FmtFld:=IntStr(GetN(TI,B,F))+'%';Exit;End;
 Case K Of
  1: FmtFld:=IntStr(GetN(TI,B,F));
  2: If Tb[TI]^.F[F].Typ='D' Then FmtFld:=FmtDate(GetN(TI,B,F))
     Else FmtFld:=GetS(TI,B,F);
  3: FmtFld:=FmtMoney(GetN(TI,B,F));
  4: If GetN(TI,B,F)<>0 Then FmtFld:='*' Else FmtFld:='';
  6: If Tb[TI]^.F[F].Typ='C' Then Begin
      S:=GetS(TI,B,F);
      If S='' Then FmtFld:='' Else FmtFld:=CodeName(Key,S[1]);
     End Else FmtFld:=PrioName(GetN(TI,B,F));
  Else FmtFld:=GetS(TI,B,F);
 End;
End;

{ ---- selection d'une entree du carnet ---- }

Function PickEntryDlg: LongInt;
Var Q: String; I,Sel: Integer; Ids: Array[1..200] Of LongInt; N: Integer;
Begin
 PickEntryDlg:=0;
 Q:='';
 If Not InputBox(T('Rechercher une entr@ee~Find an entry~Eintrag suchen~Busc'
   +'ar entrada~Cerca voce'),
   T('Nom (ou partie du nom) :~Name (or part of it):~Name (oder Teil):~Nombr'
     +'e (o parte):~Nome (o parte):'),Q,30) Then Exit;
 If Not SqlRun('SELECT * FROM abentry WHERE name LIKE ''%'+Q+'%'' ORDER BY n'
   +'ame')
 Then Exit;
 PickN:=0;N:=0;
 For I:=1 To SqlN Do
  If (N<200) And RowGet(tAB,P1^[I],RB2) Then Begin
   Inc(N);Ids[N]:=GetN(tAB,RB2,1);
   PickAdd(SG(tAB,RB2,'NAME'));
  End;
 If N=0 Then Begin
  Info(T('Aucune entr@ee trouv@ee.~No entry found.~Kein Eintrag gefunden.~No'
    +' se encontr@o.~Nessuna voce trovata.'));
  Exit;
 End;
 Sel:=1;
 If PickList(T('Choisir une entr@ee~Choose an entry~Eintrag w@1hlen~Elegir e'
   +'ntrada~Scegli voce'),Sel) Then
  PickEntryDlg:=Ids[Sel];
End;

Function NormTime(Const S: String): String;
Var I,H,M,N: Integer; D: String;
Begin
 NormTime:='';
 D:='';
 For I:=1 To Length(S) Do If (S[I]>='0') And (S[I]<='9') Then D:=D+S[I];
 If D='' Then Exit;
 If Length(D)<=2 Then Begin H:=ValInt(D,0);M:=0;End
 Else Begin M:=ValInt(Copy(D,Length(D)-1,2),0);
   H:=ValInt(Copy(D,1,Length(D)-2),0);End;
 If (H>23) Or (M>59) Then Exit;
 NormTime:=Two(H)+':'+Two(M);
End;

{ ---- formulaire d'edition ---- }

Function FormEdit(TI: Integer; B: PRec; Const Title,Show,Hide: String): Boolean;
Var NF,I,Cur,Top,Vis,X1,Y1,X2,Y2,CPos,Sel2,W: Integer;
    FI: Array[1..MAXFLD] Of Integer;
    FK: Array[1..MAXFLD] Of Integer;
    FKey: Array[1..MAXFLD] Of String[8];
    FV: Array[1..MAXFLD] Of String[80];
    FId: Array[1..MAXFLD] Of LongInt;
    E: TEvent; Done,Ok,Redraw,Sel: Boolean; FN,Kc: String; Y: Integer;
    Id: LongInt; D: LongInt; S,Err: String; Dd: LongInt;
 Procedure Setup;
 Var F: Integer; Inc_: Boolean;
 Begin
  NF:=0;
  For F:=2 To Tb[TI]^.NF Do Begin
   FN:=Tb[TI]^.F[F].Nm;
   If Show<>'' Then Inc_:=Pos(','+FN+',',','+Show+',')>0
   Else Inc_:=(Pos(','+FN+',',','+Hide+',')=0) And
     Not ((FN[1]='U') And (Length(FN)>=2) And (FN[2]>='0') And (FN[2]<='9'));
   If Inc_ And (NF<MAXFLD) Then Begin
    Inc(NF);FI[NF]:=F;FK[NF]:=FKind(TI,F,Kc);FKey[NF]:=Kc;FId[NF]:=0;
    If (FN='ENTRY_ID') Or (FN='OTHER_ID') Then FK[NF]:=8;
    Case FK[NF] Of
     6: If Tb[TI]^.F[F].Typ='C' Then FV[NF]:=GetS(TI,B,F)
        Else FV[NF]:=IntStr(GetN(TI,B,F));
     4: FV[NF]:=IntStr(GetN(TI,B,F));
     8: Begin FId[NF]:=GetN(TI,B,F);FV[NF]:=EntryName(FId[NF]);End;
     1: FV[NF]:=IntStr(GetN(TI,B,F));
     Else FV[NF]:=FmtFld(TI,B,F);
    End;
   End;
  End;
 End;
 Function LKey(I: Integer; K: Word): Boolean;
 Var S: String;
 Begin
  S:=FV[I];
  LKey:=LineKey(S,Tb[TI]^.F[FI[I]].Sz,CPos,K,Sel);
  FV[I]:=Copy(S,1,80);
 End;
 Function ShowVal(I: Integer): String;
 Begin
  Case FK[I] Of
   6: If FV[I]='' Then ShowVal:='' Else ShowVal:=CodeName(FKey[I],FV[I][1]);
   4: If FV[I]='1' Then ShowVal:='[x]' Else ShowVal:='[ ]';
   Else ShowVal:=FV[I];
  End;
 End;
 Procedure StagePick(I: Integer);
 Var J: Integer;
 Begin
  If SqlRun('SELECT * FROM listv WHERE lst=''STAGE'' AND val='''+FV[I]+'''')
    Then
   If (SqlN>0) And RowGet(tLV,P1^[1],RB2) Then
    For J:=1 To NF Do If Tb[TI]^.F[FI[J]].Nm='PROB' Then
      FV[J]:=IntStr(NG(tLV,RB2,'EXTRA'));
 End;
 Procedure PickIt_(I: Integer);
 Var J,Sl: Integer; Cd: Char;
 Begin
  Sl:=1;
  Case FK[I] Of
   5: Begin
       LoadList(FKey[I]);
       For J:=1 To PickN Do If PickIt^[J]=FV[I] Then Sl:=J;
       If PickN=0 Then Exit;
       If PickList(FCap(Tb[TI]^.F[FI[I]].Nm),Sl) Then Begin
        FV[I]:=PickIt^[Sl];
        If FKey[I]='STAGE' Then StagePick(I);
       End;
      End;
   7: Begin
       LoadUsers;
       For J:=1 To PickN Do If PickIt^[J]=FV[I] Then Sl:=J;
       If PickN=0 Then Exit;
       If PickList(FCap(Tb[TI]^.F[FI[I]].Nm),Sl) Then FV[I]:=PickIt^[Sl];
      End;
   6: Begin
       PickN:=0;
       For J:=1 To CodeCount(FKey[I]) Do Begin
        Cd:=CodeAt(FKey[I],J);PickAdd(CodeName(FKey[I],Cd));
        If (FV[I]<>'') And (FV[I][1]=Cd) Then Sl:=J;
       End;
       If PickList(FCap(Tb[TI]^.F[FI[I]].Nm),Sl) Then
        FV[I]:=CodeAt(FKey[I],Sl);
      End;
   8: Begin
       Id:=PickEntryDlg;
       If Id>0 Then Begin FId[I]:=Id;FV[I]:=EntryName(Id);End;
      End;
  End;
 End;
 Function Store: Boolean;
 Var J: Integer; F: Integer; V: LongInt; Tm: String;
 Begin
  Store:=False;
  For J:=1 To NF Do Begin
   F:=FI[J];FN:=Tb[TI]^.F[F].Nm;
   Err:='';
   Case FK[J] Of
    1: Begin
        If (TrimStr(FV[J])<>'') And (ValInt(FV[J],-999999)=-999999) Then
         Err:=FCap(FN);
        SetN(TI,B,F,ValInt(FV[J],0));
       End;
    2: Begin
        If TrimStr(FV[J])='' Then Dd:=0
        Else If Not ParseDate(FV[J],Dd) Then Err:=FCap(FN);
        If Tb[TI]^.F[F].Typ='D' Then SetN(TI,B,F,Dd)
        Else If Dd=0 Then SetS(TI,B,F,'') Else SetS(TI,B,F,FmtDate(Dd));
       End;
    3: SetN(TI,B,F,ParseMoney(FV[J]));
    4: SetN(TI,B,F,ValInt(FV[J],0));
    8: SetN(TI,B,F,FId[J]);
    6: If Tb[TI]^.F[F].Typ='C' Then SetS(TI,B,F,FV[J])
       Else SetN(TI,B,F,ValInt(FV[J],2));
    Else Begin
     If (FN='AT') Or (FN='ET') Or (FN='NT') Then Begin
      Tm:=NormTime(FV[J]);
      If (Tm='') And (TrimStr(FV[J])<>'') Then Err:=FCap(FN);
      FV[J]:=Tm;
     End;
     If Tb[TI]^.F[F].Typ='C' Then SetS(TI,B,F,FV[J])
     Else SetN(TI,B,F,ValInt(FV[J],0));
    End;
   End;
   If Err<>'' Then Begin
    Info(T('Valeur invalide : ~Invalid value: ~Ung@3ltiger Wert: ~Valor no v'
      +'@alido: ~Valore non valido: ')+Err);
    Cur:=J;Exit;
   End;
  End;
  Store:=True;
 End;
Var Hh, FeFoc, A, St0: LongInt;
 { --- fiche de PM : une rangee par champ visible (etiquette, champ de
   saisie ou case a cocher, bouton de liste), barre de defilement --- }
 Procedure FeSave;
 Var R,J: Integer;
 Begin
  For R:=1 To FeRows Do Begin
   J:=Top+R-1;
   If (J>=1) And (J<=NF) And (FeEf[R]<>0) Then
    Case FK[J] Of
     4: If WinSendMsg(FeEf[R],BM_QUERYCHECK,0,0)<>0 Then FV[J]:='1' Else FV[J]:='0';
     6,8: ;
     Else FV[J]:=Copy(MxText(FeEf[R]),1,80);
    End;
  End;
 End;
 Procedure FeBuild;
 Var R,J,Y,X2,Wv,St: LongInt; Lb: String;
 Begin
  For R:=1 To FeRows Do Begin
   If FeLb[R]<>0 Then Dummy:=WinDestroyWindow(FeLb[R]);
   If FeEf[R]<>0 Then Dummy:=WinDestroyWindow(FeEf[R]);
   If FeBt[R]<>0 Then Dummy:=WinDestroyWindow(FeBt[R]);
   FeLb[R]:=0;FeEf[R]:=0;FeBt[R]:=0;
  End;
  FeTopG:=Top;
  If FeSb<>0 Then X2:=W-30 Else X2:=W-10;
  For R:=1 To FeRows Do Begin
   J:=Top+R-1;
   If J>NF Then Break;
   Y:=Hh-10-R*26;
   Lb:=FCap(Tb[TI]^.F[FI[J]].Nm);
   FeLb[R]:=WinCreateWindow(FeCl,WC_STATIC,OsZ(Copy(Lb,1,22)),WS_VISIBLE Or SS_TEXT Or DT_VCENTER,
     10,Y+2,180,20,FeCl,HWND_TOP,200+R,0,0);
   MxGray(FeLb[R]);
   If FK[J] In [5,6,7,8] Then Wv:=X2-196-34 Else Wv:=X2-196;
   Case FK[J] Of
    4: Begin
        FeEf[R]:=WinCreateWindow(FeCl,WC_BUTTON,OsZ(''),WS_VISIBLE Or WS_TABSTOP Or BS_AUTOCHECKBOX,
          196,Y+3,24,18,FeCl,HWND_TOP,220+R,0,0);
        Dummy:=WinSendMsg(FeEf[R],BM_SETCHECK,Ord(FV[J]='1'),0);
       End;
    Else Begin
     St:=WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN;
     If FK[J] In [6,8] Then St:=St Or ES_READONLY;
     FeEf[R]:=WinCreateWindow(FeCl,WC_ENTRYFIELD,0,St,196,Y+2,Wv,20,FeCl,HWND_TOP,220+R,0,0);
     If FK[J] In [6,8] Then Dummy:=WinSendMsg(FeEf[R],EM_SETTEXTLIMIT,80,0)
     Else Dummy:=WinSendMsg(FeEf[R],EM_SETTEXTLIMIT,Tb[TI]^.F[FI[J]].Sz,0);
     Dummy:=WinSetWindowText(FeEf[R],OsZ(ShowVal(J)));
    End;
   End;
   If FK[J] In [5,6,7,8] Then
    FeBt[R]:=WinCreateWindow(FeCl,WC_BUTTON,OsZ('...'),WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
      X2-30,Y+1,30,22,FeCl,HWND_TOP,240+R,0,0);
  End;
  FeBars;
 End;
 Procedure FeShow(J: Integer);
 Begin
  If J<1 Then J:=1;
  If J>NF Then J:=NF;
  If J<Top Then Top:=J;
  If J>=Top+FeRows Then Top:=J-FeRows+1;
  If Top<>FeTopG Then FeBuild;
  FeFoc:=FeEf[J-Top+1];
  If FeFoc=0 Then FeFoc:=FeBt[J-Top+1];
 End;

Begin
 FormEdit:=False;
 Setup;
 If NF=0 Then Exit;
 MxRegister;
 FeRows:=NF;If FeRows>MXF_ROWS Then FeRows:=MXF_ROWS;
 FeNF:=NF;
 W:=560;Hh:=10+FeRows*26+50;
 FeFr:=PmOpenBox('MXFORM',Title,W,Hh,FeCl);
 If FeFr=0 Then Exit;
 FillChar(FeLb,SizeOf(FeLb),0);FillChar(FeEf,SizeOf(FeEf),0);FillChar(FeBt,SizeOf(FeBt),0);
 FeSb:=0;
 If NF>FeRows Then
  FeSb:=WinCreateWindow(FeCl,WC_SCROLLBAR,0,WS_VISIBLE Or SBS_VERT,
    W-22,Hh-10-FeRows*26,16,FeRows*26,FeCl,HWND_TOP,ID_PVSB,0,0);
 St0:=WinCreateWindow(FeCl,WC_STATIC,OsZ('F4 = '+T('Liste~List~Liste~Lista~Lista')+'   F2 = OK'),
   WS_VISIBLE Or SS_TEXT Or DT_VCENTER,10,10,200,24,FeCl,HWND_TOP,199,0,0);
 MxGray(St0);
 FeOk:=WinCreateWindow(FeCl,WC_BUTTON,OsZ('OK'),WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
   W-196,8,88,26,FeCl,HWND_TOP,ID_POK,0,0);
 FeCan:=WinCreateWindow(FeCl,WC_BUTTON,OsZ(T('Annuler~Cancel~Abbrechen~Cancelar~Annulla')),
   WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,W-100,8,88,26,FeCl,HWND_TOP,ID_PCANCEL,0,0);
 Top:=1;FeTopG:=0;Ok:=False;
 FeBuild;
 FeFoc:=FeEf[1];If FeFoc=0 Then FeFoc:=FeBt[1];
 MxBegin(FeFr);
 Repeat
  A:=MxWait(FeFoc);
  Case A Of
   1: Begin
       FeSave;
       If Store Then Begin Ok:=True;A:=0;End
       Else Begin FeShow(Cur);A:=-1;End;
      End;
   2: A:=0;
   11..10+MXF_ROWS: Begin
       FeSave;
       Cur:=Top+A-11;
       PickIt_(Cur);
       FeTopG:=0;FeShow(Cur);
       FeFoc:=FeBt[Cur-Top+1];
       A:=-1;
      End;
   5001: Begin
       FeSave;
       If Top+FeRows<=NF Then Inc(Top);
       FeBuild;
       FeFoc:=FeEf[FeRows];If FeFoc=0 Then FeFoc:=FeBt[FeRows];
       A:=-1;
      End;
   6001: Begin
       FeSave;
       If Top>1 Then Dec(Top);
       FeBuild;
       FeFoc:=FeEf[1];If FeFoc=0 Then FeFoc:=FeBt[1];
       A:=-1;
      End;
   1001..1000+MAXFLD: Begin
       FeSave;
       Top:=A-1000;
       FeBuild;
       FeFoc:=FeEf[1];If FeFoc=0 Then FeFoc:=FeBt[1];
       A:=-1;
      End;
   Else A:=-1;
  End;
 Until A=0;
 MxEnd(FeFr);
 FormEdit:=Ok;
End;

{ ---- grilles ---- }

Procedure GridCols(Var G: TGrid; TI: Integer; Const Cols: String);
Var I,P: Integer; Tk,Nm: String; Wd: Integer; F: Integer;
Begin
 G.TI:=TI;G.NC:=0;G.SortF:=1;G.SortD:=False;
 Tk:='';
 For I:=1 To Length(Cols)+1 Do
  If (I>Length(Cols)) Or (Cols[I]=',') Then Begin
   P:=Pos(':',Tk);
   Nm:=Copy(Tk,1,P-1);Wd:=ValInt(Copy(Tk,P+1,5),80);
   F:=FldIndex(Tb[TI],Nm);
   If (F>0) And (G.NC<MAXGC) Then Begin
    Inc(G.NC);G.CF[G.NC]:=F;G.CWd[G.NC]:=Wd;G.CHd[G.NC]:=FCap(Nm);
   End;
   Tk:='';
  End Else Tk:=Tk+Cols[I];
End;

Procedure GridInit(Var G: TGrid; TI: Integer; Cap: LongInt; Const Cols: String);
Begin
 G.Cap:=Cap;G.N:=0;G.Top:=1;G.Sel:=1;
 G.Foc:=False;G.Marks:=False;G.Base:='';
 GetMem(G.Sl,Cap*SizeOf(LongInt));
 GridCols(G,TI,Cols);
End;

Procedure GridArea(Var G: TGrid; X1,Y1,X2,Y2: Integer);
Begin
 G.X1:=X1;G.Y1:=Y1;G.X2:=X2;G.Y2:=Y2;
End;

Function GridVis(Var G: TGrid): Integer;
Begin
 GridVis:=(G.Y2-G.Y1-16) Div RH;
End;

Function GridSelId(Var G: TGrid): LongInt;
Begin
 GridSelId:=0;
 If (G.N>=1) And (G.Sel>=1) And (G.Sel<=G.N) Then
  If RowGet(G.TI,G.Sl^[G.Sel],RB) Then GridSelId:=GetN(G.TI,RB,1);
End;

Function GridSelSlot(Var G: TGrid): LongInt;
Begin
 If (G.N>=1) And (G.Sel>=1) And (G.Sel<=G.N) Then GridSelSlot:=G.Sl^[G.Sel]
 Else GridSelSlot:=-1;
End;

Procedure GridReload(Var G: TGrid; Const Extra: String);
Var Id: LongInt; Q: String; I: LongInt; Ord: String;
Begin
 Id:=GridSelId(G);
 Q:=G.Base;
 Ord:=Tb[G.TI]^.F[G.SortF].Nm;
 If G.SortF<>1 Then Ord:=Ord+',id';
 Q:=Q+' ORDER BY '+Ord;
 If G.SortD Then Q:=Q+' DESC';
 G.N:=0;
 If SqlRun(Q) Then Begin
  G.N:=SqlN;
  If G.N>G.Cap Then G.N:=G.Cap;
  Move(P1^,G.Sl^,G.N*SizeOf(LongInt));
 End;
 If Id>0 Then Begin
  I:=RowFind(G.TI,Id);
  G.Sel:=1;
  { retrouve la selection par ID }
  For I:=1 To G.N Do
   If RowGet(G.TI,G.Sl^[I],RB) Then If GetN(G.TI,RB,1)=Id Then G.Sel:=I;
 End Else G.Sel:=1;
 If G.Sel>G.N Then G.Sel:=G.N;
 If G.Sel<1 Then G.Sel:=1;
 If G.Top>G.Sel Then G.Top:=G.Sel;
 If G.Top<1 Then G.Top:=1;
End;

Procedure GridDraw(Var G: TGrid);
Var I,J,X,Y,Vis,R,Cw,Tw: Integer; S: String; Hi: Boolean; Mk: Boolean;
Begin
 Vis:=GridVis(G);
 If G.Sel<G.Top Then G.Top:=G.Sel;
 If G.Sel>=G.Top+Vis Then G.Top:=G.Sel-Vis+1;
 If G.Top<1 Then G.Top:=1;
 Sunken(G.X1,G.Y1,G.X2,G.Y2,cWht);
 { en-tete }
 X:=G.X1+2;
 Bx(G.X1+2,G.Y1+2,G.X2-2,G.Y1+15,cLGr);
 Ln(G.X1+2,G.Y1+15,G.X2-2,G.Y1+15,cDGr);
 For J:=1 To G.NC Do Begin
  Cw:=G.CWd[J];
  If (X+Cw>G.X2-14) Or (J=G.NC) Then Cw:=G.X2-14-X;
  If Cw>8 Then Begin
   TxC(X+3,G.Y1+5,Cw-12,G.CHd[J],cBlk);
   If G.SortF=G.CF[J] Then
    If G.SortD Then Arw(X+Cw-9,G.Y1+8,2,cBlk) Else Arw(X+Cw-9,G.Y1+8,1,cBlk);
   Ln(X+Cw-1,G.Y1+3,X+Cw-1,G.Y1+14,cDGr);
  End;
  X:=X+Cw;
 End;
 For I:=0 To Vis-1 Do Begin
  R:=G.Top+I;
  Y:=G.Y1+17+I*RH;
  If R<=G.N Then Begin
   Hi:=R=G.Sel;
   If Hi Then Begin
    If G.Foc Then Bx(G.X1+2,Y,G.X2-15,Y+RH-1,cNavy)
    Else Bx(G.X1+2,Y,G.X2-15,Y+RH-1,cDGr);
   End;
   If RowGet(G.TI,G.Sl^[R],RB) Then Begin
    Mk:=G.Marks And (MarkIdx(GetN(G.TI,RB,1))>0);
    X:=G.X1+2;
    For J:=1 To G.NC Do Begin
     Cw:=G.CWd[J];
     If (X+Cw>G.X2-14) Or (J=G.NC) Then Cw:=G.X2-14-X;
     If Cw>8 Then Begin
      S:=FmtFld(G.TI,RB,G.CF[J]);
      If (J=1) And Mk Then S:=#4+S;
      If Hi Then TxC(X+3,Y+3,Cw-6,S,cWht)
      Else If Mk Then TxC(X+3,Y+3,Cw-6,S,cRed)
      Else TxC(X+3,Y+3,Cw-6,S,cBlk);
     End;
     X:=X+Cw;
    End;
   End;
  End;
 End;
 { barre de defilement }
 Bx(G.X2-14,G.Y1+2,G.X2-2,G.Y2-2,cLGr);
 Raised(G.X2-14,G.Y1+2,G.X2-2,G.Y1+14);Arw(G.X2-8,G.Y1+8,1,cBlk);
 Raised(G.X2-14,G.Y2-14,G.X2-2,G.Y2-2);Arw(G.X2-8,G.Y2-8,2,cBlk);
 If G.N>1 Then Begin
  Y:=G.Y1+16+Integer(((G.Y2-G.Y1-44)*(G.Sel-1)) Div (G.N-1));
  Raised(G.X2-14,Y,G.X2-2,Y+10);
 End;
 If G.Foc Then Rc(G.X1-1,G.Y1-1,G.X2+1,G.Y2+1,cLBl);
End;

{ retourne True si la touche a ete consommee }
Function GridKey(Var G: TGrid; K: Word): Boolean;
Var Vis: Integer;
Begin
 GridKey:=True;
 Vis:=GridVis(G);
 Case K Of
  K_UP: If G.Sel>1 Then Dec(G.Sel);
  K_DOWN: If G.Sel<G.N Then Inc(G.Sel);
  K_PGUP: G.Sel:=Max2(1,G.Sel-Vis);
  K_PGDN: G.Sel:=Min2(Max2(1,G.N),G.Sel+Vis);
  K_HOME: G.Sel:=1;
  K_END: G.Sel:=Max2(1,G.N);
  Else GridKey:=False;
 End;
End;

{ 0 rien, 1 ligne choisie, 2 en-tete (G.HitCol), 3 defilement }
Function GridClick(Var G: TGrid; X,Y: LongInt): Integer;
Var R,J,CX,Vis: Integer;
Begin
 GridClick:=0;
 If Not InBox(X,Y,G.X1,G.Y1,G.X2,G.Y2) Then Exit;
 Vis:=GridVis(G);
 If X>=G.X2-14 Then Begin
  If Y<G.Y1+16 Then G.Sel:=Max2(1,G.Sel-1)
  Else If Y>G.Y2-16 Then G.Sel:=Min2(Max2(1,G.N),G.Sel+1)
  Else If G.N>1 Then
   G.Sel:=1+((Y-G.Y1-16)*(G.N-1)) Div (G.Y2-G.Y1-32);
  If G.Sel<1 Then G.Sel:=1;
  If G.Sel>G.N Then G.Sel:=Max2(1,G.N);
  GridClick:=3;Exit;
 End;
 If Y<G.Y1+16 Then Begin
  CX:=G.X1+2;
  For J:=1 To G.NC Do Begin
   If (X>=CX) And ((X<CX+G.CWd[J]) Or (J=G.NC)) Then Begin
    If G.SortF=G.CF[J] Then G.SortD:=Not G.SortD Else Begin
     G.SortF:=G.CF[J];G.SortD:=False;End;
    G.HitCol:=J;GridClick:=2;
   End;
   CX:=CX+G.CWd[J];
  End;
  Exit;
 End;
 R:=G.Top+(Y-G.Y1-17) Div RH;
 If (R>=1) And (R<=G.N) Then Begin G.Sel:=R;GridClick:=1;End;
End;

{ ---- gestionnaire generique d'une table ---- }

Function PairsWhere(TI: Integer; Const Pairs: String): String;
Var I,P,F: Integer; Tk,Nm,Vl,W: String;
Begin
 W:='';Tk:='';
 For I:=1 To Length(Pairs)+1 Do
  If (I>Length(Pairs)) Or (Pairs[I]=';') Then Begin
   P:=Pos('=',Tk);
   If P>0 Then Begin
    Nm:=Copy(Tk,1,P-1);Vl:=Copy(Tk,P+1,60);
    F:=FldIndex(Tb[TI],Nm);
    If W<>'' Then W:=W+' AND ';
    If (F>0) And (Tb[TI]^.F[F].Typ='C') Then W:=W+Nm+'='''+Vl+''''
    Else W:=W+Nm+'='+Vl;
   End;
   Tk:='';
  End Else Tk:=Tk+Pairs[I];
 PairsWhere:=W;
End;

Procedure PairsApply(TI: Integer; B: PRec; Const Pairs: String);
Var I,P,F: Integer; Tk,Nm,Vl: String;
Begin
 Tk:='';
 For I:=1 To Length(Pairs)+1 Do
  If (I>Length(Pairs)) Or (Pairs[I]=';') Then Begin
   P:=Pos('=',Tk);
   If P>0 Then Begin
    Nm:=Copy(Tk,1,P-1);Vl:=Copy(Tk,P+1,60);
    F:=FldIndex(Tb[TI],Nm);
    If F>0 Then SetS(TI,B,F,Vl);
   End;
   Tk:='';
  End Else Tk:=Tk+Pairs[I];
End;

Function PairsHide(Const Pairs: String): String;
Var I,P: Integer; Tk,R: String;
Begin
 R:=',ID';Tk:='';
 For I:=1 To Length(Pairs)+1 Do
  If (I>Length(Pairs)) Or (Pairs[I]=';') Then Begin
   P:=Pos('=',Tk);
   If P>0 Then R:=R+','+Copy(Tk,1,P-1);
   Tk:='';
  End Else Tk:=Tk+Pairs[I];
 PairsHide:=R+',';
End;

Procedure RecalcOrder(OrdId: LongInt);
Var I: Integer; Tot: LongInt; S: LongInt;
Begin
 Tot:=0;
 If SqlRun('SELECT * FROM orderln WHERE ord_id='+IntStr(OrdId)) Then
  For I:=1 To SqlN Do
   If RowGet(tOL,P1^[I],RB2) Then Tot:=Tot+NG(tOL,RB2,'QTY')*NG(tOL,RB2,
     'PRICE');
 S:=RowFind(tOR,OrdId);
 If (S>=0) And RowGet(tOR,S,RB2) Then Begin
  SN(tOR,RB2,'TOTAL',Tot);
  If RowPut(tOR,S,RB2) Then ;
 End;
End;

Procedure ManageTableD(TI: Integer; Const Title,Pairs,Cols: String);
Var G: TGrid; E: TEvent; Done,Redraw: Boolean; X1,Y1,X2,Y2,R: Integer;
    S: LongInt; Wh: String; Id: LongInt; Hd: String;
 Procedure Reload;
 Begin
  G.Base:='SELECT * FROM '+Tb[TI]^.Nm;
  Wh:=PairsWhere(TI,Pairs);
  If Wh<>'' Then G.Base:=G.Base+' WHERE '+Wh;
  GridReload(G,'');
 End;
 Procedure Hook;
 Begin
  TblFlush(TI);
  If MgHook=1 Then RecalcOrder(ValInt(Copy(Pairs,Pos('=',Pairs)+1,12),0));
  If MgHook=2 Then UdfLoad;
 End;
 Procedure DoNew;
 Begin
  NewRow(TI,RBF);
  PairsApply(TI,RBF,Pairs);
  If FormEdit(TI,RBF,Title,'',Hd) Then Begin
   If RowAdd(TI,RBF)=0 Then Info(DbErr);
   Hook;Reload;
  End;
 End;
 Procedure DoEdit;
 Begin
  S:=GridSelSlot(G);
  If (S>=0) And RowGet(TI,S,RBF) Then
   If FormEdit(TI,RBF,Title,'',Hd) Then Begin
    If RowPut(TI,S,RBF) Then ;
    Hook;Reload;
   End;
 End;
 Procedure DoDel;
 Begin
  S:=GridSelSlot(G);
  If S>=0 Then
   If MsgBox(T('Supprimer cet enregistrement ?~Delete this record?~Diesen Ei'
     +'ntrag l@3schen?'),1)=1 Then Begin
    RowDel(TI,S);Hook;Reload;
   End;
 End;
Begin
 Hd:=PairsHide(Pairs);
 X1:=40;Y1:=50;X2:=SCR_W-41;Y2:=SCR_H-50;
 GridInit(G,TI,2000,Cols);
 GridArea(G,X1+10,Y1+28,X2-10,Y2-46);
 G.Foc:=True;
 Reload;
 Backdrop;
 Done:=False;Redraw:=True;
 Repeat
  If Redraw Then Begin
   DlgFrame(X1,Y1,X2,Y2,Title);
   GridDraw(G);
   Btn(X1+10,Y2-36,X1+100,Y2-14,T('&Nouveau~&New~&Neu~&Nuevo~&Nuovo'),False);
   Btn(X1+110,Y2-36,X1+210,Y2-14,T('&Modifier~&Edit~&Bearbeiten~&Editar~&Mod'
     +'ifica'),False);
   Btn(X1+220,Y2-36,X1+320,Y2-14,T('&Supprimer~&Delete~&L@3schen~&Eliminar~&'
     +'Elimina'),False);
   Btn(X2-110,Y2-36,X2-10,Y2-14,T('&Fermer~&Close~&Schlie@7en~&Cerrar~&Chiud'
     +'i'),True);
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Redraw:=True;
   If Not GridKey(G,E.Key) Then Case E.Key Of
    K_ESC: Done:=True;
    K_INS: Begin DoNew;Redraw:=True;End;
    K_ENTER: Begin DoEdit;Redraw:=True;End;
    K_DEL: Begin DoDel;Redraw:=True;End;
    Else Begin
     Case UpCase(Chr(E.Key And 255)) Of
      'N': DoNew;
      'M': DoEdit;
      'S': DoDel;
      'F': Done:=True;
      Else Redraw:=False;
     End;
    End;
   End;
  End Else If E.Kind=2 Then Begin
   Redraw:=True;
   R:=GridClick(G,E.X,E.Y);
   If R=2 Then GridReload(G,'')
   Else If (R=1) And IsDouble(E.X,E.Y) Then DoEdit
   Else If R=0 Then Begin
    If InBox(E.X,E.Y,X1+10,Y2-36,X1+100,Y2-14) Then DoNew
    Else If InBox(E.X,E.Y,X1+110,Y2-36,X1+210,Y2-14) Then DoEdit
    Else If InBox(E.X,E.Y,X1+220,Y2-36,X1+320,Y2-14) Then DoDel
    Else If InBox(E.X,E.Y,X2-110,Y2-36,X2-10,Y2-14) Then Done:=True
    Else If InBox(E.X,E.Y,X2-19,Y1+5,X2-5,Y1+17) Then Done:=True
    Else Redraw:=False;
   End;
  End;
 Until Done;
 FreeMem(G.Sl,G.Cap*SizeOf(LongInt));
End;
Procedure ManageTable(TI: Integer; Const Title,Pairs,Cols: String);
Begin
 MxCatWant:=True;ManageTableD(TI,Title,Pairs,Cols);MxCatDone;
End;

{ ====================================================================== }
{                       INTERFACE PRINCIPALE                             }
{ ====================================================================== }

Const
 TOOL_Y  = 36;
 WORK_Y  = 62;
 NAV_W   = 124;
 CX1     = 127;
 NTOOL   = 17;
 NMOD    = 9;

Var
 STAT_Y,CX2,AB_Y2,PANE_Y,BODY_Y,BODY_Y2,LW,Mid2,CalW,CalH : Integer;
 WdPanel  : Integer;
 LibMode  : Integer;
 LibCat   : String[20];
 NLibIds  : Integer;
 LibIds   : Array[1..200] Of LongInt;
 RBE      : PRec;
 Modu     : Integer;
 Foc      : Integer;
 GMain,GSubL,GSubR : TGrid;
 GW       : Array[1..4] Of TGrid;
 TabL,TabR: Integer;
 CurId    : LongInt;
 Recent   : Array[1..5] Of LongInt;
 MenuOpen,MenuHi : Integer;
 ShowFilter : Integer;
 FilterSql  : String[200];
 FilterName : String[40];
 FiltIds    : Array[1..400] Of LongInt;
 NFilt      : Integer;
 NoteType   : String[16];
 NotePer    : Integer;
 HotMode    : Integer;
 CalDate    : LongInt;
 CalCnt     : Array[1..31] Of Integer;
 MailFold   : Char;
 MT         : Array[1..NMENU] Of String[24];
 MLb        : Array[1..NMENU,1..20] Of String[44];
 MCm        : Array[1..NMENU,1..20] Of Integer;
 MCnt       : Array[1..NMENU] Of Integer;
 TbX        : Array[1..NTOOL] Of Integer;
 TbCmd      : Array[1..NTOOL] Of Integer;
 TbIcon     : Array[1..NTOOL] Of Integer;
 TbTip      : Array[1..NTOOL] Of String[40];
 TipIdx     : Integer;

Procedure DoCmd(Cm: Integer); Forward;

{ ---- icones 16x16 ---- }

Procedure DrawIcon(Id,X,Y: Integer);
Begin
 SetLineStyle(SolidLn,0,1);
 Case Id Of
  1: Begin Bx(X+1,Y+4,X+14,Y+13,cYel);Rc(X+1,Y+4,X+14,Y+13,cBlk);
      Bx(X+1,Y+2,X+6,Y+4,cYel);Ln(X+9,Y+6,X+9,Y+11,cRed);
        Ln(X+6,Y+8,X+12,Y+8,cRed);End;
  2: Begin Bx(X+1,Y+3,X+14,Y+12,cWht);Rc(X+1,Y+3,X+14,Y+12,cBlk);
      Ln(X+1,Y+3,X+7,Y+8,cBlk);Ln(X+14,Y+3,X+8,Y+8,cBlk);End;
  3: Begin Bx(X+2,Y+1,X+12,Y+14,cYel);Rc(X+2,Y+1,X+12,Y+14,cBlk);
      Ln(X+4,Y+5,X+10,Y+5,cDGr);Ln(X+4,Y+8,X+10,Y+8,cDGr);
        Ln(X+4,Y+11,X+8,Y+11,cDGr);End;
  4: Begin Bx(X+1,Y+2,X+14,Y+14,cWht);Rc(X+1,Y+2,X+14,Y+14,cBlk);
      Bx(X+1,Y+2,X+14,Y+5,cLRd);Ln(X+4,Y,X+4,Y+3,cBlk);Ln(X+11,Y,X+11,Y+3,cBlk);
      Bx(X+4,Y+8,X+6,Y+10,cNavy);Bx(X+8,Y+8,X+10,Y+10,cNavy);End;
  5: Begin Bx(X+1,Y+1,X+13,Y+14,cWht);Rc(X+1,Y+1,X+13,Y+14,cBlk);
      Ln(X+3,Y+6,X+5,Y+9,cGrn);Ln(X+5,Y+9,X+10,Y+3,cGrn);
      Ln(X+4,Y+12,X+11,Y+12,cDGr);End;
  6: Begin Bx(X+1,Y+4,X+14,Y+8,cNavy);Bx(X+3,Y+8,X+6,Y+13,cNavy);
      Bx(X+9,Y+8,X+12,Y+13,cNavy);Bx(X+5,Y+2,X+10,Y+4,cNavy);End;
  7: Begin Bx(X+2,Y+2,X+13,Y+13,cYel);Rc(X+2,Y+2,X+13,Y+13,cBrn);
      Tx_(X+5,Y+4,'$',cBlk);End;
  8: Begin Bx(X+1,Y+2,X+12,Y+14,cWht);Rc(X+1,Y+2,X+12,Y+14,cBlk);
      Ln(X+3,Y+5,X+10,Y+5,cBlk);Ln(X+3,Y+8,X+10,Y+8,cBlk);
        Ln(X+3,Y+11,X+10,Y+11,cBlk);
      Ln(X+9,Y+10,X+14,Y+12,cRed);End;
  9: Begin Bx(X+2,Y+2,X+13,Y+13,cWht);Rc(X+2,Y+2,X+13,Y+13,cBlk);
      Ln(X+7,Y+4,X+7,Y+8,cBlk);Ln(X+7,Y+8,X+10,Y+10,cRed);End;
  10: Begin Rc(X+2,Y+2,X+9,Y+9,cNavy);Rc(X+3,Y+3,X+8,Y+8,cNavy);
      Ln(X+9,Y+9,X+14,Y+14,cBlk);Ln(X+10,Y+9,X+14,Y+13,cBlk);End;
  11: Begin Bx(X+2,Y+8,X+5,Y+14,cLBl);Bx(X+6,Y+4,X+9,Y+14,cLRd);
      Bx(X+10,Y+6,X+13,Y+14,cLGn);Ln(X+1,Y+14,X+14,Y+14,cBlk);End;
  12: Begin Bx(X+2,Y+1,X+12,Y+14,cWht);Rc(X+2,Y+1,X+12,Y+14,cBlk);
      Ln(X+4,Y+4,X+10,Y+4,cDGr);Ln(X+4,Y+7,X+10,Y+7,cDGr);
        Ln(X+4,Y+10,X+10,Y+10,cDGr);End;
  13: Begin Ln(X+3,Y+3,X+12,Y+12,cRed);Ln(X+4,Y+3,X+13,Y+12,cRed);
      Ln(X+12,Y+3,X+3,Y+12,cRed);Ln(X+13,Y+3,X+4,Y+12,cRed);End;
  14: Begin Ln(X+3,Y+12,X+12,Y+3,cBrn);Ln(X+4,Y+12,X+13,Y+3,cBrn);
      Ln(X+2,Y+13,X+4,Y+12,cBlk);End;
  15: Begin Rc(X+3,Y+3,X+12,Y+12,cBlk);Ln(X+5,Y+8,X+7,Y+11,cGrn);
      Ln(X+7,Y+11,X+11,Y+4,cGrn);End;
  { icones de modules }
  20: Begin Bx(X+2,Y+2,X+13,Y+13,cYel);Rc(X+2,Y+2,X+13,Y+13,cBrn);
      Ln(X+7,Y+4,X+7,Y+8,cBlk);Ln(X+7,Y+8,X+10,Y+8,cBlk);End;
  21: Begin Bx(X+3,Y+1,X+13,Y+14,cLBl);Rc(X+3,Y+1,X+13,Y+14,cNavy);
      Bx(X+1,Y+3,X+3,Y+6,cNavy);Bx(X+1,Y+8,X+3,Y+11,cNavy);
      Ln(X+6,Y+5,X+11,Y+5,cWht);Ln(X+6,Y+8,X+11,Y+8,cWht);End;
  22: Begin Bx(X+2,Y+3,X+13,Y+12,cYel);Rc(X+2,Y+3,X+13,Y+12,cBrn);
      Ln(X+4,Y+10,X+7,Y+6,cGrn);Ln(X+7,Y+6,X+11,Y+9,cGrn);End;
  23: Begin Bx(X+4,Y+6,X+11,Y+14,cLRd);Bx(X+6,Y+3,X+9,Y+7,cYel);
      Ln(X+7,Y+1,X+7,Y+4,cYel);End;
  24: DrawIcon(4,X,Y);
  25: DrawIcon(2,X,Y);
  26: Begin Bx(X+1,Y+3,X+4,Y+14,cRed);Bx(X+5,Y+2,X+8,Y+14,cLBl);
      Bx(X+9,Y+4,X+13,Y+14,cGrn);Ln(X+1,Y+14,X+14,Y+14,cBlk);End;
  27: Begin Bx(X+5,Y+2,X+10,Y+7,cBrn);Bx(X+3,Y+8,X+12,Y+14,cNavy);End;
  28: Begin Rc(X+2,Y+5,X+13,Y+11,cBlk);Bx(X+3,Y+6,X+12,Y+10,cLCy);
      Ln(X+1,Y+3,X+3,Y+5,cBlk);Bx(X+4,Y+12,X+6,Y+14,cBlk);
        Bx(X+10,Y+12,X+12,Y+14,cBlk);End;
 End;
End;

{ ---- menus (style SIMPLY) ---- }

Procedure MAdd(M: Integer; Const Lb: String; Cm: Integer);
Begin
 Inc(MCnt[M]);
 MLb[M,MCnt[M]]:=Lb;
 MCm[M,MCnt[M]]:=Cm;
End;

Procedure BuildMenus;
Begin
 FillChar(MCnt,SizeOf(MCnt),0);
 MT[1]:=T('&Fichier~&File~&Datei~&Archivo~&File');
 MT[2]:=T('&Edition~&Edit~&Bearbeiten~&Edici@on~&Modifica');
 MT[3]:=T('&Affichage~&View~&Ansicht~&Ver~&Visualizza');
 MT[4]:=T('Re&chercher~&Search~&Suchen~&Buscar~C&erca');
 MT[5]:=T('Ac&tions~A&ctions~A&ktionen~A&cciones~A&zioni');
 MT[6]:=T('&Outils~&Tools~&Extras~&Herramientas~&Strumenti');
 MT[7]:=T('&Rapports~&Reports~Be&richte~&Informes~Rap&porti');
 MT[8]:=T('Co&nfig.~Set&up~E&instellungen~Con&figuraci@on~&Impostazioni');
 MT[9]:=T('Ai&de~&Help~&Hilfe~Ay&uda~&Aiuto');
 MAdd(1,T('Nouvelle entr@ee...|Ctrl+N~New entry...|Ctrl+N~Neuer Eintrag...|S'
   +'trg+N'),1);
 MAdd(1,T('Changer d''utilisateur...~Change user...~Benutzer wechseln...'),2);
 MAdd(1,'-',0);
 MAdd(1,T('Importer (CSV)...~Import (CSV)...~Import (CSV)...~Importar (CSV).'
   +'..~Importa (CSV)...'),3);
 MAdd(1,T('Exporter (CSV)...~Export (CSV)...~Export (CSV)...~Exportar (CSV).'
   +'..~Esporta (CSV)...'),4);
 MAdd(1,T('Copie de s@ecurit@e...~Backup...~Sicherung...~Copia de seguridad.'
   +'..~Copia di sicurezza...'),5);
 MAdd(1,T('Restaurer...~Restore...~Wiederherstellen...~Restaurar...~Ripristi'
   +'na...'),6);
 MAdd(1,'-',0);
 MAdd(1,T('Imprimer la liste~Print list~Liste drucken~Imprimir lista~Stampa '
   +'elenco'),7);
 MAdd(1,'-',0);
 MAdd(1,T('Quitter|Alt+X~Exit|Alt+X~Beenden|Alt+X~Salir|Alt+X~Esci|Alt+X'),8);
 MAdd(2,T('Modifier|Entr@ee~Edit|Enter~Bearbeiten|Enter~Editar|Enter~Modific'
   +'a|Invio'),10);
 MAdd(2,T('Nouveau|Ins~New|Ins~Neu|Einfg~Nuevo|Ins~Nuovo|Ins'),12);
 MAdd(2,T('Supprimer|Suppr~Delete|Del~L@3schen|Entf~Eliminar|Supr~Elimina|Ca'
   +'nc'),11);
 MAdd(2,'-',0);
 MAdd(2,T('Dupliquer l''entr@ee~Duplicate entry~Eintrag duplizieren~Duplicar'
   +' entrada~Duplica voce'),13);
 MAdd(2,T('Marquer / d@emarquer|Espace~Mark / unmark|Space~Markieren|Leer'),14);
 MAdd(2,T('Tout marquer~Mark all~Alle markieren~Marcar todo~Segna tutto'),15);
 MAdd(2,T('Tout d@emarquer~Unmark all~Alle demarkieren~Desmarcar todo~Desele'
   +'ziona tutto'),16);
 MAdd(2,'-',0);
 MAdd(2,T('Copier|Ctrl+C~Copy|Ctrl+C~Kopieren|Strg+C~Copiar|Ctrl+C~Copia|Ctr'
   +'l+C'),120);
 MAdd(2,T('Coller|Ctrl+V~Paste|Ctrl+V~Einf@3gen|Strg+V~Pegar|Ctrl+V~Incolla|'
   +'Ctrl+V'),121);
 MAdd(2,'-',0);
 MAdd(2,T('Nouveau contact~New contact~Neuer Kontakt~Nuevo contacto~Nuovo co'
   +'ntatto'),17);
 MAdd(2,T('Nouvelle opportunit@e~New opportunity~Neue Verkaufschance~Nueva o'
   +'portunidad~Nuova opportunit@q'),66);
 MAdd(3,T('Mon jour de travail~My Work Day~Mein Arbeitstag~Mi d@ia de trabaj'
   +'o~La mia giornata'),20);
 MAdd(3,T('Carnet d''adresses~Address Book~Adressbuch~Libreta de direcciones'
   +'~Rubrica|F6'),21);
 MAdd(3,T('Opportunit@es~Opportunities~Verkaufschancen~Oportunidades~Opportu'
   +'nit@q'),22);
 MAdd(3,T('Hotlist~Hotlist~Hotlist~Hotlist~Hotlist'),23);
 MAdd(3,T('Calendrier~Calendar~Kalender~Calendario~Calendario'),24);
 MAdd(3,T('Courriel~Email~E-Mail~Correo~E-mail'),25);
 MAdd(3,T('Biblioth@eque de la soci@et@e~Company Library~Firmenbibliothek'),26);
 MAdd(3,T('Personnel~Personal~Pers@2nlich~Personal~Personale'),27);
 MAdd(3,T('OrderDesk~OrderDesk~OrderDesk~OrderDesk~OrderDesk'),28);
 MAdd(3,'-',0);
 MAdd(3,T('Afficher : tout / soci@et@es / individus...~Show: all / companies'
   +' / individuals...~Anzeige: alle / Firmen / Personen...'),33);
 MAdd(3,T('Actualiser|F5~Refresh|F5~Aktualisieren|F5~Actualizar|F5~Aggiorna|'
   +'F5'),29);
 MAdd(3,T('Barre d''outils~Toolbar~Symbolleiste~Barra de herramientas~Barra '
   +'strumenti'),30);
 MAdd(3,T('Barre d''@etat~Status bar~Statusleiste~Barra de estado~Barra di s'
   +'tato'),31);
 MAdd(4,T('Rechercher un nom...|Ctrl+F~Find a name...|Ctrl+F~Namen suchen...'
   +'|Strg+F'),40);
 MAdd(4,T('Recherche avanc@ee...~Advanced search...~Erweiterte Suche...~B@3s'
   +'queda avanzada...~Ricerca avanzata...'),41);
 MAdd(4,T('Rechercher dans les notes...~Search notes...~Notizen durchsuchen.'
   +'..'),42);
 MAdd(4,T('Requ@etes enregistr@ees...~Saved queries...~Gespeicherte Abfragen'
   +'...'),43);
 MAdd(4,T('Enregistrer la recherche...~Save search...~Suche speichern...'),44);
 MAdd(4,T('Tout afficher~Show all~Alle anzeigen~Mostrar todo~Mostra tutto'),45);
 MAdd(4,T('Trouver les doublons~Find duplicates~Duplikate suchen~Buscar dupl'
   +'icados~Trova duplicati'),46);
 MAdd(4,T('Aller @a une date (calendrier)...~Go to date (calendar)...~Gehe z'
   +'u Datum...'),47);
 MAdd(5,T('Courriel...~Email...~E-Mail...~Correo...~E-mail...'),50);
 MAdd(5,T('Note...~Note...~Notiz...~Nota...~Nota...'),51);
 MAdd(5,T('Lettre...~Letter...~Brief...~Carta...~Lettera...'),52);
 MAdd(5,T('T@el@copie...~Fax...~Fax...~Fax...~Fax...'),53);
 MAdd(5,T('Document...~Document...~Dokument...~Documento...~Documento...'),54);
 MAdd(5,'-',0);
 MAdd(5,T('Passer un appel...~Make a call...~Anruf t@etigen...~Hacer llamada'
   +'...~Fai chiamata...'),55);
 MAdd(5,T('Recevoir un appel...~Receive a call...~Anruf empfangen...~Recibir'
   +' llamada...~Ricevi chiamata...'),56);
 MAdd(5,T('R@eunion...~Meeting...~Besprechung...~Reuni@on...~Riunione...'),57);
 MAdd(5,T('@A faire...~To-do...~Aufgabe...~Tarea...~Da fare...'),58);
 MAdd(5,T('Appel t@el@ephonique (rdv)...~Phone call (appt)...~Anruf (Termin)'
   +'...'),59);
 MAdd(5,T('Plan d''action...~Action plan...~Aktionsplan...~Plan de acci@on..'
   +'.~Piano d''azione...'),60);
 MAdd(5,'-',0);
 MAdd(5,T('Ins@erer un fichier...~Insert a file...~Datei einf@3gen...~Insert'
   +'ar archivo...~Inserisci file...'),61);
 MAdd(5,T('Ins@erer un hyperlien...~Insert a hyperlink...~Hyperlink einf@3ge'
   +'n...~Insertar hiperv@inculo...~Inserisci collegamento...'),62);
 MAdd(5,T('Imprimer une enveloppe~Print an envelope~Umschlag drucken~Imprimi'
   +'r sobre~Stampa busta'),63);
 MAdd(5,T('Imprimer une @etiquette~Print a label~Etikett drucken~Imprimir et'
   +'iqueta~Stampa etichetta'),64);
 MAdd(5,T('Chronom@etrer une t@qche...~Time a task...~Aufgabe zeiten...'),65);
 MAdd(6,T('Publipostage...~Mail merge...~Serienbrief...~Combinar corresponde'
   +'ncia...~Stampa unione...'),70);
 MAdd(6,T('Console SQL...~SQL console...~SQL-Konsole...~Consola SQL...~Conso'
   +'le SQL...'),71);
 MAdd(6,T('Calculatrice...~Calculator...~Rechner...~Calculadora...~Calcolatr'
   +'ice...'),72);
 MAdd(6,T('V@erifier les tables~Check tables~Tabellen pr@3fen~Verificar tabl'
   +'as~Verifica tabelle'),73);
 MAdd(6,T('R@eparer les index~Repair indexes~Indizes reparieren~Reparar @ind'
   +'ices~Ripara indici'),74);
 MAdd(6,T('Informations sur la base~Database information~Datenbankinfo~Infor'
   +'maci@on de la base~Informazioni database'),75);
 MAdd(7,T('Liste du carnet d''adresses~Address book list~Adressbuchliste'),80);
 MAdd(7,T('Liste des contacts~Contacts list~Kontaktliste~Lista de contactos~'
   +'Elenco contatti'),81);
 MAdd(7,T('Liste t@el@ephonique~Phone list~Telefonliste~Lista telef@onica~El'
   +'enco telefonico'),82);
 MAdd(7,T('Opportunit@es~Opportunities~Verkaufschancen~Oportunidades~Opportu'
   +'nit@q'),83);
 MAdd(7,T('Entonnoir des ventes (@etapes)~Sales pipeline (stages)~Verkaufstr'
   +'ichter'),84);
 MAdd(7,T('Pr@evisions par mois~Forecast by month~Prognose pro Monat~Previsi'
   +'@on mensual~Previsione mensile'),85);
 MAdd(7,T('Notes de l''entr@ee~Entry notes~Eintragsnotizen~Notas de la entra'
   +'da~Note della voce'),86);
 MAdd(7,T('Activit@es (Hotlist)~Activities (Hotlist)~Aktivit@1ten~Actividade'
   +'s~Attivit@q'),87);
 MAdd(7,T('Agenda de la semaine~Weekly agenda~Wochenagenda~Agenda semanal~Ag'
   +'enda settimanale'),88);
 MAdd(7,T('Temps et facturation~Time and billing~Zeit und Abrechnung~Tiempo '
   +'y facturaci@on~Tempo e fatturazione'),89);
 MAdd(7,T('Commandes~Orders~Auftr@1ge~Pedidos~Ordini'),90);
 MAdd(7,T('Entr@ees par statut~Entries by status~Eintr@1ge nach Status~Entra'
   +'das por estado~Voci per stato'),91);
 MAdd(7,T('@Etiquettes d''adresse~Mailing labels~Adressetiketten~Etiquetas~E'
   +'tichette'),92);
 MAdd(8,T('Utilisateurs...~Users...~Benutzer...~Usuarios...~Utenti...'),100);
 MAdd(8,T('Champs d@efinis par l''utilisateur...~User-defined fields...~Benu'
   +'tzerfelder...'),101);
 MAdd(8,T('Listes de valeurs...~Value lists...~Wertelisten...~Listas de valo'
   +'res...~Elenchi valori...'),102);
 MAdd(8,T('Plans d''action...~Action plans...~Aktionspl@1ne...~Planes de acc'
   +'i@on...~Piani d''azione...'),103);
 MAdd(8,T('@Etapes d''un plan...~Plan steps...~Planschritte...~Pasos del pla'
   +'n...~Passi del piano...'),104);
 MAdd(8,T('Mod@eles de documents...~Document templates...~Dokumentvorlagen..'
   +'.~Plantillas...~Modelli...'),105);
 MAdd(8,T('Texte d''un mod@ele...~Template text...~Vorlagentext...~Texto de '
   +'plantilla...~Testo del modello...'),106);
 MAdd(8,T('Produits (OrderDesk)...~Products (OrderDesk)...~Produkte (OrderDe'
   +'sk)...~Productos...~Prodotti...'),107);
 MAdd(8,T('Soci@et@e...~Company...~Firma...~Empresa...~Azienda...'),108);
 MAdd(8,T('Langue...~Language...~Sprache...~Idioma...~Lingua...'),109);
 MAdd(9,T('Aide|F1~Help|F1~Hilfe|F1~Ayuda|F1~Aiuto|F1'),110);
 MAdd(9,T('Raccourcis clavier~Keyboard shortcuts~Tastenk@3rzel~Atajos de tec'
   +'lado~Scorciatoie'),111);
 MAdd(9,'-',0);
 MAdd(9,T('@A propos de Maximilien CRM...~About Maximilien CRM...~@3ber Maxi'
   +'milien CRM...'),112);
End;

Function MenuChecked(Cm: Integer): Boolean;
Begin
 MenuChecked:=False;
 If Cm=30 Then MenuChecked:=ToolBarOn;
 If Cm=31 Then MenuChecked:=StatusOn;
 If (Cm>=20) And (Cm<=28) Then MenuChecked:=(Modu=Cm-19);
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
  du menu M = identificateur 100 + 32 * M + I ; sous-menu M = 900 + M }
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
   If MLb[M,I]='-' Then MnItem(MIS_SEPARATOR,0,100+32*M+I,'')
   Else MnItem(MIS_TEXT,0,100+32*M+I,PmMenuText(MLb[M,I]));
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
  If MLb[M,I]<>'-' Then MnAttr(100+32*M+I,MIA_CHECKED,MenuChecked(MCm[M,I]));
End;

Function MenuX(M: Integer): Integer;
Var I,X: Integer;
Begin
 X:=10;
 For I:=1 To M-1 Do X:=X+TextW(MT[I])+8;
 MenuX:=X;
End;

Function ItemH(M,I: Integer): Integer;
Begin
 If MLb[M,I]='-' Then ItemH:=8 Else ItemH:=16;
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
  If P>0 Then L:=(P-1)*8+24+(Length(S)-P)*8 Else L:=Length(S)*8;
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
   If Hi Then Bx(X1+3,Y,X2-3,Y+15,cNavy);
   If MenuChecked(MCm[MenuOpen,I]) Then Begin
    If Hi Then Tx_(X1+8,Y+4,#251,cWht) Else Tx_(X1+8,Y+4,#251,cBlk);
   End;
   If Hi Then Begin
    Tx_(X1+24,Y+4,Lb,cWht);
    If Sc<>'' Then Tx_(X2-10-Length(Sc)*8,Y+4,Sc,cWht);
   End Else Begin
    Tx_(X1+24,Y+4,Lb,cBlk);
    If Sc<>'' Then Tx_(X2-10-Length(Sc)*8,Y+4,Sc,cBlk);
   End;
  End;
 End;
End;

{ ---- barre d'outils ---- }

Procedure TAddB(I,Cm,Ic: Integer; Const Tip: String);
Begin
 TbCmd[I]:=Cm;TbIcon[I]:=Ic;TbTip[I]:=Tip;
 If I=1 Then TbX[I]:=6 Else TbX[I]:=TbX[I-1]+26;
 If I In [2,8,11,14] Then TbX[I]:=TbX[I]+6;
End;

Procedure BuildToolbar;
Begin
 TAddB(1,1,1,T('Nouvelle entr@ee~New entry~Neuer Eintrag~Nueva entrada~Nuova'
   +' voce'));
 TAddB(2,50,2,T('Courriel~Email~E-Mail~Correo~E-mail'));
 TAddB(3,51,3,T('Note~Note~Notiz~Nota~Nota'));
 TAddB(4,57,4,T('R@eunion~Meeting~Besprechung~Reuni@on~Riunione'));
 TAddB(5,58,5,T('@A faire~To-do~Aufgabe~Tarea~Da fare'));
 TAddB(6,55,6,T('Passer un appel~Make a call~Anruf~Llamar~Chiama'));
 TAddB(7,66,7,T('Opportunit@e~Opportunity~Verkaufschance~Oportunidad~Opportu'
   +'nit@q'));
 TAddB(8,60,8,T('Plan d''action~Action plan~Aktionsplan~Plan de acci@on~Pian'
   +'o d''azione'));
 TAddB(9,52,12,T('Lettre~Letter~Brief~Carta~Lettera'));
 TAddB(10,65,9,T('Chronom@etrer une t@qche~Time a task~Aufgabe zeiten~Cronom'
   +'etrar~Cronometra'));
 TAddB(11,40,10,T('Rechercher~Find~Suchen~Buscar~Cerca'));
 TAddB(12,45,15,T('Tout afficher~Show all~Alle anzeigen~Mostrar todo~Mostra '
   +'tutto'));
 TAddB(13,80,11,T('Rapports~Reports~Berichte~Informes~Rapporti'));
 TAddB(14,10,14,T('Modifier~Edit~Bearbeiten~Editar~Modifica'));
 TAddB(15,11,13,T('Supprimer~Delete~L@3schen~Eliminar~Elimina'));
 TAddB(16,29,15,T('Actualiser~Refresh~Aktualisieren~Actualizar~Aggiorna'));
 TAddB(17,110,10,T('Aide~Help~Hilfe~Ayuda~Aiuto'));
End;

Function ToolHit(X,Y: LongInt): Integer;
Var I: Integer;
Begin
 ToolHit:=0;
 If Not ToolBarOn Then Exit;
 For I:=1 To NTOOL Do
  If InBox(X,Y,TbX[I],TOOL_Y+2,TbX[I]+23,TOOL_Y+23) Then ToolHit:=I;
End;

Procedure DrawToolbar;
Var I: Integer;
Begin
 Bx(0,TOOL_Y,SCR_W-1,TOOL_Y+25,cLGr);
 Ln(0,TOOL_Y+25,SCR_W-1,TOOL_Y+25,cDGr);
 For I:=1 To NTOOL Do Begin
  Raised(TbX[I],TOOL_Y+2,TbX[I]+23,TOOL_Y+23);
  DrawIcon(TbIcon[I],TbX[I]+4,TOOL_Y+5);
 End;
End;

{ ---- panneau de navigation ---- }

Function ModName(M: Integer): String;
Begin
 Case M Of
  1: ModName:=T('Ma journ@ee~My Work Day~Arbeitstag~Mi d@ia~Giornata');
  2: ModName:=T('Carnet d''adresses~Address Book~Adressbuch~Direcciones~Rubr'
    +'ica');
  3: ModName:=T('Opportunit@es~Opportunities~Chancen~Oportunidades~Opportuni'
    +'t@q');
  4: ModName:='Hotlist';
  5: ModName:=T('Calendrier~Calendar~Kalender~Calendario~Calendario');
  6: ModName:=T('Courriel~Email~E-Mail~Correo~E-mail');
  7: ModName:=T('Biblioth@eque~Library~Bibliothek~Biblioteca~Biblioteca');
  8: ModName:=T('Personnel~Personal~Pers@2nlich~Personal~Personale');
  Else ModName:='OrderDesk';
 End;
End;

Procedure DrawNav;
Var I,Y: Integer; S: LongInt;
Begin
 Bx(0,WORK_Y,NAV_W,STAT_Y-1,cWht);
 Ln(NAV_W,WORK_Y,NAV_W,STAT_Y-1,cDGr);
 For I:=1 To NMOD Do Begin
  Y:=WORK_Y+4+(I-1)*26;
  If I=Modu Then Begin
   Bx(2,Y,NAV_W-2,Y+23,cLCy);Rc(2,Y,NAV_W-2,Y+23,cLBl);
   If Foc=1 Then MxFocusRect(4,Y+2,NAV_W-4,Y+21);
  End;
  DrawIcon(19+I,6,Y+4);
  If I=Modu Then TxB(26,Y+8,Copy(ModName(I),1,12),cBlk)
  Else TxC(26,Y+8,NAV_W-28,ModName(I),cBlk);
 End;
 Y:=WORK_Y+4+NMOD*26+6;
 Bx(0,Y,NAV_W-1,Y+14,cLBl);
 TxB(4,Y+4,T('Entr@ees r@ecentes~Recent Entries~Zuletzt~Recientes~Recenti'
   ),cNavy);
 For I:=1 To 5 Do
  If Recent[I]>0 Then Begin
   DrawIcon(27,2,Y+15+(I-1)*17);
   TxC(20,Y+19+(I-1)*17,NAV_W-22,EntryName(Recent[I]),cBlk);
  End;
End;

Function NavHit(X,Y: LongInt): Integer;
Var I: Integer;
Begin
 NavHit:=0;
 If X>NAV_W Then Exit;
 For I:=1 To NMOD Do
  If InBox(X,Y,0,WORK_Y+4+(I-1)*26,NAV_W,WORK_Y+27+(I-1)*26) Then NavHit:=I;
 For I:=1 To 5 Do
  If (Recent[I]>0) And InBox(X,Y,0,WORK_Y+4+NMOD*26+21+(I-1)*17,NAV_W,
    WORK_Y+4+NMOD*26+37+(I-1)*17) Then NavHit:=100+I;
End;

{ ---- onglets ---- }

Procedure DrawTabs(X1,Y,X2: Integer; Var Tabs: String; Cur: Integer;
  Active: Boolean);
Var I,N,X,W: Integer; Nm: String; Tk: String;
Begin
 Bx(X1,Y,X2,Y+17,cLGr);
 Ln(X1,Y+17,X2,Y+17,cWht);
 X:=X1+2;I:=1;Tk:='';N:=0;
 Tk:=Tabs;
 While Tk<>'' Do Begin
  Inc(N);
  I:=Pos('|',Tk);
  If I=0 Then Begin Nm:=Tk;Tk:='';End Else Begin Nm:=Copy(Tk,1,I-1);
    Delete(Tk,1,I);End;
  W:=Length(Nm)*8+10;
  If N=Cur Then Begin
   Bx(X,Y,X+W,Y+18,cWht);
   Ln(X,Y,X,Y+17,cDGr);Ln(X,Y,X+W,Y,cDGr);Ln(X+W,Y,X+W,Y+17,cDGr);
   If Active Then TxB(X+5,Y+5,Nm,cNavy) Else Tx_(X+5,Y+5,Nm,cBlk);
  End Else Begin
   Ln(X,Y+3,X,Y+17,cDGr);Ln(X,Y+3,X+W,Y+3,cDGr);Ln(X+W,Y+3,X+W,Y+17,cDGr);
   Tx_(X+5,Y+6,Nm,cDGr);
  End;
  X:=X+W+1;
 End;
End;

Function TabHit(X1,Y: Integer; Const Tabs: String; PX,PY: LongInt): Integer;
Var I,N,X,W: Integer; Nm,Tk: String;
Begin
 TabHit:=0;
 If (PY<Y) Or (PY>Y+17) Then Exit;
 X:=X1+2;Tk:=Tabs;N:=0;
 While Tk<>'' Do Begin
  Inc(N);
  I:=Pos('|',Tk);
  If I=0 Then Begin Nm:=Tk;Tk:='';End Else Begin Nm:=Copy(Tk,1,I-1);
    Delete(Tk,1,I);End;
  W:=Length(Nm)*8+10;
  If (PX>=X) And (PX<=X+W) Then TabHit:=N;
  X:=X+W+1;
 End;
End;

Function TabsL: String;
Begin
 TabsL:=T('Contacts|Opport.|Li@es~Contacts|Opps|Related~Kontakte|Chancen|Bez'
   +'.~Contactos|Oport.|Rel.~Contatti|Opp.|Coll.');
End;

Function TabsR: String;
Begin
 TabsR:=T('Notes|Champs|Docs|Social|Cmdes~Notes|UDF|Docs|Social|Orders~Notiz'
   +'en|Felder|Dok.|Social|Auftr.');
End;

{ ====================================================================== }
{                       MODULES : DONNEES ET AFFICHAGE                   }
{ ====================================================================== }

Const
 AB_Y1   = 98;

{ disposition selon la definition de l'ecran (640x480 ou plus) }
Procedure ComputeLayout;
Begin
 STAT_Y:=SCR_H-18;
 CX2:=SCR_W-4;
 BODY_Y2:=STAT_Y-6;
 AB_Y2:=AB_Y1+(BODY_Y2-AB_Y1)*43 Div 100;
 PANE_Y:=AB_Y2+6;
 BODY_Y:=PANE_Y+19;
 LW:=196+(SCR_W-640) Div 4;
 Mid2:=AB_Y1+(BODY_Y2-AB_Y1)*56 Div 100;
 CalW:=44+(SCR_W-640) Div 20;
 CalH:=40+(SCR_H-480) Div 9;
End;

Function IsoToday: String;
Begin
 IsoToday:=IsoDate(SessDate);
End;

Procedure SetSort(Var G: TGrid; Const F: String; Desc: Boolean);
Begin
 G.SortF:=FldIndex(Tb[G.TI],F);
 If G.SortF<1 Then G.SortF:=1;
 G.SortD:=Desc;
End;

Procedure PostFilter(Var G: TGrid);
Var I,K: LongInt; Id: LongInt; Keep: Boolean; J: Integer;
Begin
 If (ShowFilter<3) Then Exit;
 K:=0;
 For I:=1 To G.N Do Begin
  Keep:=False;
  If RowGet(G.TI,G.Sl^[I],RB) Then Begin
   Id:=GetN(G.TI,RB,1);
   If ShowFilter=3 Then Keep:=MarkIdx(Id)>0
   Else For J:=1 To NFilt Do If FiltIds[J]=Id Then Keep:=True;
  End;
  If Keep Then Begin Inc(K);G.Sl^[K]:=G.Sl^[I];End;
 End;
 G.N:=K;
 If G.Sel>G.N Then G.Sel:=Max2(1,G.N);
End;

{ ne garde que les documents trouves par la recherche de texte }
Procedure LibFilterIds;
Var I,K: LongInt; J: Integer; Keep: Boolean;
Begin
 K:=0;
 For I:=1 To GMain.N Do Begin
  Keep:=False;
  If RowGet(GMain.TI,GMain.Sl^[I],RB) Then
   For J:=1 To NLibIds Do If LibIds[J]=GetN(GMain.TI,RB,1) Then Keep:=True;
  If Keep Then Begin Inc(K);GMain.Sl^[K]:=GMain.Sl^[I];End;
 End;
 GMain.N:=K;
 If GMain.Sel>GMain.N Then GMain.Sel:=Max2(1,GMain.N);
End;

Procedure LoadMain;
Var Q: String;
Begin
 GMain.Marks:=Modu In [2,8];
 Case Modu Of
  2,8: Begin
   If Modu=2 Then Q:='SELECT * FROM abentry WHERE personal=0'
   Else Q:='SELECT * FROM abentry WHERE personal=1 AND owner='''+UserCode+'''';
   If ShowFilter=1 Then Q:=Q+' AND kind=''C''';
   If ShowFilter=2 Then Q:=Q+' AND kind=''I''';
   If FilterSql<>'' Then Q:=Q+' AND ('+FilterSql+')';
  End;
  3: Q:='SELECT * FROM oppor';
  4: Begin
   Q:='SELECT * FROM appt WHERE ';
   Case HotMode Of
    1: Q:=Q+'done=0 AND ad>''0000-00-00'' AND ad<'''+IsoToday+'''';
    2: Q:=Q+'done=0 AND ad='''+IsoToday+'''';
    3: Q:=Q+'done=0 AND ad>='''+IsoToday+''' AND ad<='''
      +IsoDate(AddDays(SessDate,7))+'''';
    5: Q:=Q+'done=1';
    Else Q:=Q+'done=0';
   End;
  End;
  6: Q:='SELECT * FROM email WHERE folder='''+MailFold+'''';
  7: Begin
      Q:='SELECT * FROM library';
      If LibMode=1 Then Q:=Q+' WHERE category = '''+QEsc(LibCat)+'''';
     End;
  9: Q:='SELECT * FROM orders';
  Else Exit;
 End;
 GMain.Base:=Q;
 GridReload(GMain,'');
 If Modu In [2,8] Then PostFilter(GMain);
 If (Modu=7) And (LibMode=2) Then LibFilterIds;
End;

Procedure NoteWhere(Var Q: String);
Begin
 If NoteType<>'' Then Q:=Q+' AND kind='''+NoteType+'''';
 Case NotePer Of
  1: Q:=Q+' AND nd>='''+IsoDate(AddDays(SessDate,-365))+'''';
  2: Q:=Q+' AND nd>='''+IsoDate(AddDays(SessDate,-90))+'''';
  3: Q:=Q+' AND nd>='''+IsoDate(AddDays(SessDate,-30))+'''';
 End;
End;

Procedure SetTabCols;
Begin
 Case TabL Of
  1: GridCols(GSubL,tCO,'NAME:110,TITLE:72');
  2: GridCols(GSubL,tOP,'NAME:90,AMOUNT:80');
  Else GridCols(GSubL,tRE,'RELATION:64,OTHER_ID:112');
 End;
 Case TabR Of
  1: Begin GridCols(GSubR,tNO,'FLAG:18,ND:88,NT:40,KIND:56,BODY:100');
      SetSort(GSubR,'ND',True);End;
  3: GridCols(GSubR,tDO,'NAME:100,KIND:60,DD:88,PATH:60');
  5: GridCols(GSubR,tOR,'ORDNO:70,OD:88,STATUS:60,TOTAL:80');
  Else GridCols(GSubR,tNO,'ND:68');
 End;
 If TabL=1 Then SetSort(GSubL,'NAME',False)
 Else If TabL=2 Then SetSort(GSubL,'CLOSEDT',False)
 Else SetSort(GSubL,'RELATION',False);
 If TabR=3 Then SetSort(GSubR,'DD',True);
 If TabR=5 Then SetSort(GSubR,'OD',True);
End;

Function ReadEntry: Boolean;
Var S: LongInt;
Begin
 ReadEntry:=False;
 If CurId<=0 Then Exit;
 S:=RowFind(tAB,CurId);
 If S>=0 Then ReadEntry:=RowGet(tAB,S,RBE);
End;

Procedure LoadSubs;
Var Q,E: String;
Begin
 GSubL.N:=0;GSubR.N:=0;
 If ReadEntry Then ;
 If Modu=9 Then Begin
  GridCols(GSubL,tOL,'PRODUCT:240,QTY:60,PRICE:100,ID:60');
  If GridSelId(GMain)>0 Then Begin
   GSubL.Base:='SELECT * FROM orderln WHERE ord_id='+IntStr(GridSelId(GMain));
   GridReload(GSubL,'');
  End;
  Exit;
 End;
 If Not (Modu In [2,8]) Then Exit;
 If CurId<=0 Then Exit;
 E:=IntStr(CurId);
 Case TabL Of
  1: GSubL.Base:='SELECT * FROM contact WHERE entry_id='+E;
  2: GSubL.Base:='SELECT * FROM oppor WHERE entry_id='+E;
  Else GSubL.Base:='SELECT * FROM related WHERE entry_id='+E;
 End;
 GridReload(GSubL,'');
 Case TabR Of
  1: Begin
      Q:='SELECT * FROM notes WHERE entry_id='+E;NoteWhere(Q);
      GSubR.Base:=Q;GridReload(GSubR,'');
     End;
  3: Begin GSubR.Base:='SELECT * FROM docs WHERE entry_id='+E;
    GridReload(GSubR,'');End;
  5: Begin GSubR.Base:='SELECT * FROM orders WHERE entry_id='+E;
    GridReload(GSubR,'');End;
 End;
End;

Procedure PushRecent(Id: LongInt);
Var I,J: Integer;
Begin
 If Id<=0 Then Exit;
 J:=5;
 For I:=1 To 5 Do If Recent[I]=Id Then J:=I;
 For I:=J DownTo 2 Do Recent[I]:=Recent[I-1];
 Recent[1]:=Id;
End;

Procedure SelectEntry(Id: LongInt);
Begin
 If Id<=0 Then Exit;
 CurId:=Id;
 PushRecent(Id);
 LoadSubs;
End;

{ creneau de l'activite choisie selon le module }
Function ApptSlot: LongInt;
Begin
 Case Modu Of
  1: If WdPanel In [1,2] Then ApptSlot:=GridSelSlot(GW[WdPanel]) Else
    ApptSlot:=-1;
  4: ApptSlot:=GridSelSlot(GMain);
  Else ApptSlot:=GridSelSlot(GSubR);
 End;
End;

{ entree liee a la ligne choisie dans Ma journee }
Function WdEntryId: LongInt;
Var S: LongInt;
Begin
 WdEntryId:=0;
 S:=GridSelSlot(GW[WdPanel]);
 If S<0 Then Exit;
 If RowGet(GW[WdPanel].TI,S,RB) Then Begin
  If WdPanel=4 Then WdEntryId:=GetN(tAB,RB,1)
  Else WdEntryId:=NG(GW[WdPanel].TI,RB,'ENTRY_ID');
 End;
End;

{ synchronise l'entree courante avec la ligne choisie }
Procedure SyncCur;
Var Id: LongInt; S: LongInt;
Begin
 S:=GridSelSlot(GMain);
 Case Modu Of
  2,8: Begin
        Id:=GridSelId(GMain);
        If (Id<>CurId) Then Begin
         CurId:=Id;LoadSubs;
        End;
       End;
  1: Begin
      Id:=WdEntryId;
      If Id>0 Then CurId:=Id;
     End;
  5: Begin
      S:=GridSelSlot(GSubR);
      If (S>=0) And RowGet(tAP,S,RB) Then Begin
       Id:=NG(tAP,RB,'ENTRY_ID');
       If Id>0 Then CurId:=Id;
      End;
     End;
  3,4,6,9: If (S>=0) And RowGet(GMain.TI,S,RB) Then Begin
        Id:=NG(GMain.TI,RB,'ENTRY_ID');
        If Id>0 Then CurId:=Id;
        If Modu=9 Then LoadSubs;
       End;
 End;
End;

Procedure LoadWorkDay;
Var I: Integer;
Begin
 GW[1].Base:='SELECT * FROM appt WHERE done=0 AND ad='''+IsoToday+'''';
 SetSort(GW[1],'AT',False);
 GW[2].Base:='SELECT * FROM appt WHERE done=0 AND ad>''0000-00-00'' AND ad<'
   +''''+IsoToday+'''';
 SetSort(GW[2],'AD',False);
 GW[3].Base:='SELECT * FROM oppor WHERE prob>0 AND prob<100';
 SetSort(GW[3],'CLOSEDT',False);
 GW[4].Base:='SELECT * FROM abentry WHERE personal=0';
 SetSort(GW[4],'MODIFIED',True);
 For I:=1 To 4 Do Begin
  GridReload(GW[I],'');
  If GW[I].N>12 Then GW[I].N:=12;
 End;
End;

Procedure CalLoad;
Var Y,M,I: Integer; Q: String; D: LongInt;
Begin
 Y:=CalDate Div 10000;M:=(CalDate Div 100) Mod 100;
 For I:=1 To 31 Do CalCnt[I]:=0;
 Q:='SELECT * FROM appt WHERE done=0 AND ad>='''+IsoDate(Y*10000+M*100+1)
   +''' AND ad<='''+IsoDate(Y*10000+M*100+31)+'''';
 If SqlRun(Q) Then
  For I:=1 To SqlN Do
   If RowGet(tAP,P1^[I],RB) Then Begin
    D:=NG(tAP,RB,'AD') Mod 100;
    If (D>=1) And (D<=31) Then Inc(CalCnt[D]);
   End;
 GSubR.Base:='SELECT * FROM appt WHERE ad='''+IsoDate(CalDate)+'''';
 GridReload(GSubR,'');
End;

Procedure SetupModule;
Begin
 Case Modu Of
  1: Begin LoadWorkDay;End;
  2,8: Begin
   GridCols(GMain,tAB,'NAME:150,PHONE:112,EMAIL:136,CITY:66,STATE:36');
   SetSort(GMain,'NAME',False);
   GridArea(GMain,CX1,AB_Y1,CX2,AB_Y2);
   GridArea(GSubL,CX1,BODY_Y,CX1+LW,BODY_Y2);
   GridArea(GSubR,CX1+LW+6,BODY_Y+18,CX2,BODY_Y2);
   SetTabCols;
  End;
  3: Begin
   GridCols(GMain,tOP,'ENTRY_ID:110,NAME:110,STAGE:76,PROB:40,AMOUNT:80,CLOS'
     +'EDT:88');
   SetSort(GMain,'CLOSEDT',False);
   GridArea(GMain,CX1,AB_Y1,CX2,BODY_Y2-56);
  End;
  4: Begin
   GridCols(GMain,tAP,'AD:88,AT:48,KIND:64,ENTRY_ID:110,SUBJ:190');
   SetSort(GMain,'AD',False);
   GridArea(GMain,CX1,AB_Y1,CX2,BODY_Y2);
  End;
  5: Begin
   GridCols(GSubR,tAP,'AT:44,KIND:56,SUBJ:100');
   SetSort(GSubR,'AT',False);
   GridArea(GSubR,CX1+7*CalW+8,AB_Y1+18,CX2,BODY_Y2);
   If CalDate=0 Then CalDate:=SessDate;
  End;
  6: Begin
   GridCols(GMain,tEM,'ED:88,FROMA:100,TOA:100,SUBJ:100');
   SetSort(GMain,'ED',True);
   GridArea(GMain,CX1+104,AB_Y1,CX2,Mid2);
  End;
  7: Begin
   GridCols(GMain,tLI,'NAME:150,CATEGORY:90,DD:88,CREATOR:72,DESCR:100');
   SetSort(GMain,'NAME',False);
   GridArea(GMain,CX1,AB_Y1,CX2,Mid2);
  End;
  9: Begin
   GridCols(GMain,tOR,'ORDNO:80,ENTRY_ID:150,OD:88,STATUS:90,TOTAL:96');
   SetSort(GMain,'OD',True);
   GridArea(GMain,CX1,AB_Y1,CX2,Mid2-30);
   GridArea(GSubL,CX1,Mid2-7,CX2,BODY_Y2);
  End;
 End;
End;

Procedure ReloadAll;
Begin
 If Modu=1 Then LoadWorkDay
 Else If Modu=5 Then CalLoad
 Else Begin LoadMain;SyncCur;LoadSubs;End;
 Dirty:=True;
End;

Procedure SetModule(M: Integer);
Begin
 Modu:=M;Foc:=2;
 If Modu=8 Then CurId:=0;
 SetupModule;
 If Modu=5 Then CalLoad Else ReloadAll;
 If Modu In [2,8] Then Begin
  If GMain.N>0 Then SelectEntry(GridSelId(GMain)) Else Begin CurId:=0;
    LoadSubs;End;
 End Else If Modu<>1 Then SyncCur;
 Dirty:=True;
End;

{ ---- dessin ---- }

Procedure Combo(X1,Y,X2: Integer; Const Txt: String);
Begin
 Sunken(X1,Y,X2,Y+15,cWht);
 TxC(X1+4,Y+4,X2-X1-22,Txt,cBlk);
 Raised(X2-14,Y+2,X2-2,Y+13);Arw(X2-8,Y+7,2,cBlk);
End;

Function ShowName: String;
Begin
 Case ShowFilter Of
  1: ShowName:=T('Soci@et@es~Companies~Firmen~Empresas~Aziende');
  2: ShowName:=T('Individus~Individuals~Personen~Individuos~Individui');
  3: ShowName:=T('Entr@ees marqu@ees~Marked entries~Markierte~Marcadas~Segna'
    +'te');
  4: ShowName:=T('R@esultat de recherche~Search result~Suchergebnis~Resultad'
    +'o~Risultato');
  Else ShowName:='<'+T('Tout~All~Alle~Todo~Tutto')+'>';
 End;
End;

Function HotName: String;
Begin
 Case HotMode Of
  1: HotName:=T('En retard~Overdue~@3berf@1llig~Atrasadas~In ritardo');
  2: HotName:=T('Aujourd''hui~Today~Heute~Hoy~Oggi');
  3: HotName:=T('7 prochains jours~Next 7 days~N@1chste 7 Tage~Pr@oximos 7 d'
    +'@ias~Prossimi 7 giorni');
  5: HotName:=T('Termin@ees~Completed~Erledigt~Completadas~Completate');
  Else HotName:=T('Toutes en cours~All pending~Alle offenen~Todas pendientes'
    +'~Tutte in sospeso');
 End;
End;

Procedure Title(Const S: String; Ic: Integer);
Begin
 Bx(CX1,WORK_Y,CX2,WORK_Y+17,cLBl);
 DrawIcon(Ic,CX1+2,WORK_Y+1);
 TxB(CX1+22,WORK_Y+5,S,cNavy);
End;

Procedure DrawUdfPane;
Var I,Y,N: Integer; X1,X2: Integer; V: String; FI: Integer;
Begin
 X1:=CX1+LW+6;X2:=CX2;
 Sunken(X1,BODY_Y,X2,BODY_Y2,cWht);
 N:=0;
 For I:=1 To 10 Do
  If UdfDefined(I) Then Begin
   Y:=BODY_Y+4+N*17;Inc(N);
   FI:=Fx(tAB,'U'+IntStr(I));
   If CurId>0 Then V:=GetS(tAB,RBE,FI) Else V:='';
   TxB(X1+6,Y+3,Copy(UdfNm[I],1,16),cNavy);
   Sunken(X1+150,Y,X2-8,Y+15,cWht);
   Tx_(X1+154,Y+4,Copy(V,1,24),cBlk);
  End;
 If N=0 Then
  Tx_(X1+8,BODY_Y+8,T('Aucun champ d@efini. Voir Configuration.~No fields de'
    +'fined. See Setup.~Keine Felder definiert.'),cDGr);
End;

Procedure DrawSocialPane;
Var I,Y,X1,X2: Integer; Nm: Array[1..4] Of String[8]; V: String;
Begin
 X1:=CX1+LW+6;X2:=CX2;
 Sunken(X1,BODY_Y,X2,BODY_Y2,cWht);
 Nm[1]:='LINKEDIN';Nm[2]:='FACEBOOK';Nm[3]:='TWITTER';Nm[4]:='SKYPE';
 For I:=1 To 4 Do Begin
  Y:=BODY_Y+8+(I-1)*22;
  TxB(X1+8,Y+3,FCap(Nm[I]),cNavy);
  Sunken(X1+100,Y,X2-8,Y+16,cWht);
  If CurId>0 Then V:=SG(tAB,RBE,Nm[I]) Else V:='';
  Tx_(X1+104,Y+4,Copy(V,1,30),cBlk);
 End;
End;

Procedure DrawAddrBook;
Var S: String; X1: Integer; Tb_: String;
Begin
 If Modu=2 Then S:=ModName(2) Else S:=ModName(8);
 Title(S+' - '+T('Toutes les notes~All Notes~Alle Notizen~Todas las notas~Tu'
   +'tte le note')+' - '+EntryName(CurId),20+Modu);
 Bx(CX1,WORK_Y+18,CX2,AB_Y1-1,cLGr);
 Tx_(CX1+4,WORK_Y+23,T('Afficher :~Show:~Anzeige:~Mostrar:~Mostra:'),cBlk);
 Combo(CX1+76,WORK_Y+19,CX1+230,ShowName);
 If FilterName<>'' Then TxC(CX1+240,WORK_Y+23,200,T('Filtre : ~Filter: ~Filt'
   +'er: ~Filtro: ~Filtro: ')+FilterName,cRed);
 Tx_(CX2-130,WORK_Y+23,IntStr(GMain.N)+' '+T('entr@ees~entries~Eintr@1ge~ent'
   +'radas~voci'),cBlk);
 GMain.Foc:=(Foc=2);
 GridDraw(GMain);
 Bx(CX1,AB_Y2+1,CX2,BODY_Y2+1,cLGr);
 Tb_:=TabsL;
 DrawTabs(CX1,PANE_Y,CX1+LW,Tb_,TabL,Foc=3);
 GSubL.Foc:=(Foc=3);
 GridDraw(GSubL);
 Tb_:=TabsR;
 DrawTabs(CX1+LW+6,PANE_Y,CX2,Tb_,TabR,Foc=4);
 X1:=CX1+LW+6;
 If TabR=1 Then Begin
  Bx(X1,BODY_Y,CX2,BODY_Y+17,cLGr);
  Tx_(X1+2,BODY_Y+5,T('Afficher:~Show:~Zeige:~Mostrar:~Mostra:'),cBlk);
  If NoteType='' Then S:='<'+T('Tout~All~Alle~Todo~Tutto')+'>' Else S:=NoteType;
  Combo(X1+66,BODY_Y+1,X1+158,S);
  Tx_(X1+164,BODY_Y+5,T('Filtre:~Filter:~Filter:~Filtro:~Filtro:'),cBlk);
  Case NotePer Of
   1: S:=T('12 derniers mois~Last 12 months~12 Monate~12 meses~12 mesi');
   2: S:=T('3 derniers mois~Last 3 months~3 Monate~3 meses~3 mesi');
   3: S:=T('30 jours~Last 30 days~30 Tage~30 d@ias~30 giorni');
   Else S:='<'+T('Tout~All~Alle~Todo~Tutto')+'>';
  End;
  Combo(X1+218,BODY_Y+1,CX2,S);
  GSubR.Foc:=(Foc=4);
  GridDraw(GSubR);
 End Else If TabR=2 Then DrawUdfPane
 Else If TabR=4 Then DrawSocialPane
 Else Begin
  GridArea(GSubR,X1,BODY_Y,CX2,BODY_Y2);
  GSubR.Foc:=(Foc=4);
  GridDraw(GSubR);
  GridArea(GSubR,X1,BODY_Y+18,CX2,BODY_Y2);
 End;
End;

Procedure DrawPanelTitle(X1,Y1,X2: Integer; Const S: String);
Begin
 Bx(X1,Y1,X2,Y1+14,cNavy);
 TxB(X1+4,Y1+4,S,cWht);
End;

Procedure DrawWorkDay;
Var I,HW: Integer;
Begin
 Title(ModName(1)+' - '+UserName+' - '+FmtDate(SessDate),20);
 Bx(CX1,WORK_Y+18,CX2,STAT_Y-1,cLGr);
 HW:=(CX2-CX1) Div 2;
 DrawPanelTitle(CX1+2,WORK_Y+20,CX1+HW-4,T('Horaire d''aujourd''hui~Today''s'
   +' schedule~Heutiger Zeitplan~Agenda de hoy~Agenda di oggi'));
 GridArea(GW[1],CX1+2,WORK_Y+35,CX1+HW-4,PANE_Y);
 DrawPanelTitle(CX1+HW+2,WORK_Y+20,CX2-2,T('Activit@es en retard~Overdue act'
   +'ivities~@3berf@1llige Aktivit@1ten~Actividades atrasadas~Attivit@q in r'
   +'itardo'));
 GridArea(GW[2],CX1+HW+2,WORK_Y+35,CX2-2,PANE_Y);
 DrawPanelTitle(CX1+2,PANE_Y+4,CX1+HW-4,T('Opportunit@es @a fermer~Opportuni'
   +'ties to close~Abzuschlie@7ende Chancen~Oportunidades a cerrar~Opportuni'
   +'t@q da chiudere'));
 GridArea(GW[3],CX1+2,BODY_Y,CX1+HW-4,BODY_Y2);
 DrawPanelTitle(CX1+HW+2,PANE_Y+4,CX2-2,T('Entr@ees r@ecemment modifi@ees~Re'
   +'cently modified entries~K@3rzlich ge@1ndert'));
 GridArea(GW[4],CX1+HW+2,BODY_Y,CX2-2,BODY_Y2);
 For I:=1 To 4 Do Begin GW[I].Foc:=(I=WdPanel) And (Foc=2);GridDraw(GW[I]);End;
End;

Procedure DrawOpps;
Var Tot,Wt: LongInt; N,I: Integer; S: String;
Begin
 Title(ModName(3),22);
 Bx(CX1,WORK_Y+18,CX2,AB_Y1-1,cLGr);
 Tx_(CX1+4,WORK_Y+23,IntStr(GMain.N)+' '+T('opportunit@es~opportunities~Chan'
   +'cen~oportunidades~opportunit@q'),cBlk);
 GMain.Foc:=True;
 GridDraw(GMain);
 Bx(CX1,BODY_Y2-55,CX2,BODY_Y2+1,cLGr);
 Tot:=0;Wt:=0;N:=0;
 If SqlRun('SELECT * FROM oppor WHERE prob>0 AND prob<100') Then
  For I:=1 To SqlN Do
   If RowGet(tOP,P1^[I],RB) Then Begin
    Inc(N);Tot:=Tot+NG(tOP,RB,'AMOUNT');
    Wt:=Wt+(NG(tOP,RB,'AMOUNT') Div 100)*NG(tOP,RB,'PROB');
   End;
 TxB(CX1+8,BODY_Y2-46,T('Entonnoir ouvert~Open pipeline~Offene Pipeline~Embu'
   +'do abierto~Pipeline aperto')+' :',cNavy);
 Tx_(CX1+8,BODY_Y2-30,IntStr(N)+' '+T('opportunit@es~opportunities~Chancen~o'
   +'portunidades~opportunit@q')+'   '
   +T('Total~Total~Summe~Total~Totale')+' '+FmtMoney(Tot),cBlk);
 Tx_(CX1+8,BODY_Y2-16,T('Valeur pond@er@ee~Weighted value~Gewichteter Wert~V'
   +'alor ponderado~Valore ponderato')+' '+FmtMoney(Wt),cBlk);
End;

Procedure DrawHotlist;
Begin
 Title('Hotlist',23);
 Bx(CX1,WORK_Y+18,CX2,AB_Y1-1,cLGr);
 Tx_(CX1+4,WORK_Y+23,T('Afficher :~Show:~Anzeige:~Mostrar:~Mostra:'),cBlk);
 Combo(CX1+76,WORK_Y+19,CX1+300,HotName);
 Tx_(CX2-150,WORK_Y+23,IntStr(GMain.N)+' '+T('activit@es~activities~Aktivit'
   +'@1ten~actividades~attivit@q'),cBlk);
 GMain.Foc:=True;
 GridDraw(GMain);
End;

Procedure DrawCalendar;
Var Y,M,I,Dd,Col,Row,X,Yy,First,Nd_,D: Integer; Cell: LongInt; Sel,Tdy: Boolean;
Begin
 Y:=CalDate Div 10000;M:=(CalDate Div 100) Mod 100;
 Title(ModName(5)+' - '+MonthName(M)+' '+IntStr(Y),24);
 Bx(CX1,WORK_Y+18,CX2,STAT_Y-1,cLGr);
 Raised(CX1+2,WORK_Y+20,CX1+22,WORK_Y+36);Arw(CX1+12,WORK_Y+28,3,cBlk);
 Raised(CX1+7*CalW-18,WORK_Y+20,CX1+7*CalW+2,WORK_Y+36);
 Arw(CX1+7*CalW-8,WORK_Y+28,4,cBlk);
 TxB(CX1+80,WORK_Y+24,MonthName(M)+' '+IntStr(Y),cNavy);
 For I:=0 To 6 Do Begin
  Bx(CX1+2+I*CalW,AB_Y1,CX1+CalW+1+I*CalW,AB_Y1+14,cNavy);
  Tx_(CX1+8+I*CalW,AB_Y1+4,Copy(DayName(I),1,3),cWht);
 End;
 First:=WeekDay(Y*10000+M*100+1);
 Nd_:=DaysInMonth(Y,M);
 For Row:=0 To 5 Do
  For Col:=0 To 6 Do Begin
   Dd:=Row*7+Col-First+1;
   X:=CX1+2+Col*CalW;Yy:=AB_Y1+16+Row*CalH;
   If (Dd>=1) And (Dd<=Nd_) Then Begin
    Cell:=Y*10000+M*100+Dd;
    Sel:=Cell=CalDate;Tdy:=Cell=SessDate;
    If Sel Then Bx(X,Yy,X+CalW-1,Yy+CalH-2,cNavy)
    Else Bx(X,Yy,X+CalW-1,Yy+CalH-2,cWht);
    Rc(X,Yy,X+CalW-1,Yy+CalH-2,cDGr);
    If Tdy Then Rc(X+1,Yy+1,X+CalW-2,Yy+CalH-3,cRed);
    If Sel Then TxB(X+4,Yy+4,IntStr(Dd),cWht) Else
      TxB(X+4,Yy+4,IntStr(Dd),cBlk);
    If CalCnt[Dd]>0 Then Begin
     Bx(X+4,Yy+22,X+39,Yy+34,cLCy);
     Tx_(X+7,Yy+25,IntStr(CalCnt[Dd])+' '+Copy(T('act.~act.~Akt.~act.~att.'
       ),1,4),cBlk);
    End;
   End Else Bx(X,Yy,X+CalW-1,Yy+CalH-2,cLGr);
  End;
 DrawPanelTitle(CX1+7*CalW+8,AB_Y1,CX2,DayName(WeekDay(CalDate))+' '
   +FmtDate(CalDate));
 GSubR.Foc:=Foc=4;
 GridDraw(GSubR);
End;

{ apercu du texte lie : lu directement, sans toucher a la zone TX }
Procedure PreviewText(Own: Char; Id: LongInt; Y1: Integer);
Var I: Integer;
Begin
 Sunken(CX1,Y1,CX2,BODY_Y2,cWht);
 If Id<=0 Then Exit;
 If SqlRun('SELECT * FROM textln WHERE own='''+Own+''' AND ownid='+IntStr(Id)
   +' ORDER BY seq') Then
  For I:=1 To SqlN Do
   If (Y1+4+(I-1)*11<BODY_Y2-8) And RowGet(tTX,P1^[I],RB) Then
    Tx_(CX1+6,Y1+4+(I-1)*11,Copy(SG(tTX,RB,'LINE'),1,64),cBlk);
End;

Function FolderCount(F: Char): Integer;
Begin
 FolderCount:=0;
 If SqlRun('SELECT COUNT(*) FROM email WHERE folder='''+F+'''') Then
  FolderCount:=ValInt(SqlRows^[1][1],0);
End;

Procedure DrawEmail;
Var I: Integer; F: Char; Y: Integer;
Begin
 Title(ModName(6),25);
 Bx(CX1,WORK_Y+18,CX2,STAT_Y-1,cLGr);
 For I:=1 To 4 Do Begin
  F:=CodeAt('FD',I);
  Y:=AB_Y1+(I-1)*22;
  If F=MailFold Then Begin Bx(CX1,Y,CX1+100,Y+20,cNavy);
   TxC(CX1+4,Y+6,92,CodeName('FD',F),cWht);End
  Else Begin Raised(CX1,Y,CX1+100,Y+20);TxC(CX1+4,Y+6,92,CodeName('FD'
    ,F),cBlk);End;
 End;
 GMain.Foc:=True;
 GridDraw(GMain);
 If GMain.N>0 Then Begin
  PreviewText('E',GridSelId(GMain),Mid2+6);
 End Else PreviewText('E',0,Mid2+6);
 If (GMain.N>0) And RowGet(tEM,GridSelSlot(GMain),RB) Then
  TxB(CX1+6,310-2,SG(tEM,RB,'SUBJ'),cNavy);
End;

Procedure DrawLibrary;
Begin
 Title(ModName(7),26);
 Bx(CX1,WORK_Y+18,CX2,AB_Y1-1,cLGr);
 Tx_(CX1+4,WORK_Y+23,IntStr(GMain.N)+' '+T('documents~documents~Dokumente~do'
   +'cumentos~documenti'),cBlk);
 If LibMode=1 Then
  Tx_(CX1+150,WORK_Y+23,T('Cat@egorie : ~Category: ~Kategorie: ')+LibCat,cRed)
 Else If LibMode=2 Then
  Tx_(CX1+150,WORK_Y+23,T('Recherche : ~Search: ~Suche: ')+LibCat,cRed);
 GMain.Foc:=True;
 GridDraw(GMain);
 PreviewText('L',GridSelId(GMain),Mid2+6);
End;

Procedure DrawOrders;
Begin
 Title(ModName(9),28);
 Bx(CX1,WORK_Y+18,CX2,STAT_Y-1,cLGr);
 GMain.Foc:=Foc<>3;
 GridDraw(GMain);
 DrawPanelTitle(CX1,Mid2-22,CX2,T('Lignes de la commande (Entr@ee pour modif'
   +'ier)~Order lines (Enter to edit)~Auftragspositionen (Enter)'));
 GSubL.Foc:=Foc=3;
 GridArea(GSubL,CX1,Mid2-7,CX2,BODY_Y2);
 GridDraw(GSubL);
End;

Procedure DrawModule;
Begin
 Bx(CX1-1,WORK_Y,SCR_W-1,STAT_Y-1,cLGr);
 Case Modu Of
  1: DrawWorkDay;
  2,8: DrawAddrBook;
  3: DrawOpps;
  4: DrawHotlist;
  5: DrawCalendar;
  6: DrawEmail;
  7: DrawLibrary;
  9: DrawOrders;
 End;
End;

Procedure DrawStatusBar;
Var S: String;
Begin
 Bx(0,STAT_Y,SCR_W-1,SCR_H-1,cLGr);
 Sunken(2,STAT_Y+1,SCR_W-278,SCR_H-2,cLGr);
 Sunken(SCR_W-276,STAT_Y+1,SCR_W-3,SCR_H-2,cLGr);
 If StatMsg<>'' Then S:=StatMsg Else S:=T('Appuyez sur F1 pour l''aide~Press'
   +' F1 for Help~F1 = Hilfe');
 TxC(8,STAT_Y+6,SCR_W-292,S,cBlk);
 Tx_(SCR_W-270,STAT_Y+6,T('Util.~User~Benutzer~Usuario~Utente')+': '+UserCode+
   '  '+FmtDate(SessDate)+' '+NowTime,cBlk);
End;

Procedure DrawAll;
Var S: String;
Begin
 HideMouse;
 Bx(0,0,SCR_W-1,MENU_H-1,cNavy);
 Bx(3,3,13,14,cWht);Bx(4,4,12,8,cLRd);Ln(4,10,12,10,cDGr);
 S:=APP_NAME+' ['+CfgCo+']';
 TxB(22,5,S,cWht);
 MxTitle(S);
 Raised(SCR_W-52,2,SCR_W-38,15);Raised(SCR_W-37,2,SCR_W-23,15);
 Raised(SCR_W-20,2,SCR_W-4,15);
 Ln(SCR_W-49,12,SCR_W-42,12,cBlk);Rc(SCR_W-34,5,SCR_W-27,12,cBlk);
 Ln(SCR_W-16,5,SCR_W-8,12,cBlk);Ln(SCR_W-16,12,SCR_W-8,5,cBlk);
 DrawMenuBar;
 If ToolBarOn Then DrawToolbar Else Bx(0,TOOL_Y,SCR_W-1,TOOL_Y+25,cLGr);
 DrawNav;
 DrawModule;
 If StatusOn Then DrawStatusBar;
 DrawDropDown;
 ShowMouse;
 Dirty:=False;
End;


{ ====================================================================== }
{                          ACTIONS DU CRM                                }
{ ====================================================================== }

Function NeedEntry: Boolean;
Begin
 NeedEntry:=CurId>0;
 If CurId<=0 Then
  Info(T('S@electionnez d''abord une entr@ee.~Select an entry first.~Bitte z'
    +'uerst einen Eintrag w@1hlen.'));
End;

Procedure GridGoto(Var G: TGrid; Id: LongInt);
Var I: LongInt;
Begin
 For I:=1 To G.N Do
  If RowGet(G.TI,G.Sl^[I],RB) Then
   If GetN(G.TI,RB,1)=Id Then Begin G.Sel:=I;Exit;End;
End;

Function UserEmail: String;
Var S: LongInt;
Begin
 UserEmail:='';
 If SqlRun('SELECT * FROM users WHERE code='''+UserCode+'''') Then
  If (SqlN>0) And RowGet(tUS,P1^[1],RB2) Then UserEmail:=SG(tUS,RB2,'EMAIL');
End;

Function NoteKindName(N: Integer): String;
Begin
 Case N Of
  1: NoteKindName:=T('Appel~Phone call~Anruf~Llamada~Chiamata');
  2: NoteKindName:=T('Courriel~Email~E-Mail~Correo~E-mail');
  3: NoteKindName:=T('R@eunion~Meeting~Besprechung~Reuni@on~Riunione');
  4: NoteKindName:=T('Lettre~Letter~Brief~Carta~Lettera');
  5: NoteKindName:=T('Fax~Fax~Fax~Fax~Fax');
  Else NoteKindName:=T('Note~Note~Notiz~Nota~Nota');
 End;
End;

{ ---- entrees ---- }

Procedure NewEntry;
Var Id: LongInt;
Begin
 NewRow(tAB,RBF);
 SS(tAB,RBF,'KIND','C');SN(tAB,RBF,'CREATED',SessDate);
 SN(tAB,RBF,'MODIFIED',SessDate);SS(tAB,RBF,'OWNER',UserCode);
 If Modu=8 Then SN(tAB,RBF,'PERSONAL',1);
 If FormEdit(tAB,RBF,T('Nouvelle entr@ee~New entry~Neuer Eintrag~Nueva entra'
   +'da~Nuova voce'),
   '',',CREATED,MODIFIED,PERSONAL,') Then Begin
  If TrimStr(SG(tAB,RBF,'NAME'))='' Then Begin
   Info(T('Le nom est obligatoire.~The name is required.~Der Name ist erford'
     +'erlich.~El nombre es obligatorio.~Il nome @e obbligatorio.'));
   Exit;
  End;
  Id:=RowAdd(tAB,RBF);
  If Id=0 Then Begin Info(DbErr);Exit;End;
  TblFlush(tAB);
  If Not (Modu In [2,8]) Then SetModule(2);
  ShowFilter:=0;FilterSql:='';FilterName:='';
  LoadMain;GridGoto(GMain,Id);
  SelectEntry(Id);
 End;
End;

Procedure EditEntry;
Var S: LongInt;
Begin
 If Not NeedEntry Then Exit;
 S:=RowFind(tAB,CurId);
 If (S>=0) And RowGet(tAB,S,RBF) Then
  If FormEdit(tAB,RBF,T('Entr@ee~Entry~Eintrag~Entrada~Voce')+' - '
    +EntryName(CurId),
    '',',CREATED,MODIFIED,') Then Begin
   SN(tAB,RBF,'MODIFIED',SessDate);
   If RowPut(tAB,S,RBF) Then ;
   TblFlush(tAB);ReloadAll;
  End;
End;

Procedure DeleteCur;
Begin
 If Not NeedEntry Then Exit;
 If MsgBox(T('Supprimer l''entr@ee et toutes ses donn@ees li@ees ?~Delete th'
   +'is entry and all its linked data?~Eintrag und alle verkn@3pften Daten l'
   +'@3schen?')+' '+EntryName(CurId),1)=1 Then Begin
  DeleteEntry(CurId);
  If MarkIdx(CurId)>0 Then ToggleMark(CurId);
  CurId:=0;
  ReloadAll;
  If GMain.N>0 Then SelectEntry(GridSelId(GMain));
 End;
End;

Procedure DuplicateEntry;
Var S,Id: LongInt;
Begin
 If Not NeedEntry Then Exit;
 S:=RowFind(tAB,CurId);
 If (S>=0) And RowGet(tAB,S,RBF) Then Begin
  SS(tAB,RBF,'NAME',Copy(SG(tAB,RBF,'NAME'),1,30)+' (2)');
  SN(tAB,RBF,'ID',0);SN(tAB,RBF,'CREATED',SessDate);SN(tAB,RBF,'MODIFIED'
    ,SessDate);
  Id:=RowAdd(tAB,RBF);
  If Id>0 Then Begin TblFlush(tAB);LoadMain;GridGoto(GMain,Id);
    SelectEntry(Id);End;
 End;
End;

{ ---- sous-enregistrements ---- }

Procedure NewSub(TI: Integer; Const Show,Hide: String; Const Ttl: String;
  Fn: Integer);
Begin
 NewRow(TI,RBF);
 If Fn>0 Then SetN(TI,RBF,Fn,CurId);
 Case Modu Of
  3,4,6,9: ;
 End;
 If FormEdit(TI,RBF,Ttl,Show,Hide) Then Begin
  If RowAdd(TI,RBF)=0 Then Info(DbErr);
  TblFlush(TI);Touch(CurId);ReloadAll;
 End;
End;

Procedure EditSlot(TI: Integer; S: LongInt; Const Show,Hide,Ttl: String);
Begin
 If (S>=0) And RowGet(TI,S,RBF) Then
  If FormEdit(TI,RBF,Ttl,Show,Hide) Then Begin
   If RowPut(TI,S,RBF) Then ;
   TblFlush(TI);ReloadAll;
  End;
End;

Procedure DelSlot(TI: Integer; S: LongInt);
Begin
 If S<0 Then Exit;
 If MsgBox(T('Supprimer cet enregistrement ?~Delete this record?~Diesen Eint'
   +'rag l@3schen?'),1)=1 Then Begin
  RowDel(TI,S);TblFlush(TI);ReloadAll;
 End;
End;

{ ---- notes ---- }

Procedure NoteDlg(S: LongInt; Const KindNm: String);
Var Id: LongInt; New: Boolean;
Begin
 If Not NeedEntry Then Exit;
 New:=S<0;
 If New Then Begin
  NewRow(tNO,RBF);
  SN(tNO,RBF,'ENTRY_ID',CurId);SN(tNO,RBF,'ND',SessDate);
  SS(tNO,RBF,'NT',NowTime);SS(tNO,RBF,'CREATOR',UserCode);
  If KindNm<>'' Then SS(tNO,RBF,'KIND',KindNm)
  Else SS(tNO,RBF,'KIND',NoteKindName(0));
  TXN:=0;
 End Else Begin
  If Not RowGet(tNO,S,RBF) Then Exit;
  TextLoad('N',GetN(tNO,RBF,1));
  If TXN=0 Then TxAdd(SG(tNO,RBF,'BODY'));
 End;
 If Not FormEdit(tNO,RBF,T('Note~Note~Notiz~Nota~Nota')+' - '+EntryName(CurId),
   'ND,NT,KIND,FLAG','') Then Exit;
 If Not New Then Begin
  { le formulaire a pu ecraser TX via listes : recharge }
  TextLoad('N',GetN(tNO,RBF,1));
  If TXN=0 Then TxAdd(SG(tNO,RBF,'BODY'));
 End;
 If Not EditText(T('Texte de la note~Note text~Notiztext~Texto de la nota~Te'
   +'sto della nota')) Then Exit;
 If TXN<1 Then Begin TXN:=1;TX^[1]:='';End;
 SS(tNO,RBF,'BODY',TX^[1]);
 If New Then Begin
  Id:=RowAdd(tNO,RBF);
 End Else Begin
  Id:=GetN(tNO,RBF,1);
  If RowPut(tNO,S,RBF) Then ;
 End;
 If Id>0 Then TextSave('N',Id);
 TblFlush(tNO);Touch(CurId);ReloadAll;
End;

{ ---- fusion de texte ---- }

Function MergeLine(Const L: String; Const Cn: String): String;
Var R,Tk,V: String; I,J: Integer;
Begin
 R:=L;
 Repeat
  I:=Pos('<<',R);J:=Pos('>>',R);
  If (I>0) And (J>I) Then Begin
   Tk:=Upper(Copy(R,I+2,J-I-2));
   V:='';
   If Tk='DATE' Then V:=FmtDate(SessDate)
   Else If Tk='CONTACT' Then V:=Cn
   Else If Tk='USER' Then V:=UserName
   Else If Tk='COMPANY' Then V:=CfgCo
   Else If Fx(tAB,Tk)>0 Then V:=FmtFld(tAB,RBE,Fx(tAB,Tk));
   Delete(R,I,J-I+2);
   Insert(V,R,I);
  End Else I:=0;
 Until I=0;
 MergeLine:=R;
End;

Function MainContact: String;
Begin
 MainContact:='';
 If CurId<=0 Then Exit;
 If SqlRun('SELECT * FROM contact WHERE entry_id='+IntStr(CurId)+
   ' ORDER BY main DESC') Then
  If (SqlN>0) And RowGet(tCO,P1^[1],RB2) Then MainContact:=SG(tCO,RB2,'NAME');
End;

Procedure MergeAll(Const Cn: String);
Var I: Integer;
Begin
 For I:=1 To TXN Do TX^[I]:=Copy(MergeLine(TX^[I],Cn),1,78);
End;

{ ---- lettres, fax, documents ---- }

Procedure ActDoc(Kd: Char);
Var N,I,Sel: Integer; Ids: Array[1..30] Of LongInt; Id,Did: LongInt; Nm: String;
Begin
 If Not NeedEntry Then Exit;
 If ReadEntry Then ;
 PickN:=0;N:=0;
 PickAdd(T('(Document vierge)~(Blank document)~(Leeres Dokument)~(Documento '
   +'en blanco)~(Documento vuoto)'));
 If SqlRun('SELECT * FROM template WHERE kind='''+Kd+'''') Then
  For I:=1 To SqlN Do
   If (N<29) And RowGet(tTP,P1^[I],RB2) Then Begin
    Inc(N);Ids[N]:=GetN(tTP,RB2,1);PickAdd(SG(tTP,RB2,'NAME'));
   End;
 Sel:=1;
 If Not PickList(CodeName('TK',Kd)+' - '+T('Mod@ele~Template~Vorlage~Plantil'
   +'la~Modello'),Sel) Then Exit;
 TXN:=0;Nm:=CodeName('TK',Kd);
 If Sel>1 Then Begin
  TextLoad('T',Ids[Sel-1]);
  If RowFind(tTP,Ids[Sel-1])>=0 Then Nm:=PickIt^[Sel];
 End;
 MergeAll(MainContact);
 If TXN=0 Then Begin TXN:=1;TX^[1]:='';End;
 If Not InputBox(CodeName('TK',Kd),T('Nom du document :~Document name:~Dokum'
   +'entname:~Nombre del documento:~Nome del documento:'),Nm,40) Then Exit;
 If Not EditText(Nm+' - '+EntryName(CurId)) Then Exit;
 NewRow(tDO,RBF);
 SN(tDO,RBF,'ENTRY_ID',CurId);SS(tDO,RBF,'NAME',Nm);SS(tDO,RBF,'KIND','D');
 SN(tDO,RBF,'DD',SessDate);SS(tDO,RBF,'CREATOR',UserCode);
 SS(tDO,RBF,'PATH',CodeName('TK',Kd));
 Did:=RowAdd(tDO,RBF);
 If Did>0 Then TextSave('D',Did);
 TblFlush(tDO);
 Id:=TXN;
 TXN:=1;TX^[1]:=CodeName('TK',Kd)+': '+Nm;
 If Kd='L' Then Sel:=4 Else If Kd='F' Then Sel:=5 Else Sel:=0;
 If AddNote(CurId,NoteKindName(Sel),'',False)=0 Then ;
 Touch(CurId);ReloadAll;
End;

{ ---- courriel ---- }

Var MailTo,CallNum,MailSubj: String;
    MailDoc: LongInt;

Procedure ActEmail;
Var Id: LongInt; Fd: Integer; Sub: String;
Begin
 If Not NeedEntry Then Exit;
 If ReadEntry Then ;
 NewRow(tEM,RBF);
 SN(tEM,RBF,'ENTRY_ID',CurId);SS(tEM,RBF,'FOLDER','S');
 SN(tEM,RBF,'ED',SessDate);SS(tEM,RBF,'ET',NowTime);
 SS(tEM,RBF,'FROMA',UserEmail);SS(tEM,RBF,'TOA',SG(tAB,RBE,'EMAIL'));
 If MailTo<>'' Then SS(tEM,RBF,'TOA',MailTo);
 If MailSubj<>'' Then SS(tEM,RBF,'SUBJ',MailSubj);
 SN(tEM,RBF,'READ',1);
 If Not FormEdit(tEM,RBF,T('Nouveau courriel~New email~Neue E-Mail~Nuevo cor'
   +'reo~Nuova e-mail'),
   'FROMA,TOA,SUBJ','') Then Exit;
 TXN:=0;
 If MailDoc>0 Then TextLoad('L',MailDoc)
 Else Begin
  TxAdd(T('Bonjour,~Hello,~Guten Tag,~Hola,~Buongiorno,'));TxAdd('');TxAdd('');
  TxAdd(T('Cordialement,~Regards,~Mit freundlichen Gr@3@7en,~Saludos,~Cordia'
    +'li saluti,'));
  TxAdd(UserName);
 End;
 MergeAll(MainContact);
 If Not EditText(T('Message~Message~Nachricht~Mensaje~Messaggio')) Then Exit;
 Fd:=MsgBox(T('Envoyer maintenant ? (Non = brouillon)~Send now? (No = draft)'
   +'~Jetzt senden? (Nein = Entwurf)'),2);
 If Fd=3 Then Exit;
 If Fd=2 Then SS(tEM,RBF,'FOLDER','D') Else SS(tEM,RBF,'FOLDER','O');
 Sub:=SG(tEM,RBF,'SUBJ');
 Id:=RowAdd(tEM,RBF);
 If Id>0 Then TextSave('E',Id);
 TblFlush(tEM);
 If Fd=1 Then Begin
  TXN:=1;TX^[1]:=NoteKindName(2)+': '+Sub;
  If AddNote(CurId,NoteKindName(2),'',False)=0 Then ;
 End;
 Touch(CurId);ReloadAll;
End;

Procedure ActReceiveMail;
Var Id: LongInt;
Begin
 NewRow(tEM,RBF);
 SN(tEM,RBF,'ENTRY_ID',CurId);SS(tEM,RBF,'FOLDER','I');
 SN(tEM,RBF,'ED',SessDate);SS(tEM,RBF,'ET',NowTime);
 SS(tEM,RBF,'TOA',UserEmail);
 If ReadEntry Then SS(tEM,RBF,'FROMA',SG(tAB,RBE,'EMAIL'));
 If Not FormEdit(tEM,RBF,T('Courriel re@cu~Received email~Empfangene E-Mail~'
   +'Correo recibido~E-mail ricevuta'),
   'ENTRY_ID,ED,ET,FROMA,SUBJ','') Then Exit;
 TXN:=0;TxAdd('');
 If Not EditText(T('Message~Message~Nachricht~Mensaje~Messaggio')) Then Exit;
 Id:=RowAdd(tEM,RBF);
 If Id>0 Then TextSave('E',Id);
 TblFlush(tEM);ReloadAll;
End;

{ ---- appels et rendez-vous ---- }

Procedure ActCall(Incoming: Boolean);
Var N,Sel: Integer; Ph,Cm: String; I: Integer;
Begin
 If Not NeedEntry Then Exit;
 If ReadEntry Then ;
 PickN:=0;
 If SG(tAB,RBE,'PHONE')<>'' Then PickAdd(SG(tAB,RBE,'PHONE'));
 If SqlRun('SELECT * FROM contact WHERE entry_id='+IntStr(CurId)) Then
  For I:=1 To SqlN Do
   If RowGet(tCO,P1^[I],RB2) Then
    If SG(tCO,RB2,'PHONE')<>'' Then
     PickAdd(Copy(SG(tCO,RB2,'NAME'),1,16)+' '+SG(tCO,RB2,'PHONE'));
 Ph:='';
 If CallNum<>'' Then Ph:=CallNum
 Else If PickN>0 Then Begin
  Sel:=1;
  If Not PickList(EntryName(CurId),Sel) Then Exit;
  Ph:=PickIt^[Sel];
 End;
 If Not InputBox(T('Appel~Phone call~Anruf~Llamada~Chiamata'),
   T('Num@ero :~Number:~Nummer:~N@3mero:~Numero:'),Ph,40) Then Exit;
 Cm:='';
 If Not InputBox(T('Appel~Phone call~Anruf~Llamada~Chiamata'),
   T('R@esum@e de l''appel :~Call summary:~Gespr@1chsnotiz:~Resumen:~Riepilo'
     +'go:'),Cm,70) Then Exit;
 TXN:=1;
 If Incoming Then TX^[1]:=T('Appel re@cu de ~Incoming call from ~Eingehender'
   +' Anruf von ~Llamada recibida de ~Chiamata ricevuta da ')+Ph+' '+Cm
 Else TX^[1]:=T('Appel vers ~Outgoing call to ~Ausgehender Anruf an ~Llamada'
   +' a ~Chiamata a ')+Ph+' '+Cm;
 If AddNote(CurId,NoteKindName(1),'',False)=0 Then ;
 Touch(CurId);ReloadAll;
End;

Function NextHour: String;
Var H,M,S,S1: Word;
Begin
 GetTime(H,M,S,S1);
 If H<23 Then Inc(H);
 NextHour:=Two(H)+':00';
End;

Procedure ActAppt(K: Char);
Var Id: LongInt;
Begin
 NewRow(tAP,RBF);
 SN(tAP,RBF,'ENTRY_ID',CurId);SS(tAP,RBF,'KIND',K);
 If (Modu=5) And (CalDate>0) Then SN(tAP,RBF,'AD',CalDate)
 Else SN(tAP,RBF,'AD',SessDate);
 SS(tAP,RBF,'AT',NextHour);SS(tAP,RBF,'ET',NextHour);
 SS(tAP,RBF,'OWNER',UserCode);SN(tAP,RBF,'PRIO',2);
 If FormEdit(tAP,RBF,CodeName('AK',K),'','DONE,') Then Begin
  Id:=RowAdd(tAP,RBF);
  If Id=0 Then Info(DbErr);
  TblFlush(tAP);ReloadAll;
 End;
End;

Procedure ActPlan;
Var N,I,Sel: Integer; Ids: Array[1..30] Of LongInt; Pl: LongInt; Cnt: Integer;
Begin
 If Not NeedEntry Then Exit;
 PickN:=0;N:=0;
 For I:=0 To Tb[tPL]^.Slots-1 Do
  If (N<30) And RowGet(tPL,I,RB2) Then Begin
   Inc(N);Ids[N]:=GetN(tPL,RB2,1);PickAdd(SG(tPL,RB2,'NAME'));
  End;
 If N=0 Then Begin
  Info(T('Aucun plan d''action d@efini.~No action plan defined.~Kein Aktions'
    +'plan definiert.'));
  Exit;
 End;
 Sel:=1;
 If Not PickList(T('Plan d''action~Action plan~Aktionsplan~Plan de acci@on~P'
   +'iano d''azione'),Sel) Then Exit;
 Pl:=Ids[Sel];Cnt:=0;
 If SqlRun('SELECT * FROM planstep WHERE plan_id='+IntStr(Pl)+' ORDER BY seq')
   Then Begin
  For I:=1 To SqlN Do
   If RowGet(tST,P1^[I],RB2) Then Begin
    NewRow(tAP,RBF);
    SN(tAP,RBF,'ENTRY_ID',CurId);SS(tAP,RBF,'KIND',SG(tST,RB2,'KIND'));
    SN(tAP,RBF,'AD',AddDays(SessDate,NG(tST,RB2,'DAYS')));
    SS(tAP,RBF,'AT','09:00');SS(tAP,RBF,'ET','09:00');
    SS(tAP,RBF,'SUBJ',SG(tST,RB2,'SUBJ'));SS(tAP,RBF,'OWNER',UserCode);
    SN(tAP,RBF,'PRIO',2);
    If RowAdd(tAP,RBF)>0 Then Inc(Cnt);
   End;
 End;
 TblFlush(tAP);
 TXN:=1;TX^[1]:=T('Plan d''action appliqu@e : ~Action plan applied: ~Aktions'
   +'plan angewendet: ')+PickIt^[Sel];
 If AddNote(CurId,NoteKindName(0),'',False)=0 Then ;
 ReloadAll;
 Info(IntStr(Cnt)+' '+T('activit@es cr@e@ees.~activities created.~Aktivit@1t'
   +'en erstellt.~actividades creadas.~attivit@q create.'));
End;

Procedure ActAttach(Link: Boolean);
Var P: String; Id: LongInt; I: Integer;
Begin
 If Not NeedEntry Then Exit;
 P:='';
 If Not InputBox(T('Ins@erer~Insert~Einf@3gen~Insertar~Inserisci'),
   T('Fichier ou adresse (URL) :~File or address (URL):~Datei oder Adresse ('
     +'URL):'),P,78) Then Exit;
 If P='' Then Exit;
 NewRow(tDO,RBF);
 SN(tDO,RBF,'ENTRY_ID',CurId);
 I:=Length(P);
 While (I>0) And (P[I]<>'\') And (P[I]<>'/') Do Dec(I);
 SS(tDO,RBF,'NAME',Copy(P,I+1,40));
 SS(tDO,RBF,'PATH',P);
 If Link Then SS(tDO,RBF,'KIND','L') Else SS(tDO,RBF,'KIND','F');
 SN(tDO,RBF,'DD',SessDate);SS(tDO,RBF,'CREATOR',UserCode);
 If RowAdd(tDO,RBF)=0 Then Info(DbErr);
 TblFlush(tDO);Touch(CurId);ReloadAll;
End;

Procedure ActOpp;
Begin
 NewRow(tOP,RBF);
 SN(tOP,RBF,'ENTRY_ID',CurId);SS(tOP,RBF,'OWNER',UserCode);
 SN(tOP,RBF,'CREATED',SessDate);SN(tOP,RBF,'CLOSEDT',AddDays(SessDate,30));
 SS(tOP,RBF,'STATUS',T('Ouverte~Open~Offen~Abierta~Aperta'));
 If FormEdit(tOP,RBF,T('Nouvelle opportunit@e~New opportunity~Neue Verkaufsc'
   +'hance~Nueva oportunidad~Nuova opportunit@q'),'','CREATED,') Then Begin
  If RowAdd(tOP,RBF)=0 Then Info(DbErr);
  TblFlush(tOP);Touch(CurId);ReloadAll;
 End;
End;

Procedure ActEnvelope(Lbl: Boolean);
Var I,N: Integer; Ids: Array[1..400] Of LongInt; S: LongInt; Cn: String;
 Procedure One(Id: LongInt);
 Begin
  S:=RowFind(tAB,Id);
  If (S>=0) And RowGet(tAB,S,RBE) Then Begin
   If Not Lbl Then Begin
    TxAdd(CfgCo);TxAdd('');TxAdd('');TxAdd('');
    TxAdd(Rep(' ',34)+SG(tAB,RBE,'NAME'));
    TxAdd(Rep(' ',34)+SG(tAB,RBE,'ADDR1'));
    TxAdd(Rep(' ',34)+SG(tAB,RBE,'CITY')+', '+SG(tAB,RBE,'STATE')+' '
      +SG(tAB,RBE,'ZIP'));
    TxAdd(Rep(' ',34)+SG(tAB,RBE,'COUNTRY'));
    TxAdd(Rep('-',70));
   End Else Begin
    TxAdd(SG(tAB,RBE,'NAME'));TxAdd(SG(tAB,RBE,'ADDR1'));
    TxAdd(SG(tAB,RBE,'CITY')+', '+SG(tAB,RBE,'STATE')+' '+SG(tAB,RBE,'ZIP'));
    TxAdd('');
   End;
  End;
 End;
Begin
 TXN:=0;
 If (NMark>0) And Lbl Then Begin
  For I:=1 To NMark Do One(Marked[I]);
 End Else Begin
  If Not NeedEntry Then Exit;
  One(CurId);
 End;
 If ReadEntry Then ;
 If Lbl Then ViewText(T('@Etiquettes~Labels~Etiketten~Etiquetas~Etichette'))
 Else ViewText(T('Enveloppe~Envelope~Umschlag~Sobre~Busta'));
End;

Procedure ActTimerD;
Var T0,T1,El: LongInt; E: TEvent; Done,Run,Redraw: Boolean; Acc_: LongInt;
    X1,Y1,X2,Y2: Integer; Task: String; Min: LongInt; S: String;
 Function Secs: LongInt;
 Begin
  Secs:=UnixNow;
 End;
Begin
 If Not NeedEntry Then Exit;
 X1:=(SCR_W-340) Div 2;Y1:=(SCR_H-150) Div 2;X2:=X1+340;Y2:=Y1+150;
 Acc_:=0;Run:=True;T0:=Secs;Done:=False;Redraw:=True;
 Backdrop;
 Repeat
  If Run Then El:=Acc_+Secs-T0 Else El:=Acc_;
  DlgFrame(X1,Y1,X2,Y2,T('Chronom@etrer une t@qche~Time a task~Aufgabe zeite'
    +'n~Cronometrar tarea~Cronometra attivit@q'));
  Tx_(X1+20,Y1+34,EntryName(CurId),cBlk);
  Sunken(X1+80,Y1+54,X2-80,Y1+84,cBlk);
  S:=Two(El Div 3600)+':'+Two((El Div 60) Mod 60)+':'+Two(El Mod 60);
  TxB(X1+110,Y1+65,S,cLGn);
  If Run Then Btn(X1+20,Y2-36,X1+100,Y2-14,T('&Pause~&Pause~&Pause~&Pausa~&P'
    +'ausa'),False)
  Else Btn(X1+20,Y2-36,X1+100,Y2-14,T('&D@emarrer~&Start~&Start~&Iniciar~&Av'
    +'via'),False);
  Btn(X1+110,Y2-36,X1+220,Y2-14,T('&Enregistrer~&Save~&Speichern~&Guardar~&S'
    +'alva'),True);
  Btn(X1+230,Y2-36,X1+320,Y2-14,T('Annuler~Cancel~Abbrechen~Cancelar~Annulla'
    ),False);
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case UpCase(Chr(E.Key And 255)) Of
    'P','D': Begin
      If Run Then Begin Acc_:=Acc_+Secs-T0;Run:=False;End
      Else Begin T0:=Secs;Run:=True;End;
     End;
    'E','S',#13: Begin Run:=False;Acc_:=El;Done:=True;
      Min:=(El+59) Div 60;If Min<1 Then Min:=1;
      Task:='';
      If InputBox(T('T@qche~Task~Aufgabe~Tarea~Attivit@q'),T('Description :~'
        +'Description:~Beschreibung:~Descripci@on:~Descrizione:'),Task,50)
        Then Begin
       NewRow(tTL,RBF);
       SN(tTL,RBF,'ENTRY_ID',CurId);SN(tTL,RBF,'TD',SessDate);
       SN(tTL,RBF,'MINUTES',Min);SS(tTL,RBF,'TASK',Task);SN(tTL,RBF,'BILL',1);
       SS(tTL,RBF,'USR',UserCode);
       If RowAdd(tTL,RBF)>0 Then TblFlush(tTL);
      End;
     End;
    #27: Done:=True;
   End;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+20,Y2-36,X1+100,Y2-14) Then Begin
    If Run Then Begin Acc_:=Acc_+Secs-T0;Run:=False;End Else Begin T0:=Secs;
      Run:=True;End;
   End Else If InBox(E.X,E.Y,X1+110,Y2-36,X1+220,Y2-14) Then Begin
    Run:=False;Acc_:=El;
    Min:=(El+59) Div 60;If Min<1 Then Min:=1;
    Task:='';
    If InputBox(T('T@qche~Task~Aufgabe~Tarea~Attivit@q'),T('Description :~De'
      +'scription:~Beschreibung:~Descripci@on:~Descrizione:'),Task,50) Then
      Begin
     NewRow(tTL,RBF);
     SN(tTL,RBF,'ENTRY_ID',CurId);SN(tTL,RBF,'TD',SessDate);
     SN(tTL,RBF,'MINUTES',Min);SS(tTL,RBF,'TASK',Task);SN(tTL,RBF,'BILL',1);
     SS(tTL,RBF,'USR',UserCode);
     If RowAdd(tTL,RBF)>0 Then TblFlush(tTL);
    End;
    Done:=True;
   End Else If InBox(E.X,E.Y,X1+230,Y2-36,X1+320,Y2-14) Then Done:=True;
  End;
 Until Done;
End;
Procedure ActTimer;
Begin
 MxCatWant:=True;ActTimerD;MxCatDone;
End;

{ ====================================================================== }
{                  RAPPORTS ET OUTILS                                    }
{ ====================================================================== }

Procedure RepHead(Const Ti: String);
Begin
 TXN:=0;
 TxAdd(Ti);
 TxAdd(CfgCo+'   '+FmtDate(SessDate)+'   '+UserCode);
 TxAdd(Rep('=',76));
End;

Procedure RepEnd;
Begin
 If TXN>=MAXTXT-1 Then TX^[MAXTXT]:='... ('+T('rapport tronqu@e~report trunc'
   +'ated~Bericht gek@3rzt~informe truncado~report troncato')+')';
End;

{ rapport a partir d'une requete SQL : colonnes m_xxx = argent en cents }
Procedure ReportSql(Const Ti,Q: String);
Var W: Array[1..MAXCC] Of Integer; I,J,Cd: Integer; S,H: String;
    Money: Array[1..MAXCC] Of Boolean; R: Real;
Begin
 RepHead(Ti);
 If Not SqlRun(Q) Then Begin TxAdd(SqlErr);ViewText(Ti);Exit;End;
 For J:=1 To SqlNC Do Begin
  Money[J]:=Copy(SqlHead[J],1,2)='m_';
  If Money[J] Then SqlHead[J]:=Copy(SqlHead[J],3,26);
  W[J]:=Length(SqlHead[J]);
 End;
 For I:=1 To SqlNR Do
  For J:=1 To SqlNC Do Begin
   If Money[J] Then Begin
    Val(SqlRows^[I][J],R,Cd);
    If Cd<>0 Then R:=0;
    SqlRows^[I][J]:=FmtMoney(Round(R));
   End;
   If Length(SqlRows^[I][J])>W[J] Then W[J]:=Length(SqlRows^[I][J]);
  End;
 S:='';
 For J:=1 To SqlNC Do S:=S+Pad(SqlHead[J],W[J]+2);
 TxAdd(S);TxAdd(Rep('-',76));
 For I:=1 To SqlNR Do Begin
  S:='';
  For J:=1 To SqlNC Do
   If Money[J] Then S:=S+PadL(SqlRows^[I][J],W[J])+'  '
   Else S:=S+Pad(SqlRows^[I][J],W[J]+2);
  TxAdd(S);
 End;
 TxAdd('');TxAdd(IntStr(SqlNR)+' '+T('ligne(s)~row(s)~Zeile(n)~fila(s)~riga/'
   +'e'));
 ViewText(Ti);
End;

Procedure RepEntries(Mode: Integer);
Var I: LongInt; S: String;
Begin
 Case Mode Of
  1: RepHead(T('Liste du carnet d''adresses~Address book list~Adressbuchlist'
    +'e'));
  Else RepHead(T('Liste t@el@ephonique~Phone list~Telefonliste~Lista telef@o'
    +'nica~Elenco telefonico'));
 End;
 If Modu In [2,8] Then Begin
  For I:=1 To GMain.N Do
   If RowGet(tAB,GMain.Sl^[I],RBE) Then Begin
    If Mode=1 Then
     TxAdd(Pad(SG(tAB,RBE,'NAME'),32)+Pad(SG(tAB,RBE,'PHONE'),16)+
      Pad(SG(tAB,RBE,'CITY'),16)+Pad(SG(tAB,RBE,'STATE'),6))
    Else
     TxAdd(Pad(SG(tAB,RBE,'NAME'),34)+Pad(SG(tAB,RBE,'PHONE'),20)+SG(tAB,RBE,
       'FAX'));
   End;
 End Else
  For I:=0 To Tb[tAB]^.Slots-1 Do
   If RowGet(tAB,I,RBE) Then
    TxAdd(Pad(SG(tAB,RBE,'NAME'),34)+Pad(SG(tAB,RBE,'PHONE'),20)+SG(tAB,RBE,
      'CITY'));
 RepEnd;
 ViewText(TX^[1]);
End;

Procedure RepNotes;
Var I,J: Integer; S: String; Id: LongInt;
Begin
 If Not NeedEntry Then Exit;
 RepHead(T('Notes~Notes~Notizen~Notas~Note')+' - '+EntryName(CurId));
 If SqlRun('SELECT * FROM notes WHERE entry_id='+IntStr(CurId)+' ORDER BY nd'
   +' DESC') Then
  For I:=1 To SqlN Do
   If RowGet(tNO,P1^[I],RBE) Then Begin
    Id:=GetN(tNO,RBE,1);
    TxAdd(FmtDate(NG(tNO,RBE,'ND'))+' '+SG(tNO,RBE,'NT')+'  '+SG(tNO,RBE,
      'KIND')+'  ('+SG(tNO,RBE,'CREATOR')+')');
    S:=SG(tNO,RBE,'BODY');
    TxAdd('   '+S);
    TxAdd('');
   End;
 RepEnd;
 ViewText(TX^[1]);
End;

Procedure RepActivities(Days: Integer);
Var I: Integer; Q: String;
Begin
 If Days=0 Then Q:='SELECT ad, at, kind, subj FROM appt WHERE done=0 ORDER B'
   +'Y ad'
 Else Q:='SELECT ad, at, subj FROM appt WHERE done=0 AND ad>='''+IsoToday+
   ''' AND ad<='''+IsoDate(AddDays(SessDate,Days))+''' ORDER BY ad, at';
 If Days=0 Then ReportSql(T('Activit@es en cours~Pending activities~Offene A'
   +'ktivit@1ten~Actividades pendientes~Attivit@q in sospeso'),Q)
 Else ReportSql(T('Agenda~Agenda~Agenda~Agenda~Agenda'),Q);
End;

Procedure RepLabels;
Begin
 If NMark=0 Then Begin
  Info(T('Marquez d''abord des entr@ees (Espace).~Mark entries first (Space)'
    +'.~Zuerst Eintr@1ge markieren (Leertaste).'));
  Exit;
 End;
 ActEnvelope(True);
End;

Procedure MailMerge;
Var N,I,J,Sel,Cnt: Integer; Ids: Array[1..30] Of LongInt; F: Text; Nm: String;
    S: LongInt; Cn: String; Tmpl: LongInt; Own: Array[1..120] Of String[78];
    NL: Integer; SaveCur: LongInt;
Begin
 PickN:=0;N:=0;
 If SqlRun('SELECT * FROM template WHERE kind=''L'' OR kind=''E'' OR kind='''
   +'F''') Then
  For I:=1 To SqlN Do
   If (N<30) And RowGet(tTP,P1^[I],RB2) Then Begin
    Inc(N);Ids[N]:=GetN(tTP,RB2,1);PickAdd(SG(tTP,RB2,'NAME'));
   End;
 If N=0 Then Begin
  Info(T('Aucun mod@ele disponible.~No template available.~Keine Vorlage vor'
    +'handen.'));Exit;
 End;
 Sel:=1;
 If Not PickList(T('Publipostage~Mail merge~Serienbrief~Combinar corresponde'
   +'ncia~Stampa unione'),Sel) Then Exit;
 Tmpl:=Ids[Sel];
 TextLoad('T',Tmpl);
 NL:=TXN;
 For I:=1 To NL Do Own[I]:=TX^[I];
 Nm:='MERGE.TXT';
 If Not InputBox(T('Publipostage~Mail merge~Serienbrief~Combinar corresponde'
   +'ncia~Stampa unione'),T('Fichier de sortie :~Output file:~Ausgabedatei:~'
   +'Archivo de salida:~File di uscita:'),Nm,40) Then Exit;
 {$I-}
 Assign(F,Nm);Rewrite(F);
 {$I+}
 If IOResult<>0 Then Begin Info(Nm);Exit;End;
 SaveCur:=CurId;Cnt:=0;
 If (Modu In [2,8]) And (NMark=0) Then Begin
  For J:=1 To GMain.N Do
   If RowGet(tAB,GMain.Sl^[J],RBF) Then Begin
    CurId:=GetN(tAB,RBF,1);
    If ReadEntry Then Begin
     Cn:=MainContact;
     For I:=1 To NL Do WriteLn(F,MergeLine(Own[I],Cn));
     WriteLn(F,#12);Inc(Cnt);
    End;
   End;
 End Else
  For J:=1 To NMark Do Begin
   CurId:=Marked[J];
   If ReadEntry Then Begin
    Cn:=MainContact;
    For I:=1 To NL Do WriteLn(F,MergeLine(Own[I],Cn));
    WriteLn(F,#12);Inc(Cnt);
   End;
  End;
 Close(F);
 CurId:=SaveCur;
 If ReadEntry Then ;
 Info(IntStr(Cnt)+' '+T('lettres g@en@er@ees dans ~letters written to ~Brief'
   +'e geschrieben in ')+Nm);
End;

{ ---- console SQL et calculatrice ---- }

Procedure SqlShow(Const Q: String);
Var I,J: Integer; S: String;
Begin
 TXN:=0;
 TxAdd('> '+Copy(Q,1,74));
 If Not SqlRun(Q) Then TxAdd('ERROR: '+SqlErr)
 Else Begin
  If SqlIsSlots Then Begin
   S:='';
   For J:=1 To Tb[SqlTbl]^.NF Do S:=S+Lower(Tb[SqlTbl]^.F[J].Nm)+' | ';
   TxAdd(S);
   For I:=1 To SqlN Do
    If RowGet(SqlTbl,P1^[I],RBE) Then Begin
     S:='';
     For J:=1 To Tb[SqlTbl]^.NF Do S:=S+GetS(SqlTbl,RBE,J)+' | ';
     TxAdd(S);
    End;
  End Else If SqlNC>0 Then Begin
   S:='';
   For J:=1 To SqlNC Do S:=S+SqlHead[J]+' | ';
   TxAdd(S);
   For I:=1 To SqlNR Do Begin
    S:='';
    For J:=1 To SqlNC Do S:=S+SqlRows^[I][J]+' | ';
    TxAdd(S);
   End;
  End;
  If SqlMsg<>'' Then TxAdd('-- '+SqlMsg);
 End;
 If SqlErr='' Then TblFlushAll;
 ViewText('SQL');
End;

Procedure SqlConsole;
Var Q: String;
Begin
 Q:='SELECT * FROM abentry WHERE city = ''Toronto''';
 While InputBox(T('Console SQL (SELECT, INSERT, UPDATE, DELETE, CREATE...)~S'
   +'QL console (SELECT, INSERT, UPDATE, DELETE, CREATE...)~SQL-Konsole'),
   'SQL>',Q,200) And (Q<>'') Do Begin
  SqlShow(Q);
 End;
 ReloadAll;
End;

Procedure Calculator;
Var Q: String;
Begin
 Q:='';
 If Not InputBox(T('Calculatrice~Calculator~Rechner~Calculadora~Calcolatrice'
   ),T('Expression :~Expression:~Ausdruck:~Expresi@on:~Espressione:'),Q,60)
   Then Exit;
 If SqlRun('SELECT '+Q) And (SqlNR>0) Then Info(Q+' = '+SqlRows^[1][1])
 Else Info(T('Expression invalide.~Invalid expression.~Ung@3ltiger Ausdruck.'
   +'~Expresi@on inv@alida.~Espressione non valida.'));
End;

Procedure CheckTables(Rep_: Boolean);
Var I: Integer; Nm,Sp: String;
Begin
 TXN:=0;
 For I:=1 To NSCH Do Begin
  SchemaDef(I,Nm,Sp);
  If SqlRun('CHECK TABLE '+Nm) Then TxAdd(Pad(Nm,12)+SqlMsg);
  If Rep_ Then If SqlRun('REPAIR TABLE '+Nm) Then TxAdd(Pad(Nm,12)+SqlMsg);
 End;
 ViewText(T('V@erification des tables~Table check~Tabellenpr@3fung~Verificac'
   +'i@on de tablas~Verifica tabelle'));
End;

Procedure DbInfo;
Var I: Integer; Nm,Sp: String; K: Integer;
Begin
 TXN:=0;
 TxAdd(T('Dossier de la base :~Database folder:~Datenbankordner:~Carpeta de '
   +'la base:~Cartella database:')+' '+DbDir);
 TxAdd(T('Format : MyISAM (.frm .MYD .MYI), lignes fixes~Format: MyISAM (.fr'
   +'m .MYD .MYI), fixed rows~Format: MyISAM (.frm .MYD .MYI)'));
 TxAdd('');
 TxAdd(Pad('Table',12)+PadL('Rows',8)+PadL('Deleted',9)+PadL('RowLen',8)+PadL(
   'AutoInc',9));
 TxAdd(Rep('-',50));
 For I:=1 To NSCH Do Begin
  SchemaDef(I,Nm,Sp);
  K:=TblIdx(Nm);
  If K>0 Then
   TxAdd(Pad(Nm,12)+PadL(IntStr(Tb[K]^.NIdx),8)+PadL(IntStr(Tb[K]^.Del),9)+
     PadL(IntStr(Tb[K]^.RecLen),8)+PadL(IntStr(Tb[K]^.AutoInc),9));
 End;
 ViewText(T('Informations sur la base~Database information~Datenbankinfo~Inf'
   +'ormaci@on de la base~Informazioni database'));
End;

{ ---- import / export CSV ---- }

Procedure PickTable(Var TI: Integer);
Var I,Sel: Integer; Nm,Sp: String;
Begin
 TI:=0;
 PickN:=0;
 For I:=1 To NSCH Do Begin SchemaDef(I,Nm,Sp);PickAdd(Nm);End;
 Sel:=1;
 If PickList(T('Table~Table~Tabelle~Tabla~Tabella'),Sel) Then Begin
  SchemaDef(Sel,Nm,Sp);TI:=TblIdx(Nm);
 End;
End;

Procedure ExportCsv;
Var TI,I,J: Integer; F: Text; Nm,S: String; Sl: LongInt;
Begin
 PickTable(TI);
 If TI=0 Then Exit;
 Nm:=Upper(Tb[TI]^.Nm)+'.CSV';
 If Not InputBox('CSV',T('Fichier de sortie :~Output file:~Ausgabedatei:~Arc'
   +'hivo de salida:~File di uscita:'),Nm,40) Then Exit;
 {$I-}
 Assign(F,Nm);Rewrite(F);
 {$I+}
 If IOResult<>0 Then Begin Info(Nm);Exit;End;
 S:='';
 For J:=2 To Tb[TI]^.NF Do Begin S:=S+Tb[TI]^.F[J].Nm;If J<Tb[TI]^.NF Then
   S:=S+';';End;
 WriteLn(F,S);
 J:=0;
 For Sl:=0 To Tb[TI]^.Slots-1 Do
  If RowGet(TI,Sl,RB2) Then Begin
   S:='';
   For I:=2 To Tb[TI]^.NF Do Begin
    S:=S+GetS(TI,RB2,I);
    If I<Tb[TI]^.NF Then S:=S+';';
   End;
   WriteLn(F,S);Inc(J);
  End;
 Close(F);
 Info(IntStr(J)+' '+T('lignes export@ees.~rows exported.~Zeilen exportiert.~'
   +'filas exportadas.~righe esportate.'));
End;

Procedure ImportCsv;
Var TI,I,K,P,N: Integer; F: Text; Nm,L,H,Cell: String; Map: Array[1..MAXFLD]
  Of Integer;
    NC: Integer; Cnt: Integer; Sep: Char; Q: Boolean;
Begin
 PickTable(TI);
 If TI=0 Then Exit;
 Nm:=Upper(Tb[TI]^.Nm)+'.CSV';
 If Not InputBox('CSV',T('Fichier @a importer :~File to import:~Zu importier'
   +'ende Datei:~Archivo a importar:~File da importare:'),Nm,40) Then Exit;
 {$I-}
 Assign(F,Nm);Reset(F);
 {$I+}
 If IOResult<>0 Then Begin Info(Nm);Exit;End;
 ReadLn(F,H);
 If Pos(';',H)>0 Then Sep:=';' Else Sep:=',';
 NC:=0;Cell:='';
 For I:=1 To Length(H)+1 Do
  If (I>Length(H)) Or (H[I]=Sep) Then Begin
   Inc(NC);Map[NC]:=FldIndex(Tb[TI],TrimStr(Cell));
   If Map[NC]=1 Then Map[NC]:=0;
   Cell:='';
  End Else Cell:=Cell+H[I];
 Cnt:=0;
 While Not Eof(F) Do Begin
  ReadLn(F,L);
  If L<>'' Then Begin
   NewRow(TI,RBF);
   K:=0;Cell:='';Q:=False;
   For I:=1 To Length(L)+1 Do
    If (I>Length(L)) Or ((L[I]=Sep) And Not Q) Then Begin
     Inc(K);
     If (K<=NC) And (Map[K]>0) Then SetS(TI,RBF,Map[K],Cell);
     Cell:='';
    End Else If L[I]='"' Then Q:=Not Q Else Cell:=Cell+L[I];
   If RowAdd(TI,RBF)>0 Then Inc(Cnt);
  End;
 End;
 Close(F);
 TblFlush(TI);
 Info(IntStr(Cnt)+' '+T('lignes import@ees.~rows imported.~Zeilen importiert'
   +'.~filas importadas.~righe importate.'));
 ReloadAll;
End;

{ ---- sauvegarde ---- }

Function CopyFile(Const A,B: String): Boolean;
Var F,G: File; Got,Put: Word; Buf: PBig;
Begin
 CopyFile:=False;
 {$I-}
 Assign(F,A);Reset(F,1);
 If IOResult<>0 Then Exit;
 Assign(G,B);Rewrite(G,1);
 If IOResult<>0 Then Begin Close(F);Exit;End;
 GetMem(Buf,SizeOf(TBig));
 Repeat
  BlockRead(F,Buf^,SizeOf(TBig),Got);
  If Got>0 Then BlockWrite(G,Buf^,Got,Put);
 Until Got=0;
 FreeMem(Buf,SizeOf(TBig));
 Close(F);Close(G);
 {$I+}
 CopyFile:=IOResult=0;
End;

Procedure BackupRestore(Restore: Boolean);
Var I,N: Integer; Nm,Sp,Bd: String; Ex: Array[1..3] Of String[3];
 Procedure One(J: Integer);
 Var A,B: String;
 Begin
  A:=TblPath(Nm,Ex[J]);
  B:=Bd+DirSep+Lower(Nm)+'.'+Ex[J];
  If Restore Then Begin
   If CopyFile(B,A) Then Inc(N);
  End Else If CopyFile(A,B) Then Inc(N);
 End;
Begin
 Ex[1]:='frm';Ex[2]:='MYD';Ex[3]:='MYI';
 Bd:=DbDir+DirSep+'BACKUP';
 If Restore Then Begin
  If MsgBox(T('Restaurer remplacera les donn@ees actuelles. Continuer ?~Rest'
    +'ore will replace current data. Continue?~Wiederherstellen ersetzt die '
    +'Daten. Fortfahren?'),1)<>1 Then Exit;
  TblCloseAll;
 End Else Begin
  TblFlushAll;
  {$I-}
  MkDir(Bd);
  {$I+}
  If IOResult<>0 Then ;
 End;
 N:=0;
 For I:=1 To NSCH Do Begin
  SchemaDef(I,Nm,Sp);
  One(1);One(2);One(3);
 End;
 If Restore Then Begin
  If Not OpenTables Then Begin Info(DbErr);Exit;End;
  UdfLoad;CurId:=0;ReloadAll;
 End;
 Info(IntStr(N)+' '+T('fichiers copi@es.~files copied.~Dateien kopiert.~arch'
   +'ivos copiados.~file copiati.'));
End;

{ ====================================================================== }
{                  RECHERCHE, CONFIGURATION, AIDE                        }
{ ====================================================================== }

Procedure CfgGet;
Begin
 CfgCo:='Maximilien';
 If SqlRun('SELECT * FROM config WHERE k=''DBNAME''') Then
  If (SqlN>0) And RowGet(tCF,P1^[1],RB2) Then CfgCo:=SG(tCF,RB2,'V');
 UserName:=UserCode;
 If SqlRun('SELECT * FROM users WHERE code='''+UserCode+'''') Then
  If (SqlN>0) And RowGet(tUS,P1^[1],RB2) Then UserName:=SG(tUS,RB2,'NAME');
End;

Procedure CfgSet(Const K,V: String);
Begin
 If SqlRun('UPDATE config SET v='''+V+''' WHERE k='''+K+'''') Then
  If SqlAff=0 Then Cfg(K,V);
 TblFlushAll;
End;

Procedure ApplyFilter(Const Cl,Nm: String);
Begin
 FilterSql:=Cl;FilterName:=Nm;ShowFilter:=0;
 If Not (Modu In [2,8]) Then SetModule(2);
 ReloadAll;
 If GMain.N>0 Then SelectEntry(GridSelId(GMain));
End;

Procedure FindName;
Var Q: String;
Begin
 Q:='';
 If Not InputBox(T('Rechercher~Find~Suchen~Buscar~Cerca'),
   T('Texte @a chercher (nom, ville, courriel, t@el@ephone) :~Text to find ('
     +'name, city, email, phone):~Suchtext (Name, Stadt, E-Mail, Telefon):'
     ),Q,30) Then Exit;
 If Q='' Then Exit;
 ApplyFilter('name LIKE ''%'+Q+'%'' OR city LIKE ''%'+Q+'%'' OR email LIKE '
   +'''%'+Q+'%'' OR phone LIKE ''%'+Q+'%''',Q);
End;

Procedure ShowAll;
Begin
 FilterSql:='';FilterName:='';ShowFilter:=0;NFilt:=0;
 ReloadAll;
 If (Modu In [2,8]) And (GMain.N>0) Then SelectEntry(GridSelId(GMain));
End;

Procedure AdvSearch;
Const FN: String = 'NAME,PHONE,EMAIL,CITY,STATE,ZIP,COUNTRY,STATUS,SOURCE,TE'
  +'RR,DEPT,DIVISION,OWNER,EMPL,REVENUE';
Var Cl,Fld,Op,V,Cond,Conn: String; Sel,I,K: Integer; More: Integer;
    Cnt: Integer; Fi: Integer; Fin: Boolean;
Begin
 Cl:='';Cnt:=0;Conn:='AND';
 Repeat
  PickN:=0;
  K:=0;Cond:='';
  For I:=1 To 15 Do Begin
   Fld:=Part_(FN,I);
   PickAdd(FCap(Fld));
  End;
  Sel:=1;
  If Not PickList(T('Champ~Field~Feld~Campo~Campo'),Sel) Then Exit;
  Fld:=Part_(FN,Sel);
  PickN:=0;
  PickAdd(T('contient~contains~enth@1lt~contiene~contiene'));
  PickAdd(T('commence par~starts with~beginnt mit~empieza por~inizia con'));
  PickAdd('=');PickAdd('<>');PickAdd('>');PickAdd('<');
  Sel:=1;
  If Not PickList(T('Op@erateur~Operator~Operator~Operador~Operatore'),Sel)
    Then Exit;
  V:='';
  If Not InputBox(FCap(Fld),T('Valeur :~Value:~Wert:~Valor:~Valore:'),V,30)
    Then Exit;
  Fi:=Fx(tAB,Fld);
  If Tb[tAB]^.F[Fi].Typ='C' Then Begin
   Case Sel Of
    1: Cond:=Fld+' LIKE ''%'+V+'%''';
    2: Cond:=Fld+' LIKE '''+V+'%''';
    Else Cond:=Fld+' '+PickIt^[Sel]+' '''+V+'''';
   End;
  End Else Begin
   If Fld='REVENUE' Then V:=IntStr(ParseMoney(V));
   If Sel>2 Then Cond:=Fld+' '+PickIt^[Sel]+' '+IntStr(ValInt(V,0))
   Else Cond:=Fld+' = '+IntStr(ValInt(V,0));
  End;
  If Cl<>'' Then Cl:=Cl+' '+Conn+' ';
  Cl:=Cl+Cond;Inc(Cnt);
  More:=MsgBox(T('Ajouter un crit@ere ? Oui = ET, Annuler = OU, Non = recher'
    +'cher~Add a criterion? Yes = AND, Cancel = OR, No = search~Weiteres Kri'
    +'terium? Ja = UND, Abbrechen = ODER, Nein = suchen'),2);
  Fin:=More=2;
  If More=3 Then Conn:='OR' Else Conn:='AND';
 Until Fin Or (Length(Cl)>120);
 If Cl<>'' Then Begin
  ApplyFilter(Cl,Copy(Cl,1,38));
  Cond:='';
  If MsgBox(T('Enregistrer cette recherche ?~Save this search?~Diese Suche s'
    +'peichern?'),1)=1 Then Begin
   If InputBox(T('Requ@ete~Query~Abfrage~Consulta~Query'),T('Nom :~Name:~Nam'
     +'e:~Nombre:~Nome:'),Cond,30) Then Begin
    NewRow(tQR,RBF);SS(tQR,RBF,'NAME',Cond);SS(tQR,RBF,'WHERECL',Cl);
    If RowAdd(tQR,RBF)=0 Then ;
    TblFlush(tQR);
   End;
  End;
 End;
End;

Procedure SearchNotes;
Var Q: String; I,J: Integer; Id: LongInt; Dup: Boolean;
Begin
 Q:='';
 If Not InputBox(T('Rechercher dans les notes~Search notes~Notizen durchsuch'
   +'en'),T('Texte :~Text:~Text:~Texto:~Testo:'),Q,40) Then Exit;
 NFilt:=0;
 If SqlRun('SELECT * FROM notes WHERE body LIKE ''%'+Q+'%''') Then
  For I:=1 To SqlN Do
   If RowGet(tNO,P1^[I],RB2) Then Begin
    Id:=NG(tNO,RB2,'ENTRY_ID');Dup:=False;
    For J:=1 To NFilt Do If FiltIds[J]=Id Then Dup:=True;
    If (Not Dup) And (NFilt<400) Then Begin Inc(NFilt);FiltIds[NFilt]:=Id;End;
   End;
 If Not (Modu In [2,8]) Then SetModule(2);
 FilterSql:='';FilterName:=Q;ShowFilter:=4;
 ReloadAll;
 If GMain.N>0 Then SelectEntry(GridSelId(GMain));
End;

Procedure SavedQueries;
Var I,Sel: Integer; Ids: Array[1..60] Of String[100];
Begin
 PickN:=0;
 For I:=0 To Tb[tQR]^.Slots-1 Do
  If (PickN<60) And RowGet(tQR,I,RB2) Then Begin
   Ids[PickN+1]:=SG(tQR,RB2,'WHERECL');PickAdd(SG(tQR,RB2,'NAME'));
  End;
 If PickN=0 Then Begin
  Info(T('Aucune requ@ete enregistr@ee.~No saved query.~Keine gespeicherte A'
    +'bfrage.'));
  Exit;
 End;
 Sel:=1;
 If PickList(T('Requ@etes enregistr@ees~Saved queries~Gespeicherte Abfragen~'
   +'Consultas guardadas~Query salvate'),Sel) Then
  ApplyFilter(Ids[Sel],PickIt^[Sel]);
End;

Procedure FindDup;
Var I: Integer; Prev,Cur: String; PId,CId: LongInt;
Begin
 NFilt:=0;Prev:='';PId:=0;
 If SqlRun('SELECT * FROM abentry ORDER BY name') Then
  For I:=1 To SqlN Do
   If RowGet(tAB,P1^[I],RB2) Then Begin
    Cur:=Upper(SG(tAB,RB2,'NAME'));CId:=GetN(tAB,RB2,1);
    If (Cur=Prev) And (Cur<>'') Then Begin
     If (NFilt<399) Then Begin
      If (NFilt=0) Or (FiltIds[NFilt]<>PId) Then Begin Inc(NFilt);
        FiltIds[NFilt]:=PId;End;
      Inc(NFilt);FiltIds[NFilt]:=CId;
     End;
    End;
    Prev:=Cur;PId:=CId;
   End;
 If NFilt=0 Then Begin
  Info(T('Aucun doublon trouv@e.~No duplicates found.~Keine Duplikate gefund'
    +'en.~No hay duplicados.~Nessun duplicato.'));
  Exit;
 End;
 If Not (Modu In [2,8]) Then SetModule(2);
 FilterSql:='';FilterName:=T('Doublons~Duplicates~Duplikate~Duplicados~Dupli'
   +'cati');ShowFilter:=4;
 ReloadAll;
End;

Procedure PickShow;
Var Sel: Integer;
Begin
 PickN:=0;
 PickAdd('<'+T('Tout~All~Alle~Todo~Tutto')+'>');
 PickAdd(T('Soci@et@es~Companies~Firmen~Empresas~Aziende'));
 PickAdd(T('Individus~Individuals~Personen~Individuos~Individui'));
 PickAdd(T('Entr@ees marqu@ees~Marked entries~Markierte~Marcadas~Segnate'));
 Sel:=ShowFilter+1;
 If Sel>4 Then Sel:=1;
 If PickList(T('Afficher~Show~Anzeige~Mostrar~Mostra'),Sel) Then Begin
  ShowFilter:=Sel-1;ReloadAll;
  If GMain.N>0 Then SelectEntry(GridSelId(GMain));
 End;
End;

Procedure PickHot;
Var Sel: Integer;
Begin
 PickN:=0;
 PickAdd(T('En retard~Overdue~@3berf@1llig~Atrasadas~In ritardo'));
 PickAdd(T('Aujourd''hui~Today~Heute~Hoy~Oggi'));
 PickAdd(T('7 prochains jours~Next 7 days~N@1chste 7 Tage~Pr@oximos 7 d@ias~'
   +'Prossimi 7 giorni'));
 PickAdd(T('Toutes en cours~All pending~Alle offenen~Todas pendientes~Tutte '
   +'in sospeso'));
 PickAdd(T('Termin@ees~Completed~Erledigt~Completadas~Completate'));
 Sel:=HotMode;
 If PickList('Hotlist',Sel) Then Begin HotMode:=Sel;ReloadAll;End;
End;

Procedure PickNoteFilter(Which: Integer);
Var Sel: Integer;
Begin
 PickN:=0;
 If Which=1 Then Begin
  PickAdd('<'+T('Tout~All~Alle~Todo~Tutto')+'>');
  LoadList('NOTET');
  If PickN=0 Then PickAdd('<'+T('Tout~All~Alle~Todo~Tutto')+'>');
  Sel:=1;
  If Not PickList(T('Type de note~Note type~Notiztyp~Tipo de nota~Tipo di no'
    +'ta'),Sel) Then Exit;
  If Sel=1 Then NoteType:='' Else NoteType:=PickIt^[Sel];
 End Else Begin
  PickAdd('<'+T('Tout~All~Alle~Todo~Tutto')+'>');
  PickAdd(T('12 derniers mois~Last 12 months~12 Monate~12 meses~12 mesi'));
  PickAdd(T('3 derniers mois~Last 3 months~3 Monate~3 meses~3 mesi'));
  PickAdd(T('30 jours~Last 30 days~30 Tage~30 d@ias~30 giorni'));
  Sel:=NotePer+1;
  If Not PickList(T('P@eriode~Period~Zeitraum~Per@iodo~Periodo'),Sel) Then Exit;
  NotePer:=Sel-1;
 End;
 LoadSubs;Dirty:=True;
End;

{ ---- marquage / termine ---- }

Procedure ToggleDone;
Var S: LongInt; TI: Integer;
Begin
 S:=ApptSlot;
 If S<0 Then Exit;
 If RowGet(tAP,S,RBF) Then Begin
  If NG(tAP,RBF,'DONE')=0 Then SN(tAP,RBF,'DONE',1) Else SN(tAP,RBF,'DONE',0);
  If RowPut(tAP,S,RBF) Then ;
  TblFlush(tAP);ReloadAll;
 End;
End;

Procedure MarkCur(All: Integer);
Var I: LongInt;
Begin
 If Not (Modu In [2,8]) Then Exit;
 Case All Of
  0: Begin ToggleMark(GridSelId(GMain));
      If GMain.Sel<GMain.N Then Inc(GMain.Sel);SyncCur;End;
  1: For I:=1 To GMain.N Do
      If RowGet(tAB,GMain.Sl^[I],RB2) Then
       If MarkIdx(GetN(tAB,RB2,1))=0 Then ToggleMark(GetN(tAB,RB2,1));
  Else NMark:=0;
 End;
 Dirty:=True;
End;

{ ---- operations contextuelles ---- }

Procedure NewRelated;
Var Id,Oth: LongInt;
Begin
 If Not NeedEntry Then Exit;
 NewRow(tRE,RBF);
 SN(tRE,RBF,'ENTRY_ID',CurId);
 If FormEdit(tRE,RBF,T('Entr@ee li@ee~Related entry~Verkn@3pfter Eintrag~Ent'
   +'rada relacionada~Voce collegata'),
   'OTHER_ID,RELATION','') Then Begin
  Oth:=NG(tRE,RBF,'OTHER_ID');
  If Oth<=0 Then Exit;
  If RowAdd(tRE,RBF)=0 Then Exit;
  NewRow(tRE,RBF);
  SN(tRE,RBF,'ENTRY_ID',Oth);SN(tRE,RBF,'OTHER_ID',CurId);
  SS(tRE,RBF,'RELATION',T('Li@e @a~Related to~Verkn@3pft mit~Relacionado con'
    +'~Collegato a'));
  If RowAdd(tRE,RBF)=0 Then ;
  TblFlush(tRE);ReloadAll;
 End;
End;

Procedure EditPane(P: Integer);  { 2 = champs definis, 4 = social }
Var S: LongInt; Sh: String; I: Integer;
Begin
 If Not NeedEntry Then Exit;
 S:=RowFind(tAB,CurId);
 If (S<0) Or Not RowGet(tAB,S,RBF) Then Exit;
 If P=2 Then Begin
  Sh:='';
  For I:=1 To 10 Do If UdfDefined(I) Then Sh:=Sh+',U'+IntStr(I);
  If Sh='' Then Begin
   Info(T('Aucun champ d@efini (Configuration).~No fields defined (Setup).~K'
     +'eine Felder definiert.'));Exit;End;
  Sh:=Copy(Sh,2,100);
 End Else Sh:='LINKEDIN,FACEBOOK,TWITTER,SKYPE';
 If FormEdit(tAB,RBF,EntryName(CurId),Sh,'') Then Begin
  If RowPut(tAB,S,RBF) Then ;
  SN(tAB,RBF,'MODIFIED',SessDate);
  TblFlush(tAB);LoadSubs;
 End;
End;

Procedure NewOrder;
Var Id: LongInt;
Begin
 If CurId<=0 Then CurId:=PickEntryDlg;
 If CurId<=0 Then Exit;
 NewRow(tOR,RBF);
 SN(tOR,RBF,'ENTRY_ID',CurId);SN(tOR,RBF,'OD',SessDate);
 SS(tOR,RBF,'ORDNO','SO-'+Copy('0000'
   +IntStr(Tb[tOR]^.AutoInc+1),Length(IntStr(Tb[tOR]^.AutoInc+1))+1,4));
 If FormEdit(tOR,RBF,T('Nouvelle commande~New order~Neuer Auftrag~Nuevo pedi'
   +'do~Nuovo ordine'),'ENTRY_ID,ORDNO,OD,STATUS','') Then Begin
  Id:=RowAdd(tOR,RBF);
  If Id>0 Then Begin
   TblFlush(tOR);
   MgHook:=1;
   ManageTable(tOL,T('Lignes de commande~Order lines~Auftragspositionen~L@in'
     +'eas de pedido~Righe ordine'),'ORD_ID='+IntStr(Id),'PRODUCT:240,QTY:60'
     +',PRICE:100');
   MgHook:=0;
   ReloadAll;
  End;
 End;
End;

Procedure EditOrderLines;
Var Id: LongInt;
Begin
 Id:=0;
 If Modu=9 Then Id:=GridSelId(GMain)
 Else If Modu In [2,8] Then Begin
  If GridSelSlot(GSubR)>=0 Then Begin
   If RowGet(tOR,GridSelSlot(GSubR),RB2) Then Id:=GetN(tOR,RB2,1);
  End;
 End;
 If Id=0 Then Exit;
 MgHook:=1;
 ManageTable(tOL,T('Lignes de commande~Order lines~Auftragspositionen~L@inea'
   +'s de pedido~Righe ordine'),'ORD_ID='+IntStr(Id),'PRODUCT:240,QTY:60,PRI'
   +'CE:100');
 MgHook:=0;
 ReloadAll;
End;

Procedure LibDoc(S: LongInt);
Var Id: LongInt; New: Boolean;
Begin
 New:=S<0;
 If New Then Begin
  NewRow(tLI,RBF);SN(tLI,RBF,'DD',SessDate);SS(tLI,RBF,'CREATOR',UserCode);
  TXN:=0;
 End Else If Not RowGet(tLI,S,RBF) Then Exit;
 If Not FormEdit(tLI,RBF,T('Document de la biblioth@eque~Library document~Bi'
   +'bliotheksdokument'),'NAME,CATEGORY,DESCR,PATH','') Then Exit;
 If New Then Id:=RowAdd(tLI,RBF) Else Id:=GetN(tLI,RBF,1);
 If Not New Then Begin If RowPut(tLI,S,RBF) Then ;End;
 If Id>0 Then Begin
  TextLoad('L',Id);
  If EditText(SG(tLI,RBF,'NAME')) Then TextSave('L',Id);
 End;
 TblFlush(tLI);ReloadAll;
End;

Procedure ViewMail;
Var S: LongInt;
Begin
 S:=GridSelSlot(GMain);
 If (S>=0) And RowGet(tEM,S,RBF) Then Begin
  TextLoad('E',GetN(tEM,RBF,1));
  If TXN<MAXTXT-4 Then Begin
   Move(TX^[1],TX^[5],TXN*SizeOf(String[78]));
   TX^[1]:=T('De : ~From: ~Von: ~De: ~Da: ')+SG(tEM,RBF,'FROMA');
   TX^[2]:=T('@A : ~To: ~An: ~Para: ~A: ')+SG(tEM,RBF,'TOA');
   TX^[3]:=T('Sujet : ~Subject: ~Betreff: ~Asunto: ~Oggetto: ')+SG(tEM,RBF,
     'SUBJ');
   TX^[4]:=Rep('-',70);
   Inc(TXN,4);
  End;
  ViewText(SG(tEM,RBF,'SUBJ'));
 End;
End;

Procedure CtxNew;
Begin
 Case Modu Of
  1: Case WdPanel Of
      1,2: ActAppt('T');
      3: Begin If CurId<=0 Then CurId:=PickEntryDlg;ActOpp;End;
      Else NewEntry;
     End;
  2,8: Case Foc Of
    3: Case TabL Of
        1: Begin If NeedEntry Then NewSub(tCO,'','ENTRY_ID,',T('Nouveau cont'
          +'act~New contact~Neuer Kontakt~Nuevo contacto~Nuovo contatto'
          ),Fx(tCO,'ENTRY_ID'));End;
        2: If NeedEntry Then ActOpp;
        Else NewRelated;
       End;
    4: Case TabR Of
        1: NoteDlg(-1,'');
        2,4: EditPane(TabR);
        3: ActAttach(False);
        Else NewOrder;
       End;
    Else NewEntry;
   End;
  3: Begin If CurId<=0 Then CurId:=PickEntryDlg;ActOpp;End;
  4: ActAppt('T');
  5: ActAppt('M');
  6: Begin If CurId<=0 Then CurId:=PickEntryDlg;ActEmail;End;
  7: LibDoc(-1);
  9: NewOrder;
 End;
End;

Procedure CtxEdit;
Var S: LongInt;
Begin
 Case Modu Of
  1: Case WdPanel Of
      1,2: EditSlot(tAP,GridSelSlot(GW[WdPanel]),'','',T('Activit@e~Activity'
        +'~Aktivit@1t'));
      3: EditSlot(tOP,GridSelSlot(GW[3]),'','CREATED,',T('Opportunit@e~Oppor'
        +'tunity~Verkaufschance'));
      Else EditEntry;
     End;
  2,8: Case Foc Of
    3: Begin S:=GridSelSlot(GSubL);
        Case TabL Of
         1: EditSlot(tCO,S,'','ENTRY_ID,',T('Contact~Contact~Kontakt~Contact'
           +'o~Contatto'));
         2: EditSlot(tOP,S,'','CREATED,',T('Opportunit@e~Opportunity~Verkauf'
           +'schance~Oportunidad~Opportunit@q'));
         Else EditSlot(tRE,S,'OTHER_ID,RELATION','',T('Relation~Relationship'
           +'~Beziehung~Relaci@on~Relazione'));
        End;
       End;
    4: Begin S:=GridSelSlot(GSubR);
        Case TabR Of
         1: NoteDlg(S,'');
         2,4: EditPane(TabR);
         3: EditSlot(tDO,S,'','ENTRY_ID,',T('Document~Document~Dokument~Docu'
           +'mento~Documento'));
         Else EditOrderLines;
        End;
       End;
    Else EditEntry;
   End;
  3: EditSlot(tOP,GridSelSlot(GMain),'','CREATED,',T('Opportunit@e~Opportuni'
    +'ty~Verkaufschance~Oportunidad~Opportunit@q'));
  4: EditSlot(tAP,GridSelSlot(GMain),'','',T('Activit@e~Activity~Aktivit@1t~'
    +'Actividad~Attivit@q'));
  5: EditSlot(tAP,GridSelSlot(GSubR),'','',T('Activit@e~Activity~Aktivit@1t~'
    +'Actividad~Attivit@q'));
  6: ViewMail;
  7: LibDoc(GridSelSlot(GMain));
  9: If Foc=3 Then EditOrderLines Else Begin
      EditSlot(tOR,GridSelSlot(GMain),'ENTRY_ID,ORDNO,OD,STATUS','',
        'OrderDesk');
      EditOrderLines;
     End;
 End;
End;

Procedure CtxDel;
Var S: LongInt;
Begin
 Case Modu Of
  1: Case WdPanel Of
      1,2: DelSlot(tAP,GridSelSlot(GW[WdPanel]));
      3: DelSlot(tOP,GridSelSlot(GW[3]));
      Else DeleteCur;
     End;
  2,8: Case Foc Of
    3: Begin S:=GridSelSlot(GSubL);
        Case TabL Of
         1: DelSlot(tCO,S);
         2: DelSlot(tOP,S);
         Else DelSlot(tRE,S);
        End;
       End;
    4: Begin S:=GridSelSlot(GSubR);
        Case TabR Of
         1: If S>=0 Then If RowGet(tNO,S,RB2) Then Begin
             DelWhere('textln','own=''N'' AND ownid='+IntStr(GetN(tNO,RB2,1)));
             DelSlot(tNO,S);
            End;
         3: DelSlot(tDO,S);
         5: If S>=0 Then If RowGet(tOR,S,RB2) Then Begin
             DelWhere('orderln','ord_id='+IntStr(GetN(tOR,RB2,1)));
             DelSlot(tOR,S);
            End;
        End;
       End;
    Else DeleteCur;
   End;
  3: DelSlot(tOP,GridSelSlot(GMain));
  4: DelSlot(tAP,GridSelSlot(GMain));
  5: DelSlot(tAP,GridSelSlot(GSubR));
  6: DelSlot(tEM,GridSelSlot(GMain));
  7: Begin
      S:=GridSelSlot(GMain);
      If S>=0 Then If RowGet(tLI,S,RB2) Then DelWhere('textln','own=''L'' AN'
        +'D ownid='+IntStr(GetN(tLI,RB2,1)));
      DelSlot(tLI,S);
     End;
  9: Begin
      S:=GridSelSlot(GMain);
      If S>=0 Then If RowGet(tOR,S,RB2) Then DelWhere('orderln','ord_id='
        +IntStr(GetN(tOR,RB2,1)));
      DelSlot(tOR,S);
     End;
 End;
End;

{ ---- configuration ---- }

Procedure SetupLists;
Var Sel: Integer; Nm: String;
Begin
 PickN:=0;
 PickAdd('STATUS');PickAdd('SOURCE');PickAdd('TERR');PickAdd('STAGE');
 PickAdd('OPPST');PickAdd('ORDST');PickAdd('NOTET');PickAdd('SALUT');PickAdd(
   'REL');
 Sel:=1;
 If PickList(T('Listes de valeurs~Value lists~Wertelisten~Listas de valores~'
   +'Elenchi valori'),Sel) Then Begin
  Nm:=PickIt^[Sel];
  ManageTable(tLV,Nm,'LST='+Nm,'VAL:300,EXTRA:100');
 End;
End;

Function PickPlan(Tbl: Integer; Const Ttl: String): LongInt;
Var I,N,Sel: Integer; Ids: Array[1..60] Of LongInt;
Begin
 PickPlan:=0;PickN:=0;N:=0;
 For I:=0 To Tb[Tbl]^.Slots-1 Do
  If (N<60) And RowGet(Tbl,I,RB2) Then Begin
   Inc(N);Ids[N]:=GetN(Tbl,RB2,1);PickAdd(SG(Tbl,RB2,'NAME'));
  End;
 If N=0 Then Exit;
 Sel:=1;
 If PickList(Ttl,Sel) Then PickPlan:=Ids[Sel];
End;

Procedure SetupCmd(Cm: Integer);
Var Id: LongInt; Q: String; Sel: Integer;
Begin
 Case Cm Of
  100: ManageTable(tUS,T('Utilisateurs~Users~Benutzer~Usuarios~Utenti'),'',
    'CODE:90,NAME:200,ROLE:100,EMAIL:130');
  101: Begin MgHook:=2;
        ManageTable(tUD,T('Champs d@efinis par l''utilisateur~User-defined f'
          +'ields~Benutzerfelder'),'','SLOT:60,NAME:200,KIND:80,LST:80');
        MgHook:=0;ReloadAll;
       End;
  102: SetupLists;
  103: ManageTable(tPL,T('Plans d''action~Action plans~Aktionspl@1ne~Planes '
    +'de acci@on~Piani d''azione'),'','NAME:250,DESCR:250');
  104: Begin
        Id:=PickPlan(tPL,T('Plan d''action~Action plan~Aktionsplan~Plan de a'
          +'cci@on~Piano d''azione'));
        If Id>0 Then ManageTable(tST,T('@Etapes~Steps~Schritte~Pasos~Passi'),
          'PLAN_ID='+IntStr(Id),'SEQ:50,DAYS:70,KIND:90,SUBJ:300');
       End;
  105: ManageTable(tTP,T('Mod@eles de documents~Document templates~Dokumentv'
    +'orlagen~Plantillas~Modelli'),'','NAME:250,KIND:90,SUBJ:170');
  106: Begin
        Id:=PickPlan(tTP,T('Mod@ele~Template~Vorlage~Plantilla~Modello'));
        If Id>0 Then Begin
         TextLoad('T',Id);
         If EditText(T('Texte du mod@ele (champs <<NOM>>)~Template text (<<N'
           +'AME>> fields)~Vorlagentext (<<NAME>>)')) Then TextSave('T',Id);
        End;
       End;
  107: ManageTable(tPR,T('Produits~Products~Produkte~Productos~Prodotti'),'',
    'CODE:100,NAME:260,PRICE:100');
  108: Begin
        Q:=CfgCo;
        If InputBox(T('Soci@et@e~Company~Firma~Empresa~Azienda'),T(
          'Nom de la base de donn@ees :~Database name:~Datenbankname:'),Q,40)
          Then Begin
         CfgSet('DBNAME',Q);CfgCo:=Q;
        End;
       End;
  109: Begin
        PickN:=0;
        PickAdd('Fran@cais');PickAdd('English');PickAdd('Deutsch');
        PickAdd('Espa@nol');PickAdd('Italiano');
        PickIt^[1]:=Dc('Fran@kais');PickIt^[4]:=Dc('Espa@nol');
        Sel:=Lang;
        If PickList(T('Langue~Language~Sprache~Idioma~Lingua'),Sel) Then Begin
         Lang:=Sel;BuildMenus;BuildToolbar;SetupModule;UdfLoad;
         ReloadAll;
        End;
       End;
 End;
End;

Procedure ChangeUser;
Var Sel: Integer;
Begin
 LoadUsers;
 If PickN=0 Then Exit;
 Sel:=1;
 If PickList(T('Utilisateur~User~Benutzer~Usuario~Utente'),Sel) Then Begin
  UserCode:=PickIt^[Sel];
  CfgGet;
  If Modu=8 Then Begin CurId:=0;ReloadAll;End;
 End;
End;

Procedure HelpText;
Begin
 TXN:=0;
 TxAdd(T('MAXIMILIEN CRM - Aide~MAXIMILIEN CRM - Help~MAXIMILIEN CRM - Hilfe'
   +'~MAXIMILIEN CRM - Ayuda~MAXIMILIEN CRM - Guida'));
 TxAdd(Rep('=',70));
 TxAdd(T('Modules (volet de gauche) : Mon jour de travail, Carnet d''adresse'
   +'s,~Modules (left pane): My Work Day, Address Book, Opportunities,~Modul'
   +'e (links): Mein Arbeitstag, Adressbuch, Chancen, Hotlist,'));
 TxAdd(T('Opportunit@es, Hotlist, Calendrier, Courriel, Biblioth@eque, Perso'
   +'nnel~Hotlist, Calendar, Email, Company Library, Personal, OrderDesk.~Ka'
   +'lender, E-Mail, Bibliothek, Pers@2nlich, OrderDesk.'));
 TxAdd('');
 TxAdd(T('Touches :~Keys:~Tasten:~Teclas:~Tasti:'));
 TxAdd('  F10 / Alt+'+T('lettre~letter~Buchstabe~letra~lettera')+'   '+T(
   'Menus~Menus~Men@3s~Men@3s~Menu'));
 TxAdd('  Tab / Shift+Tab     '+T('Change de volet~Switch pane~Bereich wechs'
   +'eln~Cambia panel~Cambia pannello'));
 TxAdd('  Ins / Enter / Del   '+T('Nouveau / Modifier / Supprimer~New / Edit'
   +' / Delete~Neu / Bearbeiten / L@3schen'));
 TxAdd('  '+T('Espace~Space~Leertaste~Espacio~Spazio')+'              '+T(
   'Marquer une entr@ee / terminer une activit@e~Mark an entry / complete an'
   +' activity~Eintrag markieren / Aktivit@1t erledigen'));
 TxAdd('  Ctrl+N / Ctrl+F     '+T('Nouvelle entr@ee / Rechercher~New entry /'
   +' Find~Neuer Eintrag / Suchen'));
 TxAdd('  '+T('Clic droit / F9~Right click / F9~Rechtsklick / F9')+'       '
   +T('Menu contextuel~Context menu~Kontextmen@3')+'');
 TxAdd('  Ctrl+C / Ctrl+V     '+T('Copier / coller (presse-papiers)~Copy / p'
   +'aste (clipboard)~Kopieren / Einf@3gen (Zwischenablage)'));
 TxAdd('  F4                  '+T('Liste de valeurs dans un formulaire~Value'
   +' list in a form~Wertliste im Formular'));
 TxAdd('  F2                  '+T('Valider un formulaire / un texte~Accept a'
   +' form / text~Formular / Text best@1tigen'));
 TxAdd('  PgUp / PgDn         '+T('Mois pr@ec@edent / suivant (calendrier)~P'
   +'revious / next month (calendar)~Vorheriger / n@1chster Monat'));
 TxAdd('');
 TxAdd(T('Base de donn@ees : fichiers MyISAM (.frm .MYD .MYI) compatibles My'
   +'SQL / MariaDB.~Database: MyISAM files (.frm .MYD .MYI) compatible with '
   +'MySQL / MariaDB.~Datenbank: MyISAM-Dateien (.frm .MYD .MYI), MySQL / Ma'
   +'riaDB-kompatibel.'));
 TxAdd(T('Outils > Console SQL : SELECT, INSERT, UPDATE, DELETE, CREATE TABL'
   +'E...~Tools > SQL console: SELECT, INSERT, UPDATE, DELETE, CREATE TABLE.'
   +'..~Extras > SQL-Konsole: SELECT, INSERT, UPDATE, DELETE, CREATE TABLE..'
   +'.'));
 TxAdd(T('Champs de fusion : <<NAME>> <<ADDR1>> <<CITY>> <<STATE>> <<ZIP>> <'
   +'<CONTACT>> <<DATE>> <<USER>>~Merge fields: <<NAME>> <<ADDR1>> <<CITY>> '
   +'<<STATE>> <<ZIP>> <<CONTACT>> <<DATE>> <<USER>>'));
 ViewText(T('Aide~Help~Hilfe~Ayuda~Aiuto'));
End;

Procedure AboutBox; Forward;

{ ====================================================================== }
{              MENUS CONTEXTUELS (CLIC DROIT) ET COPIER / COLLER         }
{ ====================================================================== }

Const
 MAXPM = 64;

Var
 PML : Array[1..MAXPM] Of String[44];
 PMC : Array[1..MAXPM] Of Integer;
 PME : Array[1..MAXPM] Of Boolean;
 PMN : Integer;
 PMBase : Integer;

Procedure PMAdd(Const L: String; Cm: Integer; En: Boolean);
Begin
 If PMN>=MAXPM Then Exit;
 Inc(PMN);PML[PMN]:=L;PMC[PMN]:=Cm;PME[PMN]:=En;
End;

{ entree ouvrant un sous-menu }
Procedure PMSub(Const L: String; Sid: Integer; En: Boolean);
Begin
 PMAdd(L,-100-Sid,En);
End;

Procedure PMSep;
Begin
 If (PMN>PMBase) And (PML[PMN]<>'-') Then PMAdd('-',0,False);
End;

Function PMH(I: Integer): Integer;
Begin
 If PML[I]='-' Then PMH:=8 Else PMH:=16;
End;

Procedure BuildSub(Sid: Integer); Forward;

{ affiche les entrees Lo..Hi et retourne la commande choisie (0 = aucune) }
{ articles Lo..Hi dans le gabarit de menu (sous-menus compris) ; retourne
  leur nombre }
Function PopEmit(Lo,Hi: Integer): Integer;
Var I,N,H1,OldN,Lo2,Cnt: Integer; A: LongInt;
Begin
 While (Hi>=Lo) And (PML[Hi]='-') Do Dec(Hi);
 N:=0;
 For I:=Lo To Hi Do Begin
  If PME[I] Then A:=0 Else A:=MIA_DISABLED;
  If PML[I]='-' Then MnItem(MIS_SEPARATOR,0,0,'')
  Else If PMC[I]<=-100 Then Begin
   MnItem(MIS_TEXT Or MIS_SUBMENU,A,4000+I,MxTilde(PML[I]));
   H1:=MnOpen;
   OldN:=PMN;Lo2:=PMN+1;
   BuildSub(-PMC[I]-100);
   Cnt:=PopEmit(Lo2,PMN);
   MnClose(H1,Cnt);
   PMN:=OldN;
  End Else Begin
   If MxPopN<160 Then Inc(MxPopN);
   MxPopIds[MxPopN]:=PMC[I];
   MnItem(MIS_TEXT,A,5000+MxPopN,MxTilde(PML[I]));
  End;
  Inc(N);
 End;
 PopEmit:=N;
End;

{ menu contextuel de PM des entrees Lo..Hi a la position X, Y de l'image ;
  retourne la commande choisie (0 = aucune) }
Function PopupRun(X,Y,Lo,Hi: Integer): Integer;
Var H0,Cnt,Got,K,NK: Integer; Pop,C: LongInt; Keep: Array[0..31] Of LongInt;
 Procedure Scan;
 Begin
  While CmdH<>CmdT Do Begin
   C:=CmdQ[CmdH];CmdH:=(CmdH+1) And 31;
   If (C>5000) And (C<=5000+MxPopN) Then Got:=MxPopIds[C-5000]
   Else If NK<32 Then Begin Keep[NK]:=C;Inc(NK);End;
  End;
 End;
Begin
 PopupRun:=0;
 MenuLen:=0;MxPopN:=0;
 H0:=MnOpen;
 Cnt:=PopEmit(Lo,Hi);
 MnClose(H0,Cnt);
 If Cnt=0 Then Exit;
 Pop:=WinCreateMenu(HWND_DESKTOP,LongInt(@MenuT));
 If Pop=0 Then Exit;
 FlushScreen;
 Dummy:=WinSetCapture(HWND_DESKTOP,0);
 MBtn:=0;MLatch:=0;
 If Y<CanvasTop Then Y:=CanvasTop;
 Dummy:=WinPopupMenu(OsClient,OsClient,Pop,X,CanvasBot-Y,0,0);
 Got:=0;NK:=0;
 Repeat
  PumpMessages;
  Scan;
  If Got=0 Then Dummy:=DosSleep(10);
 Until (Got<>0) Or (WinIsWindowVisible(Pop)=0);
 PumpMessages;
 Scan;
 For K:=0 To NK-1 Do CmdPush(Keep[K]);
 Dummy:=WinDestroyWindow(Pop);
 Dirty:=True;
 PopupRun:=Got;
End;

{ ---- copier / coller ---- }

Function GridRowText(Var G: TGrid): String;
Var S: String; J: Integer; Sl: LongInt;
Begin
 S:='';
 Sl:=GridSelSlot(G);
 If (Sl>=0) And RowGet(G.TI,Sl,RB) Then
  For J:=1 To G.NC Do Begin
   If J>1 Then S:=S+#9;
   S:=S+FmtFld(G.TI,RB,G.CF[J]);
  End;
 GridRowText:=S;
End;

Procedure LibCopyText; Forward;
Procedure LibNewFromClip; Forward;

Procedure CopyAppt(Slot: LongInt);
Begin
 If (Slot<0) Or Not RowGet(tAP,Slot,RBF) Then Exit;
 ClipClear;
 ClipAdd('[APPT]'+SG(tAP,RBF,'KIND')+'|'+SG(tAP,RBF,'AT')+'|'+SG(tAP,RBF,'ET')
   +'|'+IntStr(NG(tAP,RBF,'ENTRY_ID')));
 ClipAdd(SG(tAP,RBF,'SUBJ'));
 ClipAdd(SG(tAP,RBF,'NOTES'));
 ClipPush;
End;

Procedure CopyCur;
Var I: Integer; Sl: LongInt;
Begin
 ClipClear;
 If Modu=7 Then Begin LibCopyText;Exit;End;
 If (Modu=1) And (WdPanel>2) Then Begin
  ClipAdd(GridRowText(GW[WdPanel]));ClipPush;Exit;
 End;
 If Modu In [1,4,5] Then Begin
  CopyAppt(ApptSlot);
  Exit;
 End;
 If (Modu In [2,8]) And (Foc=2) Then Begin
  If Not ReadEntry Then Exit;
  ClipAdd(SG(tAB,RBE,'NAME'));
  ClipAdd(SG(tAB,RBE,'ADDR1'));
  ClipAdd(SG(tAB,RBE,'CITY')+', '+SG(tAB,RBE,'STATE')+' '+SG(tAB,RBE,'ZIP'));
  ClipAdd(SG(tAB,RBE,'COUNTRY'));
  ClipAdd(T('T@el. : ~Phone: ~Tel.: ~Tel.: ~Tel.: ')+SG(tAB,RBE,'PHONE'));
  ClipAdd(T('Courriel : ~Email: ~E-Mail: ~Correo: ~E-mail: ')+SG(tAB,RBE,
    'EMAIL'));
  ClipPush;Exit;
 End;
 If (Modu In [2,8]) And (Foc=4) And (TabR=1) Then Begin
  Sl:=GridSelSlot(GSubR);
  If (Sl>=0) And RowGet(tNO,Sl,RBF) Then Begin
   TextLoad('N',GetN(tNO,RBF,1));
   If TXN=0 Then TxAdd(SG(tNO,RBF,'BODY'));
   For I:=1 To TXN Do ClipAdd(TX^[I]);
   ClipPush;
  End;
  Exit;
 End;
 If (Modu In [2,8]) And (Foc=3) Then ClipAdd(GridRowText(GSubL))
 Else If (Modu In [2,8]) And (Foc=4) Then ClipAdd(GridRowText(GSubR))
 Else If (Modu=9) And (Foc=3) Then ClipAdd(GridRowText(GSubL))
 Else ClipAdd(GridRowText(GMain));
 ClipPush;
End;

Procedure PasteAppt;
Var L1,Subj,Notes: String; K: Char; At,Et: String; En: LongInt; P,Q: Integer;
Begin
 ClipPull;
 If ClipLines=0 Then Begin
  Info(T('Le presse-papiers est vide.~The clipboard is empty.~Die Zwischenab'
    +'lage ist leer.~El portapapeles est@a vac@io.~Gli appunti sono vuoti.'));
  Exit;
 End;
 L1:=ClipLine(1);K:='T';At:=NextHour;Et:=At;En:=CurId;
 If Copy(L1,1,6)='[APPT]' Then Begin
  K:=L1[7];
  Delete(L1,1,8);
  P:=Pos('|',L1);At:=Copy(L1,1,P-1);Delete(L1,1,P);
  P:=Pos('|',L1);Et:=Copy(L1,1,P-1);Delete(L1,1,P);
  En:=ValInt(L1,CurId);
  Subj:=ClipLine(2);Notes:=ClipLine(3);
 End Else Begin Subj:=L1;Notes:=ClipLine(2);End;
 NewRow(tAP,RBF);
 SN(tAP,RBF,'ENTRY_ID',En);SS(tAP,RBF,'KIND',K);
 If Modu=5 Then SN(tAP,RBF,'AD',CalDate) Else SN(tAP,RBF,'AD',SessDate);
 SS(tAP,RBF,'AT',At);SS(tAP,RBF,'ET',Et);SS(tAP,RBF,'SUBJ',Subj);
 SS(tAP,RBF,'NOTES',Notes);SS(tAP,RBF,'OWNER',UserCode);SN(tAP,RBF,'PRIO',2);
 If RowAdd(tAP,RBF)=0 Then Info(DbErr);
 TblFlush(tAP);ReloadAll;
End;

Procedure PasteNote;
Var I: Integer;
Begin
 If Not NeedEntry Then Exit;
 ClipPull;
 If ClipLines=0 Then Begin
  Info(T('Le presse-papiers est vide.~The clipboard is empty.~Die Zwischenab'
    +'lage ist leer.~El portapapeles est@a vac@io.~Gli appunti sono vuoti.'));
  Exit;
 End;
 TXN:=0;
 For I:=1 To ClipLines Do TxAdd(ClipLine(I));
 If EditText(T('Texte de la note~Note text~Notiztext~Texto de la nota~Testo '
   +'della nota')) Then Begin
  If TXN<1 Then Begin TXN:=1;TX^[1]:='';End;
  If AddNote(CurId,NoteKindName(0),'',False)=0 Then ;
  Touch(CurId);ReloadAll;
 End;
End;

Procedure PasteCur;
Begin
 If Modu=7 Then LibNewFromClip
 Else If Modu In [1,4,5] Then PasteAppt
 Else If Modu In [2,8] Then PasteNote
 Else Info(T('Rien @a coller ici.~Nothing to paste here.~Hier kann nichts ei'
   +'ngef@3gt werden.~Nada que pegar aqu@i.~Niente da incollare qui.'));
End;

{ duplique le rendez-vous choisi, une semaine plus tard }
Procedure DupAppt;
Var Sl: LongInt;
Begin
 Sl:=ApptSlot;
 If (Sl<0) Or Not RowGet(tAP,Sl,RBF) Then Exit;
 SN(tAP,RBF,'ID',0);
 SN(tAP,RBF,'AD',AddDays(NG(tAP,RBF,'AD'),7));
 SN(tAP,RBF,'DONE',0);
 If RowAdd(tAP,RBF)=0 Then Info(DbErr);
 TblFlush(tAP);ReloadAll;
End;

{ ---- actions du carnet d'adresses ---- }

Procedure ClipText(Const S: String);
Begin
 ClipClear;ClipAdd(S);ClipPush;
End;

{ applique une modification aux entrees marquees, sinon a l'entree courante }
Procedure ForTargets(Op: Integer; Const Fld,Val: String);
Var I,N: Integer; Ids: Array[1..400] Of LongInt; S: LongInt; F: Integer;
Begin
 N:=0;
 If NMark>0 Then Begin
  For I:=1 To NMark Do Begin Inc(N);Ids[N]:=Marked[I];End;
  If MsgBox(IntStr(N)+' '+T('entr@ees marqu@ees seront modifi@ees. Continuer'
    +' ?~marked entries will be changed. Continue?~markierte Eintr@1ge werde'
    +'n ge@1ndert. Fortfahren?'),1)<>1 Then Exit;
 End Else Begin
  If CurId<=0 Then Begin If NeedEntry Then ;Exit;End;
  N:=1;Ids[1]:=CurId;
 End;
 F:=Fx(tAB,Fld);
 For I:=1 To N Do Begin
  S:=RowFind(tAB,Ids[I]);
  If (S>=0) And RowGet(tAB,S,RBF) Then Begin
   Case Op Of
    1: SetS(tAB,RBF,F,Val);
    2: If SG(tAB,RBF,'KIND')='I' Then SS(tAB,RBF,'KIND','C') Else SS(tAB,RBF,
      'KIND','I');
    3: If NG(tAB,RBF,'PERSONAL')=0 Then SN(tAB,RBF,'PERSONAL',1) Else
      SN(tAB,RBF,'PERSONAL',0);
   End;
   SN(tAB,RBF,'MODIFIED',SessDate);
   If RowPut(tAB,S,RBF) Then ;
  End;
 End;
 TblFlush(tAB);ReloadAll;
End;

Procedure SetEntryField(Const Fld: String);
Var Sel: Integer;
Begin
 If Fld='OWNER' Then LoadUsers Else LoadList(Fld);
 If PickN=0 Then Begin
  Info(T('Liste vide (Configuration > Listes).~Empty list (Setup > Lists).~L'
    +'eere Liste (Einstellungen > Listen).'));
  Exit;
 End;
 Sel:=1;
 If PickList(FCap(Fld),Sel) Then ForTargets(1,Fld,PickIt^[Sel]);
End;

Procedure MarkSame(Const Fld: String);
Var V: String; I: LongInt;
Begin
 If Not ReadEntry Then Exit;
 V:=Upper(SG(tAB,RBE,Fld));
 For I:=1 To GMain.N Do
  If RowGet(tAB,GMain.Sl^[I],RB2) Then
   If (Upper(SG(tAB,RB2,Fld))=V) And (MarkIdx(GetN(tAB,RB2,1))=0) Then
    ToggleMark(GetN(tAB,RB2,1));
 Dirty:=True;
End;

Procedure InvertMarks;
Var I: LongInt;
Begin
 For I:=1 To GMain.N Do
  If RowGet(tAB,GMain.Sl^[I],RB2) Then ToggleMark(GetN(tAB,RB2,1));
 Dirty:=True;
End;

Procedure FilterSame(Const Fld: String);
Var V: String;
Begin
 If Not ReadEntry Then Exit;
 V:=SG(tAB,RBE,Fld);
 If V='' Then Begin
  Info(T('Cette valeur est vide.~This value is empty.~Dieser Wert ist leer.'
    ));Exit;
 End;
 ApplyFilter(Lower(Fld)+' = '''+QEsc(V)+'''',Copy(FCap(Fld)+'='+V,1,38));
End;

Procedure SortBy(Const Fld: String; Desc: Boolean);
Begin
 SetSort(GMain,Fld,Desc);
 ReloadAll;
End;

Procedure CopyField(N: Integer);
Begin
 If Not ReadEntry Then Exit;
 Case N Of
  1: ClipText(SG(tAB,RBE,'NAME'));
  2: ClipText(SG(tAB,RBE,'PHONE'));
  3: ClipText(SG(tAB,RBE,'EMAIL'));
  4: Begin
      ClipClear;ClipAdd(SG(tAB,RBE,'ADDR1'));
      ClipAdd(SG(tAB,RBE,'CITY')+', '+SG(tAB,RBE,'STATE')+' '+SG(tAB,RBE,'ZI'
        +'P'));
      ClipAdd(SG(tAB,RBE,'COUNTRY'));ClipPush;
     End;
  5: ClipText(SG(tAB,RBE,'WEB'));
  Else ClipText(GridRowText(GMain));
 End;
End;

{ fusionne une autre entree dans l'entree courante }
Procedure MergeEntry;
Var Oth: LongInt; S: LongInt; F: Integer; Tn: Array[1..9] Of String[8];
    I: Integer;
Begin
 If Not NeedEntry Then Exit;
 Oth:=PickEntryDlg;
 If (Oth<=0) Or (Oth=CurId) Then Exit;
 If MsgBox(EntryName(Oth)+' -> '+EntryName(CurId)+' ?',1)<>1 Then Exit;
 Tn[1]:='contact';Tn[2]:='oppor';Tn[3]:='notes';Tn[4]:='appt';Tn[5]:='docs';
 Tn[6]:='email';Tn[7]:='timelog';Tn[8]:='orders';Tn[9]:='related';
 For I:=1 To 9 Do
  If SqlRun('UPDATE '+Tn[I]+' SET entry_id = '+IntStr(CurId)+' WHERE entry_i'
    +'d = '+IntStr(Oth)) Then ;
 If SqlRun('UPDATE related SET other_id = '+IntStr(CurId)+' WHERE other_id ='
   +' '+IntStr(Oth)) Then ;
 S:=RowFind(tAB,Oth);
 If (S>=0) And RowGet(tAB,S,RBF) And ReadEntry Then Begin
  For F:=3 To Tb[tAB]^.NF Do
   If (Tb[tAB]^.F[F].Typ='C') And (GetS(tAB,RBE,F)='') And (GetS(tAB,RBF,F)<>
     '') Then
    SetS(tAB,RBE,F,GetS(tAB,RBF,F));
  S:=RowFind(tAB,CurId);
  If S>=0 Then If RowPut(tAB,S,RBE) Then ;
 End;
 DeleteEntry(Oth);
 TblFlushAll;
 ReloadAll;
End;

Procedure DeleteMarked;
Var I: Integer;
Begin
 If NMark=0 Then Exit;
 If MsgBox(IntStr(NMark)+' '+T('entr@ees marqu@ees seront supprim@ees avec l'
   +'eurs donn@ees. Continuer ?~marked entries will be deleted with their da'
   +'ta. Continue?~markierte Eintr@1ge werden mit ihren Daten gel@3scht. For'
   +'tfahren?'),1)<>1 Then Exit;
 For I:=1 To NMark Do DeleteEntry(Marked[I]);
 NMark:=0;CurId:=0;
 ReloadAll;
 If GMain.N>0 Then SelectEntry(GridSelId(GMain));
End;

Procedure ExportMarked;
Var F: Text; I,J: Integer; S: LongInt; Ln_: String;
Begin
 If NMark=0 Then Begin
  Info(T('Marquez d''abord des entr@ees (Espace).~Mark entries first (Space)'
    +'.~Zuerst Eintr@1ge markieren (Leertaste).'));
  Exit;
 End;
 {$I-}
 Assign(F,'MARKED.CSV');Rewrite(F);
 {$I+}
 If IOResult<>0 Then Exit;
 Ln_:='';
 For J:=2 To Tb[tAB]^.NF Do Begin
  Ln_:=Ln_+Tb[tAB]^.F[J].Nm;
  If J<Tb[tAB]^.NF Then Ln_:=Ln_+';';
 End;
 WriteLn(F,Ln_);
 For I:=1 To NMark Do Begin
  S:=RowFind(tAB,Marked[I]);
  If (S>=0) And RowGet(tAB,S,RB2) Then Begin
   Ln_:='';
   For J:=2 To Tb[tAB]^.NF Do Begin
    Ln_:=Ln_+GetS(tAB,RB2,J);
    If J<Tb[tAB]^.NF Then Ln_:=Ln_+';';
   End;
   WriteLn(F,Ln_);
  End;
 End;
 Close(F);
 Info(IntStr(NMark)+' '+T('entr@ees export@ees dans MARKED.CSV.~entries expo'
   +'rted to MARKED.CSV.~Eintr@1ge nach MARKED.CSV exportiert.'));
End;

{ fiche de l'entree : coordonnees, contacts, opportunites, activites, notes }
Procedure EntryCard;
Var I: Integer; E: String;
Begin
 If Not NeedEntry Then Exit;
 If Not ReadEntry Then Exit;
 E:=IntStr(CurId);
 RepHead(SG(tAB,RBE,'NAME'));
 TxAdd(SG(tAB,RBE,'ADDR1')+' '+SG(tAB,RBE,'ADDR2'));
 TxAdd(SG(tAB,RBE,'CITY')+', '+SG(tAB,RBE,'STATE')+' '+SG(tAB,RBE,'ZIP')+' '
   +SG(tAB,RBE,'COUNTRY'));
 TxAdd(FCap('PHONE')+': '+SG(tAB,RBE,'PHONE')+'   '+FCap('FAX')+': '
   +SG(tAB,RBE,'FAX'));
 TxAdd(FCap('EMAIL')+': '+SG(tAB,RBE,'EMAIL')+'   '+FCap('WEB')+': '
   +SG(tAB,RBE,'WEB'));
 TxAdd(FCap('STATUS')+': '+SG(tAB,RBE,'STATUS')+'   '+FCap('SOURCE')+': '
   +SG(tAB,RBE,'SOURCE')+'   '+FCap('TERR')+': '+SG(tAB,RBE,'TERR'));
 TxAdd('');TxAdd(T('Contacts~Contacts~Kontakte'));TxAdd(Rep('-',40));
 If SqlRun('SELECT * FROM contact WHERE entry_id='+E) Then
  For I:=1 To SqlN Do
   If RowGet(tCO,P1^[I],RB2) Then
    TxAdd(Pad(SG(tCO,RB2,'NAME'),30)+Pad(SG(tCO,RB2,'PHONE'),18)+SG(tCO,RB2,
      'EMAIL'));
 TxAdd('');TxAdd(T('Opportunit@es~Opportunities~Verkaufschancen'));TxAdd(Rep(
   '-',40));
 If SqlRun('SELECT * FROM oppor WHERE entry_id='+E) Then
  For I:=1 To SqlN Do
   If RowGet(tOP,P1^[I],RB2) Then
    TxAdd(Pad(SG(tOP,RB2,'NAME'),30)+Pad(SG(tOP,RB2,'STAGE'
      ),14)+PadL(FmtMoney(NG(tOP,RB2,'AMOUNT')),14));
 TxAdd('');TxAdd(T('Activit@es en cours~Pending activities~Offene Aktivit@1t'
   +'en'));TxAdd(Rep('-',40));
 If SqlRun('SELECT * FROM appt WHERE done=0 AND entry_id='+E+' ORDER BY ad')
   Then
  For I:=1 To SqlN Do
   If RowGet(tAP,P1^[I],RB2) Then
    TxAdd(FmtDate(NG(tAP,RB2,'AD'))+' '+SG(tAP,RB2,'AT')+'  '+SG(tAP,RB2,
      'SUBJ'));
 TxAdd('');TxAdd(T('Notes~Notes~Notizen'));TxAdd(Rep('-',40));
 If SqlRun('SELECT * FROM notes WHERE entry_id='+E+' ORDER BY nd DESC') Then
  For I:=1 To SqlN Do
   If (I<=12) And RowGet(tNO,P1^[I],RB2) Then
    TxAdd(FmtDate(NG(tNO,RB2,'ND'))+' '+Pad(SG(tNO,RB2,'KIND'),12)+SG(tNO,RB2,
      'BODY'));
 ViewText(SG(tAB,RBE,'NAME'));
End;

{ ---- contacts ---- }

Function ContactField(Const Fld: String): String;
Var S: LongInt;
Begin
 ContactField:='';
 S:=GridSelSlot(GSubL);
 If (S>=0) And RowGet(tCO,S,RB2) Then ContactField:=SG(tCO,RB2,Fld);
End;

Procedure SetMainContact;
Var S: LongInt;
Begin
 S:=GridSelSlot(GSubL);
 If S<0 Then Exit;
 If SqlRun('UPDATE contact SET main = 0 WHERE entry_id = '+IntStr(CurId)) Then ;
 If RowGet(tCO,S,RBF) Then Begin SN(tCO,RBF,'MAIN',1);If RowPut(tCO,S,RBF)
   Then ;End;
 TblFlush(tCO);ReloadAll;
End;

Procedure EmailContact;
Begin
 MailTo:=ContactField('EMAIL');
 ActEmail;
 MailTo:='';
End;

Procedure CallContact;
Begin
 CallNum:=ContactField('PHONE');
 ActCall(False);
 CallNum:='';
End;

Procedure CopyContactField(N: Integer);
Begin
 Case N Of
  1: ClipText(ContactField('NAME'));
  2: ClipText(ContactField('PHONE'));
  Else ClipText(ContactField('EMAIL'));
 End;
End;

{ ---- opportunites : etapes (1 gagnee 2 perdue 3 suivante 4 precedente) ---- }

Procedure OppStage(Mode: Integer);
Var S: LongInt; I,K,Cur,Best: Integer; Nm: String;
Begin
 If Modu=1 Then S:=GridSelSlot(GW[3])
 Else If Modu=3 Then S:=GridSelSlot(GMain)
 Else S:=GridSelSlot(GSubL);
 If (S<0) Or Not RowGet(tOP,S,RBF) Then Exit;
 Cur:=NG(tOP,RBF,'PROB');
 Best:=-1;Nm:='';
 For I:=0 To Tb[tLV]^.Slots-1 Do
  If RowGet(tLV,I,RB2) And (SG(tLV,RB2,'LST')='STAGE') Then Begin
   K:=NG(tLV,RB2,'EXTRA');
   Case Mode Of
    1: If K=100 Then Begin Best:=K;Nm:=SG(tLV,RB2,'VAL');End;
    2: If K=0 Then Begin Best:=K;Nm:=SG(tLV,RB2,'VAL');End;
    3: If (K>Cur) And ((Best<0) Or (K<Best)) Then Begin Best:=K;
      Nm:=SG(tLV,RB2,'VAL');End;
    4: If (K<Cur) And (K>0) And (K>Best) Then Begin Best:=K;Nm:=SG(tLV,RB2,
      'VAL');End;
   End;
  End;
 If Nm='' Then Exit;
 SS(tOP,RBF,'STAGE',Nm);SN(tOP,RBF,'PROB',Best);
 { statut selon l'ordre de la liste OPPST : ouverte, gagnee, perdue }
 K:=0;
 For I:=0 To Tb[tLV]^.Slots-1 Do
  If RowGet(tLV,I,RB2) And (SG(tLV,RB2,'LST')='OPPST') Then Begin
   Inc(K);
   If ((Best=100) And (K=2)) Or ((Best=0) And (K=3)) Or
      ((Best>0) And (Best<100) And (K=1)) Then SS(tOP,RBF,'STATUS',SG(tLV,RB2,
        'VAL'));
  End;
 If RowPut(tOP,S,RBF) Then ;
 TblFlush(tOP);ReloadAll;
End;

{ ---- notes, documents, liens ---- }

Procedure ToggleNoteFlag;
Var S: LongInt;
Begin
 S:=GridSelSlot(GSubR);
 If (S<0) Or Not RowGet(tNO,S,RBF) Then Exit;
 If NG(tNO,RBF,'FLAG')=0 Then SN(tNO,RBF,'FLAG',1) Else SN(tNO,RBF,'FLAG',0);
 If RowPut(tNO,S,RBF) Then ;
 TblFlush(tNO);ReloadAll;
End;

Procedure ChangeNoteType;
Var S: LongInt; Sel: Integer;
Begin
 S:=GridSelSlot(GSubR);
 If (S<0) Or Not RowGet(tNO,S,RBF) Then Exit;
 LoadList('NOTET');
 If PickN=0 Then Exit;
 Sel:=1;
 If PickList(T('Type de note~Note type~Notiztyp'),Sel) Then Begin
  If RowGet(tNO,S,RBF) Then Begin
   SS(tNO,RBF,'KIND',PickIt^[Sel]);
   If RowPut(tNO,S,RBF) Then ;
  End;
  TblFlush(tNO);ReloadAll;
 End;
End;

Procedure CopyDocPath;
Var S: LongInt;
Begin
 S:=GridSelSlot(GSubR);
 If (S>=0) And RowGet(tDO,S,RB2) Then ClipText(SG(tDO,RB2,'PATH'));
End;

Procedure OpenLinked;
Var S: LongInt; Id: LongInt;
Begin
 S:=GridSelSlot(GSubL);
 If (S<0) Or Not RowGet(tRE,S,RB2) Then Exit;
 Id:=NG(tRE,RB2,'OTHER_ID');
 If Id<=0 Then Exit;
 ShowFilter:=0;FilterSql:='';FilterName:='';
 LoadMain;GridGoto(GMain,Id);Foc:=2;
 SelectEntry(Id);
End;

{ ---- Ma journee : actions des panneaux ---- }

Procedure OpenEntryCur;
Var Id: LongInt;
Begin
 If Not NeedEntry Then Exit;
 Id:=CurId;
 SetModule(2);
 ShowFilter:=0;FilterSql:='';FilterName:='';
 LoadMain;GridGoto(GMain,Id);
 SelectEntry(Id);
End;

{ reporte l'activite choisie (1 demain, 2 une semaine, 3 lundi, 4 date) }
Procedure Postpone(Mode: Integer);
Var Sl,Base,Nd: LongInt; Dt: String; K: Integer;
Begin
 Sl:=ApptSlot;
 If (Sl<0) Or Not RowGet(tAP,Sl,RBF) Then Exit;
 Base:=NG(tAP,RBF,'AD');
 If Base<SessDate Then Base:=SessDate;
 Case Mode Of
  1: Nd:=AddDays(Base,1);
  2: Nd:=AddDays(Base,7);
  3: Begin
      K:=(8-WeekDay(SessDate)) Mod 7;
      If K=0 Then K:=7;
      Nd:=AddDays(SessDate,K);
     End;
  Else Begin
   Dt:=FmtDate(Base);
   If Not InputBox(T('Reporter~Postpone~Verschieben'),T('Nouvelle date :~New'
     +' date:~Neues Datum:'),Dt,12) Then Exit;
   If Not ParseDate(Dt,Nd) Then Begin
    Info(T('Date invalide.~Invalid date.~Ung@3ltiges Datum.'));Exit;
   End;
  End;
 End;
 If RowGet(tAP,Sl,RBF) Then Begin
  SN(tAP,RBF,'AD',Nd);
  If RowPut(tAP,Sl,RBF) Then ;
 End;
 TblFlush(tAP);ReloadAll;
End;

{ copie toutes les lignes d'une grille }
Procedure CopyAllRows(Var G: TGrid);
Var I: LongInt; S: String; J: Integer;
Begin
 ClipClear;
 For I:=1 To G.N Do
  If RowGet(G.TI,G.Sl^[I],RB2) Then Begin
   S:='';
   For J:=1 To G.NC Do Begin
    If J>1 Then S:=S+#9;
    S:=S+FmtFld(G.TI,RB2,G.CF[J]);
   End;
   ClipAdd(S);
  End;
 ClipPush;
End;

Procedure BuildWd;
Var Sel: Boolean; P: Integer;
Begin
 P:=WdPanel;
 Sel:=GW[P].N>0;
 If P In [1,2] Then Begin
  PMAdd(T('Marquer comme termin@e~Mark as done~Als erledigt markieren~Marcar'
    +' hecho~Segna come fatto'),67,Sel);
  PMAdd(T('Modifier~Edit~Bearbeiten~Editar~Modifica'),10,Sel);
  PMSub(T('Reporter~Postpone~Verschieben~Aplazar~Rinvia'),11,Sel);
  PMAdd(T('Ouvrir l''entr@ee~Open entry~Eintrag @2ffnen~Abrir entrada~Apri v'
    +'oce'),195,Sel And (CurId>0));
  PMSep;
  PMSub(T('Nouvelle activit@e~New activity~Neue Aktivit@1t'),12,True);
  PMSub(T('Contacter~Contact~Kontaktieren'),13,Sel And (CurId>0));
  PMSep;
  PMAdd(T('Dupliquer (+7 jours)~Duplicate (+7 days)~Duplizieren (+7 Tage)'
    ),127,Sel);
  PMAdd(T('Supprimer~Delete~L@3schen~Eliminar~Elimina'),11,Sel);
  PMSep;
  PMAdd(T('Copier~Copy~Kopieren~Copiar~Copia'),120,Sel);
  PMAdd(T('Coller~Paste~Einf@3gen~Pegar~Incolla'),121,ClipLines>0);
  PMAdd(T('Copier tout le panneau~Copy whole panel~Ganzes Feld kopieren'
    ),190,Sel);
  PMSep;
  PMAdd(T('Agenda de la semaine~Weekly agenda~Wochenagenda'),88,True);
  PMAdd(T('Activit@es en cours~Pending activities~Offene Aktivit@1ten'
    ),87,True);
  PMAdd('Hotlist',23,True);
  PMAdd(T('Calendrier~Calendar~Kalender~Calendario~Calendario'),24,True);
 End Else If P=3 Then Begin
  PMAdd(T('Modifier~Edit~Bearbeiten~Editar~Modifica'),10,Sel);
  PMSub(T('@Etape~Stage~Phase'),9,Sel);
  PMAdd(T('Ouvrir l''entr@ee~Open entry~Eintrag @2ffnen~Abrir entrada~Apri v'
    +'oce'),195,Sel And (CurId>0));
  PMSub(T('Contacter~Contact~Kontaktieren'),13,Sel And (CurId>0));
  PMSep;
  PMAdd(T('Nouvelle opportunit@e~New opportunity~Neue Verkaufschance'),12,True);
  PMAdd(T('Supprimer~Delete~L@3schen~Eliminar~Elimina'),11,Sel);
  PMSep;
  PMAdd(T('Copier~Copy~Kopieren~Copiar~Copia'),120,Sel);
  PMAdd(T('Copier tout le panneau~Copy whole panel~Ganzes Feld kopieren'
    ),190,Sel);
  PMSep;
  PMAdd(T('Rapport des opportunit@es~Opportunities report~Chancenbericht'
    ),83,True);
  PMAdd(T('Entonnoir des ventes~Sales pipeline~Verkaufstrichter'),84,True);
  PMAdd(T('Pr@evisions par mois~Forecast by month~Prognose pro Monat'),85,True);
  PMAdd(T('Module Opportunit@es~Opportunities module~Modul Verkaufschancen'
    ),22,True);
 End Else Begin
  PMAdd(T('Ouvrir l''entr@ee~Open entry~Eintrag @2ffnen~Abrir entrada~Apri v'
    +'oce'),195,Sel);
  PMAdd(T('Modifier l''entr@ee~Edit entry~Eintrag bearbeiten~Editar entrada~'
    +'Modifica voce'),10,Sel);
  PMSub(T('Nouveau~New~Neu~Nuevo~Nuovo'),1,Sel);
  PMSub(T('Contacter~Contact~Kontaktieren'),13,Sel);
  PMSub(T('Imprimer / rapports~Print / reports~Drucken / Berichte'),3,Sel);
  PMSep;
  PMSub(T('Copier~Copy~Kopieren~Copiar~Copia'),8,Sel);
  PMAdd(T('Copier tout le panneau~Copy whole panel~Ganzes Feld kopieren'
    ),190,Sel);
  PMSep;
  PMAdd(T('Nouvelle entr@ee~New entry~Neuer Eintrag'),1,True);
  PMAdd(T('Carnet d''adresses~Address Book~Adressbuch~Direcciones~Rubrica'
    ),21,True);
 End;
 PMSep;
 PMAdd(T('Actualiser~Refresh~Aktualisieren~Actualizar~Aggiorna'),29,True);
End;

{ ---- Bibliotheque de la societe ---- }

Function LibSlot: LongInt;
Begin
 LibSlot:=GridSelSlot(GMain);
End;

{ charge le document choisi dans RBF et son texte dans TX }
Function LibLoad(Slot: LongInt): LongInt;
Begin
 LibLoad:=0;
 If (Slot<0) Or Not RowGet(tLI,Slot,RBF) Then Exit;
 LibLoad:=GetN(tLI,RBF,1);
 TextLoad('L',GetN(tLI,RBF,1));
End;

{ cree un document a partir du texte de TX ; retourne son ID }
Function LibCreate(Const Nm: String): LongInt;
Var Id: LongInt;
Begin
 NewRow(tLI,RB2);
 SS(tLI,RB2,'NAME',Copy(Nm,1,40));SN(tLI,RB2,'DD',SessDate);
 SS(tLI,RB2,'CREATOR',UserCode);
 If LibMode=1 Then SS(tLI,RB2,'CATEGORY',LibCat);
 Id:=RowAdd(tLI,RB2);
 If Id>0 Then TextSave('L',Id);
 TblFlush(tLI);
 LibCreate:=Id;
End;

Procedure LibShow(Id: LongInt);
Begin
 ReloadAll;
 GridGoto(GMain,Id);
End;

Procedure LibView;
Var Id: LongInt; Nm: String; K,I: Integer;
Begin
 Id:=LibLoad(LibSlot);
 If Id=0 Then Exit;
 Nm:=SG(tLI,RBF,'NAME');
 If TXN=0 Then Begin TXN:=1;TX^[1]:='';End;
 If TXN+4<=MAXTXT Then Begin
  Move(TX^[1],TX^[5],TXN*SizeOf(String[78]));
  TX^[1]:=Nm;
  TX^[2]:=SG(tLI,RBF,'CATEGORY')+'  '+FmtDate(NG(tLI,RBF,'DD'))+'  '
    +SG(tLI,RBF,'CREATOR');
  TX^[3]:=SG(tLI,RBF,'DESCR');
  TX^[4]:=Rep('-',60);
  Inc(TXN,4);
 End;
 ViewText(Nm);
End;

Procedure LibCopyText;
Var I: Integer;
Begin
 If LibLoad(LibSlot)=0 Then Exit;
 ClipClear;
 For I:=1 To TXN Do ClipAdd(TX^[I]);
 ClipPush;
End;

Procedure LibNewFromClip;
Var I,N: Integer; Id: LongInt;
Begin
 ClipPull;
 N:=ClipLines;
 If N=0 Then Begin
  Info(T('Le presse-papiers est vide.~The clipboard is empty.~Die Zwischenab'
    +'lage ist leer.'));
  Exit;
 End;
 TXN:=0;
 For I:=1 To N Do TxAdd(ClipLine(I));
 Id:=LibCreate(TrimStr(ClipLine(1)));
 If Id>0 Then LibShow(Id);
End;

Procedure LibImportFile;
Var P,Nm: String; F: Text; L: String; I: Integer; Id: LongInt;
Begin
 P:='';
 If Not InputBox(T('Importer un fichier texte~Import a text file~Textdatei i'
   +'mportieren'),
   T('Fichier :~File:~Datei:'),P,70) Then Exit;
 If P='' Then Exit;
 {$I-}
 Assign(F,P);Reset(F);
 {$I+}
 If IOResult<>0 Then Begin Info(P);Exit;End;
 TXN:=0;
 While Not Eof(F) And (TXN<MAXTXT) Do Begin
  ReadLn(F,L);
  TxAdd(L);
 End;
 Close(F);
 I:=Length(P);
 While (I>0) And (P[I]<>'\') And (P[I]<>'/') Do Dec(I);
 Nm:=Copy(P,I+1,40);
 Id:=LibCreate(Nm);
 If Id>0 Then Begin
  If RowGet(tLI,RowFind(tLI,Id),RBF) Then Begin
   SS(tLI,RBF,'PATH',Copy(P,1,60));
   If RowPut(tLI,RowFind(tLI,Id),RBF) Then ;
   TblFlush(tLI);
  End;
  LibShow(Id);
 End;
End;

Procedure LibProps;
Begin
 EditSlot(tLI,LibSlot,'NAME,CATEGORY,DESCR,PATH','',
   T('Propri@et@es du document~Document properties~Dokumenteigenschaften'));
End;

{ joint une copie du document a l'entree courante }
Procedure LibToEntry;
Var Id,Did: LongInt; Nm: String;
Begin
 Id:=LibLoad(LibSlot);
 If Id=0 Then Exit;
 If CurId<=0 Then CurId:=PickEntryDlg;
 If CurId<=0 Then Exit;
 Nm:=SG(tLI,RBF,'NAME');
 NewRow(tDO,RB2);
 SN(tDO,RB2,'ENTRY_ID',CurId);SS(tDO,RB2,'NAME',Nm);SS(tDO,RB2,'KIND','D');
 SS(tDO,RB2,'PATH',T('Biblioth@eque~Library~Bibliothek'));
 SN(tDO,RB2,'DD',SessDate);SS(tDO,RB2,'CREATOR',UserCode);
 Did:=RowAdd(tDO,RB2);
 If Did>0 Then TextSave('D',Did);
 TblFlush(tDO);
 TXN:=1;TX^[1]:=T('Document joint : ~Document attached: ~Dokument angeh@1ngt'
   +': ')+Nm;
 If AddNote(CurId,NoteKindName(0),'',False)=0 Then ;
 Touch(CurId);
 Info(Nm+' -> '+EntryName(CurId));
End;

Procedure LibEmail;
Var Id: LongInt;
Begin
 Id:=LibLoad(LibSlot);
 If Id=0 Then Exit;
 If CurId<=0 Then CurId:=PickEntryDlg;
 If CurId<=0 Then Exit;
 MailSubj:=SG(tLI,RBF,'NAME');MailDoc:=Id;
 ActEmail;
 MailSubj:='';MailDoc:=0;
End;

Procedure LibToTemplate;
Var Id,Tid: LongInt;
Begin
 Id:=LibLoad(LibSlot);
 If Id=0 Then Exit;
 NewRow(tTP,RB2);
 SS(tTP,RB2,'NAME',SG(tLI,RBF,'NAME'));SS(tTP,RB2,'KIND','L');
 SS(tTP,RB2,'SUBJ',SG(tLI,RBF,'NAME'));
 Tid:=RowAdd(tTP,RB2);
 If Tid>0 Then TextSave('T',Tid);
 TblFlush(tTP);
 Info(T('Mod@ele de lettre cr@e@e.~Letter template created.~Briefvorlage ers'
   +'tellt.'));
End;

Procedure LibPrint;
Begin
 If LibLoad(LibSlot)=0 Then Exit;
 If TXN=0 Then Begin TXN:=1;TX^[1]:='';End;
 PrintText;
End;

Procedure LibExport;
Var F: Text; Nm: String; I: Integer;
Begin
 If LibLoad(LibSlot)=0 Then Exit;
 Nm:='';
 For I:=1 To Length(SG(tLI,RBF,'NAME')) Do
  If (Length(Nm)<8) And (UpCase(SG(tLI,RBF,'NAME')[I]) In ['A'..'Z','0'..'9'])
    Then
   Nm:=Nm+UpCase(SG(tLI,RBF,'NAME')[I]);
 If Nm='' Then Nm:='DOCUMENT';
 Nm:=Nm+'.TXT';
 If Not InputBox(T('Exporter~Export~Exportieren'),T('Fichier de sortie :~Out'
   +'put file:~Ausgabedatei:'),Nm,40) Then Exit;
 {$I-}
 Assign(F,Nm);Rewrite(F);
 {$I+}
 If IOResult<>0 Then Begin Info(Nm);Exit;End;
 For I:=1 To TXN Do WriteLn(F,TX^[I]);
 Close(F);
 Info(Nm);
End;

Procedure LibCopyRow;
Begin
 ClipText(GridRowText(GMain));
End;

Procedure LibCopyName;
Begin
 If LibLoad(LibSlot)<>0 Then ClipText(SG(tLI,RBF,'NAME'));
End;

Procedure LibDup;
Var Id,N: LongInt; I: Integer;
Begin
 Id:=LibLoad(LibSlot);
 If Id=0 Then Exit;
 NewRow(tLI,RB2);
 SS(tLI,RB2,'NAME',Copy(SG(tLI,RBF,'NAME'),1,35)+' (2)');
 SS(tLI,RB2,'CATEGORY',SG(tLI,RBF,'CATEGORY'));SS(tLI,RB2,'DESCR',SG(tLI,RBF,
   'DESCR'));
 SS(tLI,RB2,'PATH',SG(tLI,RBF,'PATH'));SN(tLI,RB2,'DD',SessDate);
 SS(tLI,RB2,'CREATOR',UserCode);
 N:=RowAdd(tLI,RB2);
 If N>0 Then Begin TextSave('L',N);TblFlush(tLI);LibShow(N);End;
End;

{ choisit une categorie parmi celles qui existent (ou une nouvelle) }
Function LibCatPick(Var Res: String): Boolean;
Var I,J,Sel: Integer; C: String; Dup: Boolean;
Begin
 LibCatPick:=False;
 PickN:=0;
 For I:=0 To Tb[tLI]^.Slots-1 Do
  If RowGet(tLI,I,RB2) Then Begin
   C:=SG(tLI,RB2,'CATEGORY');
   Dup:=C='';
   For J:=1 To PickN Do If PickIt^[J]=C Then Dup:=True;
   If Not Dup Then PickAdd(C);
  End;
 PickAdd(T('(Nouvelle cat@egorie...)~(New category...)~(Neue Kategorie...)'));
 Sel:=1;
 If Not PickList(T('Cat@egorie~Category~Kategorie'),Sel) Then Exit;
 If Sel=PickN Then Begin
  C:='';
  If Not InputBox(T('Cat@egorie~Category~Kategorie'),T('Nom :~Name:~Name:'
    ),C,20) Then Exit;
  Res:=C;
 End Else Res:=PickIt^[Sel];
 LibCatPick:=Res<>'';
End;

Procedure LibSetCat;
Var C: String; S: LongInt;
Begin
 S:=LibSlot;
 If (S<0) Or Not LibCatPick(C) Then Exit;
 If RowGet(tLI,S,RBF) Then Begin
  SS(tLI,RBF,'CATEGORY',C);
  If RowPut(tLI,S,RBF) Then ;
 End;
 TblFlush(tLI);ReloadAll;
End;

Procedure LibFilterCat;
Var C: String;
Begin
 If Not LibCatPick(C) Then Exit;
 LibMode:=1;LibCat:=C;
 ReloadAll;
End;

Procedure LibClear;
Begin
 LibMode:=0;LibCat:='';NLibIds:=0;
 ReloadAll;
End;

{ recherche un texte dans les noms, descriptions et contenus }
Procedure LibSearch;
Var Q: String; I: LongInt; Id: LongInt; J: Integer; Dup: Boolean;
 Procedure Add(V: LongInt);
 Var K: Integer;
 Begin
  For K:=1 To NLibIds Do If LibIds[K]=V Then Exit;
  If NLibIds<200 Then Begin Inc(NLibIds);LibIds[NLibIds]:=V;End;
 End;
Begin
 Q:='';
 If Not InputBox(T('Rechercher dans la biblioth@eque~Search the library~Bibl'
   +'iothek durchsuchen'),
   T('Texte :~Text:~Text:'),Q,40) Then Exit;
 If Q='' Then Exit;
 NLibIds:=0;
 For I:=0 To Tb[tLI]^.Slots-1 Do
  If RowGet(tLI,I,RB2) Then
   If HasStr(SG(tLI,RB2,'NAME'),Q) Or HasStr(SG(tLI,RB2,'DESCR'),Q) Then
    Add(GetN(tLI,RB2,1));
 For I:=0 To Tb[tTX]^.Slots-1 Do
  If RowGet(tTX,I,RB2) Then
   If (SG(tTX,RB2,'OWN')='L') And HasStr(SG(tTX,RB2,'LINE'),Q) Then
    Add(NG(tTX,RB2,'OWNID'));
 LibMode:=2;LibCat:=Copy(Q,1,20);
 ReloadAll;
End;

{ ---- sous-menus ---- }

Procedure BuildSub(Sid: Integer);
Begin
 PMBase:=PMN;
 Case Sid Of
  1: Begin
      PMAdd(T('Nouvelle entr@ee~New entry~Neuer Eintrag'),1,True);
      PMAdd(T('Nouveau contact~New contact~Neuer Kontakt'),17,CurId>0);
      PMAdd(T('Nouvelle note~New note~Neue Notiz'),51,CurId>0);
      PMAdd(T('Nouvelle opportunit@e~New opportunity~Neue Verkaufschance'
        ),66,CurId>0);
      PMAdd(T('Nouvelle commande~New order~Neuer Auftrag'),187,CurId>0);
      PMAdd(T('Ins@erer un fichier...~Insert a file...~Datei einf@3gen...'
        ),61,CurId>0);
      PMAdd(T('Ins@erer un hyperlien...~Insert a hyperlink...~Hyperlink einf'
        +'@3gen...'),62,CurId>0);
     End;
  2: Begin
      PMAdd(T('Courriel...~Email...~E-Mail...'),50,CurId>0);
      PMAdd(T('Lettre...~Letter...~Brief...'),52,CurId>0);
      PMAdd(T('T@el@copie...~Fax...~Fax...'),53,CurId>0);
      PMAdd(T('Document...~Document...~Dokument...'),54,CurId>0);
      PMSep;
      PMAdd(T('Passer un appel...~Make a call...~Anruf...'),55,CurId>0);
      PMAdd(T('Recevoir un appel...~Receive a call...~Anruf empfangen...'
        ),56,CurId>0);
      PMAdd(T('R@eunion...~Meeting...~Besprechung...'),57,CurId>0);
      PMAdd(T('@A faire...~To-do...~Aufgabe...'),58,CurId>0);
      PMAdd(T('Appel t@el@ephonique (rdv)...~Phone call (appt)...~Anruf (Ter'
        +'min)...'),59,CurId>0);
      PMSep;
      PMAdd(T('Plan d''action...~Action plan...~Aktionsplan...'),60,CurId>0);
      PMAdd(T('Chronom@etrer une t@qche...~Time a task...~Aufgabe zeiten...'
        ),65,CurId>0);
     End;
  3: Begin
      PMAdd(T('Enveloppe~Envelope~Umschlag'),63,CurId>0);
      PMAdd(T('@Etiquettes (marqu@ees)~Labels (marked)~Etiketten (markierte)'
        ),64,True);
      PMAdd(T('Fiche de l''entr@ee~Entry card~Eintragsblatt'),170,CurId>0);
      PMAdd(T('Notes de l''entr@ee~Entry notes~Eintragsnotizen'),86,CurId>0);
      PMAdd(T('Liste du carnet~Address book list~Adressbuchliste'),80,True);
      PMAdd(T('Liste t@el@ephonique~Phone list~Telefonliste'),82,True);
     End;
  4: Begin
      PMAdd(T('Marquer / d@emarquer~Mark / unmark~Markieren'),14,CurId>0);
      PMAdd(T('Tout marquer~Mark all~Alle markieren'),15,True);
      PMAdd(T('Tout d@emarquer~Unmark all~Alle demarkieren'),16,NMark>0);
      PMAdd(T('Inverser les marques~Invert marks~Markierung umkehren'
        ),130,True);
      PMSep;
      PMAdd(T('Marquer m@eme ville~Mark same city~Gleiche Stadt markieren'
        ),131,CurId>0);
      PMAdd(T('Marquer m@eme statut~Mark same status~Gleichen Status markier'
        +'en'),132,CurId>0);
      PMAdd(T('Marquer m@eme territoire~Mark same territory~Gleiches Gebiet '
        +'markieren'),148,CurId>0);
     End;
  5: Begin
      If NMark>0 Then PMAdd('('+IntStr(NMark)+' '+T('marqu@ees~marked~markie'
        +'rt')+')',0,False);
      PMAdd(T('Statut...~Status...~Status...'),133,CurId>0);
      PMAdd(T('Source...~Source...~Quelle...'),134,CurId>0);
      PMAdd(T('Territoire...~Territory...~Gebiet...'),135,CurId>0);
      PMAdd(T('Responsable...~Owner...~Betreuer...'),136,CurId>0);
      PMSep;
      PMAdd(T('Soci@et@e <-> individu~Company <-> individual~Firma <-> Perso'
        +'n'),137,CurId>0);
      PMAdd(T('Personnel <-> public~Personal <-> public~Pers@2nlich <-> @2ff'
        +'entlich'),138,CurId>0);
     End;
  6: Begin
      PMAdd(T('M@eme ville~Same city~Gleiche Stadt'),140,CurId>0);
      PMAdd(T('M@eme province / @etat~Same state~Gleiches Bundesland'
        ),141,CurId>0);
      PMAdd(T('M@eme statut~Same status~Gleicher Status'),142,CurId>0);
      PMAdd(T('M@eme source~Same source~Gleiche Quelle'),143,CurId>0);
      PMAdd(T('M@eme territoire~Same territory~Gleiches Gebiet'),144,CurId>0);
      PMAdd(T('M@eme responsable~Same owner~Gleicher Betreuer'),145,CurId>0);
      PMSep;
      PMAdd(T('Entr@ees marqu@ees~Marked entries~Markierte Eintr@1ge'
        ),146,NMark>0);
      PMAdd(T('Tout afficher~Show all~Alle anzeigen'),45,True);
     End;
  7: Begin
      PMAdd(T('Nom~Name~Name'),150,True);
      PMAdd(T('Ville~City~Stadt'),151,True);
      PMAdd(T('Statut~Status~Status'),154,True);
      PMAdd(T('Derni@ere modification~Last modified~Zuletzt ge@1ndert'
        ),152,True);
      PMAdd(T('Date de cr@eation~Created~Erstellt'),153,True);
     End;
  8: Begin
      PMAdd(T('Coordonn@ees compl@etes~Full details~Alle Daten'),120,CurId>0);
      PMAdd(T('Nom~Name~Name'),160,CurId>0);
      PMAdd(T('T@el@ephone~Phone~Telefon'),161,CurId>0);
      PMAdd(T('Courriel~Email~E-Mail'),162,CurId>0);
      PMAdd(T('Adresse~Address~Adresse'),163,CurId>0);
      PMAdd(T('Site Web~Web site~Webseite'),164,CurId>0);
      PMAdd(T('Ligne de la liste~List row~Listenzeile'),165,CurId>0);
     End;
  9: Begin
      PMAdd(T('Gagn@ee~Won~Gewonnen'),177,True);
      PMAdd(T('Perdue~Lost~Verloren'),178,True);
      PMAdd(T('@Etape suivante~Next stage~N@1chste Phase'),179,True);
      PMAdd(T('@Etape pr@ec@edente~Previous stage~Vorherige Phase'),180,True);
     End;
  11: Begin
      PMAdd(T('Demain~Tomorrow~Morgen'),191,True);
      PMAdd(T('Dans une semaine~In one week~In einer Woche'),192,True);
      PMAdd(T('Lundi prochain~Next Monday~N@1chsten Montag'),193,True);
      PMAdd(T('Choisir une date...~Pick a date...~Datum w@1hlen...'),194,True);
     End;
  12: Begin
      PMAdd(T('R@eunion...~Meeting...~Besprechung...'),57,True);
      PMAdd(T('Appel...~Phone call...~Anruf...'),59,True);
      PMAdd(T('@A faire...~To-do...~Aufgabe...'),58,True);
      PMAdd(T('Plan d''action...~Action plan...~Aktionsplan...'),60,CurId>0);
     End;
  13: Begin
      PMAdd(T('Courriel...~Email...~E-Mail...'),50,CurId>0);
      PMAdd(T('Passer un appel...~Make a call...~Anruf...'),55,CurId>0);
      PMAdd(T('Note...~Note...~Notiz...'),51,CurId>0);
      PMAdd(T('Lettre...~Letter...~Brief...'),52,CurId>0);
      PMAdd(T('R@eunion...~Meeting...~Besprechung...'),57,CurId>0);
     End;
  14: Begin
      PMAdd(T('Nouveau document...~New document...~Neues Dokument...'),12,True);
      PMAdd(T('@A partir du presse-papiers~From clipboard~Aus Zwischenablage'
        ),201,ClipLines>0);
      PMAdd(T('Importer un fichier texte...~Import a text file...~Textdatei '
        +'importieren...'),202,True);
     End;
  15: Begin
      PMAdd(T('Joindre @a l''entr@ee courante~Attach to current entry~An akt'
        +'uellen Eintrag anh@1ngen'),204,True);
      PMAdd(T('Envoyer par courriel...~Send by email...~Per E-Mail senden...'
        ),205,True);
      PMAdd(T('Utiliser comme mod@ele de lettre~Use as letter template~Als B'
        +'riefvorlage'),206,True);
     End;
  16: Begin
      PMAdd(T('Le texte~The text~Den Text'),120,True);
      PMAdd(T('Le nom~The name~Den Namen'),209,True);
      PMAdd(T('La ligne de la liste~The list row~Die Listenzeile'),219,True);
     End;
  17: Begin
      PMAdd(T('D@efinir la cat@egorie...~Set category...~Kategorie setzen...'
        ),211,True);
      PMAdd(T('Filtrer par cat@egorie...~Filter by category...~Nach Kategori'
        +'e filtern...'),212,True);
      PMAdd(T('Tout afficher~Show all~Alle anzeigen'),213,LibMode>0);
     End;
  18: Begin
      PMAdd(T('Nom~Name~Name'),214,True);
      PMAdd(T('Cat@egorie~Category~Kategorie'),215,True);
      PMAdd(T('Date (r@ecent d''abord)~Date (newest first)~Datum (neueste zu'
        +'erst)'),216,True);
      PMAdd(T('Cr@eateur~Creator~Ersteller'),217,True);
     End;
  10: Begin
      PMAdd(T('Nom~Name~Name'),174,True);
      PMAdd(T('T@el@ephone~Phone~Telefon'),175,True);
      PMAdd(T('Courriel~Email~E-Mail'),176,True);
     End;
 End;
End;

{ ---- contenu du menu contextuel selon le module et le volet ---- }

Procedure BuildContext;
Var Sel,HasClip: Boolean;
Begin
 PMN:=0;PMBase:=0;
 ClipPull;
 HasClip:=ClipLines>0;
 Case Modu Of
  1: BuildWd;
  7: Begin
      Sel:=GMain.N>0;
      PMAdd(T('Ouvrir (lire)~Open (read)~@2ffnen (lesen)~Abrir (leer)~Apri ('
        +'leggi)'),200,Sel);
      PMAdd(T('Modifier le texte~Edit text~Text bearbeiten~Editar texto~Modi'
        +'fica testo'),10,Sel);
      PMAdd(T('Propri@et@es...~Properties...~Eigenschaften...~Propiedades...'
        +'~Propriet@q...'),203,Sel);
      PMSub(T('Nouveau~New~Neu~Nuevo~Nuovo'),14,True);
      PMSep;
      PMSub(T('Envoyer @a~Send to~Senden an'),15,Sel);
      PMSub(T('Copier~Copy~Kopieren~Copiar~Copia'),16,Sel);
      PMAdd(T('Coller comme nouveau document~Paste as new document~Als neues'
        +' Dokument einf@3gen'),201,HasClip);
      PMAdd(T('Dupliquer~Duplicate~Duplizieren~Duplicar~Duplica'),210,Sel);
      PMSep;
      PMSub(T('Cat@egorie~Category~Kategorie~Categor@ia~Categoria'),17,True);
      PMSub(T('Trier par~Sort by~Sortieren nach'),18,True);
      PMAdd(T('Rechercher dans le texte...~Search text...~Text suchen...'
        ),218,True);
      PMSep;
      PMAdd(T('Exporter vers un fichier...~Export to a file...~In Datei expo'
        +'rtieren...'),208,Sel);
      PMAdd(T('Imprimer...~Print...~Drucken...~Imprimir...~Stampa...'),207,Sel);
      PMSep;
      PMAdd(T('Supprimer~Delete~L@3schen~Eliminar~Elimina'),11,Sel);
      PMAdd(T('Actualiser~Refresh~Aktualisieren~Actualizar~Aggiorna'),29,True);
     End;
  3: Begin
      Sel:=GMain.N>0;
      PMAdd(T('Modifier~Edit~Bearbeiten~Editar~Modifica'),10,Sel);
      PMSub(T('@Etape~Stage~Phase'),9,Sel);
      PMAdd(T('Ouvrir l''entr@ee~Open entry~Eintrag @2ffnen~Abrir entrada~Ap'
        +'ri voce'),195,Sel);
      PMSub(T('Contacter~Contact~Kontaktieren'),13,Sel);
      PMSep;
      PMAdd(T('Nouvelle opportunit@e~New opportunity~Neue Verkaufschance'
        ),12,True);
      PMAdd(T('Supprimer~Delete~L@3schen~Eliminar~Elimina'),11,Sel);
      PMSep;
      PMAdd(T('Copier~Copy~Kopieren~Copiar~Copia'),120,Sel);
      PMAdd(T('Copier tout~Copy all~Alles kopieren'),196,Sel);
      PMSep;
      PMAdd(T('Rapport des opportunit@es~Opportunities report~Chancenbericht'
        ),83,True);
      PMAdd(T('Entonnoir des ventes~Sales pipeline~Verkaufstrichter'),84,True);
      PMAdd(T('Pr@evisions par mois~Forecast by month~Prognose pro Monat'
        ),85,True);
      PMSep;
      PMAdd(T('Actualiser~Refresh~Aktualisieren~Actualizar~Aggiorna'),29,True);
     End;
  5: Begin
      Sel:=GSubR.N>0;
      PMAdd(T('Nouvelle r@eunion~New meeting~Neue Besprechung~Nueva reuni@on'
        +'~Nuova riunione'),57,True);
      PMAdd(T('Nouvel appel~New phone call~Neuer Anruf~Nueva llamada~Nuova c'
        +'hiamata'),59,True);
      PMAdd(T('Nouvelle t@qche~New to-do~Neue Aufgabe~Nueva tarea~Nuova atti'
        +'vit@q'),58,True);
      PMAdd(T('Plan d''action...~Action plan...~Aktionsplan...~Plan de acci'
        +'@on...~Piano d''azione...'),60,True);
      PMSep;
      PMAdd(T('Modifier~Edit~Bearbeiten~Editar~Modifica'),10,Sel);
      PMAdd(T('Marquer comme termin@e~Mark as done~Als erledigt markieren~Ma'
        +'rcar hecho~Segna come fatto'),67,Sel);
      PMSub(T('Reporter~Postpone~Verschieben~Aplazar~Rinvia'),11,Sel);
      PMAdd(T('Dupliquer (+7 jours)~Duplicate (+7 days)~Duplizieren (+7 Tage'
        +')~Duplicar (+7 d@ias)~Duplica (+7 giorni)'),127,Sel);
      PMAdd(T('Ouvrir l''entr@ee~Open entry~Eintrag @2ffnen~Abrir entrada~Ap'
        +'ri voce'),195,Sel And (CurId>0));
      PMSub(T('Contacter~Contact~Kontaktieren'),13,Sel And (CurId>0));
      PMAdd(T('Supprimer~Delete~L@3schen~Eliminar~Elimina'),11,Sel);
      PMSep;
      PMAdd(T('Copier~Copy~Kopieren~Copiar~Copia'),120,Sel);
      PMAdd(T('Coller~Paste~Einf@3gen~Pegar~Incolla'),121,HasClip);
      PMSep;
      PMAdd(T('Aujourd''hui~Today~Heute~Hoy~Oggi'),122,True);
      PMAdd(T('Mois pr@ec@edent~Previous month~Vormonat~Mes anterior~Mese pr'
        +'ecedente'),123,True);
      PMAdd(T('Mois suivant~Next month~N@1chster Monat~Mes siguiente~Mese su'
        +'ccessivo'),124,True);
      PMAdd(T('Aller @a une date...~Go to date...~Gehe zu Datum...~Ir a fech'
        +'a...~Vai a data...'),47,True);
      PMSep;
      PMAdd(T('Agenda de la semaine~Weekly agenda~Wochenagenda~Agenda semana'
        +'l~Agenda settimanale'),88,True);
      PMAdd(T('Activit@es en cours~Pending activities~Offene Aktivit@1ten~Ac'
        +'tividades~Attivit@q'),87,True);
     End;
  2,8: Begin
      If Foc=2 Then Begin
       Sel:=(GMain.N>0) And (CurId>0);
       PMAdd(T('Modifier l''entr@ee~Edit entry~Eintrag bearbeiten~Editar ent'
         +'rada~Modifica voce'),10,Sel);
       PMSub(T('Nouveau~New~Neu~Nuevo~Nuovo'),1,True);
       PMSub(T('Actions~Actions~Aktionen~Acciones~Azioni'),2,Sel);
       PMSub(T('Imprimer / rapports~Print / reports~Drucken / Berichte'
         ),3,True);
       PMSep;
       PMSub(T('Marquer~Mark~Markieren~Marcar~Segna'),4,True);
       PMSub(T('D@efinir~Set~Setzen~Definir~Imposta'),5,Sel);
       PMSub(T('Filtrer par~Filter by~Filtern nach'),6,Sel);
       PMSub(T('Trier par~Sort by~Sortieren nach'),7,True);
       PMSep;
       PMSub(T('Copier~Copy~Kopieren~Copiar~Copia'),8,Sel);
       PMAdd(T('Coller en note~Paste as note~Als Notiz einf@3gen~Pegar como '
         +'nota~Incolla come nota'),121,HasClip And Sel);
       PMSep;
       PMAdd(T('Dupliquer~Duplicate~Duplizieren~Duplicar~Duplica'),13,Sel);
       PMAdd(T('Fusionner avec...~Merge with...~Zusammenf@3hren mit...'
         ),166,Sel);
       PMAdd(T('Lier @a une entr@ee...~Link to an entry...~Mit Eintrag verkn'
         +'@3pfen...'),167,Sel);
       PMAdd(T('Exporter les marqu@ees (CSV)~Export marked (CSV)~Markierte e'
         +'xportieren (CSV)'),169,NMark>0);
       PMSep;
       PMAdd(T('Supprimer~Delete~L@3schen~Eliminar~Elimina'),11,Sel);
       If NMark>0 Then
        PMAdd(T('Supprimer les marqu@ees~Delete marked~Markierte l@3schen'
          ),168,True);
       PMSep;
       PMAdd(T('Rechercher...~Find...~Suchen...~Buscar...~Cerca...'),40,True);
       PMAdd(T('Recherche avanc@ee...~Advanced search...~Erweiterte Suche...'
         ),41,True);
       PMAdd(T('Trouver les doublons~Find duplicates~Duplikate suchen'
         ),46,True);
      End Else If Foc=3 Then Begin
       Sel:=GSubL.N>0;
       Case TabL Of
        1: Begin
            PMAdd(T('Nouveau contact~New contact~Neuer Kontakt'),12,CurId>0);
            PMAdd(T('Modifier~Edit~Bearbeiten'),10,Sel);
            PMAdd(T('D@efinir comme principal~Set as primary~Als Hauptkontak'
              +'t'),171,Sel);
            PMSep;
            PMAdd(T('Courriel au contact...~Email contact...~E-Mail an Konta'
              +'kt...'),172,Sel);
            PMAdd(T('Appeler le contact...~Call contact...~Kontakt anrufen..'
              +'.'),173,Sel);
            PMAdd(T('Lettre...~Letter...~Brief...'),52,CurId>0);
            PMSep;
            PMSub(T('Copier~Copy~Kopieren'),10,Sel);
            PMAdd(T('Copier la ligne~Copy row~Zeile kopieren'),120,Sel);
            PMSep;
            PMAdd(T('Supprimer~Delete~L@3schen'),11,Sel);
           End;
        2: Begin
            PMAdd(T('Nouvelle opportunit@e~New opportunity~Neue Verkaufschan'
              +'ce'),12,CurId>0);
            PMAdd(T('Modifier~Edit~Bearbeiten'),10,Sel);
            PMSub(T('@Etape~Stage~Phase'),9,Sel);
            PMSep;
            PMAdd(T('Copier la ligne~Copy row~Zeile kopieren'),120,Sel);
            PMAdd(T('Supprimer~Delete~L@3schen'),11,Sel);
            PMSep;
            PMAdd(T('Rapport des opportunit@es~Opportunities report~Chancenb'
              +'ericht'),83,True);
           End;
        Else Begin
            PMAdd(T('Lier @a une entr@ee...~Link to an entry...~Verkn@3pfen.'
              +'..'),12,CurId>0);
            PMAdd(T('Ouvrir l''entr@ee li@ee~Open linked entry~Verkn@3pften '
              +'Eintrag @2ffnen'),181,Sel);
            PMAdd(T('Modifier la relation~Edit relationship~Beziehung bearbe'
              +'iten'),10,Sel);
            PMAdd(T('Supprimer~Delete~L@3schen'),11,Sel);
           End;
       End;
      End Else Begin
       Sel:=GSubR.N>0;
       Case TabR Of
        1: Begin
            PMAdd(T('Nouvelle note...~New note...~Neue Notiz...'),12,CurId>0);
            PMAdd(T('Modifier la note~Edit note~Notiz bearbeiten'),10,Sel);
            PMAdd(T('Important (on/off)~Flag (on/off)~Wichtig (an/aus)'
              ),182,Sel);
            PMAdd(T('Changer le type...~Change type...~Typ @1ndern...'
              ),183,Sel);
            PMSep;
            PMAdd(T('Copier le texte~Copy text~Text kopieren'),120,Sel);
            PMAdd(T('Coller en nouvelle note~Paste as new note~Als neue Noti'
              +'z einf@3gen'),121,HasClip And (CurId>0));
            PMSep;
            PMAdd(T('Afficher le type...~Show type...~Typ anzeigen...'
              ),184,True);
            PMAdd(T('Filtrer la p@eriode...~Filter period...~Zeitraum filter'
              +'n...'),185,True);
            PMAdd(T('Rapport des notes~Notes report~Notizbericht'),86,CurId>0);
            PMSep;
            PMAdd(T('Supprimer~Delete~L@3schen'),11,Sel);
           End;
        3: Begin
            PMAdd(T('Ins@erer un fichier...~Insert a file...~Datei einf@3gen'
              +'...'),61,CurId>0);
            PMAdd(T('Ins@erer un hyperlien...~Insert a hyperlink...~Hyperlin'
              +'k einf@3gen...'),62,CurId>0);
            PMAdd(T('Modifier~Edit~Bearbeiten'),10,Sel);
            PMAdd(T('Copier le chemin~Copy path~Pfad kopieren'),186,Sel);
            PMAdd(T('Supprimer~Delete~L@3schen'),11,Sel);
           End;
        5: Begin
            PMAdd(T('Nouvelle commande...~New order...~Neuer Auftrag...'
              ),12,CurId>0);
            PMAdd(T('Lignes de la commande~Order lines~Auftragspositionen'
              ),10,Sel);
            PMAdd(T('Copier la ligne~Copy row~Zeile kopieren'),120,Sel);
            PMAdd(T('Supprimer~Delete~L@3schen'),11,Sel);
           End;
        Else Begin
            PMAdd(T('Modifier~Edit~Bearbeiten'),10,CurId>0);
            PMAdd(T('Actualiser~Refresh~Aktualisieren'),29,True);
           End;
       End;
      End;
     End;
  4: Begin
      Sel:=GMain.N>0;
      PMAdd(T('Marquer comme termin@e~Mark as done~Als erledigt markieren~Ma'
        +'rcar hecho~Segna come fatto'),67,Sel);
      PMAdd(T('Modifier~Edit~Bearbeiten~Editar~Modifica'),10,Sel);
      PMSub(T('Reporter~Postpone~Verschieben~Aplazar~Rinvia'),11,Sel);
      PMAdd(T('Dupliquer (+7 jours)~Duplicate (+7 days)~Duplizieren (+7 Tage'
        +')~Duplicar (+7 d@ias)~Duplica (+7 giorni)'),127,Sel);
      PMAdd(T('Ouvrir l''entr@ee~Open entry~Eintrag @2ffnen~Abrir entrada~Ap'
        +'ri voce'),195,Sel And (CurId>0));
      PMSub(T('Contacter~Contact~Kontaktieren'),13,Sel And (CurId>0));
      PMAdd(T('Supprimer~Delete~L@3schen~Eliminar~Elimina'),11,Sel);
      PMSep;
      PMAdd(T('Nouveau~New~Neu~Nuevo~Nuovo'),12,True);
      PMAdd(T('Copier~Copy~Kopieren~Copiar~Copia'),120,Sel);
      PMAdd(T('Coller~Paste~Einf@3gen~Pegar~Incolla'),121,HasClip);
      PMSep;
      PMAdd(T('Activit@es en cours~Pending activities~Offene Aktivit@1ten~Ac'
        +'tividades~Attivit@q'),87,True);
      PMAdd(T('Actualiser~Refresh~Aktualisieren~Actualizar~Aggiorna'),29,True);
     End;
  Else Begin
      If (Modu=9) And (Foc=3) Then Sel:=GSubL.N>0 Else Sel:=GMain.N>0;
      PMAdd(T('Nouveau~New~Neu~Nuevo~Nuovo'),12,True);
      PMAdd(T('Modifier~Edit~Bearbeiten~Editar~Modifica'),10,Sel);
      PMAdd(T('Supprimer~Delete~L@3schen~Eliminar~Elimina'),11,Sel);
      PMSep;
      PMAdd(T('Copier~Copy~Kopieren~Copiar~Copia'),120,Sel);
      PMSep;
      PMAdd(T('Actualiser~Refresh~Aktualisieren~Actualizar~Aggiorna'),29,True);
     End;
 End;
End;


{ ====================================================================== }
{                       ECRAN D'ACCUEIL                                  }
{ ====================================================================== }
{ L'image occupe tout l'ecran : sa taille suit la definition obtenue
  (640x480 par defaut, davantage avec -maxscreen).                         }

Const
 NNET = 600;
 NEDG = 1800;

Var
 UiReady  : Boolean;
 SpFoc    : Integer;
 SeedKind : Integer;           { 0 rien, 1 base vide, 2 exemple }
 DirGiven : Boolean;
 GfxOn    : Boolean;
 NetN     : Integer;
 NetX,NetY: Array[1..NNET] Of Integer;
 NetA,NetB: Array[1..NEDG] Of Integer;
 NetE     : Integer;
 NetOk    : Boolean;
 Seed     : LongInt;
 CfgNew   : String[40];
 J_       : Integer;
 { geometrie de l'accueil }
 SpS      : Integer;           { echelle en % (100 = 640x480) }
 BX1,BY1,BX2,BY2 : Integer;    { cadre de la banniere }
 BtnY,BtnW : Integer;
 AbtOn    : Boolean;           { banniere reduite dans la boite A propos }
 AbtX1,AbtY1,AbtX2,AbtY2 : Integer;

Function Rnd(M: Integer): Integer;
Begin
 Seed:=(Seed*25173+13849) And 65535;
 Rnd:=Integer((Seed Div 7) Mod M);
End;

Function Sz(Base,Cap: Integer): Integer;
Var V: Integer;
Begin
 V:=(Base*SpS+50) Div 100;
 If V<1 Then V:=1;
 If V>Cap Then V:=Cap;
 Sz:=V;
End;

Procedure SplashGeom;
Var A,B: Integer;
Begin
 If AbtOn Then Begin
  SpS:=60;BX1:=AbtX1;BY1:=AbtY1;BX2:=AbtX2;BY2:=AbtY2;
  Exit;
 End;
 A:=SCR_W*100 Div 640;B:=SCR_H*100 Div 480;
 If A<B Then SpS:=A Else SpS:=B;
 If SpS<100 Then SpS:=100;
 BX1:=20;BX2:=SCR_W-21;
 BY1:=24+8*Sz(3,6);
 BY2:=SCR_H-142;
 BtnY:=SCR_H-124;
 BtnW:=(SCR_W-38) Div 3;
End;

{ centre du monogramme et rayon }
Function MedY: Integer;
Begin
 MedY:=BY1+(BY2-BY1)*22 Div 100;
End;

Function MedR: Integer;
Begin
 MedR:=44*SpS Div 100;
End;

Function NameY: Integer;
Begin
 NameY:=BY1+(BY2-BY1)*43 Div 100;
End;

Function TagY: Integer;
Begin
 TagY:=NameY+8*Sz(5,10)+6*SpS Div 100;
End;

Function InZone(X,Y: Integer): Boolean;
Var R: LongInt;
Begin
 R:=MedR+8;
 InZone:=(Sqr(LongInt(X)-SCR_W Div 2)+Sqr(LongInt(Y)-MedY)<R*R) Or
   InBox(X,Y,BX1+16,NameY-8,BX2-16,TagY+8*Sz(2,6)+8);
End;

{ reseau de points lumineux relies par des lignes dorees }
Procedure NetBuild;
Var N,I,J,B1,B2,B3: Integer; D,D1,D2,D3,Lim: LongInt;
Begin
 SplashGeom;
 NetN:=Integer(240*LongInt(BX2-BX1)*(BY2-BY1) Div (590*290));
 If NetN>NNET Then NetN:=NNET;
 If NetN<60 Then NetN:=60;
 Lim:=6400*LongInt(SpS)*SpS Div 10000;
 Seed:=12345;N:=0;
 While N<NetN Do Begin
  I:=BX1+6+Rnd(BX2-BX1-12);J:=BY1+4+Rnd(BY2-BY1-8);
  If Not InZone(I,J) Then Begin Inc(N);NetX[N]:=I;NetY[N]:=J;End;
 End;
 NetE:=0;
 For I:=1 To NetN Do Begin
  B1:=0;B2:=0;B3:=0;D1:=Lim;D2:=Lim;D3:=Lim;
  For J:=1 To NetN Do
   If J<>I Then Begin
    D:=Sqr(LongInt(NetX[I]-NetX[J]))+Sqr(LongInt(NetY[I]-NetY[J]));
    If D<D1 Then Begin D3:=D2;B3:=B2;D2:=D1;B2:=B1;D1:=D;B1:=J;End
    Else If D<D2 Then Begin D3:=D2;B3:=B2;D2:=D;B2:=J;End
    Else If D<D3 Then Begin D3:=D;B3:=J;End;
   End;
  If (B1>0) And (NetE<NEDG) Then Begin Inc(NetE);NetA[NetE]:=I;NetB[NetE]:=B1;
    End;
  If (B2>0) And (NetE<NEDG) Then Begin Inc(NetE);NetA[NetE]:=I;NetB[NetE]:=B2;
    End;
  If (B3>0) And (NetE<NEDG) Then Begin Inc(NetE);NetA[NetE]:=I;NetB[NetE]:=B3;
    End;
 End;
 NetOk:=True;
End;

{ texte agrandi : metal argente (Metal) ou dore }
Procedure BigText(CX,Y,Size: Integer; Const S: String; Metal: Boolean);
Var X,O: Integer;
Begin
 SetTextStyle(DefaultFont,HorizDir,Size);
 X:=CX-TextWidth(S) Div 2;
 O:=(Size+2) Div 3;
 If Metal Then Begin
  Tx_(X+3*O,Y+3*O,S,cBlk);Tx_(X+2*O,Y+2*O,S,cDGr);
  Tx_(X+O,Y+O,S,cLGr);Tx_(X,Y,S,cWht);
 End Else Begin
  Tx_(X+2*O,Y+2*O,S,cBlk);Tx_(X+O,Y+O,S,cBrn);Tx_(X,Y,S,cYel);
 End;
 SetTextStyle(DefaultFont,HorizDir,1);
End;

Procedure SplashBanner;
Var I,X,Y,Dx,Dy,R,Cx,Cy,NS: Integer; D2: LongInt; Dd: Real;
Begin
 If Not NetOk Then NetBuild;
 Cx:=SCR_W Div 2;Cy:=MedY;R:=MedR;
 { cadre dore et fond bleu nuit }
 Bx(BX1,BY1,BX2,BY2,cNavy);
 Rc(BX1,BY1,BX2,BY2,cYel);Rc(BX1+2,BY1+2,BX2-2,BY2-2,cBrn);
 { etoiles }
 Seed:=777;
 NS:=Integer(90*LongInt(BX2-BX1)*(BY2-BY1) Div (590*290));
 If NS>600 Then NS:=600;
 For I:=1 To NS Do Begin
  X:=BX1+4+Rnd(BX2-BX1-8);Y:=BY1+4+Rnd(BY2-BY1-8);
  If Odd(I) Then PutPixel(X,Y,cLCy) Else PutPixel(X,Y,cWht);
 End;
 { lignes dorees }
 For I:=1 To NetE Do Begin
  Dx:=NetX[NetA[I]]-NetX[NetB[I]];Dy:=NetY[NetA[I]]-NetY[NetB[I]];
  If Sqr(LongInt(Dx))+Sqr(LongInt(Dy))<1300*LongInt(SpS)*SpS Div 10000 Then
   Ln(NetX[NetA[I]],NetY[NetA[I]],NetX[NetB[I]],NetY[NetB[I]],cYel)
  Else Ln(NetX[NetA[I]],NetY[NetA[I]],NetX[NetB[I]],NetY[NetB[I]],cBrn);
 End;
 { rayons vers le monogramme }
 J_:=0;
 For I:=1 To NetN Do Begin
  Dx:=NetX[I]-Cx;Dy:=NetY[I]-Cy;
  D2:=Sqr(LongInt(Dx))+Sqr(LongInt(Dy));
  If (D2>Sqr(LongInt(R)*3 Div 2)) And (D2<Sqr(LongInt(R)*3)) And (J_<20) Then
    Begin
   Inc(J_);
   Dd:=Sqrt(D2);
   Ln(NetX[I],NetY[I],Cx+Round(Dx*R/Dd),Cy+Round(Dy*R/Dd),cBrn);
  End;
 End;
 { points lumineux }
 For I:=1 To NetN Do Begin
  X:=NetX[I];Y:=NetY[I];
  If I Mod 8=0 Then Begin
   Bx(X-2,Y-2,X+2,Y+2,cYel);Bx(X-1,Y-1,X+1,Y+1,cWht);
  End Else Begin
   Bx(X-1,Y,X+1,Y,cYel);Bx(X,Y-1,X,Y+1,cYel);PutPixel(X,Y,cWht);
  End;
 End;
 { monogramme M dore }
 SetFillStyle(SolidFill,cBlk);FillEllipse(Cx+3,Cy+3,R+1,R+1);
 SetFillStyle(SolidFill,cYel);FillEllipse(Cx,Cy,R,R);
 SetFillStyle(SolidFill,cBrn);FillEllipse(Cx,Cy,R-4,R-4);
 SetFillStyle(SolidFill,cNavy);FillEllipse(Cx,Cy,R-7,R-7);
 BigText(Cx,Cy-4*Sz(6,10),Sz(6,10),'M',False);
 { nom en lettres argentees }
 BigText(Cx,NameY,Sz(5,10),APP_NAME,True);
 BigText(Cx,TagY,Sz(2,6),T('L''empire des relations~The empire of relationsh'
   +'ips~Das Imperium der Beziehungen~El imperio de las relaciones~L''impero'
   +' delle relazioni'),False);
End;

Procedure SplashBtn(I: Integer; Const L: String);
Var X1: Integer;
Begin
 X1:=14+(I-1)*(BtnW+5);
 Raised(X1,BtnY,X1+BtnW-5,BtnY+32);
 UTx(X1+(BtnW-5-TextW(L)) Div 2,BtnY+12,L,cBlk);
 If SpFoc=I Then Begin
  Rc(X1-1,BtnY-1,X1+BtnW-4,BtnY+33,cYel);
  MxFocusRect(X1+3,BtnY+3,X1+BtnW-8,BtnY+29);
 End;
End;

Function SplashLbl(I: Integer): String;
Begin
 Case I Of
  1: SplashLbl:=T('Lancer un &exemple~Launch an &example~Beispiel &starten~L'
    +'anzar un &ejemplo~Avvia un &esempio');
  2: SplashLbl:=T('&Nouveau CRM vide~&New empty CRM~&Neues leeres CRM~&Nuevo'
    +' CRM vac@io~&Nuovo CRM vuoto');
  Else SplashLbl:=T('&Ouvrir un CRM existant~&Open an existing CRM~Bestehend'
    +'es CRM &@2ffnen~&Abrir un CRM existente~&Apri un CRM esistente');
 End;
End;

Procedure SplashDraw;
Var I: Integer;
Begin
 HideMouse;
 If Not NetOk Then NetBuild;
 SetViewPort(0,CanvasTop,SCR_W-1,CanvasBot,True);
 Bx(0,0,SCR_W-1,SCR_H-1,cBlk);
 BigText(SCR_W Div 2,12,Sz(3,6),APP_NAME,True);
 SplashBanner;
 For I:=1 To 3 Do SplashBtn(I,SplashLbl(I));
 Tx_(14,BtnY+46,T('Fl@eches / Tab : choisir    Entr@ee : valider    Echap : '
   +'quitter~Arrows / Tab: choose    Enter: accept    Esc: quit~Pfeile / Tab'
   +': w@1hlen    Enter: best@1tigen    Esc: Ende~Flechas / Tab: elegir    I'
   +'ntro: aceptar    Esc: salir~Frecce / Tab: scegli    Invio: conferma    '
   +'Esc: esci'),cDGr);
 Tx_(14,SCR_H-18,'Maximilien CRM '+VERSION_TEXT+'  -  MyISAM / SQL  -  gladi'
   +'r.com/office-0',cDGr);
 ShowMouse;
End;

{ boite A propos : image d'accueil reduite, puis texte centre }
Procedure AboutBoxD;
Var X1,Y1,X2,Y2,W,H,I,Ty,Cx: Integer; E: TEvent; Done: Boolean;
    L: Array[1..6] Of String[60];
Begin
 W:=440;H:=362;
 X1:=(SCR_W-W) Div 2;Y1:=(SCR_H-H) Div 2;X2:=X1+W;Y2:=Y1+H;
 Cx:=(X1+X2) Div 2;
 L[1]:=APP_NAME+' '+VERSION_TEXT;
 L[2]:=T('Clone de Maximizer CRM~Maximizer CRM clone~Maximizer-CRM-Klon');
 L[3]:=T('pour Turbo Pascal / Free Pascal~for Turbo Pascal / Free Pascal~f@3r'
   +' Turbo Pascal / Free Pascal');
 L[4]:=T('Auteur : ~Author: ~Autor: ')+'Sylvain Maltais';
 L[5]:=T('Date : ~Date: ~Datum: ')+'2026';
 L[6]:=T('Site Web : ~Website: ~Webseite: ')+'gladir.com/office-0';
 Backdrop;
 HideMouse;
 DlgFrame(X1,Y1,X2,Y2,T('@A propos de ~About ~@3ber ')+APP_NAME);
 { image d'accueil }
 AbtOn:=True;
 AbtX1:=X1+20;AbtX2:=X2-20;AbtY1:=Y1+30;AbtY2:=Y1+200;
 NetOk:=False;
 SplashBanner;
 AbtOn:=False;NetOk:=False;
 { texte }
 Ty:=AbtY2+12;
 TxB(Cx-TextW(L[1]) Div 2,Ty,L[1],cBlk);
 For I:=2 To 3 Do Tx_(Cx-TextW(L[I]) Div 2,Ty+4+(I-1)*14,L[I],cBlk);
 For I:=4 To 6 Do Tx_(Cx-TextW(L[I]) Div 2,Ty+14+(I-1)*14,L[I],cBlk);
 Btn(Cx-38,Y2-30,Cx+38,Y2-10,T('&OK~&OK~&OK~&OK~&OK'),True);
 ShowMouse;
 Done:=False;
 Repeat
  PollEvent(E);
  If E.Kind=1 Then Begin
   If (E.Key=K_ENTER) Or (E.Key=K_ESC) Or (E.Key=32) Or
      (UpCase(Chr(E.Key And 255))='O') Then Done:=True;
  End Else If E.Kind=2 Then
   If InBox(E.X,E.Y,Cx-38,Y2-30,Cx+38,Y2-10) Or
      InBox(E.X,E.Y,X2-19,Y1+5,X2-5,Y1+17) Then Done:=True;
 Until Done;
End;
Procedure AboutBox;
Begin
 MxCatWant:=True;AboutBoxD;MxCatDone;
End;

Procedure Backdrop;
Begin
 If CatCl<>0 Then Exit;
 If UiReady Then DrawAll Else SplashDraw;
End;

{ dossiers contenant un CRM (abentry.frm) }
Procedure FindCrmDirs;
Var SR: SearchRec;
Begin
 PickN:=0;
 FindFirst('*',Directory,SR);
 While DosError=0 Do Begin
  If (SR.Attr And Directory<>0) And (SR.Name<>'.') And (SR.Name<>'..') Then
   If FileExists(SR.Name+DirSep+'abentry.frm') Then PickAdd(SR.Name);
  FindNext(SR);
 End;
End;

Function OpenDlg: Boolean;
Var Sel: Integer; D: String;
Begin
 OpenDlg:=False;
 FindCrmDirs;
 PickAdd(T('(Autre dossier...)~(Other folder...)~(Anderer Ordner...)~(Otra c'
   +'arpeta...)~(Altra cartella...)'));
 Sel:=1;
 If Not PickList(T('Ouvrir un CRM existant~Open an existing CRM~Bestehendes '
   +'CRM @2ffnen~Abrir un CRM existente~Apri un CRM esistente'),Sel) Then
   Exit;
 If Sel=PickN Then Begin
  D:='';
  If Not InputBox(T('Dossier du CRM~CRM folder~CRM-Ordner~Carpeta del CRM~Ca'
    +'rtella del CRM'),
    T('Chemin du dossier :~Folder path:~Ordnerpfad:~Ruta de la carpeta:~Perc'
      +'orso cartella:'),D,50) Then Exit;
 End Else D:=PickIt^[Sel];
 If (D='') Or Not FileExists(D+DirSep+'abentry.frm') Then Begin
  Info(T('Aucun CRM trouv@e dans ce dossier.~No CRM found in this folder.~Ke'
    +'in CRM in diesem Ordner.~No hay CRM en esta carpeta.~Nessun CRM in que'
    +'sta cartella.'));
  Exit;
 End;
 DbDir:=D;SeedKind:=0;OpenDlg:=True;
End;

Function NewDlg: Boolean;
Var Nm,D: String; I: Integer;
Begin
 NewDlg:=False;
 Nm:='';
 If Not InputBox(T('Nouveau CRM~New CRM~Neues CRM~Nuevo CRM~Nuovo CRM'),
   T('Nom du CRM :~CRM name:~Name des CRM:~Nombre del CRM:~Nome del CRM:'
     ),Nm,40) Then Exit;
 If Nm='' Then Exit;
 D:='';
 For I:=1 To Length(Nm) Do
  If (Length(D)<8) And (UpCase(Nm[I]) In ['A'..'Z','0'..'9']) Then
    D:=D+UpCase(Nm[I]);
 If D='' Then D:='NOUVEAU';
 If Not InputBox(T('Nouveau CRM~New CRM~Neues CRM~Nuevo CRM~Nuovo CRM'),
   T('Dossier de la base de donn@ees :~Database folder:~Datenbankordner:~Car'
     +'peta de la base:~Cartella del database:'),D,50) Then Exit;
 If D='' Then Exit;
 If FileExists(D+DirSep+'abentry.frm') Then Begin
  If MsgBox(T('Ce dossier contient d@ej@a un CRM. L''ouvrir ?~This folder al'
    +'ready holds a CRM. Open it?~Dieser Ordner enth@1lt bereits ein CRM. @2'
    +'ffnen?~La carpeta ya contiene un CRM. @?Abrirlo?~La cartella contiene '
    +'gi@q un CRM. Aprirlo?'),1)<>1 Then Exit;
  SeedKind:=0;
 End Else Begin
  {$I-}
  MkDir(D);
  {$I+}
  If IOResult<>0 Then ;
  SeedKind:=1;CfgNew:=Nm;
 End;
 DbDir:=D;NewDlg:=True;
End;

{ retourne False pour quitter }
Function Splash: Boolean;
Var E: TEvent; Done,Redraw: Boolean; Ch: Char; I,Pick: Integer;
    SvH: Integer; C: LongInt; SpB: Array[1..3] Of LongInt; Bx1: Integer;
Begin
 Splash:=False;
 { l'accueil occupe la zone client (sous la barre de menus de PM) }
 SvH:=SCR_H;SCR_H:=CanvasBot+1-CanvasTop;
 SplashGeom;
 For I:=1 To 3 Do Begin
  Bx1:=14+(I-1)*(BtnW+5);
  SpB[I]:=WinCreateWindow(OsClient,WC_BUTTON,OsZ(MxTilde(SplashLbl(I))),WS_VISIBLE Or BS_PUSHBUTTON,
    Bx1,SCR_H-1-(BtnY+32),BtnW-4,33,OsClient,HWND_TOP,7000+I,0,0);
 End;
 SpFoc:=1;Redraw:=True;Done:=False;
 Repeat
  If Redraw Then Begin SplashDraw;Redraw:=False;End;
  PollEvent(E);
  Pick:=0;
  { boutons de PM, fermeture de la fenetre ; les menus attendent le CRM }
  While PollCmd(C) Do
   If (C>7000) And (C<=7003) Then Pick:=C-7000
   Else If C=CMD_CLOSE Then Begin Done:=True;Pick:=-1;End;
  If Pick<>0 Then E.Kind:=0;
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ESC: Begin Done:=True;Pick:=-1;End;
    K_LEFT,K_STAB: Begin If SpFoc>1 Then Dec(SpFoc) Else SpFoc:=3;
      Redraw:=True;End;
    K_RIGHT,K_TAB: Begin If SpFoc<3 Then Inc(SpFoc) Else SpFoc:=1;
      Redraw:=True;End;
    K_ENTER: Pick:=SpFoc;
    256+45: Begin Done:=True;Pick:=-1;End;
    Else Begin
     Ch:=UpCase(Chr(E.Key And 255));
     For I:=1 To 3 Do
      If (Pos('&',SplashLbl(I))>0) And
         (UpCase(SplashLbl(I)[Pos('&',SplashLbl(I))+1])=Ch) Then Pick:=I;
    End;
   End;
  End Else If E.Kind=2 Then Begin
   For I:=1 To 3 Do
    If InBox(E.X,E.Y-CanvasTop,14+(I-1)*(BtnW+5),BtnY,14+(I-1)*(BtnW+5)+BtnW-5,BtnY+32)
      Then Begin
     SpFoc:=I;Pick:=I;
    End;
  End;
  If Pick>0 Then Begin
   SpFoc:=Pick;
   Case Pick Of
    1: Begin DbDir:='EXEMPLE';SeedKind:=2;Splash:=True;Done:=True;End;
    2: If NewDlg Then Begin Splash:=True;Done:=True;End;
    3: If OpenDlg Then Begin Splash:=True;Done:=True;End;
   End;
   Redraw:=True;
  End;
 Until Done;
 For I:=1 To 3 Do Dummy:=WinDestroyWindow(SpB[I]);
 SCR_H:=SvH;
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
End;

{ ====================================================================== }
{                       COMMANDES DE L'APPLICATION                       }
{ ====================================================================== }

Procedure CalKey(K: Word); Forward;
Procedure ContextKey; Forward;

Procedure DoCmd(Cm: Integer);
Var Dt: String;
Begin
 StatMsg:='';
 Case Cm Of
  1: NewEntry;
  2: ChangeUser;
  3: ImportCsv;
  4: ExportCsv;
  5: BackupRestore(False);
  6: BackupRestore(True);
  7: RepEntries(1);
  8: Quit:=True;
  10: CtxEdit;
  11: CtxDel;
  12: CtxNew;
  13: DuplicateEntry;
  14: Begin If Modu=4 Then ToggleDone Else MarkCur(0);End;
  15: MarkCur(1);
  16: MarkCur(2);
  17: Begin
       If Not (Modu In [2,8]) Then SetModule(2);
       If NeedEntry Then NewSub(tCO,'','ENTRY_ID,',T('Nouveau contact~New co'
         +'ntact~Neuer Kontakt~Nuevo contacto~Nuovo contatto'),Fx(tCO,
         'ENTRY_ID'));
      End;
  20..28: SetModule(Cm-19);
  29: ReloadAll;
  30: ToolBarOn:=Not ToolBarOn;
  31: StatusOn:=Not StatusOn;
  33: PickShow;
  40: FindName;
  41: AdvSearch;
  42: SearchNotes;
  43: SavedQueries;
  44: If FilterSql='' Then Info(T('Aucune recherche active.~No active search'
    +'.~Keine aktive Suche.~Sin b@3squeda activa.~Nessuna ricerca attiva.'))
      Else Begin
       FilterName:=Copy(FilterName,1,30);
       NewRow(tQR,RBF);SS(tQR,RBF,'NAME',FilterName);SS(tQR,RBF,'WHERECL'
         ,FilterSql);
       If RowAdd(tQR,RBF)>0 Then TblFlush(tQR);
      End;
  45: ShowAll;
  46: FindDup;
  47: Begin
       Dt:=FmtDate(SessDate);
       If InputBox(T('Calendrier~Calendar~Kalender~Calendario~Calendario'),T(
         'Date :~Date:~Datum:~Fecha:~Data:'),Dt,12) Then
        If ParseDate(Dt,CalDate) Then SetModule(5);
      End;
  50: ActEmail;
  51: NoteDlg(-1,'');
  52: ActDoc('L');
  53: ActDoc('F');
  54: ActDoc('D');
  55: ActCall(False);
  56: ActCall(True);
  57: ActAppt('M');
  58: ActAppt('T');
  59: ActAppt('C');
  60: ActPlan;
  61: ActAttach(False);
  62: ActAttach(True);
  63: ActEnvelope(False);
  64: ActEnvelope(True);
  65: ActTimer;
  66: ActOpp;
  67: ToggleDone;
  70: MailMerge;
  71: SqlConsole;
  72: Calculator;
  73: CheckTables(False);
  74: CheckTables(True);
  75: DbInfo;
  80: RepEntries(1);
  81: ReportSql(T('Liste des contacts~Contacts list~Kontaktliste~Lista de co'
    +'ntactos~Elenco contatti'),
       'SELECT e.name AS company, c.name AS contact, c.phone, c.email FROM c'
         +'ontact c JOIN abentry e ON c.entry_id = e.id ORDER BY e.name');
  82: RepEntries(2);
  83: ReportSql(T('Opportunit@es~Opportunities~Verkaufschancen~Oportunidades'
    +'~Opportunit@q'),
       'SELECT e.name AS company, o.name AS opportunity, o.stage, o.prob AS '
         +'pct, o.amount AS m_amount, o.closedt FROM oppor o JOIN abentry e '
         +'ON o.entry_id = e.id ORDER BY o.closedt');
  84: ReportSql(T('Entonnoir des ventes~Sales pipeline~Verkaufstrichter~Embu'
    +'do de ventas~Pipeline vendite'),
       'SELECT stage, COUNT(*) AS cnt, SUM(amount) AS m_total FROM oppor WHE'
         +'RE prob > 0 AND prob < 100 GROUP BY stage ORDER BY stage');
  85: ReportSql(T('Pr@evisions par mois~Forecast by month~Prognose pro Monat'
    +'~Previsi@on mensual~Previsione mensile'),
       'SELECT LEFT(closedt,7) AS month, COUNT(*) AS cnt, SUM(amount) AS m_t'
         +'otal, SUM(amount*prob/100) AS m_weighted FROM oppor WHERE prob > '
         +'0 AND prob < 100 GROUP BY LEFT(closedt,7) ORDER BY LEFT(closedt,7'
         +')');
  86: RepNotes;
  87: RepActivities(0);
  88: RepActivities(7);
  89: ReportSql(T('Temps et facturation~Time and billing~Zeit und Abrechnung'
    +'~Tiempo y facturaci@on~Tempo e fatturazione'),
       'SELECT usr, COUNT(*) AS entries, SUM(minutes) AS minutes, SUM(minute'
         +'s)/60 AS hours FROM timelog GROUP BY usr');
  90: ReportSql(T('Commandes~Orders~Auftr@1ge~Pedidos~Ordini'),
       'SELECT o.ordno, e.name AS customer, o.od AS orderdate, o.status, o.t'
         +'otal AS m_total FROM orders o JOIN abentry e ON o.entry_id = e.id'
         +' ORDER BY o.od');
  91: ReportSql(T('Entr@ees par statut~Entries by status~Eintr@1ge nach Stat'
    +'us~Entradas por estado~Voci per stato'),
       'SELECT status, COUNT(*) AS entries FROM abentry GROUP BY status ORDE'
         +'R BY status');
  92: RepLabels;
  100..109: SetupCmd(Cm);
  120: CopyCur;
  121: PasteCur;
  122: Begin CalDate:=SessDate;If Modu=5 Then CalLoad;End;
  123: CalKey(K_PGUP);
  124: CalKey(K_PGDN);
  127: DupAppt;
  130: InvertMarks;
  131: MarkSame('CITY');
  132: MarkSame('STATUS');
  133: SetEntryField('STATUS');
  134: SetEntryField('SOURCE');
  135: SetEntryField('TERR');
  136: SetEntryField('OWNER');
  137: ForTargets(2,'','');
  138: ForTargets(3,'','');
  140: FilterSame('CITY');
  141: FilterSame('STATE');
  142: FilterSame('STATUS');
  143: FilterSame('SOURCE');
  144: FilterSame('TERR');
  145: FilterSame('OWNER');
  146: Begin ShowFilter:=3;ReloadAll;End;
  148: MarkSame('TERR');
  150: SortBy('NAME',False);
  151: SortBy('CITY',False);
  152: SortBy('MODIFIED',True);
  153: SortBy('CREATED',True);
  154: SortBy('STATUS',False);
  160..165: CopyField(Cm-159);
  166: MergeEntry;
  167: NewRelated;
  168: DeleteMarked;
  169: ExportMarked;
  170: EntryCard;
  171: SetMainContact;
  172: EmailContact;
  173: CallContact;
  174..176: CopyContactField(Cm-173);
  177..180: OppStage(Cm-176);
  181: OpenLinked;
  182: ToggleNoteFlag;
  183: ChangeNoteType;
  184: PickNoteFilter(1);
  185: PickNoteFilter(2);
  186: CopyDocPath;
  187: NewOrder;
  190: CopyAllRows(GW[WdPanel]);
  191..194: Postpone(Cm-190);
  195: OpenEntryCur;
  196: CopyAllRows(GMain);
  200: LibView;
  201: LibNewFromClip;
  202: LibImportFile;
  203: LibProps;
  204: LibToEntry;
  205: LibEmail;
  206: LibToTemplate;
  207: LibPrint;
  208: LibExport;
  209: LibCopyName;
  210: LibDup;
  211: LibSetCat;
  212: LibFilterCat;
  213: LibClear;
  214: SortBy('NAME',False);
  215: SortBy('CATEGORY',False);
  216: SortBy('DD',True);
  217: SortBy('CREATOR',False);
  218: LibSearch;
  219: LibCopyRow;
  110,111: HelpText;
  112: AboutBox;
 End;
 Dirty:=True;
End;

{ ====================================================================== }
{                       MENUS DEROULANTS                                 }
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
Var M,Hi,H,Tt: Integer; E: TEvent; Done,Pick,Redraw: Boolean;
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
         Tt:=TitleHit(E.X,E.Y);
         If (Tt>0) And (Tt<>M) Then Begin M:=Tt;Hi:=0;Redraw:=True;End
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

Procedure CycleFocus(Dir: Integer);
Var Mx: Integer;
Begin
 Case Modu Of
  2,8: Mx:=4;
  9: Mx:=3;
  5: Mx:=4;
  Else Mx:=2;
 End;
 Repeat
  Foc:=Foc+Dir;
  If Foc<1 Then Foc:=Mx;
  If Foc>Mx Then Foc:=1;
 Until (Modu<>5) Or (Foc<>3);
 Dirty:=True;
End;

Procedure AfterMove;
Begin
 If Modu In [2,8] Then Begin
  If GridSelId(GMain)<>CurId Then Begin
   CurId:=GridSelId(GMain);LoadSubs;
  End;
 End Else If Modu<>1 Then SyncCur;
 Dirty:=True;
End;

Function NameStarts(I: LongInt; C: Char): Boolean;
Var S: String;
Begin
 NameStarts:=False;
 If RowGet(tAB,GMain.Sl^[I],RB2) Then Begin
  S:=Upper(SG(tAB,RB2,'NAME'));
  NameStarts:=(S<>'') And (S[1]=C);
 End;
End;

Procedure FirstLetter(C: Char);
Var I: LongInt;
Begin
 For I:=GMain.Sel+1 To GMain.N Do
  If NameStarts(I,C) Then Begin GMain.Sel:=I;AfterMove;Exit;End;
 For I:=1 To GMain.Sel Do
  If NameStarts(I,C) Then Begin GMain.Sel:=I;AfterMove;Exit;End;
End;

Procedure CalKey(K: Word);
Var D: LongInt;
Begin
 D:=CalDate;
 Case K Of
  K_LEFT: D:=AddDays(D,-1);
  K_RIGHT: D:=AddDays(D,1);
  K_UP: D:=AddDays(D,-7);
  K_DOWN: D:=AddDays(D,7);
  K_PGUP: D:=AddDays(D-(D Mod 100)+1,-1);
  K_PGDN: D:=AddDays(D-(D Mod 100)+DaysInMonth(D Div 10000,(D Div 100) Mod
    100)+1,0);
  K_HOME: D:=SessDate;
  Else Exit;
 End;
 CalDate:=D;CalLoad;Dirty:=True;
End;

Procedure HandleKey(K: Word);
Var L: Integer; Ch: Char;
Begin
 If K>=256 Then Begin
  If K=256+45 Then Begin Quit:=True;Exit;End;
  L:=AltLetter(K);
  If L>=0 Then Exit;
 End;
 Case K Of
  K_F1: Begin DoCmd(110);Exit;End;
  K_F5: Begin DoCmd(29);Exit;End;
  K_F6: Begin DoCmd(21);Exit;End;
  14: Begin DoCmd(1);Exit;End;
  3: Begin DoCmd(120);Exit;End;
  22: Begin DoCmd(121);Exit;End;
  K_F9,256+93: Begin ContextKey;Exit;End;
  6: Begin DoCmd(40);Exit;End;
  K_TAB: Begin CycleFocus(1);Exit;End;
  K_STAB: Begin CycleFocus(-1);Exit;End;
 End;
 Case Foc Of
  1: Case K Of
      K_UP: Begin If Modu>1 Then SetModule(Modu-1);End;
      K_DOWN: Begin If Modu<NMOD Then SetModule(Modu+1);End;
      K_ENTER: Begin Foc:=2;Dirty:=True;End;
     End;
  2: Begin
      If (Modu=5) Then Begin
       CalKey(K);
       If (K=K_ENTER) Or (K=K_INS) Then DoCmd(12);
       If K=K_DEL Then DoCmd(11);
       If K=32 Then ToggleDone;
       Exit;
      End;
      If Modu=1 Then Begin
       If GridKey(GW[WdPanel],K) Then AfterMove
       Else Case K Of
        K_LEFT,K_PGUP: Begin If WdPanel>1 Then Dec(WdPanel) Else WdPanel:=4;
          AfterMove;End;
        K_RIGHT,K_PGDN: Begin If WdPanel<4 Then Inc(WdPanel) Else WdPanel:=1;
          AfterMove;End;
        K_ENTER: DoCmd(10);
        K_INS: DoCmd(12);
        K_DEL: DoCmd(11);
        32: If WdPanel In [1,2] Then ToggleDone;
       End;
       Exit;
      End;
      If GridKey(GMain,K) Then AfterMove
      Else Case K Of
       K_ENTER: DoCmd(10);
       K_INS: DoCmd(12);
       K_DEL: DoCmd(11);
       32: If Modu In [2,8,4] Then DoCmd(14);
       K_LEFT: If Modu=6 Then Begin
         L:=Pos(MailFold,'ISDO');If L>1 Then MailFold:=CodeAt('FD',L-1);
           ReloadAll;End;
       K_RIGHT: If Modu=6 Then Begin
         L:=Pos(MailFold,'ISDO');If L<4 Then MailFold:=CodeAt('FD',L+1);
           ReloadAll;End;
       Else Begin
        Ch:=UpCase(Chr(K And 255));
        If (Modu In [2,8]) And (K<256) And (Ch>='A') And (Ch<='Z') Then
          FirstLetter(Ch);
       End;
      End;
     End;
  3: Begin
      If GridKey(GSubL,K) Then Dirty:=True
      Else Case K Of
       K_ENTER: DoCmd(10);
       K_INS: DoCmd(12);
       K_DEL: DoCmd(11);
       K_LEFT: If (Modu In [2,8]) Then Begin If TabL>1 Then Dec(TabL) Else
         TabL:=3;SetTabCols;LoadSubs;Dirty:=True;End;
       K_RIGHT: If (Modu In [2,8]) Then Begin If TabL<3 Then Inc(TabL) Else
         TabL:=1;SetTabCols;LoadSubs;Dirty:=True;End;
      End;
     End;
  4: Begin
      If GridKey(GSubR,K) Then Dirty:=True
      Else Case K Of
       K_ENTER: If Modu=5 Then DoCmd(10) Else DoCmd(10);
       K_INS: DoCmd(12);
       K_DEL: DoCmd(11);
       32: If Modu=5 Then ToggleDone;
       K_LEFT: If (Modu In [2,8]) Then Begin If TabR>1 Then Dec(TabR) Else
         TabR:=5;SetTabCols;LoadSubs;Dirty:=True;End;
       K_RIGHT: If (Modu In [2,8]) Then Begin If TabR<5 Then Inc(TabR) Else
         TabR:=1;SetTabCols;LoadSubs;Dirty:=True;End;
      End;
     End;
 End;
End;

{ clic sur une grille : retourne True si une ligne a ete touchee }
Function GridMouse(Var G: TGrid; X,Y: LongInt; PostF: Boolean): Integer;
Var R: Integer;
Begin
 R:=GridClick(G,X,Y);
 If R=2 Then Begin
  GridReload(G,'');
  If PostF Then PostFilter(G);
 End;
 GridMouse:=R;
End;

Procedure ModuleMouse(X,Y: LongInt);
Var R,Tbn,I: Integer; Dbl: Boolean; Y0,D,Dd,First: LongInt; Yr,Mo: Integer;
    Tb_: String;
Begin
 Case Modu Of
  1: Begin
      For I:=1 To 4 Do
       If InBox(X,Y,GW[I].X1,GW[I].Y1,GW[I].X2,GW[I].Y2) Then Begin
        WdPanel:=I;Foc:=2;
        R:=GridClick(GW[I],X,Y);
        SyncCur;
        If (R=1) And IsDouble(X,Y) Then Begin
         If I=4 Then Begin
          If RowGet(tAB,GridSelSlot(GW[4]),RB) Then Begin
           SetModule(2);GridGoto(GMain,GetN(tAB,RB,1));
             SelectEntry(GetN(tAB,RB,1));End;
         End Else If I=3 Then Begin
          EditSlot(tOP,GridSelSlot(GW[3]),'','CREATED,','');
         End Else EditSlot(tAP,GridSelSlot(GW[I]),'','','');
        End;
       End;
      Dirty:=True;
     End;
  2,8: Begin
      If InBox(X,Y,CX1+76,WORK_Y+19,CX1+230,WORK_Y+34) Then Begin PickShow;
        Exit;End;
      If InBox(X,Y,CX1,AB_Y1,CX2,AB_Y2) Then Begin
       Foc:=2;
       R:=GridMouse(GMain,X,Y,True);
       If R<>0 Then AfterMove;
       If (R=1) And IsDouble(X,Y) Then DoCmd(10);
       Dirty:=True;Exit;
      End;
      Tb_:=TabsL;
      I:=TabHit(CX1,PANE_Y,Tb_,X,Y);
      If I>0 Then Begin TabL:=I;Foc:=3;SetTabCols;LoadSubs;Dirty:=True;Exit;End;
      Tb_:=TabsR;
      I:=TabHit(CX1+LW+6,PANE_Y,Tb_,X,Y);
      If I>0 Then Begin TabR:=I;Foc:=4;SetTabCols;LoadSubs;Dirty:=True;Exit;End;
      If InBox(X,Y,GSubL.X1,GSubL.Y1,GSubL.X2,GSubL.Y2) Then Begin
       Foc:=3;
       R:=GridMouse(GSubL,X,Y,False);
       If (R=1) And IsDouble(X,Y) Then DoCmd(10);
       Dirty:=True;Exit;
      End;
      If TabR=1 Then Begin
       If InBox(X,Y,CX1+LW+72,BODY_Y+1,CX1+LW+164,BODY_Y+16) Then Begin
         PickNoteFilter(1);Exit;End;
       If InBox(X,Y,CX1+LW+224,BODY_Y+1,CX2,BODY_Y+16) Then Begin
         PickNoteFilter(2);Exit;End;
      End;
      If InBox(X,Y,CX1+LW+6,BODY_Y,CX2,BODY_Y2) Then Begin
       Foc:=4;
       If TabR In [2,4] Then Begin If IsDouble(X,Y) Then DoCmd(10);End
       Else Begin
        R:=GridMouse(GSubR,X,Y,False);
        If (R=1) And IsDouble(X,Y) Then DoCmd(10);
       End;
       Dirty:=True;
      End;
     End;
  3,7: Begin
      R:=GridMouse(GMain,X,Y,False);
      If R<>0 Then AfterMove;
      If (R=1) And IsDouble(X,Y) Then DoCmd(10);
      Dirty:=True;
     End;
  4: Begin
      If InBox(X,Y,CX1+76,WORK_Y+19,CX1+300,WORK_Y+34) Then Begin PickHot;
        Exit;End;
      R:=GridMouse(GMain,X,Y,False);
      If R<>0 Then AfterMove;
      If (R=1) And IsDouble(X,Y) Then DoCmd(10);
      Dirty:=True;
     End;
  5: Begin
      If InBox(X,Y,CX1+2,WORK_Y+20,CX1+22,WORK_Y+36) Then Begin
        CalKey(K_PGUP);Exit;End;
      If InBox(X,Y,CX1+7*CalW-18,WORK_Y+20,CX1+7*CalW+2,WORK_Y+36) Then Begin
       CalKey(K_PGDN);Exit;End;
      Yr:=CalDate Div 10000;Mo:=(CalDate Div 100) Mod 100;
      If InBox(X,Y,CX1+2,AB_Y1+16,CX1+7*CalW+1,AB_Y1+15+6*CalH) Then Begin
       First:=WeekDay(Yr*10000+Mo*100+1);
       Dd:=((Y-AB_Y1-16) Div CalH)*7+((X-CX1-2) Div CalW)-First+1;
       If (Dd>=1) And (Dd<=DaysInMonth(Yr,Mo)) Then Begin
        CalDate:=Yr*10000+Mo*100+Dd;CalLoad;Foc:=2;
        If IsDouble(X,Y) Then DoCmd(12);
       End;
       Dirty:=True;Exit;
      End;
      If InBox(X,Y,GSubR.X1,GSubR.Y1,GSubR.X2,GSubR.Y2) Then Begin
       Foc:=4;
       R:=GridMouse(GSubR,X,Y,False);
       If (R=1) And IsDouble(X,Y) Then DoCmd(10);
       Dirty:=True;
      End;
     End;
  6: Begin
      For I:=1 To 4 Do
       If InBox(X,Y,CX1,AB_Y1+(I-1)*22,CX1+100,AB_Y1+(I-1)*22+20) Then Begin
        MailFold:=CodeAt('FD',I);ReloadAll;Exit;
       End;
      R:=GridMouse(GMain,X,Y,False);
      If R<>0 Then AfterMove;
      If (R=1) And IsDouble(X,Y) Then DoCmd(10);
      Dirty:=True;
     End;
  9: Begin
      If InBox(X,Y,GSubL.X1,GSubL.Y1,GSubL.X2,GSubL.Y2) Then Begin
       Foc:=3;
       R:=GridMouse(GSubL,X,Y,False);
       If (R=1) And IsDouble(X,Y) Then DoCmd(10);
       Dirty:=True;Exit;
      End;
      Foc:=2;
      R:=GridMouse(GMain,X,Y,False);
      If R<>0 Then AfterMove;
      If (R=1) And IsDouble(X,Y) Then DoCmd(10);
      Dirty:=True;
     End;
 End;
End;

Procedure MouseDown(X,Y: LongInt);
Var Tt,Cm,I: Integer;
Begin
 Tt:=TitleHit(X,Y);
 If Tt>0 Then Begin RunMenu(Tt,True);Exit;End;
 If (Y<MENU_H) And (X>=SCR_W-20) Then Begin Quit:=True;Exit;End;
 I:=ToolHit(X,Y);
 If I>0 Then Begin DoCmd(TbCmd[I]);Exit;End;
 I:=NavHit(X,Y);
 If I In [1..NMOD] Then Begin SetModule(I);Exit;End;
 If I>100 Then Begin
  SetModule(2);
  ShowFilter:=0;FilterSql:='';FilterName:='';LoadMain;
  GridGoto(GMain,Recent[I-100]);SelectEntry(Recent[I-100]);
  Exit;
 End;
 If (X>=CX1) And (Y>=WORK_Y) And (Y<STAT_Y) Then ModuleMouse(X,Y);
End;

{ selectionne l'element sous le curseur sans l'activer (clic droit) }
Procedure RightSelect(X,Y: LongInt);
Var R,Yr,Mo,I: Integer; First,Dd: LongInt;
 Function Pick(Var G: TGrid; F: Integer): Boolean;
 Begin
  Pick:=False;
  If InBox(X,Y,G.X1,G.Y1+16,G.X2-14,G.Y2) Then Begin
   R:=GridClick(G,X,Y);
   Foc:=F;Pick:=True;
  End;
 End;
Begin
 Case Modu Of
  2,8: If Not Pick(GMain,2) Then
        If Not Pick(GSubL,3) Then
         If TabR In [1,3,5] Then If Pick(GSubR,4) Then ;
  1: Begin
      For I:=1 To 4 Do
       If InBox(X,Y,GW[I].X1,GW[I].Y1,GW[I].X2,GW[I].Y2) Then Begin
        WdPanel:=I;Foc:=2;
        If Pick(GW[I],2) Then ;
       End;
     End;
  3,4,6,7: If Pick(GMain,2) Then ;
  9: If Not Pick(GMain,2) Then If Pick(GSubL,3) Then ;
  5: Begin
      Yr:=CalDate Div 10000;Mo:=(CalDate Div 100) Mod 100;
      If InBox(X,Y,CX1+2,AB_Y1+16,CX1+7*CalW+1,AB_Y1+15+6*CalH) Then Begin
       First:=WeekDay(Yr*10000+Mo*100+1);
       Dd:=((Y-AB_Y1-16) Div CalH)*7+((X-CX1-2) Div CalW)-First+1;
       If (Dd>=1) And (Dd<=DaysInMonth(Yr,Mo)) Then Begin
        CalDate:=Yr*10000+Mo*100+Dd;CalLoad;
       End;
       Foc:=2;
      End Else If Pick(GSubR,4) Then ;
     End;
 End;
 AfterMove;
End;

Procedure MouseRight(X,Y: LongInt);
Var Cm: Integer;
Begin
 If (Y<WORK_Y) Or (X<CX1) Or (Y>=STAT_Y) Then Exit;
 NoDbl:=True;
 RightSelect(X,Y);
 NoDbl:=False;
 DrawAll;
 BuildContext;
 Cm:=PopupRun(X,Y,1,PMN);
 Dirty:=True;
 If Cm>0 Then DoCmd(Cm);
End;

Procedure ContextKey;
Begin
 If Modu=1 Then MouseRight(GW[WdPanel].X1+60,GW[WdPanel].Y1+34)
 Else MouseRight(CX1+90,AB_Y1+34);
End;

Procedure ShowTip;
Var I: Integer;
Begin
 I:=ToolHit(MX,MY);
 If I<>TipIdx Then Begin
  TipIdx:=I;
  If I>0 Then StatMsg:=TbTip[I] Else StatMsg:='';
  If StatusOn Then Begin HideMouse;DrawStatusBar;ShowMouse;End;
 End;
End;

Procedure MainLoop;
Var E: TEvent; C: LongInt;
Begin
 Repeat
  If Dirty Then DrawAll;
  { barre de menus de PM }
  While PollCmd(C) And Not Quit Do Begin
   If C=CMD_CLOSE Then DoCmd(8)
   Else If (C>=133) And (C<100+32*(NMENU+1)) Then
    If ((C-100) Mod 32>=1) And ((C-100) Mod 32<=MCnt[(C-100) Div 32]) Then
     DoCmd(MCm[(C-100) Div 32,(C-100) Mod 32]);
   Dirty:=True;
  End;
  If Quit Then Exit;
  PollEvent(E);
  Case E.Kind Of
   1: HandleKey(E.Key);
   2: MouseDown(E.X,E.Y);
   5: MouseRight(E.X,E.Y);
   4: ShowTip;
  End;
 Until Quit;
End;

Procedure ShowHelpLine;
Begin
 WriteLn('MAXIMIZE - Cette commande permet de lancer Maximilien CRM (clone de Maximizer CRM).');
 WriteLn;
 WriteLn('Syntaxe : MAXIMIZE [/D:dossier] [/U:utilisateur] [-maxscreen]');
 WriteLn('              MAXIMIZE /SQL "requete" [/D:dossier]');
 WriteLn;
 WriteLn('  /D:dossier  Dossier de la base MyISAM (defaut : CRMDATA).');
 WriteLn('  /U:code     Code utilisateur (defaut : JNAPOLI).');
 WriteLn('  -maxscreen  Utilise la resolution maximale disponible.');
 WriteLn('  /SQL        Execute une requete SQL sans interface graphique.');
 WriteLn('  /?          Affiche cette aide.');
 WriteLn;
 WriteLn('Langue : variable LANGUAGE=EN (anglais), GR (allemand),');
 WriteLn('         SP (espagnol), IT (italien) ; francais par defaut.');
End;

Procedure BatchSql(Const Q: String);
Var I,J: Integer; S: String;
Begin
 If Not SqlRun(Q) Then Begin WriteLn('ERROR: ',SqlErr);Exit;End;
 If SqlIsSlots Then Begin
  S:='';
  For J:=1 To Tb[SqlTbl]^.NF Do S:=S+Lower(Tb[SqlTbl]^.F[J].Nm)+#9;
  WriteLn(S);
  For I:=1 To SqlN Do
   If RowGet(SqlTbl,P1^[I],RB2) Then Begin
    S:='';
    For J:=1 To Tb[SqlTbl]^.NF Do S:=S+GetS(SqlTbl,RB2,J)+#9;
    WriteLn(S);
   End;
 End Else If SqlNC>0 Then Begin
  S:='';
  For J:=1 To SqlNC Do S:=S+SqlHead[J]+#9;
  WriteLn(S);
  For I:=1 To SqlNR Do Begin
   S:='';
   For J:=1 To SqlNC Do S:=S+SqlRows^[I][J]+#9;
   WriteLn(S);
  End;
 End;
 If SqlMsg<>'' Then WriteLn('-- ',SqlMsg);
 TblFlushAll;
End;

Var
 Pi     : Integer;
 Pa     : String;
 SqlArg : String;
 NewDb  : Boolean;

BEGIN
 DbDir:='CRMDATA';
 DirGiven:=False;
 MaxScreen:=False;
 SCR_W:=640;SCR_H:=480;
 If GetEnv('MAXIMDB')<>'' Then Begin DbDir:=GetEnv('MAXIMDB');DirGiven:=True;
   End;
 UserCode:='JNAPOLI';
 If GetEnv('CRMUSER')<>'' Then UserCode:=Upper(GetEnv('CRMUSER'));
 SqlArg:='';
 For Pi:=1 To ParamCount Do Begin
  Pa:=ParamStr(Pi);
  If (Pa='/?') Or (Pa='-h') Or (Pa='--help') Then Begin ShowHelpLine;Halt(0);
    End;
  If Upper(Copy(Pa,1,3))='/D:' Then Begin DbDir:=Copy(Pa,4,60);DirGiven:=True;
    End;
  If Upper(Copy(Pa,1,3))='/U:' Then UserCode:=Upper(Copy(Pa,4,12));
  If (Upper(Pa)='-MAXSCREEN') Or (Upper(Pa)='/MAXSCREEN') Then MaxScreen:=True;
  If Upper(Pa)='/SQL' Then Begin
   If Pi<ParamCount Then SqlArg:=ParamStr(Pi+1);
  End;
 End;
 DetectLanguage;
 SessDate:=TodayDate;
 DbInit;SqlInit;
 GetMem(TX,SizeOf(TTxtArr));
 GetMem(PickIt,SizeOf(TStrArr));
 GetMem(RBE,SizeOf(TRec));
 GetMem(ClipP,SizeOf(TBig));
 ClipLen:=0;NoDbl:=False;MailTo:='';CallNum:='';MailSubj:='';MailDoc:=0;
   LibMode:=0;LibCat:='';NLibIds:=0;
 TXN:=0;PickN:=0;
 FillChar(UdfNm,SizeOf(UdfNm),0);
 FillChar(UdfKd,SizeOf(UdfKd),'T');
 MX:=0;MY:=0;MB:=0;LastB:=0;LastClickT:=0;LastClickX:=0;LastClickY:=0;
 UiReady:=False;GfxOn:=False;NetOk:=False;SeedKind:=2;CfgNew:='CRM';
 ToolBarOn:=True;StatusOn:=True;Modu:=2;
 BuildMenus;BuildToolbar;
 MxLastTitle:='';CatCl:=0;CatFr:=0;MxCatWant:=False;MxCatOwn:=False;
 { ecran d'accueil : exemple, nouveau CRM vide ou CRM existant }
 If (Not DirGiven) And (SqlArg='') Then Begin
  InitializeGraphics;
  If MouseDriverFound Then ShowMouse;
  GfxOn:=True;
  If Not Splash Then Begin Dummy:=WinDestroyWindow(OsFrame);Halt(0);End;
 End;
 {$I-}
 MkDir(DbDir);
 {$I+}
 If IOResult<>0 Then ;
 NewDb:=Not FileExists(TblPath('abentry','frm'));
 If Not OpenTables Then Begin
  If GfxOn Then CloseGraph;
  WriteLn('Erreur base de donnees : ',DbErr);Halt(1);
 End;
 UdfLoad;
 If NewDb Then Begin
  If SeedKind=1 Then SeedBase(CfgNew,False)
  Else If SeedKind=2 Then SeedDemo;
 End;
 CfgGet;
 UdfLoad;
 If SqlArg<>'' Then Begin
  BatchSql(SqlArg);
  TblCloseAll;
  Halt(0);
 End;
 Quit:=False;Dirty:=True;ToolBarOn:=True;StatusOn:=True;
 StatMsg:='';TipIdx:=0;
 Modu:=2;Foc:=2;TabL:=1;TabR:=1;CurId:=0;WdPanel:=1;
 ShowFilter:=0;FilterSql:='';FilterName:='';NFilt:=0;NMark:=0;
 NoteType:='';NotePer:=1;HotMode:=4;CalDate:=SessDate;MailFold:='I';
 FillChar(Recent,SizeOf(Recent),0);
 MenuOpen:=0;MenuHi:=0;
 GridInit(GMain,tAB,MAXIDX,'NAME:176');
 GridInit(GSubL,tCO,300,'NAME:96');
 GridInit(GSubR,tNO,400,'ND:68');
 For Pi:=1 To 4 Do Begin
  If Pi In [1,2] Then GridInit(GW[Pi],tAP,40,'AT:40')
  Else If Pi=3 Then GridInit(GW[Pi],tOP,40,'NAME:80')
  Else GridInit(GW[Pi],tAB,40,'NAME:80');
 End;
 GridCols(GW[1],tAP,'AT:44,SUBJ:130,ENTRY_ID:68');
 GridCols(GW[2],tAP,'AD:88,SUBJ:100,ENTRY_ID:60');
 GridCols(GW[3],tOP,'CLOSEDT:88,NAME:100,AMOUNT:60');
 GridCols(GW[4],tAB,'NAME:150,MODIFIED:88');
 If Not GfxOn Then Begin
  InitializeGraphics;
  If MouseDriverFound Then ShowMouse;
 End;
 ComputeLayout;
 UiReady:=True;
 SetModule(2);
 MainLoop;
 TblCloseAll;
 Dummy := WinDestroyWindow(OsFrame);
END.
