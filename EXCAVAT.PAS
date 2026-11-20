{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: EXCAVAT - Excavateur (jeu d'action : creuser des galeries)
                pour le Presentation Manager d'OS/2-0 (dossier Jeux du
                bureau).
}

Program EXCAVAT;

{$R-,S-,I-}

{ Compilation : OS2PC EXCAVAT.PAS   (produit EXCAVAT.EXE)

  Jeu du genre des creuseurs de galeries, ecrit pour OS/2-0 a partir des
  regles d'un clone en Turbo Pascal (DigMan In the Rock, de l'equipe
  dark-cloud : MDIGGER.PAS et RMDIGGER.PAS, mode 320 x 200, fichiers de
  niveaux et d'images a part). Les dessins, les huit niveaux, les
  creatures et l'apparence sont propres a ce programme : fenetre de
  Presentation Manager avec menus, image en memoire (GpiDrawBits, seules
  les parties qui changent sont recopiees), ciel et chevalement de la
  mine, terre en couches avec cailloux, galeries creusees au pixel pres,
  excavatrice jaune a foret, taupes et foreuses, pierres precieuses
  taillees (une couleur par niveau), sacs d'or, panneau du pointage et
  barre d'etat.

  Regles : l'excavatrice creuse ou elle va et ramasse les pierres
  precieuses (25 points ; huit a la suite : 250 de plus). Un sac d'or que
  plus rien ne soutient se balance puis tombe ; tombe de deux etages ou
  plus, il s'ouvre et l'or vaut 500 points ; il ecrase ce qui est
  dessous (250 points par creature). Un sac se pousse a gauche ou a
  droite. Les taupes sortent du repaire (en bas a droite) et suivent les
  galeries ; certaines deviennent des foreuses qui creusent et mangent
  les pierres. Le tir (Espace) part dans la galerie et se recharge. La
  lanterne, qui parait au repaire quand la moitie des creatures sont
  vaincues, les effraie un moment : on peut alors les attraper (200,
  400, 800, 1600). Le niveau est fini quand toutes les pierres sont
  prises ou toutes les creatures vaincues. Trois vies, une de plus tous
  les 20000 points.

  Clavier : fleches (creuser), Espace (tirer), P (pause), F2 (nouvelle
  partie), F1 (regles).
  Parametres : /SEED:n ; /AUTO (l'excavatrice joue seule : demonstration) ;
  /LEVEL:n (niveau de depart). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_QUERY = $10; MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_NEWLINE = $08; VK_SPACE = $10; VK_LEFT = $15; VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  VK_UP = $16; VK_PAUSE = $0D;
  CM_NEW = 101; CM_PAUSE = 102; CM_QUIT = 104;
  CM_SLOW = 201; CM_NORMAL = 202; CM_FAST = 203;
  CM_RULES = 301; CM_ABOUT = 302;
  BW = 456; BH = 400; OX = 8; OY = 8;
  PnX = 472; PW = 146;
  CWant = 624; CHWant = 436;
  MaxDirty = 200; MaxSpr = 100;
  { grille : 15 x 11 cases de 30 pixels, sous la surface }
  GC = 15; GR = 11; CS = 30; FX0 = 3; FY0 = 52; NCell = 165;
  MaxMon = 8; MaxBag = 16; MaxPart = 90;
  D_UP = 1; D_DOWN = 2; D_LEFT = 3; D_RIGHT = 4;
  B_NONE = 0; B_REST = 1; B_WOB = 2; B_FALL = 3; B_SLIDE = 4; B_GOLD = 5;
  S_PLAY = 1; S_DIE = 2; S_PAUSE = 3; S_OVER = 4; S_LEVEL = 5;
  { couleurs de l'image (palette en vraies couleurs) }
  C_BLACK = 0; C_WHITE = 1; C_SKY1 = 2; C_SKY2 = 3; C_SKY3 = 4; C_SUN = 5; C_SUNL = 6; C_HILL = 7; C_HILL2 = 8;
  C_GRASS = 9; C_GRASSD = 10; C_GRASSL = 11; C_E1 = 12; C_E1D = 13; C_E1L = 14; C_E2 = 15; C_E2D = 16;
  C_E2L = 17; C_E3 = 18; C_E3D = 19; C_E3L = 20; C_E4 = 21; C_E4D = 22; C_E4L = 23; C_ROCK = 24; C_ROCKD = 25;
  C_ROCKL = 26; C_BED = 27; C_BEDD = 28; C_BEDL = 29; C_TUN = 30; C_TUN2 = 31; C_RIM = 32; C_WOOD = 33;
  C_WOODD = 34; C_WOODL = 35; C_GEML = 36; C_GEM = 37; C_GEMD = 38; C_GEMW = 39; C_SACK = 40; C_SACKD = 41;
  C_SACKL = 42; C_ROPE = 43; C_GOLD = 44; C_GOLDD = 45; C_GOLDL = 46; C_YEL = 47; C_YELD = 48; C_YELL = 49;
  C_TREAD = 50; C_TREADL = 51; C_STEEL = 52; C_STEELD = 53; C_STEELL = 54; C_GLASS = 55; C_BEACON = 56;
  C_FUR = 57; C_FURD = 58; C_FURL = 59; C_NOSE = 60; C_EYE = 61; C_HELM = 62; C_HELMD = 63; C_SCARE = 64;
  C_SCARED = 65; C_SCAREL = 66; C_FIRE = 67; C_FIREC = 68; C_FIRED = 69; C_LAMP = 70; C_BANNER = 71;
  C_BANNERE = 72; C_RED = 73; C_GREEN = 74; C_YELLOW = 75; C_CAVE = 76; C_CAVEE = 77; C_DUST = 78;
  C_SHADOW = 79;
  NPal = 80;
  Pal : Array[0..NPal - 1] Of LongInt = (
    $000000, $FFFFFF, $7DB4E6, $9CCAF0, $C4E2F6, $FFE680, $FFF6CC, $6E9A6E, $557F58, $3CA03C,
    $2A7A2E, $74CC5E, $C8A064, $AE8850, $DCB884, $A8784A, $8E643C, $BE9062, $8C5A3C, $744830,
    $A26E4C, $6A5040, $564034, $806452, $8C8C8C, $646464, $B4B4B4, $50505A, $3C3C46, $6E6E78,
    $2A1C12, $34241A, $4A3020, $8B5A2B, $5E3A1A, $B07840, $78F0A0, $28C864, $148C46, $FFFFFF,
    $C8A46E, $9C7A48, $E6C88C, $6E4A28, $FFD23C, $C8962A, $FFF08C, $F5C81E, $C8961E, $FFE678,
    $28282D, $5A5A64, $A0A5AF, $6E737D, $D2D7E1, $64B4DC, $FF3C28, $7D7068, $5A4E48, $9C8E84,
    $FF8CA0, $101010, $D23C28, $961E14, $78A0FF, $4664C8, $B4C8FF, $FFB43C, $FFF0B4, $FF6414,
    $50C8FF, $1E1E3C, $FFD23C, $FF5050, $50DC78, $FFE650, $140E0C, $8C4628, $C8B496, $1E140C);
  { lutins de 24 x 24 (index de la palette ; 0 : transparent) : excavatrice, taupe (deux pas),
    foreuse, pierre precieuse, sac d'or }
  SP_DIG = 0; SP_MOLE1 = 1; SP_MOLE2 = 2; SP_DRILL = 3; SP_GEM = 4; SP_SACK = 5; NSprite = 6;
  SprB : Array[0..NSprite * 576 - 1] Of Byte = (
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,56,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,47,47,47,47,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,47,55,55,55,1,47,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,47,55,55,55,55,47,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,47,55,55,55,55,47,0,0,0,0,0,0,0,0,0,0,53,0,0,0,0,0,0,0,47,47,47,47,47,47,47,47,47,47,47,
    47,47,48,0,53,52,53,0,0,0,0,0,49,49,49,49,49,49,49,49,49,49,49,49,49,49,47,48,53,52,54,53,0,0,0,0,
    47,47,47,47,47,47,47,47,47,47,47,47,47,47,47,48,53,52,54,52,53,0,0,0,47,47,47,47,47,47,47,47,47,47,47,47,
    47,47,47,48,53,52,54,52,52,53,0,0,47,48,48,48,48,48,48,48,48,48,48,48,48,48,47,48,53,52,54,52,52,52,53,0,
    47,47,47,47,47,47,47,47,47,47,47,47,47,47,47,48,53,52,54,52,52,52,52,53,48,48,48,48,48,48,48,48,48,48,48,48,
    48,48,48,48,53,52,54,52,52,52,53,0,0,53,52,52,52,52,52,52,52,52,52,52,52,52,53,0,53,52,54,52,52,53,0,0,
    0,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,0,53,52,52,53,0,0,0,50,51,50,50,51,50,50,51,50,50,51,50,
    50,51,50,50,50,0,53,53,0,0,0,0,50,51,51,51,51,51,51,51,51,51,51,51,51,51,51,51,50,0,0,0,0,0,0,0,
    50,50,51,50,50,51,50,50,51,50,50,51,50,50,51,50,50,0,0,0,0,0,0,0,0,50,50,50,50,50,50,50,50,50,50,50,
    50,50,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,58,58,58,58,58,58,58,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,58,58,57,57,57,57,57,57,57,58,58,0,0,0,0,0,0,0,0,0,0,0,0,58,57,57,59,57,57,57,
    57,57,57,57,57,58,0,0,0,0,0,0,0,0,0,0,58,57,59,59,57,57,57,57,57,57,57,57,57,57,58,0,0,0,0,0,
    0,0,0,58,57,59,57,57,57,57,57,57,57,57,57,57,1,61,57,58,0,0,0,0,0,0,0,58,57,57,57,57,57,57,57,57,
    57,57,57,57,61,61,57,57,58,0,0,0,0,0,58,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,60,60,0,
    0,0,58,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,60,60,60,0,0,58,57,57,57,57,57,57,57,57,57,
    57,57,57,57,57,57,57,57,57,58,60,0,0,0,58,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,58,0,0,
    0,0,0,58,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,58,0,0,0,0,0,0,0,58,58,57,57,57,57,57,57,
    57,57,57,57,57,57,58,58,0,0,0,0,0,0,0,0,0,60,60,0,58,58,58,58,58,58,58,58,0,60,60,0,0,0,0,0,
    0,0,0,0,60,0,60,0,0,0,0,0,0,0,0,0,60,0,60,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,58,58,58,58,58,58,58,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,58,58,57,57,57,57,57,57,57,58,58,0,0,0,0,0,0,0,0,0,0,0,0,58,57,57,59,57,57,57,
    57,57,57,57,57,58,0,0,0,0,0,0,0,0,0,0,58,57,59,59,57,57,57,57,57,57,57,57,57,57,58,0,0,0,0,0,
    0,0,0,58,57,59,57,57,57,57,57,57,57,57,57,57,1,61,57,58,0,0,0,0,0,0,0,58,57,57,57,57,57,57,57,57,
    57,57,57,57,61,61,57,57,58,0,0,0,0,0,58,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,60,60,0,
    0,0,58,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,60,60,60,0,0,58,57,57,57,57,57,57,57,57,57,
    57,57,57,57,57,57,57,57,57,58,60,0,0,0,58,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,58,0,0,
    0,0,0,58,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,58,0,0,0,0,0,0,0,58,58,57,57,57,57,57,57,
    57,57,57,57,57,57,58,58,0,0,0,0,0,0,0,0,0,0,0,60,60,0,58,58,58,58,58,58,0,60,60,0,0,0,0,0,
    0,0,0,0,0,0,60,0,60,0,0,0,0,0,0,0,60,0,60,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,63,62,62,62,62,62,63,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,63,62,62,62,62,62,
    62,62,63,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,63,62,62,62,62,62,62,62,62,70,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,63,63,63,63,63,63,63,63,63,70,70,0,0,0,0,0,0,0,0,0,0,0,0,0,58,58,57,57,57,57,
    57,57,57,58,58,0,0,0,0,0,0,0,0,0,0,0,0,58,57,57,59,57,57,57,57,57,57,57,57,58,0,0,0,0,0,0,
    0,0,0,0,58,57,59,59,57,57,57,57,57,57,57,57,57,57,58,0,0,0,0,0,0,0,0,58,57,59,57,57,57,57,57,57,
    57,57,57,57,1,61,57,58,0,0,0,0,0,0,0,58,57,57,57,57,57,57,57,57,57,57,57,57,61,61,57,57,58,53,53,0,
    0,0,58,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,53,52,54,0,0,58,57,57,57,57,57,57,57,57,57,
    57,57,57,57,57,57,57,57,57,52,54,52,0,0,58,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,53,52,54,
    0,0,58,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,57,58,53,53,0,0,0,58,57,57,57,57,57,57,57,57,
    57,57,57,57,57,57,57,57,58,0,0,0,0,0,0,0,58,58,57,57,57,57,57,57,57,57,57,57,57,57,58,58,0,0,0,0,
    0,0,0,0,0,60,60,0,58,58,58,58,58,58,58,58,0,60,60,0,0,0,0,0,0,0,0,0,60,0,60,0,0,0,0,0,
    0,0,0,0,60,0,60,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,36,36,36,36,36,36,
    36,36,36,36,36,36,0,0,0,0,0,0,0,0,0,0,0,36,36,39,36,36,36,36,36,36,36,36,36,36,37,0,0,0,0,0,
    0,0,0,0,36,36,39,39,36,36,36,36,36,36,36,36,36,36,37,37,0,0,0,0,0,0,0,36,36,36,36,36,37,37,37,37,
    37,37,37,37,37,36,36,36,38,0,0,0,0,0,36,36,36,36,37,37,37,37,37,37,37,37,37,37,37,37,37,36,36,38,38,0,
    0,0,38,36,36,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,38,38,0,0,0,0,38,38,37,37,37,37,37,37,37,
    37,37,37,37,37,37,37,37,37,38,0,0,0,0,0,0,38,38,37,37,37,37,37,37,37,37,37,37,37,37,37,38,38,0,0,0,
    0,0,0,0,0,38,38,38,37,37,37,37,37,37,37,37,37,38,38,38,0,0,0,0,0,0,0,0,0,0,0,38,38,38,38,37,
    37,37,37,38,38,38,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,38,38,38,38,38,38,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,43,43,0,0,43,43,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,43,43,43,43,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,41,40,
    40,40,40,41,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,43,43,43,43,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,41,42,40,40,40,41,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,41,40,42,40,
    40,40,40,40,41,0,0,0,0,0,0,0,0,0,0,0,0,0,41,41,42,42,40,40,40,40,40,40,40,41,41,0,0,0,0,0,
    0,0,0,0,0,41,40,42,42,40,40,40,40,40,40,40,40,40,40,41,0,0,0,0,0,0,0,0,41,40,42,40,40,40,40,44,
    44,44,44,40,40,40,40,40,41,0,0,0,0,0,0,0,41,40,42,40,40,40,44,46,44,44,44,45,40,40,40,40,41,0,0,0,
    0,0,0,41,40,42,40,40,40,40,44,46,44,45,45,44,40,40,40,40,40,41,0,0,0,0,0,41,40,42,40,40,40,40,44,46,
    44,40,40,40,40,40,40,40,40,41,0,0,0,0,0,41,40,40,40,40,40,40,44,46,44,45,45,44,40,40,40,40,41,41,0,0,
    0,0,0,41,40,40,40,40,40,40,40,44,44,44,44,45,40,40,40,40,41,41,0,0,0,0,0,0,41,40,40,40,40,40,40,40,
    45,45,45,45,40,40,40,41,41,0,0,0,0,0,0,0,41,41,40,40,40,40,40,40,40,40,40,40,40,40,41,41,41,0,0,0,
    0,0,0,0,0,41,41,41,40,40,40,40,40,40,40,40,41,41,41,41,0,0,0,0,0,0,0,0,0,0,0,41,41,41,41,41,
    41,41,41,41,41,41,41,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
  { niveaux (15 x 11) : 0 terre, 1 galerie, 2 pierre precieuse, 3 sac d'or, 4 depart, 5 repaire }
  NLev = 8;
  LevB : Array[0..NLev * 165 - 1] Of Byte = (
    4,1,1,1,1,0,0,3,0,0,0,0,3,0,0,0,0,0,1,0,2,2,0,0,2,2,0,0,0,0,0,3,0,1,0,2,2,0,0,2,2,0,0,3,0,
    0,0,0,1,0,2,2,0,0,2,2,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0,3,0,0,0,0,1,0,0,2,2,2,0,0,
    0,2,2,2,0,0,0,1,0,0,2,2,2,0,3,0,2,2,2,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,3,0,0,1,1,1,1,1,1,0,0,
    0,0,2,2,0,0,0,0,0,0,3,0,1,0,0,0,0,2,2,0,0,0,0,0,0,0,0,1,1,5,4,1,1,1,1,1,0,0,0,3,0,0,2,2,0,
    0,0,0,0,0,1,0,0,2,2,2,0,2,2,0,0,3,0,0,0,1,0,0,2,2,2,0,0,0,0,0,0,2,2,0,1,0,0,0,0,0,3,0,0,0,
    0,0,2,2,0,1,1,1,1,1,1,1,0,0,0,0,0,2,2,0,0,0,0,3,0,0,1,0,0,0,0,0,0,0,0,0,0,2,2,2,0,1,0,3,0,
    0,0,3,0,0,0,0,2,2,2,0,1,0,0,0,0,2,2,0,0,0,0,2,2,2,0,1,0,0,0,0,2,2,0,0,3,0,0,0,0,0,1,1,1,1,
    0,0,0,0,0,0,0,0,0,0,0,0,0,1,5,4,1,0,0,0,0,0,3,0,0,0,0,0,3,0,0,1,0,2,2,0,0,0,0,0,2,2,0,0,0,
    0,1,0,2,2,0,0,3,0,0,2,2,0,0,0,0,1,0,2,2,0,0,0,0,0,2,2,0,0,0,0,1,1,1,1,1,1,0,1,1,1,1,1,0,0,
    0,0,0,0,3,0,1,0,1,0,0,0,1,0,0,0,0,2,2,2,0,1,0,1,0,3,0,1,0,0,0,0,2,2,2,0,1,1,1,0,0,0,1,0,0,
    0,0,2,2,2,0,0,0,3,0,0,0,1,0,0,0,3,0,0,0,0,0,0,2,2,2,0,1,0,0,0,0,0,0,0,0,0,0,2,2,2,0,1,1,5,
    4,1,1,1,3,0,0,2,2,0,0,3,0,0,0,0,0,0,1,0,0,0,2,2,0,0,0,0,0,0,0,2,2,1,0,3,0,2,2,0,0,2,2,2,0,
    0,2,2,1,0,0,0,0,0,0,0,2,2,2,0,0,2,2,1,1,1,1,1,0,3,0,0,0,0,0,0,0,0,0,3,0,0,1,0,0,0,3,0,0,0,
    0,0,2,2,0,0,0,1,0,0,2,2,0,0,0,0,0,2,2,0,0,0,1,1,1,1,1,1,0,0,0,0,2,2,0,3,0,0,0,0,0,0,1,0,0,
    0,0,0,0,0,0,2,2,2,2,0,0,1,0,3,0,0,3,0,0,0,2,2,2,2,0,0,1,1,5,4,1,1,1,1,1,1,1,1,1,1,0,0,0,0,
    0,2,0,2,0,2,0,2,0,2,1,0,3,0,0,0,0,3,0,0,0,3,0,0,0,1,0,0,0,0,0,2,0,2,0,2,0,2,0,2,1,0,2,2,0,
    0,0,0,0,0,0,0,0,0,0,1,0,2,2,0,0,3,0,0,2,2,2,0,0,0,1,0,0,0,0,0,0,0,0,2,2,2,0,0,3,1,0,0,3,0,
    0,0,0,0,2,2,2,0,0,0,1,0,0,0,0,0,0,3,0,0,0,0,0,0,0,1,0,2,2,0,0,2,2,0,0,3,0,0,2,2,1,0,2,2,0,
    0,2,2,0,0,0,0,0,2,2,1,1,1,1,5,4,1,0,0,3,0,0,0,3,0,0,0,3,0,0,0,1,0,2,2,2,0,2,2,2,0,2,2,2,0,
    0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,1,1,1,1,1,1,0,0,0,0,0,0,0,1,0,1,0,0,0,0,1,0,
    0,3,0,2,2,0,1,0,1,0,2,2,0,1,0,0,0,0,2,2,0,1,0,1,0,2,2,0,1,0,0,0,0,2,2,0,1,1,1,0,2,2,0,1,0,
    0,3,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,2,2,2,0,0,3,0,0,2,2,2,1,0,0,0,2,2,2,0,0,0,0,0,2,2,2,1,5,
    4,1,0,0,0,0,2,2,2,0,0,0,0,3,0,0,1,0,3,0,0,2,2,2,0,3,0,0,0,0,0,1,0,0,0,0,2,2,2,0,0,0,0,0,0,
    0,1,0,2,2,0,0,0,0,0,2,2,0,3,0,0,1,0,2,2,0,3,0,3,0,2,2,0,0,0,0,1,0,2,2,0,0,0,0,0,2,2,0,0,0,
    0,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,3,0,0,0,0,0,0,1,0,0,0,2,2,0,2,2,2,2,0,2,2,0,1,0,
    0,0,2,2,0,2,2,2,2,0,2,2,0,1,0,0,3,0,0,0,0,0,0,0,0,0,0,0,1,5,4,1,1,1,0,3,0,0,3,0,0,3,0,0,0,
    0,0,0,1,0,0,0,0,0,0,0,0,0,2,2,0,2,0,1,0,2,2,2,2,2,0,0,0,2,2,0,2,0,1,0,0,0,0,0,0,0,0,0,2,2,
    0,2,0,1,1,1,1,1,0,3,0,0,0,0,0,0,3,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,2,2,2,0,0,1,0,0,2,2,2,0,0,
    0,0,2,2,2,0,0,1,0,0,2,2,2,0,3,0,0,3,0,0,0,0,1,1,1,1,1,1,0,0,0,2,2,0,0,3,0,0,0,0,0,0,1,0,0,
    0,2,2,0,0,0,0,0,0,0,0,0,1,1,5);
  { pierres de chaque niveau : claire, moyenne, sombre }
  GemSet : Array[0..14] Of LongInt = (
    $78F0A0, $28C864, $148C46,
    $FF8CA0, $DC2846, $961432,
    $8CB4FF, $2864DC, $143C96,
    $D2A0FF, $9650DC, $64289C,
    $FFE08C, $F0A028, $B46E14);

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back, Ground : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  DX1, DY1, DX2, DY2 : Array[0..MaxDirty - 1] Of LongInt;
  SX1, SY1, SX2, SY2 : Array[0..MaxSpr - 1] Of LongInt;
  NDirty, NSpr : LongInt;
  { grille : pierres, cases creusees, passages ouverts (vers la droite,
    vers le bas) }
  Gem, Dug, EH, EV : Array[0..NCell - 1] Of Byte;
  Dist, Que, Par : Array[0..NCell - 1] Of LongInt;
  { sacs d'or }
  BagX, BagY, BagS, BagT, BagF, BagD : Array[0..MaxBag - 1] Of LongInt;
  NBag : LongInt;
  { creatures : 1 taupe, 2 foreuse ; vivante 1, sortant du repaire 2 }
  MonX, MonY, MonD, MonK, MonA, MonT, MonAcc, MonF, MonLc, MonLr : Array[0..MaxMon - 1] Of LongInt;
  { excavatrice }
  PlX, PlY, PDir, PFace, PWant, PLc, PLr, Pushing, StartC, StartR, LairC, LairR : LongInt;
  { tir }
  FirX, FirY, FirD, FirOn, FireCool, FireMax : LongInt;
  LampOn, LampT, LampDone, BonusT, BonusMax, EatChain : LongInt;
  { eclats }
  QX, QY, QVX, QVY, QLife, QCol : Array[0..MaxPart - 1] Of LongInt;
  Level, Lives, Score, Best, NextLife, MonLeft, MonTotal, MonKilled, SpawnT, GemsLeft, Chain, ChainT : LongInt;
  State, Wait, Seed, AutoAll, Tick, SpeedMs, KeyDir, KeyNew, StartLevel0 : LongInt;
  Banner, Banner2, Msg : String;
  BannerC : LongInt;
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

Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;


Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';

Procedure WrL(A, V : LongInt);
Begin
  WrW(A, V And $FFFF);
  WrW(A + 2, (V Shr 16) And $FFFF);
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
{ Image en memoire (8 bits, palette en vraies couleurs) : fond fixe     }
{ (Back), image affichee (Fb), rectangles a recopier (GpiDrawBits)      }
{ ==================================================================== }

Procedure SetPal(I, C : LongInt);
Var A : LongInt;
Begin
  A := LongInt(@Bmi) + 16 + I * 4;
  WrB(A, C And 255); WrB(A + 1, (C Shr 8) And 255); WrB(A + 2, (C Shr 16) And 255);
End;

Procedure InitBmi;
Var I : LongInt;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, BW);
  WrL(LongInt(@Bmi) + 8, BH);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
  For I := 0 To NPal - 1 Do SetPal(I, Pal[I]);
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

{ ellipse pleine de centre (Cx, Cy) }
Procedure Ell(Cx, Cy, Rx, Ry, C : LongInt);
Var Dy, W : LongInt;
Begin
  For Dy := -Ry To Ry Do
  Begin
    W := 0;
    While (W + 1) * (W + 1) * Ry * Ry + Dy * Dy * Rx * Rx <= Rx * Rx * Ry * Ry + Rx * Ry Do Inc(W);
    Rect(Cx - W, Cy + Dy, Cx + W, Cy + Dy, C);
  End;
End;

Procedure FDisc(Cx, Cy, R, C : LongInt);
Begin
  If R <= 0 Then Pix(Cx, Cy, C) Else Ell(Cx, Cy, R, R, C);
End;

Procedure DLine(X1, Y1, X2, Y2, C : LongInt);
Var N, K, Dx, Dy : LongInt;
Begin
  Dx := X2 - X1; Dy := Y2 - Y1;
  N := Abs(Dx);
  If Abs(Dy) > N Then N := Abs(Dy);
  If N = 0 Then
  Begin
    Pix(X1, Y1, C);
    Exit;
  End;
  For K := 0 To N Do Pix(X1 + (Dx * K) Div N, Y1 + (Dy * K) Div N, C);
End;

{ trait epais (carre de cote 2T + 1 le long du trait) }
Procedure TLine(X1, Y1, X2, Y2, T, C : LongInt);
Var N, K, Dx, Dy, X, Y : LongInt;
Begin
  Dx := X2 - X1; Dy := Y2 - Y1;
  N := Abs(Dx);
  If Abs(Dy) > N Then N := Abs(Dy);
  If N = 0 Then N := 1;
  For K := 0 To N Do
  Begin
    X := X1 + (Dx * K) Div N; Y := Y1 + (Dy * K) Div N;
    Rect(X - T, Y - T, X + T, Y + T, C);
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

{ texte avec une ombre d'un pixel }
Procedure FbTextSh(X, Y : LongInt; S : String; C, Sh, Sc : LongInt);
Begin
  FbText(X + 1, Y + 1, S, Sh, Sc);
  FbText(X, Y, S, C, Sc);
End;

{ --- fond fixe --- }
Procedure SaveBack;
Begin
  Move(Fb, Back, SizeOf(Fb));
End;

Procedure RestoreRect(X1, Y1, X2, Y2 : LongInt);
Var Y, B : LongInt;
Begin
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  For Y := Y1 To Y2 Do
  Begin
    B := (BH - 1 - Y) * BW + X1;
    Move(Back[B], Fb[B], X2 - X1 + 1);
  End;
End;

{ --- rectangles a recopier --- }
Procedure AddDirty(X1, Y1, X2, Y2 : LongInt);
Begin
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  If NDirty >= MaxDirty Then
  Begin
    NDirty := 1;
    DX1[0] := 0; DY1[0] := 0; DX2[0] := BW - 1; DY2[0] := BH - 1;
    Exit;
  End;
  DX1[NDirty] := X1; DY1[NDirty] := Y1; DX2[NDirty] := X2; DY2[NDirty] := Y2;
  Inc(NDirty);
End;

Procedure BlitRect(H, X1, Y1, X2, Y2 : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
  P[0] := OX + X1; P[1] := CH - OY - 1 - Y2; P[2] := OX + X2 + 1; P[3] := CH - OY - Y1;
  P[4] := X1; P[5] := BH - 1 - Y2; P[6] := X2 + 1; P[7] := BH - Y1;
  Dummy := GpiDrawBits(H, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

{ --- objets mobiles : effaces (fond fixe) puis redessines --- }
Procedure SprBegin;
Var K : LongInt;
Begin
  For K := 0 To NSpr - 1 Do
  Begin
    RestoreRect(SX1[K], SY1[K], SX2[K], SY2[K]);
    AddDirty(SX1[K], SY1[K], SX2[K], SY2[K]);
  End;
  NSpr := 0;
End;

Procedure SprRect(X1, Y1, X2, Y2 : LongInt);
Begin
  If NSpr >= MaxSpr Then Exit;
  SX1[NSpr] := X1; SY1[NSpr] := Y1; SX2[NSpr] := X2; SY2[NSpr] := Y2;
  Inc(NSpr);
  AddDirty(X1, Y1, X2, Y2);
End;


Function MinX(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinX := A Else MinX := B;
End;

Function MaxX(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxX := A Else MaxX := B;
End;

{ ==================================================================== }
{ Grille                                                                }
{ ==================================================================== }

Function CI(C, R : LongInt) : LongInt;
Begin
  CI := R * GC + C;
End;

Function CellX(C : LongInt) : LongInt;
Begin
  CellX := FX0 + C * CS + 15;
End;

Function CellY(R : LongInt) : LongInt;
Begin
  CellY := FY0 + R * CS + 15;
End;

Function ColOf(X : LongInt) : LongInt;
Begin
  ColOf := (X - FX0) Div CS;
End;

Function RowOf(Y : LongInt) : LongInt;
Begin
  RowOf := (Y - FY0) Div CS;
End;

Function OnCenter(X, Y : LongInt) : Boolean;
Begin
  OnCenter := ((X - FX0 - 15) Mod CS = 0) And ((Y - FY0 - 15) Mod CS = 0);
End;

Function InGrid(C, R : LongInt) : Boolean;
Begin
  InGrid := (C >= 0) And (C < GC) And (R >= 0) And (R < GR);
End;

Function DirX(D : LongInt) : LongInt;
Begin
  If D = D_LEFT Then DirX := -1 Else If D = D_RIGHT Then DirX := 1 Else DirX := 0;
End;

Function DirY(D : LongInt) : LongInt;
Begin
  If D = D_UP Then DirY := -1 Else If D = D_DOWN Then DirY := 1 Else DirY := 0;
End;

Function RevDir(D : LongInt) : LongInt;
Begin
  Case D Of
    D_UP : RevDir := D_DOWN;
    D_DOWN : RevDir := D_UP;
    D_LEFT : RevDir := D_RIGHT;
    D_RIGHT : RevDir := D_LEFT;
  Else
    RevDir := 0;
  End;
End;

{ passage ouvert de la case (C, R) vers la direction D }
Function EdgeOpen(C, R, D : LongInt) : Boolean;
Begin
  EdgeOpen := False;
  Case D Of
    D_UP : If R > 0 Then EdgeOpen := EV[CI(C, R - 1)] <> 0;
    D_DOWN : If R < GR - 1 Then EdgeOpen := EV[CI(C, R)] <> 0;
    D_LEFT : If C > 0 Then EdgeOpen := EH[CI(C - 1, R)] <> 0;
    D_RIGHT : If C < GC - 1 Then EdgeOpen := EH[CI(C, R)] <> 0;
  End;
End;

Procedure OpenBetween(C1, R1, C2, R2 : LongInt);
Begin
  If Not InGrid(C1, R1) Or Not InGrid(C2, R2) Then Exit;
  Dug[CI(C1, R1)] := 1; Dug[CI(C2, R2)] := 1;
  If (R1 = R2) And (Abs(C1 - C2) = 1) Then EH[CI(MinX(C1, C2), R1)] := 1
  Else If (C1 = C2) And (Abs(R1 - R2) = 1) Then EV[CI(C1, MinX(R1, R2))] := 1;
End;

{ sac (pas l'or) dans la case (C, R), sauf Skip ; -1 s'il n'y en a pas }
Function BagAt(C, R, Skip : LongInt) : LongInt;
Var K, S : LongInt;
Begin
  BagAt := -1;
  For K := 0 To NBag - 1 Do
  Begin
    S := BagS[K];
    If (K <> Skip) And (S <> B_NONE) And (S <> B_GOLD) Then
      If ((ColOf(BagX[K] - 14) = C) Or (ColOf(BagX[K] + 14) = C)) And
         ((RowOf(BagY[K] - 14) = R) Or (RowOf(BagY[K] + 14) = R)) Then
      Begin
        BagAt := K;
        Exit;
      End;
  End;
End;

Function GoldAt(C, R : LongInt) : LongInt;
Var K : LongInt;
Begin
  GoldAt := -1;
  For K := 0 To NBag - 1 Do
    If (BagS[K] = B_GOLD) And (ColOf(BagX[K]) = C) And (RowOf(BagY[K]) = R) Then
    Begin
      GoldAt := K;
      Exit;
    End;
End;

{ ==================================================================== }
{ Decor : ciel, chevalement, terre en couches (dessines une fois)       }
{ ==================================================================== }

Var
  RndS : LongInt;

Function NextR(N : LongInt) : LongInt;
Begin
  RndS := (RndS * 1103515245 + 12345) And $7FFFFFFF;
  NextR := (RndS Shr 8) Mod N;
End;

Procedure RenderGround;
Var X, Y, K, H1, H2, L, C, R, B1, B2, B3, Rx, Ry : LongInt;
    Wa, Wb : Array[0..BW - 1] Of LongInt;
Begin
  RndS := 4242;
  For X := 0 To BW - 1 Do
  Begin
    Wa[X] := Round(6 * Sin(X / 23.0) + 4 * Sin(X / 9.0 + 1));
    Wb[X] := Round(7 * Sin(X / 31.0 + 2) + 3 * Sin(X / 11.0));
  End;
  { ciel en trois teintes, tramees aux limites }
  For Y := 0 To 43 Do
    For X := 0 To BW - 1 Do
    Begin
      If Y < 12 Then C := C_SKY1
      Else If Y < 15 Then Begin If (X + Y) Mod 2 = 0 Then C := C_SKY1 Else C := C_SKY2; End
      Else If Y < 26 Then C := C_SKY2
      Else If Y < 29 Then Begin If (X + Y) Mod 2 = 0 Then C := C_SKY2 Else C := C_SKY3; End
      Else C := C_SKY3;
      Fb[(BH - 1 - Y) * BW + X] := C;
    End;
  { soleil }
  FDisc(418, 15, 10, C_SUN);
  FDisc(416, 13, 5, C_SUNL);
  { collines au loin }
  For X := 0 To BW - 1 Do
  Begin
    H1 := 30 - Round(6 * Sin(X / 41.0) + 4 * Sin(X / 17.0 + 2));
    H2 := 37 - Round(4 * Sin(X / 29.0 + 1) + 2 * Sin(X / 7.0));
    For Y := H1 To 43 Do Pix(X, Y, C_HILL);
    For Y := H2 To 43 Do Pix(X, Y, C_HILL2);
  End;
  { herbe }
  For X := 0 To BW - 1 Do
  Begin
    For Y := 44 To 51 Do
      If Y >= 50 Then Pix(X, Y, C_GRASSD) Else Pix(X, Y, C_GRASS);
    Pix(X, 44, C_GRASSL);
    K := NextR(5);
    If K = 0 Then Begin Pix(X, 43, C_GRASS); Pix(X, 42, C_GRASSL); End
    Else If K = 1 Then Pix(X, 43, C_GRASSD);
  End;
  { terre : quatre couches aux limites ondulees, grain, cailloux }
  For Y := 52 To FY0 + GR * CS - 1 Do
    For X := 0 To BW - 1 Do
    Begin
      If Y < 122 + Wa[X] Then L := 0
      Else If Y < 204 + Wb[X] Then L := 1
      Else If Y < 292 + Wa[(X + 150) Mod BW] Then L := 2
      Else L := 3;
      B1 := C_E1 + L * 3;
      R := NextR(100);
      If R < 13 Then C := B1 + 1 Else If R < 22 Then C := B1 + 2 Else C := B1;
      { petites mottes plus sombres }
      If ((X Div 5 + Y Div 4) Mod 23 = 0) And (R < 50) Then C := B1 + 1;
      Fb[(BH - 1 - Y) * BW + X] := C;
    End;
  { racines sous l'herbe }
  For K := 0 To 13 Do
  Begin
    X := 20 + NextR(BW - 40);
    Y := 52;
    L := 6 + NextR(14);
    For R := 0 To L Do
    Begin
      Pix(X, Y + R, C_E1D);
      If NextR(3) = 0 Then X := X + NextR(3) - 1;
    End;
  End;
  For K := 0 To 85 Do
  Begin
    X := 6 + NextR(BW - 12);
    Y := 58 + NextR(FY0 + GR * CS - 64);
    Rx := 2 + NextR(3); Ry := 1 + NextR(2);
    Ell(X, Y, Rx, Ry, C_ROCK);
    Pix(X - Rx + 1, Y - Ry + 1, C_ROCKL);
    Pix(X - Rx + 2, Y - Ry + 1, C_ROCKL);
    Rect(X - Rx + 1, Y + Ry, X + Rx - 1, Y + Ry, C_ROCKD);
  End;
  { roche du fond }
  For Y := FY0 + GR * CS To BH - 1 Do
    For X := 0 To BW - 1 Do
    Begin
      R := NextR(100);
      If R < 15 Then C := C_BEDD Else If R < 25 Then C := C_BEDL Else C := C_BED;
      Fb[(BH - 1 - Y) * BW + X] := C;
    End;
  Rect(0, FY0 + GR * CS, BW - 1, FY0 + GR * CS, C_BEDD);
  { chevalement en bois au-dessus du puits de depart (case 0, 0) }
  B2 := CellX(0);
  TLine(B2 - 15, 44, B2 - 5, 6, 1, C_WOOD);
  TLine(B2 + 15, 44, B2 + 5, 6, 1, C_WOODD);
  TLine(B2 - 12, 32, B2 + 12, 32, 0, C_WOODL);
  TLine(B2 - 9, 20, B2 + 9, 20, 0, C_WOODL);
  DLine(B2 - 12, 32, B2 + 9, 20, C_WOODD);
  DLine(B2 + 12, 32, B2 - 9, 20, C_WOODD);
  Ell(B2, 7, 6, 6, C_STEELD);
  Ell(B2, 7, 4, 4, C_SKY2);
  DLine(B2 - 4, 7, B2 + 4, 7, C_STEELD);
  DLine(B2, 3, B2, 11, C_STEELD);
  Rect(B2 - 7, 5, B2 - 7, 44, C_ROPE);
  { petite cabane }
  B3 := CellX(2);
  Rect(B3 - 10, 32, B3 + 12, 44, C_WOOD);
  For X := B3 - 10 To B3 + 12 Do If (X - B3) Mod 4 = 0 Then Rect(X, 32, X, 44, C_WOODD);
  For K := 0 To 8 Do Rect(B3 - 12 + K, 32 - K Div 2, B3 + 14 - K, 32 - K Div 2, C_RED);
  Rect(B3 - 2, 37, B3 + 4, 44, C_WOODD);
  { titre }
  FbTextSh(150, 8, 'EXCAVATEUR', C_YEL, C_WOODD, 2);
  Move(Fb, Ground, SizeOf(Fb));
End;

{ ==================================================================== }
{ Lutins et galeries                                                     }
{ ==================================================================== }

{ couleurs d'une creature effrayee }
Function Scared(V : LongInt) : LongInt;
Begin
  Case V Of
    C_FUR : Scared := C_SCARE;
    C_FURD : Scared := C_SCARED;
    C_FURL : Scared := C_SCAREL;
    C_NOSE : Scared := C_WHITE;
    C_HELM : Scared := C_SCARE;
    C_HELMD : Scared := C_SCARED;
  Else
    Scared := V;
  End;
End;

{ lutin Id centre en (Cx, Cy) ; Orient : 0 droite, 1 gauche, 2 haut, 3 bas }
Procedure DrawSpr(Id, Cx, Cy, Orient, Mode : LongInt; Reg : Boolean);
Var X, Y, V, Base, Tx, Ty : LongInt;
Begin
  Base := Id * 576;
  For Y := 0 To 23 Do
    For X := 0 To 23 Do
    Begin
      V := SprB[Base + Y * 24 + X];
      If V <> 0 Then
      Begin
        If Mode = 1 Then V := Scared(V);
        Case Orient Of
          0 : Begin Tx := X; Ty := Y; End;
          1 : Begin Tx := 23 - X; Ty := Y; End;
          2 : Begin Tx := Y; Ty := 23 - X; End;
        Else
          Begin Tx := 23 - Y; Ty := X; End;
        End;
        Pix(Cx - 12 + Tx, Cy - 12 + Ty, V);
      End;
    End;
  If Reg Then SprRect(Cx - 12, Cy - 12, Cx + 11, Cy + 11);
End;

Function OrientOf(D : LongInt) : LongInt;
Begin
  Case D Of
    D_LEFT : OrientOf := 1;
    D_UP : OrientOf := 2;
    D_DOWN : OrientOf := 3;
  Else
    OrientOf := 0;
  End;
End;

{ creuser autour du point (Cx, Cy) : carre arrondi de 25 pixels, bord
  sombre dans la terre ; le fond fixe (Back) et l'image sont modifies }
Procedure Carve(Cx, Cy : LongInt);
Var X, Y, Dx, Dy, Ax, Ay, B, V, Ytop, Ybot : LongInt;
Begin
  Ytop := FY0 + 1; Ybot := FY0 + GR * CS - 1;
  For Dy := -14 To 14 Do
  Begin
    Y := Cy + Dy;
    If (Y >= Ytop) And (Y <= Ybot) Then
      For Dx := -14 To 14 Do
      Begin
        X := Cx + Dx;
        If (X >= FX0) And (X < FX0 + GC * CS) Then
        Begin
          Ax := Abs(Dx); Ay := Abs(Dy);
          B := (BH - 1 - Y) * BW + X;
          V := Back[B];
          If (Ax <= 12) And (Ay <= 12) And Not ((Ax > 8) And (Ay > 8) And (Sqr(Ax - 8) + Sqr(Ay - 8) > 16)) Then
          Begin
            If (V <> C_TUN) And (V <> C_TUN2) And (V <> C_CAVE) Then
            Begin
              If (X * 7 + Y * 13) Mod 11 = 0 Then Back[B] := C_TUN2 Else Back[B] := C_TUN;
            End;
          End
          Else If (V >= C_E1) And (V <= C_ROCKL) Then Back[B] := C_RIM;
        End;
      End;
  End;
  RestoreRect(Cx - 14, Cy - 14, Cx + 14, Cy + 14);
  AddDirty(Cx - 14, Cy - 14, Cx + 14, Cy + 14);
End;

{ pierre ramassee : ses pixels redeviennent de la terre }
Procedure RemoveGem(C, R : LongInt);
Var X, Y, B, X0, Y0 : LongInt;
Begin
  X0 := CellX(C); Y0 := CellY(R);
  For Y := Y0 - 13 To Y0 + 12 Do
    For X := X0 - 13 To X0 + 12 Do
    Begin
      B := (BH - 1 - Y) * BW + X;
      If (Back[B] >= C_GEML) And (Back[B] <= C_GEMW) Then Back[B] := Ground[B];
    End;
  RestoreRect(X0 - 13, Y0 - 13, X0 + 12, Y0 + 12);
  AddDirty(X0 - 13, Y0 - 13, X0 + 12, Y0 + 12);
End;

{ copier une partie de l'image dans le fond fixe }
Procedure FbToBack(X1, Y1, X2, Y2 : LongInt);
Var Y, B : LongInt;
Begin
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  For Y := Y1 To Y2 Do
  Begin
    B := (BH - 1 - Y) * BW + X1;
    Move(Fb[B], Back[B], X2 - X1 + 1);
  End;
End;

{ repaire des creatures : caverne entouree de pierres ; puits de depart }
Procedure DrawLair;
Var X, Y, K, A : LongInt;
Begin
  X := CellX(LairC); Y := CellY(LairR);
  Ell(X, Y + 2, 12, 10, C_CAVE);
  For K := 0 To 8 Do
  Begin
    A := K * 180 Div 8;
    FDisc(X + Round(15 * Cos(A * Pi / 180)), Y + 2 - Round(13 * Sin(A * Pi / 180)), 3, C_ROCKD);
    Pix(X + Round(15 * Cos(A * Pi / 180)) - 1, Y + 1 - Round(13 * Sin(A * Pi / 180)), C_ROCKL);
  End;
  Pix(X - 4, Y, C_CAVEE); Pix(X - 2, Y, C_CAVEE);
  Pix(X + 3, Y + 2, C_CAVEE); Pix(X + 5, Y + 2, C_CAVEE);
  FbToBack(X - 20, Y - 15, X + 20, Y + 15);
  { puits de depart : galerie jusqu'a l'herbe, boisage }
  X := CellX(StartC);
  Rect(X - 11, 44, X + 11, FY0 + 2, C_TUN);
  Rect(X - 13, 44, X - 12, FY0 + 8, C_WOOD);
  Rect(X + 12, 44, X + 13, FY0 + 8, C_WOODD);
  Rect(X - 13, 46, X + 13, 47, C_WOODL);
  FbToBack(X - 14, 40, X + 14, FY0 + 9);
  RestoreRect(0, 0, BW - 1, BH - 1);
End;

{ ==================================================================== }
{ Niveau                                                                }
{ ==================================================================== }

Procedure BuildLevel;
Var L, C, R, V, I, K : LongInt;
Begin
  L := (Level - 1) Mod NLev;
  I := ((Level - 1) Mod 5) * 3;
  SetPal(C_GEML, GemSet[I]); SetPal(C_GEM, GemSet[I + 1]); SetPal(C_GEMD, GemSet[I + 2]);
  Move(Ground, Fb, SizeOf(Fb));
  FillChar(Gem, SizeOf(Gem), 0); FillChar(Dug, SizeOf(Dug), 0);
  FillChar(EH, SizeOf(EH), 0); FillChar(EV, SizeOf(EV), 0);
  NBag := 0; GemsLeft := 0;
  StartC := 0; StartR := 0; LairC := GC - 1; LairR := GR - 1;
  For R := 0 To GR - 1 Do
    For C := 0 To GC - 1 Do
    Begin
      V := LevB[L * NCell + CI(C, R)];
      Case V Of
        1 : Dug[CI(C, R)] := 1;
        2 : Begin Gem[CI(C, R)] := 1; Inc(GemsLeft); End;
        3 : If NBag < MaxBag Then
            Begin
              BagX[NBag] := CellX(C); BagY[NBag] := CellY(R); BagS[NBag] := B_REST; BagT[NBag] := 0;
              Inc(NBag);
            End;
        4 : Begin Dug[CI(C, R)] := 1; StartC := C; StartR := R; End;
        5 : Begin Dug[CI(C, R)] := 1; LairC := C; LairR := R; End;
      End;
    End;
  For R := 0 To GR - 1 Do
    For C := 0 To GC - 1 Do
      If Dug[CI(C, R)] <> 0 Then
      Begin
        If (C < GC - 1) And (Dug[CI(C + 1, R)] <> 0) Then EH[CI(C, R)] := 1;
        If (R < GR - 1) And (Dug[CI(C, R + 1)] <> 0) Then EV[CI(C, R)] := 1;
      End;
  For R := 0 To GR - 1 Do
    For C := 0 To GC - 1 Do
      If Gem[CI(C, R)] <> 0 Then DrawSpr(SP_GEM, CellX(C), CellY(R) + 1, 0, 0, False);
  Move(Fb, Back, SizeOf(Fb));
  { galeries du niveau }
  For R := 0 To GR - 1 Do
    For C := 0 To GC - 1 Do
      If Dug[CI(C, R)] <> 0 Then
      Begin
        Carve(CellX(C), CellY(R));
        If EH[CI(C, R)] <> 0 Then For K := 1 To CS - 1 Do Carve(CellX(C) + K, CellY(R));
        If EV[CI(C, R)] <> 0 Then For K := 1 To CS - 1 Do Carve(CellX(C), CellY(R) + K);
      End;
  DrawLair;
  NDirty := 0;
End;

{ ==================================================================== }
{ Dessin des objets mobiles                                              }
{ ==================================================================== }

Procedure DrawGold(X, Y, T : LongInt);
Begin
  If (T < 60) And (Tick Mod 6 < 3) Then Exit;
  FDisc(X - 6, Y + 6, 4, C_GOLDD);
  FDisc(X + 5, Y + 7, 4, C_GOLDD);
  FDisc(X, Y + 3, 5, C_GOLD);
  FDisc(X - 7, Y + 5, 3, C_GOLD);
  FDisc(X + 6, Y + 5, 3, C_GOLD);
  FDisc(X + 1, Y - 3, 3, C_GOLD);
  Pix(X - 1, Y + 1, C_GOLDL); Pix(X, Y + 1, C_GOLDL); Pix(X, Y - 5, C_GOLDL);
  Pix(X - 8, Y + 4, C_GOLDL); Pix(X + 5, Y + 3, C_GOLDL);
  If Tick Mod 10 < 5 Then Pix(X + 3, Y - 1, C_WHITE) Else Pix(X - 4, Y + 2, C_WHITE);
  SprRect(X - 11, Y - 7, X + 10, Y + 12);
End;

Procedure DrawLamp(X, Y : LongInt);
Begin
  If Tick Mod 8 < 4 Then FDisc(X, Y + 2, 11, C_FIRED);
  DLine(X - 4, Y - 8, X, Y - 11, C_STEELD);
  DLine(X + 4, Y - 8, X, Y - 11, C_STEELD);
  Rect(X - 6, Y - 8, X + 6, Y - 6, C_STEELD);
  Rect(X - 5, Y - 5, X + 5, Y + 7, C_LAMP);
  Rect(X - 2, Y - 3, X + 2, Y + 5, C_FIREC);
  Rect(X - 5, Y - 5, X - 5, Y + 7, C_STEELD); Rect(X + 5, Y - 5, X + 5, Y + 7, C_STEELD);
  Rect(X - 7, Y + 8, X + 7, Y + 10, C_STEELD);
  SprRect(X - 12, Y - 12, X + 12, Y + 14);
End;

Procedure DrawFire;
Var Bx, By : LongInt;
Begin
  If FirOn = 0 Then Exit;
  Bx := FirX - DirX(FirD) * 7; By := FirY - DirY(FirD) * 7;
  FDisc(Bx, By, 2, C_FIRED);
  FDisc(FirX, FirY, 5, C_FIRED);
  FDisc(FirX, FirY, 3, C_FIRE);
  FDisc(FirX, FirY, 1, C_FIREC);
  SprRect(MinX(FirX, Bx) - 6, MinX(FirY, By) - 6, MaxX(FirX, Bx) + 6, MaxX(FirY, By) + 6);
End;

Procedure BannerDraw;
Var W, X, Y : LongInt;
Begin
  If Banner = '' Then Exit;
  W := Length(Banner) * 16;
  If Length(Banner2) * 8 > W Then W := Length(Banner2) * 8;
  W := W + 28;
  X := (BW - W) Div 2; Y := 170;
  Rect(X, Y, X + W - 1, Y + 58, C_BANNER);
  Rect(X, Y, X + W - 1, Y, C_BANNERE); Rect(X, Y + 58, X + W - 1, Y + 58, C_BANNERE);
  Rect(X, Y, X, Y + 58, C_BANNERE); Rect(X + W - 1, Y, X + W - 1, Y + 58, C_BANNERE);
  FbTextSh(X + (W - Length(Banner) * 16) Div 2, Y + 6, Banner, BannerC, C_BLACK, 2);
  FbText(X + (W - Length(Banner2) * 8) Div 2, Y + 38, Banner2, C_WHITE, 1);
  SprRect(X, Y, X + W - 1, Y + 58);
End;

Procedure DrawSprites;
Var K, X, Y, Sp, Md : LongInt;
Begin
  SprBegin;
  For K := 0 To NBag - 1 Do
    Case BagS[K] Of
      B_REST, B_SLIDE, B_FALL : DrawSpr(SP_SACK, BagX[K], BagY[K], 0, 0, True);
      B_WOB : DrawSpr(SP_SACK, BagX[K] + (BagT[K] Div 2) Mod 3 - 1, BagY[K], 0, 0, True);
      B_GOLD : DrawGold(BagX[K], BagY[K], BagT[K]);
    End;
  If LampOn <> 0 Then DrawLamp(CellX(LairC), CellY(LairR));
  For K := 0 To MaxMon - 1 Do
    If MonA[K] <> 0 Then
      If (MonA[K] = 1) Or ((Tick Div 3) Mod 2 = 0) Then
      Begin
        If MonK[K] = 2 Then Sp := SP_DRILL
        Else If ((MonX[K] + MonY[K]) Div 6) Mod 2 = 0 Then Sp := SP_MOLE1 Else Sp := SP_MOLE2;
        Md := 0;
        If (BonusT > 0) And ((BonusT > 50) Or (Tick Mod 8 < 4)) Then Md := 1;
        DrawSpr(Sp, MonX[K], MonY[K], MonF[K], Md, True);
      End;
  If (State = S_PLAY) Or (State = S_PAUSE) Or (State = S_LEVEL) Or ((State = S_DIE) And (Wait < 24) And (Tick Mod 4 < 2)) Then
    DrawSpr(SP_DIG, PlX, PlY, OrientOf(PFace), 0, True);
  DrawFire;
  For K := 0 To MaxPart - 1 Do
    If QLife[K] > 0 Then
    Begin
      X := QX[K] Div 16; Y := QY[K] Div 16;
      Rect(X, Y, X + 1, Y + 1, QCol[K]);
      SprRect(X, Y, X + 1, Y + 1);
    End;
  BannerDraw;
End;

Procedure BlitAll(H : LongInt);
Var K : LongInt;
Begin
  For K := 0 To NDirty - 1 Do BlitRect(H, DX1[K], DY1[K], DX2[K], DY2[K]);
  NDirty := 0;
End;

{ ==================================================================== }
{ Fenetre                                                               }
{ ==================================================================== }

Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

{ petite excavatrice (vies) }
Procedure LifeIcon(X, Y : LongInt);
Begin
  FBar(X + 1, Y, X + 4, Y + 3, CLR_YELLOW);
  FBar(X, Y + 4, X + 11, Y + 7, CLR_YELLOW);
  FBar(X + 12, Y + 4, X + 14, Y + 7, CLR_DARKGRAY);
  FBar(X, Y + 8, X + 11, Y + 10, CLR_BLACK);
End;

Procedure Gauge(Y, V, VMax, C : LongInt);
Var W : LongInt;
Begin
  Edge(PnX + 72, Y + 2, PnX + PW - 1, Y + 13, CLR_DARKGRAY, CLR_WHITE);
  FBar(PnX + 73, Y + 3, PnX + PW - 2, Y + 12, CLR_WHITE);
  If VMax <= 0 Then Exit;
  W := (PW - 75) * V Div VMax;
  If W > PW - 75 Then W := PW - 75;
  If W > 0 Then FBar(PnX + 73, Y + 3, PnX + 73 + W - 1, Y + 12, C);
End;

Procedure DrawCounters;
Var S : String; K, N : LongInt;
Begin
  FBar(PnX + 2, 30, PnX + PW - 3, 64, CLR_WHITE);
  S := IStr(Score);
  BigText(PnX + PW - 8 - Length(S) * 16, 31, S, CLR_DARKBLUE, CLR_WHITE);
  FBar(PnX, 72, PnX + PW - 1, 206, CLR_PALEGRAY);
  OutTxt(PnX, 72, 'Niveau : ' + IStr(Level), CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 90, 'Vies :', CLR_BLACK, CLR_PALEGRAY);
  For K := 0 To Lives - 1 Do If K < 5 Then LifeIcon(PnX + 52 + K * 18, 93);
  OutTxt(PnX, 108, 'Pierres : ' + IStr(GemsLeft), CLR_BLACK, CLR_PALEGRAY);
  N := 0;
  For K := 0 To MaxMon - 1 Do If MonA[K] <> 0 Then Inc(N);
  OutTxt(PnX, 126, 'Cr' + Chr(130) + 'atures : ' + IStr(MonLeft + N), CLR_BLACK, CLR_PALEGRAY);
  If Best > 0 Then OutTxt(PnX, 144, 'Record : ' + IStr(Best), CLR_DARKRED, CLR_PALEGRAY);
  OutTxt(PnX, 166, 'Tir', CLR_BLACK, CLR_PALEGRAY);
  If (FirOn = 0) And (FireCool = 0) Then Gauge(166, 1, 1, CLR_DARKGREEN)
  Else Gauge(166, FireMax - FireCool, FireMax, CLR_RED);
  If BonusT > 0 Then
  Begin
    OutTxt(PnX, 186, 'Lanterne', CLR_DARKBLUE, CLR_PALEGRAY);
    Gauge(186, BonusT, BonusMax, CLR_BLUE);
  End;
End;

Procedure DrawPanel;
Begin
  OutTxt(PnX, 8, 'Pointage', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, 26, PnX + PW - 1, 68, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, 27, PnX + PW - 2, 67, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, 28, PnX + PW - 3, 66, CLR_WHITE);
  DrawCounters;
  Button(PnX, 214, PW, 28, 'Nouvelle partie');
  Button(PnX, 248, PW, 28, 'Pause');
  OutTxt(PnX, 292, 'Fl' + Chr(138) + 'ches : creuser', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 308, 'Espace : tirer', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 324, 'P : pause', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 340, 'F2 : nouvelle', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 356, 'F1 : r' + Chr(138) + 'gles', CLR_DARKGRAY, CLR_PALEGRAY);
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure PaintAll(H : LongInt);
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(OX - 2, OY - 2, OX + BW + 1, OY + BH + 1, CLR_DARKGRAY, CLR_WHITE);
  Edge(OX - 1, OY - 1, OX + BW, OY + BH, CLR_BLACK, CLR_PALEGRAY);
  DrawSprites;
  NDirty := 0;
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  DrawPanel;
  DrawStatus;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  If Client <> 0 Then Dummy := WinInvalidateRect(Client, 0, 0);
End;

Procedure Frame1(Counters : Boolean);
Begin
  If Client = 0 Then Exit;
  DrawSprites;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  BlitAll(Hps);
  If Counters Then
  Begin
    DrawCounters;
    DrawStatus;
  End;
  Dummy := WinReleasePS(Hps);
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure Show(B1, B2 : String; C : LongInt);
Begin
  Banner := B1; Banner2 := B2; BannerC := C;
End;

Procedure Burst(X, Y, N, C1, C2 : LongInt);
Var K, M : LongInt;
Begin
  M := 0;
  For K := 0 To MaxPart - 1 Do
    If (QLife[K] <= 0) And (M < N) Then
    Begin
      QX[K] := X * 16; QY[K] := Y * 16;
      QVX[K] := Rnd(49) - 24; QVY[K] := Rnd(49) - 30;
      QLife[K] := 8 + Rnd(14);
      If Rnd(2) = 0 Then QCol[K] := C1 Else QCol[K] := C2;
      Inc(M);
    End;
End;

Procedure AddScore(N : LongInt);
Begin
  Score := Score + N;
  If Score >= NextLife Then
  Begin
    NextLife := NextLife + 20000;
    If Lives < 6 Then Inc(Lives);
    Msg := 'Vie suppl' + Chr(130) + 'mentaire !';
  End;
End;

Function GemName : String;
Begin
  Case (Level - 1) Mod 5 Of
    0 : GemName := Chr(130) + 'meraudes';
    1 : GemName := 'rubis';
    2 : GemName := 'saphirs';
    3 : GemName := 'am' + Chr(130) + 'thystes';
  Else
    GemName := 'topazes';
  End;
End;

Procedure PlayMsg;
Begin
  Msg := 'Fl' + Chr(138) + 'ches : creuser, Espace : tirer. Ramassez les ' + GemName + ' !';
End;

Procedure ClearMonsters;
Var K : LongInt;
Begin
  For K := 0 To MaxMon - 1 Do MonA[K] := 0;
End;

Procedure PlacePlayer;
Begin
  PlX := CellX(StartC); PlY := CellY(StartR);
  PLc := StartC; PLr := StartR;
  PDir := 0; PFace := D_RIGHT; Pushing := -1; FirOn := 0; KeyDir := 0; KeyNew := 0;
End;

Procedure StartLevel;
Begin
  BuildLevel;
  ClearMonsters;
  PlacePlayer;
  MonTotal := 5 + Level;
  If MonTotal > 12 Then MonTotal := 12;
  MonLeft := MonTotal; MonKilled := 0; SpawnT := 70;
  FireCool := 0; FireMax := 45 + Level * 5;
  If FireMax > 90 Then FireMax := 90;
  BonusT := 0; LampOn := 0; LampDone := 0;
  BonusMax := 260 - Level * 15;
  If BonusMax < 120 Then BonusMax := 120;
  Chain := 0; ChainT := 0; EatChain := 0;
  State := S_PLAY;
  Show('Niveau ' + IStr(Level), 'Ramassez les ' + GemName + ' !', C_YELLOW);
  Wait := 45;
  PlayMsg;
  Redraw;
End;

Procedure NewGame;
Var K : LongInt;
Begin
  For K := 0 To MaxPart - 1 Do QLife[K] := 0;
  Score := 0; Lives := 3; NextLife := 20000; KeyDir := 0; KeyNew := 0;
  Level := StartLevel0;
  StartLevel;
End;

Procedure GameOver;
Begin
  State := S_OVER;
  If Score > Best Then Best := Score;
  Show('Partie termin' + Chr(130) + 'e', 'Pointage : ' + IStr(Score) + '   F2 : nouvelle partie', C_RED);
  Msg := 'Partie termin' + Chr(130) + 'e. Pointage : ' + IStr(Score) + '. F2 : nouvelle partie.';
  Wait := 0;
  Redraw;
End;

Procedure PlayerDie;
Begin
  If State <> S_PLAY Then Exit;
  Burst(PlX, PlY, 26, C_YEL, C_STEEL);
  Burst(PlX, PlY, 14, C_FIRE, C_FIRED);
  Dec(Lives);
  State := S_DIE; Wait := 0;
  Msg := 'L''excavatrice est d' + Chr(130) + 'truite !';
End;

{ apres la perte d'une vie : creatures au repaire, excavatrice au depart }
Procedure ResetAfterDeath;
Var K : LongInt;
Begin
  For K := 0 To MaxMon - 1 Do
    If MonA[K] <> 0 Then
    Begin
      MonA[K] := 0;
      Inc(MonLeft);
    End;
  For K := 0 To NBag - 1 Do
    If BagS[K] = B_SLIDE Then
    Begin
      BagX[K] := CellX(ColOf(BagX[K]));
      BagS[K] := B_REST;
    End;
  PlacePlayer;
  BonusT := 0; SpawnT := 60;
  State := S_PLAY; Banner := '';
  PlayMsg;
End;

Procedure KillMonster(K, Pts : LongInt);
Begin
  If MonA[K] = 0 Then Exit;
  MonA[K] := 0;
  Inc(MonKilled);
  AddScore(Pts);
  Burst(MonX[K], MonY[K], 18, C_FUR, C_NOSE);
  If (LampDone = 0) And (MonKilled >= MonTotal Div 2) Then
  Begin
    LampOn := 1; LampT := 320; LampDone := 1;
    Msg := 'Une lanterne est apparue au repaire !';
  End;
End;

Procedure Fire;
Begin
  If (State <> S_PLAY) Or (FirOn <> 0) Or (FireCool > 0) Then Exit;
  FirOn := 1; FirX := PlX; FirY := PlY;
  If PDir <> 0 Then FirD := PDir Else FirD := PFace;
  FireCool := FireMax;
End;

{ case (C, R) atteinte par l'excavatrice : pierre ou or }
Procedure EnterCell(C, R : LongInt);
Var K : LongInt;
Begin
  If Not InGrid(C, R) Then Exit;
  If Gem[CI(C, R)] <> 0 Then
  Begin
    Gem[CI(C, R)] := 0;
    Dec(GemsLeft);
    RemoveGem(C, R);
    AddScore(25);
    Burst(CellX(C), CellY(R), 6, C_GEML, C_WHITE);
    If ChainT > 0 Then Inc(Chain) Else Chain := 1;
    ChainT := 40;
    If Chain >= 8 Then
    Begin
      AddScore(250);
      Chain := 0;
      Msg := 'Huit pierres de suite : 250 points de plus !';
      Burst(CellX(C), CellY(R), 16, C_YELLOW, C_WHITE);
    End;
  End;
  K := GoldAt(C, R);
  If K >= 0 Then
  Begin
    BagS[K] := B_NONE;
    AddScore(500);
    Burst(BagX[K], BagY[K], 14, C_GOLD, C_GOLDL);
    Msg := 'Or ramass' + Chr(130) + ' : 500 points.';
  End;
End;

{ l'excavatrice peut-elle aller de (C, R) vers D (en poussant un sac) ? }
Function CanGo(C, R, D : LongInt) : Boolean;
Var Nc, Nr, Fc, K : LongInt;
Begin
  CanGo := False;
  Nc := C + DirX(D); Nr := R + DirY(D);
  If Not InGrid(Nc, Nr) Then Exit;
  K := BagAt(Nc, Nr, -1);
  If K < 0 Then
  Begin
    CanGo := True;
    Exit;
  End;
  If ((D = D_LEFT) Or (D = D_RIGHT)) And ((BagS[K] = B_REST) Or (BagS[K] = B_WOB)) Then
  Begin
    Fc := Nc + DirX(D);
    If InGrid(Fc, Nr) And (BagAt(Fc, Nr, K) < 0) And (Gem[CI(Fc, Nr)] = 0) And ((Fc <> LairC) Or (Nr <> LairR)) Then
    Begin
      BagS[K] := B_SLIDE; BagD[K] := D; Pushing := K;
      CanGo := True;
    End;
  End;
End;

Procedure PlayerPx;
Var C, R, Oc, Or2, K : LongInt;
Begin
  If OnCenter(PlX, PlY) Then
  Begin
    C := ColOf(PlX); R := RowOf(PlY);
    If (C <> PLc) Or (R <> PLr) Then
    Begin
      OpenBetween(PLc, PLr, C, R);
      PLc := C; PLr := R;
    End;
    Dug[CI(C, R)] := 1;
    Pushing := -1;
    { Presentation Manager ne signale pas le relachement des touches :
      chaque appui fait avancer d'une case, la repetition automatique
      d'une touche tenue fait continuer }
    If PWant <> 0 Then
    Begin
      PFace := PWant;
      If (AutoAll = 0) And (KeyNew = 0) Then PDir := 0
      Else
      Begin
        KeyNew := 0;
        If CanGo(C, R, PWant) Then PDir := PWant Else PDir := 0;
      End;
    End
    Else PDir := 0;
  End
  Else If (PWant <> 0) And (PWant = RevDir(PDir)) And (Pushing < 0) Then
  Begin
    PDir := PWant; PFace := PWant;
  End;
  If PDir = 0 Then Exit;
  Oc := ColOf(PlX); Or2 := RowOf(PlY);
  PlX := PlX + DirX(PDir); PlY := PlY + DirY(PDir);
  If Pushing >= 0 Then
  Begin
    K := Pushing;
    BagX[K] := BagX[K] + DirX(PDir);
    Carve(BagX[K], BagY[K]);
    If OnCenter(BagX[K], BagY[K]) Then
    Begin
      OpenBetween(ColOf(BagX[K]) - DirX(PDir), RowOf(BagY[K]), ColOf(BagX[K]), RowOf(BagY[K]));
      BagS[K] := B_REST;
      Pushing := -1;
    End;
  End;
  Carve(PlX, PlY);
  If (ColOf(PlX) <> Oc) Or (RowOf(PlY) <> Or2) Then EnterCell(ColOf(PlX), RowOf(PlY));
End;

{ sac sans appui : la case du dessous est creusee et vide }
Function BagLoose(K : LongInt) : Boolean;
Var C, R : LongInt;
Begin
  BagLoose := False;
  C := ColOf(BagX[K]); R := RowOf(BagY[K]);
  If R >= GR - 1 Then Exit;
  If Dug[CI(C, R + 1)] = 0 Then Exit;
  If BagAt(C, R + 1, K) >= 0 Then Exit;
  BagLoose := True;
End;

Procedure BagFallPx(K : LongInt);
Var C, R, J : LongInt;
Begin
  BagY[K] := BagY[K] + 1;
  Carve(BagX[K], BagY[K]);
  For J := 0 To MaxMon - 1 Do
    If MonA[J] <> 0 Then
      If (Abs(MonX[J] - BagX[K]) < 20) And (MonY[J] - BagY[K] >= 0) And (MonY[J] - BagY[K] < 26) Then
      Begin
        KillMonster(J, 250);
        Msg := 'Une cr' + Chr(130) + 'ature est ' + Chr(130) + 'cras' + Chr(130) + 'e : 250 points.';
      End;
  If (State = S_PLAY) And (Abs(PlX - BagX[K]) < 20) And (PlY - BagY[K] >= 0) And (PlY - BagY[K] < 26) Then
  Begin
    PlayerDie;
    Msg := 'L''excavatrice est ' + Chr(130) + 'cras' + Chr(130) + 'e par un sac !';
  End;
  If OnCenter(BagX[K], BagY[K]) Then
  Begin
    C := ColOf(BagX[K]); R := RowOf(BagY[K]);
    OpenBetween(C, R - 1, C, R);
    If (R >= GR - 1) Or (Dug[CI(C, R + 1)] = 0) Or (BagAt(C, R + 1, K) >= 0) Then
    Begin
      If R - BagF[K] >= 2 Then
      Begin
        BagS[K] := B_GOLD; BagT[K] := 240;
        Burst(BagX[K], BagY[K] + 6, 12, C_GOLD, C_DUST);
      End
      Else
      Begin
        BagS[K] := B_REST;
        Burst(BagX[K], BagY[K] + 10, 6, C_DUST, C_SACKD);
      End;
    End;
  End;
End;

Procedure BagsStep;
Var K, J, C, R : LongInt;
Begin
  For K := 0 To NBag - 1 Do
    Case BagS[K] Of
      B_REST :
        If (K <> Pushing) And BagLoose(K) Then
        Begin
          BagS[K] := B_WOB; BagT[K] := 22;
        End;
      B_WOB :
        If Not BagLoose(K) Then BagS[K] := B_REST
        Else
        Begin
          Dec(BagT[K]);
          { il ne tombe pas tant que l'excavatrice est juste dessous }
          C := ColOf(BagX[K]); R := RowOf(BagY[K]);
          If (ColOf(PlX) = C) And (RowOf(PlY) = R + 1) And (BagT[K] < 8) Then BagT[K] := 8;
          If BagT[K] <= 0 Then
          Begin
            BagS[K] := B_FALL; BagF[K] := R;
          End;
        End;
      B_FALL :
        For J := 1 To 5 Do If BagS[K] = B_FALL Then BagFallPx(K);
      B_GOLD :
        Begin
          Dec(BagT[K]);
          If BagT[K] <= 0 Then BagS[K] := B_NONE;
        End;
    End;
End;

{ distances (en cases, par les galeries) de chaque case a l'excavatrice }
Procedure ComputeDist;
Var H, T, I, C, R, D, Nc, Nr, N : LongInt;
Begin
  For I := 0 To NCell - 1 Do Dist[I] := 9999;
  C := ColOf(PlX); R := RowOf(PlY);
  H := 0; T := 0;
  Dist[CI(C, R)] := 0; Que[T] := CI(C, R); Inc(T);
  While H < T Do
  Begin
    I := Que[H]; Inc(H);
    C := I Mod GC; R := I Div GC;
    For D := 1 To 4 Do
      If EdgeOpen(C, R, D) Then
      Begin
        Nc := C + DirX(D); Nr := R + DirY(D);
        N := CI(Nc, Nr);
        If (Dist[N] = 9999) And (BagAt(Nc, Nr, -1) < 0) Then
        Begin
          Dist[N] := Dist[I] + 1;
          Que[T] := N; Inc(T);
        End;
      End;
  End;
End;

Function NumAlive : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To MaxMon - 1 Do If MonA[K] <> 0 Then Inc(N);
  NumAlive := N;
End;

Function NumDrill : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To MaxMon - 1 Do If (MonA[K] <> 0) And (MonK[K] = 2) Then Inc(N);
  NumDrill := N;
End;

{ direction d'une taupe : par les galeries, vers l'excavatrice (ou loin
  d'elle quand la lanterne effraie les creatures) }
Function MoleChoose(K, C, R : LongInt) : LongInt;
Var D, N, Best0, Bd, V, Rev : LongInt; Cand : Array[0..3] Of LongInt;
Begin
  N := 0;
  For D := 1 To 4 Do
    If EdgeOpen(C, R, D) And (BagAt(C + DirX(D), R + DirY(D), -1) < 0) Then
    Begin
      Cand[N] := D; Inc(N);
    End;
  MoleChoose := 0;
  If N = 0 Then Exit;
  Rev := RevDir(MonD[K]);
  If N > 1 Then
  Begin
    D := 0;
    While D < N Do
      If Cand[D] = Rev Then
      Begin
        Cand[D] := Cand[N - 1]; Dec(N);
      End
      Else Inc(D);
  End;
  If Rnd(100) < 15 Then
  Begin
    MoleChoose := Cand[Rnd(N)];
    Exit;
  End;
  Best0 := Cand[0];
  If BonusT > 0 Then Bd := -1 Else Bd := 99999;
  For D := 0 To N - 1 Do
  Begin
    V := Dist[CI(C + DirX(Cand[D]), R + DirY(Cand[D]))];
    If BonusT > 0 Then
    Begin
      If V = 9999 Then V := 500;
      If V > Bd Then Begin Bd := V; Best0 := Cand[D]; End;
    End
    Else If V < Bd Then Begin Bd := V; Best0 := Cand[D]; End;
  End;
  If (BonusT = 0) And (Bd >= 9999) Then Best0 := Cand[Rnd(N)];
  MoleChoose := Best0;
End;

{ direction d'une foreuse : tout droit vers l'excavatrice, en creusant }
Function DrillChoose(K, C, R : LongInt) : LongInt;
Var Dx, Dy, D1, D2, I, D, Nc, Nr : LongInt; Ord0 : Array[0..3] Of LongInt;
Begin
  Dx := ColOf(PlX) - C; Dy := RowOf(PlY) - R;
  If BonusT > 0 Then Begin Dx := -Dx; Dy := -Dy; End;
  If Dx < 0 Then D1 := D_LEFT Else D1 := D_RIGHT;
  If Dy < 0 Then D2 := D_UP Else D2 := D_DOWN;
  If Abs(Dx) >= Abs(Dy) Then
  Begin
    Ord0[0] := D1; Ord0[1] := D2; Ord0[2] := RevDir(D2); Ord0[3] := RevDir(D1);
  End
  Else
  Begin
    Ord0[0] := D2; Ord0[1] := D1; Ord0[2] := RevDir(D1); Ord0[3] := RevDir(D2);
  End;
  If Dx = 0 Then Ord0[1] := Ord0[0];
  DrillChoose := 0;
  For I := 0 To 3 Do
  Begin
    D := Ord0[I];
    Nc := C + DirX(D); Nr := R + DirY(D);
    If InGrid(Nc, Nr) And (BagAt(Nc, Nr, -1) < 0) Then
    Begin
      DrillChoose := D;
      Exit;
    End;
  End;
End;

Procedure MonPx(K : LongInt);
Var C, R, Oc, Or2 : LongInt;
Begin
  If OnCenter(MonX[K], MonY[K]) Then
  Begin
    C := ColOf(MonX[K]); R := RowOf(MonY[K]);
    If (C <> MonLc[K]) Or (R <> MonLr[K]) Then
    Begin
      If MonK[K] = 2 Then OpenBetween(MonLc[K], MonLr[K], C, R);
      MonLc[K] := C; MonLr[K] := R;
    End;
    { une taupe devient foreuse un moment (a partir du niveau 2), ou
      quand aucune galerie ne la mene a l'excavatrice }
    If (MonK[K] = 1) And (BonusT = 0) And
       (((Dist[CI(C, R)] >= 9999) And (MonT[K] > 100)) Or
        ((Level >= 2) And (MonT[K] > 150) And (NumDrill = 0) And (Rnd(90) = 0))) Then
    Begin
      MonK[K] := 2; MonT[K] := 0;
    End
    Else If (MonK[K] = 2) And (MonT[K] > 170) And (Dist[CI(C, R)] < 9999) Then
    Begin
      MonK[K] := 1; MonT[K] := 0;
    End;
    If MonK[K] = 2 Then
    Begin
      Dug[CI(C, R)] := 1;
      MonD[K] := DrillChoose(K, C, R);
    End
    Else MonD[K] := MoleChoose(K, C, R);
  End;
  If MonD[K] = 0 Then Exit;
  Oc := ColOf(MonX[K]); Or2 := RowOf(MonY[K]);
  MonX[K] := MonX[K] + DirX(MonD[K]); MonY[K] := MonY[K] + DirY(MonD[K]);
  If MonD[K] = D_LEFT Then MonF[K] := 1 Else If MonD[K] = D_RIGHT Then MonF[K] := 0;
  If MonK[K] = 2 Then
  Begin
    Carve(MonX[K], MonY[K]);
    C := ColOf(MonX[K]); R := RowOf(MonY[K]);
    If ((C <> Oc) Or (R <> Or2)) And (Gem[CI(C, R)] <> 0) Then
    Begin
      Gem[CI(C, R)] := 0;
      Dec(GemsLeft);
      RemoveGem(C, R);
    End;
  End;
End;

Procedure MonstersStep;
Var K, Spd, MaxAlive : LongInt;
Begin
  { sorties du repaire }
  MaxAlive := 2 + Level Div 2;
  If MaxAlive > 5 Then MaxAlive := 5;
  If SpawnT > 0 Then Dec(SpawnT);
  If (MonLeft > 0) And (SpawnT <= 0) And (NumAlive < MaxAlive) And (BagAt(LairC, LairR, -1) < 0) Then
  Begin
    K := 0;
    While (K < MaxMon) And (MonA[K] <> 0) Do Inc(K);
    If K < MaxMon Then
    Begin
      MonX[K] := CellX(LairC); MonY[K] := CellY(LairR);
      MonA[K] := 2; MonT[K] := 0; MonK[K] := 1; MonD[K] := 0; MonAcc[K] := 0; MonF[K] := 1;
      MonLc[K] := LairC; MonLr[K] := LairR;
      Dec(MonLeft);
      SpawnT := 80 - Level * 5;
      If SpawnT < 30 Then SpawnT := 30;
    End;
  End;
  For K := 0 To MaxMon - 1 Do
    If MonA[K] <> 0 Then
    Begin
      Inc(MonT[K]);
      If MonA[K] = 2 Then
      Begin
        If MonT[K] > 30 Then Begin MonA[K] := 1; MonT[K] := 0; End;
      End
      Else
      Begin
        Spd := 8 + Level;
        If Spd > 13 Then Spd := 13;
        If MonK[K] = 2 Then Spd := Spd - 2;
        If BonusT > 0 Then Spd := Spd - 3;
        MonAcc[K] := MonAcc[K] + Spd;
        While (MonAcc[K] >= 4) And (MonA[K] <> 0) Do
        Begin
          MonAcc[K] := MonAcc[K] - 4;
          MonPx(K);
        End;
      End;
    End;
End;

Procedure FireStep;
Var J, K, C, R : LongInt;
Begin
  If FirOn = 0 Then Exit;
  For J := 1 To 6 Do
  Begin
    If OnCenter(FirX, FirY) Then
    Begin
      C := ColOf(FirX); R := RowOf(FirY);
      If Not EdgeOpen(C, R, FirD) Or (BagAt(C + DirX(FirD), R + DirY(FirD), -1) >= 0) Then
      Begin
        FirOn := 0;
        Burst(FirX, FirY, 6, C_FIRE, C_FIRED);
        Exit;
      End;
    End;
    FirX := FirX + DirX(FirD); FirY := FirY + DirY(FirD);
    For K := 0 To MaxMon - 1 Do
      If (MonA[K] = 1) And (Abs(MonX[K] - FirX) + Abs(MonY[K] - FirY) < 18) Then
      Begin
        KillMonster(K, 250);
        FirOn := 0;
        Burst(FirX, FirY, 8, C_FIRE, C_FIREC);
        Exit;
      End;
  End;
End;

Procedure Collide;
Var K, Pts : LongInt;
Begin
  For K := 0 To MaxMon - 1 Do
    If (State = S_PLAY) And (MonA[K] = 1) And (Abs(MonX[K] - PlX) + Abs(MonY[K] - PlY) < 20) Then
    Begin
      If BonusT > 0 Then
      Begin
        Pts := 200 Shl MinX(EatChain, 3);
        Inc(EatChain);
        KillMonster(K, Pts);
        Msg := 'Cr' + Chr(130) + 'ature attrap' + Chr(130) + 'e : ' + IStr(Pts) + ' points.';
      End
      Else
      Begin
        PlayerDie;
        Msg := 'L''excavatrice a ' + Chr(130) + 't' + Chr(130) + ' attrap' + Chr(130) + 'e !';
      End;
    End;
  If (LampOn <> 0) And (State = S_PLAY) And (Abs(CellX(LairC) - PlX) + Abs(CellY(LairR) - PlY) < 20) Then
  Begin
    LampOn := 0;
    BonusT := BonusMax; EatChain := 0;
    AddScore(100);
    Show('Lanterne !', 'Les cr' + Chr(130) + 'atures ont peur : attrapez-les !', C_LAMP);
    Wait := 40;
    Msg := 'Lanterne : attrapez les cr' + Chr(130) + 'atures !';
  End;
End;

Procedure CheckLevel;
Begin
  If State <> S_PLAY Then Exit;
  If (GemsLeft <= 0) Or ((MonLeft = 0) And (NumAlive = 0) And (MonKilled >= MonTotal)) Then
  Begin
    AddScore(500);
    State := S_LEVEL; Wait := 0;
    Show('Niveau ' + IStr(Level) + ' termin' + Chr(130), 'Bonus : 500 points', C_GREEN);
    Msg := 'Niveau termin' + Chr(130) + ' !';
  End;
End;

{ ==================================================================== }
{ Demonstration (/AUTO)                                                 }
{ ==================================================================== }

Function NearMonster(C, R : LongInt) : Boolean;
Var K : LongInt;
Begin
  NearMonster := False;
  For K := 0 To MaxMon - 1 Do
    If MonA[K] <> 0 Then
      If Abs(ColOf(MonX[K]) - C) + Abs(RowOf(MonY[K]) - R) <= 1 Then
      Begin
        NearMonster := True;
        Exit;
      End;
End;

Function IsTarget(C, R : LongInt) : Boolean;
Begin
  IsTarget := (Gem[CI(C, R)] <> 0) Or (GoldAt(C, R) >= 0) Or ((LampOn <> 0) And (C = LairC) And (R = LairR));
End;

{ chemin le plus court (en creusant) vers une pierre, de l'or ou la
  lanterne ; Strict : eviter aussi les cases sous un sac }
Function AutoPath(C0, R0 : LongInt; Strict : Boolean) : LongInt;
Var H, T, I, C, R, D, Nc, Nr, N, Found : LongInt; Ok : Boolean;
Begin
  AutoPath := 0;
  For I := 0 To NCell - 1 Do Par[I] := -1;
  H := 0; T := 0;
  Par[CI(C0, R0)] := CI(C0, R0); Que[T] := CI(C0, R0); Inc(T);
  Found := -1;
  While (H < T) And (Found < 0) Do
  Begin
    I := Que[H]; Inc(H);
    C := I Mod GC; R := I Div GC;
    For D := 1 To 4 Do
    Begin
      Nc := C + DirX(D); Nr := R + DirY(D);
      If InGrid(Nc, Nr) And (Found < 0) Then
      Begin
        N := CI(Nc, Nr);
        Ok := (Par[N] < 0) And (BagAt(Nc, Nr, -1) < 0);
        If Ok And (BonusT = 0) And NearMonster(Nc, Nr) Then Ok := False;
        If Ok And Strict And (Nr > 0) And (BagAt(Nc, Nr - 1, -1) >= 0) Then Ok := False;
        If Ok Then
        Begin
          Par[N] := I;
          Que[T] := N; Inc(T);
          If IsTarget(Nc, Nr) Then Found := N;
        End;
      End;
    End;
  End;
  If Found < 0 Then Exit;
  N := Found;
  While Par[N] <> CI(C0, R0) Do N := Par[N];
  C := N Mod GC; R := N Div GC;
  If C < C0 Then AutoPath := D_LEFT
  Else If C > C0 Then AutoPath := D_RIGHT
  Else If R < R0 Then AutoPath := D_UP
  Else AutoPath := D_DOWN;
End;

Procedure AutoPlay;
Var C, R, D, K, N, Cc, Rr, Best0, Bd, V : LongInt; Hit : Boolean;
Begin
  If Not OnCenter(PlX, PlY) Then Exit;
  C := ColOf(PlX); R := RowOf(PlY);
  { tirer sur une creature dans l'axe d'une galerie }
  If (FirOn = 0) And (FireCool = 0) Then
    For D := 1 To 4 Do
    Begin
      Cc := C; Rr := R; Hit := False;
      For N := 1 To 6 Do
        If Not Hit And EdgeOpen(Cc, Rr, D) Then
        Begin
          Cc := Cc + DirX(D); Rr := Rr + DirY(D);
          For K := 0 To MaxMon - 1 Do
            If (MonA[K] = 1) And (ColOf(MonX[K]) = Cc) And (RowOf(MonY[K]) = Rr) Then Hit := True;
        End;
      If Hit And (FirOn = 0) Then
      Begin
        PFace := D; PDir := 0;
        Fire;
      End;
    End;
  D := AutoPath(C, R, True);
  If D = 0 Then D := AutoPath(C, R, False);
  If D = 0 Then
  Begin
    { rien a atteindre sans danger : s'eloigner des creatures }
    Best0 := 0; Bd := -1;
    For K := 1 To 4 Do
      If InGrid(C + DirX(K), R + DirY(K)) And (BagAt(C + DirX(K), R + DirY(K), -1) < 0) Then
      Begin
        V := 99;
        For N := 0 To MaxMon - 1 Do
          If MonA[N] <> 0 Then
            V := MinX(V, Abs(ColOf(MonX[N]) - C - DirX(K)) + Abs(RowOf(MonY[N]) - R - DirY(K)));
        If V > Bd Then Begin Bd := V; Best0 := K; End;
      End;
    D := Best0;
  End;
  PWant := D;
End;

{ ==================================================================== }
{ Pas de jeu                                                            }
{ ==================================================================== }

Procedure Step;
Var K : LongInt;
Begin
  Inc(Tick);
  For K := 0 To MaxPart - 1 Do
    If QLife[K] > 0 Then
    Begin
      Dec(QLife[K]);
      QX[K] := QX[K] + QVX[K]; QY[K] := QY[K] + QVY[K];
      QVY[K] := QVY[K] + 3;
    End;
  If State = S_DIE Then
  Begin
    BagsStep;
    Exit;
  End;
  If State <> S_PLAY Then Exit;
  If FireCool > 0 Then Dec(FireCool);
  If ChainT > 0 Then Dec(ChainT);
  If BonusT > 0 Then
  Begin
    Dec(BonusT);
    If BonusT = 0 Then PlayMsg;
  End;
  If LampOn <> 0 Then
  Begin
    Dec(LampT);
    If LampT <= 0 Then LampOn := 0;
  End;
  ComputeDist;
  If AutoAll <> 0 Then AutoPlay Else PWant := KeyDir;
  For K := 1 To 3 Do If State = S_PLAY Then PlayerPx;
  If State <> S_PLAY Then Exit;
  BagsStep;
  If State <> S_PLAY Then Exit;
  MonstersStep;
  FireStep;
  Collide;
  CheckLevel;
End;

Procedure TimerTick;
Var C : Boolean;
Begin
  If State = S_PAUSE Then Exit;
  C := False;
  Step;
  Case State Of
    S_PLAY :
      If Wait > 0 Then
      Begin
        Dec(Wait);
        If Wait = 0 Then Banner := '';
      End;
    S_DIE :
      Begin
        Inc(Wait);
        If Wait > 50 Then
        Begin
          If Lives <= 0 Then
          Begin
            Lives := 0;
            GameOver;
          End
          Else ResetAfterDeath;
          C := True;
        End;
      End;
    S_LEVEL :
      Begin
        Inc(Wait);
        If Wait > 60 Then
        Begin
          Inc(Level);
          StartLevel;
          Exit;
        End;
      End;
    S_OVER :
      If AutoAll <> 0 Then
      Begin
        Inc(Wait);
        If Wait > 60 Then NewGame;
      End;
  End;
  If Tick Mod 5 = 0 Then C := True;
  Frame1(C);
End;

Procedure TogglePause;
Begin
  If State = S_PLAY Then
  Begin
    State := S_PAUSE;
    Show('Pause', 'P ou Espace : reprendre', C_GREEN);
    Msg := 'Pause.';
    Frame1(True);
  End
  Else If State = S_PAUSE Then
  Begin
    State := S_PLAY; Banner := '';
    PlayMsg;
    Frame1(True);
  End;
End;

Procedure SetMark(Id : LongInt; On : Boolean);
Var M : LongInt;
Begin
  M := WinWindowFromID(Frame, $8005);
  If M = 0 Then Exit;
  If On Then Dummy := WinSendMsg(M, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16))
  Else Dummy := WinSendMsg(M, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED);
End;

Procedure SetSpeed(Ms : LongInt);
Begin
  SpeedMs := Ms;
  SetMark(CM_SLOW, Ms = 55); SetMark(CM_NORMAL, Ms = 40); SetMark(CM_FAST, Ms = 30);
  If Client <> 0 Then Dummy := WinStartTimer(Hab, Client, 1, SpeedMs);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_PAUSE : TogglePause;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_SLOW : SetSpeed(55);
    CM_NORMAL : SetSpeed(40);
    CM_FAST : SetSpeed(30);
    CM_RULES :
      Begin
        If State = S_PLAY Then TogglePause;
        LClr;
        LAdd('Votre excavatrice creuse des galeries l' + Chr(133) + ' o' + Chr(151) + ' elle va et ramasse les ' +
             'pierres pr' + Chr(130) + 'cieuses (25 points ; huit ' + Chr(133) + ' la suite : 250 de plus). ');
        LAdd('Le niveau est fini quand toutes les pierres sont prises, ou toutes les cr' + Chr(130) + 'atures ' +
             'vaincues.' + Chr(10) + Chr(10));
        LAdd('Un sac d''or que plus rien ne soutient se balance puis tombe ; s''il tombe de deux ' + Chr(130) +
             'tages ou plus, il s''ouvre : l''or vaut 500 points. ');
        LAdd('Un sac qui tombe ' + Chr(130) + 'crase ce qui est dessous (250 points par cr' + Chr(130) +
             'ature). Un sac se pousse ' + Chr(133) + ' gauche ou ' + Chr(133) + ' droite.' + Chr(10) + Chr(10));
        LAdd('Les taupes sortent du repaire et suivent les galeries ; certaines deviennent des foreuses qui ' +
             'creusent et mangent les pierres. ');
        LAdd('Le tir (Espace) part dans la galerie (250 points) et doit se recharger. ');
        LAdd('La lanterne, qui para' + Chr(140) + 't au repaire quand la moiti' + Chr(130) + ' des ' +
             'cr' + Chr(130) + 'atures sont vaincues, les effraie un moment : attrapez-les (200, 400, 800, ' +
             '1600 points).' + Chr(10) + Chr(10));
        LAdd('Trois vies, une de plus tous les 20000 points. Clavier : fl' + Chr(138) + 'ches (creuser), ' +
             'Espace (tirer), P (pause), F2 (nouvelle partie). Menu Options : vitesse du jeu.');
        Dummy := LMsgBox('Excavateur - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Excavateur pour OS/2-0 (Presentation Manager) : creusez, ramassez les pierres ' +
                            'pr' + Chr(130) + 'cieuses et l''or, ' + Chr(130) + 'chappez aux taupes.' + Chr(10) +
                            'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) + ' par OS2PC.',
                            'A propos d''Excavateur', MB_OK Or MB_INFORMATION);
  End;
End;

Function KeyDirOf(Vk : LongInt) : LongInt;
Begin
  Case Vk Of
    VK_LEFT : KeyDirOf := D_LEFT;
    VK_RIGHT : KeyDirOf := D_RIGHT;
    VK_UP : KeyDirOf := D_UP;
    VK_DOWN : KeyDirOf := D_DOWN;
  Else
    KeyDirOf := 0;
  End;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk, D : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Fl And (KC_CTRL Or KC_ALT)) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If Vk = VK_PAUSE Then Begin TogglePause; Exit; End;
    D := KeyDirOf(Vk);
    If D <> 0 Then
    Begin
      KeyDir := D; KeyNew := 1;
      If State = S_PAUSE Then TogglePause;
      Exit;
    End;
    If Vk = VK_SPACE Then
    Begin
      If State = S_PLAY Then Fire
      Else If State = S_PAUSE Then TogglePause
      Else If State = S_OVER Then NewGame;
      Exit;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'P' : TogglePause;
      'N' : NewGame;
      ' ' : If State = S_PLAY Then Fire Else If State = S_PAUSE Then TogglePause;
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 214) And (Y < 242) Then NewGame
    Else If (Y >= 248) And (Y < 276) Then TogglePause;
    Exit;
  End;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    If State = S_PLAY Then Fire
    Else If State = S_PAUSE Then TogglePause
    Else If State = S_OVER Then NewGame;
  End;
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
  Fl, H0, H1, H2, H3, Sw, Sh, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; AutoAll := 0; Banner := ''; Banner2 := ''; NSpr := 0; NDirty := 0; Best := 0; Tick := 0;
  Client := 0; Lives := 3; Level := 1; StartLevel0 := 1; State := S_PLAY; SpeedMs := 40; KeyDir := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) > 6) And ((Copy(S, 1, 6) = '/SEED:') Or (Copy(S, 1, 6) = '/seed:')) Then
      Val(Copy(S, 7, 20), Seed, E);
    If (Length(S) > 7) And ((Copy(S, 1, 7) = '/LEVEL:') Or (Copy(S, 1, 7) = '/level:')) Then
    Begin
      Val(Copy(S, 8, 20), StartLevel0, E);
      If (StartLevel0 < 1) Or (StartLevel0 > 99) Then StartLevel0 := 1;
    End;
    If (S = '/AUTO') Or (S = '/auto') Then AutoAll := 1;
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  InitBmi;
  For K := 0 To MaxPart - 1 Do QLife[K] := 0;
  For K := 0 To MaxMon - 1 Do MonA[K] := 0;
  RenderGround;
  Dummy := WinRegisterClass(Hab, Z('EXCAVAT'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('EXCAVAT'), Z2('Excavateur'),
                              0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_PAUSE, '~Pause' + Chr(9) + 'P');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 4);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_SLOW, 'Vitesse ~lente');
  MItem(MIS_TEXT, MIA_CHECKED, CM_NORMAL, 'Vitesse ~normale');
  MItem(MIS_TEXT, 0, CM_FAST, 'Vitesse ~rapide');
  MenuClose(H3, 3);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos d''Excavateur');
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
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  NewGame;
  Dummy := WinStartTimer(Hab, Client, 1, SpeedMs);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
