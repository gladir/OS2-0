{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: XIANGQI - Xiangqi, les echecs chinois, contre l'ordinateur
                pour le Presentation Manager d'OS/2-0 (dossier Jeux du
                bureau).
}

Program XIANGQI;

{$R-,S-,I-}

{ Compilation : OS2PC XIANGQI.PAS   (produit XIANGQI.EXE)

  Portage vers OS/2-0 du prototype XIANGQI.PAS du depot 7iles (Turbo
  Pascal, BGI en 640 x 480, clavier seulement) : fenetre de Presentation
  Manager avec menus, image en memoire recopiee par GpiDrawBits (seules
  les zones qui changent sont recopiees), plateau de bois veine avec ses
  neuf colonnes et dix rangees, la riviere (Chu he, Han jie, en
  ideogrammes), les deux palais et leurs diagonales, les reperes des
  canons et des soldats ; pieces rondes d'ivoire en relief, a l'anneau
  et a l'ideogramme graves (rouge ou noir), ombre portee, piece soulevee
  quand elle est choisie, pieces qui glissent, liste des coups en
  notation chinoise, barre d'etat et apparence d'OS/2 Warp 3.

  Comme le prototype : le rouge (en bas) contre le noir (en haut),
  General, Conseillers, Elephants, Chevaux, Chars, Canons et Soldats avec
  leurs deplacements du Xiangqi ; partie contre l'ordinateur ou a deux.
  Ce qui est corrige : l'echec n'etait jamais detecte (la verification
  refusait les pieces du camp qui n'a pas le trait), donc ni l'echec et
  mat, ni l'interdiction de laisser son General en prise ; la regle des
  Generaux face a face manquait ; le pat comptait pour nul (au Xiangqi,
  le camp qui ne peut plus jouer perd) ; l'ordinateur ne regardait qu'un
  demi-coup et recalculait toutes les positions a chaque case (lent) ;
  la souris n'etait pas prise en charge.
  Ce qui s'ajoute : recherche alpha-beta (negamax, approfondissement
  progressif, recherche des prises) en trois niveaux, coups possibles
  marques, dernier coup marque, annulation, indice, choix du camp
  (plateau retourne), partie a deux, demonstration, nulle par triple
  repetition, par 60 coups de chaque camp sans prise ou par manque de
  pieces d'attaque, bruitages.

  Souris : cliquer une piece (elle se souleve), puis son point
  d'arrivee. Clavier : fleches (curseur), Espace ou Entree (choisir puis
  jouer), Echap (lacher la piece), U ou Retour arriere (annuler), I
  (indice), F2 (nouvelle partie), F1 (regles).
  Parametres : /SEED:n ; /LEVEL:n (1 a 3) ; /AUTO (demonstration :
  l'ordinateur joue les deux camps) ; /NOSOUND ; /TEST (essais des regles
  et partie jouee par l'ordinateur sans fenetre, resultat sur le port
  serie COM1). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_INFORMATION = $30; MB_MOVEABLE = $4000;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_BACKSPACE = $05; VK_NEWLINE = $08; VK_ESC = $0F; VK_SPACE = $10;
  VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_UNDO = 102; CM_HINT = 103; CM_QUIT = 104;
  CM_LEVEL1 = 201; CM_LEVEL2 = 202; CM_LEVEL3 = 203; CM_BLACK = 204; CM_TWO = 205; CM_SHOW = 206;
  CM_AUTO = 207; CM_SOUND = 208;
  CM_RULES = 301; CM_ABOUT = 302;
  { image : plateau de 360 x 400 }
  BW = 360; BH = 400; OX = 8; OY = 8;
  PnX = 380; PW = 236;
  CWant = 624; CHWant = 436;
  { plateau : 9 colonnes, 10 rangees, 39 points entre deux lignes }
  NC = 9; NR = 10; NSq = 90; GX = 24; GY = 24; Sp = 39; PR = 18; PS = 40;
  { pieces : 1 General, 2 Conseiller, 3 Elephant, 4 Cheval, 5 Char,
    6 Canon, 7 Soldat ; rouge > 0, noir < 0 }
  GEN = 1; ADV = 2; ELE = 3; HOR = 4; CHA = 5; CAN = 6; SOL = 7;
  MaxPly = 40; MaxMv = 160; MaxHist = 600;
  Inf = 1000000; MateVal = 100000;
  PieceVal : Array[0..7] Of LongInt = (0, 0, 200, 200, 400, 900, 450, 100);
  { couleurs de l'image }
  C_WOOD = 0;                                  { 0..31 : bois (sombre -> clair) }
  C_WOODS = 32;                                { 32..63 : bois a l'ombre }
  C_LINE = 64; C_LINES = 65; C_IVORY = 66;     { 66..81 : ivoire (sombre -> clair) }
  C_INKR = 82; C_INKB = 85;                    { 82..84 et 85..87 : encre rouge et noire }
  C_EDGE = 88; C_SEL = 89; C_DOT = 90; C_DOTE = 91; C_LAST = 92; C_CHECK = 93; C_HINT = 94; C_CURSOR = 95;
  C_BANNER = 96; C_BANNERE = 97; C_YELLOW = 98; C_WHITE = 99; C_SHADOW = 100; C_GREEN = 101; C_DARK = 102;
  C_RIVER = 103;
  T_NONE = 255; T_SHADE = 254;
  { etats de la partie }
  O_PLAY = 0; O_REDWIN = 1; O_BLACKWIN = 2; O_DRAW = 3;
  SndRate = 11025;
  { ideogrammes des pieces (18 x 18, 4 nuances : . + * #) : rouge Shuai, Shi, Xiang,
    Ma, Ju, Pao, Bing ; noir Jiang, Shi, Xiang, Ma, Ju, Pao, Zu }
  GlyphS : Array[0..251] Of String[18] = (
    '..................', '....*+......+.....', '...+#......+#.....',
    '..+#*......+#.....', '.+#***#.+***#***..', '.+*...#.+*.+#..#..',
    '.+*...#.+*.+#..#..', '.+*+++#.+*.+#..#..', '.+#***#.+*.+#..#..',
    '.+*.....+*.+#..#..', '.+#****.+*.+#..#..', '.+#+++#.+*.+#..#..',
    '.+*...#.+*.+#+*#..', '.+*...#.++.+#.+...', '.+#***#....+#.....',
    '.+#+++#....+#.....', '.+*........+#.....', '..................',
    '..................', '.....*+...+*......', '....+#+...+#......',
    '....**....+#......', '....#+....+#......', '...*#.....+#......',
    '..+#*.+*++*#+++++.', '.+#**.+****#*****.', '+#++*.....+#......',
    '...+*.....+#......', '...+*.....+#......', '...+*.....+#......',
    '...+*.....+#......', '...+*.....+#......', '...+*..++++#++++..',
    '...+*.+*********+.', '...+*.............', '..................',
    '..................', '....+#............', '....+#...+******..',
    '....+#...**++++#..', '..+++#+++*+...+#..', '.+***#****+...+#..',
    '....##...******#..', '....##*..**++++#..', '...+###*.*+...+#..',
    '...**#.#**+...+#..', '..+#+#.+.**+++*#..', '..#*+#...**+++*#..',
    '.*#.+#...*+...+#..', '.*+.+#...*+...+#..', '....+#...***++*#..',
    '....+#...**+++*#..', '....+*...*+...+*..', '..................',
    '..................', '....+*.++++++++...', '....**.#***#***+..',
    '....#+.#..+#......', '...+*..#***#***...', '...#+..#+++#+++...',
    '..*#+..#..+#......', '.*##+..##*##**#+..', '+#+#+..#..+#......',
    '...#+..#+++#+++++.', '...#+..**********.', '...#+.....+.+*.**.',
    '...#+.**#+**.#+**.', '...#++#.+#.#+++**.', '...#+**..*.....**.',
    '...#++.......+*#*.', '...*+.........**..', '..................',
    '..................', '.....*+...+#......', '....+#+...+#......',
    '....**+****#****+.', '....#+....+#......', '...*#..****#***+..',
    '..+#*..*+++#++**..', '.+##*..*+.+#..**..', '.#*+*..*#**#**#*..',
    '...+*..*+..#..**..', '...+*..****#****..', '...+*..++++#++++..',
    '...+*.+++++#+++++.', '...+*.*****#*****.', '...+*......#......',
    '...+*.....+#......', '...+*......+......', '..................',
    '..................', '...+#....+*.......', '...+#....**.......',
    '...+#....#+.......', '...+#.*.+#######..', '..#+#*#.#+....+#..',
    '.+#+##.+#++++.+#..', '.#++#+.##***#.+#..', '.#.+#.*#*+.+#.+#..',
    '...+#..+*+.+#.+#..', '...+#+..*####.+#..', '...+##..*+...+*#..',
    '...**#*.*+...##+..', '...#++#.*+......*.', '..**..+.*+......#.',
    '.+#.....********#.', '.++......+******+.', '..................',
    '..................', '..........++#*....', '....+#####**+.....',
    '....+*............', '....+*............', '....+#*********...',
    '....+*++++#++++...', '....+*....#+......', '....+*....#+......',
    '....+*....#+......', '.+++*#++++#*+++++.', '.*+++++++++++++++.',
    '.....*+....*+.....', '....+#+....*#+....', '...+#+......*#+...',
    '..*#+........*#+..', '.*#+..........*+..', '..................',
    '..................', '.....*+...+*......', '..#+.**...##***+..',
    '..#..*+..*#+++#+..', '..#..*+.***#.+#...', '..#..**##*.**#+...',
    '..#++*+++#+.#*....', '..+**#+..+*#*++...', '.....*++*##+.**...',
    '.+***#++*+...**...', '..#*+*+**#***##**.', '..*+.*+.+#...*+...',
    '..*+.*+..**..*+...', '..#+.*+...*..*+...', '.+#..*+......*+...',
    '.*+..**....++*+...', '.....*+....+#*....', '..................',
    '..................', '........++........', '........#+........',
    '........*+........', '........*+........', '........*+........',
    '........*+........', '.*******#********.', '.*++++++#*+++++++.',
    '........*+........', '........*+........', '........*+........',
    '........*+........', '........*+........', '........*+........',
    '..******##*****+..', '..*+++++++++++++..', '..................',
    '..................', '......*...........', '.....*#+++++......',
    '....*#****##......', '...*#+...+#+......', '..*##***##***#*...',
    '.#***...#+...+*...', '...*****#******...', '....++*##++++++...',
    '....+*#+#*..+#*...', '.+*##*+*##*##+....', '.**++*#**###......',
    '..+*#*+*#+#**.....', '.+#*+.*#+.#.**....', '...+*#*..+*..*#*..',
    '.*##*+..*#+...+*..', '.++....**.........', '..................',
    '..................', '...*###########+..', '...*+...+*........',
    '...**+++**+++++...', '...******#*****...', '...*+...+*........',
    '...**+++*#+++++...', '...**+++*#+++++...', '...*+...+*........',
    '...*#***##******+.', '...........+...**.', '..++.*..#..**..**.',
    '..#+.#*.*#..#*.**.', '.*#..+#..**..+.**.', '+#+...*........**.',
    '.+...........+*#*.', '.............+**..', '..................',
    '..................', '........**........', '........*+........',
    '.+##############..', '........*+........', '...+****##****+...',
    '...**+++**+++#+...', '...**+++**+++#+...', '...*#***##***#+...',
    '...**...*+...#+...', '...*##########+...', '........*+........',
    '.+++++++**+++++++.', '.*******##*******.', '........*+........',
    '........*+........', '........*+........', '..................',
    '..................', '.........+........', '.++++++..#+.......',
    '.**#***.+#*****+..', '...#+...#*++++*#..', '...#...+#.....+#..',
    '..**...#*++*+.+#..', '..#*++.***+**.+#..', '.+##*#+.**.+*.+#..',
    '.*#*.*+.**.+*.+#..', '.#**.*+.*###*.+#..', '+#+*.*+.**....+#..',
    '..+*.*+.**...*#*..', '..+*+*+.**...*+.*.', '..+#*#+.**......#.',
    '..+*.*+.+*++++++#.', '.........*******+.', '..................',
    '..................', '.......**.........', '.......+#+........',
    '.+**************..', '.....**....**.....', '.....#+...+#+.....',
    '....+#+...##+.....', '....#*#+.*#*#+....', '...**.+#+#..+#+...',
    '..*#...+#+...+*...', '..*.....#+........', '+*******#*******+.',
    '.+++++++#+++++++..', '........#+........', '........#+........',
    '........#+........', '........#+........', '..................');
  { ideogrammes de la riviere (26 x 26) : Chu he, Han jie }
  RivS : Array[0..103] Of String[26] = (
    '.......+*+......+*+.......', '.......+#+......+#*.......', '.......+#+......+#*.......',
    '..+++++*#++++++++#*+++++..', '.+######################*.', '......*##+.....+####......',
    '.....*####*...+#####*.....', '....+##*###*..##*#**#+....', '...+##++#+##+##++#*.*#*...',
    '..+##+.+#+.+##+.+#*..*##+.', '.*#*...+#+..*+..+#*...**..', '.**....+#+......+#*.......',
    '...+......................', '...###################*...', '............*#.....+##+...',
    '......+.....*#.....*#+....', '......##....*#............', '.....+#*....*#+++++++.....',
    '.....*#*....*#*******.....', '....+###+...*#............', '....*#+##+..*#............',
    '...+#*.+##*.*#............', '..+##....*####++..........', '.+##+.....+*###########*..',
    '.##+.........++******##+..', '..+.......................', '..........................',
    '...**.....................', '..+###...++++++++++++++++.', '....###..################.',
    '.....###............#*....', '......*.............#*....', '....................#*....',
    '.##.......+++++++...#*....', '.###......#######+..#*....', '..*##+....#*...*#+..#*....',
    '...*#+.*..#*...*#+..#*....', '....+.+#..#*...*#+..#*....', '......**..#*...*#+..#*....',
    '......#+..#*...*#+..#*....', '.....+#...##+++*#+..#*....', '.....#*...#######+..#*....',
    '....+#+...#*...*#+..#*....', '....*#....#*...*#+..#*....', '....#*....++...++...#*....',
    '...*#+..............#*....', '...##...............#*....', '..+#*...............#*....',
    '..##*..............+#*....', '.*##+............####+....', '..+*.............###+.....',
    '..........................', '............+......+......', '...*.......*#+....+#*.....',
    '..+##......+#+....+#*.....', '...*##..***##******##***+.', '....*#*.+++*#*++++*#*+++..',
    '.....**....+#+....+#+.....', '...........+##****##+.....', '.*+.........+++*#+++......',
    '+##+......+++++*#++++++...', '.+##+....+############*...', '..+##.+..+#....*#....**...',
    '...+..#..+#....*#....**...', '.....+#..+############*...', '.....**........*#.........',
    '.....#+........*#.........', '....+#...*############*...', '....**....+++++*#++++++...',
    '....#+.........*#.........', '...+#...*******##*******+.', '...*#...+++++++###++++++..',
    '...#*.........*#+##.......', '..*#+........*#*.+##......', '..##.......+*#*...+##*....',
    '.+##....+**##*......*##*+.', '.+**....+##*.........+*#..', '.........+................',
    '..........................', '....+################.....', '....+#*+++++#*+++++##.....',
    '....+#*....+#*.....*#.....', '....+#*....+#*.....*#.....', '....+#******#******##.....',
    '....+##****###*****##.....', '....+#*....+#*.....*#.....', '....+#*....+#*.....*#.....',
    '....+#*+++++#*+++++##.....', '....+################.....', '....+#*...+##*.....*#.....',
    '.....++..+##*#*....++.....', '........*##+.+##+.........', '......+##*....+##*+.......',
    '...+*###**....+*####**+++.', '.*####*.*#+...+#+.+*####+.', '.*#*+...*#+...+#+....+++..',
    '........*#+...+#+.........', '........*#....+#+.........', '.......+#*....+#+.........',
    '.......##+....+#+.........', '.....+##+.....+#+.........', '....*##+......+#*.........',
    '.....*........+*+.........', '..........................');

Var
  InDlg : LongInt;
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  Spr : Array[0..14 * PS * PS - 1] Of Byte;            { 7 pieces x 2 camps }
  Shade : Array[0..255] Of Byte;
  { position }
  Bd : Array[0..NSq - 1] Of LongInt;
  Side, Ply, Nodes, Budget, Abort, NoCap : LongInt;
  MvList, MvScore : Array[0..MaxPly * MaxMv - 1] Of LongInt;
  CapS : Array[0..MaxPly] Of LongInt;
  LegL : Array[0..MaxMv - 1] Of LongInt;
  NLeg : LongInt;
  { partie }
  HMv, HCap, HKey, HNoCap : Array[0..MaxHist] Of LongInt;
  HTxt : Array[0..MaxHist] Of String[12];
  NHist, Over, Level, CompSide, AutoAll, ShowMv, Flip, Seed, SoundOn, TestMode, Tick, Wait : LongInt;
  SelSq, CurSq, KbdUsed, HintF, HintT, LastF, LastT, OverWhy, Games, Wins, Losses : LongInt;
  { glissement d'une piece }
  AnOn, AnF, AnT, AnP, AnCap, AnK, AnN : LongInt;
  { zone a recopier }
  DX1, DY1, DX2, DY2, FullBlit : LongInt;
  Banner, Banner2, Banner3, Msg, LastMsg : String;
  LastSig : LongInt;
  { bruitages }
  SndBuf : Array[0..29999] Of Byte;
  SndOfs, SndLen, SndPri : Array[0..15] Of LongInt;
  NSndBuf, SndPrio, SndCur, SndEnd : LongInt;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Font : Array[0..4095] Of Byte;
  FontH : LongInt;
  Qmsg : Array[0..7] Of LongInt;

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
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';
Function VioGetFont(PInfo, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioGetFont';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
Function MdmPlay(PData, Bytes, Rate, Bits, Ch : LongInt) : LongInt; External 'MDM' Name 'MDMPLAY';

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

Procedure WrL(A, V : LongInt);
Begin
  WrW(A, V And $FFFF);
  WrW(A + 2, (V Shr 16) And $FFFF);
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

Function MinI(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinI := A Else MinI := B;
End;

Function MaxI(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxI := A Else MaxI := B;
End;

Function AbsI(A : LongInt) : LongInt;
Begin
  If A < 0 Then AbsI := -A Else AbsI := A;
End;

Function Rnd(N : LongInt) : LongInt;
Begin
  Seed := (Seed * 1103515245 + 12345) And $7FFFFFFF;
  Rnd := (Seed Shr 8) Mod N;
End;

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Inc(InDlg);
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
  Dec(InDlg);
End;

{ journal : port serie COM1 (mode /TEST) }
Procedure Log(S : String);
Var I, C : LongInt;
Begin
  S := S + Chr(13) + Chr(10);
  For I := 1 To Length(S) Do
  Begin
    C := Ord(S[I]);
    asm
      mov dx,3FDh
      mov ecx,100000
    @w:
      in al,dx
      test al,20h
      jnz @ok
      dec ecx
      jnz @w
    @ok:
      mov dx,3F8h
      mov eax,C
      out dx,al
    end;
  End;
End;

{ messages de plus de 255 caracteres : texte cumule dans LBuf }
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
  Inc(InDlg);
  LMsgBox := WinMessageBox(HWND_DESKTOP, Frame, LongInt(@LBuf), Z2(Cap), 0, Fl Or MB_MOVEABLE);
  Dec(InDlg);
End;

{ ==================================================================== }
{ Regles : generation des coups                                         }
{ ==================================================================== }

Function SqOf(R, C : LongInt) : LongInt;
Begin
  SqOf := R * NC + C;
End;

Function OnBoard(R, C : LongInt) : Boolean;
Begin
  OnBoard := (R >= 0) And (R < NR) And (C >= 0) And (C < NC);
End;

{ palais du camp S (1 rouge en bas, -1 noir en haut) }
Function InPalace(R, C, S : LongInt) : Boolean;
Begin
  If (C < 3) Or (C > 5) Then InPalace := False
  Else If S > 0 Then InPalace := (R >= 7) And (R <= 9)
  Else InPalace := (R >= 0) And (R <= 2);
End;

{ cote de la riviere du camp S }
Function OwnSide(R, S : LongInt) : Boolean;
Begin
  If S > 0 Then OwnSide := R >= 5 Else OwnSide := R <= 4;
End;

Function MvFrom(M : LongInt) : LongInt;
Begin
  MvFrom := M And 127;
End;

Function MvTo(M : LongInt) : LongInt;
Begin
  MvTo := (M Shr 7) And 127;
End;

Var
  GenN, GenCaps : LongInt;

Procedure AddMv(F, T : LongInt);
Var P : LongInt;
Begin
  P := Bd[T];
  If P * Side > 0 Then Exit;
  If (GenCaps <> 0) And (P = 0) Then Exit;
  If GenN < MaxMv Then
  Begin
    MvList[Ply * MaxMv + GenN] := F + T * 128;
    Inc(GenN);
  End;
End;

Procedure AddRC(F, R, C : LongInt);
Begin
  If OnBoard(R, C) Then AddMv(F, SqOf(R, C));
End;

{ coups pseudo-legaux du camp au trait (Caps : prises seulement) }
Function GenMoves(Caps : Boolean) : LongInt;
Var Sq, P, T, R, C, D, Dr, Dc, R2, C2, Scr : LongInt;
Begin
  GenN := 0;
  If Caps Then GenCaps := 1 Else GenCaps := 0;
  For Sq := 0 To NSq - 1 Do
  Begin
    P := Bd[Sq];
    If P * Side > 0 Then
    Begin
      T := AbsI(P); R := Sq Div NC; C := Sq Mod NC;
      Case T Of
        GEN :
          For D := 0 To 3 Do
          Begin
            Dr := 0; Dc := 0;
            Case D Of 0 : Dr := -1; 1 : Dr := 1; 2 : Dc := -1; 3 : Dc := 1; End;
            If InPalace(R + Dr, C + Dc, Side) Then AddMv(Sq, SqOf(R + Dr, C + Dc));
          End;
        ADV :
          For D := 0 To 3 Do
          Begin
            If D < 2 Then Dr := -1 Else Dr := 1;
            If Odd(D) Then Dc := 1 Else Dc := -1;
            If InPalace(R + Dr, C + Dc, Side) Then AddMv(Sq, SqOf(R + Dr, C + Dc));
          End;
        ELE :
          For D := 0 To 3 Do
          Begin
            If D < 2 Then Dr := -2 Else Dr := 2;
            If Odd(D) Then Dc := 2 Else Dc := -2;
            R2 := R + Dr; C2 := C + Dc;
            If OnBoard(R2, C2) And OwnSide(R2, Side) Then
              If Bd[SqOf(R + Dr Div 2, C + Dc Div 2)] = 0 Then AddMv(Sq, SqOf(R2, C2));
          End;
        HOR :
          For D := 0 To 3 Do
          Begin
            { pas d'une case orthogonal (la jambe), puis un pas diagonal }
            Dr := 0; Dc := 0;
            Case D Of 0 : Dr := -1; 1 : Dr := 1; 2 : Dc := -1; 3 : Dc := 1; End;
            If OnBoard(R + Dr, C + Dc) Then
              If Bd[SqOf(R + Dr, C + Dc)] = 0 Then
              Begin
                If Dr <> 0 Then
                Begin
                  AddRC(Sq, R + 2 * Dr, C - 1); AddRC(Sq, R + 2 * Dr, C + 1);
                End
                Else
                Begin
                  AddRC(Sq, R - 1, C + 2 * Dc); AddRC(Sq, R + 1, C + 2 * Dc);
                End;
              End;
          End;
        CHA, CAN :
          For D := 0 To 3 Do
          Begin
            Dr := 0; Dc := 0;
            Case D Of 0 : Dr := -1; 1 : Dr := 1; 2 : Dc := -1; 3 : Dc := 1; End;
            R2 := R + Dr; C2 := C + Dc; Scr := 0;
            While OnBoard(R2, C2) Do
            Begin
              If Scr = 0 Then
              Begin
                If Bd[SqOf(R2, C2)] = 0 Then AddMv(Sq, SqOf(R2, C2))
                Else
                Begin
                  If T = CHA Then
                  Begin
                    AddMv(Sq, SqOf(R2, C2));
                    R2 := -99;
                  End
                  Else Scr := 1;
                End;
              End
              Else If Bd[SqOf(R2, C2)] <> 0 Then
              Begin
                { canon : prise par-dessus un ecran }
                If Bd[SqOf(R2, C2)] * Side < 0 Then AddMv(Sq, SqOf(R2, C2));
                R2 := -99;
              End;
              If R2 >= 0 Then
              Begin
                R2 := R2 + Dr; C2 := C2 + Dc;
              End;
            End;
          End;
        SOL :
          Begin
            AddRC(Sq, R - Side, C);
            If Not OwnSide(R, Side) Then
            Begin
              AddRC(Sq, R, C - 1); AddRC(Sq, R, C + 1);
            End;
          End;
      End;
    End;
  End;
  GenMoves := GenN;
End;

Function KingSq(S : LongInt) : LongInt;
Var R, C, K : LongInt;
Begin
  K := -1;
  For R := 0 To 2 Do
    For C := 3 To 5 Do
    Begin
      If S > 0 Then
      Begin
        If Bd[SqOf(9 - R, C)] = GEN Then K := SqOf(9 - R, C);
      End
      Else If Bd[SqOf(R, C)] = -GEN Then K := SqOf(R, C);
    End;
  KingSq := K;
End;

{ le General du camp S est-il attaque (ou face au General adverse) ? }
Function InCheck(S : LongInt) : Boolean;
Var K, Kr, Kc, E, D, Dr, Dc, R2, C2, N, P, Res, Hr, Hc, Lr, Lc : LongInt;
Begin
  K := KingSq(S);
  If K < 0 Then
  Begin
    InCheck := True;
    Exit;
  End;
  Kr := K Div NC; Kc := K Mod NC; E := -S; Res := 0;
  { lignes : char, General (face a face), canon (deuxieme piece) }
  For D := 0 To 3 Do
  Begin
    Dr := 0; Dc := 0;
    Case D Of 0 : Dr := -1; 1 : Dr := 1; 2 : Dc := -1; 3 : Dc := 1; End;
    R2 := Kr + Dr; C2 := Kc + Dc; N := 0;
    While (N < 2) And OnBoard(R2, C2) Do
    Begin
      P := Bd[SqOf(R2, C2)];
      If P <> 0 Then
      Begin
        Inc(N);
        If (N = 1) And ((P = E * CHA) Or (P = E * GEN)) Then Res := 1;
        If (N = 2) And (P = E * CAN) Then Res := 1;
      End;
      R2 := R2 + Dr; C2 := C2 + Dc;
    End;
  End;
  { chevaux (jambe libre) }
  For D := 0 To 7 Do
  Begin
    Case D Of
      0 : Begin Dr := -2; Dc := -1; End;
      1 : Begin Dr := -2; Dc := 1; End;
      2 : Begin Dr := 2; Dc := -1; End;
      3 : Begin Dr := 2; Dc := 1; End;
      4 : Begin Dr := -1; Dc := -2; End;
      5 : Begin Dr := 1; Dc := -2; End;
      6 : Begin Dr := -1; Dc := 2; End;
    Else
      Begin Dr := 1; Dc := 2; End;
    End;
    Hr := Kr + Dr; Hc := Kc + Dc;
    If OnBoard(Hr, Hc) Then
      If Bd[SqOf(Hr, Hc)] = E * HOR Then
      Begin
        If AbsI(Dr) = 2 Then
        Begin
          If Dr > 0 Then Lr := Hr - 1 Else Lr := Hr + 1;
          Lc := Hc;
        End
        Else
        Begin
          Lr := Hr;
          If Dc > 0 Then Lc := Hc - 1 Else Lc := Hc + 1;
        End;
        If Bd[SqOf(Lr, Lc)] = 0 Then Res := 1;
      End;
  End;
  { soldats : de face, ou de cote apres la riviere }
  If OnBoard(Kr + S * (-1), Kc) Then
    If Bd[SqOf(Kr - S, Kc)] = E * SOL Then Res := 1;
  For D := 0 To 1 Do
  Begin
    C2 := Kc - 1 + 2 * D;
    If OnBoard(Kr, C2) Then
      If (Bd[SqOf(Kr, C2)] = E * SOL) And Not OwnSide(Kr, E) Then Res := 1;
  End;
  InCheck := Res <> 0;
End;

Procedure DoMv(M : LongInt);
Var F, T : LongInt;
Begin
  F := MvFrom(M); T := MvTo(M);
  CapS[Ply] := Bd[T];
  Bd[T] := Bd[F]; Bd[F] := 0;
  Side := -Side;
  Inc(Ply);
End;

Procedure UndoMv(M : LongInt);
Var F, T : LongInt;
Begin
  Dec(Ply);
  Side := -Side;
  F := MvFrom(M); T := MvTo(M);
  Bd[F] := Bd[T]; Bd[T] := CapS[Ply];
End;

{ joue M s'il est legal (sinon rien) }
Function TryMv(M : LongInt) : Boolean;
Begin
  DoMv(M);
  If InCheck(-Side) Then
  Begin
    UndoMv(M);
    TryMv := False;
  End
  Else TryMv := True;
End;

{ coups legaux du camp au trait dans LegL }
Function LegalMoves : LongInt;
Var N, K, C, B : LongInt;
Begin
  B := Ply * MaxMv;
  N := GenMoves(False);
  C := 0;
  For K := 0 To N - 1 Do
    If TryMv(MvList[B + K]) Then
    Begin
      UndoMv(MvList[B + K]);
      LegL[C] := MvList[B + K];
      Inc(C);
    End;
  NLeg := C;
  LegalMoves := C;
End;

Function IsLegal(F, T : LongInt) : Boolean;
Var K : LongInt; R : Boolean;
Begin
  R := False;
  For K := 0 To NLeg - 1 Do
    If LegL[K] = F + T * 128 Then R := True;
  IsLegal := R;
End;

{ ==================================================================== }
{ Recherche                                                             }
{ ==================================================================== }

Function PieceScore(P, Sq : LongInt) : LongInt;
Var T, S, R, C, V, Adv : LongInt;
Begin
  T := AbsI(P);
  If P > 0 Then S := 1 Else S := -1;
  R := Sq Div NC; C := Sq Mod NC;
  If S > 0 Then Adv := 9 - R Else Adv := R;       { avancee : 0 (rangee de depart) .. 9 }
  V := PieceVal[T];
  Case T Of
    SOL :
      If Adv >= 5 Then
      Begin
        V := 200 + (4 - AbsI(C - 4)) * 8;
        If (Adv >= 6) And (Adv <= 8) Then V := V + 30 - AbsI(C - 4) * 5;
        If Adv = 9 Then V := V - 40;
      End;
    HOR : V := V + (4 - AbsI(C - 4)) * 6 + MinI(Adv, 6) * 5;
    CAN : If C = 4 Then V := V + 15;
    CHA : V := V + MinI(Adv, 6) * 3;
  End;
  PieceScore := V;
End;

Function Evaluate : LongInt;
Var K, P, V : LongInt;
Begin
  V := 0;
  For K := 0 To NSq - 1 Do
  Begin
    P := Bd[K];
    If P > 0 Then V := V + PieceScore(P, K)
    Else If P < 0 Then V := V - PieceScore(P, K);
  End;
  Evaluate := V * Side;
End;

{ ordre : prises (victime chere, attaquant bon marche) d'abord }
Procedure OrderMoves(B, N, First : LongInt);
Var K, J, M, S : LongInt;
Begin
  For K := 0 To N - 1 Do
  Begin
    M := MvList[B + K];
    S := 0;
    If Bd[MvTo(M)] <> 0 Then S := 10 * PieceVal[AbsI(Bd[MvTo(M)])] - PieceVal[AbsI(Bd[MvFrom(M)])] + 10000;
    If M = First Then S := 1000000;
    MvScore[B + K] := S;
  End;
  For K := 1 To N - 1 Do
  Begin
    M := MvList[B + K]; S := MvScore[B + K]; J := K - 1;
    While (J >= 0) And (MvScore[B + J] < S) Do
    Begin
      MvList[B + J + 1] := MvList[B + J]; MvScore[B + J + 1] := MvScore[B + J];
      Dec(J);
    End;
    MvList[B + J + 1] := M; MvScore[B + J + 1] := S;
  End;
End;

Function Quiesce(Alpha, Beta : LongInt) : LongInt;
Var Stand, N, K, B, V, M : LongInt;
Begin
  Inc(Nodes);
  Stand := Evaluate;
  If (Stand >= Beta) Or (Ply >= MaxPly - 2) Then
  Begin
    Quiesce := Stand;
    Exit;
  End;
  If Stand > Alpha Then Alpha := Stand;
  B := Ply * MaxMv;
  N := GenMoves(True);
  OrderMoves(B, N, -1);
  For K := 0 To N - 1 Do
  Begin
    M := MvList[B + K];
    If TryMv(M) Then
    Begin
      V := -Quiesce(-Beta, -Alpha);
      UndoMv(M);
      If V >= Beta Then
      Begin
        Quiesce := V;
        Exit;
      End;
      If V > Alpha Then Alpha := V;
    End;
  End;
  Quiesce := Alpha;
End;

Function Search(Depth, Alpha, Beta : LongInt) : LongInt;
Var N, K, B, V, Legal, M : LongInt;
Begin
  If Depth <= 0 Then
  Begin
    Search := Quiesce(Alpha, Beta);
    Exit;
  End;
  Inc(Nodes);
  If Nodes > Budget Then Abort := 1;
  If Abort <> 0 Then
  Begin
    Search := 0;
    Exit;
  End;
  B := Ply * MaxMv;
  N := GenMoves(False);
  OrderMoves(B, N, -1);
  Legal := 0;
  For K := 0 To N - 1 Do
  Begin
    M := MvList[B + K];
    If TryMv(M) Then
    Begin
      Inc(Legal);
      V := -Search(Depth - 1, -Beta, -Alpha);
      UndoMv(M);
      If V >= Beta Then
      Begin
        Search := V;
        Exit;
      End;
      If V > Alpha Then Alpha := V;
    End;
  End;
  { au Xiangqi, le camp qui ne peut plus jouer a perdu (mat ou pat) }
  If Legal = 0 Then Alpha := -MateVal + Ply;
  Search := Alpha;
End;

{ meilleur coup du camp au trait : approfondissement progressif jusqu'a
  MaxD, budget de noeuds, bruit (Noise) ajoute aux notes de la racine }
Function BestMove(MaxD, Bud, Noise : LongInt) : LongInt;
Var N, K, J, B, V, Alpha, D, Best, BestV, DBest, DBestV, M, Bonus : LongInt;
    RootM, RootB : Array[0..MaxMv - 1] Of LongInt;
Begin
  Nodes := 0; Abort := 0; Budget := Bud;
  B := Ply * MaxMv;
  N := GenMoves(False);
  OrderMoves(B, N, -1);
  J := 0;
  For K := 0 To N - 1 Do
  Begin
    M := MvList[B + K];
    If TryMv(M) Then
    Begin
      UndoMv(M);
      RootM[J] := M;
      If Noise > 0 Then RootB[J] := Rnd(Noise) Else RootB[J] := 0;
      Inc(J);
    End;
  End;
  N := J;
  Best := 0; BestV := -Inf;
  If N = 0 Then
  Begin
    BestMove := 0;
    Exit;
  End;
  Best := RootM[0];
  For D := 1 To MaxD Do
  Begin
    DBest := 0; DBestV := -Inf; Alpha := -Inf;
    For K := 0 To N - 1 Do
      If Abort = 0 Then
      Begin
        M := RootM[K];
        DoMv(M);
        Bonus := RootB[K];
        V := -Search(D - 1, -Inf, -(Alpha - Bonus)) + Bonus;
        UndoMv(M);
        If (Abort = 0) And ((V > DBestV) Or (DBest = 0)) Then
        Begin
          DBestV := V; DBest := M;
        End;
        If V > Alpha Then Alpha := V;
      End;
    If (Abort <> 0) And (D > 1) Then Break;
    Best := DBest; BestV := DBestV;
    { le meilleur coup en tete pour la profondeur suivante }
    For K := 0 To N - 1 Do
      If RootM[K] = Best Then
      Begin
        For J := K Downto 1 Do
        Begin
          RootM[J] := RootM[J - 1]; V := RootB[J]; RootB[J] := RootB[J - 1]; RootB[J - 1] := V;
        End;
        RootM[0] := Best;
      End;
    If BestV >= MateVal - 100 Then Break;
    Abort := 0;
    If Nodes > Bud Then Break;
  End;
  BestMove := Best;
End;

{ niveaux : profondeur, budget, bruit }
Function LevelMove(L : LongInt) : LongInt;
Begin
  Case L Of
    1 : LevelMove := BestMove(1, 4000, 90);
    2 : LevelMove := BestMove(3, 12000, 12);
  Else
    LevelMove := BestMove(5, 45000, 4);
  End;
End;

{ ==================================================================== }
{ Partie : position, coups, notation                                    }
{ ==================================================================== }

Procedure SetupBoard;
Var K : LongInt;
Begin
  For K := 0 To NSq - 1 Do Bd[K] := 0;
  { rangees du fond : char, cheval, elephant, conseiller, General ... }
  For K := 0 To 8 Do
  Begin
    Case K Of
      0, 8 : Bd[K] := -CHA;
      1, 7 : Bd[K] := -HOR;
      2, 6 : Bd[K] := -ELE;
      3, 5 : Bd[K] := -ADV;
      4 : Bd[K] := -GEN;
    End;
    Bd[81 + K] := -Bd[K];
  End;
  Bd[SqOf(2, 1)] := -CAN; Bd[SqOf(2, 7)] := -CAN;
  Bd[SqOf(7, 1)] := CAN; Bd[SqOf(7, 7)] := CAN;
  For K := 0 To 4 Do
  Begin
    Bd[SqOf(3, K * 2)] := -SOL;
    Bd[SqOf(6, K * 2)] := SOL;
  End;
  Side := 1; Ply := 0;
End;

Function PosKey : LongInt;
Var K, H : LongInt;
Begin
  H := Side * 7919;
  For K := 0 To NSq - 1 Do
    If Bd[K] <> 0 Then H := (H * 31 + (Bd[K] + 8) * (K + 1) * 2654435) And $7FFFFFFF;
  PosKey := H;
End;

Function PieceAbbr(T : LongInt) : String;
Begin
  Case T Of
    GEN : PieceAbbr := 'G' + Chr(130) + 'n';
    ADV : PieceAbbr := 'Con';
    ELE : PieceAbbr := Chr(144) + 'l' + Chr(130);
    HOR : PieceAbbr := 'Che';
    CHA : PieceAbbr := 'Cha';
    CAN : PieceAbbr := 'Can';
  Else
    PieceAbbr := 'Sol';
  End;
End;

Function PieceName(T : LongInt) : String;
Begin
  Case T Of
    GEN : PieceName := 'G' + Chr(130) + 'n' + Chr(130) + 'ral';
    ADV : PieceName := 'Conseiller';
    ELE : PieceName := Chr(144) + 'l' + Chr(130) + 'phant';
    HOR : PieceName := 'Cheval';
    CHA : PieceName := 'Char';
    CAN : PieceName := 'Canon';
  Else
    PieceName := 'Soldat';
  End;
End;

{ colonne vue par le camp S (1 a 9 de sa droite vers sa gauche) }
Function FileOf(C, S : LongInt) : LongInt;
Begin
  If S > 0 Then FileOf := 9 - C Else FileOf := C + 1;
End;

{ notation chinoise (WXF) du coup M joue par le camp S, avant le coup :
  piece, colonne, sens (+ avance, - recule, . de cote), arrivee }
Function MoveText(M, S : LongInt) : String;
Var F, T, P, Fr, Fc, Tr, Tc, K, Fwd, Other : LongInt; Txt : String;
Begin
  F := MvFrom(M); T := MvTo(M);
  P := AbsI(Bd[F]);
  Fr := F Div NC; Fc := F Mod NC; Tr := T Div NC; Tc := T Mod NC;
  Txt := PieceAbbr(P) + ' ';
  { deux pieces semblables sur la meme colonne : avant (+) ou arriere (-) }
  Other := -1;
  For K := 0 To NR - 1 Do
    If (K <> Fr) And (Bd[SqOf(K, Fc)] = Bd[F]) Then Other := K;
  If (Other >= 0) And (P <> SOL) Then
  Begin
    If (Other - Fr) * S > 0 Then Txt := Txt + '+' Else Txt := Txt + '-';
  End
  Else Txt := Txt + IStr(FileOf(Fc, S));
  Fwd := (Fr - Tr) * S;                          { > 0 : vers l'adversaire }
  If Fwd = 0 Then Txt := Txt + '.' + IStr(FileOf(Tc, S))
  Else
  Begin
    If Fwd > 0 Then Txt := Txt + '+' Else Txt := Txt + '-';
    If (P = ADV) Or (P = ELE) Or (P = HOR) Then Txt := Txt + IStr(FileOf(Tc, S))
    Else Txt := Txt + IStr(AbsI(Fwd));
  End;
  If Bd[T] <> 0 Then Txt := Txt + 'x';
  MoveText := Txt;
End;

{ plus aucune piece d'attaque (cheval, char, canon, soldat) des deux cotes }
Function NoAttackers : Boolean;
Var K, T : LongInt; R : Boolean;
Begin
  R := True;
  For K := 0 To NSq - 1 Do
  Begin
    T := AbsI(Bd[K]);
    If (T = HOR) Or (T = CHA) Or (T = CAN) Or (T = SOL) Then R := False;
  End;
  NoAttackers := R;
End;

Function Repeats : LongInt;
Var K, N, Key : LongInt;
Begin
  Key := PosKey; N := 0;
  For K := 0 To NHist - 1 Do
    If HKey[K] = Key Then Inc(N);
  Repeats := N;
End;

{ ==================================================================== }
{ Dessin dans la fenetre (panneau, barre d'etat)                        }
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

{ ==================================================================== }
{ Image en memoire (8 bits, palette en vraies couleurs)                 }
{ ==================================================================== }

Procedure SetPal(I, C : LongInt);
Var A : LongInt;
Begin
  A := LongInt(@Bmi) + 16 + I * 4;
  WrB(A, C And 255); WrB(A + 1, (C Shr 8) And 255); WrB(A + 2, (C Shr 16) And 255);
End;

Function Mix(C1, C2, N, D : LongInt) : LongInt;
Var R, G, B : LongInt;
Begin
  R := ((C1 Shr 16) And 255) + (((C2 Shr 16) And 255) - ((C1 Shr 16) And 255)) * N Div D;
  G := ((C1 Shr 8) And 255) + (((C2 Shr 8) And 255) - ((C1 Shr 8) And 255)) * N Div D;
  B := (C1 And 255) + ((C2 And 255) - (C1 And 255)) * N Div D;
  Mix := (R Shl 16) Or (G Shl 8) Or B;
End;

Const
  IvoryMid = $F2E4C4;

Procedure InitBmi;
Var I, W : LongInt;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, BW);
  WrL(LongInt(@Bmi) + 8, BH);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
  For I := 0 To 31 Do
  Begin
    W := Mix($B87A38, $EEC888, I, 31);
    SetPal(C_WOOD + I, W);
    SetPal(C_WOODS + I, Mix(W, $201004, 9, 20));
  End;
  SetPal(C_LINE, $4A2A10); SetPal(C_LINES, $2A1606);
  For I := 0 To 15 Do
    If I < 10 Then SetPal(C_IVORY + I, Mix($9C7A4C, IvoryMid, I, 10))
    Else SetPal(C_IVORY + I, Mix(IvoryMid, $FFFCF0, I - 10, 5));
  For I := 0 To 2 Do
  Begin
    SetPal(C_INKR + I, Mix(IvoryMid, $B4141C, I + 1, 3));
    SetPal(C_INKB + I, Mix(IvoryMid, $181818, I + 1, 3));
  End;
  SetPal(C_EDGE, $5A3A1C); SetPal(C_SEL, $30E060); SetPal(C_DOT, $1EA03C); SetPal(C_DOTE, $0A4A18);
  SetPal(C_LAST, $2060E0); SetPal(C_CHECK, $FF2020); SetPal(C_HINT, $FFD020); SetPal(C_CURSOR, $00D8FF);
  SetPal(C_BANNER, $3A1A08); SetPal(C_BANNERE, $F0C070); SetPal(C_YELLOW, $FFDC46); SetPal(C_WHITE, $FFFFFF);
  SetPal(C_SHADOW, $1A0C02); SetPal(C_GREEN, $64E68C); SetPal(C_DARK, $2A1606); SetPal(C_RIVER, $6A3A14);
  For I := 0 To 255 Do Shade[I] := C_SHADOW;
  For I := 0 To 31 Do Shade[C_WOOD + I] := C_WOODS + I;
  For I := 0 To 31 Do Shade[C_WOODS + I] := C_WOODS + I Div 2;
  Shade[C_LINE] := C_LINES; Shade[C_RIVER] := C_LINES;
End;

Procedure Pix(X, Y, C : LongInt);
Begin
  If (X >= 0) And (X < BW) And (Y >= 0) And (Y < BH) Then Fb[(BH - 1 - Y) * BW + X] := C;
End;

Procedure Rect(X1, Y1, X2, Y2, C : LongInt);
Var X, Y, B : LongInt;
Begin
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  For Y := Y1 To Y2 Do
  Begin
    B := (BH - 1 - Y) * BW;
    For X := X1 To X2 Do Fb[B + X] := C;
  End;
End;

Procedure Disc(Cx, Cy, R, C : LongInt);
Var Dy, W : LongInt;
Begin
  For Dy := -R To R Do
  Begin
    W := 0;
    While (W + 1) * (W + 1) + Dy * Dy <= R * R + R Do Inc(W);
    Rect(Cx - W, Cy + Dy, Cx + W, Cy + Dy, C);
  End;
End;

{ anneau de rayon R1 a R2 }
Procedure Ring(Cx, Cy, R1, R2, C : LongInt);
Var X, Y, D2 : LongInt;
Begin
  For Y := -R2 To R2 Do
    For X := -R2 To R2 Do
    Begin
      D2 := X * X + Y * Y;
      If (D2 <= R2 * R2 + R2) And (D2 > R1 * R1 - R1) Then Pix(Cx + X, Cy + Y, C);
    End;
End;

{ assombrit un disque (ombre) }
Procedure ShadeDisc(Cx, Cy, R : LongInt);
Var X, Y, A : LongInt;
Begin
  For Y := -R To R Do
    For X := -R To R Do
      If X * X + Y * Y <= R * R + R Then
        If (Cx + X >= 0) And (Cx + X < BW) And (Cy + Y >= 0) And (Cy + Y < BH) Then
        Begin
          A := (BH - 1 - (Cy + Y)) * BW + Cx + X;
          Fb[A] := Shade[Fb[A]];
        End;
End;

{ trait d'une epaisseur de T + 1 points }
Procedure TLine(X1, Y1, X2, Y2, T, C : LongInt);
Var N, K, Dx, Dy, X, Y : LongInt;
Begin
  Dx := X2 - X1; Dy := Y2 - Y1;
  N := AbsI(Dx);
  If AbsI(Dy) > N Then N := AbsI(Dy);
  If N = 0 Then N := 1;
  For K := 0 To N Do
  Begin
    X := X1 + (Dx * K) Div N; Y := Y1 + (Dy * K) Div N;
    Rect(X, Y, X + T, Y + T, C);
  End;
End;

{ texte dans l'image (police 8 x FontH du VGA ; Sc : 1 ou 2) }
Procedure FbText(X, Y : LongInt; S : String; C, Sc : LongInt);
Var I, R, K, B : LongInt;
Begin
  If FontH = 0 Then Exit;
  For I := 1 To Length(S) Do
    For R := 0 To FontH - 1 Do
    Begin
      B := Font[Ord(S[I]) * FontH + R];
      For K := 0 To 7 Do
        If (B And ($80 Shr K)) <> 0 Then
        Begin
          If Sc = 1 Then Pix(X + (I - 1) * 8 + K, Y + R, C)
          Else Rect(X + (I - 1) * 16 + K * 2, Y + R * 2, X + (I - 1) * 16 + K * 2 + 1, Y + R * 2 + 1, C);
        End;
    End;
End;

{ ==================================================================== }
{ Plateau de bois et pieces                                             }
{ ==================================================================== }

{ point (colonne C, rangee R) du plateau a l'ecran (plateau retourne si
  l'on joue les noirs) }
Function PtX(Sq : LongInt) : LongInt;
Var C : LongInt;
Begin
  C := Sq Mod NC;
  If Flip <> 0 Then C := NC - 1 - C;
  PtX := GX + C * Sp;
End;

Function PtY(Sq : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := Sq Div NC;
  If Flip <> 0 Then R := NR - 1 - R;
  PtY := GY + R * Sp;
End;

Procedure BLine(C1, R1, C2, R2 : LongInt);
Begin
  TLine(GX + C1 * Sp, GY + R1 * Sp, GX + C2 * Sp, GY + R2 * Sp, 0, C_LINE);
End;

{ reperes en coin autour d'un point (canons et soldats) }
Procedure Marker(C, R : LongInt);
Var X, Y, Sx, Sy, K : LongInt;
Begin
  X := GX + C * Sp; Y := GY + R * Sp;
  For K := 0 To 3 Do
  Begin
    If Odd(K) Then Sx := 1 Else Sx := -1;
    If K < 2 Then Sy := -1 Else Sy := 1;
    If ((C > 0) Or (Sx > 0)) And ((C < NC - 1) Or (Sx < 0)) Then
    Begin
      Rect(MinI(X + Sx * 4, X + Sx * 10), Y + Sy * 4, MaxI(X + Sx * 4, X + Sx * 10), Y + Sy * 4, C_LINE);
      Rect(X + Sx * 4, MinI(Y + Sy * 4, Y + Sy * 10), X + Sx * 4, MaxI(Y + Sy * 4, Y + Sy * 10), C_LINE);
    End;
  End;
End;

{ ideogramme de la riviere (26 x 26) centre en (Cx, Cy) }
Procedure RiverGlyph(N, Cx, Cy : LongInt);
Var X, Y, V : LongInt; S : String;
Begin
  For Y := 0 To 25 Do
  Begin
    S := RivS[N * 26 + Y];
    For X := 0 To 25 Do
    Begin
      V := Pos(S[X + 1], '.+*#') - 1;
      If V >= 2 Then Pix(Cx - 13 + X, Cy - 13 + Y, C_RIVER)
      Else If V = 1 Then Pix(Cx - 13 + X, Cy - 13 + Y, C_WOOD + 8);
    End;
  End;
End;

Function Noise(N : LongInt) : LongInt;
Begin
  N := (N * 1103515245 + 12345) And $7FFFFFFF;
  N := (N * 1103515245 + 12345) And $7FFFFFFF;
  Noise := (N Shr 12) And 255;
End;

Procedure RenderBack;
Var X, Y, V, W, K, R, C, Ry : LongInt;
Begin
  { bois veine : fil horizontal ondule, plus clair au centre }
  For Y := 0 To BH - 1 Do
    For X := 0 To BW - 1 Do
    Begin
      W := Y * 4 + (Noise(X Div 23 + 7) And 15) + (Noise(X Div 9 + 100) And 3);
      V := 22 - AbsI(Y - BH Div 2) Div 30 - AbsI(X - BW Div 2) Div 40;
      K := W Mod 37;
      If K < 3 Then V := V - 6 + K
      Else If K < 9 Then V := V - 2;
      If (Noise(X * 3 + Y * 997) And 15) = 0 Then V := V - 1;
      If V < 0 Then V := 0;
      If V > 31 Then V := 31;
      Fb[(BH - 1 - Y) * BW + X] := C_WOOD + V;
    End;
  { cadre exterieur double }
  R := GX - 9;
  Rect(R, R, BW - 1 - R, R + 2, C_LINE); Rect(R, BH - 1 - R - 2, BW - 1 - R, BH - 1 - R, C_LINE);
  Rect(R, R, R + 2, BH - 1 - R, C_LINE); Rect(BW - 1 - R - 2, R, BW - 1 - R, BH - 1 - R, C_LINE);
  { grille : bord epais, rangees, colonnes coupees par la riviere }
  Rect(GX - 1, GY - 1, GX + 8 * Sp + 1, GY, C_LINE); Rect(GX - 1, GY + 9 * Sp, GX + 8 * Sp + 1, GY + 9 * Sp + 1, C_LINE);
  Rect(GX - 1, GY - 1, GX, GY + 9 * Sp + 1, C_LINE); Rect(GX + 8 * Sp, GY - 1, GX + 8 * Sp + 1, GY + 9 * Sp + 1, C_LINE);
  For R := 1 To NR - 2 Do BLine(0, R, 8, R);
  For C := 1 To NC - 2 Do
  Begin
    BLine(C, 0, C, 4);
    BLine(C, 5, C, 9);
  End;
  { palais : diagonales }
  BLine(3, 0, 5, 2); BLine(5, 0, 3, 2); BLine(3, 7, 5, 9); BLine(5, 7, 3, 9);
  { reperes des canons et des soldats }
  Marker(1, 2); Marker(7, 2); Marker(1, 7); Marker(7, 7);
  For C := 0 To 4 Do
  Begin
    Marker(C * 2, 3); Marker(C * 2, 6);
  End;
  { riviere : Chu he (riviere de Chu) et Han jie (frontiere de Han) }
  Ry := GY + 4 * Sp + Sp Div 2;
  RiverGlyph(0, GX + Sp + Sp Div 2, Ry); RiverGlyph(1, GX + 2 * Sp + Sp Div 2, Ry);
  RiverGlyph(2, GX + 5 * Sp + Sp Div 2, Ry); RiverGlyph(3, GX + 6 * Sp + Sp Div 2, Ry);
  Move(Fb, Back, SizeOf(Fb));
End;

{ pieces : disque d'ivoire en relief, bord sombre, anneau et ideogramme
  graves (rouge ou noir), ombre portee ; T_NONE : transparent }
Procedure MakeSprites;
Var K, T, S, X, Y, Dx, Dy, D2, D, L, V, Base, Gx0, Gy0, G, Ink : LongInt; Ln : String;
Begin
  For K := 0 To 13 Do
  Begin
    T := K Mod 7 + 1; S := K Div 7;
    Base := K * PS * PS;
    If S = 0 Then Ink := C_INKR Else Ink := C_INKB;
    For Y := 0 To PS - 1 Do
      For X := 0 To PS - 1 Do
      Begin
        Dx := X - 19; Dy := Y - 19;
        D2 := Dx * Dx + Dy * Dy;
        If D2 <= PR * PR + PR Then
        Begin
          D := Round(Sqrt(D2));
          If D >= PR Then V := C_EDGE
          Else If D >= PR - 3 Then
          Begin
            { biseau : clair en haut a gauche, sombre en bas a droite }
            L := 8 + ((-Dx - Dy) * 8) Div (PR + 1);
            If L < 0 Then L := 0;
            If L > 15 Then L := 15;
            V := C_IVORY + L;
          End
          Else
          Begin
            L := 10 + (-Dx - Dy) Div 14;
            If L > 12 Then L := 12;
            V := C_IVORY + L;
            { anneau grave }
            If D = 13 Then V := Ink + 2
            Else If (D = 14) And (Dx + Dy > 0) Then V := C_IVORY + 15
            Else If (D = 12) And (Dx + Dy < 0) Then V := C_IVORY + 6;
          End;
        End
        Else If (X - 21) * (X - 21) + (Y - 22) * (Y - 22) <= PR * PR + PR Then V := T_SHADE
        Else V := T_NONE;
        Spr[Base + Y * PS + X] := V;
      End;
    { ideogramme 18 x 18 grave : reflet clair en bas a droite, encre }
    Gx0 := 10; Gy0 := 10;
    For Y := 0 To 17 Do
    Begin
      Ln := GlyphS[K * 18 + Y];
      For X := 0 To 17 Do
      Begin
        G := Pos(Ln[X + 1], '.+*#') - 1;
        If G >= 2 Then
          If (X < 17) And (Y < 17) Then
            If Pos(GlyphS[K * 18 + Y + 1][X + 2], '*#') = 0 Then
              Spr[Base + (Gy0 + Y + 1) * PS + Gx0 + X + 1] := C_IVORY + 14;
      End;
    End;
    For Y := 0 To 17 Do
    Begin
      Ln := GlyphS[K * 18 + Y];
      For X := 0 To 17 Do
      Begin
        G := Pos(Ln[X + 1], '.+*#') - 1;
        If G > 0 Then Spr[Base + (Gy0 + Y) * PS + Gx0 + X] := Ink + G - 1;
      End;
    End;
  End;
End;

{ piece P centree en (Cx, Cy) ; Lift : soulevee (ombre plus loin) }
Procedure DrawPiece(Cx, Cy, P, Lift : LongInt);
Var K, X, Y, V, A, Src, X0, Y0 : LongInt;
Begin
  If P = 0 Then Exit;
  If P > 0 Then K := P - 1 Else K := -P - 1 + 7;
  Src := K * PS * PS;
  If Lift <> 0 Then
  Begin
    ShadeDisc(Cx + 3, Cy + 4, PR);
    Cx := Cx - 1; Cy := Cy - 3;
  End;
  X0 := Cx - 19; Y0 := Cy - 19;
  For Y := 0 To PS - 1 Do
    If (Y0 + Y >= 0) And (Y0 + Y < BH) Then
      For X := 0 To PS - 1 Do
      Begin
        V := Spr[Src + Y * PS + X];
        If (V <> T_NONE) And (X0 + X >= 0) And (X0 + X < BW) Then
        Begin
          A := (BH - 1 - (Y0 + Y)) * BW + X0 + X;
          If V = T_SHADE Then
          Begin
            If Lift = 0 Then Fb[A] := Shade[Fb[A]];
          End
          Else Fb[A] := V;
        End;
      End;
End;

{ coins d'un carre de demi-cote H autour d'un point }
Procedure Corners(Cx, Cy, H, L, C : LongInt);
Var K, Sx, Sy : LongInt;
Begin
  For K := 0 To 3 Do
  Begin
    If Odd(K) Then Sx := 1 Else Sx := -1;
    If K < 2 Then Sy := -1 Else Sy := 1;
    Rect(MinI(Cx + Sx * H, Cx + Sx * (H - L)), MinI(Cy + Sy * H, Cy + Sy * (H - 1)),
         MaxI(Cx + Sx * H, Cx + Sx * (H - L)), MaxI(Cy + Sy * H, Cy + Sy * (H - 1)), C);
    Rect(MinI(Cx + Sx * H, Cx + Sx * (H - 1)), MinI(Cy + Sy * H, Cy + Sy * (H - L)),
         MaxI(Cx + Sx * H, Cx + Sx * (H - 1)), MaxI(Cy + Sy * H, Cy + Sy * (H - L)), C);
  End;
End;

Procedure Touch(X1, Y1, X2, Y2 : LongInt);
Begin
  If DX2 < DX1 Then
  Begin
    DX1 := X1; DY1 := Y1; DX2 := X2; DY2 := Y2;
  End
  Else
  Begin
    DX1 := MinI(DX1, X1); DY1 := MinI(DY1, Y1); DX2 := MaxI(DX2, X2); DY2 := MaxI(DY2, Y2);
  End;
End;

Procedure TouchSq(Sq : LongInt);
Begin
  If Sq < 0 Then Exit;
  Touch(PtX(Sq) - 24, PtY(Sq) - 24, PtX(Sq) + 24, PtY(Sq) + 24);
End;

Procedure DrawBanner;
Var W, X, Y, H : LongInt;
Begin
  If Banner = '' Then Exit;
  W := MaxI(Length(Banner) * 16, MaxI(Length(Banner2), Length(Banner3)) * 8) + 32;
  If W > BW - 16 Then W := BW - 16;
  H := 96; X := (BW - W) Div 2; Y := 150;
  Rect(X + 5, Y + 5, X + W + 4, Y + H + 4, C_SHADOW);
  Rect(X, Y, X + W - 1, Y + H - 1, C_BANNER);
  Rect(X, Y, X + W - 1, Y + 1, C_BANNERE); Rect(X, Y + H - 2, X + W - 1, Y + H - 1, C_BANNERE);
  Rect(X, Y, X + 1, Y + H - 1, C_BANNERE); Rect(X + W - 2, Y, X + W - 1, Y + H - 1, C_BANNERE);
  FbText((BW - Length(Banner) * 16) Div 2, Y + 12, Banner, C_YELLOW, 2);
  FbText((BW - Length(Banner2) * 8) Div 2, Y + 50, Banner2, C_WHITE, 1);
  FbText((BW - Length(Banner3) * 8) Div 2, Y + 70, Banner3, C_GREEN, 1);
End;

{ l'image entiere : plateau, marques, pieces, piece qui glisse }
Procedure Render;
Var Sq, X, Y, P, K, T, Ck : LongInt;
Begin
  Move(Back, Fb, SizeOf(Fb));
  { dernier coup }
  If LastF >= 0 Then
  Begin
    Corners(PtX(LastF), PtY(LastF), 20, 6, C_LAST);
    Corners(PtX(LastT), PtY(LastT), 20, 6, C_LAST);
  End;
  { General en echec }
  Ck := -1;
  If (Over = O_PLAY) And (AnOn = 0) Then
    If InCheck(Side) Then Ck := KingSq(Side);
  For Sq := 0 To NSq - 1 Do
  Begin
    P := Bd[Sq];
    If (AnOn <> 0) And (Sq = AnT) Then P := AnCap;
    If (P <> 0) And (Sq <> SelSq) Then
    Begin
      If Sq = Ck Then Ring(PtX(Sq), PtY(Sq), 19, 21, C_CHECK);
      DrawPiece(PtX(Sq), PtY(Sq), P, 0);
    End;
  End;
  { coups possibles de la piece choisie }
  If (SelSq >= 0) And (ShowMv <> 0) Then
    For K := 0 To NLeg - 1 Do
      If MvFrom(LegL[K]) = SelSq Then
      Begin
        T := MvTo(LegL[K]);
        X := PtX(T); Y := PtY(T);
        If Bd[T] <> 0 Then Ring(X, Y, 19, 21, C_DOT)
        Else
        Begin
          Disc(X, Y, 6, C_DOTE);
          Disc(X, Y, 5, C_DOT);
        End;
      End;
  { indice }
  If HintF >= 0 Then
  Begin
    Ring(PtX(HintF), PtY(HintF), 19, 21, C_HINT);
    Ring(PtX(HintT), PtY(HintT), 19, 21, C_HINT);
  End;
  { piece soulevee }
  If SelSq >= 0 Then
  Begin
    DrawPiece(PtX(SelSq), PtY(SelSq), Bd[SelSq], 1);
    Ring(PtX(SelSq) - 1, PtY(SelSq) - 3, 19, 20, C_SEL);
  End;
  { curseur du clavier }
  If (KbdUsed <> 0) And (Over = O_PLAY) Then Corners(PtX(CurSq), PtY(CurSq), 22, 8, C_CURSOR);
  { piece qui glisse }
  If AnOn <> 0 Then
  Begin
    X := PtX(AnF) + (PtX(AnT) - PtX(AnF)) * AnK Div AnN;
    Y := PtY(AnF) + (PtY(AnT) - PtY(AnF)) * AnK Div AnN;
    DrawPiece(X, Y, AnP, 1);
  End;
  DrawBanner;
End;

Procedure BlitRect(H, X1, Y1, X2, Y2 : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  P[0] := OX + X1; P[1] := CH - OY - 1 - Y2; P[2] := OX + X2 + 1; P[3] := CH - OY - Y1;
  P[4] := X1; P[5] := BH - 1 - Y2; P[6] := X2 + 1; P[7] := BH - Y1;
  Dummy := GpiDrawBits(H, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

Function SideName(S : LongInt) : String;
Begin
  If S > 0 Then SideName := 'Rouge' Else SideName := 'Noir';
End;

Function Who(S : LongInt) : String;
Begin
  If (AutoAll <> 0) Or (CompSide = S) Then Who := ' (ordinateur)'
  Else If CompSide = 0 Then Who := ''
  Else Who := ' (vous)';
End;

Function Captured(S : LongInt) : LongInt;
Var K, N : LongInt;
Begin
  { pieces du camp S encore sur le plateau : 16 au depart }
  N := 0;
  For K := 0 To NSq - 1 Do
    If Bd[K] * S > 0 Then Inc(N);
  Captured := 16 - N;
End;

{ trait, prises et liste des coups }
Procedure DrawInfo;
Var S : String; I, First, Y, N : LongInt;
Begin
  FBar(PnX, 54, PnX + PW - 1, 94, CLR_PALEGRAY);
  If Over = O_PLAY Then
  Begin
    If Side > 0 Then FBar(PnX, 57, PnX + 11, 68, CLR_DARKRED) Else FBar(PnX, 57, PnX + 11, 68, CLR_BLACK);
    Edge(PnX, 57, PnX + 11, 68, CLR_WHITE, CLR_DARKGRAY);
    OutTxt(PnX + 18, 54, 'Trait : ' + SideName(Side) + Who(Side), CLR_BLACK, CLR_PALEGRAY);
  End
  Else OutTxt(PnX, 54, 'Partie termin' + Chr(130) + 'e', CLR_DARKRED, CLR_PALEGRAY);
  OutTxt(PnX, 76, 'Prises : rouge ' + IStr(Captured(-1)) + ', noir ' + IStr(Captured(1)), CLR_DARKGRAY,
         CLR_PALEGRAY);
  { liste des coups (9 dernieres lignes) }
  FBar(PnX + 2, 104, PnX + PW - 3, 278, CLR_WHITE);
  N := (NHist + 1) Div 2;
  First := MaxI(0, N - 9);
  Y := 108;
  For I := First To N - 1 Do
  Begin
    S := IStr(I + 1) + '.';
    While Length(S) < 4 Do S := ' ' + S;
    OutTxt(PnX + 4, Y, S, CLR_DARKGRAY, CLR_WHITE);
    OutTxt(PnX + 40, Y, HTxt[I * 2], CLR_DARKRED, CLR_WHITE);
    If I * 2 + 1 < NHist Then OutTxt(PnX + 136, Y, HTxt[I * 2 + 1], CLR_BLACK, CLR_WHITE);
    Y := Y + 18;
  End;
  If NHist = 0 Then OutTxt(PnX + 8, 108, 'Le rouge commence.', CLR_DARKGRAY, CLR_WHITE);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 7 * 16) Div 2, 2, 'Xiangqi', CLR_DARKRED, CLR_PALEGRAY);
  OutTxt(PnX + (PW - 14 * 8) Div 2, 34, Chr(144) + 'checs chinois', CLR_DARKGRAY, CLR_PALEGRAY);
  Edge(PnX, 102, PnX + PW - 1, 280, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, 103, PnX + PW - 2, 279, CLR_BLACK, CLR_PALEGRAY);
  DrawInfo;
  Button(PnX, 290, PW, 26, 'Nouvelle partie');
  Button(PnX, 322, (PW - 6) Div 2, 26, 'Annuler');
  Button(PnX + (PW + 6) Div 2, 322, (PW - 6) Div 2, 26, 'Indice');
  OutTxt(PnX, 356, 'Clic : choisir puis jouer', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 372, 'Fl' + Chr(138) + 'ches, Espace, Echap', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 388, 'U annuler  I indice  F1', CLR_DARKGRAY, CLR_PALEGRAY);
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Function Sig : LongInt;
Begin
  Sig := NHist * 7 + Side * 131 + Over * 1009 + CompSide * 10007 + AutoAll * 77 + Captured(1) * 3 +
         Captured(-1) * 5;
End;

Procedure PaintAll(H : LongInt);
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, OX - 3, CH - 1, CLR_PALEGRAY);
  FBar(OX + BW + 2, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  FBar(0, 0, CW - 1, OY - 3, CLR_PALEGRAY);
  FBar(0, OY + BH + 2, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(OX - 2, OY - 2, OX + BW + 1, OY + BH + 1, CLR_DARKGRAY, CLR_WHITE);
  Edge(OX - 1, OY - 1, OX + BW, OY + BH, CLR_BLACK, CLR_PALEGRAY);
  Render;
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1; FullBlit := 0;
  DrawPanel;
  DrawStatus;
  LastMsg := Msg; LastSig := Sig;
  Dummy := WinEndPaint(Hps);
End;

{ recopie des zones changees (hors de WM_PAINT) }
Procedure Frame1;
Begin
  If (Client = 0) Or (TestMode <> 0) Then Exit;
  If (FullBlit = 0) And (DX2 < DX1) And (Sig = LastSig) And (Msg = LastMsg) Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  If (FullBlit <> 0) Or (DX2 >= DX1) Then Render;
  If FullBlit <> 0 Then BlitRect(Hps, 0, 0, BW - 1, BH - 1)
  Else If DX2 >= DX1 Then BlitRect(Hps, DX1, DY1, DX2, DY2);
  FullBlit := 0;
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1;
  If Sig <> LastSig Then
  Begin
    LastSig := Sig;
    DrawInfo;
  End;
  If Msg <> LastMsg Then
  Begin
    LastMsg := Msg;
    DrawStatus;
  End;
  Dummy := WinReleasePS(Hps);
End;

{ ==================================================================== }
{ Bruitages                                                             }
{ ==================================================================== }

Procedure MakeTone(N, F1, F2, Ms, Vol : LongInt);
Var K, Len, F, Ph, V, Env : LongInt;
Begin
  Len := SndRate * Ms Div 1000;
  If NSndBuf + Len > SizeOf(SndBuf) Then Exit;
  SndOfs[N] := NSndBuf; SndLen[N] := Len; SndPri[N] := SndPrio;
  Ph := 0;
  For K := 0 To Len - 1 Do
  Begin
    F := F1 + (F2 - F1) * K Div Len;
    Ph := (Ph + F * 65536 Div SndRate) And $FFFF;
    If K < 40 Then Env := K * 255 Div 40 Else Env := 255 * (Len - K) Div (Len - 40 + 1);
    If Ph < 32768 Then V := Vol Else V := -Vol;
    If (Ph < 2048) Or ((Ph >= 32768) And (Ph < 34816)) Then V := V Div 2;
    SndBuf[NSndBuf + K] := 128 + V * Env Div 255;
  End;
  NSndBuf := NSndBuf + Len;
End;

{ claquement de bois : bruit tres court qui s'eteint vite }
Procedure MakeClack(N, Ms, Vol, Hold : LongInt);
Var K, Len, V, Env, R, H : LongInt;
Begin
  Len := SndRate * Ms Div 1000;
  If NSndBuf + Len > SizeOf(SndBuf) Then Exit;
  SndOfs[N] := NSndBuf; SndLen[N] := Len; SndPri[N] := SndPrio;
  R := 4321; V := 0; H := 0;
  For K := 0 To Len - 1 Do
  Begin
    If H <= 0 Then
    Begin
      R := (R * 1103515245 + 12345) And $7FFFFFFF;
      V := ((R Shr 16) And 255) - 128;
      H := Hold;
    End;
    Dec(H);
    If K < 8 Then Env := K * 255 Div 8 Else Env := 255 * (Len - K) Div (Len - 8 + 1);
    Env := Env * Env Div 255 * Env Div 255;
    SndBuf[NSndBuf + K] := 128 + V * Vol Div 128 * Env Div 255;
  End;
  NSndBuf := NSndBuf + Len;
End;

Function SndNow : LongInt;
Var T : Array[0..15] Of Byte;
Begin
  Dummy := DosGetDateTime(LongInt(@T));
  SndNow := ((T[0] * 60 + T[1]) * 60 + T[2]) * 1000 + T[3] * 10;
End;

Procedure PlaySnd(N : LongInt);
Var T : LongInt;
Begin
  If (SoundOn = 0) Or (TestMode <> 0) Or (SndLen[N] = 0) Then Exit;
  T := SndNow;
  If (SndPri[N] < SndCur) And (T < SndEnd) And (T >= SndEnd - 60000) Then Exit;
  SndCur := SndPri[N];
  SndEnd := T + SndLen[N] * 1000 Div SndRate;
  Dummy := MdmPlay(LongInt(@SndBuf[SndOfs[N]]), SndLen[N], SndRate, 8, 1);
End;

Procedure MakeSounds;
Begin
  NSndBuf := 0;
  SndPrio := 0; MakeClack(0, 45, 60, 2);                  { piece posee }
  SndPrio := 1; MakeClack(1, 90, 80, 5);                  { prise }
  SndPrio := 2; MakeTone(2, 880, 1320, 220, 40);          { echec }
  SndPrio := 3; MakeTone(3, 520, 1560, 700, 50);          { partie gagnee }
  SndPrio := 3; MakeTone(4, 420, 140, 700, 45);           { partie perdue }
  SndPrio := 1; MakeTone(5, 300, 260, 90, 30);            { coup refuse }
  SndPrio := 0; MakeTone(6, 1400, 1700, 25, 25);          { piece soulevee }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Deroulement de la partie                                              }
{ ==================================================================== }

Procedure TurnMsg;
Begin
  If Over <> O_PLAY Then Exit;
  If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur joue les deux camps (Options).'
  Else If (CompSide = 0) Then Msg := 'Partie ' + Chr(133) + ' deux : au ' + SideName(Side) + ' de jouer.'
  Else If Side = CompSide Then Msg := 'L''ordinateur r' + Chr(130) + 'fl' + Chr(130) + 'chit...'
  Else Msg := 'A vous : cliquez une pi' + Chr(138) + 'ce ' + SideName(Side) + ', puis son point d''arriv' +
              Chr(130) + 'e.';
  If InCheck(Side) Then Msg := Chr(144) + 'chec au G' + Chr(130) + 'n' + Chr(130) + 'ral ' +
                               SideName(Side) + ' ! ' + Msg;
End;

Procedure EndGame(Res, Why : LongInt);
Var Human : LongInt;
Begin
  Over := Res; OverWhy := Why;
  SelSq := -1; HintF := -1;
  Wait := 0;
  If Res = O_DRAW Then
  Begin
    Banner := 'Partie nulle';
    Case Why Of
      1 : Banner2 := 'Position r' + Chr(130) + 'p' + Chr(130) + 't' + Chr(130) + 'e trois fois';
      2 : Banner2 := '60 coups de chaque camp sans prise';
    Else
      Banner2 := 'Plus aucune pi' + Chr(138) + 'ce d''attaque';
    End;
  End
  Else
  Begin
    If Res = O_REDWIN Then Banner := 'Le rouge gagne' Else Banner := 'Le noir gagne';
    If Why = 0 Then Banner2 := Chr(144) + 'chec et mat'
    Else Banner2 := 'Pat : le camp qui ne peut plus jouer perd';
  End;
  Banner3 := 'F2 ou clic : nouvelle partie';
  Msg := Banner + ' (' + Banner2 + ').';
  If (CompSide <> 0) And (AutoAll = 0) Then
  Begin
    Inc(Games);
    Human := -CompSide;
    If ((Res = O_REDWIN) And (Human > 0)) Or ((Res = O_BLACKWIN) And (Human < 0)) Then
    Begin
      Inc(Wins);
      PlaySnd(3);
    End
    Else If Res <> O_DRAW Then
    Begin
      Inc(Losses);
      PlaySnd(4);
    End;
  End
  Else PlaySnd(3);
  FullBlit := 1;
End;

{ apres un coup : fin de partie ? }
Procedure CheckEnd;
Begin
  Ply := 0;
  If LegalMoves = 0 Then
  Begin
    If Side > 0 Then EndGame(O_BLACKWIN, Ord(Not InCheck(Side)))
    Else EndGame(O_REDWIN, Ord(Not InCheck(Side)));
  End
  Else If Repeats >= 2 Then EndGame(O_DRAW, 1)
  Else If NoCap >= 120 Then EndGame(O_DRAW, 2)
  Else If NoAttackers Then EndGame(O_DRAW, 3);
End;

{ joue le coup M (legal) ; Anim : la piece glisse }
Procedure PlayMove(M : LongInt; Anim : Boolean);
Var F, T, Cap : LongInt;
Begin
  F := MvFrom(M); T := MvTo(M);
  If NHist > MaxHist - 1 Then Exit;
  HTxt[NHist] := MoveText(M, Side);
  HKey[NHist] := PosKey;
  HNoCap[NHist] := NoCap;
  Cap := Bd[T];
  HMv[NHist] := M; HCap[NHist] := Cap;
  Inc(NHist);
  If Cap <> 0 Then NoCap := 0 Else Inc(NoCap);
  Ply := 0;
  If Anim And (TestMode = 0) And (Client <> 0) Then
  Begin
    AnOn := 1; AnF := F; AnT := T; AnP := Bd[F]; AnCap := Cap; AnK := 0;
    AnN := MaxI(5, MinI(12, (AbsI(PtX(T) - PtX(F)) + AbsI(PtY(T) - PtY(F))) Div 14));
  End;
  DoMv(M);
  Ply := 0;
  LastF := F; LastT := T;
  SelSq := -1; HintF := -1; HintT := -1;
  Wait := 0;
  If AnOn = 0 Then
  Begin
    If Cap <> 0 Then PlaySnd(1) Else PlaySnd(0);
  End;
  CheckEnd;
  If Over = O_PLAY Then
  Begin
    TurnMsg;
    If (AnOn = 0) And InCheck(Side) Then PlaySnd(2);
  End;
  FullBlit := 1;
End;

Procedure NewGame;
Begin
  SetupBoard;
  NHist := 0; Over := O_PLAY; NoCap := 0;
  SelSq := -1; HintF := -1; HintT := -1; LastF := -1; LastT := -1; AnOn := 0; Wait := 0;
  Banner := ''; Banner2 := ''; Banner3 := '';
  If CompSide > 0 Then Flip := 1 Else Flip := 0;
  If Flip <> 0 Then CurSq := SqOf(0, 4) Else CurSq := SqOf(9, 4);
  Ply := 0;
  Dummy := LegalMoves;
  TurnMsg;
  FullBlit := 1;
End;

Function HumanTurn : Boolean;
Begin
  HumanTurn := (Over = O_PLAY) And (AutoAll = 0) And (AnOn = 0) And ((CompSide = 0) Or (Side <> CompSide));
End;

Procedure ComputerMove;
Var M, L : LongInt;
Begin
  Ply := 0;
  L := Level;
  If AutoAll <> 0 Then L := 2;
  M := LevelMove(L);
  Ply := 0;
  If M <> 0 Then PlayMove(M, True);
End;

Procedure UndoOne;
Var M : LongInt;
Begin
  If NHist = 0 Then Exit;
  Dec(NHist);
  M := HMv[NHist];
  Ply := 1;
  CapS[0] := HCap[NHist];
  UndoMv(M);
  Ply := 0;
  NoCap := HNoCap[NHist];
End;

Procedure UndoMove;
Begin
  If (AutoAll <> 0) Or (AnOn <> 0) Or (NHist = 0) Then Exit;
  If (CompSide <> 0) And (Over = O_PLAY) And (Side = CompSide) Then Exit;
  UndoOne;
  { contre l'ordinateur : son coup et le votre }
  If (CompSide <> 0) And (Side = CompSide) And (NHist > 0) Then UndoOne;
  If (CompSide <> 0) And (Side = CompSide) Then
  Begin
    { l'ordinateur avait le premier coup : il le rejoue }
  End;
  Over := O_PLAY; Banner := ''; Banner2 := ''; Banner3 := '';
  SelSq := -1; HintF := -1; LastF := -1; LastT := -1;
  If NHist > 0 Then
  Begin
    LastF := MvFrom(HMv[NHist - 1]); LastT := MvTo(HMv[NHist - 1]);
  End;
  Ply := 0;
  Dummy := LegalMoves;
  TurnMsg;
  Msg := 'Coup annul' + Chr(130) + '. ' + Msg;
  PlaySnd(5);
  FullBlit := 1;
End;

Procedure Hint;
Var M : LongInt;
Begin
  If Not HumanTurn Then Exit;
  Msg := 'Recherche d''un indice...';
  Frame1;
  Ply := 0;
  M := BestMove(3, 12000, 0);
  Ply := 0;
  Dummy := LegalMoves;
  If M = 0 Then Exit;
  HintF := MvFrom(M); HintT := MvTo(M);
  SelSq := -1;
  Msg := 'Indice : ' + MoveText(M, Side) + ' (' + PieceName(AbsI(Bd[HintF])) + ', anneaux jaunes).';
  FullBlit := 1;
End;

{ clic ou touche sur le point Sq }
Procedure Activate(Sq : LongInt);
Var P, N, K, Pseudo : LongInt;
Begin
  If Over <> O_PLAY Then
  Begin
    NewGame;
    Exit;
  End;
  If Not HumanTurn Then Exit;
  If (Sq < 0) Or (Sq >= NSq) Then Exit;
  P := Bd[Sq];
  If P * Side > 0 Then
  Begin
    If SelSq = Sq Then SelSq := -1
    Else
    Begin
      SelSq := Sq;
      PlaySnd(6);
      Msg := PieceName(AbsI(P)) + ' ' + SideName(Side) + ' choisi : cliquez son point d''arriv' + Chr(130) + 'e.';
    End;
    HintF := -1;
    FullBlit := 1;
    Exit;
  End;
  If SelSq < 0 Then
  Begin
    If P <> 0 Then Msg := 'Cette pi' + Chr(138) + 'ce est ' + Chr(133) + ' l''adversaire.'
    Else Msg := 'Choisissez d''abord une de vos pi' + Chr(138) + 'ces.';
    Exit;
  End;
  If IsLegal(SelSq, Sq) Then PlayMove(SelSq + Sq * 128, True)
  Else
  Begin
    PlaySnd(5);
    Ply := 0;
    N := GenMoves(False);
    Pseudo := 0;
    For K := 0 To N - 1 Do
      If MvList[K] = SelSq + Sq * 128 Then Pseudo := 1;
    If Pseudo <> 0 Then
      Msg := 'Coup interdit : votre G' + Chr(130) + 'n' + Chr(130) + 'ral serait en prise (ou face ' + Chr(133) +
             ' l''autre).'
    Else
      Msg := 'Le ' + PieceName(AbsI(Bd[SelSq])) + ' ne peut pas aller l' + Chr(133) + '.';
  End;
End;

Procedure TimerTick;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  If AnOn <> 0 Then
  Begin
    Inc(AnK);
    If AnK >= AnN Then
    Begin
      AnOn := 0;
      If AnCap <> 0 Then PlaySnd(1) Else PlaySnd(0);
      If (Over = O_PLAY) And InCheck(Side) Then PlaySnd(2);
      FullBlit := 1;
    End
    Else Touch(0, 0, BW - 1, BH - 1);
  End
  Else If (Over = O_PLAY) And ((AutoAll <> 0) Or ((CompSide <> 0) And (Side = CompSide))) Then
  Begin
    Inc(Wait);
    If Wait = 2 Then
    Begin
      Msg := 'L''ordinateur r' + Chr(130) + 'fl' + Chr(130) + 'chit...';
      Frame1;
    End;
    If Wait > 6 Then
    Begin
      Wait := 0;
      ComputerMove;
    End;
  End
  Else If (Over <> O_PLAY) And (AutoAll <> 0) Then
  Begin
    Inc(Wait);
    If Wait > 125 Then NewGame;
  End;
  Frame1;
End;

Procedure SetMark(Id : LongInt; On : Boolean);
Var M : LongInt;
Begin
  M := WinWindowFromID(Frame, $8005);
  If M = 0 Then Exit;
  If On Then Dummy := WinSendMsg(M, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16))
  Else Dummy := WinSendMsg(M, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED);
End;

Procedure SetMarks;
Begin
  SetMark(CM_LEVEL1, Level = 1); SetMark(CM_LEVEL2, Level = 2); SetMark(CM_LEVEL3, Level = 3);
  SetMark(CM_BLACK, CompSide = 1); SetMark(CM_TWO, CompSide = 0); SetMark(CM_SHOW, ShowMv <> 0);
  SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0);
End;

Procedure ShowRules;
Begin
  LClr;
  LAdd('Le Xiangqi se joue sur les intersections d''un plateau de 9 colonnes et 10 rang' + Chr(130) + 'es, coup' +
       Chr(130) + ' en deux par la rivi' + Chr(138) + 're. Le rouge commence. On gagne en mettant le G' + Chr(130) +
       'n' + Chr(130) + 'ral adverse ' + Chr(130) + 'chec et mat ; le camp qui ne peut plus jouer perd aussi (pat).' +
       Chr(10) + Chr(10));
  LAdd('G' + Chr(130) + 'n' + Chr(130) + 'ral (' + 'Shuai, Jiang) : un pas en ligne, sans sortir du palais. ' +
       'Les deux G' + Chr(130) + 'n' + Chr(130) + 'raux ne doivent jamais se faire face sur une colonne vide. ' +
       'Conseiller : un pas en diagonale, dans le palais. ' + Chr(144) + 'l' + Chr(130) + 'phant : deux pas en ' +
       'diagonale, sans traverser la rivi' + Chr(138) + 're, bloqu' + Chr(130) + ' si le point du milieu est occup' +
       Chr(130) + '. ' + Chr(10));
  LAdd('Cheval : un pas en ligne puis un en diagonale, bloqu' + Chr(130) + ' si le premier point est occup' +
       Chr(130) + '. Char : en ligne, aussi loin que libre. Canon : se d' + Chr(130) + 'place comme le char, ' +
       'mais prend en sautant par-dessus exactement une pi' + Chr(138) + 'ce. Soldat : un pas en avant ; ' +
       'apr' + Chr(138) + 's la rivi' + Chr(138) + 're, aussi un pas de c' + Chr(147) + 't' + Chr(130) + '.' +
       Chr(10) + Chr(10));
  LAdd('Nulle : position r' + Chr(130) + 'p' + Chr(130) + 't' + Chr(130) + 'e trois fois, 60 coups de chaque ' +
       'camp sans prise, ou plus aucune pi' + Chr(138) + 'ce d''attaque.' + Chr(10));
  LAdd('Notation : pi' + Chr(138) + 'ce, colonne (1 ' + Chr(133) + ' 9 depuis la droite du joueur), + avance, - ' +
       'recule, . de c' + Chr(147) + 't' + Chr(130) + ', puis le nombre de rang' + Chr(130) + 'es ou la colonne ' +
       'd''arriv' + Chr(130) + 'e ; x : prise.' + Chr(10) + Chr(10));
  LAdd('Souris : cliquer une pi' + Chr(138) + 'ce puis son point d''arriv' + Chr(130) + 'e. Clavier : fl' +
       Chr(138) + 'ches, Espace ou Entr' + Chr(130) + 'e, Echap, U (annuler), I (indice), F2 (nouvelle partie).');
  Dummy := LMsgBox('Xiangqi - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_UNDO : UndoMove;
    CM_HINT : Hint;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_LEVEL1, CM_LEVEL2, CM_LEVEL3 :
      Begin
        Level := Id - CM_LEVEL1 + 1; SetMarks;
        Case Level Of
          1 : Msg := 'Niveau d' + Chr(130) + 'butant.';
          2 : Msg := 'Niveau moyen.';
        Else
          Msg := 'Niveau expert.';
        End;
      End;
    CM_BLACK :
      Begin
        If CompSide = 1 Then CompSide := -1 Else CompSide := 1;
        SetMarks; NewGame;
      End;
    CM_TWO :
      Begin
        If CompSide = 0 Then CompSide := -1 Else CompSide := 0;
        SetMarks; NewGame;
      End;
    CM_SHOW : Begin ShowMv := 1 - ShowMv; SetMarks; FullBlit := 1; End;
    CM_AUTO : Begin AutoAll := 1 - AutoAll; SetMarks; Wait := 0; SelSq := -1; TurnMsg; FullBlit := 1; End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_RULES : ShowRules;
    CM_ABOUT : Dummy := Ask('Xiangqi (' + Chr(130) + 'checs chinois) pour OS/2-0 (Presentation Manager), port' +
                            Chr(130) + ' du prototype XIANGQI.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or
                            MB_INFORMATION);
  End;
  Frame1;
End;

Procedure MoveCur(Dx, Dy : LongInt);
Var R, C : LongInt;
Begin
  If Over <> O_PLAY Then Exit;
  KbdUsed := 1;
  If Flip <> 0 Then
  Begin
    Dx := -Dx; Dy := -Dy;
  End;
  R := CurSq Div NC; C := CurSq Mod NC;
  R := (R + Dy + NR) Mod NR; C := (C + Dx + NC) Mod NC;
  CurSq := SqOf(R, C);
  Touch(0, 0, BW - 1, BH - 1);
  Frame1;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And (KC_KEYUP Or KC_ALT)) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Fl And KC_CTRL) <> 0 Then
  Begin
    If (Ch = 26) Or (UpCase(Chr(Ch)) = 'Z') Then Command(CM_UNDO) Else KeyChar := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If Vk = VK_LEFT Then Begin MoveCur(-1, 0); Exit; End;
    If Vk = VK_RIGHT Then Begin MoveCur(1, 0); Exit; End;
    If Vk = VK_UP Then Begin MoveCur(0, -1); Exit; End;
    If Vk = VK_DOWN Then Begin MoveCur(0, 1); Exit; End;
    If Vk = VK_BACKSPACE Then Begin Command(CM_UNDO); Exit; End;
    If Vk = VK_ESC Then
    Begin
      SelSq := -1; HintF := -1; TurnMsg; FullBlit := 1; Frame1;
      Exit;
    End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then
    Begin
      KbdUsed := 1;
      Activate(CurSq);
      Frame1;
      Exit;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'U' : Command(CM_UNDO);
      'I' : Command(CM_HINT);
      ' ' : Begin KbdUsed := 1; Activate(CurSq); Frame1; End;
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, C, R, Dx, Dy : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 290) And (Y < 316) Then Command(CM_NEW)
    Else If (Y >= 322) And (Y < 348) Then
    Begin
      If X < PnX + PW Div 2 Then Command(CM_UNDO) Else Command(CM_HINT);
    End;
    Exit;
  End;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    X := X - OX - GX + Sp Div 2; Y := Y - OY - GY + Sp Div 2;
    If (X < 0) Or (Y < 0) Then Exit;
    C := X Div Sp; R := Y Div Sp;
    If (C >= NC) Or (R >= NR) Then Exit;
    Dx := X - C * Sp - Sp Div 2; Dy := Y - R * Sp - Sp Div 2;
    If Dx * Dx + Dy * Dy > (PR + 1) * (PR + 1) Then Exit;
    If Flip <> 0 Then
    Begin
      C := NC - 1 - C; R := NR - 1 - R;
    End;
    KbdUsed := 0;
    CurSq := SqOf(R, C);
    Activate(SqOf(R, C));
    Frame1;
  End;
End;

Function MainProc(H, Msg0, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  MainProc := 0;
  Case Msg0 Of
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
      If Not KeyChar(Mp1, Mp2) Then MainProc := WinDefWindowProc(H, Msg0, Mp1, Mp2) Else MainProc := 1;
    WM_CLOSE : Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    MainProc := WinDefWindowProc(H, Msg0, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Essais (/TEST)                                                        }
{ ==================================================================== }

{ nombre de positions a la profondeur D (coups legaux) }
Function Perft(D : LongInt) : LongInt;
Var N, K, B, T, M : LongInt;
Begin
  If D = 0 Then
  Begin
    Perft := 1;
    Exit;
  End;
  B := Ply * MaxMv;
  N := GenMoves(False);
  T := 0;
  For K := 0 To N - 1 Do
  Begin
    M := MvList[B + K];
    If TryMv(M) Then
    Begin
      T := T + Perft(D - 1);
      UndoMv(M);
    End;
  End;
  Perft := T;
End;

Procedure ClearBoard;
Var K : LongInt;
Begin
  For K := 0 To NSq - 1 Do Bd[K] := 0;
  Ply := 0;
End;

Function CountFrom(Sq : LongInt) : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  Dummy := LegalMoves;
  For K := 0 To NLeg - 1 Do
    If MvFrom(LegL[K]) = Sq Then Inc(N);
  CountFrom := N;
End;

Procedure RunTests;
Var Ok, N1, N2, N3, A, B, C, D, E, M, Moves, Caps, K : LongInt;
Begin
  Ok := 0;
  { 1 : coups legaux de la position de depart (44, 1920, 79666) }
  SetupBoard;
  N1 := Perft(1); N2 := Perft(2); N3 := Perft(3);
  Log('XIANGQI : TEST1 coups depuis le depart ' + IStr(N1) + ' / ' + IStr(N2) + ' / ' + IStr(N3));
  If (N1 = 44) And (N2 = 1920) And (N3 = 79666) Then Inc(Ok);
  { 2 : regles particulieres }
  ClearBoard;
  Side := 1;
  Bd[SqOf(9, 4)] := GEN; Bd[SqOf(0, 3)] := -GEN;
  Bd[SqOf(7, 2)] := HOR; Bd[SqOf(6, 2)] := SOL;            { jambe du cheval bloquee vers le haut }
  Bd[SqOf(9, 6)] := ELE; Bd[SqOf(8, 7)] := -SOL;           { oeil de l'elephant bouche }
  Bd[SqOf(5, 0)] := CAN; Bd[SqOf(3, 0)] := -SOL; Bd[SqOf(1, 0)] := -CHA;  { canon : ecran puis prise }
  Bd[SqOf(4, 8)] := SOL;                                   { soldat passe : 3 coups }
  A := CountFrom(SqOf(7, 2));                              { cheval : 6 (pas vers le haut) }
  B := CountFrom(SqOf(9, 6));                              { elephant : 1 }
  C := CountFrom(SqOf(5, 0));                              { canon : 13 deplacements + 1 prise }
  D := CountFrom(SqOf(4, 8));                              { soldat : 2 (avance, gauche) }
  E := CountFrom(SqOf(9, 4));                              { General : 2 (pas la colonne 3 : face a face) }
  Log('XIANGQI : TEST2 cheval ' + IStr(A) + ' elephant ' + IStr(B) + ' canon ' + IStr(C) + ' soldat ' + IStr(D) +
      ' general ' + IStr(E));
  If (A = 6) And (B = 1) And (C = 14) And (D = 2) And (E = 2) Then Inc(Ok);
  { 3 : mat par deux chars, et l'ordinateur trouve le mat en un coup }
  ClearBoard;
  Bd[SqOf(0, 4)] := -GEN; Bd[SqOf(9, 3)] := GEN; Bd[SqOf(1, 8)] := CHA; Bd[SqOf(5, 0)] := CHA;
  Side := 1;
  { le coup choisi doit laisser le noir sans coup legal (mat ou pat) }
  M := BestMove(2, 20000, 0);
  Ply := 0;
  DoMv(M);
  Ply := 0;
  A := Ord((M <> 0) And (LegalMoves = 0));
  ClearBoard;
  Bd[SqOf(0, 4)] := -GEN; Bd[SqOf(9, 3)] := GEN; Bd[SqOf(1, 8)] := CHA; Bd[SqOf(5, 0)] := CHA;
  Side := 1;
  DoMv(SqOf(5, 0) + SqOf(0, 0) * 128);
  Ply := 0;
  B := LegalMoves; C := Ord(InCheck(Side));
  { pat : le General noir ne peut plus bouger sans etre en echec }
  ClearBoard;
  Bd[SqOf(0, 3)] := -GEN; Bd[SqOf(9, 4)] := GEN; Bd[SqOf(2, 4)] := CHA; Bd[SqOf(1, 8)] := CHA;
  Side := -1;
  D := LegalMoves; E := Ord(InCheck(Side));
  Log('XIANGQI : TEST3 coup gagnant ' + IStr(A) + ' coups ' + IStr(B) + ' echec ' + IStr(C) + ' ; pat coups ' +
      IStr(D) + ' echec ' + IStr(E));
  If (A = 1) And (B = 0) And (C = 1) And (D = 0) And (E = 0) Then Inc(Ok);
  { partie : l'ordinateur joue les deux camps (graine fixe) }
  Seed := 2026; CompSide := 0; AutoAll := 0; Client := 0;
  NewGame;
  Moves := 0; Caps := 0;
  While (Over = O_PLAY) And (NHist < 300) Do
  Begin
    Ply := 0;
    If Side > 0 Then M := LevelMove(2) Else M := LevelMove(1);
    If M = 0 Then Break;
    If Bd[MvTo(M)] <> 0 Then Inc(Caps);
    PlayMove(M, False);
    Inc(Moves);
  End;
  K := 0;
  For A := 0 To NHist - 1 Do
    If HTxt[A] = '' Then Inc(K);
  Log('XIANGQI : PARTIE demi-coups ' + IStr(Moves) + ' prises ' + IStr(Caps) + ' resultat ' + IStr(Over) +
      ' raison ' + IStr(OverWhy));
  If (Over <> O_PLAY) And (K = 0) Then Inc(Ok);
  Log('XIANGQI : ' + IStr(Ok) + '/4 essais reussis');
End;

{ ==================================================================== }
{ Menus et programme principal                                          }
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

{ police 8 x 16 du VGA (VIOCALLS) }
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
  Flg, H0, H1, H2, H3, Sw, Sh, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  InDlg := 0;
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; LastMsg := ''; AutoAll := 0; Banner := ''; Banner2 := ''; Banner3 := ''; Tick := 0;
  Client := 0; Frame := 0; SoundOn := 1; ShowMv := 1; Level := 2; CompSide := -1; Flip := 0; SndCur := 0;
  SndEnd := 0; TestMode := 0; KbdUsed := 0; Games := 0; Wins := 0; Losses := 0; AnOn := 0;
  CW := CWant; CH := CHWant;
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1; FullBlit := 1;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If (Length(S) > 7) And (Copy(S, 1, 7) = '/LEVEL:') Then
    Begin
      Val(Copy(S, 8, 20), Level, E);
      If Level < 1 Then Level := 1;
      If Level > 3 Then Level := 3;
    End;
    If S = '/AUTO' Then AutoAll := 1;
    If S = '/NOSOUND' Then SoundOn := 0;
    If S = '/TEST' Then TestMode := 1;
  End;
  If TestMode <> 0 Then
  Begin
    RunTests;
    Halt(0);
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  InitBmi;
  RenderBack;
  MakeSprites;
  MakeSounds;
  Dummy := WinRegisterClass(Hab, Z('XIANGQI'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('XIANGQI'), Z2('Xiangqi'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler le coup' + Chr(9) + 'U');
  MItem(MIS_TEXT, 0, CM_HINT, '~Indice' + Chr(9) + 'I');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_LEVEL1, 'Niveau ~d' + Chr(130) + 'butant');
  MItem(MIS_TEXT, 0, CM_LEVEL2, 'Niveau ~moyen');
  MItem(MIS_TEXT, 0, CM_LEVEL3, 'Niveau ~expert');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_BLACK, 'Jouer les ~noirs');
  MItem(MIS_TEXT, 0, CM_TWO, 'Partie ' + Chr(133) + ' ~deux joueurs');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_SHOW, '~Coups possibles');
  MItem(MIS_TEXT, 0, CM_AUTO, 'D' + Chr(130) + 'mons~tration');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MenuClose(H3, 10);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Xiangqi');
  MenuClose(H2, 2);
  MenuClose(H0, 3);
  M := WinCreateMenu(Frame, LongInt(@MenuT));
  Rc[0] := 0; Rc[1] := 0; Rc[2] := CWant; Rc[3] := CHWant;
  Dummy := WinCalcFrameRect(Frame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  X := (Sw - Fw) Div 2; Y := (Sh - Fh) Div 2;
  If X < 0 Then X := 0;
  If Y < 0 Then Y := Sh - Fh;
  SetMarks;
  NewGame;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  Dummy := WinStartTimer(Hab, Client, 1, 40);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
