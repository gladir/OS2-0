{ @author: Sylvain Maltais (support@gladir.com)
  @created: 1992 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: SOKOBAN - Soko-Ban pour le Presentation Manager d'OS/2-0
                (dossier Jeux du bureau).
}

Program SOKOBAN;

{$R-,S-,I-}

{ Compilation : OS2PC SOKOBAN.PAS   (produit SOKOBAN.EXE)

  Portage vers OS/2-0 du prototype SOKOBAN.PAS du depot 7iles (Turbo
  Pascal, mode texte, 85 etages, F8 et F9 pour changer d'etage, F10 pour
  recommencer, F3 : demonstration du premier etage) : fenetre de
  Presentation Manager avec menus, murs de briques, caisses, cibles,
  souris, annulation, choix de l'etage, barre d'etat et apparence d'OS/2.
  Les 85 etages du prototype sont repris tels quels.

  But : pousser toutes les caisses sur les cibles (losanges). Le
  magasinier pousse une caisse a la fois en marchant contre elle ; il ne
  peut pas tirer, ni pousser deux caisses.

  Clavier : fleches (marcher, pousser), Ctrl+Z ou Retour arriere (annuler
  un pas), F10 ou Echap (recommencer l'etage), F8 et F9 (etage precedent
  et suivant), F3 (demonstration du premier etage, comme le prototype),
  F2 (choisir l'etage), F1 (regles). Souris : cliquer une case libre : le
  magasinier y va par le plus court chemin ; cliquer une caisse voisine :
  la pousser.
  Parametres : /SEED:n ; /LEVEL:n (etage de depart) ; /DEMO (lance la
  demonstration). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_QUERY = $10; MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_BACKSPACE = $05; VK_NEWLINE = $08; VK_ESC = $0F; VK_SPACE = $10; VK_LEFT = $15; VK_UP = $16;
  VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21; VK_F3 = $22; VK_F8 = $27; VK_F9 = $28; VK_F10 = $29;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKPINK = 11; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  CM_RESTART = 101; CM_UNDO = 102; CM_PREV = 103; CM_NEXT = 104; CM_CHOOSE = 105; CM_DEMO = 106; CM_QUIT = 107;
  CM_RULES = 301; CM_ABOUT = 302;
  GWd = 20; GHt = 16; NC = 320;    { grille : 20 colonnes, 16 rangees }
  TOut = 0; TWall = 1; TFloor = 2;
  { disposition (zone client, Y vers le bas) }
  Cs = 22; BX0 = 10; BY0 = 10; AW = 440; AH = 352;
  PnX = 462; PW = 140;
  CWant = 612; CHWant = 398;
  MaxUndo = 8000;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  G, Goal, Box : Array[0..NC - 1] Of LongInt;
  LvRow : Array[0..GHt - 1] Of String[24];
  LvH, LvW, OffX, OffY, Level, Pl, Moves, Pushes, NGoal, Seed, Picking, PickSel, Wait : LongInt;
  Solved, BestMv : Array[1..85] Of LongInt;
  UndoD : Array[0..MaxUndo - 1] Of Byte;   { direction (0 a 3) + 4 si une caisse a ete poussee }
  NUndo : LongInt;
  Path : Array[0..NC - 1] Of LongInt;      { marche vers une case (souris) }
  NPath, IPath, Demo, DemoPos : LongInt;
  DemoS : String;
  Msg : String;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Font : Array[0..4095] Of Byte;
  FontH : LongInt;
  Qmsg : Array[0..7] Of LongInt;

Procedure AddRow(S : String);
Begin
  If LvH < GHt Then
  Begin
    LvRow[LvH] := S;
    Inc(LvH);
  End;
End;


{ --- PMWIN.DLL, PMGPI.DLL, VIOCALLS.DLL, DOSCALLS.DLL --- }
Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinBeginPaint(H, Hps, P : LongInt) : LongInt; External 'PMWIN';
Function WinEndPaint(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinFillRect(Hps, P, C : LongInt) : LongInt; External 'PMWIN';
Function WinDrawText(Hps, Cch, P, PR, Fg, Bg, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(HPar, Id : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinAlarm(HD, Typ : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function VioGetFont(PInfo, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioGetFont';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Type
  PByte = ^Byte;

Procedure WrB(A, V : LongInt);
Var Q : PByte;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Function RdB(A : LongInt) : LongInt;
Var Q : PByte;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Procedure WrW(A, V : LongInt);
Begin
  WrB(A, V And 255);
  WrB(A + 1, (V Shr 8) And 255);
End;

Function RdL(A : LongInt) : LongInt;
Begin
  RdL := RdB(A) Or (RdB(A + 1) Shl 8) Or (RdB(A + 2) Shl 16) Or (RdB(A + 3) Shl 24);
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
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

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
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

Function Rnd(N : LongInt) : LongInt;
Begin
  Seed := (Seed * 1103515245 + 12345) And $7FFFFFFF;
  Rnd := (Seed Shr 8) Mod N;
End;

{ niveaux du prototype SOKOBAN.PAS de 7iles (genere par extract.py) :
  # mur, espace sol, $ caisse, . cible, * caisse sur cible, @ joueur,
  ~ dehors }
Const
  NLevels = 85;

Procedure LevelRows(N : LongInt);
Begin
  LvH := 0;
  Case N Of
    1 :
      Begin
        AddRow('~~~~#####~~~~~~~~~~');
        AddRow('~~~~#   #~~~~~~~~~~');
        AddRow('~~~~#$  #~~~~~~~~~~');
        AddRow('~~###  $##~~~~~~~~~');
        AddRow('~~#  $ $ #~~~~~~~~~');
        AddRow('### # ## #~~~######');
        AddRow('#   # ## #####  ..#');
        AddRow('# $  $          ..#');
        AddRow('##### ### #@##  ..#');
        AddRow('~~~~#     #########');
        AddRow('~~~~#######~~~~~~~~');
      End;
    2 :
      Begin
        AddRow('############~~');
        AddRow('#..  #     ###');
        AddRow('#..  # $  $  #');
        AddRow('#..  #$####  #');
        AddRow('#..    @ ##  #');
        AddRow('#..  # #  $ ##');
        AddRow('###### ##$ $ #');
        AddRow('~~# $  $ $ $ #');
        AddRow('~~#    #     #');
        AddRow('~~############');
      End;
    3 :
      Begin
        AddRow('~~~~~~~~########~');
        AddRow('~~~~~~~~#     @#~');
        AddRow('~~~~~~~~# $#$ ##~');
        AddRow('~~~~~~~~# $  $#~~');
        AddRow('~~~~~~~~##$ $ #~~');
        AddRow('######### $ # ###');
        AddRow('#....  ## $  $  #');
        AddRow('##...    $  $   #');
        AddRow('#....  ##########');
        AddRow('########~~~~~~~~~');
      End;
    4 :
      Begin
        AddRow('~~~~~~~~~~~########');
        AddRow('~~~~~~~~~~~#  ....#');
        AddRow('############  ....#');
        AddRow('#    #  $ $   ....#');
        AddRow('# $$$#$  $ #  ....#');
        AddRow('#  $     $ #  ....#');
        AddRow('# $$ #$ $ $########');
        AddRow('#  $ #     #~~~~~~~');
        AddRow('## #########~~~~~~~');
        AddRow('#    #    ##~~~~~~~');
        AddRow('#     $   ##~~~~~~~');
        AddRow('#  $$#$$  @#~~~~~~~');
        AddRow('#    #    ##~~~~~~~');
        AddRow('###########~~~~~~~~');
      End;
    5 :
      Begin
        AddRow('~~~~~~~~#####~~~~');
        AddRow('~~~~~~~~#   #####');
        AddRow('~~~~~~~~# #$##  #');
        AddRow('~~~~~~~~#     $ #');
        AddRow('######### ###   #');
        AddRow('#....  ## $  $###');
        AddRow('#....    $ $$ ##~');
        AddRow('#....  ##$  $ @#~');
        AddRow('#########  $  ##~');
        AddRow('~~~~~~~~# $ $  #~');
        AddRow('~~~~~~~~### ## #~');
        AddRow('~~~~~~~~~~#    #~');
        AddRow('~~~~~~~~~~######~');
      End;
    6 :
      Begin
        AddRow('######~~###~');
        AddRow('#..  #~##@##');
        AddRow('#..  ###   #');
        AddRow('#..     $$ #');
        AddRow('#..  # # $ #');
        AddRow('#..### # $ #');
        AddRow('#### $ #$  #');
        AddRow('~~~#  $# $ #');
        AddRow('~~~# $  $  #');
        AddRow('~~~#  ##   #');
        AddRow('~~~#########');
      End;
    7 :
      Begin
        AddRow('~~~~~~~#####~');
        AddRow('~#######   ##');
        AddRow('## # @## $$ #');
        AddRow('#    $      #');
        AddRow('#  $  ###   #');
        AddRow('### #####$###');
        AddRow('# $  ### ..#~');
        AddRow('# $ $ $ ...#~');
        AddRow('#    ###...#~');
        AddRow('# $$ #~#...#~');
        AddRow('#  ###~#####~');
        AddRow('####~~~~~~~~~');
      End;
    8 :
      Begin
        AddRow('~~####~~~~~~~~~~');
        AddRow('~~#  ###########');
        AddRow('~~#    $   $ $ #');
        AddRow('~~# $# $ #  $  #');
        AddRow('~~#  $ $  #    #');
        AddRow('### $# #  #### #');
        AddRow('#@#$ $ $  ##   #');
        AddRow('#    $ #$#   # #');
        AddRow('#   $    $ $ $ #');
        AddRow('#####  #########');
        AddRow('~~#      #~~~~~~');
        AddRow('~~#      #~~~~~~');
        AddRow('~~#......#~~~~~~');
        AddRow('~~#......#~~~~~~');
        AddRow('~~#......#~~~~~~');
        AddRow('~~########~~~~~~');
      End;
    9 :
      Begin
        AddRow('~~~~~~~~~~#######');
        AddRow('~~~~~~~~~~#  ...#');
        AddRow('~~~~~~#####  ...#');
        AddRow('~~~~~~#      . .#');
        AddRow('~~~~~~#  ##  ...#');
        AddRow('~~~~~~## ##  ...#');
        AddRow('~~~~~### ########');
        AddRow('~~~~~# $$$ ##~~~~');
        AddRow('~#####  $ $ #####');
        AddRow('##   #$ $   #   #');
        AddRow('#@ $  $    $  $ #');
        AddRow('###### $$ $ #####');
        AddRow('~~~~~#      #~~~~');
        AddRow('~~~~~########~~~~');
      End;
    10 :
      Begin
        AddRow('~###~~#############');
        AddRow('##@####       #   #');
        AddRow('# $$   $$  $ $ ...#');
        AddRow('#  $$$#    $  #...#');
        AddRow('# $   # $$ $$ #...#');
        AddRow('###   #  $    #...#');
        AddRow('#     # $ $ $ #...#');
        AddRow('#    ###### ###...#');
        AddRow('## #  #  $ $  #...#');
        AddRow('#  ## # $$ $ $##..#');
        AddRow('# ..# #  $      #.#');
        AddRow('# ..# # $$$ $$$ #.#');
        AddRow('##### #       # #.#');
        AddRow('~~~~# ######### #.#');
        AddRow('~~~~#           #.#');
        AddRow('~~~~###############');
      End;
    11 :
      Begin
        AddRow('~~~~~~~~~~####~~~~~');
        AddRow('~~~~~####~#  #~~~~~');
        AddRow('~~~### @###$ #~~~~~');
        AddRow('~~##      $  #~~~~~');
        AddRow('~##  $ $$## ##~~~~~');
        AddRow('~#  #$##     #~~~~~');
        AddRow('~# # $ $$ # ###~~~~');
        AddRow('~#   $ #  # $ #####');
        AddRow('####    #  $$ #   #');
        AddRow('#### ## $         #');
        AddRow('#.    ###  ########');
        AddRow('#.. ..#~####~~~~~~~');
        AddRow('#...#.#~~~~~~~~~~~~');
        AddRow('#.....#~~~~~~~~~~~~');
        AddRow('#######~~~~~~~~~~~~');
      End;
    12 :
      Begin
        AddRow('################~');
        AddRow('#              #~');
        AddRow('# # ######     #~');
        AddRow('# #  $ $ $ $#  #~');
        AddRow('# #   $@$   ## ##');
        AddRow('# #  $ $ $###...#');
        AddRow('# #   $ $  ##...#');
        AddRow('# ###$$$ $ ##...#');
        AddRow('#     # ## ##...#');
        AddRow('#####   ## ##...#');
        AddRow('~~~~#####     ###');
        AddRow('~~~~~~~~#     #~~');
        AddRow('~~~~~~~~#######~~');
      End;
    13 :
      Begin
        AddRow('#####~####~~~~~~');
        AddRow('#...#~#  ####~~~');
        AddRow('#...###  $  #~~~');
        AddRow('#....## $  $###~');
        AddRow('##....##   $  #~');
        AddRow('###... ## $ $ #~');
        AddRow('# ##    #  $  #~');
        AddRow('#  ## # ### ####');
        AddRow('# $ # #$  $    #');
        AddRow('#  $ @ $    $  #');
        AddRow('#   # $ $$ $ ###');
        AddRow('#  ######  ###~~');
        AddRow('# ##~~~~####~~~~');
        AddRow('###~~~~~~~~~~~~~');
      End;
    14 :
      Begin
        AddRow('~~~#########~~~~~~~');
        AddRow('~~##   ##  ######~~');
        AddRow('###     #  #    ###');
        AddRow('#  $ #$ #  #  ... #');
        AddRow('# # $#@$## # #.#. #');
        AddRow('#  # #$  #    . . #');
        AddRow('# $    $ # # #.#. #');
        AddRow('#   ##  ##$ $ . . #');
        AddRow('# $ #   #  #$#.#. #');
        AddRow('## $  $   $  $... #');
        AddRow('~#$ ######    ##  #');
        AddRow('~#  #~~~~##########');
        AddRow('~####~~~~~~~~~~~~~~');
      End;
    15 :
      Begin
        AddRow('~~~~~~~#######~~~~');
        AddRow('~#######     #~~~~');
        AddRow('~#     # $@$ #~~~~');
        AddRow('~#$$ #   #########');
        AddRow('~# ###......##   #');
        AddRow('~#   $......## # #');
        AddRow('~# ###......     #');
        AddRow('##   #### ### #$##');
        AddRow('#  #$   #  $  # #~');
        AddRow('#  $ $$$  # $## #~');
        AddRow('#   $ $ ###$$ # #~');
        AddRow('#####     $   # #~');
        AddRow('~~~~### ###   # #~');
        AddRow('~~~~~~#     #   #~');
        AddRow('~~~~~~########  #~');
        AddRow('~~~~~~~~~~~~~####~');
      End;
    16 :
      Begin
        AddRow('~~~########~~~~~~');
        AddRow('~~~#   #  #~~~~~~');
        AddRow('~~~#  $   #~~~~~~');
        AddRow('~### #$   ####~~~');
        AddRow('~#  $  ##$   #~~~');
        AddRow('~#  # @ $ # $#~~~');
        AddRow('~#  #      $ ####');
        AddRow('~## ####$##     #');
        AddRow('~# $#.....# #   #');
        AddRow('~#  $..**. $# ###');
        AddRow('##  #.....#   #~~');
        AddRow('#   ### #######~~');
        AddRow('# $$  #  #~~~~~~~');
        AddRow('#  #     #~~~~~~~');
        AddRow('######   #~~~~~~~');
        AddRow('~~~~~#####~~~~~~~');
      End;
    17 :
      Begin
        AddRow('#####~~~~~~~~~');
        AddRow('#   ##~~~~~~~~');
        AddRow('#    #~~####~~');
        AddRow('# $  ####  #~~');
        AddRow('#  $$ $   $#~~');
        AddRow('###@ #$    ##~');
        AddRow('~#  ##  $ $ ##');
        AddRow('~# $  ## ## .#');
        AddRow('~#  #$##$  #.#');
        AddRow('~###   $..##.#');
        AddRow('~~#    #.*...#');
        AddRow('~~# $$ #.....#');
        AddRow('~~#  #########');
        AddRow('~~#  #~~~~~~~~');
        AddRow('~~####~~~~~~~~');
      End;
    18 :
      Begin
        AddRow('~~~##########~~~');
        AddRow('~~~#..  #   #~~~');
        AddRow('~~~#..      #~~~');
        AddRow('~~~#..  #  ####~');
        AddRow('~~#######  #  ##');
        AddRow('~~#            #');
        AddRow('~~#  #  ##  #  #');
        AddRow('#### ##  #### ##');
        AddRow('#  $  ##### #  #');
        AddRow('# # $  $  # $  #');
        AddRow('# @$  $   #   ##');
        AddRow('#### ## #######~');
        AddRow('~~~#    #~~~~~~~');
        AddRow('~~~######~~~~~~~');
      End;
    19 :
      Begin
        AddRow('~~~~~###########~~~');
        AddRow('~~~~~#  .  #   #~~~');
        AddRow('~~~~~# #.    @ #~~~');
        AddRow('~##### ##..# ####~~');
        AddRow('##  # ..###     ###');
        AddRow('# $ #...   $ #  $ #');
        AddRow('#    .. ##  ## ## #');
        AddRow('####$##$# $ #   # #');
        AddRow('~~## #    #$ $$ # #');
        AddRow('~~#  $ # #  # $## #');
        AddRow('~~#               #');
        AddRow('~~#  ###########  #');
        AddRow('~~####~~~~~~~~~####');
      End;
    20 :
      Begin
        AddRow('~~######~~~~~~~~~~~');
        AddRow('~~#   @####~~~~~~~~');
        AddRow('##### $   #~~~~~~~~');
        AddRow('#   ##    ####~~~~~');
        AddRow('# $ #  ##    #~~~~~');
        AddRow('# $ #  ##### #~~~~~');
        AddRow('## $  $    # #~~~~~');
        AddRow('## $ $ ### # #~~~~~');
        AddRow('## #  $  # # #~~~~~');
        AddRow('## # #$#   # #~~~~~');
        AddRow('## ###   # # ######');
        AddRow('#  $  #### # #....#');
        AddRow('#    $    $   ..#.#');
        AddRow('####$  $# $   ....#');
        AddRow('#       #  ## ....#');
        AddRow('###################');
      End;
    21 :
      Begin
        AddRow('~~~~##########~~~~~');
        AddRow('#####        ####~~');
        AddRow('#     #   $  #@ #~~');
        AddRow('# #######$####  ###');
        AddRow('# #    ## #  #$ ..#');
        AddRow('# # $     #  #  #.#');
        AddRow('# # $  #     #$ ..#');
        AddRow('# #  ### ##     #.#');
        AddRow('# ###  #  #  #$ ..#');
        AddRow('# #    #  ####  #.#');
        AddRow('# #$   $  $  #$ ..#');
        AddRow('#    $ # $ $ #  #.#');
        AddRow('#### $###    #$ ..#');
        AddRow('~~~#    $$ ###....#');
        AddRow('~~~#      ##~######');
        AddRow('~~~########~~~~~~~~');
      End;
    22 :
      Begin
        AddRow('#########~~~~~~');
        AddRow('#       #~~~~~~');
        AddRow('#       ####~~~');
        AddRow('## #### #  #~~~');
        AddRow('## #@##    #~~~');
        AddRow('# $$$ $  $$#~~~');
        AddRow('#  # ## $  #~~~');
        AddRow('#  # ##  $ ####');
        AddRow('####  $$$ $#  #');
        AddRow('~#   ##   ....#');
        AddRow('~# #   # #.. .#');
        AddRow('~#   # # ##...#');
        AddRow('~##### $  #...#');
        AddRow('~~~~~##   #####');
        AddRow('~~~~~~#####~~~~');
      End;
    23 :
      Begin
        AddRow('######~~~~~####~~~~');
        AddRow('#    #######  #####');
        AddRow('#   $#  #  $  #   #');
        AddRow('#  $  $  $ # $ $  #');
        AddRow('##$ $   # @# $    #');
        AddRow('#  $ ########### ##');
        AddRow('# #   #.......# $#~');
        AddRow('# ##  # ......#  #~');
        AddRow('# #   $........$ #~');
        AddRow('# # $ #.... ..#  #~');
        AddRow('#  $ $####$#### $#~');
        AddRow('# $   ### $   $  ##');
        AddRow('# $     $ $  $    #');
        AddRow('## ###### $ ##### #');
        AddRow('#         #       #');
        AddRow('###################');
      End;
    24 :
      Begin
        AddRow('~~~~#######~~~~~~~~');
        AddRow('~~~~#  #  ####~~~~~');
        AddRow('##### $#$ #  ##~~~~');
        AddRow('#.. #  #  #   #~~~~');
        AddRow('#.. # $#$ #  $####~');
        AddRow('#.  #     #$  #  #~');
        AddRow('#..   $#  # $    #~');
        AddRow('#..@#  #$ #$  #  #~');
        AddRow('#.. # $#     $#  #~');
        AddRow('#.. #  #$$#$  #  ##');
        AddRow('#.. # $#  #  $#$  #');
        AddRow('#.. #  #  #   #   #');
        AddRow('##. ####  #####   #');
        AddRow('~####~~####~~~#####');
      End;
    25 :
      Begin
        AddRow('###############~~~~');
        AddRow('#..........  .####~');
        AddRow('#..........$$.#  #~');
        AddRow('###########$ #   ##');
        AddRow('#      $  $     $ #');
        AddRow('## ####   #  $ #  #');
        AddRow('#      #   ##  # ##');
        AddRow('#  $#  # ##  ### ##');
        AddRow('# $ #$###    ### ##');
        AddRow('###  $ #  #  ### ##');
        AddRow('###    $ ## #  # ##');
        AddRow('~# $  #  $  $ $   #');
        AddRow('~#  $  $#$$$  #   #');
        AddRow('~#  #  $      #####');
        AddRow('~# @##  #  #  #~~~~');
        AddRow('~##############~~~~');
      End;
    26 :
      Begin
        AddRow('####~~~~~~~~~~~~~~~');
        AddRow('#  ##############~~');
        AddRow('#  #   ..#......#~~');
        AddRow('#  # # ##### ...#~~');
        AddRow('##$#    ........#~~');
        AddRow('#   ##$######  ####');
        AddRow('# $ #     ######@ #');
        AddRow('##$ # $   ######  #');
        AddRow('#  $ #$$$##       #');
        AddRow('#      #    #$#$###');
        AddRow('# #### #$$$$$    #~');
        AddRow('# #    $     #   #~');
        AddRow('# #   ##        ###');
        AddRow('# ######$###### $ #');
        AddRow('#        #~~~~#   #');
        AddRow('##########~~~~#####');
      End;
    27 :
      Begin
        AddRow('~#######~~~~~~~');
        AddRow('~#  #  #####~~~');
        AddRow('##  #  #...###~');
        AddRow('#  $#  #...  #~');
        AddRow('# $ #$$ ...  #~');
        AddRow('#  $#  #... .#~');
        AddRow('#   # $########');
        AddRow('##$       $ $ #');
        AddRow('##  #  $$ #   #');
        AddRow('~######  ##$$@#');
        AddRow('~~~~~~#      ##');
        AddRow('~~~~~~########~');
      End;
    28 :
      Begin
        AddRow('~#################~');
        AddRow('~#...   #    #   ##');
        AddRow('##.....  $## # #$ #');
        AddRow('#......#  $  #    #');
        AddRow('#......#  #  # #  #');
        AddRow('######### $  $ $  #');
        AddRow('~~#     #$##$ ##$##');
        AddRow('~##   $    # $    #');
        AddRow('~#  ## ### #  ##$ #');
        AddRow('~# $ $$     $  $  #');
        AddRow('~# $    $##$ ######');
        AddRow('~#######  @ ##~~~~~');
        AddRow('~~~~~~~######~~~~~~');
      End;
    29 :
      Begin
        AddRow('~~~~~~~~~#####~~~');
        AddRow('~~~~~#####   #~~~');
        AddRow('~~~~## $  $  ####');
        AddRow('##### $  $ $ ##.#');
        AddRow('#       $$  ##..#');
        AddRow('#  ###### ###.. #');
        AddRow('## #  #    #... #');
        AddRow('# $   #    #... #');
        AddRow('#@ #$ ## ####...#');
        AddRow('####  $ $$  ##..#');
        AddRow('~~~##  $ $  $...#');
        AddRow('~~~~# $$  $ #  .#');
        AddRow('~~~~#   $ $  ####');
        AddRow('~~~~######   #~~~');
        AddRow('~~~~~~~~~#####~~~');
      End;
    30 :
      Begin
        AddRow('#####~~~~~~~~~~~~~~');
        AddRow('#   ##~~~~~~~~~~~~~');
        AddRow('# $  #########~~~~~');
        AddRow('## # #       ######');
        AddRow('## #   $#$#@  #   #');
        AddRow('#  #      $ #   $ #');
        AddRow('#  ### ######### ##');
        AddRow('#  ## ..*..... # ##');
        AddRow('## ## *.*..*.* # ##');
        AddRow('# $########## ##$ #');
        AddRow('#  $   $  $    $  #');
        AddRow('#  #   #   #   #  #');
        AddRow('###################');
      End;
    31 :
      Begin
        AddRow('~~~~~~~###########~');
        AddRow('~~~~~~~#   #     #~');
        AddRow('#####~~#     $ $ #~');
        AddRow('#   ##### $## # ##~');
        AddRow('# $ ##   # ## $  #~');
        AddRow('# $  @$$ # ##$$$ #~');
        AddRow('## ###   # ##    #~');
        AddRow('## #   ### #####$#~');
        AddRow('## #     $  #....#~');
        AddRow('#  ### ## $ #....##');
        AddRow('# $   $ #   #..$. #');
        AddRow('#  ## $ #  ##.... #');
        AddRow('#####   ######...##');
        AddRow('~~~~#####~~~~#####~');
      End;
    32 :
      Begin
        AddRow('~~####~~~~~~~~~~~~');
        AddRow('~~#  #########~~~~');
        AddRow('~##  ##  #   #~~~~');
        AddRow('~#  $# $@$   ####~');
        AddRow('~#$  $  # $ $#  ##');
        AddRow('##  $## #$ $     #');
        AddRow('#  #  # #   $$$  #');
        AddRow('# $    $  $## ####');
        AddRow('# $ $ #$#  #  #~~~');
        AddRow('##  ###  ###$ #~~~');
        AddRow('~#  #....     #~~~');
        AddRow('~####......####~~~');
        AddRow('~~~#....####~~~~~~');
        AddRow('~~~#...##~~~~~~~~~');
        AddRow('~~~#...#~~~~~~~~~~');
        AddRow('~~~#####~~~~~~~~~~');
      End;
    33 :
      Begin
        AddRow('~~~~~~####~~~');
        AddRow('~~#####  #~~~');
        AddRow('~##     $#~~~');
        AddRow('## $  ## ###~');
        AddRow('#@$ $ # $  #~');
        AddRow('#### ##   $#~');
        AddRow('~#....#$ $ #~');
        AddRow('~#....#   $#~');
        AddRow('~#....  $$ ##');
        AddRow('~#... # $   #');
        AddRow('~######$ $  #');
        AddRow('~~~~~~#   ###');
        AddRow('~~~~~~#$ ###~');
        AddRow('~~~~~~#  #~~~');
        AddRow('~~~~~~####~~~');
      End;
    34 :
      Begin
        AddRow('############');
        AddRow('##     ##  #');
        AddRow('##   $   $ #');
        AddRow('#### ## $$ #');
        AddRow('#   $ #    #');
        AddRow('# $$$ # ####');
        AddRow('#   # # $ ##');
        AddRow('#  #  #  $ #');
        AddRow('# $# $#    #');
        AddRow('#   ..# ####');
        AddRow('####.. $ #@#');
        AddRow('#.....# $# #');
        AddRow('##....#  $ #');
        AddRow('###..##    #');
        AddRow('############');
      End;
    35 :
      Begin
        AddRow('~#########~~~~');
        AddRow('~#....   ##~~~');
        AddRow('~#.#.#  $ ##~~');
        AddRow('##....# # @##~');
        AddRow('# ....#  #  ##');
        AddRow('#     #$ ##$ #');
        AddRow('## ###  $    #');
        AddRow('~#$  $ $ $#  #');
        AddRow('~# #  $ $ ## #');
        AddRow('~#  ###  ##  #');
        AddRow('~#    ## ## ##');
        AddRow('~#  $ #  $  #~');
        AddRow('~###$ $   ###~');
        AddRow('~~~#  #####~~~');
        AddRow('~~~####~~~~~~~');
      End;
    36 :
      Begin
        AddRow('############~######');
        AddRow('#   #    # ###....#');
        AddRow('#   $$#   @  .....#');
        AddRow('#   # ###   # ....#');
        AddRow('## ## ###  #  ....#');
        AddRow(' # $ $     # # ####');
        AddRow(' #  $ $##  #      #');
        AddRow('#### #  #### # ## #');
        AddRow('#  # #$   ## #    #');
        AddRow('# $  $  # ## #   ##');
        AddRow('# # $ $    # #   #~');
        AddRow('#  $ ## ## # #####~');
        AddRow('# $$     $$  #~~~~~');
        AddRow('## ## ### $  #~~~~~');
        AddRow('~#    #~#    #~~~~~');
        AddRow('~######~######~~~~~');
      End;
    37 :
      Begin
        AddRow('~~~~~~~~~~~~#####~~');
        AddRow('#####~~######   #~~');
        AddRow('#   ####  $ $ $ #~~');
        AddRow('# $   ## ## ##  ##~');
        AddRow('#   $ $     $  $ #~');
        AddRow('### $  ## ##     ##');
        AddRow('~~# ##### #####$$ #');
        AddRow('~##$##### @##     #');
        AddRow('~# $  ###$### $  ##');
        AddRow('~# $  #   ###  ###~');
        AddRow('~# $$ $ #   $$ #~~~');
        AddRow('~#     #   ##  #~~~');
        AddRow('~#######.. .###~~~~');
        AddRow('~~~~#.........#~~~~');
        AddRow('~~~~#.........#~~~~');
        AddRow('~~~~###########~~~~');
      End;
    38 :
      Begin
        AddRow('###########~~~~~~~~');
        AddRow('#......   #########');
        AddRow('#......   #  ##   #');
        AddRow('#..### $    $     #');
        AddRow('#... $ $ #   ##   #');
        AddRow('#...#$#####    #  #');
        AddRow('###    #   #$  #$ #');
        AddRow('~~#  $$ $ $  $##  #');
        AddRow('~~#  $   #$#$ ##$ #');
        AddRow('~~### ## #    ##  #');
        AddRow('~~~#  $ $ ## ######');
        AddRow('~~~#    $  $  #~~~~');
        AddRow('~~~##   # #   #~~~~');
        AddRow('~~~~#####@#####~~~~');
        AddRow('~~~~~~~~###~~~~~~~~');
      End;
    39 :
      Begin
        AddRow('~~~~~~####~');
        AddRow('####### @#~');
        AddRow('#     $  #~');
        AddRow('#   $## $#~');
        AddRow('##$#...# #~');
        AddRow('~# $...  #~');
        AddRow('~# #. .# ##');
        AddRow('~#   # #$ #');
        AddRow('~#$  $    #');
        AddRow('~#  #######');
        AddRow('~####~~~~~~');
      End;
    40 :
      Begin
        AddRow('~~~~~~~~~~~~~######');
        AddRow('~#############....#');
        AddRow('##   ##     ##....#');
        AddRow('#  $$##  $ @##....#');
        AddRow('#      $$ $#  ....#');
        AddRow('#  $ ## $$ # # ...#');
        AddRow('#  $ ## $  #  ....#');
        AddRow('## ##### ### ##.###');
        AddRow('##   $  $ ##   .  #');
        AddRow('# $###  # ##### ###');
        AddRow('#   $   #       #~~');
        AddRow('#  $ #$ $ $###  #~~');
        AddRow('# $$$# $   #~####~~');
        AddRow('#    #  $$ #~~~~~~~');
        AddRow('######   ###~~~~~~~');
        AddRow('~~~~~#####~~~~~~~~~');
      End;
    41 :
      Begin
        AddRow('~~~~############~');
        AddRow('~~~~#          ##');
        AddRow('~~~~#  # #$$ $  #');
        AddRow('~~~~#$ #$#  ## @#');
        AddRow('~~~## ## # $ # ##');
        AddRow('~~~#   $ #$  # #~');
        AddRow('~~~#   # $   # #~');
        AddRow('~~~## $ $   ## #~');
        AddRow('~~~#  #  ##  $ #~');
        AddRow('~~~#    ## $$# #~');
        AddRow('######$$   #   #~');
        AddRow('#....#  ########~');
        AddRow('#.#... ##~~~~~~~~');
        AddRow('#....   #~~~~~~~~');
        AddRow('#....   #~~~~~~~~');
        AddRow('#########~~~~~~~~');
      End;
    42 :
      Begin
        AddRow('~~~~~~~~~~~#####~~~');
        AddRow('~~~~~~~~~~##   ##~~');
        AddRow('~~~~~~~~~##     #~~');
        AddRow('~~~~~~~~##  $$  #~~');
        AddRow('~~~~~~~## $$  $ #~~');
        AddRow('~~~~~~~# $    $ #~~');
        AddRow('####~~~#   $$ #####');
        AddRow('#  ######## ##    #');
        AddRow('#.            $$$@#');
        AddRow('#.# ####### ##   ##');
        AddRow('#.# #######. #$ $##');
        AddRow('#........... #    #');
        AddRow('##############  $ #');
        AddRow('~~~~~~~~~~~~~##  ##');
        AddRow('~~~~~~~~~~~~~~####~');
      End;
    43 :
      Begin
        AddRow('~~~~~########~~~~~');
        AddRow('~~####      ######');
        AddRow('~~#    ## $ $   @#');
        AddRow('~~# ## ##$#$ $ $##');
        AddRow('### ......#  $$ ##');
        AddRow('#   ......#  #   #');
        AddRow('# # ......#$  $  #');
        AddRow('# #$...... $$# $ #');
        AddRow('#   ### ###$  $ ##');
        AddRow('###  $  $  $  $ #~');
        AddRow('~~#  $  $  $  $ #~');
        AddRow('~~######   ######~');
        AddRow('~~~~~~~#####~~~~~~');
      End;
    44 :
      Begin
        AddRow('~~~~~~~~#######~~~~');
        AddRow('~~~~#####  #  ####~');
        AddRow('~~~~#   #   $    #~');
        AddRow('~#### #$$ ## ##  #~');
        AddRow('##      # #  ## ###');
        AddRow('#  ### $#$  $  $  #');
        AddRow('#...    # ##  #   #');
        AddRow('#...#    @ # ### ##');
        AddRow('#...#  ###  $  $  #');
        AddRow('########~##   #   #');
        AddRow('~~~~~~~~~~#########');
      End;
    45 :
      Begin
        AddRow('~#####~~~~~~~~~~~~~');
        AddRow('~#   #~~~~~~~~~~~~~');
        AddRow('~# # #######~~~~~~~');
        AddRow('~#      $@######~~~');
        AddRow('~# $ ##$ ###   #~~~');
        AddRow('~# #### $    $ #~~~');
        AddRow('~# ##### #  #$ ####');
        AddRow('##  #### ##$      #');
        AddRow('#  $#  $  # ## ## #');
        AddRow('#         # #...# #');
        AddRow('######  ###  ...  #');
        AddRow('~~~~~####~# #...# #');
        AddRow('~~~~~~~~~~# ### # #');
        AddRow('~~~~~~~~~~#       #');
        AddRow('~~~~~~~~~~#########');
      End;
    46 :
      Begin
        AddRow('##########~~~~');
        AddRow('#        ####~');
        AddRow('# ###### #  ##');
        AddRow('# # $ $ $  $ #');
        AddRow('#       #$   #');
        AddRow('###$  $$#  ###');
        AddRow('~~#  ## # $##~');
        AddRow('~~##$#   $ @#~');
        AddRow('~~~#  $ $ ###~');
        AddRow('~~~# #   $  #~');
        AddRow('~~~# ##   # #~');
        AddRow('~~##  ##### #~');
        AddRow('~~#         #~');
        AddRow('~~#.......###~');
        AddRow('~~#.......#~~~');
        AddRow('~~#########~~~');
      End;
    47 :
      Begin
        AddRow('~~~~~~~~~####~~~~~');
        AddRow('~#########  ##~~~~');
        AddRow('##  $      $ #####');
        AddRow('#   ## ##   ##...#');
        AddRow('# #$$ $ $$#$##...#');
        AddRow('# #   @   #   ...#');
        AddRow('#  $# ###$$   ...#');
        AddRow('# $  $$  $ ##....#');
        AddRow('###$       #######');
        AddRow('~~#  #######~~~~~~');
        AddRow('~~####~~~~~~~~~~~~');
      End;
    48 :
      Begin
        AddRow('~~#########~~');
        AddRow('~~#*.*#*.*#~~');
        AddRow('~~#.*.*.*.#~~');
        AddRow('~~#*.*.*.*#~~');
        AddRow('~~#.*.*.*.#~~');
        AddRow('~~#*.*.*.*#~~');
        AddRow('~~###   ###~~');
        AddRow('~~~~#   #~~~~');
        AddRow('###### ######');
        AddRow('#           #');
        AddRow('# $ $ $ $ $ #');
        AddRow('## $ $ $ $ ##');
        AddRow('~#$ $ $ $ $#~');
        AddRow('~#   $@$   #~');
        AddRow('~#  #####  #~');
        AddRow('~####~~~####~');
      End;
    49 :
      Begin
        AddRow('~~~~~~~####~~~~~');
        AddRow('~~~~~~~#  ##~~~~');
        AddRow('~~~~~~~#   ##~~~');
        AddRow('~~~~~~~# $$ ##~~');
        AddRow('~~~~~###$  $ ##~');
        AddRow('~~####    $   #~');
        AddRow('###  # #####  #~');
        AddRow('#    # #....$ #~');
        AddRow('# #   $ ....# #~');
        AddRow('#  $ # #.*..# #~');
        AddRow('###  #### ### #~');
        AddRow('~~#### @$  ##$##');
        AddRow('~~~~~### $     #');
        AddRow('~~~~~~~#  ##   #');
        AddRow('~~~~~~~#########');
      End;
    50 :
      Begin
        AddRow('~~~~~~############~');
        AddRow('~~~~~##..    #   #~');
        AddRow('~~~~##..* $    $ #~');
        AddRow('~~~##..*.# # # $##~');
        AddRow('~~~#..*.# # # $  #~');
        AddRow('####...#  #    # #~');
        AddRow('#  ## #          #~');
        AddRow('# @$ $ ###  #   ##~');
        AddRow('# $   $   # #   #~~');
        AddRow('###$$   # # # # #~~');
        AddRow('~~#   $   # # #####');
        AddRow('~~# $# #####      #');
        AddRow('~~#$   #~~~#    # #');
        AddRow('~~#  ###~~~##     #');
        AddRow('~~#  #~~~~~~#    ##');
        AddRow('~~####~~~~~~######~');
      End;
    51 :
      Begin
        AddRow('#########~~~~');
        AddRow('#       #~~~~');
        AddRow('#  $   $#~~~~');
        AddRow('####    #~~~~');
        AddRow('~~~# $  ##~~~');
        AddRow('####   $ #~~~');
        AddRow('#.. $ ## ####');
        AddRow('#..  $##    #');
        AddRow('#..    $    #');
        AddRow('#.###$### #@#');
        AddRow('#.#~#     ###');
        AddRow('###~#######~~');
      End;
    52 :
      Begin
        AddRow('####################');
        AddRow('#  ##########     @#');
        AddRow('# $#    #     ######');
        AddRow('#      ####   #  ###');
        AddRow('#####         #  ###');
        AddRow('#   $         #  ###');
        AddRow('#  $####  #   #    #');
        AddRow('# # #  #..#$###  # #');
        AddRow('# # #$ #..#  $  $$ #');
        AddRow('#      #..#  #   # #');
        AddRow('#   #  #..#  #   # #');
        AddRow('####################');
      End;
    53 :
      Begin
        AddRow('####################');
        AddRow('#                ###');
        AddRow('# $#   $ ##  $    ##');
        AddRow('#    $###    # $$ ##');
        AddRow('#.###     $ $ ##  ##');
        AddRow('#...#  #  #    #$  #');
        AddRow('#..##$$#### $  #   #');
        AddRow('#...#      $ ##  ###');
        AddRow('#...$  ###  #    # #');
        AddRow('##..  $#  ##   ##@ #');
        AddRow('###.#              #');
        AddRow('####################');
      End;
    54 :
      Begin
        AddRow('####################');
        AddRow('#   #    #   #   #@#');
        AddRow('# $      $   $   # #');
        AddRow('## ###..## ###     #');
        AddRow('#   #....#$#  $### #');
        AddRow('# $ #....#  $  $ $ #');
        AddRow('#   #....# # # $ $ #');
        AddRow('#   ##..##   #$#   #');
        AddRow('##$##    ##  #  #$##');
        AddRow('#   $  $     #  #  #');
        AddRow('#   #    #   #     #');
        AddRow('####################');
      End;
    55 :
      Begin
        AddRow('####################');
        AddRow('#    @##      #   ##');
        AddRow('#    ##    $    $ ##');
        AddRow('#  ###....# # #  ###');
        AddRow('#   #....# # # $   #');
        AddRow('### #...#  #       #');
        AddRow('##  ##.#     $   $ #');
        AddRow('##  $ $ ###  # # ###');
        AddRow('## $       # # $   #');
        AddRow('#### $  $# # # # $ #');
        AddRow('####         # #  ##');
        AddRow('####################');
      End;
    56 :
      Begin
        AddRow('####################');
        AddRow('#  #  ##    #   @###');
        AddRow('##    $    # $###  #');
        AddRow('##$# $ ##$# $ $    #');
        AddRow('#   $#    $      ###');
        AddRow('# ##   $ ###  #....#');
        AddRow('# # $# # # # #....##');
        AddRow('#    $ $ #  #....###');
        AddRow('##$ ###  $ #....####');
        AddRow('#  # $        ######');
        AddRow('#      # #    ######');
        AddRow('####################');
      End;
    57 :
      Begin
        AddRow('####################');
        AddRow('#@     ###   #  #  #');
        AddRow('# # #  #  $  $     #');
        AddRow('#####     # $ $#$# #');
        AddRow('#.#..#    ##$ $    #');
        AddRow('#.....    $   #   ##');
        AddRow('#.....    ###$##$###');
        AddRow('#.#..#    $    #   #');
        AddRow('#####     #  #$  $ #');
        AddRow('#####  #  $    $ $ #');
        AddRow('#####  #  #  #  #  #');
        AddRow('####################');
      End;
    58 :
      Begin
        AddRow('####################');
        AddRow('##...   ## #    #  #');
        AddRow('#....         $ ## #');
        AddRow('#....# # #$###$    #');
        AddRow('#...#    #       # #');
        AddRow('##.#  #$ #     $## #');
        AddRow('#  #  # $ $ ###  $ #');
        AddRow('#     $  $ #  # ## #');
        AddRow('## # ## #$$# $#  # #');
        AddRow('#  #   $ $ #      ##');
        AddRow('#    #     #  #   @#');
        AddRow('####################');
      End;
    59 :
      Begin
        AddRow('####################');
        AddRow('#   #  #@# ##  #####');
        AddRow('# # #  $    $  #####');
        AddRow('# #    ###### $  ###');
        AddRow('#   #  #....#  $$  #');
        AddRow('##$##$##....#      #');
        AddRow('#      #....##$##$##');
        AddRow('#  $$  #....#      #');
        AddRow('# $  $  #  #  ###  #');
        AddRow('#####  $   $    $  #');
        AddRow('##### #    #  #   ##');
        AddRow('####################');
      End;
    60 :
      Begin
        AddRow('####################');
        AddRow('#     ###..###     #');
        AddRow('# $$  ###..###  $@ #');
        AddRow('#  # ##......#  $  #');
        AddRow('#     #......#  $  #');
        AddRow('####  ###..######$ #');
        AddRow('#   $$$ #..#    #  #');
        AddRow('# $#   $  $  $$ #$ #');
        AddRow('#  #  ## $  ##  #  #');
        AddRow('# $    $ ## $    $ #');
        AddRow('#  #  ##    ##  #  #');
        AddRow('####################');
      End;
    61 :
      Begin
        AddRow('####################');
        AddRow('#    #  # #  #  #  #');
        AddRow('# @# # ## $   $   ##');
        AddRow('#### #    #  # $   #');
        AddRow('#    # ## #$ ## ## #');
        AddRow('#      $   $   $   #');
        AddRow('#..###$$## $##$ ## #');
        AddRow('#..#.#  # $   $ #  #');
        AddRow('#....# $$   ##$ ####');
        AddRow('#....#  #####      #');
        AddRow('#...###        ##  #');
        AddRow('####################');
      End;
    62 :
      Begin
        AddRow('####################');
        AddRow('#....#       #  #  #');
        AddRow('#....# # $  $      #');
        AddRow('#.... ##  $# # $#$ #');
        AddRow('#...#   $   $#  $  #');
        AddRow('#..####  # $   $$  #');
        AddRow('#      #### #### ###');
        AddRow('#        #   #     #');
        AddRow('# ##   #   $ # $ $ #');
        AddRow('# ##    $ ## $  $  #');
        AddRow('#     @#     #   # #');
        AddRow('####################');
      End;
    63 :
      Begin
        AddRow('####################');
        AddRow('#....###           #');
        AddRow('#....##### #  #$# ##');
        AddRow('#....###   #$  $   #');
        AddRow('#....###    $  #$$##');
        AddRow('##  #### $#  #$ $  #');
        AddRow('##  ####  $  $  #  #');
        AddRow('#@  ####$###$## $  #');
        AddRow('##        #  #  $  #');
        AddRow('##   ###  #  $  ####');
        AddRow('########  #  #     #');
        AddRow('####################');
      End;
    64 :
      Begin
        AddRow('####################');
        AddRow('#     #     @#...###');
        AddRow('#     #      ##...##');
        AddRow('# # # ##$## ## ....#');
        AddRow('#   $ #   $$$  ....#');
        AddRow('###$### $$  ### ##.#');
        AddRow('#     $  #    # ####');
        AddRow('#  $  #  ###  # #  #');
        AddRow('## #$##    $  $$   #');
        AddRow('#   $ ##   #  # #  #');
        AddRow('#     #    #  #    #');
        AddRow('####################');
      End;
    65 :
      Begin
        AddRow('####################');
        AddRow('#     #  #...#@    #');
        AddRow('# #       ....#    #');
        AddRow('#  $  #   #....#   #');
        AddRow('# ##$#### ##....#  #');
        AddRow('# $   $  #  #...#  #');
        AddRow('# $$ #   #   # $$  #');
        AddRow('###  $$$#   $$  $  #');
        AddRow('# $  #  #    # $#  #');
        AddRow('#   $#  #       $  #');
        AddRow('#  #    #    #  #  #');
        AddRow('####################');
      End;
    66 :
      Begin
        AddRow('####################');
        AddRow('#####@###.##...##  #');
        AddRow('#####$  ..#...#    #');
        AddRow('####    ......#  $ #');
        AddRow('###  $ #.....## # ##');
        AddRow('##  $$# #####  $ $ #');
        AddRow('## $# $    ##  $$  #');
        AddRow('##  #  #    # $  $ #');
        AddRow('##   $$ ### #$##   #');
        AddRow('## $#      $ $  $ ##');
        AddRow('###    #    #    ###');
        AddRow('####################');
      End;
    67 :
      Begin
        AddRow('####################');
        AddRow('#@     #   #       #');
        AddRow('## ### ##  #### # ##');
        AddRow('#    # #  $$       #');
        AddRow('#  # # # $ # $ ## ##');
        AddRow('#     $ #  #$$ #   #');
        AddRow('#  ###  #      ## ##');
        AddRow('#..#.# $ #  $ #    #');
        AddRow('#..#.#  $ # ## $$  #');
        AddRow('#....##   $$  $  # #');
        AddRow('#.....##        #  #');
        AddRow('####################');
      End;
    68 :
      Begin
        AddRow('####################');
        AddRow('#  #      #   #   ##');
        AddRow('# $# $ $ ##...$  $ #');
        AddRow('#  $  # ##....# $  #');
        AddRow('# ## $ ##....#   $ #');
        AddRow('# $    #....## $   #');
        AddRow('# $##  #...#       #');
        AddRow('#   $$$##$##  ### ##');
        AddRow('# # #  #   #  #    #');
        AddRow('# $ #  $  ##       #');
        AddRow('#    #    #@       #');
        AddRow('####################');
      End;
    69 :
      Begin
        AddRow('####################');
        AddRow('#  #  # #    #  #  #');
        AddRow('#   $      $ $     #');
        AddRow('## #  #$###$##  ## #');
        AddRow('#   $     $  #  $  #');
        AddRow('# ###$##$#   # $   #');
        AddRow('# #   $ $  ###### $#');
        AddRow('# $  $$ $  #@#.#...#');
        AddRow('# #     #  # #.#...#');
        AddRow('# ########## #.....#');
        AddRow('#            #.....#');
        AddRow('####################');
      End;
    70 :
      Begin
        AddRow('####################');
        AddRow('#  #     #  ##    ##');
        AddRow('# $#   $ #     ##  #');
        AddRow('# $  $  #..#     $ #');
        AddRow('# $ $  #....#   # ##');
        AddRow('# $#  #......### $ #');
        AddRow('#   #  #....#  #$  #');
        AddRow('# $  ####..#   #   #');
        AddRow('## $   ## # # $  $##');
        AddRow('### $    $#@$ $#   #');
        AddRow('####   #       #   #');
        AddRow('####################');
      End;
    71 :
      Begin
        AddRow('####################');
        AddRow('#      ....#    ####');
        AddRow('#      ....        #');
        AddRow('# # ##########     #');
        AddRow('# #$   #      ###..#');
        AddRow('#  $   #$$###   #..#');
        AddRow('# $ ### $   $   #..#');
        AddRow('# $ #   $ $ #  ##..#');
        AddRow('#  #  $$ # $ ##   ##');
        AddRow('#@## $#  $  $     ##');
        AddRow('##       ##   #  ###');
        AddRow('####################');
      End;
    72 :
      Begin
        AddRow('####################');
        AddRow('#        #   #@ #  #');
        AddRow('# $$  #$$# # #  ## #');
        AddRow('#  # $ $ #$$ #     #');
        AddRow('## #  #  # # #  #  #');
        AddRow('#   ##       #     #');
        AddRow('#   # $ #   #   #  #');
        AddRow('# $ #$ #   #  $ #..#');
        AddRow('##$ #  ####    #...#');
        AddRow('#  $          #....#');
        AddRow('#   #  #     #.....#');
        AddRow('####################');
      End;
    73 :
      Begin
        AddRow('####################');
        AddRow('#     #   #####    #');
        AddRow('## $  #   ####  $  #');
        AddRow('#### $$   #..#  #  #');
        AddRow('#  $  $  ##..#### ##');
        AddRow('# $   ###....   $$ #');
        AddRow('#  #$#   ....# # $ #');
        AddRow('# #  # $ ..###$#   #');
        AddRow('# #   $ #..#   ##  #');
        AddRow('#   $#  ####   # $##');
        AddRow('# #  #    @#      ##');
        AddRow('####################');
      End;
    74 :
      Begin
        AddRow('####################');
        AddRow('#   #   #    #   #@#');
        AddRow('#   $  $     # $ # #');
        AddRow('##$# $### #    $$# #');
        AddRow('#  #  #.###  #$ $  #');
        AddRow('#  #$#....#  # ### #');
        AddRow('# $  #.....##    # #');
        AddRow('##$  #.#....#$$ $  #');
        AddRow('#  ######..## #  # #');
        AddRow('#  $         $ ### #');
        AddRow('#   #   #        # #');
        AddRow('####################');
      End;
    75 :
      Begin
        AddRow('####################');
        AddRow('# # # #   #@##   # #');
        AddRow('#             $    #');
        AddRow('#  ##$# ##### $ # ##');
        AddRow('##    ##.....#  #  #');
        AddRow('##$##$#.....###$#$ #');
        AddRow('#   # ##.....#  # ##');
        AddRow('#  $    ##..##  #  #');
        AddRow('# $ #   $   $  $$$ #');
        AddRow('## $  $# #  #  $   #');
        AddRow('#   ##   #  #      #');
        AddRow('####################');
      End;
    76 :
      Begin
        AddRow('######~~#####~');
        AddRow('#    #~~#   #~');
        AddRow('# $  #### $ #~');
        AddRow('# $      $  #~');
        AddRow('#  ###@###$ #~');
        AddRow('########## ###');
        AddRow('#..   ##     #');
        AddRow('#..   ##$    #');
        AddRow('#..   ## $   #');
        AddRow('#..   ## $   #');
        AddRow('#..     $ $  #');
        AddRow('###  #########');
        AddRow('~~####~~~~~~~~');
      End;
    77 :
      Begin
        AddRow('~~~~~~~###########~');
        AddRow('~~~~~~~#         #~');
        AddRow('~~~~~~~#    $ $  #~');
        AddRow('######~# $ ##### #~');
        AddRow('#    ##### $  ##$#~');
        AddRow('#       $ $      #~');
        AddRow('#          ## ## #~');
        AddRow('#    ##@##### ## #~');
        AddRow('#    ####~~~# ## ##');
        AddRow('#....#~~~~~~# $   #');
        AddRow('#....#~~~~~~#     #');
        AddRow('######~~~~~~#######');
      End;
    78 :
      Begin
        AddRow('#############~~~~~~');
        AddRow('#           #~~~~~~');
        AddRow('# ### $$    #~~~~~~');
        AddRow('#   # $  $  #~~~~~~');
        AddRow('#  $####$######~~~~');
        AddRow('# $ ##        #####');
        AddRow('#  $$ $        ...#');
        AddRow('### ## $$#     ...#');
        AddRow('~~# ##   #     ...#');
        AddRow('~~#      #     ...#');
        AddRow('~~###@#############');
        AddRow('~~~~###~~~~~~~~~~~~');
      End;
    79 :
      Begin
        AddRow('~~#################');
        AddRow('###@##         ...#');
        AddRow('#    #         ...#');
        AddRow('# $  #         ...#');
        AddRow('# $$ #         ...#');
        AddRow('## $ ###$##########');
        AddRow('~# ###  $ #~~~~~~~~');
        AddRow('##   $  $ #~~~~~~~~');
        AddRow('#  $ #  $ #~~~~~~~~');
        AddRow('# $  #    #~~~~~~~~');
        AddRow('#  $ #    #~~~~~~~~');
        AddRow('#    #    #~~~~~~~~');
        AddRow('###########~~~~~~~~');
      End;
    80 :
      Begin
        AddRow('~~~~~~~~~~~~~~#####');
        AddRow('~~~~~##########   #');
        AddRow('~~~~~#        #   #');
        AddRow('~~~~~#  $ $    $$ #');
        AddRow('~~~~~# ##### ## $ #');
        AddRow('~~~~~#$$   #$## $ #');
        AddRow('~~~~~# ### # ##$  #');
        AddRow('###### ### $ $    #');
        AddRow('#....        ##   #');
        AddRow('#....        ######');
        AddRow('#....        #~~~~~');
        AddRow('###########@##~~~~~');
        AddRow('~~~~~~~~~~###~~~~~~');
      End;
    81 :
      Begin
        AddRow('~~~~######~~~~~~~');
        AddRow('~####    #~~~~~~~');
        AddRow('~#    ## #~~~~~~~');
        AddRow('~# $     #~~~~~~~');
        AddRow('### #### ########');
        AddRow('#  $   $ ##  ...#');
        AddRow('#   $$ $$    ...#');
        AddRow('#    $  $##  ...#');
        AddRow('##@## ## ##  ...#');
        AddRow('~###  $  ########');
        AddRow('~#   $$  #~~~~~~~');
        AddRow('~#    #  #~~~~~~~');
        AddRow('~#########~~~~~~~');
      End;
    82 :
      Begin
        AddRow('#######~#########');
        AddRow('#     #~#   ##  #');
        AddRow('# ### #~#   $   #');
        AddRow('# # $ ###   $   #');
        AddRow('#   $$      ##$ #');
        AddRow('#    ####   ##  #');
        AddRow('#@############ ##');
        AddRow('###..    #####$ #');
        AddRow('~~#..    ####   #');
        AddRow('~~#..       $$  #');
        AddRow('~~#..    #### $ #');
        AddRow('~~#..    #~~#   #');
        AddRow('~~########~~#####');
      End;
    83 :
      Begin
        AddRow('#######~~~~~~~~~');
        AddRow('#     ##########');
        AddRow('#     #    #  ##');
        AddRow('# $   #   $ $  #');
        AddRow('#  $  #  $ ##  #');
        AddRow('# $$  ##$ $    #');
        AddRow('## #  ## #######');
        AddRow('## #  ##    ...#');
        AddRow('#  #$       ...#');
        AddRow('#   $$      ...#');
        AddRow('#     ##@#  ...#');
        AddRow('################');
      End;
    84 :
      Begin
        AddRow('############~~~~~~~~');
        AddRow('#      #   ##~~~~~~~');
        AddRow('# $  $   #  ######~~');
        AddRow('####  #####      #~~');
        AddRow('~#..  #     #### #~~');
        AddRow('~#.####  ####    #~~');
        AddRow('~#....    #  $ ####~');
        AddRow('~# ...#   # $$$#  ##');
        AddRow('###.#### ##  $@$   #');
        AddRow('#     ##### $ #    #');
        AddRow('# #.# $      $###$ #');
        AddRow('# #.########  #  $ #');
        AddRow('# #..        ##  $ #');
        AddRow('# # ####### $ # #  #');
        AddRow('#   #~~~~~#       ##');
        AddRow('#####~~~~~##########');
      End;
    85 :
      Begin
        AddRow('####################');
        AddRow('# #     #          #');
        AddRow('#       $  ## ### ##');
        AddRow('#####  ##   $  $   #');
        AddRow('##..##  # # $ # #  #');
        AddRow('#....  $     ##$# ##');
        AddRow('#....  $#####   #$##');
        AddRow('##..# #  #   #  $  #');
        AddRow('###.# #  $   $  # @#');
        AddRow('##  $  $ #   #  ####');
        AddRow('##       ###########');
        AddRow('####################');
      End;
  End;
End;

{ demonstration du niveau 1 (solution du prototype ; F3) }
Function DemoMoves(Part : LongInt) : String;
Begin
  Case Part Of
    0 : DemoMoves := 'ULLLUUULULLDLLDDDRRRRRRRRRRRRRDRULLLLLLLLLLLLLLULLDRRRRRRRRRRRRRRURDLDRLULLLLLLLUUULULLDDDUULLDDDRRRRRRRRRRRRRLLLLLLLLUUULLULDDDUULLDDDRRRRRRRRRRRRLLLLLLLLRUUULLUUULDDDDDUULLDDDRRRRRRRRRRRDRULURLDLLLL';
    1 : DemoMoves := 'LLUUULLUUURDDLLDDDDRRRUUULLULDDDUULLDDDRRRRRRRRRRRURDLDR';
  Else
    DemoMoves := '';
  End;
End;

Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;

{ deplacement d'une direction : 0 haut, 1 bas, 2 gauche, 3 droite }
Function DirD(D : LongInt) : LongInt;
Begin
  Case D Of
    0 : DirD := -GWd;
    1 : DirD := GWd;
    2 : DirD := -1;
  Else
    DirD := 1;
  End;
End;

Function BoxesHome : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To NC - 1 Do If (Box[K] <> 0) And (Goal[K] <> 0) Then Inc(N);
  BoxesHome := N;
End;

{ charge l'etage N ; les cases du sol non atteignables restent dehors }
Procedure LoadLevel(N : LongInt);
Var R, C, I : LongInt; Ch : Char;
Begin
  For I := 0 To NC - 1 Do
  Begin
    G[I] := TOut; Goal[I] := 0; Box[I] := 0;
  End;
  LevelRows(N);
  LvW := 0;
  For R := 0 To LvH - 1 Do If Length(LvRow[R]) > LvW Then LvW := Length(LvRow[R]);
  If LvW > GWd Then LvW := GWd;
  Pl := 0; NGoal := 0;
  For R := 0 To LvH - 1 Do
    For C := 0 To Length(LvRow[R]) - 1 Do
      If C < GWd Then
      Begin
        I := R * GWd + C;
        Ch := LvRow[R][C + 1];
        Case Ch Of
          '#' : G[I] := TWall;
          ' ' : G[I] := TFloor;
          '$' : Begin G[I] := TFloor; Box[I] := 1; End;
          '.' : Begin G[I] := TFloor; Goal[I] := 1; End;
          '*' : Begin G[I] := TFloor; Box[I] := 1; Goal[I] := 1; End;
          '+' : Begin G[I] := TFloor; Goal[I] := 1; Pl := I; End;
          '@' : Begin G[I] := TFloor; Pl := I; End;
        End;
        If Goal[I] <> 0 Then Inc(NGoal);
      End;
  OffX := BX0 + (AW - LvW * Cs) Div 2;
  OffY := BY0 + (AH - LvH * Cs) Div 2;
  Level := N; Moves := 0; Pushes := 0; NUndo := 0; NPath := 0; IPath := 0;
End;

{ un pas dans la direction D ; resultat : le pas a ete fait }
Function TryMove(D : LongInt) : Boolean;
Var T, T2 : LongInt; Pushed : Boolean;
Begin
  TryMove := False;
  T := Pl + DirD(D);
  If (T < 0) Or (T >= NC) Then Exit;
  If (D = 2) And (Pl Mod GWd = 0) Then Exit;
  If (D = 3) And (Pl Mod GWd = GWd - 1) Then Exit;
  If G[T] <> TFloor Then Exit;
  Pushed := False;
  If Box[T] <> 0 Then
  Begin
    T2 := T + DirD(D);
    If (T2 < 0) Or (T2 >= NC) Then Exit;
    If (G[T2] <> TFloor) Or (Box[T2] <> 0) Then Exit;
    Box[T] := 0; Box[T2] := 1;
    Inc(Pushes);
    Pushed := True;
  End;
  Pl := T;
  Inc(Moves);
  If NUndo < MaxUndo Then
  Begin
    If Pushed Then UndoD[NUndo] := D + 4 Else UndoD[NUndo] := D;
    Inc(NUndo);
  End;
  TryMove := True;
End;

{ annule le dernier pas ; resultat : la case d'avant }
Function UndoStep : Boolean;
Var D, B : LongInt;
Begin
  UndoStep := False;
  If NUndo = 0 Then Exit;
  Dec(NUndo);
  D := UndoD[NUndo] And 3;
  If (UndoD[NUndo] And 4) <> 0 Then
  Begin
    B := Pl + DirD(D);
    Box[B] := 0; Box[Pl] := 1;
    Dec(Pushes);
  End;
  Pl := Pl - DirD(D);
  Dec(Moves);
  UndoStep := True;
End;

{ plus court chemin (sans pousser) du magasinier vers T : Path[0..NPath-1] }
Function FindPath(T : LongInt) : Boolean;
Var Prev, Qu : Array[0..NC - 1] Of LongInt; H, Tl, I, J, D, N : LongInt;
Begin
  FindPath := False;
  NPath := 0; IPath := 0;
  If (T < 0) Or (T >= NC) Or (G[T] <> TFloor) Or (Box[T] <> 0) Or (T = Pl) Then Exit;
  For I := 0 To NC - 1 Do Prev[I] := -1;
  Prev[Pl] := Pl; Qu[0] := Pl; H := 0; Tl := 1;
  While (H < Tl) And (Prev[T] < 0) Do
  Begin
    I := Qu[H]; Inc(H);
    For D := 0 To 3 Do
    Begin
      If ((D = 2) And (I Mod GWd = 0)) Or ((D = 3) And (I Mod GWd = GWd - 1)) Then J := -1
      Else J := I + DirD(D);
      If (J >= 0) And (J < NC) Then
        If (G[J] = TFloor) And (Box[J] = 0) And (Prev[J] < 0) Then
        Begin
          Prev[J] := I; Qu[Tl] := J; Inc(Tl);
        End;
    End;
  End;
  If Prev[T] < 0 Then Exit;
  { le chemin a l'envers, puis les directions dans l'ordre }
  N := 0; I := T;
  While I <> Pl Do
  Begin
    Qu[N] := I; Inc(N);
    I := Prev[I];
  End;
  I := Pl;
  For J := N - 1 DownTo 0 Do
  Begin
    For D := 0 To 3 Do If I + DirD(D) = Qu[J] Then Path[N - 1 - J] := D;
    I := Qu[J];
  End;
  NPath := N;
  FindPath := True;
End;


{ messages de plus de 255 caracteres (limite des chaines) : texte cumule
  dans LBuf par LAdd, puis affiche par LMsgBox }
Var
  LBuf : Array[0..4095] Of Byte;
  LLen : LongInt;

Procedure LClr;
Begin
  LLen := 0;
  LBuf[0] := 0;
End;

Procedure LAdd(S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If LLen < 4094 Then
    Begin
      LBuf[LLen] := Ord(S[K]);
      Inc(LLen);
    End;
  LBuf[LLen] := 0;
End;

Function LMsgBox(Cap : String; Fl : LongInt) : LongInt;
Begin
  LMsgBox := WinMessageBox(HWND_DESKTOP, Frame, LongInt(@LBuf), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;
{ ==================================================================== }

Procedure FBar(X1, Y1, X2, Y2, C : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  Rc[0] := X1; Rc[1] := CH - 1 - Y2; Rc[2] := X2 + 1; Rc[3] := CH - Y1;
  Dummy := WinFillRect(Hps, LongInt(@Rc), C);
End;

Procedure Edge(X1, Y1, X2, Y2, Lt, Dk : LongInt);
Begin
  FBar(X1, Y1, X2, Y1, Lt); FBar(X1, Y1, X1, Y2, Lt);
  FBar(X1, Y2, X2, Y2, Dk); FBar(X2, Y1, X2, Y2, Dk);
End;

Procedure OutTxt(X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := CH - Y - 16; Rc[2] := X + Length(S) * 8; Rc[3] := CH - Y;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

{ texte agrandi deux fois (police du VGA) }
Procedure BigText(X, Y : LongInt; S : String; C, Bg : LongInt);
Var I, R, K, B, Run : LongInt;
Begin
  If FontH = 0 Then
  Begin
    OutTxt(X, Y + 8, S, C, Bg);
    Exit;
  End;
  For I := 1 To Length(S) Do
    For R := 0 To FontH - 1 Do
    Begin
      B := Font[Ord(S[I]) * FontH + R];
      K := 0;
      While K < 8 Do
        If (B And ($80 Shr K)) <> 0 Then
        Begin
          Run := K;
          While (K < 8) And ((B And ($80 Shr K)) <> 0) Do Inc(K);
          FBar(X + (I - 1) * 16 + Run * 2, Y + R * 2, X + (I - 1) * 16 + K * 2 - 1, Y + R * 2 + 1, C);
        End
        Else Inc(K);
    End;
End;

{ disque plein de rayon R centre en (X, Y) }
Procedure Disc(X, Y, R, C : LongInt);
Var Dy, W, Rr : LongInt;
Begin
  Rr := R * R + R;
  For Dy := -R To R Do
  Begin
    W := 0;
    While (W + 1) * (W + 1) + Dy * Dy <= Rr Do Inc(W);
    FBar(X - W, Y + Dy, X + W, Y + Dy, C);
  End;
End;

{ ==================================================================== }
{ Dessin (Y vers le bas)                                                }
{ ==================================================================== }

{ mur de briques roses (rangees decalees, relief) }
Procedure DrawWall(X, Y : LongInt);
Var R, K, Yr, Off : LongInt;
Begin
  FBar(X, Y, X + Cs - 1, Y + Cs - 1, CLR_DARKPINK);
  For R := 0 To 2 Do
  Begin
    Yr := Y + R * 7 + 1;
    FBar(X, Yr - 1, X + Cs - 1, Yr - 1, CLR_BLACK);
    FBar(X, Yr, X + Cs - 1, Yr, CLR_PINK);
    If R Mod 2 = 0 Then Off := 0 Else Off := 5;
    K := Off;
    While K < Cs Do
    Begin
      FBar(X + K, Yr, X + K, Yr + 5, CLR_BLACK);
      If K + 1 < Cs Then FBar(X + K + 1, Yr, X + K + 1, Yr + 5, CLR_PINK);
      K := K + 11;
    End;
  End;
  FBar(X, Y + Cs - 1, X + Cs - 1, Y + Cs - 1, CLR_BLACK);
  FBar(X + Cs - 1, Y, X + Cs - 1, Y + Cs - 1, CLR_BLACK);
End;

{ cible : losange bleu }
Procedure DrawGoal(Cx, Cy : LongInt);
Var Dy, W : LongInt;
Begin
  For Dy := -7 To 7 Do
  Begin
    W := 7 - Abs(Dy);
    FBar(Cx - W, Cy + Dy, Cx + W, Cy + Dy, CLR_BLUE);
    If W > 1 Then FBar(Cx - W + 2, Cy + Dy, Cx + W - 2, Cy + Dy, CLR_CYAN);
  End;
End;

{ caisse en bois (verte une fois sur sa cible) }
Procedure DrawBox(X, Y : LongInt; Home : Boolean);
Var Fill, Lt, Dk, K : LongInt;
Begin
  If Home Then
  Begin
    Fill := CLR_DARKGREEN; Lt := CLR_GREEN; Dk := CLR_BLACK;
  End
  Else
  Begin
    Fill := CLR_BROWN; Lt := CLR_YELLOW; Dk := CLR_DARKRED;
  End;
  FBar(X + 2, Y + 2, X + Cs - 3, Y + Cs - 3, Fill);
  Edge(X + 2, Y + 2, X + Cs - 3, Y + Cs - 3, Lt, CLR_BLACK);
  Edge(X + 4, Y + 4, X + Cs - 5, Y + Cs - 5, Dk, Lt);
  For K := 0 To Cs - 11 Do
  Begin
    FBar(X + 5 + K, Y + 5 + K, X + 5 + K, Y + 5 + K, Lt);
    FBar(X + Cs - 6 - K, Y + 5 + K, X + Cs - 6 - K, Y + 5 + K, Lt);
  End;
End;

{ le magasinier }
Procedure DrawMan(X, Y : LongInt);
Var Cx : LongInt;
Begin
  Cx := X + Cs Div 2;
  Disc(Cx, Y + 6, 4, CLR_BLACK);
  Disc(Cx, Y + 6, 3, CLR_YELLOW);
  FBar(Cx - 2, Y + 5, Cx - 2, Y + 5, CLR_BLACK);
  FBar(Cx + 1, Y + 5, Cx + 1, Y + 5, CLR_BLACK);
  FBar(Cx - 4, Y + 1, Cx + 4, Y + 2, CLR_RED);
  FBar(Cx - 4, Y + 11, Cx + 4, Y + 16, CLR_BLUE);
  FBar(Cx - 7, Y + 11, Cx - 5, Y + 15, CLR_BLUE);
  FBar(Cx + 5, Y + 11, Cx + 7, Y + 15, CLR_BLUE);
  FBar(Cx - 4, Y + 17, Cx - 1, Y + 20, CLR_DARKBLUE);
  FBar(Cx + 1, Y + 17, Cx + 4, Y + 20, CLR_DARKBLUE);
End;

Procedure DrawCell(I : LongInt);
Var X, Y : LongInt;
Begin
  If (I Mod GWd >= LvW) Or (I Div GWd >= LvH) Then Exit;
  X := OffX + (I Mod GWd) * Cs; Y := OffY + (I Div GWd) * Cs;
  Case G[I] Of
    TWall : DrawWall(X, Y);
    TFloor :
      Begin
        FBar(X, Y, X + Cs - 1, Y + Cs - 1, CLR_PALEGRAY);
        FBar(X + Cs - 1, Y, X + Cs - 1, Y + Cs - 1, CLR_WHITE);
        FBar(X, Y + Cs - 1, X + Cs - 1, Y + Cs - 1, CLR_WHITE);
        If (Goal[I] <> 0) And (Box[I] = 0) Then DrawGoal(X + Cs Div 2, Y + Cs Div 2);
        If Box[I] <> 0 Then DrawBox(X, Y, Goal[I] <> 0);
        If I = Pl Then DrawMan(X, Y);
      End;
  Else
    FBar(X, Y, X + Cs - 1, Y + Cs - 1, CLR_DARKCYAN);
  End;
End;

Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

Function NSolved : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 1 To NLevels Do If Solved[K] <> 0 Then Inc(N);
  NSolved := N;
End;

{ compteurs du panneau }
Procedure DrawCounters;
Begin
  FBar(PnX, 48, PnX + PW - 1, 160, CLR_PALEGRAY);
  OutTxt(PnX, 50, Chr(144) + 'tage ' + IStr(Level) + ' / ' + IStr(NLevels), CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 72, 'Pas : ' + IStr(Moves), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, 90, 'Pouss' + Chr(130) + 'es : ' + IStr(Pushes), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, 108, 'Caisses : ' + IStr(BoxesHome) + ' / ' + IStr(NGoal), CLR_BLACK, CLR_PALEGRAY);
  If BestMv[Level] > 0 Then OutTxt(PnX, 126, 'Record : ' + IStr(BestMv[Level]), CLR_DARKGREEN, CLR_PALEGRAY);
  OutTxt(PnX, 144, 'R' + Chr(130) + 'ussis : ' + IStr(NSolved), CLR_BLACK, CLR_PALEGRAY);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 8 * 16) Div 2, 10, 'SOKO-BAN', CLR_DARKPINK, CLR_PALEGRAY);
  DrawCounters;
  Button(PnX, 176, PW, 28, 'Recommencer');
  Button(PnX, 210, PW, 28, 'Annuler');
  Button(PnX, 244, 68, 28, '<');
  Button(PnX + 72, 244, 68, 28, '>');
  Button(PnX, 278, PW, 28, 'Choisir...');
  OutTxt(PnX, 316, 'Fl' + Chr(138) + 'ches : marcher', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 332, 'Ctrl+Z : annuler', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 348, 'F8 F9 : ' + Chr(130) + 'tage', CLR_DARKGRAY, CLR_PALEGRAY);
End;

{ choix de l'etage : 85 boutons sur le plateau }
Procedure DrawPicker;
Var K, X, Y : LongInt; S : String;
Begin
  FBar(BX0, BY0, BX0 + AW - 1, BY0 + AH - 1, CLR_DARKCYAN);
  S := 'Choisissez l''' + Chr(130) + 'tage';
  OutTxt(BX0 + (AW - Length(S) * 8) Div 2, BY0 + 8, S, CLR_WHITE, CLR_DARKCYAN);
  For K := 1 To NLevels Do
  Begin
    X := BX0 + 10 + ((K - 1) Mod 10) * 42; Y := BY0 + 34 + ((K - 1) Div 10) * 34;
    If Solved[K] <> 0 Then FBar(X, Y, X + 37, Y + 27, CLR_GREEN) Else FBar(X, Y, X + 37, Y + 27, CLR_PALEGRAY);
    Edge(X, Y, X + 37, Y + 27, CLR_WHITE, CLR_BLACK);
    If K = PickSel Then
    Begin
      Edge(X - 1, Y - 1, X + 38, Y + 28, CLR_YELLOW, CLR_YELLOW);
      Edge(X - 2, Y - 2, X + 39, Y + 29, CLR_YELLOW, CLR_YELLOW);
    End;
    S := IStr(K);
    If Solved[K] <> 0 Then OutTxt(X + 19 - Length(S) * 4, Y + 6, S, CLR_BLACK, CLR_GREEN)
    Else OutTxt(X + 19 - Length(S) * 4, Y + 6, S, CLR_BLACK, CLR_PALEGRAY);
  End;
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure PaintAll(H : LongInt);
Var I : LongInt;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(BX0 - 2, BY0 - 2, BX0 + AW + 1, BY0 + AH + 1, CLR_DARKGRAY, CLR_WHITE);
  If Picking <> 0 Then DrawPicker
  Else
  Begin
    FBar(BX0, BY0, BX0 + AW - 1, BY0 + AH - 1, CLR_DARKCYAN);
    For I := 0 To NC - 1 Do DrawCell(I);
  End;
  DrawPanel;
  DrawStatus;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ apres un pas : les trois cases autour, les compteurs, la barre d'etat }
Procedure ShowStep(Old, D : LongInt);
Begin
  If Client = 0 Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  DrawCell(Old);
  If (Old + DirD(D) >= 0) And (Old + DirD(D) < NC) Then DrawCell(Old + DirD(D));
  If (Old + 2 * DirD(D) >= 0) And (Old + 2 * DirD(D) < NC) Then DrawCell(Old + 2 * DirD(D));
  If (Old - DirD(D) >= 0) And (Old - DirD(D) < NC) Then DrawCell(Old - DirD(D));
  DrawCounters;
  DrawStatus;
  Dummy := WinReleasePS(Hps);
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure StartLevel(N : LongInt);
Begin
  If N < 1 Then N := 1;
  If N > NLevels Then N := NLevels;
  LoadLevel(N);
  Picking := 0; Demo := 0;
  Msg := Chr(144) + 'tage ' + IStr(N) + ' : poussez les ' + IStr(NGoal) + ' caisses sur les cibles (losanges).';
  If N = 1 Then Msg := Msg + ' F3 : d' + Chr(130) + 'mo.';
  Redraw;
End;

Procedure LevelDone;
Var S : String;
Begin
  NPath := 0; Demo := 0;
  Solved[Level] := 1;
  If (BestMv[Level] = 0) Or (Moves < BestMv[Level]) Then BestMv[Level] := Moves;
  Msg := Chr(144) + 'tage ' + IStr(Level) + ' r' + Chr(130) + 'ussi en ' + IStr(Moves) + ' pas et ' + IStr(Pushes) +
         ' pouss' + Chr(130) + 'es !';
  Redraw;
  S := Msg + Chr(10) + Chr(10);
  If Level < NLevels Then
  Begin
    If Ask(S + Chr(144) + 'tage suivant ?', 'Soko-Ban', MB_YESNO Or MB_QUERY) = MBID_YES Then StartLevel(Level + 1);
  End
  Else Dummy := Ask(S + 'Bravo, c''est le dernier ' + Chr(130) + 'tage !', 'Soko-Ban', MB_OK Or MB_INFORMATION);
End;

{ un pas (clavier, souris, demonstration) }
Procedure Step(D : LongInt);
Var Old : LongInt;
Begin
  Old := Pl;
  If Not TryMove(D) Then
  Begin
    NPath := 0;
    Exit;
  End;
  ShowStep(Old, D);
  If BoxesHome = NGoal Then LevelDone;
End;

Procedure Undo;
Var Old, D : LongInt; Ok : Boolean;
Begin
  NPath := 0; Demo := 0;
  If NUndo = 0 Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  D := UndoD[NUndo - 1] And 3;
  Old := Pl;
  Ok := UndoStep;
  If Client = 0 Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  DrawCell(Old - DirD(D)); DrawCell(Old);
  If (Old + DirD(D) >= 0) And (Old + DirD(D) < NC) Then DrawCell(Old + DirD(D));
  DrawCounters;
  Dummy := WinReleasePS(Hps);
End;

Procedure StartDemo;
Begin
  StartLevel(1);
  DemoS := DemoMoves(0) + '';
  Demo := 1; DemoPos := 1;
  Msg := 'D' + Chr(130) + 'monstration de l''' + Chr(130) + 'tage 1 (une touche l''arr' + Chr(136) + 'te).';
  Redraw;
End;

Procedure TimerTick;
Var Ch : Char; D : LongInt;
Begin
  If Picking <> 0 Then Exit;
  If Demo > 0 Then
  Begin
    If DemoPos > Length(DemoS) Then
    Begin
      Inc(Demo);
      DemoS := DemoMoves(Demo - 1);
      DemoPos := 1;
      If DemoS = '' Then
      Begin
        Demo := 0;
        Exit;
      End;
    End;
    Ch := DemoS[DemoPos];
    Inc(DemoPos);
    Case Ch Of
      'U' : D := 0;
      'D' : D := 1;
      'L' : D := 2;
    Else
      D := 3;
    End;
    Step(D);
    Exit;
  End;
  If IPath < NPath Then
  Begin
    D := Path[IPath];
    Inc(IPath);
    Step(D);
  End;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_RESTART : StartLevel(Level);
    CM_UNDO : Undo;
    CM_PREV : If Level > 1 Then StartLevel(Level - 1) Else Dummy := WinAlarm(HWND_DESKTOP, 0);
    CM_NEXT : If Level < NLevels Then StartLevel(Level + 1) Else Dummy := WinAlarm(HWND_DESKTOP, 0);
    CM_CHOOSE :
      Begin
        Picking := 1; PickSel := Level; NPath := 0; Demo := 0;
        Msg := 'Cliquez un ' + Chr(130) + 'tage (en vert : r' + Chr(130) + 'ussi), ou fl' + Chr(138) +
               'ches et Entr' + Chr(130) + 'e ; ' + Chr(144) + 'chap : annuler.';
        Redraw;
      End;
    CM_DEMO : StartDemo;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES :
      Begin
        LClr;
        LAdd('Poussez toutes les caisses sur les cibles (losanges bleus) : une caisse rang' + Chr(130) +
             'e devient verte. Le magasinier pousse une caisse ' + Chr(133) + ' la fois en marchant contre elle ; ');
        LAdd('il ne peut ni tirer une caisse, ni en pousser deux. Attention aux coins : une caisse pouss' + Chr(130) +
             'e dans un coin ne peut plus en sortir (Ctrl+Z annule un pas).' + Chr(10) + Chr(10));
        LAdd('Clavier : fl' + Chr(138) + 'ches (marcher, pousser), Ctrl+Z ou Retour arri' + Chr(138) +
             're (annuler), F10 ou ' + Chr(144) + 'chap (recommencer), F8 et F9 (' + Chr(130) +
             'tage pr' + Chr(130) + 'c' + Chr(130) + 'dent et suivant), F2 (choisir l''' + Chr(130) + 'tage), ');
        LAdd('F3 (d' + Chr(130) + 'monstration de l''' + Chr(130) + 'tage 1). Souris : cliquer une case libre (le ' +
             'magasinier y va) ou une caisse voisine (la pousser).');
        Dummy := LMsgBox('Soko-Ban - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Soko-Ban pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'SOKOBAN.PAS de 7iles (1992, mode texte) avec ses 85 ' + Chr(130) + 'tages.' + Chr(10) +
                            'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) + ' par OS2PC.',
                            'A propos de Soko-Ban', MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Procedure Click(Mx, My : LongInt);
Var X, Y, C, R, I, D, K : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If Picking <> 0 Then
  Begin
    For K := 1 To NLevels Do
      If (X >= BX0 + 10 + ((K - 1) Mod 10) * 42) And (X < BX0 + 48 + ((K - 1) Mod 10) * 42) And
         (Y >= BY0 + 34 + ((K - 1) Div 10) * 34) And (Y < BY0 + 62 + ((K - 1) Div 10) * 34) Then
      Begin
        StartLevel(K);
        Exit;
      End;
    Exit;
  End;
  If (X >= OffX) And (X < OffX + LvW * Cs) And (Y >= OffY) And (Y < OffY + LvH * Cs) Then
  Begin
    Demo := 0;
    C := (X - OffX) Div Cs; R := (Y - OffY) Div Cs;
    I := R * GWd + C;
    { caisse voisine : la pousser }
    For D := 0 To 3 Do
      If (Pl + DirD(D) = I) And (Box[I] <> 0) Then
      Begin
        NPath := 0;
        Step(D);
        Exit;
      End;
    If FindPath(I) Then TimerTick Else Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 176) And (Y < 204) Then Command(CM_RESTART)
    Else If (Y >= 210) And (Y < 238) Then Command(CM_UNDO)
    Else If (Y >= 244) And (Y < 272) Then
    Begin
      If X < PnX + 70 Then Command(CM_PREV) Else Command(CM_NEXT);
    End
    Else If (Y >= 278) And (Y < 306) Then Command(CM_CHOOSE);
  End;
End;

Procedure Key(D : LongInt);
Begin
  NPath := 0;
  If Demo > 0 Then
  Begin
    Demo := 0;
    Exit;
  End;
  If Picking <> 0 Then
  Begin
    Case D Of
      0 : If PickSel > 10 Then PickSel := PickSel - 10;
      1 : If PickSel + 10 <= NLevels Then PickSel := PickSel + 10;
      2 : If PickSel > 1 Then Dec(PickSel);
    Else
      If PickSel < NLevels Then Inc(PickSel);
    End;
    Redraw;
    Exit;
  End;
  Step(D);
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Fl And KC_CTRL) <> 0 Then
  Begin
    If (Ch = 26) Or (Ch = Ord('z')) Or (Ch = Ord('Z')) Then Undo Else KeyChar := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_CHOOSE); Exit; End;
    If Vk = VK_F3 Then Begin Command(CM_DEMO); Exit; End;
    If Vk = VK_F8 Then Begin Command(CM_PREV); Exit; End;
    If Vk = VK_F9 Then Begin Command(CM_NEXT); Exit; End;
    If Vk = VK_F10 Then Begin Command(CM_RESTART); Exit; End;
    If Vk = VK_UP Then Begin Key(0); Exit; End;
    If Vk = VK_DOWN Then Begin Key(1); Exit; End;
    If Vk = VK_LEFT Then Begin Key(2); Exit; End;
    If Vk = VK_RIGHT Then Begin Key(3); Exit; End;
    If Vk = VK_BACKSPACE Then Begin Undo; Exit; End;
    If Vk = VK_ESC Then
    Begin
      If Picking <> 0 Then
      Begin
        Picking := 0;
        Redraw;
      End
      Else Command(CM_RESTART);
      Exit;
    End;
    If ((Vk = VK_NEWLINE) Or (Vk = VK_ENTER)) And (Picking <> 0) Then
    Begin
      StartLevel(PickSel);
      Exit;
    End;
  End;
  KeyChar := False;
End;

Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  MainProc := 0;
  Case Msg Of
    WM_SIZE :
      Begin
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        CW := Rc[2]; CH := Rc[3];
      End;
    WM_PAINT : PaintAll(H);
    WM_TIMER : If Lo16(Mp1) = 1 Then TimerTick;
    WM_BUTTON1DOWN :
      Begin
        Dummy := WinSetFocus(HWND_DESKTOP, H);
        Click(S16(Mp1), S16(Mp1 Shr 16));
        MainProc := 1;
      End;
    WM_COMMAND : Command(Lo16(Mp1));
    WM_CHAR :
      If Not KeyChar(Mp1, Mp2) Then MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2) Else MainProc := 1;
    WM_CLOSE : Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Menus                                                                 }
{ ==================================================================== }

Procedure MB(V : LongInt);
Begin
  MenuT[MenuLen] := V And 255;
  Inc(MenuLen);
End;

Procedure MW(V : LongInt);
Begin
  MB(V And 255); MB((V Shr 8) And 255);
End;

Function MenuOpen : LongInt;
Begin
  MenuOpen := MenuLen;
  MW(0); MW(0); MW(0);
End;

Procedure MenuClose(H, Count : LongInt);
Begin
  WrW(LongInt(@MenuT) + H, MenuLen - H);
  WrW(LongInt(@MenuT) + H + 4, Count);
End;

Procedure MItem(Style, Attr, Id : LongInt; S : String);
Var K : LongInt;
Begin
  MW(Style); MW(Attr); MW(Id);
  If (Style And MIS_SEPARATOR) = 0 Then
  Begin
    For K := 1 To Length(S) Do MB(Ord(S[K]));
    MB(0);
  End;
End;

{ police 8 x 16 du VGA (VIOCALLS) pour les textes agrandis }
Procedure LoadFont;
Var P, K : LongInt; Inf : Array[0..15] Of Byte;
Begin
  FontH := 0;
  For K := 0 To 15 Do Inf[K] := 0;
  WrW(LongInt(@Inf), 14); WrW(LongInt(@Inf) + 2, 1);
  If VioGetFont(LongInt(@Inf), 0) <> 0 Then Exit;
  P := RdL(LongInt(@Inf) + 8);
  K := Inf[6] Or (Inf[7] Shl 8);
  If (P = 0) Or (K < 8) Or (K > 16) Then Exit;
  FontH := K;
  For K := 0 To 256 * FontH - 1 Do Font[K] := RdB(P + K);
End;

Var
  Fl, H0, H1, H2, Sw, Sh, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; Picking := 0; Demo := 0; NPath := 0; IPath := 0; Level := 1;
  For K := 1 To 85 Do
  Begin
    Solved[K] := 0; BestMv[K] := 0;
  End;
  Client := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) > 6) And ((Copy(S, 1, 6) = '/SEED:') Or (Copy(S, 1, 6) = '/seed:')) Then
      Val(Copy(S, 7, 20), Seed, E);
    If (Length(S) > 7) And ((Copy(S, 1, 7) = '/LEVEL:') Or (Copy(S, 1, 7) = '/level:')) Then
      Val(Copy(S, 8, 20), Level, E);
    If (S = '/DEMO') Or (S = '/demo') Then Demo := -1;
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  Dummy := WinRegisterClass(Hab, Z('SOKOBAN'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('SOKOBAN'), Z2('Soko-Ban'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RESTART, '~Recommencer l''' + Chr(130) + 'tage' + Chr(9) + 'F10');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler un pas' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_PREV, Chr(144) + 'tage ~pr' + Chr(130) + 'c' + Chr(130) + 'dent' + Chr(9) + 'F8');
  MItem(MIS_TEXT, 0, CM_NEXT, Chr(144) + 'tage ~suivant' + Chr(9) + 'F9');
  MItem(MIS_TEXT, 0, CM_CHOOSE, '~Choisir l''' + Chr(130) + 'tage...' + Chr(9) + 'F2');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_DEMO, '~D' + Chr(130) + 'monstration' + Chr(9) + 'F3');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 10);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Soko-Ban');
  MenuClose(H2, 2);
  MenuClose(H0, 2);
  M := WinCreateMenu(Frame, LongInt(@MenuT));
  Rc[0] := 0; Rc[1] := 0; Rc[2] := CWant; Rc[3] := CHWant;
  Dummy := WinCalcFrameRect(Frame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  X := (Sw - Fw) Div 2; Y := (Sh - Fh) Div 2;
  If X < 0 Then X := 0;
  If Y < 0 Then Y := Sh - Fh;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  If Demo < 0 Then StartDemo Else StartLevel(Level);
  Dummy := WinStartTimer(Hab, Client, 1, 70);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
