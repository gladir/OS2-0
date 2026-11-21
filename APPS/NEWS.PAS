{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Clone de l'application News Master (publication de journaux),
                pour le Presentation Manager d'OS/2-0 (dossier Productivite)

  Portage vers OS/2-0 (OS2PC -COS2) de NEWS.PAS du depot OFFICE-0 : toute
  la mise en page est conservee (articles, colonnes, polices, images,
  pages, apercu). Pour OS/2 : fenetre de Presentation Manager, barre de
  menus d'OS/2 construite a partir des huit menus d'origine (coches et
  choix grises mis a jour a l'ouverture), dessin dans une image en
  memoire montree par GpiDrawBits (ecran de 640 x 449 : la page et le
  panneau des touches de fonction sont un peu moins hauts), boites de
  dialogue et messages de PM.
}

Program NEWS;

{ Impression Windows : active seulement avec Free Pascal pour Windows
  (pas dans la version pour OS/2-0). }

{$IFNDEF FPC}
 {$M 16384,0,655360}
{$ENDIF}


{ ====================================================================== }
{                              CONSTANTES                                }
{ ====================================================================== }

Const
 VERSION_TEXT = '1.00';
 SCR_W    = 640;
 SCR_H    = 449;        { 480 sous DOS : la fenetre de PM tient dans 640 x 480 }
 MENU_H   = 18;
 INK      = 0;
 PAPER    = 15;
 PANEL_Y  = 349;        { haut du panneau de touches de fonction }
 TBH      = 20;         { hauteur de la barre de titre des dialogues }
 NMENU    = 8;
 VW       = 640;        { zone d'affichage des pages }
 VH       = 330;

 { Page (en points a l'echelle 1:1) }
 HSZ      = 3;          { demi-taille des poignees de coin }
 PGW      = 960;
 PGH      = 760;
 PGGAP    = 16;
 MAXPG    = 4;
 MAXCOL   = 4;
 MRG      = 0;
 HEADH    = 152;
 COLGAP   = 30;
 MINSLOT  = 60;
 PAD      = 0;

 MAXFONT  = 40;
 MAXLINE  = 900;
 MAXREG   = 32;
 MAXART   = 48;
 MAXLIB   = 48;
 MAXBLIB  = 16;
 MAXSRC   = 12;
 MAXSH    = 170;
 STCAP    = 12000;
 HCAP     = 1200;
 CLIPCAP  = 6000;
 MAXCTL   = 24;

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
 K_CLEFT  = 371;
 K_CRIGHT = 372;
 K_CHOME  = 375;
 K_CEND   = 373;
 K_STAB   = 271;

 { Habillage du texte autour des objets }
 FL_OVER  = 0;
 FL_BOTH  = 1;
 FL_LEFT  = 2;
 FL_RIGHT = 3;
 FL_CLEAR = 4;

 { Types d'objets }
 AR_ART   = 1;
 AR_LINE  = 2;
 AR_BOX   = 3;

 { Modes d'edition (menu courant du panneau) }
 MD_MAIN   = 0;
 MD_VIEW   = 1;
 MD_TEXT   = 2;
 MD_ART    = 3;
 MD_LAYOUT = 4;
 MD_FILE   = 5;
 MD_PRINT  = 6;

 { Alignement des paragraphes }
 AL_LEFT   = 0;
 AL_RIGHT  = 1;
 AL_CENTER = 2;
 AL_BOTH   = 3;

{ ====================================================================== }
{                                TYPES                                   }
{ ====================================================================== }

Type
 TBytes = Array[0..65000] Of Byte;
 PBytes = ^TBytes;
 TWords = Array[0..255] Of Word;
 PWords = ^TWords;

 TStory = Record
  Len,Cap : Integer;
  T,F,A   : PBytes;       { caracteres, polices, alignement (sur les CR) }
 End;

 TLine = Record
  S,E,Nx   : Integer;     { debut, fin (exclue), debut de la ligne suivante }
  X,Y,W,H  : Integer;     { emplacement sur la page (points) }
  Asc,Lw   : Integer;     { ligne de base, largeur naturelle }
  Hg       : Integer;     { largeur des espaces terminales (centrage) }
  Ns       : Integer;     { nombre d'espaces }
  Sty,Pg,Al,Fl : Byte;    { histoire, page, alignement, 1 = fin de paragraphe }
 End;
 TLineArr = Array[0..MAXLINE] Of TLine;
 PLineArr = ^TLineArr;

 TPiece = Record
  Name : String[16];
  W,H  : Integer;
  B    : PBytes;          { bitmap monochrome, (W+7) div 8 octets par rangee }
 End;

 TArt = Record
  Kind,Flow,FH,FV,Pat,Th : Byte;
  Lib    : Integer;
  Pg     : Integer;
  X,Y,W,H : Integer;      { page, points }
  X2,Y2  : Integer;       { extremite d'une ligne }
  SX1,SY1,SX2,SY2 : Integer; { zone source (rognage) }
 End;

 TArtArr = Array[1..MAXART] Of TArt;
 TColArr = Array[1..MAXPG] Of Byte;
 THasArr = Array[1..MAXPG] Of Boolean;

 TEvent = Record
  { 0 rien, 1 touche, 2 bouton bas, 3 bouton haut, 4 mouvement }
  Kind : Byte;
  Key  : Word;
  X,Y,B: LongInt;
 End;

 TCtl = Record
  Kind,Id,Grp: Byte;
  X,Y,W,H: Integer;
  Txt: String[44];
  Str: String[40];
  Val: Integer;
  Sfx: String[3];
  Num,On: Boolean;
 End;

 TPBtn = Record
  Fk    : Byte;
  L1,L2,L3 : String[10];
  Ico   : Byte;
  On    : Boolean;
 End;

{ ====================================================================== }
{                              VARIABLES                                 }
{ ====================================================================== }

Var
 { Document }
 St        : Array[0..MAXPG] Of TStory;
 NPg       : Integer;
 NCol      : TColArr;
 HasHead   : THasArr;
 Arts      : TArtArr;
 NArt      : Integer;
 DocName   : String[79];
 Named,Modified : Boolean;

 { Polices }
 NFont     : Integer;
 FName     : Array[0..MAXFONT-1] Of String[26];
 FAsc,FDsc,FSpc,FGap,FKind : Array[0..MAXFONT-1] Of Integer;
 FPos,FLen : Array[0..MAXFONT-1] Of LongInt;
 FSys      : Array[0..MAXFONT-1] Of Byte;
 FBuf      : Array[0..MAXFONT-1] Of PBytes;
 FOff      : Array[0..MAXFONT-1] Of PWords;
 FAdv      : Array[0..MAXFONT-1] Of PBytes;
 FLBFile   : String[79];
 FLBFound,UseFLB : Boolean;
 DefBody,DefHead : Integer;
 G8        : Array[0..255,0..7] Of Byte;

 { Bibliotheque d'images }
 Lib       : Array[1..MAXLIB] Of TPiece;   { images du journal (copies) }
 NLib      : Integer;
 BLib      : Array[1..MAXBLIB] Of TPiece;  { images integrees }
 NBLib     : Integer;
 NSrc,SrcCur,SrcN : Integer;               { bibliotheques d'images }
 SrcBase   : Array[0..MAXSRC] Of String[79];
 SrcFD,SrcFX,SrcFS : Array[0..MAXSRC] Of String[79];
 SrcTitle  : Array[0..MAXSRC] Of String[12];
 SrcNm     : Array[1..MAXSH] Of String[15];
 SrcOff    : Array[1..MAXSH+1] Of LongInt;

 { Mise en page calculee }
 Lines     : PLineArr;
 NLn       : Integer;
 Overflow  : Boolean;
 NReg      : Integer;
 RegPg,RegX,RegY,RegW,RegH : Array[1..MAXREG] Of Integer;

 { Edition du texte }
 ASt       : Integer;          { histoire active }
 Cur,SelA  : Integer;
 CurFont   : Integer;
 MarkMode  : Boolean;
 WantX     : Integer;
 TypRun    : Boolean;
 ClipT,ClipF : PBytes;
 ClipN     : Integer;
 UndoT,UndoF,UndoA : PBytes;
 UndoLen,UndoCur,UndoSt : Integer;
 UndoOK    : Boolean;
 UKind,UTag,UNArt : Integer;   { 1 texte, 2 objets / mise en page }
 UArts     : TArtArr;
 UNCol     : TColArr;
 UHas      : THasArr;
 FindStr   : String[40];
 Lang      : Integer;          { 0 francais, 1 anglais, 2 allemand }

 { Edition des images }
 ACx,ACy   : LongInt;          { curseur d'images (coordonnees document) }
 ACStep    : Integer;
 SelArt    : Integer;
 Held      : TArt;
 HeldOn    : Boolean;
 ArtSub    : Integer;          { 0 normal, 1 taille, 2 rogner, 3 trace }
 CropEnd   : Integer;
 DrawKind  : Integer;
 DrawPat   : Integer;
 DrawTh    : Integer;
 DrawStep  : Integer;          { 0 hors tracage, 1 point de depart pose }
 DrawX0,DrawY0 : LongInt;
 LastPiece : Integer;

 { Affichage }
 Mode      : Integer;
 ZN,ZD     : Integer;          { echelle = ZN/ZD }
 ViewNo    : Integer;
 ScrX,ScrY : LongInt;
 GuidesOn  : Boolean;
 CurPage   : Integer;          { page courante (mise en page) }
 PB        : Array[1..10] Of TPBtn;
 NPB       : Integer;
 PanelTitle : String[40];
 PBDown    : Integer;

 { Souris / evenements }
 MX,MY,MB,LastB : LongInt;
 PrevMX,PrevMY  : LongInt;
 Quit,NeedDraw  : Boolean;
 MenuOpen,MenuHi : Integer;
 Dragging  : Integer;
 DragOX,DragOY : LongInt;
 DragA     : TArt;             { objet avant le debut de la poignee }
 DragCorner: Integer;          { 0 haut-gauche, 1 haut-droit, 2 bas-gauche... }
 DragPushed: Boolean;
 CaretOn   : Boolean;
 CaretT    : LongInt;
 LastClickT : LongInt;
 LastFill  : Integer;
 StatusMsg : String[60];
 StatusT   : LongInt;

 { Dialogues }
 DC        : Array[1..MAXCTL] Of TCtl;
 NDC       : Integer;
 DlgX,DlgY,DlgW,DlgH,DlgFocus,DlgId : Integer;
 DlgFresh  : Boolean;
 DlgTitle  : String[44];

Const
 C_LABEL  = 1;
 C_EDIT   = 2;
 C_CHECK  = 3;
 C_RADIO  = 4;
 C_BTN    = 5;
 C_POP    = 6;
 C_GROUP  = 7;

 PatStripe : FillPatternType = ($88,$88,$88,$88,$88,$88,$88,$88);
 PatGrey   : FillPatternType = ($AA,$55,$AA,$55,$AA,$55,$AA,$55);
 PatLight  : FillPatternType = ($88,$00,$22,$00,$88,$00,$22,$00);
 PatDark   : FillPatternType = ($EE,$BB,$EE,$BB,$EE,$BB,$EE,$BB);
 PatHatch  : FillPatternType = ($88,$44,$22,$11,$88,$44,$22,$11);
 PatHatch2 : FillPatternType = ($11,$22,$44,$88,$11,$22,$44,$88);
 PatHoriz  : FillPatternType = ($FF,$00,$00,$00,$FF,$00,$00,$00);
 PatVert   : FillPatternType = ($88,$88,$88,$88,$88,$88,$88,$88);
 PatGrid   : FillPatternType = ($FF,$88,$88,$88,$FF,$88,$88,$88);
 PatBrick  : FillPatternType = ($FF,$80,$80,$80,$FF,$08,$08,$08);
 PatDots   : FillPatternType = ($80,$00,$08,$00,$80,$00,$08,$00);
 NPAT      = 30;
 OPat : Array[0..29] Of FillPatternType = (
  ($FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF),
  ($7F,$FF,$FF,$FF,$7F,$FF,$FF,$FF),
  ($7F,$FF,$F7,$FF,$7F,$FF,$F7,$FF),
  ($3F,$FF,$F3,$FF,$3F,$FF,$F3,$FF),
  ($7F,$EF,$FD,$DF,$FE,$F7,$BF,$FB),
  ($33,$FF,$CC,$FF,$33,$FF,$CC,$FF),
  ($33,$CC,$33,$CC,$33,$CC,$33,$CC),
  ($55,$55,$55,$55,$55,$55,$55,$55),
  ($44,$11,$44,$11,$44,$11,$44,$11),
  ($CC,$00,$33,$00,$CC,$00,$33,$00),
  ($80,$10,$02,$20,$01,$08,$40,$04),
  ($C0,$00,$0C,$00,$C0,$00,$0C,$00),
  ($80,$00,$08,$00,$80,$00,$08,$00),
  ($80,$00,$00,$00,$80,$00,$00,$00),
  ($00,$00,$00,$00,$00,$00,$00,$00),
  ($33,$33,$33,$33,$33,$33,$33,$33),
  ($00,$FF,$00,$FF,$00,$FF,$00,$FF),
  ($0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F),
  ($00,$00,$FF,$FF,$00,$00,$FF,$FF),
  ($1F,$C7,$F1,$7C,$1F,$C7,$F1,$7C),
  ($E0,$38,$0E,$83,$E0,$38,$0E,$83),
  ($F8,$E3,$8F,$3E,$F8,$E3,$8F,$3E),
  ($07,$1C,$70,$C1,$07,$1C,$70,$C1),
  ($7F,$BF,$DF,$FF,$FD,$FB,$F7,$FF),
  ($80,$40,$20,$00,$02,$04,$08,$00),
  ($7F,$BE,$DD,$EB,$F7,$EB,$DD,$BE),
  ($80,$41,$22,$14,$08,$14,$22,$41),
  ($00,$3F,$3F,$3F,$00,$F3,$F3,$F3),
  ($4C,$7C,$7C,$BB,$C4,$C7,$C7,$BB),
  ($F8,$74,$22,$47,$8F,$17,$22,$71));


{ ====================================================================== }
{                  GRAPHIQUE / SOURIS (squelette)                        }
{ ====================================================================== }

Const
 CanvasTop = MENU_H;
 CanvasBot = SCR_H - 1;

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
 OpenWindow('NEWS', 'News Master');
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
{                       UTILITAIRES GENERAUX                             }
{ ====================================================================== }

Function IntStr(N: LongInt): String;
Var S: String;
Begin
 Str(N,S);
 IntStr:=S;
End;

Function Upper(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do S[I]:=UpCase(S[I]);
 Upper:=S;
End;

Function TrimStr(S: String): String;
Begin
 While (Length(S)>0) And (S[1]=' ') Do Delete(S,1,1);
 While (Length(S)>0) And (S[Length(S)]=' ') Do Delete(S,Length(S),1);
 TrimStr:=S;
End;



Function Clamp(V,Lo,Hi: LongInt): LongInt;
Begin
 If V<Lo Then V:=Lo;
 If V>Hi Then V:=Hi;
 Clamp:=V;
End;

Function ValInt(Const S: String; Def: LongInt): LongInt;
Var V: LongInt; Code: Integer; T: String;
Begin
 T:=TrimStr(S);
 Val(T,V,Code);
 If (Code<>0) Or (T='') Then ValInt:=Def Else ValInt:=V;
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

Function NoExt(Const N: String): String;
Var I: Integer;
Begin
 I:=Length(N);
 While (I>0) And (N[I]<>'.') And (N[I]<>'\') And (N[I]<>'/') Do Dec(I);
 If (I>0) And (N[I]='.') Then NoExt:=Copy(N,1,I-1) Else NoExt:=N;
End;

Function Tick: LongInt;
Var H,M,S,S100: Word;
Begin
 GetTime(H,M,S,S100);
 Tick:=((LongInt(H)*60+M)*60+S)*100+S100;
End;

Function InBox(X,Y,X1,Y1,X2,Y2: LongInt): Boolean;
Begin
 InBox:=(X>=X1) And (X<=X2) And (Y>=Y1) And (Y<=Y2);
End;

Function HeapOK(Sz: LongInt): Boolean;
Begin
 {$IFDEF FPC}
 HeapOK:=True;
 {$ELSE}
 HeapOK:=MaxAvail>=Sz;
 {$ENDIF}
End;

Function Tr(Const S: String): String; Forward;

Procedure SetStatus(Const S: String);
Begin
 StatusMsg:=Tr(S);
 StatusT:=Tick;
 NeedDraw:=True;
End;

{ ====================================================================== }
{                       PRIMITIVES GRAPHIQUES (GUI)                      }
{ ====================================================================== }

Procedure SetFill(C: Integer);
Begin
 If LastFill<>C Then Begin SetFillStyle(SolidFill,C);LastFill:=C;End;
End;

Procedure Box(X1,Y1,X2,Y2,C: Integer);
Begin
 SetFill(C);
 Bar(X1,Y1,X2,Y2);
End;

Procedure Frame(X1,Y1,X2,Y2: Integer);
Begin
 SetColor(INK);
 SetLineStyle(SolidLn,0,1);
 Rectangle(X1,Y1,X2,Y2);
End;

Procedure SetPat(Const Pat: FillPatternType);
Var Q: FillPatternType; I: Integer;
Begin
 For I:=1 To 8 Do Q[I]:=Not Pat[I];
 SetFillPattern(Q,PAPER);
 LastFill:=-1;
End;

Procedure PatBar(X1,Y1,X2,Y2: Integer; Const Pat: FillPatternType);
Begin
 SetPat(Pat);
 Bar(X1,Y1,X2,Y2);
End;

Procedure PText(X,Y: Integer; Const S: String);
Begin
 SetColor(INK);
 OutTextXY(X,Y,S);
End;

Procedure BText(X,Y: Integer; Const S: String);
Begin
 SetColor(INK);
 OutTextXY(X,Y,S);
 OutTextXY(X+1,Y,S);
End;

Procedure WText(X,Y: Integer; Const S: String);
Begin
 SetColor(PAPER);
 OutTextXY(X,Y,S);
End;

Function TextW(Const S: String): Integer;
Var I,N: Integer;
Begin
 N:=0;
 For I:=1 To Length(S) Do If S[I]<>'&' Then Inc(N);
 TextW:=N*8;
End;

{ Texte avec lettre soulignee : '&' precede la lettre }
Procedure UText(X,Y: Integer; Const S: String; Col: Integer);
Var I,P: Integer; Mark: Boolean;
Begin
 SetColor(Col);
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

Procedure GreyText(X,Y: Integer; Const S: String);
Var I,J,W: Integer;
Begin
 PText(X,Y,S);
 W:=TextW(S);
 For J:=0 To 7 Do
  For I:=0 To W-1 Do
   If Odd(I+J) Then
    If GetPixel(X+I,Y+J)=INK Then PutPixel(X+I,Y+J,PAPER);
End;

{ Boite ombree avec texte centre (etiquette du panneau) }
Procedure LabelBox(X1,Y1,X2,Y2: Integer; Const S: String);
Begin
 Box(X1+3,Y1+3,X2+3,Y2+3,INK);
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);
 Frame(X1+1,Y1+1,X2-1,Y2-1);
 BText((X1+X2+1-TextW(S)) Div 2,(Y1+Y2-6) Div 2,S);
End;

Procedure ArrowBox(X1,Y1,X2,Y2,Dir: Integer);
{ Dir : 1 haut, 2 bas, 3 gauche, 4 droite }
Var Pt: Array[1..3] Of PointType; CX,CY: Integer;
Begin
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);
 CX:=(X1+X2) Div 2;CY:=(Y1+Y2) Div 2;
 Case Dir Of
  1: Begin
    Pt[1].X:=CX;Pt[1].Y:=CY-3;Pt[2].X:=CX-4;Pt[2].Y:=CY+3;Pt[3].X:=CX+4;
    Pt[3].Y:=CY+3;End;
  2: Begin
    Pt[1].X:=CX;Pt[1].Y:=CY+3;Pt[2].X:=CX-4;Pt[2].Y:=CY-3;Pt[3].X:=CX+4;
    Pt[3].Y:=CY-3;End;
  3: Begin
    Pt[1].X:=CX-3;Pt[1].Y:=CY;Pt[2].X:=CX+3;Pt[2].Y:=CY-4;Pt[3].X:=CX+3;
    Pt[3].Y:=CY+4;End;
  4: Begin
    Pt[1].X:=CX+3;Pt[1].Y:=CY;Pt[2].X:=CX-3;Pt[2].Y:=CY-4;Pt[3].X:=CX-3;
    Pt[3].Y:=CY+4;End;
 End;
 SetFillStyle(SolidFill,INK);LastFill:=-1;
 SetColor(INK);
 FillPoly(3,Pt);
End;

{ Bouton GEM : OK (Def) a double bordure }
Procedure Button(X1,Y1,X2,Y2: Integer; Const S0: String; Def,Enabled: Boolean);
Var TX: Integer; S: String;
Begin
 S:=Tr(S0);
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);
 If Def Then Begin Frame(X1+1,Y1+1,X2-1,Y2-1);Frame(X1-1,Y1-1,X2+1,Y2+1);End;
 TX:=(X1+X2+1-TextW(S)) Div 2;
 If Enabled Then UText(TX,(Y1+Y2-6) Div 2,S,INK)
 Else GreyText(TX,(Y1+Y2-6) Div 2,S);
End;

{ ====================================================================== }
{                  EVENEMENTS (clavier / souris)                         }
{ ====================================================================== }

Procedure CmdQuit; Forward;

Procedure PollEvent(Var E: TEvent);
Var Ch: Char; K: Word; C: LongInt;
Begin
 E.Kind:=0;E.Key:=0;E.X:=MX;E.Y:=MY;E.B:=MB;
 { barre de menus de PM }
 While PollCmd(C) Do Begin
  If C=CMD_CLOSE Then CmdQuit
  Else If (C>132) And (C<100+32*(NMENU+1)) Then
   If ((C-100) Mod 32>=1) And ((C-100) Mod 32<=MCount((C-100) Div 32)) Then
    If MEnabled((C-100) Div 32,(C-100) Mod 32) Then DoMenu((C-100) Div 32,(C-100) Mod 32);
  NeedDraw:=True;
  E.Kind:=5;
  Exit;
 End;
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

Function TrEN(Const S: String): String;
Begin
 TrEN:='';
 If S='NEWSMASTER - CLONE VERSION ' Then Begin
   TrEN:='NEWSMASTER - CLONE VERSION ';Exit;End;
 If S='PROGRAMME DE PUBLICATION DE JOURNAUX' Then Begin
   TrEN:='NEWSLETTER PUBLISHING PROGRAM';Exit;End;
 If S='D''APRES NEWS MASTER (UNISON WORLD, 1986)' Then Begin
   TrEN:='BASED ON NEWS MASTER (UNISON WORLD, 1986)';Exit;End;
 If S='APPUYEZ SUR ESPACE POUR CONTINUER' Then Begin
   TrEN:='PRESS SPACE TO CONTINUE';Exit;End;
 If S='NewsMaster : Menu principal' Then Begin TrEN:='NewsMaster: Main Menu';
   Exit;End;
 If S='Choisissez une activit'#130' :' Then Begin TrEN:='Choose an activity:';
   Exit;End;
 If S='Commencer un nouveau journal' Then Begin
   TrEN:='Start work on a new newsletter';Exit;End;
 If S='Continuer le journal courant' Then Begin
   TrEN:='Continue working on the current newsletter';Exit;End;
 If S='Choisir un journal enregistr'#130 Then Begin
   TrEN:='Select a saved newsletter to work on';Exit;End;
 If S='Quitter NewsMaster' Then Begin TrEN:='Quit NewsMaster';Exit;End;
 If S='ENTR'#144'E : POINT FINAL' Then Begin TrEN:='ENTER: END POINT';Exit;End;
 If S='OBJET AJOUT'#144 Then Begin TrEN:='OBJECT ADDED';Exit;End;
 If S='Clone graphique du programme de publication de journaux News Master.'
   Then Begin
   TrEN:='Graphical clone of the News Master newsletter publishing program.';
   Exit;End;
 If S='Utilisation : NEWS [fichier.NWS] [/?]' Then Begin
   TrEN:='Usage: NEWS [file.NWS] [/?]';Exit;End;
 If S='fichier.NWS  Journal '#133' ouvrir.' Then Begin
   TrEN:='file.NWS     Newsletter to open.';Exit;End;
 If S='/?           Affiche cette aide.' Then Begin
   TrEN:='/?           Show this help.';Exit;End;
 If S='Langue : fran'#135'ais par d'#130'faut. LANGUAGE=EN : anglais, '+
   'LANGUAGE=GR : allemand.' Then Begin
   TrEN:='Language: French by default. LANGUAGE=EN: English, LANGUAGE=GR: '+
   'German.';Exit;End;
 If S='Place NEWS.FLB dans le r'#130'pertoire courant pour utiliser les '+
   'polices originales.' Then Begin
   TrEN:='Put NEWS.FLB in the current directory to use the original fonts.';
   Exit;End;
 If S='Couverts' Then Begin TrEN:='Cutlery';Exit;End;
 If S='Poisson' Then Begin TrEN:='Fish';Exit;End;
 If S='Etoile' Then Begin TrEN:='Star';Exit;End;
 If S='Soleil' Then Begin TrEN:='Sun';Exit;End;
 If S='Maison' Then Begin TrEN:='House';Exit;End;
 If S='Arbre' Then Begin TrEN:='Tree';Exit;End;
 If S='Ciseaux' Then Begin TrEN:='Scissors';Exit;End;
 If S='Ballon' Then Begin TrEN:='Balloon';Exit;End;
 If S='Telephone' Then Begin TrEN:='Telephone';Exit;End;
 If S='Coeur' Then Begin TrEN:='Heart';Exit;End;
 If S='Fleche' Then Begin TrEN:='Arrow';Exit;End;
 If S='Journal' Then Begin TrEN:='Newspaper';Exit;End;
 If S='Tasse' Then Begin TrEN:='Cup';Exit;End;
 If S='Livre' Then Begin TrEN:='Book';Exit;End;
 If S='Gauche' Then Begin TrEN:='Left';Exit;End;
 If S='Droite' Then Begin TrEN:='Right';Exit;End;
 If S='Centr'#130 Then Begin TrEN:='Centered';Exit;End;
 If S='Justifi'#130 Then Begin TrEN:='Justified';Exit;End;
 If S='Texte par-dessus' Then Begin TrEN:='Text over art';Exit;End;
 If S='Texte des deux c'#147't'#130's' Then Begin TrEN:='Text on both sides';
   Exit;End;
 If S='Texte '#133' gauche seul' Then Begin TrEN:='Text on left only';Exit;End;
 If S='Texte '#133' droite seul' Then Begin TrEN:='Text on right only';Exit;End;
 If S='Zone d'#130'gag'#130'e' Then Begin TrEN:='Keep clear';Exit;End;
 If S='Grand pas (16)' Then Begin TrEN:='Big step (16)';Exit;End;
 If S='Pas moyen (4)' Then Begin TrEN:='Medium step (4)';Exit;End;
 If S='Un point (1)' Then Begin TrEN:='One dot (1)';Exit;End;
 If S='Ligne' Then Begin TrEN:='Line';Exit;End;
 If S='Bo'#140'te' Then Begin TrEN:='Box';Exit;End;
 If S='Horizontalement' Then Begin TrEN:='Horizontally';Exit;End;
 If S='Verticalement' Then Begin TrEN:='Vertically';Exit;End;
 If S='&Oui' Then Begin TrEN:='&Yes';Exit;End;
 If S='&Non' Then Begin TrEN:='&No';Exit;End;
 If S='&Annuler' Then Begin TrEN:='&Cancel';Exit;End;
 If S='Fichier' Then Begin TrEN:='File';Exit;End;
 If S='Edition' Then Begin TrEN:='Edit';Exit;End;
 If S='Texte' Then Begin TrEN:='Text';Exit;End;
 If S='Image' Then Begin TrEN:='Artwork';Exit;End;
 If S='Page' Then Begin TrEN:='Page';Exit;End;
 If S='Vue' Then Begin TrEN:='View';Exit;End;
 If S='Options' Then Begin TrEN:='Options';Exit;End;
 If S=#192' propos de NewsMaster...' Then Begin TrEN:='About NewsMaster...';
   Exit;End;
 If S='Statistiques...' Then Begin TrEN:='Statistics...';Exit;End;
 If S='M'#130'moire libre' Then Begin TrEN:='Free memory';Exit;End;
 If S='Menu principal...' Then Begin TrEN:='Main menu...';Exit;End;
 If S='Nouveau|^N' Then Begin TrEN:='New|^N';Exit;End;
 If S='Ouvrir...|^O' Then Begin TrEN:='Open...|^O';Exit;End;
 If S='Enregistrer|^S' Then Begin TrEN:='Save|^S';Exit;End;
 If S='Enregistrer sous...' Then Begin TrEN:='Save as...';Exit;End;
 If S='Importer texte ASCII...' Then Begin TrEN:='Import ASCII text...';Exit;
   End;
 If S='Exporter texte ASCII...' Then Begin TrEN:='Export ASCII text...';Exit;
   End;
 If S='Imprimer la page (PBM)...' Then Begin TrEN:='Print page (PBM)...';Exit;
   End;
 If S='Imprimer tout (PBM)...' Then Begin TrEN:='Print all (PBM)...';Exit;End;
 If S='Quitter|^Q' Then Begin TrEN:='Quit|^Q';Exit;End;
 If S='Annuler|^Z' Then Begin TrEN:='Undo|^Z';Exit;End;
 If S='Couper|^X' Then Begin TrEN:='Cut|^X';Exit;End;
 If S='Copier|^C' Then Begin TrEN:='Copy|^C';Exit;End;
 If S='Coller|^V' Then Begin TrEN:='Paste|^V';Exit;End;
 If S='Effacer|Suppr' Then Begin TrEN:='Clear|Del';Exit;End;
 If S='Tout s'#130'lectionner|^A' Then Begin TrEN:='Select all|^A';Exit;End;
 If S='Chercher...|^F' Then Begin TrEN:='Find...|^F';Exit;End;
 If S='Chercher suivant|^G' Then Begin TrEN:='Find next|^G';Exit;End;
 If S='Choisir la police...|^T' Then Begin TrEN:='Choose font...|^T';Exit;End;
 If S='Police pr'#130'c'#130'dente' Then Begin TrEN:='Previous font';Exit;End;
 If S='Police suivante' Then Begin TrEN:='Next font';Exit;End;
 If S='Aligner '#133' gauche|^L' Then Begin TrEN:='Align left|^L';Exit;End;
 If S='Aligner '#133' droite|^R' Then Begin TrEN:='Align right|^R';Exit;End;
 If S='Centrer|^E' Then Begin TrEN:='Center|^E';Exit;End;
 If S='Justifier|^J' Then Begin TrEN:='Justify|^J';Exit;End;
 If S='Marquer la s'#130'lection' Then Begin TrEN:='Mark selection';Exit;End;
 If S='Mode '#130'dition du texte|F2' Then Begin TrEN:='Text edit mode|F2';Exit;
   End;
 If S='Mode '#130'dition d''images|F3' Then Begin TrEN:='Artwork edit mode|F3';
   Exit;End;
 If S='Choisir une image...|F1' Then Begin TrEN:='Choose artwork...|F1';Exit;
   End;
 If S='Prendre|F2' Then Begin TrEN:='Pick up|F2';Exit;End;
 If S='Prendre une copie|F3' Then Begin TrEN:='Pick up a copy|F3';Exit;End;
 If S='Poser|Entr'#130'e' Then Begin TrEN:='Stamp down|Enter';Exit;End;
 If S='Supprimer|Suppr' Then Begin TrEN:='Delete|Del';Exit;End;
 If S='Agrandir|+' Then Begin TrEN:='Enlarge|+';Exit;End;
 If S='R'#130'duire|-' Then Begin TrEN:='Shrink|-';Exit;End;
 If S='Taille d''origine' Then Begin TrEN:='Original size';Exit;End;
 If S='Retourner horizontal.' Then Begin TrEN:='Flip horizontally';Exit;End;
 If S='Retourner vertical.' Then Begin TrEN:='Flip vertically';Exit;End;
 If S='Tracer une ligne' Then Begin TrEN:='Draw a line';Exit;End;
 If S='Tracer une bo'#140'te' Then Begin TrEN:='Draw a box';Exit;End;
 If S='Motif de remplissage...' Then Begin TrEN:='Fill pattern...';Exit;End;
 If S=#144'paisseur du trait...' Then Begin TrEN:='Line thickness...';Exit;End;
 If S='Mode mise en page|F4' Then Begin TrEN:='Page layout mode|F4';Exit;End;
 If S='Ajouter une colonne' Then Begin TrEN:='Add a column';Exit;End;
 If S='Supprimer une colonne' Then Begin TrEN:='Delete a column';Exit;End;
 If S='Ajouter un titre' Then Begin TrEN:='Add a headline';Exit;End;
 If S='Supprimer le titre' Then Begin TrEN:='Delete the headline';Exit;End;
 If S='Ajouter une page' Then Begin TrEN:='Add a page';Exit;End;
 If S='Supprimer la page' Then Begin TrEN:='Delete the page';Exit;End;
 If S='Page pr'#130'c'#130'dente|PgHaut' Then Begin TrEN:='Previous page|PgUp';
   Exit;End;
 If S='Page suivante|PgBas' Then Begin TrEN:='Next page|PgDn';Exit;End;
 If S=#133' la page...' Then Begin TrEN:='Go to page...';Exit;End;
 If S='Zoom avant (x2)' Then Begin TrEN:='Zoom in (x2)';Exit;End;
 If S='Vue normale' Then Begin TrEN:='Normal view';Exit;End;
 If S='Largeur de la page' Then Begin TrEN:='Page width';Exit;End;
 If S='Page enti'#138're' Then Begin TrEN:='Whole page';Exit;End;
 If S='Pas du curseur : grand' Then Begin TrEN:='Cursor step: big';Exit;End;
 If S='Pas du curseur : moyen' Then Begin TrEN:='Cursor step: medium';Exit;End;
 If S='Pas du curseur : point' Then Begin TrEN:='Cursor step: dot';Exit;End;
 If S='Polices de NEWS.FLB' Then Begin TrEN:='Fonts from NEWS.FLB';Exit;End;
 If S='Guides de colonnes' Then Begin TrEN:='Column guides';Exit;End;
 If S='Afficher les infos...' Then Begin TrEN:='About...';Exit;End;
 If S='MENU D'''#144'DITION PRINCIPAL' Then Begin TrEN:='MAIN EDIT MENU';Exit;
   End;
 If S='VUE' Then Begin TrEN:='VIEW';Exit;End;
 If S='TEXTE' Then Begin TrEN:='TEXT';Exit;End;
 If S='IMAGES' Then Begin TrEN:='ART';Exit;End;
 If S='PAGE' Then Begin TrEN:='PAGE';Exit;End;
 If S='FICHIER' Then Begin TrEN:='FILE';Exit;End;
 If S='IMPRIM.' Then Begin TrEN:='PRINT';Exit;End;
 If S='CHANGER LA VUE DU JOURNAL' Then Begin TrEN:='CHANGE THE PAGE VIEW';Exit;
   End;
 If S='ZOOM|AVANT' Then Begin TrEN:='ZOOM|IN';Exit;End;
 If S='VUE|NORMALE' Then Begin TrEN:='NORMAL|VIEW';Exit;End;
 If S='LARGEUR|DE PAGE' Then Begin TrEN:='PAGE|WIDTH';Exit;End;
 If S='PAGE|ENTI'#138'RE' Then Begin TrEN:='WHOLE|PAGE';Exit;End;
 If S='PAGE|PR'#144'C.' Then Begin TrEN:='PREV.|PAGE';Exit;End;
 If S='PAGE|SUIV.' Then Begin TrEN:='NEXT|PAGE';Exit;End;
 If S='MODIFIER LE TEXTE' Then Begin TrEN:='EDIT TEXT';Exit;End;
 If S='CHOISIR|POLICE' Then Begin TrEN:='CHOOSE|FONT';Exit;End;
 If S='ALIGNE-|MENT' Then Begin TrEN:='ALIGN-|MENT';Exit;End;
 If S='S'#144'LEC-|TION' Then Begin TrEN:='SELECT';Exit;End;
 If S='COUPER' Then Begin TrEN:='CUT';Exit;End;
 If S='COPIER' Then Begin TrEN:='COPY';Exit;End;
 If S='COLLER' Then Begin TrEN:='PASTE';Exit;End;
 If S='IMPORT|ASCII' Then Begin TrEN:='IMPORT|ASCII';Exit;End;
 If S='ANNULER' Then Begin TrEN:='UNDO';Exit;End;
 If S='MODIFIER LES IMAGES' Then Begin TrEN:='EDIT ARTWORK';Exit;End;
 If S='CHOISIR|IMAGE' Then Begin TrEN:='CHOOSE|ART';Exit;End;
 If S='PRENDRE' Then Begin TrEN:='PICK UP';Exit;End;
 If S='PRENDRE|COPIE' Then Begin TrEN:='PICK UP|COPY';Exit;End;
 If S='POSER' Then Begin TrEN:='STAMP';Exit;End;
 If S='TAILLE' Then Begin TrEN:='SIZE';Exit;End;
 If S='ROGNER' Then Begin TrEN:='CROP';Exit;End;
 If S='HABIL-|LAGE' Then Begin TrEN:='TEXT|FLOW';Exit;End;
 If S='RETOUR-|NER' Then Begin TrEN:='FLIP';Exit;End;
 If S='LIGNE|BO'#139'TE' Then Begin TrEN:='LINE|BOX';Exit;End;
 If S='SUPPR.' Then Begin TrEN:='DELETE';Exit;End;
 If S='MODIFIER LA MISE EN PAGE' Then Begin TrEN:='EDIT THE PAGE LAYOUT';Exit;
   End;
 If S='AJOUT|COLONNE' Then Begin TrEN:='ADD|COLUMN';Exit;End;
 If S='SUPPR.|COLONNE' Then Begin TrEN:='DELETE|COLUMN';Exit;End;
 If S='AJOUT|TITRE' Then Begin TrEN:='ADD|HEAD|LINE';Exit;End;
 If S='SUPPR.|TITRE' Then Begin TrEN:='DELETE|HEAD|LINE';Exit;End;
 If S='AJOUT|PAGE' Then Begin TrEN:='ADD|PAGE';Exit;End;
 If S='SUPPR.|PAGE' Then Begin TrEN:='DELETE|PAGE';Exit;End;
 If S='CHARGER ET ENREGISTRER' Then Begin TrEN:='LOAD AND SAVE NEWSLETTER';Exit;
   End;
 If S='NOUVEAU' Then Begin TrEN:='NEW';Exit;End;
 If S='OUVRIR' Then Begin TrEN:='LOAD';Exit;End;
 If S='ENREG.' Then Begin TrEN:='SAVE';Exit;End;
 If S='ENREG.|SOUS' Then Begin TrEN:='SAVE|AS';Exit;End;
 If S='MENU|PRINC.' Then Begin TrEN:='MAIN|MENU';Exit;End;
 If S='QUITTER' Then Begin TrEN:='QUIT';Exit;End;
 If S='IMPRIMER LE JOURNAL' Then Begin TrEN:='PRINT NEWSLETTER';Exit;End;
 If S='CETTE|PAGE' Then Begin TrEN:='THIS|PAGE';Exit;End;
 If S='TOUTES|PAGES' Then Begin TrEN:='ALL|PAGES';Exit;End;
 If S='EXPORT|TEXTE' Then Begin TrEN:='EXPORT|TEXT';Exit;End;
 If S='ZOOM X2' Then Begin TrEN:='ZOOM X2';Exit;End;
 If S='NORMALE' Then Begin TrEN:='NORMAL';Exit;End;
 If S='LARGEUR' Then Begin TrEN:='WIDTH';Exit;End;
 If S='PAGE ENTI'#138'RE' Then Begin TrEN:='WHOLE PAGE';Exit;End;
 If S='PAS ' Then Begin TrEN:='STEP ';Exit;End;
 If S='ROGNAGE' Then Begin TrEN:='CROP';Exit;End;
 If S='TRAC'#144 Then Begin TrEN:='DRAW';Exit;End;
 If S='SANS NOM' Then Begin TrEN:='UNNAMED';Exit;End;
 If S='PAGE ' Then Begin TrEN:='PAGE ';Exit;End;
 If S='TEXTE EN TROP' Then Begin TrEN:='TEXT OVERFLOW';Exit;End;
 If S='MISE EN PAGE - PAGE ' Then Begin TrEN:='PAGE LAYOUT - PAGE ';Exit;End;
 If S=' COLONNES' Then Begin TrEN:=' COLUMNS';Exit;End;
 If S=' COLONNE' Then Begin TrEN:=' COLUMN';Exit;End;
 If S=' + TITRE' Then Begin TrEN:=' + HEADLINE';Exit;End;
 If S='TEXTE TROP LONG' Then Begin TrEN:='TEXT TOO LONG';Exit;End;
 If S=' CARACT'#138'RES COPI'#144'S' Then Begin TrEN:=' CHARACTERS COPIED';Exit;
   End;
 If S='MARQUEZ AVEC LES FL'#138'CHES' Then Begin
   TrEN:='MARK WITH THE ARROW KEYS';Exit;End;
 If S='S'#144'LECTION FIX'#144'E' Then Begin TrEN:='SELECTION FIXED';Exit;End;
 If S='Choisir une police' Then Begin TrEN:='Choose Font';Exit;End;
 If S=' polices' Then Begin TrEN:=' fonts';Exit;End;
 If S='int'#130'gr'#130'es' Then Begin TrEN:='built-in';Exit;End;
 If S='INTROUVABLE' Then Begin TrEN:='NOT FOUND';Exit;End;
 If S='Chercher' Then Begin TrEN:='Find';Exit;End;
 If S='Texte '#133' chercher :' Then Begin TrEN:='Text to find:';Exit;End;
 If S='TROP D''OBJETS' Then Begin TrEN:='TOO MANY OBJECTS';Exit;End;
 If S='RIEN A POSER' Then Begin TrEN:='NOTHING TO STAMP';Exit;End;
 If S='AUCUNE IMAGE ICI' Then Begin TrEN:='NO ARTWORK HERE';Exit;End;
 If S='Choisir une image' Then Begin TrEN:='Choose Artwork';Exit;End;
 If S='Fl'#138'ches : choisir  Entr'#130'e : valider' Then Begin
   TrEN:='Arrows: choose  Enter: accept';Exit;End;
 If S='M'#138'ME PAGE SVP' Then Begin TrEN:='SAME PAGE PLEASE';Exit;End;
 If S='ENTR'#144'E : POINT DE D'#144'PART' Then Begin
   TrEN:='ENTER: START POINT';Exit;End;
 If S='Motif de remplissage' Then Begin TrEN:='Fill Pattern';Exit;End;
 If S=#144'paisseur' Then Begin TrEN:='Thickness';Exit;End;
 If S='Epaisseur du trait (1-30) :' Then Begin TrEN:='Line thickness (1-30):';
   Exit;End;
 If S='MAXIMUM : ' Then Begin TrEN:='MAXIMUM: ';Exit;End;
 If S='UNE COLONNE MINIMUM' Then Begin TrEN:='AT LEAST ONE COLUMN';Exit;End;
 If S='TITRE D'#144'J'#133' PR'#144'SENT' Then Begin
   TrEN:='HEADLINE ALREADY THERE';Exit;End;
 If S='Titre' Then Begin TrEN:='Headline';Exit;End;
 If S=' PAGES' Then Begin TrEN:=' PAGES';Exit;End;
 If S='IMPOSSIBLE : UNE PAGE' Then Begin TrEN:='IMPOSSIBLE: ONE PAGE ONLY';Exit;
   End;
 If S='TEXTE TRONQU'#144 Then Begin TrEN:='TEXT TRUNCATED';Exit;End;
 If S='Fichier :' Then Begin TrEN:='File:';Exit;End;
 If S='(aucun fichier ' Then Begin TrEN:='(no file ';Exit;End;
 If S='Impression de la page ' Then Begin TrEN:='Printing page ';Exit;End;
 If S='Impression' Then Begin TrEN:='Printing';Exit;End;
 If S='Page ' Then Begin TrEN:='Page ';Exit;End;
 If S=' enregistr'#130'e dans ' Then Begin TrEN:=' saved in ';Exit;End;
 If S='Pages enregistr'#130'es : ' Then Begin TrEN:='Pages saved: ';Exit;End;
  If S='Imprimer la page...' Then Begin TrEN:='Print page...';Exit;End;
 If S='Imprimer tout...' Then Begin TrEN:='Print all...';Exit;End;
 If S='Envoi '#133' l''imprimante ...' Then Begin
   TrEN:='Sending to the printer ...';Exit;End;
 If S='Imprim'#130' sur : ' Then Begin TrEN:='Printed on: ';Exit;End;
 If S='Page(s) : ' Then Begin TrEN:='Page(s): ';Exit;End;
 If S='Erreur d''impression Windows.' Then Begin
   TrEN:='Windows printing error.';Exit;End;
 If S='(sans nom)' Then Begin TrEN:='(untitled)';Exit;End;
 If S='Journal : ' Then Begin TrEN:='Newsletter: ';Exit;End;
 If S='Page courante : ' Then Begin TrEN:='Current page: ';Exit;End;
 If S='Colonnes : ' Then Begin TrEN:='Columns: ';Exit;End;
 If S='Taille : ' Then Begin TrEN:='Size: ';Exit;End;
 If S=', avec titre' Then Begin TrEN:=', with headline';Exit;End;
 If S='Vue : ' Then Begin TrEN:='View: ';Exit;End;
 If S='Police : ' Then Begin TrEN:='Font: ';Exit;End;
 If S='Curseur de texte : ' Then Begin TrEN:='Text cursor: ';Exit;End;
 If S='Objet s'#130'lectionn'#130' : ' Then Begin TrEN:='Selected object: ';
   Exit;End;
 If S='page ' Then Begin TrEN:='page ';Exit;End;
 If S='Aucun objet s'#130'lectionn'#130 Then Begin TrEN:='No object selected';
   Exit;End;
 If S='Informations' Then Begin TrEN:='Information';Exit;End;
 If S='Format : bitmap PBM ' Then Begin TrEN:='Format: PBM bitmap ';Exit;End;
 If S='Erreur d'''#130'criture du fichier.' Then Begin
   TrEN:='File write error.';Exit;End;
 If S='Titre du journal' Then Begin TrEN:='Newsletter headline';Exit;End;
 If S='Les changements non enregistr'#130's seront perdus. Continuer ?' Then
   Begin TrEN:='Unsaved changes will be lost. Continue?';Exit;End;
 If S='Ouvrir un journal' Then Begin TrEN:='Open a Newsletter';Exit;End;
 If S='Ouvrir' Then Begin TrEN:='Open';Exit;End;
 If S='Fichier introuvable : ' Then Begin TrEN:='File not found: ';Exit;End;
 If S='JOURNAL CHARG'#144 Then Begin TrEN:='NEWSLETTER LOADED';Exit;End;
 If S='Ce fichier n''est pas un journal NewsMaster valide.' Then Begin
   TrEN:='This file is not a valid NewsMaster newsletter.';Exit;End;
 If S='Enregistrer le journal' Then Begin TrEN:='Save the Newsletter';Exit;End;
 If S='Enregistrer' Then Begin TrEN:='Save';Exit;End;
 If S='Le fichier ' Then Begin TrEN:='The file ';Exit;End;
 If S=' existe. Le remplacer ?' Then Begin TrEN:=' exists. Replace it?';Exit;
   End;
 If S='JOURNAL ENREGISTR'#144 Then Begin TrEN:='NEWSLETTER SAVED';Exit;End;
 If S='Importer du texte ASCII' Then Begin TrEN:='Import ASCII Text';Exit;End;
 If S='Importer' Then Begin TrEN:='Import';Exit;End;
 If S='Impossible de lire ' Then Begin TrEN:='Cannot read ';Exit;End;
 If S='Exporter le texte ASCII' Then Begin TrEN:='Export ASCII Text';Exit;End;
 If S='TEXTE EXPORT'#144 Then Begin TrEN:='TEXT EXPORTED';Exit;End;
 If S='Exporter' Then Begin TrEN:='Export';Exit;End;
 If S='Quitter NewsMaster ? Les changements seront perdus.' Then Begin
   TrEN:='Quit NewsMaster? Changes will be lost.';Exit;End;
 If S='Quitter NewsMaster ?' Then Begin TrEN:='Quit NewsMaster?';Exit;End;
 If S=#133' la page' Then Begin TrEN:='Go to Page';Exit;End;
 If S='Num'#130'ro de page :' Then Begin TrEN:='Page number:';Exit;End;
 If S=#192' propos de NewsMaster' Then Begin TrEN:='About NewsMaster';Exit;End;
 If S='NewsMaster - Clone Pascal' Then Begin TrEN:='NewsMaster - Pascal clone';
   Exit;End;
 If S='Programme de publication de journaux' Then Begin
   TrEN:='Newsletter publishing program';Exit;End;
 If S='Inspir'#130' de News Master (Unison World, 1986)' Then Begin
   TrEN:='Inspired by News Master (Unison World, 1986)';Exit;End;
 If S='Pages : ' Then Begin TrEN:='Pages: ';Exit;End;
 If S='Texte principal : ' Then Begin TrEN:='Main text: ';Exit;End;
 If S=' caract'#138'res' Then Begin TrEN:=' characters';Exit;End;
 If S='Images et traits : ' Then Begin TrEN:='Artwork and lines: ';Exit;End;
 If S='Polices disponibles : ' Then Begin TrEN:='Available fonts: ';Exit;End;
 If S=' (int'#130'gr'#130'es)' Then Begin TrEN:=' (built-in)';Exit;End;
 If S='ATTENTION : du texte d'#130'passe la mise en page' Then Begin
   TrEN:='WARNING: text overflows the layout';Exit;End;
 If S='Statistiques' Then Begin TrEN:='Statistics';Exit;End;
 If S='M'#130'moire' Then Begin TrEN:='Memory';Exit;End;
 If S='M'#130'moire g'#130'r'#130'e par Free Pascal.' Then Begin
   TrEN:='Memory managed by Free Pascal.';Exit;End;
 If S='Plus grand bloc libre : ' Then Begin TrEN:='Largest free block: ';Exit;
   End;
 If S='M'#130'moire libre : ' Then Begin TrEN:='Free memory: ';Exit;End;
 If S='CRAZY JOE''S FISH SHACK' Then Begin TrEN:='CRAZY JOE''S FISH SHACK';Exit;
   End;
 If S='Attrapez nos portions de taille BALEINE '#133' prix de sardine !' Then
   Begin TrEN:='Catch our WHALE size portions at sardine prices!';Exit;End;
 If S='Sp'#130'cial du jour' Then Begin TrEN:='Today''s special';Exit;End;
 If S='Flet frit : 5,25 $. Notre cuisinier, un ancien marin au grand coeur, '
   Then Begin
   TrEN:='Fried flounder: $5.25. Our cook, a former sailor with a heart of '+
   'gold, ';Exit;End;
 If S='pr'#130'pare chaque matin le poisson le plus frais du port. ' Then Begin
   TrEN:='prepares the freshest fish from the harbor every morning. ';Exit;End;
 If S='Servi avec des frites maison, une salade croquante et la fameuse sauce '+
   'secr'#138'te de la maison.' Then Begin
   TrEN:='Served with homemade fries, a crisp salad and the famous secret '+
   'house sauce.';Exit;End;
 If S='Chaudr'#130'e de palourdes : 3,95 $. Une soupe onctueuse '#133' la '+
   'cr'#138'me, ' Then Begin
   TrEN:='Clam chowder: $3.95. A smooth, creamy soup, ';Exit;End;
 If S='garnie de palourdes, de pommes de terre et de lard fum'#130'. '+
   'Id'#130'ale ' Then Begin
   TrEN:='topped with clams, potatoes and smoked bacon. Perfect ';Exit;End;
 If S='pour r'#130'chauffer les journ'#130'es d''hiver sur le quai.' Then Begin
   TrEN:='for warming up winter days on the dock.';Exit;End;
 If S='Plateau de fruits de mer : 7,99 $. ' Then Begin
   TrEN:='Seafood platter: $7.99. ';Exit;End;
 If S='Crevettes, p'#130'tonles, calmars et moules, accompagn'#130's de '+
   'citron et de beurre fondu. ' Then Begin
   TrEN:='Shrimp, scallops, squid and mussels, served with lemon and melted '+
   'butter. ';Exit;End;
 If S='Le plateau est servi sur glace pour garder toute la fra'#139'cheur de '+
   'la mer. ' Then Begin
   TrEN:='The platter is served on ice to keep all the freshness of the sea. ';
   Exit;End;
 If S='Venez nombreux, la maison offre le caf'#130' !' Then Begin
   TrEN:='Come one, come all, coffee is on the house!';Exit;End;
 If S='Biblioth'#138'que : ' Then Begin TrEN:='Library: ';Exit;End;
 If S='Tab : biblioth'#138'que' Then Begin TrEN:='Tab: library';Exit;End;
 If S='&Biblio.' Then Begin TrEN:='&Library';Exit;End;
 If S='Le format NWS est limit'#130' '#133' 4 pages.' Then Begin
   TrEN:='The NWS format is limited to 4 pages.';Exit;End;
End;

Function TrDE(Const S: String): String;
Begin
 TrDE:='';
 If S='NEWSMASTER - CLONE VERSION ' Then Begin
   TrDE:='NEWSMASTER - KLON VERSION ';Exit;End;
 If S='PROGRAMME DE PUBLICATION DE JOURNAUX' Then Begin
   TrDE:='PROGRAMM ZUR ZEITUNGSGESTALTUNG';Exit;End;
 If S='D''APRES NEWS MASTER (UNISON WORLD, 1986)' Then Begin
   TrDE:='NACH NEWS MASTER (UNISON WORLD, 1986)';Exit;End;
 If S='APPUYEZ SUR ESPACE POUR CONTINUER' Then Begin
   TrDE:='LEERTASTE ZUM FORTFAHREN DR'#154'CKEN';Exit;End;
 If S='NewsMaster : Menu principal' Then Begin TrDE:='NewsMaster: Hauptmen'#129;
   Exit;End;
 If S='Choisissez une activit'#130' :' Then Begin
   TrDE:='W'#132'hlen Sie eine Aktivit'#132't:';Exit;End;
 If S='Commencer un nouveau journal' Then Begin TrDE:='Neue Zeitung beginnen';
   Exit;End;
 If S='Continuer le journal courant' Then Begin
   TrDE:='Aktuelle Zeitung weiterbearbeiten';Exit;End;
 If S='Choisir un journal enregistr'#130 Then Begin
   TrDE:='Gespeicherte Zeitung ausw'#132'hlen';Exit;End;
 If S='Quitter NewsMaster' Then Begin TrDE:='NewsMaster beenden';Exit;End;
 If S='ENTR'#144'E : POINT FINAL' Then Begin TrDE:='EINGABE: ENDPUNKT';Exit;End;
 If S='OBJET AJOUT'#144 Then Begin TrDE:='OBJEKT HINZUGEF'#154'GT';Exit;End;
 If S='Clone graphique du programme de publication de journaux News Master.'
   Then Begin TrDE:='Grafischer Klon des Zeitungsprogramms News Master.';Exit;
   End;
 If S='Utilisation : NEWS [fichier.NWS] [/?]' Then Begin
   TrDE:='Aufruf: NEWS [datei.NWS] [/?]';Exit;End;
 If S='fichier.NWS  Journal '#133' ouvrir.' Then Begin
   TrDE:='datei.NWS    Zu '#148'ffnende Zeitung.';Exit;End;
 If S='/?           Affiche cette aide.' Then Begin
   TrDE:='/?           Diese Hilfe anzeigen.';Exit;End;
 If S='Langue : fran'#135'ais par d'#130'faut. LANGUAGE=EN : anglais, '+
   'LANGUAGE=GR : allemand.' Then Begin
   TrDE:='Sprache: Franz'#148'sisch als Standard. LANGUAGE=EN: Englisch, '+
   'LANGUAGE=GR: Deutsch.';Exit;End;
 If S='Place NEWS.FLB dans le r'#130'pertoire courant pour utiliser les '+
   'polices originales.' Then Begin
   TrDE:='NEWS.FLB ins aktuelle Verzeichnis legen, um die Originalschriften '+
   'zu nutzen.';Exit;End;
 If S='Couverts' Then Begin TrDE:='Besteck';Exit;End;
 If S='Poisson' Then Begin TrDE:='Fisch';Exit;End;
 If S='Etoile' Then Begin TrDE:='Stern';Exit;End;
 If S='Soleil' Then Begin TrDE:='Sonne';Exit;End;
 If S='Maison' Then Begin TrDE:='Haus';Exit;End;
 If S='Arbre' Then Begin TrDE:='Baum';Exit;End;
 If S='Ciseaux' Then Begin TrDE:='Schere';Exit;End;
 If S='Ballon' Then Begin TrDE:='Ballon';Exit;End;
 If S='Telephone' Then Begin TrDE:='Telefon';Exit;End;
 If S='Coeur' Then Begin TrDE:='Herz';Exit;End;
 If S='Fleche' Then Begin TrDE:='Pfeil';Exit;End;
 If S='Journal' Then Begin TrDE:='Zeitung';Exit;End;
 If S='Tasse' Then Begin TrDE:='Tasse';Exit;End;
 If S='Livre' Then Begin TrDE:='Buch';Exit;End;
 If S='Gauche' Then Begin TrDE:='Links';Exit;End;
 If S='Droite' Then Begin TrDE:='Rechts';Exit;End;
 If S='Centr'#130 Then Begin TrDE:='Zentriert';Exit;End;
 If S='Justifi'#130 Then Begin TrDE:='Blocksatz';Exit;End;
 If S='Texte par-dessus' Then Begin TrDE:='Text '#129'ber Bild';Exit;End;
 If S='Texte des deux c'#147't'#130's' Then Begin
   TrDE:='Text auf beiden Seiten';Exit;End;
 If S='Texte '#133' gauche seul' Then Begin TrDE:='Text nur links';Exit;End;
 If S='Texte '#133' droite seul' Then Begin TrDE:='Text nur rechts';Exit;End;
 If S='Zone d'#130'gag'#130'e' Then Begin TrDE:='Freihalten';Exit;End;
 If S='Grand pas (16)' Then Begin TrDE:='Gro'#225'er Schritt (16)';Exit;End;
 If S='Pas moyen (4)' Then Begin TrDE:='Mittlerer Schritt (4)';Exit;End;
 If S='Un point (1)' Then Begin TrDE:='Ein Punkt (1)';Exit;End;
 If S='Ligne' Then Begin TrDE:='Linie';Exit;End;
 If S='Bo'#140'te' Then Begin TrDE:='Rahmen';Exit;End;
 If S='Horizontalement' Then Begin TrDE:='Horizontal';Exit;End;
 If S='Verticalement' Then Begin TrDE:='Vertikal';Exit;End;
 If S='&Oui' Then Begin TrDE:='&Ja';Exit;End;
 If S='&Non' Then Begin TrDE:='&Nein';Exit;End;
 If S='&Annuler' Then Begin TrDE:='&Abbruch';Exit;End;
 If S='Fichier' Then Begin TrDE:='Datei';Exit;End;
 If S='Edition' Then Begin TrDE:='Bearbeiten';Exit;End;
 If S='Texte' Then Begin TrDE:='Text';Exit;End;
 If S='Image' Then Begin TrDE:='Bild';Exit;End;
 If S='Page' Then Begin TrDE:='Seite';Exit;End;
 If S='Vue' Then Begin TrDE:='Ansicht';Exit;End;
 If S='Options' Then Begin TrDE:='Optionen';Exit;End;
 If S=#192' propos de NewsMaster...' Then Begin TrDE:=#154'ber NewsMaster...';
   Exit;End;
 If S='Statistiques...' Then Begin TrDE:='Statistik...';Exit;End;
 If S='M'#130'moire libre' Then Begin TrDE:='Freier Speicher';Exit;End;
 If S='Menu principal...' Then Begin TrDE:='Hauptmen'#129'...';Exit;End;
 If S='Nouveau|^N' Then Begin TrDE:='Neu|^N';Exit;End;
 If S='Ouvrir...|^O' Then Begin TrDE:=#153'ffnen...|^O';Exit;End;
 If S='Enregistrer|^S' Then Begin TrDE:='Speichern|^S';Exit;End;
 If S='Enregistrer sous...' Then Begin TrDE:='Speichern unter...';Exit;End;
 If S='Importer texte ASCII...' Then Begin TrDE:='ASCII-Text importieren...';
   Exit;End;
 If S='Exporter texte ASCII...' Then Begin TrDE:='ASCII-Text exportieren...';
   Exit;End;
 If S='Imprimer la page (PBM)...' Then Begin TrDE:='Seite drucken (PBM)...';
   Exit;End;
 If S='Imprimer tout (PBM)...' Then Begin TrDE:='Alles drucken (PBM)...';Exit;
   End;
 If S='Quitter|^Q' Then Begin TrDE:='Beenden|^Q';Exit;End;
 If S='Annuler|^Z' Then Begin TrDE:='R'#129'ckg'#132'ngig|^Z';Exit;End;
 If S='Couper|^X' Then Begin TrDE:='Ausschneiden|^X';Exit;End;
 If S='Copier|^C' Then Begin TrDE:='Kopieren|^C';Exit;End;
 If S='Coller|^V' Then Begin TrDE:='Einf'#129'gen|^V';Exit;End;
 If S='Effacer|Suppr' Then Begin TrDE:='L'#148'schen|Entf';Exit;End;
 If S='Tout s'#130'lectionner|^A' Then Begin TrDE:='Alles markieren|^A';Exit;
   End;
 If S='Chercher...|^F' Then Begin TrDE:='Suchen...|^F';Exit;End;
 If S='Chercher suivant|^G' Then Begin TrDE:='Weitersuchen|^G';Exit;End;
 If S='Choisir la police...|^T' Then Begin TrDE:='Schrift w'#132'hlen...|^T';
   Exit;End;
 If S='Police pr'#130'c'#130'dente' Then Begin TrDE:='Vorherige Schrift';Exit;
   End;
 If S='Police suivante' Then Begin TrDE:='N'#132'chste Schrift';Exit;End;
 If S='Aligner '#133' gauche|^L' Then Begin TrDE:='Linksb'#129'ndig|^L';Exit;
   End;
 If S='Aligner '#133' droite|^R' Then Begin TrDE:='Rechtsb'#129'ndig|^R';Exit;
   End;
 If S='Centrer|^E' Then Begin TrDE:='Zentrieren|^E';Exit;End;
 If S='Justifier|^J' Then Begin TrDE:='Blocksatz|^J';Exit;End;
 If S='Marquer la s'#130'lection' Then Begin TrDE:='Auswahl markieren';Exit;End;
 If S='Mode '#130'dition du texte|F2' Then Begin TrDE:='Textmodus|F2';Exit;End;
 If S='Mode '#130'dition d''images|F3' Then Begin TrDE:='Bildmodus|F3';Exit;End;
 If S='Choisir une image...|F1' Then Begin TrDE:='Bild w'#132'hlen...|F1';Exit;
   End;
 If S='Prendre|F2' Then Begin TrDE:='Aufnehmen|F2';Exit;End;
 If S='Prendre une copie|F3' Then Begin TrDE:='Kopie aufnehmen|F3';Exit;End;
 If S='Poser|Entr'#130'e' Then Begin TrDE:='Ablegen|Eingabe';Exit;End;
 If S='Supprimer|Suppr' Then Begin TrDE:='L'#148'schen|Entf';Exit;End;
 If S='Agrandir|+' Then Begin TrDE:='Vergr'#148#225'ern|+';Exit;End;
 If S='R'#130'duire|-' Then Begin TrDE:='Verkleinern|-';Exit;End;
 If S='Taille d''origine' Then Begin TrDE:='Originalgr'#148#225'e';Exit;End;
 If S='Retourner horizontal.' Then Begin TrDE:='Horizontal spiegeln';Exit;End;
 If S='Retourner vertical.' Then Begin TrDE:='Vertikal spiegeln';Exit;End;
 If S='Tracer une ligne' Then Begin TrDE:='Linie zeichnen';Exit;End;
 If S='Tracer une bo'#140'te' Then Begin TrDE:='Rahmen zeichnen';Exit;End;
 If S='Motif de remplissage...' Then Begin TrDE:='F'#129'llmuster...';Exit;End;
 If S=#144'paisseur du trait...' Then Begin TrDE:='Linienst'#132'rke...';Exit;
   End;
 If S='Mode mise en page|F4' Then Begin TrDE:='Layoutmodus|F4';Exit;End;
 If S='Ajouter une colonne' Then Begin TrDE:='Spalte hinzuf'#129'gen';Exit;End;
 If S='Supprimer une colonne' Then Begin TrDE:='Spalte l'#148'schen';Exit;End;
 If S='Ajouter un titre' Then Begin TrDE:='Titel hinzuf'#129'gen';Exit;End;
 If S='Supprimer le titre' Then Begin TrDE:='Titel l'#148'schen';Exit;End;
 If S='Ajouter une page' Then Begin TrDE:='Seite hinzuf'#129'gen';Exit;End;
 If S='Supprimer la page' Then Begin TrDE:='Seite l'#148'schen';Exit;End;
 If S='Page pr'#130'c'#130'dente|PgHaut' Then Begin
   TrDE:='Vorherige Seite|BildAuf';Exit;End;
 If S='Page suivante|PgBas' Then Begin TrDE:='N'#132'chste Seite|BildAb';Exit;
   End;
 If S=#133' la page...' Then Begin TrDE:='Gehe zu Seite...';Exit;End;
 If S='Zoom avant (x2)' Then Begin TrDE:='Vergr'#148#225'ern (x2)';Exit;End;
 If S='Vue normale' Then Begin TrDE:='Normalansicht';Exit;End;
 If S='Largeur de la page' Then Begin TrDE:='Seitenbreite';Exit;End;
 If S='Page enti'#138're' Then Begin TrDE:='Ganze Seite';Exit;End;
 If S='Pas du curseur : grand' Then Begin TrDE:='Cursorschritt: gro'#225;Exit;
   End;
 If S='Pas du curseur : moyen' Then Begin TrDE:='Cursorschritt: mittel';Exit;
   End;
 If S='Pas du curseur : point' Then Begin TrDE:='Cursorschritt: Punkt';Exit;End;
 If S='Polices de NEWS.FLB' Then Begin TrDE:='Schriften aus NEWS.FLB';Exit;End;
 If S='Guides de colonnes' Then Begin TrDE:='Spaltenf'#129'hrung';Exit;End;
 If S='Afficher les infos...' Then Begin TrDE:='Info...';Exit;End;
 If S='MENU D'''#144'DITION PRINCIPAL' Then Begin
   TrDE:='HAUPTMEN'#154' BEARBEITEN';Exit;End;
 If S='VUE' Then Begin TrDE:='ANSICHT';Exit;End;
 If S='TEXTE' Then Begin TrDE:='TEXT';Exit;End;
 If S='IMAGES' Then Begin TrDE:='BILDER';Exit;End;
 If S='PAGE' Then Begin TrDE:='SEITE';Exit;End;
 If S='FICHIER' Then Begin TrDE:='DATEI';Exit;End;
 If S='IMPRIM.' Then Begin TrDE:='DRUCK';Exit;End;
 If S='CHANGER LA VUE DU JOURNAL' Then Begin TrDE:='SEITENANSICHT '#142'NDERN';
   Exit;End;
 If S='ZOOM|AVANT' Then Begin TrDE:='ZOOM|GROSS';Exit;End;
 If S='VUE|NORMALE' Then Begin TrDE:='NORMAL|ANSICHT';Exit;End;
 If S='LARGEUR|DE PAGE' Then Begin TrDE:='SEITEN-|BREITE';Exit;End;
 If S='PAGE|ENTI'#138'RE' Then Begin TrDE:='GANZE|SEITE';Exit;End;
 If S='PAGE|PR'#144'C.' Then Begin TrDE:='SEITE|ZUR'#154'CK';Exit;End;
 If S='PAGE|SUIV.' Then Begin TrDE:='N'#142'CHSTE|SEITE';Exit;End;
 If S='MODIFIER LE TEXTE' Then Begin TrDE:='TEXT BEARBEITEN';Exit;End;
 If S='CHOISIR|POLICE' Then Begin TrDE:='SCHRIFT|W'#142'HLEN';Exit;End;
 If S='ALIGNE-|MENT' Then Begin TrDE:='AUS-|RICHTEN';Exit;End;
 If S='S'#144'LEC-|TION' Then Begin TrDE:='MARKIE-|REN';Exit;End;
 If S='COUPER' Then Begin TrDE:='AUSSCH.';Exit;End;
 If S='COPIER' Then Begin TrDE:='KOPIE';Exit;End;
 If S='COLLER' Then Begin TrDE:='EINF'#154'G.';Exit;End;
 If S='IMPORT|ASCII' Then Begin TrDE:='ASCII|IMPORT';Exit;End;
 If S='ANNULER' Then Begin TrDE:='R'#154'CKG.';Exit;End;
 If S='MODIFIER LES IMAGES' Then Begin TrDE:='BILDER BEARBEITEN';Exit;End;
 If S='CHOISIR|IMAGE' Then Begin TrDE:='BILD|W'#142'HLEN';Exit;End;
 If S='PRENDRE' Then Begin TrDE:='NEHMEN';Exit;End;
 If S='PRENDRE|COPIE' Then Begin TrDE:='KOPIE|NEHMEN';Exit;End;
 If S='POSER' Then Begin TrDE:='ABLEGEN';Exit;End;
 If S='TAILLE' Then Begin TrDE:='GR'#153'SSE';Exit;End;
 If S='ROGNER' Then Begin TrDE:='BESCHN.';Exit;End;
 If S='HABIL-|LAGE' Then Begin TrDE:='TEXT-|FLUSS';Exit;End;
 If S='RETOUR-|NER' Then Begin TrDE:='SPIEGEL';Exit;End;
 If S='LIGNE|BO'#139'TE' Then Begin TrDE:='LINIE|RAHMEN';Exit;End;
 If S='SUPPR.' Then Begin TrDE:='L'#153'SCHEN';Exit;End;
 If S='MODIFIER LA MISE EN PAGE' Then Begin TrDE:='SEITENLAYOUT '#142'NDERN';
   Exit;End;
 If S='AJOUT|COLONNE' Then Begin TrDE:='SPALTE|NEU';Exit;End;
 If S='SUPPR.|COLONNE' Then Begin TrDE:='SPALTE|L'#153'SCHEN';Exit;End;
 If S='AJOUT|TITRE' Then Begin TrDE:='TITEL|NEU';Exit;End;
 If S='SUPPR.|TITRE' Then Begin TrDE:='TITEL|L'#153'SCHEN';Exit;End;
 If S='AJOUT|PAGE' Then Begin TrDE:='SEITE|NEU';Exit;End;
 If S='SUPPR.|PAGE' Then Begin TrDE:='SEITE|L'#153'SCHEN';Exit;End;
 If S='CHARGER ET ENREGISTRER' Then Begin TrDE:='LADEN UND SPEICHERN';Exit;End;
 If S='NOUVEAU' Then Begin TrDE:='NEU';Exit;End;
 If S='OUVRIR' Then Begin TrDE:='LADEN';Exit;End;
 If S='ENREG.' Then Begin TrDE:='SPEICH.';Exit;End;
 If S='ENREG.|SOUS' Then Begin TrDE:='SPEICH.|UNTER';Exit;End;
 If S='MENU|PRINC.' Then Begin TrDE:='HAUPT-|MEN'#154;Exit;End;
 If S='QUITTER' Then Begin TrDE:='ENDE';Exit;End;
 If S='IMPRIMER LE JOURNAL' Then Begin TrDE:='ZEITUNG DRUCKEN';Exit;End;
 If S='CETTE|PAGE' Then Begin TrDE:='DIESE|SEITE';Exit;End;
 If S='TOUTES|PAGES' Then Begin TrDE:='ALLE|SEITEN';Exit;End;
 If S='EXPORT|TEXTE' Then Begin TrDE:='TEXT-|EXPORT';Exit;End;
 If S='ZOOM X2' Then Begin TrDE:='ZOOM X2';Exit;End;
 If S='NORMALE' Then Begin TrDE:='NORMAL';Exit;End;
 If S='LARGEUR' Then Begin TrDE:='BREITE';Exit;End;
 If S='PAGE ENTI'#138'RE' Then Begin TrDE:='GANZE SEITE';Exit;End;
 If S='PAS ' Then Begin TrDE:='SCHRITT ';Exit;End;
 If S='ROGNAGE' Then Begin TrDE:='BESCHNITT';Exit;End;
 If S='TRAC'#144 Then Begin TrDE:='ZEICHNEN';Exit;End;
 If S='SANS NOM' Then Begin TrDE:='OHNE NAME';Exit;End;
 If S='PAGE ' Then Begin TrDE:='SEITE ';Exit;End;
 If S='TEXTE EN TROP' Then Begin TrDE:='TEXT ZU LANG';Exit;End;
 If S='MISE EN PAGE - PAGE ' Then Begin TrDE:='SEITENLAYOUT - SEITE ';Exit;End;
 If S=' COLONNES' Then Begin TrDE:=' SPALTEN';Exit;End;
 If S=' COLONNE' Then Begin TrDE:=' SPALTE';Exit;End;
 If S=' + TITRE' Then Begin TrDE:=' + TITEL';Exit;End;
 If S='TEXTE TROP LONG' Then Begin TrDE:='TEXT ZU LANG';Exit;End;
 If S=' CARACT'#138'RES COPI'#144'S' Then Begin TrDE:=' ZEICHEN KOPIERT';Exit;
   End;
 If S='MARQUEZ AVEC LES FL'#138'CHES' Then Begin
   TrDE:='MIT PFEILTASTEN MARKIEREN';Exit;End;
 If S='S'#144'LECTION FIX'#144'E' Then Begin TrDE:='AUSWAHL FIXIERT';Exit;End;
 If S='Choisir une police' Then Begin TrDE:='Schrift w'#132'hlen';Exit;End;
 If S=' polices' Then Begin TrDE:=' Schriften';Exit;End;
 If S='int'#130'gr'#130'es' Then Begin TrDE:='eingebaut';Exit;End;
 If S='INTROUVABLE' Then Begin TrDE:='NICHT GEFUNDEN';Exit;End;
 If S='Chercher' Then Begin TrDE:='Suchen';Exit;End;
 If S='Texte '#133' chercher :' Then Begin TrDE:='Suchtext:';Exit;End;
 If S='TROP D''OBJETS' Then Begin TrDE:='ZU VIELE OBJEKTE';Exit;End;
 If S='RIEN A POSER' Then Begin TrDE:='NICHTS ZUM ABLEGEN';Exit;End;
 If S='AUCUNE IMAGE ICI' Then Begin TrDE:='KEIN BILD HIER';Exit;End;
 If S='Choisir une image' Then Begin TrDE:='Bild w'#132'hlen';Exit;End;
 If S='Fl'#138'ches : choisir  Entr'#130'e : valider' Then Begin
   TrDE:='Pfeile: w'#132'hlen  Eingabe: OK';Exit;End;
 If S='M'#138'ME PAGE SVP' Then Begin TrDE:='BITTE GLEICHE SEITE';Exit;End;
 If S='ENTR'#144'E : POINT DE D'#144'PART' Then Begin
   TrDE:='EINGABE: STARTPUNKT';Exit;End;
 If S='Motif de remplissage' Then Begin TrDE:='F'#129'llmuster';Exit;End;
 If S=#144'paisseur' Then Begin TrDE:='St'#132'rke';Exit;End;
 If S='Epaisseur du trait (1-30) :' Then Begin
   TrDE:='Linienst'#132'rke (1-30):';Exit;End;
 If S='MAXIMUM : ' Then Begin TrDE:='MAXIMAL: ';Exit;End;
 If S='UNE COLONNE MINIMUM' Then Begin TrDE:='MINDESTENS EINE SPALTE';Exit;End;
 If S='TITRE D'#144'J'#133' PR'#144'SENT' Then Begin
   TrDE:='TITEL SCHON VORHANDEN';Exit;End;
 If S='Titre' Then Begin TrDE:='Titel';Exit;End;
 If S=' PAGES' Then Begin TrDE:=' SEITEN';Exit;End;
 If S='IMPOSSIBLE : UNE PAGE' Then Begin TrDE:='UNM'#153'GLICH: NUR EINE SEITE';
   Exit;End;
 If S='TEXTE TRONQU'#144 Then Begin TrDE:='TEXT GEK'#154'RZT';Exit;End;
 If S='Fichier :' Then Begin TrDE:='Datei:';Exit;End;
 If S='(aucun fichier ' Then Begin TrDE:='(keine Datei ';Exit;End;
 If S='Impression de la page ' Then Begin TrDE:='Drucke Seite ';Exit;End;
 If S='Impression' Then Begin TrDE:='Drucken';Exit;End;
 If S='Page ' Then Begin TrDE:='Seite ';Exit;End;
 If S=' enregistr'#130'e dans ' Then Begin TrDE:=' gespeichert in ';Exit;End;
 If S='Pages enregistr'#130'es : ' Then Begin TrDE:='Gespeicherte Seiten: ';
   Exit;End;
  If S='Imprimer la page...' Then Begin TrDE:='Seite drucken...';Exit;End;
 If S='Imprimer tout...' Then Begin TrDE:='Alles drucken...';Exit;End;
 If S='Envoi '#133' l''imprimante ...' Then Begin
   TrDE:='Senden an den Drucker ...';Exit;End;
 If S='Imprim'#130' sur : ' Then Begin TrDE:='Gedruckt auf: ';Exit;End;
 If S='Page(s) : ' Then Begin TrDE:='Seite(n): ';Exit;End;
 If S='Erreur d''impression Windows.' Then Begin
   TrDE:='Windows-Druckfehler.';Exit;End;
 If S='(sans nom)' Then Begin TrDE:='(ohne Namen)';Exit;End;
 If S='Journal : ' Then Begin TrDE:='Zeitung: ';Exit;End;
 If S='Page courante : ' Then Begin TrDE:='Aktuelle Seite: ';Exit;End;
 If S='Colonnes : ' Then Begin TrDE:='Spalten: ';Exit;End;
 If S='Taille : ' Then Begin TrDE:='Gr'#148#225'e: ';Exit;End;
 If S=', avec titre' Then Begin TrDE:=', mit Titel';Exit;End;
 If S='Vue : ' Then Begin TrDE:='Ansicht: ';Exit;End;
 If S='Police : ' Then Begin TrDE:='Schrift: ';Exit;End;
 If S='Curseur de texte : ' Then Begin TrDE:='Textcursor: ';Exit;End;
 If S='Objet s'#130'lectionn'#130' : ' Then Begin
   TrDE:='Gew'#132'hltes Objekt: ';Exit;End;
 If S='page ' Then Begin TrDE:='Seite ';Exit;End;
 If S='Aucun objet s'#130'lectionn'#130 Then Begin
   TrDE:='Kein Objekt gew'#132'hlt';Exit;End;
 If S='Informations' Then Begin TrDE:='Informationen';Exit;End;
 If S='Format : bitmap PBM ' Then Begin TrDE:='Format: PBM-Bitmap ';Exit;End;
 If S='Erreur d'''#130'criture du fichier.' Then Begin
   TrDE:='Fehler beim Schreiben der Datei.';Exit;End;
 If S='Titre du journal' Then Begin TrDE:='Titel der Zeitung';Exit;End;
 If S='Les changements non enregistr'#130's seront perdus. Continuer ?' Then
   Begin TrDE:='Nicht gespeicherte '#142'nderungen gehen verloren. Fortfahren?';
   Exit;End;
 If S='Ouvrir un journal' Then Begin TrDE:='Zeitung '#148'ffnen';Exit;End;
 If S='Ouvrir' Then Begin TrDE:=#153'ffnen';Exit;End;
 If S='Fichier introuvable : ' Then Begin TrDE:='Datei nicht gefunden: ';Exit;
   End;
 If S='JOURNAL CHARG'#144 Then Begin TrDE:='ZEITUNG GELADEN';Exit;End;
 If S='Ce fichier n''est pas un journal NewsMaster valide.' Then Begin
   TrDE:='Diese Datei ist keine g'#129'ltige NewsMaster-Zeitung.';Exit;End;
 If S='Enregistrer le journal' Then Begin TrDE:='Zeitung speichern';Exit;End;
 If S='Enregistrer' Then Begin TrDE:='Speichern';Exit;End;
 If S='Le fichier ' Then Begin TrDE:='Die Datei ';Exit;End;
 If S=' existe. Le remplacer ?' Then Begin TrDE:=' existiert. Ersetzen?';Exit;
   End;
 If S='JOURNAL ENREGISTR'#144 Then Begin TrDE:='ZEITUNG GESPEICHERT';Exit;End;
 If S='Importer du texte ASCII' Then Begin TrDE:='ASCII-Text importieren';Exit;
   End;
 If S='Importer' Then Begin TrDE:='Importieren';Exit;End;
 If S='Impossible de lire ' Then Begin TrDE:='Kann nicht lesen: ';Exit;End;
 If S='Exporter le texte ASCII' Then Begin TrDE:='ASCII-Text exportieren';Exit;
   End;
 If S='TEXTE EXPORT'#144 Then Begin TrDE:='TEXT EXPORTIERT';Exit;End;
 If S='Exporter' Then Begin TrDE:='Exportieren';Exit;End;
 If S='Quitter NewsMaster ? Les changements seront perdus.' Then Begin
   TrDE:='NewsMaster beenden? '#142'nderungen gehen verloren.';Exit;End;
 If S='Quitter NewsMaster ?' Then Begin TrDE:='NewsMaster beenden?';Exit;End;
 If S=#133' la page' Then Begin TrDE:='Gehe zu Seite';Exit;End;
 If S='Num'#130'ro de page :' Then Begin TrDE:='Seitennummer:';Exit;End;
 If S=#192' propos de NewsMaster' Then Begin TrDE:=#154'ber NewsMaster';Exit;
   End;
 If S='NewsMaster - Clone Pascal' Then Begin TrDE:='NewsMaster - Pascal-Klon';
   Exit;End;
 If S='Programme de publication de journaux' Then Begin
   TrDE:='Programm zur Zeitungsgestaltung';Exit;End;
 If S='Inspir'#130' de News Master (Unison World, 1986)' Then Begin
   TrDE:='Inspiriert von News Master (Unison World, 1986)';Exit;End;
 If S='Pages : ' Then Begin TrDE:='Seiten: ';Exit;End;
 If S='Texte principal : ' Then Begin TrDE:='Haupttext: ';Exit;End;
 If S=' caract'#138'res' Then Begin TrDE:=' Zeichen';Exit;End;
 If S='Images et traits : ' Then Begin TrDE:='Bilder und Linien: ';Exit;End;
 If S='Polices disponibles : ' Then Begin TrDE:='Verf'#129'gbare Schriften: ';
   Exit;End;
 If S=' (int'#130'gr'#130'es)' Then Begin TrDE:=' (eingebaut)';Exit;End;
 If S='ATTENTION : du texte d'#130'passe la mise en page' Then Begin
   TrDE:='ACHTUNG: Text passt nicht ins Layout';Exit;End;
 If S='Statistiques' Then Begin TrDE:='Statistik';Exit;End;
 If S='M'#130'moire' Then Begin TrDE:='Speicher';Exit;End;
 If S='M'#130'moire g'#130'r'#130'e par Free Pascal.' Then Begin
   TrDE:='Speicher wird von Free Pascal verwaltet.';Exit;End;
 If S='Plus grand bloc libre : ' Then Begin
   TrDE:='Gr'#148#225'ter freier Block: ';Exit;End;
 If S='M'#130'moire libre : ' Then Begin TrDE:='Freier Speicher: ';Exit;End;
 If S='CRAZY JOE''S FISH SHACK' Then Begin TrDE:='CRAZY JOE''S FISCHBUDE';Exit;
   End;
 If S='Attrapez nos portions de taille BALEINE '#133' prix de sardine !' Then
   Begin TrDE:='Schnappen Sie sich unsere WAL-Portionen zum Sardinenpreis!';
   Exit;End;
 If S='Sp'#130'cial du jour' Then Begin TrDE:='Tagesangebot';Exit;End;
 If S='Flet frit : 5,25 $. Notre cuisinier, un ancien marin au grand coeur, '
   Then Begin
   TrDE:='Gebratene Flunder: 5,25 $. Unser Koch, ein ehemaliger Seemann mit '+
   'gro'#225'em Herz, ';Exit;End;
 If S='pr'#130'pare chaque matin le poisson le plus frais du port. ' Then Begin
   TrDE:='bereitet jeden Morgen den frischesten Fisch des Hafens zu. ';Exit;End;
 If S='Servi avec des frites maison, une salade croquante et la fameuse sauce '+
   'secr'#138'te de la maison.' Then Begin
   TrDE:='Serviert mit hausgemachten Pommes, knackigem Salat und der '+
   'ber'#129'hmten geheimen Hausso'#225'e.';Exit;End;
 If S='Chaudr'#130'e de palourdes : 3,95 $. Une soupe onctueuse '#133' la '+
   'cr'#138'me, ' Then Begin
   TrDE:='Muschelsuppe: 3,95 $. Eine s'#132'mige Suppe mit Sahne, ';Exit;End;
 If S='garnie de palourdes, de pommes de terre et de lard fum'#130'. '+
   'Id'#130'ale ' Then Begin
   TrDE:='mit Muscheln, Kartoffeln und R'#132'ucherspeck. Ideal ';Exit;End;
 If S='pour r'#130'chauffer les journ'#130'es d''hiver sur le quai.' Then Begin
   TrDE:='um kalte Wintertage am Kai zu erw'#132'rmen.';Exit;End;
 If S='Plateau de fruits de mer : 7,99 $. ' Then Begin
   TrDE:='Meeresfr'#129'chteplatte: 7,99 $. ';Exit;End;
 If S='Crevettes, p'#130'tonles, calmars et moules, accompagn'#130's de '+
   'citron et de beurre fondu. ' Then Begin
   TrDE:='Garnelen, Jakobsmuscheln, Tintenfisch und Miesmuscheln mit Zitrone '+
   'und zerlassener Butter. ';Exit;End;
 If S='Le plateau est servi sur glace pour garder toute la fra'#139'cheur de '+
   'la mer. ' Then Begin
   TrDE:='Die Platte wird auf Eis serviert, damit die Frische des Meeres '+
   'erhalten bleibt. ';Exit;End;
 If S='Venez nombreux, la maison offre le caf'#130' !' Then Begin
   TrDE:='Kommen Sie zahlreich, der Kaffee geht aufs Haus!';Exit;End;
 If S='Biblioth'#138'que : ' Then Begin TrDE:='Bibliothek: ';Exit;End;
 If S='Tab : biblioth'#138'que' Then Begin TrDE:='Tab: Bibliothek';Exit;End;
 If S='&Biblio.' Then Begin TrDE:='&Bibl.';Exit;End;
 If S='Le format NWS est limit'#130' '#133' 4 pages.' Then Begin
   TrDE:='Das NWS-Format ist auf 4 Seiten begrenzt.';Exit;End;
End;

Function Tr(Const S: String): String;
Var R: String; P: Integer;
Begin
 Tr:=S;
 If Lang=0 Then Exit;
 If Lang=1 Then R:=TrEN(S) Else R:=TrDE(S);
 If R<>'' Then Begin Tr:=R;Exit;End;
 P:=Pos('|',S);
 If P>0 Then Tr:=Tr(Copy(S,1,P-1))+'|'+Tr(Copy(S,P+1,255));
End;

{ ====================================================================== }
{                              POLICES                                   }
{ ====================================================================== }
{ Deux sources de polices :                                              }
{  - NEWS.FLB (bibliotheque de polices originale de News Master), lue    }
{    directement si le fichier est present dans le repertoire courant ;  }
{  - polices integrees, produites a partir de la police 8x8 du BGI.      }

Function GBit(C,X,Y: Integer): Integer;
Begin
 If (X<0) Or (X>7) Or (Y<0) Or (Y>7) Then GBit:=0
 Else If (G8[C,Y] And ($80 Shr X))<>0 Then GBit:=1 Else GBit:=0;
End;

{ Lit la police 8x8 du BGI }
Procedure ReadBios8;
Var C,X,Y: Integer;
Begin
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 For C:=0 To 255 Do Begin
  SetFillStyle(SolidFill,PAPER);
  Bar(0,0,7,7);
  If C>=32 Then Begin
   SetColor(INK);
   OutTextXY(0,0,Chr(C));
  End;
  For Y:=0 To 7 Do Begin
   G8[C,Y]:=0;
   For X:=0 To 7 Do
    If GetPixel(X,Y)=INK Then G8[C,Y]:=G8[C,Y] Or ($80 Shr X);
  End;
 End;
 LastFill:=-1;
End;

{ Lissage EPX d'une police doublee (X,Y dans 0..15) }
Function EpxBit(C,X,Y: Integer): Integer;
Var SX,SY,P,A,B,Cc,D,Q: Integer;
Begin
 SX:=X Shr 1;SY:=Y Shr 1;
 P:=GBit(C,SX,SY);A:=GBit(C,SX,SY-1);B:=GBit(C,SX+1,SY);
 Cc:=GBit(C,SX-1,SY);D:=GBit(C,SX,SY+1);
 Q:=P;
 Case (X And 1)+2*(Y And 1) Of
  0: If (Cc=A) And (Cc<>D) And (A<>B) Then Q:=A;
  1: If (A=B) And (A<>Cc) And (B<>D) Then Q:=B;
  2: If (D=Cc) And (D<>B) And (Cc<>A) Then Q:=Cc;
  3: If (B=D) And (B<>A) And (D<>Cc) Then Q:=D;
 End;
 EpxBit:=Q;
End;

{ Bit de la police integree a l'echelle K }
Function SysBit(C,K,X,Y: Integer): Integer;
Begin
 If (X<0) Or (Y<0) Or (X>=8*K) Or (Y>=8*K) Then SysBit:=0
 Else If K=1 Then SysBit:=GBit(C,X,Y)
 Else If (K And 1)=0 Then SysBit:=EpxBit(C,X Div (K Div 2),Y Div (K Div 2))
 Else SysBit:=GBit(C,X Div K,Y Div K);
End;

{ Caractere de remplacement pour les polices ne contenant que l'ASCII }
Function FoldCh(C: Byte): Byte;
Begin
 Case C Of
  128: FoldCh:=67;
  129,150,151,163: FoldCh:=117;
  130,136,137,138: FoldCh:=101;
  131,132,133,134,160: FoldCh:=97;
  135: FoldCh:=99;
  139,140,141,161: FoldCh:=105;
  142,143: FoldCh:=65;
  144: FoldCh:=69;
  147,148,149,162: FoldCh:=111;
  152: FoldCh:=121;
  153: FoldCh:=79;
  154: FoldCh:=85;
  164: FoldCh:=110;
  165: FoldCh:=78;
  225: FoldCh:=115;
 Else
  If C<128 Then FoldCh:=C Else FoldCh:=63;
 End;
End;

Procedure SysMetrics(C,K: Integer; Var L,R: Integer);
Var X,Y: Integer;
Begin
 L:=99;R:=-1;
 For Y:=0 To 7 Do
  For X:=0 To 7 Do
   If GBit(C,X,Y)=1 Then Begin
    If X<L Then L:=X;
    If X>R Then R:=X;
   End;
End;

{ Construit une police integree : echelle K, style 0 normal 1 gras 2 italique }
Procedure BuildSysFont(F: Integer);
Var K,Sty,C,X,Y,L,R,W,H,Bpr,T,Sh,ShRow,Pass,J,SX,Lo,Hi: Integer;
    Sz,O: LongInt; Buf: PBytes; Bit: Boolean;
Begin
 K:=FSys[F] Shr 2;Sty:=FSys[F] And 3;
 H:=8*K;
 T:=1;Sh:=0;
 If Sty=1 Then T:=1+(K+2) Div 3;
 If Sty=2 Then Sh:=(H-1) Div 4;
 If K>=4 Then Begin Lo:=32;Hi:=127;End Else Begin Lo:=32;Hi:=255;End;
 GetMem(FOff[F],SizeOf(TWords));
 GetMem(FAdv[F],256);
 For C:=0 To 255 Do Begin FOff[F]^[C]:=$FFFF;FAdv[F]^[C]:=0;End;
 Buf:=Nil;
 For Pass:=1 To 2 Do Begin
  Sz:=0;
  For C:=Lo To Hi Do Begin
   SysMetrics(C,K,L,R);
   If R<0 Then Begin
    If C=32 Then FAdv[F]^[C]:=3*K+FGap[F];
    Continue;
   End;
   W:=(R-L+1)*K+(T-1)+Sh;
   Bpr:=(W+7) Shr 3;
   If Pass=2 Then Begin
    O:=Sz;
    FOff[F]^[C]:=Word(O);
    FAdv[F]^[C]:=Byte(W+FGap[F]);
    Buf^[O]:=0;Buf^[O+1]:=W;Buf^[O+2]:=7*K;Buf^[O+3]:=H;
    FillChar(Buf^[O+4],H*Bpr,0);
    For Y:=0 To H-1 Do Begin
     If Sty=2 Then ShRow:=(H-1-Y) Div 4 Else ShRow:=0;
     For X:=0 To W-1 Do Begin
      Bit:=False;
      For J:=0 To T-1 Do Begin
       SX:=L*K+X-ShRow-J;
       If SysBit(C,K,SX,Y)=1 Then Bit:=True;
      End;
      If Bit Then Buf^[O+4+Y*Bpr+(X Shr 3)]:=Buf^[O+4+Y*Bpr+(X Shr 3)] Or ($80
        Shr (X And 7));
     End;
    End;
   End;
   Sz:=Sz+4+H*Bpr;
  End;
  If Pass=1 Then Begin
   GetMem(Buf,Sz);
   FLen[F]:=Sz;
  End;
 End;
 FBuf[F]:=Buf;
 { caracteres absents : repli sur le caractere ASCII de base }
 For C:=0 To 255 Do
  If FOff[F]^[C]=$FFFF Then
   If (C<>32) And (FoldCh(C)<>C) And (FOff[F]^[FoldCh(C)]<>$FFFF) Then Begin
    FOff[F]^[C]:=FOff[F]^[FoldCh(C)];
    FAdv[F]^[C]:=FAdv[F]^[FoldCh(C)];
   End;
 FAdv[F]^[13]:=0;
End;

Procedure AddSys(Const Nm: String; K,Sty: Integer);
Begin
 If NFont>=MAXFONT Then Exit;
 FName[NFont]:=Nm;FKind[NFont]:=1;FSys[NFont]:=K*4+Sty;
 FAsc[NFont]:=7*K;FDsc[NFont]:=K;FSpc[NFont]:=3*K+K;FGap[NFont]:=K;
 FBuf[NFont]:=Nil;FOff[NFont]:=Nil;FAdv[NFont]:=Nil;
 Inc(NFont);
End;

Procedure FreeFonts;
Var I: Integer;
Begin
 For I:=0 To MAXFONT-1 Do Begin
  If FBuf[I]<>Nil Then Begin FreeMem(FBuf[I],FLen[I]);FBuf[I]:=Nil;End;
  If FOff[I]<>Nil Then Begin FreeMem(FOff[I],SizeOf(TWords));FOff[I]:=Nil;End;
  If FAdv[I]<>Nil Then Begin FreeMem(FAdv[I],256);FAdv[I]:=Nil;End;
 End;
End;

Function Rd16(Var B; O: Integer): Integer;
Var P: PBytes;
Begin
 P:=@B;
 Rd16:=P^[O]+P^[O+1]*256;
End;

{ Cherche NEWS.FLB dans le repertoire courant, puis dans celui du programme }
Function FindFLB: Boolean;
Var D: String;
Begin
 FindFLB:=True;
 FLBFile:='NEWS.FLB';
 If FileExists(FLBFile) Then Exit;
 FLBFile:='news.flb';
 If FileExists(FLBFile) Then Exit;
 D:=ParamStr(0);
 While (Length(D)>0) And (D[Length(D)]<>'\') And (D[Length(D)]<>'/') Do
   Dec(D[0]);
 FLBFile:=D+'NEWS.FLB';
 If FileExists(FLBFile) Then Exit;
 FLBFile:=D+'news.flb';
 If FileExists(FLBFile) Then Exit;
 FindFLB:=False;
End;

{ Index des polices du fichier FLB (80 octets par police) }
Function LoadFLBIndex: Boolean;
Var Fh: File; Rec: Array[0..79] Of Byte; N,I,J: Integer; P0,Fs: LongInt;
    Pos: Array[0..MAXFONT] Of LongInt; Nm: String;
Begin
 LoadFLBIndex:=False;
 {$I-}
 Assign(Fh,FLBFile);Reset(Fh,1);
 {$I+}
 If IOResult<>0 Then Exit;
 Fs:=FileSize(Fh);
 BlockRead(Fh,Rec,80);
 P0:=LongInt(Rec[6])+LongInt(Rec[7])*256+LongInt(Rec[8])*65536;
 N:=P0 Div 80;
 If (N<1) Or (N>MAXFONT) Or (P0>Fs) Then Begin Close(Fh);Exit;End;
 Seek(Fh,0);
 NFont:=0;
 For I:=0 To N-1 Do Begin
  BlockRead(Fh,Rec,80);
  Nm:='';J:=10;
  While (J<60) And (Rec[J]<>0) Do Begin Nm:=Nm+Chr(Rec[J]);Inc(J);End;
  FName[I]:=Nm;
  Pos[I]:=LongInt(Rec[6])+LongInt(Rec[7])*256+LongInt(Rec[8])*65536;
  FPos[I]:=Pos[I]+Rd16(Rec,60);
  FAsc[I]:=Rd16(Rec,70);FDsc[I]:=Rd16(Rec,72);
  FSpc[I]:=Rd16(Rec,74)+Rd16(Rec,78);FGap[I]:=Rd16(Rec,78);
  FKind[I]:=0;FBuf[I]:=Nil;FOff[I]:=Nil;FAdv[I]:=Nil;
  Inc(NFont);
 End;
 Pos[N]:=Fs;
 For I:=0 To N-1 Do Begin
  FLen[I]:=Pos[I+1]-FPos[I];
  If FLen[I]>64000 Then FLen[I]:=64000;
  If FLen[I]<512 Then FLen[I]:=512;
 End;
 Close(Fh);
 LoadFLBIndex:=True;
End;

{ Largeur d'une espace dans NEWS.FLB (mesuree sur News Master : elle ne
  se deduit pas de l'en-tete des polices) ; 0 = en-tete }
Const
 FlbSpace : Array[0..33] Of Byte = (7,7,8,10,10,10,13,12,7,9,11,11,10,10,11,
   11,13,13,13,13,18,19,20,16,0,0,0,0,4,37,13,4,20,9);

Procedure LoadFLBFont(F: Integer);
Var Fh: File; C,J: Integer; Tb: Array[0..255] Of Byte; W: Word; Got: LongInt;
Begin
 GetMem(FOff[F],SizeOf(TWords));
 GetMem(FAdv[F],256);
 GetMem(FBuf[F],FLen[F]);
 FillChar(FBuf[F]^,FLen[F],0);
 For C:=0 To 255 Do Begin FOff[F]^[C]:=$FFFF;FAdv[F]^[C]:=0;End;
 {$I-}
 Assign(Fh,FLBFile);Reset(Fh,1);
 Seek(Fh,FPos[F]);
 BlockRead(Fh,FBuf[F]^,FLen[F],Got);
 Close(Fh);
 {$I+}
 If IOResult<>0 Then Exit;
 For C:=0 To 127 Do Begin
  W:=FBuf[F]^[C*2]+FBuf[F]^[C*2+1]*256;
  If (W<>$FFFF) And (LongInt(W)+260<FLen[F]) Then Begin
   FOff[F]^[C]:=W+256;
   FAdv[F]^[C]:=FBuf[F]^[W+256+1]+FGap[F];
  End;
 End;
 If FOff[F]^[32]=$FFFF Then Begin
  FAdv[F]^[32]:=FSpc[F];
  If (F<=33) And (NFont=34) Then
   If FlbSpace[F]>0 Then FAdv[F]^[32]:=FlbSpace[F];
 End;
 For C:=128 To 255 Do Begin
  J:=FoldCh(C);
  FOff[F]^[C]:=FOff[F]^[J];
  FAdv[F]^[C]:=FAdv[F]^[J];
 End;
 FAdv[F]^[225]:=FAdv[F]^[115]*2;
 FAdv[F]^[13]:=0;
End;

Procedure EnsureFont(F: Integer);
Begin
 If F>=NFont Then F:=0;
 If FOff[F]<>Nil Then Exit;
 If FKind[F]=0 Then LoadFLBFont(F) Else BuildSysFont(F);
End;

Function FontByName(Const Nm: String): Integer;
Var I: Integer;
Begin
 FontByName:=-1;
 For I:=0 To NFont-1 Do
  If FName[I]=Nm Then Begin FontByName:=I;Exit;End;
End;

{ Police la plus proche (hauteur) pour remplacer une police absente }
Function NearestFont(Const Nm: String; Ht: Integer): Integer;
Var I,B,D,BD: Integer;
Begin
 B:=FontByName(Nm);
 If B>=0 Then Begin NearestFont:=B;Exit;End;
 B:=0;BD:=9999;
 For I:=0 To NFont-1 Do Begin
  D:=Abs(FAsc[I]+FDsc[I]-Ht);
  If Copy(FName[I],1,6)='glyphs' Then D:=D+500;
  If D<BD Then Begin BD:=D;B:=I;End;
 End;
 NearestFont:=B;
End;

Function FontHt(F: Integer): Integer;
Begin
 FontHt:=FAsc[F]+FDsc[F];
End;

Procedure PickDefaults;
Begin
 If UseFLB Then Begin
  DefBody:=FontByName('Park 10');
  DefHead:=FontByName('News 24 bold');
 End Else Begin
  DefBody:=FontByName('Systeme 8');
  DefHead:=FontByName('Titre 32');
 End;
 If DefBody<0 Then DefBody:=0;
 If DefHead<0 Then DefHead:=0;
End;

{ Construit la table des polices (UseFLB : polices de NEWS.FLB) }
Procedure BuildFontTable;
Var Ok: Boolean;
Begin
 FreeFonts;
 NFont:=0;
 Ok:=False;
 If UseFLB And FLBFound Then Ok:=LoadFLBIndex;
 If Not Ok Then Begin
  UseFLB:=False;
  NFont:=0;
  AddSys('Systeme 8',1,0);
  AddSys('Systeme 8 gras',1,1);
  AddSys('Systeme 8 italique',1,2);
  AddSys('Systeme 16',2,0);
  AddSys('Systeme 16 gras',2,1);
  AddSys('Systeme 16 italique',2,2);
  AddSys('Systeme 24',3,0);
  AddSys('Systeme 24 gras',3,1);
  AddSys('Titre 32',4,1);
  AddSys('Titre 48',6,1);
 End;
 PickDefaults;
End;

{ Largeur d'un caractere (points a l'echelle 1:1) }
Function CharAdv(F,C: Byte): Integer;
Begin
 If C=13 Then Begin CharAdv:=0;Exit;End;
 If F>=NFont Then F:=0;
 EnsureFont(F);
 CharAdv:=FAdv[F]^[C];
End;

{ Trace un morceau horizontal (echelle K) }
Procedure PlotRun(X1,X2,Y,K: Integer);
Begin
 If K=1 Then Line(X1,Y,X2,Y) Else Bar(X1,Y,X2,Y+K-1);
End;

{ Type d'accent d'un caractere CP437 (les polices NEWS.FLB sont ASCII) }
Function AccentOf(C: Byte): Integer;
Begin
 Case C Of
  130,144,160,161,162,163: AccentOf:=1;
  133,138,141,149,151: AccentOf:=2;
  131,136,140,147,150,143: AccentOf:=3;
  132,137,139,148,129,142,153,154,152: AccentOf:=4;
  135,128: AccentOf:=5;
  164,165: AccentOf:=6;
 Else AccentOf:=0;
 End;
End;

Procedure DrawAccent(F,C,X,YB,K,W,YO: Integer);
Var U,CX,MY,S,A: Integer;
Begin
 A:=AccentOf(C);
 If A=0 Then Exit;
 U:=(FAsc[F]+FDsc[F]) Div 10+1;
 CX:=X+(W*K) Div 2;
 MY:=YB-YO*K-U*K;
 If (C>=65) And (C<=90) Then Begin End Else MY:=MY-K;
 If (FoldCh(C)>=65) And (FoldCh(C)<=90) Then MY:=YB-YO*K-U*K-K Div 2;
 Case A Of
  1: Line(CX-U*K,MY+U*K,CX+U*K,MY-U*K);
  2: Line(CX-U*K,MY-U*K,CX+U*K,MY+U*K);
  3: Begin Line(CX-U*K,MY+U*K,CX,MY-U*K);Line(CX,MY-U*K,CX+U*K,MY+U*K);End;
  4: Begin
    S:=K*((U+1) Div 2);
    Bar(CX-U*K-S,MY,CX-U*K-1,MY+S-1);Bar(CX+U*K,MY,CX+U*K+S-1,MY+S-1);
   End;
  5: Begin Line(CX,YB,CX,YB+U*K);Line(CX,YB+U*K,CX-K,YB+U*K);End;
  6: Begin
    Line(CX-U*K,MY+K,CX-U*K Div 2,MY);Line(CX-U*K Div 2,MY,CX+U*K Div 2,MY+K);
    Line(CX+U*K Div 2,MY+K,CX+U*K,MY);
   End;
 End;
End;

{ Trace un glyphe : X, YB = ligne de base (ecran), K = agrandissement }
Procedure DrawGlyph(F,C,X,YB,K: Integer);
Var O: LongInt; W,YO,H,Bpr,R,Bx,Run,Y: Integer; B: PBytes; Bit: Boolean;
Begin
 If F>=NFont Then F:=0;
 EnsureFont(F);
 O:=FOff[F]^[C];
 If (C=225) And (FKind[F]=0) Then Begin
  DrawGlyph(F,115,X,YB,K);
  DrawGlyph(F,115,X+FAdv[F]^[115]*K,YB,K);
  Exit;
 End;
 If O=$FFFF Then Exit;
 B:=FBuf[F];
 W:=B^[O+1];YO:=B^[O+2];H:=B^[O+3];
 If YO>127 Then YO:=YO-256;
 If (X>VW) Or (X+W*K<0) Then Exit;
 Bpr:=(W+7) Shr 3;
 For R:=0 To H-1 Do Begin
  Y:=YB-YO*K+R*K;
  If (Y+K<0) Or (Y>VH) Then Continue;
  Run:=-1;
  For Bx:=0 To W-1 Do Begin
   Bit:=(B^[O+4+R*Bpr+(Bx Shr 3)] And ($80 Shr (Bx And 7)))<>0;
   If Bit Then Begin
    If Run<0 Then Run:=Bx;
   End Else If Run>=0 Then Begin
    PlotRun(X+Run*K,X+Bx*K-1,Y,K);Run:=-1;
   End;
  End;
  If Run>=0 Then PlotRun(X+Run*K,X+W*K-1,Y,K);
 End;
 If (C>=128) And (FKind[F]=0) Then DrawAccent(F,C,X,YB,K,W,YO);
End;

{ Largeur d'une chaine dans une police }
Function StrWidthF(F: Integer; Const S: String): Integer;
Var I,W: Integer;
Begin
 W:=0;
 For I:=1 To Length(S) Do W:=W+CharAdv(F,Ord(S[I]));
 StrWidthF:=W;
End;

{ Ecrit une chaine dans une police de document (ecran, coordonnees ecran) }
Procedure DrawStrF(F,X,YTop: Integer; Const S: String);
Var I: Integer;
Begin
 EnsureFont(F);
 SetColor(INK);SetFill(INK);
 For I:=1 To Length(S) Do Begin
  DrawGlyph(F,Ord(S[I]),X,YTop+FAsc[F],1);
  X:=X+CharAdv(F,Ord(S[I]));
 End;
End;

{ ====================================================================== }
{                  BIBLIOTHEQUE D'IMAGES (ARTWORK)                       }
{ ====================================================================== }
{ Les images sont dessinees au demarrage avec les primitives du BGI puis  }
{ stockees en bitmaps monochromes.                                       }

Procedure PBegin;
Begin
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 SetFillStyle(SolidFill,PAPER);
 Bar(0,0,89,89);
 SetColor(INK);
 SetFillStyle(SolidFill,INK);
 SetLineStyle(SolidLn,0,1);
 LastFill:=-1;
End;

Procedure PEnd(Const Nm: String; W,H: Integer);
Var X,Y,Bpr: Integer;
Begin
 If NBLib>=MAXBLIB Then Exit;
 Inc(NBLib);
 Bpr:=(W+7) Shr 3;
 BLib[NBLib].Name:=Nm;BLib[NBLib].W:=W;BLib[NBLib].H:=H;
 GetMem(BLib[NBLib].B,Bpr*H);
 FillChar(BLib[NBLib].B^,Bpr*H,0);
 For Y:=0 To H-1 Do
  For X:=0 To W-1 Do
   If GetPixel(X,Y)=INK Then
    BLib[NBLib].B^[Y*Bpr+(X Shr 3)]:=BLib[NBLib].B^[Y*Bpr+(X Shr 3)] Or
      ($80 Shr (X And 7));
 SetLineStyle(SolidLn,0,1);
End;

Procedure Thick(T: Integer);
Begin
 If T>1 Then SetLineStyle(SolidLn,0,ThickWidth) Else SetLineStyle(SolidLn,0,
   NormWidth);
End;

Procedure MakeCouverts;
Var P: Array[1..6] Of PointType;
Begin
 PBegin;
 { fourchette }
 SetLineStyle(SolidLn,0,ThickWidth);
 Line(12,4,12,24);Line(20,4,20,24);Line(28,4,28,24);
 Line(12,24,28,24);
 Line(20,24,20,59);
 { couteau }
 P[1].X:=44;P[1].Y:=4;P[2].X:=54;P[2].Y:=10;P[3].X:=54;P[3].Y:=36;
 P[4].X:=44;P[4].Y:=36;
 SetLineStyle(SolidLn,0,NormWidth);
 FillPoly(4,P);
 SetLineStyle(SolidLn,0,ThickWidth);
 Line(49,36,49,59);
 PEnd('Couverts',64,64);
End;

Procedure MakePoisson;
Var P: Array[1..6] Of PointType; I: Integer;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 Ellipse(28,24,0,360,24,13);
 P[1].X:=50;P[1].Y:=24;P[2].X:=62;P[2].Y:=10;P[3].X:=62;P[3].Y:=38;
 FillPoly(3,P);
 Circle(14,20,3);
 FillEllipse(14,20,1,1);
 Arc(22,24,100,260,10);
 For I:=0 To 3 Do Line(30+I*5,14+I,30+I*5,34-I);
 PEnd('Poisson',64,48);
End;

Procedure MakeEtoile;
Var P: Array[1..10] Of PointType; I: Integer; A,R: Real;
Begin
 PBegin;
 For I:=0 To 9 Do Begin
  A:=-Pi/2+I*Pi/5;
  If Odd(I) Then R:=12 Else R:=29;
  P[I+1].X:=32+Round(R*Cos(A));
  P[I+1].Y:=33+Round(R*Sin(A));
 End;
 SetLineStyle(SolidLn,0,NormWidth);
 SetPat(PatGrey);
 FillPoly(10,P);
 SetColor(INK);
 DrawPoly(10,P);
 Line(P[10].X,P[10].Y,P[1].X,P[1].Y);
 PEnd('Etoile',64,64);
End;

Procedure MakeSoleil;
Var I: Integer; A: Real;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 SetFillStyle(SolidFill,INK);
 FillEllipse(32,32,11,11);
 SetLineStyle(SolidLn,0,ThickWidth);
 For I:=0 To 11 Do Begin
  A:=I*Pi/6;
  Line(32+Round(17*Cos(A)),32+Round(17*Sin(A)),
       32+Round(29*Cos(A)),32+Round(29*Sin(A)));
 End;
 PEnd('Soleil',64,64);
End;

Procedure MakeMaison;
Var P: Array[1..5] Of PointType;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 SetPat(PatHatch);
 P[1].X:=4;P[1].Y:=30;P[2].X:=32;P[2].Y:=6;P[3].X:=60;P[3].Y:=30;
 FillPoly(3,P);
 SetColor(INK);
 Line(4,30,32,6);Line(32,6,60,30);Line(4,30,60,30);
 Rectangle(10,30,54,60);
 Rectangle(26,40,38,60);
 Rectangle(14,36,22,46);Rectangle(42,36,50,46);
 Rectangle(44,10,50,22);
 PEnd('Maison',64,64);
End;

Procedure MakeArbre;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 SetFillStyle(SolidFill,INK);
 Bar(28,40,36,62);
 SetPat(PatDark);
 FillEllipse(32,22,20,17);
 FillEllipse(20,34,14,11);
 FillEllipse(44,34,14,11);
 SetColor(INK);
 Ellipse(32,22,0,360,20,17);
 PEnd('Arbre',64,64);
End;

Procedure MakeCiseaux;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 Ellipse(14,50,0,360,9,11);Ellipse(50,50,0,360,9,11);
 Ellipse(14,50,0,360,5,7);Ellipse(50,50,0,360,5,7);
 SetLineStyle(SolidLn,0,ThickWidth);
 Line(16,40,48,4);Line(48,40,16,4);
 PEnd('Ciseaux',64,64);
End;

Procedure MakeBallon;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 SetPat(PatHatch2);
 FillEllipse(32,22,22,20);
 SetColor(INK);
 Ellipse(32,22,0,360,22,20);
 Ellipse(32,22,0,360,10,20);
 Line(14,34,26,50);Line(50,34,38,50);Line(30,42,28,50);Line(34,42,36,50);
 SetFillStyle(SolidFill,INK);LastFill:=-1;
 Rectangle(24,50,40,60);
 Bar(24,50,40,53);
 PEnd('Ballon',64,64);
End;

Procedure MakeTelephone;
Var P: Array[1..8] Of PointType;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 SetFillStyle(SolidFill,INK);
 Bar(4,36,60,58);
 SetColor(PAPER);
 Rectangle(8,40,56,54);
 SetColor(INK);
 P[1].X:=6;P[1].Y:=36;P[2].X:=4;P[2].Y:=24;P[3].X:=16;P[3].Y:=14;
 P[4].X:=48;P[4].Y:=14;P[5].X:=60;P[5].Y:=24;P[6].X:=58;P[6].Y:=36;
 P[7].X:=48;P[7].Y:=30;P[8].X:=16;P[8].Y:=30;
 SetFillStyle(SolidFill,INK);LastFill:=-1;
 FillPoly(8,P);
 SetColor(PAPER);
 Line(20,45,44,45);Line(20,49,44,49);
 PEnd('Telephone',64,64);
End;

Procedure MakeCoeur;
Var P: Array[1..3] Of PointType;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 SetFillStyle(SolidFill,INK);
 FillEllipse(20,22,14,13);FillEllipse(44,22,14,13);
 P[1].X:=6;P[1].Y:=28;P[2].X:=58;P[2].Y:=28;P[3].X:=32;P[3].Y:=58;
 FillPoly(3,P);
 PEnd('Coeur',64,64);
End;

Procedure MakeFleche;
Var P: Array[1..7] Of PointType;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 P[1].X:=2;P[1].Y:=22;P[2].X:=36;P[2].Y:=22;P[3].X:=36;P[3].Y:=6;
 P[4].X:=62;P[4].Y:=32;P[5].X:=36;P[5].Y:=58;P[6].X:=36;P[6].Y:=42;
 P[7].X:=2;P[7].Y:=42;
 SetPat(PatGrey);
 FillPoly(7,P);
 SetColor(INK);
 DrawPoly(7,P);
 Line(P[7].X,P[7].Y,P[1].X,P[1].Y);
 PEnd('Fleche',64,64);
End;

Procedure MakeJournal;
Var I: Integer;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 Rectangle(4,4,60,60);
 SetFillStyle(SolidFill,INK);
 Bar(8,8,56,18);
 SetColor(PAPER);
 Line(12,13,52,13);
 SetColor(INK);
 Rectangle(8,22,26,40);
 Line(8,22,26,40);Line(26,22,8,40);
 For I:=0 To 3 Do Line(30,24+I*5,56,24+I*5);
 For I:=0 To 3 Do Line(8,44+I*4,56,44+I*4);
 PEnd('Journal',64,64);
End;

Procedure MakeTasse;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 Ellipse(26,24,0,360,20,5);
 Line(6,24,10,50);Line(46,24,42,50);
 Ellipse(26,50,180,360,16,5);
 Ellipse(26,50,0,180,16,5);
 SetLineStyle(SolidLn,0,ThickWidth);
 Arc(48,34,270,90,8);
 SetLineStyle(SolidLn,0,NormWidth);
 SetFillStyle(SolidFill,INK);
 Line(16,4,18,14);Line(26,2,24,14);Line(36,4,34,14);
 PEnd('Tasse',64,64);
End;

Procedure MakeLivre;
Var P: Array[1..4] Of PointType; I: Integer;
Begin
 PBegin;
 SetLineStyle(SolidLn,0,NormWidth);
 P[1].X:=4;P[1].Y:=14;P[2].X:=32;P[2].Y:=20;P[3].X:=32;P[3].Y:=58;P[4].X:=4;
   P[4].Y:=52;
 DrawPoly(4,P);Line(4,52,4,14);
 P[1].X:=60;P[1].Y:=14;P[2].X:=32;P[2].Y:=20;P[3].X:=32;P[3].Y:=58;P[4].X:=60;
   P[4].Y:=52;
 DrawPoly(4,P);Line(60,52,60,14);
 For I:=0 To 4 Do Begin
  Line(8,24+I*6,28,28+I*6);Line(56,24+I*6,36,28+I*6);
 End;
 PEnd('Livre',64,64);
End;

Procedure BuildLibrary;
Begin
 NLib:=0;NBLib:=0;
 MakeCouverts;MakePoisson;MakeEtoile;MakeSoleil;MakeMaison;MakeArbre;
 MakeCiseaux;MakeBallon;MakeTelephone;MakeCoeur;MakeFleche;MakeJournal;
 MakeTasse;MakeLivre;
End;

{ Bit (X,Y) d'une image }
Function PBitP(Var P: TPiece; X,Y: Integer): Boolean;
Var Bpr: Integer;
Begin
 PBitP:=False;
 If P.B=Nil Then Exit;
 If (X<0) Or (Y<0) Or (X>=P.W) Or (Y>=P.H) Then Exit;
 Bpr:=(P.W+7) Shr 3;
 PBitP:=(P.B^[Y*Bpr+(X Shr 3)] And ($80 Shr (X And 7)))<>0;
End;

{ Dessine la zone source (SX1,SY1,SX2,SY2) d'une image dans le rectangle
  ecran DX,DY,DW,DH (coordonnees relatives a la fenetre courante) }
Procedure DrawPieceP(Var P: TPiece; SX1,SY1,SX2,SY2: Integer; FlH,FlV: Boolean;
                     DX,DY,DW,DH: LongInt);
Var X,Y,X1,X2,Y1,Y2,Run: LongInt; SX,SY,SW,SHt: LongInt; Bit: Boolean;
Begin
 If (DW<=0) Or (DH<=0) Then Exit;
 SW:=SX2-SX1;SHt:=SY2-SY1;
 If (SW<=0) Or (SHt<=0) Then Exit;
 X1:=Max2(DX,0);X2:=Min2(DX+DW-1,VW-1);
 Y1:=Max2(DY,0);Y2:=Min2(DY+DH-1,VH-1);
 If (X1>X2) Or (Y1>Y2) Then Exit;
 SetColor(INK);
 For Y:=Y1 To Y2 Do Begin
  SY:=((Y-DY)*SHt) Div DH;
  If FlV Then SY:=SHt-1-SY;
  SY:=SY+SY1;
  Run:=-1;
  For X:=X1 To X2 Do Begin
   SX:=((X-DX)*SW) Div DW;
   If FlH Then SX:=SW-1-SX;
   SX:=SX+SX1;
   Bit:=PBitP(P,Integer(SX),Integer(SY));
   If Bit Then Begin
    If Run<0 Then Run:=X;
   End Else If Run>=0 Then Begin
    Line(Run,Y,X-1,Y);Run:=-1;
   End;
  End;
  If Run>=0 Then Line(Run,Y,X2,Y);
 End;
End;

{ Image du journal numero L (reserve pour les images de la page) }
Procedure DrawPiece(L,SX1,SY1,SX2,SY2: Integer; FlH,FlV: Boolean;
                    DX,DY,DW,DH: LongInt);
Begin
 If (L<1) Or (L>NLib) Then Exit;
 DrawPieceP(Lib[L],SX1,SY1,SX2,SY2,FlH,FlV,DX,DY,DW,DH);
End;

Procedure FreePiece(Var P: TPiece);
Begin
 If P.B<>Nil Then FreeMem(P.B,((P.W+7) Shr 3)*P.H);
 P.B:=Nil;P.W:=0;P.H:=0;
End;

Procedure FreePool;
Var I: Integer;
Begin
 For I:=1 To NLib Do FreePiece(Lib[I]);
 NLib:=0;
End;

{ Ajoute (ou retrouve) une image dans le journal ; retourne son numero }
Function PoolAdd(Var P: TPiece): Integer;
Var I,K,Sz: Integer; Same: Boolean;
Begin
 PoolAdd:=0;
 If (P.B=Nil) Or (P.W<1) Or (P.H<1) Then Exit;
 Sz:=((P.W+7) Shr 3)*P.H;
 For I:=1 To NLib Do
  If (Lib[I].W=P.W) And (Lib[I].H=P.H) And (Lib[I].Name=P.Name) Then Begin
   Same:=True;
   For K:=0 To Sz-1 Do If Lib[I].B^[K]<>P.B^[K] Then Same:=False;
   If Same Then Begin PoolAdd:=I;Exit;End;
  End;
 If NLib>=MAXLIB Then Exit;
 Inc(NLib);
 Lib[NLib].Name:=P.Name;Lib[NLib].W:=P.W;Lib[NLib].H:=P.H;
 GetMem(Lib[NLib].B,Sz);
 Move(P.B^,Lib[NLib].B^,Sz);
 PoolAdd:=NLib;
End;

{ ---- bibliotheques d'images d'origine (.SDR noms, .SDX index, .SHP) ---- }

Function LowerCase(C: Char): Char;
Begin
 If (C>='A') And (C<='Z') Then LowerCase:=Chr(Ord(C)+32) Else LowerCase:=C;
End;

Function ResolveFile(Const Base,Ext: String): String;
Var I: Integer; L: String;
Begin
 ResolveFile:='';
 If FileExists(Base+'.'+Ext) Then Begin ResolveFile:=Base+'.'+Ext;Exit;End;
 L:=Ext;
 For I:=1 To Length(L) Do L[I]:=LowerCase(L[I]);
 If FileExists(Base+'.'+L) Then Begin ResolveFile:=Base+'.'+L;Exit;End;
End;

Procedure AddSrc(Const Base: String);
Var T,D,X,S: String; I: Integer;
Begin
 If NSrc>=MAXSRC Then Exit;
 D:=ResolveFile(Base,'SDR');X:=ResolveFile(Base,'SDX');
   S:=ResolveFile(Base,'SHP');
 If (D='') Or (X='') Or (S='') Then Exit;
 T:=Upper(ShortName(Base));
 For I:=1 To NSrc Do If SrcTitle[I]=T Then Exit;
 Inc(NSrc);
 SrcBase[NSrc]:=Base;SrcFD[NSrc]:=D;SrcFX[NSrc]:=X;SrcFS[NSrc]:=S;
 SrcTitle[NSrc]:=Copy(T,1,12);
End;

{ Cherche les bibliotheques *.SDR du repertoire courant et du programme }
Procedure ScanLibs;
Var SR: SearchRec; Dir,Mk: String; Pass,K,I: Integer;
Begin
 NSrc:=0;
 SrcTitle[0]:='NEWSMASTER-0';
 Dir:=ParamStr(0);
 While (Length(Dir)>0) And (Dir[Length(Dir)]<>'') And (Dir[Length(Dir)]<>'/')
   Do Dec(Dir[0]);
 For Pass:=1 To 2 Do
  For K:=1 To 2 Do Begin
   If Pass=1 Then Mk:='' Else Mk:=Dir;
   If (Pass=2) And (Mk='') Then Continue;
   If K=1 Then FindFirst(Mk+'*.SDR',AnyFile,SR)
   Else FindFirst(Mk+'*.sdr',AnyFile,SR);
   While DosError=0 Do Begin
    AddSrc(Mk+Copy(SR.Name,1,Length(SR.Name)-4));
    FindNext(SR);
   End;
   {$IFDEF FPC}FindClose(SR);{$ENDIF}
  End;
 I:=0;
End;

{ Choisit la bibliotheque I (0 = images integrees) }
Procedure SrcSelect(I: Integer);
Var F: File; N,K,L: Integer; Buf: Array[0..15] Of Byte; Got: Word;
Begin
 SrcCur:=I;SrcN:=0;
 If I=0 Then Begin SrcN:=NBLib;Exit;End;
 {$I-}
 Assign(F,SrcFD[I]);Reset(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 N:=Integer(FileSize(F) Div 16);
 If N>MAXSH Then N:=MAXSH;
 For K:=1 To N Do Begin
  BlockRead(F,Buf,16,Got);
  SrcNm[K]:='';L:=0;
  While (L<15) And (Buf[L]<>0) Do Begin
   If Buf[L]>=32 Then SrcNm[K]:=SrcNm[K]+Chr(Buf[L]);
   Inc(L);
  End;
 End;
 Close(F);
 {$I-}
 Assign(F,SrcFX[I]);Reset(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 If FileSize(F) Div 4<N Then N:=Integer(FileSize(F) Div 4);
 For K:=1 To N Do BlockRead(F,SrcOff[K],4);
 Close(F);
 SrcN:=N;
End;

{ Charge l'image K de la bibliotheque courante }
Procedure SrcPiece(K: Integer; Var P: TPiece);
Var F: File; H: Array[0..4] Of Byte; Bpr,Hh: Integer; Got: Word;
Begin
 FreePiece(P);
 If (K<1) Or (K>SrcN) Then Exit;
 If SrcCur=0 Then Begin
  P.Name:=BLib[K].Name;P.W:=BLib[K].W;P.H:=BLib[K].H;
  GetMem(P.B,((P.W+7) Shr 3)*P.H);
  Move(BLib[K].B^,P.B^,((P.W+7) Shr 3)*P.H);
  Exit;
 End;
 {$I-}
 Assign(F,SrcFS[SrcCur]);Reset(F,1);
 Seek(F,SrcOff[K]);
 BlockRead(F,H,5,Got);
 {$I+}
 If (IOResult<>0) Or (Got<5) Then Begin {$I-}Close(F);{$I+}Exit;End;
 Bpr:=H[0];Hh:=H[1];
 If (Bpr<1) Or (Hh<1) Or (Bpr*Hh>12000) Then Begin Close(F);Exit;End;
 P.Name:=SrcNm[K];
 P.W:=H[2];
 If (P.W+7) Shr 3<>Bpr Then P.W:=Bpr*8;
 P.H:=Hh;
 GetMem(P.B,Bpr*Hh);
 {$I-}BlockRead(F,P.B^,Bpr*Hh,Got);{$I+}
 If IOResult<>0 Then FillChar(P.B^,Bpr*Hh,0);
 Close(F);
End;

{ Motif de remplissage numero I (palette de 30 motifs de News Master) }
Procedure FillPat(I: Integer; X1,Y1,X2,Y2: Integer);
Begin
 If (I<0) Or (I>29) Then I:=14;
 SetPat(OPat[I]);
 Bar(X1,Y1,X2,Y2);
 LastFill:=-1;
End;

{ ====================================================================== }
{                      HISTOIRES (flux de texte)                         }
{ ====================================================================== }
{ Histoire 0 : texte principal ; 1..MAXPG : titre de chaque page.        }
{ Un CR est toujours present en fin de texte (position Len).             }

Procedure StInit(I,ACap,Fn,Al: Integer);
Begin
 St[I].Cap:=ACap;
 GetMem(St[I].T,ACap+2);GetMem(St[I].F,ACap+2);GetMem(St[I].A,ACap+2);
 FillChar(St[I].T^,ACap+2,0);FillChar(St[I].F^,ACap+2,0);FillChar(St[I].A^,
   ACap+2,0);
 St[I].Len:=0;
 St[I].T^[0]:=13;St[I].F^[0]:=Fn;St[I].A^[0]:=Al;
End;

Procedure StClear(I,Fn,Al: Integer);
Begin
 St[I].Len:=0;
 St[I].T^[0]:=13;St[I].F^[0]:=Fn;St[I].A^[0]:=Al;
End;

Function StIns(S,Ps: Integer; Ch,Fn,Al: Byte): Boolean;
Var N: Integer;
Begin
 StIns:=False;
 If St[S].Len>=St[S].Cap Then Exit;
 N:=St[S].Len-Ps+1;
 Move(St[S].T^[Ps],St[S].T^[Ps+1],N);
 Move(St[S].F^[Ps],St[S].F^[Ps+1],N);
 Move(St[S].A^[Ps],St[S].A^[Ps+1],N);
 St[S].T^[Ps]:=Ch;St[S].F^[Ps]:=Fn;St[S].A^[Ps]:=Al;
 Inc(St[S].Len);
 StIns:=True;
End;

Procedure StDel(S,P1,P2: Integer);
Var N: Integer;
Begin
 If P2>St[S].Len Then P2:=St[S].Len;
 If P1>=P2 Then Exit;
 N:=St[S].Len-P2+1;
 Move(St[S].T^[P2],St[S].T^[P1],N);
 Move(St[S].F^[P2],St[S].F^[P1],N);
 Move(St[S].A^[P2],St[S].A^[P1],N);
 Dec(St[S].Len,P2-P1);
End;

Function ParaEndPos(S,Ps: Integer): Integer;
Begin
 While (Ps<St[S].Len) And (St[S].T^[Ps]<>13) Do Inc(Ps);
 ParaEndPos:=Ps;
End;

Function ParaStartPos(S,Ps: Integer): Integer;
Begin
 While (Ps>0) And (St[S].T^[Ps-1]<>13) Do Dec(Ps);
 ParaStartPos:=Ps;
End;

Procedure StAppend(S: Integer; Const Tx: String; Fn: Byte);
Var I: Integer;
Begin
 For I:=1 To Length(Tx) Do
  If Tx[I]=#13 Then StIns(S,St[S].Len,13,Fn,St[S].A^[St[S].Len])
  Else StIns(S,St[S].Len,Ord(Tx[I]),Fn,0);
End;

Function SelRange(Var A,B: Integer): Boolean;
Begin
 SelRange:=False;
 If SelA<0 Then Exit;
 If SelA<Cur Then Begin A:=SelA;B:=Cur;End Else Begin A:=Cur;B:=SelA;End;
 SelRange:=A<B;
End;

{ ---- annulation (un niveau) ---- }
Procedure PushUndo;
Var N: Integer;
Begin
 If UndoT=Nil Then Exit;
 N:=St[ASt].Len+1;
 If N>St[0].Cap+2 Then Exit;
 Move(St[ASt].T^,UndoT^,N);Move(St[ASt].F^,UndoF^,N);Move(St[ASt].A^,UndoA^,N);
 UndoLen:=St[ASt].Len;UndoCur:=Cur;UndoSt:=ASt;UndoOK:=True;
 UKind:=1;UTag:=0;
End;

{ Annulation des actions sur les objets et la mise en page. Tag<>0 : les
  actions successives de meme nature (ex. agrandir) comptent pour une. }
Procedure PushUndoDoc(Tag: Integer);
Begin
 If (UKind=2) And UndoOK And (Tag<>0) And (Tag=UTag) Then Exit;
 UArts:=Arts;UNArt:=NArt;UNCol:=NCol;UHas:=HasHead;
 UKind:=2;UTag:=Tag;UndoOK:=True;
End;

Procedure Relayout; Forward;
Procedure UpdateSelArt; Forward;

Procedure DoUndo;
Var N: Integer;
Begin
 If Not UndoOK Then Exit;
 If UKind=2 Then Begin
  Arts:=UArts;NArt:=UNArt;NCol:=UNCol;HasHead:=UHas;
  SelArt:=0;UndoOK:=False;UKind:=0;UTag:=0;
  Modified:=True;
  Relayout;
  If Mode=MD_ART Then UpdateSelArt;
  NeedDraw:=True;
  Exit;
 End;
 N:=UndoLen+1;
 Move(UndoT^,St[UndoSt].T^,N);Move(UndoF^,St[UndoSt].F^,N);Move(UndoA^,
   St[UndoSt].A^,N);
 St[UndoSt].Len:=UndoLen;
 ASt:=UndoSt;Cur:=UndoCur;SelA:=-1;
 UndoOK:=False;UKind:=0;
 Modified:=True;
 Relayout;
End;

{ ====================================================================== }
{                   MISE EN PAGE : REGIONS ET HABILLAGE                  }
{ ====================================================================== }

Const
 MAXIV  = 8;
 MAXLX  = 520;

Var
 IvA,IvB   : Array[1..MAXIV] Of Integer;
 NIv       : Integer;
 BandOn    : Boolean;
 BandR,BandY,BandH,BandNext,BandN : Integer;
 BandA,BandB : Array[1..MAXIV] Of Integer;
 LX        : Array[0..MAXLX] Of Integer;
 LXn       : Integer;

{ hauteur d'une ligne : hauteur de la police + 10 % (mesure sur l'original) }
Function Pitch(AD: Integer): Integer;
Begin
 { News 60 (60 points) mesure 67 sur l'original }
 If AD>=60 Then Pitch:=(AD*11+9) Div 10+1
 Else Pitch:=(AD*11+9) Div 10;
End;

Procedure BuildRegions;
Var P,C,N,CW,Y0: Integer;
Begin
 NReg:=0;
 For P:=1 To NPg Do Begin
  N:=NCol[P];
  CW:=(PGW-2*MRG-(N-1)*COLGAP) Div N;
  If HasHead[P] Then Y0:=HEADH+15 Else Y0:=MRG;
  For C:=0 To N-1 Do Begin
   Inc(NReg);
   RegPg[NReg]:=P;RegX[NReg]:=MRG+C*(CW+COLGAP);RegY[NReg]:=Y0;
   RegW[NReg]:=CW;RegH[NReg]:=PGH-Y0;
  End;
 End;
End;

Procedure SortIv;
Var I,J,T: Integer;
Begin
 For I:=1 To NIv-1 Do
  For J:=I+1 To NIv Do
   If IvA[J]<IvA[I] Then Begin
    T:=IvA[I];IvA[I]:=IvA[J];IvA[J]:=T;
    T:=IvB[I];IvB[I]:=IvB[J];IvB[J]:=T;
   End;
End;

Procedure CutIv(OL,OR_: Integer);
Var K,A,B: Integer; N0: Integer;
Begin
 N0:=NIv;
 For K:=1 To N0 Do Begin
  A:=IvA[K];B:=IvB[K];
  If (OR_<=A) Or (OL>=B) Then Continue;
  If (OL<=A) And (OR_>=B) Then Begin IvB[K]:=IvA[K];End
  Else If (OL>A) And (OR_<B) Then Begin
   IvB[K]:=OL;
   If NIv<MAXIV Then Begin Inc(NIv);IvA[NIv]:=OR_;IvB[NIv]:=B;End;
  End
  Else If OL<=A Then IvA[K]:=OR_
  Else IvB[K]:=OL;
 End;
End;

{ Intervalles libres d'une bande. Retourne False si l'on doit descendre
  (NewY = ordonnee de reprise) }
Function BandIntervals(PgN,X0,W,Y,H: Integer; Var NewY: Integer): Boolean;
Var I,K,N,MinW,OT,OB,OL,OR_,Bot: Integer; Blocked: Boolean;
Begin
 NIv:=1;IvA[1]:=X0;IvB[1]:=X0+W;
 Blocked:=False;Bot:=32000;BandIntervals:=True;
 For I:=1 To NArt Do
  If (Arts[I].Pg=PgN) And (Arts[I].Flow<>FL_OVER) Then Begin
   OT:=Arts[I].Y-PAD;OB:=Arts[I].Y+Arts[I].H+PAD;
   OL:=Arts[I].X-PAD;OR_:=Arts[I].X+Arts[I].W+PAD;
   If (Y<OB) And (Y+H>OT) And (OR_>X0) And (OL<X0+W) Then Begin
    If OB<Bot Then Bot:=OB;
    Case Arts[I].Flow Of
     FL_CLEAR: Begin NewY:=OB;BandIntervals:=False;Exit;End;
     FL_BOTH: CutIv(OL,OR_);
     FL_LEFT: For K:=1 To NIv Do If IvB[K]>OL Then IvB[K]:=OL;
     FL_RIGHT: For K:=1 To NIv Do If IvA[K]<OR_ Then IvA[K]:=OR_;
    End;
    Blocked:=True;
   End;
  End;
 MinW:=MINSLOT;
 If MinW>W Div 2 Then MinW:=W Div 2;
 N:=0;
 For K:=1 To NIv Do
  If IvB[K]-IvA[K]>=MinW Then Begin
   Inc(N);IvA[N]:=IvA[K];IvB[N]:=IvB[K];
  End;
 NIv:=N;
 SortIv;
 If (NIv=0) And Blocked Then Begin NewY:=Bot;BandIntervals:=False;End
 Else If NIv=0 Then Begin NIv:=1;IvA[1]:=X0;IvB[1]:=X0+W;End;
End;

{ Trouve une bande libre de hauteur H a partir de (R,Y) }
Function FindBand(Var R,Y: Integer; H: Integer): Boolean;
Var NewY,K,Guard: Integer;
Begin
 FindBand:=False;
 Guard:=0;
 While R<=NReg Do Begin
  Inc(Guard);
  If Guard>400 Then Begin R:=NReg+1;Exit;End;
  If (Y+H>RegY[R]+RegH[R]) And (Y>RegY[R]) Then Begin
   Inc(R);
   If R<=NReg Then Y:=RegY[R];
   Continue;
  End;
  NewY:=Y+4;
  If BandIntervals(RegPg[R],RegX[R],RegW[R],Y,H,NewY) Then Begin
   BandR:=R;BandY:=Y;BandH:=H;BandN:=NIv;BandNext:=2;BandOn:=True;
   For K:=1 To NIv Do Begin BandA[K]:=IvA[K];BandB[K]:=IvB[K];End;
   FindBand:=True;
   Exit;
  End;
  If NewY<=Y Then NewY:=Y+1;
  Y:=NewY;
 End;
End;

{ Remplit une ligne a partir de Ps dans une largeur W }
Var LastHang: Integer;

Procedure FillLine(S,Ps,W: Integer; Var E,Nx,Lw,Ns,Asc,Dsc: Integer; Var
  ParaEnd: Boolean);
Var I,X,Adv,LastSp,F,K: Integer; C: Byte;
Begin
 I:=Ps;X:=0;LastSp:=-1;ParaEnd:=False;
 E:=Ps;Nx:=Ps;
 While True Do Begin
  C:=St[S].T^[I];
  If C=13 Then Begin
   E:=I;Nx:=I+1;ParaEnd:=True;Break;
  End;
  Adv:=CharAdv(St[S].F^[I],C);
  { la coupure ne consomme qu'une espace : celle qui deborde, ou la premiere
    d'une suite d'espaces ; les suivantes commencent la ligne suivante }
  If (C=32) And ((I=Ps) Or (St[S].T^[I-1]<>32)) Then LastSp:=I;
  If (X+Adv>W) And (I>Ps) Then Begin
   If C=32 Then Begin E:=I;Nx:=I+1;End
   Else If LastSp>=Ps Then Begin E:=LastSp;Nx:=LastSp+1;End
   Else Begin E:=I;Nx:=I;End;
   Break;
  End;
  X:=X+Adv;
  Inc(I);
 End;
 { retire les espaces terminaux ; une coupure sur une espace suivie de la
   fin du paragraphe ne cree pas de ligne vide }
 While (E>Ps) And (St[S].T^[E-1]=32) Do Dec(E);
 { apres un point, la coupure absorbe toute la suite d'espaces }
 If (Not ParaEnd) And (E>Ps) And (St[S].T^[E-1]=46) Then
  While (Nx<St[S].Len) And (St[S].T^[Nx]=32) Do Inc(Nx);
 If (Not ParaEnd) And (Nx>Ps) And (Nx<=St[S].Len) Then
  If (St[S].T^[Nx-1]=32) And (St[S].T^[Nx]=13) Then Begin
   Inc(Nx);ParaEnd:=True;
  End;
 Lw:=0;Ns:=0;Asc:=0;Dsc:=0;
 For K:=Ps To E-1 Do Begin
  F:=St[S].F^[K];
  Lw:=Lw+CharAdv(F,St[S].T^[K]);
  If St[S].T^[K]=32 Then Inc(Ns);
  If FAsc[F]>Asc Then Asc:=FAsc[F];
  If FDsc[F]>Dsc Then Dsc:=FDsc[F];
 End;
 If E=Ps Then Begin
  F:=St[S].F^[Ps];
  Asc:=FAsc[F];Dsc:=FDsc[F];
 End;
 { les espaces terminales comptent pour le centrage et l'alignement a droite }
 LastHang:=0;
 For K:=E To Nx-1 Do
  If St[S].T^[K]=32 Then LastHang:=LastHang+CharAdv(St[S].F^[K],32);
End;

Procedure AddLine(S,PgN,Ps,E,Nx,X,Y,W,H,Asc,Lw,Ns: Integer; ParaEnd: Boolean);
Var PE: Integer;
Begin
 If NLn>=MAXLINE Then Exit;
 Lines^[NLn].S:=Ps;Lines^[NLn].E:=E;Lines^[NLn].Nx:=Nx;
 Lines^[NLn].X:=X;Lines^[NLn].Y:=Y;Lines^[NLn].W:=W;Lines^[NLn].H:=H;
 Lines^[NLn].Asc:=Asc;Lines^[NLn].Lw:=Lw;Lines^[NLn].Ns:=Ns;
 Lines^[NLn].Hg:=LastHang;
 Lines^[NLn].Sty:=S;Lines^[NLn].Pg:=PgN;
 PE:=ParaEndPos(S,Ps);
 Lines^[NLn].Al:=St[S].A^[PE];
 If ParaEnd Then Lines^[NLn].Fl:=1 Else Lines^[NLn].Fl:=0;
 Inc(NLn);
End;

Procedure LayoutHead(P: Integer);
Var Ps,R,Y,E,Nx,Lw,Ns,Asc,Dsc,Hd,H2,Tries,SX,SW,LY,LH,F0,First,I,Tot,
    SvReg: Integer;
    PEnd,Ok: Boolean;
Begin
 If NReg>=MAXREG Then Exit;
 { le titre est une region de la largeur de la page ; il s'ecoule dans les
   intervalles libres de chaque bande, comme le texte principal }
 SvReg:=NReg;Inc(NReg);
 RegPg[NReg]:=P;RegX[NReg]:=0;RegY[NReg]:=0;RegW[NReg]:=PGW;RegH[NReg]:=HEADH;
 R:=NReg;Y:=0;Ps:=0;First:=NLn;BandOn:=False;
 SX:=0;SW:=100;LY:=0;LH:=10;
 While (Ps<=St[P].Len) And (NLn<MAXLINE) Do Begin
  F0:=St[P].F^[Ps];
  If BandOn And (BandNext<=BandN) Then Begin
   SX:=BandA[BandNext];SW:=BandB[BandNext]-SX;LY:=BandY;LH:=BandH;
   Inc(BandNext);
   FillLine(P,Ps,SW,E,Nx,Lw,Ns,Asc,Dsc,PEnd);
  End Else Begin
   If BandOn Then Y:=BandY+BandH;
   BandOn:=False;
   Hd:=Pitch(FAsc[F0]+FDsc[F0]);
   Tries:=0;
   Repeat
    Ok:=FindBand(R,Y,Hd);
    If Not Ok Then Break;
    SX:=BandA[1];SW:=BandB[1]-SX;
    FillLine(P,Ps,SW,E,Nx,Lw,Ns,Asc,Dsc,PEnd);
    H2:=Pitch(Asc+Dsc);
    Inc(Tries);
    If (H2>Hd) And (Tries<4) Then Begin Hd:=H2;BandOn:=False;End
    Else Break;
   Until False;
   If Not Ok Then Break;
   LY:=BandY;LH:=Integer(Max2(BandH,Pitch(Asc+Dsc)));
  End;
  AddLine(P,P,Ps,E,Nx,SX,LY,SW,LH,Asc,Lw,Ns,PEnd);
  Ps:=Nx;
 End;
 BandOn:=False;
 NReg:=SvReg;
 Tot:=0;
 For I:=First To NLn-1 Do
  If Lines^[I].Y+Lines^[I].H>Tot Then Tot:=Lines^[I].Y+Lines^[I].H;
 If (Tot<HEADH) And (NLn>First) Then
  For I:=First To NLn-1 Do Lines^[I].Y:=Lines^[I].Y+(HEADH-Tot) Div 2;
End;

Procedure LayoutFlow;
Var Ps,R,Y,E,Nx,Lw,Ns,Asc,Dsc,Hd,H2,Tries,SX,SW,LY,LH,F0: Integer; PEnd,Ok:
  Boolean;
Begin
 Ps:=0;R:=1;Y:=RegY[1];BandOn:=False;Overflow:=False;
 SX:=0;SW:=100;LY:=0;LH:=10;
 While (Ps<=St[0].Len) And (NLn<MAXLINE) Do Begin
  F0:=St[0].F^[Ps];
  If BandOn And (BandNext<=BandN) Then Begin
   SX:=BandA[BandNext];SW:=BandB[BandNext]-SX;LY:=BandY;LH:=BandH;
   Inc(BandNext);
   FillLine(0,Ps,SW,E,Nx,Lw,Ns,Asc,Dsc,PEnd);
  End Else Begin
   If BandOn Then Y:=BandY+BandH;
   BandOn:=False;
   Hd:=Pitch(FAsc[F0]+FDsc[F0]);
   Tries:=0;
   Repeat
    Ok:=FindBand(R,Y,Hd);
    If Not Ok Then Break;
    SX:=BandA[1];SW:=BandB[1]-SX;
    FillLine(0,Ps,SW,E,Nx,Lw,Ns,Asc,Dsc,PEnd);
    H2:=Pitch(Asc+Dsc);
    Inc(Tries);
    If (H2>Hd) And (Tries<4) Then Begin Hd:=H2;BandOn:=False;End
    Else Break;
   Until False;
   If Not Ok Then Begin Overflow:=True;Break;End;
   { un paragraphe vide en haut d'une colonne est ignore }
   If (Ps>0) And (E=Ps) And PEnd And (BandY<=RegY[BandR]) Then Begin
    AddLine(0,RegPg[BandR],Ps,E,Nx,SX,BandY,SW,0,Asc,Lw,Ns,PEnd);
    Ps:=Nx;BandOn:=False;Continue;
   End;
   LY:=BandY;LH:=Integer(Max2(BandH,Pitch(Asc+Dsc)));
  End;
  AddLine(0,RegPg[BandR],Ps,E,Nx,SX,LY,SW,LH,Asc,Lw,Ns,PEnd);
  Ps:=Nx;
 End;
 If Ps<=St[0].Len Then Overflow:=True;
End;

Procedure LayoutAll;
Var P: Integer;
Begin
 NPg:=MAXPG;
 NLn:=0;
 BuildRegions;
 For P:=1 To NPg Do If HasHead[P] Then LayoutHead(P);
 LayoutFlow;
End;

Procedure Relayout;
Begin
 LayoutAll;
 NeedDraw:=True;
End;

{ ---- lignes et positions ---- }

Function LineOfPos(S,Ps: Integer): Integer;
Var I,B: Integer;
Begin
 B:=-1;
 For I:=0 To NLn-1 Do
  If Lines^[I].Sty=S Then
   If Lines^[I].S<=Ps Then B:=I;
 If B>=0 Then
  If (Ps>=Lines^[B].Nx) And (Lines^[B].Nx<=St[S].Len) Then B:=-1;
 LineOfPos:=B;
End;

{ Positions horizontales des caracteres de la ligne I (points de page) }
Procedure LineXs(I: Integer);
Var K,X0,Ex,Per,Rem_,SpI,Adv,N: Integer; S: Integer;
Begin
 S:=Lines^[I].Sty;
 N:=Lines^[I].E-Lines^[I].S;
 If N>MAXLX-1 Then N:=MAXLX-1;
 Ex:=0;Per:=0;Rem_:=0;
 Case Lines^[I].Al Of
  AL_RIGHT: X0:=Lines^[I].X+Lines^[I].W-Lines^[I].Lw-Lines^[I].Hg;
  AL_CENTER: Begin
   X0:=Lines^[I].X+(Lines^[I].W-Lines^[I].Lw-Lines^[I].Hg) Div 2;
   If X0<Lines^[I].X Then X0:=Lines^[I].X;
  End;
 Else
  X0:=Lines^[I].X;
 End;
 If (Lines^[I].Al=AL_BOTH) And (Lines^[I].Fl=0) And (Lines^[I].Ns>0) Then Begin
  Ex:=Lines^[I].W-Lines^[I].Lw;
  If Ex<0 Then Ex:=0;
  Per:=Ex Div Lines^[I].Ns;Rem_:=Ex Mod Lines^[I].Ns;
 End;
 SpI:=0;
 For K:=0 To N-1 Do Begin
  LX[K]:=X0;
  Adv:=CharAdv(St[S].F^[Lines^[I].S+K],St[S].T^[Lines^[I].S+K]);
  X0:=X0+Adv;
  If St[S].T^[Lines^[I].S+K]=32 Then Begin
   X0:=X0+Per;
   If SpI<Rem_ Then Inc(X0);
   Inc(SpI);
  End;
 End;
 LX[N]:=X0;
 LXn:=N;
End;

{ Position dans le texte pour l'abscisse Xp (points de page) sur la ligne I }
Function PosAtX(I,Xp: Integer): Integer;
Var K: Integer;
Begin
 LineXs(I);
 K:=0;
 While (K<LXn) And (Xp>=(LX[K]+LX[K+1]) Div 2) Do Inc(K);
 PosAtX:=Lines^[I].S+K;
End;

{ Abscisse (points de page) de la position Ps sur la ligne I }
Function XOfPos(I,Ps: Integer): Integer;
Var K: Integer;
Begin
 LineXs(I);
 K:=Ps-Lines^[I].S;
 If K<0 Then K:=0;
 If K>LXn Then K:=LXn;
 XOfPos:=LX[K];
End;

{ ====================================================================== }
{                  GEOMETRIE DE LA VUE (points <-> pixels)               }
{ ====================================================================== }

Var
 OrgX,OrgY0 : LongInt;           { origine de la page 1 dans la fenetre }
 CaretX,CaretY1,CaretY2 : Integer;
 CaretShown : Boolean;

Function Sc(V: LongInt): LongInt;
Begin
 Sc:=V*ZN Div ZD;
End;

Function Greek: Boolean;
Begin
 Greek:=ZD>1;
End;

Function StrideP: LongInt;
Begin
 StrideP:=Sc(PGH+PGGAP);
End;

Function DocWpx: LongInt;
Begin
 DocWpx:=Sc(PGW)+12;
End;

Function DocHpx: LongInt;
Begin
 DocHpx:=LongInt(NPg)*StrideP+12;
End;

Procedure ClampScroll;
Begin
 If ScrX>DocWpx-VW Then ScrX:=DocWpx-VW;
 If ScrX<0 Then ScrX:=0;
 If ScrY>DocHpx-VH Then ScrY:=DocHpx-VH;
 If ScrY<0 Then ScrY:=0;
End;

Procedure CalcOrg;
Begin
 ClampScroll;
 If DocWpx<VW Then OrgX:=(VW-Sc(PGW)) Div 2 Else OrgX:=6-ScrX;
 OrgY0:=6-ScrY;
End;

Function PgY0(P: Integer): LongInt;
Begin
 PgY0:=OrgY0+LongInt(P-1)*StrideP;
End;

{ Position document (page P, point lx,ly) -> ecran (relatif a la fenetre) }
Procedure PageToScr(P: Integer; LX_,LY_: LongInt; Var SX,SY: LongInt);
Begin
 SX:=OrgX+Sc(LX_);
 SY:=PgY0(P)+Sc(LY_);
End;

{ Ecran -> page et points de page (la page la plus proche) }
Function ScrToPage(X,Y: LongInt; Var P: Integer; Var LX_,LY_: LongInt): Boolean;
Var I: Integer;
Begin
 ScrToPage:=False;
 P:=1;
 For I:=1 To NPg Do
  If Y>=PgY0(I)-Sc(PGGAP) Div 2 Then P:=I;
 LX_:=(X-OrgX)*ZD Div ZN;
 LY_:=(Y-PgY0(P))*ZD Div ZN;
 ScrToPage:=(LX_>=0) And (LX_<PGW) And (LY_>=0) And (LY_<PGH);
End;

Function ArtOnPage(Pg,X,Y: Integer): Integer;
Var I: Integer;
Begin
 ArtOnPage:=0;
 For I:=NArt DownTo 1 Do
  If (Arts[I].Pg=Pg) And (X>=Arts[I].X-2) And (X<=Arts[I].X+Arts[I].W+2) And
     (Y>=Arts[I].Y-2) And (Y<=Arts[I].Y+Arts[I].H+2) Then Begin
   ArtOnPage:=I;Exit;
  End;
End;

{ ====================================================================== }
{                          DESSIN DES PAGES                              }
{ ====================================================================== }

Procedure DrawPageBase(X0,Y0: LongInt);
Var X1,Y1: LongInt;
Begin
 X1:=X0+Sc(PGW)-1;Y1:=Y0+Sc(PGH)-1;
 Box(X0+4,Y0+4,X1+4,Y1+4,INK);
 Box(X0-3,Y0-3,X1+3,Y1+3,PAPER);
 Frame(X0-3,Y0-3,X1+3,Y1+3);
 Frame(X0-1,Y0-1,X1+1,Y1+1);
End;

Procedure XorLine(X1,Y,X2: Integer);
Begin
 SetWriteMode(XORPut);
 SetColor(PAPER);
 SetLineStyle(SolidLn,0,1);
 Line(X1,Y,X2,Y);
 SetWriteMode(NormalPut);
End;

Procedure XorRect(X1,Y1,X2,Y2: Integer);
Var Y: Integer;
Begin
 If Y1<0 Then Y1:=0;
 If Y2>VH Then Y2:=VH;
 SetWriteMode(XORPut);
 SetColor(PAPER);
 SetLineStyle(SolidLn,0,1);
 For Y:=Y1 To Y2 Do Line(X1,Y,X2,Y);
 SetWriteMode(NormalPut);
End;

Procedure DotRect(X1,Y1,X2,Y2: Integer);
Begin
 SetColor(INK);
 SetLineStyle(UserBitLn,$AAAA,1);
 Rectangle(X1,Y1,X2,Y2);
 SetLineStyle(SolidLn,0,1);
End;

{ Ligne de texte "grisee" (vues reduites) }
Procedure DrawGreekLine(I: Integer; X0,Y0: LongInt);
Var XS,XE,YT,H,Fh: LongInt; F: Integer;
Begin
 If Lines^[I].E<=Lines^[I].S Then Exit;
 Case Lines^[I].Al Of
  AL_RIGHT: XS:=Lines^[I].X+Lines^[I].W-Lines^[I].Lw-Lines^[I].Hg;
  AL_CENTER: Begin
   XS:=Lines^[I].X+(Lines^[I].W-Lines^[I].Lw-Lines^[I].Hg) Div 2;
   If XS<Lines^[I].X Then XS:=Lines^[I].X;
  End;
 Else
  XS:=Lines^[I].X;
 End;
 XE:=XS+Lines^[I].Lw;
 If (Lines^[I].Al=AL_BOTH) And (Lines^[I].Fl=0) Then Begin XS:=Lines^[I].X;
   XE:=XS+Lines^[I].W;End;
 F:=St[Lines^[I].Sty].F^[Lines^[I].S];
 Fh:=FAsc[F]+FDsc[F];
 YT:=Y0+Sc(Lines^[I].Y+Lines^[I].Asc-FAsc[F]*7 Div 10);
 H:=Sc(Fh*7 Div 10);
 If H<1 Then H:=1;
 If H>=3 Then Begin
  If Fh>=20 Then PatBar(X0+Sc(XS),YT,X0+Sc(XE),YT+H-1,PatDark)
  Else PatBar(X0+Sc(XS),YT,X0+Sc(XE),YT+H-1,PatGrey);
 End Else Begin
  SetColor(INK);
  SetLineStyle(UserBitLn,$AAAA,1);
  Line(X0+Sc(XS),YT,X0+Sc(XE),YT);
  SetLineStyle(SolidLn,0,1);
 End;
End;

Procedure DrawTextLine(I: Integer; X0,Y0: LongInt);
Var K,J,S,Sa,Sb,A,B,X1,X2: Integer; YB,YT: LongInt; C: Byte;
Begin
 S:=Lines^[I].Sty;
 K:=ZN;
 LineXs(I);
 YB:=Y0+(Lines^[I].Y+Lines^[I].Asc)*K;
 YT:=Y0+Lines^[I].Y*K;
 SetColor(INK);SetFill(INK);
 For J:=Lines^[I].S To Lines^[I].E-1 Do Begin
  C:=St[S].T^[J];
  If C<>32 Then DrawGlyph(St[S].F^[J],C,X0+LX[J-Lines^[I].S]*K,YB,K);
 End;
 If (S=ASt) And SelRange(Sa,Sb) Then Begin
  A:=Sa;B:=Sb;
  If A<Lines^[I].S Then A:=Lines^[I].S;
  If B>Lines^[I].Nx Then B:=Lines^[I].Nx;
  If A<B Then Begin
   X1:=A-Lines^[I].S;
   If X1>LXn Then X1:=LXn;
   If B>Lines^[I].E Then Begin
    X2:=LXn;
    X1:=X1;
    XorRect(X0+LX[X1]*K,YT,X0+LX[X2]*K+K*3,YT+Lines^[I].H*K-1);
   End Else Begin
    X2:=B-Lines^[I].S;
    XorRect(X0+LX[X1]*K,YT,X0+LX[X2]*K-1,YT+Lines^[I].H*K-1);
   End;
  End;
 End;
End;

Procedure DrawLinesOfPage(P: Integer; X0,Y0: LongInt);
Var I: Integer; YT,YE: LongInt;
Begin
 For I:=0 To NLn-1 Do
  If Lines^[I].Pg=P Then Begin
   YT:=Y0+Sc(Lines^[I].Y);YE:=YT+Sc(Lines^[I].H+4);
   If (YE<0) Or (YT>VH) Then Continue;
   If Greek Then DrawGreekLine(I,X0,Y0) Else DrawTextLine(I,X0,Y0);
  End;
End;

{ Epaisseur en points ecran d'une ligne / d'une bordure (unites d'origine) }
Function LinePx(Th: Integer): LongInt;
Var T: LongInt;
Begin
 T:=Sc((Th+1) Div 2);
 If T<1 Then T:=1;
 LinePx:=T;
End;

Function BorderPx(Th: Integer): LongInt;
Var T: LongInt;
Begin
 T:=Sc((Th+2) Div 3);
 If T<1 Then T:=1;
 BorderPx:=T;
End;

Procedure DrawArtItem(I: Integer; X0,Y0: LongInt; Sel: Boolean);
Var SX,SY,SW,SH,T,H1,H2: LongInt; Pt: Array[1..4] Of PointType;
    X1,Y1,X2,Y2: LongInt;
Begin
 SX:=X0+Sc(Arts[I].X);SY:=Y0+Sc(Arts[I].Y);
 SW:=Sc(Arts[I].W);SH:=Sc(Arts[I].H);
 Case Arts[I].Kind Of
  AR_ART: Begin
    If SW<1 Then SW:=1;
    If SH<1 Then SH:=1;
    DrawPiece(Arts[I].Lib,Arts[I].SX1,Arts[I].SY1,Arts[I].SX2,Arts[I].SY2,
              Arts[I].FH<>0,Arts[I].FV<>0,SX,SY,SW,SH);
   End;
  AR_BOX: Begin
    T:=BorderPx(Arts[I].Th);
    If (SW<T) Or (SH<T) Then
     { boite degeneree : simple barre remplie du motif }
     FillPat(Arts[I].Pat,Integer(SX),Integer(SY),Integer(SX+Max2(SW,T)-1),
       Integer(SY+Max2(SH,T)-1))
    Else Begin
     FillPat(Arts[I].Pat,Integer(SX),Integer(SY),Integer(SX+SW),Integer(SY+SH));
     Box(Integer(SX),Integer(SY),Integer(SX+SW),Integer(SY+T-1),INK);
     Box(Integer(SX),Integer(SY+SH-T+1),Integer(SX+SW),Integer(SY+SH),INK);
     Box(Integer(SX),Integer(SY),Integer(SX+T-1),Integer(SY+SH),INK);
     Box(Integer(SX+SW-T+1),Integer(SY),Integer(SX+SW),Integer(SY+SH),INK);
    End;
   End;
  AR_LINE: Begin
    T:=LinePx(Arts[I].Th);
    X1:=SX;X2:=SX+SW;
    If Arts[I].FV=0 Then Begin Y1:=SY;Y2:=SY+SH;End
    Else Begin Y1:=SY+SH;Y2:=SY;End;
    H1:=T Div 2;H2:=T-H1;
    If SH=0 Then
     FillPat(Arts[I].Pat,Integer(X1),Integer(Y1-H1),Integer(X2),
       Integer(Y1+H2-1))
    Else If SW=0 Then
     FillPat(Arts[I].Pat,Integer(X1-H1),Integer(Y1),Integer(X1+H2-1),
       Integer(Y2))
    Else Begin
     If SW>=SH Then Begin
      Pt[1].X:=Integer(X1);Pt[1].Y:=Integer(Y1-H1);
      Pt[2].X:=Integer(X2);Pt[2].Y:=Integer(Y2-H1);
      Pt[3].X:=Integer(X2);Pt[3].Y:=Integer(Y2+H2);
      Pt[4].X:=Integer(X1);Pt[4].Y:=Integer(Y1+H2);
     End Else Begin
      Pt[1].X:=Integer(X1-H1);Pt[1].Y:=Integer(Y1);
      Pt[2].X:=Integer(X2-H1);Pt[2].Y:=Integer(Y2);
      Pt[3].X:=Integer(X2+H2);Pt[3].Y:=Integer(Y2);
      Pt[4].X:=Integer(X1+H2);Pt[4].Y:=Integer(Y1);
     End;
     SetPat(OPat[Arts[I].Pat Mod 30]);
     FillPoly(4,Pt);
     LastFill:=-1;
    End;
   End;
 End;
 If SW<1 Then SW:=1;
 If SH<1 Then SH:=1;
 If Sel Then DotRect(Integer(SX)-2,Integer(SY)-2,Integer(SX+SW)+1,
   Integer(SY+SH)+1);
End;

Procedure DrawColumnGuides(P: Integer; X0,Y0: LongInt);
Var R: Integer;
Begin
 For R:=1 To NReg Do
  If RegPg[R]=P Then
   DotRect(X0+Sc(RegX[R]),Y0+Sc(RegY[R]),X0+Sc(RegX[R]+RegW[R]),
     Y0+Sc(RegY[R]+RegH[R]));
 If HasHead[P] Then
  DotRect(X0,Y0,X0+Sc(PGW),Y0+Sc(HEADH));
End;

{ Page complete : fond, texte, images }
Procedure DrawPageFull(P: Integer; X0,Y0: LongInt; Guides: Boolean);
Var I: Integer;
Begin
 DrawPageBase(X0,Y0);
 If Guides Then DrawColumnGuides(P,X0,Y0);
 { lignes et boites sous le texte, images par-dessus }
 For I:=1 To NArt Do
  If (Arts[I].Pg=P) And (Arts[I].Kind<>AR_ART) Then
   DrawArtItem(I,X0,Y0,(I=SelArt) And (Mode=MD_ART));
 DrawLinesOfPage(P,X0,Y0);
 For I:=1 To NArt Do
  If (Arts[I].Pg=P) And (Arts[I].Kind=AR_ART) Then
   DrawArtItem(I,X0,Y0,(I=SelArt) And (Mode=MD_ART));
End;

{ ---- curseur de texte et d'images ---- }

Procedure CaretGeom(Var Ok: Boolean);
Var I,K: Integer; X0,Y0: LongInt;
Begin
 Ok:=False;
 If (Mode<>MD_TEXT) Or Greek Then Exit;
 I:=LineOfPos(ASt,Cur);
 If I<0 Then Exit;
 K:=ZN;
 X0:=OrgX;Y0:=PgY0(Lines^[I].Pg);
 CaretX:=Integer(X0+XOfPos(I,Cur)*K);
 CaretY1:=Integer(Y0+Lines^[I].Y*K);
 CaretY2:=CaretY1+Lines^[I].H*K-1;
 Ok:=(CaretY2>=0) And (CaretY1<=VH);
End;

Procedure ToggleCaret;
Var Ok: Boolean;
Begin
 CaretGeom(Ok);
 If Not Ok Then Exit;
 SetViewPort(0,MENU_H+1,SCR_W-1,PANEL_Y-1,True);
 SetWriteMode(XORPut);
 SetColor(PAPER);
 SetLineStyle(SolidLn,0,1);
 Line(CaretX,CaretY1,CaretX,CaretY2);
 Line(CaretX+1,CaretY1,CaretX+1,CaretY2);
 SetWriteMode(NormalPut);
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 CaretOn:=Not CaretOn;
End;

{ Convertit une position document (x,y absolus) en page + coordonnees }
Procedure DocToPage(DX,DY: LongInt; Var P: Integer; Var LX_,LY_: LongInt);
Begin
 P:=Integer(DY Div (PGH+PGGAP))+1;
 If P<1 Then P:=1;
 If P>NPg Then P:=NPg;
 LX_:=DX;
 LY_:=DY-LongInt(P-1)*(PGH+PGGAP);
End;

{ Coin C (0 haut-gauche, 1 haut-droit, 2 bas-gauche, 3 bas-droit) de
  l'objet A, en coordonnees de la fenetre d'affichage }
Procedure CornerPos(Const A: TArt; C: Integer; Var HX,HY: LongInt);
Var SX,SY: LongInt;
Begin
 PageToScr(A.Pg,A.X,A.Y,SX,SY);
 HX:=SX;HY:=SY;
 If (C And 1)<>0 Then HX:=SX+Sc(A.W);
 If (C And 2)<>0 Then HY:=SY+Sc(A.H);
End;

{ Poignee sous le pointeur (coordonnees fenetre d'affichage) ou -1 }
Function HandleHit(X,Y: LongInt): Integer;
Var C: Integer; HX,HY: LongInt;
Begin
 HandleHit:=-1;
 If (SelArt<1) Or (SelArt>NArt) Then Exit;
 For C:=0 To 3 Do Begin
  CornerPos(Arts[SelArt],C,HX,HY);
  If (Abs(X-HX)<=HSZ+1) And (Abs(Y-HY)<=HSZ+1) Then Begin
   HandleHit:=C;Exit;
  End;
 End;
End;

Procedure DrawHandles;
Var C: Integer; HX,HY: LongInt;
Begin
 If (SelArt<1) Or (SelArt>NArt) Or HeldOn Or (ArtSub>2) Then Exit;
 For C:=0 To 3 Do Begin
  CornerPos(Arts[SelArt],C,HX,HY);
  Box(Integer(HX)-HSZ,Integer(HY)-HSZ,Integer(HX)+HSZ,Integer(HY)+HSZ,INK);
  If ArtSub=2 Then
   Box(Integer(HX)-HSZ+2,Integer(HY)-HSZ+2,Integer(HX)+HSZ-2,Integer(HY)+HSZ-2,
     PAPER)
  Else
   Box(Integer(HX)-1,Integer(HY)-1,Integer(HX)+1,Integer(HY)+1,PAPER);
 End;
End;

Procedure DrawArtCursor;
Var P: Integer; LX_,LY_,SX,SY: LongInt; I: Integer; HW,HH: LongInt;
Begin
 DrawHandles;
 DocToPage(ACx,ACy,P,LX_,LY_);
 PageToScr(P,LX_,LY_,SX,SY);
 { piece tenue : apercu a la position du curseur }
 If HeldOn Then Begin
  HW:=Sc(Held.W);HH:=Sc(Held.H);
  If Held.Kind=AR_ART Then
   DrawPiece(Held.Lib,Held.SX1,Held.SY1,Held.SX2,Held.SY2,Held.FH<>0,Held.FV<>0,
     SX,SY,HW,HH);
  If Held.Kind=AR_BOX Then Begin
   SetColor(INK);Rectangle(SX,SY,SX+HW-1,SY+HH-1);
  End;
  If Held.Kind=AR_LINE Then Line(SX,SY,SX+HW-1,SY+HH-1);
  DotRect(SX-1,SY-1,SX+HW,SY+HH);
 End;
 SetWriteMode(XORPut);
 SetColor(PAPER);
 SetLineStyle(SolidLn,0,1);
 Line(Integer(SX)-9,Integer(SY),Integer(SX)+9,Integer(SY));
 Line(Integer(SX),Integer(SY)-9,Integer(SX),Integer(SY)+9);
 SetWriteMode(NormalPut);
 { trace en cours }
 If DrawStep=1 Then Begin
  DocToPage(DrawX0,DrawY0,P,LX_,LY_);
  PageToScr(P,LX_,LY_,SX,SY);
  DotRect(Integer(SX),Integer(SY),Integer(SX)+4,Integer(SY)+4);
 End;
End;

Procedure DrawViewArea;
Var P: Integer; Ok: Boolean;
Begin
 CalcOrg;
 SetViewPort(0,MENU_H+1,SCR_W-1,PANEL_Y-1,True);
 PatBar(0,0,VW-1,VH-1,PatStripe);
 For P:=1 To NPg Do
  If (PgY0(P)<=VH+4) And (PgY0(P)+Sc(PGH)>=-4) Then
   DrawPageFull(P,OrgX,PgY0(P),GuidesOn);
 If Mode=MD_ART Then DrawArtCursor;
 CaretOn:=False;
 CaretGeom(Ok);
 If Ok Then ToggleCaret;
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
End;

{ Fait defiler la fenetre pour voir la ligne I }
Procedure ScrollToLine(I: Integer);
Var Top,Bot,XS: LongInt;
Begin
 If I<0 Then Exit;
 Top:=6+LongInt(Lines^[I].Pg-1)*StrideP+Sc(Lines^[I].Y);
 Bot:=Top+Sc(Lines^[I].H);
 If Top<ScrY+4 Then ScrY:=Top-4
 Else If Bot>ScrY+VH-4 Then ScrY:=Bot-VH+4;
 If Not Greek Then Begin
  XS:=6+Sc(XOfPos(I,Cur));
  If XS<ScrX+20 Then ScrX:=XS-60
  Else If XS>ScrX+VW-20 Then ScrX:=XS-VW+60;
 End;
 ClampScroll;
End;

Procedure ScrollToDoc(DX,DY: LongInt);
Var P: Integer; LX_,LY_,SX,SY: LongInt;
Begin
 DocToPage(DX,DY,P,LX_,LY_);
 SX:=6+Sc(LX_);
 SY:=6+LongInt(P-1)*StrideP+Sc(LY_);
 If SY<ScrY+20 Then ScrY:=SY-40
 Else If SY>ScrY+VH-40 Then ScrY:=SY-VH+60;
 If SX<ScrX+20 Then ScrX:=SX-60
 Else If SX>ScrX+VW-40 Then ScrX:=SX-VW+80;
 ClampScroll;
End;

{ ====================================================================== }
{                  DIALOGUES (style GEM, repris de Papyrus)              }
{ ====================================================================== }

Procedure DrawAll; Forward;

Function ListCount(L: Integer): Integer;
Begin
 Case L Of
  1: ListCount:=4;
  2: ListCount:=5;
  3: ListCount:=3;
  4: ListCount:=2;
  5: ListCount:=2;
  Else ListCount:=0;
 End;
End;

Function ListItemFr(L,I: Integer): String;
Begin
 ListItemFr:='';
 Case L Of
  1: Case I Of
      1: ListItemFr:='Gauche';
      2: ListItemFr:='Droite';
      3: ListItemFr:='Centr'#130;
      4: ListItemFr:='Justifi'#130;
     End;
  2: Case I Of
      1: ListItemFr:='Texte par-dessus';
      2: ListItemFr:='Texte des deux c'#147't'#130's';
      3: ListItemFr:='Texte '#133' gauche seul';
      4: ListItemFr:='Texte '#133' droite seul';
      5: ListItemFr:='Zone d'#130'gag'#130'e';
     End;
  3: Case I Of
      1: ListItemFr:='Grand pas (16)';
      2: ListItemFr:='Pas moyen (4)';
      3: ListItemFr:='Un point (1)';
     End;
  4: Case I Of
      1: ListItemFr:='Ligne';
      2: ListItemFr:='Bo'#140'te';
     End;
  5: Case I Of
      1: ListItemFr:='Horizontalement';
      2: ListItemFr:='Verticalement';
     End;
 End;
End;

Function ListItem(L,I: Integer): String;
Begin
 ListItem:=Tr(ListItemFr(L,I));
End;

Function ListMain(I: Integer): String;
Begin
 Case I Of
  1: ListMain:='Commencer un nouveau journal';
  2: ListMain:='Continuer le journal courant';
  3: ListMain:='Choisir un journal enregistr'#130;
  4: ListMain:='Quitter NewsMaster';
 Else ListMain:='';
 End;
End;

{ Liste deroulante : retourne l'element choisi (1..n) ou 0 }
Function PopupAt(X,Y,W,L,Cur: Integer): Integer;
Var N,I,H,Hi,Res: Integer; E: TEvent; Done,Redraw,Armed: Boolean; Y1: Integer;
Begin
 Armed:=False;
 N:=ListCount(L);
 H:=N*16+4;
 If Y+H>SCR_H-2 Then Y:=SCR_H-2-H;
 If Y<MENU_H Then Y:=MENU_H;
 If X+W>SCR_W-2 Then X:=SCR_W-2-W;
 Hi:=Cur;Res:=0;Done:=False;Redraw:=True;
 Repeat
  If Redraw Then Begin
   HideMouse;
   Box(X+3,Y+3,X+W+3,Y+H+3,INK);
   Box(X,Y,X+W,Y+H,PAPER);
   Frame(X,Y,X+W,Y+H);
   For I:=1 To N Do Begin
    Y1:=Y+2+(I-1)*16;
    If I=Hi Then Begin
     Box(X+1,Y1,X+W-1,Y1+15,INK);
     WText(X+20,Y1+4,ListItem(L,I));
    End Else PText(X+20,Y1+4,ListItem(L,I));
    If I=Cur Then Begin
     If I=Hi Then WText(X+5,Y1+4,#251) Else PText(X+5,Y1+4,#251);
    End;
   End;
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  Case E.Kind Of
   4: Begin
       Armed:=True;
       If InBox(E.X,E.Y,X,Y+2,X+W,Y+H-2) Then I:=Integer((E.Y-Y-2) Div 16+1)
         Else I:=0;
       If I>N Then I:=N;
       If I<>Hi Then Begin Hi:=I;Redraw:=True;End;
      End;
   2: Begin
       If InBox(E.X,E.Y,X,Y+2,X+W,Y+H-2) Then Res:=Integer((E.Y-Y-2) Div 16+1);
       If Res>N Then Res:=N;
       Done:=True;
      End;
   3: If Armed And InBox(E.X,E.Y,X,Y+2,X+W,Y+H-2) And (Hi>0) Then Begin Res:=Hi;
     Done:=True;End;
   1: Case E.Key Of
       K_ESC: Done:=True;
       K_UP: Begin If Hi>1 Then Dec(Hi) Else Hi:=N;Redraw:=True;End;
       K_DOWN: Begin If (Hi<N) And (Hi>0) Then Inc(Hi) Else Hi:=1;Redraw:=True;
         End;
       K_ENTER: Begin Res:=Hi;Done:=True;End;
      End;
  End;
 Until Done;
 NeedDraw:=True;
 PopupAt:=Res;
End;

Procedure DlgInit(Id,W,H: Integer; Const Title: String);
Begin
 DlgId:=Id;NDC:=0;DlgW:=W;DlgH:=H;DlgTitle:=Title;
 DlgX:=(SCR_W-W) Div 2;DlgY:=(SCR_H-H) Div 2-8;
 DlgFocus:=0;DlgFresh:=True;
End;

Function AddCtl(Kind,Id,X,Y,W,H: Integer; Const Txt: String): Integer;
Begin
 If NDC<MAXCTL Then Inc(NDC);
 FillChar(DC[NDC],SizeOf(TCtl),0);
 DC[NDC].Kind:=Kind;DC[NDC].Id:=Id;DC[NDC].X:=X;DC[NDC].Y:=Y;
 DC[NDC].W:=W;DC[NDC].H:=H;DC[NDC].Txt:=Txt;DC[NDC].On:=True;
 AddCtl:=NDC;
End;

Procedure CLabel(X,Y: Integer; Const T0: String);
Var I: Integer; T: String;
Begin
 T:=Tr(T0);
 I:=AddCtl(C_LABEL,0,X,Y,TextW(T),10,T);
End;

Procedure CEdit(Id,X,Y,W: Integer; Const Init,Sfx: String; Numeric: Boolean);
Var I: Integer;
Begin
 I:=AddCtl(C_EDIT,Id,X,Y,W,16,'');
 DC[I].Str:=Init;DC[I].Sfx:=Sfx;DC[I].Num:=Numeric;
 If DlgFocus=0 Then DlgFocus:=I;
End;

Procedure CCheck(Id,X,Y: Integer; Const T0: String; On: Boolean);
Var I: Integer; T: String;
Begin
 T:=Tr(T0);
 I:=AddCtl(C_CHECK,Id,X,Y,TextW(T)+20,14,T);
 DC[I].Val:=Ord(On);
End;

Procedure CRadio(Id,Grp,Val,X,Y: Integer; Const T0: String; Sel: Boolean);
Var I: Integer; T: String;
Begin
 T:=Tr(T0);
 I:=AddCtl(C_RADIO,Id,X,Y,TextW(T)+20,14,T);
 DC[I].Grp:=Grp;DC[I].Val:=Val;DC[I].On:=Sel;
End;

Procedure CButton(Code,X,Y,W,H: Integer; Const T: String; Def,Enab: Boolean);
Var I: Integer;
Begin
 I:=AddCtl(C_BTN,Code,X,Y,W,H,T);
 DC[I].Num:=Def;DC[I].On:=Enab;
End;

Procedure CPopup(Id,X,Y,W,L,Cur: Integer);
Var I: Integer;
Begin
 I:=AddCtl(C_POP,Id,X,Y,W,18,'');
 DC[I].Grp:=L;DC[I].Val:=Cur;
End;

Procedure CGroup(X,Y,W,H: Integer; Const T: String);
Var I: Integer;
Begin
 I:=AddCtl(C_GROUP,0,X,Y,W,H,T);
End;

Function CtlIdx(Id: Integer): Integer;
Var I: Integer;
Begin
 CtlIdx:=0;
 For I:=1 To NDC Do If (DC[I].Id=Id) And (DC[I].Kind<>C_BTN) Then Begin
   CtlIdx:=I;Exit;End;
End;

Function CStr(Id: Integer): String;
Var I: Integer;
Begin
 I:=CtlIdx(Id);
 If I>0 Then CStr:=DC[I].Str Else CStr:='';
End;

Function CNum(Id: Integer; Def: LongInt): LongInt;
Begin
 CNum:=ValInt(CStr(Id),Def);
End;

Function CChk(Id: Integer): Boolean;
Var I: Integer;
Begin
 I:=CtlIdx(Id);
 CChk:=(I>0) And (DC[I].Val<>0);
End;

Function CVal(Id: Integer): Integer;
Var I: Integer;
Begin
 I:=CtlIdx(Id);
 If I>0 Then CVal:=DC[I].Val Else CVal:=0;
End;

Function CRad(G: Integer): Integer;
Var I: Integer;
Begin
 CRad:=0;
 For I:=1 To NDC Do
  If (DC[I].Kind=C_RADIO) And (DC[I].Grp=G) And DC[I].On Then CRad:=DC[I].Val;
End;

Procedure DlgFrame(X,Y,W,H: Integer; Const Title0: String);
Var Title: String;
Begin
 Title:=Tr(Title0);
 Box(X+4,Y+4,X+W+4,Y+H+4,INK);
 Box(X,Y,X+W,Y+H,PAPER);
 Frame(X,Y,X+W,Y+H);
 Frame(X+1,Y+1,X+W-1,Y+H-1);
 Frame(X+2,Y+2,X+W-2,Y+H-2);
 PatBar(X+3,Y+3,X+W-3,Y+TBH,PatStripe);
 SetColor(INK);
 Line(X+3,Y+TBH+1,X+W-3,Y+TBH+1);
 Box(X+3,Y+3,X+22,Y+TBH,PAPER);
 Frame(X+3,Y+3,X+22,Y+TBH);
 Frame(X+8,Y+8,X+17,Y+TBH-5);
 Box((X+W-TextW(Title)) Div 2-6,Y+5,(X+W+TextW(Title)) Div 2+6,Y+TBH-2,PAPER);
 BText((X+W-TextW(Title)) Div 2,Y+9,Title);
End;

Procedure DlgDraw;
Var I,X,Y,W,H,Cx,Cy: Integer; S: String;
Begin
 HideMouse;
 DlgFrame(DlgX,DlgY,DlgW,DlgH,DlgTitle);
 For I:=1 To NDC Do Begin
  X:=DlgX+DC[I].X;Y:=DlgY+DC[I].Y;W:=DC[I].W;H:=DC[I].H;
  Case DC[I].Kind Of
   C_LABEL: UText(X,Y,DC[I].Txt,INK);
   C_GROUP: Begin
     Frame(X,Y+4,X+W,Y+H);
     Box(X+8,Y,X+16+TextW(DC[I].Txt),Y+9,PAPER);
     UText(X+12,Y,DC[I].Txt,INK);
    End;
   C_EDIT: Begin
     Box(X,Y,X+W,Y+H,PAPER);
     Frame(X,Y,X+W,Y+H);
     S:=DC[I].Str;
     If (I=DlgFocus) And DlgFresh And (S<>'') Then Begin
      Box(X+2,Y+2,X+4+TextW(S),Y+H-2,INK);
      WText(X+3,Y+4,S);
     End Else Begin
      PText(X+3,Y+4,S);
      If I=DlgFocus Then Line(X+3+TextW(S),Y+3,X+3+TextW(S),Y+H-3);
     End;
     If DC[I].Sfx<>'' Then PText(X+W+8,Y+4,DC[I].Sfx);
    End;
   C_CHECK: Begin
     Box(X,Y,X+12,Y+12,PAPER);Frame(X,Y,X+12,Y+12);
     If DC[I].Val<>0 Then Begin
      Line(X+2,Y+2,X+10,Y+10);Line(X+10,Y+2,X+2,Y+10);
     End;
     UText(X+20,Y+3,DC[I].Txt,INK);
    End;
   C_RADIO: Begin
     Cx:=X+6;Cy:=Y+6;
     SetColor(INK);
     Circle(Cx,Cy,6);
     If DC[I].On Then Begin SetFill(INK);FillEllipse(Cx,Cy,3,3);End;
     UText(X+20,Y+3,DC[I].Txt,INK);
    End;
   C_BTN: Button(X,Y,X+W,Y+H,DC[I].Txt,DC[I].Num,DC[I].On);
   C_POP: Begin
     Box(X+3,Y+3,X+W+3,Y+H+3,INK);
     Box(X,Y,X+W,Y+H,PAPER);Frame(X,Y,X+W,Y+H);
     S:=ListItem(DC[I].Grp,DC[I].Val);
     UText((X+X+W-TextW(S)) Div 2,Y+5,S,INK);
    End;
  End;
 End;
 ShowMouse;
End;

Procedure DlgNextEdit(Dir: Integer);
Var I,K: Integer;
Begin
 If DlgFocus=0 Then Exit;
 I:=DlgFocus;
 For K:=1 To NDC Do Begin
  I:=I+Dir;
  If I>NDC Then I:=1;
  If I<1 Then I:=NDC;
  If DC[I].Kind=C_EDIT Then Begin DlgFocus:=I;DlgFresh:=True;Exit;End;
 End;
End;

{ Boucle de dialogue ; retourne le code du bouton ferme (1 OK, 2 annuler) }
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
{ OS/2-0 : BOITES DE DIALOGUE DE NEWS MASTER EN CONTROLES DE PM        }
{ ================================================================== }
{ La version DOS decrit ses boites (DlgInit, CLabel, CEdit, CCheck,    }
{ CRadio, CButton, CPopup, CGroup) puis les dessine et les mene par    }
{ RunDialog. Ici RunDialog en fait une vraie boite de dialogue de      }
{ Presentation Manager : etiquettes, champs de saisie, cases a cocher, }
{ boutons radio, boutons, listes deroulantes et cadres de groupe de    }
{ PM ; au bouton choisi, les valeurs sont recopiees dans DC.           }

Const
 WC_COMBOBOX = $FFFF0002; CBS_DROPDOWNLIST = 4;
 BS_AUTOCHECKBOX = 2; BS_AUTORADIOBUTTON = 4;
 SS_TEXT = 1; SS_GROUPBOX = 2; DT_VCENTER = $0400;
 BM_QUERYCHECK = $0124; BM_SETCHECK = $0125;
 BN_CLICKED = 1;
 ID_NCTL = 1000;

Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; External 'PMWIN';

Var
 NdH : Array[1..MAXCTL] Of LongInt;
 NdFr, NdCl, NdRes, NdEnd : LongInt;
 NdClsDone : Boolean;

Function NdText(H: LongInt): String;
Var Buf: Array[0..259] Of Byte; N, K: LongInt; S: String;
Begin
 N:=WinQueryWindowText(H,250,LongInt(@Buf));
 S:='';K:=0;
 While (K<N) And (Buf[K]<>0) Do Begin S:=S+Chr(Buf[K]);Inc(K);End;
 NdText:=S;
End;

Function NdLabel(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do If S[I]='&' Then S[I]:='~';
 NdLabel:=S;
End;

{ valeurs des controles de PM -> DC }
Procedure NdRead;
Var I, K: Integer; S, T: String;
Begin
 For I:=1 To NDC Do If NdH[I]<>0 Then
  Case DC[I].Kind Of
   C_EDIT : Begin
     S:=NdText(NdH[I]);
     If DC[I].Num Then Begin
      T:='';
      For K:=1 To Length(S) Do If S[K] In ['0'..'9','-'] Then T:=T+S[K];
      S:=T;
     End;
     DC[I].Str:=S;
    End;
   C_CHECK : DC[I].Val:=Ord(WinSendMsg(NdH[I],BM_QUERYCHECK,0,0)<>0);
   C_RADIO : DC[I].On:=WinSendMsg(NdH[I],BM_QUERYCHECK,0,0)<>0;
   C_POP : Begin
     K:=WinSendMsg(NdH[I],LM_QUERYSELECTION,-1,0);
     If K>=0 Then DC[I].Val:=K+1;
    End;
  End;
End;

Function WinQueryFocus(HD : LongInt) : LongInt; External 'PMWIN';

{ controle suivant (Dir = 1) ou precedent (-1) qui prend le clavier }
Procedure NdMove(Dir: Integer);
Var F, I, K, N: Integer;
Begin
 F:=WinQueryFocus(HWND_DESKTOP);
 K:=0;
 For I:=1 To NDC Do If NdH[I]=F Then K:=I;
 For N:=1 To NDC Do Begin
  K:=K+Dir;
  If K>NDC Then K:=1;
  If K<1 Then K:=NDC;
  If (NdH[K]<>0) And (DC[K].Kind In [C_EDIT,C_CHECK,C_RADIO,C_BTN,C_POP]) And
     ((DC[K].Kind<>C_BTN) Or DC[K].On) Then Begin
   Dummy:=WinSetFocus(HWND_DESKTOP,NdH[K]);
   Exit;
  End;
 End;
End;

Function NdProc(H, Msg, Mp1, Mp2: LongInt): LongInt;
Var I, L, Fl, Vk: LongInt; Hps: LongInt; Rc: Array[0..3] Of LongInt;
Begin
 NdProc:=0;
 Case Msg Of
  WM_PAINT : Begin
    Hps:=WinBeginPaint(H,0,LongInt(@Rc));
    Dummy:=WinQueryWindowRect(H,LongInt(@Rc));
    Dummy:=WinFillRect(Hps,LongInt(@Rc),CLR_PALEGRAY);
    Dummy:=WinEndPaint(Hps);
   End;
  WM_COMMAND : Begin
    I:=PmLo(Mp1)-ID_NCTL;
    If (I>=1) And (I<=NDC) And (DC[I].Kind=C_BTN) Then Begin
     NdRead;NdRes:=DC[I].Id;NdEnd:=1;
    End;
   End;
  WM_CONTROL : Begin
    I:=PmLo(Mp1)-ID_NCTL;
    If (I>=1) And (I<=NDC) And (DC[I].Kind=C_RADIO) And (PmHi(Mp1)=BN_CLICKED) Then
     { boutons radio du meme groupe }
     For L:=1 To NDC Do
      If (L<>I) And (DC[L].Kind=C_RADIO) And (DC[L].Grp=DC[I].Grp) And (NdH[L]<>0) Then
       Dummy:=WinSendMsg(NdH[L],BM_SETCHECK,0,0);
   End;
  WM_CHAR : Begin
    Fl:=PmLo(Mp1);Vk:=PmHi(Mp2);
    NdProc:=1;
    If ((Fl And KC_KEYUP)=0) And ((Fl And KC_VIRTUALKEY)<>0) Then Begin
     If Vk=VK_ESC Then Begin NdRes:=2;NdEnd:=1;Exit;End;
     If (Vk=VK_ENTER) Or (Vk=VK_NEWLINE) Then Begin NdRead;NdRes:=1;NdEnd:=1;Exit;End;
     If (Vk=VK_TAB) Or (Vk=VK_DOWN) Or (Vk=VK_RIGHT) Then Begin NdMove(1);Exit;End;
     If (Vk=VK_BACKTAB) Or (Vk=VK_UP) Or (Vk=VK_LEFT) Then Begin NdMove(-1);Exit;End;
    End;
    { premiere lettre (ou chiffre) d'un bouton : ce bouton }
    If ((Fl And KC_KEYUP)=0) And ((Fl And KC_CHAR)<>0) Then Begin
     Vk:=Ord(UpCase(Chr(PmLo(Mp2))));
     For L:=1 To NDC Do
      If (DC[L].Kind=C_BTN) And DC[L].On And (DC[L].Txt<>'') Then Begin
       I:=1;
       If (DC[L].Txt[1]='&') And (Length(DC[L].Txt)>1) Then I:=2;
       If Ord(UpCase(DC[L].Txt[I]))=Vk Then Begin
        NdRead;NdRes:=DC[L].Id;NdEnd:=1;Exit;
       End;
      End;
    End;
    NdProc:=WinDefWindowProc(H,Msg,Mp1,Mp2);
   End;
  WM_CLOSE : Begin NdRes:=2;NdEnd:=1;End;
 Else
  NdProc:=WinDefWindowProc(H,Msg,Mp1,Mp2);
 End;
End;

{ Boite de dialogue de PM ; retourne le code du bouton (1 OK, 2 annuler) }
Function RunDialog: Integer;
Var I, J, N, CH, X, Y, W, Ht, St, Cls, Clr, Foc, Prev: LongInt; Lb: String;
Begin
 If Not NdClsDone Then Begin
  NdClsDone:=True;
  Dummy:=WinRegisterClass(OsHab,OsZ('NEWSDLG'),LongInt(@NdProc),0,0);
 End;
 FlushScreen;
 If PmTopFr=0 Then PmTopFr:=OsFrame;
 Prev:=PmTopFr;
 MBtn:=0;MLatch:=0;
 Dummy:=WinSetCapture(HWND_DESKTOP,0);
 Dummy:=WinEnableWindow(Prev,0);
 CH:=DlgH-TBH;
 NdFr:=PmOpenBox('NEWSDLG',Tr(DlgTitle),DlgW,CH,NdCl);
 PmTopFr:=NdFr;
 Foc:=0;
 For I:=1 To NDC Do NdH[I]:=0;
 { cadres de groupe d'abord (sous les autres controles) }
 For I:=1 To NDC Do
  If DC[I].Kind=C_GROUP Then
   NdH[I]:=WinCreateWindow(NdCl,WC_STATIC,OsZ(NdLabel(DC[I].Txt)),WS_VISIBLE Or SS_GROUPBOX,
     DC[I].X,CH-(DC[I].Y-TBH+DC[I].H),DC[I].W,DC[I].H,NdCl,HWND_TOP,ID_NCTL+I,0,0);
 For I:=1 To NDC Do Begin
  X:=DC[I].X;Y:=DC[I].Y-TBH;W:=DC[I].W;Ht:=DC[I].H;
  Cls:=0;St:=WS_VISIBLE;Lb:=NdLabel(DC[I].Txt);
  Case DC[I].Kind Of
   C_LABEL : Begin
     Cls:=WC_STATIC;St:=St Or SS_TEXT Or DT_VCENTER;Y:=Y-4;Ht:=16;
     If W<Length(DC[I].Txt)*8 Then W:=Length(DC[I].Txt)*8;
    End;
   C_EDIT : Begin
     Cls:=WC_ENTRYFIELD;St:=St Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN;
     Y:=Y-2;Ht:=20;Lb:=DC[I].Str;
     If Foc=0 Then Foc:=I;
    End;
   C_CHECK : Begin Cls:=WC_BUTTON;St:=St Or WS_TABSTOP Or BS_AUTOCHECKBOX;Y:=Y-1;Ht:=16;End;
   C_RADIO : Begin Cls:=WC_BUTTON;St:=St Or WS_TABSTOP Or BS_AUTORADIOBUTTON;Y:=Y-1;Ht:=16;End;
   C_BTN : Begin
     Cls:=WC_BUTTON;St:=St Or WS_TABSTOP Or BS_PUSHBUTTON;
     If DC[I].Num Then St:=St Or BS_DEFAULT;
     If Ht<24 Then Begin Y:=Y-(24-Ht) Div 2;Ht:=24;End;
    End;
   C_POP : Begin Cls:=WC_COMBOBOX;St:=St Or WS_TABSTOP Or CBS_DROPDOWNLIST;Lb:='';Y:=Y-2;Ht:=22;End;
  End;
  If Cls<>0 Then Begin
   NdH[I]:=WinCreateWindow(NdCl,Cls,OsZ(Lb),St,X,CH-(Y+Ht),W,Ht,NdCl,HWND_TOP,ID_NCTL+I,0,0);
   Case DC[I].Kind Of
    C_LABEL, C_CHECK, C_RADIO : Begin
      Clr:=CLR_PALEGRAY;
      Dummy:=WinSetPresParam(NdH[I],4,4,LongInt(@Clr));
     End;
   End;
   Case DC[I].Kind Of
    C_EDIT : Begin
      Dummy:=WinSendMsg(NdH[I],EM_SETTEXTLIMIT,40,0);
      If DC[I].Sfx<>'' Then Begin
       J:=WinCreateWindow(NdCl,WC_STATIC,OsZ(DC[I].Sfx),WS_VISIBLE Or SS_TEXT Or DT_VCENTER,
         X+W+8,CH-(Y+Ht),Length(DC[I].Sfx)*8+8,Ht,NdCl,HWND_TOP,0,0,0);
       Clr:=CLR_PALEGRAY;
       Dummy:=WinSetPresParam(J,4,4,LongInt(@Clr));
      End;
     End;
    C_CHECK : Dummy:=WinSendMsg(NdH[I],BM_SETCHECK,Ord(DC[I].Val<>0),0);
    C_RADIO : Dummy:=WinSendMsg(NdH[I],BM_SETCHECK,Ord(DC[I].On),0);
    C_BTN : If Not DC[I].On Then Dummy:=WinEnableWindow(NdH[I],0);
    C_POP : Begin
      N:=ListCount(DC[I].Grp);
      For J:=1 To N Do Dummy:=WinSendMsg(NdH[I],LM_INSERTITEM,-1,OsZ(ListItem(DC[I].Grp,J)));
      If (DC[I].Val>=1) And (DC[I].Val<=N) Then Dummy:=WinSendMsg(NdH[I],LM_SELECTITEM,DC[I].Val-1,1);
     End;
   End;
  End;
 End;
 If Foc>0 Then Begin
  Dummy:=WinSetFocus(HWND_DESKTOP,NdH[Foc]);
  Dummy:=WinSendMsg(NdH[Foc],EM_SETSEL,Length(DC[Foc].Str) Shl 16,0);
 End Else Dummy:=WinSetFocus(HWND_DESKTOP,NdCl);
 NdRes:=2;NdEnd:=0;
 While NdEnd=0 Do Begin
  If WinGetMsg(OsHab,LongInt(@Qmsg),0,0,0)=0 Then Begin
   CmdPush(CMD_CLOSE);NdRes:=2;NdEnd:=1;
  End Else Dummy:=WinDispatchMsg(OsHab,LongInt(@Qmsg));
 End;
 PmTopFr:=Prev;
 Dummy:=WinEnableWindow(Prev,1);
 Dummy:=WinSetActiveWindow(HWND_DESKTOP,Prev);
 If Prev=OsFrame Then Dummy:=WinSetFocus(HWND_DESKTOP,OsClient);
 Dummy:=WinDestroyWindow(NdFr);
 NeedDraw:=True;
 RunDialog:=NdRes;
End;

Procedure MsgBox(Const Title0,Txt0: String);
{ boite de message de PM ; '|' separe les lignes }
Var T: String; I: Integer;
Begin
 T:=Tr(Txt0);
 For I:=1 To Length(T) Do If T[I]='|' Then T[I]:=#10;
 Dummy:=PmBox(Tr(Title0),T,MB_OK Or MB_INFORMATION);
 NeedDraw:=True;
End;

Function ConfirmBox(Const Txt0: String): Boolean;
Var T: String; I: Integer;
Begin
 T:=Tr(Txt0);
 For I:=1 To Length(T) Do If T[I]='|' Then T[I]:=#10;
 ConfirmBox:=PmBox('News Master',T,MB_YESNO Or MB_ICONQUESTION)=MBID_YES;
 NeedDraw:=True;
End;

Function InputBox(Const Title0,Prompt0: String; Var S: String; MaxLen: Integer):
  Boolean;
Var W: Integer; Title,Prompt: String;
Begin
 Title:=Tr(Title0);Prompt:=Tr(Prompt0);
 W:=TextW(Prompt)+MaxLen*8+60;
 If W<300 Then W:=300;
 If W>600 Then W:=600;
 DlgInit(97,W,TBH+80,Title);
 CLabel(16,TBH+14,Prompt);
 CEdit(1,16,TBH+30,W-32,S,'',False);
 CButton(1,16,TBH+54,80,20,'OK',True,True);
 CButton(2,W-96,TBH+54,80,20,'&Annuler',False,True);
 If RunDialog=1 Then Begin
  S:=CStr(1);InputBox:=True;
 End Else InputBox:=False;
End;

{ ====================================================================== }
{                              MENUS                                     }
{ ====================================================================== }

Const
 MTitle : Array[1..NMENU] Of String[8] = ('News','Fichier','Edition','Texte',
   'Image','Page','Vue','Options');

Procedure DoMenu(M,I: Integer); Forward;

Function MCount(M: Integer): Integer;
Begin
 Case M Of
  1: MCount:=4;
  2: MCount:=13;
  3: MCount:=10;
  4: MCount:=11;
  5: MCount:=24;
  6: MCount:=10;
  7: MCount:=8;
  8: MCount:=3;
  Else MCount:=0;
 End;
End;

{ '-' = separateur ; '|' separe le raccourci }
Function MLabelFr(M,I: Integer): String;
Begin
 MLabelFr:='';
 Case M Of
  1: Case I Of
      1: MLabelFr:=#192' propos de NewsMaster...';
      2: MLabelFr:='-';
      3: MLabelFr:='Statistiques...';
      4: MLabelFr:='M'#130'moire libre';
     End;
  2: Case I Of
      1: MLabelFr:='Menu principal...';
      2: MLabelFr:='Nouveau|^N';
      3: MLabelFr:='Ouvrir...|^O';
      4: MLabelFr:='Enregistrer|^S';
      5: MLabelFr:='Enregistrer sous...';
      6: MLabelFr:='-';
      7: MLabelFr:='Importer texte ASCII...';
      8: MLabelFr:='Exporter texte ASCII...';
      9: MLabelFr:='-';
      {$IFDEF WINPRINT}
      10: MLabelFr:='Imprimer la page...';
      11: MLabelFr:='Imprimer tout...';
      {$ELSE}
      10: MLabelFr:='Imprimer la page (PBM)...';
      11: MLabelFr:='Imprimer tout (PBM)...';
      {$ENDIF}
      12: MLabelFr:='-';
      13: MLabelFr:='Quitter|^Q';
     End;
  3: Case I Of
      1: MLabelFr:='Annuler|^Z';
      2: MLabelFr:='-';
      3: MLabelFr:='Couper|^X';
      4: MLabelFr:='Copier|^C';
      5: MLabelFr:='Coller|^V';
      6: MLabelFr:='Effacer|Suppr';
      7: MLabelFr:='Tout s'#130'lectionner|^A';
      8: MLabelFr:='-';
      9: MLabelFr:='Chercher...|^F';
      10: MLabelFr:='Chercher suivant|^G';
     End;
  4: Case I Of
      1: MLabelFr:='Choisir la police...|^T';
      2: MLabelFr:='Police pr'#130'c'#130'dente';
      3: MLabelFr:='Police suivante';
      4: MLabelFr:='-';
      5: MLabelFr:='Aligner '#133' gauche|^L';
      6: MLabelFr:='Aligner '#133' droite|^R';
      7: MLabelFr:='Centrer|^E';
      8: MLabelFr:='Justifier|^J';
      9: MLabelFr:='-';
      10: MLabelFr:='Marquer la s'#130'lection';
      11: MLabelFr:='Mode '#130'dition du texte|F2';
     End;
  5: Case I Of
      1: MLabelFr:='Mode '#130'dition d''images|F3';
      2: MLabelFr:='-';
      3: MLabelFr:='Choisir une image...|F1';
      4: MLabelFr:='Prendre|F2';
      5: MLabelFr:='Prendre une copie|F3';
      6: MLabelFr:='Poser|Entr'#130'e';
      7: MLabelFr:='Supprimer|Suppr';
      8: MLabelFr:='-';
      9: MLabelFr:='Texte par-dessus';
      10: MLabelFr:='Texte des deux c'#147't'#130's';
      11: MLabelFr:='Texte '#133' gauche seul';
      12: MLabelFr:='Texte '#133' droite seul';
      13: MLabelFr:='Zone d'#130'gag'#130'e';
      14: MLabelFr:='-';
      15: MLabelFr:='Agrandir|+';
      16: MLabelFr:='R'#130'duire|-';
      17: MLabelFr:='Taille d''origine';
      18: MLabelFr:='Retourner horizontal.';
      19: MLabelFr:='Retourner vertical.';
      20: MLabelFr:='-';
      21: MLabelFr:='Tracer une ligne';
      22: MLabelFr:='Tracer une bo'#140'te';
      23: MLabelFr:='Motif de remplissage...';
      24: MLabelFr:=#144'paisseur du trait...';
     End;
  6: Case I Of
      1: MLabelFr:='Mode mise en page|F4';
      2: MLabelFr:='-';
      3: MLabelFr:='Ajouter une colonne';
      4: MLabelFr:='Supprimer une colonne';
      5: MLabelFr:='Ajouter un titre';
      6: MLabelFr:='Supprimer le titre';
      7: MLabelFr:='-';
      8: MLabelFr:='Page pr'#130'c'#130'dente|PgHaut';
      9: MLabelFr:='Page suivante|PgBas';
      10: MLabelFr:=#133' la page...';
     End;
  7: Case I Of
      1: MLabelFr:='Zoom avant (x2)';
      2: MLabelFr:='Vue normale';
      3: MLabelFr:='Largeur de la page';
      4: MLabelFr:='Page enti'#138're';
      5: MLabelFr:='-';
      6: MLabelFr:='Pas du curseur : grand';
      7: MLabelFr:='Pas du curseur : moyen';
      8: MLabelFr:='Pas du curseur : point';
     End;
  8: Case I Of
      1: MLabelFr:='Polices de NEWS.FLB';
      2: MLabelFr:='Guides de colonnes';
      3: MLabelFr:='Afficher les infos...';
     End;
 End;
End;

Function MLabel(M,I: Integer): String;
Begin
 MLabel:=Tr(MLabelFr(M,I));
End;

Function MTitleS(M: Integer): String;
Begin
 MTitleS:=Tr(MTitle[M]);
End;

Function CurArtFlow: Integer;
Begin
 If SelArt>0 Then CurArtFlow:=Arts[SelArt].Flow Else CurArtFlow:=-1;
End;

Function MChecked(M,I: Integer): Boolean;
Begin
 MChecked:=False;
 If M=4 Then If I In [5..8] Then
  MChecked:=(St[ASt].A^[ParaEndPos(ASt,Cur)]=I-5);
 If M=5 Then If I In [9..13] Then MChecked:=(CurArtFlow=I-9);
 If M=7 Then Begin
  If I In [1..4] Then MChecked:=(ViewNo=I);
  If I=6 Then MChecked:=(ACStep=16);
  If I=7 Then MChecked:=(ACStep=4);
  If I=8 Then MChecked:=(ACStep=1);
 End;
 If M=8 Then Begin
  If I=1 Then MChecked:=UseFLB;
  If I=2 Then MChecked:=GuidesOn;
 End;
End;

Function MEnabled(M,I: Integer): Boolean;
Var A,B: Integer;
Begin
 MEnabled:=True;
 If M=3 Then Begin
  If I=1 Then MEnabled:=UndoOK;
  If I In [3,4,6] Then MEnabled:=SelRange(A,B);
  If I=5 Then MEnabled:=ClipN>0;
 End;
 If M=5 Then
  If I In [7,9..13,15..19] Then MEnabled:=SelArt>0;
 If M=8 Then If I=1 Then MEnabled:=FLBFound;
End;

Function MSep(M,I: Integer): Boolean;
Begin
 MSep:=(MLabel(M,I)='-');
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
  du menu M = identificateur 100 + 32 * M + I ; sous-menu M = 900 + M ;
  mnemonique : premiere lettre du titre pas encore prise }
Procedure BuildMenuBar;
Var M,I,K,H0,H1: Integer; S,Lb: String; Mn: Boolean;
Begin
 MenuLen:=0;
 MnemoKeys:='';
 H0:=MnOpen;
 For M:=1 To NMENU Do Begin
  S:=MTitleS(M);Lb:='';Mn:=False;
  For K:=1 To Length(S) Do Begin
   If (Not Mn) And (UpCase(S[K])>='A') And (UpCase(S[K])<='Z') And
      (Pos(UpCase(S[K]),MnemoKeys)=0) Then Begin
    Lb:=Lb+'~';MnemoKeys:=MnemoKeys+UpCase(S[K]);Mn:=True;
   End;
   Lb:=Lb+S[K];
  End;
  MnItem(MIS_TEXT Or MIS_SUBMENU,0,900+M,Lb);
  H1:=MnOpen;
  For I:=1 To MCount(M) Do
   If MSep(M,I) Then MnItem(MIS_SEPARATOR,0,100+32*M+I,'')
   Else MnItem(MIS_TEXT,0,100+32*M+I,PmMenuText(MLabel(M,I)));
  MnClose(H1,MCount(M));
 End;
 MnClose(H0,NMENU);
 OsMenu:=WinCreateMenu(OsFrame,LongInt(@MenuT));
End;

{ ouverture d'un menu : coches et choix grises de la version DOS }
Procedure MenuInit(M: LongInt);
Var I: Integer;
Begin
 M:=M-900;
 If (M<1) Or (M>NMENU) Then Exit;
 For I:=1 To MCount(M) Do
  If Not MSep(M,I) Then Begin
   MnAttr(100+32*M+I,MIA_CHECKED,MChecked(M,I));
   MnAttr(100+32*M+I,MIA_DISABLED,Not MEnabled(M,I));
  End;
End;

Function MenuX(M: Integer): Integer;
Var I,X: Integer;
Begin
 X:=12;
 For I:=1 To M-1 Do X:=X+Length(MTitleS(I))*8+20;
 MenuX:=X;
End;

Function ItemH(M,I: Integer): Integer;
Begin
 If MSep(M,I) Then ItemH:=8 Else ItemH:=16;
End;

Procedure DropRect(M: Integer; Var X1,Y1,X2,Y2: Integer);
Var I,W,L,P: Integer; S: String;
Begin
 W:=0;Y2:=MENU_H+2;
 For I:=1 To MCount(M) Do Begin
  S:=MLabel(M,I);
  P:=Pos('|',S);
  If P>0 Then L:=(P-1)*8+24+(Length(S)-P)*8 Else L:=Length(S)*8;
  If L>W Then W:=L;
  Y2:=Y2+ItemH(M,I);
 End;
 X1:=MenuX(M)-8;
 X2:=X1+W+32;
 If X2>SCR_W-4 Then Begin X1:=X1-(X2-(SCR_W-4));X2:=SCR_W-4;End;
 Y1:=MENU_H;
End;

Function ItemY(M,I: Integer): Integer;
Var K,Y: Integer;
Begin
 Y:=MENU_H+2;
 For K:=1 To I-1 Do Y:=Y+ItemH(M,K);
 ItemY:=Y;
End;

Function DropHit(M: Integer; X,Y: LongInt): Integer;
Var X1,Y1,X2,Y2,I: Integer;
Begin
 DropHit:=0;
 DropRect(M,X1,Y1,X2,Y2);
 If Not InBox(X,Y,X1,Y1,X2,Y2) Then Exit;
 For I:=1 To MCount(M) Do
  If (Y>=ItemY(M,I)) And (Y<ItemY(M,I)+ItemH(M,I)) Then DropHit:=I;
End;

Function TitleHit(X,Y: LongInt): Integer;
Var M: Integer;
Begin
 TitleHit:=0;
 If (Y<0) Or (Y>=MENU_H) Then Exit;
 For M:=1 To NMENU Do
  If (X>=MenuX(M)-8) And (X<=MenuX(M)+Length(MTitleS(M))*8+7) Then TitleHit:=M;
End;

Procedure DrawMenuBar;
Var M: Integer;
Begin
 Box(0,0,SCR_W-1,MENU_H-1,PAPER);
 SetColor(INK);
 SetLineStyle(SolidLn,0,1);
 Line(0,MENU_H-1,SCR_W-1,MENU_H-1);
 For M:=1 To NMENU Do Begin
  If M=MenuOpen Then Begin
   Box(MenuX(M)-8,0,MenuX(M)+Length(MTitleS(M))*8+7,MENU_H-2,INK);
   WText(MenuX(M),5,MTitleS(M));
  End Else BText(MenuX(M),5,MTitleS(M));
 End;
End;

Procedure DrawDropDown;
Var X1,Y1,X2,Y2,I,Y,P: Integer; S,Sc_,Lb: String; Hi: Boolean;
Begin
 If MenuOpen=0 Then Exit;
 DropRect(MenuOpen,X1,Y1,X2,Y2);
 Box(X1+3,Y1+3,X2+3,Y2+3,INK);
 Box(X1,Y1,X2,Y2,PAPER);
 Frame(X1,Y1,X2,Y2);
 For I:=1 To MCount(MenuOpen) Do Begin
  S:=MLabel(MenuOpen,I);
  Y:=ItemY(MenuOpen,I);
  If S='-' Then Begin
   SetLineStyle(UserBitLn,$AAAA,1);
   SetColor(INK);
   Line(X1+2,Y+3,X2-2,Y+3);
   SetLineStyle(SolidLn,0,1);
  End Else Begin
   P:=Pos('|',S);
   If P>0 Then Begin Lb:=Copy(S,1,P-1);Sc_:=Copy(S,P+1,20);End Else Begin
     Lb:=S;Sc_:='';End;
   Hi:=(I=MenuHi) And MEnabled(MenuOpen,I);
   If Hi Then Box(X1+1,Y,X2-1,Y+15,INK);
   If MChecked(MenuOpen,I) Then Begin
    If Hi Then WText(X1+4,Y+4,#251) Else PText(X1+4,Y+4,#251);
   End;
   If Not MEnabled(MenuOpen,I) Then Begin
    GreyText(X1+24,Y+4,Lb);
    If Sc_<>'' Then GreyText(X2-8-Length(Sc_)*8,Y+4,Sc_);
   End Else If Hi Then Begin
    WText(X1+24,Y+4,Lb);
    If Sc_<>'' Then WText(X2-8-Length(Sc_)*8,Y+4,Sc_);
   End Else Begin
    PText(X1+24,Y+4,Lb);
    If Sc_<>'' Then PText(X2-8-Length(Sc_)*8,Y+4,Sc_);
   End;
  End;
 End;
End;

Function NextItem(M,From,Dir: Integer): Integer;
Var I,N: Integer;
Begin
 N:=MCount(M);
 I:=From;
 Repeat
  I:=I+Dir;
  If I<1 Then I:=N;
  If I>N Then I:=1;
  If (Not MSep(M,I)) And MEnabled(M,I) Then Begin NextItem:=I;Exit;End;
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
          If (H<>0) And (MSep(M,H) Or Not MEnabled(M,H)) Then H:=0;
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
       If (H<>0) And (Hi=H) Then Begin Pick:=True;Done:=True;End;
      End;
   1: Case E.Key Of
       K_ESC: Done:=True;
       K_LEFT: Begin Dec(M);If M<1 Then M:=NMENU;Hi:=NextItem(M,0,1);
         Redraw:=True;End;
       K_RIGHT: Begin Inc(M);If M>NMENU Then M:=1;Hi:=NextItem(M,0,1);
         Redraw:=True;End;
       K_UP: Begin Hi:=NextItem(M,Hi,-1);Redraw:=True;End;
       K_DOWN: Begin Hi:=NextItem(M,Hi,1);Redraw:=True;End;
       K_ENTER: If Hi<>0 Then Begin Pick:=True;Done:=True;End;
      End;
  End;
  If Redraw Then Begin MenuOpen:=M;MenuHi:=Hi;DrawAll;End;
 Until Done;
 MenuOpen:=0;MenuHi:=0;
 DrawAll;
 If Pick And (Hi>0) Then DoMenu(M,Hi);
End;

{ ====================================================================== }
{                  PANNEAU DES TOUCHES DE FONCTION                       }
{ ====================================================================== }

Procedure AddPB(Const Txt: String; Ico: Byte);
Var P: Integer; S: String;
Begin
 If NPB>=10 Then Exit;
 Inc(NPB);
 PB[NPB].Fk:=NPB;PB[NPB].Ico:=Ico;PB[NPB].On:=True;
 PB[NPB].L1:='';PB[NPB].L2:='';PB[NPB].L3:='';
 S:=Tr(Txt);
 P:=Pos('|',S);
 If P=0 Then PB[NPB].L1:=Copy(S,1,7)
 Else Begin
  PB[NPB].L1:=Copy(S,1,Min2(P-1,7));Delete(S,1,P);
  P:=Pos('|',S);
  If P=0 Then PB[NPB].L2:=Copy(S,1,7)
  Else Begin PB[NPB].L2:=Copy(S,1,Min2(P-1,7));PB[NPB].L3:=Copy(S,P+1,7);End;
 End;
End;

Procedure SetPanel(M: Integer);
Begin
 Mode:=M;NPB:=0;PBDown:=0;
 Case M Of
  MD_MAIN: Begin
    PanelTitle:='MENU D'''#144'DITION PRINCIPAL';
    AddPB('VUE',1);AddPB('TEXTE',2);AddPB('IMAGES',3);
    AddPB('PAGE',4);AddPB('FICHIER',5);AddPB('IMPRIM.',6);
   End;
  MD_VIEW: Begin
    PanelTitle:='CHANGER LA VUE DU JOURNAL';
    AddPB('ZOOM|AVANT',0);AddPB('VUE|NORMALE',0);AddPB('LARGEUR|DE PAGE',0);
    AddPB('PAGE|ENTI'#138'RE',0);AddPB('PAGE|PR'#144'C.',0);AddPB('PAGE|SUIV.',
      0);
   End;
  MD_TEXT: Begin
    PanelTitle:='MODIFIER LE TEXTE';
    AddPB('CHOISIR|POLICE',0);AddPB('ALIGNE-|MENT',0);AddPB('S'#144'LEC-|TION',
      0);
    AddPB('COUPER',0);AddPB('COPIER',0);AddPB('COLLER',0);
    AddPB('IMPORT|ASCII',0);AddPB('ANNULER',0);
   End;
  MD_ART: Begin
    PanelTitle:='MODIFIER LES IMAGES';
    AddPB('CHOISIR|IMAGE',0);AddPB('PRENDRE',0);AddPB('PRENDRE|COPIE',0);
    AddPB('POSER',0);AddPB('TAILLE',0);AddPB('ROGNER',0);AddPB('HABIL-|LAGE',0);
    AddPB('RETOUR-|NER',0);AddPB('LIGNE|BO'#139'TE',0);AddPB('SUPPR.',0);
   End;
  MD_LAYOUT: Begin
    PanelTitle:='MODIFIER LA MISE EN PAGE';
    AddPB('AJOUT|COLONNE',0);AddPB('SUPPR.|COLONNE',0);AddPB('AJOUT|TITRE',0);
    AddPB('SUPPR.|TITRE',0);
   End;
  MD_FILE: Begin
    PanelTitle:='CHARGER ET ENREGISTRER';
    AddPB('NOUVEAU',0);AddPB('OUVRIR',0);AddPB('ENREG.',0);
    AddPB('ENREG.|SOUS',0);AddPB('MENU|PRINC.',0);AddPB('QUITTER',0);
   End;
  MD_PRINT: Begin
    PanelTitle:='IMPRIMER LE JOURNAL';
    AddPB('CETTE|PAGE',0);AddPB('TOUTES|PAGES',0);AddPB('EXPORT|TEXTE',0);
   End;
 End;
 NeedDraw:=True;
End;

{ Icones des boutons du menu principal (zone 32 x 30) }
Procedure DrawIcon(N,X,Y: Integer);
Var C: Integer;
Begin
 SetColor(INK);SetLineStyle(SolidLn,0,1);SetFill(INK);
 Case N Of
  1: Begin
    Circle(X+13,Y+12,10);Circle(X+13,Y+12,9);
    Line(X+21,Y+20,X+30,Y+29);Line(X+22,Y+19,X+31,Y+28);Line(X+20,Y+21,X+29,
      Y+30);
    Line(X+8,Y+9,X+18,Y+9);Line(X+7,Y+12,X+19,Y+12);Line(X+8,Y+15,X+16,Y+15);
   End;
  2: Begin
    Bar(X+5,Y+4,X+8,Y+26);Bar(X+5,Y+4,X+19,Y+7);
    Bar(X+5,Y+13,X+16,Y+16);Bar(X+5,Y+23,X+19,Y+26);
    Line(X+25,Y+4,X+25,Y+26);Line(X+22,Y+4,X+28,Y+4);Line(X+22,Y+26,X+28,Y+26);
   End;
  3: Begin
    Rectangle(X+2,Y+2,X+29,Y+27);Rectangle(X+4,Y+4,X+27,Y+25);
    Circle(X+11,Y+11,3);
    Line(X+4,Y+25,X+13,Y+14);Line(X+13,Y+14,X+19,Y+21);
    Line(X+19,Y+21,X+22,Y+17);Line(X+22,Y+17,X+27,Y+25);
   End;
  4: Begin
    Rectangle(X+5,Y+1,X+27,Y+28);
    Bar(X+8,Y+4,X+24,Y+8);
    For C:=0 To 2 Do PatBar(X+8+C*6,Y+11,X+11+C*6,Y+25,PatGrey);
    For C:=0 To 2 Do Rectangle(X+8+C*6,Y+11,X+11+C*6,Y+25);
   End;
  5: Begin
    Rectangle(X+3,Y+2,X+29,Y+28);
    Bar(X+10,Y+2,X+22,Y+10);
    SetColor(PAPER);Bar(X+17,Y+4,X+20,Y+8);SetColor(INK);
    Rectangle(X+7,Y+15,X+25,Y+27);
    Line(X+9,Y+19,X+23,Y+19);Line(X+9,Y+23,X+23,Y+23);
   End;
  6: Begin
    Rectangle(X+9,Y+1,X+23,Y+10);
    Line(X+11,Y+4,X+21,Y+4);Line(X+11,Y+7,X+21,Y+7);
    Bar(X+3,Y+10,X+29,Y+20);
    Rectangle(X+9,Y+17,X+23,Y+28);
    SetColor(PAPER);Line(X+11,Y+21,X+21,Y+21);Line(X+11,Y+24,X+21,Y+24);
      SetColor(INK);
    SetColor(PAPER);Line(X+5,Y+13,X+8,Y+13);SetColor(INK);
   End;
 End;
End;

Procedure DrawPanelButton(I: Integer);
Var X,Y,W,H,TX: Integer; S: String;
Begin
 X:=8+(I-1)*62;Y:=PANEL_Y+34;W:=58;H:=58;
 Box(X+3,Y+3,X+W+3,Y+H+3,INK);
 Box(X,Y,X+W,Y+H,PAPER);
 Frame(X,Y,X+W,Y+H);
 S:='F'+IntStr(I);
 BText(X+(W-TextW(S)) Div 2,Y+3,S);
 SetColor(INK);Line(X,Y+13,X+W,Y+13);
 If PB[I].Ico>0 Then Begin
  DrawIcon(PB[I].Ico,X+13,Y+19);
 End Else Begin
  If PB[I].L2='' Then Begin
   PText(X+(W-TextW(PB[I].L1)) Div 2,Y+30,PB[I].L1);
  End Else If PB[I].L3='' Then Begin
   PText(X+(W-TextW(PB[I].L1)) Div 2,Y+24,PB[I].L1);
   PText(X+(W-TextW(PB[I].L2)) Div 2,Y+37,PB[I].L2);
  End Else Begin
   PText(X+(W-TextW(PB[I].L1)) Div 2,Y+19,PB[I].L1);
   PText(X+(W-TextW(PB[I].L2)) Div 2,Y+31,PB[I].L2);
   PText(X+(W-TextW(PB[I].L3)) Div 2,Y+43,PB[I].L3);
  End;
 End;
 If PBDown=I Then Begin
  SetWriteMode(XORPut);SetColor(PAPER);
  For TX:=Y+1 To Y+H-1 Do Line(X+1,TX,X+W-1,TX);
  SetWriteMode(NormalPut);
 End;
End;

Function PanelHit(X,Y: LongInt): Integer;
Var I: Integer;
Begin
 PanelHit:=0;
 For I:=1 To NPB Do
  If InBox(X,Y,8+(I-1)*62,PANEL_Y+34,8+(I-1)*62+58,PANEL_Y+92) Then PanelHit:=I;
End;

Function ViewName: String;
Begin
 Case ViewNo Of
  1: ViewName:=Tr('ZOOM X2');
  2: ViewName:=Tr('NORMALE');
  3: ViewName:=Tr('LARGEUR');
  4: ViewName:=Tr('PAGE ENTI'#138'RE');
 Else ViewName:='';
 End;
End;

Function IndicatorText: String;
Var S: String;
Begin
 Case Mode Of
  MD_MAIN,MD_TEXT: Begin
    S:=Upper(FName[CurFont]);
    IndicatorText:=S;
   End;
  MD_VIEW: IndicatorText:=ViewName;
  MD_ART: Begin
    S:=Tr('PAS ')+IntStr(ACStep);
    If ArtSub=1 Then S:=Tr('TAILLE');
    If ArtSub=2 Then S:=Tr('ROGNAGE');
    If ArtSub=3 Then S:=Tr('TRAC'#144);
    IndicatorText:=S;
   End;
  MD_FILE,MD_PRINT: Begin
    If DocName='' Then IndicatorText:=Tr('SANS NOM') Else
      IndicatorText:=Upper(ShortName(DocName));
   End;
 Else IndicatorText:='';
 End;
End;

Procedure DrawPanel;
Var I,W,X: Integer; S: String;
Begin
 PatBar(0,PANEL_Y,SCR_W-1,SCR_H-1,PatStripe);
 SetColor(INK);SetLineStyle(SolidLn,0,1);
 Line(0,PANEL_Y,SCR_W-1,PANEL_Y);
 Line(0,PANEL_Y+1,SCR_W-1,PANEL_Y+1);
 S:=Tr(PanelTitle);
 W:=TextW(S)+24;
 LabelBox((SCR_W-W) Div 2,PANEL_Y+8,(SCR_W+W) Div 2,PANEL_Y+26,S);
 { page courante }
 S:=Tr('PAGE ')+IntStr(CurPage)+'/'+IntStr(NPg);
 If (Mode=MD_TEXT) And (Mode<>MD_LAYOUT) Then Begin
  I:=LineOfPos(ASt,Cur);
  If I>=0 Then S:=Tr('PAGE ')+IntStr(Lines^[I].Pg)+'/'+IntStr(NPg);
 End;
 LabelBox(14,PANEL_Y+8,14+TextW(S)+20,PANEL_Y+26,S);
 { message d'etat }
 If (StatusMsg<>'') And (Tick>=StatusT) And (Tick-StatusT<500) Then Begin
  W:=TextW(StatusMsg)+20;
  LabelBox(SCR_W-14-W,PANEL_Y+8,SCR_W-14,PANEL_Y+26,StatusMsg);
 End Else If Overflow And (Mode=MD_TEXT) Then Begin
  S:=Tr('TEXTE EN TROP');
  LabelBox(SCR_W-14-TextW(S)-20,PANEL_Y+8,SCR_W-14,PANEL_Y+26,S);
 End;
 For I:=1 To NPB Do DrawPanelButton(I);
 S:=IndicatorText;
 If S<>'' Then Begin
  W:=TextW(S)+20;
  If W<80 Then W:=80;
  If NPB>8 Then Begin
   If Not ((StatusMsg<>'') And (Tick>=StatusT) And (Tick-StatusT<500)) And Not
     (Overflow And (Mode=MD_TEXT)) Then
    LabelBox(SCR_W-14-W,PANEL_Y+8,SCR_W-14,PANEL_Y+26,S);
  End Else
   LabelBox(SCR_W-14-W,PANEL_Y+64,SCR_W-14,PANEL_Y+82,S);
 End;
End;

{ ====================================================================== }
{               ECRAN DE MISE EN PAGE (apercu en miniature)              }
{ ====================================================================== }

Procedure DrawLayoutScreen;
Var X0,Y0,SvN,SvD,Yb: Integer; S: String; W,I: Integer;
Begin
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 PatBar(0,MENU_H,SCR_W-1,SCR_H-1,PatStripe);
 SvN:=ZN;SvD:=ZD;
 ZN:=3;ZD:=10;
 X0:=(SCR_W-Sc(PGW)) Div 2;Y0:=MENU_H+10;
 DrawPageFull(CurPage,X0,Y0,True);
 Yb:=Y0+Sc(PGH)+20;
 ZN:=SvN;ZD:=SvD;
 S:=Tr('MISE EN PAGE - PAGE ')+IntStr(CurPage)+'/'+IntStr(NPg)+' '+
   '- '+IntStr(NCol[CurPage]);
 If NCol[CurPage]>1 Then S:=S+Tr(' COLONNES') Else S:=S+Tr(' COLONNE');
 If HasHead[CurPage] Then S:=S+Tr(' + TITRE');
 W:=TextW(S)+30;
 LabelBox((SCR_W-W) Div 2,Yb,(SCR_W+W) Div 2,Yb+20,S);
 For I:=1 To NPB Do Begin
  DrawPanelButton(I);
 End;
End;

{ ====================================================================== }
{                           VUE ET DEFILEMENT                            }
{ ====================================================================== }

Procedure SetView(V: Integer);
Var I: Integer;
Begin
 ViewNo:=V;
 Case V Of
  1: Begin ZN:=2;ZD:=1;End;
  2: Begin ZN:=1;ZD:=1;End;
  3: Begin ZN:=5;ZD:=8;End;
  4: Begin ZN:=3;ZD:=8;End;
 End;
 If CurPage<1 Then CurPage:=1;
 If CurPage>NPg Then CurPage:=NPg;
 ScrX:=0;
 ScrY:=LongInt(CurPage-1)*StrideP;
 If (Mode=MD_TEXT) And Not Greek Then Begin
  I:=LineOfPos(ASt,Cur);
  If I>=0 Then ScrollToLine(I);
 End;
 ClampScroll;
 NeedDraw:=True;
End;

Procedure ScrollBy(DX,DY: LongInt);
Begin
 ScrX:=ScrX+DX;ScrY:=ScrY+DY;
 ClampScroll;
 NeedDraw:=True;
End;

Procedure GotoPage(P: Integer);
Begin
 If P<1 Then P:=1;
 If P>NPg Then P:=NPg;
 CurPage:=P;
 ScrY:=LongInt(P-1)*StrideP;
 ClampScroll;
 If Mode=MD_ART Then Begin
  ACy:=LongInt(P-1)*(PGH+PGGAP)+MRG;
 End;
 NeedDraw:=True;
End;

{ ====================================================================== }
{                          EDITION DU TEXTE                              }
{ ====================================================================== }

Procedure SyncFont;
Begin
 If (Cur>0) And (St[ASt].T^[Cur-1]<>13) Then CurFont:=St[ASt].F^[Cur-1]
 Else CurFont:=St[ASt].F^[Cur];
End;

Procedure AfterEdit;
Var I: Integer;
Begin
 Modified:=True;
 Relayout;
 I:=LineOfPos(ASt,Cur);
 If I>=0 Then Begin ScrollToLine(I);CurPage:=Lines^[I].Pg;End;
End;

Procedure Moved;
Var I: Integer;
Begin
 TypRun:=False;
 SyncFont;
 I:=LineOfPos(ASt,Cur);
 If I>=0 Then Begin ScrollToLine(I);CurPage:=Lines^[I].Pg;End;
 NeedDraw:=True;
End;

Function DelSel: Boolean;
Var A,B: Integer;
Begin
 DelSel:=False;
 If SelRange(A,B) Then Begin
  StDel(ASt,A,B);Cur:=A;SelA:=-1;MarkMode:=False;DelSel:=True;
 End Else SelA:=-1;
End;

Procedure TypeChar(Ch: Byte);
Var Al: Byte; A,B: Integer;
Begin
 If SelRange(A,B) Then Begin PushUndo;TypRun:=True;DelSel;End
 Else If Not TypRun Then Begin PushUndo;TypRun:=True;End;
 If Ch=13 Then Al:=St[ASt].A^[ParaEndPos(ASt,Cur)] Else Al:=0;
 If StIns(ASt,Cur,Ch,CurFont,Al) Then Inc(Cur)
 Else SetStatus('TEXTE TROP LONG');
 SelA:=-1;
 AfterEdit;
End;

Procedure DoBackspace;
Var A,B: Integer;
Begin
 If SelRange(A,B) Then Begin PushUndo;DelSel;AfterEdit;Exit;End;
 SelA:=-1;
 If Cur=0 Then Exit;
 If Not TypRun Then Begin PushUndo;TypRun:=True;End;
 StDel(ASt,Cur-1,Cur);Dec(Cur);
 AfterEdit;
End;

Procedure DoDelete;
Var A,B: Integer;
Begin
 If SelRange(A,B) Then Begin PushUndo;DelSel;AfterEdit;Exit;End;
 SelA:=-1;
 If Cur>=St[ASt].Len Then Exit;
 If Not TypRun Then Begin PushUndo;TypRun:=True;End;
 StDel(ASt,Cur,Cur+1);
 AfterEdit;
End;

Procedure MoveTo(P: Integer);
Begin
 If P<0 Then P:=0;
 If P>St[ASt].Len Then P:=St[ASt].Len;
 If MarkMode Then Begin
  If SelA<0 Then SelA:=Cur;
 End Else SelA:=-1;
 Cur:=P;WantX:=-1;
 Moved;
End;

Procedure CurUpDown(Dir: Integer);
Var I,J,P: Integer;
Begin
 I:=LineOfPos(ASt,Cur);
 If I<0 Then Exit;
 If WantX<0 Then WantX:=XOfPos(I,Cur)-Lines^[I].X;
 J:=I+Dir;
 While (J>=0) And (J<NLn) And (Lines^[J].Sty<>ASt) Do J:=J+Dir;
 If (J<0) Or (J>=NLn) Then Exit;
 P:=PosAtX(J,Lines^[J].X+WantX);
 If P>Lines^[J].E Then P:=Lines^[J].E;
 If MarkMode Then Begin
  If SelA<0 Then SelA:=Cur;
 End Else SelA:=-1;
 Cur:=P;
 TypRun:=False;SyncFont;
 ScrollToLine(J);CurPage:=Lines^[J].Pg;
 NeedDraw:=True;
End;

Procedure CurLineEdge(Home: Boolean);
Var I: Integer;
Begin
 I:=LineOfPos(ASt,Cur);
 If I<0 Then Exit;
 If Home Then MoveTo(Lines^[I].S) Else MoveTo(Lines^[I].E);
End;

Procedure ClipCopy;
Var A,B,N: Integer;
Begin
 If Not SelRange(A,B) Then Exit;
 N:=B-A;
 If N>CLIPCAP Then N:=CLIPCAP;
 Move(St[ASt].T^[A],ClipT^,N);
 Move(St[ASt].F^[A],ClipF^,N);
 ClipN:=N;
 SetStatus(IntStr(N)+Tr(' CARACT'#138'RES COPI'#144'S'));
End;

Procedure ClipCut;
Var A,B: Integer;
Begin
 If Not SelRange(A,B) Then Exit;
 ClipCopy;
 PushUndo;
 DelSel;
 AfterEdit;
End;

Procedure ClipPaste;
Var A,B,N: Integer; AA: Byte;
Begin
 If ClipN=0 Then Exit;
 PushUndo;
 If SelRange(A,B) Then DelSel;
 N:=ClipN;
 If St[ASt].Len+N>St[ASt].Cap Then N:=St[ASt].Cap-St[ASt].Len;
 If N<=0 Then Begin SetStatus('TEXTE TROP LONG');Exit;End;
 Move(St[ASt].T^[Cur],St[ASt].T^[Cur+N],St[ASt].Len-Cur+1);
 Move(St[ASt].F^[Cur],St[ASt].F^[Cur+N],St[ASt].Len-Cur+1);
 Move(St[ASt].A^[Cur],St[ASt].A^[Cur+N],St[ASt].Len-Cur+1);
 Move(ClipT^,St[ASt].T^[Cur],N);
 Move(ClipF^,St[ASt].F^[Cur],N);
 FillChar(St[ASt].A^[Cur],N,AL_LEFT);
 Inc(St[ASt].Len,N);
 Cur:=Cur+N;SelA:=-1;
 AfterEdit;
End;

Procedure SelectAll;
Begin
 SelA:=0;Cur:=St[ASt].Len;
 Moved;
End;

Procedure ToggleMark;
Begin
 MarkMode:=Not MarkMode;
 If MarkMode Then Begin SelA:=Cur;SetStatus('MARQUEZ AVEC LES FL'#138'CHES');End
 Else SetStatus('S'#144'LECTION FIX'#144'E');
 NeedDraw:=True;
End;

Procedure SetAlign(Al: Integer);
Var A,B,P,PE: Integer;
Begin
 PushUndo;
 If Not SelRange(A,B) Then Begin A:=Cur;B:=Cur;End;
 P:=ParaEndPos(ASt,A);
 PE:=ParaEndPos(ASt,B);
 While True Do Begin
  St[ASt].A^[P]:=Al;
  If (P>=PE) Or (P>=St[ASt].Len) Then Break;
  P:=ParaEndPos(ASt,P+1);
 End;
 Modified:=True;
 Relayout;
End;

Procedure SetFontSel(F: Integer);
Var A,B,I: Integer;
Begin
 If SelRange(A,B) Then Begin
  PushUndo;
  For I:=A To B-1 Do St[ASt].F^[I]:=F;
  CurFont:=F;
  Modified:=True;
  Relayout;
 End Else Begin
  CurFont:=F;
  St[ASt].F^[Cur]:=F;
  If (Cur<St[ASt].Len) And (St[ASt].T^[Cur]=13) Then St[ASt].F^[Cur]:=F;
  Relayout;
 End;
End;

{ ---- selecteur de police ---- }
Function PickFont(Cur0: Integer): Integer;
Var Sel,Top,I,Y,N,RowH,Rows,X0,Y0,W,H: Integer; E: TEvent; Done,Redraw: Boolean;
    S: String; LastT: LongInt;
Begin
 PickFont:=-1;
 Sel:=Cur0;Top:=0;Rows:=14;RowH:=14;
 W:=560;H:=Rows*RowH+TBH+56;
 X0:=(SCR_W-W) Div 2;Y0:=(SCR_H-H) Div 2-6;
 Done:=False;Redraw:=True;LastT:=0;
 Repeat
  If Sel<Top Then Top:=Sel;
  If Sel>=Top+Rows Then Top:=Sel-Rows+1;
  If Redraw Then Begin
   HideMouse;
   DlgFrame(X0,Y0,W,H,'Choisir une police');
   Box(X0+10,Y0+TBH+8,X0+240,Y0+TBH+8+Rows*RowH,PAPER);
   Frame(X0+10,Y0+TBH+8,X0+240,Y0+TBH+8+Rows*RowH);
   For I:=0 To Rows-1 Do
    If Top+I<NFont Then Begin
     Y:=Y0+TBH+10+I*RowH;
     If Top+I=Sel Then Begin
      Box(X0+11,Y-1,X0+239,Y+RowH-2,INK);
      WText(X0+16,Y+2,FName[Top+I]);
     End Else PText(X0+16,Y+2,FName[Top+I]);
    End;
   { apercu }
   Box(X0+250,Y0+TBH+8,X0+W-10,Y0+TBH+8+Rows*RowH,PAPER);
   Frame(X0+250,Y0+TBH+8,X0+W-10,Y0+TBH+8+Rows*RowH);
   SetViewPort(X0+251,Y0+TBH+9,X0+W-11,Y0+TBH+7+Rows*RowH,True);
   EnsureFont(Sel);
   N:=FAsc[Sel]+FDsc[Sel];
   Y:=4;
   S:='Journal NewsMaster';
   DrawStrF(Sel,6,Y,S);Y:=Y+N+4;
   If Y+N<Rows*RowH-4 Then Begin DrawStrF(Sel,6,Y,'ABCDEFGHIJKLMNOPQRSTU');
     Y:=Y+N+4;End;
   If Y+N<Rows*RowH-4 Then Begin DrawStrF(Sel,6,Y,'abcdefghijklmnopqrstu');
     Y:=Y+N+4;End;
   If Y+N<Rows*RowH-4 Then DrawStrF(Sel,6,Y,'0123456789 !?&%$.,;:()');
   SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
   Button(X0+W-190,Y0+H-34,X0+W-110,Y0+H-14,'OK',True,True);
   Button(X0+W-96,Y0+H-34,X0+W-16,Y0+H-14,'&Annuler',False,True);
   PText(X0+14,Y0+H-30,IntStr(NFont)+Tr(' polices'));
   If UseFLB Then PText(X0+14,Y0+H-20,'NEWS.FLB') Else PText(X0+14,Y0+H-20,
     Tr('int'#130'gr'#130'es'));
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ESC: Done:=True;
    K_ENTER: Begin PickFont:=Sel;Done:=True;End;
    K_UP: If Sel>0 Then Begin Dec(Sel);Redraw:=True;End;
    K_DOWN: If Sel<NFont-1 Then Begin Inc(Sel);Redraw:=True;End;
    K_PGUP: Begin Sel:=Sel-Rows;If Sel<0 Then Sel:=0;Redraw:=True;End;
    K_PGDN: Begin Sel:=Sel+Rows;If Sel>NFont-1 Then Sel:=NFont-1;Redraw:=True;
      End;
    K_HOME: Begin Sel:=0;Redraw:=True;End;
    K_END: Begin Sel:=NFont-1;Redraw:=True;End;
   End;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X0+10,Y0+TBH+10,X0+240,Y0+TBH+10+Rows*RowH) Then Begin
    I:=Top+Integer((E.Y-(Y0+TBH+10)) Div RowH);
    If (I>=0) And (I<NFont) Then Begin
     If (I=Sel) And (Tick-LastT<40) Then Begin PickFont:=Sel;Done:=True;End;
     Sel:=I;Redraw:=True;LastT:=Tick;
    End;
   End Else If InBox(E.X,E.Y,X0+W-190,Y0+H-34,X0+W-110,Y0+H-14) Then Begin
    PickFont:=Sel;Done:=True;
   End Else If InBox(E.X,E.Y,X0+W-96,Y0+H-34,X0+W-16,Y0+H-14) Then Done:=True
   Else If InBox(E.X,E.Y,X0+3,Y0+3,X0+22,Y0+TBH) Then Done:=True;
  End;
 Until Done;
 NeedDraw:=True;
End;

Procedure CmdFont;
Var F: Integer;
Begin
 F:=PickFont(CurFont);
 If F>=0 Then SetFontSel(F);
End;

Procedure CmdFontStep(Dir: Integer);
Var F: Integer;
Begin
 F:=CurFont+Dir;
 If F<0 Then F:=NFont-1;
 If F>=NFont Then F:=0;
 SetFontSel(F);
End;

Procedure CmdAlignPopup;
Var Cur0,R: Integer;
Begin
 Cur0:=St[ASt].A^[ParaEndPos(ASt,Cur)]+1;
 R:=PopupAt(8+1*62,PANEL_Y-80,110,1,Cur0);
 If R>0 Then SetAlign(R-1);
End;

Function MatchAt(Ps: Integer; Const Pat: String): Boolean;
Var I: Integer;
Begin
 MatchAt:=False;
 If Ps+Length(Pat)>St[ASt].Len Then Exit;
 For I:=1 To Length(Pat) Do
  If UpCase(Chr(St[ASt].T^[Ps+I-1]))<>UpCase(Pat[I]) Then Exit;
 MatchAt:=True;
End;

Procedure FindNextText;
Var I: Integer; Ok: Boolean;
Begin
 If FindStr='' Then Exit;
 Ok:=False;
 For I:=Cur+1 To St[ASt].Len-Length(FindStr) Do
  If MatchAt(I,FindStr) Then Begin
   SelA:=I;Cur:=I+Length(FindStr);Ok:=True;Break;
  End;
 If Not Ok Then
  For I:=0 To Cur Do
   If MatchAt(I,FindStr) Then Begin
    SelA:=I;Cur:=I+Length(FindStr);Ok:=True;Break;
   End;
 If Ok Then Begin MarkMode:=False;Moved;End
 Else SetStatus('INTROUVABLE');
End;

Procedure CmdFind;
Var S: String;
Begin
 S:=FindStr;
 If InputBox('Chercher','Texte '#133' chercher :',S,30) Then Begin
  FindStr:=Copy(S,1,40);
  If Mode<>MD_TEXT Then SetPanel(MD_TEXT);
  FindNextText;
 End;
End;

{ ====================================================================== }
{                       EDITION DES IMAGES                               }
{ ====================================================================== }

Procedure UpdateSelArt;
Var P: Integer; LX_,LY_: LongInt;
Begin
 DocToPage(ACx,ACy,P,LX_,LY_);
 CurPage:=P;
 SelArt:=ArtOnPage(P,Integer(LX_),Integer(LY_));
End;

Procedure DelArt(I: Integer);
Var K: Integer;
Begin
 If (I<1) Or (I>NArt) Then Exit;
 PushUndoDoc(0);
 For K:=I To NArt-1 Do Arts[K]:=Arts[K+1];
 Dec(NArt);
 SelArt:=0;
 Modified:=True;
 Relayout;
 UpdateSelArt;
End;

Function AddArt(Const A: TArt): Integer;
Begin
 AddArt:=0;
 If NArt>=MAXART Then Begin SetStatus('TROP D''OBJETS');Exit;End;
 Inc(NArt);
 Arts[NArt]:=A;
 AddArt:=NArt;
End;

Procedure ClampArt(Var A: TArt);
Begin
 If A.W<4 Then A.W:=4;
 If A.H<4 Then A.H:=4;
 If A.W>PGW Then A.W:=PGW;
 If A.H>PGH Then A.H:=PGH;
 If A.X<0 Then A.X:=0;
 If A.Y<0 Then A.Y:=0;
 If A.X+A.W>PGW Then A.X:=PGW-A.W;
 If A.Y+A.H>PGH Then A.Y:=PGH-A.H;
End;

Procedure StampHeld;
Var P: Integer; LX_,LY_: LongInt; A: TArt; I: Integer;
Begin
 If Not HeldOn Then Begin SetStatus('RIEN A POSER');Exit;End;
 DocToPage(ACx,ACy,P,LX_,LY_);
 A:=Held;
 A.Pg:=P;A.X:=Integer(LX_);A.Y:=Integer(LY_);
 ClampArt(A);
 PushUndoDoc(0);
 I:=AddArt(A);
 If I>0 Then Begin
  Modified:=True;
  Relayout;
  SelArt:=I;
 End;
End;

Procedure PickUp(Copy_: Boolean);
Begin
 If SelArt<=0 Then Begin SetStatus('AUCUNE IMAGE ICI');Exit;End;
 Held:=Arts[SelArt];
 HeldOn:=True;
 ACx:=Held.X;
 ACy:=LongInt(Held.Pg-1)*(PGH+PGGAP)+Held.Y;
 If Not Copy_ Then DelArt(SelArt);
 NeedDraw:=True;
End;

Function ArtPicker: Integer;
Var Sel,Pg,OldPg,I,K,X0,Y0,W,H,CX,CY,Cols,PerPg,NPgs,DW,DH,Fit: Integer;
    YY: Integer; E: TEvent; Done,Redraw,Reload: Boolean; T: TPiece; S: String;
    Cache: Array[1..15] Of TPiece;
Begin
 ArtPicker:=0;
 FillChar(Cache,SizeOf(Cache),0);
 T.B:=Nil;T.W:=0;T.H:=0;
 If SrcN<1 Then SrcSelect(SrcCur);
 Sel:=1;Cols:=5;PerPg:=15;
 W:=Cols*96+24;H:=3*96+TBH+78;
 X0:=(SCR_W-W) Div 2;Y0:=(SCR_H-H) Div 2-6;
 OldPg:=-1;Done:=False;Redraw:=True;
 Repeat
  If SrcN<1 Then Sel:=0
  Else Begin
   If Sel<1 Then Sel:=1;
   If Sel>SrcN Then Sel:=SrcN;
  End;
  Pg:=(Sel-1) Div PerPg;If Pg<0 Then Pg:=0;
  Reload:=(Pg<>OldPg);
  If Reload Then Begin
   For K:=1 To PerPg Do Begin
    SrcPiece(Pg*PerPg+K,Cache[K]);
   End;
   OldPg:=Pg;Redraw:=True;
  End;
  NPgs:=(SrcN+PerPg-1) Div PerPg;
  If Redraw Then Begin
   HideMouse;
   DlgFrame(X0,Y0,W,H,'Choisir une image');
   S:=Tr('Biblioth'#138'que : ');
   If SrcCur=0 Then S:=S+Tr('int'#130'gr'#130'es') Else S:=S+SrcTitle[SrcCur];
   S:=S+'  ('+IntStr(SrcCur+1)+'/'+IntStr(NSrc+1)+')   '+Tr('Page ')+
      IntStr(Pg+1)+'/'+IntStr(NPgs);
   PText(X0+14,Y0+TBH+6,S);
   For K:=1 To PerPg Do Begin
    CX:=X0+12+((K-1) Mod Cols)*96;
    CY:=Y0+TBH+20+((K-1) Div Cols)*96;
    Box(CX,CY,CX+90,CY+90,PAPER);
    Frame(CX,CY,CX+90,CY+90);
    If Cache[K].B<>Nil Then Begin
     SetViewPort(CX+1,CY+1,CX+89,CY+89,True);
     DW:=Cache[K].W;DH:=Cache[K].H;
     If (DW>84) Or (DH>64) Then Begin
      Fit:=Integer(Min2(84*100 Div DW,64*100 Div DH));
      DW:=DW*Fit Div 100;DH:=DH*Fit Div 100;
     End;
     DrawPieceP(Cache[K],0,0,Cache[K].W,Cache[K].H,False,False,
       (88-DW) Div 2,2+(66-DH) Div 2,DW,DH);
     SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
     S:=Copy(Cache[K].Name,1,11);
     If SrcCur=0 Then S:=Tr(S);
     PText(CX+(90-TextW(S)) Div 2,CY+78,S);
     If Pg*PerPg+K=Sel Then Begin
      SetWriteMode(XORPut);SetColor(PAPER);
      For YY:=CY+1 To CY+89 Do Line(CX+1,YY,CX+89,YY);
      SetWriteMode(NormalPut);
     End;
    End;
   End;
   Button(X0+W-190,Y0+H-34,X0+W-110,Y0+H-14,'OK',True,True);
   Button(X0+W-96,Y0+H-34,X0+W-16,Y0+H-14,'&Annuler',False,True);
   Button(X0+14,Y0+H-34,X0+104,Y0+H-14,'&Biblio.',False,NSrc>0);
   PText(X0+114,Y0+H-28,Tr('Tab : biblioth'#138'que'));
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ESC: Done:=True;
    K_ENTER: If SrcN>0 Then Begin
      SrcPiece(Sel,T);
      ArtPicker:=PoolAdd(T);
      FreePiece(T);
      Done:=True;
     End;
    K_LEFT: If Sel>1 Then Begin Dec(Sel);Redraw:=True;End;
    K_RIGHT: If Sel<SrcN Then Begin Inc(Sel);Redraw:=True;End;
    K_UP: If Sel>Cols Then Begin Sel:=Sel-Cols;Redraw:=True;End;
    K_DOWN: If Sel+Cols<=SrcN Then Begin Sel:=Sel+Cols;Redraw:=True;End;
    K_PGUP: Begin Sel:=Sel-PerPg;If Sel<1 Then Sel:=1;Redraw:=True;End;
    K_PGDN: Begin Sel:=Sel+PerPg;If Sel>SrcN Then Sel:=SrcN;Redraw:=True;End;
    K_HOME: Begin Sel:=1;Redraw:=True;End;
    K_END: Begin Sel:=SrcN;Redraw:=True;End;
    K_TAB: If NSrc>0 Then Begin
      SrcSelect((SrcCur+1) Mod (NSrc+1));
      Sel:=1;OldPg:=-1;Redraw:=True;
     End;
   End;
  End Else If E.Kind=2 Then Begin
   For K:=1 To PerPg Do Begin
    CX:=X0+12+((K-1) Mod Cols)*96;
    CY:=Y0+TBH+20+((K-1) Div Cols)*96;
    If InBox(E.X,E.Y,CX,CY,CX+90,CY+90) And (Pg*PerPg+K<=SrcN) Then Begin
     If Pg*PerPg+K=Sel Then Begin
      SrcPiece(Sel,T);ArtPicker:=PoolAdd(T);FreePiece(T);Done:=True;
     End Else Begin Sel:=Pg*PerPg+K;Redraw:=True;End;
    End;
   End;
   If InBox(E.X,E.Y,X0+W-190,Y0+H-34,X0+W-110,Y0+H-14) And (SrcN>0) Then Begin
    SrcPiece(Sel,T);ArtPicker:=PoolAdd(T);FreePiece(T);Done:=True;
   End;
   If InBox(E.X,E.Y,X0+W-96,Y0+H-34,X0+W-16,Y0+H-14) Then Done:=True;
   If InBox(E.X,E.Y,X0+14,Y0+H-34,X0+104,Y0+H-14) And (NSrc>0) Then Begin
    SrcSelect((SrcCur+1) Mod (NSrc+1));Sel:=1;OldPg:=-1;Redraw:=True;
   End;
   If InBox(E.X,E.Y,X0+3,Y0+3,X0+22,Y0+TBH) Then Done:=True;
  End;
 Until Done;
 For K:=1 To PerPg Do FreePiece(Cache[K]);
 NeedDraw:=True;
End;

Procedure CmdChooseArt;
Var L: Integer;
Begin
 L:=ArtPicker;
 If L<=0 Then Exit;
 FillChar(Held,SizeOf(Held),0);
 Held.Kind:=AR_ART;Held.Lib:=L;Held.Flow:=FL_BOTH;
 Held.W:=Lib[L].W*3 Div 2;Held.H:=Lib[L].H*3 Div 2;
 If Held.W>PGW-2 Then Held.W:=PGW-2;
 If Held.H>PGH-2 Then Held.H:=PGH-2;
 Held.SX1:=0;Held.SY1:=0;Held.SX2:=Lib[L].W;Held.SY2:=Lib[L].H;
 HeldOn:=True;
 If Mode<>MD_ART Then SetPanel(MD_ART);
 ArtSub:=0;
 NeedDraw:=True;
End;

{ Objet cible des operations : l'objet tenu, sinon l'objet selectionne }
Function TargetOk: Boolean;
Begin
 TargetOk:=HeldOn Or (SelArt>0);
End;

Procedure ArtSetFlow(Fl: Integer);
Begin
 If HeldOn Then Held.Flow:=Fl
 Else If SelArt>0 Then Begin PushUndoDoc(0);Arts[SelArt].Flow:=Fl;End
 Else Exit;
 Modified:=True;
 Relayout;
End;

Procedure ArtFlip(Horiz: Boolean);
Begin
 If HeldOn Then Begin
  If Horiz Then Held.FH:=1-Held.FH Else Held.FV:=1-Held.FV;
 End Else If SelArt>0 Then Begin
  PushUndoDoc(0);
  If Horiz Then Arts[SelArt].FH:=1-Arts[SelArt].FH Else
    Arts[SelArt].FV:=1-Arts[SelArt].FV;
 End Else Exit;
 Modified:=True;
 NeedDraw:=True;
End;

Procedure ArtResize(DW,DH: Integer);
Var A: TArt; NW,NH: Integer;
Begin
 If HeldOn Then A:=Held Else If SelArt>0 Then A:=Arts[SelArt] Else Exit;
 If Not HeldOn Then PushUndoDoc(1000+SelArt);
 If A.Kind=AR_ART Then Begin
  NW:=A.W+DW;
  If DW=0 Then NW:=A.W-DH;
  If NW<8 Then NW:=8;
  If NW>PGW-2 Then NW:=PGW-2;
  NH:=Integer(LongInt(A.H)*NW Div A.W);
  If NH>PGH-2 Then Exit;
  A.W:=NW;A.H:=NH;
 End Else Begin
  A.W:=A.W+DW;A.H:=A.H+DH;
  If A.W<2 Then A.W:=2;
  If A.H<2 Then A.H:=2;
 End;
 ClampArt(A);
 If HeldOn Then Held:=A Else Arts[SelArt]:=A;
 Modified:=True;
 If Not HeldOn Then Relayout;
 NeedDraw:=True;
End;

Procedure ArtResetSize;
Var A: TArt;
Begin
 If HeldOn Then A:=Held Else If SelArt>0 Then A:=Arts[SelArt] Else Exit;
 If Not HeldOn Then PushUndoDoc(0);
 If A.Kind=AR_ART Then Begin
  A.W:=(A.SX2-A.SX1)*3 Div 2;A.H:=(A.SY2-A.SY1)*3 Div 2;
 End;
 ClampArt(A);
 If HeldOn Then Held:=A Else Arts[SelArt]:=A;
 Modified:=True;
 If Not HeldOn Then Relayout;
 NeedDraw:=True;
End;

{ Rognage : D = pas en pixels source }
Procedure ArtCrop(DX,DY: Integer);
Var A: TArt; OW,OH,SW,SHh,NW,NH: Integer;
Begin
 If HeldOn Then A:=Held Else If SelArt>0 Then A:=Arts[SelArt] Else Exit;
 If A.Kind<>AR_ART Then Exit;
 If Not HeldOn Then PushUndoDoc(2000+SelArt);
 SW:=A.SX2-A.SX1;SHh:=A.SY2-A.SY1;
 OW:=A.W;OH:=A.H;
 If CropEnd=0 Then Begin
  If (DX>0) And (SW-DX<4) Then DX:=0;
  If (A.SX1+DX<0) Then DX:=-A.SX1;
  If (DY>0) And (SHh-DY<4) Then DY:=0;
  If (A.SY1+DY<0) Then DY:=-A.SY1;
  A.SX1:=A.SX1+DX;A.SY1:=A.SY1+DY;
 End Else Begin
  If (DX<0) And (SW+DX<4) Then DX:=0;
  If A.SX2+DX>Lib[A.Lib].W Then DX:=Lib[A.Lib].W-A.SX2;
  If (DY<0) And (SHh+DY<4) Then DY:=0;
  If A.SY2+DY>Lib[A.Lib].H Then DY:=Lib[A.Lib].H-A.SY2;
  A.SX2:=A.SX2+DX;A.SY2:=A.SY2+DY;
 End;
 NW:=Integer(LongInt(OW)*(A.SX2-A.SX1) Div SW);
 NH:=Integer(LongInt(OH)*(A.SY2-A.SY1) Div SHh);
 If CropEnd=0 Then Begin
  A.X:=A.X+(OW-NW);A.Y:=A.Y+(OH-NH);
 End;
 A.W:=NW;A.H:=NH;
 If NW<2 Then A.W:=2;
 If NH<2 Then A.H:=2;
 If HeldOn Then Held:=A Else Arts[SelArt]:=A;
 Modified:=True;
 If Not HeldOn Then Relayout;
 NeedDraw:=True;
End;

{ Redimensionnement par un coin : le coin oppose reste fixe. }
Procedure ResizeByCorner(Var A: TArt; Const O: TArt; C: Integer;
  PX,PY: LongInt);
Var FX,FY,NW,NH: LongInt; L,T: Boolean;
Begin
 A:=O;
 L:=(C And 1)=0;T:=(C And 2)=0;
 If L Then FX:=O.X+O.W Else FX:=O.X;
 If T Then FY:=O.Y+O.H Else FY:=O.Y;
 If O.Kind=AR_ART Then Begin
  { image : proportions conservees }
  NW:=Abs(PX-FX);
  If NW<8 Then NW:=8;
  If NW>PGW-2 Then NW:=PGW-2;
  NH:=NW*O.H Div O.W;
  If NH<4 Then NH:=4;
  If NH>PGH-2 Then Begin NH:=PGH-2;NW:=NH*O.W Div O.H;End;
  If L Then A.X:=Integer(FX-NW) Else A.X:=Integer(FX);
  If T Then A.Y:=Integer(FY-NH) Else A.Y:=Integer(FY);
  A.W:=Integer(NW);A.H:=Integer(NH);
 End Else Begin
  A.X:=Integer(Min2(PX,FX));A.Y:=Integer(Min2(PY,FY));
  A.W:=Integer(Abs(PX-FX));A.H:=Integer(Abs(PY-FY));
 End;
 ClampArt(A);
End;

{ Un axe du rognage. S1,S2 : zone source ; Lim : taille de l'image source ;
  Pos,Len : position et taille sur la page ; Low : c'est le bord bas (gauche
  ou haut) qui bouge ; Edge : nouvelle position du bord ; Rev : image
  retournee sur cet axe. }
Procedure CropAxis(Var S1,S2: Integer; Lim: Integer; Var Pos,Len: Integer;
  Low: Boolean; Edge: LongInt; Rev: Boolean);
Var O1,O2,OP,OL: LongInt; D,N,NL: LongInt; UseS1: Boolean;
Begin
 O1:=S1;O2:=S2;OP:=Pos;OL:=Len;
 If (O2-O1<1) Or (OL<1) Then Exit;
 { le bord deplace correspond a S1 ou S2 de la source }
 UseS1:=Low Xor Rev;
 If Low Then D:=Edge-OP Else D:=Edge-(OP+OL);
 If Low Then D:=D*(O2-O1) Div OL Else D:=D*(O2-O1) Div OL;
 If Rev Then D:=-D;
 If UseS1 Then Begin
  N:=O1+D;
  If N<0 Then N:=0;
  If N>O2-4 Then N:=O2-4;
  NL:=OL*(O2-N) Div (O2-O1);
  S1:=Integer(N);
 End Else Begin
  N:=O2+D;
  If N<O1+4 Then N:=O1+4;
  If N>Lim Then N:=Lim;
  NL:=OL*(N-O1) Div (O2-O1);
  S2:=Integer(N);
 End;
 If NL<2 Then NL:=2;
 Len:=Integer(NL);
 If Low Then Pos:=Integer(OP+OL-NL);
End;

Procedure CropByCorner(Var A: TArt; Const O: TArt; C: Integer;
  PX,PY: LongInt);
Begin
 A:=O;
 CropAxis(A.SX1,A.SX2,Lib[O.Lib].W,A.X,A.W,(C And 1)=0,PX,O.FH<>0);
 CropAxis(A.SY1,A.SY2,Lib[O.Lib].H,A.Y,A.H,(C And 2)=0,PY,O.FV<>0);
 ClampArt(A);
End;

Procedure ArtFinishDraw;
Var P1,P2: Integer; X1,Y1,X2,Y2: LongInt; A: TArt; I: Integer;
Begin
 DocToPage(DrawX0,DrawY0,P1,X1,Y1);
 DocToPage(ACx,ACy,P2,X2,Y2);
 DrawStep:=0;
 If P1<>P2 Then Begin SetStatus('M'#138'ME PAGE SVP');Exit;End;
 FillChar(A,SizeOf(A),0);
 A.Kind:=DrawKind;A.Pg:=P1;
 A.X:=Integer(Min2(X1,X2));A.Y:=Integer(Min2(Y1,Y2));
 A.W:=Integer(Abs(X2-X1));A.H:=Integer(Abs(Y2-Y1));
 If A.Kind=AR_LINE Then Begin
  If ((X2-X1)*(Y2-Y1))<0 Then A.FV:=1;
  If A.W<1 Then A.W:=1;
  If A.H<1 Then A.H:=1;
 End Else Begin
  If A.W<4 Then A.W:=4;
  If A.H<4 Then A.H:=4;
 End;
 A.Th:=DrawTh;A.Pat:=DrawPat;A.Flow:=FL_OVER;
 PushUndoDoc(0);
 I:=AddArt(A);
 If I>0 Then Begin Modified:=True;Relayout;SelArt:=I;End;
End;

Procedure CmdDrawTool;
Var R: Integer;
Begin
 R:=PopupAt(8+8*62,PANEL_Y-50,100,4,DrawKind-1);
 If R>0 Then Begin
  DrawKind:=R+1;
  If DrawKind=AR_LINE Then DrawPat:=0 Else DrawPat:=14;
  ArtSub:=3;DrawStep:=0;HeldOn:=False;
  SetStatus('ENTR'#144'E : POINT DE D'#144'PART');
 End;
End;

Procedure CmdPattern;
Var Sel,I,X0,Y0,W,H,CX,CY: Integer; E: TEvent; Done,Redraw: Boolean;
Begin
 Sel:=DrawPat;
 W:=6*50+24;H:=5*50+TBH+64;
 X0:=(SCR_W-W) Div 2;Y0:=(SCR_H-H) Div 2-6;
 Done:=False;Redraw:=True;
 Repeat
  If Redraw Then Begin
   HideMouse;
   DlgFrame(X0,Y0,W,H,'Motif de remplissage');
   For I:=0 To NPAT-1 Do Begin
    CX:=X0+12+(I Mod 6)*50;CY:=Y0+TBH+8+(I Div 6)*50;
    Box(CX,CY,CX+44,CY+44,PAPER);
    FillPat(I,CX+1,CY+1,CX+43,CY+43);
    If I=0 Then PText(CX+16,CY+18,'0');
    Frame(CX,CY,CX+44,CY+44);
    If I=Sel Then Begin Frame(CX-2,CY-2,CX+46,CY+46);Frame(CX-3,CY-3,CX+47,
      CY+47);End;
   End;
   Button(X0+W-190,Y0+H-34,X0+W-110,Y0+H-14,'OK',True,True);
   Button(X0+W-96,Y0+H-34,X0+W-16,Y0+H-14,'&Annuler',False,True);
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ESC: Done:=True;
    K_ENTER: Begin DrawPat:=Sel;Done:=True;End;
    K_LEFT: If Sel>0 Then Begin Dec(Sel);Redraw:=True;End;
    K_RIGHT: If Sel<NPAT-1 Then Begin Inc(Sel);Redraw:=True;End;
    K_UP: If Sel>=6 Then Begin Sel:=Sel-6;Redraw:=True;End;
    K_DOWN: If Sel+6<NPAT Then Begin Sel:=Sel+6;Redraw:=True;End;
   End;
  End Else If E.Kind=2 Then Begin
   For I:=0 To NPAT-1 Do Begin
    CX:=X0+12+(I Mod 6)*50;CY:=Y0+TBH+8+(I Div 6)*50;
    If InBox(E.X,E.Y,CX,CY,CX+44,CY+44) Then Begin
     If I=Sel Then Begin DrawPat:=Sel;Done:=True;End Else Begin Sel:=I;
       Redraw:=True;End;
    End;
   End;
   If InBox(E.X,E.Y,X0+W-190,Y0+H-34,X0+W-110,Y0+H-14) Then Begin DrawPat:=Sel;
     Done:=True;End;
   If InBox(E.X,E.Y,X0+W-96,Y0+H-34,X0+W-16,Y0+H-14) Then Done:=True;
  End;
 Until Done;
 If (SelArt>0) And (Arts[SelArt].Kind<>AR_ART) Then Begin
  PushUndoDoc(0);
  Arts[SelArt].Pat:=DrawPat;Modified:=True;
 End;
 NeedDraw:=True;
End;

Procedure CmdThickness;
Var S: String; V: LongInt;
Begin
 S:=IntStr(DrawTh);
 If InputBox(#144'paisseur','Epaisseur du trait (1-30) :',S,3) Then Begin
  V:=ValInt(S,DrawTh);
  If V<1 Then V:=1;
  If V>30 Then V:=30;
  DrawTh:=V;
  If (SelArt>0) And (Arts[SelArt].Kind<>AR_ART) Then Begin
   PushUndoDoc(0);
   Arts[SelArt].Th:=V;Modified:=True;
  End;
  NeedDraw:=True;
 End;
End;

{ Deplacement du curseur d'images }
Procedure ArtCursorMove(DX,DY: Integer);
Var MaxY: LongInt;
Begin
 ACx:=ACx+DX*ACStep;ACy:=ACy+DY*ACStep;
 If ACx<0 Then ACx:=0;
 If ACx>PGW-1 Then ACx:=PGW-1;
 If ACy<0 Then ACy:=0;
 MaxY:=LongInt(NPg)*(PGH+PGGAP)-PGGAP-1;
 If ACy>MaxY Then ACy:=MaxY;
 UpdateSelArt;
 ScrollToDoc(ACx,ACy);
 NeedDraw:=True;
End;

{ ====================================================================== }
{                       EDITION DE LA MISE EN PAGE                       }
{ ====================================================================== }

Procedure CmdAddCol;
Begin
 If NCol[CurPage]>=MAXCOL Then Begin
   SetStatus(Tr('MAXIMUM : ')+IntStr(MAXCOL)+Tr(' COLONNES'));Exit;End;
 PushUndoDoc(0);
 Inc(NCol[CurPage]);Modified:=True;Relayout;
End;

Procedure CmdDelCol;
Begin
 If NCol[CurPage]<=1 Then Begin SetStatus('UNE COLONNE MINIMUM');Exit;End;
 PushUndoDoc(0);
 Dec(NCol[CurPage]);Modified:=True;Relayout;
End;

Procedure CmdAddHead;
Begin
 If HasHead[CurPage] Then Begin SetStatus('TITRE D'#144'J'#133' PR'#144'SENT');
   Exit;End;
 PushUndoDoc(0);
 HasHead[CurPage]:=True;
 If St[CurPage].Len=0 Then StAppend(CurPage,Tr('Titre'),DefHead);
 St[CurPage].A^[St[CurPage].Len]:=AL_CENTER;
 Modified:=True;Relayout;
End;

Procedure CmdDelHead;
Begin
 If Not HasHead[CurPage] Then Exit;
 PushUndoDoc(0);
 HasHead[CurPage]:=False;
 If ASt=CurPage Then Begin ASt:=0;Cur:=0;SelA:=-1;End;
 Modified:=True;Relayout;
End;

{ ====================================================================== }
{                     OUTILS DE LECTURE / ECRITURE                       }
{ ====================================================================== }

Var
 OutF   : File;
 FileOk : Boolean;

Procedure WB(V: Integer);
Var B: Byte;
Begin
 B:=V And 255;
 {$I-}BlockWrite(OutF,B,1);{$I+}
 If IOResult<>0 Then FileOk:=False;
End;

Procedure WW(V: Integer);
Begin
 WB(V And 255);WB((V Shr 8) And 255);
End;

Function RB: Integer;
Var B: Byte;
Begin
 B:=0;
 {$I-}BlockRead(OutF,B,1);{$I+}
 If IOResult<>0 Then FileOk:=False;
 RB:=B;
End;

Function RW: Integer;
Var V: LongInt;
Begin
 V:=RB;
 V:=V+LongInt(RB)*256;
 If V>32767 Then V:=V-65536;
 RW:=Integer(V);
End;

{ ====================================================================== }
{          FICHIERS D'ORIGINE DE NEWS MASTER (.NWS)                      }
{ ====================================================================== }
{ Structure (mots de 16 bits, petit-boutiste) :                          }
{  0, N images, [nom, 0, larg, haut, taille, bitmap]*N,                   }
{  4 (pages), 0, 1, 4 blocs de page, tableau final (5,0,N,N,M,...),       }
{  puis M paires (caractere, attribut) : attribut = police (6 bits)      }
{  + justification (2 bits). Les N premiers caracteres forment le texte   }
{  principal, les M-N suivants le texte du titre.                         }

Const
 OrigName : Array[0..33] Of String[14] = ('Park 10','Park 10 bold',
   'Park 10 italic','Park 12','Park 12 bold','Park 12 italic','Park 24',
   'Park 24 italic','News 10','News 10 italic','News 12','News 12 bold',
   'News 12 italic','News 18','News 18 bold','News 18 italic','News 24',
   'News 24 bold','hampton','office','scribe','script','twig','cafe',
   'glyphs 10','glyphs 12','glyphs 18','glyphs 24','smallcap','News 60',
   'News 24 italic','Park  8','paris','bremen');
 OrigHt   : Array[0..33] Of Byte = (10,10,10,13,13,13,24,24,11,11,13,13,13,
   18,18,18,24,24,24,27,41,45,41,25,8,13,18,24,5,60,24,8,42,15);

Var
 NB    : PBytes;
 NBSz  : LongInt;

Procedure ResetDoc; Forward;

Function NW(O: LongInt): LongInt;
Begin
 If (O<0) Or (O+1>=NBSz) Then NW:=0
 Else NW:=NB^[O]+LongInt(NB^[O+1])*256;
End;

{ police d'origine (0..33) -> police courante }
Function MapOrigFont(F: Integer): Integer;
Begin
 If (F<0) Or (F>33) Then F:=0;
 If UseFLB And (NFont>=34) And (FName[F]=OrigName[F]) Then MapOrigFont:=F
 Else MapOrigFont:=NearestFont(OrigName[F],OrigHt[F]);
End;

{ police courante -> police d'origine }
Function ToOrigFont(F: Integer): Integer;
Var I,Best,BS,Sc_,Ht: Integer; Bold,Ital: Boolean; N: String;
Begin
 If UseFLB And (F<34) And (NFont>=34) And (FName[F]=OrigName[F]) Then Begin
  ToOrigFont:=F;Exit;
 End;
 N:=FName[F];Ht:=FontHt(F);
 Bold:=(Pos('bold',N)>0) Or (Pos('gras',N)>0);
 Ital:=(Pos('ital',N)>0);
 Best:=0;BS:=9999;
 For I:=0 To 33 Do Begin
  If (I>=24) And (I<=28) Then Continue;
  Sc_:=Abs(OrigHt[I]-Ht)*4;
  If Bold<>(Pos('bold',OrigName[I])>0) Then Sc_:=Sc_+3;
  If Ital<>(Pos('italic',OrigName[I])>0) Then Sc_:=Sc_+3;
  If Sc_<BS Then Begin BS:=Sc_;Best:=I;End;
 End;
 ToOrigFont:=Best;
End;

Procedure AppendCh(S: Integer; C,Fn,Al: Byte);
Begin
 If St[S].Len>=St[S].Cap Then Exit;
 St[S].T^[St[S].Len]:=C;St[S].F^[St[S].Len]:=Fn;
 If C=13 Then St[S].A^[St[S].Len]:=Al Else St[S].A^[St[S].Len]:=0;
 Inc(St[S].Len);
 St[S].T^[St[S].Len]:=13;St[S].F^[St[S].Len]:=Fn;St[S].A^[St[S].Len]:=AL_LEFT;
End;

{ Segment d'un tableau de paires (caractere, attribut) -> histoire S.
  Un CR final (fin de paragraphe) est represente par le CR implicite. }
Procedure PairsToStory(S: Integer; Base,Cnt: LongInt; Var FMapO: Array Of Byte);
Var I: LongInt; C,At: Byte; L: Integer;
Begin
 StClear(S,DefBody,AL_LEFT);
 For I:=0 To Cnt-1 Do Begin
  C:=NB^[Base+2*I];At:=NB^[Base+2*I+1];
  If C=10 Then C:=13;
  If (C>=32) Or (C=13) Then AppendCh(S,C,FMapO[At And 63],At Shr 6);
 End;
 L:=St[S].Len;
 If (S<>0) And (L>0) Then
  If St[S].T^[L-1]=13 Then Dec(St[S].Len);
End;

Procedure AddObj(Kind: Byte; Th,Pt: Integer; RX1,RY1,RX2,RY2: LongInt; Pg:
  Integer);
Var A: TArt;
Begin
 FillChar(A,SizeOf(A),0);
 A.Kind:=Kind;A.Pg:=Pg;A.Th:=Byte(Th);A.Pat:=Byte(Pt);A.Flow:=FL_OVER;
 A.X:=Integer(Min2(RX1,RX2));A.Y:=Integer(Min2(RY1,RY2));
 A.W:=Integer(Abs(RX2-RX1));A.H:=Integer(Abs(RY2-RY1));
 If (Kind=AR_LINE) And (((RX2-RX1)*(RY2-RY1))<0) Then A.FV:=1;
 AddArt(A);
End;

Function LoadNWS(Const Name: String): Boolean;
Var F: File; Fs,O,T,Q,Qc,Qr,Nx,N,M,L,Sz,Bpr,HS,HE: LongInt;
    NPics,NPF,I,K,J,Ix,Aux,Nc,NcR,Np,N1,N2: Integer;
    PIdx: Array[1..MAXLIB] Of Integer; Pc: TPiece; Ok: Boolean;
    X1,Y1,X2,Y2,RX1,RY1,RX2,RY2,Fw,Fh,Pw,Ph: LongInt; A: TArt;
    FMapO: Array[0..63] Of Byte; HF: Array[1..8] Of Integer;
Begin
 LoadNWS:=False;
 {$I-}
 Assign(F,Name);Reset(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 Fs:=FileSize(F);
 If (Fs<30) Or (Fs>64000) Then Begin Close(F);Exit;End;
 GetMem(NB,Fs);NBSz:=Fs;
 {$I-}BlockRead(F,NB^,Fs);{$I+}
 Close(F);
 Ok:=False;
 Repeat
  If (NW(0)<>0) Or (NW(2)>MAXLIB) Then Break;
  NPics:=Integer(NW(2));
  { tableau final : (5,0,N,N,M1,M1,...) puis M paires }
  T:=-1;O:=4;
  Q:=4;
  While Q<=Fs-30 Do Begin
   If (NW(Q)=5) And (NW(Q+2)=0) And (NW(Q+4)=NW(Q+6)) And
      (NW(Q+8)=NW(Q+10)) And (Fs-(Q+26)=2*NW(Q+24)) And
      (NW(Q+24)>=NW(Q+4)) Then T:=Q;
   Q:=Q+1;
  End;
  If T<0 Then Break;
  N:=NW(T+4);M:=NW(T+24);
  ResetDoc;
  FillChar(PIdx,SizeOf(PIdx),0);
  For I:=1 To NPics Do Begin
   L:=NW(O);
   If (L>60) Or (O+2+L+8>Fs) Then Break;
   If L>16 Then Pc.Name[0]:=#16 Else Pc.Name[0]:=Chr(L);
   For K:=1 To Length(Pc.Name) Do Pc.Name[K]:=Chr(NB^[O+1+K]);
   O:=O+2+L;
   Pw:=NW(O+2);Ph:=NW(O+4);Sz:=NW(O+6);O:=O+8;
   If (Ph<1) Or (Pw<1) Or (Sz<1) Or (O+Sz>Fs) Or (Sz>12000) Then Break;
   Bpr:=Sz Div Ph;
   If (Bpr*Ph<>Sz) Or (Bpr<1) Then Bpr:=(Pw+7) Shr 3;
   If Bpr*Ph>Sz Then Break;
   Pc.W:=Integer(Pw);Pc.H:=Integer(Ph);
   If ((Pc.W+7) Shr 3)<>Bpr Then Pc.W:=Integer(Bpr*8);
   GetMem(Pc.B,Bpr*Ph);
   Move(NB^[O],Pc.B^,Bpr*Ph);
   PIdx[I]:=PoolAdd(Pc);
   FreePiece(Pc);
   O:=O+Sz;
  End;
  NPF:=Integer(NW(O));
  If (NPF<1) Or (NPF>8) Then Break;
  O:=O+6;
  For I:=0 To 63 Do FMapO[I]:=Byte(MapOrigFont(I));
  If N>STCAP Then N:=STCAP;
  If M<N Then M:=N;
  PairsToStory(0,T+26,N,FMapO);
  St[0].A^[St[0].Len]:=AL_LEFT;
  For K:=1 To MAXPG Do Begin HasHead[K]:=False;StClear(K,DefHead,AL_CENTER);End;
  { pages }
  Q:=O;
  For K:=1 To NPF Do Begin
   If (NW(Q)<>2) Or (Q>=T) Then Break;
   If K>MAXPG Then Break;
   HF[K]:=Integer(NW(Q+4));
   HasHead[K]:=HF[K]<>0;
   HS:=NW(Q+10);HE:=NW(Q+12);
   If (HE>HS) And (HE<=M) And (HE-HS<=HCAP) Then
    PairsToStory(K,T+26+2*HS,HE-HS,FMapO);
   NcR:=Integer(NW(Q+36));
   If (NcR<1) Or (NcR>6) Then Break;
   Nc:=NcR;If Nc>MAXCOL Then Nc:=MAXCOL;
   NCol[K]:=Nc;
   Qc:=Q+40+(NcR-1)*8+6;
   Np:=Integer(NW(Qc));Qr:=Qc+2;
   If (Np<0) Or (Np>MAXART) Then Break;
   For J:=1 To Np Do Begin
    Ix:=Integer(NW(Qr+2));Aux:=Integer(NW(Qr+6));
    X1:=NW(Qr+8);Y1:=NW(Qr+10);X2:=NW(Qr+12);Y2:=NW(Qr+14);
    RX1:=NW(Qr+16);RY1:=NW(Qr+18);RX2:=NW(Qr+20);RY2:=NW(Qr+22);
    Qr:=Qr+24;
    If (Ix>=0) And (Ix<NPics) And (PIdx[Ix+1]>0) And (X2>X1) And (Y2>Y1) Then
    Begin
     FillChar(A,SizeOf(A),0);
     A.Kind:=AR_ART;A.Lib:=PIdx[Ix+1];A.Pg:=K;
     A.X:=Integer(X1);A.Y:=Integer(Y1);
     A.W:=Integer(X2-X1);A.H:=Integer(Y2-Y1);
     Pw:=Lib[A.Lib].W;Ph:=Lib[A.Lib].H;
     A.SX1:=0;A.SY1:=0;A.SX2:=Integer(Pw);A.SY2:=Integer(Ph);
     Fw:=RX2-RX1;Fh:=RY2-RY1;
     If (Fw>0) And (Fh>0) And ((RX1<>X1) Or (RX2<>X2) Or (RY1<>Y1) Or
        (RY2<>Y2)) Then Begin
      A.SX1:=Integer(Clamp((X1-RX1)*Pw Div Fw,0,Pw-1));
      A.SX2:=Integer(Clamp((X2-RX1)*Pw Div Fw,A.SX1+1,Pw));
      A.SY1:=Integer(Clamp((Y1-RY1)*Ph Div Fh,0,Ph-1));
      A.SY2:=Integer(Clamp((Y2-RY1)*Ph Div Fh,A.SY1+1,Ph));
     End;
     { mot 3 : habillage du texte (0 aucun, 1 gauche, 2 droite, 3 les deux) ;
       mot 4 : retournements (2 horizontal, 4 vertical) }
     Case Integer(NW(Qr-24+4)) And 3 Of
      0: A.Flow:=FL_CLEAR;
      1: A.Flow:=FL_LEFT;
      2: A.Flow:=FL_RIGHT;
     Else A.Flow:=FL_BOTH;
     End;
     If (Aux And 2)<>0 Then A.FH:=1;
     If (Aux And 4)<>0 Then A.FV:=1;
     AddArt(A);
    End;
   End;
   { lignes puis boites : [type][epaisseur][motif][0][R1][R2] }
   N1:=Integer(NW(Qr));Qr:=Qr+2;
   If (N1<0) Or (N1>40) Then Break;
   For J:=1 To N1 Do Begin
    AddObj(AR_LINE,Integer(NW(Qr+2)),Integer(NW(Qr+4)),NW(Qr+16),NW(Qr+18),
       NW(Qr+20),NW(Qr+22),K);
    Qr:=Qr+24;
   End;
   N2:=Integer(NW(Qr));Qr:=Qr+2;
   If (N2<0) Or (N2>40) Then Break;
   For J:=1 To N2 Do Begin
    AddObj(AR_BOX,Integer(NW(Qr+2)),Integer(NW(Qr+4)),NW(Qr+8),NW(Qr+10),
       NW(Qr+12),NW(Qr+14),K);
    Qr:=Qr+24;
   End;
   Q:=Qr;
  End;
  NPg:=MAXPG;
  If NCol[1]=0 Then NCol[1]:=2;
  For K:=2 To MAXPG Do If (NCol[K]<1) Or (NCol[K]>MAXCOL) Then NCol[K]:=NCol[1];
  Ok:=True;
 Until True;
 FreeMem(NB,NBSz);NB:=Nil;
 LoadNWS:=Ok;
End;

Procedure WriteObj(Kind,Th,Pt: Integer; X1,Y1,X2,Y2,T2: LongInt);
Var EX,EY: LongInt;
Begin
 WW(Kind);WW(Th);WW(Pt);WW(0);
 If Kind=1 Then Begin
  EX:=0;EY:=0;
  If Y1=Y2 Then EY:=T2;
  If X1=X2 Then EX:=T2;
  If (Y1<>Y2) And (X1<>X2) Then Begin EX:=T2;EY:=T2;End;
  WW(Integer(Min2(X1,X2)-EX Div 2));WW(Integer(Min2(Y1,Y2)-EY Div 2));
  WW(Integer(Max2(X1,X2)-EX Div 2+EX));WW(Integer(Max2(Y1,Y2)-EY Div 2+EY));
  WW(Integer(X1));WW(Integer(Y1));WW(Integer(X2));WW(Integer(Y2));
 End Else Begin
  WW(Integer(X1));WW(Integer(Y1));WW(Integer(X2));WW(Integer(Y2));
  WW(Integer(X1));WW(Integer(Y1));WW(Integer(X2));WW(Integer(Y2));
 End;
End;

Function SaveNWS(Const Name: String): Boolean;
Var Used: Array[1..MAXLIB] Of Integer; PicOf: Array[1..MAXLIB] Of Integer;
    NU,I,K,P,PE,Nn,Mt,Bpr,Ent,Y,Ctop,Np,NL,NB_: Integer; S: String;
    PStart,PEnd,HS,HE: Array[0..8] Of Integer; Al,At: Byte;
    Fw,Fh,X1,Y1,X2,Y2,RX1,RY1,RX2,RY2,Pw,Ph: LongInt;
Begin
 SaveNWS:=False;
 FileOk:=True;
 {$I-}
 Assign(OutF,Name);Rewrite(OutF,1);
 {$I+}
 If IOResult<>0 Then Exit;
 FillChar(Used,SizeOf(Used),0);NU:=0;
 For I:=1 To NArt Do
  If (Arts[I].Kind=AR_ART) And (Arts[I].Lib>=1) And (Arts[I].Lib<=NLib) Then
   If Used[Arts[I].Lib]=0 Then Begin
    Inc(NU);Used[Arts[I].Lib]:=NU;PicOf[NU]:=Arts[I].Lib;
   End;
 WW(0);WW(NU);
 For I:=1 To NU Do Begin
  S:=Lib[PicOf[I]].Name;
  WW(Length(S));BlockWrite(OutF,S[1],Length(S));
  Bpr:=(Lib[PicOf[I]].W+7) Shr 3;
  WW(0);WW(Lib[PicOf[I]].W);WW(Lib[PicOf[I]].H);WW(Bpr*Lib[PicOf[I]].H);
  BlockWrite(OutF,Lib[PicOf[I]].B^,Bpr*Lib[PicOf[I]].H);
 End;
 Nn:=St[0].Len;
 { segments de titre : un par page, a la suite du texte principal }
 Mt:=Nn;
 For P:=1 To 4 Do Begin
  HS[P]:=Mt;
  If St[P].Len>0 Then Mt:=Mt+St[P].Len+1;
  HE[P]:=Mt;
 End;
 { plages de texte par page }
 For P:=1 To 4 Do Begin PStart[P]:=-1;PEnd[P]:=-1;End;
 For P:=1 To 4 Do Begin
  For I:=0 To NLn-1 Do
   If (Lines^[I].Sty=0) And (Lines^[I].Pg=P) Then Begin
    If PStart[P]<0 Then PStart[P]:=Lines^[I].S;
    PEnd[P]:=Lines^[I].Nx;
    If PEnd[P]>Nn Then PEnd[P]:=Nn;
   End;
 End;
 PEnd[0]:=0;
 For P:=1 To 4 Do Begin
  If PStart[P]<0 Then Begin PStart[P]:=PEnd[P-1];PEnd[P]:=PEnd[P-1];End;
  If P=1 Then PStart[P]:=0;
  If PEnd[P]<PStart[P] Then PEnd[P]:=PStart[P];
 End;
 WW(4);WW(0);WW(1);
 For P:=1 To 4 Do Begin
  WW(2);WW(0);
  WW(Ord(HasHead[P]));
  WW(P);WW(0);
  WW(HS[P]);WW(HE[P]);
  WW(1);WW(0);WW(0);WW(PGW);WW(HEADH);WW(1);WW(1);WW(0);WW(0);
  WW(PStart[P]);WW(PEnd[P]);
  Ent:=NCol[P];
  WW(Ent);WW(0);
  If HasHead[P] Then Ctop:=167 Else Ctop:=0;
  For K:=1 To Ent-1 Do Begin
   Y:=Integer((LongInt(PGW-30*(Ent-1)) Div Ent)*K+30*(K-1));
   WW(Ctop);WW(Y);WW(PGH);WW(Y+30);
  End;
  WW(Ctop);WW(PGW);WW(PGH);
  Np:=0;NL:=0;NB_:=0;
  For I:=1 To NArt Do If Arts[I].Pg=P Then Begin
   If (Arts[I].Kind=AR_ART) And (Used[Arts[I].Lib]>0) Then Inc(Np);
   If Arts[I].Kind=AR_LINE Then Inc(NL);
   If Arts[I].Kind=AR_BOX Then Inc(NB_);
  End;
  WW(Np);
  For I:=1 To NArt Do
   If (Arts[I].Pg=P) And (Arts[I].Kind=AR_ART) And (Used[Arts[I].Lib]>0) Then
   Begin
    WW(0);WW(Used[Arts[I].Lib]-1);
    Case Arts[I].Flow Of
     FL_CLEAR: WW(0);
     FL_LEFT: WW(1);
     FL_RIGHT: WW(2);
    Else WW(3);
    End;
    WW(Arts[I].FH*2+Arts[I].FV*4);
    X1:=Arts[I].X;Y1:=Arts[I].Y;X2:=X1+Arts[I].W;Y2:=Y1+Arts[I].H;
    RX1:=X1;RY1:=Y1;RX2:=X2;RY2:=Y2;
    Pw:=Lib[Arts[I].Lib].W;Ph:=Lib[Arts[I].Lib].H;
    If (Arts[I].SX2>Arts[I].SX1) And (Arts[I].SY2>Arts[I].SY1) Then Begin
     Fw:=LongInt(Arts[I].W)*Pw Div (Arts[I].SX2-Arts[I].SX1);
     Fh:=LongInt(Arts[I].H)*Ph Div (Arts[I].SY2-Arts[I].SY1);
     RX1:=X1-LongInt(Arts[I].SX1)*Fw Div Pw;RX2:=RX1+Fw;
     RY1:=Y1-LongInt(Arts[I].SY1)*Fh Div Ph;RY2:=RY1+Fh;
    End;
    WW(Integer(X1));WW(Integer(Y1));WW(Integer(X2));WW(Integer(Y2));
    WW(Integer(RX1));WW(Integer(RY1));WW(Integer(RX2));WW(Integer(RY2));
   End;
  WW(NL);
  For I:=1 To NArt Do
   If (Arts[I].Pg=P) And (Arts[I].Kind=AR_LINE) Then Begin
    X1:=Arts[I].X;X2:=X1+Arts[I].W;
    If Arts[I].FV=0 Then Begin Y1:=Arts[I].Y;Y2:=Y1+Arts[I].H;End
    Else Begin Y2:=Arts[I].Y;Y1:=Y2+Arts[I].H;End;
    WriteObj(1,Arts[I].Th,Arts[I].Pat,X1,Y1,X2,Y2,(Arts[I].Th+1) Div 2);
   End;
  WW(NB_);
  For I:=1 To NArt Do
   If (Arts[I].Pg=P) And (Arts[I].Kind=AR_BOX) Then
    WriteObj(2,Arts[I].Th,Arts[I].Pat,Arts[I].X,Arts[I].Y,
      Arts[I].X+Arts[I].W,Arts[I].Y+Arts[I].H,0);
 End;
 { tableau final }
 WW(5);WW(0);WW(Nn);WW(Nn);
 For I:=1 To 7 Do WW(Mt);
 WW(ToOrigFont(CurFont));WW(Mt);
 { texte principal puis un titre par page }
 For K:=0 To 4 Do Begin
  P:=K;
  If (K=0) Or (St[P].Len>0) Then Begin
   I:=0;
   While I<=St[P].Len Do Begin
    PE:=ParaEndPos(P,I);
    Al:=St[P].A^[PE];
    While I<PE Do Begin
     At:=Byte((ToOrigFont(St[P].F^[I]) And 63) Or (Al Shl 6));
     WB(St[P].T^[I]);WB(At);
     Inc(I);
    End;
    If (PE<St[P].Len) Or (K>0) Then Begin
     At:=Byte((ToOrigFont(St[P].F^[PE]) And 63) Or (Al Shl 6));
     WB(10);WB(At);
    End;
    I:=PE+1;
   End;
  End;
 End;
 {$I-}Close(OutF);{$I+}
 If IOResult<>0 Then FileOk:=False;
 SaveNWS:=FileOk;
End;

{ ---- importation / exportation ASCII ---- }

Function ImportASCII(Const Name: String): Boolean;
Var F: File; Buf: Array[0..2047] Of Byte; Got: Word; I,NL: Integer; C: Byte;
    PrevCR,Full: Boolean; LastC: Byte;
Begin
 ImportASCII:=False;
 {$I-}
 Assign(F,Name);Reset(F,1);
 {$I+}
 If IOResult<>0 Then Exit;
 PushUndo;
 If SelA>=0 Then DelSel;
 NL:=0;PrevCR:=False;Full:=False;LastC:=13;
 If Cur>0 Then LastC:=St[ASt].T^[Cur-1];
 Repeat
  Got:=0;
  {$I-}BlockRead(F,Buf,SizeOf(Buf),Got);{$I+}
  If IOResult<>0 Then Got:=0;
  For I:=0 To Got-1 Do Begin
   C:=Buf[I];
   If C=13 Then Begin Inc(NL);PrevCR:=True;End
   Else If C=10 Then Begin
    If Not PrevCR Then Inc(NL);
    PrevCR:=False;
   End Else Begin
    PrevCR:=False;
    If C=9 Then C:=32;
    If C>=32 Then Begin
     If Not Full Then Begin
      If NL>=2 Then Begin
       If StIns(ASt,Cur,13,CurFont,AL_LEFT) Then Inc(Cur) Else Full:=True;
       LastC:=13;
      End Else If (NL=1) And (LastC<>32) And (LastC<>13) Then Begin
       If StIns(ASt,Cur,32,CurFont,0) Then Inc(Cur) Else Full:=True;
       LastC:=32;
      End;
      NL:=0;
      If Not ((C=32) And ((LastC=32) Or (LastC=13))) Then Begin
       If StIns(ASt,Cur,C,CurFont,0) Then Inc(Cur) Else Full:=True;
       LastC:=C;
      End;
     End;
    End;
   End;
  End;
 Until Got=0;
 Close(F);
 AfterEdit;
 If Full Then SetStatus('TEXTE TRONQU'#144);
 ImportASCII:=True;
End;

Function ExportASCII(Const Name: String): Boolean;
Var T: Text; P,I: Integer;
Begin
 ExportASCII:=False;
 {$I-}
 Assign(T,Name);Rewrite(T);
 {$I+}
 If IOResult<>0 Then Exit;
 For P:=1 To NPg Do
  If HasHead[P] And (St[P].Len>0) Then Begin
   For I:=0 To St[P].Len-1 Do
    If St[P].T^[I]=13 Then WriteLn(T) Else Write(T,Chr(St[P].T^[I]));
   WriteLn(T);WriteLn(T);
  End;
 For I:=0 To St[0].Len-1 Do
  If St[0].T^[I]=13 Then WriteLn(T) Else Write(T,Chr(St[0].T^[I]));
 WriteLn(T);
 Close(T);
 ExportASCII:=IOResult=0;
End;

{ ---- selecteur de fichier ---- }
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

Function FilePicker(Const Title,Mask: String; Var Name: String; Save: Boolean):
  Boolean;
{ boite de fichiers de PM (pmfile.inc) }
Begin
 FilePicker:=PmFileDlg(Tr(Title),Mask,Name,Save);
 NeedDraw:=True;
End;

{ ====================================================================== }
{                  IMPRESSION : EXPORT D'UNE PAGE EN PBM                 }
{ ====================================================================== }

{ Dessine la bande de page P commencant a BandY (VH rangees au plus) en
  bitmap monochrome : BPR octets par rangee, bit a 1 = encre.        }
Procedure RenderBand(P,BandY,R,BPR: Integer; Buf: PBytes);
Var TX,X,Y,I: Integer; X0,Y0: LongInt;
Begin
 FillChar(Buf^,BPR*VH,0);
 For TX:=0 To 1 Do Begin
  SetViewPort(0,0,VW-1,VH-1,True);
  SetFillStyle(SolidFill,PAPER);LastFill:=-1;
  Bar(0,0,VW-1,VH-1);
  X0:=-TX*VW;Y0:=-BandY;
  DrawLinesOfPage(P,X0,Y0);
  For I:=1 To NArt Do
   If Arts[I].Pg=P Then DrawArtItem(I,X0,Y0,False);
  For Y:=0 To R-1 Do
   For X:=0 To VW-1 Do
    If TX*VW+X<PGW Then
     If GetPixel(X,Y)=INK Then
      Buf^[Y*BPR+((TX*VW+X) Shr 3)]:=Buf^[Y*BPR+((TX*VW+X) Shr 3)] Or ($80 Shr
        ((TX*VW+X) And 7));
 End;
End;

Function ExportPagePBM(P: Integer; Const FN: String): Boolean;
Var F: File; Hdr: String; BandY,R,BPR: Integer; Buf: PBytes;
    SvN,SvD: Integer;
Begin
 ExportPagePBM:=False;
 BPR:=(PGW+7) Div 8;
 GetMem(Buf,BPR*VH);
 {$I-}
 Assign(F,FN);Rewrite(F,1);
 {$I+}
 If IOResult<>0 Then Begin FreeMem(Buf,BPR*VH);Exit;End;
 Hdr:='P4'#10+IntStr(PGW)+' '+IntStr(PGH)+#10;
 BlockWrite(F,Hdr[1],Length(Hdr));
 SvN:=ZN;SvD:=ZD;ZN:=1;ZD:=1;
 BandY:=0;
 While BandY<PGH Do Begin
  R:=VH;
  If BandY+R>PGH Then R:=PGH-BandY;
  RenderBand(P,BandY,R,BPR,Buf);
  BlockWrite(F,Buf^,BPR*R);
  BandY:=BandY+VH;
 End;
 Close(F);
 ZN:=SvN;ZD:=SvD;
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 FreeMem(Buf,BPR*VH);
 ExportPagePBM:=IOResult=0;
End;

{$IFDEF WINPRINT}
{ ---------------------------------------------------------------------- }
{ Impression sous Windows : les fonctions de l'API sont declarees ici     }
{ (gdi32 et winspool) pour ne pas ajouter d'unite au programme.          }
{ ---------------------------------------------------------------------- }
Type
 TWDocInfo = Record
  cbSize: LongInt;
  lpszDocName,lpszOutput,lpszDatatype: PChar;
  fwType: LongInt;
 End;
 TWBmpInfo = Record
  biSize: LongInt;
  biWidth,biHeight: LongInt;
  biPlanes,biBitCount: Word;
  biCompression,biSizeImage: LongInt;
  biXPels,biYPels: LongInt;
  biClrUsed,biClrImportant: LongInt;
  Pal: Array[0..1] Of LongInt;
 End;
 TBigBytes = Array[0..4194303] Of Byte;
 PBigBytes = ^TBigBytes;

Function WGetDefaultPrinter(Buf: PChar; Var Sz: LongInt): LongInt;
 stdcall; external 'winspool.drv' name 'GetDefaultPrinterA';
Function WCreateDC(Drv,Dev,Port: PChar; Mode: Pointer): PtrUInt;
 stdcall; external 'gdi32' name 'CreateDCA';
Function WDeleteDC(Dc: PtrUInt): LongInt;
 stdcall; external 'gdi32' name 'DeleteDC';
Function WGetDeviceCaps(Dc: PtrUInt; Idx: LongInt): LongInt;
 stdcall; external 'gdi32' name 'GetDeviceCaps';
Function WStartDoc(Dc: PtrUInt; Var DI: TWDocInfo): LongInt;
 stdcall; external 'gdi32' name 'StartDocA';
Function WEndDoc(Dc: PtrUInt): LongInt;
 stdcall; external 'gdi32' name 'EndDoc';
Function WAbortDoc(Dc: PtrUInt): LongInt;
 stdcall; external 'gdi32' name 'AbortDoc';
Function WStartPage(Dc: PtrUInt): LongInt;
 stdcall; external 'gdi32' name 'StartPage';
Function WEndPage(Dc: PtrUInt): LongInt;
 stdcall; external 'gdi32' name 'EndPage';
Function WStretchDIBits(Dc: PtrUInt; XD,YD,WD,HD,XS,YS,WS,HS: LongInt;
 Bits: Pointer; Var BI: TWBmpInfo; Usage,Rop: LongInt): LongInt;
 stdcall; external 'gdi32' name 'StretchDIBits';

{ Dessine la page P entiere dans Pg (PGW x PGH, 120 octets par rangee). }
Procedure RenderWholePage(P: Integer; Pg: PBigBytes);
Var BandY,R,BPR: Integer; Buf: PBytes; SvN,SvD: Integer; O: LongInt;
Begin
 BPR:=(PGW+7) Div 8;
 GetMem(Buf,BPR*VH);
 SvN:=ZN;SvD:=ZD;ZN:=1;ZD:=1;
 BandY:=0;
 While BandY<PGH Do Begin
  R:=VH;
  If BandY+R>PGH Then R:=PGH-BandY;
  RenderBand(P,BandY,R,BPR,Buf);
  O:=BandY;O:=O*BPR;
  Move(Buf^,Pg^[O],BPR*R);
  BandY:=BandY+VH;
 End;
 ZN:=SvN;ZD:=SvD;
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 FreeMem(Buf,BPR*VH);
End;

{ Envoie les pages P1..P2 a l'imprimante par defaut de Windows.
  Retour : 0 = imprime, 1 = aucune imprimante, 2 = erreur.         }
Function PrintPagesWin(P1,P2: Integer; Var PName: String): Integer;
Var Sz: LongInt; Nm: Array[0..259] Of Char; Dn: Array[0..15] Of Char;
    Dc: PtrUInt; DI: TWDocInfo; BI: TWBmpInfo; Pg,Rot,Out: PBigBytes;
    PgSz,I,X,Y,PBPR,W,H,RBPR,HR,VR,S,DW,DH,DX,DY: LongInt; P: Integer;
    Turn,Ok: Boolean; Title: String;
Begin
 PrintPagesWin:=1;
 Sz:=260;
 If WGetDefaultPrinter(@Nm,Sz)=0 Then Exit;
 If Nm[0]=#0 Then Exit;
 PName:='';
 I:=0;
 While (I<260) And (Nm[I]<>#0) Do Begin PName:=PName+Nm[I];Inc(I);End;
 Dc:=WCreateDC('WINSPOOL',@Nm,Nil,Nil);
 If Dc=0 Then Begin PrintPagesWin:=2;Exit;End;
 HR:=WGetDeviceCaps(Dc,8);      { HORZRES }
 VR:=WGetDeviceCaps(Dc,10);     { VERTRES }
 Turn:=VR>HR;                   { imprimante portrait : page tournee }
 PBPR:=(PGW+7) Div 8;
 PgSz:=PBPR*PGH;
 GetMem(Pg,PgSz);GetMem(Rot,PgSz+64);
 If Turn Then Begin W:=PGH;H:=PGW;End Else Begin W:=PGW;H:=PGH;End;
 RBPR:=((W+31) Shr 5) Shl 2;
 FillChar(DI,SizeOf(DI),0);
 DI.cbSize:=SizeOf(DI);
 Title:='NEWSMASTER';
 For I:=1 To Length(Title) Do Dn[I-1]:=Title[I];
 Dn[Length(Title)]:=#0;
 DI.lpszDocName:=@Dn;
 FillChar(BI,SizeOf(BI),0);
 BI.biSize:=40;BI.biWidth:=W;BI.biHeight:=-H;
 BI.biPlanes:=1;BI.biBitCount:=1;BI.biClrUsed:=2;
 BI.Pal[0]:=$00FFFFFF;          { bit a 0 : blanc }
 BI.Pal[1]:=0;                  { bit a 1 : noir (encre) }
 { echelle entiere si possible, sinon ajustement a la page }
 S:=HR Div W;
 If (VR Div H)<S Then S:=VR Div H;
 If S>=1 Then Begin DW:=W*S;DH:=H*S;End
 Else If W*VR>H*HR Then Begin
  DW:=HR;DH:=(H*HR) Div W;
 End Else Begin
  DH:=VR;DW:=(W*VR) Div H;
 End;
 DX:=(HR-DW) Div 2;DY:=(VR-DH) Div 2;
 Ok:=WStartDoc(Dc,DI)>0;
 P:=P1;
 While Ok And (P<=P2) Do Begin
  RenderWholePage(P,Pg);
  Out:=Pg;
  If Turn Then Begin
   FillChar(Rot^,PgSz+64,0);
   For Y:=0 To PGH-1 Do
    For X:=0 To PGW-1 Do
     If (Pg^[Y*PBPR+(X Shr 3)] And ($80 Shr (X And 7)))<>0 Then Begin
      { rotation de 90 degres : (X,Y) -> (PGH-1-Y,X) }
      I:=X*RBPR+((PGH-1-Y) Shr 3);
      Rot^[I]:=Rot^[I] Or ($80 Shr ((PGH-1-Y) And 7));
     End;
   Out:=Rot;
  End;
  If WStartPage(Dc)<=0 Then Ok:=False
  Else Begin
   If WStretchDIBits(Dc,DX,DY,DW,DH,0,0,W,H,Out,BI,0,$00CC0020)=0 Then
    Ok:=False;
   If WEndPage(Dc)<=0 Then Ok:=False;
  End;
  Inc(P);
 End;
 If Ok Then WEndDoc(Dc) Else WAbortDoc(Dc);
 WDeleteDC(Dc);
 FreeMem(Pg,PgSz);FreeMem(Rot,PgSz+64);
 If Ok Then PrintPagesWin:=0 Else PrintPagesWin:=2;
End;
{$ENDIF}

Procedure CmdPrint(All: Boolean);
Var P1,P2,P: Integer; Base,FN: String; Ok: Boolean;
    {$IFDEF WINPRINT}PName: String;{$ENDIF}
Begin
 If DocName<>'' Then Base:=NoExt(ShortName(DocName)) Else Base:='NEWS';
 If All Then Begin P1:=1;P2:=NPg;End Else Begin P1:=CurPage;P2:=CurPage;End;
 {$IFDEF WINPRINT}
 HideMouse;
 Box(160,200,480,250,PAPER);Frame(160,200,480,250);Frame(162,202,478,248);
 BText(180,220,Tr('Envoi '#133' l''imprimante ...'));
 ShowMouse;
 Case PrintPagesWin(P1,P2,PName) Of
  0: Begin
      NeedDraw:=True;
      MsgBox('Impression',Tr('Imprim'#130' sur : ')+PName+'|'+
        Tr('Page(s) : ')+IntStr(P1)+' - '+IntStr(P2));
      Exit;
     End;
  2: Begin
      NeedDraw:=True;
      MsgBox('Impression','Erreur d''impression Windows.');
      Exit;
     End;
 End;
 { aucune imprimante par defaut : repli sur l'export PBM }
 {$ENDIF}
 Ok:=True;
 For P:=P1 To P2 Do Begin
  FN:=Copy(Base,1,6)+Chr(48+P Div 10)+Chr(48+P Mod 10)+'.PBM';
  HideMouse;
  Box(160,200,480,250,PAPER);Frame(160,200,480,250);Frame(162,202,478,248);
  BText(180,220,Tr('Impression de la page ')+IntStr(P)+' ...');
  ShowMouse;
  If Not ExportPagePBM(P,FN) Then Ok:=False;
 End;
 NeedDraw:=True;
 If Ok Then Begin
  If P1=P2 Then MsgBox('Impression',
    Tr('Page ')+IntStr(P1)+Tr(' enregistr'#130'e dans ')+Copy(Base,1,
    6)+Chr(48+P1 Div 10)+Chr(48+P1 Mod 10)+'.PBM')
  Else MsgBox('Impression',Tr('Pages enregistr'#130'es : ')+Copy(Base,1,
    6)+'01.PBM ...|'+Tr('Format : bitmap PBM ')+IntStr(PGW)+' x '+IntStr(PGH))
 End Else MsgBox('Impression','Erreur d'''#130'criture du fichier.');
End;

{ ====================================================================== }
{                       COMMANDES DE DOCUMENT                            }
{ ====================================================================== }

Procedure ResetDoc;
Var P: Integer;
Begin
 FreePool;
 NPg:=MAXPG;
 For P:=1 To MAXPG Do Begin NCol[P]:=2;HasHead[P]:=True;End;
 For P:=0 To MAXPG Do StClear(P,DefHead,AL_CENTER);
 StClear(0,DefBody,AL_LEFT);
 NArt:=0;SelArt:=0;HeldOn:=False;ArtSub:=0;DrawStep:=0;
 DocName:='';Named:=False;Modified:=False;
 ASt:=0;Cur:=0;SelA:=-1;MarkMode:=False;CurFont:=DefBody;TypRun:=False;
 UndoOK:=False;CurPage:=1;ScrX:=0;ScrY:=0;WantX:=-1;
 ACx:=MRG+20;ACy:=MRG+HEADH+30;
 Relayout;
End;

Function FontOr(Const Nm: String; Def: Integer): Integer;
Var F: Integer;
Begin
 F:=FontByName(Nm);
 If F<0 Then F:=Def;
 FontOr:=F;
End;

Procedure MakeDemo;
Var FB,FH,FT: Integer; A: TArt;
Begin
 ResetDoc;
 If UseFLB Then Begin
  FH:=FontOr('News 24 bold',DefHead);
  FT:=FontOr('Park 12 bold',DefBody);
  FB:=FontOr('Park 12',DefBody);
 End Else Begin
  FH:=FontOr('Titre 32',DefHead);
  FT:=FontOr('Systeme 16 gras',DefBody);
  FB:=FontOr('Systeme 8',DefBody);
 End;
 StClear(1,FH,AL_CENTER);
 StAppend(1,Tr('CRAZY JOE''S FISH SHACK'),FH);
 StAppend(0,
   Tr('Attrapez nos portions de taille BALEINE '#133' prix de sardine !')+#13,
   FT);
 St[0].A^[St[0].Len-1]:=AL_CENTER;
 StAppend(0,#13,FB);
 StAppend(0,Tr('Sp'#130'cial du jour')+#13,FT);
 StAppend(0,
   Tr('Flet frit : 5,25 $. Notre cuisinier, un ancien marin au grand coeur, '),
   FB);
 StAppend(0,Tr('pr'#130'pare chaque matin le poisson le plus frais du port. '),
   FB);
 StAppend(0,
   Tr('Servi avec des frites maison, une salade croquante et la fameuse sauce '+
   'secr'#138'te de la maison.')+#13,FB);
 StAppend(0,#13,FB);
 StAppend(0,
   Tr('Chaudr'#130'e de palourdes : 3,95 $. Une soupe onctueuse '#133' la '+
   'cr'#138'me, '),FB);
 StAppend(0,
   Tr('garnie de palourdes, de pommes de terre et de lard fum'#130'. '+
   'Id'#130'ale '),FB);
 StAppend(0,
   Tr('pour r'#130'chauffer les journ'#130'es d''hiver sur le quai.')+#13,FB);
 StAppend(0,#13,FB);
 StAppend(0,Tr('Plateau de fruits de mer : 7,99 $. '),FB);
 StAppend(0,
   Tr('Crevettes, p'#130'tonles, calmars et moules, accompagn'#130's de '+
   'citron et de beurre fondu. '),FB);
 StAppend(0,
   Tr('Le plateau est servi sur glace pour garder toute la fra'#139'cheur de '+
   'la mer. '),FB);
 StAppend(0,Tr('Venez nombreux, la maison offre le caf'#130' !')+#13,FB);
 St[0].A^[St[0].Len]:=AL_LEFT;
 FillChar(A,SizeOf(A),0);
 A.Kind:=AR_ART;A.Lib:=PoolAdd(BLib[1]);A.Pg:=1;A.Flow:=FL_BOTH;
 A.X:=PGW Div 2-48;A.Y:=MRG+HEADH+24;A.W:=96;A.H:=96;
 A.SX1:=0;A.SY1:=0;A.SX2:=Lib[A.Lib].W;A.SY2:=Lib[A.Lib].H;
 AddArt(A);
 A.Lib:=PoolAdd(BLib[2]);A.X:=PGW-MRG-90;A.Y:=PGH-MRG-130;A.W:=90;A.H:=68;
 A.SX1:=0;A.SY1:=0;A.SX2:=Lib[A.Lib].W;A.SY2:=Lib[A.Lib].H;A.Flow:=FL_BOTH;
 AddArt(A);
 Modified:=False;
 Relayout;
End;

Function ConfirmLose: Boolean;
Begin
 If Not Modified Then ConfirmLose:=True
 Else ConfirmLose:=ConfirmBox('Les changements non enregistr'#130's seront '+
   'perdus. Continuer ?');
End;

Procedure CmdNew;
Begin
 If Not ConfirmLose Then Exit;
 ResetDoc;
 SetPanel(MD_MAIN);
 SetView(2);
End;

Procedure CmdOpen;
Var N: String;
Begin
 If Not ConfirmLose Then Exit;
 N:='';
 If Not FilePicker('Ouvrir un journal','*.NWS',N,False) Then Exit;
 If Not FileExists(N) Then N:=AddExt(N,'NWS');
 If Not FileExists(N) Then Begin MsgBox('Ouvrir',
   Tr('Fichier introuvable : ')+N);Exit;End;
 If LoadNWS(N) Then Begin
  DocName:=N;Named:=True;Modified:=False;
  ASt:=0;Cur:=0;SelA:=-1;SelArt:=0;HeldOn:=False;UndoOK:=False;CurPage:=1;
    ScrX:=0;ScrY:=0;
  CurFont:=St[0].F^[0];
  Relayout;
  SetView(ViewNo);
  SetStatus('JOURNAL CHARG'#144);
 End Else Begin
  MsgBox('Ouvrir','Ce fichier n''est pas un journal NewsMaster valide.');
  ResetDoc;
 End;
End;

Procedure CmdSaveAs;
Var N: String;
Begin
 N:=DocName;
 If Not FilePicker('Enregistrer le journal','*.NWS',N,True) Then Exit;
 N:=AddExt(N,'NWS');
 If FileExists(N) Then
  If Not ConfirmBox(Tr('Le fichier ')+ShortName(N)+Tr(' existe. Le remplacer '+
    '?')) Then Exit;
 If SaveNWS(N) Then Begin
  DocName:=N;Named:=True;Modified:=False;
  SetStatus('JOURNAL ENREGISTR'#144);
 End Else MsgBox('Enregistrer','Erreur d'''#130'criture du fichier.');
End;

Procedure CmdSave;
Begin
 If Not Named Then Begin CmdSaveAs;Exit;End;
 If SaveNWS(DocName) Then Begin
  Modified:=False;SetStatus('JOURNAL ENREGISTR'#144);
 End Else MsgBox('Enregistrer','Erreur d'''#130'criture du fichier.');
End;

Procedure CmdImport;
Var N: String;
Begin
 N:='';
 If Not FilePicker('Importer du texte ASCII','*.TXT',N,False) Then Exit;
 If Not FileExists(N) Then N:=AddExt(N,'TXT');
 If Not FileExists(N) Then Begin MsgBox('Importer',
   Tr('Fichier introuvable : ')+N);Exit;End;
 If Mode<>MD_TEXT Then SetPanel(MD_TEXT);
 If Not ImportASCII(N) Then MsgBox('Importer',Tr('Impossible de lire ')+N);
End;

Procedure CmdExport;
Var N: String;
Begin
 N:='NEWS.TXT';
 If Not FilePicker('Exporter le texte ASCII','*.TXT',N,True) Then Exit;
 N:=AddExt(N,'TXT');
 If ExportASCII(N) Then SetStatus('TEXTE EXPORT'#144) Else
   MsgBox('Exporter','Erreur d'''#130'criture du fichier.');
End;

Procedure CmdQuit;
Begin
 If Modified Then Begin
  If ConfirmBox('Quitter NewsMaster ? Les changements seront perdus.') Then
    Quit:=True;
 End Else If ConfirmBox('Quitter NewsMaster ?') Then Quit:=True;
 NeedDraw:=True;
End;

Procedure CmdGoto;
Var S: String; V: LongInt;
Begin
 S:=IntStr(CurPage);
 If InputBox(#133' la page','Num'#130'ro de page :',S,3) Then Begin
  V:=ValInt(S,CurPage);
  GotoPage(Integer(V));
 End;
End;

Procedure CmdAbout;
Begin
 MsgBox(#192' propos de NewsMaster',
   Tr('NewsMaster - Clone Pascal')+'|'+Tr('Programme de publication de '+
   'journaux')+'|Version '+VERSION_TEXT+' - OFFICE-0|'+Tr('Inspir'#130' de '+
   'News Master (Unison World, 1986)')+'|https://www.gladir.com/office-0');
End;

Procedure CmdStats;
Var I,Tx,Ar: LongInt; S: String;
Begin
 Tx:=St[0].Len;
 Ar:=NArt;
 S:=Tr('Pages : ')+IntStr(NPg)+'|'+Tr('Texte principal : ')+IntStr(Tx)+Tr(' '+
   'caract'#138'res')+'|';
 S:=S+Tr('Images et traits : ')+IntStr(Ar)+'|'+Tr('Polices disponibles '+
   ': ')+IntStr(NFont);
 If UseFLB Then S:=S+' (NEWS.FLB)' Else S:=S+Tr(' (int'#130'gr'#130'es)');
 If Overflow Then
   S:=S+'|'+Tr('ATTENTION : du texte d'#130'passe la mise en page');
 MsgBox('Statistiques',S);
End;

{ Informations sur le journal et sur l'objet / la police courante }
Procedure CmdInfo;
Var S,K: String;
Begin
 If DocName<>'' Then S:=DocName Else S:=Tr('(sans nom)');
 If Modified Then S:=S+' *';
 S:=Tr('Journal : ')+S+'|'+Tr('Page courante : ')+IntStr(CurPage)+'/'+
   IntStr(NPg)+'|'+Tr('Colonnes : ')+IntStr(NCol[CurPage]);
 If HasHead[CurPage] Then S:=S+Tr(', avec titre');
 S:=S+'|'+Tr('Vue : ')+ViewName+'|'+Tr('Police : ')+FName[CurFont]+' ('+
   IntStr(FAsc[CurFont]+FDsc[CurFont])+' pts)';
 S:=S+'|'+Tr('Curseur de texte : ')+IntStr(Cur)+'/'+IntStr(St[ASt].Len);
 If (SelArt>0) And (SelArt<=NArt) Then Begin
  Case Arts[SelArt].Kind Of
   AR_ART: K:=Tr('Image');
   AR_LINE: K:=Tr('Ligne');
  Else K:=Tr('Bo'#140'te');
  End;
  S:=S+'|'+Tr('Objet s'#130'lectionn'#130' : ')+K+'|  '+Tr('page ')+
    IntStr(Arts[SelArt].Pg)+' : '+IntStr(Arts[SelArt].X)+','+
    IntStr(Arts[SelArt].Y)+'|  '+Tr('Taille : ')+IntStr(Arts[SelArt].W)+
    ' x '+IntStr(Arts[SelArt].H);
 End Else S:=S+'|'+Tr('Aucun objet s'#130'lectionn'#130);
 MsgBox('Informations',S);
End;

Procedure CmdFreeMem;
Begin
 {$IFDEF FPC}
 MsgBox('M'#130'moire','M'#130'moire g'#130'r'#130'e par Free Pascal.');
 {$ELSE}
 MsgBox('M'#130'moire',Tr('Plus grand bloc libre : ')+IntStr(MaxAvail Div
   1024)+' Ko|'+Tr('M'#130'moire libre : ')+IntStr(MemAvail Div 1024)+' Ko');
 {$ENDIF}
End;

{ Change la source des polices (NEWS.FLB ou polices integrees) }
Procedure SwitchFonts(NewFLB: Boolean);
Var OldN,I,S,K: Integer; OldName: Array[0..MAXFONT-1] Of String[26];
    OldHt: Array[0..MAXFONT-1] Of Integer; Map: Array[0..MAXFONT-1] Of Byte;
Begin
 OldN:=NFont;
 For I:=0 To OldN-1 Do Begin OldName[I]:=FName[I];OldHt[I]:=FontHt(I);End;
 UseFLB:=NewFLB;
 BuildFontTable;
 For I:=0 To OldN-1 Do Map[I]:=NearestFont(OldName[I],OldHt[I]);
 For S:=0 To MAXPG Do
  For K:=0 To St[S].Len Do
   If St[S].F^[K]<OldN Then St[S].F^[K]:=Map[St[S].F^[K]] Else
     St[S].F^[K]:=DefBody;
 For K:=0 To ClipN-1 Do
  If ClipF^[K]<OldN Then ClipF^[K]:=Map[ClipF^[K]] Else ClipF^[K]:=DefBody;
 If CurFont<OldN Then CurFont:=Map[CurFont] Else CurFont:=DefBody;
 UndoOK:=False;
 Relayout;
End;

{ ====================================================================== }
{                        COMMANDES DU PANNEAU                            }
{ ====================================================================== }

Procedure MainMenuLoop; Forward;

Procedure PanelKey(N: Integer);
Begin
 If (N<1) Or (N>NPB) Then Exit;
 Case Mode Of
  MD_MAIN: Case N Of
    1: SetPanel(MD_VIEW);
    2: Begin SetPanel(MD_TEXT);Moved;End;
    3: Begin SetPanel(MD_ART);UpdateSelArt;End;
    4: Begin SetPanel(MD_LAYOUT);End;
    5: SetPanel(MD_FILE);
    6: SetPanel(MD_PRINT);
   End;
  MD_VIEW: Case N Of
    1..4: SetView(N);
    5: GotoPage(CurPage-1);
    6: GotoPage(CurPage+1);
   End;
  MD_TEXT: Case N Of
    1: CmdFont;
    2: CmdAlignPopup;
    3: ToggleMark;
    4: ClipCut;
    5: ClipCopy;
    6: ClipPaste;
    7: CmdImport;
    8: DoUndo;
   End;
  MD_ART: Case N Of
    1: CmdChooseArt;
    2: PickUp(False);
    3: PickUp(True);
    4: StampHeld;
    5: If TargetOk Then Begin
        If ArtSub=1 Then ArtSub:=0 Else ArtSub:=1;
        NeedDraw:=True;
       End;
    6: If TargetOk Then Begin
        If ArtSub=2 Then ArtSub:=0 Else ArtSub:=2;
        NeedDraw:=True;
       End;
    7: If TargetOk Then Begin
        If HeldOn Then N:=PopupAt(8+6*62,PANEL_Y-80,190,2,Held.Flow+1)
        Else N:=PopupAt(8+6*62,PANEL_Y-80,190,2,Arts[SelArt].Flow+1);
        If N>0 Then ArtSetFlow(N-1);
       End;
    8: If TargetOk Then Begin
        N:=PopupAt(8+7*62,PANEL_Y-50,150,5,1);
        If N>0 Then ArtFlip(N=1);
       End;
    9: CmdDrawTool;
    10: If SelArt>0 Then DelArt(SelArt) Else If HeldOn Then Begin HeldOn:=False;
      NeedDraw:=True;End;
   End;
  MD_LAYOUT: Case N Of
    1: CmdAddCol;
    2: CmdDelCol;
    3: CmdAddHead;
    4: CmdDelHead;
   End;
  MD_FILE: Case N Of
    1: CmdNew;
    2: CmdOpen;
    3: CmdSave;
    4: CmdSaveAs;
    5: MainMenuLoop;
    6: CmdQuit;
   End;
  MD_PRINT: Case N Of
    1: CmdPrint(False);
    2: CmdPrint(True);
    3: CmdExport;
   End;
 End;
 NeedDraw:=True;
End;

Procedure DoMenu(M,I: Integer);
Var A,B: Integer;
Begin
 Case M Of
  1: Case I Of
      1: CmdAbout;
      3: CmdStats;
      4: CmdFreeMem;
     End;
  2: Case I Of
      1: MainMenuLoop;
      2: CmdNew;
      3: CmdOpen;
      4: CmdSave;
      5: CmdSaveAs;
      7: CmdImport;
      8: CmdExport;
      10: CmdPrint(False);
      11: CmdPrint(True);
      13: CmdQuit;
     End;
  3: Case I Of
      1: DoUndo;
      3: ClipCut;
      4: ClipCopy;
      5: ClipPaste;
      6: If SelRange(A,B) Then Begin PushUndo;DelSel;AfterEdit;End;
      7: Begin If Mode<>MD_TEXT Then SetPanel(MD_TEXT);SelectAll;End;
      9: CmdFind;
      10: FindNextText;
     End;
  4: Case I Of
      1: Begin If Mode<>MD_TEXT Then SetPanel(MD_TEXT);CmdFont;End;
      2: CmdFontStep(-1);
      3: CmdFontStep(1);
      5..8: SetAlign(I-5);
      10: Begin If Mode<>MD_TEXT Then SetPanel(MD_TEXT);ToggleMark;End;
      11: Begin SetPanel(MD_TEXT);Moved;End;
     End;
  5: Case I Of
      1: Begin SetPanel(MD_ART);UpdateSelArt;End;
      3: CmdChooseArt;
      4: PickUp(False);
      5: PickUp(True);
      6: StampHeld;
      7: If SelArt>0 Then DelArt(SelArt);
      9..13: ArtSetFlow(I-9);
      15: ArtResize(ACStep,ACStep);
      16: ArtResize(-ACStep,-ACStep);
      17: ArtResetSize;
      18: ArtFlip(True);
      19: ArtFlip(False);
      21: Begin DrawKind:=AR_LINE;DrawPat:=0;ArtSub:=3;DrawStep:=0;
        HeldOn:=False;
           If Mode<>MD_ART Then SetPanel(MD_ART);NeedDraw:=True;End;
      22: Begin DrawKind:=AR_BOX;DrawPat:=14;ArtSub:=3;DrawStep:=0;
        HeldOn:=False;
           If Mode<>MD_ART Then SetPanel(MD_ART);NeedDraw:=True;End;
      23: CmdPattern;
      24: CmdThickness;
     End;
  6: Case I Of
      1: SetPanel(MD_LAYOUT);
      3: CmdAddCol;
      4: CmdDelCol;
      5: CmdAddHead;
      6: CmdDelHead;
      8: GotoPage(CurPage-1);
      9: GotoPage(CurPage+1);
      10: CmdGoto;
     End;
  7: Case I Of
      1..4: SetView(I);
      6: ACStep:=16;
      7: ACStep:=4;
      8: ACStep:=1;
     End;
  8: Case I Of
      1: If FLBFound Then SwitchFonts(Not UseFLB);
      2: GuidesOn:=Not GuidesOn;
      3: CmdInfo;
     End;
 End;
 NeedDraw:=True;
End;

{ ====================================================================== }
{                          AFFICHAGE GLOBAL                              }
{ ====================================================================== }

Procedure DrawAll;
Begin
 NeedDraw:=False;
 HideMouse;
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 SetLineStyle(SolidLn,0,1);
 LastFill:=-1;
 If Mode=MD_LAYOUT Then DrawLayoutScreen
 Else Begin
  DrawViewArea;
  DrawPanel;
 End;
 DrawMenuBar;
 If MenuOpen>0 Then DrawDropDown;
 ShowMouse;
End;

{ ====================================================================== }
{                        ECRANS D'ACCUEIL                                }
{ ====================================================================== }

Procedure CenterTextF(F,Y,X1,X2: Integer; Const S: String);
Begin
 DrawStrF(F,(X1+X2-StrWidthF(F,S)) Div 2,Y,S);
End;

Procedure ShowSplash;
Var F,FB,Y,I,W,X1,X2,Y2,LH,PW: Integer; E: TEvent; T0: LongInt; Ln: Array[1..4]
  Of String;
    Pr: String;
Begin
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 PatBar(0,0,SCR_W-1,SCR_H-1,PatStripe);
 If UseFLB Then Begin F:=FontOr('Park 12 bold',DefBody);
   FB:=FontOr('News 18 bold',DefHead);End
 Else Begin F:=FontOr('Systeme 16 gras',DefBody);FB:=FontOr('Titre 32',DefHead);
   End;
 Ln[1]:=Tr('NEWSMASTER - CLONE VERSION ')+VERSION_TEXT;
 Ln[2]:=Tr('PROGRAMME DE PUBLICATION DE JOURNAUX');
 Ln[3]:=Tr('D''APRES NEWS MASTER (UNISON WORLD, 1986)');
 Ln[4]:=Tr('OFFICE-0 - WWW.GLADIR.COM');
 { la boite s'adapte a la largeur du texte le plus long }
 W:=StrWidthF(FB,'NEWSMASTER');
 For I:=1 To 4 Do If StrWidthF(F,Ln[I])>W Then W:=StrWidthF(F,Ln[I]);
 W:=W+80;
 If W<360 Then W:=360;
 If W>SCR_W-16 Then W:=SCR_W-16;
 X1:=(SCR_W-W) Div 2;X2:=X1+W;
 LH:=FAsc[F]+FDsc[F]+6;
 Y:=108+FAsc[FB]+FDsc[FB]+14;
 Y2:=Y+4*LH+16;
 Box(X1+5,90+5,X2+5,Y2+5,INK);
 Box(X1,90,X2,Y2,PAPER);
 Frame(X1,90,X2,Y2);Frame(X1+4,94,X2-4,Y2-4);
 CenterTextF(FB,108,X1,X2,'NEWSMASTER');
 For I:=1 To 4 Do Begin
  CenterTextF(F,Y,X1,X2,Ln[I]);
  Y:=Y+LH;
 End;
 Pr:=Tr('APPUYEZ SUR ESPACE POUR CONTINUER');
 PW:=TextW(Pr)+60;
 LabelBox((SCR_W-PW) Div 2,Y2+40,(SCR_W+PW) Div 2,Y2+64,Pr);
 T0:=Tick;
 Repeat
  PollEvent(E);
 Until ((E.Kind=1)) Or (E.Kind=2) Or (Abs(Tick-T0)>1500);
End;

Procedure MainMenuLoop;
Var R,I: Integer; Done: Boolean;
Begin
 Done:=False;
 Repeat
  HideMouse;
  SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
  PatBar(0,MENU_H,SCR_W-1,SCR_H-1,PatStripe);
  ShowMouse;
  DlgInit(96,380,TBH+170,'NewsMaster : Menu principal');
  CLabel(20,TBH+14,'Choisissez une activit'#130' :');
  For I:=1 To 4 Do
   CButton(I,20,TBH+36+(I-1)*30,340,24,IntStr(I)+'. '+Tr(ListMain(I)),I=2,True);
  R:=RunDialog;
  Case R Of
   1: If ConfirmLose Then Begin ResetDoc;Done:=True;End;
   2: Done:=True;
   3: Begin CmdOpen;If Named Then Done:=True;End;
   4: Begin CmdQuit;If Quit Then Done:=True;End;
  End;
 Until Done Or Quit;
 SetPanel(MD_MAIN);
 SetView(ViewNo);
 NeedDraw:=True;
End;

{ ====================================================================== }
{                              CLAVIER                                   }
{ ====================================================================== }

Function AltLetter(K: Word): Integer;
Const
 RowQ : String[10] = 'QWERTYUIOP';
 RowA : String[9] = 'ASDFGHJKL';
 RowZ : String[7] = 'ZXCVBNM';
Var Sc_: Integer;
Begin
 AltLetter:=-1;
 If K<256 Then Exit;
 Sc_:=K-256;
 Case Sc_ Of
  16..25: AltLetter:=Ord(RowQ[Sc_-15])-65;
  30..38: AltLetter:=Ord(RowA[Sc_-29])-65;
  44..50: AltLetter:=Ord(RowZ[Sc_-43])-65;
 End;
End;

Procedure MenuByLetter(L: Integer);
Var M: Integer;
Begin
 M:=0;
 Case Chr(L+65) Of
  'N': M:=1;
  'F': M:=2;
  'E': M:=3;
  'T': M:=4;
  'I': M:=5;
  'P': M:=6;
  'V': M:=7;
  'O': M:=8;
 End;
 If M>0 Then RunMenu(M,False);
End;

Procedure ScrollKeys(K: Word);
Begin
 Case K Of
  K_UP: ScrollBy(0,-24);
  K_DOWN: ScrollBy(0,24);
  K_LEFT: ScrollBy(-24,0);
  K_RIGHT: ScrollBy(24,0);
  K_PGUP: ScrollBy(0,-(VH-30));
  K_PGDN: ScrollBy(0,VH-30);
  K_HOME: Begin ScrX:=0;ScrY:=0;ClampScroll;NeedDraw:=True;End;
  K_END: Begin ScrY:=DocHpx;ClampScroll;NeedDraw:=True;End;
 End;
End;

Procedure TextKey(K: Word);
Var I,N: Integer;
Begin
 Case K Of
  K_ENTER: TypeChar(13);
  K_TAB: Begin TypeChar(32);TypeChar(32);TypeChar(32);TypeChar(32);End;
  K_BKSP: DoBackspace;
  K_DEL: DoDelete;
  K_LEFT: MoveTo(Cur-1);
  K_RIGHT: MoveTo(Cur+1);
  K_UP: CurUpDown(-1);
  K_DOWN: CurUpDown(1);
  K_HOME: CurLineEdge(True);
  K_END: CurLineEdge(False);
  K_CHOME: MoveTo(0);
  K_CEND: MoveTo(St[ASt].Len);
  K_PGUP: For I:=1 To 12 Do CurUpDown(-1);
  K_PGDN: For I:=1 To 12 Do CurUpDown(1);
  32..255: TypeChar(K);
 End;
 N:=0;
End;

Procedure ArtKey(K: Word);
Begin
 Case ArtSub Of
  1: Case K Of
      K_RIGHT: ArtResize(ACStep,0);
      K_LEFT: ArtResize(-ACStep,0);
      K_UP: ArtResize(0,-ACStep);
      K_DOWN: ArtResize(0,ACStep);
      43: ArtResize(ACStep,ACStep);
      45: ArtResize(-ACStep,-ACStep);
      K_HOME: ArtResetSize;
      K_ENTER,K_ESC: Begin ArtSub:=0;NeedDraw:=True;End;
     End;
  2: Case K Of
      K_RIGHT: ArtCrop(1,0);
      K_LEFT: ArtCrop(-1,0);
      K_UP: ArtCrop(0,-1);
      K_DOWN: ArtCrop(0,1);
      K_TAB: Begin CropEnd:=1-CropEnd;NeedDraw:=True;End;
      K_ENTER,K_ESC: Begin ArtSub:=0;NeedDraw:=True;End;
     End;
 Else
  Case K Of
   K_LEFT: ArtCursorMove(-1,0);
   K_RIGHT: ArtCursorMove(1,0);
   K_UP: ArtCursorMove(0,-1);
   K_DOWN: ArtCursorMove(0,1);
   K_PGUP: ArtCursorMove(0,-(VH Div ACStep));
   K_PGDN: ArtCursorMove(0,VH Div ACStep);
   K_ENTER: Begin
     If ArtSub=3 Then Begin
      If DrawStep=0 Then Begin
       DrawStep:=1;DrawX0:=ACx;DrawY0:=ACy;
       SetStatus('ENTR'#144'E : POINT FINAL');
      End Else Begin ArtFinishDraw;SetStatus('OBJET AJOUT'#144);End;
     End Else If HeldOn Then StampHeld
     Else If SelArt>0 Then PickUp(False);
     NeedDraw:=True;
    End;
   K_DEL: If SelArt>0 Then DelArt(SelArt);
   K_TAB: Begin CropEnd:=1-CropEnd;End;
   43: ArtResize(ACStep,ACStep);
   45: ArtResize(-ACStep,-ACStep);
  End;
 End;
End;

Procedure HandleKey(K: Word);
Var L: Integer;
Begin
 If K>=256 Then Begin
  L:=AltLetter(K);
  If L>=0 Then Exit;
 End;
 If (K>=K_F1) And (K<=K_F1+9) Then Begin PanelKey(K-K_F1+1);Exit;End;
 { raccourcis control }
 Case K Of
  14: Begin CmdNew;Exit;End;
  15: Begin CmdOpen;Exit;End;
  17: Begin CmdQuit;Exit;End;
  19: Begin CmdSave;Exit;End;
  26: Begin DoUndo;Exit;End;
  6: Begin CmdFind;Exit;End;
  7: Begin FindNextText;Exit;End;
  20: Begin If Mode<>MD_TEXT Then SetPanel(MD_TEXT);CmdFont;Exit;End;
 End;
 If Mode=MD_TEXT Then Begin
  Case K Of
   1: Begin SelectAll;Exit;End;
   3: Begin ClipCopy;Exit;End;
   24: Begin ClipCut;Exit;End;
   22: Begin ClipPaste;Exit;End;
   12: Begin SetAlign(AL_LEFT);Exit;End;
   18: Begin SetAlign(AL_RIGHT);Exit;End;
   5: Begin SetAlign(AL_CENTER);Exit;End;
   10: Begin SetAlign(AL_BOTH);Exit;End;
   K_ESC: Begin
     If (SelA>=0) Or MarkMode Then Begin SelA:=-1;MarkMode:=False;
       NeedDraw:=True;End
     Else SetPanel(MD_MAIN);
     Exit;
    End;
  End;
  TextKey(K);
  Exit;
 End;
 If K=K_ESC Then Begin
  If Mode=MD_ART Then Begin
   If ArtSub<>0 Then Begin ArtSub:=0;DrawStep:=0;NeedDraw:=True;End
   Else If HeldOn Then Begin HeldOn:=False;NeedDraw:=True;End
   Else SetPanel(MD_MAIN);
  End Else If Mode<>MD_MAIN Then SetPanel(MD_MAIN);
  Exit;
 End;
 Case Mode Of
  MD_ART: ArtKey(K);
  MD_LAYOUT: Case K Of
     K_PGUP,K_UP,K_LEFT: Begin If CurPage>1 Then Dec(CurPage);NeedDraw:=True;
       End;
     K_PGDN,K_DOWN,K_RIGHT: Begin If CurPage<NPg Then Inc(CurPage);
       NeedDraw:=True;End;
    End;
 Else ScrollKeys(K);
 End;
End;

{ ====================================================================== }
{                              SOURIS                                    }
{ ====================================================================== }

Function HitText(X,Y: LongInt): Boolean;
Var P,I,Best: Integer; LX_,LY_,D,BD: LongInt;
Begin
 HitText:=False;
 If Greek Then Exit;
 ScrToPage(X,Y-(MENU_H+1),P,LX_,LY_);
 Best:=-1;BD:=999999;
 For I:=0 To NLn-1 Do
  If Lines^[I].Pg=P Then Begin
   If LY_<Lines^[I].Y Then D:=Lines^[I].Y-LY_
   Else If LY_>=Lines^[I].Y+Lines^[I].H Then D:=LY_-(Lines^[I].Y+Lines^[I].H)+1
   Else D:=0;
   If D<BD Then Begin BD:=D;Best:=I;End;
  End;
 If Best<0 Then Exit;
 ASt:=Lines^[Best].Sty;
 Cur:=PosAtX(Best,Integer(LX_));
 If Cur>Lines^[Best].E Then Cur:=Lines^[Best].E;
 HitText:=True;
End;

Procedure MouseDown(X,Y: LongInt);
Var T,P: Integer; LX_,LY_: LongInt; OldSt,OldCur: Integer;
Begin
 If Y<MENU_H Then Begin
  T:=TitleHit(X,Y);
  If T>0 Then RunMenu(T,True);
  Exit;
 End;
 T:=PanelHit(X,Y);
 If (T>0) And ((Y>=PANEL_Y) Or (Mode=MD_LAYOUT)) Then Begin
  PBDown:=T;NeedDraw:=True;
  Exit;
 End;
 If (Mode=MD_LAYOUT) Or (Y>=PANEL_Y) Then Exit;
 Case Mode Of
  MD_TEXT: Begin
    OldSt:=ASt;OldCur:=Cur;
    If HitText(X,Y) Then Begin
     SelA:=-1;MarkMode:=False;WantX:=-1;
     Dragging:=1;
     Moved;
     If ASt<>OldSt Then TypRun:=False;
    End;
   End;
  MD_ART: Begin
    If (SelArt>0) And (Not HeldOn) And (ArtSub<=2) Then Begin
     T:=HandleHit(X,Y-(MENU_H+1));
     If T>=0 Then Begin
      DragA:=Arts[SelArt];DragCorner:=T;DragPushed:=False;
      If (ArtSub=2) And (DragA.Kind=AR_ART) Then Dragging:=4
      Else Dragging:=3;
      NeedDraw:=True;
      Exit;
     End;
    End;
    ScrToPage(X,Y-(MENU_H+1),P,LX_,LY_);
    ACx:=LX_;ACy:=LongInt(P-1)*(PGH+PGGAP)+LY_;
    If ACx<0 Then ACx:=0;
    If ACx>PGW-1 Then ACx:=PGW-1;
    If LY_<0 Then ACy:=LongInt(P-1)*(PGH+PGGAP);
    If LY_>=PGH Then ACy:=LongInt(P-1)*(PGH+PGGAP)+PGH-1;
    UpdateSelArt;
    If ArtSub=3 Then Begin ArtKey(K_ENTER);End
    Else If HeldOn Then StampHeld
    Else If SelArt>0 Then Begin
     Dragging:=2;DragPushed:=False;
     DragOX:=ACx-Arts[SelArt].X;
     DragOY:=ACy-(LongInt(Arts[SelArt].Pg-1)*(PGH+PGGAP)+Arts[SelArt].Y);
    End;
    NeedDraw:=True;
   End;
 End;
End;

Procedure MouseMove(X,Y: LongInt);
Var P: Integer; LX_,LY_: LongInt; OldCur: Integer;
Begin
 If Dragging=0 Then Exit;
 Case Dragging Of
  1: Begin
      If Y<MENU_H+1 Then ScrollBy(0,-8) Else If Y>PANEL_Y-1 Then ScrollBy(0,8);
      OldCur:=Cur;
      If SelA<0 Then SelA:=Cur;
      If HitText(Max2(0,Min2(X,VW-1)),Max2(MENU_H+1,Min2(Y,PANEL_Y-1))) Then
        Begin
       If Cur<>OldCur Then Begin SyncFont;NeedDraw:=True;End;
      End;
     End;
  3,4: If SelArt>0 Then Begin
      If Y<MENU_H+1 Then ScrollBy(0,-8) Else If Y>PANEL_Y-1 Then ScrollBy(0,8);
      If Not DragPushed Then Begin PushUndoDoc(0);DragPushed:=True;End;
      LX_:=(X-OrgX)*ZD Div ZN;
      LY_:=(Y-(MENU_H+1)-PgY0(DragA.Pg))*ZD Div ZN;
      If Dragging=3 Then ResizeByCorner(Arts[SelArt],DragA,DragCorner,LX_,LY_)
      Else CropByCorner(Arts[SelArt],DragA,DragCorner,LX_,LY_);
      Modified:=True;NeedDraw:=True;
     End;
  2: If SelArt>0 Then Begin
      If Not DragPushed Then Begin PushUndoDoc(0);DragPushed:=True;End;
      ScrToPage(X,Y-(MENU_H+1),P,LX_,LY_);
      Arts[SelArt].Pg:=P;
      Arts[SelArt].X:=Integer(LX_-DragOX);
      Arts[SelArt].Y:=Integer(LY_-DragOY);
      ClampArt(Arts[SelArt]);
      ACx:=Arts[SelArt].X+DragOX;
      ACy:=LongInt(P-1)*(PGH+PGGAP)+Arts[SelArt].Y+DragOY;
      Modified:=True;NeedDraw:=True;
     End;
 End;
End;

Procedure MouseUp(X,Y: LongInt);
Var H: Integer;
Begin
 If PBDown>0 Then Begin
  H:=PanelHit(X,Y);
  If H=PBDown Then Begin PBDown:=0;PanelKey(H);End
  Else PBDown:=0;
  NeedDraw:=True;
  Exit;
 End;
 If (Dragging>=2) And (Dragging<=4) Then Begin
  If (Dragging>=3) And (SelArt>0) Then Begin
   ACx:=Arts[SelArt].X+Arts[SelArt].W Div 2;
   ACy:=LongInt(Arts[SelArt].Pg-1)*(PGH+PGGAP)+Arts[SelArt].Y+
     Arts[SelArt].H Div 2;
  End;
  Relayout;
 End;
 If (Dragging=1) And (SelA=Cur) Then SelA:=-1;
 Dragging:=0;
 NeedDraw:=True;
End;

{ ====================================================================== }
{                  INITIALISATION ET BOUCLE PRINCIPALE                   }
{ ====================================================================== }

Procedure InitData;
Var P: Integer;
Begin
 FillChar(St,SizeOf(St),0);
 FillChar(Arts,SizeOf(Arts),0);
 GetMem(Lines,SizeOf(TLineArr));
 GetMem(ClipT,CLIPCAP+2);GetMem(ClipF,CLIPCAP+2);
 GetMem(UndoT,STCAP+2);GetMem(UndoF,STCAP+2);GetMem(UndoA,STCAP+2);
 StInit(0,STCAP,DefBody,AL_LEFT);
 For P:=1 To MAXPG Do StInit(P,HCAP,DefHead,AL_CENTER);
 NPg:=MAXPG;NArt:=0;ClipN:=0;UndoOK:=False;
 ZN:=1;ZD:=1;ViewNo:=2;ScrX:=0;ScrY:=0;
 GuidesOn:=False;
 Mode:=MD_MAIN;CurPage:=1;
 ASt:=0;Cur:=0;SelA:=-1;MarkMode:=False;CurFont:=DefBody;WantX:=-1;
   TypRun:=False;
 ACStep:=4;ACx:=100;ACy:=100;SelArt:=0;HeldOn:=False;ArtSub:=0;CropEnd:=0;
 DrawKind:=AR_BOX;DrawPat:=14;DrawTh:=6;DrawStep:=0;LastPiece:=1;
 Quit:=False;NeedDraw:=True;Dragging:=0;MenuOpen:=0;MenuHi:=0;
 MX:=0;MY:=0;MB:=0;LastB:=0;LastFill:=-1;
 CaretOn:=False;CaretT:=0;PBDown:=0;StatusMsg:='';StatusT:=0;
 FindStr:='';DocName:='';Named:=False;Modified:=False;
End;

Procedure MainLoop;
Var E: TEvent; T: LongInt;
Begin
 Repeat
  If NeedDraw Then DrawAll;
  PollEvent(E);
  Case E.Kind Of
   1: HandleKey(E.Key);
   2: MouseDown(E.X,E.Y);
   3: MouseUp(E.X,E.Y);
   4: MouseMove(E.X,E.Y);
   0: Begin
       T:=Tick;
       If (StatusMsg<>'') And ((T<StatusT) Or (T-StatusT>=500)) Then Begin
        StatusMsg:='';NeedDraw:=True;
       End;
       If (Mode=MD_TEXT) And ((T<CaretT) Or (T-CaretT>=50)) Then Begin
        HideMouse;ToggleCaret;ShowMouse;CaretT:=T;
       End;
      End;
  End;
 Until Quit;
End;

Procedure ShowHelpLine;
Begin
 WriteLn('NEWS - ',
   Tr('Clone graphique du programme de publication de journaux News Master.'));
 WriteLn;
 WriteLn(Tr('Utilisation : NEWS [fichier.NWS] [/?]'));
 WriteLn;
 WriteLn('  ',Tr('fichier.NWS  Journal '#133' ouvrir.'));
 WriteLn('  ',Tr('/?           Affiche cette aide.'));
 WriteLn;
 WriteLn(Tr('Langue : fran'#135'ais par d'#130'faut. LANGUAGE=EN : anglais, '+
   'LANGUAGE=GR : allemand.'));
 WriteLn(Tr('Place NEWS.FLB dans le r'#130'pertoire courant pour utiliser les '+
   'polices originales.'));
End;

Var NDummy,StartOk: Boolean; StartName: String;

Procedure DetectLanguage;
Var S: String;
Begin
 Lang:=0;
 S:=Upper(GetEnv('LANGUAGE'));
 If Copy(S,1,2)='EN' Then Lang:=1;
 If (Copy(S,1,2)='GR') Or (Copy(S,1,2)='DE') Then Lang:=2;
End;

BEGIN
 NDummy:=False;
 DetectLanguage;
 If (ParamCount>=1) And ((ParamStr(1)='/?') Or (ParamStr(1)='-h') Or
    (ParamStr(1)='--help')) Then Begin
  ShowHelpLine;
  Halt(0);
 End;
 InitializeGraphics;
 ReadBios8;
 BuildLibrary;
 ScanLibs;SrcSelect(0);
 FLBFound:=FindFLB;
 UseFLB:=FLBFound;
 BuildFontTable;
 InitData;
 If MouseDriverFound Then ShowMouse;
 SetPanel(MD_MAIN);
 ShowSplash;
 StartOk:=False;
 If ParamCount>=1 Then Begin
  StartName:=ParamStr(1);
  If Not FileExists(StartName) Then StartName:=AddExt(StartName,'NWS');
  If FileExists(StartName) Then StartOk:=LoadNWS(StartName);
 End;
 If StartOk Then Begin
  DocName:=StartName;Named:=True;Modified:=False;
  CurFont:=St[0].F^[0];
  Relayout;
 End Else MakeDemo;
 SetView(2);
 MainMenuLoop;
 If Not Quit Then MainLoop;
 Dummy := WinDestroyWindow(OsFrame);
END.
