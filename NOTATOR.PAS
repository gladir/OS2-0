{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @version: 1.00
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Notator for OS2-Zero - clone de l'application Notator SL
                (sequenceur MIDI et editeur de partition) pour le
                Presentation Manager d'OS/2-0 (dossier Multimedia du bureau).
}

Program NOTATOR;

{$R-,S-,I-}

{ Compilation : OS2PC NOTATOR.PAS   (produit NOTATOR.EXE)

  Portage vers OS/2-0 de NOTATOR.PAS du depot OFFICE-0 (Turbo Pascal 7,
  Free Pascal : BGI 640 x 480 en 16 couleurs, souris de l'interruption
  33h, haut-parleur, MPU-401 ou synthetiseur logiciel de Windows).
  Toutes les fonctions de la version DOS sont conservees : arrangement
  (4 chaines de 99 patterns de 16 pistes), partition, matrice, liste
  d'evenements, palette de symboles, hyper-editeur, groove, quantification,
  transposition, copie de pistes / patterns / mesures, enregistrement au
  clavier d'ordinateur, metronome, boucle entre locators, punch, fichiers
  .SON et MIDI standard (.MID), impression de la partition, copie d'ecran
  PBM, options (NOTATOR.INI), trois langues (LANGUAGE=EN / FR / GR).

  Ce qui change pour OS/2 :
  - fenetre de Presentation Manager : barre de titre, menu systeme, barre
    de menus d'OS/2 construite a partir des tables de menus d'origine
    (memes commandes, coches et elements grises, raccourcis affiches) ;
  - le dessin du BGI va dans une image de 640 x 480 en memoire, montree
    dans la zone client par GpiDrawBits (seulement les zones modifiees) ;
  - boites de dialogue dans le style d'OS/2 (gris, barre de titre bleue,
    boutons en relief) ; messages et confirmations par WinMessageBox ;
  - son : le synthetiseur logiciel (ondes, enveloppes, batterie) joue par
    MDM.DLL (MMPM/2) sur la carte son (Sound Blaster 16, AC'97, ES1370) ;
    sans carte son, choix "Aucune" ; la sortie MPU-401 (ports d'E/S) est
    reservee a la version DOS ;
  - les echantillons sont dans C:\NOTATOR (BLUES_C, CANON_RE, FREREJAC,
    GROOVES, ODE_JOIE, TWINKLE, en .SON et en .MID).
}

{ ====================================================================== }
{                              CONSTANTES                                }
{ ====================================================================== }

Const
 VERSION_TEXT = '3.21';
 SCR_W        = 640;
 SCR_H        = 480;
 MENU_H       = 18;
 TB_H         = 16;
 INK          = 0;
 PAPER        = 15;

 NPAT   = 99;          { nombre de patterns }
 TPP    = 16;          { pistes par pattern }
 MAXTRK = 1584;        { 99 * 16 pistes (64 actives = 4 chaines x 16) }
 MAXEV  = 700;         { evenements par piste }
 NQUA   = 10;          { valeurs de quantification }
 NLYR   = 200;         { textes / paroles }
 MAXDN  = 240;         { notes affichees a l'ecran }
 NSYM   = 14;          { symboles de la palette }

 { Vues }
 V_ARR = 1;
 V_SCORE = 2;
 V_MATRIX = 3;
 V_LIST = 4;

 { Types d'evenements }
 EK_NOTE  = 1;
 EK_CTRL  = 2;
 EK_PROG  = 3;
 EK_BEND  = 4;
 EK_CHANP = 5;
 EK_POLYP = 6;
 EK_SYM   = 7;
 EK_TEXT  = 8;

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
 K_F11    = 389;
 K_F12    = 390;
 K_CLEFT  = 371;
 K_CRIGHT = 372;
 K_STAB   = 271;

{ ====================================================================== }
{                                TYPES                                   }
{ ====================================================================== }

Type
 TEvt = Packed Record
  T,Len : LongInt;
  Kind,D1,D2,Sty : Byte;
  Sel : Boolean;
 End;
 PEvArr = ^TEvArr;
 TEvArr = Array[1..MAXEV] Of TEvt;

 TTrkPar = Packed Record
  Name,Instr : String[10];
  Port,Chan,Qua,Groove,Clef : Byte;
  Trans,Vel,Comp,Delay,Loop,Lo,Hi,Shift : Integer;
  Mute,Solo,Drum : Boolean;
 End;
 PTrk = ^TTrk;
 TTrk = Record
  P   : TTrkPar;
  Cnt : Integer;
  Ev  : PEvArr;
  Sel : Boolean;
 End;

 TPat = Packed Record
  Name : String[12];
  Len  : Integer;
  Rep  : Array[1..4] Of Byte;
 End;

 TEvent = Record
  { 0 rien, 1 touche, 2 bouton bas, 3 bouton haut, 4 mouvement }
  Kind : Byte;
  Key  : Word;
  X,Y,B: LongInt;
 End;

{ ====================================================================== }
{                       LANGUE / UTILITAIRES                             }
{ ====================================================================== }

Var
 Lang : Integer;       { 0 anglais, 1 francais, 2 allemand }

Function T3(Const En,Fr,De: String): String;
Begin
 Case Lang Of
  0: T3:=En;
  2: T3:=De;
 Else T3:=Fr;
 End;
End;

{ 'EN~FR~DE' : extrait la partie N }
Function Part3(Const S: String; N: Integer): String;
Var I,K: Integer; R: String;
Begin
 R:='';K:=0;
 For I:=1 To Length(S) Do
  If S[I]='~' Then Inc(K) Else If K=N Then R:=R+S[I];
 If (R='') And (N<>0) Then Part3:=Part3(S,0) Else Part3:=R;
End;

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

Function Min2(A,B: LongInt): LongInt;
Begin
 If A<B Then Min2:=A Else Min2:=B;
End;

Function Max2(A,B: LongInt): LongInt;
Begin
 If A>B Then Max2:=A Else Max2:=B;
End;

Function Clamp(V,A,B: LongInt): LongInt;
Begin
 If V<A Then V:=A;
 If V>B Then V:=B;
 Clamp:=V;
End;

Function Pad2(N: LongInt): String;
Var S: String;
Begin
 Str(N,S);
 If Length(S)<2 Then S:='0'+S;
 Pad2:=S;
End;

Function PadL(Const S: String; W: Integer): String;
Var R: String;
Begin
 R:=S;
 While Length(R)<W Do R:=' '+R;
 PadL:=R;
End;

Function ToInt(Const S: String): LongInt;
Var V: LongInt; C: Integer;
Begin
 Val(S,V,C);
 If C<>0 Then V:=0;
 ToInt:=V;
End;

Function FileExists(Const N: String): Boolean;
Var F: File;
Begin

 Assign(F,N);
 Reset(F,1);

 If IOResult=0 Then Begin Close(F);FileExists:=True;End Else FileExists:=False;
End;

Function ShortName(Const N: String): String;
Var I: Integer;
Begin
 I:=Length(N);
 While (I>0) And (N[I]<>'\') And (N[I]<>'/') And (N[I]<>':') Do Dec(I);
 ShortName:=Copy(N,I+1,255);
End;

Function AddExt(Const N,Ext: String): String;
Var S: String;
Begin
 S:=N;
 If Pos('.',ShortName(S))=0 Then S:=S+'.'+Ext;
 AddExt:=S;
End;

{ ====================================================================== }
{          OS/2-0 : PRESENTATION MANAGER, GRAPH ET CRT EMULES             }
{ ====================================================================== }
{ La version DOS dessine avec l'unite Graph du BGI (640 x 480, 16         }
{ couleurs) et lit le clavier et la souris dans sa boucle. Ici :          }
{  - le dessin va dans une image en memoire de 640 x 480 (un octet par    }
{    point, couleurs du BGI), montree dans la zone client d'une fenetre   }
{    de PM par GpiDrawBits (zones modifiees seulement) ; les lignes 0 a   }
{    33 (barre de menus et barre de titre GEM) sont remplacees par la     }
{    barre de titre et la barre de menus de PM ;                          }
{  - les routines de Graph utilisees par NOTATOR (Line, Rectangle, Bar,   }
{    FillPoly, Ellipse, FillEllipse, Arc, PutPixel, GetPixel, OutTextXY,  }
{    styles de trait et de remplissage, SetWriteMode) sont ecrites ici ;  }
{  - PollEvent vide la file de messages de PM (WinPeekMsg) : touches      }
{    (WM_CHAR, en codes du BIOS), souris (WM_BUTTON*, WM_MOUSEMOVE),      }
{    commandes des menus de PM. }

Const
 { Graph : Black..White, SolidLn.., EmptyFill.., CopyPut, XORPut et grOk
   sont predefinis par OS2PC (unite Graph) }
 NormalPut = 0;
 { zone montree : lignes CanvasTop a 479 de l'image }
 CanvasTop = 34;
 { couleurs d'OS/2 (indices de la palette de l'image) }
 OS_FACE = 7; OS_SHADOW = 8; OS_LIGHT = 15; OS_DARK = 0; OS_TITLE = 1;

Type
 PointType = Record
  X,Y : Integer;
 End;
 FillPatternType = Array[1..8] Of Byte;

{ --- PMWIN.DLL, PMGPI.DLL, DOSCALLS.DLL, MDM.DLL --- }
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
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(HPar, Id : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HD, H : LongInt) : LongInt; External 'PMWIN';
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function KTicks : LongInt; External 'DOSCALLS' Name 'GetTickCount';
Function MdmPlay(PData, Bytes, Rate, Bits, Ch : LongInt) : LongInt; External 'MDM' Name 'MDMPLAY';
Function MdmStop : LongInt; External 'MDM' Name 'MDMSTOP';
Function MdmPosition : LongInt; External 'MDM' Name 'MDMPOSITION';
Function MdmState : LongInt; External 'MDM' Name 'MDMSTATE';
Function MdmAudioInfo(PBuf, Len : LongInt) : LongInt; External 'MDM' Name 'MDMAUDIOINFO';

Const
 WM_SIZE = $0007; WM_COMMAND = $0020; WM_SYSCOMMAND = $0021; WM_PAINT = $0023; WM_CLOSE = $0029;
 WM_QUIT = $002A; WM_INITMENU = $0033; WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071;
 WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073; WM_BUTTON2DOWN = $0074; WM_BUTTON2UP = $0075;
 WM_BUTTON2DBLCLK = $0076; WM_CHAR = $007A;
 FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
 HWND_DESKTOP = 1; HWND_TOP = 3;
 SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
 MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000; MIA_DISABLED = $4000;
 MM_SETITEMATTR = $0192;
 MB_OK = 0; MB_YESNO = 4; MB_QUERY = $10; MB_INFORMATION = $30; MB_MOVEABLE = $4000; MBID_YES = 6;
 KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SHIFT = 8; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
 VK_BACKSPACE = $05; VK_TAB = $06; VK_BACKTAB = $07; VK_NEWLINE = $08; VK_ESC = $0F;
 VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14; VK_LEFT = $15; VK_UP = $16;
 VK_RIGHT = $17; VK_DOWN = $18; VK_INSERT = $1A; VK_DELETE = $1B; VK_ENTER = $1E; VK_F1 = $20;
 SC_APPMENU = $8006; CMDSRC_ACCELERATOR = 3;
 PM_REMOVE = 1;
 ScrW = 640; ScrH = 480;
 EvQMax = 64;

{ police 8 x 8 (256 caracteres, page de codes 437) reprise de Win16_Font8
  de DEVENV.PAS (depot dev-cools) : texte du BGI (OutTextXY) }
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
 Hab, Hmq, HFrame, Client, Dummy, CliH, HMenu : LongInt;
 Fb : Array[0..ScrW * ScrH - 1] Of Byte;     { image, lignes de bas en haut }
 Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;   { BITMAPINFO2 et palette }
 DirtyX1, DirtyY1, DirtyX2, DirtyY2 : LongInt;
 GColor, GBk, GFillStyle, GFillColor, GLineStyle, GThick, GWrite : LongInt;
 GLinePat : LongInt;
 GFillPat : FillPatternType;
 { souris et clavier (file d'evenements) }
 MX, MY, MB, LastB, PrevMX, PrevMY : LongInt;
 EvKind, EvKey, EvX, EvY, EvB : Array[0..EvQMax - 1] Of LongInt;
 EvHead, EvTail : LongInt;
 NameZ, NameZ2 : Array[0..1023] Of Byte;
 TxtBuf : Array[0..4095] Of Byte;
 MenuT : Array[0..16383] Of Byte;
 MenuLen : LongInt;
 Qmsg : Array[0..7] Of LongInt;
 LastTitle : String;
 FpuCw : Word;

{ --- utilitaires --- }

Procedure WrB(A, V : LongInt);
Type PByte1 = ^Byte;
Var Q : PByte1;
Begin
 Q := Pointer(A);
 Q^ := V;
End;

Function PkB(A : LongInt) : LongInt;
Type PByte2 = ^Byte;
Var Q : PByte2;
Begin
 Q := Pointer(A);
 PkB := Q^;
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

Function GetZ(A : LongInt) : String;
Var S : String; C : LongInt;
Begin
 S := '';
 If A <> 0 Then
 Begin
  C := PkB(A);
  While (C <> 0) And (Length(S) < 250) Do
  Begin
   S := S + Chr(C);
   Inc(A);
   C := PkB(A);
  End;
 End;
 GetZ := S;
End;

Function Z(S : String) : LongInt;
Begin
 PutZ(LongInt(@NameZ), S);
 Z := LongInt(@NameZ);
End;

Function Z2(S : String) : LongInt;
Begin
 PutZ(LongInt(@NameZ2), S);
 Z2 := LongInt(@NameZ2);
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


{ --- image et zones modifiees --- }

Procedure Touch(X1, Y1, X2, Y2 : LongInt);
Begin
 If X1 < 0 Then X1 := 0;
 If Y1 < 0 Then Y1 := 0;
 If X2 > ScrW - 1 Then X2 := ScrW - 1;
 If Y2 > ScrH - 1 Then Y2 := ScrH - 1;
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

{ point (X, Y) de couleur C (mode d'ecriture : copie ou ou exclusif) }
Procedure Plot(X, Y, C : LongInt);
Var A : LongInt;
Begin
 If (X < 0) Or (Y < 0) Or (X >= ScrW) Or (Y >= ScrH) Then Exit;
 A := (ScrH - 1 - Y) * ScrW + X;
 If GWrite = XORPut Then Fb[A] := (Fb[A] Xor C) And 15 Else Fb[A] := C And 15;
End;

Procedure HSpan(X1, X2, Y, C : LongInt);
Var A, X : LongInt;
Begin
 If (Y < 0) Or (Y >= ScrH) Then Exit;
 If X1 < 0 Then X1 := 0;
 If X2 > ScrW - 1 Then X2 := ScrW - 1;
 If X2 < X1 Then Exit;
 A := (ScrH - 1 - Y) * ScrW;
 For X := X1 To X2 Do Fb[A + X] := C And 15;
End;

{ --- Graph : etat --- }

Procedure SetColor(C : Integer);
Begin
 GColor := C And 15;
End;

Function GetColor : Integer;
Begin
 GetColor := GColor;
End;

Procedure SetBkColor(C : Integer);
Begin
 GBk := C And 15;
End;

Procedure SetWriteMode(M : Integer);
Begin
 GWrite := M;
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
 GFillColor := Color And 15;
End;

Procedure SetFillPattern(Pat : FillPatternType; Color : Integer);
Var I : Integer;
Begin
 For I := 1 To 8 Do GFillPat[I] := Pat[I];
 GFillStyle := UserFill;
 GFillColor := Color And 15;
End;

Procedure SetViewPort(X1, Y1, X2, Y2 : Integer; Clip : Boolean);
Begin
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
Var X, A : LongInt;
Begin
 If (Y < 0) Or (Y >= ScrH) Then Exit;
 If X1 < 0 Then X1 := 0;
 If X2 > ScrW - 1 Then X2 := ScrW - 1;
 If X2 < X1 Then Exit;
 If GFillStyle = SolidFill Then
 Begin
  HSpan(X1, X2, Y, GFillColor);
  Exit;
 End;
 A := (ScrH - 1 - Y) * ScrW;
 For X := X1 To X2 Do
  If FillBit(X, Y) Then Fb[A + X] := GFillColor Else Fb[A + X] := GBk;
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

Procedure Line(X1, Y1, X2, Y2 : Integer);
Begin
 Touch(Min2(X1, X2) - 1, Min2(Y1, Y2) - 1, Max2(X1, X2) + 1, Max2(Y1, Y2) + 1);
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

Procedure Rectangle(X1, Y1, X2, Y2 : Integer);
Begin
 Line(X1, Y1, X2, Y1); Line(X2, Y1, X2, Y2);
 Line(X2, Y2, X1, Y2); Line(X1, Y2, X1, Y1);
End;

Procedure Bar(X1, Y1, X2, Y2 : Integer);
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
 Touch(X1, Y1, X2, Y2);
 For Y := Y1 To Y2 Do FillSpan(X1, X2, Y);
End;

Procedure PutPixel(X, Y : Integer; C : Word);
Begin
 Touch(X, Y, X, Y);
 Plot(X, Y, C);
End;

Function GetPixel(X, Y : Integer) : Word;
Begin
 If (X < 0) Or (Y < 0) Or (X >= ScrW) Or (Y >= ScrH) Then GetPixel := 0
 Else GetPixel := Fb[(ScrH - 1 - Y) * ScrW + X];
End;

{ polygone plein (regle pair-impair), puis son contour }
Procedure FillPoly(N : Integer; Var Pts);
Type TPts = Array[1..64] Of PointType;
Var P : ^TPts; I, J, Y, Y1, Y2, K, Cnt, T, Xa, Ya, Xb, Yb : LongInt; Xs : Array[0..63] Of LongInt;
Begin
 P := @Pts;
 If (N < 2) Or (N > 64) Then Exit;
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
   Touch(Xs[I], Y, Xs[I + 1], Y);
   FillSpan(Xs[I], Xs[I + 1], Y);
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

{ --- Graph : ellipses (angles en degres, sens trigonometrique) --- }

Procedure Ellipse(X, Y : Integer; StAngle, EndAngle : Word; XR, YR : Word);
Var A, A2, Steps, K, Px, Py, Qx, Qy : LongInt; T : Double;
Begin
 If (XR = 0) And (YR = 0) Then
 Begin
  PutPixel(X, Y, GColor);
  Exit;
 End;
 A := StAngle; A2 := EndAngle;
 If A2 <= A Then A2 := A2 + 360;
 If (StAngle = 0) And (EndAngle = 360) Then A2 := 360;
 Steps := ((A2 - A) * (XR + YR)) Div 60 + 8;
 If Steps > 720 Then Steps := 720;
 Touch(X - XR - 2, Y - YR - 2, X + XR + 2, Y + YR + 2);
 T := A * Pi / 180;
 Px := X + Round(XR * Cos(T)); Py := Y - Round(YR * Sin(T));
 For K := 1 To Steps Do
 Begin
  T := (A + (A2 - A) * K / Steps) * Pi / 180;
  Qx := X + Round(XR * Cos(T)); Qy := Y - Round(YR * Sin(T));
  If (Qx <> Px) Or (Qy <> Py) Then
  Begin
   If GThick = 3 Then Line(Px, Py, Qx, Qy) Else
   Begin
    LineThin(Px, Py, Qx, Qy);
   End;
   Px := Qx; Py := Qy;
  End;
 End;
End;

Procedure FillEllipse(X, Y : Integer; XR, YR : Word);
Var Dy, W : LongInt; T : Double;
Begin
 Touch(X - XR - 1, Y - YR - 1, X + XR + 1, Y + YR + 1);
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
 Ellipse(X, Y, 0, 360, XR, YR);
End;

Procedure Arc(X, Y : Integer; StAngle, EndAngle, Radius : Word);
Begin
 Ellipse(X, Y, StAngle, EndAngle, Radius, Radius);
End;

Procedure Circle(X, Y : Integer; Radius : Word);
Begin
 Ellipse(X, Y, 0, 360, Radius, Radius);
End;

{ --- Graph : texte (police 8 x 8, fond transparent) --- }

Procedure OutTextXY(X, Y : Integer; S : String);
Var I, R, K, B, C : LongInt;
Begin
 If S = '' Then Exit;
 Touch(X, Y, X + Length(S) * 8 - 1, Y + 7);
 For I := 1 To Length(S) Do
 Begin
  C := Ord(S[I]);
  For R := 0 To 7 Do
  Begin
   B := Font8[C * 8 + R];
   If B <> 0 Then
    For K := 0 To 7 Do
     If (B And ($80 Shr K)) <> 0 Then Plot(X + (I - 1) * 8 + K, Y + R, GColor);
  End;
 End;
End;

Procedure ClearDevice;
Var K : LongInt;
Begin
 For K := 0 To ScrW * ScrH - 1 Do Fb[K] := GBk;
 Touch(0, 0, ScrW - 1, ScrH - 1);
End;

{ --- palette de l'image (couleurs du BGI, BITMAPINFO2 de 8 bits) --- }

Procedure InitBmi;
Const
 Pal : Array[0..15] Of LongInt = (
  $000000, $0000AA, $00AA00, $00AAAA, $AA0000, $AA00AA, $AA5500, $AAAAAA,
  $555555, $5555FF, $55FF55, $55FFFF, $FF5555, $FF55FF, $FFFF55, $FFFFFF);
Var I, A : LongInt;
Begin
 FillChar(Bmi, SizeOf(Bmi), 0);
 WrL(LongInt(@Bmi), 16);
 WrL(LongInt(@Bmi) + 4, ScrW);
 WrL(LongInt(@Bmi) + 8, ScrH);
 WrW(LongInt(@Bmi) + 12, 1);
 WrW(LongInt(@Bmi) + 14, 8);
 For I := 0 To 15 Do
 Begin
  A := LongInt(@Bmi) + 16 + I * 4;
  WrB(A, Pal[I] And 255);
  WrB(A + 1, (Pal[I] Shr 8) And 255);
  WrB(A + 2, (Pal[I] Shr 16) And 255);
 End;
 GColor := White; GBk := Black; GFillStyle := SolidFill; GFillColor := White;
 GLineStyle := SolidLn; GLinePat := $FFFF; GThick := 1; GWrite := NormalPut;
 DirtyX1 := -1;
End;

Procedure HideMouse;
Begin
End;

Procedure ShowMouse;
Begin
End;

{ --- WinGetPS / WinReleasePS --- }
Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function WinQueryCapture(HD : LongInt) : LongInt; External 'PMWIN';

{ montrer la zone X1..X2, Y1..Y2 de l'image (coordonnees de l'image, Y
  vers le bas) dans la zone client : la ligne Y de l'image est la ligne
  479 - Y du client (et du bitmap, range de bas en haut) }
Procedure Blit(Hps, X1, Y1, X2, Y2 : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
 If Y1 < CanvasTop Then Y1 := CanvasTop;
 If (X2 < X1) Or (Y2 < Y1) Then Exit;
 P[0] := X1; P[1] := ScrH - 1 - Y2; P[2] := X2 + 1; P[3] := ScrH - Y1;
 P[4] := X1; P[5] := ScrH - 1 - Y2; P[6] := X2 + 1; P[7] := ScrH - Y1;
 Dummy := GpiDrawBits(Hps, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

{ envoyer a l'ecran ce qui a change depuis le dernier appel }
Procedure FlushScreen;
Var Hps : LongInt;
Begin
 If (DirtyX1 < 0) Or (Client = 0) Then Exit;
 Hps := WinGetPS(Client);
 If Hps <> 0 Then
 Begin
  Blit(Hps, DirtyX1, DirtyY1, DirtyX2, DirtyY2);
  Dummy := WinReleasePS(Hps);
 End;
 DirtyX1 := -1;
End;

{ --- file d'evenements (remplie par la procedure de fenetre) --- }

Procedure EvPush(K, Key, X, Y, B : LongInt);
Var N, Prev : LongInt;
Begin
 { mouvements de souris consecutifs : seul le dernier compte }
 If (K = 4) And (EvHead <> EvTail) Then
 Begin
  Prev := (EvTail + EvQMax - 1) Mod EvQMax;
  If EvKind[Prev] = 4 Then
  Begin
   EvX[Prev] := X; EvY[Prev] := Y; EvB[Prev] := B;
   Exit;
  End;
 End;
 N := (EvTail + 1) Mod EvQMax;
 If N = EvHead Then Exit;
 EvKind[EvTail] := K; EvKey[EvTail] := Key; EvX[EvTail] := X; EvY[EvTail] := Y; EvB[EvTail] := B;
 EvTail := N;
End;

{ touche de PM (WM_CHAR) -> code du BIOS de la version DOS : caractere =
  Ord, touche etendue = 256 + code de balayage }
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
   VK_HOME : K := 327;
   VK_END : K := 335;
   VK_PAGEUP : K := 329;
   VK_PAGEDOWN : K := 337;
   VK_INSERT : K := 338;
   VK_DELETE : K := 339;
  End;
  If (Vk >= VK_F1) And (Vk <= VK_F1 + 9) And ((Fl And (KC_ALT Or KC_CTRL Or KC_SHIFT)) = 0) Then K := 315 + Vk - VK_F1;
  If (Vk = VK_F1 + 10) And ((Fl And (KC_ALT Or KC_CTRL Or KC_SHIFT)) = 0) Then K := 389;
  If (Vk = VK_F1 + 11) And ((Fl And (KC_ALT Or KC_CTRL Or KC_SHIFT)) = 0) Then K := 390;
 End;
 If (K < 0) And ((Fl And KC_CHAR) <> 0) And ((Fl And KC_ALT) = 0) And (Ch > 0) And (Ch < 256) Then
 Begin
  K := Ch;
  If ((Fl And KC_CTRL) <> 0) And (Upcase(Chr(Ch)) >= 'A') And (Upcase(Chr(Ch)) <= 'Z') Then
   K := Ord(Upcase(Chr(Ch))) - 64;
 End;
 { Ctrl + lettre sans KC_CHAR }
 If (K < 0) And ((Fl And KC_CTRL) <> 0) And ((Fl And KC_ALT) = 0) And (Ch > 0) And (Ch < 256) Then
  If (Upcase(Chr(Ch)) >= 'A') And (Upcase(Chr(Ch)) <= 'Z') Then K := Ord(Upcase(Chr(Ch))) - 64;
 KeyCode := K;
End;

Procedure MenuInit(M : LongInt); Forward;

{ procedure de la zone client : tout devient un evenement de la file }
Function ClientProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, K, X, Y : LongInt; Rc : Array[0..3] Of LongInt;
Begin
 ClientProc := 0;
 Case Msg Of
  WM_PAINT :
   Begin
    Hps := WinBeginPaint(H, 0, LongInt(@Rc));
    Blit(Hps, 0, CanvasTop, ScrW - 1, ScrH - 1);
    Dummy := WinEndPaint(Hps);
   End;
  WM_CHAR :
   Begin
    K := KeyCode(Mp1, Mp2);
    If K >= 0 Then
    Begin
     EvPush(1, K, MX, MY, MB);
     ClientProc := 1;
    End
    Else ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_MOUSEMOVE :
   Begin
    X := S16(Mp1); Y := ScrH - 1 - S16(Mp1 Shr 16);
    EvPush(4, 0, X, Y, MB);
    ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
   End;
  WM_BUTTON1DOWN, WM_BUTTON1DBLCLK, WM_BUTTON2DOWN, WM_BUTTON2DBLCLK :
   Begin
    X := S16(Mp1); Y := ScrH - 1 - S16(Mp1 Shr 16);
    Dummy := WinSetFocus(HWND_DESKTOP, H);
    Dummy := WinSetCapture(HWND_DESKTOP, H);
    If (Msg = WM_BUTTON1DOWN) Or (Msg = WM_BUTTON1DBLCLK) Then MB := MB Or 1 Else MB := MB Or 2;
    EvPush(2, 0, X, Y, MB);
    ClientProc := 1;
   End;
  WM_BUTTON1UP, WM_BUTTON2UP :
   Begin
    X := S16(Mp1); Y := ScrH - 1 - S16(Mp1 Shr 16);
    If Msg = WM_BUTTON1UP Then MB := MB And Not 1 Else MB := MB And Not 2;
    If MB = 0 Then Dummy := WinSetCapture(HWND_DESKTOP, 0);
    EvPush(3, 0, X, Y, MB);
    ClientProc := 1;
   End;
  WM_COMMAND : EvPush(5, Lo16(Mp1), MX, MY, MB);
  WM_INITMENU : MenuInit(Lo16(Mp1));
  WM_CLOSE : EvPush(5, 9999, MX, MY, MB);
 Else
  ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
 End;
End;

{ cadre : F10 (accelerateur du systeme) reste la touche F10 de NOTATOR
  (choix de la duree de note), comme dans la version DOS }
Function FrameProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
 If (Msg = WM_SYSCOMMAND) And (Lo16(Mp1) = SC_APPMENU) And (Lo16(Mp2) = CMDSRC_ACCELERATOR) Then
 Begin
  EvPush(1, 324, MX, MY, MB);
  FrameProc := 0;
 End
 Else FrameProc := WinSysClassProc(H, Msg, Mp1, Mp2);
End;

{ vider la file de messages de PM ; True si un evenement attend }
Procedure PumpMessages;
Begin
 While WinPeekMsg(Hab, LongInt(@Qmsg), 0, 0, 0, PM_REMOVE) <> 0 Do
 Begin
  If Qmsg[1] = WM_QUIT Then EvPush(5, 9999, MX, MY, MB)
  Else Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
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

{ --- boites de message d'OS/2 --- }

Function PmBox(Title, Txt : String; Fl : LongInt) : LongInt;
Begin
 FlushScreen;
 PutZ(LongInt(@TxtBuf), Txt);
 PmBox := WinMessageBox(HWND_DESKTOP, HFrame, LongInt(@TxtBuf), Z(Title), 0, Fl Or MB_MOVEABLE);
End;

{ ====================================================================== }
{                       PRIMITIVES GRAPHIQUES                            }
{ ====================================================================== }

Const
 PatChecker : FillPatternType = ($AA,$55,$AA,$55,$AA,$55,$AA,$55);
 PatLight   : FillPatternType = ($88,$22,$88,$22,$88,$22,$88,$22);
 PatDark    : FillPatternType = ($77,$DD,$77,$DD,$77,$DD,$77,$DD);
 PatHyper   : Array[0..3] Of FillPatternType = (
  ($FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF),
  ($AA,$55,$AA,$55,$AA,$55,$AA,$55),
  ($88,$44,$22,$11,$88,$44,$22,$11),
  ($77,$DD,$77,$DD,$77,$DD,$77,$DD));

Procedure Box(X1,Y1,X2,Y2,C: Integer);
Begin
 SetFillStyle(SolidFill,C);
 Bar(X1,Y1,X2,Y2);
End;

Procedure Frame(X1,Y1,X2,Y2: Integer);
Begin
 SetColor(INK);
 SetLineStyle(SolidLn,0,1);
 Rectangle(X1,Y1,X2,Y2);
End;

{ Le BGI peint les bits a 1 avec la couleur et les bits a 0 avec la couleur 0 :
  on inverse donc le motif et on le peint en blanc pour obtenir noir sur blanc }
Procedure PatBar(X1,Y1,X2,Y2: Integer; Const Pat: FillPatternType);
Var Q: FillPatternType; I: Integer;
Begin
 For I:=1 To 8 Do Q[I]:=Not Pat[I];
 SetFillPattern(Q,PAPER);
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

{ texte grise (element inactif) : gris fonce, comme dans PM }
Procedure GreyText(X,Y: Integer; Const S: String);
Begin
 SetColor(OS_SHADOW);
 OutTextXY(X,Y,S);
End;

Function TextW(Const S: String): Integer;
Begin
 TextW:=Length(S)*8;
End;

Function InBox(X,Y,X1,Y1,X2,Y2: LongInt): Boolean;
Begin
 InBox:=(X>=X1) And (X<=X2) And (Y>=Y1) And (Y<=Y2);
End;

{ relief d'OS/2 : bord noir, clair en haut a gauche, ombre en bas a droite }
Procedure Bevel(X1,Y1,X2,Y2: Integer; Sunken: Boolean);
Var Hi,Lo: Integer;
Begin
 If Sunken Then Begin Hi:=OS_SHADOW;Lo:=White;End
 Else Begin Hi:=White;Lo:=OS_SHADOW;End;
 SetLineStyle(SolidLn,0,1);
 SetColor(Hi);
 Line(X1+1,Y1+1,X2-1,Y1+1);Line(X1+1,Y1+1,X1+1,Y2-1);
 SetColor(Lo);
 Line(X1+1,Y2-1,X2-1,Y2-1);Line(X2-1,Y1+1,X2-1,Y2-1);
 SetColor(INK);
 Rectangle(X1,Y1,X2,Y2);
End;

Procedure SmallBox(X,Y: Integer);
Begin
 Box(X,Y,X+TB_H-1,Y+TB_H-1,OS_FACE);
 Bevel(X,Y,X+TB_H-1,Y+TB_H-1,False);
 Box(X+4,Y+7,X+TB_H-5,Y+8,INK);
End;

Procedure ArrowBox(X1,Y1,X2,Y2,Dir: Integer);
{ Dir : 1 haut, 2 bas, 3 gauche, 4 droite }
Var Pt: Array[1..3] Of PointType; CX,CY,R: Integer;
Begin
 Box(X1,Y1,X2,Y2,OS_FACE);
 Bevel(X1,Y1,X2,Y2,False);
 CX:=(X1+X2) Div 2;CY:=(Y1+Y2) Div 2;
 R:=3;
 If (X2-X1<10) Or (Y2-Y1<10) Then R:=2;
 Case Dir Of
  1: Begin
    Pt[1].X:=CX;Pt[1].Y:=CY-R;Pt[2].X:=CX-R-1;Pt[2].Y:=CY+R;Pt[3].X:=CX+R+1;
    Pt[3].Y:=CY+R;End;
  2: Begin
    Pt[1].X:=CX;Pt[1].Y:=CY+R;Pt[2].X:=CX-R-1;Pt[2].Y:=CY-R;Pt[3].X:=CX+R+1;
    Pt[3].Y:=CY-R;End;
  3: Begin
    Pt[1].X:=CX-R;Pt[1].Y:=CY;Pt[2].X:=CX+R;Pt[2].Y:=CY-R-1;Pt[3].X:=CX+R;
    Pt[3].Y:=CY+R+1;End;
  4: Begin
    Pt[1].X:=CX+R;Pt[1].Y:=CY;Pt[2].X:=CX-R;Pt[2].Y:=CY-R-1;Pt[3].X:=CX-R;
    Pt[3].Y:=CY+R+1;End;
 End;
 SetFillStyle(SolidFill,INK);
 SetColor(INK);
 FillPoly(3,Pt);
End;

{ bouton de la fenetre principale : Hot = enfonce (fonction active) }
Procedure Button(X1,Y1,X2,Y2: Integer; Const S: String; Hot,Enabled: Boolean);
Var TX,TY: Integer;
Begin
 TX:=(X1+X2+1-TextW(S)) Div 2;TY:=(Y1+Y2-6) Div 2;
 If Hot Then Begin
  Box(X1,Y1,X2,Y2,OS_SHADOW);
  Bevel(X1,Y1,X2,Y2,True);
  Inc(TX);Inc(TY);
 End Else Begin
  Box(X1,Y1,X2,Y2,OS_FACE);
  Bevel(X1,Y1,X2,Y2,False);
 End;
 If Not Enabled Then GreyText(TX,TY,S)
 Else If Hot Then WText(TX,TY,S)
 Else PText(TX,TY,S);
End;

{ bouton d'une boite de dialogue : Def = bouton par defaut (cadre epais) }
Procedure DlgButton(X1,Y1,X2,Y2: Integer; Const S: String; Def: Boolean);
Begin
 Box(X1,Y1,X2,Y2,OS_FACE);
 Bevel(X1,Y1,X2,Y2,False);
 If Def Then Begin
  SetColor(INK);
  Rectangle(X1-1,Y1-1,X2+1,Y2+1);
 End;
 PText((X1+X2+1-TextW(S)) Div 2,(Y1+Y2-6) Div 2,S);
End;

{ zone de saisie ou liste : blanche, en creux }
Procedure Field(X1,Y1,X2,Y2: Integer);
Begin
 Box(X1,Y1,X2,Y2,PAPER);
 SetColor(OS_SHADOW);
 Line(X1-1,Y1-1,X2,Y1-1);Line(X1-1,Y1-1,X1-1,Y2);
 SetColor(White);
 Line(X1-1,Y2+1,X2+1,Y2+1);Line(X2+1,Y1-1,X2+1,Y2+1);
 SetColor(INK);
 Rectangle(X1,Y1,X2,Y2);
End;

{ fenetre de dialogue d'OS/2 : bord en relief, barre de titre bleue avec le
  menu systeme a gauche (un clic ferme la boite), fond gris }
Procedure DlgBox(X1,Y1,X2,Y2: Integer; Const Title: String; OkBox: Boolean);
Begin
 Box(X1,Y1,X2,Y2,OS_FACE);
 Bevel(X1,Y1,X2,Y2,False);
 SetColor(OS_FACE);
 Rectangle(X1+2,Y1+2,X2-2,Y2-2);
 Box(X1+3,Y1+3,X2-3,Y1+TB_H+1,OS_TITLE);
 SmallBox(X1+3,Y1+3);
 SetColor(White);
 OutTextXY((X1+X2-TextW(Title)) Div 2,Y1+7,Title);
 SetColor(OS_SHADOW);
 Line(X1+3,Y1+TB_H+2,X2-3,Y1+TB_H+2);
End;

{ ====================================================================== }
{                   EVENEMENTS (clavier / souris)                        }
{ ====================================================================== }

Var
 NeedDraw : Boolean;
 Quit     : Boolean;

Procedure DrawAll; Forward;
Procedure EngineStep; Forward;

{ evenement suivant : la file de PM est videe (WinPeekMsg) dans la file de
  NOTATOR ; sans evenement, le moteur avance (lecture, son) et le
  programme rend la main au systeme quelques millisecondes }
Procedure PollEvent(Var E: TEvent);
Begin
 E.Kind:=0;E.Key:=0;E.X:=MX;E.Y:=MY;E.B:=MB;
 FlushScreen;
 If EvHead=EvTail Then PumpMessages;
 If EvHead<>EvTail Then Begin
  E.Kind:=EvKind[EvHead];E.Key:=EvKey[EvHead];
  E.X:=EvX[EvHead];E.Y:=EvY[EvHead];E.B:=EvB[EvHead];
  EvHead:=(EvHead+1) Mod EvQMax;
  If E.Kind<>1 Then Begin
   PrevMX:=MX;PrevMY:=MY;LastB:=MB;
   MX:=E.X;MY:=E.Y;
  End;
  Exit;
 End;
 EngineStep;
 FlushScreen;
 Dummy:=DosSleep(4);
End;

{ ====================================================================== }
{                      BOITES DE DIALOGUE                                }
{ ====================================================================== }

Var
 FormLbl : Array[1..12] Of String[30];
 FormVal : Array[1..12] Of String[70];
 FormFW  : Integer;
 LstItem : Array[1..120] Of String[36];
 LstN    : Integer;

{ lignes du message (MsgBox les decoupe aux '|' ; CmdHelp les ajoute une a
  une : le texte complet de l'aide depasse les 255 caracteres d'une chaine) }
Var
 MsgLn : Array[1..14] Of String[60];
 MsgN  : Integer;

Procedure MsgAdd(Const S: String);
Begin
 If MsgN<14 Then Begin Inc(MsgN);MsgLn[MsgN]:=Copy(S,1,60);End;
End;

Procedure MsgShow(Const Title: String);
Var N,I,W,X1,Y1,X2,Y2: Integer; E: TEvent; Done: Boolean;
Begin
 N:=MsgN;
 W:=TextW(Title)+80;
 For I:=1 To N Do If TextW(MsgLn[I])+32>W Then W:=TextW(MsgLn[I])+32;
 If W<200 Then W:=200;
 X1:=(SCR_W-W) Div 2;X2:=X1+W;
 Y1:=(SCR_H-(N*12+TB_H+40)) Div 2;Y2:=Y1+N*12+TB_H+40;
 HideMouse;
 DlgBox(X1,Y1,X2,Y2,Title,True);
 For I:=1 To N Do PText(X1+16,Y1+TB_H+14+(I-1)*12,MsgLn[I]);
 DlgButton((X1+X2) Div 2-30,Y2-26,(X1+X2) Div 2+30,Y2-8,'OK',True);
 ShowMouse;
 Done:=False;
 Repeat
  PollEvent(E);
  If E.Kind=1 Then Begin
   If (E.Key=K_ENTER) Or (E.Key=K_ESC) Or (E.Key=32) Then Done:=True;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2)
       Or InBox(E.X,E.Y,X2-30,Y1+3,X2-4,Y1+TB_H)
      Or InBox(E.X,E.Y,(X1+X2) Div 2-30,Y2-26,(X1+X2) Div 2+30,Y2-8) Then
        Done:=True;
  End;
 Until Done;
 NeedDraw:=True;
End;

Procedure MsgBox(Const Title,Txt: String);
Var P: Integer; S: String;
Begin
 MsgN:=0;S:=Txt;
 While (S<>'') And (MsgN<14) Do Begin
  P:=Pos('|',S);
  If P=0 Then Begin MsgAdd(S);S:='';End
  Else Begin MsgAdd(Copy(S,1,P-1));Delete(S,1,P);End;
 End;
 MsgShow(Title);
End;

{ confirmation : boite de message d'OS/2 (Oui / Non) }
Function ConfirmBox(Const Txt: String): Boolean;
Begin
 ConfirmBox:=PmBox('Notator for OS2-Zero',Txt,MB_YESNO Or MB_QUERY)=MBID_YES;
 NeedDraw:=True;
End;

Function FormBox(Const Title: String; N: Integer): Boolean;
Var LW,W,H,X1,Y1,X2,Y2,I,F,FX,FY,FW: Integer; E: TEvent;
Done,Ok,Fresh,Redraw: Boolean; Ch: Char; CancelS: String;
Begin
 CancelS:=T3('Cancel','Annuler','Abbruch');
 LW:=0;
 For I:=1 To N Do If Length(FormLbl[I])>LW Then LW:=Length(FormLbl[I]);
 LW:=LW*8+8;
 FW:=FormFW*8+8;
 W:=LW+FW+32;
 If W<TextW(Title)+80 Then W:=TextW(Title)+80;
 If W>620 Then Begin W:=620;FW:=W-LW-32;End;
 H:=TB_H+N*22+56;
 X1:=(SCR_W-W) Div 2;X2:=X1+W;Y1:=(SCR_H-H) Div 2-20;Y2:=Y1+H;
 F:=1;Fresh:=True;Done:=False;Ok:=False;Redraw:=True;
 Repeat
  If Redraw Then Begin
   HideMouse;
   DlgBox(X1,Y1,X2,Y2,Title,True);
   For I:=1 To N Do Begin
    PText(X1+14,Y1+TB_H+16+(I-1)*22,FormLbl[I]);
    FX:=X1+14+LW;FY:=Y1+TB_H+12+(I-1)*22;
    Field(FX,FY,FX+FW,FY+14);
    If (I=F) And Fresh Then Begin
     Box(FX+1,FY+1,FX+8*Length(FormVal[I])+3,FY+13,OS_TITLE);
     WText(FX+3,FY+4,Copy(FormVal[I],1,FormFW));
    End Else Begin
     PText(FX+3,FY+4,Copy(FormVal[I],1,FormFW));
     If I=F Then PText(FX+3+8*Length(Copy(FormVal[I],1,FormFW)),FY+4,'_');
    End;
   End;
   DlgButton(X1+14,Y2-28,X1+84,Y2-8,'OK',True);
   DlgButton(X2-94,Y2-28,X2-14,Y2-8,CancelS,False);
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ENTER: Begin Ok:=True;Done:=True;End;
    K_ESC: Done:=True;
    K_TAB,K_DOWN: Begin If F<N Then Inc(F) Else
      F:=1;Fresh:=True;Redraw:=True;End;
    K_STAB,K_UP: Begin If F>1 Then Dec(F) Else
      F:=N;Fresh:=True;Redraw:=True;End;
    K_BKSP: Begin
             If Fresh Then FormVal[F]:='' Else If Length(FormVal[F])>0 Then
               Dec(FormVal[F][0]);
             Fresh:=False;Redraw:=True;
            End;
    K_DEL: Begin FormVal[F]:='';Fresh:=False;Redraw:=True;End;
    32..255: Begin
              Ch:=Chr(E.Key);
              If Fresh Then FormVal[F]:='';
              Fresh:=False;
              If Length(FormVal[F])<FormFW Then FormVal[F]:=FormVal[F]+Ch;
              Redraw:=True;
             End;
   End;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2) Then Done:=True
   Else
     If InBox(E.X,E.Y,X2-30,Y1+3,X2-4,Y1+TB_H)
       Or InBox(E.X,E.Y,X1+14,Y2-28,X1+84,Y2-8) Then Begin
     Ok:=True;Done:=True;End
   Else If InBox(E.X,E.Y,X2-94,Y2-28,X2-14,Y2-8) Then Done:=True
   Else For I:=1 To N Do
    If InBox(E.X,E.Y,X1+14+LW,Y1+TB_H+12+(I-1)*22,X1+14+LW+FW,
        Y1+TB_H+26+(I-1)*22) Then Begin
     F:=I;Fresh:=False;Redraw:=True;
    End;
  End;
 Until Done;
 FormBox:=Ok;
 NeedDraw:=True;
End;

Function InputBox(Const Title,Prompt: String; Var S: String;
                  MaxLen: Integer): Boolean;
Begin
 FormLbl[1]:=Copy(Prompt,1,30);
 FormVal[1]:=Copy(S,1,70);
 FormFW:=MaxLen;
 If FormFW>40 Then FormFW:=40;
 If FormBox(Title,1) Then Begin
  S:=FormVal[1];
  InputBox:=True;
 End Else InputBox:=False;
End;

{ Demande un nombre ; retourne False si annule }
Function AskNum(Const Title,Prompt: String; Var V: LongInt;
                Lo,Hi: LongInt): Boolean;
Var S: String;
Begin
 AskNum:=False;
 S:=IntStr(V);
 If InputBox(Title,Prompt,S,10) Then Begin
  V:=Clamp(ToInt(S),Lo,Hi);
  AskNum:=True;
 End;
End;

{ Boite de selection dans une liste : LstItem[1..LstN]. Retourne 0 si annule }
Function ChooseBox(Const Title: String; Start: Integer): Integer;
Var X1,Y1,X2,Y2,W,H,I,Top,Sel,VisN: Integer; E: TEvent; Done,Redraw: Boolean;
Res: Integer; CancelS: String;
Begin
 CancelS:=T3('Cancel','Annuler','Abbruch');
 W:=TextW(Title)+80;
 For I:=1 To LstN Do If TextW(LstItem[I])+60>W Then W:=TextW(LstItem[I])+60;
 If W<260 Then W:=260;
 VisN:=LstN;
 If VisN>16 Then VisN:=16;
 If VisN<3 Then VisN:=3;
 H:=TB_H+VisN*12+50;
 X1:=(SCR_W-W) Div 2;X2:=X1+W;Y1:=(SCR_H-H) Div 2-10;Y2:=Y1+H;
 Sel:=Start;If Sel<1 Then Sel:=1;If Sel>LstN Then Sel:=LstN;
 Top:=1;
 Done:=False;Res:=0;Redraw:=True;
 Repeat
  If Sel<Top Then Top:=Sel;
  If Sel>=Top+VisN Then Top:=Sel-VisN+1;
  If Redraw Then Begin
   HideMouse;
   DlgBox(X1,Y1,X2,Y2,Title,True);
   Field(X1+10,Y1+TB_H+8,X2-28,Y1+TB_H+8+VisN*12+2);
   For I:=Top To Top+VisN-1 Do
    If I<=LstN Then Begin
     If I=Sel Then Begin
      Box(X1+11,Y1+TB_H+9+(I-Top)*12,X2-29,Y1+TB_H+20+(I-Top)*12,OS_TITLE);
      WText(X1+14,Y1+TB_H+11+(I-Top)*12,LstItem[I]);
     End Else PText(X1+14,Y1+TB_H+11+(I-Top)*12,LstItem[I]);
    End;
   ArrowBox(X2-26,Y1+TB_H+8,X2-10,Y1+TB_H+24,1);
   ArrowBox(X2-26,Y1+TB_H+8+VisN*12-14,X2-10,Y1+TB_H+8+VisN*12+2,2);
   DlgButton(X1+14,Y2-26,X1+84,Y2-8,'OK',True);
   DlgButton(X2-94,Y2-26,X2-14,Y2-8,CancelS,False);
   ShowMouse;
   Redraw:=False;
  End;
  PollEvent(E);
  If E.Kind=1 Then Begin
   Case E.Key Of
    K_ENTER: Begin Res:=Sel;Done:=True;End;
    K_ESC: Done:=True;
    K_UP: If Sel>1 Then Begin Dec(Sel);Redraw:=True;End;
    K_DOWN: If Sel<LstN Then Begin Inc(Sel);Redraw:=True;End;
    K_PGUP: Begin Sel:=Max2(1,Sel-VisN);Redraw:=True;End;
    K_PGDN: Begin Sel:=Min2(LstN,Sel+VisN);Redraw:=True;End;
    K_HOME: Begin Sel:=1;Redraw:=True;End;
    K_END: Begin Sel:=LstN;Redraw:=True;End;
   End;
  End Else If E.Kind=2 Then Begin
   If InBox(E.X,E.Y,X1+2,Y1+2,X1+TB_H+2,Y1+TB_H+2)
       Or InBox(E.X,E.Y,X2-94,Y2-26,X2-14,Y2-8) Then Done:=True
   Else
     If InBox(E.X,E.Y,X2-30,Y1+3,X2-4,Y1+TB_H)
       Or InBox(E.X,E.Y,X1+14,Y2-26,X1+84,Y2-8) Then Begin
     Res:=Sel;Done:=True;End
   Else If InBox(E.X,E.Y,X2-26,Y1+TB_H+8,X2-10,Y1+TB_H+24) Then Begin
     If Sel>1 Then Dec(Sel);Redraw:=True;End
   Else
     If InBox(E.X,E.Y,X2-26,Y1+TB_H+8+VisN*12-14,X2-10,Y1+TB_H+8+VisN*12+2) Then
     Begin If Sel<LstN Then Inc(Sel);Redraw:=True;End
   Else If InBox(E.X,E.Y,X1+10,Y1+TB_H+8,X2-28,Y1+TB_H+8+VisN*12) Then Begin
    I:=Top+((E.Y-(Y1+TB_H+9)) Div 12);
    If (I>=1) And (I<=LstN) Then Begin
     If I=Sel Then Begin Res:=Sel;Done:=True;End;
     Sel:=I;Redraw:=True;
    End;
   End;
  End;
 Until Done;
 ChooseBox:=Res;
 NeedDraw:=True;
End;

{ Selecteur de fichier : liste les fichiers correspondant au masque }
Procedure ScanFiles(Const Mask: String);
Var SR: SearchRec; I: Integer; Dup: Boolean;
Begin
 FindFirst(Mask,AnyFile-Directory,SR);
 While (DosError=0) And (LstN<119) Do Begin
  Dup:=False;
  For I:=1 To LstN Do If LstItem[I]=Copy(SR.Name,1,36) Then Dup:=True;
  If Not Dup Then Begin
   Inc(LstN);
   LstItem[LstN]:=Copy(SR.Name,1,36);
  End;
  FindNext(SR);
 End;

 FindClose(SR);

End;

Function LowerStr(S: String): String;
Var I: Integer;
Begin
 For I:=1 To Length(S) Do
  If (S[I]>='A') And (S[I]<='Z') Then S[I]:=Chr(Ord(S[I])+32);
 LowerStr:=S;
End;

Function FileSelect(Const Title,Mask: String; Var Name: String): Boolean;
Var I,Sel: Integer; S: String;
Begin
 LstN:=0;
 ScanFiles(Mask);
 If LowerStr(Mask)<>Mask Then ScanFiles(LowerStr(Mask));
 Inc(LstN);
 LstItem[LstN]:=T3('[ Type a name... ]','[ Saisir un nom... ]',
                   '[ Namen eingeben... ]');
 FileSelect:=False;
 S:=Name;
 Sel:=1;
 For I:=1 To LstN-1 Do If Upper(LstItem[I])=Upper(ShortName(S)) Then Sel:=I;
 I:=ChooseBox(Title+' ('+Mask+')',Sel);
 If I=0 Then Exit;
 If I<LstN Then Begin
  Name:=LstItem[I];
  FileSelect:=True;
 End Else Begin
  If InputBox(Title,T3('File name','Nom du fichier','Dateiname'),S,36) Then Begin
   Name:=S;
   FileSelect:=(S<>'');
  End;
 End;
End;

{ ====================================================================== }
{                       MORCEAU : DONNEES MIDI                           }
{ ====================================================================== }

Const
 QuaLbl : Array[0..NQUA] Of String[5] =
  ('off','1/2','1/4','1/8','1/16','1/32','1/64','1/4T','1/8T','1/16T','1/32T');
 NoteNm : Array[0..11] Of String[2] =
  ('C ','C#','D ','D#','E ','F ','F#','G ','G#','A ','A#','B ');
 NINST = 14;
 InstName : Array[1..NINST] Of String[10] =
  ('Drums','Piano','E.Piano','Bass','Guitar','Violin','Viola','Cello',
   'Flute','Brass','Strings','Organ','Synth','Pad');
 InstProg : Array[1..NINST] Of Byte =
  (0,0,4,33,25,40,41,42,73,61,48,16,80,88);
 NDRUM = 16;
 DrumNote : Array[1..NDRUM] Of Byte =
  (36,37,38,39,40,41,42,44,46,43,45,47,48,49,51,56);
 DrumNm : Array[1..NDRUM] Of String[8] =
  ('BD 1','Rim','Snare 1','Clap','Dry SD','Tom 1','HH cl','HH ped','Open HH',
   'Tom 2','Tom 3','Tom 4','Tom 5','Crash','Ride','Cowbell');

Var
 PPQ      : Integer;
 Tempo10k : LongInt;                 { tempo x 10000 }
 SigN,SigD: Integer;
 KeyS     : Integer;                 { armure -7..7 }
 FmtQ     : Integer;                 { quantification d'affichage }
 SyncMode : Integer;                 { 0 intern, 1 MIDI, 2 SMPTE }
 SyncDel  : Integer;
 SongName : String[79];
 SongNamed,Modified : Boolean;
 LocL,LocR: LongInt;                 { locators gauche / droit (ticks) }
 PosTick  : LongInt;                 { position courante }
 Pats     : Array[1..NPAT] Of TPat;
 Trks     : Array[1..MAXTRK] Of PTrk;
 CurPat,CurTrk : Integer;
 View     : Integer;
 TxtPool  : Array[1..NLYR] Of String[20];
 TxtUsed  : Array[1..NLYR] Of Boolean;
 GrvOff   : Array[0..3] Of Integer;  { decalage groove en % de la grille }
 GrvVel   : Array[0..3] Of Integer;  { accent de velocite par pas }
 { Drapeaux }
 FlAutoIns,FlFixVel,FlAllCha,FlLockScore : Boolean;
 FlClick,FlCountIn,FlThru,FlAutoDrop,FlCycle,FlPunch,FlFollow : Boolean;
 FlArrange : Boolean;
 PenVel,ZoomX,ZoomY,SetNo,ColorNo : Integer;
 RestQ    : Integer;                 { seuil d'affichage des silences }
 OutDev   : Integer;                 { 0 carte son, 1 MPU-401, 2 aucun }
 MpuPort  : Integer;
 PrnDest  : String[40];
 { Annulation / presse-papiers }
 UndoTI   : Integer;
 UndoCnt  : Integer;
 UndoBuf  : PEvArr;
 UndoValid: Boolean;
 ClipBuf  : PEvArr;
 ClipCnt  : Integer;
 TakePending : Boolean;

Function TI(P,T: Integer): Integer;
Begin
 TI:=(P-1)*TPP+T;
End;

Function GetTrk(I: Integer): PTrk;
Var P: PTrk; T: Integer;
Begin
 GetTrk:=Nil;
 If (I<1) Or (I>MAXTRK) Then Exit;
 If Trks[I]=Nil Then Begin
  New(P);
  FillChar(P^,SizeOf(TTrk),0);
  T:=((I-1) Mod TPP)+1;
  P^.P.Chan:=T;P^.P.Comp:=100;P^.P.Hi:=127;P^.P.Drum:=(T=10);
  If T=10 Then P^.P.Instr:='Drums';
  Trks[I]:=P;
 End;
 GetTrk:=Trks[I];
End;

Function CT: PTrk;
Begin
 CT:=GetTrk(TI(CurPat,CurTrk));
End;

Function TrkName(Idx: Integer): String;
Var P: PTrk; S: String;
Begin
 P:=Trks[Idx];
 S:='';
 If P<>Nil Then S:=P^.P.Name;
 If S='' Then S:=T3('Track ','Piste ','Spur ')+IntStr(((Idx-1) Mod TPP)+1);
 TrkName:=S;
End;

Function PortCh(P: PTrk): String;
Begin
 PortCh:=Chr(65+P^.P.Port)+' '+IntStr(P^.P.Chan);
End;

Procedure FreeTrkEv(P: PTrk);
Begin
 If P^.Ev<>Nil Then Begin Dispose(P^.Ev);P^.Ev:=Nil;End;
 P^.Cnt:=0;
End;

Function BarTicks: LongInt;
Begin
 BarTicks:=LongInt(PPQ)*4*SigN Div SigD;
End;

Function BeatTicks: LongInt;
Begin
 BeatTicks:=LongInt(PPQ)*4 Div SigD;
End;

Function PatTicks(P: Integer): LongInt;
Begin
 PatTicks:=LongInt(Pats[P].Len)*BarTicks;
End;

Function QuaTicks(Q: Integer): LongInt;
Begin
 Case Q Of
  1: QuaTicks:=PPQ*2;
  2: QuaTicks:=PPQ;
  3: QuaTicks:=PPQ Div 2;
  4: QuaTicks:=PPQ Div 4;
  5: QuaTicks:=PPQ Div 8;
  6: QuaTicks:=PPQ Div 16;
  7: QuaTicks:=PPQ*2 Div 3;
  8: QuaTicks:=PPQ Div 3;
  9: QuaTicks:=PPQ Div 6;
  10: QuaTicks:=PPQ Div 12;
 Else QuaTicks:=0;
 End;
End;

Function QuaShort(Q: Integer): String;
Begin
 If Q=0 Then QuaShort:='--' Else QuaShort:=Copy(QuaLbl[Q],3,5);
End;

{ Quantifie un instant sur la grille Q, avec groove optionnel }
Function QuantT(T,Q: LongInt; Grv: Boolean): LongInt;
Var Step,R: LongInt;
Begin
 If Q<=0 Then Begin QuantT:=T;Exit;End;
 Step:=(T+Q Div 2) Div Q;
 R:=Step*Q;
 If Grv Then R:=R+(LongInt(GrvOff[Step And 3])*Q) Div 100;
 If R<0 Then R:=0;
 QuantT:=R;
End;

{ Instant reel de lecture d'un evenement }
Function EffT(Tr: PTrk; T: LongInt): LongInt;
Var Q: LongInt;
Begin
 Q:=QuaTicks(Tr^.P.Qua);
 If Q>0 Then T:=QuantT(T,Q,Tr^.P.Groove<>0);
 EffT:=T+Tr^.P.Delay+LongInt(Tr^.P.Shift)*BarTicks;
End;

{ Instant d'affichage (partition / matrice) }
Function DispT(Tr: PTrk; T: LongInt): LongInt;
Var Q: LongInt; G: Boolean;
Begin
 Q:=QuaTicks(Tr^.P.Qua);G:=(Tr^.P.Groove<>0);
 If Q=0 Then Begin Q:=QuaTicks(FmtQ);G:=False;End;
 DispT:=QuantT(T,Q,G);
End;

Function EffVel(Tr: PTrk; V,Step: Integer): Integer;
Var X: LongInt;
Begin
 X:=64+((LongInt(V)-64)*Tr^.P.Comp) Div 100+Tr^.P.Vel+GrvVel[Step And 3];
 EffVel:=Clamp(X,1,127);
End;

Function EffNote(Tr: PTrk; N: Integer): Integer;
Begin
 EffNote:=Clamp(LongInt(N)+Tr^.P.Trans,0,127);
End;

Function NoteName(N: Integer): String;
Begin
 NoteName:=NoteNm[N Mod 12]+IntStr(N Div 12-1);
End;

Procedure TickToBBT(T: LongInt; Var Bar,Beat,Six,Tk: LongInt);
Var R,Sx: LongInt;
Begin
 If T<0 Then T:=0;
 Bar:=T Div BarTicks;R:=T Mod BarTicks;
 Beat:=R Div BeatTicks;R:=R Mod BeatTicks;
 Sx:=PPQ Div 4;
 Six:=R Div Sx;Tk:=R Mod Sx;
 Inc(Bar);Inc(Beat);Inc(Six);Inc(Tk);
End;

Function BBTToTick(Bar,Beat,Six,Tk: LongInt): LongInt;
Begin
 BBTToTick:=(Bar-1)*BarTicks+(Beat-1)*BeatTicks+(Six-1)*(PPQ Div 4)+(Tk-1);
End;

Function PosStr(T: LongInt): String;
Var B,Bt,Sx,Tk: LongInt;
Begin
 TickToBBT(T,B,Bt,Sx,Tk);
 PosStr:=IntStr(B)+' '+IntStr(Bt)+' '+IntStr(Sx)+' '+IntStr(Tk);
End;

{ Duree en ms depuis un nombre de ticks }
Function TickMs(T: LongInt): LongInt;
Var Per,B: LongInt;
Begin
 Per:=60000000 Div (Tempo10k Div 10);
 If Per<=0 Then Per:=500;
 B:=T Div PPQ;
 TickMs:=B*Per+((T Mod PPQ)*Per) Div PPQ;
End;

{ ====================================================================== }
{                       OPERATIONS SUR LES EVENEMENTS                    }
{ ====================================================================== }

Function AddEv(TIdx: Integer; T,Len: LongInt; K,D1,D2: Byte): Integer;
Var Tr: PTrk; I,J: Integer;
Begin
 AddEv:=0;
 Tr:=GetTrk(TIdx);
 If Tr=Nil Then Exit;
 If Tr^.Ev=Nil Then Begin New(Tr^.Ev);Tr^.Cnt:=0;End;
 If Tr^.Cnt>=MAXEV Then Exit;
 If T<0 Then T:=0;
 I:=Tr^.Cnt;
 While (I>0) And (Tr^.Ev^[I].T>T) Do Dec(I);
 For J:=Tr^.Cnt DownTo I+1 Do Tr^.Ev^[J+1]:=Tr^.Ev^[J];
 Inc(Tr^.Cnt);
 Tr^.Ev^[I+1].T:=T;
 Tr^.Ev^[I+1].Len:=Len;
 Tr^.Ev^[I+1].Kind:=K;
 Tr^.Ev^[I+1].D1:=D1;
 Tr^.Ev^[I+1].D2:=D2;
 Tr^.Ev^[I+1].Sty:=0;
 Tr^.Ev^[I+1].Sel:=False;
 AddEv:=I+1;
 Modified:=True;
 If PatTicks(CurPat)<=T Then
  Pats[CurPat].Len:=Min2(255,T Div BarTicks+1);
End;

Procedure DelEv(Tr: PTrk; I: Integer);
Var J: Integer;
Begin
 If (I<1) Or (I>Tr^.Cnt) Then Exit;
 For J:=I To Tr^.Cnt-1 Do Tr^.Ev^[J]:=Tr^.Ev^[J+1];
 Dec(Tr^.Cnt);
 Modified:=True;
End;

Procedure SortTrk(Tr: PTrk);
Var I,J: Integer; E: TEvt;
Begin
 If Tr^.Ev=Nil Then Exit;
 For I:=2 To Tr^.Cnt Do Begin
  E:=Tr^.Ev^[I];
  J:=I-1;
  While (J>=1) And (Tr^.Ev^[J].T>E.T) Do Begin
   Tr^.Ev^[J+1]:=Tr^.Ev^[J];
   Dec(J);
  End;
  Tr^.Ev^[J+1]:=E;
 End;
End;

Procedure SaveUndo(TIdx: Integer);
Var Tr: PTrk;
Begin
 If UndoBuf=Nil Then New(UndoBuf);
 Tr:=GetTrk(TIdx);
 UndoTI:=TIdx;
 UndoCnt:=Tr^.Cnt;
 If (Tr^.Cnt>0) And (Tr^.Ev<>Nil) Then
  Move(Tr^.Ev^,UndoBuf^,Tr^.Cnt*SizeOf(TEvt));
 UndoValid:=True;
End;

Procedure DoUndo;
Var Tr: PTrk;
Begin
 If Not UndoValid Then Begin
  MsgBox('Undo',T3('Nothing to undo.','Rien '#133' annuler.',
    'Nichts r'#129'ckg'#132'ngig zu machen.'));
  Exit;
 End;
 Tr:=GetTrk(UndoTI);
 If Tr^.Ev=Nil Then New(Tr^.Ev);
 Tr^.Cnt:=UndoCnt;
 If UndoCnt>0 Then Move(UndoBuf^,Tr^.Ev^,UndoCnt*SizeOf(TEvt));
 UndoValid:=False;
 TakePending:=False;
 Modified:=True;
 NeedDraw:=True;
End;

Function SelCount(Tr: PTrk): Integer;
Var I,N: Integer;
Begin
 N:=0;
 For I:=1 To Tr^.Cnt Do If Tr^.Ev^[I].Sel Then Inc(N);
 SelCount:=N;
End;

Procedure SelAll(Tr: PTrk; V: Boolean);
Var I: Integer;
Begin
 For I:=1 To Tr^.Cnt Do Tr^.Ev^[I].Sel:=V;
End;

{ Recherche d'une note (hauteur) a l'instant T ; retourne l'index ou 0 }
Function FindNote(Tr: PTrk; T: LongInt; Pitch: Integer; Tol: LongInt): Integer;
Var I: Integer;
Begin
 FindNote:=0;
 For I:=1 To Tr^.Cnt Do
  If (Tr^.Ev^[I].Kind=EK_NOTE) And (Tr^.Ev^[I].D1=Pitch) Then
   If (Tr^.Ev^[I].T-Tol<=T) And (Tr^.Ev^[I].T+Tr^.Ev^[I].Len>T) Then Begin
    FindNote:=I;Exit;
   End;
End;

Procedure ResetTrkPar(Tr: PTrk);
Begin
 Tr^.P.Qua:=0;Tr^.P.Groove:=0;Tr^.P.Trans:=0;Tr^.P.Vel:=0;Tr^.P.Comp:=100;
 Tr^.P.Delay:=0;Tr^.P.Loop:=0;Tr^.P.Lo:=0;Tr^.P.Hi:=127;Tr^.P.Shift:=0;
End;

Procedure InitSong;
Var I: Integer;
Begin
 For I:=1 To MAXTRK Do
  If Trks[I]<>Nil Then Begin
   FreeTrkEv(Trks[I]);
   Dispose(Trks[I]);
   Trks[I]:=Nil;
  End;
 FillChar(Pats,SizeOf(Pats),0);
 For I:=1 To NPAT Do Begin Pats[I].Len:=8;Pats[I].Name:='';End;
 Pats[1].Name:='Intro';
 FillChar(TxtUsed,SizeOf(TxtUsed),0);
 PPQ:=384;Tempo10k:=1200000;SigN:=4;SigD:=4;KeyS:=0;FmtQ:=4;
 SyncMode:=0;SyncDel:=0;
 LocL:=0;LocR:=BarTicks*4;PosTick:=0;
 CurPat:=1;CurTrk:=1;
 GrvOff[0]:=0;GrvOff[1]:=0;GrvOff[2]:=0;GrvOff[3]:=0;
 GrvVel[0]:=0;GrvVel[1]:=0;GrvVel[2]:=0;GrvVel[3]:=0;
 SongName:='NEWSONG.SON';SongNamed:=False;Modified:=False;
 UndoValid:=False;TakePending:=False;
 ClipCnt:=0;
End;

{ Index libre dans le pool de textes }
Function NewText(Const S: String): Integer;
Var I: Integer;
Begin
 NewText:=0;
 For I:=1 To NLYR Do
  If Not TxtUsed[I] Then Begin
   TxtUsed[I]:=True;TxtPool[I]:=Copy(S,1,20);NewText:=I;Exit;
  End;
End;

{ ====================================================================== }
{                  MOTEUR : SORTIE MIDI / LECTURE / ENREGISTREMENT       }
{ ====================================================================== }

Const
 MAXSND = 48;
 SpkBase : Array[0..11] Of Word =
  (818,866,917,972,1030,1091,1156,1224,1297,1375,1457,1544);

Type
 TSnd = Record
  Used,UseCs : Boolean;
  Port,Chan,Note : Byte;
  OffAt : LongInt;
 End;

Var
 Playing,Recording,CountInOn : Boolean;
 PlayTick   : LongInt;
 LastCs,RemT: LongInt;
 SongLen    : LongInt;
 NSeg       : Array[1..4] Of Integer;
 SegPat,SegRep : Array[1..4,1..NPAT] Of Byte;
 SegStart   : Array[1..4,1..NPAT+1] Of LongInt;
 ChainLen   : Array[1..4] Of LongInt;
 ChSeg,ChPat: Array[1..4] Of Integer;
 ChIter     : Array[1..4] Of LongInt;
 PIdx,PK    : Array[1..4,1..TPP] Of Integer;
 SoloAny    : Boolean;
 Snd        : Array[1..MAXSND] Of TSnd;
 SpkFreq    : Word;
 ClickUntil : LongInt;
 LastBeat   : LongInt;
 RecTI      : Integer;
 RecStart   : Array[0..127] Of LongInt;
 Oct        : Integer;
 InSt,InD1,InN : Integer;
 PlayShown  : LongInt;       { derniere position affichee }

Function NowCs: LongInt;
Begin
 NowCs:=KTicks Div 10;
End;

Function CurPos: LongInt;
Begin
 If Playing Then CurPos:=PlayTick Else CurPos:=PosTick;
End;

Var
 PenDur : Integer;           { 0 ronde .. 5 triple-croche }
 PenDot,PenTrip : Boolean;

Function PenTicks: LongInt;
Var L: LongInt;
Begin
 L:=(LongInt(PPQ)*4) Shr PenDur;
 If PenDot Then L:=L*3 Div 2;
 If PenTrip Then L:=L*2 Div 3;
 PenTicks:=L;
End;

Procedure MidiSend(Port1,St,D1,D2: Byte; Cnt: Integer);
Begin

End;

{ ---- Synthetiseur logiciel PCM16 mono (22050 Hz) joue par MDM.DLL ----
  MDM.DLL (MMPM/2 d'OS/2-0) joue un tampon en memoire et le lit au fur et a
  mesure : le flux est un tampon de 20 s (44100 Hz, 16 bits, stereo) que
  SynthPump remplit juste devant la position de lecture de la carte (avance
  = anneau du pilote + 50 ms). Au bout du tampon, ce qui reste a jouer est
  ramene au debut et le flux est relance. }
{$Q-}{$R-}
Const
 SynthRate  = 22050;
 SynthBlock = 1024;          { octets par bloc rendu (512 echantillons) }
 NVoice     = 24;
 StrRate    = 44100;         { flux envoye a MDM }
 StrFrames  = 882000;        { 20 s }
 BlkFrames  = 1024;          { trames de flux par bloc (2 par echantillon) }

Type
 TVoice = Record
  Used : Boolean;
  Chan,Note,Timbre,Stage,Kind : Byte;
  Phase,Inc,IncMin,Seed : LongWord;
  Level,Amp,Age,Atk,DecS,Sus,RelS,Prev : LongInt;
 End;
 PSmallArr = ^TSmallArr;
 TSmallArr = Array[0..SynthBlock Div 2-1] Of SmallInt;
 PStrArr = ^TStrArr;
 TStrArr = Array[0..StrFrames-1] Of LongInt;

Var
 WaveOpened : Boolean;
 StrBuf     : PStrArr;
 RendF,LeadF: LongInt;
 SynBlk     : TSmallArr;
 Voices     : Array[1..NVoice] Of TVoice;
 SinTab     : Array[0..255] Of LongInt;
 NoteInc    : Array[0..127] Of LongWord;
 ChanTimbre : Array[1..16] Of Byte;
 VoiceAge   : LongInt;
 TablesDone : Boolean;

Function TimbreOf(Const S: String): Byte;
Var U: String;
Begin
 U:=Upper(S);
 TimbreOf:=0;
 If U='FLUTE' Then TimbreOf:=1
 Else If (U='STRINGS') Or (U='VIOLIN') Or (U='VIOLA') Or (U='CELLO') Or
   (U='ORGAN') Or (U='PAD') Or (U='SYNTH') Then TimbreOf:=2
 Else If U='BASS' Then TimbreOf:=3
 Else If U='BRASS' Then TimbreOf:=4;
End;

Procedure SynthTables;
Var I: Integer; F: Double;
Begin
 If TablesDone Then Exit;
 For I:=0 To 255 Do SinTab[I]:=Round(32767*Sin(2*Pi*I/256));
 For I:=0 To 127 Do Begin
  F:=440*Exp(Ln(2)*(I-69)/12);
  F:=F/SynthRate*4294967296.0;
  If F>2147483647.0 Then F:=F-4294967296.0;
  NoteInc[I]:=LongWord(Round(F));
 End;
 For I:=1 To 16 Do ChanTimbre[I]:=0;
 FillChar(Voices,SizeOf(Voices),0);
 TablesDone:=True;
End;

Function MdmCardFormat(PRate,PBits,PCh: LongInt): LongInt; External 'MDM' Name 'MDMCARDFORMAT';

{ (re)lancer le flux sur le tampon ; Keep trames deja rendues au debut }
Function StreamBegin(Keep: LongInt): Boolean;
Var R,B,C,Fb1: LongInt;
Begin
 StreamBegin:=False;
 If MdmPlay(LongInt(StrBuf),StrFrames*4,StrRate,16,2)<>0 Then Exit;
 R:=0;B:=0;C:=0;
 Dummy:=MdmCardFormat(LongInt(@R),LongInt(@B),LongInt(@C));
 Fb1:=(B Div 8)*C;
 If (R<=0) Or (Fb1<=0) Then Begin R:=StrRate;Fb1:=4;End;
 { le pilote lit d'avance un anneau de 64 Ko au format de la carte }
 LeadF:=(65536 Div Fb1)*(StrRate Div 100) Div (R Div 100)+2205;
 If Keep<LeadF Then Keep:=LeadF;
 RendF:=Keep;
 StreamBegin:=True;
End;

Function SynthStart: Boolean;
Var CardName: Array[0..63] Of Byte;
Begin
 SynthStart:=False;
 If WaveOpened Then Begin SynthStart:=True;Exit;End;
 SynthTables;
 If MdmAudioInfo(LongInt(@CardName),64)=0 Then Exit;
 If StrBuf=Nil Then
  If DosAllocMem(LongInt(@StrBuf),StrFrames*4,$13)<>0 Then Begin StrBuf:=Nil;Exit;End;
 FillChar(StrBuf^,StrFrames*4,0);
 If Not StreamBegin(0) Then Exit;
 WaveOpened:=True;
 SynthStart:=True;
End;

Procedure SynthStop;
Begin
 If Not WaveOpened Then Exit;
 Dummy:=MdmStop;
 WaveOpened:=False;
 FillChar(Voices,SizeOf(Voices),0);
End;

Procedure SynthNoteOn(Ch,Nt,Vl,Tb: Integer);
Var I,F,Old: Integer;
Begin
 If Not WaveOpened Then Exit;
 F:=0;Old:=1;
 For I:=1 To NVoice Do Begin
  If (F=0) And (Not Voices[I].Used) Then F:=I;
  If Voices[I].Age<Voices[Old].Age Then Old:=I;
 End;
 If F=0 Then F:=Old;
 Inc(VoiceAge);
 Voices[F].Used:=True;Voices[F].Chan:=Ch;Voices[F].Note:=Nt;
 Voices[F].Timbre:=Tb;Voices[F].Stage:=0;Voices[F].Kind:=0;
 Voices[F].Phase:=0;Voices[F].Level:=0;Voices[F].Prev:=0;
 Voices[F].Seed:=LongWord(VoiceAge)*LongWord(-1640531535)+LongWord(Nt);
 Voices[F].Age:=VoiceAge;
 Voices[F].Amp:=Vl;
 Voices[F].Inc:=NoteInc[Clamp(Nt,0,127)];
 Voices[F].IncMin:=0;
 If Ch=10 Then Begin
  { batterie : timbre = famille de percussion }
  Voices[F].Timbre:=5;Voices[F].Stage:=1;Voices[F].Level:=32767;
  Voices[F].Atk:=0;Voices[F].Sus:=0;Voices[F].RelS:=9;
  Case Nt Of
   35,36: Begin Voices[F].Kind:=1;Voices[F].DecS:=12;
           Voices[F].Inc:=NoteInc[67];Voices[F].IncMin:=NoteInc[31];End;
   37,38,39,40: Begin Voices[F].Kind:=2;Voices[F].DecS:=11;
           Voices[F].Inc:=NoteInc[55];End;
   42,44: Begin Voices[F].Kind:=3;Voices[F].DecS:=9;End;
   46: Begin Voices[F].Kind:=3;Voices[F].DecS:=12;End;
   49,51,52,53,55,57: Begin Voices[F].Kind:=3;Voices[F].DecS:=14;End;
   41,43,45,47,48,50: Begin Voices[F].Kind:=4;Voices[F].DecS:=12;
           Voices[F].Inc:=NoteInc[Clamp(Nt+12,0,127)];
           Voices[F].IncMin:=NoteInc[Clamp(Nt+4,0,127)];End;
   56: Begin Voices[F].Kind:=5;Voices[F].DecS:=11;
           Voices[F].Inc:=NoteInc[89];End;
  Else Begin Voices[F].Kind:=2;Voices[F].DecS:=10;End;
  End;
 End Else
  Case Tb Of
   1: Begin Voices[F].Atk:=40;Voices[F].DecS:=14;Voices[F].Sus:=26000;Voices[F].RelS:=10;End;
   2: Begin Voices[F].Atk:=12;Voices[F].DecS:=14;Voices[F].Sus:=28000;Voices[F].RelS:=11;End;
   3: Begin Voices[F].Atk:=6000;Voices[F].DecS:=12;Voices[F].Sus:=6000;Voices[F].RelS:=9;End;
   4: Begin Voices[F].Atk:=60;Voices[F].DecS:=13;Voices[F].Sus:=24000;Voices[F].RelS:=10;End;
   6: Begin Voices[F].Atk:=32767;Voices[F].DecS:=8;Voices[F].Sus:=0;Voices[F].RelS:=8;
           Voices[F].Inc:=NoteInc[102];End;
  Else Begin Voices[F].Atk:=8000;Voices[F].DecS:=13;Voices[F].Sus:=0;Voices[F].RelS:=9;End;
  End;
End;

Procedure SynthNoteOff(Ch,Nt: Integer);
Var I: Integer;
Begin
 If Ch=10 Then Exit;
 For I:=1 To NVoice Do
  If Voices[I].Used And (Voices[I].Chan=Ch) And (Voices[I].Note=Nt)
     And (Voices[I].Stage<2) Then Voices[I].Stage:=2;
End;

Procedure SynthAllOff;
Var I: Integer;
Begin
 For I:=1 To NVoice Do
  If Voices[I].Used Then Voices[I].Stage:=2;
End;

Procedure SynthRender(Buf: PSmallArr; N: Integer);
Var K,I,Idx,W,Nz: Integer; Mix: LongInt; V: ^TVoice;
Begin
 For K:=0 To N-1 Do Begin
  Mix:=0;
  For I:=1 To NVoice Do
   If Voices[I].Used Then Begin
    V:=@Voices[I];
    Idx:=Integer(V^.Phase Shr 24);
    If V^.Timbre=5 Then Begin
     V^.Seed:=V^.Seed*1664525+1013904223;
     Nz:=Integer(V^.Seed Shr 17)-16384;
     Case V^.Kind Of
      1,4: Begin
            W:=SinTab[Idx];
            If V^.Inc>V^.IncMin Then V^.Inc:=V^.Inc-(V^.Inc Shr 11);
           End;
      2: W:=Nz Div 2+SinTab[Idx] Div 4;
      3: Begin W:=Nz-Integer(V^.Prev);V^.Prev:=Nz;End;
      5: If Idx<128 Then W:=16000 Else W:=-16000;
     Else W:=Nz;
     End;
     V^.Phase:=V^.Phase+V^.Inc;
    End Else Begin
     Case V^.Timbre Of
      1: W:=SinTab[Idx]+SinTab[(Idx*2) And 255] Div 6;
      2: W:=(Idx*256-32768) Div 2+SinTab[Idx] Div 3;
      3: If Idx<128 Then W:=(18000+SinTab[Idx]) Div 2 Else W:=(-18000+SinTab[Idx]) Div 2;
      4: W:=(Idx*256-32768) Div 2+SinTab[(Idx*2) And 255] Div 4;
      6: W:=SinTab[Idx];
     Else W:=(SinTab[Idx]+SinTab[(Idx*2) And 255] Div 2+
              SinTab[(Idx*3) And 255] Div 3) Div 2;
     End;
     V^.Phase:=V^.Phase+V^.Inc;
    End;
    { enveloppe }
    Case V^.Stage Of
     0: Begin
         V^.Level:=V^.Level+V^.Atk;
         If V^.Level>=32767 Then Begin V^.Level:=32767;V^.Stage:=1;End;
        End;
     1: If V^.Level>V^.Sus Then Begin
         V^.Level:=V^.Level-(V^.Level Shr V^.DecS)-1;
         If V^.Level<V^.Sus Then V^.Level:=V^.Sus;
         If (V^.Sus=0) And (V^.Level<=8) Then V^.Used:=False;
        End;
    Else Begin
         V^.Level:=V^.Level-(V^.Level Shr V^.RelS)-1;
         If V^.Level<=0 Then Begin V^.Level:=0;V^.Used:=False;End;
        End;
    End;
    Mix:=Mix+(((LongInt(W)*V^.Level) Div 32768)*V^.Amp) Div 127;
   End;
  Mix:=Mix Div 3;
  If Mix>32767 Then Mix:=32767;
  If Mix<-32767 Then Mix:=-32767;
  Buf^[K]:=SmallInt(Mix);
 End;
End;

{ remplit les tampons libres ; appele par le moteur a chaque passage }
Procedure SynthPump;
Var Pos,PlayF,Target,K,V,Keep: LongInt;
Begin
 If Not WaveOpened Then Exit;
 Pos:=MdmPosition;
 If Pos<0 Then Begin
  { flux arrete (fin du tampon ou erreur) : le relancer }
  FillChar(StrBuf^,StrFrames*4,0);
  If Not StreamBegin(0) Then Begin WaveOpened:=False;Exit;End;
  Pos:=0;
 End;
 PlayF:=Pos Div 4;
 If RendF<PlayF+LeadF Then RendF:=PlayF+LeadF;
 Target:=PlayF+LeadF+BlkFrames;
 While RendF<Target Do Begin
  If RendF+BlkFrames>StrFrames Then Begin
   { bout du tampon : ramener ce qui reste a jouer au debut }
   PlayF:=MdmPosition Div 4;
   If PlayF<0 Then PlayF:=0;
   If PlayF>RendF Then PlayF:=RendF;
   Keep:=RendF-PlayF;
   Move(StrBuf^[PlayF],StrBuf^[0],Keep*4);
   FillChar(StrBuf^[Keep],(StrFrames-Keep)*4,0);
   If Not StreamBegin(Keep) Then Begin WaveOpened:=False;Exit;End;
   Target:=LeadF+BlkFrames;
   If RendF>=Target Then Exit;
  End;
  SynthRender(@SynBlk,SynthBlock Div 2);
  For K:=0 To SynthBlock Div 2-1 Do Begin
   V:=(LongInt(SynBlk[K]) And $FFFF) Or (LongInt(SynBlk[K]) Shl 16);
   StrBuf^[RendF+2*K]:=V;
   StrBuf^[RendF+2*K+1]:=V;
  End;
  RendF:=RendF+BlkFrames;
 End;
End;

Procedure SpeakerSet(F: Word);
Begin
 If F=SpkFreq Then Exit;
 SpkFreq:=F;

End;

Procedure SpeakerUpdate;
Var I,Hi: Integer; F: LongInt;
Begin
 { OS/2 : le synthetiseur logiciel remplace le haut-parleur }
 If OutDev=0 Then SynthPump;
 Exit;

 If OutDev<>0 Then Begin SpeakerSet(0);Exit;End;
 If NowCs<ClickUntil Then Begin SpeakerSet(1200);Exit;End;
 Hi:=-1;
 For I:=1 To MAXSND Do
  If Snd[I].Used And (Snd[I].Chan<>10) Then
   If Snd[I].Note>Hi Then Hi:=Snd[I].Note;
 If Hi<0 Then Begin
  For I:=1 To MAXSND Do
   If Snd[I].Used And (Snd[I].Chan=10) Then Hi:=0;
  If Hi=0 Then Begin SpeakerSet(110);Exit;End;
  SpeakerSet(0);Exit;
 End;
 F:=(LongInt(SpkBase[Hi Mod 12])*(1 Shl (Hi Div 12))) Div 100;
 If F<40 Then F:=40;
 If F>12000 Then F:=12000;
 SpeakerSet(F);
End;

Procedure SndOn(Port1,Chan,Note,Vel: Byte; OffAt: LongInt; UseCs: Boolean);
Var I,F: Integer;
Begin

 If OutDev=0 Then SynthNoteOn(Chan,Note,Vel,ChanTimbre[Chan]);

 F:=0;I:=1;
 While (F=0) And (I<=MAXSND) Do Begin
  If Not Snd[I].Used Then F:=I;
  Inc(I);
 End;
 If F=0 Then F:=1;
 Snd[F].Used:=True;Snd[F].Port:=Port1;Snd[F].Chan:=Chan;Snd[F].Note:=Note;
 Snd[F].OffAt:=OffAt;Snd[F].UseCs:=UseCs;
 MidiSend(Port1,$90+(Chan-1),Note,Vel,3);
End;

Procedure SndOff(I: Integer);
Begin
 If Not Snd[I].Used Then Exit;

 If OutDev=0 Then SynthNoteOff(Snd[I].Chan,Snd[I].Note);

 MidiSend(Snd[I].Port,$80+(Snd[I].Chan-1),Snd[I].Note,0,3);
 Snd[I].Used:=False;
End;

Procedure AllNotesOff;
Var I,C: Integer;
Begin
 For I:=1 To MAXSND Do SndOff(I);

 SynthAllOff;

 SpeakerSet(0);
End;

Procedure UpdateSolo;
Var I: Integer;
Begin
 SoloAny:=False;
 For I:=1 To MAXTRK Do
  If (Trks[I]<>Nil) Then If Trks[I]^.P.Solo Then SoloAny:=True;
End;

Function Audible(Tr: PTrk): Boolean;
Begin
 If SoloAny Then Audible:=Tr^.P.Solo And Not Tr^.P.Mute
 Else Audible:=Not Tr^.P.Mute;
End;

{ Declenche un evenement de piste }
Procedure Fire(Tr: PTrk; Var E: TEvt; Te,Lt: LongInt);
Var Note,Vel: Integer; Q,Step: LongInt; Ch: Byte;
Begin
 Ch:=Tr^.P.Chan;
 Case E.Kind Of
  EK_NOTE: Begin

    ChanTimbre[Ch]:=TimbreOf(Tr^.P.Instr);

    Note:=EffNote(Tr,E.D1);
    If (Note<Tr^.P.Lo) Or (Note>Tr^.P.Hi) Then Exit;
    Q:=QuaTicks(Tr^.P.Qua);Step:=0;
    If Q>0 Then Step:=(E.T+Q Div 2) Div Q;
    Vel:=EffVel(Tr,E.D2,Step);
    SndOn(Tr^.P.Port,Ch,Note,Vel,PlayTick+(Te+E.Len-Lt),False);
   End;
  EK_CTRL: MidiSend(Tr^.P.Port,$B0+(Ch-1),E.D1,E.D2,3);
  EK_PROG: MidiSend(Tr^.P.Port,$C0+(Ch-1),E.D1,0,2);
  EK_BEND: MidiSend(Tr^.P.Port,$E0+(Ch-1),E.D1,E.D2,3);
  EK_CHANP: MidiSend(Tr^.P.Port,$D0+(Ch-1),E.D1,0,2);
  EK_POLYP: MidiSend(Tr^.P.Port,$A0+(Ch-1),E.D1,E.D2,3);
 End;
End;

{ Joue les evenements d'une piste jusqu'a l'instant local Lt }
Procedure PlayTrack(C,T,Pat: Integer; Lt,PT: LongInt);
Var Tr: PTrk; Done: Boolean; LoopLen,Te: LongInt;
Begin
 Tr:=Trks[TI(Pat,T)];
 If Tr=Nil Then Exit;
 If (Tr^.Ev=Nil) Or Not Audible(Tr) Then Exit;
 LoopLen:=LongInt(Tr^.P.Loop)*BarTicks;
 Done:=False;
 Repeat
  If PIdx[C,T]>Tr^.Cnt Then Begin
   If (LoopLen>0) And ((PK[C,T]+1)*LoopLen<PT) Then Begin
    Inc(PK[C,T]);PIdx[C,T]:=1;
   End Else Done:=True;
  End Else Begin
   If (LoopLen>0) And (Tr^.Ev^[PIdx[C,T]].T>=LoopLen) Then Inc(PIdx[C,T])
   Else Begin
    Te:=EffT(Tr,Tr^.Ev^[PIdx[C,T]].T)+PK[C,T]*LoopLen;
    If Te>Lt Then Done:=True
    Else Begin
     Fire(Tr,Tr^.Ev^[PIdx[C,T]],Te,Lt);
     Inc(PIdx[C,T]);
    End;
   End;
  End;
 Until Done;
End;

Procedure BuildChains;
Var C,R,K: Integer; Any: Boolean;
Begin
 For C:=1 To 4 Do Begin NSeg[C]:=0;ChainLen[C]:=0;ChSeg[C]:=0;End;
 Any:=False;
 If FlArrange Then
  For C:=1 To 4 Do
   For R:=1 To NPAT Do
    If Pats[R].Rep[C]>0 Then Begin
     Inc(NSeg[C]);K:=NSeg[C];
     SegPat[C,K]:=R;SegRep[C,K]:=Pats[R].Rep[C];
     SegStart[C,K]:=ChainLen[C];
     ChainLen[C]:=ChainLen[C]+PatTicks(R)*Pats[R].Rep[C];
     SegStart[C,K+1]:=ChainLen[C];
     Any:=True;
    End;
 If Not Any Then Begin
  NSeg[1]:=1;SegPat[1,1]:=CurPat;SegRep[1,1]:=1;SegStart[1,1]:=0;
  ChainLen[1]:=PatTicks(CurPat);SegStart[1,2]:=ChainLen[1];
 End;
 SongLen:=0;
 For C:=1 To 4 Do If ChainLen[C]>SongLen Then SongLen:=ChainLen[C];
End;

Function FindSeg(C: Integer; T: LongInt): Integer;
Var K: Integer;
Begin
 K:=NSeg[C];
 While (K>1) And (T<SegStart[C,K]) Do Dec(K);
 FindSeg:=K;
End;

Procedure ResetChain(C,S: Integer; Iter: LongInt; Lt: LongInt);
Var T,Pat: Integer; Tr: PTrk; LoopLen: LongInt;
Begin
 Pat:=SegPat[C,S];
 ChSeg[C]:=S;ChIter[C]:=Iter;ChPat[C]:=Pat;
 For T:=1 To TPP Do Begin
  PIdx[C,T]:=1;PK[C,T]:=0;
  Tr:=Trks[TI(Pat,T)];
  If (Tr<>Nil) And (Tr^.Ev<>Nil) And (Lt>0) Then Begin
   LoopLen:=LongInt(Tr^.P.Loop)*BarTicks;
   If LoopLen>0 Then PK[C,T]:=Lt Div LoopLen;
   While (PIdx[C,T]<=Tr^.Cnt) And
     (EffT(Tr,Tr^.Ev^[PIdx[C,T]].T)+PK[C,T]*LoopLen<Lt) Do Inc(PIdx[C,T]);
  End;
 End;
End;

Procedure PlaySeek(Tick: LongInt);
Var C,S: Integer; Pt,Loc: LongInt;
Begin
 AllNotesOff;
 For C:=1 To 4 Do Begin
  ChSeg[C]:=0;
  If (NSeg[C]>0) And (Tick<ChainLen[C]) And (Tick>=0) Then Begin
   S:=FindSeg(C,Tick);
   Pt:=PatTicks(SegPat[C,S]);
   Loc:=Tick-SegStart[C,S];
   ResetChain(C,S,Loc Div Pt,Loc Mod Pt);
  End;
 End;
 PlayTick:=Tick;
End;

Procedure PlayChain(C: Integer; NewTick: LongInt);
Var S,T: Integer; Pt,Loc,Lt: LongInt;
Begin
 If (NSeg[C]=0) Or (NewTick<0) Then Exit;
 If NewTick>=ChainLen[C] Then Exit;
 S:=FindSeg(C,NewTick);
 Pt:=PatTicks(SegPat[C,S]);
 Loc:=NewTick-SegStart[C,S];
 Lt:=Loc Mod Pt;
 If (S<>ChSeg[C]) Or ((Loc Div Pt)<>ChIter[C]) Then Begin
  If ChSeg[C]>0 Then
   For T:=1 To TPP Do PlayTrack(C,T,ChPat[C],PatTicks(ChPat[C])-1,
     PatTicks(ChPat[C]));
  ResetChain(C,S,Loc Div Pt,0);
 End;
 For T:=1 To TPP Do PlayTrack(C,T,SegPat[C,S],Lt,Pt);
End;

Procedure StopPlay; Forward;

Procedure Click;
Begin
 ClickUntil:=NowCs+4;

 If OutDev=0 Then SynthNoteOn(1,102,100,6);

End;

Procedure AdvanceTo(NewTick: LongInt);
Var C: Integer; B: LongInt;
Begin
 If FlCycle And (Not CountInOn) And (LocR>LocL) And (NewTick>=LocR) Then Begin
  NewTick:=LocL+(NewTick-LocR);
  PlaySeek(NewTick);
  LastBeat:=(NewTick Div BeatTicks)-1;
 End;
 If (Not Recording) And (Not CountInOn) And (NewTick>=SongLen) Then Begin
  StopPlay;Exit;
 End;
 If NewTick>=0 Then
  B:=NewTick Div BeatTicks
 Else B:=-1-((-NewTick-1) Div BeatTicks);
 If B<>LastBeat Then Begin
  LastBeat:=B;
  If FlClick Then Click;
 End;
 If CountInOn And (NewTick>=PosTick) Then Begin
  CountInOn:=False;
  PlaySeek(PosTick);
 End;
 If Not CountInOn Then
  For C:=1 To 4 Do PlayChain(C,NewTick);
 PlayTick:=NewTick;
 If Recording Then
  If (SongLen<=NewTick) Then SongLen:=NewTick+BarTicks;
End;

Procedure StartPlay(From: LongInt);
Begin
 If Playing Then Exit;
 BuildChains;
 UpdateSolo;
 AllNotesOff;
 FillChar(Snd,SizeOf(Snd),0);
 PosTick:=From;
 CountInOn:=False;
 If Recording And FlCountIn Then Begin
  CountInOn:=True;
  PlayTick:=From-BarTicks;
 End Else PlaySeek(From);
 RemT:=0;LastCs:=NowCs;
 LastBeat:=(PlayTick Div BeatTicks)-1;
 If PlayTick<0 Then LastBeat:=-2;
 If Recording Then SongLen:=Max2(SongLen,From+BarTicks);
 Playing:=True;
 PlayShown:=-1;
 NeedDraw:=True;
End;

Procedure StopPlay;
Var I: Integer; Tr: PTrk;
Begin
 If Not Playing Then Begin
  { 2e arret : retour au locator gauche }
  PosTick:=LocL;
  NeedDraw:=True;
  Exit;
 End;
 Playing:=False;
 If PlayTick>=0 Then PosTick:=PlayTick;
 CountInOn:=False;
 AllNotesOff;
 FillChar(Snd,SizeOf(Snd),0);
 If Recording Then Begin
  Recording:=False;
  Tr:=GetTrk(RecTI);
  If (Tr<>Nil) And (Tr^.Ev<>Nil) Then
   For I:=1 To Tr^.Cnt Do Tr^.Ev^[I].Sel:=False;
  If Not FlAutoDrop Then TakePending:=True;
 End;
 If PosTick>=SongLen Then PosTick:=LocL;
 NeedDraw:=True;
End;

{ ---- enregistrement ---- }

Procedure RecNoteOn(Pitch,Vel: Integer; Len: LongInt);
Var Tr: PTrk; I: Integer;
Begin
 If (Not Playing) Or (Not Recording) Or CountInOn Then Exit;
 If FlPunch And ((PlayTick<LocL) Or (PlayTick>=LocR)) Then Exit;
 If FlFixVel Then Vel:=PenVel;
 I:=AddEv(RecTI,PlayTick,Len,EK_NOTE,Pitch,Vel);
 If I>0 Then Begin
  RecStart[Pitch]:=PlayTick;
  Tr:=GetTrk(RecTI);
  Tr^.Ev^[I].Sel:=True;
  NeedDraw:=True;
 End;
End;

Procedure RecNoteOff(Pitch: Integer);
Var Tr: PTrk; I: Integer; L: LongInt; Fnd: Boolean;
Begin
 If (Not Playing) Or (Not Recording) Then Exit;
 If RecStart[Pitch]<0 Then Exit;
 Tr:=GetTrk(RecTI);
 If Tr^.Ev=Nil Then Exit;
 I:=Tr^.Cnt;Fnd:=False;
 While (I>=1) And Not Fnd Do Begin
  If (Tr^.Ev^[I].Kind=EK_NOTE) And (Tr^.Ev^[I].D1=Pitch)
     And (Tr^.Ev^[I].T=RecStart[Pitch]) Then Begin
   L:=PlayTick-RecStart[Pitch];
   If L<1 Then L:=1;
   Tr^.Ev^[I].Len:=L;
   Fnd:=True;
  End;
  Dec(I);
 End;
 RecStart[Pitch]:=-1;
 NeedDraw:=True;
End;

{ Apercu sonore d'une note (hors lecture) }
Procedure PreviewNote(Pitch,Vel: Integer);
Var Tr: PTrk;
Begin
 Tr:=CT;

 ChanTimbre[Tr^.P.Chan]:=TimbreOf(Tr^.P.Instr);

 SndOn(Tr^.P.Port,Tr^.P.Chan,Pitch,Vel,NowCs+30,True);
End;

Procedure EngineStep;
Var Now1,D,Adv: LongInt; I: Integer;
Begin

 Now1:=NowCs;
 For I:=1 To MAXSND Do
  If Snd[I].Used And Snd[I].UseCs Then
   If Now1>=Snd[I].OffAt Then SndOff(I);
 If Playing Then Begin
  D:=Now1-LastCs;
  If D<0 Then D:=D+8640000;
  If D<0 Then D:=0;
  LastCs:=Now1;
  If D>30 Then D:=30;
  RemT:=RemT+D*(Tempo10k Div 100)*PPQ;
  Adv:=RemT Div 600000;
  RemT:=RemT Mod 600000;
  If Adv>0 Then Begin
   AdvanceTo(PlayTick+Adv);
   If Playing Then
    For I:=1 To MAXSND Do
     If Snd[I].Used And (Not Snd[I].UseCs) Then
      If PlayTick>=Snd[I].OffAt Then SndOff(I);
  End;
 End;
 SpeakerUpdate;
End;

{ Clavier d'ordinateur = clavier musical }
Function PianoKey(K: Word): Integer;
Const
 Low  : String[17] = 'zsxdcvgbhnjm,l.;/';
 Up   : String[17] = 'q2w3er5t6y7ui9o0p';
Var Ch: Char; I: Integer;
Begin
 PianoKey:=-1;
 If K>255 Then Exit;
 Ch:=LowerStr(Chr(K))[1];
 I:=Pos(Ch,Low);
 If I>0 Then Begin PianoKey:=Oct*12+12+I-1;Exit;End;
 I:=Pos(Ch,Up);
 If I>0 Then PianoKey:=Oct*12+24+I-1;
End;

{ ====================================================================== }
{                  GEOMETRIE DES ECRANS / EN-TETE                        }
{ ====================================================================== }

Const
 TB_Y   = 18;
 R1_Y   = 35;
 R1_B   = 63;
 R2_Y   = 65;
 R2_B   = 103;
 R3_Y   = 105;
 R3_B   = 120;
 RL_Y   = 122;
 RL_B   = 134;
 BODY_Y = 136;
 BODY_B = 479;
 PAL_W  = 48;
 HYP_H  = 64;
 NOTEX0 = 126;         { origine du temps dans la partition }
 SCX2   = 620;
 NFLT   = 8;
 FltName : Array[1..NFLT] Of String[8] =
  ('NOTE','CONTROL','PROGRAM','PITCH W.','C-PRESS','P-PRESS','SYMBOL','TEXT');
 FltKind : Array[1..NFLT] Of Byte =
  (EK_NOTE,EK_CTRL,EK_PROG,EK_BEND,EK_CHANP,EK_POLYP,EK_SYM,EK_TEXT);

Var
 ViewBar   : LongInt;                { premiere mesure visible (0..) }
 TimeX0    : Integer;                { x de l'origine du temps }
 UseStretch: Boolean;                { ajustement aux paroles }
 TrkTop    : Integer;                { premiere piste affichee }
 Tool      : Integer;                { outil de palette }
 CurEv     : Integer;                { evenement courant (piste courante) }
 ListTop   : Integer;
 HyperKind : Integer;                { 0 vel,1 vol,2 pan,3 mod,4 expr,5 bend }
 ShowHyper : Boolean;
 Flt       : Array[1..NFLT] Of Boolean;
 FltOn     : Boolean;
 FltTop    : Integer;
 Catch     : Boolean;
 VT        : Array[1..TPP] Of Integer;
 VN        : Integer;
 MatTop    : Integer;                { hauteur de la rangee du haut (matrice) }
 LastRuler : Integer;
 { ajustement aux paroles }
 StrN      : Integer;
 StrT      : Array[1..NLYR] Of LongInt;
 StrX      : Array[1..NLYR] Of Integer;  { decalage cumule apres ce tick }

Function PxQ: Integer;
Begin
 PxQ:=10+8*ZoomX;
End;

Function StretchAt(T: LongInt): Integer;
Var I,S: Integer;
Begin
 S:=0;
 If UseStretch Then
  For I:=1 To StrN Do
   If StrT[I]<T Then S:=StrX[I];
 StretchAt:=S;
End;

Function XOfTick(T: LongInt): Integer;
Var Org,V: LongInt;
Begin
 Org:=ViewBar*BarTicks;
 V:=TimeX0+((T-Org)*PxQ) Div PPQ+StretchAt(T);
 XOfTick:=Integer(Clamp(V,-30000,30000));
End;

Function TickOfX(X: Integer): LongInt;
Var Lo,Hi,Mid,I: LongInt;
Begin
 Lo:=ViewBar*BarTicks-BarTicks;Hi:=Lo+BarTicks*40;
 For I:=1 To 26 Do Begin
  Mid:=(Lo+Hi) Div 2;
  If XOfTick(Mid)<X Then Lo:=Mid Else Hi:=Mid;
 End;
 If Lo<0 Then Lo:=0;
 TickOfX:=Lo;
End;

{ nombre de pixels d'une mesure }
Function BarPx: Integer;
Begin
 BarPx:=Integer((BarTicks*PxQ) Div PPQ);
End;

{ construit la liste des pistes visibles }
Procedure BuildVT;
Var T,I: Integer; P: PTrk; Found: Boolean;
Begin
 VN:=0;
 For T:=1 To TPP Do Begin
  P:=Trks[TI(CurPat,T)];
  If (P<>Nil) And P^.Sel Then Begin Inc(VN);VT[VN]:=T;End;
 End;
 Found:=False;
 For I:=1 To VN Do If VT[I]=CurTrk Then Found:=True;
 If (VN=0) Or (Not Found And (VN=0)) Then Begin VN:=1;VT[1]:=CurTrk;End;
 If TrkTop>VN Then TrkTop:=VN;
 If TrkTop<1 Then TrkTop:=1;
End;

Function ScoreTop: Integer;
Begin
 If ShowHyper Then ScoreTop:=BODY_Y+HYP_H+8 Else ScoreTop:=BODY_Y+8;
End;

Function TrkSp: Integer;
Begin
 TrkSp:=52+ZoomY*2;
End;

Function VisTrk: Integer;
Begin
 VisTrk:=Integer(Max2(1,(BODY_B-ScoreTop) Div TrkSp));
End;

{ ====================================================================== }
{                     EN-TETE : BARRE DE TITRE, TRANSPORT                }
{ ====================================================================== }

Procedure Cell(X1,Y1,X2,Y2: Integer; Const Val,Lbl: String; Inv: Boolean);
Begin
 If Inv Then Box(X1,Y1,X2,Y2,INK) Else Begin
  Box(X1,Y1,X2,Y2,PAPER);Frame(X1,Y1,X2,Y2);End;
 If Lbl<>'' Then Begin
  If Inv Then WText((X1+X2+1-TextW(Lbl)) Div 2,Y2-9,Lbl)
  Else PText((X1+X2+1-TextW(Lbl)) Div 2,Y2-9,Lbl);
 End;
 If Inv Then WText((X1+X2+1-TextW(Val)) Div 2,Y1+4,Val)
 Else BText((X1+X2+1-TextW(Val)) Div 2,Y1+4,Val);
End;

Function SyncLbl: String;
Begin
 Case SyncMode Of
  1: SyncLbl:='MIDI';
  2: SyncLbl:='SMPTE';
 Else SyncLbl:='intern';
 End;
End;

Function TempoStr: String;
Var S: String;
Begin
 S:=IntStr(Tempo10k Div 10000)+'.'+Copy(IntStr(10000+(Tempo10k Mod 10000)),2,4);
 TempoStr:=S;
End;

Function DosQuerySysInfo(IStart,ILast,PBuf,CbBuf: LongInt): LongInt; External 'DOSCALLS';

{ memoire libre (QSV_TOTAVAILMEM) en Ko : la cellule FREE de la version
  DOS montrait MemAvail en octets (au plus 640 Ko) }
Function MemFree: LongInt;
Var L: LongInt;
Begin
 L:=0;
 If DosQuerySysInfo(19,19,LongInt(@L),4)<>0 Then L:=0;
 L:=L Div 1024;
 If L<0 Then L:=0;
 If L>999999 Then L:=999999;
 MemFree:=L;
End;

Procedure DrawPosCells;
Var B,Bt,Sx,Tk,Ms,Mn,Sc: LongInt; T: LongInt; S: String;
Begin
 T:=CurPos;
 TickToBBT(T,B,Bt,Sx,Tk);
 Ms:=TickMs(Max2(0,T));
 Mn:=Ms Div 60000;Sc:=(Ms Mod 60000) Div 1000;Ms:=Ms Mod 1000;
 S:=Pad2(Mn)+' '+Pad2(Sc)+'.'+Copy(IntStr(1000+Ms),2,3);
 Cell(433,R1_Y,516,R1_B,S,'min sec ms',False);
 Box(518,R1_Y,637,R1_B,INK);
 WText(524,R1_Y+4,PadL(IntStr(B),3)+PadL(IntStr(Bt),3)+PadL(IntStr(Sx),3)+
   PadL(IntStr(Tk),3));
 WText(524,R1_B-9,'BAR/'+IntStr(SigD)+' 16 '+IntStr(PPQ*2));
 PlayShown:=T;
End;

{ la barre de titre GEM de la version DOS devient le titre de la fenetre
  de PM : nom du morceau (* s'il est modifie) }
Procedure DrawTitleBar;
Var S: String;
Begin
 S:=ShortName(SongName);
 If Modified Then S:=S+'*';
 S:='Notator for OS2-Zero - '+S;
 If (S<>LastTitle) And (HFrame<>0) Then Begin
  LastTitle:=S;
  Dummy:=WinSetWindowText(HFrame,Z(S));
 End;
End;

Procedure DrawTransport;
Var S: String;
Begin
 Cell(0,R1_Y,55,R1_B,IntStr(MemFree),'FREE',False);
 If FlArrange Then S:='ARR' Else S:='--';
 Cell(57,R1_Y,115,R1_B,S,'ARRANGE',False);
 Cell(117,R1_Y,175,R1_B,IntStr(SyncDel),'SyncDEL',False);
 Cell(177,R1_Y,232,R1_B,SyncLbl,'SYNC',False);
 Cell(234,R1_Y,303,R1_B,TempoStr,'TEMPO',False);
 Cell(305,R1_Y,356,R1_B,QuaLbl[FmtQ],'FORMAT',False);
 Cell(358,R1_Y,431,R1_B,IntStr(SigN)+'/'+IntStr(SigD),'SIGNATURE',False);
 DrawPosCells;
End;

{ Descriptions d'evenement }
Function EvStatus(Var E: TEvt): String;
Begin
 Case E.Kind Of
  EK_NOTE: EvStatus:='NOTE';
  EK_CTRL: EvStatus:='Control '+IntStr(E.D1);
  EK_PROG: EvStatus:='Program';
  EK_BEND: EvStatus:='Pitch W.';
  EK_CHANP: EvStatus:='C-Press';
  EK_POLYP: EvStatus:='P-Press';
  EK_SYM: EvStatus:='Symbol';
  EK_TEXT: Case E.D2 Of
            0: EvStatus:='Lyric';
            1: EvStatus:='Text';
           Else EvStatus:='Chord';
           End;
 Else EvStatus:='?';
 End;
End;

Function EvData(Var E: TEvt): String;
Begin
 Case E.Kind Of
  EK_NOTE: EvData:=PadL(NoteName(E.D1),4)+PadL(IntStr(E.D2),5)+
                    PadL(IntStr(E.Len),6);
  EK_CTRL: EvData:=PadL(IntStr(E.D2),9);
  EK_PROG: EvData:=PadL(IntStr(E.D1),9);
  EK_BEND: EvData:=PadL(IntStr(E.D2*128+E.D1-8192),9);
  EK_CHANP: EvData:=PadL(IntStr(E.D1),9);
  EK_POLYP: EvData:=PadL(NoteName(E.D1),4)+PadL(IntStr(E.D2),5);
  EK_SYM: EvData:=PadL(IntStr(E.D1),9);
  EK_TEXT: If (E.Sty>=1) And (E.Sty<=NLYR) Then EvData:=' '+TxtPool[E.Sty]
           Else EvData:='';
 Else EvData:='';
 End;
End;

Function Passes(Var E: TEvt): Boolean;
Var I: Integer;
Begin
 Passes:=True;
 If Not FltOn Then Exit;
 For I:=1 To NFLT Do
  If FltKind[I]=E.Kind Then Passes:=Flt[I];
End;

{ Evenement filtre suivant/precedent }
Function NextFlt(Tr: PTrk; From,Dir: Integer): Integer;
Var I: Integer;
Begin
 NextFlt:=0;
 If Tr^.Ev=Nil Then Exit;
 I:=From+Dir;
 While (I>=1) And (I<=Tr^.Cnt) Do Begin
  If Passes(Tr^.Ev^[I]) Then Begin NextFlt:=I;Exit;End;
  I:=I+Dir;
 End;
End;

Procedure DrawEventRow;
Var I,Y,X,K,J: Integer; Tr: PTrk; Ix: Array[1..3] Of Integer; S: String;
Begin
 Box(0,R2_Y,SCR_W-1,R2_B,PAPER);
 { ON / OFF }
 If FltOn Then Begin
  Box(0,R2_Y,37,R2_Y+13,INK);WText(10,R2_Y+4,'ON');
  Box(38,R2_Y,75,R2_Y+13,PAPER);Frame(38,R2_Y,75,R2_Y+13);PText(46,R2_Y+4,'OFF');
 End Else Begin
  Box(0,R2_Y,37,R2_Y+13,PAPER);Frame(0,R2_Y,37,R2_Y+13);PText(10,R2_Y+4,'ON');
  Box(38,R2_Y,75,R2_Y+13,INK);WText(46,R2_Y+4,'OFF');
 End;
 { liste des filtres }
 Frame(0,R2_Y+14,75,R2_B);
 For I:=0 To 2 Do Begin
  K:=FltTop+I;
  If K<=NFLT Then Begin
   Y:=R2_Y+15+I*8;
   If Flt[K] Then Begin
    Box(1,Y,66,Y+7,INK);
    SetColor(PAPER);OutTextXY(2,Y,FltName[K]);
   End Else PText(2,Y,FltName[K]);
  End;
 End;
 ArrowBox(67,R2_Y+15,74,R2_Y+24,1);
 ArrowBox(67,R2_Y+26,74,R2_Y+35,2);
 { liste d'evenements }
 Frame(78,R2_Y,SCR_W-50,R2_B);
 Tr:=CT;
 If (Tr<>Nil) And (Tr^.Ev<>Nil) And (Tr^.Cnt>0) Then Begin
  If CurEv<1 Then CurEv:=1;
  If CurEv>Tr^.Cnt Then CurEv:=Tr^.Cnt;
  Ix[2]:=CurEv;
  Ix[1]:=NextFlt(Tr,CurEv,-1);
  Ix[3]:=NextFlt(Tr,CurEv,1);
  For J:=1 To 3 Do
   If Ix[J]>0 Then Begin
    Y:=R2_Y+3+(J-1)*11;
    If J=2 Then Box(80,Y-1,SCR_W-52,Y+9,INK);
    S:=PosStr(Tr^.Ev^[Ix[J]].T);
    X:=84;
    If J=2 Then Begin
     WText(X,Y,PadL(S,12));
     WText(X+110,Y,PadL(EvStatus(Tr^.Ev^[Ix[J]]),10));
     WText(X+200,Y,EvData(Tr^.Ev^[Ix[J]]));
    End Else Begin
     PText(X,Y,PadL(S,12));
     PText(X+110,Y,PadL(EvStatus(Tr^.Ev^[Ix[J]]),10));
     PText(X+200,Y,EvData(Tr^.Ev^[Ix[J]]));
    End;
   End;
 End Else PText(84,R2_Y+14,T3('(no events)','(aucun '#130'v'#130'nement)',
   '(keine Ereignisse)'));
 { CATCH }
 Box(SCR_W-48,R2_Y,SCR_W-2,R2_Y+16,PAPER);Frame(SCR_W-48,R2_Y,SCR_W-2,R2_Y+16);
 If Catch Then Begin Box(SCR_W-47,R2_Y+1,SCR_W-3,R2_Y+15,INK);
  WText(SCR_W-42,R2_Y+5,'CATCH');End
 Else PText(SCR_W-42,R2_Y+5,'CATCH');
End;

Procedure SetCell(X1,X2: Integer; Const Lbl: String; V: Integer);
Begin
 Box(X1,R3_Y,X2,R3_B,PAPER);
 PText(X1+3,R3_Y+5,Lbl);
 BText(X1+3+TextW(Lbl)+4,R3_Y+4,IntStr(V));
End;

Procedure FlagCell(X1,X2: Integer; Const Lbl: String; On: Boolean);
Begin
 Box(X1,R3_Y,X2,R3_B,PAPER);
 If On Then BText(X1+2,R3_Y+4,#251);
 PText(X1+13,R3_Y+5,Lbl);
End;

Procedure DrawSetRow;
Begin
 Box(0,R3_Y,SCR_W-1,R3_B,PAPER);
 SetColor(INK);
 Line(0,R3_Y,SCR_W-1,R3_Y);
 Line(0,R3_B,SCR_W-1,R3_B);
 SetCell(0,52,'SET',SetNo);
 SetCell(54,118,'Zoom'+#26,ZoomX);
 SetCell(120,184,'Zoom'+#25,ZoomY);
 SetCell(186,250,'PEN',PenVel);
 SetCell(252,318,'COLOR',ColorNo);
 FlagCell(320,396,'AutoIns',FlAutoIns);
 FlagCell(398,462,'FixVel',FlFixVel);
 FlagCell(464,532,'AllCha',FlAllCha);
 FlagCell(534,SCR_W-1,'LockScore',FlLockScore);
End;

{ Regle des mesures }
Procedure DrawRuler(NameW: Integer);
Var B,X,N: LongInt; Bt: Integer; T: LongInt;
Begin
 Box(0,RL_Y,SCR_W-1,RL_B,PAPER);
 SetColor(INK);
 Line(0,RL_Y,SCR_W-1,RL_Y);
 Line(0,RL_B,SCR_W-1,RL_B);
 Frame(0,RL_Y,NameW-2,RL_B);
 If NameW<150 Then PText(Max2(2,(NameW-56) Div 2),RL_Y+3,'N A M E');
 N:=ViewBar;
 While True Do Begin
  X:=XOfTick(N*BarTicks);
  If X>SCX2 Then Begin LastRuler:=Integer(X);Exit;End;
  If X>=TimeX0 Then Begin
   Line(X,RL_Y,X,RL_B);
   PText(X+3,RL_Y+3,IntStr(N+1));
  End;
  For Bt:=1 To SigN-1 Do Begin
   T:=N*BarTicks+Bt*BeatTicks;
   X:=XOfTick(T);
   If (X>=TimeX0) And (X<=SCX2) Then Line(X,RL_B-3,X,RL_B);
  End;
  Inc(N);
 End;
End;

{ Marqueurs de locators et position sur la regle }
Procedure DrawMarkers;
Var X: Integer; Pt: Array[1..3] Of PointType;
Begin
 X:=XOfTick(LocL);
 If (X>=TimeX0) And (X<=SCX2) Then Begin
  SetColor(INK);Line(X,RL_Y+1,X,RL_B-1);Line(X+1,RL_Y+1,X+4,RL_Y+1);
 End;
 X:=XOfTick(LocR);
 If (X>=TimeX0) And (X<=SCX2) Then Begin
  SetColor(INK);Line(X,RL_Y+1,X,RL_B-1);Line(X-4,RL_Y+1,X,RL_Y+1);
 End;
 X:=XOfTick(CurPos);
 If (X>=TimeX0) And (X<=SCX2) Then Begin
  Pt[1].X:=X-3;Pt[1].Y:=RL_B-6;Pt[2].X:=X+3;Pt[2].Y:=RL_B-6;
  Pt[3].X:=X;Pt[3].Y:=RL_B;
  SetFillStyle(SolidFill,INK);SetColor(INK);
  FillPoly(3,Pt);
 End;
End;

{ ====================================================================== }
{                  NOTATION : GLYPHES ET RENDU DES PORTEES               }
{ ====================================================================== }

Const
 DBot : Array[0..3] Of Integer = (37,25,31,29);   { diatonique ligne du bas }
 StepS : Array[0..11] Of Byte = (0,0,1,1,2,3,3,4,4,5,5,6);
 AccS  : Array[0..11] Of Byte = (0,1,0,1,0,0,1,0,1,0,1,0);
 StepF : Array[0..11] Of Byte = (0,1,1,2,2,3,4,4,5,5,6,6);
 AccF  : Array[0..11] Of Byte = (0,2,0,2,0,0,2,0,2,0,2,0);
 SharpOrd : Array[1..7] Of Byte = (3,0,4,1,5,2,6);
 FlatOrd  : Array[1..7] Of Byte = (6,2,5,1,4,0,3);
 SharpPos : Array[1..7] Of Byte = (8,5,9,6,3,7,4);
 FlatPos  : Array[1..7] Of Byte = (4,7,3,6,2,5,1);
 Seg7 : Array[0..9] Of String[7] =
  ('abcdef','bc','abdeg','abcdg','bcfg','acdfg','acdefg','abc','abcdefg',
   'abcdfg');
 SymTxt : Array[1..NSYM] Of String[5] =
  ('pp','p','mp','mf','f','ff','<','>','fer','.','>','slur','tr','Ped');

Type
 TDN = Record
  Te,Dur : LongInt;
  Pitch,Typ,Dot,Trip,Ev : Integer;
  Tie,Sel : Boolean;
  Sty : Byte;
 End;

Var
 NtLen : Array[1..40] Of LongInt;
 NtTyp,NtDot,NtTrip : Array[1..40] Of Integer;
 NtN   : Integer;
 NtPPQ : Integer;
 DN    : Array[1..MAXDN] Of TDN;
 DNN   : Integer;
 GS,GC,GDir,GTop,GBot,GEnd,GX : Array[1..MAXDN] Of Integer;
 GTyp,GDot,GTrip : Array[1..MAXDN] Of Integer;
 GTe,GDur : Array[1..MAXDN] Of LongInt;
 GN    : Integer;
 KeyAcc: Array[0..6] Of Byte;
 StrW  : Array[1..NLYR] Of Integer;
 PlayX : Integer;                { x de la tete de lecture (XOR) }

Procedure BuildNt;
Var T,N,I,J: Integer; B: LongInt;
 L,Tp,Dt,Tr: LongInt;
Begin
 N:=0;
 For T:=0 To 6 Do Begin
  B:=(LongInt(PPQ)*4) Shr T;
  Inc(N);NtLen[N]:=B;NtTyp[N]:=T;NtDot[N]:=0;NtTrip[N]:=0;
  If T<=5 Then Begin
   Inc(N);NtLen[N]:=B*3 Div 2;NtTyp[N]:=T;NtDot[N]:=1;NtTrip[N]:=0;End;
  If (T>=1) And (T<=5) Then Begin
   Inc(N);NtLen[N]:=B*2 Div 3;NtTyp[N]:=T;NtDot[N]:=0;NtTrip[N]:=1;End;
 End;
 For I:=2 To N Do Begin
  L:=NtLen[I];Tp:=NtTyp[I];Dt:=NtDot[I];Tr:=NtTrip[I];
  J:=I-1;
  While (J>=1) And (NtLen[J]<L) Do Begin
   NtLen[J+1]:=NtLen[J];NtTyp[J+1]:=NtTyp[J];NtDot[J+1]:=NtDot[J];
   NtTrip[J+1]:=NtTrip[J];
   Dec(J);
  End;
  NtLen[J+1]:=L;NtTyp[J+1]:=Tp;NtDot[J+1]:=Dt;NtTrip[J+1]:=Tr;
 End;
 NtN:=N;NtPPQ:=PPQ;
End;

{ plus grande duree notable <= D }
Function Notate(D: LongInt; AllowTrip: Boolean; Var Typ,Dot,Trip: Integer): LongInt;
Var I: Integer;
Begin
 If NtPPQ<>PPQ Then BuildNt;
 I:=1;
 While (I<NtN) And ((NtLen[I]>D) Or ((NtTrip[I]=1) And Not AllowTrip)) Do Inc(I);
 Typ:=NtTyp[I];Dot:=NtDot[I];Trip:=NtTrip[I];
 Notate:=NtLen[I];
End;

Procedure SetKeyAcc;
Var I: Integer;
Begin
 For I:=0 To 6 Do KeyAcc[I]:=0;
 If KeyS>0 Then For I:=1 To KeyS Do KeyAcc[SharpOrd[I]]:=1;
 If KeyS<0 Then For I:=1 To -KeyS Do KeyAcc[FlatOrd[I]]:=2;
End;

{ Epelle une hauteur : D = numero diatonique, Acc a afficher (0 rien,1 #,2 b,3 becarre) }
Procedure Spell(N: Integer; Var D,Acc: Integer);
Var Pc,St,Ac: Integer;
Begin
 Pc:=N Mod 12;
 If KeyS>=0 Then Begin St:=StepS[Pc];Ac:=AccS[Pc];End
 Else Begin St:=StepF[Pc];Ac:=AccF[Pc];End;
 D:=(N Div 12)*7+St;
 Acc:=0;
 If Ac<>KeyAcc[St] Then Begin
  If Ac=0 Then Acc:=3 Else Acc:=Ac;
 End;
End;

{ ---- petits glyphes ---- }

Const
 Strokes : Array[0..9] Of String[40] =
  ('', '22 40 4A | 1A 7A', '03 11 30 51 63 0A 6A',
   '01 20 50 62 54 25 56 68 5A 2A 09', '50 07 67 | 50 5A',
   '60 10 05 44 66 68 4A 09', '50 21 05 08 2A 5A 68 56 26 07',
   '00 60 2A', '', '1A 49 65 62 40 10 02 14 44 63');

Function SCh(Const S: String; I: Integer): Integer;
Begin
 If (I<1) Or (I>Length(S)) Then SCh:=0
 Else If S[I]>='A' Then SCh:=Ord(S[I])-55
 Else SCh:=Ord(S[I])-48;
End;

{ chiffre en traits (grille 6 x 10) }
Procedure Digit7(X,Y,Dg,W,H: Integer);
Var S: String; I,X1,Y1,X2,Y2,K: Integer; Pen: Boolean;
Begin
 SetColor(INK);SetLineStyle(SolidLn,0,1);
 If Dg=0 Then Begin
  Ellipse(X+3,Y+5,0,360,3,5);Ellipse(X+4,Y+5,0,360,3,5);Exit;End;
 If Dg=8 Then Begin
  Ellipse(X+3,Y+2,0,360,3,2);Ellipse(X+3,Y+7,0,360,3,3);
  Ellipse(X+4,Y+2,0,360,3,2);Ellipse(X+4,Y+7,0,360,3,3);Exit;End;
 S:=Strokes[Dg];
 Pen:=False;X1:=0;Y1:=0;
 I:=1;
 While I<=Length(S) Do Begin
  If S[I]='|' Then Begin Pen:=False;Inc(I);End
  Else If S[I]=' ' Then Inc(I)
  Else Begin
   X2:=X+SCh(S,I);Y2:=Y+SCh(S,I+1);
   If Pen Then Begin Line(X1,Y1,X2,Y2);Line(X1+1,Y1,X2+1,Y2);End;
   X1:=X2;Y1:=Y2;Pen:=True;
   I:=I+2;
  End;
 End;
 K:=W+H;
End;

Procedure BigNum(X,Y,N: Integer);
Var S: String; I: Integer;
Begin
 S:=IntStr(N);
 For I:=1 To Length(S) Do Digit7(X+(I-1)*9,Y,Ord(S[I])-48,6,10);
End;

Procedure DrawAcc(X,Y,A: Integer);
Begin
 SetColor(INK);SetLineStyle(SolidLn,0,1);
 Case A Of
  1: Begin
      Line(X-2,Y-5,X-2,Y+6);Line(X+2,Y-6,X+2,Y+5);
      Line(X-4,Y-1,X+4,Y-3);Line(X-4,Y+3,X+4,Y+1);
     End;
  2: Begin
      Line(X-2,Y-8,X-2,Y+3);Line(X-2,Y+3,X+2,Y);Line(X+2,Y,X+3,Y-2);
      Line(X+3,Y-2,X+1,Y-4);Line(X+1,Y-4,X-2,Y-2);
     End;
  3: Begin
      Line(X-2,Y-6,X-2,Y+2);Line(X+2,Y-2,X+2,Y+6);
      Line(X-2,Y-1,X+2,Y-3);Line(X-2,Y+3,X+2,Y+1);
     End;
 End;
End;

Procedure DrawHead(X,Y,Typ,Sty: Integer; Sel: Boolean);
Var Pt: Array[1..4] Of PointType;
Begin
 SetColor(INK);SetLineStyle(SolidLn,0,1);
 SetFillStyle(SolidFill,INK);
 Case Sty Of
  1: Begin
      Pt[1].X:=X;Pt[1].Y:=Y-4;Pt[2].X:=X+4;Pt[2].Y:=Y;
      Pt[3].X:=X;Pt[3].Y:=Y+4;Pt[4].X:=X-4;Pt[4].Y:=Y;
      If Typ>=2 Then FillPoly(4,Pt) Else Begin
       Line(X,Y-4,X+4,Y);Line(X+4,Y,X,Y+4);Line(X,Y+4,X-4,Y);Line(X-4,Y,X,Y-4);
      End;
     End;
  2: Begin
      Line(X-4,Y-3,X+4,Y+3);Line(X-4,Y+3,X+4,Y-3);
      Line(X-4,Y-2,X+4,Y+4);Line(X-4,Y+2,X+4,Y-4);
     End;
  3: Begin
      Pt[1].X:=X-4;Pt[1].Y:=Y+3;Pt[2].X:=X+4;Pt[2].Y:=Y+3;
      Pt[3].X:=X;Pt[3].Y:=Y-4;
      If Typ>=2 Then FillPoly(3,Pt) Else Begin
       Line(X-4,Y+3,X+4,Y+3);Line(X+4,Y+3,X,Y-4);Line(X,Y-4,X-4,Y+3);End;
     End;
  4: Begin
      Line(X-4,Y+4,X+4,Y-4);Line(X-3,Y+4,X+5,Y-4);
     End;
 Else
  If Typ>=2 Then FillEllipse(X,Y,4,3)
  Else Begin
   Ellipse(X,Y,0,360,5,3);Ellipse(X,Y,0,360,4,3);
   If Typ=0 Then Ellipse(X,Y,0,360,2,3) Else Ellipse(X,Y,0,360,3,2);
  End;
 End;
 If Sel Then Frame(X-7,Y-6,X+7,Y+6);
End;

Procedure DrawLedger(X,Pos,YB: Integer);
Var P: Integer;
Begin
 SetColor(INK);
 If Pos<0 Then Begin
  P:=-2;
  While P>=Pos Do Begin Line(X-7,YB-P*3,X+7,YB-P*3);P:=P-2;End;
 End;
 If Pos>8 Then Begin
  P:=10;
  While P<=Pos Do Begin Line(X-7,YB-P*3,X+7,YB-P*3);P:=P+2;End;
 End;
End;

Procedure DrawRest(X,YT,Typ,Dot: Integer);
Var I: Integer;
Begin
 SetColor(INK);SetFillStyle(SolidFill,INK);
 Case Typ Of
  0: Bar(X-4,YT+6,X+4,YT+9);
  1: Bar(X-4,YT+9,X+4,YT+12);
  2: Begin
      Line(X-1,YT+5,X+2,YT+9);Line(X+2,YT+9,X-2,YT+13);
      Line(X-2,YT+13,X+2,YT+17);Line(X+2,YT+17,X,YT+19);
      Line(X,YT+19,X-2,YT+17);
     End;
 Else
  Begin
   For I:=0 To Typ-3 Do Begin
    FillEllipse(X-2,YT+8+I*4,2,2);
    Line(X+2,YT+7+I*4,X-2,YT+13+I*4);
   End;
   Line(X+2,YT+7,X-2+(Typ-3)*0,YT+13+(Typ-3)*4);
  End;
 End;
 If Dot=1 Then FillEllipse(X+7,YT+10,1,1);
End;

Procedure DrawClef(X,YT,Clef: Integer);
Var YB: Integer;
Begin
 YB:=YT+24;
 SetColor(INK);SetLineStyle(SolidLn,0,1);SetFillStyle(SolidFill,INK);
 Case Clef Of
  1: Begin
      FillEllipse(X+3,YT+6,3,3);
      Ellipse(X+6,YT+7,0,150,7,7);
      Ellipse(X+6,YT+7,0,150,6,7);
      Line(X-1,YT+6,X+4,YT+12);Line(X+4,YT+12,X+8,YT+22);
      FillEllipse(X+14,YT+3,1,1);FillEllipse(X+14,YT+9,1,1);
     End;
  2,3: Begin
      Bar(X,YT,X+2,YB);Line(X+4,YT,X+4,YB);
      If Clef=2 Then Begin
       Ellipse(X+7,YT+6,270,90,5,5);Ellipse(X+7,YT+18,270,90,5,5);
       Line(X+8,YT+10,X+8,YT+14);
      End Else Begin
       Ellipse(X+7,YT+3,270,90,5,5);Ellipse(X+7,YT+9,270,90,5,5);
       Line(X+8,YT+7,X+8,YT+9);
      End;
     End;
 Else
  Begin
   Line(X+5,YT-5,X+5,YB+7);Line(X+6,YT-5,X+6,YB+7);
   Ellipse(X+5,YB-7,0,360,6,6);
   Ellipse(X+5,YT+2,60,360,4,5);
   Arc(X+2,YB+7,180,360,3);
   FillEllipse(X+4,YB-5,1,1);
  End;
 End;
End;

{ ---- collecte des notes visibles pour une piste ---- }
Procedure SortDN;
Var I,J: Integer; X: TDN;
Begin
 For I:=2 To DNN Do Begin
  X:=DN[I];J:=I-1;
  While (J>=1) And ((DN[J].Te>X.Te) Or ((DN[J].Te=X.Te) And
     ((DN[J].Dur<X.Dur) Or ((DN[J].Dur=X.Dur) And (DN[J].Pitch>X.Pitch))))) Do Begin
   DN[J+1]:=DN[J];Dec(J);
  End;
  DN[J+1]:=X;
 End;
End;

Procedure GatherNotes(Tr: PTrk; T0,T1: LongInt);
Var I,J,Typ,Dot,Trip: Integer; Te,L,G,Nx,T,Rem,BE,Seg,Pc: LongInt; Q: LongInt;
 Done,HaveNx: Boolean; Rq,BE0: LongInt;
Begin
 DNN:=0;
 If Tr^.Ev=Nil Then Exit;
 Q:=QuaTicks(Tr^.P.Qua);
 If Q=0 Then Q:=QuaTicks(FmtQ);
 G:=Q;
 For I:=1 To Tr^.Cnt Do
  If (Tr^.Ev^[I].Kind=EK_NOTE) And (DNN<MAXDN-4) Then Begin
   Te:=DispT(Tr,Tr^.Ev^[I].T);
   If Te<T1 Then Begin
    L:=Tr^.Ev^[I].Len;
    If G>0 Then Begin L:=((L+G Div 2) Div G)*G;If L<G Then L:=G;End;
    If L<1 Then L:=1;
    { limite par le prochain depart }
    J:=I+1;Done:=False;HaveNx:=False;Nx:=0;
    While (J<=Tr^.Cnt) And Not Done Do Begin
     If Tr^.Ev^[J].Kind=EK_NOTE Then Begin
      Nx:=DispT(Tr,Tr^.Ev^[J].T);
      If Nx>Te Then Begin
       If Te+L>Nx Then L:=Nx-Te;
       HaveNx:=True;Done:=True;
      End;
     End;
     Inc(J);
    End;
    Rq:=QuaTicks(RestQ);
    If Rq>0 Then Begin
     If HaveNx Then Begin
      If (Nx-(Te+L)>0) And (Nx-(Te+L)<Rq) Then L:=Nx-Te;
     End Else Begin
      BE0:=(Te Div BarTicks+1)*BarTicks;
      If (BE0-(Te+L)>0) And (BE0-(Te+L)<Rq) Then L:=BE0-Te;
     End;
    End;
    If Te+L>T0 Then Begin
     T:=Te;Rem:=L;
     While (Rem>0) And (DNN<MAXDN) Do Begin
      BE:=(T Div BarTicks+1)*BarTicks;
      Seg:=Rem;If Seg>BE-T Then Seg:=BE-T;
      Pc:=Notate(Seg,(Seg Mod (PPQ Div 4))<>0,Typ,Dot,Trip);
      If Pc>Seg Then Pc:=Seg;
      Inc(DNN);
      DN[DNN].Te:=T;DN[DNN].Dur:=Pc;DN[DNN].Pitch:=Tr^.Ev^[I].D1;
      DN[DNN].Typ:=Typ;DN[DNN].Dot:=Dot;DN[DNN].Trip:=Trip;DN[DNN].Ev:=I;
      DN[DNN].Tie:=(Rem-Pc>0);DN[DNN].Sel:=Tr^.Ev^[I].Sel;
      DN[DNN].Sty:=Tr^.Ev^[I].Sty;
      T:=T+Pc;Rem:=Rem-Pc;
      If Pc<=0 Then Rem:=0;
     End;
    End;
   End;
  End;
 SortDN;
End;

Function PosOf(Pitch,Clef: Integer; Var Acc: Integer): Integer;
Var D: Integer;
Begin
 Spell(Pitch,D,Acc);
 PosOf:=D-DBot[Clef];
End;

Function BeamUnit: LongInt;
Begin
 If (SigD=8) And (SigN Mod 3=0) Then BeamUnit:=LongInt(PPQ)*3 Div 2
 Else BeamUnit:=PPQ;
End;

{ Fond de portee, cle, armure, chiffrage, barres }
Procedure DrawStaffBase(YT: Integer; Tr: PTrk; Idx: Integer);
Var I,X,K,Pos: Integer; B: LongInt;
Begin
 SetColor(INK);SetLineStyle(SolidLn,0,1);
 For I:=0 To 4 Do Line(PAL_W+4,YT+I*6,SCX2,YT+I*6);
 { accolade }
 Line(PAL_W+3,YT,PAL_W+3,YT+24);Line(PAL_W+2,YT,PAL_W+2,YT+24);
 DrawClef(PAL_W+8,YT,Tr^.P.Clef);
 X:=PAL_W+30;
 If KeyS>0 Then
  For K:=1 To KeyS Do Begin
   Pos:=SharpPos[K];
   Case Tr^.P.Clef Of 1: Pos:=Pos-2;2: Pos:=Pos-1;3: Pos:=Pos+1;End;
   DrawAcc(X+(K-1)*5,YT+24-Pos*3,1);
  End;
 If KeyS<0 Then
  For K:=1 To -KeyS Do Begin
   Pos:=FlatPos[K];
   Case Tr^.P.Clef Of 1: Pos:=Pos-2;2: Pos:=Pos-1;3: Pos:=Pos+1;End;
   If Pos<0 Then Pos:=Pos+7;
   DrawAcc(X+(K-1)*5,YT+24-Pos*3,2);
  End;
 X:=PAL_W+30+7*5+4;
 BigNum(X,YT,SigN);
 BigNum(X,YT+13,SigD);
 { nom de piste }
 PText(PAL_W+6,YT-13,Copy(TrkName(Idx),1,10));
 PText(PAL_W+6+88,YT-13,Copy(Tr^.P.Instr,1,10)+' '+PortCh(Tr));
 { barres de mesure }
 B:=ViewBar;
 While True Do Begin
  X:=XOfTick(B*BarTicks);
  If X>SCX2 Then Exit;
  If B>=Pats[CurPat].Len Then Begin
   If X>=NOTEX0-6 Then Begin
    Line(X,YT,X,YT+24);Bar(X+2,YT,X+3,YT+24);End;
   Exit;
  End;
  If (X>=NOTEX0-6) Then Line(X,YT,X,YT+24);
  Inc(B);
 End;
End;

Procedure DrawSym(Var E: TEvt; YT: Integer; Tr: PTrk);
Var X,X2,Y: Integer; S: String;
Begin
 X:=XOfTick(DispT(Tr,E.T));
 If (X<NOTEX0-6) Or (X>SCX2) Then Exit;
 X2:=XOfTick(DispT(Tr,E.T)+E.Len);
 If X2<X+16 Then X2:=X+16;
 If X2>SCX2 Then X2:=SCX2;
 SetColor(INK);SetLineStyle(SolidLn,0,1);
 S:=SymTxt[Clamp(E.D1,1,NSYM)];
 If E.Sel Then Frame(X-3,YT+28,X+Length(S)*8+3,YT+40);
 Case E.D1 Of
  1..6: Begin BText(X,YT+31,S);End;
  7: Begin Line(X,YT+36,X2,YT+31);Line(X,YT+36,X2,YT+41);End;
  8: Begin Line(X,YT+31,X2,YT+36);Line(X,YT+41,X2,YT+36);End;
  9: Begin Ellipse(X,YT-4,0,180,6,5);FillEllipse(X,YT-4,1,1);End;
  10: FillEllipse(X,YT-6,1,1);
  11: Begin Line(X-4,YT-9,X+4,YT-6);Line(X-4,YT-3,X+4,YT-6);End;
  12: Begin Ellipse((X+X2) Div 2,YT-2,10,170,(X2-X) Div 2,6);
       Ellipse((X+X2) Div 2,YT-2,10,170,(X2-X) Div 2,5);End;
  13: BText(X,YT-14,'tr');
  14: BText(X,YT+40,'Ped.');
 End;
End;

Procedure DrawTextEv(Var E: TEvt; YT: Integer; Tr: PTrk);
Var X: Integer; S: String;
Begin
 If (E.Sty<1) Or (E.Sty>NLYR) Then Exit;
 X:=XOfTick(DispT(Tr,E.T));
 If (X<NOTEX0-8) Or (X>SCX2) Then Exit;
 S:=TxtPool[E.Sty];
 Case E.D2 Of
  0: PText(X-4,YT+46,S);
  1: PText(X-4,YT-24,S);
 Else BText(X-4,YT-24,S);
 End;
 If E.Sel Then Frame(X-6,YT+44,X+Length(S)*8,YT+56);
End;

{ Tuplets : crochet + chiffre 3 }
Procedure DrawTuplets;
Var G,Run,F: Integer; Y,X1,X2: Integer;
Begin
 Run:=0;F:=0;
 For G:=1 To GN Do Begin
  If GTrip[G]=1 Then Begin
   If Run=0 Then F:=G;
   Inc(Run);
   If Run=3 Then Begin
    X1:=GX[F];X2:=GX[G];
    If GDir[F]=1 Then Begin
     Y:=Integer(Min2(GEnd[F],Min2(GEnd[F+1],GEnd[G])))-5;
     Line(X1,Y+3,X1,Y);Line(X1,Y,X2,Y);Line(X2,Y,X2,Y+3);
     PText((X1+X2) Div 2-4,Y-9,'3');
    End Else Begin
     Y:=Integer(Max2(GEnd[F],Max2(GEnd[F+1],GEnd[G])))+5;
     Line(X1,Y-3,X1,Y);Line(X1,Y,X2,Y);Line(X2,Y,X2,Y-3);
     PText((X1+X2) Div 2-4,Y+2,'3');
    End;
    Run:=0;
   End;
  End Else Run:=0;
 End;
End;

{ Dessine une piste dans la rangee Row ; retourne rien }
Procedure DrawScoreTrack(Idx,Row: Integer);
Var Tr: PTrk; YT,YB,I,J,K,X,Y,Pos,Acc,Pv,TX: Integer; T0,T1,T,Cur,BE: LongInt;
 Typ,Dot,Trip: Integer; Dir,B,Lv,Lim,E1: Integer; Pc: LongInt; HasNotes: Boolean;
 BY,Sx,Sy1,Sy2,XA,XB: Integer; Run0,Run1: Integer;
 Tmp: Integer; BarB: LongInt; RT0,RT1: LongInt;
Begin
 Tr:=Trks[Idx];
 If Tr=Nil Then Exit;
 YT:=ScoreTop+(Row-1)*TrkSp+22;
 YB:=YT+24;
 If YT>BODY_B-20 Then Exit;
 DrawStaffBase(YT,Tr,Idx);
 T0:=ViewBar*BarTicks;
 T1:=TickOfX(SCX2+20);
 GatherNotes(Tr,T0,T1);
 { groupes }
 GN:=0;I:=1;
 While I<=DNN Do Begin
  Inc(GN);
  GS[GN]:=I;GC[GN]:=1;
  J:=I+1;
  While (J<=DNN) And (DN[J].Te=DN[I].Te) And (DN[J].Dur=DN[I].Dur) Do Begin
   Inc(GC[GN]);Inc(J);End;
  GTe[GN]:=DN[I].Te;GDur[GN]:=DN[I].Dur;
  GTyp[GN]:=DN[I].Typ;GDot[GN]:=DN[I].Dot;GTrip[GN]:=DN[I].Trip;
  GX[GN]:=XOfTick(DN[I].Te)+6;
  { positions extremes }
  GTop[GN]:=10000;GBot[GN]:=-10000;
  For K:=I To J-1 Do Begin
   Pos:=PosOf(DN[K].Pitch,Tr^.P.Clef,Acc);
   Y:=YB-Pos*3;
   If Y<GTop[GN] Then GTop[GN]:=Y;
   If Y>GBot[GN] Then GBot[GN]:=Y;
  End;
  If (GTop[GN]+GBot[GN]) Div 2>=YT+12 Then GDir[GN]:=1 Else GDir[GN]:=-1;
  I:=J;
 End;
 { poutres }
 For I:=1 To GN Do Begin
  If GDir[I]=1 Then GEnd[I]:=GTop[I]-19 Else GEnd[I]:=GBot[I]+19;
 End;
 I:=1;
 While I<=GN Do Begin
  If GTyp[I]>=3 Then Begin
   J:=I;
   While (J<GN) And (GTyp[J+1]>=3) And (GTe[J+1]=GTe[J]+GDur[J])
      And (GTe[J+1] Div BeamUnit=GTe[I] Div BeamUnit) Do Inc(J);
   If J>I Then Begin
    { direction commune = moyenne }
    Tmp:=0;
    For K:=I To J Do Tmp:=Tmp+(GTop[K]+GBot[K]) Div 2;
    If Tmp Div (J-I+1)>=YT+12 Then Dir:=1 Else Dir:=-1;
    For K:=I To J Do GDir[K]:=Dir;
    If Dir=1 Then Begin
     BY:=10000;
     For K:=I To J Do If GTop[K]-19<BY Then BY:=GTop[K]-19;
    End Else Begin
     BY:=-10000;
     For K:=I To J Do If GBot[K]+19>BY Then BY:=GBot[K]+19;
    End;
    For K:=I To J Do GEnd[K]:=BY;
    { barres }
    SetFillStyle(SolidFill,INK);
    For Lv:=1 To 4 Do Begin
     For K:=I To J Do
      If GTyp[K]>=2+Lv Then Begin
       If K<J Then Begin
        If GTyp[K+1]>=2+Lv Then Begin
         If Dir=1 Then Bar(GX[K]+4,BY+(Lv-1)*4,GX[K+1]+4,BY+(Lv-1)*4+1)
         Else Bar(GX[K]-4,BY-(Lv-1)*4-1,GX[K+1]-4,BY-(Lv-1)*4);
        End Else If (K=I) Or (GTyp[K-1]<2+Lv) Then Begin
         If Dir=1 Then Bar(GX[K]+4,BY+(Lv-1)*4,GX[K]+9,BY+(Lv-1)*4+1)
         Else Bar(GX[K]-4,BY-(Lv-1)*4-1,GX[K]+1,BY-(Lv-1)*4);
        End;
       End Else If (K>I) And (GTyp[K-1]<2+Lv) Then Begin
        If Dir=1 Then Bar(GX[K]-1,BY+(Lv-1)*4,GX[K]+4,BY+(Lv-1)*4+1)
        Else Bar(GX[K]-9,BY-(Lv-1)*4-1,GX[K]-4,BY-(Lv-1)*4);
       End;
      End;
    End;
    For K:=I To J Do GTyp[K]:=GTyp[K]+100;   { marque : poutre dessinee }
   End;
   I:=J+1;
  End Else Inc(I);
 End;
 { dessin des groupes }
 SetColor(INK);SetLineStyle(SolidLn,0,1);SetFillStyle(SolidFill,INK);
 For I:=1 To GN Do Begin
  Typ:=GTyp[I];Lv:=0;
  If Typ>=100 Then Begin Typ:=Typ-100;Lv:=1;End;
  X:=GX[I];
  If (X>=NOTEX0-6) And (X<=SCX2) Then Begin
   For K:=GS[I] To GS[I]+GC[I]-1 Do Begin
    Pos:=PosOf(DN[K].Pitch,Tr^.P.Clef,Acc);
    Y:=YB-Pos*3;
    DrawLedger(X,Pos,YB);
    If (Acc>0) And ((K=GS[I]) Or True) And Not ((K>1) And DN[K-1].Tie And
        (DN[K-1].Pitch=DN[K].Pitch) And (DN[K-1].Te+DN[K-1].Dur=DN[K].Te))
      Then DrawAcc(X-11,Y,Acc);
    DrawHead(X,Y,Typ,DN[K].Sty,DN[K].Sel);
    If GDot[I]=1 Then Begin
     If Odd(Pos) Then FillEllipse(X+9,Y,1,1) Else FillEllipse(X+9,Y-3,1,1);
    End;
    If DN[K].Tie Then Begin
     { liaison vers la note suivante }
     XB:=XOfTick(DN[K].Te+DN[K].Dur)+6;
     If XB>SCX2 Then XB:=SCX2;
     If GDir[I]=1 Then Ellipse((X+XB) Div 2,Y+3,200,340,(XB-X) Div 2,4)
     Else Ellipse((X+XB) Div 2,Y-3,20,160,(XB-X) Div 2,4);
    End;
   End;
   { hampe }
   If Typ>=1 Then Begin
    If GDir[I]=1 Then Begin
     Sx:=X+4;Line(Sx,GBot[I],Sx,GEnd[I]);
    End Else Begin
     Sx:=X-4;Line(Sx,GTop[I],Sx,GEnd[I]);
    End;
    If (Typ>=3) And (Lv=0) Then Begin
     For B:=0 To Typ-3 Do
      If GDir[I]=1 Then Begin
       Line(Sx,GEnd[I]+B*4,Sx+6,GEnd[I]+6+B*4);
       Line(Sx+6,GEnd[I]+6+B*4,Sx+4,GEnd[I]+12+B*4);
      End Else Begin
       Line(Sx,GEnd[I]-B*4,Sx+6,GEnd[I]-6-B*4);
       Line(Sx+6,GEnd[I]-6-B*4,Sx+4,GEnd[I]-12-B*4);
      End;
    End;
   End;
  End;
 End;
 DrawTuplets;
 { silences }
 HasNotes:=(DNN>0);
 If (Tr^.Ev<>Nil) And Not HasNotes Then
  For I:=1 To Tr^.Cnt Do If Tr^.Ev^[I].Kind=EK_NOTE Then HasNotes:=True;
 If HasNotes Then Begin
  B:=0;
  BarB:=ViewBar;
  While XOfTick(BarB*BarTicks)<=SCX2 Do Begin
   If BarB<Pats[CurPat].Len Then Begin
    Cur:=BarB*BarTicks;BE:=Cur+BarTicks;
    I:=1;
    While (I<=GN) And (GTe[I]<Cur) Do Inc(I);
    If (I>GN) Or (GTe[I]>=BE) Then Begin
     X:=XOfTick(Cur+BarTicks Div 2);
     If X<=SCX2 Then DrawRest(X,YT,0,0);
    End Else Begin
     While Cur<BE Do Begin
      If (I<=GN) And (GTe[I]<BE) Then Begin RT1:=GTe[I];End Else RT1:=BE;
      While Cur<RT1 Do Begin
       Pc:=Notate(RT1-Cur,((RT1-Cur) Mod (PPQ Div 4))<>0,Typ,Dot,Trip);
       If Pc>RT1-Cur Then Pc:=RT1-Cur;
       If Pc<=0 Then Pc:=RT1-Cur;
       X:=XOfTick(Cur)+6;
       If (X>=NOTEX0-6) And (X<=SCX2) Then DrawRest(X,YT,Typ,Dot);
       Cur:=Cur+Pc;
      End;
      If (I<=GN) And (GTe[I]<BE) Then Begin
       Cur:=GTe[I]+GDur[I];
       Inc(I);
       While (I<=GN) And (GTe[I]<Cur) Do Inc(I);
      End Else Cur:=BE;
     End;
    End;
   End;
   Inc(BarB);
  End;
 End;
 { symboles et textes }
 If Tr^.Ev<>Nil Then
  For I:=1 To Tr^.Cnt Do Begin
   If Tr^.Ev^[I].Kind=EK_SYM Then DrawSym(Tr^.Ev^[I],YT,Tr);
   If Tr^.Ev^[I].Kind=EK_TEXT Then DrawTextEv(Tr^.Ev^[I],YT,Tr);
  End;
 { piste courante }
 If Idx=TI(CurPat,CurTrk) Then Begin
  SetColor(INK);
  Frame(PAL_W,YT-1,PAL_W+1,YT+25);
 End;
End;

{ ajustement de l'espacement aux paroles }
Procedure BuildStretch;
Var I,J,K,N: Integer; Tr: PTrk; T,T0: LongInt; W,Dx,Ex,Cum: Integer;
Begin
 StrN:=0;
 T0:=ViewBar*BarTicks-BarTicks;
 For I:=1 To VN Do Begin
  Tr:=Trks[TI(CurPat,VT[I])];
  If (Tr<>Nil) And (Tr^.Ev<>Nil) Then
   For J:=1 To Tr^.Cnt Do
    If (Tr^.Ev^[J].Kind=EK_TEXT) And (Tr^.Ev^[J].D2=0) And
       (Tr^.Ev^[J].Sty>=1) And (Tr^.Ev^[J].T>=T0) And (StrN<NLYR) Then Begin
     T:=DispT(Tr,Tr^.Ev^[J].T);
     W:=Length(TxtPool[Tr^.Ev^[J].Sty])*8+10;
     K:=1;
     While (K<=StrN) And (StrT[K]<T) Do Inc(K);
     If (K<=StrN) And (StrT[K]=T) Then Begin
      If W>StrW[K] Then StrW[K]:=W;
     End Else Begin
      For N:=StrN DownTo K Do Begin StrT[N+1]:=StrT[N];StrW[N+1]:=StrW[N];End;
      StrT[K]:=T;StrW[K]:=W;Inc(StrN);
     End;
    End;
 End;
 Cum:=0;
 For I:=1 To StrN Do Begin
  If I<StrN Then Dx:=Integer(((StrT[I+1]-StrT[I])*PxQ) Div PPQ) Else Dx:=9999;
  Ex:=StrW[I]-Dx;
  If Ex<0 Then Ex:=0;
  Cum:=Cum+Ex;
  StrX[I]:=Cum;
 End;
End;

{ ====================================================================== }
{                  VUES : PARTITION / MATRICE / LISTE / ARRANGEMENT      }
{ ====================================================================== }

Const
 HyperLbl : Array[0..5] Of String[6] = ('veloc.','volume','pan','mod.',
                                         'expr.','bend');
 HyperCC  : Array[1..4] Of Byte = (7,10,1,11);
 NPAL     = 29;
 MajPc    : Array[0..6] Of Byte = (0,2,4,5,7,9,11);
 AR_LX    = 0;       { panneau gauche : liste des patterns }
 AR_MX    = 216;     { panneau central : pistes }
 AR_RX    = 424;     { panneau droit : parametres }

Var
 ArrTop,HeadSty : Integer;

Function PalY0: Integer;
Begin
 If ShowHyper Then PalY0:=BODY_Y+HYP_H Else PalY0:=BODY_Y+16;
End;

Function PalCellX(I: Integer): Integer;
Begin
 PalCellX:=((I-1) Mod 2)*24;
End;

Function PalCellY(I: Integer): Integer;
Begin
 PalCellY:=PalY0+((I-1) Div 2)*16;
End;

Procedure DrawPalCell(I: Integer);
Var X,Y: Integer; Sel: Boolean; S: String; Pt: Array[1..3] Of PointType;
Begin
 X:=PalCellX(I);Y:=PalCellY(I);
 Sel:=False;
 Case I Of
  1..6: Sel:=(Tool=I);
  7..12: Sel:=(Tool=2) And (PenDur=I-7) ;
  13: Sel:=PenDot;
  14: Sel:=PenTrip;
  15..28: Sel:=(Tool=I);
  29: Sel:=(HeadSty<>0);
 End;
 If Sel Then Box(X,Y,X+23,Y+15,INK) Else Box(X,Y,X+23,Y+15,PAPER);
 Frame(X,Y,X+23,Y+15);
 If Sel Then SetColor(PAPER) Else SetColor(INK);
 Case I Of
  1: Begin Line(X+8,Y+3,X+8,Y+12);Line(X+8,Y+3,X+14,Y+9);Line(X+8,Y+9,X+12,Y+9);End;
  2: Begin Line(X+7,Y+12,X+15,Y+4);Line(X+7,Y+12,X+7,Y+10);Line(X+7,Y+12,X+9,Y+12);End;
  3: Begin Rectangle(X+6,Y+5,X+16,Y+11);Line(X+9,Y+5,X+9,Y+11);End;
  4: OutTextXY(X+4,Y+4,'Ly');
  5: OutTextXY(X+4,Y+4,'Tx');
  6: OutTextXY(X+4,Y+4,'Ch');
  7..12: Begin
          Pt[1].X:=0;
          If Sel Then SetFillStyle(SolidFill,PAPER) Else SetFillStyle(SolidFill,INK);
          If I=7 Then Ellipse(X+10,Y+10,0,360,4,3)
          Else If I=8 Then Begin Ellipse(X+10,Y+10,0,360,4,3);Line(X+14,Y+10,X+14,Y+2);End
          Else Begin
           FillEllipse(X+10,Y+10,4,3);Line(X+14,Y+10,X+14,Y+2);
           If I>=9 Then Line(X+14,Y+2,X+18,Y+5);
           If I>=10 Then Line(X+14,Y+5,X+18,Y+8);
           If I>=11 Then Line(X+14,Y+8,X+18,Y+11);
          End;
         End;
  13: Begin OutTextXY(X+6,Y+4,'.');End;
  14: OutTextXY(X+8,Y+4,'3');
  15..28: Begin
           S:=SymTxt[I-14];
           If I-14=7 Then Begin Line(X+4,Y+8,X+19,Y+4);Line(X+4,Y+8,X+19,Y+12);End
           Else If I-14=8 Then Begin Line(X+4,Y+4,X+19,Y+8);Line(X+4,Y+12,X+19,Y+8);End
           Else If I-14=10 Then FillEllipse(X+11,Y+8,1,1)
           Else If I-14=11 Then Begin Line(X+5,Y+4,X+17,Y+8);Line(X+5,Y+12,X+17,Y+8);End
           Else OutTextXY(X+(24-Length(S)*8) Div 2,Y+4,S);
          End;
  29: Begin
       Case HeadSty Of
        1: Begin Line(X+11,Y+4,X+16,Y+8);Line(X+16,Y+8,X+11,Y+12);
            Line(X+11,Y+12,X+6,Y+8);Line(X+6,Y+8,X+11,Y+4);End;
        2: Begin Line(X+7,Y+5,X+15,Y+11);Line(X+7,Y+11,X+15,Y+5);End;
        3: Begin Line(X+6,Y+12,X+16,Y+12);Line(X+16,Y+12,X+11,Y+4);
            Line(X+11,Y+4,X+6,Y+12);End;
        4: Line(X+6,Y+12,X+16,Y+4);
       Else FillEllipse(X+11,Y+8,4,3);
       End;
      End;
 End;
End;

Procedure DrawPalette;
Var I: Integer;
Begin
 Box(0,BODY_Y,PAL_W-1,BODY_B,PAPER);
 Line(PAL_W-1,BODY_Y,PAL_W-1,BODY_B);
 For I:=1 To NPAL Do DrawPalCell(I);
End;

{ valeur d'un evenement pour l'editeur hyper ; retourne l'echelle max }
Function HyperVal(Var E: TEvt; Var V: LongInt): Boolean;
Begin
 HyperVal:=False;
 If HyperKind=0 Then Begin
  If E.Kind=EK_NOTE Then Begin V:=E.D2;HyperVal:=True;End;
 End Else If HyperKind=5 Then Begin
  If E.Kind=EK_BEND Then Begin V:=E.D2*128+E.D1;HyperVal:=True;End;
 End Else If (E.Kind=EK_CTRL) And (E.D1=HyperCC[HyperKind]) Then Begin
  V:=E.D2;HyperVal:=True;End;
End;

Function HyperMax: LongInt;
Begin
 If HyperKind=5 Then HyperMax:=16383 Else HyperMax:=127;
End;

Procedure DrawHyper;
Var Tr: PTrk; I: Integer; V,Mx: LongInt; X,XP,H,HP,YB: Integer; Have: Boolean;
Begin
 YB:=BODY_Y+HYP_H-3;
 Box(PAL_W,BODY_Y,SCX2+16,BODY_Y+HYP_H-1,PAPER);
 Frame(PAL_W,BODY_Y,SCX2,BODY_Y+HYP_H-1);
 Box(0,BODY_Y,PAL_W-1,BODY_Y+15,PAPER);Frame(0,BODY_Y,PAL_W-1,BODY_Y+15);
 BText(2,BODY_Y+4,HyperLbl[HyperKind]);
 Mx:=HyperMax;
 Tr:=CT;
 If (Tr=Nil) Or (Tr^.Ev=Nil) Then Exit;
 SetColor(INK);
 If HyperKind=0 Then Begin
  SetFillStyle(SolidFill,INK);
  For I:=1 To Tr^.Cnt Do
   If HyperVal(Tr^.Ev^[I],V) Then Begin
    X:=XOfTick(DispT(Tr,Tr^.Ev^[I].T));
    If (X>=NOTEX0-4) And (X<=SCX2) Then Begin
     H:=Integer((V*(HYP_H-8)) Div Mx);
     Bar(X-1,YB-H,X+2,YB);
    End;
   End;
 End Else Begin
  XP:=NOTEX0-4;HP:=0;Have:=False;
  For I:=1 To Tr^.Cnt Do
   If HyperVal(Tr^.Ev^[I],V) Then Begin
    X:=XOfTick(Tr^.Ev^[I].T);
    H:=Integer((V*(HYP_H-8)) Div Mx);
    If X>SCX2 Then X:=SCX2;
    If X<NOTEX0-4 Then X:=NOTEX0-4;
    If Have Then PatBar(XP,YB-HP,X,YB,PatHyper[ColorNo And 3]);
    If Have Then Line(X,YB-HP,X,YB-H);
    XP:=X;HP:=H;Have:=True;
   End;
  If Have Then PatBar(XP,YB-HP,SCX2-1,YB,PatHyper[ColorNo And 3]);
 End;
End;

Procedure DrawScrollArrows(Y1,Y2: Integer);
Begin
 Box(SCX2+1,Y1,SCR_W-1,Y2,PAPER);
 Frame(SCX2+1,Y1,SCR_W-1,Y2);
 ArrowBox(SCX2+1,Y1,SCR_W-1,Y1+14,1);
 ArrowBox(SCX2+1,Y2-14,SCR_W-1,Y2,2);
End;

Procedure DrawScoreView;
Var R,K,Idx: Integer;
Begin
 TimeX0:=NOTEX0;UseStretch:=True;
 BuildVT;BuildStretch;
 SetKeyAcc;
 Box(0,BODY_Y,SCR_W-1,BODY_B,PAPER);
 DrawRuler(NOTEX0-4);
 ArrowBox(SCX2+1,RL_Y,SCX2+8,RL_B,3);
 ArrowBox(SCX2+9,RL_Y,SCR_W-1,RL_B,4);
 DrawMarkers;
 DrawPalette;
 If ShowHyper Then DrawHyper;
 For R:=1 To VisTrk Do Begin
  K:=TrkTop+R-1;
  If K<=VN Then DrawScoreTrack(TI(CurPat,VT[K]),R);
 End;
 DrawScrollArrows(BODY_Y,BODY_B);
End;

{ ---- Matrice ---- }
Function MatRowH: Integer;
Begin
 MatRowH:=8+ZoomY Div 2;
End;

Function MatRows: Integer;
Begin
 MatRows:=Integer((BODY_B-BODY_Y-2) Div MatRowH);
End;

Function MatPitch(Row: Integer): Integer;
Var Tr: PTrk;
Begin
 Tr:=CT;
 If Tr^.P.Drum Then Begin
  If (Row>=1) And (Row<=NDRUM) Then MatPitch:=DrumNote[Row] Else MatPitch:=-1;
 End Else MatPitch:=Integer(Clamp(MatTop-(Row-1),0,127));
End;

Procedure DrawMatrixView;
Var Tr: PTrk; R,I,Y,X,X2,P,NR: Integer; T,G,T0,T1,Te: LongInt; S: String; Cnt: Integer;
 Q: LongInt;
Begin
 TimeX0:=190;UseStretch:=False;
 Tr:=CT;
 Box(0,BODY_Y,SCR_W-1,BODY_B,PAPER);
 DrawRuler(190);
 ArrowBox(SCX2+1,RL_Y,SCX2+8,RL_B,3);
 ArrowBox(SCX2+9,RL_Y,SCR_W-1,RL_B,4);
 { entetes de colonnes }
 Box(0,BODY_Y,189,BODY_Y+11,PAPER);
 PText(4,BODY_Y+2,'NAME');PText(64,BODY_Y+2,'QUA');PText(92,BODY_Y+2,'DLY');
 PText(114,BODY_Y+2,'WHAT');PText(152,BODY_Y+2,'STATUS');
 NR:=MatRows-1;
 If Tr^.P.Drum Then NR:=Integer(Min2(NR,NDRUM));
 G:=QuaTicks(FmtQ);
 If G=0 Then G:=PPQ Div 4;
 T0:=ViewBar*BarTicks;T1:=TickOfX(SCX2);
 For R:=1 To NR Do Begin
  Y:=BODY_Y+12+(R-1)*MatRowH;
  P:=MatPitch(R);
  SetColor(INK);
  Line(0,Y+MatRowH-1,SCX2,Y+MatRowH-1);
  If Tr^.P.Drum Then S:=DrumNm[R] Else S:=NoteName(P);
  If (Not Tr^.P.Drum) And ((P Mod 12) In [1,3,6,8,10]) Then
   PatBar(0,Y,189,Y+MatRowH-2,PatLight);
  PText(4,Y+(MatRowH-8) Div 2,S);
  PText(68,Y+(MatRowH-8) Div 2,QuaShort(FmtQ));
  If Tr^.P.Delay<>0 Then PText(94,Y+(MatRowH-8) Div 2,#251);
  PText(114,Y+(MatRowH-8) Div 2,'NOTE');
  PText(154,Y+(MatRowH-8) Div 2,'NOTE');
 End;
 { grille verticale }
 T:=(T0 Div G)*G;
 Q:=G;
 While T<=T1 Do Begin
  X:=XOfTick(T);
  If (X>=TimeX0) And (X<=SCX2) Then Begin
   If (T Mod BarTicks)=0 Then Begin
    SetColor(INK);Line(X,BODY_Y+12,X,BODY_B);
   End Else If (T Mod BeatTicks)=0 Then Begin
    For Y:=BODY_Y+12 To BODY_B Do If Odd(Y Div 2) Then PutPixel(X,Y,INK);
   End Else Begin
    For Y:=BODY_Y+12 To BODY_B Do If (Y Mod 4)=0 Then PutPixel(X,Y,INK);
   End;
  End;
  T:=T+Q;
 End;
 Line(190,BODY_Y,190,BODY_B);
 { notes }
 If Tr^.Ev<>Nil Then
  For I:=1 To Tr^.Cnt Do
   If Tr^.Ev^[I].Kind=EK_NOTE Then Begin
    For R:=1 To NR Do
     If MatPitch(R)=Tr^.Ev^[I].D1 Then Begin
      Te:=DispT(Tr,Tr^.Ev^[I].T);
      X:=XOfTick(Te);X2:=XOfTick(Te+Tr^.Ev^[I].Len)-1;
      If Tr^.P.Drum Then X2:=XOfTick(Te+G)-1;
      If X2<X+2 Then X2:=X+2;
      If (X2>=TimeX0) And (X<=SCX2) Then Begin
       If X<TimeX0+1 Then X:=TimeX0+1;
       If X2>SCX2 Then X2:=SCX2;
       Y:=BODY_Y+12+(R-1)*MatRowH;
       If Tr^.Ev^[I].D2>=90 Then Box(X,Y+1,X2,Y+MatRowH-3,INK)
       Else If Tr^.Ev^[I].D2>=60 Then PatBar(X,Y+1,X2,Y+MatRowH-3,PatDark)
       Else PatBar(X,Y+1,X2,Y+MatRowH-3,PatLight);
       Frame(X,Y+1,X2,Y+MatRowH-3);
       If Tr^.Ev^[I].Sel Then Frame(X-1,Y,X2+1,Y+MatRowH-2);
      End;
     End;
   End;
 DrawMarkers;
 DrawScrollArrows(BODY_Y,BODY_B);
End;

{ ---- Liste d'evenements ---- }
Const LST_ROW = 11;

Function ListRows: Integer;
Begin
 ListRows:=Integer((BODY_B-BODY_Y-26) Div LST_ROW);
End;

Procedure DrawListView;
Var Tr: PTrk; I,N,Y: Integer; S: String; Inv: Boolean;
Begin
 Box(0,BODY_Y,SCR_W-1,BODY_B,PAPER);
 Tr:=CT;
 Box(0,RL_Y,SCR_W-1,RL_B,PAPER);Line(0,RL_Y,SCR_W-1,RL_Y);Line(0,RL_B,SCR_W-1,RL_B);
 PText(8,RL_Y+3,'BAR BEAT 16  TICK');
 PText(180,RL_Y+3,'STATUS');PText(280,RL_Y+3,'DATA 1  DATA 2  LENGTH');
 PText(500,RL_Y+3,'CH');
 PText(4,BODY_Y+2,TrkName(TI(CurPat,CurTrk))+'  ('+Tr^.P.Instr+' '+PortCh(Tr)+')  '+
   IntStr(Tr^.Cnt)+' events');
 SetColor(INK);Line(0,BODY_Y+14,SCX2,BODY_Y+14);
 If Tr^.Ev=Nil Then Exit;
 If ListTop<1 Then ListTop:=1;
 I:=ListTop;N:=0;
 If Not Passes(Tr^.Ev^[Max2(1,Min2(I,Tr^.Cnt))]) Then I:=NextFlt(Tr,I,1);
 While (I>=1) And (I<=Tr^.Cnt) And (N<ListRows) Do Begin
  Y:=BODY_Y+18+N*LST_ROW;
  Inv:=(I=CurEv);
  If Inv Then Box(0,Y-1,SCX2,Y+LST_ROW-3,INK);
  S:=PadL(PosStr(Tr^.Ev^[I].T),14);
  If Inv Then SetColor(PAPER) Else SetColor(INK);
  OutTextXY(8,Y,S);
  OutTextXY(180,Y,Copy(EvStatus(Tr^.Ev^[I]),1,12));
  OutTextXY(272,Y,EvData(Tr^.Ev^[I]));
  OutTextXY(500,Y,IntStr(Tr^.P.Chan));
  If Tr^.Ev^[I].Sel Then OutTextXY(540,Y,'*');
  Inc(N);
  I:=NextFlt(Tr,I,1);
 End;
 DrawScrollArrows(BODY_Y,BODY_B);
End;

{ ---- Page arrangement ---- }
Const
 AR_ROWH = 12;
 AR_ROWS = 24;
 NPAR = 12;
 ParLbl : Array[1..NPAR] Of String[9] =
  ('TRACK','CHANNEL','QUANTIZE','GROOVE','TRANSPOSE','VELOCITY','COMPRESS',
   'LOOP','DELAY','LOWEST','HIGHEST','SHIFT');
 NBTN = 15;
 BtnLbl : Array[1..NBTN] Of String[12] =
  ('DROP','UNDO','PUNCH','RECORD','EDIT','DO QUANTIZE','SOLO','MUTE',
   'DEFAULT','AUTODROP','CYCLE','MATRIX','START','CONT','STOP');

Function ParVal(Tr: PTrk; I: Integer): String;
Begin
 Case I Of
  1: ParVal:=IntStr(CurTrk);
  2: ParVal:=PortCh(Tr);
  3: ParVal:=QuaShort(Tr^.P.Qua);
  4: If Tr^.P.Groove<>0 Then ParVal:='ON' Else ParVal:='--';
  5: ParVal:=IntStr(Tr^.P.Trans);
  6: ParVal:=IntStr(Tr^.P.Vel);
  7: ParVal:=IntStr(Tr^.P.Comp);
  8: If Tr^.P.Loop=0 Then ParVal:='OFF' Else ParVal:=IntStr(Tr^.P.Loop);
  9: ParVal:=IntStr(Tr^.P.Delay);
  10: ParVal:=NoteName(Tr^.P.Lo);
  11: ParVal:=NoteName(Tr^.P.Hi);
  12: ParVal:=IntStr(Tr^.P.Shift);
 Else ParVal:='';
 End;
End;

{ position (x1,y1,x2,y2) d'un bouton de la page arrangement }
Procedure BtnRect(I: Integer; Var X1,Y1,X2,Y2: Integer);
Begin
 If I<=12 Then Begin
  X1:=AR_RX+((I-1) Mod 2)*104+2;
  Y1:=300+((I-1) Div 2)*22;
  X2:=X1+98;Y2:=Y1+18;
 End Else Begin
  X1:=AR_RX+2+(I-13)*70;Y1:=436;X2:=X1+66;Y2:=Y1+22;
 End;
End;

Function BtnHot(I: Integer): Boolean;
Begin
 Case I Of
  3: BtnHot:=FlPunch;
  4: BtnHot:=Recording;
  7: BtnHot:=CT^.P.Solo;
  8: BtnHot:=CT^.P.Mute;
  10: BtnHot:=FlAutoDrop;
  11: BtnHot:=FlCycle;
  13: BtnHot:=Playing;
 Else BtnHot:=False;
 End;
End;

Procedure DrawArrange;
Var I,Y,R,X1,Y1,X2,Y2,C: Integer; Tr: PTrk; S: String;
Begin
 Box(0,R2_Y,SCR_W-1,BODY_B,PAPER);
 { panneau gauche }
 Frame(AR_LX,R2_Y,AR_MX-4,BODY_B);
 Box(AR_LX+1,R2_Y+1,AR_MX-5,R2_Y+13,INK);
 WText(AR_LX+24,R2_Y+3,'ARRANGE');
 For C:=1 To 4 Do Begin
  WText(AR_LX+116+(C-1)*24+8,R2_Y+3,Chr(96+C));
 End;
 For R:=0 To AR_ROWS-1 Do Begin
  I:=ArrTop+R;
  If I<=NPAT Then Begin
   Y:=R2_Y+16+R*AR_ROWH;
   If I=CurPat Then Box(AR_LX+1,Y-1,AR_MX-5,Y+AR_ROWH-3,INK);
   If I=CurPat Then SetColor(PAPER) Else SetColor(INK);
   OutTextXY(AR_LX+2,Y,PadL(IntStr(I),2));
   S:=Pats[I].Name;
   OutTextXY(AR_LX+22,Y,Copy(S,1,12));
   For C:=1 To 4 Do
    If Pats[I].Rep[C]>0 Then
     OutTextXY(AR_LX+116+(C-1)*24+6,Y,IntStr(Pats[I].Rep[C]));
   SetColor(INK);
   Line(AR_LX+114,Y-1,AR_LX+114,Y+AR_ROWH-3);
   For C:=1 To 3 Do Line(AR_LX+114+C*24,Y-1,AR_LX+114+C*24,Y+AR_ROWH-3);
  End;
 End;
 ArrowBox(AR_MX-20,BODY_B-60,AR_MX-6,BODY_B-46,1);
 ArrowBox(AR_MX-20,BODY_B-44,AR_MX-6,BODY_B-30,2);
 PText(AR_LX+4,BODY_B-56,'Pattern LENGTH');
 BText(AR_LX+4,BODY_B-42,IntStr(Pats[CurPat].Len));
 PText(AR_LX+60,BODY_B-42,T3('bars','mesures','Takte'));
 { panneau central : pistes }
 Frame(AR_MX,R2_Y,AR_RX-4,BODY_B);
 Box(AR_MX+1,R2_Y+1,AR_RX-5,R2_Y+13,INK);
 WText(AR_MX+4,R2_Y+3,'STATUS');
 WText(AR_MX+76,R2_Y+3,'Pattern: '+IntStr(CurPat));
 WText(AR_MX+164,R2_Y+3,'CH');
 For R:=1 To TPP Do Begin
  Y:=R2_Y+17+(R-1)*16;
  Tr:=Trks[TI(CurPat,R)];
  If (Tr<>Nil) And Tr^.Sel Then Box(AR_MX+1,Y-2,AR_RX-5,Y+12,INK);
  If (Tr<>Nil) And Tr^.Sel Then SetColor(PAPER) Else SetColor(INK);
  OutTextXY(AR_MX+4,Y,PadL(IntStr(R),2));
  If R=CurTrk Then Begin Line(AR_MX+2,Y-1,AR_MX+2,Y+9);End;
  If Tr<>Nil Then Begin
   OutTextXY(AR_MX+26,Y,Copy(TrkName(TI(CurPat,R)),1,10));
   OutTextXY(AR_MX+112,Y,Copy(Tr^.P.Instr,1,6));
   OutTextXY(AR_MX+164,Y,PortCh(Tr));
   If Tr^.Cnt>0 Then OutTextXY(AR_MX+196-8,Y+0,'');
   If Tr^.P.Mute Then OutTextXY(AR_MX+194,Y,'M');
   If Tr^.P.Solo Then OutTextXY(AR_MX+186,Y,'S');
  End Else Begin
   OutTextXY(AR_MX+26,Y,T3('Track ','Piste ','Spur ')+IntStr(R));
   OutTextXY(AR_MX+164,Y,'A '+IntStr(R));
  End;
  SetColor(INK);
  Line(AR_MX+1,Y+12,AR_RX-5,Y+12);
  If R=CurTrk Then Frame(AR_MX+1,Y-2,AR_RX-5,Y+12);
 End;
 { evenements : note }
 PText(AR_MX+4,R2_Y+17+TPP*16+6,T3('Click: select / Dbl: edit track',
   'Clic: s'#130'lection / Dbl: '#130'diter piste',
   'Klick: Auswahl / Doppel: Spur'));
 { panneau droit }
 Tr:=CT;
 Frame(AR_RX,R2_Y,SCR_W-1,BODY_B);
 Box(AR_RX+1,R2_Y+1,SCR_W-2,R2_Y+13,INK);
 WText(AR_RX+4,R2_Y+3,'TRACK: '+IntStr(CurTrk)+'  '+Copy(TrkName(TI(CurPat,CurTrk)),1,10));
 For I:=1 To NPAR Do Begin
  Y:=R2_Y+18+(I-1)*13;
  PText(AR_RX+6,Y,ParLbl[I]);
  Box(AR_RX+90,Y-2,AR_RX+160,Y+9,PAPER);Frame(AR_RX+90,Y-2,AR_RX+160,Y+9);
  BText(AR_RX+94,Y,ParVal(Tr,I));
 End;
 { locators }
 Y:=R2_Y+18+NPAR*13+8;
 PText(AR_RX+6,Y,'LEFT LOCATOR');
 Box(AR_RX+6,Y+12,AR_RX+150,Y+24,INK);WText(AR_RX+10,Y+14,PadL(PosStr(LocL),16));
 PText(AR_RX+6,Y+30,'RIGHT LOCATOR');
 Box(AR_RX+6,Y+42,AR_RX+150,Y+54,INK);WText(AR_RX+10,Y+44,PadL(PosStr(LocR),16));
 { boutons }
 For I:=1 To NBTN Do Begin
  BtnRect(I,X1,Y1,X2,Y2);
  Button(X1,Y1,X2,Y2,BtnLbl[I],BtnHot(I),True);
 End;
 If TakePending Then PText(AR_RX+6,R2_B+4+0,'');
End;

{ ---- tete de lecture (XOR) ---- }
Procedure DrawPlayhead;
Var X: Integer;
Begin
 If (View<>V_SCORE) And (View<>V_MATRIX) Then Begin PlayX:=-1;Exit;End;
 SetWriteMode(XORPut);
 SetColor(15);SetLineStyle(SolidLn,0,1);
 If PlayX>=0 Then Line(PlayX,BODY_Y,PlayX,BODY_B);
 PlayX:=-1;
 If Playing And (PlayTick>=0) Then Begin
  X:=XOfTick(PlayTick);
  If (X>=TimeX0) And (X<=SCX2) Then Begin
   Line(X,BODY_Y,X,BODY_B);PlayX:=X;
  End;
 End;
 SetWriteMode(NormalPut);
End;

Procedure UpdatePlayDisplay;
Var X: Integer;
Begin
 If Not Playing Then Exit;
 If (PlayShown>=0) And (Abs(PlayTick-PlayShown)<PPQ Div 4) Then Exit;
 If (FlFollow) And ((View=V_SCORE) Or (View=V_MATRIX)) And (PlayTick>=0) Then Begin
  X:=XOfTick(PlayTick);
  If (X>SCX2-10) Or (X<TimeX0) Then Begin
   ViewBar:=PlayTick Div BarTicks;
   NeedDraw:=True;
   Exit;
  End;
 End;
 HideMouse;
 DrawPosCells;
 DrawPlayhead;
 ShowMouse;
End;

{ ====================================================================== }
{                  FICHIERS : MORCEAU (.SON) ET MIDI (.MID)              }
{ ====================================================================== }

Type
 TSonHdr = Packed Record
  ID : Array[1..4] Of Char;
  Ver,PPQ : Word;
  Tempo,LocL,LocR : LongInt;
  SigN,SigD,Fmt,Sync : Byte;
  Key : ShortInt;
  GOff,GVel : Array[0..3] Of Integer;
  NT : Word;
 End;
 TMsg = Record
  T : LongInt;
  Ord1,S,D1,D2,Cnt : Byte;
 End;
 PMsgArr = ^TMsgArr;
 TMsgArr = Array[1..1500] Of TMsg;
 PByteArr = ^TByteArr;
 TByteArr = Array[0..16000] Of Byte;

Var
 SonFile : String[79];
 MidFile : String[79];

{ Les fichiers .SON gardent la disposition de Turbo Pascal 7 (enregistrements
  compactes, String[n] sur n + 1 octets) : en-tete de 43 octets, 99 patterns
  de 19 octets, 200 drapeaux et 200 textes de 21 octets, puis pour chaque
  piste son numero, ses parametres (46 octets), le nombre d'evenements et les
  evenements (13 octets). OS2PC range ses chaines sur 256 octets : chaque
  champ est donc lu et ecrit un a un. }
Var
 SonF   : File;
 SIO    : Array[0..4095] Of Byte;
 SIOPos,SIOLen : LongInt;
 SEof   : Boolean;

Procedure SW1(V: LongInt);
Begin
 SIO[SIOPos]:=V And 255;
 Inc(SIOPos);
 If SIOPos=4096 Then Begin BlockWrite(SonF,SIO,4096);SIOPos:=0;End;
End;

Procedure SW2(V: LongInt);
Begin
 SW1(V);SW1(V Shr 8);
End;

Procedure SW4(V: LongInt);
Begin
 SW2(V And $FFFF);SW2((V Shr 16) And $FFFF);
End;

Procedure SWStr(Const S: String; L: Integer);
Var I,N: Integer;
Begin
 N:=Length(S);
 If N>L Then N:=L;
 SW1(N);
 For I:=1 To L Do If I<=N Then SW1(Ord(S[I])) Else SW1(0);
End;

Procedure SWBool(B: Boolean);
Begin
 If B Then SW1(1) Else SW1(0);
End;

Function SR1: LongInt;
Begin
 If SIOPos>=SIOLen Then Begin
  SIOLen:=0;
  BlockRead(SonF,SIO,4096,SIOLen);
  SIOPos:=0;
  If SIOLen<=0 Then Begin SEof:=True;SR1:=0;Exit;End;
 End;
 SR1:=SIO[SIOPos];
 Inc(SIOPos);
End;

Function SR2: LongInt;
Var V: LongInt;
Begin
 V:=SR1;
 V:=V Or (SR1 Shl 8);
 SR2:=V;
End;

{ entier signe de 16 bits (Integer de TP7) }
Function SR2S: LongInt;
Var V: LongInt;
Begin
 V:=SR2;
 If V>=32768 Then V:=V-65536;
 SR2S:=V;
End;

Function SR4: LongInt;
Var V: LongInt;
Begin
 V:=SR2;
 V:=V Or (SR2 Shl 16);
 SR4:=V;
End;

Function SRStr(L: Integer): String;
Var I,N: Integer; S: String;
Begin
 N:=SR1;S:='';
 For I:=1 To L Do
  If I<=N Then S:=S+Chr(SR1) Else Dummy:=SR1;
 SRStr:=S;
End;

Function SaveSong(Const Name: String): Boolean;
Var I,K,NT: Integer; Tr: PTrk;
Begin
 SaveSong:=False;
 NT:=0;
 For I:=1 To MAXTRK Do If Trks[I]<>Nil Then Inc(NT);
 Assign(SonF,Name);
 Rewrite(SonF,1);
 If IOResult<>0 Then Exit;
 SIOPos:=0;
 SW1(Ord('N'));SW1(Ord('S'));SW1(Ord('O'));SW1(Ord('N'));
 SW2(1);SW2(PPQ);SW4(Tempo10k);SW4(LocL);SW4(LocR);
 SW1(SigN);SW1(SigD);SW1(FmtQ);SW1(SyncMode);SW1(KeyS);
 For I:=0 To 3 Do SW2(GrvOff[I]);
 For I:=0 To 3 Do SW2(GrvVel[I]);
 SW2(NT);
 For I:=1 To NPAT Do Begin
  SWStr(Pats[I].Name,12);SW2(Pats[I].Len);
  For K:=1 To 4 Do SW1(Pats[I].Rep[K]);
 End;
 For I:=1 To NLYR Do SWBool(TxtUsed[I]);
 For I:=1 To NLYR Do SWStr(TxtPool[I],20);
 For I:=1 To MAXTRK Do
  If Trks[I]<>Nil Then Begin
   Tr:=Trks[I];
   SW2(I);
   SWStr(Tr^.P.Name,10);SWStr(Tr^.P.Instr,10);
   SW1(Tr^.P.Port);SW1(Tr^.P.Chan);SW1(Tr^.P.Qua);SW1(Tr^.P.Groove);SW1(Tr^.P.Clef);
   SW2(Tr^.P.Trans);SW2(Tr^.P.Vel);SW2(Tr^.P.Comp);SW2(Tr^.P.Delay);
   SW2(Tr^.P.Loop);SW2(Tr^.P.Lo);SW2(Tr^.P.Hi);SW2(Tr^.P.Shift);
   SWBool(Tr^.P.Mute);SWBool(Tr^.P.Solo);SWBool(Tr^.P.Drum);
   If Tr^.Ev=Nil Then SW2(0) Else Begin
    SW2(Tr^.Cnt);
    For K:=1 To Tr^.Cnt Do Begin
     SW4(Tr^.Ev^[K].T);SW4(Tr^.Ev^[K].Len);
     SW1(Tr^.Ev^[K].Kind);SW1(Tr^.Ev^[K].D1);SW1(Tr^.Ev^[K].D2);SW1(Tr^.Ev^[K].Sty);
     SWBool(Tr^.Ev^[K].Sel);
    End;
   End;
  End;
 If SIOPos>0 Then BlockWrite(SonF,SIO,SIOPos);
 SIOPos:=0;
 Close(SonF);
 SaveSong:=(IOResult=0);
End;

Function LoadSong(Const Name: String): Boolean;
Var I,K,NT,W,Idx: LongInt; P: PTrk; Ok: Boolean; Id: String; GO,GV: Array[0..3] Of LongInt;
    HPPQ,HTempo,HLocL,HLocR,HSigN,HSigD,HFmt,HSync,HKey: LongInt;
Begin
 LoadSong:=False;
 Assign(SonF,Name);
 Reset(SonF,1);
 If IOResult<>0 Then Exit;
 SIOPos:=0;SIOLen:=0;SEof:=False;
 Id:='';
 For I:=1 To 4 Do Id:=Id+Chr(SR1);
 Dummy:=SR2;HPPQ:=SR2;HTempo:=SR4;HLocL:=SR4;HLocR:=SR4;
 HSigN:=SR1;HSigD:=SR1;HFmt:=SR1;HSync:=SR1;HKey:=SR1;
 If HKey>=128 Then HKey:=HKey-256;
 For I:=0 To 3 Do GO[I]:=SR2S;
 For I:=0 To 3 Do GV[I]:=SR2S;
 NT:=SR2;
 If SEof Or (Id<>'NSON') Then Begin Close(SonF);Exit;End;
 InitSong;
 PPQ:=HPPQ;If (PPQ<>192) And (PPQ<>384) Then PPQ:=384;
 Tempo10k:=HTempo;SigN:=HSigN;SigD:=HSigD;KeyS:=HKey;FmtQ:=HFmt;
 SyncMode:=HSync;LocL:=HLocL;LocR:=HLocR;
 If (SigD<1) Or (SigN<1) Then Begin SigN:=4;SigD:=4;End;
 For I:=0 To 3 Do Begin GrvOff[I]:=GO[I];GrvVel[I]:=GV[I];End;
 Ok:=True;
 For I:=1 To NPAT Do Begin
  Pats[I].Name:=SRStr(12);Pats[I].Len:=SR2S;
  For K:=1 To 4 Do Pats[I].Rep[K]:=SR1;
 End;
 For I:=1 To NLYR Do TxtUsed[I]:=(SR1<>0);
 For I:=1 To NLYR Do TxtPool[I]:=SRStr(20);
 For K:=1 To NT Do
  If Ok Then Begin
   Idx:=SR2;
   If SEof Or (Idx<1) Or (Idx>MAXTRK) Then Ok:=False Else Begin
    P:=GetTrk(Idx);
    P^.P.Name:=SRStr(10);P^.P.Instr:=SRStr(10);
    P^.P.Port:=SR1;P^.P.Chan:=SR1;P^.P.Qua:=SR1;P^.P.Groove:=SR1;P^.P.Clef:=SR1;
    P^.P.Trans:=SR2S;P^.P.Vel:=SR2S;P^.P.Comp:=SR2S;P^.P.Delay:=SR2S;
    P^.P.Loop:=SR2S;P^.P.Lo:=SR2S;P^.P.Hi:=SR2S;P^.P.Shift:=SR2S;
    P^.P.Mute:=(SR1<>0);P^.P.Solo:=(SR1<>0);P^.P.Drum:=(SR1<>0);
    W:=SR2;
    If W>0 Then Begin
     New(P^.Ev);
     For I:=1 To W Do
      If I<=MAXEV Then Begin
       P^.Ev^[I].T:=SR4;P^.Ev^[I].Len:=SR4;
       P^.Ev^[I].Kind:=SR1;P^.Ev^[I].D1:=SR1;P^.Ev^[I].D2:=SR1;P^.Ev^[I].Sty:=SR1;
       P^.Ev^[I].Sel:=(SR1<>0);
      End Else For Idx:=1 To 13 Do Dummy:=SR1;
     If W>MAXEV Then W:=MAXEV;
     P^.Cnt:=W;
    End;
    If SEof Then Ok:=False;
    P^.Sel:=(W>0) And (Not P^.P.Drum);
   End;
  End;
 Close(SonF);
 LoadSong:=Ok;
 SongName:=Name;
 If Length(Name)>79 Then SongName:=ShortName(Name);
 SongNamed:=True;Modified:=False;
End;

{ ---- Standard MIDI File : ecriture ---- }

Var
 MBuf : PByteArr;
 MLen : Integer;
 Msg  : PMsgArr;

Procedure MPut(B: Integer);
Begin
 If MLen<16000 Then Begin MBuf^[MLen]:=B And $FF;Inc(MLen);End;
End;

Procedure MPutVLQ(V: LongInt);
Var Tmp: Array[1..5] Of Byte; N,I: Integer;
Begin
 N:=1;Tmp[1]:=V And $7F;V:=V Shr 7;
 While V>0 Do Begin Inc(N);Tmp[N]:=(V And $7F) Or $80;V:=V Shr 7;End;
 For I:=N DownTo 1 Do MPut(Tmp[I]);
End;

Procedure PutBE(Var F: File; V: LongInt; N: Integer);
Var I: Integer; B: Byte;
Begin
 For I:=N-1 DownTo 0 Do Begin
  B:=(V Shr (I*8)) And $FF;
  BlockWrite(F,B,1);
 End;
End;

Procedure FlushTrack(Var F: File);
Var S: String[4];
Begin
 S:='MTrk';
 BlockWrite(F,S[1],4);
 PutBE(F,MLen,4);
 BlockWrite(F,MBuf^,MLen);
 MLen:=0;
End;

Procedure MPutText(Ty: Integer; Const S: String);
Var I: Integer;
Begin
 MPut($FF);MPut(Ty);MPutVLQ(Length(S));
 For I:=1 To Length(S) Do MPut(Ord(S[I]));
End;

Function Log2(V: Integer): Integer;
Var N: Integer;
Begin
 N:=0;
 While V>1 Do Begin V:=V Shr 1;Inc(N);End;
 Log2:=N;
End;

Function SaveMidi(Const Name: String): Boolean;
Var F: File; NT,T,I,J,K,M: Integer; Tr: PTrk; US,Last: LongInt; Ch: Byte;
 XT: LongInt; XO,XS,XD1,XD2,XC: Byte; S: String[4];
Begin
 SaveMidi:=False;
 NT:=0;
 For T:=1 To TPP Do Begin
  Tr:=Trks[TI(CurPat,T)];
  If (Tr<>Nil) And (Tr^.Cnt>0) Then Inc(NT);
 End;
 If MBuf=Nil Then New(MBuf);
 If Msg=Nil Then New(Msg);

 Assign(F,Name);
 Rewrite(F,1);

 If IOResult<>0 Then Exit;
 S:='MThd';BlockWrite(F,S[1],4);
 PutBE(F,6,4);PutBE(F,1,2);PutBE(F,NT+1,2);PutBE(F,PPQ,2);
 { piste 0 : tempo, mesure, armure }
 MLen:=0;
 MPut(0);MPutText(3,ShortName(SongName));
 US:=Round(6.0E11/Tempo10k);
 MPut(0);MPut($FF);MPut($51);MPut(3);
 MPut((US Shr 16) And $FF);MPut((US Shr 8) And $FF);MPut(US And $FF);
 MPut(0);MPut($FF);MPut($58);MPut(4);MPut(SigN);MPut(Log2(SigD));MPut(24);MPut(8);
 MPut(0);MPut($FF);MPut($59);MPut(2);MPut(KeyS And $FF);MPut(0);
 MPut(0);MPut($FF);MPut($2F);MPut(0);
 FlushTrack(F);
 For T:=1 To TPP Do Begin
  Tr:=Trks[TI(CurPat,T)];
  If (Tr<>Nil) And (Tr^.Cnt>0) Then Begin
   Ch:=Tr^.P.Chan-1;
   M:=0;
   For I:=1 To Tr^.Cnt Do
    If M<1496 Then
     Case Tr^.Ev^[I].Kind Of
      EK_NOTE: Begin
        Inc(M);Msg^[M].T:=Tr^.Ev^[I].T+Tr^.Ev^[I].Len;Msg^[M].Ord1:=0;
        Msg^[M].S:=$80+Ch;Msg^[M].D1:=Tr^.Ev^[I].D1;Msg^[M].D2:=0;Msg^[M].Cnt:=3;
        Inc(M);Msg^[M].T:=Tr^.Ev^[I].T;Msg^[M].Ord1:=1;
        Msg^[M].S:=$90+Ch;Msg^[M].D1:=Tr^.Ev^[I].D1;Msg^[M].D2:=Tr^.Ev^[I].D2;
        Msg^[M].Cnt:=3;
       End;
      EK_CTRL,EK_BEND,EK_POLYP,EK_PROG,EK_CHANP: Begin
        Inc(M);Msg^[M].T:=Tr^.Ev^[I].T;Msg^[M].Ord1:=1;
        Case Tr^.Ev^[I].Kind Of
         EK_CTRL: Begin Msg^[M].S:=$B0+Ch;Msg^[M].Cnt:=3;End;
         EK_BEND: Begin Msg^[M].S:=$E0+Ch;Msg^[M].Cnt:=3;End;
         EK_POLYP: Begin Msg^[M].S:=$A0+Ch;Msg^[M].Cnt:=3;End;
         EK_PROG: Begin Msg^[M].S:=$C0+Ch;Msg^[M].Cnt:=2;End;
        Else Begin Msg^[M].S:=$D0+Ch;Msg^[M].Cnt:=2;End;
        End;
        Msg^[M].D1:=Tr^.Ev^[I].D1;Msg^[M].D2:=Tr^.Ev^[I].D2;
       End;
      EK_TEXT: If (Tr^.Ev^[I].Sty>=1) And (Tr^.Ev^[I].Sty<=NLYR) Then Begin
        Inc(M);Msg^[M].T:=Tr^.Ev^[I].T;Msg^[M].Ord1:=1;Msg^[M].S:=$FF;
        Msg^[M].Cnt:=0;Msg^[M].D1:=Tr^.Ev^[I].Sty;
        If Tr^.Ev^[I].D2=0 Then Msg^[M].D2:=5 Else Msg^[M].D2:=1;
       End;
     End;
   { tri par insertion (champ par champ : les copies d'enregistrements
     d'OS2PC ne sont pas sures) }
   For I:=2 To M Do Begin
    XT:=Msg^[I].T;XO:=Msg^[I].Ord1;XS:=Msg^[I].S;XD1:=Msg^[I].D1;XD2:=Msg^[I].D2;
    XC:=Msg^[I].Cnt;J:=I-1;
    While (J>=1) And ((Msg^[J].T>XT) Or ((Msg^[J].T=XT) And (Msg^[J].Ord1>XO))) Do Begin
     Msg^[J+1].T:=Msg^[J].T;Msg^[J+1].Ord1:=Msg^[J].Ord1;Msg^[J+1].S:=Msg^[J].S;
     Msg^[J+1].D1:=Msg^[J].D1;Msg^[J+1].D2:=Msg^[J].D2;Msg^[J+1].Cnt:=Msg^[J].Cnt;
     Dec(J);
    End;
    Msg^[J+1].T:=XT;Msg^[J+1].Ord1:=XO;Msg^[J+1].S:=XS;
    Msg^[J+1].D1:=XD1;Msg^[J+1].D2:=XD2;Msg^[J+1].Cnt:=XC;
   End;
   MLen:=0;
   MPut(0);MPutText(3,TrkName(TI(CurPat,T)));
   If (Not Tr^.P.Drum) And (Tr^.P.Instr<>'') Then
    For K:=1 To NINST Do
     If InstName[K]=Tr^.P.Instr Then Begin MPut(0);MPut($C0+Ch);MPut(InstProg[K]);End;
   Last:=0;
   For I:=1 To M Do Begin
    MPutVLQ(Msg^[I].T-Last);Last:=Msg^[I].T;
    If Msg^[I].S=$FF Then Begin
     MPutText(Msg^[I].D2,TxtPool[Msg^[I].D1]);
    End Else Begin
     MPut(Msg^[I].S);MPut(Msg^[I].D1);
     If Msg^[I].Cnt=3 Then MPut(Msg^[I].D2);
    End;
   End;
   MPut(0);MPut($FF);MPut($2F);MPut(0);
   FlushTrack(F);
  End;
 End;
 Close(F);
 SaveMidi:=(IOResult=0);
 K:=0;
End;

{ ---- Standard MIDI File : lecture ---- }

Var
 RF     : File;
 RBuf   : Array[0..1023] Of Byte;
 RPos,RLen : Integer;
 RCount : LongInt;
 REof   : Boolean;

Function RdB: Integer;
Var W: Word;
Begin
 If RPos>=RLen Then Begin

  BlockRead(RF,RBuf,1024,W);

  If IOResult<>0 Then W:=0;
  RLen:=W;RPos:=0;
  If W=0 Then Begin REof:=True;RdB:=0;Exit;End;
 End;
 RdB:=RBuf[RPos];Inc(RPos);Inc(RCount);
End;

Function RdBE(N: Integer): LongInt;
Var V: LongInt; I: Integer;
Begin
 V:=0;
 For I:=1 To N Do V:=V*256+RdB;
 RdBE:=V;
End;

Function RdVLQ: LongInt;
Var V: LongInt; B,N: Integer;
Begin
 V:=0;N:=0;
 Repeat
  B:=RdB;V:=V*128+(B And $7F);Inc(N);
 Until ((B And $80)=0) Or (N>=5) Or REof;
 RdVLQ:=V;
End;

{ variables de LoadMidi partagees avec SlotOf (fonction locale de la
  version DOS) }
Var
 LmNSlot : Integer;
 LmSlotTrk,LmSlotCh,LmProg : Array[1..TPP] Of Integer;
 LmHold : String[10];
 LmTr : PTrk;

Function SlotOf(Trk,C: Integer): Integer;
Var J: Integer;
Begin
 SlotOf:=0;
 For J:=1 To LmNSlot Do
  If (LmSlotTrk[J]=Trk) And (LmSlotCh[J]=C) Then Begin SlotOf:=J;Exit;End;
 If LmNSlot<TPP Then Begin
  Inc(LmNSlot);LmSlotTrk[LmNSlot]:=Trk;LmSlotCh[LmNSlot]:=C;LmProg[LmNSlot]:=-1;
  LmTr:=GetTrk(TI(CurPat,LmNSlot));
  LmTr^.P.Chan:=C+1;LmTr^.P.Drum:=(C=9);
  If C=9 Then LmTr^.P.Instr:='Drums';
  LmTr^.P.Name:=LmHold;
  SlotOf:=LmNSlot;
 End;
End;


Function LoadMidi(Const Name: String): Boolean;
Var Fmt,NTrk,FPPQ,TrkN,K,I,B,St,Run,Ty,Ch,D1,D2,Slot: Integer;
 Len,CEnd,Abs,Tm,US,MaxT: LongInt; S: String;
 Ok,GotTempo: Boolean; Pend: Integer; Id: String[4];
 Fnd: Boolean; E: Integer; Sm,Nn: LongInt;


Begin
 LoadMidi:=False;

 Assign(RF,Name);
 Reset(RF,1);

 If IOResult<>0 Then Exit;
 RPos:=0;RLen:=0;REof:=False;RCount:=0;
 Id:='';
 For I:=1 To 4 Do Id:=Id+Chr(RdB);
 If Id<>'MThd' Then Begin Close(RF);Exit;End;
 Len:=RdBE(4);Fmt:=RdBE(2);NTrk:=RdBE(2);FPPQ:=RdBE(2);
 For I:=7 To Len Do B:=RdB;
 If FPPQ<=0 Then Begin Close(RF);Exit;End;
 { vider le pattern courant }
 For I:=1 To TPP Do
  If Trks[TI(CurPat,I)]<>Nil Then Begin
   FreeTrkEv(Trks[TI(CurPat,I)]);Dispose(Trks[TI(CurPat,I)]);Trks[TI(CurPat,I)]:=Nil;
  End;
 LmNSlot:=0;GotTempo:=False;MaxT:=0;Ok:=True;
 For TrkN:=1 To NTrk Do
  If Ok And Not REof Then Begin
   Id:='';
   For I:=1 To 4 Do Id:=Id+Chr(RdB);
   Len:=RdBE(4);
   If Id<>'MTrk' Then Begin
    For K:=1 To Len Do B:=RdB;
   End Else Begin
    RCount:=0;Abs:=0;Run:=0;Pend:=-1;LmHold:='';Slot:=0;
    While (RCount<Len) And Not REof Do Begin
     Abs:=Abs+RdVLQ;
     Tm:=(Abs*PPQ) Div FPPQ;
     B:=RdB;
     If B>=$80 Then Begin St:=B;If St<$F0 Then Run:=St;End
     Else Begin St:=Run;Pend:=B;End;
     If St=$FF Then Begin
      Ty:=RdB;CEnd:=RdVLQ;S:='';
      For K:=1 To CEnd Do Begin
       B:=RdB;
       If Length(S)<20 Then S:=S+Chr(B);
      End;
      Case Ty Of
       3: LmHold:=Copy(S,1,10);
       $51: If (Not GotTempo) And (Length(S)=3) Then Begin
             US:=Ord(S[1])*65536+Ord(S[2])*256+Ord(S[3]);
             If US>0 Then Begin Tempo10k:=Round(6.0E9/US)*100;GotTempo:=True;End;
            End;
       $58: If Length(S)>=2 Then Begin
             SigN:=Ord(S[1]);SigD:=1 Shl Ord(S[2]);
             If (SigN<1) Or (SigD<1) Or (SigD>32) Then Begin SigN:=4;SigD:=4;End;
            End;
       $59: If Length(S)>=1 Then Begin
             KeyS:=Ord(S[1]);If KeyS>127 Then KeyS:=KeyS-256;
             KeyS:=Integer(Clamp(KeyS,-7,7));
            End;
       1,5: If Slot>0 Then Begin
             E:=NewText(S);
             If E>0 Then Begin
              K:=AddEv(TI(CurPat,Slot),Tm,0,EK_TEXT,0,0);
              If K>0 Then Begin
               GetTrk(TI(CurPat,Slot))^.Ev^[K].Sty:=E;
               If Ty=5 Then GetTrk(TI(CurPat,Slot))^.Ev^[K].D2:=0
               Else GetTrk(TI(CurPat,Slot))^.Ev^[K].D2:=1;
              End;
             End;
            End;
      End;
     End Else If (St=$F0) Or (St=$F7) Then Begin
      CEnd:=RdVLQ;
      For K:=1 To CEnd Do B:=RdB;
     End Else Begin
      Ch:=St And 15;
      If Pend>=0 Then Begin D1:=Pend;Pend:=-1;End Else D1:=RdB;
      D2:=0;
      If ((St And $F0)<>$C0) And ((St And $F0)<>$D0) Then D2:=RdB;
      Slot:=SlotOf(TrkN,Ch);
      If Slot>0 Then Begin
       Case St Shr 4 Of
        9: If D2>0 Then Begin
            K:=AddEv(TI(CurPat,Slot),Tm,0,EK_NOTE,D1,D2);
           End Else Fnd:=True;
        8: Fnd:=True;
        11: AddEv(TI(CurPat,Slot),Tm,0,EK_CTRL,D1,D2);
        12: Begin AddEv(TI(CurPat,Slot),Tm,0,EK_PROG,D1,0);
             If LmProg[Slot]<0 Then LmProg[Slot]:=D1;End;
        13: AddEv(TI(CurPat,Slot),Tm,0,EK_CHANP,D1,0);
        14: AddEv(TI(CurPat,Slot),Tm,0,EK_BEND,D1,D2);
        10: AddEv(TI(CurPat,Slot),Tm,0,EK_POLYP,D1,D2);
       End;
       If ((St Shr 4)=8) Or (((St Shr 4)=9) And (D2=0)) Then Begin
        { fermeture de note : derniere note de meme hauteur sans duree }
        LmTr:=GetTrk(TI(CurPat,Slot));
        K:=LmTr^.Cnt;Fnd:=False;
        While (K>=1) And Not Fnd Do Begin
         If (LmTr^.Ev^[K].Kind=EK_NOTE) And (LmTr^.Ev^[K].D1=D1) And
            (LmTr^.Ev^[K].Len=0) Then Begin
          LmTr^.Ev^[K].Len:=Tm-LmTr^.Ev^[K].T;
          If LmTr^.Ev^[K].Len<1 Then LmTr^.Ev^[K].Len:=1;
          Fnd:=True;
         End;
         Dec(K);
        End;
       End;
       If Tm>MaxT Then MaxT:=Tm;
      End;
     End;
    End;
   End;
  End;
 Close(RF);
 { notes sans fin : duree par defaut ; instruments }
 For I:=1 To TPP Do Begin
  LmTr:=Trks[TI(CurPat,I)];
  If LmTr<>Nil Then Begin
   For K:=1 To LmTr^.Cnt Do
    If (LmTr^.Ev^[K].Kind=EK_NOTE) And (LmTr^.Ev^[K].Len=0) Then LmTr^.Ev^[K].Len:=PPQ Div 4;
   If (LmTr^.P.Instr='') And (I<=LmNSlot) And (LmProg[I]>=0) Then Begin
    For K:=1 To NINST Do If InstProg[K]=LmProg[I] Then LmTr^.P.Instr:=InstName[K];
   End;
   If LmTr^.P.Name='' Then LmTr^.P.Name:=Copy(TrkName(TI(CurPat,I)),1,10);
   LmTr^.Sel:=(Not LmTr^.P.Drum) And (LmTr^.Cnt>0);
   Sm:=0;Nn:=0;
   For K:=1 To LmTr^.Cnt Do
    If LmTr^.Ev^[K].Kind=EK_NOTE Then Begin Sm:=Sm+LmTr^.Ev^[K].D1;Inc(Nn);End;
   If (Nn>0) And (Sm Div Nn<57) Then LmTr^.P.Clef:=1;
  End;
 End;
 Pats[CurPat].Len:=Integer(Clamp(MaxT Div BarTicks+1,1,255));
 LocL:=0;LocR:=PatTicks(CurPat);PosTick:=0;ViewBar:=0;CurTrk:=1;CurEv:=1;
 UndoValid:=False;
 LoadMidi:=(LmNSlot>0);
 Modified:=True;
End;

{ ---- Morceau de demonstration : Ode a la joie (Beethoven, domaine public) }

Procedure DemoNote(TIdx: Integer; Var T: LongInt; Pitch: Integer; Dur16: Integer;
                   Vel: Integer);
Var L: LongInt;
Begin
 L:=LongInt(Dur16)*(PPQ Div 4);
 If Pitch>0 Then AddEv(TIdx,T,L-L Div 16,EK_NOTE,Pitch,Vel);
 T:=T+L;
End;

Procedure BuildDemo;
Const
 Mel : Array[1..30] Of Byte = (64,64,65,67,67,65,64,62,60,60,62,64,64,62,62,
                               64,64,65,67,67,65,64,62,60,60,62,64,62,60,60);
 MelD: Array[1..30] Of Byte = (4,4,4,4,4,4,4,4,4,4,4,4,6,2,8,
                               4,4,4,4,4,4,4,4,4,4,4,4,6,2,8);
 Lyr : Array[1..30] Of String[8] = ('Joy','ful','joy','ful','we','a-','dore','thee',
  'God','of','glo','ry','Lord','of','love','Hearts','unfold','like','flow''rs',
  'be-','fore','thee','o-','pening','to','the','sun','a-','bove','.');
 Bass: Array[1..8] Of Byte = (48,55,48,55,53,55,48,55);
Var T: LongInt; I,K,TIm,TIb,TId,B: Integer; E: Integer; Tr: PTrk;
Begin
 InitSong;
 Pats[1].Name:='Ode to Joy';Pats[1].Len:=8;
 Tempo10k:=1100000;KeyS:=0;
 { melodie }
 TIm:=TI(1,1);
 Tr:=GetTrk(TIm);Tr^.P.Name:='Melody';Tr^.P.Instr:='Flute';Tr^.P.Chan:=1;Tr^.Sel:=True;
 T:=0;
 For I:=1 To 30 Do Begin
  DemoNote(TIm,T,Mel[I],MelD[I],90);
 End;
 T:=0;
 For I:=1 To 30 Do Begin
  E:=NewText(Lyr[I]);
  If E>0 Then Begin
   K:=AddEv(TIm,T,0,EK_TEXT,0,0);
   If K>0 Then GetTrk(TIm)^.Ev^[K].Sty:=E;
  End;
  T:=T+LongInt(MelD[I])*(PPQ Div 4);
 End;
 For K:=0 To 31 Do Begin
  If K<16 Then E:=70+K*3 Else E:=118-(K-16)*3;
  AddEv(TIm,K*PPQ,0,EK_CTRL,7,E);
 End;
 AddEv(TIm,0,PPQ*4,EK_SYM,5,0);
 AddEv(TIm,PPQ*8,PPQ*4,EK_SYM,7,0);
 AddEv(TIm,PPQ*12,0,EK_SYM,9,0);
 { basse }
 TIb:=TI(1,2);
 Tr:=GetTrk(TIb);Tr^.P.Name:='Bass';Tr^.P.Instr:='Bass';Tr^.P.Chan:=2;Tr^.P.Clef:=1;Tr^.Sel:=True;
 T:=0;
 For B:=0 To 7 Do Begin
  DemoNote(TIb,T,Bass[B+1]-12,8,80);
  DemoNote(TIb,T,0,8,0);
 End;
 { batterie }
 TId:=TI(1,10);
 Tr:=GetTrk(TId);Tr^.P.Name:='Drums';Tr^.P.Instr:='Drums';Tr^.P.Chan:=10;Tr^.P.Drum:=True;
 T:=0;
 For B:=0 To 31 Do Begin
  AddEv(TId,T,PPQ Div 4,EK_NOTE,42,70);
  If (B Mod 2)=0 Then AddEv(TId,T,PPQ Div 4,EK_NOTE,42,95);
  If (B Mod 4)=0 Then AddEv(TId,T,PPQ Div 4,EK_NOTE,36,110);
  If (B Mod 4)=2 Then AddEv(TId,T,PPQ Div 4,EK_NOTE,38,100);
  T:=T+PPQ;
 End;
 GetTrk(TIm)^.P.Qua:=0;
 CurTrk:=1;CurEv:=1;ViewBar:=0;
 LocL:=0;LocR:=PatTicks(1);
 SongName:='ODE.SON';Modified:=False;
End;

{ ====================================================================== }
{                          COMMANDES                                     }
{ ====================================================================== }

Const
 OPTFILE = 'NOTATOR.OPT';

Function TrkIdx: Integer;
Begin
 TrkIdx:=TI(CurPat,CurTrk);
End;

Procedure NotImplemented;
Begin
 MsgBox('NOTATOR',T3('Not available in this version.',
   'Non disponible dans cette version.','In dieser Version nicht verf'#129'gbar.'));
End;

Procedure Info(Const En,Fr,De: String);
Begin
 MsgBox('NOTATOR',T3(En,Fr,De));
End;

{ ---- transport ---- }

Procedure SendInstruments;
Var I: Integer; K: Integer;
Begin
 For I:=1 To MAXTRK Do
  If (Trks[I]<>Nil) And (Trks[I]^.P.Instr<>'') And (Not Trks[I]^.P.Drum) Then
   For K:=1 To NINST Do
    If InstName[K]=Trks[I]^.P.Instr Then
     MidiSend(Trks[I]^.P.Port,$C0+Trks[I]^.P.Chan-1,InstProg[K],0,2);
End;

Procedure CmdStart;
Begin
 If Playing Then Begin StopPlay;Exit;End;
 SendInstruments;
 StartPlay(LocL);
End;

Procedure CmdCont;
Begin
 If Playing Then Exit;
 SendInstruments;
 StartPlay(PosTick);
End;

Procedure CmdStop;
Begin
 StopPlay;
End;

Procedure CmdRecord;
Var I: Integer;
Begin
 If Recording Then Begin StopPlay;Exit;End;
 If Playing Then StopPlay;
 GetTrk(TrkIdx);
 SaveUndo(TrkIdx);
 RecTI:=TrkIdx;
 For I:=0 To 127 Do RecStart[I]:=-1;
 Recording:=True;
 SendInstruments;
 StartPlay(LocL);
End;

Procedure CmdDrop;
Begin
 TakePending:=False;
 UndoValid:=False;
 NeedDraw:=True;
End;

Procedure SetPos(T: LongInt);
Begin
 If T<0 Then T:=0;
 PosTick:=T;
 If Playing Then Begin PlaySeek(T);RemT:=0;LastCs:=NowCs;End;
 NeedDraw:=True;
End;

Procedure CmdGoto;
Var B,Bt,Sx,Tk: LongInt;
Begin
 TickToBBT(CurPos,B,Bt,Sx,Tk);
 FormLbl[1]:=T3('Bar','Mesure','Takt');FormVal[1]:=IntStr(B);
 FormLbl[2]:=T3('Beat','Temps','Schlag');FormVal[2]:=IntStr(Bt);
 FormLbl[3]:='1/16';FormVal[3]:=IntStr(Sx);
 FormLbl[4]:='Tick';FormVal[4]:=IntStr(Tk);
 FormFW:=6;
 If Not FormBox(T3('Go to position','Aller '#133' la position','Gehe zu Position'),4) Then Exit;
 SetPos(BBTToTick(Max2(1,ToInt(FormVal[1])),Max2(1,ToInt(FormVal[2])),
   Max2(1,ToInt(FormVal[3])),Max2(1,ToInt(FormVal[4]))));
 ViewBar:=PosTick Div BarTicks;
End;

Function ParseTempo(Const S: String; Var V: LongInt): Boolean;
Var P,I: Integer; Fr: String; N: LongInt;
Begin
 ParseTempo:=False;
 P:=Pos('.',S);
 If P=0 Then P:=Pos(',',S);
 If P=0 Then Begin N:=ToInt(S);Fr:='0000';End
 Else Begin N:=ToInt(Copy(S,1,P-1));Fr:=Copy(S,P+1,4);End;
 While Length(Fr)<4 Do Fr:=Fr+'0';
 V:=N*10000+ToInt(Fr);
 If (V<300000) Or (V>3000000) Then Exit;
 ParseTempo:=True;
End;

Procedure CmdTempo;
Var S: String; V: LongInt;
Begin
 S:=TempoStr;
 If InputBox('TEMPO','BPM (30-300)',S,10) Then
  If ParseTempo(S,V) Then Begin Tempo10k:=V;Modified:=True;End
  Else Info('Invalid tempo.','Tempo invalide.','Ung'#129'ltiges Tempo.');
 NeedDraw:=True;
End;

Procedure CmdSongSettings;
Var V: LongInt; N,D,K: Integer;
Begin
 FormLbl[1]:='Tempo (BPM)';FormVal[1]:=TempoStr;
 FormLbl[2]:=T3('Beats per bar','Temps par mesure','Schl'#132'ge pro Takt');
 FormVal[2]:=IntStr(SigN);
 FormLbl[3]:=T3('Beat unit (1-32)','Unit'#130' (1-32)','Schlagwert (1-32)');
 FormVal[3]:=IntStr(SigD);
 FormLbl[4]:=T3('Key (-7..7)','Armure (-7..7)','Tonart (-7..7)');
 FormVal[4]:=IntStr(KeyS);
 FormFW:=10;
 If Not FormBox(T3('Song settings','Param'#138'tres du morceau','Lied-Einstellungen'),4) Then Exit;
 If ParseTempo(FormVal[1],V) Then Tempo10k:=V;
 N:=Integer(Clamp(ToInt(FormVal[2]),1,32));
 D:=Integer(Clamp(ToInt(FormVal[3]),1,32));
 K:=1;
 While (K*2<=D) Do K:=K*2;
 SigN:=N;SigD:=K;
 KeyS:=Integer(Clamp(ToInt(FormVal[4]),-7,7));
 Modified:=True;NeedDraw:=True;
End;

Procedure CmdSignature;
Begin
 CmdSongSettings;
End;

Procedure CmdSync;
Begin
 LstN:=3;LstItem[1]:='intern';LstItem[2]:='MIDI';LstItem[3]:='SMPTE';
 SyncMode:=Max2(0,ChooseBox('SYNC',SyncMode+1)-1);
 NeedDraw:=True;
End;

Procedure CmdFormat;
Var I,R: Integer;
Begin
 LstN:=NQUA;
 For I:=1 To NQUA Do LstItem[I]:=QuaLbl[I];
 R:=ChooseBox('FORMAT',FmtQ);
 If R>0 Then FmtQ:=R;
 NeedDraw:=True;
End;

Procedure CmdSyncDel;
Var V: LongInt;
Begin
 V:=SyncDel;
 If AskNum('SyncDEL','ms',V,0,999) Then SyncDel:=V;
 NeedDraw:=True;
End;

{ ---- parametres de piste ---- }

Procedure ForTracks(Which: Integer; V: LongInt);
Var T: Integer; Tr: PTrk;
Begin
 For T:=1 To TPP Do Begin
  Tr:=GetTrk(TI(CurPat,T));
  If Tr^.Sel Or (T=CurTrk) Then
   Case Which Of
    3: Tr^.P.Qua:=V;
    4: Tr^.P.Groove:=V;
    5: Tr^.P.Trans:=V;
    6: Tr^.P.Vel:=V;
    7: Tr^.P.Comp:=V;
    8: Tr^.P.Loop:=V;
    9: Tr^.P.Delay:=V;
    10: Tr^.P.Lo:=V;
    11: Tr^.P.Hi:=V;
    12: Tr^.P.Shift:=V;
   End;
 End;
 Modified:=True;
End;

Procedure CmdQuaValue;
Var I,R: Integer;
Begin
 LstN:=NQUA+1;
 For I:=0 To NQUA Do LstItem[I+1]:=QuaLbl[I];
 R:=ChooseBox(T3('Quantize value','Valeur de quantification','Quantisierungswert'),
   CT^.P.Qua+1);
 If R>0 Then ForTracks(3,R-1);
 NeedDraw:=True;
End;

Procedure CmdChannel;
Var Tr: PTrk; P: String;
Begin
 Tr:=CT;
 FormLbl[1]:=T3('Port (A-F)','Port (A-F)','Port (A-F)');FormVal[1]:=Chr(65+Tr^.P.Port);
 FormLbl[2]:=T3('Channel (1-16)','Canal (1-16)','Kanal (1-16)');
 FormVal[2]:=IntStr(Tr^.P.Chan);
 FormFW:=4;
 If Not FormBox(T3('Port and channel','Port et canal','Port und Kanal'),2) Then Exit;
 P:=Upper(FormVal[1]);
 If (P<>'') And (P[1]>='A') And (P[1]<='F') Then Tr^.P.Port:=Ord(P[1])-65;
 Tr^.P.Chan:=Integer(Clamp(ToInt(FormVal[2]),1,16));
 If (Tr^.P.Chan=10) And (Tr^.P.Instr='') Then Begin Tr^.P.Instr:='Drums';Tr^.P.Drum:=True;End;
 Modified:=True;NeedDraw:=True;
End;

Procedure EditPar(I: Integer);
Var Tr: PTrk; V: LongInt; Ok: Boolean;
Begin
 Tr:=CT;
 Case I Of
  1: Begin
      V:=CurTrk;
      If AskNum('TRACK',T3('Track (1-16)','Piste (1-16)','Spur (1-16)'),V,1,16) Then Begin
       CurTrk:=V;CurEv:=1;End;
     End;
  2: CmdChannel;
  3: CmdQuaValue;
  4: Begin
      If Tr^.P.Groove=0 Then ForTracks(4,1) Else ForTracks(4,0);
     End;
  5: Begin V:=Tr^.P.Trans;
      If AskNum('TRANSPOSE',T3('Semitones','Demi-tons','Halbt'#148'ne'),V,-48,48) Then ForTracks(5,V);End;
  6: Begin V:=Tr^.P.Vel;
      If AskNum('VELOCITY',T3('Offset','D'#130'calage','Offset'),V,-127,127) Then ForTracks(6,V);End;
  7: Begin V:=Tr^.P.Comp;
      If AskNum('COMPRESS','%',V,0,300) Then ForTracks(7,V);End;
  8: Begin V:=Tr^.P.Loop;
      If AskNum('LOOP',T3('Bars (0=off)','Mesures (0=non)','Takte (0=aus)'),V,0,64) Then ForTracks(8,V);End;
  9: Begin V:=Tr^.P.Delay;
      If AskNum('DELAY','Ticks',V,-960,960) Then ForTracks(9,V);End;
  10: Begin V:=Tr^.P.Lo;
      If AskNum('LOWEST',T3('Note (0-127)','Note (0-127)','Note (0-127)'),V,0,127) Then ForTracks(10,V);End;
  11: Begin V:=Tr^.P.Hi;
      If AskNum('HIGHEST',T3('Note (0-127)','Note (0-127)','Note (0-127)'),V,0,127) Then ForTracks(11,V);End;
  12: Begin V:=Tr^.P.Shift;
      If AskNum('SHIFT',T3('Bars','Mesures','Takte'),V,-16,16) Then ForTracks(12,V);End;
 End;
 NeedDraw:=True;
End;

Procedure CmdResetPar;
Begin
 ResetTrkPar(CT);
 Modified:=True;NeedDraw:=True;
End;

Procedure CmdTrackSettings;
Var Tr: PTrk; P: String;
Begin
 Tr:=CT;
 FormLbl[1]:=T3('Name','Nom','Name');FormVal[1]:=Tr^.P.Name;
 FormLbl[2]:=T3('Instrument','Instrument','Instrument');FormVal[2]:=Tr^.P.Instr;
 FormLbl[3]:='Port (A-F)';FormVal[3]:=Chr(65+Tr^.P.Port);
 FormLbl[4]:=T3('Channel (1-16)','Canal (1-16)','Kanal (1-16)');FormVal[4]:=IntStr(Tr^.P.Chan);
 FormLbl[5]:=T3('Clef 0 G 1 F 2 C 3 T','Cl'#130' 0 Sol 1 Fa 2 Ut 3 Te',
   'Schl'#129'ssel 0G 1F 2C 3T');
 FormVal[5]:=IntStr(Tr^.P.Clef);
 FormFW:=10;
 If Not FormBox(T3('Track settings','Param'#138'tres de piste','Spur-Einstellungen'),5) Then Exit;
 Tr^.P.Name:=Copy(FormVal[1],1,10);
 Tr^.P.Instr:=Copy(FormVal[2],1,10);
 P:=Upper(FormVal[3]);
 If (P<>'') And (P[1]>='A') And (P[1]<='F') Then Tr^.P.Port:=Ord(P[1])-65;
 Tr^.P.Chan:=Integer(Clamp(ToInt(FormVal[4]),1,16));
 Tr^.P.Clef:=Integer(Clamp(ToInt(FormVal[5]),0,3));
 Tr^.P.Drum:=(Upper(Tr^.P.Instr)='DRUMS') Or (Tr^.P.Chan=10);
 Modified:=True;NeedDraw:=True;
End;

Procedure CmdInstrument;
Var I,R: Integer;
Begin
 LstN:=NINST;
 For I:=1 To NINST Do LstItem[I]:=InstName[I];
 R:=ChooseBox(T3('Instrument','Instrument','Instrument'),1);
 If R>0 Then Begin
  CT^.P.Instr:=InstName[R];
  CT^.P.Drum:=(R=1);
  Modified:=True;
 End;
 NeedDraw:=True;
End;

Procedure CmdClef;
Begin
 LstN:=4;
 LstItem[1]:=T3('Treble (G)','Sol','Violin (G)');
 LstItem[2]:=T3('Bass (F)','Fa','Bass (F)');
 LstItem[3]:=T3('Alto (C)','Ut 3','Alt (C)');
 LstItem[4]:=T3('Tenor (C)','Ut 4','Tenor (C)');
 Modified:=True;
 CT^.P.Clef:=Max2(0,ChooseBox(T3('Clef','Cl'#130,'Schl'#129'ssel'),CT^.P.Clef+1)-1);
 NeedDraw:=True;
End;

{ ---- groove ---- }

Procedure CmdGrooveDesign;
Var I: Integer;
Begin
 For I:=0 To 3 Do Begin
  FormLbl[I+1]:=T3('Step offset %','D'#130'calage pas %','Schritt-Offset %')+' '+IntStr(I+1);
  FormVal[I+1]:=IntStr(GrvOff[I]);
  FormLbl[I+5]:=T3('Step accent','Accent pas','Schritt-Akzent')+' '+IntStr(I+1);
  FormVal[I+5]:=IntStr(GrvVel[I]);
 End;
 FormFW:=6;
 If Not FormBox(T3('Groove design','Conception du groove','Groove-Design'),8) Then Exit;
 For I:=0 To 3 Do Begin
  GrvOff[I]:=Integer(Clamp(ToInt(FormVal[I+1]),-49,49));
  GrvVel[I]:=Integer(Clamp(ToInt(FormVal[I+5]),-60,60));
 End;
 Modified:=True;NeedDraw:=True;
End;

Procedure CmdLearnGroove;
Var Tr: PTrk; I,S: Integer; G,Stp,D: LongInt; Sum,VS: Array[0..3] Of LongInt;
 Cnt: Array[0..3] Of Integer; Tot,TotN: LongInt; T: Integer;
Begin
 Tr:=CT;
 If (Tr^.Ev=Nil) Or (Tr^.Cnt=0) Then Begin
  Info('No events in the track.','Aucun '#130'v'#130'nement dans la piste.','Keine Ereignisse in der Spur.');Exit;End;
 G:=QuaTicks(Tr^.P.Qua);
 If G=0 Then G:=QuaTicks(FmtQ);
 If G=0 Then G:=PPQ Div 4;
 For S:=0 To 3 Do Begin Sum[S]:=0;VS[S]:=0;Cnt[S]:=0;End;
 Tot:=0;TotN:=0;
 For I:=1 To Tr^.Cnt Do
  If Tr^.Ev^[I].Kind=EK_NOTE Then Begin
   Stp:=(Tr^.Ev^[I].T+G Div 2) Div G;
   D:=Tr^.Ev^[I].T-Stp*G;
   S:=Stp And 3;
   Sum[S]:=Sum[S]+(D*100) Div G;
   VS[S]:=VS[S]+Tr^.Ev^[I].D2;
   Inc(Cnt[S]);Tot:=Tot+Tr^.Ev^[I].D2;Inc(TotN);
  End;
 If TotN=0 Then Exit;
 For S:=0 To 3 Do
  If Cnt[S]>0 Then Begin
   GrvOff[S]:=Integer(Clamp(Sum[S] Div Cnt[S],-49,49));
   GrvVel[S]:=Integer(Clamp(VS[S] Div Cnt[S]-Tot Div TotN,-60,60));
  End;
 For T:=1 To TPP Do
  If Trks[TI(CurPat,T)]<>Nil Then Trks[TI(CurPat,T)]^.P.Groove:=1;
 Modified:=True;
 Info('Groove learned from the track and applied to the pattern.',
  'Groove appris de la piste et appliqu'#130' au pattern.',
  'Groove von der Spur gelernt und auf das Pattern angewendet.');
 NeedDraw:=True;
End;

Procedure CmdClearGroove;
Var I,T: Integer;
Begin
 For I:=0 To 3 Do Begin GrvOff[I]:=0;GrvVel[I]:=0;End;
 For T:=1 To TPP Do
  If Trks[TI(CurPat,T)]<>Nil Then Trks[TI(CurPat,T)]^.P.Groove:=0;
 NeedDraw:=True;
End;

{ ---- edition ---- }

Function AnySel(Tr: PTrk): Boolean;
Begin
 AnySel:=SelCount(Tr)>0;
End;

Procedure CmdTransposeSel;
Var Tr: PTrk; V: LongInt; I: Integer; All: Boolean;
Begin
 Tr:=CT;
 If Tr^.Ev=Nil Then Exit;
 V:=0;
 If Not AskNum(T3('Transpose','Transposer','Transponieren'),
   T3('Semitones','Demi-tons','Halbt'#148'ne'),V,-48,48) Then Exit;
 SaveUndo(TrkIdx);
 All:=Not AnySel(Tr);
 For I:=1 To Tr^.Cnt Do
  If (All Or Tr^.Ev^[I].Sel) And (Tr^.Ev^[I].Kind=EK_NOTE) Then
   Tr^.Ev^[I].D1:=Integer(Clamp(Tr^.Ev^[I].D1+V,0,127));
 Modified:=True;NeedDraw:=True;
End;

Procedure CmdChangeVel;
Var Tr: PTrk; V: LongInt; I: Integer; All: Boolean;
Begin
 Tr:=CT;
 If Tr^.Ev=Nil Then Exit;
 V:=0;
 If Not AskNum(T3('Velocity','V'#130'locit'#130,'Anschlag'),
   T3('Change by','Variation','Aenderung'),V,-127,127) Then Exit;
 SaveUndo(TrkIdx);
 All:=Not AnySel(Tr);
 For I:=1 To Tr^.Cnt Do
  If (All Or Tr^.Ev^[I].Sel) And (Tr^.Ev^[I].Kind=EK_NOTE) Then
   Tr^.Ev^[I].D2:=Integer(Clamp(Tr^.Ev^[I].D2+V,1,127));
 Modified:=True;NeedDraw:=True;
End;

Procedure CmdChangeLen;
Var Tr: PTrk; V: LongInt; I: Integer; All: Boolean;
Begin
 Tr:=CT;
 If Tr^.Ev=Nil Then Exit;
 V:=100;
 If Not AskNum(T3('Length','Dur'#130'e','L'#132'nge'),'%',V,10,500) Then Exit;
 SaveUndo(TrkIdx);
 All:=Not AnySel(Tr);
 For I:=1 To Tr^.Cnt Do
  If (All Or Tr^.Ev^[I].Sel) And (Tr^.Ev^[I].Kind=EK_NOTE) Then
   Tr^.Ev^[I].Len:=Max2(1,(Tr^.Ev^[I].Len*V) Div 100);
 Modified:=True;NeedDraw:=True;
End;

{ Quantification definitive }
Procedure QuantizeTrack(OnlySel: Boolean; Q: Integer);
Var Tr: PTrk; I: Integer; G,L: LongInt; Grv: Boolean;
Begin
 Tr:=CT;
 If (Tr^.Ev=Nil) Or (Tr^.Cnt=0) Then Exit;
 G:=QuaTicks(Q);
 If G=0 Then Exit;
 Grv:=Tr^.P.Groove<>0;
 SaveUndo(TrkIdx);
 For I:=1 To Tr^.Cnt Do
  If (Not OnlySel) Or Tr^.Ev^[I].Sel Then Begin
   If Tr^.Ev^[I].Kind=EK_NOTE Then Begin
    L:=((Tr^.Ev^[I].Len+G Div 2) Div G)*G;
    If L<G Then L:=G;
    Tr^.Ev^[I].Len:=L;
    If Grv Then Tr^.Ev^[I].D2:=EffVel(Tr,Tr^.Ev^[I].D2,(Tr^.Ev^[I].T+G Div 2) Div G);
   End;
   Tr^.Ev^[I].T:=QuantT(Tr^.Ev^[I].T,G,Grv);
  End;
 SortTrk(Tr);
 Modified:=True;NeedDraw:=True;
End;

Procedure CmdDoQuantize;
Var Tr: PTrk;
Begin
 Tr:=CT;
 If Tr^.P.Qua=0 Then Begin
  Info('Set a quantize value first.','D'#130'finissez d''abord une quantification.',
    'Zuerst einen Quantisierungswert w'#132'hlen.');
  Exit;
 End;
 QuantizeTrack(False,Tr^.P.Qua);
 Tr^.P.Qua:=0;Tr^.P.Groove:=0;
 NeedDraw:=True;
End;

Procedure CmdQuantSel;
Var Q: Integer;
Begin
 Q:=CT^.P.Qua;If Q=0 Then Q:=FmtQ;
 QuantizeTrack(True,Q);
End;

Procedure CmdCopyEv(Cut: Boolean);
Var Tr: PTrk; I: Integer; MinT: LongInt;
Begin
 Tr:=CT;
 If (Tr^.Ev=Nil) Or (SelCount(Tr)=0) Then Begin
  Info('Select events first.','S'#130'lectionnez d''abord des '#130'v'#130'nements.',
    'Zuerst Ereignisse ausw'#132'hlen.');Exit;End;
 If ClipBuf=Nil Then New(ClipBuf);
 ClipCnt:=0;MinT:=2000000000;
 For I:=1 To Tr^.Cnt Do
  If Tr^.Ev^[I].Sel Then Begin
   Inc(ClipCnt);ClipBuf^[ClipCnt]:=Tr^.Ev^[I];
   If Tr^.Ev^[I].T<MinT Then MinT:=Tr^.Ev^[I].T;
  End;
 For I:=1 To ClipCnt Do Begin
  ClipBuf^[I].T:=ClipBuf^[I].T-MinT;ClipBuf^[I].Sel:=False;End;
 If Cut Then Begin
  SaveUndo(TrkIdx);
  I:=1;
  While I<=Tr^.Cnt Do
   If Tr^.Ev^[I].Sel Then DelEv(Tr,I) Else Inc(I);
  CurEv:=1;
 End;
 NeedDraw:=True;
End;

Procedure CmdPaste;
Var I,K: Integer;
Begin
 If (ClipBuf=Nil) Or (ClipCnt=0) Then Begin
  Info('Clipboard empty.','Presse-papiers vide.','Zwischenablage leer.');Exit;End;
 SaveUndo(TrkIdx);
 SelAll(CT,False);
 For I:=1 To ClipCnt Do Begin
  K:=AddEv(TrkIdx,PosTick+ClipBuf^[I].T,ClipBuf^[I].Len,ClipBuf^[I].Kind,
    ClipBuf^[I].D1,ClipBuf^[I].D2);
  If K>0 Then Begin
   CT^.Ev^[K].Sty:=ClipBuf^[I].Sty;CT^.Ev^[K].Sel:=True;End;
 End;
 NeedDraw:=True;
End;

Procedure CmdDelete;
Var Tr: PTrk; I: Integer;
Begin
 Tr:=CT;
 If Tr^.Ev=Nil Then Exit;
 SaveUndo(TrkIdx);
 If SelCount(Tr)=0 Then Begin
  If (CurEv>=1) And (CurEv<=Tr^.Cnt) Then DelEv(Tr,CurEv);
 End Else Begin
  I:=1;
  While I<=Tr^.Cnt Do
   If Tr^.Ev^[I].Sel Then DelEv(Tr,I) Else Inc(I);
 End;
 If CurEv>Tr^.Cnt Then CurEv:=Tr^.Cnt;
 If CurEv<1 Then CurEv:=1;
 NeedDraw:=True;
End;

Procedure CmdSelAll(V: Boolean);
Begin
 If CT^.Ev<>Nil Then SelAll(CT,V);
 NeedDraw:=True;
End;

Procedure CmdSelBetween;
Var Tr: PTrk; I: Integer;
Begin
 Tr:=CT;
 If Tr^.Ev=Nil Then Exit;
 For I:=1 To Tr^.Cnt Do
  Tr^.Ev^[I].Sel:=(Tr^.Ev^[I].T>=LocL) And (Tr^.Ev^[I].T<LocR);
 NeedDraw:=True;
End;

Procedure CmdClearTrack;
Var Tr: PTrk;
Begin
 Tr:=CT;
 If Tr^.Cnt=0 Then Exit;
 If Not ConfirmBox(T3('Clear the track?','Effacer la piste ?','Spur l'#148'schen?')) Then Exit;
 SaveUndo(TrkIdx);
 Tr^.Cnt:=0;
 CurEv:=1;Modified:=True;NeedDraw:=True;
End;

Procedure CmdInsertBars(Ins: Boolean);
Var AtBar,N: LongInt; T,I: Integer; Tr: PTrk; D,A,B: LongInt;
Begin
 AtBar:=PosTick Div BarTicks+1;N:=1;
 FormLbl[1]:=T3('At bar','A la mesure',' Takt');FormVal[1]:=IntStr(AtBar);
 FormLbl[2]:=T3('Number of bars','Nombre de mesures','Anzahl Takte');FormVal[2]:='1';
 FormFW:=6;
 If Ins Then Begin
  If Not FormBox(T3('Insert bars','Ins'#130'rer des mesures','Takte einf'#129'gen'),2) Then Exit;
 End Else
  If Not FormBox(T3('Delete bars','Supprimer des mesures','Takte l'#148'schen'),2) Then Exit;
 AtBar:=Max2(1,ToInt(FormVal[1]));N:=Clamp(ToInt(FormVal[2]),1,64);
 A:=(AtBar-1)*BarTicks;D:=N*BarTicks;
 For T:=1 To TPP Do Begin
  Tr:=Trks[TI(CurPat,T)];
  If (Tr<>Nil) And (Tr^.Ev<>Nil) Then Begin
   If T=CurTrk Then SaveUndo(TI(CurPat,T));
   If Ins Then Begin
    For I:=1 To Tr^.Cnt Do If Tr^.Ev^[I].T>=A Then Tr^.Ev^[I].T:=Tr^.Ev^[I].T+D;
   End Else Begin
    I:=1;B:=A+D;
    While I<=Tr^.Cnt Do Begin
     If (Tr^.Ev^[I].T>=A) And (Tr^.Ev^[I].T<B) Then DelEv(Tr,I)
     Else Begin
      If Tr^.Ev^[I].T>=B Then Tr^.Ev^[I].T:=Tr^.Ev^[I].T-D;
      Inc(I);
     End;
    End;
   End;
  End;
 End;
 If Ins Then Pats[CurPat].Len:=Integer(Min2(255,Pats[CurPat].Len+N))
 Else Pats[CurPat].Len:=Integer(Max2(1,Pats[CurPat].Len-N));
 Modified:=True;NeedDraw:=True;
End;

{ ---- copie ---- }

Procedure CmdCopyTrack(Merge: Boolean);
Var P,T,I,K: Integer; Src,Dst: PTrk; Ok: Boolean;
Begin
 FormLbl[1]:=T3('To pattern (1-99)','Vers pattern (1-99)','Nach Pattern (1-99)');
 FormVal[1]:=IntStr(CurPat);
 FormLbl[2]:=T3('To track (1-16)','Vers piste (1-16)','Nach Spur (1-16)');
 FormVal[2]:=IntStr(Min2(16,CurTrk+1));
 FormFW:=6;
 If Merge Then Ok:=FormBox(T3('Merge track','Fusionner la piste','Spur mischen'),2)
 Else Ok:=FormBox(T3('Copy track','Copier la piste','Spur kopieren'),2);
 If Not Ok Then Exit;
 P:=Integer(Clamp(ToInt(FormVal[1]),1,NPAT));T:=Integer(Clamp(ToInt(FormVal[2]),1,TPP));
 Src:=CT;Dst:=GetTrk(TI(P,T));
 If Dst=Src Then Exit;
 SaveUndo(TI(P,T));
 If Not Merge Then Begin
  Dst^.Cnt:=0;
  Dst^.P:=Src^.P;
 End;
 If Src^.Ev<>Nil Then
  For I:=1 To Src^.Cnt Do Begin
   K:=AddEv(TI(P,T),Src^.Ev^[I].T,Src^.Ev^[I].Len,Src^.Ev^[I].Kind,
     Src^.Ev^[I].D1,Src^.Ev^[I].D2);
   If K>0 Then Dst^.Ev^[K].Sty:=Src^.Ev^[I].Sty;
  End;
 If P<>CurPat Then If Pats[P].Len<Pats[CurPat].Len Then Pats[P].Len:=Pats[CurPat].Len;
 Modified:=True;NeedDraw:=True;
End;

Procedure CmdCopyPattern;
Var P,T,I,K: Integer; Src,Dst: PTrk;
Begin
 FormLbl[1]:=T3('To pattern (1-99)','Vers pattern (1-99)','Nach Pattern (1-99)');
 FormVal[1]:=IntStr(Min2(NPAT,CurPat+1));
 FormFW:=6;
 If Not FormBox(T3('Copy pattern','Copier le pattern','Pattern kopieren'),1) Then Exit;
 P:=Integer(Clamp(ToInt(FormVal[1]),1,NPAT));
 If P=CurPat Then Exit;
 For T:=1 To TPP Do Begin
  Src:=Trks[TI(CurPat,T)];
  If Trks[TI(P,T)]<>Nil Then Begin
   FreeTrkEv(Trks[TI(P,T)]);Dispose(Trks[TI(P,T)]);Trks[TI(P,T)]:=Nil;End;
  If Src<>Nil Then Begin
   Dst:=GetTrk(TI(P,T));
   Dst^.P:=Src^.P;
   If (Src^.Ev<>Nil) And (Src^.Cnt>0) Then Begin
    New(Dst^.Ev);Dst^.Cnt:=Src^.Cnt;
    Move(Src^.Ev^,Dst^.Ev^,Src^.Cnt*SizeOf(TEvt));
   End;
  End;
 End;
 Pats[P].Len:=Pats[CurPat].Len;
 If Pats[P].Name='' Then Pats[P].Name:=Pats[CurPat].Name;
 Modified:=True;NeedDraw:=True;
End;

Procedure CmdCopyBars;
Var DestBar: LongInt; I,K,N: Integer; Tr: PTrk; D: LongInt;
 Tmp: Array[1..1] Of Byte;
Begin
 If LocR<=LocL Then Begin
  Info('Set the locators first.','D'#130'finissez d''abord les locators.',
    'Zuerst die Locators setzen.');Exit;End;
 FormLbl[1]:=T3('Copy to bar','Copier '#133' la mesure','Kopieren nach Takt');
 FormVal[1]:=IntStr(LocR Div BarTicks+1);
 FormFW:=6;
 If Not FormBox(T3('Copy bars','Copier des mesures','Takte kopieren'),1) Then Exit;
 DestBar:=Max2(1,ToInt(FormVal[1]));
 D:=(DestBar-1)*BarTicks-LocL;
 Tr:=CT;
 If Tr^.Ev=Nil Then Exit;
 SaveUndo(TrkIdx);
 N:=Tr^.Cnt;
 For I:=1 To N Do
  If (Tr^.Ev^[I].T>=LocL) And (Tr^.Ev^[I].T<LocR) Then Begin
   K:=AddEv(TrkIdx,Tr^.Ev^[I].T+D,Tr^.Ev^[I].Len,Tr^.Ev^[I].Kind,
     Tr^.Ev^[I].D1,Tr^.Ev^[I].D2);
  End;
 Modified:=True;NeedDraw:=True;
End;

{ ---- impression / copie d'ecran ---- }

Procedure PrintScore;
Var F: File; Buf: Array[1..3840] Of Byte; Y0,X,D,Y,Bt,By: Integer; C: Byte;
 Hdr: Array[1..5] Of Byte; Dst: String; Cnt: Integer;
Begin
 Dst:=Upper(PrnDest);
 If (Dst='') Or (Dst='LPT1') Then Dst:='PRN';

 Assign(F,Dst);
 Rewrite(F,1);

 If IOResult<>0 Then Begin
  Info('Cannot open the printer.','Impossible d''ouvrir l''imprimante.',
    'Drucker nicht verf'#129'gbar.');Exit;
 End;
 DrawAll;
 HideMouse;
 C:=27;BlockWrite(F,C,1);C:=Ord('@');BlockWrite(F,C,1);
 Y0:=TB_Y;
 While Y0<SCR_H Do Begin
  Hdr[1]:=27;Hdr[2]:=Ord('*');Hdr[3]:=33;Hdr[4]:=0;Hdr[5]:=5;
  BlockWrite(F,Hdr,5);
  Cnt:=0;
  For X:=0 To 639 Do
   For D:=1 To 2 Do
    For By:=0 To 2 Do Begin
     C:=0;
     For Bt:=0 To 7 Do Begin
      Y:=Y0+((By*8+Bt) Div 2);
      If (Y<SCR_H) And (GetPixel(X,Y)<>PAPER) Then C:=C Or ($80 Shr Bt);
     End;
     Inc(Cnt);Buf[Cnt]:=C;
    End;
  BlockWrite(F,Buf,3840);
  C:=13;BlockWrite(F,C,1);
  C:=27;BlockWrite(F,C,1);C:=Ord('J');BlockWrite(F,C,1);C:=24;BlockWrite(F,C,1);
  Y0:=Y0+12;
 End;
 C:=12;BlockWrite(F,C,1);
 Close(F);
 ShowMouse;
 Info('Score sent to '+Dst+'.','Partition envoy'#130'e vers '+Dst+'.','Partitur gesendet an '+Dst+'.');
End;

Procedure HardcopyPBM;
Var F: File; Row: Array[1..80] Of Byte; X,Y: Integer; H: String;
Begin
 DrawAll;

 Assign(F,'NOTATOR.PBM');
 Rewrite(F,1);

 If IOResult<>0 Then Begin Info('Cannot write the file.','Ecriture impossible.','Schreiben nicht m'#148'glich.');Exit;End;
 HideMouse;
 H:='P4'#10'640 '+IntStr(SCR_H-TB_Y)+#10;
 BlockWrite(F,H[1],Length(H));
 For Y:=TB_Y To SCR_H-1 Do Begin
  FillChar(Row,SizeOf(Row),0);
  For X:=0 To 639 Do
   If GetPixel(X,Y)<>PAPER Then Row[X Shr 3+1]:=Row[X Shr 3+1] Or ($80 Shr (X And 7));
  BlockWrite(F,Row,80);
 End;
 Close(F);
 ShowMouse;
 Info('Screen saved in NOTATOR.PBM.','Ecran sauv'#130' dans NOTATOR.PBM.','Bildschirm in NOTATOR.PBM gesichert.');
End;

{ ====================================================================== }
{                  COMMANDES : FICHIERS / OPTIONS / MIDI                 }
{ ====================================================================== }

Procedure ResetView;
Begin
 ViewBar:=0;CurTrk:=1;CurEv:=1;ListTop:=1;TrkTop:=1;MatTop:=84;
 PlayX:=-1;
End;

Procedure CmdNew;
Begin
 If Playing Then StopPlay;
 If Modified Then
  If Not ConfirmBox(T3('Discard the current song?','Abandonner le morceau actuel ?',
    'Aktuelles Lied verwerfen?')) Then Exit;
 InitSong;
 ResetView;
 NeedDraw:=True;
End;

Procedure CmdSaveAs;
Var S: String;
Begin
 S:=SongName;
 If FileSelect(T3('Save song','Sauver le morceau','Lied speichern'),'*.SON',S) Then Begin
  S:=AddExt(S,'SON');
  If SaveSong(S) Then Begin
   SongName:=S;SongNamed:=True;Modified:=False;
  End Else Info('Write error.','Erreur d'''#130'criture.','Schreibfehler.');
 End;
 NeedDraw:=True;
End;

Procedure CmdSave;
Begin
 If Not SongNamed Then Begin CmdSaveAs;Exit;End;
 If Not SaveSong(SongName) Then Info('Write error.','Erreur d'''#130'criture.','Schreibfehler.')
 Else Modified:=False;
 NeedDraw:=True;
End;

Procedure CmdLoad;
Var S: String;
Begin
 If Playing Then StopPlay;
 S:='';
 If Not FileSelect(T3('Load song','Charger un morceau','Lied laden'),'*.SON',S) Then Begin
  NeedDraw:=True;Exit;End;
 S:=AddExt(S,'SON');
 If LoadSong(S) Then ResetView
 Else Info('Cannot read this song.','Lecture impossible.','Lied nicht lesbar.');
 NeedDraw:=True;
End;

Procedure CmdLoadMidi;
Var S: String;
Begin
 If Playing Then StopPlay;
 S:='';
 If Not FileSelect(T3('Load MIDI file','Charger un fichier MIDI','MIDI-Datei laden'),
   '*.MID',S) Then Begin NeedDraw:=True;Exit;End;
 S:=AddExt(S,'MID');
 If Not ConfirmBox(T3('Replace the current pattern?','Remplacer le pattern courant ?',
   'Aktuelles Pattern ersetzen?')) Then Begin NeedDraw:=True;Exit;End;
 If LoadMidi(S) Then Begin
  ResetView;
  SongName:=Copy(ShortName(S),1,8)+'.SON';SongNamed:=False;
 End Else Info('Cannot read this MIDI file.','Fichier MIDI illisible.','MIDI-Datei nicht lesbar.');
 NeedDraw:=True;
End;

Procedure CmdSaveMidi;
Var S: String;
Begin
 S:=Copy(ShortName(SongName),1,8);
 If Pos('.',S)>0 Then S:=Copy(S,1,Pos('.',S)-1);
 S:=S+'.MID';
 If FileSelect(T3('Save MIDI file','Sauver un fichier MIDI','MIDI-Datei speichern'),
   '*.MID',S) Then Begin
  S:=AddExt(S,'MID');
  If Not SaveMidi(S) Then Info('Write error.','Erreur d'''#130'criture.','Schreibfehler.');
 End;
 NeedDraw:=True;
End;

Procedure CmdDemo;
Begin
 If Playing Then StopPlay;
 If Modified Then
  If Not ConfirmBox(T3('Discard the current song?','Abandonner le morceau actuel ?',
    'Aktuelles Lied verwerfen?')) Then Exit;
 BuildDemo;
 ResetView;
 View:=V_SCORE;
 NeedDraw:=True;
End;

Procedure CmdQuit;
Begin
 If Modified Then
  If Not ConfirmBox(T3('Quit without saving?','Quitter sans sauver ?','Beenden ohne Speichern?')) Then
   Exit;
 If Playing Then StopPlay;
 Quit:=True;
End;

Procedure CmdAbout;
Begin
 MsgBox(T3('About Notator','A propos de Notator','Ueber Notator'),
  'NOTATOR SL '+VERSION_TEXT+'|'+
  T3('Sequencer / score editor clone','Clone du s'#130'quenceur / '#130'diteur de partition',
     'Sequenzer- / Partitur-Editor Klon')+'|'+
  T3('384/192 PPQ, 1584 tracks (64 active), 96 MIDI channels',
     '384/192 PPQ, 1584 pistes (64 actives), 96 canaux MIDI',
     '384/192 PPQ, 1584 Spuren (64 aktiv), 96 MIDI-Kan'#132'le')+'|'+
  'https://www.gladir.com/office-0');
End;

Procedure CmdFreeMem;
Begin
 MsgBox(T3('Free memory','M'#130'moire libre','Freier Speicher'),
  T3('Free memory: ','M'#130'moire libre : ','Freier Speicher: ')+IntStr(MemFree)+' KB');
End;

Procedure CmdHelp;
Begin
 MsgN:=0;
 MsgAdd(T3('F1 Arrange  F2 Score  F3 Matrix  F4 List  F12 Menus',
     'F1 Arrangement  F2 Partition  F3 Matrice  F4 Liste  F12 Menus',
     'F1 Arrange  F2 Partitur  F3 Matrix  F4 Liste  F12 Men'#129's'));
 MsgAdd(T3('SPACE BAR = play / stop the song or MIDI file',
     'BARRE D''ESPACEMENT = jouer / arr'#136'ter le son ou le MIDI',
     'LEERTASTE = Song oder MIDI abspielen / stoppen'));
 MsgAdd(T3('Enter continue  * record',
     'Entr'#130'e continuer  * enregistrer',
     'Enter weiter  * Aufnahme'));
 MsgAdd(T3('Z..M and Q..P = piano keys, - + = octave',
     'Z..M et Q..P = touches de piano, - + = octave',
     'Z..M und Q..P = Klaviertasten, - + = Oktave'));
 MsgAdd(T3('[ ] set left/right locator  Home = start',
     '[ ] locator gauche/droit  Origine = d'#130'but',
     '[ ] linker/rechter Locator  Pos1 = Anfang'));
 MsgAdd(T3('F5-F10 note values, Del delete',
     'F5-F10 valeurs de notes, Suppr effacer',
     'F5-F10 Notenwerte, Entf l'#148'schen'));
 MsgAdd(T3('right click = erase',
     'clic droit = gommer',
     'Rechtsklick = l'#148'schen'));
 MsgShow(T3('Help','Aide','Hilfe'));
End;

{ ---- options ---- }

Procedure CmdZoom;
Var V: LongInt;
Begin
 V:=ZoomX;
 If AskNum('Zoom ->','1-8',V,1,8) Then ZoomX:=V;
 V:=ZoomY;
 If AskNum('Zoom v','1-20',V,1,20) Then ZoomY:=V;
 NeedDraw:=True;
End;

Procedure CmdPen;
Var V: LongInt;
Begin
 V:=PenVel;
 If AskNum('PEN',T3('Velocity (1-127)','V'#130'locit'#130' (1-127)','Anschlag (1-127)'),V,1,127) Then
  PenVel:=V;
 NeedDraw:=True;
End;

Procedure CmdHyperPattern;
Var V: LongInt;
Begin
 V:=ColorNo;
 If AskNum('COLOR','0-3',V,0,3) Then ColorNo:=V;
 NeedDraw:=True;
End;

Procedure CmdHyperKind;
Begin
 HyperKind:=(HyperKind+1) Mod 6;
 NeedDraw:=True;
End;

Var
 ResNewP : Integer;

{ duree V ramenee a la nouvelle resolution (fonction locale de la version DOS) }
Function ResScale(V: LongInt): LongInt;
Begin
 If ResNewP<PPQ Then ResScale:=V Div 2 Else ResScale:=V*2;
End;

Procedure CmdResolution;
Var NewP: Integer; T: Integer; I: Integer; Tr: PTrk;
Begin
 If Playing Then StopPlay;
 If PPQ=384 Then NewP:=192 Else NewP:=384;
 ResNewP:=NewP;
 For T:=1 To MAXTRK Do Begin
  Tr:=Trks[T];
  If Tr<>Nil Then Begin
   For I:=1 To Tr^.Cnt Do Begin
    Tr^.Ev^[I].T:=ResScale(Tr^.Ev^[I].T);
    Tr^.Ev^[I].Len:=ResScale(Tr^.Ev^[I].Len);
    If (Tr^.Ev^[I].Kind=EK_NOTE) And (Tr^.Ev^[I].Len<1) Then Tr^.Ev^[I].Len:=1;
   End;
   Tr^.P.Delay:=Integer(ResScale(Tr^.P.Delay));
  End;
 End;
 LocL:=ResScale(LocL);LocR:=ResScale(LocR);PosTick:=ResScale(PosTick);
 PPQ:=NewP;
 UndoValid:=False;Modified:=True;NeedDraw:=True;
 Info('Resolution: '+IntStr(PPQ)+' PPQ','R'#130'solution : '+IntStr(PPQ)+' PPQ',
   'Aufl'#148'sung: '+IntStr(PPQ)+' PPQ');
End;

Procedure CmdRestQ;
Var I,R: Integer;
Begin
 LstN:=NQUA+1;
 For I:=0 To NQUA Do LstItem[I+1]:=QuaLbl[I];
 R:=ChooseBox(T3('Smallest rest shown','Plus petit silence affich'#130,'Kleinste Pause'),RestQ+1);
 If R>0 Then RestQ:=R-1;
 NeedDraw:=True;
End;

Procedure CmdLanguage;
Begin
 LstN:=3;LstItem[1]:='English';LstItem[2]:='Fran'#135'ais';LstItem[3]:='Deutsch';
 Lang:=Max2(0,ChooseBox('Language / Langue / Sprache',Lang+1)-1);
 NeedDraw:=True;
End;

Procedure CmdPrintDest;
Var S: String;
Begin
 S:=PrnDest;
 If InputBox(T3('Print destination','Destination d''impression','Druckziel'),
   T3('PRN or file','PRN ou fichier','PRN oder Datei'),S,30) Then PrnDest:=S;
 NeedDraw:=True;
End;

Procedure SaveOptions;
Var F: Text;
Begin

 Assign(F,OPTFILE);
 Rewrite(F);

 If IOResult<>0 Then Begin
  Info('Cannot write NOTATOR.OPT.','Ecriture de NOTATOR.OPT impossible.','NOTATOR.OPT nicht schreibbar.');
  Exit;End;
 WriteLn(F,'LANG ',Lang);
 WriteLn(F,'OUTDEV ',OutDev);
 WriteLn(F,'MPU ',MpuPort);
 WriteLn(F,'PEN ',PenVel);
 WriteLn(F,'ZOOMX ',ZoomX);
 WriteLn(F,'ZOOMY ',ZoomY);
 WriteLn(F,'COLOR ',ColorNo);
 WriteLn(F,'RESTQ ',RestQ);
 WriteLn(F,'FLAGS ',Ord(FlAutoIns),Ord(FlFixVel),Ord(FlAllCha),Ord(FlLockScore),
   Ord(FlClick),Ord(FlCountIn),Ord(FlThru),Ord(FlAutoDrop),Ord(FlCycle),
   Ord(FlPunch),Ord(FlFollow),Ord(FlArrange));
 WriteLn(F,'PRN ',PrnDest);
 Close(F);
 Info('Options saved.','Options sauv'#130'es.','Optionen gespeichert.');
End;

{ drapeau I de la ligne FLAGS (fonction locale de la version DOS) }
Function OptFlag(Const V: String; I: Integer): Boolean;
Begin
 OptFlag:=(Length(V)>=I) And (V[I]='1');
End;

Procedure LoadOptions(UseLang: Boolean);
Var F: Text; L,K,V: String; P,C: Integer; N: LongInt;
Begin

 Assign(F,OPTFILE);
 Reset(F);

 If IOResult<>0 Then Exit;
 While Not Eof(F) Do Begin
  ReadLn(F,L);
  P:=Pos(' ',L);
  If P>0 Then Begin
   K:=Upper(Copy(L,1,P-1));V:=Copy(L,P+1,60);
   Val(V,N,C);
   If K='LANG' Then Begin If UseLang And (C=0) Then Lang:=Integer(Clamp(N,0,2));End
   Else If K='OUTDEV' Then Begin If C=0 Then OutDev:=Integer(Clamp(N,0,2));End
   Else If K='MPU' Then Begin If C=0 Then MpuPort:=Integer(N);End
   Else If K='PEN' Then Begin If C=0 Then PenVel:=Integer(Clamp(N,1,127));End
   Else If K='ZOOMX' Then Begin If C=0 Then ZoomX:=Integer(Clamp(N,1,8));End
   Else If K='ZOOMY' Then Begin If C=0 Then ZoomY:=Integer(Clamp(N,1,20));End
   Else If K='COLOR' Then Begin If C=0 Then ColorNo:=Integer(Clamp(N,0,3));End
   Else If K='RESTQ' Then Begin If C=0 Then RestQ:=Integer(Clamp(N,0,NQUA));End
   Else If K='PRN' Then PrnDest:=Copy(V,1,40)
   Else If K='FLAGS' Then Begin
    FlAutoIns:=OptFlag(V,1);FlFixVel:=OptFlag(V,2);FlAllCha:=OptFlag(V,3);FlLockScore:=OptFlag(V,4);
    FlClick:=OptFlag(V,5);FlCountIn:=OptFlag(V,6);FlThru:=OptFlag(V,7);FlAutoDrop:=OptFlag(V,8);
    FlCycle:=OptFlag(V,9);FlPunch:=OptFlag(V,10);FlFollow:=OptFlag(V,11);FlArrange:=OptFlag(V,12);
   End;
  End;
 End;
 Close(F);
End;

{ ---- MIDI ---- }

Procedure CmdOutDev;
Begin
 LstN:=3;
 LstItem[1]:=T3('Sound card (MMPM/2)','Carte son (MMPM/2)','Soundkarte (MMPM/2)');
 LstItem[2]:='MPU-401 (DOS)';
 LstItem[3]:=T3('None','Aucune','Keine');
 AllNotesOff;
 OutDev:=Max2(0,ChooseBox(T3('MIDI output','Sortie MIDI','MIDI-Ausgang'),OutDev+1)-1);

 If OutDev=1 Then Begin
  OutDev:=0;
  Info('MPU-401 is only available under DOS: sound card used.',
    'MPU-401 disponible seulement sous DOS : la carte son est utilis'#130'e.',
    'MPU-401 nur unter DOS verf'#129'gbar.');
 End;

 If OutDev=0 Then Begin
  If Not SynthStart Then Begin
   OutDev:=2;
   Info('No sound card (MDM.DLL): sound output is off.',
     'Aucune carte son (MDM.DLL) : la sortie du son est coup'#130'e.',
     'Keine Soundkarte (MDM.DLL): Tonausgabe aus.');
  End;
 End Else SynthStop;

 NeedDraw:=True;
End;

Procedure CmdMpuPort;
Var S: String; N: LongInt; C: Integer;
Begin
 S:='330';
 If InputBox('MPU-401',T3('Base port (hex)','Port de base (hex)','Basisport (hex)'),S,5) Then Begin
  Val('$'+S,N,C);
  If (C=0) And (N>=$200) And (N<=$3F0) Then Begin
   MpuPort:=Integer(N);

  End;
 End;
 NeedDraw:=True;
End;

Procedure CmdInsProgram;
Var V: LongInt;
Begin
 V:=0;
 If AskNum(T3('Program change','Changement de programme','Programmwechsel'),
   T3('Program (0-127)','Programme (0-127)','Programm (0-127)'),V,0,127) Then Begin
  AddEv(TrkIdx,PosTick,0,EK_PROG,V,0);
  MidiSend(CT^.P.Port,$C0+CT^.P.Chan-1,V,0,2);
 End;
 NeedDraw:=True;
End;

Procedure CmdInsCtrl;
Begin
 FormLbl[1]:=T3('Controller (0-127)','Contr'#147'leur (0-127)','Controller (0-127)');
 FormVal[1]:='7';
 FormLbl[2]:=T3('Value (0-127)','Valeur (0-127)','Wert (0-127)');
 FormVal[2]:='100';
 FormFW:=6;
 If FormBox('Control',2) Then
  AddEv(TrkIdx,PosTick,0,EK_CTRL,Clamp(ToInt(FormVal[1]),0,127),
    Clamp(ToInt(FormVal[2]),0,127));
 NeedDraw:=True;
End;

Procedure CmdPanic;
Begin
 AllNotesOff;
End;

Procedure Toggle(Var B: Boolean);
Begin
 B:=Not B;
 NeedDraw:=True;
End;

Procedure CmdPatLen;
Var V: LongInt;
Begin
 V:=Pats[CurPat].Len;
 If AskNum(T3('Pattern length','Longueur du pattern','Pattern-L'#132'nge'),
   T3('Bars (1-255)','Mesures (1-255)','Takte (1-255)'),V,1,255) Then Begin
  Pats[CurPat].Len:=V;Modified:=True;End;
 NeedDraw:=True;
End;

Procedure CmdPatName;
Var S: String;
Begin
 S:=Pats[CurPat].Name;
 If InputBox(T3('Pattern name','Nom du pattern','Pattern-Name'),T3('Name','Nom','Name'),S,12) Then Begin
  Pats[CurPat].Name:=Copy(S,1,12);Modified:=True;End;
 NeedDraw:=True;
End;

Procedure CenterMatrix;
Var Tr: PTrk; I,N,S: Integer;
Begin
 Tr:=CT;
 N:=0;S:=0;
 If Tr^.Ev<>Nil Then
  For I:=1 To Tr^.Cnt Do
   If Tr^.Ev^[I].Kind=EK_NOTE Then Begin S:=S+Tr^.Ev^[I].D1;Inc(N);End;
 If N>0 Then MatTop:=Integer(Clamp(S Div N+MatRows Div 2,11,127))
 Else MatTop:=Integer(Clamp(72+MatRows Div 2,11,127));
End;

Procedure CmdSetView(V: Integer);
Begin
 View:=V;
 If V=V_MATRIX Then CenterMatrix;
 NeedDraw:=True;
End;

Procedure CmdSetLoc(Left: Boolean);
Begin
 If Left Then Begin
  LocL:=CurPos;If LocR<=LocL Then LocR:=LocL+BarTicks;
 End Else Begin
  LocR:=CurPos;If LocL>=LocR Then LocL:=Max2(0,LocR-BarTicks);
 End;
 NeedDraw:=True;
End;

{ ====================================================================== }
{                         MENUS DEROULANTS                               }
{ ====================================================================== }

Const
 NMENU = 9;
 MTitle : Array[1..NMENU] Of String[40] =
  ('Desk~Bureau~Desk','File~Fichier~Datei','Functions~Fonctions~Funktionen',
   'Quantize~Quantif.~Quantis.','MIDI~MIDI~MIDI','Flags~Drapeaux~Flags',
   'Options~Options~Optionen','Edit~Edition~Bearb.','Copy~Copie~Kopie');

Var
 MenuOpen,MenuHi : Integer;

Function MCount(M: Integer): Integer;
Begin
 Case M Of
  1: MCount:=4;
  2: MCount:=11;
  3: MCount:=18;
  4: MCount:=17;
  5: MCount:=10;
  6: MCount:=13;
  7: MCount:=10;
  8: MCount:=19;
  9: MCount:=7;
 Else MCount:=0;
 End;
End;

{ 'EN~FR~DE|raccourci' ; '-' = separateur }
Function MItem(M,I: Integer): String;
Begin
 MItem:='';
 Case M Of
  1: Case I Of
      1: MItem:='About Notator~A propos de Notator~'#154'ber Notator';
      2: MItem:='-';
      3: MItem:='Free memory~M'#130'moire libre~Freier Speicher';
      4: MItem:='Help~Aide~Hilfe|F11';
     End;
  2: Case I Of
      1: MItem:='New song~Nouveau morceau~Neues Lied|^N';
      2: MItem:='Load song...~Charger morceau...~Lied laden...|^L';
      3: MItem:='Save song~Sauver morceau~Lied speichern|^S';
      4: MItem:='Save song as...~Sauver sous...~Speichern unter...';
      5: MItem:='-';
      6: MItem:='Load MIDI file...~Charger fichier MIDI...~MIDI-Datei laden...';
      7: MItem:='Save MIDI file...~Sauver fichier MIDI...~MIDI-Datei speichern...';
      8: MItem:='-';
      9: MItem:='Demo song~Morceau de d'#130'mo~Demo-Lied';
      10: MItem:='-';
      11: MItem:='Quit~Quitter~Beenden|^Q';
     End;
  3: Case I Of
      1: MItem:='Arrange page~Page arrangement~Arrange-Seite|F1';
      2: MItem:='Score edit~Edition partition~Partitur-Editor|F2';
      3: MItem:='Matrix edit~Edition matrice~Matrix-Editor|F3';
      4: MItem:='Event list~Liste d''ev.~Eventliste|F4';
      5: MItem:='Play~Jouer~Spielen|Space';
      6: MItem:='Continue~Continuer~Fortsetzen|Enter';
      7: MItem:='Stop~Arr'#136'ter~Stopp|Space';
      8: MItem:='Record~Enregistrer~Aufnahme|*';
      9: MItem:='-';
      10: MItem:='Go to bar...~Aller '#133' mesure...~Gehe zu Takt...|^G';
      11: MItem:='Set left locator~Locator gauche~Linker Locator|[';
      12: MItem:='Set right locator~Locator droit~Rechter Locator|]';
      13: MItem:='Pattern length...~Longueur pattern...~Pattern-L'#132'nge...';
      14: MItem:='Pattern name...~Nom du pattern...~Pattern-Name...';
      15: MItem:='Track settings...~Param'#138'tres piste...~Spur-Einstellungen...';
      16: MItem:='-';
      17: MItem:='Hyper edit type~Type hyper edit~Hyper-Edit Typ';
      18: MItem:='Show hyper edit~Afficher hyper edit~Hyper-Edit zeigen';
     End;
  4: Case I Of
      1: MItem:='Quantize value...~Valeur quantif...~Quantisierungswert...';
      2: MItem:='Display format...~Format affichage...~Anzeigeformat...';
      3: MItem:='Do quantize~Quantifier~Quantisieren';
      4: MItem:='Undo quantize~Annuler quantif.~Quantis. r'#129'ckg.|^Z';
      5: MItem:='-';
      6: MItem:='Groove design...~Conception groove...~Groove-Design...';
      7: MItem:='Learn groove (adaptive)~Groove adaptatif~Adaptiver Groove';
      8: MItem:='Clear groove~Effacer groove~Groove l'#148'schen';
      9: MItem:='-';
      10: MItem:='Transpose track...~Transposer piste...~Spur transponieren...';
      11: MItem:='Velocity...~V'#130'locit'#130'...~Anschlag...';
      12: MItem:='Compress...~Compresser...~Komprimieren...';
      13: MItem:='Delay...~D'#130'lai...~Verz'#148'gerung...';
      14: MItem:='Lowest note...~Note la plus basse...~Tiefste Note...';
      15: MItem:='Highest note...~Note la plus haute...~H'#148'chste Note...';
      16: MItem:='Loop...~Boucle...~Schleife...';
      17: MItem:='Reset track~Param. par d'#130'faut~Spur zur'#129'cksetzen';
     End;
  5: Case I Of
      1: MItem:='MIDI output...~Sortie MIDI...~MIDI-Ausgang...';
      2: MItem:='MPU-401 port...~Port MPU-401...~MPU-401 Port...';
      3: MItem:='-';
      4: MItem:='Instrument...~Instrument...~Instrument...';
      5: MItem:='Port / channel...~Port / canal...~Port / Kanal...';
      6: MItem:='Insert program change~Ins'#130'rer prog. change~Programmwechsel einf.';
      7: MItem:='Insert controller~Ins'#130'rer contr'#147'leur~Controller einf'#129'gen';
      8: MItem:='Sync mode...~Mode synchro...~Sync-Modus...';
      9: MItem:='-';
      10: MItem:='All notes off~Toutes notes off~Alle Noten aus';
     End;
  6: Case I Of
      1: MItem:='AutoIns~AutoIns~AutoIns';
      2: MItem:='FixVel~FixVel~FixVel';
      3: MItem:='AllCha~AllCha~AllCha';
      4: MItem:='LockScore~LockScore~LockScore';
      5: MItem:='-';
      6: MItem:='Click (metronome)~Click (m'#130'tronome)~Klick (Metronom)';
      7: MItem:='Count-in~Pr'#130'-compte~Vorz'#132'hler';
      8: MItem:='Thru~Thru~Thru';
      9: MItem:='Autodrop~Autodrop~Autodrop';
      10: MItem:='Cycle~Cycle~Zyklus';
      11: MItem:='Punch~Punch~Punch';
      12: MItem:='Follow song~Suivre morceau~Lied folgen';
      13: MItem:='Arrange mode~Mode arrangement~Arrange-Modus';
     End;
  7: Case I Of
      1: MItem:='Song settings...~Param'#138'tres morceau...~Lied-Einstellungen...';
      2: MItem:='Resolution 384/192~R'#130'solution 384/192~Aufl'#148'sung 384/192';
      3: MItem:='Zoom...~Zoom...~Zoom...';
      4: MItem:='Pen velocity...~V'#130'locit'#130' stylo...~Stift-Anschlag...';
      5: MItem:='Hyper edit color...~Couleur hyper edit...~Hyper-Edit Farbe...';
      6: MItem:='Clef of track...~Cl'#130' de la piste...~Schl'#129'ssel der Spur...';
      7: MItem:='Rest threshold...~Seuil des silences...~Pausen-Schwelle...';
      8: MItem:='Print destination...~Destination impression...~Druckziel...';
      9: MItem:='Language...~Langue...~Sprache...';
      10: MItem:='Save options~Sauver options~Optionen speichern';
     End;
  8: Case I Of
      1: MItem:='Undo~Annuler~R'#129'ckg'#132'ngig|^Z';
      2: MItem:='-';
      3: MItem:='Cut~Couper~Ausschneiden|^X';
      4: MItem:='Copy~Copier~Kopieren|^C';
      5: MItem:='Paste~Coller~Einf'#129'gen|^V';
      6: MItem:='Delete~Supprimer~L'#148'schen|Del';
      7: MItem:='-';
      8: MItem:='Select all~Tout s'#130'lectionner~Alles w'#132'hlen|^A';
      9: MItem:='Select none~D'#130's'#130'lectionner~Nichts w'#132'hlen';
      10: MItem:='Select locators~S'#130'lection locators~Auswahl Locators';
      11: MItem:='-';
      12: MItem:='Transpose sel.~Transposer s'#130'l.~Auswahl transp.';
      13: MItem:='Change velocity~Changer v'#130'locit'#130'~Anschlag '#132'ndern';
      14: MItem:='Change length~Changer dur'#130'e~L'#132'nge '#132'ndern';
      15: MItem:='Quantize sel.~Quantifier s'#130'l.~Auswahl quantis.';
      16: MItem:='-';
      17: MItem:='Insert bars...~Ins'#130'rer mesures...~Takte einf'#129'gen...';
      18: MItem:='Delete bars...~Supprimer mesures...~Takte l'#148'schen...';
      19: MItem:='Clear track~Effacer piste~Spur l'#148'schen';
     End;
  9: Case I Of
      1: MItem:='Copy track...~Copier piste...~Spur kopieren...';
      2: MItem:='Merge track...~Fusionner piste...~Spur mischen...';
      3: MItem:='Copy pattern...~Copier pattern...~Pattern kopieren...';
      4: MItem:='Copy bars...~Copier mesures...~Takte kopieren...';
      5: MItem:='-';
      6: MItem:='Print score~Imprimer partition~Partitur drucken';
      7: MItem:='Hardcopy (PBM)~Copie d''ecran (PBM)~Bildschirmkopie (PBM)';
     End;
 End;
End;

Function MLabel(M,I: Integer): String;
Var S: String; P: Integer;
Begin
 S:=MItem(M,I);
 If S='-' Then Begin MLabel:='-';Exit;End;
 P:=Pos('|',S);
 If P>0 Then MLabel:=Part3(Copy(S,1,P-1),Lang)+Copy(S,P,40)
 Else MLabel:=Part3(S,Lang);
End;

Function MChecked(M,I: Integer): Boolean;
Begin
 MChecked:=False;
 If M=3 Then Begin
  If (I>=1) And (I<=4) Then MChecked:=(View=I);
  If I=18 Then MChecked:=ShowHyper;
 End;
 If M=4 Then If I=8 Then MChecked:=(CT^.P.Groove<>0);
 If M=5 Then Begin
  If I=1 Then MChecked:=(OutDev<>2);
 End;
 If M=6 Then
  Case I Of
   1: MChecked:=FlAutoIns;
   2: MChecked:=FlFixVel;
   3: MChecked:=FlAllCha;
   4: MChecked:=FlLockScore;
   6: MChecked:=FlClick;
   7: MChecked:=FlCountIn;
   8: MChecked:=FlThru;
   9: MChecked:=FlAutoDrop;
   10: MChecked:=FlCycle;
   11: MChecked:=FlPunch;
   12: MChecked:=FlFollow;
   13: MChecked:=FlArrange;
  End;
End;

Function MEnabled(M,I: Integer): Boolean;
Begin
 MEnabled:=True;
 If (M=8) And (I=1) Then MEnabled:=UndoValid;
 If (M=4) And (I=4) Then MEnabled:=UndoValid;
End;

Function MIsSep(M,I: Integer): Boolean;
Begin
 MIsSep:=(MItem(M,I)='-');
End;

Function MT(I: Integer): String;
Begin
 MT:=Part3(MTitle[I],Lang);
End;

{ ---- barre de menus de PM construite a partir des tables ci-dessus ----
  element I du menu M : identificateur M * 100 + I ; sous-menu M * 100 + 99
  (WM_INITMENU : coches et elements grises mis a jour a l'ouverture) }
Var
 MenuLang : Integer;

{ raccourci de la version DOS ('^Z') -> texte d'OS/2 ('Ctrl+Z') }
Function ShortcutText(Const S: String): String;
Begin
 If (Length(S)=2) And (S[1]='^') Then ShortcutText:='Ctrl+'+S[2]
 Else ShortcutText:=S;
End;

Procedure BuildMenuBar;
Var M,I,H0,H1,P,K,N: Integer; S,Lb,Used: String; Mn: Boolean;
Begin
 MenuLen:=0;Used:='';
 H0:=MnOpen;
 For M:=1 To NMENU Do Begin
  { mnemonique : premiere lettre pas encore prise par un autre titre }
  S:=MT(M);Lb:='';Mn:=False;
  For K:=1 To Length(S) Do Begin
   If (Not Mn) And (UpCase(S[K])>='A') And (UpCase(S[K])<='Z') And
      (Pos(UpCase(S[K]),Used)=0) Then Begin
    Lb:=Lb+'~';Used:=Used+UpCase(S[K]);Mn:=True;
   End;
   Lb:=Lb+S[K];
  End;
  MnItem(MIS_TEXT Or MIS_SUBMENU,0,M*100+99,Lb);
  H1:=MnOpen;N:=0;
  For I:=1 To MCount(M) Do Begin
   S:=MLabel(M,I);
   If S='-' Then MnItem(MIS_SEPARATOR,0,M*100+I,'')
   Else Begin
    P:=Pos('|',S);
    If P>0 Then S:=Copy(S,1,P-1)+Chr(9)+ShortcutText(Copy(S,P+1,20));
    MnItem(MIS_TEXT,0,M*100+I,S);
   End;
   Inc(N);
  End;
  MnClose(H1,N);
 End;
 MnClose(H0,NMENU);
 HMenu:=WinCreateMenu(HFrame,LongInt(@MenuT));
 MenuLang:=Lang;
End;

Procedure SetItemAttr(Id,Attr: LongInt; On: Boolean);
Var V: LongInt;
Begin
 If On Then V:=Attr Else V:=0;
 Dummy:=WinSendMsg(HMenu,MM_SETITEMATTR,Id Or $10000,Attr Or (V Shl 16));
End;

Procedure MenuInit(M : LongInt);
Var I: Integer;
Begin
 M:=M Div 100;
 If (M<1) Or (M>NMENU) Then Exit;
 For I:=1 To MCount(M) Do
  If Not MIsSep(M,I) Then Begin
   SetItemAttr(M*100+I,MIA_CHECKED,MChecked(M,I));
   SetItemAttr(M*100+I,MIA_DISABLED,Not MEnabled(M,I));
  End;
End;

{ la barre de menus est celle de PM : refaite seulement si la langue change }
Procedure DrawMenuBar;
Begin
 If (HFrame<>0) And (MenuLang<>Lang) Then BuildMenuBar;
End;

Procedure DrawDropDown;
Begin
End;

Procedure DoMenu(M,I: Integer);
Begin
 Case M Of
  1: Case I Of
      1: CmdAbout;
      3: CmdFreeMem;
      4: CmdHelp;
     End;
  2: Case I Of
      1: CmdNew;
      2: CmdLoad;
      3: CmdSave;
      4: CmdSaveAs;
      6: CmdLoadMidi;
      7: CmdSaveMidi;
      9: CmdDemo;
      11: CmdQuit;
     End;
  3: Case I Of
      1: CmdSetView(V_ARR);
      2: CmdSetView(V_SCORE);
      3: CmdSetView(V_MATRIX);
      4: CmdSetView(V_LIST);
      5: CmdStart;
      6: CmdCont;
      7: CmdStop;
      8: CmdRecord;
      10: CmdGoto;
      11: CmdSetLoc(True);
      12: CmdSetLoc(False);
      13: CmdPatLen;
      14: CmdPatName;
      15: CmdTrackSettings;
      17: CmdHyperKind;
      18: Toggle(ShowHyper);
     End;
  4: Case I Of
      1: CmdQuaValue;
      2: CmdFormat;
      3: CmdDoQuantize;
      4: DoUndo;
      6: CmdGrooveDesign;
      7: CmdLearnGroove;
      8: CmdClearGroove;
      10: EditPar(5);
      11: EditPar(6);
      12: EditPar(7);
      13: EditPar(9);
      14: EditPar(10);
      15: EditPar(11);
      16: EditPar(8);
      17: CmdResetPar;
     End;
  5: Case I Of
      1: CmdOutDev;
      2: CmdMpuPort;
      4: CmdInstrument;
      5: CmdChannel;
      6: CmdInsProgram;
      7: CmdInsCtrl;
      8: CmdSync;
      10: CmdPanic;
     End;
  6: Case I Of
      1: Toggle(FlAutoIns);
      2: Toggle(FlFixVel);
      3: Toggle(FlAllCha);
      4: Toggle(FlLockScore);
      6: Toggle(FlClick);
      7: Toggle(FlCountIn);
      8: Toggle(FlThru);
      9: Toggle(FlAutoDrop);
      10: Toggle(FlCycle);
      11: Toggle(FlPunch);
      12: Toggle(FlFollow);
      13: Toggle(FlArrange);
     End;
  7: Case I Of
      1: CmdSongSettings;
      2: CmdResolution;
      3: CmdZoom;
      4: CmdPen;
      5: CmdHyperPattern;
      6: CmdClef;
      7: CmdRestQ;
      8: CmdPrintDest;
      9: CmdLanguage;
      10: SaveOptions;
     End;
  8: Case I Of
      1: DoUndo;
      3: CmdCopyEv(True);
      4: CmdCopyEv(False);
      5: CmdPaste;
      6: CmdDelete;
      8: CmdSelAll(True);
      9: CmdSelAll(False);
      10: CmdSelBetween;
      12: CmdTransposeSel;
      13: CmdChangeVel;
      14: CmdChangeLen;
      15: CmdQuantSel;
      17: CmdInsertBars(True);
      18: CmdInsertBars(False);
      19: CmdClearTrack;
     End;
  9: Case I Of
      1: CmdCopyTrack(False);
      2: CmdCopyTrack(True);
      3: CmdCopyPattern;
      4: CmdCopyBars;
      6: PrintScore;
      7: HardcopyPBM;
     End;
 End;
End;

{ F12 de la version DOS (ouvrir le menu Fichier au clavier) : la barre de
  menus de PM est activee comme par F10 }
Procedure RunMenu(StartM: Integer; ByMouse: Boolean);
Begin
 Dummy:=WinPostMsg(HFrame,WM_SYSCOMMAND,SC_APPMENU,2);
End;

{ ====================================================================== }
{                  SOURIS / CLAVIER : GESTION DES VUES                   }
{ ====================================================================== }

Var
 LastClkCs  : LongInt;
 LastClkId  : Integer;
 DragKind   : Integer;
 HyLastT    : LongInt;
 HyLastV    : LongInt;

Function DblClick(Id: Integer): Boolean;
Var N: LongInt;
Begin
 N:=NowCs;
 DblClick:=(LastClkId=Id) And (Abs(N-LastClkCs)<45);
 LastClkId:=Id;LastClkCs:=N;
 If DblClick Then LastClkId:=-1;
End;

Function SnapT(T: LongInt): LongInt;
Var G: LongInt;
Begin
 G:=QuaTicks(FmtQ);
 If G=0 Then G:=PPQ Div 4;
 If T<0 Then T:=0;
 SnapT:=((T+G Div 2) Div G)*G;
End;

Function PitchAtPos(Pos,Clef: Integer): Integer;
Var D,St,N: Integer;
Begin
 D:=Pos+DBot[Clef];
 If D<0 Then D:=0;
 St:=D Mod 7;
 N:=(D Div 7)*12+MajPc[St];
 If KeyAcc[St]=1 Then Inc(N) Else If KeyAcc[St]=2 Then Dec(N);
 PitchAtPos:=Integer(Clamp(N,0,127));
End;

Function NoteAtClick(Tr: PTrk; T: LongInt; Pos: Integer): Integer;
Var I,A: Integer; Te,L,G: LongInt;
Begin
 NoteAtClick:=0;
 If Tr^.Ev=Nil Then Exit;
 G:=QuaTicks(FmtQ);If G=0 Then G:=PPQ Div 4;
 For I:=Tr^.Cnt DownTo 1 Do
  If Tr^.Ev^[I].Kind=EK_NOTE Then
   If PosOf(Tr^.Ev^[I].D1,Tr^.P.Clef,A)=Pos Then Begin
    Te:=DispT(Tr,Tr^.Ev^[I].T);
    L:=Max2(Tr^.Ev^[I].Len,G);
    If (T>=Te-G Div 2) And (T<Te+L) Then NoteAtClick:=I;
   End;
End;

{ ---- ligne d'evenements, ligne de reglages, regle ---- }

Procedure EventRowClick(X,Y: Integer);
Var Tr: PTrk; J,K,I: Integer;
Begin
 If X>=SCR_W-48 Then Begin
  If Y<=R2_Y+16 Then Toggle(Catch);
  Exit;
 End;
 If X<=75 Then Begin
  If Y<R2_Y+14 Then Begin
   FltOn:=(X<=37);NeedDraw:=True;
  End Else If X>=67 Then Begin
   If (Y>=R2_Y+15) And (Y<=R2_Y+24) And (FltTop>1) Then Dec(FltTop)
   Else If (Y>=R2_Y+26) And (FltTop<NFLT-2) Then Inc(FltTop);
   NeedDraw:=True;
  End Else Begin
   K:=FltTop+(Y-R2_Y-15) Div 8;
   If (K>=1) And (K<=NFLT) Then Begin Flt[K]:=Not Flt[K];NeedDraw:=True;End;
  End;
  Exit;
 End;
 Tr:=CT;
 If Tr^.Ev=Nil Then Exit;
 J:=(Y-R2_Y-3) Div 11;
 If J=0 Then I:=NextFlt(Tr,CurEv,-1) Else If J=2 Then I:=NextFlt(Tr,CurEv,1) Else I:=0;
 If I>0 Then Begin CurEv:=I;NeedDraw:=True;End;
End;

Procedure SetRowClick(X,Y: Integer; Btn: LongInt);
Var D: Integer;
Begin
 If (Btn And 2)<>0 Then D:=-1 Else D:=1;
 If X<=52 Then Begin HyperKind:=(HyperKind+D+6) Mod 6;SetNo:=HyperKind+1;End
 Else If X<=118 Then ZoomX:=Integer(Clamp(ZoomX+D,1,8))
 Else If X<=184 Then ZoomY:=Integer(Clamp(ZoomY+D,1,20))
 Else If X<=250 Then Begin PenVel:=Integer(Clamp(PenVel+D*5,1,127)); End
 Else If X<=318 Then ColorNo:=(ColorNo+D+4) Mod 4
 Else If X<=396 Then FlAutoIns:=Not FlAutoIns
 Else If X<=462 Then FlFixVel:=Not FlFixVel
 Else If X<=532 Then FlAllCha:=Not FlAllCha
 Else FlLockScore:=Not FlLockScore;
 NeedDraw:=True;
End;

Procedure RulerClick(X,Y: Integer; Btn: LongInt);
Var T: LongInt;
Begin
 If X>SCX2 Then Begin
  If X<=SCX2+8 Then Begin If ViewBar>0 Then Dec(ViewBar);End
  Else If ViewBar<254 Then Inc(ViewBar);
  NeedDraw:=True;Exit;
 End;
 If X<TimeX0 Then Exit;
 T:=SnapT(TickOfX(X));
 If (Btn And 2)<>0 Then Begin
  LocL:=T;If LocR<=LocL Then LocR:=LocL+BarTicks;NeedDraw:=True;
 End Else SetPos(T);
End;

{ ---- editeur hyper ---- }

Procedure HyperEdit(X,Y: Integer; First: Boolean);
Var Tr: PTrk; T,Mx,V: LongInt; I,Fnd: Integer; YB: Integer; Done: Boolean;
Begin
 If FlLockScore Then Exit;
 Tr:=CT;
 T:=SnapT(TickOfX(X));Mx:=HyperMax;
 YB:=BODY_Y+HYP_H-3;
 V:=Clamp(((YB-Y)*Mx) Div (HYP_H-8),0,Mx);
 If (Not First) And (T=HyLastT) And (V=HyLastV) Then Exit;
 HyLastT:=T;HyLastV:=V;
 If First Then SaveUndo(TrkIdx);
 Fnd:=0;
 If Tr^.Ev<>Nil Then Begin
  I:=1;Done:=False;
  While (I<=Tr^.Cnt) And Not Done Do Begin
   If HyperKind=0 Then Begin
    If (Tr^.Ev^[I].Kind=EK_NOTE) And (DispT(Tr,Tr^.Ev^[I].T)=T) Then Fnd:=I;
   End Else If HyperKind=5 Then Begin
    If (Tr^.Ev^[I].Kind=EK_BEND) And (Tr^.Ev^[I].T=T) Then Fnd:=I;
   End Else If (Tr^.Ev^[I].Kind=EK_CTRL) And (Tr^.Ev^[I].D1=HyperCC[HyperKind])
      And (Tr^.Ev^[I].T=T) Then Fnd:=I;
   If Fnd>0 Then Done:=True;
   Inc(I);
  End;
 End;
 If Fnd>0 Then Begin
  If HyperKind=5 Then Begin
   Tr^.Ev^[Fnd].D1:=V Mod 128;Tr^.Ev^[Fnd].D2:=V Div 128;
  End Else If HyperKind=0 Then Tr^.Ev^[Fnd].D2:=Integer(Clamp(V,1,127))
  Else Tr^.Ev^[Fnd].D2:=V;
 End Else If HyperKind=5 Then AddEv(TrkIdx,T,0,EK_BEND,V Mod 128,V Div 128)
 Else If HyperKind>0 Then AddEv(TrkIdx,T,0,EK_CTRL,HyperCC[HyperKind],V);
 Modified:=True;NeedDraw:=True;
End;

{ ---- partition ---- }

Procedure InsertSym(Tk: Integer; T: LongInt);
Var S: String; E,K: Integer; L: LongInt;
Begin
 If Tk<=6 Then Begin
  S:='';
  If Not InputBox(T3('Text','Texte','Text'),T3('Text','Texte','Text'),S,18) Then Exit;
  If S='' Then Exit;
  E:=NewText(S);
  If E=0 Then Begin Info('Text pool full.','Table de textes pleine.','Textspeicher voll.');Exit;End;
  K:=AddEv(TrkIdx,T,0,EK_TEXT,0,Tk-4);
  If K>0 Then CT^.Ev^[K].Sty:=E;
 End Else Begin
  L:=0;
  If (Tk-14=7) Or (Tk-14=8) Or (Tk-14=12) Then L:=PPQ*2;
  K:=AddEv(TrkIdx,T,L,EK_SYM,Tk-14,0);
 End;
 If K>0 Then CurEv:=K;
End;

Procedure ScoreClick(X,Y: Integer; Btn: LongInt);
Var I,Row,K,Pos,Pit,A,Cell: Integer; Tr: PTrk; T,Ts: LongInt; YT,YB: Integer;
 Right: Boolean;
Begin
 Right:=(Btn And 2)<>0;
 If X>SCX2 Then Begin
  If Y<BODY_Y+15 Then Begin If TrkTop>1 Then Dec(TrkTop);End
  Else If Y>BODY_B-15 Then Begin If TrkTop<VN Then Inc(TrkTop);End;
  NeedDraw:=True;Exit;
 End;
 If X<PAL_W Then Begin
  If ShowHyper And (Y<BODY_Y+16) Then Begin CmdHyperKind;Exit;End;
  If Y<PalY0 Then Exit;
  Cell:=((Y-PalY0) Div 16)*2+(X Div 24)+1;
  Case Cell Of
   1..6: Tool:=Cell;
   7..12: Begin PenDur:=Cell-7;Tool:=2;End;
   13: Begin PenDot:=Not PenDot;If PenDot Then PenTrip:=False;End;
   14: Begin PenTrip:=Not PenTrip;If PenTrip Then PenDot:=False;End;
   15..28: Tool:=Cell;
   29: HeadSty:=(HeadSty+1) Mod 5;
  End;
  NeedDraw:=True;Exit;
 End;
 If ShowHyper And (Y>=BODY_Y) And (Y<BODY_Y+HYP_H) Then Begin
  If X>=NOTEX0 Then Begin DragKind:=1;HyperEdit(X,Y,True);End;
  Exit;
 End;
 BuildVT;SetKeyAcc;
 Row:=(Y-ScoreTop) Div TrkSp+1;
 If (Y<ScoreTop) Or (TrkTop+Row-1>VN) Or (Row<1) Then Exit;
 K:=VT[TrkTop+Row-1];
 If K<>CurTrk Then Begin CurTrk:=K;CurEv:=1;End;
 Tr:=CT;
 If X<NOTEX0-6 Then Begin NeedDraw:=True;Exit;End;
 YT:=ScoreTop+(Row-1)*TrkSp+22;YB:=YT+24;
 T:=TickOfX(X);Ts:=SnapT(T);
 If YB-Y>=0 Then Pos:=(YB-Y+1) Div 3 Else Pos:=-((Y-YB+1) Div 3);
 I:=NoteAtClick(Tr,T,Pos);
 If Right Or (Tool=3) Then Begin
  If FlLockScore Then Exit;
  If I>0 Then Begin SaveUndo(TrkIdx);DelEv(Tr,I);NeedDraw:=True;End;
  Exit;
 End;
 Case Tool Of
  1: Begin
      If I>0 Then Begin
       If Tr^.Ev^[I].Sel Then Tr^.Ev^[I].Sel:=False Else Begin
        SelAll(Tr,False);Tr^.Ev^[I].Sel:=True;End;
       CurEv:=I;
      End Else If Tr<>Nil Then SelAll(Tr,False);
      NeedDraw:=True;
     End;
  2: Begin
      If FlLockScore Then Exit;
      If I>0 Then Begin
       SelAll(Tr,False);Tr^.Ev^[I].Sel:=True;CurEv:=I;
      End Else Begin
       Pit:=PitchAtPos(Pos,Tr^.P.Clef);
       SaveUndo(TrkIdx);
       K:=AddEv(TrkIdx,Ts,PenTicks,EK_NOTE,Pit,PenVel);
       If K>0 Then Begin Tr^.Ev^[K].Sty:=HeadSty;CurEv:=K;PreviewNote(Pit,PenVel);End;
      End;
      NeedDraw:=True;
     End;
  4..6,15..28: Begin
      If FlLockScore Then Exit;
      SaveUndo(TrkIdx);
      InsertSym(Tool,Ts);
      NeedDraw:=True;
     End;
 End;
End;

{ ---- matrice ---- }

Procedure MatrixClick(X,Y: Integer; Btn: LongInt);
Var R,I,K,Pit: Integer; Tr: PTrk; T,Ts,G,Te,L: LongInt; Fnd: Integer;
Begin
 If X>SCX2 Then Begin
  If Y<BODY_Y+15 Then MatTop:=Integer(Clamp(MatTop+6,11,127))
  Else If Y>BODY_B-15 Then MatTop:=Integer(Clamp(MatTop-6,11,127));
  NeedDraw:=True;Exit;
 End;
 If Y<BODY_Y+12 Then Exit;
 Tr:=CT;
 R:=(Y-BODY_Y-12) Div MatRowH+1;
 Pit:=MatPitch(R);
 If Pit<0 Then Exit;
 If X<190 Then Begin PreviewNote(Pit,PenVel);Exit;End;
 If FlLockScore Then Exit;
 G:=QuaTicks(FmtQ);If G=0 Then G:=PPQ Div 4;
 T:=TickOfX(X);Ts:=SnapT(T);
 If Ts>T Then Begin
  If (T Div G)*G+G>T Then Ts:=(T Div G)*G;
 End;
 Fnd:=0;
 If Tr^.Ev<>Nil Then
  For I:=1 To Tr^.Cnt Do
   If (Tr^.Ev^[I].Kind=EK_NOTE) And (Tr^.Ev^[I].D1=Pit) Then Begin
    Te:=DispT(Tr,Tr^.Ev^[I].T);
    If Tr^.P.Drum Then L:=G Else L:=Max2(Tr^.Ev^[I].Len,G);
    If (T>=Te) And (T<Te+L) Then Fnd:=I;
   End;
 SaveUndo(TrkIdx);
 If Fnd>0 Then DelEv(Tr,Fnd)
 Else If (Btn And 2)=0 Then Begin
  If Tr^.P.Drum Then K:=AddEv(TrkIdx,Ts,G,EK_NOTE,Pit,100)
  Else K:=AddEv(TrkIdx,Ts,PenTicks,EK_NOTE,Pit,PenVel);
  PreviewNote(Pit,PenVel);
 End;
 NeedDraw:=True;
End;

{ ---- liste ---- }

Procedure EditEvent(Idx: Integer);
Var Tr: PTrk; B,Bt,Sx,Tk: LongInt; S: String;
Begin
 Tr:=CT;
 If (Tr^.Ev=Nil) Or (Idx<1) Or (Idx>Tr^.Cnt) Then Exit;
 If Tr^.Ev^[Idx].Kind=EK_TEXT Then Begin
  If (Tr^.Ev^[Idx].Sty>=1) Then Begin
   S:=TxtPool[Tr^.Ev^[Idx].Sty];
   If InputBox(T3('Text','Texte','Text'),T3('Text','Texte','Text'),S,18) Then
    TxtPool[Tr^.Ev^[Idx].Sty]:=Copy(S,1,20);
  End;
  NeedDraw:=True;Exit;
 End;
 TickToBBT(Tr^.Ev^[Idx].T,B,Bt,Sx,Tk);
 FormLbl[1]:=T3('Bar','Mesure','Takt');FormVal[1]:=IntStr(B);
 FormLbl[2]:=T3('Beat','Temps','Schlag');FormVal[2]:=IntStr(Bt);
 FormLbl[3]:='1/16';FormVal[3]:=IntStr(Sx);
 FormLbl[4]:='Tick';FormVal[4]:=IntStr(Tk);
 FormLbl[5]:='Data 1';FormVal[5]:=IntStr(Tr^.Ev^[Idx].D1);
 FormLbl[6]:='Data 2';FormVal[6]:=IntStr(Tr^.Ev^[Idx].D2);
 FormLbl[7]:=T3('Length','Dur'#130'e','L'#132'nge');FormVal[7]:=IntStr(Tr^.Ev^[Idx].Len);
 FormFW:=8;
 If Not FormBox(EvStatus(Tr^.Ev^[Idx]),7) Then Exit;
 SaveUndo(TrkIdx);
 Tr^.Ev^[Idx].T:=BBTToTick(Max2(1,ToInt(FormVal[1])),Max2(1,ToInt(FormVal[2])),
   Max2(1,ToInt(FormVal[3])),Max2(1,ToInt(FormVal[4])));
 Tr^.Ev^[Idx].D1:=Integer(Clamp(ToInt(FormVal[5]),0,127));
 Tr^.Ev^[Idx].D2:=Integer(Clamp(ToInt(FormVal[6]),0,127));
 Tr^.Ev^[Idx].Len:=Max2(0,ToInt(FormVal[7]));
 SortTrk(Tr);
 Modified:=True;NeedDraw:=True;
End;

Procedure ListInsert;
Var K: Integer;
Begin
 SaveUndo(TrkIdx);
 K:=AddEv(TrkIdx,PosTick,PenTicks,EK_NOTE,60,PenVel);
 If K>0 Then Begin CurEv:=K;EditEvent(K);End;
 NeedDraw:=True;
End;

Procedure ListClick(X,Y: Integer);
Var Tr: PTrk; L,I,N: Integer;
Begin
 If X>SCX2 Then Begin
  Tr:=CT;
  If Y<BODY_Y+15 Then Begin
   I:=NextFlt(Tr,CurEv,-1);If I>0 Then CurEv:=I;
  End Else If Y>BODY_B-15 Then Begin
   I:=NextFlt(Tr,CurEv,1);If I>0 Then CurEv:=I;
  End;
  NeedDraw:=True;Exit;
 End;
 If Y<BODY_Y+17 Then Exit;
 Tr:=CT;
 If Tr^.Ev=Nil Then Exit;
 L:=(Y-(BODY_Y+18)) Div LST_ROW;
 I:=ListTop;N:=0;
 If (I<=Tr^.Cnt) And Not Passes(Tr^.Ev^[I]) Then I:=NextFlt(Tr,I,1);
 While (I>=1) And (N<L) Do Begin I:=NextFlt(Tr,I,1);Inc(N);End;
 If I>=1 Then Begin
  CurEv:=I;
  If DblClick(100+I) Then EditEvent(I);
  NeedDraw:=True;
 End;
End;

{ ---- page arrangement ---- }

Procedure EditLoc(Left: Boolean);
Var T,B,Bt,Sx,Tk: LongInt;
Begin
 If Left Then T:=LocL Else T:=LocR;
 TickToBBT(T,B,Bt,Sx,Tk);
 FormLbl[1]:=T3('Bar','Mesure','Takt');FormVal[1]:=IntStr(B);
 FormLbl[2]:=T3('Beat','Temps','Schlag');FormVal[2]:=IntStr(Bt);
 FormLbl[3]:='1/16';FormVal[3]:=IntStr(Sx);
 FormLbl[4]:='Tick';FormVal[4]:=IntStr(Tk);
 FormFW:=6;
 If Left Then Begin
  If Not FormBox('LEFT LOCATOR',4) Then Exit;
 End Else If Not FormBox('RIGHT LOCATOR',4) Then Exit;
 T:=BBTToTick(Max2(1,ToInt(FormVal[1])),Max2(1,ToInt(FormVal[2])),
   Max2(1,ToInt(FormVal[3])),Max2(1,ToInt(FormVal[4])));
 If Left Then Begin LocL:=T;If LocR<=LocL Then LocR:=LocL+BarTicks;End
 Else Begin LocR:=T;If LocL>=LocR Then LocL:=Max2(0,LocR-BarTicks);End;
 NeedDraw:=True;
End;

Procedure BtnAction(I: Integer);
Var T: Integer; Any: Boolean; Tr: PTrk;
Begin
 Case I Of
  1: CmdDrop;
  2: DoUndo;
  3: Toggle(FlPunch);
  4: CmdRecord;
  5: Begin
      Any:=False;
      For T:=1 To TPP Do If Trks[TI(CurPat,T)]<>Nil Then
        If Trks[TI(CurPat,T)]^.Sel Then Any:=True;
      If Not Any Then CT^.Sel:=True;
      View:=V_SCORE;NeedDraw:=True;
     End;
  6: CmdDoQuantize;
  7: Begin CT^.P.Solo:=Not CT^.P.Solo;UpdateSolo;NeedDraw:=True;End;
  8: Begin CT^.P.Mute:=Not CT^.P.Mute;NeedDraw:=True;End;
  9: CmdResetPar;
  10: Toggle(FlAutoDrop);
  11: Toggle(FlCycle);
  12: Begin View:=V_MATRIX;NeedDraw:=True;End;
  13: CmdStart;
  14: CmdCont;
  15: CmdStop;
 End;
End;

Procedure ArrangeClick(X,Y: Integer; Btn: LongInt);
Var R,I,C,X1,Y1,X2,Y2: Integer; Tr: PTrk; D: Integer;
Begin
 If (Btn And 2)<>0 Then D:=-1 Else D:=1;
 { panneau gauche }
 If X<AR_MX-4 Then Begin
  If InBox(X,Y,AR_MX-20,BODY_B-60,AR_MX-6,BODY_B-46) Then Begin
   If ArrTop>1 Then Dec(ArrTop,3);If ArrTop<1 Then ArrTop:=1;NeedDraw:=True;Exit;End;
  If InBox(X,Y,AR_MX-20,BODY_B-44,AR_MX-6,BODY_B-30) Then Begin
   If ArrTop<NPAT-AR_ROWS+1 Then Inc(ArrTop,3);NeedDraw:=True;Exit;End;
  If InBox(X,Y,AR_LX+2,BODY_B-58,AR_LX+110,BODY_B-34) Then Begin CmdPatLen;Exit;End;
  R:=(Y-(R2_Y+16)) Div AR_ROWH;
  I:=ArrTop+R;
  If (Y>=R2_Y+16) And (R<AR_ROWS) And (I>=1) And (I<=NPAT) Then Begin
   CurPat:=I;
   If X>=AR_LX+114 Then Begin
    C:=(X-AR_LX-114) Div 24+1;
    If (C>=1) And (C<=4) Then Begin
     Pats[I].Rep[C]:=Integer(Clamp(Pats[I].Rep[C]+D,0,99));
     Modified:=True;
    End;
   End Else If X>=AR_LX+20 Then Begin
    If DblClick(I) Then CmdPatName;
   End;
   NeedDraw:=True;
  End;
  Exit;
 End;
 { panneau central }
 If X<AR_RX-4 Then Begin
  R:=(Y-(R2_Y+17)+2) Div 16+1;
  If (R>=1) And (R<=TPP) And (Y>=R2_Y+15) Then Begin
   CurTrk:=R;CurEv:=1;
   Tr:=GetTrk(TI(CurPat,R));
   If X>=AR_MX+194 Then Tr^.P.Mute:=Not Tr^.P.Mute
   Else If X>=AR_MX+184 Then Begin Tr^.P.Solo:=Not Tr^.P.Solo;UpdateSolo;End
   Else If DblClick(200+R) Then CmdTrackSettings
   Else Tr^.Sel:=Not Tr^.Sel;
   NeedDraw:=True;
  End;
  Exit;
 End;
 { panneau droit }
 For I:=1 To NBTN Do Begin
  BtnRect(I,X1,Y1,X2,Y2);
  If InBox(X,Y,X1,Y1,X2,Y2) Then Begin BtnAction(I);Exit;End;
 End;
 For I:=1 To NPAR Do
  If InBox(X,Y,AR_RX+6,R2_Y+16+(I-1)*13,SCR_W-4,R2_Y+16+(I-1)*13+11) Then Begin
   EditPar(I);Exit;End;
 R:=R2_Y+18+NPAR*13+8;
 If InBox(X,Y,AR_RX+6,R+12,AR_RX+150,R+24) Then Begin EditLoc(True);Exit;End;
 If InBox(X,Y,AR_RX+6,R+42,AR_RX+150,R+54) Then Begin EditLoc(False);Exit;End;
End;

{ ---- distribution ---- }

Procedure MouseDown(X,Y: Integer; Btn: LongInt);
Var T: Integer;
Begin
 If (Y>=TB_Y) And (Y<TB_Y+TB_H) Then Begin
  If X<TB_H Then CmdQuit;
  Exit;
 End;
 If (Y>=R1_Y) And (Y<=R1_B) Then Begin
  If X<=55 Then CmdFreeMem
  Else If X<=115 Then Toggle(FlArrange)
  Else If X<=175 Then CmdSyncDel
  Else If X<=232 Then Begin SyncMode:=(SyncMode+1) Mod 3;NeedDraw:=True;End
  Else If X<=303 Then CmdTempo
  Else If X<=356 Then CmdFormat
  Else If X<=431 Then CmdSignature
  Else If X>=518 Then CmdGoto;
  Exit;
 End;
 If View=V_ARR Then Begin ArrangeClick(X,Y,Btn);Exit;End;
 If (Y>=R2_Y) And (Y<=R2_B) Then Begin EventRowClick(X,Y);Exit;End;
 If (Y>=R3_Y) And (Y<=R3_B) Then Begin SetRowClick(X,Y,Btn);Exit;End;
 If (Y>=RL_Y) And (Y<=RL_B) Then Begin
  If View<>V_LIST Then RulerClick(X,Y,Btn);Exit;End;
 If Y>=BODY_Y Then
  Case View Of
   V_SCORE: ScoreClick(X,Y,Btn);
   V_MATRIX: MatrixClick(X,Y,Btn);
   V_LIST: ListClick(X,Y);
  End;
End;

Procedure MouseMove(X,Y: Integer);
Begin
 If (DragKind=1) And ((MB And 1)<>0) Then HyperEdit(X,Y,False);
End;

Procedure MouseUp;
Begin
 DragKind:=0;
End;

{ ---- clavier ---- }

Procedure ScrollTo(Bar: LongInt);
Begin
 If Bar<0 Then Bar:=0;
 If Bar>254 Then Bar:=254;
 ViewBar:=Bar;
 NeedDraw:=True;
End;

Procedure HandleKey(K: Word);
Var P,I: Integer; Tr: PTrk;
Begin
 Tr:=CT;
 Case K Of
  K_ESC: If Playing Then StopPlay;
  K_F1..K_F1+3: CmdSetView(K-K_F1+1);
  K_F1+4..K_F1+9: Begin PenDur:=K-K_F1-4;Tool:=2;NeedDraw:=True;End;
  K_F11: CmdHelp;
  K_F12: RunMenu(2,False);
  32: CmdStart;
  K_ENTER: CmdCont;
  42: CmdRecord;
  Ord('['): CmdSetLoc(True);
  Ord(']'): CmdSetLoc(False);
  Ord('-'): Begin If Oct>0 Then Dec(Oct);End;
  Ord('+'),Ord('='): Begin If Oct<8 Then Inc(Oct);End;
  K_TAB: Begin CurTrk:=(CurTrk Mod TPP)+1;CurEv:=1;If View=V_MATRIX Then CenterMatrix;NeedDraw:=True;End;
  K_STAB: Begin CurTrk:=CurTrk-1;If CurTrk<1 Then CurTrk:=TPP;CurEv:=1;If View=V_MATRIX Then CenterMatrix;NeedDraw:=True;End;
  K_HOME: Begin SetPos(0);ScrollTo(0);ListTop:=1;CurEv:=1;End;
  K_END: Begin ScrollTo(Pats[CurPat].Len-1);SetPos(PatTicks(CurPat));End;
  K_LEFT: ScrollTo(ViewBar-1);
  K_RIGHT: ScrollTo(ViewBar+1);
  K_PGUP: If View=V_MATRIX Then Begin MatTop:=Integer(Clamp(MatTop+12,11,127));NeedDraw:=True;End
          Else ScrollTo(ViewBar-3);
  K_PGDN: If View=V_MATRIX Then Begin MatTop:=Integer(Clamp(MatTop-12,11,127));NeedDraw:=True;End
          Else ScrollTo(ViewBar+3);
  K_UP,K_DOWN: Begin
    If View=V_LIST Then Begin
     If K=K_UP Then I:=NextFlt(Tr,CurEv,-1) Else I:=NextFlt(Tr,CurEv,1);
     If I>0 Then CurEv:=I;
     If CurEv<ListTop Then ListTop:=CurEv;
     If CurEv>=ListTop+ListRows Then ListTop:=CurEv-ListRows+1;
     NeedDraw:=True;
    End Else If View=V_MATRIX Then Begin
     If K=K_UP Then MatTop:=Integer(Clamp(MatTop+1,11,127))
     Else MatTop:=Integer(Clamp(MatTop-1,11,127));
     NeedDraw:=True;
    End Else If (View=V_SCORE) And (SelCount(Tr)>0) Then Begin
     SaveUndo(TrkIdx);
     For I:=1 To Tr^.Cnt Do
      If Tr^.Ev^[I].Sel And (Tr^.Ev^[I].Kind=EK_NOTE) Then
       If K=K_UP Then Tr^.Ev^[I].D1:=Integer(Clamp(Tr^.Ev^[I].D1+1,0,127))
       Else Tr^.Ev^[I].D1:=Integer(Clamp(Tr^.Ev^[I].D1-1,0,127));
     Modified:=True;NeedDraw:=True;
    End Else Begin
     If K=K_UP Then Begin If CurTrk>1 Then Dec(CurTrk);End
     Else If CurTrk<TPP Then Inc(CurTrk);
     CurEv:=1;NeedDraw:=True;
    End;
   End;
  K_DEL: CmdDelete;
  K_INS: If View=V_LIST Then ListInsert;
  K_CLEFT,K_CRIGHT: Begin End;
  14: CmdNew;
  12: CmdLoad;
  19: CmdSave;
  17: CmdQuit;
  7: CmdGoto;
  26: DoUndo;
  24: CmdCopyEv(True);
  3: CmdCopyEv(False);
  22: CmdPaste;
  1: CmdSelAll(True);
 Else
  Begin
   If (K=K_ENTER) And (View=V_LIST) Then EditEvent(CurEv);
   P:=PianoKey(K);
   If P>=0 Then Begin
    If Playing And Recording Then Begin
     RecNoteOn(P,PenVel,PenTicks);
     SndOn(Tr^.P.Port,Tr^.P.Chan,P,PenVel,PlayTick+PenTicks,False);
    End Else Begin
     PreviewNote(P,PenVel);
     If FlAutoIns And (View<>V_ARR) And (Not FlLockScore) And (Not Playing) Then Begin
      SaveUndo(TrkIdx);
      I:=AddEv(TrkIdx,PosTick,PenTicks,EK_NOTE,P,PenVel);
      If I>0 Then Begin
       CurEv:=I;Tr^.Ev^[I].Sty:=HeadSty;
       PosTick:=PosTick+PenTicks;
       If (View=V_SCORE) Or (View=V_MATRIX) Then
        If XOfTick(PosTick)>SCX2-20 Then ViewBar:=PosTick Div BarTicks;
      End;
      NeedDraw:=True;
     End;
    End;
   End;
  End;
 End;
End;

{ ====================================================================== }
{                          DESSIN GLOBAL                                 }
{ ====================================================================== }

Procedure DrawAll;
Begin
 HideMouse;
 SetViewPort(0,0,SCR_W-1,SCR_H-1,True);
 Box(0,0,SCR_W-1,SCR_H-1,PAPER);
 DrawTitleBar;
 DrawTransport;
 Case View Of
  V_ARR: DrawArrange;
  V_SCORE: Begin DrawEventRow;DrawSetRow;DrawScoreView;End;
  V_MATRIX: Begin DrawEventRow;DrawSetRow;DrawMatrixView;End;
  V_LIST: Begin DrawEventRow;DrawSetRow;DrawListView;End;
 End;
 DrawMenuBar;
 DrawDropDown;
 PlayX:=-1;
 DrawPlayhead;
 ShowMouse;
 NeedDraw:=False;
End;

{ ====================================================================== }
{                          INITIALISATION                                }
{ ====================================================================== }

Procedure InitData;
Var S: String; I: Integer;
Begin
 S:=Upper(Copy(GetEnv('LANGUAGE'),1,2));
 If S='EN' Then Lang:=0
 Else If (S='GR') Or (S='DE') Then Lang:=2
 Else Lang:=1;
 FillChar(Trks,SizeOf(Trks),0);
 FillChar(Snd,SizeOf(Snd),0);
 FlAutoIns:=True;FlFixVel:=True;FlAllCha:=True;FlLockScore:=False;
 FlClick:=False;FlCountIn:=False;FlThru:=True;FlAutoDrop:=True;FlCycle:=False;
 FlPunch:=False;FlFollow:=True;FlArrange:=False;
 PenVel:=80;ZoomX:=3;ZoomY:=10;SetNo:=2;ColorNo:=0;
 RestQ:=3;OutDev:=0;MpuPort:=$330;PrnDest:='NOTATOR.PRN';
 PenDur:=2;PenDot:=False;PenTrip:=False;
 Tool:=2;HeadSty:=0;ShowHyper:=True;HyperKind:=1;
 FltOn:=False;FltTop:=1;Catch:=False;
 For I:=1 To NFLT Do Flt[I]:=True;
 Oct:=4;ArrTop:=1;View:=V_ARR;
 UndoBuf:=Nil;ClipBuf:=Nil;MBuf:=Nil;Msg:=Nil;
 Playing:=False;Recording:=False;CountInOn:=False;
 SoloAny:=False;SpkFreq:=0;ClickUntil:=0;InSt:=0;InN:=0;
 MenuOpen:=0;MenuHi:=0;DragKind:=0;LastClkId:=-1;NeedDraw:=True;
 MX:=0;MY:=0;MB:=0;LastB:=0;
 NtPPQ:=0;StrN:=0;UseStretch:=False;


 InitSong;
 ResetView;
End;

Procedure ShowHelpLine;
Var H: Text;
Begin
 Assign(H,'');Rewrite(H);
 If Lang=0 Then Begin
  WriteLn(H,'NOTATOR - Graphical clone of the Notator SL sequencer / score editor.');
  WriteLn(H);
  WriteLn(H,'Usage : NOTATOR [file.SON | file.MID] [/PLAY] [/?]');
  WriteLn(H);
  WriteLn(H,'  file.SON  Song to open.');
  WriteLn(H,'  file.MID  Standard MIDI file to import in the current pattern.');
  WriteLn(H,'  /PLAY     Play the file immediately in the GUI.');
  WriteLn(H,'  /?        Show this help.');
  WriteLn(H,'  In the GUI, the space bar plays / stops the sound or MIDI.');
  WriteLn(H);
  WriteLn(H,'Language : French by default, LANGUAGE=EN for English,');
  WriteLn(H,'LANGUAGE=GR for German.');
 End Else If Lang=2 Then Begin
  WriteLn(H,'NOTATOR - Grafischer Klon des Sequenzers / Partitur-Editors Notator SL.');
  WriteLn(H);
  WriteLn(H,'Aufruf : NOTATOR [Datei.SON | Datei.MID] [/PLAY] [/?]');
  WriteLn(H);
  WriteLn(H,'  /PLAY  Datei sofort in der Oberfl'#132'che abspielen.');
  WriteLn(H,'  Leertaste = Song oder MIDI abspielen / stoppen.');
  WriteLn(H);
  WriteLn(H,'Sprache : Franz'#148'sisch als Standard, LANGUAGE=EN f'#129'r Englisch,');
  WriteLn(H,'LANGUAGE=GR f'#129'r Deutsch.');
 End Else Begin
  WriteLn(H,'NOTATOR - Cette commande permet de lancer le clone graphique '+
            'du s'#130'quenceur / '#130'diteur de partition Notator SL.');
  WriteLn(H);
  WriteLn(H,'Syntaxe : NOTATOR [fichier.SON | fichier.MID] [/PLAY] [/?]');
  WriteLn(H);
  WriteLn(H,'  fichier.SON  Morceau '#133' ouvrir.');
  WriteLn(H,'  fichier.MID  Fichier MIDI standard '#133' importer dans le pattern courant.');
  WriteLn(H,'  /PLAY        Joue imm'#130'diatement le fichier dans l''interface.');
  WriteLn(H,'  /?           Affiche cette aide.');
  WriteLn(H,'  Dans l''interface, la barre d''espacement joue / arr'#136'te le son.');
  WriteLn(H);
  WriteLn(H,'Langue : fran'#135'ais par d'#130'faut, LANGUAGE=EN pour l''anglais,');
  WriteLn(H,'LANGUAGE=GR pour l''allemand.');
 End;
 Close(H);
End;

Procedure LoadCommandLine;
Var Name,Ext: String; I: Integer; PlayNow,Loaded: Boolean;
Begin
 Name:='';PlayNow:=False;Loaded:=False;
 For I:=1 To ParamCount Do
  If (Upper(ParamStr(I))='/PLAY') Or (Upper(ParamStr(I))='-PLAY') Or
     (Upper(ParamStr(I))='--PLAY') Then PlayNow:=True
  Else If Name='' Then Name:=ParamStr(I);
 If Name='' Then Exit;
 Ext:=Upper(Copy(Name,Length(Name)-3,4));
 If Ext='.MID' Then Begin
  If LoadMidi(Name) Then Begin
   ResetView;View:=V_SCORE;
   SongName:=Copy(ShortName(Name),1,Pos('.',ShortName(Name))-1)+'.SON';
   SongNamed:=False;
   Loaded:=True;
  End;
 End Else Begin
  Name:=AddExt(Name,'SON');
  If FileExists(Name) Then
   If LoadSong(Name) Then Begin ResetView;View:=V_ARR;Loaded:=True;End;
 End;
 If PlayNow And Loaded Then CmdStart;
End;

Procedure MainLoop;
Var E: TEvent;
Begin
 Repeat
  If NeedDraw Then DrawAll;
  PollEvent(E);
  Case E.Kind Of
   1: HandleKey(E.Key);
   2: MouseDown(E.X,E.Y,E.B);
   3: MouseUp;
   4: MouseMove(E.X,E.Y);
   5: If E.Key=9999 Then CmdQuit
      Else DoMenu(E.Key Div 100,E.Key Mod 100);
  End;
  UpdatePlayDisplay;
 Until Quit;
End;

{ fenetre principale : zone client de 640 x 446 (lignes 34 a 479 de l'image ;
  les lignes 0 a 33 de la version DOS, barre de menus et barre de titre GEM,
  sont la barre de titre et la barre de menus de PM) }
Procedure OpenWindow;
Var Fl,W,H,X,Y,Sw,Sh: LongInt; Rc: Array[0..3] Of LongInt;
Begin
 Hab:=WinInitialize(0);
 Hmq:=WinCreateMsgQueue(Hab,64);
 Dummy:=WinRegisterClass(Hab,Z('NOTATOR'),LongInt(@ClientProc),0,0);
 Fl:=FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_TASKLIST Or FCF_DLGBORDER;
 Client:=0;
 HFrame:=WinCreateStdWindow(HWND_DESKTOP,0,LongInt(@Fl),Z('NOTATOR'),
   Z2('Notator for OS2-Zero'),0,0,0,LongInt(@Client));
 Dummy:=WinSubclassWindow(HFrame,LongInt(@FrameProc));
 BuildMenuBar;
 Rc[0]:=0;Rc[1]:=0;Rc[2]:=ScrW;Rc[3]:=ScrH-CanvasTop;
 Dummy:=WinCalcFrameRect(HFrame,LongInt(@Rc),0);
 W:=Rc[2]-Rc[0];H:=Rc[3]-Rc[1];
 Sw:=WinQuerySysValue(HWND_DESKTOP,20);Sh:=WinQuerySysValue(HWND_DESKTOP,21);
 X:=(Sw-W) Div 2;Y:=(Sh-H) Div 2;
 If X<0 Then X:=0;
 { ecran trop petit : barre de titre en haut de l'ecran }
 If Y<0 Then Y:=Sh-H;
 Dummy:=WinSetWindowPos(HFrame,HWND_TOP,X,Y,W,H,
   SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
 Dummy:=WinSetFocus(HWND_DESKTOP,Client);
End;

BEGIN
 Quit:=False;
 If (ParamCount>=1) And ((ParamStr(1)='/?') Or (ParamStr(1)='-h')
     Or (ParamStr(1)='--help')) Then Begin
  Lang:=1;
  If Upper(Copy(GetEnv('LANGUAGE'),1,2))='EN' Then Lang:=0;
  If (Upper(Copy(GetEnv('LANGUAGE'),1,2))='GR') Or
     (Upper(Copy(GetEnv('LANGUAGE'),1,2))='DE') Then Lang:=2;
  ShowHelpLine;
  Halt(0);
 End;
 InitData;
 LoadOptions(GetEnv('LANGUAGE')='');
 If OutDev=1 Then OutDev:=0;
 InitBmi;
 EvHead:=0;EvTail:=0;HFrame:=0;Client:=0;LastTitle:='';MenuLang:=-1;
 StrBuf:=Nil;WaveOpened:=False;
 OpenWindow;
 If OutDev=0 Then
  If Not SynthStart Then OutDev:=2;
 LoadCommandLine;
 MainLoop;
 AllNotesOff;
 SynthStop;
 Dummy:=WinDestroyWindow(HFrame);
END.
