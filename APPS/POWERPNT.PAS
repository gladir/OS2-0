{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/office-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Clone de l'application PresentPoint, pour le Presentation
                Manager d'OS/2-0 (dossier Productivite)

  Portage vers OS/2-0 (OS2PC -COS2) de POWERPNT.PAS du depot OFFICE-0 :
  tout l'editeur de presentations est conserve (diapositives, formes,
  texte, images BMP, PCX, PNG, JPEG, themes, masque, transitions,
  animations, diaporama, .PPT et .PPTX, impression). Pour OS/2 : fenetre
  de Presentation Manager, barre de menus d'OS/2 construite a partir des
  dix menus d'origine (repliee sur deux lignes, comme dans PM), dessin
  dans une image en memoire montree par GpiDrawBits (ecran de 640 x 430
  : la diapositive est un peu moins haute), messages, questions, saisies,
  listes et boite de fichiers de PM.
}

Program SR;


Const
 CanvasTop = 16;
 CanvasBot = 429;

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

Procedure InitMenus; Forward;

Procedure InitializeGraphics;
Begin
 InitBmi;
 InitMenus;                    { barre de menus de PM (OpenWindow) }
 OsFrame := 0; OsClient := 0;
 OpenWindow('POWERPNT', 'PresentPoint');
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
{                       CONSTANTES                                       }
{ ====================================================================== }

Const
 SCREEN_W      = 640;
 SCREEN_H      = 430;      { 480 sous DOS : la fenetre de PM tient dans 640 x 480 }
 MENU_H        = 16;
 CLASSIC_TOOL_H = 22;
 STATUS_H      = 16;
 PANEL_W       = 100;    { panneau des miniatures a gauche }
 RULER_H       = 14;

 MAX_SLIDES        = 128;
 MAX_SHAPES        = 96;     { par diapositive }
 MAX_TEXT_LINES    = 16;     { lignes par forme texte }
 MAX_THEMES        = 8;
 MAX_IMAGES        = 16;     { images chargees globalement }
 MAX_IMG_W         = 320;
 MAX_IMG_H         = 240;
 BMP_SIGNATURE     = $4D42;

 SHAPE_NAME_LEN    = 24;
 TXT_LINE_LEN      = 96;
 TITLE_LEN         = 80;
 SLIDE_NAME_LEN    = 32;

 { Types de formes (compatibles AutoShape PowerPoint) }
 SHP_NONE        = 0;
 SHP_TITLE       = 1;     { placeholder de titre }
 SHP_CONTENT     = 2;     { placeholder de contenu / corps }
 SHP_SUBTITLE    = 3;     { sous-titre }
 SHP_TEXT        = 4;     { zone de texte libre }
 SHP_RECT        = 10;
 SHP_ROUNDRECT   = 11;
 SHP_ELLIPSE     = 12;
 SHP_LINE        = 13;
 SHP_ARROW       = 14;
 SHP_TRIANGLE    = 15;
 SHP_DIAMOND     = 16;
 SHP_PENTAGON    = 17;
 SHP_HEXAGON     = 18;
 SHP_STAR        = 19;
 SHP_HEART       = 20;
 SHP_CALLOUT     = 21;
 SHP_PARALLEL    = 22;    { parallelogramme }
 SHP_TRAPEZOID   = 23;
 SHP_CROSS       = 24;
 SHP_IMAGE       = 30;
 SHP_TABLE       = 31;
 SHP_CHART       = 32;

 { Layouts de diapositive }
 LAY_TITLE         = 0;   { titre + sous-titre centres }
 LAY_TITLE_CONTENT = 1;   { titre haut + corps }
 LAY_TWO_CONTENT   = 2;   { titre + 2 colonnes }
 LAY_COMPARISON    = 3;   { titre + 2 colonnes avec en-tetes }
 LAY_TITLE_ONLY    = 4;
 LAY_BLANK         = 5;
 LAY_CONTENT_CAPT  = 6;   { contenu + legende a gauche }
 LAY_SECTION       = 7;   { en-tete de section }

 { Vues actives }
 VIEW_NORMAL    = 0;     { editeur de slide }
 VIEW_OUTLINE   = 1;     { mode plan }
 VIEW_SORTER    = 2;     { trieuse de diapositives }
 VIEW_NOTES     = 3;     { page de commentaires }
 VIEW_SLIDESHOW = 4;     { diaporama plein ecran }

 { Outils de dessin actifs }
 TOOL_SELECT    = 0;
 TOOL_TEXT      = 1;
 TOOL_RECT      = 2;
 TOOL_ELLIPSE   = 3;
 TOOL_LINE      = 4;
 TOOL_ARROW     = 5;
 TOOL_TRIANGLE  = 6;
 TOOL_STAR      = 7;
 TOOL_CALLOUT   = 8;
 TOOL_HAND      = 9;

 { Transitions }
 TRANS_NONE     = 0;
 TRANS_FADE     = 1;
 TRANS_WIPE_L   = 2;
 TRANS_WIPE_R   = 3;
 TRANS_WIPE_U   = 4;
 TRANS_WIPE_D   = 5;
 TRANS_SPLIT    = 6;
 TRANS_CHECKER  = 7;
 TRANS_PUSH     = 8;
 TRANS_BLINDS   = 9;
 TRANS_DISSOLVE = 10;

 { Animations d'entree }
 ANIM_NONE      = 0;
 ANIM_APPEAR    = 1;
 ANIM_FADE      = 2;
 ANIM_SLIDE_L   = 3;
 ANIM_SLIDE_R   = 4;
 ANIM_SLIDE_U   = 5;
 ANIM_SLIDE_D   = 6;
 ANIM_ZOOM      = 7;
 ANIM_SPIN      = 8;

 { Alignement texte }
 ALIGN_LEFT   = 0;
 ALIGN_CENTER = 1;
 ALIGN_RIGHT  = 2;
 ALIGN_JUSTIFY = 3;

 { Couleurs VGA 16 }
 CLR_BLACK     = 0;  CLR_BLUE      = 1;  CLR_GREEN     = 2;  CLR_CYAN      = 3;
 CLR_RED       = 4;  CLR_MAGENTA   = 5;  CLR_BROWN     = 6;  CLR_LGRAY     = 7;
 CLR_DGRAY     = 8;  CLR_LBLUE     = 9;  CLR_LGREEN    = 10; CLR_LCYAN     = 11;
 CLR_LRED      = 12; CLR_LMAGENTA  = 13; CLR_YELLOW    = 14; CLR_WHITE     = 15;

 { Couleurs UI }
 CLR_WIN_BG       = 7;
 CLR_WIN_HI       = 15;
 CLR_WIN_LO       = 8;
 CLR_MENU_BG      = 7;
 CLR_MENU_FG      = 0;
 CLR_MENU_SEL_BG  = 1;
 CLR_MENU_SEL_FG  = 15;
 CLR_DLG_BG       = 7;
 CLR_DLG_TITLE_BG = 4;     { rouge/orange PowerPoint }
 CLR_DLG_TITLE_FG = 15;
 CLR_STATUS_BG    = 7;
 CLR_STATUS_FG    = 0;
 CLR_SLIDE_BG     = 15;    { fond de slide par defaut }
 CLR_SLIDE_BORD   = 8;
 CLR_PANEL_BG     = 8;     { fond panneau miniatures }
 CLR_PANEL_SEL    = 4;
 CLR_WORK_BG      = 8;     { zone de travail derriere la slide }

 { Identifiants d'actions }
 ACT_NONE         = 0;
 ACT_NEW          = 1;
 ACT_OPEN         = 2;
 ACT_SAVE         = 3;
 ACT_SAVEAS       = 4;
 ACT_CLOSE        = 5;
 ACT_PRINT        = 6;
 ACT_QUIT         = 7;
 ACT_UNDO         = 10;
 ACT_REDO         = 11;
 ACT_CUT          = 12;
 ACT_COPY         = 13;
 ACT_PASTE        = 14;
 ACT_DELETE       = 15;
 ACT_FIND         = 16;
 ACT_REPLACE      = 17;
 ACT_SELECTALL    = 18;
 ACT_DUP          = 19;
 ACT_VIEW_NORMAL  = 20;
 ACT_VIEW_OUTLINE = 21;
 ACT_VIEW_SORTER  = 22;
 ACT_VIEW_NOTES   = 23;
 ACT_VIEW_MASTER  = 24;
 ACT_NEW_SLIDE    = 30;
 ACT_DUP_SLIDE    = 31;
 ACT_DEL_SLIDE    = 32;
 ACT_MOVE_UP      = 33;
 ACT_MOVE_DOWN    = 34;
 ACT_LAYOUT       = 35;
 ACT_BACKGROUND   = 36;
 ACT_THEME        = 37;
 ACT_INS_TEXT     = 40;
 ACT_INS_RECT     = 41;
 ACT_INS_ELLIPSE  = 42;
 ACT_INS_LINE     = 43;
 ACT_INS_ARROW    = 44;
 ACT_INS_TRIANGLE = 45;
 ACT_INS_STAR     = 46;
 ACT_INS_CALLOUT  = 47;
 ACT_INS_IMAGE    = 48;
 ACT_INS_TABLE    = 49;
 ACT_INS_CHART    = 50;
 ACT_INS_HEADER   = 51;
 ACT_INS_DATE     = 52;
 ACT_INS_NUMBER   = 53;
 ACT_FONT_BOLD    = 60;
 ACT_FONT_ITAL    = 61;
 ACT_FONT_UND     = 62;
 ACT_ALIGN_LEFT   = 63;
 ACT_ALIGN_CENTER = 64;
 ACT_ALIGN_RIGHT  = 65;
 ACT_BULLET       = 66;
 ACT_NUMBERING    = 67;
 ACT_INDENT_INC   = 68;
 ACT_INDENT_DEC   = 69;
 ACT_FONT_SIZE_UP = 70;
 ACT_FONT_SIZE_DN = 71;
 ACT_COLOR_FILL   = 72;
 ACT_COLOR_LINE   = 73;
 ACT_COLOR_TEXT   = 74;
 ACT_TRANS        = 80;
 ACT_ANIM_ENTRY   = 81;
 ACT_ANIM_EXIT    = 82;
 ACT_TIMING       = 83;
 ACT_SLIDESHOW    = 90;
 ACT_SLIDESHOW_FROM = 91;
 ACT_RUN_FROM_BEG = 92;
 ACT_REHEARSE     = 93;
 ACT_GROUP        = 100;
 ACT_UNGROUP      = 101;
 ACT_BRING_FRONT  = 102;
 ACT_SEND_BACK    = 103;
 ACT_ALIGN_OBJ_L  = 104;
 ACT_ALIGN_OBJ_C  = 105;
 ACT_ALIGN_OBJ_R  = 106;
 ACT_HELP_TOPIC   = 110;
 ACT_HELP_ABOUT   = 111;
 ACT_EXPORT_PPTX  = 115;
 ACT_IMPORT_PPTX  = 116;
 ACT_NEXT_SLIDE   = 120;
 ACT_PREV_SLIDE   = 121;
 ACT_FIRST_SLIDE  = 122;
 ACT_LAST_SLIDE   = 123;
 ACT_ZOOM_IN      = 130;
 ACT_ZOOM_OUT     = 131;
 ACT_ZOOM_FIT     = 132;
 ACT_TOOL_SELECT  = 140;
 ACT_TOOL_TEXT    = 141;
 ACT_TOOL_RECT    = 142;
 ACT_TOOL_ELL     = 143;
 ACT_TOOL_LINE    = 144;
 ACT_TOOL_ARROW   = 145;

 { Icones (vectoriel 18x18) }
 ICO_NEW       = 1;
 ICO_OPEN      = 2;
 ICO_SAVE      = 3;
 ICO_PRINT     = 4;
 ICO_CUT       = 5;
 ICO_COPY      = 6;
 ICO_PASTE     = 7;
 ICO_UNDO      = 8;
 ICO_REDO      = 9;
 ICO_NEWSLIDE  = 10;
 ICO_DELSLIDE  = 11;
 ICO_TEXT      = 12;
 ICO_RECT      = 13;
 ICO_ELLIPSE   = 14;
 ICO_LINE      = 15;
 ICO_ARROW     = 16;
 ICO_TRIANGLE  = 17;
 ICO_STAR      = 18;
 ICO_IMAGE     = 19;
 ICO_TABLE     = 20;
 ICO_BOLD      = 21;
 ICO_ITAL      = 22;
 ICO_UND       = 23;
 ICO_ALIGN_L   = 24;
 ICO_ALIGN_C   = 25;
 ICO_ALIGN_R   = 26;
 ICO_BULLET    = 27;
 ICO_FILL      = 28;
 ICO_PEN       = 29;
 ICO_SLIDESHOW = 30;
 ICO_HELP      = 31;
 ICO_SELECT    = 32;
 ICO_FONT      = 33;
 ICO_TRANS     = 34;
 ICO_ANIM      = 35;

{ ====================================================================== }
{                       TYPES                                            }
{ ====================================================================== }

Type
 TShapeName = String[SHAPE_NAME_LEN];
 TTxtLine   = String[TXT_LINE_LEN];
 TTitleStr  = String[TITLE_LEN];
 TSlideName = String[SLIDE_NAME_LEN];

 PShape = ^TShape;
 TShape = Record
  Name        : TShapeName;
  ShType      : Byte;          { SHP_* }
  X, Y        : Integer;       { coordonnees logiques (slide 1000x750) }
  W, H        : Integer;
  FillColor   : Byte;
  LineColor   : Byte;
  LineWidth   : Byte;
  Filled      : Boolean;
  Rotation    : Integer;       { 0..359, simplifie }
  ZOrder      : Integer;
  Locked      : Boolean;
  Hidden      : Boolean;
  { Texte (utilise pour SHP_TITLE/CONTENT/TEXT/SUBTITLE) }
  TxtCount    : Integer;
  Text        : Array[1..MAX_TEXT_LINES] Of TTxtLine;
  Bullets     : Array[1..MAX_TEXT_LINES] Of Boolean;
  Indent      : Array[1..MAX_TEXT_LINES] Of Byte;
  Bold        : Boolean;
  Italic      : Boolean;
  Underline   : Boolean;
  FontSize    : Byte;          { 8..72 }
  TextColor   : Byte;
  Align       : Byte;
  { Image (index dans Pres.Images) }
  ImageIdx    : Integer;
  { Animations attachees }
  AnimEntry   : Byte;
  AnimExit    : Byte;
  AnimOrder   : Byte;
 End;

 PSlide = ^TSlide;
 TSlide = Record
  Name        : TSlideName;
  Title       : TTitleStr;
  Layout      : Byte;
  Background  : Byte;
  Theme       : Byte;
  Transition  : Byte;
  TransSpeed  : Byte;        { 0=lent 1=moyen 2=rapide }
  Notes       : String;
  Hidden      : Boolean;
  ShCount     : Integer;
  Shapes      : Array[1..MAX_SHAPES] Of PShape;
  Dirty       : Boolean;
 End;

 TTheme = Record
  Name        : String[32];
  BgColor     : Byte;
  TitleColor  : Byte;
  TextColor   : Byte;
  AccentColor : Byte;
  FontSize    : Byte;
 End;

 PImage = ^TImage;
 TImagePixels = Array[0..199999] Of Byte;
 PImagePixels = ^TImagePixels;
 TImage = Record
  Name   : String[40];
  FileName : String[80];
  W, H   : Integer;
  Loaded : Boolean;
  Pixels : PImagePixels;     { palette 0..15 indexee, W*H octets, Nil si vide }
 End;

 TPresentation = Record
  Name        : String[40];
  FileName    : String[80];
  Author      : String[40];
  Company     : String[60];
  Title       : String[80];
  Subject     : String[80];
  Comments    : String[120];
  SldCount    : Integer;
  Slides      : Array[1..MAX_SLIDES] Of PSlide;
  ThemeIdx    : Integer;
  Themes      : Array[1..MAX_THEMES] Of TTheme;
  ThemeCount  : Integer;
  ImgCount    : Integer;
  Images      : Array[1..MAX_IMAGES] Of PImage;
  Dirty       : Boolean;
  { Phase 6 : masque + en-tete/pied de page }
  HeaderText    : String[60];
  FooterText    : String[60];
  DateText      : String[20];
  ShowHeader    : Boolean;
  ShowFooter    : Boolean;
  ShowDate      : Boolean;
  ShowSlideNum  : Boolean;
  MasterBg      : Byte;        { fond par defaut applique aux nouvelles slides }
  MasterTitleC  : Byte;        { couleur titre par defaut }
  MasterTextC   : Byte;        { couleur texte par defaut }
  EditingMaster : Boolean;     { mode masque actif }
 End;

 TMouseState = Record
  X, Y, B : LongInt;
 End;

 TMenuItem = Record
  Caption  : String[32];
  Shortcut : String[12];
  IsSep    : Boolean;
  Action   : Integer;
  Enabled  : Boolean;
 End;

 TMenu = Record
  Caption : String[16];
  X1, X2  : Integer;
  Count   : Integer;
  Items   : Array[1..28] Of TMenuItem;
 End;

 TToolButton = Record
  Icon    : Integer;
  Hint    : String[40];
  Action  : Integer;
  IsSep   : Boolean;
  Enabled : Boolean;
  Toggle  : Boolean;     { bouton bistable (outils de dessin) }
  Down    : Boolean;
  X1,Y1,X2,Y2 : Integer;
 End;

{ ====================================================================== }
{                       VARIABLES GLOBALES                               }
{ ====================================================================== }

Const
 VGA_R : Array[0..15] Of Byte =
  (  0,   0,   0,   0, 168, 168, 168, 168,  84,  84,  84,  84, 252, 252, 252, 252);
 VGA_G : Array[0..15] Of Byte =
  (  0,   0, 168, 168,   0,   0,  84, 168,  84,  84, 252, 252,  84,  84, 252, 252);
 VGA_B : Array[0..15] Of Byte =
  (  0, 168,   0, 168,   0, 168,   0, 168,  84, 252,  84, 252,  84, 252,  84, 252);

Var
 Pres            : TPresentation;
 CurSlide        : Integer;          { 1..SldCount, 0 si vide }
 CurShape        : Integer;          { 0=aucune }
 CurView         : Integer;
 CurTool         : Integer;          { TOOL_* }
 PanelScroll     : Integer;          { defilement panneau miniatures }
 SorterScroll    : Integer;
 SorterSel       : Integer;
 OutlineScroll   : Integer;
 OutlineSel      : Integer;

 { Zone de travail (slide affichee) }
 SlideX1, SlideY1, SlideX2, SlideY2 : Integer;
 SlideScale     : Integer;       { % zoom }

 { Edition }
 EditMode       : Boolean;
 EditBuf        : String;
 EditCaret      : Integer;
 EditLine       : Integer;        { ligne en cours d'edition dans la forme }
 BlinkState     : Boolean;

 { Drag/drop / dessin }
 Dragging       : Boolean;
 DragShapeIdx   : Integer;
 DragStartX     : Integer;
 DragStartY     : Integer;
 DragOrigX      : Integer;
 DragOrigY      : Integer;
 DrawingNew     : Boolean;
 DrawStartX     : Integer;
 DrawStartY     : Integer;
 DrawCurX       : Integer;
 DrawCurY       : Integer;
 { Phase 2 - manipulation interactive }
 DragMode       : Byte;          { 0=none 1=move 2=resize 3=newshape 4=marquee }
 DragHandle     : Byte;          { 1..8 (NW,N,NE,E,SE,S,SW,W) }
 DragShapeKind  : Byte;          { SHP_* a creer en mode 3 }
 DragOrigW      : Integer;
 DragOrigH      : Integer;
 RubberValid    : Boolean;
 RubberX1, RubberY1, RubberX2, RubberY2: Integer;
 LastMouseX     : Integer;
 LastMouseY     : Integer;

 { Mouse }
 Mouse          : TMouseState;
 LastClickB     : LongInt;
 LastClickX     : LongInt;
 LastClickY     : LongInt;
 LastClickTime  : LongInt;
 DoubleClicked  : Boolean;

 { Menus }
 Menus          : Array[1..16] Of TMenu;
 MenuCount      : Integer;
 MenuOpen       : Integer;       { 0 = aucun }
 MenuHover      : Integer;
 MenuItemHover  : Integer;
 MenuY1, MenuY2 : Integer;
 MenuKbdActive  : Boolean;       { selection clavier active : ignore souris stationnaire }
 MenuKbdMx      : Integer;
 MenuKbdMy      : Integer;

 { Toolbar }
 Tools          : Array[1..40] Of TToolButton;
 RibbonMode,RibbonKeyboard: Boolean;
 RibbonTab,RibbonFocus,RibbonHover,RibbonInk: Integer;
 TOOL_H: Integer;
 CommandLineFile: String;
 ToolCount      : Integer;
 ToolHover      : Integer;
 ToolY1, ToolY2 : Integer;

 { Etat global }
 TickCount      : LongInt;
 PaintReady,PaintLocked,NeedChromeRedraw: Boolean;
 TextCaretKnown,TextCaretDrawn: Boolean;
 TextCaretX,TextCaretY,TextCaretHeight: Integer;
 NeedFullRedraw : Boolean;
 NeedSlideRedraw: Boolean;
 NeedPanelRedraw: Boolean;
 NeedStatRedraw : Boolean;
 Quitting       : Boolean;
 StatusMsg      : String;

{ ====================================================================== }
{                       UTILITAIRES STRING                               }
{ ====================================================================== }

Function IntToStr(N: LongInt): String;
Var S: String;
Begin
 Str(N, S); IntToStr := S;
End;

Function StrToIntDef(Const S: String; Def: LongInt): LongInt;
Var V: LongInt; Code: Integer;
Begin
 Val(S, V, Code);
 If Code = 0 Then StrToIntDef := V Else StrToIntDef := Def;
End;

Function UpperStr(Const S: String): String;
Var I: Integer; R: String;
Begin
 R := S;
 For I := 1 To Length(R) Do R[I] := UpCase(R[I]);
 UpperStr := R;
End;

Function TrimStr(Const S: String): String;
Var A, B: Integer;
Begin
 A := 1; B := Length(S);
 While (A <= B) And (S[A] <= ' ') Do Inc(A);
 While (B >= A) And (S[B] <= ' ') Do Dec(B);
 TrimStr := Copy(S, A, B - A + 1);
End;

Function MinI(A, B: LongInt): LongInt;
Begin If A < B Then MinI := A Else MinI := B; End;

Function MaxI(A, B: LongInt): LongInt;
Begin If A > B Then MaxI := A Else MaxI := B; End;

Function LayoutName(L: Byte): String;
Begin
 Case L Of
  LAY_TITLE         : LayoutName := 'Diapositive de titre';
  LAY_TITLE_CONTENT : LayoutName := 'Titre et contenu';
  LAY_TWO_CONTENT   : LayoutName := 'Deux contenus';
  LAY_COMPARISON    : LayoutName := 'Comparaison';
  LAY_TITLE_ONLY    : LayoutName := 'Titre seul';
  LAY_BLANK         : LayoutName := 'Vide';
  LAY_CONTENT_CAPT  : LayoutName := 'Contenu avec legende';
  LAY_SECTION       : LayoutName := 'En-tete de section';
 Else LayoutName := 'Personnalise';
 End;
End;

Function TransName(T: Byte): String;
Begin
 Case T Of
  TRANS_NONE     : TransName := 'Aucune';
  TRANS_FADE     : TransName := 'Fondu';
  TRANS_WIPE_L   : TransName := 'Balayage gauche';
  TRANS_WIPE_R   : TransName := 'Balayage droite';
  TRANS_WIPE_U   : TransName := 'Balayage haut';
  TRANS_WIPE_D   : TransName := 'Balayage bas';
  TRANS_SPLIT    : TransName := 'Decoupage';
  TRANS_CHECKER  : TransName := 'Damier';
  TRANS_PUSH     : TransName := 'Pousser';
  TRANS_BLINDS   : TransName := 'Stores';
  TRANS_DISSOLVE : TransName := 'Dissolution';
 Else TransName := '?';
 End;
End;

Function ShapeKindName(T: Byte): String;
Begin
 Case T Of
  SHP_TITLE     : ShapeKindName := 'Titre';
  SHP_CONTENT   : ShapeKindName := 'Contenu';
  SHP_SUBTITLE  : ShapeKindName := 'Sous-titre';
  SHP_TEXT      : ShapeKindName := 'Texte';
  SHP_RECT      : ShapeKindName := 'Rectangle';
  SHP_ROUNDRECT : ShapeKindName := 'Rectangle arrondi';
  SHP_ELLIPSE   : ShapeKindName := 'Ellipse';
  SHP_LINE      : ShapeKindName := 'Ligne';
  SHP_ARROW     : ShapeKindName := 'Fleche';
  SHP_TRIANGLE  : ShapeKindName := 'Triangle';
  SHP_DIAMOND   : ShapeKindName := 'Losange';
  SHP_PENTAGON  : ShapeKindName := 'Pentagone';
  SHP_HEXAGON   : ShapeKindName := 'Hexagone';
  SHP_STAR      : ShapeKindName := 'Etoile';
  SHP_HEART     : ShapeKindName := 'Coeur';
  SHP_CALLOUT   : ShapeKindName := 'Bulle';
  SHP_PARALLEL  : ShapeKindName := 'Parallelogramme';
  SHP_TRAPEZOID : ShapeKindName := 'Trapeze';
  SHP_CROSS     : ShapeKindName := 'Croix';
  SHP_IMAGE     : ShapeKindName := 'Image';
  SHP_TABLE     : ShapeKindName := 'Tableau';
  SHP_CHART     : ShapeKindName := 'Graphique';
 Else ShapeKindName := 'Forme';
 End;
End;

{ ====================================================================== }
{                       PRIMITIVES SOURIS                                }
{ ====================================================================== }

{ pointeur de la souris de PM }
Procedure AppShowMouse;
Begin
End;
Procedure AppHideMouse;
Begin
End;

Procedure UpdateMouse;
Var Dt: LongInt;
Begin
 LastClickB := Mouse.B;
 GetMouseState(Mouse.X, Mouse.Y, Mouse.B);
 DoubleClicked := False;
 If ((Mouse.B And 1) <> 0) And ((LastClickB And 1) = 0) Then Begin
  Dt := TickCount - LastClickTime;
  If (Dt > 0) And (Dt < 8) And (Abs(Mouse.X - LastClickX) < 4)
     And (Abs(Mouse.Y - LastClickY) < 4) Then DoubleClicked := True;
  LastClickTime := TickCount;
  LastClickX    := Mouse.X;
  LastClickY    := Mouse.Y;
 End;
End;

Function LeftPressed: Boolean;
Begin LeftPressed := ((Mouse.B And 1) <> 0) And ((LastClickB And 1) = 0); End;

Function LeftDown: Boolean;
Begin LeftDown := (Mouse.B And 1) <> 0; End;

Function LeftReleased: Boolean;
Begin LeftReleased := ((Mouse.B And 1) = 0) And ((LastClickB And 1) <> 0); End;

Function RightPressed: Boolean;
Begin RightPressed := ((Mouse.B And 2) <> 0) And ((LastClickB And 2) = 0); End;

Function InRect(X, Y, X1, Y1, X2, Y2: LongInt): Boolean;
Begin
 InRect := (X >= X1) And (X <= X2) And (Y >= Y1) And (Y <= Y2);
End;

{ ====================================================================== }
{                       PRIMITIVES DE DESSIN                             }
{ ====================================================================== }

Procedure FillBox(X1, Y1, X2, Y2, Col: Integer);
Begin
 SetFillStyle(1, Col);
 Bar(X1, Y1, X2, Y2);
End;

Procedure HLine(X1, X2, Y, Col: Integer);
Begin
 SetColor(Col); Line(X1, Y, X2, Y);
End;

Procedure VLine(X, Y1, Y2, Col: Integer);
Begin
 SetColor(Col); Line(X, Y1, X, Y2);
End;

Procedure DrawRaised(X1, Y1, X2, Y2, Bg, Hi, Lo: Integer);
Begin
 FillBox(X1, Y1, X2, Y2, Bg);
 HLine(X1, X2, Y1, Hi);
 VLine(X1, Y1, Y2, Hi);
 HLine(X1, X2, Y2, Lo);
 VLine(X2, Y1, Y2, Lo);
End;

Procedure DrawSunken(X1, Y1, X2, Y2, Bg, Hi, Lo: Integer);
Begin
 FillBox(X1, Y1, X2, Y2, Bg);
 HLine(X1, X2, Y1, Lo);
 VLine(X1, Y1, Y2, Lo);
 HLine(X1, X2, Y2, Hi);
 VLine(X2, Y1, Y2, Hi);
End;

Procedure DropShadow(X1, Y1, X2, Y2: Integer);
Begin
 FillBox(X1 + 4, Y2 + 1, X2 + 4, Y2 + 3, CLR_BLACK);
 FillBox(X2 + 1, Y1 + 4, X2 + 3, Y2 + 3, CLR_BLACK);
End;

Procedure DrawCheckBox(X, Y: Integer; Checked: Boolean);
Begin
 DrawSunken(X, Y, X + 11, Y + 11, CLR_WHITE, CLR_WIN_HI, CLR_WIN_LO);
 If Checked Then Begin
  SetColor(CLR_BLACK);
  Line(X + 2, Y + 5, X + 4, Y + 8);
  Line(X + 3, Y + 5, X + 5, Y + 8);
  Line(X + 4, Y + 8, X + 9, Y + 2);
  Line(X + 5, Y + 8, X + 9, Y + 3);
 End;
End;

{ ====================================================================== }
{                       PRIMITIVES DIALOGUES                             }
{ ====================================================================== }

Procedure DlgFrame(X1, Y1, X2, Y2: Integer; Const Title: String);
Begin
 AppHideMouse;
 DropShadow(X1, Y1, X2, Y2);
 DrawRaised(X1, Y1, X2, Y2, CLR_DLG_BG, CLR_WIN_HI, CLR_WIN_LO);
 FillBox(X1 + 2, Y1 + 2, X2 - 2, Y1 + 15, CLR_DLG_TITLE_BG);
 SetColor(CLR_DLG_TITLE_FG);
 OutTextXY(X1 + 6, Y1 + 4, Title);
 DrawRaised(X2 - 16, Y1 + 3, X2 - 4, Y1 + 13, CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO);
 SetColor(CLR_BLACK);
 Line(X2 - 13, Y1 + 6, X2 - 7, Y1 + 10);
 Line(X2 - 13, Y1 + 10, X2 - 7, Y1 + 6);
 AppShowMouse;
End;

Procedure DlgBtn(X1, Y1, X2, Y2: Integer; Const Caption: String;
                 Pressed, Focused: Boolean);
Var Tw: Integer;
Begin
 If Pressed Then
  DrawSunken(X1, Y1, X2, Y2, CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO)
 Else
  DrawRaised(X1, Y1, X2, Y2, CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO);
 If Focused Then Begin
  SetColor(CLR_BLACK);
  Rectangle(X1 + 3, Y1 + 3, X2 - 3, Y2 - 3);
 End;
 SetColor(CLR_BLACK);
 Tw := TextWidth(Caption);
 OutTextXY(X1 + ((X2 - X1) - Tw) Div 2 + Ord(Pressed),
           Y1 + ((Y2 - Y1) - 8) Div 2 + Ord(Pressed), Caption);
End;

Procedure DlgEdit(X1, Y1, X2, Y2: Integer; Const Text: String;
                  Focused: Boolean; Caret: Integer);
Var S: String; Cx: Integer;
Begin
 FillBox(X1, Y1, X2, Y2, CLR_WHITE);
 SetColor(CLR_WIN_LO); Rectangle(X1, Y1, X2, Y2);
 S := Text;
 While (Length(S) > 0) And (TextWidth(S) > X2 - X1 - 6) Do
  S := Copy(S, 2, Length(S) - 1);
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 4, Y1 + ((Y2 - Y1) - 8) Div 2, S);
 If Focused And BlinkState Then Begin
  If Caret > Length(S) Then Caret := Length(S);
  Cx := X1 + 4 + TextWidth(Copy(S, 1, Caret));
  Line(Cx, Y1 + 3, Cx, Y2 - 3);
 End;
End;

Procedure DlgLabel(X, Y: Integer; Const S: String);
Begin SetColor(CLR_BLACK); OutTextXY(X, Y, S); End;

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


Procedure MessageBox(Const Title, Msg: String);
Begin
 Dummy := PmBox(Title, Msg, MB_OK Or MB_INFORMATION);
 NeedFullRedraw := True;
End;

Function ConfirmYesNo(Const Title, Msg: String): Boolean;
Begin
 ConfirmYesNo := PmBox(Title, Msg, MB_YESNO Or MB_ICONQUESTION) = MBID_YES;
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{                       MENUS                                            }
{ ====================================================================== }

Procedure AddMenu(Const Caption: String);
Begin
 If MenuCount >= 16 Then Exit;
 Inc(MenuCount);
 Menus[MenuCount].Caption := Caption;
 Menus[MenuCount].Count   := 0;
End;

Procedure AddMenuItem(M: Integer; Const Caption, Shortcut: String;
                      IsSep: Boolean; Action: Integer);
Var C: Integer;
Begin
 If (M < 1) Or (M > MenuCount) Then Exit;
 If Menus[M].Count >= 28 Then Exit;
 Inc(Menus[M].Count);
 C := Menus[M].Count;
 Menus[M].Items[C].Caption  := Caption;
 Menus[M].Items[C].Shortcut := Shortcut;
 Menus[M].Items[C].IsSep    := IsSep;
 Menus[M].Items[C].Action   := Action;
 Menus[M].Items[C].Enabled  := True;
End;

Function RibbonCanonicalAction(A: Integer): Integer;
Begin
 RibbonCanonicalAction:=A;
 Case A Of
  ACT_TOOL_TEXT: RibbonCanonicalAction:=ACT_INS_TEXT;
  ACT_TOOL_RECT: RibbonCanonicalAction:=ACT_INS_RECT;
  ACT_TOOL_ELL: RibbonCanonicalAction:=ACT_INS_ELLIPSE;
  ACT_TOOL_LINE: RibbonCanonicalAction:=ACT_INS_LINE;
  ACT_TOOL_ARROW: RibbonCanonicalAction:=ACT_INS_ARROW;
 End;
End;

Procedure InitMenus;
Var I, X: Integer;
Begin
 MenuCount := 0;
 AddMenu(' Fichier ');
 AddMenu(' Edition ');
 AddMenu(' Affichage ');
 AddMenu(' Insertion ');
 AddMenu(' Conception ');
 AddMenu(' Transitions ');
 AddMenu(' Animations ');
 AddMenu(' Diaporama ');
 AddMenu(' Revision ');
 AddMenu(' Aide ');

 AddMenuItem(1, 'Nouveau',                   'Ctrl+N',    False, ACT_NEW);
 AddMenuItem(1, 'Ouvrir...',                 'Ctrl+O',    False, ACT_OPEN);
 AddMenuItem(1, 'Fermer',                    'Ctrl+F4',   False, ACT_CLOSE);
 AddMenuItem(1, '',                          '',          True,  0);
 AddMenuItem(1, 'Enregistrer',               'Ctrl+S',    False, ACT_SAVE);
 AddMenuItem(1, 'Enregistrer sous...',       'F12',       False, ACT_SAVEAS);
 AddMenuItem(1, '',                          '',          True,  0);
 AddMenuItem(1, 'Imprimer...',               'Ctrl+P',    False, ACT_PRINT);
 AddMenuItem(1, '',                          '',          True,  0);
 AddMenuItem(1, 'Quitter',                   'Alt+F4',    False, ACT_QUIT);

 AddMenuItem(2, 'Annuler',                   'Ctrl+Z',    False, ACT_UNDO);
 AddMenuItem(2, 'Retablir',                  'Ctrl+Y',    False, ACT_REDO);
 AddMenuItem(2, '',                          '',          True,  0);
 AddMenuItem(2, 'Couper',                    'Ctrl+X',    False, ACT_CUT);
 AddMenuItem(2, 'Copier',                    'Ctrl+C',    False, ACT_COPY);
 AddMenuItem(2, 'Coller',                    'Ctrl+V',    False, ACT_PASTE);
 AddMenuItem(2, 'Dupliquer',                 'Ctrl+D',    False, ACT_DUP);
 AddMenuItem(2, 'Supprimer',                 'Suppr',     False, ACT_DELETE);
 AddMenuItem(2, '',                          '',          True,  0);
 AddMenuItem(2, 'Rechercher...',             'Ctrl+F',    False, ACT_FIND);
 AddMenuItem(2, 'Remplacer...',              'Ctrl+H',    False, ACT_REPLACE);
 AddMenuItem(2, 'Selectionner tout',         'Ctrl+A',    False, ACT_SELECTALL);

 AddMenuItem(3, 'Normal',                    '',          False, ACT_VIEW_NORMAL);
 AddMenuItem(3, 'Plan',                      '',          False, ACT_VIEW_OUTLINE);
 AddMenuItem(3, 'Trieuse de diapositives',   '',          False, ACT_VIEW_SORTER);
 AddMenuItem(3, 'Page de commentaires',      '',          False, ACT_VIEW_NOTES);
 AddMenuItem(3, '',                          '',          True,  0);
 AddMenuItem(3, 'Masque des diapositives',   '',          False, ACT_VIEW_MASTER);
 AddMenuItem(3, '',                          '',          True,  0);
 AddMenuItem(3, 'Zoom +',                    'Ctrl++',    False, ACT_ZOOM_IN);
 AddMenuItem(3, 'Zoom -',                    'Ctrl+-',    False, ACT_ZOOM_OUT);
 AddMenuItem(3, 'Ajuster a la fenetre',      '',          False, ACT_ZOOM_FIT);

 AddMenuItem(4, 'Nouvelle diapositive',      'Ctrl+M',    False, ACT_NEW_SLIDE);
 AddMenuItem(4, 'Dupliquer la diapositive',  '',          False, ACT_DUP_SLIDE);
 AddMenuItem(4, '',                          '',          True,  0);
 AddMenuItem(4, 'Zone de texte',             '',          False, ACT_INS_TEXT);
 AddMenuItem(4, 'Image...',                  '',          False, ACT_INS_IMAGE);
 AddMenuItem(4, 'Tableau...',                '',          False, ACT_INS_TABLE);
 AddMenuItem(4, 'Graphique...',              '',          False, ACT_INS_CHART);
 AddMenuItem(4, '',                          '',          True,  0);
 AddMenuItem(4, 'Forme - Rectangle',         '',          False, ACT_INS_RECT);
 AddMenuItem(4, 'Forme - Ellipse',           '',          False, ACT_INS_ELLIPSE);
 AddMenuItem(4, 'Forme - Triangle',          '',          False, ACT_INS_TRIANGLE);
 AddMenuItem(4, 'Forme - Etoile',            '',          False, ACT_INS_STAR);
 AddMenuItem(4, 'Forme - Bulle',             '',          False, ACT_INS_CALLOUT);
 AddMenuItem(4, 'Ligne',                     '',          False, ACT_INS_LINE);
 AddMenuItem(4, 'Fleche',                    '',          False, ACT_INS_ARROW);
 AddMenuItem(4, '',                          '',          True,  0);
 AddMenuItem(4, 'En-tete et pied',           '',          False, ACT_INS_HEADER);
 AddMenuItem(4, 'Date et heure',             '',          False, ACT_INS_DATE);
 AddMenuItem(4, 'Numero de diapositive',     '',          False, ACT_INS_NUMBER);

 AddMenuItem(5, 'Mise en page de slide...',  '',          False, ACT_LAYOUT);
 AddMenuItem(5, 'Theme...',                  '',          False, ACT_THEME);
 AddMenuItem(5, 'Arriere-plan...',           '',          False, ACT_BACKGROUND);
 AddMenuItem(5, '',                          '',          True,  0);
 AddMenuItem(5, 'Couleur de remplissage',    '',          False, ACT_COLOR_FILL);
 AddMenuItem(5, 'Couleur de contour',        '',          False, ACT_COLOR_LINE);
 AddMenuItem(5, 'Couleur du texte',          '',          False, ACT_COLOR_TEXT);

 AddMenuItem(6, 'Aucune',                    '',          False, ACT_TRANS);
 AddMenuItem(6, 'Fondu',                     '',          False, ACT_TRANS);
 AddMenuItem(6, 'Balayage',                  '',          False, ACT_TRANS);
 AddMenuItem(6, 'Decoupage',                 '',          False, ACT_TRANS);
 AddMenuItem(6, 'Pousser',                   '',          False, ACT_TRANS);
 AddMenuItem(6, 'Damier',                    '',          False, ACT_TRANS);
 AddMenuItem(6, 'Dissolution',               '',          False, ACT_TRANS);
 AddMenuItem(6, '',                          '',          True,  0);
 AddMenuItem(6, 'Minutage...',               '',          False, ACT_TIMING);

 AddMenuItem(7, 'Animation d''entree...',    '',          False, ACT_ANIM_ENTRY);
 AddMenuItem(7, 'Animation de sortie...',    '',          False, ACT_ANIM_EXIT);
 AddMenuItem(7, '',                          '',          True,  0);
 AddMenuItem(7, 'Volet d''animation',        '',          False, 0);

 AddMenuItem(8, 'Demarrer le diaporama',     'F5',        False, ACT_SLIDESHOW);
 AddMenuItem(8, 'A partir de cette slide',   'Maj+F5',    False, ACT_SLIDESHOW_FROM);
 AddMenuItem(8, 'Verifier le minutage',      '',          False, ACT_REHEARSE);
 AddMenuItem(8, '',                          '',          True,  0);
 AddMenuItem(8, 'Configurer le diaporama',   '',          False, 0);

 AddMenuItem(9, 'Orthographe...',            'F7',        False, 0);
 AddMenuItem(9, 'Recherche...',              '',          False, 0);
 AddMenuItem(9, 'Commentaires...',           '',          False, 0);

 AddMenuItem(10,'Rubriques d''aide',         'F1',        False, ACT_HELP_TOPIC);
 AddMenuItem(10,'',                          '',          True,  0);
 AddMenuItem(10,'A propos de PresentPoint...',   '',          False, ACT_HELP_ABOUT);

 If RibbonMode Then Begin
  Menus[1].Caption:='Fichier';Menus[2].Caption:='Accueil';Menus[3].Caption:='Affich.';
  Menus[4].Caption:='Inserer';Menus[5].Caption:='Creer';Menus[6].Caption:='Transit.';
  Menus[7].Caption:='Animat.';Menus[8].Caption:='Diapo';Menus[9].Caption:='Revis.';
  Menus[10].Caption:='Aide';
  AddMenuItem(2,'Selectionner','',False,ACT_TOOL_SELECT);
  AddMenuItem(2,'Gras','Ctrl+B',False,ACT_FONT_BOLD);
  AddMenuItem(2,'Italique','Ctrl+I',False,ACT_FONT_ITAL);
  AddMenuItem(2,'Souligne','Ctrl+U',False,ACT_FONT_UND);
  AddMenuItem(2,'Gauche','Ctrl+L',False,ACT_ALIGN_LEFT);
  AddMenuItem(2,'Centrer','Ctrl+E',False,ACT_ALIGN_CENTER);
  AddMenuItem(2,'Droite','Ctrl+R',False,ACT_ALIGN_RIGHT);
  AddMenuItem(2,'Puces','',False,ACT_BULLET);
  AddMenuItem(2,'Supprimer la diapositive','',False,ACT_DEL_SLIDE);
 End;
 X := 4;
 For I := 1 To MenuCount Do Begin
  Menus[I].X1 := X;
  Menus[I].X2 := X + TextWidth(Menus[I].Caption) + 6;
  X := Menus[I].X2 + 2;
 End;
 MenuY1 := 0;
 MenuY2 := MENU_H - 1;
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
 For M:=1 To MenuCount Do Begin
  S:=Menus[M].Caption;
  While (S<>'') And (S[1]=' ') Do Delete(S,1,1);
  While (S<>'') And (S[Length(S)]=' ') Do Delete(S,Length(S),1);
  Lb:='';Mn:=False;
  For K:=1 To Length(S) Do Begin
   If (Not Mn) And (UpCase(S[K])>='A') And (UpCase(S[K])<='Z') And
      (Pos(UpCase(S[K]),MnemoKeys)=0) Then Begin
    Lb:=Lb+'~';MnemoKeys:=MnemoKeys+UpCase(S[K]);Mn:=True;
   End;
   Lb:=Lb+S[K];
  End;
  MnItem(MIS_TEXT Or MIS_SUBMENU,0,900+M,Lb);
  H1:=MnOpen;
  For I:=1 To Menus[M].Count Do
   If Menus[M].Items[I].IsSep Then MnItem(MIS_SEPARATOR,0,100+32*M+I,'')
   Else Begin
    S:=Menus[M].Items[I].Caption;
    If Menus[M].Items[I].Shortcut<>'' Then S:=S+#9+Menus[M].Items[I].Shortcut;
    MnItem(MIS_TEXT,0,100+32*M+I,S);
   End;
  MnClose(H1,Menus[M].Count);
 End;
 MnClose(H0,MenuCount);
 OsMenu:=WinCreateMenu(OsFrame,LongInt(@MenuT));
End;

{ ouverture d'un menu : choix grises de la version DOS }
Procedure MenuInit(M: LongInt);
Var I: Integer;
Begin
 M:=M-900;
 If (M<1) Or (M>MenuCount) Then Exit;
 For I:=1 To Menus[M].Count Do
  If Not Menus[M].Items[I].IsSep Then
   MnAttr(100+32*M+I,MIA_DISABLED,Not Menus[M].Items[I].Enabled);
End;

Procedure DrawMenuBar;
Var I, Bg, Fg: Integer;
Begin
 AppHideMouse;
 FillBox(0, MenuY1, SCREEN_W - 1, MenuY2, CLR_MENU_BG);
 HLine(0, SCREEN_W - 1, MenuY2, CLR_WIN_LO);
 For I := 1 To MenuCount Do Begin
  If (I = MenuOpen) Or (RibbonMode And (I=RibbonTab)) Or
     ((I = MenuHover) And (MenuOpen = 0)) Then Begin
   Bg := CLR_MENU_SEL_BG; Fg := CLR_MENU_SEL_FG;
   FillBox(Menus[I].X1, MenuY1 + 1, Menus[I].X2, MenuY2 - 1, Bg);
  End
  Else Begin Bg := CLR_MENU_BG; Fg := CLR_MENU_FG; End;
  SetColor(Fg);
  OutTextXY(Menus[I].X1 + 4, MenuY1 + 4, Menus[I].Caption);
 End;
 AppShowMouse;
End;

Function MenuAtX(X: LongInt): Integer;
Var I: Integer;
Begin
 MenuAtX := 0;
 For I := 1 To MenuCount Do
  If (X >= Menus[I].X1) And (X <= Menus[I].X2) Then Begin
   MenuAtX := I; Exit;
  End;
End;

Var
 DropX, DropY, DropW, DropH: Integer;

Function DropItemH(M, I: Integer): Integer;
Begin
 If Menus[M].Items[I].IsSep Then DropItemH := 6 Else DropItemH := 14;
End;

Procedure ComputeDropLayout(M: Integer);
Var I, H, W, Tw: Integer; S: String;
Begin
 W := 130;
 For I := 1 To Menus[M].Count Do Begin
  S := Menus[M].Items[I].Caption + '   ' + Menus[M].Items[I].Shortcut;
  Tw := TextWidth(S) + 32;
  If Tw > W Then W := Tw;
 End;
 H := 4;
 For I := 1 To Menus[M].Count Do H := H + DropItemH(M, I);
 H := H + 2;
 DropX := Menus[M].X1;
 DropY := MENU_H;
 DropW := W;
 DropH := H;
 If DropX + DropW > SCREEN_W - 2 Then DropX := SCREEN_W - DropW - 2;
End;

Procedure DrawDropDown;
Var M, I, Y, Ih, Bg, Fg: Integer; S: String;
Begin
 If RibbonMode Then Exit;
 If MenuOpen = 0 Then Exit;
 M := MenuOpen;
 ComputeDropLayout(M);
 AppHideMouse;
 DropShadow(DropX, DropY, DropX + DropW, DropY + DropH);
 DrawRaised(DropX, DropY, DropX + DropW, DropY + DropH,
            CLR_MENU_BG, CLR_WIN_HI, CLR_WIN_LO);
 Y := DropY + 2;
 For I := 1 To Menus[M].Count Do Begin
  Ih := DropItemH(M, I);
  If Menus[M].Items[I].IsSep Then Begin
   HLine(DropX + 4, DropX + DropW - 4, Y + 2, CLR_WIN_LO);
   HLine(DropX + 4, DropX + DropW - 4, Y + 3, CLR_WIN_HI);
  End
  Else Begin
   If I = MenuItemHover Then Begin Bg := CLR_MENU_SEL_BG; Fg := CLR_MENU_SEL_FG; End
   Else Begin Bg := CLR_MENU_BG; Fg := CLR_MENU_FG; End;
   FillBox(DropX + 2, Y, DropX + DropW - 2, Y + Ih - 1, Bg);
   SetColor(Fg);
   OutTextXY(DropX + 8, Y + 2, Menus[M].Items[I].Caption);
   S := Menus[M].Items[I].Shortcut;
   If S <> '' Then
    OutTextXY(DropX + DropW - TextWidth(S) - 8, Y + 2, S);
  End;
  Y := Y + Ih;
 End;
 AppShowMouse;
End;

{ Phase 12 : repaint d'une seule rangee d'item dans le menu deroulant ouvert
  (pas de cadre, pas d'ombre) -- evite le scintillement plein dropdown lors
  d'un simple changement de surlignage. }
Procedure DrawDropDownItem(I: Integer);
Var M, J, Y, Ih, Bg, Fg: Integer; S: String;
Begin
 If MenuOpen = 0 Then Exit;
 M := MenuOpen;
 If (I < 1) Or (I > Menus[M].Count) Then Exit;
 If Menus[M].Items[I].IsSep Then Exit;
 Y := DropY + 2;
 For J := 1 To I - 1 Do Y := Y + DropItemH(M, J);
 Ih := DropItemH(M, I);
 If I = MenuItemHover Then Begin Bg := CLR_MENU_SEL_BG; Fg := CLR_MENU_SEL_FG; End
 Else Begin Bg := CLR_MENU_BG; Fg := CLR_MENU_FG; End;
 AppHideMouse;
 FillBox(DropX + 2, Y, DropX + DropW - 2, Y + Ih - 1, Bg);
 SetColor(Fg);
 OutTextXY(DropX + 8, Y + 2, Menus[M].Items[I].Caption);
 S := Menus[M].Items[I].Shortcut;
 If S <> '' Then
  OutTextXY(DropX + DropW - TextWidth(S) - 8, Y + 2, S);
 AppShowMouse;
End;

{ Phase 12 : change l'item survole sans repeindre tout le dropdown. }
Procedure SetMenuItemHover(NewSel: Integer);
Var Old: Integer;
Begin
 If MenuOpen = 0 Then Exit;
 If NewSel = MenuItemHover Then Exit;
 Old := MenuItemHover;
 MenuItemHover := NewSel;
 If Old <> 0 Then DrawDropDownItem(Old);
 If NewSel <> 0 Then DrawDropDownItem(NewSel);
End;

Function DropItemAtY(M: Integer; Y: LongInt): Integer;
Var I, YY, Ih: Integer;
Begin
 DropItemAtY := 0;
 YY := DropY + 2;
 For I := 1 To Menus[M].Count Do Begin
  Ih := DropItemH(M, I);
  If (Y >= YY) And (Y < YY + Ih) And (Not Menus[M].Items[I].IsSep) Then Begin
   DropItemAtY := I; Exit;
  End;
  YY := YY + Ih;
 End;
End;

{ ====================================================================== }
{                       ICONES VECTORIELLES 18x18                        }
{ ====================================================================== }

Procedure IconSetColor(C: Integer);
Begin If RibbonInk>=0 Then C:=RibbonInk;SetColor(C);End;
Procedure IconSetFillStyle(Style,C: Integer);
Begin If RibbonInk>=0 Then C:=RibbonInk;SetFillStyle(Style,C);End;
Procedure IconFillBox(X1,Y1,X2,Y2,C: Integer);
Begin
 If RibbonInk>=0 Then Begin C:=CLR_MENU_BG;If RibbonInk=CLR_WHITE Then C:=CLR_MENU_SEL_BG;End;
 FillBox(X1,Y1,X2,Y2,C);
End;
Procedure IconHLine(X1,X2,Y,C: Integer);
Begin If RibbonInk>=0 Then C:=RibbonInk;HLine(X1,X2,Y,C);End;
Procedure IconVLine(X,Y1,Y2,C: Integer);
Begin If RibbonInk>=0 Then C:=RibbonInk;VLine(X,Y1,Y2,C);End;

Procedure IconNew(X, Y: Integer);
Begin
 IconFillBox(X + 3, Y + 1, X + 12, Y + 16, CLR_WHITE);
 IconSetColor(CLR_BLACK);
 Rectangle(X + 3, Y + 1, X + 12, Y + 16);
 Line(X + 9, Y + 1, X + 12, Y + 4);
 IconHLine(X + 5, X + 10, Y + 7, CLR_DGRAY);
 IconHLine(X + 5, X + 10, Y + 9, CLR_DGRAY);
 IconHLine(X + 5, X + 10, Y + 11, CLR_DGRAY);
End;

Procedure IconOpen(X, Y: Integer);
Begin
 IconSetColor(CLR_BLACK);
 IconFillBox(X + 1, Y + 5, X + 15, Y + 14, CLR_YELLOW);
 Rectangle(X + 1, Y + 5, X + 15, Y + 14);
 Line(X + 1, Y + 5, X + 4, Y + 3);
 Line(X + 4, Y + 3, X + 8, Y + 3);
 Line(X + 8, Y + 3, X + 9, Y + 5);
 IconHLine(X + 2, X + 14, Y + 7, CLR_BROWN);
End;

Procedure IconSave(X, Y: Integer);
Begin
 IconFillBox(X + 2, Y + 2, X + 15, Y + 15, CLR_BLUE);
 IconSetColor(CLR_BLACK); Rectangle(X + 2, Y + 2, X + 15, Y + 15);
 IconFillBox(X + 5, Y + 2, X + 12, Y + 6, CLR_WHITE);
 IconSetColor(CLR_BLACK); Rectangle(X + 5, Y + 2, X + 12, Y + 6);
 IconFillBox(X + 9, Y + 3, X + 11, Y + 5, CLR_BLACK);
 IconFillBox(X + 4, Y + 9, X + 13, Y + 14, CLR_WHITE);
End;

Procedure IconPrint(X, Y: Integer);
Begin
 IconFillBox(X + 4, Y + 2, X + 13, Y + 6, CLR_WHITE);
 IconSetColor(CLR_BLACK); Rectangle(X + 4, Y + 2, X + 13, Y + 6);
 IconFillBox(X + 1, Y + 6, X + 16, Y + 12, CLR_LGRAY);
 IconSetColor(CLR_BLACK); Rectangle(X + 1, Y + 6, X + 16, Y + 12);
 IconFillBox(X + 4, Y + 12, X + 13, Y + 15, CLR_WHITE);
 IconSetColor(CLR_BLACK); Rectangle(X + 4, Y + 12, X + 13, Y + 15);
 PutPixel(X + 13, Y + 8, CLR_GREEN);
End;

Procedure IconCut(X, Y: Integer);
Begin
 IconSetColor(CLR_BLACK);
 Line(X + 3, Y + 3, X + 13, Y + 13);
 Line(X + 13, Y + 3, X + 3, Y + 13);
 IconSetColor(CLR_RED);
 Circle(X + 4, Y + 14, 2);
 Circle(X + 12, Y + 14, 2);
End;

Procedure IconCopy(X, Y: Integer);
Begin
 IconFillBox(X + 5, Y + 3, X + 13, Y + 14, CLR_WHITE);
 IconSetColor(CLR_BLACK); Rectangle(X + 5, Y + 3, X + 13, Y + 14);
 IconFillBox(X + 2, Y + 6, X + 10, Y + 16, CLR_WHITE);
 IconSetColor(CLR_BLACK); Rectangle(X + 2, Y + 6, X + 10, Y + 16);
End;

Procedure IconPaste(X, Y: Integer);
Begin
 IconFillBox(X + 5, Y + 2, X + 12, Y + 4, CLR_BROWN);
 IconFillBox(X + 3, Y + 4, X + 14, Y + 15, CLR_YELLOW);
 IconSetColor(CLR_BLACK); Rectangle(X + 3, Y + 4, X + 14, Y + 15);
 IconFillBox(X + 5, Y + 7, X + 12, Y + 13, CLR_WHITE);
End;

Procedure IconUndo(X, Y: Integer);
Begin
 IconSetColor(CLR_BLUE);
 Arc(X + 9, Y + 11, 30, 200, 6);
 Line(X + 3, Y + 11, X + 3, Y + 5);
 Line(X + 3, Y + 5, X + 7, Y + 5);
 Line(X + 3, Y + 5, X + 5, Y + 3);
 Line(X + 3, Y + 5, X + 5, Y + 7);
End;

Procedure IconRedo(X, Y: Integer);
Begin
 IconSetColor(CLR_BLUE);
 Arc(X + 9, Y + 11, 0, 150, 6);
 Line(X + 15, Y + 11, X + 15, Y + 5);
 Line(X + 11, Y + 5, X + 15, Y + 5);
 Line(X + 15, Y + 5, X + 13, Y + 3);
 Line(X + 15, Y + 5, X + 13, Y + 7);
End;

Procedure IconNewSlide(X, Y: Integer);
Begin
 IconFillBox(X + 2, Y + 2, X + 14, Y + 12, CLR_WHITE);
 IconSetColor(CLR_BLACK); Rectangle(X + 2, Y + 2, X + 14, Y + 12);
 IconHLine(X + 4, X + 12, Y + 5, CLR_BLUE);
 IconHLine(X + 4, X + 12, Y + 8, CLR_DGRAY);
 IconSetColor(CLR_GREEN);
 Line(X + 14, Y + 14, X + 14, Y + 17);
 Line(X + 12, Y + 16, X + 16, Y + 16);
End;

Procedure IconDelSlide(X, Y: Integer);
Begin
 IconFillBox(X + 2, Y + 2, X + 14, Y + 12, CLR_WHITE);
 IconSetColor(CLR_BLACK); Rectangle(X + 2, Y + 2, X + 14, Y + 12);
 IconHLine(X + 4, X + 12, Y + 5, CLR_BLUE);
 IconSetColor(CLR_RED);
 Line(X + 12, Y + 13, X + 16, Y + 17);
 Line(X + 16, Y + 13, X + 12, Y + 17);
End;

Procedure IconText(X, Y: Integer);
Begin
 IconSetColor(CLR_BLACK);
 Rectangle(X + 2, Y + 4, X + 15, Y + 15);
 IconSetColor(CLR_DGRAY);
 Line(X + 5, Y + 6, X + 12, Y + 6);
 Line(X + 8, Y + 6, X + 8, Y + 13);
 Line(X + 7, Y + 13, X + 9, Y + 13);
End;

Procedure IconRect(X, Y: Integer);
Begin
 IconFillBox(X + 2, Y + 4, X + 15, Y + 14, CLR_LCYAN);
 IconSetColor(CLR_BLUE); Rectangle(X + 2, Y + 4, X + 15, Y + 14);
End;

Procedure IconEllipse(X, Y: Integer);
Begin
 IconSetFillStyle(1, CLR_LRED);
 FillEllipse(X + 9, Y + 9, 6, 4);
 IconSetColor(CLR_RED); Ellipse(X + 9, Y + 9, 0, 360, 6, 4);
End;

Procedure IconLine(X, Y: Integer);
Begin
 IconSetColor(CLR_BLACK); Line(X + 2, Y + 14, X + 15, Y + 3);
 Line(X + 3, Y + 14, X + 15, Y + 4);
End;

Procedure IconArrow(X, Y: Integer);
Begin
 IconSetColor(CLR_BLACK);
 Line(X + 2, Y + 9, X + 14, Y + 9);
 Line(X + 14, Y + 9, X + 11, Y + 6);
 Line(X + 14, Y + 9, X + 11, Y + 12);
End;

Procedure IconTriangle(X, Y: Integer);
Begin
 IconSetFillStyle(1, CLR_LGREEN);
 IconSetColor(CLR_GREEN);
 Line(X + 8, Y + 3, X + 2, Y + 14);
 Line(X + 8, Y + 3, X + 14, Y + 14);
 Line(X + 2, Y + 14, X + 14, Y + 14);
 FloodFill(X + 8, Y + 12, CLR_GREEN);
End;

Procedure IconStar(X, Y: Integer);
Var Cx, Cy: Integer;
Begin
 Cx := X + 9; Cy := Y + 9;
 IconSetColor(CLR_YELLOW);
 Line(Cx, Cy - 6, Cx - 5, Cy + 5);
 Line(Cx - 5, Cy + 5, Cx + 6, Cy - 2);
 Line(Cx + 6, Cy - 2, Cx - 6, Cy - 2);
 Line(Cx - 6, Cy - 2, Cx + 5, Cy + 5);
 Line(Cx + 5, Cy + 5, Cx, Cy - 6);
End;

Procedure IconImage(X, Y: Integer);
Begin
 IconFillBox(X + 2, Y + 3, X + 15, Y + 14, CLR_WHITE);
 IconSetColor(CLR_BLACK); Rectangle(X + 2, Y + 3, X + 15, Y + 14);
 IconSetFillStyle(1, CLR_YELLOW); FillEllipse(X + 6, Y + 7, 2, 2);
 IconSetColor(CLR_GREEN);
 Line(X + 3, Y + 13, X + 8, Y + 8);
 Line(X + 8, Y + 8, X + 12, Y + 11);
 Line(X + 12, Y + 11, X + 14, Y + 9);
End;

Procedure IconTable(X, Y: Integer);
Begin
 IconFillBox(X + 2, Y + 3, X + 15, Y + 15, CLR_WHITE);
 IconSetColor(CLR_BLACK); Rectangle(X + 2, Y + 3, X + 15, Y + 15);
 IconFillBox(X + 2, Y + 3, X + 15, Y + 6, CLR_LBLUE);
 IconHLine(X + 2, X + 15, Y + 9, CLR_DGRAY);
 IconHLine(X + 2, X + 15, Y + 12, CLR_DGRAY);
 IconVLine(X + 8, Y + 3, Y + 15, CLR_DGRAY);
End;

Procedure IconBold(X, Y: Integer);
Begin
 IconSetColor(CLR_BLACK);
 OutTextXY(X + 6, Y + 4, 'B');
 OutTextXY(X + 7, Y + 4, 'B');
End;

Procedure IconItal(X, Y: Integer);
Begin
 IconSetColor(CLR_BLACK);
 OutTextXY(X + 7, Y + 4, 'I');
 Line(X + 6, Y + 14, X + 9, Y + 14);
 Line(X + 5, Y + 4, X + 8, Y + 4);
End;

Procedure IconUnd(X, Y: Integer);
Begin
 IconSetColor(CLR_BLACK);
 OutTextXY(X + 6, Y + 3, 'U');
 Line(X + 4, Y + 14, X + 14, Y + 14);
End;

Procedure IconAlignL(X, Y: Integer);
Begin
 IconSetColor(CLR_BLACK);
 Line(X + 2, Y + 4, X + 14, Y + 4);
 Line(X + 2, Y + 7, X + 10, Y + 7);
 Line(X + 2, Y + 10, X + 14, Y + 10);
 Line(X + 2, Y + 13, X + 9, Y + 13);
End;

Procedure IconAlignC(X, Y: Integer);
Begin
 IconSetColor(CLR_BLACK);
 Line(X + 2, Y + 4, X + 14, Y + 4);
 Line(X + 4, Y + 7, X + 12, Y + 7);
 Line(X + 2, Y + 10, X + 14, Y + 10);
 Line(X + 5, Y + 13, X + 11, Y + 13);
End;

Procedure IconAlignR(X, Y: Integer);
Begin
 IconSetColor(CLR_BLACK);
 Line(X + 2, Y + 4, X + 14, Y + 4);
 Line(X + 6, Y + 7, X + 14, Y + 7);
 Line(X + 2, Y + 10, X + 14, Y + 10);
 Line(X + 7, Y + 13, X + 14, Y + 13);
End;

Procedure IconBullet(X, Y: Integer);
Begin
 IconSetColor(CLR_BLACK);
 PutPixel(X + 3, Y + 5, CLR_BLACK); PutPixel(X + 4, Y + 5, CLR_BLACK);
 PutPixel(X + 3, Y + 6, CLR_BLACK); PutPixel(X + 4, Y + 6, CLR_BLACK);
 Line(X + 6, Y + 5, X + 14, Y + 5);
 PutPixel(X + 3, Y + 9, CLR_BLACK); PutPixel(X + 4, Y + 9, CLR_BLACK);
 PutPixel(X + 3, Y + 10, CLR_BLACK); PutPixel(X + 4, Y + 10, CLR_BLACK);
 Line(X + 6, Y + 9, X + 14, Y + 9);
 PutPixel(X + 3, Y + 13, CLR_BLACK); PutPixel(X + 4, Y + 13, CLR_BLACK);
 PutPixel(X + 3, Y + 14, CLR_BLACK); PutPixel(X + 4, Y + 14, CLR_BLACK);
 Line(X + 6, Y + 13, X + 14, Y + 13);
End;

Procedure IconFill(X, Y: Integer);
Begin
 IconSetFillStyle(1, CLR_LRED);
 Bar(X + 3, Y + 4, X + 14, Y + 12);
 IconSetColor(CLR_BLACK); Rectangle(X + 3, Y + 4, X + 14, Y + 12);
 IconSetColor(CLR_RED);
 Line(X + 5, Y + 13, X + 12, Y + 13);
 Line(X + 6, Y + 14, X + 11, Y + 14);
End;

Procedure IconPen(X, Y: Integer);
Begin
 IconSetColor(CLR_BROWN);
 Line(X + 3, Y + 14, X + 14, Y + 3);
 Line(X + 4, Y + 14, X + 14, Y + 4);
 IconSetColor(CLR_BLACK);
 Line(X + 12, Y + 2, X + 15, Y + 5);
End;

Procedure IconSlideshow(X, Y: Integer);
Begin
 IconSetFillStyle(1, CLR_LGREEN);
 Bar(X + 4, Y + 3, X + 5, Y + 14);
 IconSetColor(CLR_GREEN);
 Line(X + 4, Y + 3, X + 15, Y + 9);
 Line(X + 4, Y + 14, X + 15, Y + 9);
 Line(X + 5, Y + 4, X + 14, Y + 9);
 Line(X + 5, Y + 13, X + 14, Y + 9);
End;

Procedure IconHelp(X, Y: Integer);
Begin
 IconSetFillStyle(1, CLR_BLUE);
 FillEllipse(X + 8, Y + 9, 6, 6);
 IconSetColor(CLR_WHITE);
 OutTextXY(X + 5, Y + 5, '?');
End;

Procedure IconSelect(X, Y: Integer);
Begin
 IconSetColor(CLR_BLACK);
 Line(X + 4, Y + 3, X + 4, Y + 14);
 Line(X + 4, Y + 3, X + 12, Y + 11);
 Line(X + 4, Y + 14, X + 8, Y + 11);
 Line(X + 12, Y + 11, X + 8, Y + 11);
 Line(X + 8, Y + 11, X + 11, Y + 16);
End;

Procedure IconFont(X, Y: Integer);
Begin
 IconSetColor(CLR_BLACK);
 OutTextXY(X + 4, Y + 3, 'A');
 IconSetColor(CLR_RED);
 Line(X + 3, Y + 13, X + 14, Y + 13);
 Line(X + 3, Y + 14, X + 14, Y + 14);
End;

Procedure IconTrans(X, Y: Integer);
Begin
 IconSetFillStyle(1, CLR_LCYAN);
 Bar(X + 2, Y + 4, X + 7, Y + 13);
 IconSetColor(CLR_CYAN); Rectangle(X + 2, Y + 4, X + 7, Y + 13);
 IconSetFillStyle(1, CLR_LMAGENTA);
 Bar(X + 10, Y + 4, X + 15, Y + 13);
 IconSetColor(CLR_MAGENTA); Rectangle(X + 10, Y + 4, X + 15, Y + 13);
 IconSetColor(CLR_BLACK);
 Line(X + 7, Y + 9, X + 10, Y + 9);
 Line(X + 10, Y + 9, X + 8, Y + 7);
 Line(X + 10, Y + 9, X + 8, Y + 11);
End;

Procedure IconAnim(X, Y: Integer);
Begin
 IconSetColor(CLR_YELLOW);
 IconSetFillStyle(1, CLR_YELLOW);
 FillEllipse(X + 6, Y + 9, 3, 3);
 IconSetColor(CLR_BLACK);
 Line(X + 9, Y + 9, X + 15, Y + 5);
 Line(X + 9, Y + 9, X + 15, Y + 9);
 Line(X + 9, Y + 9, X + 15, Y + 13);
End;

Procedure DrawIcon(IconId, X, Y: Integer);
Begin
 Case IconId Of
  ICO_NEW:       IconNew(X, Y);
  ICO_OPEN:      IconOpen(X, Y);
  ICO_SAVE:      IconSave(X, Y);
  ICO_PRINT:     IconPrint(X, Y);
  ICO_CUT:       IconCut(X, Y);
  ICO_COPY:      IconCopy(X, Y);
  ICO_PASTE:     IconPaste(X, Y);
  ICO_UNDO:      IconUndo(X, Y);
  ICO_REDO:      IconRedo(X, Y);
  ICO_NEWSLIDE:  IconNewSlide(X, Y);
  ICO_DELSLIDE:  IconDelSlide(X, Y);
  ICO_TEXT:      IconText(X, Y);
  ICO_RECT:      IconRect(X, Y);
  ICO_ELLIPSE:   IconEllipse(X, Y);
  ICO_LINE:      IconLine(X, Y);
  ICO_ARROW:     IconArrow(X, Y);
  ICO_TRIANGLE:  IconTriangle(X, Y);
  ICO_STAR:      IconStar(X, Y);
  ICO_IMAGE:     IconImage(X, Y);
  ICO_TABLE:     IconTable(X, Y);
  ICO_BOLD:      IconBold(X, Y);
  ICO_ITAL:      IconItal(X, Y);
  ICO_UND:       IconUnd(X, Y);
  ICO_ALIGN_L:   IconAlignL(X, Y);
  ICO_ALIGN_C:   IconAlignC(X, Y);
  ICO_ALIGN_R:   IconAlignR(X, Y);
  ICO_BULLET:    IconBullet(X, Y);
  ICO_FILL:      IconFill(X, Y);
  ICO_PEN:       IconPen(X, Y);
  ICO_SLIDESHOW: IconSlideshow(X, Y);
  ICO_HELP:      IconHelp(X, Y);
  ICO_SELECT:    IconSelect(X, Y);
  ICO_FONT:      IconFont(X, Y);
  ICO_TRANS:     IconTrans(X, Y);
  ICO_ANIM:      IconAnim(X, Y);
 End;
End;

{ ====================================================================== }
{                       BARRE D'OUTILS                                   }
{ ====================================================================== }

Procedure AddTool(IconId: Integer; Const Hint: String; Action: Integer;
                  Toggle: Boolean);
Begin
 If ToolCount >= 40 Then Exit;
 Inc(ToolCount);
 Tools[ToolCount].Icon    := IconId;
 Tools[ToolCount].Hint    := Hint;
 Tools[ToolCount].Action  := Action;
 Tools[ToolCount].IsSep   := False;
 Tools[ToolCount].Enabled := True;
 Tools[ToolCount].Toggle  := Toggle;
 Tools[ToolCount].Down    := False;
End;

Procedure AddToolSep;
Begin
 If ToolCount >= 40 Then Exit;
 Inc(ToolCount);
 Tools[ToolCount].IsSep := True;
End;

Procedure InitTools;
Var I, X: Integer;
Begin
 ToolCount := 0;
 AddTool(ICO_NEW,       'Nouveau',                 ACT_NEW,         False);
 AddTool(ICO_OPEN,      'Ouvrir',                  ACT_OPEN,        False);
 AddTool(ICO_SAVE,      'Enregistrer',             ACT_SAVE,        False);
 AddTool(ICO_PRINT,     'Imprimer',                ACT_PRINT,       False);
 AddToolSep;
 AddTool(ICO_CUT,       'Couper',                  ACT_CUT,         False);
 AddTool(ICO_COPY,      'Copier',                  ACT_COPY,        False);
 AddTool(ICO_PASTE,     'Coller',                  ACT_PASTE,       False);
 AddTool(ICO_UNDO,      'Annuler',                 ACT_UNDO,        False);
 AddTool(ICO_REDO,      'Retablir',                ACT_REDO,        False);
 AddToolSep;
 AddTool(ICO_NEWSLIDE,  'Nouvelle diapositive',    ACT_NEW_SLIDE,   False);
 AddTool(ICO_DELSLIDE,  'Supprimer la diapositive',ACT_DEL_SLIDE,   False);
 AddToolSep;
 AddTool(ICO_SELECT,    'Selectionner',            ACT_TOOL_SELECT, True);
 AddTool(ICO_TEXT,      'Zone de texte',           ACT_TOOL_TEXT,   True);
 AddTool(ICO_RECT,      'Rectangle',               ACT_TOOL_RECT,   True);
 AddTool(ICO_ELLIPSE,   'Ellipse',                 ACT_TOOL_ELL,    True);
 AddTool(ICO_LINE,      'Ligne',                   ACT_TOOL_LINE,   True);
 AddTool(ICO_ARROW,     'Fleche',                  ACT_TOOL_ARROW,  True);
 AddTool(ICO_TRIANGLE,  'Triangle',                ACT_INS_TRIANGLE,False);
 AddTool(ICO_STAR,      'Etoile',                  ACT_INS_STAR,    False);
 AddToolSep;
 AddTool(ICO_IMAGE,     'Image',                   ACT_INS_IMAGE,   False);
 AddTool(ICO_TABLE,     'Tableau',                 ACT_INS_TABLE,   False);
 AddToolSep;
 AddTool(ICO_BOLD,      'Gras',                    ACT_FONT_BOLD,   True);
 AddTool(ICO_ITAL,      'Italique',                ACT_FONT_ITAL,   True);
 AddTool(ICO_UND,       'Souligne',                ACT_FONT_UND,    True);
 AddTool(ICO_ALIGN_L,   'Aligner a gauche',        ACT_ALIGN_LEFT,  True);
 AddTool(ICO_ALIGN_C,   'Centrer',                 ACT_ALIGN_CENTER,True);
 AddTool(ICO_ALIGN_R,   'Aligner a droite',        ACT_ALIGN_RIGHT, True);
 AddTool(ICO_BULLET,    'Puces',                   ACT_BULLET,      True);
 AddToolSep;
 AddTool(ICO_FILL,      'Remplissage',             ACT_COLOR_FILL,  False);
 AddTool(ICO_PEN,       'Contour',                 ACT_COLOR_LINE,  False);
 AddTool(ICO_FONT,      'Couleur du texte',        ACT_COLOR_TEXT,  False);
 AddToolSep;
 AddTool(ICO_TRANS,     'Transitions',             ACT_TRANS,       False);
 AddTool(ICO_ANIM,      'Animations',              ACT_ANIM_ENTRY,  False);
 AddTool(ICO_SLIDESHOW, 'Diaporama (F5)',          ACT_SLIDESHOW,   False);
 AddTool(ICO_HELP,      'Aide',                    ACT_HELP_TOPIC,  False);

 ToolY1 := MENU_H;
 ToolY2 := MENU_H + TOOL_H - 1;
 X := 2;
 For I := 1 To ToolCount Do Begin
  If Tools[I].IsSep Then Begin
   Tools[I].X1 := X; Tools[I].X2 := X + 3;
   Tools[I].Y1 := ToolY1 + 2; Tools[I].Y2 := ToolY2 - 2;
   X := X + 6;
  End
  Else Begin
   Tools[I].X1 := X; Tools[I].X2 := X + 19;
   Tools[I].Y1 := ToolY1 + 1; Tools[I].Y2 := ToolY2 - 1;
   X := X + 20;
  End;
 End;
End;

Function RibbonActionEnabled(A: Integer): Boolean;
Begin
 RibbonActionEnabled:=False;
 Case A Of
  ACT_QUIT,ACT_NEW,ACT_OPEN,ACT_SAVE,ACT_SAVEAS,ACT_CLOSE,ACT_PRINT,ACT_EXPORT_PPTX,ACT_IMPORT_PPTX,
  ACT_HELP_ABOUT,ACT_NEW_SLIDE,ACT_DUP_SLIDE,ACT_DEL_SLIDE,ACT_NEXT_SLIDE,ACT_PREV_SLIDE,ACT_FIRST_SLIDE,
  ACT_LAST_SLIDE,ACT_VIEW_NORMAL,ACT_VIEW_OUTLINE,ACT_VIEW_SORTER,ACT_VIEW_NOTES,ACT_TOOL_SELECT,ACT_INS_RECT,
  ACT_INS_ELLIPSE,ACT_INS_LINE,ACT_INS_ARROW,ACT_INS_TRIANGLE,ACT_INS_STAR,ACT_INS_CALLOUT,ACT_INS_TEXT,
  ACT_FONT_BOLD,ACT_FONT_ITAL,ACT_FONT_UND,ACT_ALIGN_LEFT,ACT_ALIGN_CENTER,ACT_ALIGN_RIGHT,ACT_BULLET,
  ACT_INDENT_INC,ACT_INDENT_DEC,ACT_FONT_SIZE_UP,ACT_FONT_SIZE_DN,ACT_COLOR_FILL,ACT_COLOR_LINE,
  ACT_COLOR_TEXT,ACT_MOVE_UP,ACT_MOVE_DOWN,ACT_LAYOUT,ACT_BACKGROUND,ACT_THEME,ACT_VIEW_MASTER,ACT_INS_HEADER,
  ACT_SLIDESHOW,ACT_SLIDESHOW_FROM,ACT_RUN_FROM_BEG,ACT_TRANS,ACT_INS_IMAGE,ACT_ANIM_ENTRY,ACT_ANIM_EXIT,
  ACT_TIMING,ACT_DELETE,ACT_DUP,ACT_BRING_FRONT,ACT_SEND_BACK:
   RibbonActionEnabled:=True;
 End;
End;
Function RibbonItemCount: Integer;
Var I,N: Integer;
Begin
 N:=0;For I:=1 To Menus[RibbonTab].Count Do If Not Menus[RibbonTab].Items[I].IsSep Then Inc(N);
 RibbonItemCount:=N;
End;
Function RibbonMenuItem(Index: Integer): Integer;
Var I,N: Integer;
Begin
 N:=0;RibbonMenuItem:=0;
 For I:=1 To Menus[RibbonTab].Count Do If Not Menus[RibbonTab].Items[I].IsSep Then Begin
  Inc(N);If N=Index Then Begin RibbonMenuItem:=I;Exit;End;
 End;
End;
Function RibbonEntryEnabled(Index: Integer): Boolean;
Var Item: Integer;
Begin
 RibbonEntryEnabled:=False;Item:=RibbonMenuItem(Index);If Item=0 Then Exit;
 RibbonEntryEnabled:=Menus[RibbonTab].Items[Item].Enabled And
  RibbonActionEnabled(Menus[RibbonTab].Items[Item].Action);
End;
Procedure RibbonButtonBox(Index: Integer;Var X,Y,W,H: Integer);
Var Columns: Integer;
Begin
 Columns:=(RibbonItemCount+3) Div 4;If Columns<3 Then Columns:=3;
 W:=(SCREEN_W-16) Div Columns;H:=24;
 X:=8+((Index-1) Div 4)*W;Y:=MENU_H+4+((Index-1) Mod 4)*H;
End;
Function RibbonHitAt(X,Y: LongInt): Integer;
Var I,BX,BY,W,H: Integer;
Begin
 RibbonHitAt:=0;If Not RibbonMode Then Exit;
 For I:=1 To RibbonItemCount Do Begin
  RibbonButtonBox(I,BX,BY,W,H);
  If (X>=BX) And (X<BX+W-4) And (Y>=BY) And (Y<BY+H-2) Then Begin RibbonHitAt:=I;Exit;End;
 End;
End;
Function RibbonActionIcon(A: Integer): Integer;
Var I,N: Integer;
Begin
 N:=ICO_NEWSLIDE;A:=RibbonCanonicalAction(A);
 For I:=1 To ToolCount Do If Not Tools[I].IsSep And
  (RibbonCanonicalAction(Tools[I].Action)=A) Then N:=Tools[I].Icon;
 Case A Of
  ACT_SAVEAS,ACT_EXPORT_PPTX: N:=ICO_SAVE;ACT_IMPORT_PPTX: N:=ICO_OPEN;
  ACT_VIEW_NORMAL,ACT_VIEW_OUTLINE,ACT_VIEW_SORTER,ACT_VIEW_NOTES,ACT_LAYOUT: N:=ICO_NEWSLIDE;
  ACT_ANIM_EXIT: N:=ICO_ANIM;ACT_TIMING: N:=ICO_TRANS;
  ACT_SLIDESHOW_FROM: N:=ICO_SLIDESHOW;ACT_HELP_ABOUT: N:=ICO_HELP;
 End;
 RibbonActionIcon:=N;
End;
Procedure DrawRibbon;
Var I,Item,X,Y,W,H,Color: Integer;Caption: String;
Begin
 AppHideMouse;FillBox(0,ToolY1,SCREEN_W-1,ToolY2,CLR_MENU_BG);
 For I:=1 To RibbonItemCount Do Begin
  Item:=RibbonMenuItem(I);RibbonButtonBox(I,X,Y,W,H);Color:=CLR_BLACK;
  If Not RibbonEntryEnabled(I) Then Color:=CLR_DGRAY
  Else If (RibbonHover=I) Or (RibbonKeyboard And (RibbonFocus=I)) Then Begin
   FillBox(X,Y,X+W-5,Y+H-3,CLR_MENU_SEL_BG);Color:=CLR_WHITE;
  End;
  RibbonInk:=-1;If Color<>CLR_BLACK Then RibbonInk:=Color;
  DrawIcon(RibbonActionIcon(Menus[RibbonTab].Items[Item].Action),X+4,Y+2);RibbonInk:=-1;
  Caption:=Menus[RibbonTab].Items[Item].Caption;
  If TextWidth(Caption)>W-34 Then Begin
   While (Length(Caption)>0) And (TextWidth(Caption+'...')>W-34) Do Delete(Caption,Length(Caption),1);
   Caption:=Caption+'...';
  End;
  SetColor(Color);OutTextXY(X+26,Y+7,Caption);
 End;
 HLine(4,SCREEN_W-5,ToolY2-14,CLR_WIN_LO);
 SetColor(CLR_DGRAY);OutTextXY(8,ToolY2-10,Menus[RibbonTab].Caption);AppShowMouse;
End;

Procedure DrawToolBar;
Var I: Integer;
Begin
 If RibbonMode Then Exit;
 AppHideMouse;
 FillBox(0, ToolY1, SCREEN_W - 1, ToolY2, CLR_WIN_BG);
 HLine(0, SCREEN_W - 1, ToolY2, CLR_WIN_LO);
 For I := 1 To ToolCount Do Begin
  If Tools[I].IsSep Then Begin
   VLine(Tools[I].X1 + 1, Tools[I].Y1, Tools[I].Y2, CLR_WIN_LO);
   VLine(Tools[I].X1 + 2, Tools[I].Y1, Tools[I].Y2, CLR_WIN_HI);
  End
  Else Begin
   If Tools[I].Down Then
    DrawSunken(Tools[I].X1, Tools[I].Y1, Tools[I].X2, Tools[I].Y2,
               CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO)
   Else If I = ToolHover Then
    DrawRaised(Tools[I].X1, Tools[I].Y1, Tools[I].X2, Tools[I].Y2,
               CLR_LGRAY, CLR_WIN_HI, CLR_WIN_LO);
   DrawIcon(Tools[I].Icon, Tools[I].X1, Tools[I].Y1 + 1);
  End;
 End;
 AppShowMouse;
End;

Function ToolAt(X, Y: LongInt): Integer;
Var I: Integer;
Begin
 If RibbonMode Then Begin ToolAt:=0;Exit;End;
 ToolAt := 0;
 For I := 1 To ToolCount Do
  If (Not Tools[I].IsSep) And
     InRect(X, Y, Tools[I].X1, Tools[I].Y1, Tools[I].X2, Tools[I].Y2) Then Begin
   ToolAt := I; Exit;
  End;
End;

Procedure UpdateToolToggles;
Var I: Integer;
Begin
 For I := 1 To ToolCount Do
  If (Not Tools[I].IsSep) And Tools[I].Toggle Then
   Case Tools[I].Action Of
    ACT_TOOL_SELECT: Tools[I].Down := CurTool = TOOL_SELECT;
    ACT_TOOL_TEXT:   Tools[I].Down := CurTool = TOOL_TEXT;
    ACT_TOOL_RECT:   Tools[I].Down := CurTool = TOOL_RECT;
    ACT_TOOL_ELL:    Tools[I].Down := CurTool = TOOL_ELLIPSE;
    ACT_TOOL_LINE:   Tools[I].Down := CurTool = TOOL_LINE;
    ACT_TOOL_ARROW:  Tools[I].Down := CurTool = TOOL_ARROW;
   End;
End;

{ ====================================================================== }
{                       MODELE PRESENTATION / SLIDES / SHAPES            }
{ ====================================================================== }

Function NewShape: PShape;
Var P: PShape; I: Integer;
Begin
 New(P);
 P^.Name      := '';
 P^.ShType    := SHP_RECT;
 P^.X := 100; P^.Y := 100; P^.W := 200; P^.H := 120;
 P^.FillColor := CLR_LCYAN;
 P^.LineColor := CLR_BLUE;
 P^.LineWidth := 1;
 P^.Filled    := True;
 P^.Rotation  := 0;
 P^.ZOrder    := 0;
 P^.Locked    := False;
 P^.Hidden    := False;
 P^.TxtCount  := 0;
 For I := 1 To MAX_TEXT_LINES Do Begin
  P^.Text[I] := '';
  P^.Bullets[I] := False;
  P^.Indent[I] := 0;
 End;
 P^.Bold := False; P^.Italic := False; P^.Underline := False;
 P^.FontSize := 14;
 P^.TextColor := CLR_BLACK;
 P^.Align := ALIGN_LEFT;
 P^.ImageIdx := 0;
 P^.AnimEntry := ANIM_NONE;
 P^.AnimExit  := ANIM_NONE;
 P^.AnimOrder := 0;
 NewShape := P;
End;

Procedure FreeShape(Var P: PShape);
Begin
 If P <> Nil Then Begin Dispose(P); P := Nil; End;
End;

Function NewSlide: PSlide;
Var S: PSlide; I: Integer;
Begin
 New(S);
 S^.Name       := '';
 S^.Title      := '';
 S^.Layout     := LAY_TITLE_CONTENT;
 S^.Background := CLR_WHITE;
 S^.Theme      := 0;
 S^.Transition := TRANS_NONE;
 S^.TransSpeed := 1;
 S^.Notes      := '';
 S^.Hidden     := False;
 S^.ShCount    := 0;
 For I := 1 To MAX_SHAPES Do S^.Shapes[I] := Nil;
 S^.Dirty      := False;
 NewSlide := S;
End;

Procedure FreeSlide(Var S: PSlide);
Var I: Integer;
Begin
 If S = Nil Then Exit;
 For I := 1 To S^.ShCount Do FreeShape(S^.Shapes[I]);
 Dispose(S); S := Nil;
End;

Procedure AddShapeToSlide(S: PSlide; P: PShape);
Begin
 If (S = Nil) Or (P = Nil) Then Exit;
 If S^.ShCount >= MAX_SHAPES Then Exit;
 Inc(S^.ShCount);
 S^.Shapes[S^.ShCount] := P;
 S^.Dirty := True;
End;

Function AddSlideAt(Pos: Integer): Integer;
Var I: Integer; NewS: PSlide;
Begin
 AddSlideAt := 0;
 If Pres.SldCount >= MAX_SLIDES Then Exit;
 NewS := NewSlide;
 If Pos < 1 Then Pos := 1;
 If Pos > Pres.SldCount + 1 Then Pos := Pres.SldCount + 1;
 For I := Pres.SldCount Downto Pos Do
  Pres.Slides[I + 1] := Pres.Slides[I];
 Pres.Slides[Pos] := NewS;
 Inc(Pres.SldCount);
 Pres.Dirty := True;
 AddSlideAt := Pos;
End;

Procedure RemoveSlide(Idx: Integer);
Var I: Integer;
Begin
 If (Idx < 1) Or (Idx > Pres.SldCount) Then Exit;
 FreeSlide(Pres.Slides[Idx]);
 For I := Idx To Pres.SldCount - 1 Do
  Pres.Slides[I] := Pres.Slides[I + 1];
 Pres.Slides[Pres.SldCount] := Nil;
 Dec(Pres.SldCount);
 Pres.Dirty := True;
 If CurSlide > Pres.SldCount Then CurSlide := Pres.SldCount;
 If CurSlide < 1 Then CurSlide := 0;
End;

Procedure InitDefaultThemes;
Begin
 Pres.ThemeCount := 0;
 With Pres do begin
  Inc(ThemeCount);
  Themes[ThemeCount].Name        := 'Office';
  Themes[ThemeCount].BgColor     := CLR_WHITE;
  Themes[ThemeCount].TitleColor  := CLR_BLUE;
  Themes[ThemeCount].TextColor   := CLR_BLACK;
  Themes[ThemeCount].AccentColor := CLR_LRED;
  Themes[ThemeCount].FontSize    := 14;

  Inc(ThemeCount);
  Themes[ThemeCount].Name        := 'Ocean';
  Themes[ThemeCount].BgColor     := CLR_LBLUE;
  Themes[ThemeCount].TitleColor  := CLR_WHITE;
  Themes[ThemeCount].TextColor   := CLR_BLACK;
  Themes[ThemeCount].AccentColor := CLR_YELLOW;
  Themes[ThemeCount].FontSize    := 14;

  Inc(ThemeCount);
  Themes[ThemeCount].Name        := 'Sombre';
  Themes[ThemeCount].BgColor     := CLR_BLACK;
  Themes[ThemeCount].TitleColor  := CLR_YELLOW;
  Themes[ThemeCount].TextColor   := CLR_WHITE;
  Themes[ThemeCount].AccentColor := CLR_LCYAN;
  Themes[ThemeCount].FontSize    := 14;

  Inc(ThemeCount);
  Themes[ThemeCount].Name        := 'Vert';
  Themes[ThemeCount].BgColor     := CLR_LGREEN;
  Themes[ThemeCount].TitleColor  := CLR_GREEN;
  Themes[ThemeCount].TextColor   := CLR_BLACK;
  Themes[ThemeCount].AccentColor := CLR_BROWN;
  Themes[ThemeCount].FontSize    := 14;
 End;
 Pres.ThemeIdx := 1;
End;

Procedure InitPresentation;
Var I: Integer;
Begin
 Pres.Name     := 'Presentation1';
 Pres.FileName := '';
 Pres.Author   := 'Sylvain Maltais';
 Pres.Company  := 'gladir.com';
 Pres.Title    := '';
 Pres.Subject  := '';
 Pres.Comments := '';
 Pres.SldCount := 0;
 For I := 1 To MAX_SLIDES Do Pres.Slides[I] := Nil;
 Pres.ImgCount := 0;
 For I := 1 To MAX_IMAGES Do Pres.Images[I] := Nil;
 Pres.Dirty    := False;
 Pres.HeaderText   := '';
 Pres.FooterText   := 'gladir.com';
 Pres.DateText     := '2026';
 Pres.ShowHeader   := False;
 Pres.ShowFooter   := True;
 Pres.ShowDate     := True;
 Pres.ShowSlideNum := True;
 Pres.MasterBg     := CLR_WHITE;
 Pres.MasterTitleC := CLR_BLUE;
 Pres.MasterTextC  := CLR_BLACK;
 Pres.EditingMaster := False;
 InitDefaultThemes;
 CurSlide := 0;
 CurShape := 0;
End;

Procedure FreePresentation;
Var I: Integer;
Begin
 For I := 1 To Pres.SldCount Do FreeSlide(Pres.Slides[I]);
 Pres.SldCount := 0;
 For I := 1 To Pres.ImgCount Do
  If Pres.Images[I] <> Nil Then Begin
   If Pres.Images[I]^.Pixels <> Nil Then Begin
    FreeMem(Pres.Images[I]^.Pixels,
            LongInt(Pres.Images[I]^.W) * Pres.Images[I]^.H);
    Pres.Images[I]^.Pixels := Nil;
   End;
   Dispose(Pres.Images[I]); Pres.Images[I] := Nil;
  End;
 Pres.ImgCount := 0;
End;

{ Place les placeholders selon le layout sur une nouvelle slide.
  Coordonnees en pixels relatifs au cadre de la slide (1000 x 750 logique,
  re-echellonne au dessin). }
Procedure ApplyLayout(S: PSlide; Lay: Byte);
Var P: PShape;
Begin
 If S = Nil Then Exit;
 S^.Layout := Lay;
 Case Lay Of
  LAY_TITLE: Begin
   P := NewShape;
   P^.ShType := SHP_TITLE;
   P^.X := 80; P^.Y := 200; P^.W := 840; P^.H := 140;
   P^.Filled := False; P^.FillColor := CLR_WHITE;
   P^.LineColor := CLR_DGRAY; P^.LineWidth := 0;
   P^.FontSize := 36; P^.TextColor := CLR_BLUE; P^.Align := ALIGN_CENTER;
   P^.Bold := True;
   P^.TxtCount := 1; P^.Text[1] := 'Cliquez pour ajouter un titre';
   AddShapeToSlide(S, P);
   P := NewShape;
   P^.ShType := SHP_SUBTITLE;
   P^.X := 160; P^.Y := 380; P^.W := 680; P^.H := 80;
   P^.Filled := False; P^.LineWidth := 0;
   P^.FontSize := 20; P^.TextColor := CLR_DGRAY; P^.Align := ALIGN_CENTER;
   P^.TxtCount := 1; P^.Text[1] := 'Cliquez pour ajouter un sous-titre';
   AddShapeToSlide(S, P);
  End;
  LAY_TITLE_CONTENT: Begin
   P := NewShape;
   P^.ShType := SHP_TITLE;
   P^.X := 60; P^.Y := 40; P^.W := 880; P^.H := 90;
   P^.Filled := False; P^.LineWidth := 0;
   P^.FontSize := 28; P^.TextColor := CLR_BLUE; P^.Bold := True;
   P^.TxtCount := 1; P^.Text[1] := 'Cliquez pour ajouter un titre';
   AddShapeToSlide(S, P);
   P := NewShape;
   P^.ShType := SHP_CONTENT;
   P^.X := 60; P^.Y := 150; P^.W := 880; P^.H := 540;
   P^.Filled := False; P^.LineWidth := 0;
   P^.FontSize := 18;
   P^.TxtCount := 3;
   P^.Text[1] := 'Cliquez pour ajouter du texte';
   P^.Text[2] := 'Deuxieme puce'; P^.Bullets[2] := True;
   P^.Text[3] := 'Troisieme puce'; P^.Bullets[3] := True;
   P^.Bullets[1] := True;
   AddShapeToSlide(S, P);
  End;
  LAY_TWO_CONTENT: Begin
   P := NewShape;
   P^.ShType := SHP_TITLE;
   P^.X := 60; P^.Y := 40; P^.W := 880; P^.H := 90;
   P^.Filled := False; P^.LineWidth := 0;
   P^.FontSize := 28; P^.TextColor := CLR_BLUE; P^.Bold := True;
   P^.TxtCount := 1; P^.Text[1] := 'Titre';
   AddShapeToSlide(S, P);
   P := NewShape;
   P^.ShType := SHP_CONTENT;
   P^.X := 60; P^.Y := 150; P^.W := 420; P^.H := 540;
   P^.Filled := False; P^.LineWidth := 0;
   P^.TxtCount := 1; P^.Text[1] := 'Contenu gauche'; P^.Bullets[1] := True;
   AddShapeToSlide(S, P);
   P := NewShape;
   P^.ShType := SHP_CONTENT;
   P^.X := 520; P^.Y := 150; P^.W := 420; P^.H := 540;
   P^.Filled := False; P^.LineWidth := 0;
   P^.TxtCount := 1; P^.Text[1] := 'Contenu droit'; P^.Bullets[1] := True;
   AddShapeToSlide(S, P);
  End;
  LAY_TITLE_ONLY: Begin
   P := NewShape;
   P^.ShType := SHP_TITLE;
   P^.X := 60; P^.Y := 40; P^.W := 880; P^.H := 90;
   P^.Filled := False; P^.LineWidth := 0;
   P^.FontSize := 28; P^.TextColor := CLR_BLUE; P^.Bold := True;
   P^.TxtCount := 1; P^.Text[1] := 'Titre seul';
   AddShapeToSlide(S, P);
  End;
  LAY_SECTION: Begin
   P := NewShape;
   P^.ShType := SHP_RECT;
   P^.X := 0; P^.Y := 300; P^.W := 1000; P^.H := 150;
   P^.Filled := True; P^.FillColor := CLR_BLUE; P^.LineWidth := 0;
   AddShapeToSlide(S, P);
   P := NewShape;
   P^.ShType := SHP_TITLE;
   P^.X := 60; P^.Y := 320; P^.W := 880; P^.H := 110;
   P^.Filled := False; P^.LineWidth := 0;
   P^.FontSize := 36; P^.TextColor := CLR_WHITE; P^.Bold := True;
   P^.Align := ALIGN_CENTER;
   P^.TxtCount := 1; P^.Text[1] := 'Nouvelle section';
   AddShapeToSlide(S, P);
  End;
  LAY_BLANK: Begin
   { rien }
  End;
 Else
  ApplyLayout(S, LAY_TITLE_CONTENT);
 End;
End;

Procedure SeedSamplePresentation;
Var Pos: Integer; S: PSlide; P: PShape;
Begin
 { Slide 1 : titre }
 Pos := AddSlideAt(1);
 S := Pres.Slides[Pos];
 ApplyLayout(S, LAY_TITLE);
 S^.Shapes[1]^.Text[1] := 'Office-0 PresentPoint';
 S^.Shapes[2]^.Text[1] := 'Clone Pascal de Microsoft PowerPoint';

 { Slide 2 : titre + contenu }
 Pos := AddSlideAt(2);
 S := Pres.Slides[Pos];
 ApplyLayout(S, LAY_TITLE_CONTENT);
 S^.Shapes[1]^.Text[1] := 'Fonctionnalites';
 S^.Shapes[2]^.TxtCount := 5;
 S^.Shapes[2]^.Text[1] := 'Edition vectorielle de diapositives';
 S^.Shapes[2]^.Text[2] := 'Mises en page multiples';
 S^.Shapes[2]^.Text[3] := 'Themes et arriere-plans';
 S^.Shapes[2]^.Text[4] := 'Transitions et animations';
 S^.Shapes[2]^.Text[5] := 'Export .PPT et .PPTX';
 S^.Shapes[2]^.Bullets[1] := True;
 S^.Shapes[2]^.Bullets[2] := True;
 S^.Shapes[2]^.Bullets[3] := True;
 S^.Shapes[2]^.Bullets[4] := True;
 S^.Shapes[2]^.Bullets[5] := True;

 { Slide 3 : deux colonnes avec une forme }
 Pos := AddSlideAt(3);
 S := Pres.Slides[Pos];
 ApplyLayout(S, LAY_TWO_CONTENT);
 S^.Shapes[1]^.Text[1] := 'Phases du projet';
 S^.Shapes[2]^.TxtCount := 4;
 S^.Shapes[2]^.Text[1] := 'Charpente UI';
 S^.Shapes[2]^.Text[2] := 'Outils de dessin';
 S^.Shapes[2]^.Text[3] := 'Edition de texte';
 S^.Shapes[2]^.Text[4] := 'Layouts de slide';
 S^.Shapes[2]^.Bullets[1] := True;
 S^.Shapes[2]^.Bullets[2] := True;
 S^.Shapes[2]^.Bullets[3] := True;
 S^.Shapes[2]^.Bullets[4] := True;
 S^.Shapes[3]^.TxtCount := 4;
 S^.Shapes[3]^.Text[1] := 'Themes et masques';
 S^.Shapes[3]^.Text[2] := 'Diaporama F5';
 S^.Shapes[3]^.Text[3] := 'Animations';
 S^.Shapes[3]^.Text[4] := 'Format .PPTX';
 S^.Shapes[3]^.Bullets[1] := True;
 S^.Shapes[3]^.Bullets[2] := True;
 S^.Shapes[3]^.Bullets[3] := True;
 S^.Shapes[3]^.Bullets[4] := True;

 { Slide 4 : section }
 Pos := AddSlideAt(4);
 S := Pres.Slides[Pos];
 ApplyLayout(S, LAY_SECTION);
 S^.Shapes[2]^.Text[1] := 'Demarrage rapide';

 { Slide 5 : titre + contenu + forme decorative }
 Pos := AddSlideAt(5);
 S := Pres.Slides[Pos];
 ApplyLayout(S, LAY_TITLE_CONTENT);
 S^.Shapes[1]^.Text[1] := 'Formes vectorielles';
 S^.Shapes[2]^.TxtCount := 2;
 S^.Shapes[2]^.Text[1] := 'Rectangles, ellipses, lignes';
 S^.Shapes[2]^.Text[2] := 'Etoiles, triangles, bulles';
 S^.Shapes[2]^.Bullets[1] := True;
 S^.Shapes[2]^.Bullets[2] := True;
 P := NewShape;
 P^.ShType := SHP_STAR;
 P^.X := 720; P^.Y := 380; P^.W := 180; P^.H := 180;
 P^.FillColor := CLR_YELLOW; P^.LineColor := CLR_BROWN;
 AddShapeToSlide(S, P);

 Pres.Dirty := False;
 CurSlide := 1;
End;

{ ====================================================================== }
{                       LAYOUT DE LA FENETRE                             }
{ ====================================================================== }

Procedure ComputeLayout;
Var AvW, AvH, SW, SH: Integer;
Begin
 { Zone disponible pour la slide affichee : entre toolbar/ruler et statusbar,
   entre panneau gauche et bord droit. }
 AvW := SCREEN_W - PANEL_W - 12;
 AvH := SCREEN_H - (MENU_H + TOOL_H + RULER_H) - STATUS_H - 12;
 { Conserver ratio 4:3 (1000x750) }
 SW := AvW;
 SH := (SW * 3) Div 4;
 If SH > AvH Then Begin
  SH := AvH;
  SW := (SH * 4) Div 3;
 End;
 SlideX1 := PANEL_W + 6 + (AvW - SW) Div 2;
 SlideY1 := MENU_H + TOOL_H + RULER_H + 6 + (AvH - SH) Div 2;
 SlideX2 := SlideX1 + SW;
 SlideY2 := SlideY1 + SH;
 SlideScale := (SW * 100) Div 1000;   { logique 1000 -> SW pixels }
End;

Function LogX(L: Integer): Integer;
Begin LogX := SlideX1 + (L * (SlideX2 - SlideX1)) Div 1000; End;

Function LogY(L: Integer): Integer;
Begin LogY := SlideY1 + (L * (SlideY2 - SlideY1)) Div 750; End;

Function LogW(L: Integer): Integer;
Begin LogW := (L * (SlideX2 - SlideX1)) Div 1000; End;

Function LogH(L: Integer): Integer;
Begin LogH := (L * (SlideY2 - SlideY1)) Div 750; End;

{ ====================================================================== }
{                       RENDU D'UNE FORME                                }
{ ====================================================================== }

{ --- Phase 8 : images BMP/PCX --- }

{ Couleur VGA 16 la plus proche d'un triplet RGB. }
Function NearestVGA16(R, G, B: Integer): Byte;
Var I, BestI: Integer; D, BestD, DR, DG, DB: LongInt;
Begin
 BestI := 0; BestD := MaxLongInt;
 For I := 0 To 15 Do Begin
  DR := LongInt(R) - VGA_R[I];
  DG := LongInt(G) - VGA_G[I];
  DB := LongInt(B) - VGA_B[I];
  D  := DR*DR + DG*DG + DB*DB;
  If D < BestD Then Begin BestD := D; BestI := I; End;
 End;
 NearestVGA16 := Byte(BestI);
End;

{ Libere la memoire pixels d'une image. }
Procedure FreeImagePixels(Img: PImage);
Begin
 If Img = Nil Then Exit;
 If Img^.Pixels <> Nil Then Begin
  FreeMem(Img^.Pixels, LongInt(Img^.W) * Img^.H);
  Img^.Pixels := Nil;
 End;
 Img^.W := 0; Img^.H := 0; Img^.Loaded := False;
End;

{ Trouve un slot d'image libre (1..MAX_IMAGES), ou 0 si plein. }
Function FindFreeImageSlot: Integer;
Var I: Integer;
Begin
 For I := 1 To MAX_IMAGES Do
  If Pres.Images[I] = Nil Then Begin
   FindFreeImageSlot := I; Exit;
  End;
 FindFreeImageSlot := 0;
End;

{ Alloue un slot image avec un buffer pixel W*H octets. }
Function AllocImageSlot(W, H: Integer; Const Nm: String): Integer;
Var Slot: Integer; Img: PImage; Sz: LongInt;
Begin
 AllocImageSlot := 0;
 Slot := FindFreeImageSlot;
 If Slot = 0 Then Exit;
 New(Img);
 If Img = Nil Then Exit;
 Img^.Name     := Nm;
 Img^.FileName := '';
 Img^.W        := W;
 Img^.H        := H;
 Img^.Loaded   := False;
 Img^.Pixels   := Nil;
 Sz := LongInt(W) * H;
 If Sz > 0 Then Begin
  GetMem(Img^.Pixels, Sz);
  If Img^.Pixels = Nil Then Begin Dispose(Img); Exit; End;
  FillChar(Img^.Pixels^, Sz, 0);
 End;
 Pres.Images[Slot] := Img;
 If Slot > Pres.ImgCount Then Pres.ImgCount := Slot;
 AllocImageSlot := Slot;
End;

{ --- LoadBMP : 1/4/8/24 bpp non compresse --- }

Function LoadImageBMP(Const FN: String; Var Slot: Integer): Boolean;
Type
 TBMPFile = Packed Record
  bfType: Word; bfSize: LongInt;
  bfRes1, bfRes2: Word; bfOffBits: LongInt;
 End;
 TBMPInfo = Packed Record
  biSize: LongInt; biWidth, biHeight: LongInt;
  biPlanes, biBitCount: Word;
  biCompression, biSizeImage: LongInt;
  biXPel, biYPel: LongInt;
  biClrUsed, biClrImp: LongInt;
 End;
 TRGBQ = Packed Record B, G, R, X: Byte; End;
Var F: File; FH: TBMPFile; IH: TBMPInfo; Got: Word;
    RowSize: LongInt; W, H, X, Y, SrcY, I, PalN: Integer;
    RowBuf: Array[0..4095] Of Byte;
    Pal: Array[0..255] Of TRGBQ;
    Remap: Array[0..255] Of Byte;
    Img: PImage; V, BV: Byte; BP: Integer;
    Rb, Gb, Bb: Byte;
Begin
 LoadImageBMP := False; Slot := 0;
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 BlockRead(F, FH, SizeOf(FH), Got);
 If (Got <> SizeOf(FH)) Or (FH.bfType <> BMP_SIGNATURE) Then Begin Close(F); Exit; End;
 BlockRead(F, IH, SizeOf(IH), Got);
 If Got <> SizeOf(IH) Then Begin Close(F); Exit; End;
 W := IH.biWidth; H := Abs(IH.biHeight);
 If (W <= 0) Or (H <= 0) Then Begin Close(F); Exit; End;
 If W > MAX_IMG_W Then W := MAX_IMG_W;
 If H > MAX_IMG_H Then H := MAX_IMG_H;
 If IH.biCompression <> 0 Then Begin Close(F); Exit; End;
 RowSize := ((LongInt(IH.biWidth) * IH.biBitCount + 31) Div 32) * 4;
 If RowSize > 4096 Then Begin Close(F); Exit; End;
 If IH.biBitCount <= 8 Then Begin
  If IH.biClrUsed > 0 Then PalN := IH.biClrUsed
                      Else PalN := 1 Shl IH.biBitCount;
  BlockRead(F, Pal, PalN * 4, Got);
  For I := 0 To PalN - 1 Do
   Remap[I] := NearestVGA16(Pal[I].R, Pal[I].G, Pal[I].B);
  For I := PalN To 255 Do Remap[I] := 0;
 End;
 Slot := AllocImageSlot(W, H, FN);
 If Slot = 0 Then Begin Close(F); Exit; End;
 Img := Pres.Images[Slot];
 Seek(F, FH.bfOffBits);
 For Y := 0 To H - 1 Do Begin
  BlockRead(F, RowBuf, RowSize, Got);
  If IH.biHeight < 0 Then SrcY := Y Else SrcY := H - 1 - Y;
  For X := 0 To W - 1 Do Begin
   V := 0;
   Case IH.biBitCount Of
    1: Begin
     BV := RowBuf[X Shr 3]; BP := 7 - (X And 7);
     V := Remap[(BV Shr BP) And 1];
    End;
    4: Begin
     BV := RowBuf[X Shr 1];
     If (X And 1) = 0 Then V := Remap[(BV Shr 4) And 15]
                      Else V := Remap[BV And 15];
    End;
    8: V := Remap[RowBuf[X]];
    24: Begin
     Bb := RowBuf[X*3]; Gb := RowBuf[X*3+1]; Rb := RowBuf[X*3+2];
     V := NearestVGA16(Rb, Gb, Bb);
    End;
   End;
   Img^.Pixels^[LongInt(SrcY) * W + X] := V;
  End;
 End;
 Close(F);
 Img^.Loaded := True;
 LoadImageBMP := True;
End;

{ --- LoadPCX : 1/4/8 bpp, jusqu'a 4 plans --- }

Function LoadImagePCX(Const FN: String; Var Slot: Integer): Boolean;
Type
 TPCXHdr = Packed Record
  Manuf, Ver, Enc, BPP: Byte;
  Xmin, Ymin, Xmax, Ymax: Word;
  HDpi, VDpi: Word;
  EgaPal: Array[0..47] Of Byte;
  Reserved: Byte;
  NPlanes: Byte;
  BytesPerLine: Word;
  PalInfo: Word;
  HScr, VScr: Word;
  Filler: Array[0..53] Of Byte;
 End;
Var F: File; H: TPCXHdr; Got: Word; FSz: LongInt;
    Tail: Array[0..768] Of Byte;
    PalR, PalG, PalB: Array[0..255] Of Byte;
    Remap: Array[0..255] Of Byte;
    PalCount, I: Integer;
    HasPal8: Boolean;
    PcxW, PcxH, ScanBytes: LongInt;
    Scan: Array[0..16383] Of Byte;
    W, Hh, X, Y, ByteOff, BitIdx, Plane, BitC, Idx: Integer;
    Img: PImage;
    FBuf: Array[0..16383] Of Byte;
    FLen, FPos: Integer; FEof: Boolean;

 Function R1: Integer;
 Var G: Word;
 Begin
  If FPos >= FLen Then Begin
   If FEof Then Begin R1 := -1; Exit; End;
   BlockRead(F, FBuf, 16384, G); FLen := G; FPos := 0;
   If G = 0 Then Begin FEof := True; R1 := -1; Exit; End;
  End;
  R1 := FBuf[FPos]; Inc(FPos);
 End;

 Function ReadScan: Boolean;
 Var Cnt, Val, J: Integer; P: LongInt;
 Begin
  ReadScan := False; P := 0;
  While P < ScanBytes Do Begin
   Val := R1; If Val < 0 Then Exit;
   If (Val And $C0) = $C0 Then Begin
    Cnt := Val And $3F; Val := R1;
    If Val < 0 Then Exit;
    For J := 1 To Cnt Do Begin
     If P < ScanBytes Then Scan[P] := Byte(Val);
     Inc(P);
    End;
   End Else Begin
    Scan[P] := Byte(Val); Inc(P);
   End;
  End;
  ReadScan := True;
 End;

Begin
 LoadImagePCX := False; Slot := 0;
 FLen := 0; FPos := 0; FEof := False;
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 BlockRead(F, H, SizeOf(H), Got);
 If Got <> SizeOf(H) Then Begin Close(F); Exit; End;
 If (H.Manuf <> $0A) Or (H.Enc <> 1) Then Begin Close(F); Exit; End;
 If (H.BPP <> 1) And (H.BPP <> 4) And (H.BPP <> 8) Then Begin Close(F); Exit; End;
 If (H.NPlanes < 1) Or (H.NPlanes > 4) Then Begin Close(F); Exit; End;
 PcxW := LongInt(H.Xmax) - H.Xmin + 1;
 PcxH := LongInt(H.Ymax) - H.Ymin + 1;
 If (PcxW <= 0) Or (PcxH <= 0) Then Begin Close(F); Exit; End;
 ScanBytes := LongInt(H.BytesPerLine) * H.NPlanes;
 If (ScanBytes <= 0) Or (ScanBytes > 16384) Then Begin Close(F); Exit; End;
 HasPal8 := False; PalCount := 0;
 If (H.BPP = 8) And (H.NPlanes = 1) Then Begin
  FSz := FileSize(F);
  If FSz >= 769 Then Begin
   Seek(F, FSz - 769);
   BlockRead(F, Tail, 769, Got);
   If (Got = 769) And (Tail[0] = $0C) Then Begin
    HasPal8 := True; PalCount := 256;
    For I := 0 To 255 Do Begin
     PalR[I] := Tail[1 + I*3];
     PalG[I] := Tail[1 + I*3 + 1];
     PalB[I] := Tail[1 + I*3 + 2];
    End;
   End;
  End;
  Seek(F, 128);
  FLen := 0; FPos := 0; FEof := False;
 End;
 If Not HasPal8 Then Begin
  PalCount := 16;
  For I := 0 To 15 Do Begin
   PalR[I] := H.EgaPal[I*3];
   PalG[I] := H.EgaPal[I*3 + 1];
   PalB[I] := H.EgaPal[I*3 + 2];
  End;
  If (H.NPlanes = 1) And (H.BPP = 1) Then Begin
   PalR[0]:=0;   PalG[0]:=0;   PalB[0]:=0;
   PalR[1]:=255; PalG[1]:=255; PalB[1]:=255;
  End;
 End;
 For I := 0 To PalCount - 1 Do
  Remap[I] := NearestVGA16(PalR[I], PalG[I], PalB[I]);
 For I := PalCount To 255 Do Remap[I] := 0;
 W := PcxW; Hh := PcxH;
 If W  > MAX_IMG_W Then W  := MAX_IMG_W;
 If Hh > MAX_IMG_H Then Hh := MAX_IMG_H;
 Slot := AllocImageSlot(W, Hh, FN);
 If Slot = 0 Then Begin Close(F); Exit; End;
 Img := Pres.Images[Slot];
 For Y := 0 To PcxH - 1 Do Begin
  If Not ReadScan Then Begin Close(F); Exit; End;
  If Y >= Hh Then Continue;
  For X := 0 To W - 1 Do Begin
   Idx := 0;
   If (H.NPlanes = 1) And (H.BPP = 8) Then Idx := Scan[X]
   Else If (H.NPlanes = 1) And (H.BPP = 1) Then Begin
    ByteOff := X Shr 3; BitIdx := 7 - (X And 7);
    Idx := (Scan[ByteOff] Shr BitIdx) And 1;
   End
   Else If (H.NPlanes = 1) And (H.BPP = 4) Then Begin
    ByteOff := X Shr 1;
    If (X And 1) = 0 Then Idx := (Scan[ByteOff] Shr 4) And 15
                     Else Idx := Scan[ByteOff] And 15;
   End
   Else If (H.BPP = 1) And (H.NPlanes >= 2) Then Begin
    ByteOff := X Shr 3; BitIdx := 7 - (X And 7);
    Idx := 0;
    For Plane := 0 To H.NPlanes - 1 Do
     If ((Scan[Plane * H.BytesPerLine + ByteOff] Shr BitIdx) And 1) <> 0 Then
      Idx := Idx Or (1 Shl Plane);
   End;
   Img^.Pixels^[LongInt(Y) * W + X] := Remap[Idx];
  End;
 End;
 Close(F);
 Img^.Loaded := True;
 LoadImagePCX := True;
End;

{ Charge une image en detectant le format via l'extension. }
Function LoadImageFile(Const FN: String; Var Slot: Integer): Boolean;
Var I: Integer; Ext: String;
Begin
 Ext := '';
 For I := Length(FN) DownTo 1 Do
  If FN[I] = '.' Then Begin Ext := Copy(FN, I + 1, 8); Break; End;
 For I := 1 To Length(Ext) Do
  If (Ext[I] >= 'a') And (Ext[I] <= 'z') Then
   Ext[I] := Chr(Ord(Ext[I]) - 32);
 If Ext = 'BMP' Then LoadImageFile := LoadImageBMP(FN, Slot)
 Else If Ext = 'PCX' Then LoadImageFile := LoadImagePCX(FN, Slot)
 Else LoadImageFile := False;
End;

{ Affiche une image (palette 16) mise a l'echelle dans [X1..X2]x[Y1..Y2]. }
Procedure DrawImageScaled(Img: PImage; X1, Y1, X2, Y2: Integer);
Var Sx, Sy, Ix, Iy, Dw, Dh: Integer;
Begin
 If Img = Nil Then Exit;
 If Not Img^.Loaded Then Exit;
 If Img^.Pixels = Nil Then Exit;
 Dw := X2 - X1 + 1; Dh := Y2 - Y1 + 1;
 If (Dw <= 0) Or (Dh <= 0) Then Exit;
 For Sy := 0 To Dh - 1 Do Begin
  Iy := LongInt(Sy) * Img^.H Div Dh;
  If Iy >= Img^.H Then Iy := Img^.H - 1;
  For Sx := 0 To Dw - 1 Do Begin
   Ix := LongInt(Sx) * Img^.W Div Dw;
   If Ix >= Img^.W Then Ix := Img^.W - 1;
   PutPixel(X1 + Sx, Y1 + Sy,
            Img^.Pixels^[LongInt(Iy) * Img^.W + Ix]);
  End;
 End;
End;

{ La surface PTC est presentee par un autre thread. Garder le verrou pendant
  un rendu complet evite d'afficher les etapes d'effacement et de dessin. }
Procedure BeginPaint;
Begin
End;
Procedure EndPaint;
Begin
End;
Procedure ToggleTextCaret;
Begin
 If Not TextCaretKnown Then Exit;
 AppHideMouse;SetWriteMode(XORPut);SetColor(CLR_WHITE);
 Line(TextCaretX,TextCaretY,TextCaretX,TextCaretY+TextCaretHeight);
 SetWriteMode(NormalPut);AppShowMouse;
 TextCaretDrawn:=Not TextCaretDrawn;
End;
Procedure BlinkTextCaret;
Begin
 If EditMode And TextCaretKnown And (MenuOpen=0) And Not RibbonKeyboard Then Begin
  BlinkState:=Not BlinkState;
  If TextCaretDrawn<>BlinkState Then Begin BeginPaint;ToggleTextCaret;EndPaint;End;
 End;
End;

Procedure DrawShapeTextLines(P: PShape; X1, Y1, X2, Y2: Integer);
Var I, Ty, Tx, LineH, TitleSz, Ind, CaretX: Integer; S: String;
    IsEditing: Boolean;
Begin
 If P^.TxtCount <= 0 Then Exit;
 LineH := 12;
 If P^.FontSize >= 24 Then LineH := 22
 Else If P^.FontSize >= 18 Then LineH := 16
 Else LineH := 12;
 Ty := Y1 + 4;
 For I := 1 To P^.TxtCount Do Begin
  IsEditing := EditMode And (CurSlide >= 1) And
               (Pres.Slides[CurSlide]^.Shapes[CurShape] = P) And
               (EditLine = I);
  If IsEditing Then S := EditBuf Else S := P^.Text[I];
  Ind := P^.Indent[I] * 12;
  TitleSz := 1;
  If P^.FontSize >= 24 Then TitleSz := 2;
  If P^.FontSize >= 36 Then TitleSz := 3;
  SetTextStyle(DefaultFont, HorizDir, TitleSz);
  Case P^.Align Of
   ALIGN_CENTER: Tx := (X1 + X2) Div 2 - TextWidth(S) Div 2;
   ALIGN_RIGHT:  Tx := X2 - TextWidth(S) - 4;
  Else Tx := X1 + 4 + Ind;
  End;
  If P^.Bullets[I] Then Begin
   SetColor(P^.TextColor);
   FillBox(Tx - 8, Ty + 4, Tx - 5, Ty + 6, P^.TextColor);
   Tx := Tx + 4;
  End;
  SetColor(P^.TextColor);
  OutTextXY(Tx, Ty, S);
  If P^.Underline Then
   Line(Tx, Ty + LineH - 2, Tx + TextWidth(S), Ty + LineH - 2);
  { Texte en gras simule par re-trace decale d'un pixel }
  If P^.Bold Then OutTextXY(Tx + 1, Ty, S);
  { Caret clignotant en edition }
  If IsEditing Then Begin
   If (EditCaret >= 0) And (EditCaret <= Length(S)) Then
    CaretX := Tx + TextWidth(Copy(S, 1, EditCaret))
   Else
    CaretX := Tx + TextWidth(S);
   TextCaretX:=CaretX;TextCaretY:=Ty;TextCaretHeight:=LineH-2;
   TextCaretKnown:=True;
   If BlinkState Then ToggleTextCaret;
  End;
  SetTextStyle(DefaultFont, HorizDir, 1);
  Ty := Ty + LineH;
  If Ty > Y2 - LineH Then Exit;
 End;
End;

Procedure DrawStarShape(X1, Y1, X2, Y2: Integer; Fill, LineCol: Integer);
Var Cx, Cy, Rx, Ry, I: Integer;
    Pts: Array[1..11] Of Record X, Y: Integer; End;
    Angle, R: Real;
Begin
 Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
 Rx := (X2 - X1) Div 2; Ry := (Y2 - Y1) Div 2;
 For I := 1 To 10 Do Begin
  Angle := (I - 1) * 36.0 * Pi / 180.0 - Pi / 2.0;
  If (I Mod 2) = 1 Then R := 1.0 Else R := 0.45;
  Pts[I].X := Cx + Round(R * Rx * Cos(Angle));
  Pts[I].Y := Cy + Round(R * Ry * Sin(Angle));
 End;
 Pts[11] := Pts[1];
 SetFillStyle(1, Fill);
 SetColor(LineCol);
 For I := 1 To 10 Do
  Line(Pts[I].X, Pts[I].Y, Pts[I + 1].X, Pts[I + 1].Y);
 FloodFill(Cx, Cy, LineCol);
End;

Procedure DrawDiamondShape(X1, Y1, X2, Y2: Integer; Fill, LineCol: Integer);
Var Cx, Cy: Integer;
Begin
 Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
 SetColor(LineCol);
 SetFillStyle(1, Fill);
 Line(Cx, Y1, X2, Cy);
 Line(X2, Cy, Cx, Y2);
 Line(Cx, Y2, X1, Cy);
 Line(X1, Cy, Cx, Y1);
 FloodFill(Cx, Cy, LineCol);
End;

Procedure DrawTriangleShape(X1, Y1, X2, Y2: Integer; Fill, LineCol: Integer);
Var Cx: Integer;
Begin
 Cx := (X1 + X2) Div 2;
 SetColor(LineCol);
 SetFillStyle(1, Fill);
 Line(Cx, Y1, X2, Y2);
 Line(X2, Y2, X1, Y2);
 Line(X1, Y2, Cx, Y1);
 FloodFill(Cx, (Y1 + Y2) Div 2 + (Y2 - Y1) Div 4, LineCol);
End;

Procedure DrawShape(P: PShape);
Var X1, Y1, X2, Y2, Cx, Cy: Integer;
Begin
 If P = Nil Then Exit;
 If P^.Hidden Then Exit;
 X1 := LogX(P^.X);
 Y1 := LogY(P^.Y);
 X2 := LogX(P^.X + P^.W);
 Y2 := LogY(P^.Y + P^.H);
 Case P^.ShType Of
  SHP_RECT: Begin
   If P^.Filled Then Begin
    SetFillStyle(1, P^.FillColor); Bar(X1, Y1, X2, Y2);
   End;
   If P^.LineWidth > 0 Then Begin
    SetColor(P^.LineColor); Rectangle(X1, Y1, X2, Y2);
   End;
   DrawShapeTextLines(P, X1, Y1, X2, Y2);
  End;
  SHP_ROUNDRECT: Begin
   If P^.Filled Then Begin
    SetFillStyle(1, P^.FillColor); Bar(X1 + 6, Y1 + 6, X2 - 6, Y2 - 6);
    Bar(X1, Y1 + 6, X2, Y2 - 6); Bar(X1 + 6, Y1, X2 - 6, Y2);
   End;
   SetColor(P^.LineColor);
   Line(X1 + 6, Y1, X2 - 6, Y1);
   Line(X1 + 6, Y2, X2 - 6, Y2);
   Line(X1, Y1 + 6, X1, Y2 - 6);
   Line(X2, Y1 + 6, X2, Y2 - 6);
   Arc(X1 + 6, Y1 + 6, 90, 180, 6);
   Arc(X2 - 6, Y1 + 6, 0,  90, 6);
   Arc(X1 + 6, Y2 - 6, 180,270, 6);
   Arc(X2 - 6, Y2 - 6, 270,360, 6);
   DrawShapeTextLines(P, X1, Y1, X2, Y2);
  End;
  SHP_ELLIPSE: Begin
   Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
   If P^.Filled Then Begin
    SetFillStyle(1, P^.FillColor);
    FillEllipse(Cx, Cy, (X2 - X1) Div 2, (Y2 - Y1) Div 2);
   End;
   SetColor(P^.LineColor);
   Ellipse(Cx, Cy, 0, 360, (X2 - X1) Div 2, (Y2 - Y1) Div 2);
   DrawShapeTextLines(P, X1, Y1, X2, Y2);
  End;
  SHP_LINE: Begin
   SetColor(P^.LineColor);
   Line(X1, Y1, X2, Y2);
  End;
  SHP_ARROW: Begin
   SetColor(P^.LineColor);
   Line(X1, Y1, X2, Y2);
   Line(X2, Y2, X2 - 8, Y2 - 4);
   Line(X2, Y2, X2 - 8, Y2 + 4);
  End;
  SHP_TRIANGLE:  DrawTriangleShape(X1, Y1, X2, Y2, P^.FillColor, P^.LineColor);
  SHP_DIAMOND:   DrawDiamondShape (X1, Y1, X2, Y2, P^.FillColor, P^.LineColor);
  SHP_STAR:      DrawStarShape    (X1, Y1, X2, Y2, P^.FillColor, P^.LineColor);
  SHP_TITLE,
  SHP_SUBTITLE,
  SHP_TEXT,
  SHP_CONTENT: Begin
   If P^.Filled Then Begin
    SetFillStyle(1, P^.FillColor); Bar(X1, Y1, X2, Y2);
   End;
   DrawShapeTextLines(P, X1, Y1, X2, Y2);
   { Bord en pointille pour les placeholders sans contenu defini }
   If (P^.LineWidth = 0) And EditMode And (CurShape = 0) Then Begin
    SetColor(CLR_DGRAY);
    Rectangle(X1, Y1, X2, Y2);
   End;
  End;
  SHP_IMAGE: Begin
   If (P^.ImageIdx >= 1) And (P^.ImageIdx <= MAX_IMAGES) And
      (Pres.Images[P^.ImageIdx] <> Nil) And
      Pres.Images[P^.ImageIdx]^.Loaded Then Begin
    DrawImageScaled(Pres.Images[P^.ImageIdx], X1, Y1, X2, Y2);
    SetColor(CLR_DGRAY); Rectangle(X1, Y1, X2, Y2);
   End Else Begin
    FillBox(X1, Y1, X2, Y2, CLR_LGRAY);
    SetColor(CLR_DGRAY); Rectangle(X1, Y1, X2, Y2);
    Line(X1, Y1, X2, Y2); Line(X1, Y2, X2, Y1);
    SetColor(CLR_BLACK);
    If (P^.TxtCount >= 1) And (P^.Text[1] <> '') Then
     OutTextXY(X1 + 4, Y1 + 4, '[' + P^.Text[1] + ']')
    Else
     OutTextXY(X1 + 4, Y1 + 4, '[Image]');
   End;
  End;
  SHP_TABLE: Begin
   FillBox(X1, Y1, X2, Y2, CLR_WHITE);
   SetColor(CLR_DGRAY); Rectangle(X1, Y1, X2, Y2);
  End;
  SHP_CHART: Begin
   FillBox(X1, Y1, X2, Y2, CLR_WHITE);
   SetColor(CLR_DGRAY); Rectangle(X1, Y1, X2, Y2);
   SetColor(CLR_BLUE);
   Bar(X1 + 10, Y2 - 30, X1 + 30, Y2 - 4);
   SetFillStyle(1, CLR_LGREEN); Bar(X1 + 35, Y2 - 60, X1 + 55, Y2 - 4);
   SetFillStyle(1, CLR_LRED);   Bar(X1 + 60, Y2 - 45, X1 + 80, Y2 - 4);
  End;
 Else
  { Forme inconnue : rectangle simple }
  SetColor(P^.LineColor); Rectangle(X1, Y1, X2, Y2);
 End;
End;

Procedure DrawSelectionHandles(P: PShape);
Var X1, Y1, X2, Y2, Cx, Cy: Integer;
Begin
 If P = Nil Then Exit;
 X1 := LogX(P^.X);
 Y1 := LogY(P^.Y);
 X2 := LogX(P^.X + P^.W);
 Y2 := LogY(P^.Y + P^.H);
 Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
 SetColor(CLR_BLUE);
 Rectangle(X1 - 1, Y1 - 1, X2 + 1, Y2 + 1);
 FillBox(X1 - 3, Y1 - 3, X1 + 1, Y1 + 1, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(X1 - 3, Y1 - 3, X1 + 1, Y1 + 1);
 FillBox(X2 - 1, Y1 - 3, X2 + 3, Y1 + 1, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(X2 - 1, Y1 - 3, X2 + 3, Y1 + 1);
 FillBox(X1 - 3, Y2 - 1, X1 + 1, Y2 + 3, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(X1 - 3, Y2 - 1, X1 + 1, Y2 + 3);
 FillBox(X2 - 1, Y2 - 1, X2 + 3, Y2 + 3, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(X2 - 1, Y2 - 1, X2 + 3, Y2 + 3);
 FillBox(Cx - 2, Y1 - 3, Cx + 2, Y1 + 1, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(Cx - 2, Y1 - 3, Cx + 2, Y1 + 1);
 FillBox(Cx - 2, Y2 - 1, Cx + 2, Y2 + 3, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(Cx - 2, Y2 - 1, Cx + 2, Y2 + 3);
 FillBox(X1 - 3, Cy - 2, X1 + 1, Cy + 2, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(X1 - 3, Cy - 2, X1 + 1, Cy + 2);
 FillBox(X2 - 1, Cy - 2, X2 + 3, Cy + 2, CLR_WHITE);
 SetColor(CLR_BLUE); Rectangle(X2 - 1, Cy - 2, X2 + 3, Cy + 2);
End;

{ ====================================================================== }
{                       PANNEAU MINIATURES                               }
{ ====================================================================== }

Const
 THUMB_H_TOTAL = 60;     { hauteur d'une miniature + marge }
 THUMB_PAD     = 6;

Procedure DrawSlideThumb(Idx, Y: Integer);
Var X1, X2, Y1, Y2, Tw, I: Integer; S: PSlide; Sh: PShape;
    SX1, SY1, SX2, SY2: Integer; Title: String;
Begin
 If (Idx < 1) Or (Idx > Pres.SldCount) Then Exit;
 S := Pres.Slides[Idx];
 X1 := 8;          X2 := PANEL_W - 8;
 Y1 := Y;          Y2 := Y + THUMB_H_TOTAL - THUMB_PAD;
 { Numero }
 SetColor(CLR_WHITE);
 OutTextXY(2, Y1 + 14, IntToStr(Idx));
 { Cadre miniature }
 If Idx = CurSlide Then Begin
  FillBox(X1 - 2, Y1 - 2, X2 + 2, Y2 + 2, CLR_PANEL_SEL);
 End;
 FillBox(X1, Y1, X2, Y2, S^.Background);
 SetColor(CLR_BLACK); Rectangle(X1, Y1, X2, Y2);
 { Apercu simplifie : rectangles colores selon les formes }
 For I := 1 To S^.ShCount Do Begin
  Sh := S^.Shapes[I];
  If Sh = Nil Then Continue;
  SX1 := X1 + ((Sh^.X) * (X2 - X1)) Div 1000;
  SY1 := Y1 + ((Sh^.Y) * (Y2 - Y1)) Div 750;
  SX2 := X1 + ((Sh^.X + Sh^.W) * (X2 - X1)) Div 1000;
  SY2 := Y1 + ((Sh^.Y + Sh^.H) * (Y2 - Y1)) Div 750;
  If SX2 > X2 Then SX2 := X2;
  If SY2 > Y2 Then SY2 := Y2;
  If SX1 < X1 Then SX1 := X1;
  If SY1 < Y1 Then SY1 := Y1;
  Case Sh^.ShType Of
   SHP_TITLE, SHP_SUBTITLE: Begin
    SetColor(CLR_BLUE);
    Line(SX1, (SY1 + SY2) Div 2, SX2, (SY1 + SY2) Div 2);
   End;
   SHP_CONTENT, SHP_TEXT: Begin
    SetColor(CLR_DGRAY);
    Line(SX1, SY1 + 2, SX2 - 4, SY1 + 2);
    Line(SX1, SY1 + 6, SX2 - 4, SY1 + 6);
    Line(SX1, SY1 + 10, SX2 - 8, SY1 + 10);
   End;
   SHP_ELLIPSE: Begin
    SetFillStyle(1, Sh^.FillColor);
    FillEllipse((SX1 + SX2) Div 2, (SY1 + SY2) Div 2,
                MaxI(2,(SX2 - SX1) Div 2), MaxI(2,(SY2 - SY1) Div 2));
   End;
   SHP_STAR, SHP_TRIANGLE, SHP_DIAMOND: Begin
    SetFillStyle(1, Sh^.FillColor); Bar(SX1, SY1, SX2, SY2);
   End;
  Else
   If Sh^.Filled Then Begin
    SetFillStyle(1, Sh^.FillColor); Bar(SX1, SY1, SX2, SY2);
   End;
  End;
 End;
 { Titre raccourci }
 Title := S^.Title;
 If Title = '' Then
  If (S^.ShCount > 0) And (S^.Shapes[1] <> Nil) And
     (S^.Shapes[1]^.ShType In [SHP_TITLE, SHP_SUBTITLE, SHP_TEXT]) Then
   Title := S^.Shapes[1]^.Text[1];
 If Length(Title) > 14 Then Title := Copy(Title, 1, 14);
 SetColor(CLR_WHITE);
 Tw := TextWidth(Title);
 If Tw > X2 - X1 - 4 Then Tw := X2 - X1 - 4;
 OutTextXY(X1 + ((X2 - X1) - Tw) Div 2, Y2 + 2, Title);
End;

Procedure DrawSlidePanel;
Var I, Y, Top, Bottom: Integer;
Begin
 AppHideMouse;
 Top    := MENU_H + TOOL_H;
 Bottom := SCREEN_H - STATUS_H;
 FillBox(0, Top, PANEL_W - 1, Bottom - 1, CLR_PANEL_BG);
 VLine(PANEL_W - 1, Top, Bottom - 1, CLR_WIN_LO);
 Y := Top + 10 - PanelScroll;
 For I := 1 To Pres.SldCount Do Begin
  If (Y + THUMB_H_TOTAL > Top) And (Y < Bottom) Then
   DrawSlideThumb(I, Y);
  Y := Y + THUMB_H_TOTAL;
 End;
 AppShowMouse;
End;

Function SlideAtPanelY(Y: LongInt): Integer;
Var I, Yy, Top: Integer;
Begin
 SlideAtPanelY := 0;
 Top := MENU_H + TOOL_H;
 Yy  := Top + 10 - PanelScroll;
 For I := 1 To Pres.SldCount Do Begin
  If (Y >= Yy) And (Y < Yy + THUMB_H_TOTAL - THUMB_PAD) Then Begin
   SlideAtPanelY := I; Exit;
  End;
  Yy := Yy + THUMB_H_TOTAL;
 End;
End;

{ ====================================================================== }
{                       REGLE                                            }
{ ====================================================================== }

Procedure DrawRuler;
Var X, Y, Tk, X1, X2: Integer;
Begin
 Y  := MENU_H + TOOL_H;
 X1 := PANEL_W;
 X2 := SCREEN_W - 1;
 FillBox(X1, Y, X2, Y + RULER_H - 1, CLR_WIN_BG);
 HLine(X1, X2, Y + RULER_H - 1, CLR_WIN_LO);
 SetColor(CLR_BLACK);
 For Tk := 0 To 20 Do Begin
  X := X1 + 4 + (Tk * (X2 - X1 - 8)) Div 20;
  If (Tk Mod 5) = 0 Then Line(X, Y + 4, X, Y + RULER_H - 3)
  Else Line(X, Y + 8, X, Y + RULER_H - 3);
 End;
End;

{ ====================================================================== }
{                       ZONE PRINCIPALE                                  }
{ ====================================================================== }

Procedure DrawMasterOverlay(SlideIdx: Integer; X1, Y1, X2, Y2: Integer); Forward;

{ Dessine une miniature de diapositive a une position et taille arbitraires.
  Utilise par la trieuse de diapositives (Phase 5). }
Procedure DrawSlideThumbAt(Idx, X1, Y1, X2, Y2: Integer; Selected: Boolean);
Var I, SX1, SY1, SX2, SY2: Integer; S: PSlide; Sh: PShape;
    Title: String; Tw: Integer;
Begin
 If (Idx < 1) Or (Idx > Pres.SldCount) Then Exit;
 S := Pres.Slides[Idx];
 If Selected Then Begin
  FillBox(X1 - 3, Y1 - 3, X2 + 3, Y2 + 3, CLR_PANEL_SEL);
 End;
 FillBox(X1, Y1, X2, Y2, S^.Background);
 SetColor(CLR_BLACK); Rectangle(X1, Y1, X2, Y2);
 For I := 1 To S^.ShCount Do Begin
  Sh := S^.Shapes[I]; If Sh = Nil Then Continue;
  SX1 := X1 + ((Sh^.X) * (X2 - X1)) Div 1000;
  SY1 := Y1 + ((Sh^.Y) * (Y2 - Y1)) Div 750;
  SX2 := X1 + ((Sh^.X + Sh^.W) * (X2 - X1)) Div 1000;
  SY2 := Y1 + ((Sh^.Y + Sh^.H) * (Y2 - Y1)) Div 750;
  If SX2 > X2 Then SX2 := X2;  If SY2 > Y2 Then SY2 := Y2;
  If SX1 < X1 Then SX1 := X1;  If SY1 < Y1 Then SY1 := Y1;
  Case Sh^.ShType Of
   SHP_TITLE, SHP_SUBTITLE: Begin
    SetColor(CLR_BLUE);
    Line(SX1, (SY1 + SY2) Div 2, SX2, (SY1 + SY2) Div 2);
   End;
   SHP_CONTENT, SHP_TEXT: Begin
    SetColor(CLR_DGRAY);
    Line(SX1, SY1 + 3, SX2 - 4, SY1 + 3);
    Line(SX1, SY1 + 8, SX2 - 4, SY1 + 8);
    Line(SX1, SY1 + 13, SX2 - 8, SY1 + 13);
   End;
   SHP_ELLIPSE: Begin
    SetFillStyle(1, Sh^.FillColor);
    FillEllipse((SX1 + SX2) Div 2, (SY1 + SY2) Div 2,
                MaxI(2, (SX2 - SX1) Div 2), MaxI(2, (SY2 - SY1) Div 2));
   End;
   SHP_STAR, SHP_TRIANGLE, SHP_DIAMOND: Begin
    SetFillStyle(1, Sh^.FillColor); Bar(SX1, SY1, SX2, SY2);
   End;
  Else
   If Sh^.Filled Then Begin
    SetFillStyle(1, Sh^.FillColor); Bar(SX1, SY1, SX2, SY2);
   End;
  End;
 End;
 If S^.Hidden Then Begin
  SetColor(CLR_LRED);
  Line(X1, Y1, X2, Y2); Line(X1, Y2, X2, Y1);
 End;
 { Numero + titre au bas }
 SetColor(CLR_BLACK);
 OutTextXY(X1, Y2 + 2, IntToStr(Idx) + '.');
 Title := S^.Title;
 If Title = '' Then
  If (S^.ShCount > 0) And (S^.Shapes[1] <> Nil) And
     (S^.Shapes[1]^.ShType In [SHP_TITLE, SHP_SUBTITLE, SHP_TEXT]) Then
   Title := S^.Shapes[1]^.Text[1];
 If Length(Title) > 18 Then Title := Copy(Title, 1, 18);
 Tw := TextWidth(Title);
 If Tw > X2 - X1 - 20 Then Tw := X2 - X1 - 20;
 OutTextXY(X1 + 20, Y2 + 2, Title);
End;

{ ---------- TRIEUSE DE DIAPOSITIVES (VIEW_SORTER) ---------- }

Const
 SORT_COLS    = 4;
 SORT_THUMB_W = 130;
 SORT_THUMB_H = 90;
 SORT_GAP_X   = 16;
 SORT_GAP_Y   = 28;
 SORT_PAD_TOP = 16;

Function SorterCellRect(Idx: Integer; Var X1, Y1, X2, Y2: Integer): Boolean;
Var Col, Row, AreaTop, AreaLeft: Integer;
Begin
 SorterCellRect := False;
 If (Idx < 1) Or (Idx > Pres.SldCount) Then Exit;
 AreaTop  := MENU_H + TOOL_H + RULER_H;
 AreaLeft := PANEL_W;
 Col := (Idx - 1) Mod SORT_COLS;
 Row := (Idx - 1) Div SORT_COLS;
 X1 := AreaLeft + SORT_GAP_X + Col * (SORT_THUMB_W + SORT_GAP_X);
 Y1 := AreaTop  + SORT_PAD_TOP - SorterScroll + Row * (SORT_THUMB_H + SORT_GAP_Y);
 X2 := X1 + SORT_THUMB_W;
 Y2 := Y1 + SORT_THUMB_H;
 SorterCellRect := True;
End;

Function SorterAt(Mx, My: LongInt): Integer;
Var I, X1, Y1, X2, Y2: Integer;
Begin
 SorterAt := 0;
 For I := 1 To Pres.SldCount Do
  If SorterCellRect(I, X1, Y1, X2, Y2) Then
   If (Mx >= X1 - 3) And (Mx <= X2 + 3) And
      (My >= Y1 - 3) And (My <= Y2 + 3) Then Begin
    SorterAt := I; Exit;
   End;
End;

Procedure DrawSorterView;
Var I, X1, Y1, X2, Y2, Top, Bottom, Left, Right: Integer;
Begin
 Top    := MENU_H + TOOL_H + RULER_H;
 Bottom := SCREEN_H - STATUS_H;
 Left   := PANEL_W;
 Right  := SCREEN_W - 1;
 FillBox(Left, Top, Right, Bottom - 1, CLR_WORK_BG);
 If SorterSel < 1 Then SorterSel := CurSlide;
 If SorterSel > Pres.SldCount Then SorterSel := Pres.SldCount;
 If SorterSel < 1 Then SorterSel := 0;
 For I := 1 To Pres.SldCount Do Begin
  If Not SorterCellRect(I, X1, Y1, X2, Y2) Then Continue;
  If (Y2 < Top) Or (Y1 > Bottom) Then Continue;
  DrawSlideThumbAt(I, X1, Y1, X2, Y2, I = SorterSel);
 End;
 { En-tete titre }
 SetColor(CLR_BLACK);
 OutTextXY(Left + 8, Top + 2,
   'Trieuse de diapositives - ' + IntToStr(Pres.SldCount) + ' diapositive(s)');
End;

{ ---------- MODE PLAN (VIEW_OUTLINE) ---------- }

Const
 OUTLINE_LINE_H = 12;

Type
 TOutlineLines = Array[0..63] Of String;
 TOutlineLevs  = Array[0..63] Of Byte;
   { 255 = titre, 0..7 = niveau de puce/indentation }

Procedure CollectSlideOutline(S: PSlide; Var Lines: TOutlineLines;
                              Var Levels: TOutlineLevs; Var Count: Integer);
Var I, J: Integer; Sh: PShape;
Begin
 If S = Nil Then Exit;
 For I := 1 To S^.ShCount Do Begin
  Sh := S^.Shapes[I];
  If (Sh <> Nil) And (Sh^.ShType = SHP_TITLE) Then Begin
   If Count >= 64 Then Exit;
   Lines[Count]  := Sh^.Text[1];
   Levels[Count] := 255;
   Inc(Count); Break;
  End;
 End;
 For I := 1 To S^.ShCount Do Begin
  Sh := S^.Shapes[I];
  If Sh = Nil Then Continue;
  If Sh^.ShType In [SHP_CONTENT, SHP_SUBTITLE, SHP_TEXT] Then
   For J := 1 To Sh^.TxtCount Do Begin
    If Count >= 64 Then Exit;
    Lines[Count]  := Sh^.Text[J];
    Levels[Count] := Sh^.Indent[J];
    Inc(Count);
   End;
 End;
End;

Procedure DrawOutlineView;
Var Top, Bottom, Left, Right, Y, I, J, Cnt: Integer;
    Lines: TOutlineLines; Levels: TOutlineLevs;
    LineY, Indent: Integer;
Begin
 Top    := MENU_H + TOOL_H + RULER_H;
 Bottom := SCREEN_H - STATUS_H;
 Left   := PANEL_W;
 Right  := SCREEN_W - 1;
 FillBox(Left, Top, Right, Bottom - 1, CLR_WHITE);
 SetColor(CLR_DGRAY); Rectangle(Left + 4, Top + 4, Right - 4, Bottom - 4);
 Y := Top + 10 - OutlineScroll;
 For I := 1 To Pres.SldCount Do Begin
  LineY := Y;
  If (LineY >= Top) And (LineY < Bottom) Then Begin
   If I = OutlineSel Then Begin
    FillBox(Left + 6, LineY - 1, Right - 6, LineY + 12, CLR_PANEL_SEL);
    SetColor(CLR_WHITE);
   End Else
    SetColor(CLR_BLUE);
   OutTextXY(Left + 12, LineY + 1,
     IntToStr(I) + '. ' + Pres.Slides[I]^.Name);
  End;
  Y := Y + OUTLINE_LINE_H + 2;
  Cnt := 0;
  CollectSlideOutline(Pres.Slides[I], Lines, Levels, Cnt);
  For J := 0 To Cnt - 1 Do Begin
   LineY := Y;
   If (LineY + OUTLINE_LINE_H >= Top) And (LineY < Bottom) Then Begin
    If Levels[J] = 255 Then Begin
     SetColor(CLR_BLACK);
     OutTextXY(Left + 24, LineY, Lines[J]);
    End Else Begin
     Indent := Levels[J]; If Indent > 6 Then Indent := 6;
     SetColor(CLR_BLACK);
     OutTextXY(Left + 24 + (Indent + 1) * 12, LineY,
       #250 + ' ' + Lines[J]);
    End;
   End;
   Y := Y + OUTLINE_LINE_H;
   If Y > Bottom Then Break;
  End;
  Y := Y + 6;
  If Y > Bottom Then Break;
 End;
End;

Function OutlineSlideAtY(My: LongInt): Integer;
Var Top, Y, I, Cnt, Block: Integer;
    Lines: TOutlineLines; Levels: TOutlineLevs;
Begin
 OutlineSlideAtY := 0;
 Top := MENU_H + TOOL_H + RULER_H;
 Y := Top + 10 - OutlineScroll;
 For I := 1 To Pres.SldCount Do Begin
  Cnt := 0;
  CollectSlideOutline(Pres.Slides[I], Lines, Levels, Cnt);
  Block := OUTLINE_LINE_H + 2 + Cnt * OUTLINE_LINE_H + 6;
  If (My >= Y) And (My < Y + Block) Then Begin
   OutlineSlideAtY := I; Exit;
  End;
  Y := Y + Block;
 End;
End;

{ ---------- PAGE DE COMMENTAIRES (VIEW_NOTES) ---------- }

Procedure DrawNotesView;
Var Top, Bottom, Left, Right, MidY, I: Integer; S: PSlide;
    PrevX1, PrevY1, PrevX2, PrevY2: Integer;
    Notes: String; LineW, Pos, Cur: Integer; Word, Line: String;
Begin
 Top    := MENU_H + TOOL_H + RULER_H;
 Bottom := SCREEN_H - STATUS_H;
 Left   := PANEL_W;
 Right  := SCREEN_W - 1;
 FillBox(Left, Top, Right, Bottom - 1, CLR_WORK_BG);
 MidY := Top + (Bottom - Top) Div 2;
 { Apercu de slide en haut }
 PrevX1 := Left + 80; PrevX2 := Right - 80;
 PrevY1 := Top + 10;  PrevY2 := MidY - 10;
 If (CurSlide >= 1) And (CurSlide <= Pres.SldCount) Then Begin
  S := Pres.Slides[CurSlide];
  FillBox(PrevX1 + 3, PrevY1 + 3, PrevX2 + 3, PrevY2 + 3, CLR_BLACK);
  FillBox(PrevX1, PrevY1, PrevX2, PrevY2, S^.Background);
  SetColor(CLR_SLIDE_BORD); Rectangle(PrevX1, PrevY1, PrevX2, PrevY2);
  DrawSlideThumbAt(CurSlide, PrevX1, PrevY1, PrevX2, PrevY2, False);
 End Else Begin
  SetColor(CLR_DGRAY);
  OutTextXY(PrevX1 + 8, PrevY1 + 8, '(Aucune diapositive)');
 End;
 { Cadre notes en bas }
 FillBox(Left + 20, MidY + 4, Right - 20, Bottom - 8, CLR_WHITE);
 SetColor(CLR_WIN_LO); Rectangle(Left + 20, MidY + 4, Right - 20, Bottom - 8);
 SetColor(CLR_BLACK);
 OutTextXY(Left + 24, MidY + 8, 'Notes du presentateur :');
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 Notes := Pres.Slides[CurSlide]^.Notes;
 If Notes = '' Then Begin
  SetColor(CLR_DGRAY);
  OutTextXY(Left + 28, MidY + 28,
    '(Double-cliquez ou appuyez sur Entree pour modifier...)');
  Exit;
 End;
 { Wrap simple par mot }
 LineW := Right - 20 - (Left + 28);
 Cur   := MidY + 28;
 Line  := '';
 Pos   := 1;
 SetColor(CLR_BLACK);
 While Pos <= Length(Notes) Do Begin
  Word := '';
  While (Pos <= Length(Notes)) And (Notes[Pos] <> ' ') Do Begin
   Word := Word + Notes[Pos]; Inc(Pos);
  End;
  If TextWidth(Line + Word) > LineW Then Begin
   OutTextXY(Left + 28, Cur, Line);
   Cur := Cur + 11;
   If Cur > Bottom - 16 Then Exit;
   Line := Word;
  End Else
   If Line = '' Then Line := Word Else Line := Line + ' ' + Word;
  If Pos <= Length(Notes) Then Inc(Pos); { saute espace }
 End;
 If Line <> '' Then OutTextXY(Left + 28, Cur, Line);
 I := 0; { evite warning }
End;

Procedure DrawNormalView;
Var I, Top, Bottom, Left, Right: Integer; S: PSlide;
Begin
 Top    := MENU_H + TOOL_H + RULER_H;
 Bottom := SCREEN_H - STATUS_H;
 Left   := PANEL_W;
 Right  := SCREEN_W - 1;
 FillBox(Left, Top, Right, Bottom - 1, CLR_WORK_BG);
 ComputeLayout;
 FillBox(SlideX1 + 4, SlideY1 + 4, SlideX2 + 4, SlideY2 + 4, CLR_BLACK);
 If (CurSlide >= 1) And (CurSlide <= Pres.SldCount) Then
  S := Pres.Slides[CurSlide]
 Else S := Nil;
 If S <> Nil Then Begin
  FillBox(SlideX1, SlideY1, SlideX2, SlideY2, S^.Background);
  SetColor(CLR_SLIDE_BORD); Rectangle(SlideX1, SlideY1, SlideX2, SlideY2);
  For I := 1 To S^.ShCount Do DrawShape(S^.Shapes[I]);
  If (CurShape >= 1) And (CurShape <= S^.ShCount) Then
   DrawSelectionHandles(S^.Shapes[CurShape]);
  DrawMasterOverlay(CurSlide, SlideX1, SlideY1, SlideX2, SlideY2);
 End
 Else Begin
  FillBox(SlideX1, SlideY1, SlideX2, SlideY2, CLR_WHITE);
  SetColor(CLR_DGRAY); Rectangle(SlideX1, SlideY1, SlideX2, SlideY2);
  SetColor(CLR_DGRAY);
  OutTextXY(SlideX1 + 20, SlideY1 + 20, '(Aucune diapositive)');
 End;
End;

Procedure DrawMainArea;
Begin
 AppHideMouse;
 Case CurView Of
  VIEW_OUTLINE: DrawOutlineView;
  VIEW_SORTER:  DrawSorterView;
  VIEW_NOTES:   DrawNotesView;
 Else
  DrawNormalView;
 End;
 AppShowMouse;
End;

{ ====================================================================== }
{                       BARRE D'ETAT                                     }
{ ====================================================================== }

Procedure DrawStatusBar;
Var Y, X: Integer; S: String;
Begin
 AppHideMouse;
 Y := SCREEN_H - STATUS_H;
 FillBox(0, Y, SCREEN_W - 1, SCREEN_H - 1, CLR_STATUS_BG);
 HLine(0, SCREEN_W - 1, Y, CLR_WIN_HI);
 SetColor(CLR_STATUS_FG);
 OutTextXY(4, Y + 4, StatusMsg);
 { Bloc droit : "Diapositive X sur Y" et nom du theme/zoom }
 X := SCREEN_W - 320;
 SetColor(CLR_DGRAY); VLine(X - 2, Y + 2, SCREEN_H - 3, CLR_DGRAY);
 SetColor(CLR_BLACK);
 If Pres.SldCount > 0 Then
  S := 'Diapositive ' + IntToStr(CurSlide) + ' sur ' + IntToStr(Pres.SldCount)
 Else
  S := 'Aucune diapositive';
 OutTextXY(X + 4, Y + 4, S);
 X := SCREEN_W - 160;
 VLine(X - 2, Y + 2, SCREEN_H - 3, CLR_DGRAY);
 OutTextXY(X + 4, Y + 4, 'Theme : ' + Pres.Themes[Pres.ThemeIdx].Name);
 X := SCREEN_W - 60;
 VLine(X - 2, Y + 2, SCREEN_H - 3, CLR_DGRAY);
 OutTextXY(X + 4, Y + 4, IntToStr(SlideScale) + '%');
 AppShowMouse;
End;

{ ====================================================================== }
{                       REDRAW                                           }
{ ====================================================================== }

Procedure RedrawWork;
Begin
 If NeedFullRedraw Or NeedSlideRedraw Then Begin
  If TextCaretDrawn Then ToggleTextCaret;
  TextCaretKnown:=False;
 End;
 If NeedFullRedraw Then Begin
  DrawMenuBar;
  UpdateToolToggles;
  If RibbonMode Then DrawRibbon Else DrawToolBar;
  DrawRuler;
  DrawSlidePanel;
  DrawMainArea;
  DrawStatusBar;
  If MenuOpen <> 0 Then DrawDropDown;
  NeedFullRedraw  := False;
  NeedChromeRedraw:=False;
  NeedSlideRedraw := False;
  NeedPanelRedraw := False;
  NeedStatRedraw  := False;
  Exit;
 End;
 If NeedChromeRedraw Then Begin
  DrawMenuBar;UpdateToolToggles;
  If RibbonMode Then DrawRibbon Else DrawToolBar;
  NeedChromeRedraw:=False;
 End;
 If NeedSlideRedraw Then Begin DrawMainArea; NeedSlideRedraw := False; End;
 If NeedPanelRedraw Then Begin DrawSlidePanel; NeedPanelRedraw := False; End;
 If NeedStatRedraw  Then Begin DrawStatusBar;  NeedStatRedraw  := False; End;
End;

Procedure Redraw;
Begin
 If Not (NeedFullRedraw Or NeedSlideRedraw Or NeedPanelRedraw Or
         NeedStatRedraw Or NeedChromeRedraw) Then Exit;
 BeginPaint;
 RedrawWork;
 EndPaint;
End;

{ ====================================================================== }
{                       ACTIONS                                          }
{ ====================================================================== }

Function ConfirmDiscardChanges: Boolean;
Begin
 If Pres.Dirty Then
  ConfirmDiscardChanges := ConfirmYesNo('PresentPoint',
   'Modifications non enregistrees. Continuer ?')
 Else ConfirmDiscardChanges := True;
End;

Procedure ActionQuit;
Begin
 If Not ConfirmDiscardChanges Then Exit;
 Quitting := True;
End;

Procedure ActionNew;
Var Pos: Integer;
Begin
 If Not ConfirmDiscardChanges Then Exit;
 FreePresentation;
 InitPresentation;
 { Phase 12 fix : "Nouveau" doit creer une presentation VIDE (une seule
   diapo de titre blanche), pas re-injecter l'exemple de 4 pages. }
 Pos := AddSlideAt(1);
 If Pos > 0 Then ApplyLayout(Pres.Slides[Pos], LAY_TITLE_ONLY);
 CurSlide := 1;
 CurShape := 0;
 Pres.Dirty := False;
 StatusMsg := 'Nouvelle presentation.';
 NeedFullRedraw := True;
End;

Procedure ActionNewSlide;
Var Pos: Integer;
Begin
 If CurSlide < 1 Then Pos := AddSlideAt(1)
 Else Pos := AddSlideAt(CurSlide + 1);
 If Pos > 0 Then Begin
  ApplyLayout(Pres.Slides[Pos], LAY_TITLE_CONTENT);
  CurSlide := Pos;
  CurShape := 0;
  StatusMsg := 'Diapositive ' + IntToStr(Pos) + ' ajoutee.';
  NeedFullRedraw := True;
 End
 Else MessageBox('PresentPoint', 'Nombre maximum de diapositives atteint.');
End;

Procedure ActionDupSlide;
Var Pos, I: Integer; Src, Dst: PSlide; SH: PShape;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 Pos := AddSlideAt(CurSlide + 1);
 If Pos = 0 Then Begin
  MessageBox('PresentPoint', 'Nombre maximum de diapositives atteint.'); Exit;
 End;
 Src := Pres.Slides[CurSlide];
 Dst := Pres.Slides[Pos];
 Dst^.Title      := Src^.Title;
 Dst^.Layout     := Src^.Layout;
 Dst^.Background := Src^.Background;
 Dst^.Theme      := Src^.Theme;
 Dst^.Transition := Src^.Transition;
 For I := 1 To Src^.ShCount Do Begin
  SH := NewShape;
  SH^ := Src^.Shapes[I]^;
  AddShapeToSlide(Dst, SH);
 End;
 CurSlide := Pos;
 CurShape := 0;
 StatusMsg := 'Diapositive dupliquee.';
 NeedFullRedraw := True;
End;

Procedure ActionDelSlide;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 If Not ConfirmYesNo('PresentPoint',
  'Supprimer la diapositive ' + IntToStr(CurSlide) + ' ?') Then Exit;
 RemoveSlide(CurSlide);
 CurShape := 0;
 StatusMsg := 'Diapositive supprimee.';
 NeedFullRedraw := True;
End;

Procedure ActionNextSlide;
Begin
 If CurSlide < Pres.SldCount Then Begin
  Inc(CurSlide); CurShape := 0; NeedFullRedraw := True;
 End;
End;

Procedure ActionPrevSlide;
Begin
 If CurSlide > 1 Then Begin
  Dec(CurSlide); CurShape := 0; NeedFullRedraw := True;
 End;
End;

Procedure ActionFirstSlide;
Begin
 If Pres.SldCount > 0 Then Begin
  CurSlide := 1; CurShape := 0; NeedFullRedraw := True;
 End;
End;

Procedure ActionLastSlide;
Begin
 If Pres.SldCount > 0 Then Begin
  CurSlide := Pres.SldCount; CurShape := 0; NeedFullRedraw := True;
 End;
End;

Procedure ActionAbout;
Var X1, Y1, X2, Y2: Integer; K: Char;
Begin
 X1 := 130; Y1 := 110; X2 := 510; Y2 := 370;
 DlgFrame(X1, Y1, X2, Y2, 'A propos de Office-0 PresentPoint');
 AppHideMouse;
 SetColor(CLR_BLACK);
 SetTextStyle(DefaultFont, HorizDir, 2);
 OutTextXY(X1 + 20, Y1 + 30, 'Office-0  PresentPoint');
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetColor(CLR_BLUE);
 OutTextXY(X1 + 20, Y1 + 60, 'Clone de Microsoft PowerPoint');
 SetColor(CLR_BLACK);
 OutTextXY(X1 + 20, Y1 + 80, 'Version 1.0 - 2026 (Phase 12 finale)');
 OutTextXY(X1 + 20, Y1 + 96, '(c) Sylvain Maltais  www.gladir.com');
 SetColor(CLR_DGRAY);
 OutTextXY(X1 + 20, Y1 + 120,'Clone complet : 12 phases livrees');
 OutTextXY(X1 + 20, Y1 + 136,'Formats : .PPT natif, .PPTX, .BMP, .PCX, .PRN');
 OutTextXY(X1 + 20, Y1 + 152,'Free Pascal 3.2 (-Mtp) - VGA 640 x 480 x 16');
 OutTextXY(X1 + 20, Y1 + 176,'F5 Diaporama  Ctrl+P Imprimer  Ctrl+E Exporter');
 OutTextXY(X1 + 20, Y1 + 192,'Ctrl+M Nouvelle slide  Ctrl+S Enregistrer');
 DlgBtn(X1 + 160, Y2 - 32, X1 + 220, Y2 - 12, 'OK', False, True);
 AppShowMouse;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then ReadKey;
   If (K = #13) Or (K = #27) Or (K = ' ') Then Begin
    NeedFullRedraw := True; Exit;
   End;
  End;
  If LeftPressed Then
   If InRect(Mouse.X, Mouse.Y, X1 + 160, Y2 - 32, X1 + 220, Y2 - 12) Then Begin
    NeedFullRedraw := True; Exit;
   End;
 Until False;
End;

Procedure SetTool(T: Integer);
Begin
 CurTool := T;
 Case T Of
  TOOL_SELECT:   StatusMsg := 'Outil : Selection';
  TOOL_TEXT:     StatusMsg := 'Outil : Zone de texte';
  TOOL_RECT:     StatusMsg := 'Outil : Rectangle';
  TOOL_ELLIPSE:  StatusMsg := 'Outil : Ellipse';
  TOOL_LINE:     StatusMsg := 'Outil : Ligne';
  TOOL_ARROW:    StatusMsg := 'Outil : Fleche';
 Else StatusMsg := 'Outil change.';
 End;
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{           PHASE 4 - DIALOGUES REUTILISABLES + GESTION SLIDES           }
{ ====================================================================== }

{ Saisie de texte modal. Retourne True si OK valide, False si Annuler. }
Function InputTextDlg(Const Title, Prompt: String;
                      Var Value: String; MaxLen: Integer): Boolean;
{ boite de dialogue de PM : champ de saisie, boutons OK et Annuler }
Begin
 InputTextDlg := PmInput(Title, Prompt, Value, MaxLen);
 NeedFullRedraw := True;
End;

{ Selection dans une liste deroulante. Items separes par #10. Retourne
  l'index 1..N choisi, ou 0 si annule. }
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

Function SelectListDlg(Const Title: String; Const Items: String;
                       InitialIdx: Integer): Integer;
{ boite de liste de PM ; 0 : annulee }
Begin
 SelectListDlg := PmListDlg(Title, Items, InitialIdx);
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{           PHASE 4 - OPERATIONS SUR LES DIAPOSITIVES                    }
{ ====================================================================== }

Procedure ClearSlideShapes(S: PSlide);
Var I: Integer;
Begin
 If S = Nil Then Exit;
 For I := 1 To S^.ShCount Do
  If S^.Shapes[I] <> Nil Then FreeShape(S^.Shapes[I]);
 For I := 1 To MAX_SHAPES Do S^.Shapes[I] := Nil;
 S^.ShCount := 0;
End;

Procedure ActionMoveSlideUp;
Var Tmp: PSlide;
Begin
 If (CurSlide <= 1) Or (CurSlide > Pres.SldCount) Then Exit;
 Tmp := Pres.Slides[CurSlide - 1];
 Pres.Slides[CurSlide - 1] := Pres.Slides[CurSlide];
 Pres.Slides[CurSlide] := Tmp;
 Dec(CurSlide);
 Pres.Dirty := True;
 StatusMsg := 'Diapositive remontee.';
 NeedFullRedraw := True;
End;

Procedure ActionMoveSlideDown;
Var Tmp: PSlide;
Begin
 If (CurSlide < 1) Or (CurSlide >= Pres.SldCount) Then Exit;
 Tmp := Pres.Slides[CurSlide + 1];
 Pres.Slides[CurSlide + 1] := Pres.Slides[CurSlide];
 Pres.Slides[CurSlide] := Tmp;
 Inc(CurSlide);
 Pres.Dirty := True;
 StatusMsg := 'Diapositive descendue.';
 NeedFullRedraw := True;
End;

Procedure ActionApplyLayoutToCurrent(Lay: Byte);
Var S: PSlide;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide];
 If Not ConfirmYesNo('Mise en page',
   'Remplacer les elements par les placeholders de la mise en page ?')
 Then Exit;
 ClearSlideShapes(S);
 ApplyLayout(S, Lay);
 CurShape := 0;
 S^.Dirty := True; Pres.Dirty := True;
 StatusMsg := 'Mise en page appliquee : ' + LayoutName(Lay);
 NeedFullRedraw := True;
End;

Procedure ActionChangeLayoutDlg;
Var Idx: Integer; Items: String;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 Items := 'Titre'                + #10 +
          'Titre + contenu'      + #10 +
          'Deux contenus'        + #10 +
          'Comparaison'          + #10 +
          'Titre seul'           + #10 +
          'Vide'                 + #10 +
          'Contenu et legende'   + #10 +
          'En-tete de section';
 Idx := SelectListDlg('Mise en page de la diapositive', Items,
                      Pres.Slides[CurSlide]^.Layout + 1);
 If Idx > 0 Then ActionApplyLayoutToCurrent(Idx - 1);
End;

Procedure ActionChangeBackgroundDlg;
Var Idx: Integer; Items: String;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 Items := 'Noir'        + #10 + 'Bleu'        + #10 + 'Vert'      + #10 +
          'Cyan'        + #10 + 'Rouge'       + #10 + 'Magenta'   + #10 +
          'Marron'      + #10 + 'Gris clair'  + #10 + 'Gris fonce'+ #10 +
          'Bleu clair'  + #10 + 'Vert clair'  + #10 + 'Cyan clair'+ #10 +
          'Rouge clair' + #10 + 'Magenta cl.' + #10 + 'Jaune'     + #10 +
          'Blanc';
 Idx := SelectListDlg('Arriere-plan de diapositive', Items,
                      Pres.Slides[CurSlide]^.Background + 1);
 If Idx > 0 Then Begin
  Pres.Slides[CurSlide]^.Background := Idx - 1;
  Pres.Slides[CurSlide]^.Dirty := True;
  Pres.Dirty := True;
  StatusMsg := 'Arriere-plan modifie.';
  NeedFullRedraw := True;
 End;
End;

Procedure ApplyThemeToSlide(S: PSlide; T: Integer);
Var I: Integer; Sh: PShape;
Begin
 If (S = Nil) Or (T < 1) Or (T > Pres.ThemeCount) Then Exit;
 S^.Background := Pres.Themes[T].BgColor;
 S^.Theme := T;
 For I := 1 To S^.ShCount Do Begin
  Sh := S^.Shapes[I]; If Sh = Nil Then Continue;
  Case Sh^.ShType Of
   SHP_TITLE:    Sh^.TextColor := Pres.Themes[T].TitleColor;
   SHP_SUBTITLE: Sh^.TextColor := Pres.Themes[T].TitleColor;
   SHP_CONTENT,
   SHP_TEXT:     Sh^.TextColor := Pres.Themes[T].TextColor;
  End;
 End;
 S^.Dirty := True;
End;

Procedure ApplyThemeToAll(T: Integer);
Var I: Integer;
Begin
 If (T < 1) Or (T > Pres.ThemeCount) Then Exit;
 Pres.MasterBg     := Pres.Themes[T].BgColor;
 Pres.MasterTitleC := Pres.Themes[T].TitleColor;
 Pres.MasterTextC  := Pres.Themes[T].TextColor;
 For I := 1 To Pres.SldCount Do ApplyThemeToSlide(Pres.Slides[I], T);
 Pres.Dirty := True;
End;

Procedure ActionChangeThemeDlg;
Var Idx, I: Integer; Items: String;
Begin
 Items := '';
 For I := 1 To Pres.ThemeCount Do Begin
  If I > 1 Then Items := Items + #10;
  Items := Items + Pres.Themes[I].Name;
 End;
 Idx := SelectListDlg('Theme de la presentation', Items, Pres.ThemeIdx);
 If Idx > 0 Then Begin
  Pres.ThemeIdx := Idx;
  If ConfirmYesNo('Appliquer le theme',
                  'Appliquer le theme a toutes les diapositives ?') Then
   ApplyThemeToAll(Idx);
  Pres.Dirty := True;
  StatusMsg := 'Theme : ' + Pres.Themes[Idx].Name;
  NeedFullRedraw := True;
 End;
End;

Procedure ActionRenameSlide;
Var S: String;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide]^.Name;
 If InputTextDlg('Nom de la diapositive',
                 'Nom interne de la diapositive :', S, 30) Then Begin
  Pres.Slides[CurSlide]^.Name := S;
  Pres.Slides[CurSlide]^.Dirty := True;
  Pres.Dirty := True;
  StatusMsg := 'Diapositive renommee.';
  NeedFullRedraw := True;
 End;
End;

Procedure ActionEditNotes;
Var S: String;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide]^.Notes;
 If InputTextDlg('Notes du presentateur',
                 'Notes pour cette diapositive :', S, 200) Then Begin
  Pres.Slides[CurSlide]^.Notes := S;
  Pres.Slides[CurSlide]^.Dirty := True;
  Pres.Dirty := True;
  StatusMsg := 'Notes enregistrees.';
  NeedFullRedraw := True;
 End;
End;

Procedure ActionToggleHideSlide;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 Pres.Slides[CurSlide]^.Hidden := Not Pres.Slides[CurSlide]^.Hidden;
 If Pres.Slides[CurSlide]^.Hidden Then
  StatusMsg := 'Diapositive masquee.'
 Else
  StatusMsg := 'Diapositive visible.';
 Pres.Dirty := True;
 NeedFullRedraw := True;
End;

Procedure ActionInsertFromLayout;
Var Idx, Pos: Integer; Items: String;
Begin
 Items := 'Titre'                + #10 +
          'Titre + contenu'      + #10 +
          'Deux contenus'        + #10 +
          'Comparaison'          + #10 +
          'Titre seul'           + #10 +
          'Vide'                 + #10 +
          'Contenu et legende'   + #10 +
          'En-tete de section';
 Idx := SelectListDlg('Nouvelle diapositive : mise en page', Items, 2);
 If Idx <= 0 Then Exit;
 If CurSlide < 1 Then Pos := AddSlideAt(1)
 Else Pos := AddSlideAt(CurSlide + 1);
 If Pos > 0 Then Begin
  ApplyLayout(Pres.Slides[Pos], Idx - 1);
  CurSlide := Pos; CurShape := 0;
  StatusMsg := 'Diapositive inseree.';
  NeedFullRedraw := True;
 End;
End;

{ ====================================================================== }
{           PHASE 6 - EN-TETE / PIED / MASQUE / THEMES                   }
{ ====================================================================== }

Procedure ActionHeaderFooter;
Var S: String;
Begin
 Pres.ShowHeader := ConfirmYesNo('En-tete et pied de page',
                                 'Afficher un en-tete ?');
 If Pres.ShowHeader Then Begin
  S := Pres.HeaderText;
  If InputTextDlg('En-tete', 'Texte de l''en-tete :', S, 60) Then
   Pres.HeaderText := S;
 End;
 Pres.ShowFooter := ConfirmYesNo('En-tete et pied de page',
                                 'Afficher un pied de page ?');
 If Pres.ShowFooter Then Begin
  S := Pres.FooterText;
  If InputTextDlg('Pied de page', 'Texte du pied de page :', S, 60) Then
   Pres.FooterText := S;
 End;
 Pres.ShowDate := ConfirmYesNo('En-tete et pied de page',
                               'Afficher la date ?');
 If Pres.ShowDate Then Begin
  S := Pres.DateText;
  If InputTextDlg('Date', 'Texte de la date :', S, 20) Then
   Pres.DateText := S;
 End;
 Pres.ShowSlideNum := ConfirmYesNo('En-tete et pied de page',
                                   'Afficher le numero de diapositive ?');
 Pres.Dirty := True;
 StatusMsg := 'En-tete / pied / date / numero : mis a jour.';
 NeedFullRedraw := True;
End;

Procedure ActionMasterEdit;
Var Idx: Integer; Items: String;
Begin
 Items := 'Modifier la couleur de fond par defaut'    + #10 +
          'Modifier la couleur de titre par defaut'   + #10 +
          'Modifier la couleur de texte par defaut'   + #10 +
          'Appliquer le masque aux nouvelles slides'  + #10 +
          'Reappliquer le masque a toutes les slides';
 Idx := SelectListDlg('Masque des diapositives', Items, 1);
 If Idx <= 0 Then Exit;
 Case Idx Of
  1: Begin
   Items := 'Noir'        + #10 + 'Bleu'        + #10 + 'Vert'      + #10 +
            'Cyan'        + #10 + 'Rouge'       + #10 + 'Magenta'   + #10 +
            'Marron'      + #10 + 'Gris clair'  + #10 + 'Gris fonce'+ #10 +
            'Bleu clair'  + #10 + 'Vert clair'  + #10 + 'Cyan clair'+ #10 +
            'Rouge clair' + #10 + 'Magenta cl.' + #10 + 'Jaune'     + #10 +
            'Blanc';
   Idx := SelectListDlg('Couleur de fond du masque', Items, Pres.MasterBg + 1);
   If Idx > 0 Then Pres.MasterBg := Idx - 1;
  End;
  2: Begin
   Items := 'Noir'        + #10 + 'Bleu'        + #10 + 'Vert'      + #10 +
            'Cyan'        + #10 + 'Rouge'       + #10 + 'Magenta'   + #10 +
            'Marron'      + #10 + 'Gris clair'  + #10 + 'Gris fonce'+ #10 +
            'Bleu clair'  + #10 + 'Vert clair'  + #10 + 'Cyan clair'+ #10 +
            'Rouge clair' + #10 + 'Magenta cl.' + #10 + 'Jaune'     + #10 +
            'Blanc';
   Idx := SelectListDlg('Couleur de titre du masque', Items, Pres.MasterTitleC + 1);
   If Idx > 0 Then Pres.MasterTitleC := Idx - 1;
  End;
  3: Begin
   Items := 'Noir'        + #10 + 'Bleu'        + #10 + 'Vert'      + #10 +
            'Cyan'        + #10 + 'Rouge'       + #10 + 'Magenta'   + #10 +
            'Marron'      + #10 + 'Gris clair'  + #10 + 'Gris fonce'+ #10 +
            'Bleu clair'  + #10 + 'Vert clair'  + #10 + 'Cyan clair'+ #10 +
            'Rouge clair' + #10 + 'Magenta cl.' + #10 + 'Jaune'     + #10 +
            'Blanc';
   Idx := SelectListDlg('Couleur de texte du masque', Items, Pres.MasterTextC + 1);
   If Idx > 0 Then Pres.MasterTextC := Idx - 1;
  End;
  4: Begin
   StatusMsg := 'Le masque sera applique aux prochaines slides creees.';
  End;
  5: ApplyThemeToAll(Pres.ThemeIdx);
 End;
 Pres.Dirty := True;
 NeedFullRedraw := True;
End;

Procedure ActionBackgroundAll;
Var Idx, I: Integer; Items: String;
Begin
 Items := 'Noir'        + #10 + 'Bleu'        + #10 + 'Vert'      + #10 +
          'Cyan'        + #10 + 'Rouge'       + #10 + 'Magenta'   + #10 +
          'Marron'      + #10 + 'Gris clair'  + #10 + 'Gris fonce'+ #10 +
          'Bleu clair'  + #10 + 'Vert clair'  + #10 + 'Cyan clair'+ #10 +
          'Rouge clair' + #10 + 'Magenta cl.' + #10 + 'Jaune'     + #10 +
          'Blanc';
 Idx := SelectListDlg('Arriere-plan global', Items, Pres.MasterBg + 1);
 If Idx <= 0 Then Exit;
 Pres.MasterBg := Idx - 1;
 For I := 1 To Pres.SldCount Do
  If Pres.Slides[I] <> Nil Then Pres.Slides[I]^.Background := Idx - 1;
 Pres.Dirty := True;
 StatusMsg := 'Arriere-plan applique a toutes les diapositives.';
 NeedFullRedraw := True;
End;

{ Trace l'en-tete/pied/date/numero a l'interieur d'une slide rendue. }
Procedure DrawMasterOverlay(SlideIdx: Integer; X1, Y1, X2, Y2: Integer);
Var FgC, BgC: Byte; W: Integer; S: String;
Begin
 BgC := Pres.MasterBg;
 If (SlideIdx >= 1) And (SlideIdx <= Pres.SldCount) Then
  BgC := Pres.Slides[SlideIdx]^.Background;
 { Choix de la couleur du texte selon le fond }
 If (BgC = CLR_BLACK) Or (BgC = CLR_BLUE) Or
    (BgC = CLR_DGRAY) Or (BgC = CLR_BROWN) Then
  FgC := CLR_WHITE
 Else
  FgC := CLR_BLACK;
 SetColor(FgC);
 If Pres.ShowHeader And (Pres.HeaderText <> '') Then Begin
  S := Pres.HeaderText;
  W := TextWidth(S);
  OutTextXY(X1 + ((X2 - X1) - W) Div 2, Y1 + 4, S);
 End;
 If Pres.ShowDate And (Pres.DateText <> '') Then
  OutTextXY(X1 + 8, Y2 - 12, Pres.DateText);
 If Pres.ShowFooter And (Pres.FooterText <> '') Then Begin
  S := Pres.FooterText;
  W := TextWidth(S);
  OutTextXY(X1 + ((X2 - X1) - W) Div 2, Y2 - 12, S);
 End;
 If Pres.ShowSlideNum And (SlideIdx > 0) Then Begin
  S := IntToStr(SlideIdx);
  W := TextWidth(S);
  OutTextXY(X2 - 8 - W, Y2 - 12, S);
 End;
End;

{ ====================================================================== }
{                  PHASE 7 : DIAPORAMA + TRANSITIONS                     }
{ ====================================================================== }

{ ----- Phase 9 : helpers d'animations ------------------------------- }

{ Plus grande valeur AnimOrder utilisee par les formes ayant une entree
  animee. Retourne 0 si aucune animation : il y a alors une seule etape
  (tout visible). }
Function MaxAnimOrder(S: PSlide): Integer;
Var I, M: Integer;
Begin
 M := 0;
 If S <> Nil Then
  For I := 1 To S^.ShCount Do
   If (S^.Shapes[I] <> Nil) And
      (S^.Shapes[I]^.AnimEntry <> ANIM_NONE) And
      (S^.Shapes[I]^.AnimOrder > M) Then
    M := S^.Shapes[I]^.AnimOrder;
 MaxAnimOrder := M;
End;

{ Une forme est-elle visible a l'etape d'animation Step ?
  - AnimEntry = ANIM_NONE : toujours visible (sauf Hidden).
  - sinon : visible quand AnimOrder <= Step. }
Function ShapeVisibleAt(P: PShape; Step: Integer): Boolean;
Begin
 If P = Nil Then Begin ShapeVisibleAt := False; Exit; End;
 If P^.Hidden Then Begin ShapeVisibleAt := False; Exit; End;
 If P^.AnimEntry = ANIM_NONE Then ShapeVisibleAt := True
 Else ShapeVisibleAt := P^.AnimOrder <= Step;
End;

{ Rend la diapositive Idx en plein ecran en montrant les formes visibles
  a l'etape d'animation Step (0 = etat initial). }
Procedure RenderSlideAtStep(Idx, Step: Integer);
Var S: PSlide; I, MaxX, MaxY: Integer;
    SX1, SY1, SX2, SY2: Integer;
Begin
 If (Idx < 1) Or (Idx > Pres.SldCount) Then Exit;
 S := Pres.Slides[Idx];
 If S = Nil Then Exit;
 MaxX := GetMaxX; MaxY := GetMaxY;
 SX1 := SlideX1; SY1 := SlideY1; SX2 := SlideX2; SY2 := SlideY2;
 SlideX1 := 0; SlideY1 := 0; SlideX2 := MaxX; SlideY2 := MaxY;
 SetFillStyle(1, S^.Background);
 Bar(0, 0, MaxX, MaxY);
 For I := 1 To S^.ShCount Do
  If ShapeVisibleAt(S^.Shapes[I], Step) Then DrawShape(S^.Shapes[I]);
 DrawMasterOverlay(Idx, 0, 0, MaxX, MaxY);
 SlideX1 := SX1; SlideY1 := SY1; SlideX2 := SX2; SlideY2 := SY2;
End;

{ Rendu complet (toutes animations terminees) : utilise pour transitions
  et navigation arriere. }
Procedure RenderSlideFullscreen(Idx: Integer);
Begin
 If (Idx >= 1) And (Idx <= Pres.SldCount) Then
  RenderSlideAtStep(Idx, MaxAnimOrder(Pres.Slides[Idx]));
End;

Procedure TransDelay(Speed: Byte);
Begin
 Case Speed Of
  0: Delay(70);
  1: Delay(35);
  2: Delay(15);
 Else Delay(35);
 End;
End;

{ Recouvre en CLR_BLACK la region NON ENCORE revelee a l'etape K (0..STEPS).
  K=0 : tout est cache. K=STEPS : rien n'est cache. }
Procedure DrawTransitionCover(Trans: Byte; K, Steps: Integer);
Var MaxX, MaxY, Cx, Cy, Half, I, J, Bh, H, Cw, Ch, Gap: Integer;
Begin
 MaxX := GetMaxX; MaxY := GetMaxY;
 Cx := MaxX Div 2; Cy := MaxY Div 2;
 SetFillStyle(1, CLR_BLACK);
 SetColor(CLR_BLACK);
 Case Trans Of
  TRANS_WIPE_R, TRANS_PUSH:
   Bar(K * MaxX Div Steps, 0, MaxX, MaxY);
  TRANS_WIPE_L:
   Bar(0, 0, MaxX - K * MaxX Div Steps, MaxY);
  TRANS_WIPE_D:
   Bar(0, K * MaxY Div Steps, MaxX, MaxY);
  TRANS_WIPE_U:
   Bar(0, 0, MaxX, MaxY - K * MaxY Div Steps);
  TRANS_SPLIT: Begin
   Half := (Steps - K) * MaxX Div (2 * Steps);
   If Half > 0 Then Bar(Cx - Half, 0, Cx + Half, MaxY);
  End;
  TRANS_BLINDS: Begin
   Bh := MaxY Div 8;
   H  := (Steps - K) * Bh Div Steps;
   If H > 0 Then
    For I := 0 To 7 Do Bar(0, I * Bh, MaxX, I * Bh + H);
  End;
  TRANS_CHECKER: Begin
   Cw := 32; Ch := 24;
   For I := 0 To (MaxX Div Cw) Do
    For J := 0 To (MaxY Div Ch) Do
     If ((I + J) Mod 2) = 0 Then Begin
      If I + J + 1 > K Then
       Bar(I * Cw, J * Ch, I * Cw + Cw - 1, J * Ch + Ch - 1);
     End Else Begin
      If I + J + 2 > K Then
       Bar(I * Cw, J * Ch, I * Cw + Cw - 1, J * Ch + Ch - 1);
     End;
  End;
  TRANS_DISSOLVE: Begin
   { Pavage 16x16, ordre pseudo-aleatoire base sur Steps }
   For I := 0 To (MaxX Div 16) Do
    For J := 0 To (MaxY Div 16) Do
     If (((I * 7 + J * 13 + I*J) Mod (Steps + 1)) >= K) Then
      Bar(I * 16, J * 16, I * 16 + 15, J * 16 + 15);
  End;
  TRANS_FADE: Begin
   { Pattern de pixels noirs qui se rarefie a chaque etape }
   Gap := K + 1;
   If Gap > 0 Then
    For I := 0 To MaxX Div Gap Do
     For J := 0 To MaxY Div Gap Do
      PutPixel(I * Gap, J * Gap, CLR_BLACK);
  End;
 End;
End;

{ Anime la transition vers la diapositive NewIdx. Le contenu actuel de
  l'ecran est considere comme l'ancienne diapositive. }
Procedure RunTransition(NewIdx: Integer; Trans, Speed: Byte);
Const STEPS = 10;
Var K, MaxX, MaxY: Integer;
Begin
 MaxX := GetMaxX; MaxY := GetMaxY;
 If Trans = TRANS_NONE Then Begin
  RenderSlideFullscreen(NewIdx);
  Exit;
 End;
 For K := 0 To STEPS Do Begin
  RenderSlideFullscreen(NewIdx);
  DrawTransitionCover(Trans, K, STEPS);
  TransDelay(Speed);
  If KeyPressed Then Exit;
 End;
 RenderSlideFullscreen(NewIdx);
End;

{ Couvre la forme P avec un patron de pixels noirs decroissant.
  K = Steps : couverture maximale ; K = 0 : aucune couverture. }
Procedure DrawShapeDitherCover(P: PShape; K, Steps: Integer);
Var X1, Y1, X2, Y2, IX, IY, Gap: Integer;
Begin
 If (P = Nil) Or (K <= 0) Or (Steps <= 0) Then Exit;
 X1 := LogX(P^.X);
 Y1 := LogY(P^.Y);
 X2 := LogX(P^.X + P^.W);
 Y2 := LogY(P^.Y + P^.H);
 Gap := Steps - K + 1;
 If Gap < 1 Then Gap := 1;
 IY := Y1;
 While IY <= Y2 Do Begin
  IX := X1;
  While IX <= X2 Do Begin
   PutPixel(IX, IY, CLR_BLACK);
   Inc(IX, Gap);
  End;
  Inc(IY, Gap);
 End;
End;

{ Joue l'animation d'entree d'une forme. Le rendu de la slide a l'etape
  AtStep (forme finale visible) est utilise pour chaque image
  intermediaire. Modifie temporairement les coordonnees de la forme. }
Procedure PlayShapeEntry(Idx, AtStep, ShapeIdx: Integer);
Const STEPS = 8;
Var S: PSlide; P: PShape; K: Integer;
    SaveX, SaveY, SaveW, SaveH: Integer;
    Dx, Dy: Integer;
Begin
 If (Idx < 1) Or (Idx > Pres.SldCount) Then Exit;
 S := Pres.Slides[Idx]; If S = Nil Then Exit;
 If (ShapeIdx < 1) Or (ShapeIdx > S^.ShCount) Then Exit;
 P := S^.Shapes[ShapeIdx];
 If (P = Nil) Or (P^.AnimEntry = ANIM_NONE) Then Exit;
 SaveX := P^.X; SaveY := P^.Y; SaveW := P^.W; SaveH := P^.H;
 Dx := 0; Dy := 0;
 Case P^.AnimEntry Of
  ANIM_APPEAR:
   RenderSlideAtStep(Idx, AtStep);
  ANIM_FADE: Begin
   For K := STEPS Downto 0 Do Begin
    RenderSlideAtStep(Idx, AtStep);
    DrawShapeDitherCover(P, K, STEPS);
    Delay(35);
    If KeyPressed Then Break;
   End;
   RenderSlideAtStep(Idx, AtStep);
  End;
  ANIM_SLIDE_L, ANIM_SLIDE_R, ANIM_SLIDE_U, ANIM_SLIDE_D: Begin
   Case P^.AnimEntry Of
    ANIM_SLIDE_L: Begin Dx := -1100; Dy := 0; End;
    ANIM_SLIDE_R: Begin Dx :=  1100; Dy := 0; End;
    ANIM_SLIDE_U: Begin Dx := 0; Dy := -850; End;
    ANIM_SLIDE_D: Begin Dx := 0; Dy :=  850; End;
   End;
   For K := STEPS Downto 0 Do Begin
    P^.X := SaveX + (LongInt(Dx) * K) Div STEPS;
    P^.Y := SaveY + (LongInt(Dy) * K) Div STEPS;
    RenderSlideAtStep(Idx, AtStep);
    Delay(30);
    If KeyPressed Then Break;
   End;
   P^.X := SaveX; P^.Y := SaveY;
   RenderSlideAtStep(Idx, AtStep);
  End;
  ANIM_ZOOM: Begin
   For K := 1 To STEPS Do Begin
    P^.W := (LongInt(SaveW) * K) Div STEPS;
    P^.H := (LongInt(SaveH) * K) Div STEPS;
    If P^.W < 2 Then P^.W := 2;
    If P^.H < 2 Then P^.H := 2;
    P^.X := SaveX + (SaveW - P^.W) Div 2;
    P^.Y := SaveY + (SaveH - P^.H) Div 2;
    RenderSlideAtStep(Idx, AtStep);
    Delay(35);
    If KeyPressed Then Break;
   End;
   P^.X := SaveX; P^.Y := SaveY; P^.W := SaveW; P^.H := SaveH;
   RenderSlideAtStep(Idx, AtStep);
  End;
  ANIM_SPIN: Begin
   { Rotation non supportee : clignotement avant apparition. }
   For K := 1 To 4 Do Begin
    If AtStep > 0 Then RenderSlideAtStep(Idx, AtStep - 1)
                  Else RenderSlideAtStep(Idx, 0);
    Delay(50);
    RenderSlideAtStep(Idx, AtStep);
    Delay(50);
    If KeyPressed Then Break;
   End;
   RenderSlideAtStep(Idx, AtStep);
  End;
 Else
  RenderSlideAtStep(Idx, AtStep);
 End;
End;

{ Revele toutes les formes ayant AnimOrder = TargetStep, l'une apres
  l'autre dans leur ordre de declaration. Masque temporairement les
  formes non encore animees de cette etape pour qu'elles n'apparaissent
  pas avant leur tour. }
Procedure RevealAnimStep(Idx, TargetStep: Integer);
Var S: PSlide; I, J: Integer; P: PShape;
    OrigOrder: Array[1..MAX_SHAPES] Of Byte;
Begin
 If (Idx < 1) Or (Idx > Pres.SldCount) Then Exit;
 S := Pres.Slides[Idx]; If S = Nil Then Exit;
 For J := 1 To S^.ShCount Do
  If S^.Shapes[J] <> Nil Then OrigOrder[J] := S^.Shapes[J]^.AnimOrder
                         Else OrigOrder[J] := 0;
 For I := 1 To S^.ShCount Do Begin
  P := S^.Shapes[I];
  If (P <> Nil) And (P^.AnimEntry <> ANIM_NONE) And
     (OrigOrder[I] = TargetStep) And (Not P^.Hidden) Then Begin
   { Masque les formes suivantes de la meme etape non encore animees. }
   For J := I + 1 To S^.ShCount Do
    If (S^.Shapes[J] <> Nil) And
       (S^.Shapes[J]^.AnimEntry <> ANIM_NONE) And
       (OrigOrder[J] = TargetStep) Then
     S^.Shapes[J]^.AnimOrder := TargetStep + 1;
   PlayShapeEntry(Idx, TargetStep, I);
   For J := I + 1 To S^.ShCount Do
    If S^.Shapes[J] <> Nil Then
     S^.Shapes[J]^.AnimOrder := OrigOrder[J];
  End;
 End;
 RenderSlideAtStep(Idx, TargetStep);
End;

{ Boucle principale du diaporama plein ecran. }
Procedure SlideShowLoop(StartIdx: Integer);
Var Idx, K, ExtCode: Integer; Done, GoNext, GoPrev: Boolean; C: Char;
    Sl: PSlide; SaveView: Byte;
    CurStep, MaxStep: Integer;
Begin
 If Pres.SldCount = 0 Then Begin
  MessageBox('Diaporama', 'Aucune diapositive a presenter.');
  Exit;
 End;
 Idx := StartIdx;
 If Idx < 1 Then Idx := 1;
 If Idx > Pres.SldCount Then Idx := Pres.SldCount;
 { Saute les slides masquees au debut }
 While (Idx <= Pres.SldCount) And (Pres.Slides[Idx] <> Nil) And
       Pres.Slides[Idx]^.Hidden Do Inc(Idx);
 If Idx > Pres.SldCount Then Begin
  MessageBox('Diaporama', 'Toutes les diapositives sont masquees.');
  Exit;
 End;
 SaveView := CurView;
 CurView  := VIEW_SLIDESHOW;
 SetFillStyle(1, CLR_BLACK);
 Bar(0, 0, GetMaxX, GetMaxY);
 CurStep := 0;
 MaxStep := MaxAnimOrder(Pres.Slides[Idx]);
 RenderSlideAtStep(Idx, CurStep);
 Done := False;
 Repeat
  GoNext := False; GoPrev := False;
  GetMouseState(Mouse.X, Mouse.Y, Mouse.B);
  If KeyPressed Then Begin
   C := ReadKey;
   If C = #0 Then Begin
    ExtCode := Ord(ReadKey);
    Case ExtCode Of
     75, 72: GoPrev := True;             { fleche gauche / haut }
     77, 80, 81: GoNext := True;         { fleche droite / bas / PgDn }
     71: Begin                           { Home }
      Idx := 1;
      While (Idx <= Pres.SldCount) And (Pres.Slides[Idx] <> Nil) And
            Pres.Slides[Idx]^.Hidden Do Inc(Idx);
      If Idx <= Pres.SldCount Then Begin
       CurStep := 0;
       MaxStep := MaxAnimOrder(Pres.Slides[Idx]);
       RenderSlideAtStep(Idx, CurStep);
      End;
     End;
     79: Begin                           { End }
      Idx := Pres.SldCount;
      While (Idx >= 1) And (Pres.Slides[Idx] <> Nil) And
            Pres.Slides[Idx]^.Hidden Do Dec(Idx);
      If Idx >= 1 Then Begin
       MaxStep := MaxAnimOrder(Pres.Slides[Idx]);
       CurStep := MaxStep;
       RenderSlideAtStep(Idx, CurStep);
      End;
     End;
    End;
   End Else Begin
    Case C Of
     #27: Done := True;                  { Echap }
     #13, ' ', 'n', 'N': GoNext := True; { Entree / Espace / N }
     'p', 'P', #8: GoPrev := True;       { P / Backspace }
     'b', 'B': Begin
      SetFillStyle(1, CLR_BLACK);
      Bar(0, 0, GetMaxX, GetMaxY);
     End;
     'w', 'W': Begin
      SetFillStyle(1, CLR_WHITE);
      Bar(0, 0, GetMaxX, GetMaxY);
     End;
     'r', 'R': RenderSlideAtStep(Idx, CurStep);
    End;
   End;
  End Else If ((Mouse.B And 1) <> 0) And ((LastClickB And 1) = 0) Then Begin
   GoNext := True;
   LastClickB := Mouse.B;
  End Else If ((Mouse.B And 2) <> 0) And ((LastClickB And 2) = 0) Then Begin
   GoPrev := True;
   LastClickB := Mouse.B;
  End Else
   LastClickB := Mouse.B;
  { Avance : etape suivante d'animation, sinon slide suivante }
  If GoNext Then Begin
   If CurStep < MaxStep Then Begin
    Inc(CurStep);
    RevealAnimStep(Idx, CurStep);
   End Else Begin
    K := Idx + 1;
    While (K <= Pres.SldCount) And (Pres.Slides[K] <> Nil) And
          Pres.Slides[K]^.Hidden Do Inc(K);
    If K <= Pres.SldCount Then Begin
     Sl  := Pres.Slides[Idx];
     Idx := K;
     CurStep := 0;
     MaxStep := MaxAnimOrder(Pres.Slides[Idx]);
     If Sl <> Nil Then
      RunTransition(Idx, Sl^.Transition, Sl^.TransSpeed);
     RenderSlideAtStep(Idx, CurStep);
    End Else Done := True;
   End;
  End;
  { Recul : etape precedente, sinon slide precedente }
  If GoPrev Then Begin
   If CurStep > 0 Then Begin
    Dec(CurStep);
    RenderSlideAtStep(Idx, CurStep);
   End Else Begin
    K := Idx - 1;
    While (K >= 1) And (Pres.Slides[K] <> Nil) And
          Pres.Slides[K]^.Hidden Do Dec(K);
    If K >= 1 Then Begin
     Idx := K;
     MaxStep := MaxAnimOrder(Pres.Slides[Idx]);
     CurStep := MaxStep;
     RenderSlideAtStep(Idx, CurStep);
    End;
   End;
  End;
  Delay(20);
 Until Done;
 CurView := SaveView;
 NeedFullRedraw := True;
End;

Procedure ActionInsertImage;
Var FN: String; Slot: Integer; P: PShape; S: PSlide;
    ImW, ImH, LogIW, LogIH: Integer;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide];
 If S = Nil Then Exit;
 If S^.ShCount >= MAX_SHAPES Then Begin
  MessageBox('Image', 'Nombre maximum de formes atteint sur cette slide.');
  Exit;
 End;
 FN := '';
 If Not InputTextDlg('Inserer une image',
                     'Fichier BMP ou PCX :', FN, 79) Then Exit;
 If FN = '' Then Exit;
 If Not LoadImageFile(FN, Slot) Then Begin
  MessageBox('Image', 'Impossible de charger : ' + FN);
  Exit;
 End;
 ImW := Pres.Images[Slot]^.W;
 ImH := Pres.Images[Slot]^.H;
 LogIW := 400;
 If ImW > 0 Then LogIH := (LongInt(ImH) * LogIW) Div ImW
            Else LogIH := 300;
 If LogIH > 500 Then Begin
  LogIH := 500;
  If ImH > 0 Then LogIW := (LongInt(ImW) * LogIH) Div ImH;
 End;
 P := NewShape;
 If P = Nil Then Begin
  MessageBox('Image', 'Memoire insuffisante.'); Exit;
 End;
 P^.ShType    := SHP_IMAGE;
 P^.X         := (1000 - LogIW) Div 2;
 P^.Y         := (750  - LogIH) Div 2;
 P^.W         := LogIW;
 P^.H         := LogIH;
 P^.ImageIdx  := Slot;
 P^.Filled    := False;
 P^.LineWidth := 0;
 P^.TxtCount  := 0;
 AddShapeToSlide(S, P);
 CurShape := S^.ShCount;
 S^.Dirty := True;
 Pres.Dirty := True;
 StatusMsg := 'Image chargee : ' + FN +
              ' (' + IntToStr(ImW) + 'x' + IntToStr(ImH) + ')';
 NeedStatRedraw := True;
 NeedSlideRedraw := True;
 NeedPanelRedraw := True;
End;

Procedure ActionAnimEntryDlg;
Const ANIM_LIST = 'Aucune'#10'Apparaitre'#10'Fondu'#10 +
                  'Glisser depuis la gauche'#10 +
                  'Glisser depuis la droite'#10 +
                  'Glisser depuis le haut'#10 +
                  'Glisser depuis le bas'#10 +
                  'Zoom'#10'Rotation';
Var S: PSlide; P: PShape; Sel: Integer; OrdStr: String;
    NewOrder: LongInt;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide];
 If (S = Nil) Or (CurShape < 1) Or (CurShape > S^.ShCount) Then Begin
  MessageBox('Animation', 'Selectionnez d''abord une forme.');
  Exit;
 End;
 P := S^.Shapes[CurShape]; If P = Nil Then Exit;
 Sel := SelectListDlg('Animation d''entree', ANIM_LIST, P^.AnimEntry + 1);
 If Sel = 0 Then Exit;
 P^.AnimEntry := Byte(Sel - 1);
 If P^.AnimEntry <> ANIM_NONE Then Begin
  OrdStr := IntToStr(P^.AnimOrder);
  If P^.AnimOrder = 0 Then OrdStr := '1';
  If InputTextDlg('Ordre d''animation',
                  'Ordre (1 = premier, max 250) :', OrdStr, 4) Then Begin
   NewOrder := StrToIntDef(OrdStr, 1);
   If NewOrder < 1 Then NewOrder := 1;
   If NewOrder > 250 Then NewOrder := 250;
   P^.AnimOrder := Byte(NewOrder);
  End Else If P^.AnimOrder = 0 Then
   P^.AnimOrder := 1;
 End Else
  P^.AnimOrder := 0;
 S^.Dirty := True;
 Pres.Dirty := True;
 StatusMsg := 'Animation d''entree mise a jour.';
 NeedStatRedraw := True;
End;

Procedure ActionAnimExitDlg;
Const ANIM_LIST = 'Aucune'#10'Disparaitre'#10'Fondu'#10 +
                  'Glisser vers la gauche'#10 +
                  'Glisser vers la droite'#10 +
                  'Glisser vers le haut'#10 +
                  'Glisser vers le bas'#10 +
                  'Zoom'#10'Rotation';
Var S: PSlide; P: PShape; Sel: Integer;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide];
 If (S = Nil) Or (CurShape < 1) Or (CurShape > S^.ShCount) Then Begin
  MessageBox('Animation', 'Selectionnez d''abord une forme.');
  Exit;
 End;
 P := S^.Shapes[CurShape]; If P = Nil Then Exit;
 Sel := SelectListDlg('Animation de sortie', ANIM_LIST, P^.AnimExit + 1);
 If Sel = 0 Then Exit;
 P^.AnimExit := Byte(Sel - 1);
 S^.Dirty := True;
 Pres.Dirty := True;
 StatusMsg := 'Animation de sortie mise a jour.';
 NeedStatRedraw := True;
End;

Procedure ActionTimingDlg;
Const SPD_LIST = 'Lente'#10'Moyenne'#10'Rapide';
Var S: PSlide; Sel: Integer;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide];
 If S = Nil Then Exit;
 Sel := SelectListDlg('Vitesse des transitions/animations',
                      SPD_LIST, S^.TransSpeed + 1);
 If Sel = 0 Then Exit;
 S^.TransSpeed := Byte(Sel - 1);
 S^.Dirty := True;
 Pres.Dirty := True;
 StatusMsg := 'Vitesse mise a jour.';
 NeedStatRedraw := True;
End;

Procedure ActionSlideShow;
Begin SlideShowLoop(1); End;

Procedure ActionSlideShowFrom;
Begin SlideShowLoop(CurSlide); End;

Procedure ActionChangeTransitionDlg;
Var Idx, I: Integer; Items: String; S: PSlide;
Begin
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide];
 If S = Nil Then Exit;
 Items := '';
 For I := 0 To 10 Do Begin
  If I > 0 Then Items := Items + #10;
  Items := Items + TransName(Byte(I));
 End;
 Idx := SelectListDlg('Transition de diapositive', Items, S^.Transition + 1);
 If Idx > 0 Then Begin
  S^.Transition := Byte(Idx - 1);
  S^.Dirty := True;
  If ConfirmYesNo('Transition',
                  'Appliquer a toutes les diapositives ?') Then Begin
   For I := 1 To Pres.SldCount Do
    If Pres.Slides[I] <> Nil Then Begin
     Pres.Slides[I]^.Transition := Byte(Idx - 1);
     Pres.Slides[I]^.Dirty      := True;
    End;
  End;
  StatusMsg := 'Transition : ' + TransName(Byte(Idx - 1));
  NeedStatRedraw := True;
 End;
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{          PHASE 10 : FORMAT .PPT NATIF + DIALOGUES FICHIER              }
{ ====================================================================== }

Var
 PPTBuf : Array[0..511] Of Byte;

{ ----- I/O binaire little-endian sur File untyped (record size = 1) --- }

Procedure PtWrB(Var F:File; B:Byte);
Begin PPTBuf[0]:=B; BlockWrite(F,PPTBuf,1); End;

Procedure PtWrW(Var F:File; W:Word);
Begin
 PPTBuf[0] := Byte(W And $FF);
 PPTBuf[1] := Byte((W Shr 8) And $FF);
 BlockWrite(F, PPTBuf, 2);
End;

Procedure WrI(Var F:File; I:Integer);
Begin PtWrW(F, Word(I)); End;

Procedure WrS(Var F:File; Const S:String);
Var L:Integer;
Begin
 L := Length(S);
 If L > 255 Then L := 255;
 PtWrB(F, Byte(L));
 If L > 0 Then BlockWrite(F, S[1], L);
End;

Function RdB(Var F:File):Byte;
Begin
 BlockRead(F, PPTBuf, 1);
 RdB := PPTBuf[0];
End;

Function RdW(Var F:File):Word;
Begin
 BlockRead(F, PPTBuf, 2);
 RdW := Word(PPTBuf[0]) Or (Word(PPTBuf[1]) Shl 8);
End;

Function RdI(Var F:File):Integer;
Begin RdI := Integer(RdW(F)); End;

Procedure RdS(Var F:File; Var S:String);
Var L:Byte;
Begin
 BlockRead(F, L, 1);
 S[0] := Char(L);
 If L > 0 Then BlockRead(F, S[1], L);
End;

{ ----- Ecriture du fichier .PPT natif --------------------------------- }

Function SavePresentationFile(Const FN: String): Boolean;
Var F: File; I, J, K: Integer; S: PSlide; Sh: PShape; Img: PImage;
    Magic: Array[1..4] Of Char;
    PixSize: LongInt;
Begin
 SavePresentationFile := False;
 Assign(F, FN);
 {$I-} Rewrite(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 Magic[1]:='P'; Magic[2]:='P'; Magic[3]:='N'; Magic[4]:='T';
 BlockWrite(F, Magic, 4);
 PtWrB(F, 1);                         { version }
 PtWrB(F, 0); PtWrB(F, 0); PtWrB(F, 0);   { reserve }

 WrS(F, Pres.Name);
 WrS(F, Pres.Author);
 WrS(F, Pres.Company);
 WrS(F, Pres.Title);
 WrS(F, Pres.Subject);
 WrS(F, Pres.Comments);
 WrS(F, Pres.HeaderText);
 WrS(F, Pres.FooterText);
 WrS(F, Pres.DateText);
 PtWrB(F, Byte(Pres.ShowHeader));
 PtWrB(F, Byte(Pres.ShowFooter));
 PtWrB(F, Byte(Pres.ShowDate));
 PtWrB(F, Byte(Pres.ShowSlideNum));
 PtWrB(F, Pres.MasterBg);
 PtWrB(F, Pres.MasterTitleC);
 PtWrB(F, Pres.MasterTextC);
 PtWrW(F, Word(Pres.ThemeIdx));

 { Images : 16 slots, marker 0/1 par slot }
 PtWrW(F, Word(Pres.ImgCount));
 For I := 1 To MAX_IMAGES Do Begin
  Img := Pres.Images[I];
  If Img = Nil Then PtWrB(F, 0)
  Else Begin
   PtWrB(F, 1);
   WrS(F, Img^.Name);
   WrS(F, Img^.FileName);
   PtWrW(F, Word(Img^.W));
   PtWrW(F, Word(Img^.H));
   PtWrB(F, Byte(Img^.Loaded));
   If Img^.Loaded And (Img^.Pixels <> Nil) And
      (Img^.W > 0) And (Img^.H > 0) Then Begin
    PixSize := LongInt(Img^.W) * Img^.H;
    BlockWrite(F, Img^.Pixels^, PixSize);
   End;
  End;
 End;

 { Slides }
 PtWrW(F, Word(Pres.SldCount));
 For I := 1 To Pres.SldCount Do Begin
  S := Pres.Slides[I];
  If S <> Nil Then Begin
   WrS(F, S^.Name);
   WrS(F, S^.Title);
   PtWrB(F, S^.Layout);
   PtWrB(F, S^.Background);
   PtWrB(F, S^.Theme);
   PtWrB(F, S^.Transition);
   PtWrB(F, S^.TransSpeed);
   WrS(F, S^.Notes);
   PtWrB(F, Byte(S^.Hidden));
   PtWrW(F, Word(S^.ShCount));
   For J := 1 To S^.ShCount Do Begin
    Sh := S^.Shapes[J];
    If Sh <> Nil Then Begin
     WrS(F, Sh^.Name);
     PtWrB(F, Sh^.ShType);
     WrI(F, Sh^.X);  WrI(F, Sh^.Y);
     WrI(F, Sh^.W);  WrI(F, Sh^.H);
     PtWrB(F, Sh^.FillColor);
     PtWrB(F, Sh^.LineColor);
     PtWrB(F, Sh^.LineWidth);
     PtWrB(F, Byte(Sh^.Filled));
     WrI(F, Sh^.Rotation);
     WrI(F, Sh^.ZOrder);
     PtWrB(F, Byte(Sh^.Locked));
     PtWrB(F, Byte(Sh^.Hidden));
     PtWrB(F, Byte(Sh^.TxtCount));
     For K := 1 To Sh^.TxtCount Do Begin
      WrS(F, Sh^.Text[K]);
      PtWrB(F, Byte(Sh^.Bullets[K]));
      PtWrB(F, Sh^.Indent[K]);
     End;
     PtWrB(F, Byte(Sh^.Bold));
     PtWrB(F, Byte(Sh^.Italic));
     PtWrB(F, Byte(Sh^.Underline));
     PtWrB(F, Sh^.FontSize);
     PtWrB(F, Sh^.TextColor);
     PtWrB(F, Sh^.Align);
     PtWrW(F, Word(Sh^.ImageIdx));
     PtWrB(F, Sh^.AnimEntry);
     PtWrB(F, Sh^.AnimExit);
     PtWrB(F, Sh^.AnimOrder);
    End;
   End;
  End;
 End;
 Close(F);
 SavePresentationFile := True;
End;

{ ----- Lecture du fichier .PPT natif ---------------------------------- }

Function LoadPresentationFile(Const FN: String): Boolean;
Var F: File;
    I, J, K: Integer;
    NImg, NSld, NSh, NTxt: Integer;
    S: PSlide; Sh: PShape; Img: PImage;
    Magic: Array[1..4] Of Char;
    Version, Marker: Byte;
    PixSize: LongInt;
    StrBuf: String;
Begin
 LoadPresentationFile := False;
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Exit;
 {$I-} BlockRead(F, Magic, 4); {$I+}
 If (IOResult <> 0) Or
    (Magic[1] <> 'P') Or (Magic[2] <> 'P') Or
    (Magic[3] <> 'N') Or (Magic[4] <> 'T') Then Begin
  Close(F); Exit;
 End;
 Version := RdB(F);
 If Version <> 1 Then Begin Close(F); Exit; End;
 RdB(F); RdB(F); RdB(F);

 FreePresentation;
 InitPresentation;

 RdS(F, StrBuf); Pres.Name        := StrBuf;
 RdS(F, StrBuf); Pres.Author      := StrBuf;
 RdS(F, StrBuf); Pres.Company     := StrBuf;
 RdS(F, StrBuf); Pres.Title       := StrBuf;
 RdS(F, StrBuf); Pres.Subject     := StrBuf;
 RdS(F, StrBuf); Pres.Comments    := StrBuf;
 RdS(F, StrBuf); Pres.HeaderText  := StrBuf;
 RdS(F, StrBuf); Pres.FooterText  := StrBuf;
 RdS(F, StrBuf); Pres.DateText    := StrBuf;
 Pres.ShowHeader   := RdB(F) <> 0;
 Pres.ShowFooter   := RdB(F) <> 0;
 Pres.ShowDate     := RdB(F) <> 0;
 Pres.ShowSlideNum := RdB(F) <> 0;
 Pres.MasterBg     := RdB(F);
 Pres.MasterTitleC := RdB(F);
 Pres.MasterTextC  := RdB(F);
 Pres.ThemeIdx     := Integer(RdW(F));

 { Images }
 NImg := Integer(RdW(F));
 Pres.ImgCount := NImg;
 For I := 1 To MAX_IMAGES Do Begin
  Marker := RdB(F);
  If Marker = 0 Then Pres.Images[I] := Nil
  Else Begin
   New(Img);
   RdS(F, StrBuf); Img^.Name     := StrBuf;
   RdS(F, StrBuf); Img^.FileName := StrBuf;
   Img^.W := Integer(RdW(F));
   Img^.H := Integer(RdW(F));
   Img^.Loaded := RdB(F) <> 0;
   Img^.Pixels := Nil;
   If Img^.Loaded And (Img^.W > 0) And (Img^.H > 0) Then Begin
    PixSize := LongInt(Img^.W) * Img^.H;
    GetMem(Img^.Pixels, PixSize);
    BlockRead(F, Img^.Pixels^, PixSize);
   End;
   Pres.Images[I] := Img;
  End;
 End;

 { Slides }
 NSld := Integer(RdW(F));
 If NSld > MAX_SLIDES Then NSld := MAX_SLIDES;
 For I := 1 To NSld Do Begin
  S := NewSlide;
  RdS(F, StrBuf); S^.Name  := StrBuf;
  RdS(F, StrBuf); S^.Title := StrBuf;
  S^.Layout     := RdB(F);
  S^.Background := RdB(F);
  S^.Theme      := RdB(F);
  S^.Transition := RdB(F);
  S^.TransSpeed := RdB(F);
  RdS(F, StrBuf); S^.Notes := StrBuf;
  S^.Hidden := RdB(F) <> 0;
  NSh := Integer(RdW(F));
  If NSh > MAX_SHAPES Then NSh := MAX_SHAPES;
  For J := 1 To NSh Do Begin
   Sh := NewShape;
   RdS(F, StrBuf); Sh^.Name := StrBuf;
   Sh^.ShType    := RdB(F);
   Sh^.X := Integer(RdW(F));  Sh^.Y := Integer(RdW(F));
   Sh^.W := Integer(RdW(F));  Sh^.H := Integer(RdW(F));
   Sh^.FillColor := RdB(F);
   Sh^.LineColor := RdB(F);
   Sh^.LineWidth := RdB(F);
   Sh^.Filled    := RdB(F) <> 0;
   Sh^.Rotation  := Integer(RdW(F));
   Sh^.ZOrder    := Integer(RdW(F));
   Sh^.Locked    := RdB(F) <> 0;
   Sh^.Hidden    := RdB(F) <> 0;
   NTxt := RdB(F);
   Sh^.TxtCount := NTxt;
   If NTxt > MAX_TEXT_LINES Then NTxt := MAX_TEXT_LINES;
   For K := 1 To NTxt Do Begin
    RdS(F, StrBuf); Sh^.Text[K] := StrBuf;
    Sh^.Bullets[K] := RdB(F) <> 0;
    Sh^.Indent[K]  := RdB(F);
   End;
   Sh^.Bold      := RdB(F) <> 0;
   Sh^.Italic    := RdB(F) <> 0;
   Sh^.Underline := RdB(F) <> 0;
   Sh^.FontSize  := RdB(F);
   Sh^.TextColor := RdB(F);
   Sh^.Align     := RdB(F);
   Sh^.ImageIdx  := Integer(RdW(F));
   Sh^.AnimEntry := RdB(F);
   Sh^.AnimExit  := RdB(F);
   Sh^.AnimOrder := RdB(F);
   AddShapeToSlide(S, Sh);
  End;
  Pres.Slides[I] := S;
 End;
 Pres.SldCount := NSld;
 Close(F);
 Pres.FileName := FN;
 Pres.Dirty    := False;
 If Pres.SldCount > 0 Then CurSlide := 1 Else CurSlide := 0;
 CurShape := 0;
 LoadPresentationFile := True;
End;

{ ====================================================================== }
{   DIALOGUE DE SELECTION DE FICHIER (Phase 12 - style Office classique)  }
{                                                                        }
{   - Champ "Nom du fichier" editable (avec caret clignotant)            }
{   - Combo "Type" cyclable : *.PPT / *.PPTX / *.PRN / *.*               }
{   - Affichage du repertoire courant ("Chercher dans :")                }
{   - Listbox "Fichiers" (filtree par le combo Type)                     }
{   - Listbox "Dossiers et lecteurs" : [..], [SOUS-DOSSIER], [-A-]..[-Z-]}
{   - Boutons "Aller dans le parent", "OK", "Annuler"                    }
{   - Navigation clavier : Tab/Shift+Tab pour le focus, fleches dans     }
{     les listes, Entree active, Esc annule, frappe edite le nom         }
{   - Navigation souris : simple clic = selection, double clic = activer }
{   - Mise a jour automatique de la liste apres chaque ChDir/changement  }
{     de filtre                                                          }
{ ====================================================================== }

Function FileSelectDlg(Const Title: String;
                       Var FN: String; ForSave: Boolean): Boolean;
{ boite de fichiers de PM (presentations .PPT et .PPTX) }
Begin
 FileSelectDlg := PmFileDlg(Title, '*.PPT;*.PPTX', FN, ForSave);
 NeedFullRedraw := True;
End;

{ ----- Actions Fichier (Open/Save/SaveAs/Close) ----------------------- }

Procedure ActionSaveAs;
Var FN: String;
Begin
 FN := Pres.FileName;
 If FN = '' Then FN := 'PRESENT.PPT';
 If Not InputTextDlg('Enregistrer sous',
                     'Nom du fichier (.PPT) :', FN, 79) Then Begin
  NeedFullRedraw := True; Exit;
 End;
 If FN = '' Then Begin NeedFullRedraw := True; Exit; End;
 If Pos('.', FN) = 0 Then FN := FN + '.PPT';
 If SavePresentationFile(FN) Then Begin
  Pres.FileName := FN;
  Pres.Dirty    := False;
  StatusMsg     := 'Enregistre : ' + FN;
 End Else
  MessageBox('Enregistrer', 'Impossible d''ecrire : ' + FN);
 NeedFullRedraw := True;
End;

Procedure ActionSave;
Begin
 If Pres.FileName = '' Then Begin ActionSaveAs; Exit; End;
 If SavePresentationFile(Pres.FileName) Then Begin
  Pres.Dirty := False;
  StatusMsg  := 'Enregistre : ' + Pres.FileName;
 End Else
  MessageBox('Enregistrer',
             'Impossible d''ecrire : ' + Pres.FileName);
 NeedStatRedraw := True;
End;

Procedure ActionOpen;
Var FN: String;
Begin
 If Not ConfirmDiscardChanges Then Exit;
 FN := '';
 If Not FileSelectDlg('Ouvrir une presentation .PPT', FN, False) Then Begin
  NeedFullRedraw := True; Exit;
 End;
 If LoadPresentationFile(FN) Then
  StatusMsg := 'Charge : ' + FN
 Else
  MessageBox('Ouvrir', 'Impossible de lire : ' + FN);
 NeedFullRedraw := True;
End;

Procedure ActionClose;
Begin
 If Not ConfirmDiscardChanges Then Exit;
 FreePresentation;
 InitPresentation;
 SeedSamplePresentation;
 StatusMsg := 'Presentation fermee.';
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{          PHASE 11 : .PPTX (OOXML) -- ECRITURE ET LECTURE                }
{ ====================================================================== }
{ Format ZIP : entrees STORED (methode 0) uniquement. Le fichier produit  }
{ s'ouvre dans PowerPoint, Impress, et nous-memes. La lecture est limitee }
{ aux entrees STORED ; pour les .pptx natifs PowerPoint (DEFLATE), il    }
{ faudrait integrer un decodeur deflate (UNZIP.PAS). On extrait les       }
{ chaines <a:t>...</a:t> des fichiers ppt/slides/slide*.xml.              }
{ ----------------------------------------------------------------------- }

Const
 MAX_ZIP_ENT       = 320;
 ZIP_LFH_SIG       : LongInt = $04034B50;
 ZIP_CDH_SIG       : LongInt = $02014B50;
 ZIP_EOCD_SIG      : LongInt = $06054B50;
 CRC32_POLY        : LongInt = -306674912; { = $EDB88320 en non-signe }

Var
 CRC32Tab     : Array[0..255] Of LongInt;
 CRC32Inited  : Boolean;
 ZOutF        : File;
 ZOutOk       : Boolean;
 ZCurStart    : LongInt;
 ZCurDataOff  : LongInt;
 ZCurName     : String[80];
 ZCurCRC      : LongInt;
 ZCurSize     : LongInt;
 ZCdNames     : Array[1..MAX_ZIP_ENT] Of String[80];
 ZCdOffsets   : Array[1..MAX_ZIP_ENT] Of LongInt;
 ZCdSizes     : Array[1..MAX_ZIP_ENT] Of LongInt;
 ZCdCRCs      : Array[1..MAX_ZIP_ENT] Of LongInt;
 ZCdCount     : Integer;

{ ----- 4 octets little-endian -------------------------------------------- }

Procedure PtWrL(Var F: File; L: LongInt);
Begin
 PPTBuf[0] := Byte(L And $FF);
 PPTBuf[1] := Byte((L Shr 8) And $FF);
 PPTBuf[2] := Byte((L Shr 16) And $FF);
 PPTBuf[3] := Byte((L Shr 24) And $FF);
 BlockWrite(F, PPTBuf, 4);
End;

Function RdL(Var F: File): LongInt;
Begin
 BlockRead(F, PPTBuf, 4);
 RdL := LongInt(PPTBuf[0]) Or (LongInt(PPTBuf[1]) Shl 8) Or
        (LongInt(PPTBuf[2]) Shl 16) Or (LongInt(PPTBuf[3]) Shl 24);
End;

{ ----- CRC32 ------------------------------------------------------------- }

Procedure InitCRC32;
Var I, J: Integer; C: LongInt;
Begin
 For I := 0 To 255 Do Begin
  C := I;
  For J := 0 To 7 Do
   If (C And 1) <> 0 Then C := LongInt(C Shr 1) Xor CRC32_POLY
   Else C := C Shr 1;
  CRC32Tab[I] := C;
 End;
 CRC32Inited := True;
End;

Procedure CRC32Update(Var CRC: LongInt; B: Byte);
Begin
 CRC := CRC32Tab[Byte((CRC Xor LongInt(B)) And $FF)] Xor LongInt(CRC Shr 8);
End;

{ ----- ZIP Writer (stored only) ------------------------------------------ }

Procedure ZipOpen(Const FN: String);
Begin
 ZOutOk := False;
 ZCdCount := 0;
 If Not CRC32Inited Then InitCRC32;
 Assign(ZOutF, FN);
 {$I-} Rewrite(ZOutF, 1); {$I+}
 If IOResult = 0 Then ZOutOk := True;
End;

Procedure ZipBeginEntry(Const Name: String);
Var L: Integer;
Begin
 If Not ZOutOk Then Exit;
 ZCurStart := FilePos(ZOutF);
 ZCurName  := Name;
 ZCurCRC   := LongInt($FFFFFFFF);
 ZCurSize  := 0;
 L := Length(Name);
 { Local file header : sig 4, ver 2, flags 2, method 2, time 2, date 2,
   crc 4, csize 4, usize 4, namelen 2, extralen 2, name }
 PtWrL(ZOutF, ZIP_LFH_SIG);
 PtWrW(ZOutF, 20);          { version }
 PtWrW(ZOutF, 0);           { flags }
 PtWrW(ZOutF, 0);           { method 0 = stored }
 PtWrW(ZOutF, 0);           { mod time }
 PtWrW(ZOutF, $4321);       { mod date (2013-01-01 environ) }
 PtWrL(ZOutF, 0);           { CRC placeholder }
 PtWrL(ZOutF, 0);           { csize placeholder }
 PtWrL(ZOutF, 0);           { usize placeholder }
 PtWrW(ZOutF, Word(L));     { name length }
 PtWrW(ZOutF, 0);           { extra length }
 If L > 0 Then BlockWrite(ZOutF, Name[1], L);
 ZCurDataOff := FilePos(ZOutF);
End;

Procedure ZipWriteByte(B: Byte);
Begin
 If Not ZOutOk Then Exit;
 PPTBuf[0] := B;
 BlockWrite(ZOutF, PPTBuf, 1);
 CRC32Update(ZCurCRC, B);
 Inc(ZCurSize);
End;

Procedure ZipWriteStr(Const S: String);
Var I, L: Integer;
Begin
 If Not ZOutOk Then Exit;
 L := Length(S);
 For I := 1 To L Do CRC32Update(ZCurCRC, Byte(S[I]));
 If L > 0 Then BlockWrite(ZOutF, S[1], L);
 ZCurSize := ZCurSize + L;
End;

Procedure ZipWriteLn(Const S: String);
Begin
 ZipWriteStr(S);
 ZipWriteByte(10);
End;

Procedure ZipWriteXml(Const S: String);
Var I: Integer; C: Char;
Begin
 For I := 1 To Length(S) Do Begin
  C := S[I];
  Case C Of
   '&': ZipWriteStr('&amp;');
   '<': ZipWriteStr('&lt;');
   '>': ZipWriteStr('&gt;');
   '"': ZipWriteStr('&quot;');
   '''': ZipWriteStr('&apos;');
  Else
   If (Byte(C) >= 32) And (Byte(C) < 127) Then ZipWriteByte(Byte(C))
   Else ZipWriteByte(63);
  End;
 End;
End;

Procedure ZipEndEntry;
Var CRC: LongInt; EndPos: LongInt;
Begin
 If Not ZOutOk Then Exit;
 CRC := ZCurCRC Xor LongInt($FFFFFFFF);
 EndPos := FilePos(ZOutF);
 { Repositionne dans le local header pour patcher CRC + sizes }
 Seek(ZOutF, ZCurStart + 14);
 PtWrL(ZOutF, CRC);
 PtWrL(ZOutF, ZCurSize);
 PtWrL(ZOutF, ZCurSize);
 Seek(ZOutF, EndPos);
 { Enregistre pour le central directory }
 If ZCdCount < MAX_ZIP_ENT Then Begin
  Inc(ZCdCount);
  ZCdNames[ZCdCount]   := ZCurName;
  ZCdOffsets[ZCdCount] := ZCurStart;
  ZCdSizes[ZCdCount]   := ZCurSize;
  ZCdCRCs[ZCdCount]    := CRC;
 End;
End;

Procedure ZipClose;
Var I, L: Integer;
    CdStart, CdSize: LongInt;
Begin
 If Not ZOutOk Then Exit;
 CdStart := FilePos(ZOutF);
 For I := 1 To ZCdCount Do Begin
  L := Length(ZCdNames[I]);
  PtWrL(ZOutF, ZIP_CDH_SIG);
  PtWrW(ZOutF, 20);                  { ver made by }
  PtWrW(ZOutF, 20);                  { ver needed }
  PtWrW(ZOutF, 0);                   { flags }
  PtWrW(ZOutF, 0);                   { method }
  PtWrW(ZOutF, 0);                   { time }
  PtWrW(ZOutF, $4321);               { date }
  PtWrL(ZOutF, ZCdCRCs[I]);
  PtWrL(ZOutF, ZCdSizes[I]);
  PtWrL(ZOutF, ZCdSizes[I]);
  PtWrW(ZOutF, Word(L));             { name len }
  PtWrW(ZOutF, 0);                   { extra len }
  PtWrW(ZOutF, 0);                   { comment len }
  PtWrW(ZOutF, 0);                   { disk number }
  PtWrW(ZOutF, 0);                   { internal attr }
  PtWrL(ZOutF, 0);                   { external attr }
  PtWrL(ZOutF, ZCdOffsets[I]);
  If L > 0 Then BlockWrite(ZOutF, ZCdNames[I][1], L);
 End;
 CdSize := FilePos(ZOutF) - CdStart;
 { End of central directory }
 PtWrL(ZOutF, ZIP_EOCD_SIG);
 PtWrW(ZOutF, 0);                    { disk }
 PtWrW(ZOutF, 0);                    { cd disk }
 PtWrW(ZOutF, Word(ZCdCount));
 PtWrW(ZOutF, Word(ZCdCount));
 PtWrL(ZOutF, CdSize);
 PtWrL(ZOutF, CdStart);
 PtWrW(ZOutF, 0);                    { comment len }
 Close(ZOutF);
 ZOutOk := False;
End;

{ ----- Emetteurs XML PPTX ------------------------------------------------ }

Procedure EmitContentTypes;
Var I: Integer; S: String;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteStr('<Types xmlns="http://schemas.openxmlformats.org/package/');
 ZipWriteLn('2006/content-types">');
 ZipWriteLn('<Default Extension="rels" ContentType="application/' +
            'vnd.openxmlformats-package.relationships+xml"/>');
 ZipWriteLn('<Default Extension="xml" ContentType="application/xml"/>');
 ZipWriteLn('<Override PartName="/ppt/presentation.xml" ContentType=' +
   '"application/vnd.openxmlformats-officedocument.' +
   'presentationml.presentation.main+xml"/>');
 ZipWriteLn('<Override PartName="/ppt/slideMasters/slideMaster1.xml" ' +
   'ContentType="application/vnd.openxmlformats-officedocument.' +
   'presentationml.slideMaster+xml"/>');
 ZipWriteLn('<Override PartName="/ppt/slideLayouts/slideLayout1.xml" ' +
   'ContentType="application/vnd.openxmlformats-officedocument.' +
   'presentationml.slideLayout+xml"/>');
 ZipWriteLn('<Override PartName="/ppt/theme/theme1.xml" ContentType=' +
   '"application/vnd.openxmlformats-officedocument.theme+xml"/>');
 For I := 1 To Pres.SldCount Do Begin
  Str(I, S);
  ZipWriteLn('<Override PartName="/ppt/slides/slide' + S +
             '.xml" ContentType="application/vnd.openxmlformats-' +
             'officedocument.presentationml.slide+xml"/>');
 End;
 ZipWriteLn('</Types>');
End;

Procedure EmitRootRels;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteLn('<Relationships xmlns="http://schemas.openxmlformats.org/' +
            'package/2006/relationships">');
 ZipWriteLn('<Relationship Id="rId1" Type="http://schemas.openxmlformats' +
   '.org/officeDocument/2006/relationships/officeDocument" ' +
   'Target="ppt/presentation.xml"/>');
 ZipWriteLn('</Relationships>');
End;

Procedure EmitPresentation;
Var I: Integer; S: String;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteStr('<p:presentation xmlns:a="http://schemas.openxmlformats.');
 ZipWriteStr('org/drawingml/2006/main" xmlns:r="http://schemas.');
 ZipWriteStr('openxmlformats.org/officeDocument/2006/relationships" ');
 ZipWriteLn('xmlns:p="http://schemas.openxmlformats.org/' +
            'presentationml/2006/main">');
 ZipWriteLn('<p:sldMasterIdLst><p:sldMasterId id="2147483648" ' +
            'r:id="rId1"/></p:sldMasterIdLst>');
 ZipWriteStr('<p:sldIdLst>');
 For I := 1 To Pres.SldCount Do Begin
  Str(255 + I, S);
  ZipWriteStr('<p:sldId id="' + S + '" r:id="rId' );
  Str(I + 1, S);
  ZipWriteStr(S + '"/>');
 End;
 ZipWriteLn('</p:sldIdLst>');
 ZipWriteLn('<p:sldSz cx="9144000" cy="6858000" type="screen4x3"/>');
 ZipWriteLn('<p:notesSz cx="6858000" cy="9144000"/>');
 ZipWriteLn('</p:presentation>');
End;

Procedure EmitPresentationRels;
Var I: Integer; S: String;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteLn('<Relationships xmlns="http://schemas.openxmlformats.org/' +
            'package/2006/relationships">');
 ZipWriteLn('<Relationship Id="rId1" Type="http://schemas.openxmlformats' +
            '.org/officeDocument/2006/relationships/slideMaster" ' +
            'Target="slideMasters/slideMaster1.xml"/>');
 For I := 1 To Pres.SldCount Do Begin
  Str(I + 1, S);
  ZipWriteStr('<Relationship Id="rId' + S + '" Type=');
  ZipWriteStr('"http://schemas.openxmlformats.org/officeDocument/');
  ZipWriteStr('2006/relationships/slide" Target="slides/slide');
  Str(I, S);
  ZipWriteLn(S + '.xml"/>');
 End;
 ZipWriteLn('</Relationships>');
End;

Procedure EmitTheme;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteLn('<a:theme xmlns:a="http://schemas.openxmlformats.org/' +
            'drawingml/2006/main" name="Office">');
 ZipWriteLn('<a:themeElements>');
 ZipWriteLn('<a:clrScheme name="Office">');
 ZipWriteLn('<a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1>');
 ZipWriteLn('<a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1>');
 ZipWriteLn('<a:dk2><a:srgbClr val="1F497D"/></a:dk2>');
 ZipWriteLn('<a:lt2><a:srgbClr val="EEECE1"/></a:lt2>');
 ZipWriteLn('<a:accent1><a:srgbClr val="4F81BD"/></a:accent1>');
 ZipWriteLn('<a:accent2><a:srgbClr val="C0504D"/></a:accent2>');
 ZipWriteLn('<a:accent3><a:srgbClr val="9BBB59"/></a:accent3>');
 ZipWriteLn('<a:accent4><a:srgbClr val="8064A2"/></a:accent4>');
 ZipWriteLn('<a:accent5><a:srgbClr val="4BACC6"/></a:accent5>');
 ZipWriteLn('<a:accent6><a:srgbClr val="F79646"/></a:accent6>');
 ZipWriteLn('<a:hlink><a:srgbClr val="0000FF"/></a:hlink>');
 ZipWriteLn('<a:folHlink><a:srgbClr val="800080"/></a:folHlink>');
 ZipWriteLn('</a:clrScheme>');
 ZipWriteLn('<a:fontScheme name="Office">');
 ZipWriteLn('<a:majorFont><a:latin typeface="Calibri"/>' +
            '<a:ea typeface=""/><a:cs typeface=""/></a:majorFont>');
 ZipWriteLn('<a:minorFont><a:latin typeface="Calibri"/>' +
            '<a:ea typeface=""/><a:cs typeface=""/></a:minorFont>');
 ZipWriteLn('</a:fontScheme>');
 ZipWriteLn('<a:fmtScheme name="Office">');
 ZipWriteLn('<a:fillStyleLst>' +
   '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
   '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
   '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
   '</a:fillStyleLst>');
 ZipWriteLn('<a:lnStyleLst>' +
   '<a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/>' +
   '</a:solidFill></a:ln>' +
   '<a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/>' +
   '</a:solidFill></a:ln>' +
   '<a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/>' +
   '</a:solidFill></a:ln></a:lnStyleLst>');
 ZipWriteLn('<a:effectStyleLst>' +
   '<a:effectStyle><a:effectLst/></a:effectStyle>' +
   '<a:effectStyle><a:effectLst/></a:effectStyle>' +
   '<a:effectStyle><a:effectLst/></a:effectStyle>' +
   '</a:effectStyleLst>');
 ZipWriteLn('<a:bgFillStyleLst>' +
   '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
   '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
   '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>' +
   '</a:bgFillStyleLst>');
 ZipWriteLn('</a:fmtScheme>');
 ZipWriteLn('</a:themeElements>');
 ZipWriteLn('</a:theme>');
End;

Procedure EmitSlideMaster;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteStr('<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/');
 ZipWriteStr('drawingml/2006/main" xmlns:r="http://schemas.openxml');
 ZipWriteStr('formats.org/officeDocument/2006/relationships" xmlns:p=');
 ZipWriteLn('"http://schemas.openxmlformats.org/presentationml/2006/' +
            'main">');
 ZipWriteLn('<p:cSld><p:bg><p:bgRef idx="1001">' +
            '<a:schemeClr val="bg1"/></p:bgRef></p:bg>');
 ZipWriteLn('<p:spTree>');
 ZipWriteLn('<p:nvGrpSpPr><p:cNvPr id="1" name=""/>' +
            '<p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>');
 ZipWriteLn('<p:grpSpPr><a:xfrm><a:off x="0" y="0"/>' +
   '<a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/>' +
   '<a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>');
 ZipWriteLn('</p:spTree></p:cSld>');
 ZipWriteLn('<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" ' +
   'accent1="accent1" accent2="accent2" accent3="accent3" ' +
   'accent4="accent4" accent5="accent5" accent6="accent6" ' +
   'hlink="hlink" folHlink="folHlink"/>');
 ZipWriteLn('<p:sldLayoutIdLst><p:sldLayoutId id="2147483649" ' +
            'r:id="rId1"/></p:sldLayoutIdLst>');
 ZipWriteLn('<p:txStyles>');
 ZipWriteLn('<p:titleStyle><a:lvl1pPr algn="ctr">' +
            '<a:defRPr sz="4400"/></a:lvl1pPr></p:titleStyle>');
 ZipWriteLn('<p:bodyStyle><a:lvl1pPr><a:defRPr sz="2400"/>' +
            '</a:lvl1pPr></p:bodyStyle>');
 ZipWriteLn('<p:otherStyle/>');
 ZipWriteLn('</p:txStyles>');
 ZipWriteLn('</p:sldMaster>');
End;

Procedure EmitSlideMasterRels;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteLn('<Relationships xmlns="http://schemas.openxmlformats.org/' +
            'package/2006/relationships">');
 ZipWriteLn('<Relationship Id="rId1" Type="http://schemas.openxml' +
            'formats.org/officeDocument/2006/relationships/' +
            'slideLayout" Target="../slideLayouts/slideLayout1.xml"/>');
 ZipWriteLn('<Relationship Id="rId2" Type="http://schemas.openxml' +
            'formats.org/officeDocument/2006/relationships/theme" ' +
            'Target="../theme/theme1.xml"/>');
 ZipWriteLn('</Relationships>');
End;

Procedure EmitSlideLayout;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteStr('<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/');
 ZipWriteStr('drawingml/2006/main" xmlns:r="http://schemas.openxml');
 ZipWriteStr('formats.org/officeDocument/2006/relationships" xmlns:p=');
 ZipWriteStr('"http://schemas.openxmlformats.org/presentationml/2006/');
 ZipWriteLn('main" type="blank" preserve="1">');
 ZipWriteLn('<p:cSld name="Blank">');
 ZipWriteLn('<p:spTree>');
 ZipWriteLn('<p:nvGrpSpPr><p:cNvPr id="1" name=""/>' +
            '<p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>');
 ZipWriteLn('<p:grpSpPr><a:xfrm><a:off x="0" y="0"/>' +
   '<a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/>' +
   '<a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>');
 ZipWriteLn('</p:spTree></p:cSld>');
 ZipWriteLn('</p:sldLayout>');
End;

Procedure EmitSlideLayoutRels;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteLn('<Relationships xmlns="http://schemas.openxmlformats.org/' +
            'package/2006/relationships">');
 ZipWriteLn('<Relationship Id="rId1" Type="http://schemas.openxml' +
            'formats.org/officeDocument/2006/relationships/' +
            'slideMaster" Target="../slideMasters/slideMaster1.xml"/>');
 ZipWriteLn('</Relationships>');
End;

Procedure EmitSlide(SlIdx: Integer);
Var S: PSlide; Sh: PShape; I, J: Integer;
    Tmp: String;
Begin
 S := Pres.Slides[SlIdx];
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteStr('<p:sld xmlns:a="http://schemas.openxmlformats.org/');
 ZipWriteStr('drawingml/2006/main" xmlns:r="http://schemas.openxml');
 ZipWriteStr('formats.org/officeDocument/2006/relationships" xmlns:p=');
 ZipWriteLn('"http://schemas.openxmlformats.org/presentationml/2006/' +
            'main">');
 ZipWriteLn('<p:cSld><p:spTree>');
 ZipWriteLn('<p:nvGrpSpPr><p:cNvPr id="1" name=""/>' +
            '<p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>');
 ZipWriteLn('<p:grpSpPr/>');
 { Bloc titre }
 ZipWriteLn('<p:sp>');
 ZipWriteLn('<p:nvSpPr><p:cNvPr id="2" name="Title"/>' +
   '<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>' +
   '<p:nvPr><p:ph type="ctrTitle"/></p:nvPr></p:nvSpPr>');
 ZipWriteLn('<p:spPr><a:xfrm><a:off x="838200" y="365125"/>' +
   '<a:ext cx="7467600" cy="1325563"/></a:xfrm></p:spPr>');
 ZipWriteLn('<p:txBody><a:bodyPr/><a:lstStyle/>');
 ZipWriteStr('<a:p><a:r><a:rPr lang="fr-FR"/><a:t>');
 If S <> Nil Then Tmp := S^.Title Else Tmp := '';
 If Tmp = '' Then Tmp := 'Diapositive';
 ZipWriteXml(Tmp);
 ZipWriteLn('</a:t></a:r></a:p></p:txBody></p:sp>');
 { Bloc contenu : concatene toutes les lignes de texte de toutes les formes }
 ZipWriteLn('<p:sp>');
 ZipWriteLn('<p:nvSpPr><p:cNvPr id="3" name="Content"/>' +
   '<p:cNvSpPr><a:spLocks noGrp="1"/></p:cNvSpPr>' +
   '<p:nvPr><p:ph idx="1"/></p:nvPr></p:nvSpPr>');
 ZipWriteLn('<p:spPr><a:xfrm><a:off x="838200" y="1825625"/>' +
   '<a:ext cx="7467600" cy="4351338"/></a:xfrm></p:spPr>');
 ZipWriteLn('<p:txBody><a:bodyPr/><a:lstStyle/>');
 If S <> Nil Then
  For I := 1 To S^.ShCount Do Begin
   Sh := S^.Shapes[I];
   If Sh <> Nil Then
    For J := 1 To Sh^.TxtCount Do Begin
     ZipWriteStr('<a:p><a:r><a:rPr lang="fr-FR"/><a:t>');
     ZipWriteXml(Sh^.Text[J]);
     ZipWriteLn('</a:t></a:r></a:p>');
    End;
  End;
 ZipWriteLn('</p:txBody></p:sp>');
 ZipWriteLn('</p:spTree></p:cSld>');
 ZipWriteLn('</p:sld>');
End;

Procedure EmitSlideRels;
Begin
 ZipWriteLn('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
 ZipWriteLn('<Relationships xmlns="http://schemas.openxmlformats.org/' +
            'package/2006/relationships">');
 ZipWriteLn('<Relationship Id="rId1" Type="http://schemas.openxml' +
            'formats.org/officeDocument/2006/relationships/' +
            'slideLayout" Target="../slideLayouts/slideLayout1.xml"/>');
 ZipWriteLn('</Relationships>');
End;

{ ----- Sauvegarde .PPTX complete ----------------------------------------- }

Function SavePPTX(Const FN: String): Boolean;
Var I: Integer; S: String;
Begin
 SavePPTX := False;
 ZipOpen(FN);
 If Not ZOutOk Then Exit;

 ZipBeginEntry('[Content_Types].xml');  EmitContentTypes;       ZipEndEntry;
 ZipBeginEntry('_rels/.rels');          EmitRootRels;           ZipEndEntry;
 ZipBeginEntry('ppt/presentation.xml'); EmitPresentation;       ZipEndEntry;
 ZipBeginEntry('ppt/_rels/presentation.xml.rels');
 EmitPresentationRels; ZipEndEntry;
 ZipBeginEntry('ppt/theme/theme1.xml'); EmitTheme;              ZipEndEntry;
 ZipBeginEntry('ppt/slideMasters/slideMaster1.xml');
 EmitSlideMaster;      ZipEndEntry;
 ZipBeginEntry('ppt/slideMasters/_rels/slideMaster1.xml.rels');
 EmitSlideMasterRels;  ZipEndEntry;
 ZipBeginEntry('ppt/slideLayouts/slideLayout1.xml');
 EmitSlideLayout;      ZipEndEntry;
 ZipBeginEntry('ppt/slideLayouts/_rels/slideLayout1.xml.rels');
 EmitSlideLayoutRels;  ZipEndEntry;

 For I := 1 To Pres.SldCount Do Begin
  Str(I, S);
  ZipBeginEntry('ppt/slides/slide' + S + '.xml');
  EmitSlide(I);
  ZipEndEntry;
  ZipBeginEntry('ppt/slides/_rels/slide' + S + '.xml.rels');
  EmitSlideRels;
  ZipEndEntry;
 End;
 ZipClose;
 SavePPTX := True;
End;

{ ====================================================================== }
{   Decodeur DEFLATE (RFC 1951) - pur Pascal, suffisant pour decompresser }
{   les entrees Method=8 d'un .PPTX produit par PowerPoint.               }
{ ====================================================================== }

Type
 TInfLenArr  = Array[0..287] Of Integer;
 TInfCntArr  = Array[0..15]  Of Integer;
 TInfDLenArr = Array[0..31]  Of Integer;

Const
 INF_LEN_BASE: Array[0..28] Of Integer = (
  3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,
  35,43,51,59,67,83,99,115,131,163,195,227,258);
 INF_LEN_EXTRA: Array[0..28] Of Integer = (
  0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0);
 INF_DIST_BASE: Array[0..29] Of LongInt = (
  1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,
  1025,1537,2049,3073,4097,6145,8193,12289,16385,24577);
 INF_DIST_EXTRA: Array[0..29] Of Integer = (
  0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13);
 INF_CLEN_ORDER: Array[0..18] Of Integer = (
  16,17,18,0,8,7,9,6,10,5,11,4,12,3,13,2,14,1,15);

Var
 InfBitBuf : LongInt;
 InfBitCnt : Integer;
 InfIn     : ^Byte;
 InfInPos  : LongInt;
 InfInLen  : LongInt;
 InfOut    : ^Byte;
 InfOutPos : LongInt;
 InfOutLen : LongInt;
 InfError  : Boolean;
 { Tables Huffman courantes }
 InfLL_Lens   : TInfLenArr;
 InfLL_Counts : TInfCntArr;
 InfLL_Sorted : TInfLenArr;
 InfD_Lens    : TInfDLenArr;
 InfD_Counts  : TInfCntArr;
 InfD_Sorted  : TInfDLenArr;
 InfCL_Lens   : Array[0..18] Of Integer;
 InfCL_Counts : TInfCntArr;
 InfCL_Sorted : Array[0..18] Of Integer;

Function InfReadByte: Byte;
Var P: ^Byte;
Begin
 If InfInPos >= InfInLen Then Begin
  InfError := True; InfReadByte := 0; Exit;
 End;
 P := InfIn; Inc(P, InfInPos); InfReadByte := P^;
 Inc(InfInPos);
End;

Function InfGetBits(N: Integer): LongInt;
Var R, B, Mask: LongInt;
Begin
 While InfBitCnt < N Do Begin
  B := InfReadByte;
  InfBitBuf := InfBitBuf Or (LongInt(B) Shl InfBitCnt);
  Inc(InfBitCnt, 8);
 End;
 If N = 0 Then Mask := 0 Else Mask := (LongInt(1) Shl N) - 1;
 R := InfBitBuf And Mask;
 InfBitBuf := InfBitBuf Shr N;
 Dec(InfBitCnt, N);
 InfGetBits := R;
End;

Procedure InfPutByte(B: Byte);
Var P: ^Byte;
Begin
 If InfOutPos >= InfOutLen Then Begin
  InfError := True; Exit;
 End;
 P := InfOut; Inc(P, InfOutPos); P^ := B;
 Inc(InfOutPos);
End;

Function InfOutByteAt(Off: LongInt): Byte;
Var P: ^Byte;
Begin
 P := InfOut; Inc(P, Off); InfOutByteAt := P^;
End;

{ Construit la table de decodage canonique. NumSym <= NumSymMax. }
Procedure InfBuildHuf(Var Lens: Array Of Integer; NumSym: Integer;
                      Var Counts: Array Of Integer;
                      Var Sorted: Array Of Integer);
Var I, L: Integer;
    NextOf: Array[0..16] Of Integer;
    Base  : Array[0..16] Of Integer;
Begin
 For I := 0 To 15 Do Counts[I] := 0;
 For I := 0 To NumSym - 1 Do
  If (Lens[I] >= 1) And (Lens[I] <= 15) Then Inc(Counts[Lens[I]]);
 Base[0] := 0; Base[1] := 0;
 For L := 2 To 16 Do Base[L] := Base[L - 1] + Counts[L - 1];
 For L := 0 To 16 Do NextOf[L] := Base[L];
 For I := 0 To NumSym - 1 Do Begin
  L := Lens[I];
  If (L >= 1) And (L <= 15) Then Begin
   Sorted[NextOf[L]] := I;
   Inc(NextOf[L]);
  End;
 End;
End;

Function InfDecodeSym(Var Counts: Array Of Integer;
                      Var Sorted: Array Of Integer): Integer;
Var Code, First, Index, Count, L: LongInt;
Begin
 Code := 0; First := 0; Index := 0;
 For L := 1 To 15 Do Begin
  Code := (Code Shl 1) Or InfGetBits(1);
  Count := Counts[L];
  If (Code - Count) < First Then Begin
   InfDecodeSym := Sorted[Index + (Code - First)];
   Exit;
  End;
  Index := Index + Count;
  First := (First + Count) Shl 1;
 End;
 InfError := True;
 InfDecodeSym := -1;
End;

Procedure InfDoStored;
Var Len, NLen, I: LongInt;
    B: Byte;
Begin
 { aligne sur octet }
 InfBitBuf := 0; InfBitCnt := 0;
 Len  := LongInt(InfReadByte);
 Len  := Len Or (LongInt(InfReadByte) Shl 8);
 NLen := LongInt(InfReadByte);
 NLen := NLen Or (LongInt(InfReadByte) Shl 8);
 If InfError Then Exit;
 If (Len Xor NLen) <> 65535 Then Begin
  InfError := True; Exit;
 End;
 For I := 1 To Len Do Begin
  B := InfReadByte;
  If InfError Then Exit;
  InfPutByte(B);
  If InfError Then Exit;
 End;
End;

Procedure InfInitFixed;
Var I: Integer;
Begin
 For I := 0 To 143 Do InfLL_Lens[I] := 8;
 For I := 144 To 255 Do InfLL_Lens[I] := 9;
 For I := 256 To 279 Do InfLL_Lens[I] := 7;
 For I := 280 To 287 Do InfLL_Lens[I] := 8;
 InfBuildHuf(InfLL_Lens, 288, InfLL_Counts, InfLL_Sorted);
 For I := 0 To 29 Do InfD_Lens[I] := 5;
 InfD_Lens[30] := 0; InfD_Lens[31] := 0;
 InfBuildHuf(InfD_Lens, 32, InfD_Counts, InfD_Sorted);
End;

Procedure InfReadDynamicTables;
Var HLit, HDist, HCLen, I, Idx, Sym, Rep: Integer;
    PrevLen: Integer;
    AllLens: Array[0..319] Of Integer;
Begin
 HLit  := InfGetBits(5) + 257;
 HDist := InfGetBits(5) + 1;
 HCLen := InfGetBits(4) + 4;
 If (HLit > 286) Or (HDist > 30) Or (HCLen > 19) Then Begin
  InfError := True; Exit;
 End;
 For I := 0 To 18 Do InfCL_Lens[I] := 0;
 For I := 0 To HCLen - 1 Do
  InfCL_Lens[INF_CLEN_ORDER[I]] := InfGetBits(3);
 InfBuildHuf(InfCL_Lens, 19, InfCL_Counts, InfCL_Sorted);
 If InfError Then Exit;
 Idx := 0;
 PrevLen := 0;
 While Idx < HLit + HDist Do Begin
  Sym := InfDecodeSym(InfCL_Counts, InfCL_Sorted);
  If InfError Then Exit;
  If Sym < 16 Then Begin
   AllLens[Idx] := Sym;
   PrevLen := Sym;
   Inc(Idx);
  End
  Else If Sym = 16 Then Begin
   Rep := InfGetBits(2) + 3;
   While (Rep > 0) And (Idx < HLit + HDist) Do Begin
    AllLens[Idx] := PrevLen; Inc(Idx); Dec(Rep);
   End;
  End
  Else If Sym = 17 Then Begin
   Rep := InfGetBits(3) + 3;
   PrevLen := 0;
   While (Rep > 0) And (Idx < HLit + HDist) Do Begin
    AllLens[Idx] := 0; Inc(Idx); Dec(Rep);
   End;
  End
  Else Begin   { 18 }
   Rep := InfGetBits(7) + 11;
   PrevLen := 0;
   While (Rep > 0) And (Idx < HLit + HDist) Do Begin
    AllLens[Idx] := 0; Inc(Idx); Dec(Rep);
   End;
  End;
 End;
 For I := 0 To HLit - 1 Do InfLL_Lens[I] := AllLens[I];
 For I := HLit To 287 Do InfLL_Lens[I] := 0;
 For I := 0 To HDist - 1 Do InfD_Lens[I] := AllLens[HLit + I];
 For I := HDist To 31 Do InfD_Lens[I] := 0;
 InfBuildHuf(InfLL_Lens, 288, InfLL_Counts, InfLL_Sorted);
 InfBuildHuf(InfD_Lens, 32, InfD_Counts, InfD_Sorted);
End;

Procedure InfDecodeBlock;
Var Sym, LenIdx, DistIdx, K: Integer;
    Length_, Distance, Src: LongInt;
Begin
 Repeat
  Sym := InfDecodeSym(InfLL_Counts, InfLL_Sorted);
  If InfError Then Exit;
  If Sym < 256 Then Begin
   InfPutByte(Byte(Sym));
   If InfError Then Exit;
  End
  Else If Sym = 256 Then Exit
  Else Begin
   LenIdx := Sym - 257;
   If LenIdx > 28 Then Begin InfError := True; Exit; End;
   Length_ := INF_LEN_BASE[LenIdx] + InfGetBits(INF_LEN_EXTRA[LenIdx]);
   DistIdx := InfDecodeSym(InfD_Counts, InfD_Sorted);
   If InfError Then Exit;
   If DistIdx > 29 Then Begin InfError := True; Exit; End;
   Distance := INF_DIST_BASE[DistIdx] + InfGetBits(INF_DIST_EXTRA[DistIdx]);
   If Distance > InfOutPos Then Begin InfError := True; Exit; End;
   Src := InfOutPos - Distance;
   For K := 1 To Length_ Do Begin
    InfPutByte(InfOutByteAt(Src));
    If InfError Then Exit;
    Inc(Src);
   End;
  End;
 Until False;
End;

Function Inflate(InBuf: Pointer; InLen: LongInt;
                 OutBuf: Pointer; OutLen: LongInt): Boolean;
Var BFinal, BType: Integer;
    BlockNo: Integer;

 Procedure InfLog(Const S: String);
 Var LF: Text;
 Begin
  Assign(LF, 'POWERPNT.LOG');
  {$I-} Append(LF); {$I+} If IOResult <> 0 Then Begin
   {$I-} Rewrite(LF); {$I+} If IOResult <> 0 Then Exit;
  End;
  WriteLn(LF, S); Close(LF);
 End;

 Function LS(L: LongInt): String;
 Var T: String; Begin Str(L, T); LS := T; End;

Begin
 InfIn := InBuf; InfInLen := InLen; InfInPos := 0;
 InfOut := OutBuf; InfOutLen := OutLen; InfOutPos := 0;
 InfBitBuf := 0; InfBitCnt := 0;
 InfError := False;
 BlockNo := 0;
 InfLog('  Inflate: InLen=' + LS(InLen) + ' OutLen=' + LS(OutLen));
 Repeat
  BFinal := InfGetBits(1);
  BType  := InfGetBits(2);
  Inc(BlockNo);
  InfLog('  Block ' + LS(BlockNo) + ': BFinal=' + LS(BFinal) + ' BType=' + LS(BType) + ' InPos=' + LS(InfInPos) + ' OutPos=' + LS(InfOutPos));
  Case BType Of
   0: InfDoStored;
   1: Begin InfInitFixed; InfDecodeBlock; End;
   2: Begin InfReadDynamicTables; If Not InfError Then InfDecodeBlock; End;
  Else
   InfError := True;
  End;
  If InfError Then Begin
   InfLog('  ERROR after block ' + LS(BlockNo) + ' InPos=' + LS(InfInPos) + ' OutPos=' + LS(InfOutPos));
   Break;
  End;
 Until BFinal = 1;
 InfLog('  Inflate done: err=' + LS(Ord(InfError)) + ' OutPos=' + LS(InfOutPos));
 Inflate := Not InfError;
End;

{ Helper de log top-level (PptxLog/LStr ne sont visibles qu'a l'interieur
  de LoadPPTX). Ecrit dans POWERPNT.LOG. }
Procedure PicLog(Const S: String);
Var LF: Text;
Begin
 Assign(LF, 'POWERPNT.LOG');
 {$I-} Append(LF); {$I+} If IOResult <> 0 Then Begin
  {$I-} Rewrite(LF); {$I+} If IOResult <> 0 Then Exit;
 End;
 WriteLn(LF, S); Close(LF);
End;

Function PicLS(L: LongInt): String;
Var T: String; Begin Str(L, T); PicLS := T; End;

{ ====================================================================== }
{           DITHERING FLOYD-STEINBERG VERS EGA 16 (Etape 5D)             }
{ ----------------------------------------------------------------------
   Convertit un buffer RGB (R,G,B,R,G,B,...) WxH octets vers indices EGA
   16 dans OutBuf (W*H octets), avec dithering Floyd-Steinberg :
     7/16 -> (x+1, y)
     3/16 -> (x-1, y+1)
     5/16 -> (x,   y+1)
     1/16 -> (x+1, y+1)
   Utilise 2 lignes d'erreur LongInt par canal pour eviter de saturer
   les corrections (les Bytes ne suffisent pas pour les erreurs signees).
}

Procedure DitherRgbToEga(W, H: Integer; RgbBuf, OutBuf: Pointer);
Type
 TDitBA = Array[0..1024*1024*16 - 1] Of Byte;
 PDitBA = ^TDitBA;
 TDitLA = Array[0..16383] Of LongInt;
 PDitLA = ^TDitLA;
Var Rgb: PDitBA; Outp: PDitBA;
    ErrR, ErrG, ErrB: PDitLA;
    X, Y, Cur, Nxt: Integer;
    Idx, RowBase, ErrCurOff, ErrNxtOff: LongInt;
    R, G, B, Best, Er, Eg, Eb: Integer;
    Stride: LongInt;
    Sz: LongInt;
Begin
 If (W <= 0) Or (H <= 0) Then Exit;
 Rgb  := RgbBuf;
 Outp := OutBuf;
 Stride := LongInt(W) + 2;
 Sz := Stride * 2 * SizeOf(LongInt);
 GetMem(ErrR, Sz); GetMem(ErrG, Sz); GetMem(ErrB, Sz);
 If (ErrR = Nil) Or (ErrG = Nil) Or (ErrB = Nil) Then Begin
  If ErrR <> Nil Then FreeMem(ErrR, Sz);
  If ErrG <> Nil Then FreeMem(ErrG, Sz);
  If ErrB <> Nil Then FreeMem(ErrB, Sz);
  Exit;
 End;
 FillChar(ErrR^, Sz, 0);
 FillChar(ErrG^, Sz, 0);
 FillChar(ErrB^, Sz, 0);
 Cur := 0; Nxt := 1;
 For Y := 0 To H - 1 Do Begin
  { Reinitialise la ligne suivante }
  For X := 0 To W + 1 Do Begin
   ErrR^[Nxt * Stride + X] := 0;
   ErrG^[Nxt * Stride + X] := 0;
   ErrB^[Nxt * Stride + X] := 0;
  End;
  For X := 0 To W - 1 Do Begin
   Idx := (LongInt(Y) * W + X) * 3;
   R := Rgb^[Idx]     + (ErrR^[Cur * Stride + X + 1] Div 16);
   G := Rgb^[Idx + 1] + (ErrG^[Cur * Stride + X + 1] Div 16);
   B := Rgb^[Idx + 2] + (ErrB^[Cur * Stride + X + 1] Div 16);
   If R < 0 Then R := 0 Else If R > 255 Then R := 255;
   If G < 0 Then G := 0 Else If G > 255 Then G := 255;
   If B < 0 Then B := 0 Else If B > 255 Then B := 255;
   Best := NearestVGA16(R, G, B);
   Outp^[LongInt(Y) * W + X] := Byte(Best);
   Er := R - VGA_R[Best];
   Eg := G - VGA_G[Best];
   Eb := B - VGA_B[Best];
   { Repartition (en 16emes pre-multiplies pour eviter division precoce) }
   ErrR^[Cur * Stride + X + 2] := ErrR^[Cur * Stride + X + 2] + Er * 7;
   ErrG^[Cur * Stride + X + 2] := ErrG^[Cur * Stride + X + 2] + Eg * 7;
   ErrB^[Cur * Stride + X + 2] := ErrB^[Cur * Stride + X + 2] + Eb * 7;
   ErrR^[Nxt * Stride + X]     := ErrR^[Nxt * Stride + X]     + Er * 3;
   ErrG^[Nxt * Stride + X]     := ErrG^[Nxt * Stride + X]     + Eg * 3;
   ErrB^[Nxt * Stride + X]     := ErrB^[Nxt * Stride + X]     + Eb * 3;
   ErrR^[Nxt * Stride + X + 1] := ErrR^[Nxt * Stride + X + 1] + Er * 5;
   ErrG^[Nxt * Stride + X + 1] := ErrG^[Nxt * Stride + X + 1] + Eg * 5;
   ErrB^[Nxt * Stride + X + 1] := ErrB^[Nxt * Stride + X + 1] + Eb * 5;
   ErrR^[Nxt * Stride + X + 2] := ErrR^[Nxt * Stride + X + 2] + Er * 1;
   ErrG^[Nxt * Stride + X + 2] := ErrG^[Nxt * Stride + X + 2] + Eg * 1;
   ErrB^[Nxt * Stride + X + 2] := ErrB^[Nxt * Stride + X + 2] + Eb * 1;
  End;
  { Echange Cur / Nxt }
  Cur := 1 - Cur; Nxt := 1 - Nxt;
 End;
 FreeMem(ErrR, Sz); FreeMem(ErrG, Sz); FreeMem(ErrB, Sz);
End;

{ ====================================================================== }
{                       DECODEUR PNG (Etape 5B)                          }
{ ----------------------------------------------------------------------
   Supporte :
   - Signature 89 50 4E 47 0D 0A 1A 0A
   - Chunks IHDR / PLTE / IDAT (concatenes) / IEND
   - BitDepth = 8 pour ColorType 0,2,4,6
   - BitDepth 1/2/4/8 pour ColorType 3 (paletted)
   - Filtres scanline : None/Sub/Up/Average/Paeth
   - Pas d'interlace (Adam7 refuse)
   Resultat : pixels EGA 16 (nearest match via NearestVGA16). Le dithering
   Floyd-Steinberg sera ajoute en Etape 5D.
}

Function LoadImagePngMem(InBuf: Pointer; InSize: LongInt;
                         Const Nm: String; Var Slot: Integer): Boolean;
Type
 TByteArr = Array[0..1024*1024*16 - 1] Of Byte;
 PByteArr = ^TByteArr;
 TPltEnt  = Record R, G, B: Byte; End;
Label LDone;
Var Src: PByteArr;
    Pos: LongInt;
    PngW, PngH: LongInt;
    BitDepth, ColorType, Interlace: Integer;
    Channels, BytesPerPixel: Integer;
    RowBytes: LongInt;
    IDatBuf: PByteArr;
    IDatLen, IDatCap, OldCap: LongInt;
    NewBuf: PByteArr;
    Plt: Array[0..255] Of TPltEnt;
    PltCount: Integer;
    RawBuf: PByteArr;
    RawSize: LongInt;
    ChunkLen: LongInt;
    ChunkType: String[4];
    I: LongInt;
    X, Y: Integer;
    Filter: Byte;
    LineOff, PrevLineOff: LongInt;
    A, BB, CC, Paeth, Pa, Pb, Pc: LongInt;
    R, G, B: Integer;
    PalI: Integer;
    OutSlot: Integer;
    Img: PImage;
    PxIdx: LongInt;
    OK: Boolean;
    DeflPtr: Pointer;
    RgbBuf: PByteArr;
    RgbSize: LongInt;
    Step, OutW, OutH, XX, YY: Integer;

 Function ReadBE32At(Off: LongInt): LongInt;
 Begin
  ReadBE32At := LongInt(Src^[Off])    * 16777216 +
                LongInt(Src^[Off + 1]) * 65536 +
                LongInt(Src^[Off + 2]) * 256 +
                LongInt(Src^[Off + 3]);
 End;

Begin
 LoadImagePngMem := False;
 Slot     := 0;
 OK       := False;
 IDatBuf  := Nil; IDatCap := 0; IDatLen := 0;
 RawBuf   := Nil; RawSize := 0;
 RgbBuf   := Nil; RgbSize := 0;
 PltCount := 0;
 PicLog('PNG decode "' + Nm + '" InSize=' + PicLS(InSize));
 If InSize < 16 Then Exit;
 Src := PByteArr(InBuf);
 { Signature 137,80,78,71,13,10,26,10 }
 If (Src^[0] <> 137) Or (Src^[1] <> 80) Or (Src^[2] <> 78) Or
    (Src^[3] <> 71)  Or (Src^[4] <> 13) Or (Src^[5] <> 10) Or
    (Src^[6] <> 26)  Or (Src^[7] <> 10) Then Exit;
 Pos := 8;
 PngW := 0; PngH := 0; BitDepth := 0; ColorType := 0; Interlace := 0;

 { ---- Parcours des chunks ---- }
 While Pos + 8 <= InSize Do Begin
  ChunkLen := ReadBE32At(Pos); Inc(Pos, 4);
  If (ChunkLen < 0) Or (ChunkLen > InSize) Then Goto LDone;
  If Pos + 4 + ChunkLen + 4 > InSize Then Goto LDone;
  ChunkType := Char(Src^[Pos]) + Char(Src^[Pos + 1]) +
               Char(Src^[Pos + 2]) + Char(Src^[Pos + 3]);
  Inc(Pos, 4);
  If ChunkType = 'IHDR' Then Begin
   If ChunkLen < 13 Then Goto LDone;
   PngW      := ReadBE32At(Pos);
   PngH      := ReadBE32At(Pos + 4);
   BitDepth  := Src^[Pos + 8];
   ColorType := Src^[Pos + 9];
   Interlace := Src^[Pos + 12];
  End Else If ChunkType = 'PLTE' Then Begin
   PltCount := ChunkLen Div 3;
   If PltCount > 256 Then PltCount := 256;
   For I := 0 To PltCount - 1 Do Begin
    Plt[I].R := Src^[Pos + I * 3];
    Plt[I].G := Src^[Pos + I * 3 + 1];
    Plt[I].B := Src^[Pos + I * 3 + 2];
   End;
  End Else If ChunkType = 'IDAT' Then Begin
   { Re-grow buffer si necessaire }
   If IDatLen + ChunkLen > IDatCap Then Begin
    OldCap := IDatCap;
    If IDatCap = 0 Then IDatCap := 16384;
    While IDatCap < IDatLen + ChunkLen Do IDatCap := IDatCap * 2;
    If IDatCap > LongInt(4) * 1024 * 1024 Then Goto LDone;
    GetMem(NewBuf, IDatCap);
    If NewBuf = Nil Then Goto LDone;
    If (IDatBuf <> Nil) And (IDatLen > 0) Then
     Move(IDatBuf^[0], NewBuf^[0], IDatLen);
    If IDatBuf <> Nil Then FreeMem(IDatBuf, OldCap);
    IDatBuf := NewBuf;
   End;
   If ChunkLen > 0 Then
    Move(Src^[Pos], IDatBuf^[IDatLen], ChunkLen);
   Inc(IDatLen, ChunkLen);
  End Else If ChunkType = 'IEND' Then Begin
   Inc(Pos, ChunkLen + 4);
   Break;
  End;
  Inc(Pos, ChunkLen + 4);   { saute donnees + CRC }
 End;

 PicLog('  PNG hdr: W=' + PicLS(PngW) + ' H=' + PicLS(PngH)
        + ' CT=' + PicLS(ColorType) + ' BD=' + PicLS(BitDepth)
        + ' Inter=' + PicLS(Interlace) + ' Plt=' + PicLS(PltCount)
        + ' IDatLen=' + PicLS(IDatLen));
 If (PngW <= 0) Or (PngH <= 0) Then Goto LDone;
 If Interlace <> 0 Then Goto LDone;
 If IDatLen < 6 Then Goto LDone;
 { Limites raisonnables pour eviter d'epuiser la heap }
 If (PngW > 4096) Or (PngH > 4096) Then Goto LDone;
 { Facteur de sous-echantillonnage pour borner la sortie EGA a 200000 px }
 Step := 1;
 While LongInt(PngW Div Step) * (PngH Div Step) > 200000 Do Inc(Step);
 OutW := Integer(PngW Div Step); If OutW < 1 Then OutW := 1;
 OutH := Integer(PngH Div Step); If OutH < 1 Then OutH := 1;
 PicLog('  PNG ok-hdr ' + PicLS(PngW) + 'x' + PicLS(PngH) + ' CT=' + PicLS(ColorType)
        + ' BD=' + PicLS(BitDepth) + ' step=' + PicLS(Step) + ' out='
        + PicLS(OutW) + 'x' + PicLS(OutH));
 { Channels selon ColorType }
 Case ColorType Of
  0: Channels := 1;
  2: Channels := 3;
  3: Channels := 1;
  4: Channels := 2;
  6: Channels := 4;
 Else Goto LDone;
 End;
 { Restriction BitDepth }
 If (ColorType = 2) Or (ColorType = 4) Or (ColorType = 6) Then
  If BitDepth <> 8 Then Goto LDone;
 If (ColorType = 0) Then
  If (BitDepth <> 1) And (BitDepth <> 2) And (BitDepth <> 4) And (BitDepth <> 8) Then Goto LDone;
 If (ColorType = 3) Then Begin
  If (BitDepth <> 1) And (BitDepth <> 2) And (BitDepth <> 4) And (BitDepth <> 8) Then Goto LDone;
  If PltCount = 0 Then Goto LDone;
 End;

 BytesPerPixel := (Channels * BitDepth + 7) Div 8;
 If BytesPerPixel < 1 Then BytesPerPixel := 1;
 RowBytes := (LongInt(PngW) * Channels * BitDepth + 7) Div 8;
 RawSize  := (RowBytes + 1) * PngH;
 If RawSize > LongInt(4) * 1024 * 1024 Then Goto LDone;

 { ---- Decompression zlib : sauter 2 octets d'en-tete ---- }
 GetMem(RawBuf, RawSize);
 If RawBuf = Nil Then Goto LDone;
 DeflPtr := @IDatBuf^[2];
 If Not Inflate(DeflPtr, IDatLen - 2, RawBuf, RawSize) Then Goto LDone;

 { ---- Defiltrage ligne par ligne ---- }
 For Y := 0 To PngH - 1 Do Begin
  LineOff     := LongInt(Y) * (RowBytes + 1);
  PrevLineOff := LineOff - (RowBytes + 1);
  Filter      := RawBuf^[LineOff];
  Case Filter Of
   0: ;
   1: Begin { Sub }
    For I := BytesPerPixel To RowBytes - 1 Do
     RawBuf^[LineOff + 1 + I] :=
      Byte((LongInt(RawBuf^[LineOff + 1 + I]) +
            LongInt(RawBuf^[LineOff + 1 + I - BytesPerPixel])) And 255);
   End;
   2: Begin { Up }
    If Y > 0 Then
     For I := 0 To RowBytes - 1 Do
      RawBuf^[LineOff + 1 + I] :=
       Byte((LongInt(RawBuf^[LineOff + 1 + I]) +
             LongInt(RawBuf^[PrevLineOff + 1 + I])) And 255);
   End;
   3: Begin { Average }
    For I := 0 To RowBytes - 1 Do Begin
     If I >= BytesPerPixel Then A := RawBuf^[LineOff + 1 + I - BytesPerPixel] Else A := 0;
     If Y > 0 Then BB := RawBuf^[PrevLineOff + 1 + I] Else BB := 0;
     RawBuf^[LineOff + 1 + I] :=
      Byte((LongInt(RawBuf^[LineOff + 1 + I]) + (A + BB) Div 2) And 255);
    End;
   End;
   4: Begin { Paeth }
    For I := 0 To RowBytes - 1 Do Begin
     If I >= BytesPerPixel Then A := RawBuf^[LineOff + 1 + I - BytesPerPixel] Else A := 0;
     If Y > 0 Then BB := RawBuf^[PrevLineOff + 1 + I] Else BB := 0;
     If (Y > 0) And (I >= BytesPerPixel) Then
      CC := RawBuf^[PrevLineOff + 1 + I - BytesPerPixel]
     Else CC := 0;
     Paeth := A + BB - CC;
     Pa := Paeth - A;  If Pa < 0 Then Pa := -Pa;
     Pb := Paeth - BB; If Pb < 0 Then Pb := -Pb;
     Pc := Paeth - CC; If Pc < 0 Then Pc := -Pc;
     If (Pa <= Pb) And (Pa <= Pc) Then Paeth := A
     Else If Pb <= Pc                Then Paeth := BB
     Else                                  Paeth := CC;
     RawBuf^[LineOff + 1 + I] :=
      Byte((LongInt(RawBuf^[LineOff + 1 + I]) + Paeth) And 255);
    End;
   End;
  Else Goto LDone;
  End;
 End;

 { ---- Allocation du slot image + conversion EGA ---- }
 OutSlot := AllocImageSlot(OutW, OutH, Nm);
 If OutSlot = 0 Then Goto LDone;
 Img := Pres.Images[OutSlot];

 { Buffer RGB intermediaire pour dithering Floyd-Steinberg }
 RgbSize := LongInt(OutW) * OutH * 3;
 GetMem(RgbBuf, RgbSize);
 If RgbBuf = Nil Then Goto LDone;

 PxIdx := 0;
 For YY := 0 To OutH - 1 Do Begin
  Y := YY * Step;
  LineOff := LongInt(Y) * (RowBytes + 1) + 1;
  For XX := 0 To OutW - 1 Do Begin
   X := XX * Step;
   Case ColorType Of
    0: Begin { Gris }
     If BitDepth = 8 Then BB := RawBuf^[LineOff + X]
     Else If BitDepth = 4 Then
      BB := (RawBuf^[LineOff + X Div 2] Shr ((1 - (X And 1)) * 4)) And $F
     Else If BitDepth = 2 Then
      BB := (RawBuf^[LineOff + X Div 4] Shr ((3 - (X And 3)) * 2)) And $3
     Else { 1 }
      BB := (RawBuf^[LineOff + X Div 8] Shr (7 - (X And 7))) And $1;
     Case BitDepth Of
      1: BB := BB * 255;
      2: BB := BB * 85;
      4: BB := BB * 17;
     End;
     R := BB; G := BB; B := BB;
    End;
    2: Begin { RGB 8 }
     R := RawBuf^[LineOff + X * 3];
     G := RawBuf^[LineOff + X * 3 + 1];
     B := RawBuf^[LineOff + X * 3 + 2];
    End;
    3: Begin { Paletted }
     If BitDepth = 8 Then PalI := RawBuf^[LineOff + X]
     Else If BitDepth = 4 Then
      PalI := (RawBuf^[LineOff + X Div 2] Shr ((1 - (X And 1)) * 4)) And $F
     Else If BitDepth = 2 Then
      PalI := (RawBuf^[LineOff + X Div 4] Shr ((3 - (X And 3)) * 2)) And $3
     Else
      PalI := (RawBuf^[LineOff + X Div 8] Shr (7 - (X And 7))) And $1;
     If (PalI < 0) Or (PalI >= PltCount) Then PalI := 0;
     R := Plt[PalI].R; G := Plt[PalI].G; B := Plt[PalI].B;
    End;
    4: Begin { Gris + alpha }
     BB := RawBuf^[LineOff + X * 2];
     R := BB; G := BB; B := BB;
    End;
    6: Begin { RGBA }
     R := RawBuf^[LineOff + X * 4];
     G := RawBuf^[LineOff + X * 4 + 1];
     B := RawBuf^[LineOff + X * 4 + 2];
    End;
   Else
    R := 0; G := 0; B := 0;
   End;
   RgbBuf^[PxIdx * 3]     := Byte(R);
   RgbBuf^[PxIdx * 3 + 1] := Byte(G);
   RgbBuf^[PxIdx * 3 + 2] := Byte(B);
   Inc(PxIdx);
  End;
 End;
 DitherRgbToEga(OutW, OutH, RgbBuf, Img^.Pixels);
 Img^.Loaded := True;
 Slot := OutSlot;
 OK := True;

LDone:
 If IDatBuf <> Nil Then FreeMem(IDatBuf, IDatCap);
 If RawBuf  <> Nil Then FreeMem(RawBuf,  RawSize);
 If RgbBuf  <> Nil Then FreeMem(RgbBuf,  RgbSize);
 LoadImagePngMem := OK;
End;

{ ====================================================================== }
{                       DECODEUR JPEG BASELINE (Etape 5C)                }
{ ----------------------------------------------------------------------
   Supporte :
   - SOI/EOI, APPn/COM (sautes), DQT (8-bit/16-bit), DHT, SOF0, SOS, DRI
   - Composantes 1 (gris) ou 3 (YCbCr), subsampling arbitraire (Hi,Vi)
   - Restart markers RST0..RST7 (reset DC + bit buffer)
   - IDCT 2-passes flottant (Single)
   - Byte stuffing FF 00 dans le bitstream
   Pas supporte :
   - Progressive (SOF2), arithmetique, 12-bit, hierarchique
   - Color profiles, EXIF (ignores)
}

Function LoadImageJpegMem(InBuf: Pointer; InSize: LongInt;
                          Const Nm: String; Var Slot: Integer): Boolean;
Type
 TJByteArr = Array[0..1024*1024*16 - 1] Of Byte;
 PJByteArr = ^TJByteArr;
 TBitsCnt  = Array[0..15] Of Byte;
 THuff = Record
  MinCode : Array[1..17] Of LongInt;
  MaxCode : Array[1..17] Of LongInt;
  ValOff  : Array[1..17] Of Integer;
  Vals    : Array[0..255] Of Byte;
  Valid   : Boolean;
 End;
 TJComp = Record
  Id, H, V, Tq, Td, Ta : Integer;
  PlaneW, PlaneH       : LongInt;
  Plane                : PJByteArr;
  PrevDc               : LongInt;
 End;
Const
 JZigzag : Array[0..63] Of Byte =
 ( 0, 1, 8,16, 9, 2, 3,10,
  17,24,32,25,18,11, 4, 5,
  12,19,26,33,40,48,41,34,
  27,20,13, 6, 7,14,21,28,
  35,42,49,56,57,50,43,36,
  29,22,15,23,30,37,44,51,
  58,59,52,45,38,31,39,46,
  53,60,61,54,47,55,62,63);
Label LDoneJ;
Var Src: PJByteArr;
    JPos: LongInt;
    PicW, PicH: Integer;
    NumComp: Integer;
    QTbl: Array[0..3] Of Record
     Have: Boolean; Q: Array[0..63] Of Integer;
    End;
    HT   : Array[0..1, 0..3] Of THuff;
    Comp : Array[0..3] Of TJComp;
    Hmax, Vmax: Integer;
    NumMcuX, NumMcuY: Integer;
    BitBuf: LongInt; BitCnt: Integer;
    EntPos, EntEnd: LongInt;
    Marker: Integer;
    Block: Array[0..63] Of LongInt;
    Tmp64: Array[0..63] Of Single;
    Pixels: Array[0..63] Of LongInt;
    IdctCos: Array[0..7, 0..7] Of Single;
    DecodeOK: Boolean;
    RestartInterval: Integer;
    McuCount: LongInt;
    OK: Boolean;
    i, j, x, y, mx, my, bx, by: Integer;
    SegLen: Integer;
    OutSlot: Integer;
    Img: PImage;
    RR, GG, BB: Integer;
    YV, Cb, Cr: Integer;
    cxc, cyc: Integer;
    PxIdx: LongInt;
    L, K, Total: Integer;
    HCnt: TBitsCnt;
    RgbBuf: PJByteArr;
    RgbSize: LongInt;
    Step, OutW, OutH, XX, YY: Integer;

 Function GetByte: Integer;
 Begin
  If JPos >= InSize Then Begin GetByte := -1; Exit; End;
  GetByte := Src^[JPos]; Inc(JPos);
 End;

 Function GetWord: Integer;
 Var Hi, Lo: Integer;
 Begin
  Hi := GetByte; Lo := GetByte;
  If (Hi < 0) Or (Lo < 0) Then GetWord := -1
  Else GetWord := Hi * 256 + Lo;
 End;

 Procedure InitIdct;
 Var iu, ix: Integer;
 Begin
  For iu := 0 To 7 Do
   For ix := 0 To 7 Do
    If iu = 0 Then
     IdctCos[iu, ix] := 0.70710678 * Cos(((2*ix + 1) * iu * Pi) / 16.0)
    Else
     IdctCos[iu, ix] := Cos(((2*ix + 1) * iu * Pi) / 16.0);
 End;

 Procedure BuildHuff(Var H: THuff; Const Cnt: TBitsCnt);
 Var Code: LongInt; Si, K2, P, LL: Integer;
     HuffSize: Array[0..256] Of Integer;
 Begin
  P := 0;
  For Si := 1 To 16 Do
   For K2 := 1 To Cnt[Si - 1] Do Begin
    HuffSize[P] := Si; Inc(P);
   End;
  HuffSize[P] := 0;
  For LL := 1 To 17 Do Begin
   H.MinCode[LL] := -1; H.MaxCode[LL] := -1; H.ValOff[LL] := 0;
  End;
  Code := 0;
  If P = 0 Then Begin H.Valid := True; Exit; End;
  Si := HuffSize[0];
  K2 := 0;
  While HuffSize[K2] <> 0 Do Begin
   While HuffSize[K2] = Si Do Begin
    If H.MinCode[Si] = -1 Then Begin
     H.MinCode[Si] := Code;
     H.ValOff[Si]  := K2;
    End;
    H.MaxCode[Si] := Code;
    Inc(Code); Inc(K2);
   End;
   If HuffSize[K2] = 0 Then Break;
   Code := Code Shl (HuffSize[K2] - Si);
   Si   := HuffSize[K2];
  End;
  H.Valid := True;
 End;

 Function GetBit: Integer;
 Var b, b2: Integer;
 Begin
  If BitCnt = 0 Then Begin
   If EntPos >= EntEnd Then Begin GetBit := -1; Exit; End;
   b := Src^[EntPos]; Inc(EntPos);
   If b = $FF Then Begin
    If EntPos >= EntEnd Then Begin GetBit := -1; Exit; End;
    b2 := Src^[EntPos]; Inc(EntPos);
    If b2 <> $00 Then Begin
     Dec(EntPos, 2);
     Marker := b2;
     GetBit := -1; Exit;
    End;
   End;
   BitBuf := b; BitCnt := 8;
  End;
  GetBit := (BitBuf Shr 7) And 1;
  BitBuf := (BitBuf Shl 1) And $FF;
  Dec(BitCnt);
 End;

 Function GetBitsN(N: Integer): LongInt;
 Var R: LongInt; ii: Integer; b1: Integer;
 Begin
  R := 0;
  For ii := 1 To N Do Begin
   b1 := GetBit;
   If b1 < 0 Then Begin DecodeOK := False; GetBitsN := 0; Exit; End;
   R := (R Shl 1) Or b1;
  End;
  GetBitsN := R;
 End;

 Function HuffDecode(Var H: THuff): Integer;
 Var Code: LongInt; LL: Integer; b1: Integer;
 Begin
  HuffDecode := -1;
  b1 := GetBit; If b1 < 0 Then Begin DecodeOK := False; Exit; End;
  Code := b1;
  For LL := 1 To 16 Do Begin
   If (H.MaxCode[LL] >= 0) And (Code <= H.MaxCode[LL]) Then Begin
    HuffDecode := H.Vals[H.ValOff[LL] + (Code - H.MinCode[LL])];
    Exit;
   End;
   b1 := GetBit; If b1 < 0 Then Begin DecodeOK := False; Exit; End;
   Code := (Code Shl 1) Or b1;
  End;
  DecodeOK := False;
 End;

 Function Extend(V: LongInt; T: Integer): LongInt;
 Var Vt: LongInt;
 Begin
  If T = 0 Then Begin Extend := 0; Exit; End;
  Vt := LongInt(1) Shl (T - 1);
  If V < Vt Then Extend := V + (LongInt(-1) Shl T) + 1
  Else            Extend := V;
 End;

 Procedure Idct8x8;
 Var iu, iv, ix, iy: Integer; ss: Single;
 Begin
  For iv := 0 To 7 Do
   For ix := 0 To 7 Do Begin
    ss := 0.0;
    For iu := 0 To 7 Do ss := ss + IdctCos[iu, ix] * Block[iv*8 + iu];
    Tmp64[iv*8 + ix] := ss;
   End;
  For ix := 0 To 7 Do
   For iy := 0 To 7 Do Begin
    ss := 0.0;
    For iv := 0 To 7 Do ss := ss + IdctCos[iv, iy] * Tmp64[iv*8 + ix];
    Pixels[iy*8 + ix] := Round(ss / 4.0);
   End;
 End;

 Function DecodeBlock(CompIdx: Integer): Boolean;
 Var T, RS, Ss4, Rr4, KK: Integer; Diff, V2: LongInt; ii: Integer;
 Begin
  DecodeBlock := False;
  For ii := 0 To 63 Do Block[ii] := 0;
  T := HuffDecode(HT[0, Comp[CompIdx].Td]);
  If T < 0 Then Exit;
  Diff := Extend(GetBitsN(T), T);
  If Not DecodeOK Then Exit;
  Block[0] := Comp[CompIdx].PrevDc + Diff;
  Comp[CompIdx].PrevDc := Block[0];
  KK := 1;
  While KK <= 63 Do Begin
   RS := HuffDecode(HT[1, Comp[CompIdx].Ta]);
   If RS < 0 Then Exit;
   Ss4 := RS And $F;
   Rr4 := RS Shr 4;
   If Ss4 = 0 Then Begin
    If Rr4 = 15 Then Begin Inc(KK, 16); Continue; End
    Else Break;
   End;
   Inc(KK, Rr4);
   If KK > 63 Then Exit;
   V2 := Extend(GetBitsN(Ss4), Ss4);
   If Not DecodeOK Then Exit;
   Block[JZigzag[KK]] := V2;
   Inc(KK);
  End;
  For ii := 0 To 63 Do Block[ii] := Block[ii] * QTbl[Comp[CompIdx].Tq].Q[ii];
  Idct8x8;
  For ii := 0 To 63 Do Begin
   V2 := Pixels[ii] + 128;
   If V2 < 0 Then V2 := 0 Else If V2 > 255 Then V2 := 255;
   Pixels[ii] := V2;
  End;
  DecodeBlock := True;
 End;

 Procedure WriteBlockToPlane(CompIdx, BlockX, BlockY: Integer);
 Var iy, ix: Integer; Off: LongInt;
 Begin
  For iy := 0 To 7 Do Begin
   Off := LongInt(BlockY * 8 + iy) * Comp[CompIdx].PlaneW + BlockX * 8;
   If Off + 8 > Comp[CompIdx].PlaneW * Comp[CompIdx].PlaneH Then Exit;
   For ix := 0 To 7 Do
    Comp[CompIdx].Plane^[Off + ix] := Byte(Pixels[iy*8 + ix]);
  End;
 End;

Begin
 LoadImageJpegMem := False;
 Slot := 0;
 OK := False;
 DecodeOK := True;
 RestartInterval := 0;
 McuCount := 0;
 BitBuf := 0; BitCnt := 0;
 RgbBuf := Nil; RgbSize := 0;
 PicLog('JPEG decode "' + Nm + '" InSize=' + PicLS(InSize));
 For i := 0 To 3 Do Begin
  QTbl[i].Have := False;
  Comp[i].Plane := Nil;
  Comp[i].PlaneW := 0; Comp[i].PlaneH := 0;
  Comp[i].PrevDc := 0;
  HT[0, i].Valid := False;
  HT[1, i].Valid := False;
 End;
 If InSize < 4 Then Exit;
 Src := PJByteArr(InBuf);
 If (Src^[0] <> $FF) Or (Src^[1] <> $D8) Then Exit;
 JPos := 2; PicW := 0; PicH := 0; NumComp := 0; Marker := 0;

 InitIdct;

 { ---- Parcours des markers jusqu'a SOS ---- }
 While JPos + 1 < InSize Do Begin
  If Src^[JPos] <> $FF Then Begin Inc(JPos); Continue; End;
  While (JPos < InSize) And (Src^[JPos] = $FF) Do Inc(JPos);
  If JPos >= InSize Then Goto LDoneJ;
  Marker := Src^[JPos]; Inc(JPos);
  If Marker = $D9 Then Goto LDoneJ;
  If Marker = $00 Then Continue;
  If Marker = $DB Then Begin                           { DQT }
   SegLen := GetWord; If SegLen < 2 Then Goto LDoneJ;
   SegLen := SegLen - 2;
   While SegLen > 0 Do Begin
    i := GetByte; If i < 0 Then Goto LDoneJ;
    Dec(SegLen);
    L := i And $F;
    j := i Shr 4;
    If (L > 3) Or (j > 1) Then Goto LDoneJ;
    If j = 0 Then Begin
     If SegLen < 64 Then Goto LDoneJ;
     For i := 0 To 63 Do
      QTbl[L].Q[JZigzag[i]] := Src^[JPos + i];
     Inc(JPos, 64); Dec(SegLen, 64);
    End Else Begin
     If SegLen < 128 Then Goto LDoneJ;
     For i := 0 To 63 Do
      QTbl[L].Q[JZigzag[i]] := Src^[JPos + i*2] * 256 + Src^[JPos + i*2 + 1];
     Inc(JPos, 128); Dec(SegLen, 128);
    End;
    QTbl[L].Have := True;
   End;
   Continue;
  End;
  If Marker = $C4 Then Begin                           { DHT }
   SegLen := GetWord; If SegLen < 2 Then Goto LDoneJ;
   SegLen := SegLen - 2;
   While SegLen > 17 Do Begin
    i := GetByte; If i < 0 Then Goto LDoneJ;
    Dec(SegLen);
    L := i And $F;
    j := i Shr 4;
    If (L > 3) Or (j > 1) Then Goto LDoneJ;
    Total := 0;
    For K := 0 To 15 Do Begin
     HCnt[K] := Src^[JPos + K]; Inc(Total, HCnt[K]);
    End;
    Inc(JPos, 16); Dec(SegLen, 16);
    If (Total > 256) Or (SegLen < Total) Then Goto LDoneJ;
    For K := 0 To Total - 1 Do HT[j, L].Vals[K] := Src^[JPos + K];
    Inc(JPos, Total); Dec(SegLen, Total);
    BuildHuff(HT[j, L], HCnt);
   End;
   Continue;
  End;
  If Marker = $C0 Then Begin                           { SOF0 baseline }
   SegLen := GetWord; If SegLen < 8 Then Goto LDoneJ;
   i := GetByte;
   If i <> 8 Then Goto LDoneJ;
   PicH := GetWord;
   PicW := GetWord;
   NumComp := GetByte;
   If (NumComp <> 1) And (NumComp <> 3) Then Goto LDoneJ;
   For i := 1 To NumComp Do Begin
    Comp[i].Id := GetByte;
    j := GetByte;
    Comp[i].H  := j Shr 4;
    Comp[i].V  := j And $F;
    Comp[i].Tq := GetByte;
    If (Comp[i].H < 1) Or (Comp[i].H > 4) Or
       (Comp[i].V < 1) Or (Comp[i].V > 4) Then Goto LDoneJ;
   End;
   Continue;
  End;
  If (Marker = $C1) Or (Marker = $C2) Or (Marker = $C3) Or
     ((Marker >= $C5) And (Marker <= $CF) And (Marker <> $C8)) Then Begin
   { Autres modes DCT (extended, progressive, lossless, hierarchique) -> non supporte }
   Goto LDoneJ;
  End;
  If Marker = $DD Then Begin                           { DRI }
   SegLen := GetWord; If SegLen <> 4 Then Goto LDoneJ;
   RestartInterval := GetWord;
   Continue;
  End;
  If Marker = $DA Then Begin                           { SOS }
   SegLen := GetWord; If SegLen < 6 Then Goto LDoneJ;
   i := GetByte;
   If i <> NumComp Then Goto LDoneJ;
   For i := 1 To NumComp Do Begin
    j := GetByte;
    If j <> Comp[i].Id Then Goto LDoneJ;
    L := GetByte;
    Comp[i].Td := L Shr 4;
    Comp[i].Ta := L And $F;
   End;
   GetByte; GetByte; GetByte;
   Break;
  End;
  If (Marker >= $D0) And (Marker <= $D7) Then Continue;
  If Marker = $01 Then Continue;
  { Autres markers (APPn, COM, ...) : segment avec longueur }
  SegLen := GetWord;
  If SegLen < 2 Then Goto LDoneJ;
  Inc(JPos, SegLen - 2);
 End;

 { ---- Validations ---- }
 PicLog('  JPEG SOF: ' + PicLS(PicW) + 'x' + PicLS(PicH) + ' Comp=' + PicLS(NumComp));
 If (PicW <= 0) Or (PicH <= 0) Then Goto LDoneJ;
 If (PicW > 4096) Or (PicH > 4096) Then Goto LDoneJ;
 { Sous-echantillonnage pour borner la sortie EGA }
 Step := 1;
 While LongInt(PicW Div Step) * (PicH Div Step) > 200000 Do Inc(Step);
 OutW := PicW Div Step; If OutW < 1 Then OutW := 1;
 OutH := PicH Div Step; If OutH < 1 Then OutH := 1;
 PicLog('  JPEG step=' + PicLS(Step) + ' out=' + PicLS(OutW) + 'x' + PicLS(OutH));
 Hmax := 0; Vmax := 0;
 For i := 1 To NumComp Do Begin
  If Comp[i].H > Hmax Then Hmax := Comp[i].H;
  If Comp[i].V > Vmax Then Vmax := Comp[i].V;
 End;
 If (Hmax = 0) Or (Vmax = 0) Then Goto LDoneJ;
 NumMcuX := (PicW + Hmax * 8 - 1) Div (Hmax * 8);
 NumMcuY := (PicH + Vmax * 8 - 1) Div (Vmax * 8);
 For i := 1 To NumComp Do Begin
  Comp[i].PlaneW := LongInt(NumMcuX) * Comp[i].H * 8;
  Comp[i].PlaneH := LongInt(NumMcuY) * Comp[i].V * 8;
  If Comp[i].PlaneW * Comp[i].PlaneH > LongInt(2) * 1024 * 1024 Then Goto LDoneJ;
  GetMem(Comp[i].Plane, Comp[i].PlaneW * Comp[i].PlaneH);
  If Comp[i].Plane = Nil Then Goto LDoneJ;
  Comp[i].PrevDc := 0;
 End;

 { ---- Decode du scan ---- }
 BitBuf := 0; BitCnt := 0;
 EntPos := JPos; EntEnd := InSize;
 McuCount := 0;
 For my := 0 To NumMcuY - 1 Do
  For mx := 0 To NumMcuX - 1 Do Begin
   For i := 1 To NumComp Do
    For by := 0 To Comp[i].V - 1 Do
     For bx := 0 To Comp[i].H - 1 Do Begin
      If Not DecodeBlock(i) Then Goto LDoneJ;
      WriteBlockToPlane(i, mx * Comp[i].H + bx, my * Comp[i].V + by);
     End;
   Inc(McuCount);
   If (RestartInterval > 0) And ((McuCount Mod RestartInterval) = 0) And
      Not ((mx = NumMcuX - 1) And (my = NumMcuY - 1)) Then Begin
    BitCnt := 0; BitBuf := 0;
    If (EntPos + 1 < EntEnd) And (Src^[EntPos] = $FF) And
       (Src^[EntPos + 1] >= $D0) And (Src^[EntPos + 1] <= $D7) Then
     Inc(EntPos, 2);
    For i := 1 To NumComp Do Comp[i].PrevDc := 0;
   End;
  End;

 { ---- YCbCr -> RGB -> EGA ---- }
 OutSlot := AllocImageSlot(OutW, OutH, Nm);
 If OutSlot = 0 Then Goto LDoneJ;
 Img := Pres.Images[OutSlot];
 RgbSize := LongInt(OutW) * OutH * 3;
 GetMem(RgbBuf, RgbSize);
 If RgbBuf = Nil Then Goto LDoneJ;
 PxIdx := 0;
 For YY := 0 To OutH - 1 Do Begin
  y := YY * Step;
  For XX := 0 To OutW - 1 Do Begin
   x := XX * Step;
   YV := Comp[1].Plane^[LongInt(y) * Comp[1].PlaneW + x];
   If NumComp = 3 Then Begin
    cxc := (x * Comp[2].H) Div Hmax;
    cyc := (y * Comp[2].V) Div Vmax;
    Cb  := Comp[2].Plane^[LongInt(cyc) * Comp[2].PlaneW + cxc];
    cxc := (x * Comp[3].H) Div Hmax;
    cyc := (y * Comp[3].V) Div Vmax;
    Cr  := Comp[3].Plane^[LongInt(cyc) * Comp[3].PlaneW + cxc];
    RR := YV + ((1402 * (Cr - 128)) Div 1000);
    GG := YV - ((344 * (Cb - 128) + 714 * (Cr - 128)) Div 1000);
    BB := YV + ((1772 * (Cb - 128)) Div 1000);
    If RR < 0 Then RR := 0 Else If RR > 255 Then RR := 255;
    If GG < 0 Then GG := 0 Else If GG > 255 Then GG := 255;
    If BB < 0 Then BB := 0 Else If BB > 255 Then BB := 255;
   End Else Begin
    RR := YV; GG := YV; BB := YV;
   End;
   RgbBuf^[PxIdx * 3]     := Byte(RR);
   RgbBuf^[PxIdx * 3 + 1] := Byte(GG);
   RgbBuf^[PxIdx * 3 + 2] := Byte(BB);
   Inc(PxIdx);
  End;
 End;
 DitherRgbToEga(OutW, OutH, RgbBuf, Img^.Pixels);
 Img^.Loaded := True;
 Slot := OutSlot;
 OK := True;

LDoneJ:
 For i := 1 To 3 Do
  If Comp[i].Plane <> Nil Then
   FreeMem(Comp[i].Plane, Comp[i].PlaneW * Comp[i].PlaneH);
 If RgbBuf <> Nil Then FreeMem(RgbBuf, RgbSize);
 LoadImageJpegMem := OK;
End;

{ ----- Lecteur .PPTX (STORED + DEFLATE) ---------------------------------- }
{ On scrute les Local File Headers en sequence, on extrait <a:t>...</a:t>   }
{ depuis les fichiers ppt/slides/slide*.xml.                                }

Function LoadPPTX(Const FN: String): Boolean;
Const MAX_PPTX_SLIDES  = 256;
      MAX_PPTX_LAYOUTS = 64;
      MAX_PPTX_MEDIA   = 80;
      MAX_PPTX_RELS    = 32;
      EOCD_SCAN_MAX    = 65557;
      IMG_FMT_OTHER    = 0;
      IMG_FMT_PNG      = 1;
      IMG_FMT_JPEG     = 2;
Type
 TSlideEnt = Record
  LfhOff   : LongInt;
  CSize    : LongInt;
  USize    : LongInt;
  Mth      : Word;
  SlideNum : Integer;
 End;
 TLayoutEnt = Record
  LfhOff : LongInt;
  CSize  : LongInt;
  USize  : LongInt;
  Mth    : Word;
 End;
 TMediaEnt = Record
  LfhOff : LongInt;
  CSize  : LongInt;
  USize  : LongInt;
  Mth    : Word;
  FName  : String[24];     { p.ex. "image50.jpeg" }
  Format : Byte;           { IMG_FMT_PNG/JPEG/OTHER }
 End;
 TSlideRelEnt = Record
  LfhOff : LongInt;
  CSize  : LongInt;
  USize  : LongInt;
  Mth    : Word;
 End;
 TSlideRelMap = Record
  RId      : String[8];     { p.ex. "rId5" }
  MediaIdx : Integer;       { index dans MediaEnts ou 0 }
 End;
 TPhDefault = Record
  HasColor : Boolean; Color    : Byte;
  HasSize  : Boolean; Sz       : Integer;
  Bold, Italic, Underline : Boolean;
 End;
Var F: File;
    FSize, EocdPos, CdOff, CdSize: LongInt;
    TotalEnt, EI: Integer;
    Sig: LongInt;
    ScanBuf: ^Byte;
    ScanLen: LongInt;
    ScanByte: ^Byte;
    DiagStr: String;
    K, II, JJ: LongInt;
    SlideEnts: Array[1..MAX_PPTX_SLIDES] Of TSlideEnt;
    SlideCnt, SlideIdx: Integer;
    EntName: String;
    Mth, Flg, NameLen, ExtraLen, CommentLen: Word;
    CSize, USize: LongInt;
    LfhOff: LongInt;
    SlNum, ValErr: Integer;
    NumStr, NameTmp: String;
    XmlBuf, CompBuf: Pointer;
    BufSize, P, Q, ChI: LongInt;
    TmpEnt: TSlideEnt;
    NewSl: PSlide; NewSh, BodyShape: PShape;
    Line, StartTag, EndTag: String;
    InTitle: Boolean;
    LineCount: Integer;
    SkippedCompressed, FoundSlide: Integer;
    PresLfhOff, PresCs, PresUs: LongInt;
    PresMth: Word;
    HasPres: Boolean;
    PresCx, PresCy: LongInt;
    ThemeLfhOff, ThemeCs, ThemeUs: LongInt;
    ThemeMth: Word;
    HasTheme: Boolean;
    ThemeRGB: Array[1..12] Of String;
    LayoutEnts: Array[1..MAX_PPTX_LAYOUTS] Of TLayoutEnt;
    LayoutCnt: Integer;
    PhDefaults: Array[1..4] Of TPhDefault;
    LI: Integer;
    MediaEnts: Array[1..MAX_PPTX_MEDIA] Of TMediaEnt;
    MediaCnt: Integer;
    SlideRelsEnts: Array[1..MAX_PPTX_SLIDES] Of TSlideRelEnt;
    HasSlideRels : Array[1..MAX_PPTX_SLIDES] Of Boolean;
    CurSlideRels: Array[1..MAX_PPTX_RELS] Of TSlideRelMap;
    CurSlideRelsCnt: Integer;
    MediaSlots: Array[1..MAX_PPTX_MEDIA] Of Integer; { 0=non charge, -1=echec, >0=slot }

 Function PtrToByteAt(Off: LongInt): Byte;
 Var Ptr: ^Byte;
 Begin
  Ptr := XmlBuf; Inc(Ptr, Off); PtrToByteAt := Ptr^;
 End;

 Function MatchAt(Off: LongInt; Const Tag: String): Boolean;
 Var L: Integer;
 Begin
  MatchAt := False;
  If Off + Length(Tag) > BufSize Then Exit;
  For L := 1 To Length(Tag) Do
   If Char(PtrToByteAt(Off + L - 1)) <> Tag[L] Then Exit;
  MatchAt := True;
 End;

 Procedure PptxLog(Const S: String);
 Var LF: Text;
 Begin
  Assign(LF, 'POWERPNT.LOG');
  {$I-} Append(LF); {$I+}
  If IOResult <> 0 Then Begin {$I-} Rewrite(LF); {$I+} If IOResult <> 0 Then Exit; End;
  WriteLn(LF, S);
  Close(LF);
 End;

 Function LStr(L: LongInt): String;
 Var T: String;
 Begin Str(L, T); LStr := T; End;

 { ---- Helpers parsing XML PPTX (etape 1-3: style, couleur, position) ---- }

 Function PptxFindStr(StartPos, MaxPos: LongInt; Const S: String): LongInt;
 Var I, J, SL: LongInt; OK: Boolean;
 Begin
  PptxFindStr := -1;
  SL := Length(S);
  If (SL <= 0) Or (MaxPos > BufSize) Then MaxPos := BufSize;
  I := StartPos;
  While I + SL <= MaxPos Do Begin
   OK := True;
   For J := 1 To SL Do
    If Char(PtrToByteAt(I + J - 1)) <> S[J] Then Begin OK := False; Break; End;
   If OK Then Begin PptxFindStr := I; Exit; End;
   Inc(I);
  End;
 End;

 Function PptxFindCharFrom(StartPos, MaxPos: LongInt; C: Char): LongInt;
 Var I: LongInt;
 Begin
  PptxFindCharFrom := -1;
  If MaxPos > BufSize Then MaxPos := BufSize;
  I := StartPos;
  While I < MaxPos Do Begin
   If Char(PtrToByteAt(I)) = C Then Begin PptxFindCharFrom := I; Exit; End;
   Inc(I);
  End;
 End;

 Function PptxReadAttr(TagOpenPos: LongInt; Const AttrName: String): String;
 Var EndTagPos, P, L, K: LongInt;
     Quote: Char; R: String; AL: Integer; OK: Boolean;
 Begin
  PptxReadAttr := '';
  EndTagPos := PptxFindCharFrom(TagOpenPos, BufSize, '>');
  If EndTagPos < 0 Then Exit;
  AL := Length(AttrName);
  P := TagOpenPos + 1;
  While P + AL + 2 < EndTagPos Do Begin
   If Char(PtrToByteAt(P - 1)) <= ' ' Then Begin
    OK := True;
    For K := 1 To AL Do
     If Char(PtrToByteAt(P + K - 1)) <> AttrName[K] Then Begin OK := False; Break; End;
    If OK And (Char(PtrToByteAt(P + AL)) = '=') Then Begin
     Quote := Char(PtrToByteAt(P + AL + 1));
     If (Quote = '"') Or (Quote = '''') Then Begin
      L := P + AL + 2; R := '';
      While (L < EndTagPos) And (Char(PtrToByteAt(L)) <> Quote) Do Begin
       If Length(R) < 64 Then R := R + Char(PtrToByteAt(L));
       Inc(L);
      End;
      PptxReadAttr := R; Exit;
     End;
    End;
   End;
   Inc(P);
  End;
 End;

 Function PptxStrToLI(Const S: String): LongInt;
 Var Code: Integer; V: LongInt;
 Begin
  Val(S, V, Code);
  If Code <> 0 Then V := 0;
  PptxStrToLI := V;
 End;

 Function EmuX(E: LongInt): Integer;
 Begin
  If E <= 0 Then EmuX := 0
  Else If E >= PresCx Then EmuX := 1000
  Else EmuX := Round(E * 1000.0 / PresCx);
 End;

 Function EmuY(E: LongInt): Integer;
 Begin
  If E <= 0 Then EmuY := 0
  Else If E >= PresCy Then EmuY := 750
  Else EmuY := Round(E * 750.0 / PresCy);
 End;

 Function HexCharVal(C: Char): Integer;
 Begin
  Case C Of
   '0'..'9': HexCharVal := Ord(C) - Ord('0');
   'a'..'f': HexCharVal := 10 + Ord(C) - Ord('a');
   'A'..'F': HexCharVal := 10 + Ord(C) - Ord('A');
  Else HexCharVal := 0;
  End;
 End;

 Function RgbToEga(Const Hex: String): Byte;
 Const PalR: Array[0..15] Of Integer =
        (0,  0,  0,  0,  170,170,170,170, 85, 85, 85, 85, 255,255,255,255);
       PalG: Array[0..15] Of Integer =
        (0,  0,  170,170,0,  0,  85, 170, 85, 85, 255,255, 85, 85, 255,255);
       PalB: Array[0..15] Of Integer =
        (0,  170,0,  170,0,  170,0,  170, 85, 255,85, 255, 85, 255,85, 255);
 Var R, G, B, I, Best: Integer;
     D, BestD: LongInt;
     DR, DG, DB: Integer;
 Begin
  RgbToEga := CLR_BLACK;
  If Length(Hex) < 6 Then Exit;
  R := HexCharVal(Hex[1]) * 16 + HexCharVal(Hex[2]);
  G := HexCharVal(Hex[3]) * 16 + HexCharVal(Hex[4]);
  B := HexCharVal(Hex[5]) * 16 + HexCharVal(Hex[6]);
  Best := 0; BestD := 1000000;
  For I := 0 To 15 Do Begin
   DR := R - PalR[I]; DG := G - PalG[I]; DB := B - PalB[I];
   D := LongInt(DR)*DR + LongInt(DG)*DG + LongInt(DB)*DB;
   If D < BestD Then Begin BestD := D; Best := I; End;
  End;
  RgbToEga := Byte(Best);
 End;

 Function MapCp437(CP: LongInt): Char;
 Begin
  Case CP Of
   $00A0: MapCp437 := #$FF;  { NBSP }
   $00A1: MapCp437 := #$AD;  { ¡ }
   $00A2: MapCp437 := #$9B;  { ¢ }
   $00A3: MapCp437 := #$9C;  { £ }
   $00A5: MapCp437 := #$9D;  { ¥ }
   $00AA: MapCp437 := #$A6;  { ª }
   $00AB: MapCp437 := #$AE;  { « }
   $00BA: MapCp437 := #$A7;  { º }
   $00BB: MapCp437 := #$AF;  { » }
   $00BC: MapCp437 := #$AC;  { ¼ }
   $00BD: MapCp437 := #$AB;  { ½ }
   $00BF: MapCp437 := #$A8;  { ¿ }
   $00B0: MapCp437 := #$F8;  { ° }
   $00B1: MapCp437 := #$F1;  { ± }
   $00B2: MapCp437 := #$FD;  { ² }
   $00B5: MapCp437 := #$E6;  { µ }
   $00B7: MapCp437 := #$FA;  { · }
   $00C0: MapCp437 := 'A';
   $00C1: MapCp437 := 'A';
   $00C2: MapCp437 := 'A';
   $00C3: MapCp437 := 'A';
   $00C4: MapCp437 := #$8E;  { Ä }
   $00C5: MapCp437 := #$8F;  { Å }
   $00C6: MapCp437 := #$92;  { Æ }
   $00C7: MapCp437 := #$80;  { Ç }
   $00C8: MapCp437 := 'E';
   $00C9: MapCp437 := #$90;  { É }
   $00CA: MapCp437 := 'E';
   $00CB: MapCp437 := 'E';
   $00CC: MapCp437 := 'I';
   $00CD: MapCp437 := 'I';
   $00CE: MapCp437 := 'I';
   $00CF: MapCp437 := 'I';
   $00D1: MapCp437 := #$A5;  { Ñ }
   $00D2: MapCp437 := 'O';
   $00D3: MapCp437 := 'O';
   $00D4: MapCp437 := 'O';
   $00D5: MapCp437 := 'O';
   $00D6: MapCp437 := #$99;  { Ö }
   $00D9: MapCp437 := 'U';
   $00DA: MapCp437 := 'U';
   $00DB: MapCp437 := 'U';
   $00DC: MapCp437 := #$9A;  { Ü }
   $00DF: MapCp437 := #$E1;  { ß }
   $00E0: MapCp437 := #$85;  { à }
   $00E1: MapCp437 := #$A0;  { á }
   $00E2: MapCp437 := #$83;  { â }
   $00E3: MapCp437 := 'a';
   $00E4: MapCp437 := #$84;  { ä }
   $00E5: MapCp437 := #$86;  { å }
   $00E6: MapCp437 := #$91;  { æ }
   $00E7: MapCp437 := #$87;  { ç }
   $00E8: MapCp437 := #$8A;  { è }
   $00E9: MapCp437 := #$82;  { é }
   $00EA: MapCp437 := #$88;  { ê }
   $00EB: MapCp437 := #$89;  { ë }
   $00EC: MapCp437 := #$8D;  { ì }
   $00ED: MapCp437 := #$A1;  { í }
   $00EE: MapCp437 := #$8C;  { î }
   $00EF: MapCp437 := #$8B;  { ï }
   $00F1: MapCp437 := #$A4;  { ñ }
   $00F2: MapCp437 := #$95;  { ò }
   $00F3: MapCp437 := #$A2;  { ó }
   $00F4: MapCp437 := #$93;  { ô }
   $00F5: MapCp437 := 'o';
   $00F6: MapCp437 := #$94;  { ö }
   $00F7: MapCp437 := #$F6;  { ÷ }
   $00F9: MapCp437 := #$97;  { ù }
   $00FA: MapCp437 := #$A3;  { ú }
   $00FB: MapCp437 := #$96;  { û }
   $00FC: MapCp437 := #$81;  { ü }
   $00FF: MapCp437 := #$98;  { ÿ }
   $2013: MapCp437 := '-';   { – }
   $2014: MapCp437 := '-';   { — }
   $2018: MapCp437 := '''';  { ' }
   $2019: MapCp437 := '''';  { ' }
   $201A: MapCp437 := ',';
   $201C: MapCp437 := '"';   { " }
   $201D: MapCp437 := '"';   { " }
   $2022: MapCp437 := #$07;  { • -> bullet }
   $2026: MapCp437 := '.';   { … }
   $20AC: MapCp437 := 'E';   { € (CP437 n'a pas euro) }
  Else
   If (CP >= 32) And (CP < 127) Then MapCp437 := Char(CP)
   Else MapCp437 := '?';
  End;
 End;

 Function Utf8ToCp437(Const S: String): String;
 Var R: String; I, L: Integer; B, B2, B3: Byte; CP: LongInt;
 Begin
  R := ''; I := 1; L := Length(S);
  While I <= L Do Begin
   B := Byte(S[I]);
   If B < $80 Then Begin
    R := R + Char(B); Inc(I);
   End Else If (B And $E0) = $C0 Then Begin
    If I + 1 <= L Then Begin
     B2 := Byte(S[I+1]);
     CP := (LongInt(B And $1F) Shl 6) Or (B2 And $3F);
     R := R + MapCp437(CP); Inc(I, 2);
    End Else Begin R := R + '?'; Inc(I); End;
   End Else If (B And $F0) = $E0 Then Begin
    If I + 2 <= L Then Begin
     B2 := Byte(S[I+1]); B3 := Byte(S[I+2]);
     CP := (LongInt(B And $0F) Shl 12) Or (LongInt(B2 And $3F) Shl 6) Or (B3 And $3F);
     R := R + MapCp437(CP); Inc(I, 3);
    End Else Begin R := R + '?'; Inc(I); End;
   End Else If (B And $F8) = $F0 Then Begin
    If I + 3 <= L Then Begin R := R + '?'; Inc(I, 4); End
    Else Begin R := R + '?'; Inc(I); End;
   End Else Begin
    R := R + '?'; Inc(I);
   End;
  End;
  Utf8ToCp437 := R;
 End;

 Function DecodeEntities(Const S: String): String;
 Var R: String; I, J: Integer; CP: LongInt; Hex: Boolean; Ch: Char;
 Begin
  R := ''; I := 1;
  While I <= Length(S) Do Begin
   If (S[I] = '&') And (I + 3 <= Length(S)) Then Begin
    If Copy(S, I, 5) = '&amp;'  Then Begin R := R + '&';  Inc(I, 5); Continue; End;
    If Copy(S, I, 4) = '&lt;'   Then Begin R := R + '<';  Inc(I, 4); Continue; End;
    If Copy(S, I, 4) = '&gt;'   Then Begin R := R + '>';  Inc(I, 4); Continue; End;
    If (I + 5 <= Length(S)) And (Copy(S, I, 6) = '&quot;') Then Begin R := R + '"';  Inc(I, 6); Continue; End;
    If (I + 5 <= Length(S)) And (Copy(S, I, 6) = '&apos;') Then Begin R := R + ''''; Inc(I, 6); Continue; End;
    If (I + 2 <= Length(S)) And (S[I+1] = '#') Then Begin
     J := I + 2; Hex := False;
     If (J <= Length(S)) And ((S[J] = 'x') Or (S[J] = 'X')) Then Begin Hex := True; Inc(J); End;
     CP := 0;
     While (J <= Length(S)) And (S[J] <> ';') Do Begin
      Ch := S[J];
      If Hex Then Begin
       If      (Ch >= '0') And (Ch <= '9') Then CP := CP * 16 + (Ord(Ch) - Ord('0'))
       Else If (Ch >= 'a') And (Ch <= 'f') Then CP := CP * 16 + (Ord(Ch) - Ord('a') + 10)
       Else If (Ch >= 'A') And (Ch <= 'F') Then CP := CP * 16 + (Ord(Ch) - Ord('A') + 10)
       Else Break;
      End Else Begin
       If (Ch >= '0') And (Ch <= '9') Then CP := CP * 10 + (Ord(Ch) - Ord('0'))
       Else Break;
      End;
      Inc(J);
     End;
     If (J <= Length(S)) And (S[J] = ';') Then Begin
      R := R + MapCp437(CP); I := J + 1; Continue;
     End;
    End;
   End;
   R := R + S[I]; Inc(I);
  End;
  DecodeEntities := R;
 End;

 Function ExtractTextBetween(SP, EP: LongInt): String;
 Var P: LongInt; R: String;
 Begin
  R := ''; P := SP;
  While (P < EP) And (Length(R) < 240) Do Begin
   R := R + Char(PtrToByteAt(P)); Inc(P);
  End;
  ExtractTextBetween := Utf8ToCp437(DecodeEntities(R));
 End;

 Function SchemeIdx(Const Name: String): Integer;
 Var N: String;
 Begin
  N := Name;
  If      N = 'dk1'      Then SchemeIdx := 1
  Else If N = 'tx1'      Then SchemeIdx := 1
  Else If N = 'lt1'      Then SchemeIdx := 2
  Else If N = 'bg1'      Then SchemeIdx := 2
  Else If N = 'dk2'      Then SchemeIdx := 3
  Else If N = 'tx2'      Then SchemeIdx := 3
  Else If N = 'lt2'      Then SchemeIdx := 4
  Else If N = 'bg2'      Then SchemeIdx := 4
  Else If N = 'accent1'  Then SchemeIdx := 5
  Else If N = 'accent2'  Then SchemeIdx := 6
  Else If N = 'accent3'  Then SchemeIdx := 7
  Else If N = 'accent4'  Then SchemeIdx := 8
  Else If N = 'accent5'  Then SchemeIdx := 9
  Else If N = 'accent6'  Then SchemeIdx := 10
  Else If N = 'hlink'    Then SchemeIdx := 11
  Else If N = 'folHlink' Then SchemeIdx := 12
  Else SchemeIdx := 0;
 End;

 Function PhBucket(Const PhType: String): Integer;
 Begin
  If      (PhType = 'title') Or (PhType = 'ctrTitle') Then PhBucket := 1
  Else If (PhType = 'subTitle')                       Then PhBucket := 2
  Else If (PhType = 'body')                           Then PhBucket := 3
  Else                                                     PhBucket := 4;
 End;

 Function SchemeRgb(Const Name: String): String;
 Var I: Integer;
 Begin
  I := SchemeIdx(Name);
  If (I >= 1) And (I <= 12) And (ThemeRGB[I] <> '') Then SchemeRgb := ThemeRGB[I]
  Else SchemeRgb := '';
 End;

 Procedure ParseRunProps(RPrPos, RPrLimit: LongInt;
                         Var IsBold, IsItalic, IsUnder: Boolean;
                         Var SzPt: Integer;
                         Var Color: Byte; Var ColorSet: Boolean);
 Var Attr: String;
     CloseSlash, ClosePos, FillPos, SrgbPos, SchemePos: LongInt;
 Begin
  Attr := PptxReadAttr(RPrPos, 'b');
  If Attr = '1' Then IsBold := True;
  Attr := PptxReadAttr(RPrPos, 'i');
  If Attr = '1' Then IsItalic := True;
  Attr := PptxReadAttr(RPrPos, 'u');
  If (Attr <> '') And (Attr <> 'none') Then IsUnder := True;
  Attr := PptxReadAttr(RPrPos, 'sz');
  If Attr <> '' Then SzPt := PptxStrToLI(Attr) Div 100;
  ClosePos := PptxFindCharFrom(RPrPos, RPrLimit, '>');
  If ClosePos < 0 Then Exit;
  CloseSlash := ClosePos - 1;
  If (CloseSlash >= 0) And (Char(PtrToByteAt(CloseSlash)) = '/') Then Exit;
  FillPos := PptxFindStr(ClosePos, RPrLimit, '<a:solidFill');
  If FillPos < 0 Then Exit;
  SrgbPos := PptxFindStr(FillPos, RPrLimit, '<a:srgbClr');
  SchemePos := PptxFindStr(FillPos, RPrLimit, '<a:schemeClr');
  If (SrgbPos >= 0) And ((SchemePos < 0) Or (SrgbPos < SchemePos)) Then Begin
   Attr := PptxReadAttr(SrgbPos, 'val');
   If Length(Attr) >= 6 Then Begin
    Color := RgbToEga(Attr);
    ColorSet := True;
   End;
  End Else If SchemePos >= 0 Then Begin
   Attr := PptxReadAttr(SchemePos, 'val');
   Attr := SchemeRgb(Attr);
   If Length(Attr) >= 6 Then Begin
    Color := RgbToEga(Attr);
    ColorSet := True;
   End;
  End;
 End;

 Procedure ParseLayoutDefaultsFromBuffer;
 Var SpPos, SpEnd, PhPos2, LstPos, LvlPos, LvlEnd, DefPos, DefEnd, DefClose, FillPos, SrgbPos, SchemePos: LongInt;
     PhT, AttrV: String;
     Bk, SzVal: Integer;
     ChI2: Integer;
 Begin
  SpPos := 0;
  Repeat
   SpPos := PptxFindStr(SpPos, BufSize, '<p:sp');
   If SpPos < 0 Then Break;
   If SpPos + 5 < BufSize Then Begin
    ChI2 := PtrToByteAt(SpPos + 5);
    If (ChI2 <> 32) And (ChI2 <> 9) And (ChI2 <> 62) Then Begin
     Inc(SpPos);
     Continue;
    End;
   End;
   SpEnd := PptxFindStr(SpPos, BufSize, '</p:sp>');
   If SpEnd < 0 Then Break;
   PhPos2 := PptxFindStr(SpPos, SpEnd, '<p:ph');
   If PhPos2 >= 0 Then Begin
    PhT := PptxReadAttr(PhPos2, 'type');
    Bk  := PhBucket(PhT);
    LstPos := PptxFindStr(SpPos, SpEnd, '<a:lstStyle');
    If LstPos >= 0 Then Begin
     LvlPos := PptxFindStr(LstPos, SpEnd, '<a:lvl1pPr');
     If LvlPos < 0 Then LvlPos := LstPos;
     LvlEnd := PptxFindStr(LvlPos, SpEnd, '</a:lvl1pPr>');
     If LvlEnd < 0 Then LvlEnd := SpEnd;
     DefPos := PptxFindStr(LvlPos, LvlEnd, '<a:defRPr');
     If DefPos >= 0 Then Begin
      DefClose := PptxFindCharFrom(DefPos, LvlEnd, '>');
      If DefClose < 0 Then DefClose := LvlEnd;
      AttrV := PptxReadAttr(DefPos, 'sz');
      If AttrV <> '' Then Begin
       SzVal := PptxStrToLI(AttrV) Div 100;
       If SzVal >= 8 Then Begin
        PhDefaults[Bk].HasSize := True; PhDefaults[Bk].Sz := SzVal;
       End;
      End;
      AttrV := PptxReadAttr(DefPos, 'b');
      If AttrV = '1' Then PhDefaults[Bk].Bold := True;
      AttrV := PptxReadAttr(DefPos, 'i');
      If AttrV = '1' Then PhDefaults[Bk].Italic := True;
      AttrV := PptxReadAttr(DefPos, 'u');
      If (AttrV <> '') And (AttrV <> 'none') Then PhDefaults[Bk].Underline := True;
      If (DefClose > DefPos) And (Char(PtrToByteAt(DefClose - 1)) <> '/') Then Begin
       DefEnd := PptxFindStr(DefClose, LvlEnd, '</a:defRPr>');
       If DefEnd < 0 Then DefEnd := LvlEnd;
       FillPos := PptxFindStr(DefClose, DefEnd, '<a:solidFill');
       If FillPos >= 0 Then Begin
        SrgbPos   := PptxFindStr(FillPos, DefEnd, '<a:srgbClr');
        SchemePos := PptxFindStr(FillPos, DefEnd, '<a:schemeClr');
        If (SrgbPos >= 0) And ((SchemePos < 0) Or (SrgbPos < SchemePos)) Then Begin
         AttrV := PptxReadAttr(SrgbPos, 'val');
         If Length(AttrV) >= 6 Then Begin
          PhDefaults[Bk].HasColor := True;
          PhDefaults[Bk].Color    := RgbToEga(AttrV);
         End;
        End Else If SchemePos >= 0 Then Begin
         AttrV := PptxReadAttr(SchemePos, 'val');
         AttrV := SchemeRgb(AttrV);
         If Length(AttrV) >= 6 Then Begin
          PhDefaults[Bk].HasColor := True;
          PhDefaults[Bk].Color    := RgbToEga(AttrV);
         End;
        End;
       End;
      End;
     End;
    End;
   End;
   SpPos := SpEnd + 7;
  Until False;
 End;

 Procedure ParseShape(SpOpen, SpClose: LongInt; SlPtr: PSlide);
 Var Sh: PShape;
     PhType, Attr, LvlStr, LineText: String;
     XfrmPos, OffPos, ExtPos, BodyPos, EndBodyPos: LongInt;
     ParaPos, ParaEnd, RunPos, RunEnd, RPrPos, TStart, TEnd, PhPos, RPrLimit: LongInt;
     LineCnt, LvlInt, ShapeSz: Integer;
     ShapeBold, ShapeItalic, ShapeUnder, ShapeColorSet, FirstRun, IsTitle: Boolean;
     ShapeColor: Byte;
 Begin
  Sh := NewShape;
  Sh^.ShType    := SHP_TEXT;
  Sh^.Filled    := False;
  Sh^.LineWidth := 0;
  Sh^.FillColor := CLR_WHITE;
  Sh^.LineColor := CLR_BLACK;
  Sh^.TxtCount  := 0;
  Sh^.Bold      := False;
  Sh^.Italic    := False;
  Sh^.Underline := False;
  Sh^.FontSize  := 14;
  Sh^.TextColor := CLR_BLACK;
  Sh^.Align     := ALIGN_LEFT;
  Sh^.X := 50; Sh^.Y := 170; Sh^.W := 900; Sh^.H := 200;
  IsTitle := False;

  PhPos := PptxFindStr(SpOpen, SpClose, '<p:ph');
  If PhPos >= 0 Then Begin
   PhType := PptxReadAttr(PhPos, 'type');
   If (PhType = 'title') Or (PhType = 'ctrTitle') Then Begin
    Sh^.ShType    := SHP_TITLE;
    Sh^.FontSize  := 32;
    Sh^.Bold      := True;
    Sh^.TextColor := CLR_BLUE;
    Sh^.X := 50; Sh^.Y := 40; Sh^.W := 900; Sh^.H := 90;
    IsTitle := True;
   End Else If PhType = 'subTitle' Then Begin
    Sh^.ShType   := SHP_SUBTITLE;
    Sh^.FontSize := 18;
    Sh^.X := 50; Sh^.Y := 400; Sh^.W := 900; Sh^.H := 200;
   End Else Begin
    Sh^.ShType := SHP_CONTENT;
    Sh^.X := 50; Sh^.Y := 170; Sh^.W := 900; Sh^.H := 500;
   End;
   { Applique les defauts du slideLayout pour ce type de placeholder }
   LvlInt := PhBucket(PhType);
   If PhDefaults[LvlInt].HasColor Then Sh^.TextColor := PhDefaults[LvlInt].Color;
   If PhDefaults[LvlInt].HasSize  Then Sh^.FontSize  := Byte(PhDefaults[LvlInt].Sz);
   If PhDefaults[LvlInt].Bold     Then Sh^.Bold      := True;
   If PhDefaults[LvlInt].Italic   Then Sh^.Italic    := True;
   If PhDefaults[LvlInt].Underline Then Sh^.Underline := True;
  End;

  XfrmPos := PptxFindStr(SpOpen, SpClose, '<a:xfrm');
  If XfrmPos >= 0 Then Begin
   OffPos := PptxFindStr(XfrmPos, SpClose, '<a:off');
   If OffPos >= 0 Then Begin
    Attr := PptxReadAttr(OffPos, 'x');
    If Attr <> '' Then Sh^.X := EmuX(PptxStrToLI(Attr));
    Attr := PptxReadAttr(OffPos, 'y');
    If Attr <> '' Then Sh^.Y := EmuY(PptxStrToLI(Attr));
   End;
   ExtPos := PptxFindStr(XfrmPos, SpClose, '<a:ext');
   If ExtPos >= 0 Then Begin
    Attr := PptxReadAttr(ExtPos, 'cx');
    If Attr <> '' Then Sh^.W := EmuX(PptxStrToLI(Attr));
    Attr := PptxReadAttr(ExtPos, 'cy');
    If Attr <> '' Then Sh^.H := EmuY(PptxStrToLI(Attr));
   End;
  End;

  BodyPos := PptxFindStr(SpOpen, SpClose, '<p:txBody');
  If BodyPos < 0 Then Begin
   Dispose(Sh);
   Exit;
  End;
  EndBodyPos := PptxFindStr(BodyPos, SpClose, '</p:txBody>');
  If EndBodyPos < 0 Then EndBodyPos := SpClose;

  LineCnt := 0;
  FirstRun := True;
  ShapeBold := False; ShapeItalic := False; ShapeUnder := False;
  ShapeSz := 0;
  ShapeColor := CLR_BLACK; ShapeColorSet := False;

  ParaPos := BodyPos;
  While LineCnt < MAX_TEXT_LINES Do Begin
   ParaPos := PptxFindStr(ParaPos, EndBodyPos, '<a:p>');
   If ParaPos < 0 Then Break;
   ParaEnd := PptxFindStr(ParaPos, EndBodyPos, '</a:p>');
   If ParaEnd < 0 Then ParaEnd := EndBodyPos;

   LvlInt := 0;
   OffPos := PptxFindStr(ParaPos, ParaEnd, '<a:pPr');
   If OffPos >= 0 Then Begin
    LvlStr := PptxReadAttr(OffPos, 'lvl');
    If LvlStr <> '' Then LvlInt := PptxStrToLI(LvlStr);
    If LvlInt < 0 Then LvlInt := 0;
    If LvlInt > 6 Then LvlInt := 6;
   End;

   LineText := '';
   RunPos := ParaPos;
   While True Do Begin
    RPrPos := -1;
    RunPos := PptxFindStr(RunPos, ParaEnd, '<a:r>');
    If RunPos < 0 Then Begin
     RunPos := PptxFindStr(ParaPos, ParaEnd, '<a:r ');
     If RunPos < 0 Then Break;
    End;
    RunEnd := PptxFindStr(RunPos, ParaEnd, '</a:r>');
    If RunEnd < 0 Then RunEnd := ParaEnd;
    RPrPos := PptxFindStr(RunPos, RunEnd, '<a:rPr');
    TStart := PptxFindStr(RunPos, RunEnd, '<a:t>');
    If TStart < 0 Then TStart := PptxFindStr(RunPos, RunEnd, '<a:t ');
    If TStart >= 0 Then Begin
     TStart := PptxFindCharFrom(TStart, RunEnd, '>');
     If TStart >= 0 Then Begin
      Inc(TStart);
      TEnd := PptxFindStr(TStart, RunEnd, '</a:t>');
      If TEnd < 0 Then TEnd := RunEnd;
      If Length(LineText) < TXT_LINE_LEN Then
       LineText := LineText + ExtractTextBetween(TStart, TEnd);
      If Length(LineText) > TXT_LINE_LEN Then
       LineText := Copy(LineText, 1, TXT_LINE_LEN);
     End;
    End;
    If FirstRun And (RPrPos >= 0) Then Begin
     RPrLimit := RunEnd;
     If (TStart > 0) And (TStart < RPrLimit) Then RPrLimit := TStart;
     ParseRunProps(RPrPos, RPrLimit, ShapeBold, ShapeItalic, ShapeUnder, ShapeSz, ShapeColor, ShapeColorSet);
     FirstRun := False;
    End;
    RunPos := RunEnd + 6;
   End;

   If LineText <> '' Then Begin
    Inc(LineCnt);
    Sh^.Text[LineCnt]    := LineText;
    Sh^.Bullets[LineCnt] := Not IsTitle;
    Sh^.Indent[LineCnt]  := Byte(LvlInt);
    Sh^.TxtCount         := LineCnt;
   End;
   ParaPos := ParaEnd + 6;
  End;

  If ShapeBold       Then Sh^.Bold      := True;
  If ShapeItalic     Then Sh^.Italic    := True;
  If ShapeUnder      Then Sh^.Underline := True;
  If ShapeSz >= 8    Then Sh^.FontSize  := Byte(ShapeSz);
  If ShapeColorSet   Then Sh^.TextColor := ShapeColor;

  { Clamp dans les bornes de la slide logique (1000x750) }
  If Sh^.X < 0 Then Begin Sh^.W := Sh^.W + Sh^.X; Sh^.X := 0; End;
  If Sh^.Y < 0 Then Begin Sh^.H := Sh^.H + Sh^.Y; Sh^.Y := 0; End;
  If Sh^.X > 1000 Then Sh^.X := 1000;
  If Sh^.Y > 750  Then Sh^.Y := 750;
  If Sh^.X + Sh^.W > 1000 Then Sh^.W := 1000 - Sh^.X;
  If Sh^.Y + Sh^.H > 750  Then Sh^.H := 750  - Sh^.Y;
  If Sh^.W < 4 Then Sh^.W := 4;
  If Sh^.H < 4 Then Sh^.H := 4;

  If IsTitle And (Sh^.TxtCount >= 1) Then
   SlPtr^.Title := Copy(Sh^.Text[1], 1, 79);

  If Sh^.TxtCount > 0 Then
   AddShapeToSlide(SlPtr, Sh)
  Else
   Dispose(Sh);
 End;

 { Cherche l'index media dans MediaEnts par nom de fichier (apres Target=\"../media/X\"). }
 Function MediaIdxByName(Const Nm: String): Integer;
 Var K: Integer;
 Begin
  MediaIdxByName := 0;
  For K := 1 To MediaCnt Do
   If MediaEnts[K].FName = Nm Then Begin MediaIdxByName := K; Exit; End;
 End;

 { Parse <Relationship Id=\"...\" Target=\"...\"/> dans XmlBuf (rels d'une slide). }
 Procedure ParseCurSlideRels;
 Var RPos, REnd, TgtSlash: LongInt;
     IdAttr, TgtAttr, MediaName: String;
     K: Integer;
 Begin
  CurSlideRelsCnt := 0;
  RPos := 0;
  While CurSlideRelsCnt < MAX_PPTX_RELS Do Begin
   RPos := PptxFindStr(RPos, BufSize, '<Relationship ');
   If RPos < 0 Then Exit;
   REnd := PptxFindCharFrom(RPos, BufSize, '>');
   If REnd < 0 Then Exit;
   IdAttr  := PptxReadAttr(RPos, 'Id');
   TgtAttr := PptxReadAttr(RPos, 'Target');
   { Ne retient que les relations qui pointent vers ../media/ }
   If (Pos('media/', TgtAttr) > 0) Then Begin
    TgtSlash := Length(TgtAttr);
    While (TgtSlash > 0) And (TgtAttr[TgtSlash] <> '/') Do Dec(TgtSlash);
    MediaName := Copy(TgtAttr, TgtSlash + 1, Length(TgtAttr) - TgtSlash);
    K := MediaIdxByName(MediaName);
    If K > 0 Then Begin
     Inc(CurSlideRelsCnt);
     CurSlideRels[CurSlideRelsCnt].RId      := Copy(IdAttr, 1, 8);
     CurSlideRels[CurSlideRelsCnt].MediaIdx := K;
    End;
   End;
   RPos := REnd + 1;
  End;
 End;

 { Trouve un MediaIdx pour un rId donne (CurSlideRels). }
 Function LookupRId(Const RId: String): Integer;
 Var K: Integer;
 Begin
  LookupRId := 0;
  For K := 1 To CurSlideRelsCnt Do
   If CurSlideRels[K].RId = RId Then Begin LookupRId := CurSlideRels[K].MediaIdx; Exit; End;
 End;

 { Charge le fichier media MIdx depuis le ZIP, le decode (PNG pour 5B) et
   retourne l'index d'image (slot dans Pres.Images) ou 0 si echec. Cache
   le resultat dans MediaSlots pour eviter de re-decoder. }
 Function LoadMediaToImage(MIdx: Integer): Integer;
 Var MBuf, MComp: Pointer;
     MSig: LongInt;
     MNL, MEL: Word;
     MSlot: Integer;
     MOK:   Boolean;
 Begin
  LoadMediaToImage := 0;
  If (MIdx < 1) Or (MIdx > MediaCnt) Then Exit;
  If MediaSlots[MIdx] > 0 Then Begin
   LoadMediaToImage := MediaSlots[MIdx]; Exit;
  End;
  If MediaSlots[MIdx] = -1 Then Exit;   { precedemment echoue }
  If MediaEnts[MIdx].Format = IMG_FMT_OTHER Then Begin
   MediaSlots[MIdx] := -1; Exit;
  End;
  If (MediaEnts[MIdx].Mth <> 0) And (MediaEnts[MIdx].Mth <> 8) Then Begin
   MediaSlots[MIdx] := -1; Exit;
  End;
  If (MediaEnts[MIdx].USize <= 0) Or
     (MediaEnts[MIdx].USize > LongInt(4) * 1024 * 1024) Then Begin
   MediaSlots[MIdx] := -1; Exit;
  End;
  If (MediaEnts[MIdx].LfhOff <= 0) Or
     (MediaEnts[MIdx].LfhOff >= FSize) Then Begin
   MediaSlots[MIdx] := -1; Exit;
  End;

  Seek(F, MediaEnts[MIdx].LfhOff);
  MSig := RdL(F);
  If MSig <> ZIP_LFH_SIG Then Begin MediaSlots[MIdx] := -1; Exit; End;
  RdW(F); RdW(F); RdW(F); RdW(F); RdW(F);
  RdL(F); RdL(F); RdL(F);
  MNL := RdW(F); MEL := RdW(F);
  Seek(F, FilePos(F) + MNL + MEL);

  GetMem(MBuf, MediaEnts[MIdx].USize);
  If MBuf = Nil Then Begin MediaSlots[MIdx] := -1; Exit; End;

  If MediaEnts[MIdx].Mth = 0 Then Begin
   BlockRead(F, MBuf^, MediaEnts[MIdx].USize);
  End Else Begin
   GetMem(MComp, MediaEnts[MIdx].CSize);
   If MComp = Nil Then Begin
    FreeMem(MBuf, MediaEnts[MIdx].USize);
    MediaSlots[MIdx] := -1; Exit;
   End;
   If MediaEnts[MIdx].CSize > 0 Then
    BlockRead(F, MComp^, MediaEnts[MIdx].CSize);
   If Not Inflate(MComp, MediaEnts[MIdx].CSize, MBuf, MediaEnts[MIdx].USize) Then Begin
    FreeMem(MComp, MediaEnts[MIdx].CSize);
    FreeMem(MBuf,  MediaEnts[MIdx].USize);
    MediaSlots[MIdx] := -1; Exit;
   End;
   FreeMem(MComp, MediaEnts[MIdx].CSize);
  End;

  MSlot := 0;
  MOK   := False;
  If MediaEnts[MIdx].Format = IMG_FMT_PNG Then
   MOK := LoadImagePngMem(MBuf, MediaEnts[MIdx].USize, MediaEnts[MIdx].FName, MSlot)
  Else If MediaEnts[MIdx].Format = IMG_FMT_JPEG Then
   MOK := LoadImageJpegMem(MBuf, MediaEnts[MIdx].USize, MediaEnts[MIdx].FName, MSlot);

  FreeMem(MBuf, MediaEnts[MIdx].USize);

  If MOK And (MSlot > 0) Then Begin
   MediaSlots[MIdx]  := MSlot;
   LoadMediaToImage  := MSlot;
   PptxLog('IMG ok ' + MediaEnts[MIdx].FName + ' -> slot ' + LStr(MSlot)
           + ' (' + LStr(Pres.Images[MSlot]^.W) + 'x'
           + LStr(Pres.Images[MSlot]^.H) + ')');
  End Else Begin
   MediaSlots[MIdx] := -1;
   PptxLog('IMG echec ' + MediaEnts[MIdx].FName);
  End;
 End;

 Procedure ParsePic(PicOpen, PicClose: LongInt; SlPtr: PSlide);
 Var Sh: PShape;
     XfrmPos, OffPos, ExtPos, BlipPos: LongInt;
     Attr, RIdStr, MediaNm: String;
     MIdx: Integer;
 Begin
  Sh := NewShape;
  Sh^.ShType   := SHP_IMAGE;
  Sh^.ImageIdx := 0;
  Sh^.X := 100; Sh^.Y := 200; Sh^.W := 400; Sh^.H := 300;
  Sh^.Filled   := False;
  Sh^.LineWidth := 1;
  XfrmPos := PptxFindStr(PicOpen, PicClose, '<a:xfrm');
  If XfrmPos >= 0 Then Begin
   OffPos := PptxFindStr(XfrmPos, PicClose, '<a:off');
   If OffPos >= 0 Then Begin
    Attr := PptxReadAttr(OffPos, 'x');
    If Attr <> '' Then Sh^.X := EmuX(PptxStrToLI(Attr));
    Attr := PptxReadAttr(OffPos, 'y');
    If Attr <> '' Then Sh^.Y := EmuY(PptxStrToLI(Attr));
   End;
   ExtPos := PptxFindStr(XfrmPos, PicClose, '<a:ext');
   If ExtPos >= 0 Then Begin
    Attr := PptxReadAttr(ExtPos, 'cx');
    If Attr <> '' Then Sh^.W := EmuX(PptxStrToLI(Attr));
    Attr := PptxReadAttr(ExtPos, 'cy');
    If Attr <> '' Then Sh^.H := EmuY(PptxStrToLI(Attr));
   End;
  End;
  If Sh^.X < 0 Then Begin Sh^.W := Sh^.W + Sh^.X; Sh^.X := 0; End;
  If Sh^.Y < 0 Then Begin Sh^.H := Sh^.H + Sh^.Y; Sh^.Y := 0; End;
  If Sh^.X > 1000 Then Sh^.X := 1000;
  If Sh^.Y > 750  Then Sh^.Y := 750;
  If Sh^.X + Sh^.W > 1000 Then Sh^.W := 1000 - Sh^.X;
  If Sh^.Y + Sh^.H > 750  Then Sh^.H := 750  - Sh^.Y;
  If Sh^.W < 4 Then Sh^.W := 4;
  If Sh^.H < 4 Then Sh^.H := 4;
  { Resolution du r:embed -> MediaEnts (nom de fichier). On stocke le nom
    dans Sh^.Text[1] pour l'afficher dans le placeholder (Etape 5A). }
  BlipPos := PptxFindStr(PicOpen, PicClose, '<a:blip');
  If BlipPos >= 0 Then Begin
   RIdStr := PptxReadAttr(BlipPos, 'r:embed');
   If RIdStr = '' Then RIdStr := PptxReadAttr(BlipPos, 'embed');
   If RIdStr <> '' Then Begin
    MIdx := LookupRId(RIdStr);
    If MIdx > 0 Then Begin
     MediaNm := MediaEnts[MIdx].FName;
     Sh^.Text[1]    := MediaNm;
     Sh^.Bullets[1] := False;
     Sh^.Indent[1]  := 0;
     Sh^.TxtCount   := 1;
     { Tente de decoder l'image (cache via MediaSlots) }
     Sh^.ImageIdx := LoadMediaToImage(MIdx);
    End;
   End;
  End;
  AddShapeToSlide(SlPtr, Sh);
 End;

 Procedure ParseSlideShapes(SlPtr: PSlide);
 Var Pos, NextSp, NextPic, CloseTag: LongInt;
 Begin
  Pos := 0;
  While Pos < BufSize Do Begin
   NextSp  := PptxFindStr(Pos, BufSize, '<p:sp>');
   If NextSp < 0 Then NextSp := PptxFindStr(Pos, BufSize, '<p:sp ');
   NextPic := PptxFindStr(Pos, BufSize, '<p:pic>');
   If NextPic < 0 Then NextPic := PptxFindStr(Pos, BufSize, '<p:pic ');
   If (NextSp < 0) And (NextPic < 0) Then Exit;
   If (NextPic >= 0) And ((NextSp < 0) Or (NextPic < NextSp)) Then Begin
    CloseTag := PptxFindStr(NextPic, BufSize, '</p:pic>');
    If CloseTag < 0 Then Exit;
    ParsePic(NextPic, CloseTag, SlPtr);
    Pos := CloseTag + 8;
   End Else Begin
    CloseTag := PptxFindStr(NextSp, BufSize, '</p:sp>');
    If CloseTag < 0 Then Exit;
    ParseShape(NextSp, CloseTag, SlPtr);
    Pos := CloseTag + 7;
   End;
  End;
 End;

Begin
 PptxLog('--- LoadPPTX: ' + FN + ' ---');
 LoadPPTX := False;
 SkippedCompressed := 0;
 FoundSlide := 0;
 SlideCnt := 0;
 XmlBuf := Nil; BufSize := 0;
 ScanBuf := Nil;
 DiagStr := '';
 PresCx := 9144000; PresCy := 6858000;
 HasPres := False;
 PresLfhOff := 0; PresCs := 0; PresUs := 0; PresMth := 0;
 HasTheme := False;
 ThemeLfhOff := 0; ThemeCs := 0; ThemeUs := 0; ThemeMth := 0;
 For II := 1 To 12 Do ThemeRGB[II] := '';
 LayoutCnt := 0;
 MediaCnt := 0;
 For II := 1 To MAX_PPTX_SLIDES Do HasSlideRels[II] := False;
 CurSlideRelsCnt := 0;
 For II := 1 To MAX_PPTX_MEDIA Do MediaSlots[II] := 0;
 For LI := 1 To 4 Do Begin
  PhDefaults[LI].HasColor  := False; PhDefaults[LI].Color := CLR_BLACK;
  PhDefaults[LI].HasSize   := False; PhDefaults[LI].Sz    := 0;
  PhDefaults[LI].Bold      := False;
  PhDefaults[LI].Italic    := False;
  PhDefaults[LI].Underline := False;
 End;
 Assign(F, FN);
 {$I-} Reset(F, 1); {$I+}
 If IOResult <> 0 Then Begin
  PptxLog('FAIL: ouverture impossible');
  SeedSamplePresentation;
  StatusMsg := 'PPTX: ouverture impossible: ' + FN;
  Exit;
 End;
 FSize := FileSize(F);
 PptxLog('FSize=' + LStr(FSize));
 If FSize < 22 Then Begin
  Close(F); SeedSamplePresentation;
  StatusMsg := 'PPTX: fichier trop petit';
  Exit;
 End;

 { ---- Recherche EOCD en queue de fichier ---- }
 ScanLen := FSize;
 If ScanLen > EOCD_SCAN_MAX Then ScanLen := EOCD_SCAN_MAX;
 GetMem(ScanBuf, ScanLen);
 Seek(F, FSize - ScanLen);
 BlockRead(F, ScanBuf^, ScanLen);
 EocdPos := -1;
 K := ScanLen - 22;
 While K >= 0 Do Begin
  ScanByte := ScanBuf; Inc(ScanByte, K);
  If ScanByte^ = 80 Then Begin
   Inc(ScanByte); If ScanByte^ = 75 Then Begin
    Inc(ScanByte); If ScanByte^ = 5 Then Begin
     Inc(ScanByte); If ScanByte^ = 6 Then Begin
      EocdPos := (FSize - ScanLen) + K; Break;
     End; End; End; End;
  Dec(K);
 End;
 FreeMem(ScanBuf, ScanLen); ScanBuf := Nil;
 PptxLog('EocdPos=' + LStr(EocdPos));
 If EocdPos < 0 Then Begin
  Close(F); SeedSamplePresentation;
  Str(FSize, DiagStr);
  StatusMsg := 'PPTX: EOCD introuvable (taille=' + DiagStr + ')';
  Exit;
 End;

 { Lecture EOCD : on saute jusqu'a "total entries" (offset +10). }
 Seek(F, EocdPos + 10);
 TotalEnt := RdW(F);
 CdSize := RdL(F);
 CdOff := RdL(F);
 PptxLog('TotalEnt=' + LStr(TotalEnt) + ' CdSize=' + LStr(CdSize) + ' CdOff=' + LStr(CdOff));
 If (TotalEnt <= 0) Or (CdOff <= 0) Or (CdOff >= FSize) Then Begin
  Close(F); SeedSamplePresentation;
  Str(TotalEnt, DiagStr);
  StatusMsg := 'PPTX: CD invalide (ent=' + DiagStr + ')';
  Exit;
 End;

 { ---- Parcourt le Central Directory ---- }
 Seek(F, CdOff);
 For EI := 1 To TotalEnt Do Begin
  Sig := RdL(F);
  If Sig <> ZIP_CDH_SIG Then Begin
   PptxLog('CDH sig mismatch ent=' + LStr(EI));
   Break;
  End;
  RdW(F); RdW(F);                             { version made by / needed }
  Flg := RdW(F);
  Mth := RdW(F);
  RdW(F); RdW(F);                             { time, date }
  RdL(F);                                     { crc }
  CSize := RdL(F);
  USize := RdL(F);
  NameLen    := RdW(F);
  ExtraLen   := RdW(F);
  CommentLen := RdW(F);
  RdW(F); RdW(F); RdL(F);                     { disk, int, ext attrs }
  LfhOff := RdL(F);
  PptxLog('CDH ' + LStr(EI) + ' nameLen=' + LStr(NameLen) + ' extra=' + LStr(ExtraLen) + ' cmt=' + LStr(CommentLen) + ' off=' + LStr(LfhOff));
  If NameLen > 200 Then NameLen := 200;
  EntName[0] := Char(NameLen);
  If NameLen > 0 Then BlockRead(F, EntName[1], NameLen);
  If ExtraLen   > 0 Then Seek(F, FilePos(F) + ExtraLen);
  If CommentLen > 0 Then Seek(F, FilePos(F) + CommentLen);

  If (Pos('ppt/slides/slide', EntName) = 1) And
     (Pos('.xml', EntName) > 0) And
     (Pos('.rels', EntName) = 0) Then Begin
   PptxLog('SLIDE: ' + EntName + ' mth=' + LStr(Mth) + ' cs=' + LStr(CSize) + ' us=' + LStr(USize) + ' off=' + LStr(LfhOff));
   NameTmp := Copy(EntName, 17, Length(EntName));
   II := Pos('.xml', NameTmp);
   If II > 0 Then NameTmp := Copy(NameTmp, 1, II - 1);
   Val(NameTmp, SlNum, ValErr);
   If ValErr <> 0 Then SlNum := 9999;
   If SlideCnt < MAX_PPTX_SLIDES Then Begin
    Inc(SlideCnt);
    SlideEnts[SlideCnt].LfhOff   := LfhOff;
    SlideEnts[SlideCnt].CSize    := CSize;
    SlideEnts[SlideCnt].USize    := USize;
    SlideEnts[SlideCnt].Mth      := Mth;
    SlideEnts[SlideCnt].SlideNum := SlNum;
   End;
  End;
  If (EntName = 'ppt/presentation.xml') And (Not HasPres) Then Begin
   PptxLog('PRESXML: mth=' + LStr(Mth) + ' cs=' + LStr(CSize) + ' us=' + LStr(USize) + ' off=' + LStr(LfhOff));
   PresLfhOff := LfhOff;
   PresCs := CSize;
   PresUs := USize;
   PresMth := Mth;
   HasPres := True;
  End;
  { On veut SPECIFIQUEMENT theme1.xml (associe a slideMaster1, le master par defaut).
    Le ZIP peut lister theme2.xml avant theme1.xml dans le CD. }
  If (EntName = 'ppt/theme/theme1.xml') Then Begin
   PptxLog('THEME: ' + EntName + ' mth=' + LStr(Mth) + ' cs=' + LStr(CSize) + ' us=' + LStr(USize) + ' off=' + LStr(LfhOff));
   ThemeLfhOff := LfhOff;
   ThemeCs := CSize;
   ThemeUs := USize;
   ThemeMth := Mth;
   HasTheme := True;
  End;
  If (Pos('ppt/slideLayouts/slideLayout', EntName) = 1) And
     (Pos('.xml', EntName) > 0) And
     (Pos('.rels', EntName) = 0) And
     (LayoutCnt < MAX_PPTX_LAYOUTS) Then Begin
   Inc(LayoutCnt);
   LayoutEnts[LayoutCnt].LfhOff := LfhOff;
   LayoutEnts[LayoutCnt].CSize  := CSize;
   LayoutEnts[LayoutCnt].USize  := USize;
   LayoutEnts[LayoutCnt].Mth    := Mth;
  End;
  { Medias (images embarquees) }
  If (Pos('ppt/media/', EntName) = 1) And (MediaCnt < MAX_PPTX_MEDIA) Then Begin
   NameTmp := Copy(EntName, 11, Length(EntName));   { strip "ppt/media/" }
   Inc(MediaCnt);
   MediaEnts[MediaCnt].LfhOff := LfhOff;
   MediaEnts[MediaCnt].CSize  := CSize;
   MediaEnts[MediaCnt].USize  := USize;
   MediaEnts[MediaCnt].Mth    := Mth;
   If Length(NameTmp) > 24 Then NameTmp := Copy(NameTmp, 1, 24);
   MediaEnts[MediaCnt].FName  := NameTmp;
   { Detection format par extension }
   II := Length(NameTmp); While (II > 0) And (NameTmp[II] <> '.') Do Dec(II);
   If II > 0 Then Begin
    NumStr := Copy(NameTmp, II + 1, Length(NameTmp) - II);
    { lower-case }
    For JJ := 1 To Length(NumStr) Do
     If (NumStr[JJ] >= 'A') And (NumStr[JJ] <= 'Z') Then
      NumStr[JJ] := Char(Ord(NumStr[JJ]) + 32);
    If (NumStr = 'png') Then MediaEnts[MediaCnt].Format := IMG_FMT_PNG
    Else If (NumStr = 'jpg') Or (NumStr = 'jpeg') Then MediaEnts[MediaCnt].Format := IMG_FMT_JPEG
    Else MediaEnts[MediaCnt].Format := IMG_FMT_OTHER;
   End Else MediaEnts[MediaCnt].Format := IMG_FMT_OTHER;
  End;
  { Slide rels (ppt/slides/_rels/slideN.xml.rels) }
  If (Pos('ppt/slides/_rels/slide', EntName) = 1) And
     (Pos('.xml.rels', EntName) > 0) Then Begin
   NameTmp := Copy(EntName, 23, Length(EntName));   { strip "ppt/slides/_rels/slide" }
   II := Pos('.xml.rels', NameTmp);
   If II > 0 Then NameTmp := Copy(NameTmp, 1, II - 1);
   Val(NameTmp, SlNum, ValErr);
   If (ValErr = 0) And (SlNum >= 1) And (SlNum <= MAX_PPTX_SLIDES) Then Begin
    SlideRelsEnts[SlNum].LfhOff := LfhOff;
    SlideRelsEnts[SlNum].CSize  := CSize;
    SlideRelsEnts[SlNum].USize  := USize;
    SlideRelsEnts[SlNum].Mth    := Mth;
    HasSlideRels[SlNum] := True;
   End;
  End;
 End;

 { Trie par numero de slide croissant }
 For II := 2 To SlideCnt Do Begin
  TmpEnt := SlideEnts[II]; JJ := II - 1;
  While (JJ >= 1) And (SlideEnts[JJ].SlideNum > TmpEnt.SlideNum) Do Begin
   SlideEnts[JJ + 1] := SlideEnts[JJ]; Dec(JJ);
  End;
  SlideEnts[JJ + 1] := TmpEnt;
 End;

 FreePresentation;
 InitPresentation;

 { ---- Extraction de la taille de slide depuis ppt/presentation.xml ---- }
 If HasPres And (PresUs > 0) And (PresUs <= LongInt(1) * 1024 * 1024) And
    ((PresMth = 0) Or (PresMth = 8)) And
    (PresLfhOff > 0) And (PresLfhOff < FSize) Then Begin
  Seek(F, PresLfhOff);
  Sig := RdL(F);
  If Sig = ZIP_LFH_SIG Then Begin
   RdW(F); RdW(F); RdW(F); RdW(F); RdW(F);
   RdL(F); RdL(F); RdL(F);
   NameLen  := RdW(F);
   ExtraLen := RdW(F);
   Seek(F, FilePos(F) + NameLen + ExtraLen);
   GetMem(XmlBuf, PresUs); BufSize := PresUs;
   If PresMth = 0 Then Begin
    BlockRead(F, XmlBuf^, PresUs);
   End Else Begin
    GetMem(CompBuf, PresCs);
    If PresCs > 0 Then BlockRead(F, CompBuf^, PresCs);
    If Not Inflate(CompBuf, PresCs, XmlBuf, PresUs) Then Begin
     FreeMem(XmlBuf, BufSize); XmlBuf := Nil; BufSize := 0;
    End;
    FreeMem(CompBuf, PresCs);
   End;
   If XmlBuf <> Nil Then Begin
    II := PptxFindStr(0, BufSize, '<p:sldSz');
    If II >= 0 Then Begin
     NameTmp := PptxReadAttr(II, 'cx');
     If NameTmp <> '' Then PresCx := PptxStrToLI(NameTmp);
     NameTmp := PptxReadAttr(II, 'cy');
     If NameTmp <> '' Then PresCy := PptxStrToLI(NameTmp);
    End;
    PptxLog('SldSz cx=' + LStr(PresCx) + ' cy=' + LStr(PresCy));
    FreeMem(XmlBuf, BufSize); XmlBuf := Nil; BufSize := 0;
   End;
  End;
 End;
 If PresCx <= 0 Then PresCx := 9144000;
 If PresCy <= 0 Then PresCy := 6858000;

 { ---- Extraction du theme (clrScheme) depuis ppt/theme/theme1.xml ---- }
 If HasTheme And (ThemeUs > 0) And (ThemeUs <= LongInt(1) * 1024 * 1024) And
    ((ThemeMth = 0) Or (ThemeMth = 8)) And
    (ThemeLfhOff > 0) And (ThemeLfhOff < FSize) Then Begin
  Seek(F, ThemeLfhOff);
  Sig := RdL(F);
  If Sig = ZIP_LFH_SIG Then Begin
   RdW(F); RdW(F); RdW(F); RdW(F); RdW(F);
   RdL(F); RdL(F); RdL(F);
   NameLen  := RdW(F);
   ExtraLen := RdW(F);
   Seek(F, FilePos(F) + NameLen + ExtraLen);
   GetMem(XmlBuf, ThemeUs); BufSize := ThemeUs;
   If ThemeMth = 0 Then Begin
    BlockRead(F, XmlBuf^, ThemeUs);
   End Else Begin
    GetMem(CompBuf, ThemeCs);
    If ThemeCs > 0 Then BlockRead(F, CompBuf^, ThemeCs);
    If Not Inflate(CompBuf, ThemeCs, XmlBuf, ThemeUs) Then Begin
     FreeMem(XmlBuf, BufSize); XmlBuf := Nil; BufSize := 0;
    End;
    FreeMem(CompBuf, ThemeCs);
   End;
   If XmlBuf <> Nil Then Begin
    P := PptxFindStr(0, BufSize, '<a:clrScheme');
    Q := PptxFindStr(0, BufSize, '</a:clrScheme>');
    If (P >= 0) And (Q > P) Then Begin
     II := P;
     While II < Q Do Begin
      II := PptxFindStr(II, Q, '<a:');
      If II < 0 Then Break;
      { Lit le nom local de l'element : caracteres apres '<a:' jusqu'a ' ', '>' ou '/' }
      JJ := II + 3;
      NameTmp := '';
      While (JJ < Q) And (Length(NameTmp) < 20) Do Begin
       ChI := PtrToByteAt(JJ);
       If (ChI = 32) Or (ChI = 9) Or (ChI = 13) Or (ChI = 10) Or
          (ChI = 62) Or (ChI = 47) Then Break;
       NameTmp := NameTmp + Char(ChI);
       Inc(JJ);
      End;
      SlNum := SchemeIdx(NameTmp);
      If SlNum > 0 Then Begin
       { Cherche srgbClr ou sysClr dans cet element seulement }
       K := PptxFindStr(II, Q, '</a:' + NameTmp + '>');
       If K < 0 Then K := Q;
       P := PptxFindStr(II, K, '<a:srgbClr');
       If P >= 0 Then Begin
        NumStr := PptxReadAttr(P, 'val');
        If Length(NumStr) >= 6 Then ThemeRGB[SlNum] := NumStr;
       End Else Begin
        P := PptxFindStr(II, K, '<a:sysClr');
        If P >= 0 Then Begin
         NumStr := PptxReadAttr(P, 'lastClr');
         If Length(NumStr) >= 6 Then ThemeRGB[SlNum] := NumStr;
        End;
       End;
       II := K;
      End Else Begin
       Inc(II);
      End;
     End;
    End;
    For K := 1 To 12 Do
     If ThemeRGB[K] <> '' Then
      PptxLog('THEME[' + LStr(K) + ']=' + ThemeRGB[K]);
    FreeMem(XmlBuf, BufSize); XmlBuf := Nil; BufSize := 0;
   End;
  End;
 End;

 { ---- Extraction des defauts de placeholders depuis slideLayouts ----
   On parcourt EN ORDRE INVERSE pour que slideLayout1 (capture en premier
   lors du scan CD) ecrive ses valeurs en DERNIER et "gagne" sur PhDefaults
   (c'est le layout par defaut pour la slide titre). }
 For LI := LayoutCnt Downto 1 Do Begin
  USize  := LayoutEnts[LI].USize;
  CSize  := LayoutEnts[LI].CSize;
  Mth    := LayoutEnts[LI].Mth;
  LfhOff := LayoutEnts[LI].LfhOff;
  If (USize <= 0) Or (USize > LongInt(2) * 1024 * 1024) Then Continue;
  If (Mth <> 0) And (Mth <> 8) Then Continue;
  If (LfhOff <= 0) Or (LfhOff >= FSize) Then Continue;
  Seek(F, LfhOff);
  Sig := RdL(F);
  If Sig <> ZIP_LFH_SIG Then Continue;
  RdW(F); RdW(F); RdW(F); RdW(F); RdW(F);
  RdL(F); RdL(F); RdL(F);
  NameLen  := RdW(F);
  ExtraLen := RdW(F);
  Seek(F, FilePos(F) + NameLen + ExtraLen);
  GetMem(XmlBuf, USize); BufSize := USize;
  If Mth = 0 Then Begin
   BlockRead(F, XmlBuf^, USize);
  End Else Begin
   GetMem(CompBuf, CSize);
   If CSize > 0 Then BlockRead(F, CompBuf^, CSize);
   If Not Inflate(CompBuf, CSize, XmlBuf, USize) Then Begin
    FreeMem(XmlBuf, BufSize); XmlBuf := Nil; BufSize := 0;
   End;
   FreeMem(CompBuf, CSize);
  End;
  If XmlBuf <> Nil Then Begin
   ParseLayoutDefaultsFromBuffer;
   FreeMem(XmlBuf, BufSize); XmlBuf := Nil; BufSize := 0;
  End;
 End;
 For LI := 1 To 4 Do
  If PhDefaults[LI].HasColor Then
   PptxLog('PhDef[' + LStr(LI) + '] color=' + LStr(PhDefaults[LI].Color)
           + ' sz=' + LStr(PhDefaults[LI].Sz));

 { ---- Extraction effective ---- }
 For SlideIdx := 1 To SlideCnt Do Begin
  CSize  := SlideEnts[SlideIdx].CSize;
  USize  := SlideEnts[SlideIdx].USize;
  Mth    := SlideEnts[SlideIdx].Mth;
  LfhOff := SlideEnts[SlideIdx].LfhOff;

  If (Mth <> 0) And (Mth <> 8) Then Begin
   Inc(SkippedCompressed); Continue;
  End;
  If (USize <= 0) Or (USize > LongInt(4) * 1024 * 1024) Then Continue;
  If (CSize < 0) Or (LfhOff < 0) Or (LfhOff >= FSize) Then Continue;

  { ---- Lecture des relations de cette slide (rId -> media) ---- }
  CurSlideRelsCnt := 0;
  SlNum := SlideEnts[SlideIdx].SlideNum;
  If (SlNum >= 1) And (SlNum <= MAX_PPTX_SLIDES) And HasSlideRels[SlNum] Then Begin
   If ((SlideRelsEnts[SlNum].Mth = 0) Or (SlideRelsEnts[SlNum].Mth = 8)) And
      (SlideRelsEnts[SlNum].USize > 0) And
      (SlideRelsEnts[SlNum].USize <= LongInt(256) * 1024) And
      (SlideRelsEnts[SlNum].LfhOff > 0) And
      (SlideRelsEnts[SlNum].LfhOff < FSize) Then Begin
    Seek(F, SlideRelsEnts[SlNum].LfhOff);
    Sig := RdL(F);
    If Sig = ZIP_LFH_SIG Then Begin
     RdW(F); RdW(F); RdW(F); RdW(F); RdW(F);
     RdL(F); RdL(F); RdL(F);
     NameLen  := RdW(F);
     ExtraLen := RdW(F);
     Seek(F, FilePos(F) + NameLen + ExtraLen);
     GetMem(XmlBuf, SlideRelsEnts[SlNum].USize);
     BufSize := SlideRelsEnts[SlNum].USize;
     If SlideRelsEnts[SlNum].Mth = 0 Then Begin
      BlockRead(F, XmlBuf^, BufSize);
     End Else Begin
      GetMem(CompBuf, SlideRelsEnts[SlNum].CSize);
      If SlideRelsEnts[SlNum].CSize > 0 Then
       BlockRead(F, CompBuf^, SlideRelsEnts[SlNum].CSize);
      If Not Inflate(CompBuf, SlideRelsEnts[SlNum].CSize, XmlBuf, BufSize) Then Begin
       FreeMem(XmlBuf, BufSize); XmlBuf := Nil; BufSize := 0;
      End;
      FreeMem(CompBuf, SlideRelsEnts[SlNum].CSize);
     End;
     If XmlBuf <> Nil Then Begin
      ParseCurSlideRels;
      FreeMem(XmlBuf, BufSize); XmlBuf := Nil; BufSize := 0;
     End;
    End;
   End;
  End;

  Seek(F, LfhOff);
  Sig := RdL(F);
  If Sig <> ZIP_LFH_SIG Then Begin
   PptxLog('LFH sig mismatch idx=' + LStr(SlideIdx));
   Continue;
  End;
  RdW(F); RdW(F); RdW(F); RdW(F); RdW(F);     { ver,flg,mth,time,date }
  RdL(F); RdL(F); RdL(F);                     { crc,csize,usize (peu fiables si bit 3) }
  NameLen  := RdW(F);
  ExtraLen := RdW(F);
  Seek(F, FilePos(F) + NameLen + ExtraLen);

  GetMem(XmlBuf, USize); BufSize := USize;
  If Mth = 0 Then Begin
   If USize > 0 Then BlockRead(F, XmlBuf^, USize);
  End Else Begin
   GetMem(CompBuf, CSize);
   If CSize > 0 Then BlockRead(F, CompBuf^, CSize);
   If Not Inflate(CompBuf, CSize, XmlBuf, USize) Then Begin
    PptxLog('INFLATE FAIL idx=' + LStr(SlideIdx));
    FreeMem(CompBuf, CSize);
    FreeMem(XmlBuf, BufSize); XmlBuf := Nil;
    Inc(SkippedCompressed); Continue;
   End;
   FreeMem(CompBuf, CSize);
  End;

  Inc(FoundSlide);
  NewSl := NewSlide;
  Str(FoundSlide, NumStr);
  NewSl^.Name := 'Diapo ' + NumStr;
  NewSl^.Title := '';
  NewSl^.Background := Pres.MasterBg;

  ParseSlideShapes(NewSl);

  SlNum := Pres.SldCount + 1;
  If SlNum <= MAX_SLIDES Then Begin
   Pres.Slides[SlNum] := NewSl;
   Pres.SldCount := SlNum;
  End Else Dispose(NewSl);

  FreeMem(XmlBuf, BufSize); XmlBuf := Nil;
 End;

 Close(F);
 If XmlBuf <> Nil Then FreeMem(XmlBuf, BufSize);
 PptxLog('SlideCnt=' + LStr(SlideCnt) + ' FoundSlide=' + LStr(FoundSlide) + ' Skipped=' + LStr(SkippedCompressed));

 If FoundSlide = 0 Then Begin
  SeedSamplePresentation;
  Str(SlideCnt, DiagStr);
  StatusMsg := 'PPTX: 0 slide extraite / ' + DiagStr + ' detectees';
  Exit;
 End;
 Pres.FileName := FN;
 Pres.Dirty := False;
 CurSlide := 1;
 CurShape := 0;
 { Le fichier PPTX importe ne contient pas notre pied de page par defaut.
   On le neutralise pour eviter d'afficher "gladir.com" / "2026" sur chaque
   diapo chargee. }
 Pres.FooterText   := '';
 Pres.DateText     := '';
 Pres.HeaderText   := '';
 Pres.ShowFooter   := False;
 Pres.ShowDate     := False;
 Pres.ShowHeader   := False;
 Pres.Company      := '';
 If SkippedCompressed > 0 Then
  StatusMsg := 'PPTX importe (slides ignorees)'
 Else
  StatusMsg := 'PPTX importe : ' + FN;
 PptxLog('OK: ' + LStr(FoundSlide) + ' slides chargees');
 LoadPPTX := True;
End;

{ ----- Actions Export/Import .PPTX -------------------------------------- }

Function PptxUpStr(Const S: String): String;
Var K: Integer; R: String;
Begin
 R := S;
 For K := 1 To Length(R) Do R[K] := UpCase(R[K]);
 PptxUpStr := R;
End;

Procedure ActionExportPPTX;
Var FN: String;
Begin
 FN := Pres.FileName;
 If FN = '' Then FN := 'EXPORT.PPTX'
 Else Begin
  { Remplace .PPT par .PPTX }
  If (Length(FN) >= 4) And
     (PptxUpStr(Copy(FN, Length(FN) - 3, 4)) = '.PPT') Then
   FN := Copy(FN, 1, Length(FN) - 4) + '.PPTX';
 End;
 If Not InputTextDlg('Exporter .PPTX',
                     'Nom du fichier (.PPTX) :', FN, 79) Then Begin
  NeedFullRedraw := True; Exit;
 End;
 If FN = '' Then Begin NeedFullRedraw := True; Exit; End;
 If Pos('.', FN) = 0 Then FN := FN + '.PPTX';
 If SavePPTX(FN) Then
  StatusMsg := 'Exporte : ' + FN
 Else
  MessageBox('Exporter .PPTX', 'Impossible d''ecrire : ' + FN);
 NeedFullRedraw := True;
End;

Procedure ActionImportPPTX;
Var FN: String;
Begin
 If Not ConfirmDiscardChanges Then Exit;
 FN := '';
 If Not InputTextDlg('Importer .PPTX',
                     'Nom du fichier (.PPTX) :', FN, 79) Then Begin
  NeedFullRedraw := True; Exit;
 End;
 If FN = '' Then Begin NeedFullRedraw := True; Exit; End;
 If Not LoadPPTX(FN) Then
  MessageBox('Importer .PPTX',
             'Impossible de lire ou aucune diapositive trouvee : ' + FN);
 NeedFullRedraw := True;
End;

{ ====================================================================== }
{               PHASE 12 : IMPRESSION (vers fichier .PRN)                }
{ ====================================================================== }

Procedure ActionPrint;
Var F: Text; FN, Default: String;
    I, J, K: Integer; S: PSlide; Sh: PShape;
Begin
 Default := Pres.FileName;
 If Default = '' Then Default := 'PRINT.PRN'
 Else Begin
  If (Length(Default) >= 5) And
     (PptxUpStr(Copy(Default, Length(Default) - 4, 5)) = '.PPTX') Then
   Default := Copy(Default, 1, Length(Default) - 5) + '.PRN'
  Else If (Length(Default) >= 4) And
     (PptxUpStr(Copy(Default, Length(Default) - 3, 4)) = '.PPT') Then
   Default := Copy(Default, 1, Length(Default) - 4) + '.PRN'
  Else
   Default := Default + '.PRN';
 End;
 FN := Default;
 If Not InputTextDlg('Imprimer',
                     'Fichier d''impression (.PRN, texte) :', FN, 79) Then
 Begin
  NeedFullRedraw := True; Exit;
 End;
 If FN = '' Then Begin NeedFullRedraw := True; Exit; End;
 Assign(F, FN);
 {$I-} Rewrite(F); {$I+}
 If IOResult <> 0 Then Begin
  MessageBox('Imprimer', 'Impossible d''ecrire : ' + FN);
  NeedFullRedraw := True; Exit;
 End;
 WriteLn(F, '=================================================');
 WriteLn(F, '  ', Pres.Title);
 If Pres.Author  <> '' Then WriteLn(F, '  Auteur  : ', Pres.Author);
 If Pres.Company <> '' Then WriteLn(F, '  Societe : ', Pres.Company);
 WriteLn(F, '  Diapositives : ', Pres.SldCount);
 WriteLn(F, '=================================================');
 WriteLn(F);
 For I := 1 To Pres.SldCount Do Begin
  S := Pres.Slides[I];
  If S <> Nil Then Begin
   WriteLn(F, '--- Diapositive ', I, ' / ', Pres.SldCount,
              ' : ', S^.Title, ' ---');
   WriteLn(F);
   For J := 1 To S^.ShCount Do Begin
    Sh := S^.Shapes[J];
    If Sh <> Nil Then
     For K := 1 To Sh^.TxtCount Do Begin
      If Sh^.Bullets[K] Then Write(F, ' * ')
      Else Write(F, '   ');
      WriteLn(F, Sh^.Text[K]);
     End;
   End;
   If S^.Notes <> '' Then Begin
    WriteLn(F);
    WriteLn(F, 'Notes :');
    WriteLn(F, S^.Notes);
   End;
   WriteLn(F);
   { Saut de page ASCII (FF) entre diapos sauf la derniere }
   If I < Pres.SldCount Then Begin Write(F, #12); WriteLn(F); End;
  End;
 End;
 Close(F);
 StatusMsg := 'Imprime (texte) : ' + FN;
 NeedStatRedraw := True;
End;

Procedure DoAction(A: Integer); Forward;
Procedure RemoveShapeAt(SlIdx, ShIdx: Integer); Forward;
Procedure ShapeDuplicate; Forward;
Procedure ShapeBringFront; Forward;
Procedure ShapeSendBack; Forward;
Procedure ShapeToggleBold; Forward;
Procedure ShapeToggleItalic; Forward;
Procedure ShapeToggleUnderline; Forward;
Procedure ShapeSetAlign(A: Byte); Forward;
Procedure ShapeApplyFontDelta(Delta: Integer); Forward;
Procedure ShapeCycleColor(Which: Byte); Forward;
Procedure EditToggleBullet; Forward;
Procedure EditIndent(Delta: Integer); Forward;

Procedure ActionViewChange(V: Integer);
Begin
 CurView := V;
 Case V Of
  VIEW_NORMAL:  StatusMsg := 'Mode Normal';
  VIEW_OUTLINE: StatusMsg := 'Mode Plan';
  VIEW_SORTER:  StatusMsg := 'Trieuse de diapositives';
  VIEW_NOTES:   StatusMsg := 'Commentaires';
 End;
 NeedFullRedraw := True;
End;

Procedure DoAction(A: Integer);
Begin
 Case A Of
  ACT_QUIT:         ActionQuit;
  ACT_NEW:          ActionNew;
  ACT_OPEN:         ActionOpen;
  ACT_SAVE:         ActionSave;
  ACT_SAVEAS:       ActionSaveAs;
  ACT_CLOSE:        ActionClose;
  ACT_PRINT:        ActionPrint;
  ACT_EXPORT_PPTX:  ActionExportPPTX;
  ACT_IMPORT_PPTX:  ActionImportPPTX;
  ACT_HELP_ABOUT:   ActionAbout;
  ACT_NEW_SLIDE:    ActionNewSlide;
  ACT_DUP_SLIDE:    ActionDupSlide;
  ACT_DEL_SLIDE:    ActionDelSlide;
  ACT_NEXT_SLIDE:   ActionNextSlide;
  ACT_PREV_SLIDE:   ActionPrevSlide;
  ACT_FIRST_SLIDE:  ActionFirstSlide;
  ACT_LAST_SLIDE:   ActionLastSlide;
  ACT_VIEW_NORMAL:  ActionViewChange(VIEW_NORMAL);
  ACT_VIEW_OUTLINE: ActionViewChange(VIEW_OUTLINE);
  ACT_VIEW_SORTER:  ActionViewChange(VIEW_SORTER);
  ACT_VIEW_NOTES:   ActionViewChange(VIEW_NOTES);
  ACT_TOOL_SELECT:  SetTool(TOOL_SELECT);
  ACT_TOOL_TEXT:    SetTool(TOOL_TEXT);
  ACT_TOOL_RECT:    SetTool(TOOL_RECT);
  ACT_TOOL_ELL:     SetTool(TOOL_ELLIPSE);
  ACT_TOOL_LINE:    SetTool(TOOL_LINE);
  ACT_TOOL_ARROW:   SetTool(TOOL_ARROW);
  ACT_INS_RECT:     SetTool(TOOL_RECT);
  ACT_INS_ELLIPSE:  SetTool(TOOL_ELLIPSE);
  ACT_INS_LINE:     SetTool(TOOL_LINE);
  ACT_INS_ARROW:    SetTool(TOOL_ARROW);
  ACT_INS_TRIANGLE: SetTool(TOOL_TRIANGLE);
  ACT_INS_STAR:     SetTool(TOOL_STAR);
  ACT_INS_CALLOUT:  SetTool(TOOL_CALLOUT);
  ACT_INS_TEXT:     SetTool(TOOL_TEXT);
  ACT_FONT_BOLD:    ShapeToggleBold;
  ACT_FONT_ITAL:    ShapeToggleItalic;
  ACT_FONT_UND:     ShapeToggleUnderline;
  ACT_ALIGN_LEFT:   ShapeSetAlign(ALIGN_LEFT);
  ACT_ALIGN_CENTER: ShapeSetAlign(ALIGN_CENTER);
  ACT_ALIGN_RIGHT:  ShapeSetAlign(ALIGN_RIGHT);
  ACT_BULLET:       EditToggleBullet;
  ACT_INDENT_INC:   EditIndent(+1);
  ACT_INDENT_DEC:   EditIndent(-1);
  ACT_FONT_SIZE_UP: ShapeApplyFontDelta(+2);
  ACT_FONT_SIZE_DN: ShapeApplyFontDelta(-2);
  ACT_COLOR_FILL:   ShapeCycleColor(0);
  ACT_COLOR_LINE:   ShapeCycleColor(1);
  ACT_COLOR_TEXT:   ShapeCycleColor(2);
  ACT_MOVE_UP:      ActionMoveSlideUp;
  ACT_MOVE_DOWN:    ActionMoveSlideDown;
  ACT_LAYOUT:       ActionChangeLayoutDlg;
  ACT_BACKGROUND:   ActionChangeBackgroundDlg;
  ACT_THEME:        ActionChangeThemeDlg;
  ACT_VIEW_MASTER:  ActionMasterEdit;
  ACT_INS_HEADER:   ActionHeaderFooter;
  ACT_SLIDESHOW:      ActionSlideShow;
  ACT_SLIDESHOW_FROM: ActionSlideShowFrom;
  ACT_RUN_FROM_BEG:   ActionSlideShow;
  ACT_TRANS:          ActionChangeTransitionDlg;
  ACT_INS_IMAGE:      ActionInsertImage;
  ACT_ANIM_ENTRY:     ActionAnimEntryDlg;
  ACT_ANIM_EXIT:      ActionAnimExitDlg;
  ACT_TIMING:         ActionTimingDlg;
  ACT_DELETE: Begin
   If CurShape > 0 Then Begin
    RemoveShapeAt(CurSlide, CurShape);
    CurShape := 0;
    NeedSlideRedraw := True; NeedPanelRedraw := True;
    StatusMsg := 'Forme supprimee.'; NeedStatRedraw := True;
   End;
  End;
  ACT_DUP: Begin
   If CurShape > 0 Then Begin
    ShapeDuplicate;
    NeedSlideRedraw := True; NeedPanelRedraw := True;
    StatusMsg := 'Forme dupliquee.'; NeedStatRedraw := True;
   End Else ActionDupSlide;
  End;
  ACT_BRING_FRONT: Begin
   ShapeBringFront;
   NeedSlideRedraw := True; NeedPanelRedraw := True;
   StatusMsg := 'Premier plan.'; NeedStatRedraw := True;
  End;
  ACT_SEND_BACK: Begin
   ShapeSendBack;
   NeedSlideRedraw := True; NeedPanelRedraw := True;
   StatusMsg := 'Arriere-plan.'; NeedStatRedraw := True;
  End;
 Else Begin
  StatusMsg := 'Action ' + IntToStr(A) + ' : a implementer (phase ulterieure).';
  NeedStatRedraw := True;
 End;
 End;
End;

{ ====================================================================== }
{                       GESTION SOURIS                                   }
{ ====================================================================== }

Procedure HandleMenuBarClick;
Var M: Integer;
Begin
 M := MenuAtX(Mouse.X);
 If M = 0 Then Begin
  MenuOpen := 0; NeedFullRedraw := True; Exit;
 End;
 If M = MenuOpen Then MenuOpen := 0
 Else Begin
  MenuOpen := M;
  MenuItemHover := 0;
  MenuKbdActive := False;
  MenuKbdMx := Mouse.X; MenuKbdMy := Mouse.Y;
 end;
 NeedFullRedraw := True;
End;

Procedure HandleDropDownClick;
Var Idx, Act: Integer;
Begin
 If MenuOpen = 0 Then Exit;
 If InRect(Mouse.X, Mouse.Y, DropX, DropY, DropX + DropW, DropY + DropH) Then Begin
  Idx := DropItemAtY(MenuOpen, Mouse.Y);
  If Idx > 0 Then Begin
   Act := Menus[MenuOpen].Items[Idx].Action;
   MenuOpen := 0;
   NeedFullRedraw := True;
   If Act <> 0 Then DoAction(Act);
  End;
 End
 Else Begin
  MenuOpen := 0;
  NeedFullRedraw := True;
 End;
End;

Function ShapeAt(SX, SY: Integer): Integer;
Var I, X1, Y1, X2, Y2: Integer; S: PSlide; Sh: PShape;
Begin
 ShapeAt := 0;
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 S := Pres.Slides[CurSlide];
 For I := S^.ShCount Downto 1 Do Begin
  Sh := S^.Shapes[I];
  If (Sh = Nil) Or Sh^.Hidden Then Continue;
  X1 := LogX(Sh^.X);
  Y1 := LogY(Sh^.Y);
  X2 := LogX(Sh^.X + Sh^.W);
  Y2 := LogY(Sh^.Y + Sh^.H);
  If InRect(SX, SY, X1, Y1, X2, Y2) Then Begin
   ShapeAt := I; Exit;
  End;
 End;
End;

{ ====================================================================== }
{        PHASE 2 - INVERSE COORDS, POIGNEES, MANIPULATION                }
{ ====================================================================== }

Function ScreenToLogX(SX: Integer): Integer;
Var W: LongInt;
Begin
 W := SlideX2 - SlideX1; If W <= 0 Then W := 1;
 ScreenToLogX := (LongInt(SX - SlideX1) * 1000) Div W;
End;

Function ScreenToLogY(SY: Integer): Integer;
Var H: LongInt;
Begin
 H := SlideY2 - SlideY1; If H <= 0 Then H := 1;
 ScreenToLogY := (LongInt(SY - SlideY1) * 750) Div H;
End;

Function ScreenToLogW(SW: Integer): Integer;
Var W: LongInt;
Begin
 W := SlideX2 - SlideX1; If W <= 0 Then W := 1;
 ScreenToLogW := (LongInt(SW) * 1000) Div W;
End;

Function ScreenToLogH(SH: Integer): Integer;
Var H: LongInt;
Begin
 H := SlideY2 - SlideY1; If H <= 0 Then H := 1;
 ScreenToLogH := (LongInt(SH) * 750) Div H;
End;

{ Retourne 1..8 si (X,Y) est sur une poignee de la forme P, 0 sinon.
  Ordre : 1=NO 2=N 3=NE 4=E 5=SE 6=S 7=SO 8=O }
Function HitHandle(P: PShape; X, Y: Integer): Byte;
Var X1, Y1, X2, Y2, Cx, Cy: Integer;
Begin
 HitHandle := 0;
 If P = Nil Then Exit;
 X1 := LogX(P^.X); Y1 := LogY(P^.Y);
 X2 := LogX(P^.X + P^.W); Y2 := LogY(P^.Y + P^.H);
 Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
 If InRect(X, Y, X1 - 3, Y1 - 3, X1 + 1, Y1 + 1) Then Begin HitHandle := 1; Exit; End;
 If InRect(X, Y, Cx - 2, Y1 - 3, Cx + 2, Y1 + 1) Then Begin HitHandle := 2; Exit; End;
 If InRect(X, Y, X2 - 1, Y1 - 3, X2 + 3, Y1 + 1) Then Begin HitHandle := 3; Exit; End;
 If InRect(X, Y, X2 - 1, Cy - 2, X2 + 3, Cy + 2) Then Begin HitHandle := 4; Exit; End;
 If InRect(X, Y, X2 - 1, Y2 - 1, X2 + 3, Y2 + 3) Then Begin HitHandle := 5; Exit; End;
 If InRect(X, Y, Cx - 2, Y2 - 1, Cx + 2, Y2 + 3) Then Begin HitHandle := 6; Exit; End;
 If InRect(X, Y, X1 - 3, Y2 - 1, X1 + 1, Y2 + 3) Then Begin HitHandle := 7; Exit; End;
 If InRect(X, Y, X1 - 3, Cy - 2, X1 + 1, Cy + 2) Then Begin HitHandle := 8; Exit; End;
End;

{ Trace rectangle XOR pour bande elastique - efface si redessine }
Procedure XorRect(X1, Y1, X2, Y2: Integer);
Var T: Integer;
Begin
 If X2 < X1 Then Begin T := X1; X1 := X2; X2 := T; End;
 If Y2 < Y1 Then Begin T := Y1; Y1 := Y2; Y2 := T; End;
 SetWriteMode(XORPut);
 SetColor(CLR_WHITE);
 Rectangle(X1, Y1, X2, Y2);
 SetWriteMode(NormalPut);
End;

Procedure XorLine(X1, Y1, X2, Y2: Integer);
Begin
 SetWriteMode(XORPut);
 SetColor(CLR_WHITE);
 Line(X1, Y1, X2, Y2);
 SetWriteMode(NormalPut);
End;

Procedure EraseRubberBand;
Begin
 If Not RubberValid Then Exit;
 If DragMode = 3 Then Begin
  Case DragShapeKind Of
   SHP_LINE, SHP_ARROW: XorLine(RubberX1, RubberY1, RubberX2, RubberY2);
  Else XorRect(RubberX1, RubberY1, RubberX2, RubberY2);
  End;
 End Else
  XorRect(RubberX1, RubberY1, RubberX2, RubberY2);
 RubberValid := False;
End;

Procedure DrawRubberBand(X1, Y1, X2, Y2: Integer);
Begin
 EraseRubberBand;
 If DragMode = 3 Then Begin
  Case DragShapeKind Of
   SHP_LINE, SHP_ARROW: XorLine(X1, Y1, X2, Y2);
  Else XorRect(X1, Y1, X2, Y2);
  End;
 End Else
  XorRect(X1, Y1, X2, Y2);
 RubberX1 := X1; RubberY1 := Y1;
 RubberX2 := X2; RubberY2 := Y2;
 RubberValid := True;
End;

Function ToolToShapeKind(T: Integer): Byte;
Begin
 ToolToShapeKind := 0;
 Case T Of
  TOOL_TEXT:     ToolToShapeKind := SHP_TEXT;
  TOOL_RECT:     ToolToShapeKind := SHP_RECT;
  TOOL_ELLIPSE:  ToolToShapeKind := SHP_ELLIPSE;
  TOOL_LINE:     ToolToShapeKind := SHP_LINE;
  TOOL_ARROW:    ToolToShapeKind := SHP_ARROW;
  TOOL_TRIANGLE: ToolToShapeKind := SHP_TRIANGLE;
  TOOL_STAR:     ToolToShapeKind := SHP_STAR;
  TOOL_CALLOUT:  ToolToShapeKind := SHP_CALLOUT;
 End;
End;

{ Insere une forme dans la slide courante a partir d'un rect logique }
Function CreateShapeRect(Kind: Byte; LX1, LY1, LX2, LY2: Integer): Integer;
Var Sh: PShape; T: Integer;
Begin
 CreateShapeRect := 0;
 If (CurSlide < 1) Or (CurSlide > Pres.SldCount) Then Exit;
 If LX2 < LX1 Then Begin T := LX1; LX1 := LX2; LX2 := T; End;
 If LY2 < LY1 Then Begin T := LY1; LY1 := LY2; LY2 := T; End;
 { Taille minimum sauf pour lignes }
 If (Kind <> SHP_LINE) And (Kind <> SHP_ARROW) Then Begin
  If LX2 - LX1 < 20 Then LX2 := LX1 + 20;
  If LY2 - LY1 < 20 Then LY2 := LY1 + 20;
 End Else Begin
  If LX2 - LX1 < 4 Then LX2 := LX1 + 4;
  If LY2 - LY1 < 4 Then LY2 := LY1 + 4;
 End;
 If LX1 < 0 Then LX1 := 0; If LY1 < 0 Then LY1 := 0;
 If LX2 > 1000 Then LX2 := 1000; If LY2 > 750 Then LY2 := 750;
 Sh := NewShape;
 If Sh = Nil Then Exit;
 Sh^.ShType := Kind;
 Sh^.X := LX1; Sh^.Y := LY1;
 Sh^.W := LX2 - LX1; Sh^.H := LY2 - LY1;
 Case Kind Of
  SHP_LINE, SHP_ARROW: Begin
   Sh^.FillColor := 0; Sh^.LineColor := CLR_BLACK;
   Sh^.Filled := False; Sh^.LineWidth := 2;
  End;
  SHP_TEXT: Begin
   Sh^.FillColor := CLR_WHITE; Sh^.LineColor := CLR_LGRAY;
   Sh^.Filled := False; Sh^.LineWidth := 1;
   Sh^.TxtCount := 1; Sh^.Text[1] := 'Zone de texte';
   Sh^.FontSize := 14;
  End;
  SHP_STAR: Begin
   Sh^.FillColor := CLR_YELLOW; Sh^.LineColor := CLR_BROWN;
   Sh^.Filled := True; Sh^.LineWidth := 1;
  End;
  SHP_TRIANGLE, SHP_DIAMOND: Begin
   Sh^.FillColor := CLR_LCYAN; Sh^.LineColor := CLR_BLUE;
   Sh^.Filled := True; Sh^.LineWidth := 1;
  End;
  SHP_CALLOUT: Begin
   Sh^.FillColor := CLR_YELLOW; Sh^.LineColor := CLR_BLACK;
   Sh^.Filled := True; Sh^.LineWidth := 1;
   Sh^.TxtCount := 1; Sh^.Text[1] := 'Bulle';
  End;
 Else Begin
  Sh^.FillColor := CLR_LBLUE; Sh^.LineColor := CLR_BLUE;
  Sh^.Filled := True; Sh^.LineWidth := 1;
 End;
 End;
 AddShapeToSlide(Pres.Slides[CurSlide], Sh);
 CreateShapeRect := Pres.Slides[CurSlide]^.ShCount;
 Pres.Slides[CurSlide]^.Dirty := True;
 Pres.Dirty := True;
End;

Procedure RemoveShapeAt(SlIdx, ShIdx: Integer);
Var I: Integer; S: PSlide;
Begin
 If (SlIdx < 1) Or (SlIdx > Pres.SldCount) Then Exit;
 S := Pres.Slides[SlIdx];
 If (ShIdx < 1) Or (ShIdx > S^.ShCount) Then Exit;
 FreeShape(S^.Shapes[ShIdx]);
 For I := ShIdx To S^.ShCount - 1 Do
  S^.Shapes[I] := S^.Shapes[I + 1];
 S^.Shapes[S^.ShCount] := Nil;
 Dec(S^.ShCount);
 S^.Dirty := True;
 Pres.Dirty := True;
End;

Procedure ShapeBringFront;
Var S: PSlide; P: PShape; I: Integer;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 S := Pres.Slides[CurSlide];
 If CurShape >= S^.ShCount Then Exit;
 P := S^.Shapes[CurShape];
 For I := CurShape To S^.ShCount - 1 Do
  S^.Shapes[I] := S^.Shapes[I + 1];
 S^.Shapes[S^.ShCount] := P;
 CurShape := S^.ShCount;
 S^.Dirty := True; Pres.Dirty := True;
End;

Procedure ShapeSendBack;
Var S: PSlide; P: PShape; I: Integer;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 S := Pres.Slides[CurSlide];
 If CurShape <= 1 Then Exit;
 P := S^.Shapes[CurShape];
 For I := CurShape Downto 2 Do
  S^.Shapes[I] := S^.Shapes[I - 1];
 S^.Shapes[1] := P;
 CurShape := 1;
 S^.Dirty := True; Pres.Dirty := True;
End;

Procedure ShapeDuplicate;
Var S: PSlide; Src, Dst: PShape;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 S := Pres.Slides[CurSlide];
 If S^.ShCount >= MAX_SHAPES Then Exit;
 Src := S^.Shapes[CurShape];
 Dst := NewShape; If Dst = Nil Then Exit;
 Dst^ := Src^;
 Dst^.X := Src^.X + 20; Dst^.Y := Src^.Y + 20;
 If Dst^.X + Dst^.W > 1000 Then Dst^.X := 1000 - Dst^.W;
 If Dst^.Y + Dst^.H > 750  Then Dst^.Y := 750  - Dst^.H;
 AddShapeToSlide(S, Dst);
 CurShape := S^.ShCount;
 S^.Dirty := True; Pres.Dirty := True;
End;

Procedure NudgeShape(Dx, Dy: Integer);
Var P: PShape;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 P^.X := P^.X + Dx; P^.Y := P^.Y + Dy;
 If P^.X < 0 Then P^.X := 0;
 If P^.Y < 0 Then P^.Y := 0;
 If P^.X + P^.W > 1000 Then P^.X := 1000 - P^.W;
 If P^.Y + P^.H > 750  Then P^.Y := 750  - P^.H;
 Pres.Slides[CurSlide]^.Dirty := True; Pres.Dirty := True;
 NeedSlideRedraw := True;
End;

Procedure ResizeShapeKey(Dw, Dh: Integer);
Var P: PShape;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 P^.W := P^.W + Dw; P^.H := P^.H + Dh;
 If P^.W < 20 Then P^.W := 20;
 If P^.H < 20 Then P^.H := 20;
 If P^.X + P^.W > 1000 Then P^.W := 1000 - P^.X;
 If P^.Y + P^.H > 750  Then P^.H := 750  - P^.Y;
 Pres.Slides[CurSlide]^.Dirty := True; Pres.Dirty := True;
 NeedSlideRedraw := True;
End;

Procedure CycleShapeSelection(Reverse: Boolean);
Var N: Integer;
Begin
 If CurSlide < 1 Then Exit;
 N := Pres.Slides[CurSlide]^.ShCount;
 If N = 0 Then Begin CurShape := 0; Exit; End;
 If Reverse Then Begin
  Dec(CurShape);
  If CurShape < 1 Then CurShape := N;
 End Else Begin
  Inc(CurShape);
  If CurShape > N Then CurShape := 1;
 End;
 NeedSlideRedraw := True;
End;

Procedure UpdateDrag;
Var P: PShape; Lx, Ly, Ldx, Ldy: Integer;
    NX, NY, NW, NH: Integer;
    SX1, SY1, SX2, SY2: Integer;
Begin
 If DragMode = 0 Then Exit;
 If (Mouse.X = LastMouseX) And (Mouse.Y = LastMouseY) Then Exit;
 LastMouseX := Mouse.X; LastMouseY := Mouse.Y;
 Case DragMode Of
  1: Begin   { deplacement }
   P := Pres.Slides[CurSlide]^.Shapes[DragShapeIdx];
   If P = Nil Then Exit;
   Ldx := ScreenToLogW(Mouse.X - DragStartX);
   Ldy := ScreenToLogH(Mouse.Y - DragStartY);
   NX := DragOrigX + Ldx; NY := DragOrigY + Ldy;
   If NX < 0 Then NX := 0; If NY < 0 Then NY := 0;
   If NX + P^.W > 1000 Then NX := 1000 - P^.W;
   If NY + P^.H > 750  Then NY := 750  - P^.H;
   P^.X := NX; P^.Y := NY;
   NeedSlideRedraw := True;
  End;
  2: Begin   { resize par poignee }
   P := Pres.Slides[CurSlide]^.Shapes[DragShapeIdx];
   If P = Nil Then Exit;
   Ldx := ScreenToLogW(Mouse.X - DragStartX);
   Ldy := ScreenToLogH(Mouse.Y - DragStartY);
   NX := DragOrigX; NY := DragOrigY;
   NW := DragOrigW; NH := DragOrigH;
   Case DragHandle Of
    1: Begin NX := DragOrigX + Ldx; NY := DragOrigY + Ldy;
             NW := DragOrigW - Ldx; NH := DragOrigH - Ldy; End;
    2: Begin NY := DragOrigY + Ldy; NH := DragOrigH - Ldy; End;
    3: Begin NY := DragOrigY + Ldy;
             NW := DragOrigW + Ldx; NH := DragOrigH - Ldy; End;
    4: Begin NW := DragOrigW + Ldx; End;
    5: Begin NW := DragOrigW + Ldx; NH := DragOrigH + Ldy; End;
    6: Begin NH := DragOrigH + Ldy; End;
    7: Begin NX := DragOrigX + Ldx;
             NW := DragOrigW - Ldx; NH := DragOrigH + Ldy; End;
    8: Begin NX := DragOrigX + Ldx; NW := DragOrigW - Ldx; End;
   End;
   If NW < 20 Then Begin NW := 20; If DragHandle In [1,7,8] Then NX := DragOrigX + DragOrigW - 20; End;
   If NH < 20 Then Begin NH := 20; If DragHandle In [1,2,3] Then NY := DragOrigY + DragOrigH - 20; End;
   If NX < 0 Then Begin NW := NW + NX; NX := 0; End;
   If NY < 0 Then Begin NH := NH + NY; NY := 0; End;
   If NX + NW > 1000 Then NW := 1000 - NX;
   If NY + NH > 750  Then NH := 750  - NY;
   P^.X := NX; P^.Y := NY; P^.W := NW; P^.H := NH;
   NeedSlideRedraw := True;
  End;
  3, 4: Begin   { rubber-band : nouvelle forme ou marquee }
   SX1 := DragStartX; SY1 := DragStartY;
   SX2 := Mouse.X;    SY2 := Mouse.Y;
   If SX2 < SlideX1 Then SX2 := SlideX1;
   If SY2 < SlideY1 Then SY2 := SlideY1;
   If SX2 > SlideX2 Then SX2 := SlideX2;
   If SY2 > SlideY2 Then SY2 := SlideY2;
   AppHideMouse;
   DrawRubberBand(SX1, SY1, SX2, SY2);
   AppShowMouse;
  End;
 End;
End;

Procedure EndDrag;
Var Lx1, Ly1, Lx2, Ly2, Idx, T: Integer;
    S: PSlide; Sh: PShape; X1, Y1, X2, Y2: Integer;
Begin
 If DragMode = 0 Then Exit;
 Case DragMode Of
  1, 2: Begin
   Pres.Slides[CurSlide]^.Dirty := True;
   Pres.Dirty := True;
   NeedSlideRedraw := True;
   NeedPanelRedraw := True;
  End;
  3: Begin   { creation d'une forme par drag }
   AppHideMouse;
   EraseRubberBand;
   AppShowMouse;
   Lx1 := ScreenToLogX(DragStartX);
   Ly1 := ScreenToLogY(DragStartY);
   Lx2 := ScreenToLogX(Mouse.X);
   Ly2 := ScreenToLogY(Mouse.Y);
   Idx := CreateShapeRect(DragShapeKind, Lx1, Ly1, Lx2, Ly2);
   If Idx > 0 Then Begin
    CurShape := Idx;
    StatusMsg := 'Forme ajoutee.';
   End;
   { Retour outil selection apres dessin (comportement Visio/PowerPoint) }
   CurTool := TOOL_SELECT;
   NeedFullRedraw := True;
  End;
  4: Begin   { marquee selection - selectionne premiere forme dans le cadre }
   AppHideMouse;
   EraseRubberBand;
   AppShowMouse;
   If CurSlide >= 1 Then Begin
    S := Pres.Slides[CurSlide];
    X1 := DragStartX; Y1 := DragStartY;
    X2 := Mouse.X;    Y2 := Mouse.Y;
    If X2 < X1 Then Begin T := X1; X1 := X2; X2 := T; End;
    If Y2 < Y1 Then Begin T := Y1; Y1 := Y2; Y2 := T; End;
    For T := S^.ShCount Downto 1 Do Begin
     Sh := S^.Shapes[T];
     If Sh = Nil Then Continue;
     If (LogX(Sh^.X) >= X1) And (LogY(Sh^.Y) >= Y1) And
        (LogX(Sh^.X + Sh^.W) <= X2) And (LogY(Sh^.Y + Sh^.H) <= Y2) Then Begin
      CurShape := T; Break;
     End;
    End;
   End;
   NeedSlideRedraw := True;
  End;
 End;
 DragMode := 0;
 DragHandle := 0;
 RubberValid := False;
End;

{ ====================================================================== }
{          PHASE 3 - EDITION DE TEXTE RICHE DANS LES FORMES              }
{ ====================================================================== }

Function ShapeAcceptsText(P: PShape): Boolean;
Begin
 ShapeAcceptsText := False;
 If P = Nil Then Exit;
 Case P^.ShType Of
  SHP_TITLE, SHP_SUBTITLE, SHP_CONTENT, SHP_TEXT,
  SHP_CALLOUT, SHP_RECT, SHP_ROUNDRECT, SHP_ELLIPSE,
  SHP_TRIANGLE, SHP_DIAMOND, SHP_STAR:
   ShapeAcceptsText := True;
 End;
End;

Function IsPlaceholderText(Const S: String): Boolean;
Begin
 IsPlaceholderText := (Pos('Cliquez pour ajouter', S) = 1);
End;

Procedure CommitEditBuf;
Var P: PShape;
Begin
 If Not EditMode Then Exit;
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 If (EditLine < 1) Or (EditLine > MAX_TEXT_LINES) Then Exit;
 If Length(EditBuf) > TXT_LINE_LEN Then EditBuf[0] := Chr(TXT_LINE_LEN);
 P^.Text[EditLine] := EditBuf;
 If EditLine > P^.TxtCount Then P^.TxtCount := EditLine;
 Pres.Slides[CurSlide]^.Dirty := True;
 Pres.Dirty := True;
End;

Procedure ExitEditMode;
Begin
 If Not EditMode Then Exit;
 CommitEditBuf;
 EditMode := False;
 EditBuf := '';
 EditCaret := 0;
 EditLine := 0;
 StatusMsg := 'Edition terminee.';
 NeedSlideRedraw := True;
 NeedStatRedraw := True;
End;

Procedure LoadEditLine(P: PShape; LineIdx: Integer);
Begin
 EditLine := LineIdx;
 If (LineIdx >= 1) And (LineIdx <= P^.TxtCount) Then Begin
  EditBuf := P^.Text[LineIdx];
  If IsPlaceholderText(EditBuf) Then EditBuf := '';
 End Else Begin
  EditBuf := '';
 End;
 EditCaret := Length(EditBuf);
End;

Procedure EnterEditMode(ShIdx, LineIdx: Integer);
Var P: PShape;
Begin
 If (CurSlide < 1) Or (ShIdx < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[ShIdx];
 If Not ShapeAcceptsText(P) Then Exit;
 If P^.TxtCount = 0 Then Begin
  P^.TxtCount := 1; P^.Text[1] := ''; P^.Bullets[1] := False; P^.Indent[1] := 0;
 End;
 If LineIdx < 1 Then LineIdx := 1;
 If LineIdx > P^.TxtCount Then LineIdx := P^.TxtCount;
 CurShape := ShIdx;
 EditMode := True;
 LoadEditLine(P, LineIdx);
 StatusMsg := 'Edition de texte (Esc pour terminer).';
 NeedSlideRedraw := True;
 NeedStatRedraw := True;
End;

Procedure EditInsertChar(C: Char);
Begin
 If Not EditMode Then Exit;
 If Length(EditBuf) >= TXT_LINE_LEN Then Exit;
 If (EditCaret < 0) Then EditCaret := 0;
 If (EditCaret > Length(EditBuf)) Then EditCaret := Length(EditBuf);
 Insert(C, EditBuf, EditCaret + 1);
 Inc(EditCaret);
 NeedSlideRedraw := True;
End;

Procedure EditBackspace;
Begin
 If Not EditMode Then Exit;
 If EditCaret <= 0 Then Exit;
 Delete(EditBuf, EditCaret, 1);
 Dec(EditCaret);
 NeedSlideRedraw := True;
End;

Procedure EditDeleteChar;
Begin
 If Not EditMode Then Exit;
 If EditCaret >= Length(EditBuf) Then Exit;
 Delete(EditBuf, EditCaret + 1, 1);
 NeedSlideRedraw := True;
End;

Procedure EditMoveCaret(Dx: Integer);
Begin
 If Not EditMode Then Exit;
 Inc(EditCaret, Dx);
 If EditCaret < 0 Then EditCaret := 0;
 If EditCaret > Length(EditBuf) Then EditCaret := Length(EditBuf);
 NeedSlideRedraw := True;
End;

Procedure EditMoveLine(Dy: Integer);
Var P: PShape; N, NewLine: Integer;
Begin
 If Not EditMode Then Exit;
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 CommitEditBuf;
 N := P^.TxtCount;
 NewLine := EditLine + Dy;
 If NewLine < 1 Then NewLine := 1;
 If NewLine > N Then NewLine := N;
 LoadEditLine(P, NewLine);
 NeedSlideRedraw := True;
End;

Procedure EditHomeEnd(ToEnd: Boolean);
Begin
 If Not EditMode Then Exit;
 If ToEnd Then EditCaret := Length(EditBuf) Else EditCaret := 0;
 NeedSlideRedraw := True;
End;

Procedure EditNewLine;
Var P: PShape; I: Integer;
Begin
 If Not EditMode Then Exit;
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 If P^.TxtCount >= MAX_TEXT_LINES Then Exit;
 CommitEditBuf;
 { Decale les lignes apres EditLine vers le bas }
 For I := P^.TxtCount Downto EditLine + 1 Do Begin
  P^.Text[I + 1]    := P^.Text[I];
  P^.Bullets[I + 1] := P^.Bullets[I];
  P^.Indent[I + 1]  := P^.Indent[I];
 End;
 Inc(P^.TxtCount);
 P^.Text[EditLine + 1]    := '';
 P^.Bullets[EditLine + 1] := P^.Bullets[EditLine];
 P^.Indent[EditLine + 1]  := P^.Indent[EditLine];
 Inc(EditLine);
 EditBuf := '';
 EditCaret := 0;
 NeedSlideRedraw := True;
End;

Procedure EditBackLine;
Var P: PShape; I, PrevLen: Integer;
Begin
 { Backspace en debut de ligne : fusionne avec la precedente }
 If Not EditMode Then Exit;
 If EditLine <= 1 Then Exit;
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 CommitEditBuf;
 PrevLen := Length(P^.Text[EditLine - 1]);
 If PrevLen + Length(P^.Text[EditLine]) <= TXT_LINE_LEN Then
  P^.Text[EditLine - 1] := P^.Text[EditLine - 1] + P^.Text[EditLine];
 For I := EditLine To P^.TxtCount - 1 Do Begin
  P^.Text[I]    := P^.Text[I + 1];
  P^.Bullets[I] := P^.Bullets[I + 1];
  P^.Indent[I]  := P^.Indent[I + 1];
 End;
 P^.Text[P^.TxtCount] := '';
 P^.Bullets[P^.TxtCount] := False;
 P^.Indent[P^.TxtCount] := 0;
 Dec(P^.TxtCount);
 Dec(EditLine);
 LoadEditLine(P, EditLine);
 EditCaret := PrevLen;
 NeedSlideRedraw := True;
End;

Procedure EditIndent(Delta: Integer);
Var P: PShape;
Begin
 If Not EditMode Then Exit;
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 If (EditLine < 1) Or (EditLine > MAX_TEXT_LINES) Then Exit;
 If Delta > 0 Then Begin
  If P^.Indent[EditLine] < 5 Then Inc(P^.Indent[EditLine]);
 End Else Begin
  If P^.Indent[EditLine] > 0 Then Dec(P^.Indent[EditLine]);
 End;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
End;

Procedure EditToggleBullet;
Var P: PShape; I: Integer; NewVal: Boolean;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 If EditMode Then Begin
  P^.Bullets[EditLine] := Not P^.Bullets[EditLine];
 End Else Begin
  If P^.TxtCount > 0 Then NewVal := Not P^.Bullets[1] Else NewVal := True;
  For I := 1 To P^.TxtCount Do P^.Bullets[I] := NewVal;
 End;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
End;

{ Detection ligne ciblee par un clic dans la forme }
Function LineAtY(P: PShape; SY: Integer): Integer;
Var Ty, LineH, I, Y1: Integer;
Begin
 LineAtY := 1;
 If P^.TxtCount <= 0 Then Exit;
 LineH := 12;
 If P^.FontSize >= 24 Then LineH := 22
 Else If P^.FontSize >= 18 Then LineH := 16;
 Y1 := LogY(P^.Y);
 Ty := Y1 + 4;
 For I := 1 To P^.TxtCount Do Begin
  If (SY >= Ty) And (SY < Ty + LineH) Then Begin LineAtY := I; Exit; End;
  Ty := Ty + LineH;
 End;
 LineAtY := P^.TxtCount;
End;

Procedure ShapeApplyFontDelta(Delta: Integer);
Var P: PShape; F: Integer;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 F := P^.FontSize + Delta;
 If F < 8 Then F := 8;
 If F > 72 Then F := 72;
 P^.FontSize := F;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
 StatusMsg := 'Taille de police: ' + IntToStr(F);
 NeedStatRedraw := True;
End;

Procedure ShapeToggleBold;
Var P: PShape;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 P^.Bold := Not P^.Bold;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
End;

Procedure ShapeToggleItalic;
Var P: PShape;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 P^.Italic := Not P^.Italic;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
End;

Procedure ShapeToggleUnderline;
Var P: PShape;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 P^.Underline := Not P^.Underline;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
End;

Procedure ShapeSetAlign(A: Byte);
Var P: PShape;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 P^.Align := A;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
End;

Procedure ShapeCycleColor(Which: Byte);
{ Which : 0=fill 1=line 2=text. Cycle parmi 16 couleurs VGA }
Var P: PShape; C: Byte;
Begin
 If (CurSlide < 1) Or (CurShape < 1) Then Exit;
 P := Pres.Slides[CurSlide]^.Shapes[CurShape];
 If P = Nil Then Exit;
 Case Which Of
  0: Begin C := (P^.FillColor + 1) And 15; P^.FillColor := C;
           StatusMsg := 'Remplissage : couleur ' + IntToStr(C); End;
  1: Begin C := (P^.LineColor + 1) And 15; P^.LineColor := C;
           StatusMsg := 'Contour : couleur ' + IntToStr(C); End;
  2: Begin C := (P^.TextColor + 1) And 15; P^.TextColor := C;
           StatusMsg := 'Texte : couleur ' + IntToStr(C); End;
 End;
 Pres.Slides[CurSlide]^.Dirty := True;
 NeedSlideRedraw := True;
 NeedStatRedraw := True;
End;

Procedure HandleSlideAreaClick;
Var Idx: Integer; H: Byte; P: PShape; Kind: Byte;
Begin
 If Not InRect(Mouse.X, Mouse.Y, SlideX1, SlideY1, SlideX2, SlideY2) Then Begin
  If EditMode Then ExitEditMode;
  CurShape := 0; NeedSlideRedraw := True; Exit;
  End;
 { Si on est en edition, clic dans la meme forme = repositionne ligne, ailleurs = sort }
 If EditMode And (CurShape > 0) Then Begin
  Idx := ShapeAt(Mouse.X, Mouse.Y);
  P := Pres.Slides[CurSlide]^.Shapes[CurShape];
  If Idx = CurShape Then Begin
   CommitEditBuf;
   LoadEditLine(P, LineAtY(P, Mouse.Y));
   NeedSlideRedraw := True;
   Exit;
  End Else Begin
   ExitEditMode;
   { ne pas exit - continuer pour traiter le clic comme normal }
  End;
 End;
 { Double-clic sur une forme texte : entre en edition }
 If DoubleClicked Then Begin
  Idx := ShapeAt(Mouse.X, Mouse.Y);
  If Idx > 0 Then Begin
   P := Pres.Slides[CurSlide]^.Shapes[Idx];
   If ShapeAcceptsText(P) Then Begin
    EnterEditMode(Idx, LineAtY(P, Mouse.Y));
    Exit;
   End;
  End;
 End;
 { Outil de dessin actif : on amorce un drag rubber-band pour creer une forme }
 Kind := ToolToShapeKind(CurTool);
 If Kind <> 0 Then Begin
  DragMode      := 3;
  DragShapeKind := Kind;
  DragStartX    := Mouse.X; DragStartY := Mouse.Y;
  LastMouseX    := Mouse.X; LastMouseY := Mouse.Y;
  RubberValid   := False;
  CurShape      := 0;
  StatusMsg     := 'Glissez pour dimensionner la forme...';
  NeedStatRedraw := True;
  Exit;
 End;
 { Outil selection : tester poignee si forme deja selectionnee }
 If CurShape > 0 Then Begin
  P := Pres.Slides[CurSlide]^.Shapes[CurShape];
  H := HitHandle(P, Mouse.X, Mouse.Y);
  If H <> 0 Then Begin
   DragMode    := 2;
   DragHandle  := H;
   DragShapeIdx := CurShape;
   DragStartX  := Mouse.X; DragStartY := Mouse.Y;
   DragOrigX   := P^.X; DragOrigY := P^.Y;
   DragOrigW   := P^.W; DragOrigH := P^.H;
   LastMouseX  := Mouse.X; LastMouseY := Mouse.Y;
   StatusMsg   := 'Redimensionnement...';
   NeedStatRedraw := True;
   Exit;
  End;
 End;
 Idx := ShapeAt(Mouse.X, Mouse.Y);
 If Idx > 0 Then Begin
  CurShape := Idx;
  P := Pres.Slides[CurSlide]^.Shapes[Idx];
  DragMode     := 1;
  DragShapeIdx := Idx;
  DragStartX   := Mouse.X; DragStartY := Mouse.Y;
  DragOrigX    := P^.X; DragOrigY := P^.Y;
  LastMouseX   := Mouse.X; LastMouseY := Mouse.Y;
  StatusMsg    := 'Deplacement...';
  NeedSlideRedraw := True;
  NeedStatRedraw  := True;
 End Else Begin
  { Aucune forme : marquee }
  CurShape := 0;
  DragMode    := 4;
  DragStartX  := Mouse.X; DragStartY := Mouse.Y;
  LastMouseX  := Mouse.X; LastMouseY := Mouse.Y;
  RubberValid := False;
  NeedSlideRedraw := True;
 End;
End;

Procedure ExecuteRibbonEntry(Index: Integer);
Var A: Integer;
Begin
 If Not RibbonEntryEnabled(Index) Then Exit;
 A:=Menus[RibbonTab].Items[RibbonMenuItem(Index)].Action;
 RibbonKeyboard:=False;RibbonFocus:=0;MenuOpen:=0;NeedChromeRedraw:=True;DoAction(A);
End;
Procedure RibbonMoveFocus(Direction: Integer);
Var I: Integer;
Begin
 I:=RibbonFocus;If (I=0) And (Direction<0) Then I:=RibbonItemCount+1;
 Repeat
  Inc(I,Direction);If (I<1) Or (I>RibbonItemCount) Then Begin RibbonFocus:=0;Exit;End;
  If RibbonEntryEnabled(I) Then Begin RibbonFocus:=I;Exit;End;
 Until False;
End;
Function HandleRibbonKey(K,K2: Char): Boolean;
Var Tab,Direction: Integer;
Begin
 HandleRibbonKey:=False;If Not RibbonMode Then Exit;Tab:=0;
 If K=#0 Then Case K2 Of
  #33: Tab:=1;#18: Tab:=2;#30: Tab:=3;#23: Tab:=4;#46: Tab:=5;
  #20: Tab:=6;#50: Tab:=7;#32: Tab:=8;#19: Tab:=9;#35: Tab:=10;
 End;
 If Tab>0 Then Begin
  RibbonTab:=Tab;RibbonKeyboard:=True;RibbonFocus:=0;RibbonHover:=0;MenuOpen:=0;
  NeedChromeRedraw:=True;HandleRibbonKey:=True;Exit;
 End;
 If (K=#0) And (K2=#68) Then Begin
  RibbonKeyboard:=Not RibbonKeyboard;RibbonFocus:=0;NeedChromeRedraw:=True;HandleRibbonKey:=True;Exit;
 End;
 If Not RibbonKeyboard Then Exit;
 HandleRibbonKey:=True;Direction:=0;
 If K=#0 Then Case K2 Of
  #75: Direction:=-1;#77: Direction:=1;
  #72,#15: RibbonMoveFocus(-1);#80: RibbonMoveFocus(1);
  Else Begin RibbonKeyboard:=False;RibbonFocus:=0;HandleRibbonKey:=False;End;
 End Else Case K Of
  #9: RibbonMoveFocus(1);
  #27: If RibbonFocus>0 Then RibbonFocus:=0 Else RibbonKeyboard:=False;
  #13,' ': If RibbonFocus=0 Then RibbonMoveFocus(1) Else ExecuteRibbonEntry(RibbonFocus);
  Else Begin RibbonKeyboard:=False;RibbonFocus:=0;HandleRibbonKey:=False;End;
 End;
 If Direction<>0 Then Begin
  If RibbonFocus=0 Then Begin
   Inc(RibbonTab,Direction);If RibbonTab<1 Then RibbonTab:=MenuCount;
   If RibbonTab>MenuCount Then RibbonTab:=1;RibbonHover:=0;
  End Else RibbonMoveFocus(Direction);
 End;
 NeedChromeRedraw:=True;
End;

Procedure HandleMouseClick;
Var T, M: Integer; Idx: Integer;
Begin
 If RibbonMode Then Begin
  RibbonKeyboard:=False;RibbonFocus:=0;NeedChromeRedraw:=True;
  If (Mouse.Y>=MenuY1) And (Mouse.Y<=MenuY2) Then Begin
   T:=MenuAtX(Mouse.X);If T>0 Then Begin RibbonTab:=T;RibbonHover:=0;MenuOpen:=0;End;Exit;
  End;
  If (Mouse.Y>=ToolY1) And (Mouse.Y<=ToolY2) Then Begin
   T:=RibbonHitAt(Mouse.X,Mouse.Y);If T>0 Then ExecuteRibbonEntry(T);Exit;
  End;
 End;
 { Barre de menu }
 If InRect(Mouse.X, Mouse.Y, 0, MenuY1, SCREEN_W - 1, MenuY2) Then Begin
  HandleMenuBarClick; Exit;
 End;
 { Menu deroulant ouvert }
 If MenuOpen <> 0 Then Begin
  HandleDropDownClick; Exit;
 End;
 { Barre d'outils }
 If InRect(Mouse.X, Mouse.Y, 0, ToolY1, SCREEN_W - 1, ToolY2) Then Begin
  T := ToolAt(Mouse.X, Mouse.Y);
  If T > 0 Then Begin
   If Tools[T].Action <> 0 Then DoAction(Tools[T].Action);
  End;
  Exit;
 End;
 { Panneau miniatures }
 If InRect(Mouse.X, Mouse.Y, 0, MENU_H + TOOL_H, PANEL_W - 1,
           SCREEN_H - STATUS_H - 1) Then Begin
  Idx := SlideAtPanelY(Mouse.Y);
  If Idx > 0 Then Begin
   CurSlide := Idx; CurShape := 0; NeedFullRedraw := True;
  End;
  Exit;
 End;
 { Zone de slide }
 If InRect(Mouse.X, Mouse.Y, PANEL_W, MENU_H + TOOL_H + RULER_H,
           SCREEN_W - 1, SCREEN_H - STATUS_H - 1) Then Begin
  Case CurView Of
   VIEW_SORTER: Begin
    Idx := SorterAt(Mouse.X, Mouse.Y);
    If Idx > 0 Then Begin
     SorterSel := Idx; CurSlide := Idx; CurShape := 0;
     If DoubleClicked Then ActionViewChange(VIEW_NORMAL)
     Else NeedFullRedraw := True;
    End;
    Exit;
   End;
   VIEW_OUTLINE: Begin
    Idx := OutlineSlideAtY(Mouse.Y);
    If Idx > 0 Then Begin
     OutlineSel := Idx; CurSlide := Idx; CurShape := 0;
     If DoubleClicked Then ActionViewChange(VIEW_NORMAL)
     Else NeedFullRedraw := True;
    End;
    Exit;
   End;
   VIEW_NOTES: Begin
    If DoubleClicked Then ActionEditNotes;
    Exit;
   End;
  End;
  HandleSlideAreaClick; Exit;
 End;
 { Clic ailleurs : referme menu si actif }
 If MenuOpen <> 0 Then Begin
  MenuOpen := 0; NeedFullRedraw := True;
 End;
 M := 0; { evite avertissement variable inutilisee }
End;

Procedure UpdateHovers;
Var T, M, NewItem: Integer;
Begin
 If RibbonMode Then Begin
  M:=0;If (Mouse.Y>=MenuY1) And (Mouse.Y<=MenuY2) Then M:=MenuAtX(Mouse.X);
  T:=RibbonHitAt(Mouse.X,Mouse.Y);
  If (MenuHover<>M) Or (RibbonHover<>T) Then NeedChromeRedraw:=True;
  MenuHover:=M;RibbonHover:=T;ToolHover:=0;Exit;
 End;
 T := 0; M := 0;
 If InRect(Mouse.X, Mouse.Y, 0, MenuY1, SCREEN_W - 1, MenuY2) Then
  M := MenuAtX(Mouse.X);
 If MenuHover <> M Then Begin
  MenuHover := M;
  If MenuOpen = 0 Then DrawMenuBar;
 End;
 { Phase 12 fix : un menu deroulant est ouvert -- bascule automatique
   vers un autre menu si la souris survole un autre titre de la barre.
   MAIS si la selection clavier est active et que la souris n'a pas bouge,
   on ignore le survol-souris (sinon Gauche/Droite clavier est annule par
   la souris stationnaire sur l'ancien titre de menu). }
 If (MenuOpen <> 0) And (M <> 0) And (M <> MenuOpen) Then Begin
  If MenuKbdActive And
     (Mouse.X = MenuKbdMx) And (Mouse.Y = MenuKbdMy) Then Begin
   { ignorer : laisse le clavier piloter MenuOpen }
  End
  Else Begin
   MenuOpen := M;
   MenuItemHover := 0;
   MenuKbdActive := False;
   NeedFullRedraw := True;
   Exit;
  End;
 End;
 { Phase 12 fix : survol des items du menu deroulant ouvert.
   Si la selection a ete posee au clavier et que la souris n'a pas bouge,
   on ne touche PAS a MenuItemHover -- sinon la souris stationnaire ecrase
   la selection clavier a chaque tick. }
 If MenuOpen <> 0 Then Begin
  If MenuKbdActive And
     (Mouse.X = MenuKbdMx) And (Mouse.Y = MenuKbdMy) Then Begin
   { ne rien faire : laisse le clavier piloter MenuItemHover }
  End
  Else Begin
   MenuKbdActive := False;
   ComputeDropLayout(MenuOpen);
   If InRect(Mouse.X, Mouse.Y, DropX, DropY,
             DropX + DropW, DropY + DropH) Then
    NewItem := DropItemAtY(MenuOpen, Mouse.Y)
   Else
    NewItem := 0;
   SetMenuItemHover(NewItem);
  End;
 End;
 { Phase 12 fix : quand un menu deroulant est ouvert, on n'evalue PAS le
   survol des outils -- la souris sur le dropdown chevauche visuellement la
   barre d'outils en Y, ce qui declenche un repaint/flash de la toolbar a
   chaque pixel deplace. }
 If MenuOpen = 0 Then Begin
  If InRect(Mouse.X, Mouse.Y, 0, ToolY1, SCREEN_W - 1, ToolY2) Then
   T := ToolAt(Mouse.X, Mouse.Y);
  If ToolHover <> T Then Begin
   ToolHover := T;
   DrawToolBar;
   If T > 0 Then Begin
    StatusMsg := Tools[T].Hint;
    NeedStatRedraw := True;
   End;
  End;
 End;
 { Met a jour la position dans la status bar quand on est sur la slide }
 If InRect(Mouse.X, Mouse.Y, SlideX1, SlideY1, SlideX2, SlideY2) Then Begin
  { rien pour Phase 1 }
 End;
End;

{ ====================================================================== }
{                       GESTION CLAVIER                                  }
{ ====================================================================== }

Procedure HandleKey(K, K2: Char);
Var NewSel, Tries, Act: Integer;
Begin
 If HandleRibbonKey(K,K2) Then Exit;
 { ----- MENU DEROULANT OUVERT : priorite absolue clavier ----- }
 If MenuOpen <> 0 Then Begin
  If K = #0 Then Begin
   Case K2 Of
    #80: Begin   { Down : item selectable suivant }
     If Menus[MenuOpen].Count = 0 Then Exit;
     NewSel := MenuItemHover; Tries := 0;
     Repeat
      Inc(NewSel);
      If NewSel > Menus[MenuOpen].Count Then NewSel := 1;
      Inc(Tries);
     Until (Not Menus[MenuOpen].Items[NewSel].IsSep) Or
           (Tries > Menus[MenuOpen].Count);
     SetMenuItemHover(NewSel);
     MenuKbdActive := True; MenuKbdMx := Mouse.X; MenuKbdMy := Mouse.Y;
     Exit;
    End;
    #72: Begin   { Up : item selectable precedent }
     If Menus[MenuOpen].Count = 0 Then Exit;
     If MenuItemHover = 0 Then NewSel := 1 Else NewSel := MenuItemHover;
     Tries := 0;
     Repeat
      Dec(NewSel);
      If NewSel < 1 Then NewSel := Menus[MenuOpen].Count;
      Inc(Tries);
     Until (Not Menus[MenuOpen].Items[NewSel].IsSep) Or
           (Tries > Menus[MenuOpen].Count);
     SetMenuItemHover(NewSel);
     MenuKbdActive := True; MenuKbdMx := Mouse.X; MenuKbdMy := Mouse.Y;
     Exit;
    End;
    #75: Begin   { Left : menu precedent }
     Dec(MenuOpen); If MenuOpen < 1 Then MenuOpen := MenuCount;
     MenuItemHover := 0;
     MenuKbdActive := True; MenuKbdMx := Mouse.X; MenuKbdMy := Mouse.Y;
     NeedFullRedraw := True; Exit;
    End;
    #77: Begin   { Right : menu suivant }
     Inc(MenuOpen); If MenuOpen > MenuCount Then MenuOpen := 1;
     MenuItemHover := 0;
     MenuKbdActive := True; MenuKbdMx := Mouse.X; MenuKbdMy := Mouse.Y;
     NeedFullRedraw := True; Exit;
    End;
    #71: Begin   { Home : premier selectable }
     NewSel := 1;
     While (NewSel <= Menus[MenuOpen].Count) And
           Menus[MenuOpen].Items[NewSel].IsSep Do Inc(NewSel);
     If NewSel <= Menus[MenuOpen].Count Then SetMenuItemHover(NewSel);
     MenuKbdActive := True; MenuKbdMx := Mouse.X; MenuKbdMy := Mouse.Y;
     Exit;
    End;
    #79: Begin   { End : dernier selectable }
     NewSel := Menus[MenuOpen].Count;
     While (NewSel >= 1) And Menus[MenuOpen].Items[NewSel].IsSep Do Dec(NewSel);
     If NewSel >= 1 Then SetMenuItemHover(NewSel);
     MenuKbdActive := True; MenuKbdMx := Mouse.X; MenuKbdMy := Mouse.Y;
     Exit;
    End;
   End;
   Exit;
  End;
  Case K Of
   #27: Begin   { Esc : ferme }
    MenuOpen := 0; MenuItemHover := 0; MenuKbdActive := False;
    NeedFullRedraw := True; Exit;
   End;
   #13: Begin   { Enter : active }
    If (MenuItemHover >= 1) And (MenuItemHover <= Menus[MenuOpen].Count) And
       (Not Menus[MenuOpen].Items[MenuItemHover].IsSep) Then Begin
     Act := Menus[MenuOpen].Items[MenuItemHover].Action;
     MenuOpen := 0; MenuItemHover := 0; MenuKbdActive := False;
     NeedFullRedraw := True;
     If Act <> 0 Then DoAction(Act);
    End;
    Exit;
   End;
  End;
  Exit;
 End;
 { ----- MODE EDITION TEXTE : priorite absolue ----- }
 If EditMode Then Begin
  If K = #0 Then Begin
   Case K2 Of
    #75: EditMoveCaret(-1);            { Left }
    #77: EditMoveCaret(+1);            { Right }
    #72: EditMoveLine(-1);             { Up }
    #80: EditMoveLine(+1);             { Down }
    #71: EditHomeEnd(False);           { Home }
    #79: EditHomeEnd(True);            { End }
    #83: EditDeleteChar;               { Delete }
    #15: EditIndent(+1);               { Shift+Tab in some maps - here Tab key }
    #59: DoAction(ACT_HELP_TOPIC);     { F1 }
    #107,#45: Begin ExitEditMode; DoAction(ACT_QUIT); End;
   End;
   Exit;
  End;
  Case K Of
   #27: ExitEditMode;
   #13: EditNewLine;
   #8 : Begin
    If EditCaret > 0 Then EditBackspace Else EditBackLine;
   End;
   #9 : EditIndent(+1);
  Else Begin
   If (K >= ' ') And (K <= #126) Then EditInsertChar(K)
   Else If K >= #128 Then EditInsertChar(K);  { caracteres etendus 8 bits }
  End;
  End;
  Exit;
 End;
 { ----- MODES TRIEUSE / PLAN / NOTES ----- }
 If CurView = VIEW_SORTER Then Begin
  If K = #0 Then Begin
   Case K2 Of
    #75: If SorterSel > 1 Then Begin Dec(SorterSel); CurSlide := SorterSel; NeedFullRedraw := True; End;
    #77: If SorterSel < Pres.SldCount Then Begin Inc(SorterSel); CurSlide := SorterSel; NeedFullRedraw := True; End;
    #72: If SorterSel > SORT_COLS Then Begin Dec(SorterSel, SORT_COLS); CurSlide := SorterSel; NeedFullRedraw := True; End;
    #80: If SorterSel + SORT_COLS <= Pres.SldCount Then Begin Inc(SorterSel, SORT_COLS); CurSlide := SorterSel; NeedFullRedraw := True; End;
    #71: Begin SorterSel := 1; CurSlide := 1; NeedFullRedraw := True; End;
    #79: Begin SorterSel := Pres.SldCount; CurSlide := SorterSel; NeedFullRedraw := True; End;
    #83: Begin DoAction(ACT_DEL_SLIDE); Exit; End;
    #107,#45: Begin DoAction(ACT_QUIT); Exit; End;
   End;
   Exit;
  End;
  Case K Of
   #13: Begin ActionViewChange(VIEW_NORMAL); Exit; End;
   #27: Begin ActionViewChange(VIEW_NORMAL); Exit; End;
  End;
  { Tombe en raccourcis globaux pour Ctrl+* }
 End;
 If CurView = VIEW_OUTLINE Then Begin
  If K = #0 Then Begin
   Case K2 Of
    #72: If OutlineSel > 1 Then Begin Dec(OutlineSel); CurSlide := OutlineSel; NeedFullRedraw := True; End;
    #80: If OutlineSel < Pres.SldCount Then Begin Inc(OutlineSel); CurSlide := OutlineSel; NeedFullRedraw := True; End;
    #71: Begin OutlineSel := 1; CurSlide := 1; NeedFullRedraw := True; End;
    #79: Begin OutlineSel := Pres.SldCount; CurSlide := OutlineSel; NeedFullRedraw := True; End;
    #73: Begin Dec(OutlineScroll, 80); If OutlineScroll < 0 Then OutlineScroll := 0; NeedFullRedraw := True; End;
    #81: Begin Inc(OutlineScroll, 80); NeedFullRedraw := True; End;
    #107,#45: Begin DoAction(ACT_QUIT); Exit; End;
   End;
   Exit;
  End;
  Case K Of
   #13: Begin ActionViewChange(VIEW_NORMAL); Exit; End;
   #27: Begin ActionViewChange(VIEW_NORMAL); Exit; End;
  End;
 End;
 If CurView = VIEW_NOTES Then Begin
  If K = #0 Then Begin
   Case K2 Of
    #73,#75: ActionPrevSlide;
    #81,#77: ActionNextSlide;
    #71: ActionFirstSlide;
    #79: ActionLastSlide;
    #107,#45: DoAction(ACT_QUIT);
   End;
   Exit;
  End;
  Case K Of
   #13: Begin ActionEditNotes; Exit; End;
   #27: Begin ActionViewChange(VIEW_NORMAL); Exit; End;
  End;
 End;
 { Raccourcis globaux }
 If K = #0 Then Begin
  Case K2 Of
   #107: Begin DoAction(ACT_QUIT);        Exit; End;   { Alt+F4 }
   #45 : Begin DoAction(ACT_QUIT);        Exit; End;   { Alt+X  }
   #59 : Begin DoAction(ACT_HELP_TOPIC);  Exit; End;   { F1 }
   #63 : Begin DoAction(ACT_SLIDESHOW);   Exit; End;   { F5 }
   #50 : Begin DoAction(ACT_NEW_SLIDE);   Exit; End;   { Ctrl+M : scan 50 = M }
   #15 : Begin                                          { Tab : cycle forme }
    CycleShapeSelection(False); Exit;
   End;
   #83 : Begin                                          { Delete }
    If CurShape > 0 Then DoAction(ACT_DELETE);
    Exit;
   End;
   #80 : Begin
    If CurShape > 0 Then NudgeShape(0,  10) Else ActionNextSlide; Exit;
   End;
   #72 : Begin
    If CurShape > 0 Then NudgeShape(0, -10) Else ActionPrevSlide; Exit;
   End;
   #77 : Begin
    If CurShape > 0 Then NudgeShape( 10, 0) Else ActionNextSlide; Exit;
   End;
   #75 : Begin
    If CurShape > 0 Then NudgeShape(-10, 0) Else ActionPrevSlide; Exit;
   End;
   #81 : Begin ActionNextSlide;           Exit; End;   { PgDn }
   #73 : Begin ActionPrevSlide;           Exit; End;   { PgUp }
   #71 : Begin ActionFirstSlide;          Exit; End;   { Home }
   #79 : Begin ActionLastSlide;           Exit; End;   { End }
  End;
  Exit;
 End;
 Case K Of
  #27: Begin
   If MenuOpen <> 0 Then Begin MenuOpen := 0; NeedFullRedraw := True; End
   Else If DragMode <> 0 Then Begin
    AppHideMouse; EraseRubberBand; AppShowMouse;
    DragMode := 0; DragHandle := 0; NeedSlideRedraw := True;
    StatusMsg := 'Annule.'; NeedStatRedraw := True;
   End
   Else If CurTool <> TOOL_SELECT Then Begin
    SetTool(TOOL_SELECT);
   End
   Else If CurShape > 0 Then Begin CurShape := 0; NeedSlideRedraw := True; End;
  End;
  #14:  DoAction(ACT_NEW);                          { Ctrl+N }
  #15:  DoAction(ACT_OPEN);                         { Ctrl+O }
  #19:  DoAction(ACT_SAVE);                         { Ctrl+S }
  #16:  DoAction(ACT_PRINT);                        { Ctrl+P }
  #5:   DoAction(ACT_EXPORT_PPTX);                  { Ctrl+E }
  #2:   If CurShape > 0 Then ShapeToggleBold;       { Ctrl+B }
  #21:  If CurShape > 0 Then ShapeToggleUnderline;  { Ctrl+U }
  #26:  DoAction(ACT_UNDO);                         { Ctrl+Z }
  #25:  DoAction(ACT_REDO);                         { Ctrl+Y }
  #24:  DoAction(ACT_CUT);                          { Ctrl+X }
  #3:   DoAction(ACT_COPY);                         { Ctrl+C }
  #22:  DoAction(ACT_PASTE);                        { Ctrl+V }
  #6:   DoAction(ACT_FIND);                         { Ctrl+F }
  #4:   DoAction(ACT_DUP);                          { Ctrl+D }
  #1:   DoAction(ACT_SELECTALL);                    { Ctrl+A }
 End;
End;

{ ====================================================================== }
{                       BOUCLE PRINCIPALE                                }
{ ====================================================================== }

Procedure MainLoop;
Var K, K2: Char; C: LongInt; M, I: Integer;
Begin
 NeedFullRedraw := True;
 Redraw;
 AppShowMouse;
 Repeat
  Inc(TickCount);
  If (TickCount Mod 25) = 0 Then BlinkTextCaret;
  { barre de menus de PM }
  While PollCmd(C) And Not Quitting Do Begin
   If C = CMD_CLOSE Then DoAction(ACT_QUIT)
   Else If (C > 132) And (C < 100 + 32 * (MenuCount + 1)) Then Begin
    M := (C - 100) Div 32; I := (C - 100) Mod 32;
    If (I >= 1) And (I <= Menus[M].Count) Then
     If (Not Menus[M].Items[I].IsSep) And (Menus[M].Items[I].Action <> 0) Then
      DoAction(Menus[M].Items[I].Action);
   End;
   NeedFullRedraw := True;
  End;
  If Quitting Then Exit;
  UpdateMouse;
  UpdateHovers;
  If LeftPressed Then HandleMouseClick;
  If LeftDown And (DragMode <> 0) Then UpdateDrag;
  If LeftReleased And (DragMode <> 0) Then EndDrag;
  K := #0; K2 := #0;
  If KeyPressed Then Begin
   K := ReadKey;
   If K = #0 Then K2 := ReadKey;
   HandleKey(K, K2);
  End;
  Redraw;
  Delay(20);
 Until Quitting;
End;

{ ====================================================================== }
{                       SPLASH                                           }
{ ====================================================================== }

Procedure ShowSplash;
Var T0: LongInt; Done: Boolean; K: Char;
Begin
 AppHideMouse;
 FillBox(0, 0, SCREEN_W - 1, SCREEN_H - 1, CLR_RED);
 FillBox(80, 80, 559, 399, CLR_LGRAY);
 SetColor(CLR_BLACK); Rectangle(80, 80, 559, 399);
 FillBox(84, 84, 555, 130, CLR_RED);
 SetColor(CLR_WHITE);
 SetTextStyle(DefaultFont, HorizDir, 3);
 OutTextXY(110, 95, 'Office-0 PresentPoint');
 SetTextStyle(DefaultFont, HorizDir, 1);
 SetColor(CLR_BLACK);
 OutTextXY(120, 160, 'Clone Pascal de Microsoft PowerPoint');
 OutTextXY(120, 180, 'Version 1.0 - Phase 12 (2026) - finale');
 OutTextXY(120, 200, '(c) Sylvain Maltais  -  www.gladir.com');
 SetColor(CLR_DGRAY);
 OutTextXY(120, 240, 'Formats : .PPT natif, .PPTX (import/export), .PRN');
 OutTextXY(120, 256, 'Compilateur : Free Pascal 3.2 (-Mtp)');
 OutTextXY(120, 272, 'Affichage : VGA 640 x 480 x 16');
 SetColor(CLR_BLACK);
 OutTextXY(120, 360, 'Appuyez sur une touche ou cliquez pour continuer...');
 AppShowMouse;
 T0 := TickCount;
 Done := False;
 Repeat
  UpdateMouse;
  If KeyPressed Then Begin
   K := ReadKey; If K = #0 Then ReadKey; Done := True;
  End;
  If LeftPressed Then Done := True;
  If (TickCount - T0) > 60 Then Done := True;
  Delay(20);
 Until Done;
End;

{ ====================================================================== }
{                       PROGRAMME PRINCIPAL                              }
{ ====================================================================== }

Function CommandLineHelpRequested: Boolean;
Var I,J: Integer;Arg: String;
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
 Assign(HelpOutput,'');Rewrite(HelpOutput);
 WriteLn(HelpOutput,'PRESENTPOINT - Editeur graphique de presentations en Pascal.');
 WriteLn(HelpOutput,'Utilisation : PRESENTPOINT [/CLASSICMENU | /RUBANMENU] [presentation] [/?]');
 WriteLn(HelpOutput);
 WriteLn(HelpOutput,'  /CLASSICMENU  Menus classiques, style PowerPoint 2003 (par defaut).');
 WriteLn(HelpOutput,'  /RUBANMENU    Onglets avec icones, style PowerPoint 2007 et suivants.');
 WriteLn(HelpOutput,'               La barre d''outils est masquee ; ses commandes figurent dans les onglets.');
 WriteLn(HelpOutput,'  /?           Affiche cette aide et quitte sans ouvrir de fenetre.');
 WriteLn(HelpOutput,'  -h, --help   Affichent egalement cette aide.');
 WriteLn(HelpOutput,'  presentation Fichier .PPT ou .PPTX a ouvrir au demarrage.');
 WriteLn(HelpOutput);
 WriteLn(HelpOutput,'Options insensibles a la casse ; le dernier mode specifie est utilise.');
 WriteLn(HelpOutput,'Le fichier peut apparaitre avant ou apres les options.');
 WriteLn(HelpOutput,'Exemple : PRESENTPOINT /RUBANMENU "C:\Documents\Ma presentation.pptx"');
 WriteLn(HelpOutput,'Ruban : souris, F10 ou Alt+lettre, fleches, Tab/Maj+Tab, Entree et Echap.');
 WriteLn(HelpOutput,'Alt+F Fichier, Alt+E Accueil, Alt+A Affichage, Alt+I Insertion, Alt+C Creation,');
 WriteLn(HelpOutput,'Alt+T Transitions, Alt+M Animations, Alt+D Diaporama, Alt+R Revision, Alt+H Aide.');
 Close(HelpOutput);
End;
Procedure ParseCommandLine;
Var I,J: Integer;Arg,U: String;
Begin
 RibbonMode:=False;RibbonTab:=2;RibbonFocus:=0;RibbonHover:=0;RibbonKeyboard:=False;
 RibbonInk:=-1;CommandLineFile:='';TOOL_H:=CLASSIC_TOOL_H;
 For I:=1 To ParamCount Do Begin
  Arg:=ParamStr(I);U:=Arg;For J:=1 To Length(U) Do U[J]:=UpCase(U[J]);
  If U='/CLASSICMENU' Then RibbonMode:=False
  Else If U='/RUBANMENU' Then RibbonMode:=True
  Else Begin
   If CommandLineFile<>'' Then CommandLineFile:=CommandLineFile+' ';
   CommandLineFile:=CommandLineFile+Arg;
  End;
 End;
 If RibbonMode Then TOOL_H:=120;
End;

Var
 CmdFName: String;

Begin
 If CommandLineHelpRequested Then Begin ShowCommandLineHelp;Halt(0);End;
 ParseCommandLine;
 InitializeGraphics;
 PaintReady:=True;
 If Not MouseDriverFound Then Begin
  CloseGraph;
  WriteLn('Aucun pilote de souris detecte.');
  Halt(1);
 End;
 SetTextStyle(DefaultFont, HorizDir, 1);
 InitMenus;
 InitTools;
 InitPresentation;
 If CommandLineFile<>'' Then Begin
  CmdFName := CommandLineFile;
  { Phase 12 : vraie dispatche selon extension }
  If (Length(CmdFName) >= 5) And
     (PptxUpStr(Copy(CmdFName, Length(CmdFName) - 4, 5)) = '.PPTX') Then
  Begin
   If LoadPPTX(CmdFName) Then StatusMsg := 'Charge : ' + CmdFName
   Else Begin
    { LoadPPTX a deja seed + StatusMsg diagnostique }
    If Copy(StatusMsg, 1, 5) <> 'PPTX:' Then Begin
     SeedSamplePresentation;
     StatusMsg := 'Echec PPTX : ' + CmdFName;
    End;
   End;
  End
  Else If (Length(CmdFName) >= 4) And
          (PptxUpStr(Copy(CmdFName, Length(CmdFName) - 3, 4)) = '.PPT') Then
  Begin
   If LoadPresentationFile(CmdFName) Then
    StatusMsg := 'Charge : ' + CmdFName
   Else Begin SeedSamplePresentation;
              StatusMsg := 'Echec : ' + CmdFName; End;
  End
  Else Begin
   Pres.FileName := CmdFName;
   SeedSamplePresentation;
   StatusMsg := 'Charge (factice) : ' + CmdFName;
  End;
 End
 Else Begin
  SeedSamplePresentation;
  StatusMsg := 'Pret';
 End;
 CurView    := VIEW_NORMAL;
 CurTool    := TOOL_SELECT;
 MenuOpen   := 0;
 MenuHover  := 0;
 ToolHover  := 0;
 EditMode   := False;
 BlinkState := True;
 Quitting   := False;
 TickCount  := 0;
 PanelScroll   := 0;
 SorterScroll  := 0;
 SorterSel     := 0;
 OutlineScroll := 0;
 OutlineSel    := 0;
 MainLoop;
 AppHideMouse;
 FreePresentation;
 PaintReady:=False;
 Dummy := WinDestroyWindow(OsFrame);
End.
