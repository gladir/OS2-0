{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Excelsior, tableur graphique, pour le Presentation
                Manager d'OS/2-0 (dossier Productivite du bureau).
}

Program EXCEL;

{$R-,S-}
{$M 2097152}      { pile de 2 Mo : evaluation recursive des formules }

{ Compilation : OS2PC EXCELSIO.PAS   (produit EXCELSIO.EXE)

  Portage vers OS/2-0 d'EXCEL.PAS du depot OFFICE-0 (Turbo Pascal 7, Free
  Pascal : BGI 640 x 480 en 16 couleurs, souris de l'interruption 33h ou
  de PtcMouse). Toutes les fonctions de la version DOS sont conservees :
  16 feuilles de 4096 lignes sur 256 colonnes (A a IV), saisie, formules
  (SOMME, MOYENNE, MIN, MAX, NB, SI, ARRONDI... references relatives et
  absolues, plages, autres feuilles), recalcul, selection, copier, couper,
  coller, annuler et retablir, mise en forme des cellules (gras,
  italique, souligne, alignements, formats de nombres, couleurs),
  largeurs des colonnes et hauteurs des lignes, insertion et suppression
  de lignes, de colonnes et de feuilles, tri, rechercher, images (BMP),
  graphiques (histogrammes, barres, courbes, secteurs, aires, nuages de
  points), menus classiques ou ruban (/RUBANMENU), menus contextuels ;
  formats .XLC (natif), .XLS (Excel 97 a 2003, lecture et ecriture) et
  .XLSX (lecture et ecriture).

  Ce qui change pour OS/2 :
  - fenetre de Presentation Manager : barre de titre, menu systeme,
    barre de menus d'OS/2 construite a partir des menus d'Excelsior
    (memes commandes, lettres soulignees, raccourcis ; les commandes que
    la version DOS n'a pas sont grisees) ; avec le ruban, les titres de
    la barre de menus de PM sont les onglets ;
  - le dessin de la BGI va dans une image de 640 x 480 en memoire,
    montree dans la zone client par GpiDrawBits (zones modifiees
    seulement) ; le pointeur de la souris est celui de PM ;
  - boites de dialogue dans le style d'OS/2 (barre de titre bleue avec la
    case du menu systeme, titre centre) ; messages et confirmations par
    WinMessageBox ;
  - la boucle principale rend la main a OS/2 quand il n'y a rien a faire.
}


{ ====================================================================== }
{  OS/2-0 : Excelsior dans une fenetre de Presentation Manager            }
{ ====================================================================== }
{ La version DOS d'Excelsior dessine par la BGI (Graph / PtcGraph) et lit }
{ le clavier (Crt) et la souris (interruption 33h / PtcMouse). Ici ces    }
{ unites sont remplacees par une couche qui utilise l'API d'OS/2 :        }
{  - l'image de 640 x 480 (16 couleurs de la BGI, palette 256) est gardee }
{    en memoire (DosAllocMem) et montree par GpiDrawBits, zones modifiees }
{    seulement ; la rangee de la barre de menus d'Excelsior (18 lignes   }
{    en haut) n'est pas montree : c'est la barre de menus de PM qui la    }
{    remplace (zone client de 640 x 462) ;                                }
{  - la barre de menus de PM est construite a partir des menus           }
{    d'Excelsior (MenuItemLabel) ; une commande appelle ExecuteMenuItem ; }
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
 PointType = Record
  X, Y: Integer;
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
 OsOY : LongInt;                           { lignes du haut cachees (barre de menus d'Excelsior)}
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
  If (K < 0) And ((Fl And KC_CHAR) <> 0) And ((Fl And KC_ALT) = 0) And (Ch > 0) And (Ch < 256) Then
 Begin
  K := Ch;
  If ((Fl And KC_CTRL) <> 0) And (UpCase(Chr(Ch)) >= 'A') And (UpCase(Chr(Ch)) <= 'Z') Then
   K := Ord(UpCase(Chr(Ch))) - 64;
 End;
 If (K < 0) And ((Fl And KC_CTRL) <> 0) And ((Fl And KC_ALT) = 0) And (Ch > 0) And (Ch < 256) Then
  If (UpCase(Chr(Ch)) >= 'A') And (UpCase(Chr(Ch)) <= 'Z') Then K := Ord(UpCase(Chr(Ch))) - 64;
 { Alt+Q : Quitter (aucun menu de PM n'a la lettre Q ; les autres
   Alt+lettre ouvrent les menus de la barre de menus de PM) }
 If (K < 0) And ((Fl And KC_ALT) <> 0) And ((Fl And KC_CTRL) = 0) And (UpCase(Chr(Ch And 255)) = 'Q') Then
  K := 256 + 16;
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

{ ShowMouse et HideMouse : ceux d'Excelsior (vides pour Free Pascal) }

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


{ polygone plein (couleur de remplissage) puis son contour (couleur courante) }
Procedure FillPoly(NumPoints : Word; Var PolyPoints);
Type TPts = Array[1..64] Of PointType;
Var P : ^TPts; I, J, Y, Y1, Y2, K, Cnt, T, Xa, Ya, Xb, Yb, C : LongInt; Xs : Array[0..63] Of LongInt;
Begin
 P := @PolyPoints;
 If (NumPoints < 2) Or (NumPoints > 64) Then Exit;
 If PdwFillStyle = EmptyFill Then C := 0 Else C := PdwFillColor;
 Y1 := P^[1].Y; Y2 := P^[1].Y;
 For I := 2 To NumPoints Do
 Begin
  If P^[I].Y < Y1 Then Y1 := P^[I].Y;
  If P^[I].Y > Y2 Then Y2 := P^[I].Y;
 End;
 For Y := Y1 To Y2 Do
 Begin
  Cnt := 0;
  For I := 1 To NumPoints Do
  Begin
   J := I + 1;
   If J > NumPoints Then J := 1;
   Xa := P^[I].X; Ya := P^[I].Y; Xb := P^[J].X; Yb := P^[J].Y;
   If ((Ya <= Y) And (Yb > Y)) Or ((Yb <= Y) And (Ya > Y)) Then
    If Cnt < 64 Then
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
   PdwHLine(Xs[I] + PdwVP.X1, Xs[I + 1] + PdwVP.X1, Y + PdwVP.Y1, C);
   I := I + 2;
  End;
 End;
 For I := 1 To NumPoints Do
 Begin
  J := I + 1;
  If J > NumPoints Then J := 1;
  Line(P^[I].X, P^[I].Y, P^[J].X, P^[J].Y);
 End;
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

{ ---- mode graphique : la fenetre d'Excelsior ---- }
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
 OsDummy := WinRegisterClass(OsHab, OsZs('EXCELSIOR'), LongInt(@OsClientProc), 0, 0);
 { Excelsior est dessine pour 640 x 480, sa barre de menus comprise : la
   barre de menus de PM la remplace (zone client de 640 x 462). La
   fenetre a un cadre si le bureau a au moins 800 x 600 ; sur un bureau
   plus petit, elle n'a que la barre de menus de PM, en haut de l'ecran }
 Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
 OsSmall := (Sh < 540) Or (Sw < 660);
 If OsSmall Then Fl := FCF_TASKLIST
 Else Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_TASKLIST Or FCF_DLGBORDER;
 OsClient := 0;
 PdwTitle := 'Excelsior'#0;
 OsFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), OsZs('EXCELSIOR'), OsZs2('Excelsior'),
                               0, 0, 0, LongInt(@OsClient));
 If OsFrame = 0 Then Begin PdwResult := -1; Exit End;
 { barre de menus provisoire (pour la taille de la zone client) }
 OsMenuLen := 0;
 H0 := OsMnOpen;
 OsMnItem(MIS_TEXT, 0, OS_MENUID - 1, '~Fichier');
 OsMnClose(H0, 1);
 OsDummy := WinCreateMenu(OsFrame, LongInt(@OsMenuT));
 OsMenuSig := -1;
 { zone client : 640 x 462 (les 18 lignes de la barre de menus
   d'Excelsior sont cachees) ; sur un petit bureau, ce qui reste sous la
   barre de menus de PM (le haut de la barre d'outils est alors cache) }
 Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
 Rc[0] := 0; Rc[1] := 0; Rc[2] := Sw; Rc[3] := Sh;
 OsDummy := WinCalcFrameRect(OsFrame, LongInt(@Rc), 1);
 PdwW := 640; PdwH := Rc[3] - Rc[1];
 If (PdwH > 462) Or (PdwH < 400) Then PdwH := 462;
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



{ ====================================================================== }
{                       CONSTANTES (Phase 1)                             }
{ ====================================================================== }

Const
 SCR_W           = 640;
 SCR_H           = 480;

 MAX_SHEETS      = 16;
 MAX_COLS        = 256;        { A .. IV }
 MAX_ROWS        = 4096;
 MAX_TAB_NAME    = 31;
 MAX_CELL_TEXT   = 63;
 MAX_FORMULA     = 250;

 { Hauteurs des bandeaux fixes }
 MENUBAR_H       = 18;
 CLASSIC_TOOLBAR_H = 26;
 RIBBON_H         = 110;
 FORMULABAR_H    = 20;
 COLHEADER_H     = 16;
 TABS_H          = 20;
 STATUSBAR_H     = 16;

 ROWHEADER_W     = 34;

 GRID_BOTTOM     = SCR_H - TABS_H - STATUSBAR_H - 1;
 GRID_LEFT       = ROWHEADER_W;
 GRID_RIGHT      = SCR_W - 1;

 DEFAULT_COL_W   = 56;
 DEFAULT_ROW_H   = 14;

 { Couleurs (palette VGA 16) }
 CLR_WIN_BG      = 7;          { LightGray }
 CLR_WIN_LIGHT   = 15;         { White }
 CLR_WIN_DARK    = 8;          { DarkGray }
 CLR_TEXT        = 0;          { Black }
 CLR_GRID        = 8;
 CLR_HEADER_BG   = 7;
 CLR_HEADER_SEL  = 1;          { Blue }
 CLR_SEL_BORDER  = 1;
 CLR_SEL_FILL    = 11;         { LightCyan }
 CLR_TAB_BG      = 7;
 CLR_TAB_ACTIVE  = 15;
 CLR_TOOL_HOT    = 11;
 CLR_ERR         = 4;          { Red }

 { Styles }
 STY_BOLD        = 1;
 STY_ITALIC      = 2;
 STY_UNDERLINE   = 4;

 { Alignement }
 AL_DEFAULT      = 0;
 AL_LEFT         = 1;
 AL_CENTER       = 2;
 AL_RIGHT        = 3;

 { Format numerique }
 FMT_GENERAL     = 0;
 FMT_NUMBER      = 1;          { 0.00 }
 FMT_PERCENT     = 2;
 FMT_CURRENCY    = 3;
 FMT_DATE        = 4;
 FMT_TEXT        = 5;

 { Codes touches speciales (apres ReadKey #0) }
 K_UP            = #72;
 K_DOWN          = #80;
 K_LEFT          = #75;
 K_RIGHT         = #77;
 K_HOME          = #71;
 K_END           = #79;
 K_PGUP          = #73;
 K_PGDN          = #81;
 K_INS           = #82;
 K_DEL           = #83;
 K_F1            = #59;
 K_F2            = #60;
 K_F8            = #66;
 K_F9            = #67;
 K_F10           = #68;
 K_CTRL_LEFT     = #115;
 K_CTRL_RIGHT    = #116;
 K_CTRL_HOME     = #119;
 K_CTRL_END      = #117;
 K_CTRL_PGUP     = #132;
 K_CTRL_PGDN     = #118;
 K_ALT_F         = #33;
 K_ALT_E         = #18;
 K_ALT_A         = #30;
 K_ALT_I         = #23;
 K_ALT_O         = #24;
 K_ALT_T         = #20;
 K_ALT_D         = #32;
 K_ALT_W         = #17;
 K_ALT_Q         = #16;

{ ====================================================================== }
{                              TYPES                                     }
{ ====================================================================== }

Type
 TCellKind = (ckEmpty, ckText, ckNumber, ckFormula);
 PString250 = ^String;

 TCell = Record
  Kind     : TCellKind;
  Text     : String[MAX_CELL_TEXT]; { texte affiche / saisi }
  Num      : Double;                 { valeur numerique }
  Formula  : PString250;             { formule allouee (= ...)  Nil sinon }
  Style    : Byte;                   { bits STY_* }
  Align    : Byte;                   { AL_* }
  Format   : Byte;                   { FMT_* }
  Fg, Bg   : Byte;                   { 0 = defaut }
 End;

 PRow = ^TRow;
 TRow = Packed Array[0..MAX_COLS-1] Of TCell;

 PSheet = ^TSheet;
 TSheet = Record
  Name       : String[MAX_TAB_NAME];
  Rows       : Array[0..MAX_ROWS-1] Of PRow;  { ligne allouee a la demande }
  ColW       : Array[0..MAX_COLS-1] Of Byte;
  RowH       : Array[0..MAX_ROWS-1] Of Byte;
  ScrollRow  : Integer;
  ScrollCol  : Integer;
  CurRow     : Integer;
  CurCol     : Integer;
  SelR1, SelC1, SelR2, SelC2 : Integer; { selection rectangle (R1<=R2) }
 End;

 TWorkbook = Record
  Sheets     : Array[1..MAX_SHEETS] Of PSheet;
  Count      : Integer;
  Active     : Integer;
  FileName   : String;
  Modified   : Boolean;
 End;

 { Souris a 8 boutons : on s'en tient a 1 (gauche) et 2 (droit) }
 TMouseState = Record
  X, Y, B   : LongInt;
  Visible   : Boolean;
 End;

{ ====================================================================== }
{                              VARIABLES                                 }
{ ====================================================================== }

Var
 WB          : TWorkbook;
 Mouse       : TMouseState;
 LastClickB  : LongInt;       { etat precedent du bouton (edge detection) }
 NeedFullRedraw : Boolean;
 RibbonMode, RibbonKeyboard: Boolean;
 RibbonTab, RibbonFocus, RibbonHover: Integer;
 TOOLBAR_H, GRID_TOP: Integer; { Geometrie choisie au demarrage }
 CmdFN       : String;        { fichier passe en ligne de commande }
 CmdOK       : Boolean;
 CmdShort    : String;
 CmdF        : File;
 XlsxErr     : Integer;       { code de diagnostic XLSX }

 { Etat de menu deroulant }
 MenuOpen    : Integer;       { 0 = aucun, sinon 1..N }
 MenuItemHi  : Integer;

 { Largeur cumulee des en-tetes (cache) }
 SheetTabsX1 : Array[1..MAX_SHEETS] Of Integer;
 SheetTabsX2 : Array[1..MAX_SHEETS] Of Integer;

 { Buffer pour saisie cellule (Phase 1 : entree directe simple) }
 InputBuf    : String;
 InputMode   : Boolean;
 InputBufPos : Integer;

{ ====================================================================== }
{           PHASE 2 : SELECTION, PRESSE-PAPIER, ANNULER/RETABLIR         }
{ ====================================================================== }

Const
 CLIP_MAX_CELLS = 4096;
 UNDO_DEPTH     = 30;

Type
 TClipCell = Record
  Kind     : TCellKind;
  Text     : String[MAX_CELL_TEXT];
  Num      : Double;
  Formula  : PString250;          { dup heap, Nil sinon }
  Style    : Byte;
  Align    : Byte;
  Format   : Byte;
  Fg, Bg   : Byte;
 End;

 TClipboard = Record
  Valid    : Boolean;
  Rows     : Integer;
  Cols     : Integer;
  Cells    : Array[0..CLIP_MAX_CELLS - 1] Of TClipCell;
  CutMode  : Boolean;
  CutR     : Integer;
  CutC     : Integer;
  CutSheet : Integer;
 End;

 PUndoCell = ^TUndoCell;
 TUndoCell = Record
  Sheet    : Integer;
  R, C     : Integer;
  Kind     : TCellKind;
  Text     : String[MAX_CELL_TEXT];
  Num      : Double;
  Formula  : PString250;
  Style    : Byte;
  Align    : Byte;
  Format   : Byte;
  Fg, Bg   : Byte;
  Next     : PUndoCell;
 End;

 TUndoOp = Record
  Used     : Boolean;
  Head     : PUndoCell;
  Desc     : String[31];
 End;

Var
 Clip          : TClipboard;
 UndoStack     : Array[1..UNDO_DEPTH] Of TUndoOp;
 RedoStack     : Array[1..UNDO_DEPTH] Of TUndoOp;
 UndoTop       : Integer;
 RedoTop       : Integer;
 CurUndoHead   : PUndoCell;
 InUndoOp      : Boolean;

 ExtendMode    : Boolean;
 SelAnchorR    : Integer;
 SelAnchorC    : Integer;

 Dragging      : Boolean;
 DragStartR    : Integer;
 DragStartC    : Integer;

 { Marching ants - compteur pour animation (phase 2 minimal : statique) }
 CutMarchingFrame : Integer;

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
  WriteLn('Erreur graphique : ',GraphErrorMsg(ErrCode));
  Halt;
 End;
End;


 Function MouseDriverFound: Boolean;
 Begin
  MouseDriverFound := True;
 End;

 Procedure ShowMouse;
 Begin
  { Pas d'implementation pour Free Pascal }
 End;

 Procedure HideMouse;
 Begin
  { Pas d'implementation pour Free Pascal }
 End;


{ ====================================================================== }
{                       UTILITAIRES GENERAUX                             }
{ ====================================================================== }

Function IntToStr(N: LongInt): String;
Var S: String;
Begin
 Str(N, S);
 IntToStr := S;
End;

Function PadL(S: String; W: Integer): String;
Begin
 While Length(S) < W Do S := ' ' + S;
 PadL := S;
End;

Function MinI(A, B: Integer): Integer;
Begin If A < B Then MinI := A Else MinI := B; End;

Function MaxI(A, B: Integer): Integer;
Begin If A > B Then MaxI := A Else MaxI := B; End;

Function ColName(C: Integer): String;
{ 0 -> A, 1 -> B, ..., 25 -> Z, 26 -> AA, ..., 255 -> IV }
Var S: String;
Begin
 S := '';
 If C >= 26 Then Begin
  S := Chr(Ord('A') + (C Div 26) - 1) + Chr(Ord('A') + (C Mod 26));
 End Else
  S := Chr(Ord('A') + C);
 ColName := S;
End;

Function CellRef(R, C: Integer): String;
Begin
 CellRef := ColName(C) + IntToStr(R + 1);
End;

Function DoubleToCellStr(V: Double): String;
Var S: String; I: Integer;
Begin
 Str(V:0:6, S);
 { Retirer zeros trainants apres le point }
 I := Length(S);
 If Pos('.', S) > 0 Then Begin
  While (I > 1) And (S[I] = '0') Do Dec(I);
  If S[I] = '.' Then Dec(I);
  S := Copy(S, 1, I);
 End;
 DoubleToCellStr := S;
End;

{ ====================================================================== }
{                       MODELE : ALLOCATION / ACCES                      }
{ ====================================================================== }

Procedure CellClear(Var Cell: TCell);
Begin
 If Cell.Formula <> Nil Then Begin
  Dispose(Cell.Formula);
  Cell.Formula := Nil;
 End;
 FillChar(Cell, SizeOf(Cell), 0);
 Cell.Kind := ckEmpty;
End;

Function GetRow(Sh: PSheet; R: Integer): PRow;
Var I: Integer;
Begin
 If (R < 0) Or (R >= MAX_ROWS) Then Begin GetRow := Nil; Exit; End;
 If Sh^.Rows[R] = Nil Then Begin
  New(Sh^.Rows[R]);
  FillChar(Sh^.Rows[R]^, SizeOf(TRow), 0);
  For I := 0 To MAX_COLS - 1 Do Sh^.Rows[R]^[I].Kind := ckEmpty;
 End;
 GetRow := Sh^.Rows[R];
End;

Function PeekRow(Sh: PSheet; R: Integer): PRow;
Begin
 If (R < 0) Or (R >= MAX_ROWS) Then PeekRow := Nil
 Else PeekRow := Sh^.Rows[R];
End;

Function GetCellRef(Sh: PSheet; R, C: Integer): TCell;
Var Row: PRow; Empty: TCell;
Begin
 FillChar(Empty, SizeOf(Empty), 0);
 Empty.Kind := ckEmpty;
 Row := PeekRow(Sh, R);
 If Row = Nil Then GetCellRef := Empty
 Else If (C < 0) Or (C >= MAX_COLS) Then GetCellRef := Empty
 Else GetCellRef := Row^[C];
End;

Procedure SetCellText(Sh: PSheet; R, C: Integer; S: String);
Var Row: PRow; Code: Integer; V: Double;
Begin
 If (R < 0) Or (R >= MAX_ROWS) Or (C < 0) Or (C >= MAX_COLS) Then Exit;
 Row := GetRow(Sh, R);
 If Row = Nil Then Exit;
 CellClear(Row^[C]);
 If Length(S) = 0 Then Exit;
 If (Length(S) > 1) And (S[1] = '=') Then Begin
  Row^[C].Kind := ckFormula;
  Row^[C].Text := '#N/A';   { evalue plus tard en Phase 4 }
  New(Row^[C].Formula);
  Row^[C].Formula^ := S;
  Exit;
 End;
 { Essai conversion numerique }
 Val(S, V, Code);
 If Code = 0 Then Begin
  Row^[C].Kind := ckNumber;
  Row^[C].Num  := V;
  Row^[C].Text := DoubleToCellStr(V);
 End Else Begin
  Row^[C].Kind := ckText;
  If Length(S) > MAX_CELL_TEXT Then S := Copy(S, 1, MAX_CELL_TEXT);
  Row^[C].Text := S;
 End;
End;

Procedure ClearCell(Sh: PSheet; R, C: Integer);
Var Row: PRow;
Begin
 Row := PeekRow(Sh, R);
 If Row = Nil Then Exit;
 If (C < 0) Or (C >= MAX_COLS) Then Exit;
 CellClear(Row^[C]);
End;

{ ====================================================================== }
{                       INITIALISATION CLASSEUR                          }
{ ====================================================================== }

Procedure InitSheet(Sh: PSheet; Const N: String);
Var I: Integer;
Begin
 FillChar(Sh^, SizeOf(TSheet), 0);
 Sh^.Name := N;
 For I := 0 To MAX_COLS - 1 Do Sh^.ColW[I] := DEFAULT_COL_W;
 For I := 0 To MAX_ROWS - 1 Do Sh^.RowH[I] := DEFAULT_ROW_H;
 Sh^.CurRow := 0;
 Sh^.CurCol := 0;
 Sh^.SelR1 := 0; Sh^.SelC1 := 0;
 Sh^.SelR2 := 0; Sh^.SelC2 := 0;
 Sh^.ScrollRow := 0;
 Sh^.ScrollCol := 0;
End;

Procedure InitWorkbook;
Var I: Integer;
Begin
 FillChar(WB, SizeOf(WB), 0);
 WB.Count := 3;
 For I := 1 To MAX_SHEETS Do WB.Sheets[I] := Nil;
 For I := 1 To WB.Count Do Begin
  New(WB.Sheets[I]);
  InitSheet(WB.Sheets[I], 'Feuil' + IntToStr(I));
 End;
 WB.Active := 1;
 WB.FileName := '';
 WB.Modified := False;
End;

Function ActiveSheet: PSheet;
Begin
 ActiveSheet := WB.Sheets[WB.Active];
End;

{ ====================================================================== }
{           PHASE 4 : MOTEUR DE FORMULES (lex + parse + eval)            }
{ ====================================================================== }

Const
 MAX_EVAL_DEPTH  = 64;
 MAX_RECALC_PASS = 12;
 ERR_DIV0  = 1;
 ERR_VALUE = 2;
 ERR_REF   = 3;
 ERR_NAME  = 4;
 ERR_CIRC  = 5;
 ERR_NUM   = 6;
 ERR_NA    = 7;

Type
 TEvalRes = Record
  IsErr   : Boolean;
  ErrCode : Byte;
  IsText  : Boolean;
  Num     : Double;
  Text    : String[80];
 End;

Var
 FSrc       : String;
 FPos       : Integer;
 FSheet     : PSheet;
 FEvalDepth : Integer;
 InRecalc   : Boolean;

Function MakeErr(C: Byte): TEvalRes;
Var R: TEvalRes;
Begin
 R.IsErr := True; R.ErrCode := C; R.IsText := False; R.Num := 0; R.Text := '';
 MakeErr := R;
End;

Function MakeNum(V: Double): TEvalRes;
Var R: TEvalRes;
Begin
 R.IsErr := False; R.ErrCode := 0; R.IsText := False; R.Num := V; R.Text := '';
 MakeNum := R;
End;

Function MakeText(Const S: String): TEvalRes;
Var R: TEvalRes;
Begin
 R.IsErr := False; R.ErrCode := 0; R.IsText := True; R.Num := 0;
 If Length(S) > 80 Then R.Text := Copy(S, 1, 80) Else R.Text := S;
 MakeText := R;
End;

Function MakeBool(B: Boolean): TEvalRes;
Begin
 If B Then MakeBool := MakeNum(1) Else MakeBool := MakeNum(0);
End;

Function ErrName(C: Byte): String;
Begin
 Case C Of
  ERR_DIV0  : ErrName := '#DIV/0!';
  ERR_VALUE : ErrName := '#VALUE!';
  ERR_REF   : ErrName := '#REF!';
  ERR_NAME  : ErrName := '#NAME?';
  ERR_CIRC  : ErrName := '#CIRC!';
  ERR_NUM   : ErrName := '#NUM!';
  ERR_NA    : ErrName := '#N/A';
  Else        ErrName := '#ERR!';
 End;
End;

Function ResAsNum(Const R: TEvalRes; Var V: Double): Boolean;
Var Code: Integer;
Begin
 If R.IsErr Then Begin ResAsNum := False; Exit; End;
 If R.IsText Then Begin
  If Length(R.Text) = 0 Then Begin V := 0; ResAsNum := True; Exit; End;
  Val(R.Text, V, Code);
  ResAsNum := Code = 0;
 End Else Begin
  V := R.Num; ResAsNum := True;
 End;
End;

Function ResAsText(Const R: TEvalRes): String;
Begin
 If R.IsErr Then ResAsText := ErrName(R.ErrCode)
 Else If R.IsText Then ResAsText := R.Text
 Else ResAsText := DoubleToCellStr(R.Num);
End;

Function UpCh(C: Char): Char;
Begin
 If (C >= 'a') And (C <= 'z') Then UpCh := Chr(Ord(C) - 32) Else UpCh := C;
End;

Function UpStr(Const S: String): String;
Var I: Integer; T: String;
Begin
 T := S;
 For I := 1 To Length(T) Do T[I] := UpCh(T[I]);
 UpStr := T;
End;

{ --- Lexer helpers --- }
Procedure SkipSpaces;
Begin
 While (FPos <= Length(FSrc)) And (FSrc[FPos] = ' ') Do Inc(FPos);
End;

Function PeekCh: Char;
Begin
 If FPos <= Length(FSrc) Then PeekCh := FSrc[FPos] Else PeekCh := #0;
End;

Function PeekCh2: Char;
Begin
 If FPos + 1 <= Length(FSrc) Then PeekCh2 := FSrc[FPos + 1] Else PeekCh2 := #0;
End;

Function MatchCh(C: Char): Boolean;
Begin
 SkipSpaces;
 If PeekCh = C Then Begin Inc(FPos); MatchCh := True; End Else MatchCh := False;
End;

Function IsAlpha(C: Char): Boolean;
Begin
 IsAlpha := ((C >= 'A') And (C <= 'Z')) Or ((C >= 'a') And (C <= 'z')) Or (C = '_');
End;

Function IsDigit(C: Char): Boolean;
Begin
 IsDigit := (C >= '0') And (C <= '9');
End;

{ Parse "[A-Z]+[0-9]+" en majuscules a la position FPos. Renvoie False sans
  bouger FPos si pas un ref. R, C sont 0-based en sortie. }
Function TryParseCellRef(Var R, C: Integer): Boolean;
Var Save: Integer; Letters: String; Digits: String; Ch: Char; Cn, Rn: LongInt;
    I: Integer;
Begin
 SkipSpaces;
 Save := FPos;
 Letters := ''; Digits := '';
 While (FPos <= Length(FSrc)) And IsAlpha(FSrc[FPos]) Do Begin
  Ch := UpCh(FSrc[FPos]);
  If (Ch < 'A') Or (Ch > 'Z') Then Break;
  Letters := Letters + Ch;
  Inc(FPos);
  If Length(Letters) > 2 Then Begin FPos := Save; TryParseCellRef := False; Exit; End;
 End;
 If Length(Letters) = 0 Then Begin FPos := Save; TryParseCellRef := False; Exit; End;
 While (FPos <= Length(FSrc)) And IsDigit(FSrc[FPos]) Do Begin
  Digits := Digits + FSrc[FPos]; Inc(FPos);
  If Length(Digits) > 5 Then Begin FPos := Save; TryParseCellRef := False; Exit; End;
 End;
 If Length(Digits) = 0 Then Begin FPos := Save; TryParseCellRef := False; Exit; End;
 Cn := 0;
 For I := 1 To Length(Letters) Do Cn := Cn * 26 + (Ord(Letters[I]) - Ord('A') + 1);
 Cn := Cn - 1;
 Val(Digits, Rn, I);
 Rn := Rn - 1;
 If (Cn < 0) Or (Cn >= MAX_COLS) Or (Rn < 0) Or (Rn >= MAX_ROWS) Then Begin
  FPos := Save; TryParseCellRef := False; Exit;
 End;
 R := Rn; C := Cn;
 TryParseCellRef := True;
End;

{ Tente de lire un qualificateur "Feuil2!" ou "'Nom Feuille'!".
  Renvoie le pointeur de feuille trouve. Si non present ou nom inconnu :
  restaure FPos et renvoie False. }
Function TryParseSheetQualifier(Var Sh: PSheet): Boolean;
Var Save, I: Integer; Name: String; UN: String;
Begin
 TryParseSheetQualifier := False;
 Sh := Nil;
 SkipSpaces;
 Save := FPos;
 Name := '';
 If FPos > Length(FSrc) Then Exit;
 If FSrc[FPos] = '''' Then Begin
  Inc(FPos);
  While (FPos <= Length(FSrc)) And (FSrc[FPos] <> '''') Do Begin
   Name := Name + FSrc[FPos]; Inc(FPos);
  End;
  If (FPos > Length(FSrc)) Or (FSrc[FPos] <> '''') Then Begin FPos := Save; Exit; End;
  Inc(FPos);
 End Else Begin
  If Not IsAlpha(FSrc[FPos]) Then Exit;
  While (FPos <= Length(FSrc)) And
        (IsAlpha(FSrc[FPos]) Or IsDigit(FSrc[FPos])) Do Begin
   Name := Name + FSrc[FPos]; Inc(FPos);
  End;
 End;
 If (FPos > Length(FSrc)) Or (FSrc[FPos] <> '!') Then Begin FPos := Save; Exit; End;
 UN := UpStr(Name);
 For I := 1 To WB.Count Do
  If (WB.Sheets[I] <> Nil) And (UpStr(WB.Sheets[I]^.Name) = UN) Then Begin
   Sh := WB.Sheets[I];
   Inc(FPos);
   TryParseSheetQualifier := True;
   Exit;
  End;
 FPos := Save;
End;

{ Forward decls }
Function ParseExpr: TEvalRes; Forward;
Function EvaluateCell(R, C: Integer): TEvalRes; Forward;

Function ParseNumber: TEvalRes;
Var S: String; V: Double; Code: Integer;
Begin
 S := '';
 While (FPos <= Length(FSrc)) And IsDigit(FSrc[FPos]) Do Begin
  S := S + FSrc[FPos]; Inc(FPos);
 End;
 If (FPos <= Length(FSrc)) And (FSrc[FPos] = '.') Then Begin
  S := S + '.'; Inc(FPos);
  While (FPos <= Length(FSrc)) And IsDigit(FSrc[FPos]) Do Begin
   S := S + FSrc[FPos]; Inc(FPos);
  End;
 End;
 If (FPos <= Length(FSrc)) And ((FSrc[FPos] = 'e') Or (FSrc[FPos] = 'E')) Then Begin
  S := S + 'E'; Inc(FPos);
  If (FPos <= Length(FSrc)) And ((FSrc[FPos] = '+') Or (FSrc[FPos] = '-')) Then Begin
   S := S + FSrc[FPos]; Inc(FPos);
  End;
  While (FPos <= Length(FSrc)) And IsDigit(FSrc[FPos]) Do Begin
   S := S + FSrc[FPos]; Inc(FPos);
  End;
 End;
 Val(S, V, Code);
 If Code <> 0 Then ParseNumber := MakeErr(ERR_NUM) Else ParseNumber := MakeNum(V);
End;

Function ParseStringLit: TEvalRes;
Var S: String;
Begin
 Inc(FPos); { saute le " ouvrant }
 S := '';
 While FPos <= Length(FSrc) Do Begin
  If FSrc[FPos] = '"' Then Begin
   If (FPos < Length(FSrc)) And (FSrc[FPos + 1] = '"') Then Begin
    S := S + '"'; Inc(FPos, 2);
   End Else Begin
    Inc(FPos); ParseStringLit := MakeText(S); Exit;
   End;
  End Else Begin
   S := S + FSrc[FPos]; Inc(FPos);
  End;
 End;
 ParseStringLit := MakeErr(ERR_VALUE);
End;

{ Aggregat sur une plage : Op = 1 SUM, 2 COUNT (numeric), 3 MIN, 4 MAX,
  5 AVG sum+count, 6 COUNTA (non-empty incl text), 7 PRODUCT }
Procedure VisitCell(R, C: Integer; Op: Byte; Var Sum, MinV, MaxV, Prod: Double;
                    Var Cnt, CntA: LongInt; Var First: Boolean; Var Err: TEvalRes);
Var Res: TEvalRes; V: Double;
Begin
 If Err.IsErr Then Exit;
 Res := EvaluateCell(R, C);
 If Res.IsErr Then Begin
  If Op = 6 Then Inc(CntA);   { COUNTA : compte aussi les erreurs }
  Err := Res; Exit;
 End;
 If Res.IsText And (Length(Res.Text) = 0) Then Exit;  { vide }
 If Res.IsText Then Begin
  Inc(CntA);
  Exit;   { skip pour SUM/MIN/MAX/COUNT }
 End;
 V := Res.Num;
 Inc(CntA); Inc(Cnt);
 Sum := Sum + V;
 Prod := Prod * V;
 If First Then Begin MinV := V; MaxV := V; First := False; End
 Else Begin
  If V < MinV Then MinV := V;
  If V > MaxV Then MaxV := V;
 End;
End;

{ Parse une plage R1C1:R2C2 OU une cellule unique OU une expression scalaire,
  puis appelle l'aggregateur. Renvoie False si erreur de parse. }
Function ParseAggArg(Op: Byte; Var Sum, MinV, MaxV, Prod: Double;
                     Var Cnt, CntA: LongInt; Var First: Boolean;
                     Var Err: TEvalRes): Boolean;
Var R1, C1, R2, C2, Save, R, C: Integer; Res: TEvalRes; V: Double;
    QSh, SaveSh: PSheet; Qualified: Boolean;
Begin
 SkipSpaces;
 Save := FPos;
 SaveSh := FSheet;
 Qualified := False;
 If TryParseSheetQualifier(QSh) Then Begin
  FSheet := QSh; Qualified := True;
 End;
 If TryParseCellRef(R1, C1) Then Begin
  If MatchCh(':') Then Begin
   If Not TryParseCellRef(R2, C2) Then Begin
    If Qualified Then FSheet := SaveSh;
    Err := MakeErr(ERR_VALUE); ParseAggArg := False; Exit;
   End;
   If R1 > R2 Then Begin R := R1; R1 := R2; R2 := R; End;
   If C1 > C2 Then Begin C := C1; C1 := C2; C2 := C; End;
   For R := R1 To R2 Do
    For C := C1 To C2 Do
     VisitCell(R, C, Op, Sum, MinV, MaxV, Prod, Cnt, CntA, First, Err);
   If Qualified Then FSheet := SaveSh;
   ParseAggArg := True; Exit;
  End Else Begin
   VisitCell(R1, C1, Op, Sum, MinV, MaxV, Prod, Cnt, CntA, First, Err);
   If Qualified Then FSheet := SaveSh;
   ParseAggArg := True; Exit;
  End;
 End;
 If Qualified Then FSheet := SaveSh;
 FPos := Save;
 Res := ParseExpr;
 If Res.IsErr Then Begin Err := Res; ParseAggArg := False; Exit; End;
 If Res.IsText And (Length(Res.Text) = 0) Then Begin ParseAggArg := True; Exit; End;
 If Res.IsText Then Begin
  Inc(CntA);
  ParseAggArg := True; Exit;
 End;
 V := Res.Num;
 Inc(Cnt); Inc(CntA);
 Sum := Sum + V; Prod := Prod * V;
 If First Then Begin MinV := V; MaxV := V; First := False; End
 Else Begin If V < MinV Then MinV := V; If V > MaxV Then MaxV := V; End;
 ParseAggArg := True;
End;

Function CallAggregate(Const FName: String): TEvalRes;
Var Sum, MinV, MaxV, Prod: Double; Cnt, CntA: LongInt;
    First: Boolean; Err: TEvalRes; Op: Byte; N: String;
Begin
 N := UpStr(FName);
 Op := 1;
 If N = 'SUM' Then Op := 1
 Else If N = 'COUNT' Then Op := 2
 Else If N = 'MIN' Then Op := 3
 Else If N = 'MAX' Then Op := 4
 Else If (N = 'AVERAGE') Or (N = 'AVG') Or (N = 'MOYENNE') Then Op := 5
 Else If N = 'COUNTA' Then Op := 6
 Else If (N = 'PRODUCT') Or (N = 'PRODUIT') Then Op := 7;
 Sum := 0; MinV := 0; MaxV := 0; Prod := 1;
 Cnt := 0; CntA := 0; First := True;
 Err.IsErr := False; Err.ErrCode := 0;
 If MatchCh(')') Then Begin
  Case Op Of
   2, 6 : CallAggregate := MakeNum(0);
   Else   CallAggregate := MakeErr(ERR_VALUE);
  End;
  Exit;
 End;
 Repeat
  If Not ParseAggArg(Op, Sum, MinV, MaxV, Prod, Cnt, CntA, First, Err) Then Begin
   CallAggregate := Err; Exit;
  End;
  If Err.IsErr Then Begin CallAggregate := Err; Exit; End;
  SkipSpaces;
  If Not MatchCh(',') Then Break;
 Until False;
 If Not MatchCh(')') Then Begin CallAggregate := MakeErr(ERR_VALUE); Exit; End;
 Case Op Of
  1 : CallAggregate := MakeNum(Sum);
  2 : CallAggregate := MakeNum(Cnt);
  3 : If First Then CallAggregate := MakeNum(0) Else CallAggregate := MakeNum(MinV);
  4 : If First Then CallAggregate := MakeNum(0) Else CallAggregate := MakeNum(MaxV);
  5 : If Cnt = 0 Then CallAggregate := MakeErr(ERR_DIV0) Else CallAggregate := MakeNum(Sum / Cnt);
  6 : CallAggregate := MakeNum(CntA);
  7 : If First Then CallAggregate := MakeNum(0) Else CallAggregate := MakeNum(Prod);
 End;
End;

{ Lecture des args generaux : tableau de TEvalRes, max 8 }
Function ReadArgList(Var Args: Array Of TEvalRes; Var N: Integer; Max: Integer): TEvalRes;
Var R: TEvalRes;
Begin
 N := 0;
 SkipSpaces;
 If MatchCh(')') Then Begin ReadArgList := MakeBool(True); Exit; End;
 Repeat
  If N >= Max Then Begin ReadArgList := MakeErr(ERR_VALUE); Exit; End;
  R := ParseExpr;
  If R.IsErr Then Begin ReadArgList := R; Exit; End;
  Args[N] := R;
  Inc(N);
  SkipSpaces;
  If Not MatchCh(',') Then Break;
 Until False;
 If Not MatchCh(')') Then Begin ReadArgList := MakeErr(ERR_VALUE); Exit; End;
 ReadArgList := MakeBool(True);
End;

Function CallFunction(Const FName: String): TEvalRes;
Var N: String; Args: Array[0..7] Of TEvalRes; NArgs: Integer;
    Chk: TEvalRes; V, V2, P: Double; S, S2: String; I: LongInt; B: Boolean;
    AllTrue, AnyTrue: Boolean;
    Y, Mo, D, DOW: Word; Days: LongInt; Yi, J: Integer;
Begin
 N := UpStr(FName);
 { Aggregats }
 If (N = 'SUM') Or (N = 'COUNT') Or (N = 'MIN') Or (N = 'MAX')
    Or (N = 'AVERAGE') Or (N = 'AVG') Or (N = 'MOYENNE') Or (N = 'COUNTA')
    Or (N = 'PRODUCT') Or (N = 'PRODUIT') Then Begin
  CallFunction := CallAggregate(N); Exit;
 End;
 { IF : 2 ou 3 args }
 If (N = 'IF') Or (N = 'SI') Then Begin
  Chk := ReadArgList(Args, NArgs, 3);
  If Chk.IsErr Then Begin CallFunction := Chk; Exit; End;
  If (NArgs < 2) Or (NArgs > 3) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If Not ResAsNum(Args[0], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If V <> 0 Then CallFunction := Args[1]
  Else If NArgs = 3 Then CallFunction := Args[2]
  Else CallFunction := MakeBool(False);
  Exit;
 End;
 { AND / OR / NOT }
 If (N = 'AND') Or (N = 'ET') Then Begin
  Chk := ReadArgList(Args, NArgs, 8);
  If Chk.IsErr Then Begin CallFunction := Chk; Exit; End;
  AllTrue := True;
  For I := 0 To NArgs - 1 Do Begin
   If Args[I].IsErr Then Begin CallFunction := Args[I]; Exit; End;
   If Not ResAsNum(Args[I], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
   If V = 0 Then AllTrue := False;
  End;
  CallFunction := MakeBool(AllTrue); Exit;
 End;
 If (N = 'OR') Or (N = 'OU') Then Begin
  Chk := ReadArgList(Args, NArgs, 8);
  If Chk.IsErr Then Begin CallFunction := Chk; Exit; End;
  AnyTrue := False;
  For I := 0 To NArgs - 1 Do Begin
   If Args[I].IsErr Then Begin CallFunction := Args[I]; Exit; End;
   If Not ResAsNum(Args[I], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
   If V <> 0 Then AnyTrue := True;
  End;
  CallFunction := MakeBool(AnyTrue); Exit;
 End;
 If (N = 'NOT') Or (N = 'NON') Then Begin
  Chk := ReadArgList(Args, NArgs, 1);
  If Chk.IsErr Then Begin CallFunction := Chk; Exit; End;
  If NArgs <> 1 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Not ResAsNum(Args[0], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  CallFunction := MakeBool(V = 0); Exit;
 End;
 { Fonctions numeriques 1 arg }
 Chk := ReadArgList(Args, NArgs, 4);
 If Chk.IsErr Then Begin CallFunction := Chk; Exit; End;
 If (N = 'ABS') Then Begin
  If NArgs <> 1 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If Not ResAsNum(Args[0], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  CallFunction := MakeNum(Abs(V)); Exit;
 End;
 If (N = 'INT') Or (N = 'ENT') Then Begin
  If NArgs <> 1 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If Not ResAsNum(Args[0], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If V >= 0 Then CallFunction := MakeNum(Int(V))
  Else If V = Int(V) Then CallFunction := MakeNum(V)
  Else CallFunction := MakeNum(Int(V) - 1);
  Exit;
 End;
 If (N = 'SQRT') Or (N = 'RACINE') Then Begin
  If NArgs <> 1 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If Not ResAsNum(Args[0], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If V < 0 Then CallFunction := MakeErr(ERR_NUM)
  Else CallFunction := MakeNum(Sqrt(V));
  Exit;
 End;
 If (N = 'EXP') Then Begin
  If NArgs <> 1 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If Not ResAsNum(Args[0], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  CallFunction := MakeNum(Exp(V)); Exit;
 End;
 If (N = 'LN') Then Begin
  If NArgs <> 1 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If Not ResAsNum(Args[0], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If V <= 0 Then CallFunction := MakeErr(ERR_NUM) Else CallFunction := MakeNum(Ln(V));
  Exit;
 End;
 If (N = 'LOG10') Or (N = 'LOG') Then Begin
  If NArgs <> 1 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If Not ResAsNum(Args[0], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If V <= 0 Then CallFunction := MakeErr(ERR_NUM) Else CallFunction := MakeNum(Ln(V) / Ln(10));
  Exit;
 End;
 If (N = 'SIN') Then Begin
  If NArgs <> 1 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If Not ResAsNum(Args[0], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  CallFunction := MakeNum(Sin(V)); Exit;
 End;
 If (N = 'COS') Then Begin
  If NArgs <> 1 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If Not ResAsNum(Args[0], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  CallFunction := MakeNum(Cos(V)); Exit;
 End;
 If (N = 'SIGN') Or (N = 'SIGNE') Then Begin
  If NArgs <> 1 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If Not ResAsNum(Args[0], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If V > 0 Then CallFunction := MakeNum(1)
  Else If V < 0 Then CallFunction := MakeNum(-1)
  Else CallFunction := MakeNum(0);
  Exit;
 End;
 If (N = 'PI') Then Begin
  CallFunction := MakeNum(3.14159265358979); Exit;
 End;
 { Fonctions 2 args numeriques }
 If (N = 'MOD') Then Begin
  If NArgs <> 2 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If Args[1].IsErr Then Begin CallFunction := Args[1]; Exit; End;
  If Not ResAsNum(Args[0], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Not ResAsNum(Args[1], V2) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If V2 = 0 Then CallFunction := MakeErr(ERR_DIV0)
  Else CallFunction := MakeNum(V - V2 * Int(V / V2));
  Exit;
 End;
 If (N = 'POWER') Or (N = 'PUISSANCE') Then Begin
  If NArgs <> 2 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If Args[1].IsErr Then Begin CallFunction := Args[1]; Exit; End;
  If Not ResAsNum(Args[0], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Not ResAsNum(Args[1], V2) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If (V = 0) And (V2 <= 0) Then Begin CallFunction := MakeErr(ERR_NUM); Exit; End;
  If (V < 0) And (V2 <> Int(V2)) Then Begin CallFunction := MakeErr(ERR_NUM); Exit; End;
  If V > 0 Then CallFunction := MakeNum(Exp(V2 * Ln(V)))
  Else If V = 0 Then CallFunction := MakeNum(0)
  Else CallFunction := MakeNum(Exp(V2 * Ln(-V)) * (1 - 2 * (Trunc(Abs(V2)) Mod 2)));
  Exit;
 End;
 If (N = 'ROUND') Or (N = 'ARRONDI') Then Begin
  If NArgs <> 2 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If Args[1].IsErr Then Begin CallFunction := Args[1]; Exit; End;
  If Not ResAsNum(Args[0], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Not ResAsNum(Args[1], V2) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  V2 := Int(V2);
  P := 1;
  I := Trunc(V2);
  If I >= 0 Then Begin While I > 0 Do Begin P := P * 10; Dec(I); End; V := V * P; End
  Else Begin While I < 0 Do Begin P := P * 10; Inc(I); End; V := V / P; P := 1; End;
  If V >= 0 Then V := Int(V + 0.5) Else V := -Int(-V + 0.5);
  I := Trunc(V2);
  If I >= 0 Then Begin P := 1; While I > 0 Do Begin P := P * 10; Dec(I); End; V := V / P; End
  Else Begin P := 1; While I < 0 Do Begin P := P * 10; Inc(I); End; V := V * P; End;
  CallFunction := MakeNum(V); Exit;
 End;
 { Fonctions texte }
 If (N = 'LEN') Or (N = 'NBCAR') Then Begin
  If NArgs <> 1 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  CallFunction := MakeNum(Length(ResAsText(Args[0])));
  Exit;
 End;
 If (N = 'UPPER') Or (N = 'MAJUSCULE') Then Begin
  If NArgs <> 1 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  CallFunction := MakeText(UpStr(ResAsText(Args[0])));
  Exit;
 End;
 If (N = 'LOWER') Or (N = 'MINUSCULE') Then Begin
  If NArgs <> 1 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  S := ResAsText(Args[0]);
  For I := 1 To Length(S) Do
   If (S[I] >= 'A') And (S[I] <= 'Z') Then S[I] := Chr(Ord(S[I]) + 32);
  CallFunction := MakeText(S);
  Exit;
 End;
 If (N = 'LEFT') Or (N = 'GAUCHE') Then Begin
  If (NArgs < 1) Or (NArgs > 2) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If NArgs = 1 Then V := 1
  Else Begin If Not ResAsNum(Args[1], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End; End;
  S := ResAsText(Args[0]);
  I := Trunc(V); If I < 0 Then I := 0; If I > Length(S) Then I := Length(S);
  CallFunction := MakeText(Copy(S, 1, I));
  Exit;
 End;
 If (N = 'RIGHT') Or (N = 'DROITE') Then Begin
  If (NArgs < 1) Or (NArgs > 2) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If NArgs = 1 Then V := 1
  Else Begin If Not ResAsNum(Args[1], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End; End;
  S := ResAsText(Args[0]);
  I := Trunc(V); If I < 0 Then I := 0; If I > Length(S) Then I := Length(S);
  CallFunction := MakeText(Copy(S, Length(S) - I + 1, I));
  Exit;
 End;
 If (N = 'MID') Or (N = 'STXT') Then Begin
  If NArgs <> 3 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Args[0].IsErr Then Begin CallFunction := Args[0]; Exit; End;
  If Args[1].IsErr Then Begin CallFunction := Args[1]; Exit; End;
  If Args[2].IsErr Then Begin CallFunction := Args[2]; Exit; End;
  If Not ResAsNum(Args[1], V) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  If Not ResAsNum(Args[2], V2) Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  S := ResAsText(Args[0]);
  CallFunction := MakeText(Copy(S, Trunc(V), Trunc(V2)));
  Exit;
 End;
 If (N = 'CONCAT') Or (N = 'CONCATENER') Then Begin
  S := '';
  For I := 0 To NArgs - 1 Do Begin
   If Args[I].IsErr Then Begin CallFunction := Args[I]; Exit; End;
   S := S + ResAsText(Args[I]);
  End;
  CallFunction := MakeText(S);
  Exit;
 End;
 { Aujourd'hui / Maintenant (jour Excel base 1900-01-01 = 1) }
 If (N = 'TODAY') Or (N = 'AUJOURDHUI') Or (N = 'NOW') Or (N = 'MAINTENANT') Then Begin
  If NArgs <> 0 Then Begin CallFunction := MakeErr(ERR_VALUE); Exit; End;
  GetDate(Y, Mo, D, DOW);
  Days := 0;
  For Yi := 1900 To Y - 1 Do Begin
   Days := Days + 365;
   If ((Yi Mod 4 = 0) And (Yi Mod 100 <> 0)) Or (Yi Mod 400 = 0) Then Inc(Days);
   If Yi = 1900 Then Inc(Days);   { bug Excel 1900 leap }
  End;
  For J := 1 To Mo - 1 Do
   Case J Of
    1, 3, 5, 7, 8, 10, 12 : Days := Days + 31;
    4, 6, 9, 11           : Days := Days + 30;
    2 : If ((Y Mod 4 = 0) And (Y Mod 100 <> 0)) Or (Y Mod 400 = 0)
         Then Days := Days + 29 Else Days := Days + 28;
   End;
  Days := Days + D;
  CallFunction := MakeNum(Days);
  Exit;
 End;
 CallFunction := MakeErr(ERR_NAME);
End;

Function ParseIdent: String;
Var S: String;
Begin
 S := '';
 While (FPos <= Length(FSrc)) And (IsAlpha(FSrc[FPos]) Or IsDigit(FSrc[FPos])) Do Begin
  S := S + FSrc[FPos]; Inc(FPos);
 End;
 ParseIdent := S;
End;

Function ParsePrimary: TEvalRes;
Var Save, R, C, R2, C2: Integer; Ident: String; Res: TEvalRes; UI: String;
    QSh, SaveSh: PSheet; Qualified: Boolean;
Var ParsePrimary_R: TEvalRes;
Begin
 SkipSpaces;
 If FPos > Length(FSrc) Then Begin ParsePrimary_R := MakeErr(ERR_VALUE); Begin ParsePrimary := ParsePrimary_R; Exit End; End;
 If FSrc[FPos] = '(' Then Begin
  Inc(FPos);
  Res := ParseExpr;
  SkipSpaces;
  If Not MatchCh(')') Then Begin ParsePrimary_R := MakeErr(ERR_VALUE); Begin ParsePrimary := ParsePrimary_R; Exit End; End;
  ParsePrimary_R := Res; Begin ParsePrimary := ParsePrimary_R; Exit End;
 End;
 If FSrc[FPos] = '"' Then Begin
  ParsePrimary_R := ParseStringLit; Begin ParsePrimary := ParsePrimary_R; Exit End;
 End;
 If FSrc[FPos] = '-' Then Begin
  Inc(FPos);
  Res := ParsePrimary_R;
  If Res.IsErr Then Begin ParsePrimary_R := Res; Begin ParsePrimary := ParsePrimary_R; Exit End; End;
  If Res.IsText Then Begin ParsePrimary_R := MakeErr(ERR_VALUE); Begin ParsePrimary := ParsePrimary_R; Exit End; End;
  ParsePrimary_R := MakeNum(-Res.Num); Begin ParsePrimary := ParsePrimary_R; Exit End;
 End;
 If FSrc[FPos] = '+' Then Begin
  Inc(FPos);
  Res := ParsePrimary_R;
  ParsePrimary_R := Res; Begin ParsePrimary := ParsePrimary_R; Exit End;
 End;
 If IsDigit(FSrc[FPos]) Or (FSrc[FPos] = '.') Then Begin
  ParsePrimary_R := ParseNumber; Begin ParsePrimary := ParsePrimary_R; Exit End;
 End;
 If IsAlpha(FSrc[FPos]) Or (FSrc[FPos] = '''') Then Begin
  Save := FPos;
  SaveSh := FSheet;
  Qualified := False;
  If TryParseSheetQualifier(QSh) Then Begin
   FSheet := QSh; Qualified := True;
  End;
  { Tente une ref cellule d'abord }
  If TryParseCellRef(R, C) Then Begin
   SkipSpaces;
   If PeekCh = ':' Then Begin
    Inc(FPos);
    If Not TryParseCellRef(R2, C2) Then Begin
     If Qualified Then FSheet := SaveSh;
     ParsePrimary_R := MakeErr(ERR_REF); Begin ParsePrimary := ParsePrimary_R; Exit End;
    End;
    Res := EvaluateCell(R, C);
    If Qualified Then FSheet := SaveSh;
    ParsePrimary_R := Res; Begin ParsePrimary := ParsePrimary_R; Exit End;
   End;
   Res := EvaluateCell(R, C);
   If Qualified Then FSheet := SaveSh;
   ParsePrimary_R := Res; Begin ParsePrimary := ParsePrimary_R; Exit End;
  End;
  If Qualified Then Begin
   FSheet := SaveSh;
   ParsePrimary_R := MakeErr(ERR_REF); Begin ParsePrimary := ParsePrimary_R; Exit End;
  End;
  If PeekCh = '(' Then Begin
   FPos := Save;
   Ident := ParseIdent;
   Inc(FPos);
   ParsePrimary_R := CallFunction(Ident); Begin ParsePrimary := ParsePrimary_R; Exit End;
  End;
  Ident := ParseIdent;
  UI := UpStr(Ident);
  If (UI = 'TRUE') Or (UI = 'VRAI') Then Begin ParsePrimary_R := MakeBool(True); Begin ParsePrimary := ParsePrimary_R; Exit End; End;
  If (UI = 'FALSE') Or (UI = 'FAUX') Then Begin ParsePrimary_R := MakeBool(False); Begin ParsePrimary := ParsePrimary_R; Exit End; End;
  SkipSpaces;
  If MatchCh('(') Then Begin
   ParsePrimary_R := CallFunction(Ident); Begin ParsePrimary := ParsePrimary_R; Exit End;
  End;
  ParsePrimary_R := MakeErr(ERR_NAME); Begin ParsePrimary := ParsePrimary_R; Exit End;
 End;
 ParsePrimary_R := MakeErr(ERR_VALUE);
 ParsePrimary := ParsePrimary_R;
End;

Function ParsePow: TEvalRes;
Var L, R: TEvalRes; V1, V2: Double;
Begin
 L := ParsePrimary;
 SkipSpaces;
 While PeekCh = '^' Do Begin
  Inc(FPos);
  R := ParsePrimary;
  If L.IsErr Then Begin ParsePow := L; Exit; End;
  If R.IsErr Then Begin ParsePow := R; Exit; End;
  If Not ResAsNum(L, V1) Then Begin ParsePow := MakeErr(ERR_VALUE); Exit; End;
  If Not ResAsNum(R, V2) Then Begin ParsePow := MakeErr(ERR_VALUE); Exit; End;
  If (V1 = 0) And (V2 <= 0) Then Begin ParsePow := MakeErr(ERR_NUM); Exit; End;
  If V1 > 0 Then L := MakeNum(Exp(V2 * Ln(V1)))
  Else If V1 = 0 Then L := MakeNum(0)
  Else If V2 = Int(V2) Then L := MakeNum(Exp(V2 * Ln(-V1)) * (1 - 2 * (Trunc(Abs(V2)) And 1)))
  Else Begin ParsePow := MakeErr(ERR_NUM); Exit; End;
  SkipSpaces;
 End;
 ParsePow := L;
End;

Function ParseMul: TEvalRes;
Var L, R: TEvalRes; V1, V2: Double; Op: Char;
Begin
 L := ParsePow;
 SkipSpaces;
 While (PeekCh = '*') Or (PeekCh = '/') Do Begin
  Op := PeekCh; Inc(FPos);
  R := ParsePow;
  If L.IsErr Then Begin ParseMul := L; Exit; End;
  If R.IsErr Then Begin ParseMul := R; Exit; End;
  If Not ResAsNum(L, V1) Then Begin ParseMul := MakeErr(ERR_VALUE); Exit; End;
  If Not ResAsNum(R, V2) Then Begin ParseMul := MakeErr(ERR_VALUE); Exit; End;
  If Op = '*' Then L := MakeNum(V1 * V2)
  Else Begin
   If V2 = 0 Then Begin ParseMul := MakeErr(ERR_DIV0); Exit; End;
   L := MakeNum(V1 / V2);
  End;
  SkipSpaces;
 End;
 ParseMul := L;
End;

Function ParseAdd: TEvalRes;
Var L, R: TEvalRes; V1, V2: Double; Op: Char;
Begin
 L := ParseMul;
 SkipSpaces;
 While (PeekCh = '+') Or (PeekCh = '-') Do Begin
  Op := PeekCh; Inc(FPos);
  R := ParseMul;
  If L.IsErr Then Begin ParseAdd := L; Exit; End;
  If R.IsErr Then Begin ParseAdd := R; Exit; End;
  If Not ResAsNum(L, V1) Then Begin ParseAdd := MakeErr(ERR_VALUE); Exit; End;
  If Not ResAsNum(R, V2) Then Begin ParseAdd := MakeErr(ERR_VALUE); Exit; End;
  If Op = '+' Then L := MakeNum(V1 + V2)
  Else L := MakeNum(V1 - V2);
  SkipSpaces;
 End;
 ParseAdd := L;
End;

Function ParseConcat: TEvalRes;
Var L, R: TEvalRes; S1, S2: String;
Begin
 L := ParseAdd;
 SkipSpaces;
 While PeekCh = '&' Do Begin
  Inc(FPos);
  R := ParseAdd;
  If L.IsErr Then Begin ParseConcat := L; Exit; End;
  If R.IsErr Then Begin ParseConcat := R; Exit; End;
  S1 := ResAsText(L); S2 := ResAsText(R);
  L := MakeText(S1 + S2);
  SkipSpaces;
 End;
 ParseConcat := L;
End;

Function ParseCompare: TEvalRes;
Var L, R: TEvalRes; Op: String[2]; V1, V2: Double; S1, S2: String;
    Cmp: Integer; B: Boolean; LIsT, RIsT: Boolean;
Begin
 L := ParseConcat;
 SkipSpaces;
 Op := '';
 If PeekCh = '=' Then Begin Op := '='; Inc(FPos); End
 Else If PeekCh = '<' Then Begin
  Inc(FPos);
  If PeekCh = '=' Then Begin Op := '<='; Inc(FPos); End
  Else If PeekCh = '>' Then Begin Op := '<>'; Inc(FPos); End
  Else Op := '<';
 End
 Else If PeekCh = '>' Then Begin
  Inc(FPos);
  If PeekCh = '=' Then Begin Op := '>='; Inc(FPos); End
  Else Op := '>';
 End;
 If Op = '' Then Begin ParseCompare := L; Exit; End;
 R := ParseConcat;
 If L.IsErr Then Begin ParseCompare := L; Exit; End;
 If R.IsErr Then Begin ParseCompare := R; Exit; End;
 LIsT := L.IsText; RIsT := R.IsText;
 If LIsT Or RIsT Then Begin
  S1 := ResAsText(L); S2 := ResAsText(R);
  If S1 < S2 Then Cmp := -1
  Else If S1 > S2 Then Cmp := 1
  Else Cmp := 0;
 End Else Begin
  V1 := L.Num; V2 := R.Num;
  If V1 < V2 Then Cmp := -1
  Else If V1 > V2 Then Cmp := 1
  Else Cmp := 0;
 End;
 B := False;
 If Op = '='  Then B := Cmp = 0
 Else If Op = '<>' Then B := Cmp <> 0
 Else If Op = '<'  Then B := Cmp < 0
 Else If Op = '>'  Then B := Cmp > 0
 Else If Op = '<=' Then B := Cmp <= 0
 Else If Op = '>=' Then B := Cmp >= 0;
 ParseCompare := MakeBool(B);
End;

Function ParseExpr: TEvalRes;
Begin
 ParseExpr := ParseCompare;
End;

Function EvaluateFormula(Const Src: String): TEvalRes;
Var SaveSrc: String; SavePos: Integer; Res: TEvalRes;
Begin
 If FEvalDepth >= MAX_EVAL_DEPTH Then Begin EvaluateFormula := MakeErr(ERR_CIRC); Exit; End;
 Inc(FEvalDepth);
 SaveSrc := FSrc; SavePos := FPos;
 If (Length(Src) >= 1) And (Src[1] = '=') Then FSrc := Copy(Src, 2, 255)
 Else FSrc := Src;
 FPos := 1;
 Res := ParseExpr;
 SkipSpaces;
 If (Not Res.IsErr) And (FPos <= Length(FSrc)) Then Res := MakeErr(ERR_VALUE);
 FSrc := SaveSrc; FPos := SavePos;
 Dec(FEvalDepth);
 EvaluateFormula := Res;
End;

Function EvaluateCell(R, C: Integer): TEvalRes;
Var Cell: TCell;
Begin
 Cell := GetCellRef(FSheet, R, C);
 Case Cell.Kind Of
  ckEmpty  : EvaluateCell := MakeNum(0);
  ckNumber : EvaluateCell := MakeNum(Cell.Num);
  ckText   : EvaluateCell := MakeText(Cell.Text);
  ckFormula : Begin
   If Cell.Formula = Nil Then EvaluateCell := MakeNum(0)
   Else Begin
    { Si on est en train de recalculer cette cellule courante, on prend
      la valeur deja stockee (Num/Text) pour eviter recursion. }
    If Cell.Text = ErrName(ERR_CIRC) Then EvaluateCell := MakeErr(ERR_CIRC)
    Else EvaluateCell := EvaluateFormula(Cell.Formula^);
   End;
  End;
 End;
End;

{ Recalcule toutes les cellules formules de tous les classeurs, fixed-point. }
Procedure RecalcWorkbook;
Var Pass, S, R, C: Integer; Sh: PSheet; Row: PRow; Cell: ^TCell;
    Res: TEvalRes; NewTxt: String; NewNum: Double; NewKind: TCellKind;
    Changed: Boolean;
Begin
 If InRecalc Then Exit;
 InRecalc := True;
 For Pass := 1 To MAX_RECALC_PASS Do Begin
  Changed := False;
  For S := 1 To WB.Count Do Begin
   Sh := WB.Sheets[S];
   If Sh = Nil Then Continue;
   FSheet := Sh;
   For R := 0 To MAX_ROWS - 1 Do Begin
    Row := PeekRow(Sh, R);
    If Row = Nil Then Continue;
    For C := 0 To MAX_COLS - 1 Do Begin
     Cell := @Row^[C];
     If Cell^.Kind <> ckFormula Then Continue;
     If Cell^.Formula = Nil Then Continue;
     FEvalDepth := 0;
     Res := EvaluateFormula(Cell^.Formula^);
     If Res.IsErr Then Begin
      NewTxt := ErrName(Res.ErrCode); NewNum := 0;
      NewKind := ckFormula;
     End Else If Res.IsText Then Begin
      NewTxt := Res.Text; NewNum := 0;
      NewKind := ckFormula;
     End Else Begin
      NewNum := Res.Num;
      NewTxt := DoubleToCellStr(NewNum);
      NewKind := ckFormula;
     End;
     If (Cell^.Text <> NewTxt) Or (Cell^.Num <> NewNum) Then Begin
      Cell^.Text := NewTxt;
      Cell^.Num  := NewNum;
      Cell^.Kind := NewKind;
      Changed := True;
     End;
    End;
   End;
  End;
  If Not Changed Then Break;
 End;
 InRecalc := False;
End;

{ ====================================================================== }
{                       PRIMITIVES GRAPHIQUES                            }
{ ====================================================================== }

Procedure FillBox(X1, Y1, X2, Y2: Integer; Color: Integer);
Begin
 SetFillStyle(1, Color);
 Bar(X1, Y1, X2, Y2);
End;

Procedure DrawFrame(X1, Y1, X2, Y2: Integer; Light, Dark: Integer);
Begin
 SetColor(Light);
 Line(X1, Y1, X2, Y1);
 Line(X1, Y1, X1, Y2);
 SetColor(Dark);
 Line(X1, Y2, X2, Y2);
 Line(X2, Y1, X2, Y2);
End;

Procedure DrawSunkenFrame(X1, Y1, X2, Y2: Integer);
Begin
 DrawFrame(X1, Y1, X2, Y2, CLR_WIN_DARK, CLR_WIN_LIGHT);
End;

Procedure DrawRaisedFrame(X1, Y1, X2, Y2: Integer);
Begin
 DrawFrame(X1, Y1, X2, Y2, CLR_WIN_LIGHT, CLR_WIN_DARK);
End;

Procedure TextAt(X, Y: Integer; Color: Integer; Const S: String);
Begin
 SetColor(Color);
 OutTextXY(X, Y, S);
End;

{ OS/2-0 : barre de titre d'une boite de dialogue dans le style d'OS/2 :
  bleue, case du menu systeme a gauche, titre blanc centre }
Procedure OsTitleBar(X1, Y1, X2, Y2: Integer; Const T: String; TY: Integer);
Var S: Integer;
Begin
 FillBox(X1, Y1, X2, Y2, CLR_HEADER_SEL);
 S := Y2 - Y1 - 2;
 If S > 3 Then Begin
  FillBox(X1 + 1, Y1 + 1, X1 + 1 + S, Y1 + 1 + S, CLR_WIN_BG);
  SetColor(CLR_WIN_LIGHT);
  Line(X1 + 1, Y1 + 1, X1 + 1 + S, Y1 + 1);
  Line(X1 + 1, Y1 + 1, X1 + 1, Y1 + 1 + S);
  SetColor(CLR_WIN_DARK);
  Line(X1 + 1, Y1 + 1 + S, X1 + 1 + S, Y1 + 1 + S);
  Line(X1 + 1 + S, Y1 + 1, X1 + 1 + S, Y1 + 1 + S);
  FillBox(X1 + 4, Y1 + 1 + S Div 2, X1 + S - 2, Y1 + 2 + S Div 2, CLR_TEXT);
 End;
 TextAt((X1 + S + X2 - TextWidth(T)) Div 2, TY, CLR_WIN_LIGHT, T);
End;

Procedure TextBoldAt(X, Y: Integer; Color: Integer; Const S: String);
Begin
 SetColor(Color);
 OutTextXY(X,   Y, S);
 OutTextXY(X+1, Y, S);
End;

{ ====================================================================== }
{                       MENUS DEROULANTS                                 }
{ ====================================================================== }

Const
 MENU_COUNT = 9;
 MENU_LABELS : Array[1..MENU_COUNT] Of String[14] = (
  '&Fichier',
  '&Edition',
  '&Affichage',
  '&Insertion',
  'Forma&t',
  '&Outils',
  '&Donnees',
  'Fe&netre',
  '&?'
 );

Function MenuItemCount(M: Integer): Integer;
Begin
 Case M Of
  1: MenuItemCount := 10;  { Fichier }
  2: MenuItemCount := 9;   { Edition }
  3: MenuItemCount := 5;   { Affichage }
  4: MenuItemCount := 7;   { Insertion }
  5: MenuItemCount := 6;   { Format }
  6: MenuItemCount := 4;   { Outils }
  7: MenuItemCount := 5;   { Donnees }
  8: MenuItemCount := 3;   { Fenetre }
  9: MenuItemCount := 2;   { ? }
  Else MenuItemCount := 0;
 End;
End;

Function MenuItemLabel(M, I: Integer): String;
Begin
 MenuItemLabel := '';
 Case M Of
  1: Case I Of
      1: MenuItemLabel := '&Nouveau          Ctrl+N';
      2: MenuItemLabel := '&Ouvrir...        Ctrl+O';
      3: MenuItemLabel := '-';
      4: MenuItemLabel := '&Enregistrer      Ctrl+S';
      5: MenuItemLabel := 'Enregistrer &sous...';
      6: MenuItemLabel := '-';
      7: MenuItemLabel := 'Aperc&u avant impression';
      8: MenuItemLabel := '&Imprimer...      Ctrl+P';
      9: MenuItemLabel := '-';
     10: MenuItemLabel := '&Quitter          Alt+F4';
     End;
  2: Case I Of
      1: MenuItemLabel := '&Annuler          Ctrl+Z';
      2: MenuItemLabel := '&Retablir         Ctrl+Y';
      3: MenuItemLabel := '-';
      4: MenuItemLabel := 'Co&uper           Ctrl+X';
      5: MenuItemLabel := '&Copier           Ctrl+C';
      6: MenuItemLabel := 'C&oller           Ctrl+V';
      7: MenuItemLabel := '-';
      8: MenuItemLabel := 'Re&chercher...    Ctrl+F';
      9: MenuItemLabel := 'Re&mplacer...     Ctrl+H';
     End;
  3: Case I Of
      1: MenuItemLabel := 'Barre d''&outils';
      2: MenuItemLabel := 'Barre de &formule';
      3: MenuItemLabel := 'Barre d''e&tat';
      4: MenuItemLabel := '-';
      5: MenuItemLabel := '&Zoom...';
     End;
  4: Case I Of
      1: MenuItemLabel := '&Cellules...';
      2: MenuItemLabel := '&Lignes';
      3: MenuItemLabel := 'Colo&nnes';
      4: MenuItemLabel := '-';
      5: MenuItemLabel := '&Feuille';
      6: MenuItemLabel := '&Graphique...';
      7: MenuItemLabel := '&Image...';
     End;
  5: Case I Of
      1: MenuItemLabel := '&Cellule...';
      2: MenuItemLabel := '&Ligne';
      3: MenuItemLabel := 'Colo&nne';
      4: MenuItemLabel := '-';
      5: MenuItemLabel := '&Feuille';
      6: MenuItemLabel := 'Mise en forme &auto...';
     End;
  6: Case I Of
      1: MenuItemLabel := '&Orthographe...     F7';
      2: MenuItemLabel := '&Verifier formules';
      3: MenuItemLabel := '-';
      4: MenuItemLabel := '&Options...';
     End;
  7: Case I Of
      1: MenuItemLabel := '&Trier...';
      2: MenuItemLabel := '&Filtrer';
      3: MenuItemLabel := '-';
      4: MenuItemLabel := '&Sous-totaux...';
      5: MenuItemLabel := 'Tableau croi&se...';
     End;
  8: Case I Of
      1: MenuItemLabel := '&Nouvelle fenetre';
      2: MenuItemLabel := '&Figer les volets';
      3: MenuItemLabel := '&Reorganiser...';
     End;
  9: Case I Of
      1: MenuItemLabel := 'A&ide              F1';
      2: MenuItemLabel := 'A &propos...';
     End;
 End;
End;

Function MenuLabelWidth(Const S: String): Integer;
Var I, N: Integer;
Begin
 { 8 pixels par caractere ; ignorer '&' marqueur d'accelerateur }
 N := 0;
 For I := 1 To Length(S) Do If S[I] <> '&' Then Inc(N);
 MenuLabelWidth := N * 8;
End;

Function MenuBarLabel(M: Integer): String;
Begin
 MenuBarLabel:=MENU_LABELS[M];
 If RibbonMode Then Case M Of
  2: MenuBarLabel:='Accu&eil';
  9: MenuBarLabel:='Aide';
 End;
End;

Function MenuCommandEnabled(M,I: Integer): Boolean;
Begin
 MenuCommandEnabled:=False;
 Case M Of
  1: MenuCommandEnabled:=I In [1,2,4,5,10];
  2: MenuCommandEnabled:=I In [1,2,4,5,6];
  4: MenuCommandEnabled:=I In [5,6,7];
  5: MenuCommandEnabled:=I In [1,2,3,5];
  9: MenuCommandEnabled:=I=2;
 End;
End;

Function RibbonItemCount: Integer;
Var I,N: Integer;
Begin
 N:=0;
 For I:=1 To MenuItemCount(RibbonTab) Do If MenuItemLabel(RibbonTab,I)<>'-' Then Inc(N);
 RibbonItemCount:=N;
End;

Function RibbonMenuItem(Index: Integer): Integer;
Var I,N: Integer;
Begin
 RibbonMenuItem:=0;N:=0;
 For I:=1 To MenuItemCount(RibbonTab) Do If MenuItemLabel(RibbonTab,I)<>'-' Then Begin
  Inc(N);If N=Index Then Begin RibbonMenuItem:=I;Exit;End;
 End;
End;

Procedure RibbonButtonBox(Index: Integer; Var X,Y,W,H: Integer);
Begin
 W:=(SCR_W-16) Div 3;H:=22;
 X:=8+((Index-1) Div 3)*W;
 Y:=MENUBAR_H+4+((Index-1) Mod 3)*H;
End;

Function RibbonHitAt(MX,MY: Integer): Integer;
Var I,X,Y,W,H: Integer;
Begin
 RibbonHitAt:=0;
 If Not RibbonMode Then Exit;
 For I:=1 To RibbonItemCount Do Begin
  RibbonButtonBox(I,X,Y,W,H);
  If (MX>=X) And (MX<X+W-4) And (MY>=Y) And (MY<Y+H-2) Then Begin
   RibbonHitAt:=I;Exit;
  End;
 End;
End;

Function ToolbarTop: Integer;
Begin
 ToolbarTop:=MENUBAR_H;
 If RibbonMode Then ToolbarTop:=MENUBAR_H+74;
End;

Function MenuBarItemX(M: Integer): Integer;
Var I, X: Integer;
Begin
 X := 8;
 For I := 1 To M - 1 Do X := X + MenuLabelWidth(MenuBarLabel(I)) + 14;
 MenuBarItemX := X;
End;

Procedure DrawMenuBarItem(M: Integer; Highlight: Boolean);
Var X, W: Integer; S: String; I, Tx: Integer;
Begin
 X := MenuBarItemX(M);
 S := MenuBarLabel(M);
 W := MenuLabelWidth(S);
 If Highlight Then Begin
  FillBox(X - 3, 1, X + W + 3, MENUBAR_H - 2, CLR_HEADER_SEL);
  SetColor(CLR_WIN_LIGHT);
 End Else
  SetColor(CLR_TEXT);
 Tx := X;
 For I := 1 To Length(S) Do Begin
  If S[I] = '&' Then Continue;
  OutTextXY(Tx, 5, S[I]);
  Tx := Tx + 8;
 End;
End;

Procedure OsSyncMenu; Forward;

Procedure DrawMenuBar;
Begin
 OsSyncMenu;
End;

Procedure DrawDropDown(M: Integer);
Var I, N, X, Y, W, H, Tx, Ty, J: Integer; S: String; IsSep: Boolean;
Begin
 N := MenuItemCount(M);
 If N = 0 Then Exit;
 W := 0;
 For I := 1 To N Do Begin
  S := MenuItemLabel(M, I);
  If S <> '-' Then If MenuLabelWidth(S) > W Then W := MenuLabelWidth(S);
 End;
 W := W + 20;
 X := MenuBarItemX(M) - 4;
 If X + W > SCR_W - 2 Then X := SCR_W - 2 - W;
 Y := MENUBAR_H;
 H := N * 12 + 4;
 FillBox(X, Y, X + W, Y + H, CLR_WIN_BG);
 DrawRaisedFrame(X, Y, X + W, Y + H);
 { Ombre simple }
 SetColor(CLR_WIN_DARK);
 Line(X + W + 1, Y + 2, X + W + 1, Y + H + 1);
 Line(X + 2, Y + H + 1, X + W + 1, Y + H + 1);
 For I := 1 To N Do Begin
  S := MenuItemLabel(M, I);
  Ty := Y + 2 + (I - 1) * 12;
  IsSep := (S = '-');
  If IsSep Then Begin
   SetColor(CLR_WIN_DARK);
   Line(X + 3, Ty + 5, X + W - 3, Ty + 5);
   SetColor(CLR_WIN_LIGHT);
   Line(X + 3, Ty + 6, X + W - 3, Ty + 6);
  End Else Begin
   If I = MenuItemHi Then Begin
    FillBox(X + 2, Ty, X + W - 2, Ty + 11, CLR_HEADER_SEL);
    SetColor(CLR_WIN_LIGHT);
   End Else
    SetColor(CLR_TEXT);
   Tx := X + 6;
   For J := 1 To Length(S) Do Begin
    If S[J] = '&' Then Continue;
    OutTextXY(Tx, Ty + 2, S[J]);
    Tx := Tx + 8;
   End;
  End;
 End;
End;

Function DropDownItemAt(M, MX, MY: Integer): Integer;
{ Retourne l'item sous la souris (0 si hors menu) }
Var N, X, Y, W, H, I, Idx: Integer; S: String;
Begin
 DropDownItemAt := 0;
 N := MenuItemCount(M);
 If N = 0 Then Exit;
 W := 0;
 For I := 1 To N Do Begin
  S := MenuItemLabel(M, I);
  If S <> '-' Then If MenuLabelWidth(S) > W Then W := MenuLabelWidth(S);
 End;
 W := W + 20;
 X := MenuBarItemX(M) - 4;
 If X + W > SCR_W - 2 Then X := SCR_W - 2 - W;
 Y := MENUBAR_H;
 H := N * 12 + 4;
 If (MX < X) Or (MX > X + W) Or (MY < Y) Or (MY > Y + H) Then Exit;
 Idx := (MY - (Y + 2)) Div 12 + 1;
 If (Idx >= 1) And (Idx <= N) Then
  If MenuItemLabel(M, Idx) <> '-' Then DropDownItemAt := Idx;
End;

{ ====================================================================== }
{                       BARRE D'OUTILS (icones vectorielles)             }
{ ====================================================================== }

Const
 TOOL_COUNT = 14;
 TOOL_ICON_W = 22;
 TOOL_ICON_H = 20;
 TOOL_GAP    = 2;
 TOOL_SEP    = 6;
 TOOL_START_X = 4;

 { Indices des outils }
 TI_NEW   = 1;
 TI_OPEN  = 2;
 TI_SAVE  = 3;
 TI_CUT   = 4;
 TI_COPY  = 5;
 TI_PASTE = 6;
 TI_BOLD  = 7;
 TI_ITAL  = 8;
 TI_UND   = 9;
 TI_AL_L  = 10;
 TI_AL_C  = 11;
 TI_AL_R  = 12;
 TI_SUM   = 13;
 TI_CHART = 14;

Function ToolGroupBreakBefore(I: Integer): Boolean;
Begin
 ToolGroupBreakBefore := (I = TI_CUT) Or (I = TI_BOLD) Or (I = TI_AL_L) Or (I = TI_SUM);
End;

Function ToolBoxX(I: Integer): Integer;
Var J, X: Integer;
Begin
 X := TOOL_START_X;
 For J := 1 To I - 1 Do Begin
  X := X + TOOL_ICON_W + TOOL_GAP;
  If ToolGroupBreakBefore(J + 1) Then X := X + TOOL_SEP;
 End;
 ToolBoxX := X;
End;

Function ToolHitAt(MX, MY: Integer): Integer;
Var I, X: Integer;
Begin
 ToolHitAt := 0;
 If (MY < ToolbarTop) Or (MY >= ToolbarTop + CLASSIC_TOOLBAR_H) Then Exit;
 For I := 1 To TOOL_COUNT Do Begin
  X := ToolBoxX(I);
  If (MX >= X) And (MX < X + TOOL_ICON_W) Then Begin
   ToolHitAt := I;
   Exit;
  End;
 End;
End;

Procedure DrawIcon(I, X, Y: Integer);
Var Cx, Cy: Integer;
Begin
 Cx := X + TOOL_ICON_W Div 2;
 Cy := Y + TOOL_ICON_H Div 2;
 Case I Of
  TI_NEW : Begin                 { feuille blanche avec coin plie }
   SetColor(CLR_TEXT);
   Rectangle(X + 5, Y + 3, X + TOOL_ICON_W - 7, Y + TOOL_ICON_H - 3);
   SetFillStyle(1, CLR_WIN_LIGHT);
   Bar(X + 6, Y + 4, X + TOOL_ICON_W - 8, Y + TOOL_ICON_H - 4);
   SetColor(CLR_TEXT);
   Line(X + TOOL_ICON_W - 10, Y + 3, X + TOOL_ICON_W - 7, Y + 6);
   Line(X + TOOL_ICON_W - 10, Y + 3, X + TOOL_ICON_W - 10, Y + 6);
   Line(X + TOOL_ICON_W - 10, Y + 6, X + TOOL_ICON_W - 7, Y + 6);
  End;
  TI_OPEN : Begin                { dossier ouvert jaune }
   SetColor(6);
   SetFillStyle(1, 14);
   Bar(X + 3, Y + 6, X + TOOL_ICON_W - 4, Y + TOOL_ICON_H - 3);
   Rectangle(X + 3, Y + 6, X + TOOL_ICON_W - 4, Y + TOOL_ICON_H - 3);
   Line(X + 3, Y + 6, X + 7, Y + 4);
   Line(X + 7, Y + 4, X + 11, Y + 4);
   Line(X + 11, Y + 4, X + 11, Y + 6);
  End;
  TI_SAVE : Begin                { disquette bleue }
   SetFillStyle(1, 1);
   Bar(X + 4, Y + 3, X + TOOL_ICON_W - 5, Y + TOOL_ICON_H - 3);
   SetColor(CLR_TEXT);
   Rectangle(X + 4, Y + 3, X + TOOL_ICON_W - 5, Y + TOOL_ICON_H - 3);
   SetFillStyle(1, CLR_WIN_LIGHT);
   Bar(X + 6, Y + 11, X + TOOL_ICON_W - 7, Y + TOOL_ICON_H - 4);
   SetFillStyle(1, 7);
   Bar(X + 7, Y + 4, X + TOOL_ICON_W - 9, Y + 8);
   SetColor(CLR_TEXT);
   Rectangle(X + 7, Y + 4, X + TOOL_ICON_W - 9, Y + 8);
  End;
  TI_CUT : Begin                 { ciseaux }
   SetColor(CLR_TEXT);
   Circle(X + 7, Y + TOOL_ICON_H - 6, 3);
   Circle(X + TOOL_ICON_W - 8, Y + TOOL_ICON_H - 6, 3);
   Line(X + 7, Y + TOOL_ICON_H - 8, X + TOOL_ICON_W - 7, Y + 4);
   Line(X + TOOL_ICON_W - 8, Y + TOOL_ICON_H - 8, X + 6, Y + 4);
  End;
  TI_COPY : Begin                { deux feuilles superposees }
   SetColor(CLR_TEXT);
   SetFillStyle(1, CLR_WIN_LIGHT);
   Bar(X + 4, Y + 4, X + TOOL_ICON_W - 9, Y + TOOL_ICON_H - 6);
   Rectangle(X + 4, Y + 4, X + TOOL_ICON_W - 9, Y + TOOL_ICON_H - 6);
   Bar(X + 8, Y + 7, X + TOOL_ICON_W - 5, Y + TOOL_ICON_H - 3);
   Rectangle(X + 8, Y + 7, X + TOOL_ICON_W - 5, Y + TOOL_ICON_H - 3);
  End;
  TI_PASTE : Begin               { presse-papier }
   SetFillStyle(1, 6);
   Bar(X + 3, Y + 4, X + TOOL_ICON_W - 4, Y + TOOL_ICON_H - 3);
   SetColor(CLR_TEXT);
   Rectangle(X + 3, Y + 4, X + TOOL_ICON_W - 4, Y + TOOL_ICON_H - 3);
   SetFillStyle(1, CLR_WIN_LIGHT);
   Bar(X + 6, Y + 7, X + TOOL_ICON_W - 7, Y + TOOL_ICON_H - 5);
   Rectangle(X + 8, Y + 2, X + TOOL_ICON_W - 9, Y + 5);
  End;
  TI_BOLD : Begin                { lettre G grasse }
   TextBoldAt(Cx - 4, Y + 6, CLR_TEXT, 'G');
  End;
  TI_ITAL : Begin                { lettre I italique }
   SetColor(CLR_TEXT);
   OutTextXY(Cx - 2, Y + 6, 'I');
   Line(Cx - 4, Y + TOOL_ICON_H - 5, Cx + 4, Y + 5);
  End;
  TI_UND : Begin                 { lettre S soulignee }
   SetColor(CLR_TEXT);
   OutTextXY(Cx - 4, Y + 5, 'S');
   Line(Cx - 5, Y + TOOL_ICON_H - 5, Cx + 5, Y + TOOL_ICON_H - 5);
  End;
  TI_AL_L : Begin                { aligner gauche }
   SetColor(CLR_TEXT);
   Line(X + 4, Y + 5,  X + TOOL_ICON_W - 5, Y + 5);
   Line(X + 4, Y + 9,  X + TOOL_ICON_W - 9, Y + 9);
   Line(X + 4, Y + 13, X + TOOL_ICON_W - 5, Y + 13);
   Line(X + 4, Y + 17, X + TOOL_ICON_W - 9, Y + 17);
  End;
  TI_AL_C : Begin                { aligner centre }
   SetColor(CLR_TEXT);
   Line(X + 4, Y + 5,  X + TOOL_ICON_W - 5, Y + 5);
   Line(X + 6, Y + 9,  X + TOOL_ICON_W - 7, Y + 9);
   Line(X + 4, Y + 13, X + TOOL_ICON_W - 5, Y + 13);
   Line(X + 7, Y + 17, X + TOOL_ICON_W - 8, Y + 17);
  End;
  TI_AL_R : Begin                { aligner droite }
   SetColor(CLR_TEXT);
   Line(X + 4, Y + 5,  X + TOOL_ICON_W - 5, Y + 5);
   Line(X + 8, Y + 9,  X + TOOL_ICON_W - 5, Y + 9);
   Line(X + 4, Y + 13, X + TOOL_ICON_W - 5, Y + 13);
   Line(X + 8, Y + 17, X + TOOL_ICON_W - 5, Y + 17);
  End;
  TI_SUM : Begin                 { sigma stylise }
   SetColor(CLR_TEXT);
   Line(X + 6, Y + 4, X + TOOL_ICON_W - 6, Y + 4);
   Line(X + TOOL_ICON_W - 6, Y + 4, Cx, Cy);
   Line(Cx, Cy, X + 6, Y + TOOL_ICON_H - 4);
   Line(X + 6, Y + TOOL_ICON_H - 4, X + TOOL_ICON_W - 6, Y + TOOL_ICON_H - 4);
  End;
  TI_CHART : Begin               { 3 barres histogramme }
   SetFillStyle(1, 1);  Bar(X + 4,  Y + 12, X + 7,  Y + TOOL_ICON_H - 4);
   SetFillStyle(1, 4);  Bar(X + 9,  Y + 8,  X + 12, Y + TOOL_ICON_H - 4);
   SetFillStyle(1, 2);  Bar(X + 14, Y + 5,  X + 17, Y + TOOL_ICON_H - 4);
   SetColor(CLR_TEXT);
   Line(X + 3, Y + TOOL_ICON_H - 4, X + TOOL_ICON_W - 4, Y + TOOL_ICON_H - 4);
   Line(X + 3, Y + 3, X + 3, Y + TOOL_ICON_H - 4);
  End;
 End;
End;

Function RibbonEntryEnabled(Index: Integer): Boolean;
Var Item: Integer;
Begin
 RibbonEntryEnabled:=False;
 If (Index<1) Or (Index>RibbonItemCount+TOOL_COUNT) Then Exit;
 If Index<=RibbonItemCount Then
  RibbonEntryEnabled:=MenuCommandEnabled(RibbonTab,RibbonMenuItem(Index))
 Else Begin
  Item:=Index-RibbonItemCount;
  RibbonEntryEnabled:=Item<>TI_SUM;
 End;
End;

Function RibbonCaption(S: String): String;
Var I: Integer; R: String;
Begin
 R:='';I:=1;
 While I<=Length(S) Do Begin
  If (I<Length(S)) And (S[I]=' ') And (S[I+1]=' ') Then Break;
  If S[I]<>'&' Then R:=R+S[I];
  Inc(I);
 End;
 If Length(R)>22 Then R:=Copy(R,1,19)+'...';
 RibbonCaption:=R;
End;

{ Icones vectorielles 16x16 pour les commandes du ruban. }
Type TRibbonGlyph = (rgPage,rgOpen,rgSave,rgSaveAs,rgPrint,rgPreview,rgExit,
 rgUndo,rgRedo,rgCut,rgCopy,rgPaste,rgFind,rgReplace,rgToolbar,rgFormula,
 rgStatus,rgZoom,rgCells,rgRow,rgColumn,rgSheet,rgChart,rgImage,rgFormat,
 rgSpell,rgCheck,rgOptions,rgSort,rgFilter,rgTotal,rgPivot,rgWindow,
 rgFreeze,rgArrange,rgHelp,rgAbout);

Function RibbonCommandGlyph(M,I: Integer): TRibbonGlyph;
Begin
 RibbonCommandGlyph:=rgPage;
 Case M Of
  1: Case I Of
   1: RibbonCommandGlyph:=rgPage;2: RibbonCommandGlyph:=rgOpen;
   4: RibbonCommandGlyph:=rgSave;5: RibbonCommandGlyph:=rgSaveAs;
   7: RibbonCommandGlyph:=rgPreview;8: RibbonCommandGlyph:=rgPrint;
   10: RibbonCommandGlyph:=rgExit;
  End;
  2: Case I Of
   1: RibbonCommandGlyph:=rgUndo;2: RibbonCommandGlyph:=rgRedo;
   4: RibbonCommandGlyph:=rgCut;5: RibbonCommandGlyph:=rgCopy;
   6: RibbonCommandGlyph:=rgPaste;8: RibbonCommandGlyph:=rgFind;
   9: RibbonCommandGlyph:=rgReplace;
  End;
  3: Case I Of
   1: RibbonCommandGlyph:=rgToolbar;2: RibbonCommandGlyph:=rgFormula;
   3: RibbonCommandGlyph:=rgStatus;5: RibbonCommandGlyph:=rgZoom;
  End;
  4,5: Case I Of
   1: RibbonCommandGlyph:=rgCells;2: RibbonCommandGlyph:=rgRow;
   3: RibbonCommandGlyph:=rgColumn;5: RibbonCommandGlyph:=rgSheet;
   6: If M=4 Then RibbonCommandGlyph:=rgChart Else RibbonCommandGlyph:=rgFormat;
   7: RibbonCommandGlyph:=rgImage;
  End;
  6: Case I Of
   1: RibbonCommandGlyph:=rgSpell;2: RibbonCommandGlyph:=rgCheck;
   4: RibbonCommandGlyph:=rgOptions;
  End;
  7: Case I Of
   1: RibbonCommandGlyph:=rgSort;2: RibbonCommandGlyph:=rgFilter;
   4: RibbonCommandGlyph:=rgTotal;5: RibbonCommandGlyph:=rgPivot;
  End;
  8: Case I Of
   1: RibbonCommandGlyph:=rgWindow;2: RibbonCommandGlyph:=rgFreeze;
   3: RibbonCommandGlyph:=rgArrange;
  End;
  9: If I=1 Then RibbonCommandGlyph:=rgHelp Else RibbonCommandGlyph:=rgAbout;
 End;
End;

Procedure DrawRibbonCommandIcon(M,I,X,Y,Color: Integer);
Var Glyph: TRibbonGlyph; J,A,Accent: Integer;
Begin
 Glyph:=RibbonCommandGlyph(M,I);Accent:=Color;
 If Color=CLR_TEXT Then Accent:=2;
 SetColor(Color);
 Case Glyph Of
  rgPage,rgSave,rgSaveAs: Begin
   Rectangle(X+2,Y+1,X+13,Y+14);
   If Glyph=rgPage Then Begin
    Line(X+5,Y+5,X+10,Y+5);Line(X+5,Y+8,X+10,Y+8);
   End Else Begin
    Rectangle(X+4,Y+1,X+10,Y+5);Rectangle(X+5,Y+9,X+11,Y+14);
    If Glyph=rgSaveAs Then Begin SetColor(Accent);Line(X+8,Y+13,X+15,Y+6);End;
   End;
  End;
  rgOpen: Begin
   Line(X+1,Y+5,X+1,Y+13);Line(X+1,Y+13,X+13,Y+13);
   Line(X+1,Y+5,X+5,Y+5);Line(X+5,Y+5,X+6,Y+3);Line(X+6,Y+3,X+12,Y+3);
   Line(X+12,Y+3,X+12,Y+6);SetColor(Accent);
   Line(X+1,Y+13,X+4,Y+7);Line(X+4,Y+7,X+15,Y+7);Line(X+15,Y+7,X+13,Y+13);
  End;
  rgPrint,rgPreview: Begin
   Rectangle(X+1,Y+5,X+14,Y+11);Rectangle(X+4,Y+1,X+11,Y+5);
   Rectangle(X+4,Y+9,X+11,Y+14);Line(X+11,Y+7,X+12,Y+7);
   If Glyph=rgPreview Then Begin SetColor(Accent);Circle(X+9,Y+9,3);Line(X+11,Y+11,X+15,Y+15);End;
  End;
  rgExit: Begin
   Rectangle(X+2,Y+1,X+10,Y+14);SetColor(Accent);
   Line(X+6,Y+7,X+15,Y+7);Line(X+12,Y+4,X+15,Y+7);Line(X+12,Y+10,X+15,Y+7);
  End;
  rgUndo,rgRedo: Begin
   A:=1;If Glyph=rgRedo Then A:=-1;
   Line(X+8-A*5,Y+5,X+8+A*4,Y+5);Line(X+8+A*4,Y+5,X+8+A*6,Y+8);
   Line(X+8+A*6,Y+8,X+8+A*6,Y+12);SetColor(Accent);
   Line(X+8-A*5,Y+5,X+8-A*2,Y+2);Line(X+8-A*5,Y+5,X+8-A*2,Y+8);
  End;
  rgCut: Begin
   Circle(X+4,Y+12,2);Circle(X+11,Y+12,2);
   Line(X+5,Y+10,X+12,Y+1);Line(X+10,Y+10,X+3,Y+1);
  End;
  rgCopy,rgPaste: Begin
   Rectangle(X+2,Y+1,X+10,Y+11);
   If Glyph=rgPaste Then Rectangle(X+4,Y,X+9,Y+3);
   SetColor(Accent);Rectangle(X+6,Y+5,X+14,Y+15);
   Line(X+8,Y+8,X+12,Y+8);Line(X+8,Y+11,X+12,Y+11);
  End;
  rgFind,rgReplace,rgZoom: Begin
   Circle(X+6,Y+6,5);Line(X+10,Y+10,X+15,Y+15);
   If Glyph=rgZoom Then Begin Line(X+3,Y+6,X+9,Y+6);Line(X+6,Y+3,X+6,Y+9);End;
   If Glyph=rgReplace Then Begin SetColor(Accent);Line(X+1,Y+14,X+7,Y+14);Line(X+5,Y+12,X+7,Y+14);End;
  End;
  rgCells,rgRow,rgColumn,rgSheet,rgFormat,rgPivot,rgFreeze: Begin
   Rectangle(X+1,Y+1,X+14,Y+14);
   For J:=1 To 2 Do Begin Line(X+1+J*4,Y+1,X+1+J*4,Y+14);Line(X+1,Y+1+J*4,X+14,Y+1+J*4);End;
   SetColor(Accent);
   If Glyph=rgRow Then Rectangle(X+1,Y+5,X+14,Y+9)
   Else If Glyph=rgColumn Then Rectangle(X+5,Y+1,X+9,Y+14)
   Else If Glyph=rgFreeze Then Begin Line(X+5,Y+1,X+5,Y+14);Line(X+1,Y+5,X+14,Y+5);End
   Else Rectangle(X+5,Y+5,X+9,Y+9);
   If Glyph=rgSheet Then Line(X+3,Y+15,X+11,Y+15);
   If Glyph=rgFormat Then Begin Line(X+10,Y,X+15,Y+5);Line(X+15,Y,X+10,Y+5);End;
   If Glyph=rgPivot Then Begin Line(X+7,Y+3,X+12,Y+3);Line(X+12,Y+3,X+12,Y+7);End;
  End;
  rgChart: Begin
   Line(X+1,Y+1,X+1,Y+14);Line(X+1,Y+14,X+15,Y+14);SetColor(Accent);
   Rectangle(X+3,Y+9,X+5,Y+13);Rectangle(X+7,Y+5,X+9,Y+13);Rectangle(X+11,Y+2,X+13,Y+13);
  End;
  rgImage: Begin
   Rectangle(X+1,Y+1,X+14,Y+14);Circle(X+10,Y+5,2);SetColor(Accent);
   Line(X+2,Y+12,X+6,Y+7);Line(X+6,Y+7,X+10,Y+12);Line(X+10,Y+12,X+13,Y+9);
  End;
  rgToolbar,rgStatus,rgWindow,rgArrange: Begin
   Rectangle(X+1,Y+1,X+14,Y+13);Line(X+1,Y+4,X+14,Y+4);
   If Glyph=rgToolbar Then For J:=0 To 2 Do Rectangle(X+3+J*4,Y+6,X+5+J*4,Y+9);
   If Glyph=rgStatus Then Line(X+1,Y+11,X+14,Y+11);
   If Glyph=rgArrange Then Begin Line(X+8,Y+4,X+8,Y+13);Line(X+1,Y+8,X+14,Y+8);End;
   If Glyph=rgWindow Then Begin SetColor(Accent);Rectangle(X+5,Y+6,X+15,Y+15);End;
  End;
  rgFormula,rgTotal: Begin
   SetColor(Accent);Line(X+3,Y+2,X+13,Y+2);Line(X+3,Y+2,X+8,Y+8);
   Line(X+8,Y+8,X+3,Y+14);Line(X+3,Y+14,X+13,Y+14);
   If Glyph=rgFormula Then Line(X+11,Y+7,X+15,Y+11);
  End;
  rgSpell,rgCheck: Begin
   If Glyph=rgSpell Then Begin OutTextXY(X,Y,'A');OutTextXY(X+7,Y,'B');End
   Else Rectangle(X+2,Y+1,X+12,Y+9);
   SetColor(Accent);Line(X+4,Y+11,X+7,Y+14);Line(X+7,Y+14,X+14,Y+7);
  End;
  rgOptions: Begin
   For J:=0 To 2 Do Begin Line(X+2,Y+3+J*5,X+14,Y+3+J*5);Rectangle(X+4+J*3,Y+1+J*5,X+6+J*3,Y+5+J*5);End;
  End;
  rgSort: Begin
   OutTextXY(X,Y,'A');OutTextXY(X,Y+8,'Z');SetColor(Accent);
   Line(X+12,Y+1,X+12,Y+14);Line(X+9,Y+11,X+12,Y+14);Line(X+15,Y+11,X+12,Y+14);
  End;
  rgFilter: Begin
   Line(X+1,Y+2,X+14,Y+2);Line(X+1,Y+2,X+6,Y+8);Line(X+14,Y+2,X+9,Y+8);
   Line(X+6,Y+8,X+6,Y+14);Line(X+9,Y+8,X+9,Y+12);Line(X+6,Y+14,X+9,Y+12);
  End;
  rgHelp,rgAbout: Begin
   Circle(X+8,Y+8,7);SetColor(Accent);
   If Glyph=rgAbout Then Begin Line(X+8,Y+7,X+8,Y+11);Line(X+8,Y+4,X+8,Y+5);End
   Else Begin Line(X+5,Y+4,X+10,Y+4);Line(X+10,Y+4,X+10,Y+7);
    Line(X+10,Y+7,X+8,Y+9);Line(X+8,Y+9,X+8,Y+10);Line(X+8,Y+12,X+8,Y+13);End;
  End;
 End;
End;


Procedure DrawRibbon;
Var I,Item,X,Y,W,H,Color: Integer; S: String;
Begin
 FillBox(0,MENUBAR_H,SCR_W-1,MENUBAR_H+RIBBON_H-1,CLR_WIN_BG);
 For I:=1 To RibbonItemCount Do Begin
  Item:=RibbonMenuItem(I);RibbonButtonBox(I,X,Y,W,H);
  Color:=CLR_TEXT;
  If Not MenuCommandEnabled(RibbonTab,Item) Then Color:=CLR_WIN_DARK
  Else If (RibbonHover=I) Or (RibbonKeyboard And (RibbonFocus=I)) Then Begin
   FillBox(X,Y,X+W-5,Y+H-3,CLR_HEADER_SEL);Color:=CLR_WIN_LIGHT;
  End;
  S:=RibbonCaption(MenuItemLabel(RibbonTab,Item));
  DrawRibbonCommandIcon(RibbonTab,Item,X+5,Y+2,Color);
  If Length(S)>20 Then S:=Copy(S,1,17)+'...';
  TextAt(X+27,Y+6,Color,S);
 End;
 SetColor(CLR_WIN_DARK);Line(4,MENUBAR_H+71,SCR_W-5,MENUBAR_H+71);
 TextAt(6,MENUBAR_H+RIBBON_H-10,CLR_WIN_DARK,'Acces rapide');
 TextAt(SCR_W-190,MENUBAR_H+RIBBON_H-10,CLR_WIN_DARK,RibbonCaption(MenuBarLabel(RibbonTab)));
End;

Procedure DrawToolbar;
Var I, X, Y: Integer;
Begin
 If RibbonMode Then DrawRibbon;
 Y := ToolbarTop;
 FillBox(0, Y, SCR_W - 1, Y + CLASSIC_TOOLBAR_H - 1, CLR_WIN_BG);
 SetColor(CLR_WIN_DARK);
 Line(0, Y + CLASSIC_TOOLBAR_H - 1, SCR_W - 1, Y + CLASSIC_TOOLBAR_H - 1);
 For I := 1 To TOOL_COUNT Do Begin
  X := ToolBoxX(I);
  If Not RibbonMode Then
   DrawRaisedFrame(X, Y + 2, X + TOOL_ICON_W - 1, Y + 2 + TOOL_ICON_H - 1);
  If RibbonMode And RibbonKeyboard And (RibbonFocus=RibbonItemCount+I) Then
   FillBox(X+1,Y+3,X+TOOL_ICON_W-2,Y+TOOL_ICON_H,CLR_TOOL_HOT);
  If RibbonMode And (I=TI_SUM) Then TextAt(X+7,Y+7,CLR_WIN_DARK,'S')
  Else DrawIcon(I, X, Y + 2);
 End;
End;

{ ====================================================================== }
{                       BARRE DE FORMULE                                 }
{ ====================================================================== }

Procedure DrawFormulaBar;
Var Y, NameW: Integer; Sh: PSheet; Ref: String; C: TCell;
Begin
 Y := MENUBAR_H + TOOLBAR_H;
 FillBox(0, Y, SCR_W - 1, Y + FORMULABAR_H - 1, CLR_WIN_BG);
 SetColor(CLR_WIN_DARK);
 Line(0, Y + FORMULABAR_H - 1, SCR_W - 1, Y + FORMULABAR_H - 1);
 Sh := ActiveSheet;
 { Zone "Name Box" }
 NameW := 64;
 FillBox(2, Y + 2, NameW, Y + FORMULABAR_H - 3, CLR_WIN_LIGHT);
 DrawSunkenFrame(2, Y + 2, NameW, Y + FORMULABAR_H - 3);
 Ref := CellRef(Sh^.CurRow, Sh^.CurCol);
 TextAt(8, Y + 6, CLR_TEXT, Ref);
 { Petit "=" decoratif }
 SetFillStyle(1, CLR_WIN_BG);
 Bar(NameW + 4, Y + 2, NameW + 22, Y + FORMULABAR_H - 3);
 TextAt(NameW + 8, Y + 6, CLR_TEXT, 'fx');
 { Zone de formule }
 FillBox(NameW + 26, Y + 2, SCR_W - 4, Y + FORMULABAR_H - 3, CLR_WIN_LIGHT);
 DrawSunkenFrame(NameW + 26, Y + 2, SCR_W - 4, Y + FORMULABAR_H - 3);
 If InputMode Then
  TextAt(NameW + 32, Y + 6, CLR_TEXT, InputBuf)
 Else Begin
  C := GetCellRef(Sh, Sh^.CurRow, Sh^.CurCol);
  If C.Kind = ckFormula Then Begin
   If C.Formula <> Nil Then TextAt(NameW + 32, Y + 6, CLR_TEXT, C.Formula^);
  End Else
   TextAt(NameW + 32, Y + 6, CLR_TEXT, C.Text);
 End;
End;

{ ====================================================================== }
{                       EN-TETES + GRILLE                                }
{ ====================================================================== }

Function CurSheet: PSheet;
Begin CurSheet := WB.Sheets[WB.Active]; End;

Function ColumnXOf(Sh: PSheet; C: Integer): Integer;
Var I, X: Integer;
Begin
 X := GRID_LEFT;
 For I := Sh^.ScrollCol To C - 1 Do X := X + Sh^.ColW[I];
 ColumnXOf := X;
End;

Function RowYOf(Sh: PSheet; R: Integer): Integer;
Var I, Y: Integer;
Begin
 Y := GRID_TOP;
 For I := Sh^.ScrollRow To R - 1 Do Y := Y + Sh^.RowH[I];
 RowYOf := Y;
End;

Function LastVisibleCol(Sh: PSheet): Integer;
Var X, C: Integer;
Begin
 X := GRID_LEFT;
 C := Sh^.ScrollCol;
 While (C < MAX_COLS) And (X < GRID_RIGHT) Do Begin
  X := X + Sh^.ColW[C];
  Inc(C);
 End;
 LastVisibleCol := C - 1;
End;

Function LastVisibleRow(Sh: PSheet): Integer;
Var Y, R: Integer;
Begin
 Y := GRID_TOP;
 R := Sh^.ScrollRow;
 While (R < MAX_ROWS) And (Y < GRID_BOTTOM) Do Begin
  Y := Y + Sh^.RowH[R];
  Inc(R);
 End;
 LastVisibleRow := R - 1;
End;

Procedure DrawColHeaders;
Var Sh: PSheet; X, X2, C, LastC: Integer; S: String; Sel: Boolean;
Begin
 Sh := ActiveSheet;
 FillBox(0, GRID_TOP - COLHEADER_H, SCR_W - 1, GRID_TOP - 1, CLR_HEADER_BG);
 { Coin haut-gauche }
 FillBox(0, GRID_TOP - COLHEADER_H, GRID_LEFT - 1, GRID_TOP - 1, CLR_HEADER_BG);
 DrawRaisedFrame(0, GRID_TOP - COLHEADER_H, GRID_LEFT - 1, GRID_TOP - 1);
 LastC := LastVisibleCol(Sh);
 X := GRID_LEFT;
 For C := Sh^.ScrollCol To LastC Do Begin
  X2 := X + Sh^.ColW[C] - 1;
  If X2 > GRID_RIGHT Then X2 := GRID_RIGHT;
  Sel := (C >= Sh^.SelC1) And (C <= Sh^.SelC2);
  If Sel Then FillBox(X, GRID_TOP - COLHEADER_H, X2, GRID_TOP - 1, CLR_TAB_ACTIVE)
         Else FillBox(X, GRID_TOP - COLHEADER_H, X2, GRID_TOP - 1, CLR_HEADER_BG);
  DrawRaisedFrame(X, GRID_TOP - COLHEADER_H, X2, GRID_TOP - 1);
  S := ColName(C);
  TextAt(X + (Sh^.ColW[C] - Length(S) * 8) Div 2, GRID_TOP - COLHEADER_H + 4,
         CLR_TEXT, S);
  X := X2 + 1;
  If X > GRID_RIGHT Then Break;
 End;
End;

Procedure DrawRowHeaders;
Var Sh: PSheet; Y, Y2, R, LastR: Integer; S: String; Sel: Boolean;
Begin
 Sh := ActiveSheet;
 FillBox(0, GRID_TOP, GRID_LEFT - 1, GRID_BOTTOM, CLR_HEADER_BG);
 LastR := LastVisibleRow(Sh);
 Y := GRID_TOP;
 For R := Sh^.ScrollRow To LastR Do Begin
  Y2 := Y + Sh^.RowH[R] - 1;
  If Y2 > GRID_BOTTOM Then Y2 := GRID_BOTTOM;
  Sel := (R >= Sh^.SelR1) And (R <= Sh^.SelR2);
  If Sel Then FillBox(0, Y, GRID_LEFT - 1, Y2, CLR_TAB_ACTIVE)
         Else FillBox(0, Y, GRID_LEFT - 1, Y2, CLR_HEADER_BG);
  DrawRaisedFrame(0, Y, GRID_LEFT - 1, Y2);
  S := IntToStr(R + 1);
  TextAt(GRID_LEFT - 4 - Length(S) * 8, Y + (Sh^.RowH[R] - 8) Div 2,
         CLR_TEXT, S);
  Y := Y2 + 1;
  If Y > GRID_BOTTOM Then Break;
 End;
End;

Function FormatNumber(N: Double; Fmt: Byte): String;
Var S: String; I, Days, Y, M, D, Mo: Integer; YY: LongInt; F: Double;
Begin
 Case Fmt Of
  FMT_PERCENT  : Begin Str(N * 100.0:0:2, S); S := S + '%'; End;
  FMT_CURRENCY : Begin Str(N:0:2, S);
                       I := Pos('.', S);
                       If I > 0 Then S[I] := ',';
                       S := S + ' $'; End;
  FMT_NUMBER   : Begin Str(N:0:2, S);
                       I := Pos('.', S);
                       If I > 0 Then S[I] := ','; End;
  FMT_DATE     : Begin
                  { Serie Excel : 1=1900-01-01 (bug 1900 inclus) }
                  Days := Trunc(N);
                  If Days < 1 Then S := DoubleToCellStr(N)
                  Else Begin
                   YY := 1900;
                   { Diminuer 1 car serie 1=1/1/1900 }
                   Dec(Days);
                   While True Do Begin
                    If ((YY Mod 4 = 0) And (YY Mod 100 <> 0)) Or (YY Mod 400 = 0) Then F := 366 Else F := 365;
                    If Days < F Then Break;
                    Days := Days - Trunc(F);
                    Inc(YY);
                   End;
                   Mo := 1;
                   While True Do Begin
                    Case Mo Of
                     1, 3, 5, 7, 8, 10, 12: D := 31;
                     4, 6, 9, 11: D := 30;
                     Else If ((YY Mod 4 = 0) And (YY Mod 100 <> 0)) Or (YY Mod 400 = 0) Then D := 29 Else D := 28;
                    End;
                    If Days < D Then Break;
                    Days := Days - D;
                    Inc(Mo);
                    If Mo > 12 Then Begin Mo := 1; Inc(YY); End;
                   End;
                   S := IntToStr(Days + 1) + '/' + IntToStr(Mo) + '/' + IntToStr(YY);
                  End;
                 End;
  FMT_TEXT     : S := DoubleToCellStr(N);
  Else { FMT_GENERAL } S := DoubleToCellStr(N);
 End;
 FormatNumber := S;
End;

Procedure DrawCellContent(Sh: PSheet; R, C, X, Y, W, H: Integer);
Var Cell: TCell; S: String; Tx, Ty: Integer; SW: Integer; Fg: Integer; ULen: Integer;
    I, Ofs: Integer; Ch: Char;
Begin
 Cell := GetCellRef(Sh, R, C);
 { Fond colore si Bg <> 0 }
 If Cell.Bg <> 0 Then
  FillBox(X + 1, Y + 1, X + W - 1, Y + H - 1, Cell.Bg);
 If Cell.Kind = ckEmpty Then Exit;
 { Texte affiche : nombre formate ou texte brut }
 If (Cell.Kind = ckNumber) And (Cell.Format <> FMT_GENERAL) And (Cell.Format <> FMT_TEXT) Then
  S := FormatNumber(Cell.Num, Cell.Format)
 Else
  S := Cell.Text;
 If Length(S) = 0 Then Exit;
 If Length(S) * 8 > W - 4 Then S := Copy(S, 1, MaxI(1, (W - 4) Div 8));
 SW := Length(S) * 8;
 Ty := Y + (H - 8) Div 2;
 Case Cell.Align Of
  AL_CENTER : Tx := X + (W - SW) Div 2;
  AL_RIGHT  : Tx := X + W - SW - 2;
  AL_LEFT   : Tx := X + 2;
  Else
   If Cell.Kind = ckNumber Then Tx := X + W - SW - 2
                            Else Tx := X + 2;
 End;
 If Cell.Fg <> 0 Then Fg := Cell.Fg Else Fg := CLR_TEXT;
 { Italique : decalage progressif (skew gauche-droite) }
 If (Cell.Style And STY_ITALIC) <> 0 Then Begin
  SetColor(Fg);
  For I := 1 To Length(S) Do Begin
   Ch := S[I];
   Ofs := (8 - (Ty Mod 8)) Div 4; { petit biais visuel }
   OutTextXY(Tx + (I - 1) * 8 + 1, Ty, Ch);
   If (Cell.Style And STY_BOLD) <> 0 Then
    OutTextXY(Tx + (I - 1) * 8 + 2, Ty, Ch);
  End;
 End Else If (Cell.Style And STY_BOLD) <> 0 Then
  TextBoldAt(Tx, Ty, Fg, S)
 Else
  TextAt(Tx, Ty, Fg, S);
 { Soulignement }
 If (Cell.Style And STY_UNDERLINE) <> 0 Then Begin
  SetColor(Fg);
  ULen := SW;
  Line(Tx, Ty + 8, Tx + ULen - 1, Ty + 8);
 End;
End;

Procedure DrawGrid;
Var Sh: PSheet; X, Y, X2, Y2, R, C, LastR, LastC: Integer;
Begin
 Sh := ActiveSheet;
 FillBox(GRID_LEFT, GRID_TOP, GRID_RIGHT, GRID_BOTTOM, CLR_WIN_LIGHT);
 LastR := LastVisibleRow(Sh);
 LastC := LastVisibleCol(Sh);
 SetColor(CLR_GRID);
 { Lignes horizontales }
 Y := GRID_TOP;
 For R := Sh^.ScrollRow To LastR Do Begin
  Y := Y + Sh^.RowH[R];
  If Y > GRID_BOTTOM Then Break;
  Line(GRID_LEFT, Y, GRID_RIGHT, Y);
 End;
 { Lignes verticales }
 X := GRID_LEFT;
 For C := Sh^.ScrollCol To LastC Do Begin
  X := X + Sh^.ColW[C];
  If X > GRID_RIGHT Then Break;
  Line(X, GRID_TOP, X, GRID_BOTTOM);
 End;
 { Contenu des cellules }
 Y := GRID_TOP;
 For R := Sh^.ScrollRow To LastR Do Begin
  Y2 := Y + Sh^.RowH[R] - 1;
  If Y2 > GRID_BOTTOM Then Y2 := GRID_BOTTOM;
  X := GRID_LEFT;
  For C := Sh^.ScrollCol To LastC Do Begin
   X2 := X + Sh^.ColW[C] - 1;
   If X2 > GRID_RIGHT Then X2 := GRID_RIGHT;
   DrawCellContent(Sh, R, C, X, Y, Sh^.ColW[C], Sh^.RowH[R]);
   X := X2 + 1;
   If X > GRID_RIGHT Then Break;
  End;
  Y := Y2 + 1;
  If Y > GRID_BOTTOM Then Break;
 End;
End;

Procedure DrawSelection;
Var Sh: PSheet; X1, Y1, X2, Y2, I: Integer;
    Cx1, Cy1, Cx2, Cy2: Integer;
    R, C: Integer;
    HasRange: Boolean;
Begin
 Sh := ActiveSheet;
 HasRange := (Sh^.SelR1 <> Sh^.SelR2) Or (Sh^.SelC1 <> Sh^.SelC2);
 { Remplissage clair pour la plage selectionnee (sauf cellule active) }
 If HasRange Then Begin
  For R := MaxI(Sh^.SelR1, Sh^.ScrollRow) To MinI(Sh^.SelR2, LastVisibleRow(Sh)) Do
   For C := MaxI(Sh^.SelC1, Sh^.ScrollCol) To MinI(Sh^.SelC2, LastVisibleCol(Sh)) Do
    If (R <> Sh^.CurRow) Or (C <> Sh^.CurCol) Then Begin
     Cx1 := ColumnXOf(Sh, C);
     Cy1 := RowYOf(Sh, R);
     Cx2 := Cx1 + Sh^.ColW[C] - 1;
     Cy2 := Cy1 + Sh^.RowH[R] - 1;
     If Cx2 > GRID_RIGHT Then Cx2 := GRID_RIGHT;
     If Cy2 > GRID_BOTTOM Then Cy2 := GRID_BOTTOM;
     If (Cx1 <= GRID_RIGHT) And (Cy1 <= GRID_BOTTOM) Then Begin
      FillBox(Cx1 + 1, Cy1 + 1, Cx2, Cy2, CLR_SEL_FILL);
      { Redessiner le contenu sur fond colore }
      DrawCellContent(Sh, R, C, Cx1, Cy1, Sh^.ColW[C], Sh^.RowH[R]);
     End;
    End;
 End;
 { Cellule active (cadre fonce) }
 If (Sh^.CurCol < Sh^.ScrollCol) Or (Sh^.CurRow < Sh^.ScrollRow) Then Exit;
 X1 := ColumnXOf(Sh, Sh^.CurCol);
 Y1 := RowYOf(Sh, Sh^.CurRow);
 X2 := X1 + Sh^.ColW[Sh^.CurCol] - 1;
 Y2 := Y1 + Sh^.RowH[Sh^.CurRow] - 1;
 If (X1 > GRID_RIGHT) Or (Y1 > GRID_BOTTOM) Then Exit;
 If X2 > GRID_RIGHT Then X2 := GRID_RIGHT;
 If Y2 > GRID_BOTTOM Then Y2 := GRID_BOTTOM;
 { Cadre epais autour de toute la plage selectionnee }
 If HasRange Then Begin
  Cx1 := ColumnXOf(Sh, MaxI(Sh^.SelC1, Sh^.ScrollCol));
  Cy1 := RowYOf  (Sh, MaxI(Sh^.SelR1, Sh^.ScrollRow));
  Cx2 := X2;
  Cy2 := Y2;
  For C := MaxI(Sh^.SelC1, Sh^.ScrollCol) To MinI(Sh^.SelC2, LastVisibleCol(Sh)) Do
   Cx2 := MaxI(Cx2, ColumnXOf(Sh, C) + Sh^.ColW[C] - 1);
  For R := MaxI(Sh^.SelR1, Sh^.ScrollRow) To MinI(Sh^.SelR2, LastVisibleRow(Sh)) Do
   Cy2 := MaxI(Cy2, RowYOf(Sh, R) + Sh^.RowH[R] - 1);
  If Cx2 > GRID_RIGHT Then Cx2 := GRID_RIGHT;
  If Cy2 > GRID_BOTTOM Then Cy2 := GRID_BOTTOM;
  SetColor(CLR_SEL_BORDER);
  For I := 0 To 1 Do Rectangle(Cx1 + I, Cy1 + I, Cx2 - I, Cy2 - I);
  FillBox(Cx2 - 2, Cy2 - 2, Cx2 + 1, Cy2 + 1, CLR_SEL_BORDER);
 End Else Begin
  SetColor(CLR_SEL_BORDER);
  For I := 0 To 1 Do Rectangle(X1 + I, Y1 + I, X2 - I, Y2 - I);
  FillBox(X2 - 2, Y2 - 2, X2 + 1, Y2 + 1, CLR_SEL_BORDER);
 End;
 { Marching ants sur la source coupee (statique : pointilles) }
 If Clip.Valid And Clip.CutMode And (Clip.CutSheet = WB.Active) Then Begin
  Cx1 := ColumnXOf(Sh, Clip.CutC);
  Cy1 := RowYOf  (Sh, Clip.CutR);
  Cx2 := Cx1; Cy2 := Cy1;
  For C := Clip.CutC To Clip.CutC + Clip.Cols - 1 Do
   If (C >= Sh^.ScrollCol) And (C < MAX_COLS) Then
    Cx2 := MaxI(Cx2, ColumnXOf(Sh, C) + Sh^.ColW[C] - 1);
  For R := Clip.CutR To Clip.CutR + Clip.Rows - 1 Do
   If (R >= Sh^.ScrollRow) And (R < MAX_ROWS) Then
    Cy2 := MaxI(Cy2, RowYOf(Sh, R) + Sh^.RowH[R] - 1);
  If Cx2 > GRID_RIGHT Then Cx2 := GRID_RIGHT;
  If Cy2 > GRID_BOTTOM Then Cy2 := GRID_BOTTOM;
  SetColor(CLR_ERR);
  SetLineStyle(1, 0, 1); { dotted }
  Rectangle(Cx1, Cy1, Cx2, Cy2);
  SetLineStyle(0, 0, 1);
 End;
End;

{ ====================================================================== }
{                       ONGLETS                                          }
{ ====================================================================== }

Procedure ComputeTabBounds;
Var I, X, W: Integer;
Begin
 X := 24;
 For I := 1 To WB.Count Do Begin
  W := Length(WB.Sheets[I]^.Name) * 8 + 12;
  SheetTabsX1[I] := X;
  SheetTabsX2[I] := X + W;
  X := X + W + 2;
 End;
End;

Procedure DrawTabs;
Var Y, I, X1, X2: Integer; Act: Boolean;
Begin
 Y := SCR_H - TABS_H - STATUSBAR_H;
 FillBox(0, Y, SCR_W - 1, Y + TABS_H - 1, CLR_TAB_BG);
 SetColor(CLR_WIN_DARK);
 Line(0, Y, SCR_W - 1, Y);
 { Boutons navigation onglets <<  <  >  >> }
 SetColor(CLR_TEXT);
 OutTextXY(4,  Y + 6, '|<');
 OutTextXY(20, Y + 6, '<');
 ComputeTabBounds;
 For I := 1 To WB.Count Do Begin
  X1 := SheetTabsX1[I];
  X2 := SheetTabsX2[I];
  Act := (I = WB.Active);
  If Act Then FillBox(X1, Y + 2, X2, Y + TABS_H - 1, CLR_TAB_ACTIVE)
         Else FillBox(X1, Y + 4, X2, Y + TABS_H - 1, CLR_TAB_BG);
  SetColor(CLR_WIN_DARK);
  Line(X1, Y + 2, X1, Y + TABS_H - 1);
  Line(X1, Y + 2, X2, Y + 2);
  Line(X2, Y + 2, X2, Y + TABS_H - 1);
  TextAt(X1 + 6, Y + 6, CLR_TEXT, WB.Sheets[I]^.Name);
 End;
End;

Function TabHitAt(MX, MY: Integer): Integer;
Var Y, I: Integer;
Begin
 TabHitAt := 0;
 Y := SCR_H - TABS_H - STATUSBAR_H;
 If (MY < Y) Or (MY > Y + TABS_H) Then Exit;
 For I := 1 To WB.Count Do
  If (MX >= SheetTabsX1[I]) And (MX <= SheetTabsX2[I]) Then Begin
   TabHitAt := I;
   Exit;
  End;
End;

{ ====================================================================== }
{                       BARRE D'ETAT                                     }
{ ====================================================================== }

Procedure DrawStatusBar;
Var Y: Integer; S, R: String; Sh: PSheet; Rows, Cols: Integer;
Begin
 Y := SCR_H - STATUSBAR_H;
 FillBox(0, Y, SCR_W - 1, SCR_H - 1, CLR_WIN_BG);
 SetColor(CLR_WIN_LIGHT);
 Line(0, Y, SCR_W - 1, Y);
 If InputMode Then S := 'Saisie'
 Else If WB.Modified Then S := 'Modifie'
 Else S := 'Pret';
 TextAt(6, Y + 4, CLR_TEXT, S);
 Sh := ActiveSheet;
 If (Sh^.SelR1 <> Sh^.SelR2) Or (Sh^.SelC1 <> Sh^.SelC2) Then Begin
  Rows := Sh^.SelR2 - Sh^.SelR1 + 1;
  Cols := Sh^.SelC2 - Sh^.SelC1 + 1;
  R := CellRef(Sh^.SelR1, Sh^.SelC1) + ':' + CellRef(Sh^.SelR2, Sh^.SelC2) +
       '  ' + IntToStr(Rows) + 'L x ' + IntToStr(Cols) + 'C';
  TextAt(80, Y + 4, CLR_TEXT, R);
 End;
 If ExtendMode Then TextAt(SCR_W - 170, Y + 4, CLR_ERR, 'EXT');
 TextAt(SCR_W - 6 - TextWidth('F1=Aide  F10=Menu'), Y + 4, CLR_TEXT, 'F1=Aide  F10=Menu');
 { OS/2-0 : titre de la fenetre (nom du classeur) }
 R := WB.FileName;
 While Pos('\', R) > 0 Do Delete(R, 1, Pos('\', R));
 If R = '' Then OsSetTitle('Excelsior') Else OsSetTitle('Excelsior - ' + R);
End;

{ ====================================================================== }
{                       DESSIN COMPLET                                   }
{ ====================================================================== }

{ ---------------------------------------------------------------------- }
{           PHASE 7 : IMAGES BMP 4 bpp ancrees a une cellule             }
{ ---------------------------------------------------------------------- }

Const
 MAX_IMAGES_PER_SHEET = 8;
 MAX_IMG_W            = 320;
 MAX_IMG_H            = 200;
 EGA_RGB : Array[0..15, 0..2] Of Byte = (
  (  0,   0,   0), (  0,   0, 170), (  0, 170,   0), (  0, 170, 170),
  (170,   0,   0), (170,   0, 170), (170,  85,   0), (170, 170, 170),
  ( 85,  85,  85), ( 85,  85, 255), ( 85, 255,  85), ( 85, 255, 255),
  (255,  85,  85), (255,  85, 255), (255, 255,  85), (255, 255, 255)
 );

Type
 PImage = ^TImage;
 TImage = Record
  Anchor_R, Anchor_C : Integer;
  W, H               : Integer;
  Pixels             : Pointer;   { W*H octets, index EGA 0..15 }
 End;

Var
 SheetImages     : Array[1..MAX_SHEETS, 1..MAX_IMAGES_PER_SHEET] Of PImage;
 SheetImageCount : Array[1..MAX_SHEETS] Of Integer;

Function ColorNearest(R, G, B: Byte): Byte;
Var I: Integer; Dist, Best: LongInt; DR, DG, DB: LongInt; BestIdx: Byte;
Begin
 Best := MaxLongInt; BestIdx := 0;
 For I := 0 To 15 Do Begin
  DR := LongInt(R) - EGA_RGB[I, 0];
  DG := LongInt(G) - EGA_RGB[I, 1];
  DB := LongInt(B) - EGA_RGB[I, 2];
  Dist := DR * DR + DG * DG + DB * DB;
  If Dist < Best Then Begin Best := Dist; BestIdx := Byte(I); End;
 End;
 ColorNearest := BestIdx;
End;

Procedure FreeImage(Var Img: PImage);
Begin
 If Img <> Nil Then Begin
  If Img^.Pixels <> Nil Then
   FreeMem(Img^.Pixels, LongInt(Img^.W) * Img^.H);
  Dispose(Img);
  Img := Nil;
 End;
End;

Procedure FreeSheetImages(SheetIdx: Integer);
Var I: Integer;
Begin
 For I := 1 To MAX_IMAGES_PER_SHEET Do FreeImage(SheetImages[SheetIdx, I]);
 SheetImageCount[SheetIdx] := 0;
End;

Procedure FreeAllImages;
Var I: Integer;
Begin
 For I := 1 To MAX_SHEETS Do FreeSheetImages(I);
End;

Procedure CellScreenXY(Sh: PSheet; R, C: Integer; Var X, Y: Integer);
Var I, Ax, Ay: Integer;
Begin
 Ax := GRID_LEFT;
 For I := Sh^.ScrollCol To C - 1 Do Ax := Ax + Sh^.ColW[I];
 Ay := GRID_TOP;
 For I := Sh^.ScrollRow To R - 1 Do Ay := Ay + Sh^.RowH[I];
 X := Ax; Y := Ay;
End;

Procedure DrawImages;
Var Sh: PSheet; I, X, Y, Px, Py: Integer; Img: PImage; PB: ^Byte;
    Ofs: LongInt;
Begin
 Sh := ActiveSheet;
 For I := 1 To SheetImageCount[WB.Active] Do Begin
  Img := SheetImages[WB.Active, I];
  If Img = Nil Then Continue;
  If (Img^.Anchor_R < Sh^.ScrollRow) Or
     (Img^.Anchor_C < Sh^.ScrollCol) Then Continue;
  CellScreenXY(Sh, Img^.Anchor_R, Img^.Anchor_C, X, Y);
  For Py := 0 To Img^.H - 1 Do Begin
   If (Y + Py < GRID_TOP) Or (Y + Py > GRID_BOTTOM) Then Continue;
   Ofs := LongInt(Py) * Img^.W;
   PB := Img^.Pixels; Inc(PB, Ofs);
   For Px := 0 To Img^.W - 1 Do Begin
    If (X + Px >= GRID_LEFT) And (X + Px <= GRID_RIGHT) Then
     PutPixel(X + Px, Y + Py, PB^);
    Inc(PB);
   End;
  End;
 End;
End;

{ ---------------------------------------------------------------------- }
{           PHASE 8 : GRAPHIQUES (barres / lignes / secteurs)            }
{ ---------------------------------------------------------------------- }

Const
 MAX_CHARTS_PER_SHEET = 4;
 MAX_CHART_PTS        = 64;

Type
 TChartKind = (chBar, chLine, chPie);
 PChart = ^TChart;
 TChart = Record
  Kind             : TChartKind;
  Anchor_R, Anchor_C : Integer;
  W, H             : Integer;
  R1, C1, R2, C2   : Integer;
  Title            : String[32];
 End;

Var
 SheetCharts     : Array[1..MAX_SHEETS, 1..MAX_CHARTS_PER_SHEET] Of PChart;
 SheetChartCount : Array[1..MAX_SHEETS] Of Integer;

Procedure FreeChart(Var Ch: PChart);
Begin
 If Ch <> Nil Then Begin Dispose(Ch); Ch := Nil; End;
End;

Procedure FreeSheetCharts(SheetIdx: Integer);
Var I: Integer;
Begin
 For I := 1 To MAX_CHARTS_PER_SHEET Do FreeChart(SheetCharts[SheetIdx, I]);
 SheetChartCount[SheetIdx] := 0;
End;

Procedure FreeAllCharts;
Var I: Integer;
Begin
 For I := 1 To MAX_SHEETS Do FreeSheetCharts(I);
End;

Procedure CollectChartValues(Sh: PSheet; Ch: PChart;
                             Var Vals: Array Of Double; Var N: Integer);
Var R, C: Integer; Cell: TCell;
Begin
 N := 0;
 For R := Ch^.R1 To Ch^.R2 Do
  For C := Ch^.C1 To Ch^.C2 Do Begin
   Cell := GetCellRef(Sh, R, C);
   If Cell.Kind = ckNumber Then Begin
    If N < MAX_CHART_PTS Then Begin Vals[N] := Cell.Num; Inc(N); End;
   End Else If Cell.Kind = ckFormula Then Begin
    If (Length(Cell.Text) = 0) Or (Cell.Text[1] <> '#') Then
     If N < MAX_CHART_PTS Then Begin Vals[N] := Cell.Num; Inc(N); End;
   End;
  End;
End;

Procedure DrawChart(Sh: PSheet; Ch: PChart);
Var X, Y, X2, Y2: Integer;
    PlotL, PlotR, PlotT, PlotB: Integer;
    Vals: Array[0..MAX_CHART_PTS - 1] Of Double;
    N, I: Integer;
    VMin, VMax, V, Range_: Double;
    BarW, BarStep, Px, Py, BarBottom: Integer;
    Cx, Cy, Radius, A1, A2: Integer;
    Sum, Cur, Sweep: Double;
    Color: Integer;
    SaveX, SaveY: Integer;
Begin
 CellScreenXY(Sh, Ch^.Anchor_R, Ch^.Anchor_C, X, Y);
 X2 := X + Ch^.W; Y2 := Y + Ch^.H;
 If (X > GRID_RIGHT) Or (Y > GRID_BOTTOM) Then Exit;
 If X2 > GRID_RIGHT Then X2 := GRID_RIGHT;
 If Y2 > GRID_BOTTOM Then Y2 := GRID_BOTTOM;
 FillBox(X, Y, X2, Y2, CLR_WIN_LIGHT);
 DrawRaisedFrame(X, Y, X2, Y2);
 If Length(Ch^.Title) > 0 Then
  TextAt(X + 6, Y + 3, CLR_TEXT, Ch^.Title);
 PlotL := X + 10; PlotR := X2 - 6;
 PlotT := Y + 14; PlotB := Y2 - 6;
 CollectChartValues(Sh, Ch, Vals, N);
 If N = 0 Then Begin
  TextAt(X + 6, Y + 20, CLR_ERR, '(aucune donnee)');
  Exit;
 End;
 Case Ch^.Kind Of
  chBar, chLine: Begin
   VMin := Vals[0]; VMax := Vals[0];
   For I := 1 To N - 1 Do Begin
    If Vals[I] < VMin Then VMin := Vals[I];
    If Vals[I] > VMax Then VMax := Vals[I];
   End;
   If VMin > 0 Then VMin := 0;
   If VMax < 0 Then VMax := 0;
   Range_ := VMax - VMin;
   If Range_ < 1e-12 Then Range_ := 1;
   BarBottom := PlotB - Round((0 - VMin) / Range_ * (PlotB - PlotT));
   SetColor(CLR_WIN_DARK);
   Line(PlotL, BarBottom, PlotR, BarBottom);
   Line(PlotL, PlotT, PlotL, PlotB);
   If Ch^.Kind = chBar Then Begin
    BarStep := (PlotR - PlotL) Div N;
    If BarStep < 2 Then BarStep := 2;
    BarW := BarStep - 1;
    If BarW < 1 Then BarW := 1;
    For I := 0 To N - 1 Do Begin
     V := Vals[I];
     Px := PlotL + I * BarStep + 1;
     Py := PlotB - Round((V - VMin) / Range_ * (PlotB - PlotT));
     Color := 2 + (I Mod 13);
     If Color > 14 Then Color := 14;
     If V >= 0 Then FillBox(Px, Py, Px + BarW - 1, BarBottom, Color)
     Else FillBox(Px, BarBottom, Px + BarW - 1, Py, Color);
    End;
   End Else Begin
    SetColor(4);
    SaveX := -1; SaveY := -1;
    For I := 0 To N - 1 Do Begin
     V := Vals[I];
     If N > 1 Then
      Px := PlotL + Round(I * (PlotR - PlotL) / (N - 1))
     Else Px := (PlotL + PlotR) Div 2;
     Py := PlotB - Round((V - VMin) / Range_ * (PlotB - PlotT));
     If SaveX >= 0 Then Line(SaveX, SaveY, Px, Py);
     FillBox(Px - 1, Py - 1, Px + 1, Py + 1, 4);
     SaveX := Px; SaveY := Py;
    End;
   End;
  End;
  chPie: Begin
   Sum := 0;
   For I := 0 To N - 1 Do If Vals[I] > 0 Then Sum := Sum + Vals[I];
   If Sum < 1e-12 Then Begin
    TextAt(X + 6, Y + 20, CLR_ERR, '(valeurs nulles ou negatives)');
    Exit;
   End;
   Cx := (PlotL + PlotR) Div 2;
   Cy := (PlotT + PlotB) Div 2;
   Radius := (PlotB - PlotT) Div 2 - 2;
   If (PlotR - PlotL) Div 2 - 2 < Radius Then
    Radius := (PlotR - PlotL) Div 2 - 2;
   If Radius < 6 Then Radius := 6;
   Cur := 0;
   For I := 0 To N - 1 Do Begin
    If Vals[I] <= 0 Then Continue;
    Sweep := Vals[I] / Sum * 360;
    A1 := Round(Cur);
    A2 := Round(Cur + Sweep);
    Color := 2 + (I Mod 13);
    If Color > 14 Then Color := 14;
    SetFillStyle(1, Color);
    SetColor(CLR_TEXT);
    PieSlice(Cx, Cy, A1, A2, Radius);
    Cur := Cur + Sweep;
   End;
  End;
 End;
End;

Procedure DrawCharts;
Var Sh: PSheet; I: Integer; Ch: PChart;
Begin
 Sh := ActiveSheet;
 For I := 1 To SheetChartCount[WB.Active] Do Begin
  Ch := SheetCharts[WB.Active, I];
  If Ch = Nil Then Continue;
  If (Ch^.Anchor_R < Sh^.ScrollRow) Or
     (Ch^.Anchor_C < Sh^.ScrollCol) Then Continue;
  DrawChart(Sh, Ch);
 End;
End;

Procedure DrawAll;
Begin
 HideMouse;
 DrawMenuBar;
 DrawToolbar;
 DrawFormulaBar;
 DrawColHeaders;
 DrawRowHeaders;
 DrawGrid;
 DrawImages;
 DrawCharts;
 DrawSelection;
 DrawTabs;
 DrawStatusBar;
 If (MenuOpen > 0) And Not RibbonMode Then DrawDropDown(MenuOpen);
 ShowMouse;
End;

{ ====================================================================== }
{                       HIT-TESTING DANS LA GRILLE                       }
{ ====================================================================== }

Function GridHitCol(Sh: PSheet; MX: Integer): Integer;
Var X, C, LastC: Integer;
Begin
 GridHitCol := -1;
 If MX < GRID_LEFT Then Exit;
 LastC := LastVisibleCol(Sh);
 X := GRID_LEFT;
 For C := Sh^.ScrollCol To LastC Do Begin
  If (MX >= X) And (MX < X + Sh^.ColW[C]) Then Begin
   GridHitCol := C;
   Exit;
  End;
  X := X + Sh^.ColW[C];
 End;
End;

Function GridHitRow(Sh: PSheet; MY: Integer): Integer;
Var Y, R, LastR: Integer;
Begin
 GridHitRow := -1;
 If MY < GRID_TOP Then Exit;
 LastR := LastVisibleRow(Sh);
 Y := GRID_TOP;
 For R := Sh^.ScrollRow To LastR Do Begin
  If (MY >= Y) And (MY < Y + Sh^.RowH[R]) Then Begin
   GridHitRow := R;
   Exit;
  End;
  Y := Y + Sh^.RowH[R];
 End;
End;

{ ====================================================================== }
{                       NAVIGATION CURSEUR                               }
{ ====================================================================== }

Procedure EnsureVisible;
Var Sh: PSheet; LastR, LastC: Integer;
Begin
 Sh := ActiveSheet;
 If Sh^.CurCol < Sh^.ScrollCol Then Sh^.ScrollCol := Sh^.CurCol;
 If Sh^.CurRow < Sh^.ScrollRow Then Sh^.ScrollRow := Sh^.CurRow;
 LastC := LastVisibleCol(Sh);
 While Sh^.CurCol > LastC Do Begin
  Inc(Sh^.ScrollCol);
  LastC := LastVisibleCol(Sh);
  If Sh^.ScrollCol >= MAX_COLS - 1 Then Break;
 End;
 LastR := LastVisibleRow(Sh);
 While Sh^.CurRow > LastR Do Begin
  Inc(Sh^.ScrollRow);
  LastR := LastVisibleRow(Sh);
  If Sh^.ScrollRow >= MAX_ROWS - 1 Then Break;
 End;
End;

Procedure SetCursorEx(R, C: Integer; KeepSel: Boolean);
Var Sh: PSheet;
Begin
 Sh := ActiveSheet;
 If R < 0 Then R := 0; If R >= MAX_ROWS Then R := MAX_ROWS - 1;
 If C < 0 Then C := 0; If C >= MAX_COLS Then C := MAX_COLS - 1;
 Sh^.CurRow := R; Sh^.CurCol := C;
 If KeepSel Then Begin
  If R >= SelAnchorR Then Begin Sh^.SelR1 := SelAnchorR; Sh^.SelR2 := R; End
                     Else Begin Sh^.SelR1 := R; Sh^.SelR2 := SelAnchorR; End;
  If C >= SelAnchorC Then Begin Sh^.SelC1 := SelAnchorC; Sh^.SelC2 := C; End
                     Else Begin Sh^.SelC1 := C; Sh^.SelC2 := SelAnchorC; End;
 End Else Begin
  Sh^.SelR1 := R; Sh^.SelR2 := R;
  Sh^.SelC1 := C; Sh^.SelC2 := C;
  SelAnchorR := R; SelAnchorC := C;
 End;
 EnsureVisible;
 NeedFullRedraw := True;
End;

Procedure SetCursor(R, C: Integer);
Begin SetCursorEx(R, C, False); End;

Procedure MoveCursor(DR, DC: Integer);
Var Sh: PSheet;
Begin
 Sh := ActiveSheet;
 SetCursorEx(Sh^.CurRow + DR, Sh^.CurCol + DC, ExtendMode);
End;

{ ====================================================================== }
{                       EDITION (PHASE 1 : saisie inline simple)          }
{ ====================================================================== }

Procedure StartInput(Initial: String);
Begin
 InputMode := True;
 InputBuf := Initial;
 InputBufPos := Length(Initial) + 1;
End;

Procedure CancelInput;
Begin
 InputMode := False;
 InputBuf := '';
End;

Procedure CommitInput(MoveDown: Boolean);
Var Sh: PSheet;
Begin
 Sh := ActiveSheet;
 SetCellText(Sh, Sh^.CurRow, Sh^.CurCol, InputBuf);
 WB.Modified := True;
 InputMode := False;
 InputBuf := '';
 RecalcWorkbook;
 If MoveDown Then MoveCursor(1, 0);
End;

Procedure EditCurrentCell;
Var Sh: PSheet; C: TCell; S: String;
Begin
 Sh := ActiveSheet;
 C := GetCellRef(Sh, Sh^.CurRow, Sh^.CurCol);
 If C.Kind = ckFormula Then
  If C.Formula <> Nil Then S := C.Formula^ Else S := ''
 Else
  S := C.Text;
 StartInput(S);
End;

{ ====================================================================== }
{                       SOURIS (helpers)                                 }
{ ====================================================================== }

Procedure UpdateMouse;
Begin
 LastClickB := Mouse.B;
 GetMouseState(Mouse.X, Mouse.Y, Mouse.B);
End;

Function LeftPressed: Boolean;
Begin LeftPressed := ((Mouse.B And 1) <> 0) And ((LastClickB And 1) = 0); End;

Function RightPressed: Boolean;
Begin RightPressed := ((Mouse.B And 2) <> 0) And ((LastClickB And 2) = 0); End;

{ ====================================================================== }
{                       ACTIONS DE MENU                                  }
{ ====================================================================== }

Procedure ActionNew;
Var I: Integer;
Begin
 FreeAllImages;
 FreeAllCharts;
 For I := 1 To WB.Count Do If WB.Sheets[I] <> Nil Then Begin
  { liberer toutes les lignes allouees }
  { (geste minimal : on laisse le GC implicite a la fin) }
 End;
 InitWorkbook;
 NeedFullRedraw := True;
End;

{ Image "L'univers des cellules" : grille en perspective, cellules
  allumees, nombres et symboles, histogramme 3D qui s'eleve de la grille }
Procedure DrawAboutArt(AX1, AY1, AX2, AY2: Integer);
Const
 NR = 10;
Var
 W, Hh, HZ, GH, VX, I, K, T, Y, Y2, XL: Integer;
 Seed: LongInt;
 Pts: Array[1..4] Of PointType;
 BarH: Array[1..5] Of Integer;
 BarF, BarS: Array[1..5] Of Integer;
 TxK, TxT, TxC: Array[1..8] Of Integer;
 TxS: Array[1..8] Of String[5];
 Bw, Bx, By, Dx, Dy: Integer;

 Function RowY(R: Integer): Integer;
 Begin RowY := HZ + (GH * R * R) Div (NR * NR); End;

 Function WAt(Yy: Integer): Integer;
 Begin WAt := 6 + (50 * (Yy - HZ)) Div GH; End;

 Function CellX(Kk, Yy: Integer): Integer;
 Begin CellX := VX + Kk * WAt(Yy); End;

 Function CellOk(Kk, R: Integer): Boolean;
 Var A, B: Integer;
 Begin
  A := CellX(Kk, RowY(R + 1)); B := CellX(Kk + 1, RowY(R + 1));
  CellOk := (A >= 2) And (B <= W - 3) And
            (CellX(Kk, RowY(R)) >= 2) And (CellX(Kk + 1, RowY(R)) <= W - 3);
 End;

 Procedure Quad(Kk, R, Color: Integer);
 Begin
  Pts[1].X := AX1 + CellX(Kk, RowY(R));     Pts[1].Y := AY1 + RowY(R);
  Pts[2].X := AX1 + CellX(Kk + 1, RowY(R)); Pts[2].Y := AY1 + RowY(R);
  Pts[3].X := AX1 + CellX(Kk + 1, RowY(R + 1)); Pts[3].Y := AY1 + RowY(R + 1);
  Pts[4].X := AX1 + CellX(Kk, RowY(R + 1)); Pts[4].Y := AY1 + RowY(R + 1);
  SetFillStyle(1, Color);
  FillPoly(4, Pts);
 End;

Begin
 W := AX2 - AX1; Hh := AY2 - AY1; HZ := 62; GH := Hh - HZ - 1; VX := W Div 2;
 { ciel : bandes sombres, halo a l'horizon }
 FillBox(AX1, AY1, AX2, AY1 + 24, 0);
 FillBox(AX1, AY1 + 25, AX2, AY1 + 44, 1);
 FillBox(AX1, AY1 + 45, AX2, AY1 + HZ - 6, 9);
 FillBox(AX1, AY1 + HZ - 5, AX2, AY1 + HZ, 11);
 FillBox(AX1, AY1 + HZ + 1, AX2, AY2, 0);
 Seed := 4321;
 For I := 1 To 60 Do Begin
  Seed := (Seed * 25173 + 13849) And 65535;
  K := Seed Mod W;
  Seed := (Seed * 25173 + 13849) And 65535;
  Y := Seed Mod (HZ - 8);
  If Y < 44 Then PutPixel(AX1 + K, AY1 + Y, 15);
 End;
 { cellules allumees }
 For T := 1 To NR - 1 Do
  For K := -9 To 8 Do
   If CellOk(K, T) Then Begin
    I := (T * 7 + (K + 9) * 13) Mod 17;
    If I = 0 Then Quad(K, T, 3)
    Else If I = 5 Then Quad(K, T, 2)
    Else If I = 9 Then Quad(K, T, 6)
    Else If I = 12 Then Quad(K, T, 5)
    Else If I = 3 Then Quad(K, T, 1);
   End;
 { lignes de la grille }
 For T := 1 To NR Do Begin
  Y := RowY(T);
  If T < 4 Then SetColor(1) Else SetColor(3);
  Line(AX1, AY1 + Y, AX2, AY1 + Y);
 End;
 For K := -40 To 40 Do Begin
  If K = 0 Then Y2 := GH + HZ
  Else Begin
   Y2 := HZ + (GH * ((W Div 2 - 1) Div Abs(K) - 6)) Div 50;
   If Y2 > GH + HZ Then Y2 := GH + HZ;
  End;
  If Y2 > HZ + 2 Then Begin
   SetColor(3);
   Line(AX1 + CellX(K, HZ + 1), AY1 + HZ + 1, AX1 + CellX(K, Y2), AY1 + Y2);
  End;
 End;
 { nombres, symboles monetaires et formules dans les cellules }
 TxK[1] := -4; TxT[1] := 9; TxS[1] := '$';     TxC[1] := 14;
 TxK[2] := -2; TxT[2] := 9; TxS[2] := '42';    TxC[2] := 10;
 TxK[3] := -1; TxT[3] := 8; TxS[3] := '=SUM';  TxC[3] := 15;
 TxK[4] := 2;  TxT[4] := 9; TxS[4] := '3.14';  TxC[4] := 11;
 TxK[5] := 4;  TxT[5] := 9; TxS[5] := '%';     TxC[5] := 14;
 TxK[6] := -3; TxT[6] := 7; TxS[6] := 'EUR';   TxC[6] := 10;
 TxK[7] := 3;  TxT[7] := 8; TxS[7] := 'fx';    TxC[7] := 15;
 TxK[8] := 0;  TxT[8] := 9; TxS[8] := '1,5';   TxC[8] := 12;
 For I := 1 To 8 Do Begin
  T := TxT[I]; K := TxK[I];
  Y := RowY(T) + (RowY(T + 1) - RowY(T) - 8) Div 2;
  XL := CellX(K, RowY(T)) + (WAt(RowY(T)) - 8 * Length(TxS[I])) Div 2;
  TextAt(AX1 + XL, AY1 + Y, TxC[I], TxS[I]);
 End;
 { histogramme 3D pose sur la grille }
 BarH[1] := 16; BarH[2] := 28; BarH[3] := 44; BarH[4] := 34; BarH[5] := 56;
 BarF[1] := 10; BarF[2] := 11; BarF[3] := 14; BarF[4] := 13; BarF[5] := 12;
 BarS[1] := 2;  BarS[2] := 3;  BarS[3] := 6;  BarS[4] := 5;  BarS[5] := 4;
 T := 6; By := AY1 + RowY(T + 1);
 Bw := WAt(RowY(T)) * 7 Div 10; Dx := 7; Dy := 5;
 For I := 1 To 5 Do Begin
  Bx := AX1 + CellX(I + 1, RowY(T)) + 3;
  { face avant }
  FillBox(Bx, By - BarH[I], Bx + Bw, By, BarF[I]);
  { face droite }
  Pts[1].X := Bx + Bw;      Pts[1].Y := By - BarH[I];
  Pts[2].X := Bx + Bw + Dx; Pts[2].Y := By - BarH[I] - Dy;
  Pts[3].X := Bx + Bw + Dx; Pts[3].Y := By - Dy;
  Pts[4].X := Bx + Bw;      Pts[4].Y := By;
  SetFillStyle(1, BarS[I]); FillPoly(4, Pts);
  { dessus }
  Pts[1].X := Bx;           Pts[1].Y := By - BarH[I];
  Pts[2].X := Bx + Dx;      Pts[2].Y := By - BarH[I] - Dy;
  Pts[3].X := Bx + Bw + Dx; Pts[3].Y := By - BarH[I] - Dy;
  Pts[4].X := Bx + Bw;      Pts[4].Y := By - BarH[I];
  SetFillStyle(1, 15); FillPoly(4, Pts);
 End;
 TextAt(AX1 + 8, AY1 + 8, 15, 'L''univers des cellules');
 SetColor(CLR_WIN_DARK);
 Rectangle(AX1 - 1, AY1 - 1, AX2 + 1, AY2 + 1);
End;

Procedure ActionAbout;
Var X1, Y1, X2, Y2, BX1, BY1, BX2, BY2: Integer; K: Char; Done: Boolean;
Begin
 X1 := 100; Y1 := 60; X2 := 540; Y2 := 410;
 BX1 := (X1 + X2) Div 2 - 40; BY1 := Y2 - 32; BX2 := BX1 + 80; BY2 := BY1 + 22;
 HideMouse;
 FillBox(X1, Y1, X2, Y2, CLR_WIN_BG);
 DrawRaisedFrame(X1, Y1, X2, Y2);
 OsTitleBar(X1 + 2, Y1 + 2, X2 - 2, Y1 + 18, 'A propos de Excelsior', Y1 + 5);
 DrawAboutArt(X1 + 10, Y1 + 28, X2 - 10, Y1 + 208);
 TextBoldAt(X1 + 16, Y1 + 222, CLR_TEXT, 'Excelsior');
 TextAt(X1 + 16, Y1 + 238, CLR_TEXT,
        'Tableur graphique en Turbo Pascal / Free Pascal');
 TextAt(X1 + 16, Y1 + 264, CLR_TEXT, 'Auteur :   Sylvain Maltais');
 TextAt(X1 + 16, Y1 + 280, CLR_TEXT, 'Date :     2026');
 TextAt(X1 + 16, Y1 + 296, CLR_TEXT, 'Site Web : https://www.gladir.com/office-0');
 FillBox(BX1, BY1, BX2, BY2, CLR_WIN_BG);
 DrawRaisedFrame(BX1, BY1, BX2, BY2);
 TextAt(BX1 + 32, BY1 + 6, CLR_TEXT, 'OK');
 ShowMouse;
 UpdateMouse;
 Done := False;
 Repeat
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then K := ReadKey
   Else If (K = #13) Or (K = #27) Or (K = ' ') Then Done := True;
  End;
  UpdateMouse;
  If LeftPressed And (Mouse.X >= BX1) And (Mouse.X <= BX2) And
     (Mouse.Y >= BY1) And (Mouse.Y <= BY2) Then
   Done := True;
 Until Done;
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{           PHASE 5 : ENTREES/SORTIES FICHIER (.XLC) ET DIALOGUES        }
{ ====================================================================== }

Function InputDialog(Const Title, Prompt: String;
                     Var Value: String; MaxLen: Integer): Boolean; Forward;

Procedure FreeWorkbook;
Var I, R, C: Integer; Sh: PSheet; Row: PRow;
Begin
 FreeAllImages;
 FreeAllCharts;
 For I := 1 To MAX_SHEETS Do Begin
  Sh := WB.Sheets[I];
  If Sh = Nil Then Continue;
  For R := 0 To MAX_ROWS - 1 Do Begin
   Row := Sh^.Rows[R];
   If Row = Nil Then Continue;
   For C := 0 To MAX_COLS - 1 Do
    If Row^[C].Formula <> Nil Then Begin
     Dispose(Row^[C].Formula);
     Row^[C].Formula := Nil;
    End;
   Dispose(Row);
   Sh^.Rows[R] := Nil;
  End;
  Dispose(Sh);
  WB.Sheets[I] := Nil;
 End;
 WB.Count := 0;
End;

Procedure MessageBox(Const Title, Msg: String);
Begin
 { OS/2-0 : boite de message de Presentation Manager }
 If Title = 'Erreur' Then OsDummy := OsBox(Title, Msg, MB_OK Or MB_ERROR)
 Else OsDummy := OsBox(Title, Msg, MB_OK Or MB_INFORMATION);
 Repeat GetMouseState(Mouse.X, Mouse.Y, Mouse.B); Until (Mouse.B And 1) = 0;
 LastClickB := Mouse.B;
 NeedFullRedraw := True;
End;

Function ConfirmDialog(Const Title, Msg: String): Boolean;
Begin
 { OS/2-0 : boite de question de Presentation Manager (Oui / Non) }
 ConfirmDialog := OsBox(Title, Msg, MB_YESNO Or MB_QUERY) = MBID_YES;
 Repeat GetMouseState(Mouse.X, Mouse.Y, Mouse.B); Until (Mouse.B And 1) = 0;
 LastClickB := Mouse.B;
 NeedFullRedraw := True;
End;

{ --- Sauvegarde format .XLC --- }

Procedure WriteEscaped(Var F: Text; Const S: String);
Var I: Integer; C: Char;
Begin
 For I := 1 To Length(S) Do Begin
  C := S[I];
  Case C Of
   '\' : Write(F, '\\');
   #10 : Write(F, '\n');
   #13 : Write(F, '\r');
   #9  : Write(F, '\t');
   Else
    If (C < ' ') Then Write(F, '?') Else Write(F, C);
  End;
 End;
 Writeln(F);
End;

Function ReadEscaped(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := '';
 I := 1;
 While I <= Length(S) Do Begin
  If (S[I] = '\') And (I < Length(S)) Then Begin
   Case S[I + 1] Of
    '\' : R := R + '\';
    'n' : R := R + #10;
    'r' : R := R + #13;
    't' : R := R + #9;
    Else  R := R + S[I + 1];
   End;
   Inc(I, 2);
  End Else Begin
   R := R + S[I];
   Inc(I);
  End;
 End;
 ReadEscaped := R;
End;

Function SaveWorkbookXLC(Const FN: String): Boolean;
Var F: Text; I, R, C: Integer; Sh: PSheet; Row: PRow; Ce: TCell;
Begin
 SaveWorkbookXLC := False;
 {$I-}
 Assign(F, FN);
 Rewrite(F);
 {$I+}
 If IOResult <> 0 Then Exit;
 Writeln(F, 'XLCLONE1');
 Writeln(F, 'WB ', WB.Count, ' ', WB.Active);
 For I := 1 To WB.Count Do Begin
  Sh := WB.Sheets[I];
  If Sh = Nil Then Continue;
  Write(F, 'SH ');
  WriteEscaped(F, Sh^.Name);
  Writeln(F, 'SD ', Sh^.CurRow, ' ', Sh^.CurCol, ' ',
                    Sh^.ScrollRow, ' ', Sh^.ScrollCol);
  For C := 0 To MAX_COLS - 1 Do
   If Sh^.ColW[C] <> DEFAULT_COL_W Then
    Writeln(F, 'CW ', C, ' ', Sh^.ColW[C]);
  For R := 0 To MAX_ROWS - 1 Do
   If Sh^.RowH[R] <> DEFAULT_ROW_H Then
    Writeln(F, 'RH ', R, ' ', Sh^.RowH[R]);
  For R := 0 To MAX_ROWS - 1 Do Begin
   Row := Sh^.Rows[R];
   If Row = Nil Then Continue;
   For C := 0 To MAX_COLS - 1 Do Begin
    Ce := Row^[C];
    If Ce.Kind = ckEmpty Then Continue;
    Writeln(F, 'C ', R, ' ', C, ' ', Ord(Ce.Kind), ' ',
                Ce.Style, ' ', Ce.Align, ' ', Ce.Format, ' ',
                Ce.Fg, ' ', Ce.Bg);
    If Ce.Text <> '' Then Begin
     Write(F, 'T:'); WriteEscaped(F, Ce.Text);
    End;
    If (Ce.Kind = ckFormula) And (Ce.Formula <> Nil) Then Begin
     Write(F, 'F:'); WriteEscaped(F, Ce.Formula^);
    End;
   End;
  End;
  Writeln(F, 'END');
 End;
 Writeln(F, 'EOF');
 {$I-} Close(F); {$I+}
 If IOResult <> 0 Then Exit;
 SaveWorkbookXLC := True;
End;

Function LoadWorkbookXLC(Const FN: String): Boolean;
Var F: Text; Line, Rest, Tok: String; Sh: PSheet; Row: PRow;
    P, Code, Curi: Integer;
    R, C, K, Sty, Aln, Fmt, Fg, Bg: Integer;
    SaveCount, SaveActive: Integer;
    SaveCurR, SaveCurC, SaveScrR, SaveScrC: Integer;
    InCell: Boolean; CurR, CurC: Integer;
    Code2: Integer; V: Double;

 Function NextTok: String;
 Var Sp: Integer; T: String;
 Begin
  While (Length(Rest) > 0) And (Rest[1] = ' ') Do Delete(Rest, 1, 1);
  Sp := Pos(' ', Rest);
  If Sp = 0 Then Begin T := Rest; Rest := ''; End
  Else Begin T := Copy(Rest, 1, Sp - 1); Delete(Rest, 1, Sp); End;
  NextTok := T;
 End;

Begin
 LoadWorkbookXLC := False;
 {$I-}
 Assign(F, FN);
 Reset(F);
 {$I+}
 If IOResult <> 0 Then Exit;
 Readln(F, Line);
 If Copy(Line, 1, 8) <> 'XLCLONE1' Then Begin
  {$I-} Close(F); {$I+}
  Exit;
 End;
 FreeWorkbook;
 FillChar(WB, SizeOf(WB), 0);
 WB.Count := 0; WB.Active := 1;
 SaveCount := 0; SaveActive := 1;
 Curi := 0;
 InCell := False; CurR := 0; CurC := 0;
 While Not Eof(F) Do Begin
  Readln(F, Line);
  If Line = 'EOF' Then Break;
  If Line = 'END' Then Begin InCell := False; Continue; End;
  If Length(Line) < 2 Then Continue;
  If Copy(Line, 1, 3) = 'WB ' Then Begin
   Rest := Copy(Line, 4, 255);
   Tok := NextTok; Val(Tok, SaveCount, Code);
   Tok := NextTok; Val(Tok, SaveActive, Code);
   Continue;
  End;
  If Copy(Line, 1, 3) = 'SH ' Then Begin
   Inc(Curi);
   If Curi > MAX_SHEETS Then Continue;
   New(Sh); InitSheet(Sh, ReadEscaped(Copy(Line, 4, 255)));
   WB.Sheets[Curi] := Sh;
   WB.Count := Curi;
   InCell := False;
   Continue;
  End;
  Sh := WB.Sheets[Curi];
  If Sh = Nil Then Continue;
  If Copy(Line, 1, 3) = 'SD ' Then Begin
   Rest := Copy(Line, 4, 255);
   Tok := NextTok; Val(Tok, SaveCurR, Code);
   Tok := NextTok; Val(Tok, SaveCurC, Code);
   Tok := NextTok; Val(Tok, SaveScrR, Code);
   Tok := NextTok; Val(Tok, SaveScrC, Code);
   Sh^.CurRow := SaveCurR; Sh^.CurCol := SaveCurC;
   Sh^.ScrollRow := SaveScrR; Sh^.ScrollCol := SaveScrC;
   Sh^.SelR1 := SaveCurR; Sh^.SelC1 := SaveCurC;
   Sh^.SelR2 := SaveCurR; Sh^.SelC2 := SaveCurC;
   Continue;
  End;
  If Copy(Line, 1, 3) = 'CW ' Then Begin
   Rest := Copy(Line, 4, 255);
   Tok := NextTok; Val(Tok, C, Code);
   Tok := NextTok; Val(Tok, P, Code);
   If (Code = 0) And (C >= 0) And (C < MAX_COLS) Then Sh^.ColW[C] := P;
   Continue;
  End;
  If Copy(Line, 1, 3) = 'RH ' Then Begin
   Rest := Copy(Line, 4, 255);
   Tok := NextTok; Val(Tok, R, Code);
   Tok := NextTok; Val(Tok, P, Code);
   If (Code = 0) And (R >= 0) And (R < MAX_ROWS) Then Sh^.RowH[R] := P;
   Continue;
  End;
  If Copy(Line, 1, 2) = 'C ' Then Begin
   Rest := Copy(Line, 3, 255);
   Tok := NextTok; Val(Tok, R, Code);
   Tok := NextTok; Val(Tok, C, Code);
   Tok := NextTok; Val(Tok, K, Code);
   Tok := NextTok; Val(Tok, Sty, Code);
   Tok := NextTok; Val(Tok, Aln, Code);
   Tok := NextTok; Val(Tok, Fmt, Code);
   Tok := NextTok; Val(Tok, Fg, Code);
   Tok := NextTok; Val(Tok, Bg, Code);
   If (R < 0) Or (R >= MAX_ROWS) Or (C < 0) Or (C >= MAX_COLS) Then Continue;
   If (K < 0) Or (K > 3) Then K := 1;
   Row := GetRow(Sh, R);
   If Row = Nil Then Continue;
   Row^[C].Kind := TCellKind(K);
   Row^[C].Style := Sty; Row^[C].Align := Aln; Row^[C].Format := Fmt;
   Row^[C].Fg := Fg; Row^[C].Bg := Bg;
   Row^[C].Text := ''; Row^[C].Num := 0;
   InCell := True; CurR := R; CurC := C;
   Continue;
  End;
  If InCell And (Copy(Line, 1, 2) = 'T:') Then Begin
   Row := Sh^.Rows[CurR];
   If Row <> Nil Then Begin
    Row^[CurC].Text := Copy(ReadEscaped(Copy(Line, 3, 255)), 1, MAX_CELL_TEXT);
    If Row^[CurC].Kind = ckNumber Then Begin
     Val(Row^[CurC].Text, V, Code2);
     If Code2 = 0 Then Row^[CurC].Num := V;
    End;
   End;
   Continue;
  End;
  If InCell And (Copy(Line, 1, 2) = 'F:') Then Begin
   Row := Sh^.Rows[CurR];
   If Row <> Nil Then Begin
    New(Row^[CurC].Formula);
    Row^[CurC].Formula^ := ReadEscaped(Copy(Line, 3, 255));
   End;
   Continue;
  End;
 End;
 {$I-} Close(F); {$I+}
 If WB.Count = 0 Then Begin
  { fichier vide : recreer une feuille }
  New(Sh); InitSheet(Sh, 'Feuil1');
  WB.Sheets[1] := Sh; WB.Count := 1;
 End;
 If (SaveActive >= 1) And (SaveActive <= WB.Count) Then
  WB.Active := SaveActive
 Else
  WB.Active := 1;
 WB.FileName := FN;
 WB.Modified := False;
 RecalcWorkbook;
 LoadWorkbookXLC := True;
End;

{ ====================================================================== }
{        PHASE 9 : XLS (BIFF8 / OLE2 compound document)                  }
{ ====================================================================== }
{ Ecriture et lecture minimales du format BIFF8 dans un conteneur OLE2.   }
{ Limites : flux Workbook <= 64 KB (1 secteur FAT, 126 secteurs de        }
{ donnees), SST <= ~8 KB (pas de CONTINUE), formules non sauvegardees     }
{ (valeur calculee seulement), styles cellule par defaut, pas de support  }
{ de mini-stream en lecture.                                              }
{ ====================================================================== }

Const
 OLE_ENDOFCHAIN  = LongInt($FFFFFFFE);
 OLE_FREESECT    = LongInt($FFFFFFFF);
 OLE_FATSECT     = LongInt($FFFFFFFD);
 MAX_SST_STRINGS = 256;

Type
 TXBuf = Record
  Data : Pointer;
  Cap  : LongInt;
  Size : LongInt;
 End;

Var
 SST_Count : Integer;
 SST_Strs  : Array[1..MAX_SST_STRINGS] Of String[MAX_CELL_TEXT];
 SST_Load  : Array[1..MAX_SST_STRINGS] Of String[MAX_CELL_TEXT];
 SST_LoadN : Integer;
 OLE_FAT   : Array[0..4095] Of LongInt;

{ --- Helpers buffer dynamique --- }

Procedure XBNew(Var B: TXBuf; InitCap: LongInt);
Begin
 If InitCap < 256 Then InitCap := 256;
 GetMem(B.Data, InitCap); B.Cap := InitCap; B.Size := 0;
End;

Procedure XBFree(Var B: TXBuf);
Begin
 If B.Data <> Nil Then FreeMem(B.Data, B.Cap);
 B.Data := Nil; B.Cap := 0; B.Size := 0;
End;

Procedure XBEnsure(Var B: TXBuf; Extra: LongInt);
Var NewCap: LongInt; NewData: Pointer;
Begin
 If B.Size + Extra <= B.Cap Then Exit;
 NewCap := B.Cap;
 If NewCap < 256 Then NewCap := 256;
 While NewCap < B.Size + Extra Do NewCap := NewCap * 2;
 GetMem(NewData, NewCap);
 If B.Size > 0 Then Move(B.Data^, NewData^, B.Size);
 If B.Data <> Nil Then FreeMem(B.Data, B.Cap);
 B.Data := NewData; B.Cap := NewCap;
End;

Procedure XBByte(Var B: TXBuf; V: Byte);
Var P: ^Byte;
Begin
 XBEnsure(B, 1);
 P := B.Data; Inc(P, B.Size); P^ := V; Inc(B.Size);
End;

Procedure XBWord(Var B: TXBuf; V: Word);
Begin
 XBByte(B, Byte(V And $FF));
 XBByte(B, Byte((V Shr 8) And $FF));
End;

Procedure XBLong(Var B: TXBuf; V: LongInt);
Begin
 XBByte(B, Byte(V And $FF));
 XBByte(B, Byte((V Shr 8) And $FF));
 XBByte(B, Byte((V Shr 16) And $FF));
 XBByte(B, Byte((V Shr 24) And $FF));
End;

Procedure XBDouble(Var B: TXBuf; V: Double);
Var Tmp: Array[0..7] Of Byte; I: Integer;
Begin
 Move(V, Tmp, 8);
 For I := 0 To 7 Do XBByte(B, Tmp[I]);
End;

Procedure XBBytesPtr(Var B: TXBuf; Src: Pointer; N: LongInt);
Var Dst: ^Byte;
Begin
 If N <= 0 Then Exit;
 XBEnsure(B, N);
 Dst := B.Data; Inc(Dst, B.Size);
 Move(Src^, Dst^, N);
 Inc(B.Size, N);
End;

Procedure XBWriteWordAt(Var B: TXBuf; Ofs: LongInt; V: Word);
Var P: ^Byte;
Begin
 P := B.Data; Inc(P, Ofs);
 P^ := Byte(V And $FF); Inc(P); P^ := Byte((V Shr 8) And $FF);
End;

Procedure XBWriteLongAt(Var B: TXBuf; Ofs, V: LongInt);
Var P: ^Byte;
Begin
 P := B.Data; Inc(P, Ofs);
 P^ := Byte(V And $FF); Inc(P);
 P^ := Byte((V Shr 8) And $FF); Inc(P);
 P^ := Byte((V Shr 16) And $FF); Inc(P);
 P^ := Byte((V Shr 24) And $FF);
End;

Function XBReadByte(Const B: TXBuf; Ofs: LongInt): Byte;
Var P: ^Byte;
Begin
 P := B.Data; Inc(P, Ofs); XBReadByte := P^;
End;

Function XBReadWord(Const B: TXBuf; Ofs: LongInt): Word;
Begin
 XBReadWord := Word(XBReadByte(B, Ofs)) Or
               (Word(XBReadByte(B, Ofs + 1)) Shl 8);
End;

Function XBReadLong(Const B: TXBuf; Ofs: LongInt): LongInt;
Begin
 XBReadLong := LongInt(XBReadByte(B, Ofs)) Or
               (LongInt(XBReadByte(B, Ofs + 1)) Shl 8) Or
               (LongInt(XBReadByte(B, Ofs + 2)) Shl 16) Or
               (LongInt(XBReadByte(B, Ofs + 3)) Shl 24);
End;

Function XBReadDouble(Const B: TXBuf; Ofs: LongInt): Double;
Var Tmp: Array[0..7] Of Byte; I: Integer; D: Double;
Begin
 For I := 0 To 7 Do Tmp[I] := XBReadByte(B, Ofs + I);
 Move(Tmp, D, 8);
 XBReadDouble := D;
End;

{ --- Table SST partagee --- }

{ OS/2-0 : le resultat d'une formule est-il un texte (ou une erreur) ? }
Function XlsTextResult(Const S: String): Boolean;
Var V: Double; Code: Integer;
Begin
 If S = '' Then Begin XlsTextResult := False; Exit; End;
 Val(S, V, Code);
 XlsTextResult := (S[1] = '#') Or (Code <> 0);
End;

Function SSTAdd(Const S: String): LongInt;
Var I: Integer; T: String;
Begin
 T := S;
 If Length(T) > MAX_CELL_TEXT Then T[0] := Chr(MAX_CELL_TEXT);
 For I := 1 To SST_Count Do
  If SST_Strs[I] = T Then Begin SSTAdd := I - 1; Exit; End;
 If SST_Count >= MAX_SST_STRINGS Then Begin SSTAdd := 0; Exit; End;
 Inc(SST_Count); SST_Strs[SST_Count] := T;
 SSTAdd := SST_Count - 1;
End;

Procedure CollectSST;
Var I, R, C: Integer; Sh: PSheet; Row: PRow; Dummy: LongInt;
Begin
 SST_Count := 0;
 For I := 1 To WB.Count Do Begin
  Sh := WB.Sheets[I];
  If Sh = Nil Then Continue;
  For R := 0 To MAX_ROWS - 1 Do Begin
   Row := Sh^.Rows[R];
   If Row = Nil Then Continue;
   For C := 0 To MAX_COLS - 1 Do
    Case Row^[C].Kind Of
     ckText:
      If Row^[C].Text <> '' Then Dummy := SSTAdd(Row^[C].Text);
     ckFormula:
      If XlsTextResult(Row^[C].Text) Then
       Dummy := SSTAdd(Row^[C].Text);
    End;
  End;
 End;
End;

{ --- Ecriture BIFF8 --- }

Procedure BiffRec(Var B: TXBuf; Rec: Word; Len: Word);
Begin XBWord(B, Rec); XBWord(B, Len); End;

Procedure WriteFontRec(Var B: TXBuf);
Const FName = 'Arial';
Var I: Integer;
Begin
 BiffRec(B, $0031, 16 + Length(FName));   { OS/2-0 : 16 (et non 14) + nom }
 XBWord(B, 200); XBWord(B, 0); XBWord(B, $7FFF);
 XBWord(B, 400); XBWord(B, 0);
 XBByte(B, 0); XBByte(B, 0); XBByte(B, 0); XBByte(B, 0);
 XBByte(B, Length(FName)); XBByte(B, 0);
 For I := 1 To Length(FName) Do XBByte(B, Byte(FName[I]));
End;

Procedure WriteXFRec(Var B: TXBuf; IsStyle: Boolean);
Begin
 BiffRec(B, $00E0, 20);
 XBWord(B, 0); XBWord(B, 0);
 If IsStyle Then XBWord(B, $FFF5) Else XBWord(B, $0001);
 XBByte(B, $20); XBByte(B, 0); XBByte(B, 0); XBByte(B, 0);
 XBLong(B, 0); XBLong(B, 0); XBWord(B, 0);
End;

Procedure WriteStyleRec(Var B: TXBuf; XFIdx: Word; Built: Byte);
Begin
 BiffRec(B, $0293, 4);
 XBWord(B, XFIdx Or $8000); XBByte(B, Built); XBByte(B, $FF);
End;

Procedure WriteSSTRec(Var B: TXBuf);
Var LenOfs, RecStart: LongInt; I, J: Integer; S: String; Used: LongInt;
Begin
 XBWord(B, $00FC); LenOfs := B.Size; XBWord(B, 0);
 RecStart := B.Size;
 XBLong(B, SST_Count); XBLong(B, SST_Count);
 Used := 8;
 For I := 1 To SST_Count Do Begin
  S := SST_Strs[I];
  If Used + 3 + Length(S) > 8200 Then S := '';
  XBWord(B, Length(S)); XBByte(B, 0);
  For J := 1 To Length(S) Do XBByte(B, Byte(S[J]));
  Inc(Used, 3 + Length(S));
 End;
 XBWriteWordAt(B, LenOfs, Word(B.Size - RecStart));
End;

Procedure WriteSheetSubstream(Var B: TXBuf; Sh: PSheet);
Var R, C, FirstR, LastR, FirstC, LastC: Integer;
    Row: PRow; SI: LongInt; HasAny: Boolean;
Begin
 HasAny := False;
 FirstR := 0; LastR := 0; FirstC := 0; LastC := 0;
 For R := 0 To MAX_ROWS - 1 Do Begin
  Row := Sh^.Rows[R];
  If Row = Nil Then Continue;
  For C := 0 To MAX_COLS - 1 Do
   If Row^[C].Kind <> ckEmpty Then Begin
    If Not HasAny Then Begin
     FirstR := R; LastR := R; FirstC := C; LastC := C; HasAny := True;
    End Else Begin
     If R < FirstR Then FirstR := R;
     If R > LastR Then LastR := R;
     If C < FirstC Then FirstC := C;
     If C > LastC Then LastC := C;
    End;
   End;
 End;

 BiffRec(B, $0809, 16);
 XBWord(B, $0600); XBWord(B, $0010);
 XBWord(B, $1FD2); XBWord(B, $07CD);
 XBLong(B, $000000C1); XBLong(B, $00000606);

 BiffRec(B, $0200, 14);
 XBLong(B, FirstR); XBLong(B, LastR + 1);
 XBWord(B, Word(FirstC)); XBWord(B, Word(LastC + 1)); XBWord(B, 0);

 For R := 0 To MAX_ROWS - 1 Do Begin
  Row := Sh^.Rows[R];
  If Row = Nil Then Continue;
  For C := 0 To MAX_COLS - 1 Do Begin
   Case Row^[C].Kind Of
    ckText:
     If Row^[C].Text <> '' Then Begin
      SI := SSTAdd(Row^[C].Text);
      BiffRec(B, $00FD, 10);
      XBWord(B, Word(R)); XBWord(B, Word(C));
      XBWord(B, 15); XBLong(B, SI);
     End;
    ckNumber: Begin
     BiffRec(B, $0203, 14);
     XBWord(B, Word(R)); XBWord(B, Word(C));
     XBWord(B, 15); XBDouble(B, Row^[C].Num);
    End;
    ckFormula:
     If XlsTextResult(Row^[C].Text) Then Begin
      SI := SSTAdd(Row^[C].Text);
      BiffRec(B, $00FD, 10);
      XBWord(B, Word(R)); XBWord(B, Word(C));
      XBWord(B, 15); XBLong(B, SI);
     End Else Begin
      BiffRec(B, $0203, 14);
      XBWord(B, Word(R)); XBWord(B, Word(C));
      XBWord(B, 15); XBDouble(B, Row^[C].Num);
     End;
   End;
  End;
 End;

 BiffRec(B, $023E, 18);
 XBWord(B, $06B6); XBWord(B, 0); XBWord(B, 0);
 XBLong(B, $00000040); XBWord(B, 0); XBWord(B, 0); XBLong(B, 0);

 BiffRec(B, $000A, 0);
End;

Procedure WriteWorkbookGlobals(Var B: TXBuf;
                              Var SheetOfsPos: Array Of LongInt);
Var I, J: Integer; NameStr: String; NLen: Integer;
Begin
 BiffRec(B, $0809, 16);
 XBWord(B, $0600); XBWord(B, $0005);
 XBWord(B, $1FD2); XBWord(B, $07CD);
 XBLong(B, $000000C1); XBLong(B, $00000606);

 BiffRec(B, $00E1, 2); XBWord(B, $04B0);
 BiffRec(B, $00C1, 2); XBWord(B, 0);
 BiffRec(B, $00E2, 0);

 BiffRec(B, $005C, 112);
 XBWord(B, 7); XBByte(B, 0);
 NameStr := 'XLClone';
 For I := 1 To Length(NameStr) Do XBByte(B, Byte(NameStr[I]));
 For I := 1 To 102 Do XBByte(B, $20);

 BiffRec(B, $0042, 2); XBWord(B, 1200);
 BiffRec(B, $0161, 2); XBWord(B, 0);

 BiffRec(B, $013D, Word(WB.Count * 2));
 For I := 1 To WB.Count Do XBWord(B, Word(I));

 BiffRec(B, $003D, 18);
 XBWord(B, $0168); XBWord(B, $0078);
 XBWord(B, $25BC); XBWord(B, $1572);
 XBWord(B, $0038);
 XBWord(B, Word(WB.Active - 1));
 XBWord(B, 0); XBWord(B, 1); XBWord(B, $0258);

 BiffRec(B, $0022, 2); XBWord(B, 0);
 BiffRec(B, $000E, 2); XBWord(B, 1);
 BiffRec(B, $01B7, 2); XBWord(B, 0);
 BiffRec(B, $00DA, 2); XBWord(B, 0);

 For I := 1 To 5 Do WriteFontRec(B);
 For I := 1 To 15 Do WriteXFRec(B, True);
 WriteXFRec(B, False);

 WriteStyleRec(B, 0, 0);
 WriteStyleRec(B, 1, 3);
 WriteStyleRec(B, 2, 4);
 WriteStyleRec(B, 3, 5);
 WriteStyleRec(B, 4, 6);
 WriteStyleRec(B, 5, 7);

 BiffRec(B, $0160, 2); XBWord(B, 1);

 For I := 1 To WB.Count Do Begin
  If WB.Sheets[I] = Nil Then NameStr := 'Sheet' + IntToStr(I)
                        Else NameStr := WB.Sheets[I]^.Name;
  NLen := Length(NameStr);
  BiffRec(B, $0085, Word(8 + NLen));
  SheetOfsPos[I - 1] := B.Size;
  XBLong(B, 0);
  XBWord(B, 0);
  XBByte(B, Byte(NLen)); XBByte(B, 0);
  For J := 1 To NLen Do XBByte(B, Byte(NameStr[J]));
 End;

 BiffRec(B, $008C, 4); XBWord(B, 1); XBWord(B, 1);

 WriteSSTRec(B);

 BiffRec(B, $000A, 0);
End;

Procedure BuildBiffStream(Var B: TXBuf);
Var SheetOfsPos: Array[0..MAX_SHEETS - 1] Of LongInt;
    I: Integer; Sh: PSheet; SheetStart: LongInt;
Begin
 CollectSST;
 XBNew(B, 65536);
 WriteWorkbookGlobals(B, SheetOfsPos);
 For I := 1 To WB.Count Do Begin
  Sh := WB.Sheets[I];
  If Sh = Nil Then Continue;
  SheetStart := B.Size;
  XBWriteLongAt(B, SheetOfsPos[I - 1], SheetStart);
  WriteSheetSubstream(B, Sh);
 End;
End;

{ --- OLE2 : helpers tableau plat --- }

Procedure OPutWord(Var Buf; Ofs: Integer; V: Word);
Var Q: ^Byte;
Begin
 Q := @Buf; Inc(Q, Ofs);
 Q^ := Byte(V And $FF); Inc(Q); Q^ := Byte((V Shr 8) And $FF);
End;

Procedure OPutLong(Var Buf; Ofs: Integer; V: LongInt);
Var Q: ^Byte;
Begin
 Q := @Buf; Inc(Q, Ofs);
 Q^ := Byte(V And $FF); Inc(Q);
 Q^ := Byte((V Shr 8) And $FF); Inc(Q);
 Q^ := Byte((V Shr 16) And $FF); Inc(Q);
 Q^ := Byte((V Shr 24) And $FF);
End;

Procedure OPutName(Var D: Array Of Byte; Ofs: Integer; Const N: String);
Var I: Integer;
Begin
 For I := 0 To 63 Do D[Ofs + I] := 0;
 For I := 1 To Length(N) Do D[Ofs + (I - 1) * 2] := Byte(N[I]);
 OPutWord(D, Ofs + 64, Word((Length(N) + 1) * 2));
End;

Function ORead4(Var Buf; Ofs: Integer): LongInt;
Var Q: ^Byte; V: LongInt;
Begin
 Q := @Buf; Inc(Q, Ofs);
 V := LongInt(Q^);
 Inc(Q); V := V Or (LongInt(Q^) Shl 8);
 Inc(Q); V := V Or (LongInt(Q^) Shl 16);
 Inc(Q); V := V Or (LongInt(Q^) Shl 24);
 ORead4 := V;
End;

Function ORead2(Var Buf; Ofs: Integer): Word;
Var Q: ^Byte; V: Word;
Begin
 Q := @Buf; Inc(Q, Ofs);
 V := Word(Q^);
 Inc(Q); V := V Or (Word(Q^) Shl 8);
 ORead2 := V;
End;

Function WriteOLE2File(Const FN: String; Var Biff: TXBuf): Boolean;
Var F: File;
    Header  : Array[0..511] Of Byte;
    FATSect : Array[0..511] Of Byte;
    DirSect : Array[0..511] Of Byte;
    Zero    : Array[0..511] Of Byte;
    NumDataSec, I, BytesLeft: LongInt;
Begin
 WriteOLE2File := False;
 For I := 0 To 511 Do Begin
  Header[I] := 0; FATSect[I] := 0; DirSect[I] := 0; Zero[I] := 0;
 End;

 NumDataSec := (Biff.Size + 511) Div 512;
 If NumDataSec > 126 Then Exit;
 If NumDataSec < 1 Then NumDataSec := 1;

 For I := 0 To 127 Do OPutLong(FATSect, I * 4, OLE_FREESECT);
 OPutLong(FATSect, 0, OLE_FATSECT);
 OPutLong(FATSect, 4, OLE_ENDOFCHAIN);
 For I := 0 To NumDataSec - 1 Do
  If I = NumDataSec - 1 Then
   OPutLong(FATSect, (2 + I) * 4, OLE_ENDOFCHAIN)
  Else
   OPutLong(FATSect, (2 + I) * 4, 2 + I + 1);

 Header[0] := $D0; Header[1] := $CF; Header[2] := $11; Header[3] := $E0;
 Header[4] := $A1; Header[5] := $B1; Header[6] := $1A; Header[7] := $E1;
 OPutWord(Header, 24, $003E);
 OPutWord(Header, 26, $0003);
 OPutWord(Header, 28, $FFFE);
 OPutWord(Header, 30, 9);
 OPutWord(Header, 32, 6);
 OPutLong(Header, 44, 1);
 OPutLong(Header, 48, 1);
 OPutLong(Header, 56, $00001000);
 OPutLong(Header, 60, OLE_ENDOFCHAIN);
 OPutLong(Header, 64, 0);
 OPutLong(Header, 68, OLE_ENDOFCHAIN);
 OPutLong(Header, 72, 0);
 OPutLong(Header, 76, 0);
 For I := 1 To 108 Do OPutLong(Header, 76 + I * 4, OLE_FREESECT);

 OPutName(DirSect, 0, 'Root Entry');
 DirSect[66] := 5; DirSect[67] := 1;
 OPutLong(DirSect, 68, LongInt($FFFFFFFF));
 OPutLong(DirSect, 72, LongInt($FFFFFFFF));
 OPutLong(DirSect, 76, 1);
 OPutLong(DirSect, 116, OLE_ENDOFCHAIN);
 OPutLong(DirSect, 120, 0);
 OPutLong(DirSect, 124, 0);

 OPutName(DirSect, 128, 'Workbook');
 DirSect[128 + 66] := 2; DirSect[128 + 67] := 1;
 OPutLong(DirSect, 128 + 68, LongInt($FFFFFFFF));
 OPutLong(DirSect, 128 + 72, LongInt($FFFFFFFF));
 OPutLong(DirSect, 128 + 76, LongInt($FFFFFFFF));
 OPutLong(DirSect, 128 + 116, 2);
 OPutLong(DirSect, 128 + 120, Biff.Size);
 OPutLong(DirSect, 128 + 124, 0);

 OPutLong(DirSect, 256 + 68, LongInt($FFFFFFFF));
 OPutLong(DirSect, 256 + 72, LongInt($FFFFFFFF));
 OPutLong(DirSect, 256 + 76, LongInt($FFFFFFFF));
 OPutLong(DirSect, 384 + 68, LongInt($FFFFFFFF));
 OPutLong(DirSect, 384 + 72, LongInt($FFFFFFFF));
 OPutLong(DirSect, 384 + 76, LongInt($FFFFFFFF));

 {$I-}
 Assign(F, FN); ReWrite(F, 1);
 {$I+} If IOResult <> 0 Then Exit;
 BlockWrite(F, Header,  512);
 BlockWrite(F, FATSect, 512);
 BlockWrite(F, DirSect, 512);
 If Biff.Size > 0 Then BlockWrite(F, Biff.Data^, Biff.Size);
 BytesLeft := NumDataSec * 512 - Biff.Size;
 If BytesLeft > 0 Then BlockWrite(F, Zero, BytesLeft);
 {$I-} Close(F); {$I+}
 If IOResult <> 0 Then Exit;
 WriteOLE2File := True;
End;

Function SaveWorkbookXLS(Const FN: String): Boolean;
Var B: TXBuf;
Begin
 SaveWorkbookXLS := False;
 B.Data := Nil; B.Cap := 0; B.Size := 0;
 BuildBiffStream(B);
 { OS/2-0 : flux Workbook d'au moins 4096 octets (hors du mini-flux) }
 While (B.Size > 0) And (B.Size < 4096) Do XBByte(B, 0);
 If B.Size > 0 Then SaveWorkbookXLS := WriteOLE2File(FN, B);
 XBFree(B);
End;

{ --- Lecture OLE2 + BIFF --- }

Function ReadOLE2File(Const FN: String; Var Biff: TXBuf): Boolean;
Var F : File;
    Header : Array[0..511] Of Byte;
    Sect   : Array[0..511] Of Byte;
    DirBuf : Array[0..511] Of Byte;
    DIFAT  : Array[0..108] Of LongInt;
    NumFAT, DirSec0 : LongInt;
    I, J, K, NumEntries : LongInt;
    DirSec, WBStart, WBSize, WBSec, ToCopy : LongInt;
    EntryOfs : Integer;
    EntryType : Byte;
    NameW : Word;
    EntryName, Upper : String[40];
Begin
 ReadOLE2File := False;
 {$I-}
 Assign(F, FN); Reset(F, 1);
 {$I+} If IOResult <> 0 Then Exit;
 If FileSize(F) < 1536 Then Begin Close(F); Exit; End;
 BlockRead(F, Header, 512);
 If (Header[0] <> $D0) Or (Header[1] <> $CF) Or
    (Header[2] <> $11) Or (Header[3] <> $E0) Then Begin
  Close(F); Exit;
 End;
 NumFAT  := ORead4(Header, 44);
 DirSec0 := ORead4(Header, 48);
 For I := 0 To 108 Do DIFAT[I] := ORead4(Header, 76 + I * 4);
 If (NumFAT < 1) Or (NumFAT > 109) Then Begin Close(F); Exit; End;

 NumEntries := 0;
 For I := 0 To NumFAT - 1 Do Begin
  If DIFAT[I] = OLE_FREESECT Then Break;
  Seek(F, 512 + DIFAT[I] * 512);
  BlockRead(F, Sect, 512);
  For J := 0 To 127 Do Begin
   If NumEntries < 4096 Then OLE_FAT[NumEntries] := ORead4(Sect, J * 4);
   Inc(NumEntries);
  End;
 End;
 If NumEntries = 0 Then Begin Close(F); Exit; End;

 WBStart := -1; WBSize := 0;
 DirSec := DirSec0;
 While DirSec <> OLE_ENDOFCHAIN Do Begin
  If (DirSec < 0) Or (DirSec >= NumEntries) Then Break;
  Seek(F, 512 + DirSec * 512);
  BlockRead(F, DirBuf, 512);
  For I := 0 To 3 Do Begin
   EntryOfs := I * 128;
   EntryType := DirBuf[EntryOfs + 66];
   If EntryType = 2 Then Begin
    NameW := ORead2(DirBuf, EntryOfs + 64);
    If (NameW >= 2) And (NameW <= 64) Then Begin
     EntryName := ''; Upper := '';
     K := 0;
     While K < (LongInt(NameW) Div 2 - 1) Do Begin
      If Length(EntryName) < 40 Then
       EntryName := EntryName + Char(DirBuf[EntryOfs + K * 2]);
      Inc(K);
     End;
     For J := 1 To Length(EntryName) Do
      Upper := Upper + UpCase(EntryName[J]);
     If Upper = 'WORKBOOK' Then Begin
      WBStart := ORead4(DirBuf, EntryOfs + 116);
      WBSize  := ORead4(DirBuf, EntryOfs + 120);
     End;
    End;
   End;
  End;
  If WBStart >= 0 Then Break;
  DirSec := OLE_FAT[DirSec];
 End;

 If (WBStart < 0) Or (WBSize <= 0) Then Begin Close(F); Exit; End;
 If WBSize < $1000 Then Begin
  { Mini-stream non supporte }
  Close(F); Exit;
 End;

 XBNew(Biff, WBSize + 1024);
 WBSec := WBStart;
 While (WBSec <> OLE_ENDOFCHAIN) And (Biff.Size < WBSize) Do Begin
  If (WBSec < 0) Or (WBSec >= NumEntries) Then Break;
  Seek(F, 512 + WBSec * 512);
  BlockRead(F, Sect, 512);
  ToCopy := WBSize - Biff.Size;
  If ToCopy > 512 Then ToCopy := 512;
  XBBytesPtr(Biff, @Sect, ToCopy);
  WBSec := OLE_FAT[WBSec];
 End;
 Close(F);
 ReadOLE2File := True;
End;

{ OS/2-0 : nombre RK du format BIFF8 (entier sur 30 bits ou 30 bits de
  poids fort d'un Double, divise par 100 si le bit 0 est mis) }
Function XlsRKValue(RK: LongInt): Double;
Var Q: Array[0..1] Of LongInt; D: Double;
Begin
 If (RK And 2) <> 0 Then D := (RK And LongInt($FFFFFFFC)) / 4.0
 Else Begin
  Q[0] := 0; Q[1] := RK And LongInt($FFFFFFFC);
  Move(Q, D, 8);
 End;
 If (RK And 1) <> 0 Then D := D / 100.0;
 XlsRKValue := D;
End;

{ OS/2-0 : cellule numerique lue d'un fichier XLS }
Procedure XlsSetNum(Sh: PSheet; R, C: LongInt; V: Double);
Var Row: PRow; S: String;
Begin
 If (R < 0) Or (R >= MAX_ROWS) Or (C < 0) Or (C >= MAX_COLS) Then Exit;
 Row := GetRow(Sh, R);
 If Row = Nil Then Exit;
 Row^[C].Kind := ckNumber;
 Row^[C].Num := V;
 Str(V:0:6, S);
 Row^[C].Text := Copy(S, 1, MAX_CELL_TEXT);
End;

Function LoadBIFFWorkbook(Var Biff: TXBuf): Boolean;
Var P, Sp, EndP, Unique, SI : LongInt;
    Rec, Len : Word;
    SheetCnt : Integer;
    SheetOfs : Array[1..MAX_SHEETS] Of LongInt;
    SheetNm  : Array[1..MAX_SHEETS] Of String[MAX_TAB_NAME];
    I, J : Integer;
    R, C : LongInt;
    SLen : Integer; STmp : String;
    Sh : PSheet; Row : PRow;
    UFlag : Byte;
    V : Double;
    XK, XN, XPR, XPC : LongInt;
Begin
 LoadBIFFWorkbook := False;
 XPR := -1; XPC := -1;
 SST_LoadN := 0; SheetCnt := 0;

 P := 0;
 While P + 4 <= Biff.Size Do Begin
  Rec := XBReadWord(Biff, P);
  Len := XBReadWord(Biff, P + 2);
  Case Rec Of
   $0085: If SheetCnt < MAX_SHEETS Then Begin
    Inc(SheetCnt);
    SheetOfs[SheetCnt] := XBReadLong(Biff, P + 4);
    SLen := XBReadByte(Biff, P + 10);
    UFlag := XBReadByte(Biff, P + 11);
    STmp := '';
    If (UFlag And 1) = 0 Then Begin
     For J := 0 To SLen - 1 Do
      If Length(STmp) < MAX_TAB_NAME Then
       STmp := STmp + Char(XBReadByte(Biff, P + 12 + J));
    End Else Begin
     For J := 0 To SLen - 1 Do
      If Length(STmp) < MAX_TAB_NAME Then
       STmp := STmp + Char(XBReadByte(Biff, P + 12 + J * 2));
    End;
    SheetNm[SheetCnt] := STmp;
   End;
   $00FC: Begin
    Unique := XBReadLong(Biff, P + 8);
    Sp := P + 12;
    EndP := P + 4 + Len;
    I := 0;
    While (I < Unique) And (Sp + 3 <= EndP) Do Begin
     SLen := XBReadWord(Biff, Sp); Inc(Sp, 2);
     UFlag := XBReadByte(Biff, Sp); Inc(Sp);
     STmp := '';
     If (UFlag And 1) = 0 Then Begin
      For J := 1 To SLen Do Begin
       If Sp >= Biff.Size Then Break;
       If Length(STmp) < MAX_CELL_TEXT Then
        STmp := STmp + Char(XBReadByte(Biff, Sp));
       Inc(Sp);
      End;
     End Else Begin
      For J := 1 To SLen Do Begin
       If Sp + 1 >= Biff.Size Then Break;
       If Length(STmp) < MAX_CELL_TEXT Then
        STmp := STmp + Char(XBReadByte(Biff, Sp));
       Inc(Sp, 2);
      End;
     End;
     If SST_LoadN < MAX_SST_STRINGS Then Begin
      Inc(SST_LoadN); SST_Load[SST_LoadN] := STmp;
     End;
     Inc(I);
    End;
   End;
   $000A: Begin
    Inc(P, 4 + Len);
    P := Biff.Size;   { force sortie boucle globals }
    Continue;
   End;
  End;
  Inc(P, 4 + Len);
 End;

 If SheetCnt = 0 Then Exit;

 FreeWorkbook;
 FillChar(WB, SizeOf(WB), 0);
 WB.Count := 0; WB.Active := 1;

 For I := 1 To SheetCnt Do Begin
  New(Sh); InitSheet(Sh, SheetNm[I]);
  WB.Sheets[I] := Sh; WB.Count := I;
  P := SheetOfs[I];
  If (P < 0) Or (P >= Biff.Size) Then Continue;
  Rec := XBReadWord(Biff, P);
  If Rec <> $0809 Then Continue;
  Len := XBReadWord(Biff, P + 2);
  Inc(P, 4 + Len);
  While P + 4 <= Biff.Size Do Begin
   Rec := XBReadWord(Biff, P);
   Len := XBReadWord(Biff, P + 2);
   Case Rec Of
    $0203: Begin
     R := XBReadWord(Biff, P + 4);
     C := XBReadWord(Biff, P + 6);
     V := XBReadDouble(Biff, P + 10);
     If (R >= 0) And (R < MAX_ROWS) And
        (C >= 0) And (C < MAX_COLS) Then Begin
      Row := GetRow(Sh, R);
      If Row <> Nil Then Begin
       Row^[C].Kind := ckNumber;
       Row^[C].Num := V;
       Str(V:0:6, STmp);
       Row^[C].Text := Copy(STmp, 1, MAX_CELL_TEXT);
      End;
     End;
    End;
    $00FD: Begin
     R := XBReadWord(Biff, P + 4);
     C := XBReadWord(Biff, P + 6);
     SI := XBReadLong(Biff, P + 10);
     If (R >= 0) And (R < MAX_ROWS) And
        (C >= 0) And (C < MAX_COLS) And
        (SI >= 0) And (SI < SST_LoadN) Then Begin
      Row := GetRow(Sh, R);
      If Row <> Nil Then Begin
       Row^[C].Kind := ckText;
       Row^[C].Text := SST_Load[SI + 1];
      End;
     End;
    End;
    $0201: Begin
     R := XBReadWord(Biff, P + 4);
     C := XBReadWord(Biff, P + 6);
     If (R >= 0) And (R < MAX_ROWS) And
        (C >= 0) And (C < MAX_COLS) Then Begin
      Row := GetRow(Sh, R);
      If Row <> Nil Then Row^[C].Kind := ckEmpty;
     End;
    End;
    { OS/2-0 : RK, MULRK, FORMULA et STRING (fichiers d'Excel) }
    $027E: XlsSetNum(Sh, XBReadWord(Biff, P + 4), XBReadWord(Biff, P + 6),
                     XlsRKValue(XBReadLong(Biff, P + 10)));
    $00BD: Begin
     R := XBReadWord(Biff, P + 4);
     C := XBReadWord(Biff, P + 6);
     XN := (LongInt(Len) - 6) Div 6;
     For XK := 0 To XN - 1 Do
      XlsSetNum(Sh, R, C + XK, XlsRKValue(XBReadLong(Biff, P + 10 + XK * 6)));
    End;
    $0006: Begin
     R := XBReadWord(Biff, P + 4);
     C := XBReadWord(Biff, P + 6);
     If XBReadWord(Biff, P + 16) <> $FFFF Then
      XlsSetNum(Sh, R, C, XBReadDouble(Biff, P + 10))
     Else If XBReadByte(Biff, P + 10) = 0 Then Begin
      XPR := R; XPC := C;      { texte dans l'enregistrement STRING suivant }
     End;
    End;
    $0207: If (XPR >= 0) And (XPR < MAX_ROWS) And (XPC >= 0) And (XPC < MAX_COLS) Then Begin
     SLen := XBReadWord(Biff, P + 4);
     UFlag := XBReadByte(Biff, P + 6);
     STmp := '';
     For J := 0 To SLen - 1 Do
      If Length(STmp) < MAX_CELL_TEXT Then Begin
       If (UFlag And 1) = 0 Then STmp := STmp + Char(XBReadByte(Biff, P + 7 + J))
       Else STmp := STmp + Char(XBReadByte(Biff, P + 7 + J * 2));
      End;
     Row := GetRow(Sh, XPR);
     If Row <> Nil Then Begin
      Row^[XPC].Kind := ckText;
      Row^[XPC].Text := STmp;
     End;
     XPR := -1;
    End;
    $000A: Begin
     Inc(P, 4 + Len);
     P := Biff.Size;
     Continue;
    End;
   End;
   Inc(P, 4 + Len);
  End;
 End;

 If WB.Count = 0 Then Begin
  New(Sh); InitSheet(Sh, 'Feuil1');
  WB.Sheets[1] := Sh; WB.Count := 1;
 End;
 WB.Active := 1;
 WB.FileName := '';
 WB.Modified := False;
 RecalcWorkbook;
 LoadBIFFWorkbook := True;
End;

Function LoadWorkbookXLS(Const FN: String): Boolean;
Var B: TXBuf;
Begin
 LoadWorkbookXLS := False;
 B.Data := Nil; B.Cap := 0; B.Size := 0;
 If Not ReadOLE2File(FN, B) Then Begin XBFree(B); Exit; End;
 If LoadBIFFWorkbook(B) Then Begin
  WB.FileName := '';
  LoadWorkbookXLS := True;
 End;
 XBFree(B);
End;

Function IsXLSExt(Const FN: String): Boolean;
Var I, J, K: Integer; E: String[8];
Begin
 E := ''; K := 0;
 For I := Length(FN) DownTo 1 Do
  If (K = 0) And (FN[I] = '.') Then K := I;
 If K > 0 Then
  For J := K + 1 To Length(FN) Do
   If Length(E) < 8 Then E := E + UpCase(FN[J]);
 IsXLSExt := (E = 'XLS');
End;

Function GetExtUp(Const FN: String): String;
Var I, J, K: Integer; E: String[8];
Begin
 E := ''; K := 0;
 For I := Length(FN) DownTo 1 Do
  If (K = 0) And (FN[I] = '.') Then K := I;
 If K > 0 Then
  For J := K + 1 To Length(FN) Do
   If Length(E) < 8 Then E := E + UpCase(FN[J]);
 GetExtUp := E;
End;

Function IsXLSXExt(Const FN: String): Boolean;
Begin
 IsXLSXExt := GetExtUp(FN) = 'XLSX';
End;

{ ====================================================================== }
{           PHASE 10 : FORMAT XLSX (ZIP + XML, store-only)               }
{ ====================================================================== }

Const
 ZIP_LFH_SIG  = LongInt($04034B50);
 ZIP_CDH_SIG  = LongInt($02014B50);
 ZIP_EOCD_SIG = LongInt($06054B50);
 XLSX_MAX_SST = 1024;

Var
 CRC32Table  : Array[0..255] Of LongInt;
 CRC32Init   : Boolean;
 XSST_Count  : Integer;
 XSST_Strs   : Array[1..XLSX_MAX_SST] Of String[63];

Procedure InitCRC32;
Var I, J: Integer; C: LongInt;
Begin
 If CRC32Init Then Exit;
 For I := 0 To 255 Do Begin
  C := I;
  For J := 0 To 7 Do
   If (C And 1) <> 0 Then C := LongInt($EDB88320) Xor (C Shr 1)
   Else C := C Shr 1;
  CRC32Table[I] := C;
 End;
 CRC32Init := True;
End;

Function CRC32Update(Crc: LongInt; P: Pointer; N: LongInt): LongInt;
Var I: LongInt; B: ^Byte;
Begin
 B := P;
 For I := 0 To N - 1 Do Begin
  Crc := CRC32Table[(Crc Xor B^) And $FF] Xor (Crc Shr 8);
  Inc(LongInt(B));
 End;
 CRC32Update := Crc;
End;

Function CRC32Buf(Const B: TXBuf): LongInt;
Var C: LongInt;
Begin
 C := LongInt(-1);
 C := CRC32Update(C, B.Data, B.Size);
 CRC32Buf := C Xor LongInt(-1);
End;

Procedure XBPutStr(Var B: TXBuf; Const S: String);
Var I: Integer;
Begin
 For I := 1 To Length(S) Do XBByte(B, Byte(S[I]));
End;

Procedure XBPutPChar(Var B: TXBuf; Const S: String);
Begin
 XBPutStr(B, S);
End;

Function XmlEscape(Const S: String): String;
Var I: Integer; R: String; C: Char;
Begin
 R := '';
 For I := 1 To Length(S) Do Begin
  C := S[I];
  Case C Of
   '<': R := R + '&lt;';
   '>': R := R + '&gt;';
   '&': R := R + '&amp;';
   '"': R := R + '&quot;';
   '''': R := R + '&apos;';
  Else
   If Byte(C) < 32 Then R := R + ' '
   Else R := R + C;
  End;
  If Length(R) > 240 Then Exit(R);
 End;
 XmlEscape := R;
End;

{ ColName / CellRef / DoubleToCellStr deja definis plus haut. }

Function XSSTAdd(Const S: String): Integer;
Var I: Integer;
Begin
 For I := 1 To XSST_Count Do
  If XSST_Strs[I] = S Then Begin XSSTAdd := I - 1; Exit; End;
 If XSST_Count < XLSX_MAX_SST Then Begin
  Inc(XSST_Count);
  XSST_Strs[XSST_Count] := S;
  XSSTAdd := XSST_Count - 1;
 End Else
  XSSTAdd := 0;
End;

Procedure CollectXSST;
Var I, R, C: Integer; Sh: PSheet; Row: PRow;
Begin
 XSST_Count := 0;
 For I := 1 To WB.Count Do Begin
  Sh := WB.Sheets[I];
  If Sh = Nil Then Continue;
  For R := 0 To MAX_ROWS - 1 Do Begin
   Row := Sh^.Rows[R];
   If Row = Nil Then Continue;
   For C := 0 To MAX_COLS - 1 Do
    If Row^[C].Kind = ckText Then XSSTAdd(Row^[C].Text);
  End;
 End;
End;

Procedure BuildContentTypes(Var B: TXBuf);
Var I: Integer;
Begin
 XBPutStr(B, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 XBPutStr(B, '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">');
 XBPutStr(B, '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>');
 XBPutStr(B, '<Default Extension="xml" ContentType="application/xml"/>');
 XBPutStr(B, '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>');
 XBPutStr(B, '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>');
 XBPutStr(B, '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>');
 For I := 1 To WB.Count Do Begin
  XBPutStr(B, '<Override PartName="/xl/worksheets/sheet');
  XBPutStr(B, IntToStr(I));
  XBPutStr(B, '.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>');
 End;
 XBPutStr(B, '</Types>');
End;

Procedure BuildRootRels(Var B: TXBuf);
Begin
 XBPutStr(B, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 XBPutStr(B, '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
 XBPutStr(B, '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>');
 XBPutStr(B, '</Relationships>');
End;

Procedure BuildWorkbookXml(Var B: TXBuf);
Var I: Integer;
Begin
 XBPutStr(B, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 XBPutStr(B, '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"');
 XBPutStr(B, ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">');
 XBPutStr(B, '<sheets>');
 For I := 1 To WB.Count Do Begin
  XBPutStr(B, '<sheet name="');
  XBPutStr(B, XmlEscape(WB.Sheets[I]^.Name));
  XBPutStr(B, '" sheetId="');
  XBPutStr(B, IntToStr(I));
  XBPutStr(B, '" r:id="rId');
  XBPutStr(B, IntToStr(I));
  XBPutStr(B, '"/>');
 End;
 XBPutStr(B, '</sheets></workbook>');
End;

Procedure BuildWorkbookRels(Var B: TXBuf);
Var I: Integer;
Begin
 XBPutStr(B, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 XBPutStr(B, '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
 For I := 1 To WB.Count Do Begin
  XBPutStr(B, '<Relationship Id="rId');
  XBPutStr(B, IntToStr(I));
  XBPutStr(B, '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet');
  XBPutStr(B, IntToStr(I));
  XBPutStr(B, '.xml"/>');
 End;
 XBPutStr(B, '<Relationship Id="rIdSty" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>');
 XBPutStr(B, '<Relationship Id="rIdSst" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>');
 XBPutStr(B, '</Relationships>');
End;

Procedure BuildStylesXml(Var B: TXBuf);
Begin
 XBPutStr(B, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 XBPutStr(B, '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
 XBPutStr(B, '<fonts count="1"><font><sz val="10"/><name val="Arial"/></font></fonts>');
 XBPutStr(B, '<fills count="1"><fill><patternFill patternType="none"/></fill></fills>');
 XBPutStr(B, '<borders count="1"><border/></borders>');
 XBPutStr(B, '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0"/></cellStyleXfs>');
 XBPutStr(B, '<cellXfs count="1"><xf numFmtId="0" fontId="0" xfId="0"/></cellXfs>');
 XBPutStr(B, '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>');
 XBPutStr(B, '</styleSheet>');
End;

Procedure BuildSharedStringsXml(Var B: TXBuf);
Var I: Integer;
Begin
 XBPutStr(B, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 XBPutStr(B, '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="');
 XBPutStr(B, IntToStr(XSST_Count));
 XBPutStr(B, '" uniqueCount="');
 XBPutStr(B, IntToStr(XSST_Count));
 XBPutStr(B, '">');
 For I := 1 To XSST_Count Do Begin
  XBPutStr(B, '<si><t xml:space="preserve">');
  XBPutStr(B, XmlEscape(XSST_Strs[I]));
  XBPutStr(B, '</t></si>');
 End;
 XBPutStr(B, '</sst>');
End;

Procedure BuildSheetXml(Var B: TXBuf; Sh: PSheet);
Var R, C, SI: Integer; Row: PRow; HasNum: Boolean;
    MinR, MaxR, MinC, MaxC: Integer; Has: Boolean;
Begin
 { compute used range }
 Has := False; MinR := 0; MaxR := 0; MinC := 0; MaxC := 0;
 For R := 0 To MAX_ROWS - 1 Do Begin
  Row := Sh^.Rows[R];
  If Row = Nil Then Continue;
  For C := 0 To MAX_COLS - 1 Do
   If Row^[C].Kind <> ckEmpty Then Begin
    If Not Has Then Begin
     MinR := R; MaxR := R; MinC := C; MaxC := C; Has := True;
    End Else Begin
     If R < MinR Then MinR := R;
     If R > MaxR Then MaxR := R;
     If C < MinC Then MinC := C;
     If C > MaxC Then MaxC := C;
    End;
   End;
 End;
 XBPutStr(B, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 XBPutStr(B, '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
 If Has Then Begin
  XBPutStr(B, '<dimension ref="');
  XBPutStr(B, CellRef(MinR, MinC));
  XBPutStr(B, ':');
  XBPutStr(B, CellRef(MaxR, MaxC));
  XBPutStr(B, '"/>');
 End;
 XBPutStr(B, '<sheetData>');
 If Has Then
  For R := MinR To MaxR Do Begin
   Row := Sh^.Rows[R];
   If Row = Nil Then Continue;
   { skip empty row }
   HasNum := False;
   For C := MinC To MaxC Do
    If Row^[C].Kind <> ckEmpty Then Begin HasNum := True; Break; End;
   If Not HasNum Then Continue;
   XBPutStr(B, '<row r="');
   XBPutStr(B, IntToStr(R + 1));
   XBPutStr(B, '">');
   For C := MinC To MaxC Do
    If Row^[C].Kind <> ckEmpty Then Begin
     Case Row^[C].Kind Of
      ckText: Begin
       SI := XSSTAdd(Row^[C].Text);
       XBPutStr(B, '<c r="');
       XBPutStr(B, CellRef(R, C));
       XBPutStr(B, '" t="s"><v>');
       XBPutStr(B, IntToStr(SI));
       XBPutStr(B, '</v></c>');
      End;
      ckNumber: Begin
       XBPutStr(B, '<c r="');
       XBPutStr(B, CellRef(R, C));
       XBPutStr(B, '"><v>');
       XBPutStr(B, DoubleToCellStr(Row^[C].Num));
       XBPutStr(B, '</v></c>');
      End;
      ckFormula: Begin
       If (Length(Row^[C].Text) > 0) And (Row^[C].Text[1] = '#') Then Begin
        SI := XSSTAdd(Row^[C].Text);
        XBPutStr(B, '<c r="');
        XBPutStr(B, CellRef(R, C));
        XBPutStr(B, '" t="s"><v>');
        XBPutStr(B, IntToStr(SI));
        XBPutStr(B, '</v></c>');
       End Else If XlsTextResult(Row^[C].Text) Then Begin
        { OS/2-0 : resultat texte d'une formule }
        XBPutStr(B, '<c r="');
        XBPutStr(B, CellRef(R, C));
        XBPutStr(B, '" t="str"><v>');
        XBPutStr(B, XmlEscape(Row^[C].Text));
        XBPutStr(B, '</v></c>');
       End Else Begin
        XBPutStr(B, '<c r="');
        XBPutStr(B, CellRef(R, C));
        XBPutStr(B, '"><v>');
        XBPutStr(B, DoubleToCellStr(Row^[C].Num));
        XBPutStr(B, '</v></c>');
       End;
      End;
     End;
    End;
   XBPutStr(B, '</row>');
  End;
 XBPutStr(B, '</sheetData></worksheet>');
End;

{ --- ZIP writer --- }

Type
 TZipEntry = Record
  Name    : String[64];
  Ofs     : LongInt;     { local header offset }
  Crc     : LongInt;
  Size    : LongInt;     { uncompressed = compressed (store) }
 End;

Const
 XLSX_MAX_PARTS = 32;

Var
 ZipParts  : Array[1..XLSX_MAX_PARTS] Of TZipEntry;
 ZipPCount : Integer;

Procedure ZipWriteLocalHeader(Var Z: TXBuf; Const Name: String;
                              Crc, Sz: LongInt);
Var I: Integer;
Begin
 XBLong(Z, ZIP_LFH_SIG);
 XBWord(Z, 20);                   { version needed }
 XBWord(Z, 0);                    { flags }
 XBWord(Z, 0);                    { method = stored }
 XBWord(Z, 0);                    { mod time }
 XBWord(Z, $21);                  { mod date 1980-01-01 }
 XBLong(Z, Crc);
 XBLong(Z, Sz);                   { compressed }
 XBLong(Z, Sz);                   { uncompressed }
 XBWord(Z, Length(Name));
 XBWord(Z, 0);                    { extra len }
 For I := 1 To Length(Name) Do XBByte(Z, Byte(Name[I]));
End;

Procedure ZipAddPart(Var Z: TXBuf; Const Name: String; Var Part: TXBuf);
Var Crc: LongInt;
Begin
 If ZipPCount >= XLSX_MAX_PARTS Then Exit;
 Inc(ZipPCount);
 Crc := CRC32Buf(Part);
 ZipParts[ZipPCount].Name := Name;
 ZipParts[ZipPCount].Ofs := Z.Size;
 ZipParts[ZipPCount].Crc := Crc;
 ZipParts[ZipPCount].Size := Part.Size;
 ZipWriteLocalHeader(Z, Name, Crc, Part.Size);
 XBBytesPtr(Z, Part.Data, Part.Size);
End;

Procedure ZipFinish(Var Z: TXBuf);
Var I: Integer; CdStart, CdSize: LongInt; J: Integer;
Begin
 CdStart := Z.Size;
 For I := 1 To ZipPCount Do Begin
  XBLong(Z, ZIP_CDH_SIG);
  XBWord(Z, $0014);              { version made by }
  XBWord(Z, 20);                 { version needed }
  XBWord(Z, 0);                  { flags }
  XBWord(Z, 0);                  { method }
  XBWord(Z, 0);                  { time }
  XBWord(Z, $21);                { date }
  XBLong(Z, ZipParts[I].Crc);
  XBLong(Z, ZipParts[I].Size);
  XBLong(Z, ZipParts[I].Size);
  XBWord(Z, Length(ZipParts[I].Name));
  XBWord(Z, 0);                  { extra }
  XBWord(Z, 0);                  { comment }
  XBWord(Z, 0);                  { disk }
  XBWord(Z, 0);                  { int attr }
  XBLong(Z, 0);                  { ext attr }
  XBLong(Z, ZipParts[I].Ofs);
  For J := 1 To Length(ZipParts[I].Name) Do
   XBByte(Z, Byte(ZipParts[I].Name[J]));
 End;
 CdSize := Z.Size - CdStart;
 XBLong(Z, ZIP_EOCD_SIG);
 XBWord(Z, 0);                   { disk }
 XBWord(Z, 0);                   { cd disk }
 XBWord(Z, ZipPCount);
 XBWord(Z, ZipPCount);
 XBLong(Z, CdSize);
 XBLong(Z, CdStart);
 XBWord(Z, 0);                   { comment }
End;

Function SaveWorkbookXLSX(Const FN: String): Boolean;
Var Z, Part: TXBuf; F: File; I: Integer; NW: LongInt;
Begin
 SaveWorkbookXLSX := False;
 InitCRC32;
 CollectXSST;
 ZipPCount := 0;
 XBNew(Z, 32768);

 XBNew(Part, 4096); BuildContentTypes(Part);
 ZipAddPart(Z, '[Content_Types].xml', Part); XBFree(Part);

 XBNew(Part, 1024); BuildRootRels(Part);
 ZipAddPart(Z, '_rels/.rels', Part); XBFree(Part);

 XBNew(Part, 2048); BuildWorkbookXml(Part);
 ZipAddPart(Z, 'xl/workbook.xml', Part); XBFree(Part);

 XBNew(Part, 2048); BuildWorkbookRels(Part);
 ZipAddPart(Z, 'xl/_rels/workbook.xml.rels', Part); XBFree(Part);

 XBNew(Part, 2048); BuildStylesXml(Part);
 ZipAddPart(Z, 'xl/styles.xml', Part); XBFree(Part);

 XBNew(Part, 8192); BuildSharedStringsXml(Part);
 ZipAddPart(Z, 'xl/sharedStrings.xml', Part); XBFree(Part);

 For I := 1 To WB.Count Do Begin
  XBNew(Part, 16384); BuildSheetXml(Part, WB.Sheets[I]);
  ZipAddPart(Z, 'xl/worksheets/sheet' + IntToStr(I) + '.xml', Part);
  XBFree(Part);
 End;

 ZipFinish(Z);

 {$I-} Assign(F, FN); Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Begin XBFree(Z); Exit; End;
 {$I-} BlockWrite(F, Z.Data^, Z.Size, NW); {$I+}
 If (IOResult <> 0) Or (NW <> Z.Size) Then Begin
  Close(F); XBFree(Z); Exit;
 End;
 {$I-} Close(F); {$I+}
 XBFree(Z);
 SaveWorkbookXLSX := True;
End;

{ ====================================================================== }
{                     LECTEUR XLSX (ZIP store + XML SAX)                 }
{ ====================================================================== }

Type
 TZipMember = Record
  Name    : String[80];
  Ofs     : LongInt;     { offset of local header }
  Crc     : LongInt;
  Size    : LongInt;
  Method  : Word;
 End;

Const
 XLSX_MAX_MEMBERS = 64;

Var
 ZipMems   : Array[1..XLSX_MAX_MEMBERS] Of TZipMember;
 ZipMCount : Integer;

{ ====================================================================== }
{                  INFLATE (RFC 1951)  -  DEFLATE decoder                }
{ ====================================================================== }

Type
 TInfHuff = Record
  Count : Array[0..15] Of Integer;     { nb codes par longueur }
  Sym   : Array[0..287] Of Integer;    { symboles ordonnes par (long, val) }
 End;

Const
 INF_LBASE : Array[0..28] Of Integer = (
   3, 4, 5, 6, 7, 8, 9, 10,
   11, 13, 15, 17, 19, 23, 27, 31,
   35, 43, 51, 59, 67, 83, 99, 115,
   131, 163, 195, 227, 258);
 INF_LEXTRA: Array[0..28] Of Integer = (
   0, 0, 0, 0, 0, 0, 0, 0,
   1, 1, 1, 1, 2, 2, 2, 2,
   3, 3, 3, 3, 4, 4, 4, 4,
   5, 5, 5, 5, 0);
 INF_DBASE : Array[0..29] Of Integer = (
   1, 2, 3, 4, 5, 7, 9, 13, 17, 25,
   33, 49, 65, 97, 129, 193, 257, 385, 513, 769,
   1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577);
 INF_DEXTRA: Array[0..29] Of Integer = (
   0, 0, 0, 0, 1, 1, 2, 2, 3, 3,
   4, 4, 5, 5, 6, 6, 7, 7, 8, 8,
   9, 9, 10, 10, 11, 11, 12, 12, 13, 13);
 INF_CLORD : Array[0..18] Of Integer = (
   16, 17, 18, 0, 8, 7, 9, 6, 10, 5,
   11, 4, 12, 3, 13, 2, 14, 1, 15);

Var
 InfSrc      : TXBuf;            { copie du record source }
 InfPos      : LongInt;
 InfSrcEnd   : LongInt;
 InfBitBuf   : LongInt;
 InfBitCnt   : Integer;
 InfDst      : TXBuf;
 InfErr      : Boolean;

Procedure InfBits(N: Integer; Var V: LongInt);
Var B: Byte; Mask: LongInt;
Begin
 V := 0;
 While (InfBitCnt < N) And (InfPos < InfSrcEnd) Do Begin
  B := XBReadByte(InfSrc, InfPos);
  Inc(InfPos);
  InfBitBuf := InfBitBuf Or (LongInt(B) Shl InfBitCnt);
  Inc(InfBitCnt, 8);
 End;
 If InfBitCnt < N Then Begin InfErr := True; Exit; End;
 Mask := (LongInt(1) Shl N) - 1;
 V := InfBitBuf And Mask;
 InfBitBuf := InfBitBuf Shr N;
 Dec(InfBitCnt, N);
End;

Procedure InfAlign;
Begin
 InfBitBuf := 0;
 InfBitCnt := 0;
End;

Function InfDecode(Var H: TInfHuff): Integer;
Var Code, First, Cnt, Idx, Lvl: Integer; Bit: LongInt;
Begin
 InfDecode := -1;
 Code := 0; First := 0; Idx := 0;
 For Lvl := 1 To 15 Do Begin
  InfBits(1, Bit);
  If InfErr Then Exit;
  Code := (Code Shl 1) Or Integer(Bit);
  Cnt := H.Count[Lvl];
  If Code - First < Cnt Then Begin
   InfDecode := H.Sym[Idx + (Code - First)];
   Exit;
  End;
  Inc(Idx, Cnt);
  First := (First + Cnt) Shl 1;
 End;
 InfErr := True;
End;

Procedure InfBuildHuff(Var Lens: Array Of Integer; N: Integer;
                       Var H: TInfHuff);
Var I, L: Integer; Offs: Array[0..15] Of Integer;
Begin
 For I := 0 To 15 Do H.Count[I] := 0;
 For I := 0 To N - 1 Do
  If (Lens[I] >= 0) And (Lens[I] <= 15) Then Inc(H.Count[Lens[I]]);
 H.Count[0] := 0;
 Offs[0] := 0; Offs[1] := 0;
 For L := 1 To 14 Do Offs[L + 1] := Offs[L] + H.Count[L];
 For I := 0 To N - 1 Do
  If (Lens[I] > 0) And (Lens[I] <= 15) Then Begin
   H.Sym[Offs[Lens[I]]] := I;
   Inc(Offs[Lens[I]]);
  End;
End;

Procedure InfFixedTables(Var LH, DH: TInfHuff);
Var Lens: Array[0..287] Of Integer;
    DLens: Array[0..29] Of Integer;
    I: Integer;
Begin
 For I := 0 To 143 Do Lens[I] := 8;
 For I := 144 To 255 Do Lens[I] := 9;
 For I := 256 To 279 Do Lens[I] := 7;
 For I := 280 To 287 Do Lens[I] := 8;
 InfBuildHuff(Lens, 288, LH);
 For I := 0 To 29 Do DLens[I] := 5;
 InfBuildHuff(DLens, 30, DH);
End;

Procedure InfDynamicTables(Var LH, DH: TInfHuff);
Var HLit, HDist, HCLen, I, Sym, Last, Rep, NTot: Integer;
    Bits: LongInt;
    CLLens: Array[0..18] Of Integer;
    CLH: TInfHuff;
    Lens: Array[0..317] Of Integer;
    DLens: Array[0..29] Of Integer;
    LLens: Array[0..287] Of Integer;
Begin
 InfBits(5, Bits); HLit  := Integer(Bits) + 257;
 InfBits(5, Bits); HDist := Integer(Bits) + 1;
 InfBits(4, Bits); HCLen := Integer(Bits) + 4;
 If InfErr Then Exit;
 If (HLit > 286) Or (HDist > 30) Then Begin InfErr := True; Exit; End;
 For I := 0 To 18 Do CLLens[I] := 0;
 For I := 0 To HCLen - 1 Do Begin
  InfBits(3, Bits);
  CLLens[INF_CLORD[I]] := Integer(Bits);
 End;
 If InfErr Then Exit;
 InfBuildHuff(CLLens, 19, CLH);

 NTot := HLit + HDist;
 I := 0; Last := 0;
 While I < NTot Do Begin
  Sym := InfDecode(CLH);
  If InfErr Then Exit;
  If Sym < 16 Then Begin
   Lens[I] := Sym; Last := Sym; Inc(I);
  End
  Else If Sym = 16 Then Begin
   InfBits(2, Bits);
   If InfErr Then Exit;
   Rep := Integer(Bits) + 3;
   While Rep > 0 Do Begin
    If I >= NTot Then Begin InfErr := True; Exit; End;
    Lens[I] := Last; Inc(I); Dec(Rep);
   End;
  End
  Else If Sym = 17 Then Begin
   InfBits(3, Bits);
   If InfErr Then Exit;
   Rep := Integer(Bits) + 3;
   While Rep > 0 Do Begin
    If I >= NTot Then Begin InfErr := True; Exit; End;
    Lens[I] := 0; Inc(I); Dec(Rep);
   End;
   Last := 0;
  End
  Else If Sym = 18 Then Begin
   InfBits(7, Bits);
   If InfErr Then Exit;
   Rep := Integer(Bits) + 11;
   While Rep > 0 Do Begin
    If I >= NTot Then Begin InfErr := True; Exit; End;
    Lens[I] := 0; Inc(I); Dec(Rep);
   End;
   Last := 0;
  End
  Else Begin InfErr := True; Exit; End;
 End;
 For I := 0 To HLit - 1 Do LLens[I] := Lens[I];
 For I := 0 To HDist - 1 Do DLens[I] := Lens[HLit + I];
 InfBuildHuff(LLens, HLit, LH);
 InfBuildHuff(DLens, HDist, DH);
End;

Procedure InfDecodeBlock(Var LH, DH: TInfHuff);
Var Sym: Integer; MLen, Dist, Extra: LongInt;
    K, Src: LongInt; B: Byte;
Begin
 Repeat
  Sym := InfDecode(LH);
  If InfErr Then Exit;
  If Sym < 256 Then Begin
   XBByte(InfDst, Byte(Sym));
  End
  Else If Sym = 256 Then Exit
  Else Begin
   Sym := Sym - 257;
   If (Sym < 0) Or (Sym > 28) Then Begin InfErr := True; Exit; End;
   If INF_LEXTRA[Sym] > 0 Then InfBits(INF_LEXTRA[Sym], Extra)
                          Else Extra := 0;
   If InfErr Then Exit;
   MLen := INF_LBASE[Sym] + Extra;
   Sym := InfDecode(DH);
   If InfErr Then Exit;
   If (Sym < 0) Or (Sym > 29) Then Begin InfErr := True; Exit; End;
   If INF_DEXTRA[Sym] > 0 Then InfBits(INF_DEXTRA[Sym], Extra)
                          Else Extra := 0;
   If InfErr Then Exit;
   Dist := INF_DBASE[Sym] + Extra;
   If Dist > InfDst.Size Then Begin InfErr := True; Exit; End;
   Src := InfDst.Size - Dist;
   For K := 1 To MLen Do Begin
    B := XBReadByte(InfDst, Src);
    XBByte(InfDst, B);
    Inc(Src);
   End;
  End;
 Until False;
End;

Function Inflate(Const Src: TXBuf; SrcStart, SrcLen: LongInt;
                 ExpectedSize: LongInt; Var Dst: TXBuf): Boolean;
Var BFinal, BType: LongInt;
    LH, DH: TInfHuff;
    LenStored, NLenStored, Mask16: LongInt;
    K: LongInt; B: Byte;
Begin
 Inflate := False;
 InfSrc := Src;
 InfPos := SrcStart;
 InfSrcEnd := SrcStart + SrcLen;
 InfBitBuf := 0; InfBitCnt := 0;
 InfErr := False;
 If ExpectedSize > 0 Then XBNew(InfDst, ExpectedSize + 64)
                     Else XBNew(InfDst, 4096);
 Mask16 := 65535;
 Repeat
  InfBits(1, BFinal);
  InfBits(2, BType);
  If InfErr Then Begin XBFree(InfDst); Exit; End;
  Case BType Of
   0: Begin
       InfAlign;
       If InfPos + 4 > InfSrcEnd Then
        Begin XBFree(InfDst); Exit; End;
       LenStored := LongInt(XBReadByte(InfSrc, InfPos)) Or
                    (LongInt(XBReadByte(InfSrc, InfPos + 1)) Shl 8);
       NLenStored := LongInt(XBReadByte(InfSrc, InfPos + 2)) Or
                     (LongInt(XBReadByte(InfSrc, InfPos + 3)) Shl 8);
       Inc(InfPos, 4);
       If ((LenStored Xor Mask16) And Mask16) <> NLenStored Then
        Begin XBFree(InfDst); Exit; End;
       If InfPos + LenStored > InfSrcEnd Then
        Begin XBFree(InfDst); Exit; End;
       For K := 1 To LenStored Do Begin
        B := XBReadByte(InfSrc, InfPos);
        XBByte(InfDst, B);
        Inc(InfPos);
       End;
      End;
   1: Begin
       InfFixedTables(LH, DH);
       InfDecodeBlock(LH, DH);
       If InfErr Then Begin XBFree(InfDst); Exit; End;
      End;
   2: Begin
       InfDynamicTables(LH, DH);
       If InfErr Then Begin XBFree(InfDst); Exit; End;
       InfDecodeBlock(LH, DH);
       If InfErr Then Begin XBFree(InfDst); Exit; End;
      End;
  Else
   XBFree(InfDst); Exit;
  End;
 Until BFinal = 1;
 Dst := InfDst;
 Inflate := True;
End;

Function FindEOCD(Const Z: TXBuf; Var Pos: LongInt): Boolean;
Var I: LongInt; Start: LongInt;
Begin
 FindEOCD := False;
 If Z.Size < 22 Then Exit;
 Start := Z.Size - 22;
 If Z.Size > 65557 Then
  If Z.Size - 65557 > Start - 65535 Then ;
 I := Start;
 While I >= 0 Do Begin
  If XBReadLong(Z, I) = ZIP_EOCD_SIG Then Begin
   Pos := I; FindEOCD := True; Exit;
  End;
  Dec(I);
  If Start - I > 65535 Then Exit;
 End;
End;

Function ParseZipCD(Const Z: TXBuf): Boolean;
Var EOcd, CdOfs: LongInt; NEnt: Word; I: Integer;
    P: LongInt; FnLen, ExLen, CmLen: Word; Name: String;
    J: Integer; B: Byte;
Begin
 ParseZipCD := False;
 ZipMCount := 0;
 If Not FindEOCD(Z, EOcd) Then Exit;
 NEnt := XBReadWord(Z, EOcd + 10);
 CdOfs := XBReadLong(Z, EOcd + 16);
 P := CdOfs;
 For I := 1 To NEnt Do Begin
  If XBReadLong(Z, P) <> ZIP_CDH_SIG Then Exit;
  FnLen := XBReadWord(Z, P + 28);
  ExLen := XBReadWord(Z, P + 30);
  CmLen := XBReadWord(Z, P + 32);
  Name := '';
  For J := 0 To FnLen - 1 Do Begin
   B := XBReadByte(Z, P + 46 + J);
   If Length(Name) < 80 Then Name := Name + Chr(B);
  End;
  If ZipMCount < XLSX_MAX_MEMBERS Then Begin
   Inc(ZipMCount);
   ZipMems[ZipMCount].Name := Name;
   ZipMems[ZipMCount].Method := XBReadWord(Z, P + 10);
   ZipMems[ZipMCount].Crc := XBReadLong(Z, P + 16);
   ZipMems[ZipMCount].Size := XBReadLong(Z, P + 24);
   ZipMems[ZipMCount].Ofs := XBReadLong(Z, P + 42);
  End;
  P := P + 46 + FnLen + ExLen + CmLen;
 End;
 ParseZipCD := True;
End;

Function ZipExtract(Const Z: TXBuf; Const Name: String;
                    Var Out: TXBuf): Boolean;
Var I: Integer; M: ^TZipMember; LFH: LongInt;
    FnLen, ExLen: Word; DataOfs: LongInt; P: ^Byte;
Begin
 ZipExtract := False;
 M := Nil;
 For I := 1 To ZipMCount Do
  If ZipMems[I].Name = Name Then Begin M := @ZipMems[I]; Break; End;
 If M = Nil Then Exit;
 LFH := M^.Ofs;
 If XBReadLong(Z, LFH) <> ZIP_LFH_SIG Then Exit;
 FnLen := XBReadWord(Z, LFH + 26);
 ExLen := XBReadWord(Z, LFH + 28);
 DataOfs := LFH + 30 + FnLen + ExLen;
 { LFH peut contenir des tailles a zero (bit 3 du general purpose
   flag) - les vraies tailles sont alors dans la CD, qu'on a deja. }
 Case M^.Method Of
  0: Begin
      XBNew(Out, M^.Size + 16);
      P := Z.Data;
      Inc(LongInt(P), DataOfs);
      XBBytesPtr(Out, P, M^.Size);
      ZipExtract := True;
     End;
  8: Begin
      { taille comprimee : si LFH la donne, l'utiliser ; sinon
        prendre le reste jusqu'a la fin de l'archive (l'inflate
        s'arretera sur BFINAL). }
      ZipExtract := Inflate(Z, DataOfs, Z.Size - DataOfs,
                            M^.Size, Out);
     End;
 Else
  Exit;
 End;
End;

{ --- XML mini-scanner --- }

Function FindTag(Const X: TXBuf; Const Tag: String;
                 Start: LongInt; Var P: LongInt): Boolean;
Var I, J: LongInt; OK: Boolean;
Begin
 FindTag := False;
 If Length(Tag) = 0 Then Exit;
 I := Start;
 While I < X.Size Do Begin
  If XBReadByte(X, I) = Byte(Tag[1]) Then Begin
   OK := True;
   For J := 2 To Length(Tag) Do
    If (I + J - 1 >= X.Size) Or
       (XBReadByte(X, I + J - 1) <> Byte(Tag[J])) Then
     Begin OK := False; Break; End;
   If OK Then Begin P := I; FindTag := True; Exit; End;
  End;
  Inc(I);
 End;
End;

Function ReadAttr(Const X: TXBuf; TagStart: LongInt; Const Attr: String;
                  Var V: String): Boolean;
Var I, J, K: LongInt; OK: Boolean; Q: Byte;
Begin
 ReadAttr := False;
 V := '';
 I := TagStart;
 While (I < X.Size) And (XBReadByte(X, I) <> Byte('>')) Do Begin
  If XBReadByte(X, I) = Byte(' ') Then Begin
   OK := True;
   For J := 1 To Length(Attr) Do
    If (I + J >= X.Size) Or
       (XBReadByte(X, I + J) <> Byte(Attr[J])) Then
     Begin OK := False; Break; End;
   If OK And (I + Length(Attr) + 1 < X.Size) And
      (XBReadByte(X, I + Length(Attr) + 1) = Byte('=')) Then Begin
    K := I + Length(Attr) + 2;
    If K >= X.Size Then Exit;
    Q := XBReadByte(X, K);
    If (Q <> Byte('"')) And (Q <> Byte('''')) Then Exit;
    Inc(K);
    While (K < X.Size) And (XBReadByte(X, K) <> Q) Do Begin
     If Length(V) < 250 Then V := V + Chr(XBReadByte(X, K));
     Inc(K);
    End;
    ReadAttr := True; Exit;
   End;
  End;
  Inc(I);
 End;
End;

Function ReadTextBetween(Const X: TXBuf; FromP, ToP: LongInt): String;
Var I: LongInt; S: String; C: Char; AmpStart: LongInt;
    Ent: String;
Begin
 S := '';
 I := FromP;
 While I < ToP Do Begin
  C := Chr(XBReadByte(X, I));
  If C = '&' Then Begin
   AmpStart := I + 1; Ent := '';
   While (AmpStart < ToP) And (XBReadByte(X, AmpStart) <> Byte(';')) Do Begin
    Ent := Ent + Chr(XBReadByte(X, AmpStart));
    Inc(AmpStart);
   End;
   If Ent = 'lt' Then S := S + '<'
   Else If Ent = 'gt' Then S := S + '>'
   Else If Ent = 'amp' Then S := S + '&'
   Else If Ent = 'quot' Then S := S + '"'
   Else If Ent = 'apos' Then S := S + ''''
   Else S := S + '?';
   I := AmpStart + 1;
  End Else Begin
   If Length(S) < 250 Then S := S + C;
   Inc(I);
  End;
 End;
 ReadTextBetween := S;
End;

Function ParseColRow(Const Ref: String; Var R, C: Integer): Boolean;
Var I: Integer; CC: Integer; RR: LongInt;
Begin
 ParseColRow := False;
 CC := 0; I := 1;
 While (I <= Length(Ref)) And (Ref[I] >= 'A') And (Ref[I] <= 'Z') Do Begin
  CC := CC * 26 + (Ord(Ref[I]) - Ord('A') + 1);
  Inc(I);
 End;
 If (CC = 0) Or (I > Length(Ref)) Then Exit;
 RR := 0;
 While (I <= Length(Ref)) And (Ref[I] >= '0') And (Ref[I] <= '9') Do Begin
  RR := RR * 10 + (Ord(Ref[I]) - Ord('0'));
  Inc(I);
 End;
 If RR <= 0 Then Exit;
 C := CC - 1; R := RR - 1;
 ParseColRow := True;
End;

Procedure LoadSharedStrings(Const X: TXBuf);
Var P, Q, T1, T2: LongInt;
Begin
 XSST_Count := 0;
 P := 0;
 While FindTag(X, '<t', P, Q) Do Begin
  { skip to '>' }
  T1 := Q;
  While (T1 < X.Size) And (XBReadByte(X, T1) <> Byte('>')) Do Inc(T1);
  Inc(T1);
  { find </t> }
  If Not FindTag(X, '</t>', T1, T2) Then Break;
  If XSST_Count < XLSX_MAX_SST Then Begin
   Inc(XSST_Count);
   XSST_Strs[XSST_Count] := ReadTextBetween(X, T1, T2);
  End;
  P := T2 + 4;
 End;
End;

Procedure LoadSheetXml(Const X: TXBuf; Sh: PSheet);
Var P, CStart, CEnd, VStart, VEnd: LongInt;
    Ref, TAttr, VStr: String;
    R, C, Idx, Code: Integer;
    NumV: Double;
Begin
 P := 0;
 While FindTag(X, '<c ', P, CStart) Do Begin
  { find end of this <c ...> opening tag '>' }
  CEnd := CStart;
  While (CEnd < X.Size) And (XBReadByte(X, CEnd) <> Byte('>')) Do Inc(CEnd);
  If Not ReadAttr(X, CStart, 'r', Ref) Then Begin P := CEnd + 1; Continue; End;
  If Not ParseColRow(Ref, R, C) Then Begin P := CEnd + 1; Continue; End;
  If (R < 0) Or (R >= MAX_ROWS) Or (C < 0) Or (C >= MAX_COLS) Then Begin
   P := CEnd + 1; Continue;
  End;
  If Not ReadAttr(X, CStart, 't', TAttr) Then TAttr := '';
  { self-closing <c .../> ? }
  If XBReadByte(X, CEnd - 1) = Byte('/') Then Begin
   P := CEnd + 1; Continue;
  End;
  { find <v> }
  If FindTag(X, '<v>', CEnd, VStart) Then Begin
   VStart := VStart + 3;
   If FindTag(X, '</v>', VStart, VEnd) Then Begin
    VStr := ReadTextBetween(X, VStart, VEnd);
    If Sh^.Rows[R] = Nil Then Begin
     New(Sh^.Rows[R]); FillChar(Sh^.Rows[R]^, SizeOf(TRow), 0);
    End;
    If TAttr = 's' Then Begin
     Val(VStr, Idx, Code);
     If (Code = 0) And (Idx >= 0) And (Idx < XSST_Count) Then Begin
      Sh^.Rows[R]^[C].Kind := ckText;
      Sh^.Rows[R]^[C].Text := XSST_Strs[Idx + 1];
     End;
    End Else If TAttr = 'str' Then Begin
     Sh^.Rows[R]^[C].Kind := ckText;
     Sh^.Rows[R]^[C].Text := VStr;
    End Else Begin
     Val(VStr, NumV, Code);
     If Code = 0 Then Begin
      Sh^.Rows[R]^[C].Kind := ckNumber;
      Sh^.Rows[R]^[C].Num := NumV;
      Str(NumV:0:6, Sh^.Rows[R]^[C].Text);
     End;
    End;
    P := VEnd + 4;
    Continue;
   End;
  End;
  P := CEnd + 1;
 End;
End;

Function LoadWorkbookXLSX(Const FN: String): Boolean;
Var F: File; Z, Part: TXBuf; NR: LongInt; FS: LongInt;
    I, K: Integer; SheetNm: Array[1..MAX_SHEETS] Of String[31];
    SheetCount: Integer; P, Q, EndTag: LongInt; AttrV: String;
    Sh: PSheet;
Begin
 LoadWorkbookXLSX := False;
 XlsxErr := 1;     { open }
 InitCRC32;
 {$I-} Assign(F, FN); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 FS := FileSize(F);
 XBNew(Z, FS + 16);
 {$I-} BlockRead(F, Z.Data^, FS, NR); Close(F); {$I+}
 Z.Size := NR;
 XlsxErr := 2;     { read }
 If NR <> FS Then Begin XBFree(Z); Exit; End;
 XlsxErr := 3;     { ParseZipCD }
 If Not ParseZipCD(Z) Then Begin XBFree(Z); Exit; End;

 XlsxErr := 4;     { extract workbook.xml }
 { parse workbook.xml -> sheet names }
 If Not ZipExtract(Z, 'xl/workbook.xml', Part) Then Begin
  XBFree(Z); Exit;
 End;
 SheetCount := 0;
 P := 0;
 While FindTag(Part, '<sheet ', P, Q) Do Begin
  EndTag := Q;
  While (EndTag < Part.Size) And (XBReadByte(Part, EndTag) <> Byte('>')) Do Inc(EndTag);
  If ReadAttr(Part, Q, 'name', AttrV) Then Begin
   If SheetCount < MAX_SHEETS Then Begin
    Inc(SheetCount);
    If Length(AttrV) > 31 Then AttrV := Copy(AttrV, 1, 31);
    SheetNm[SheetCount] := AttrV;
   End;
  End;
  P := EndTag + 1;
 End;
 XBFree(Part);
 XlsxErr := 5;     { no sheets found in workbook.xml }
 If SheetCount = 0 Then Begin XBFree(Z); Exit; End;
 XlsxErr := 6;     { OK }

 { parse sharedStrings if present }
 XSST_Count := 0;
 If ZipExtract(Z, 'xl/sharedStrings.xml', Part) Then Begin
  LoadSharedStrings(Part);
  XBFree(Part);
 End;

 FreeWorkbook;
 FillChar(WB, SizeOf(WB), 0);
 WB.Count := SheetCount;
 WB.Active := 1;
 For I := 1 To SheetCount Do Begin
  New(Sh); InitSheet(Sh, SheetNm[I]);
  WB.Sheets[I] := Sh;
  If ZipExtract(Z, 'xl/worksheets/sheet' + IntToStr(I) + '.xml', Part) Then Begin
   LoadSheetXml(Part, Sh);
   XBFree(Part);
  End;
 End;
 WB.FileName := '';
 WB.Modified := False;
 XBFree(Z);
 LoadWorkbookXLSX := True;
End;


{ --- Dialogue selection de fichier --- }

Const
 FD_MAX_ENTRIES   = 512;
 FD_KIND_FILE     = 0;
 FD_KIND_DIR      = 1;
 FD_KIND_PARENT   = 2;
 FD_KIND_DRIVE    = 3;
 FD_FILTER_COUNT  = 5;

 FD_FILTER_LABEL  : Array[0..FD_FILTER_COUNT - 1] Of String[32] = (
   'Excel (XLC;XLS;XLSX)',
   'XLC (*.XLC)',
   'XLS (*.XLS)',
   'XLSX (*.XLSX)',
   'Tous (*.*)'
 );

Type
 TFDEntry = Record
  Name : String[64];
  Kind : Byte;        { FD_KIND_xxx }
 End;

Var
 FD_E         : Array[1..FD_MAX_ENTRIES] Of TFDEntry;
 FD_N         : Integer;
 FD_FilterIdx : Integer;

Function FDUpStr(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := '';
 For I := 1 To Length(S) Do R := R + UpCase(S[I]);
 FDUpStr := R;
End;

Function FDLess(Const A, B: String): Boolean;
Var I, La, Lb: Integer; Ca, Cb: Char;
Begin
 La := Length(A); Lb := Length(B);
 I := 1;
 While (I <= La) And (I <= Lb) Do Begin
  Ca := UpCase(A[I]); Cb := UpCase(B[I]);
  If Ca < Cb Then Begin FDLess := True; Exit; End;
  If Ca > Cb Then Begin FDLess := False; Exit; End;
  Inc(I);
 End;
 FDLess := La < Lb;
End;

Procedure FDSortRange(LStart, LEnd: Integer);
Var I, J: Integer; Tmp: TFDEntry;
Begin
 If LStart >= LEnd Then Exit;
 For I := LStart + 1 To LEnd Do Begin
  Tmp := FD_E[I];
  J := I - 1;
  While (J >= LStart) And FDLess(Tmp.Name, FD_E[J].Name) Do Begin
   FD_E[J + 1] := FD_E[J];
   Dec(J);
  End;
  FD_E[J + 1] := Tmp;
 End;
End;

Function FDExtUp(Const S: String): String;
Var I, K: Integer; E: String[8];
Begin
 E := ''; K := 0;
 For I := Length(S) DownTo 1 Do
  If (K = 0) And (S[I] = '.') Then K := I;
 If K > 0 Then
  For I := K + 1 To Length(S) Do
   If Length(E) < 8 Then E := E + UpCase(S[I]);
 FDExtUp := E;
End;

Function FDMatchFilter(Const Name: String): Boolean;
Var E: String;
Begin
 E := FDExtUp(Name);
 Case FD_FilterIdx Of
  0: FDMatchFilter := (E = 'XLC') Or (E = 'XLS') Or (E = 'XLSX');
  1: FDMatchFilter := (E = 'XLC');
  2: FDMatchFilter := (E = 'XLS');
  3: FDMatchFilter := (E = 'XLSX');
  4: FDMatchFilter := True;
 Else
  FDMatchFilter := True;
 End;
End;

Function FDIsDirEntry(Const Name: String): Boolean;
Var Sr: SearchRec; OK: Boolean;
Begin
 FDIsDirEntry := False;
 FindFirst(Name, Directory Or ReadOnly, Sr);
 OK := (DosError = 0) And ((Sr.Attr And Directory) <> 0);
 FindClose(Sr);
 FDIsDirEntry := OK;
End;

Procedure FDAddParentIfPossible;
Var Dir: String;
Begin
 GetDir(0, Dir);
 { 'C:\' a length 3 -> pas de parent. Sinon, on offre '..' }
 If Length(Dir) > 3 Then
  If FD_N < FD_MAX_ENTRIES Then Begin
   Inc(FD_N);
   FD_E[FD_N].Name := '..';
   FD_E[FD_N].Kind := FD_KIND_PARENT;
  End;
End;

Procedure FDAddDrives;
Var D: Byte; OK: Boolean; Sz: LongInt;
Begin
 For D := 1 To 26 Do Begin
  {$I-} Sz := DiskSize(D); {$I+}
  OK := (IOResult = 0) And (Sz > 0);
  If OK Then
   If FD_N < FD_MAX_ENTRIES Then Begin
    Inc(FD_N);
    FD_E[FD_N].Name := Chr(Ord('A') + D - 1) + ':';
    FD_E[FD_N].Kind := FD_KIND_DRIVE;
   End;
 End;
End;

Procedure FDAddDirs;
Var Sr: SearchRec; LStart: Integer;
Begin
 LStart := FD_N + 1;
 FindFirst('*.*', Directory Or ReadOnly, Sr);
 While DosError = 0 Do Begin
  If ((Sr.Attr And Directory) <> 0) And
     (Sr.Name <> '.') And (Sr.Name <> '..') Then
   If FD_N < FD_MAX_ENTRIES Then Begin
    Inc(FD_N);
    FD_E[FD_N].Name := Sr.Name;
    FD_E[FD_N].Kind := FD_KIND_DIR;
   End;
  FindNext(Sr);
 End;
 FindClose(Sr);
 FDSortRange(LStart, FD_N);
End;

Procedure FDAddFilesPass(Const Mask: String);
Var Sr: SearchRec;
Begin
 FindFirst(Mask, Archive Or ReadOnly, Sr);
 While DosError = 0 Do Begin
  If (Sr.Attr And Directory) = 0 Then
   If FDMatchFilter(Sr.Name) Then
    If FD_N < FD_MAX_ENTRIES Then Begin
     Inc(FD_N);
     FD_E[FD_N].Name := Sr.Name;
     FD_E[FD_N].Kind := FD_KIND_FILE;
    End;
  FindNext(Sr);
 End;
 FindClose(Sr);
End;

Procedure FDAddFiles;
Var LStart: Integer;
Begin
 LStart := FD_N + 1;
 { Une seule passe sur '*.*' suffit : FDMatchFilter applique le filtre. }
 FDAddFilesPass('*.*');
 FDSortRange(LStart, FD_N);
End;

Procedure FDScan;
Begin
 FD_N := 0;
 FDAddParentIfPossible;
 FDAddDrives;
 FDAddDirs;
 FDAddFiles;
End;

Function FDEntryDisplay(Const E: TFDEntry): String;
Begin
 Case E.Kind Of
  FD_KIND_PARENT : FDEntryDisplay := '[..]';
  FD_KIND_DRIVE  : FDEntryDisplay := '[-' + E.Name + '-]';
  FD_KIND_DIR    : FDEntryDisplay := '[' + E.Name + ']';
 Else
  FDEntryDisplay := E.Name;
 End;
End;

Function FileDialog(Const Title: String; SaveMode: Boolean;
                    Var FN: String): Boolean;
Var
 X1, Y1, X2, Y2: Integer;
 ListX, ListY, ListW, ListH: Integer;
 SbX, SbY1, SbY2, SbW: Integer;
 EditX, EditY, EditW: Integer;
 FltX, FltY, FltW: Integer;
 UpX1, UpY1, UpX2, UpY2: Integer;
 OkX1, OkY1, OkX2, OkY2: Integer;
 CnX1, CnY1, CnX2, CnY2: Integer;
 Sel, Top, MaxVisible: Integer;
 Buf: String; BufPos: Integer;
 K, K2: Char;
 Dir: String;
 LastB: LongInt;
 LastClickT: LongInt;
 LastClickIdx: Integer;
 ThumbY, ThumbH: Integer;
 H, Mn, Sc, Hd: Word;
 NowT: LongInt;
 I, II: Integer;
 ClickedIdx: Integer;
 Done, Accepted, JustNavigated: Boolean;
 R: Integer;

 Procedure SaveCursorIntoBuf;
 Begin
  If (Sel >= 1) And (Sel <= FD_N) And (FD_E[Sel].Kind = FD_KIND_FILE) Then Begin
   Buf := FD_E[Sel].Name;
   BufPos := Length(Buf) + 1;
  End;
 End;

 Procedure EnsureSelVisible;
 Begin
  If Sel < 1 Then Sel := 1;
  If Sel > FD_N Then Sel := FD_N;
  If Sel < Top Then Top := Sel;
  If Sel >= Top + MaxVisible Then Top := Sel - MaxVisible + 1;
  If Top < 1 Then Top := 1;
 End;

 Procedure DoRefreshList;
 Begin
  FDScan;
  GetDir(0, Dir);
  Sel := 1; Top := 1;
 End;

 Procedure DoNavigateTo(Const Path: String);
 Begin
  {$I-} ChDir(Path); {$I+}
  R := IOResult;
  If R = 0 Then Begin
   DoRefreshList;
   JustNavigated := True;
  End;
 End;

 Procedure DoActivate(Idx: Integer);
 Begin
  If (Idx < 1) Or (Idx > FD_N) Then Exit;
  Case FD_E[Idx].Kind Of
   FD_KIND_FILE   : Begin
                     Buf := FD_E[Idx].Name;
                     BufPos := Length(Buf) + 1;
                     Accepted := True; Done := True;
                    End;
   FD_KIND_DIR    : DoNavigateTo(FD_E[Idx].Name);
   FD_KIND_PARENT : DoNavigateTo('..');
   FD_KIND_DRIVE  : DoNavigateTo(FD_E[Idx].Name);
  End;
 End;

 Procedure DoCycleFilter;
 Begin
  FD_FilterIdx := (FD_FilterIdx + 1) Mod FD_FILTER_COUNT;
  FDScan;
  Sel := 1; Top := 1;
 End;

 Procedure DrawTitleBar;
 Var TLen: Integer;
 Begin
  FillBox(X1, Y1, X2, Y2, CLR_WIN_BG);
  DrawRaisedFrame(X1, Y1, X2, Y2);
  OsTitleBar(X1 + 2, Y1 + 2, X2 - 2, Y1 + 18, Title, Y1 + 5);
  TLen := Length(Title) * 8;

 End;

 Procedure DrawPathStrip;
 Var S: String; Avail: Integer;
 Begin
  TextAt(X1 + 12, Y1 + 26, CLR_TEXT, 'Dossier :');
  S := Dir;
  Avail := (UpX1 - 8) - (X1 + 12 + 80);
  If Avail < 24 Then Avail := 24;
  If Length(S) * 8 > Avail Then Begin
   While Length(S) * 8 > Avail - 24 Do Delete(S, 1, 1);
   S := '...' + S;
  End;
  TextAt(X1 + 12 + 80, Y1 + 26, CLR_TEXT, S);
 End;

 Procedure DrawUpButton;
 Begin
  FillBox(UpX1, UpY1, UpX2, UpY2, CLR_WIN_BG);
  DrawRaisedFrame(UpX1, UpY1, UpX2, UpY2);
  TextAt(UpX1 + 6, UpY1 + 4, CLR_TEXT, 'Monter');
 End;

 Procedure DrawListBox;
 Var I, Y, Idx, EW: Integer; S: String; Fg, Bg: Byte;
 Begin
  FillBox(ListX, ListY, ListX + ListW, ListY + ListH, CLR_WIN_LIGHT);
  DrawSunkenFrame(ListX, ListY, ListX + ListW, ListY + ListH);
  EW := ListW - 4;
  For I := 0 To MaxVisible - 1 Do Begin
   Idx := Top + I;
   If Idx > FD_N Then Break;
   Y := ListY + 2 + I * 10;
   S := FDEntryDisplay(FD_E[Idx]);
   If Length(S) * 8 > EW Then S := Copy(S, 1, EW Div 8);
   If Idx = Sel Then Begin
    FillBox(ListX + 2, Y, ListX + ListW - 2, Y + 9, CLR_HEADER_SEL);
    Fg := CLR_WIN_LIGHT;
   End Else Begin
    Case FD_E[Idx].Kind Of
     FD_KIND_FILE   : Fg := CLR_TEXT;
     FD_KIND_DIR    : Fg := CLR_TEXT;
     FD_KIND_PARENT : Fg := CLR_TEXT;
     FD_KIND_DRIVE  : Fg := CLR_TEXT;
    Else
     Fg := CLR_TEXT;
    End;
   End;
   Bg := 0;
   If Bg = 0 Then ;
   TextAt(ListX + 4, Y + 1, Fg, S);
  End;
 End;

 Procedure DrawScrollBar;
 Var TotH: Integer;
 Begin
  FillBox(SbX, SbY1, SbX + SbW, SbY2, CLR_WIN_BG);
  DrawSunkenFrame(SbX, SbY1, SbX + SbW, SbY2);
  TotH := SbY2 - SbY1 - 4;
  If FD_N <= MaxVisible Then Begin
   ThumbY := SbY1 + 2;
   ThumbH := TotH;
  End Else Begin
   ThumbH := (MaxVisible * TotH) Div FD_N;
   If ThumbH < 12 Then ThumbH := 12;
   If ThumbH > TotH Then ThumbH := TotH;
   ThumbY := SbY1 + 2 +
             ((Top - 1) * (TotH - ThumbH)) Div (FD_N - MaxVisible);
  End;
  FillBox(SbX + 2, ThumbY, SbX + SbW - 2, ThumbY + ThumbH - 1, CLR_HEADER_SEL);
  DrawRaisedFrame(SbX + 2, ThumbY, SbX + SbW - 2, ThumbY + ThumbH - 1);
 End;

 Procedure DrawNameField;
 Var S: String;
 Begin
  TextAt(X1 + 12, EditY + 3, CLR_TEXT, 'Nom :');
  FillBox(EditX, EditY, EditX + EditW, EditY + 14, CLR_WIN_LIGHT);
  DrawSunkenFrame(EditX - 1, EditY - 1, EditX + EditW + 1, EditY + 15);
  S := Buf;
  If Length(S) * 8 > EditW - 4 Then S := Copy(S, 1, (EditW - 4) Div 8);
  TextAt(EditX + 3, EditY + 3, CLR_TEXT, S);
  I := EditX + 3 + (BufPos - 1) * 8;
  If I < EditX + EditW Then Begin
   SetColor(CLR_TEXT);
   Line(I, EditY + 2, I, EditY + 12);
  End;
 End;

 Procedure DrawFilterButton;
 Var S: String;
 Begin
  TextAt(X1 + 12, FltY + 4, CLR_TEXT, 'Type :');
  FillBox(FltX, FltY, FltX + FltW, FltY + 18, CLR_WIN_BG);
  DrawRaisedFrame(FltX, FltY, FltX + FltW, FltY + 18);
  S := FD_FILTER_LABEL[FD_FilterIdx];
  If Length(S) * 8 > FltW - 16 Then S := Copy(S, 1, (FltW - 16) Div 8);
  TextAt(FltX + 6, FltY + 5, CLR_TEXT, S);
  { fleche cyclage a droite }
  TextAt(FltX + FltW - 12, FltY + 5, CLR_TEXT, #16);
 End;

 Procedure DrawActionButtons;
 Var Lbl: String;
 Begin
  FillBox(OkX1, OkY1, OkX2, OkY2, CLR_WIN_BG);
  DrawRaisedFrame(OkX1, OkY1, OkX2, OkY2);
  If SaveMode Then Lbl := 'Enregistrer' Else Lbl := 'Ouvrir';
  TextAt(OkX1 + (OkX2 - OkX1 - Length(Lbl) * 8) Div 2, OkY1 + 6,
         CLR_TEXT, Lbl);
  FillBox(CnX1, CnY1, CnX2, CnY2, CLR_WIN_BG);
  DrawRaisedFrame(CnX1, CnY1, CnX2, CnY2);
  TextAt(CnX1 + (CnX2 - CnX1 - 7 * 8) Div 2, CnY1 + 6, CLR_TEXT, 'Annuler');
 End;

 Procedure RedrawAll;
 Begin
  HideMouse;
  DrawTitleBar;
  DrawPathStrip;
  DrawUpButton;
  DrawListBox;
  DrawScrollBar;
  DrawNameField;
  DrawFilterButton;
  DrawActionButtons;
  ShowMouse;
 End;

 Function InBox(Mx, My, AX1, AY1, AX2, AY2: LongInt): Boolean;
 Begin
  InBox := (Mx >= AX1) And (Mx <= AX2) And (My >= AY1) And (My <= AY2);
 End;

Begin
 FileDialog := False;

 { Geometrie }
 X1 := 40; Y1 := 40; X2 := 600; Y2 := 440;
 UpX2 := X2 - 12; UpY1 := Y1 + 22; UpX2 := X2 - 12; UpY2 := UpY1 + 18;
 UpX1 := UpX2 - 70;
 ListX := X1 + 12; ListY := Y1 + 50;
 ListW := X2 - X1 - 24 - 14;
 ListH := 220;
 SbW := 12; SbX := ListX + ListW + 2;
 SbY1 := ListY; SbY2 := ListY + ListH;
 EditY := ListY + ListH + 14;
 EditX := X1 + 64; EditW := X2 - X1 - 76;
 FltY := EditY + 22;
 FltX := X1 + 64; FltW := X2 - X1 - 76;
 OkX2 := X2 - 12; OkY2 := Y2 - 12; OkX1 := OkX2 - 110; OkY1 := OkY2 - 22;
 CnX2 := OkX1 - 12; CnY2 := OkY2; CnX1 := CnX2 - 110; CnY1 := OkY1;
 MaxVisible := (ListH - 4) Div 10;

 { Initialisation }
 GetDir(0, Dir);
 If FD_FilterIdx < 0 Then FD_FilterIdx := 0;
 If FD_FilterIdx >= FD_FILTER_COUNT Then FD_FilterIdx := 0;
 FDScan;
 Sel := 1; Top := 1;
 { Si on a un nom de fichier suggere, le mettre dans Buf et chercher
   l'entree correspondante dans la liste. }
 Buf := FN; BufPos := Length(Buf) + 1;
 If Buf <> '' Then
  For I := 1 To FD_N Do
   If (FD_E[I].Kind = FD_KIND_FILE) And
      (FDUpStr(FD_E[I].Name) = FDUpStr(Buf)) Then Begin
    Sel := I; EnsureSelVisible; Break;
   End;

 RedrawAll;
 LastB := Mouse.B;
 LastClickT := 0; LastClickIdx := 0;
 Done := False; Accepted := False;

 While Not Done Do Begin
  UpdateMouse;
  JustNavigated := False;

  { --- Clic gauche --- }
  If ((Mouse.B And 1) <> 0) And ((LastB And 1) = 0) Then Begin

   { Liste : selection + double-clic }
   If InBox(Mouse.X, Mouse.Y, ListX, ListY, ListX + ListW, ListY + ListH) Then Begin
    II := (Mouse.Y - ListY - 2) Div 10;
    ClickedIdx := Top + II;
    If (ClickedIdx >= 1) And (ClickedIdx <= FD_N) Then Begin
     GetTime(H, Mn, Sc, Hd);
     NowT := ((LongInt(H) * 60 + Mn) * 60 + Sc) * 100 + Hd;
     If (ClickedIdx = LastClickIdx) And (ClickedIdx = Sel) And
        (NowT - LastClickT < 60) And (NowT - LastClickT >= 0) Then Begin
      DoActivate(ClickedIdx);
      LastClickT := 0; LastClickIdx := 0;
     End Else Begin
      Sel := ClickedIdx;
      SaveCursorIntoBuf;
      LastClickT := NowT;
      LastClickIdx := ClickedIdx;
     End;
     If Not Done Then RedrawAll;
    End;
   End

   { Scroll bar (clic direct sur le rail) }
   Else If InBox(Mouse.X, Mouse.Y, SbX, SbY1, SbX + SbW, SbY2) Then Begin
    If FD_N > MaxVisible Then Begin
     If Mouse.Y < ThumbY Then Begin
      Dec(Top, MaxVisible); If Top < 1 Then Top := 1;
      If Sel < Top Then Sel := Top;
      RedrawAll;
     End Else If Mouse.Y > ThumbY + ThumbH Then Begin
      Inc(Top, MaxVisible);
      If Top > FD_N - MaxVisible + 1 Then Top := FD_N - MaxVisible + 1;
      If Top < 1 Then Top := 1;
      If Sel < Top Then Sel := Top;
      If Sel > Top + MaxVisible - 1 Then Sel := Top + MaxVisible - 1;
      RedrawAll;
     End;
    End;
   End

   { Bouton "Monter" }
   Else If InBox(Mouse.X, Mouse.Y, UpX1, UpY1, UpX2, UpY2) Then Begin
    DoNavigateTo('..');
    RedrawAll;
   End

   { Bouton de filtre }
   Else If InBox(Mouse.X, Mouse.Y, FltX, FltY, FltX + FltW, FltY + 18) Then Begin
    DoCycleFilter;
    RedrawAll;
   End

   { Champ de saisie : place le curseur }
   Else If InBox(Mouse.X, Mouse.Y, EditX, EditY, EditX + EditW, EditY + 14) Then Begin
    II := (Mouse.X - EditX - 3) Div 8 + 1;
    If II < 1 Then II := 1;
    If II > Length(Buf) + 1 Then II := Length(Buf) + 1;
    BufPos := II;
    RedrawAll;
   End

   { OK }
   Else If InBox(Mouse.X, Mouse.Y, OkX1, OkY1, OkX2, OkY2) Then Begin
    Accepted := True; Done := True;
   End

   { Annuler }
   Else If InBox(Mouse.X, Mouse.Y, CnX1, CnY1, CnX2, CnY2) Then Begin
    Done := True;
   End;

  End;

  LastB := Mouse.B;
  If JustNavigated Then RedrawAll;

  { --- Clavier --- }
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then Begin
    K2 := ReadKey;
    Case K2 Of
     K_UP    : Begin
                If Sel > 1 Then Dec(Sel);
                EnsureSelVisible;
                SaveCursorIntoBuf;
                RedrawAll;
               End;
     K_DOWN  : Begin
                If Sel < FD_N Then Inc(Sel);
                EnsureSelVisible;
                SaveCursorIntoBuf;
                RedrawAll;
               End;
     K_PGUP  : Begin
                Dec(Sel, MaxVisible); If Sel < 1 Then Sel := 1;
                EnsureSelVisible;
                SaveCursorIntoBuf;
                RedrawAll;
               End;
     K_PGDN  : Begin
                Inc(Sel, MaxVisible); If Sel > FD_N Then Sel := FD_N;
                EnsureSelVisible;
                SaveCursorIntoBuf;
                RedrawAll;
               End;
     K_HOME  : Begin BufPos := 1; RedrawAll; End;
     K_END   : Begin BufPos := Length(Buf) + 1; RedrawAll; End;
     K_LEFT  : Begin If BufPos > 1 Then Dec(BufPos); RedrawAll; End;
     K_RIGHT : Begin
                If BufPos <= Length(Buf) Then Inc(BufPos);
                RedrawAll;
               End;
     K_DEL   : Begin
                If BufPos <= Length(Buf) Then Delete(Buf, BufPos, 1);
                RedrawAll;
               End;
    End;
   End Else Begin
    Case K Of
     #27 : Done := True;
     #13 : Begin
            { Si la selection courante est un dossier/lecteur et que
              le buffer reflete encore son nom OU est vide, on navigue.
              Sinon on accepte le buffer comme nom de fichier. }
            If (Sel >= 1) And (Sel <= FD_N) And
               (FD_E[Sel].Kind <> FD_KIND_FILE) Then Begin
             DoActivate(Sel);
             RedrawAll;
            End Else Begin
             Accepted := True; Done := True;
            End;
           End;
     #9  : Begin DoCycleFilter; RedrawAll; End;
     #8  : Begin
            If BufPos > 1 Then Begin
             Delete(Buf, BufPos - 1, 1); Dec(BufPos);
             RedrawAll;
            End;
           End;
     Else
      If (K >= ' ') And (Length(Buf) < 64) Then Begin
       Insert(K, Buf, BufPos); Inc(BufPos);
       RedrawAll;
      End;
    End;
   End;
  End;
 End;

 NeedFullRedraw := True;
 If Accepted And (Buf <> '') Then Begin
  { Si l'utilisateur a tape un chemin se terminant par '\' : naviguer
    et redemander (mais ici on est deja sorti, donc on traite comme
    nom de fichier). On essaye quand meme ChDir si Buf est un dossier. }
  If FDIsDirEntry(Buf) Then Begin
   {$I-} ChDir(Buf); {$I+}
   R := IOResult;
   If R = 0 Then ; { ignore : pas de fichier choisi }
   FileDialog := False;
   Exit;
  End;
  FN := Buf;
  { Ajout d'extension par defaut selon le filtre courant si aucune. }
  If Pos('.', FN) = 0 Then
   Case FD_FilterIdx Of
    1: FN := FN + '.XLC';
    2: FN := FN + '.XLS';
    3: FN := FN + '.XLSX';
   Else
    FN := FN + '.XLC';
   End;
  FileDialog := True;
 End;
End;

{ --- Actions de menu --- }

Procedure ActionSaveAs;
Var FN: String; OK: Boolean;
Begin
 FN := WB.FileName;
 If FN = '' Then FN := 'classeur.XLC';
 If FileDialog('Enregistrer sous', True, FN) Then Begin
  If IsXLSXExt(FN) Then OK := SaveWorkbookXLSX(FN)
  Else If IsXLSExt(FN) Then OK := SaveWorkbookXLS(FN)
                       Else OK := SaveWorkbookXLC(FN);
  If OK Then Begin
   WB.FileName := FN;
   WB.Modified := False;
   MessageBox('Enregistrement', 'Classeur enregistre.');
  End Else
   MessageBox('Erreur', 'Impossible d''ecrire le fichier.');
 End;
End;

Procedure ActionSave;
Var OK: Boolean;
Begin
 If WB.FileName = '' Then ActionSaveAs
 Else Begin
  If IsXLSXExt(WB.FileName) Then OK := SaveWorkbookXLSX(WB.FileName)
  Else If IsXLSExt(WB.FileName) Then OK := SaveWorkbookXLS(WB.FileName)
                                Else OK := SaveWorkbookXLC(WB.FileName);
  If OK Then WB.Modified := False
  Else MessageBox('Erreur', 'Impossible d''ecrire le fichier.');
 End;
End;

Procedure ActionOpen;
Var FN: String; OK: Boolean;
Begin
 FN := '';
 If WB.Modified Then
  If Not ConfirmDialog('Ouvrir',
                       'Modifications non enregistrees. Continuer ?') Then Exit;
 If FileDialog('Ouvrir', False, FN) Then Begin
  If IsXLSXExt(FN) Then OK := LoadWorkbookXLSX(FN)
  Else If IsXLSExt(FN) Then OK := LoadWorkbookXLS(FN)
                       Else OK := LoadWorkbookXLC(FN);
  If Not OK Then
   MessageBox('Erreur', 'Fichier illisible ou format invalide.');
  NeedFullRedraw := True;
 End;
End;

{ Ajoute une nouvelle feuille en fin de classeur et l'active. }
Procedure ActionAddSheet;
Var Sh: PSheet; N: Integer; Base, S: String; Existe: Boolean; I, Idx: Integer;
Begin
 If WB.Count >= MAX_SHEETS Then Begin
  MessageBox('Insertion', 'Nombre maximal de feuilles atteint.');
  Exit;
 End;
 N := WB.Count + 1;
 Repeat
  Base := 'Feuil' + IntToStr(N);
  Existe := False;
  For I := 1 To WB.Count Do
   If (WB.Sheets[I] <> Nil) And (WB.Sheets[I]^.Name = Base) Then Begin
    Existe := True; Break;
   End;
  If Existe Then Inc(N) Else Break;
 Until False;
 S := Base;
 If InputDialog('Inserer feuille', 'Nom :', S, MAX_TAB_NAME) Then Begin
  If S = '' Then S := Base;
  For I := 1 To WB.Count Do
   If (WB.Sheets[I] <> Nil) And (UpStr(WB.Sheets[I]^.Name) = UpStr(S)) Then Begin
    MessageBox('Insertion', 'Une feuille porte deja ce nom.');
    Exit;
   End;
  Idx := WB.Count + 1;
  New(Sh); InitSheet(Sh, S);
  WB.Sheets[Idx] := Sh;
  WB.Count := Idx;
  WB.Active := Idx;
  WB.Modified := True;
  NeedFullRedraw := True;
 End;
End;

{ Supprime la feuille active (avec confirmation). }
Procedure ActionDeleteSheet;
Var I, R, C: Integer; Sh: PSheet; Row: PRow;
Begin
 If WB.Count <= 1 Then Begin
  MessageBox('Supprimer feuille',
             'Impossible : un classeur doit contenir au moins une feuille.');
  Exit;
 End;
 If Not ConfirmDialog('Supprimer feuille',
   'Supprimer ' + WB.Sheets[WB.Active]^.Name + ' ?') Then Exit;
 Sh := WB.Sheets[WB.Active];
 For R := 0 To MAX_ROWS - 1 Do Begin
  Row := Sh^.Rows[R];
  If Row = Nil Then Continue;
  For C := 0 To MAX_COLS - 1 Do
   If Row^[C].Formula <> Nil Then Begin
    Dispose(Row^[C].Formula); Row^[C].Formula := Nil;
   End;
  Dispose(Row); Sh^.Rows[R] := Nil;
 End;
 Dispose(Sh);
 { Liberer images de la feuille et decaler le tableau parallele }
 FreeSheetImages(WB.Active);
 FreeSheetCharts(WB.Active);
 For I := WB.Active To WB.Count - 1 Do Begin
  WB.Sheets[I] := WB.Sheets[I + 1];
  SheetImageCount[I] := SheetImageCount[I + 1];
  For C := 1 To MAX_IMAGES_PER_SHEET Do
   SheetImages[I, C] := SheetImages[I + 1, C];
  SheetChartCount[I] := SheetChartCount[I + 1];
  For C := 1 To MAX_CHARTS_PER_SHEET Do
   SheetCharts[I, C] := SheetCharts[I + 1, C];
 End;
 WB.Sheets[WB.Count] := Nil;
 SheetImageCount[WB.Count] := 0;
 For C := 1 To MAX_IMAGES_PER_SHEET Do SheetImages[WB.Count, C] := Nil;
 SheetChartCount[WB.Count] := 0;
 For C := 1 To MAX_CHARTS_PER_SHEET Do SheetCharts[WB.Count, C] := Nil;
 Dec(WB.Count);
 If WB.Active > WB.Count Then WB.Active := WB.Count;
 WB.Modified := True;
 NeedFullRedraw := True;
 RecalcWorkbook;
End;

{ ====================================================================== }
{           PHASE 7 : INSERTION D'IMAGE BMP 4 bpp                        }
{ ====================================================================== }

Function LoadBMP4(Const FN: String; Var Img: PImage): Boolean;
Var F: File; Buf: Array[0..63] Of Byte;
    BfOffBits: LongInt;
    BiSize, BiWidth, BiHeight, BiCompression: LongInt;
    BiPlanes, BiBitCount: Word;
    Palette: Array[0..15] Of Byte;
    PalBGRA: Array[0..15, 0..3] Of Byte;
    RowBytes, PadBytes, X, Y, I: Integer;
    Row: Array[0..255] Of Byte;
    B: Byte; P: ^Byte;
Begin
 LoadBMP4 := False;
 Img := Nil;
 {$I-} Assign(F, FN); Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 BlockRead(F, Buf, 14);
 If (Buf[0] <> Ord('B')) Or (Buf[1] <> Ord('M')) Then Begin Close(F); Exit; End;
 BfOffBits := LongInt(Buf[10]) Or (LongInt(Buf[11]) Shl 8) Or
              (LongInt(Buf[12]) Shl 16) Or (LongInt(Buf[13]) Shl 24);
 BlockRead(F, Buf, 40);
 BiSize := LongInt(Buf[0]) Or (LongInt(Buf[1]) Shl 8) Or
           (LongInt(Buf[2]) Shl 16) Or (LongInt(Buf[3]) Shl 24);
 If BiSize <> 40 Then Begin Close(F); Exit; End;
 BiWidth := LongInt(Buf[4]) Or (LongInt(Buf[5]) Shl 8) Or
            (LongInt(Buf[6]) Shl 16) Or (LongInt(Buf[7]) Shl 24);
 BiHeight := LongInt(Buf[8]) Or (LongInt(Buf[9]) Shl 8) Or
             (LongInt(Buf[10]) Shl 16) Or (LongInt(Buf[11]) Shl 24);
 BiPlanes := Word(Buf[12]) Or (Word(Buf[13]) Shl 8);
 BiBitCount := Word(Buf[14]) Or (Word(Buf[15]) Shl 8);
 BiCompression := LongInt(Buf[16]) Or (LongInt(Buf[17]) Shl 8) Or
                  (LongInt(Buf[18]) Shl 16) Or (LongInt(Buf[19]) Shl 24);
 If (BiPlanes <> 1) Or (BiBitCount <> 4) Or (BiCompression <> 0) Or
    (BiWidth <= 0) Or (BiWidth > MAX_IMG_W) Or
    (BiHeight <= 0) Or (BiHeight > MAX_IMG_H) Then Begin Close(F); Exit; End;
 BlockRead(F, PalBGRA, 64);
 For I := 0 To 15 Do
  Palette[I] := ColorNearest(PalBGRA[I, 2], PalBGRA[I, 1], PalBGRA[I, 0]);
 Seek(F, BfOffBits);
 RowBytes := (BiWidth + 1) Div 2;
 PadBytes := ((RowBytes + 3) And (Not 3)) - RowBytes;
 New(Img);
 Img^.W := BiWidth; Img^.H := BiHeight;
 Img^.Anchor_R := 0; Img^.Anchor_C := 0;
 GetMem(Img^.Pixels, LongInt(BiWidth) * BiHeight);
 For Y := BiHeight - 1 Downto 0 Do Begin
  BlockRead(F, Row, RowBytes);
  If PadBytes > 0 Then BlockRead(F, Buf, PadBytes);
  P := Img^.Pixels;
  Inc(P, LongInt(Y) * BiWidth);
  For X := 0 To BiWidth - 1 Do Begin
   B := Row[X Shr 1];
   If (X And 1) = 0 Then B := B Shr 4 Else B := B And $0F;
   P^ := Palette[B];
   Inc(P);
  End;
 End;
 Close(F);
 LoadBMP4 := True;
End;

Procedure ActionInsertImage;
Var FN: String; Img: PImage; Sh: PSheet; N: Integer;
Begin
 N := SheetImageCount[WB.Active];
 If N >= MAX_IMAGES_PER_SHEET Then Begin
  MessageBox('Inserer image', 'Nombre maximal d''images atteint.');
  Exit;
 End;
 FN := '';
 If Not InputDialog('Inserer image', 'Fichier .BMP (4 bpp) :', FN, 64) Then Exit;
 If FN = '' Then Exit;
 If Not LoadBMP4(FN, Img) Then Begin
  MessageBox('Inserer image',
             'Echec : BMP 4 bpp non compresse requis, max '
             + IntToStr(MAX_IMG_W) + 'x' + IntToStr(MAX_IMG_H) + '.');
  Exit;
 End;
 Sh := ActiveSheet;
 Img^.Anchor_R := Sh^.CurRow;
 Img^.Anchor_C := Sh^.CurCol;
 Inc(N);
 SheetImages[WB.Active, N] := Img;
 SheetImageCount[WB.Active] := N;
 WB.Modified := True;
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{           PHASE 8 : DIALOGUE ET INSERTION DE GRAPHIQUE                 }
{ ====================================================================== }

Function ParseCellTok(Const S: String; Var P: Integer;
                     Var R, C: Integer): Boolean;
Var Letters, Digits: String; I, Code: Integer; Cc, Rr: Integer;
Begin
 ParseCellTok := False;
 Letters := ''; Digits := '';
 While (P <= Length(S)) And (UpCase(S[P]) >= 'A') And
       (UpCase(S[P]) <= 'Z') Do Begin
  Letters := Letters + UpCase(S[P]); Inc(P);
 End;
 While (P <= Length(S)) And (S[P] >= '0') And (S[P] <= '9') Do Begin
  Digits := Digits + S[P]; Inc(P);
 End;
 If (Letters = '') Or (Digits = '') Then Exit;
 Cc := 0;
 For I := 1 To Length(Letters) Do
  Cc := Cc * 26 + (Ord(Letters[I]) - Ord('A') + 1);
 Dec(Cc);
 Val(Digits, Rr, Code); If Code <> 0 Then Exit; Dec(Rr);
 If (Rr < 0) Or (Cc < 0) Or (Rr >= MAX_ROWS) Or (Cc >= MAX_COLS) Then Exit;
 R := Rr; C := Cc;
 ParseCellTok := True;
End;

Function ParseRangeStr(Const S: String;
                       Var R1, C1, R2, C2: Integer): Boolean;
Var P: Integer;
Begin
 ParseRangeStr := False;
 P := 1;
 If Not ParseCellTok(S, P, R1, C1) Then Exit;
 If (P <= Length(S)) And (S[P] = ':') Then Begin
  Inc(P);
  If Not ParseCellTok(S, P, R2, C2) Then Exit;
 End Else Begin R2 := R1; C2 := C1; End;
 ParseRangeStr := True;
End;

Function ChartDialog(Var Kind: TChartKind;
                     Var Title, Range: String): Boolean;
Var KindStr: String; KCh: Char;
Begin
 ChartDialog := False;
 Case Kind Of
  chBar:  KindStr := 'B';
  chLine: KindStr := 'L';
  chPie:  KindStr := 'P';
  Else    KindStr := 'B';
 End;
 If Not InputDialog('Graphique 1/3',
                    'Type (B=barres L=lignes P=secteurs) :',
                    KindStr, 4) Then Exit;
 If Length(KindStr) = 0 Then Exit;
 KCh := UpCase(KindStr[1]);
 Case KCh Of
  'B': Kind := chBar;
  'L': Kind := chLine;
  'P': Kind := chPie;
  Else Begin
   MessageBox('Graphique', 'Type invalide (B, L ou P).');
   Exit;
  End;
 End;
 If Not InputDialog('Graphique 2/3', 'Titre :', Title, 32) Then Exit;
 If Not InputDialog('Graphique 3/3', 'Plage (ex. A1:A10) :',
                    Range, 32) Then Exit;
 ChartDialog := True;
End;

Procedure ActionInsertChart;
Var Sh: PSheet; Ch: PChart; Kind: TChartKind;
    Title, Range: String;
    R1, C1, R2, C2, T, N: Integer;
Begin
 N := SheetChartCount[WB.Active];
 If N >= MAX_CHARTS_PER_SHEET Then Begin
  MessageBox('Inserer graphique',
             'Nombre maximal de graphiques atteint.');
  Exit;
 End;
 Sh := ActiveSheet;
 Title := 'Graphique';
 Range := CellRef(Sh^.SelR1, Sh^.SelC1) + ':' +
          CellRef(Sh^.SelR2, Sh^.SelC2);
 Kind := chBar;
 If Not ChartDialog(Kind, Title, Range) Then Exit;
 If Not ParseRangeStr(Range, R1, C1, R2, C2) Then Begin
  MessageBox('Inserer graphique', 'Plage invalide.');
  Exit;
 End;
 If R1 > R2 Then Begin T := R1; R1 := R2; R2 := T; End;
 If C1 > C2 Then Begin T := C1; C1 := C2; C2 := T; End;
 New(Ch);
 Ch^.Kind := Kind;
 Ch^.Anchor_R := Sh^.CurRow;
 Ch^.Anchor_C := Sh^.CurCol;
 Ch^.W := 240; Ch^.H := 150;
 Ch^.R1 := R1; Ch^.C1 := C1; Ch^.R2 := R2; Ch^.C2 := C2;
 Ch^.Title := Title;
 Inc(N);
 SheetCharts[WB.Active, N] := Ch;
 SheetChartCount[WB.Active] := N;
 WB.Modified := True;
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{                       PHASE 2 : PLAGES, PRESSE-PAPIER, UNDO            }
{ ====================================================================== }

Procedure NormalizeRect(Var R1, C1, R2, C2: Integer);
Var T: Integer;
Begin
 If R1 > R2 Then Begin T := R1; R1 := R2; R2 := T; End;
 If C1 > C2 Then Begin T := C1; C1 := C2; C2 := T; End;
End;

Procedure RecordCellUndo(SheetIdx, R, C: Integer);
Var Sh: PSheet; Src: TCell; U: PUndoCell;
Begin
 If Not InUndoOp Then Exit;
 Sh := WB.Sheets[SheetIdx];
 Src := GetCellRef(Sh, R, C);
 New(U);
 U^.Sheet := SheetIdx;
 U^.R := R; U^.C := C;
 U^.Kind := Src.Kind;
 U^.Text := Src.Text;
 U^.Num  := Src.Num;
 U^.Style := Src.Style;
 U^.Align := Src.Align;
 U^.Format := Src.Format;
 U^.Fg := Src.Fg; U^.Bg := Src.Bg;
 U^.Formula := Nil;
 If (Src.Kind = ckFormula) And (Src.Formula <> Nil) Then Begin
  New(U^.Formula);
  U^.Formula^ := Src.Formula^;
 End;
 U^.Next := CurUndoHead;
 CurUndoHead := U;
End;

Procedure FreeUndoList(Var Head: PUndoCell);
Var P, Q: PUndoCell;
Begin
 P := Head;
 While P <> Nil Do Begin
  Q := P^.Next;
  If P^.Formula <> Nil Then Dispose(P^.Formula);
  Dispose(P);
  P := Q;
 End;
 Head := Nil;
End;

Procedure ClearRedoStack;
Var I: Integer;
Begin
 For I := 1 To UNDO_DEPTH Do
  If RedoStack[I].Used Then Begin
   FreeUndoList(RedoStack[I].Head);
   RedoStack[I].Used := False;
   RedoStack[I].Desc := '';
  End;
 RedoTop := 0;
End;

Procedure PushUndoOp(Const Desc: String; AlsoClearRedo: Boolean);
Var I: Integer;
Begin
 If CurUndoHead = Nil Then Exit;
 If UndoTop >= UNDO_DEPTH Then Begin
  FreeUndoList(UndoStack[1].Head);
  For I := 1 To UNDO_DEPTH - 1 Do UndoStack[I] := UndoStack[I + 1];
  UndoStack[UNDO_DEPTH].Used := False;
  UndoStack[UNDO_DEPTH].Head := Nil;
  UndoStack[UNDO_DEPTH].Desc := '';
  Dec(UndoTop);
 End;
 Inc(UndoTop);
 UndoStack[UndoTop].Used := True;
 UndoStack[UndoTop].Head := CurUndoHead;
 UndoStack[UndoTop].Desc := Desc;
 CurUndoHead := Nil;
 If AlsoClearRedo Then ClearRedoStack;
End;

Procedure BeginUndoOp;
Begin
 InUndoOp := True;
 CurUndoHead := Nil;
End;

Procedure EndUndoOp(Const Desc: String);
Begin
 InUndoOp := False;
 PushUndoOp(Desc, True);
 RecalcWorkbook;
End;

Function SwapCell(U: PUndoCell): PUndoCell;
Var Sh: PSheet; Row: PRow; Cur: ^TCell; Saved: PUndoCell;
Begin
 SwapCell := Nil;
 Sh := WB.Sheets[U^.Sheet];
 Row := GetRow(Sh, U^.R);
 If Row = Nil Then Exit;
 Cur := @Row^[U^.C];
 New(Saved);
 Saved^.Sheet := U^.Sheet;
 Saved^.R := U^.R; Saved^.C := U^.C;
 Saved^.Kind := Cur^.Kind;
 Saved^.Text := Cur^.Text;
 Saved^.Num  := Cur^.Num;
 Saved^.Style := Cur^.Style;
 Saved^.Align := Cur^.Align;
 Saved^.Format := Cur^.Format;
 Saved^.Fg := Cur^.Fg; Saved^.Bg := Cur^.Bg;
 Saved^.Formula := Nil;
 If (Cur^.Kind = ckFormula) And (Cur^.Formula <> Nil) Then Begin
  New(Saved^.Formula);
  Saved^.Formula^ := Cur^.Formula^;
 End;
 Saved^.Next := Nil;
 If Cur^.Formula <> Nil Then Begin Dispose(Cur^.Formula); Cur^.Formula := Nil; End;
 Cur^.Kind := U^.Kind;
 Cur^.Text := U^.Text;
 Cur^.Num  := U^.Num;
 Cur^.Style := U^.Style;
 Cur^.Align := U^.Align;
 Cur^.Format := U^.Format;
 Cur^.Fg := U^.Fg; Cur^.Bg := U^.Bg;
 If (U^.Kind = ckFormula) And (U^.Formula <> Nil) Then Begin
  New(Cur^.Formula);
  Cur^.Formula^ := U^.Formula^;
 End;
 SwapCell := Saved;
End;

Procedure ApplyOpReverse(Var Op: TUndoOp; Var DestHead: PUndoCell);
Var P, Sw: PUndoCell;
Begin
 DestHead := Nil;
 P := Op.Head;
 While P <> Nil Do Begin
  Sw := SwapCell(P);
  If Sw <> Nil Then Begin
   Sw^.Next := DestHead;
   DestHead := Sw;
  End;
  P := P^.Next;
 End;
End;

Procedure DoUndo;
Var DestHead: PUndoCell; I: Integer;
Begin
 If UndoTop = 0 Then Exit;
 ApplyOpReverse(UndoStack[UndoTop], DestHead);
 If RedoTop >= UNDO_DEPTH Then Begin
  FreeUndoList(RedoStack[1].Head);
  For I := 1 To UNDO_DEPTH - 1 Do RedoStack[I] := RedoStack[I + 1];
  RedoStack[UNDO_DEPTH].Used := False;
  RedoStack[UNDO_DEPTH].Head := Nil;
  Dec(RedoTop);
 End;
 Inc(RedoTop);
 RedoStack[RedoTop].Used := True;
 RedoStack[RedoTop].Head := DestHead;
 RedoStack[RedoTop].Desc := UndoStack[UndoTop].Desc;
 FreeUndoList(UndoStack[UndoTop].Head);
 UndoStack[UndoTop].Used := False;
 UndoStack[UndoTop].Desc := '';
 Dec(UndoTop);
 NeedFullRedraw := True;
 RecalcWorkbook;
End;

Procedure DoRedo;
Var DestHead: PUndoCell; I: Integer;
Begin
 If RedoTop = 0 Then Exit;
 ApplyOpReverse(RedoStack[RedoTop], DestHead);
 If UndoTop >= UNDO_DEPTH Then Begin
  FreeUndoList(UndoStack[1].Head);
  For I := 1 To UNDO_DEPTH - 1 Do UndoStack[I] := UndoStack[I + 1];
  UndoStack[UNDO_DEPTH].Used := False;
  UndoStack[UNDO_DEPTH].Head := Nil;
  Dec(UndoTop);
 End;
 Inc(UndoTop);
 UndoStack[UndoTop].Used := True;
 UndoStack[UndoTop].Head := DestHead;
 UndoStack[UndoTop].Desc := RedoStack[RedoTop].Desc;
 FreeUndoList(RedoStack[RedoTop].Head);
 RedoStack[RedoTop].Used := False;
 Dec(RedoTop);
 NeedFullRedraw := True;
 RecalcWorkbook;
End;

Procedure ClearRange(SheetIdx, R1, C1, R2, C2: Integer);
Var Sh: PSheet; R, C: Integer; Row: PRow;
Begin
 NormalizeRect(R1, C1, R2, C2);
 Sh := WB.Sheets[SheetIdx];
 For R := R1 To R2 Do Begin
  Row := PeekRow(Sh, R);
  If Row = Nil Then Continue;
  For C := C1 To C2 Do Begin
   RecordCellUndo(SheetIdx, R, C);
   CellClear(Row^[C]);
  End;
 End;
End;

Procedure SelectionClear;
Var Sh: PSheet;
Begin
 Sh := ActiveSheet;
 BeginUndoOp;
 ClearRange(WB.Active, Sh^.SelR1, Sh^.SelC1, Sh^.SelR2, Sh^.SelC2);
 EndUndoOp('Effacer');
 WB.Modified := True;
 NeedFullRedraw := True;
End;

Procedure ClipFreeFormulas;
Var I: Integer;
Begin
 For I := 0 To CLIP_MAX_CELLS - 1 Do
  If Clip.Cells[I].Formula <> Nil Then Begin
   Dispose(Clip.Cells[I].Formula);
   Clip.Cells[I].Formula := Nil;
  End;
End;

Function CopySelectionToClip(CutMode: Boolean): Boolean;
Var Sh: PSheet; R1, C1, R2, C2, R, C, Idx: Integer; Src: TCell;
Begin
 CopySelectionToClip := False;
 Sh := ActiveSheet;
 R1 := Sh^.SelR1; C1 := Sh^.SelC1; R2 := Sh^.SelR2; C2 := Sh^.SelC2;
 NormalizeRect(R1, C1, R2, C2);
 If LongInt(R2 - R1 + 1) * LongInt(C2 - C1 + 1) > CLIP_MAX_CELLS Then Exit;
 ClipFreeFormulas;
 Clip.Rows := R2 - R1 + 1;
 Clip.Cols := C2 - C1 + 1;
 Clip.Valid := True;
 Clip.CutMode := CutMode;
 Clip.CutR := R1; Clip.CutC := C1;
 Clip.CutSheet := WB.Active;
 For R := 0 To Clip.Rows - 1 Do
  For C := 0 To Clip.Cols - 1 Do Begin
   Idx := R * Clip.Cols + C;
   Src := GetCellRef(Sh, R1 + R, C1 + C);
   Clip.Cells[Idx].Kind := Src.Kind;
   Clip.Cells[Idx].Text := Src.Text;
   Clip.Cells[Idx].Num  := Src.Num;
   Clip.Cells[Idx].Style := Src.Style;
   Clip.Cells[Idx].Align := Src.Align;
   Clip.Cells[Idx].Format := Src.Format;
   Clip.Cells[Idx].Fg := Src.Fg; Clip.Cells[Idx].Bg := Src.Bg;
   Clip.Cells[Idx].Formula := Nil;
   If (Src.Kind = ckFormula) And (Src.Formula <> Nil) Then Begin
    New(Clip.Cells[Idx].Formula);
    Clip.Cells[Idx].Formula^ := Src.Formula^;
   End;
  End;
 NeedFullRedraw := True;
 CopySelectionToClip := True;
End;

Procedure PasteAt(DstR, DstC: Integer);
Var Sh: PSheet; R, C, Idx: Integer; Row: PRow; Dst: ^TCell; Src: ^TClipCell;
    SrcSh: PSheet;
Begin
 If Not Clip.Valid Then Exit;
 Sh := ActiveSheet;
 BeginUndoOp;
 For R := 0 To Clip.Rows - 1 Do Begin
  If DstR + R >= MAX_ROWS Then Break;
  Row := GetRow(Sh, DstR + R);
  If Row = Nil Then Continue;
  For C := 0 To Clip.Cols - 1 Do Begin
   If DstC + C >= MAX_COLS Then Break;
   Idx := R * Clip.Cols + C;
   Src := @Clip.Cells[Idx];
   RecordCellUndo(WB.Active, DstR + R, DstC + C);
   Dst := @Row^[DstC + C];
   If Dst^.Formula <> Nil Then Begin Dispose(Dst^.Formula); Dst^.Formula := Nil; End;
   FillChar(Dst^, SizeOf(Dst^), 0);
   Dst^.Kind := Src^.Kind;
   Dst^.Text := Src^.Text;
   Dst^.Num  := Src^.Num;
   Dst^.Style := Src^.Style;
   Dst^.Align := Src^.Align;
   Dst^.Format := Src^.Format;
   Dst^.Fg := Src^.Fg; Dst^.Bg := Src^.Bg;
   Dst^.Formula := Nil;
   If (Src^.Kind = ckFormula) And (Src^.Formula <> Nil) Then Begin
    New(Dst^.Formula);
    Dst^.Formula^ := Src^.Formula^;
   End;
  End;
 End;
 If Clip.CutMode And (Clip.CutSheet >= 1) And (Clip.CutSheet <= WB.Count) Then Begin
  SrcSh := WB.Sheets[Clip.CutSheet];
  For R := 0 To Clip.Rows - 1 Do
   For C := 0 To Clip.Cols - 1 Do Begin
    RecordCellUndo(Clip.CutSheet, Clip.CutR + R, Clip.CutC + C);
    ClearCell(SrcSh, Clip.CutR + R, Clip.CutC + C);
   End;
  Clip.CutMode := False;
 End;
 EndUndoOp('Coller');
 Sh^.CurRow := DstR; Sh^.CurCol := DstC;
 Sh^.SelR1 := DstR; Sh^.SelC1 := DstC;
 Sh^.SelR2 := MinI(DstR + Clip.Rows - 1, MAX_ROWS - 1);
 Sh^.SelC2 := MinI(DstC + Clip.Cols - 1, MAX_COLS - 1);
 SelAnchorR := DstR; SelAnchorC := DstC;
 WB.Modified := True;
 NeedFullRedraw := True;
End;

Procedure ActionCopy;
Begin If CopySelectionToClip(False) Then ; End;

Procedure ActionCut;
Begin If CopySelectionToClip(True) Then ; End;

Procedure ActionPaste;
Var Sh: PSheet;
Begin
 If Not Clip.Valid Then Exit;
 Sh := ActiveSheet;
 PasteAt(Sh^.CurRow, Sh^.CurCol);
End;

Procedure CommitInputWithUndo(MoveDown: Boolean);
Var Sh: PSheet;
Begin
 Sh := ActiveSheet;
 BeginUndoOp;
 RecordCellUndo(WB.Active, Sh^.CurRow, Sh^.CurCol);
 SetCellText(Sh, Sh^.CurRow, Sh^.CurCol, InputBuf);
 EndUndoOp('Saisie');
 WB.Modified := True;
 InputMode := False;
 InputBuf := '';
 If MoveDown Then MoveCursor(1, 0);
End;

{ ====================================================================== }
{                       PHASE 3 : FORMATAGE DES CELLULES                 }
{ ====================================================================== }

{ -- Applique une fonction de mutation a chaque cellule de la selection -- }

Procedure ApplyStyleToggle(Mask: Byte);
Var Sh: PSheet; R, C: Integer; Row: PRow; Cell: ^TCell;
    AllSet: Boolean;
Begin
 Sh := ActiveSheet;
 { Decider : toggle base sur la cellule active }
 Row := PeekRow(Sh, Sh^.CurRow);
 If Row <> Nil Then AllSet := (Row^[Sh^.CurCol].Style And Mask) <> 0
                 Else AllSet := False;
 BeginUndoOp;
 For R := Sh^.SelR1 To Sh^.SelR2 Do Begin
  Row := GetRow(Sh, R);
  If Row = Nil Then Continue;
  For C := Sh^.SelC1 To Sh^.SelC2 Do Begin
   RecordCellUndo(WB.Active, R, C);
   Cell := @Row^[C];
   If Cell^.Kind = ckEmpty Then Cell^.Kind := ckText;
   If AllSet Then Cell^.Style := Cell^.Style And (Not Mask)
             Else Cell^.Style := Cell^.Style Or Mask;
  End;
 End;
 EndUndoOp('Style');
 WB.Modified := True;
 NeedFullRedraw := True;
End;

Procedure ApplyAlignToSelection(Align: Byte);
Var Sh: PSheet; R, C: Integer; Row: PRow;
Begin
 Sh := ActiveSheet;
 BeginUndoOp;
 For R := Sh^.SelR1 To Sh^.SelR2 Do Begin
  Row := GetRow(Sh, R);
  If Row = Nil Then Continue;
  For C := Sh^.SelC1 To Sh^.SelC2 Do Begin
   RecordCellUndo(WB.Active, R, C);
   If Row^[C].Kind = ckEmpty Then Row^[C].Kind := ckText;
   Row^[C].Align := Align;
  End;
 End;
 EndUndoOp('Alignement');
 WB.Modified := True;
 NeedFullRedraw := True;
End;

Procedure ApplyFormatToSelection(Fmt: Byte);
Var Sh: PSheet; R, C: Integer; Row: PRow;
Begin
 Sh := ActiveSheet;
 BeginUndoOp;
 For R := Sh^.SelR1 To Sh^.SelR2 Do Begin
  Row := GetRow(Sh, R);
  If Row = Nil Then Continue;
  For C := Sh^.SelC1 To Sh^.SelC2 Do Begin
   RecordCellUndo(WB.Active, R, C);
   If Row^[C].Kind = ckEmpty Then Row^[C].Kind := ckText;
   Row^[C].Format := Fmt;
  End;
 End;
 EndUndoOp('Format');
 WB.Modified := True;
 NeedFullRedraw := True;
End;

Procedure ApplyFgToSelection(Col: Byte);
Var Sh: PSheet; R, C: Integer; Row: PRow;
Begin
 Sh := ActiveSheet;
 BeginUndoOp;
 For R := Sh^.SelR1 To Sh^.SelR2 Do Begin
  Row := GetRow(Sh, R);
  If Row = Nil Then Continue;
  For C := Sh^.SelC1 To Sh^.SelC2 Do Begin
   RecordCellUndo(WB.Active, R, C);
   If Row^[C].Kind = ckEmpty Then Row^[C].Kind := ckText;
   Row^[C].Fg := Col;
  End;
 End;
 EndUndoOp('Couleur texte');
 WB.Modified := True;
 NeedFullRedraw := True;
End;

Procedure ApplyBgToSelection(Col: Byte);
Var Sh: PSheet; R, C: Integer; Row: PRow;
Begin
 Sh := ActiveSheet;
 BeginUndoOp;
 For R := Sh^.SelR1 To Sh^.SelR2 Do Begin
  Row := GetRow(Sh, R);
  If Row = Nil Then Continue;
  For C := Sh^.SelC1 To Sh^.SelC2 Do Begin
   RecordCellUndo(WB.Active, R, C);
   If Row^[C].Kind = ckEmpty Then Row^[C].Kind := ckText;
   Row^[C].Bg := Col;
  End;
 End;
 EndUndoOp('Couleur fond');
 WB.Modified := True;
 NeedFullRedraw := True;
End;

Procedure ApplyColWidth(Width: Integer);
Var Sh: PSheet; C: Integer;
Begin
 If Width < 16 Then Width := 16;
 If Width > 250 Then Width := 250;
 Sh := ActiveSheet;
 For C := Sh^.SelC1 To Sh^.SelC2 Do Sh^.ColW[C] := Byte(Width);
 WB.Modified := True;
 NeedFullRedraw := True;
End;

Procedure ApplyRowHeight(Height: Integer);
Var Sh: PSheet; R: Integer;
Begin
 If Height < 10 Then Height := 10;
 If Height > 100 Then Height := 100;
 Sh := ActiveSheet;
 For R := Sh^.SelR1 To Sh^.SelR2 Do Sh^.RowH[R] := Byte(Height);
 WB.Modified := True;
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{               DIALOGUE D'ENTREE (texte simple)                         }
{ ====================================================================== }

Function InputDialog(Const Title, Prompt: String; Var Value: String; MaxLen: Integer): Boolean;
Var X1, Y1, X2, Y2: Integer; K: Char; K2: Char;
    BufPos: Integer; Buf: String;
    EditX, EditY, EditW: Integer;

 Procedure RedrawEdit;
 Var I: Integer; S: String;
 Begin
  HideMouse;
  FillBox(EditX, EditY, EditX + EditW, EditY + 14, CLR_WIN_LIGHT);
  DrawSunkenFrame(EditX - 1, EditY - 1, EditX + EditW + 1, EditY + 15);
  S := Buf;
  If Length(S) * 8 > EditW - 4 Then S := Copy(S, 1, (EditW - 4) Div 8);
  TextAt(EditX + 3, EditY + 3, CLR_TEXT, S);
  { Curseur }
  I := EditX + 3 + (BufPos - 1) * 8;
  If I < EditX + EditW Then Begin
   SetColor(CLR_TEXT);
   Line(I, EditY + 2, I, EditY + 12);
  End;
  ShowMouse;
 End;

Begin
 InputDialog := False;
 X1 := 120; Y1 := 170; X2 := 520; Y2 := 280;
 Buf := Value;
 BufPos := Length(Buf) + 1;
 HideMouse;
 FillBox(X1, Y1, X2, Y2, CLR_WIN_BG);
 DrawRaisedFrame(X1, Y1, X2, Y2);
 OsTitleBar(X1 + 2, Y1 + 2, X2 - 2, Y1 + 18, Title, Y1 + 5);
 TextAt(X1 + 16, Y1 + 36, CLR_TEXT, Prompt);
 EditX := X1 + 16; EditY := Y1 + 56; EditW := X2 - X1 - 32;
 { Boutons }
 FillBox(X1 + 60, Y2 - 28, X1 + 140, Y2 - 8, CLR_WIN_BG);
 DrawRaisedFrame(X1 + 60, Y2 - 28, X1 + 140, Y2 - 8);
 TextAt(X1 + 88, Y2 - 22, CLR_TEXT, 'OK');
 FillBox(X1 + 220, Y2 - 28, X1 + 320, Y2 - 8, CLR_WIN_BG);
 DrawRaisedFrame(X1 + 220, Y2 - 28, X1 + 320, Y2 - 8);
 TextAt(X1 + 246, Y2 - 22, CLR_TEXT, 'Annuler');
 ShowMouse;
 RedrawEdit;
 Repeat
  K := ReadKey;
  If K = #0 Then Begin
   K2 := ReadKey;
   Case K2 Of
    K_LEFT  : If BufPos > 1 Then Dec(BufPos);
    K_RIGHT : If BufPos <= Length(Buf) Then Inc(BufPos);
    K_HOME  : BufPos := 1;
    K_END   : BufPos := Length(Buf) + 1;
    K_DEL   : If BufPos <= Length(Buf) Then Delete(Buf, BufPos, 1);
   End;
   RedrawEdit;
   Continue;
  End;
  Case K Of
   #27 : Begin NeedFullRedraw := True; Exit; End;
   #13 : Begin Value := Buf; InputDialog := True; NeedFullRedraw := True; Exit; End;
   #8  : If BufPos > 1 Then Begin
          Delete(Buf, BufPos - 1, 1);
          Dec(BufPos);
         End;
   Else
    If (K >= ' ') And (Length(Buf) < MaxLen) Then Begin
     Insert(K, Buf, BufPos);
     Inc(BufPos);
    End;
  End;
  RedrawEdit;
 Until False;
End;

Procedure FormatRowDialog;
Var S: String; H: Integer; Sh: PSheet;
Begin
 Sh := ActiveSheet;
 S := IntToStr(Sh^.RowH[Sh^.CurRow]);
 If InputDialog('Hauteur de ligne', 'Hauteur (px, 10-100) :', S, 3) Then Begin
  Val(S, H, H); { utilise H comme code d'erreur ; reaffectera apres }
  Val(S, H, H);
  If H > 0 Then ApplyRowHeight(H);
 End;
End;

Procedure FormatColDialog;
Var S: String; W: Integer; Sh: PSheet; Code: Integer;
Begin
 Sh := ActiveSheet;
 S := IntToStr(Sh^.ColW[Sh^.CurCol]);
 If InputDialog('Largeur de colonne', 'Largeur (px, 16-250) :', S, 3) Then Begin
  Val(S, W, Code);
  If (Code = 0) And (W > 0) Then ApplyColWidth(W);
 End;
End;

Procedure FormatSheetRenameDialog;
Var S: String; Sh: PSheet;
Begin
 Sh := ActiveSheet;
 S := Sh^.Name;
 If InputDialog('Renommer feuille', 'Nom :', S, MAX_TAB_NAME) Then Begin
  If S <> '' Then Begin
   Sh^.Name := Copy(S, 1, MAX_TAB_NAME);
   WB.Modified := True;
   NeedFullRedraw := True;
  End;
 End;
End;

{ ====================================================================== }
{               DIALOGUE FORMAT DE CELLULES                              }
{ ====================================================================== }

Procedure DrawColorSwatches(X, Y: Integer; Cur: Byte);
Var I, Cx, Cy: Integer;
Begin
 For I := 0 To 15 Do Begin
  Cx := X + (I Mod 8) * 18;
  Cy := Y + (I Div 8) * 14;
  FillBox(Cx, Cy, Cx + 14, Cy + 10, I);
  SetColor(CLR_WIN_DARK);
  Rectangle(Cx, Cy, Cx + 14, Cy + 10);
  If I = Cur Then Begin
   SetColor(CLR_ERR);
   Rectangle(Cx - 2, Cy - 2, Cx + 16, Cy + 12);
   Rectangle(Cx - 1, Cy - 1, Cx + 15, Cy + 11);
  End;
 End;
End;

Function ColorSwatchHit(X, Y, MX, MY: Integer): Integer;
Var I, Cx, Cy: Integer;
Begin
 ColorSwatchHit := -1;
 For I := 0 To 15 Do Begin
  Cx := X + (I Mod 8) * 18;
  Cy := Y + (I Div 8) * 14;
  If (MX >= Cx) And (MX <= Cx + 14) And (MY >= Cy) And (MY <= Cy + 10) Then Begin
   ColorSwatchHit := I; Exit;
  End;
 End;
End;

Procedure ApplyStyleSet(StyBits: Byte);
Var Sh: PSheet; R, C: Integer; Row: PRow;
Begin
 Sh := ActiveSheet;
 BeginUndoOp;
 For R := Sh^.SelR1 To Sh^.SelR2 Do Begin
  Row := GetRow(Sh, R);
  If Row = Nil Then Continue;
  For C := Sh^.SelC1 To Sh^.SelC2 Do Begin
   RecordCellUndo(WB.Active, R, C);
   If Row^[C].Kind = ckEmpty Then Row^[C].Kind := ckText;
   Row^[C].Style := StyBits;
  End;
 End;
 EndUndoOp('Style');
 WB.Modified := True;
 NeedFullRedraw := True;
End;

Procedure FormatCellsDialog;
Const FMT_NAMES: Array[0..5] Of String[12] = (
 'General', 'Nombre', 'Pourcent', 'Monetaire', 'Date', 'Texte');
Var X1, Y1, X2, Y2: Integer; K, K2: Char;
    StyBits: Byte; Align, Fmt: Byte; Fg, Bg: Byte;
    Sh: PSheet; Cur: TCell;
    Tx, Ty, I: Integer;
    OkX1, OkY1, OkX2, OkY2: Integer;
    CnX1, CnY1, CnX2, CnY2: Integer;
    StyX, StyY, AlnX, AlnY, FmtX, FmtY: Integer;
    FgX, FgY, BgX, BgY: Integer;
    Hit: Integer;
    Apply: Boolean;
    LastB: LongInt;

 Procedure Redraw;
 Var I, Tx, Ty: Integer;
 Begin
  HideMouse;
  FillBox(X1, Y1, X2, Y2, CLR_WIN_BG);
  DrawRaisedFrame(X1, Y1, X2, Y2);
  OsTitleBar(X1 + 2, Y1 + 2, X2 - 2, Y1 + 18, 'Format de cellules', Y1 + 5);
  { Style }
  TextAt(StyX, StyY - 14, CLR_TEXT, 'Style :');
  For I := 0 To 2 Do Begin
   Tx := StyX + I * 80; Ty := StyY;
   FillBox(Tx, Ty, Tx + 14, Ty + 14, CLR_WIN_LIGHT);
   DrawSunkenFrame(Tx, Ty, Tx + 14, Ty + 14);
   Case I Of
    0: If (StyBits And STY_BOLD) <> 0 Then TextAt(Tx + 4, Ty + 4, CLR_TEXT, 'X');
    1: If (StyBits And STY_ITALIC) <> 0 Then TextAt(Tx + 4, Ty + 4, CLR_TEXT, 'X');
    2: If (StyBits And STY_UNDERLINE) <> 0 Then TextAt(Tx + 4, Ty + 4, CLR_TEXT, 'X');
   End;
   Case I Of
    0: TextAt(Tx + 22, Ty + 4, CLR_TEXT, '&Gras');
    1: TextAt(Tx + 22, Ty + 4, CLR_TEXT, '&Italique');
    2: TextAt(Tx + 22, Ty + 4, CLR_TEXT, '&Souligne');
   End;
  End;
  { Alignement }
  TextAt(AlnX, AlnY - 14, CLR_TEXT, 'Alignement :');
  For I := 0 To 3 Do Begin
   Tx := AlnX + I * 80; Ty := AlnY;
   SetColor(CLR_TEXT);
   Circle(Tx + 6, Ty + 6, 5);
   If Align = I Then Begin
    SetFillStyle(1, CLR_TEXT);
    FillEllipse(Tx + 6, Ty + 6, 2, 2);
   End;
   Case I Of
    0: TextAt(Tx + 18, Ty + 4, CLR_TEXT, '&Defaut');
    1: TextAt(Tx + 18, Ty + 4, CLR_TEXT, 'Ga&uche');
    2: TextAt(Tx + 18, Ty + 4, CLR_TEXT, '&Centre');
    3: TextAt(Tx + 18, Ty + 4, CLR_TEXT, 'D&roite');
   End;
  End;
  { Format }
  TextAt(FmtX, FmtY - 14, CLR_TEXT, 'Format numerique :');
  For I := 0 To 5 Do Begin
   Tx := FmtX + (I Mod 3) * 130; Ty := FmtY + (I Div 3) * 16;
   SetColor(CLR_TEXT);
   Circle(Tx + 6, Ty + 6, 5);
   If Fmt = I Then Begin
    SetFillStyle(1, CLR_TEXT);
    FillEllipse(Tx + 6, Ty + 6, 2, 2);
   End;
   TextAt(Tx + 18, Ty + 4, CLR_TEXT, FMT_NAMES[I]);
  End;
  { Couleurs }
  TextAt(FgX, FgY - 14, CLR_TEXT, 'Couleur texte :');
  DrawColorSwatches(FgX, FgY, Fg);
  TextAt(BgX, BgY - 14, CLR_TEXT, 'Couleur fond :');
  DrawColorSwatches(BgX, BgY, Bg);
  { Boutons }
  FillBox(OkX1, OkY1, OkX2, OkY2, CLR_WIN_BG);
  DrawRaisedFrame(OkX1, OkY1, OkX2, OkY2);
  TextAt(OkX1 + 32, OkY1 + 6, CLR_TEXT, 'OK');
  FillBox(CnX1, CnY1, CnX2, CnY2, CLR_WIN_BG);
  DrawRaisedFrame(CnX1, CnY1, CnX2, CnY2);
  TextAt(CnX1 + 23, CnY1 + 6, CLR_TEXT, 'Annuler');
  ShowMouse;
 End;

Begin
 Sh := ActiveSheet;
 Cur := GetCellRef(Sh, Sh^.CurRow, Sh^.CurCol);
 StyBits := Cur.Style;
 Align := Cur.Align;
 Fmt := Cur.Format;
 Fg := Cur.Fg; Bg := Cur.Bg;
 X1 := 70; Y1 := 80; X2 := 570; Y2 := 410;
 StyX := X1 + 20; StyY := Y1 + 50;
 AlnX := X1 + 20; AlnY := Y1 + 100;
 FmtX := X1 + 20; FmtY := Y1 + 150;
 FgX  := X1 + 20; FgY  := Y1 + 220;
 BgX  := X1 + 260; BgY := Y1 + 220;
 OkX1 := X1 + 100; OkY1 := Y2 - 30; OkX2 := OkX1 + 80; OkY2 := OkY1 + 22;
 CnX1 := X1 + 240; CnY1 := Y2 - 30; CnX2 := CnX1 + 100; CnY2 := CnY1 + 22;
 Apply := False;
 Redraw;
 LastB := 0;
 Repeat
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then Begin K2 := ReadKey;
    { aucune touche speciale particuliere a gerer ici }
   End Else Begin
    Case K Of
     #27 : Break;
     #13 : Begin Apply := True; Break; End;
     'g', 'G' : Begin StyBits := StyBits Xor STY_BOLD; Redraw; End;
     'i', 'I' : Begin StyBits := StyBits Xor STY_ITALIC; Redraw; End;
     's', 'S' : Begin StyBits := StyBits Xor STY_UNDERLINE; Redraw; End;
     'd', 'D' : Begin Align := AL_DEFAULT; Redraw; End;
     'u', 'U' : Begin Align := AL_LEFT; Redraw; End;
     'c', 'C' : Begin Align := AL_CENTER; Redraw; End;
     'r', 'R' : Begin Align := AL_RIGHT; Redraw; End;
    End;
   End;
  End;
  GetMouseState(Mouse.X, Mouse.Y, Mouse.B);
  If ((Mouse.B And 1) <> 0) And ((LastB And 1) = 0) Then Begin
   { Click detection }
   { Style checkboxes }
   For I := 0 To 2 Do Begin
    Tx := StyX + I * 80; Ty := StyY;
    If (Mouse.X >= Tx) And (Mouse.X <= Tx + 70) And
       (Mouse.Y >= Ty) And (Mouse.Y <= Ty + 14) Then Begin
     Case I Of
      0: StyBits := StyBits Xor STY_BOLD;
      1: StyBits := StyBits Xor STY_ITALIC;
      2: StyBits := StyBits Xor STY_UNDERLINE;
     End;
     Redraw;
    End;
   End;
   { Align radios }
   For I := 0 To 3 Do Begin
    Tx := AlnX + I * 80; Ty := AlnY;
    If (Mouse.X >= Tx) And (Mouse.X <= Tx + 70) And
       (Mouse.Y >= Ty) And (Mouse.Y <= Ty + 14) Then Begin
     Align := I; Redraw;
    End;
   End;
   { Format radios }
   For I := 0 To 5 Do Begin
    Tx := FmtX + (I Mod 3) * 130; Ty := FmtY + (I Div 3) * 16;
    If (Mouse.X >= Tx) And (Mouse.X <= Tx + 120) And
       (Mouse.Y >= Ty) And (Mouse.Y <= Ty + 14) Then Begin
     Fmt := I; Redraw;
    End;
   End;
   { Color swatches }
   Hit := ColorSwatchHit(FgX, FgY, Mouse.X, Mouse.Y);
   If Hit >= 0 Then Begin Fg := Hit; Redraw; End;
   Hit := ColorSwatchHit(BgX, BgY, Mouse.X, Mouse.Y);
   If Hit >= 0 Then Begin Bg := Hit; Redraw; End;
   { OK / Annuler }
   If (Mouse.X >= OkX1) And (Mouse.X <= OkX2) And
      (Mouse.Y >= OkY1) And (Mouse.Y <= OkY2) Then Begin
    Apply := True; Break;
   End;
   If (Mouse.X >= CnX1) And (Mouse.X <= CnX2) And
      (Mouse.Y >= CnY1) And (Mouse.Y <= CnY2) Then Break;
  End;
  LastB := Mouse.B;
 Until False;
 NeedFullRedraw := True;
 If Apply Then Begin
  ApplyStyleSet(StyBits);
  ApplyAlignToSelection(Align);
  ApplyFormatToSelection(Fmt);
  ApplyFgToSelection(Fg);
  ApplyBgToSelection(Bg);
  WB.Modified := True;
 End;
End;

Procedure ExecuteMenuItem(M, I: Integer);
Begin
 Case M Of
  1: Case I Of
      1: ActionNew;
      2: ActionOpen;
      4: ActionSave;
      5: ActionSaveAs;
     10: Halt(0);
     End;
  2: Case I Of
      1: DoUndo;
      2: DoRedo;
      4: ActionCut;
      5: ActionCopy;
      6: ActionPaste;
     End;
  4: Case I Of
      5: ActionAddSheet;
      6: ActionInsertChart;
      7: ActionInsertImage;
     End;
  5: Case I Of
      1: FormatCellsDialog;
      2: FormatRowDialog;
      3: FormatColDialog;
      5: FormatSheetRenameDialog;
     End;
  9: Case I Of
      2: ActionAbout;
     End;
 End;
End;

{ ====================================================================== }
{                       BOUCLE DE MENU CLAVIER                           }
{ ====================================================================== }

Procedure ExecuteToolItem(T: Integer);
Begin
 Case T Of
  TI_NEW: ActionNew;
  TI_OPEN: ActionOpen;
  TI_SAVE: ActionSave;
  TI_CUT: ActionCut;
  TI_COPY: ActionCopy;
  TI_PASTE: ActionPaste;
  TI_BOLD: ApplyStyleToggle(STY_BOLD);
  TI_ITAL: ApplyStyleToggle(STY_ITALIC);
  TI_UND: ApplyStyleToggle(STY_UNDERLINE);
  TI_AL_L: ApplyAlignToSelection(AL_LEFT);
  TI_AL_C: ApplyAlignToSelection(AL_CENTER);
  TI_AL_R: ApplyAlignToSelection(AL_RIGHT);
  TI_CHART: ActionInsertChart;
 End;
End;

Procedure RibbonMoveFocus(Direction: Integer);
Var I,N: Integer;
Begin
 N:=RibbonItemCount+TOOL_COUNT;I:=RibbonFocus;
 If (I=0) And (Direction<0) Then I:=N+1;
 Repeat
  Inc(I,Direction);
  If (I<1) Or (I>N) Then Begin RibbonFocus:=0;Exit;End;
  If RibbonEntryEnabled(I) Then Begin RibbonFocus:=I;Exit;End;
 Until False;
End;

Function RibbonHandleKey(K1,K2: Char): Boolean;
Var Direction,Item: Integer;
Begin
 RibbonHandleKey:=False;
 If Not RibbonMode Or Not RibbonKeyboard Then Exit;
 RibbonHandleKey:=True;
 If K1=#0 Then Begin
  Direction:=0;
  Case K2 Of
   K_LEFT: Direction:=-1;
   K_RIGHT: Direction:=1;
   K_DOWN: RibbonMoveFocus(1);
   K_UP: RibbonMoveFocus(-1);
   #15: RibbonMoveFocus(-1); { Maj+Tab }
   K_F10: Begin RibbonKeyboard:=False;RibbonFocus:=0;End;
   Else Begin RibbonHandleKey:=False;Exit;End;
  End;
  If Direction<>0 Then Begin
   If RibbonFocus=0 Then Begin
    Inc(RibbonTab,Direction);
    If RibbonTab<1 Then RibbonTab:=MENU_COUNT;
    If RibbonTab>MENU_COUNT Then RibbonTab:=1;
    RibbonHover:=0;
   End Else RibbonMoveFocus(Direction);
  End;
 End Else Case K1 Of
  #9: RibbonMoveFocus(1);
  #27: Begin
   If RibbonFocus=0 Then RibbonKeyboard:=False Else RibbonFocus:=0;
  End;
  #13,' ': Begin
   If RibbonFocus=0 Then RibbonMoveFocus(1)
   Else Begin
    Item:=RibbonFocus;
    If RibbonEntryEnabled(Item) Then Begin
     RibbonKeyboard:=False;RibbonFocus:=0;
     If Item<=RibbonItemCount Then ExecuteMenuItem(RibbonTab,RibbonMenuItem(Item))
     Else ExecuteToolItem(Item-RibbonItemCount);
    End;
   End;
  End;
  Else Begin RibbonKeyboard:=False;RibbonFocus:=0;RibbonHandleKey:=False;End;
 End;
 NeedFullRedraw:=True;
End;

Function RibbonHandleMouse: Boolean;
Var M,Item: Integer;
Var RibbonHandleMouse_R: Boolean;
Begin
 RibbonHandleMouse_R:=False;
 If Not RibbonMode Or Not LeftPressed Then Begin RibbonHandleMouse := RibbonHandleMouse_R; Exit End;
 RibbonKeyboard:=False;RibbonFocus:=0;
 If (Mouse.Y>=0) And (Mouse.Y<MENUBAR_H) Then Begin
  For M:=1 To MENU_COUNT Do
   If (Mouse.X>=MenuBarItemX(M)-3) And
      (Mouse.X<=MenuBarItemX(M)+MenuLabelWidth(MenuBarLabel(M))+3) Then Begin
    RibbonTab:=M;RibbonHover:=0;Break;
   End;
  RibbonHandleMouse_R:=True;
 End Else If (Mouse.Y>=MENUBAR_H) And (Mouse.Y<ToolbarTop) Then Begin
  Item:=RibbonHitAt(Mouse.X,Mouse.Y);
  If Item>0 Then Begin
   Item:=RibbonMenuItem(Item);
   If MenuCommandEnabled(RibbonTab,Item) Then Begin
    If InputMode Then CommitInput(False);
    ExecuteMenuItem(RibbonTab,Item);
   End;
  End;
  RibbonHandleMouse_R:=True;
 End;
 If RibbonHandleMouse_R Then NeedFullRedraw:=True;
 RibbonHandleMouse := RibbonHandleMouse_R;
End;

Procedure MenuKeyboardLoop;
Var K: Char; Done: Boolean; Item, NewHi, NewMenu, M: Integer;
    InBar: Boolean;
Begin
 If RibbonMode Then Begin
  RibbonTab:=MenuOpen;MenuOpen:=0;RibbonFocus:=0;RibbonHover:=0;
  RibbonKeyboard:=True;NeedFullRedraw:=True;DrawAll;Exit;
 End;
 MenuItemHi := 1;
 NeedFullRedraw := True;
 DrawAll;
 Done := False;
 While Not Done Do Begin
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then Begin
    K := ReadKey;
    Case K Of
     K_LEFT  : Begin
                If MenuOpen > 1 Then Dec(MenuOpen) Else MenuOpen := MENU_COUNT;
                MenuItemHi := 1;
                DrawAll;
               End;
     K_RIGHT : Begin
                If MenuOpen < MENU_COUNT Then Inc(MenuOpen) Else MenuOpen := 1;
                MenuItemHi := 1;
                DrawAll;
               End;
     K_UP    : Begin
                Repeat
                 Dec(MenuItemHi);
                 If MenuItemHi < 1 Then MenuItemHi := MenuItemCount(MenuOpen);
                Until MenuItemLabel(MenuOpen, MenuItemHi) <> '-';
                DrawAll;
               End;
     K_DOWN  : Begin
                Repeat
                 Inc(MenuItemHi);
                 If MenuItemHi > MenuItemCount(MenuOpen) Then MenuItemHi := 1;
                Until MenuItemLabel(MenuOpen, MenuItemHi) <> '-';
                DrawAll;
               End;
    End;
   End Else Begin
    Case K Of
     #27 : Begin MenuOpen := 0; Done := True; End;
     #13 : Begin
            ExecuteMenuItem(MenuOpen, MenuItemHi);
            MenuOpen := 0; Done := True;
           End;
    End;
   End;
  End Else Begin
   UpdateMouse;
   { Survol : barre de menu ? }
   InBar := Mouse.Y < MENUBAR_H;
   If InBar Then Begin
    NewMenu := 0;
    For M := 1 To MENU_COUNT Do
     If (Mouse.X >= MenuBarItemX(M) - 3) And
        (Mouse.X <= MenuBarItemX(M) + MenuLabelWidth(MenuBarLabel(M)) + 3) Then
      Begin NewMenu := M; Break; End;
    If (NewMenu > 0) And (NewMenu <> MenuOpen) Then Begin
     MenuOpen := NewMenu;
     MenuItemHi := 1;
     DrawAll;
    End;
   End Else Begin
    { Survol dans le menu deroulant : maj de l'item courant }
    NewHi := DropDownItemAt(MenuOpen, Mouse.X, Mouse.Y);
    If (NewHi > 0) And (NewHi <> MenuItemHi) Then Begin
     MenuItemHi := NewHi;
     DrawAll;
    End;
   End;
   { Clic gauche }
   If LeftPressed Then Begin
    If InBar Then Begin
     { Cliquer sur la meme barre : fermer ; ailleurs hors barre : ferme }
     MenuOpen := 0; Done := True;
    End Else Begin
     Item := DropDownItemAt(MenuOpen, Mouse.X, Mouse.Y);
     If Item > 0 Then Begin
      ExecuteMenuItem(MenuOpen, Item);
      MenuOpen := 0; Done := True;
     End Else Begin
      { Clic hors menu : fermer }
      MenuOpen := 0; Done := True;
     End;
    End;
   End;
  End;
 End;
 NeedFullRedraw := True;
 DrawAll;
End;

{ ====================================================================== }
{                       GESTION CLAVIER (mode grille)                    }
{ ====================================================================== }

Procedure HandleKey(K1, K2: Char);
Var Sh: PSheet;
Begin
 Sh := ActiveSheet;
 If InputMode Then Begin
  If K1 = #0 Then Begin
   Case K2 Of
    K_LEFT  : If InputBufPos > 1 Then Dec(InputBufPos);
    K_RIGHT : If InputBufPos <= Length(InputBuf) Then Inc(InputBufPos);
    K_HOME  : InputBufPos := 1;
    K_END   : InputBufPos := Length(InputBuf) + 1;
    K_DEL   : If InputBufPos <= Length(InputBuf) Then
              Delete(InputBuf, InputBufPos, 1);
   End;
  End Else Begin
   Case K1 Of
    #27 : CancelInput;
    #13 : CommitInputWithUndo(True);
    #9  : Begin CommitInputWithUndo(False); MoveCursor(0, 1); End;
    #8  : If InputBufPos > 1 Then Begin
           Delete(InputBuf, InputBufPos - 1, 1);
           Dec(InputBufPos);
          End;
    Else
     If (K1 >= ' ') And (Length(InputBuf) < MAX_FORMULA) Then Begin
      Insert(K1, InputBuf, InputBufPos);
      Inc(InputBufPos);
     End;
   End;
  End;
  Exit;
 End;

 { Mode navigation }
 If RibbonHandleKey(K1,K2) Then Exit;
 If K1 = #0 Then Begin
  Case K2 Of
   K_UP        : MoveCursor(-1, 0);
   K_DOWN      : MoveCursor( 1, 0);
   K_LEFT      : MoveCursor( 0,-1);
   K_RIGHT     : MoveCursor( 0, 1);
   K_HOME      : SetCursor(Sh^.CurRow, 0);
   K_END       : SetCursor(Sh^.CurRow, MAX_COLS - 1);
   K_PGUP      : MoveCursor(-12, 0);
   K_PGDN      : MoveCursor( 12, 0);
   K_CTRL_HOME : SetCursor(0, 0);
   K_CTRL_END  : SetCursor(MAX_ROWS - 1, MAX_COLS - 1);
   K_CTRL_LEFT : MoveCursor(0, -12);
   K_CTRL_RIGHT: MoveCursor(0,  12);
   K_CTRL_PGUP : Begin
                  If WB.Active > 1 Then Begin
                   Dec(WB.Active); NeedFullRedraw := True;
                  End;
                 End;
   K_CTRL_PGDN : Begin
                  If WB.Active < WB.Count Then Begin
                   Inc(WB.Active); NeedFullRedraw := True;
                  End;
                 End;
   K_F2        : EditCurrentCell;
   K_F9        : Begin RecalcWorkbook; NeedFullRedraw := True; End;
   K_F8        : Begin
                  ExtendMode := Not ExtendMode;
                  If ExtendMode Then Begin
                   SelAnchorR := Sh^.CurRow; SelAnchorC := Sh^.CurCol;
                  End;
                 End;
   K_DEL       : SelectionClear;
   K_F10       : Begin MenuOpen := 1; MenuKeyboardLoop; End;
   K_ALT_F     : Begin MenuOpen := 1; MenuKeyboardLoop; End;
   K_ALT_E     : Begin MenuOpen := 2; MenuKeyboardLoop; End;
   K_ALT_A     : Begin MenuOpen := 3; MenuKeyboardLoop; End;
   K_ALT_I     : Begin MenuOpen := 4; MenuKeyboardLoop; End;
   K_ALT_O     : Begin MenuOpen := 6; MenuKeyboardLoop; End;
   K_ALT_T     : Begin MenuOpen := 5; MenuKeyboardLoop; End;
   K_ALT_D     : Begin MenuOpen := 7; MenuKeyboardLoop; End;
   K_ALT_W     : Begin MenuOpen := 8; MenuKeyboardLoop; End;
   K_ALT_Q     : Halt(0);
   #107        : Halt(0);   { Alt+F4 }
  End;
 End Else Begin
  Case K1 Of
   #13 : MoveCursor(1, 0);
   #9  : MoveCursor(0, 1);
   #27 : Begin
          ExtendMode := False;
          If Clip.CutMode Then Begin Clip.CutMode := False; End;
         End;
   #3  : ActionCopy;     { Ctrl+C }
   #24 : ActionCut;      { Ctrl+X }
   #22 : ActionPaste;    { Ctrl+V }
   #26 : DoUndo;         { Ctrl+Z }
   #25 : DoRedo;         { Ctrl+Y }
   #15 : ActionOpen;     { Ctrl+O }
   #19 : ActionSave;     { Ctrl+S }
   #14 : ActionNew;      { Ctrl+N }
   #2  : ApplyStyleToggle(STY_BOLD);      { Ctrl+B }
   #21 : ApplyStyleToggle(STY_UNDERLINE); { Ctrl+U }
   #12 : ApplyAlignToSelection(AL_LEFT);   { Ctrl+L }
   #5  : ApplyAlignToSelection(AL_CENTER); { Ctrl+E }
   #18 : ApplyAlignToSelection(AL_RIGHT);  { Ctrl+R }
   Else
    If K1 >= ' ' Then StartInput(K1);
  End;
 End;
End;

{ ====================================================================== }
{                       GESTION SOURIS                                   }
{ ====================================================================== }

{ Petit menu contextuel pour cellule : Couper / Copier / Coller / Effacer
  / Format... / Inserer image... Renvoie 1..6 ou 0 (annuler). }
Function CellContextMenu: Integer;
Var X1, Y1, X2, Y2: Integer; K, K2: Char; Done: Boolean;
Begin
 CellContextMenu := 0;
 X1 := Mouse.X; If X1 + 200 > SCR_W Then X1 := SCR_W - 202;
 Y1 := Mouse.Y; If Y1 + 110 > GRID_BOTTOM Then Y1 := GRID_BOTTOM - 110;
 X2 := X1 + 200; Y2 := Y1 + 108;
 HideMouse;
 FillBox(X1, Y1, X2, Y2, CLR_WIN_BG);
 DrawRaisedFrame(X1, Y1, X2, Y2);
 OsTitleBar(X1 + 2, Y1 + 2, X2 - 2, Y1 + 18, 'Cellule', Y1 + 5);
 TextAt(X1 + 12, Y1 + 24, CLR_TEXT, 'Co&uper');
 TextAt(X1 + 12, Y1 + 38, CLR_TEXT, '&Copier');
 TextAt(X1 + 12, Y1 + 52, CLR_TEXT, 'C&oller');
 TextAt(X1 + 12, Y1 + 66, CLR_TEXT, '&Effacer');
 TextAt(X1 + 12, Y1 + 80, CLR_TEXT, '&Format cellule...');
 TextAt(X1 + 12, Y1 + 94, CLR_TEXT, '&Inserer image...');
 ShowMouse;
 Done := False;
 Repeat
  K := ReadKey;
  If K = #0 Then K2 := ReadKey;
  Case UpCase(K) Of
   'U': Begin CellContextMenu := 1; Done := True; End;
   'C': Begin CellContextMenu := 2; Done := True; End;
   'O': Begin CellContextMenu := 3; Done := True; End;
   'E': Begin CellContextMenu := 4; Done := True; End;
   'F': Begin CellContextMenu := 5; Done := True; End;
   'I': Begin CellContextMenu := 6; Done := True; End;
   #27: Done := True;
  End;
 Until Done;
 NeedFullRedraw := True;
End;

{ Petit menu contextuel pour onglet : Renommer / Inserer / Supprimer.
  Renvoie 1, 2, 3 ou 0 (annuler). }
Function TabContextMenu: Integer;
Var X1, Y1, X2, Y2: Integer; K, K2: Char; Done: Boolean;
Begin
 TabContextMenu := 0;
 X1 := Mouse.X; If X1 + 180 > SCR_W Then X1 := SCR_W - 182;
 Y1 := Mouse.Y - 80; If Y1 < MENUBAR_H Then Y1 := MENUBAR_H;
 X2 := X1 + 180; Y2 := Y1 + 76;
 HideMouse;
 FillBox(X1, Y1, X2, Y2, CLR_WIN_BG);
 DrawRaisedFrame(X1, Y1, X2, Y2);
 OsTitleBar(X1 + 2, Y1 + 2, X2 - 2, Y1 + 18, 'Feuille', Y1 + 5);
 TextAt(X1 + 12, Y1 + 24, CLR_TEXT, '&Renommer');
 TextAt(X1 + 12, Y1 + 38, CLR_TEXT, '&Inserer');
 TextAt(X1 + 12, Y1 + 52, CLR_TEXT, '&Supprimer');
 ShowMouse;
 Done := False;
 Repeat
  K := ReadKey;
  If K = #0 Then K2 := ReadKey;
  Case UpCase(K) Of
   'R': Begin TabContextMenu := 1; Done := True; End;
   'I': Begin TabContextMenu := 2; Done := True; End;
   'S': Begin TabContextMenu := 3; Done := True; End;
   #27: Done := True;
  End;
 Until Done;
 NeedFullRedraw := True;
End;

Procedure HandleMouse;
Var Sh: PSheet; T, R, C, M, Item: Integer;
Begin
 If RibbonMode Then Begin
  T:=RibbonHitAt(Mouse.X,Mouse.Y);
  If T<>RibbonHover Then Begin RibbonHover:=T;NeedFullRedraw:=True;End;
  If RibbonHandleMouse Then Exit;
 End;
 If LeftPressed Then Begin
  { Clic sur barre de menu ? }
  If Mouse.Y < MENUBAR_H Then Begin
   For M := 1 To MENU_COUNT Do Begin
    If (Mouse.X >= MenuBarItemX(M) - 3) And
       (Mouse.X <= MenuBarItemX(M) + MenuLabelWidth(MenuBarLabel(M)) + 3) Then Begin
     MenuOpen := M;
     MenuItemHi := 1;
     MenuKeyboardLoop;
     Exit;
    End;
   End;
   Exit;
  End;
  { Clic sur menu deroulant ouvert ? }
  If MenuOpen > 0 Then Begin
   Item := DropDownItemAt(MenuOpen, Mouse.X, Mouse.Y);
   If Item > 0 Then Begin
    ExecuteMenuItem(MenuOpen, Item);
    MenuOpen := 0;
    NeedFullRedraw := True;
   End Else MenuOpen := 0;
   NeedFullRedraw := True;
   Exit;
  End;
  { Clic sur barre d'outils ? }
  T := ToolHitAt(Mouse.X, Mouse.Y);
  If T > 0 Then Begin
   ExecuteToolItem(T);
   Exit;
  End;
  { Clic sur onglet ? }
  T := TabHitAt(Mouse.X, Mouse.Y);
  If T > 0 Then Begin
   WB.Active := T;
   NeedFullRedraw := True;
   Exit;
  End;
  { Clic sur cellule ? }
  Sh := ActiveSheet;
  R := GridHitRow(Sh, Mouse.Y);
  C := GridHitCol(Sh, Mouse.X);
  If (R >= 0) And (C >= 0) Then Begin
   If InputMode Then CommitInput(False);
   SetCursorEx(R, C, False);
   Dragging := True;
   DragStartR := R; DragStartC := C;
  End;
 End Else If ((Mouse.B And 1) <> 0) And Dragging Then Begin
  { Drag : etendre la selection a la cellule survolee }
  Sh := ActiveSheet;
  R := GridHitRow(Sh, Mouse.Y);
  C := GridHitCol(Sh, Mouse.X);
  If (R >= 0) And (C >= 0) And ((R <> Sh^.CurRow) Or (C <> Sh^.CurCol)) Then Begin
   SetCursorEx(R, C, True);
   NeedFullRedraw := True;
  End;
 End Else If ((Mouse.B And 1) = 0) And Dragging Then Begin
  Dragging := False;
 End;
 { Clic droit sur onglet : menu contextuel feuille }
 If RightPressed Then Begin
  T := TabHitAt(Mouse.X, Mouse.Y);
  If T > 0 Then Begin
   WB.Active := T; NeedFullRedraw := True;
   DrawAll;
   Case TabContextMenu Of
    1: FormatSheetRenameDialog;
    2: ActionAddSheet;
    3: ActionDeleteSheet;
   End;
   NeedFullRedraw := True;
  End Else Begin
   { Clic droit sur cellule : menu contextuel cellule }
   Sh := ActiveSheet;
   R := GridHitRow(Sh, Mouse.Y);
   C := GridHitCol(Sh, Mouse.X);
   If (R >= 0) And (C >= 0) Then Begin
    If InputMode Then CommitInput(False);
    SetCursorEx(R, C, False);
    DrawAll;
    Case CellContextMenu Of
     1: ActionCut;
     2: ActionCopy;
     3: ActionPaste;
     4: SelectionClear;
     5: FormatCellsDialog;
     6: ActionInsertImage;
    End;
    NeedFullRedraw := True;
   End;
  End;
 End;
End;

{ ====================================================================== }
{                       BOUCLE PRINCIPALE                                }
{ ====================================================================== }

{ ====================================================================== }
{  OS/2-0 : barre de menus de PM construite a partir des menus           }
{  d'Excelsior                                                           }
{ ====================================================================== }
{ Menus classiques : les menus deroulants que dessine Excelsior          }
{ (MenuBarLabel, MenuItemLabel) deviennent la barre de menus de PM :      }
{ memes titres et elements, lettres soulignees (& devient ~), raccourcis  }
{ affiches a droite ; les commandes que la version DOS n'a pas            }
{ (MenuCommandEnabled) sont grisees, comme dans le ruban. Une commande de }
{ PM appelle ExecuteMenuItem. Ruban (/RUBANMENU) : les titres de la barre }
{ de menus de PM sont les onglets du ruban.                               }

{ libelle d'Excelsior : texte et raccourci separes par des espaces }
Procedure OsSplitLabel(S : String; Var Txt, Key : String);
Var K : LongInt;
Begin
 K := Pos('  ', S);
 If K = 0 Then Begin Txt := S; Key := ''; Exit; End;
 Txt := Copy(S, 1, K - 1);
 Key := Copy(S, K, 255);
 While (Key <> '') And (Key[1] = ' ') Do Delete(Key, 1, 1);
End;

{ texte d'un menu d'Excelsior -> texte de PM : &x devient ~x }
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

Function OsMenuSignature : LongInt;
Var I, J, K, H : LongInt; S : String;
Begin
 H := 7 + Ord(RibbonMode);
 For I := 1 To MENU_COUNT Do
 Begin
  S := MenuBarLabel(I);
  For K := 1 To Length(S) Do H := (H * 31 + Ord(S[K])) And $7FFFFFF;
  For J := 1 To MenuItemCount(I) Do
  Begin
   S := MenuItemLabel(I, J);
   For K := 1 To Length(S) Do H := (H * 31 + Ord(S[K])) And $7FFFFFF;
  End;
 End;
 OsMenuSignature := H;
End;

Procedure OsSyncMenu;
Var I, J, H0, H1, M, Attr : LongInt; S, Txt, Key : String;
Begin
 If OsFrame = 0 Then Exit;
 If OsMenuSignature = OsMenuSig Then Exit;
 OsMenuSig := OsMenuSignature;
 OsMenuLen := 0;
 H0 := OsMnOpen;
 For I := 1 To MENU_COUNT Do
 Begin
  If RibbonMode Then
   OsMnItem(MIS_TEXT, 0, OS_MENUID + I * 32 + 31, OsMnText(MenuBarLabel(I)))
  Else
  Begin
   OsMnItem(MIS_TEXT Or MIS_SUBMENU, 0, OS_MENUID - 100 - I, OsMnText(MenuBarLabel(I)));
   H1 := OsMnOpen;
   For J := 1 To MenuItemCount(I) Do
   Begin
    S := MenuItemLabel(I, J);
    If S = '-' Then OsMnItem(MIS_SEPARATOR, 0, 0, '')
    Else
    Begin
     OsSplitLabel(S, Txt, Key);
     S := OsMnText(Txt);
     If Key <> '' Then S := S + Chr(9) + Key;
     Attr := 0;
     If Not MenuCommandEnabled(I, J) Then Attr := MIA_DISABLED;
     OsMnItem(MIS_TEXT, Attr, OS_MENUID + I * 32 + J, S);
    End;
   End;
   OsMnClose(H1, MenuItemCount(I));
  End;
 End;
 OsMnClose(H0, MENU_COUNT);
 M := WinCreateMenu(OsFrame, LongInt(@OsMenuT));
 OsDummy := WinSendMsg(OsFrame, $0042, $FFFF, 0);      { WM_UPDATEFRAME : FCF_MENU }
End;

{ a l'ouverture d'un menu : rien a changer (etats fixes) }
Procedure OsMenuInit;
Begin
End;

{ commandes de la barre de menus de PM : depuis la boucle d'Excelsior }
Procedure OsDispatchCommands;
Var Id, I, J : LongInt;
Begin
 While OsCHead <> OsCTail Do
 Begin
  Id := OsCmds[OsCHead];
  OsCHead := (OsCHead + 1) Mod OsCmdMax;
  MenuOpen := 0; MenuItemHi := 0;
  If Id = OS_CMD_QUIT Then
   ExecuteMenuItem(1, 10)
  Else
  Begin
   I := Id Div 32; J := Id Mod 32;
   If (I >= 1) And (I <= MENU_COUNT) Then
   Begin
    If J = 31 Then
    Begin
     { onglet du ruban }
     RibbonTab := I; RibbonKeyboard := True; RibbonFocus := 0; RibbonHover := 0;
    End
    Else If (J >= 1) And (J <= MenuItemCount(I)) Then
     If MenuCommandEnabled(I, J) Then ExecuteMenuItem(I, J);
   End;
  End;
  NeedFullRedraw := True;
 End;
End;

Procedure MainLoop;
Var K1, K2: Char;
Begin
 NeedFullRedraw := True;
 DrawAll;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K1 := ReadKey;
   K2 := #0;
   If K1 = #0 Then Begin K2 := ReadKey; HandleKey(#0, K2); End
              Else HandleKey(K1, #0);
   NeedFullRedraw := True;
  End;
  OsDispatchCommands;
  HandleMouse;
  If NeedFullRedraw Then Begin
   DrawAll;
   NeedFullRedraw := False;
  End
  Else If Not KeyPressed Then Delay(10);   { OS/2-0 : rien a faire }
 Until False;
End;

Function CommandLineHelpRequested: Boolean;
Var I,J: Integer; Arg: String;
Begin
 CommandLineHelpRequested:=False;
 For I:=1 To ParamCount Do Begin
  Arg:=ParamStr(I);For J:=1 To Length(Arg) Do Arg[J]:=UpCase(Arg[J]);
  If (Arg='/?') Or (Arg='-H') Or (Arg='--HELP') Then Begin CommandLineHelpRequested:=True;Exit;End;
 End;
End;

Procedure ShowCommandLineHelp;
Var HelpOutput: Text;
Begin
 { Un flux distinct conserve la sortie console avec les unites Crt. }
 Assign(HelpOutput,'');Rewrite(HelpOutput);
 WriteLn(HelpOutput,'EXCELSIOR - Clone graphique du tableur Excel.');
 WriteLn(HelpOutput);
 WriteLn(HelpOutput,'Utilisation : EXCELSIO [/CLASSICMENU | /RUBANMENU] [classeur] [/?]');
 WriteLn(HelpOutput);
 WriteLn(HelpOutput,'  /CLASSICMENU  Menu classique, style Excel 2003 (par defaut).');
 WriteLn(HelpOutput,'  /RUBANMENU    Onglets et commandes avec icones, style Excel 2007 et suivants.');
 WriteLn(HelpOutput,'  /?           Affiche cette aide et quitte sans ouvrir de fenetre.');
 WriteLn(HelpOutput,'  -h, --help   Affichent egalement cette aide.');
 WriteLn(HelpOutput,'  classeur     Fichier .XLC, .XLS ou .XLSX a ouvrir au demarrage.');
 WriteLn(HelpOutput);
 WriteLn(HelpOutput,'Les parametres sont insensibles a la casse. Le dernier mode specifie est utilise.');
 WriteLn(HelpOutput,'Le classeur peut etre place avant ou apres les options.');
 WriteLn(HelpOutput,'Entourer les chemins contenant des espaces de guillemets.');
 WriteLn(HelpOutput);
 WriteLn(HelpOutput,'Exemples : EXCELSIO /RUBANMENU "C:\Documents\Budget 2026.xlsx"');
 WriteLn(HelpOutput,'           EXCELSIO "Budget.xlc" /CLASSICMENU');
 WriteLn(HelpOutput);
 WriteLn(HelpOutput,'Ruban : souris, F10 ou Alt+lettre, fleches, Tab/Maj+Tab, Entree et Echap.');
 WriteLn(HelpOutput,'Accueil : Alt+E. Les commandes non implementees sont grisees.');
 WriteLn(HelpOutput,'Raccourcis : Ctrl+N Nouveau, Ctrl+O Ouvrir, Ctrl+S Enregistrer, Alt+F4 Quitter.');
 Close(HelpOutput);
End;

Procedure ParseCommandLine;
Var I,J: Integer; Arg,U: String;
Begin
 RibbonMode:=False;RibbonTab:=2;RibbonKeyboard:=False;RibbonFocus:=0;RibbonHover:=0;CmdFN:='';
 For I:=1 To ParamCount Do Begin
  Arg:=ParamStr(I);U:=Arg;For J:=1 To Length(U) Do U[J]:=UpCase(U[J]);
  If U='/CLASSICMENU' Then RibbonMode:=False
  Else If U='/RUBANMENU' Then RibbonMode:=True
  Else Begin
   If CmdFN<>'' Then CmdFN:=CmdFN+' ';
   CmdFN:=CmdFN+Arg;
  End;
 End;
 TOOLBAR_H:=CLASSIC_TOOLBAR_H;If RibbonMode Then TOOLBAR_H:=RIBBON_H;
 GRID_TOP:=MENUBAR_H+TOOLBAR_H+FORMULABAR_H+COLHEADER_H;
End;

BEGIN
 If CommandLineHelpRequested Then Begin ShowCommandLineHelp;Halt(0);End;
 ParseCommandLine;
 InitializeGraphics;
 If MouseDriverFound Then ShowMouse;
 InitWorkbook;
 MenuOpen := 0;
 MenuItemHi := 0;
 InputMode := False;
 InputBuf := '';
 Mouse.X := 0; Mouse.Y := 0; Mouse.B := 0; Mouse.Visible := True;
 LastClickB := 0;
 { Phase 2 : init }
 FillChar(UndoStack, SizeOf(UndoStack), 0);
 FillChar(RedoStack, SizeOf(RedoStack), 0);
 FillChar(Clip, SizeOf(Clip), 0);
 UndoTop := 0;
 RedoTop := 0;
 InUndoOp := False;
 CurUndoHead := Nil;
 ExtendMode := False;
 Dragging := False;
 DragStartR := 0; DragStartC := 0;
 SelAnchorR := 0; SelAnchorC := 0;
 CutMarchingFrame := 0;
 { --- Chargement d'un fichier passe en ligne de commande --- }
 If CmdFN<>'' Then Begin
  { Strip eventuelles guillemets restants. }
  While (Length(CmdFN) > 0) And (CmdFN[1] = '"') Do Delete(CmdFN, 1, 1);
  While (Length(CmdFN) > 0) And (CmdFN[Length(CmdFN)] = '"') Do
   Delete(CmdFN, Length(CmdFN), 1);
  If CmdFN <> '' Then Begin
   { Nom court pour les messages : retire le chemin et limite la longueur. }
   CmdShort := CmdFN;
   While (Pos('\', CmdShort) > 0) Do
    Delete(CmdShort, 1, Pos('\', CmdShort));
   While (Pos('/', CmdShort) > 0) Do
    Delete(CmdShort, 1, Pos('/', CmdShort));
   If Length(CmdShort) > 32 Then CmdShort := Copy(CmdShort, 1, 32);
   { Diagnostic : fichier present ? }
   {$I-} Assign(CmdF, CmdFN); Reset(CmdF, 1); {$I+}
   If IOResult <> 0 Then Begin
    MessageBox('Erreur', 'Fichier introuvable : ' + CmdShort);
   End Else Begin
    Close(CmdF);
    If IsXLSXExt(CmdFN) Then CmdOK := LoadWorkbookXLSX(CmdFN)
    Else If IsXLSExt(CmdFN) Then CmdOK := LoadWorkbookXLS(CmdFN)
                            Else CmdOK := LoadWorkbookXLC(CmdFN);
    If Not CmdOK Then
     MessageBox('Erreur', 'Format invalide (code ' +
                IntToStr(XlsxErr) + ') : ' + CmdShort);
   End;
  End;
 End;
 MainLoop;
 CloseGraph;
END.