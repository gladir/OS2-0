{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: PLOMBIER - Le Plombier, jeu de plateformes a un seul ecran
                (genre des jeux d'arcade de 1983) pour le Presentation
                Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program PLOMBIER;

{$R-,S-,I-}

{ Compilation : OS2PC PLOMBIER.PAS   (produit PLOMBIER.EXE)

  Realisation pour OS/2-0 a partir du prototype inacheve MARIO.PAS du
  depot 7iles (Turbo Pascal, BGI en 640 x 480 avec un monde de 320 x 200
  agrandi deux fois, clavier seulement). Le jeu est entierement redessine :
  le heros s'appelle Lorenzo (chandail gris, salopette ocre, casquette
  sarcelle), tous les personnages, les tuyaux, les plateformes, le bloc
  POW et les bruitages sont des dessins et des sons originaux ; aucune
  image du prototype n'est reprise. Fenetre de Presentation Manager avec
  menus, image en memoire de 600 x 400 (8 bits, palette en vraies
  couleurs) recopiee par GpiDrawBits (seules les bandes de l'image qui
  changent sont recopiees), animation reguliere sur minuterie (WM_TIMER,
  33 images par seconde), barre d'etat et apparence d'OS/2 Warp 3.

  Le jeu : deux tuyaux en haut a gauche et a droite (bleu acier) d'ou
  sortent a tour de role les ennemis de la phase ; trois etages de
  plateformes (en haut 13 + 13 carres, au milieu 3 + 16 + 3 carres, en bas
  11 + 11 carres separes par le bloc POW) au-dessus du plancher de
  briques rouges ; deux tuyaux de retour gris en bas : un ennemi arrive au
  plancher y rentre et ressort par le tuyau du haut du meme cote.
  Lorenzo frappe le dessous d'une plateforme en sautant : l'ennemi qui est
  au-dessus se retourne ; on l'elimine en le touchant avant qu'il se
  releve (il se releve alors plus rapide et change de couleur). Une phase
  est terminee quand tous ses ennemis sont elimines (le verglas et les
  pieces ne comptent pas).
  Les ennemis : tortue (un coup) ; crabe (le premier coup le met en
  colere, le second le retourne) ; mouche combattante (avance par bonds,
  on ne la retourne que si elle touche la plateforme) ; rat (petit et
  rapide, fait demi-tour au hasard et sautille ; un coup) ; crocodile
  (lent mais deux fois plus fort qu'une tortue : le premier coup le
  blesse, il s'arrete et claque des machoires, le second le retourne ; le
  bloc POW ne compte que pour un coup) ; verglas (glacon detruit par un
  coup par-dessous ; s'il atteint le milieu d'une plateforme, il la gele
  et elle devient glissante) ; pieces (bonus en les touchant ou en
  frappant par-dessous ; une piece sort d'un tuyau apres chaque ennemi
  elimine).
  Le bloc POW (3 coups par phase, il rapetisse puis disparait) retourne
  tous les ennemis qui sont au sol. Clefs de plombier : une clef a
  molette apparait parfois sur le plancher ; Lorenzo la ramasse en la
  touchant et la depose sur une plateforme du haut (1000 points, 2000
  pour la deuxieme... jusqu'a 5000) ; ce n'est pas requis pour finir la
  phase. Phases 4 et 9 : phases bonus chronometrees (20 secondes, 10
  pieces immobiles, 2 en haut, 4 au milieu, 2 en bas, 2 sur le plancher ;
  plancher glissant a la phase 9). Apres la phase 10, les phases
  reprennent dans le meme ordre, 15 % plus vite a chaque tour.
  Pointage : 10 par ennemi retourne ; 800 pour un ennemi elimine, 1600,
  2400 puis 3200 s'ils sont elimines a la suite ; 800 par piece ; 500 par
  verglas detruit ; 5000 (phase 4) ou 8000 (phase 9) pour les 10 pieces
  d'une phase bonus ; 3 vies, une vie de plus a 20 000 points.

  Ce qui est corrige par rapport au prototype : les plateformes (8 bandes
  unies mal placees) suivent maintenant le cahier des charges ; les
  tuyaux etaient verts et les ennemis arrives en bas disparaissaient au
  lieu de ressortir en haut ; le saut etait une montee a vitesse
  constante (DY = -2) jusqu'au plafond, sans gravite ; le coup de tete
  retournait tous les ennemis de la meme hauteur sur toute la largeur de
  l'ecran et les etourdissait 30 secondes ; le POW retournait aussi les
  ennemis en l'air et inversait leur direction ; les ennemis n'etaient
  jamais dangereux (aucune vie, aucune fin de phase) ; un ennemi naissait
  toutes les 32 images, jusqu'a 31 a la fois ; le pointage donnait 100
  points a chaque ennemi sortant par un tuyau ; le fond etait sauve par
  GetImage et restaure par PutImage (scintillement, decor abime) ;
  Delay(40) liait la vitesse a l'ordinateur ; Ctrl+L changeait de niveau
  sans fin de phase.
  Ce qui s'ajoute : vies, phases (cahier des charges : 10 phases puis
  reprise plus rapide), crocodiles, rats, verglas qui gele les
  plateformes, plateformes glissantes (inertie de Lorenzo), pieces apres
  chaque ennemi elimine, ennemis elimines a la suite, phases bonus, clefs
  de plombier, nacelle de retour apres une vie perdue, bloc POW qui
  rapetisse, plateformes qui ondulent sous le coup, couleurs des
  plateformes changeant selon la phase, meilleur pointage de la seance,
  pause, demonstration (l'ordinateur joue en essayant chaque action sur
  une seconde de jeu simulee), souris, bruitages.

  Clavier : fleche gauche ou droite (Lorenzo avance et continue
  d'avancer jusqu'a ce qu'une autre fleche soit appuyee : le Presentation
  Manager ne transmet pas les touches relachees ; la fleche opposee
  l'arrete, appuyee de nouveau elle le fait repartir dans l'autre sens),
  fleche bas ou haut (arret), Espace (sauter), P (pause), F2 (nouvelle partie), Entree
  (nouvelle partie apres la fin), F1 (regles).
  Souris : clic a gauche ou a droite de Lorenzo (avancer), au-dessus de
  lui (sauter), sur lui (arret).
  Parametres : /SEED:n ; /PHASE:n (phase de depart) ; /AUTO
  (demonstration) ; /NOSOUND ; /TEST (essais du jeu sans fenetre, puis
  partie reproductible jouee par l'ordinateur ; resultat sur le port
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
  VK_NEWLINE = $08; VK_PAUSE = $0D; VK_SPACE = $10;
  VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_PAUSE = 102; CM_QUIT = 103;
  CM_AUTO = 201; CM_SOUND = 202;
  CM_RULES = 301; CM_ABOUT = 302;
  { image de 600 x 400 : 30 carres de 20 points de large }
  BW = 600; BH = 400; OX = 12; OY = 8;
  CWant = 624; CHWant = 436;
  NBand = 20; BandH = 20;
  SU = 16;                                   { sous-points par point }
  TPS = 33;                                  { images par seconde (minuterie de 30 ms) }
  { Lorenzo : hauteur, demi-largeur, vitesses en sous-points par image }
  LH = 32; LHW = 9; RunV = 48; GravL = 14; JumpV = 212; MaxFall = 128;
  GravE = 12; MaxFallE = 112;
  { decor }
  FloorY = 348;
  PowX1 = 280; PowX2 = 320; PowY = 264;
  TopPipeY1 = 24; TopPipeY2 = 66; PipeMouthL = 66; PipeMouthR = 533;
  BotPipeY1 = 304; BotPipeY2 = 347; BotMouthL = 56; BotMouthR = 543;
  NacX = 300; NacY = 58;
  MaxE = 24; MaxPop = 8; MaxRect = 120;
  { genres de personnages }
  K_TURT = 1; K_CRAB = 2; K_FLY = 3; K_RAT = 4; K_CROC = 5; K_ICE = 6; K_COIN = 7;
  { etats des personnages }
  S_NONE = 0; S_WAIT = 1; S_OUT = 2; S_WALK = 3; S_FLIP = 4; S_DEAD = 5; S_IN = 6; S_MELT = 7; S_STAT = 8;
  S_GONE = 9;
  { etats de la partie }
  ST_START = 1; ST_PLAY = 2; ST_DIE = 3; ST_CLEAR = 4; ST_BEND = 5; ST_OVER = 6;
  { segments : 0 plancher ; 1 et 2 etage du bas ; 3 bloc POW ; 4, 5 et 6
    etage du milieu ; 7 et 8 etage du haut }
  NSeg = 9;
  SegX1 : Array[0..8] Of LongInt = (0, 0, 380, 280, 0, 140, 540, 0, 340);
  SegX2 : Array[0..8] Of LongInt = (600, 220, 600, 320, 60, 460, 600, 260, 600);
  SegY : Array[0..8] Of LongInt = (348, 264, 264, 264, 180, 180, 180, 96, 96);
  SegLv : Array[0..8] Of LongInt = (0, 1, 1, 1, 2, 2, 2, 3, 3);
  { contenu des phases : T tortue, C crabe, M mouche combattante, R rat,
    K crocodile, V verglas ; '*' : phase bonus (10 pieces) }
  PhaseQ : Array[1..10] Of String[12] = ('TTK', 'TRTTRT', 'TTTTTT', '*', 'CCKCC', 'CTRCCTRC', 'MMRMM', 'MCMC', '*',
                                         'TMVT');
  { pieces des phases bonus : 2 en haut, 4 au milieu, 2 en bas, 2 sur le plancher }
  BonX : Array[0..9] Of LongInt = (130, 470, 30, 220, 380, 570, 110, 490, 150, 450);
  BonY : Array[0..9] Of LongInt = (90, 90, 174, 174, 174, 174, 258, 258, 342, 342);
  { couleurs des plateformes selon la phase (dessus, gauche, droite, dessous, bord) }
  ThemeC : Array[0..24] Of LongInt = (
    $9C8CDC, $7464BE, $504896, $37306E, $181432,
    $E6C25A, $C89C3C, $A07828, $6E5018, $2A1E08,
    $F0965A, $D26E3C, $AA5028, $78371E, $28140A,
    $6ED2C8, $46AAAA, $288287, $195A64, $0A2328,
    $F08CB4, $D26496, $AA4678, $782D55, $2D0F1E);
  ThemeOf : Array[1..10] Of LongInt = (0, 0, 0, 1, 2, 2, 3, 3, 1, 4);
  { couleurs des ennemis : genre, colere 0..2, quatre teintes (a, A, e, E) }
  EnC : Array[0..83] Of LongInt = (
    $C47828, $824614, $FAD25A, $B48228,  $C84628, $822814, $FAAA5A, $AA5A28,  $9646AA, $5A286E, $E6AAF0, $8C5AAA,
    $3C96DC, $1E5096, $96D2FA, $2864AA,  $AA50C8, $6E2882, $DCA0F0, $824096,  $DC3C6E, $8C1E3C, $FAA0BE, $A02850,
    $505A64, $282C34, $FAC828, $966E14,  $283C78, $141E46, $FA9628, $A05A14,  $28282E, $0E0E12, $F03C28, $961E14,
    $968C82, $605850, $D2C8BE, $786E64,  $B47846, $784A28, $E6BE96, $966446,  $6E4678, $462850, $C8AAD2, $78508C,
    $468C46, $245628, $DCD278, $968C46,  $AA8C32, $6E5A1E, $F0DC8C, $A08C46,  $AA4632, $6E2A1E, $F0B48C, $A05A46,
    $DCF6FF, $82C8F0, $DCF6FF, $82C8F0,  $DCF6FF, $82C8F0, $DCF6FF, $82C8F0,  $DCF6FF, $82C8F0, $DCF6FF, $82C8F0,
    $FAC828, $BE8214, $FFF8B4, $BE8214,  $FAC828, $BE8214, $FFF8B4, $BE8214,  $FAC828, $BE8214, $FFF8B4, $BE8214);
  { couleurs de l'image }
  C_BG = 0;                                  { 0..15 : briques du mur du fond (haut -> bas) }
  C_BGM = 16;                                { 16..31 : joints du mur du fond }
  C_INK = 32; C_WHITE = 33; C_BLACK = 34; C_SHADOW = 35;
  C_PIPEB = 36;                              { 36..43 : acier bleu (sombre -> clair) }
  C_PIPEG = 44;                              { 44..51 : acier gris }
  C_TILE = 52;                               { 52..56 : carres des plateformes }
  C_ICE = 57;                                { 57..61 : carres geles }
  C_BRICK = 62; C_BRICKD = 63; C_MORTAR = 64; C_BRICKL = 65;
  C_CURB = 66; C_CURBL = 67; C_CURBD = 68;
  C_POW = 69; C_POWL = 70; C_POWD = 71; C_POWT = 72; C_POWF = 73;
  C_YELLOW = 74; C_CYAN = 75; C_ORANGE = 76; C_LGRAY = 77; C_GREEN = 78; C_RED = 79;
  C_LOR = 80;                                { 80..90 : Lorenzo (s S g G o O c C b h y) }
  C_MISC = 91;                               { 91..102 : r p v 1 2 3 i I j m M n }
  C_BANNER = 103; C_BANNERE = 104; C_ICICLE = 105; C_NAC = 106; C_NACD = 107; C_CABLE = 108;
  C_EN = 112;                                { 112.. : ennemis (genre - 1) * 12 + colere * 4 + teinte }
  { dessins (1 caractere = 1 point affiche en 2 x 2) }
  A_LOR0 = 0; A_LOR1 = 1; A_LOR2 = 2; A_LOR3 = 3; A_LOR4 = 4; A_TUR0 = 5; A_TUR1 = 6; A_CRA0 = 7;
  A_CRA1 = 8; A_FLY0 = 9; A_FLY1 = 10; A_RAT0 = 11; A_RAT1 = 12; A_CRO0 = 13; A_CRO1 = 14; A_ICE0 = 15;
  A_ICE1 = 16; A_CN0 = 17; A_CN1 = 18; A_CN2 = 19; A_CN3 = 20; A_WRE = 21; A_HED = 22;
  ArtS : Array[0..22] Of LongInt = (0, 16, 32, 48, 64, 80, 90, 100, 110, 120, 130, 140, 147, 154, 164, 174, 184,
    194, 202, 210, 218, 226, 233);
  ArtH : Array[0..22] Of LongInt = (16, 16, 16, 16, 16, 10, 10, 10, 10, 10, 10, 7, 7, 10, 10, 10, 10, 8, 8, 8, 8,
    7, 7);
  ArtW : Array[0..22] Of LongInt = (13, 13, 13, 13, 13, 19, 19, 15, 15, 13, 13, 15, 15, 24, 24, 11, 11, 8, 8, 8, 8,
    14, 8);
  ArtR : Array[0..239] Of String[24] = (
    '....kkkkk....',
    '...kcccccck..',
    '..kcccccccck.',
    '..kCCCCCCCCCk',
    '..khhsssssk..',
    '..khssswksk..',
    '..khsssssssk.',
    '...ksSSSSsk..',
    '..kkgsssskk..',
    '.kggggggggk..',
    'kggoggggoggk.',
    'kgsooooooosk.',
    'kssoyooyossk.',
    '.kkooooooook.',
    '..kOOOkkOOOk.',
    '.kbbbbkkbbbbk',
    '....kkkkk....',
    '...kcccccck..',
    '..kcccccccck.',
    '..kCCCCCCCCCk',
    '..khhsssssk..',
    '..khssswksk..',
    '..khsssssssk.',
    '...ksSSSSsk..',
    '..kkgsssskk..',
    '.kggggggggk..',
    'kgggoggoggsk.',
    'kgsoooooooss.',
    '.ksoyooyook..',
    '..kooooOOOk..',
    '.kbOOkk.kOOk.',
    '.kbbbk...kbbk',
    '....kkkkk....',
    '...kcccccck..',
    '..kcccccccck.',
    '..kCCCCCCCCCk',
    '..khhsssssk..',
    '..khssswksk..',
    '..khsssssssk.',
    '...ksSSSSsk..',
    '..kkgsssskk..',
    '..kgggggggk..',
    '.kssoggogggk.',
    '.kssoooooogk.',
    '..koyooyoosk.',
    '..kOOOooook..',
    '.kOOk..kOObk.',
    'kbbk...kbbbk.',
    '....kkkkk..ks',
    '...kcccccckgs',
    '..kccccccckg.',
    '..kCCCCCCCCgk',
    '..khhssssskg.',
    '..khssswkskg.',
    '..khssssssgk.',
    '...ksSSSSsgk.',
    '..kkgssssgk..',
    '.kggggggggk..',
    'ksgoggggok...',
    'kssooooook...',
    '.kooyooyook..',
    '.kOOOooOOOk..',
    'kbbOk.kOObbk.',
    'kbbk...kkbbk.',
    '....kkkkk....',
    '...kcccccck..',
    '..kcccccccck.',
    '..kCCCCCCCCCk',
    '..khhsssssk..',
    '..khswkswksk.',
    '..khsssssssk.',
    '...ksSkkSsk..',
    's.kkgsssskk.s',
    'skggggggggkks',
    'kggoggggoggk.',
    '.kgooooooogk.',
    '..koyooyook..',
    '..kooooooook.',
    '..kOOOkkOOOk.',
    '.kbbbbkkbbbbk',
    '.....kkkkkk........',
    '...kkaeaaeaak......',
    '..kaeeaeeaeeakkk...',
    '.kaaaAaaaAaaakssk..',
    '.kAeeAeeAeeAaksksk.',
    'kAAAAAAAAAAAAkssssk',
    'kkkkkkkkkkkkkksssk.',
    '.kssk..kssk...kkk..',
    '.kssk...kssk.......',
    '..kk.....kk........',
    '.....kkkkkk........',
    '...kkaeaaeaak......',
    '..kaeeaeeaeeakkk...',
    '.kaaaAaaaAaaakssk..',
    '.kAeeAeeAeeAaksksk.',
    'kAAAAAAAAAAAAkssssk',
    'kkkkkkkkkkkkkksssk.',
    '..ksskkssk....kkk..',
    '..kssk.kssk........',
    '...kk...kk.........',
    '.kk.........kk.',
    'kaak.......kaak',
    'kaEak.k.k.kaEak',
    'kaaakkwkwkkaaak',
    '.kkaakkkkkaakk.',
    '...kaaaaaaak...',
    '..kaeeeeeeeak..',
    '.kAaaaaaaaaaAk.',
    'ka.kAAAAAAAk.ak',
    'k.ka.ka.ak.ak.k',
    '...............',
    '.kk.........kk.',
    'kaak..k.k..kaak',
    'kaEakkwkwkkaEak',
    'kaaakakkkakaaak',
    '.kkkaaaaaaakkk.',
    '..kaeeeeeeeak..',
    '.kAaaaaaaaaaAk.',
    'k.akAAAAAAAka.k',
    '.ka.ka...ak.ak.',
    '..kk.....kk..',
    '.kvvk...kvvk.',
    'kvvvvk.kvvvvk',
    '.kvvvkkkvvvk.',
    '..kkkaaakkk..',
    '..krraaarrk..',
    '..kkaeAeakk..',
    '...kaeAeak...',
    '..k.kAAAk.k..',
    '.k...kkk...k.',
    '.............',
    '.............',
    '.....kkk.....',
    '..kkkaaakkk..',
    '.kvvkaaakvvk.',
    'kvvvkrarkvvvk',
    'kvvvkaeAkvvvk',
    '.kkkkaeAekkk.',
    '...k.kAAk.k..',
    '..k..kkkk..k.',
    '........kk.....',
    '.......kaak....',
    'pp....kaaaaakk.',
    '.kpkkkaaaaawkak',
    '..kkaaaaaaaaaak',
    '...kAAAAAAaakpk',
    '...kk.kk.kk.kk.',
    '........kk.....',
    'p......kaak....',
    '.p....kaaaaakk.',
    '..pkkkaaaaawkak',
    '..kkaaaaaaaaaak',
    '...kAAAAAAaakpk',
    '..kk...kkkk....',
    '...................kk...',
    '......kk.kk.kk...kkaak..',
    '....kkaakaakaakkkaaawak.',
    'kk.kaaaaaaaaaaaaaaaaaaak',
    'kakaAaaAaaAaaAaaaaaaaaak',
    '.kaaaaaaaaaaaaaaaawkwkkk',
    '..kAAeeeeeeeeeeeAAAAAAk.',
    '...kkAAkkkkkkAAkkkkkkk..',
    '....kAAk....kAAk........',
    '....kkk.....kkk.........',
    '..................kkkk..',
    '......kk.kk.kk..kkaawak.',
    '....kkaakaakaakkaaaaaaak',
    'kk.kaaaaaaaaaaaaaaakwkwk',
    'kakaAaaAaaAaaAaaaak.....',
    '.kaaaaaaaaaaaaaaaaakwkw.',
    '..kAAeeeeeeeeeeeAAAAAAk.',
    '...kkAAkkkkkkAAkkkkkkk..',
    '...kAAk......kAAk.......',
    '...kkk.......kkk........',
    '....kkk....',
    '...kijik...',
    '..kijIjik..',
    '.kiijIjiik.',
    'kiiwkiwkiik',
    'kiiIkiIkiik',
    'kIiiiiiiiIk',
    '.kIjjjjjIk.',
    '..kkIkIkk..',
    '...k.k.k...',
    '...kkkkk...',
    '..kiijiik..',
    '.kijIjIjik.',
    '.kiijIjiik.',
    'kiiwkiwkiik',
    'kiiIkiIkiik',
    'kIiiiiiiiIk',
    '.kIjjjjjIk.',
    '..kIkIkIk..',
    '..k.k.k.k..',
    '..kkkk..',
    '.k1122k.',
    'k112222k',
    'k122232k',
    'k122232k',
    'k122332k',
    '.k2333k.',
    '..kkkk..',
    '..kkkk..',
    '..k12k..',
    '.k1222k.',
    '.k1232k.',
    '.k1232k.',
    '.k1332k.',
    '..k33k..',
    '..kkkk..',
    '...kk...',
    '...k1k..',
    '...k2k..',
    '...k2k..',
    '...k2k..',
    '...k3k..',
    '...k3k..',
    '...kk...',
    '..kkkk..',
    '..k21k..',
    '.k2221k.',
    '.k2321k.',
    '.k2321k.',
    '.k2331k.',
    '..k33k..',
    '..kkkk..',
    '.kkkk.........',
    'kmmMMk........',
    'kkk.kMkkkkkkkk',
    '....kMmmmmmmmk',
    'kkk.kMnnnnnnnk',
    'kmMMMk.kkkkkk.',
    '.kkkk.........',
    '..kkkk..',
    '.kcccck.',
    'kCCCCCCk',
    'khsswksk',
    'khsssssk',
    '.kSSSSk.',
    '..kkkk..');

Type
  TEnt = Record
    K, St, X, Y, VX, VY, Dir, Ang, Hit, T, Anim, Side, Gnd, Bnc : LongInt;
  End;
  TGame = Record
    Score, Best, Lives, Phase, Cycle, PIdx, Bonus, State, StT, Tick : LongInt;
    LX, LY, LVX, LVY, LDir, LGnd, LAnim, Want, JumpBuf, Inv, Nac, Dead : LongInt;
    Carry, WrX, WrT, WrNext, DepN, PowLeft, PowFlash, Combo, ComboT : LongInt;
    Kills, Flips, Coins, BonusT, BonusGot, AllIce, Extra, PipeSide, CoinSide : LongInt;
    Deaths, Cleared, WrTot, Pows, IceMade, Spd, Paused, Jumps : LongInt;
  End;

Var
  InDlg : LongInt;
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  { etat du jeu (sauve et restaure par la demonstration) }
  E, SvE : Array[0..MaxE - 1] Of TEnt;
  G, SvG : TGame;
  Icy, SvIcy : Array[0..8] Of LongInt;
  BumpT, SvBumpT : Array[0..119] Of LongInt;
  DepX, SvDepX : Array[0..7] Of LongInt;
  Seed, SvSeed, Sim : LongInt;
  PopX, PopY, PopT, PopV : Array[0..MaxPop - 1] Of LongInt;
  SoundOn, TestMode, AutoAll, AiAct, Tick, StartPhase0 : LongInt;
  { image en memoire : fond (decor) et image affichee }
  Fb, Bg : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  CMap : Array[0..127] Of LongInt;
  ClipL, ClipR : LongInt;
  { etat dessine (pour ne redessiner que ce qui change) }
  DrIcy : Array[0..8] Of LongInt;
  DrBump : Array[0..119] Of LongInt;
  DrPow, DrHud, DrCurb, DrTheme, FullBg : LongInt;
  { zones a recopier : rectangles des personnages et bandes de l'ecran }
  PrN, CuN : LongInt;
  PrX1, PrY1, PrX2, PrY2, CuX1, CuY1, CuX2, CuY2 : Array[0..MaxRect - 1] Of LongInt;
  BX1, BX2 : Array[0..NBand - 1] Of LongInt;
  Msg, LastMsg : String;
  { bruitages }
  SndBuf : Array[0..59999] Of Byte;
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

{ nombre sur N chiffres (zeros a gauche) }
Function ZStr(V, N : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  While Length(S) < N Do S := '0' + S;
  ZStr := S;
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

Function Sgn(A : LongInt) : LongInt;
Begin
  If A > 0 Then Sgn := 1 Else If A < 0 Then Sgn := -1 Else Sgn := 0;
End;

Function Rnd(N : LongInt) : LongInt;
Begin
  Seed := (Seed * 1103515245 + 12345) And $7FFFFFFF;
  Rnd := (Seed Shr 8) Mod N;
End;

{ ecart horizontal D ramene entre -300 et 299 (l'ecran se referme sur lui-meme) }
Function WrapD(D : LongInt) : LongInt;
Begin
  While D >= BW Div 2 Do D := D - BW;
  While D < -(BW Div 2) Do D := D + BW;
  WrapD := D;
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
{ Dessin dans la fenetre (barre d'etat, cadre)                          }
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

Procedure OutTxt(X, Y : LongInt; S : String; Fg, Bg0 : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := CH - Y - 16; Rc[2] := X + Length(S) * 8; Rc[3] := CH - Y;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg0, 0);
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
Var R, Gr, B : LongInt;
Begin
  R := ((C1 Shr 16) And 255) + (((C2 Shr 16) And 255) - ((C1 Shr 16) And 255)) * N Div D;
  Gr := ((C1 Shr 8) And 255) + (((C2 Shr 8) And 255) - ((C1 Shr 8) And 255)) * N Div D;
  B := (C1 And 255) + ((C2 And 255) - (C1 And 255)) * N Div D;
  Mix := (R Shl 16) Or (Gr Shl 8) Or B;
End;

{ couleurs des plateformes de la phase (theme 0..4) }
Procedure SetTheme(T : LongInt);
Var I : LongInt;
Begin
  For I := 0 To 4 Do SetPal(C_TILE + I, ThemeC[T * 5 + I]);
  DrTheme := T;
End;

Procedure InitBmi;
Var I, K, J : LongInt;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, BW);
  WrL(LongInt(@Bmi) + 8, BH);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
  For I := 0 To 15 Do
  Begin
    SetPal(C_BG + I, Mix($1A1E34, $241C38, I, 15));
    SetPal(C_BGM + I, Mix($10121F, $150F20, I, 15));
  End;
  SetPal(C_INK, $0E0C16); SetPal(C_WHITE, $FFFFFF); SetPal(C_BLACK, $000000); SetPal(C_SHADOW, $07060C);
  For I := 0 To 7 Do
  Begin
    SetPal(C_PIPEB + I, Mix($122850, $B4D2F5, I, 7));
    SetPal(C_PIPEG + I, Mix($2A2C32, $DCE0E8, I, 7));
  End;
  SetTheme(0);
  SetPal(C_ICE, $E6FAFF); SetPal(C_ICE + 1, $AADCF5); SetPal(C_ICE + 2, $78B4E1); SetPal(C_ICE + 3, $5082BE);
  SetPal(C_ICE + 4, $1E3250);
  SetPal(C_BRICK, $B4321E); SetPal(C_BRICKD, $781E14); SetPal(C_MORTAR, $3C1410); SetPal(C_BRICKL, $E6644B);
  SetPal(C_CURB, $3A3E4E); SetPal(C_CURBL, $7A8096); SetPal(C_CURBD, $1C1E28);
  SetPal(C_POW, $E6B428); SetPal(C_POWL, $FFE68C); SetPal(C_POWD, $96640A); SetPal(C_POWT, $3C1E06);
  SetPal(C_POWF, $FFFFFF);
  SetPal(C_YELLOW, $FFDC46); SetPal(C_CYAN, $64DCF0); SetPal(C_ORANGE, $FFA03C); SetPal(C_LGRAY, $C8CCD6);
  SetPal(C_GREEN, $64E68C); SetPal(C_RED, $F04628);
  { Lorenzo : peau, ombre, chandail gris, gris fonce, salopette ocre,
    ocre fonce, casquette sarcelle, sarcelle fonce, bottes, cheveux, boutons }
  SetPal(C_LOR, $F0B890); SetPal(C_LOR + 1, $C48460); SetPal(C_LOR + 2, $B0B4BC); SetPal(C_LOR + 3, $6E727C);
  SetPal(C_LOR + 4, $E09430); SetPal(C_LOR + 5, $9C5E18); SetPal(C_LOR + 6, $1EA0A6); SetPal(C_LOR + 7, $106468);
  SetPal(C_LOR + 8, $60381A); SetPal(C_LOR + 9, $462A16); SetPal(C_LOR + 10, $FAE260);
  { r p v 1 2 3 i I j m M n }
  SetPal(C_MISC, $F02828); SetPal(C_MISC + 1, $F096AA); SetPal(C_MISC + 2, $D2E2F0); SetPal(C_MISC + 3, $FFF8B4);
  SetPal(C_MISC + 4, $FAC828); SetPal(C_MISC + 5, $BE8214); SetPal(C_MISC + 6, $DCF6FF); SetPal(C_MISC + 7, $82C8F0);
  SetPal(C_MISC + 8, $5096D2); SetPal(C_MISC + 9, $E6EAF0); SetPal(C_MISC + 10, $A0A6B2); SetPal(C_MISC + 11, $646874);
  SetPal(C_BANNER, $141A38); SetPal(C_BANNERE, $8CA0FF); SetPal(C_ICICLE, $C8EEFF);
  SetPal(C_NAC, $9AA0B0); SetPal(C_NACD, $4A4E5C); SetPal(C_CABLE, $5A5E6E);
  For K := 1 To 7 Do
    For J := 0 To 11 Do SetPal(C_EN + (K - 1) * 12 + J, EnC[(K - 1) * 12 + J]);
End;

{ table des caracteres des dessins -> couleurs (-1 : transparent) }
Procedure InitCMap;
Var I : LongInt;
Begin
  For I := 0 To 127 Do CMap[I] := -1;
  CMap[Ord('k')] := C_INK; CMap[Ord('w')] := C_WHITE;
  CMap[Ord('s')] := C_LOR; CMap[Ord('S')] := C_LOR + 1; CMap[Ord('g')] := C_LOR + 2; CMap[Ord('G')] := C_LOR + 3;
  CMap[Ord('o')] := C_LOR + 4; CMap[Ord('O')] := C_LOR + 5; CMap[Ord('c')] := C_LOR + 6; CMap[Ord('C')] := C_LOR + 7;
  CMap[Ord('b')] := C_LOR + 8; CMap[Ord('h')] := C_LOR + 9; CMap[Ord('y')] := C_LOR + 10;
  CMap[Ord('r')] := C_MISC; CMap[Ord('p')] := C_MISC + 1; CMap[Ord('v')] := C_MISC + 2;
  CMap[Ord('1')] := C_MISC + 3; CMap[Ord('2')] := C_MISC + 4; CMap[Ord('3')] := C_MISC + 5;
  CMap[Ord('i')] := C_MISC + 6; CMap[Ord('I')] := C_MISC + 7; CMap[Ord('j')] := C_MISC + 8;
  CMap[Ord('m')] := C_MISC + 9; CMap[Ord('M')] := C_MISC + 10; CMap[Ord('n')] := C_MISC + 11;
  CMap[Ord('a')] := C_EN; CMap[Ord('A')] := C_EN + 1; CMap[Ord('e')] := C_EN + 2; CMap[Ord('E')] := C_EN + 3;
End;

{ teintes a, A, e, E d'un ennemi (genre K, colere A) }
Procedure EnCols(K, A : LongInt);
Var B : LongInt;
Begin
  If (K < 1) Or (K > 7) Then K := 1;
  If A < 0 Then A := 0;
  If A > 2 Then A := 2;
  B := C_EN + (K - 1) * 12 + A * 4;
  CMap[Ord('a')] := B; CMap[Ord('A')] := B + 1; CMap[Ord('e')] := B + 2; CMap[Ord('E')] := B + 3;
End;

{ trace dans le decor (Bg) }
Procedure BPix(X, Y, C : LongInt);
Begin
  If (X >= 0) And (X < BW) And (Y >= 0) And (Y < BH) Then Bg[(BH - 1 - Y) * BW + X] := C;
End;

Procedure BRect(X1, Y1, X2, Y2, C : LongInt);
Var X, Y, B : LongInt;
Begin
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  For Y := Y1 To Y2 Do
  Begin
    B := (BH - 1 - Y) * BW;
    For X := X1 To X2 Do Bg[B + X] := C;
  End;
End;

{ trace dans l'image affichee (Fb), limite a ClipL..ClipR }
Procedure FPix(X, Y, C : LongInt);
Begin
  If (X >= ClipL) And (X <= ClipR) And (Y >= 0) And (Y < BH) Then Fb[(BH - 1 - Y) * BW + X] := C;
End;

Procedure FRect(X1, Y1, X2, Y2, C : LongInt);
Var X, Y, B : LongInt;
Begin
  If X1 < ClipL Then X1 := ClipL;
  If Y1 < 0 Then Y1 := 0;
  If X2 > ClipR Then X2 := ClipR;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  For Y := Y1 To Y2 Do
  Begin
    B := (BH - 1 - Y) * BW;
    For X := X1 To X2 Do Fb[B + X] := C;
  End;
End;

{ bandes de l'ecran a recopier }
Procedure Touch(X1, Y1, X2, Y2 : LongInt);
Var B : LongInt;
Begin
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  For B := Y1 Div BandH To Y2 Div BandH Do
  Begin
    If BX2[B] < BX1[B] Then
    Begin
      BX1[B] := X1; BX2[B] := X2;
    End
    Else
    Begin
      If X1 < BX1[B] Then BX1[B] := X1;
      If X2 > BX2[B] Then BX2[B] := X2;
    End;
  End;
End;

Procedure TouchAll;
Begin
  Touch(0, 0, BW - 1, BH - 1);
End;

{ rectangle d'un personnage dessine (restaure depuis le decor a l'image suivante) }
Procedure AddRect(X1, Y1, X2, Y2 : LongInt);
Begin
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  Touch(X1, Y1, X2, Y2);
  If CuN >= MaxRect Then Exit;
  CuX1[CuN] := X1; CuY1[CuN] := Y1; CuX2[CuN] := X2; CuY2[CuN] := Y2;
  Inc(CuN);
End;

{ recopie d'une zone du decor dans l'image affichee }
Procedure CopyBg(X1, Y1, X2, Y2 : LongInt);
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
    Move(Bg[B], Fb[B], X2 - X1 + 1);
  End;
  Touch(X1, Y1, X2, Y2);
End;

{ texte (police 8 x FontH du VGA ; Sc : 1 ou 2) dans le decor (ToBg = 1)
  ou dans l'image affichee }
Procedure DText(X, Y : LongInt; S : String; C, Sc, ToBg : LongInt);
Var I, R, K, B : LongInt;
Begin
  If FontH = 0 Then Exit;
  For I := 1 To Length(S) Do
    For R := 0 To FontH - 1 Do
    Begin
      B := Font[Ord(S[I]) * FontH + R];
      If B <> 0 Then
        For K := 0 To 7 Do
          If (B And ($80 Shr K)) <> 0 Then
          Begin
            If Sc = 1 Then
            Begin
              If ToBg <> 0 Then BPix(X + (I - 1) * 8 + K, Y + R, C) Else FPix(X + (I - 1) * 8 + K, Y + R, C);
            End
            Else
            Begin
              If ToBg <> 0 Then BRect(X + (I - 1) * 16 + K * 2, Y + R * 2, X + (I - 1) * 16 + K * 2 + 1, Y + R * 2 + 1, C)
              Else FRect(X + (I - 1) * 16 + K * 2, Y + R * 2, X + (I - 1) * 16 + K * 2 + 1, Y + R * 2 + 1, C);
            End;
          End;
    End;
End;

{ texte avec ombre portee }
Procedure DTextSh(X, Y : LongInt; S : String; C, Sc, ToBg : LongInt);
Begin
  DText(X + Sc, Y + Sc, S, C_SHADOW, Sc, ToBg);
  DText(X, Y, S, C, Sc, ToBg);
End;

{ dessin Id (1 caractere = 2 x 2 points), coin haut gauche (X, Y) ;
  HF : miroir horizontal, VF : a l'envers }
Procedure Art1(Id, X, Y, HF, VF : LongInt);
Var W, H, R, C, Col, Src, Row, PX, PY : LongInt; S : String[24];
Begin
  W := ArtW[Id]; H := ArtH[Id];
  For R := 0 To H - 1 Do
  Begin
    If VF <> 0 Then Row := H - 1 - R Else Row := R;
    S := ArtR[ArtS[Id] + Row];
    PY := Y + R * 2;
    If (PY >= -1) And (PY < BH) Then
      For C := 0 To W - 1 Do
      Begin
        If HF <> 0 Then Src := W - C Else Src := C + 1;
        Col := CMap[Ord(S[Src]) And 127];
        If Col >= 0 Then
        Begin
          PX := X + C * 2;
          FPix(PX, PY, Col); FPix(PX + 1, PY, Col); FPix(PX, PY + 1, Col); FPix(PX + 1, PY + 1, Col);
        End;
      End;
  End;
End;

{ dessin centre en Cx, pieds en Fy ; repete de l'autre cote de l'ecran
  quand il deborde (l'ecran se referme sur lui-meme) }
Procedure ArtAt(Id, Cx, Fy, HF, VF : LongInt);
Var W, H, X, Y : LongInt;
Begin
  W := ArtW[Id] * 2; H := ArtH[Id] * 2;
  X := Cx - W Div 2; Y := Fy - H;
  Art1(Id, X, Y, HF, VF);
  AddRect(MaxI(X, ClipL), Y, MinI(X + W - 1, ClipR), Y + H - 1);
  If (ClipL = 0) And (ClipR = BW - 1) Then
  Begin
    If X < 0 Then
    Begin
      Art1(Id, X + BW, Y, HF, VF);
      AddRect(X + BW, Y, BW - 1, Y + H - 1);
    End;
    If X + W > BW Then
    Begin
      Art1(Id, X - BW, Y, HF, VF);
      AddRect(0, Y, X + W - 1 - BW, Y + H - 1);
    End;
  End;
End;

{ ==================================================================== }
{ Bruitages                                                             }
{ ==================================================================== }

Const
  SND_JUMP = 0; SND_BUMP = 1; SND_FLIP = 2; SND_KICK = 3; SND_COIN = 4; SND_POW = 5; SND_DIE = 6; SND_CLEAR = 7;
  SND_PICK = 8; SND_DEPOT = 9; SND_LIFE = 10; SND_ANGRY = 11; SND_OVER = 12; SND_PIPE = 13; SND_ICE = 14;
  SndRate = 11025;

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

{ deux notes enchainees (pieces, clef deposee) }
Procedure MakeTwo(N, F1, F2, Ms, Vol : LongInt);
Var K, Len, F, Ph, V, Env : LongInt;
Begin
  Len := SndRate * Ms Div 1000;
  If NSndBuf + Len > SizeOf(SndBuf) Then Exit;
  SndOfs[N] := NSndBuf; SndLen[N] := Len; SndPri[N] := SndPrio;
  Ph := 0;
  For K := 0 To Len - 1 Do
  Begin
    If K < Len Div 3 Then F := F1 Else F := F2;
    Ph := (Ph + F * 65536 Div SndRate) And $FFFF;
    If K < 30 Then Env := K * 255 Div 30 Else Env := 255 * (Len - K) Div (Len - 30 + 1);
    If Ph < 32768 Then V := Vol Else V := -Vol;
    SndBuf[NSndBuf + K] := 128 + V * Env Div 255;
  End;
  NSndBuf := NSndBuf + Len;
End;

{ bruit grave (coup sous la plateforme, bloc POW) }
Procedure MakeNoise(N, Ms, Vol, Hold : LongInt);
Var K, Len, V, Env, S, Cnt : LongInt;
Begin
  Len := SndRate * Ms Div 1000;
  If NSndBuf + Len > SizeOf(SndBuf) Then Exit;
  SndOfs[N] := NSndBuf; SndLen[N] := Len; SndPri[N] := SndPrio;
  S := 12345; V := 0; Cnt := 0;
  For K := 0 To Len - 1 Do
  Begin
    If Cnt <= 0 Then
    Begin
      S := (S * 1103515245 + 12345) And $7FFFFFFF;
      V := ((S Shr 16) Mod (2 * Vol + 1)) - Vol;
      Cnt := Hold + K * Hold Div Len;
    End;
    Dec(Cnt);
    Env := 255 * (Len - K) Div Len;
    SndBuf[NSndBuf + K] := 128 + V * Env Div 255;
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
  If (SoundOn = 0) Or (TestMode <> 0) Or (Sim <> 0) Or (SndLen[N] = 0) Then Exit;
  T := SndNow;
  If (SndPri[N] < SndCur) And (T < SndEnd) And (T >= SndEnd - 60000) Then Exit;
  SndCur := SndPri[N];
  SndEnd := T + SndLen[N] * 1000 Div SndRate;
  Dummy := MdmPlay(LongInt(@SndBuf[SndOfs[N]]), SndLen[N], SndRate, 8, 1);
End;

Procedure MakeSounds;
Begin
  NSndBuf := 0;
  SndPrio := 0; MakeTone(SND_JUMP, 380, 980, 110, 22);
  SndPrio := 1; MakeNoise(SND_BUMP, 70, 60, 9);
  SndPrio := 1; MakeTone(SND_FLIP, 900, 420, 90, 30);
  SndPrio := 2; MakeTone(SND_KICK, 700, 1900, 160, 34);
  SndPrio := 2; MakeTwo(SND_COIN, 1320, 1980, 150, 28);
  SndPrio := 3; MakeNoise(SND_POW, 320, 100, 24);
  SndPrio := 4; MakeTone(SND_DIE, 900, 160, 700, 38);
  SndPrio := 4; MakeTwo(SND_CLEAR, 784, 1568, 520, 34);
  SndPrio := 1; MakeTone(SND_PICK, 1000, 1400, 70, 26);
  SndPrio := 3; MakeTwo(SND_DEPOT, 660, 1320, 300, 32);
  SndPrio := 4; MakeTone(SND_LIFE, 1200, 2600, 450, 32);
  SndPrio := 1; MakeTone(SND_ANGRY, 260, 640, 120, 30);
  SndPrio := 5; MakeTone(SND_OVER, 520, 130, 1000, 38);
  SndPrio := 0; MakeTone(SND_PIPE, 200, 260, 80, 18);
  SndPrio := 1; MakeTone(SND_ICE, 2400, 1600, 140, 18);
  SndPrio := 0;
End;

{ ==================================================================== }
{ Le monde : plateformes, Lorenzo, ennemis                              }
{ ==================================================================== }

Function PowH : LongInt;
Begin
  PowH := 8 + 8 * G.PowLeft;
End;

{ le segment S existe-t-il ? (le bloc POW disparait apres 3 coups) }
Function SegOk(S : LongInt) : Boolean;
Begin
  SegOk := (S <> 3) Or (G.PowLeft > 0);
End;

{ epaisseur du segment (dessous frappable) }
Function SegTh(S : LongInt) : LongInt;
Begin
  If S = 3 Then SegTh := PowH Else If S = 0 Then SegTh := 52 Else SegTh := 20;
End;

{ etage d'apres la hauteur des pieds }
Function LevOfY(Y : LongInt) : LongInt;
Begin
  If Y > 306 Then LevOfY := 0
  Else If Y > 222 Then LevOfY := 1
  Else If Y > 138 Then LevOfY := 2
  Else LevOfY := 3;
End;

{ segment de l'etage Lv sous l'abscisse X (-1 : aucun) }
Function SegAt(X, Lv : LongInt) : LongInt;
Var S, R : LongInt;
Begin
  R := -1;
  For S := 0 To NSeg - 1 Do
    If (SegLv[S] = Lv) And SegOk(S) And (X >= SegX1[S]) And (X < SegX2[S]) Then R := S;
  SegAt := R;
End;

Function Glissant(S : LongInt) : Boolean;
Begin
  Glissant := (S >= 0) And ((G.AllIce <> 0) Or (Icy[S] <> 0));
End;

Function Counted(K : LongInt) : Boolean;
Begin
  Counted := (K >= K_TURT) And (K <= K_CROC);
End;

{ demi-largeur et hauteur d'un personnage (points) }
Function EnHW(K : LongInt) : LongInt;
Begin
  Case K Of
    K_TURT : EnHW := 19;
    K_CRAB : EnHW := 15;
    K_FLY : EnHW := 13;
    K_RAT : EnHW := 15;
    K_CROC : EnHW := 24;
    K_ICE : EnHW := 11;
  Else
    EnHW := 8;
  End;
End;

Function EnH(K : LongInt) : LongInt;
Begin
  Case K Of
    K_RAT : EnH := 14;
    K_COIN : EnH := 16;
  Else
    EnH := 20;
  End;
End;

{ vitesse de marche (sous-points par image) selon le genre, la colere
  et le tour de jeu }
Function EnSpeed(I : LongInt) : LongInt;
Var V : LongInt;
Begin
  Case E[I].K Of
    K_TURT : V := 20;
    K_CRAB : V := 22;
    K_FLY : V := 22;
    K_RAT : V := 40;
    K_CROC : V := 13;
    K_ICE : V := 18;
  Else
    V := 26;
  End;
  If (E[I].K = K_CROC) And (E[I].Hit > 0) Then V := V + 5;
  If E[I].K <> K_COIN Then V := V * (10 + 4 * E[I].Ang) Div 10;
  EnSpeed := V * G.Spd Div 100;
End;

Procedure Snd(N : LongInt);
Begin
  If Sim = 0 Then PlaySnd(N);
End;

Procedure AddPop(X, Y, V : LongInt);
Var I, B : LongInt;
Begin
  If (Sim <> 0) Or (TestMode <> 0) Then Exit;
  B := 0;
  For I := 0 To MaxPop - 1 Do
    If PopT[I] < PopT[B] Then B := I;
  PopX[B] := X; PopY[B] := Y; PopT[B] := 40; PopV[B] := V;
End;

Procedure AddPts(P : LongInt);
Begin
  G.Score := G.Score + P;
  If G.Score > G.Best Then G.Best := G.Score;
  If (G.Extra = 0) And (G.Score >= 20000) Then
  Begin
    G.Extra := 1;
    Inc(G.Lives);
    Snd(SND_LIFE);
  End;
End;

Function FreeEnt : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := MaxE - 1 DownTo 0 Do
    If (E[I].St = S_NONE) Or (E[I].St = S_GONE) Then R := I;
  FreeEnt := R;
End;

Procedure ClearEnt(I : LongInt);
Begin
  FillChar(E[I], SizeOf(TEnt), 0);
  E[I].Gnd := -1; E[I].Dir := 1;
End;

{ un personnage attend dans le tuyau du haut, cote Side (0 gauche, 1 droite) }
Function Queue(K, Side, T : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := FreeEnt;
  Queue := I;
  If I < 0 Then Exit;
  ClearEnt(I);
  E[I].K := K; E[I].St := S_WAIT; E[I].T := T; E[I].Side := Side;
End;

{ piece qui sort d'un tuyau apres un ennemi elimine }
Procedure CoinFromPipe;
Var I : LongInt;
Begin
  If G.Bonus <> 0 Then Exit;
  I := Queue(K_COIN, G.CoinSide, 30);
  G.CoinSide := 1 - G.CoinSide;
End;

Function FlipDur(I : LongInt) : LongInt;
Begin
  FlipDur := (300 - 55 * E[I].Ang) * 100 Div G.Spd;
End;

Procedure EntFlip(I : LongInt);
Begin
  E[I].St := S_FLIP; E[I].T := FlipDur(I); E[I].VY := -70; E[I].Gnd := -1; E[I].VX := 0; E[I].Hit := 0;
  AddPts(10);
  Inc(G.Flips);
  Snd(SND_FLIP);
End;

Procedure EntUnflip(I : LongInt; Angrier : Boolean);
Begin
  E[I].St := S_WALK; E[I].Hit := 0; E[I].VY := -60; E[I].Gnd := -1; E[I].T := 0;
  If Angrier And (E[I].Ang < 2) Then Inc(E[I].Ang);
  Snd(SND_ANGRY);
End;

Procedure CollectCoin(I : LongInt);
Begin
  E[I].St := S_GONE;
  AddPts(800);
  AddPop(E[I].X Div SU, E[I].Y Div SU - 20, 800);
  Inc(G.Coins);
  If G.Bonus <> 0 Then Inc(G.BonusGot);
  Snd(SND_COIN);
End;

Procedure IceBreak(I : LongInt);
Begin
  E[I].St := S_GONE;
  AddPts(500);
  AddPop(E[I].X Div SU, E[I].Y Div SU - 20, 500);
  Snd(SND_ICE);
End;

{ coup par-dessous (plateforme frappee ou bloc POW) sur le personnage I }
Procedure HitBelow(I : LongInt; ByPow : Boolean);
Begin
  Case E[I].K Of
    K_COIN : CollectCoin(I);
    K_ICE : IceBreak(I);
  Else
    If E[I].St = S_FLIP Then
    Begin
      If ByPow Then E[I].T := FlipDur(I) Else EntUnflip(I, False);
    End
    Else If E[I].St = S_WALK Then
    Begin
      If E[I].K = K_CRAB Then
      Begin
        If (E[I].Hit = 0) And Not ByPow Then
        Begin
          E[I].Hit := 1;
          If E[I].Ang < 2 Then Inc(E[I].Ang);
          E[I].VY := -50; E[I].Gnd := -1;
          Snd(SND_ANGRY);
        End
        Else EntFlip(I);
      End
      Else If E[I].K = K_CROC Then
      Begin
        If E[I].Hit = 0 Then
        Begin
          E[I].Hit := 1; E[I].T := 28; E[I].VY := -40; E[I].Gnd := -1;
          Snd(SND_ANGRY);
        End
        Else EntFlip(I);
      End
      Else EntFlip(I);
    End;
  End;
End;

Procedure PowHit;
Var I : LongInt;
Begin
  If G.PowLeft <= 0 Then Exit;
  Dec(G.PowLeft);
  Inc(G.Pows);
  G.PowFlash := 12;
  Snd(SND_POW);
  For I := 0 To MaxE - 1 Do
    If (E[I].Gnd >= 0) And ((E[I].St = S_WALK) Or (E[I].St = S_FLIP)) Then HitBelow(I, True);
  If G.PowLeft = 0 Then
  Begin
    If G.LGnd = 3 Then G.LGnd := -1;
    For I := 0 To MaxE - 1 Do
      If E[I].Gnd = 3 Then E[I].Gnd := -1;
  End;
End;

{ coup de Lorenzo sous le segment S a l'abscisse X }
Procedure Bump(S, X : LongInt);
Var I, Row, Col, C : LongInt;
Begin
  Snd(SND_BUMP);
  If S = 3 Then
  Begin
    PowHit;
    Exit;
  End;
  { les carres frappes ondulent }
  Row := SegLv[S];
  Col := X Div 20;
  For C := Col - 1 To Col + 1 Do
    If (C >= 0) And (C < 30) And (C * 20 >= SegX1[S]) And (C * 20 < SegX2[S]) Then
    Begin
      If C = Col Then BumpT[Row * 30 + C] := 8 Else BumpT[Row * 30 + C] := 7;
    End;
  For I := 0 To MaxE - 1 Do
    If (E[I].Gnd = S) And ((E[I].St = S_WALK) Or (E[I].St = S_FLIP)) And
       (Abs(WrapD(E[I].X Div SU - X)) <= 22 + EnHW(E[I].K) Div 3) Then HitBelow(I, False);
End;

{ Lorenzo elimine l'ennemi retourne I }
Procedure EntKill(I : LongInt);
Var P : LongInt;
Begin
  E[I].St := S_DEAD; E[I].VY := -110; E[I].Gnd := -1;
  If WrapD(E[I].X Div SU - G.LX Div SU) >= 0 Then E[I].VX := 40 Else E[I].VX := -40;
  If G.ComboT > 0 Then G.Combo := MinI(G.Combo + 1, 4) Else G.Combo := 1;
  G.ComboT := 75;
  P := 800 * G.Combo;
  AddPts(P);
  AddPop(E[I].X Div SU, E[I].Y Div SU - 24, P);
  Inc(G.Kills);
  Snd(SND_KICK);
  CoinFromPipe;
End;

Procedure LorDie;
Begin
  G.State := ST_DIE; G.Dead := 0; G.Carry := 0; G.LVX := 0; G.LVY := 0; G.ComboT := 0;
  Inc(G.Deaths);
  Snd(SND_DIE);
End;

{ gravite et atterrissage d'un personnage }
Procedure EntPhys(I : LongInt);
Var S, Cx, NY, T : LongInt;
Begin
  Cx := E[I].X Div SU;
  If E[I].Gnd >= 0 Then
  Begin
    S := E[I].Gnd;
    If (Not SegOk(S)) Or (Cx < SegX1[S]) Or (Cx >= SegX2[S]) Then E[I].Gnd := -1;
  End;
  If E[I].Gnd < 0 Then
  Begin
    E[I].VY := MinI(E[I].VY + GravE, MaxFallE);
    NY := E[I].Y + E[I].VY;
    If E[I].VY >= 0 Then
      For S := 0 To NSeg - 1 Do
        If SegOk(S) And (E[I].Gnd < 0) Then
        Begin
          T := SegY[S] * SU;
          If (E[I].Y <= T) And (NY >= T) And (Cx >= SegX1[S]) And (Cx < SegX2[S]) Then
          Begin
            NY := T; E[I].VY := 0; E[I].Gnd := S;
            If (E[I].K = K_FLY) And (E[I].St = S_WALK) Then E[I].T := 10;
          End;
        End;
    E[I].Y := NY;
    If E[I].Y > 440 * SU Then E[I].St := S_GONE;
  End;
End;

Procedure WrapX(I : LongInt);
Begin
  If E[I].X < 0 Then E[I].X := E[I].X + BW * SU;
  If E[I].X >= BW * SU Then E[I].X := E[I].X - BW * SU;
End;

{ le tuyau du haut cote Side est-il occupe par un personnage qui sort ? }
Function PipeBusy(Side : LongInt) : Boolean;
Var I : LongInt; R : Boolean;
Begin
  R := False;
  For I := 0 To MaxE - 1 Do
    If (E[I].St = S_OUT) And (E[I].Side = Side) Then R := True;
  PipeBusy := R;
End;

Procedure StepEnt(I : LongInt);
Var Cx, Hw, V, S : LongInt;
Begin
  Hw := EnHW(E[I].K);
  Case E[I].St Of
    S_WAIT :
      Begin
        Dec(E[I].T);
        If E[I].T <= 0 Then
        Begin
          If PipeBusy(E[I].Side) Then E[I].T := 6
          Else
          Begin
            E[I].St := S_OUT; E[I].Y := 62 * SU; E[I].VY := 0; E[I].Gnd := -1; E[I].Hit := 0;
            If E[I].Side = 0 Then
            Begin
              E[I].X := (PipeMouthL - Hw - 2) * SU; E[I].Dir := 1;
            End
            Else
            Begin
              E[I].X := (PipeMouthR + Hw + 2) * SU; E[I].Dir := -1;
            End;
            Snd(SND_PIPE);
          End;
        End;
      End;
    S_OUT :
      Begin
        E[I].X := E[I].X + E[I].Dir * EnSpeed(I);
        Inc(E[I].Anim);
        Cx := E[I].X Div SU;
        If ((E[I].Side = 0) And (Cx - Hw >= PipeMouthL)) Or ((E[I].Side = 1) And (Cx + Hw <= PipeMouthR)) Then
          E[I].St := S_WALK;
      End;
    S_WALK :
      Begin
        If E[I].Bnc > 0 Then Dec(E[I].Bnc);
        Cx := E[I].X Div SU;
        S := E[I].Gnd;
        { le verglas gele la plateforme quand il en atteint le milieu }
        If (E[I].K = K_ICE) And (S >= 1) And (S <> 3) And (Icy[MaxI(S, 0)] = 0) And (G.AllIce = 0) And
           (Abs(Cx - (SegX1[MaxI(S, 0)] + SegX2[MaxI(S, 0)]) Div 2) <= 2) Then
        Begin
          E[I].St := S_MELT; E[I].T := 40;
          Exit;
        End;
        V := EnSpeed(I);
        If (E[I].K = K_CROC) And (E[I].T > 0) Then
        Begin
          Dec(E[I].T);
          V := 0;
        End;
        If E[I].K = K_FLY Then
        Begin
          If E[I].Gnd >= 0 Then
          Begin
            V := 0;
            Dec(E[I].T);
            If E[I].T <= 0 Then
            Begin
              E[I].VY := -96; E[I].Gnd := -1;
            End;
          End;
        End;
        If (E[I].K = K_RAT) And (E[I].Gnd >= 0) Then
        Begin
          If Rnd(110) = 0 Then E[I].Dir := -E[I].Dir
          Else If Rnd(80) = 0 Then
          Begin
            E[I].VY := -58; E[I].Gnd := -1;
          End;
        End;
        E[I].X := E[I].X + E[I].Dir * V;
        WrapX(I);
        If V <> 0 Then Inc(E[I].Anim);
        EntPhys(I);
        { arrive au plancher pres d'un tuyau de retour }
        If (E[I].Gnd = 0) And (E[I].St = S_WALK) Then
        Begin
          Cx := E[I].X Div SU;
          If ((E[I].Dir < 0) And (Cx - Hw <= BotMouthL)) Or ((E[I].Dir > 0) And (Cx + Hw >= BotMouthR)) Then
            E[I].St := S_IN;
        End;
      End;
    S_FLIP :
      Begin
        Dec(E[I].T);
        Inc(E[I].Anim);
        EntPhys(I);
        If (E[I].T <= 0) And (E[I].St = S_FLIP) Then EntUnflip(I, True);
      End;
    S_IN :
      Begin
        E[I].X := E[I].X + E[I].Dir * EnSpeed(I);
        Inc(E[I].Anim);
        Cx := E[I].X Div SU;
        If ((E[I].Dir < 0) And (Cx + Hw < BotMouthL)) Or ((E[I].Dir > 0) And (Cx - Hw > BotMouthR)) Then
        Begin
          If (E[I].K = K_COIN) Or (E[I].K = K_ICE) Then E[I].St := S_GONE
          Else
          Begin
            E[I].St := S_WAIT; E[I].T := 45;
            If E[I].Dir < 0 Then E[I].Side := 0 Else E[I].Side := 1;
          End;
        End;
      End;
    S_MELT :
      Begin
        Dec(E[I].T);
        If E[I].T <= 0 Then
        Begin
          If E[I].Gnd >= 0 Then Icy[E[I].Gnd] := 1;
          Inc(G.IceMade);
          E[I].St := S_GONE;
          Snd(SND_ICE);
        End;
      End;
    S_DEAD :
      Begin
        E[I].X := E[I].X + E[I].VX;
        WrapX(I);
        E[I].VY := MinI(E[I].VY + GravE, MaxFallE);
        E[I].Y := E[I].Y + E[I].VY;
        If E[I].Y > 450 * SU Then E[I].St := S_GONE;
      End;
    S_STAT : Inc(E[I].Anim);
  End;
End;

{ deux ennemis qui se rencontrent font demi-tour }
Procedure EnemyBounce;
Var I, J, D : LongInt;
Begin
  For I := 0 To MaxE - 2 Do
    If (E[I].St = S_WALK) And (E[I].Gnd >= 0) And (E[I].K <> K_COIN) And (E[I].Bnc = 0) Then
      For J := I + 1 To MaxE - 1 Do
        If (E[J].St = S_WALK) And (E[J].Gnd = E[I].Gnd) And (E[J].K <> K_COIN) And (E[J].Bnc = 0) Then
        Begin
          D := WrapD(E[J].X Div SU - E[I].X Div SU);
          If Abs(D) < EnHW(E[I].K) + EnHW(E[J].K) - 8 Then
            If ((D > 0) And (E[I].Dir > 0) And (E[J].Dir < 0)) Or ((D < 0) And (E[I].Dir < 0) And (E[J].Dir > 0)) Then
            Begin
              E[I].Dir := -E[I].Dir; E[J].Dir := -E[J].Dir;
              E[I].Bnc := 12; E[J].Bnc := 12;
            End;
        End;
End;

Procedure StartPhase(N : LongInt); Forward;

Procedure StepLorenzo;
Var Cx, Acc, Tgt, NY, HO, HN, B, S, T, Hit : LongInt;
Begin
  { nacelle de retour apres une vie perdue }
  If G.Nac > 0 Then
  Begin
    G.LX := NacX * SU; G.LY := NacY * SU; G.LVX := 0; G.LVY := 0; G.LGnd := -2;
    Dec(G.Nac);
    If (G.Want <> 0) Or (G.JumpBuf > 0) Or (G.Nac = 0) Then
    Begin
      G.Nac := 0; G.Inv := 50; G.LGnd := -1; G.JumpBuf := 0;
      If G.Want <> 0 Then G.LDir := G.Want;
    End
    Else Exit;
  End;
  Tgt := G.Want * RunV;
  If G.LGnd >= 0 Then
  Begin
    If Glissant(G.LGnd) Then Acc := 2 Else Acc := 12;
  End
  Else Acc := 6;
  If G.LVX < Tgt Then G.LVX := MinI(G.LVX + Acc, Tgt);
  If G.LVX > Tgt Then G.LVX := MaxI(G.LVX - Acc, Tgt);
  If G.Want <> 0 Then G.LDir := G.Want;
  If (G.JumpBuf > 0) And (G.LGnd >= 0) Then
  Begin
    G.LVY := -JumpV; G.LGnd := -1; G.JumpBuf := 0;
    Inc(G.Jumps);
    Snd(SND_JUMP);
  End;
  If G.JumpBuf > 0 Then Dec(G.JumpBuf);
  G.LX := G.LX + G.LVX;
  If G.LX < 0 Then G.LX := G.LX + BW * SU;
  If G.LX >= BW * SU Then G.LX := G.LX - BW * SU;
  Cx := G.LX Div SU;
  If G.LGnd >= 0 Then
  Begin
    S := G.LGnd;
    If (Not SegOk(S)) Or (Cx < SegX1[S]) Or (Cx >= SegX2[S]) Then G.LGnd := -1;
  End;
  If G.LGnd < 0 Then
  Begin
    G.LVY := MinI(G.LVY + GravL, MaxFall);
    NY := G.LY + G.LVY;
    If G.LVY < 0 Then
    Begin
      { la tete frappe le dessous d'une plateforme ? }
      HO := G.LY - LH * SU; HN := NY - LH * SU; Hit := -1;
      For S := 1 To NSeg - 1 Do
        If SegOk(S) And (Hit < 0) Then
        Begin
          B := (SegY[S] + SegTh(S)) * SU;
          If (HO >= B) And (HN < B) And (Cx >= SegX1[S]) And (Cx < SegX2[S]) Then
          Begin
            Hit := S;
            NY := B + LH * SU; G.LVY := 0;
          End;
        End;
      If Hit >= 0 Then Bump(Hit, Cx);
      If NY - LH * SU < 24 * SU Then
      Begin
        NY := (24 + LH) * SU; G.LVY := 0;
      End;
    End
    Else
    Begin
      For S := 0 To NSeg - 1 Do
        If SegOk(S) And (G.LGnd < 0) Then
        Begin
          T := SegY[S] * SU;
          If (G.LY <= T) And (NY >= T) And (Cx >= SegX1[S]) And (Cx < SegX2[S]) Then
          Begin
            NY := T; G.LVY := 0; G.LGnd := S;
          End;
        End;
    End;
    G.LY := NY;
  End;
  If (G.LGnd >= 0) And (Abs(G.LVX) > 6) Then Inc(G.LAnim);
  If G.Inv > 0 Then Dec(G.Inv);
  { clef de plombier : ramassee sur le plancher, deposee en haut }
  If (G.WrT > 0) And (G.LGnd = 0) And (G.Carry = 0) And (Abs(WrapD(Cx - G.WrX)) < 18) Then
  Begin
    G.Carry := 1; G.WrT := 0; G.WrNext := 330;
    Snd(SND_PICK);
  End;
  If (G.Carry <> 0) And ((G.LGnd = 7) Or (G.LGnd = 8)) Then
  Begin
    S := G.LGnd;
    If G.DepN < 8 Then DepX[G.DepN] := MaxI(SegX1[S] + 12, MinI(SegX2[S] - 12, Cx));
    Inc(G.DepN); Inc(G.WrTot);
    G.Carry := 0;
    T := MinI(5000, 1000 * G.DepN);
    AddPts(T);
    AddPop(Cx, SegY[S] - 40, T);
    Snd(SND_DEPOT);
  End;
End;

{ contacts de Lorenzo avec les personnages }
Procedure Contacts;
Var I, Cx, Fy, D, EF, Hw : LongInt;
Begin
  If (G.Nac > 0) Or (G.State <> ST_PLAY) Then Exit;
  Cx := G.LX Div SU; Fy := G.LY Div SU;
  For I := 0 To MaxE - 1 Do
    If (E[I].St = S_WALK) Or (E[I].St = S_FLIP) Or (E[I].St = S_OUT) Or (E[I].St = S_IN) Or (E[I].St = S_STAT) Then
    Begin
      Hw := EnHW(E[I].K);
      D := WrapD(E[I].X Div SU - Cx);
      EF := E[I].Y Div SU;
      If (Abs(D) < LHW + Hw - 4) And (EF - EnH(E[I].K) + 3 < Fy) And (Fy - 30 < EF) Then
      Begin
        If E[I].K = K_COIN Then CollectCoin(I)
        Else If E[I].St = S_FLIP Then EntKill(I)
        Else If G.Inv = 0 Then
        Begin
          LorDie;
          Exit;
        End;
      End;
    End;
End;

Function CountLeft : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To MaxE - 1 Do
    If Counted(E[I].K) And (E[I].St <> S_NONE) And (E[I].St <> S_GONE) And (E[I].St <> S_DEAD) Then Inc(N);
  CountLeft := N;
End;

Procedure StepPlay;
Var I, N : LongInt;
Begin
  StepLorenzo;
  For I := 0 To MaxE - 1 Do
    If (E[I].St <> S_NONE) And (E[I].St <> S_GONE) Then StepEnt(I);
  EnemyBounce;
  Contacts;
  If G.State <> ST_PLAY Then Exit;
  If G.ComboT > 0 Then Dec(G.ComboT);
  If G.PowFlash > 0 Then Dec(G.PowFlash);
  For I := 0 To 119 Do
    If BumpT[I] > 0 Then Dec(BumpT[I]);
  If G.Bonus <> 0 Then
  Begin
    Dec(G.BonusT);
    If (G.BonusGot >= 10) Or (G.BonusT <= 0) Then
    Begin
      If G.BonusGot >= 10 Then
      Begin
        If G.PIdx = 9 Then AddPts(8000) Else AddPts(5000);
        Snd(SND_CLEAR);
      End
      Else Snd(SND_PIPE);
      G.State := ST_BEND; G.StT := 120;
      Inc(G.Cleared);
    End;
    Exit;
  End;
  { clef de plombier sur le plancher }
  If G.WrT > 0 Then Dec(G.WrT)
  Else If (G.Carry = 0) And (G.DepN < 6) Then
  Begin
    Dec(G.WrNext);
    If G.WrNext <= 0 Then
    Begin
      G.WrX := 80 + Rnd(440);
      If Abs(WrapD(G.WrX - G.LX Div SU)) < 70 Then G.WrX := 80 + (G.WrX + 220) Mod 440;
      G.WrT := 520; G.WrNext := 330;
    End;
  End;
  { le dernier ennemi devient le plus rapide ; phase terminee }
  N := CountLeft;
  If N = 1 Then
    For I := 0 To MaxE - 1 Do
      If Counted(E[I].K) And (E[I].St = S_WALK) And (E[I].Ang < 2) Then
      Begin
        E[I].Ang := 2;
        Snd(SND_ANGRY);
      End;
  If N = 0 Then
  Begin
    G.State := ST_CLEAR; G.StT := 110;
    Inc(G.Cleared);
    Snd(SND_CLEAR);
  End;
End;

Procedure StepDie;
Begin
  Inc(G.Dead);
  If G.Dead = 24 Then G.LVY := -150;
  If G.Dead > 24 Then
  Begin
    G.LVY := MinI(G.LVY + 10, MaxFall);
    G.LY := G.LY + G.LVY;
  End;
  If (G.Dead > 40) And (G.LY > 470 * SU) Then
  Begin
    Dec(G.Lives);
    If G.Lives <= 0 Then
    Begin
      G.Lives := 0;
      G.State := ST_OVER; G.StT := 0;
      Snd(SND_OVER);
    End
    Else
    Begin
      G.State := ST_PLAY;
      G.Nac := 150; G.LX := NacX * SU; G.LY := NacY * SU; G.LGnd := -2; G.LVX := 0; G.LVY := 0;
      G.Want := 0; G.JumpBuf := 0; G.Inv := 0;
    End;
  End;
End;

{ une image de jeu }
Procedure Step;
Var I : LongInt;
Begin
  Inc(G.Tick);
  Case G.State Of
    ST_START :
      Begin
        Dec(G.StT);
        If G.StT <= 0 Then G.State := ST_PLAY;
      End;
    ST_PLAY : StepPlay;
    ST_DIE : StepDie;
    ST_CLEAR, ST_BEND :
      Begin
        Dec(G.StT);
        If G.StT <= 0 Then StartPhase(G.Phase + 1);
      End;
    ST_OVER : Inc(G.StT);
  End;
  If Sim = 0 Then
    For I := 0 To MaxPop - 1 Do
      If PopT[I] > 0 Then Dec(PopT[I]);
End;

{ ==================================================================== }
{ Phases                                                                }
{ ==================================================================== }

Function KindOf(C : Char) : LongInt;
Begin
  Case C Of
    'T' : KindOf := K_TURT;
    'C' : KindOf := K_CRAB;
    'M' : KindOf := K_FLY;
    'R' : KindOf := K_RAT;
    'K' : KindOf := K_CROC;
    'V' : KindOf := K_ICE;
  Else
    KindOf := K_COIN;
  End;
End;

Function PhaseIdx(N : LongInt) : LongInt;
Begin
  PhaseIdx := (N - 1) Mod 10 + 1;
End;

Function Plural(N : LongInt; S1, S2 : String) : String;
Begin
  If N > 1 Then Plural := IStr(N) + ' ' + S2 Else Plural := IStr(N) + ' ' + S1;
End;

{ contenu d'une phase en clair }
Function PhaseDesc(N : LongInt) : String;
Var Q, R : String; Cnt : Array[0..7] Of LongInt; I, K : LongInt;
Begin
  Q := PhaseQ[PhaseIdx(N)];
  If Q = '*' Then
  Begin
    R := 'Phase bonus : 10 pi' + Chr(138) + 'ces en 20 secondes';
    If PhaseIdx(N) = 9 Then R := R + ', plancher glissant';
    PhaseDesc := R;
    Exit;
  End;
  For K := 0 To 7 Do Cnt[K] := 0;
  For I := 1 To Length(Q) Do Inc(Cnt[KindOf(Q[I])]);
  R := '';
  If Cnt[K_TURT] > 0 Then R := R + ', ' + Plural(Cnt[K_TURT], 'tortue', 'tortues');
  If Cnt[K_CRAB] > 0 Then R := R + ', ' + Plural(Cnt[K_CRAB], 'crabe', 'crabes');
  If Cnt[K_FLY] > 0 Then R := R + ', ' + Plural(Cnt[K_FLY], 'mouche', 'mouches');
  If Cnt[K_RAT] > 0 Then R := R + ', ' + Plural(Cnt[K_RAT], 'rat', 'rats');
  If Cnt[K_CROC] > 0 Then R := R + ', ' + Plural(Cnt[K_CROC], 'crocodile', 'crocodiles');
  If Cnt[K_ICE] > 0 Then R := R + ', ' + Plural(Cnt[K_ICE], 'verglas', 'verglas');
  PhaseDesc := Copy(R, 3, 255);
End;

Procedure StartPhase(N : LongInt);
Var I, K : LongInt; Q : String;
Begin
  If N < 1 Then N := 1;
  G.Phase := N; G.PIdx := PhaseIdx(N); G.Cycle := (N - 1) Div 10;
  G.Spd := MinI(100 + 15 * G.Cycle, 200);
  Q := PhaseQ[G.PIdx];
  For I := 0 To MaxE - 1 Do ClearEnt(I);
  For I := 0 To 8 Do Icy[I] := 0;
  For I := 0 To 119 Do BumpT[I] := 0;
  For I := 0 To 7 Do DepX[I] := 0;
  G.Bonus := Ord(Q = '*');
  G.AllIce := Ord(G.PIdx = 9);
  G.PowLeft := 3; G.PowFlash := 0; G.DepN := 0; G.Carry := 0; G.WrT := 0; G.WrNext := 300;
  G.Combo := 0; G.ComboT := 0; G.BonusGot := 0; G.BonusT := 20 * TPS;
  G.CoinSide := 0;
  G.LX := 300 * SU; G.LY := FloorY * SU; G.LVX := 0; G.LVY := 0; G.LDir := 1; G.LGnd := 0; G.LAnim := 0;
  G.Want := 0; G.JumpBuf := 0; G.Inv := 0; G.Nac := 0; G.Dead := 0;
  If G.Bonus <> 0 Then
  Begin
    For I := 0 To 9 Do
    Begin
      ClearEnt(I);
      E[I].K := K_COIN; E[I].St := S_STAT; E[I].X := BonX[I] * SU; E[I].Y := BonY[I] * SU; E[I].Anim := I * 3;
    End;
  End
  Else
    For I := 1 To Length(Q) Do
    Begin
      K := Queue(KindOf(Q[I]), (I - 1) Mod 2, 30 + ((I - 1) * 105) * 100 Div G.Spd);
    End;
  G.State := ST_START; G.StT := 70;
  FullBg := 1;
End;

Procedure NewGame;
Var B : LongInt;
Begin
  B := G.Best;
  FillChar(G, SizeOf(G), 0);
  G.Best := B; G.Lives := 3;
  StartPhase(StartPhase0);
End;

{ ==================================================================== }
{ Demonstration : l'ordinateur joue                                     }
{ Chaque action possible (aller a gauche, a droite, s'arreter, avec ou  }
{ sans saut) est essayee sur 28 images de jeu simulees ; la meilleure   }
{ (pas de vie perdue, ennemis retournes ou elimines, rapprochement du   }
{ but) est retenue.                                                     }
{ ==================================================================== }

Var
  AiPrev, AiTX : LongInt;

Procedure SaveSt;
Begin
  Move(E, SvE, SizeOf(E)); Move(G, SvG, SizeOf(G)); Move(Icy, SvIcy, SizeOf(Icy));
  Move(BumpT, SvBumpT, SizeOf(BumpT)); Move(DepX, SvDepX, SizeOf(DepX));
  SvSeed := Seed;
End;

Procedure LoadSt;
Begin
  Move(SvE, E, SizeOf(E)); Move(SvG, G, SizeOf(G)); Move(SvIcy, Icy, SizeOf(Icy));
  Move(SvBumpT, BumpT, SizeOf(BumpT)); Move(SvDepX, DepX, SizeOf(DepX));
  Seed := SvSeed;
End;

{ ennemis retournes (x 2) et ennemis deja frappes une fois (crabes en
  colere, crocodiles blesses) }
Function NFlipped : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To MaxE - 1 Do
    If Counted(E[I].K) Then
    Begin
      If E[I].St = S_FLIP Then N := N + 2
      Else If (E[I].St = S_WALK) And (E[I].Hit > 0) Then Inc(N);
    End;
  NFlipped := N;
End;

{ chemins entre les plateformes : sauts vers l'etage du dessus (depuis
  TrX sur le segment TrFrom, arrivee vers TrLand sur TrTo) et descentes
  par les bords }
Const
  NTr = 20;
  TrFrom : Array[0..19] Of LongInt = (0, 0, 0, 0, 1, 1, 2, 2, 5, 5, 1, 2, 3, 3, 4, 5, 5, 6, 7, 8);
  TrX : Array[0..19] Of LongInt = (250, 250, 350, 350, 100, 100, 500, 500, 300, 300, 222, 378, 278, 322, 62, 138,
                                   462, 538, 262, 338);
  TrTo : Array[0..19] Of LongInt = (1, 3, 2, 3, 4, 5, 5, 6, 7, 8, 0, 0, 0, 0, 1, 1, 2, 2, 5, 5);
  TrLand : Array[0..19] Of LongInt = (215, 290, 385, 310, 55, 145, 455, 545, 255, 345, 230, 370, 270, 330, 70, 130,
                                      470, 530, 270, 330);
  TrCost : Array[0..19] Of LongInt = (60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20);
  Far = 99999;

Var
  TrD, TrL : Array[0..NTr - 1] Of LongInt;
  AiTS : LongInt;

{ distance a pied sur un segment, ou entre deux segments relies par les
  bords de l'ecran (1 et 2, 4 et 6, 7 et 8) }
Function WalkD(S, X, S2, X2 : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := Far;
  If S = S2 Then
  Begin
    If S = 0 Then R := Abs(WrapD(X - X2)) Else R := Abs(X - X2);
  End
  Else If ((S = 1) And (S2 = 2)) Or ((S = 4) And (S2 = 6)) Or ((S = 7) And (S2 = 8)) Then R := X + (BW - X2)
  Else If ((S = 2) And (S2 = 1)) Or ((S = 6) And (S2 = 4)) Or ((S = 8) And (S2 = 7)) Then R := X2 + (BW - X);
  WalkD := R;
End;

{ couts depuis la position (S, X) jusqu'au depart de chaque passage }
Procedure NavFrom(S, X : LongInt);
Var T, U, K, C : LongInt;
Begin
  For T := 0 To NTr - 1 Do TrL[T] := WalkD(S, X, TrFrom[T], TrX[T]);
  For K := 1 To 6 Do
    For T := 0 To NTr - 1 Do
      If TrL[T] < Far Then
        For U := 0 To NTr - 1 Do
        Begin
          C := WalkD(TrTo[T], TrLand[T], TrFrom[U], TrX[U]);
          If C < Far Then
            If TrL[T] + TrCost[T] + C < TrL[U] Then TrL[U] := TrL[T] + TrCost[T] + C;
        End;
End;

{ cout de la position de depart (NavFrom) jusqu'a (S, X) }
Function CostTo(S0, X0, S, X : LongInt) : LongInt;
Var T, C, R : LongInt;
Begin
  R := WalkD(S0, X0, S, X);
  For T := 0 To NTr - 1 Do
    If TrL[T] < Far Then
    Begin
      C := WalkD(TrTo[T], TrLand[T], S, X);
      If (C < Far) And (TrL[T] + TrCost[T] + C < R) Then R := TrL[T] + TrCost[T] + C;
    End;
  CostTo := R;
End;

{ couts depuis l'arrivee de chaque passage jusqu'au but (S, X) }
Procedure NavTo(S, X : LongInt);
Var T, U, K, C : LongInt;
Begin
  For T := 0 To NTr - 1 Do TrD[T] := WalkD(TrTo[T], TrLand[T], S, X);
  For K := 1 To 6 Do
    For T := 0 To NTr - 1 Do
      For U := 0 To NTr - 1 Do
        If TrD[U] < Far Then
        Begin
          C := WalkD(TrTo[T], TrLand[T], TrFrom[U], TrX[U]);
          If C < Far Then
            If C + TrCost[U] + TrD[U] < TrD[T] Then TrD[T] := C + TrCost[U] + TrD[U];
        End;
End;

{ segment ou se trouve Lorenzo (en l'air : celui qui est sous lui) }
Function LorSeg : LongInt;
Var Lv, S, Cx : LongInt;
Begin
  If G.LGnd >= 0 Then
  Begin
    LorSeg := G.LGnd;
    Exit;
  End;
  Cx := G.LX Div SU;
  If G.LGnd = -2 Then
  Begin
    LorSeg := 5;
    Exit;
  End;
  Lv := LevOfY(G.LY Div SU);
  S := SegAt(Cx, Lv);
  While (S < 0) And (Lv > 0) Do
  Begin
    Dec(Lv);
    S := SegAt(Cx, Lv);
  End;
  If S < 0 Then S := 0;
  LorSeg := S;
End;

{ cout du chemin de Lorenzo jusqu'au but choisi (NavTo deja calcule) }
Function NavCost : LongInt;
Var S, X, T, C, R : LongInt;
Begin
  S := LorSeg; X := G.LX Div SU;
  R := WalkD(S, X, AiTS, AiTX);
  For T := 0 To NTr - 1 Do
    If TrD[T] < Far Then
    Begin
      C := WalkD(S, X, TrFrom[T], TrX[T]);
      If (C < Far) And (C + TrCost[T] + TrD[T] < R) Then R := C + TrCost[T] + TrD[T];
    End;
  If G.LGnd = -2 Then R := R + 20;
  NavCost := R;
End;

{ segment sous le point (X, Y) : le premier en descendant }
Function SegBelow(X, Y : LongInt) : LongInt;
Var Lv, S : LongInt;
Begin
  Lv := LevOfY(Y);
  S := SegAt(X, Lv);
  While (S < 0) And (Lv > 0) Do
  Begin
    Dec(Lv);
    S := SegAt(X, Lv);
  End;
  If S < 0 Then S := 0;
  SegBelow := S;
End;

{ ou attendre l'ennemi I pour le frapper par-dessous : son chemin est
  suivi (bords, chutes, tuyaux) jusqu'au premier endroit que Lorenzo peut
  atteindre a temps sous lui. TS, TX : place ; TT : images d'attente. }
Function Intercept(I, S0, X0 : LongInt; Var TS, TX, TT : LongInt) : Boolean;
Var X, Sg, D, V, T, Lv, Sp, Lt, Hw, Sg2 : LongInt; R : Boolean;
Begin
  R := False;
  X := E[I].X Div SU; D := E[I].Dir; V := MaxI(EnSpeed(I), 8); Hw := EnHW(E[I].K);
  If E[I].St = S_OUT Then
  Begin
    If E[I].Side = 0 Then Sg := 7 Else Sg := 8;
  End
  Else If E[I].Gnd >= 0 Then Sg := E[I].Gnd
  Else Sg := SegBelow(X, E[I].Y Div SU);
  T := 0;
  While (T < 450) And Not R Do
  Begin
    Lv := SegLv[Sg];
    If (Lv >= 1) And (Sg <> 3) Then
    Begin
      Sp := SegAt(X, Lv - 1);
      If Sp >= 0 Then
      Begin
        Lt := CostTo(S0, X0, Sp, X) * SU Div RunV + 6;
        If Lt <= T Then
        Begin
          TS := Sp; TX := X; TT := T; R := True;
        End;
      End;
    End;
    If Not R Then
    Begin
      T := T + 3;
      X := X + D * V * 3 Div SU;
      If X < 0 Then X := X + BW;
      If X >= BW Then X := X - BW;
      If Sg = 0 Then
      Begin
        If (D < 0) And (X - Hw <= BotMouthL) Then
        Begin
          T := T + 70; X := PipeMouthL + Hw + 4; Sg := 7; D := 1;
        End
        Else If (D > 0) And (X + Hw >= BotMouthR) Then
        Begin
          T := T + 70; X := PipeMouthR - Hw - 4; Sg := 8; D := -1;
        End;
      End
      Else If (X < SegX1[Sg]) Or (X >= SegX2[Sg]) Then
      Begin
        Sg2 := SegAt(X, Lv);
        If Sg2 >= 0 Then Sg := Sg2
        Else
        Begin
          Sg := SegBelow(X, SegY[Sg] + 30);
          T := T + 8;
        End;
      End;
    End;
  End;
  Intercept := R;
End;

{ choix du but de Lorenzo : piece (phase bonus), ennemi retourne a
  eliminer, place sous un ennemi debout pour le frapper, clef a
  ramasser ou a deposer }
Procedure AiTarget;
Var I, S0, X0, C, Best, Px, Sg, Pri, BPri, BX, BS, Tt, Extra : LongInt;
Begin
  S0 := LorSeg; X0 := G.LX Div SU;
  NavFrom(S0, X0);
  Best := 999999; BX := 300; BS := 0; BPri := 9;
  For I := 0 To MaxE - 1 Do
  Begin
    Pri := 9; Px := 0; Sg := -1; Extra := 0;
    If (E[I].St = S_STAT) Or ((E[I].K = K_COIN) And (E[I].St = S_WALK) And (E[I].Gnd >= 0)) Then
    Begin
      Px := E[I].X Div SU;
      If E[I].Gnd >= 0 Then Sg := E[I].Gnd Else Sg := SegAt(Px, LevOfY(E[I].Y Div SU + 6));
      If G.Bonus <> 0 Then Pri := 1 Else Pri := 3;
    End
    Else If (E[I].St = S_FLIP) And Counted(E[I].K) And (E[I].Gnd >= 0) Then
    Begin
      { ennemi retourne : a eliminer s'il est atteignable avant qu'il se releve }
      Px := E[I].X Div SU;
      If CostTo(S0, X0, E[I].Gnd, Px) * SU Div RunV + 12 < E[I].T Then
      Begin
        Sg := E[I].Gnd; Pri := 1; Extra := -300;
      End;
    End
    Else If ((E[I].St = S_WALK) Or (E[I].St = S_OUT)) And Counted(E[I].K) Then
    Begin
      { place ou attendre l'ennemi pour le frapper par-dessous }
      If Intercept(I, S0, X0, Sg, Px, Tt) Then
      Begin
        Pri := 2;
        Extra := Tt * 3 - CostTo(S0, X0, Sg, Px) - 200;
      End;
    End;
    If (Pri < 9) And (Sg >= 0) Then
    Begin
      C := CostTo(S0, X0, Sg, Px) + Pri * 300 + Extra;
      If C < Best Then
      Begin
        Best := C; BX := Px; BS := Sg; BPri := Pri;
      End;
    End;
  End;
  If (G.Carry <> 0) And (BPri >= 2) Then
  Begin
    If CostTo(S0, X0, 7, 130) <= CostTo(S0, X0, 8, 470) Then
    Begin
      BS := 7; BX := 130;
    End
    Else
    Begin
      BS := 8; BX := 470;
    End;
  End
  Else If (G.WrT > 80) And (G.Carry = 0) And (BPri >= 2) And (CostTo(S0, X0, 0, G.WrX) < 400) Then
  Begin
    BX := G.WrX; BS := 0;
  End;
  If BPri = 9 Then
  Begin
    BX := 300; BS := 0;
  End;
  AiTX := BX; AiTS := BS;
  NavTo(AiTS, AiTX);
End;

Procedure AiThink;
Var A, Best, BestV, V, T, W, J, S0, K0, F0, C0, D0, Died, Done, MinC : LongInt;
Begin
  If G.State <> ST_PLAY Then Exit;
  If (G.Tick Mod 3 <> 0) And (G.Nac = 0) Then Exit;
  AiTarget;
  SaveSt;
  S0 := G.Score; K0 := G.Kills; F0 := NFlipped; C0 := G.Cleared; D0 := G.WrTot;
  Best := 1; BestV := -999999999;
  Sim := 1;
  For A := 0 To 5 Do
  Begin
    W := (A Mod 3) - 1;
    J := A Div 3;
    If (J = 0) Or (G.LGnd >= 0) Then
    Begin
      G.Want := W;
      If J = 1 Then G.JumpBuf := 4 Else G.JumpBuf := 0;
      Died := 0; Done := 0; T := 0;
      MinC := NavCost;
      While ((T < 28) Or ((G.LGnd = -1) And (T < 60))) And (Died = 0) And (Done = 0) Do
      Begin
        Inc(T);
        Step;
        If G.State = ST_DIE Then Died := T;
        If (G.State = ST_CLEAR) Or (G.State = ST_BEND) Then Done := T;
        If (G.LGnd >= 0) And (Died = 0) Then MinC := MinI(MinC, NavCost);
      End;
      If Died > 0 Then V := -1000000 + Died * 1000
      Else
      Begin
        V := -(MinC + NavCost) Div 2 + 3 * MinI(G.Score - S0, 9000) + 1500 * (NFlipped - F0) + 5000 * (G.Kills - K0) +
             50000 * (G.Cleared - C0) + 1500 * (G.WrTot - D0);
        If J = 1 Then V := V - 30;
        If A = AiPrev Then V := V + 10;
        If (W <> 0) And (W = Sgn(SvG.LVX)) Then V := V + 30;
      End;
      If V > BestV Then
      Begin
        BestV := V; Best := A;
      End;
      LoadSt;
    End;
  End;
  Sim := 0;
  AiPrev := Best;
  G.Want := (Best Mod 3) - 1;
  If Best Div 3 = 1 Then G.JumpBuf := 4;
  Inc(AiAct);
End;

{ ==================================================================== }
{ Decor                                                                 }
{ ==================================================================== }

Const
  OffT : Array[0..8] Of LongInt = (0, 1, 3, 5, 7, 7, 5, 3, 2);

{ mur de briques sombres du fond }
Procedure Backdrop(X1, Y1, X2, Y2 : LongInt);
Var X, Y, Gi, Of0, Yy, B : LongInt;
Begin
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  For Y := Y1 To Y2 Do
  Begin
    Gi := Y * 16 Div BH;
    Yy := Y Mod 16;
    If Odd(Y Div 16) Then Of0 := 20 Else Of0 := 0;
    B := (BH - 1 - Y) * BW;
    For X := X1 To X2 Do
      If (Yy = 0) Or ((X + Of0) Mod 40 = 0) Then Bg[B + X] := C_BGM + Gi Else Bg[B + X] := C_BG + Gi;
  End;
End;

{ tuyau horizontal (ombre selon la hauteur) de la couleur Base }
Procedure PipeH(X1, X2, Y1, Y2, Base : LongInt);
Var Y, T, S : LongInt;
Begin
  For Y := Y1 To Y2 Do
  Begin
    T := (Y - Y1) * 100 Div MaxI(1, Y2 - Y1);
    If T < 30 Then S := 4 + T * 3 Div 30 Else S := 7 - (T - 30) * 6 Div 70;
    If S < 0 Then S := 0;
    If S > 7 Then S := 7;
    If (Y = Y1) Or (Y = Y2) Then BRect(X1, Y, X2, Y, C_INK) Else BRect(X1, Y, X2, Y, Base + S);
  End;
End;

{ un tuyau : corps contre le mur, collet a l'embouchure (Dir 1 : ouvert
  vers la droite) }
Procedure Pipe(BX1, BX2, FX1, FX2, Y1, Y2, Base, Dir : LongInt);
Var Y, K, Xo : LongInt;
Begin
  PipeH(BX1, BX2, Y1 + 5, Y2 - 5, Base);
  { bagues du corps }
  For K := 0 To 1 Do
  Begin
    If Dir > 0 Then Xo := BX1 + 12 + K * 18 Else Xo := BX2 - 12 - K * 18;
    For Y := Y1 + 6 To Y2 - 6 Do BPix(Xo, Y, Base + 1);
    For Y := Y1 + 6 To Y2 - 6 Do BPix(Xo + 1, Y, Base + 6);
  End;
  PipeH(FX1, FX2, Y1, Y2, Base);
  BRect(FX1, Y1, FX1, Y2, C_INK); BRect(FX2, Y1, FX2, Y2, C_INK);
  { ouverture : bord interieur sombre }
  If Dir > 0 Then
  Begin
    BRect(FX2 - 3, Y1 + 4, FX2 - 1, Y2 - 4, C_SHADOW);
    BRect(FX2 - 4, Y1 + 4, FX2 - 4, Y2 - 4, Base + 2);
  End
  Else
  Begin
    BRect(FX1 + 1, Y1 + 4, FX1 + 3, Y2 - 4, C_SHADOW);
    BRect(FX1 + 4, Y1 + 4, FX1 + 4, Y2 - 4, Base + 2);
  End;
End;

Procedure DrawPipes;
Begin
  { tuyaux d'arrivee (en haut) : acier bleu ; tuyaux de retour (en bas) : acier gris }
  Pipe(0, 51, 52, PipeMouthL - 1, TopPipeY1, TopPipeY2, C_PIPEB, 1);
  Pipe(PipeMouthR + 15, BW - 1, PipeMouthR + 1, PipeMouthR + 14, TopPipeY1, TopPipeY2, C_PIPEB, -1);
  Pipe(0, 43, 44, BotMouthL - 1, BotPipeY1, BotPipeY2, C_PIPEG, 1);
  Pipe(BotMouthR + 13, BW - 1, BotMouthR + 1, BotMouthR + 12, BotPipeY1, BotPipeY2, C_PIPEG, -1);
End;

{ segment de carres de l'etage Lv contenant la colonne Col (-1 : vide) }
Function TileSeg(Lv, Col : LongInt) : LongInt;
Var S, R : LongInt;
Begin
  R := -1;
  For S := 1 To NSeg - 1 Do
    If (S <> 3) And (SegLv[S] = Lv) And (Col * 20 >= SegX1[S]) And (Col * 20 < SegX2[S]) Then R := S;
  TileSeg := R;
End;

Function TileKey(Lv, Col : LongInt) : LongInt;
Var S, K : LongInt;
Begin
  S := TileSeg(Lv, Col);
  K := OffT[MinI(8, MaxI(0, BumpT[Lv * 30 + Col]))] * 2;
  If (S >= 0) And Glissant(S) Then Inc(K);
  TileKey := K;
End;

{ un carre de plateforme : quatre triangles (dessus clair, cotes, dessous
  sombre) ; souleve quand il est frappe ; gele : couleurs de glace et
  glacons pendants }
Procedure DrawTile(Lv, Col : LongInt);
Var S, X0, Y0, Off, Base, U, V, C, M, K : LongInt;
Begin
  S := TileSeg(Lv, Col);
  X0 := Col * 20; Y0 := SegY[MaxI(S, 1)];
  If S < 0 Then Exit;
  Backdrop(X0, Y0 - 10, X0 + 19, Y0 + 27);
  Off := OffT[MinI(8, MaxI(0, BumpT[Lv * 30 + Col]))];
  If Glissant(S) Then Base := C_ICE Else Base := C_TILE;
  For V := 0 To 19 Do
    For U := 0 To 19 Do
    Begin
      M := MinI(MinI(V, 19 - V), MinI(U, 19 - U));
      If M = V Then C := Base
      Else If M = 19 - V Then C := Base + 3
      Else If M = U Then C := Base + 1
      Else C := Base + 2;
      If (U = 0) Or (V = 19) Or (U = 19) Then C := Base + 4;
      If (V = 0) Then C := Base + 4;
      If ((U = V) Or (U = 19 - V)) And (U > 0) And (U < 19) Then C := Base + 4;
      BPix(X0 + U, Y0 - Off + V, C);
    End;
  If Glissant(S) Then
    For K := 0 To 4 Do
    Begin
      BRect(X0 + 4, Y0 - Off + 20, X0 + 6, Y0 - Off + 21, C_ICICLE);
      BRect(X0 + 5, Y0 - Off + 22, X0 + 5, Y0 - Off + 24, C_ICICLE);
      BRect(X0 + 13, Y0 - Off + 20, X0 + 15, Y0 - Off + 20, C_ICICLE);
      BRect(X0 + 14, Y0 - Off + 21, X0 + 14, Y0 - Off + 22, C_ICICLE);
    End;
End;

Function PowKey : LongInt;
Begin
  PowKey := G.PowLeft * 2 + Ord(Odd(G.PowFlash Div 2));
End;

Procedure DrawPow;
Var H, Y0, C : LongInt;
Begin
  Backdrop(PowX1 - 4, PowY - 4, PowX2 + 3, PowY + 36);
  If G.PowLeft <= 0 Then Exit;
  H := PowH; Y0 := PowY;
  If Odd(G.PowFlash Div 2) Then C := C_POWF Else C := C_POW;
  BRect(PowX1, Y0, PowX2 - 1, Y0 + H - 1, C_INK);
  BRect(PowX1 + 1, Y0 + 1, PowX2 - 2, Y0 + H - 2, C);
  BRect(PowX1 + 1, Y0 + 1, PowX2 - 2, Y0 + 2, C_POWL); BRect(PowX1 + 1, Y0 + 1, PowX1 + 2, Y0 + H - 2, C_POWL);
  BRect(PowX1 + 1, Y0 + H - 3, PowX2 - 2, Y0 + H - 2, C_POWD); BRect(PowX2 - 3, Y0 + 1, PowX2 - 2, Y0 + H - 2, C_POWD);
  DText(PowX1 + 8, Y0 + (H - 16) Div 2, 'POW', C_POWT, 1, 1);
End;

Function HudSig : LongInt;
Begin
  HudSig := G.Score * 7 + G.Best * 13 + G.Lives * 100003 + (G.BonusT Div TPS) * 1009 + G.Bonus * 3 + G.Carry * 5;
End;

Function CurbSig : LongInt;
Begin
  CurbSig := G.Phase * 31 + G.DepN * 7 + G.AllIce;
End;

{ bandeau du haut : pointage a gauche, meilleur pointage a droite }
Procedure DrawHud;
Var N : LongInt; S : String;
Begin
  Backdrop(0, 0, BW - 1, 21);
  BRect(0, 21, BW - 1, 21, C_SHADOW);
  DTextSh(8, 3, 'POINTS', C_CYAN, 1, 1);
  DTextSh(64, 3, ZStr(MinI(G.Score, 9999999), 6), C_WHITE, 1, 1);
  { les tetes de Lorenzo (vies de reserve) sont ajoutees par DrawHudAll }
  N := MaxI(0, G.Lives - 1);
  If N > 5 Then DTextSh(224, 3, 'x' + IStr(N), C_WHITE, 1, 1);
  If G.Bonus <> 0 Then
  Begin
    S := 'TEMPS ' + ZStr(MaxI(0, (G.BonusT + TPS - 1) Div TPS), 2);
    DTextSh((BW - Length(S) * 8) Div 2, 3, S, C_YELLOW, 1, 1);
  End
  Else DTextSh((BW - 11 * 8) Div 2, 3, 'LE PLOMBIER', C_ORANGE, 1, 1);
  DTextSh(BW - 8 - 14 * 8, 3, 'RECORD', C_CYAN, 1, 1);
  DTextSh(BW - 8 - 6 * 8, 3, ZStr(MinI(G.Best, 9999999), 6), C_WHITE, 1, 1);
  DrHud := HudSig;
End;

{ tete de Lorenzo dans le decor (vies) : dessin A_HED recopie dans Bg }
Procedure HeadBg(X, Y : LongInt);
Var R, C, Col : LongInt; S : String[24];
Begin
  For R := 0 To ArtH[A_HED] - 1 Do
  Begin
    S := ArtR[ArtS[A_HED] + R];
    For C := 0 To ArtW[A_HED] - 1 Do
    Begin
      Col := CMap[Ord(S[C + 1]) And 127];
      If Col >= 0 Then BRect(X + C * 2, Y + R * 2, X + C * 2 + 1, Y + R * 2 + 1, Col);
    End;
  End;
End;

Procedure DrawHudAll;
Var K, N : LongInt;
Begin
  DrawHud;
  N := MaxI(0, G.Lives - 1);
  For K := 0 To MinI(N, 5) - 1 Do HeadBg(120 + K * 20, 4);
End;

{ bordure de pierre (PHASE n en bas a gauche, sous le tuyau de retour) et
  plancher de briques rouges }
Procedure DrawCurb;
Var S : String; C : LongInt;
Begin
  If G.AllIce <> 0 Then C := C_ICE + 2 Else C := C_CURB;
  BRect(0, 348, BW - 1, 363, C);
  If G.AllIce <> 0 Then BRect(0, 348, BW - 1, 349, C_ICE) Else BRect(0, 348, BW - 1, 349, C_CURBL);
  BRect(0, 363, BW - 1, 363, C_CURBD);
  DTextSh(8, 348, 'PHASE ' + IStr(G.Phase), C_WHITE, 1, 1);
  If G.DepN > 0 Then
  Begin
    S := 'CLEFS ' + IStr(G.DepN);
    DTextSh(BW - 8 - Length(S) * 8, 348, S, C_YELLOW, 1, 1);
  End;
  DrCurb := CurbSig;
End;

Procedure DrawBricks;
Var R, X, Of0, Y0 : LongInt;
Begin
  For R := 0 To 1 Do
  Begin
    Y0 := 364 + R * 18;
    BRect(0, Y0, BW - 1, Y0 + 17, C_MORTAR);
    If R = 1 Then Of0 := 18 Else Of0 := 0;
    X := -Of0;
    While X < BW Do
    Begin
      BRect(X + 1, Y0 + 2, X + 35, Y0 + 17, C_BRICK);
      BRect(X + 1, Y0 + 2, X + 35, Y0 + 2, C_BRICKL);
      BRect(X + 1, Y0 + 2, X + 1, Y0 + 17, C_BRICKL);
      BRect(X + 1, Y0 + 16, X + 35, Y0 + 17, C_BRICKD);
      BRect(X + 34, Y0 + 3, X + 35, Y0 + 17, C_BRICKD);
      X := X + 36;
    End;
  End;
End;

Procedure RenderBg;
Var Lv, Col : LongInt;
Begin
  SetTheme(ThemeOf[MaxI(1, G.PIdx)]);
  Backdrop(0, 0, BW - 1, BH - 1);
  DrawPipes;
  For Lv := 1 To 3 Do
    For Col := 0 To 29 Do
    Begin
      DrawTile(Lv, Col);
      DrBump[Lv * 30 + Col] := TileKey(Lv, Col);
    End;
  DrawPow; DrPow := PowKey;
  DrawCurb;
  DrawBricks;
  DrawHudAll;
End;

{ ne redessine que ce qui a change dans le decor }
Procedure UpdateBg;
Var Lv, Col, K : LongInt;
Begin
  For Lv := 1 To 3 Do
    For Col := 0 To 29 Do
    Begin
      K := TileKey(Lv, Col);
      If K <> DrBump[Lv * 30 + Col] Then
      Begin
        DrBump[Lv * 30 + Col] := K;
        DrawTile(Lv, Col);
        CopyBg(Col * 20, SegY[TileSeg(Lv, Col)] - 10, Col * 20 + 19, SegY[TileSeg(Lv, Col)] + 27);
      End;
    End;
  If PowKey <> DrPow Then
  Begin
    DrPow := PowKey;
    DrawPow;
    CopyBg(PowX1 - 4, PowY - 4, PowX2 + 3, PowY + 36);
  End;
  If HudSig <> DrHud Then
  Begin
    DrawHudAll;
    CopyBg(0, 0, BW - 1, 21);
  End;
  If CurbSig <> DrCurb Then
  Begin
    DrawCurb;
    CopyBg(0, 348, BW - 1, 363);
  End;
End;

{ ==================================================================== }
{ Personnages                                                           }
{ ==================================================================== }

Procedure DrawEnt(I : LongInt);
Var Id, Cx, Fy, HF, VF, F, A : LongInt;
Begin
  If (E[I].St = S_NONE) Or (E[I].St = S_WAIT) Or (E[I].St = S_GONE) Then Exit;
  Cx := E[I].X Div SU; Fy := E[I].Y Div SU;
  F := (E[I].Anim Div 6) Mod 2;
  HF := Ord(E[I].Dir < 0);
  VF := Ord((E[I].St = S_FLIP) Or (E[I].St = S_DEAD));
  A := E[I].Ang;
  Case E[I].K Of
    K_TURT : Id := A_TUR0 + F;
    K_CRAB :
      Begin
        Id := A_CRA0 + F; HF := 0;
      End;
    K_FLY :
      Begin
        If E[I].Gnd >= 0 Then Id := A_FLY1 Else Id := A_FLY0 + (Tick Div 2) Mod 2;
        HF := 0;
      End;
    K_RAT : Id := A_RAT0 + (E[I].Anim Div 3) Mod 2;
    K_CROC :
      Begin
        If (E[I].Hit > 0) And (E[I].T > 0) And (E[I].St = S_WALK) Then Id := A_CRO0 + (Tick Div 3) Mod 2
        Else If (E[I].Anim Div 9) Mod 4 = 3 Then Id := A_CRO1
        Else Id := A_CRO0;
        A := MinI(2, A + E[I].Hit);
      End;
    K_ICE :
      Begin
        Id := A_ICE0 + (E[I].Anim Div 8) Mod 2; HF := 0;
        If E[I].St = S_MELT Then
        Begin
          If Odd(Tick Div 2) Then Exit;
          Fy := Fy + (40 - E[I].T) Div 5;
        End;
      End;
  Else
    Begin
      Id := A_CN0 + (E[I].Anim Div 4) Mod 4; HF := 0; VF := 0;
      If (E[I].K = K_COIN) And (E[I].St = S_STAT) Then Id := A_CN0 + ((Tick + E[I].Anim) Div 5) Mod 4;
    End;
  End;
  { ennemi retourne qui va se relever : il tremble }
  If (E[I].St = S_FLIP) And (E[I].T < 50) And Odd(Tick Div 2) Then Cx := Cx + 2;
  EnCols(E[I].K, A);
  ClipL := 0; ClipR := BW - 1;
  If E[I].St = S_OUT Then
  Begin
    If E[I].Side = 0 Then ClipL := PipeMouthL Else ClipR := PipeMouthR;
  End;
  If E[I].St = S_IN Then
  Begin
    If E[I].Dir < 0 Then ClipL := BotMouthL Else ClipR := BotMouthR;
  End;
  ArtAt(Id, Cx, Fy, HF, VF);
  ClipL := 0; ClipR := BW - 1;
End;

Procedure DrawLor;
Var Id, Cx, Fy, HF, VF : LongInt;
Begin
  If G.State = ST_OVER Then Exit;
  Cx := G.LX Div SU; Fy := G.LY Div SU;
  VF := 0;
  HF := Ord(G.LDir < 0);
  If G.State = ST_DIE Then
  Begin
    Id := A_LOR4;
    VF := Ord(G.Dead > 24);
  End
  Else
  Begin
    If (G.Inv > 0) And Odd(Tick Div 3) Then Exit;
    If G.LGnd = -1 Then Id := A_LOR3
    Else If Abs(G.LVX) > 6 Then
    Begin
      Case (G.LAnim Div 3) Mod 4 Of
        0 : Id := A_LOR1;
        2 : Id := A_LOR2;
      Else
        Id := A_LOR0;
      End;
    End
    Else Id := A_LOR0;
  End;
  ArtAt(Id, Cx, Fy, HF, VF);
  If (G.Carry <> 0) And (G.State <> ST_DIE) Then
  Begin
    If G.LDir < 0 Then ArtAt(A_WRE, Cx - 16, Fy - 8, 0, 0) Else ArtAt(A_WRE, Cx + 16, Fy - 8, 1, 0);
  End;
End;

Procedure DrawBanner;
Var L1, L2 : String; W, X1, Y1, X2, Y2 : LongInt;
Begin
  L1 := ''; L2 := '';
  If G.Paused <> 0 Then
  Begin
    L1 := 'PAUSE'; L2 := 'P pour reprendre';
  End
  Else
    Case G.State Of
      ST_START :
        Begin
          L1 := 'PHASE ' + IStr(G.Phase); L2 := PhaseDesc(G.Phase);
          If (G.Phase > 10) And (G.PIdx = 1) Then L2 := L2 + ' (plus vite)';
        End;
      ST_CLEAR :
        Begin
          L1 := 'PHASE TERMIN' + Chr(144) + 'E'; L2 := 'Bravo, Lorenzo !';
        End;
      ST_BEND :
        Begin
          If G.BonusGot >= 10 Then
          Begin
            L1 := 'PARFAIT !';
            If G.PIdx = 9 Then L2 := 'Les 10 pi' + Chr(138) + 'ces : 8000 points de plus'
            Else L2 := 'Les 10 pi' + Chr(138) + 'ces : 5000 points de plus';
          End
          Else
          Begin
            L1 := 'TEMPS ' + Chr(144) + 'COUL' + Chr(144); L2 := IStr(G.BonusGot) + ' pi' + Chr(138) + 'ces sur 10';
          End;
        End;
      ST_OVER :
        Begin
          L1 := 'FIN DE LA PARTIE'; L2 := 'F2 ou Entr' + Chr(130) + 'e : nouvelle partie';
        End;
    End;
  If L1 = '' Then Exit;
  W := MaxI(Length(L1) * 16, Length(L2) * 8) + 40;
  X1 := (BW - W) Div 2; X2 := X1 + W - 1; Y1 := 128; Y2 := 191;
  FRect(X1 + 4, Y1 + 4, X2 + 4, Y2 + 4, C_SHADOW);
  FRect(X1, Y1, X2, Y2, C_BANNER);
  FRect(X1, Y1, X2, Y1 + 1, C_BANNERE); FRect(X1, Y2 - 1, X2, Y2, C_BANNERE);
  FRect(X1, Y1, X1 + 1, Y2, C_BANNERE); FRect(X2 - 1, Y1, X2, Y2, C_BANNERE);
  DText((BW - Length(L1) * 16) Div 2 + 2, Y1 + 10, L1, C_SHADOW, 2, 0);
  DText((BW - Length(L1) * 16) Div 2, Y1 + 8, L1, C_YELLOW, 2, 0);
  DText((BW - Length(L2) * 8) Div 2, Y1 + 42, L2, C_WHITE, 1, 0);
  AddRect(X1, Y1, X2 + 4, Y2 + 4);
End;

Procedure DrawSprites;
Var I, K : LongInt; S : String;
Begin
  ClipL := 0; ClipR := BW - 1;
  { clefs deposees sur les plateformes du haut }
  For K := 0 To MinI(G.DepN, 8) - 1 Do ArtAt(A_WRE, DepX[K], 96, K Mod 2, 0);
  { clef sur le plancher (clignote avant de disparaitre) }
  If (G.WrT > 0) And ((G.WrT > 100) Or Odd(Tick Div 4)) Then ArtAt(A_WRE, G.WrX, FloorY, 0, 0);
  { nacelle de retour }
  If (G.Nac > 0) And (G.State = ST_PLAY) Then
  Begin
    FRect(NacX - 1, 22, NacX, NacY - 1, C_CABLE);
    FRect(NacX - 22, NacY, NacX + 21, NacY + 5, C_NAC);
    FRect(NacX - 22, NacY + 4, NacX + 21, NacY + 5, C_NACD);
    FRect(NacX - 22, NacY, NacX - 22, NacY + 5, C_INK); FRect(NacX + 21, NacY, NacX + 21, NacY + 5, C_INK);
    AddRect(NacX - 22, 22, NacX + 21, NacY + 5);
  End;
  For I := 0 To MaxE - 1 Do DrawEnt(I);
  DrawLor;
  { points gagnes }
  For I := 0 To MaxPop - 1 Do
    If PopT[I] > 0 Then
    Begin
      S := IStr(PopV[I]);
      K := PopY[I] - (40 - PopT[I]) Div 2;
      DText(PopX[I] - Length(S) * 4 + 1, K + 1, S, C_SHADOW, 1, 0);
      DText(PopX[I] - Length(S) * 4, K, S, C_YELLOW, 1, 0);
      AddRect(PopX[I] - Length(S) * 4, K, PopX[I] + Length(S) * 4 + 1, K + 17);
    End;
  DrawBanner;
End;

{ image complete (Full) ou mise a jour des zones changees }
Procedure Render(Full : Boolean);
Var I : LongInt;
Begin
  If Full Or (FullBg <> 0) Then
  Begin
    RenderBg;
    Move(Bg, Fb, SizeOf(Fb));
    TouchAll;
    PrN := 0; FullBg := 0;
  End
  Else
  Begin
    UpdateBg;
    For I := 0 To PrN - 1 Do CopyBg(PrX1[I], PrY1[I], PrX2[I], PrY2[I]);
  End;
  CuN := 0;
  DrawSprites;
  For I := 0 To CuN - 1 Do
  Begin
    PrX1[I] := CuX1[I]; PrY1[I] := CuY1[I]; PrX2[I] := CuX2[I]; PrY2[I] := CuY2[I];
  End;
  PrN := CuN;
End;

{ ==================================================================== }
{ Fenetre                                                               }
{ ==================================================================== }

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

{ recopie des bandes changees (bandes voisines de meme largeur reunies) }
Procedure BlitBands(H : LongInt);
Var B, B2 : LongInt;
Begin
  B := 0;
  While B < NBand Do
  Begin
    If BX2[B] >= BX1[B] Then
    Begin
      B2 := B;
      While (B2 + 1 < NBand) And (BX1[B2 + 1] = BX1[B]) And (BX2[B2 + 1] = BX2[B]) Do Inc(B2);
      BlitRect(H, BX1[B], B * BandH, BX2[B], B2 * BandH + BandH - 1);
      B := B2 + 1;
    End
    Else Inc(B);
  End;
  For B := 0 To NBand - 1 Do
  Begin
    BX1[B] := 0; BX2[B] := -1;
  End;
End;

Procedure SetMsg;
Begin
  If G.Paused <> 0 Then Msg := 'Pause : P pour reprendre.'
  Else If AutoAll <> 0 Then
    Msg := 'D' + Chr(130) + 'monstration : l''ordinateur joue (fl' + Chr(138) + 'che ou Espace : reprendre la main).'
  Else If G.State = ST_OVER Then Msg := 'Fin de la partie. F2 ou Entr' + Chr(130) + 'e : nouvelle partie.'
  Else If G.Bonus <> 0 Then Msg := 'Phase bonus : ramassez les 10 pi' + Chr(138) + 'ces avant la fin du temps.'
  Else If G.Carry <> 0 Then Msg := 'Lorenzo porte une clef : d' + Chr(130) + 'posez-la sur une plateforme du haut.'
  Else Msg := 'Fl' + Chr(138) + 'ches : avancer (Bas : arr' + Chr(136) + 't)  Espace : sauter  P : pause  F1 : r' +
              Chr(138) + 'gles';
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
  LastMsg := Msg;
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
  Render(True);
  BlitBands(Hps);
  SetMsg;
  DrawStatus;
  Dummy := WinEndPaint(Hps);
End;

{ recopie des zones changees (hors de WM_PAINT) }
Procedure Frame1;
Begin
  If (Client = 0) Or (TestMode <> 0) Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  Render(False);
  BlitBands(Hps);
  SetMsg;
  If Msg <> LastMsg Then DrawStatus;
  Dummy := WinReleasePS(Hps);
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
  SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0); SetMark(CM_PAUSE, G.Paused <> 0);
End;

Procedure TimerTick;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  If G.Paused = 0 Then
  Begin
    If AutoAll <> 0 Then AiThink;
    Step;
    If (G.State = ST_OVER) And (AutoAll <> 0) And (G.StT > 150) Then NewGame;
  End;
  Frame1;
End;

{ le joueur reprend la main pendant la demonstration }
Procedure TakeOver;
Begin
  If AutoAll <> 0 Then
  Begin
    AutoAll := 0;
    SetMarks;
  End;
End;

{ fleche : avancer ; la fleche opposee arrete d'abord Lorenzo }
Procedure PlayerDir(D : LongInt);
Begin
  TakeOver;
  If G.Paused <> 0 Then Exit;
  If (D <> 0) And (G.Want = -D) Then G.Want := 0 Else G.Want := D;
End;

Procedure PlayerJump;
Begin
  TakeOver;
  If G.Paused = 0 Then G.JumpBuf := 5;
End;

Procedure TogglePause;
Begin
  If G.State = ST_OVER Then Exit;
  G.Paused := 1 - G.Paused;
  SetMarks;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : Begin NewGame; SetMarks; End;
    CM_PAUSE : TogglePause;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_AUTO :
      Begin
        AutoAll := 1 - AutoAll;
        If (AutoAll <> 0) And (G.State = ST_OVER) Then NewGame;
        If AutoAll <> 0 Then G.Paused := 0;
        SetMarks;
      End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_RULES :
      Begin
        LClr;
        LAdd('Des ennemis sortent des tuyaux du haut. Sautez sous une plateforme pour frapper son dessous : ' +
             'l''ennemi au-dessus se retourne ; touchez-le pour l''' + Chr(130) + 'liminer avant qu''il se ' +
             'rel' + Chr(138) + 've (plus rapide). ');
        LAdd('Un ennemi debout co' + Chr(150) + 'te une vie. La phase finit quand tous sont ' + Chr(130) + 'limin' +
             Chr(130) + 's.' + Chr(10) + Chr(10));
        LAdd('Tortue, rat : un coup. Crabe, crocodile : deux coups. Mouche : seulement quand elle touche la ' +
             'plateforme. Verglas : un coup ; il g' + Chr(138) + 'le les plateformes. Pi' + Chr(138) + 'ces : 800 ' +
             'points.' + Chr(10) + Chr(10));
        LAdd('POW (3 coups par phase) : retourne les ennemis au sol. Clef de plombier : ramassez-la sur le ' +
             'plancher, d' + Chr(130) + 'posez-la en haut (1000, 2000... points). Phases 4 et 9 : bonus. ');
        LAdd(Chr(144) + 'liminations ' + Chr(133) + ' la suite : 800 ' + Chr(133) + ' 3200. Vie de plus ' + Chr(133) +
             ' 20 000 points.' + Chr(10) + Chr(10));
        LAdd('Fl' + Chr(138) + 'ches : avancer (Lorenzo continue ; la fl' + Chr(138) + 'che oppos' + Chr(130) +
             'e ou Bas l''arr' + Chr(136) + 'te), Espace : sauter, P : pause, F2 : nouvelle partie. Souris : clic ' +
             Chr(133) + ' gauche, ' + Chr(133) + ' droite, au-dessus de Lorenzo ou sur lui.');
        Dummy := LMsgBox('Le Plombier - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Le Plombier pour OS/2-0 (Presentation Manager), jeu de plateformes ' +
                            Chr(133) + ' un ' + Chr(130) + 'cran r' + Chr(130) + 'alis' + Chr(130) +
                            ' ' + Chr(133) + ' partir d''un prototype inachev' + Chr(130) + ' de 7iles.' + Chr(10) +
                            'Dessins et bruitages originaux. Programme ' + Chr(130) + 'crit en Pascal et compil' +
                            Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or MB_INFORMATION);
  End;
  Frame1;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt; R : Boolean;
Begin
  R := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And (KC_KEYUP Or KC_ALT Or KC_CTRL)) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Command(CM_RULES)
    Else If Vk = VK_F2 Then Command(CM_NEW)
    Else If Vk = VK_LEFT Then PlayerDir(-1)
    Else If Vk = VK_RIGHT Then PlayerDir(1)
    Else If (Vk = VK_UP) Or (Vk = VK_DOWN) Then PlayerDir(0)
    Else If Vk = VK_SPACE Then PlayerJump
    Else If Vk = VK_PAUSE Then TogglePause
    Else If (Vk = VK_ENTER) Or (Vk = VK_NEWLINE) Then
    Begin
      If G.State = ST_OVER Then Command(CM_NEW);
    End
    Else R := False;
    KeyChar := R;
    If R Then Exit;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    R := True;
    Case UpCase(Chr(Ch)) Of
      ' ' : PlayerJump;
      'P' : TogglePause;
    Else
      R := False;
    End;
    KeyChar := R;
    Exit;
  End;
  KeyChar := False;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, D, Dy : LongInt;
Begin
  X := Mx - OX; Y := CH - 1 - My - OY;
  If (X < 0) Or (Y < 0) Or (X >= BW) Or (Y >= BH) Then Exit;
  If G.State = ST_OVER Then
  Begin
    Command(CM_NEW);
    Exit;
  End;
  D := WrapD(X - G.LX Div SU);
  Dy := Y - (G.LY Div SU - LH Div 2);
  If (Abs(D) < 18) And (Abs(Dy) < 22) Then PlayerDir(0)
  Else If (Dy < -30) And (Abs(D) < 90) Then PlayerJump
  Else PlayerDir(Sgn(D));
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

{ phase N vide, Lorenzo sur le plancher }
Procedure TClear(N : LongInt);
Var I : LongInt;
Begin
  FillChar(G, SizeOf(G), 0);
  G.Lives := 3;
  StartPhase(N);
  For I := 0 To MaxE - 1 Do ClearEnt(I);
  G.State := ST_PLAY; G.WrNext := 999999; G.Score := 0;
End;

{ personnage de genre K pose sur le segment S en X }
Function TAdd(K, S, X : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := FreeEnt;
  ClearEnt(I);
  E[I].K := K; E[I].St := S_WALK; E[I].X := X * SU; E[I].Y := SegY[S] * SU; E[I].Gnd := S; E[I].T := 10;
  TAdd := I;
End;

Procedure TLor(S, X : LongInt);
Begin
  G.LX := X * SU; G.LY := SegY[S] * SU; G.LGnd := S; G.LVX := 0; G.LVY := 0; G.Want := 0; G.Nac := 0; G.Inv := 0;
  G.JumpBuf := 0;
End;

Procedure TRun(N : LongInt);
Var K : LongInt;
Begin
  For K := 1 To N Do
    If G.State = ST_PLAY Then Step;
End;

Function TJump(N : LongInt) : LongInt;
Begin
  G.JumpBuf := 4;
  TRun(N);
  TJump := G.Jumps;
End;

{ resume d'une phase : nombre de chaque genre (ordre T C M R K V P) }
Function Summary(N : LongInt) : String;
Var Q, R : String; Cnt : Array[0..7] Of LongInt; I, K : LongInt;
Begin
  Q := PhaseQ[N];
  For K := 0 To 7 Do Cnt[K] := 0;
  If Q = '*' Then Cnt[K_COIN] := 10
  Else
    For I := 1 To Length(Q) Do Inc(Cnt[KindOf(Q[I])]);
  R := '';
  For K := 1 To 7 Do
    If Cnt[K] > 0 Then R := R + '+' + IStr(Cnt[K]) + Copy('TCMRKVP', K, 1);
  Summary := Copy(R, 2, 255);
End;

Procedure RunTests;
Var Ok, A, B, C, D, F, I, K, T1, S1, Lim, St0 : LongInt; S : String; Good : Boolean;
Begin
  Ok := 0;
  Sim := 0;
  { 1 : geometrie des plateformes }
  A := (SegX2[7] - SegX1[7]) Div 20; B := (SegX2[8] - SegX1[8]) Div 20;
  C := (SegX2[4] - SegX1[4]) Div 20; D := (SegX2[5] - SegX1[5]) Div 20; F := (SegX2[6] - SegX1[6]) Div 20;
  I := (SegX2[1] - SegX1[1]) Div 20; K := (SegX2[2] - SegX1[2]) Div 20;
  Good := (SegX1[3] >= SegX2[1]) And (SegX2[3] <= SegX1[2]) And (SegY[3] = SegY[1]) And (SegY[1] = SegY[2]);
  S := 'haut ' + IStr(A) + '+' + IStr(B) + ' milieu ' + IStr(C) + '+' + IStr(D) + '+' + IStr(F) + ' bas ' + IStr(I);
  If Good Then S := S + '+POW+' Else S := S + '+?+';
  Log('PLOMBIER : TEST1 plateformes ' + S + IStr(K) + ' plancher ' + IStr(SegX2[0] Div 20) + ' carres');
  If (A = 13) And (B = 13) And (C = 3) And (D = 16) And (F = 3) And (I = 11) And (K = 11) And Good Then Inc(Ok);
  { 2 : tortue retournee par-dessous puis eliminee au contact }
  TClear(1);
  T1 := TAdd(K_TURT, 5, 170);
  TLor(1, 170);
  A := TJump(20);
  B := Ord(E[T1].St = S_FLIP);
  TLor(5, 236); G.Want := -1;
  TRun(30);
  C := Ord(E[T1].St = S_DEAD);
  D := 0;
  For I := 0 To MaxE - 1 Do
    If (E[I].K = K_COIN) And ((E[I].St = S_WAIT) Or (E[I].St = S_OUT)) Then Inc(D);
  Log('PLOMBIER : TEST2 tortue retournee ' + IStr(B) + ' eliminee ' + IStr(C) + ' points ' + IStr(G.Score) +
      ' piece qui sort du tuyau ' + IStr(D));
  If (A = 1) And (B = 1) And (C = 1) And (G.Score = 810) And (D = 1) And (G.Kills = 1) Then Inc(Ok);
  { 3 : crocodile : deux coups par-dessous }
  TClear(1);
  T1 := TAdd(K_CROC, 5, 170);
  TLor(1, 170);
  K := TJump(30);
  A := Ord((E[T1].St = S_WALK) And (E[T1].Hit = 1));
  E[T1].X := 170 * SU;
  K := TJump(30);
  B := Ord(E[T1].St = S_FLIP);
  Log('PLOMBIER : TEST3 crocodile 1er coup blesse ' + IStr(A) + ' (debout), 2e coup retourne ' + IStr(B) +
      ' sauts ' + IStr(K));
  If (A = 1) And (B = 1) And (K = 2) Then Inc(Ok);
  { 4 : crabe (deux coups), rat (un coup), mouche (seulement au sol) }
  TClear(5);
  T1 := TAdd(K_CRAB, 5, 170);
  TLor(1, 170);
  K := TJump(30);
  A := Ord((E[T1].St = S_WALK) And (E[T1].Hit = 1));
  E[T1].X := 170 * SU;
  K := TJump(30);
  B := Ord(E[T1].St = S_FLIP);
  TClear(2);
  T1 := TAdd(K_RAT, 5, 300);
  Bump(5, 300);
  C := Ord(E[T1].St = S_FLIP);
  TClear(7);
  T1 := TAdd(K_FLY, 5, 300);
  E[T1].Gnd := -1; E[T1].Y := 150 * SU; E[T1].VY := -20;
  Bump(5, 300);
  D := Ord(E[T1].St = S_FLIP);
  E[T1].Gnd := 5; E[T1].Y := 180 * SU; E[T1].VY := 0;
  Bump(5, 300);
  F := Ord(E[T1].St = S_FLIP);
  Log('PLOMBIER : TEST4 crabe 1er coup en colere ' + IStr(A) + ' 2e coup retourne ' + IStr(B) + ', rat un coup ' +
      IStr(C) + ', mouche en l''air ' + IStr(D) + ' au sol ' + IStr(F));
  If (A = 1) And (B = 1) And (C = 1) And (D = 0) And (F = 1) Then Inc(Ok);
  { 5 : bloc POW : tous les ennemis au sol, 3 coups puis il disparait }
  TClear(10);
  A := TAdd(K_TURT, 0, 100); B := TAdd(K_CRAB, 1, 60); C := TAdd(K_FLY, 8, 450); D := TAdd(K_ICE, 5, 200);
  K := TAdd(K_CROC, 2, 500);
  F := TAdd(K_FLY, 6, 560);
  E[F].Gnd := -1; E[F].Y := 120 * SU; E[F].VY := -40;
  TLor(0, 300);
  T1 := TJump(6);
  I := Ord(E[A].St = S_FLIP) + Ord(E[B].St = S_FLIP) + Ord(E[C].St = S_FLIP);
  S1 := Ord(E[D].St = S_GONE);
  St0 := G.PowLeft;
  S := 'POW ' + IStr(St0) + ' restants, retournes ' + IStr(I) + '/3, verglas detruit ' + IStr(S1) + ', crocodile ' +
       IStr(Ord(E[K].St = S_FLIP)) + ' (blesse ' + IStr(E[K].Hit) + '), mouche en l''air ' + IStr(Ord(E[F].St = S_FLIP));
  A := Ord((E[K].St = S_WALK) And (E[K].Hit = 1) And (E[F].St <> S_FLIP));
  Bump(3, 300); Bump(3, 300);
  Log('PLOMBIER : TEST5 ' + S + ', apres 3 coups POW ' + IStr(G.PowLeft) + ' existe ' + IStr(Ord(SegOk(3))));
  If (St0 = 2) And (I = 3) And (S1 = 1) And (A = 1) And (G.PowLeft = 0) And Not SegOk(3) Then Inc(Ok);
  { 6 : contenu des 10 phases }
  S := '';
  For I := 1 To 10 Do S := S + ' ' + IStr(I) + '=' + Summary(I);
  Log('PLOMBIER : TEST6 phases' + S);
  Good := S = ' 1=2T+1K 2=4T+2R 3=6T 4=10P 5=4C+1K 6=2T+4C+2R 7=4M+1R 8=2C+2M 9=10P 10=2T+1M+1V';
  TClear(4); A := 0;
  StartPhase(4);
  For I := 0 To MaxE - 1 Do
    If E[I].St = S_STAT Then Inc(A);
  StartPhase(9); B := G.AllIce; C := G.Bonus;
  StartPhase(11); D := G.PIdx; F := G.Spd;
  Log('PLOMBIER : TEST6 phase 4 pieces ' + IStr(A) + ', phase 9 glissante ' + IStr(B) + ' bonus ' + IStr(C) +
      ', phase 11 = phase ' + IStr(D) + ' vitesse ' + IStr(F) + ' %');
  If Good And (A = 10) And (B = 1) And (C = 1) And (D = 1) And (F = 115) Then Inc(Ok);
  { 7 : clef de plombier ramassee sur le plancher et deposee en haut }
  TClear(1);
  K := Queue(K_TURT, 0, 999999);
  G.WrX := 200; G.WrT := 300;
  TLor(0, 150); G.Want := 1;
  TRun(30);
  A := G.Carry;
  TLor(7, 100);
  TRun(2);
  B := G.DepN; C := G.Score;
  G.Carry := 1;
  TLor(8, 400);
  TRun(2);
  Log('PLOMBIER : TEST7 clef ramassee ' + IStr(A) + ', deposees ' + IStr(G.DepN) + ', bonus ' + IStr(C) + ' puis ' +
      IStr(G.Score));
  If (A = 1) And (B = 1) And (C = 1000) And (G.DepN = 2) And (G.Score = 3000) And (G.Carry = 0) Then Inc(Ok);
  { 8 : le verglas gele le milieu d'une plateforme, qui devient glissante }
  TClear(10);
  K := Queue(K_TURT, 0, 999999);
  A := TAdd(K_ICE, 5, 270);
  TRun(90);
  B := Icy[5];
  TLor(5, 200); G.LVX := RunV; G.Want := 0;
  TRun(8);
  C := G.LVX;
  TLor(1, 100); G.LVX := RunV; G.Want := 0;
  TRun(8);
  D := G.LVX;
  Log('PLOMBIER : TEST8 verglas ' + IStr(Ord(E[A].St = S_GONE)) + ' plateforme gelee ' + IStr(B) +
      ', vitesse apres 8 images sur la glace ' + IStr(C) + ', ailleurs ' + IStr(D));
  If (E[A].St = S_GONE) And (B = 1) And (C > 0) And (D = 0) Then Inc(Ok);
  { 9 : ennemis elimines a la suite, fin de phase, vie supplementaire }
  TClear(1);
  For I := 0 To 2 Do
  Begin
    K := TAdd(K_TURT, 0, 200 + I * 36);
    EntFlip(K);
    E[K].T := 500;
  End;
  TRun(20);
  G.Score := 0;
  TLor(0, 150); G.Want := 1;
  TRun(60);
  A := G.Score; B := G.Kills; C := G.State;
  G.Score := 19900; G.Extra := 0; D := G.Lives;
  AddPts(800);
  Log('PLOMBIER : TEST9 a la suite ' + IStr(B) + ' ennemis ' + IStr(A) + ' points, phase terminee ' +
      IStr(Ord(C = ST_CLEAR)) + ', vies ' + IStr(D) + ' puis ' + IStr(G.Lives) + ' a 20 000 points');
  If (A = 4800) And (B = 3) And (C = ST_CLEAR) And (G.Lives = D + 1) Then Inc(Ok);
  { partie reproductible jouee par l'ordinateur }
  Seed := 2026;
  FillChar(G, SizeOf(G), 0);
  StartPhase0 := 1;
  NewGame;
  Lim := 0;
  While (G.State <> ST_OVER) And (G.Phase <= 10) And (Lim < 40000) Do
  Begin
    AiThink;
    Step;
    Inc(Lim);
  End;
  Log('PLOMBIER : PARTIE images ' + IStr(Lim) + ' phase atteinte ' + IStr(G.Phase) + ' phases terminees ' +
      IStr(G.Cleared) + ' ennemis retournes ' + IStr(G.Flips) + ' elimines ' + IStr(G.Kills) + ' pieces ' +
      IStr(G.Coins) + ' clefs ' + IStr(G.WrTot) + ' POW ' + IStr(G.Pows) + ' sauts ' + IStr(G.Jumps) +
      ' vies perdues ' + IStr(G.Deaths) + ' pointage ' + IStr(G.Score));
  If (G.Cleared >= 10) And (G.Kills >= 20) And (G.State <> ST_OVER) Then Inc(Ok);
  Log('PLOMBIER : ' + IStr(Ok) + '/10 essais reussis');
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
  Flg, H0, H1, H2, H3, Sw, Sh, Fw, Fh, M, K, Er, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  InDlg := 0; Sim := 0; Tick := 0; AiAct := 0; AiPrev := 1;
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; LastMsg := ''; AutoAll := 0;
  Client := 0; Frame := 0; SoundOn := 1; SndCur := 0; SndEnd := 0; StartPhase0 := 1;
  TestMode := 0; CW := CWant; CH := CHWant; FullBg := 1; PrN := 0; CuN := 0; ClipL := 0; ClipR := BW - 1;
  For K := 0 To NBand - 1 Do
  Begin
    BX1[K] := 0; BX2[K] := -1;
  End;
  For K := 0 To MaxPop - 1 Do PopT[K] := 0;
  FillChar(G, SizeOf(G), 0);
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For Er := 1 To Length(S) Do S[Er] := UpCase(S[Er]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, Er);
    If (Length(S) > 7) And (Copy(S, 1, 7) = '/PHASE:') Then
    Begin
      Val(Copy(S, 8, 20), StartPhase0, Er);
      If StartPhase0 < 1 Then StartPhase0 := 1;
      If StartPhase0 > 99 Then StartPhase0 := 99;
    End;
    If S = '/AUTO' Then AutoAll := 1;
    If S = '/NOSOUND' Then SoundOn := 0;
    If S = '/TEST' Then TestMode := 1;
  End;
  InitCMap;
  If TestMode <> 0 Then
  Begin
    RunTests;
    Halt(0);
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  InitBmi;
  MakeSounds;
  NewGame;
  Dummy := WinRegisterClass(Hab, Z('PLOMBIER'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('PLOMBIER'), Z2('Le Plombier'), 0, 0, 0,
                              LongInt(@Client));
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
  MItem(MIS_TEXT, 0, CM_AUTO, '~D' + Chr(130) + 'monstration');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MenuClose(H3, 2);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos du Plombier');
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
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  Dummy := WinStartTimer(Hab, Client, 1, 30);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
