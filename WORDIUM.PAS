{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: WorDium, traitement de texte graphique, pour le
                Presentation Manager d'OS/2-0 (dossier Productivite du
                bureau).
}

Program WorDium;

{$R-,S-}

{ Compilation : OS2PC WORDIUM.PAS   (produit WORDIUM.EXE)

  Portage vers OS/2-0 de WORD.PAS du depot OFFICE-0 (Turbo Pascal 7, Free
  Pascal : BGI 640 x 480 en 16 couleurs, souris de l'interruption 33h ou
  de PtcMouse). Toutes les fonctions de la version DOS sont conservees :
  saisie et mise en forme (gras, italique, souligne, tailles, couleurs,
  alignements, justification, retraits, filets), affichage Normal et Mise
  en page, regle, zoom, menus classiques ou ruban (/RUBANMENU), barres
  d'outils, tableaux (insertion, lignes, colonnes, menu contextuel),
  images (BMP, PCX, GIF, JPEG, TIFF, XBM, BGX, GPX), symboles, police,
  paragraphe, rechercher et remplacer, annuler et retablir, statistiques,
  correcteur d'orthographe (francais, anglais, allemand, espagnol,
  italien), aide, options, cinq langues de l'interface (LANGUAGE=FR, EN,
  ES ou SP, IT, DE ou GR) ; formats .WPD (natif), .DOCX (lecture et
  ecriture), .DOC (Word 97 : lecture), .PDF (lecture), .GAT du MonsterBook
  (lecture et ecriture), .GPX.

  Ce qui change pour OS/2 :
  - fenetre de Presentation Manager : barre de titre (nom du document),
    menu systeme, barre de menus d'OS/2 construite a partir des menus de
    WorDium (memes commandes, lettres soulignees, raccourcis, coches de
    l'Affichage) ; avec le ruban, les titres de la barre de menus de PM
    sont les onglets ;
  - le dessin de la BGI va dans une image de 640 x 480 en memoire,
    montree dans la zone client par GpiDrawBits (zones modifiees
    seulement) ; le pointeur de la souris est celui de PM ;
  - boites de dialogue dans le style d'OS/2 (barre de titre bleue avec la
    case du menu systeme, titre centre) ; messages et confirmations par
    WinMessageBox ;
  - impression par le tampon d'impression d'OS/2 (la version DOS ne
    l'offre pas, la version Windows passe par GDI) ;
  - lettres accentuees de la page de codes 850 acceptees a la saisie ;
  - le document est dans la memoire de DosAllocMem et les copies de
    l'annulation ne gardent que les paragraphes utilises.
}


{ ====================================================================== }
{  OS/2-0 : WorDium dans une fenetre de Presentation Manager              }
{ ====================================================================== }
{ La version DOS de WorDium dessine par la BGI (Graph / PtcGraph) et lit  }
{ le clavier (Crt) et la souris (interruption 33h / PtcMouse). Ici ces    }
{ unites sont remplacees par une couche qui utilise l'API d'OS/2 :        }
{  - l'image de 640 x 480 (16 couleurs de la BGI, palette 256) est gardee }
{    en memoire (DosAllocMem) et montree par GpiDrawBits, zones modifiees }
{    seulement ; la rangee de la barre de menus de WorDium (19 lignes en  }
{    haut) n'est pas montree : c'est la barre de menus de PM qui la       }
{    remplace (zone client de 640 x 461) ;                                }
{  - la barre de menus de PM est construite a partir des menus de WorDium }
{    (Menus[]) ; une commande de PM appelle ExecAction ;                  }
{  - KeyPressed, ReadKey, Delay et GetMouseState vident la file de        }
{    messages de PM (WinPeekMsg) : WM_CHAR (codes de Crt.ReadKey),        }
{    WM_BUTTON*, WM_MOUSEMOVE, WM_COMMAND.                                }
Type
 ViewPortType = Record
  X1, Y1, X2, Y2: Integer;
  Clip: Boolean;
 End;
 FillSettingsType = Record
  Pattern, Color: Word;
 End;
 LineSettingsType = Record
  LineStyle, Pattern, Thickness: Word;
 End;
 TFbArr = Array[0..1048575] Of Byte;
 PFbArr = ^TFbArr;

{ --- PMWIN.DLL, PMGPI.DLL, DOSCALLS.DLL --- }
Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinPeekMsg(Hab, P, HF, First, Last, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinBeginPaint(H, Hps, P : LongInt) : LongInt; External 'PMWIN';
Function WinEndPaint(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(HPar, Id : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function WinAlarm(HD, Typ : LongInt) : LongInt; External 'PMWIN';
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function KTicks : LongInt; External 'DOSCALLS' Name 'GetTickCount';
Function DosBeep(Freq, Dur : LongInt) : LongInt; External 'DOSCALLS';
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';

Const
 WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_CLOSE = $0029;
 WM_QUIT = $002A; WM_INITMENU = $0033; WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071;
 WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073; WM_BUTTON2DOWN = $0074; WM_BUTTON2UP = $0075;
 WM_BUTTON2DBLCLK = $0076; WM_CHAR = $007A;
 FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
 FCF_BORDER = $200;
 HWND_DESKTOP = 1; HWND_TOP = 3;
 SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
 MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_DISABLED = $4000;
 MM_SETITEMATTR = $0192;
 MB_OK = 0; MB_YESNO = 4; MB_QUERY = $10; MB_INFORMATION = $30; MB_MOVEABLE = $4000; MBID_YES = 6;
 KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SCANCODE = 4; KC_SHIFT = 8; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
 VK_BACKSPACE = $05; VK_TAB = $06; VK_BACKTAB = $07; VK_NEWLINE = $08; VK_ESC = $0F; VK_SPACE = $10;
 VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14; VK_LEFT = $15; VK_UP = $16;
 VK_RIGHT = $17; VK_DOWN = $18; VK_INSERT = $1A; VK_DELETE = $1B; VK_ENTER = $1E; VK_F1 = $20;
 PM_REMOVE = 1;
 OsMaxW = 1024; OsMaxH = 768;
 OsKeyMax = 256; OsCmdMax = 32;
 OS_MENUID = 9000;                 { commandes : OS_MENUID + menu * 32 + element }
 MIA_CHECKED = $2000;

Const
 grOk = 0; Detect = 0; D8bit = 7; m640x480 = 2; mMaxScreen = 3;
 Black = 0; Blue = 1; Green = 2; Cyan = 3; Red = 4; Magenta = 5;
 Brown = 6; LightGray = 7; DarkGray = 8; LightBlue = 9;
 LightGreen = 10; LightCyan = 11; LightRed = 12; LightMagenta = 13;
 Yellow = 14; White = 15;
 EmptyFill = 0; SolidFill = 1;
 SolidLn = 0; DottedLn = 1; CenterLn = 2; DashedLn = 3; UserBitLn = 4;
 NormWidth = 1; ThickWidth = 3;
 CopyPut = 0; XORPut = 1; OrPut = 2; AndPut = 3; NotPut = 4;
 NormalPut = 0;
 VGA = 9; VGAHi = 2; DefaultFont = 0; HorizDir = 0; VertDir = 1;
 ClipOn = True; ClipOff = False;
 { touches Alt+lettre (codes de balayage du clavier PC) }
 PdwAltScan: Array[0..25] Of Byte = (30, 48, 46, 32, 18, 33, 34, 35, 23,
  36, 37, 38, 50, 49, 24, 25, 16, 19, 31, 20, 22, 47, 17, 45, 21, 44);
 { palette EGA (16 premieres couleurs) }
 PdwEga: Array[0..15] Of LongWord = ($000000, $0000AA, $00AA00, $00AAAA,
  $AA0000, $AA00AA, $AA5500, $AAAAAA, $555555, $5555FF, $55FF55,
  $55FFFF, $FF5555, $FF55FF, $FFFF55, $FFFFFF);
 { police 8x8 (DefaultFont de la BGI, CP437) }
 PdwFont8: Array[0..255, 0..7] Of Byte = (
    ($00,$00,$00,$00,$00,$00,$00,$00),
    ($7E,$81,$A5,$81,$BD,$99,$81,$7E),
    ($7E,$FF,$DB,$FF,$C3,$E7,$FF,$7E),
    ($6C,$FE,$FE,$FE,$7C,$38,$10,$00),
    ($10,$38,$7C,$FE,$7C,$38,$10,$00),
    ($38,$7C,$38,$FE,$FE,$7C,$38,$7C),
    ($10,$10,$38,$7C,$FE,$7C,$38,$7C),
    ($00,$00,$18,$3C,$3C,$18,$00,$00),
    ($FF,$FF,$E7,$C3,$C3,$E7,$FF,$FF),
    ($00,$3C,$66,$42,$42,$66,$3C,$00),
    ($FF,$C3,$99,$BD,$BD,$99,$C3,$FF),
    ($0F,$07,$0F,$7D,$CC,$CC,$CC,$78),
    ($3C,$66,$66,$66,$3C,$18,$7E,$18),
    ($3F,$33,$3F,$30,$30,$70,$F0,$E0),
    ($7F,$63,$7F,$63,$63,$67,$E6,$C0),
    ($99,$5A,$3C,$E7,$E7,$3C,$5A,$99),
    ($80,$E0,$F8,$FE,$F8,$E0,$80,$00),
    ($02,$0E,$3E,$FE,$3E,$0E,$02,$00),
    ($18,$3C,$7E,$18,$18,$7E,$3C,$18),
    ($66,$66,$66,$66,$66,$00,$66,$00),
    ($7F,$DB,$DB,$7B,$1B,$1B,$1B,$00),
    ($3E,$63,$38,$6C,$6C,$38,$CC,$78),
    ($00,$00,$00,$00,$7E,$7E,$7E,$00),
    ($18,$3C,$7E,$18,$7E,$3C,$18,$FF),
    ($18,$3C,$7E,$18,$18,$18,$18,$00),
    ($18,$18,$18,$18,$7E,$3C,$18,$00),
    ($00,$18,$0C,$FE,$0C,$18,$00,$00),
    ($00,$30,$60,$FE,$60,$30,$00,$00),
    ($00,$00,$C0,$C0,$C0,$FE,$00,$00),
    ($00,$24,$66,$FF,$66,$24,$00,$00),
    ($00,$18,$3C,$7E,$FF,$FF,$00,$00),
    ($00,$FF,$FF,$7E,$3C,$18,$00,$00),
    ($00,$00,$00,$00,$00,$00,$00,$00),
    ($30,$78,$78,$78,$30,$00,$30,$00),
    ($6C,$6C,$6C,$00,$00,$00,$00,$00),
    ($6C,$6C,$FE,$6C,$FE,$6C,$6C,$00),
    ($30,$7C,$C0,$78,$0C,$F8,$30,$00),
    ($00,$C6,$CC,$18,$30,$66,$C6,$00),
    ($38,$6C,$38,$76,$DC,$CC,$76,$00),
    ($60,$60,$C0,$00,$00,$00,$00,$00),
    ($18,$30,$60,$60,$60,$30,$18,$00),
    ($60,$30,$18,$18,$18,$30,$60,$00),
    ($00,$66,$3C,$FF,$3C,$66,$00,$00),
    ($00,$30,$30,$FC,$30,$30,$00,$00),
    ($00,$00,$00,$00,$00,$30,$30,$60),
    ($00,$00,$00,$FC,$00,$00,$00,$00),
    ($00,$00,$00,$00,$00,$30,$30,$00),
    ($06,$0C,$18,$30,$60,$C0,$80,$00),
    ($7C,$C6,$C6,$C6,$C6,$C6,$7C,$00),
    ($30,$70,$30,$30,$30,$30,$FC,$00),
    ($78,$CC,$0C,$38,$60,$CC,$FC,$00),
    ($78,$CC,$0C,$38,$0C,$CC,$78,$00),
    ($1C,$3C,$6C,$CC,$FE,$0C,$1E,$00),
    ($FC,$C0,$F8,$0C,$0C,$CC,$78,$00),
    ($38,$60,$C0,$F8,$CC,$CC,$78,$00),
    ($FC,$CC,$0C,$18,$30,$30,$30,$00),
    ($78,$CC,$CC,$78,$CC,$CC,$78,$00),
    ($78,$CC,$CC,$7C,$0C,$18,$70,$00),
    ($00,$30,$30,$00,$00,$30,$30,$00),
    ($00,$30,$30,$00,$00,$30,$30,$60),
    ($18,$30,$60,$C0,$60,$30,$18,$00),
    ($00,$00,$FC,$00,$00,$FC,$00,$00),
    ($60,$30,$18,$0C,$18,$30,$60,$00),
    ($78,$CC,$0C,$18,$30,$00,$30,$00),
    ($7C,$C6,$DE,$DE,$DE,$C0,$78,$00),
    ($38,$6C,$C6,$C6,$FE,$C6,$C6,$00),
    ($FC,$C6,$C6,$FC,$C6,$C6,$FC,$00),
    ($7C,$C6,$C6,$C0,$C0,$C6,$7C,$00),
    ($F8,$CC,$C6,$C6,$C6,$CC,$F8,$00),
    ($FE,$C0,$C0,$FC,$C0,$C0,$FE,$00),
    ($FE,$C0,$C0,$FC,$C0,$C0,$C0,$00),
    ($7C,$C6,$C0,$CE,$C6,$C6,$7E,$00),
    ($C6,$C6,$C6,$FE,$C6,$C6,$C6,$00),
    ($78,$30,$30,$30,$30,$30,$78,$00),
    ($1E,$06,$06,$06,$C6,$C6,$7C,$00),
    ($C6,$CC,$D8,$F0,$D8,$CC,$C6,$00),
    ($C0,$C0,$C0,$C0,$C0,$C0,$FE,$00),
    ($C6,$EE,$FE,$D6,$C6,$C6,$C6,$00),
    ($C6,$E6,$F6,$DE,$CE,$C6,$C6,$00),
    ($7C,$C6,$C6,$C6,$C6,$C6,$7C,$00),
    ($FC,$C6,$C6,$FC,$C0,$C0,$C0,$00),
    ($7C,$C6,$C6,$C6,$C6,$C6,$7C,$06),
    ($FC,$C6,$C6,$FC,$C6,$C6,$C6,$00),
    ($78,$CC,$60,$30,$18,$CC,$78,$00),
    ($FC,$30,$30,$30,$30,$30,$30,$00),
    ($C6,$C6,$C6,$C6,$C6,$C6,$7C,$00),
    ($C6,$C6,$C6,$C6,$C6,$6C,$38,$00),
    ($C6,$C6,$C6,$D6,$FE,$EE,$C6,$00),
    ($C6,$C6,$6C,$38,$6C,$C6,$C6,$00),
    ($C3,$C3,$66,$3C,$18,$18,$18,$00),
    ($FE,$0C,$18,$30,$60,$C0,$FE,$00),
    ($3C,$30,$30,$30,$30,$30,$3C,$00),
    ($C0,$60,$30,$18,$0C,$06,$03,$00),
    ($3C,$0C,$0C,$0C,$0C,$0C,$3C,$00),
    ($00,$38,$6C,$C6,$00,$00,$00,$00),
    ($00,$00,$00,$00,$00,$00,$00,$FF),
    ($30,$30,$18,$00,$00,$00,$00,$00),
    ($00,$00,$7C,$06,$7E,$C6,$7E,$00),
    ($C0,$C0,$FC,$C6,$C6,$E6,$DC,$00),
    ($00,$00,$7C,$C6,$C0,$C0,$7E,$00),
    ($06,$06,$7E,$C6,$C6,$CE,$76,$00),
    ($00,$00,$7C,$C6,$FE,$C0,$7E,$00),
    ($1E,$30,$7C,$30,$30,$30,$30,$00),
    ($00,$00,$7E,$C6,$CE,$76,$06,$7C),
    ($C0,$C0,$FC,$C6,$C6,$C6,$C6,$00),
    ($18,$00,$38,$18,$18,$18,$3C,$00),
    ($18,$00,$38,$18,$18,$18,$18,$F0),
    ($C0,$C0,$CC,$D8,$F0,$D8,$CC,$00),
    ($38,$18,$18,$18,$18,$18,$3C,$00),
    ($00,$00,$CC,$FE,$D6,$C6,$C6,$00),
    ($00,$00,$FC,$C6,$C6,$C6,$C6,$00),
    ($00,$00,$7C,$C6,$C6,$C6,$7C,$00),
    ($00,$00,$FC,$C6,$C6,$E6,$DC,$C0),
    ($00,$00,$7E,$C6,$C6,$CE,$76,$06),
    ($00,$00,$6E,$70,$60,$60,$60,$00),
    ($00,$00,$7C,$C0,$7C,$06,$FC,$00),
    ($30,$30,$7C,$30,$30,$30,$1C,$00),
    ($00,$00,$C6,$C6,$C6,$C6,$7E,$00),
    ($00,$00,$C6,$C6,$C6,$6C,$38,$00),
    ($00,$00,$C6,$C6,$D6,$FE,$6C,$00),
    ($00,$00,$C6,$6C,$38,$6C,$C6,$00),
    ($00,$00,$C6,$C6,$CE,$76,$06,$7C),
    ($00,$00,$FC,$18,$30,$60,$FC,$00),
    ($1C,$30,$30,$E0,$30,$30,$1C,$00),
    ($18,$18,$18,$00,$18,$18,$18,$00),
    ($E0,$30,$30,$1C,$30,$30,$E0,$00),
    ($76,$DC,$00,$00,$00,$00,$00,$00),
    ($00,$10,$38,$6C,$C6,$C6,$FE,$00),
    ($78,$CC,$C0,$CC,$78,$18,$0C,$78),
    ($00,$CC,$00,$CC,$CC,$CC,$7E,$00),
    ($1C,$00,$78,$CC,$FC,$C0,$78,$00),
    ($7E,$C3,$3C,$06,$3E,$66,$3F,$00),
    ($CC,$00,$78,$0C,$7C,$CC,$7E,$00),
    ($E0,$00,$78,$0C,$7C,$CC,$7E,$00),
    ($30,$30,$78,$0C,$7C,$CC,$7E,$00),
    ($00,$00,$78,$C0,$C0,$78,$0C,$38),
    ($7E,$C3,$3C,$66,$7E,$60,$3C,$00),
    ($CC,$00,$78,$CC,$FC,$C0,$78,$00),
    ($E0,$00,$78,$CC,$FC,$C0,$78,$00),
    ($CC,$00,$70,$30,$30,$30,$78,$00),
    ($7C,$C6,$38,$18,$18,$18,$3C,$00),
    ($E0,$00,$70,$30,$30,$30,$78,$00),
    ($C6,$38,$6C,$C6,$FE,$C6,$C6,$00),
    ($30,$30,$00,$78,$CC,$FC,$CC,$00),
    ($1C,$00,$FC,$60,$78,$60,$FC,$00),
    ($00,$00,$7F,$0C,$7F,$CC,$7F,$00),
    ($3E,$6C,$CC,$FE,$CC,$CC,$CE,$00),
    ($78,$CC,$00,$78,$CC,$CC,$78,$00),
    ($00,$CC,$00,$78,$CC,$CC,$78,$00),
    ($00,$E0,$00,$78,$CC,$CC,$78,$00),
    ($78,$CC,$00,$CC,$CC,$CC,$7E,$00),
    ($00,$E0,$00,$CC,$CC,$CC,$7E,$00),
    ($00,$CC,$00,$CC,$CC,$7C,$0C,$F8),
    ($C3,$18,$3C,$66,$66,$3C,$18,$00),
    ($CC,$00,$CC,$CC,$CC,$CC,$78,$00),
    ($18,$18,$7E,$C0,$C0,$7E,$18,$18),
    ($38,$6C,$64,$F0,$60,$E6,$FC,$00),
    ($CC,$CC,$78,$FC,$30,$FC,$30,$30),
    ($F8,$CC,$CC,$FA,$C6,$CF,$C6,$C7),
    ($0E,$1B,$18,$3C,$18,$18,$D8,$70),
    ($1C,$00,$78,$0C,$7C,$CC,$7E,$00),
    ($38,$00,$70,$30,$30,$30,$78,$00),
    ($00,$1C,$00,$78,$CC,$CC,$78,$00),
    ($00,$1C,$00,$CC,$CC,$CC,$7E,$00),
    ($00,$F8,$00,$F8,$CC,$CC,$CC,$00),
    ($FC,$00,$CC,$EC,$FC,$DC,$CC,$00),
    ($3C,$6C,$6C,$3E,$00,$7E,$00,$00),
    ($38,$6C,$6C,$38,$00,$7C,$00,$00),
    ($30,$00,$30,$60,$C0,$CC,$78,$00),
    ($00,$00,$00,$FC,$C0,$C0,$00,$00),
    ($00,$00,$00,$FC,$0C,$0C,$00,$00),
    ($C3,$C6,$CC,$DE,$33,$66,$CC,$0F),
    ($C3,$C6,$CC,$DB,$37,$6F,$CF,$03),
    ($18,$18,$00,$18,$18,$18,$18,$00),
    ($00,$33,$66,$CC,$66,$33,$00,$00),
    ($00,$CC,$66,$33,$66,$CC,$00,$00),
    ($22,$88,$22,$88,$22,$88,$22,$88),
    ($55,$AA,$55,$AA,$55,$AA,$55,$AA),
    ($DB,$77,$DB,$EE,$DB,$77,$DB,$EE),
    ($18,$18,$18,$18,$18,$18,$18,$18),
    ($18,$18,$18,$18,$F8,$18,$18,$18),
    ($18,$18,$F8,$18,$F8,$18,$18,$18),
    ($36,$36,$36,$36,$F6,$36,$36,$36),
    ($00,$00,$00,$00,$FE,$36,$36,$36),
    ($00,$00,$F8,$18,$F8,$18,$18,$18),
    ($36,$36,$F6,$06,$F6,$36,$36,$36),
    ($36,$36,$36,$36,$36,$36,$36,$36),
    ($00,$00,$FE,$06,$F6,$36,$36,$36),
    ($36,$36,$F6,$06,$FE,$00,$00,$00),
    ($36,$36,$36,$36,$FE,$00,$00,$00),
    ($18,$18,$F8,$18,$F8,$00,$00,$00),
    ($00,$00,$00,$00,$F8,$18,$18,$18),
    ($18,$18,$18,$18,$1F,$00,$00,$00),
    ($18,$18,$18,$18,$FF,$00,$00,$00),
    ($00,$00,$00,$00,$FF,$18,$18,$18),
    ($18,$18,$18,$18,$1F,$18,$18,$18),
    ($00,$00,$00,$00,$FF,$00,$00,$00),
    ($18,$18,$18,$18,$FF,$18,$18,$18),
    ($18,$18,$1F,$18,$1F,$18,$18,$18),
    ($36,$36,$36,$36,$37,$36,$36,$36),
    ($36,$36,$37,$30,$3F,$00,$00,$00),
    ($00,$00,$3F,$30,$37,$36,$36,$36),
    ($36,$36,$F7,$00,$FF,$00,$00,$00),
    ($00,$00,$FF,$00,$F7,$36,$36,$36),
    ($36,$36,$37,$30,$37,$36,$36,$36),
    ($00,$00,$FF,$00,$FF,$00,$00,$00),
    ($36,$36,$F7,$00,$F7,$36,$36,$36),
    ($18,$18,$FF,$00,$FF,$00,$00,$00),
    ($36,$36,$36,$36,$FF,$00,$00,$00),
    ($00,$00,$FF,$00,$FF,$18,$18,$18),
    ($00,$00,$00,$00,$FF,$36,$36,$36),
    ($36,$36,$36,$36,$3F,$00,$00,$00),
    ($18,$18,$1F,$18,$1F,$00,$00,$00),
    ($00,$00,$1F,$18,$1F,$18,$18,$18),
    ($00,$00,$00,$00,$3F,$36,$36,$36),
    ($36,$36,$36,$36,$FF,$36,$36,$36),
    ($18,$18,$FF,$18,$FF,$18,$18,$18),
    ($18,$18,$18,$18,$F8,$00,$00,$00),
    ($00,$00,$00,$00,$1F,$18,$18,$18),
    ($FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF),
    ($00,$00,$00,$00,$FF,$FF,$FF,$FF),
    ($F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0),
    ($0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F),
    ($FF,$FF,$FF,$FF,$00,$00,$00,$00),
    ($00,$00,$76,$DC,$C8,$DC,$76,$00),
    ($00,$78,$CC,$F8,$CC,$F8,$C0,$C0),
    ($00,$FC,$CC,$C0,$C0,$C0,$C0,$00),
    ($00,$FE,$6C,$6C,$6C,$6C,$6C,$00),
    ($FC,$CC,$60,$30,$60,$CC,$FC,$00),
    ($00,$00,$7E,$D8,$D8,$D8,$70,$00),
    ($00,$66,$66,$66,$66,$7C,$60,$C0),
    ($00,$76,$DC,$18,$18,$18,$18,$00),
    ($FC,$30,$78,$CC,$CC,$78,$30,$FC),
    ($38,$6C,$C6,$FE,$C6,$6C,$38,$00),
    ($38,$6C,$C6,$C6,$6C,$6C,$EE,$00),
    ($1C,$30,$18,$7C,$CC,$CC,$78,$00),
    ($00,$00,$7E,$DB,$DB,$7E,$00,$00),
    ($06,$0C,$7E,$DB,$DB,$7E,$60,$C0),
    ($38,$60,$C0,$F8,$C0,$60,$38,$00),
    ($78,$CC,$CC,$CC,$CC,$CC,$CC,$00),
    ($00,$FC,$00,$FC,$00,$FC,$00,$00),
    ($30,$30,$FC,$30,$30,$00,$FC,$00),
    ($60,$30,$18,$30,$60,$00,$FC,$00),
    ($18,$30,$60,$30,$18,$00,$FC,$00),
    ($0E,$1B,$1B,$18,$18,$18,$18,$18),
    ($18,$18,$18,$18,$18,$D8,$D8,$70),
    ($30,$30,$00,$FC,$00,$30,$30,$00),
    ($00,$76,$DC,$00,$76,$DC,$00,$00),
    ($38,$6C,$6C,$38,$00,$00,$00,$00),
    ($00,$00,$00,$18,$18,$00,$00,$00),
    ($00,$00,$00,$00,$18,$00,$00,$00),
    ($0F,$0C,$0C,$0C,$EC,$6C,$3C,$1C),
    ($78,$6C,$6C,$6C,$6C,$00,$00,$00),
    ($70,$18,$30,$60,$78,$00,$00,$00),
    ($00,$00,$3C,$3C,$3C,$3C,$00,$00),
    ($00,$00,$00,$00,$00,$00,$00,$00));


Var
 OsHab, OsHmq, OsFrame, OsClient, OsDummy : LongInt;
 PdwW, PdwH : LongInt;                     { taille de l'image (zone client) }
 PdwFb : PFbArr;                           { image, lignes de bas en haut }
 OsBmi : Array[0..16 + 256 * 4 - 1] Of Byte;
 PdwDirty : Boolean;
 PdwDX1, PdwDY1, PdwDX2, PdwDY2 : LongInt;
 PdwColor, PdwFillColor, PdwFillStyle : LongInt;
 PdwLineStyle, PdwLinePat, PdwThick, PdwWrite : LongInt;
 PdwVP : ViewPortType;
 PdwKeys : Array[0..OsKeyMax - 1] Of Char;
 PdwKHead, PdwKTail : LongInt;
 PdwMX, PdwMY, PdwMB, PdwMBLatch : LongInt;
 PdwResult : Integer;
 PdwCharSize : LongInt;                    { SetTextStyle : agrandissement }
 OsOY : LongInt;                           { lignes du haut cachees (barre de menus de WorDium) }
 PdwTitle : String;
 OsCmds : Array[0..OsCmdMax - 1] Of LongInt;
 OsCHead, OsCTail : LongInt;
 OsQuit : Boolean;
 OsZ, OsZ2 : Array[0..1023] Of Byte;
 OsTxt : Array[0..4095] Of Byte;
 OsMenuT : Array[0..16383] Of Byte;
 OsMenuLen, OsMenuSig : LongInt;
 OsQmsg : Array[0..7] Of LongInt;
 OsOpenTick, OsRepaints : LongInt;
 OsSmall : Boolean;

{ --- utilitaires --- }
Procedure OsWrB(A, V : LongInt);
Type PB1 = ^Byte;
Var Q : PB1;
Begin
 Q := Pointer(A);
 Q^ := V;
End;

Function OsPkB(A : LongInt) : LongInt;
Type PB2 = ^Byte;
Var Q : PB2;
Begin
 Q := Pointer(A);
 OsPkB := Q^;
End;

Procedure OsWrW(A, V : LongInt);
Begin
 OsWrB(A, V And 255); OsWrB(A + 1, (V Shr 8) And 255);
End;

Procedure OsWrL(A, V : LongInt);
Begin
 OsWrW(A, V And $FFFF); OsWrW(A + 2, (V Shr 16) And $FFFF);
End;

Procedure OsPutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
 For K := 1 To Length(S) Do OsWrB(A + K - 1, Ord(S[K]));
 OsWrB(A + Length(S), 0);
End;

Function OsZs(S : String) : LongInt;
Begin
 OsPutZ(LongInt(@OsZ), S);
 OsZs := LongInt(@OsZ);
End;

Function OsZs2(S : String) : LongInt;
Begin
 OsPutZ(LongInt(@OsZ2), S);
 OsZs2 := LongInt(@OsZ2);
End;

Function OsLo16(V : LongInt) : LongInt;
Begin
 OsLo16 := V And $FFFF;
End;

Function OsHi16(V : LongInt) : LongInt;
Begin
 OsHi16 := (V Shr 16) And $FFFF;
End;

Function OsS16(V : LongInt) : LongInt;
Begin
 V := V And $FFFF;
 If V >= $8000 Then V := V - $10000;
 OsS16 := V;
End;

{ comparaison d'octets (FPC) : <0, 0, >0 }
Function CompareByte(Var A; Var B; N : LongInt) : LongInt;
Var I, PA, PB, VA, VB : LongInt;
Begin
 CompareByte := 0;
 PA := LongInt(@A); PB := LongInt(@B);
 For I := 0 To N - 1 Do
 Begin
  VA := OsPkB(PA + I); VB := OsPkB(PB + I);
  If VA <> VB Then
  Begin
   CompareByte := VA - VB;
   Exit;
  End;
 End;
End;

Function InterLockedIncrement(Var V : LongInt) : LongInt;
Begin
 Inc(V);
 InterLockedIncrement := V;
End;

{ zone de l'ecran a recopier dans la fenetre }
Procedure PdwMark(X1, Y1, X2, Y2 : LongInt);
Begin
 If X1 < 0 Then X1 := 0;
 If Y1 < 0 Then Y1 := 0;
 If X2 >= PdwW Then X2 := PdwW - 1;
 If Y2 >= PdwH Then Y2 := PdwH - 1;
 If (X1 > X2) Or (Y1 > Y2) Then Exit;
 If Not PdwDirty Then
 Begin
  PdwDX1 := X1; PdwDY1 := Y1; PdwDX2 := X2; PdwDY2 := Y2;
  PdwDirty := True;
  Exit;
 End;
 If X1 < PdwDX1 Then PdwDX1 := X1;
 If Y1 < PdwDY1 Then PdwDY1 := Y1;
 If X2 > PdwDX2 Then PdwDX2 := X2;
 If Y2 > PdwDY2 Then PdwDY2 := Y2;
End;

{ GpiDrawBits : rectangle X1..X2, Y1..Y2 (Y vers le bas) }
Procedure OsBlit(Hps, X1, Y1, X2, Y2 : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
 If (X2 < X1) Or (Y2 < Y1) Then Exit;
 P[0] := X1; P[1] := PdwH - 1 - Y2; P[2] := X2 + 1; P[3] := PdwH - Y1;
 P[4] := X1; P[5] := PdwH - 1 - Y2; P[6] := X2 + 1; P[7] := PdwH - Y1;
 OsDummy := GpiDrawBits(Hps, LongInt(PdwFb), LongInt(@OsBmi), 4, LongInt(@P), $CC, 0);
End;

{ recopier la zone modifiee de l'image dans la fenetre }
Procedure PdwFlush;
Var Hps : LongInt;
Begin
 If (Not PdwDirty) Or (OsClient = 0) Then Exit;
 Hps := WinGetPS(OsClient);
 If Hps <> 0 Then
 Begin
  OsBlit(Hps, PdwDX1, PdwDY1, PdwDX2, PdwDY2);
  OsDummy := WinReleasePS(Hps);
 End;
 PdwDirty := False;
End;

Procedure PdwPush(C : Char);
Begin
 If ((PdwKTail + 1) Mod OsKeyMax) = PdwKHead Then Exit;
 PdwKeys[PdwKTail] := C;
 PdwKTail := (PdwKTail + 1) Mod OsKeyMax;
End;

Procedure PdwPushCode(K : LongInt);
Begin
 If K >= 256 Then
 Begin
  PdwPush(#0); PdwPush(Chr(K - 256));
 End
 Else PdwPush(Chr(K));
End;

{ touche de PM (WM_CHAR) -> codes de Crt.ReadKey (#0 + code etendu) }
Function OsKeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk, K : LongInt;
Begin
 OsKeyChar := False;
 Fl := OsLo16(Mp1); Ch := OsLo16(Mp2); Vk := OsHi16(Mp2);
 If (Fl And KC_KEYUP) <> 0 Then Exit;
 K := -1;
 If (Fl And KC_VIRTUALKEY) <> 0 Then
 Begin
  Case Vk Of
   VK_ESC : K := 27;
   VK_NEWLINE, VK_ENTER : If (Fl And KC_CTRL) <> 0 Then K := 10 Else K := 13;
   VK_BACKSPACE : K := 8;
   VK_TAB : If (Fl And KC_SHIFT) <> 0 Then K := 256 + 15 Else K := 9;
   VK_BACKTAB : K := 256 + 15;
   VK_UP : K := 256 + 72;
   VK_DOWN : K := 256 + 80;
   VK_LEFT : If (Fl And KC_CTRL) <> 0 Then K := 256 + 115 Else K := 256 + 75;
   VK_RIGHT : If (Fl And KC_CTRL) <> 0 Then K := 256 + 116 Else K := 256 + 77;
   VK_HOME : K := 256 + 71;
   VK_END : K := 256 + 79;
   VK_PAGEUP : K := 256 + 73;
   VK_PAGEDOWN : K := 256 + 81;
   VK_INSERT : K := 256 + 82;
   VK_DELETE : K := 256 + 83;
   VK_SPACE : If (Fl And KC_CHAR) = 0 Then K := 32;
  End;
  If (Vk >= VK_F1) And (Vk <= VK_F1 + 9) Then
  Begin
   If (Fl And KC_ALT) <> 0 Then K := 256 + 104 + Vk - VK_F1
   Else If (Fl And KC_CTRL) <> 0 Then K := 256 + 94 + Vk - VK_F1
   Else If (Fl And KC_SHIFT) <> 0 Then K := 256 + 84 + Vk - VK_F1
   Else K := 256 + 59 + Vk - VK_F1;
  End;
  If Vk = VK_F1 + 10 Then K := 256 + 133;
  If Vk = VK_F1 + 11 Then K := 256 + 134;
 End;
 { Alt+X : quitter (raccourci de WorDium ; les autres Alt+lettre vont a la
   barre de menus de PM) }
 If (K < 0) And ((Fl And KC_ALT) <> 0) And ((Ch = Ord('x')) Or (Ch = Ord('X'))) Then K := 256 + 45;
 If (K < 0) And ((Fl And KC_CHAR) <> 0) And ((Fl And KC_ALT) = 0) And (Ch > 0) And (Ch < 256) Then
 Begin
  K := Ch;
  If ((Fl And KC_CTRL) <> 0) And (UpCase(Chr(Ch)) >= 'A') And (UpCase(Chr(Ch)) <= 'Z') Then
   K := Ord(UpCase(Chr(Ch))) - 64;
 End;
 If (K < 0) And ((Fl And KC_CTRL) <> 0) And ((Fl And KC_ALT) = 0) And (Ch > 0) And (Ch < 256) Then
  If (UpCase(Chr(Ch)) >= 'A') And (UpCase(Chr(Ch)) <= 'Z') Then K := Ord(UpCase(Chr(Ch))) - 64;
 If K < 0 Then Exit;
 PdwPushCode(K);
 OsKeyChar := True;
End;

Procedure OsMenuInit; Forward;

Function OsClientProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, B : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 OsClientProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, LongInt(@Rc));
    OsBlit(Hps, 0, 0, PdwW - 1, PdwH - 1);
    OsDummy := WinEndPaint(Hps);
   End;
  WM_CHAR :
   If OsKeyChar(Mp1, Mp2) Then OsClientProc := 1
   Else OsClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  WM_MOUSEMOVE :
   Begin
    PdwMX := OsS16(Mp1); PdwMY := PdwH - 1 - OsS16(Mp1 Shr 16) + OsOY;
    OsClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_BUTTON1DOWN, WM_BUTTON1DBLCLK, WM_BUTTON2DOWN, WM_BUTTON2DBLCLK :
   Begin
    PdwMX := OsS16(Mp1); PdwMY := PdwH - 1 - OsS16(Mp1 Shr 16) + OsOY;
    OsDummy := WinSetFocus(HWND_DESKTOP, H);
    OsDummy := WinSetCapture(HWND_DESKTOP, H);
    If (Msg = WM_BUTTON1DOWN) Or (Msg = WM_BUTTON1DBLCLK) Then B := 1 Else B := 2;
    { un clic bref (appui et relachement entre deux lectures) reste vu }
    PdwMB := PdwMB Or B; PdwMBLatch := PdwMBLatch Or B;
    OsClientProc := 1;
   End;
  WM_BUTTON1UP, WM_BUTTON2UP :
   Begin
    PdwMX := OsS16(Mp1); PdwMY := PdwH - 1 - OsS16(Mp1 Shr 16) + OsOY;
    If Msg = WM_BUTTON1UP Then B := 1 Else B := 2;
    PdwMB := PdwMB And Not B;
    If PdwMB = 0 Then OsDummy := WinSetCapture(HWND_DESKTOP, 0);
    OsClientProc := 1;
   End;
  WM_COMMAND :
   If OsLo16(Mp1) >= OS_MENUID Then
   Begin
    If (OsCTail + 1) Mod OsCmdMax <> OsCHead Then
    Begin
     OsCmds[OsCTail] := OsLo16(Mp1) - OS_MENUID;
     OsCTail := (OsCTail + 1) Mod OsCmdMax;
    End;
   End;
  WM_INITMENU : OsMenuInit;
  WM_CLOSE :
   Begin
    { fermer la fenetre : Fichier - Quitter (confirmation si le document
      est modifie) }
    If (OsCTail + 1) Mod OsCmdMax <> OsCHead Then
    Begin
     OsCmds[OsCTail] := OS_CMD_QUIT;
     OsCTail := (OsCTail + 1) Mod OsCmdMax;
    End;
   End;
 Else
  OsClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

{ messages en attente, puis mise a jour de la fenetre ; l'image entiere
  est redemandee 1 s puis 3 s apres l'ouverture (fenetre ouverte depuis
  le bureau : les parties encore couvertes par les dossiers) }
Procedure PdwPump;
Begin
 If (OsRepaints < 2) And (OsClient <> 0) And (KTicks - OsOpenTick >= 1000 + 2000 * OsRepaints) Then
 Begin
  Inc(OsRepaints);
  OsDummy := WinInvalidateRect(OsClient, 0, 0);
 End;
 While WinPeekMsg(OsHab, LongInt(@OsQmsg), 0, 0, 0, PM_REMOVE) <> 0 Do
 Begin
  If OsQmsg[1] = WM_QUIT Then OsQuit := True
  Else OsDummy := WinDispatchMsg(OsHab, LongInt(@OsQmsg));
 End;
 PdwFlush;
End;

{ ---- Crt ---- }
Function KeyPressed : Boolean;
Begin
 PdwPump;
 KeyPressed := PdwKHead <> PdwKTail;
End;

Function ReadKey : Char;
Begin
 While Not KeyPressed Do OsDummy := DosSleep(10);
 ReadKey := PdwKeys[PdwKHead];
 PdwKHead := (PdwKHead + 1) Mod OsKeyMax;
End;

Procedure Delay(Ms : Word);
Begin
 PdwPump;
 If Ms > 0 Then OsDummy := DosSleep(Ms);
End;

Procedure Sound(Hz : Word);
Begin
End;

Procedure NoSound;
Begin
End;

{ ---- souris (fonctions de PtcMouse) ---- }
Procedure InitMouse;
Begin
 PdwMX := 0; PdwMY := 0; PdwMB := 0; PdwMBLatch := 0;
End;

Procedure ShowMouse;
Begin
End;

Procedure HideMouse;
Begin
End;

Procedure GetMouseState(Var X, Y, B : LongInt);
Begin
 PdwPump;
 X := PdwMX; Y := PdwMY; B := PdwMB Or PdwMBLatch;
 PdwMBLatch := 0;
End;

Procedure SetMousePos(X, Y : LongInt);
Begin
 PdwMX := X; PdwMY := Y;
End;

{ ---- Graph : primitives sur l'image 8 bits ---- }

{ point absolu (coordonnees ecran), ecrete par l'ecran et la fenetre de
  vue ; Mode : CopyPut ou XORPut }
Procedure PdwPlot(X, Y, C, Mode : LongInt);
Var A : LongInt;
Begin
 If PdwVP.Clip Then
  If (X < PdwVP.X1) Or (X > PdwVP.X2) Or (Y < PdwVP.Y1) Or (Y > PdwVP.Y2) Then Exit;
 Y := Y - OsOY;
 If (X < 0) Or (Y < 0) Or (X >= PdwW) Or (Y >= PdwH) Then Exit;
 A := (PdwH - 1 - Y) * PdwW + X;
 If Mode = XORPut Then PdwFb^[A] := PdwFb^[A] Xor (C And 255)
 Else PdwFb^[A] := C And 255;
 PdwMark(X, Y, X, Y);
End;

{ ligne horizontale pleine (coordonnees ecran) }
Procedure PdwHLine(X1, X2, Y, C : LongInt);
Var T : LongInt;
Begin
 If X1 > X2 Then Begin T := X1; X1 := X2; X2 := T End;
 If PdwVP.Clip Then
 Begin
  If (Y < PdwVP.Y1) Or (Y > PdwVP.Y2) Then Exit;
  If X1 < PdwVP.X1 Then X1 := PdwVP.X1;
  If X2 > PdwVP.X2 Then X2 := PdwVP.X2;
 End;
 Y := Y - OsOY;
 If (Y < 0) Or (Y >= PdwH) Then Exit;
 If X1 < 0 Then X1 := 0;
 If X2 >= PdwW Then X2 := PdwW - 1;
 If X1 > X2 Then Exit;
 FillChar(PdwFb^[(PdwH - 1 - Y) * PdwW + X1], X2 - X1 + 1, C And 255);
 PdwMark(X1, Y, X2, Y);
End;

Procedure PutPixel(X, Y : Integer; Color : Word);
Begin
 PdwPlot(X + PdwVP.X1, Y + PdwVP.Y1, Color, CopyPut);
End;

Function GetPixel(X, Y : Integer) : Word;
Var AX, AY : LongInt;
Begin
 AX := X + PdwVP.X1; AY := Y + PdwVP.Y1 - OsOY;
 If (AX < 0) Or (AY < 0) Or (AX >= PdwW) Or (AY >= PdwH) Then GetPixel := 0
 Else GetPixel := PdwFb^[(PdwH - 1 - AY) * PdwW + AX];
End;
Procedure SetColor(Color: Word);
Begin
 PdwColor := Color;
End;

Function GetColor: Word;
Begin
 GetColor := PdwColor;
End;

Function GetMaxColor: Word;
Begin
 GetMaxColor := 255;
End;

Procedure SetFillStyle(Pattern, Color: Word);
Begin
 PdwFillStyle := Pattern;
 PdwFillColor := Color;
End;

Procedure GetFillSettings(Var F: FillSettingsType);
Begin
 F.Pattern := PdwFillStyle;
 F.Color := PdwFillColor;
End;

Procedure SetLineStyle(LineStyle, Pattern, Thickness: Word);
Begin
 PdwLineStyle := LineStyle;
 Case LineStyle Of
  SolidLn: PdwLinePat := $FFFF;
  DottedLn: PdwLinePat := $CCCC;
  CenterLn: PdwLinePat := $FC78;
  DashedLn: PdwLinePat := $F8F8;
 Else
  PdwLinePat := Pattern;
 End;
 PdwThick := Thickness;
End;

Procedure GetLineSettings(Var L: LineSettingsType);
Begin
 L.LineStyle := PdwLineStyle;
 L.Pattern := PdwLinePat;
 L.Thickness := PdwThick;
End;

Procedure SetWriteMode(Mode: Integer);
Begin
 PdwWrite := Mode;
End;

Procedure SetViewPort(X1, Y1, X2, Y2: Integer; Clip: Boolean);
Begin
 PdwVP.X1 := X1; PdwVP.Y1 := Y1; PdwVP.X2 := X2; PdwVP.Y2 := Y2;
 PdwVP.Clip := Clip;
End;

Procedure GetViewSettings(Var V: ViewPortType);
Begin
 V := PdwVP;
End;

{ ligne (coordonnees ecran) avec le style et le mode d ecriture }
Procedure PdwLine(X1, Y1, X2, Y2: LongInt);
Var DX, DY, SX, SY, E, E2, N: LongInt;
Begin
 DX := Abs(X2 - X1); DY := Abs(Y2 - Y1);
 If X1 < X2 Then SX := 1 Else SX := -1;
 If Y1 < Y2 Then SY := 1 Else SY := -1;
 E := DX - DY;
 N := 0;
 While True Do
 Begin
  If ((PdwLinePat Shr (15 - (N And 15))) And 1) <> 0 Then
  Begin
   PdwPlot(X1, Y1, PdwColor, PdwWrite);
   If PdwThick >= 3 Then
   Begin
    If DX > DY Then
    Begin
     PdwPlot(X1, Y1 - 1, PdwColor, PdwWrite);
     PdwPlot(X1, Y1 + 1, PdwColor, PdwWrite);
    End
    Else
    Begin
     PdwPlot(X1 - 1, Y1, PdwColor, PdwWrite);
     PdwPlot(X1 + 1, Y1, PdwColor, PdwWrite);
    End;
   End;
  End;
  Inc(N);
  If (X1 = X2) And (Y1 = Y2) Then Break;
  E2 := 2 * E;
  If E2 > -DY Then Begin E := E - DY; X1 := X1 + SX End;
  If E2 < DX Then Begin E := E + DX; Y1 := Y1 + SY End;
 End;
End;

Procedure Line(X1, Y1, X2, Y2: Integer);
Begin
 PdwLine(X1 + PdwVP.X1, Y1 + PdwVP.Y1, X2 + PdwVP.X1, Y2 + PdwVP.Y1);
End;

Procedure Rectangle(X1, Y1, X2, Y2: Integer);
Var T: Integer;
Begin
 If X1 > X2 Then Begin T := X1; X1 := X2; X2 := T End;
 If Y1 > Y2 Then Begin T := Y1; Y1 := Y2; Y2 := T End;
 Line(X1, Y1, X2, Y1);
 If Y2 > Y1 Then Line(X1, Y2, X2, Y2);
 If Y2 > Y1 + 1 Then
 Begin
  Line(X1, Y1 + 1, X1, Y2 - 1);
  If X2 > X1 Then Line(X2, Y1 + 1, X2, Y2 - 1);
 End;
End;

Procedure Bar(X1, Y1, X2, Y2: Integer);
Var Y, T, C: LongInt;
Begin
 If X1 > X2 Then Begin T := X1; X1 := X2; X2 := T End;
 If Y1 > Y2 Then Begin T := Y1; Y1 := Y2; Y2 := T End;
 If PdwFillStyle = EmptyFill Then C := 0 Else C := PdwFillColor;
 For Y := Y1 To Y2 Do
  PdwHLine(X1 + PdwVP.X1, X2 + PdwVP.X1, Y + PdwVP.Y1, C);
End;

{ angle (degres, 0..360) du point (X, Y) }
Function ArcTan2Deg(Y, X: Double): Double;
Var A: Double;
Begin
 If X = 0 Then
 Begin
  If Y >= 0 Then A := 90 Else A := 270;
 End
 Else
 Begin
  A := ArcTan(Y / X) * 180 / Pi;
  If X < 0 Then A := A + 180
  Else If Y < 0 Then A := A + 360;
 End;
 ArcTan2Deg := A;
End;

{ points d une ellipse (centre absolu), chacun une seule fois ; arc de
  StA a EnA degres (sens trigonometrique, 0 = 3 heures) }
Procedure PdwEllipse(CX, CY, XR, YR, StA, EnA: LongInt);
Var X, Y, A2, B2, FA2, FB2, Sigma, Full: LongInt;

 Procedure P4(DX, DY: LongInt);
 Var Ang: Double; K: LongInt;
 Begin
  If Full = 0 Then
  Begin
   Ang := ArcTan2Deg(-DY, DX);
   K := Round(Ang);
   If StA <= EnA Then
   Begin
    If (K < StA) Or (K > EnA) Then Exit;
   End
   Else If (K < StA) And (K > EnA) Then Exit;
  End;
  PdwPlot(CX + DX, CY + DY, PdwColor, PdwWrite);
 End;

 Procedure Quad(DX, DY: LongInt);
 Begin
  P4(DX, DY);
  If DX <> 0 Then P4(-DX, DY);
  If DY <> 0 Then
  Begin
   P4(DX, -DY);
   If DX <> 0 Then P4(-DX, -DY);
  End;
 End;

Begin
 StA := StA Mod 360; If StA < 0 Then StA := StA + 360;
 EnA := EnA Mod 361; If EnA < 0 Then EnA := EnA + 360;
 If (StA = 0) And (EnA >= 360) Then Full := 1 Else Full := 0;
 If (XR <= 0) Or (YR <= 0) Then
 Begin
  If XR <= 0 Then PdwLine(CX, CY - YR, CX, CY + YR)
  Else PdwLine(CX - XR, CY, CX + XR, CY);
  Exit;
 End;
 A2 := XR * XR; B2 := YR * YR; FA2 := 4 * A2; FB2 := 4 * B2;
 { premiere moitie }
 X := 0; Y := YR; Sigma := 2 * B2 + A2 * (1 - 2 * YR);
 While B2 * X <= A2 * Y Do
 Begin
  Quad(X, Y);
  If Sigma >= 0 Then
  Begin
   Sigma := Sigma + FA2 * (1 - Y);
   Dec(Y);
  End;
  Sigma := Sigma + B2 * ((4 * X) + 6);
  Inc(X);
 End;
 { seconde moitie }
 X := XR; Y := 0; Sigma := 2 * A2 + B2 * (1 - 2 * XR);
 While A2 * Y < B2 * X Do
 Begin
  Quad(X, Y);
  If Sigma >= 0 Then
  Begin
   Sigma := Sigma + FB2 * (1 - X);
   Dec(X);
  End;
  Sigma := Sigma + A2 * ((4 * Y) + 6);
  Inc(Y);
 End;
End;

Procedure Circle(X, Y: Integer; Radius: Word);
Begin
 PdwEllipse(X + PdwVP.X1, Y + PdwVP.Y1, Radius, Radius, 0, 360);
End;

Procedure Arc(X, Y: Integer; StAngle, EndAngle, Radius: Word);
Begin
 PdwEllipse(X + PdwVP.X1, Y + PdwVP.Y1, Radius, Radius, StAngle, EndAngle);
End;

Procedure Ellipse(X, Y: Integer; StAngle, EndAngle: Word; XRadius,
 YRadius: Word);
Begin
 PdwEllipse(X + PdwVP.X1, Y + PdwVP.Y1, XRadius, YRadius, StAngle,
  EndAngle);
End;

Procedure FillEllipse(X, Y: Integer; XRadius, YRadius: Word);
Var DY, HW, C: LongInt;
Begin
 If PdwFillStyle = EmptyFill Then C := 0 Else C := PdwFillColor;
 If YRadius > 0 Then
  For DY := -YRadius To YRadius Do
  Begin
   HW := Round(XRadius * Sqrt(1.0 - (DY * DY) / (1.0 * YRadius * YRadius)));
   PdwHLine(X + PdwVP.X1 - HW, X + PdwVP.X1 + HW, Y + PdwVP.Y1 + DY, C);
  End;
 PdwEllipse(X + PdwVP.X1, Y + PdwVP.Y1, XRadius, YRadius, 0, 360);
End;

{ ---- texte : police 8x8 de la BGI (DefaultFont), agrandie par SetTextStyle ---- }
Procedure OutTextXY(X, Y : Integer; Const TextString : String);
Var K, R, Col, B, BX, BY, M, J : LongInt;
Begin
 BX := X + PdwVP.X1; BY := Y + PdwVP.Y1; M := PdwCharSize;
 For K := 1 To Length(TextString) Do
 Begin
  For R := 0 To 7 Do
  Begin
   B := PdwFont8[Ord(TextString[K]), R];
   If B <> 0 Then
    For Col := 0 To 7 Do
     If (B And ($80 Shr Col)) <> 0 Then
     Begin
      If M = 1 Then PdwPlot(BX + Col, BY + R, PdwColor, CopyPut)
      Else
       For J := 0 To M - 1 Do
        PdwHLine(BX + Col * M, BX + Col * M + M - 1, BY + R * M + J, PdwColor);
     End;
  End;
  BX := BX + 8 * M;
 End;
End;

Procedure SetTextStyle(Font, Direction : Word; CharSize : Word);
Begin
 PdwCharSize := CharSize;
 If PdwCharSize < 1 Then PdwCharSize := 1;
 If PdwCharSize > 10 Then PdwCharSize := 10;
End;

Function TextWidth(Const TextString : String) : Word;
Begin
 TextWidth := 8 * PdwCharSize * Length(TextString);
End;

Function TextHeight(Const TextString : String) : Word;
Begin
 TextHeight := 8 * PdwCharSize;
End;

{ secteur plein (camembert) : interieur a la couleur de remplissage, bord
  (arc et rayons) a la couleur courante }
Procedure PieSlice(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Var DX, DY, CX, CY, C, K, St, En : LongInt; Ang : Double; Inside : Boolean;
Begin
 CX := X + PdwVP.X1; CY := Y + PdwVP.Y1;
 St := StAngle Mod 360; En := EndAngle Mod 361;
 If PdwFillStyle = EmptyFill Then C := 0 Else C := PdwFillColor;
 For DY := -Radius To Radius Do
  For DX := -Radius To Radius Do
   If DX * DX + DY * DY <= LongInt(Radius) * Radius Then
   Begin
    Ang := ArcTan2Deg(-DY, DX); K := Round(Ang);
    If St <= En Then Inside := (K >= St) And (K <= En)
    Else Inside := (K >= St) Or (K <= En);
    If (DX = 0) And (DY = 0) Then Inside := True;
    If Inside Then PdwPlot(CX + DX, CY + DY, C, CopyPut);
   End;
 PdwEllipse(CX, CY, Radius, Radius, St, En);
 PdwLine(CX, CY, CX + Round(Radius * Cos(St * Pi / 180)), CY - Round(Radius * Sin(St * Pi / 180)));
 PdwLine(CX, CY, CX + Round(Radius * Cos(En * Pi / 180)), CY - Round(Radius * Sin(En * Pi / 180)));
End;

Function GraphErrorMsg(ErrorCode : Integer) : String;
Begin
 GraphErrorMsg := 'Presentation Manager';
End;

{ ---- images : [largeur][hauteur] (2 x LongInt) puis les pixels ---- }
Function ImageSize(X1, Y1, X2, Y2 : Integer) : LongInt;
Begin
 ImageSize := 8 + LongInt(Abs(X2 - X1) + 1) * (Abs(Y2 - Y1) + 1);
End;

Procedure GetImage(X1, Y1, X2, Y2 : Integer; Var BitMap);
Var P, W, H, X, Y, SX, SY : LongInt;
Begin
 W := X2 - X1 + 1; H := Y2 - Y1 + 1;
 P := LongInt(@BitMap);
 OsWrL(P, W); OsWrL(P + 4, H);
 P := P + 8;
 For Y := 0 To H - 1 Do
  For X := 0 To W - 1 Do
  Begin
   SX := X1 + PdwVP.X1 + X; SY := Y1 + PdwVP.Y1 + Y - OsOY;
   If (SX >= 0) And (SY >= 0) And (SX < PdwW) And (SY < PdwH) Then
    OsWrB(P, PdwFb^[(PdwH - 1 - SY) * PdwW + SX])
   Else OsWrB(P, 0);
   Inc(P);
  End;
End;

Procedure PutImage(X, Y : Integer; Var BitMap; BitBlt : Word);
Var P, W, H, I, J : LongInt;
Begin
 P := LongInt(@BitMap);
 W := OsPkB(P) Or (OsPkB(P + 1) Shl 8) Or (OsPkB(P + 2) Shl 16);
 H := OsPkB(P + 4) Or (OsPkB(P + 5) Shl 8) Or (OsPkB(P + 6) Shl 16);
 P := P + 8;
 For J := 0 To H - 1 Do
  For I := 0 To W - 1 Do
  Begin
   If BitBlt = XORPut Then
    PdwPlot(X + PdwVP.X1 + I, Y + PdwVP.Y1 + J, OsPkB(P), XORPut)
   Else
    PdwPlot(X + PdwVP.X1 + I, Y + PdwVP.Y1 + J, OsPkB(P), CopyPut);
   Inc(P);
  End;
End;

{ ---- palette (composantes 0..255) : RGB2 de BITMAPINFO2 (bleu, vert, rouge) ---- }
Procedure SetRGBPalette(ColorNum, Red, Green, Blue : Integer);
Var A : LongInt;
Begin
 If (ColorNum < 0) Or (ColorNum > 255) Then Exit;
 A := LongInt(@OsBmi) + 16 + ColorNum * 4;
 OsWrB(A, Blue And 255); OsWrB(A + 1, Green And 255); OsWrB(A + 2, Red And 255); OsWrB(A + 3, 0);
 PdwMark(0, 0, PdwW - 1, PdwH - 1);
End;

{ ---- mode graphique : la fenetre de WorDium ---- }
Function GraphResult : Integer;
Begin
 GraphResult := PdwResult;
End;

Function GetMaxX : Integer;
Begin
 GetMaxX := PdwW - 1;
End;

Function GetMaxY : Integer;
Begin
 GetMaxY := PdwH - 1 + OsOY;
End;

Procedure GetModeRange(GraphDriver : Integer; Var LoMode, HiMode : Integer);
Begin
 LoMode := m640x480;
 HiMode := mMaxScreen;
End;

Procedure PdwSetTitle(Const S : String);
Begin
 PdwTitle := S + #0;
 If OsFrame <> 0 Then OsDummy := WinSetWindowText(OsFrame, OsZs(S));
End;

{ titre de la fenetre (seulement s'il change) }
Procedure OsSetTitle(Const S : String);
Begin
 If PdwTitle <> S + #0 Then PdwSetTitle(S);
End;

Function OsBox(Title, Txt : String; Fl : LongInt) : LongInt;
Begin
 PdwFlush;
 OsPutZ(LongInt(@OsTxt), Txt);
 OsBox := WinMessageBox(HWND_DESKTOP, OsFrame, LongInt(@OsTxt), OsZs(Title), 0, Fl Or MB_MOVEABLE);
End;

{ --- gabarit de la barre de menus (MENUTEMPLATE) --- }
Procedure OsMnB(V : LongInt);
Begin
 OsMenuT[OsMenuLen] := V And 255;
 Inc(OsMenuLen);
End;

Procedure OsMnW(V : LongInt);
Begin
 OsMnB(V And 255); OsMnB((V Shr 8) And 255);
End;

Function OsMnOpen : LongInt;
Begin
 OsMnOpen := OsMenuLen;
 OsMnW(0); OsMnW(0); OsMnW(0);
End;

Procedure OsMnClose(H, Count : LongInt);
Begin
 OsWrW(LongInt(@OsMenuT) + H, OsMenuLen - H);
 OsWrW(LongInt(@OsMenuT) + H + 4, Count);
End;

Procedure OsMnItem(Style, Attr, Id : LongInt; S : String);
Var K : LongInt;
Begin
 OsMnW(Style); OsMnW(Attr); OsMnW(Id);
 If (Style And MIS_SEPARATOR) = 0 Then
 Begin
  For K := 1 To Length(S) Do OsMnB(Ord(S[K]));
  OsMnB(0);
 End;
End;

Procedure InitGraph(Var GraphDriver, GraphMode : Integer; Const PathToDriver : String);
Var Fl, Sw, Sh, H0, I, V, A, Fw, Fh : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 PdwResult := grOk;
 OsHab := WinInitialize(0);
 OsHmq := WinCreateMsgQueue(OsHab, 64);
 OsDummy := WinRegisterClass(OsHab, OsZs('WORDIUM'), LongInt(@OsClientProc), 0, 0);
 { WorDium est dessine pour 640 x 480, sa barre de menus comprise : la
   barre de menus de PM la remplace (zone client de 640 x 461). La
   fenetre a un cadre si le bureau a au moins 800 x 600 ; sur un bureau
   plus petit, elle n'a que la barre de menus de PM, en haut de l'ecran }
 Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
 OsSmall := (Sh < 540) Or (Sw < 660);
 If OsSmall Then Fl := FCF_TASKLIST
 Else Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_TASKLIST Or FCF_DLGBORDER;
 OsClient := 0;
 PdwTitle := 'WorDium'#0;
 OsFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), OsZs('WORDIUM'), OsZs2('WorDium'),
                               0, 0, 0, LongInt(@OsClient));
 If OsFrame = 0 Then Begin PdwResult := -1; Exit End;
 { barre de menus provisoire (pour la taille de la zone client) }
 OsMenuLen := 0;
 H0 := OsMnOpen;
 OsMnItem(MIS_TEXT, 0, OS_MENUID - 1, '~Fichier');
 OsMnClose(H0, 1);
 OsDummy := WinCreateMenu(OsFrame, LongInt(@OsMenuT));
 OsMenuSig := -1;
 { zone client : 640 x 461 (les 19 lignes de la barre de menus de
   WorDium sont cachees) ; sur un petit bureau, ce qui reste sous la
   barre de menus de PM (le haut de la barre d'outils est alors cache) }
 Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
 Rc[0] := 0; Rc[1] := 0; Rc[2] := Sw; Rc[3] := Sh;
 OsDummy := WinCalcFrameRect(OsFrame, LongInt(@Rc), 1);
 PdwW := 640; PdwH := Rc[3] - Rc[1];
 If (PdwH > 461) Or (PdwH < 400) Then PdwH := 461;
 OsOY := 480 - PdwH;
 PdwW := PdwW And Not 3;
 PdwFb := Nil;
 If DosAllocMem(LongInt(@PdwFb), PdwW * PdwH, $13) <> 0 Then Begin PdwResult := -1; Exit End;
 FillChar(PdwFb^, PdwW * PdwH, 0);
 { BITMAPINFOHEADER2 (16 octets) et palette : EGA, gris, cube 6 x 6 x 6 }
 FillChar(OsBmi, SizeOf(OsBmi), 0);
 OsWrL(LongInt(@OsBmi), 16);
 OsWrL(LongInt(@OsBmi) + 4, PdwW);
 OsWrL(LongInt(@OsBmi) + 8, PdwH);
 OsWrW(LongInt(@OsBmi) + 12, 1);
 OsWrW(LongInt(@OsBmi) + 14, 8);
 For I := 0 To 15 Do
  SetRGBPalette(I, (PdwEga[I] Shr 16) And 255, (PdwEga[I] Shr 8) And 255, PdwEga[I] And 255);
 For I := 16 To 31 Do
 Begin
  V := (I - 16) * 17;
  SetRGBPalette(I, V, V, V);
 End;
 For I := 32 To 247 Do
  SetRGBPalette(I, ((I - 32) Div 36) * 51, (((I - 32) Div 6) Mod 6) * 51, ((I - 32) Mod 6) * 51);
 PdwVP.X1 := 0; PdwVP.Y1 := 0; PdwVP.X2 := PdwW - 1; PdwVP.Y2 := PdwH - 1 + OsOY;
 PdwCharSize := 1;
 PdwVP.Clip := True;
 PdwColor := White; PdwFillColor := White; PdwFillStyle := SolidFill;
 PdwLineStyle := SolidLn; PdwLinePat := $FFFF; PdwThick := NormWidth;
 PdwWrite := CopyPut;
 PdwDirty := False;
 { fenetre centree en haut du bureau }
 Rc[0] := 0; Rc[1] := 0; Rc[2] := PdwW; Rc[3] := PdwH;
 OsDummy := WinCalcFrameRect(OsFrame, LongInt(@Rc), 0);
 Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
 A := (Sw - Fw) Div 2; If A < 0 Then A := 0;
 V := (Sh - Fh) Div 2; If V < 0 Then V := 0;
 If OsSmall Then Begin A := 0; V := Sh - Fh; If V < 0 Then V := 0; End;
 OsDummy := WinSetWindowPos(OsFrame, HWND_TOP, A, V, Fw, Fh,
                            SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
 OsDummy := WinSetFocus(HWND_DESKTOP, OsClient);
 OsOpenTick := KTicks; OsRepaints := 0;
 PdwKHead := 0; PdwKTail := 0; OsCHead := 0; OsCTail := 0; OsQuit := False;
 PdwMB := 0; PdwMBLatch := 0;
 GraphDriver := D8bit;
End;

Procedure CloseGraph;
Begin
 If OsFrame = 0 Then Exit;
 OsDummy := WinDestroyWindow(OsFrame);
 OsFrame := 0; OsClient := 0;
End;



{ ============================================================ }
{ ===================  LANGUES (FR EN ES IT DE)  ============= }
{ ============================================================ }
{ Langue de l'interface : variable d'environnement LANGUAGE.   }
{   EN = anglais, ES = espagnol, IT = italien, GR (ou DE) =     }
{   allemand, FR (ou absente) = francais (par defaut).          }
{ Tr(Texte) retourne la traduction du texte source (la cle).    }
{ Les textes sont en CP437 (police de l'ecran graphique).       }

Const
 LANG_FR = 0;
 LANG_EN = 1;
 LANG_ES = 2;
 LANG_IT = 3;
 LANG_DE = 4;
 TR_COUNT = 282;

Type
 TTrRow = Record
  K : String[255];                       { cle (texte source) }
  V : Array[0..4] Of String[255];        { FR, EN, ES, IT, DE }
 End;

Const
 TrTab : Array[1..TR_COUNT] Of TTrRow = (
  (K: '&Fichier';
   V: ('&Fichier',
    '&File',
    '&Archivo',
    '&File',
    '&Datei')),
  (K: '&Edition';
   V: ('&'#144'dition',
    '&Edit',
    '&Edici'#162'n',
    '&Modifica',
    '&Bearbeiten')),
  (K: '&Affichage';
   V: ('&Affichage',
    '&View',
    '&Ver',
    '&Visualizza',
    '&Ansicht')),
  (K: '&Insertion';
   V: ('&Insertion',
    '&Insert',
    '&Insertar',
    '&Inserisci',
    'E&inf'#129'gen')),
  (K: 'F&ormat';
   V: ('F&ormat',
    'F&ormat',
    'F&ormato',
    'F&ormato',
    'F&ormat')),
  (K: 'O&utils';
   V: ('O&utils',
    '&Tools',
    '&Herramientas',
    'S&trumenti',
    'E&xtras')),
  (K: '&Tableau';
   V: ('&Tableau',
    'T&able',
    '&Tabla',
    'Ta&bella',
    '&Tabelle')),
  (K: 'Fe&netre';
   V: ('Fe&n'#136'tre',
    '&Window',
    'Ve&ntana',
    'Fi&nestra',
    'Fe&nster')),
  (K: 'Ai&de';
   V: ('Ai&de',
    '&Help',
    'A&yuda',
    'Ai&uto',
    '&Hilfe')),
  (K: 'Accu&eil';
   V: ('Accu&eil',
    'Ho&me',
    'Ini&cio',
    'Ho&me',
    '&Start')),
  (K: '&Nouveau';
   V: ('&Nouveau',
    '&New',
    '&Nuevo',
    '&Nuovo',
    '&Neu')),
  (K: '&Ouvrir...';
   V: ('&Ouvrir...',
    '&Open...',
    '&Abrir...',
    '&Apri...',
    #153'&ffnen...')),
  (K: '&Enregistrer';
   V: ('&Enregistrer',
    '&Save',
    '&Guardar',
    '&Salva',
    '&Speichern')),
  (K: 'Enregistrer &sous...';
   V: ('Enregistrer &sous...',
    'Save &As...',
    'Guardar &como...',
    'Salva con n&ome...',
    'Speichern &unter...')),
  (K: '&Imprimer...';
   V: ('&Imprimer...',
    '&Print...',
    '&Imprimir...',
    'S&tampa...',
    '&Drucken...')),
  (K: '&Quitter';
   V: ('&Quitter',
    'E&xit',
    '&Salir',
    '&Esci',
    '&Beenden')),
  (K: '&Annuler';
   V: ('&Annuler',
    'U&ndo',
    '&Deshacer',
    'A&nnulla',
    '&R'#129'ckg'#132'ngig')),
  (K: '&Retablir';
   V: ('&R'#130'tablir',
    '&Redo',
    '&Rehacer',
    '&Ripristina',
    'Wiederh&olen')),
  (K: 'Co&uper';
   V: ('Co&uper',
    'Cu&t',
    'Cor&tar',
    'Ta&glia',
    'Aus&schneiden')),
  (K: '&Copier';
   V: ('&Copier',
    '&Copy',
    '&Copiar',
    '&Copia',
    '&Kopieren')),
  (K: 'Co&ller';
   V: ('Co&ller',
    '&Paste',
    '&Pegar',
    '&Incolla',
    '&Einf'#129'gen')),
  (K: 'Rec&hercher...';
   V: ('Rec&hercher...',
    '&Find...',
    '&Buscar...',
    '&Trova...',
    'S&uchen...')),
  (K: 'Rechercher &suivant';
   V: ('Rechercher &suivant',
    'Find Ne&xt',
    'Buscar &siguiente',
    'Trova &successivo',
    '&Weitersuchen')),
  (K: 'Re&mplacer...';
   V: ('Re&mplacer...',
    'Rep&lace...',
    'Reemp&lazar...',
    'Sostit&uisci...',
    'Erse&tzen...')),
  (K: '&Normal';
   V: ('&Normal',
    '&Normal',
    '&Normal',
    '&Normale',
    '&Normal')),
  (K: '&Mise en page';
   V: ('&Mise en page',
    '&Page Layout',
    '&Dise'#164'o de p'#160'gina',
    '&Layout di pagina',
    '&Seitenlayout')),
  (K: '&Regle';
   V: ('&R'#138'gle',
    '&Ruler',
    '&Regla',
    '&Righello',
    '&Lineal')),
  (K: '&Zoom...';
   V: ('&Zoom...',
    '&Zoom...',
    '&Zoom...',
    '&Zoom...',
    '&Zoom...')),
  (K: '&Saut de page';
   V: ('&Saut de page',
    '&Page Break',
    '&Salto de p'#160'gina',
    'Interruzione di &pagina',
    '&Seitenumbruch')),
  (K: '&Image...';
   V: ('&Image...',
    'Pi&cture...',
    '&Imagen...',
    '&Immagine...',
    '&Bild...')),
  (K: 'Symbo&le...';
   V: ('Symbo&le...',
    'S&ymbol...',
    'S'#161'mbo&lo...',
    'Si&mbolo...',
    'Sy&mbol...')),
  (K: '&Tableau...';
   V: ('&Tableau...',
    '&Table...',
    '&Tabla...',
    '&Tabella...',
    '&Tabelle...')),
  (K: '&Police...';
   V: ('&Police...',
    '&Font...',
    '&Fuente...',
    '&Carattere...',
    '&Schriftart...')),
  (K: 'Para&graphe...';
   V: ('Para&graphe...',
    '&Paragraph...',
    '&P'#160'rrafo...',
    '&Paragrafo...',
    '&Absatz...')),
  (K: 'G&ras';
   V: ('G&ras',
    '&Bold',
    '&Negrita',
    '&Grassetto',
    '&Fett')),
  (K: '&Italique';
   V: ('&Italique',
    '&Italic',
    'C&ursiva',
    'Cor&sivo',
    '&Kursiv')),
  (K: '&Souligne';
   V: ('&Soulign'#130,
    '&Underline',
    '&Subrayado',
    'S&ottolineato',
    '&Unterstrichen')),
  (K: 'Aligner a g&auche';
   V: ('Aligner '#133' g&auche',
    'Align &Left',
    'Alinear a la &izquierda',
    'Allinea a si&nistra',
    '&Linksb'#129'ndig')),
  (K: '&Centrer';
   V: ('&Centrer',
    '&Center',
    'C&entrar',
    'Allinea al c&entro',
    '&Zentriert')),
  (K: 'Aligner a &droite';
   V: ('Aligner '#133' &droite',
    'Align &Right',
    'Alinear a la &derecha',
    'Allinea a &destra',
    '&Rechtsb'#129'ndig')),
  (K: '&Orthographe...';
   V: ('&Orthographe...',
    '&Spelling...',
    '&Ortograf'#161'a...',
    '&Ortografia...',
    '&Rechtschreibung...')),
  (K: 'Stat&istiques...';
   V: ('Stat&istiques...',
    'S&tatistics...',
    'E&stad'#161'sticas...',
    'S&tatistiche...',
    '&Statistik...')),
  (K: 'O&ptions...';
   V: ('O&ptions...',
    '&Options...',
    'Opcio&nes...',
    'Op&zioni...',
    'O&ptionen...')),
  (K: '&Inserer un tableau...';
   V: ('&Ins'#130'rer un tableau...',
    '&Insert Table...',
    '&Insertar tabla...',
    '&Inserisci tabella...',
    'Tabelle &einf'#129'gen...')),
  (K: '&Supprimer le tableau';
   V: ('&Supprimer le tableau',
    '&Delete Table',
    '&Eliminar tabla',
    '&Elimina tabella',
    'Tabelle &l'#148'schen')),
  (K: '&Cascade';
   V: ('&Cascade',
    '&Cascade',
    '&Cascada',
    '&Cascata',
    '&Kaskade')),
  (K: '&Sommaire...';
   V: ('&Sommaire...',
    '&Contents...',
    '&Contenido...',
    'S&ommario...',
    '&Inhalt...')),
  (K: 'A &propos...';
   V: ('A &propos...',
    '&About...',
    'Acerca &de...',
    '&Informazioni su...',
    #154'&ber...')),
  (K: 'Suivant';
   V: ('Suivant',
    'Next',
    'Siguiente',
    'Successivo',
    'Weiter')),
  (K: 'Gauche';
   V: ('Gauche',
    'Left',
    'Izquierda',
    'Sinistra',
    'Links')),
  (K: 'Centrer';
   V: ('Centrer',
    'Center',
    'Centrar',
    'Centra',
    'Zentriert')),
  (K: 'Droite';
   V: ('Droite',
    'Right',
    'Derecha',
    'Destra',
    'Rechts')),
  (K: 'Justifier';
   V: ('Justifier',
    'Justify',
    'Justificar',
    'Giustifica',
    'Blocksatz')),
  (K: '&Justifier';
   V: ('&Justifier',
    '&Justify',
    '&Justificar',
    'Giusti&fica',
    '&Blocksatz')),
  (K: 'New (Ctrl+N)';
   V: ('Nouveau (Ctrl+N)',
    'New (Ctrl+N)',
    'Nuevo (Ctrl+N)',
    'Nuovo (Ctrl+N)',
    'Neu (Strg+N)')),
  (K: 'Open (Ctrl+O)';
   V: ('Ouvrir (Ctrl+O)',
    'Open (Ctrl+O)',
    'Abrir (Ctrl+O)',
    'Apri (Ctrl+O)',
    #153'ffnen (Strg+O)')),
  (K: 'Save (Ctrl+S)';
   V: ('Enregistrer (Ctrl+S)',
    'Save (Ctrl+S)',
    'Guardar (Ctrl+S)',
    'Salva (Ctrl+S)',
    'Speichern (Strg+S)')),
  (K: 'Print (Ctrl+P)';
   V: ('Imprimer (Ctrl+P)',
    'Print (Ctrl+P)',
    'Imprimir (Ctrl+P)',
    'Stampa (Ctrl+P)',
    'Drucken (Strg+P)')),
  (K: 'Cut (Ctrl+X)';
   V: ('Couper (Ctrl+X)',
    'Cut (Ctrl+X)',
    'Cortar (Ctrl+X)',
    'Taglia (Ctrl+X)',
    'Ausschneiden (Strg+X)')),
  (K: 'Copy (Ctrl+C)';
   V: ('Copier (Ctrl+C)',
    'Copy (Ctrl+C)',
    'Copiar (Ctrl+C)',
    'Copia (Ctrl+C)',
    'Kopieren (Strg+C)')),
  (K: 'Paste (Ctrl+V)';
   V: ('Coller (Ctrl+V)',
    'Paste (Ctrl+V)',
    'Pegar (Ctrl+V)',
    'Incolla (Ctrl+V)',
    'Einf'#129'gen (Strg+V)')),
  (K: 'Undo (Ctrl+Z)';
   V: ('Annuler (Ctrl+Z)',
    'Undo (Ctrl+Z)',
    'Deshacer (Ctrl+Z)',
    'Annulla (Ctrl+Z)',
    'R'#129'ckg'#132'ngig (Strg+Z)')),
  (K: 'Redo (Ctrl+Y)';
   V: ('R'#130'tablir (Ctrl+Y)',
    'Redo (Ctrl+Y)',
    'Rehacer (Ctrl+Y)',
    'Ripristina (Ctrl+Y)',
    'Wiederholen (Strg+Y)')),
  (K: 'Insert Picture';
   V: ('Ins'#130'rer une image',
    'Insert Picture',
    'Insertar imagen',
    'Inserisci immagine',
    'Bild einf'#129'gen')),
  (K: 'Insert Table';
   V: ('Ins'#130'rer un tableau',
    'Insert Table',
    'Insertar tabla',
    'Inserisci tabella',
    'Tabelle einf'#129'gen')),
  (K: 'Bold (Ctrl+B)';
   V: ('Gras (Ctrl+B)',
    'Bold (Ctrl+B)',
    'Negrita (Ctrl+B)',
    'Grassetto (Ctrl+B)',
    'Fett (Strg+B)')),
  (K: 'Italic (Ctrl+I)';
   V: ('Italique (Ctrl+I)',
    'Italic (Ctrl+I)',
    'Cursiva (Ctrl+I)',
    'Corsivo (Ctrl+I)',
    'Kursiv (Strg+I)')),
  (K: 'Underline (Ctrl+U)';
   V: ('Soulign'#130' (Ctrl+U)',
    'Underline (Ctrl+U)',
    'Subrayado (Ctrl+U)',
    'Sottolineato (Ctrl+U)',
    'Unterstrichen (Strg+U)')),
  (K: 'Align Left';
   V: ('Aligner '#133' gauche',
    'Align Left',
    'Alinear a la izquierda',
    'Allinea a sinistra',
    'Linksb'#129'ndig')),
  (K: 'Align Center';
   V: ('Centrer',
    'Align Center',
    'Centrar',
    'Centra',
    'Zentriert')),
  (K: 'Align Right';
   V: ('Aligner '#133' droite',
    'Align Right',
    'Alinear a la derecha',
    'Allinea a destra',
    'Rechtsb'#129'ndig')),
  (K: 'Justify';
   V: ('Justifier',
    'Justify',
    'Justificar',
    'Giustifica',
    'Blocksatz')),
  (K: 'Inserer ligne au-dessus';
   V: ('Ins'#130'rer une ligne au-dessus',
    'Insert row above',
    'Insertar fila arriba',
    'Inserisci riga sopra',
    'Zeile oberhalb einf'#129'gen')),
  (K: 'Inserer ligne en-dessous';
   V: ('Ins'#130'rer une ligne en dessous',
    'Insert row below',
    'Insertar fila abajo',
    'Inserisci riga sotto',
    'Zeile unterhalb einf'#129'gen')),
  (K: 'Supprimer la ligne';
   V: ('Supprimer la ligne',
    'Delete row',
    'Eliminar fila',
    'Elimina riga',
    'Zeile l'#148'schen')),
  (K: 'Inserer colonne a gauche';
   V: ('Ins'#130'rer une colonne '#133' gauche',
    'Insert column left',
    'Insertar columna a la izquierda',
    'Inserisci colonna a sinistra',
    'Spalte links einf'#129'gen')),
  (K: 'Inserer colonne a droite';
   V: ('Ins'#130'rer une colonne '#133' droite',
    'Insert column right',
    'Insertar columna a la derecha',
    'Inserisci colonna a destra',
    'Spalte rechts einf'#129'gen')),
  (K: 'Supprimer la colonne';
   V: ('Supprimer la colonne',
    'Delete column',
    'Eliminar columna',
    'Elimina colonna',
    'Spalte l'#148'schen')),
  (K: 'Proprietes du tableau...';
   V: ('Propri'#130't'#130's du tableau...',
    'Table properties...',
    'Propiedades de la tabla...',
    'Propriet'#133' tabella...',
    'Tabelleneigenschaften...')),
  (K: 'Tableau plein (max 16 lignes).';
   V: ('Tableau plein (max 16 lignes).',
    'Table full (max 16 rows).',
    'Tabla llena (m'#160'x. 16 filas).',
    'Tabella piena (max 16 righe).',
    'Tabelle voll (max. 16 Zeilen).')),
  (K: 'Impossible : le tableau n''a qu''une ligne.';
   V: ('Impossible : le tableau n''a qu''une ligne.',
    'Not possible: the table has only one row.',
    'Imposible: la tabla solo tiene una fila.',
    'Impossibile: la tabella ha una sola riga.',
    'Nicht m'#148'glich: Die Tabelle hat nur eine Zeile.')),
  (K: 'Tableau plein (max 6 colonnes).';
   V: ('Tableau plein (max 6 colonnes).',
    'Table full (max 6 columns).',
    'Tabla llena (m'#160'x. 6 columnas).',
    'Tabella piena (max 6 colonne).',
    'Tabelle voll (max. 6 Spalten).')),
  (K: 'Impossible : le tableau n''a qu''une colonne.';
   V: ('Impossible : le tableau n''a qu''une colonne.',
    'Not possible: the table has only one column.',
    'Imposible: la tabla solo tiene una columna.',
    'Impossibile: la tabella ha una sola colonna.',
    'Nicht m'#148'glich: Die Tabelle hat nur eine Spalte.')),
  (K: 'Tableau : ';
   V: ('Tableau : ',
    'Table: ',
    'Tabla: ',
    'Tabella: ',
    'Tabelle: ')),
  (K: ' lignes x ';
   V: (' lignes x ',
    ' rows x ',
    ' filas x ',
    ' righe x ',
    ' Zeilen x ')),
  (K: ' colonnes';
   V: (' colonnes',
    ' columns',
    ' columnas',
    ' colonne',
    ' Spalten')),
  (K: 'Page ';
   V: ('Page ',
    'Page ',
    'P'#160'gina ',
    'Pagina ',
    'Seite ')),
  (K: ' of ';
   V: (' sur ',
    ' of ',
    ' de ',
    ' di ',
    ' von ')),
  (K: 'Ln ';
   V: ('Lig ',
    'Ln ',
    'L'#161'n ',
    'Rg ',
    'Z ')),
  (K: '  Col ';
   V: ('  Col ',
    '  Col ',
    '  Col ',
    '  Col ',
    '  Sp ')),
  (K: 'Yes';
   V: ('Oui',
    'Yes',
    'S'#161,
    'S'#141,
    'Ja')),
  (K: 'No';
   V: ('Non',
    'No',
    'No',
    'No',
    'Nein')),
  (K: 'Repertoire :';
   V: ('R'#130'pertoire :',
    'Directory:',
    'Directorio:',
    'Cartella:',
    'Verzeichnis:')),
  (K: 'Fichiers :';
   V: ('Fichiers :',
    'Files:',
    'Archivos:',
    'File:',
    'Dateien:')),
  (K: 'Nom :';
   V: ('Nom :',
    'Name:',
    'Nombre:',
    'Nome:',
    'Dateiname:')),
  (K: 'Save';
   V: ('Enregistrer',
    'Save',
    'Guardar',
    'Salva',
    'Speichern')),
  (K: 'Open';
   V: ('Ouvrir',
    'Open',
    'Abrir',
    'Apri',
    #153'ffnen')),
  (K: 'Cancel';
   V: ('Annuler',
    'Cancel',
    'Cancelar',
    'Annulla',
    'Abbrechen')),
  (K: 'Pages';
   V: ('Pages',
    'Pages',
    'P'#160'ginas',
    'Pagine',
    'Seiten')),
  (K: 'Mots';
   V: ('Mots',
    'Words',
    'Palabras',
    'Parole',
    'W'#148'rter')),
  (K: 'Caract'#138'res (avec espaces)';
   V: ('Caract'#138'res (avec espaces)',
    'Characters (with spaces)',
    'Caracteres (con espacios)',
    'Caratteri (con spazi)',
    'Zeichen (mit Leerzeichen)')),
  (K: 'Caract'#138'res (sans espaces)';
   V: ('Caract'#138'res (sans espaces)',
    'Characters (no spaces)',
    'Caracteres (sin espacios)',
    'Caratteri (senza spazi)',
    'Zeichen (ohne Leerzeichen)')),
  (K: 'Paragraphes';
   V: ('Paragraphes',
    'Paragraphs',
    'P'#160'rrafos',
    'Paragrafi',
    'Abs'#132'tze')),
  (K: 'Lignes de texte';
   V: ('Lignes de texte',
    'Text lines',
    'L'#161'neas de texto',
    'Righe di testo',
    'Textzeilen')),
  (K: 'Tableaux';
   V: ('Tableaux',
    'Tables',
    'Tablas',
    'Tabelle',
    'Tabellen')),
  (K: 'Cellules';
   V: ('Cellules',
    'Cells',
    'Celdas',
    'Celle',
    'Zellen')),
  (K: 'Images';
   V: ('Images',
    'Images',
    'Im'#160'genes',
    'Immagini',
    'Bilder')),
  (K: 'Statistiques du document';
   V: ('Statistiques du document',
    'Document statistics',
    'Estad'#161'sticas del documento',
    'Statistiche del documento',
    'Dokumentstatistik')),
  (K: 'Mesure';
   V: ('Mesure',
    'Measure',
    'Medida',
    'Misura',
    'Messwert')),
  (K: 'Total';
   V: ('Total',
    'Total',
    'Total',
    'Totale',
    'Gesamt')),
  (K: 'Valeurs relatives';
   V: ('Valeurs relatives',
    'Relative values',
    'Valores relativos',
    'Valori relativi',
    'Relative Werte')),
  (K: 'Unites differentes';
   V: ('Unit'#130's diff'#130'rentes',
    'Different units',
    'Unidades diferentes',
    'Unit'#133' diverse',
    'Verschiedene Einheiten')),
  (K: 'Fermer';
   V: ('Fermer',
    'Close',
    'Cerrar',
    'Chiudi',
    'Schlie'#225'en')),
  (K: 'Nothing to undo';
   V: ('Rien '#133' annuler',
    'Nothing to undo',
    'Nada que deshacer',
    'Niente da annullare',
    'Nichts zum R'#129'ckg'#132'ngigmachen')),
  (K: 'Undo';
   V: ('Annulation',
    'Undo',
    'Deshacer',
    'Annulla',
    'R'#129'ckg'#132'ngig')),
  (K: 'Nothing to redo';
   V: ('Rien '#133' r'#130'tablir',
    'Nothing to redo',
    'Nada que rehacer',
    'Niente da ripristinare',
    'Nichts zum Wiederholen')),
  (K: 'Redo';
   V: ('R'#130'tablissement',
    'Redo',
    'Rehacer',
    'Ripristina',
    'Wiederholen')),
  (K: 'Find';
   V: ('Rechercher',
    'Find',
    'Buscar',
    'Trova',
    'Suchen')),
  (K: 'Find what:';
   V: ('Rechercher :',
    'Find what:',
    'Buscar:',
    'Trova:',
    'Suchen nach:')),
  (K: 'Found: ';
   V: ('Trouv'#130' : ',
    'Found: ',
    'Encontrado: ',
    'Trovato: ',
    'Gefunden: ')),
  (K: 'Not found: ';
   V: ('Introuvable : ',
    'Not found: ',
    'No encontrado: ',
    'Non trovato: ',
    'Nicht gefunden: ')),
  (K: 'No more matches';
   V: ('Plus aucune occurrence',
    'No more matches',
    'No hay m'#160's coincidencias',
    'Nessun''altra corrispondenza',
    'Keine weiteren Treffer')),
  (K: 'Replace';
   V: ('Remplacer',
    'Replace',
    'Reemplazar',
    'Sostituisci',
    'Ersetzen')),
  (K: 'Replace with:';
   V: ('Remplacer par :',
    'Replace with:',
    'Reemplazar con:',
    'Sostituisci con:',
    'Ersetzen durch:')),
  (K: 'Replace All? (Y/N)';
   V: ('Tout remplacer ? (O/N)',
    'Replace All? (Y/N)',
    #168'Reemplazar todo? (S/N)',
    'Sostituire tutto? (S/N)',
    'Alle ersetzen? (J/N)')),
  (K: ' replacement(s)';
   V: (' remplacement(s)',
    ' replacement(s)',
    ' reemplazo(s)',
    ' sostituzione/i',
    ' Ersetzung(en)')),
  (K: 'Replaced';
   V: ('Remplac'#130,
    'Replaced',
    'Reemplazado',
    'Sostituito',
    'Ersetzt')),
  (K: 'Zoom';
   V: ('Zoom',
    'Zoom',
    'Zoom',
    'Zoom',
    'Zoom')),
  (K: 'Pourcentage (25 a 300 %) :';
   V: ('Pourcentage (25 '#133' 300 %) :',
    'Percentage (25 to 300 %):',
    'Porcentaje (25 a 300 %):',
    'Percentuale (25-300 %):',
    'Prozent (25 bis 300 %):')),
  (K: 'Page';
   V: ('Page',
    'Page',
    'P'#160'gina',
    'Pagina',
    'Seite')),
  (K: 'Largeur';
   V: ('Largeur',
    'Width',
    'Ancho',
    'Larghezza',
    'Breite')),
  (K: 'Annuler';
   V: ('Annuler',
    'Cancel',
    'Cancelar',
    'Annulla',
    'Abbrechen')),
  (K: 'Insertion de symbole';
   V: ('Insertion de symbole',
    'Insert Symbol',
    'Insertar s'#161'mbolo',
    'Inserisci simbolo',
    'Symbol einf'#129'gen')),
  (K: 'Choisir un caractere CP437';
   V: ('Choisir un caract'#138're CP437',
    'Choose a CP437 character',
    'Elegir un car'#160'cter CP437',
    'Scegli un carattere CP437',
    'Zeichen CP437 w'#132'hlen')),
  (K: 'Apercu : ';
   V: ('Aper'#135'u : ',
    'Preview: ',
    'Vista previa: ',
    'Anteprima: ',
    'Vorschau: ')),
  (K: 'Inserer';
   V: ('Ins'#130'rer',
    'Insert',
    'Insertar',
    'Inserisci',
    'Einf'#129'gen')),
  (K: 'Cette cellule est pleine.';
   V: ('Cette cellule est pleine.',
    'This cell is full.',
    'Esta celda est'#160' llena.',
    'Questa cella '#138' piena.',
    'Diese Zelle ist voll.')),
  (K: 'Ce paragraphe est plein.';
   V: ('Ce paragraphe est plein.',
    'This paragraph is full.',
    'Este p'#160'rrafo est'#160' lleno.',
    'Questo paragrafo '#138' pieno.',
    'Dieser Absatz ist voll.')),
  (K: 'Insertion impossible : trop de segments de style.';
   V: ('Insertion impossible : trop de segments de style.',
    'Cannot insert: too many style segments.',
    'Inserci'#162'n imposible: demasiados segmentos de estilo.',
    'Inserimento impossibile: troppi segmenti di stile.',
    'Einf'#129'gen nicht m'#148'glich: zu viele Formatsegmente.')),
  (K: 'Gras';
   V: ('Gras',
    'Bold',
    'Negrita',
    'Grassetto',
    'Fett')),
  (K: 'Italique';
   V: ('Italique',
    'Italic',
    'Cursiva',
    'Corsivo',
    'Kursiv')),
  (K: 'Souligne';
   V: ('Soulign'#130,
    'Underline',
    'Subrayado',
    'Sottolineato',
    'Unterstrichen')),
  (K: 'Police';
   V: ('Police',
    'Font',
    'Fuente',
    'Carattere',
    'Schriftart')),
  (K: 'Taille (6 a 72 pt)';
   V: ('Taille (6 '#133' 72 pt)',
    'Size (6 to 72 pt)',
    'Tama'#164'o (6 a 72 pt)',
    'Dimensione (6-72 pt)',
    'Gr'#148#225'e (6 bis 72 pt)')),
  (K: 'Tab : option   Espace : ouvrir / basculer';
   V: ('Tab : option   Espace : ouvrir / basculer',
    'Tab: option   Space: open / toggle',
    'Tab: opci'#162'n   Espacio: abrir / alternar',
    'Tab: opzione   Spazio: apri / alterna',
    'Tab: Option   Leertaste: '#148'ffnen / umschalten')),
  (K: 'Appliquer';
   V: ('Appliquer',
    'Apply',
    'Aplicar',
    'Applica',
    #154'bernehmen')),
  (K: 'Les cellules utilisent une police fixe.';
   V: ('Les cellules utilisent une police fixe.',
    'Table cells use a fixed font.',
    'Las celdas usan una fuente fija.',
    'Le celle usano un carattere fisso.',
    'Zellen verwenden eine feste Schriftart.')),
  (K: 'Selection trop fragmentee pour appliquer la police.';
   V: ('S'#130'lection trop fragment'#130'e pour appliquer la police.',
    'Selection too fragmented to apply the font.',
    'Selecci'#162'n demasiado fragmentada para la fuente.',
    'Selezione troppo frammentata per il carattere.',
    'Auswahl zu fragmentiert f'#129'r die Schriftart.')),
  (K: 'Centre';
   V: ('Centre',
    'Center',
    'Centro',
    'Centro',
    'Zentriert')),
  (K: 'Justifie';
   V: ('Justifi'#130,
    'Justified',
    'Justificado',
    'Giustificato',
    'Blocksatz')),
  (K: 'Paragraphe';
   V: ('Paragraphe',
    'Paragraph',
    'P'#160'rrafo',
    'Paragrafo',
    'Absatz')),
  (K: 'Retrait gauche (0 a 160 px)';
   V: ('Retrait gauche (0 '#133' 160 px)',
    'Left indent (0 to 160 px)',
    'Sangr'#161'a izquierda (0 a 160 px)',
    'Rientro sinistro (0-160 px)',
    'Linker Einzug (0 bis 160 px)')),
  (K: '] Inclure la premiere ligne';
   V: ('] Inclure la premi'#138're ligne',
    '] Include first line',
    '] Incluir la primera l'#161'nea',
    '] Includi la prima riga',
    '] Erste Zeile einbeziehen')),
  (K: '] Bordure inferieure';
   V: ('] Bordure inf'#130'rieure',
    '] Bottom border',
    '] Borde inferior',
    '] Bordo inferiore',
    '] Untere Linie')),
  (K: '] Saut de page avant';
   V: ('] Saut de page avant',
    '] Page break before',
    '] Salto de p'#160'gina antes',
    '] Interruzione pagina prima',
    '] Seitenumbruch davor')),
  (K: 'Saisir un retrait de 0 a 160 px.';
   V: ('Saisir un retrait de 0 '#133' 160 px.',
    'Enter an indent from 0 to 160 px.',
    'Introduzca una sangr'#161'a de 0 a 160 px.',
    'Inserire un rientro da 0 a 160 px.',
    'Einzug von 0 bis 160 px eingeben.')),
  (K: 'Tab : option   Espace : basculer';
   V: ('Tab : option   Espace : basculer',
    'Tab: option   Space: toggle',
    'Tab: opci'#162'n   Espacio: alternar',
    'Tab: opzione   Spazio: alterna',
    'Tab: Option   Leertaste: umschalten')),
  (K: 'Choisir un paragraphe de texte.';
   V: ('Choisir un paragraphe de texte.',
    'Choose a text paragraph.',
    'Elija un p'#160'rrafo de texto.',
    'Scegli un paragrafo di testo.',
    'Textabsatz ausw'#132'hlen.')),
  (K: 'Orthographe - ';
   V: ('Orthographe - ',
    'Spelling - ',
    'Ortograf'#161'a - ',
    'Ortografia - ',
    'Rechtschreibung - ')),
  (K: 'Mot : ';
   V: ('Mot : ',
    'Word: ',
    'Palabra: ',
    'Parola: ',
    'Wort: ')),
  (K: 'Aucune suggestion';
   V: ('Aucune suggestion',
    'No suggestions',
    'Sin sugerencias',
    'Nessun suggerimento',
    'Keine Vorschl'#132'ge')),
  (K: 'Remplacer';
   V: ('Remplacer',
    'Replace',
    'Reemplazar',
    'Sostituisci',
    'Ersetzen')),
  (K: 'Ignorer';
   V: ('Ignorer',
    'Ignore',
    'Omitir',
    'Ignora',
    'Ignorieren')),
  (K: 'Correction trop longue pour ce paragraphe.';
   V: ('Correction trop longue pour ce paragraphe.',
    'Correction too long for this paragraph.',
    'Correcci'#162'n demasiado larga para este p'#160'rrafo.',
    'Correzione troppo lunga per questo paragrafo.',
    'Korrektur zu lang f'#129'r diesen Absatz.')),
  (K: 'Orthographe : ';
   V: ('Orthographe : ',
    'Spelling: ',
    'Ortograf'#161'a: ',
    'Ortografia: ',
    'Rechtschreibung: ')),
  (K: ' correction(s).';
   V: (' correction(s).',
    ' correction(s).',
    ' correcci'#162'n(es).',
    ' correzione/i.',
    ' Korrektur(en).')),
  (K: 'Automatique';
   V: ('Automatique',
    'Automatic',
    'Autom'#160'tico',
    'Automatico',
    'Automatisch')),
  (K: 'Francais';
   V: ('Fran'#135'ais',
    'French',
    'Franc'#130's',
    'Francese',
    'Franz'#148'sisch')),
  (K: 'Anglais';
   V: ('Anglais',
    'English',
    'Ingl'#130's',
    'Inglese',
    'Englisch')),
  (K: 'Allemand';
   V: ('Allemand',
    'German',
    'Alem'#160'n',
    'Tedesco',
    'Deutsch')),
  (K: 'Italien';
   V: ('Italien',
    'Italian',
    'Italiano',
    'Italiano',
    'Italienisch')),
  (K: 'Espagnol';
   V: ('Espagnol',
    'Spanish',
    'Espa'#164'ol',
    'Spagnolo',
    'Spanisch')),
  (K: 'Options';
   V: ('Options',
    'Options',
    'Opciones',
    'Opzioni',
    'Optionen')),
  (K: 'Affichage';
   V: ('Affichage',
    'Display',
    'Pantalla',
    'Visualizzazione',
    'Anzeige')),
  (K: 'Mode Page';
   V: ('Mode Page',
    'Page Mode',
    'Modo p'#160'gina',
    'Modalit'#133' pagina',
    'Seitenmodus')),
  (K: 'Afficher la regle';
   V: ('Afficher la r'#138'gle',
    'Show ruler',
    'Mostrar regla',
    'Mostra righello',
    'Lineal anzeigen')),
  (K: 'Langue du correcteur';
   V: ('Langue du correcteur',
    'Spell-check language',
    'Idioma del corrector',
    'Lingua del correttore',
    'Sprache der Pr'#129'fung')),
  (K: 'Automatique suit LANGUAGE (francais par defaut).';
   V: ('Automatique suit LANGUAGE (fran'#135'ais par d'#130'faut).',
    'Automatic follows LANGUAGE (French by default).',
    'Autom'#160'tico sigue LANGUAGE (franc'#130's por defecto).',
    'Automatico segue LANGUAGE (francese predefinito).',
    'Automatisch folgt LANGUAGE (Standard: Franz'#148'sisch).')),
  (K: 'Tab : option   Espace : choisir';
   V: ('Tab : option   Espace : choisir',
    'Tab: option   Space: choose',
    'Tab: opci'#162'n   Espacio: elegir',
    'Tab: opzione   Spazio: scegli',
    'Tab: Option   Leertaste: w'#132'hlen')),
  (K: 'Documents';
   V: ('Documents',
    'Documents',
    'Documentos',
    'Documenti',
    'Dokumente')),
  (K: 'Edition';
   V: (#144'dition',
    'Editing',
    'Edici'#162'n',
    'Modifica',
    'Bearbeiten')),
  (K: 'Insertion';
   V: ('Insertion',
    'Insert',
    'Insertar',
    'Inserimento',
    'Einf'#129'gen')),
  (K: 'Mise en forme';
   V: ('Mise en forme',
    'Formatting',
    'Formato',
    'Formattazione',
    'Formatierung')),
  (K: 'Orthographe';
   V: ('Orthographe',
    'Spelling',
    'Ortograf'#161'a',
    'Ortografia',
    'Rechtschreibung')),
  (K: 'Statistiques';
   V: ('Statistiques',
    'Statistics',
    'Estad'#161'sticas',
    'Statistiche',
    'Statistik')),
  (K: 'Sommaire de l''aide WorDium';
   V: ('Sommaire de l''aide WorDium',
    'WorDium Help Contents',
    'Contenido de la ayuda de WorDium',
    'Sommario della guida di WorDium',
    'WorDium-Hilfe'#129'bersicht')),
  (K: 'Fleches : choisir une rubrique';
   V: ('Fl'#138'ches : choisir une rubrique',
    'Arrows: choose a topic',
    'Flechas: elegir un tema',
    'Frecce: scegli un argomento',
    'Pfeile: Thema w'#132'hlen')),
  (K: 'A propos de WorDium';
   V: ('A propos de WorDium',
    'About WorDium',
    'Acerca de WorDium',
    'Informazioni su WorDium',
    #154'ber WorDium')),
  (K: 'Traitement de texte graphique en Pascal';
   V: ('Traitement de texte graphique en Pascal',
    'Graphical word processor in Pascal',
    'Procesador de textos gr'#160'fico en Pascal',
    'Elaboratore di testi grafico in Pascal',
    'Grafische Textverarbeitung in Pascal')),
  (K: 'Auteur';
   V: ('Auteur',
    'Author',
    'Autor',
    'Autore',
    'Autor')),
  (K: 'Licence';
   V: ('Licence',
    'License',
    'Licencia',
    'Licenza',
    'Lizenz')),
  (K: 'Creation';
   V: ('Cr'#130'ation',
    'Created',
    'Creaci'#162'n',
    'Creazione',
    'Erstellt')),
  (K: 'Site';
   V: ('Site',
    'Website',
    'Sitio web',
    'Sito web',
    'Website')),
  (K: 'Imprimante indisponible.';
   V: ('Imprimante indisponible.',
    'Printer unavailable.',
    'Impresora no disponible.',
    'Stampante non disponibile.',
    'Drucker nicht verf'#129'gbar.')),
  (K: 'Document transmis a l''imprimante.';
   V: ('Document transmis '#133' l''imprimante.',
    'Document sent to the printer.',
    'Documento enviado a la impresora.',
    'Documento inviato alla stampante.',
    'Dokument an den Drucker gesendet.')),
  (K: 'Echec de l''impression.';
   V: (#144'chec de l''impression.',
    'Printing failed.',
    'Error de impresi'#162'n.',
    'Stampa non riuscita.',
    'Drucken fehlgeschlagen.')),
  (K: 'Impossible d''ouvrir le dialogue d''impression.';
   V: ('Impossible d''ouvrir le dialogue d''impression.',
    'Cannot open the print dialog.',
    'No se puede abrir el di'#160'logo de impresi'#162'n.',
    'Impossibile aprire la finestra di stampa.',
    'Druckdialog kann nicht ge'#148'ffnet werden.')),
  (K: 'Impression disponible sous Windows.';
   V: ('Impression disponible sous Windows.',
    'Printing is available on Windows.',
    'La impresi'#162'n est'#160' disponible en Windows.',
    'La stampa '#138' disponibile su Windows.',
    'Drucken ist unter Windows verf'#129'gbar.')),
  (K: 'File already exists. Overwrite it?';
   V: ('Le fichier existe d'#130'j'#133'. L'''#130'craser ?',
    'File already exists. Overwrite it?',
    'El archivo existe. '#168'Sobrescribirlo?',
    'Il file esiste gi'#133'. Sovrascriverlo?',
    'Datei existiert. '#154'berschreiben?')),
  (K: 'Discard unsaved changes?';
   V: ('Abandonner les modifications ?',
    'Discard unsaved changes?',
    #168'Descartar los cambios sin guardar?',
    'Annullare le modifiche non salvate?',
    'Nicht gespeicherte '#142'nderungen verwerfen?')),
  (K: 'New document';
   V: ('Nouveau document',
    'New document',
    'Nuevo documento',
    'Nuovo documento',
    'Neues Dokument')),
  (K: 'Open Document';
   V: ('Ouvrir un document',
    'Open Document',
    'Abrir documento',
    'Apri documento',
    'Dokument '#148'ffnen')),
  (K: 'Opened ';
   V: ('Ouvert : ',
    'Opened ',
    'Abierto: ',
    'Aperto: ',
    'Ge'#148'ffnet: ')),
  (K: 'GAT tronque (500 paragraphes max)';
   V: ('GAT tronqu'#130' (500 paragraphes max)',
    'GAT truncated (500 paragraphs max)',
    'GAT truncado (m'#160'x. 500 p'#160'rrafos)',
    'GAT troncato (max 500 paragrafi)',
    'GAT gek'#129'rzt (max. 500 Abs'#132'tze)')),
  (K: 'Cannot open file (PDF: readable text required): ';
   V: ('Impossible d''ouvrir le fichier (PDF : texte lisible requis) : ',
    'Cannot open file (PDF: readable text required): ',
    'No se puede abrir el archivo (PDF: texto legible requerido): ',
    'Impossibile aprire il file (PDF: testo leggibile richiesto): ',
    'Datei kann nicht ge'#148'ffnet werden (PDF: lesbarer Text n'#148'tig): ')),
  (K: 'Save Document';
   V: ('Enregistrer le document',
    'Save Document',
    'Guardar documento',
    'Salva documento',
    'Dokument speichern')),
  (K: 'Saved ';
   V: ('Enregistr'#130' : ',
    'Saved ',
    'Guardado: ',
    'Salvato: ',
    'Gespeichert: ')),
  (K: 'Cannot save file: ';
   V: ('Impossible d''enregistrer le fichier : ',
    'Cannot save file: ',
    'No se puede guardar el archivo: ',
    'Impossibile salvare il file: ',
    'Datei kann nicht gespeichert werden: ')),
  (K: 'Save As';
   V: ('Enregistrer sous',
    'Save As',
    'Guardar como',
    'Salva con nome',
    'Speichern unter')),
  (K: 'Cannot save as .DOC (read-only format)';
   V: ('Impossible d''enregistrer en .DOC (lecture seule)',
    'Cannot save as .DOC (read-only format)',
    'No se puede guardar como .DOC (solo lectura)',
    'Impossibile salvare come .DOC (sola lettura)',
    'Speichern als .DOC nicht m'#148'glich (nur Lesen)')),
  (K: 'Cut (Phase 2+)';
   V: ('Couper (phase 2+)',
    'Cut (Phase 2+)',
    'Cortar (fase 2+)',
    'Taglia (fase 2+)',
    'Ausschneiden (Phase 2+)')),
  (K: 'Copy (Phase 2+)';
   V: ('Copier (phase 2+)',
    'Copy (Phase 2+)',
    'Copiar (fase 2+)',
    'Copia (fase 2+)',
    'Kopieren (Phase 2+)')),
  (K: 'Paste (Phase 2+)';
   V: ('Coller (phase 2+)',
    'Paste (Phase 2+)',
    'Pegar (fase 2+)',
    'Incolla (fase 2+)',
    'Einf'#129'gen (Phase 2+)')),
  (K: 'Page break inserted';
   V: ('Saut de page ins'#130'r'#130,
    'Page break inserted',
    'Salto de p'#160'gina insertado',
    'Interruzione di pagina inserita',
    'Seitenumbruch eingef'#129'gt')),
  (K: 'Picture inserted: ';
   V: ('Image ins'#130'r'#130'e : ',
    'Picture inserted: ',
    'Imagen insertada: ',
    'Immagine inserita: ',
    'Bild eingef'#129'gt: ')),
  (K: 'Cannot load image: ';
   V: ('Impossible de charger l''image : ',
    'Cannot load image: ',
    'No se puede cargar la imagen: ',
    'Impossibile caricare l''immagine: ',
    'Bild kann nicht geladen werden: ')),
  (K: 'Toggle Bold';
   V: ('Basculer le gras',
    'Toggle Bold',
    'Alternar negrita',
    'Alterna grassetto',
    'Fett umschalten')),
  (K: 'Toggle Italic';
   V: ('Basculer l''italique',
    'Toggle Italic',
    'Alternar cursiva',
    'Alterna corsivo',
    'Kursiv umschalten')),
  (K: 'Toggle Underline';
   V: ('Basculer le soulignement',
    'Toggle Underline',
    'Alternar subrayado',
    'Alterna sottolineato',
    'Unterstreichen umschalten')),
  (K: 'Color: Black';
   V: ('Couleur : noir',
    'Color: Black',
    'Color: negro',
    'Colore: nero',
    'Farbe: Schwarz')),
  (K: 'Color #';
   V: ('Couleur #',
    'Color #',
    'Color #',
    'Colore #',
    'Farbe #')),
  (K: 'Le curseur n''est pas dans un tableau.';
   V: ('Le curseur n''est pas dans un tableau.',
    'The cursor is not in a table.',
    'El cursor no est'#160' en una tabla.',
    'Il cursore non '#138' in una tabella.',
    'Der Cursor befindet sich nicht in einer Tabelle.')),
  (K: 'Cascade (single-doc)';
   V: ('Cascade (document unique)',
    'Cascade (single-doc)',
    'Cascada (documento '#163'nico)',
    'Cascata (documento singolo)',
    #154'berlappend (ein Dokument)')),
  (K: 'Action non implementee';
   V: ('Action non impl'#130'ment'#130'e',
    'Action not implemented',
    'Acci'#162'n no implementada',
    'Azione non implementata',
    'Aktion nicht implementiert')),
  (K: 'Menu contextuel : clic droit sur un tableau';
   V: ('Menu contextuel : clic droit sur un tableau',
    'Context menu: right-click on a table',
    'Men'#163' contextual: clic derecho en una tabla',
    'Menu contestuale: clic destro su una tabella',
    'Kontextmen'#129': Rechtsklick auf eine Tabelle')),
  (K: 'Pret. F10=menu, fleches=naviguer, Alt+X=quitter.';
   V: ('Pr'#136't. F10=menu, fl'#138'ches=naviguer, Alt+X=quitter.',
    'Ready. F10=menu, arrows=navigate, Alt+X=quit.',
    'Listo. F10=men'#163', flechas=navegar, Alt+X=salir.',
    'Pronto. F10=menu, frecce=navigare, Alt+X=esci.',
    'Bereit. F10=Men'#129', Pfeile=navigieren, Alt+X=beenden.')),
  (K: 'Cannot open file: ';
   V: ('Impossible d''ouvrir le fichier : ',
    'Cannot open file: ',
    'No se puede abrir el archivo: ',
    'Impossibile aprire il file: ',
    'Datei kann nicht ge'#148'ffnet werden: ')),
  (K: 'Ctrl+O ouvre un document.';
   V: ('Ctrl+O ouvre un document.',
    'Ctrl+O opens a document.',
    'Ctrl+O abre un documento.',
    'Ctrl+O apre un documento.',
    'Strg+O '#148'ffnet ein Dokument.')),
  (K: 'Ctrl+S enregistre le document courant.';
   V: ('Ctrl+S enregistre le document courant.',
    'Ctrl+S saves the current document.',
    'Ctrl+S guarda el documento actual.',
    'Ctrl+S salva il documento corrente.',
    'Strg+S speichert das aktuelle Dokument.')),
  (K: 'Fichier > Enregistrer sous permet de';
   V: ('Fichier > Enregistrer sous permet de',
    'File > Save As lets you choose',
    'Archivo > Guardar como permite',
    'File > Salva con nome permette di',
    'Datei > Speichern unter erlaubt es,')),
  (K: 'choisir un autre nom ou format.';
   V: ('choisir un autre nom ou format.',
    'another name or format.',
    'elegir otro nombre o formato.',
    'scegliere un altro nome o formato.',
    'Name oder Format zu '#132'ndern.')),
  (K: 'Alt+X quitte WorDium.';
   V: ('Alt+X quitte WorDium.',
    'Alt+X exits WorDium.',
    'Alt+X cierra WorDium.',
    'Alt+X chiude WorDium.',
    'Alt+X beendet WorDium.')),
  (K: 'Ctrl+X coupe et Ctrl+C copie.';
   V: ('Ctrl+X coupe et Ctrl+C copie.',
    'Ctrl+X cuts and Ctrl+C copies.',
    'Ctrl+X corta y Ctrl+C copia.',
    'Ctrl+X taglia e Ctrl+C copia.',
    'Strg+X schneidet aus, Strg+C kopiert.')),
  (K: 'Ctrl+V colle le texte.';
   V: ('Ctrl+V colle le texte.',
    'Ctrl+V pastes the text.',
    'Ctrl+V pega el texto.',
    'Ctrl+V incolla il testo.',
    'Strg+V f'#129'gt den Text ein.')),
  (K: 'Ctrl+Z annule la derniere modification.';
   V: ('Ctrl+Z annule la derni'#138're modification.',
    'Ctrl+Z undoes the last change.',
    'Ctrl+Z deshace el '#163'ltimo cambio.',
    'Ctrl+Z annulla l''ultima modifica.',
    'Strg+Z: letzte '#142'nderung r'#129'ckg'#132'ngig.')),
  (K: 'Ctrl+Y retablit une modification.';
   V: ('Ctrl+Y r'#130'tablit une modification.',
    'Ctrl+Y redoes a change.',
    'Ctrl+Y rehace un cambio.',
    'Ctrl+Y ripristina una modifica.',
    'Strg+Y wiederholt eine '#142'nderung.')),
  (K: 'F3 recherche la prochaine occurrence.';
   V: ('F3 recherche la prochaine occurrence.',
    'F3 finds the next match.',
    'F3 busca la siguiente coincidencia.',
    'F3 trova la corrispondenza successiva.',
    'F3 sucht das n'#132'chste Vorkommen.')),
  (K: 'Le menu Affichage permet de changer';
   V: ('Le menu Affichage permet de changer',
    'The View menu lets you change',
    'El men'#163' Ver permite cambiar',
    'Il menu Visualizza permette di',
    'Das Men'#129' Ansicht erm'#148'glicht es,')),
  (K: 'de vue, de zoom ou de masquer la regle.';
   V: ('de vue, de zoom ou de masquer la r'#138'gle.',
    'view, zoom or hide the ruler.',
    'la vista, el zoom u ocultar la regla.',
    'cambiare vista, zoom o righello.',
    'Ansicht, Zoom oder Lineal zu '#132'ndern.')),
  (K: 'Utilisez le mode Page pour visualiser';
   V: ('Utilisez le mode Page pour visualiser',
    'Use Page mode to see',
    'Use el modo P'#160'gina para ver',
    'Usa la modalit'#133' Pagina per vedere',
    'Im Seitenmodus sehen Sie')),
  (K: 'la disposition sur la feuille.';
   V: ('la disposition sur la feuille.',
    'the layout on the sheet.',
    'la disposici'#162'n en la hoja.',
    'la disposizione sul foglio.',
    'das Layout auf dem Blatt.')),
  (K: 'Insertion > Symbole ouvre la grille.';
   V: ('Insertion > Symbole ouvre la grille.',
    'Insert > Symbol opens the grid.',
    'Insertar > S'#161'mbolo abre la cuadr'#161'cula.',
    'Inserisci > Simbolo apre la griglia.',
    'Einf'#129'gen > Symbol '#148'ffnet das Raster.')),
  (K: 'Choisissez un caractere puis Inserer.';
   V: ('Choisissez un caract'#138're puis Ins'#130'rer.',
    'Choose a character then Insert.',
    'Elija un car'#160'cter y pulse Insertar.',
    'Scegli un carattere poi Inserisci.',
    'Zeichen w'#132'hlen, dann Einf'#129'gen.')),
  (K: 'Le menu permet aussi d''inserer une';
   V: ('Le menu permet aussi d''ins'#130'rer une',
    'The menu also inserts an',
    'El men'#163' tambi'#130'n inserta una',
    'Il menu permette anche di inserire',
    'Das Men'#129' f'#129'gt auch ein Bild')),
  (K: 'image ou un tableau.';
   V: ('image ou un tableau.',
    'image or a table.',
    'imagen o una tabla.',
    'un''immagine o una tabella.',
    'oder eine Tabelle ein.')),
  (K: 'Ctrl+Entree insere un saut de page.';
   V: ('Ctrl+Entr'#130'e ins'#138're un saut de page.',
    'Ctrl+Enter inserts a page break.',
    'Ctrl+Intro inserta un salto de p'#160'gina.',
    'Ctrl+Invio inserisce un salto pagina.',
    'Strg+Eingabe: Seitenumbruch einf'#129'gen.')),
  (K: 'Format > Police regle taille et couleur.';
   V: ('Format > Police r'#138'gle taille et couleur.',
    'Format > Font sets size and color.',
    'Formato > Fuente ajusta tama'#164'o y color.',
    'Formato > Carattere: dimensioni e colore.',
    'Format > Schriftart: Gr'#148#225'e und Farbe.')),
  (K: 'Ctrl+B active ou desactive le gras.';
   V: ('Ctrl+B active ou d'#130'sactive le gras.',
    'Ctrl+B toggles bold.',
    'Ctrl+B activa o desactiva la negrita.',
    'Ctrl+B attiva o disattiva il grassetto.',
    'Strg+B schaltet Fett um.')),
  (K: 'Ctrl+I gere l''italique et Ctrl+U souligne.';
   V: ('Ctrl+I g'#138're l''italique et Ctrl+U souligne.',
    'Ctrl+I toggles italic, Ctrl+U underlines.',
    'Ctrl+I cursiva, Ctrl+U subraya.',
    'Ctrl+I corsivo, Ctrl+U sottolinea.',
    'Strg+I Kursiv, Strg+U unterstreicht.')),
  (K: 'Format > Paragraphe regle alignement,';
   V: ('Format > Paragraphe r'#138'gle alignement,',
    'Format > Paragraph sets alignment,',
    'Formato > P'#160'rrafo ajusta alineaci'#162'n,',
    'Formato > Paragrafo imposta allineamento,',
    'Format > Absatz legt Ausrichtung,')),
  (K: 'retrait, bordure et saut de page.';
   V: ('retrait, bordure et saut de page.',
    'indent, border and page break.',
    'sangr'#161'a, borde y salto de p'#160'gina.',
    'rientro, bordo e interruzione pagina.',
    'Einzug, Rahmen und Seitenumbruch fest.')),
  (K: 'F7 lance le correcteur orthographique.';
   V: ('F7 lance le correcteur orthographique.',
    'F7 starts the spell checker.',
    'F7 inicia el corrector ortogr'#160'fico.',
    'F7 avvia il correttore ortografico.',
    'F7 startet die Rechtschreibpr'#129'fung.')),
  (K: 'Choisissez une suggestion puis Remplacer.';
   V: ('Choisissez une suggestion puis Remplacer.',
    'Choose a suggestion then Replace.',
    'Elija una sugerencia y pulse Reemplazar.',
    'Scegli un suggerimento poi Sostituisci.',
    'Vorschlag w'#132'hlen, dann Ersetzen.')),
  (K: 'Ignorer passe au mot suivant.';
   V: ('Ignorer passe au mot suivant.',
    'Ignore skips to the next word.',
    'Omitir pasa a la palabra siguiente.',
    'Ignora passa alla parola successiva.',
    'Ignorieren springt zum n'#132'chsten Wort.')),
  (K: 'Outils > Options permet de choisir';
   V: ('Outils > Options permet de choisir',
    'Tools > Options lets you choose',
    'Herramientas > Opciones permite elegir',
    'Strumenti > Opzioni permette di scegliere',
    'Extras > Optionen erlaubt die Wahl')),
  (K: 'la langue du correcteur.';
   V: ('la langue du correcteur.',
    'the spell-check language.',
    'el idioma del corrector.',
    'la lingua del correttore.',
    'der Sprache der Pr'#129'fung.')),
  (K: 'Outils > Statistiques affiche les';
   V: ('Outils > Statistiques affiche les',
    'Tools > Statistics shows the',
    'Herramientas > Estad'#161'sticas muestra',
    'Strumenti > Statistiche mostra i',
    'Extras > Statistik zeigt die')),
  (K: 'decomptes du document.';
   V: ('d'#130'comptes du document.',
    'document counts.',
    'los recuentos del documento.',
    'conteggi del documento.',
    'Z'#132'hlwerte des Dokuments.')),
  (K: 'Le tableau indique les pages, mots,';
   V: ('Le tableau indique les pages, mots,',
    'The table lists pages, words,',
    'La tabla indica p'#160'ginas, palabras,',
    'La tabella indica pagine, parole,',
    'Die Tabelle zeigt Seiten, W'#148'rter,')),
  (K: 'caracteres, paragraphes, lignes,';
   V: ('caract'#138'res, paragraphes, lignes,',
    'characters, paragraphs, lines,',
    'caracteres, p'#160'rrafos, l'#161'neas,',
    'caratteri, paragrafi, righe,',
    'Zeichen, Abs'#132'tze, Zeilen,')),
  (K: 'tableaux, cellules et images.';
   V: ('tableaux, cellules et images.',
    'tables, cells and images.',
    'tablas, celdas e im'#160'genes.',
    'tabelle, celle e immagini.',
    'Tabellen, Zellen und Bilder.')),
  (K: 'WorDium - Traitement de texte graphique en Pascal.';
   V: ('WorDium - Traitement de texte graphique en Pascal.',
    'WorDium - Graphical word processor in Pascal.',
    'WorDium - Procesador de textos gr'#160'fico en Pascal.',
    'WorDium - Elaboratore di testi grafico in Pascal.',
    'WorDium - Grafische Textverarbeitung in Pascal.')),
  (K: 'Utilisation : WorDium [/CLASSICMENU | /RUBANMENU] [document] [/?]';
   V: ('Utilisation : WorDium [/CLASSICMENU | /RUBANMENU] [document] [/?]',
    'Usage: WorDium [/CLASSICMENU | /RUBANMENU] [document] [/?]',
    'Uso: WorDium [/CLASSICMENU | /RUBANMENU] [documento] [/?]',
    'Uso: WorDium [/CLASSICMENU | /RUBANMENU] [documento] [/?]',
    'Verwendung: WorDium [/CLASSICMENU | /RUBANMENU] [Dokument] [/?]')),
  (K: '  /CLASSICMENU  Menus classiques, style Word 2003 (par defaut).';
   V: ('  /CLASSICMENU  Menus classiques, style Word 2003 (par d'#130'faut).',
    '  /CLASSICMENU  Classic menus, Word 2003 style (default).',
    '  /CLASSICMENU  Men'#163's cl'#160'sicos, estilo Word 2003 (por defecto).',
    '  /CLASSICMENU  Menu classici, stile Word 2003 (predefinito).',
    '  /CLASSICMENU  Klassische Men'#129's im Stil von Word 2003 (Standard).')),
  (K:
    '  /RUBANMENU    Onglets et commandes avec icones, style Word 2007 et sui'+
    'vants.';
   V:
     ('  /RUBANMENU    Onglets et commandes avec ic'#147'nes, style Word 2007'+
     ' et suivants.',
    '  /RUBANMENU    Tabs and commands with icons, Word 2007 style and later.',
    '  /RUBANMENU    Pesta'#164'as y comandos con iconos, estilo Word 2007 y '+
      'posteriores.',
    '  /RUBANMENU    Schede e comandi con icone, stile Word 2007 e successivi.',
    '  /RUBANMENU    Registerkarten und Befehle mit Symbolen, Stil Word 2007 '+
      'und neuer.')),
  (K: '  /?           Affiche cette aide et quitte sans ouvrir de fenetre.';
   V:
     ('  /?           Affiche cette aide et quitte sans ouvrir de fen'#136'tr'+
     'e.',
    '  /?           Shows this help and exits without opening a window.',
    '  /?           Muestra esta ayuda y sale sin abrir ninguna ventana.',
    '  /?           Mostra questa guida ed esce senza aprire finestre.',
    '  /?           Zeigt diese Hilfe an und beendet ohne Fenster.')),
  (K: '  -h, --help   Affichent egalement cette aide.';
   V: ('  -h, --help   Affichent '#130'galement cette aide.',
    '  -h, --help   Also show this help.',
    '  -h, --help   Tambi'#130'n muestran esta ayuda.',
    '  -h, --help   Mostrano anch''essi questa guida.',
    '  -h, --help   Zeigen ebenfalls diese Hilfe an.')),
  (K: '  document     Fichier a ouvrir au demarrage.';
   V: ('  document     Fichier '#133' ouvrir au d'#130'marrage.',
    '  document     File to open at startup.',
    '  documento    Archivo que se abre al iniciar.',
    '  documento    File da aprire all''avvio.',
    '  Dokument     Beim Start zu '#148'ffnende Datei.')),
  (K:
    'Les options sont insensibles a la casse ; le dernier mode specifie est u'+
    'tilise.';
   V:
     ('Les options sont insensibles '#133' la casse ; le dernier mode '+
     'sp'#130'cifi'#130' est utilis'#130'.',
    'Options are case-insensitive; the last mode specified is used.',
    'Las opciones no distinguen may'#163'sculas; se usa el '#163'ltimo modo i'+
      'ndicado.',
    'Le opzioni non distinguono maiuscole; si usa l''ultima modalit'#133' ind'+
      'icata.',
    'Optionen sind nicht gro'#225'-/kleinschreibungsabh'#132'ngig; der letzte'+
      ' Modus gilt.')),
  (K: 'Le document peut etre place avant ou apres les options.';
   V: ('Le document peut '#136'tre plac'#130' avant ou apr'#138's les options.',
    'The document may be placed before or after the options.',
    'El documento puede ir antes o despu'#130's de las opciones.',
    'Il documento pu'#149' essere posto prima o dopo le opzioni.',
    'Das Dokument kann vor oder nach den Optionen stehen.')),
  (K: 'Entourer les chemins contenant des espaces de guillemets.';
   V: ('Entourer les chemins contenant des espaces de guillemets.',
    'Enclose paths containing spaces in quotes.',
    'Ponga entre comillas las rutas con espacios.',
    'Racchiudere tra virgolette i percorsi con spazi.',
    'Pfade mit Leerzeichen in Anf'#129'hrungszeichen setzen.')),
  (K: 'Exemple : WorDium /RUBANMENU "C:\Documents\Mon texte.docx"';
   V: ('Exemple : WorDium /RUBANMENU "C:\Documents\Mon texte.docx"',
    'Example: WorDium /RUBANMENU "C:\Documents\My text.docx"',
    'Ejemplo: WorDium /RUBANMENU "C:\Documents\Mi texto.docx"',
    'Esempio: WorDium /RUBANMENU "C:\Documents\Mio testo.docx"',
    'Beispiel: WorDium /RUBANMENU "C:\Documents\Mein Text.docx"')),
  (K:
    'Ruban : souris, F10 ou Alt+lettre, fleches, Tab/Maj+Tab, Entree et Echap.';
   V:
     ('Ruban : souris, F10 ou Alt+lettre, fl'#138'ches, Tab/Maj+Tab, En'+
     'tr'#130'e et '#144'chap.',
    'Ribbon: mouse, F10 or Alt+letter, arrows, Tab/Shift+Tab, Enter and Esc.',
    'Cinta: rat'#162'n, F10 o Alt+letra, flechas, Tab/May'#163's+Tab, Intro y'+
      ' Esc.',
    'Barra multifunzione: mouse, F10 o Alt+lettera, frecce, Tab/Maiusc+Tab, I'+
      'nvio ed Esc.',
    'Men'#129'band: Maus, F10 oder Alt+Buchstabe, Pfeile, Tab/Umschalt+Tab, E'+
      'ingabe und Esc.')),
  (K: 'Accueil : Alt+E. Les commandes non implementees sont grisees.';
   V:
     ('Accueil : Alt+E. Les commandes non impl'#130'ment'#130'es sont gr'+
     'is'#130'es.',
    'Home: Alt+M. Unimplemented commands are grayed out.',
    'Inicio: Alt+C. Los comandos no implementados aparecen atenuados.',
    'Home: Alt+M. I comandi non implementati sono disattivati.',
    'Start: Alt+S. Nicht implementierte Befehle sind abgeblendet.')),
  (K: 'Ctrl+N Nouveau, Ctrl+O Ouvrir, Ctrl+S Enregistrer, Alt+X Quitter.';
   V: ('Ctrl+N Nouveau, Ctrl+O Ouvrir, Ctrl+S Enregistrer, Alt+X Quitter.',
    'Ctrl+N New, Ctrl+O Open, Ctrl+S Save, Alt+X Exit.',
    'Ctrl+N Nuevo, Ctrl+O Abrir, Ctrl+S Guardar, Alt+X Salir.',
    'Ctrl+N Nuovo, Ctrl+O Apri, Ctrl+S Salva, Alt+X Esci.',
    'Strg+N Neu, Strg+O '#153'ffnen, Strg+S Speichern, Alt+X Beenden.')),
  (K: 'Erreur graphique : ';
   V: ('Erreur graphique : ',
    'Graphics error: ',
    'Error gr'#160'fico: ',
    'Errore grafico: ',
    'Grafikfehler: ')),
  (K:
    'Documents (*.WPD;*.DOCX;*.DOC;*.PDF;*.GAT;*.GPX)|*.WPD;*.DOCX;*.DOC;*.PD'+
    'F;*.GAT;*.GPX|GPX (*.GPX)|*.GPX|GAT MonsterBook (*.GAT)|*.GAT|PDF (*.PDF'+
    ')|*.PDF|WPD (*.WPD)|*.WPD|DOCX (*.DOCX)|*.DOCX|DOC (*.DOC)|*.DOC|Tous (*'+
    '.*)|*.*';
   V:
     ('Documents (*.WPD;*.DOCX;*.DOC;*.PDF;*.GAT;*.GPX)|*.WPD;*.DOCX;*.DOC;*.'+
     'PDF;*.GAT;*.GPX|GPX (*.GPX)|*.GPX|GAT MonsterBook (*.GAT)|*.GAT|PDF (*.'+
     'PDF)|*.PDF|WPD (*.WPD)|*.WPD|DOCX (*.DOCX)|*.DOCX|DOC (*.DOC)|*.DOC|Tou'+
     's (*.*)|*.*',
    'Documents (*.WPD;*.DOCX;*.DOC;*.PDF;*.GAT;*.GPX)|*.WPD;*.DOCX;*.DOC;*.PD'+
      'F;*.GAT;*.GPX|GPX (*.GPX)|*.GPX|GAT MonsterBook (*.GAT)|*.GAT|PDF (*.P'+
      'DF)|*.PDF|WPD (*.WPD)|*.WPD|DOCX (*.DOCX)|*.DOCX|DOC (*.DOC)|*.DOC|All'+
      ' (*.*)|*.*',
    'Documentos (*.WPD;*.DOCX;*.DOC;*.PDF;*.GAT;*.GPX)|*.WPD;*.DOCX;*.DOC;*.P'+
      'DF;*.GAT;*.GPX|GPX (*.GPX)|*.GPX|GAT MonsterBook (*.GAT)|*.GAT|PDF (*.'+
      'PDF)|*.PDF|WPD (*.WPD)|*.WPD|DOCX (*.DOCX)|*.DOCX|DOC (*.DOC)|*.DOC|To'+
      'dos (*.*)|*.*',
    'Documenti (*.WPD;*.DOCX;*.DOC;*.PDF;*.GAT;*.GPX)|*.WPD;*.DOCX;*.DOC;*.PD'+
      'F;*.GAT;*.GPX|GPX (*.GPX)|*.GPX|GAT MonsterBook (*.GAT)|*.GAT|PDF (*.P'+
      'DF)|*.PDF|WPD (*.WPD)|*.WPD|DOCX (*.DOCX)|*.DOCX|DOC (*.DOC)|*.DOC|Tut'+
      'ti (*.*)|*.*',
    'Dokumente (*.WPD;*.DOCX;*.DOC;*.PDF;*.GAT;*.GPX)|*.WPD;*.DOCX;*.DOC;*.PD'+
      'F;*.GAT;*.GPX|GPX (*.GPX)|*.GPX|GAT MonsterBook (*.GAT)|*.GAT|PDF (*.P'+
      'DF)|*.PDF|WPD (*.WPD)|*.WPD|DOCX (*.DOCX)|*.DOCX|DOC (*.DOC)|*.DOC|All'+
      'e (*.*)|*.*')),
  (K:
    'Documents (*.WPD;*.DOCX;*.GAT)|*.WPD;*.DOCX;*.GAT|WPD (*.WPD)|*.WPD|DOCX'+
    ' (*.DOCX)|*.DOCX|GAT MonsterBook (*.GAT)|*.GAT';
   V:
     ('Documents (*.WPD;*.DOCX;*.GAT)|*.WPD;*.DOCX;*.GAT|WPD (*.WPD)|*.WPD|DO'+
     'CX (*.DOCX)|*.DOCX|GAT MonsterBook (*.GAT)|*.GAT',
    'Documents (*.WPD;*.DOCX;*.GAT)|*.WPD;*.DOCX;*.GAT|WPD (*.WPD)|*.WPD|DOCX'+
      ' (*.DOCX)|*.DOCX|GAT MonsterBook (*.GAT)|*.GAT',
    'Documentos (*.WPD;*.DOCX;*.GAT)|*.WPD;*.DOCX;*.GAT|WPD (*.WPD)|*.WPD|DOC'+
      'X (*.DOCX)|*.DOCX|GAT MonsterBook (*.GAT)|*.GAT',
    'Documenti (*.WPD;*.DOCX;*.GAT)|*.WPD;*.DOCX;*.GAT|WPD (*.WPD)|*.WPD|DOCX'+
      ' (*.DOCX)|*.DOCX|GAT MonsterBook (*.GAT)|*.GAT',
    'Dokumente (*.WPD;*.DOCX;*.GAT)|*.WPD;*.DOCX;*.GAT|WPD (*.WPD)|*.WPD|DOCX'+
      ' (*.DOCX)|*.DOCX|GAT MonsterBook (*.GAT)|*.GAT')),
  (K:
    'Images (*.BMP;*.PCX;*.GIF;*.JPG;*.GPX)|*.BMP;*.GPX;*.PCX;*.BGX;*.XBM;*.T'+
    'IF;*.TIFF;*.GIF;*.JPG;*.JPEG|BMP (*.BMP)|*.BMP|PCX (*.PCX)|*.PCX|GIF (*.'+
    'GIF)|*.GIF|JPEG (*.JPG;*.JPEG)|*.JPG;*.JPEG|TIFF (*.TIF;*.TIFF)|*.TIF;*.'+
    'TIFF|Tous (*.*)|*.*';
   V:
     ('Images (*.BMP;*.PCX;*.GIF;*.JPG;*.GPX)|*.BMP;*.GPX;*.PCX;*.BGX;*.XBM;*'+
     '.TIF;*.TIFF;*.GIF;*.JPG;*.JPEG|BMP (*.BMP)|*.BMP|PCX (*.PCX)|*.PCX|GIF '+
     '(*.GIF)|*.GIF|JPEG (*.JPG;*.JPEG)|*.JPG;*.JPEG|TIFF (*.TIF;*.TIFF)|*.TI'+
     'F;*.TIFF|Tous (*.*)|*.*',
    'Images (*.BMP;*.PCX;*.GIF;*.JPG;*.GPX)|*.BMP;*.GPX;*.PCX;*.BGX;*.XBM;*.T'+
      'IF;*.TIFF;*.GIF;*.JPG;*.JPEG|BMP (*.BMP)|*.BMP|PCX (*.PCX)|*.PCX|GIF ('+
      '*.GIF)|*.GIF|JPEG (*.JPG;*.JPEG)|*.JPG;*.JPEG|TIFF (*.TIF;*.TIFF)|*.TI'+
      'F;*.TIFF|All (*.*)|*.*',
    'Im'#160'genes (*.BMP;*.PCX;*.GIF;*.JPG;*.GPX)|*.BMP;*.GPX;*.PCX;*.BGX;*.'+
      'XBM;*.TIF;*.TIFF;*.GIF;*.JPG;*.JPEG|BMP (*.BMP)|*.BMP|PCX (*.PCX)|*.PC'+
      'X|GIF (*.GIF)|*.GIF|JPEG (*.JPG;*.JPEG)|*.JPG;*.JPEG|TIFF (*.TIF;*.TIF'+
      'F)|*.TIF;*.TIFF|Todos (*.*)|*.*',
    'Immagini (*.BMP;*.PCX;*.GIF;*.JPG;*.GPX)|*.BMP;*.GPX;*.PCX;*.BGX;*.XBM;*'+
      '.TIF;*.TIFF;*.GIF;*.JPG;*.JPEG|BMP (*.BMP)|*.BMP|PCX (*.PCX)|*.PCX|GIF'+
      ' (*.GIF)|*.GIF|JPEG (*.JPG;*.JPEG)|*.JPG;*.JPEG|TIFF (*.TIF;*.TIFF)|*.'+
      'TIF;*.TIFF|Tutti (*.*)|*.*',
    'Bilder (*.BMP;*.PCX;*.GIF;*.JPG;*.GPX)|*.BMP;*.GPX;*.PCX;*.BGX;*.XBM;*.T'+
      'IF;*.TIFF;*.GIF;*.JPG;*.JPEG|BMP (*.BMP)|*.BMP|PCX (*.PCX)|*.PCX|GIF ('+
      '*.GIF)|*.GIF|JPEG (*.JPG;*.JPEG)|*.JPG;*.JPEG|TIFF (*.TIF;*.TIFF)|*.TI'+
      'F;*.TIFF|Alle (*.*)|*.*'))
  );

Var
 UILang  : Integer;
 TrReady : Boolean;
 TrHash  : Array[0..1023] Of Integer;

Function TrHashOf(Const S: String): Integer;
Var I: Integer; H: LongInt;
Begin
 H := 5381;
 For I := 1 To Length(S) Do H := (H And $3FFFFF) * 33 + Ord(S[I]);
 TrHashOf := H And 1023;
End;

Procedure InitLanguage;
Var L: String; I, H: Integer;
Begin
 L := GetEnv('LANGUAGE');
 For I := 1 To Length(L) Do L[I] := UpCase(L[I]);
 L := Copy(L, 1, 2);
 UILang := LANG_FR;
 If L = 'EN' Then UILang := LANG_EN
 Else If (L = 'ES') Or (L = 'SP') Then UILang := LANG_ES
 Else If L = 'IT' Then UILang := LANG_IT
 Else If (L = 'GR') Or (L = 'DE') Then UILang := LANG_DE;
 FillChar(TrHash, SizeOf(TrHash), 0);
 For I := 1 To TR_COUNT Do Begin
  H := TrHashOf(TrTab[I].K);
  While TrHash[H] <> 0 Do H := (H + 1) And 1023;
  TrHash[H] := I;
 End;
 TrReady := True;
End;

{ Traduit un texte source ; un texte inconnu est retourne tel quel. }
Function Tr(Const S: String): String;
Var H: Integer;
Begin
 Tr := S;
 If Not TrReady Then Exit;
 H := TrHashOf(S);
 While TrHash[H] <> 0 Do Begin
  If TrTab[TrHash[H]].K = S Then Begin
   Tr := TrTab[TrHash[H]].V[UILang];
   Exit;
  End;
  H := (H + 1) And 1023;
 End;
End;

{ Touche "oui" : Y, plus la lettre du mot Oui/Si/Ja de la langue. }
Function IsYesChar(C: Char): Boolean;
Begin
 C := UpCase(C);
 IsYesChar := (C = 'Y') Or ((UILang = LANG_FR) And (C = 'O')) Or
   (((UILang = LANG_ES) Or (UILang = LANG_IT)) And (C = 'S')) Or
   ((UILang = LANG_DE) And (C = 'J')),
  (K: 'Imprimer';
   V: ('Imprimer',
    'Print',
    'Imprimir',
    'Stampa',
    'Drucken')),
  (K: 'Pages a imprimer (ex. 1-3) :';
   V: ('Pages '#133' imprimer (ex. 1-3) :',
    'Pages to print (e.g. 1-3):',
    'P'#160'ginas a imprimir (ej. 1-3):',
    'Pagine da stampare (es. 1-3):',
    'Zu druckende Seiten (z. B. 1-3):')),
  (K: 'Sans titre';
   V: ('Sans titre',
    'Untitled',
    'Sin t'#161'tulo',
    'Senza titolo',
    'Unbenannt'));
End;

{ Raccourci clavier affiche : Ctrl+ -> Strg+ (allemand), nom de la
  touche Entree selon la langue. }
Function TrShortcut(Const S: String): String;
Var R, E: String; P: Integer;
Begin
 R := S;
 If (UILang = LANG_DE) And (Copy(R, 1, 5) = 'Ctrl+') Then
  R := 'Strg+' + Copy(R, 6, 255);
 P := Pos('+Enter', R);
 If P > 0 Then Begin
  Case UILang Of
   LANG_FR : E := 'Entr'#130'e';
   LANG_ES : E := 'Intro';
   LANG_IT : E := 'Invio';
   LANG_DE : E := 'Eingabe';
  Else E := 'Enter';
  End;
  R := Copy(R, 1, P) + E;
 End;
 TrShortcut := R;
End;

{ Lettre Alt d'un libelle de menu : celle qui suit le '&'. }
Function AltFromCaption(Const Cap: String; Dflt: Char): Char;
Var P: Integer;
Begin
 P := Pos('&', Cap);
 If (P > 0) And (P < Length(Cap)) Then
  AltFromCaption := UpCase(Cap[P + 1])
 Else If UILang = LANG_FR Then AltFromCaption := Dflt
 Else AltFromCaption := #0;
End;

Procedure InitializeGraphics;
Var
 Driver, Mode: Integer;
 ErrCode: Integer;
Begin
 
  Driver:=VGA;
  Mode:=VGAHi;
 
 InitGraph(Driver,Mode,'');
 ErrCode:=GraphResult;
 If ErrCode=grOk Then Begin
  SetColor(White);
  SetLineStyle(0,0,1);
 End
  Else
 Begin
  WriteLn(Tr('Erreur graphique : '),GraphErrorMsg(ErrCode));
  Halt;
 End;
End;

{ ============================================================ }
{ ====================  CONSTANTES UI  ======================= }
{ ============================================================ }

Const
 SCREEN_W              = 640;
 SCREEN_H              = 480;

 { --- Barre de titre / menus --- }
 MENUBAR_TOP           = 0;
 MENUBAR_HEIGHT        = 18;
 MENUBAR_BG            = 7;          { Gris clair }
 MENUBAR_FG            = 0;          { Noir }
 MENUBAR_HL_BG         = 1;          { Bleu }
 MENUBAR_HL_FG         = 15;         { Blanc }

 { --- Toolbar standard (ic??nes) --- }
 CLASSIC_STDBAR_TOP = 19;
 STDBAR_HEIGHT         = 24;
 STDBAR_BG             = 7;
 STDBAR_BTN            = 22;         { largeur/hauteur bouton 22x22 }

 { --- Toolbar formatage --- }
 CLASSIC_FMTBAR_TOP = 44;
 FMTBAR_HEIGHT         = 22;
 FMTBAR_BG             = 7;
 FMTBAR_BTN            = 20;

 { --- R??gle horizontale --- }
 CLASSIC_RULER_TOP = 67;
 RULER_HEIGHT          = 14;
 RULER_BG              = 15;
 RULER_FG              = 0;

 { --- Zone document --- }
 CLASSIC_DOCAREA_TOP = 82;
 DOCAREA_BOTTOM        = 459;        { au-dessus de la status bar }
 DOCAREA_BG            = 8;          { gris fonc?? (autour de la page) }

 { --- Page virtuelle (Letter 8.5"x11" ?? ~50 dpi visuel) --- }
 PageLayoutView: Boolean = True;
 RulerVisible: Boolean = True;
 ZoomPercent: Integer = 100;
 ZoomPanX: Integer = 0;
 PAGE_W                = 460;        { largeur page ?? l'??cran }
 PAGE_H                = 600;        { hauteur page ?? l'??cran }
 { Marges en pixels - typed const, donc modifiables a l'execution selon sectPr }
 PAGE_MARGIN_L : Integer = 60;       { marge gauche dans la page }
 PAGE_MARGIN_R : Integer = 60;
 PAGE_MARGIN_T : Integer = 60;
 PAGE_MARGIN_B : Integer = 60;
 PAGE_MARGIN_DEFAULT   = 60;         { valeur par defaut, pour reset }
 PAGE_BG               = 15;         { blanc }
 PAGE_SHADOW           = 8;
 PAGE_BORDER           = 0;

 { --- Status bar --- }
 STATUSBAR_TOP         = 460;
 STATUSBAR_HEIGHT      = 20;
 STATUSBAR_BG          = 7;
 STATUSBAR_FG          = 0;

 { --- Couleurs 3D --- }
 CLR_3D_FACE           = 7;          { Gris clair }
 CLR_3D_LIGHT          = 15;         { Blanc }
 CLR_3D_DARK           = 8;          { Gris fonc?? }
 CLR_3D_SHADOW         = 0;          { Noir }

 { --- Codes touches ??tendues --- }
 KEY_NONE              = 0;
 KEY_ESC               = 27;
 KEY_TAB               = 9;
 KEY_ENTER             = 13;
 KEY_BACKSPACE         = 8;
 { Touches ??tendues (pr??fix??es #0 dans ReadKey) - on les code en >256 }
 KEY_F1                = 315;
 KEY_F2                = 316;
 KEY_F3                = 317;
 KEY_F4                = 318;
 KEY_F7                = 321;
 KEY_F10               = 324;
 KEY_HOME              = 327;
 KEY_UP                = 328;
 KEY_PGUP              = 329;
 KEY_LEFT              = 331;
 KEY_RIGHT             = 333;
 KEY_END               = 335;
 KEY_DOWN              = 336;
 KEY_PGDN              = 337;
 KEY_INS               = 338;
 KEY_DEL               = 339;
 KEY_ALT_F             = 289;        { Alt+F  - scancode 33 + 256 }
 KEY_ALT_E             = 274;
 KEY_ALT_V             = 303;
 KEY_ALT_I             = 279;
 KEY_ALT_O             = 280;        { Alt+O = Format }
 KEY_ALT_T             = 276;        { Alt+T = Tools }
 KEY_ALT_A             = 286;        { Alt+A = Table }
 KEY_ALT_W             = 273;
 KEY_ALT_H             = 291;        { Alt+H = Help }
 KEY_ALT_X             = 301;        { Alt+X = sortie rapide }

 { --- Boutons souris (bitmask) --- }
 MB_LEFT               = 1;
 MB_RIGHT              = 2;
 MB_MIDDLE             = 4;

 { --- Limites document (Phase 1: structures pr??par??es) --- }
 MAX_RUNS_PER_PARA     = 32;
 MAX_PARAS_PER_DOC     = 500;
 MAX_PAGES             = 50;
 MAX_TEXT_LEN          = 240;
 MAX_DOC_FILENAME      = 80;

 { --- Limites tableaux (Phase 11) --- }
 MAX_TABLES            = 32;
 MAX_TBL_ROWS          = 16;
 MAX_TBL_COLS          = 6;
 MAX_CELL_TEXT_LEN     = 80;
 TBL_CELL_HEIGHT       = 16;
 TBL_CELL_PAD          = 3;

 { --- Styles caract??res (bitmask) --- }
 STY_BOLD              = 1;
 STY_ITALIC            = 2;
 STY_UNDERLINE         = 4;

 { --- Alignement paragraphe --- }
 ALIGN_LEFT            = 0;
 ALIGN_CENTER          = 1;
 ALIGN_RIGHT           = 2;
 ALIGN_JUSTIFY         = 3;

{ ============================================================ }
{ ========================  TYPES  =========================== }
{ ============================================================ }

Type
 TStr80   = String[80];
 TStr240  = String[240];

 { --- Style d'un run de texte (Phase 3 utilisera) --- }
 TCharStyle = Record
  FontSize : Byte;       { 8, 10, 12, 14, 18, 24 }
  Style    : Byte;       { combinaison STY_* }
  Color    : Byte;       { 0..15 palette EGA/VGA }
 End;

 { --- Run = portion contigu?? de m??me style --- }
 TRun = Record
  Text  : TStr240;
  Style : TCharStyle;
 End;

 { --- Paragraphe = liste de runs + alignement (+ image en Phase 6) --- }
 TPDFPlacement = Record
  Active: Boolean;
  Page, X, Y, Height, Width: Integer;
  Face: String[31];
 End;
 TPDFGraphic = Record
  Page, X1,Y1,X2,Y2: Integer;
  Kind, Color: Byte; { 1=line, 2=filled rectangle }
 End;
 TParagraph = Record
  PDF: TPDFPlacement;
  Runs            : Array[1..MAX_RUNS_PER_PARA] Of TRun;
  RunCount        : Integer;
  Alignment       : Byte;
  PageBreakBefore : Boolean;
  IsImage         : Boolean;
  ImgW, ImgH      : Integer;
  ImgData         : Pointer;     { palette indices 0..15, W*H octets }
  TableIdx        : Integer;     { 0 = pas table; sinon index dans Tables }
  LeftIndent      : Integer;     { hang indent en pixels (lignes 2+ d'une liste)
    }
  FirstLineHang   : Boolean;     { True => 1re ligne aussi indentee
    (continuation) }
  BorderBottom    : Boolean;     { trait horizontal sous le paragraphe }
  ContinuesPrev   : Boolean;     { sous-paragraphe artificiel (split
    ShortString) }
  ContinuesNext   : Boolean;     { ce paragraphe est suivi d'un sous-para
    artificiel }
 End;

 { --- Cellule de tableau : texte simple (Phase 11) --- }
 TTableCell = String[MAX_CELL_TEXT_LEN];

 TTable = Record
  Used  : Boolean;
  Rows  : Byte;       { 1..MAX_TBL_ROWS }
  Cols  : Byte;       { 1..MAX_TBL_COLS }
  Cells : Array[1..MAX_TBL_ROWS, 1..MAX_TBL_COLS] Of TTableCell;
 End;

 { --- Document --- }
 TDocument = Record
  PDFPageCount, PDFGraphicCount: Integer;
  PDFGraphics: Array[1..2048] of TPDFGraphic;
  Paragraphs : Array[1..MAX_PARAS_PER_DOC] Of TParagraph;
  ParaCount  : Integer;
  PageCount  : Integer;
  FileName   : String[MAX_DOC_FILENAME];
  Modified   : Boolean;
 End;

 { --- Position curseur --- }
 TCursorPos = Record
  ParaIdx : Integer;     { 1..ParaCount }
  RunIdx  : Integer;     { 1..RunCount }
  CharIdx : Integer;     { 0..Length(Run.Text) }
 End;

 { --- D??finition d'un menu et de ses items --- }
 TMenuItem = Record
  Caption   : String[40];
  Shortcut  : String[16];   { ex. 'Ctrl+S' affich?? ?? droite }
  AltKey    : Char;         { lettre soulign??e, #0 si aucune }
  Separator : Boolean;
  ActionId  : Integer;      { identifiant d'action }
  Enabled   : Boolean;
 End;

 TMenu = Record
  Caption   : String[20];
  AltKey    : Char;
  X1, X2    : Integer;
  ItemCount : Integer;
  Items     : Array[1..16] Of TMenuItem;
  DropW     : Integer;      { largeur du dropdown calcul??e }
 End;

 { --- Toolbar : un bouton --- }
 TToolBtn = Record
  X, Y, W, H : Integer;
  IconId     : Integer;
  ActionId   : Integer;
  Tooltip    : String[40];
  Pressed    : Boolean;     { pour boutons toggle (gras/italique...) }
  Separator  : Boolean;
 End;

{ ============================================================ }
{ ====================  IDENTIFIANTS  ======================== }
{ ============================================================ }

Const
 { Actions menu/toolbar - une num??rotation unifi??e. }
 ACT_NONE        = 0;

 { File }
 ACT_FILE_NEW    = 101;
 ACT_FILE_OPEN   = 102;
 ACT_FILE_SAVE   = 103;
 ACT_FILE_SAVEAS = 104;
 ACT_FILE_PRINT  = 105;
 ACT_FILE_EXIT   = 109;

 { Edit }
 ACT_EDIT_UNDO   = 201;
 ACT_EDIT_REDO   = 202;
 ACT_EDIT_CUT    = 203;
 ACT_EDIT_COPY   = 204;
 ACT_EDIT_PASTE  = 205;
 ACT_EDIT_FIND   = 206;
 ACT_EDIT_REPL   = 207;
 ACT_EDIT_FIND_NEXT = 208;

 { View }
 ACT_VIEW_NORMAL = 301;
 ACT_VIEW_PAGE   = 302;
 ACT_VIEW_RULER  = 303;
 ACT_VIEW_ZOOM   = 304;

 { Insert }
 ACT_INS_PAGEBRK = 401;
 ACT_INS_IMAGE   = 402;
 ACT_INS_SYMBOL  = 403;
 ACT_INS_TABLE   = 404;

 { Format }
 ACT_FMT_FONT    = 501;
 ACT_FMT_PARA    = 502;
 ACT_FMT_BOLD    = 503;
 ACT_FMT_ITALIC  = 504;
 ACT_FMT_UNDER   = 505;
 ACT_FMT_LEFT    = 506;
 ACT_FMT_CENTER  = 507;
 ACT_FMT_RIGHT   = 508;
 ACT_FMT_JUSTIFY = 509;
 ACT_FMT_COLOR   = 510;

 { Tools }
 ACT_TLS_SPELL   = 601;
 ACT_TLS_OPTIONS = 602;
 ACT_TLS_WORDS   = 603;

 { Table }
 ACT_TBL_INSERT  = 701;
 ACT_TBL_DELETE  = 702;

 { Window }
 ACT_WIN_CASCADE = 801;

 { Help }
 ACT_HLP_ABOUT   = 901;
 ACT_HLP_CONTENT = 902;

 { Ic??nes toolbar (num??rotation des dessins vectoriels) }
 ICN_NEW         = 1;
 ICN_OPEN        = 2;
 ICN_SAVE        = 3;
 ICN_PRINT       = 4;
 ICN_CUT         = 5;
 ICN_COPY        = 6;
 ICN_PASTE       = 7;
 ICN_UNDO        = 8;
 ICN_REDO        = 9;
 ICN_BOLD        = 10;
 ICN_ITALIC      = 11;
 ICN_UNDER       = 12;
 ICN_ALIGN_L     = 13;
 ICN_ALIGN_C     = 14;
 ICN_ALIGN_R     = 15;
 ICN_ALIGN_J     = 16;
 ICN_IMAGE       = 17;
 ICN_TABLE       = 18;

{ ============================================================ }
{ ===================  VARIABLES GLOBALES  =================== }
{ ============================================================ }

Var
 { ??tat application }
 AppShouldExit  : Boolean;
 RibbonMode,RibbonKeyboard: Boolean;
 RibbonTab,RibbonFocus,RibbonHover,RibbonPressed,RibbonInk: Integer;
 STDBAR_TOP,FMTBAR_TOP,RULER_TOP,DOCAREA_TOP: Integer;
 CommandLineFile: String;
 NeedsRedraw    : Boolean;
 StatusMsg      : String[80];

 { Document }
 Doc            : ^TDocument;
 Cursor         : TCursorPos;
 CurrentStyle   : TCharStyle;        { style actif (pour saisie future) }
 CurrentAlign   : Byte;
 CurrentPage    : Integer;           { page affich?e }
 ScrollY        : Integer;           { d?filement vertical (Phase 10) }
 { En-tete et pied de page extraits du DOCX charge (vides sinon). }
 DocxHeaderText : String;
 DocxFooterText : String;

 { Pool de tableaux (Phase 11) }
 Tables         : Array[1..MAX_TABLES] Of TTable;

 { Selection de texte (ancre + extr?mit? = Cursor) }
 Sel            : Record
                   Active     : Boolean;
                   AnchorPara : Integer;
                   AnchorChar : Integer;
                  End;
 MouseSelecting : Boolean;          { drag souris en cours }

 { Souris (pr??fixe Ms* pour ??viter conflit avec PtcMouse.MsX/MsY) }
 MsAvailable : Boolean;
 MsX         : LongInt;
 MsY         : LongInt;
 MsBtn       : LongInt;
 LastMsX     : LongInt;
 LastMsY     : LongInt;
 LastMsBtn   : LongInt;
 MsSaved     : Boolean;            { curseur logiciel sauv?? ? (FPC) }
 MsSaveBuf   : Pointer;            { backing store sous le curseur }
 MsSaveX     : LongInt;
 MsSaveY     : LongInt;

 { Menus }
 Menus          : Array[1..9] Of TMenu;
 MenuCount      : Integer;
 ActiveMenu     : Integer;            { 0 = aucun, sinon 1..9 }
 MenuItemHover  : Integer;            { item survol?? dans dropdown }
 MenuKeyboardMode: Boolean;           { menu ouvert au clavier ? }

 { Toolbars }
 StdBar         : Array[1..24] Of TToolBtn;
 StdBarCount    : Integer;
 FmtBar         : Array[1..16] Of TToolBtn;
 FmtBarCount    : Integer;
 HoveredStdBtn  : Integer;
 HoveredFmtBtn  : Integer;

{ ============================================================ }
{ ==================  ROUTINES SOURIS X-PLAT  ================ }
{ ============================================================ }


 { Sous FPC/PtcMouse, le pilote est toujours pr??sent.
   PtcMouse expose : ShowMouse, HideMouse,
                     GetMouseState(Var X, Y, Buttons: LongInt). }
 Function MouseDriverFound: Boolean;
 Begin
  MouseDriverFound := True;
 End;

 Procedure GetMouseStateLI(Var X, Y, Button: LongInt);
 Begin
  GetMouseState(X, Y, Button);
 End;


{ ============================================================ }
{ =================  INITIALIZE GRAPHICS  ==================== }
{ ============================================================ }
{ NOTE : la proc??dure InitializeGraphics elle-m??me se trouve   }
{ plus haut dans le fichier (ne pas la modifier).              }

{ ============================================================ }
{ ================  UTILITAIRES GRAPHIQUES  ================== }
{ ============================================================ }

Procedure FillRectArea(X1, Y1, X2, Y2, Color: Integer);
Begin
 SetFillStyle(SolidFill, Color);
 Bar(X1, Y1, X2, Y2);
End;

Procedure DrawHLine(X1, X2, Y, Color: Integer);
Begin
 SetColor(Color);
 Line(X1, Y, X2, Y);
End;

Procedure DrawVLine(X, Y1, Y2, Color: Integer);
Begin
 SetColor(Color);
 Line(X, Y1, X, Y2);
End;

Procedure DrawFrameRect(X1, Y1, X2, Y2, Color: Integer);
Begin
 SetColor(Color);
 Rectangle(X1, Y1, X2, Y2);
End;

{ Bouton 3D style Win 3.x / Visio. Pressed=True ??? enfonc??. }
Procedure DrawButton3D(X1, Y1, X2, Y2: Integer; Pressed: Boolean);
Begin
 FillRectArea(X1+1, Y1+1, X2-1, Y2-1, CLR_3D_FACE);
 If Pressed Then Begin
  DrawHLine(X1, X2, Y1, CLR_3D_DARK);
  DrawVLine(X1, Y1, Y2, CLR_3D_DARK);
  DrawHLine(X1+1, X2-1, Y1+1, CLR_3D_SHADOW);
  DrawVLine(X1+1, Y1+1, Y2-1, CLR_3D_SHADOW);
  DrawHLine(X1, X2, Y2, CLR_3D_LIGHT);
  DrawVLine(X2, Y1, Y2, CLR_3D_LIGHT);
 End Else Begin
  DrawHLine(X1, X2, Y1, CLR_3D_LIGHT);
  DrawVLine(X1, Y1, Y2, CLR_3D_LIGHT);
  DrawHLine(X1, X2-1, Y2, CLR_3D_SHADOW);
  DrawVLine(X2, Y1, Y2, CLR_3D_SHADOW);
  DrawHLine(X1+1, X2-2, Y2-1, CLR_3D_DARK);
  DrawVLine(X2-1, Y1+1, Y2-1, CLR_3D_DARK);
 End;
End;

{ Cadre creux (ex. encadrement champ texte). }
Procedure DrawSunkenRect(X1, Y1, X2, Y2: Integer);
Begin
 DrawHLine(X1, X2, Y1, CLR_3D_DARK);
 DrawVLine(X1, Y1, Y2, CLR_3D_DARK);
 DrawHLine(X1, X2, Y2, CLR_3D_LIGHT);
 DrawVLine(X2, Y1, Y2, CLR_3D_LIGHT);
End;

Procedure DrawTextAt(X, Y: Integer; Const S: String; Color: Integer);
Begin
 SetColor(Color);
 OutTextXY(X, Y, S);
End;

{ OS/2-0 : barre de titre d'une boite de dialogue dans le style d'OS/2 :
  bleue, case du menu systeme a gauche, titre blanc centre }
Procedure OsTitleBar(X1, Y1, X2, Y2: Integer; Const T: String; TY: Integer);
Var S: Integer;
Begin
 FillRectArea(X1, Y1, X2, Y2, Blue);
 S := Y2 - Y1 - 2;
 If S > 3 Then Begin
  FillRectArea(X1 + 1, Y1 + 1, X1 + 1 + S, Y1 + 1 + S, LightGray);
  DrawHLine(X1 + 1, X1 + 1 + S, Y1 + 1, White);
  DrawVLine(X1 + 1, Y1 + 1, Y1 + 1 + S, White);
  DrawHLine(X1 + 1, X1 + 1 + S, Y1 + 1 + S, DarkGray);
  DrawVLine(X1 + 1 + S, Y1 + 1, Y1 + 1 + S, DarkGray);
  FillRectArea(X1 + 4, Y1 + 1 + S Div 2, X1 + S - 2, Y1 + 2 + S Div 2, Black);
 End;
 DrawTextAt((X1 + S + X2 - TextWidth(T)) Div 2, TY, T, White);
End;

{ Dessine une cha??ne avec un caract??re soulign?? (raccourci Alt). }
{ Retire les marqueurs '&' d'une chaine (utilise pour le calcul de largeur). }
Function StripAmp(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := '';
 I := 1;
 While I <= Length(S) Do Begin
  If (S[I] = '&') And (I < Length(S)) Then Begin
   R := R + S[I+1];
   Inc(I, 2);
  End Else Begin
   R := R + S[I];
   Inc(I);
  End;
 End;
 StripAmp := R;
End;

Procedure DrawTextWithAlt(X, Y: Integer; Const S: String;
                          AltCh: Char; Color: Integer);
Var
 I, Px, UX, UW : Integer;
 Disp          : String;
 HasAmp        : Boolean;
 Found         : Boolean;
 Up            : Char;
Begin
 SetColor(Color);
 { Analyse '&' : construit la chaine sans '&' et repere le caractere souligne. }
 Disp := '';
 HasAmp := False;
 UX := X; UW := 0;
 I := 1;
 While I <= Length(S) Do Begin
  If (S[I] = '&') And (I < Length(S)) Then Begin
   HasAmp := True;
   UX := X + TextWidth(Disp);
   UW := TextWidth(S[I+1]);
   Disp := Disp + S[I+1];
   Inc(I, 2);
  End Else Begin
   Disp := Disp + S[I];
   Inc(I);
  End;
 End;
 OutTextXY(X, Y, Disp);
 If HasAmp Then Begin
  Line(UX, Y+8, UX + UW - 1, Y+8);
  Exit;
 End;
 { Aucun '&' explicite : utiliser AltCh par recherche du premier caractere
   correspondant. }
 If AltCh = #0 Then Exit;
 Found := False;
 Px := X;
 Up := UpCase(AltCh);
 For I := 1 To Length(Disp) Do Begin
  If (Not Found) And (UpCase(Disp[I]) = Up) Then Begin
   Line(Px, Y+8, Px + TextWidth(Disp[I]) - 1, Y+8);
   Found := True;
  End;
  Inc(Px, TextWidth(Disp[I]));
 End;
End;

{ Conversion ReadKey #0+code ??? code ??tendu (>=256). }
Function ReadKeyEx: Word;
Var Ch: Char;
Begin
 Ch := ReadKey;
 If Ch = #0 Then Begin
  Ch := ReadKey;
  ReadKeyEx := 256 + Ord(Ch);
 End Else
  ReadKeyEx := Ord(Ch);
End;

{ ============================================================ }
{ =================  CURSEUR SOURIS LOGICIEL  ================ }
{ ============================================================ }
{ Sous Turbo Pascal + Int 33h, le curseur mat??riel est g??r??    }
{ par le pilote.  Sous PtcMouse il est invisible : on dessine  }
{ une fl??che logicielle avec backing store via GetImage.       }


{ OS/2-0 : le pointeur de la souris est celui de Presentation Manager }
Procedure DrawSoftCursor(X, Y: Integer);
Begin
End;

Procedure EraseSoftCursor;
Begin
End;


{ ============================================================ }
{ ===================  INIT MENUS / TOOLBARS  ================ }
{ ============================================================ }

Procedure SetMenuItem(M: Integer; Idx: Integer; Const Cap: String;
                     Const Sc: String; Alt: Char; Sep: Boolean;
                     Act: Integer);
Begin
 Menus[M].Items[Idx].Caption   := Cap;
 Menus[M].Items[Idx].Shortcut  := TrShortcut(Sc);
 Menus[M].Items[Idx].AltKey    := AltFromCaption(Cap, Alt);
 Menus[M].Items[Idx].Separator := Sep;
 Menus[M].Items[Idx].ActionId  := Act;
 Menus[M].Items[Idx].Enabled   := True;
End;

Procedure SetMenuTitle(M: Integer; Const Cap: String; Alt: Char);
Begin
 Menus[M].Caption := Cap;
 Menus[M].AltKey  := AltFromCaption(Cap, Alt);
End;

Procedure InitMenus;
Var I, MaxW, W, J, X: Integer;
Begin
 MenuCount := 9;
 { --- D??finition des menus --- }
 SetMenuTitle(1, Tr('&Fichier'), 'F');
 SetMenuTitle(2, Tr('&Edition'), 'E');
 SetMenuTitle(3, Tr('&Affichage'), 'A');
 SetMenuTitle(4, Tr('&Insertion'), 'I');
 SetMenuTitle(5, Tr('F&ormat'), 'O');
 SetMenuTitle(6, Tr('O&utils'), 'U');
 SetMenuTitle(7, Tr('&Tableau'), 'T');
 SetMenuTitle(8, Tr('Fe&netre'), 'N');
 SetMenuTitle(9, Tr('Ai&de'), 'D');

 { Fichier }
 Menus[1].ItemCount := 7;
 SetMenuItem(1,1,Tr('&Nouveau'),              'Ctrl+N','N',False, ACT_FILE_NEW);
 SetMenuItem(1,2,Tr('&Ouvrir...'),            'Ctrl+O','O',False,
   ACT_FILE_OPEN);
 SetMenuItem(1,3,Tr('&Enregistrer'),          'Ctrl+S','E',False,
   ACT_FILE_SAVE);
 SetMenuItem(1,4,Tr('Enregistrer &sous...'),  '',      'S',False,
   ACT_FILE_SAVEAS);
 SetMenuItem(1,5,'-',                     '',      #0, True, ACT_NONE);
 SetMenuItem(1,6,Tr('&Imprimer...'),          'Ctrl+P','I',False,
   ACT_FILE_PRINT);
 SetMenuItem(1,7,Tr('&Quitter'),              'Alt+X', 'Q',False,
   ACT_FILE_EXIT);

 { Edition }
 Menus[2].ItemCount := 9;
 SetMenuItem(2,1,Tr('&Annuler'),              'Ctrl+Z','A',False,
   ACT_EDIT_UNDO);
 SetMenuItem(2,2,Tr('&Retablir'),             'Ctrl+Y','R',False,
   ACT_EDIT_REDO);
 SetMenuItem(2,3,'-',                     '',      #0, True, ACT_NONE);
 SetMenuItem(2,4,Tr('Co&uper'),               'Ctrl+X','U',False, ACT_EDIT_CUT);
 SetMenuItem(2,5,Tr('&Copier'),               'Ctrl+C','C',False,
   ACT_EDIT_COPY);
 SetMenuItem(2,6,Tr('Co&ller'),               'Ctrl+V','L',False,
   ACT_EDIT_PASTE);
 SetMenuItem(2,7,Tr('Rec&hercher...'),        'Ctrl+F','H',False,
   ACT_EDIT_FIND);
 SetMenuItem(2,8,Tr('Rechercher &suivant'),   'F3',    'S',False,
   ACT_EDIT_FIND_NEXT);
 SetMenuItem(2,9,Tr('Re&mplacer...'),         'Ctrl+H','M',False,
   ACT_EDIT_REPL);

 { Affichage }
 Menus[3].ItemCount := 4;
 SetMenuItem(3,1,Tr('&Normal'),               '',      'N',False,
   ACT_VIEW_NORMAL);
 SetMenuItem(3,2,Tr('&Mise en page'),         '',      'M',False,
   ACT_VIEW_PAGE);
 SetMenuItem(3,3,Tr('&Regle'),                '',      'R',False,
   ACT_VIEW_RULER);
 SetMenuItem(3,4,Tr('&Zoom...'),              '',      'Z',False,
   ACT_VIEW_ZOOM);

 { Insertion }
 Menus[4].ItemCount := 4;
 SetMenuItem(4,1,Tr('&Saut de page'),         'Ctrl+Enter','S',False,
   ACT_INS_PAGEBRK);
 SetMenuItem(4,2,Tr('&Image...'),             '',      'I',False,
   ACT_INS_IMAGE);
 SetMenuItem(4,3,Tr('Symbo&le...'),           '',      'L',False,
   ACT_INS_SYMBOL);
 SetMenuItem(4,4,Tr('&Tableau...'),           '',      'T',False,
   ACT_INS_TABLE);

 { Format }
 Menus[5].ItemCount := 10;
 SetMenuItem(5,1,Tr('&Police...'),            '',      'P',False, ACT_FMT_FONT);
 SetMenuItem(5,2,Tr('Para&graphe...'),        '',      'G',False, ACT_FMT_PARA);
 SetMenuItem(5,3,'-',                     '',      #0, True, ACT_NONE);
 SetMenuItem(5,4,Tr('G&ras'),                 'Ctrl+B','R',False, ACT_FMT_BOLD);
 SetMenuItem(5,5,Tr('&Italique'),             'Ctrl+I','I',False,
   ACT_FMT_ITALIC);
 SetMenuItem(5,6,Tr('&Souligne'),             'Ctrl+U','S',False,
   ACT_FMT_UNDER);
 SetMenuItem(5,7,'-',                     '',      #0, True, ACT_NONE);
 SetMenuItem(5,8,Tr('Aligner a g&auche'),     'Ctrl+L','A',False, ACT_FMT_LEFT);
 SetMenuItem(5,9,Tr('&Centrer'),              'Ctrl+E','C',False,
   ACT_FMT_CENTER);
 SetMenuItem(5,10,Tr('Aligner a &droite'),    'Ctrl+R','D',False,
   ACT_FMT_RIGHT);

 { Outils }
 Menus[6].ItemCount := 3;
 SetMenuItem(6,1,Tr('&Orthographe...'),       'F7',    'O',False,
   ACT_TLS_SPELL);
 SetMenuItem(6,2,Tr('Stat&istiques...'),      '',      'I',False,
   ACT_TLS_WORDS);
 SetMenuItem(6,3,Tr('O&ptions...'),           '',      'P',False,
   ACT_TLS_OPTIONS);

 { Tableau }
 Menus[7].ItemCount := 2;
 SetMenuItem(7,1,Tr('&Inserer un tableau...'),'',      'I',False,
   ACT_TBL_INSERT);
 SetMenuItem(7,2,Tr('&Supprimer le tableau'), '',      'S',False,
   ACT_TBL_DELETE);

 { Fenetre }
 Menus[8].ItemCount := 1;
 SetMenuItem(8,1,Tr('&Cascade'),              '',      'C',False,
   ACT_WIN_CASCADE);

 { Aide }
 Menus[9].ItemCount := 2;
 SetMenuItem(9,1,Tr('&Sommaire...'),          'F1',    'S',False,
   ACT_HLP_CONTENT);
 SetMenuItem(9,2,Tr('A &propos...'),          '',      'P',False,
   ACT_HLP_ABOUT);

 { --- Calcul positions X dans la barre de menus --- }
 X := 6;
 If RibbonMode Then Begin
  SetMenuTitle(2,Tr('Accu&eil'),'E');Menus[2].ItemCount:=16;
  Menus[2].Items[8].Caption:=Tr('Suivant');
  Menus[2].Items[8].AltKey:=
   AltFromCaption(Menus[2].Items[8].Caption,'S');
  SetMenuItem(2,10,Tr('G&ras'),'Ctrl+B','R',False,ACT_FMT_BOLD);
  SetMenuItem(2,11,Tr('&Italique'),'Ctrl+I','I',False,ACT_FMT_ITALIC);
  SetMenuItem(2,12,Tr('&Souligne'),'Ctrl+U','S',False,ACT_FMT_UNDER);
  SetMenuItem(2,13,Tr('Gauche'),'Ctrl+L','G',False,ACT_FMT_LEFT);
  SetMenuItem(2,14,Tr('Centrer'),'Ctrl+E','C',False,ACT_FMT_CENTER);
  SetMenuItem(2,15,Tr('Droite'),'Ctrl+R','D',False,ACT_FMT_RIGHT);
  SetMenuItem(2,16,Tr('Justifier'),'','J',False,ACT_FMT_JUSTIFY);
  Menus[5].ItemCount:=11;
  SetMenuItem(5,11,Tr('&Justifier'),'','J',False,ACT_FMT_JUSTIFY);
 End;
 For I := 1 To MenuCount Do Begin
  Menus[I].X1 := X;
  W := TextWidth(StripAmp(Menus[I].Caption)) + 12;   { padding }
  Menus[I].X2 := X + W;
  X := X + W + 2;
 End;

 { --- Largeur dropdown = max largeur item + raccourci --- }
 For I := 1 To MenuCount Do Begin
  MaxW := 0;
  For J := 1 To Menus[I].ItemCount Do Begin
   W := TextWidth(StripAmp(Menus[I].Items[J].Caption));
   If Menus[I].Items[J].Shortcut <> '' Then
    W := W + 24 + TextWidth(Menus[I].Items[J].Shortcut);
   If W > MaxW Then MaxW := W;
  End;
  Menus[I].DropW := MaxW + 24;
 End;
End;

Procedure AddStdBtn(IconId, ActId: Integer; Const Tip: String;
                    Sep: Boolean);
Begin
 Inc(StdBarCount);
 StdBar[StdBarCount].IconId    := IconId;
 StdBar[StdBarCount].ActionId  := ActId;
 StdBar[StdBarCount].Tooltip   := Tip;
 StdBar[StdBarCount].Pressed   := False;
 StdBar[StdBarCount].Separator := Sep;
End;

Procedure AddFmtBtn(IconId, ActId: Integer; Const Tip: String;
                    Sep: Boolean);
Begin
 Inc(FmtBarCount);
 FmtBar[FmtBarCount].IconId    := IconId;
 FmtBar[FmtBarCount].ActionId  := ActId;
 FmtBar[FmtBarCount].Tooltip   := Tip;
 FmtBar[FmtBarCount].Pressed   := False;
 FmtBar[FmtBarCount].Separator := Sep;
End;

Procedure InitToolbars;
Var
 I, X, Y, BtnW : Integer;
Begin
 StdBarCount := 0;
 AddStdBtn(ICN_NEW,    ACT_FILE_NEW,   Tr('New (Ctrl+N)'),    False);
 AddStdBtn(ICN_OPEN,   ACT_FILE_OPEN,  Tr('Open (Ctrl+O)'),   False);
 AddStdBtn(ICN_SAVE,   ACT_FILE_SAVE,  Tr('Save (Ctrl+S)'),   False);
 AddStdBtn(ICN_PRINT,  ACT_FILE_PRINT, Tr('Print (Ctrl+P)'),  True);
 AddStdBtn(ICN_CUT,    ACT_EDIT_CUT,   Tr('Cut (Ctrl+X)'),    False);
 AddStdBtn(ICN_COPY,   ACT_EDIT_COPY,  Tr('Copy (Ctrl+C)'),   False);
 AddStdBtn(ICN_PASTE,  ACT_EDIT_PASTE, Tr('Paste (Ctrl+V)'),  True);
 AddStdBtn(ICN_UNDO,   ACT_EDIT_UNDO,  Tr('Undo (Ctrl+Z)'),   False);
 AddStdBtn(ICN_REDO,   ACT_EDIT_REDO,  Tr('Redo (Ctrl+Y)'),   True);
 AddStdBtn(ICN_IMAGE,  ACT_INS_IMAGE,  Tr('Insert Picture'),  False);
 AddStdBtn(ICN_TABLE,  ACT_INS_TABLE,  Tr('Insert Table'),    False);

 X := 6;
 Y := STDBAR_TOP + 1;
 BtnW := STDBAR_BTN;
 For I := 1 To StdBarCount Do Begin
  StdBar[I].X := X;
  StdBar[I].Y := Y;
  StdBar[I].W := BtnW;
  StdBar[I].H := BtnW;
  X := X + BtnW + 1;
  If StdBar[I].Separator Then X := X + 6;
 End;

 FmtBarCount := 0;
 AddFmtBtn(ICN_BOLD,    ACT_FMT_BOLD,    Tr('Bold (Ctrl+B)'),    False);
 AddFmtBtn(ICN_ITALIC,  ACT_FMT_ITALIC,  Tr('Italic (Ctrl+I)'),  False);
 AddFmtBtn(ICN_UNDER,   ACT_FMT_UNDER,   Tr('Underline (Ctrl+U)'),False);
 AddFmtBtn(ICN_ALIGN_L, ACT_FMT_LEFT,    Tr('Align Left'),       True);
 AddFmtBtn(ICN_ALIGN_C, ACT_FMT_CENTER,  Tr('Align Center'),     False);
 AddFmtBtn(ICN_ALIGN_R, ACT_FMT_RIGHT,   Tr('Align Right'),      False);
 AddFmtBtn(ICN_ALIGN_J, ACT_FMT_JUSTIFY, Tr('Justify'),          False);

 { Police taille combo : on r??serve la place visuelle dans la barre }
 X := 6 + 100;     { apr??s le combo "Times New Roman" }
 X := X + 50;      { apr??s combo taille }
 Y := FMTBAR_TOP + 1;
 BtnW := FMTBAR_BTN;
 For I := 1 To FmtBarCount Do Begin
  FmtBar[I].X := X;
  FmtBar[I].Y := Y;
  FmtBar[I].W := BtnW;
  FmtBar[I].H := BtnW;
  X := X + BtnW + 1;
  If FmtBar[I].Separator Then X := X + 6;
 End;
End;

{ ============================================================ }
{ ====================  IC??NES VECTORIELLES  ================= }
{ ============================================================ }

Procedure IconSetColor(Color: Integer);
Begin If RibbonInk>=0 Then Color:=RibbonInk;SetColor(Color);End;
Procedure IconSetFillStyle(Style,Color: Integer);
Begin
 If RibbonInk>=0 Then Begin
  Color:=MENUBAR_BG;If RibbonInk=White Then Color:=MENUBAR_HL_BG;
 End;
 SetFillStyle(Style,Color);
End;
Procedure IconFillRect(X1,Y1,X2,Y2,Color: Integer);
Begin
 If RibbonInk>=0 Then Begin
  Color:=MENUBAR_BG;If RibbonInk=White Then Color:=MENUBAR_HL_BG;
 End;
 FillRectArea(X1,Y1,X2,Y2,Color);
End;

Procedure DrawIcon(IconId, Cx, Cy: Integer);
Begin
 Case IconId Of
  ICN_NEW: Begin
   { Feuille blanche avec coin pli?? }
   IconFillRect(Cx-5, Cy-7, Cx+4, Cy+7, White);
   IconSetColor(Black);
   Rectangle(Cx-5, Cy-7, Cx+4, Cy+7);
   Line(Cx+1, Cy-7, Cx+4, Cy-4);
   Line(Cx+1, Cy-7, Cx+1, Cy-4);
   Line(Cx+1, Cy-4, Cx+4, Cy-4);
  End;
  ICN_OPEN: Begin
   { Dossier ouvert }
   IconSetFillStyle(SolidFill, Yellow);
   Bar(Cx-7, Cy-2, Cx+7, Cy+6);
   IconSetColor(DarkGray);
   Rectangle(Cx-7, Cy-2, Cx+7, Cy+6);
   Line(Cx-7, Cy-2, Cx-3, Cy-5);
   Line(Cx-3, Cy-5, Cx+1, Cy-5);
   Line(Cx+1, Cy-5, Cx+3, Cy-2);
  End;
  ICN_SAVE: Begin
   { Disquette 3.5" }
   IconSetFillStyle(SolidFill, Blue);
   Bar(Cx-7, Cy-7, Cx+7, Cy+7);
   IconSetColor(Black);
   Rectangle(Cx-7, Cy-7, Cx+7, Cy+7);
   IconFillRect(Cx-4, Cy-7, Cx+4, Cy-2, LightGray);
   IconFillRect(Cx-2, Cy-6, Cx-1, Cy-3, Black);
   IconFillRect(Cx-5, Cy+1, Cx+5, Cy+6, White);
  End;
  ICN_PRINT: Begin
   { Imprimante }
   IconFillRect(Cx-5, Cy-5, Cx+5, Cy-1, LightGray);
   IconSetColor(Black);
   Rectangle(Cx-7, Cy-1, Cx+7, Cy+4);
   IconFillRect(Cx-4, Cy+4, Cx+4, Cy+7, White);
   Rectangle(Cx-4, Cy+4, Cx+4, Cy+7);
  End;
  ICN_CUT: Begin
   { Ciseaux }
   IconSetColor(Black);
   Line(Cx-6, Cy-7, Cx+5, Cy+5);
   Line(Cx-6, Cy+5, Cx+5, Cy-7);
   Circle(Cx-5, Cy+5, 2);
   Circle(Cx+5, Cy+5, 2);
  End;
  ICN_COPY: Begin
   { Deux feuilles superpos??es }
   IconFillRect(Cx-6, Cy-6, Cx+2, Cy+4, White);
   IconSetColor(Black);
   Rectangle(Cx-6, Cy-6, Cx+2, Cy+4);
   IconFillRect(Cx-3, Cy-3, Cx+5, Cy+7, White);
   Rectangle(Cx-3, Cy-3, Cx+5, Cy+7);
  End;
  ICN_PASTE: Begin
   { Presse-papiers + feuille }
   IconSetFillStyle(SolidFill, LightGray);
   Bar(Cx-6, Cy-6, Cx+6, Cy+7);
   IconSetColor(Black);
   Rectangle(Cx-6, Cy-6, Cx+6, Cy+7);
   IconFillRect(Cx-2, Cy-7, Cx+2, Cy-5, DarkGray);
   IconFillRect(Cx-3, Cy-2, Cx+5, Cy+5, White);
   Rectangle(Cx-3, Cy-2, Cx+5, Cy+5);
  End;
  ICN_UNDO: Begin
   { Fl??che courb??e vers la gauche }
   IconSetColor(Blue);
   Arc(Cx, Cy, 30, 180, 6);
   Line(Cx-6, Cy, Cx-3, Cy-3);
   Line(Cx-6, Cy, Cx-3, Cy+3);
  End;
  ICN_REDO: Begin
   IconSetColor(Blue);
   Arc(Cx, Cy, 0, 150, 6);
   Line(Cx+6, Cy, Cx+3, Cy-3);
   Line(Cx+6, Cy, Cx+3, Cy+3);
  End;
  ICN_BOLD: Begin
   IconSetColor(Black);
   { Lettre "B" ??paisse }
   OutTextXY(Cx-3, Cy-4, 'B');
   OutTextXY(Cx-2, Cy-4, 'B');
  End;
  ICN_ITALIC: Begin
   IconSetColor(Black);
   { Lettre "I" inclin??e approxim??e }
   Line(Cx-2, Cy-5, Cx+2, Cy-5);
   Line(Cx, Cy-5, Cx-2, Cy+5);
   Line(Cx-4, Cy+5, Cx, Cy+5);
  End;
  ICN_UNDER: Begin
   IconSetColor(Black);
   OutTextXY(Cx-3, Cy-5, 'U');
   Line(Cx-4, Cy+5, Cx+4, Cy+5);
  End;
  ICN_ALIGN_L: Begin
   IconSetColor(Black);
   Line(Cx-7, Cy-5, Cx+7, Cy-5);
   Line(Cx-7, Cy-2, Cx+3, Cy-2);
   Line(Cx-7, Cy+1, Cx+7, Cy+1);
   Line(Cx-7, Cy+4, Cx+3, Cy+4);
  End;
  ICN_ALIGN_C: Begin
   IconSetColor(Black);
   Line(Cx-7, Cy-5, Cx+7, Cy-5);
   Line(Cx-5, Cy-2, Cx+5, Cy-2);
   Line(Cx-7, Cy+1, Cx+7, Cy+1);
   Line(Cx-5, Cy+4, Cx+5, Cy+4);
  End;
  ICN_ALIGN_R: Begin
   IconSetColor(Black);
   Line(Cx-7, Cy-5, Cx+7, Cy-5);
   Line(Cx-3, Cy-2, Cx+7, Cy-2);
   Line(Cx-7, Cy+1, Cx+7, Cy+1);
   Line(Cx-3, Cy+4, Cx+7, Cy+4);
  End;
  ICN_ALIGN_J: Begin
   IconSetColor(Black);
   Line(Cx-7, Cy-5, Cx+7, Cy-5);
   Line(Cx-7, Cy-2, Cx+7, Cy-2);
   Line(Cx-7, Cy+1, Cx+7, Cy+1);
   Line(Cx-7, Cy+4, Cx+7, Cy+4);
  End;
  ICN_IMAGE: Begin
   { Cadre photo avec montagne }
   IconFillRect(Cx-7, Cy-6, Cx+7, Cy+6, White);
   IconSetColor(Black);
   Rectangle(Cx-7, Cy-6, Cx+7, Cy+6);
   IconSetFillStyle(SolidFill, Yellow);
   FillEllipse(Cx-3, Cy-2, 2, 2);
   IconSetColor(Green);
   Line(Cx-7, Cy+5, Cx-2, Cy);
   Line(Cx-2, Cy, Cx+3, Cy+5);
   Line(Cx+1, Cy+2, Cx+7, Cy+5);
  End;
  ICN_TABLE: Begin
   IconSetColor(Black);
   Rectangle(Cx-7, Cy-6, Cx+7, Cy+6);
   Line(Cx-7, Cy-2, Cx+7, Cy-2);
   Line(Cx-7, Cy+2, Cx+7, Cy+2);
   Line(Cx-2, Cy-6, Cx-2, Cy+6);
   Line(Cx+3, Cy-6, Cx+3, Cy+6);
  End;
 End;
End;

{ ============================================================ }
{ =====================  DESSIN INTERFACE  =================== }
{ ============================================================ }

Function ViewActionChecked(Act:Integer):Boolean;
Begin
 ViewActionChecked:=False;
 Case Act Of
  ACT_VIEW_NORMAL:ViewActionChecked:=Not PageLayoutView;
  ACT_VIEW_PAGE:ViewActionChecked:=PageLayoutView;
  ACT_VIEW_RULER:ViewActionChecked:=RulerVisible;
 End;
End;

Function RibbonActionEnabled(Act: Integer): Boolean;
Begin
 RibbonActionEnabled:=False;
 Case Act Of
  ACT_FILE_NEW,ACT_FILE_OPEN,ACT_FILE_SAVE,ACT_FILE_SAVEAS,ACT_FILE_EXIT,
  ACT_EDIT_UNDO,ACT_EDIT_REDO,ACT_EDIT_FIND,ACT_EDIT_FIND_NEXT,ACT_EDIT_REPL,
  ACT_INS_PAGEBRK,ACT_INS_IMAGE,ACT_INS_TABLE,ACT_TBL_INSERT,ACT_TBL_DELETE,
  ACT_FMT_BOLD,ACT_FMT_ITALIC,ACT_FMT_UNDER,ACT_FMT_LEFT,ACT_FMT_CENTER,
  ACT_FMT_RIGHT,ACT_FMT_JUSTIFY,ACT_FMT_COLOR,ACT_TLS_WORDS,ACT_HLP_ABOUT,
    ACT_VIEW_ZOOM,ACT_VIEW_NORMAL,ACT_VIEW_PAGE,ACT_VIEW_RULER:
   RibbonActionEnabled:=True;
 End;
End;

Function RibbonItemCount: Integer;
Var I,N: Integer;
Begin
 N:=0;For I:=1 To Menus[RibbonTab].ItemCount Do
  If Not Menus[RibbonTab].Items[I].Separator Then Inc(N);
 RibbonItemCount:=N;
End;
Function RibbonMenuItem(Index: Integer): Integer;
Var I,N: Integer;
Begin
 RibbonMenuItem:=0;N:=0;
 For I:=1 To Menus[RibbonTab].ItemCount Do If Not
   Menus[RibbonTab].Items[I].Separator Then Begin
  Inc(N);If N=Index Then Begin RibbonMenuItem:=I;Exit;End;
 End;
End;
Function RibbonEntryAction(Index: Integer): Integer;
Begin
 RibbonEntryAction:=ACT_NONE;
 If (Index>=1) And (Index<=RibbonItemCount) Then
  RibbonEntryAction:=Menus[RibbonTab].Items[RibbonMenuItem(Index)].ActionId;
End;
Function RibbonEntryEnabled(Index: Integer): Boolean;
Var RibbonEntryEnabled_R: Boolean;
Begin
 RibbonEntryEnabled_R:=RibbonActionEnabled(RibbonEntryAction(Index));
 If (Index>=1) And (Index<=RibbonItemCount) Then
  RibbonEntryEnabled_R:=RibbonEntryEnabled_R And
    Menus[RibbonTab].Items[RibbonMenuItem(Index)].Enabled;
 RibbonEntryEnabled := RibbonEntryEnabled_R;
End;
Procedure RibbonButtonBox(Index: Integer;Var X,Y,W,H: Integer);
Var Columns: Integer;
Begin
 Columns:=(RibbonItemCount+2) Div 3;If Columns<3 Then Columns:=3;
 W:=(SCREEN_W-16) Div Columns;
 H:=24;X:=8+((Index-1) Div 3)*W;
 Y:=MENUBAR_HEIGHT+4+((Index-1) Mod 3)*H;
End;
Function RibbonHitAt(X,Y: LongInt): Integer;
Var I,BX,BY,W,H: Integer;
Begin
 RibbonHitAt:=0;If Not RibbonMode Then Exit;
 For I:=1 To RibbonItemCount Do Begin
  RibbonButtonBox(I,BX,BY,W,H);
  If (X>=BX) And (X<BX+W-4) And (Y>=BY) And (Y<BY+H-2) Then Begin
    RibbonHitAt:=I;Exit;End;
 End;
End;
Function RibbonActionIcon(Act: Integer): Integer;
Var I,Icon: Integer;
Begin
 Icon:=0;
 For I:=1 To StdBarCount Do If StdBar[I].ActionId=Act Then
   Icon:=StdBar[I].IconId;
 For I:=1 To FmtBarCount Do If FmtBar[I].ActionId=Act Then
   Icon:=FmtBar[I].IconId;
 Case Act Of
  ACT_FILE_SAVEAS: Icon:=ICN_SAVE;
  ACT_TBL_INSERT,ACT_TBL_DELETE: Icon:=ICN_TABLE;
  ACT_FMT_FONT: Icon:=ICN_BOLD;
  ACT_FMT_PARA: Icon:=ICN_ALIGN_J;
 End;
 RibbonActionIcon:=Icon;
End;
Procedure DrawRibbonActionIcon(Act,X,Y,Color: Integer);
Var Icon,J: Integer;
Begin
 Icon:=RibbonActionIcon(Act);RibbonInk:=-1;
 If Color<>Black Then RibbonInk:=Color;
 If Icon<>0 Then DrawIcon(Icon,X,Y)
 Else Begin
  SetColor(Color);
  Case Act Of
   ACT_EDIT_FIND,ACT_EDIT_FIND_NEXT,ACT_EDIT_REPL,ACT_VIEW_ZOOM: Begin
    Circle(X-2,Y-2,5);Line(X+2,Y+2,X+7,Y+7);
    If Act=ACT_EDIT_REPL Then Line(X-7,Y+7,X-1,Y+7);
   End;
   ACT_FILE_EXIT: Begin
    Rectangle(X-6,Y-7,X+2,Y+7);Line(X-2,Y,X+7,Y);
    Line(X+4,Y-3,X+7,Y);Line(X+4,Y+3,X+7,Y);
   End;
   ACT_HLP_ABOUT,ACT_HLP_CONTENT: Begin
    Circle(X,Y,7);OutTextXY(X-3,Y-4,'i');
   End;
   ACT_TLS_WORDS,ACT_TLS_SPELL: Begin
    OutTextXY(X-7,Y-7,'AB');Line(X-6,Y+4,X-2,Y+7);Line(X-2,Y+7,X+6,Y+1);
   End;
   ACT_TLS_OPTIONS: For J:=0 To 2 Do Begin
    Line(X-7,Y-5+J*5,X+7,Y-5+J*5);Rectangle(X-5+J*3,Y-7+J*5,X-3+J*3,Y-3+J*5);
   End;
   Else Begin
    Rectangle(X-6,Y-7,X+6,Y+7);
    Line(X-3,Y-3,X+3,Y-3);Line(X-3,Y,X+3,Y);Line(X-3,Y+3,X+3,Y+3);
    If Act=ACT_INS_PAGEBRK Then Line(X-7,Y,X+7,Y);
   End;
  End;
 End;
 RibbonInk:=-1;
End;
Procedure DrawRibbon;
Var I,Item,Act,X,Y,W,H,Color: Integer;Caption,SizeText: String;
Begin
 FillRectArea(0,MENUBAR_HEIGHT,SCREEN_W-1,STDBAR_TOP-1,MENUBAR_BG);
 For I:=1 To RibbonItemCount Do Begin
  Item:=RibbonMenuItem(I);Act:=RibbonEntryAction(I);RibbonButtonBox(I,X,Y,W,H);
    Color:=Black;
  If Not RibbonEntryEnabled(I) Then Color:=DarkGray
  Else If (RibbonHover=I) Or (RibbonKeyboard And (RibbonFocus=I)) Or
    ViewActionChecked(Act) Then Begin
   FillRectArea(X,Y,X+W-5,Y+H-3,MENUBAR_HL_BG);Color:=White;
  End;
  DrawRibbonActionIcon(Act,X+12,Y+11,Color);
  Caption:=StripAmp(Menus[RibbonTab].Items[Item].Caption);
  While (Length(Caption)>0) And (TextWidth(Caption)>W-35) Do
   Caption:=Copy(Caption,1,Length(Caption)-1);
  DrawTextAt(X+27,Y+7,Caption,Color);
 End;
 DrawHLine(4,SCREEN_W-5,STDBAR_TOP-15,CLR_3D_DARK);
 DrawTextAt(8,STDBAR_TOP-11,StripAmp(Menus[RibbonTab].Caption),DarkGray);
 If (RibbonTab=2) Or (RibbonTab=5) Then Begin
  Str(CurrentStyle.FontSize,SizeText);
  DrawTextAt(360,STDBAR_TOP-11,'Times New Roman '+SizeText+' pt',DarkGray);
 End;
End;

Procedure OsSyncMenu; Forward;

Procedure DrawMenuBar;
Begin
 OsSyncMenu;
End;

Procedure DrawMenuDropdown;
Var
 M, I, X1, Y1, X2, Y2, ItY, IH : Integer;
 Item : TMenuItem;
Begin
 If RibbonMode Or (ActiveMenu < 1) Then Exit;
 M := ActiveMenu;
 IH := 16;
 X1 := Menus[M].X1;
 Y1 := MENUBAR_HEIGHT;
 X2 := X1 + Menus[M].DropW;
 Y2 := Y1 + Menus[M].ItemCount * IH + 4;
 If X2 > SCREEN_W-1 Then Begin
  X1 := SCREEN_W-1 - Menus[M].DropW;
  X2 := SCREEN_W-1;
 End;
 { Ombre }
 FillRectArea(X1+3, Y2+1, X2+3, Y2+3, Black);
 FillRectArea(X2+1, Y1+3, X2+3, Y2+3, Black);
 { Cadre }
 FillRectArea(X1, Y1, X2, Y2, MENUBAR_BG);
 SetColor(Black);
 Rectangle(X1, Y1, X2, Y2);
 DrawHLine(X1+1, X2-1, Y1+1, CLR_3D_LIGHT);
 DrawVLine(X1+1, Y1+1, Y2-1, CLR_3D_LIGHT);

 For I := 1 To Menus[M].ItemCount Do Begin
  Item := Menus[M].Items[I];
  ItY := Y1 + 2 + (I-1)*IH;
  If Item.Separator Then Begin
   DrawHLine(X1+4, X2-4, ItY+IH Div 2, CLR_3D_DARK);
   DrawHLine(X1+4, X2-4, ItY+IH Div 2 + 1, CLR_3D_LIGHT);
  End Else Begin
   If MenuItemHover = I Then Begin
    FillRectArea(X1+2, ItY, X2-2, ItY+IH-1, MENUBAR_HL_BG);
    DrawTextWithAlt(X1+8, ItY+3, Item.Caption, Item.AltKey,
                    MENUBAR_HL_FG);
    If Item.Shortcut <> '' Then
     DrawTextAt(X2 - TextWidth(Item.Shortcut) - 8, ItY+3,
                Item.Shortcut, MENUBAR_HL_FG);
   End Else Begin
    DrawTextWithAlt(X1+8, ItY+3, Item.Caption, Item.AltKey,
                    MENUBAR_FG);
    If Item.Shortcut <> '' Then
     DrawTextAt(X2 - TextWidth(Item.Shortcut) - 8, ItY+3,
                Item.Shortcut, CLR_3D_DARK);
   End;
   If ViewActionChecked(Item.ActionId) Then Begin
    If MenuItemHover=I Then SetColor(MENUBAR_HL_FG) Else SetColor(MENUBAR_FG);
    Line(X1+3,ItY+8,X1+5,ItY+10);Line(X1+5,ItY+10,X1+7,ItY+5);
   End;
  End;
 End;
End;

Procedure DrawStdToolbar;
Var
 I, Cx, Cy : Integer;
Begin
 If RibbonMode Then Exit;
 FillRectArea(0, STDBAR_TOP, SCREEN_W-1,
              STDBAR_TOP+STDBAR_HEIGHT-1, STDBAR_BG);
 DrawHLine(0, SCREEN_W-1, STDBAR_TOP+STDBAR_HEIGHT-1, CLR_3D_DARK);
 For I := 1 To StdBarCount Do Begin
  DrawButton3D(StdBar[I].X, StdBar[I].Y,
               StdBar[I].X+StdBar[I].W,
               StdBar[I].Y+StdBar[I].H,
               (HoveredStdBtn = I) And ((MsBtn And MB_LEFT) <> 0));
  Cx := StdBar[I].X + StdBar[I].W Div 2;
  Cy := StdBar[I].Y + StdBar[I].H Div 2;
  DrawIcon(StdBar[I].IconId, Cx, Cy);
  If StdBar[I].Separator Then
   DrawVLine(StdBar[I].X+StdBar[I].W+3,
             StdBar[I].Y, StdBar[I].Y+StdBar[I].H, CLR_3D_DARK);
 End;
End;

Procedure DrawFmtToolbar;
Var
 I, Cx, Cy : Integer;
 SizeStr   : String[8];
Begin
 If RibbonMode Then Exit;
 FillRectArea(0, FMTBAR_TOP, SCREEN_W-1,
              FMTBAR_TOP+FMTBAR_HEIGHT-1, FMTBAR_BG);
 DrawHLine(0, SCREEN_W-1, FMTBAR_TOP+FMTBAR_HEIGHT-1, CLR_3D_DARK);

 { Combo "Police" - placeholder }
 FillRectArea(6, FMTBAR_TOP+2, 100, FMTBAR_TOP+FMTBAR_HEIGHT-3, White);
 DrawSunkenRect(6, FMTBAR_TOP+2, 100, FMTBAR_TOP+FMTBAR_HEIGHT-3);
 DrawTextAt(10, FMTBAR_TOP+5, 'Times New Roman', Black);
 SetColor(Black);
 { triangle dropdown }
 Line(92, FMTBAR_TOP+8,  98, FMTBAR_TOP+8);
 Line(93, FMTBAR_TOP+9,  97, FMTBAR_TOP+9);
 Line(94, FMTBAR_TOP+10, 96, FMTBAR_TOP+10);
 Line(95, FMTBAR_TOP+11, 95, FMTBAR_TOP+11);

 { Combo "Taille" }
 FillRectArea(106, FMTBAR_TOP+2, 150, FMTBAR_TOP+FMTBAR_HEIGHT-3, White);
 DrawSunkenRect(106, FMTBAR_TOP+2, 150, FMTBAR_TOP+FMTBAR_HEIGHT-3);
 Str(CurrentStyle.FontSize, SizeStr);
 DrawTextAt(112, FMTBAR_TOP+5, SizeStr, Black);
 Line(140, FMTBAR_TOP+8,  146, FMTBAR_TOP+8);
 Line(141, FMTBAR_TOP+9,  145, FMTBAR_TOP+9);
 Line(142, FMTBAR_TOP+10, 144, FMTBAR_TOP+10);
 Line(143, FMTBAR_TOP+11, 143, FMTBAR_TOP+11);

 For I := 1 To FmtBarCount Do Begin
  DrawButton3D(FmtBar[I].X, FmtBar[I].Y,
               FmtBar[I].X+FmtBar[I].W,
               FmtBar[I].Y+FmtBar[I].H, FmtBar[I].Pressed);
  Cx := FmtBar[I].X + FmtBar[I].W Div 2;
  Cy := FmtBar[I].Y + FmtBar[I].H Div 2;
  DrawIcon(FmtBar[I].IconId, Cx, Cy);
 End;
End;

Function ZoomValue:Integer;
Begin ZoomValue:=ZoomPercent;If (ZoomPercent<25) or (ZoomPercent>300) Then
  ZoomValue:=100;End;
Function ZoomX(X:Integer):Integer;
Begin ZoomX:=SCREEN_W div 2+LongInt(X-SCREEN_W div 2-ZoomPanX)*ZoomValue div
  100;End;
Function ZoomY(Y:Integer):Integer;
Begin ZoomY:=DOCAREA_TOP+LongInt(Y-DOCAREA_TOP)*ZoomValue div 100;End;
Function UnzoomX(X:Integer):Integer;
Begin UnzoomX:=SCREEN_W div 2+LongInt(X-SCREEN_W div 2)*100 div
  ZoomValue+ZoomPanX;End;
Function UnzoomY(Y:Integer):Integer;
Begin UnzoomY:=DOCAREA_TOP+LongInt(Y-DOCAREA_TOP)*100 div ZoomValue;End;
Function DocPhysicalBottom:Integer;
Begin
 DocPhysicalBottom:=DOCAREA_BOTTOM;
 If LongInt(PAGE_W)*ZoomValue div 100>SCREEN_W-16 Then
   DocPhysicalBottom:=DOCAREA_BOTTOM-12;
End;
Function DocBottom:Integer;
Begin DocBottom:=UnzoomY(DocPhysicalBottom);End;
Function ZoomPanLimit:Integer;
Var ZoomPanLimit_R: Integer;
Begin
 ZoomPanLimit_R:=(PAGE_W-(SCREEN_W-16)*100 div ZoomValue) div 2;
 If ZoomPanLimit_R<0 Then ZoomPanLimit_R:=0;
 ZoomPanLimit := ZoomPanLimit_R;
End;

Procedure ZoomLine(X1,Y1,X2,Y2:Integer);
Var VP:ViewPortType;
Begin
 GetViewSettings(VP);SetViewPort(0,DOCAREA_TOP,SCREEN_W-1,DocPhysicalBottom,
   ClipOn);
 Line(ZoomX(X1),ZoomY(Y1)-DOCAREA_TOP,ZoomX(X2),ZoomY(Y2)-DOCAREA_TOP);
 SetViewPort(VP.X1,VP.Y1,VP.X2,VP.Y2,VP.Clip);
End;
Procedure ZoomBar(X1,Y1,X2,Y2:Integer);
Var VP:ViewPortType;
Begin
 GetViewSettings(VP);SetViewPort(0,DOCAREA_TOP,SCREEN_W-1,DocPhysicalBottom,
   ClipOn);
 Bar(ZoomX(X1),ZoomY(Y1)-DOCAREA_TOP,ZoomX(X2+1)-1,ZoomY(Y2+1)-DOCAREA_TOP-1);
 SetViewPort(VP.X1,VP.Y1,VP.X2,VP.Y2,VP.Clip);
End;
Procedure ZoomRectangle(X1,Y1,X2,Y2:Integer);
Begin ZoomLine(X1,Y1,X2,Y1);ZoomLine(X2,Y1,X2,Y2);
 ZoomLine(X2,Y2,X1,Y2);ZoomLine(X1,Y2,X1,Y1);End;
Procedure ZoomFillRect(X1,Y1,X2,Y2,Color:Integer);
Begin SetFillStyle(SolidFill,Color);ZoomBar(X1,Y1,X2,Y2);End;
Procedure ZoomFrameRect(X1,Y1,X2,Y2,Color:Integer);
Begin SetColor(Color);ZoomRectangle(X1,Y1,X2,Y2);End;
Procedure ZoomPixel(X,Y:Integer;Color:Word);
Var X1,Y1,X2,Y2:Integer;
Begin
 X1:=ZoomX(X);X2:=ZoomX(X+1)-1;Y1:=ZoomY(Y);Y2:=ZoomY(Y+1)-1;
 If (X2<X1) or (Y2<Y1) Then Exit;
 If X1<0 Then X1:=0;If X2>=SCREEN_W Then X2:=SCREEN_W-1;
 If Y1<DOCAREA_TOP Then Y1:=DOCAREA_TOP;If Y2>DocPhysicalBottom Then
   Y2:=DocPhysicalBottom;
 If (X1<=X2) and (Y1<=Y2) Then Begin
   SetFillStyle(SolidFill,Color);Bar(X1,Y1,X2,Y2);End;
End;

Procedure DrawRuler;
Var
 I, X, PageX1, PageX2 : Integer;
 PMx                  : Integer;
Begin
 If Not RulerVisible Then Exit;
 FillRectArea(0, RULER_TOP, SCREEN_W-1,
              RULER_TOP+RULER_HEIGHT-1, RULER_BG);
 DrawHLine(0, SCREEN_W-1, RULER_TOP+RULER_HEIGHT-1, CLR_3D_DARK);

 { Centre la "page" : graduations en pouces (1 pouce ~= 50 px) }
 PageX1 := (SCREEN_W - PAGE_W) Div 2;
 PageX2 := PageX1 + PAGE_W;
 PMx := 50;   { 1 pouce visuel = 50 pixels }
 SetColor(RULER_FG);
 For I := 0 To 9 Do Begin
  X := ZoomX(PageX1 + PAGE_MARGIN_L + I*PMx);
  If (X>=0) and (X<ZoomX(PageX2)) and (X<SCREEN_W) Then Begin
   Line(X, RULER_TOP+9, X, RULER_TOP+12);
   { num??ros impairs / pairs }
   If I > 0 Then Begin
    SetColor(RULER_FG);
    Line(X-2, RULER_TOP+5, X+2, RULER_TOP+5);
   End;
  End;
 End;
 { Indication marges }
 SetColor(DarkGray);
 Line(ZoomX(PageX1+PAGE_MARGIN_L), RULER_TOP+1,
      ZoomX(PageX1+PAGE_MARGIN_L), RULER_TOP+RULER_HEIGHT-2);
 Line(ZoomX(PageX2-PAGE_MARGIN_R), RULER_TOP+1,
      ZoomX(PageX2-PAGE_MARGIN_R), RULER_TOP+RULER_HEIGHT-2);
End;

{ ============================================================ }
{ =================  PHASE 2 : LAYOUT / SAISIE  ============== }
{ ============================================================ }

Const
 MAX_VLINES        = 2000;
 LINE_HEIGHT       = 12;
 CURSOR_BLINK_TICKS= 25;     { ~500ms avec Delay(20) }
 MAX_IMG_W         = 340;    { largeur max image (= AvailW d'une page) }
 MAX_IMG_H         = 400;    { hauteur max image }

Type
 TVisualLine = Record
  ParaIdx   : Integer;       { 1..Doc.ParaCount }
  CharStart : Integer;       { 1-based offset dans paragraphe }
  CharLen   : Integer;       { nb caract??res de la ligne }
  PageIdx   : Integer;       { 1..Doc.PageCount }
  X, Y      : Integer;       { coords ??cran (sans ScrollY) }
  Width     : Integer;       { largeur pixel du texte }
  Height    : Integer;       { hauteur pixel (LINE_HEIGHT ou ImgH) }
  Alignment : Byte;
  IsImage   : Boolean;
  IsTable   : Boolean;       { Phase 11 : ligne de tableau }
  TblRow    : Integer;       { 1..Rows si IsTable, sinon 0 }
 End;

Var
 VLines           : Array[1..MAX_VLINES] Of TVisualLine;
 VLineCount       : Integer;
 NeedsRelayout    : Boolean;
 CursorBlinkOn    : Boolean;
 CursorBlinkCnt   : Integer;

{ ----- Manipulation paragraphes (Phase 2: 1 run / paragraphe) ----- }

Function ParaText(P: Integer): String;
Var I: Integer; S: String;
Begin
 S := '';
 For I := 1 To Doc^.Paragraphs[P].RunCount Do
  S := S + Doc^.Paragraphs[P].Runs[I].Text;
 ParaText := S;
End;

{ Largeur reelle (en pixels) d'une plage de caracteres du paragraphe P,
  en tenant compte du gras (qui ajoute +1 px par caractere car dessine
  deux fois avec un decalage de 1 px). StartIdx 1-based dans ParaText. }
Function PDFTextWidth(Const S,Face:String;H:Integer;Style:Byte):Integer;
  Forward;

Function RunHeight(Const Sty: TCharStyle): Integer;
Var Points: Integer;
Begin
 Points:=Sty.FontSize;
 If Points<6 Then Points:=12;
 If Points>72 Then Points:=72;
 
 RunHeight:=8*((Points+6) div 12);
 
End;

Function RunAdvance(Const Sty: TCharStyle): Integer;
Begin
 RunAdvance:=RunHeight(Sty)+Ord((Sty.Style and STY_BOLD)<>0);
End;

Function StyledRangeWidth(P, StartIdx, Len: Integer): Integer;
Var
 I, EndIdx, W, RunPos, RunLen           : Integer;
 OvStart, OvEnd, OvLen, LocalStart      : Integer;
 Sub                                    : String;
Begin
 If Doc^.Paragraphs[P].PDF.Active Then Begin
  StyledRangeWidth:=PDFTextWidth(Copy(ParaText(P),StartIdx,Len),
    Doc^.Paragraphs[P].PDF.Face,
   Doc^.Paragraphs[P].PDF.Height,Doc^.Paragraphs[P].Runs[1].Style.Style);Exit;
 End;
 W := 0;
 If Len <= 0 Then Begin StyledRangeWidth := 0; Exit; End;
 EndIdx := StartIdx + Len - 1;
 RunPos := 1;
 For I := 1 To Doc^.Paragraphs[P].RunCount Do Begin
  RunLen := Length(Doc^.Paragraphs[P].Runs[I].Text);
  If RunLen > 0 Then Begin
   OvStart := StartIdx;
   If RunPos > OvStart Then OvStart := RunPos;
   OvEnd := EndIdx;
   If RunPos + RunLen - 1 < OvEnd Then OvEnd := RunPos + RunLen - 1;
   If OvStart <= OvEnd Then Begin
    OvLen := OvEnd - OvStart + 1;
    LocalStart := OvStart - RunPos + 1;
    Sub := Copy(Doc^.Paragraphs[P].Runs[I].Text, LocalStart, OvLen);
    Inc(W, OvLen*RunAdvance(Doc^.Paragraphs[P].Runs[I].Style));
   End;
  End;
  Inc(RunPos, RunLen);
 End;
 StyledRangeWidth := W;
End;

{ Style.Style byte du run contenant la position 1-based AbsPos dans
  ParaText(P). Retourne 0 si hors limites. }
Function CharStyleAt(P, AbsPos: Integer): Byte;
Var I, RunPos, RunLen: Integer;
Begin
 CharStyleAt := 0;
 RunPos := 1;
 For I := 1 To Doc^.Paragraphs[P].RunCount Do Begin
  RunLen := Length(Doc^.Paragraphs[P].Runs[I].Text);
  If (AbsPos >= RunPos) And (AbsPos < RunPos + RunLen) Then Begin
   CharStyleAt := Doc^.Paragraphs[P].Runs[I].Style.Style;
   Exit;
  End;
  Inc(RunPos, RunLen);
 End;
End;

Procedure ParaSetText(P: Integer; Const S: String);
Begin
 If Doc^.Paragraphs[P].RunCount < 1 Then Begin
  Doc^.Paragraphs[P].RunCount := 1;
  Doc^.Paragraphs[P].Runs[1].Style := CurrentStyle;
 End;
 Doc^.Paragraphs[P].Runs[1].Text := S;
 { Phase 2 : on consolide en un seul run }
 Doc^.Paragraphs[P].RunCount := 1;
End;

{ ----- Phase 3 : helpers multi-run ----------------------------- }

Function StyleEq(Const A, B: TCharStyle): Boolean;
Begin
 StyleEq := (A.FontSize = B.FontSize) And
            (A.Style    = B.Style)    And
            (A.Color    = B.Color);
End;

{ Localise (RIdx, ROff) o? ins?rer un caract?re ? la position
  CharIdx (0-based, 0..Length(ParaText)). ROff est l'index 0-based
  dans Runs[RIdx].Text o? l'insertion aurait lieu (0..Length). }
Procedure LocateInsertion(P, CharIdx: Integer; Var RIdx, ROff: Integer);
Var Acc, K, L: Integer;
Begin
 Acc := 0;
 For K := 1 To Doc^.Paragraphs[P].RunCount Do Begin
  L := Length(Doc^.Paragraphs[P].Runs[K].Text);
  If CharIdx <= Acc + L Then Begin
   RIdx := K;
   ROff := CharIdx - Acc;
   Exit;
  End;
  Inc(Acc, L);
 End;
 RIdx := Doc^.Paragraphs[P].RunCount;
 If RIdx < 1 Then RIdx := 1;
 ROff := Length(Doc^.Paragraphs[P].Runs[RIdx].Text);
End;

{ Localise (RIdx, ROff) du caract?re ? la position CharIdx
  (0-based, 0..Length-1). ROff est l'index 0-based dans le run. }
Procedure LocateChar(P, CharIdx: Integer; Var RIdx, ROff: Integer);
Var Acc, K, L: Integer;
Begin
 Acc := 0;
 For K := 1 To Doc^.Paragraphs[P].RunCount Do Begin
  L := Length(Doc^.Paragraphs[P].Runs[K].Text);
  If CharIdx < Acc + L Then Begin
   RIdx := K;
   ROff := CharIdx - Acc;
   Exit;
  End;
  Inc(Acc, L);
 End;
 RIdx := Doc^.Paragraphs[P].RunCount;
 If RIdx < 1 Then RIdx := 1;
 ROff := Length(Doc^.Paragraphs[P].Runs[RIdx].Text) - 1;
 If ROff < 0 Then ROff := 0;
End;

{ Ins?re un run vide ? la position RIdx (les runs ?RIdx d?cal?s). }
Function InsertRunAt(P, RIdx: Integer): Boolean;
Var I: Integer;
Begin
 If Doc^.Paragraphs[P].RunCount >= MAX_RUNS_PER_PARA Then Begin
  InsertRunAt := False; Exit;
 End;
 For I := Doc^.Paragraphs[P].RunCount Downto RIdx Do
  Doc^.Paragraphs[P].Runs[I + 1] := Doc^.Paragraphs[P].Runs[I];
 Inc(Doc^.Paragraphs[P].RunCount);
 Doc^.Paragraphs[P].Runs[RIdx].Text := '';
 FillChar(Doc^.Paragraphs[P].Runs[RIdx].Style, SizeOf(TCharStyle), 0);
 InsertRunAt := True;
End;

Procedure RemoveRunAt(P, RIdx: Integer);
Var I: Integer;
Begin
 If (RIdx < 1) Or (RIdx > Doc^.Paragraphs[P].RunCount) Then Exit;
 For I := RIdx To Doc^.Paragraphs[P].RunCount - 1 Do
  Doc^.Paragraphs[P].Runs[I] := Doc^.Paragraphs[P].Runs[I + 1];
 FillChar(Doc^.Paragraphs[P].Runs[Doc^.Paragraphs[P].RunCount],
          SizeOf(TRun), 0);
 Dec(Doc^.Paragraphs[P].RunCount);
 If Doc^.Paragraphs[P].RunCount = 0 Then Begin
  Doc^.Paragraphs[P].RunCount := 1;
  Doc^.Paragraphs[P].Runs[1].Style := CurrentStyle;
  Doc^.Paragraphs[P].Runs[1].Text  := '';
 End;
End;

Procedure MergeAdjacentSameStyleRuns(P: Integer);
Var I: Integer;
Begin
 I := 1;
 While I < Doc^.Paragraphs[P].RunCount Do Begin
  If StyleEq(Doc^.Paragraphs[P].Runs[I].Style,
             Doc^.Paragraphs[P].Runs[I+1].Style) Then Begin
   Doc^.Paragraphs[P].Runs[I].Text :=
    Doc^.Paragraphs[P].Runs[I].Text + Doc^.Paragraphs[P].Runs[I+1].Text;
   RemoveRunAt(P, I+1);
  End Else
   Inc(I);
 End;
End;

{ Forward : helpers selection definis plus bas (apres CursorScreenX). }
Function  SelHasRange: Boolean; Forward;
Procedure SelGetRange(Var P1, C1, P2, C2: Integer); Forward;

{ Garantit une frontiere de run au caractere CharOff (0-based) du
  paragraphe P. Si CharOff tombe au milieu d'un run, le decoupe en
  deux runs adjacents de meme style. Retourne True en cas de succes
  (False uniquement si MAX_RUNS_PER_PARA atteint). }
Function SplitRunAtChar(P, CharOff: Integer): Boolean;
Var
 RIdx, ROff, ParaLen : Integer;
 Tail                : String;
Begin
 SplitRunAtChar := True;
 ParaLen := Length(ParaText(P));
 If CharOff <= 0 Then Exit;
 If CharOff >= ParaLen Then Exit;
 LocateChar(P, CharOff, RIdx, ROff);
 If ROff = 0 Then Exit;   { deja sur une frontiere }
 If Doc^.Paragraphs[P].RunCount >= MAX_RUNS_PER_PARA Then Begin
  SplitRunAtChar := False; Exit;
 End;
 Tail := Copy(Doc^.Paragraphs[P].Runs[RIdx].Text, ROff + 1,
              Length(Doc^.Paragraphs[P].Runs[RIdx].Text) - ROff);
 Doc^.Paragraphs[P].Runs[RIdx].Text :=
  Copy(Doc^.Paragraphs[P].Runs[RIdx].Text, 1, ROff);
 If Not InsertRunAt(P, RIdx + 1) Then Begin
  { rollback }
  Doc^.Paragraphs[P].Runs[RIdx].Text :=
   Doc^.Paragraphs[P].Runs[RIdx].Text + Tail;
  SplitRunAtChar := False; Exit;
 End;
 Doc^.Paragraphs[P].Runs[RIdx + 1].Style := Doc^.Paragraphs[P].Runs[RIdx].Style;
 Doc^.Paragraphs[P].Runs[RIdx + 1].Text  := Tail;
End;

{ True si tous les caracteres de [C1..C2) du paragraphe P portent
  le bit StyBit. Retourne True si l'intervalle est vide. }
Function ParaRangeAllHaveStyle(P, C1, C2: Integer; StyBit: Byte): Boolean;
Var
 K, Acc, RL, SegStart, SegEnd : Integer;
Begin
 ParaRangeAllHaveStyle := True;
 If C2 <= C1 Then Exit;
 Acc := 0;
 For K := 1 To Doc^.Paragraphs[P].RunCount Do Begin
  RL := Length(Doc^.Paragraphs[P].Runs[K].Text);
  SegStart := Acc;   If C1 > SegStart Then SegStart := C1;
  SegEnd   := Acc + RL; If C2 < SegEnd Then SegEnd := C2;
  If SegEnd > SegStart Then
   If (Doc^.Paragraphs[P].Runs[K].Style.Style And StyBit) = 0 Then Begin
    ParaRangeAllHaveStyle := False; Exit;
   End;
  Inc(Acc, RL);
 End;
End;

{ Applique (Set=True) ou retire (Set=False) le bit StyBit sur tous les
  runs couvrant [C1..C2) du paragraphe P. Decoupe les runs aux bornes. }
Procedure ParaApplyStyleBit(P, C1, C2: Integer; StyBit: Byte; SetIt: Boolean);
Var
 K, Acc, RL, NewStyle : Integer;
Begin
 If C2 <= C1 Then Exit;
 { Decouper aux deux bornes (l'ordre importe : C2 d'abord pour ne pas
   invalider l'offset de C1 -- en fait c'est l'inverse, decouper C1
   peut decaler les runs apres C1 mais pas les chars; les offsets de
   caracteres sont absolus dans le paragraphe et ne bougent pas). }
 If Not SplitRunAtChar(P, C1) Then Exit;
 If Not SplitRunAtChar(P, C2) Then Exit;
 Acc := 0;
 For K := 1 To Doc^.Paragraphs[P].RunCount Do Begin
  RL := Length(Doc^.Paragraphs[P].Runs[K].Text);
  If (Acc >= C1) And (Acc + RL <= C2) And (RL > 0) Then Begin
   NewStyle := Doc^.Paragraphs[P].Runs[K].Style.Style;
   If SetIt Then NewStyle := NewStyle Or StyBit
   Else NewStyle := NewStyle And (Not StyBit);
   Doc^.Paragraphs[P].Runs[K].Style.Style := Byte(NewStyle);
  End;
  Inc(Acc, RL);
 End;
 MergeAdjacentSameStyleRuns(P);
End;

{ Applique le bit StyBit sur l'ensemble de la selection en cours, en
  basculant : si TOUS les caracteres l'ont deja, on le retire ; sinon
  on l'ajoute partout. Aucun effet si pas de selection active. }
Procedure SelApplyStyleBit(StyBit: Byte);
Var
 P1, C1, P2, C2, P, ParaLen, RangeL, RangeR : Integer;
 AllSet                                     : Boolean;
Begin
 If Not SelHasRange Then Exit;
 SelGetRange(P1, C1, P2, C2);
 AllSet := True;
 For P := P1 To P2 Do Begin
  ParaLen := Length(ParaText(P));
  If P = P1 Then RangeL := C1 Else RangeL := 0;
  If P = P2 Then RangeR := C2 Else RangeR := ParaLen;
  If RangeL < 0 Then RangeL := 0;
  If RangeR > ParaLen Then RangeR := ParaLen;
  If RangeR > RangeL Then
   If Not ParaRangeAllHaveStyle(P, RangeL, RangeR, StyBit) Then Begin
    AllSet := False; Break;
   End;
 End;
 For P := P1 To P2 Do Begin
  ParaLen := Length(ParaText(P));
  If P = P1 Then RangeL := C1 Else RangeL := 0;
  If P = P2 Then RangeR := C2 Else RangeR := ParaLen;
  If RangeL < 0 Then RangeL := 0;
  If RangeR > ParaLen Then RangeR := ParaLen;
  If RangeR > RangeL Then
   ParaApplyStyleBit(P, RangeL, RangeR, StyBit, Not AllSet);
 End;
 Doc^.Modified  := True;
 NeedsRelayout := True;
End;

{ Applique la fonte/agrandissement n?cessaires ? un style donn?.
  Phase 3 : tailles toutes ? mag 1, gras simul? par overstrike. }
{ Native Windows font metrics and antialiased glyphs for positioned PDF text. }


Function PDFPalette(R,G,B:Integer):Byte;
Const Colors:Array[0..15,0..2] of Byte=(
 (0,0,0),(0,0,170),(0,170,0),(0,170,170),(170,0,0),(170,0,170),(170,85,0),(170,
   170,170),
 (85,85,85),(85,85,255),(85,255,85),(85,255,255),(255,85,85),(255,85,255),(255,
   255,85),(255,255,255));
Var I,Best:Integer;D,MinD:LongInt;
Begin
 Best:=0;MinD:=MaxLongInt;
 For I:=0 To 15 Do Begin
  D:=Sqr(LongInt(R)-Colors[I,0])+Sqr(LongInt(G)-Colors[I,
    1])+Sqr(LongInt(B)-Colors[I,2]);
  If D<MinD Then Begin MinD:=D;Best:=I;End;
 End;
 PDFPalette:=Best;
End;

Function PDFTextWidth(Const S,Face:String;H:Integer;Style:Byte):Integer;

Begin
 PDFTextWidth:=Length(S)*H div 2;
 
End;

Procedure DrawPDFTextFragment(P,X,Y,First,Count:Integer);

Begin
 
 SetColor(Doc^.Paragraphs[P].Runs[1].Style.Color);OutTextXY(X,Y,ParaText(P));
 
End;

Procedure DrawPDFText(P,X,Y:Integer);
Begin DrawPDFTextFragment(P,X,Y,1,Length(ParaText(P)));End;

Procedure ZoomText(X,Y:Integer;Const S:String;Style:Byte;Color:Word;
  PreviewHeight:Integer; DocumentHeight:Integer);

Begin
 If (PreviewHeight=0) And (DocumentHeight=0) And (ZoomValue=100) Then Begin
   OutTextXY(X-ZoomPanX,Y,S);Exit;End;
 
 If PreviewHeight>0 Then Begin
  SetTextStyle(DefaultFont,HorizDir,PreviewHeight div 8);
  OutTextXY(X,Y,S);
 End Else Begin
  If DocumentHeight>0 Then
    SetTextStyle(DefaultFont,HorizDir,(DocumentHeight*ZoomValue+400) div 800)
  Else SetTextStyle(DefaultFont,HorizDir,ZoomValue div 100);
  OutTextXY(ZoomX(X),ZoomY(Y),S);
 End;
 SetTextStyle(DefaultFont,HorizDir,1);
 
End;
Procedure ZoomOutTextXY(X,Y:Integer;Const S:String);
Begin ZoomText(X,Y,S,0,GetColor,0,0);End;

Procedure ApplyRunStyle(Const Sty: TCharStyle);
Begin
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetColor(Sty.Color);
End;

{ Dessine S en (X,Y) avec gras (double-frappe +1px) et/ou italique
  (cisaillement : moitie haute decalee de +1 px) selon Sty.Style.
  La police 8x8 par defaut de BGI n'a pas de variante italique :
  on simule via deux SetViewPort qui clippent le haut et le bas du
  glyphe et redessinent avec un decalage horizontal. }
Procedure DrawStyledText(X, Y: Integer; Const S: String;
                         Const Sty: TCharStyle);
Var
 VP : ViewPortType;
 TW : Integer;
Begin
 If (ZoomValue<>100) or (ZoomPanX<>0) or (RunHeight(Sty)<>8) Then Begin
  ZoomText(X,Y,S,Sty.Style,Sty.Color,0,RunHeight(Sty));Exit;
 End;
 If (Sty.Style And STY_ITALIC) <> 0 Then Begin
  TW := TextWidth(S);
  If (Sty.Style And STY_BOLD) <> 0 Then Inc(TW);
  GetViewSettings(VP);
  { Moitie haute (rangees 0..3) decalee de +1 px vers la droite }
  SetViewPort(X, Y, X + TW + 2, Y + 3, ClipOn);
  OutTextXY(1, 0, S);
  If (Sty.Style And STY_BOLD) <> 0 Then OutTextXY(2, 0, S);
  { Moitie basse (rangees 4..7) sans decalage }
  SetViewPort(X, Y + 4, X + TW + 2, Y + 7, ClipOn);
  OutTextXY(0, -4, S);
  If (Sty.Style And STY_BOLD) <> 0 Then OutTextXY(1, -4, S);
  SetViewPort(VP.X1, VP.Y1, VP.X2, VP.Y2, VP.Clip);
 End Else Begin
  OutTextXY(X, Y, S);
  If (Sty.Style And STY_BOLD) <> 0 Then OutTextXY(X + 1, Y, S);
 End;
End;

{ ============================================================ }
{ ===================  PHASE 11 - TABLEAUX  ================== }
{ ============================================================ }

Procedure ResetTablePool;
Var I: Integer;
Begin
 For I := 1 To MAX_TABLES Do Begin
  Tables[I].Used := False;
  Tables[I].Rows := 0;
  Tables[I].Cols := 0;
  FillChar(Tables[I].Cells, SizeOf(Tables[I].Cells), 0);
 End;
End;

Function AllocTable(Rows, Cols: Integer): Integer;
Var I, R, C: Integer;
Begin
 AllocTable := 0;
 If Rows < 1 Then Rows := 1;
 If Rows > MAX_TBL_ROWS Then Rows := MAX_TBL_ROWS;
 If Cols < 1 Then Cols := 1;
 If Cols > MAX_TBL_COLS Then Cols := MAX_TBL_COLS;
 For I := 1 To MAX_TABLES Do
  If Not Tables[I].Used Then Begin
   Tables[I].Used := True;
   Tables[I].Rows := Rows;
   Tables[I].Cols := Cols;
   For R := 1 To MAX_TBL_ROWS Do
    For C := 1 To MAX_TBL_COLS Do
     Tables[I].Cells[R, C] := '';
   AllocTable := I;
   Exit;
  End;
End;

Procedure FreeTable(Idx: Integer);
Begin
 If (Idx < 1) Or (Idx > MAX_TABLES) Then Exit;
 Tables[Idx].Used := False;
 Tables[Idx].Rows := 0;
 Tables[Idx].Cols := 0;
 FillChar(Tables[Idx].Cells, SizeOf(Tables[Idx].Cells), 0);
End;

Function ParaIsTable(P: Integer): Boolean;
Begin
 ParaIsTable := False;
 If (P < 1) Or (P > Doc^.ParaCount) Then Exit;
 If Doc^.Paragraphs[P].TableIdx <= 0 Then Exit;
 If Doc^.Paragraphs[P].TableIdx > MAX_TABLES Then Exit;
 ParaIsTable := Tables[Doc^.Paragraphs[P].TableIdx].Used;
End;

Function ParaTablePtr(P: Integer): Integer;
Begin
 If ParaIsTable(P) Then ParaTablePtr := Doc^.Paragraphs[P].TableIdx
 Else                  ParaTablePtr := 0;
End;

Function CursorInTable: Boolean;
Begin
 CursorInTable := ParaIsTable(Cursor.ParaIdx);
End;

Procedure GetCursorCell(Var Row, Col: Integer);
Var TIdx, Lin, NCols: Integer;
Begin
 Row := 1; Col := 1;
 TIdx := ParaTablePtr(Cursor.ParaIdx);
 If TIdx = 0 Then Exit;
 NCols := Tables[TIdx].Cols;
 Lin := Cursor.RunIdx;
 If Lin < 1 Then Lin := 1;
 Row := ((Lin - 1) Div NCols) + 1;
 Col := ((Lin - 1) Mod NCols) + 1;
 If Row < 1 Then Row := 1;
 If Row > Tables[TIdx].Rows Then Row := Tables[TIdx].Rows;
 If Col < 1 Then Col := 1;
 If Col > NCols Then Col := NCols;
End;

Procedure SetCursorToCell(P, Row, Col, Ofs: Integer);
Var TIdx, NCols, L: Integer;
Begin
 If Not ParaIsTable(P) Then Exit;
 TIdx := Doc^.Paragraphs[P].TableIdx;
 NCols := Tables[TIdx].Cols;
 If Row < 1 Then Row := 1;
 If Row > Tables[TIdx].Rows Then Row := Tables[TIdx].Rows;
 If Col < 1 Then Col := 1;
 If Col > NCols Then Col := NCols;
 L := Length(Tables[TIdx].Cells[Row, Col]);
 If Ofs < 0 Then Ofs := 0;
 If Ofs > L Then Ofs := L;
 Cursor.ParaIdx := P;
 Cursor.RunIdx  := (Row - 1) * NCols + Col;
 Cursor.CharIdx := Ofs;
End;

Function CellTextOf(P, Row, Col: Integer): String;
Var TIdx: Integer;
Begin
 CellTextOf := '';
 TIdx := ParaTablePtr(P);
 If TIdx = 0 Then Exit;
 If (Row < 1) Or (Row > Tables[TIdx].Rows) Then Exit;
 If (Col < 1) Or (Col > Tables[TIdx].Cols) Then Exit;
 CellTextOf := Tables[TIdx].Cells[Row, Col];
End;

Procedure SetCellTextOf(P, Row, Col: Integer; Const S: String);
Var TIdx: Integer; T: String;
Begin
 TIdx := ParaTablePtr(P);
 If TIdx = 0 Then Exit;
 If (Row < 1) Or (Row > Tables[TIdx].Rows) Then Exit;
 If (Col < 1) Or (Col > Tables[TIdx].Cols) Then Exit;
 T := S;
 If Length(T) > MAX_CELL_TEXT_LEN Then T := Copy(T, 1, MAX_CELL_TEXT_LEN);
 Tables[TIdx].Cells[Row, Col] := T;
End;

{ Insertion d'une ligne dans le tableau, avant AtRow (1..Rows+1).
  AtRow=Rows+1 = ajout en fin. Renvoie False si plein. }
Function TableInsertRow(TIdx, AtRow: Integer): Boolean;
Var R, C: Integer;
Begin
 TableInsertRow := False;
 If (TIdx < 1) Or (TIdx > MAX_TABLES) Then Exit;
 If Not Tables[TIdx].Used Then Exit;
 If Tables[TIdx].Rows >= MAX_TBL_ROWS Then Exit;
 If AtRow < 1 Then AtRow := 1;
 If AtRow > Tables[TIdx].Rows + 1 Then AtRow := Tables[TIdx].Rows + 1;
 For R := Tables[TIdx].Rows Downto AtRow Do
  For C := 1 To Tables[TIdx].Cols Do
   Tables[TIdx].Cells[R + 1, C] := Tables[TIdx].Cells[R, C];
 For C := 1 To Tables[TIdx].Cols Do
  Tables[TIdx].Cells[AtRow, C] := '';
 Inc(Tables[TIdx].Rows);
 TableInsertRow := True;
End;

Function TableDeleteRow(TIdx, AtRow: Integer): Boolean;
Var R, C: Integer;
Begin
 TableDeleteRow := False;
 If (TIdx < 1) Or (TIdx > MAX_TABLES) Then Exit;
 If Not Tables[TIdx].Used Then Exit;
 If Tables[TIdx].Rows <= 1 Then Exit;
 If (AtRow < 1) Or (AtRow > Tables[TIdx].Rows) Then Exit;
 For R := AtRow To Tables[TIdx].Rows - 1 Do
  For C := 1 To Tables[TIdx].Cols Do
   Tables[TIdx].Cells[R, C] := Tables[TIdx].Cells[R + 1, C];
 For C := 1 To Tables[TIdx].Cols Do
  Tables[TIdx].Cells[Tables[TIdx].Rows, C] := '';
 Dec(Tables[TIdx].Rows);
 TableDeleteRow := True;
End;

Function TableInsertCol(TIdx, AtCol: Integer): Boolean;
Var R, C: Integer;
Begin
 TableInsertCol := False;
 If (TIdx < 1) Or (TIdx > MAX_TABLES) Then Exit;
 If Not Tables[TIdx].Used Then Exit;
 If Tables[TIdx].Cols >= MAX_TBL_COLS Then Exit;
 If AtCol < 1 Then AtCol := 1;
 If AtCol > Tables[TIdx].Cols + 1 Then AtCol := Tables[TIdx].Cols + 1;
 For R := 1 To Tables[TIdx].Rows Do Begin
  For C := Tables[TIdx].Cols Downto AtCol Do
   Tables[TIdx].Cells[R, C + 1] := Tables[TIdx].Cells[R, C];
  Tables[TIdx].Cells[R, AtCol] := '';
 End;
 Inc(Tables[TIdx].Cols);
 TableInsertCol := True;
End;

Function TableDeleteCol(TIdx, AtCol: Integer): Boolean;
Var R, C: Integer;
Begin
 TableDeleteCol := False;
 If (TIdx < 1) Or (TIdx > MAX_TABLES) Then Exit;
 If Not Tables[TIdx].Used Then Exit;
 If Tables[TIdx].Cols <= 1 Then Exit;
 If (AtCol < 1) Or (AtCol > Tables[TIdx].Cols) Then Exit;
 For R := 1 To Tables[TIdx].Rows Do Begin
  For C := AtCol To Tables[TIdx].Cols - 1 Do
   Tables[TIdx].Cells[R, C] := Tables[TIdx].Cells[R, C + 1];
  Tables[TIdx].Cells[R, Tables[TIdx].Cols] := '';
 End;
 Dec(Tables[TIdx].Cols);
 TableDeleteCol := True;
End;

{ ----- Layout : word-wrap + pagination ------------------------- }

Procedure LayoutDocument;
Var
 P, Pos, LineStart, LineEnd, LastSpace : Integer;
 W, CharW, AvailW                      : Integer;
 ParaStr                               : String;
 Ch                                    : Char;
 PageIdx                               : Integer;
 PageX1, PageContentL, PageContentR    : Integer;
 PageContentBottom                     : Integer;
 CurY                                  : Integer;     { offset Y dans la page }
 LineW, LineX                          : Integer;
 LineYAbs                              : Integer;
 PageTopAbs                            : Integer;
 SettledLineEnd                        : Integer;
 PAlign                                : Byte;
 TblP, TblR, I, NormalY, LineH: Integer;

 Function ComputeLineX(LW: Integer; AL: Byte): Integer;
 Begin
  Case AL Of
   ALIGN_CENTER : ComputeLineX := PageContentL + (AvailW - LW) Div 2;
   ALIGN_RIGHT  : ComputeLineX := PageContentR - LW;
  Else
   ComputeLineX := PageContentL;     { LEFT et JUSTIFY = bord gauche }
  End;
 End;

 Procedure EmitLine(PI, CSt, CLn, LX, LY, LW, LH: Integer; AL: Byte;
   IsImg: Boolean);
 Begin
  If VLineCount >= MAX_VLINES Then Exit;
  Inc(VLineCount);
  VLines[VLineCount].ParaIdx   := PI;
  VLines[VLineCount].CharStart := CSt;
  VLines[VLineCount].CharLen   := CLn;
  VLines[VLineCount].PageIdx   := PageIdx;
  VLines[VLineCount].X         := LX;
  VLines[VLineCount].Y         := LY;
  VLines[VLineCount].Width     := LW;
  VLines[VLineCount].Height    := LH;
  VLines[VLineCount].Alignment := AL;
  VLines[VLineCount].IsImage   := IsImg;
  VLines[VLineCount].IsTable   := False;
  VLines[VLineCount].TblRow    := 0;
 End;

 Procedure EmitTableRow(PI, RowIdx, LY: Integer);
 Begin
  If VLineCount >= MAX_VLINES Then Exit;
  Inc(VLineCount);
  VLines[VLineCount].ParaIdx   := PI;
  VLines[VLineCount].CharStart := 1;
  VLines[VLineCount].CharLen   := 0;
  VLines[VLineCount].PageIdx   := PageIdx;
  VLines[VLineCount].X         := PageContentL;
  VLines[VLineCount].Y         := LY;
  VLines[VLineCount].Width     := AvailW;
  VLines[VLineCount].Height    := TBL_CELL_HEIGHT;
  VLines[VLineCount].Alignment := ALIGN_LEFT;
  VLines[VLineCount].IsImage   := False;
  VLines[VLineCount].IsTable   := True;
  VLines[VLineCount].TblRow    := RowIdx;
 End;

Begin
 VLineCount := 0;
 PageIdx := 1;
 PageX1 := (SCREEN_W - PAGE_W) Div 2;
 PageContentL := PageX1 + PAGE_MARGIN_L;
 PageContentR := PageX1 + PAGE_W - PAGE_MARGIN_R;
 AvailW := PageContentR - PageContentL;
 PageContentBottom := PAGE_H - PAGE_MARGIN_B;
 CurY := PAGE_MARGIN_T;

 SetTextStyle(DefaultFont, HorizDir, 1);

 For P := 1 To Doc^.ParaCount Do Begin
  If Not PageLayoutView and Doc^.Paragraphs[P].PDF.Active Then Begin
   If PageIdx<>Doc^.Paragraphs[P].PDF.Page Then CurY:=PAGE_MARGIN_T;
   PageIdx:=Doc^.Paragraphs[P].PDF.Page;
  End;
  If PageLayoutView and Doc^.Paragraphs[P].PDF.Active Then Begin
   PageIdx:=Doc^.Paragraphs[P].PDF.Page;
   PageTopAbs:=DOCAREA_TOP+8+(PageIdx-1)*(PAGE_H+12);
   EmitLine(P,1,Length(ParaText(P)),PageX1+Doc^.Paragraphs[P].PDF.X,
    PageTopAbs+Doc^.Paragraphs[P].PDF.Y,
    PDFTextWidth(ParaText(P),Doc^.Paragraphs[P].PDF.Face,
      Doc^.Paragraphs[P].PDF.Height,
     Doc^.Paragraphs[P].Runs[1].Style.Style),
    Doc^.Paragraphs[P].PDF.Height,ALIGN_LEFT,False);
   Continue;
  End;
  { Saut de page dur avant ce paragraphe }
  If Doc^.Paragraphs[P].PageBreakBefore And (P > 1) Then Begin
   Inc(PageIdx);
   CurY := PAGE_MARGIN_T;
  End;

  PAlign  := Doc^.Paragraphs[P].Alignment;

  { Paragraphe image : 1 VLine, hauteur = ImgH }
  If Doc^.Paragraphs[P].IsImage Then Begin
   If CurY + Doc^.Paragraphs[P].ImgH > PageContentBottom Then Begin
    Inc(PageIdx);
    CurY := PAGE_MARGIN_T;
   End;
   PageTopAbs := DOCAREA_TOP + 8 + (PageIdx-1)*(PAGE_H + 12);
   LineYAbs := PageTopAbs + CurY;
   LineX := ComputeLineX(Doc^.Paragraphs[P].ImgW, PAlign);
   EmitLine(P, 1, 0, LineX, LineYAbs,
            Doc^.Paragraphs[P].ImgW, Doc^.Paragraphs[P].ImgH,
            PAlign, True);
   Inc(CurY, Doc^.Paragraphs[P].ImgH + 4);
   Continue;
  End;

  { Paragraphe tableau : 1 VLine par ligne du tableau }
  If ParaIsTable(P) Then Begin
   TblP := Doc^.Paragraphs[P].TableIdx;
   For TblR := 1 To Tables[TblP].Rows Do Begin
    If CurY + TBL_CELL_HEIGHT > PageContentBottom Then Begin
     Inc(PageIdx);
     CurY := PAGE_MARGIN_T;
    End;
    PageTopAbs := DOCAREA_TOP + 8 + (PageIdx-1)*(PAGE_H + 12);
    LineYAbs := PageTopAbs + CurY;
    EmitTableRow(P, TblR, LineYAbs);
    Inc(CurY, TBL_CELL_HEIGHT);
   End;
   Inc(CurY, 4);   { petit espace apres le tableau }
   Continue;
  End;

  ParaStr := ParaText(P);
  LineH:=LINE_HEIGHT;
  If Doc^.Paragraphs[P].PDF.Active Then LineH:=Doc^.Paragraphs[P].PDF.Height+4;

  If Length(ParaStr) = 0 Then Begin
   { Paragraphe vide = 1 ligne vide }
   If CurY + LineH > PageContentBottom Then Begin
    Inc(PageIdx);
    CurY := PAGE_MARGIN_T;
   End;
   PageTopAbs := DOCAREA_TOP + 8 + (PageIdx-1)*(PAGE_H + 12);
   LineYAbs := PageTopAbs + CurY;
   EmitLine(P, 1, 0, ComputeLineX(0, PAlign), LineYAbs, 0,
            LineH, PAlign, False);
   Inc(CurY, LineH);
   Continue;
  End;

  LineStart := 1;
  While LineStart <= Length(ParaStr) Do Begin
   { Hang indent : largeur disponible reduite pour lignes 2+, ou des la 1re
     ligne si le paragraphe est marque comme continuation (apres <w:br/>).  }
   If (LineStart > 1) Or Doc^.Paragraphs[P].FirstLineHang Then
    Begin
     LineX := PageContentL + Doc^.Paragraphs[P].LeftIndent;
     AvailW := PageContentR - LineX;
    End
   Else
    Begin
     LineX := PageContentL;
     AvailW := PageContentR - PageContentL;
    End;
   { Greedy fit jusqu'au prochain wrap }
   Pos := LineStart;
   W := 0;
   LastSpace := 0;
   SettledLineEnd := 0;
   While Pos <= Length(ParaStr) Do Begin
    Ch := ParaStr[Pos];
    CharW:=StyledRangeWidth(P,Pos,1);
    If W + CharW > AvailW Then Begin
     If LastSpace >= LineStart Then
      SettledLineEnd := LastSpace
     Else Begin
      SettledLineEnd := Pos - 1;
      If SettledLineEnd < LineStart Then SettledLineEnd := LineStart;
     End;
     Break;
    End;
    Inc(W, CharW);
    If Ch = ' ' Then LastSpace := Pos;
    Inc(Pos);
   End;
   If SettledLineEnd = 0 Then
    LineEnd := Length(ParaStr)
   Else
    LineEnd := SettledLineEnd;

   If Not Doc^.Paragraphs[P].PDF.Active Then Begin
    LineH:=LINE_HEIGHT;
    W:=1;
    For Pos:=1 To Doc^.Paragraphs[P].RunCount Do Begin
     CharW:=Length(Doc^.Paragraphs[P].Runs[Pos].Text);
     If (CharW>0) And (W<=LineEnd) And (W+CharW>LineStart) Then
      If RunHeight(Doc^.Paragraphs[P].Runs[Pos].Style)+4>LineH Then
       LineH:=RunHeight(Doc^.Paragraphs[P].Runs[Pos].Style)+4;
     Inc(W,CharW);
    End;
   End;
   LineW := StyledRangeWidth(P, LineStart, LineEnd - LineStart + 1);
   { Alignement : Center/Right utilisent ComputeLineX dans la fenetre
     restante (X..PageContentR), pas la pleine largeur de page.        }
   Case PAlign Of
    ALIGN_CENTER : LineX := LineX + (AvailW - LineW) Div 2;
    ALIGN_RIGHT  : LineX := PageContentR - LineW;
   End;

   If CurY + LineH > PageContentBottom Then Begin
    Inc(PageIdx);
    CurY := PAGE_MARGIN_T;
   End;
   PageTopAbs := DOCAREA_TOP + 8 + (PageIdx-1)*(PAGE_H + 12);
   LineYAbs := PageTopAbs + CurY;
   EmitLine(P, LineStart, LineEnd - LineStart + 1,
            LineX, LineYAbs, LineW, LineH, PAlign, False);
   Inc(CurY, LineH);
   LineStart := LineEnd + 1;
  End;
 End;

 If Doc^.PDFPageCount>PageIdx Then PageIdx:=Doc^.PDFPageCount;
 If PageIdx > MAX_PAGES Then PageIdx := MAX_PAGES;
 Doc^.PageCount := PageIdx;
 If Not PageLayoutView Then Begin
  NormalY:=DOCAREA_TOP+12;
  For I:=1 To VLineCount Do Begin
   VLines[I].Y:=NormalY;
   Inc(NormalY,VLines[I].Height);
   If I<VLineCount Then If VLines[I].ParaIdx<>VLines[I+1].ParaIdx Then
     Inc(NormalY,4);
  End;
 End;
 NeedsRelayout := False;
End;

{ ----- Recherche ligne du curseur + position ??cran ------------ }

Function FindCursorVLine: Integer;
Var I, R, LastInPara, CurRow, CurCol: Integer;
Begin
 R := 0; LastInPara := 0;
 If CursorInTable Then Begin
  GetCursorCell(CurRow, CurCol);
  For I := 1 To VLineCount Do
   If (VLines[I].ParaIdx = Cursor.ParaIdx) And VLines[I].IsTable And
      (VLines[I].TblRow = CurRow) Then Begin
    FindCursorVLine := I; Exit;
   End;
 End;
 For I := 1 To VLineCount Do
  If VLines[I].ParaIdx = Cursor.ParaIdx Then Begin
   LastInPara := I;
   If R = 0 Then
    If (Cursor.CharIdx >= VLines[I].CharStart - 1) And
       (Cursor.CharIdx <  VLines[I].CharStart + VLines[I].CharLen) Then
     R := I;
  End;
 If R = 0 Then R := LastInPara;
 FindCursorVLine := R;
End;

Function VLineIsLastInPara(L: Integer): Boolean; Forward;

Function CursorScreenX(L: Integer): Integer;
Var
 Off, AvailW, SpaceCnt, Slack             : Integer;
 PerSpace, Remainder, Extra, SpacesSeen   : Integer;
 I, Limit, J, LastNonSpaceAbs, EffW, Idx  : Integer;
 ParaStr, Sub                             : String;
 IsLastInPara                             : Boolean;
 CurRow, CurCol, CellW, NCols, TblP       : Integer;
Begin
 If VLines[L].IsTable Then Begin
  TblP := Doc^.Paragraphs[VLines[L].ParaIdx].TableIdx;
  GetCursorCell(CurRow, CurCol);
  NCols := Tables[TblP].Cols;
  CellW := VLines[L].Width Div NCols;
  Sub := Copy(Tables[TblP].Cells[CurRow, CurCol], 1, Cursor.CharIdx);
  SetTextStyle(DefaultFont, HorizDir, 1);
  CursorScreenX := VLines[L].X + (CurCol - 1) * CellW + TBL_CELL_PAD +
    TextWidth(Sub);
  Exit;
 End;
 Off := Cursor.CharIdx - (VLines[L].CharStart - 1);
 If Off < 0 Then Off := 0;
 If Off > VLines[L].CharLen Then Off := VLines[L].CharLen;
 ParaStr := ParaText(VLines[L].ParaIdx);
 Sub := Copy(ParaStr, VLines[L].CharStart, Off);
 SetTextStyle(DefaultFont, HorizDir, 1);

 Extra := 0;
 If VLines[L].Alignment = ALIGN_JUSTIFY Then Begin
  IsLastInPara := VLineIsLastInPara(L);
  If Not IsLastInPara Then Begin
   AvailW := (SCREEN_W - PAGE_W) Div 2 + PAGE_W - PAGE_MARGIN_R - VLines[L].X;
   { Determine la position 1-based dans le para du dernier non-espace. }
   LastNonSpaceAbs := 0;
   For J := 1 To VLines[L].CharLen Do Begin
    Idx := VLines[L].CharStart + J - 1;
    If (Idx >= 1) And (Idx <= Length(ParaStr)) Then
     If ParaStr[Idx] <> ' ' Then LastNonSpaceAbs := Idx;
   End;
   SpaceCnt := 0;
   If LastNonSpaceAbs > 0 Then
    For I := VLines[L].CharStart To LastNonSpaceAbs - 1 Do
     If (I >= 1) And (I <= Length(ParaStr)) Then
      If ParaStr[I] = ' ' Then Inc(SpaceCnt);
   If LastNonSpaceAbs > 0 Then
    EffW := StyledRangeWidth(VLines[L].ParaIdx, VLines[L].CharStart,
                              LastNonSpaceAbs - VLines[L].CharStart + 1)
   Else
    EffW := 0;
   Slack := AvailW - EffW;
   If (SpaceCnt > 0) And (Slack > 0) Then Begin
    PerSpace  := Slack Div SpaceCnt;
    Remainder := Slack Mod SpaceCnt;
    SpacesSeen := 0;
    Limit := VLines[L].CharStart + Off - 1;
    For I := VLines[L].CharStart To Limit Do
     If (I >= 1) And (I <= Length(ParaStr)) And (I < LastNonSpaceAbs) Then
      If ParaStr[I] = ' ' Then Begin
       Inc(SpacesSeen);
       Inc(Extra, PerSpace);
       If SpacesSeen <= Remainder Then Inc(Extra);
      End;
   End;
  End;
 End;
 CursorScreenX := VLines[L].X + StyledRangeWidth(VLines[L].ParaIdx,
   VLines[L].CharStart, Off) + Extra;
End;

{ Position ecran X de la limite gauche du caractere a l'offset
  AbsCharIdx (0-based dans le paragraphe) sur la ligne visuelle L.
  Identique a CursorScreenX mais parametre par AbsCharIdx. }
Function LineCharScreenX(L, AbsCharIdx: Integer): Integer;
Var
 Off, AvailW, SpaceCnt, Slack             : Integer;
 PerSpace, Remainder, Extra, SpacesSeen   : Integer;
 I, Limit, J, LastNonSpaceAbs, EffW, Idx  : Integer;
 ParaStr, Sub                             : String;
 IsLastInPara                             : Boolean;
Begin
 Off := AbsCharIdx - (VLines[L].CharStart - 1);
 If Off < 0 Then Off := 0;
 If Off > VLines[L].CharLen Then Off := VLines[L].CharLen;
 ParaStr := ParaText(VLines[L].ParaIdx);
 Sub := Copy(ParaStr, VLines[L].CharStart, Off);
 SetTextStyle(DefaultFont, HorizDir, 1);
 Extra := 0;
 If VLines[L].Alignment = ALIGN_JUSTIFY Then Begin
  IsLastInPara := VLineIsLastInPara(L);
  If Not IsLastInPara Then Begin
   AvailW := (SCREEN_W - PAGE_W) Div 2 + PAGE_W - PAGE_MARGIN_R - VLines[L].X;
   LastNonSpaceAbs := 0;
   For J := 1 To VLines[L].CharLen Do Begin
    Idx := VLines[L].CharStart + J - 1;
    If (Idx >= 1) And (Idx <= Length(ParaStr)) Then
     If ParaStr[Idx] <> ' ' Then LastNonSpaceAbs := Idx;
   End;
   SpaceCnt := 0;
   If LastNonSpaceAbs > 0 Then
    For I := VLines[L].CharStart To LastNonSpaceAbs - 1 Do
     If (I >= 1) And (I <= Length(ParaStr)) Then
      If ParaStr[I] = ' ' Then Inc(SpaceCnt);
   If LastNonSpaceAbs > 0 Then
    EffW := StyledRangeWidth(VLines[L].ParaIdx, VLines[L].CharStart,
                              LastNonSpaceAbs - VLines[L].CharStart + 1)
   Else
    EffW := 0;
   Slack := AvailW - EffW;
   If (SpaceCnt > 0) And (Slack > 0) Then Begin
    PerSpace  := Slack Div SpaceCnt;
    Remainder := Slack Mod SpaceCnt;
    SpacesSeen := 0;
    Limit := VLines[L].CharStart + Off - 1;
    For I := VLines[L].CharStart To Limit Do
     If (I >= 1) And (I <= Length(ParaStr)) And (I < LastNonSpaceAbs) Then
      If ParaStr[I] = ' ' Then Begin
       Inc(SpacesSeen);
       Inc(Extra, PerSpace);
       If SpacesSeen <= Remainder Then Inc(Extra);
      End;
   End;
  End;
 End;
 LineCharScreenX := VLines[L].X + StyledRangeWidth(VLines[L].ParaIdx,
   VLines[L].CharStart, Off) + Extra;
End;

{ ----- Helpers selection -------------------------------------- }

Function SelHasRange: Boolean;
Begin
 SelHasRange := Sel.Active And
                ((Sel.AnchorPara <> Cursor.ParaIdx) Or
                 (Sel.AnchorChar <> Cursor.CharIdx));
End;

Procedure SelClear;
Begin
 Sel.Active := False;
End;

Procedure SelStartFromCursor;
Begin
 Sel.Active := True;
 Sel.AnchorPara := Cursor.ParaIdx;
 Sel.AnchorChar := Cursor.CharIdx;
End;

Procedure SelGetRange(Var P1, C1, P2, C2: Integer);
Var Swap: Boolean;
Begin
 P1 := Sel.AnchorPara; C1 := Sel.AnchorChar;
 P2 := Cursor.ParaIdx; C2 := Cursor.CharIdx;
 Swap := False;
 If P1 > P2 Then Swap := True
 Else If (P1 = P2) And (C1 > C2) Then Swap := True;
 If Swap Then Begin
  P1 := Cursor.ParaIdx; C1 := Cursor.CharIdx;
  P2 := Sel.AnchorPara; C2 := Sel.AnchorChar;
 End;
End;

{ ----- Helpers justification (Phase 4) ------------------------- }

Function VLineIsLastInPara(L: Integer): Boolean;
Var PI: Integer;
Begin
 If L >= VLineCount Then Begin
  { Derniere vline globale : on regarde le paragraphe courant. Si elle a
    une continuation artificielle (rare car la suivante aurait des vlines
    aussi), on laisse True. }
  VLineIsLastInPara := True; Exit;
 End;
 If VLines[L+1].ParaIdx = VLines[L].ParaIdx Then Begin
  VLineIsLastInPara := False; Exit;
 End;
 { Sous-paragraphes issus du split ShortString : on traite la frontiere
   comme INTERNE pour conserver la justification jusqu'au bout. }
 PI := VLines[L].ParaIdx;
 If (PI >= 1) And (PI <= Doc^.ParaCount) And
    Doc^.Paragraphs[PI].ContinuesNext Then Begin
  VLineIsLastInPara := False; Exit;
 End;
 If (VLines[L+1].ParaIdx >= 1) And
    (VLines[L+1].ParaIdx <= Doc^.ParaCount) And
    Doc^.Paragraphs[VLines[L+1].ParaIdx].ContinuesPrev Then Begin
  VLineIsLastInPara := False; Exit;
 End;
 VLineIsLastInPara := True;
End;

Function VLineSpaceCount(L: Integer): Integer;
Var I, N: Integer; ParaStr: String;
Begin
 N := 0;
 ParaStr := ParaText(VLines[L].ParaIdx);
 For I := VLines[L].CharStart To VLines[L].CharStart + VLines[L].CharLen - 1 Do
  If (I >= 1) And (I <= Length(ParaStr)) Then
   If ParaStr[I] = ' ' Then Inc(N);
 VLineSpaceCount := N;
End;

{ Statistiques pour la justification : exclut les espaces terminaux
  de la ligne (sinon, le slack se deverse sur l'espace de fin de ligne
  consomme par le wrap, ce qui rend l'expansion invisible).
  - InterSpaceCnt : nombre d'espaces ENTRE mots (non-terminaux).
  - EffWidth      : largeur pixel de la ligne sans les espaces terminaux.
  - LastVisOff    : offset 1-based dans la ligne du dernier caractere
                    non-espace (0 si la ligne ne contient que des espaces).
  Pre-condition : SetTextStyle(DefaultFont, ...) deja actif. }
Procedure VLineJustifyStats(L: Integer;
                            Var InterSpaceCnt, EffWidth,
                                LastVisOff: Integer);
Var
 I, Idx, LastNonSpace, Cnt : Integer;
 ParaStr                   : String;
Begin
 ParaStr := ParaText(VLines[L].ParaIdx);
 LastNonSpace := 0;
 For I := 1 To VLines[L].CharLen Do Begin
  Idx := VLines[L].CharStart + I - 1;
  If (Idx >= 1) And (Idx <= Length(ParaStr)) Then
   If ParaStr[Idx] <> ' ' Then LastNonSpace := I;
 End;
 LastVisOff := LastNonSpace;
 Cnt := 0;
 If LastNonSpace > 1 Then
  For I := 1 To LastNonSpace - 1 Do Begin
   Idx := VLines[L].CharStart + I - 1;
   If (Idx >= 1) And (Idx <= Length(ParaStr)) Then
    If ParaStr[Idx] = ' ' Then Inc(Cnt);
  End;
 InterSpaceCnt := Cnt;
 If LastNonSpace > 0 Then
  EffWidth := StyledRangeWidth(VLines[L].ParaIdx, VLines[L].CharStart,
    LastNonSpace)
 Else
  EffWidth := 0;
End;

{ Retourne True si la ligne L doit ?tre justifi?e ; renseigne Slack et
  SpaceCnt. Slack = pixels ? r?partir entre les espaces inter-mots.
  SpaceCnt exclut les espaces terminaux. }
Function LineNeedsJustify(L: Integer; Var Slack, SpaceCnt: Integer): Boolean;
Var AvailW, EffW, LastVis: Integer;
Begin
 LineNeedsJustify := False;
 Slack := 0; SpaceCnt := 0;
 If VLines[L].Alignment <> ALIGN_JUSTIFY Then Exit;
 If VLineIsLastInPara(L) Then Exit;
 AvailW := (SCREEN_W - PAGE_W) Div 2 + PAGE_W - PAGE_MARGIN_R - VLines[L].X;
 VLineJustifyStats(L, SpaceCnt, EffW, LastVis);
 If SpaceCnt = 0 Then Exit;
 Slack := AvailW - EffW;
 If Slack <= 0 Then Begin Slack := 0; Exit; End;
 LineNeedsJustify := True;
End;

{ Pixels extras ajout?s avant le caract?re ? l'offset OffInLine
  (0..CharLen). Pour usage par CursorScreenX en mode justify.
  Les espaces terminaux ne recoivent PAS d'extra. }
Function CursorJustifyExtra(L, OffInLine, Slack, SpaceCnt: Integer): Integer;
Var
 I, Limit, SpacesSeen, PerSpace, Remainder, Extra : Integer;
 LastVisAbs                                       : Integer;
 EffWDummy, InterDummy, LastVis                   : Integer;
 ParaStr                                          : String;
Begin
 If (Slack <= 0) Or (SpaceCnt <= 0) Then Begin
  CursorJustifyExtra := 0; Exit;
 End;
 PerSpace  := Slack Div SpaceCnt;
 Remainder := Slack Mod SpaceCnt;
 ParaStr := ParaText(VLines[L].ParaIdx);
 VLineJustifyStats(L, InterDummy, EffWDummy, LastVis);
 LastVisAbs := VLines[L].CharStart + LastVis - 1;  { 1-based dans Para }
 SpacesSeen := 0; Extra := 0;
 Limit := VLines[L].CharStart + OffInLine - 1;
 For I := VLines[L].CharStart To Limit Do Begin
  If (I >= 1) And (I <= Length(ParaStr)) And (I < LastVisAbs) Then
   If ParaStr[I] = ' ' Then Begin
    Inc(SpacesSeen);
    Inc(Extra, PerSpace);
    If SpacesSeen <= Remainder Then Inc(Extra);
   End;
 End;
 CursorJustifyExtra := Extra;
End;

{ ----- Rendu texte du document --------------------------------- }

Procedure RenderPDFGraphics;
Var I,ScreenY,LineL,LineR:Integer;
Begin
 For I:=1 To Doc^.PDFGraphicCount Do Begin
  With Doc^.PDFGraphics[I] Do Begin
   ScreenY:=DOCAREA_TOP+8+(Page-1)*(PAGE_H+12)-ScrollY;
   If (ScreenY+Y2>=DOCAREA_TOP) and (ScreenY+Y1<=DocBottom) Then Begin
    LineL:=Y1+ScreenY;LineR:=Y2+ScreenY;
    If LineL<DOCAREA_TOP Then LineL:=DOCAREA_TOP;
    If LineR>DocBottom Then LineR:=DocBottom;
    SetColor(Color);
    If Kind=2 Then Begin SetFillStyle(SolidFill,Color);
     ZoomBar((SCREEN_W-PAGE_W) div 2+X1,LineL,(SCREEN_W-PAGE_W) div 2+X2,LineR);
    End Else If (Y1+ScreenY>=DOCAREA_TOP) and (Y2+ScreenY<=DocBottom) Then
     ZoomLine((SCREEN_W-PAGE_W) div 2+X1,Y1+ScreenY,(SCREEN_W-PAGE_W) div
       2+X2,Y2+ScreenY);
   End;
  End;
 End;
End;

Procedure RenderDocText;
Var
 I, ScreenY, ScreenX  : Integer;
 LineL, LineR         : Integer;
 Acc, K, RunStart, RunEnd : Integer;
 SegStart, SegEnd, SegLen : Integer;
 RunLen, SegW             : Integer;
 P, RC                    : Integer;
 Sub, OneCh               : String;
 Sty                      : TCharStyle;
 Slack, SpaceCnt          : Integer;
 PerSpace, Remainder      : Integer;
 Justify                  : Boolean;
 SegOff, J                : Integer;
 SpacesSeen, ExtraThis    : Integer;
 SegStartX, CharW         : Integer;
 IxImg, IyImg             : Integer;
 IW, IH                   : Integer;
 PB                       : ^Byte;
 LineLastNSAbs, LastVisOff : Integer;
 TblPRen, NColsRen, NRowsRen, RowR, ColC : Integer;
 CellW, CellX, CellY, TextX, TextY        : Integer;
 CellTxt                                  : String;
Begin
 If PageLayoutView Then RenderPDFGraphics;
 SetTextStyle(DefaultFont, HorizDir, 1);
 For I := 1 To VLineCount Do Begin
  ScreenY := VLines[I].Y - ScrollY;
  If (ScreenY + VLines[I].Height < DOCAREA_TOP) Or
     (ScreenY > DocBottom) Then Continue;

  P:=VLines[I].ParaIdx;
  If Doc^.Paragraphs[P].PDF.Active Then Begin
   DrawPDFTextFragment(P,VLines[I].X,ScreenY,VLines[I].CharStart,
     VLines[I].CharLen);Continue;
  End;

  { Image line ? }
  If VLines[I].IsImage Then Begin
   P := VLines[I].ParaIdx;
   IW := Doc^.Paragraphs[P].ImgW;
   IH := Doc^.Paragraphs[P].ImgH;
   If (Doc^.Paragraphs[P].ImgData = Nil) Or (IW <= 0) Or (IH <= 0) Then Continue;
   PB := Doc^.Paragraphs[P].ImgData;
   For IyImg := 0 To IH-1 Do Begin
    If (ScreenY + IyImg < DOCAREA_TOP) Or
       (ScreenY + IyImg > DocBottom) Then Begin
     Inc(PB, IW);
     Continue;
    End;
    For IxImg := 0 To IW-1 Do Begin
     ZoomPixel(VLines[I].X + IxImg, ScreenY + IyImg, PB^ And 15);
     Inc(PB);
    End;
   End;
   Continue;
  End;

  { Table row ? }
  If VLines[I].IsTable Then Begin
   P := VLines[I].ParaIdx;
   TblPRen := Doc^.Paragraphs[P].TableIdx;
   If (TblPRen < 1) Or (TblPRen > MAX_TABLES) Then Continue;
   If Not Tables[TblPRen].Used Then Continue;
   NColsRen := Tables[TblPRen].Cols;
   NRowsRen := Tables[TblPRen].Rows;
   RowR := VLines[I].TblRow;
   If (RowR < 1) Or (RowR > NRowsRen) Then Continue;
   CellW := VLines[I].Width Div NColsRen;
   CellY := ScreenY;
   For ColC := 1 To NColsRen Do Begin
    CellX := VLines[I].X + (ColC-1) * CellW;
    SetColor(Black);
    ZoomLine(CellX, CellY, CellX + CellW, CellY);
    ZoomLine(CellX, CellY, CellX, CellY + TBL_CELL_HEIGHT);
    If ColC = NColsRen Then
     ZoomLine(CellX + CellW, CellY, CellX + CellW, CellY + TBL_CELL_HEIGHT);
    If RowR = NRowsRen Then
     ZoomLine(CellX, CellY + TBL_CELL_HEIGHT, CellX + CellW,
       CellY + TBL_CELL_HEIGHT);
    CellTxt := Tables[TblPRen].Cells[RowR, ColC];
    If Length(CellTxt) > 0 Then Begin
     TextX := CellX + TBL_CELL_PAD;
     TextY := CellY + (TBL_CELL_HEIGHT - 8) Div 2;
     SetTextStyle(DefaultFont, HorizDir, 1);
     SetColor(Black);
     ZoomOutTextXY(TextX, TextY, CellTxt);
    End;
   End;
   Continue;
  End;

  If VLines[I].CharLen = 0 Then Begin
   { Paragraphe vide : dessiner quand meme la bordure inferieure si demandee. }
   If VLineIsLastInPara(I) Then
    If (VLines[I].ParaIdx >= 1) And
       (VLines[I].ParaIdx <= Doc^.ParaCount) Then
     If Doc^.Paragraphs[VLines[I].ParaIdx].BorderBottom Then Begin
      SetColor(DarkGray);
      ZoomLine((SCREEN_W - PAGE_W) Div 2 + PAGE_MARGIN_L,
           ScreenY + VLines[I].Height - 1,
           (SCREEN_W - PAGE_W) Div 2 + PAGE_W - PAGE_MARGIN_R - 1,
           ScreenY + VLines[I].Height - 1);
      SetColor(Black);
     End;
   Continue;
  End;
  If (ScreenY < DOCAREA_TOP) Or
     (ScreenY + VLines[I].Height - 1 > DocBottom) Then Continue;

  P := VLines[I].ParaIdx;
  RC := Doc^.Paragraphs[P].RunCount;
  LineL := VLines[I].CharStart - 1;
  LineR := LineL + VLines[I].CharLen;
  ScreenX := VLines[I].X;
  Acc := 0;

  Justify := LineNeedsJustify(I, Slack, SpaceCnt);
  If Justify Then Begin
   PerSpace  := Slack Div SpaceCnt;
   Remainder := Slack Mod SpaceCnt;
   { Position 1-based dans le paragraphe du dernier non-espace de la ligne :
     les espaces strictement au-dela ne recoivent PAS de pixels extras. }
   VLineJustifyStats(I, J, SegW, LastVisOff);
   LineLastNSAbs := VLines[I].CharStart + LastVisOff - 1;
  End Else Begin
   PerSpace := 0; Remainder := 0;
   LineLastNSAbs := MaxInt;
  End;
  SpacesSeen := 0;

  For K := 1 To RC Do Begin
   RunLen   := Length(Doc^.Paragraphs[P].Runs[K].Text);
   RunStart := Acc;
   RunEnd   := Acc + RunLen;
   Inc(Acc, RunLen);
   SegStart := RunStart; If LineL > SegStart Then SegStart := LineL;
   SegEnd   := RunEnd;   If LineR < SegEnd   Then SegEnd   := LineR;
   If SegStart >= SegEnd Then Continue;
   SegLen := SegEnd - SegStart;
   Sub := Copy(Doc^.Paragraphs[P].Runs[K].Text,
               SegStart - RunStart + 1, SegLen);
   Sty := Doc^.Paragraphs[P].Runs[K].Style;
   ApplyRunStyle(Sty);

   If Not Justify Then Begin
    DrawStyledText(ScreenX, ScreenY, Sub, Sty);
    SegW := SegLen*RunAdvance(Sty);
    If (Sty.Style And STY_UNDERLINE) <> 0 Then Begin
     SetColor(Sty.Color);
     ZoomLine(ScreenX, ScreenY + RunHeight(Sty)+2,
          ScreenX + SegW - 1, ScreenY + RunHeight(Sty)+2);
    End;
    Inc(ScreenX, SegW);
   End Else Begin
    { Justifi? : rendu char par char avec extras sur espaces. }
    SegStartX := ScreenX;
    For SegOff := 1 To SegLen Do Begin
     OneCh := Copy(Sub, SegOff, 1);
     DrawStyledText(ScreenX, ScreenY, OneCh, Sty);
     CharW := RunAdvance(Sty);
     ExtraThis := 0;
     If OneCh[1] = ' ' Then Begin
      { (SegStart + SegOff) = position 1-based dans le para de ce char.
        Espaces terminaux : pas d'extra (sinon poussent rien et le slack
        est gaspille sur l'espace de fin de ligne). }
      If (SegStart + SegOff) < LineLastNSAbs Then Begin
       Inc(SpacesSeen);
       ExtraThis := PerSpace;
       If SpacesSeen <= Remainder Then Inc(ExtraThis);
      End;
     End;
     Inc(ScreenX, CharW + ExtraThis);
    End;
    If (Sty.Style And STY_UNDERLINE) <> 0 Then Begin
     SetColor(Sty.Color);
     ZoomLine(SegStartX, ScreenY + RunHeight(Sty)+2,
          ScreenX - 1, ScreenY + RunHeight(Sty)+2);
    End;
    { Pas d'incr?ment ScreenX r?siduel : d?j? mis ? jour char par char. }
    J := 0;     { dummy: silence "unused J" }
    If J <> 0 Then ;
   End;
  End;
  { Bordure inferieure de paragraphe : trait horizontal sous la
    derniere ligne visuelle du paragraphe. }
  If (Not VLines[I].IsImage) And (Not VLines[I].IsTable) Then
   If VLineIsLastInPara(I) Then
    If (VLines[I].ParaIdx >= 1) And
       (VLines[I].ParaIdx <= Doc^.ParaCount) Then
     If Doc^.Paragraphs[VLines[I].ParaIdx].BorderBottom Then Begin
      SetColor(DarkGray);
      ZoomLine((SCREEN_W - PAGE_W) Div 2 + PAGE_MARGIN_L,
           ScreenY + VLines[I].Height - 1,
           (SCREEN_W - PAGE_W) Div 2 + PAGE_W - PAGE_MARGIN_R - 1,
           ScreenY + VLines[I].Height - 1);
      SetColor(Black);
     End;
 End;
 SetColor(Black);
End;

Procedure RenderTextCursor;
Var L, X, Y: Integer;
Begin
 If VLineCount = 0 Then Exit;
 If Not CursorBlinkOn Then Exit;
 If ActiveMenu > 0 Then Exit;
 L := FindCursorVLine;
 If L = 0 Then Exit;
 X := CursorScreenX(L);
 Y := VLines[L].Y - ScrollY;
 If (Y < DOCAREA_TOP) Or (Y + VLines[L].Height > DocBottom) Then Exit;
 SetColor(Black);
 ZoomLine(X, Y, X, Y + VLines[L].Height - 2);
End;

{ Rendu de la selection : inversion video (XOR avec blanc) sur les
  portions de chaque ligne visuelle couvertes par [P1,C1]..[P2,C2]. }
Procedure RenderSelection;
Var
 P1, C1, P2, C2, I    : Integer;
 LineL, LineR         : Integer;
 SegL, SegR           : Integer;
 X1, X2, Y, YY        : Integer;
Begin
 If Not Sel.Active Then Exit;
 SelGetRange(P1, C1, P2, C2);
 If (P1 = P2) And (C1 = C2) Then Exit;
 SetTextStyle(DefaultFont, HorizDir, 1);
 For I := 1 To VLineCount Do Begin
  If VLines[I].IsImage Then Continue;
  If (VLines[I].ParaIdx < P1) Or (VLines[I].ParaIdx > P2) Then Continue;
  LineL := VLines[I].CharStart - 1;
  LineR := LineL + VLines[I].CharLen;
  If VLines[I].ParaIdx = P1 Then Begin
   SegL := C1; If SegL < LineL Then SegL := LineL;
  End Else SegL := LineL;
  If VLines[I].ParaIdx = P2 Then Begin
   SegR := C2; If SegR > LineR Then SegR := LineR;
  End Else SegR := LineR;
  If SegR <= SegL Then Continue;
  X1 := LineCharScreenX(I, SegL);
  X2 := LineCharScreenX(I, SegR);
  If X2 <= X1 Then Continue;
  Y := VLines[I].Y - ScrollY;
  If (Y + VLines[I].Height - 1 < DOCAREA_TOP) Or (Y > DocBottom) Then Continue;
  SetWriteMode(XORPut);
  SetColor(White);
  For YY := Y To Y + VLines[I].Height - 1 Do
   ZoomLine(X1, YY, X2 - 1, YY);
  SetWriteMode(NormalPut);
 End;
 SetColor(Black);
End;

{ Bascule (XOR) le caret texte sans repeindre tout l'ecran. }
Procedure ToggleTextCursor;
Var L, X, Y: Integer;
Begin
 If VLineCount = 0 Then Exit;
 If ActiveMenu > 0 Then Exit;
 L := FindCursorVLine;
 If L = 0 Then Exit;
 X := CursorScreenX(L);
 Y := VLines[L].Y - ScrollY;
 If (Y < DOCAREA_TOP) Or (Y + VLines[L].Height > DocBottom) Then Exit;
  EraseSoftCursor; 
 SetWriteMode(XORPut);
 SetColor(White);
 ZoomLine(X, Y, X, Y + VLines[L].Height - 2);
 SetWriteMode(NormalPut);
  DrawSoftCursor(MsX, MsY); 
End;

{ ----- Suivi curseur : auto-scroll + page courante ------------- }

Procedure EnsureCursorVisible;
Var L, ScreenY: Integer;
Begin
 If VLineCount = 0 Then Exit;
 L := FindCursorVLine;
 If L = 0 Then Exit;
 CurrentPage := VLines[L].PageIdx;
 ScreenY := VLines[L].Y - ScrollY;
 If ScreenY < DOCAREA_TOP + 4 Then
  ScrollY := VLines[L].Y - DOCAREA_TOP - 4;
 If ScreenY + VLines[L].Height > DocBottom - 4 Then
  ScrollY := VLines[L].Y + VLines[L].Height - DocBottom + 4;
 If ScrollY < 0 Then ScrollY := 0;
 If ZoomPanLimit>0 Then Begin
  If ZoomX(CursorScreenX(L))<12 Then ZoomPanX:=CursorScreenX(L)-SCREEN_W div
    2+30000 div ZoomValue;
  If ZoomX(CursorScreenX(L))>SCREEN_W-12 Then
   ZoomPanX:=CursorScreenX(L)-SCREEN_W div 2-30000 div ZoomValue;
  If ZoomPanX< -ZoomPanLimit Then ZoomPanX:=-ZoomPanLimit;
  If ZoomPanX>ZoomPanLimit Then ZoomPanX:=ZoomPanLimit;
 End;
End;

{ ----- Edition de texte (Phase 3 : multi-run) ----------------- }

Procedure InsertCharAtCursor(Ch: Char);
Var
 P, RIdx, ROff       : Integer;
 Tail                : String;
 ParaLen             : Integer;
 Sty                 : TCharStyle;
 CRow, CCol          : Integer;
 CellTxt             : String;
Begin
 P := Cursor.ParaIdx;
 { Edition dans une cellule de tableau. }
 If CursorInTable Then Begin
  GetCursorCell(CRow, CCol);
  CellTxt := CellTextOf(P, CRow, CCol);
  If Length(CellTxt) >= MAX_CELL_TEXT_LEN Then Exit;
  Insert(Ch, CellTxt, Cursor.CharIdx + 1);
  SetCellTextOf(P, CRow, CCol, CellTxt);
  Inc(Cursor.CharIdx);
  Doc^.Modified  := True;
  NeedsRelayout := True;
  Exit;
 End;
 ParaLen := Length(ParaText(P));
 If ParaLen >= MAX_TEXT_LEN Then Exit;
 Sty := CurrentStyle;

 { Cas paragraphe vide }
 If Doc^.Paragraphs[P].RunCount = 0 Then Begin
  Doc^.Paragraphs[P].RunCount := 1;
  Doc^.Paragraphs[P].Runs[1].Style := Sty;
  Doc^.Paragraphs[P].Runs[1].Text  := Ch;
  Inc(Cursor.CharIdx);
  Doc^.Modified  := True;
  NeedsRelayout := True;
  Exit;
 End;

 LocateInsertion(P, Cursor.CharIdx, RIdx, ROff);

 { Run cible m?me style ? ins?rer dedans. }
 If StyleEq(Doc^.Paragraphs[P].Runs[RIdx].Style, Sty) Then Begin
  Insert(Ch, Doc^.Paragraphs[P].Runs[RIdx].Text, ROff + 1);
 End
 { Bord gauche d'un run, run pr?c?dent m?me style ? append. }
 Else If (ROff = 0) And (RIdx > 1) And
         StyleEq(Doc^.Paragraphs[P].Runs[RIdx-1].Style, Sty) Then Begin
  Doc^.Paragraphs[P].Runs[RIdx-1].Text :=
   Doc^.Paragraphs[P].Runs[RIdx-1].Text + Ch;
 End
 { Bord droit d'un run, run suivant m?me style ? prepend. }
 Else If (ROff = Length(Doc^.Paragraphs[P].Runs[RIdx].Text)) And
         (RIdx < Doc^.Paragraphs[P].RunCount) And
         StyleEq(Doc^.Paragraphs[P].Runs[RIdx+1].Style, Sty) Then Begin
  Insert(Ch, Doc^.Paragraphs[P].Runs[RIdx+1].Text, 1);
 End
 { Insertion ? un bord : nouveau run. }
 Else If ROff = 0 Then Begin
  If Not InsertRunAt(P, RIdx) Then Exit;
  Doc^.Paragraphs[P].Runs[RIdx].Style := Sty;
  Doc^.Paragraphs[P].Runs[RIdx].Text  := Ch;
 End
 Else If ROff = Length(Doc^.Paragraphs[P].Runs[RIdx].Text) Then Begin
  If Not InsertRunAt(P, RIdx + 1) Then Exit;
  Doc^.Paragraphs[P].Runs[RIdx+1].Style := Sty;
  Doc^.Paragraphs[P].Runs[RIdx+1].Text  := Ch;
 End
 { Splittage du run au milieu : tail puis nouveau run. }
 Else Begin
  If Doc^.Paragraphs[P].RunCount + 2 > MAX_RUNS_PER_PARA Then Exit;
  Tail := Copy(Doc^.Paragraphs[P].Runs[RIdx].Text,
               ROff + 1, Length(Doc^.Paragraphs[P].Runs[RIdx].Text) - ROff);
  Doc^.Paragraphs[P].Runs[RIdx].Text :=
   Copy(Doc^.Paragraphs[P].Runs[RIdx].Text, 1, ROff);
  If Not InsertRunAt(P, RIdx + 1) Then Exit;
  Doc^.Paragraphs[P].Runs[RIdx+1].Style := Sty;
  Doc^.Paragraphs[P].Runs[RIdx+1].Text  := Ch;
  If Not InsertRunAt(P, RIdx + 2) Then Exit;
  Doc^.Paragraphs[P].Runs[RIdx+2].Style := Doc^.Paragraphs[P].Runs[RIdx].Style;
  Doc^.Paragraphs[P].Runs[RIdx+2].Text  := Tail;
 End;

 Inc(Cursor.CharIdx);
 Doc^.Modified  := True;
 NeedsRelayout := True;
End;

Procedure BackspaceAtCursor;
Var
 P, RIdx, ROff, I    : Integer;
 LastRun             : Integer;
 ParaLenPrev         : Integer;
 CRow, CCol          : Integer;
 CellTxt             : String;
Begin
 P := Cursor.ParaIdx;
 If CursorInTable Then Begin
  If Cursor.CharIdx > 0 Then Begin
   GetCursorCell(CRow, CCol);
   CellTxt := CellTextOf(P, CRow, CCol);
   Delete(CellTxt, Cursor.CharIdx, 1);
   SetCellTextOf(P, CRow, CCol, CellTxt);
   Dec(Cursor.CharIdx);
   Doc^.Modified  := True;
   NeedsRelayout := True;
  End;
  Exit;
 End;
 If Cursor.CharIdx > 0 Then Begin
  LocateChar(P, Cursor.CharIdx - 1, RIdx, ROff);
  Delete(Doc^.Paragraphs[P].Runs[RIdx].Text, ROff + 1, 1);
  If Length(Doc^.Paragraphs[P].Runs[RIdx].Text) = 0 Then
   RemoveRunAt(P, RIdx);
  MergeAdjacentSameStyleRuns(P);
  Dec(Cursor.CharIdx);
  Doc^.Modified  := True;
  NeedsRelayout := True;
 End Else If Cursor.ParaIdx > 1 Then Begin
  ParaLenPrev := Length(ParaText(Cursor.ParaIdx - 1));
  If ParaLenPrev + Length(ParaText(Cursor.ParaIdx)) > MAX_TEXT_LEN Then Exit;
  { Append runs du paragraphe courant ? la fin du pr?c?dent }
  LastRun := Doc^.Paragraphs[Cursor.ParaIdx - 1].RunCount;
  For I := 1 To Doc^.Paragraphs[Cursor.ParaIdx].RunCount Do Begin
   If LastRun >= MAX_RUNS_PER_PARA Then Break;
   Inc(LastRun);
   Doc^.Paragraphs[Cursor.ParaIdx - 1].Runs[LastRun] :=
    Doc^.Paragraphs[Cursor.ParaIdx].Runs[I];
  End;
  Doc^.Paragraphs[Cursor.ParaIdx - 1].RunCount := LastRun;
  MergeAdjacentSameStyleRuns(Cursor.ParaIdx - 1);
  For I := Cursor.ParaIdx To Doc^.ParaCount - 1 Do
   Doc^.Paragraphs[I] := Doc^.Paragraphs[I + 1];
  FillChar(Doc^.Paragraphs[Doc^.ParaCount], SizeOf(TParagraph), 0);
  Dec(Doc^.ParaCount);
  Dec(Cursor.ParaIdx);
  Cursor.RunIdx  := 1;
  Cursor.CharIdx := ParaLenPrev;
  Doc^.Modified   := True;
  NeedsRelayout  := True;
 End;
End;

Procedure DeleteAtCursor;
Var
 P, RIdx, ROff, I   : Integer;
 ParaLen, LastRun   : Integer;
 CRow, CCol         : Integer;
 CellTxt            : String;
Begin
 P := Cursor.ParaIdx;
 If CursorInTable Then Begin
  GetCursorCell(CRow, CCol);
  CellTxt := CellTextOf(P, CRow, CCol);
  If Cursor.CharIdx < Length(CellTxt) Then Begin
   Delete(CellTxt, Cursor.CharIdx + 1, 1);
   SetCellTextOf(P, CRow, CCol, CellTxt);
   Doc^.Modified  := True;
   NeedsRelayout := True;
  End;
  Exit;
 End;
 ParaLen := Length(ParaText(P));
 If Cursor.CharIdx < ParaLen Then Begin
  LocateChar(P, Cursor.CharIdx, RIdx, ROff);
  Delete(Doc^.Paragraphs[P].Runs[RIdx].Text, ROff + 1, 1);
  If Length(Doc^.Paragraphs[P].Runs[RIdx].Text) = 0 Then
   RemoveRunAt(P, RIdx);
  MergeAdjacentSameStyleRuns(P);
  Doc^.Modified  := True;
  NeedsRelayout := True;
 End Else If Cursor.ParaIdx < Doc^.ParaCount Then Begin
  If ParaLen + Length(ParaText(Cursor.ParaIdx + 1)) > MAX_TEXT_LEN Then Exit;
  LastRun := Doc^.Paragraphs[P].RunCount;
  For I := 1 To Doc^.Paragraphs[Cursor.ParaIdx + 1].RunCount Do Begin
   If LastRun >= MAX_RUNS_PER_PARA Then Break;
   Inc(LastRun);
   Doc^.Paragraphs[P].Runs[LastRun] :=
    Doc^.Paragraphs[Cursor.ParaIdx + 1].Runs[I];
  End;
  Doc^.Paragraphs[P].RunCount := LastRun;
  MergeAdjacentSameStyleRuns(P);
  For I := Cursor.ParaIdx + 1 To Doc^.ParaCount - 1 Do
   Doc^.Paragraphs[I] := Doc^.Paragraphs[I + 1];
  FillChar(Doc^.Paragraphs[Doc^.ParaCount], SizeOf(TParagraph), 0);
  Dec(Doc^.ParaCount);
  Doc^.Modified  := True;
  NeedsRelayout := True;
 End;
End;

Procedure NewParagraphAtCursor;
Var
 P, RIdx, ROff, NewIdx, I, K : Integer;
 Tail                        : String;
 OldRunCount                 : Integer;
 CRow, CCol, NCols, NRows, TIdx : Integer;
Begin
 If CursorInTable Then Begin
  { Enter dans un tableau = passer a la cellule suivante. }
  P := Cursor.ParaIdx;
  TIdx := Doc^.Paragraphs[P].TableIdx;
  GetCursorCell(CRow, CCol);
  NCols := Tables[TIdx].Cols;
  NRows := Tables[TIdx].Rows;
  If CCol < NCols Then
   SetCursorToCell(P, CRow, CCol + 1, 0)
  Else If CRow < NRows Then
   SetCursorToCell(P, CRow + 1, 1, 0)
  Else Begin
   { Sortie : aller au paragraphe suivant. }
   If P < Doc^.ParaCount Then Begin
    Cursor.ParaIdx := P + 1;
    Cursor.RunIdx  := 1;
    Cursor.CharIdx := 0;
   End;
  End;
  Exit;
 End;
 If Doc^.ParaCount >= MAX_PARAS_PER_DOC Then Exit;
 P := Cursor.ParaIdx;
 NewIdx := P + 1;
 For I := Doc^.ParaCount Downto NewIdx Do
  Doc^.Paragraphs[I + 1] := Doc^.Paragraphs[I];
 Inc(Doc^.ParaCount);
 FillChar(Doc^.Paragraphs[NewIdx], SizeOf(TParagraph), 0);
 Doc^.Paragraphs[NewIdx].Alignment := Doc^.Paragraphs[P].Alignment;
 Doc^.Paragraphs[NewIdx].RunCount  := 0;

 { Localise dans le paragraphe courant. }
 LocateInsertion(P, Cursor.CharIdx, RIdx, ROff);
 OldRunCount := Doc^.Paragraphs[P].RunCount;

 { Cas tail = vide (curseur en fin de para) }
 If (RIdx = OldRunCount) And
    (ROff = Length(Doc^.Paragraphs[P].Runs[OldRunCount].Text)) Then Begin
  { Nouveau paragraphe vide avec style courant. }
  Doc^.Paragraphs[NewIdx].RunCount := 1;
  Doc^.Paragraphs[NewIdx].Runs[1].Style := CurrentStyle;
  Doc^.Paragraphs[NewIdx].Runs[1].Text  := '';
 End Else Begin
  { Split run RIdx en head/tail. Head reste dans P, tail va dans NewIdx. }
  Tail := Copy(Doc^.Paragraphs[P].Runs[RIdx].Text,
               ROff + 1, Length(Doc^.Paragraphs[P].Runs[RIdx].Text) - ROff);
  Doc^.Paragraphs[P].Runs[RIdx].Text :=
   Copy(Doc^.Paragraphs[P].Runs[RIdx].Text, 1, ROff);

  K := 0;
  If Length(Tail) > 0 Then Begin
   Inc(K);
   Doc^.Paragraphs[NewIdx].Runs[K].Style := Doc^.Paragraphs[P].Runs[RIdx].Style;
   Doc^.Paragraphs[NewIdx].Runs[K].Text  := Tail;
  End;
  For I := RIdx + 1 To OldRunCount Do Begin
   Inc(K);
   Doc^.Paragraphs[NewIdx].Runs[K] := Doc^.Paragraphs[P].Runs[I];
  End;
  Doc^.Paragraphs[NewIdx].RunCount := K;
  { Tronque P apr?s le run head. Si head vide et qu'il y a d'autres runs,
    enlever ce run vide. }
  Doc^.Paragraphs[P].RunCount := RIdx;
  If (Length(Doc^.Paragraphs[P].Runs[RIdx].Text) = 0) And (RIdx > 1) Then
   RemoveRunAt(P, RIdx);
  If Doc^.Paragraphs[NewIdx].RunCount = 0 Then Begin
   Doc^.Paragraphs[NewIdx].RunCount := 1;
   Doc^.Paragraphs[NewIdx].Runs[1].Style := CurrentStyle;
   Doc^.Paragraphs[NewIdx].Runs[1].Text  := '';
  End;
 End;

 { Nettoyage runs vides flottants dans P. }
 If Doc^.Paragraphs[P].RunCount = 0 Then Begin
  Doc^.Paragraphs[P].RunCount := 1;
  Doc^.Paragraphs[P].Runs[1].Style := CurrentStyle;
  Doc^.Paragraphs[P].Runs[1].Text  := '';
 End;

 Cursor.ParaIdx := NewIdx;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := 0;
 Doc^.Modified   := True;
 NeedsRelayout  := True;
End;

{ ----- Navigation curseur ------------------------------------- }

Procedure CursorMoveLeft;
Var CRow, CCol, P, TIdx: Integer;
Begin
 If CursorInTable Then Begin
  P := Cursor.ParaIdx;
  TIdx := Doc^.Paragraphs[P].TableIdx;
  GetCursorCell(CRow, CCol);
  If Cursor.CharIdx > 0 Then Dec(Cursor.CharIdx)
  Else If CCol > 1 Then
   SetCursorToCell(P, CRow, CCol - 1,
    Length(Tables[TIdx].Cells[CRow, CCol - 1]))
  Else If CRow > 1 Then
   SetCursorToCell(P, CRow - 1, Tables[TIdx].Cols,
    Length(Tables[TIdx].Cells[CRow - 1, Tables[TIdx].Cols]))
  Else If P > 1 Then Begin
   Dec(Cursor.ParaIdx);
   Cursor.RunIdx := 1;
   Cursor.CharIdx := Length(ParaText(Cursor.ParaIdx));
  End;
  Exit;
 End;
 If Cursor.CharIdx > 0 Then Dec(Cursor.CharIdx)
 Else If Cursor.ParaIdx > 1 Then Begin
  Dec(Cursor.ParaIdx);
  Cursor.RunIdx := 1;
  Cursor.CharIdx := Length(ParaText(Cursor.ParaIdx));
 End;
End;

Procedure CursorMoveRight;
Var L, CRow, CCol, P, TIdx, CellLen: Integer;
Begin
 If CursorInTable Then Begin
  P := Cursor.ParaIdx;
  TIdx := Doc^.Paragraphs[P].TableIdx;
  GetCursorCell(CRow, CCol);
  CellLen := Length(Tables[TIdx].Cells[CRow, CCol]);
  If Cursor.CharIdx < CellLen Then Inc(Cursor.CharIdx)
  Else If CCol < Tables[TIdx].Cols Then
   SetCursorToCell(P, CRow, CCol + 1, 0)
  Else If CRow < Tables[TIdx].Rows Then
   SetCursorToCell(P, CRow + 1, 1, 0)
  Else If P < Doc^.ParaCount Then Begin
   Inc(Cursor.ParaIdx);
   Cursor.RunIdx := 1;
   Cursor.CharIdx := 0;
  End;
  Exit;
 End;
 L := Length(ParaText(Cursor.ParaIdx));
 If Cursor.CharIdx < L Then Inc(Cursor.CharIdx)
 Else If Cursor.ParaIdx < Doc^.ParaCount Then Begin
  Inc(Cursor.ParaIdx);
  Cursor.RunIdx := 1;
  Cursor.CharIdx := 0;
 End;
End;

Procedure CursorMoveHome;
Var L: Integer;
Begin
 If CursorInTable Then Begin Cursor.CharIdx := 0; Exit; End;
 L := FindCursorVLine;
 If L > 0 Then
  Cursor.CharIdx := VLines[L].CharStart - 1
 Else
  Cursor.CharIdx := 0;
End;

Procedure CursorMoveEnd;
Var L, CRow, CCol, TIdx: Integer;
Begin
 If CursorInTable Then Begin
  GetCursorCell(CRow, CCol);
  TIdx := Doc^.Paragraphs[Cursor.ParaIdx].TableIdx;
  Cursor.CharIdx := Length(Tables[TIdx].Cells[CRow, CCol]);
  Exit;
 End;
 L := FindCursorVLine;
 If L > 0 Then
  Cursor.CharIdx := VLines[L].CharStart + VLines[L].CharLen - 1
 Else
  Cursor.CharIdx := Length(ParaText(Cursor.ParaIdx));
End;

Procedure CursorVerticalMove(Delta: Integer);
Var
 L, NL, Off, BestOff, BestDist, D : Integer;
 TargetX, TestX                   : Integer;
 ParaStr, Pre                     : String;
 CRow, CCol, TIdx, NewRow         : Integer;
Begin
 If CursorInTable Then Begin
  TIdx := Doc^.Paragraphs[Cursor.ParaIdx].TableIdx;
  GetCursorCell(CRow, CCol);
  NewRow := CRow + Delta;
  If (NewRow >= 1) And (NewRow <= Tables[TIdx].Rows) Then
   SetCursorToCell(Cursor.ParaIdx, NewRow, CCol, 0)
  Else If Delta > 0 Then Begin
   { Sortir vers paragraphe suivant. }
   If Cursor.ParaIdx < Doc^.ParaCount Then Begin
    Inc(Cursor.ParaIdx); Cursor.RunIdx := 1; Cursor.CharIdx := 0;
   End;
  End Else Begin
   If Cursor.ParaIdx > 1 Then Begin
    Dec(Cursor.ParaIdx); Cursor.RunIdx := 1; Cursor.CharIdx := 0;
   End;
  End;
  Exit;
 End;
 L := FindCursorVLine;
 If L = 0 Then Exit;
 NL := L + Delta;
 If (NL < 1) Or (NL > VLineCount) Then Exit;
 SetTextStyle(DefaultFont, HorizDir, 1);
 TargetX := CursorScreenX(L);
 ParaStr := ParaText(VLines[NL].ParaIdx);
 BestOff := 0;
 BestDist := 32767;
 For Off := 0 To VLines[NL].CharLen Do Begin
  Pre := Copy(ParaStr, VLines[NL].CharStart, Off);
  TestX := VLines[NL].X + TextWidth(Pre);
  D := TestX - TargetX;
  If D < 0 Then D := -D;
  If D < BestDist Then Begin
   BestDist := D;
   BestOff := Off;
  End;
 End;
 Cursor.ParaIdx := VLines[NL].ParaIdx;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := VLines[NL].CharStart - 1 + BestOff;
End;

Procedure CursorPageUp;
Var I: Integer;
Begin
 For I := 1 To (DocBottom-DOCAREA_TOP) div LINE_HEIGHT Do
   CursorVerticalMove(-1);
End;

Procedure CursorPageDown;
Var I: Integer;
Begin
 For I := 1 To (DocBottom-DOCAREA_TOP) div LINE_HEIGHT Do CursorVerticalMove(1);
End;

Procedure CursorDocStart;
Begin
 Cursor.ParaIdx := 1;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := 0;
End;

Procedure CursorDocEnd;
Begin
 Cursor.ParaIdx := Doc^.ParaCount;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := Length(ParaText(Cursor.ParaIdx));
End;

{ ============================================================ }
{ ===================  PHASE 6 - IMAGES  ===================== }
{ ============================================================ }

Const VGA_RGB : Array[0..15, 0..2] Of Byte =
 ((  0,  0,  0),(  0,  0,170),(  0,170,  0),(  0,170,170),
  (170,  0,  0),(170,  0,170),(170, 85,  0),(170,170,170),
  ( 85, 85, 85),( 85, 85,255),( 85,255, 85),( 85,255,255),
  (255, 85, 85),(255, 85,255),(255,255, 85),(255,255,255));

Function NearestVGA(R, G, B: Byte): Byte;
Var
 I, BestI    : Integer;
 D, BestD    : LongInt;
 DR, DG, DB  : LongInt;
Begin
 BestI := 0; BestD := MaxLongInt;
 For I := 0 To 15 Do Begin
  DR := LongInt(R) - VGA_RGB[I,0];
  DG := LongInt(G) - VGA_RGB[I,1];
  DB := LongInt(B) - VGA_RGB[I,2];
  D  := DR*DR + DG*DG + DB*DB;
  If D < BestD Then Begin BestD := D; BestI := I; End;
 End;
 NearestVGA := BestI;
End;

Procedure FreeParaImage(Var Pp: TParagraph);
Begin
 If Pp.ImgData <> Nil Then Begin
  FreeMem(Pp.ImgData, Pp.ImgW * Pp.ImgH);
  Pp.ImgData := Nil;
 End;
 Pp.IsImage := False;
 Pp.ImgW := 0; Pp.ImgH := 0;
End;

Procedure FreeAllDocImages;
Var I: Integer;
Begin
 For I := 1 To Doc^.ParaCount Do
  If Doc^.Paragraphs[I].IsImage Then
   FreeParaImage(Doc^.Paragraphs[I]);
End;

{ Nearest-neighbor downscale + copie. Source toujours liber? par appelant. }
Procedure ScaleImageNN(Src: Pointer; SW, SH: Integer;
                       Var Dst: Pointer; Var DW, DH: Integer);
Var
 Sx, Sy : Integer;
 PSrc, PDst, SrcRow : ^Byte;
 X, Y   : Integer;
Begin
 If (SW <= MAX_IMG_W) And (SH <= MAX_IMG_H) Then Begin
  GetMem(Dst, SW*SH);
  Move(Src^, Dst^, SW*SH);
  DW := SW; DH := SH; Exit;
 End;
 If LongInt(SW) * MAX_IMG_H > LongInt(SH) * MAX_IMG_W Then Begin
  DW := MAX_IMG_W;
  DH := (LongInt(SH) * MAX_IMG_W) Div SW;
  If DH < 1 Then DH := 1;
 End Else Begin
  DH := MAX_IMG_H;
  DW := (LongInt(SW) * MAX_IMG_H) Div SH;
  If DW < 1 Then DW := 1;
 End;
 GetMem(Dst, DW*DH);
 PDst := Dst;
 For Y := 0 To DH-1 Do Begin
  Sy := (LongInt(Y) * SH) Div DH;
  SrcRow := Src; Inc(SrcRow, LongInt(Sy) * SW);
  For X := 0 To DW-1 Do Begin
   Sx := (LongInt(X) * SW) Div DW;
   PSrc := SrcRow; Inc(PSrc, Sx);
   PDst^ := PSrc^;
   Inc(PDst);
  End;
 End;
End;

Function LoadBMP(Const FName: String; Var Buf: Pointer;
                 Var W, H: Integer): Boolean;
Var
 F                         : File;
 BFType                    : Array[1..2] Of Char;
 BFSize, BFRsv, BFOffBits  : LongInt;
 BISize, BIWidth, BIHeight : LongInt;
 BIPlanes, BIBitCount      : Word;
 BICompression, BISizeImg  : LongInt;
 BIXP, BIYP, BIClrUsed,
 BIClrImp                  : LongInt;
 PalCnt, PalI              : Integer;
 PalIdx                    : Array[0..255] Of Byte;
 RowBytes                  : LongInt;
 X, Y, IW, IH              : Integer;
 RowBuf                    : Array[0..2047] Of Byte;
 RowDst                    : ^Byte;
 R, G, BC, B0, B1          : Byte;
 PalEntry                  : Array[0..3] Of Byte;
Begin
 Buf := Nil; W := 0; H := 0;
 {$I-} Assign(F, FName); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Begin LoadBMP := False; Exit; End;
 BlockRead(F, BFType, 2);
 If (BFType[1]<>'B') Or (BFType[2]<>'M') Then Begin
  Close(F); LoadBMP := False; Exit;
 End;
 BlockRead(F, BFSize, 4);
 BlockRead(F, BFRsv, 4);
 BlockRead(F, BFOffBits, 4);
 BlockRead(F, BISize, 4);
 If BISize < 40 Then Begin Close(F); LoadBMP := False; Exit; End;
 BlockRead(F, BIWidth, 4);
 BlockRead(F, BIHeight, 4);
 BlockRead(F, BIPlanes, 2);
 BlockRead(F, BIBitCount, 2);
 BlockRead(F, BICompression, 4);
 BlockRead(F, BISizeImg, 4);
 BlockRead(F, BIXP, 4);
 BlockRead(F, BIYP, 4);
 BlockRead(F, BIClrUsed, 4);
 BlockRead(F, BIClrImp, 4);
 If BISize > 40 Then Seek(F, 14 + BISize);
 If BICompression <> 0 Then Begin Close(F); LoadBMP := False; Exit; End;
 If (BIBitCount <> 4) And (BIBitCount <> 8) And (BIBitCount <> 24) Then Begin
  Close(F); LoadBMP := False; Exit;
 End;
 IW := BIWidth; IH := BIHeight;
 If IH < 0 Then IH := -IH;
 If (IW <= 0) Or (IH <= 0) Or (IW > 4096) Or (IH > 4096) Then Begin
  Close(F); LoadBMP := False; Exit;
 End;
 If BIBitCount <= 8 Then Begin
  PalCnt := BIClrUsed;
  If PalCnt = 0 Then PalCnt := 1 Shl BIBitCount;
  If PalCnt > 256 Then PalCnt := 256;
  For PalI := 0 To PalCnt-1 Do Begin
   BlockRead(F, PalEntry, 4);
   PalIdx[PalI] := NearestVGA(PalEntry[2], PalEntry[1], PalEntry[0]);
  End;
 End;
 Seek(F, BFOffBits);
 RowBytes := ((LongInt(IW) * BIBitCount + 31) Shr 3) And $FFFFFFFC;
 If RowBytes > 2048 Then Begin Close(F); LoadBMP := False; Exit; End;
 GetMem(Buf, IW * IH);
 For Y := 0 To IH-1 Do Begin
  BlockRead(F, RowBuf, RowBytes);
  RowDst := Buf;
  If BIHeight < 0 Then Inc(RowDst, LongInt(Y) * IW)
  Else                Inc(RowDst, LongInt(IH - 1 - Y) * IW);
  Case BIBitCount Of
   4: For X := 0 To IW-1 Do Begin
       B0 := RowBuf[X Shr 1];
       If (X And 1) = 0 Then B1 := B0 Shr 4 Else B1 := B0 And $0F;
       RowDst^ := PalIdx[B1]; Inc(RowDst);
      End;
   8: For X := 0 To IW-1 Do Begin
       RowDst^ := PalIdx[RowBuf[X]]; Inc(RowDst);
      End;
   24: For X := 0 To IW-1 Do Begin
        BC := RowBuf[X*3+0]; G := RowBuf[X*3+1]; R := RowBuf[X*3+2];
        RowDst^ := NearestVGA(R, G, BC); Inc(RowDst);
       End;
  End;
 End;
 Close(F);
 W := IW; H := IH;
 LoadBMP := True;
End;

Function LoadPCX(Const FName: String; Var Buf: Pointer;
                 Var W, H: Integer): Boolean;
Var
 F                  : File;
 Hdr                : Array[0..127] Of Byte;
 Encoding, BitsPerPx, NPlanes : Byte;
 BytesPerLine       : Word;
 Xmin,Ymin,Xmax,Ymax: Word;
 IW, IH             : Integer;
 Y, X, P            : Integer;
 ScanLine           : Array[0..4095] Of Byte;
 ScanIdx, TotalScan : Integer;
 RowDst             : ^Byte;
 ReadByte, Run      : Byte;
 Cnt, I             : Integer;
 PalIdx             : Array[0..255] Of Byte;
 BB                 : Byte;
 FSize              : LongInt;
 Pal256             : Array[0..767] Of Byte;
 Mask               : Byte;
Begin
 Buf := Nil; W := 0; H := 0;
 {$I-} Assign(F, FName); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Begin LoadPCX := False; Exit; End;
 BlockRead(F, Hdr, 128);
 If Hdr[0] <> 10 Then Begin Close(F); LoadPCX := False; Exit; End;
 Encoding     := Hdr[2];
 BitsPerPx    := Hdr[3];
 Xmin := Hdr[4]  Or (Word(Hdr[5])  Shl 8);
 Ymin := Hdr[6]  Or (Word(Hdr[7])  Shl 8);
 Xmax := Hdr[8]  Or (Word(Hdr[9])  Shl 8);
 Ymax := Hdr[10] Or (Word(Hdr[11]) Shl 8);
 NPlanes      := Hdr[65];
 BytesPerLine := Hdr[66] Or (Word(Hdr[67]) Shl 8);
 IW := Xmax - Xmin + 1;
 IH := Ymax - Ymin + 1;
 If (Encoding <> 1) Or (IW <= 0) Or (IH <= 0) Or
    (IW > 4096) Or (IH > 4096) Or
    (LongInt(NPlanes) * BytesPerLine > 4096) Then Begin
  Close(F); LoadPCX := False; Exit;
 End;
 If (BitsPerPx = 8) And (NPlanes = 1) Then Begin
  FSize := FileSize(F);
  Seek(F, FSize - 769);
  BlockRead(F, BB, 1);
  If BB = 12 Then Begin
   BlockRead(F, Pal256, 768);
   For I := 0 To 255 Do
    PalIdx[I] := NearestVGA(Pal256[I*3], Pal256[I*3+1], Pal256[I*3+2]);
  End Else
   For I := 0 To 255 Do PalIdx[I] := I And 15;
 End Else Begin
  For I := 0 To 15 Do
   PalIdx[I] := NearestVGA(Hdr[16+I*3], Hdr[16+I*3+1], Hdr[16+I*3+2]);
 End;
 Seek(F, 128);
 GetMem(Buf, IW * IH);
 TotalScan := LongInt(NPlanes) * BytesPerLine;
 For Y := 0 To IH-1 Do Begin
  ScanIdx := 0;
  While ScanIdx < TotalScan Do Begin
   BlockRead(F, ReadByte, 1);
   If (ReadByte And $C0) = $C0 Then Begin
    Cnt := ReadByte And $3F;
    BlockRead(F, Run, 1);
    For I := 1 To Cnt Do Begin
     If ScanIdx < TotalScan Then ScanLine[ScanIdx] := Run;
     Inc(ScanIdx);
    End;
   End Else Begin
    ScanLine[ScanIdx] := ReadByte;
    Inc(ScanIdx);
   End;
  End;
  RowDst := Buf;
  Inc(RowDst, LongInt(Y) * IW);
  Case BitsPerPx Of
   1: If NPlanes = 1 Then Begin
       For X := 0 To IW-1 Do Begin
        Mask := 1 Shl (7 - (X And 7));
        If (ScanLine[X Shr 3] And Mask) <> 0 Then RowDst^ := 15 Else RowDst^ :=
          0;
        Inc(RowDst);
       End;
      End Else Begin
       For X := 0 To IW-1 Do Begin
        Mask := 1 Shl (7 - (X And 7));
        BB := 0;
        For P := 0 To NPlanes-1 Do
         If (ScanLine[P*BytesPerLine + (X Shr 3)] And Mask) <> 0 Then
          BB := BB Or (1 Shl P);
        RowDst^ := PalIdx[BB];
        Inc(RowDst);
       End;
      End;
   4: For X := 0 To IW-1 Do Begin
       BB := ScanLine[X Shr 1];
       If (X And 1) = 0 Then BB := BB Shr 4 Else BB := BB And $0F;
       RowDst^ := PalIdx[BB];
       Inc(RowDst);
      End;
   8: If NPlanes = 1 Then Begin
       For X := 0 To IW-1 Do Begin
        RowDst^ := PalIdx[ScanLine[X]]; Inc(RowDst);
       End;
      End Else Begin
       Close(F); FreeMem(Buf, IW*IH); Buf := Nil; LoadPCX := False; Exit;
      End;
  Else
   Close(F); FreeMem(Buf, IW*IH); Buf := Nil; LoadPCX := False; Exit;
  End;
 End;
 Close(F);
 W := IW; H := IH;
 LoadPCX := True;
End;


{ ============================================================ }
{ ====  PHASE 11: IMAGE LOADERS BGX/XBM/TIFF/GIF/JPEG  ======= }
{ ============================================================ }

{ ----- Helpers communs ----- }

Function ImgPByteAt(P: Pointer; Ofs: LongInt): Byte;
Var Q: ^Byte;
Begin
 Q := P; Inc(Q, Ofs);
 ImgPByteAt := Q^;
End;

Procedure ImgPByteSet(P: Pointer; Ofs: LongInt; B: Byte);
Var Q: ^Byte;
Begin
 Q := P; Inc(Q, Ofs);
 Q^ := B;
End;

Function ImgUpcaseChar(C: Char): Char;
Begin
 If (C>='a') And (C<='z') Then ImgUpcaseChar := Char(Byte(C)-32)
 Else ImgUpcaseChar := C;
End;

Function ImgUpperStr(Const S: String): String;
Var R: String; I: Integer;
Begin
 R := S;
 For I := 1 To Length(R) Do R[I] := ImgUpcaseChar(R[I]);
 ImgUpperStr := R;
End;

{ Palette VGA 256 par defaut (BIOS) reduite a 16 via NearestVGA.
  Pour BGX nous prenons une approximation simple : 0..15 EGA standard,
  16..31 niveaux de gris, 32..255 plage coloree ponderee. }
Function BGXIdxToVGA(Idx: Byte): Byte;
Var R, G, B: Byte; J: Integer;
Begin
 If Idx < 16 Then Begin BGXIdxToVGA := Idx; Exit; End;
 If Idx < 32 Then Begin
  J := (Idx - 16) * 17;     { 0..255 niveaux de gris }
  BGXIdxToVGA := NearestVGA(J, J, J); Exit;
 End;
 { Indices 32..255 : cube 6x6x6 approx }
 J := Idx - 32;             { 0..223 }
 R := Byte((J Div 36) * 51);
 G := Byte(((J Div 6) Mod 6) * 51);
 B := Byte((J Mod 6) * 51);
 BGXIdxToVGA := NearestVGA(R, G, B);
End;

{ ------------------------------------------------------------ }
{ -------- BGX (signature 'BGX1' + W16 + H16 + 8bpp) --------- }
{ ------------------------------------------------------------ }

Function LoadBGX(Const FName: String; Var Buf: Pointer;
                 Var W, H: Integer): Boolean;
Var
 F        : File;
 Sig      : Array[0..3] Of Char;
 W16, H16 : Word;
 Bpp      : Byte;
 N        : LongInt;
 P        : ^Byte;
 I        : LongInt;
 BR       : LongInt;
Begin
 LoadBGX := False; Buf := Nil; W := 0; H := 0;
 {$I-} Assign(F, FName); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 BlockRead(F, Sig, 4, BR);
 If (BR<>4) Or (Sig[0]<>'B') Or (Sig[1]<>'G') Or
    (Sig[2]<>'X') Or (Sig[3]<>'1') Then Begin
  Close(F); Exit;
 End;
 BlockRead(F, W16, 2);
 BlockRead(F, H16, 2);
 BlockRead(F, Bpp, 1);
 If (Bpp<>8) Or (W16=0) Or (H16=0) Or (W16>4096) Or (H16>4096) Then Begin
  Close(F); Exit;
 End;
 N := LongInt(W16) * LongInt(H16);
 GetMem(Buf, N);
 BlockRead(F, Buf^, N, BR);
 Close(F);
 If BR < N Then Begin
  FreeMem(Buf, N); Buf := Nil; Exit;
 End;
 P := Buf;
 For I := 0 To N-1 Do Begin
  P^ := BGXIdxToVGA(P^);
  Inc(P);
 End;
 W := W16; H := H16;
 LoadBGX := True;
End;

{ ------------------------------------------------------------ }
{ ---------- XBM (texte C, monochrome, LSB-first) ------------ }
{ ------------------------------------------------------------ }

Function XBMExtractInt(Const S: String): LongInt;
Var I, J: Integer; V: LongInt;
Begin
 J := Length(S);
 While (J>0) And ((S[J]=' ') Or (S[J]=#9) Or (S[J]=#13)) Do Dec(J);
 I := J;
 While (I>1) And (S[I-1]>='0') And (S[I-1]<='9') Do Dec(I);
 V := 0;
 While (I<=J) And (S[I]>='0') And (S[I]<='9') Do Begin
  V := V*10 + (Byte(S[I]) - Byte('0'));
  Inc(I);
 End;
 XBMExtractInt := V;
End;

{ Lit un nombre 0xXX ou decimal a partir de Pos dans S, avance Pos }
Function XBMNextHexByte(Const S: String; Var P: Integer;
  Var V: LongInt): Boolean;
Var Base: Integer; D: Char; Found: Boolean;
Begin
 XBMNextHexByte := False; V := 0; Base := 10; Found := False;
 While P <= Length(S) Do Begin
  D := S[P];
  If (D='0') And (P<Length(S)) And ((S[P+1]='x') Or (S[P+1]='X')) Then Begin
   Base := 16; Inc(P, 2); Found := True; Break;
  End;
  If (D>='0') And (D<='9') Then Begin
   Found := True; Break;
  End;
  Inc(P);
 End;
 If Not Found Then Exit;
 While P <= Length(S) Do Begin
  D := S[P];
  If (D>='0') And (D<='9') Then V := V*Base + (Byte(D)-Byte('0'))
  Else If (Base=16) And (D>='a') And (D<='f') Then V := V*Base +
    (Byte(D)-Byte('a')+10)
  Else If (Base=16) And (D>='A') And (D<='F') Then V := V*Base +
    (Byte(D)-Byte('A')+10)
  Else Break;
  Inc(P);
 End;
 XBMNextHexByte := True;
End;

Function LoadXBM(Const FName: String; Var Buf: Pointer;
                 Var W, H: Integer): Boolean;
Var
 T          : Text;
 Line, US   : String;
 BW, BH     : Integer;
 RowBytes   : Integer;
 TotalBytes : LongInt;
 BitsBuf    : Pointer;
 K          : LongInt;
 InData     : Boolean;
 Pp         : Integer;
 V          : LongInt;
 X, Y       : Integer;
 ByteIdx    : Integer;
 PD         : ^Byte;
 BV         : Byte;
Begin
 LoadXBM := False; Buf := Nil; W := 0; H := 0;
 BW := 0; BH := 0; InData := False;
 {$I-} Assign(T, FName); Reset(T); {$I+}
 If IOResult <> 0 Then Exit;
 { Pass 1 : recuperer width, height et localiser accolade ouvrante }
 While (Not Eof(T)) And (Not InData) Do Begin
  ReadLn(T, Line);
  US := ImgUpperStr(Line);
  If Pos('_WIDTH', US) > 0 Then BW := XBMExtractInt(Line)
  Else If Pos('_HEIGHT', US) > 0 Then BH := XBMExtractInt(Line);
  If Pos('{', Line) > 0 Then InData := True;
 End;
 If (Not InData) Or (BW<=0) Or (BH<=0) Or (BW>4096) Or (BH>4096) Then Begin
  Close(T); Exit;
 End;
 RowBytes := (BW + 7) Div 8;
 TotalBytes := LongInt(RowBytes) * BH;
 GetMem(BitsBuf, TotalBytes);
 FillChar(BitsBuf^, TotalBytes, 0);
 K := 0;
 { Pass 2 : lire octets 0xXX }
 While (Not Eof(T)) And (K < TotalBytes) Do Begin
  ReadLn(T, Line);
  Pp := 1;
  While (Pp <= Length(Line)) And (K < TotalBytes) Do Begin
   If Not XBMNextHexByte(Line, Pp, V) Then Break;
   ImgPByteSet(BitsBuf, K, Byte(V And $FF));
   Inc(K);
  End;
 End;
 Close(T);
 If K < TotalBytes Then Begin
  FreeMem(BitsBuf, TotalBytes); Exit;
 End;
 GetMem(Buf, LongInt(BW) * BH);
 PD := Buf;
 For Y := 0 To BH-1 Do
  For X := 0 To BW-1 Do Begin
   ByteIdx := X Shr 3;
   BV := ImgPByteAt(BitsBuf, LongInt(Y)*RowBytes + ByteIdx);
   If ((BV Shr (X And 7)) And 1) <> 0 Then PD^ := 0   { foreground noir }
                                       Else PD^ := 15; { fond blanc }
   Inc(PD);
  End;
 FreeMem(BitsBuf, TotalBytes);
 W := BW; H := BH;
 LoadXBM := True;
End;

{ ------------------------------------------------------------ }
{ ---------- TIFF baseline (II/MM, compression=1) ------------ }
{ ------------------------------------------------------------ }

Var
 TifBE : Boolean;        { True = big-endian (MM), False = little-endian (II) }
 TifFh : File;

Function TifRdByte: Byte;
Var B: Byte;
Begin
 BlockRead(TifFh, B, 1); TifRdByte := B;
End;

Function TifRdWord: Word;
Var B0, B1: Byte;
Begin
 BlockRead(TifFh, B0, 1); BlockRead(TifFh, B1, 1);
 If TifBE Then TifRdWord := Word(B0) Shl 8 Or B1
          Else TifRdWord := Word(B1) Shl 8 Or B0;
End;

Function TifRdDWord: LongInt;
Var B: Array[0..3] Of Byte; I: Integer;
Begin
 For I := 0 To 3 Do BlockRead(TifFh, B[I], 1);
 If TifBE Then
  TifRdDWord := (LongInt(B[0]) Shl 24) Or (LongInt(B[1]) Shl 16) Or
                (LongInt(B[2]) Shl 8)  Or  LongInt(B[3])
 Else
  TifRdDWord := (LongInt(B[3]) Shl 24) Or (LongInt(B[2]) Shl 16) Or
                (LongInt(B[1]) Shl 8)  Or  LongInt(B[0]);
End;

Function TifReadValue(FType: Integer; Cnt: LongInt; Ofs: LongInt): LongInt;
Var
 V     : LongInt;
Begin
 V := 0;
 If (FType = 3) And (Cnt = 1) Then
  V := Ofs And $FFFF
 Else If (FType = 4) And (Cnt = 1) Then
  V := Ofs
 Else If (FType = 1) And (Cnt = 1) Then
  V := Ofs And $FF
 Else
  V := Ofs;
 TifReadValue := V;
End;

Function LoadTIFF(Const FName: String; Var Buf: Pointer;
                  Var W, H: Integer): Boolean;
Var
 ByteOrder       : Array[0..1] Of Char;
 Magic           : Word;
 IFDOff          : LongInt;
 EntryCount      : Word;
 IE              : Integer;
 Tag, FType      : Word;
 Cnt, Vof        : LongInt;
 IW, IH          : LongInt;
 BitsPerSample   : Integer;
 SamplesPerPixel : Integer;
 Compression     : Integer;
 Photometric     : Integer;
 StripOffsets    : Array[0..255] Of LongInt;
 StripByteCount  : Array[0..255] Of LongInt;
 NumStrips       : Integer;
 RowsPerStrip    : LongInt;
 ColorMapOfs     : LongInt;
 HasColorMap     : Boolean;
 PlanarConfig    : Integer;
 BPSOfs          : LongInt;
 HasMultiBPS     : Boolean;
 SaveP           : LongInt;
 SrcRow          : Array[0..16383] Of Byte;
 PalR, PalG, PalB: Array[0..255] Of Word;
 PalNumColors    : Integer;
 Y, X            : LongInt;
 Si              : Integer;
 RowsThisStrip   : LongInt;
 RowBytes        : LongInt;
 ToRead          : LongInt;
 Got             : LongInt;
 PD              : ^Byte;
 OutIdx          : LongInt;
 Pix             : Byte;
 Cr, Cg, Cb_     : Byte;
 RowsRemaining   : LongInt;
 Row             : LongInt;
 ColIdx          : LongInt;
Begin
 LoadTIFF := False; Buf := Nil; W := 0; H := 0;
 {$I-} Assign(TifFh, FName); Reset(TifFh, 1); {$I+}
 If IOResult <> 0 Then Exit;
 BlockRead(TifFh, ByteOrder, 2);
 If (ByteOrder[0]='I') And (ByteOrder[1]='I') Then TifBE := False
 Else If (ByteOrder[0]='M') And (ByteOrder[1]='M') Then TifBE := True
 Else Begin Close(TifFh); Exit; End;
 Magic := TifRdWord;
 If Magic <> 42 Then Begin Close(TifFh); Exit; End;
 IFDOff := TifRdDWord;
 Seek(TifFh, IFDOff);
 EntryCount := TifRdWord;
 IW := 0; IH := 0; BitsPerSample := 1; SamplesPerPixel := 1;
 Compression := 1; Photometric := 1; NumStrips := 0;
 RowsPerStrip := 0; ColorMapOfs := 0; HasColorMap := False;
 PlanarConfig := 1; BPSOfs := 0; HasMultiBPS := False;
 For IE := 0 To Integer(EntryCount) - 1 Do Begin
  Tag := TifRdWord;
  FType := TifRdWord;
  Cnt := TifRdDWord;
  Vof := TifRdDWord;
  Case Tag Of
   256: IW := TifReadValue(FType, Cnt, Vof);
   257: IH := TifReadValue(FType, Cnt, Vof);
   258: Begin
    If Cnt = 1 Then BitsPerSample := Integer(Vof And $FFFF)
    Else Begin
     BPSOfs := Vof; HasMultiBPS := True; BitsPerSample := 8;
    End;
   End;
   259: Compression := Integer(Vof And $FFFF);
   262: Photometric := Integer(Vof And $FFFF);
   273: Begin
    NumStrips := Integer(Cnt);
    If NumStrips > 256 Then NumStrips := 256;
    If Cnt = 1 Then StripOffsets[0] := Vof
    Else Begin
     SaveP := FilePos(TifFh);
     Seek(TifFh, Vof);
     If FType = 3 Then
      For Si := 0 To NumStrips - 1 Do StripOffsets[Si] := TifRdWord
     Else
      For Si := 0 To NumStrips - 1 Do StripOffsets[Si] := TifRdDWord;
     Seek(TifFh, SaveP);
    End;
   End;
   277: SamplesPerPixel := Integer(Vof And $FFFF);
   278: RowsPerStrip := Vof;
   279: Begin
    If Cnt = 1 Then StripByteCount[0] := Vof
    Else Begin
     SaveP := FilePos(TifFh);
     Seek(TifFh, Vof);
     If FType = 3 Then
      For Si := 0 To NumStrips - 1 Do StripByteCount[Si] := TifRdWord
     Else
      For Si := 0 To NumStrips - 1 Do StripByteCount[Si] := TifRdDWord;
     Seek(TifFh, SaveP);
    End;
   End;
   284: PlanarConfig := Integer(Vof And $FFFF);
   320: Begin
    ColorMapOfs := Vof; HasColorMap := True;
   End;
  End;
 End;
 If (IW<=0) Or (IH<=0) Or (IW>4096) Or (IH>4096) Then Begin
  Close(TifFh); Exit;
 End;
 If Compression <> 1 Then Begin Close(TifFh); Exit; End;
 If (PlanarConfig <> 1) Then Begin Close(TifFh); Exit; End;
 If RowsPerStrip = 0 Then RowsPerStrip := IH;
 If NumStrips = 0 Then NumStrips := 1;
 { Charge BPS multi si presents }
 If HasMultiBPS Then Begin
  SaveP := FilePos(TifFh);
  Seek(TifFh, BPSOfs);
  BitsPerSample := TifRdWord;
  Seek(TifFh, SaveP);
 End;
 { Charge ColorMap si presente (Photometric=3) }
 If HasColorMap And (Photometric = 3) Then Begin
  PalNumColors := 1 Shl BitsPerSample;
  If PalNumColors > 256 Then PalNumColors := 256;
  SaveP := FilePos(TifFh);
  Seek(TifFh, ColorMapOfs);
  For Si := 0 To PalNumColors - 1 Do PalR[Si] := TifRdWord;
  For Si := 0 To PalNumColors - 1 Do PalG[Si] := TifRdWord;
  For Si := 0 To PalNumColors - 1 Do PalB[Si] := TifRdWord;
  Seek(TifFh, SaveP);
 End Else
  PalNumColors := 0;
 { Allocation buffer destination }
 GetMem(Buf, IW * IH);
 PD := Buf;
 RowsRemaining := IH;
 Row := 0;
 For Si := 0 To NumStrips - 1 Do Begin
  If RowsRemaining <= 0 Then Break;
  RowsThisStrip := RowsPerStrip;
  If RowsThisStrip > RowsRemaining Then RowsThisStrip := RowsRemaining;
  RowBytes := (LongInt(IW) * BitsPerSample * SamplesPerPixel + 7) Div 8;
  If RowBytes > 16384 Then Begin
   FreeMem(Buf, IW*IH); Buf := Nil; Close(TifFh); Exit;
  End;
  Seek(TifFh, StripOffsets[Si]);
  ToRead := RowsThisStrip * RowBytes;
  Got := 0;
  For Y := 0 To RowsThisStrip - 1 Do Begin
   BlockRead(TifFh, SrcRow, RowBytes);
   Inc(Got, RowBytes);
   OutIdx := LongInt(Row + Y) * IW;
   Case Photometric Of
    0: Begin { WhiteIsZero (gray) }
     For X := 0 To IW - 1 Do Begin
      Case BitsPerSample Of
       1: Begin
        Pix := SrcRow[X Shr 3];
        If ((Pix Shr (7 - (X And 7))) And 1) <> 0 Then Pix := 0 Else Pix := 255;
       End;
       4: Begin
        Pix := SrcRow[X Shr 1];
        If (X And 1) = 0 Then Pix := (Pix Shr 4) And $0F Else Pix := Pix And
          $0F;
        Pix := Byte(255 - Pix * 17);
       End;
       8: Pix := Byte(255 - SrcRow[X]);
      Else Pix := 0;
      End;
      ImgPByteSet(Buf, OutIdx + X, NearestVGA(Pix, Pix, Pix));
     End;
    End;
    1: Begin { BlackIsZero (gray) }
     For X := 0 To IW - 1 Do Begin
      Case BitsPerSample Of
       1: Begin
        Pix := SrcRow[X Shr 3];
        If ((Pix Shr (7 - (X And 7))) And 1) <> 0 Then Pix := 255 Else Pix := 0;
       End;
       4: Begin
        Pix := SrcRow[X Shr 1];
        If (X And 1) = 0 Then Pix := (Pix Shr 4) And $0F Else Pix := Pix And
          $0F;
        Pix := Byte(Pix * 17);
       End;
       8: Pix := SrcRow[X];
      Else Pix := 0;
      End;
      ImgPByteSet(Buf, OutIdx + X, NearestVGA(Pix, Pix, Pix));
     End;
    End;
    2: Begin { RGB }
     If (BitsPerSample = 8) And (SamplesPerPixel >= 3) Then
      For X := 0 To IW - 1 Do Begin
       ColIdx := LongInt(X) * SamplesPerPixel;
       Cr := SrcRow[ColIdx];
       Cg := SrcRow[ColIdx + 1];
       Cb_ := SrcRow[ColIdx + 2];
       ImgPByteSet(Buf, OutIdx + X, NearestVGA(Cr, Cg, Cb_));
      End;
    End;
    3: Begin { Palette }
     For X := 0 To IW - 1 Do Begin
      Case BitsPerSample Of
       4: Begin
        Pix := SrcRow[X Shr 1];
        If (X And 1) = 0 Then Pix := (Pix Shr 4) And $0F Else Pix := Pix And
          $0F;
       End;
       8: Pix := SrcRow[X];
      Else Pix := 0;
      End;
      ImgPByteSet(Buf, OutIdx + X,
       NearestVGA(Byte(PalR[Pix] Shr 8), Byte(PalG[Pix] Shr 8),
         Byte(PalB[Pix] Shr 8)));
     End;
    End;
   End;
  End;
  Inc(Row, RowsThisStrip);
  Dec(RowsRemaining, RowsThisStrip);
 End;
 Close(TifFh);
 W := IW; H := IH;
 LoadTIFF := True;
End;

{ ------------------------------------------------------------ }
{ ---------- GIF 87a/89a (LZW, image unique) ----------------- }
{ ------------------------------------------------------------ }

Const
 GIF_MAX_DICT = 4096;

Var
 GifFh         : File;
 GifBlkBuf     : Array[0..255] Of Byte;
 GifBlkLen     : Integer;
 GifBlkIdx     : Integer;
 GifBitBuf     : LongInt;
 GifBitCnt     : Integer;
 GifEof        : Boolean;

Function GifReadByte(Var B: Byte): Boolean;
Var BR: LongInt;
Begin
 BlockRead(GifFh, B, 1, BR);
 GifReadByte := BR = 1;
End;

{ Lit le prochain octet du flux de blocs LZW (sub-blocks) }
Function GifNextLzwByte(Var B: Byte): Boolean;
Var Sz: Byte;
Begin
 GifNextLzwByte := False;
 If GifBlkIdx >= GifBlkLen Then Begin
  If Not GifReadByte(Sz) Then Exit;
  If Sz = 0 Then Begin GifEof := True; Exit; End;
  BlockRead(GifFh, GifBlkBuf, Sz);
  GifBlkLen := Sz;
  GifBlkIdx := 0;
 End;
 B := GifBlkBuf[GifBlkIdx];
 Inc(GifBlkIdx);
 GifNextLzwByte := True;
End;

Function GifReadCode(NBits: Integer; Var Code: Word): Boolean;
Var B: Byte;
Begin
 GifReadCode := False;
 While GifBitCnt < NBits Do Begin
  If Not GifNextLzwByte(B) Then Exit;
  GifBitBuf := GifBitBuf Or (LongInt(B) Shl GifBitCnt);
  Inc(GifBitCnt, 8);
 End;
 Code := Word(GifBitBuf And ((LongInt(1) Shl NBits) - 1));
 GifBitBuf := GifBitBuf Shr NBits;
 Dec(GifBitCnt, NBits);
 GifReadCode := True;
End;

Procedure GifSkipSubBlocks;
Var Sz: Byte; Skip: Array[0..255] Of Byte;
Begin
 Repeat
  If Not GifReadByte(Sz) Then Exit;
  If Sz = 0 Then Exit;
  BlockRead(GifFh, Skip, Sz);
 Until False;
End;

Function LoadGIF(Const FName: String; Var Buf: Pointer;
                 Var W, H: Integer): Boolean;
Var
 Sig          : Array[0..5] Of Char;
 LSW, LSH     : Word;
 Packed_      : Byte;
 BgIdx, AsR   : Byte;
 GctSize      : Integer;
 GctPresent   : Boolean;
 GctR, GctG, GctB : Array[0..255] Of Byte;
 RawByte      : Byte;
 LzwMinCode   : Byte;
 NPalIdx      : Array[0..255] Of Byte;   { palette -> VGA }
 PalI         : Integer;
 ImL, ImT, ImW, ImH: Word;
 ImPacked     : Byte;
 LctR, LctG, LctB : Array[0..255] Of Byte;
 LctPresent   : Boolean;
 LctSize      : Integer;
 Interlaced   : Boolean;
 ClearCode    : Word;
 EOICode      : Word;
 CodeSize     : Integer;
 NextCode     : Word;
 DictPrefix   : Array[0..GIF_MAX_DICT-1] Of Word;
 DictSuffix   : Array[0..GIF_MAX_DICT-1] Of Byte;
 PrevCode     : Word;
 Code         : Word;
 FirstByte    : Byte;
 OutStack     : Array[0..GIF_MAX_DICT-1] Of Byte;
 SP           : Integer;
 K            : Word;
 OutBuf       : Pointer;
 OutBufLn     : LongInt;
 OutPx        : LongInt;
 Done         : Boolean;
 IPass, ILine : Integer;
 InterStart   : Array[0..3] Of Integer;
 InterStep    : Array[0..3] Of Integer;
 PixelRow     : LongInt;
 PixelCol     : LongInt;
 LineW        : LongInt;
 Tmp          : Word;
 PD           : ^Byte;
Begin
 LoadGIF := False; Buf := Nil; W := 0; H := 0;
 {$I-} Assign(GifFh, FName); Reset(GifFh, 1); {$I+}
 If IOResult <> 0 Then Exit;
 BlockRead(GifFh, Sig, 6);
 If (Sig[0]<>'G') Or (Sig[1]<>'I') Or (Sig[2]<>'F') Then Begin
  Close(GifFh); Exit;
 End;
 BlockRead(GifFh, LSW, 2);
 BlockRead(GifFh, LSH, 2);
 BlockRead(GifFh, Packed_, 1);
 BlockRead(GifFh, BgIdx, 1);
 BlockRead(GifFh, AsR, 1);
 GctPresent := (Packed_ And $80) <> 0;
 GctSize := 1 Shl ((Packed_ And 7) + 1);
 If GctPresent Then
  For PalI := 0 To GctSize - 1 Do Begin
   BlockRead(GifFh, GctR[PalI], 1);
   BlockRead(GifFh, GctG[PalI], 1);
   BlockRead(GifFh, GctB[PalI], 1);
  End;
 { Boucle blocs jusqu'a premier image descriptor }
 Done := False;
 ImW := 0; ImH := 0; ImL := 0; ImT := 0; ImPacked := 0;
 LctPresent := False; LctSize := 0; Interlaced := False;
 While Not Done Do Begin
  If Not GifReadByte(RawByte) Then Begin Close(GifFh); Exit; End;
  Case RawByte Of
   $21: Begin   { Extension }
    If Not GifReadByte(RawByte) Then Begin Close(GifFh); Exit; End;
    GifSkipSubBlocks;
   End;
   $2C: Begin   { Image descriptor }
    BlockRead(GifFh, ImL, 2);
    BlockRead(GifFh, ImT, 2);
    BlockRead(GifFh, ImW, 2);
    BlockRead(GifFh, ImH, 2);
    BlockRead(GifFh, ImPacked, 1);
    LctPresent := (ImPacked And $80) <> 0;
    Interlaced := (ImPacked And $40) <> 0;
    LctSize := 1 Shl ((ImPacked And 7) + 1);
    If LctPresent Then
     For PalI := 0 To LctSize - 1 Do Begin
      BlockRead(GifFh, LctR[PalI], 1);
      BlockRead(GifFh, LctG[PalI], 1);
      BlockRead(GifFh, LctB[PalI], 1);
     End;
    Done := True;
   End;
   $3B: Begin Close(GifFh); Exit; End;   { trailer sans image }
  Else
   Close(GifFh); Exit;
  End;
 End;
 If (ImW = 0) Or (ImH = 0) Or (ImW > 4096) Or (ImH > 4096) Then Begin
  Close(GifFh); Exit;
 End;
 { Construire mapping palette -> VGA }
 If LctPresent Then
  For PalI := 0 To LctSize - 1 Do
   NPalIdx[PalI] := NearestVGA(LctR[PalI], LctG[PalI], LctB[PalI])
 Else If GctPresent Then
  For PalI := 0 To GctSize - 1 Do
   NPalIdx[PalI] := NearestVGA(GctR[PalI], GctG[PalI], GctB[PalI])
 Else Begin Close(GifFh); Exit; End;
 { Init LZW }
 BlockRead(GifFh, LzwMinCode, 1);
 If (LzwMinCode < 2) Or (LzwMinCode > 8) Then Begin Close(GifFh); Exit; End;
 ClearCode := Word(1) Shl LzwMinCode;
 EOICode := ClearCode + 1;
 GifBlkLen := 0; GifBlkIdx := 0; GifEof := False;
 GifBitBuf := 0; GifBitCnt := 0;
 OutBufLn := LongInt(ImW) * ImH;
 GetMem(OutBuf, OutBufLn);
 OutPx := 0;
 { Interlacing }
 InterStart[0] := 0; InterStep[0] := 8;
 InterStart[1] := 4; InterStep[1] := 8;
 InterStart[2] := 2; InterStep[2] := 4;
 InterStart[3] := 1; InterStep[3] := 2;
 IPass := 0; ILine := InterStart[0];
 LineW := ImW;
 { Init dict }
 CodeSize := LzwMinCode + 1;
 NextCode := EOICode + 1;
 For K := 0 To ClearCode - 1 Do Begin
  DictPrefix[K] := 0;
  DictSuffix[K] := Byte(K);
 End;
 PrevCode := 0; FirstByte := 0;
 Done := False;
 PixelRow := 0; PixelCol := 0;
 While Not Done Do Begin
  If Not GifReadCode(CodeSize, Code) Then Begin Done := True; Break; End;
  If Code = ClearCode Then Begin
   CodeSize := LzwMinCode + 1;
   NextCode := EOICode + 1;
   If Not GifReadCode(CodeSize, Code) Then Begin Done := True; Break; End;
   If Code = EOICode Then Begin Done := True; Break; End;
   FirstByte := DictSuffix[Code];
   { Emit }
   If Interlaced Then Begin
    If (ILine < ImH) And (PixelCol < LineW) Then Begin
     ImgPByteSet(OutBuf, LongInt(ILine)*ImW + PixelCol, NPalIdx[FirstByte]);
     Inc(PixelCol);
     If PixelCol >= LineW Then Begin
      PixelCol := 0; Inc(ILine, InterStep[IPass]);
      While (ILine >= ImH) And (IPass < 3) Do Begin
       Inc(IPass); ILine := InterStart[IPass];
      End;
     End;
    End;
   End Else Begin
    If OutPx < OutBufLn Then ImgPByteSet(OutBuf, OutPx, NPalIdx[FirstByte]);
    Inc(OutPx);
   End;
   PrevCode := Code;
   Continue;
  End;
  If Code = EOICode Then Begin Done := True; Break; End;
  SP := 0;
  K := Code;
  If K >= NextCode Then Begin
   { KwKwK case }
   OutStack[SP] := FirstByte; Inc(SP);
   K := PrevCode;
  End;
  While K >= ClearCode Do Begin
   If SP >= GIF_MAX_DICT Then Begin Done := True; Break; End;
   OutStack[SP] := DictSuffix[K]; Inc(SP);
   K := DictPrefix[K];
  End;
  FirstByte := DictSuffix[K];
  OutStack[SP] := FirstByte; Inc(SP);
  { Emit stack in reverse }
  While SP > 0 Do Begin
   Dec(SP);
   If Interlaced Then Begin
    If (ILine < ImH) And (PixelCol < LineW) Then Begin
     ImgPByteSet(OutBuf, LongInt(ILine)*ImW + PixelCol, NPalIdx[OutStack[SP]]);
     Inc(PixelCol);
     If PixelCol >= LineW Then Begin
      PixelCol := 0; Inc(ILine, InterStep[IPass]);
      While (ILine >= ImH) And (IPass < 3) Do Begin
       Inc(IPass); ILine := InterStart[IPass];
      End;
     End;
    End;
   End Else Begin
    If OutPx < OutBufLn Then ImgPByteSet(OutBuf, OutPx, NPalIdx[OutStack[SP]]);
    Inc(OutPx);
   End;
  End;
  { Add to dict }
  If (NextCode < GIF_MAX_DICT) Then Begin
   DictPrefix[NextCode] := PrevCode;
   DictSuffix[NextCode] := FirstByte;
   Inc(NextCode);
   If (NextCode = (Word(1) Shl CodeSize)) And (CodeSize < 12) Then
    Inc(CodeSize);
  End;
  PrevCode := Code;
 End;
 { Consommer sub-blocks restants }
 If Not GifEof Then GifSkipSubBlocks;
 Close(GifFh);
 Buf := OutBuf; W := ImW; H := ImH;
 LoadGIF := True;
End;

{ ------------------------------------------------------------ }
{ -------- JPEG baseline DCT (Huffman + IDCT + YCbCr) -------- }
{ ------------------------------------------------------------ }

Const
 JPG_DCT_SIZE = 8;

Type
 TJpgQT     = Array[0..63] Of Integer;
 TJpgHuff   = Record
  Bits   : Array[0..16] Of Byte;       { count per length, [0] unused }
  HuffV  : Array[0..255] Of Byte;
  MinCode: Array[1..16] Of LongInt;
  MaxCode: Array[1..16] Of LongInt;
  ValPtr : Array[1..16] Of Integer;
  NumVals: Integer;
 End;
 TJpgComp   = Record
  Id     : Byte;
  HSamp  : Byte;
  VSamp  : Byte;
  QTId   : Byte;
  DCT    : Byte;
  ACT    : Byte;
  PrevDC : Integer;
 End;
 TJpgBlock  = Array[0..63] Of Integer;

Var
 JpgFh        : File;
 JpgBuf       : Array[0..4095] Of Byte;
 JpgBufLen    : Integer;
 JpgBufIdx    : Integer;
 JpgEofFlag   : Boolean;
 JpgBitBuf    : LongInt;
 JpgBitCnt    : Integer;
 JpgQT        : Array[0..3] Of TJpgQT;
 JpgDCHuff    : Array[0..3] Of TJpgHuff;
 JpgACHuff    : Array[0..3] Of TJpgHuff;
 JpgComp      : Array[0..2] Of TJpgComp;
 JpgNComp     : Integer;
 JpgWidth     : Integer;
 JpgHeight    : Integer;
 JpgHmax      : Integer;
 JpgVmax      : Integer;
 JpgMCUW      : Integer;
 JpgMCUH      : Integer;
 JpgRSTI      : Integer;
 JpgRSTCount  : Integer;
 JpgZigzag    : Array[0..63] Of Byte;
 JpgCosTab    : Array[0..7, 0..7] Of Real;
 JpgIDCTInit  : Boolean;

Function JpgFillBuf: Boolean;
Var BR: LongInt;
Begin
 BlockRead(JpgFh, JpgBuf, 4096, BR);
 JpgBufLen := Integer(BR);
 JpgBufIdx := 0;
 JpgFillBuf := BR > 0;
 If BR = 0 Then JpgEofFlag := True;
End;

Function JpgGetRawByte(Var B: Byte): Boolean;
Begin
 If JpgBufIdx >= JpgBufLen Then
  If Not JpgFillBuf Then Begin JpgGetRawByte := False; Exit; End;
 B := JpgBuf[JpgBufIdx]; Inc(JpgBufIdx);
 JpgGetRawByte := True;
End;

{ Lit un octet du flux entropie : FF00 -> FF, FFxx (xx<>0) = marker }
Function JpgGetEntropyByte(Var B: Byte; Var Marker: Byte): Boolean;
Var B2: Byte;
Begin
 JpgGetEntropyByte := False; Marker := 0;
 If Not JpgGetRawByte(B) Then Exit;
 If B = $FF Then Begin
  If Not JpgGetRawByte(B2) Then Exit;
  If B2 = 0 Then Begin
   B := $FF;
  End Else Begin
   Marker := B2;
   JpgGetEntropyByte := False; Exit;
  End;
 End;
 JpgGetEntropyByte := True;
End;

{ Charge NBits dans le bitbuf (depuis MSB) }
Function JpgFillBits(NBits: Integer): Boolean;
Var B, Mk: Byte;
Begin
 JpgFillBits := True;
 While JpgBitCnt < NBits Do Begin
  If Not JpgGetEntropyByte(B, Mk) Then Begin
   { Marker rencontre ou fin : bourre des zeros }
   JpgBitBuf := JpgBitBuf Shl 8;
   Inc(JpgBitCnt, 8);
   { Si c'est un marker non-restart, on s'arrete }
   If (Mk <> 0) And ((Mk < $D0) Or (Mk > $D7)) Then Begin
    { remettre le marker en buffer en stockant un sentinelle }
    JpgFillBits := False;
   End;
   Continue;
  End;
  JpgBitBuf := (JpgBitBuf Shl 8) Or B;
  Inc(JpgBitCnt, 8);
 End;
End;

Function JpgReadBits(NBits: Integer): LongInt;
Var V: LongInt;
Begin
 If NBits = 0 Then Begin JpgReadBits := 0; Exit; End;
 JpgFillBits(NBits);
 V := (JpgBitBuf Shr (JpgBitCnt - NBits)) And ((LongInt(1) Shl NBits) - 1);
 Dec(JpgBitCnt, NBits);
 JpgReadBits := V;
End;

Function JpgPeekBits(NBits: Integer): LongInt;
Begin
 JpgFillBits(NBits);
 JpgPeekBits := (JpgBitBuf Shr (JpgBitCnt - NBits)) And ((LongInt(1) Shl NBits)
   - 1);
End;

Procedure JpgDropBits(NBits: Integer);
Begin
 Dec(JpgBitCnt, NBits);
End;

{ Decode un code Huffman via mincode/maxcode/valptr }
Function JpgDecodeSymbol(Var T: TJpgHuff): Integer;
Var
 Code : LongInt;
 L    : Integer;
Begin
 Code := JpgReadBits(1);
 L := 1;
 While (L <= 16) And (Code > T.MaxCode[L]) Do Begin
  Code := (Code Shl 1) Or JpgReadBits(1);
  Inc(L);
 End;
 If L > 16 Then Begin JpgDecodeSymbol := 0; Exit; End;
 JpgDecodeSymbol := T.HuffV[T.ValPtr[L] + Integer(Code - T.MinCode[L])];
End;

{ Etend la valeur lue selon JPEG (signe via bit haut) }
Function JpgExtend(V: LongInt; T: Integer): Integer;
Begin
 If T = 0 Then Begin JpgExtend := 0; Exit; End;
 If V < (LongInt(1) Shl (T - 1)) Then
  JpgExtend := Integer(V - ((LongInt(1) Shl T) - 1))
 Else
  JpgExtend := Integer(V);
End;

Procedure JpgBuildHuffTables(Var T: TJpgHuff);
Var
 HuffCode : Array[0..255] Of LongInt;
 HuffSize : Array[0..255] Of Integer;
 I, J, K  : Integer;
 Code     : LongInt;
 SI       : Integer;
Begin
 { Construire huffsize }
 K := 0;
 For I := 1 To 16 Do
  For J := 1 To T.Bits[I] Do Begin
   HuffSize[K] := I; Inc(K);
  End;
 T.NumVals := K;
 { Construire huffcode }
 Code := 0; SI := HuffSize[0];
 For I := 0 To K - 1 Do Begin
  While HuffSize[I] <> SI Do Begin
   Code := Code Shl 1; Inc(SI);
  End;
  HuffCode[I] := Code;
  Inc(Code);
 End;
 { Construire mincode/maxcode/valptr par longueur }
 For I := 1 To 16 Do Begin
  T.MinCode[I] := -1;
  T.MaxCode[I] := -1;
  T.ValPtr[I]  := 0;
 End;
 J := 0;
 For I := 1 To 16 Do
  If T.Bits[I] > 0 Then Begin
   T.ValPtr[I]  := J;
   T.MinCode[I] := HuffCode[J];
   T.MaxCode[I] := HuffCode[J + T.Bits[I] - 1];
   Inc(J, T.Bits[I]);
  End;
End;

Procedure JpgInitTables;
Var
 ZZ : Array[0..63] Of Byte;
 I, J: Integer;
 PI : Real;
 Cu : Real;
Begin
 ZZ[0]:=0;  ZZ[1]:=1;  ZZ[2]:=8;  ZZ[3]:=16; ZZ[4]:=9;  ZZ[5]:=2;  ZZ[6]:=3;
   ZZ[7]:=10;
 ZZ[8]:=17; ZZ[9]:=24; ZZ[10]:=32; ZZ[11]:=25; ZZ[12]:=18; ZZ[13]:=11;
   ZZ[14]:=4;  ZZ[15]:=5;
 ZZ[16]:=12; ZZ[17]:=19; ZZ[18]:=26; ZZ[19]:=33; ZZ[20]:=40; ZZ[21]:=48;
   ZZ[22]:=41; ZZ[23]:=34;
 ZZ[24]:=27; ZZ[25]:=20; ZZ[26]:=13; ZZ[27]:=6;  ZZ[28]:=7;  ZZ[29]:=14;
   ZZ[30]:=21; ZZ[31]:=28;
 ZZ[32]:=35; ZZ[33]:=42; ZZ[34]:=49; ZZ[35]:=56; ZZ[36]:=57; ZZ[37]:=50;
   ZZ[38]:=43; ZZ[39]:=36;
 ZZ[40]:=29; ZZ[41]:=22; ZZ[42]:=15; ZZ[43]:=23; ZZ[44]:=30; ZZ[45]:=37;
   ZZ[46]:=44; ZZ[47]:=51;
 ZZ[48]:=58; ZZ[49]:=59; ZZ[50]:=52; ZZ[51]:=45; ZZ[52]:=38; ZZ[53]:=31;
   ZZ[54]:=39; ZZ[55]:=46;
 ZZ[56]:=53; ZZ[57]:=60; ZZ[58]:=61; ZZ[59]:=54; ZZ[60]:=47; ZZ[61]:=55;
   ZZ[62]:=62; ZZ[63]:=63;
 For I := 0 To 63 Do JpgZigzag[I] := ZZ[I];
 PI := 3.14159265358979;
 For I := 0 To 7 Do Begin
  If I = 0 Then Cu := 1.0 / 1.41421356237
           Else Cu := 1.0;
  For J := 0 To 7 Do
   JpgCosTab[I, J] := Cu * Cos((2*J + 1) * I * PI / 16.0);
 End;
 JpgIDCTInit := True;
End;

{ IDCT 8x8 separable. In = coefs de-quantifies; Out = pixels (-128..127) }
Procedure JpgIDCT(Var Coef: TJpgBlock; Var Pix: Array Of Integer);
Var
 Tmp    : Array[0..63] Of Real;
 X, Y, U, V : Integer;
 S      : Real;
 V0     : Integer;
Begin
 { Row pass : Tmp[y][x] = sum_u F[y][u]*Cu*cos((2x+1)u pi/16) }
 For Y := 0 To 7 Do
  For X := 0 To 7 Do Begin
   S := 0;
   For U := 0 To 7 Do
    S := S + Coef[Y*8 + U] * JpgCosTab[U, X];
   Tmp[Y*8 + X] := S;
  End;
 { Col pass + scale 1/4 }
 For X := 0 To 7 Do
  For Y := 0 To 7 Do Begin
   S := 0;
   For V := 0 To 7 Do
    S := S + Tmp[V*8 + X] * JpgCosTab[V, Y];
   V0 := Round(S / 4.0);
   If V0 < -128 Then V0 := -128;
   If V0 > 127  Then V0 := 127;
   Pix[Y*8 + X] := V0;
  End;
End;

{ Decode un bloc 8x8 (DC+AC), dequant, IDCT. Pix sera -128..127. }
Function JpgDecodeBlock(Var Comp: TJpgComp; Var Pix: Array Of Integer): Boolean;
Var
 Coef        : TJpgBlock;
 ZZCoef      : TJpgBlock;
 I           : Integer;
 S, T        : Integer;
 Run         : Integer;
 RS          : Integer;
 K           : Integer;
 V           : LongInt;
 QT          : Integer;
Begin
 For I := 0 To 63 Do Coef[I] := 0;
 { DC }
 T := JpgDecodeSymbol(JpgDCHuff[Comp.DCT]);
 V := JpgReadBits(T);
 S := JpgExtend(V, T);
 Comp.PrevDC := Comp.PrevDC + S;
 Coef[0] := Comp.PrevDC;
 { AC }
 K := 1;
 While K < 64 Do Begin
  RS := JpgDecodeSymbol(JpgACHuff[Comp.ACT]);
  Run := RS Shr 4;
  T   := RS And $0F;
  If T = 0 Then Begin
   If Run = 15 Then Begin
    Inc(K, 16);
    Continue;
   End;
   Break;     { EOB }
  End;
  Inc(K, Run);
  If K >= 64 Then Break;
  V := JpgReadBits(T);
  Coef[K] := JpgExtend(V, T);
  Inc(K);
 End;
 { Dequantize + dezigzag }
 QT := Comp.QTId;
 For I := 0 To 63 Do
  ZZCoef[JpgZigzag[I]] := Coef[I] * JpgQT[QT, I];
 JpgIDCT(ZZCoef, Pix);
 JpgDecodeBlock := True;
End;

Procedure JpgReadDQT(Len: Integer);
Var
 PqTq, Pq, Tq: Byte;
 Bytes: Integer;
 I: Integer;
 W: Word;
Begin
 Bytes := Len - 2;
 While Bytes > 0 Do Begin
  BlockRead(JpgFh, PqTq, 1); Dec(Bytes);
  Pq := PqTq Shr 4;
  Tq := PqTq And $0F;
  If Tq > 3 Then Exit;
  For I := 0 To 63 Do
   If Pq = 0 Then Begin
    BlockRead(JpgFh, PqTq, 1); Dec(Bytes);
    JpgQT[Tq, I] := PqTq;
   End Else Begin
    BlockRead(JpgFh, W, 2); Dec(Bytes, 2);
    JpgQT[Tq, I] := Integer(Swap(W));
   End;
 End;
End;

Procedure JpgReadDHT(Len: Integer);
Var
 TcTh, Tc, Th : Byte;
 I, Total     : Integer;
 Bytes        : Integer;
Begin
 Bytes := Len - 2;
 While Bytes > 0 Do Begin
  BlockRead(JpgFh, TcTh, 1); Dec(Bytes);
  Tc := TcTh Shr 4;
  Th := TcTh And $0F;
  If Th > 3 Then Exit;
  Total := 0;
  If Tc = 0 Then Begin
   For I := 1 To 16 Do Begin
    BlockRead(JpgFh, JpgDCHuff[Th].Bits[I], 1);
    Inc(Total, JpgDCHuff[Th].Bits[I]);
   End;
   Dec(Bytes, 16);
   For I := 0 To Total - 1 Do BlockRead(JpgFh, JpgDCHuff[Th].HuffV[I], 1);
   Dec(Bytes, Total);
   JpgBuildHuffTables(JpgDCHuff[Th]);
  End Else Begin
   For I := 1 To 16 Do Begin
    BlockRead(JpgFh, JpgACHuff[Th].Bits[I], 1);
    Inc(Total, JpgACHuff[Th].Bits[I]);
   End;
   Dec(Bytes, 16);
   For I := 0 To Total - 1 Do BlockRead(JpgFh, JpgACHuff[Th].HuffV[I], 1);
   Dec(Bytes, Total);
   JpgBuildHuffTables(JpgACHuff[Th]);
  End;
 End;
End;

Function JpgReadSOF0(Len: Integer): Boolean;
Var
 Prec        : Byte;
 HH, WW      : Word;
 Nf          : Byte;
 I           : Integer;
 CompID, HV, Tq : Byte;
Begin
 JpgReadSOF0 := False;
 BlockRead(JpgFh, Prec, 1);
 If Prec <> 8 Then Exit;
 BlockRead(JpgFh, HH, 2);
 BlockRead(JpgFh, WW, 2);
 JpgHeight := Integer(Swap(HH));
 JpgWidth  := Integer(Swap(WW));
 BlockRead(JpgFh, Nf, 1);
 If (Nf <> 1) And (Nf <> 3) Then Exit;
 JpgNComp := Nf;
 JpgHmax := 0; JpgVmax := 0;
 For I := 0 To Nf - 1 Do Begin
  BlockRead(JpgFh, CompID, 1);
  BlockRead(JpgFh, HV, 1);
  BlockRead(JpgFh, Tq, 1);
  JpgComp[I].Id := CompID;
  JpgComp[I].HSamp := HV Shr 4;
  JpgComp[I].VSamp := HV And $0F;
  JpgComp[I].QTId := Tq;
  If JpgComp[I].HSamp > JpgHmax Then JpgHmax := JpgComp[I].HSamp;
  If JpgComp[I].VSamp > JpgVmax Then JpgVmax := JpgComp[I].VSamp;
 End;
 JpgMCUW := JpgHmax * 8;
 JpgMCUH := JpgVmax * 8;
 JpgReadSOF0 := True;
End;

Function JpgReadSOS(Len: Integer): Boolean;
Var
 Ns, CS, Td_Ta, Ss, Se, AhAl : Byte;
 I, J : Integer;
Begin
 JpgReadSOS := False;
 BlockRead(JpgFh, Ns, 1);
 If Ns <> JpgNComp Then Exit;
 For I := 0 To Ns - 1 Do Begin
  BlockRead(JpgFh, CS, 1);
  BlockRead(JpgFh, Td_Ta, 1);
  For J := 0 To JpgNComp - 1 Do
   If JpgComp[J].Id = CS Then Begin
    JpgComp[J].DCT := Td_Ta Shr 4;
    JpgComp[J].ACT := Td_Ta And $0F;
   End;
 End;
 BlockRead(JpgFh, Ss, 1);
 BlockRead(JpgFh, Se, 1);
 BlockRead(JpgFh, AhAl, 1);
 JpgReadSOS := True;
End;

Function JpgYCbCrToVGA(Y, Cb, Cr: Integer): Byte;
Var R, G, B, T: Integer;
Begin
 { Y, Cb, Cr deja ajoutes +128 ; conversion JFIF }
 T := Cr - 128;
 R := Y + ((91881 * T) Shr 16);
 T := Cb - 128;
 B := Y + ((116130 * T) Shr 16);
 G := Y - ((22554 * (Cb - 128) + 46802 * (Cr - 128)) Shr 16);
 If R < 0 Then R := 0; If R > 255 Then R := 255;
 If G < 0 Then G := 0; If G > 255 Then G := 255;
 If B < 0 Then B := 0; If B > 255 Then B := 255;
 JpgYCbCrToVGA := NearestVGA(Byte(R), Byte(G), Byte(B));
End;

Function LoadJPEG(Const FName: String; Var Buf: Pointer;
                  Var W, H: Integer): Boolean;
Var
 Sig         : Word;
 Marker      : Byte;
 SegLen      : Word;
 B           : Byte;
 NumMCURows  : Integer;
 NumMCUCols  : Integer;
 MX, MY      : Integer;
 Ci, Bi, BIdx: Integer;
 Pix         : Array[0..63] Of Integer;
 CompPlanes  : Array[0..2, 0..255] Of Integer;   { max MCU 16x16 = 256 }
 PX, PY      : Integer;
 GX, GY      : Integer;
 YVal, CbVal, CrVal : Integer;
 LumaX, LumaY : Integer;
 ChrX, ChrY   : Integer;
 OutBuf      : Pointer;
 RstCnt      : Integer;
 I, J        : Integer;
 SOSDone     : Boolean;
 ScanByte    : Byte;
 ScanByte2   : Byte;
 BX, BY      : Integer;
Begin
 LoadJPEG := False; Buf := Nil; W := 0; H := 0;
 If Not JpgIDCTInit Then JpgInitTables;
 {$I-} Assign(JpgFh, FName); Reset(JpgFh, 1); {$I+}
 If IOResult <> 0 Then Exit;
 JpgBufLen := 0; JpgBufIdx := 0; JpgEofFlag := False;
 JpgBitBuf := 0; JpgBitCnt := 0;
 JpgRSTI := 0;
 { SOI }
 If Not JpgGetRawByte(B) Then Begin Close(JpgFh); Exit; End;
 If B <> $FF Then Begin Close(JpgFh); Exit; End;
 If Not JpgGetRawByte(B) Then Begin Close(JpgFh); Exit; End;
 If B <> $D8 Then Begin Close(JpgFh); Exit; End;
 { Parse markers jusqu'a SOS }
 SOSDone := False;
 While Not SOSDone Do Begin
  If Not JpgGetRawByte(B) Then Begin Close(JpgFh); Exit; End;
  If B <> $FF Then Continue;
  While B = $FF Do
   If Not JpgGetRawByte(B) Then Begin Close(JpgFh); Exit; End;
  Marker := B;
  If Marker = 0 Then Continue;
  If (Marker >= $D0) And (Marker <= $D9) Then Continue;
  { Lire longueur }
  If Not JpgGetRawByte(B) Then Begin Close(JpgFh); Exit; End;
  SegLen := Word(B) Shl 8;
  If Not JpgGetRawByte(B) Then Begin Close(JpgFh); Exit; End;
  SegLen := SegLen Or B;
  Case Marker Of
   $C0: Begin
    If Not JpgReadSOF0(SegLen) Then Begin Close(JpgFh); Exit; End;
   End;
   $C4: JpgReadDHT(SegLen);
   $DB: JpgReadDQT(SegLen);
   $DD: Begin
    BlockRead(JpgFh, B, 1);
    JpgRSTI := Integer(B) Shl 8;
    BlockRead(JpgFh, B, 1);
    JpgRSTI := JpgRSTI Or B;
   End;
   $DA: Begin
    If Not JpgReadSOS(SegLen) Then Begin Close(JpgFh); Exit; End;
    SOSDone := True;
   End;
  Else
   { Skip segment }
   For I := 0 To Integer(SegLen) - 3 Do BlockRead(JpgFh, B, 1);
  End;
 End;
 { Decode scan }
 If (JpgWidth <= 0) Or (JpgHeight <= 0) Or
    (JpgWidth > 4096) Or (JpgHeight > 4096) Then Begin Close(JpgFh); Exit; End;
 NumMCUCols := (JpgWidth  + JpgMCUW - 1) Div JpgMCUW;
 NumMCURows := (JpgHeight + JpgMCUH - 1) Div JpgMCUH;
 GetMem(OutBuf, LongInt(JpgWidth) * JpgHeight);
 For I := 0 To 2 Do JpgComp[I].PrevDC := 0;
 RstCnt := 0;
 For MY := 0 To NumMCURows - 1 Do
  For MX := 0 To NumMCUCols - 1 Do Begin
   { Decode chaque composante }
   For Ci := 0 To JpgNComp - 1 Do Begin
    For BY := 0 To JpgComp[Ci].VSamp - 1 Do
     For BX := 0 To JpgComp[Ci].HSamp - 1 Do Begin
      JpgDecodeBlock(JpgComp[Ci], Pix);
      { Niveau shift +128 et place dans CompPlanes }
      For PY := 0 To 7 Do
       For PX := 0 To 7 Do Begin
        I := (BY*8 + PY) * JpgMCUW + (BX*8 + PX);
        { Si composante a sampling < max, etirer }
        If JpgComp[Ci].HSamp = JpgHmax Then ChrX := 1 Else ChrX := JpgHmax Div
          JpgComp[Ci].HSamp;
        If JpgComp[Ci].VSamp = JpgVmax Then ChrY := 1 Else ChrY := JpgVmax Div
          JpgComp[Ci].VSamp;
        For LumaY := 0 To ChrY - 1 Do
         For LumaX := 0 To ChrX - 1 Do Begin
          J := ((BY*8 + PY)*ChrY + LumaY) * JpgMCUW + ((BX*8 + PX)*ChrX +
            LumaX);
          If (J >= 0) And (J < 256) Then
           CompPlanes[Ci, J] := Pix[PY*8 + PX] + 128;
         End;
       End;
     End;
   End;
   { Convertir et ecrire dans OutBuf }
   For PY := 0 To JpgMCUH - 1 Do
    For PX := 0 To JpgMCUW - 1 Do Begin
     GX := MX * JpgMCUW + PX;
     GY := MY * JpgMCUH + PY;
     If (GX < JpgWidth) And (GY < JpgHeight) Then Begin
      I := PY * JpgMCUW + PX;
      If JpgNComp = 1 Then Begin
       YVal := CompPlanes[0, I];
       If YVal < 0 Then YVal := 0;
       If YVal > 255 Then YVal := 255;
       ImgPByteSet(OutBuf, LongInt(GY)*JpgWidth + GX,
        NearestVGA(Byte(YVal), Byte(YVal), Byte(YVal)));
      End Else Begin
       YVal := CompPlanes[0, I];
       CbVal := CompPlanes[1, I];
       CrVal := CompPlanes[2, I];
       ImgPByteSet(OutBuf, LongInt(GY)*JpgWidth + GX,
        JpgYCbCrToVGA(YVal, CbVal, CrVal));
      End;
     End;
    End;
   { Restart interval }
   If JpgRSTI > 0 Then Begin
    Inc(RstCnt);
    If (RstCnt = JpgRSTI) And ((MY < NumMCURows - 1) Or (MX < NumMCUCols - 1))
      Then Begin
     RstCnt := 0;
     { Vider bits, lire marker RSTm }
     JpgBitBuf := 0; JpgBitCnt := 0;
     If JpgGetRawByte(ScanByte) Then Begin
      While (ScanByte <> $FF) And JpgGetRawByte(ScanByte) Do ;
      JpgGetRawByte(ScanByte2);
     End;
     For I := 0 To 2 Do JpgComp[I].PrevDC := 0;
    End;
   End;
  End;
 Close(JpgFh);
 Buf := OutBuf; W := JpgWidth; H := JpgHeight;
 LoadJPEG := True;
End;

{ ---------- Image GPX du MonsterBook ----------------------------- }
{ Entete (11 octets) : 'GPX'#26, Largeur(W), Hauteur(W), Bandes(W),  }
{ BitsParPixel(B). Puis Largeur*Bandes octets (bandes verticales de  }
{ 8 pixels, pour l'impression) suivis de la trame : Bandes*8 lignes  }
{ de (Largeur*Bpp+7)/8 octets, bit de poids fort = pixel de gauche.  }
{ 1 bpp : bit a 1 = encre (noir). 4 bpp : couleur EGA. 8 bpp : gris. }

Function LoadGPX(Const FName: String; Var Buf: Pointer;
                 Var W, H: Integer): Boolean;
Var
 F        : File;
 Hd       : Array[0..10] Of Byte;
 Len, Ln, Bpp, RowB, Y, X, Rows : Integer;
 Row      : Array[0..2047] Of Byte;
 P        : ^Byte;
 V        : Byte;
 Got      : LongInt;
Begin
 LoadGPX := False; Buf := Nil; W := 0; H := 0;
 {$I-} Assign(F, FName); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 {$I-} BlockRead(F, Hd, 11, Got); {$I+}
 If (IOResult <> 0) Or (Got <> 11) Or (Hd[0] <> 71) Or (Hd[1] <> 80) Or
    (Hd[2] <> 88) Or (Hd[3] <> 26) Then Begin
  {$I-} Close(F); {$I+} If IOResult <> 0 Then ;
  Exit;
 End;
 Len := Hd[4] + Hd[5] * 256;
 Ln  := Hd[8] + Hd[9] * 256;
 Bpp := Hd[10];
 Rows := Ln * 8;
 If (Len < 1) Or (Rows < 1) Or (Rows > 4000) Or
    ((Bpp <> 1) And (Bpp <> 4) And (Bpp <> 8)) Then Begin
  {$I-} Close(F); {$I+} If IOResult <> 0 Then ;
  Exit;
 End;
 RowB := (Len * Bpp + 7) Div 8;
 If RowB > 2048 Then Begin
  {$I-} Close(F); {$I+} If IOResult <> 0 Then ;
  Exit;
 End;
 GetMem(Buf, LongInt(Len) * Rows);
 {$I-} Seek(F, 11 + LongInt(Len) * Ln); {$I+}
 P := Buf;
 For Y := 0 To Rows - 1 Do Begin
  FillChar(Row, SizeOf(Row), 0);
  {$I-} BlockRead(F, Row, RowB, Got); {$I+}
  If (IOResult <> 0) Or (Got <> RowB) Then Begin
   FreeMem(Buf, LongInt(Len) * Rows); Buf := Nil;
   {$I-} Close(F); {$I+} If IOResult <> 0 Then ;
   Exit;
  End;
  For X := 0 To Len - 1 Do Begin
   Case Bpp Of
    1: If ((Row[X Shr 3] Shr (7 - (X And 7))) And 1) <> 0 Then V := 0 Else V :=
      15;
    4: If (X And 1) = 0 Then V := Row[X Shr 1] Shr 4 Else V := Row[X Shr 1] And
      15;
   Else V := Row[X] Shr 4;
   End;
   P^ := V; Inc(P);
  End;
 End;
 {$I-} Close(F); {$I+} If IOResult <> 0 Then ;
 W := Len; H := Rows;
 LoadGPX := True;
End;

{ ------------------------------------------------------------ }
{ ------ Dispatcher unifie par extension --------------------- }
{ ------------------------------------------------------------ }

Function LoadAnyImage(Const FName: String; Var Buf: Pointer;
                      Var W, H: Integer): Boolean;
Var
 Ext : String;
 LF  : Integer;
 CC  : Char;
Begin
 LoadAnyImage := False;
 Ext := ''; LF := Length(FName);
 If LF >= 4 Then Begin
  If FName[LF-3] = '.' Then Begin
   CC := ImgUpcaseChar(FName[LF-2]); Ext := Ext + CC;
   CC := ImgUpcaseChar(FName[LF-1]); Ext := Ext + CC;
   CC := ImgUpcaseChar(FName[LF]);   Ext := Ext + CC;
  End Else If (LF >= 5) And (FName[LF-4] = '.') Then Begin
   CC := ImgUpcaseChar(FName[LF-3]); Ext := Ext + CC;
   CC := ImgUpcaseChar(FName[LF-2]); Ext := Ext + CC;
   CC := ImgUpcaseChar(FName[LF-1]); Ext := Ext + CC;
   CC := ImgUpcaseChar(FName[LF]);   Ext := Ext + CC;
  End;
 End;
 If      Ext = 'BMP'  Then LoadAnyImage := LoadBMP(FName, Buf, W, H)
 Else If Ext = 'PCX'  Then LoadAnyImage := LoadPCX(FName, Buf, W, H)
 Else If Ext = 'BGX'  Then LoadAnyImage := LoadBGX(FName, Buf, W, H)
 Else If Ext = 'XBM'  Then LoadAnyImage := LoadXBM(FName, Buf, W, H)
 Else If Ext = 'TIF'  Then LoadAnyImage := LoadTIFF(FName, Buf, W, H)
 Else If Ext = 'TIFF' Then LoadAnyImage := LoadTIFF(FName, Buf, W, H)
 Else If Ext = 'GIF'  Then LoadAnyImage := LoadGIF(FName, Buf, W, H)
 Else If Ext = 'JPG'  Then LoadAnyImage := LoadJPEG(FName, Buf, W, H)
 Else If Ext = 'JPEG' Then LoadAnyImage := LoadJPEG(FName, Buf, W, H)
 Else If Ext = 'GPX'  Then LoadAnyImage := LoadGPX(FName, Buf, W, H);
End;

Procedure InsertImageAtCursor(Buf: Pointer; W, H: Integer);
Var
 NewIdx, P, I       : Integer;
 ScaledBuf          : Pointer;
 SW, SH             : Integer;
Begin
 If Doc^.ParaCount >= MAX_PARAS_PER_DOC - 1 Then Begin
  FreeMem(Buf, W*H);
  Exit;
 End;
 ScaleImageNN(Buf, W, H, ScaledBuf, SW, SH);
 FreeMem(Buf, W*H);
 If Cursor.CharIdx > 0 Then NewParagraphAtCursor;
 P := Cursor.ParaIdx;
 NewIdx := P + 1;
 For I := Doc^.ParaCount Downto NewIdx Do
  Doc^.Paragraphs[I+1] := Doc^.Paragraphs[I];
 Inc(Doc^.ParaCount);
 FillChar(Doc^.Paragraphs[NewIdx], SizeOf(TParagraph), 0);
 Doc^.Paragraphs[NewIdx].Alignment := ALIGN_CENTER;
 Doc^.Paragraphs[NewIdx].IsImage   := True;
 Doc^.Paragraphs[NewIdx].ImgW      := SW;
 Doc^.Paragraphs[NewIdx].ImgH      := SH;
 Doc^.Paragraphs[NewIdx].ImgData   := ScaledBuf;
 { Para vide ensuite pour permettre saisie sous l'image. }
 If (NewIdx = Doc^.ParaCount) And (Doc^.ParaCount < MAX_PARAS_PER_DOC) Then Begin
  Inc(Doc^.ParaCount);
  FillChar(Doc^.Paragraphs[NewIdx+1], SizeOf(TParagraph), 0);
  Doc^.Paragraphs[NewIdx+1].RunCount := 1;
  Doc^.Paragraphs[NewIdx+1].Runs[1].Style := CurrentStyle;
  Doc^.Paragraphs[NewIdx+1].Runs[1].Text := '';
  Cursor.ParaIdx := NewIdx + 1;
 End Else
  Cursor.ParaIdx := NewIdx + 1;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := 0;
 Doc^.Modified   := True;
 NeedsRelayout  := True;
End;

{ ----- Insertion d'un tableau au curseur (Phase 11) ----------- }

Procedure InsertTableAtCursor(Rows, Cols: Integer);
Var
 NewIdx, P, I, TIdx : Integer;
Begin
 If Doc^.ParaCount >= MAX_PARAS_PER_DOC - 1 Then Exit;
 TIdx := AllocTable(Rows, Cols);
 If TIdx = 0 Then Exit;
 If Cursor.CharIdx > 0 Then NewParagraphAtCursor;
 P := Cursor.ParaIdx;
 NewIdx := P + 1;
 For I := Doc^.ParaCount Downto NewIdx Do
  Doc^.Paragraphs[I+1] := Doc^.Paragraphs[I];
 Inc(Doc^.ParaCount);
 FillChar(Doc^.Paragraphs[NewIdx], SizeOf(TParagraph), 0);
 Doc^.Paragraphs[NewIdx].Alignment := ALIGN_LEFT;
 Doc^.Paragraphs[NewIdx].TableIdx  := TIdx;
 { Para vide ensuite pour permettre saisie sous le tableau. }
 If (NewIdx = Doc^.ParaCount) And (Doc^.ParaCount < MAX_PARAS_PER_DOC) Then Begin
  Inc(Doc^.ParaCount);
  FillChar(Doc^.Paragraphs[NewIdx+1], SizeOf(TParagraph), 0);
  Doc^.Paragraphs[NewIdx+1].RunCount := 1;
  Doc^.Paragraphs[NewIdx+1].Runs[1].Style := CurrentStyle;
  Doc^.Paragraphs[NewIdx+1].Runs[1].Text := '';
 End;
 { Curseur dans la cellule (1,1). }
 SetCursorToCell(NewIdx, 1, 1, 0);
 Doc^.Modified   := True;
 NeedsRelayout  := True;
End;

{ Supprime le tableau dont le paragraphe est P, libere son slot. }
Procedure DeleteTableAtPara(P: Integer);
Var I, TIdx: Integer;
Begin
 If Not ParaIsTable(P) Then Exit;
 TIdx := Doc^.Paragraphs[P].TableIdx;
 FreeTable(TIdx);
 For I := P To Doc^.ParaCount - 1 Do
  Doc^.Paragraphs[I] := Doc^.Paragraphs[I+1];
 FillChar(Doc^.Paragraphs[Doc^.ParaCount], SizeOf(TParagraph), 0);
 Dec(Doc^.ParaCount);
 If Doc^.ParaCount < 1 Then Begin
  Doc^.ParaCount := 1;
  Doc^.Paragraphs[1].RunCount := 1;
  Doc^.Paragraphs[1].Runs[1].Style := CurrentStyle;
  Doc^.Paragraphs[1].Runs[1].Text := '';
 End;
 If Cursor.ParaIdx > Doc^.ParaCount Then Cursor.ParaIdx := Doc^.ParaCount;
 If Cursor.ParaIdx < 1 Then Cursor.ParaIdx := 1;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := 0;
 Doc^.Modified   := True;
 NeedsRelayout  := True;
End;

{ ----- Menu contextuel tableau (clic droit) ------------------- }

Procedure ShowMessage(Const S: String); Forward;
Procedure MarkMutation(Kind: Integer); Forward;

Const
 TBL_CTX_ITEMS = 9;
 TblCtxLabels : Array[1..TBL_CTX_ITEMS] Of String[28] = (
  'Inserer ligne au-dessus',
  'Inserer ligne en-dessous',
  'Supprimer la ligne',
  '-',
  'Inserer colonne a gauche',
  'Inserer colonne a droite',
  'Supprimer la colonne',
  '-',
  'Proprietes du tableau...');

{ Affiche le menu contextuel a (Mx,My). P = paragraphe-tableau,
  Row,Col = cellule cliquee. Action effectuee directement. }
Procedure ShowTableContextMenu(Mx, My, P, Row, Col: Integer);
Var
 X1, Y1, X2, Y2, ItemH, MenuW : Integer;
 I, Hover, Sel                : Integer;
 Done                         : Boolean;
 K                            : Word;
 LastBtn                      : Word;
 TIdx                         : Integer;
 Msg, SR, SC                  : String;

 Function ItemAtY(Y: Integer): Integer;
 Var II: Integer;
 Begin
  ItemAtY := 0;
  If (Y < Y1+2) Or (Y > Y2-2) Then Exit;
  II := ((Y - (Y1+2)) Div ItemH) + 1;
  If (II >= 1) And (II <= TBL_CTX_ITEMS) Then
   If TblCtxLabels[II] <> '-' Then ItemAtY := II;
 End;

 Procedure DrawCtx;
 Var II, IY: Integer;
 Begin
  FillRectArea(X1, Y1, X2, Y2, CLR_3D_FACE);
  DrawButton3D(X1, Y1, X2, Y2, False);
  For II := 1 To TBL_CTX_ITEMS Do Begin
   IY := Y1 + 2 + (II-1)*ItemH;
   If TblCtxLabels[II] = '-' Then Begin
    SetColor(DarkGray);
    Line(X1+4, IY+ItemH Div 2, X2-4, IY+ItemH Div 2);
   End Else Begin
    If II = Hover Then Begin
     FillRectArea(X1+2, IY, X2-2, IY+ItemH-1, Blue);
     DrawTextAt(X1+8, IY+3, Tr(TblCtxLabels[II]), White);
    End Else
     DrawTextAt(X1+8, IY+3, Tr(TblCtxLabels[II]), Black);
   End;
  End;
 End;

Begin
 If Not ParaIsTable(P) Then Exit;
 TIdx := Doc^.Paragraphs[P].TableIdx;
 ItemH := 14;
 MenuW := 200;
 For I := 1 To TBL_CTX_ITEMS Do
  If TextWidth(Tr(TblCtxLabels[I])) + 24 > MenuW Then
   MenuW := TextWidth(Tr(TblCtxLabels[I])) + 24;
 X1 := Mx;
 Y1 := My;
 X2 := X1 + MenuW;
 Y2 := Y1 + ItemH * TBL_CTX_ITEMS + 4;
 If X2 > SCREEN_W - 4 Then Begin X2 := SCREEN_W - 4; X1 := X2 - MenuW; End;
 If Y2 > SCREEN_H - 4 Then Begin Y2 := SCREEN_H - 4;
   Y1 := Y2 - (ItemH*TBL_CTX_ITEMS + 4); End;
 If X1 < 2 Then X1 := 2;
 If Y1 < 2 Then Y1 := 2;
 EraseSoftCursor;
 Hover := 1;
 Sel := 0;
 Done := False;
 DrawCtx;
  DrawSoftCursor(MsX, MsY); 
 LastBtn := MsBtn;
 { Attendre relachement initial du bouton droit. }
 Repeat GetMouseStateLI(MsX, MsY, MsBtn); Until (MsBtn And MB_RIGHT) = 0;
 LastBtn := 0;
 Repeat
  If KeyPressed Then Begin
   K := ReadKeyEx;
   Case K Of
    KEY_ESC   : Begin Done := True; Sel := 0; End;
    KEY_UP    : Begin
                 Repeat Dec(Hover); If Hover < 1 Then Hover := TBL_CTX_ITEMS;
                 Until TblCtxLabels[Hover] <> '-';
                 EraseSoftCursor; DrawCtx;
                  DrawSoftCursor(MsX, MsY); 
                End;
    KEY_DOWN  : Begin
                 Repeat Inc(Hover); If Hover > TBL_CTX_ITEMS Then Hover := 1;
                 Until TblCtxLabels[Hover] <> '-';
                 EraseSoftCursor; DrawCtx;
                  DrawSoftCursor(MsX, MsY); 
                End;
    KEY_ENTER : Begin Done := True; Sel := Hover; End;
   End;
  End;
  EraseSoftCursor;
  GetMouseStateLI(MsX, MsY, MsBtn);
  If (MsX >= X1) And (MsX <= X2) And (MsY >= Y1) And (MsY <= Y2) Then Begin
   I := ItemAtY(MsY);
   If (I > 0) And (I <> Hover) Then Begin
    Hover := I;
    DrawCtx;
   End;
  End;
  If ((MsBtn And MB_LEFT) <> 0) And ((LastBtn And MB_LEFT) = 0) Then Begin
   If (MsX >= X1) And (MsX <= X2) And (MsY >= Y1) And (MsY <= Y2) Then Begin
    I := ItemAtY(MsY);
    If I > 0 Then Begin Sel := I; Done := True; End;
   End Else Begin
    Sel := 0; Done := True;
   End;
  End;
  If ((MsBtn And MB_RIGHT) <> 0) And ((LastBtn And MB_RIGHT) = 0) Then Begin
   Sel := 0; Done := True;
  End;
  LastBtn := MsBtn;
   DrawSoftCursor(MsX, MsY); 
 Until Done;
 { Attendre relachement boutons. }
 Repeat GetMouseStateLI(MsX, MsY, MsBtn);
 Until ((MsBtn And MB_LEFT) = 0) And ((MsBtn And MB_RIGHT) = 0);
 NeedsRedraw := True;

 Case Sel Of
  1: Begin
      MarkMutation(2);
      If TableInsertRow(TIdx, Row) Then Begin
       SetCursorToCell(P, Row, Col, 0);
       NeedsRelayout := True;
      End Else
       ShowMessage(Tr('Tableau plein (max 16 lignes).'));
     End;
  2: Begin
      MarkMutation(2);
      If TableInsertRow(TIdx, Row + 1) Then Begin
       SetCursorToCell(P, Row + 1, Col, 0);
       NeedsRelayout := True;
      End Else
       ShowMessage(Tr('Tableau plein (max 16 lignes).'));
     End;
  3: Begin
      If Tables[TIdx].Rows <= 1 Then Begin
       ShowMessage(Tr('Impossible : le tableau n''a qu''une ligne.'));
      End Else Begin
       MarkMutation(2);
       TableDeleteRow(TIdx, Row);
       If Row > Tables[TIdx].Rows Then Row := Tables[TIdx].Rows;
       SetCursorToCell(P, Row, Col, 0);
       NeedsRelayout := True;
      End;
     End;
  5: Begin
      MarkMutation(2);
      If TableInsertCol(TIdx, Col) Then Begin
       SetCursorToCell(P, Row, Col, 0);
       NeedsRelayout := True;
      End Else
       ShowMessage(Tr('Tableau plein (max 6 colonnes).'));
     End;
  6: Begin
      MarkMutation(2);
      If TableInsertCol(TIdx, Col + 1) Then Begin
       SetCursorToCell(P, Row, Col + 1, 0);
       NeedsRelayout := True;
      End Else
       ShowMessage(Tr('Tableau plein (max 6 colonnes).'));
     End;
  7: Begin
      If Tables[TIdx].Cols <= 1 Then Begin
       ShowMessage(Tr('Impossible : le tableau n''a qu''une colonne.'));
      End Else Begin
       MarkMutation(2);
       TableDeleteCol(TIdx, Col);
       If Col > Tables[TIdx].Cols Then Col := Tables[TIdx].Cols;
       SetCursorToCell(P, Row, Col, 0);
       NeedsRelayout := True;
      End;
     End;
  9: Begin
      Str(Tables[TIdx].Rows, SR);
      Str(Tables[TIdx].Cols, SC);
      Msg := Tr('Tableau : ') + SR + Tr(' lignes x ') + SC + Tr(' colonnes');
      ShowMessage(Msg);
     End;
 End;
End;


{ ----------------------- CRC-32 (zlib) ---------------------- }

Var
 CRC32_Tbl_Init : Boolean;
 CRC32_Tbl      : Array[0..255] Of Cardinal;

Procedure InitCRC32Tbl;
Var I, J: Integer; C: Cardinal;
Begin
 If CRC32_Tbl_Init Then Exit;
 For I := 0 To 255 Do Begin
  C := I;
  For J := 0 To 7 Do
   If (C And 1) <> 0 Then C := Cardinal($EDB88320) Xor (C Shr 1)
   Else                   C := C Shr 1;
  CRC32_Tbl[I] := C;
 End;
 CRC32_Tbl_Init := True;
End;

Function CRC32Of(P: Pointer; N: LongInt): Cardinal;
Var PB: ^Byte; I: LongInt; CRC: Cardinal;
Begin
 InitCRC32Tbl;
 PB := P;
 CRC := Cardinal($FFFFFFFF);
 For I := 1 To N Do Begin
  CRC := CRC32_Tbl[(CRC Xor PB^) And $FF] Xor (CRC Shr 8);
  Inc(PB);
 End;
 CRC32Of := CRC Xor Cardinal($FFFFFFFF);
End;

{ ------------------- INFLATE (RFC 1951) -------------------- }

Const
 INF_LengthBase  : Array[0..28] Of Word =
  (3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,
   35,43,51,59,67,83,99,115,131,163,195,227,258);
 INF_LengthExtra : Array[0..28] Of Byte =
  (0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,
   3,3,3,3,4,4,4,4,5,5,5,5,0);
 INF_DistBase    : Array[0..29] Of Word =
  (1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,
   257,385,513,769,1025,1537,2049,3073,4097,6145,
   8193,12289,16385,24577);
 INF_DistExtra   : Array[0..29] Of Byte =
  (0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,
   7,7,8,8,9,9,10,10,11,11,12,12,13,13);
 INF_ClenOrder   : Array[0..18] Of Byte =
  (16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15);

Type
 THuffTable = Record
  Counts  : Array[0..15] Of Integer;
  Symbols : Array[0..287] Of Integer;
 End;

Var
 InfSrc      : ^Byte;
 InfSrcLeft  : LongInt;
 InfBitBuf   : Cardinal;
 InfBitCnt   : Integer;
 InfOutBase  : ^Byte;
 InfOutPtr   : ^Byte;
 InfOutPos   : LongInt;
 InfOutSize  : LongInt;
 InfErr      : Boolean;

Procedure InfFillByte;
Begin
 If InfSrcLeft <= 0 Then Begin InfErr := True; Exit; End;
 InfBitBuf := InfBitBuf Or (Cardinal(InfSrc^) Shl InfBitCnt);
 Inc(InfBitCnt, 8);
 Inc(InfSrc); Dec(InfSrcLeft);
End;

Function InfGetBits(N: Integer): LongInt;
Var V, Mask: Cardinal;
Begin
 While InfBitCnt < N Do Begin
  InfFillByte;
  If InfErr Then Begin InfGetBits := 0; Exit; End;
 End;
 If N = 0 Then Begin InfGetBits := 0; Exit; End;
 Mask := (Cardinal(1) Shl N) - 1;
 V := InfBitBuf And Mask;
 InfBitBuf := InfBitBuf Shr N;
 Dec(InfBitCnt, N);
 InfGetBits := V;
End;

Procedure InfAlignByte;
Var Drop: Integer;
Begin
 Drop := InfBitCnt And 7;
 If Drop > 0 Then Begin
  InfBitBuf := InfBitBuf Shr Drop;
  Dec(InfBitCnt, Drop);
 End;
End;

Procedure InfOutByte(B: Byte);
Begin
 If InfOutPos >= InfOutSize Then Begin InfErr := True; Exit; End;
 InfOutPtr^ := B;
 Inc(InfOutPtr); Inc(InfOutPos);
End;

Procedure InfCopyMatch(Dist, Len: LongInt);
Var I, SrcPos: LongInt; SP: ^Byte;
Begin
 If (Dist <= 0) Or (Dist > InfOutPos) Then Begin InfErr := True; Exit; End;
 SrcPos := InfOutPos - Dist;
 For I := 1 To Len Do Begin
  If InfOutPos >= InfOutSize Then Begin InfErr := True; Exit; End;
  SP := InfOutBase; Inc(SP, SrcPos);
  InfOutPtr^ := SP^;
  Inc(InfOutPtr); Inc(InfOutPos); Inc(SrcPos);
 End;
End;

Procedure InfBuildHuff(Var Lens: Array Of Integer; N: Integer;
                       Var H: THuffTable);
Var I: Integer; Offs: Array[0..15] Of Integer;
Begin
 For I := 0 To 15 Do H.Counts[I] := 0;
 For I := 0 To N-1 Do
  If (Lens[I] >= 0) And (Lens[I] <= 15) Then Inc(H.Counts[Lens[I]]);
 H.Counts[0] := 0;
 Offs[0] := 0; Offs[1] := 0;
 For I := 1 To 14 Do Offs[I+1] := Offs[I] + H.Counts[I];
 For I := 0 To N-1 Do
  If (Lens[I] > 0) And (Lens[I] <= 15) Then Begin
   H.Symbols[Offs[Lens[I]]] := I;
   Inc(Offs[Lens[I]]);
  End;
End;

Function InfDecodeSym(Var H: THuffTable): Integer;
Var Code, First, Count, Idx, Len, Bit: Integer;
Begin
 Code := 0; First := 0; Idx := 0;
 For Len := 1 To 15 Do Begin
  Bit := InfGetBits(1);
  Code := (Code Shl 1) Or Bit;
  Count := H.Counts[Len];
  If (Code - Count) < First Then Begin
   InfDecodeSym := H.Symbols[Idx + (Code - First)];
   Exit;
  End;
  Idx := Idx + Count;
  First := (First + Count) Shl 1;
 End;
 InfErr := True;
 InfDecodeSym := -1;
End;

Procedure InfBuildFixed(Var HLit, HDist: THuffTable);
Var Lens: Array[0..287] Of Integer;
    DLens: Array[0..29] Of Integer;
    I: Integer;
Begin
 For I := 0 To 143 Do Lens[I] := 8;
 For I := 144 To 255 Do Lens[I] := 9;
 For I := 256 To 279 Do Lens[I] := 7;
 For I := 280 To 287 Do Lens[I] := 8;
 InfBuildHuff(Lens, 288, HLit);
 For I := 0 To 29 Do DLens[I] := 5;
 InfBuildHuff(DLens, 30, HDist);
End;

Procedure InfReadDynHuff(Var HLit, HDist: THuffTable);
Var
 HLitN, HDistN, HCLenN: Integer;
 ClenLens : Array[0..18] Of Integer;
 LitLens  : Array[0..287] Of Integer;
 DistLens : Array[0..29]  Of Integer;
 AllLens  : Array[0..317] Of Integer;
 HClen    : THuffTable;
 I, Sym, Rep, Total: Integer;
Begin
 HLitN  := InfGetBits(5) + 257;
 HDistN := InfGetBits(5) + 1;
 HCLenN := InfGetBits(4) + 4;
 If (HLitN > 286) Or (HDistN > 30) Or (HCLenN > 19) Then Begin
  InfErr := True; Exit;
 End;
 For I := 0 To 18 Do ClenLens[I] := 0;
 For I := 0 To HCLenN-1 Do ClenLens[INF_ClenOrder[I]] := InfGetBits(3);
 InfBuildHuff(ClenLens, 19, HClen);
 If InfErr Then Exit;
 Total := HLitN + HDistN; I := 0;
 While I < Total Do Begin
  Sym := InfDecodeSym(HClen);
  If InfErr Then Exit;
  If Sym < 16 Then Begin
   AllLens[I] := Sym; Inc(I);
  End Else If Sym = 16 Then Begin
   If I = 0 Then Begin InfErr := True; Exit; End;
   Rep := InfGetBits(2) + 3;
   While (Rep > 0) And (I < Total) Do Begin
    AllLens[I] := AllLens[I-1]; Inc(I); Dec(Rep);
   End;
  End Else If Sym = 17 Then Begin
   Rep := InfGetBits(3) + 3;
   While (Rep > 0) And (I < Total) Do Begin
    AllLens[I] := 0; Inc(I); Dec(Rep);
   End;
  End Else If Sym = 18 Then Begin
   Rep := InfGetBits(7) + 11;
   While (Rep > 0) And (I < Total) Do Begin
    AllLens[I] := 0; Inc(I); Dec(Rep);
   End;
  End Else Begin InfErr := True; Exit; End;
 End;
 For I := 0 To HLitN-1  Do LitLens[I]  := AllLens[I];
 For I := 0 To HDistN-1 Do DistLens[I] := AllLens[HLitN+I];
 InfBuildHuff(LitLens,  HLitN,  HLit);
 InfBuildHuff(DistLens, HDistN, HDist);
End;

Function InflateBuf(Src: Pointer; SrcSize: LongInt;
                    Dst: Pointer; DstSize: LongInt): Boolean;
Var
 BFinal, BType: Integer;
 Len, NLen: Word;
 I: LongInt;
 HLit, HDist: THuffTable;
 Sym, LenIdx, DistIdx: Integer;
 MLen, MDist: LongInt;
Begin
 InfSrc := Src; InfSrcLeft := SrcSize;
 InfBitBuf := 0; InfBitCnt := 0;
 InfOutBase := Dst; InfOutPtr := Dst;
 InfOutPos := 0; InfOutSize := DstSize;
 InfErr := False;
 BFinal := 0;
 While (Not InfErr) And (BFinal = 0) Do Begin
  BFinal := InfGetBits(1);
  BType  := InfGetBits(2);
  If InfErr Then Break;
  Case BType Of
   0: Begin
       InfAlignByte;
       Len  := Word(InfGetBits(16));
       NLen := Word(InfGetBits(16));
       If LongInt(Len) + LongInt(NLen) <> 65535 Then Begin
        InfErr := True; Break;
       End;
       For I := 1 To Len Do Begin
        InfOutByte(Byte(InfGetBits(8)));
        If InfErr Then Break;
       End;
      End;
   1: Begin
       InfBuildFixed(HLit, HDist);
       While Not InfErr Do Begin
        Sym := InfDecodeSym(HLit);
        If InfErr Then Break;
        If Sym < 256 Then InfOutByte(Sym)
        Else If Sym = 256 Then Break
        Else Begin
         LenIdx  := Sym - 257;
         If LenIdx > 28 Then Begin InfErr := True; Break; End;
         MLen    := INF_LengthBase[LenIdx] +
           InfGetBits(INF_LengthExtra[LenIdx]);
         DistIdx := InfDecodeSym(HDist);
         If (DistIdx < 0) Or (DistIdx > 29) Then Begin InfErr := True; Break;
           End;
         MDist   := INF_DistBase[DistIdx] + InfGetBits(INF_DistExtra[DistIdx]);
         InfCopyMatch(MDist, MLen);
        End;
       End;
      End;
   2: Begin
       InfReadDynHuff(HLit, HDist);
       If InfErr Then Break;
       While Not InfErr Do Begin
        Sym := InfDecodeSym(HLit);
        If InfErr Then Break;
        If Sym < 256 Then InfOutByte(Sym)
        Else If Sym = 256 Then Break
        Else Begin
         LenIdx  := Sym - 257;
         If LenIdx > 28 Then Begin InfErr := True; Break; End;
         MLen    := INF_LengthBase[LenIdx] +
           InfGetBits(INF_LengthExtra[LenIdx]);
         DistIdx := InfDecodeSym(HDist);
         If (DistIdx < 0) Or (DistIdx > 29) Then Begin InfErr := True; Break;
           End;
         MDist   := INF_DistBase[DistIdx] + InfGetBits(INF_DistExtra[DistIdx]);
         InfCopyMatch(MDist, MLen);
        End;
       End;
      End;
  Else
   InfErr := True;
  End;
 End;
 InflateBuf := Not InfErr;
End;

{ ----------------- DEFLATE encoder (stored) ---------------- }

Function DeflateStored(Src: Pointer; SrcSize: LongInt;
                       Var Dst: Pointer; Var DstSize: LongInt): Boolean;
Var
 BlocksNeeded, OutSize, Pos, ChunkLen: LongInt;
 PB, PS: ^Byte;
 LastBlock: Boolean;
 Hdr: Byte;
 W, NW: Word;
Begin
 If SrcSize < 0 Then Begin DeflateStored := False; Exit; End;
 BlocksNeeded := (SrcSize + 65534) Div 65535;
 If BlocksNeeded < 1 Then BlocksNeeded := 1;
 OutSize := SrcSize + 5 * BlocksNeeded;
 GetMem(Dst, OutSize);
 PB := Dst; PS := Src;
 Pos := 0;
 Repeat
  If SrcSize - Pos > 65535 Then ChunkLen := 65535
  Else                          ChunkLen := SrcSize - Pos;
  LastBlock := (Pos + ChunkLen >= SrcSize);
  If LastBlock Then Hdr := 1 Else Hdr := 0;
  PB^ := Hdr; Inc(PB);
  W  := Word(ChunkLen);
  NW := 65535 - W;
  PB^ := Byte(W And $FF);   Inc(PB);
  PB^ := Byte(W Shr 8);     Inc(PB);
  PB^ := Byte(NW And $FF);  Inc(PB);
  PB^ := Byte(NW Shr 8);    Inc(PB);
  If ChunkLen > 0 Then Begin
   Move(PS^, PB^, ChunkLen);
   Inc(PB, ChunkLen);
   Inc(PS, ChunkLen);
  End;
  Inc(Pos, ChunkLen);
 Until LastBlock;
 DstSize := OutSize;
 DeflateStored := True;
End;

{ -------------------- ZIP container ------------------------ }

Const
 MAX_ZIP_ENTRIES = 256;
 ZIP_SIG_LFH    = LongInt($04034B50);
 ZIP_SIG_CDH    = LongInt($02014B50);
 ZIP_SIG_EOCD   = LongInt($06054B50);

Type
 TZipEntry = Record
  Name       : String[80];
  Method     : Word;
  CRC32      : Cardinal;
  CompSize   : LongInt;
  UncompSize : LongInt;
  LFHOffset  : LongInt;
 End;

 TZipReader = Record
  F          : File;
  IsOpen     : Boolean;
  EntryCount : Integer;
  Entries    : Array[1..MAX_ZIP_ENTRIES] Of TZipEntry;
 End;

 TZipWriter = Record
  F          : File;
  IsOpen     : Boolean;
  EntryCount : Integer;
  Entries    : Array[1..MAX_ZIP_ENTRIES] Of TZipEntry;
 End;

Procedure ZipWriteWord(Var F: File; W: Word);
Begin BlockWrite(F, W, 2); End;

Procedure ZipWriteLong(Var F: File; L: LongInt);
Begin BlockWrite(F, L, 4); End;

Function ZipRead_Open(Var Z: TZipReader; Const FName: String): Boolean;
Var
 FileLen, ScanStart, ScanLen, EOCDPos: LongInt;
 Buf       : Array[0..4095] Of Byte;
 BufLen, I : LongInt;
 NEntries  : Word;
 CDOff, CDSize : LongInt;
 EntrySig, EntryCSize, EntryUSize, EntryLFHOff: LongInt;
 EntryCRC  : Cardinal;
 EntryMethod, EntryFlen, EntryExtra, EntryComment: Word;
 NameBuf   : Array[0..255] Of Byte;
 N, P      : Integer;
 Idx       : Integer;
Begin
 ZipRead_Open := False;
 Z.IsOpen := False; Z.EntryCount := 0;
 {$I-} Assign(Z.F, FName); Reset(Z.F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 FileLen := FileSize(Z.F);
 If FileLen < 22 Then Begin Close(Z.F); Exit; End;
 { Recherche EOCD dans les derniers 4096 octets (suffisant si pas de
   commentaire) }
 If FileLen > 4096 Then ScanStart := FileLen - 4096
 Else                   ScanStart := 0;
 ScanLen := FileLen - ScanStart;
 Seek(Z.F, ScanStart);
 BlockRead(Z.F, Buf, ScanLen, BufLen);
 If BufLen < 22 Then Begin Close(Z.F); Exit; End;
 EOCDPos := -1;
 For I := BufLen - 22 Downto 0 Do
  If (Buf[I]=$50) And (Buf[I+1]=$4B) And
     (Buf[I+2]=$05) And (Buf[I+3]=$06) Then Begin
   EOCDPos := ScanStart + I; Break;
  End;
 If EOCDPos < 0 Then Begin Close(Z.F); Exit; End;
 Seek(Z.F, EOCDPos + 10);
 BlockRead(Z.F, NEntries, 2);
 BlockRead(Z.F, CDSize, 4);
 BlockRead(Z.F, CDOff, 4);
 If NEntries > MAX_ZIP_ENTRIES Then Begin Close(Z.F); Exit; End;
 Z.EntryCount := NEntries;
 Seek(Z.F, CDOff);
 For Idx := 1 To NEntries Do Begin
  BlockRead(Z.F, EntrySig, 4);
  If EntrySig <> ZIP_SIG_CDH Then Begin Close(Z.F); Exit; End;
  Seek(Z.F, FilePos(Z.F) + 4); { version made + needed }
  Seek(Z.F, FilePos(Z.F) + 2); { flags }
  BlockRead(Z.F, EntryMethod, 2);
  Seek(Z.F, FilePos(Z.F) + 4); { time + date }
  BlockRead(Z.F, EntryCRC, 4);
  BlockRead(Z.F, EntryCSize, 4);
  BlockRead(Z.F, EntryUSize, 4);
  BlockRead(Z.F, EntryFlen, 2);
  BlockRead(Z.F, EntryExtra, 2);
  BlockRead(Z.F, EntryComment, 2);
  Seek(Z.F, FilePos(Z.F) + 8); { disk + internal + external attrs }
  BlockRead(Z.F, EntryLFHOff, 4);
  N := EntryFlen; If N > 255 Then N := 255;
  If N > 0 Then BlockRead(Z.F, NameBuf, N);
  If EntryFlen > N Then Seek(Z.F, FilePos(Z.F) + (EntryFlen - N));
  If N > 80 Then N := 80;
  Z.Entries[Idx].Name[0] := Char(N);
  For P := 1 To N Do Z.Entries[Idx].Name[P] := Char(NameBuf[P-1]);
  Z.Entries[Idx].Method := EntryMethod;
  Z.Entries[Idx].CRC32  := EntryCRC;
  Z.Entries[Idx].CompSize   := EntryCSize;
  Z.Entries[Idx].UncompSize := EntryUSize;
  Z.Entries[Idx].LFHOffset  := EntryLFHOff;
  Seek(Z.F, FilePos(Z.F) + EntryExtra + EntryComment);
 End;
 Z.IsOpen := True;
 ZipRead_Open := True;
End;

Function ZipRead_Find(Var Z: TZipReader; Const Name: String): Integer;
Var I: Integer;
Begin
 ZipRead_Find := -1;
 For I := 1 To Z.EntryCount Do
  If Z.Entries[I].Name = Name Then Begin
   ZipRead_Find := I; Exit;
  End;
End;

Function ZipRead_Extract(Var Z: TZipReader; Idx: Integer;
                          Var Buf: Pointer; Var Size: LongInt): Boolean;
Var
 FLen, ExtraLen, Method: Word;
 CompBuf: Pointer;
 CSize, USize: LongInt;
 OK: Boolean;
Begin
 ZipRead_Extract := False;
 Buf := Nil; Size := 0;
 If (Idx < 1) Or (Idx > Z.EntryCount) Or (Not Z.IsOpen) Then Exit;
 Method := Z.Entries[Idx].Method;
 CSize  := Z.Entries[Idx].CompSize;
 USize  := Z.Entries[Idx].UncompSize;
 Seek(Z.F, Z.Entries[Idx].LFHOffset + 26);
 BlockRead(Z.F, FLen, 2);
 BlockRead(Z.F, ExtraLen, 2);
 Seek(Z.F, Z.Entries[Idx].LFHOffset + 30 + FLen + ExtraLen);
 If Method = 0 Then Begin
  GetMem(Buf, USize);
  If USize > 0 Then BlockRead(Z.F, Buf^, USize);
  Size := USize;
  ZipRead_Extract := True;
 End
 Else If Method = 8 Then Begin
  If CSize <= 0 Then Begin
   GetMem(Buf, USize);
   Size := USize;
   ZipRead_Extract := True;
   Exit;
  End;
  GetMem(CompBuf, CSize);
  BlockRead(Z.F, CompBuf^, CSize);
  GetMem(Buf, USize);
  OK := InflateBuf(CompBuf, CSize, Buf, USize);
  FreeMem(CompBuf, CSize);
  If OK Then Begin
   Size := USize;
   ZipRead_Extract := True;
  End Else Begin
   FreeMem(Buf, USize);
   Buf := Nil;
  End;
 End;
End;

Procedure ZipRead_Close(Var Z: TZipReader);
Begin
 If Z.IsOpen Then Begin
  Close(Z.F);
  Z.IsOpen := False;
 End;
End;

Function ZipWrite_Create(Var Z: TZipWriter; Const FName: String): Boolean;
Begin
 Z.IsOpen := False; Z.EntryCount := 0;
 {$I-} Assign(Z.F, FName); Rewrite(Z.F, 1); {$I+}
 If IOResult <> 0 Then Begin ZipWrite_Create := False; Exit; End;
 Z.IsOpen := True;
 ZipWrite_Create := True;
End;

Function ZipWrite_AddStored(Var Z: TZipWriter; Const Name: String;
                              Buf: Pointer; Size: LongInt): Boolean;
Var
 LFHOff: LongInt;
 CRC: Cardinal;
 Idx: Integer;
Begin
 ZipWrite_AddStored := False;
 If (Not Z.IsOpen) Or (Z.EntryCount >= MAX_ZIP_ENTRIES) Then Exit;
 If Length(Name) > 80 Then Exit;
 LFHOff := FilePos(Z.F);
 CRC := CRC32Of(Buf, Size);
 ZipWriteLong(Z.F, ZIP_SIG_LFH);
 ZipWriteWord(Z.F, 20);    { version needed }
 ZipWriteWord(Z.F, 0);     { flags }
 ZipWriteWord(Z.F, 0);     { method = stored }
 ZipWriteWord(Z.F, 0);     { mod time }
 ZipWriteWord(Z.F, 33);    { mod date 1980-01-01 }
 ZipWriteLong(Z.F, LongInt(CRC));
 ZipWriteLong(Z.F, Size);
 ZipWriteLong(Z.F, Size);
 ZipWriteWord(Z.F, Length(Name));
 ZipWriteWord(Z.F, 0);     { extra len }
 If Length(Name) > 0 Then BlockWrite(Z.F, Name[1], Length(Name));
 If Size > 0 Then BlockWrite(Z.F, Buf^, Size);
 Inc(Z.EntryCount); Idx := Z.EntryCount;
 Z.Entries[Idx].Name       := Name;
 Z.Entries[Idx].Method     := 0;
 Z.Entries[Idx].CRC32      := CRC;
 Z.Entries[Idx].CompSize   := Size;
 Z.Entries[Idx].UncompSize := Size;
 Z.Entries[Idx].LFHOffset  := LFHOff;
 ZipWrite_AddStored := True;
End;

Function ZipWrite_AddDeflate(Var Z: TZipWriter; Const Name: String;
                               Buf: Pointer; Size: LongInt): Boolean;
Var
 LFHOff, CompSize: LongInt;
 Comp: Pointer;
 CRC: Cardinal;
 Idx: Integer;
Begin
 ZipWrite_AddDeflate := False;
 If (Not Z.IsOpen) Or (Z.EntryCount >= MAX_ZIP_ENTRIES) Then Exit;
 If Length(Name) > 80 Then Exit;
 If Not DeflateStored(Buf, Size, Comp, CompSize) Then Exit;
 LFHOff := FilePos(Z.F);
 CRC := CRC32Of(Buf, Size);
 ZipWriteLong(Z.F, ZIP_SIG_LFH);
 ZipWriteWord(Z.F, 20);
 ZipWriteWord(Z.F, 0);
 ZipWriteWord(Z.F, 8);     { method = deflate }
 ZipWriteWord(Z.F, 0);
 ZipWriteWord(Z.F, 33);
 ZipWriteLong(Z.F, LongInt(CRC));
 ZipWriteLong(Z.F, CompSize);
 ZipWriteLong(Z.F, Size);
 ZipWriteWord(Z.F, Length(Name));
 ZipWriteWord(Z.F, 0);
 If Length(Name) > 0 Then BlockWrite(Z.F, Name[1], Length(Name));
 If CompSize > 0 Then BlockWrite(Z.F, Comp^, CompSize);
 FreeMem(Comp, CompSize);
 Inc(Z.EntryCount); Idx := Z.EntryCount;
 Z.Entries[Idx].Name       := Name;
 Z.Entries[Idx].Method     := 8;
 Z.Entries[Idx].CRC32      := CRC;
 Z.Entries[Idx].CompSize   := CompSize;
 Z.Entries[Idx].UncompSize := Size;
 Z.Entries[Idx].LFHOffset  := LFHOff;
 ZipWrite_AddDeflate := True;
End;

Function ZipWrite_Finish(Var Z: TZipWriter): Boolean;
Var
 CDStart, CDEnd, CDSize: LongInt;
 I: Integer;
 NLen: Word;
Begin
 ZipWrite_Finish := False;
 If Not Z.IsOpen Then Exit;
 CDStart := FilePos(Z.F);
 For I := 1 To Z.EntryCount Do Begin
  ZipWriteLong(Z.F, ZIP_SIG_CDH);
  ZipWriteWord(Z.F, 20);                       { version made by }
  ZipWriteWord(Z.F, 20);                       { version needed }
  ZipWriteWord(Z.F, 0);                        { flags }
  ZipWriteWord(Z.F, Z.Entries[I].Method);
  ZipWriteWord(Z.F, 0);                        { mod time }
  ZipWriteWord(Z.F, 33);                       { mod date }
  ZipWriteLong(Z.F, LongInt(Z.Entries[I].CRC32));
  ZipWriteLong(Z.F, Z.Entries[I].CompSize);
  ZipWriteLong(Z.F, Z.Entries[I].UncompSize);
  NLen := Length(Z.Entries[I].Name);
  ZipWriteWord(Z.F, NLen);
  ZipWriteWord(Z.F, 0);                        { extra }
  ZipWriteWord(Z.F, 0);                        { comment }
  ZipWriteWord(Z.F, 0);                        { disk# }
  ZipWriteWord(Z.F, 0);                        { internal attrs }
  ZipWriteLong(Z.F, 0);                        { external attrs }
  ZipWriteLong(Z.F, Z.Entries[I].LFHOffset);
  If NLen > 0 Then BlockWrite(Z.F, Z.Entries[I].Name[1], NLen);
 End;
 CDEnd  := FilePos(Z.F);
 CDSize := CDEnd - CDStart;
 ZipWriteLong(Z.F, ZIP_SIG_EOCD);
 ZipWriteWord(Z.F, 0);
 ZipWriteWord(Z.F, 0);
 ZipWriteWord(Z.F, Z.EntryCount);
 ZipWriteWord(Z.F, Z.EntryCount);
 ZipWriteLong(Z.F, CDSize);
 ZipWriteLong(Z.F, CDStart);
 ZipWriteWord(Z.F, 0);
 {$I-} Close(Z.F); {$I+}
 Z.IsOpen := False;
 If IOResult <> 0 Then Exit;
 ZipWrite_Finish := True;
End;

{ ============================================================ }
{ ====================  INIT DOCUMENT  ======================= }
{ ============================================================ }

Procedure InitDocument;
Begin
 FreeAllDocImages;
 ResetTablePool;
 FillChar(Doc^, SizeOf(Doc^), 0);
 Doc^.ParaCount := 1;
 Doc^.PageCount := 1;
 Doc^.FileName  := 'Document1';
 Doc^.Modified  := False;
 Doc^.Paragraphs[1].RunCount := 1;
 Doc^.Paragraphs[1].Alignment := ALIGN_LEFT;
 Doc^.Paragraphs[1].Runs[1].Text := '';
 Doc^.Paragraphs[1].Runs[1].Style.FontSize := 12;
 Doc^.Paragraphs[1].Runs[1].Style.Style := 0;
 Doc^.Paragraphs[1].Runs[1].Style.Color := Black;

 CurrentStyle.FontSize := 12;
 CurrentStyle.Style    := 0;
 CurrentStyle.Color    := Black;
 CurrentAlign          := ALIGN_LEFT;
 CurrentPage           := 1;
 ScrollY               := 0;

 Cursor.ParaIdx := 1;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := 0;

 NeedsRelayout  := True;
 CursorBlinkOn  := True;
 CursorBlinkCnt := 0;
End;

Procedure DrawDocArea;
Var
 PageNum            : String;
 PX1, PY1, PX2, PY2 : Integer;
 P                  : Integer;
 YStart             : Integer;
Begin
 { Fond zone document }
 FillRectArea(0, DOCAREA_TOP, SCREEN_W-1, DOCAREA_BOTTOM, DOCAREA_BG);

 If Not PageLayoutView Then Begin
  FillRectArea(0,DOCAREA_TOP,SCREEN_W-1,DOCAREA_BOTTOM,PAGE_BG);
  RenderDocText;RenderSelection;RenderTextCursor;Exit;
 End;

 { Page centr??e horizontalement, position verticale d??pend de CurrentPage }
 PX1 := (SCREEN_W - PAGE_W) Div 2;
 YStart := DOCAREA_TOP + 8;

 For P := 1 To Doc^.PageCount Do Begin
  PY1 := YStart + (P-1) * (PAGE_H + 12) - ScrollY;
  PY2 := PY1 + PAGE_H;
  PX2 := PX1 + PAGE_W;

  { Skip si enti??rement hors zone }
  If (PY2 < DOCAREA_TOP) Or (PY1 > DocBottom) Then Continue;

  { Ombre droite et bas }
  ZoomFillRect(PX2+1, PY1+3, PX2+3, PY2+3, PAGE_SHADOW);
  ZoomFillRect(PX1+3, PY2+1, PX2+3, PY2+3, PAGE_SHADOW);

  { Page blanche }
  ZoomFillRect(PX1, PY1, PX2, PY2, PAGE_BG);
  ZoomFrameRect(PX1, PY1, PX2, PY2, PAGE_BORDER);

  { Marges en pointill??s discrets }
  SetColor(LightGray);
  If Doc^.PDFPageCount=0 Then ZoomRectangle(PX1+PAGE_MARGIN_L, PY1+PAGE_MARGIN_T,
            PX2-PAGE_MARGIN_R, PY2-PAGE_MARGIN_B);

  { En-tete DOCX (si charge depuis word/header*.xml) }
  If (Doc^.PDFPageCount=0) and (Length(DocxHeaderText)>0) Then Begin
   SetColor(DarkGray);
   ZoomOutTextXY(PX1 + PAGE_W Div 2 - TextWidth(DocxHeaderText) Div 2,
             PY1 + (PAGE_MARGIN_T Div 2) - 4, DocxHeaderText);
  End;

  { Num??ro de page en bas }
  SetColor(DarkGray);
  Str(P, PageNum);
  PageNum := Tr('Page ') + PageNum;
  If Doc^.PDFPageCount=0 Then
   ZoomOutTextXY(PX1 + PAGE_W Div 2 - TextWidth(PageNum) Div
     2,PY2-12,PageNum);

  { Pied de page DOCX (au-dessus du numero de page) }
  If (Doc^.PDFPageCount=0) and (Length(DocxFooterText)>0) Then Begin
   SetColor(DarkGray);
   ZoomOutTextXY(PX1 + PAGE_W Div 2 - TextWidth(DocxFooterText) Div 2,
             PY2 - 12 - 10, DocxFooterText);
  End;
 End;

 { ----- Texte du document + curseur ----- }
 RenderDocText;
 RenderSelection;
 RenderTextCursor;
End;

Procedure DrawZoomPan;
Var MaxPan,Thumb,TX,Y:Integer;
Begin
 MaxPan:=ZoomPanLimit;If MaxPan=0 Then Exit;
 Y:=DOCAREA_BOTTOM-11;
 FillRectArea(0,Y,SCREEN_W-1,DOCAREA_BOTTOM,LightGray);
 DrawFrameRect(0,Y,SCREEN_W-1,DOCAREA_BOTTOM,DarkGray);
 Thumb:=60;TX:=20+(LongInt(ZoomPanX+MaxPan)*(SCREEN_W-40-Thumb)) div (2*MaxPan);
 FillRectArea(TX,Y+1,TX+Thumb,Y+10,DarkGray);
 DrawTextAt(4,Y+2,'<',Black);DrawTextAt(SCREEN_W-12,Y+2,'>',Black);
End;

Procedure DrawStatusBar;
Var
 PageStr  : String[40];
 LineColS : String[40];
 SP, SC   : String[12];
 SL, SCo  : String[12];
 L, Col, X: Integer;
Begin
 FillRectArea(0, STATUSBAR_TOP, SCREEN_W-1,
              STATUSBAR_TOP+STATUSBAR_HEIGHT-1, STATUSBAR_BG);
 DrawHLine(0, SCREEN_W-1, STATUSBAR_TOP, CLR_3D_LIGHT);

 Str(CurrentPage, SP);
 Str(Doc^.PageCount, SC);
 PageStr := Tr('Page ') + SP + Tr(' of ') + SC;
 DrawTextAt(8, STATUSBAR_TOP+5, PageStr, STATUSBAR_FG);
 { OS/2-0 : les textes ne se chevauchent pas (Page 1 sur 1, Lig 1 Col 1) }
 X := 96; If 8 + TextWidth(PageStr) + 16 > X Then X := 8 + TextWidth(PageStr) + 16;
 { titre de la fenetre : nom du document }
 If Doc^.FileName = '' Then OsSetTitle('WorDium - ' + Tr('Sans titre'))
 Else OsSetTitle('WorDium - ' + Doc^.FileName);

 L := FindCursorVLine;
 If L > 0 Then Begin
  Col := Cursor.CharIdx - (VLines[L].CharStart - 1) + 1;
  Str(L, SL);
  Str(Col, SCo);
  LineColS := Tr('Ln ') + SL + Tr('  Col ') + SCo;
  DrawTextAt(X, STATUSBAR_TOP+5, LineColS, STATUSBAR_FG);
  X := X + TextWidth(LineColS) + 16;
 End;

 If X < 220 Then X := 220;
 { le message s'arrete avant le zoom }
 DrawTextAt(X, STATUSBAR_TOP+5, Copy(StatusMsg, 1, (SCREEN_W - 125 - 8 - X) Div 8), STATUSBAR_FG);

 Str(ZoomValue,SP);DrawTextAt(SCREEN_W-125,STATUSBAR_TOP+5,SP+' %',
   STATUSBAR_FG);
 If Doc^.Modified Then
  DrawTextAt(SCREEN_W-50, STATUSBAR_TOP+5, '[MOD]', Red);
End;

{ ============================================================ }
{ =====================  GESTION ACTIONS  ==================== }
{ ============================================================ }

{ ============================================================ }
{ ===================  PHASE 5 - I/O WPD  ==================== }
{ ============================================================ }
{ Format binaire .WPD :                                         }
{   Offset  Taille  Contenu                                     }
{   0       6       Magic 'WPDOC1'                              }
{   6       2       Version (Word LE) = 1                       }
{   8       2       ParaCount (Word LE)                         }
{   Pour chaque paragraphe :                                    }
{     1     Alignment (Byte)                                    }
{     1     PageBreakBefore (0/1)                               }
{     1     RunCount (Byte)                                     }
{     Pour chaque run :                                         }
{       1   FontSize / 1 Style / 1 Color / 1 TextLen (Byte)     }
{       N   Text (TextLen octets)                               }
{ ============================================================ }

Procedure EnsureWPDExt(Var FN: String);
Var I, DotPos : Integer;
Begin
 DotPos := 0;
 For I := Length(FN) Downto 1 Do
  If FN[I] = '.' Then Begin DotPos := I; Break; End;
 If DotPos = 0 Then FN := FN + '.WPD';
End;

Function SaveDocumentToFile(Const FName: String): Boolean;
Var
 F          : File;
 P, R       : Integer;
 B, RunCnt  : Byte;
 TextLen    : Byte;
 W          : Word;
 Magic      : Array[1..6] Of Char;
 OK         : Boolean;
 S          : String;
 ImgBytes   : LongInt;
Begin
 OK := True;
 Magic[1]:='W'; Magic[2]:='P'; Magic[3]:='D';
 Magic[4]:='O'; Magic[5]:='C'; Magic[6]:='1';
 {$I-} Assign(F, FName); Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin SaveDocumentToFile := False; Exit; End;
 BlockWrite(F, Magic, 6);
 W := 4;             BlockWrite(F, W, 2);
   { version 4 adds paragraph formatting }
 W := Doc^.ParaCount; BlockWrite(F, W, 2);
 W:=Doc^.PDFPageCount;BlockWrite(F,W,2);W:=Doc^.PDFGraphicCount;BlockWrite(F,W,2);
 For P:=1 To Doc^.PDFGraphicCount Do
   BlockWrite(F,Doc^.PDFGraphics[P],SizeOf(TPDFGraphic));
 For P := 1 To Doc^.ParaCount Do Begin
  BlockWrite(F,Doc^.Paragraphs[P].PDF,SizeOf(TPDFPlacement));
  W:=Doc^.Paragraphs[P].LeftIndent; BlockWrite(F,W,2);
  B:=Ord(Doc^.Paragraphs[P].FirstLineHang)+2*Ord(Doc^.Paragraphs[P].BorderBottom);
  BlockWrite(F,B,1);
  B := Doc^.Paragraphs[P].Alignment;                BlockWrite(F, B, 1);
  If Doc^.Paragraphs[P].PageBreakBefore Then B:=1 Else B:=0;
  BlockWrite(F, B, 1);
  If Doc^.Paragraphs[P].IsImage Then B:=1 Else B:=0;
  BlockWrite(F, B, 1);
  If Doc^.Paragraphs[P].IsImage Then Begin
   W := Doc^.Paragraphs[P].ImgW; BlockWrite(F, W, 2);
   W := Doc^.Paragraphs[P].ImgH; BlockWrite(F, W, 2);
   ImgBytes := LongInt(Doc^.Paragraphs[P].ImgW) * Doc^.Paragraphs[P].ImgH;
   If (ImgBytes > 0) And (Doc^.Paragraphs[P].ImgData <> Nil) Then
    BlockWrite(F, Doc^.Paragraphs[P].ImgData^, ImgBytes);
   Continue;
  End;
  RunCnt := Doc^.Paragraphs[P].RunCount;            BlockWrite(F, RunCnt, 1);
  For R := 1 To Doc^.Paragraphs[P].RunCount Do Begin
   B := Doc^.Paragraphs[P].Runs[R].Style.FontSize;  BlockWrite(F, B, 1);
   B := Doc^.Paragraphs[P].Runs[R].Style.Style;     BlockWrite(F, B, 1);
   B := Doc^.Paragraphs[P].Runs[R].Style.Color;     BlockWrite(F, B, 1);
   S := Doc^.Paragraphs[P].Runs[R].Text;
   TextLen := Length(S);                           BlockWrite(F, TextLen, 1);
   If TextLen > 0 Then BlockWrite(F, S[1], TextLen);
  End;
 End;
 {$I-} Close(F); {$I+}
 If IOResult <> 0 Then OK := False;
 SaveDocumentToFile := OK;
End;

Function LoadDocumentFromFile(Const FName: String): Boolean;
Var
 F        : File;
 Magic    : Array[1..6] Of Char;
 V, PCnt, PDFPages, PDFGfx, W: Word;
 P, R, I  : Integer;
 B, RunCnt: Byte;
 TextLen  : Byte;
 Buf      : Array[0..255] Of Byte;
 S        : String;
 IsImg    : Byte;
 IW, IH   : Word;
 ImgBytes : LongInt;
 ImgPtr   : Pointer;
Begin
 {$I-} Assign(F, FName); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Begin LoadDocumentFromFile := False; Exit; End;
 BlockRead(F, Magic, 6);
 If (Magic[1]<>'W') Or (Magic[2]<>'P') Or (Magic[3]<>'D') Or
    (Magic[4]<>'O') Or (Magic[5]<>'C') Or (Magic[6]<>'1') Then Begin
  Close(F); LoadDocumentFromFile := False; Exit;
 End;
 BlockRead(F, V, 2);
 BlockRead(F, PCnt, 2);
 If (PCnt < 1) Or (PCnt > MAX_PARAS_PER_DOC) Then Begin
  Close(F); LoadDocumentFromFile := False; Exit;
 End;
 FreeAllDocImages;
 FillChar(Doc^, SizeOf(Doc^), 0);
 Doc^.ParaCount := PCnt;
 Doc^.PageCount := 1;
 If V>=3 Then Begin
  BlockRead(F,PDFPages,2);BlockRead(F,PDFGfx,2);
  If (PDFPages>MAX_PAGES) or (PDFGfx>2048) Then Begin
    Close(F);LoadDocumentFromFile:=False;Exit;End;
  Doc^.PDFPageCount:=PDFPages;Doc^.PDFGraphicCount:=PDFGfx;
  For P:=1 To PDFGfx Do BlockRead(F,Doc^.PDFGraphics[P],SizeOf(TPDFGraphic));
 End;
 For P := 1 To PCnt Do Begin
  If V>=3 Then BlockRead(F,Doc^.Paragraphs[P].PDF,SizeOf(TPDFPlacement));
  If V>=4 Then Begin
   BlockRead(F,W,2);
   If W>160 Then W:=160;
   Doc^.Paragraphs[P].LeftIndent:=W;
   BlockRead(F,B,1);
   Doc^.Paragraphs[P].FirstLineHang:=(B and 1)<>0;
   Doc^.Paragraphs[P].BorderBottom:=(B and 2)<>0;
  End;
  BlockRead(F, B, 1); Doc^.Paragraphs[P].Alignment      := B;
  BlockRead(F, B, 1); Doc^.Paragraphs[P].PageBreakBefore:= B <> 0;
  IsImg := 0;
  If V >= 2 Then BlockRead(F, IsImg, 1);
  If IsImg <> 0 Then Begin
   BlockRead(F, IW, 2); BlockRead(F, IH, 2);
   If (IW = 0) Or (IH = 0) Or (IW > MAX_IMG_W) Or (IH > MAX_IMG_H) Then Begin
    Close(F); LoadDocumentFromFile := False; Exit;
   End;
   ImgBytes := LongInt(IW) * IH;
   GetMem(ImgPtr, ImgBytes);
   BlockRead(F, ImgPtr^, ImgBytes);
   Doc^.Paragraphs[P].IsImage := True;
   Doc^.Paragraphs[P].ImgW    := IW;
   Doc^.Paragraphs[P].ImgH    := IH;
   Doc^.Paragraphs[P].ImgData := ImgPtr;
   Doc^.Paragraphs[P].RunCount := 0;
   Continue;
  End;
  BlockRead(F, RunCnt, 1);
  If RunCnt > MAX_RUNS_PER_PARA Then RunCnt := MAX_RUNS_PER_PARA;
  Doc^.Paragraphs[P].RunCount := RunCnt;
  For R := 1 To RunCnt Do Begin
   BlockRead(F, B, 1); Doc^.Paragraphs[P].Runs[R].Style.FontSize := B;
   BlockRead(F, B, 1); Doc^.Paragraphs[P].Runs[R].Style.Style    := B;
   BlockRead(F, B, 1); Doc^.Paragraphs[P].Runs[R].Style.Color    := B;
   BlockRead(F, TextLen, 1);
   S := '';
   If TextLen > 0 Then Begin
    BlockRead(F, Buf, TextLen);
    If TextLen > MAX_TEXT_LEN Then TextLen := MAX_TEXT_LEN;
    S[0] := Char(TextLen);
    For I := 1 To TextLen Do S[I] := Char(Buf[I-1]);
   End;
   Doc^.Paragraphs[P].Runs[R].Text := S;
  End;
 End;
 Close(F);
 Doc^.FileName   := FName;
 Doc^.Modified   := False;
 Cursor.ParaIdx := 1;
 Cursor.RunIdx  := 1;
 Cursor.CharIdx := 0;
 ScrollY        := 0;
 CurrentPage    := 1;
 NeedsRelayout  := True;
 LoadDocumentFromFile := True;
End;

{ ============================================================ }
{ ===================  PHASE 8 - DOCX I/O  =================== }
{ ============================================================ }
{ DOCX = ZIP contenant au minimum :                             }
{   [Content_Types].xml                                         }
{   _rels/.rels                                                 }
{   word/document.xml  (le seul reellement parse)               }
{                                                               }
{ Mapping :                                                     }
{  <w:p><w:pPr><w:jc w:val="left|center|right|both"/>           }
{    <w:pageBreakBefore/></w:pPr>                               }
{   <w:r><w:rPr><w:b/><w:i/><w:u w:val="single"/>               }
{       <w:sz w:val="N"/></w:rPr>                               }
{    <w:t xml:space="preserve">texte</w:t></w:r>                }
{   <w:r><w:br w:type="page"/></w:r>  --> PageBreakBefore       }
{                       sur le paragraphe suivant.              }
{  </w:p>                                                       }
{ Les images ne sont pas exportees (paragraphes images = vides).}
{ ============================================================ }

Type
 TByteBuf = Record
  Data : Pointer;
  Size : LongInt;
  Cap  : LongInt;
 End;

Procedure BufInit(Var B: TByteBuf);
Begin
 B.Data := Nil; B.Size := 0; B.Cap := 0;
End;

Procedure BufFree(Var B: TByteBuf);
Begin
 If B.Data <> Nil Then FreeMem(B.Data, B.Cap);
 B.Data := Nil; B.Size := 0; B.Cap := 0;
End;

Procedure BufEnsure(Var B: TByteBuf; Need: LongInt);
Var
 NewCap : LongInt;
 NewPtr : Pointer;
 Dst    : ^Byte;
Begin
 If Need <= B.Cap Then Exit;
 NewCap := B.Cap;
 If NewCap < 512 Then NewCap := 512;
 While NewCap < Need Do NewCap := NewCap * 2;
 GetMem(NewPtr, NewCap);
 If (B.Data <> Nil) And (B.Size > 0) Then Begin
  Dst := NewPtr;
  Move(B.Data^, Dst^, B.Size);
 End;
 If B.Data <> Nil Then FreeMem(B.Data, B.Cap);
 B.Data := NewPtr; B.Cap := NewCap;
End;

Procedure BufAppendBytes(Var B: TByteBuf; P: Pointer; N: LongInt);
Var Dst: ^Byte;
Begin
 If N <= 0 Then Exit;
 BufEnsure(B, B.Size + N);
 Dst := B.Data; Inc(Dst, B.Size);
 Move(P^, Dst^, N);
 Inc(B.Size, N);
End;

Procedure BufAppendStr(Var B: TByteBuf; Const S: String);
Begin
 If Length(S) > 0 Then BufAppendBytes(B, @S[1], Length(S));
End;

Function Cp437ToUni(B: Byte): Word; Forward;

Procedure BufAppendXmlText(Var B: TByteBuf; Const S: String);
Var I: Integer; C: Char; Tmp: Byte; W: Word; B0,B1,B2: Byte;
Begin
 For I := 1 To Length(S) Do Begin
  C := S[I];
  Case C Of
   '&': BufAppendStr(B, '&amp;');
   '<': BufAppendStr(B, '&lt;');
   '>': BufAppendStr(B, '&gt;');
   '"': BufAppendStr(B, '&quot;');
   #39: BufAppendStr(B, '&apos;');
  Else
   Tmp := Byte(C);
   If Tmp < $80 Then BufAppendBytes(B, @Tmp, 1)
   Else Begin
    W := Cp437ToUni(Tmp);
    If W < $0800 Then Begin
     B0 := $C0 Or Byte(W Shr 6);
     B1 := $80 Or Byte(W And $3F);
     BufAppendBytes(B, @B0, 1); BufAppendBytes(B, @B1, 1);
    End Else Begin
     B0 := $E0 Or Byte(W Shr 12);
     B1 := $80 Or Byte((W Shr 6) And $3F);
     B2 := $80 Or Byte(W And $3F);
     BufAppendBytes(B, @B0, 1); BufAppendBytes(B, @B1, 1);
     BufAppendBytes(B, @B2, 1);
    End;
   End;
  End;
 End;
End;

{ ---------- Lexer XML minimal (sur buffer) ---------- }

Const
 DTK_EOF   = 0;
 DTK_TEXT  = 1;
 DTK_START = 2;
 DTK_END   = 3;
 DTK_EMPTY = 4;

Var
 DocxBuf  : Pointer;
 DocxPos  : LongInt;
 DocxSize : LongInt;
 TokKind  : Integer;
 TokName  : String;
 TokAttrs : String;
 TokText  : String;

Function DocxByte(Pos: LongInt): Byte;
Var P: ^Byte;
Begin
 P := DocxBuf; Inc(P, Pos); DocxByte := P^;
End;

Function DocxDecodeEntity(Const E: String): String;
Begin
 If      E = 'amp'  Then DocxDecodeEntity := '&'
 Else If E = 'lt'   Then DocxDecodeEntity := '<'
 Else If E = 'gt'   Then DocxDecodeEntity := '>'
 Else If E = 'quot' Then DocxDecodeEntity := '"'
 Else If E = 'apos' Then DocxDecodeEntity := #39
 Else DocxDecodeEntity := '';
End;

Function DocxDecodeText(Const S: String): String;
Var I, J: Integer; R, E, Dec1: String;
Begin
 R := ''; I := 1;
 While I <= Length(S) Do Begin
  If S[I] = '&' Then Begin
   J := I + 1; E := '';
   While (J <= Length(S)) And (S[J] <> ';') And (Length(E) < 8) Do Begin
    E := E + S[J]; Inc(J);
   End;
   If (J <= Length(S)) And (S[J] = ';') Then Begin
    Dec1 := DocxDecodeEntity(E);
    If (Length(R) + Length(Dec1)) <= 255 Then R := R + Dec1;
    I := J + 1;
   End Else Begin
    If Length(R) < 255 Then R := R + '&';
    Inc(I);
   End;
  End Else Begin
   If Length(R) < 255 Then R := R + S[I];
   Inc(I);
  End;
 End;
 DocxDecodeText := R;
End;

Procedure DocxNextToken;
Var
 Ch      : Char;
 First, I: LongInt;
 Tag     : String;
 HasSlash: Boolean;
 K       : Integer;
Begin
 TokKind := DTK_EOF; TokName := ''; TokAttrs := ''; TokText := '';
 If DocxPos >= DocxSize Then Exit;
 Ch := Char(DocxByte(DocxPos));
 If Ch = '<' Then Begin
  Inc(DocxPos);
  If DocxPos >= DocxSize Then Exit;
  Ch := Char(DocxByte(DocxPos));
  { <?xml ... ?> : skip jusqu'a ?> }
  If Ch = '?' Then Begin
   While DocxPos + 1 < DocxSize Do Begin
    If (DocxByte(DocxPos) = Byte('?')) And (DocxByte(DocxPos+1) = Byte('>'))
      Then Begin
     Inc(DocxPos, 2); Break;
    End;
    Inc(DocxPos);
   End;
   DocxNextToken; Exit;
  End;
  { <!-- --> ou <![CDATA[ ]]> ou <!DOCTYPE ...> }
  If Ch = '!' Then Begin
   If (DocxPos+2 < DocxSize) And
      (DocxByte(DocxPos+1) = Byte('-')) And
      (DocxByte(DocxPos+2) = Byte('-')) Then Begin
    Inc(DocxPos, 3);
    While DocxPos + 2 < DocxSize Do Begin
     If (DocxByte(DocxPos) = Byte('-')) And
        (DocxByte(DocxPos+1) = Byte('-')) And
        (DocxByte(DocxPos+2) = Byte('>')) Then Begin
      Inc(DocxPos, 3); Break;
     End;
     Inc(DocxPos);
    End;
   End Else If (DocxPos+7 < DocxSize) And (DocxByte(DocxPos+1) = Byte('[')) Then
     Begin
    Inc(DocxPos, 8);  { sauter ![CDATA[ }
    First := DocxPos;
    While DocxPos + 2 < DocxSize Do Begin
     If (DocxByte(DocxPos) = Byte(']')) And
        (DocxByte(DocxPos+1) = Byte(']')) And
        (DocxByte(DocxPos+2) = Byte('>')) Then Begin
      Tag := '';
      For I := First To DocxPos - 1 Do
       If Length(Tag) < 240 Then Tag := Tag + Char(DocxByte(I));
      Inc(DocxPos, 3);
      TokKind := DTK_TEXT; TokText := Tag;
      Exit;
     End;
     Inc(DocxPos);
    End;
   End Else Begin
    While (DocxPos < DocxSize) And (DocxByte(DocxPos) <> Byte('>')) Do
      Inc(DocxPos);
    If DocxPos < DocxSize Then Inc(DocxPos);
   End;
   DocxNextToken; Exit;
  End;
  { </name> }
  If Ch = '/' Then Begin
   Inc(DocxPos);
   Tag := '';
   While (DocxPos < DocxSize) And (DocxByte(DocxPos) <> Byte('>')) Do Begin
    If Length(Tag) < 240 Then Tag := Tag + Char(DocxByte(DocxPos));
    Inc(DocxPos);
   End;
   If DocxPos < DocxSize Then Inc(DocxPos);
   While (Length(Tag) > 0) And
         ((Tag[Length(Tag)] = ' ') Or (Tag[Length(Tag)] = #9) Or
          (Tag[Length(Tag)] = #10) Or (Tag[Length(Tag)] = #13)) Do
    Dec(Tag[0]);
   TokKind := DTK_END; TokName := Tag; Exit;
  End;
  { Start ou empty }
  Tag := '';
  While (DocxPos < DocxSize) And (DocxByte(DocxPos) <> Byte('>')) Do Begin
   If Length(Tag) < 240 Then Tag := Tag + Char(DocxByte(DocxPos));
   Inc(DocxPos);
  End;
  If DocxPos < DocxSize Then Inc(DocxPos);
  HasSlash := False;
  If (Length(Tag) > 0) And (Tag[Length(Tag)] = '/') Then Begin
   HasSlash := True; Dec(Tag[0]);
   While (Length(Tag) > 0) And
         ((Tag[Length(Tag)] = ' ') Or (Tag[Length(Tag)] = #9)) Do
    Dec(Tag[0]);
  End;
  K := 1;
  While (K <= Length(Tag)) And (Tag[K] <> ' ') And (Tag[K] <> #9) And
        (Tag[K] <> #10) And (Tag[K] <> #13) Do Inc(K);
  TokName := Copy(Tag, 1, K - 1);
  If K <= Length(Tag) Then TokAttrs := Copy(Tag, K + 1,
    255) Else TokAttrs := '';
  If HasSlash Then TokKind := DTK_EMPTY Else TokKind := DTK_START;
  Exit;
 End Else Begin
  { Texte jusqu'au prochain < }
  First := DocxPos;
  While (DocxPos < DocxSize) And (DocxByte(DocxPos) <> Byte('<')) Do
    Inc(DocxPos);
  Tag := '';
  For I := First To DocxPos - 1 Do
   If Length(Tag) < 240 Then Tag := Tag + Char(DocxByte(I));
  TokKind := DTK_TEXT;
  TokText := DocxDecodeText(Tag);
 End;
End;

Function DocxGetAttr(Const Attrs, Name: String): String;
Var I, J, K, NLen: Integer; OK: Boolean; Q: Char;
Begin
 DocxGetAttr := ''; NLen := Length(Name);
 If NLen = 0 Then Exit;
 I := 1;
 While I + NLen <= Length(Attrs) + 1 Do Begin
  OK := True;
  If I > 1 Then Begin
   Q := Attrs[I-1];
   If (Q <> ' ') And (Q <> #9) And (Q <> #10) And (Q <> #13) Then OK := False;
  End;
  If OK Then
   For K := 1 To NLen Do
    If Attrs[I+K-1] <> Name[K] Then Begin OK := False; Break; End;
  If OK Then Begin
   J := I + NLen;
   If (J <= Length(Attrs)) And (Attrs[J] = '=') Then Begin
    Inc(J);
    If (J <= Length(Attrs)) And ((Attrs[J] = '"') Or (Attrs[J] = #39)) Then
      Begin
     Q := Attrs[J]; Inc(J); K := J;
     While (K <= Length(Attrs)) And (Attrs[K] <> Q) Do Inc(K);
     DocxGetAttr := DocxDecodeText(Copy(Attrs, J, K - J));
     Exit;
    End;
   End;
  End;
  Inc(I);
 End;
End;

{ ---------- DOCX writer ---------- }

Var
 DocxImgOut : Integer;     { nombre d'images ecrites dans document.xml }

{ Image du document -> BMP 24 bits (palette EGA 16 couleurs) }
Procedure DocxBuildBmp(Var B: TByteBuf; P: Integer);
Const
 Pal: Array[0..15, 0..2] Of Byte = (
  (0,0,0),(0,0,170),(0,170,0),(0,170,170),
  (170,0,0),(170,0,170),(170,85,0),(170,170,170),
  (85,85,85),(85,85,255),(85,255,85),(85,255,255),
  (255,85,85),(255,85,255),(255,255,85),(255,255,255));
Var
 Hd  : Array[0..53] Of Byte;
 Row : Array[0..1535] Of Byte;
 W, H, RB, X, Y : Integer;
 Sz  : LongInt;
 Src : ^Byte;
 V   : Byte;
 Base: Pointer;
 Procedure Put32(Off: Integer; N: LongInt);
 Var K: Integer;
 Begin
  For K := 0 To 3 Do Hd[Off + K] := (N Shr (8 * K)) And 255;
 End;
Begin
 W := Doc^.Paragraphs[P].ImgW;
 H := Doc^.Paragraphs[P].ImgH;
 If W > 500 Then W := 500;
 RB := ((W * 3 + 3) Div 4) * 4;
 Sz := LongInt(RB) * H;
 FillChar(Hd, SizeOf(Hd), 0);
 Hd[0] := 66; Hd[1] := 77;
 Put32(2, 54 + Sz); Put32(10, 54); Put32(14, 40);
 Put32(18, W); Put32(22, H);
 Hd[26] := 1; Hd[28] := 24;
 Put32(34, Sz); Put32(38, 2835); Put32(42, 2835);
 BufAppendBytes(B, @Hd, 54);
 Base := Doc^.Paragraphs[P].ImgData;
 For Y := H - 1 Downto 0 Do Begin
  FillChar(Row, SizeOf(Row), 0);
  Src := Base; Inc(Src, LongInt(Y) * Doc^.Paragraphs[P].ImgW);
  For X := 0 To W - 1 Do Begin
   V := Src^ And 15; Inc(Src);
   Row[X * 3]     := Pal[V, 2];
   Row[X * 3 + 1] := Pal[V, 1];
   Row[X * 3 + 2] := Pal[V, 0];
  End;
  BufAppendBytes(B, @Row, RB);
 End;
End;

Procedure DocxAppendImagePara(Var B: TByteBuf; P: Integer);
Var N, CX, CY, Al: String;
Begin
 Inc(DocxImgOut);
 Str(DocxImgOut, N);
 Str(LongInt(Doc^.Paragraphs[P].ImgW) * 9525, CX);
 Str(LongInt(Doc^.Paragraphs[P].ImgH) * 9525, CY);
 Case Doc^.Paragraphs[P].Alignment Of
  ALIGN_CENTER : Al := 'center';
  ALIGN_RIGHT  : Al := 'right';
 Else Al := 'left';
 End;
 BufAppendStr(B, '<w:p><w:pPr><w:jc w:val="' + Al + '"/></w:pPr><w:r>');
 BufAppendStr(B, '<w:drawing><wp:inline distT="0" distB="0" distL="0" ' +
   'distR="0"><wp:extent cx="' + CX + '" cy="' + CY + '"/>');
 BufAppendStr(B, '<wp:docPr id="' + N + '" name="Image ' + N + '"/>');
 BufAppendStr(B, '<a:graphic xmlns:a="http://schemas.openxmlformats.org/' +
   'drawingml/2006/main"><a:graphicData uri="http://schemas.openxmlformats.' +
   'org/drawingml/2006/picture">');
 BufAppendStr(B, '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/' +
   'drawingml/2006/picture"><pic:nvPicPr><pic:cNvPr id="' + N +
   '" name="image' + N + '.bmp"/><pic:cNvPicPr/></pic:nvPicPr>');
 BufAppendStr(B, '<pic:blipFill><a:blip r:embed="rIdImg' + N + '"/>' +
   '<a:stretch><a:fillRect/></a:stretch></pic:blipFill>');
 BufAppendStr(B, '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="' + CX +
   '" cy="' + CY + '"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/>' +
   '</a:prstGeom></pic:spPr></pic:pic>');
 BufAppendStr(B, '</a:graphicData></a:graphic></wp:inline></w:drawing>' +
   '</w:r></w:p>');
End;

Procedure DocxBuildDocRels(Var B: TByteBuf; N: Integer);
Var I: Integer; S: String;
Begin
 BufInit(B);
 BufAppendStr(B, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 BufAppendStr(B, '<Relationships xmlns="http://schemas.openxmlformats.org/' +
   'package/2006/relationships">');
 For I := 1 To N Do Begin
  Str(I, S);
  BufAppendStr(B, '<Relationship Id="rIdImg' + S + '" Type="http://schemas.' +
    'openxmlformats.org/officeDocument/2006/relationships/image" ' +
    'Target="media/image' + S + '.bmp"/>');
 End;
 BufAppendStr(B, '</Relationships>');
End;

Procedure DocxBuildContentTypes(Var B: TByteBuf);
Begin
 BufInit(B);
 BufAppendStr(B, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 BufAppendStr(B,
   '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-type'+
   's">');
 BufAppendStr(B, '<Default Extension="rels" ContentType=');
 BufAppendStr(B,
   '"application/vnd.openxmlformats-package.relationships+xml"/>');
 BufAppendStr(B, '<Default Extension="xml" ContentType="application/xml"/>');
 BufAppendStr(B, '<Default Extension="bmp" ContentType="image/bmp"/>');
 BufAppendStr(B, '<Override PartName="/word/document.xml" ContentType=');
 BufAppendStr(B,
   '"application/vnd.openxmlformats-officedocument.wordprocessingml.document.'+
   'main+xml"/>');
 BufAppendStr(B, '</Types>');
End;

Procedure DocxBuildRels(Var B: TByteBuf);
Begin
 BufInit(B);
 BufAppendStr(B, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 BufAppendStr(B,
   '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/rela'+
   'tionships">');
 BufAppendStr(B, '<Relationship Id="rId1" Type=');
 BufAppendStr(B,
   '"http://schemas.openxmlformats.org/officeDocument/2006/relationships/offi'+
   'ceDocument"');
 BufAppendStr(B, ' Target="word/document.xml"/>');
 BufAppendStr(B, '</Relationships>');
End;

Procedure DocxBuildDocument(Var B: TByteBuf);
Var
 P, R     : Integer;
 AlignStr : String;
 Sty      : Byte;
 SzHP     : Integer;
 NumStr   : String;
Begin
 BufInit(B);
 BufAppendStr(B, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 BufAppendStr(B, '<w:document xmlns:w=');
 BufAppendStr(B,
   '"http://schemas.openxmlformats.org/wordprocessingml/2006/main"');
 BufAppendStr(B, ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/' +
   '2006/relationships"');
 BufAppendStr(B, ' xmlns:wp="http://schemas.openxmlformats.org/drawingml/' +
   '2006/wordprocessingDrawing">');
 BufAppendStr(B, '<w:body>');
 DocxImgOut := 0;
 For P := 1 To Doc^.ParaCount Do Begin
  If Doc^.Paragraphs[P].IsImage Then Begin
   If Doc^.Paragraphs[P].ImgData <> Nil Then
    DocxAppendImagePara(B, P)
   Else
    BufAppendStr(B, '<w:p/>');
   Continue;
  End;
  BufAppendStr(B, '<w:p><w:pPr>');
  Case Doc^.Paragraphs[P].Alignment Of
   ALIGN_CENTER : AlignStr := 'center';
   ALIGN_RIGHT  : AlignStr := 'right';
   ALIGN_JUSTIFY: AlignStr := 'both';
  Else AlignStr := '';
  End;
  If AlignStr <> '' Then Begin
   BufAppendStr(B, '<w:jc w:val="');
   BufAppendStr(B, AlignStr);
   BufAppendStr(B, '"/>');
  End;
  If Doc^.Paragraphs[P].PageBreakBefore Then
   BufAppendStr(B, '<w:pageBreakBefore/>');
  If Doc^.Paragraphs[P].BorderBottom Then
   BufAppendStr(B, '<w:pBdr><w:bottom w:val="single" w:sz="4"/></w:pBdr>');
  If Doc^.Paragraphs[P].LeftIndent>0 Then Begin
   Str(LongInt(Doc^.Paragraphs[P].LeftIndent)*15,AlignStr);
   BufAppendStr(B, '<w:ind w:left="'+AlignStr+'"');
   If Not Doc^.Paragraphs[P].FirstLineHang Then
    BufAppendStr(B, ' w:hanging="'+AlignStr+'"');
   BufAppendStr(B, '/>');
  End;
  BufAppendStr(B, '</w:pPr>');
  For R := 1 To Doc^.Paragraphs[P].RunCount Do Begin
   BufAppendStr(B, '<w:r><w:rPr>');
   Sty := Doc^.Paragraphs[P].Runs[R].Style.Style;
   If (Sty And STY_BOLD)      <> 0 Then BufAppendStr(B, '<w:b/>');
   If (Sty And STY_ITALIC)    <> 0 Then BufAppendStr(B, '<w:i/>');
   If (Sty And STY_UNDERLINE) <> 0 Then BufAppendStr(B,
     '<w:u w:val="single"/>');
   SzHP := Doc^.Paragraphs[P].Runs[R].Style.FontSize * 2;
   If SzHP < 4 Then SzHP := 24;
   Str(SzHP, NumStr);
   BufAppendStr(B, '<w:sz w:val="');
   BufAppendStr(B, NumStr);
   BufAppendStr(B, '"/></w:rPr>');
   BufAppendStr(B, '<w:t xml:space="preserve">');
   BufAppendXmlText(B, Doc^.Paragraphs[P].Runs[R].Text);
   BufAppendStr(B, '</w:t></w:r>');
  End;
  BufAppendStr(B, '</w:p>');
 End;
 BufAppendStr(B, '</w:body></w:document>');
End;

Function SaveDocxToFile(Const FName: String): Boolean;
Var
 Z              : TZipWriter;
 BCT, BRels, BD : TByteBuf;
 BMP, BRD       : TByteBuf;
 OK             : Boolean;
 I, N           : Integer;
 NS             : String;
Begin
 SaveDocxToFile := False;
 DocxBuildContentTypes(BCT);
 DocxBuildRels(BRels);
 DocxBuildDocument(BD);
 OK := ZipWrite_Create(Z, FName);
 If OK Then OK := ZipWrite_AddDeflate(Z, '[Content_Types].xml', BCT.Data,
   BCT.Size);
 If OK Then OK := ZipWrite_AddDeflate(Z, '_rels/.rels',         BRels.Data,
   BRels.Size);
 If OK Then OK := ZipWrite_AddDeflate(Z, 'word/document.xml',   BD.Data,
   BD.Size);
 N := 0;
 For I := 1 To Doc^.ParaCount Do
  If OK And Doc^.Paragraphs[I].IsImage And
     (Doc^.Paragraphs[I].ImgData <> Nil) Then Begin
   Inc(N); Str(N, NS);
   BufInit(BMP);
   DocxBuildBmp(BMP, I);
   OK := ZipWrite_AddStored(Z, 'word/media/image' + NS + '.bmp', BMP.Data,
     BMP.Size);
   BufFree(BMP);
  End;
 If OK And (N > 0) Then Begin
  DocxBuildDocRels(BRD, N);
  OK := ZipWrite_AddDeflate(Z, 'word/_rels/document.xml.rels', BRD.Data,
    BRD.Size);
  BufFree(BRD);
 End;
 If OK Then OK := ZipWrite_Finish(Z);
 BufFree(BCT); BufFree(BRels); BufFree(BD);
 SaveDocxToFile := OK;
End;

{ ---------- Conversion Unicode <-> CP437 ----------------------- }
{ Mappage Unicode (BMP) -> CP437 pour les caracteres frequents.   }
{ Retourne 0 si pas de glyphe correspondant (l'appelant met '?'). }

Function UniToCp437(W: Word): Byte;
Begin
 UniToCp437 := 0;
 If W < 128 Then Begin UniToCp437 := Byte(W); Exit; End;
 Case W Of
  $00A0: UniToCp437 := 32;     { NBSP -> espace }
  $00A1: UniToCp437 := 173;    $00A2: UniToCp437 := 155;
  $00A3: UniToCp437 := 156;    $00A5: UniToCp437 := 157;
  $00AA: UniToCp437 := 166;    $00AB: UniToCp437 := 174;
  $00AC: UniToCp437 := 170;    $00B0: UniToCp437 := 248;
  $00B1: UniToCp437 := 241;    $00B2: UniToCp437 := 253;
  $00B5: UniToCp437 := 230;    $00B7: UniToCp437 := 250;
  $00BA: UniToCp437 := 167;    $00BB: UniToCp437 := 175;
  $00BC: UniToCp437 := 172;    $00BD: UniToCp437 := 171;
  $00BF: UniToCp437 := 168;
  $00C0: UniToCp437 := 65;     { A grave -> A (pas de glyphe CP437) }
  $00C2: UniToCp437 := 65;     { A circ  -> A }
  $00C4: UniToCp437 := 142;    $00C5: UniToCp437 := 143;
  $00C6: UniToCp437 := 146;    $00C7: UniToCp437 := 128;
  $00C8: UniToCp437 := 69;     $00C9: UniToCp437 := 144;
  $00CA: UniToCp437 := 69;     $00CB: UniToCp437 := 69;
  $00CE: UniToCp437 := 73;     $00CF: UniToCp437 := 73;
  $00D1: UniToCp437 := 165;    $00D4: UniToCp437 := 79;
  $00D6: UniToCp437 := 153;    $00D9: UniToCp437 := 85;
  $00DB: UniToCp437 := 85;     $00DC: UniToCp437 := 154;
  $00DF: UniToCp437 := 225;
  $00E0: UniToCp437 := 133;    $00E1: UniToCp437 := 160;
  $00E2: UniToCp437 := 131;    $00E4: UniToCp437 := 132;
  $00E5: UniToCp437 := 134;    $00E6: UniToCp437 := 145;
  $00E7: UniToCp437 := 135;    $00E8: UniToCp437 := 138;
  $00E9: UniToCp437 := 130;    $00EA: UniToCp437 := 136;
  $00EB: UniToCp437 := 137;    $00EC: UniToCp437 := 141;
  $00ED: UniToCp437 := 161;    $00EE: UniToCp437 := 140;
  $00EF: UniToCp437 := 139;    $00F1: UniToCp437 := 164;
  $00F2: UniToCp437 := 149;    $00F3: UniToCp437 := 162;
  $00F4: UniToCp437 := 147;    $00F6: UniToCp437 := 148;
  $00F7: UniToCp437 := 246;    $00F9: UniToCp437 := 151;
  $00FA: UniToCp437 := 163;    $00FB: UniToCp437 := 150;
  $00FC: UniToCp437 := 129;    $00FF: UniToCp437 := 152;
  $0152: UniToCp437 := 79;     { OE ligature -> O (approx) }
  $0153: UniToCp437 := 111;    { oe ligature -> o }
  $2013, $2014, $2212: UniToCp437 := 45;       { tirets -> '-' }
  $2018, $2019, $201A, $2032: UniToCp437 := 39; { quotes -> ' }
  $201C, $201D, $201E: UniToCp437 := 34;
  $2022: UniToCp437 := 7;      { puce }
  $2026: UniToCp437 := 46;     { ... -> '.' (laissera 1 point) }
  $20AC: UniToCp437 := 69;     { Euro -> 'E' }
 End;
End;

Function Cp437ToUni(B: Byte): Word;
Const
 Hi128: Array[128..255] Of Word = (
  $00C7,$00FC,$00E9,$00E2,$00E4,$00E0,$00E5,$00E7,
  $00EA,$00EB,$00E8,$00EF,$00EE,$00EC,$00C4,$00C5,
  $00C9,$00E6,$00C6,$00F4,$00F6,$00F2,$00FB,$00F9,
  $00FF,$00D6,$00DC,$00A2,$00A3,$00A5,$20A7,$0192,
  $00E1,$00ED,$00F3,$00FA,$00F1,$00D1,$00AA,$00BA,
  $00BF,$2310,$00AC,$00BD,$00BC,$00A1,$00AB,$00BB,
  $2591,$2592,$2593,$2502,$2524,$2561,$2562,$2556,
  $2555,$2563,$2551,$2557,$255D,$255C,$255B,$2510,
  $2514,$2534,$252C,$251C,$2500,$253C,$255E,$255F,
  $255A,$2554,$2569,$2566,$2560,$2550,$256C,$2567,
  $2568,$2564,$2565,$2559,$2558,$2552,$2553,$256B,
  $256A,$2518,$250C,$2588,$2584,$258C,$2590,$2580,
  $03B1,$00DF,$0393,$03C0,$03A3,$03C3,$00B5,$03C4,
  $03A6,$0398,$03A9,$03B4,$221E,$03C6,$03B5,$2229,
  $2261,$00B1,$2265,$2264,$2320,$2321,$00F7,$2248,
  $00B0,$2219,$00B7,$221A,$207F,$00B2,$25A0,$00A0);
Begin
 If B < 128 Then Cp437ToUni := B
 Else Cp437ToUni := Hi128[B];
End;

Function Utf8ToCp437(Const S: String): String;
Var
 I, L     : Integer;
 B0,B1,B2 : Byte;
 W        : LongInt;
 Mapped   : Byte;
 R        : String;
Begin
 R := ''; I := 1; L := Length(S);
 While I <= L Do Begin
  B0 := Byte(S[I]);
  If B0 < $80 Then Begin
   R := R + Chr(B0); Inc(I);
  End Else If (B0 And $E0) = $C0 Then Begin
   If I+1 > L Then Begin R := R + '?'; Inc(I); Continue; End;
   B1 := Byte(S[I+1]);
   W := (LongInt(B0 And $1F) Shl 6) Or (B1 And $3F);
   Mapped := UniToCp437(Word(W));
   If Mapped <> 0 Then R := R + Chr(Mapped) Else R := R + '?';
   Inc(I, 2);
  End Else If (B0 And $F0) = $E0 Then Begin
   If I+2 > L Then Begin R := R + '?'; Inc(I); Continue; End;
   B1 := Byte(S[I+1]); B2 := Byte(S[I+2]);
   W := (LongInt(B0 And $0F) Shl 12) Or
        (LongInt(B1 And $3F) Shl 6) Or (B2 And $3F);
   If W <= $FFFF Then Mapped := UniToCp437(Word(W)) Else Mapped := 0;
   If Mapped <> 0 Then R := R + Chr(Mapped) Else R := R + '?';
   Inc(I, 3);
  End Else If (B0 And $F8) = $F0 Then Begin
   { 4 octets : hors BMP, pas de mapping }
   R := R + '?'; Inc(I, 4);
  End Else Begin
   { Octet de continuation isole ou invalide }
   R := R + '?'; Inc(I);
  End;
  If Length(R) >= 240 Then Begin Utf8ToCp437 := R; Exit; End;
 End;
 Utf8ToCp437 := R;
End;

{ ---------- DOCX reader ---------- }

{ ----- Tables auxiliaires DOCX (styles, numerotation, en-tetes/pieds) ----- }

Const
 MAX_DOCX_STYLES   = 64;
 MAX_DOCX_NUMS     = 32;
 MAX_DOCX_ABSNUMS  = 32;

 NFMT_BULLET       = 0;
 NFMT_DECIMAL      = 1;
 NFMT_LOWERLETTER  = 2;
 NFMT_UPPERLETTER  = 3;
 NFMT_LOWERROMAN   = 4;
 NFMT_UPPERROMAN   = 5;

Type
 TDocxStyleEntry = Record
  StyleId  : String[40];
  Sty      : Byte;
  Size     : Byte;
  HasAlign : Boolean;
  Align    : Byte;
  HasBorderBottom : Boolean;
 End;
 TDocxAbsNum = Record
  AbsId : Integer;
  Fmt   : Array[0..8] Of Byte;
 End;
 TDocxNum = Record
  NumId : Integer;
  AbsId : Integer;
 End;

Var
 DocxStyleCount  : Integer;
 DocxStyles      : Array[1..MAX_DOCX_STYLES] Of TDocxStyleEntry;
 DocxNumCount    : Integer;
 DocxNums        : Array[1..MAX_DOCX_NUMS] Of TDocxNum;
 DocxAbsNumCount : Integer;
 DocxAbsNums     : Array[1..MAX_DOCX_ABSNUMS] Of TDocxAbsNum;
 ListCounters    : Array[1..MAX_DOCX_NUMS, 0..8] Of Integer;
 DocxPgMarL, DocxPgMarR, DocxPgMarT, DocxPgMarB : Integer;
 DocxPgMarValid  : Boolean;

Procedure ResetDocxAux;
Var I, J: Integer;
Begin
 DocxStyleCount  := 0;
 DocxNumCount    := 0;
 DocxAbsNumCount := 0;
 DocxHeaderText  := '';
 DocxFooterText  := '';
 DocxPgMarValid  := False;
 For I := 1 To MAX_DOCX_NUMS Do
  For J := 0 To 8 Do ListCounters[I, J] := 0;
End;

Function FindDocxStyle(Const Id: String): Integer;
Var I: Integer;
Begin
 FindDocxStyle := 0;
 For I := 1 To DocxStyleCount Do
  If DocxStyles[I].StyleId = Id Then Begin FindDocxStyle := I; Exit; End;
End;

Function FindDocxNum(N: Integer): Integer;
Var I: Integer;
Begin
 FindDocxNum := 0;
 For I := 1 To DocxNumCount Do
  If DocxNums[I].NumId = N Then Begin FindDocxNum := I; Exit; End;
End;

Function FindDocxAbsNum(A: Integer): Integer;
Var I: Integer;
Begin
 FindDocxAbsNum := 0;
 For I := 1 To DocxAbsNumCount Do
  If DocxAbsNums[I].AbsId = A Then Begin FindDocxAbsNum := I; Exit; End;
End;

{ Convertir un entier en notation alphabetique a..z, aa..zz, ... (style Word). }
Function IntToAlpha(N: Integer; Upper: Boolean): String;
Var R: String; D: Integer; Base: Char;
Begin
 If Upper Then Base := 'A' Else Base := 'a';
 R := '';
 If N < 1 Then N := 1;
 While N > 0 Do Begin
  Dec(N);
  D := N Mod 26;
  R := Char(Byte(Base) + D) + R;
  N := N Div 26;
 End;
 IntToAlpha := R;
End;

Function IntToRoman(N: Integer; Upper: Boolean): String;
Const
 Vals : Array[1..13] Of Integer = (1000,900,500,400,100,90,50,40,10,9,5,4,1);
 Syms : Array[1..13] Of String[2] =
   ('M','CM','D','CD','C','XC','L','XL','X','IX','V','IV','I');
Var R, S: String; I, K: Integer;
Begin
 R := '';
 If N < 1 Then N := 1;
 If N > 3999 Then N := 3999;
 For I := 1 To 13 Do
  While N >= Vals[I] Do Begin
   S := Syms[I];
   If Not Upper Then
    For K := 1 To Length(S) Do
     S[K] := Char(Byte(S[K]) + 32);
   R := R + S;
   Dec(N, Vals[I]);
  End;
 IntToRoman := R;
End;

Function BuildListPrefix(NumId, Ilvl: Integer): String;
Var Nidx, AnIdx, Fmt: Integer; Marker, Indent: String; J: Integer;
Begin
 BuildListPrefix := '';
 If (Ilvl < 0) Or (Ilvl > 8) Then Ilvl := 0;
 Indent := '';
 For J := 1 To Ilvl Do Indent := Indent + '  ';
 Fmt := NFMT_BULLET;
 Nidx := FindDocxNum(NumId);
 If Nidx > 0 Then Begin
  AnIdx := FindDocxAbsNum(DocxNums[Nidx].AbsId);
  If AnIdx > 0 Then Fmt := DocxAbsNums[AnIdx].Fmt[Ilvl];
 End;
 If (NumId >= 1) And (NumId <= MAX_DOCX_NUMS) Then
  Inc(ListCounters[NumId, Ilvl]);
 Case Fmt Of
  NFMT_DECIMAL :
   Begin
    If (NumId >= 1) And (NumId <= MAX_DOCX_NUMS) Then Begin
     Str(ListCounters[NumId, Ilvl], Marker);
     Marker := Marker + '.';
    End Else
     Marker := '1.';
   End;
  NFMT_LOWERLETTER :
   If (NumId >= 1) And (NumId <= MAX_DOCX_NUMS) Then
    Marker := IntToAlpha(ListCounters[NumId, Ilvl], False) + '.'
   Else Marker := 'a.';
  NFMT_UPPERLETTER :
   If (NumId >= 1) And (NumId <= MAX_DOCX_NUMS) Then
    Marker := IntToAlpha(ListCounters[NumId, Ilvl], True) + '.'
   Else Marker := 'A.';
  NFMT_LOWERROMAN :
   If (NumId >= 1) And (NumId <= MAX_DOCX_NUMS) Then
    Marker := IntToRoman(ListCounters[NumId, Ilvl], False) + '.'
   Else Marker := 'i.';
  NFMT_UPPERROMAN :
   If (NumId >= 1) And (NumId <= MAX_DOCX_NUMS) Then
    Marker := IntToRoman(ListCounters[NumId, Ilvl], True) + '.'
   Else Marker := 'I.';
 Else
  Marker := #7;     { puce CP437 }
 End;
 BuildListPrefix := Indent + Marker + ' ';
End;

{ Charger styles.xml dans DocxStyles[]. Le buffer DocxBuf/Size doit etre }
{ alloue par l'appelant pour le contenu de styles.xml.                    }
Procedure DocxParseStyles;
Var
 InStyle, InRPr, InPPr  : Boolean;
 InPBdr                 : Boolean;
 CurId                  : String[40];
 CurSty                 : Byte;
 CurSize                : Byte;
 CurAlign               : Byte;
 CurHasAlign            : Boolean;
 CurHasBdr              : Boolean;
 Tn, AttrVal            : String;
 SzHP, Code             : Integer;
Begin
 InStyle := False; InRPr := False; InPPr := False; InPBdr := False;
 CurId := ''; CurSty := 0; CurSize := 0; CurAlign := ALIGN_LEFT;
 CurHasAlign := False; CurHasBdr := False;
 Repeat
  DocxNextToken;
  Case TokKind Of
   DTK_START : Begin
    Tn := TokName;
    If Tn = 'w:style' Then Begin
     AttrVal := DocxGetAttr(TokAttrs, 'w:styleId');
     CurId := Copy(AttrVal, 1, 40);
     CurSty := 0; CurSize := 0; CurAlign := ALIGN_LEFT;
     CurHasAlign := False;
     CurHasBdr := False;
     InStyle := True;
    End
    Else If Tn = 'w:rPr' Then InRPr := True
    Else If Tn = 'w:pPr' Then InPPr := True
    Else If (Tn = 'w:pBdr') And InPPr Then InPBdr := True;
   End;
   DTK_EMPTY : Begin
    Tn := TokName;
    If InRPr Then Begin
     If Tn = 'w:b' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      If Not ((AttrVal='0') Or (AttrVal='false')) Then CurSty := CurSty Or
        STY_BOLD;
     End
     Else If Tn = 'w:i' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      If Not ((AttrVal='0') Or (AttrVal='false')) Then CurSty := CurSty Or
        STY_ITALIC;
     End
     Else If Tn = 'w:u' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      If AttrVal <> 'none' Then CurSty := CurSty Or STY_UNDERLINE;
     End
     Else If Tn = 'w:sz' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      Val(AttrVal, SzHP, Code);
      If Code = 0 Then Begin
       SzHP := SzHP Div 2;
       If SzHP < 6  Then SzHP := 6;
       If SzHP > 72 Then SzHP := 72;
       CurSize := SzHP;
      End;
     End;
    End
    Else If InPPr Then Begin
     If Tn = 'w:jc' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      If      AttrVal = 'center'  Then CurAlign := ALIGN_CENTER
      Else If AttrVal = 'right'   Then CurAlign := ALIGN_RIGHT
      Else If AttrVal = 'both'    Then CurAlign := ALIGN_JUSTIFY
      Else If AttrVal = 'justify' Then CurAlign := ALIGN_JUSTIFY
      Else                             CurAlign := ALIGN_LEFT;
      CurHasAlign := True;
     End
     Else If (Tn = 'w:bottom') And InPBdr Then CurHasBdr := True;
    End;
   End;
   DTK_END : Begin
    Tn := TokName;
    If Tn = 'w:rPr' Then InRPr := False
    Else If Tn = 'w:pPr' Then InPPr := False
    Else If Tn = 'w:pBdr' Then InPBdr := False
    Else If Tn = 'w:style' Then Begin
     If InStyle And (Length(CurId) > 0) And
        (DocxStyleCount < MAX_DOCX_STYLES) Then Begin
      Inc(DocxStyleCount);
      DocxStyles[DocxStyleCount].StyleId  := CurId;
      DocxStyles[DocxStyleCount].Sty      := CurSty;
      DocxStyles[DocxStyleCount].Size     := CurSize;
      DocxStyles[DocxStyleCount].HasAlign := CurHasAlign;
      DocxStyles[DocxStyleCount].Align    := CurAlign;
      DocxStyles[DocxStyleCount].HasBorderBottom := CurHasBdr;
     End;
     InStyle := False;
    End;
   End;
  End;
 Until TokKind = DTK_EOF;
End;

{ Charger numbering.xml. }
Procedure DocxParseNumbering;
Var
 InAbs, InLvl, InNum     : Boolean;
 CurAbsId, CurNumId      : Integer;
 CurILvl                 : Integer;
 LvlFmt                  : Array[0..8] Of Byte;
 J, NIv, Code            : Integer;
 Tn, AttrVal             : String;
Begin
 InAbs := False; InLvl := False; InNum := False;
 CurAbsId := -1; CurNumId := -1; CurILvl := -1;
 For J := 0 To 8 Do LvlFmt[J] := NFMT_BULLET;
 Repeat
  DocxNextToken;
  Case TokKind Of
   DTK_START : Begin
    Tn := TokName;
    If Tn = 'w:abstractNum' Then Begin
     AttrVal := DocxGetAttr(TokAttrs, 'w:abstractNumId');
     Val(AttrVal, CurAbsId, Code);
     If Code <> 0 Then CurAbsId := -1;
     For J := 0 To 8 Do LvlFmt[J] := NFMT_BULLET;
     InAbs := True;
    End
    Else If (Tn = 'w:lvl') And InAbs Then Begin
     AttrVal := DocxGetAttr(TokAttrs, 'w:ilvl');
     Val(AttrVal, CurILvl, Code);
     If (Code <> 0) Or (CurILvl < 0) Or (CurILvl > 8) Then CurILvl := -1;
     InLvl := True;
    End
    Else If Tn = 'w:num' Then Begin
     AttrVal := DocxGetAttr(TokAttrs, 'w:numId');
     Val(AttrVal, CurNumId, Code);
     If Code <> 0 Then CurNumId := -1;
     InNum := True;
    End;
   End;
   DTK_EMPTY : Begin
    Tn := TokName;
    If InLvl And (Tn = 'w:numFmt') Then Begin
     AttrVal := DocxGetAttr(TokAttrs, 'w:val');
     If (CurILvl >= 0) And (CurILvl <= 8) Then Begin
      If      AttrVal = 'decimal'      Then LvlFmt[CurILvl] := NFMT_DECIMAL
      Else If AttrVal = 'lowerLetter'  Then LvlFmt[CurILvl] := NFMT_LOWERLETTER
      Else If AttrVal = 'upperLetter'  Then LvlFmt[CurILvl] := NFMT_UPPERLETTER
      Else If AttrVal = 'lowerRoman'   Then LvlFmt[CurILvl] := NFMT_LOWERROMAN
      Else If AttrVal = 'upperRoman'   Then LvlFmt[CurILvl] := NFMT_UPPERROMAN
      Else                                  LvlFmt[CurILvl] := NFMT_BULLET;
     End;
    End
    Else If InNum And (Tn = 'w:abstractNumId') Then Begin
     AttrVal := DocxGetAttr(TokAttrs, 'w:val');
     Val(AttrVal, NIv, Code);
     If (Code = 0) And (CurNumId >= 0) And
        (DocxNumCount < MAX_DOCX_NUMS) Then Begin
      Inc(DocxNumCount);
      DocxNums[DocxNumCount].NumId := CurNumId;
      DocxNums[DocxNumCount].AbsId := NIv;
     End;
    End;
   End;
   DTK_END : Begin
    Tn := TokName;
    If Tn = 'w:lvl' Then InLvl := False
    Else If Tn = 'w:abstractNum' Then Begin
     If InAbs And (CurAbsId >= 0) And
        (DocxAbsNumCount < MAX_DOCX_ABSNUMS) Then Begin
      Inc(DocxAbsNumCount);
      DocxAbsNums[DocxAbsNumCount].AbsId := CurAbsId;
      For J := 0 To 8 Do
       DocxAbsNums[DocxAbsNumCount].Fmt[J] := LvlFmt[J];
     End;
     InAbs := False;
    End
    Else If Tn = 'w:num' Then InNum := False;
   End;
  End;
 Until TokKind = DTK_EOF;
End;

{ Extraire le texte concatene des elements <w:t> dans un buffer XML. }
Function DocxExtractAllText: String;
Var R, TxtPiece: String; InT: Boolean; Tn: String;
Begin
 R := ''; InT := False;
 Repeat
  DocxNextToken;
  Case TokKind Of
   DTK_START : Begin
    Tn := TokName;
    If Tn = 'w:t' Then InT := True
    Else If Tn = 'w:tab' Then If Length(R) < 200 Then R := R + ' '
    Else If Tn = 'w:br'  Then If Length(R) < 200 Then R := R + ' ';
   End;
   DTK_EMPTY : Begin
    Tn := TokName;
    If Tn = 'w:tab' Then If Length(R) < 200 Then R := R + ' '
    Else If Tn = 'w:br' Then If Length(R) < 200 Then R := R + ' ';
   End;
   DTK_END : If TokName = 'w:t' Then InT := False;
   DTK_TEXT :
    If InT Then Begin
     TxtPiece := Utf8ToCp437(TokText);
     If Length(R) + Length(TxtPiece) > 200 Then
      TxtPiece := Copy(TxtPiece, 1, 200 - Length(R));
     R := R + TxtPiece;
    End;
  End;
 Until TokKind = DTK_EOF;
 DocxExtractAllText := R;
End;

{ ----- Images DOCX : lecture (word/media/*) ----- }

Const
 MAX_DOCX_IMGS = 24;

Type
 TDocxImg = Record
  RelId : String[40];
  Buf   : Pointer;
  W, H  : Integer;
 End;

Var
 DocxImgs     : Array[1..MAX_DOCX_IMGS] Of TDocxImg;
 DocxImgCount : Integer;

Procedure DocxFreeImgs;
Var I: Integer;
Begin
 For I := 1 To DocxImgCount Do
  If DocxImgs[I].Buf <> Nil Then
   FreeMem(DocxImgs[I].Buf, LongInt(DocxImgs[I].W) * DocxImgs[I].H);
 DocxImgCount := 0;
End;

{ Decode une image du zip via un fichier temporaire (LoadAnyImage) }
Function DocxDecodeImage(IBuf: Pointer; ISize: LongInt; Const Ext: String;
                         Var Buf: Pointer; Var W, H: Integer): Boolean;
Var F: File; TmpN: String;
Begin
 DocxDecodeImage := False; Buf := Nil;
 TmpN := 'WRDIMGTMP.' + Ext;
 {$I-} Assign(F, TmpN); Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 {$I-} BlockWrite(F, IBuf^, ISize); Close(F); {$I+}
 If IOResult = 0 Then DocxDecodeImage := LoadAnyImage(TmpN, Buf, W, H);
 {$I-} Erase(F); {$I+}
 If IOResult <> 0 Then ;
End;

Procedure DocxLoadImages(Var Z: TZipReader);
Var
 Idx, I, W, H, SW, SH : Integer;
 RBuf, IBuf, Buf, Sc  : Pointer;
 RSize, ISize         : LongInt;
 SBuf                 : Pointer;
 SPos, SSize          : LongInt;
 Id, Target, Ext      : String;
Begin
 DocxImgCount := 0;
 Idx := ZipRead_Find(Z, 'word/_rels/document.xml.rels');
 If Idx <= 0 Then Exit;
 If Not ZipRead_Extract(Z, Idx, RBuf, RSize) Then Exit;
 SBuf := DocxBuf; SPos := DocxPos; SSize := DocxSize;
 DocxBuf := RBuf; DocxPos := 0; DocxSize := RSize;
 Repeat
  DocxNextToken;
  If ((TokKind = DTK_EMPTY) Or (TokKind = DTK_START)) And
     (TokName = 'Relationship') And (DocxImgCount < MAX_DOCX_IMGS) Then Begin
   Id := DocxGetAttr(TokAttrs, 'Id');
   Target := DocxGetAttr(TokAttrs, 'Target');
   If Pos('media/', Target) > 0 Then Begin
    Ext := '';
    For I := Length(Target) Downto 1 Do
     If Target[I] = '.' Then Begin Ext := Copy(Target, I + 1, 6); Break; End;
    If (Length(Target) > 0) And (Target[1] = '/') Then
     Target := Copy(Target, 2, 255)
    Else Target := 'word/' + Target;
    Idx := ZipRead_Find(Z, Target);
    If (Idx > 0) And (Ext <> '') And ZipRead_Extract(Z, Idx, IBuf, ISize) Then
     Begin
      If DocxDecodeImage(IBuf, ISize, Ext, Buf, W, H) Then Begin
       ScaleImageNN(Buf, W, H, Sc, SW, SH);
       FreeMem(Buf, LongInt(W) * H);
       Inc(DocxImgCount);
       DocxImgs[DocxImgCount].RelId := Id;
       DocxImgs[DocxImgCount].Buf   := Sc;
       DocxImgs[DocxImgCount].W     := SW;
       DocxImgs[DocxImgCount].H     := SH;
      End;
      FreeMem(IBuf, ISize);
     End;
   End;
  End;
 Until TokKind = DTK_EOF;
 FreeMem(RBuf, RSize);
 DocxBuf := SBuf; DocxPos := SPos; DocxSize := SSize;
End;

{ Transforme le paragraphe ParaIdx en image (ou ajoute un paragraphe image
  apres lui s'il contient du texte). }
Procedure DocxPlaceImage(Var ParaIdx: Integer; Const Rel: String);
Var I, J, P: Integer; Has: Boolean; Cp: Pointer;
Begin
 I := 0;
 For J := 1 To DocxImgCount Do
  If DocxImgs[J].RelId = Rel Then I := J;
 If I = 0 Then Exit;
 P := ParaIdx; Has := False;
 For J := 1 To Doc^.Paragraphs[P].RunCount Do
  If Doc^.Paragraphs[P].Runs[J].Text <> '' Then Has := True;
 If Has Then Begin
  If ParaIdx >= MAX_PARAS_PER_DOC Then Exit;
  Inc(ParaIdx); P := ParaIdx;
  Doc^.Paragraphs[P].Alignment := Doc^.Paragraphs[P - 1].Alignment;
 End;
 GetMem(Cp, LongInt(DocxImgs[I].W) * DocxImgs[I].H);
 Move(DocxImgs[I].Buf^, Cp^, LongInt(DocxImgs[I].W) * DocxImgs[I].H);
 Doc^.Paragraphs[P].RunCount := 0;
 Doc^.Paragraphs[P].IsImage  := True;
 Doc^.Paragraphs[P].ImgW     := DocxImgs[I].W;
 Doc^.Paragraphs[P].ImgH     := DocxImgs[I].H;
 Doc^.Paragraphs[P].ImgData  := Cp;
End;

Procedure DocxLoadAuxParts(Var Z: TZipReader);
Var
 Idx, I    : Integer;
 Buf       : Pointer;
 Size      : LongInt;
 Nm        : String;
 SavedBuf  : Pointer;
 SavedPos, SavedSize : LongInt;
Begin
 SavedBuf := DocxBuf; SavedPos := DocxPos; SavedSize := DocxSize;
 { styles.xml }
 Idx := ZipRead_Find(Z, 'word/styles.xml');
 If (Idx >= 0) And ZipRead_Extract(Z, Idx, Buf, Size) Then Begin
  DocxBuf := Buf; DocxPos := 0; DocxSize := Size;
  DocxParseStyles;
  FreeMem(Buf, Size);
 End;
 { numbering.xml }
 Idx := ZipRead_Find(Z, 'word/numbering.xml');
 If (Idx >= 0) And ZipRead_Extract(Z, Idx, Buf, Size) Then Begin
  DocxBuf := Buf; DocxPos := 0; DocxSize := Size;
  DocxParseNumbering;
  FreeMem(Buf, Size);
 End;
 { Premier header*.xml }
 For I := 1 To Z.EntryCount Do Begin
  Nm := Z.Entries[I].Name;
  If (Length(Nm) >= 11) And (Copy(Nm, 1, 11) = 'word/header') Then Begin
   If ZipRead_Extract(Z, I, Buf, Size) Then Begin
    DocxBuf := Buf; DocxPos := 0; DocxSize := Size;
    DocxHeaderText := DocxExtractAllText;
    FreeMem(Buf, Size);
   End;
   Break;
  End;
 End;
 { Premier footer*.xml }
 For I := 1 To Z.EntryCount Do Begin
  Nm := Z.Entries[I].Name;
  If (Length(Nm) >= 11) And (Copy(Nm, 1, 11) = 'word/footer') Then Begin
   If ZipRead_Extract(Z, I, Buf, Size) Then Begin
    DocxBuf := Buf; DocxPos := 0; DocxSize := Size;
    DocxFooterText := DocxExtractAllText;
    FreeMem(Buf, Size);
   End;
   Break;
  End;
 End;
 DocxBuf := SavedBuf; DocxPos := SavedPos; DocxSize := SavedSize;
End;

{ Convertir une couleur RVB hex DOCX (ex "FF0000") vers la couleur VGA 16 la }
{ plus proche.  Renvoie Black si chaine invalide ou "auto".                  }
Function HexRgbToVga(Const HexS: String): Byte;
Const
 PalR : Array[0..15] Of Byte =
  (  0,  0,  0,  0,170,170,170,170, 85, 85, 85, 85,255,255,255,255);
 PalG : Array[0..15] Of Byte =
  (  0,  0,170,170,  0,  0, 85,170, 85, 85,255,255, 85, 85,255,255);
 PalB : Array[0..15] Of Byte =
  (  0,170,  0,170,  0,170,  0,170, 85,255, 85,255, 85,255, 85,255);
Var
 R, G, B, Code : Integer;
 H             : String[6];
 I, Best       : Integer;
 D, BestD, DR, DG, DB : LongInt;
Begin
 HexRgbToVga := Black;
 If Length(HexS) < 6 Then Exit;
 If (HexS = 'auto') Or (HexS = 'AUTO') Then Exit;
 H := Copy(HexS, 1, 6);
 Val('$' + Copy(H, 1, 2), R, Code); If Code <> 0 Then Exit;
 Val('$' + Copy(H, 3, 2), G, Code); If Code <> 0 Then Exit;
 Val('$' + Copy(H, 5, 2), B, Code); If Code <> 0 Then Exit;
 Best := 0; BestD := MaxLongInt;
 For I := 0 To 15 Do Begin
  DR := LongInt(R) - PalR[I];
  DG := LongInt(G) - PalG[I];
  DB := LongInt(B) - PalB[I];
  D := DR*DR + DG*DG + DB*DB;
  If D < BestD Then Begin BestD := D; Best := I; End;
 End;
 { Eviter d'utiliser blanc (15) ou gris tres clair (7) qui sont invisibles }
 { sur la page blanche : rabattre sur DarkGray.                            }
 If (Best = 15) Or (Best = 7) Then Best := DarkGray;
 HexRgbToVga := Byte(Best);
End;

Function LoadDocxFromFile(Const FName: String): Boolean;
Var
 Z          : TZipReader;
 Idx, Code  : Integer;
 Buf        : Pointer;
 Size       : LongInt;
 ParaIdx    : Integer;
 RunIdx     : Integer;
 InP, InR   : Boolean;
 InRPr, InPPr, InT : Boolean;
 InNumPr    : Boolean;
 InSectPr   : Boolean;
 InPBdr     : Boolean;
 PendingPB  : Boolean;
 CurAlign   : Byte;
 RunSty     : Byte;
 RunSize    : Byte;
 RunColor   : Byte;
 RunStyleSet: Boolean;
 ParaForceSty  : Byte;
 ParaForceSize : Byte;
 ParaHasNum    : Boolean;
 ParaIlvl      : Integer;
 ParaNumId     : Integer;
 StyIdx        : Integer;
 PgMarT, PgMarB, PgMarL, PgMarR : LongInt;
 EffSty     : Byte;
 EffSize    : Byte;
 BulletS    : String;
 NIv, IndValue, IndError: Integer;
 AttrVal    : String;
 Tn         : String;
 SzHP       : Integer;
 OK         : Boolean;
 TLen, AvailLen : Integer;
 TotLen, K  : Integer;
 M          : Integer;
 PendingTail, LastRunText : String;
 TxtPiece   : String;
 ParaImgRel : String;
Begin
 LoadDocxFromFile := False;
 ParaImgRel := '';
 { Reinitialiser tables auxiliaires et marges par defaut }
 ResetDocxAux;
 PAGE_MARGIN_L := PAGE_MARGIN_DEFAULT;
 PAGE_MARGIN_R := PAGE_MARGIN_DEFAULT;
 PAGE_MARGIN_T := PAGE_MARGIN_DEFAULT;
 PAGE_MARGIN_B := PAGE_MARGIN_DEFAULT;
 If Not ZipRead_Open(Z, FName) Then Exit;
 Idx := ZipRead_Find(Z, 'word/document.xml');
 If Idx < 0 Then Begin ZipRead_Close(Z); Exit; End;
 If Not ZipRead_Extract(Z, Idx, Buf, Size) Then Begin ZipRead_Close(Z); Exit;
   End;
 { Charger styles, numerotation, en-tete,
   pied avant la lecture de document.xml }
 DocxLoadAuxParts(Z);
 DocxLoadImages(Z);
 ZipRead_Close(Z);

 DocxBuf := Buf; DocxPos := 0; DocxSize := Size;

 FreeAllDocImages;
 FillChar(Doc^, SizeOf(Doc^), 0);
 Doc^.PageCount := 1;
 ParaIdx := 0; RunIdx := 0;
 InP := False; InR := False; InRPr := False; InPPr := False; InT := False;
 InNumPr := False; InSectPr := False;
 InPBdr := False;
 PendingPB := False;
 CurAlign := ALIGN_LEFT;
 RunSty := 0; RunSize := 12; RunStyleSet := False;
 RunColor := Black;
 ParaForceSty := 0; ParaForceSize := 0;
 ParaHasNum := False; ParaIlvl := 0; ParaNumId := -1;
 OK := True;

 Repeat
  DocxNextToken;
  Case TokKind Of

   DTK_START : Begin
    Tn := TokName;
    If Tn = 'w:p' Then Begin
     If ParaIdx >= MAX_PARAS_PER_DOC Then Begin
      { On stoppe la lecture mais on garde ce qu'on a. }
      OK := True; Break;
     End;
     Inc(ParaIdx);
     Doc^.Paragraphs[ParaIdx].Alignment := ALIGN_LEFT;
     Doc^.Paragraphs[ParaIdx].PageBreakBefore := PendingPB;
     PendingPB := False;
     Doc^.Paragraphs[ParaIdx].RunCount := 0;
     Doc^.Paragraphs[ParaIdx].IsImage := False;
     InP := True;
     ParaImgRel := '';
     CurAlign := ALIGN_LEFT;
     ParaForceSty := 0; ParaForceSize := 0;
     ParaHasNum := False; ParaIlvl := 0; ParaNumId := -1;
    End
    Else If (Tn = 'a:blip') And InP Then
     ParaImgRel := DocxGetAttr(TokAttrs, 'r:embed')
    Else If Tn = 'w:pPr' Then InPPr := True
    Else If Tn = 'w:sectPr' Then InSectPr := True
    Else If (Tn = 'w:pBdr') And InPPr Then InPBdr := True
    Else If (Tn = 'w:numPr') And InPPr Then Begin
     InNumPr := True; ParaHasNum := True;
    End
    Else If (Tn = 'w:r') And InP Then Begin
     If Doc^.Paragraphs[ParaIdx].RunCount < MAX_RUNS_PER_PARA Then Begin
      Inc(Doc^.Paragraphs[ParaIdx].RunCount);
      RunIdx := Doc^.Paragraphs[ParaIdx].RunCount;
      RunSty := 0; RunSize := 12; RunStyleSet := False;
      RunColor := Black;
      Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text := '';
      Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Style.Style    := 0;
      Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Style.FontSize := 12;
      Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Style.Color    := Black;
      InR := True;
     End;
    End
    Else If Tn = 'w:rPr' Then InRPr := True
    Else If (Tn = 'w:t') And InR Then InT := True;
   End;

   DTK_EMPTY : Begin
    Tn := TokName;
    { Word legacy HR : <w:pict><v:rect o:hr="t" .../></w:pict> }
    If (Tn = 'a:blip') And InP Then
     ParaImgRel := DocxGetAttr(TokAttrs, 'r:embed')
    Else If (Tn = 'v:rect') And InP Then Begin
     AttrVal := DocxGetAttr(TokAttrs, 'o:hr');
     If AttrVal = 't' Then Doc^.Paragraphs[ParaIdx].BorderBottom := True;
    End
    Else If InPPr Then Begin
     If Tn = 'w:jc' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      If      AttrVal = 'center'  Then CurAlign := ALIGN_CENTER
      Else If AttrVal = 'right'   Then CurAlign := ALIGN_RIGHT
      Else If AttrVal = 'both'    Then CurAlign := ALIGN_JUSTIFY
      Else If AttrVal = 'justify' Then CurAlign := ALIGN_JUSTIFY
      Else                             CurAlign := ALIGN_LEFT;
     End
     Else If (Tn = 'w:ind') And InP Then Begin
      AttrVal:=DocxGetAttr(TokAttrs,'w:left');
      If AttrVal='' Then AttrVal:=DocxGetAttr(TokAttrs,'w:start');
      Val(AttrVal,IndValue,IndError);
      If (IndError=0) And (IndValue>=0) Then Begin
       If IndValue>2400 Then IndValue:=2400;
       Doc^.Paragraphs[ParaIdx].LeftIndent:=(IndValue+7) div 15;
       AttrVal:=DocxGetAttr(TokAttrs,'w:hanging');
       Val(AttrVal,IndValue,IndError);
       Doc^.Paragraphs[ParaIdx].FirstLineHang:=(IndError<>0) Or (IndValue=0);
      End;
     End
     Else If Tn = 'w:pageBreakBefore' Then Begin
      If InP Then Doc^.Paragraphs[ParaIdx].PageBreakBefore := True;
     End
     Else If (Tn = 'w:bottom') And InPBdr Then Begin
      If InP Then Doc^.Paragraphs[ParaIdx].BorderBottom := True;
     End
     Else If Tn = 'w:pStyle' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      { Reconnaitre styles de titre courants : Heading1..6, Title, Subtitle. }
      If      (AttrVal = 'Heading1') Or (AttrVal = 'heading 1') Then Begin
       ParaForceSty := STY_BOLD; ParaForceSize := 18;
      End
      Else If (AttrVal = 'Heading2') Or (AttrVal = 'heading 2') Then Begin
       ParaForceSty := STY_BOLD; ParaForceSize := 16;
      End
      Else If (AttrVal = 'Heading3') Or (AttrVal = 'heading 3') Then Begin
       ParaForceSty := STY_BOLD; ParaForceSize := 14;
      End
      Else If (AttrVal = 'Heading4') Or (AttrVal = 'heading 4') Or
              (AttrVal = 'Heading5') Or (AttrVal = 'heading 5') Or
              (AttrVal = 'Heading6') Or (AttrVal = 'heading 6') Then Begin
       ParaForceSty := STY_BOLD Or STY_ITALIC; ParaForceSize := 12;
      End
      Else If (AttrVal = 'Title') Then Begin
       ParaForceSty := STY_BOLD; ParaForceSize := 22;
      End
      Else If (AttrVal = 'Subtitle') Then Begin
       ParaForceSty := STY_ITALIC; ParaForceSize := 14;
      End
      Else Begin
       { Style personnalise : chercher dans styles.xml }
       StyIdx := FindDocxStyle(AttrVal);
       If StyIdx > 0 Then Begin
        ParaForceSty := DocxStyles[StyIdx].Sty;
        If DocxStyles[StyIdx].Size > 0 Then ParaForceSize :=
          DocxStyles[StyIdx].Size;
        If DocxStyles[StyIdx].HasAlign Then CurAlign :=
          DocxStyles[StyIdx].Align;
       End;
      End;
      { Bordure inferieure : toujours interroger styles.xml meme pour les }
      { styles de titre reconnus en fast-path (Heading1..6, Title...).    }
      StyIdx := FindDocxStyle(AttrVal);
      If StyIdx > 0 Then
       If DocxStyles[StyIdx].HasBorderBottom And InP Then
        Doc^.Paragraphs[ParaIdx].BorderBottom := True;
     End
     Else If InNumPr Then Begin
      If Tn = 'w:ilvl' Then Begin
       AttrVal := DocxGetAttr(TokAttrs, 'w:val');
       Val(AttrVal, NIv, Code);
       If (Code = 0) And (NIv >= 0) And (NIv <= 8) Then ParaIlvl := NIv;
      End
      Else If Tn = 'w:numId' Then Begin
       AttrVal := DocxGetAttr(TokAttrs, 'w:val');
       Val(AttrVal, NIv, Code);
       If Code = 0 Then ParaNumId := NIv;
      End;
     End;
    End
    Else If InSectPr And (Tn = 'w:pgMar') Then Begin
     AttrVal := DocxGetAttr(TokAttrs, 'w:top');    Val(AttrVal, PgMarT, Code);
     If Code <> 0 Then PgMarT := -1;
     AttrVal := DocxGetAttr(TokAttrs, 'w:bottom'); Val(AttrVal, PgMarB, Code);
     If Code <> 0 Then PgMarB := -1;
     AttrVal := DocxGetAttr(TokAttrs, 'w:left');   Val(AttrVal, PgMarL, Code);
     If Code <> 0 Then PgMarL := -1;
     AttrVal := DocxGetAttr(TokAttrs, 'w:right');  Val(AttrVal, PgMarR, Code);
     If Code <> 0 Then PgMarR := -1;
     { Conversion twips -> pixels (8.5 po = 12240 twips = PAGE_W pixels). }
     If PgMarL >= 0 Then PAGE_MARGIN_L := Integer((PgMarL * LongInt(PAGE_W)) Div
       12240);
     If PgMarR >= 0 Then PAGE_MARGIN_R := Integer((PgMarR * LongInt(PAGE_W)) Div
       12240);
     If PgMarT >= 0 Then PAGE_MARGIN_T := Integer((PgMarT * LongInt(PAGE_H)) Div
       15840);
     If PgMarB >= 0 Then PAGE_MARGIN_B := Integer((PgMarB * LongInt(PAGE_H)) Div
       15840);
     { Bornes raisonnables : eviter zones de texte ridiculement petites. }
     If PAGE_MARGIN_L < 10 Then PAGE_MARGIN_L := 10;
     If PAGE_MARGIN_R < 10 Then PAGE_MARGIN_R := 10;
     If PAGE_MARGIN_T < 10 Then PAGE_MARGIN_T := 10;
     If PAGE_MARGIN_B < 10 Then PAGE_MARGIN_B := 10;
     If PAGE_MARGIN_L > (PAGE_W Div 3) Then PAGE_MARGIN_L := PAGE_W Div 3;
     If PAGE_MARGIN_R > (PAGE_W Div 3) Then PAGE_MARGIN_R := PAGE_W Div 3;
     If PAGE_MARGIN_T > (PAGE_H Div 3) Then PAGE_MARGIN_T := PAGE_H Div 3;
     If PAGE_MARGIN_B > (PAGE_H Div 3) Then PAGE_MARGIN_B := PAGE_H Div 3;
    End
    Else If InRPr Then Begin
     If Tn = 'w:b' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      If (AttrVal = '0') Or (AttrVal = 'false') Then
       RunSty := RunSty And (Not STY_BOLD)
      Else
       RunSty := RunSty Or STY_BOLD;
     End
     Else If Tn = 'w:i' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      If (AttrVal = '0') Or (AttrVal = 'false') Then
       RunSty := RunSty And (Not STY_ITALIC)
      Else
       RunSty := RunSty Or STY_ITALIC;
     End
     Else If Tn = 'w:u' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      If AttrVal <> 'none' Then RunSty := RunSty Or STY_UNDERLINE;
     End
     Else If Tn = 'w:sz' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      Val(AttrVal, SzHP, Code);
      If Code = 0 Then Begin
       SzHP := SzHP Div 2;
       If SzHP < 6  Then SzHP := 6;
       If SzHP > 72 Then SzHP := 72;
       RunSize := SzHP;
      End;
     End
     Else If Tn = 'w:color' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:val');
      RunColor := HexRgbToVga(AttrVal);
     End;
     RunStyleSet := True;
    End
    Else If InR Then Begin
     If Tn = 'w:br' Then Begin
      AttrVal := DocxGetAttr(TokAttrs, 'w:type');
      If AttrVal = 'page' Then PendingPB := True
      Else Begin
       { Saut de ligne souple : creer un nouveau paragraphe heritant }
       { du style et de l'alignement courants, et continuer dedans.   }
       If ParaIdx < MAX_PARAS_PER_DOC Then Begin
        { Sauver l'indentation pour propagation (paragraphe en cours). }
        NIv := Doc^.Paragraphs[ParaIdx].LeftIndent;
        { Marquer la continuation des deux cotes pour preserver justify }
        { sur la derniere vline du paragraphe parent (le break est      }
        { interne au paragraphe Word logique).                          }
        Doc^.Paragraphs[ParaIdx].ContinuesNext := True;
        Inc(ParaIdx);
        Doc^.Paragraphs[ParaIdx].Alignment := CurAlign;
        Doc^.Paragraphs[ParaIdx].PageBreakBefore := False;
        Doc^.Paragraphs[ParaIdx].RunCount := 1;
        Doc^.Paragraphs[ParaIdx].IsImage := False;
        Doc^.Paragraphs[ParaIdx].ContinuesPrev := True;
        { Heriter de l'indentation de liste : pas de marqueur, mais texte
          aligne sous le contenu de la ligne precedente.                  }
        Doc^.Paragraphs[ParaIdx].LeftIndent := NIv;
        Doc^.Paragraphs[ParaIdx].FirstLineHang := NIv > 0;
        RunIdx := 1;
        EffSty := RunSty; If ParaForceSty <> 0 Then EffSty := EffSty Or
          ParaForceSty;
        EffSize := RunSize;
        If (ParaForceSize > 0) And (RunSize = 12) Then EffSize := ParaForceSize;
        Doc^.Paragraphs[ParaIdx].Runs[1].Text := '';
        Doc^.Paragraphs[ParaIdx].Runs[1].Style.Style    := EffSty;
        Doc^.Paragraphs[ParaIdx].Runs[1].Style.FontSize := EffSize;
        Doc^.Paragraphs[ParaIdx].Runs[1].Style.Color    := RunColor;
       End;
      End;
     End
     Else If Tn = 'w:tab' Then Begin
      { Tabulation : 4 espaces (faute de tabulateurs reels) }
      If Length(Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text) + 4 <= MAX_TEXT_LEN
        Then
       Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text :=
        Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text + '    '
      Else If Length(Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text) < MAX_TEXT_LEN
        Then
       Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text :=
        Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text + ' ';
     End;
    End;
   End;

   DTK_END : Begin
    Tn := TokName;
    If Tn = 'w:t' Then InT := False
    Else If Tn = 'w:numPr' Then InNumPr := False
    Else If Tn = 'w:sectPr' Then InSectPr := False
    Else If Tn = 'w:pBdr' Then InPBdr := False
    Else If Tn = 'w:rPr' Then Begin
     InRPr := False;
     { Le commit definitif des styles est fait a </w:r> pour pouvoir }
     { appliquer ParaForceSty/Size hericies du pStyle.               }
    End
    Else If Tn = 'w:r' Then Begin
     If InR Then Begin
      EffSty  := RunSty;
      EffSize := RunSize;
      If ParaForceSty <> 0 Then EffSty := EffSty Or ParaForceSty;
      If (ParaForceSize > 0) And (RunSize = 12) Then EffSize := ParaForceSize;
      Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Style.Style    := EffSty;
      Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Style.FontSize := EffSize;
      Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Style.Color    := RunColor;
     End;
     InR := False;
    End
    Else If Tn = 'w:pPr' Then Begin
     InPPr := False;
     If InP Then Doc^.Paragraphs[ParaIdx].Alignment := CurAlign;
     { Inserer le marqueur de liste (puce, decimal, lettre, romain) }
     If InP And ParaHasNum And
        (Doc^.Paragraphs[ParaIdx].RunCount = 0) Then Begin
      BulletS := BuildListPrefix(ParaNumId, ParaIlvl);
      Inc(Doc^.Paragraphs[ParaIdx].RunCount);
      Doc^.Paragraphs[ParaIdx].Runs[1].Text := BulletS;
      Doc^.Paragraphs[ParaIdx].Runs[1].Style.Style    := 0;
      Doc^.Paragraphs[ParaIdx].Runs[1].Style.FontSize := 12;
      Doc^.Paragraphs[ParaIdx].Runs[1].Style.Color    := Black;
      { Largeur visuelle approximative du prefixe (8 px / char en DefaultFont).
        }
      Doc^.Paragraphs[ParaIdx].LeftIndent := Length(BulletS) * 8;
      Doc^.Paragraphs[ParaIdx].FirstLineHang := False;
     End;
    End
    Else If Tn = 'w:p' Then Begin
     If (ParaIdx > 0) And (Doc^.Paragraphs[ParaIdx].RunCount = 0) Then Begin
      Doc^.Paragraphs[ParaIdx].RunCount := 1;
      Doc^.Paragraphs[ParaIdx].Runs[1].Text := '';
      Doc^.Paragraphs[ParaIdx].Runs[1].Style.Style    := 0;
      Doc^.Paragraphs[ParaIdx].Runs[1].Style.FontSize := 12;
      Doc^.Paragraphs[ParaIdx].Runs[1].Style.Color    := Black;
     End;
     If (ParaIdx > 0) And (ParaImgRel <> '') Then
      DocxPlaceImage(ParaIdx, ParaImgRel);
     ParaImgRel := '';
     InP := False;
    End;
   End;

   DTK_TEXT : Begin
    If InT And InR And (ParaIdx > 0) And (RunIdx > 0) Then Begin
     TxtPiece := Utf8ToCp437(TokText);
     { Longueur totale courante du paragraphe (somme des runs). }
     TotLen := 0;
     For K := 1 To Doc^.Paragraphs[ParaIdx].RunCount Do
      Inc(TotLen, Length(Doc^.Paragraphs[ParaIdx].Runs[K].Text));
     { Boucle de placement : la limite reelle est ShortString (ParaText        }
     { concatene tous les runs en un String de 255 max). Quand le total du     }
     { paragraphe approche 240, on cree un sous-paragraphe de continuation    }
     { heritant alignement+indent. On preserve la frontiere mot et FirstLine- }
     { Hang := True pour que la continuation reste indentee a la 1re ligne.   }
     While Length(TxtPiece) > 0 Do Begin
      AvailLen := MAX_TEXT_LEN - TotLen;
      TLen := Length(Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text);
      If MAX_TEXT_LEN - TLen < AvailLen Then AvailLen := MAX_TEXT_LEN - TLen;
      If AvailLen <= 0 Then Begin
       If ParaIdx >= MAX_PARAS_PER_DOC Then Break;
       PendingTail := '';
       LastRunText := Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text;
       K := Length(LastRunText);
       If (K > 0) And (LastRunText[K] <> ' ') Then Begin
        M := K;
        While (M > 0) And (LastRunText[M] <> ' ') Do Dec(M);
        If (M > 0) And (M < K) And ((K - M) <= (K Div 2)) Then Begin
         PendingTail := Copy(LastRunText, M + 1, K - M);
         Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text := Copy(LastRunText, 1, M);
        End;
       End;
       K := ParaIdx;
       Doc^.Paragraphs[K].ContinuesNext := True;
       Inc(ParaIdx);
       Doc^.Paragraphs[ParaIdx].Alignment       := Doc^.Paragraphs[K].Alignment;
       Doc^.Paragraphs[ParaIdx].LeftIndent      := Doc^.Paragraphs[K].LeftIndent;
       { FirstLineHang := True => la 1re ligne du sous-paragraphe est aussi
         }
       { indentee au LeftIndent (pas de bullet en tete),
         preservant l'aspect    }
       { d'une liste continuee.
         }
       Doc^.Paragraphs[ParaIdx].FirstLineHang   := Doc^.Paragraphs[K].LeftIndent >
         0;
       Doc^.Paragraphs[ParaIdx].PageBreakBefore := False;
       Doc^.Paragraphs[ParaIdx].ContinuesPrev   := True;
       Doc^.Paragraphs[ParaIdx].RunCount        := 1;
       RunIdx := 1;
       Doc^.Paragraphs[ParaIdx].Runs[1].Text    := PendingTail;
       Doc^.Paragraphs[ParaIdx].Runs[1].Style.Style    := RunSty Or ParaForceSty;
       If ParaForceSize > 0 Then
        Doc^.Paragraphs[ParaIdx].Runs[1].Style.FontSize := ParaForceSize
       Else
        Doc^.Paragraphs[ParaIdx].Runs[1].Style.FontSize := RunSize;
       Doc^.Paragraphs[ParaIdx].Runs[1].Style.Color    := RunColor;
       TotLen   := Length(PendingTail);
       AvailLen := MAX_TEXT_LEN - TotLen;
      End;
      If Length(TxtPiece) <= AvailLen Then Begin
       Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text :=
        Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text + TxtPiece;
       Inc(TotLen, Length(TxtPiece));
       TxtPiece := '';
      End Else Begin
       { Reculer jusqu'au dernier espace pour ne pas couper un mot. }
       K := AvailLen;
       While (K > 1) And (TxtPiece[K] <> ' ') Do Dec(K);
       If K <= 1 Then K := AvailLen;  { aucun espace trouve : on coupe quand
         meme }
       Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text :=
        Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text + Copy(TxtPiece, 1, K);
       Inc(TotLen, K);
       TxtPiece := Copy(TxtPiece, K + 1, Length(TxtPiece));
      End;
     End;
    End;
   End;

  End;
 Until TokKind = DTK_EOF;

 FreeMem(Buf, Size);

 If ParaIdx = 0 Then Begin
  ParaIdx := 1;
  Doc^.Paragraphs[1].Alignment := ALIGN_LEFT;
  Doc^.Paragraphs[1].RunCount := 1;
  Doc^.Paragraphs[1].Runs[1].Text := '';
  Doc^.Paragraphs[1].Runs[1].Style.Style    := 0;
  Doc^.Paragraphs[1].Runs[1].Style.FontSize := 12;
  Doc^.Paragraphs[1].Runs[1].Style.Color    := Black;
 End;
 Doc^.ParaCount  := ParaIdx;
 Doc^.FileName   := FName;
 Doc^.Modified   := False;
 Cursor.ParaIdx := 1; Cursor.RunIdx := 1; Cursor.CharIdx := 0;
 ScrollY := 0; CurrentPage := 1; NeedsRelayout := True;
 DocxFreeImgs;
 LoadDocxFromFile := OK;
End;

{ ---------- Dispatch par extension ---------- }

Function ExtIsDocx(Const FN: String): Boolean;
Var L: Integer; E: String;
Begin
 ExtIsDocx := False;
 L := Length(FN);
 If L < 5 Then Exit;
 E := Copy(FN, L - 4, 5);
 If (UpCase(E[1]) = '.') And (UpCase(E[2]) = 'D') And
    (UpCase(E[3]) = 'O') And (UpCase(E[4]) = 'C') And
    (UpCase(E[5]) = 'X') Then ExtIsDocx := True;
End;

Procedure EnsureDocExt(Var FN: String; WantDocx: Boolean);
Var I, DotPos : Integer;
Begin
 DotPos := 0;
 For I := Length(FN) Downto 1 Do
  If FN[I] = '.' Then Begin DotPos := I; Break; End;
 If DotPos = 0 Then Begin
  If WantDocx Then FN := FN + '.DOCX' Else FN := FN + '.WPD';
 End;
End;

{ ============================================================ }
{ ===================  PHASE 9 - DOC CFBF  =================== }
{ ============================================================ }
{ Lecture seule de fichiers .DOC Word 97-2003 :                 }
{   - Parseur Compound File Binary Format (CFBF / OLE2)         }
{   - Extraction du texte via la table de pieces (CLX) du FIB   }
{   - Pieces compressees (CP1252, 1 octet/char) ou UTF-16       }
{   - Conversion en paragraphes (separateur #13)                }
{   - #12 = saut de page, #11 = saut de ligne -> espace         }
{   - Formatage (gras/italique/taille) NON preserve             }
{ ============================================================ }

Const
 CFB_DIFSECT    = LongInt($FFFFFFFC);
 CFB_FATSECT    = LongInt($FFFFFFFD);
 CFB_ENDOFCHAIN = LongInt($FFFFFFFE);
 CFB_FREESECT   = LongInt($FFFFFFFF);
 CFB_MAX_DIRS   = 256;

Type
 TCfbDir = Record
  Name    : String[32];
  ObjType : Byte;
  StartSec: LongInt;
  SizeLo  : LongInt;
 End;

Var
 CfbF       : File;
 CfbFOpen   : Boolean;
 CfbSecSize : LongInt;
 CfbMiniSz  : LongInt;
 CfbDirFirst: LongInt;
 CfbMiniCut : LongInt;
 CfbMFATFst : LongInt;
 CfbMFATCnt : LongInt;
 CfbDIFFst  : LongInt;
 CfbDIFCnt  : LongInt;
 CfbFATNum  : LongInt;
 CfbFAT     : Pointer;
 CfbFATLen  : LongInt;
 CfbMFAT    : Pointer;
 CfbMFATLen : LongInt;
 CfbMini    : Pointer;
 CfbMiniLen : LongInt;
 CfbDirs    : Array[0..CFB_MAX_DIRS-1] Of TCfbDir;
 CfbDirCnt  : LongInt;

Function PByteAt(P: Pointer; Ofs: LongInt): Byte;
Var Pp: ^Byte;
Begin
 Pp := P; Inc(Pp, Ofs); PByteAt := Pp^;
End;

Function CfbBufU16(P: Pointer; Ofs: LongInt): Word;
Var Pp: ^Byte; A, B: Word;
Begin
 Pp := P; Inc(Pp, Ofs);
 A := Word(Pp^); Inc(Pp); B := Word(Pp^);
 CfbBufU16 := A Or (B Shl 8);
End;

Function CfbBufU32(P: Pointer; Ofs: LongInt): Cardinal;
Var Pp: ^Byte; A, B, C, D: Cardinal;
Begin
 Pp := P; Inc(Pp, Ofs);
 A := Cardinal(Pp^); Inc(Pp);
 B := Cardinal(Pp^); Inc(Pp);
 C := Cardinal(Pp^); Inc(Pp);
 D := Cardinal(Pp^);
 CfbBufU32 := A Or (B Shl 8) Or (C Shl 16) Or (D Shl 24);
End;

Function CfbFATEntry(Idx: LongInt): Cardinal;
Var Pp: ^Byte;
Begin
 If (Idx < 0) Or (Idx >= CfbFATLen) Then Begin
  CfbFATEntry := Cardinal(CFB_FREESECT); Exit;
 End;
 Pp := CfbFAT; Inc(Pp, Idx * 4);
 CfbFATEntry := CfbBufU32(Pp, 0);
End;

Function CfbMFATEntry(Idx: LongInt): Cardinal;
Var Pp: ^Byte;
Begin
 If (Idx < 0) Or (Idx >= CfbMFATLen) Then Begin
  CfbMFATEntry := Cardinal(CFB_FREESECT); Exit;
 End;
 Pp := CfbMFAT; Inc(Pp, Idx * 4);
 CfbMFATEntry := CfbBufU32(Pp, 0);
End;

Procedure CfbReadSector(SecNum: LongInt; Buf: Pointer);
Var Offs: LongInt;
Begin
 Offs := (SecNum + 1) * CfbSecSize;
 {$I-} Seek(CfbF, Offs); {$I+}
 If IOResult <> 0 Then Exit;
 {$I-} BlockRead(CfbF, Buf^, CfbSecSize); {$I+}
 If IOResult <> 0 Then ;
End;

Function CfbReadFATChain(StartSec: LongInt; TotalSize: LongInt;
                         Var Buf: Pointer): Boolean;
Var
 Cur     : Cardinal;
 Pos     : LongInt;
 Chunk   : LongInt;
 SecBuf  : Pointer;
 OutP    : ^Byte;
 Safety  : LongInt;
Begin
 CfbReadFATChain := False;
 If TotalSize <= 0 Then Begin Buf := Nil; CfbReadFATChain := True; Exit; End;
 GetMem(Buf, TotalSize);
 GetMem(SecBuf, CfbSecSize);
 Cur := Cardinal(StartSec);
 Pos := 0; Safety := 0;
 OutP := Buf;
 While (Pos < TotalSize) And
       (Cur <> Cardinal(CFB_ENDOFCHAIN)) And
       (Cur <> Cardinal(CFB_FREESECT)) Do Begin
  CfbReadSector(LongInt(Cur), SecBuf);
  Chunk := CfbSecSize;
  If Pos + Chunk > TotalSize Then Chunk := TotalSize - Pos;
  Move(SecBuf^, OutP^, Chunk);
  Inc(OutP, Chunk);
  Inc(Pos, Chunk);
  Cur := CfbFATEntry(LongInt(Cur));
  Inc(Safety);
  If Safety > 1048576 Then Begin
   FreeMem(SecBuf, CfbSecSize); FreeMem(Buf, TotalSize); Buf := Nil; Exit;
  End;
 End;
 FreeMem(SecBuf, CfbSecSize);
 If Pos < TotalSize Then Begin
  FreeMem(Buf, TotalSize); Buf := Nil; Exit;
 End;
 CfbReadFATChain := True;
End;

Function CfbReadMiniChain(StartSec: LongInt; TotalSize: LongInt;
                          Var Buf: Pointer): Boolean;
Var
 Cur     : Cardinal;
 Pos     : LongInt;
 Chunk   : LongInt;
 SrcP    : ^Byte;
 OutP    : ^Byte;
 Safety  : LongInt;
Begin
 CfbReadMiniChain := False;
 If TotalSize <= 0 Then Begin Buf := Nil; CfbReadMiniChain := True; Exit; End;
 If CfbMini = Nil Then Exit;
 GetMem(Buf, TotalSize);
 Cur := Cardinal(StartSec);
 Pos := 0; Safety := 0;
 OutP := Buf;
 While (Pos < TotalSize) And
       (Cur <> Cardinal(CFB_ENDOFCHAIN)) And
       (Cur <> Cardinal(CFB_FREESECT)) Do Begin
  If LongInt(Cur) * CfbMiniSz + CfbMiniSz > CfbMiniLen Then Begin
   FreeMem(Buf, TotalSize); Buf := Nil; Exit;
  End;
  SrcP := CfbMini; Inc(SrcP, LongInt(Cur) * CfbMiniSz);
  Chunk := CfbMiniSz;
  If Pos + Chunk > TotalSize Then Chunk := TotalSize - Pos;
  Move(SrcP^, OutP^, Chunk);
  Inc(OutP, Chunk);
  Inc(Pos, Chunk);
  Cur := CfbMFATEntry(LongInt(Cur));
  Inc(Safety);
  If Safety > 1048576 Then Begin
   FreeMem(Buf, TotalSize); Buf := Nil; Exit;
  End;
 End;
 If Pos < TotalSize Then Begin
  FreeMem(Buf, TotalSize); Buf := Nil; Exit;
 End;
 CfbReadMiniChain := True;
End;

Procedure CfbCleanup;
Begin
 If CfbFAT  <> Nil Then Begin FreeMem(CfbFAT,  CfbFATLen * 4);  CfbFAT  := Nil;
   End;
 If CfbMFAT <> Nil Then Begin FreeMem(CfbMFAT, CfbMFATLen * 4); CfbMFAT := Nil;
   End;
 If CfbMini <> Nil Then Begin FreeMem(CfbMini, CfbMiniLen);     CfbMini := Nil;
   End;
 CfbFATLen := 0; CfbMFATLen := 0; CfbMiniLen := 0;
 CfbDirCnt := 0;
 If CfbFOpen Then Begin
  {$I-} Close(CfbF); {$I+}
  If IOResult <> 0 Then ;
  CfbFOpen := False;
 End;
End;

Function CfbOpenFile(Const FName: String): Boolean;
Var
 Hdr        : Array[0..511] Of Byte;
 I, J       : LongInt;
 DifSectors : Array[0..1023] Of LongInt;
 DifSectCnt : LongInt;
 DIFCount   : LongInt;
 Buf        : Pointer;
 DirBuf     : Pointer;
 DirEntries : LongInt;
 EntryP     : ^Byte;
 NameLen    : Word;
 K          : LongInt;
 M          : Byte;
 RootStart  : LongInt;
 RootSize   : LongInt;
 NextDifSec : Cardinal;
 PFat       : ^Byte;
Begin
 CfbOpenFile := False;
 CfbFAT := Nil; CfbMFAT := Nil; CfbMini := Nil; CfbFOpen := False;
 CfbFATLen := 0; CfbMFATLen := 0; CfbMiniLen := 0; CfbDirCnt := 0;

 {$I-} Assign(CfbF, FName); Reset(CfbF, 1); {$I+}
 If IOResult <> 0 Then Exit;
 CfbFOpen := True;
 {$I-} BlockRead(CfbF, Hdr, 512); {$I+}
 If IOResult <> 0 Then Begin CfbCleanup; Exit; End;

 If (Hdr[0] <> $D0) Or (Hdr[1] <> $CF) Or (Hdr[2] <> $11) Or (Hdr[3] <> $E0) Or
    (Hdr[4] <> $A1) Or (Hdr[5] <> $B1) Or (Hdr[6] <> $1A) Or (Hdr[7] <> $E1)
      Then Begin
  CfbCleanup; Exit;
 End;

 CfbSecSize  := LongInt(1) Shl CfbBufU16(@Hdr, 30);
 CfbMiniSz   := LongInt(1) Shl CfbBufU16(@Hdr, 32);
 CfbFATNum   := LongInt(CfbBufU32(@Hdr, 44));
 CfbDirFirst := LongInt(CfbBufU32(@Hdr, 48));
 CfbMiniCut  := LongInt(CfbBufU32(@Hdr, 56));
 CfbMFATFst  := LongInt(CfbBufU32(@Hdr, 60));
 CfbMFATCnt  := LongInt(CfbBufU32(@Hdr, 64));
 CfbDIFFst   := LongInt(CfbBufU32(@Hdr, 68));
 CfbDIFCnt   := LongInt(CfbBufU32(@Hdr, 72));

 If (CfbSecSize <> 512) And (CfbSecSize <> 4096) Then Begin CfbCleanup; Exit;
   End;
 If CfbMiniSz <> 64 Then Begin CfbCleanup; Exit; End;
 If (CfbFATNum <= 0) Or (CfbFATNum > 100000) Then Begin CfbCleanup; Exit; End;

 DifSectCnt := 0;
 For I := 0 To 108 Do Begin
  J := LongInt(CfbBufU32(@Hdr, 76 + I * 4));
  If (Cardinal(J) <> Cardinal(CFB_FREESECT)) And (DifSectCnt < 1024) Then Begin
   DifSectors[DifSectCnt] := J; Inc(DifSectCnt);
  End;
 End;

 NextDifSec := Cardinal(CfbDIFFst);
 GetMem(Buf, CfbSecSize);
 While (NextDifSec <> Cardinal(CFB_ENDOFCHAIN)) And
       (NextDifSec <> Cardinal(CFB_FREESECT)) And
       (DifSectCnt < 1024) Do Begin
  CfbReadSector(LongInt(NextDifSec), Buf);
  DIFCount := (CfbSecSize Div 4) - 1;
  For I := 0 To DIFCount - 1 Do Begin
   J := LongInt(CfbBufU32(Buf, I * 4));
   If (Cardinal(J) <> Cardinal(CFB_FREESECT)) And (DifSectCnt < 1024) Then Begin
    DifSectors[DifSectCnt] := J; Inc(DifSectCnt);
   End;
  End;
  NextDifSec := CfbBufU32(Buf, DIFCount * 4);
 End;
 FreeMem(Buf, CfbSecSize);

 CfbFATLen := DifSectCnt * (CfbSecSize Div 4);
 If CfbFATLen <= 0 Then Begin CfbCleanup; Exit; End;
 GetMem(CfbFAT, CfbFATLen * 4);
 GetMem(Buf, CfbSecSize);
 PFat := CfbFAT;
 For I := 0 To DifSectCnt - 1 Do Begin
  CfbReadSector(DifSectors[I], Buf);
  Move(Buf^, PFat^, CfbSecSize);
  Inc(PFat, CfbSecSize);
 End;
 FreeMem(Buf, CfbSecSize);

 If (CfbMFATCnt > 0) And (CfbMFATFst >= 0) Then Begin
  CfbMFATLen := CfbMFATCnt * (CfbSecSize Div 4);
  GetMem(CfbMFAT, CfbMFATLen * 4);
  GetMem(Buf, CfbSecSize);
  PFat := CfbMFAT;
  J := CfbMFATFst;
  I := 0;
  While (I < CfbMFATCnt) And (Cardinal(J) <> Cardinal(CFB_ENDOFCHAIN)) And
        (Cardinal(J) <> Cardinal(CFB_FREESECT)) Do Begin
   CfbReadSector(J, Buf);
   Move(Buf^, PFat^, CfbSecSize);
   Inc(PFat, CfbSecSize);
   J := LongInt(CfbFATEntry(J));
   Inc(I);
  End;
  FreeMem(Buf, CfbSecSize);
 End Else Begin
  CfbMFAT := Nil; CfbMFATLen := 0;
 End;

 { Lecture du repertoire (limite a CFB_MAX_DIRS entrees) }
 If Not CfbReadFATChain(CfbDirFirst, 128 * CFB_MAX_DIRS, DirBuf) Then Begin
  If Not CfbReadFATChain(CfbDirFirst, 4 * CfbSecSize, DirBuf) Then Begin
   CfbCleanup; Exit;
  End;
  DirEntries := (4 * CfbSecSize) Div 128;
 End Else
  DirEntries := CFB_MAX_DIRS;

 If DirEntries > CFB_MAX_DIRS Then DirEntries := CFB_MAX_DIRS;
 CfbDirCnt := 0;
 EntryP := DirBuf;
 RootStart := -1; RootSize := 0;
 For I := 0 To DirEntries - 1 Do Begin
  NameLen := CfbBufU16(EntryP, 64);
  CfbDirs[I].ObjType := PByteAt(EntryP, 66);
  CfbDirs[I].StartSec := LongInt(CfbBufU32(EntryP, 116));
  CfbDirs[I].SizeLo   := LongInt(CfbBufU32(EntryP, 120));
  CfbDirs[I].Name := '';
  If NameLen > 64 Then NameLen := 64;
  If NameLen >= 2 Then Dec(NameLen, 2);
  K := 0;
  While K < (NameLen Div 2) Do Begin
   M := PByteAt(EntryP, K * 2);
   If (M >= 32) And (M < 128) And (Length(CfbDirs[I].Name) < 32) Then
    CfbDirs[I].Name := CfbDirs[I].Name + Char(M)
   Else If (Length(CfbDirs[I].Name) < 32) Then
    CfbDirs[I].Name := CfbDirs[I].Name + '?';
   Inc(K);
  End;
  If CfbDirs[I].ObjType = 5 Then Begin
   RootStart := CfbDirs[I].StartSec;
   RootSize  := CfbDirs[I].SizeLo;
  End;
  Inc(CfbDirCnt);
  Inc(EntryP, 128);
 End;
 FreeMem(DirBuf, 128 * DirEntries);

 If (RootStart >= 0) And (RootSize > 0) Then Begin
  If Not CfbReadFATChain(RootStart, RootSize, CfbMini) Then Begin
   CfbMini := Nil; CfbMiniLen := 0;
  End Else
   CfbMiniLen := RootSize;
 End Else Begin
  CfbMini := Nil; CfbMiniLen := 0;
 End;

 CfbOpenFile := True;
End;

Function CfbFindStream(Const Name: String): LongInt;
Var I, K: LongInt; Match: Boolean;
Begin
 CfbFindStream := -1;
 For I := 0 To CfbDirCnt - 1 Do Begin
  If CfbDirs[I].ObjType <> 2 Then Continue;
  If Length(CfbDirs[I].Name) <> Length(Name) Then Continue;
  Match := True;
  For K := 1 To Length(Name) Do
   If CfbDirs[I].Name[K] <> Name[K] Then Begin Match := False; Break; End;
  If Match Then Begin CfbFindStream := I; Exit; End;
 End;
End;

Function CfbReadStreamByDir(Idx: LongInt; Var Buf: Pointer): LongInt;
Var Size: LongInt;
Begin
 CfbReadStreamByDir := 0; Buf := Nil;
 If (Idx < 0) Or (Idx >= CfbDirCnt) Then Exit;
 Size := CfbDirs[Idx].SizeLo;
 If Size <= 0 Then Exit;
 If Size < CfbMiniCut Then Begin
  If Not CfbReadMiniChain(CfbDirs[Idx].StartSec, Size, Buf) Then Exit;
 End Else Begin
  If Not CfbReadFATChain(CfbDirs[Idx].StartSec, Size, Buf) Then Exit;
 End;
 CfbReadStreamByDir := Size;
End;

{ ---------- DOC : extraction du texte via la piece table ---------- }

Procedure DocStartFirstPara(Var ParaIdx, RunIdx: Integer;
  Var PendingPB: Boolean);
Begin
 ParaIdx := 1;
 Doc^.Paragraphs[1].Alignment := ALIGN_LEFT;
 Doc^.Paragraphs[1].PageBreakBefore := PendingPB; PendingPB := False;
 Doc^.Paragraphs[1].RunCount := 1;
 Doc^.Paragraphs[1].Runs[1].Text := '';
 Doc^.Paragraphs[1].Runs[1].Style.Style    := 0;
 Doc^.Paragraphs[1].Runs[1].Style.FontSize := 12;
 Doc^.Paragraphs[1].Runs[1].Style.Color    := Black;
 RunIdx := 1;
End;

Procedure DocAppendCh(Var ParaIdx, RunIdx: Integer; Var PendingPB: Boolean;
  C: Char);
Var L: Integer;
Begin
 If ParaIdx = 0 Then DocStartFirstPara(ParaIdx, RunIdx, PendingPB);
 L := Length(Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text);
 If L < MAX_TEXT_LEN Then
  Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text :=
   Doc^.Paragraphs[ParaIdx].Runs[RunIdx].Text + C
 Else Begin
  If ParaIdx >= MAX_PARAS_PER_DOC Then Exit;
  Inc(ParaIdx);
  Doc^.Paragraphs[ParaIdx].Alignment := ALIGN_LEFT;
  Doc^.Paragraphs[ParaIdx].PageBreakBefore := False;
  Doc^.Paragraphs[ParaIdx].RunCount := 1;
  Doc^.Paragraphs[ParaIdx].Runs[1].Text := C;
  Doc^.Paragraphs[ParaIdx].Runs[1].Style.Style    := 0;
  Doc^.Paragraphs[ParaIdx].Runs[1].Style.FontSize := 12;
  Doc^.Paragraphs[ParaIdx].Runs[1].Style.Color    := Black;
  RunIdx := 1;
 End;
End;

Procedure DocFinishParaP(Var ParaIdx, RunIdx: Integer; Var PendingPB: Boolean);
Begin
 If ParaIdx = 0 Then DocStartFirstPara(ParaIdx, RunIdx, PendingPB);
 If ParaIdx >= MAX_PARAS_PER_DOC Then Exit;
 Inc(ParaIdx);
 Doc^.Paragraphs[ParaIdx].Alignment := ALIGN_LEFT;
 Doc^.Paragraphs[ParaIdx].PageBreakBefore := PendingPB; PendingPB := False;
 Doc^.Paragraphs[ParaIdx].RunCount := 1;
 Doc^.Paragraphs[ParaIdx].Runs[1].Text := '';
 Doc^.Paragraphs[ParaIdx].Runs[1].Style.Style    := 0;
 Doc^.Paragraphs[ParaIdx].Runs[1].Style.FontSize := 12;
 Doc^.Paragraphs[ParaIdx].Runs[1].Style.Color    := Black;
 RunIdx := 1;
End;

Procedure DocProcessW(Var ParaIdx, RunIdx: Integer; Var PendingPB: Boolean;
  W: Word);
Begin
 Case W Of
  13 : DocFinishParaP(ParaIdx, RunIdx, PendingPB);
  12 : Begin PendingPB := True;
        DocFinishParaP(ParaIdx, RunIdx, PendingPB);
       End;
  9  : DocAppendCh(ParaIdx, RunIdx, PendingPB, ' ');
  11 : DocAppendCh(ParaIdx, RunIdx, PendingPB, ' ');
  7, 14, 19, 20, 21 : ;   { marqueurs cellule/champ ignores }
  $2013, $2014 : DocAppendCh(ParaIdx, RunIdx, PendingPB, '-');
  $2018, $2019 : DocAppendCh(ParaIdx, RunIdx, PendingPB, #39);
  $201C, $201D : DocAppendCh(ParaIdx, RunIdx, PendingPB, '"');
  $00A0       : DocAppendCh(ParaIdx, RunIdx, PendingPB, ' ');
 Else
  If (W >= 32) And (W < 256) Then
   DocAppendCh(ParaIdx, RunIdx, PendingPB, Char(W))
  Else If W >= 256 Then
   DocAppendCh(ParaIdx, RunIdx, PendingPB, '?');
 End;
End;

Function LoadDocFromFile(Const FName: String): Boolean;
Var
 WDIdx, TBIdx : LongInt;
 WDBuf, TBBuf : Pointer;
 WDSize, TBSize : LongInt;
 TableName    : String;
 WIdent       : Word;
 FibFlags     : Word;
 FWhichTbl    : Boolean;
 CbRgFcLcb    : Word;
 FCLcbOffset  : LongInt;
 FcClx, LcbClx: LongInt;
 ClxP         : ^Byte;
 ClxOff       : LongInt;
 PcdtOff      : LongInt;
 LcbPlcfPcd   : LongInt;
 NPieces      : LongInt;
 CPs          : Array[0..512] Of LongInt;
 I            : LongInt;
 PcdP         : ^Byte;
 FcRaw        : Cardinal;
 Compressed   : Boolean;
 FcReal       : LongInt;
 CPStart, CPEnd : LongInt;
 PieceLen     : LongInt;
 ByteLen      : LongInt;
 SrcP         : ^Byte;
 ParaIdx, RunIdx : Integer;
 PendingPB    : Boolean;
 K            : LongInt;
 W            : Word;
 PcdEntryOff  : LongInt;
Begin
 LoadDocFromFile := False;
 If Not CfbOpenFile(FName) Then Exit;

 WDIdx := CfbFindStream('WordDocument');
 If WDIdx < 0 Then Begin CfbCleanup; Exit; End;
 WDSize := CfbReadStreamByDir(WDIdx, WDBuf);
 If (WDSize < 158) Or (WDBuf = Nil) Then Begin
  If WDBuf <> Nil Then FreeMem(WDBuf, WDSize);
  CfbCleanup; Exit;
 End;

 WIdent := CfbBufU16(WDBuf, 0);
 If (WIdent <> $A5EC) And (WIdent <> $A5DC) And (WIdent <> $A699) Then Begin
  FreeMem(WDBuf, WDSize); CfbCleanup; Exit;
 End;

 FibFlags := CfbBufU16(WDBuf, 10);
 FWhichTbl := (FibFlags And $0200) <> 0;
 If FWhichTbl Then TableName := '1Table' Else TableName := '0Table';

 TBIdx := CfbFindStream(TableName);
 If TBIdx < 0 Then Begin
  If FWhichTbl Then TableName := '0Table' Else TableName := '1Table';
  TBIdx := CfbFindStream(TableName);
 End;
 If TBIdx < 0 Then Begin FreeMem(WDBuf, WDSize); CfbCleanup; Exit; End;
 TBSize := CfbReadStreamByDir(TBIdx, TBBuf);
 If (TBSize <= 0) Or (TBBuf = Nil) Then Begin
  If TBBuf <> Nil Then FreeMem(TBBuf, TBSize);
  FreeMem(WDBuf, WDSize); CfbCleanup; Exit;
 End;

 { FibRgFcLcb a l'offset 154 pour Word 97-2003 standard }
 CbRgFcLcb := CfbBufU16(WDBuf, 152);
 FCLcbOffset := 154;
 If (CbRgFcLcb <= 33) Or (FCLcbOffset + 33 * 8 + 8 > WDSize) Then Begin
  FreeMem(WDBuf, WDSize); FreeMem(TBBuf, TBSize); CfbCleanup; Exit;
 End;
 FcClx  := LongInt(CfbBufU32(WDBuf, FCLcbOffset + 33 * 8));
 LcbClx := LongInt(CfbBufU32(WDBuf, FCLcbOffset + 33 * 8 + 4));

 If (FcClx < 0) Or (LcbClx <= 0) Or (FcClx + LcbClx > TBSize) Then Begin
  FreeMem(WDBuf, WDSize); FreeMem(TBBuf, TBSize); CfbCleanup; Exit;
 End;

 ClxP := TBBuf; Inc(ClxP, FcClx);
 ClxOff := 0;
 PcdtOff := -1;
 While ClxOff < LcbClx Do Begin
  If PByteAt(ClxP, ClxOff) = $01 Then Begin
   If ClxOff + 3 > LcbClx Then Break;
   ByteLen := LongInt(CfbBufU16(ClxP, ClxOff + 1));
   Inc(ClxOff, 3 + ByteLen);
  End Else If PByteAt(ClxP, ClxOff) = $02 Then Begin
   PcdtOff := ClxOff;
   Break;
  End Else
   Break;
 End;

 If (PcdtOff < 0) Or (PcdtOff + 5 > LcbClx) Then Begin
  FreeMem(WDBuf, WDSize); FreeMem(TBBuf, TBSize); CfbCleanup; Exit;
 End;
 LcbPlcfPcd := LongInt(CfbBufU32(ClxP, PcdtOff + 1));
 If (LcbPlcfPcd <= 4) Or (PcdtOff + 5 + LcbPlcfPcd > LcbClx) Then Begin
  FreeMem(WDBuf, WDSize); FreeMem(TBBuf, TBSize); CfbCleanup; Exit;
 End;

 NPieces := (LcbPlcfPcd - 4) Div 12;
 If (NPieces <= 0) Or (NPieces > 512) Then Begin
  FreeMem(WDBuf, WDSize); FreeMem(TBBuf, TBSize); CfbCleanup; Exit;
 End;

 PcdP := ClxP; Inc(PcdP, PcdtOff + 5);
 For I := 0 To NPieces Do
  CPs[I] := LongInt(CfbBufU32(PcdP, I * 4));

 FreeAllDocImages;
 FillChar(Doc^, SizeOf(Doc^), 0);
 Doc^.PageCount := 1;
 ParaIdx := 0; RunIdx := 0; PendingPB := False;

 For I := 0 To NPieces - 1 Do Begin
  CPStart := CPs[I];
  CPEnd   := CPs[I + 1];
  PieceLen := CPEnd - CPStart;
  If PieceLen <= 0 Then Continue;
  PcdEntryOff := (NPieces + 1) * 4 + I * 8;
  FcRaw := CfbBufU32(PcdP, PcdEntryOff + 2);
  Compressed := (FcRaw And Cardinal($40000000)) <> 0;
  If Compressed Then
   FcReal := LongInt((FcRaw And Cardinal($BFFFFFFF)) Shr 1)
  Else
   FcReal := LongInt(FcRaw And Cardinal($BFFFFFFF));
  If Compressed Then ByteLen := PieceLen Else ByteLen := PieceLen * 2;
  If (FcReal < 0) Or (FcReal + ByteLen > WDSize) Then Break;
  SrcP := WDBuf; Inc(SrcP, FcReal);
  If Compressed Then Begin
   For K := 0 To PieceLen - 1 Do Begin
    W := Word(SrcP^);
    DocProcessW(ParaIdx, RunIdx, PendingPB, W);
    Inc(SrcP);
   End;
  End Else Begin
   For K := 0 To PieceLen - 1 Do Begin
    W := Word(SrcP^) Or (Word(PByteAt(SrcP, 1)) Shl 8);
    DocProcessW(ParaIdx, RunIdx, PendingPB, W);
    Inc(SrcP, 2);
   End;
  End;
  If ParaIdx >= MAX_PARAS_PER_DOC Then Break;
 End;

 FreeMem(WDBuf, WDSize); FreeMem(TBBuf, TBSize); CfbCleanup;

 If ParaIdx = 0 Then DocStartFirstPara(ParaIdx, RunIdx, PendingPB);
 Doc^.ParaCount  := ParaIdx;
 Doc^.FileName   := FName;
 Doc^.Modified   := False;
 Cursor.ParaIdx := 1; Cursor.RunIdx := 1; Cursor.CharIdx := 0;
 ScrollY := 0; CurrentPage := 1; NeedsRelayout := True;
 LoadDocFromFile := True;
End;

Function ExtIsDoc(Const FN: String): Boolean;
Var L: Integer; E: String;
Begin
 ExtIsDoc := False;
 If ExtIsDocx(FN) Then Exit;
 L := Length(FN);
 If L < 4 Then Exit;
 E := Copy(FN, L - 3, 4);
 If (E[1] = '.') And (UpCase(E[2]) = 'D') And
    (UpCase(E[3]) = 'O') And (UpCase(E[4]) = 'C') Then ExtIsDoc := True;
End;

{ PDF text import: unfiltered and FlateDecode streams,
  no external application. }
Function ExtIsPDF(Const FN:String):Boolean;
Var E:String;I:Integer;
Begin
 E:=Copy(FN,Length(FN)-3,4);For I:=1 To Length(E) Do E[I]:=UpCase(E[I]);
 ExtIsPDF:=E='.PDF';
End;

{ PDF object/page reader. Positions stay attached to editable text paragraphs. }
Function LoadPDFfromFile(Const FN:String):Boolean;
Const Limit=16777216;StreamLimit=4194304;MaxObjects=4096;
Type
 TObjectEntry=Record ID:LongInt;Start,Stop,Stream,Count:LongInt;End;
 TPDFUnicodeMap=Array[0..65535] of Word;
 PPDFUnicodeMap=^TPDFUnicodeMap;
 TPDFFontMap=Record ID:Integer;Wide:Boolean;Map:PPDFUnicodeMap;End;
 TNumbers=Array[1..32] of Real;
 TMatrix=Record A,B,C,D,E,F:Real;End;
 TState=Record M:TMatrix;Fill,Stroke:Byte;End;
Var Data,Decoded:Pointer;FileSizePDF,Got:LongInt;F:File;
 Objects:Array[1..MaxObjects] of TObjectEntry;ObjectCount:Integer;
 Pages:Array[1..MAX_PAGES] of Integer;PageCountPDF:Integer;
 NewDoc:^TDocument;Good:Boolean;
 FontMaps:Array[1..64] of
   TPDFFontMap;FontMapCount:Integer;PageNo,ResourceObject:Integer;
 PageW,PageH:Real;
 Function C(Buffer:Pointer;P:LongInt):Char;
 Begin C:=Char(ImgPByteAt(Buffer,P));End;
 Function Hex(Ch:Char):Integer;
 Begin Case Ch Of '0'..'9':Hex:=Ord(Ch)-48;'A'..'F':Hex:=Ord(Ch)-55;
  'a'..'f':Hex:=Ord(Ch)-87;Else Hex:=-1;End;End;
 { One bounded lexical reader, also used for object dictionaries. }
 Function Token(Buffer:Pointer;Var P:LongInt;Stop:LongInt;Var Kind:Char):String;
 Var S:String;Ch:Char;Depth,V,J,H:Integer;
 Begin
  S:='';Kind:=#0;
  While P<Stop Do Begin
   Ch:=C(Buffer,P);
   If Ch='%' Then Begin
    While P<Stop Do Begin Ch:=C(Buffer,P);Inc(P);If Ch in [#10,#13] Then
      Break;End;
   End Else If Ch<=#32 Then Inc(P) Else Break;
  End;
  If P>=Stop Then Begin Token:='';Exit;End;
  Ch:=C(Buffer,P);Inc(P);Kind:=Ch;
  If Ch='(' Then Begin
   Kind:='s';Depth:=1;
   While (P<Stop) and (Depth>0) Do Begin
    Ch:=C(Buffer,P);Inc(P);
    If Ch='\' Then Begin
     If P>=Stop Then Break;Ch:=C(Buffer,P);Inc(P);
     Case Ch Of
      'n':Ch:=#10;'r':Ch:=#13;'t':Ch:=#9;'b':Ch:=#8;'f':Ch:=#12;
      #10:Continue;
      #13:Begin If P<Stop Then If C(Buffer,P)=#10 Then Inc(P);Continue;End;
      '0'..'7':Begin
       V:=Ord(Ch)-48;J:=1;
       While (J<3) and (P<Stop) Do Begin
        Ch:=C(Buffer,P);If Not (Ch in ['0'..'7']) Then Break;
        V:=V*8+Ord(Ch)-48;Inc(P);Inc(J);
       End;Ch:=Char(V and 255);
      End;
     End;
    End Else If Ch='(' Then Inc(Depth)
    Else If Ch=')' Then Begin Dec(Depth);If Depth=0 Then Break;End;
    If Length(S)<240 Then S:=S+Ch Else Good:=False;
   End;
   If Depth<>0 Then Good:=False;
  End Else If Ch='<' Then Begin
   If P<Stop Then If C(Buffer,P)='<' Then Begin Inc(P);Token:='<<';Exit;End;
   Kind:='s';H:=-1;
   While P<Stop Do Begin
    Ch:=C(Buffer,P);Inc(P);If Ch='>' Then Break;
    V:=Hex(Ch);If V<0 Then Continue;
    If H<0 Then H:=V Else Begin
     If Length(S)<240 Then S:=S+Char(H*16+V) Else Good:=False;H:=-1;
    End;
   End;
   If H>=0 Then S:=S+Char(H*16);
  End Else If Ch='>' Then Begin
   S:='>';If P<Stop Then If C(Buffer,P)='>' Then Begin S:='>>';Inc(P);End;
  End Else If Ch in ['[',']','{','}'] Then S:=Ch
  Else Begin
   If Ch='/' Then Begin Kind:='a';S:='';End
   Else Begin Kind:='k';S:=Ch;If Ch in ['0'..'9','-','+','.'] Then
     Kind:='n';End;
   While P<Stop Do Begin
    Ch:=C(Buffer,P);If (Ch<=#32) or (Ch in ['(',')','<','>','[',']','/','%'])
      Then Break;
    If Length(S)<240 Then S:=S+Ch;Inc(P);
   End;
  End;
  Token:=S;
 End;
 Function ObjIndex(ID:LongInt):Integer;
 Var J:Integer;
 Begin ObjIndex:=0;For J:=1 To ObjectCount Do If Objects[J].ID=ID Then
   ObjIndex:=J;End;
 Function Number(Const S:String):Real;
 Var V:Real;Err:Integer;
 Begin Val(S,V,Err);If Err<>0 Then V:=0;Number:=V;End;
 Function KeyAt(Obj:Integer;Const Name:String):LongInt;
 Var P,Stop:LongInt;K:Char;S:String;
 Begin
  KeyAt:=0;If Obj<1 Then Exit;P:=Objects[Obj].Start;Stop:=Objects[Obj].Stop;
  If Objects[Obj].Stream>0 Then Stop:=Objects[Obj].Stream;
  While P<Stop Do Begin
   S:=Token(Data,P,Stop,K);
   If (K='a') and (S=Name) Then Begin KeyAt:=P;Exit;End;
  End;
 End;
 Function RefAt(Var P:LongInt;Stop:LongInt):Integer;
 Var S:String;K:Char;ID:LongInt;
 Begin
  RefAt:=0;S:=Token(Data,P,Stop,K);If K<>'n' Then Exit;ID:=Round(Number(S));
  S:=Token(Data,P,Stop,K);If K<>'n' Then Exit;
  S:=Token(Data,P,Stop,K);If S='R' Then RefAt:=ObjIndex(ID);
 End;
 Function TypeIs(Obj:Integer;Const Name:String):Boolean;
 Var P:LongInt;S:String;K:Char;
 Begin
  TypeIs:=False;P:=KeyAt(Obj,'Type');If P=0 Then Exit;
  S:=Token(Data,P,Objects[Obj].Stop,K);TypeIs:=(K='a') and (S=Name);
 End;
 Procedure VisitPages(Obj,Depth:Integer);
 Var P,Save:LongInt;S:String;K:Char;Child:Integer;
 Begin
  If (Obj=0) or (Depth>32) or (PageCountPDF>=MAX_PAGES) Then Begin
    Good:=False;Exit;End;
  If TypeIs(Obj,'Page') Then Begin
    Inc(PageCountPDF);Pages[PageCountPDF]:=Obj;Exit;End;
  P:=KeyAt(Obj,'Kids');If P=0 Then Exit;
  S:=Token(Data,P,Objects[Obj].Stop,K);If S<>'[' Then Exit;
  While P<Objects[Obj].Stop Do Begin
   Save:=P;S:=Token(Data,P,Objects[Obj].Stop,K);If S=']' Then Break;
   P:=Save;Child:=RefAt(P,Objects[Obj].Stop);If Child=0 Then Break;
   VisitPages(Child,Depth+1);
  End;
 End;
 Function InheritedKey(Obj:Integer;Const Name:String):LongInt;
 Var P:LongInt;Depth:Integer;
 Begin
  InheritedKey:=0;Depth:=0;
  While (Obj>0) and (Depth<32) Do Begin
   P:=KeyAt(Obj,Name);If P>0 Then Begin InheritedKey:=P;Exit;End;
   P:=KeyAt(Obj,'Parent');If P=0 Then Exit;
   Obj:=RefAt(P,FileSizePDF);Inc(Depth);
  End;
 End;
 Function StreamData(Obj:Integer;Var Buffer:Pointer;Var Count:LongInt):Boolean;
 Var P:LongInt;S:String;K:Char;
 Begin
  StreamData:=False;If (Obj<1) or (Objects[Obj].Stream=0) Then Exit;
  Count:=Objects[Obj].Count;Buffer:=Pointer(PtrUInt(Data)+Objects[Obj].Stream);
  P:=KeyAt(Obj,'Filter');
  If P>0 Then Begin
   S:=Token(Data,P,Objects[Obj].Stop,K);
   If S='[' Then S:=Token(Data,P,Objects[Obj].Stop,K);
   If S<>'FlateDecode' Then Exit;
   If Count<6 Then Exit;
   If Not InflateBuf(Pointer(PtrUInt(Buffer)+2),Count-6,Decoded,StreamLimit)
     Then Exit;
   Buffer:=Decoded;Count:=InfOutPos;
  End;
  StreamData:=True;
 End;
 Function StringCode(Const S:String):LongInt;
 Var I:Integer;V:LongInt;
 Begin
  V:=0;For I:=1 To Length(S) Do V:=V*256+Ord(S[I]);StringCode:=V;
 End;
 Procedure ExpandObjectStreams;
 Var I,J,CountObjects:Integer;First,Offset,NextOffset:LongInt;
 P,Count,Base,OldEnd:LongInt;Buffer:Pointer;K:Char;S:String;
 IDs,Offsets:Array[1..MaxObjects] of LongInt;
 Begin
  OldEnd:=ObjectCount;
  For I:=1 To OldEnd Do If TypeIs(I,'ObjStm') Then Begin
   P:=KeyAt(I,'N');If P=0 Then Begin Good:=False;Exit;End;
   S:=Token(Data,P,FileSizePDF,K);CountObjects:=Round(Number(S));
   P:=KeyAt(I,'First');If P=0 Then Begin Good:=False;Exit;End;
   S:=Token(Data,P,FileSizePDF,K);First:=Round(Number(S));
   If (CountObjects<1) or (CountObjects>MaxObjects-ObjectCount) Then Begin
     Good:=False;Exit;End;
   If Not StreamData(I,Buffer,Count) Then Begin Good:=False;Exit;End;
   If (First<0) or (First>=Count) or (Count>Limit-FileSizePDF) Then Begin
     Good:=False;Exit;End;
   Base:=FileSizePDF;Move(Buffer^,Pointer(PtrUInt(Data)+Base)^,Count);
     Inc(FileSizePDF,Count);
   P:=Base;
   For J:=1 To CountObjects Do Begin
    S:=Token(Data,P,Base+First,K);IDs[J]:=Round(Number(S));
    S:=Token(Data,P,Base+First,K);Offsets[J]:=Round(Number(S));
   End;
   For J:=1 To CountObjects Do Begin
    Offset:=Offsets[J];NextOffset:=Count-First;
    If J<CountObjects Then NextOffset:=Offsets[J+1];
    If (Offset<0) or (NextOffset<Offset) or (First+NextOffset>Count) Then Begin
      Good:=False;Exit;End;
    Inc(ObjectCount);
    With Objects[ObjectCount] Do Begin
     ID:=IDs[J];Start:=Base+First+Offset;Stop:=Base+First+NextOffset;Stream:=0;
       Objects[ObjectCount].Count:=0;
    End;
   End;
  End;
 End;
 Procedure PrepareFontMap(Obj:Integer);
 Var P,Count:LongInt;Buffer:Pointer;K:Char;S,A,B,U:String;
 Index:Integer;First,Last,V,Code:LongInt;InChars,InRanges:Boolean;
 Begin
  If FontMapCount>=64 Then Exit;
  If KeyAt(Obj,'BaseFont')=0 Then Exit;
  Inc(FontMapCount);Index:=FontMapCount;FontMaps[Index].ID:=Obj;
  P:=KeyAt(Obj,'Subtype');If P>0 Then Begin
   S:=Token(Data,P,FileSizePDF,K);FontMaps[Index].Wide:=S='Type0';
  End;
  P:=KeyAt(Obj,'ToUnicode');If P=0 Then Exit;
  V:=RefAt(P,FileSizePDF);If Not StreamData(V,Buffer,Count) Then Exit;
  New(FontMaps[Index].Map);FillChar(FontMaps[Index].Map^,SizeOf(TPDFUnicodeMap),
    0);
  P:=0;InChars:=False;InRanges:=False;
  While P<Count Do Begin
   S:=Token(Buffer,P,Count,K);
   If S='beginbfchar' Then InChars:=True
   Else If S='endbfchar' Then InChars:=False
   Else If S='beginbfrange' Then InRanges:=True
   Else If S='endbfrange' Then InRanges:=False
   Else If (K='s') and (InChars or InRanges) Then Begin
    First:=StringCode(S);If (First<0) or (First>65535) Then Continue;
    A:=Token(Buffer,P,Count,K);
    If InChars Then Begin
     V:=StringCode(A);If (V>=0) and (V<=65535) Then
       FontMaps[Index].Map^[First]:=V;
    End Else Begin
     Last:=StringCode(A);B:=Token(Buffer,P,Count,K);
     If (Last<First) or (Last>65535) Then Continue;
     If B='[' Then Begin
      For Code:=First To Last Do Begin
       U:=Token(Buffer,P,Count,K);If K<>'s' Then Break;
       V:=StringCode(U);If (V>=0) and (V<=65535) Then
         FontMaps[Index].Map^[Code]:=V;
      End;
     End Else Begin
      V:=StringCode(B);
      For Code:=First To Last Do If (V+Code-First>=0) and (V+Code-First<=65535)
        Then
       FontMaps[Index].Map^[Code]:=V+Code-First;
     End;
    End;
   End;
  End;
 End;
 Function WinAnsi(W:Word):Char;
 Begin
  If W<=255 Then WinAnsi:=Char(W) Else Case W Of
   $20AC:WinAnsi:=#128;$201A:WinAnsi:=#130;$0192:WinAnsi:=#131;
     $201E:WinAnsi:=#132;
   $2026:WinAnsi:=#133;$2020:WinAnsi:=#134;$2021:WinAnsi:=#135;
     $02C6:WinAnsi:=#136;
   $2030:WinAnsi:=#137;$0160:WinAnsi:=#138;$2039:WinAnsi:=#139;
     $0152:WinAnsi:=#140;
   $017D:WinAnsi:=#142;$2018:WinAnsi:=#145;$2019:WinAnsi:=#146;
     $201C:WinAnsi:=#147;
   $201D:WinAnsi:=#148;$2022:WinAnsi:=#149;$2013:WinAnsi:=#150;
     $2014:WinAnsi:=#151;
   $02DC:WinAnsi:=#152;$2122:WinAnsi:=#153;$0161:WinAnsi:=#154;
     $203A:WinAnsi:=#155;
   $0153:WinAnsi:=#156;$017E:WinAnsi:=#158;$0178:WinAnsi:=#159;
   Else WinAnsi:='?';End;
 End;
 Procedure FontInfo(Const Name:String;Var Face:String;Var Style:Byte;Var
   MapIndex:Integer);
 Var P,Q,Save:LongInt;S:String;K:Char;Obj,J:Integer;
 Begin
  Face:='Arial';Style:=0;MapIndex:=0;
  { Prefer the resource dictionary of the current page. }
  Obj:=ResourceObject;
  P:=KeyAt(Obj,'Font');
  If P>0 Then Begin
   Save:=P;S:=Token(Data,P,FileSizePDF,K);
   If S<>'<<' Then Begin P:=Save;J:=RefAt(P,FileSizePDF);If J>0 Then
     P:=Objects[J].Start;End;
   For J:=1 To 128 Do Begin
    S:=Token(Data,P,FileSizePDF,K);If S='>>' Then Break;
    If (K='a') and (S=Name) Then Begin
     Obj:=RefAt(P,FileSizePDF);Break;
    End;
   End;
  End;
  For J:=1 To FontMapCount Do If FontMaps[J].ID=Obj Then MapIndex:=J;
  Q:=KeyAt(Obj,'BaseFont');If Q=0 Then Exit;
  S:=Token(Data,Q,FileSizePDF,K);
  If Pos('Bold',S)>0 Then Style:=Style or STY_BOLD;
  If (Pos('Italic',S)>0) or (Pos('Oblique',S)>0) Then Style:=Style or
    STY_ITALIC;
  If Pos('Times',S)>0 Then Face:='Times New Roman'
  Else If Pos('Courier',S)>0 Then Face:='Courier New';
 End;
 Procedure ReadContent(Buffer:Pointer;Count:LongInt);
 Var P:LongInt;K:Char;S,Text,Face,FontName:String;Nums:TNumbers;N,SP:Integer;
 State:TState;Stack:Array[1..32] of TState;MapIndex:Integer;
 Tx,Ty,LX,LY,FS,Leading,Rise:Real;Style:Byte;InText,ArrayText:Boolean;
 PathX1,PathY1,PathX2,PathY2:Real;PathKind:Byte;
 Procedure Transform(X,Y:Real;Var OX,OY:Real);
 Begin
   OX:=State.M.A*X+State.M.C*Y+State.M.E;OY:=State.M.B*X+State.M.D*Y+State.M.F;
   End;
 Procedure ShowText(Const Value:String);
 Var J,PI,W,H,Code,V:Integer;X,Y:Real;S:String;
 Begin
  If Not InText or (Value='') Then Exit;
  If NewDoc^.ParaCount>=MAX_PARAS_PER_DOC Then Begin Good:=False;Exit;End;
  S:=Value;
  If MapIndex>0 Then If FontMaps[MapIndex].Map<>Nil Then Begin
   S:='';J:=1;
   While J<=Length(Value) Do Begin
    Code:=Ord(Value[J]);Inc(J);
    If FontMaps[MapIndex].Wide Then Begin
     If J>Length(Value) Then Break;Code:=Code*256+Ord(Value[J]);Inc(J);
    End;
    V:=FontMaps[MapIndex].Map^[Code];If V=0 Then V:=Code;
    S:=S+WinAnsi(V);
   End;
  End;
  { Simple fonts use WinAnsi. UTF-16 strings are decoded when explicitly marked.
    }
  If (Length(S)>=2) and (S[1]=#$FE) and (S[2]=#$FF) Then Begin
   S:='';J:=3;While J<Length(Value) Do Begin
    If Value[J]=#0 Then S:=S+Value[J+1] Else S:=S+'?';Inc(J,2);
   End;
  End;
  Transform(Tx,Ty+Rise,X,Y);
  Inc(NewDoc^.ParaCount);PI:=NewDoc^.ParaCount;
  H:=Round(Abs(FS*State.M.D)*PAGE_W/PageW);If H<4 Then H:=4;If H>255 Then
    H:=255;
  W:=PDFTextWidth(S,Face,H,Style);
  With NewDoc^.Paragraphs[PI] Do Begin
   RunCount:=1;Runs[1].Text:=S;Runs[1].Style.FontSize:=Round(FS);
   Runs[1].Style.Style:=Style;Runs[1].Style.Color:=State.Fill;
   PDF.Active:=True;PDF.Page:=PageNo;PDF.X:=Round(X*PAGE_W/PageW);
   PDF.Y:=Round((PageH-Y)*PAGE_H/PageH)-Round(H*0.8);
   PDF.Height:=H;PDF.Width:=W;PDF.Face:=Face;
  End;
  Tx:=Tx+W*PageW/PAGE_W;
 End;
 Procedure Graphic(GKind,GColor:Byte);
 Var J,Tmp:Integer;AX,AY,BX,BY:Real;
 Begin
  If NewDoc^.PDFGraphicCount>=2048 Then Begin Good:=False;Exit;End;
  Transform(PathX1,PathY1,AX,AY);Transform(PathX2,PathY2,BX,BY);
  Inc(NewDoc^.PDFGraphicCount);J:=NewDoc^.PDFGraphicCount;
  With NewDoc^.PDFGraphics[J] Do Begin
   Page:=PageNo;Kind:=GKind;Color:=GColor;
   X1:=Round(AX*PAGE_W/PageW);X2:=Round(BX*PAGE_W/PageW);
   Y1:=Round((PageH-AY)*PAGE_H/PageH);Y2:=Round((PageH-BY)*PAGE_H/PageH);
   If (GKind=2) and (Y1>Y2) Then Begin Tmp:=Y1;Y1:=Y2;
    Y2:=Tmp;End;
   If (GKind=2) and (X1>X2) Then Begin
    Tmp:=X1;X1:=X2;X2:=Tmp;End;
  End;
 End;
 Procedure ExecutePDFOperator;
 Var M:TMatrix;AX,AY,BX,BY:Real;
 Begin
  If S='BT' Then Begin InText:=True;Tx:=0;Ty:=0;LX:=0;LY:=0;End
  Else If S='ET' Then InText:=False
  Else If S='q' Then Begin If SP<32 Then Begin Inc(SP);Stack[SP]:=State;End;End
  Else If S='Q' Then Begin If SP>0 Then Begin State:=Stack[SP];Dec(SP);End;End
  Else If (S='cm') and (N>=6) Then Begin
   M:=State.M;
   State.M.A:=Nums[1]*M.A+Nums[2]*M.C;State.M.B:=Nums[1]*M.B+Nums[2]*M.D;
   State.M.C:=Nums[3]*M.A+Nums[4]*M.C;State.M.D:=Nums[3]*M.B+Nums[4]*M.D;
   State.M.E:=Nums[5]*M.A+Nums[6]*M.C+M.E;
     State.M.F:=Nums[5]*M.B+Nums[6]*M.D+M.F;
  End
  Else If (S='Tf') and (N>=1) Then Begin
    FS:=Nums[N];FontInfo(FontName,Face,Style,MapIndex);End
  Else If (S='Tm') and (N>=6) Then Begin
    Tx:=Nums[5];Ty:=Nums[6];LX:=Tx;LY:=Ty;End
  Else If ((S='Td') or (S='TD')) and (N>=2) Then Begin
   LX:=LX+Nums[N-1];LY:=LY+Nums[N];Tx:=LX;Ty:=LY;
   If S='TD' Then Leading:=-Nums[N];
  End
  Else If (S='TL') and (N>0) Then Leading:=Nums[N]
  Else If (S='T*') or (S=#39) or (S='"') Then Begin
   LY:=LY-Leading;Tx:=LX;Ty:=LY;If S<>'T*' Then ShowText(Text);
  End
  Else If S='Tj' Then ShowText(Text)
  Else If (S='Ts') and (N>0) Then Rise:=Nums[N]
  Else If ((S='rg') or (S='RG')) and (N>=3) Then Begin
   If S='rg' Then
     State.Fill:=PDFPalette(Round(Nums[1]*255),Round(Nums[2]*255),
     Round(Nums[3]*255))
   Else
     State.Stroke:=PDFPalette(Round(Nums[1]*255),Round(Nums[2]*255),
     Round(Nums[3]*255));
  End
  Else If ((S='g') or (S='G')) and (N>0) Then Begin
   If S='g' Then
     State.Fill:=PDFPalette(Round(Nums[1]*255),Round(Nums[1]*255),
     Round(Nums[1]*255))
   Else
     State.Stroke:=PDFPalette(Round(Nums[1]*255),Round(Nums[1]*255),
     Round(Nums[1]*255));
  End
  Else If (S='m') and (N>=2) Then Begin
    PathX1:=Nums[1];PathY1:=Nums[2];PathKind:=1;End
  Else If (S='l') and (N>=2) Then Begin
    PathX2:=Nums[1];PathY2:=Nums[2];PathKind:=1;End
  Else If (S='re') and (N>=4) Then Begin
   PathX1:=Nums[1];PathY1:=Nums[2];PathX2:=PathX1+Nums[3];
     PathY2:=PathY1+Nums[4];PathKind:=2;
  End
  Else If (S='S') or (S='s') Then Begin
   If PathKind=1 Then Graphic(1,State.Stroke)
   Else If PathKind=2 Then Begin
    AX:=PathX1;AY:=PathY1;BX:=PathX2;BY:=PathY2;
    PathY2:=AY;Graphic(1,State.Stroke);
    PathX1:=BX;PathY1:=AY;PathY2:=BY;Graphic(1,State.Stroke);
    PathY1:=BY;PathX2:=AX;Graphic(1,State.Stroke);
    PathX1:=AX;PathY2:=AY;Graphic(1,State.Stroke);
    PathX1:=AX;PathY1:=AY;PathX2:=BX;PathY2:=BY;
   End;PathKind:=0;
  End
  Else If (S='f') or (S='f*') or (S='F') Then Begin If PathKind=2 Then
    Graphic(2,State.Fill);PathKind:=0;End;
 End;
 Begin
  FillChar(State,SizeOf(State),0);State.M.A:=1;State.M.D:=1;SP:=0;
  Tx:=0;Ty:=0;LX:=0;LY:=0;FS:=12;Leading:=14;Rise:=0;Style:=0;MapIndex:=0;
    Face:='Arial';
  P:=0;N:=0;InText:=False;ArrayText:=False;Text:='';FontName:='';PathKind:=0;
  While (P<Count) and Good Do Begin
   S:=Token(Buffer,P,Count,K);
   If K='n' Then Begin
    If ArrayText Then Tx:=Tx-Number(S)*FS/1000
    Else If N<32 Then Begin Inc(N);Nums[N]:=Number(S);End;
   End Else If K='a' Then FontName:=S
   Else If K='s' Then Begin If ArrayText Then ShowText(S) Else Text:=S;End
   Else If S='[' Then ArrayText:=True
   Else If S=']' Then ArrayText:=False
   Else Begin ExecutePDFOperator;N:=0;End;
  End;
 End;
 Procedure ReadPage(Obj:Integer);
 Var P,Save:LongInt;S:String;K:Char;J:Integer;Buffer:Pointer;Count:LongInt;
 Procedure ReadOne(ID:Integer);
 Begin
  If Not StreamData(ID,Buffer,Count) Then Begin Good:=False;Exit;End;
  ReadContent(Buffer,Count);
 End;
 Begin
  PageW:=595;PageH:=842;
  P:=InheritedKey(Obj,'MediaBox');
  If P>0 Then Begin
   S:=Token(Data,P,FileSizePDF,K);
   S:=Token(Data,P,FileSizePDF,K);S:=Token(Data,P,FileSizePDF,K);
   S:=Token(Data,P,FileSizePDF,K);PageW:=Number(S);
   S:=Token(Data,P,FileSizePDF,K);PageH:=Number(S);
  End;
  If (PageW<1) or (PageH<1) Then Begin Good:=False;Exit;End;
  ResourceObject:=Obj;P:=InheritedKey(Obj,'Resources');
  If P>0 Then Begin
   Save:=P;S:=Token(Data,P,FileSizePDF,K);
   If S<>'<<' Then Begin P:=Save;J:=RefAt(P,FileSizePDF);If J>0 Then
     ResourceObject:=J;End;
  End;
  P:=KeyAt(Obj,'Contents');If P=0 Then Exit;
  Save:=P;S:=Token(Data,P,FileSizePDF,K);
  If S='[' Then Begin
   While (P<Objects[Obj].Stop) and Good Do Begin
    Save:=P;S:=Token(Data,P,FileSizePDF,K);If S=']' Then Break;
    P:=Save;J:=RefAt(P,FileSizePDF);If J=0 Then Begin
      Good:=False;Break;End;ReadOne(J);
   End;
  End Else Begin P:=Save;J:=RefAt(P,FileSizePDF);ReadOne(J);End;
 End;
Var P,Start,ObjID,LengthPos:LongInt;S,S2,S3:String;K:Char;
 I,J,Catalog:Integer;SwapPara:TParagraph;
Begin
 LoadPDFfromFile:=False;Good:=True;ObjectCount:=0;PageCountPDF:=0;
 FontMapCount:=0;FillChar(FontMaps,SizeOf(FontMaps),0);
 {$I-}Assign(F,FN);Reset(F,1);{$I+}If IOResult<>0 Then Exit;
 FileSizePDF:=FileSize(F);
 If (FileSizePDF<8) or (FileSizePDF>Limit) Then Begin Close(F);Exit;End;
 GetMem(Data,Limit);GetMem(Decoded,StreamLimit);
 {$I-}BlockRead(F,Data^,FileSizePDF,Got);Close(F);{$I+}
 If (IOResult<>0) or (Got<>FileSizePDF) Then Good:=False;
 If Good Then If (C(Data,0)<>'%') or (C(Data,1)<>'P') or (C(Data,2)<>'D') or
   (C(Data,3)<>'F') Then Good:=False;
 P:=0;
 While (P<FileSizePDF) and Good Do Begin
  S:=Token(Data,P,FileSizePDF,K);
  If (K='a') and (S='Encrypt') Then Begin Good:=False;Break;End;
  If K<>'n' Then Continue;
  ObjID:=Round(Number(S));Start:=P;
  S2:=Token(Data,P,FileSizePDF,K);If K<>'n' Then Begin P:=Start;Continue;End;
  S3:=Token(Data,P,FileSizePDF,K);If S3<>'obj' Then Begin P:=Start;Continue;End;
  If ObjectCount>=MaxObjects Then Begin Good:=False;Break;End;
  Inc(ObjectCount);J:=ObjectCount;Objects[J].ID:=ObjID;Objects[J].Start:=P;
  Objects[J].Stream:=0;Objects[J].Count:=0;LengthPos:=0;
  While P<FileSizePDF Do Begin
   S:=Token(Data,P,FileSizePDF,K);
   If (K='a') and (S='Encrypt') Then Good:=False;
   If (K='a') and (S='Length') Then Begin
    Start:=P;S2:=Token(Data,P,FileSizePDF,K);If K='n' Then
      LengthPos:=Round(Number(S2));P:=Start;
   End;
   If S='stream' Then Begin
    If P<FileSizePDF Then If C(Data,P)=#13 Then Inc(P);
    If P<FileSizePDF Then If C(Data,P)=#10 Then Inc(P);
    Objects[J].Stream:=P;
    If (LengthPos>0) and (LengthPos<FileSizePDF-P) Then Begin
     Objects[J].Count:=LengthPos;Inc(P,LengthPos);
    End Else Begin
     Start:=P;
     While P+9<FileSizePDF Do Begin
      If C(Data,P)='e' Then If C(Data,P+1)='n' Then If C(Data,P+2)='d' Then
       If C(Data,P+3)='s' Then If C(Data,P+4)='t' Then Break;
      Inc(P);
     End;
     Objects[J].Count:=P-Start;
    End;
   End;
   If S='endobj' Then Break;
  End;
  Objects[J].Stop:=P;
 End;
 If Good Then ExpandObjectStreams;
 Catalog:=0;
 If Good Then Begin
  For I:=1 To ObjectCount Do If TypeIs(I,'Catalog') Then Catalog:=I;
  If Catalog>0 Then Begin
   P:=KeyAt(Catalog,'Pages');If P>0 Then VisitPages(RefAt(P,FileSizePDF),0);
  End;
  If PageCountPDF=0 Then For I:=1 To ObjectCount Do If TypeIs(I,'Page') Then
    Begin
   If PageCountPDF>=MAX_PAGES Then Begin Good:=False;Break;End;
   Inc(PageCountPDF);Pages[PageCountPDF]:=I;
  End;
 End;
 If Good Then For I:=1 To ObjectCount Do PrepareFontMap(I);
 New(NewDoc);FillChar(NewDoc^,SizeOf(TDocument),0);
 For PageNo:=1 To PageCountPDF Do If Good Then ReadPage(Pages[PageNo]);
 If Good and (NewDoc^.ParaCount>0) Then Begin
  For I:=2 To NewDoc^.ParaCount Do Begin
   J:=I;
   While J>1 Do Begin
    With NewDoc^ Do Begin
     If (Paragraphs[J].PDF.Page>Paragraphs[J-1].PDF.Page) Then Break;
     If Paragraphs[J].PDF.Page=Paragraphs[J-1].PDF.Page Then Begin
      If Paragraphs[J].PDF.Y>Paragraphs[J-1].PDF.Y Then Break;
      If (Paragraphs[J].PDF.Y=Paragraphs[J-1].PDF.Y) and
         (Paragraphs[J].PDF.X>=Paragraphs[J-1].PDF.X) Then Break;
     End;
     SwapPara:=Paragraphs[J];Paragraphs[J]:=Paragraphs[J-1];
       Paragraphs[J-1]:=SwapPara;
    End;Dec(J);
   End;
  End;
  FreeAllDocImages;Doc^:=NewDoc^;Doc^.PDFPageCount:=PageCountPDF;
    Doc^.PageCount:=PageCountPDF;
  Doc^.FileName:='';Doc^.Modified:=True;Cursor.ParaIdx:=1;Cursor.RunIdx:=1;
    Cursor.CharIdx:=0;
  ScrollY:=0;CurrentPage:=1;NeedsRelayout:=True;LoadPDFfromFile:=True;
 End;
 For I:=1 To FontMapCount Do If FontMaps[I].Map<>Nil Then
   Dispose(FontMaps[I].Map);
 Dispose(NewDoc);FreeMem(Decoded,StreamLimit);FreeMem(Data,Limit);
End;

{ ============================================================ }
{ ============  FORMAT GAT (Genesis Ascii Typewriter)  ======= }
{ ============================================================ }
{ Format texte du MonsterBook :                                 }
{   ligne 1 : ': X1 Y1 X2 Y2 [L|R|A|N] [debut] [I]'              }
{             (';' = fichier protege par mot de passe)          }
{   corps   : lignes ASCII (CP437) separees par CR+LF           }
{   octet < 32 : attribut du caractere SUIVANT                  }
{                1=gras 2=souligne 4=italique 8=inverse         }
{                16=double largeur                              }
{   '[AUTEUR:' '[SUJET:' '[TITRE:' '[DESCR:' : proprietes       }
{   '[DC:' '[DD:' '[DG:' : image centree / droite / gauche      }

Const
 GAT_MAXLINE = 1024;
 GAT_DEF_X1  = 10;
 GAT_DEF_X2  = 120;

Type
 TGatBuf  = Array[0..16777215] Of Byte;
 PGatBuf  = ^TGatBuf;

Var
 GatPI        : Integer;       { paragraphe courant (chargement) }
 GatFull      : Boolean;       { limite de paragraphes atteinte }
 GatTruncated : Boolean;       { dernier chargement tronque }
 LnCh         : Array[1..GAT_MAXLINE] Of Char;
 LnAt         : Array[1..GAT_MAXLINE] Of Byte;
 LnN          : Integer;
 GatOutF      : File;
 GatOutBuf    : Array[0..4095] Of Byte;
 GatOutN      : Integer;
 GatOutErr    : Boolean;
 GatChA       : Array[1..8192] Of Char;
 GatAtA       : Array[1..8192] Of Byte;

Function ExtIsGat(Const FN: String): Boolean;
Var L: Integer;
Begin
 ExtIsGat := False;
 L := Length(FN);
 If L < 4 Then Exit;
 ExtIsGat := (FN[L-3] = '.') And (UpCase(FN[L-2]) = 'G') And
             (UpCase(FN[L-1]) = 'A') And (UpCase(FN[L]) = 'T');
End;

Procedure GatNewPara(Align: Byte; Cont: Boolean);
Begin
 If GatPI >= MAX_PARAS_PER_DOC Then Begin GatFull := True; Exit; End;
 Inc(GatPI);
 Doc^.Paragraphs[GatPI].Alignment       := Align;
 Doc^.Paragraphs[GatPI].PageBreakBefore := False;
 Doc^.Paragraphs[GatPI].ContinuesPrev   := Cont;
 Doc^.Paragraphs[GatPI].RunCount        := 1;
 Doc^.Paragraphs[GatPI].Runs[1].Text           := '';
 Doc^.Paragraphs[GatPI].Runs[1].Style.Style    := 0;
 Doc^.Paragraphs[GatPI].Runs[1].Style.FontSize := 12;
 Doc^.Paragraphs[GatPI].Runs[1].Style.Color    := Black;
End;

Procedure GatAddCh(C: Char; Sty, Sz: Byte);
Var P, R: Integer;
Begin
 If GatFull Then Exit;
 P := GatPI;
 R := Doc^.Paragraphs[P].RunCount;
 If Doc^.Paragraphs[P].Runs[R].Text = '' Then Begin
  Doc^.Paragraphs[P].Runs[R].Style.Style    := Sty;
  Doc^.Paragraphs[P].Runs[R].Style.FontSize := Sz;
 End Else If (Doc^.Paragraphs[P].Runs[R].Style.Style <> Sty) Or
             (Doc^.Paragraphs[P].Runs[R].Style.FontSize <> Sz) Then Begin
  If R < MAX_RUNS_PER_PARA Then Begin
   Inc(Doc^.Paragraphs[P].RunCount); R := Doc^.Paragraphs[P].RunCount;
   Doc^.Paragraphs[P].Runs[R].Text           := '';
   Doc^.Paragraphs[P].Runs[R].Style.Style    := Sty;
   Doc^.Paragraphs[P].Runs[R].Style.FontSize := Sz;
   Doc^.Paragraphs[P].Runs[R].Style.Color    := Black;
  End;
 End;
 If Length(Doc^.Paragraphs[P].Runs[R].Text) >= MAX_TEXT_LEN Then Begin
  If R < MAX_RUNS_PER_PARA Then Begin
   Inc(Doc^.Paragraphs[P].RunCount); R := Doc^.Paragraphs[P].RunCount;
   Doc^.Paragraphs[P].Runs[R].Text           := '';
   Doc^.Paragraphs[P].Runs[R].Style.Style    := Sty;
   Doc^.Paragraphs[P].Runs[R].Style.FontSize := Sz;
   Doc^.Paragraphs[P].Runs[R].Style.Color    := Black;
  End Else Begin
   Doc^.Paragraphs[P].ContinuesNext := True;
   GatNewPara(Doc^.Paragraphs[P].Alignment, True);
   If GatFull Then Exit;
   GatAddCh(C, Sty, Sz);
   Exit;
  End;
 End;
 Doc^.Paragraphs[P].Runs[R].Text := Doc^.Paragraphs[P].Runs[R].Text + C;
End;

{ Decode les octets [S,E) en caracteres + attributs (LnCh/LnAt/LnN) }
Procedure GatDecode(B: PGatBuf; S, E: LongInt);
Var I: LongInt; A: Byte;
Begin
 LnN := 0; A := 0; I := S;
 While I < E Do Begin
  If B^[I] < 32 Then A := B^[I]
  Else Begin
   If LnN < GAT_MAXLINE Then Begin
    Inc(LnN); LnCh[LnN] := Char(B^[I]); LnAt[LnN] := A;
   End;
   A := 0;
  End;
  Inc(I);
 End;
End;

Function GatStarts(B: PGatBuf; S, E: LongInt; Const Pat: String): Boolean;
Var I: Integer;
Begin
 GatStarts := False;
 If E - S < Length(Pat) Then Exit;
 For I := 1 To Length(Pat) Do
  If UpCase(Char(B^[S + I - 1])) <> Pat[I] Then Exit;
 GatStarts := True;
End;

Function GatNextNum(B: PGatBuf; Var I: LongInt; E: LongInt): LongInt;
Var V: LongInt; Got: Boolean;
Begin
 V := 0; Got := False;
 While (I < E) And (B^[I] = 32) Do Inc(I);
 While (I < E) And (B^[I] >= 48) And (B^[I] <= 57) Do Begin
  If V < 100000 Then V := V * 10 + (B^[I] - 48);
  Got := True; Inc(I);
 End;
 If Got Then GatNextNum := V Else GatNextNum := -1;
End;

Function GatStyleOf(A: Byte): Byte;
Var S: Byte;
Begin
 S := 0;
 If (A And 1) <> 0 Then S := S Or STY_BOLD;
 If (A And 2) <> 0 Then S := S Or STY_UNDERLINE;
 If (A And 4) <> 0 Then S := S Or STY_ITALIC;
 GatStyleOf := S;
End;

Function GatSizeOf(A: Byte): Byte;
Begin
 If (A And 16) <> 0 Then GatSizeOf := 18 Else GatSizeOf := 12;
End;

Function LoadGpxDocument(Const FName: String): Boolean;
Var Buf, Sc: Pointer; W, H, SW, SH: Integer;
Begin
 LoadGpxDocument := False;
 If Not LoadGPX(FName, Buf, W, H) Then Exit;
 ScaleImageNN(Buf, W, H, Sc, SW, SH);
 FreeMem(Buf, LongInt(W) * H);
 FreeAllDocImages;
 FillChar(Doc^, SizeOf(Doc^), 0);
 Doc^.PageCount := 1;
 Doc^.ParaCount := 2;
 Doc^.Paragraphs[1].Alignment := ALIGN_CENTER;
 Doc^.Paragraphs[1].IsImage := True;
 Doc^.Paragraphs[1].ImgW := SW;
 Doc^.Paragraphs[1].ImgH := SH;
 Doc^.Paragraphs[1].ImgData := Sc;
 Doc^.Paragraphs[2].RunCount := 1;
 Doc^.Paragraphs[2].Runs[1].Text := '';
 Doc^.Paragraphs[2].Runs[1].Style.FontSize := 12;
 Doc^.Paragraphs[2].Runs[1].Style.Color := Black;
 Doc^.FileName := FName;
 Doc^.Modified := False;
 Cursor.ParaIdx := 2; Cursor.RunIdx := 1; Cursor.CharIdx := 0;
 ScrollY := 0; CurrentPage := 1; NeedsRelayout := True;
 LoadGpxDocument := True;
End;

Function ExtIsGpx(Const FN: String): Boolean;
Var L: Integer;
Begin
 ExtIsGpx := False; L := Length(FN);
 If L < 4 Then Exit;
 ExtIsGpx := (FN[L-3] = '.') And (UpCase(FN[L-2]) = 'G') And
             (UpCase(FN[L-1]) = 'P') And (UpCase(FN[L]) = 'X');
End;

{ Recherche l'image d'un '[DC:chemin' : chemin tel quel, sinon nom de
  fichier dans le dossier du .GAT. }
Function GatLoadPicture(Const Path, GatFile: String; Var Buf: Pointer;
                        Var W, H: Integer): Boolean;
Var I, Cut: Integer; Base: String;
Begin
 GatLoadPicture := True;
 If LoadAnyImage(Path, Buf, W, H) Then Exit;
 Cut := 0;
 For I := Length(Path) Downto 1 Do
  If (Path[I] = '\') Or (Path[I] = '/') Or (Path[I] = ':') Then Begin Cut := I;
    Break; End;
 Base := Copy(Path, Cut + 1, 255);
 Cut := 0;
 For I := Length(GatFile) Downto 1 Do
  If (GatFile[I] = '\') Or (GatFile[I] = '/') Then Begin Cut := I; Break; End;
 If LoadAnyImage(Copy(GatFile, 1, Cut) + Base, Buf, W, H) Then Exit;
 GatLoadPicture := False;
End;

Function LoadGatFromFile(Const FName: String): Boolean;
Var
 IBuf, ISc : Pointer;
 IW, IH, ISW, ISH : Integer;
 F        : File;
 Size     : LongInt;
 B        : PGatBuf;
 I, LS, LE, NextLS : LongInt;
 X1, X2, N, Wid : LongInt;
 Lead, Last, K, J, Rel, Wd, EndCol, Spc : Integer;
 Boxy     : Boolean;
 Align    : Byte;
 GatOpen  : Boolean;
 A        : Byte;
 Path     : String;
Begin
 LoadGatFromFile := False;
 GatTruncated := False;
 {$I-} Assign(F, FName); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 Size := FileSize(F);
 If (Size < 3) Or (Size > 16000000) Then Begin
  {$I-} Close(F); {$I+} If IOResult <> 0 Then ;
  Exit;
 End;
 GetMem(B, Size);
 {$I-} BlockRead(F, B^, Size); {$I+}
 If IOResult <> 0 Then Begin
  FreeMem(B, Size); {$I-} Close(F); {$I+} If IOResult <> 0 Then ;
  Exit;
 End;
 {$I-} Close(F); {$I+} If IOResult <> 0 Then ;
 { Signature : ':' = normal ; ';' = protege par mot de passe (non supporte) }
 If B^[0] <> Ord(':') Then Begin FreeMem(B, Size); Exit; End;

 { --- Entete --- }
 LE := 0;
 While (LE < Size) And (B^[LE] <> 10) Do Inc(LE);
 I := 1;
 X1 := GatNextNum(B, I, LE);
 N  := GatNextNum(B, I, LE);      { Y1 }
 X2 := GatNextNum(B, I, LE);
 N  := GatNextNum(B, I, LE);      { Y2 }
 If (X1 < 0) Or (X2 <= X1) Or (X2 > 400) Then Begin X1 := GAT_DEF_X1;
   X2 := GAT_DEF_X2; End;
 Wid := X2 - X1;
 NextLS := LE + 1;

 FreeAllDocImages;
 FillChar(Doc^, SizeOf(Doc^), 0);
 Doc^.PageCount := 1;
 GatPI := 0; GatFull := False; GatOpen := False;

 { --- Corps --- }
 While (NextLS < Size) And (Not GatFull) Do Begin
  LS := NextLS;
  LE := LS;
  While (LE < Size) And (B^[LE] <> 10) Do Inc(LE);
  NextLS := LE + 1;
  If (LE > LS) And (B^[LE - 1] = 13) Then Dec(LE);   { retire le CR }

  { Lignes d'information particuliere : '[...' }
  If (LE > LS) And (B^[LS] = Ord('[')) Then Begin
   If GatStarts(B, LS, LE, '[AUTEUR:') Or GatStarts(B, LS, LE, '[SUJET:') Or
      GatStarts(B, LS, LE, '[TITRE:') Or GatStarts(B, LS, LE,
        '[DESCR:') Then Begin
    GatOpen := False;
    Continue;                                   { proprietes : pas de texte }
   End;
   If GatStarts(B, LS, LE, '[DC:') Or GatStarts(B, LS, LE, '[DD:') Or
      GatStarts(B, LS, LE, '[DG:') Then Begin
    GatOpen := False;
    Path := '';
    J := 0;
    I := LS + 4;
    While (I < LE) And (J < 200) Do Begin
     If B^[I] >= 32 Then Begin Path := Path + Char(B^[I]); Inc(J); End;
     Inc(I);
    End;
    Case UpCase(Char(B^[LS + 2])) Of
     'D': Align := ALIGN_RIGHT;
     'G': Align := ALIGN_LEFT;
    Else  Align := ALIGN_CENTER;
    End;
    GatNewPara(Align, False);
    If GatFull Then Break;
    If GatLoadPicture(Path, FName, IBuf, IW, IH) Then Begin
     ScaleImageNN(IBuf, IW, IH, ISc, ISW, ISH);
     FreeMem(IBuf, LongInt(IW) * IH);
     Doc^.Paragraphs[GatPI].RunCount := 0;
     Doc^.Paragraphs[GatPI].IsImage  := True;
     Doc^.Paragraphs[GatPI].ImgW     := ISW;
     Doc^.Paragraphs[GatPI].ImgH     := ISH;
     Doc^.Paragraphs[GatPI].ImgData  := ISc;
    End Else Begin
     Path := '[Image : ' + Path + ']';
     For J := 1 To Length(Path) Do GatAddCh(Path[J], STY_ITALIC, 12);
    End;
    Continue;
   End;
  End;

  GatDecode(B, LS, LE);

  { Ligne vide }
  Lead := 0;
  While (Lead < LnN) And (LnCh[Lead + 1] = ' ') Do Inc(Lead);
  Last := LnN;
  While (Last > 0) And (LnCh[Last] = ' ') Do Dec(Last);
  If Last <= Lead Then Begin
   GatOpen := False;
   GatNewPara(ALIGN_LEFT, False);
   Continue;
  End;

  { Largeur du texte (les caracteres en double largeur comptent 2) + espaces }
  Wd := 0; Spc := 0; Boxy := False;
  For K := Lead + 1 To Last Do Begin
   Inc(Wd);
   If (LnAt[K] And 16) <> 0 Then Inc(Wd);
   If LnCh[K] = ' ' Then Inc(Spc);
   If (Ord(LnCh[K]) >= 176) And (Ord(LnCh[K]) <= 223) Then Boxy := True;
  End;
  Rel := Lead - X1;
  If Rel < 0 Then Rel := 0;
  EndCol := Lead + Wd;

  { Detection de l'alignement }
  Align := ALIGN_LEFT;
  If (Rel >= 4) And (Abs(Rel - (Wid - Wd) Div 2) <= 2) Then Align :=
    ALIGN_CENTER
  Else If (Rel >= 6) And (Rel + Wd >= Wid - 1) Then Align := ALIGN_RIGHT;

  If GatOpen And (Not Boxy) And (Align = ALIGN_LEFT) And (Rel <= 1) Then Begin
   GatAddCh(' ', 0, 12);                         { suite du paragraphe }
  End Else Begin
   GatNewPara(Align, False);
   If GatFull Then Break;
   If Align = ALIGN_LEFT Then Begin
    If Rel > 60 Then Rel := 60;
    For K := 1 To Rel Do GatAddCh(' ', 0, 12);   { retrait de 1re ligne }
   End;
  End;

  For K := Lead + 1 To Last Do Begin
   If LnCh[K] = ' ' Then Begin
    { l'espace herite du style des voisins s'ils sont identiques }
    A := 0;
    If (K > Lead + 1) And (K < Last) Then Begin
     J := K + 1;
     While (J < Last) And (LnCh[J] = ' ') Do Inc(J);
     If LnAt[K - 1] = LnAt[J] Then A := LnAt[J];
    End;
    GatAddCh(' ', GatStyleOf(A), GatSizeOf(A));
   End Else
    GatAddCh(LnCh[K], GatStyleOf(LnAt[K]), GatSizeOf(LnAt[K]));
  End;

  GatOpen := (Not Boxy) And (Align = ALIGN_LEFT) And (Spc >= 3) And (EndCol >=
    X2 - 16);
 End;

 If NextLS < Size Then GatTruncated := GatFull;
 FreeMem(B, Size);
 If GatPI = 0 Then GatNewPara(ALIGN_LEFT, False);
 Doc^.ParaCount  := GatPI;
 Doc^.FileName   := FName;
 Doc^.Modified   := False;
 Cursor.ParaIdx := 1; Cursor.RunIdx := 1; Cursor.CharIdx := 0;
 ScrollY := 0; CurrentPage := 1; NeedsRelayout := True;
 LoadGatFromFile := True;
End;

{ ---------- Sauvegarde au format GAT ---------- }

Procedure GatFlush;
Begin
 If GatOutN > 0 Then Begin
  {$I-} BlockWrite(GatOutF, GatOutBuf, GatOutN); {$I+}
  If IOResult <> 0 Then GatOutErr := True;
  GatOutN := 0;
 End;
End;

Procedure GatPut(V: Byte);
Begin
 If GatOutN > High(GatOutBuf) Then GatFlush;
 GatOutBuf[GatOutN] := V;
 Inc(GatOutN);
End;

Procedure GatPutStr(Const S: String);
Var I: Integer;
Begin
 For I := 1 To Length(S) Do GatPut(Ord(S[I]));
End;

Procedure GatPutLn;
Begin
 GatPut(13); GatPut(10);
End;

Procedure GatWriteText(N: Integer; Align: Byte);
Var
 Pos, I, Cols, W, LastSp, LineEnd, NextPos, Wid, Wd, Off, Q : Integer;
Begin
 Wid := GAT_DEF_X2 - GAT_DEF_X1;
 If N = 0 Then Begin GatPutLn; Exit; End;
 Pos := 1;
 While Pos <= N Do Begin
  Cols := 0; LastSp := 0; I := Pos;
  While I <= N Do Begin
   W := 1;
   If (GatAtA[I] And 16) <> 0 Then W := 2;
   If Cols + W > Wid Then Break;
   Cols := Cols + W;
   If GatChA[I] = ' ' Then LastSp := I;
   Inc(I);
  End;
  If I > N Then Begin LineEnd := N; NextPos := N + 1; End
  Else If LastSp > Pos Then Begin LineEnd := LastSp - 1; NextPos := LastSp + 1;
    End
  Else Begin
   LineEnd := I - 1; NextPos := I;
   If LineEnd < Pos Then Begin LineEnd := Pos; NextPos := Pos + 1; End;
  End;
  While (LineEnd > Pos) And (GatChA[LineEnd] = ' ') Do Dec(LineEnd);
  Wd := 0;
  For Q := Pos To LineEnd Do Begin
   Inc(Wd);
   If (GatAtA[Q] And 16) <> 0 Then Inc(Wd);
  End;
  Off := 0;
  If Align = ALIGN_CENTER Then Off := (Wid - Wd) Div 2
  Else If Align = ALIGN_RIGHT Then Off := Wid - Wd;
  If Off < 0 Then Off := 0;
  For Q := 1 To GAT_DEF_X1 + Off Do GatPut(32);
  For Q := Pos To LineEnd Do Begin
   If GatAtA[Q] <> 0 Then GatPut(GatAtA[Q]);
   GatPut(Ord(GatChA[Q]));
  End;
  GatPutLn;
  Pos := NextPos;
 End;
End;

Procedure GatWritePara(P: Integer);
Var
 R, I, N, T, RW, CL : Integer;
 A, Sty : Byte;
 S : String;
Begin
 If Doc^.Paragraphs[P].IsImage Then Begin
  S := '[Image]';
  N := 0;
  For I := 1 To Length(S) Do Begin
   Inc(N); GatChA[N] := S[I]; GatAtA[N] := 4;
  End;
  GatWriteText(N, ALIGN_CENTER);
  Exit;
 End;
 If Doc^.Paragraphs[P].TableIdx > 0 Then Begin
  T := Doc^.Paragraphs[P].TableIdx;
  If (P > 1) And (Doc^.Paragraphs[P - 1].TableIdx = T) Then Exit;
  If (T > MAX_TABLES) Or (Not Tables[T].Used) Then Exit;
  For RW := 1 To Tables[T].Rows Do Begin
   N := 0;
   For CL := 1 To Tables[T].Cols Do Begin
    S := Tables[T].Cells[RW, CL];
    If CL > 1 Then S := ' | ' + S;
    For I := 1 To Length(S) Do
     If N < 8192 Then Begin
      Inc(N);
      If Ord(S[I]) < 32 Then GatChA[N] := ' ' Else GatChA[N] := S[I];
      GatAtA[N] := 0;
     End;
   End;
   GatWriteText(N, ALIGN_LEFT);
  End;
  Exit;
 End;
 N := 0;
 For R := 1 To Doc^.Paragraphs[P].RunCount Do Begin
  Sty := Doc^.Paragraphs[P].Runs[R].Style.Style;
  A := 0;
  If (Sty And STY_BOLD) <> 0 Then A := A Or 1;
  If (Sty And STY_UNDERLINE) <> 0 Then A := A Or 2;
  If (Sty And STY_ITALIC) <> 0 Then A := A Or 4;
  If Doc^.Paragraphs[P].Runs[R].Style.FontSize >= 18 Then A := A Or 16;
  S := Doc^.Paragraphs[P].Runs[R].Text;
  For I := 1 To Length(S) Do
   If N < 8192 Then Begin
    Inc(N);
    If Ord(S[I]) < 32 Then Begin GatChA[N] := ' '; GatAtA[N] := 0; End
    Else Begin
     GatChA[N] := S[I];
     If S[I] = ' ' Then GatAtA[N] := 0 Else GatAtA[N] := A;
    End;
   End;
 End;
 GatWriteText(N, Doc^.Paragraphs[P].Alignment);
End;

Function SaveGatToFile(Const FName: String): Boolean;
Var P: Integer;
Begin
 SaveGatToFile := False;
 {$I-} Assign(GatOutF, FName); Rewrite(GatOutF, 1); {$I+}
 If IOResult <> 0 Then Exit;
 GatOutN := 0; GatOutErr := False;
 GatPutStr(': ' + '10 6 120 82 N 0');
 GatPutLn;
 For P := 1 To Doc^.ParaCount Do GatWritePara(P);
 GatFlush;
 {$I-} Close(GatOutF); {$I+}
 If IOResult <> 0 Then GatOutErr := True;
 SaveGatToFile := Not GatOutErr;
End;

Function LoadAnyDocument(Const FName: String): Boolean;
Begin
 If ExtIsGat(FName) Then LoadAnyDocument := LoadGatFromFile(FName)
 Else If ExtIsGpx(FName) Then LoadAnyDocument := LoadGpxDocument(FName)
 Else If ExtIsPDF(FName) Then LoadAnyDocument:=LoadPDFfromFile(FName)
 Else If ExtIsDocx(FName) Then LoadAnyDocument := LoadDocxFromFile(FName)
 Else If ExtIsDoc (FName) Then LoadAnyDocument := LoadDocFromFile(FName)
 Else                          LoadAnyDocument := LoadDocumentFromFile(FName);
End;

Function SaveAnyDocument(Const FName: String): Boolean;
Begin
 If ExtIsGat(FName) Then SaveAnyDocument := SaveGatToFile(FName)
 Else If ExtIsPDF(FName) Then SaveAnyDocument:=False
 Else If ExtIsDocx(FName) Then SaveAnyDocument := SaveDocxToFile(FName)
 Else If ExtIsDoc (FName) Then SaveAnyDocument := False
 Else                          SaveAnyDocument := SaveDocumentToFile(FName);
End;

{ ============================================================ }
{ ===================  PHASE 5 - DIALOGUES  ================== }
{ ============================================================ }

Function ShowConfirmYN(Const Msg: String): Boolean;
Begin
 { OS/2-0 : boite de question de Presentation Manager (Oui / Non) }
 ShowConfirmYN := OsBox('WorDium', Msg, MB_YESNO Or MB_QUERY) = MBID_YES;
 Repeat GetMouseStateLI(MsX, MsY, MsBtn); Until (MsBtn And MB_LEFT) = 0;
 NeedsRedraw := True;
End;

Function ShowFileDialog(Const Title: String; SaveMode: Boolean;
                        Const Filter: String;
                        Var FName: String): Boolean;
Const
 MAX_LIST   = 256;
 LIST_ROWS  = 12;
 ROW_H      = 14;
 MAX_FLTS   = 8;
Var
 X1, Y1, X2, Y2  : Integer;
 LX1, LY1, LX2, LY2 : Integer;
 IX1, IY1, IX2, IY2 : Integer;
 FX1, FY1, FX2, FY2 : Integer;
 OkX1, CnX1, BY1, BY2 : Integer;
 K               : Word;
 OK, Done        : Boolean;
 Files           : Array[1..MAX_LIST] Of String[64];
 FileIsDir       : Array[1..MAX_LIST] Of Boolean;
 FileCount       : Integer;
 Sel, Top        : Integer;
 SR              : SearchRec;
 Inp             : String;
 CurDir          : String;
 DirDisp         : String;
 I, Idx          : Integer;
 FltLabels       : Array[1..MAX_FLTS] Of String[40];
 FltMasks        : Array[1..MAX_FLTS] Of String[80];
 FltCount        : Integer;
 FltCur          : Integer;
 FltDisp         : String;
 LastBtn         : Word;
 NeedRescan      : Boolean;
 FltOpen, FltFocus, MouseConsumed: Boolean;
 FltHover, PopupY1, PopupY2, OldHover: Integer;

 Procedure ParseFilter;
 Var P, L, J: Integer; Seg: String;
 Begin
  FltCount := 0;
  P := 1; L := Length(Filter);
  { Format: Label1|masks1|Label2|masks2|...   ou simple "*.X;*.Y" }
  If Pos('|', Filter) = 0 Then Begin
   FltCount := 1;
   FltLabels[1] := Filter;
   FltMasks[1]  := Filter;
   Exit;
  End;
  While (P <= L) And (FltCount < MAX_FLTS) Do Begin
   J := P;
   While (J <= L) And (Filter[J] <> '|') Do Inc(J);
   Seg := Copy(Filter, P, J - P);
   P := J + 1;
   Inc(FltCount);
   FltLabels[FltCount] := Seg;
   J := P;
   While (J <= L) And (Filter[J] <> '|') Do Inc(J);
   Seg := Copy(Filter, P, J - P);
   P := J + 1;
   FltMasks[FltCount] := Seg;
  End;
 End;

 Procedure NavigateUp;
 Var J, SlashPos: Integer;
 Begin
  { CurDir se termine par '\'. Trouver l'avant-dernier separateur. }
  If Length(CurDir) <= 3 Then Exit;  { 'X:\' = racine }
  SlashPos := 0;
  For J := Length(CurDir) - 1 Downto 1 Do
   If (CurDir[J] = '\') Or (CurDir[J] = '/') Then Begin
    SlashPos := J; Break;
   End;
  If SlashPos > 0 Then
   CurDir := Copy(CurDir, 1, SlashPos);
 End;

 Procedure NavigateInto(Const SubDir: String);
 Begin
  If SubDir = '..' Then Begin NavigateUp; Exit; End;
  If SubDir = '.'  Then Exit;
  CurDir := CurDir + SubDir;
  If (Length(CurDir) > 0) And (CurDir[Length(CurDir)] <> '\') Then
   CurDir := CurDir + '\';
 End;

 Procedure RedrawList;
 Var L, Y : Integer;
 Begin
  FillRectArea(LX1+1, LY1+1, LX2-1, LY2-1, White);
  DrawFrameRect(LX1, LY1, LX2, LY2, Black);
  For L := 0 To LIST_ROWS-1 Do Begin
   If Top + L > FileCount Then Break;
   Y := LY1 + 1 + L*ROW_H;
   If Top + L = Sel Then Begin
    FillRectArea(LX1+1, Y, LX2-1, Y+ROW_H-1, Blue);
    DrawTextAt(LX1+6, Y+3, Files[Top+L], White);
   End Else
    If FileIsDir[Top+L] Then
     DrawTextAt(LX1+6, Y+3, Files[Top+L], DarkGray)
    Else
     DrawTextAt(LX1+6, Y+3, Files[Top+L], Black);
  End;
 End;

 Procedure RedrawInput;
 Var TW : Integer;
 Begin
  FillRectArea(IX1+1, IY1+1, IX2-1, IY2-1, White);
  DrawFrameRect(IX1, IY1, IX2, IY2, Black);
  DrawTextAt(IX1+4, IY1+3, Inp, Black);
  TW := TextWidth(Inp);
  FillRectArea(IX1+4+TW, IY1+3, IX1+4+TW+1, IY2-3, Black);
 End;

 Procedure RedrawFilter;
 Begin
  FillRectArea(FX1, FY1, FX2, FY2, CLR_3D_FACE);
  DrawButton3D(FX1, FY1, FX2, FY2, False);
  FltDisp := FltLabels[FltCur];
  If Length(FltDisp) > 38 Then FltDisp := Copy(FltDisp, 1, 38);
  DrawTextAt(FX1+5, FY1+3, FltDisp, Black);
  { fleche vers le bas a droite }
  DrawTextAt(FX2-12, FY1+3, #25, Black);
 End;

 { La liste se deploie vers le haut pour rester dans la boite de dialogue. }
 Procedure DrawFilterPopup;
 Var J,Y:Integer;FG,BG:Word;
 Begin
  PopupY2:=FY1-1;PopupY1:=PopupY2-FltCount*ROW_H-2;
  FillRectArea(FX1,PopupY1,FX2,PopupY2,White);
  DrawFrameRect(FX1,PopupY1,FX2,PopupY2,Black);
  For J:=1 To FltCount Do Begin
   Y:=PopupY1+1+(J-1)*ROW_H;
   If J=FltHover Then Begin BG:=Blue;FG:=White;End Else Begin
     BG:=White;FG:=Black;End;
   FillRectArea(FX1+1,Y,FX2-1,Y+ROW_H-1,BG);
   DrawTextAt(FX1+5,Y+3,Copy(FltLabels[J],1,54),FG);
  End;
 End;

 Procedure CloseFilterPopup(Apply:Boolean);
 Begin
  If Apply and (FltHover>=1) and (FltHover<=FltCount) Then Begin
   If FltCur<>FltHover Then Begin FltCur:=FltHover;NeedRescan:=True;End;
  End;
  FltOpen:=False;
  RedrawList;RedrawFilter;
 End;

 Procedure OpenFilterPopup;
 Begin
  FltOpen:=True;FltFocus:=True;FltHover:=FltCur;DrawFilterPopup;
 End;

 Procedure RedrawDir;
 Begin
  FillRectArea(X1+15, Y1+38, X2-15, Y1+52, CLR_3D_FACE);
  DirDisp := CurDir;
  If Length(DirDisp) > 56 Then
   DirDisp := '...' + Copy(DirDisp, Length(DirDisp)-52, 53);
  DrawTextAt(X1+15, Y1+40, DirDisp, Black);
 End;

 Procedure ScanDir;
 Var FS, FE, FL: Integer; M, FullMask: String;
 Begin
  FileCount := 0;
  { 1) Sous-repertoires }
  If Length(CurDir) > 0 Then Begin
   FindFirst(CurDir + '*.*', Directory, SR);
   While (DosError = 0) And (FileCount < MAX_LIST) Do Begin
    If ((SR.Attr And Directory) <> 0) And
       (SR.Name <> '.') And (SR.Name <> '..') Then Begin
     Inc(FileCount);
     Files[FileCount] := '[' + SR.Name + ']';
     FileIsDir[FileCount] := True;
    End;
    FindNext(SR);
   End;
    FindClose(SR); 
  End;
  { 2) Entree parent }
  If (Length(CurDir) > 3) And (FileCount < MAX_LIST) Then Begin
   { Decaler tous les sous-dirs d'un cran pour mettre [..] en premier. }
   For FS := FileCount Downto 1 Do Begin
    Files[FS+1]     := Files[FS];
    FileIsDir[FS+1] := FileIsDir[FS];
   End;
   Files[1]     := '[..]';
   FileIsDir[1] := True;
   Inc(FileCount);
  End;
  { 3) Fichiers selon masques du filtre courant }
  M := FltMasks[FltCur];
  FS := 1; FL := Length(M);
  While FS <= FL Do Begin
   FE := FS;
   While (FE <= FL) And (M[FE] <> ';') Do Inc(FE);
   FullMask := Copy(M, FS, FE - FS);
   If Length(FullMask) > 0 Then Begin
    If Length(CurDir) > 0 Then FullMask := CurDir + FullMask;
    FindFirst(FullMask, AnyFile, SR);
    While (DosError = 0) And (FileCount < MAX_LIST) Do Begin
     If (SR.Attr And Directory) = 0 Then Begin
      Inc(FileCount);
      Files[FileCount] := SR.Name;
      FileIsDir[FileCount] := False;
     End;
     FindNext(SR);
    End;
     FindClose(SR); 
   End;
   FS := FE + 1;
  End;
  Sel := 0; Top := 1;
 End;

 Function DirExistsHere(Const D: String): Boolean;
 Var S: SearchRec;
 Begin
  FindFirst(D, Directory, S);
  DirExistsHere := (DosError = 0) And ((S.Attr And Directory) <> 0);
   FindClose(S); 
 End;

Begin
 OK := False;
 X1 := 80; X2 := 560; Y1 := 60; Y2 := 420;
 LX1 := X1+15;  LY1 := Y1+110;
 LX2 := X2-15;  LY2 := LY1 + LIST_ROWS*ROW_H + 1;
 IX1 := X1+60;  IY1 := Y1+82;
 IX2 := X2-15;  IY2 := Y1+98;
 FX1 := X1+15;  FY1 := LY2 + 8;
 FX2 := X2-15;  FY2 := FY1 + 18;
 BY1 := Y2-30;  BY2 := Y2-10;
 OkX1 := X2-180;
 CnX1 := X2-90;
 ParseFilter;
 FltCur := 1;FltOpen:=False;FltFocus:=False;FltHover:=1;
 { Separer le repertoire et le nom dans FName. }
 CurDir := '';
 Inp    := FName;
 For I := Length(Inp) Downto 1 Do
  If (Inp[I]='\') Or (Inp[I]='/') Or (Inp[I]=':') Then Begin
   CurDir := Copy(Inp, 1, I);
   Inp    := Copy(Inp, I+1, Length(Inp)-I);
   Break;
  End;
 If Length(CurDir) = 0 Then Begin
  GetDir(0, CurDir);
  If (Length(CurDir) > 0) And (CurDir[Length(CurDir)] <> '\') Then
   CurDir := CurDir + '\';
 End;
 ScanDir;

 EraseSoftCursor;
 FillRectArea(X1+5, Y2+1, X2+5, Y2+5, Black);
 FillRectArea(X2+1, Y1+5, X2+5, Y2+5, Black);
 FillRectArea(X1, Y1, X2, Y2, CLR_3D_FACE);
 DrawButton3D(X1, Y1, X2, Y2, False);
 OsTitleBar(X1+3, Y1+3, X2-3, Y1+18, Title, Y1+6);
 DrawTextAt(X1+15, Y1+26, Tr('Repertoire :'), Black);
 RedrawDir;
 DrawTextAt(X1+15, Y1+62, Tr('Fichiers :'), Black);
 DrawTextAt(X1+15, Y1+86, Tr('Nom :'), Black);
 RedrawInput;
 RedrawList;
 RedrawFilter;
 DrawButton3D(OkX1, BY1, OkX1+80, BY2, False);
 If SaveMode Then DrawTextAt(OkX1+25, BY1+4, Tr('Save'), Black)
             Else DrawTextAt(OkX1+30, BY1+4, Tr('Open'), Black);
 DrawButton3D(CnX1, BY1, CnX1+80, BY2, False);
 DrawTextAt(CnX1+22, BY1+4, Tr('Cancel'), Black);
  DrawSoftCursor(MsX, MsY); 

 LastBtn := MsBtn;
 Done := False;
 Repeat
  NeedRescan := False;
  If KeyPressed Then Begin
   K := ReadKeyEx;
   If FltOpen Then Begin
    Case K Of
     KEY_UP:If FltHover>1 Then Dec(FltHover);
     KEY_DOWN:If FltHover<FltCount Then Inc(FltHover);
     KEY_HOME:FltHover:=1;
     KEY_END:FltHover:=FltCount;
     KEY_ENTER,KEY_TAB:CloseFilterPopup(True);
     KEY_ESC,KEY_F4:CloseFilterPopup(False);
    End;
    If FltOpen Then DrawFilterPopup;
   End Else If (K=KEY_F4) or ((K=KEY_ENTER) and FltFocus) or
               ((K=KEY_DOWN) and FltFocus) or ((K=32) and FltFocus) Then
                 OpenFilterPopup
   Else If K=KEY_TAB Then Begin
    FltFocus:=Not FltFocus;
    If FltFocus Then OpenFilterPopup;
   End Else Begin
   FltFocus:=False;
   Case K Of
    KEY_ESC   : Begin OK:=False; Done:=True; End;
    KEY_ENTER : If (Sel >= 1) And (Sel <= FileCount) And FileIsDir[Sel] Then
      Begin
                 If Files[Sel] = '[..]' Then NavigateUp
                 Else NavigateInto(Copy(Files[Sel], 2, Length(Files[Sel])-2));
                 NeedRescan := True;
                End Else If Length(Inp) > 0 Then Begin OK:=True; Done:=True;
                  End;
    KEY_UP    : If FileCount > 0 Then Begin
                 If Sel <= 1 Then Sel := 1 Else Dec(Sel);
                 If Sel < Top Then Top := Sel;
                 If Not FileIsDir[Sel] Then Inp := Files[Sel];
                 RedrawInput; RedrawList;
                End;
    KEY_DOWN  : If Sel < FileCount Then Begin
                 If Sel = 0 Then Sel := 1 Else Inc(Sel);
                 If Sel > Top + LIST_ROWS - 1 Then Top := Sel - LIST_ROWS + 1;
                 If Not FileIsDir[Sel] Then Inp := Files[Sel];
                 RedrawInput; RedrawList;
                End;
    KEY_BACKSPACE : If Length(Inp) > 0 Then Begin
                     Inp[0] := Char(Length(Inp)-1);
                     RedrawInput;
                    End;
   Else
    If (K >= 32) And (K <= 126) And (Length(Inp) < 80) Then Begin
     Inp := Inp + Char(K);
     RedrawInput;
    End;
   End;
  End;
   End;
  GetMouseStateLI(MsX, MsY, MsBtn);
  MouseConsumed:=False;
  If FltOpen Then Begin
   If (MsX>=FX1) and (MsX<=FX2) and (MsY>PopupY1) and (MsY<PopupY2) Then Begin
    OldHover:=FltHover;FltHover:=(MsY-PopupY1-1) div ROW_H+1;
    If FltHover>FltCount Then FltHover:=FltCount;
    If OldHover<>FltHover Then DrawFilterPopup;
   End;
   If ((MsBtn and MB_LEFT)<>0) and ((LastBtn and MB_LEFT)=0) Then Begin
    MouseConsumed:=True;
    CloseFilterPopup((MsX>=FX1) and (MsX<=FX2) and
                     (MsY>PopupY1) and (MsY<PopupY2));
   End;
  End;
  If Not MouseConsumed and ((MsBtn And MB_LEFT) <> 0) And ((LastBtn And MB_LEFT)
    = 0) Then Begin
   If (MsX>=OkX1) And (MsX<=OkX1+80) And (MsY>=BY1) And (MsY<=BY2) Then Begin
    If Length(Inp)>0 Then Begin OK:=True; Done:=True; End;
   End Else If (MsX>=CnX1) And (MsX<=CnX1+80) And (MsY>=BY1) And (MsY<=BY2) Then
     Begin
    OK:=False; Done:=True;
   End Else If (MsX>=FX1) And (MsX<=FX2) And (MsY>=FY1) And (MsY<=FY2) Then
     Begin
    OpenFilterPopup;
   End Else If (MsX>=IX1) and (MsX<=IX2) and (MsY>=IY1) and (MsY<=IY2) Then
     Begin
    FltFocus:=False;
   End Else If (MsX>=LX1) And (MsX<=LX2) And (MsY>=LY1) And (MsY<=LY2) Then
     Begin
    FltFocus:=False;
    Idx := Top + (MsY - LY1 - 1) Div ROW_H;
    If (Idx >= 1) And (Idx <= FileCount) Then Begin
     If FileIsDir[Idx] Then Begin
      If Files[Idx] = '[..]' Then NavigateUp
      Else NavigateInto(Copy(Files[Idx], 2, Length(Files[Idx])-2));
      NeedRescan := True;
     End Else Begin
      Sel := Idx; Inp := Files[Sel]; RedrawInput; RedrawList;
     End;
    End;
   End;
  End;
  LastBtn := MsBtn;
  If NeedRescan Then Begin
   ScanDir;
   RedrawDir;
   RedrawList;
   RedrawInput;
  End;
 Until Done;
 If OK Then Begin
  { Si l'utilisateur a tape un chemin complet, le garder tel quel. }
  For I := 1 To Length(Inp) Do
   If (Inp[I]='\') Or (Inp[I]='/') Or (Inp[I]=':') Then Begin
    FName := Inp;
    NeedsRedraw := True;
    ShowFileDialog := OK;
    Exit;
   End;
  FName := CurDir + Inp;
 End;
 NeedsRedraw := True;
 ShowFileDialog := OK;
End;

{ ============================================================ }
{ ===================  PHASE 10 - POLISSAGE  ================= }
{ ============================================================ }
{ Boite de saisie de texte, recherche/remplacement, undo/redo  }
{ (snapshot du document, profondeur 5), comptage de mots.      }
{ ============================================================ }

Const
 ACT_EDIT_FIND_NEXT_X = 208;  { kept for back-compat with Phase 10 placeholder }
 ACT_TLS_WORDS_X      = 603;
 MAX_UNDO           = 5;
 MAX_FIND_LEN       = 60;

Type
 TDocPtr = ^TDocument;

Var
 UndoStack    : Array[1..MAX_UNDO] Of TDocPtr;
 UndoCursors  : Array[1..MAX_UNDO] Of TCursorPos;
 UndoCount    : Integer;
 RedoStack    : Array[1..MAX_UNDO] Of TDocPtr;
 RedoCursors  : Array[1..MAX_UNDO] Of TCursorPos;
 RedoCount    : Integer;
 LastMutate   : Integer;     { 0=none, 1=typing, 2=other }
 LastFindStr  : String[MAX_FIND_LEN];
 LastReplStr  : String[MAX_FIND_LEN];

{ ---- Boite de saisie texte simple ---- }

Function InputBoxDlg(Const Title, Prompt: String;
                     Var S: String; MaxLen: Integer): Boolean;
Var
 X1, Y1, X2, Y2  : Integer;
 IX1, IY1, IX2, IY2 : Integer;
 OkX1, CnX1, BY1, BY2 : Integer;
 K               : Word;
 OK, Done        : Boolean;
 Inp             : String;
 TW              : Integer;

 Procedure RedrawInput;
 Var TWi : Integer;
 Begin
  FillRectArea(IX1+1, IY1+1, IX2-1, IY2-1, White);
  DrawFrameRect(IX1, IY1, IX2, IY2, Black);
  DrawTextAt(IX1+4, IY1+4, Inp, Black);
  TWi := TextWidth(Inp);
  FillRectArea(IX1+4+TWi, IY1+3, IX1+4+TWi+1, IY2-3, Black);
 End;

Begin
 OK := False;
 X1 := 160; X2 := 480; Y1 := 160; Y2 := 280;
 IX1 := X1+15; IX2 := X2-15; IY1 := Y1+60; IY2 := Y1+78;
 BY1 := Y2-30; BY2 := Y2-10;
 OkX1 := X2-180; CnX1 := X2-90;
 Inp := S;
 If MaxLen <= 0 Then MaxLen := 80;
 If MaxLen > 250 Then MaxLen := 250;

 EraseSoftCursor;
 FillRectArea(X1+5, Y2+1, X2+5, Y2+5, Black);
 FillRectArea(X2+1, Y1+5, X2+5, Y2+5, Black);
 FillRectArea(X1, Y1, X2, Y2, CLR_3D_FACE);
 DrawButton3D(X1, Y1, X2, Y2, False);
 OsTitleBar(X1+3, Y1+3, X2-3, Y1+18, Title, Y1+6);
 DrawTextAt(X1+15, Y1+34, Prompt, Black);
 RedrawInput;
 DrawButton3D(OkX1, BY1, OkX1+80, BY2, False);
 TW := TextWidth('OK');
 DrawTextAt(OkX1 + 40 - TW Div 2, BY1+4, 'OK', Black);
 DrawButton3D(CnX1, BY1, CnX1+80, BY2, False);
 DrawTextAt(CnX1+22, BY1+4, Tr('Cancel'), Black);
  DrawSoftCursor(MsX, MsY); 

 Done := False;
 Repeat
  If KeyPressed Then Begin
   K := ReadKeyEx;
   Case K Of
    KEY_ESC   : Begin OK := False; Done := True; End;
    KEY_ENTER : Begin OK := True; Done := True; End;
    KEY_BACKSPACE : If Length(Inp) > 0 Then Begin
                     Inp[0] := Char(Length(Inp)-1);
                     RedrawInput;
                    End;
   Else
    If (K >= 32) And (K <= 126) And (Length(Inp) < MaxLen) Then Begin
     Inp := Inp + Char(K);
     RedrawInput;
    End;
   End;
  End;
  GetMouseStateLI(MsX, MsY, MsBtn);
  If (MsBtn And MB_LEFT) <> 0 Then Begin
   If (MsX>=OkX1) And (MsX<=OkX1+80) And (MsY>=BY1) And (MsY<=BY2) Then Begin
    OK := True; Done := True;
   End Else If (MsX>=CnX1) And (MsX<=CnX1+80) And (MsY>=BY1) And (MsY<=BY2) Then
     Begin
    OK := False; Done := True;
   End;
   Repeat GetMouseStateLI(MsX, MsY, MsBtn); Until (MsBtn And MB_LEFT) = 0;
  End;
 Until Done;
 If OK Then S := Inp;
 NeedsRedraw := True;
 InputBoxDlg := OK;
End;

{ ---- Comptage mots / caracteres ---- }

Function CountWordsInStr(Const S: String): LongInt;
Var I, L: Integer; InWord: Boolean; N: LongInt;
Begin
 N := 0; InWord := False; L := Length(S);
 For I := 1 To L Do Begin
  If (S[I] = ' ') Or (S[I] = #9) Or (S[I] = #13) Then Begin
   InWord := False;
  End Else Begin
   If Not InWord Then Inc(N);
   InWord := True;
  End;
 End;
 CountWordsInStr := N;
End;

Procedure ShowWordCountDialog;
Const
 Labels: Array[1..9] of String[32] = (
  'Pages','Mots','Caract'+#138+'res (avec espaces)',
  'Caract'+#138+'res (sans espaces)','Paragraphes','Lignes de texte',
  'Tableaux','Cellules','Images');
 Colors: Array[1..9] of Word =
   (Blue,Red,Green,Magenta,Cyan,Brown,DarkGray,LightRed,LightBlue);
Var
 Totals: Array[1..9] of LongInt;
 P, I, R, C, T, Y, Ink: Integer;
 Total, Running: LongInt;
 StartAngle, EndAngle: Integer;
 ValueText: String;
 PrevButtons: LongInt;
 Done: Boolean;

 Procedure CountText(Const S: String);
 Var J: Integer;
 Begin
  Inc(Totals[2],CountWordsInStr(S));
  Inc(Totals[3],Length(S));
  For J:=1 To Length(S) Do
   If Not (S[J] in [#9..#13,' ',#255]) Then Inc(Totals[4]);
 End;

Begin
 If NeedsRelayout Then LayoutDocument;
 FillChar(Totals,SizeOf(Totals),0);
 Totals[1]:=Doc^.PageCount;
 For P:=1 To Doc^.ParaCount Do Begin
  If Doc^.Paragraphs[P].IsImage Then Inc(Totals[9])
  Else If ParaIsTable(P) Then Begin
   Inc(Totals[7]);
   T:=Doc^.Paragraphs[P].TableIdx;
   Inc(Totals[8],LongInt(Tables[T].Rows)*Tables[T].Cols);
   For R:=1 To Tables[T].Rows Do
    For C:=1 To Tables[T].Cols Do CountText(CellTextOf(P,R,C));
  End Else Begin
   Inc(Totals[5]);
   CountText(ParaText(P));
  End;
 End;
 For I:=1 To VLineCount Do
  If Not (VLines[I].IsImage Or VLines[I].IsTable) Then Inc(Totals[6]);

 EraseSoftCursor;
 FillRectArea(38,92,602,385,CLR_3D_FACE);
 DrawButton3D(38,92,602,385,False);
 OsTitleBar(41,95,599,113,Tr('Statistiques du document'),100);
 FillRectArea(53,126,383,148,DarkGray);
 DrawTextAt(65,134,Tr('Mesure'),White);
 DrawTextAt(327,134,Tr('Total'),White);
 For I:=1 To 9 Do Begin
  Y:=149+(I-1)*21;
  Ink:=White;
  If Odd(I) Then Ink:=LightGray;
  FillRectArea(53,Y,383,Y+19,Ink);
  FillRectArea(61,Y+6,70,Y+14,Colors[I]);
  DrawTextAt(77,Y+6,Tr(Labels[I]),Black);
  Str(Totals[I],ValueText);
  DrawTextAt(370-TextWidth(ValueText),Y+6,ValueText,Black);
 End;
 SetColor(DarkGray);
 Line(307,126,307,337);
 DrawSunkenRect(52,125,384,338);
 Total:=0;
 For I:=1 To 9 Do Inc(Total,Totals[I]);
 DrawTextAt(416,134,Tr('Valeurs relatives'),Black);
 If Total>0 Then Begin
  Running:=0;
  StartAngle:=0;
  For I:=1 To 9 Do Begin
   Inc(Running,Totals[I]);
   EndAngle:=Round(360.0*Running/Total);
   If EndAngle>StartAngle Then Begin
    SetColor(Colors[I]);
    SetFillStyle(SolidFill,Colors[I]);
    If EndAngle-StartAngle=360 Then FillEllipse(492,236,83,83)
    Else PieSlice(492,236,StartAngle,EndAngle,83);
   End;
   StartAngle:=EndAngle;
  End;
 End;
 SetColor(DarkGray);
 Circle(492,236,83);
 DrawTextAt(408,325,Tr('Unites differentes'),DarkGray);
 DrawButton3D(414,349,515,374,False);
 DrawTextAt(435,358,Tr('Fermer'),Black);

 PrevButtons:=MsBtn;
 Repeat
  Done:=False;
  If KeyPressed Then Done:=ReadKeyEx in [KEY_ENTER,KEY_ESC,32];
  EraseSoftCursor;
  GetMouseStateLI(MsX,MsY,MsBtn);
  If ((MsBtn and MB_LEFT)<>0) And ((PrevButtons and MB_LEFT)=0) Then
   If (MsX>=414) And (MsX<=515) And (MsY>=349) And (MsY<=374) Then Done:=True;
  PrevButtons:=MsBtn;
  If Not Done Then Begin
    DrawSoftCursor(MsX,MsY); 
   Delay(10);
  End;
 Until Done;
 NeedsRedraw:=True;
End;


{ ---- Recherche dans le document ---- }

Function UpperStr(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := S;
 For I := 1 To Length(R) Do
  If (R[I] >= 'a') And (R[I] <= 'z') Then
   R[I] := Char(Byte(R[I]) - 32);
 UpperStr := R;
End;

{ Cherche Needle a partir de (StartP, StartCh) inclus, sans wrap. Si trouve,
  pose Cursor au debut du match et retourne True. }
Function FindNextFromCursor(Const Needle: String): Boolean;
Var
 P            : Integer;
 T, UT, UN    : String;
 StartCh, Idx : Integer;
 RIdx, ROff   : Integer;
Begin
 FindNextFromCursor := False;
 If Length(Needle) = 0 Then Exit;
 UN := UpperStr(Needle);
 StartCh := Cursor.CharIdx + 1;
 For P := Cursor.ParaIdx To Doc^.ParaCount Do Begin
  If Doc^.Paragraphs[P].IsImage Then Begin
   StartCh := 1; Continue;
  End;
  T := ParaText(P);
  UT := UpperStr(T);
  If StartCh < 1 Then StartCh := 1;
  If StartCh > Length(UT) Then Begin StartCh := 1; Continue; End;
  Idx := Pos(UN, Copy(UT, StartCh, Length(UT) - StartCh + 1));
  If Idx > 0 Then Begin
   Idx := Idx + StartCh - 1;
   Cursor.ParaIdx := P;
   Cursor.CharIdx := Idx - 1;
   LocateChar(P, Cursor.CharIdx, RIdx, ROff);
   Cursor.RunIdx := RIdx;
   FindNextFromCursor := True;
   Exit;
  End;
  StartCh := 1;
 End;
End;

{ ---- Undo/Redo : snapshots avec clonage des images ----
  OS/2-0 : une copie ne garde que les paragraphes utilises (la version
  DOS copie tout le document, 500 paragraphes, a chaque fois) : un bloc
  [nombre de paragraphes][debut du document][paragraphes][fin du
  document]. Les images des paragraphes sont clonees comme dans la
  version DOS ; une restauration rend les images du bloc au document. }

Type
 TParaPtr = ^TParagraph;

Function SnapOfsParas: LongInt;
Begin
 SnapOfsParas := LongInt(@Doc^.Paragraphs[1]) - LongInt(Doc);
End;

Function SnapOfsTail: LongInt;
Begin
 SnapOfsTail := LongInt(@Doc^.ParaCount) - LongInt(Doc);
End;

Function SnapCount(Snap: TDocPtr): LongInt;
Var Q: ^LongInt;
Begin
 Q := Pointer(Snap);
 SnapCount := Q^;
End;

Function SnapSize(N: LongInt): LongInt;
Begin
 SnapSize := 4 + SnapOfsParas + N * SizeOf(TParagraph) + (SizeOf(TDocument) - SnapOfsTail);
End;

Function SnapPara(Snap: TDocPtr; I: LongInt): TParaPtr;
Begin
 SnapPara := Pointer(LongInt(Snap) + 4 + SnapOfsParas + (I - 1) * SizeOf(TParagraph));
End;

{ copie compacte du document (images clonees) }
Function SnapTake: TDocPtr;
Var
 N, I, Sz : LongInt;
 Snap     : TDocPtr;
 Q        : ^LongInt;
 Pp       : TParaPtr;
 NewP     : Pointer;
Begin
 N := Doc^.ParaCount;
 If N < 0 Then N := 0;
 If N > MAX_PARAS_PER_DOC Then N := MAX_PARAS_PER_DOC;
 GetMem(Snap, SnapSize(N));
 Q := Pointer(Snap); Q^ := N;
 Move(Doc^, Pointer(LongInt(Snap) + 4)^, SnapOfsParas);
 If N > 0 Then Move(Doc^.Paragraphs[1], SnapPara(Snap, 1)^, N * SizeOf(TParagraph));
 Move(Doc^.ParaCount, Pointer(LongInt(Snap) + 4 + SnapOfsParas + N * SizeOf(TParagraph))^,
      SizeOf(TDocument) - SnapOfsTail);
 For I := 1 To N Do
 Begin
  Pp := SnapPara(Snap, I);
  If Pp^.IsImage And (Pp^.ImgData <> Nil) Then
  Begin
   Sz := LongInt(Pp^.ImgW) * Pp^.ImgH;
   If Sz > 0 Then
   Begin
    GetMem(NewP, Sz);
    Move(Pp^.ImgData^, NewP^, Sz);
    Pp^.ImgData := NewP;
   End
   Else Pp^.ImgData := Nil;
  End;
 End;
 SnapTake := Snap;
End;

Procedure DocSnapshotFreeImages(Snap: TDocPtr);
Var I, Sz: LongInt; Pp: TParaPtr;
Begin
 For I := 1 To SnapCount(Snap) Do
 Begin
  Pp := SnapPara(Snap, I);
  If Pp^.IsImage And (Pp^.ImgData <> Nil) Then
  Begin
   Sz := LongInt(Pp^.ImgW) * Pp^.ImgH;
   FreeMem(Pp^.ImgData, Sz);
   Pp^.ImgData := Nil;
  End;
 End;
End;

Procedure DisposeSnapshot(Var Snap: TDocPtr);
Begin
 If Snap = Nil Then Exit;
 DocSnapshotFreeImages(Snap);
 FreeMem(Snap, SnapSize(SnapCount(Snap)));
 Snap := Nil;
End;

{ le document reprend la copie ; ses images (et le bloc) sont liberes
  avant, celles de la copie passent au document }
Procedure SnapRestore(Var Snap: TDocPtr);
Var N: LongInt;
Begin
 FreeAllDocImages;
 N := SnapCount(Snap);
 FillChar(Doc^, SizeOf(TDocument), 0);
 Move(Pointer(LongInt(Snap) + 4)^, Doc^, SnapOfsParas);
 If N > 0 Then Move(SnapPara(Snap, 1)^, Doc^.Paragraphs[1], N * SizeOf(TParagraph));
 Move(Pointer(LongInt(Snap) + 4 + SnapOfsParas + N * SizeOf(TParagraph))^, Doc^.ParaCount,
      SizeOf(TDocument) - SnapOfsTail);
 FreeMem(Snap, SnapSize(N));
 Snap := Nil;
End;

Procedure ClearRedoStack;
Var I: Integer;
Begin
 For I := 1 To RedoCount Do DisposeSnapshot(RedoStack[I]);
 RedoCount := 0;
End;

Procedure ClearAllUndo;
Var I: Integer;
Begin
 For I := 1 To UndoCount Do DisposeSnapshot(UndoStack[I]);
 UndoCount := 0;
 ClearRedoStack;
 LastMutate := 0;
End;

Procedure PushUndoSnapshot;
Var
 NewSnap : TDocPtr;
 I       : Integer;
Begin
 NewSnap := SnapTake;
 If UndoCount >= MAX_UNDO Then Begin
  DisposeSnapshot(UndoStack[1]);
  For I := 1 To MAX_UNDO - 1 Do Begin
   UndoStack[I]   := UndoStack[I+1];
   UndoCursors[I] := UndoCursors[I+1];
  End;
  Dec(UndoCount);
 End;
 Inc(UndoCount);
 UndoStack[UndoCount]   := NewSnap;
 UndoCursors[UndoCount] := Cursor;
 ClearRedoStack;
End;

Procedure PushRedoSnapshot;
Var
 NewSnap : TDocPtr;
 I       : Integer;
Begin
 NewSnap := SnapTake;
 If RedoCount >= MAX_UNDO Then Begin
  DisposeSnapshot(RedoStack[1]);
  For I := 1 To MAX_UNDO - 1 Do Begin
   RedoStack[I]   := RedoStack[I+1];
   RedoCursors[I] := RedoCursors[I+1];
  End;
  Dec(RedoCount);
 End;
 Inc(RedoCount);
 RedoStack[RedoCount]   := NewSnap;
 RedoCursors[RedoCount] := Cursor;
End;

Procedure DoUndo;
Var Snap: TDocPtr; Cur: TCursorPos;
Begin
 If UndoCount = 0 Then Begin
  StatusMsg := Tr('Nothing to undo'); Exit;
 End;
 PushRedoSnapshot;
 Snap := UndoStack[UndoCount];
 Cur  := UndoCursors[UndoCount];
 Dec(UndoCount);
 SnapRestore(Snap);
 Cursor := Cur;
 NeedsRelayout := True;
 StatusMsg := Tr('Undo');
 LastMutate := 0;
End;

Procedure DoRedo;
Var Snap: TDocPtr; Cur: TCursorPos; NewSnap: TDocPtr; I: Integer;
Begin
 If RedoCount = 0 Then Begin
  StatusMsg := Tr('Nothing to redo'); Exit;
 End;
 { Re-push undo (sans clear du redo) }
 NewSnap := SnapTake;
 If UndoCount >= MAX_UNDO Then Begin
  DisposeSnapshot(UndoStack[1]);
  For I := 1 To MAX_UNDO - 1 Do Begin
   UndoStack[I]   := UndoStack[I+1];
   UndoCursors[I] := UndoCursors[I+1];
  End;
  Dec(UndoCount);
 End;
 Inc(UndoCount);
 UndoStack[UndoCount]   := NewSnap;
 UndoCursors[UndoCount] := Cursor;

 Snap := RedoStack[RedoCount];
 Cur  := RedoCursors[RedoCount];
 Dec(RedoCount);
 SnapRestore(Snap);
 Cursor := Cur;
 NeedsRelayout := True;
 StatusMsg := Tr('Redo');
 LastMutate := 0;
End;

{ Helper : a appeler avant toute mutation. Coalesce le typing en un seul
  snapshot par burst. }
Procedure MarkMutation(Kind: Integer);
Begin
 If (Kind = 1) And (LastMutate = 1) Then Exit;
 PushUndoSnapshot;
 LastMutate := Kind;
End;

Procedure ResetMutation;
Begin
 LastMutate := 0;
End;

{ ---- Dialogues Find / Replace haut niveau ---- }

Procedure DoFindDialog;
Var S: String;
Begin
 S := LastFindStr;
 If Not InputBoxDlg(Tr('Find'), Tr('Find what:'), S, MAX_FIND_LEN) Then Begin
  NeedsRedraw := True; Exit;
 End;
 If Length(S) = 0 Then Exit;
 LastFindStr := S;
 If FindNextFromCursor(S) Then Begin
  NeedsRelayout := True;
  StatusMsg := Tr('Found: ') + S;
 End Else
  ShowMessage(Tr('Not found: ') + S);
End;

Procedure DoFindNext;
Begin
 If Length(LastFindStr) = 0 Then Begin
  DoFindDialog; Exit;
 End;
 { Avance d'un cran pour ne pas re-trouver le meme }
 If Cursor.CharIdx < Length(ParaText(Cursor.ParaIdx)) Then
  Inc(Cursor.CharIdx)
 Else If Cursor.ParaIdx < Doc^.ParaCount Then Begin
  Inc(Cursor.ParaIdx); Cursor.CharIdx := 0;
 End;
 If FindNextFromCursor(LastFindStr) Then Begin
  NeedsRelayout := True;
  StatusMsg := Tr('Found: ') + LastFindStr;
 End Else
  ShowMessage(Tr('No more matches'));
End;

Procedure DoReplaceDialog;
Var
 SFind, SRepl, Ans : String;
 NReplaced         : Integer;
 K                 : Integer;
Begin
 SFind := LastFindStr;
 If Not InputBoxDlg(Tr('Replace'), Tr('Find what:'), SFind,
   MAX_FIND_LEN) Then Begin
  NeedsRedraw := True; Exit;
 End;
 If Length(SFind) = 0 Then Exit;
 SRepl := LastReplStr;
 If Not InputBoxDlg(Tr('Replace'), Tr('Replace with:'), SRepl,
   MAX_FIND_LEN) Then Begin
  NeedsRedraw := True; Exit;
 End;
 LastFindStr := SFind;
 LastReplStr := SRepl;
 Ans := 'A';
 If Not InputBoxDlg(Tr('Replace'), Tr('Replace All? (Y/N)'), Ans, 2) Then Begin
  NeedsRedraw := True; Exit;
 End;
 NReplaced := 0;
 If (Length(Ans) > 0) And IsYesChar(Ans[1]) Then Begin
  { Replace All : repart du debut. }
  MarkMutation(2);
  Cursor.ParaIdx := 1; Cursor.CharIdx := 0; Cursor.RunIdx := 1;
  While FindNextFromCursor(SFind) Do Begin
   { Supprime Length(SFind) chars }
   For K := 1 To Length(SFind) Do DeleteAtCursor;
   { Insere SRepl }
   For K := 1 To Length(SRepl) Do InsertCharAtCursor(SRepl[K]);
   Inc(NReplaced);
   If NReplaced > 10000 Then Break;
  End;
  Str(NReplaced, Ans);
  StatusMsg := Ans + Tr(' replacement(s)');
  NeedsRelayout := True;
 End Else Begin
  { Une seule occurrence depuis cursor }
  If FindNextFromCursor(SFind) Then Begin
   MarkMutation(2);
   For K := 1 To Length(SFind) Do DeleteAtCursor;
   For K := 1 To Length(SRepl) Do InsertCharAtCursor(SRepl[K]);
   StatusMsg := Tr('Replaced');
   NeedsRelayout := True;
  End Else
   ShowMessage(Tr('Not found: ') + SFind);
 End;
End;

Procedure UpdateViewGeometry;
Begin
 DOCAREA_TOP:=RULER_TOP+1;
 If RulerVisible Then Inc(DOCAREA_TOP,RULER_HEIGHT);
End;

Procedure ChangeDocumentView(LayoutMode:Boolean);
Begin
 If PageLayoutView=LayoutMode Then Exit;
 PageLayoutView:=LayoutMode;ZoomPanX:=0;ScrollY:=0;
 NeedsRelayout:=True;NeedsRedraw:=True;CursorBlinkOn:=True;
End;

Procedure ToggleDocumentRuler;
Begin
 RulerVisible:=Not RulerVisible;UpdateViewGeometry;
 NeedsRelayout:=True;NeedsRedraw:=True;CursorBlinkOn:=True;
End;

Function SetViewZoom(Value:Integer;FitPage:Boolean):Boolean;
Var CenterY,OldZoom,Visible:LongInt;
Begin
 SetViewZoom:=False;If (Value<25) or (Value>300) Then Exit;
 OldZoom:=ZoomValue;Visible:=DOCAREA_BOTTOM-DOCAREA_TOP;
 CenterY:=ScrollY+Visible*100 div OldZoom div 2;
 ZoomPercent:=Value;ZoomPanX:=0;
 If FitPage Then Begin PageLayoutView:=True;NeedsRelayout:=True;End;
 If FitPage Then ScrollY:=(CurrentPage-1)*(PAGE_H+12)
 Else ScrollY:=CenterY-Visible*100 div Value div 2;
 If ScrollY<0 Then ScrollY:=0;
 CursorBlinkOn:=True;CursorBlinkCnt:=0;NeedsRedraw:=True;
 SetViewZoom:=True;
End;

Procedure ShowZoomDialog;
Const Values:Array[1..8] of Integer=(50,75,100,125,150,200,0,-1);
Var Value,Choice,I,X,Y:Integer;K:Word;Text,LabelText:String;
 Done,Apply:Boolean;PrevButton:LongInt;
 Procedure Paint;
 Var J,BX,BY:Integer;
 Begin
  EraseSoftCursor;
  FillRectArea(155,125,485,350,CLR_3D_FACE);DrawButton3D(155,125,485,350,False);
  OsTitleBar(158,128,482,146,Tr('Zoom'),132);
  DrawTextAt(170,161,Tr('Pourcentage (25 a 300 %) :'),Black);
  FillRectArea(170,180,265,200,White);DrawSunkenRect(170,180,265,200);
  DrawTextAt(176,186,Text+' %',Black);
  For J:=1 To 8 Do Begin
   BX:=170+((J-1) mod 4)*75;BY:=216+((J-1) div 4)*30;
   DrawButton3D(BX,BY,BX+68,BY+23,Choice=J);
   If J=7 Then LabelText:=Tr('Page') Else If J=8 Then LabelText:=Tr('Largeur')
   Else Begin Str(Values[J],LabelText);LabelText:=LabelText+' %';End;
   DrawTextAt(BX+5,BY+7,LabelText,Black);
  End;
  DrawButton3D(285,313,365,336,False);DrawTextAt(315,320,'OK',Black);
  DrawButton3D(385,313,470,336,False);DrawTextAt(397,320,Tr('Annuler'),Black);
   DrawSoftCursor(MsX,MsY);
 End;
 Procedure Pick(Index:Integer);
 Begin
  Choice:=Index;Value:=Values[Index];
  If Value=0 Then Value:=(DOCAREA_BOTTOM-DOCAREA_TOP-16)*100 div PAGE_H;
  If Value=-1 Then Value:=(SCREEN_W-24)*100 div PAGE_W;
  If Value<25 Then Value:=25;If Value>300 Then Value:=300;
  Str(Value,Text);
 End;
Begin
 Str(ZoomValue,Text);Choice:=0;Done:=False;Apply:=False;PrevButton:=MsBtn;
 EraseSoftCursor;Paint;
 Repeat
  If KeyPressed Then Begin
   K:=ReadKeyEx;
   Case K Of
    KEY_ESC:Done:=True;
    KEY_ENTER:Begin
     Val(Text,Value,I);
     If (I=0) and (Value>=25) and (Value<=300) Then Begin
       Apply:=True;Done:=True;End;
    End;
    KEY_LEFT,KEY_UP:Begin If Choice<=1 Then Pick(8) Else
      Pick(Choice-1);Paint;End;
    KEY_RIGHT,KEY_DOWN,KEY_TAB:Begin If Choice>=8 Then Pick(1) Else
      Pick(Choice+1);Paint;End;
    KEY_BACKSPACE:Begin If Length(Text)>0 Then
      Delete(Text,Length(Text),1);Choice:=0;Paint;End;
    48..57:Begin
     If Choice<>0 Then Text:='';Choice:=0;
     If Length(Text)>=3 Then Text:='';Text:=Text+Char(K);Paint;
    End;
   End;
  End;
  EraseSoftCursor;GetMouseStateLI(MsX,MsY,MsBtn);
  If ((MsBtn and MB_LEFT)<>0) and ((PrevButton and MB_LEFT)=0) Then Begin
   For I:=1 To 8 Do Begin
    X:=170+((I-1) mod 4)*75;Y:=216+((I-1) div 4)*30;
    If (MsX>=X) and (MsX<=X+68) and (MsY>=Y) and (MsY<=Y+23) Then Begin
      Pick(I);Paint;End;
   End;
   If (MsY>=313) and (MsY<=336) Then Begin
    If (MsX>=385) and (MsX<=470) Then Done:=True;
    If (MsX>=285) and (MsX<=365) Then Begin
     Val(Text,Value,I);
     If (I=0) and (Value>=25) and (Value<=300) Then Begin
       Apply:=True;Done:=True;End;
    End;
   End;
  End;
  PrevButton:=MsBtn; DrawSoftCursor(MsX,MsY);
 Until Done;
 EraseSoftCursor;
 If Apply Then Apply:=SetViewZoom(Value,Choice=7);
 NeedsRedraw:=True;
End;

Procedure ShowSymbolDialog;
Const
 GridX = 108; GridY = 120;
 Cols = 16; Rows = 14;
 CellW = 26; CellH = 19;
 FirstCode = 33; LastCode = 254;
Var
 Code, I, X, Y, OldPos: Integer;
 K: Word;
 PreviousButtons: LongInt;
 Done, Accepted, Repaint: Boolean;

 Function HexDigit(N: Integer): Char;
 Const Digits = '0123456789ABCDEF';
 Begin
  HexDigit := Digits[N+1];
 End;

 Function UnicodeLabel(N: Word): String;
 Begin
  UnicodeLabel := 'U+' + HexDigit(N shr 12) +
    HexDigit((N shr 8) and 15) + HexDigit((N shr 4) and 15) +
    HexDigit(N and 15);
 End;

 Procedure Paint;
 Var J, BX, BY, Ink: Integer; Number: String;
 Begin
  EraseSoftCursor;
  FillRectArea(96,76,536,454,CLR_3D_FACE);
  DrawButton3D(96,76,536,454,False);
  OsTitleBar(99,79,533,97,Tr('Insertion de symbole'),83);
  DrawTextAt(108,105,Tr('Choisir un caractere CP437'),Black);

  For J := FirstCode To LastCode Do Begin
   { 127 est DEL, reserve aux commandes de controle. }
   If J <> 127 Then Begin
    BX := GridX + ((J-FirstCode) mod Cols)*CellW;
    BY := GridY + ((J-FirstCode) div Cols)*CellH;
    Ink := Black;
    If J = Code Then Begin
     FillRectArea(BX,BY,BX+CellW-2,BY+CellH-2,Blue);
     Ink := White;
    End Else DrawButton3D(BX,BY,BX+CellW-2,BY+CellH-2,False);
    DrawTextAt(BX+9,BY+5,Chr(J),Ink);
   End;
  End;

  Str(Code,Number);
  DrawTextAt(108,396,Tr('Apercu : ')+Chr(Code)+'   CP437 '+Number+
    '   '+UnicodeLabel(Cp437ToUni(Code)),Black);
  DrawButton3D(326,420,417,443,False);
  DrawTextAt(339,428,Tr('Inserer'),Black);
  DrawButton3D(427,420,524,443,False);
  DrawTextAt(443,428,Tr('Annuler'),Black);
 End;

 Procedure MoveSelection(Delta: Integer);
 Begin
  Inc(Code,Delta);
  If Code < FirstCode Then Code := FirstCode;
  If Code > LastCode Then Code := LastCode;
  If Code = 127 Then
   If Delta < 0 Then Dec(Code) Else Inc(Code);
 End;

Begin
 Code := 130;
 Done := False;
 Accepted := False;
 PreviousButtons := MsBtn;
 Paint;
 Repeat
  Repaint := False;
  If KeyPressed Then Begin
   K := ReadKeyEx;
   I := Code;
   Case K Of
    KEY_ESC: Done := True;
    KEY_ENTER: Begin Accepted := True; Done := True; End;
    KEY_LEFT: MoveSelection(-1);
    KEY_RIGHT,KEY_TAB: MoveSelection(1);
    KEY_UP: MoveSelection(-Cols);
    KEY_DOWN: MoveSelection(Cols);
    KEY_HOME: Code := FirstCode;
    KEY_END: Code := LastCode;
    KEY_PGUP: Code := 128;
    KEY_PGDN: Code := 224;
   End;
   Repaint := I <> Code;
  End;

  EraseSoftCursor;
  GetMouseStateLI(MsX,MsY,MsBtn);
  If (Not Done) And ((MsBtn and MB_LEFT) <> 0) And
     ((PreviousButtons and MB_LEFT) = 0) Then Begin
   X := MsX-GridX;
   Y := MsY-GridY;
   If (X >= 0) And (X < Cols*CellW) And
      (Y >= 0) And (Y < Rows*CellH) Then Begin
    I := FirstCode + (Y div CellH)*Cols + X div CellW;
    If (I <= LastCode) And (I <> 127) Then Begin
     Code := I;
     Repaint := True;
    End;
   End;
   If (MsY >= 420) And (MsY <= 443) Then Begin
    If (MsX >= 326) And (MsX <= 417) Then Begin
     Accepted := True;
     Done := True;
    End;
    If (MsX >= 427) And (MsX <= 524) Then Done := True;
   End;
  End;
  PreviousButtons := MsBtn;
  If Not Done Then Begin
   If Repaint Then Paint;
    DrawSoftCursor(MsX,MsY); 
   Delay(10);
  End;
 Until Done;
 EraseSoftCursor;
 NeedsRedraw := True;

 If Accepted Then Begin
  OldPos := Cursor.CharIdx;
  If CursorInTable Then Begin
   GetCursorCell(X,Y);
   If Length(CellTextOf(Cursor.ParaIdx,X,Y)) >= MAX_CELL_TEXT_LEN Then Begin
    ShowMessage(Tr('Cette cellule est pleine.'));
    Exit;
   End;
  End Else If Length(ParaText(Cursor.ParaIdx)) >= MAX_TEXT_LEN Then Begin
   ShowMessage(Tr('Ce paragraphe est plein.'));
   Exit;
  End;
  SelClear;
  PushUndoSnapshot;
  ResetMutation;
  InsertCharAtCursor(Chr(Code));
  If Cursor.CharIdx = OldPos Then
   ShowMessage(Tr('Insertion impossible : trop de segments de style.'));
 End;
End;


Procedure ShowFontDialog;
Const
 Options: Array[1..3] of String[10] = ('Gras','Italique','Souligne');
 Bits: Array[1..3] of Byte = (STY_BOLD,STY_ITALIC,STY_UNDERLINE);
 MinSize=6; MaxSize=72; VisibleSizes=10;
Var
 Draft, Initial: TCharStyle;
 P1,C1,P2,C2,P,L,R,J,A,B,Extra,F,Choice,FirstSize: Integer;
 SizeText: String;
 K: Word;
 Prev: LongInt;
 Done, Accept, Dirty, ListOpen: Boolean;

 Procedure Bounds;
 Begin
  L:=0; R:=Length(ParaText(P));
  If P=P1 Then L:=C1;
  If (P=P2) And (C2<R) Then R:=C2;
 End;

 Procedure MoveChoice(NewChoice: Integer);
 Begin
  If NewChoice<MinSize Then NewChoice:=MinSize;
  If NewChoice>MaxSize Then NewChoice:=MaxSize;
  Choice:=NewChoice;
  If Choice<FirstSize Then FirstSize:=Choice;
  If Choice>=FirstSize+VisibleSizes Then FirstSize:=Choice-VisibleSizes+1;
 End;

 Procedure ToggleList;
 Begin
  ListOpen:=Not ListOpen;
  If ListOpen Then MoveChoice(Draft.FontSize);
 End;

 Procedure Paint;
 Var I,X,Y,Ink,PreviewSize,Height: Integer; Sample: String;
 Begin
  EraseSoftCursor;
  FillRectArea(110,94,530,404,CLR_3D_FACE);
  DrawButton3D(110,94,530,404,False);
  OsTitleBar(113,97,527,116,Tr('Police'),102);
  DrawTextAt(128,132,Tr('Taille (6 a 72 pt)'),Black);
  FillRectArea(294,124,376,148,White);
  DrawSunkenRect(294,124,376,148);
  Str(Draft.FontSize,SizeText);
  DrawTextAt(303,132,SizeText+' pt',Black);
  DrawButton3D(353,125,375,147,ListOpen);
  DrawTextAt(361,132,'v',Black);
  For I:=1 To 3 Do Begin
   X:=128+(I-1)*124;
   DrawButton3D(X,160,X+112,184,(Draft.Style and Bits[I])<>0);
   DrawTextAt(X+8,168,Tr(Options[I]),Black);
   If F=I Then DrawTextAt(X+98,168,'*',Blue);
  End;
  For I:=0 To 15 Do Begin
   X:=128+(I mod 8)*47; Y:=198+(I div 8)*24;
   DrawButton3D(X,Y,X+39,Y+21,Draft.Color=I);
   FillRectArea(X+5,Y+5,X+34,Y+16,I);
   If Draft.Color=I Then Begin
    SetColor(White); Rectangle(X+2,Y+2,X+37,Y+19);
   End;
  End;
  FillRectArea(128,253,512,337,White);
  DrawSunkenRect(128,253,512,337);
  Sample:='AaBb';
  PreviewSize:=Draft.FontSize;
  If ListOpen Then PreviewSize:=Choice;
  { Scale the sample to fit the fixed-height preview at 72 pt. }
  Height:=(PreviewSize*2+1) div 3;
  ApplyRunStyle(Draft);
  
  Height:=((Height+4) div 8)*8;
  Sample:='Aa';
  
  ZoomText(384,261,Sample,Draft.Style,Draft.Color,Height,0);
  If (Draft.Style and STY_UNDERLINE)<>0 Then Begin
   SetColor(Draft.Color);
   
   Line(384,263+Height,383+Length(Sample)*Height,263+Height);
   
  End;
  DrawTextAt(128,345,Tr('Tab : option   Espace : ouvrir / basculer'),Black);
  DrawButton3D(329,370,414,393,False);
  DrawButton3D(421,370,512,393,False);
  DrawTextAt(340,378,Tr('Appliquer'),Black);
  DrawTextAt(434,378,Tr('Annuler'),Black);
  If F=0 Then DrawTextAt(380,132,'*',Blue);
  If F=4 Then DrawTextAt(508,202,'*',Blue);
  If ListOpen Then Begin
   FillRectArea(294,149,376,331,White);
   DrawSunkenRect(294,149,376,331);
   For I:=0 To VisibleSizes-1 Do Begin
    Y:=150+I*18;
    Ink:=Black;
    If FirstSize+I=Choice Then Begin
     FillRectArea(295,Y,352,Y+17,Blue);
     Ink:=White;
    End;
    Str(FirstSize+I,SizeText);
    DrawTextAt(303,Y+5,SizeText+' pt',Ink);
   End;
   DrawButton3D(353,150,375,168,False);
   DrawTextAt(360,155,'^',Black);
   DrawButton3D(353,312,375,330,False);
   DrawTextAt(360,318,'v',Black);
  End;
 End;

Begin
 If CursorInTable And Not SelHasRange Then Begin
  ShowMessage(Tr('Les cellules utilisent une police fixe.'));
  Exit;
 End;
 Initial:=CurrentStyle;
 If SelHasRange Then Begin
  SelGetRange(P1,C1,P2,C2);
  For P:=P1 To P2 Do Begin
   Bounds;
   If R>L Then Begin
    LocateChar(P,L,J,A);
    Initial:=Doc^.Paragraphs[P].Runs[J].Style;
    Break;
   End;
  End;
 End;
 Draft:=Initial;
 If (Draft.FontSize<6) Or (Draft.FontSize>72) Then Draft.FontSize:=12;
 F:=0; ListOpen:=False; FirstSize:=MinSize; Choice:=Draft.FontSize;
 Done:=False; Accept:=False; Prev:=MsBtn;
 Paint;
 Repeat
  Dirty:=False;
  If KeyPressed Then Begin
   K:=ReadKeyEx;
   Dirty:=True;
   If ListOpen Then Begin
    Case K Of
     KEY_ESC: ListOpen:=False;
     KEY_TAB: Begin ListOpen:=False; F:=1; End;
     KEY_ENTER,32: Begin Draft.FontSize:=Choice; ListOpen:=False; End;
     KEY_UP: MoveChoice(Choice-1);
     KEY_DOWN: MoveChoice(Choice+1);
     KEY_HOME: MoveChoice(MinSize);
     KEY_END: MoveChoice(MaxSize);
     KEY_PGUP: MoveChoice(Choice-VisibleSizes);
     KEY_PGDN: MoveChoice(Choice+VisibleSizes);
    End;
   End Else Case K Of
    KEY_ESC: Done:=True;
    KEY_ENTER: If F=0 Then ToggleList Else Begin Done:=True; Accept:=True; End;
    KEY_TAB: F:=(F+1) mod 5;
    KEY_LEFT: If F=4 Then Draft.Color:=(Draft.Color+15) mod 16;
    KEY_RIGHT: If F=4 Then Draft.Color:=(Draft.Color+1) mod 16;
    KEY_UP,KEY_DOWN: If F=0 Then ToggleList
     Else If F=4 Then Draft.Color:=Draft.Color xor 8;
    32: If F=0 Then ToggleList
     Else If (F>=1) And (F<=3) Then Draft.Style:=Draft.Style xor Bits[F];
   End;
  End;
  EraseSoftCursor;
  GetMouseStateLI(MsX,MsY,MsBtn);
  If Not Done And ((MsBtn and MB_LEFT)<>0) And ((Prev and MB_LEFT)=0) Then Begin
   Dirty:=True;
   If (MsY>=124) And (MsY<=148) And (MsX>=294) And (MsX<=376) Then Begin
    F:=0; ToggleList;
   End Else If ListOpen Then Begin
    If (MsX>=294) And (MsX<=352) And (MsY>=150) And (MsY<330) Then Begin
     Draft.FontSize:=FirstSize+(MsY-150) div 18;
     ListOpen:=False;
    End Else If (MsX>=353) And (MsX<=376) And (MsY>=150) And (MsY<=330) Then
      Begin
     If MsY<=168 Then MoveChoice(FirstSize-1);
     If MsY>=312 Then MoveChoice(FirstSize+VisibleSizes);
    End Else ListOpen:=False;
   End Else Begin
   If (MsY>=160) And (MsY<=184) Then
    For J:=1 To 3 Do
     If (MsX>=128+(J-1)*124) And (MsX<=240+(J-1)*124) Then Begin
      F:=J; Draft.Style:=Draft.Style xor Bits[J];
     End;
   If (MsX>=128) And (MsX<504) And (MsY>=198) And (MsY<246) Then Begin
    F:=4; Draft.Color:=(MsX-128) div 47+8*((MsY-198) div 24);
   End;
   If (MsY>=370) And (MsY<=393) Then Begin
    If (MsX>=329) And (MsX<=414) Then Begin Done:=True; Accept:=True; End;
    If (MsX>=421) And (MsX<=512) Then Done:=True;
   End;
   End;
  End;
  Prev:=MsBtn;
  If Dirty And Not Done Then Paint;
  If Not Done Then Begin
    DrawSoftCursor(MsX,MsY); 
   Delay(10);
  End;
 Until Done;
 EraseSoftCursor;
 NeedsRedraw:=True;
 If Not Accept Then Exit;

 If SelHasRange Then Begin
  For P:=P1 To P2 Do Begin
   Bounds;
   If R<=L Then Continue;
   Extra:=0;
   LocateChar(P,L,J,A);
   If A>0 Then Inc(Extra);
   If R<Length(ParaText(P)) Then Begin
    LocateChar(P,R,J,B);
    If B>0 Then Inc(Extra);
   End;
   If Doc^.Paragraphs[P].RunCount+Extra>MAX_RUNS_PER_PARA Then Begin
    ShowMessage(Tr('Selection trop fragmentee pour appliquer la police.'));
    Exit;
   End;
  End;
  PushUndoSnapshot;
  For P:=P1 To P2 Do Begin
   Bounds;
   If R<=L Then Continue;
   If Not SplitRunAtChar(P,L) Then Continue;
   If Not SplitRunAtChar(P,R) Then Continue;
   A:=0;
   For J:=1 To Doc^.Paragraphs[P].RunCount Do Begin
    B:=A+Length(Doc^.Paragraphs[P].Runs[J].Text);
    If (A>=L) And (B<=R) And (B>A) Then
     Doc^.Paragraphs[P].Runs[J].Style:=Draft;
    A:=B;
   End;
   MergeAdjacentSameStyleRuns(P);
  End;
  Doc^.Modified:=True;
  NeedsRelayout:=True;
 End;
 CurrentStyle:=Draft;
 For J:=1 To 3 Do FmtBar[J].Pressed:=(Draft.Style and Bits[J])<>0;
 ResetMutation;
End;


Procedure ShowParagraphDialog;
Const
 Labels: Array[0..3] of String[10]=('Gauche','Centre','Droite','Justifie');
Var
 A, Indent, P, P1, C1, P2, C2, F, I, X, Y, V, ErrorPos: Integer;
 AllLines, Border, PageBreak, Done, Accept, Dirty, Changed, Fresh: Boolean;
 K: Word;
 Prev: LongInt;
 ValueText: String;

 Procedure AcceptSettings;
 Begin
  Val(ValueText,V,ErrorPos);
  If (ErrorPos=0) And (V>=0) And (V<=160) Then Begin
   Indent:=V; Accept:=True; Done:=True;
  End Else F:=1;
 End;

 Procedure Paint;
 Var J,BX,StartX,EndX,Width: Integer;
 Begin
  EraseSoftCursor;
  FillRectArea(108,96,532,395,CLR_3D_FACE);
  DrawButton3D(108,96,532,395,False);
  OsTitleBar(111,99,529,118,Tr('Paragraphe'),104);
  For J:=0 To 3 Do Begin
   BX:=120+100*J;
   DrawButton3D(BX,128,BX+94,153,A=J);
   DrawTextAt(BX+7,137,Tr(Labels[J]),Black);
  End;
  DrawTextAt(122,170,Tr('Retrait gauche (0 a 160 px)'),Black);
  FillRectArea(384,164,448,188,White);
  DrawSunkenRect(384,164,448,188);
  DrawTextAt(392,171,ValueText,Black);
  DrawTextAt(122,
    202,'['+Chr(32+56*Ord(AllLines))+Tr('] Inclure la premiere ligne'),
    Black);
  DrawTextAt(122,225,'['+Chr(32+56*Ord(Border))+Tr('] Bordure inferieure'),
    Black);
  DrawTextAt(122,248,'['+Chr(32+56*Ord(PageBreak))+Tr('] Saut de page avant'),
    Black);
  If F=0 Then DrawTextAt(519,137,'*',Blue)
  Else DrawTextAt(510,171+(F-1)*23,'*',Blue);
  FillRectArea(122,272,515,335,White);
  DrawSunkenRect(122,272,515,335);
  Val(ValueText,V,ErrorPos);
  If (ErrorPos<>0) Or (V<0) Or (V>160) Then V:=0;
  SetColor(Black);
  For J:=0 To 3 Do Begin
   StartX:=138;
   If AllLines Or (J>0) Then Inc(StartX,V);
   EndX:=499;
   Width:=EndX-StartX-32;
   If J=3 Then Width:=Width div 2;
   Case A Of
    ALIGN_CENTER: StartX:=StartX+(EndX-StartX-Width) div 2;
    ALIGN_RIGHT: StartX:=EndX-Width;
    ALIGN_JUSTIFY: If J<3 Then Width:=EndX-StartX;
   End;
   Line(StartX,282+J*11,StartX+Width,282+J*11);
  End;
  If Border Then Line(138,327,499,327);
  If (ErrorPos<>0) Or (ValueText='') Or (Length(ValueText)>3) Then
   DrawTextAt(122,343,Tr('Saisir un retrait de 0 a 160 px.'),Black)
  Else DrawTextAt(122,343,Tr('Tab : option   Espace : basculer'),Black);
  DrawButton3D(322,362,414,385,False);
  DrawButton3D(423,362,515,385,False);
  DrawTextAt(332,370,Tr('Appliquer'),Black);
  DrawTextAt(438,370,Tr('Annuler'),Black);
 End;

 Procedure ToggleOption;
 Begin
  Case F Of
   2: AllLines:=Not AllLines;
   3: Border:=Not Border;
   4: PageBreak:=Not PageBreak;
  End;
 End;

 Function TextParagraph(Index: Integer): Boolean;
 Begin
  TextParagraph:=Not Doc^.Paragraphs[Index].IsImage And Not ParaIsTable(Index)
    And Not Doc^.Paragraphs[Index].PDF.Active;
 End;

Begin
 P1:=Cursor.ParaIdx; P2:=P1;
 If SelHasRange Then Begin
  SelGetRange(P1,C1,P2,C2);
  If (P2>P1) And (C2=0) Then Dec(P2);
 End;
 P:=P1;
 While (P<=P2) And Not TextParagraph(P) Do Inc(P);
 If P>P2 Then Begin
  ShowMessage(Tr('Choisir un paragraphe de texte.'));
  Exit;
 End;
 A:=Doc^.Paragraphs[P].Alignment;
 If A>3 Then A:=0;
 Str(Doc^.Paragraphs[P].LeftIndent,ValueText);
 AllLines:=Doc^.Paragraphs[P].FirstLineHang;
 Border:=Doc^.Paragraphs[P].BorderBottom;
 PageBreak:=Doc^.Paragraphs[P].PageBreakBefore;
 F:=0; Fresh:=True; Done:=False; Accept:=False; Prev:=MsBtn;
 Paint;
 Repeat
  Dirty:=False;
  If KeyPressed Then Begin
   K:=ReadKeyEx; Dirty:=True;
   Case K Of
    KEY_ESC: Done:=True;
    KEY_ENTER: AcceptSettings;
    KEY_TAB: Begin F:=(F+1) mod 5; Fresh:=True; End;
    KEY_LEFT: If F=0 Then A:=(A+3) mod 4;
    KEY_RIGHT: If F=0 Then A:=(A+1) mod 4;
    KEY_BACKSPACE: If F=1 Then Begin
     Delete(ValueText,Length(ValueText),1); Fresh:=False;
    End;
    32: ToggleOption;
    48..57: If F=1 Then Begin
     If Fresh Then ValueText:='';
     Fresh:=False;
     If Length(ValueText)<3 Then ValueText:=ValueText+Chr(K);
    End;
   End;
  End;
  EraseSoftCursor;
  GetMouseStateLI(MsX,MsY,MsBtn);
  If Not Done And ((MsBtn and MB_LEFT)<>0) And ((Prev and MB_LEFT)=0) Then Begin
   Dirty:=True;
   X:=MsX; Y:=MsY;
   If (X>=120) And (X<520) And (Y>=128) And (Y<=153) Then Begin
    F:=0; A:=(X-120) div 100;
   End Else If (X>=384) And (X<=448) And (Y>=164) And (Y<=188) Then Begin
    F:=1; Fresh:=True;
   End Else If (X>=122) And (X<=480) And (Y>=196) And (Y<265) Then Begin
    F:=2+(Y-196) div 23; ToggleOption;
   End Else If (Y>=362) And (Y<=385) Then Begin
    If (X>=322) And (X<=414) Then AcceptSettings;
    If (X>=423) And (X<=515) Then Done:=True;
   End;
  End;
  Prev:=MsBtn;
  If Dirty And Not Done Then Paint;
  If Not Done Then Begin
    DrawSoftCursor(MsX,MsY); 
   Delay(10);
  End;
 Until Done;
 EraseSoftCursor;
 NeedsRedraw:=True;
 If Not Accept Then Exit;

 Changed:=False;
 For P:=P1 To P2 Do
  If TextParagraph(P) Then
   With Doc^.Paragraphs[P] Do
    If (Alignment<>A) Or (LeftIndent<>Indent) Or
       (FirstLineHang<>AllLines) Or (BorderBottom<>Border) Or
       (PageBreakBefore<>PageBreak) Then Changed:=True;
 If Not Changed Then Exit;
 PushUndoSnapshot;
 ResetMutation;
 For P:=P1 To P2 Do
  If TextParagraph(P) Then
   With Doc^.Paragraphs[P] Do Begin
    Alignment:=A; LeftIndent:=Indent; FirstLineHang:=AllLines;
    BorderBottom:=Border; PageBreakBefore:=PageBreak;
   End;
 CurrentAlign:=A;
 For I:=4 To 7 Do FmtBar[I].Pressed:=I=4+A;
 Doc^.Modified:=True;
 NeedsRelayout:=True;
End;

{ Moteur et lexiques adaptes de CORRECTEUR-0/HUNSPELL.PAS.
  Copyright (c) 2026 Sylvain Maltais, licence MIT. }
Const MaxWords=2400; MaxSuggestions=5;
Type TWord=String[80]; PWord=^TWord;
Var
 Dictionary: Array[1..MaxWords] of PWord;
 WordCount, SuggestionCount: Integer;
 Suggestions: Array[1..MaxSuggestions] of TWord;
 Scores: Array[1..MaxSuggestions] of Integer;
 DictName: String;
 SpellLanguage: Byte;

Function Lower(S: TWord): TWord;
Var
 P, B: Integer;
Begin
 P := 1;
 While P <= Length(S) Do Begin
  If Copy(S,P,3)=#225#186#158 Then Begin
   Delete(S,P,3); Insert(#195#159,S,P)
  End;
  B := Ord(S[P]);
  If B In [65..90] Then S[P] := Chr(B+32);
  If (B=195) And (P<Length(S)) Then Begin
   Inc(P); B := Ord(S[P]);
   If (B In [128..150,152..158]) Then S[P] := Chr(B+32)
  End Else If (B=197) And (P<Length(S)) Then Begin
   Inc(P); If Ord(S[P])=146 Then S[P] := #147
  End;
  Inc(P)
 End;
 Lower := S
End;
{ Shared vocabulary is copied into this source, never included at compile
  time. Exact spelling retains accents; Fold is only used for ranking. }

Function Fold(S: String): TWord;
Var
 P: Integer;
 C, D: Byte;
 R: TWord;
Begin
 R := ''; P := 1;
 While P <= Length(S) Do Begin
  C := Ord(S[P]);
  If (C >= 65) And (C <= 90) Then C := C + 32;
  If (C = 195) And (P < Length(S)) Then Begin
   Inc(P); D := Ord(S[P]);
   Case D Of
   128..134,160..166: C := 97;
   135,167: C := 99;
   136..139,168..171: C := 101;
   140..143,172..175: C := 105;
   146..150,178..182: C := 111;
   153..156,185..188: C := 117;
   157,189,191: C := 121;
   Else C := 0
  End
 End;
 If C <> 0 Then R := R + Chr(C);
 Inc(P)
End;
Fold := R
End;

Procedure Words(S: String);
Var
 P, B: Integer;
Begin
 P := 1;
 While P <= Length(S) Do Begin
  While (P <= Length(S)) And (S[P] = ' ') Do Inc(P);
  B := P;
  While (P <= Length(S)) And (S[P] <> ' ') Do Inc(P);
  If P > B Then Begin
   If WordCount = MaxWords Then Exit;
   Inc(WordCount); New(Dictionary[WordCount]); Dictionary[WordCount]^ := Copy(S,
     B, P-B)
  End
 End
End;

Procedure FrenchWords;
Begin
 Words(
 'a '#195#160' ai aie aies ait as au aux avec avant apr'#195#168's assez auss'+
   'i autant autre');
 Words('autres aucun aucune');
 Words('alors ainsi aller allons allez allez-vous');
 Words(
 'avoir avons avez avaient avais avait ayant eu eue eus eues aurai auras aura'+
   ' aurons aurez');
 Words('auront');
 Words('aurais aurait auraient');
 Words(
   #195#170'tre suis es est sommes '#195#170'tes sont '#195#169'tai'+
   's '#195#169'tait');
 Words(
   #195#169'tions '#195#169'tiez '#195#169'taient '#195#169't'#195#169' serai'+
   ' seras');
 Words('sera serons serez seront serait seraient sois soit soient');
 Words(
 'bonjour bonsoir salut merci oui non peut-'#195#170'tre voici vo'+
   'il'#195#160' bien mal mieux');
 Words('tr'#195#168's trop peu plus');
 Words('moins beaucoup tout tous toute toutes');
 Words(
 'ce cet cette ces celui celle ceux celles ceci cela '#195#167'a de du des le'+
   ' la les un une et');
 Words('ou o'#195#185);
 Words('mais donc or ni car si sinon');
 Words(
 'je tu il elle on nous vous ils elles me te se moi toi soi lui leur leurs mo'+
   'n ma mes ton ta');
 Words('tes');
 Words('son sa ses notre nos votre vos');
 Words(
 'dans sur sous par pour sans entre vers chez contre depuis pendant durant ma'+
   'lgr'#195#169)
 ;
 Words('selon parmi');
 Words('devant derri'#195#168're');
 Words(
 'ne pas jamais rien personne aucun seulement encore d'#195#169'j'#195#160' t'+
   'oujours souvent');
 Words('parfois quelquefois');
 Words('maintenant aujourd'#226#128#153'hui demain hier');
 Words(
 'ici l'#195#160' ailleurs partout ensemble quand comme comment pourquoi parc'+
   'e que qui quoi');
 Words('dont lequel');
 Words('laquelle lesquels lesquelles');
 Words(
 'chaque plusieurs quelques quelque m'#195#170'me m'#195#170'mes certain cert'+
   'ains certaine');
 Words('certaines tel telle');
 Words('tels telles');
 Words(
 'puis peux peut pouvons pouvez peuvent pouvais pouvait pouvaient pu dois doi'+
   't devons devez');
 Words('doivent devrait devraient d'#195#187);
 Words(
 'fais fait faisons faites font faisais faisait faisaient faire faisant vais '+
   'vas va vont aller');
 Words('viens vient venons venez viennent venir');
 Words(
 'veux veut voulons voulez veulent vouloir sais sait savons savez savent savo'+
   'ir vois voit');
 Words('voyons');
 Words('voyez voient voir');
 Words(
 'dis dit disent dire donne donnes donnent donner prends prend prendre pense '+
   'penses pensent');
 Words('penser aime aimes aiment aimer');
 Words(
 'parle parles parlent parlons parlez parler mange manges mangent mangeons ma'+
   'ngez manger')
 ;
 Words('travaille travaillent travailler');
 Words(
 'habite habitent habiter regarde regardent regarder trouve trouvent trouver '+
   'semble semblent');
 Words('sembler reste restent rester');
 Words(
 'faut fallait fallait falloir pleut pleuvoir existe existent existe'+
   'z '#195#169'crit');
 Words(#195#169'cris '#195#169'crivent');
 Words(#195#169'crire lire lis lit lisent lu lue');
 Words(
 'bonjour monde texte textes fichier fichiers phrase phrases mot mots mot-'+
   'cl'#195#169' exemple');
 Words('exemples');
 Words('erreur erreurs faute fautes');
 Words(
 'fran'#195#167'ais fran'#195#167'aise fran'#195#167'aises langue langues gra'+
   'mmaire orthographe');
 Words('correction correcteur');
 Words('correcteurs dictionnaire rapport r'#195#169'sultat r'#195#169'sultats');
 Words(
 'petit petits petite petites grand grands grande grandes bon bons bonne bonn'+
   'es mauvais');
 Words('mauvaise');
 Words('mauvaises beau beaux belle belles');
 Words(
 'nouveau nouveaux nouvelle nouvelles vieux vieille vieilles jeune jeunes jol'+
   'i jolis jolie');
 Words('jolies');
 Words('heureux heureuse heureuses');
 Words(
 'chat chats chatte chattes chien chiens chienne chiennes animal animaux chev'+
   'al chevaux oiseau');
 Words('oiseaux poisson poissons');
 Words(
 'maison maisons jardin jardins voiture voitures livre livres '#195#169'col'+
   'e '#195#169'coles');
 Words('classe classes');
 Words(#195#169'l'#195#168've '#195#169'l'#195#168'ves enfant enfants');
 Words(
 'homme hommes femme femmes fille filles gar'#195#167'on gar'#195#167'ons ami'+
   ' amis amie amies');
 Words('famille familles');
 Words('p'#195#168're m'#195#168're fr'#195#168're soeur s'#197#147'ur');
 Words(
 'jour jours nuit nuits matin matins soir soirs semaine semaines mois a'+
   'nn'#195#169'e');
 Words('ann'#195#169'es an ans heure');
 Words('heures minute minutes temps');
 Words(
 'eau pain vin lait caf'#195#169' th'#195#169' pomme pommes fruit fruits repa'+
   's table tables');
 Words('chaise chaises porte');
 Words('portes fen'#195#170'tre fen'#195#170'tres');
 Words('ville villes pays rue rues route routes chemin chemins train trains a'+
   'vion avions')
 ;
 Words('v'#195#169'lo bateau');
 Words('bateaux travail travaux bureau bureaux');
 Words(
 'ordinateur ordinateurs programme programmes information informations sy'+
   'st'#195#168'me');
 Words('syst'#195#168'mes');
 Words('donn'#195#169'es document documents ligne lignes');
 Words(
 'important importants importante importantes possible possibles impossible i'+
   'mpossibles simple');
 Words('simples difficile difficiles facile faciles');
 Words('vrai vrais vraie vraies faux fausse fausses premier premiers pre'+
   'mi'#195#168're');
 Words('premi'#195#168'res dernier');
 Words('derniers derni'#195#168're derni'#195#168'res');
 Words(
 'rouge rouges vert verts verte vertes bleu bleus bleue bleues blanc blancs b'+
   'lanche blanches');
 Words('noir');
 Words('noirs noire noires');
 Words(
 'gentil gentils gentille gentilles content contents contente contentes heure'+
   'ux heureuse triste');
 Words('tristes fatigu'#195#169' fatigu'#195#169's fatigu'#195#169'e fati'+
   'gu'#195#169'es');
 Words(
 'deux trois quatre cinq six sept huit neuf dix onze douze cent cents mille m'+
   'illion millions');
 Words('z'#195#169'ro');
 Words(
 'chose choses probl'#195#168'me probl'#195#168'mes question questions'+
   ' r'#195#169'ponse');
 Words('r'#195#169'ponses raison raisons besoin');
 Words('besoins point points cas mani'#195#168're fa'#195#167'on');
 Words('d'#195#169'but fin suite partie parties place places'+
   ' c'#195#180't'#195#169);
 Words('c'#195#180't'#195#169's droit droite gauche centre nord sud');
 Words('ouest');
 Words(
 'vraiment simplement rapidement lentement facilement correctement notammen'+
   't '#195#169'galement');
 Words('cependant');
 Words('pourtant ensuite enfin plut'#195#180't presque');
 Words(
 'attention accord accords nom noms verbe verbes sujet sujets adjectif adject'+
   'ifs pluriel')
 ;
 Words('singulier f'#195#169'minin masculin');
 Words(
 'merci monsieur madame bon bonne journ'#195#169'e bienvenue bient'#195#180't'+
   ' revoir plaisir');
 Words('sant'#195#169' vie mort');
 Words('amour paix');
 Words(
 'pris prise compris comprendre appris apprendre ouvert ouvrir fe'+
   'rm'#195#169' fermer');
 Words('re'#195#167'u recevoir');
 Words('envoy'#195#169' envoyer utilis'#195#169' utiliser');
 Words(
 'besoin envie peur raison tort cours course histoire histoires musique film '+
   'films photo photos');
 Words('image images');
 Words('l d j c n s t m qu jusqu lorsqu puisqu aujourd hui est-ce');
End;

Procedure EnglishWords;
Begin
 Words('a an the this that these those i you he she it we they me him her us '+
   'them');
 Words('my your his its our their mine yours hers ours theirs myself yourself'+
   ' himself');
 Words('herself itself ourselves yourselves themselves who whom whose which w'+
   'hat');
 Words('am is are was were be been being have has had having do does did done'+
   ' doing');
 Words('will would shall should can could may might must ought need dare not '+
   'no yes');
 Words('and or but if then else because so although though while until unless'+
   ' since');
 Words('as than whether either neither both all any some each every much many'+
   ' few');
 Words('more most less least other another such same only own enough several '+
   'none');
 Words('in on at to from by for with without of about above below over under '+
   'between');
 Words('through across along around against among before after during into on'+
   'to upon');
 Words('up down out off away back here there where when why how now very too '+
   'also');
 Words('just still already yet always never ever often sometimes usually agai'+
   'n once');
 Words('twice together apart almost quite rather really well even perhaps may'+
   'be');
 Words('hello hi goodbye welcome please thanks thank sorry excuse okay ok de'+
   'ar');
 Words('world word words text texts file files document documents line lines '+
   'page pages');
 Words('spell spelling checker check checks checked checking correct correcti'+
   'on corrections');
 Words('error errors mistake mistakes suggestion suggestions dictionary dicti'+
   'onaries');
 Words('english french language languages sentence sentences grammar letter l'+
   'etters');
 Words('write writes writing written wrote read reads reading reader readers '+
   'book books');
 Words('say says said tell tells told speak speaks speaking spoken talk talks'+
   ' talking');
 Words('go goes going gone went come comes coming came get gets getting got');
 Words('make makes making made take takes taking taken took give gives giving'+
   ' given gave');
 Words('see sees seeing seen saw look looks looking looked watch watches watc'+
   'hed');
 Words('know knows knowing known knew think thinks thinking thought understan'+
   'd understood');
 Words('want wants wanted like likes liked love loves loved hate hates hated');
 Words('work works working worked use uses using used try tries trying tried');
 Words('help helps helping helped find finds finding found keep keeps kept');
 Words('learn learns learned learning teach teaches teaching taught study stu'+
   'dies');
 Words('play plays playing played run runs running ran walk walks walked walk'+
   'ing');
 Words('eat eats eating eaten ate drink drinks drinking drunk drank sleep sle'+
   'eps slept');
 Words('live lives lived living move moves moved moving leave leaves leaving '+
   'left');
 Words('put puts putting let lets letting set sets setting sit sits sitting s'+
   'at');
 Words('stand stands standing stood open opens opened close closes closed');
 Words('start starts started starting stop stops stopped stopping finish fini'+
   'shed');
 Words('change changes changed changing turn turns turned turning bring bring'+
   's brought');
 Words('buy buys buying bought sell sells selling sold pay pays paying paid');
 Words('send sends sending sent receive receives received receiving believe b'+
   'elieves');
 Words('believed believing achieve achieved achieving become becomes became b'+
   'ecome');
 Words('happen happens happened happening occur occurs occurred occurring');
 Words('remember remembers remembered forget forgets forgot forgotten');
 Words('worry worries worried worrying hope hopes hoped hoping wish wishes wi'+
   'shed');
 Words('feel feels feeling felt hear hears hearing heard meet meets meeting m'+
   'et');
 Words('good better best bad worse worst new old young great small big large '+
   'little');
 Words('long short tall high low wide narrow early late first last next previ'+
   'ous');
 Words('happy sad easy difficult simple hard possible impossible true false r'+
   'ight wrong');
 Words('beautiful nice pretty ugly important different interesting useful car'+
   'eful');
 Words('quick fast slow quiet loud clear clean dirty full empty hot cold warm'+
   ' cool');
 Words('red green blue yellow black white brown orange purple pink grey gray');
 Words('one two three four five six seven eight nine ten eleven twelve hundre'+
   'd thousand');
 Words('zero million number numbers time times day days night nights morning '+
   'evening');
 Words('today yesterday tomorrow week weeks month months year years hour hour'+
   's minute');
 Words('minutes second seconds monday tuesday wednesday thursday friday satur'+
   'day sunday');
 Words('january february march april may june july august september october n'+
   'ovember december');
 Words('man men woman women child children boy boys girl girls baby babies pe'+
   'rson people');
 Words('friend friends family families father mother brother sister son daugh'+
   'ter parent parents');
 Words('name names home homes house houses room rooms door doors window windo'+
   'ws');
 Words('table tables chair chairs bed beds kitchen garden school schools clas'+
   's classes');
 Words('student students teacher teachers lesson lessons office business comp'+
   'any companies');
 Words('job jobs money price prices shop shops store stores market markets');
 Words('city cities town towns country countries street streets road roads ca'+
   'r cars');
 Words('bus buses train trains plane planes boat boats bike bikes bicycle bic'+
   'ycles');
 Words('water food bread milk tea coffee apple apples fruit fruits vegetable '+
   'vegetables');
 Words('meat fish egg eggs rice potato potatoes tomato tomatoes cheese sugar '+
   'salt');
 Words('cat cats dog dogs horse horses bird birds animal animals tree trees f'+
   'lower flowers');
 Words('sun moon star stars sky rain snow wind weather sea river mountain mou'+
   'ntains');
 Words('computer computers program programs software hardware system systems '+
   'data');
 Words('information message messages email emails internet network networks w'+
   'ebsite websites');
 Words('screen screens keyboard mouse button buttons folder folders command c'+
   'ommands');
 Words('option options parameter parameters code source output input result r'+
   'esults');
 Words('report reports test tests testing version versions update updates upd'+
   'ated');
 Words('question questions answer answers problem problems solution solutions'+
   ' example examples');
 Words('idea ideas reason reasons fact facts way ways thing things part parts'+
   ' place places');
 Words('story stories history music song songs film films movie movies pictur'+
   'e pictures');
 Words('image images photo photos game games team teams life health peace lo'+
   've');
 Words('public private free available special general common local national i'+
   'nternational');
 Words('quickly slowly carefully correctly especially probably actually certa'+
   'inly');
 Words('really simply usually finally recently suddenly immediately unfortuna'+
   'tely');
 Words('beautifully definitely necessary separate receive address addresses t'+
   'omorrow');
 Words('beginning accommodation environment government successful success bus'+
   'iness');
 Words('don doesn didn couldn wouldn shouldn isn aren wasn weren hasn haven h'+
   'adn');
 Words('mustn needn won shan t s m d re ve ll ain');
 If DictName='en_GB' Then Begin
  Words('colour colours coloured colouring favourite favourites neighbour nei'+
    'ghbours');
  Words('centre centres theatre theatres metre metres litre litres honour hon'+
    'ours');
  Words('behaviour organise organises organised organising organisation organ'+
    'isations');
  Words('recognise recognised realise realised travelling travelled traveller'+
    ' travellers');
  Words('programme programmes defence licence licences practise practised lea'+
    'rnt got')
 End Else Begin
  Words('color colors colored coloring favorite favorites neighbor neighbors');
  Words('center centers theater theaters meter meters liter liters honor hono'+
    'rs');
  Words('behavior organize organizes organized organizing organization organi'+
    'zations');
  Words('recognize recognized realize realized traveling traveled traveler tr'+
    'avelers');
  Words('defense license licenses practice practiced learned gotten')
 End
End;

Procedure GermanWords;
Begin
 Words(#195#150'l');
 Words('ich du er sie es wir ihr mich dich ihn uns euch mir dir ihm ihnen');
 Words('mein meine meinen meinem meiner meines dein deine sein seine unser un'+
   'sere euer eure');
 Words('der die das den dem des ein eine einen einem einer eines kein keine k'+
   'einen keiner');
 Words('dieser diese dieses diesen diesem jeder jede jedes alle alles beide v'+
   'iele viel wenige');
 Words('etwas nichts man jemand niemand selbst bin bist ist sind seid war war'+
   'st waren wart');
 Words('gewesen sein habe hast hat haben habt hatte hatten gehabt werde wirst'+
   ' wird werden');
 Words('wurde wurden worden und oder aber denn weil wenn als dass ob obwohl d'+
   'amit bevor');
 Words('nachdem bis seit w'#195#164'hrend sondern also doch nur auch noch sch'+
   'on sehr mehr weniger');
 Words('am an auf aus bei mit nach von zu zum zur f'#195#188'r '#195#188'ber '+
   'unter vor hinter neben');
 Words('zwischen');
 Words('ohne gegen durch um im ins beim vom ja nein nicht bitte danke gern ge'+
   'rne heute morgen');
 Words('gestern jetzt hier dort da immer nie niemals oft manchmal bald wieder'+
   ' zusammen allein');
 Words('vielleicht wirklich leider einfach ziemlich besonders kann kannst'+
   ' k'#195#182'nnen');
 Words('k'#195#182'nnt konnte');
 Words('konnten darf darfst d'#195#188'rfen d'#195#188'rft muss musst'+
   ' m'#195#188'ssen m'#195#188'sst');
 Words('musste mussten soll sollst');
 Words('sollen sollt sollte sollten will willst wollen wollt wollte wollten'+
   ' m'#195#182'chte');
 Words('m'#195#182'chten');
 Words('gut gute guten guter gutes besser beste schlecht schlechte klein klei'+
   'ne kleinen');
 Words('gro'#195#159' gro'#195#159'e gro'#195#159'en sch'#195#182'n s'+
   'ch'#195#182'ne sch'#195#182'nen');
 Words('sch'#195#182'nes neu neue neuen alt alte alten jung junge');
 Words('lang lange kurz kurze hoch hohe niedrig richtig falsch wichtig'+
   ' m'#195#182'glich');
 Words('unm'#195#182'glich leicht');
 Words('schwer schnell langsam fr'#195#188'h sp'#195#164't warm kalt h'+
   'ei'#195#159' frei offen');
 Words('geschlossen m'#195#188'de gl'#195#188'cklich');
 Words('traurig freundlich klar sauber leer voll Hallo hallo Welt Tag Tage Na'+
   'cht N'#195#164'chte');
 Words('Morgen');
 Words('Abend Woche Wochen Monat Monate Jahr Jahre Stunde Stunden Minute Minu'+
   'ten Zeit Zeiten');
 Words('Montag Dienstag Mittwoch Donnerstag Freitag Samstag Sonntag Januar Fe'+
   'bruar M'#195#164'rz April');
 Words('Mai Juni Juli August September Oktober November Dezember Mensch Mensc'+
   'hen Mann M'#195#164'nner');
 Words('Frau Frauen Kind Kinder Junge Jungen M'#195#164'dchen Baby Familie Va'+
   'ter Mutter Eltern Bruder');
 Words('Schwester Sohn Tochter Freund Freunde Freundin Name Namen Haus'+
   ' H'#195#164'user Wohnung Zimmer');
 Words('T'#195#188'r T'#195#188'ren Fenster Tisch Stuhl Bett K'#195#188'che G'+
   'arten Schule Schulen');
 Words('Lehrer Lehrerin Sch'#195#188'ler');
 Words('Sch'#195#188'lerin Klasse Universit'#195#164't Buch B'#195#188'cher S'+
   'eite Seiten Brief Briefe');
 Words('Wort W'#195#182'rter Satz S'#195#164'tze');
 Words('Text Texte Sprache Sprachen Deutsch Englisch Franz'#195#182'sisch Gra'+
   'mmatik Rechtschreibung');
 Words('Fehler Korrektur W'#195#182'rterbuch Vorschlag Vorschl'#195#164'ge Da'+
   'tei Dateien Zeile Zeilen');
 Words('Zeichen');
 Words('Dokument Dokumente Programm Programme Computer Rechner Tastatur Maus '+
   'Bildschirm Internet');
 Words('Nachricht Nachrichten Daten System Ausgabe Eingabe Ergebnis Ergebniss'+
   'e Befehl Befehle');
 Words('Option Optionen Test Tests Version Hilfe Frage Fragen Antwort Antwort'+
   'en Problem Probleme');
 Words('L'#195#182'sung L'#195#182'sungen Beispiel Beispiele Stadt '+
   'St'#195#164'dte Land');
 Words('L'#195#164'nder Dorf D'#195#182'rfer Stra'#195#159'e Stra'#195#159'en');
 Words('Weg Wege Auto Autos Bus Zug Z'#195#188'ge Bahn Bahnhof Flugzeug Fahrr'+
   'ad Reise Reisen Arbeit');
 Words('Beruf');
 Words('B'#195#188'ro Geld Preis Gesch'#195#164'ft Laden Markt Wasser Brot Mi'+
   'lch Kaffee Tee Apfel');
 Words(#195#132'pfel Obst Gem'#195#188'se');
 Words('Fleisch Fisch Ei Eier Reis Kartoffel Kartoffeln Tomate Tomaten'+
   ' K'#195#164'se Zucker Salz Essen');
 Words('Fr'#195#188'hst'#195#188'ck Mittagessen Abendessen Hund Hunde Katze K'+
   'atzen Tier Tiere Pferd');
 Words('Vogel V'#195#182'gel');
 Words('Baum B'#195#164'ume Blume Blumen Sonne Mond Stern Sterne Himmel Regen'+
   ' Schnee Wind Wetter See');
 Words('Meer');
 Words('Fluss Berg Berge Wald Feuer Erde Luft Hand H'#195#164'nde '+
   'Fu'#195#159' F'#195#188#195#159'e');
 Words('Kopf Auge Augen Ohr Ohren Herz');
 Words('Leben Gesundheit Frieden Liebe Musik Lied Lieder Film Filme Bild Bild'+
   'er Spiel Spiele');
 Words('Sport Urlaub Deutschland Berlin M'#195#188'nchen '#195#150'sterreich '+
   'Schweiz gehen geht gehe');
 Words('gehst ging');
 Words('gingen gegangen kommen kommt komme kommst kam kamen gekommen machen m'+
   'acht mache machst');
 Words('gemacht sagen sagt sage sagst sagte gesagt sehen sieht sehe siehst sa'+
   'h gesehen h'#195#182'ren');
 Words('h'#195#182'rt h'#195#182're geh'#195#182'rt lesen liest lese las gele'+
   'sen schreiben schreibt');
 Words('schreibe geschrieben');
 Words('sprechen spricht spreche gesprochen lernen lernt lerne gelernt arbeit'+
   'en arbeitet arbeite');
 Words('gearbeitet spielen spielt spiele gespielt wohnen wohnt wohne gewohnt '+
   'leben lebt lebe gelebt');
 Words('lieben liebt liebe geliebt hei'#195#159'en hei'#195#159't h'+
   'ei'#195#159'e essen isst esse');
 Words('gegessen trinken trinkt');
 Words('trinke getrunken schlafen schl'#195#164'ft schlafe geschlafen fahren'+
   ' f'#195#164'hrt fahre');
 Words('gefahren laufen');
 Words('l'#195#164'uft laufe gelaufen geben gibt gebe gegeben nehmen nimmt ne'+
   'hme genommen finden');
 Words('findet');
 Words('finde gefunden wissen wei'#195#159' wusste gewusst denken denkt denke'+
   ' gedacht glauben glaubt');
 Words('glaube geglaubt verstehen versteht verstehe verstanden fragen fragt f'+
   'rage gefragt');
 Words('antworten antwortet helfen hilft helfe geholfen brauchen braucht brau'+
   'che gebraucht suchen');
 Words('sucht suche gesucht kaufen kauft kaufe gekauft bezahlen bezahl'+
   't '#195#182'ffnen');
 Words(#195#182'ffnet ge'#195#182'ffnet');
 Words('schlie'#195#159'en schlie'#195#159't geschlossen beginnen beginnt beg'+
   'onnen bleiben bleibt');
 Words('geblieben bringen');
 Words('bringt gebracht stehen steht gestanden sitzen sitzt gesessen liegen l'+
   'iegt gelegen tragen');
 Words('tr'#195#164'gt getragen zeigen zeigt gezeigt benutzen benutzt korrigi'+
   'eren korrigiert');
 Words('pr'#195#188'fen pr'#195#188'ft');
 Words('gepr'#195#188'ft speichern speichert gespeichert '#195#164'nder'+
   'n '#195#164'ndert');
 Words('ge'#195#164'ndert funktionieren funktioniert');
 Words('versuchen versucht freuen freut treffen trifft getroffen halten'+
   ' h'#195#164'lt gehalten');
 Words('vergessen');
 Words('vergisst bekommen bekommt erkl'#195#164'ren erkl'#195#164'rt bestelle'+
   'n bestellt');
 Words('w'#195#188'nschen w'#195#188'nscht gew'#195#188'nscht');
 Words('danken dankt gedankt begr'#195#188#195#159'en begr'#195#188#195#159't'+
   ' besuchen besucht reisen');
 Words('reist gereist rot gr'#195#188'n blau');
 Words('gelb schwarz wei'#195#159' braun grau rosa orange eins zwei drei vier'+
   ' f'#195#188'nf sechs');
 Words('sieben acht neun');
 Words('zehn elf zw'#195#182'lf hundert tausend null Million Millionen erste '+
   'zweite dritte letzte');
 Words('n'#195#164'chste');
 Words('andere einigen einige deshalb deswegen trotzdem au'#195#159'erdem'+
   ' n'#195#164'mlich bisschen');
 Words('Gr'#195#188#195#159'e Gru'#195#159);
 Words('gr'#195#182#195#159'er gr'#195#182#195#159'te Spa'#195#159' '+
   'au'#195#159'en s'#195#188#195#159);
 Words('Fu'#195#159'g'#195#164'nger Fu'#195#159'ball Stra'#195#159'enbahnen H'+
   'aust'#195#188'r');
 Words('Sonnenlicht');
 Words('Krankenhaus Geburtstag Wochenende Weihnachten');
End;

Procedure SpanishWords;
Begin
 Words(#195#177'and'#195#186);
 Words('yo t'#195#186' '#195#169'l ella usted nosotros nosotras vosotros voso'+
   'tras ellos ellas ustedes');
 Words('me te se nos os lo la los las le les mi mis tu tus su sus nuestro nue'+
   'stra nuestros');
 Words('nuestras vuestro vuestra vuestros vuestras m'#195#173'o m'#195#173'a '+
   'tuyo tuya suyo suya');
 Words('contigo conmigo');
 Words('el un una unos unas este esta estos estas ese esa esos esas aquel aqu'+
   'ella aquellos');
 Words('aquellas esto eso aquello cada todo toda todos todas otro otra otros '+
   'otras alguno alguna');
 Words('algunos algunas ninguno ninguna mucho mucha muchos muchas poco poca p'+
   'ocos pocas');
 Words('varios varias ambos ambas mismo misma mismos mismas alguien nadie alg'+
   'o nada quien');
 Words('quienes cuyo cuya cuyos cuyas qu'#195#169' qui'#195#169'n '+
   'cu'#195#161'l cu'#195#161'les');
 Words('cu'#195#161'nto cu'#195#161'nta cu'#195#161'ntos cu'#195#161'ntas');
 Words('soy eres es somos sois son era eras '#195#169'ramos erais eran fui fu'+
   'iste fue fuimos fuisteis');
 Words('fueron sido siendo ser sea seas seamos se'#195#161'is sean s'+
   'er'#195#161' ser'#195#161'n');
 Words('ser'#195#173'a ser'#195#173'an');
 Words('estoy est'#195#161's est'#195#161' estamos est'#195#161'is e'+
   'st'#195#161'n estaba estabas');
 Words('est'#195#161'bamos estaban estado estar');
 Words('est'#195#169' est'#195#169's estemos est'#195#169'n estar'#195#161' e'+
   'star'#195#161'n');
 Words('estar'#195#173'a tengo tienes tiene tenemos ten'#195#169'is');
 Words('tienen ten'#195#173'a ten'#195#173'an tuve tuvo tuvieron tenido tener'+
   ' tenga tengan');
 Words('tendr'#195#161' tendr'#195#161'n');
 Words('he has ha hemos hab'#195#169'is han hab'#195#173'a hab'#195#173'an hu'+
   'bo habido haber hay haya');
 Words('hayan habr'#195#161);
 Words('y e o u pero porque aunque sino si s'#195#173' no ni que como'+
   ' c'#195#179'mo cuando');
 Words('cu'#195#161'ndo donde d'#195#179'nde');
 Words('mientras entonces pues tambi'#195#169'n tampoco adem'#195#161's '+
   'as'#195#173' a'#195#186'n aun');
 Words('ya todav'#195#173'a siempre nunca');
 Words('jam'#195#161's ahora hoy ayer ma'#195#177'ana antes despu'#195#169's '+
   'luego pronto tarde');
 Words('temprano aqu'#195#173' ah'#195#173' all'#195#173);
 Words('all'#195#161' cerca lejos dentro fuera arriba abajo delante de'+
   'tr'#195#161's m'#195#161's mas');
 Words('menos muy tan tanto');
 Words('bien mal mejor peor solo sola solamente casi bastante demasiado qu'+
   'iz'#195#161's quiz'#195#161);
 Words('realmente');
 Words('de del a al en con sin por para desde hasta entre sobre bajo contra h'+
   'acia seg'#195#186'n');
 Words('durante');
 Words('hola adi'#195#179's gracias favor perd'#195#179'n disculpa disculpe b'+
   'ienvenido bienvenida');
 Words('salud saludos');
 Words('buen bueno buena buenos buenas malo mala malos malas nuevo nueva nuev'+
   'os nuevas');
 Words('viejo vieja viejos viejas joven j'#195#179'venes grande grandes peq'+
   'ue'#195#177'o');
 Words('peque'#195#177'a peque'#195#177'os');
 Words('peque'#195#177'as bonito bonita bonitos bonitas hermoso hermosa feliz'+
   ' felices triste tristes');
 Words('f'#195#161'cil f'#195#161'ciles dif'#195#173'cil dif'#195#173'ciles i'+
   'mportante importantes');
 Words('posible imposible necesario');
 Words('necesaria diferente diferencias igual iguales r'#195#161'pido'+
   ' r'#195#161'pida lento lenta');
 Words('primero primera');
 Words('primer '#195#186'ltimo '#195#186'ltima pr'#195#179'ximo pr'#195#179'x'+
   'ima largo larga corto');
 Words('corta alto alta bajo baja');
 Words('caliente fr'#195#173'o fr'#195#173'a limpio limpia abierto abierta ce'+
   'rrado cerrada libre');
 Words('gratis correcto');
 Words('correcta incorrecto verdadero verdadera falso falsa claro clara segur'+
   'o segura');
 Words('mundo palabra palabras texto textos archivo archivos documento docume'+
   'ntos l'#195#173'nea');
 Words('l'#195#173'neas');
 Words('p'#195#161'gina p'#195#161'ginas letra letras frase frases ora'+
   'ci'#195#179'n oraciones idioma');
 Words('idiomas lengua lenguas');
 Words('espa'#195#177'ol espa'#195#177'ola espa'#195#177'oles espa'#195#177'o'+
   'las franc'#195#169's');
 Words('francesa ingl'#195#169's inglesa alem'#195#161'n alemana');
 Words('gram'#195#161'tica ortograf'#195#173'a error errores falta faltas cor'+
   'recci'#195#179'n');
 Words('correcciones diccionario');
 Words('diccionarios sugerencia sugerencias programa programas ordenador orde'+
   'nadores computadora');
 Words('computadoras sistema sistemas informaci'#195#179'n datos entrada sali'+
   'da resultado resultados');
 Words('informe informes prueba pruebas versi'#195#179'n versiones op'+
   'ci'#195#179'n opciones comando');
 Words('comandos');
 Words('c'#195#179'digo fuente pantalla teclado rat'#195#179'n internet mensa'+
   'je mensajes correo');
 Words('electr'#195#179'nico');
 Words('pregunta preguntas respuesta respuestas problema problemas solu'+
   'ci'#195#179'n soluciones');
 Words('ejemplo');
 Words('ejemplos ayuda n'#195#186'mero n'#195#186'meros nombre nombres direc'+
   'ci'#195#179'n direcciones');
 Words('tel'#195#169'fono tel'#195#169'fonos');
 Words('d'#195#173'a d'#195#173'as noche noches hora horas minuto minutos seg'+
   'undo segundos semana');
 Words('semanas mes');
 Words('meses a'#195#177'o a'#195#177'os tiempo tiempos lunes martes '+
   'mi'#195#169'rcoles jueves viernes');
 Words('s'#195#161'bado domingo');
 Words('enero febrero marzo abril mayo junio julio agosto septiembre octubre '+
   'noviembre diciembre');
 Words('cero uno dos tres cuatro cinco seis siete ocho nueve diez once doce c'+
   'ien ciento mil');
 Words('mill'#195#179'n millones persona personas hombre hombres mujer mujere'+
   's ni'#195#177'o');
 Words('ni'#195#177'os ni'#195#177'a ni'#195#177'as');
 Words('beb'#195#169' beb'#195#169's familia familias padre madre padres hijo'+
   ' hijos hija hijas hermano');
 Words('hermana');
 Words('abuelo abuela amigo amigos amiga amigas se'#195#177'or se'#195#177'or'+
   'a se'#195#177'ores');
 Words('se'#195#177'orita gente');
 Words('casa casas hogar habitaci'#195#179'n habitaciones cuarto cuartos puer'+
   'ta puertas ventana');
 Words('ventanas');
 Words('mesa mesas silla sillas cama camas cocina ba'#195#177'o ba'#195#177'o'+
   's jard'#195#173'n');
 Words('jardines escuela escuelas');
 Words('colegio universidad clase clases alumno alumnos alumna profesor profe'+
   'sora estudiante');
 Words('estudiantes lecci'#195#179'n lecciones libro libros cuaderno cuaderno'+
   's l'#195#161'piz');
 Words('l'#195#161'pices papel');
 Words('ciudad ciudades pueblo pueblos pa'#195#173's pa'#195#173'ses calle ca'+
   'lles camino caminos coche');
 Words('coches');
 Words('auto autos autob'#195#186's autobuses tren trenes avi'#195#179'n avio'+
   'nes barco barcos');
 Words('bicicleta bicicletas');
 Words('viaje viajes estaci'#195#179'n aeropuerto hospital oficina trabajo tr'+
   'abajos dinero precio');
 Words('precios');
 Words('tienda tiendas mercado mercados empresa empresas negocio negocios agu'+
   'a pan leche caf'#195#169);
 Words('t'#195#169);
 Words('fruta frutas manzana manzanas naranja naranjas pl'#195#161'tano arroz'+
   ' carne pescado huevo');
 Words('huevos');
 Words('patata patatas tomate tomates queso az'#195#186'car sal aceite comida'+
   ' desayuno almuerzo cena');
 Words('perro perros gato gatos animal animales caballo caballos p'#195#161'j'+
   'aro p'#195#161'jaros pez');
 Words('peces');
 Words(
   #195#161'rbol '#195#161'rboles flor flores bosque monta'#195#177'a mon'+
   'ta'#195#177'as');
 Words('r'#195#173'o r'#195#173'os mar playa sol luna estrella');
 Words('estrellas cielo tierra lluvia nieve viento fuego aire mano manos pie '+
   'pies cabeza ojo');
 Words('ojos oreja orejas coraz'#195#179'n vida muerte amor paz m'#195#186'si'+
   'ca canci'#195#179'n');
 Words('canciones pel'#195#173'cula foto');
 Words('fotos imagen im'#195#161'genes juego juegos deporte equipo fiesta cum'+
   'plea'#195#177'os Navidad');
 Words('Espa'#195#177'a Madrid');
 Words('M'#195#169'xico Argentina Chile Colombia Per'#195#186' Am'#195#169'ri'+
   'ca Europa verano invierno');
 Words('primavera oto'#195#177'o');
 Words('rojo roja verde verdes azul azules amarillo amarilla blanco blanca ne'+
   'gro negra gris');
 Words('rosa marr'#195#179'n color colores punto puntos parte partes lugar lu'+
   'gares cosa cosas');
 Words('raz'#195#179'n');
 Words('razones verdad historia historias idea ideas luz noche fuerza cara fo'+
   'rma formas');
 Words('hacer hago haces hace hacemos hacen hice hizo hecho haciendo h'+
   'ar'#195#169' har'#195#161);
 Words('hacemos');
 Words('ir voy vas va vamos vais van iba iban ido yendo vaya vayan fui fue fu'+
   'eron');
 Words('venir vengo vienes viene venimos vienen vino venido decir digo dices '+
   'dice decimos');
 Words('dicen dijo dicho hablar hablo hablas habla hablamos hablan hablado ha'+
   'blando');
 Words('leer leo lees lee leemos leen le'#195#173'do leyendo escribir escribo'+
   ' escribes escribe');
 Words('escribimos escriben escrito escribiendo ver veo ves ve vemos ven vist'+
   'o viendo');
 Words('mirar miro miras mira miramos miran mirado escuchar escucho escucha e'+
   'scuchan escuchado');
 Words('saber s'#195#169' sabes sabe sabemos saben sab'#195#173'a s'+
   'ab'#195#173'a sabido conocer');
 Words('conozco conoce conocemos');
 Words('conocen conocido pensar pienso piensas piensa pensamos piensan pensad'+
   'o creer creo cree');
 Words('creemos creen cre'#195#173'do entender entiendo entiendes entiende en'+
   'tendemos entienden');
 Words('entendido');
 Words('comprender comprendo comprende comprenden comprendido aprender aprend'+
   'o aprende aprendemos');
 Words('aprenden aprendido ense'#195#177'ar ense'#195#177'o ense'#195#177'a e'+
   'nse'#195#177'an');
 Words('ense'#195#177'ado querer quiero quieres quiere');
 Words('queremos quieren querido poder puedo puedes puede podemos pueden p'+
   'od'#195#173'a');
 Words('podr'#195#173'an podido');
 Words('deber debo debes debe debemos deben debido necesitar necesito necesit'+
   'a necesitamos');
 Words('necesitan necesitado gustar gusta gustan gustado amar amo amas ama am'+
   'amos aman amado');
 Words('comer como comes come comemos comen comido comiendo beber bebo bebes '+
   'bebe bebemos beben');
 Words('bebido vivir vivo vives vive vivimos viven vivido dormir duermo duerm'+
   'e duermen dormido');
 Words('trabajar trabajo trabajas trabaja trabajamos trabajan trabajado estud'+
   'iar estudio estudias');
 Words('estudia estudiamos estudian estudiado jugar juego juegas juega jugamo'+
   's juegan jugado');
 Words('correr corro corre corren corrido caminar camino camina caminan camin'+
   'ado comprar compro');
 Words('compra compran comprado vender vendo vende venden vendido pagar pago '+
   'paga pagan pagado');
 Words('dar doy das da damos dan dado tomar tomo toma toman tomado llevar lle'+
   'vo lleva llevan');
 Words('llevado traer traigo trae traen tra'#195#173'do poner pongo pones pon'+
   'e ponemos ponen puesto');
 Words('salir salgo sale salen salido llegar llego llega llegan llegado pasar'+
   ' paso pasa pasan');
 Words('pasado quedar quedo queda quedan quedado dejar dejo deja dejan dejado'+
   ' buscar busco busca');
 Words('buscan buscado encontrar encuentro encuentra encuentran encontrado es'+
   'perar espero espera');
 Words('esperan esperado ayudar ayudo ayuda ayudan ayudado abrir abro abre ab'+
   'ren abierto');
 Words('cerrar cierro cierra cierran cerrado empezar empiezo empieza empiezan'+
   ' empezado terminar');
 Words('termino termina terminan terminado cambiar cambio cambia cambian camb'+
   'iado usar uso usa');
 Words('usan usado corregir corrijo corrige corrigen corregido comprobar comp'+
   'ruebo comprueba');
 Words('guardar guardo guarda guardan guardado enviar env'#195#173'o e'+
   'nv'#195#173'a env'#195#173'an');
 Words('enviado recibir recibo');
 Words('recibe reciben recibido volver vuelvo vuelve vuelven vuelto recordar '+
   'recuerdo recuerda');
 Words('olvidar olvido olvida olvidado repetir repito repite repetido pedir p'+
   'ido pide pedido');
 Words('gracias actualmente especialmente probablemente simplemente'+
   ' r'#195#161'pidamente lentamente');
 Words('correctamente finalmente completamente f'#195#161'cilmente completame'+
   'nte ping'#195#188'ino');
 Words('ping'#195#188'inos');
 Words('verg'#195#188'enza biling'#195#188'e ling'#195#188#195#173'stica tam'+
   'bi'#195#169'n');
 Words('despu'#195#169's atenci'#195#179'n acci'#195#179'n canci'#195#179'n e'+
   'staci'#195#179'n');
 Words('ola olas ano anos papa pap'#195#161' mama mam'#195#161' si'+
   ' s'#195#173' el '#195#169'l tu');
 Words('t'#195#186' mi m'#195#173' te t'#195#169' de d'#195#169' se s'#195#169);
End;

Procedure ItalianWords;
Begin
 Words('io tu lui lei noi voi loro mi ti ci vi si s'#195#169' me te gli le lo'+
   ' la li ne');
 Words('il i l un uno una un altro altra altri altre questo questa questi que'+
   'ste quello quella');
 Words('quelli quelle ci'#195#178' ogni qualche qualsiasi ciascuno ciascuna t'+
   'utto tutta tutti tutte');
 Words('nessuno nessuna qualcuno qualcuna qualcosa niente nulla molto molta m'+
   'olti molte poco');
 Words('poca pochi poche tanto tanta tanti tante troppo troppa troppi troppe '+
   'stesso stessa');
 Words('stessi stesse mio mia miei mie tuo tua tuoi tue suo sua suoi sue nost'+
   'ro nostra nostri');
 Words('nostre vostro vostra vostri vostre chi che cui quale quali quanto qua'+
   'nta quanti quante');
 Words('sono sei '#195#168' siamo siete era eri eravamo eravate erano fui fu '+
   'fummo furono stato stata');
 Words('stati state essere essendo sia siano sar'#195#160' saranno sarei sare'+
   'bbe sarebbero');
 Words('ho hai ha abbiamo avete hanno avevo aveva avevamo avevate avevano avu'+
   'to avere avendo');
 Words('abbia abbiano avr'#195#160' avranno avrei avrebbe ebbe ebbero sto sta'+
   'i sta stiamo state stanno');
 Words('stavo stava stavano stato stare stia stiano e ed o oppure ma p'+
   'er'#195#178' perch'#195#169);
 Words('poich'#195#169' quindi');
 Words('dunque anche ancora gi'#195#160' sempre mai non'+
   ' n'#195#169' s'#195#172' no forse certamente');
 Words('davvero proprio solo');
 Words('soltanto quasi abbastanza cos'#195#172' pi'#195#185' meno troppo bene'+
   ' male meglio peggio come');
 Words('dove quando');
 Words('mentre se senza purch'#195#169' bench'#195#169' affinch'#195#169' c'+
   'io'#195#168' oggi ieri');
 Words('domani adesso ora prima dopo poi');
 Words('presto tardi subito spesso talvolta qui qua l'#195#172' l'#195#160' d'+
   'entro fuori sopra sotto');
 Words('davanti');
 Words('dietro vicino lontano insieme attraverso durante contro verso fino tr'+
   'a fra con su per');
 Words('a ad da di in del dello della dei degli delle al allo alla ai agli al'+
   'le dal dallo');
 Words('dalla dai dagli dalle nel nello nella nei negli nelle sul sullo sulla'+
   ' sui sugli sulle');
 Words('col coi d all dell dall nell sull quest quell sant c m t s v po');
 Words('ciao buongiorno buonasera buonanotte arrivederci salve grazie prego f'+
   'avore scusa scusi');
 Words('benvenuto benvenuta auguri salute piacere buono buona buoni buone buo'+
   'n cattivo cattiva');
 Words('bello bella belli belle bel brutto brutta grande grandi piccolo picco'+
   'la piccoli piccole');
 Words('nuovo nuova nuovi nuove vecchio vecchia vecchi vecchie giovane giovan'+
   'i felice felici');
 Words('triste tristi facile facili difficile difficili importante importanti'+
   ' possibile impossibile');
 Words('necessario necessaria diverso diversa uguale uguali giusto giusta sba'+
   'gliato sbagliata');
 Words('vero vera falso falsa libero libera gratuito gratuita aperto aperta c'+
   'hiuso chiusa');
 Words('lungo lunga corto corta alto alta basso bassa caldo calda freddo fred'+
   'da veloce lento');
 Words('lenta chiaro chiara pulito pulita vuoto vuota pieno piena pronto pron'+
   'ta sicuro sicura');
 Words('mondo parola parole testo testi file documento documenti riga righe p'+
   'agina pagine');
 Words('lettera lettere frase frasi lingua lingue italiano italiana italiani '+
   'italiane francese');
 Words('inglese tedesco spagnolo grammatica ortografia errore errori correzio'+
   'ne correzioni');
 Words('correttore dizionario dizionari suggerimento suggerimenti programma p'+
   'rogrammi codice');
 Words('sorgente computer sistema sistemi informazione informazioni dati ingr'+
   'esso uscita risultato');
 Words('risultati rapporto rapporti prova prove versione versioni opzione opz'+
   'ioni comando comandi');
 Words('schermo tastiera mouse rete internet sito siti messaggio messaggi pos'+
   'ta elettronica');
 Words('domanda domande risposta risposte problema problemi soluzione soluzio'+
   'ni esempio esempi');
 Words('aiuto numero numeri nome nomi indirizzo indirizzi telefono telefoni g'+
   'iorno giorni notte');
 Words('notti mattina pomeriggio sera settimana settimane mese mesi anno anni'+
   ' ora ore minuto');
 Words('minuti secondo secondi tempo tempi luned'#195#172' marted'#195#172' m'+
   'ercoled'#195#172);
 Words('gioved'#195#172' venerd'#195#172' sabato domenica');
 Words('gennaio febbraio marzo aprile maggio giugno luglio agosto settembre o'+
   'ttobre novembre');
 Words('dicembre zero uno due tre quattro cinque sei sette otto nove dieci un'+
   'dici dodici cento');
 Words('mille milione milioni primo prima primi prime ultimo ultima ultimi ul'+
   'time prossimo');
 Words('prossima persona persone uomo uomini donna donne bambino bambini bamb'+
   'ina bambine ragazzo');
 Words('ragazzi ragazza ragazze amico amici amica amiche famiglia famiglie pa'+
   'dre madre genitori');
 Words('figlio figli figlia figlie fratello fratelli sorella sorelle nonno no'+
   'nna signore signora');
 Words('casa case stanza stanze camera camere porta porte finestra finestre t'+
   'avolo tavoli sedia');
 Words('sedie letto letti cucina bagno bagni giardino giardini scuola scuole '+
   'classe classi');
 Words('studente studenti studentessa insegnante professore professoressa uni'+
   'versit'#195#160' libro');
 Words('libri');
 Words('quaderno quaderni penna penne matita matite carta citt'#195#160' paes'+
   'e paesi strada strade via');
 Words('vie');
 Words('macchina macchine automobile automobili auto autobus treno treni aere'+
   'o aerei nave navi');
 Words('barca barche bicicletta biciclette viaggio viaggi stazione aeroporto '+
   'ufficio ospedale');
 Words('lavoro lavori denaro soldi prezzo prezzi negozio negozi mercato merca'+
   'ti azienda aziende');
 Words('acqua pane latte caff'#195#168' t'#195#168' frutta mela mele arancia '+
   'arance banana riso carne');
 Words('pesce uovo');
 Words('uova patata patate pomodoro pomodori formaggio zucchero sale olio cib'+
   'o colazione pranzo');
 Words('cena pasta pizza vino birra cane cani gatto gatti animale animali cav'+
   'allo cavalli uccello');
 Words('uccelli albero alberi fiore fiori bosco montagna montagne fiume fiumi'+
   ' mare spiaggia sole');
 Words('luna stella stelle cielo terra pioggia neve vento fuoco aria mano man'+
   'i piede piedi testa');
 Words('occhio occhi orecchio orecchie cuore vita morte amore pace musica can'+
   'zone canzoni film');
 Words('fotografia fotografie foto immagine immagini gioco giochi sport squad'+
   'ra festa compleanno');
 Words('Natale Italia Roma Milano Venezia Napoli Europa estate inverno primav'+
   'era autunno rosso');
 Words('rossa verde verdi blu azzurro azzurra giallo gialla bianco bianca ner'+
   'o nera grigio grigia');
 Words('rosa marrone colore colori punto punti parte parti luogo luoghi cosa '+
   'cose ragione ragioni');
 Words('verit'#195#160' storia storie idea idee luce forza faccia forma forme'+
   ' qualit'#195#160);
 Words('quantit'#195#160' capacit'#195#160);
 Words('fare faccio fai fa facciamo fate fanno fatto facendo feci fece f'+
   'ar'#195#178' far'#195#160);
 Words('farebbe');
 Words('andare vado vai va andiamo andate vanno andato andata andando venire '+
   'vengo vieni viene');
 Words('veniamo venite vengono venuto venuta dire dico dici dice diciamo dite'+
   ' dicono detto');
 Words('parlare parlo parli parla parliamo parlate parlano parlato parlando l'+
   'eggere leggo leggi');
 Words('legge leggiamo leggete leggono letto leggendo scrivere scrivo scrivi '+
   'scrive scriviamo');
 Words('scrivete scrivono scritto scrivendo vedere vedo vedi vede vediamo ved'+
   'ete vedono visto');
 Words('guardare guardo guarda guardiamo guardano guardato ascoltare ascolto '+
   'ascolta ascoltano');
 Words('ascoltato sapere so sai sa sappiamo sapete sanno sapevo saputo conosc'+
   'ere conosco conosci');
 Words('conosce conosciamo conoscete conoscono conosciuto pensare penso pensi'+
   ' pensa pensiamo');
 Words('pensano pensato credere credo crede crediamo credono creduto capire c'+
   'apisco capisci');
 Words('capisce capiamo capite capiscono capito comprendere comprendo compren'+
   'de compreso');
 Words('imparare imparo impara impariamo imparano imparato insegnare insegno '+
   'insegna insegnato');
 Words('volere voglio vuoi vuole vogliamo volete vogliono voluto vorrei vorre'+
   'bbe potere posso');
 Words('puoi pu'#195#178' possiamo potete possono potuto potrei potrebbe dove'+
   're devo devi deve');
 Words('dobbiamo');
 Words('dovete devono dovuto dovrei dovrebbe piacere piace piacciono piaciuto'+
   ' amare amo ama');
 Words('amiamo amano amato mangiare mangio mangi mangia mangiamo mangiate man'+
   'giano mangiato');
 Words('bere bevo bevi beve beviamo bevete bevono bevuto vivere vivo vivi viv'+
   'e viviamo vivete');
 Words('vivono vissuto dormire dormo dormi dorme dormiamo dormite dormono dor'+
   'mito lavorare lavoro');
 Words('lavori lavora lavoriamo lavorate lavorano lavorato studiare studio st'+
   'udi studia studiamo');
 Words('studiate studiano studiato giocare gioco gioca giochiamo giocano gioc'+
   'ato correre corro');
 Words('corre corrono corso camminare cammino cammina camminano camminato com'+
   'prare compro compra');
 Words('comprano comprato vendere vendo vende vendono venduto pagare pago pag'+
   'a pagano pagato');
 Words('dare do dai d'#195#160' diamo date danno dato prendere prendo prendi '+
   'prende prendiamo prendono');
 Words('preso portare porto porta portano portato mettere metto metti mette m'+
   'ettiamo mettono');
 Words('messo uscire esco esci esce usciamo uscite escono uscito arrivare arr'+
   'ivo arriva arrivano');
 Words('arrivato passare passo passa passano passato restare resto resta rest'+
   'ano restato');
 Words('lasciare lascio lascia lasciamo lasciano lasciato cercare cerco cerca'+
   ' cercano cercato');
 Words('trovare trovo trovi trova troviamo trovano trovato aspettare aspetto '+
   'aspetta aspettano');
 Words('aspettato aiutare aiuto aiuta aiutiamo aiutano aiutato aprire apro ap'+
   'ri apre apriamo');
 Words('aprono aperto chiudere chiudo chiudi chiude chiudiamo chiudono chiuso'+
   ' iniziare inizio');
 Words('inizia iniziano iniziato finire finisco finisci finisce finiamo finis'+
   'cono finito');
 Words('cambiare cambio cambia cambiamo cambiano cambiato usare uso usa usiam'+
   'o usano usato');
 Words('correggere correggo corregge correggono corretto corretta controllare'+
   ' controllo controlla');
 Words('controllato salvare salvo salva salvano salvato inviare invio invia i'+
   'nviano inviato');
 Words('ricevere ricevo riceve ricevono ricevuto tornare torno torna tornano '+
   'tornato ricordare');
 Words('ricordo ricorda ricordano ricordato dimenticare dimentico dimentica d'+
   'imenticato chiedere');
 Words('chiedo chiedi chiede chiediamo chiedono chiesto rispondere rispondo r'+
   'isponde risposto');
 Words('scegliere scelgo sceglie scelgono scelto tenere tengo tiene tengono t'+
   'enuto perdere perso');
 Words('soprattutto purtroppo infatti invece inoltre comunque dunque allora v'+
   'eramente facilmente');
 Words('rapidamente lentamente correttamente finalmente completamente probabi'+
   'lmente sicuramente');
 Words('attenzione azione stazione lezione lezioni emozione emozioni informat'+
   'ica tecnologia');
 Words('perch'#195#169' affinch'#195#169' poich'#195#169' ben'+
   'ch'#195#169' '#195#168' s'#195#172);
 Words('n'#195#169' s'#195#169' t'#195#168' d'#195#160' gi'#195#160' '+
   'gi'#195#185' pi'#195#185);
 Words('l'#195#172' l'#195#160' per'#195#178' cio'#195#168' caff'#195#168);
End;

Procedure InitDictionary;
Var A,B: Integer; W: TWord;
Begin
 WordCount := 0;
 If DictName='fr_FR' Then FrenchWords
 Else If DictName='de_DE' Then GermanWords
 Else If DictName='es_ES' Then SpanishWords
 Else If DictName='it_IT' Then ItalianWords Else EnglishWords;
  { Sort once; binary lookup preserves accented dictionary spellings. }
 For A := 2 To WordCount Do Begin
  W := Dictionary[A]^; B := A-1;
  While B > 0 Do Begin
   If Lower(Dictionary[B]^) <= Lower(W) Then Break;
   Dictionary[B+1]^ := Dictionary[B]^; Dec(B)
  End;
  Dictionary[B+1]^ := W
 End
End;

Function Known(W: TWord): Boolean;
Var
 L,H,M,P: Integer;
 K: TWord;
 AllUpper: Boolean;
Begin
 AllUpper := True;
 For P := 1 To Length(W) Do Begin
  If W[P] In ['a'..'z'] Then AllUpper := False;
  If (Ord(W[P])=195) And (P<Length(W)) Then
   If Ord(W[P+1]) In [159..182,184..190] Then AllUpper := False
 End;
 W := Lower(W); L := 1; H := WordCount; Known := False;
 While L<=H Do Begin
  M := (L+H) Div 2; K := Lower(Dictionary[M]^);
  If W=K Then Begin
   Known := True; Exit
  End;
  If W<K Then H := M-1 Else L := M+1
 End;
 { In German uppercase text, SS is also a valid rendering of sharp s. }
 If (DictName='de_DE') And AllUpper Then
  For M := 1 To WordCount Do Begin
   K := Lower(Dictionary[M]^); P := Pos(#195#159,K);
   While P>0 Do Begin Delete(K,P,2); Insert('ss',K,P); P := Pos(#195#159,K) End;
   If W=K Then Begin Known := True; Exit End
  End
End;

Function RankingKey(W: TWord): TWord;
Var P: Integer;
Begin
 W := Lower(W);
 If DictName='de_DE' Then Begin
  P := Pos(#195#159,W);
  While P>0 Do Begin Delete(W,P,2); Insert('ss',W,P); P := Pos(#195#159,W) End
 End;
 If DictName='es_ES' Then Begin
  { Keep the Spanish letter enye distinct from n in suggestion ranking. }
  P := Pos(#195#177,W);
  While P>0 Do Begin Delete(W,P,2); Insert('~',W,P); P := Pos(#195#177,W) End
 End;
 RankingKey := Fold(W)
End;

Function Distance(A,B: TWord): Integer;
Var
 Matrix: Array[0..80,0..80] Of Byte;
 X,Y,V: Integer;
Begin
 For X := 0 To Length(A) Do Matrix[X,0] := X;
 For Y := 0 To Length(B) Do Matrix[0,Y] := Y;
 For X := 1 To Length(A) Do
 For Y := 1 To Length(B) Do Begin
  V := Matrix[X-1,Y-1]; If A[X]<>B[Y] Then Inc(V);
  If Matrix[X-1,Y]+1<V Then V := Matrix[X-1,Y]+1;
  If Matrix[X,Y-1]+1<V Then V := Matrix[X,Y-1]+1;
  If (X>1) And (Y>1) Then    If (A[X]=B[Y-1]) And (A[X-1]=B[Y]) Then     If
    Matrix[X-2,Y-
  2]+1<V Then V := Matrix[X-2,Y-2]+1;
  Matrix[X,Y] := V
 End;
 Distance := Matrix[Length(A),Length(B)]
End;

Function MatchCase(S,Original: TWord): TWord;
Var
 P,B: Integer;
 AllUpper, FirstUpper: Boolean;
Begin
 AllUpper := True; FirstUpper := False; P := 1;
 While P<=Length(Original) Do Begin
  B := Ord(Original[P]);
  If B In [97..122] Then AllUpper := False;
  If (P=1) And (B In [65..90]) Then FirstUpper := True;
  If (B=195) And (P<Length(Original)) Then Begin
   Inc(P); B := Ord(Original[P]);
   If B In [159..182,184..190] Then AllUpper := False;
   If (P=2) And (B In [128..150,152..158]) Then FirstUpper := True
  End;
  Inc(P)
 End;
 P := 1;
 While P<=Length(S) Do Begin
  B := Ord(S[P]);
  If AllUpper Or (FirstUpper And (P=1)) Then Begin
   If B In [97..122] Then S[P] := Chr(B-32);
   If (B=195) And (P<Length(S)) Then Begin
    Inc(P); B := Ord(S[P]);
    If B=159 Then Begin
     Delete(S,P-1,2); Insert('SS',S,P-1)
    End;
    If B In [160..182,184..190] Then S[P] := Chr(B-32)
   End
  End;
  Inc(P)
 End;
 MatchCase := S
End;

Procedure InsertSuggestion(W: TWord; Score: Integer);
Var
 P,N,Limit: Integer;
Begin
 For N := 1 To SuggestionCount Do If Suggestions[N]=W Then Exit;
 P := 1;
 While P<=SuggestionCount Do Begin
  If Score<Scores[P] Then Break;
  Inc(P)
 End;
 If P>MaxSuggestions Then Exit;
 Limit := SuggestionCount;
 If Limit<MaxSuggestions Then Inc(SuggestionCount) Else Dec(Limit);
 For N := Limit Downto P Do Begin
  Suggestions[N+1] := Suggestions[N]; Scores[N+1] := Scores[N]
 End;
 Suggestions[P] := W; Scores[P] := Score
End;

Function ElidesInFrench(Const Prefix, Rest: TWord): Boolean;
Begin
 ElidesInFrench:=False;
 If Rest='' Then Exit;
 If Not (Rest[1] in ['a','e','i','o','u','y','h',#195,#197]) Then Exit;
 ElidesInFrench:=(Prefix='d') Or (Prefix='l') Or (Prefix='j') Or
  (Prefix='m') Or (Prefix='n') Or (Prefix='s') Or (Prefix='t') Or
  (Prefix='c') Or (Prefix='qu') Or (Prefix='jusqu') Or
  (Prefix='lorsqu') Or (Prefix='puisqu');
End;

Procedure SuggestWordBoundaries(Const W: TWord);
Var Cut: Integer; LeftWord, RightWord: TWord;
Begin
 { Keep every letter when the missing separator explains the error. }
 For Cut:=1 To Length(W)-1 Do Begin
  LeftWord:=Copy(W,1,Cut);
  RightWord:=Copy(W,Cut+1,Length(W)-Cut);
  If Known(RightWord) Then Begin
   If (DictName='fr_FR') And ElidesInFrench(LeftWord,RightWord) Then Begin
    InsertSuggestion(LeftWord+#39+RightWord,1);
    { Also offer a plural in -s when the lexicon confirms it. }
    If Known(RightWord+'s') Then
     InsertSuggestion(LeftWord+#39+RightWord+'s',35);
   End;
   If (Cut>=2) And (Length(RightWord)>=2) And Known(LeftWord) Then
    InsertSuggestion(LeftWord+' '+RightWord,2);
  End;
 End;
End;

Procedure Suggest(W: TWord);
Var
 N,D,Limit: Integer;
 K,F,Preferred: TWord;
Begin
 SuggestionCount := 0; W := Lower(W); F := RankingKey(W);
 Preferred := '';
 If DictName='fr_FR' Then Begin
 If W='bonjours' Then Preferred := 'bonjour';
 If W='beaucoups' Then Preferred := 'beaucoup';
 If W='malgres' Then Preferred := 'malgr'#195#169;
 If W='parmis' Then Preferred := 'parmi';
 If W='biensur' Then Preferred := 'bien s'#195#187'r';
 End Else If DictName='de_DE' Then Begin
  If W='hlo' Then Preferred := 'Hallo';
  If W='wlet' Then Preferred := 'Welt';
  If W='dsa' Then Preferred := 'das';
  If W='udn' Then Preferred := 'und';
  If W='nciht' Then Preferred := 'nicht';
  If W='deutch' Then Preferred := 'deutsch';
  If W='deutsh' Then Preferred := 'deutsch';
  If W='strasse' Then Preferred := 'Stra'#195#159'e';
  If W='grusse' Then Preferred := 'Gr'#195#188#195#159'e';
  If W='gruesse' Then Preferred := 'Gr'#195#188#195#159'e';
  If W='fuer' Then Preferred := 'f'#195#188'r';
  If W='ueber' Then Preferred := #195#188'ber';
  If W='schoen' Then Preferred := 'sch'#195#182'n';
  If W='haeuser' Then Preferred := 'H'#195#164'user';
  If W='koennen' Then Preferred := 'k'#195#182'nnen';
  If W='moechte' Then Preferred := 'm'#195#182'chte';
  If W='schones' Then Preferred := 'sch'#195#182'nes';
  If W='bischen' Then Preferred := 'bisschen';
  If W='nemlich' Then Preferred := 'n'#195#164'mlich'
 End Else If DictName='es_ES' Then Begin
  If W='holaa' Then Preferred := 'hola';
  If W='mndo' Then Preferred := 'mundo';
  If W='gracais' Then Preferred := 'gracias';
  If W='espanol' Then Preferred := 'espa'#195#177'ol';
  If W='nino' Then Preferred := 'ni'#195#177'o';
  If W='ninos' Then Preferred := 'ni'#195#177'os';
  If W='ninia' Then Preferred := 'ni'#195#177'a';
  If W='maniana' Then Preferred := 'ma'#195#177'ana';
  If W='correcion' Then Preferred := 'correcci'#195#179'n';
  If W='diccionarioo' Then Preferred := 'diccionario';
  If W='haver' Then Preferred := 'haber';
  If W='tamvien' Then Preferred := 'tambi'#195#169'n';
  If W='pinguino' Then Preferred := 'ping'#195#188'ino';
  If W='verguenza' Then Preferred := 'verg'#195#188'enza'
 End Else If DictName='it_IT' Then Begin
  If W='ciaoo' Then Preferred := 'ciao';
  If W='mndo' Then Preferred := 'mondo';
  If W='grazzie' Then Preferred := 'grazie';
  If W='italaino' Then Preferred := 'italiano';
  If W='perche' Then Preferred := 'perch'#195#169;
  If W='caffe' Then Preferred := 'caff'#195#168;
  If W='piu' Then Preferred := 'pi'#195#185;
  If W='lunedi' Then Preferred := 'luned'#195#172;
  If W='citta' Then Preferred := 'citt'#195#160;
  If W='universita' Then Preferred := 'universit'#195#160;
  If W='sopratutto' Then Preferred := 'soprattutto';
  If W='pultroppo' Then Preferred := 'purtroppo';
  If W='qualita' Then Preferred := 'qualit'#195#160;
  If W='correzzione' Then Preferred := 'correzione'
 End Else Begin
  If W='teh' Then Preferred := 'the';
  If W='helo' Then Preferred := 'hello';
  If W='wrld' Then Preferred := 'world';
  If W='recieve' Then Preferred := 'receive';
  If W='becuase' Then Preferred := 'because';
  If W='seperate' Then Preferred := 'separate';
  If W='definately' Then Preferred := 'definitely';
  If W='adress' Then Preferred := 'address';
  If W='tomorow' Then Preferred := 'tomorrow';
  If W='langauge' Then Preferred := 'language';
  If W='beutiful' Then Preferred := 'beautiful'
 End;
 If Preferred<>'' Then InsertSuggestion(Preferred,0);
 If Length(W)<80 Then SuggestWordBoundaries(W);
 Limit := 2; If Length(F)<5 Then Limit := 1;
 For N := 1 To WordCount Do Begin
  K := RankingKey(Dictionary[N]^);
  If Abs(Length(F)-Length(K))<=Limit Then Begin
   D := Distance(F,K);
   If D<=Limit Then Begin
    { Exact accent/case-insensitive matches rank before edit corrections. }
    If D=0 Then InsertSuggestion(Dictionary[N]^,1)
           Else InsertSuggestion(Dictionary[N]^,D*10+2)
   End
  End
 End
End;


Function SpellLetter(C: Char): Boolean;
Var U: Word;
Begin
 U:=Cp437ToUni(Ord(C));
 SpellLetter:=(C in ['A'..'Z','a'..'z']) Or
  ((U>=$C0) And (U<=$FF) And (U<>$D7) And (U<>$F7));
End;

Function SpellEncode(Const S: String): String;
Var I: Integer; U: Word; R: String;
Begin
 R:='';
 For I:=1 To Length(S) Do Begin
  U:=Cp437ToUni(Ord(S[I]));
  If U<128 Then R:=R+Chr(U)
  Else R:=R+Chr($C0 or (U shr 6))+Chr($80 or (U and 63));
 End;
 SpellEncode:=R;
End;

Function SpellDecode(Const S: TWord): String;
Var I,B: Integer; U: Word; R: String;
Begin
 SpellDecode:=''; R:=''; I:=1;
 While I<=Length(S) Do Begin
  U:=Ord(S[I]); Inc(I);
  If U>127 Then Begin
   If (U<$C2) Or (U>$DF) Or (I>Length(S)) Then Exit;
   U:=((U and 31) shl 6) or (Ord(S[I]) and 63); Inc(I);
  End;
  B:=32;
  While (B<=254) And (Cp437ToUni(B)<>U) Do Inc(B);
  If B>254 Then Exit;
  R:=R+Chr(B);
 End;
 SpellDecode:=R;
End;

Type TSpellPicks=Array[1..MaxSuggestions] of String[80];

Procedure RenderAll; Forward;

Function ChooseSpelling(P, First, Last: Integer; Const Original: String;
                        Const Picks: TSpellPicks; Count: Integer): Integer;
Var
 SavedCursor: TCursorPos;
 L, A, B, Y, TopY, I, Selected, ResultCode, RowY, WaveX, WaveEnd,
   WaveY: Integer;
 Key: Word;
 PreviousButtons: LongInt;
 Repaint: Boolean;

 Procedure Paint;
 Var Row, TextY: Integer;
 Begin
  EraseSoftCursor;
  FillRectArea(110,TopY,530,TopY+186,CLR_3D_FACE);
  DrawButton3D(110,TopY,530,TopY+186,False);
  OsTitleBar(113,TopY+3,527,TopY+21,Tr('Orthographe - ')+DictName,TopY+7);
  DrawTextAt(122,TopY+29,Tr('Mot : ')+Copy(Original,1,43),Black);
  If Count=0 Then DrawTextAt(122,TopY+55,Tr('Aucune suggestion'),Black);
  For Row:=1 To Count Do Begin
   TextY:=TopY+45+(Row-1)*17;
   SetColor(Black);
   Circle(131,TextY+5,5);
   If Row=Selected Then FillRectArea(129,TextY+3,133,TextY+7,Black);
   DrawTextAt(145,TextY+1,Copy(Picks[Row],1,45),Black);
  End;
  DrawButton3D(191,TopY+151,301,TopY+176,False);
  DrawTextAt(202,TopY+160,Tr('Remplacer'),Black);
  DrawButton3D(310,TopY+151,410,TopY+176,False);
  DrawTextAt(326,TopY+160,Tr('Ignorer'),Black);
  DrawButton3D(419,TopY+151,519,TopY+176,False);
  DrawTextAt(435,TopY+160,Tr('Fermer'),Black);
 End;

Begin
 SavedCursor:=Cursor;
 Cursor.ParaIdx:=P; Cursor.CharIdx:=First; Cursor.RunIdx:=1;
 LayoutDocument;
 EnsureCursorVisible;
 L:=FindCursorVLine;
 TopY:=267;
 If L>0 Then
  If ZoomY(VLines[L].Y-ScrollY)>245 Then TopY:=99;
 RenderAll;
 EraseSoftCursor;
 For L:=1 To VLineCount Do
  If VLines[L].ParaIdx=P Then Begin
   A:=VLines[L].CharStart-1; B:=A+VLines[L].CharLen;
   If A<First Then A:=First;
   If B>Last Then B:=Last;
   Y:=VLines[L].Y-ScrollY+VLines[L].Height-2;
   If (A<B) And (ZoomY(Y)>=DOCAREA_TOP) And (ZoomY(Y)<=DocPhysicalBottom) Then
     Begin
    SetColor(Red);
    WaveX:=ZoomX(LineCharScreenX(L,A));
    WaveEnd:=ZoomX(LineCharScreenX(L,B))-1;
    If WaveX<0 Then WaveX:=0;
    If WaveEnd>=SCREEN_W Then WaveEnd:=SCREEN_W-1;
    WaveY:=ZoomY(Y);
    For I:=WaveX To WaveEnd Do
     If WaveY-((I-WaveX) mod 4 div 2)>=DOCAREA_TOP Then
      PutPixel(I,WaveY-((I-WaveX) mod 4 div 2),Red);
   End;
  End;
 Cursor:=SavedCursor;
 Selected:=Ord(Count>0);
 ResultCode:=-2;
 PreviousButtons:=MsBtn;
 Paint;
 Repeat
  Repaint:=False;
  If KeyPressed Then Begin
   Key:=ReadKeyEx; Repaint:=True;
   Case Key Of
    KEY_ESC: ResultCode:=-1;
    KEY_ENTER: If Selected>0 Then ResultCode:=Selected;
    73,105: ResultCode:=0;
    KEY_UP: If Selected>1 Then Dec(Selected);
    KEY_DOWN: If Selected<Count Then Inc(Selected);
    49..53: If Key-48<=Count Then Selected:=Key-48;
   End;
  End;
  EraseSoftCursor;
  GetMouseStateLI(MsX,MsY,MsBtn);
  If (ResultCode=-2) And ((MsBtn and MB_LEFT)<>0) And
     ((PreviousButtons and MB_LEFT)=0) Then Begin
   RowY:=MsY-TopY;
   If (MsX>=122) And (MsX<=513) And (RowY>=45) And (RowY<45+Count*17) Then Begin
    I:=1+(RowY-45) div 17;
    Selected:=I; Repaint:=True;
   End;
   If (RowY>=151) And (RowY<=176) Then Begin
    If (MsX>=191) And (MsX<=301) And (Selected>0) Then ResultCode:=Selected;
    If (MsX>=310) And (MsX<=410) Then ResultCode:=0;
    If (MsX>=419) And (MsX<=519) Then ResultCode:=-1;
   End;
  End;
  PreviousButtons:=MsBtn;
  If ResultCode=-2 Then Begin
   If Repaint Then Paint;
    DrawSoftCursor(MsX,MsY); 
   Delay(10);
  End;
 Until ResultCode<>-2;
 EraseSoftCursor;
 ChooseSpelling:=ResultCode;
End;

Procedure DoSpellDialog;
Var
 P, Start, Stop, I, J, K, R1, R2, O1, O2, Count, Choice, Replaced: Integer;
 S, Original, Candidate, Answer: String;
 LanguageCode: String;
 Encoded: TWord;
 Picks: TSpellPicks;
 Cancelled: Boolean;
Begin
 LanguageCode:=GetEnv('LANGUAGE');
 For I:=1 To Length(LanguageCode) Do LanguageCode[I]:=UpCase(LanguageCode[I]);
 DictName:='fr_FR';
 If LanguageCode='EN' Then DictName:='en_US'
 Else If (LanguageCode='GR') Or (LanguageCode='DE') Then DictName:='de_DE'
 Else If LanguageCode='IT' Then DictName:='it_IT'
 Else If (LanguageCode='ES') Or (LanguageCode='SP') Then DictName:='es_ES';
 Case SpellLanguage Of
  1: DictName:='fr_FR';
  2: DictName:='en_US';
  3: DictName:='de_DE';
  4: DictName:='it_IT';
  5: DictName:='es_ES';
 End;
 InitDictionary;
 Replaced:=0; Cancelled:=False;
 For P:=1 To Doc^.ParaCount Do Begin
  If Doc^.Paragraphs[P].IsImage Or ParaIsTable(P) Then Continue;
  S:=ParaText(P); Stop:=1;
  While Stop<=Length(S) Do Begin
   If Not SpellLetter(S[Stop]) Then Begin Inc(Stop); Continue; End;
   Start:=Stop;
   While Stop<=Length(S) Do Begin
    If SpellLetter(S[Stop]) Then Inc(Stop)
    Else If (S[Stop]=#39) And (Stop<Length(S)) Then Begin
     If Not SpellLetter(S[Stop+1]) Then Break;
     Inc(Stop);
    End Else Break;
   End;
   Original:=Copy(S,Start,Stop-Start);
   Candidate:=SpellEncode(Original);
   If Length(Candidate)>80 Then Continue;
   Encoded:=Candidate;
   If Known(Encoded) Then Continue;
   I:=Pos(#39,Encoded);
   If (I>0) And (DictName='fr_FR') Then Begin
    Candidate:=Copy(Encoded,I+1,80);
    If ElidesInFrench(Lower(Copy(Encoded,1,I-1)),Lower(Candidate)) And
       Known(Candidate) Then Continue;
   End;
   Suggest(Encoded);
   Count:=0;
   For I:=1 To SuggestionCount Do Begin
    Candidate:=SpellDecode(MatchCase(Suggestions[I],Encoded));
    If Candidate='' Then Continue;
    Inc(Count); Picks[Count]:=Candidate;
   End;
   LocateChar(P,Start-1,R1,O1);
   LocateChar(P,Stop-2,R2,O2);
   Choice:=ChooseSpelling(P,Start-1,Stop-1,Original,Picks,Count);
   If Choice<0 Then Begin Cancelled:=True; Break; End;
   If Choice=0 Then Continue;
   Answer:=Picks[Choice];
   If Answer=Original Then Continue;
   If Length(S)-Length(Original)+Length(Answer)>MAX_TEXT_LEN Then Begin
    ShowMessage(Tr('Correction trop longue pour ce paragraphe.'));
    Continue;
   End;
   If Replaced=0 Then Begin PushUndoSnapshot; ResetMutation; SelClear; End;
   { Keep the first run style and preserve the text outside the word. }
   Delete(Doc^.Paragraphs[P].Runs[R1].Text,O1+1,Length(Original));
   If R2>R1 Then Begin
    Delete(Doc^.Paragraphs[P].Runs[R2].Text,1,O2+1);
    For J:=R1+1 To R2-1 Do Doc^.Paragraphs[P].Runs[J].Text:='';
   End;
   Insert(Answer,Doc^.Paragraphs[P].Runs[R1].Text,O1+1);
   MergeAdjacentSameStyleRuns(P);
   Inc(Replaced);
   Cursor.ParaIdx:=P; Cursor.CharIdx:=Start-1+Length(Answer);
   Cursor.RunIdx:=1;
   Stop:=Start+Length(Answer);
   S:=ParaText(P);
  End;
  If Cancelled Then Break;
 End;
 For K:=1 To WordCount Do Dispose(Dictionary[K]);
 WordCount:=0;
 If Replaced>0 Then Begin Doc^.Modified:=True; NeedsRelayout:=True; End;
 NeedsRedraw:=True;
 If Not Cancelled Then Begin
  Str(Replaced,Answer);
  ShowMessage(Tr('Orthographe : ')+Answer+Tr(' correction(s).'));
 End;
End;

Procedure ShowOptionsDialog;
Const
 Languages: Array[0..5] of String[12] =
  ('Automatique','Francais','Anglais','Allemand','Italien','Espagnol');
Var
 LayoutMode, ShowRuler, Done, Apply: Boolean;
 Language, Focus, I: Integer;
 Key: Word;
 PreviousButtons: LongInt;

 Procedure Paint;
 Var J,X,Y: Integer;
 Begin
  EraseSoftCursor;
  FillRectArea(100,105,540,375,CLR_3D_FACE);
  DrawButton3D(100,105,540,375,False);
  OsTitleBar(103,108,537,127,Tr('Options'),114);
  DrawTextAt(117,141,Tr('Affichage'),Black);
  DrawButton3D(117,158,296,183,LayoutMode);
  DrawTextAt(127,167,Tr('Mode Page'),Black);
  DrawButton3D(307,158,523,183,ShowRuler);
  DrawTextAt(317,167,Tr('Afficher la regle'),Black);
  DrawTextAt(117,200,Tr('Langue du correcteur'),Black);
  For J:=0 To 5 Do Begin
   X:=117+(J mod 3)*137;
   Y:=219+(J div 3)*30;
   DrawButton3D(X,Y,X+130,Y+24,Language=J);
   DrawTextAt(X+8,Y+8,Tr(Languages[J]),Black);
  End;
  DrawTextAt(117,289,Tr('Automatique suit LANGUAGE (francais par defaut).'),
    Black);
  DrawTextAt(117,308,Tr('Tab : option   Espace : choisir'),DarkGray);
  SetColor(Blue);
  Case Focus Of
   0: Rectangle(115,156,298,185);
   1: Rectangle(305,156,525,185);
  Else
   X:=117+((Focus-2) mod 3)*137;
   Y:=219+((Focus-2) div 3)*30;
   Rectangle(X-2,Y-2,X+132,Y+26);
  End;
  DrawButton3D(323,335,419,362,False);
  DrawTextAt(334,344,Tr('Appliquer'),Black);
  DrawButton3D(427,335,523,362,False);
  DrawTextAt(441,344,Tr('Annuler'),Black);
 End;

 Procedure Choose;
 Begin
  Case Focus Of
   0: LayoutMode:=Not LayoutMode;
   1: ShowRuler:=Not ShowRuler;
  Else Language:=Focus-2;
  End;
 End;

Begin
 LayoutMode:=PageLayoutView;
 ShowRuler:=RulerVisible;
 Language:=SpellLanguage;
 Focus:=0; Done:=False; Apply:=False;
 PreviousButtons:=MsBtn;
 Paint;
 Repeat
  If KeyPressed Then Begin
   Key:=ReadKeyEx;
   Case Key Of
    KEY_ESC: Done:=True;
    KEY_ENTER: Begin Apply:=True; Done:=True; End;
    KEY_TAB,KEY_RIGHT: Focus:=(Focus+1) mod 8;
    KEY_LEFT: Focus:=(Focus+7) mod 8;
    32: Choose;
   End;
   If Not Done Then Paint;
  End;
  EraseSoftCursor;
  GetMouseStateLI(MsX,MsY,MsBtn);
  If Not Done And ((MsBtn and MB_LEFT)<>0) And
     ((PreviousButtons and MB_LEFT)=0) Then Begin
   If (MsY>=158) And (MsY<=183) Then Begin
    If (MsX>=117) And (MsX<=296) Then Begin Focus:=0; Choose; End;
    If (MsX>=307) And (MsX<=523) Then Begin Focus:=1; Choose; End;
   End;
   For I:=0 To 5 Do
    If (MsX>=117+(I mod 3)*137) And (MsX<=247+(I mod 3)*137) And
       (MsY>=219+(I div 3)*30) And (MsY<=243+(I div 3)*30) Then Begin
     Focus:=I+2; Choose;
    End;
   If (MsY>=335) And (MsY<=362) Then Begin
    If (MsX>=323) And (MsX<=419) Then Begin Apply:=True; Done:=True; End;
    If (MsX>=427) And (MsX<=523) Then Done:=True;
   End;
   If Not Done Then Paint;
  End;
  PreviousButtons:=MsBtn;
  If Not Done Then Begin
    DrawSoftCursor(MsX,MsY); 
   Delay(10);
  End;
 Until Done;
 EraseSoftCursor;
 If Apply Then Begin
  ChangeDocumentView(LayoutMode);
  If ShowRuler<>RulerVisible Then ToggleDocumentRuler;
  SpellLanguage:=Language;
 End;
 NeedsRedraw:=True;
End;


Procedure ShowHelpContents;
Const
 Topics: Array[1..7] of String[16] =
  ('Documents','Edition','Affichage','Insertion','Mise en forme','Orthograp'+
    'he','Statistiques');
 HelpText: Array[1..7,1..5] of String[43] = (
  ('Ctrl+O ouvre un document.',
   'Ctrl+S enregistre le document courant.',
   'Fichier > Enregistrer sous permet de',
   'choisir un autre nom ou format.',
   'Alt+X quitte WorDium.'),
  ('Ctrl+X coupe et Ctrl+C copie.',
   'Ctrl+V colle le texte.',
   'Ctrl+Z annule la derniere modification.',
   'Ctrl+Y retablit une modification.',
   'F3 recherche la prochaine occurrence.'),
  ('Le menu Affichage permet de changer',
   'de vue, de zoom ou de masquer la regle.',
   'Utilisez le mode Page pour visualiser',
   'la disposition sur la feuille.',
   ''),
  ('Insertion > Symbole ouvre la grille.',
   'Choisissez un caractere puis Inserer.',
   'Le menu permet aussi d''inserer une',
   'image ou un tableau.',
   'Ctrl+Entree insere un saut de page.'),
  ('Format > Police regle taille et couleur.',
   'Ctrl+B active ou desactive le gras.',
   'Ctrl+I gere l''italique et Ctrl+U souligne.',
   'Format > Paragraphe regle alignement,',
   'retrait, bordure et saut de page.'),
  ('F7 lance le correcteur orthographique.',
   'Choisissez une suggestion puis Remplacer.',
   'Ignorer passe au mot suivant.',
   'Outils > Options permet de choisir',
   'la langue du correcteur.'),
  ('Outils > Statistiques affiche les',
   'decomptes du document.',
   'Le tableau indique les pages, mots,',
   'caracteres, paragraphes, lignes,',
   'tableaux, cellules et images.'));
Var
 Topic, Row, Y: Integer;
 Key: Word;
 PreviousButtons: LongInt;
 Done, Repaint: Boolean;

 Procedure Paint;
 Var I, TopY, Ink: Integer;
 Begin
  EraseSoftCursor;
  FillRectArea(47,102,593,373,CLR_3D_FACE);
  DrawButton3D(47,102,593,373,False);
  OsTitleBar(50,105,590,124,Tr('Sommaire de l''aide WorDium'),110);
  FillRectArea(60,138,216,310,White);
  DrawSunkenRect(59,137,217,311);
  For I:=1 To 7 Do Begin
   TopY:=140+(I-1)*24;
   Ink:=Black;
   If I=Topic Then Begin
    FillRectArea(61,TopY,215,TopY+23,Blue);
    Ink:=White;
   End;
   DrawTextAt(68,TopY+8,Tr(Topics[I]),Ink);
  End;
  FillRectArea(227,138,580,310,White);
  DrawSunkenRect(226,137,581,311);
  DrawTextAt(237,151,Tr(Topics[Topic]),Blue);
  For I:=1 To 5 Do DrawTextAt(237,174+(I-1)*19,Tr(HelpText[Topic,I]),Black);
  DrawTextAt(61,340,Tr('Fleches : choisir une rubrique'),DarkGray);
  DrawButton3D(482,330,580,358,False);
  DrawTextAt(507,340,Tr('Fermer'),Black);
 End;

Begin
 Topic:=1; Done:=False; PreviousButtons:=MsBtn;
 Paint;
 Repeat
  Repaint:=False;
  If KeyPressed Then Begin
   Key:=ReadKeyEx;
   Repaint:=True;
   Case Key Of
    KEY_ESC,KEY_ENTER: Done:=True;
    KEY_UP: If Topic>1 Then Dec(Topic);
    KEY_DOWN,KEY_TAB: If Topic<7 Then Inc(Topic) Else Topic:=1;
    KEY_HOME: Topic:=1;
    KEY_END: Topic:=7;
   End;
  End;
  EraseSoftCursor;
  GetMouseStateLI(MsX,MsY,MsBtn);
  If ((MsBtn and MB_LEFT)<>0) And ((PreviousButtons and MB_LEFT)=0) Then Begin
   Y:=MsY;
   If (MsX>=61) And (MsX<=215) And (Y>=140) And (Y<308) Then Begin
    Row:=1+(Y-140) div 24;
    Repaint:=Topic<>Row;
    Topic:=Row;
   End;
   If (MsX>=482) And (MsX<=580) And (Y>=330) And (Y<=358) Then Done:=True;
  End;
  PreviousButtons:=MsBtn;
  If Not Done Then Begin
   If Repaint Then Paint;
    DrawSoftCursor(MsX,MsY); 
   Delay(10);
  End;
 Until Done;
 EraseSoftCursor;
 NeedsRedraw:=True;
End;


Procedure ShowAboutDialog;
Var
 PreviousButtons: LongInt;
 Key: Word;
 Done: Boolean;

 Procedure DrawIllustration;
 Var I,X: Integer;
 Begin
  FillRectArea(125,112,515,246,DarkGray);
  { Two overlapping sheets and handwritten lines. }
  FillRectArea(208,135,346,219,Brown);
  FillRectArea(196,142,333,228,LightGray);
  FillRectArea(214,128,359,218,Yellow);
  SetColor(Brown);
  Rectangle(214,128,359,218);
  Rectangle(220,134,353,212);
  DrawTextAt(229,144,'Aa',Brown);
  For I:=0 To 4 Do
   Line(230,162+I*8,336-(I mod 3)*13,162+I*8);

  { Feather silhouette drawn in nested strokes along the shaft. }
  For I:=0 To 63 Do Begin
   X:=330+I;
   SetColor(Brown);
   Line(X,197-I-I div 5,X,211-I+I div 9);
   SetColor(LightGray);
   Line(X,199-I-I div 5,X,209-I+I div 9);
  End;
  SetColor(White);
  Line(334,204,393,130);
  SetColor(Brown);
  Line(316,227,402,118);
  Line(317,227,403,118);
  For I:=0 To 5 Do Begin
   X:=343+I*8;
   Line(X,193-I*10,X+4,181-I*10);
   Line(X,193-I*10,X+10,195-I*10);
  End;
 End;

Begin
 EraseSoftCursor;
 FillRectArea(110,76,530,414,CLR_3D_FACE);
 DrawButton3D(110,76,530,414,False);
 OsTitleBar(113,79,527,98,Tr('A propos de WorDium'),84);
 DrawIllustration;
 ApplyRunStyle(CurrentStyle);
 DrawTextAt(126,259,'WorDium  1.00',Blue);
 DrawTextAt(126,277,Tr('Traitement de texte graphique en Pascal'),Black);
 SetColor(DarkGray);
 Line(126,293,514,293);
 DrawTextAt(126,306,Tr('Auteur'),DarkGray);
 DrawTextAt(235,306,'Sylvain Maltais',Black);
 DrawTextAt(126,324,Tr('Licence'),DarkGray);
 DrawTextAt(235,324,'MIT',Black);
 DrawTextAt(126,342,Tr('Creation'),DarkGray);
 DrawTextAt(235,342,'2026',Black);
 DrawTextAt(126,360,Tr('Site'),DarkGray);
 DrawTextAt(235,360,'www.gladir.com/office-0',Blue);
 DrawButton3D(415,378,515,404,False);
 DrawTextAt(440,387,Tr('Fermer'),Black);

 PreviousButtons:=MsBtn;
 Repeat
  Done:=False;
  If KeyPressed Then Begin
   Key:=ReadKeyEx;
   Done:=(Key=KEY_ENTER) Or (Key=KEY_ESC) Or (Key=32);
  End;
  EraseSoftCursor;
  GetMouseStateLI(MsX,MsY,MsBtn);
  If ((MsBtn and MB_LEFT)<>0) And ((PreviousButtons and MB_LEFT)=0) Then
   If (MsX>=415) And (MsX<=515) And (MsY>=378) And (MsY<=404) Then Done:=True;
  PreviousButtons:=MsBtn;
  If Not Done Then Begin
    DrawSoftCursor(MsX,MsY); 
   Delay(10);
  End;
 Until Done;
 NeedsRedraw:=True;
End;




{ ---- OS/2-0 : impression par le tampon d'impression d'OS/2 ----
  La version Windows imprime par PrintDlg et GDI ; la version DOS ne
  l'offre pas. Ici chaque page est dessinee par la GPI dans un contexte
  OD_QUEUED (DevOpenDC, donnees PM_Q_STD) : PMSPL.DLL met le travail dans
  la file par defaut et PicPrint (PMPIC.DLL) l'envoie a l'imprimante
  (graphique ESC/P, 120 x 72 points par pouce). La page de WorDium (460
  x 600) devient une page de 960 x 760 points (/W:960 /H:760 des
  parametres du processeur de file), soit 8 x 10,5 pouces. Memes elements
  que la version Windows : en-tete et pied DOCX, graphiques PDF, texte
  (gras, italique, souligne, couleurs), tableaux, filets, images. }

Function DevOpenDC(Hab, Typ, PTok, N, PDop, HComp : LongInt) : LongInt; External 'PMGPI';
Function DevCloseDC(H : LongInt) : LongInt; External 'PMGPI';
Function DevEscape(H, Code, NIn, PIn, PNOut, POut : LongInt) : LongInt; External 'PMGPI';
Function GpiCreatePS(Hab, Hdc, PSize, Fl : LongInt) : LongInt; External 'PMGPI';
Function GpiDestroyPS(Hps : LongInt) : LongInt; External 'PMGPI';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiSetCharBox(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiSetCharShear(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiCharStringAt(Hps, PPt, N, P : LongInt) : LongInt; External 'PMGPI';

Const
 PRN_W = 960;
 PRN_H = 760;
 { couleurs de la BGI (EGA) -> couleurs CLR_* de la GPI }
 PrnClr : Array[0..15] Of LongInt = (-1, 9, 12, 13, 10, 11, 14, 15, 8, 1, 4, 5, 2, 3, 6, -2);

Var
 PrnHps : LongInt;
 PrnOK  : Boolean;
 PrnPt  : Array[0..3] Of LongInt;

Function PrnX(V : LongInt) : LongInt;
Begin
 PrnX := V * PRN_W Div PAGE_W;
End;

{ y de la page (vers le bas) -> y de la GPI (vers le haut) }
Function PrnY(V : LongInt) : LongInt;
Begin
 PrnY := PRN_H - V * PRN_H Div PAGE_H;
End;

Procedure PrnColor(C : Byte);
Begin
 If GpiSetColor(PrnHps, PrnClr[C And 15]) = 0 Then PrnOK := False;
End;

{ rectangle plein (Filled) ou trait de (AX, AY) a (BX, BY), pixels de la page }
Procedure PrnShape(AX, AY, BX, BY : Integer; Color : Byte; Filled : Boolean);
Begin
 If Not PrnOK Then Exit;
 PrnColor(Color);
 If Filled Then
 Begin
  PrnPt[0] := PrnX(AX); PrnPt[1] := PrnY(BY + 1);
  OsDummy := GpiMove(PrnHps, LongInt(@PrnPt));
  PrnPt[0] := PrnX(BX + 1) - 1; PrnPt[1] := PrnY(AY);
  If PrnPt[0] < PrnX(AX) Then PrnPt[0] := PrnX(AX);
  If GpiBox(PrnHps, 1, LongInt(@PrnPt), 0, 0) = 0 Then PrnOK := False;
 End
 Else
 Begin
  PrnPt[0] := PrnX(AX); PrnPt[1] := PrnY(AY);
  OsDummy := GpiMove(PrnHps, LongInt(@PrnPt));
  PrnPt[0] := PrnX(BX); PrnPt[1] := PrnY(BY);
  If GpiLine(PrnHps, LongInt(@PrnPt)) = 0 Then PrnOK := False;
 End;
End;

{ texte en (AX, AY) (haut des caracteres), Height pixels, Advance pixels
  par caractere : police de la GPI (VGA 8 x 16) a l'echelle de la page }
Procedure PrnText(AX, AY : Integer; Const Value : String; Const Sty : TCharStyle;
                  Height, Advance : Integer);
Var K, Pass, Bx : LongInt; Box : Array[0..1] Of LongInt; Sh : Array[0..1] Of LongInt;
Begin
 If (Value = '') Or Not PrnOK Then Exit;
 If Height < 4 Then Height := 4;
 If Advance < 2 Then Advance := 2;
 PrnColor(Sty.Color);
 Box[0] := PrnX(Advance) Shl 16;
 Box[1] := (Height * PRN_H Div PAGE_H) * 16 Div 10 Shl 16;
 OsDummy := GpiSetCharBox(PrnHps, LongInt(@Box));
 If (Sty.Style And STY_ITALIC) <> 0 Then Begin Sh[0] := 1; Sh[1] := 4; End
 Else Begin Sh[0] := 0; Sh[1] := 1; End;
 OsDummy := GpiSetCharShear(PrnHps, LongInt(@Sh));
 For Pass := 0 To Ord((Sty.Style And STY_BOLD) <> 0) Do
  For K := 1 To Length(Value) Do
   If Value[K] <> ' ' Then
   Begin
    Bx := AX + (K - 1) * Advance;
    PrnPt[0] := PrnX(Bx) + Pass * 2; PrnPt[1] := PrnY(AY + Height * 7 Div 8);
    If GpiCharStringAt(PrnHps, LongInt(@PrnPt), 1, LongInt(@Value[K])) = 0 Then PrnOK := False;
   End;
 If (Sty.Style And STY_UNDERLINE) <> 0 Then
  PrnShape(AX, AY + Height, AX + Length(Value) * Advance - 1, AY + Height, Sty.Color, True);
 Sh[0] := 0; Sh[1] := 1;
 OsDummy := GpiSetCharShear(PrnHps, LongInt(@Sh));
End;

{ image (indices 0..15, Width x Height) : suites de pixels de meme couleur }
Procedure PrnPicture(AX, AY, Width, Height : Integer; Data : Pointer);
Var Row, Col, Start : LongInt; C : Byte; Src : ^Byte;
Begin
 If (Data = Nil) Or (Width <= 0) Or (Height <= 0) Then Exit;
 For Row := 0 To Height - 1 Do
 Begin
  Col := 0;
  While Col < Width Do
  Begin
   Src := Pointer(LongInt(Data) + Row * Width + Col);
   C := Src^ And 15;
   Start := Col;
   Repeat
    Inc(Col);
    Src := Pointer(LongInt(Data) + Row * Width + Col);
   Until (Col >= Width) Or ((Src^ And 15) <> C);
   If C <> White Then PrnShape(AX + Start, AY + Row, AX + Col - 1, AY + Row, C, True);
  End;
 End;
End;

{ une page : nouveau travail du tampon d'impression }
Function PrnPage(PrintPage : Integer) : Boolean;
Var
 Hdc, N, Job : LongInt;
 L, P, I, J, R, C, T, X, Y, W, PageX : Integer;
 Dop  : Array[0..8] Of LongInt;
 Sz   : Array[0..1] Of LongInt;
 Z0, Z1, Z3, Z6, ZN : Array[0..63] Of Char;
 S    : String;
 St   : TCharStyle;
Begin
 PrnPage := False;
 OsPutZ(LongInt(@Z0), ''); OsPutZ(LongInt(@Z1), 'IBMNULL'); OsPutZ(LongInt(@Z3), 'PM_Q_STD');
 OsPutZ(LongInt(@Z6), '/W:960 /H:760'); OsPutZ(LongInt(@ZN), 'WorDium');
 For I := 0 To 8 Do Dop[I] := 0;
 Dop[0] := LongInt(@Z0); Dop[1] := LongInt(@Z1); Dop[3] := LongInt(@Z3); Dop[6] := LongInt(@Z6);
 Hdc := DevOpenDC(OsHab, 2, OsZs('*'), 7, LongInt(@Dop), 0);
 If Hdc = 0 Then Exit;
 Sz[0] := 0; Sz[1] := 0;
 PrnHps := GpiCreatePS(OsHab, Hdc, LongInt(@Sz), $4008);
 PrnOK := (PrnHps <> 0) And (DevEscape(Hdc, 8150, 7, LongInt(@ZN), 0, 0) = 1);
 If PrnOK Then
 Begin
  PageX := (SCREEN_W - PAGE_W) Div 2;
  FillChar(St, SizeOf(St), 0); St.FontSize := 12;
  If Doc^.PDFPageCount = 0 Then
  Begin
   PrnText((PAGE_W - Length(DocxHeaderText) * 8) Div 2, PAGE_MARGIN_T Div 2, DocxHeaderText, St, 8, 8);
   PrnText((PAGE_W - Length(DocxFooterText) * 8) Div 2, PAGE_H - 22, DocxFooterText, St, 8, 8);
  End;
  For I := 1 To Doc^.PDFGraphicCount Do
   With Doc^.PDFGraphics[I] Do
    If Doc^.PDFGraphics[I].Page = PrintPage Then PrnShape(X1, Y1, X2, Y2, Color, Kind = 2);
  For L := 1 To VLineCount Do
  Begin
   If VLines[L].PageIdx <> PrintPage Then Continue;
   P := VLines[L].ParaIdx;
   Y := VLines[L].Y - (DOCAREA_TOP + 8) - (PrintPage - 1) * (PAGE_H + 12);
   X := VLines[L].X - PageX;
   If VLines[L].IsImage Then
    With Doc^.Paragraphs[P] Do PrnPicture(X, Y, ImgW, ImgH, ImgData)
   Else If VLines[L].IsTable Then
   Begin
    T := Doc^.Paragraphs[P].TableIdx;
    R := VLines[L].TblRow; W := VLines[L].Width Div Tables[T].Cols;
    FillChar(St, SizeOf(St), 0); St.FontSize := 12;
    For C := 1 To Tables[T].Cols Do
    Begin
     PrnShape(X, Y, X + W, Y, Black, True);
     PrnShape(X, Y, X, Y + TBL_CELL_HEIGHT, Black, True);
     PrnShape(X + W, Y, X + W, Y + TBL_CELL_HEIGHT, Black, True);
     If R = Tables[T].Rows Then
      PrnShape(X, Y + TBL_CELL_HEIGHT, X + W, Y + TBL_CELL_HEIGHT, Black, True);
     S := CellTextOf(P, R, C);
     PrnText(X + TBL_CELL_PAD, Y + (TBL_CELL_HEIGHT - 8) Div 2, S, St, 8, 8);
     Inc(X, W);
    End;
   End
   Else If Doc^.Paragraphs[P].PDF.Active Then
   Begin
    S := Copy(ParaText(P), VLines[L].CharStart, VLines[L].CharLen);
    With Doc^.Paragraphs[P] Do
     PrnText(X, Y, S, Runs[1].Style, PDF.Height, PDFTextWidth(S, PDF.Face, PDF.Height, Runs[1].Style.Style)
             Div (Length(S) + Ord(S = '')));
   End
   Else
   Begin
    For I := 0 To VLines[L].CharLen - 1 Do
    Begin
     J := VLines[L].CharStart - 1 + I;
     LocateChar(P, J, R, C);
     With Doc^.Paragraphs[P].Runs[R] Do
      PrnText(LineCharScreenX(L, J) - PageX, Y, Text[C + 1], Style, RunHeight(Style), RunAdvance(Style));
    End;
    If VLineIsLastInPara(L) And Doc^.Paragraphs[P].BorderBottom Then
     PrnShape(PAGE_MARGIN_L, Y + VLines[L].Height - 1, PAGE_W - PAGE_MARGIN_R,
              Y + VLines[L].Height - 1, DarkGray, True);
   End;
  End;
 End;
 N := 2; Job := 0;
 If PrnOK Then PrnOK := DevEscape(Hdc, 8151, 0, 0, LongInt(@N), LongInt(@Job)) = 1
 Else OsDummy := DevEscape(Hdc, 8153, 0, 0, 0, 0);
 If PrnHps <> 0 Then OsDummy := GpiDestroyPS(PrnHps);
 OsDummy := DevCloseDC(Hdc);
 PrnPage := PrnOK;
End;

Procedure PrintDocument;
Var
 SavedView, OK : Boolean;
 PrintPage, FirstPage, LastPage, Code, K : Integer;
 S : String;
Begin
 SavedView := PageLayoutView;
 PageLayoutView := True;
 LayoutDocument;
 FirstPage := 1; LastPage := Doc^.PageCount;
 Str(FirstPage, S); Str(LastPage, StatusMsg);
 S := S + '-' + StatusMsg; StatusMsg := '';
 OK := InputBoxDlg(Tr('Imprimer'), Tr('Pages a imprimer (ex. 1-3) :'), S, 20);
 If OK Then
 Begin
  K := Pos('-', S);
  If K > 0 Then
  Begin
   Val(Copy(S, 1, K - 1), FirstPage, Code); If Code <> 0 Then FirstPage := 1;
   Val(Copy(S, K + 1, 20), LastPage, Code); If Code <> 0 Then LastPage := Doc^.PageCount;
  End
  Else
  Begin
   Val(S, FirstPage, Code);
   If Code <> 0 Then FirstPage := 1;
   LastPage := FirstPage;
  End;
  If FirstPage < 1 Then FirstPage := 1;
  If LastPage > Doc^.PageCount Then LastPage := Doc^.PageCount;
  For PrintPage := FirstPage To LastPage Do
   If OK Then OK := PrnPage(PrintPage);
  If OK Then StatusMsg := Tr('Document transmis a l''imprimante.')
  Else ShowMessage(Tr('Echec de l''impression.'));
 End;
 PageLayoutView := SavedView;
 NeedsRelayout := True; NeedsRedraw := True;
End;


{ Fichier existant ? (test d'ouverture en lecture) }
Function FileAlreadyExists(Const FN: String): Boolean;
Var F: File;
Begin
 FileAlreadyExists := False;
 {$I-} Assign(F, FN); Reset(F, 1); {$I+}
 If IOResult = 0 Then Begin
  {$I-} Close(F); {$I+}
  If IOResult <> 0 Then ;
  FileAlreadyExists := True;
 End;
End;

{ Boite "Enregistrer" : redemande le nom tant que l'utilisateur refuse
  d'ecraser un fichier existant. Retourne False si annule. }
Function AskSaveFileName(Const Title, Filter: String;
                         Var FN: String): Boolean;
Begin
 AskSaveFileName := False;
 Repeat
  If Not ShowFileDialog(Title, True, Filter, FN) Then Exit;
  EnsureDocExt(FN, ExtIsDocx(FN));
  If Not FileAlreadyExists(FN) Then Begin
   AskSaveFileName := True; Exit;
  End;
  If ShowConfirmYN(Tr('File already exists. Overwrite it?')) Then Begin
   AskSaveFileName := True; Exit;
  End;
 Until False;
End;

Procedure ExecAction(Act: Integer);
Var
 FNameTmp : String;
 ImgBuf   : Pointer;
 IW, IH   : Integer;
 Ext      : String;
 LF       : Integer;
 CC       : Char;
 LoadOK   : Boolean;
Begin
 Case Act Of
  ACT_FILE_NEW    : Begin
                     If Doc^.Modified Then
                      If Not ShowConfirmYN(Tr('Discard unsaved changes?')) Then
                        Exit;
                     InitDocument; LayoutDocument;
                     ClearAllUndo;
                     StatusMsg := Tr('New document'); NeedsRedraw := True;
                    End;
  ACT_FILE_OPEN   : Begin
                     If Doc^.Modified Then
                      If Not ShowConfirmYN(Tr('Discard unsaved changes?')) Then
                        Exit;
                     FNameTmp := '';
                     If ShowFileDialog(Tr('Open Document'), False,
                       Tr('Documents (*.WPD;*.DOCX;*.DOC;*.PDF;*.GAT;*.GPX)|*'+
                         '.WP'+
                       'D;*.DOCX;*.DOC;*.PDF;*.GAT;*.GPX|GPX (*.GPX)|*.GPX|GA'+
                       'T MonsterBook (*.GAT)|*.GAT|PDF (*.PDF)|*.PDF|WPD (*.'+
                       'WPD)|*.WPD|DOCX (*.DOCX)|*.DOCX|DOC (*.DOC)|*.DOC|Tou'+
                       's (*.*)|*.*'), FNameTmp) Then Begin
                      EnsureDocExt(FNameTmp, ExtIsDocx(FNameTmp));
                      If LoadAnyDocument(FNameTmp) Then Begin
                       LayoutDocument;
                       ClearAllUndo;
                       StatusMsg := Tr('Opened ') + FNameTmp;
                       If GatTruncated Then StatusMsg :=
                         Tr('GAT tronque (500 paragraphes max)');
                      End Else
                       ShowMessage(
                         Tr('Cannot open file (PDF: readable text requ'+
                         'ired): ') + FNameTmp);
                     End;
                     NeedsRedraw := True;
                    End;
  ACT_FILE_SAVE   : Begin
                     FNameTmp := Doc^.FileName;
                     If (FNameTmp = '') Or (FNameTmp = 'Document1') Then Begin
                      If Not AskSaveFileName(Tr('Save Document'),
                        Tr('Documents (*.WPD;*.DOCX;*.GAT)|*.WPD;*.DOCX;*.GAT'+
                          '|WP'+
                        'D (*.WPD)|*.WPD|DOCX (*.DOCX)|*.DOCX|GAT MonsterBook'+
                        ' (*.GAT)|*.GAT'), FNameTmp) Then Begin
                      { .DOC en sortie n'est pas supporte (Phase 9 lecture
                        seule) }
                       NeedsRedraw := True; Exit;
                      End;
                     End;
                     EnsureDocExt(FNameTmp, ExtIsDocx(FNameTmp));
                     If SaveAnyDocument(FNameTmp) Then Begin
                      Doc^.FileName := FNameTmp;
                      Doc^.Modified := False;
                      StatusMsg := Tr('Saved ') + FNameTmp;
                     End Else
                      ShowMessage(Tr('Cannot save file: ') + FNameTmp);
                     NeedsRedraw := True;
                    End;
  ACT_FILE_SAVEAS : Begin
                     FNameTmp := Doc^.FileName;
                     If FNameTmp = 'Document1' Then FNameTmp := '';
                     If AskSaveFileName(Tr('Save As'),
                       Tr('Documents (*.WPD;*.DOCX;*.GAT)|*.WPD;*.DOCX;*.GAT|'+
                         'WPD'+
                       ' (*.WPD)|*.WPD|DOCX (*.DOCX)|*.DOCX|GAT MonsterBook ('+
                       '*.GAT)|*.GAT'), FNameTmp) Then Begin
                      EnsureDocExt(FNameTmp, ExtIsDocx(FNameTmp));
                      If ExtIsDoc(FNameTmp) And (Not ExtIsDocx(FNameTmp)) Then
                        Begin
                       ShowMessage(Tr('Cannot save as .DOC (read-only format)')
                         );
                       NeedsRedraw := True; Exit;
                      End;
                      If SaveAnyDocument(FNameTmp) Then Begin
                       Doc^.FileName := FNameTmp;
                       Doc^.Modified := False;
                       StatusMsg := Tr('Saved ') + FNameTmp;
                      End Else
                       ShowMessage(Tr('Cannot save file: ') + FNameTmp);
                     End;
                     NeedsRedraw := True;
                    End;
  ACT_FILE_PRINT  : PrintDocument;
  ACT_FILE_EXIT   : AppShouldExit := True;

  ACT_EDIT_UNDO   : DoUndo;
  ACT_EDIT_REDO   : DoRedo;
  ACT_EDIT_CUT    : StatusMsg := Tr('Cut (Phase 2+)');
  ACT_EDIT_COPY   : StatusMsg := Tr('Copy (Phase 2+)');
  ACT_EDIT_PASTE  : StatusMsg := Tr('Paste (Phase 2+)');
  ACT_EDIT_FIND   : DoFindDialog;
  ACT_EDIT_REPL   : DoReplaceDialog;
  ACT_EDIT_FIND_NEXT : DoFindNext;

  ACT_VIEW_NORMAL : ChangeDocumentView(False);
  ACT_VIEW_PAGE   : ChangeDocumentView(True);
  ACT_VIEW_RULER  : ToggleDocumentRuler;
  ACT_VIEW_ZOOM   : ShowZoomDialog;

  ACT_INS_PAGEBRK : Begin
                     If Doc^.ParaCount < MAX_PARAS_PER_DOC Then Begin
                      MarkMutation(2);
                      { Si curseur n'est pas en t?te de paragraphe, splitte
                        d'abord pour que le saut de page s'applique au
                        nouveau paragraphe. }
                      If Cursor.CharIdx > 0 Then NewParagraphAtCursor
                      Else If Cursor.ParaIdx > 1 Then ;
                      Doc^.Paragraphs[Cursor.ParaIdx].PageBreakBefore := True;
                      Doc^.Modified  := True;
                      NeedsRelayout := True;
                      StatusMsg := Tr('Page break inserted');
                     End;
                    End;
  ACT_INS_IMAGE   : Begin
                     FNameTmp := '';
                     If ShowFileDialog(Tr('Insert Picture'), False,
                      Tr('Images (*.BMP;*.PCX;*.GIF;*.JPG;*.GPX)|*.BMP;'+
                      '*.GPX;*.PCX;*.BGX;*.XBM;*.TIF;*.TIFF;*.GIF;*.JPG;'+
                      '*.JPEG|BMP (*.BMP)|*.BMP|PCX (*.PCX)|*.PCX|'+
                      'GIF (*.GIF)|*.GIF|JPEG (*.JPG;*.JPEG)|'+
                      '*.JPG;*.JPEG|TIFF (*.TIF;*.TIFF)|*.TIF;'+
                      '*.TIFF|Tous (*.*)|*.*'), FNameTmp) Then Begin
                      LoadOK := False; ImgBuf := Nil; IW := 0; IH := 0;
                      LoadOK := LoadAnyImage(FNameTmp, ImgBuf, IW, IH);
                      If LoadOK Then Begin
                       MarkMutation(2);
                       InsertImageAtCursor(ImgBuf, IW, IH);
                       LayoutDocument;
                       StatusMsg := Tr('Picture inserted: ') + FNameTmp;
                      End Else
                       ShowMessage(Tr('Cannot load image: ') + FNameTmp);
                     End;
                     NeedsRedraw := True;
                    End;
  ACT_INS_SYMBOL  : ShowSymbolDialog;
  ACT_INS_TABLE   : Begin
                     MarkMutation(2);
                     InsertTableAtCursor(3, 3);
                     NeedsRelayout := True;
                     NeedsRedraw   := True;
                    End;

  ACT_FMT_FONT    : ShowFontDialog;
  ACT_FMT_PARA    : ShowParagraphDialog;
  ACT_FMT_BOLD    : Begin
                     If SelHasRange Then Begin
                      MarkMutation(2);
                      SelApplyStyleBit(STY_BOLD);
                     End;
                     CurrentStyle.Style := CurrentStyle.Style Xor STY_BOLD;
                     FmtBar[1].Pressed := (CurrentStyle.Style And STY_BOLD) <>
                       0;
                     StatusMsg := Tr('Toggle Bold');
                    End;
  ACT_FMT_ITALIC  : Begin
                     If SelHasRange Then Begin
                      MarkMutation(2);
                      SelApplyStyleBit(STY_ITALIC);
                     End;
                     CurrentStyle.Style := CurrentStyle.Style Xor STY_ITALIC;
                     FmtBar[2].Pressed := (CurrentStyle.Style And STY_ITALIC) <>
                       0;
                     StatusMsg := Tr('Toggle Italic');
                    End;
  ACT_FMT_UNDER   : Begin
                     If SelHasRange Then Begin
                      MarkMutation(2);
                      SelApplyStyleBit(STY_UNDERLINE);
                     End;
                     CurrentStyle.Style := CurrentStyle.Style Xor STY_UNDERLINE;
                     FmtBar[3].Pressed := (CurrentStyle.Style And STY_UNDERLINE)
                       <> 0;
                     StatusMsg := Tr('Toggle Underline');
                    End;
  ACT_FMT_LEFT    : Begin
                     MarkMutation(2);
                     CurrentAlign := ALIGN_LEFT;
                     Doc^.Paragraphs[Cursor.ParaIdx].Alignment := ALIGN_LEFT;
                     FmtBar[4].Pressed := True;  FmtBar[5].Pressed := False;
                     FmtBar[6].Pressed := False; FmtBar[7].Pressed := False;
                     Doc^.Modified := True; NeedsRelayout := True;
                     StatusMsg := Tr('Align Left');
                    End;
  ACT_FMT_CENTER  : Begin
                     MarkMutation(2);
                     CurrentAlign := ALIGN_CENTER;
                     Doc^.Paragraphs[Cursor.ParaIdx].Alignment := ALIGN_CENTER;
                     FmtBar[4].Pressed := False; FmtBar[5].Pressed := True;
                     FmtBar[6].Pressed := False; FmtBar[7].Pressed := False;
                     Doc^.Modified := True; NeedsRelayout := True;
                     StatusMsg := Tr('Align Center');
                    End;
  ACT_FMT_RIGHT   : Begin
                     MarkMutation(2);
                     CurrentAlign := ALIGN_RIGHT;
                     Doc^.Paragraphs[Cursor.ParaIdx].Alignment := ALIGN_RIGHT;
                     FmtBar[4].Pressed := False; FmtBar[5].Pressed := False;
                     FmtBar[6].Pressed := True;  FmtBar[7].Pressed := False;
                     Doc^.Modified := True; NeedsRelayout := True;
                     StatusMsg := Tr('Align Right');
                    End;
  ACT_FMT_JUSTIFY : Begin
                     MarkMutation(2);
                     CurrentAlign := ALIGN_JUSTIFY;
                     Doc^.Paragraphs[Cursor.ParaIdx].Alignment := ALIGN_JUSTIFY;
                     FmtBar[4].Pressed := False; FmtBar[5].Pressed := False;
                     FmtBar[6].Pressed := False; FmtBar[7].Pressed := True;
                     Doc^.Modified := True; NeedsRelayout := True;
                     StatusMsg := Tr('Justify');
                    End;
  ACT_FMT_COLOR   : Begin
                     CurrentStyle.Color := (CurrentStyle.Color + 1) And 15;
                     If CurrentStyle.Color = 0 Then
                      StatusMsg := Tr('Color: Black')
                     Else Begin
                      Str(CurrentStyle.Color, StatusMsg);
                      StatusMsg := Tr('Color #') + StatusMsg;
                     End;
                    End;

  ACT_TLS_SPELL   : DoSpellDialog;
  ACT_TLS_WORDS   : ShowWordCountDialog;
  ACT_TLS_OPTIONS : ShowOptionsDialog;

  ACT_TBL_INSERT  : Begin
                     MarkMutation(2);
                     InsertTableAtCursor(3, 3);
                     NeedsRelayout := True;
                     NeedsRedraw   := True;
                    End;
  ACT_TBL_DELETE  : Begin
                     If CursorInTable Then Begin
                      MarkMutation(2);
                      DeleteTableAtPara(Cursor.ParaIdx);
                      NeedsRelayout := True;
                      NeedsRedraw   := True;
                     End Else
                      ShowMessage(Tr('Le curseur n''est pas dans un tableau.'));
                    End;

  ACT_WIN_CASCADE : StatusMsg := Tr('Cascade (single-doc)');

  ACT_HLP_CONTENT : ShowHelpContents;
  ACT_HLP_ABOUT   : ShowAboutDialog;
 Else
  StatusMsg := Tr('Action non implementee');
 End;
End;

{ ============================================================ }
{ =====================  BO??TE MESSAGE  ====================== }
{ ============================================================ }

Procedure ShowMessage(Const S: String);
Begin
 { OS/2-0 : boite de message de Presentation Manager }
 OsDummy := OsBox('WorDium', S, MB_OK Or MB_INFORMATION);
 Repeat GetMouseStateLI(MsX, MsY, MsBtn); Until (MsBtn And MB_LEFT) = 0;
 NeedsRedraw := True;
End;

{ ============================================================ }
{ =====================  GESTION CLAVIER  ==================== }
{ ============================================================ }

{ Trouve un menu par sa lettre Alt (insensible ?? la casse) }
Function FindMenuByAlt(Alt: Char): Integer;
Var I, R: Integer;
Begin
 R := 0;
 For I := 1 To MenuCount Do
  If UpCase(Menus[I].AltKey) = UpCase(Alt) Then R := I;
 FindMenuByAlt := R;
End;

{ Trouve un item de menu par sa lettre Alt }
Function FindItemByAlt(M: Integer; Alt: Char): Integer;
Var I, R: Integer;
Begin
 R := 0;
 For I := 1 To Menus[M].ItemCount Do
  If (Not Menus[M].Items[I].Separator) And
     (UpCase(Menus[M].Items[I].AltKey) = UpCase(Alt)) Then R := I;
 FindItemByAlt := R;
End;

Procedure HandleMenuKey(K: Word);
Var Idx, SavedM: Integer;
Begin
 Case K Of
  KEY_ESC: Begin ActiveMenu := 0; MenuItemHover := 0;
                 MenuKeyboardMode := False; End;
  KEY_LEFT: Begin
   Dec(ActiveMenu); If ActiveMenu < 1 Then ActiveMenu := MenuCount;
   MenuItemHover := 1;
  End;
  KEY_RIGHT: Begin
   Inc(ActiveMenu); If ActiveMenu > MenuCount Then ActiveMenu := 1;
   MenuItemHover := 1;
  End;
  KEY_UP: Begin
   Repeat
    Dec(MenuItemHover);
    If MenuItemHover < 1 Then MenuItemHover := Menus[ActiveMenu].ItemCount;
   Until Not Menus[ActiveMenu].Items[MenuItemHover].Separator;
  End;
  KEY_DOWN: Begin
   Repeat
    Inc(MenuItemHover);
    If MenuItemHover > Menus[ActiveMenu].ItemCount Then MenuItemHover := 1;
   Until Not Menus[ActiveMenu].Items[MenuItemHover].Separator;
  End;
  KEY_ENTER: Begin
   If (MenuItemHover >= 1) And
      (Not Menus[ActiveMenu].Items[MenuItemHover].Separator) Then Begin
    SavedM := ActiveMenu;
    Idx := Menus[SavedM].Items[MenuItemHover].ActionId;
    ActiveMenu := 0; MenuItemHover := 0;
    MenuKeyboardMode := False;
    ExecAction(Idx);
   End;
  End;
 Else
  { Lettre Alt ??? item du menu actif }
  If (K >= Ord('A')) And (K <= Ord('z')) Then Begin
   SavedM := ActiveMenu;
   Idx := FindItemByAlt(SavedM, Chr(K));
   If Idx > 0 Then Begin
    ActiveMenu := 0; MenuItemHover := 0;
    MenuKeyboardMode := False;
    ExecAction(Menus[SavedM].Items[Idx].ActionId);
   End;
  End;
 End;
End;

{ Raccourcis Ctrl+X au niveau application. ReadKey retourne #1..#26. }
Procedure HandleCtrlKey(C: Char);
Begin
 Case C Of
  #14: ExecAction(ACT_FILE_NEW);    { Ctrl+N }
  #15: ExecAction(ACT_FILE_OPEN);   { Ctrl+O }
  #19: ExecAction(ACT_FILE_SAVE);   { Ctrl+S }
  #16: ExecAction(ACT_FILE_PRINT);  { Ctrl+P }
  #26: ExecAction(ACT_EDIT_UNDO);   { Ctrl+Z }
  #25: ExecAction(ACT_EDIT_REDO);   { Ctrl+Y }
  #24: ExecAction(ACT_EDIT_CUT);    { Ctrl+X }
  #03: ExecAction(ACT_EDIT_COPY);   { Ctrl+C }
  #22: ExecAction(ACT_EDIT_PASTE);  { Ctrl+V }
  #06: ExecAction(ACT_EDIT_FIND);   { Ctrl+F }
  #08: ExecAction(ACT_EDIT_REPL);   { Ctrl+H }
  #02: ExecAction(ACT_FMT_BOLD);    { Ctrl+B }
  #09: ExecAction(ACT_FMT_ITALIC);  { Ctrl+I (Tab=#9 aussi) }
  #21: ExecAction(ACT_FMT_UNDER);   { Ctrl+U }
  #12: ExecAction(ACT_FMT_LEFT);    { Ctrl+L }
  #05: ExecAction(ACT_FMT_CENTER);  { Ctrl+E }
  #18: ExecAction(ACT_FMT_RIGHT);   { Ctrl+R }
 End;
End;

Procedure ExecuteRibbonEntry(Index: Integer);
Var Act: Integer;
Begin
 If Not RibbonEntryEnabled(Index) Then Exit;
 Act:=RibbonEntryAction(Index);RibbonKeyboard:=False;RibbonFocus:=0;
 RibbonPressed:=0;ActiveMenu:=0;NeedsRedraw:=True;ExecAction(Act);
End;
Procedure RibbonMoveFocus(Direction: Integer);
Var I,N: Integer;
Begin
 N:=RibbonItemCount;I:=RibbonFocus;
 If (I=0) And (Direction<0) Then I:=N+1;
 Repeat
  Inc(I,Direction);
  If (I<1) Or (I>N) Then Begin RibbonFocus:=0;Exit;End;
  If RibbonEntryEnabled(I) Then Begin RibbonFocus:=I;Exit;End;
 Until False;
End;
Function HandleRibbonKey(K: Word): Boolean;
Var Tab,Direction: Integer;
Begin
 HandleRibbonKey:=False;If Not RibbonMode Then Exit;Tab:=0;
 Case K Of
  KEY_ALT_F: Tab:=1;KEY_ALT_E: Tab:=2;KEY_ALT_V: Tab:=3;KEY_ALT_I: Tab:=4;
  KEY_ALT_O: Tab:=5;KEY_ALT_T: Tab:=6;KEY_ALT_A: Tab:=7;KEY_ALT_W:
    Tab:=8;KEY_ALT_H: Tab:=9;
 End;
 If Tab>0 Then Begin
  RibbonTab:=Tab;RibbonKeyboard:=True;RibbonFocus:=0;RibbonPressed:=0;
    ActiveMenu:=0;
  NeedsRedraw:=True;HandleRibbonKey:=True;Exit;
 End;
 If K=KEY_F10 Then Begin
  RibbonKeyboard:=Not
    RibbonKeyboard;RibbonFocus:=0;NeedsRedraw:=True;HandleRibbonKey:=True;Exit;
 End;
 If Not RibbonKeyboard Then Exit;
 HandleRibbonKey:=True;Direction:=0;
 Case K Of
  KEY_LEFT: Direction:=-1;KEY_RIGHT: Direction:=1;
  KEY_UP,271: RibbonMoveFocus(-1);KEY_DOWN,KEY_TAB: RibbonMoveFocus(1);
  KEY_ESC: If RibbonFocus>0 Then RibbonFocus:=0 Else RibbonKeyboard:=False;
  KEY_ENTER,32: If RibbonFocus=0 Then RibbonMoveFocus(1) Else
    ExecuteRibbonEntry(RibbonFocus);
  Else Begin RibbonKeyboard:=False;RibbonFocus:=0;HandleRibbonKey:=False;End;
 End;
 If Direction<>0 Then Begin
  If RibbonFocus=0 Then Begin
   Inc(RibbonTab,Direction);If RibbonTab<1 Then RibbonTab:=MenuCount;
   If RibbonTab>MenuCount Then RibbonTab:=1;RibbonHover:=0;
  End Else RibbonMoveFocus(Direction);
 End;
 NeedsRedraw:=True;
End;

Procedure HandleKey(K: Word);
Begin
 If HandleRibbonKey(K) Then Exit;
 If ActiveMenu > 0 Then Begin
  HandleMenuKey(K);
  Exit;
 End;

 { Toute action de navigation / edition annule la selection en cours. }
 If Sel.Active Then
  If (K = KEY_LEFT) Or (K = KEY_RIGHT) Or (K = KEY_UP) Or (K = KEY_DOWN) Or
     (K = KEY_HOME) Or (K = KEY_END) Or (K = KEY_PGUP) Or (K = KEY_PGDN) Or
     (K = KEY_BACKSPACE) Or (K = KEY_DEL) Or (K = KEY_ENTER) Or
     (K = KEY_TAB) Or ((K >= 32) And (K <= 126)) Or ((K >= 128) And (K <= 254)) Then SelClear;

 Case K Of
  KEY_F10: Begin
   ActiveMenu := 1; MenuItemHover := 1; MenuKeyboardMode := True;
  End;
  KEY_ESC: ;
  KEY_ALT_F: Begin ActiveMenu := 1; MenuItemHover := 1;
    MenuKeyboardMode := True; End;
  KEY_ALT_E: Begin ActiveMenu := 2; MenuItemHover := 1;
    MenuKeyboardMode := True; End;
  KEY_ALT_V: Begin ActiveMenu := 3; MenuItemHover := 1;
    MenuKeyboardMode := True; End;
  KEY_ALT_I: Begin ActiveMenu := 4; MenuItemHover := 1;
    MenuKeyboardMode := True; End;
  KEY_ALT_O: Begin ActiveMenu := 5; MenuItemHover := 1;
    MenuKeyboardMode := True; End;
  KEY_ALT_T: Begin ActiveMenu := 6; MenuItemHover := 1;
    MenuKeyboardMode := True; End;
  KEY_ALT_A: Begin ActiveMenu := 7; MenuItemHover := 1;
    MenuKeyboardMode := True; End;
  KEY_ALT_W: Begin ActiveMenu := 8; MenuItemHover := 1;
    MenuKeyboardMode := True; End;
  KEY_ALT_H: Begin ActiveMenu := 9; MenuItemHover := 1;
    MenuKeyboardMode := True; End;
  KEY_ALT_X: ExecAction(ACT_FILE_EXIT);
  KEY_F1   : ExecAction(ACT_HLP_CONTENT);
  KEY_F3   : ExecAction(ACT_EDIT_FIND_NEXT);
  KEY_F7   : ExecAction(ACT_TLS_SPELL);

  { ----- Navigation ----- }
  KEY_LEFT : Begin CursorMoveLeft;  ResetMutation; End;
  KEY_RIGHT: Begin CursorMoveRight; ResetMutation; End;
  KEY_UP   : Begin CursorVerticalMove(-1); ResetMutation; End;
  KEY_DOWN : Begin CursorVerticalMove(1);  ResetMutation; End;
  KEY_HOME : Begin CursorMoveHome; ResetMutation; End;
  KEY_END  : Begin CursorMoveEnd;  ResetMutation; End;
  KEY_PGUP : Begin CursorPageUp;   ResetMutation; End;
  KEY_PGDN : Begin CursorPageDown; ResetMutation; End;

  { ----- Edition ----- }
  KEY_BACKSPACE: Begin MarkMutation(2); BackspaceAtCursor; End;
  KEY_DEL      : Begin MarkMutation(2); DeleteAtCursor; End;
  KEY_ENTER    : Begin MarkMutation(2); NewParagraphAtCursor; End;
  KEY_TAB      : Begin
                  If CursorInTable Then NewParagraphAtCursor   { tab = cellule
                    suivante }
                  Else Begin MarkMutation(1); InsertCharAtCursor(' '); End;
                 End;
 Else
  If ((K >= 32) And (K <= 126)) Or ((K >= 128) And (K <= 254)) Then Begin
   MarkMutation(1);
   InsertCharAtCursor(Chr(K));
  End Else If (K >= 1) And (K <= 26) Then
   HandleCtrlKey(Chr(K));
 End;

 { Toute frappe relance le clignotement }
 CursorBlinkOn  := True;
 CursorBlinkCnt := 0;
End;

{ ============================================================ }
{ =====================  GESTION SOURIS  ===================== }
{ ============================================================ }

Function PointInRect(Px, Py, X1, Y1, X2, Y2: LongInt): Boolean;
Begin
 PointInRect := (Px >= X1) And (Px <= X2) And
                (Py >= Y1) And (Py <= Y2);
End;

{ Identifie le menu sous (X,Y) dans la barre de menus ; 0 sinon. }
Function MenuAtPoint(X, Y: LongInt): Integer;
Var I, R: Integer;
Begin
 R := 0;
 If (Y >= MENUBAR_TOP) And (Y < MENUBAR_TOP+MENUBAR_HEIGHT) Then
  For I := 1 To MenuCount Do
   If (X >= Menus[I].X1) And (X <= Menus[I].X2) Then R := I;
 MenuAtPoint := R;
End;

{ Item du dropdown sous (X,Y) ; 0 sinon. }
Function DropItemAtPoint(X, Y: LongInt): Integer;
Var
 X1, Y1, X2, Y2, IH, I, R : Integer;
Begin
 R := 0;
 If ActiveMenu < 1 Then Begin DropItemAtPoint := 0; Exit; End;
 IH := 16;
 X1 := Menus[ActiveMenu].X1;
 Y1 := MENUBAR_HEIGHT;
 X2 := X1 + Menus[ActiveMenu].DropW;
 Y2 := Y1 + Menus[ActiveMenu].ItemCount * IH + 4;
 If X2 > SCREEN_W-1 Then Begin
  X1 := SCREEN_W-1 - Menus[ActiveMenu].DropW;
  X2 := SCREEN_W-1;
 End;
 If (X >= X1) And (X <= X2) And (Y >= Y1+2) And (Y <= Y2) Then Begin
  I := ((Y - (Y1+2)) Div IH) + 1;
  If (I >= 1) And (I <= Menus[ActiveMenu].ItemCount) Then R := I;
 End;
 DropItemAtPoint := R;
End;

Function StdBtnAtPoint(X, Y: LongInt): Integer;
Var I, R: Integer;
Begin
 If RibbonMode Then Begin StdBtnAtPoint:=0;Exit;End;
 R := 0;
 For I := 1 To StdBarCount Do
  If PointInRect(X, Y, StdBar[I].X, StdBar[I].Y,
                 StdBar[I].X+StdBar[I].W, StdBar[I].Y+StdBar[I].H) Then R := I;
 StdBtnAtPoint := R;
End;

Function FmtBtnAtPoint(X, Y: LongInt): Integer;
Var I, R: Integer;
Begin
 If RibbonMode Then Begin FmtBtnAtPoint:=0;Exit;End;
 R := 0;
 For I := 1 To FmtBarCount Do
  If PointInRect(X, Y, FmtBar[I].X, FmtBar[I].Y,
                 FmtBar[I].X+FmtBar[I].W, FmtBar[I].Y+FmtBar[I].H) Then R := I;
 FmtBtnAtPoint := R;
End;

{ Convertit (Mx,My) en position document la plus proche.
  Renvoie False si aucune ligne visuelle disponible. }
Function MouseToDocPos(Mx, My: LongInt; Var P, C: Integer): Boolean;
Var
 I, Best, Off, BestOff, BestDist, D : Integer;
 TestX, LineY                       : Integer;
 ParaStr, Pre, CellTxt              : String;
 TIdx, NCols, CellW, ColC, RowR     : Integer;
Begin
 Mx:=UnzoomX(Mx);My:=UnzoomY(My);
 P := 0; C := 0;
 If VLineCount = 0 Then Begin MouseToDocPos := False; Exit; End;
 Best := 0;
 BestDist := 32767;
 SetTextStyle(DefaultFont, HorizDir, 1);
 For I := 1 To VLineCount Do Begin
  If VLines[I].IsImage Then Continue;
  LineY := VLines[I].Y - ScrollY;
  If My < LineY Then D := LineY - My
  Else If My > LineY + VLines[I].Height - 1 Then D := My - (LineY +
    VLines[I].Height - 1)
  Else D := 0;
  If D < BestDist Then Begin BestDist := D; Best := I; End;
 End;
 If Best = 0 Then Begin MouseToDocPos := False; Exit; End;
 P := VLines[Best].ParaIdx;
 { Cas tableau : positionner curseur dans la cellule cliquee. }
 If VLines[Best].IsTable Then Begin
  TIdx := Doc^.Paragraphs[P].TableIdx;
  If (TIdx >= 1) And (TIdx <= MAX_TABLES) And Tables[TIdx].Used Then Begin
   NCols := Tables[TIdx].Cols;
   CellW := VLines[Best].Width Div NCols;
   ColC  := ((Mx - VLines[Best].X) Div CellW) + 1;
   If ColC < 1 Then ColC := 1;
   If ColC > NCols Then ColC := NCols;
   RowR := VLines[Best].TblRow;
   { Trouver l'offset texte le plus proche dans la cellule. }
   CellTxt := Tables[TIdx].Cells[RowR, ColC];
   BestOff := 0; BestDist := 32767;
   For Off := 0 To Length(CellTxt) Do Begin
    Pre := Copy(CellTxt, 1, Off);
    TestX := VLines[Best].X + (ColC - 1) * CellW + TBL_CELL_PAD +
      TextWidth(Pre);
    D := TestX - Mx;
    If D < 0 Then D := -D;
    If D < BestDist Then Begin BestDist := D; BestOff := Off; End;
   End;
   Cursor.ParaIdx := P;
   Cursor.RunIdx  := (RowR - 1) * NCols + ColC;
   Cursor.CharIdx := BestOff;
   { Sortie : on a deja place le curseur ; renvoyer la position
     "logique" pour compatibilite, mais HandleMouse va l'ecraser
     avec son propre Set. }
   C := BestOff;
   MouseToDocPos := True;
   Exit;
  End;
 End;
 ParaStr := ParaText(P);
 BestOff := 0;
 BestDist := 32767;
 For Off := 0 To VLines[Best].CharLen Do Begin
  Pre := Copy(ParaStr, VLines[Best].CharStart, Off);
  TestX := VLines[Best].X + StyledRangeWidth(P,VLines[Best].CharStart,Off);
  D := TestX - Mx;
  If D < 0 Then D := -D;
  If D < BestDist Then Begin BestDist := D; BestOff := Off; End;
 End;
 C := VLines[Best].CharStart - 1 + BestOff;
 MouseToDocPos := True;
End;

Function PointInDocArea(X, Y: LongInt): Boolean;
Begin
 PointInDocArea := (Y >= DOCAREA_TOP) And (Y <= DocPhysicalBottom);
End;

Procedure HandleMouse;
Var
 LeftDown, LeftPressed, LeftReleased: Boolean;
 RightDown                          : Boolean;
 M, Itm, B                          : Integer;
 NewP, NewC                         : Integer;
Begin
 LastMsBtn := MsBtn;
 GetMouseStateLI(MsX, MsY, MsBtn);
 LeftDown     := (MsBtn And MB_LEFT) <> 0;
 LeftPressed  := LeftDown And ((LastMsBtn And MB_LEFT) = 0);
 LeftReleased := (Not LeftDown) And ((LastMsBtn And MB_LEFT) <> 0);
 If LeftPressed and (ZoomPanLimit>0) and (MsY>DocPhysicalBottom) and
   (MsY<=DOCAREA_BOTTOM) Then Begin
  If MsX<20 Then Dec(ZoomPanX,30)
  Else If MsX>SCREEN_W-20 Then Inc(ZoomPanX,30)
  Else ZoomPanX:=-ZoomPanLimit+LongInt(MsX-20)*2*ZoomPanLimit div (SCREEN_W-40);
  If ZoomPanX< -ZoomPanLimit Then ZoomPanX:=-ZoomPanLimit;
  If ZoomPanX>ZoomPanLimit Then ZoomPanX:=ZoomPanLimit;
  NeedsRedraw:=True;Exit;
 End;
 RightDown    := (MsBtn And MB_RIGHT) <> 0;

 If RibbonMode Then Begin
  Itm:=RibbonHitAt(MsX,MsY);
  If Itm<>RibbonHover Then Begin RibbonHover:=Itm;NeedsRedraw:=True;End;
  If LeftPressed Then Begin
   RibbonKeyboard:=False;RibbonFocus:=0;RibbonPressed:=0;NeedsRedraw:=True;
   M:=MenuAtPoint(MsX,MsY);
   If M>0 Then Begin RibbonTab:=M;RibbonHover:=0;ActiveMenu:=0;End
   Else If (Itm>0) And RibbonEntryEnabled(Itm) Then RibbonPressed:=Itm;
  End;
  If LeftReleased And (RibbonPressed>0) Then Begin
   B:=RibbonPressed;RibbonPressed:=0;If Itm=B Then ExecuteRibbonEntry(B);
  End;
  If MsY<STDBAR_TOP Then Begin
   HoveredStdBtn:=0;HoveredFmtBtn:=0;
   If LeftReleased And MouseSelecting Then Begin
    MouseSelecting:=False;If Not SelHasRange Then SelClear;NeedsRedraw:=True;
   End;
   Exit;
  End;
 End;

 { Survol toolbars }
 HoveredStdBtn := StdBtnAtPoint(MsX, MsY);
 HoveredFmtBtn := FmtBtnAtPoint(MsX, MsY);

 { Survol barre de menus : si un menu est deja ouvert et la souris
   passe au-dessus d'un AUTRE menu de la barre, on bascule. }
 If ActiveMenu > 0 Then Begin
  M := MenuAtPoint(MsX, MsY);
  If (M > 0) And (M <> ActiveMenu) Then Begin
   ActiveMenu := M;
   MenuItemHover := 1;
   MenuKeyboardMode := False;
  End;
 End;

 { Survol dropdown menu actif : la souris choisit l'item courant. }
 If ActiveMenu > 0 Then Begin
  Itm := DropItemAtPoint(MsX, MsY);
  If (Itm > 0) And (Not Menus[ActiveMenu].Items[Itm].Separator) Then Begin
   MenuItemHover := Itm;
   MenuKeyboardMode := False;
  End;
 End;

 { ----- Click gauche ----- }
 If LeftPressed Then Begin
  M := MenuAtPoint(MsX, MsY);
  If M > 0 Then Begin
   If ActiveMenu = M Then ActiveMenu := 0
   Else Begin
    ActiveMenu := M; MenuItemHover := 1;
    MenuKeyboardMode := False;
   End;
  End Else If ActiveMenu > 0 Then Begin
   { Clic dans dropdown ou ailleurs }
   Itm := DropItemAtPoint(MsX, MsY);
   If (Itm > 0) And
      (Not Menus[ActiveMenu].Items[Itm].Separator) Then Begin
    B := Menus[ActiveMenu].Items[Itm].ActionId;
    ActiveMenu := 0; MenuItemHover := 0;
    ExecAction(B);
   End Else
    ActiveMenu := 0;
  End Else If HoveredStdBtn > 0 Then Begin
   { rien : on agit au release pour effet bouton enfonc?? visuel }
  End Else If HoveredFmtBtn > 0 Then Begin
   { idem }
  End Else If PointInDocArea(MsX, MsY) Then Begin
   { Clic dans la zone document : positionne le curseur et amorce
     une selection. Drag etend la selection. }
   If MouseToDocPos(MsX, MsY, NewP, NewC) Then Begin
    Cursor.ParaIdx := NewP;
    Cursor.RunIdx  := 1;
    Cursor.CharIdx := NewC;
    SelStartFromCursor;
    MouseSelecting := True;
    CursorBlinkOn  := True;
    CursorBlinkCnt := 0;
    NeedsRedraw    := True;
   End;
  End;
 End;

 { ----- Drag gauche : extension de la selection ----- }
 If LeftDown And MouseSelecting And (Not LeftPressed) Then Begin
  If MouseToDocPos(MsX, MsY, NewP, NewC) Then Begin
   If (NewP <> Cursor.ParaIdx) Or (NewC <> Cursor.CharIdx) Then Begin
    Cursor.ParaIdx := NewP;
    Cursor.RunIdx  := 1;
    Cursor.CharIdx := NewC;
    CursorBlinkOn  := True;
    CursorBlinkCnt := 0;
    NeedsRedraw    := True;
   End;
  End;
 End;

 { ----- Release gauche ----- }
 If LeftReleased Then Begin
  If MouseSelecting Then Begin
   MouseSelecting := False;
   { Selection vide => on efface l'etat selection (juste un clic). }
   If Not SelHasRange Then SelClear;
  End;
  If (ActiveMenu = 0) And (HoveredStdBtn > 0) Then
   If Not RibbonMode Or RibbonActionEnabled(StdBar[HoveredStdBtn].ActionId) Then
    ExecAction(StdBar[HoveredStdBtn].ActionId);
  If (ActiveMenu = 0) And (HoveredFmtBtn > 0) Then
   ExecAction(FmtBar[HoveredFmtBtn].ActionId);
 End;

 { ----- Click droit ----- }
 If RightDown And ((LastMsBtn And MB_RIGHT) = 0) Then Begin
  If ActiveMenu > 0 Then ActiveMenu := 0;
  If PointInDocArea(MsX, MsY) Then Begin
   If MouseToDocPos(MsX, MsY, NewP, NewC) Then Begin
    If ParaIsTable(NewP) Then Begin
     { MouseToDocPos a positionne le curseur dans la cellule.
       Recuperer la cellule courante et afficher le menu. }
     Begin
      ShowTableContextMenu(MsX, MsY, NewP,
       ((Cursor.RunIdx - 1) Div Tables[Doc^.Paragraphs[NewP].TableIdx].Cols) + 1,
       ((Cursor.RunIdx - 1) Mod Tables[Doc^.Paragraphs[NewP].TableIdx].Cols) +
         1);
     End;
    End Else
     StatusMsg := Tr('Menu contextuel : clic droit sur un tableau');
   End;
  End Else
   StatusMsg := '';
 End;
End;

{ ============================================================ }
{ =====================  RENDU COMPLET  ====================== }
{ ============================================================ }

Procedure RenderAll;
Begin
 EraseSoftCursor;
 SetViewPort(0, 0, SCREEN_W-1, SCREEN_H-1, ClipOn);

 DrawDocArea;
 DrawZoomPan;
 DrawRuler;
 If RibbonMode Then DrawRibbon
 Else Begin DrawStdToolbar;DrawFmtToolbar;End;
 DrawMenuBar;
 If ActiveMenu > 0 Then DrawMenuDropdown;
 DrawStatusBar;

  DrawSoftCursor(MsX, MsY); 
End;

{ ============================================================ }
{ =====================  BOUCLE PRINCIPALE  ================== }
{ ============================================================ }

{ ====================================================================== }
{  OS/2-0 : barre de menus de PM construite a partir des menus de WorDium }
{ ====================================================================== }
{ Menus classiques : les menus deroulants que dessine WorDium (Menus[],   }
{ InitMenus) deviennent la barre de menus de PM : memes titres, memes     }
{ elements et lettres soulignees (& devient ~), raccourcis affiches a     }
{ droite, elements coches (Affichage) ; une commande de PM appelle        }
{ ExecAction. Ruban (/RUBANMENU) : les titres de la barre de menus de PM  }
{ sont les onglets du ruban (une commande choisit l'onglet). Si un titre  }
{ ou un element change, la barre est reconstruite.                       }

Function OsMenuSignature : LongInt;
Var I, J, K, H : LongInt;
Begin
 H := 7 + Ord(RibbonMode);
 For I := 1 To MenuCount Do
 Begin
  For K := 1 To Length(Menus[I].Caption) Do H := (H * 31 + Ord(Menus[I].Caption[K])) And $7FFFFFF;
  H := (H * 31 + Menus[I].ItemCount) And $7FFFFFF;
  For J := 1 To Menus[I].ItemCount Do
  Begin
   For K := 1 To Length(Menus[I].Items[J].Caption) Do
    H := (H * 31 + Ord(Menus[I].Items[J].Caption[K])) And $7FFFFFF;
   H := (H * 31 + Ord(Menus[I].Items[J].Enabled)) And $7FFFFFF;
  End;
 End;
 OsMenuSignature := H;
End;

{ texte d'un menu de WorDium -> texte de PM : &x devient ~x }
Function OsMnText(S : String) : String;
Var K : LongInt; R : String;
Begin
 R := ''; K := 1;
 While K <= Length(S) Do
 Begin
  If (S[K] = '&') And (K < Length(S)) Then
  Begin
   If S[K + 1] = '&' Then R := R + '&' Else R := R + '~' + S[K + 1];
   Inc(K, 2);
  End
  Else
  Begin
   If S[K] = '~' Then R := R + '~~' Else R := R + S[K];
   Inc(K);
  End;
 End;
 OsMnText := R;
End;

Function OsItemAttr(I, J : LongInt) : LongInt;
Var Attr : LongInt;
Begin
 Attr := 0;
 If Not Menus[I].Items[J].Enabled Then Attr := Attr Or MIA_DISABLED;
 If ViewActionChecked(Menus[I].Items[J].ActionId) Then Attr := Attr Or MIA_CHECKED;
 OsItemAttr := Attr;
End;

Procedure OsSyncMenu;
Var I, J, H0, H1, M : LongInt; S : String;
Begin
 If OsFrame = 0 Then Exit;
 If OsMenuSignature = OsMenuSig Then Exit;
 OsMenuSig := OsMenuSignature;
 OsMenuLen := 0;
 H0 := OsMnOpen;
 For I := 1 To MenuCount Do
 Begin
  If RibbonMode Then
   OsMnItem(MIS_TEXT, 0, OS_MENUID + I * 32 + 31, OsMnText(Menus[I].Caption))
  Else
  Begin
   OsMnItem(MIS_TEXT Or MIS_SUBMENU, 0, OS_MENUID - 100 - I, OsMnText(Menus[I].Caption));
   H1 := OsMnOpen;
   For J := 1 To Menus[I].ItemCount Do
   Begin
    If Menus[I].Items[J].Separator Then OsMnItem(MIS_SEPARATOR, 0, 0, '')
    Else
    Begin
     S := OsMnText(Menus[I].Items[J].Caption);
     If Menus[I].Items[J].Shortcut <> '' Then S := S + Chr(9) + Menus[I].Items[J].Shortcut;
     OsMnItem(MIS_TEXT, OsItemAttr(I, J), OS_MENUID + I * 32 + J, S);
    End;
   End;
   OsMnClose(H1, Menus[I].ItemCount);
  End;
 End;
 OsMnClose(H0, MenuCount);
 M := WinCreateMenu(OsFrame, LongInt(@OsMenuT));
 OsDummy := WinSendMsg(OsFrame, $0042, $FFFF, 0);      { WM_UPDATEFRAME : FCF_MENU }
End;

{ a l'ouverture d'un menu : elements actifs ou grises, coches }
Procedure OsMenuInit;
Var I, J, M, Id : LongInt;
Begin
 If RibbonMode Then Exit;
 M := WinWindowFromID(OsFrame, $8005);
 If M = 0 Then Exit;
 For I := 1 To MenuCount Do
  For J := 1 To Menus[I].ItemCount Do
   If Not Menus[I].Items[J].Separator Then
   Begin
    Id := (OS_MENUID + I * 32 + J) Or $10000;
    OsDummy := WinSendMsg(M, MM_SETITEMATTR, Id, (MIA_DISABLED Or MIA_CHECKED) Or (OsItemAttr(I, J) Shl 16));
   End;
End;

{ commandes de la barre de menus de PM : depuis la boucle de WorDium }
Procedure OsDispatchCommands;
Var Id, I, J : LongInt;
Begin
 While OsCHead <> OsCTail Do
 Begin
  Id := OsCmds[OsCHead];
  OsCHead := (OsCHead + 1) Mod OsCmdMax;
  ActiveMenu := 0; MenuItemHover := 0; MenuKeyboardMode := False;
  If Id = OS_CMD_QUIT Then
  Begin
   ExecAction(ACT_FILE_EXIT);
   NeedsRedraw := True;
  End
  Else
  Begin
   I := Id Div 32; J := Id Mod 32;
   If (I >= 1) And (I <= MenuCount) Then
   Begin
    If J = 31 Then
    Begin
     { onglet du ruban }
     RibbonTab := I; RibbonKeyboard := True; RibbonFocus := 0; RibbonPressed := 0;
     NeedsRedraw := True;
    End
    Else If (J >= 1) And (J <= Menus[I].ItemCount) Then
     If Menus[I].Items[J].Enabled And Not Menus[I].Items[J].Separator Then
     Begin
      ExecAction(Menus[I].Items[J].ActionId);
      NeedsRedraw := True;
     End;
   End;
  End;
 End;
End;

Procedure MainLoop;
Var
 K              : Word;
 RedrawAfter    : Boolean;
 MouseOnly      : Boolean;
 CursorOnly     : Boolean;
 PrevMx,PrevMy  : LongInt;
 PrevActiveMenu : Integer;
 PrevMenuHover  : Integer;
 PrevHovStd     : Integer;
 PrevHovFmt     : Integer;
Begin
 AppShouldExit := False;
 ActiveMenu    := 0;
 MenuItemHover := 0;
 HoveredStdBtn := 0;
 HoveredFmtBtn := 0;
 MsBtn      := 0;
 LastMsBtn  := 0;
 MsX        := SCREEN_W Div 2;
 MsY        := SCREEN_H Div 2;
 PrevMx        := -1;
 PrevMy        := -1;
 PrevActiveMenu := 0;
 PrevMenuHover  := 0;
 PrevHovStd     := 0;
 PrevHovFmt     := 0;
 CursorBlinkOn := True;
 CursorBlinkCnt:= 0;
 Sel.Active     := False;
 MouseSelecting := False;
 StatusMsg     := Tr('Pret. F10=menu, fleches=naviguer, Alt+X=quitter.');

 LayoutDocument;
 RenderAll;

 While Not AppShouldExit Do Begin
  RedrawAfter := False;
  MouseOnly   := False;
  CursorOnly  := False;

  If KeyPressed Then Begin
   K := ReadKeyEx;
   HandleKey(K);
   If NeedsRelayout Then Begin
    LayoutDocument;
   End;
   { Toujours s'assurer que le curseur reste visible (defile la page si besoin).
     }
   EnsureCursorVisible;
   { Reset blink ON pendant la frappe : caret toujours visible }
   CursorBlinkOn := True;
   CursorBlinkCnt := 0;
   RedrawAfter := True;
  End;

  OsDispatchCommands;
  HandleMouse;
  If MsBtn <> LastMsBtn Then RedrawAfter := True
  Else If (MsX <> PrevMx) Or (MsY <> PrevMy) Then MouseOnly := True;

  { Tout changement d'etat de menu/toolbar du au survol force un RenderAll. }
  If (ActiveMenu <> PrevActiveMenu) Or (MenuItemHover <> PrevMenuHover) Or
     (HoveredStdBtn <> PrevHovStd) Or (HoveredFmtBtn <> PrevHovFmt) Then Begin
   RedrawAfter := True;
   MouseOnly   := False;
  End;

  If NeedsRedraw Then Begin RedrawAfter := True; NeedsRedraw := False; End;
  If NeedsRelayout Then Begin
   LayoutDocument;
   EnsureCursorVisible;
   RedrawAfter := True;
  End;

  { Clignotement curseur texte : XOR-toggle si rien d'autre a redessiner }
  Inc(CursorBlinkCnt);
  If CursorBlinkCnt >= CURSOR_BLINK_TICKS Then Begin
   CursorBlinkCnt := 0;
   CursorBlinkOn := Not CursorBlinkOn;
   If Not RedrawAfter Then CursorOnly := True;
  End;

  If RedrawAfter Then Begin
   RenderAll;
   PrevMx := MsX;
   PrevMy := MsY;
   PrevActiveMenu := ActiveMenu;
   PrevMenuHover  := MenuItemHover;
   PrevHovStd     := HoveredStdBtn;
   PrevHovFmt     := HoveredFmtBtn;
  End Else If MouseOnly Then Begin
   
   EraseSoftCursor;
   DrawSoftCursor(MsX, MsY);
   
   PrevMx := MsX;
   PrevMy := MsY;
  End Else If CursorOnly Then Begin
   ToggleTextCursor;
  End;

  Delay(20);
 End;
End;

{ ============================================================ }
{ =====================  PROGRAMME PRINCIPAL  ================ }
{ ============================================================ }

Function CommandLineHelpRequested: Boolean;
Var I,J: Integer;Arg: String;
Begin
 CommandLineHelpRequested:=False;
 For I:=1 To ParamCount Do Begin
  Arg:=ParamStr(I);For J:=1 To Length(Arg) Do Arg[J]:=UpCase(Arg[J]);
  If (Arg='/?') Or (Arg='-H') Or (Arg='--HELP') Then Begin
    CommandLineHelpRequested:=True;Exit;End;
 End;
End;
Procedure ShowCommandLineHelp;
Var OutputHelp: Text;
Begin
 Assign(OutputHelp,'');Rewrite(OutputHelp);
 WriteLn(OutputHelp,Tr('WorDium - Traitement de texte graphique en Pascal.'));
 WriteLn(
   OutputHelp,
     Tr('Utilisation : WorDium [/CLASSICMENU | /RUBANMENU] [document] ['+
   '/?]'));
 WriteLn(OutputHelp);
 WriteLn(
   OutputHelp,
     Tr('  /CLASSICMENU  Menus classiques, style Word 2003 (par defaut'+
   ').'));
 WriteLn(
   OutputHelp,
     Tr('  /RUBANMENU    Onglets et commandes avec icones, style Word 2'+
   '007 et suivants.'));
 WriteLn(
   OutputHelp,
     Tr('  /?           Affiche cette aide et quitte sans ouvrir de fen'+
   'etre.'));
 WriteLn(OutputHelp,Tr('  -h, --help   Affichent egalement cette aide.'));
 WriteLn(OutputHelp,Tr('  document     Fichier a ouvrir au demarrage.'));
 WriteLn(OutputHelp);
 WriteLn(
   OutputHelp,
     Tr('Les options sont insensibles a la casse ; le dernier mode spec'+
   'ifie est utilise.'));
 WriteLn(OutputHelp,
   Tr('Le document peut etre place avant ou apres les options.'));
 WriteLn(
   OutputHelp,Tr('Entourer les chemins contenant des espaces de guillemets.'));
 WriteLn(
   OutputHelp,Tr('Exemple : WorDium /RUBANMENU "C:\Documents\Mon texte.docx"'));
 WriteLn(
   OutputHelp,
     Tr('Ruban : souris, F10 ou Alt+lettre, fleches, Tab/Maj+Tab, Entre'+
   'e et Echap.'));
 WriteLn(
   OutputHelp,
     Tr('Accueil : Alt+E. Les commandes non implementees sont grisees.'));
 WriteLn(
   OutputHelp,
     Tr('Ctrl+N Nouveau, Ctrl+O Ouvrir, Ctrl+S Enregistrer, Alt+X Quitt'+
   'er.'));
 Close(OutputHelp);
End;
Procedure ParseCommandLine;
Var I,J: Integer;Arg,U: String;
Begin
 RibbonMode:=False;RibbonTab:=2;RibbonFocus:=0;RibbonHover:=0;RibbonPressed:=0;
 RibbonKeyboard:=False;RibbonInk:=-1;CommandLineFile:='';
 For I:=1 To ParamCount Do Begin
  Arg:=ParamStr(I);U:=Arg;For J:=1 To Length(U) Do U[J]:=UpCase(U[J]);
  If U='/CLASSICMENU' Then RibbonMode:=False
  Else If U='/RUBANMENU' Then RibbonMode:=True
  Else Begin
   If CommandLineFile<>'' Then CommandLineFile:=CommandLineFile+' ';
   CommandLineFile:=CommandLineFile+Arg;
  End;
 End;
 STDBAR_TOP:=CLASSIC_STDBAR_TOP;FMTBAR_TOP:=CLASSIC_FMTBAR_TOP;
 RULER_TOP:=CLASSIC_RULER_TOP;DOCAREA_TOP:=CLASSIC_DOCAREA_TOP;
 If RibbonMode Then Begin
   STDBAR_TOP:=108;FMTBAR_TOP:=108;RULER_TOP:=108;DOCAREA_TOP:=123;End;
 UpdateViewGeometry;
End;

BEGIN
 If DosAllocMem(LongInt(@Doc), SizeOf(TDocument), $13) <> 0 Then Halt(8);
 FillChar(Doc^, SizeOf(TDocument), 0);
 InitLanguage;
 If CommandLineHelpRequested Then Begin ShowCommandLineHelp;Halt(0);End;
 ParseCommandLine;
 InitializeGraphics;
 InitMenus;
 InitToolbars;
 InitDocument;
 UndoCount := 0; RedoCount := 0; LastMutate := 0;
 LastFindStr := ''; LastReplStr := '';
 { Argument ligne de commande : nom de fichier a ouvrir au demarrage. }
 If CommandLineFile<>'' Then Begin
  If LoadAnyDocument(CommandLineFile) Then Begin
   If Not ExtIsPDF(CommandLineFile) Then Doc^.FileName := CommandLineFile;
  End
  Else
   ShowMessage(Tr('Cannot open file: ') + CommandLineFile);
 End;
 MsAvailable := MouseDriverFound;
 If MsAvailable Then ShowMouse;
 MainLoop;
 If MsAvailable Then HideMouse;
 CloseGraph;
END.

