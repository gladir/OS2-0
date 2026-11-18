{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BATTLE - bataille navale pour le Presentation Manager
                d'OS/2-0 (dossier Jeux du bureau), en cinq langues.
}

Program BATTLE;

{$R-,S-,I-}

{ Compilation : OS2PC BATTLE.PAS   (produit BATTLE.EXE)

  Le jeu classique de la bataille navale, ecrit pour OS/2-0 (pas de
  prototype) : chaque joueur place en secret sa flotte sur une grille de
  10 x 10 (porte-avions 5 cases, cuirasse 4, croiseur 3, sous-marin 3,
  torpilleur 2), puis on tire a tour de role sur une case de la grille
  adverse : dans l'eau ou touche ; un navire dont toutes les cases sont
  touchees est coule ; le premier qui coule toute la flotte adverse gagne.
  Option tir en salve : autant de tirs par tour que de navires a flot.

  Modes : humain contre l'ordinateur (par defaut), deux joueurs (a tour de
  role devant l'ecran : un rideau cache la flotte de l'autre) ou
  ordinateur contre ordinateur. L'ordinateur Normal tire selon la densite
  des positions encore possibles des navires restants et acheve les
  navires touches ; Facile tire au hasard autour de ses coups au but.

  Langues : francais, anglais, espagnol, italien et allemand (menu Langue ;
  au depart, la langue du systeme : SET LANGUAGE= de CONFIG.SYS, ou le
  parametre /LANG:FR, EN, ES, IT ou DE).

  Souris : cliquer une case (placer un navire, le reprendre, tirer) ;
  bouton 2 : pivoter le navire a placer. Clavier : fleches, Entree ou
  Espace (placer ou tirer), R (pivoter), A (placement au hasard), F2
  (nouvelle partie), F1 (regles).
  Parametres : /SEED:n ; /AUTO (ordinateur contre ordinateur). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON2DOWN = $0074; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_QUERY = $10; MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_NEWLINE = $08; VK_ESC = $0F; VK_SPACE = $10; VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18;
  VK_ENTER = $1E; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_QUIT = 104; CM_HVC = 111; CM_HVH = 112; CM_CVC = 113;
  CM_EASY = 121; CM_NORMAL = 122; CM_SALVO = 131;
  CM_LANG0 = 201;                   { 201 a 205 : langues }
  CM_RULES = 301; CM_ABOUT = 302;
  NShip = 5;
  { disposition (zone client, Y vers le bas) }
  Cs = 24; LX = 36; RX = 340; GY = 48; GW = 240;
  PanY = 298;
  CWant = 604; CHWant = 436;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Lang : LongInt;                   { 0 francais, 1 anglais, 2 espagnol, 3 italien, 4 allemand }
  SLen : Array[0..NShip - 1] Of LongInt;
  SPos, SDir, SHits : Array[0..2 * NShip - 1] Of LongInt;   { joueur * 5 + navire ; SPos -1 : pas place }
  Own : Array[0..199] Of LongInt;   { joueur * 100 + case : navire + 1 }
  Shot : Array[0..199] Of LongInt;  { tirs recus : 0 rien, 1 dans l'eau, 2 touche }
  NShots, NHits, LastShot, Kind : Array[0..1] Of LongInt;   { Kind : 0 humain, 1 ordinateur }
  Weight : Array[0..99] Of LongInt;
  Mode, Level, Salvo, Phase, Placer, Turn, ShotsLeft, CurShip, PDir, Hover, Cur, Curtain, Over, Winner : LongInt;
  Wait, Seed, AutoAll : LongInt;
  Msg : String;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  MenuT : Array[0..2047] Of Byte;
  MenuLen : LongInt;
  Font : Array[0..4095] Of Byte;
  FontH : LongInt;
  Qmsg : Array[0..7] Of LongInt;

{ textes (genere par bt_strings.py) : 0 francais, 1 anglais, 2 espagnol,
  3 italien, 4 allemand }
Const
  T_TITLE = 1;
  T_MGAME = 2;
  T_MNEW = 3;
  T_MHVC = 4;
  T_MHVH = 5;
  T_MCVC = 6;
  T_MEASY = 7;
  T_MNORMAL = 8;
  T_MSALVO = 9;
  T_MQUIT = 10;
  T_MLANG = 11;
  T_MHELP = 12;
  T_MRULES = 13;
  T_MABOUT = 14;
  T_FLEETOF = 15;
  T_YOURFLEET = 16;
  T_ENEMYFLEET = 17;
  T_SHIP0 = 18;
  T_SHIP1 = 19;
  T_SHIP2 = 20;
  T_SHIP3 = 21;
  T_SHIP4 = 22;
  T_YOU = 23;
  T_COMPUTER = 24;
  T_COMPUTERN = 25;
  T_PLAYERN = 26;
  T_PLACE1 = 27;
  T_PLACE2 = 28;
  T_PLACE3 = 29;
  T_PLACE4 = 30;
  T_PLACE5 = 31;
  T_PLACEMSG = 32;
  T_BROTATE = 33;
  T_BRANDOM = 34;
  T_BCLEAR = 35;
  T_BDONE = 36;
  T_TOPLACE = 37;
  T_ALLPLACED = 38;
  T_NOTFIT = 39;
  T_YOURTURN = 40;
  T_AIMING = 41;
  T_MISS = 42;
  T_HIT = 43;
  T_SUNK = 44;
  T_ALREADY = 45;
  T_WINS = 46;
  T_NEWQ = 47;
  T_STATS = 48;
  T_CURT1 = 49;
  T_CURT2 = 50;
  T_CURT3 = 51;
  T_CURTPLACE = 52;
  T_SUNKW = 53;
  T_SALVOON = 54;
  T_GAMEOVER = 55;
  T_DEMO = 56;
  T_ACCURACY = 57;
  T_RULES1 = 58;
  T_RULES2 = 59;
  T_RULES3 = 60;
  T_RULES4 = 61;
  T_ABOUT1 = 62;
  T_ABOUT2 = 63;
  T_RULESCAP = 64;
  T_ABOUTCAP = 65;
  T_LEVEL = 66;
  T_EASY = 67;
  T_NORMAL = 68;

Function Tx(N : LongInt) : String;
Begin
  Tx := '';
  Case N * 8 + Lang Of
    8 : Tx := 'Bataille navale';
    9 : Tx := 'Battleship';
    10 : Tx := 'Batalla naval';
    11 : Tx := 'Battaglia navale';
    12 : Tx := 'Schiffe versenken';
    16 : Tx := '~Partie';
    17 : Tx := '~Game';
    18 : Tx := '~Partida';
    19 : Tx := '~Partita';
    20 : Tx := '~Spiel';
    24 : Tx := '~Nouvelle partie';
    25 : Tx := '~New game';
    26 : Tx := '~Nueva partida';
    27 : Tx := '~Nuova partita';
    28 : Tx := '~Neues Spiel';
    32 : Tx := 'Humain contre l''~ordinateur';
    33 : Tx := 'Human vs ~computer';
    34 : Tx := 'Humano contra ~ordenador';
    35 : Tx := 'Umano contro ~computer';
    36 : Tx := 'Mensch gegen ~Computer';
    40 : Tx := '~Deux joueurs';
    41 : Tx := '~Two players';
    42 : Tx := '~Dos jugadores';
    43 : Tx := '~Due giocatori';
    44 : Tx := '~Zwei Spieler';
    48 : Tx := 'Ordinateur contre ordinateur';
    49 : Tx := 'Computer vs computer';
    50 : Tx := 'Ordenador contra ordenador';
    51 : Tx := 'Computer contro computer';
    52 : Tx := 'Computer gegen Computer';
    56 : Tx := 'Ordinateur ~facile';
    57 : Tx := '~Easy computer';
    58 : Tx := 'Ordenador ~f' + Chr(160) + 'cil';
    59 : Tx := 'Computer ~facile';
    60 : Tx := '~Leichter Computer';
    64 : Tx := 'Ordinateur ~normal';
    65 : Tx := 'N~ormal computer';
    66 : Tx := 'Ordenador ~normal';
    67 : Tx := 'Computer ~normale';
    68 : Tx := '~Normaler Computer';
    72 : Tx := 'Tir en ~salve';
    73 : Tx := '~Salvo fire';
    74 : Tx := 'Disparo en ~salva';
    75 : Tx := 'Tiro a ~salve';
    76 : Tx := 'Sal~venfeuer';
    80 : Tx := '~Quitter';
    81 : Tx := '~Quit';
    82 : Tx := '~Salir';
    83 : Tx := '~Esci';
    84 : Tx := '~Beenden';
    88 : Tx := '~Langue';
    89 : Tx := '~Language';
    90 : Tx := '~Idioma';
    91 : Tx := '~Lingua';
    92 : Tx := 'Spr~ache';
    96 : Tx := 'A~ide';
    97 : Tx := '~Help';
    98 : Tx := 'A~yuda';
    99 : Tx := 'A~iuto';
    100 : Tx := '~Hilfe';
    104 : Tx := '~R' + Chr(138) + 'gles du jeu';
    105 : Tx := 'Game ~rules';
    106 : Tx := '~Reglas del juego';
    107 : Tx := '~Regole del gioco';
    108 : Tx := 'Spiel~regeln';
    112 : Tx := '~A propos';
    113 : Tx := '~About';
    114 : Tx := '~Acerca de';
    115 : Tx := '~Informazioni';
    116 : Tx := '~' + Chr(154) + 'ber das Spiel';
    120 : Tx := 'Flotte : %';
    121 : Tx := 'Fleet: %';
    122 : Tx := 'Flota: %';
    123 : Tx := 'Flotta: %';
    124 : Tx := 'Flotte: %';
    128 : Tx := 'Votre flotte';
    129 : Tx := 'Your fleet';
    130 : Tx := 'Tu flota';
    131 : Tx := 'La tua flotta';
    132 : Tx := 'Deine Flotte';
    136 : Tx := 'Flotte ennemie';
    137 : Tx := 'Enemy fleet';
    138 : Tx := 'Flota enemiga';
    139 : Tx := 'Flotta nemica';
    140 : Tx := 'Feindliche Flotte';
    144 : Tx := 'Porte-avions';
    145 : Tx := 'Carrier';
    146 : Tx := 'Portaaviones';
    147 : Tx := 'Portaerei';
    148 : Tx := 'Flugzeugtr' + Chr(132) + 'ger';
    152 : Tx := 'Cuirass' + Chr(130);
    153 : Tx := 'Battleship';
    154 : Tx := 'Acorazado';
    155 : Tx := 'Corazzata';
    156 : Tx := 'Schlachtschiff';
    160 : Tx := 'Croiseur';
    161 : Tx := 'Cruiser';
    162 : Tx := 'Crucero';
    163 : Tx := 'Incrociatore';
    164 : Tx := 'Kreuzer';
    168 : Tx := 'Sous-marin';
    169 : Tx := 'Submarine';
    170 : Tx := 'Submarino';
    171 : Tx := 'Sommergibile';
    172 : Tx := 'U-Boot';
    176 : Tx := 'Torpilleur';
    177 : Tx := 'Destroyer';
    178 : Tx := 'Destructor';
    179 : Tx := 'Caccia';
    180 : Tx := 'Zerst' + Chr(148) + 'rer';
    184 : Tx := 'Vous';
    185 : Tx := 'You';
    186 : Tx := 'Usted';
    187 : Tx := 'Tu';
    188 : Tx := 'Du';
    192 : Tx := 'Ordinateur';
    193 : Tx := 'Computer';
    194 : Tx := 'Ordenador';
    195 : Tx := 'Computer';
    196 : Tx := 'Computer';
    200 : Tx := 'Ordinateur %';
    201 : Tx := 'Computer %';
    202 : Tx := 'Ordenador %';
    203 : Tx := 'Computer %';
    204 : Tx := 'Computer %';
    208 : Tx := 'Joueur %';
    209 : Tx := 'Player %';
    210 : Tx := 'Jugador %';
    211 : Tx := 'Giocatore %';
    212 : Tx := 'Spieler %';
    216 : Tx := 'Placez vos navires :';
    217 : Tx := 'Place your ships:';
    218 : Tx := 'Coloque sus barcos:';
    219 : Tx := 'Posiziona le navi:';
    220 : Tx := 'Schiffe aufstellen:';
    224 : Tx := 'cliquez sur votre grille ;';
    225 : Tx := 'click on your grid;';
    226 : Tx := 'clic en su cuadr' + Chr(161) + 'cula;';
    227 : Tx := 'clic sulla tua griglia;';
    228 : Tx := 'eigenes Raster anklicken;';
    232 : Tx := 'bouton 2 ou R : pivoter ;';
    233 : Tx := 'button 2 or R: rotate;';
    234 : Tx := 'bot' + Chr(162) + 'n 2 o R: girar;';
    235 : Tx := 'pulsante 2 o R: ruota;';
    236 : Tx := 'Taste 2 oder R: drehen;';
    240 : Tx := 'clic sur un navire plac' + Chr(130) + ' :';
    241 : Tx := 'click a placed ship:';
    242 : Tx := 'clic en un barco colocado:';
    243 : Tx := 'clic su una nave posata:';
    244 : Tx := 'gesetztes Schiff anklicken:';
    248 : Tx := 'le reprendre.';
    249 : Tx := 'pick it up again.';
    250 : Tx := 'recogerlo.';
    251 : Tx := 'riprenderla.';
    252 : Tx := 'wieder aufnehmen.';
    256 : Tx := 'Placez vos navires : clic sur votre grille, R ou bouton 2 pour pivoter.';
    257 : Tx := 'Place your ships: click your grid, R or button 2 to rotate.';
    258 : Tx := 'Coloque sus barcos: clic en su cuadr' + Chr(161) + 'cula, R o bot' + Chr(162) + 'n 2 para girar.';
    259 : Tx := 'Posiziona le navi: clic sulla griglia, R o pulsante 2 per ruotare.';
    260 : Tx := 'Schiffe setzen: aufs Raster klicken, R oder Taste 2 zum Drehen.';
    264 : Tx := 'Pivoter (R)';
    265 : Tx := 'Rotate (R)';
    266 : Tx := 'Girar (R)';
    267 : Tx := 'Ruota (R)';
    268 : Tx := 'Drehen (R)';
    272 : Tx := 'Au hasard (A)';
    273 : Tx := 'Random (A)';
    274 : Tx := 'Al azar (A)';
    275 : Tx := 'A caso (A)';
    276 : Tx := 'Zuf' + Chr(132) + 'llig (A)';
    280 : Tx := 'Effacer';
    281 : Tx := 'Clear';
    282 : Tx := 'Borrar';
    283 : Tx := 'Cancella';
    284 : Tx := 'L' + Chr(148) + 'schen';
    288 : Tx := 'Terminer';
    289 : Tx := 'Done';
    290 : Tx := 'Listo';
    291 : Tx := 'Fatto';
    292 : Tx := 'Fertig';
    296 : Tx := 'A placer : % (% cases)';
    297 : Tx := 'To place: % (% squares)';
    298 : Tx := 'A colocar: % (% casillas)';
    299 : Tx := 'Da posizionare: % (% caselle)';
    300 : Tx := 'Zu setzen: % (% Felder)';
    304 : Tx := 'Flotte en place : cliquez Terminer (ou Entr' + Chr(130) + 'e).';
    305 : Tx := 'Fleet ready: click Done (or Enter).';
    306 : Tx := 'Flota lista: pulse Listo (o Intro).';
    307 : Tx := 'Flotta pronta: clic su Fatto (o Invio).';
    308 : Tx := 'Flotte bereit: Fertig klicken (oder Eingabe).';
    312 : Tx := 'Le navire ne tient pas ici.';
    313 : Tx := 'The ship does not fit here.';
    314 : Tx := 'El barco no cabe aqu' + Chr(161) + '.';
    315 : Tx := 'La nave non entra qui.';
    316 : Tx := 'Das Schiff passt hier nicht.';
    320 : Tx := '% : tirez sur la grille ennemie (% tir(s)).';
    321 : Tx := '%: fire at the enemy grid (% shot(s)).';
    322 : Tx := '%: dispare a la cuadr' + Chr(161) + 'cula enemiga (% disparo(s)).';
    323 : Tx := '%: spara sulla griglia nemica (% colpo/i).';
    324 : Tx := '%: auf das feindliche Raster schie' + Chr(225) + 'en (% Schuss).';
    328 : Tx := '% vise...';
    329 : Tx := '% is aiming...';
    330 : Tx := '% apunta...';
    331 : Tx := '% mira...';
    332 : Tx := '% zielt...';
    336 : Tx := '% en % : dans l''eau.';
    337 : Tx := '% at %: miss.';
    338 : Tx := '% en %: agua.';
    339 : Tx := '% in %: acqua.';
    340 : Tx := '% auf %: Wasser.';
    344 : Tx := '% en % : touch' + Chr(130) + ' !';
    345 : Tx := '% at %: hit!';
    346 : Tx := '% en %: ' + Chr(173) + 'tocado!';
    347 : Tx := '% in %: colpito!';
    348 : Tx := '% auf %: Treffer!';
    352 : Tx := '% en % : touch' + Chr(130) + '-coul' + Chr(130) + ' (%) !';
    353 : Tx := '% at %: hit and sunk (%)!';
    354 : Tx := '% en %: ' + Chr(173) + 'tocado y hundido (%)!';
    355 : Tx := '% in %: colpito e affondato (%)!';
    356 : Tx := '% auf %: versenkt (%)!';
    360 : Tx := 'Vous avez d' + Chr(130) + 'j' + Chr(133) + ' tir' + Chr(130) + ' sur cette case.';
    361 : Tx := 'You already fired at this square.';
    362 : Tx := 'Ya dispar' + Chr(162) + ' a esta casilla.';
    363 : Tx := 'Hai gi' + Chr(133) + ' sparato su questa casella.';
    364 : Tx := 'Auf dieses Feld wurde schon geschossen.';
    368 : Tx := '% gagne : toute la flotte adverse est coul' + Chr(130) + 'e !';
    369 : Tx := '% wins: the whole enemy fleet is sunk!';
    370 : Tx := '' + Chr(173) + '% gana: toda la flota enemiga est' + Chr(160) + ' hundida!';
    371 : Tx := '% vince: tutta la flotta nemica ' + Chr(138) + ' affondata!';
    372 : Tx := '% gewinnt: die ganze feindliche Flotte ist versenkt!';
    376 : Tx := 'Une nouvelle partie ?';
    377 : Tx := 'A new game?';
    378 : Tx := '' + Chr(168) + 'Una nueva partida?';
    379 : Tx := 'Una nuova partita?';
    380 : Tx := 'Ein neues Spiel?';
    384 : Tx := 'Tirs : %  Touch' + Chr(130) + 's : %';
    385 : Tx := 'Shots: %  Hits: %';
    386 : Tx := 'Disparos: %  Aciertos: %';
    387 : Tx := 'Colpi: %  A segno: %';
    388 : Tx := 'Sch' + Chr(129) + 'sse: %  Treffer: %';
    392 : Tx := '% : ' + Chr(133) + ' vous !';
    393 : Tx := '%: your turn!';
    394 : Tx := '%: ' + Chr(173) + 'le toca!';
    395 : Tx := '%: tocca a te!';
    396 : Tx := '%: du bist dran!';
    400 : Tx := 'L''autre joueur ne regarde pas l''' + Chr(130) + 'cran.';
    401 : Tx := 'The other player looks away.';
    402 : Tx := 'El otro jugador no mira la pantalla.';
    403 : Tx := 'L''altro giocatore non guarda lo schermo.';
    404 : Tx := 'Der andere Spieler schaut weg.';
    408 : Tx := 'Cliquez ou appuyez sur Entr' + Chr(130) + 'e.';
    409 : Tx := 'Click or press Enter.';
    410 : Tx := 'Haga clic o pulse Intro.';
    411 : Tx := 'Fai clic o premi Invio.';
    412 : Tx := 'Klicken oder Eingabe dr' + Chr(129) + 'cken.';
    416 : Tx := '% : placez votre flotte.';
    417 : Tx := '%: place your fleet.';
    418 : Tx := '%: coloque su flota.';
    419 : Tx := '%: posiziona la tua flotta.';
    420 : Tx := '%: stelle deine Flotte auf.';
    424 : Tx := 'coul' + Chr(130);
    425 : Tx := 'sunk';
    426 : Tx := 'hundido';
    427 : Tx := 'affondato';
    428 : Tx := 'versenkt';
    432 : Tx := 'Tir en salve : un tir par navire ' + Chr(133) + ' flot.';
    433 : Tx := 'Salvo fire: one shot per ship afloat.';
    434 : Tx := 'Disparo en salva: un disparo por barco a flote.';
    435 : Tx := 'Tiro a salve: un colpo per nave a galla.';
    436 : Tx := 'Salvenfeuer: ein Schuss pro schwimmendem Schiff.';
    440 : Tx := 'Partie termin' + Chr(130) + 'e : % gagne.  F2 : nouvelle partie.';
    441 : Tx := 'Game over: % wins.  F2: new game.';
    442 : Tx := 'Fin de la partida: % gana.  F2: nueva partida.';
    443 : Tx := 'Partita finita: % vince.  F2: nuova partita.';
    444 : Tx := 'Spielende: % gewinnt.  F2: neues Spiel.';
    448 : Tx := 'D' + Chr(130) + 'monstration : l''ordinateur joue les deux flottes.';
    449 : Tx := 'Demonstration: the computer plays both fleets.';
    450 : Tx := 'Demostraci' + Chr(162) + 'n: el ordenador juega con las dos flotas.';
    451 : Tx := 'Dimostrazione: il computer gioca con le due flotte.';
    452 : Tx := 'Vorf' + Chr(129) + 'hrung: der Computer spielt beide Flotten.';
    456 : Tx := 'Pr' + Chr(130) + 'cision : % %';
    457 : Tx := 'Accuracy: % %';
    458 : Tx := 'Precisi' + Chr(162) + 'n: % %';
    459 : Tx := 'Precisione: % %';
    460 : Tx := 'Trefferquote: % %';
    464 : Tx := 'Chaque joueur place en secret sa flotte sur une grille de 10 x 10 : porte-avions (5 cases), cuirass' + Chr(130) + ' (4), croiseur (3), sous-marin (3) et torpilleur (2), ' + Chr(133) + ' l''horizontale ou ' + Chr(133) + ' la verticale, sans chevauchement. ';
    465 : Tx := 'Each player secretly places a fleet on a 10 x 10 grid: aircraft carrier (5 squares), battleship (4), cruiser (3), submarine (3) and destroyer (2), horizontally or vertically, without overlapping. ';
    466 : Tx := 'Cada jugador coloca en secreto su flota en una cuadr' + Chr(161) + 'cula de 10 x 10: portaaviones (5 casillas), acorazado (4), crucero (3), submarino (3) y destructor (2), en horizontal o en vertical, sin superponerse. ';
    467 : Tx := 'Ogni giocatore posiziona in segreto la sua flotta su una griglia di 10 x 10: portaerei (5 caselle), corazzata (4), incrociatore (3), sommergibile (3) e cacciatorpediniere (2), in orizzontale o in verticale, senza sovrapporle. ';
    468 : Tx := 'Jeder Spieler stellt seine Flotte geheim auf einem 10 x 10 Raster auf: Flugzeugtr' + Chr(132) + 'ger (5 Felder), Schlachtschiff (4), Kreuzer (3), U-Boot (3) und Zerst' + Chr(148) + 'rer (2), waagrecht oder senkrecht, ohne ' + Chr(154) + 'berlappung. ';
    472 : Tx := 'Puis chacun tire ' + Chr(133) + ' son tour sur une case de la grille adverse : dans l''eau (point blanc) ou touch' + Chr(130) + ' (feu). Un navire dont toutes les cases sont touch' + Chr(130) + 'es est coul' + Chr(130) + '. Le premier qui coule toute la flotte adverse gagne. ';
    473 : Tx := 'Then the players take turns firing at a square of the enemy grid: miss (white dot) or hit (fire). A ship whose squares are all hit is sunk. The first to sink the whole enemy fleet wins. ';
    474 : Tx := 'Luego cada uno dispara por turnos a una casilla de la cuadr' + Chr(161) + 'cula enemiga: agua (punto blanco) o tocado (fuego). Un barco con todas sus casillas tocadas est' + Chr(160) + ' hundido. Gana el primero que hunde toda la flota enemiga. ';
    475 : Tx := 'Poi ognuno spara a turno su una casella della griglia nemica: acqua (punto bianco) o colpito (fuoco). Una nave con tutte le caselle colpite ' + Chr(138) + ' affondata. Vince chi affonda per primo tutta la flotta nemica. ';
    476 : Tx := 'Dann schie' + Chr(225) + 't jeder abwechselnd auf ein Feld des feindlichen Rasters: Wasser (wei' + Chr(225) + 'er Punkt) oder Treffer (Feuer). Ein Schiff, dessen Felder alle getroffen sind, ist versenkt. Wer zuerst die ganze feindliche Flotte versenkt, gewinnt. ';
    480 : Tx := 'Tir en salve : autant de tirs par tour que de navires encore ' + Chr(133) + ' flot.';
    481 : Tx := 'Salvo fire: as many shots per turn as ships still afloat.';
    482 : Tx := 'Disparo en salva: tantos disparos por turno como barcos a flote.';
    483 : Tx := 'Tiro a salve: tanti colpi per turno quante navi ancora a galla.';
    484 : Tx := 'Salvenfeuer: so viele Sch' + Chr(129) + 'sse pro Zug wie Schiffe noch schwimmen.';
    488 : Tx := 'Souris : cliquer une case. Clavier : fl' + Chr(138) + 'ches, Entr' + Chr(130) + 'e ou Espace (placer ou tirer), R (pivoter), A (placement au hasard), F2 (nouvelle partie), F1 (r' + Chr(138) + 'gles).';
    489 : Tx := 'Mouse: click a square. Keyboard: arrows, Enter or Space (place or fire), R (rotate), A (random placement), F2 (new game), F1 (rules).';
    490 : Tx := 'Rat' + Chr(162) + 'n: clic en una casilla. Teclado: flechas, Intro o Espacio (colocar o disparar), R (girar), A (colocaci' + Chr(162) + 'n al azar), F2 (nueva partida), F1 (reglas).';
    491 : Tx := 'Mouse: clic su una casella. Tastiera: frecce, Invio o Spazio (posizionare o sparare), R (ruotare), A (posizionamento a caso), F2 (nuova partita), F1 (regole).';
    492 : Tx := 'Maus: ein Feld anklicken. Tastatur: Pfeile, Eingabe oder Leertaste (setzen oder schie' + Chr(225) + 'en), R (drehen), A (zuf' + Chr(132) + 'llig aufstellen), F2 (neues Spiel), F1 (Regeln).';
    496 : Tx := 'Bataille navale pour OS/2-0 (Presentation Manager) : contre l''ordinateur, ' + Chr(133) + ' deux joueurs ou ordinateur contre ordinateur, en cinq langues (menu Langue).';
    497 : Tx := 'Battleship for OS/2-0 (Presentation Manager): against the computer, two players or computer vs computer, in five languages (Language menu).';
    498 : Tx := 'Batalla naval para OS/2-0 (Presentation Manager): contra el ordenador, dos jugadores u ordenador contra ordenador, en cinco idiomas (men' + Chr(163) + ' Idioma).';
    499 : Tx := 'Battaglia navale per OS/2-0 (Presentation Manager): contro il computer, due giocatori o computer contro computer, in cinque lingue (menu Lingua).';
    500 : Tx := 'Schiffe versenken f' + Chr(129) + 'r OS/2-0 (Presentation Manager): gegen den Computer, zu zweit oder Computer gegen Computer, in f' + Chr(129) + 'nf Sprachen (Men' + Chr(129) + ' Sprache).';
    504 : Tx := 'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) + ' par OS2PC.';
    505 : Tx := 'Program written in Pascal and compiled by OS2PC.';
    506 : Tx := 'Programa escrito en Pascal y compilado por OS2PC.';
    507 : Tx := 'Programma scritto in Pascal e compilato da OS2PC.';
    508 : Tx := 'Programm in Pascal geschrieben und mit OS2PC ' + Chr(129) + 'bersetzt.';
    512 : Tx := 'Bataille navale - R' + Chr(138) + 'gles';
    513 : Tx := 'Battleship - Rules';
    514 : Tx := 'Batalla naval - Reglas';
    515 : Tx := 'Battaglia navale - Regole';
    516 : Tx := 'Schiffe versenken - Regeln';
    520 : Tx := 'A propos de la bataille navale';
    521 : Tx := 'About Battleship';
    522 : Tx := 'Acerca de la batalla naval';
    523 : Tx := 'Informazioni sulla battaglia navale';
    524 : Tx := '' + Chr(154) + 'ber Schiffe versenken';
    528 : Tx := 'Ordinateur : %';
    529 : Tx := 'Computer: %';
    530 : Tx := 'Ordenador: %';
    531 : Tx := 'Computer: %';
    532 : Tx := 'Computer: %';
    536 : Tx := 'facile';
    537 : Tx := 'easy';
    538 : Tx := 'f' + Chr(160) + 'cil';
    539 : Tx := 'facile';
    540 : Tx := 'leicht';
    544 : Tx := 'normal';
    545 : Tx := 'normal';
    546 : Tx := 'normal';
    547 : Tx := 'normale';
    548 : Tx := 'normal';
  End;
End;

Function LangName(L : LongInt) : String;
Begin
  Case L Of
    0 : LangName := 'Fran' + Chr(135) + 'ais';
    1 : LangName := 'English';
    2 : LangName := 'Espa' + Chr(164) + 'ol';
    3 : LangName := 'Italiano';
    4 : LangName := 'Deutsch';
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

Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function DosScanEnv(PName, PVal : LongInt) : LongInt; External 'DOSCALLS';

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;

{ remplace le premier % de S par A }
Function Fmt1(S, A : String) : String;
Var K : LongInt;
Begin
  K := Pos('%', S);
  If K > 0 Then Fmt1 := Copy(S, 1, K - 1) + A + Copy(S, K + 1, 255) Else Fmt1 := S;
End;

Function Fmt2(S, A, B : String) : String;
Begin
  Fmt2 := Fmt1(Fmt1(S, A), B);
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do If (S[K] >= 'a') And (S[K] <= 'z') Then S[K] := Chr(Ord(S[K]) - 32);
  UpStr := S;
End;

{ langue d'apres un code (FR, EN, ES ou SP, IT, DE ou GR) }
Function LangOf(S : String) : LongInt;
Begin
  S := UpStr(S);
  If S = 'FR' Then LangOf := 0
  Else If (S = 'ES') Or (S = 'SP') Then LangOf := 2
  Else If S = 'IT' Then LangOf := 3
  Else If (S = 'DE') Or (S = 'GR') Then LangOf := 4
  Else If S = '' Then LangOf := 0
  Else LangOf := 1;
End;

{ variable LANGUAGE de l'environnement (SET LANGUAGE= de CONFIG.SYS) }
Function EnvLang : String;
Var P, K : LongInt; S : String; Q : ^Byte;
Begin
  EnvLang := '';
  P := 0;
  If DosScanEnv(Z('LANGUAGE'), LongInt(@P)) <> 0 Then Exit;
  If P = 0 Then Exit;
  S := '';
  K := 0;
  Repeat
    Q := Pointer(P + K);
    If Q^ <> 0 Then S := S + Chr(Q^);
    Inc(K);
  Until (Q^ = 0) Or (K > 8);
  EnvLang := S;
End;

Function ShipName(S : LongInt) : String;
Begin
  ShipName := Tx(T_SHIP0 + S);
End;

Function Opp(P : LongInt) : LongInt;
Begin
  Opp := 1 - P;
End;

Function PName(P : LongInt) : String;
Begin
  If Mode = 0 Then
  Begin
    If P = 0 Then PName := Tx(T_YOU) Else PName := Tx(T_COMPUTER);
  End
  Else If Mode = 1 Then PName := Fmt1(Tx(T_PLAYERN), IStr(P + 1))
  Else PName := Fmt1(Tx(T_COMPUTERN), IStr(P + 1));
End;

Function SqName(C : LongInt) : String;
Begin
  SqName := Chr(65 + C Mod 10) + IStr(C Div 10 + 1);
End;

{ ==================================================================== }
{ Flottes                                                               }
{ ==================================================================== }

{ case K du navire place en C dans la direction D }
Function ShipCell(C, D, K : LongInt) : LongInt;
Begin
  If D = 0 Then ShipCell := C + K Else ShipCell := C + 10 * K;
End;

Function CanPlace(P, S, C, D : LongInt) : Boolean;
Var K, Q : LongInt;
Begin
  CanPlace := False;
  If (C < 0) Or (C > 99) Then Exit;
  If (D = 0) And (C Mod 10 + SLen[S] > 10) Then Exit;
  If (D = 1) And (C Div 10 + SLen[S] > 10) Then Exit;
  For K := 0 To SLen[S] - 1 Do
  Begin
    Q := ShipCell(C, D, K);
    If (Own[P * 100 + Q] <> 0) And (Own[P * 100 + Q] <> S + 1) Then Exit;
  End;
  CanPlace := True;
End;

Procedure Unplace(P, S : LongInt);
Var K : LongInt;
Begin
  If SPos[P * NShip + S] < 0 Then Exit;
  For K := 0 To SLen[S] - 1 Do Own[P * 100 + ShipCell(SPos[P * NShip + S], SDir[P * NShip + S], K)] := 0;
  SPos[P * NShip + S] := -1;
End;

Procedure Place(P, S, C, D : LongInt);
Var K : LongInt;
Begin
  Unplace(P, S);
  SPos[P * NShip + S] := C; SDir[P * NShip + S] := D;
  For K := 0 To SLen[S] - 1 Do Own[P * 100 + ShipCell(C, D, K)] := S + 1;
End;

Procedure ClearFleet(P : LongInt);
Var K : LongInt;
Begin
  For K := 0 To 99 Do Own[P * 100 + K] := 0;
  For K := 0 To NShip - 1 Do
  Begin
    SPos[P * NShip + K] := -1; SDir[P * NShip + K] := 0; SHits[P * NShip + K] := 0;
  End;
End;

Procedure RandomFleet(P : LongInt);
Var S, C, D : LongInt;
Begin
  ClearFleet(P);
  For S := 0 To NShip - 1 Do
  Begin
    Repeat
      C := Rnd(100); D := Rnd(2);
    Until CanPlace(P, S, C, D);
    Place(P, S, C, D);
  End;
End;

Function NextUnplaced(P : LongInt) : LongInt;
Var S : LongInt;
Begin
  NextUnplaced := -1;
  For S := NShip - 1 DownTo 0 Do If SPos[P * NShip + S] < 0 Then NextUnplaced := S;
End;

Function Sunk(P, S : LongInt) : Boolean;
Begin
  Sunk := SHits[P * NShip + S] >= SLen[S];
End;

Function Afloat(P : LongInt) : LongInt;
Var S, N : LongInt;
Begin
  N := 0;
  For S := 0 To NShip - 1 Do If Not Sunk(P, S) Then Inc(N);
  Afloat := N;
End;

{ ==================================================================== }
{ Ordinateur : ou tirer sur la flotte de Q                              }
{ ==================================================================== }

{ case connue comme faisant partie d'un navire coule }
Function SunkCell(Q, C : LongInt) : Boolean;
Begin
  SunkCell := (Shot[Q * 100 + C] = 2) And (Own[Q * 100 + C] > 0) And Sunk(Q, Own[Q * 100 + C] - 1);
End;

Function CpuTarget(Q : LongInt) : LongInt;
Var S, C, D, K, H, Bad, Q2, W, Best, N, Any, Pick : LongInt; HasOpen : Boolean;
Begin
  For C := 0 To 99 Do Weight[C] := 0;
  { touches pas encore coules ? }
  HasOpen := False;
  For C := 0 To 99 Do
    If (Shot[Q * 100 + C] = 2) And Not SunkCell(Q, C) Then HasOpen := True;
  If Level = 0 Then
  Begin
    { facile : autour des coups au but, sinon au hasard }
    If HasOpen Then
      For C := 0 To 99 Do
        If (Shot[Q * 100 + C] = 2) And Not SunkCell(Q, C) Then
        Begin
          If (C Mod 10 > 0) And (Shot[Q * 100 + C - 1] = 0) Then Weight[C - 1] := 1;
          If (C Mod 10 < 9) And (Shot[Q * 100 + C + 1] = 0) Then Weight[C + 1] := 1;
          If (C >= 10) And (Shot[Q * 100 + C - 10] = 0) Then Weight[C - 10] := 1;
          If (C < 90) And (Shot[Q * 100 + C + 10] = 0) Then Weight[C + 10] := 1;
        End;
  End
  Else
  Begin
    { normal : densite des positions possibles des navires restants ;
      celles qui passent par des touches comptent beaucoup plus }
    For S := 0 To NShip - 1 Do
      If Not Sunk(Q, S) Then
        For D := 0 To 1 Do
          For C := 0 To 99 Do
            If ((D = 0) And (C Mod 10 + SLen[S] <= 10)) Or ((D = 1) And (C Div 10 + SLen[S] <= 10)) Then
            Begin
              H := 0; Bad := 0;
              For K := 0 To SLen[S] - 1 Do
              Begin
                Q2 := ShipCell(C, D, K);
                If (Shot[Q * 100 + Q2] = 1) Or SunkCell(Q, Q2) Then Bad := 1
                Else If Shot[Q * 100 + Q2] = 2 Then Inc(H);
              End;
              If (Bad = 0) And ((H > 0) Or Not HasOpen) Then
              Begin
                W := 1 + H * 40;
                For K := 0 To SLen[S] - 1 Do
                Begin
                  Q2 := ShipCell(C, D, K);
                  If Shot[Q * 100 + Q2] = 0 Then Weight[Q2] := Weight[Q2] + W;
                End;
              End;
            End;
  End;
  Best := 0;
  For C := 0 To 99 Do If (Shot[Q * 100 + C] = 0) And (Weight[C] > Best) Then Best := Weight[C];
  { au hasard parmi les meilleures cases (ou parmi les cases libres) }
  N := 0;
  For C := 0 To 99 Do
    If (Shot[Q * 100 + C] = 0) And ((Best = 0) Or (Weight[C] = Best)) Then Inc(N);
  Any := -1;
  If N > 0 Then
  Begin
    Pick := Rnd(N);
    For C := 0 To 99 Do
      If (Shot[Q * 100 + C] = 0) And ((Best = 0) Or (Weight[C] = Best)) Then
      Begin
        If Pick = 0 Then Any := C;
        Dec(Pick);
      End;
  End;
  CpuTarget := Any;
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

Var
  Pending : LongInt;                { fin de tour en attente (on voit d'abord le resultat) }

{ joueur dont la flotte est a gauche }
Function ViewP : LongInt;
Begin
  If Mode = 1 Then
  Begin
    If Phase = 0 Then ViewP := Placer Else ViewP := Turn;
  End
  Else ViewP := 0;
End;

Function Placing : Boolean;
Begin
  Placing := (Phase = 0) And (Kind[Placer] = 0) And (Curtain = 0);
End;

Function HumanFires : Boolean;
Begin
  HumanFires := (Phase = 1) And (Over = 0) And (Curtain = 0) And (Pending = 0) And (Kind[Turn] = 0) And (Wait = 0);
End;

Procedure Button(X, Y, W, H : LongInt; S : String; On : Boolean);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  If On Then OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY)
  Else OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_DARKGRAY, CLR_PALEGRAY);
End;

{ ---- navires vus de dessus (grille) : chaque type a sa silhouette ----
  repere du navire : A le long (0 a la poupe, la proue au bout), B en
  travers ; horizontal : proue a droite, vertical : proue en bas }
Var
  ShX1, ShY1, ShD : LongInt;

Procedure TB(A1, B1, A2, B2, Col : LongInt);
Begin
  If ShD = 0 Then FBar(ShX1 + A1, ShY1 + B1, ShX1 + A2, ShY1 + B2, Col)
  Else FBar(ShX1 + B1, ShY1 + A1, ShX1 + B2, ShY1 + A2, Col);
End;

Procedure TDisc(A, B, R, Col : LongInt);
Begin
  If ShD = 0 Then Disc(ShX1 + A, ShY1 + B, R, Col) Else Disc(ShX1 + B, ShY1 + A, R, Col);
End;

{ coque : demi-largeur Hw, proue effilee sur Bow points, poupe sur Stern }
Procedure Hull(Lp, Wd, Hw, Bow, Stern, Col, Edge0 : LongInt);
Var A, H, C : LongInt;
Begin
  C := Wd Div 2;
  For A := 0 To Lp - 1 Do
  Begin
    H := Hw;
    If (Bow > 0) And (A > Lp - 1 - Bow) Then H := Hw * (Lp - A) Div (Bow + 1);
    If (Stern > 0) And (A < Stern) Then H := Hw * (A + 1 + Stern) Div (2 * Stern + 1);
    If H < 1 Then H := 1;
    TB(A, C - H, A, C + H - 1, Edge0);
    If H > 1 Then TB(A, C - H + 1, A, C + H - 2, Col);
  End;
End;

{ navire S (type) de premiere case C, direction D ; Dark : coule }
Procedure DrawShip(X0, C, D, S : LongInt; Dark : Boolean; Bg : LongInt);
Var Lp, Wd, Cn, K, Hc, Dk, Lt : LongInt;
Begin
  ShX1 := X0 + (C Mod 10) * Cs + 3; ShY1 := GY + (C Div 10) * Cs + 3; ShD := D;
  Lp := SLen[S] * Cs - 6; Wd := Cs - 6; Cn := Wd Div 2;
  If Dark Then
  Begin
    Hc := CLR_DARKGRAY; Dk := CLR_BLACK; Lt := CLR_DARKGRAY;
  End
  Else
  Begin
    Hc := CLR_PALEGRAY; Dk := CLR_DARKGRAY; Lt := CLR_WHITE;
  End;
  Case S Of
    0 :
      Begin
        { porte-avions : pont d'envol large, piste, ilot sur le cote }
        Hull(Lp, Wd, Cn, 4, 0, Dk, CLR_BLACK);
        TB(2, 2, Lp - 4, Wd - 3, Dk);
        K := 6;
        While K < Lp - 8 Do
        Begin
          TB(K, Cn - 1, K + 3, Cn - 1, Lt);
          K := K + 7;
        End;
        TB(Lp * 6 Div 10, Wd - 6, Lp * 6 Div 10 + 10, Wd - 2, Hc);
        TB(Lp * 6 Div 10, Wd - 6, Lp * 6 Div 10 + 10, Wd - 6, Lt);
        TB(Lp * 6 Div 10 + 4, Wd - 5, Lp * 6 Div 10 + 6, Wd - 3, CLR_BLACK);
      End;
    1 :
      Begin
        { cuirasse : trois tourelles, superstructure }
        Hull(Lp, Wd, 7, 14, 3, Hc, CLR_BLACK);
        TB(Lp * 4 Div 10, Cn - 3, Lp * 6 Div 10, Cn + 2, Lt);
        TB(Lp * 4 Div 10 + 3, Cn - 2, Lp * 6 Div 10 - 3, Cn + 1, Dk);
        For K := 0 To 2 Do
        Begin
          Case K Of
            0 : Hc := Lp * 15 Div 100;
            1 : Hc := Lp * 70 Div 100;
          Else
            Hc := Lp * 82 Div 100;
          End;
          TDisc(Hc, Cn, 3, Dk);
          If K = 0 Then TB(Hc - 7, Cn - 1, Hc, Cn, Dk) Else TB(Hc, Cn - 1, Hc + 7, Cn, Dk);
        End;
      End;
    2 :
      Begin
        { croiseur : deux tourelles, cheminee }
        Hull(Lp, Wd, 6, 12, 3, Hc, CLR_BLACK);
        TB(Lp * 38 Div 100, Cn - 2, Lp * 60 Div 100, Cn + 1, Lt);
        TDisc(Lp * 48 Div 100, Cn, 2, CLR_BLACK);
        TDisc(Lp * 20 Div 100, Cn, 3, Dk);
        TB(Lp * 20 Div 100 - 6, Cn - 1, Lp * 20 Div 100, Cn - 1, Dk);
        TDisc(Lp * 78 Div 100, Cn, 3, Dk);
        TB(Lp * 78 Div 100, Cn - 1, Lp * 78 Div 100 + 6, Cn - 1, Dk);
      End;
    3 :
      Begin
        { sous-marin : coque etroite et sombre, arrondie aux deux bouts, kiosque }
        Hull(Lp, Wd, 5, 10, 8, Dk, CLR_BLACK);
        TB(Lp * 4 Div 10, Cn - 2, Lp * 52 Div 100, Cn + 1, CLR_BLACK);
        TB(Lp * 4 Div 10 + 1, Cn - 1, Lp * 52 Div 100 - 1, Cn, Hc);
        TB(4, Cn - 1, Lp * 4 Div 10 - 2, Cn - 1, CLR_BLACK);
      End;
  Else
    Begin
      { torpilleur : coque fine, une tourelle, cheminee }
      Hull(Lp, Wd, 5, 12, 2, Hc, CLR_BLACK);
      TB(Lp * 45 Div 100, Cn - 2, Lp * 62 Div 100, Cn + 1, Lt);
      TDisc(Lp * 35 Div 100, Cn, 2, CLR_BLACK);
      TDisc(Lp * 78 Div 100, Cn, 2, Dk);
      TB(Lp * 78 Div 100, Cn - 1, Lp * 78 Div 100 + 5, Cn - 1, Dk);
    End;
  End;
End;

{ ---- navires de profil (comme sur un ecran de placement) : ligne de
  flottaison en Yw, longueur W, hauteur H, de la poupe (gauche) a la
  proue (droite) ---- }
Procedure SB(X1, Y1, X2, Y2, Col : LongInt);
Begin
  If X2 < X1 Then Begin X2 := X2 + X1; X1 := X2 - X1; X2 := X2 - X1; End;
  If Y2 < Y1 Then Begin Y2 := Y2 + Y1; Y1 := Y2 - Y1; Y2 := Y2 - Y1; End;
  FBar(X1, Y1, X2, Y2, Col);
End;

Procedure SideShip(X, Yw, W, H, S : LongInt; Dark : Boolean);
Var Hb, K, X1, X2, Hc, Lt, Dk, Top : LongInt;
Begin
  If Dark Then
  Begin
    Hc := CLR_DARKGRAY; Lt := CLR_DARKGRAY; Dk := CLR_BLACK;
  End
  Else
  Begin
    Hc := CLR_PALEGRAY; Lt := CLR_WHITE; Dk := CLR_DARKGRAY;
  End;
  If S = 3 Then Hb := H * 2 Div 10 Else Hb := H * 35 Div 100;
  If Hb < 2 Then Hb := 2;
  Top := Yw - Hb;
  { coque : la proue avance au-dessus de l'eau, la poupe est arrondie }
  For K := 0 To Hb Do
  Begin
    X1 := X + K * (W Div 30) Div Hb + 1;
    X2 := X + W - 1 - K * (W Div 10) Div Hb;
    If S = 3 Then
    Begin
      X1 := X + Abs(2 * K - Hb) * (W Div 16) Div (Hb + 1);
      X2 := X + W - 1 - Abs(2 * K - Hb) * (W Div 10) Div (Hb + 1);
    End;
    If K = 0 Then SB(X1, Top + K, X2, Top + K, Lt) Else SB(X1, Top + K, X2, Top + K, Hc);
  End;
  SB(X + W Div 30, Yw, X + W - W Div 10, Yw, Dk);
  Case S Of
    0 :
      Begin
        { pont d'envol et ilot }
        SB(X - 2, Top - H Div 10, X + W + 2, Top - 1, Lt);
        SB(X - 2, Top - 1, X + W + 2, Top - 1, Dk);
        SB(X + W * 62 Div 100, Top - H * 45 Div 100, X + W * 72 Div 100, Top - H Div 10, Hc);
        SB(X + W * 62 Div 100, Top - H * 45 Div 100, X + W * 72 Div 100, Top - H * 45 Div 100, Lt);
        SB(X + W * 67 Div 100, Top - H * 65 Div 100, X + W * 67 Div 100, Top - H * 45 Div 100, Dk);
      End;
    1 :
      Begin
        { superstructure en gradins, mat, trois tourelles avec leurs canons }
        SB(X + W * 38 Div 100, Top - H * 28 Div 100, X + W * 62 Div 100, Top - 1, Hc);
        SB(X + W * 44 Div 100, Top - H * 50 Div 100, X + W * 56 Div 100, Top - H * 28 Div 100, Hc);
        SB(X + W * 44 Div 100, Top - H * 50 Div 100, X + W * 56 Div 100, Top - H * 50 Div 100, Lt);
        SB(X + W * 50 Div 100, Top - H * 80 Div 100, X + W * 50 Div 100, Top - H * 50 Div 100, Dk);
        SB(X + W * 14 Div 100, Top - H * 14 Div 100, X + W * 22 Div 100, Top - 1, Hc);
        SB(X + W * 6 Div 100, Top - H * 10 Div 100, X + W * 14 Div 100, Top - H * 10 Div 100, Dk);
        SB(X + W * 68 Div 100, Top - H * 14 Div 100, X + W * 76 Div 100, Top - 1, Hc);
        SB(X + W * 76 Div 100, Top - H * 10 Div 100, X + W * 84 Div 100, Top - H * 10 Div 100, Dk);
        SB(X + W * 78 Div 100, Top - H * 18 Div 100, X + W * 85 Div 100, Top - H * 14 Div 100 - 1, Hc);
        SB(X + W * 85 Div 100, Top - H * 16 Div 100, X + W * 92 Div 100, Top - H * 16 Div 100, Dk);
      End;
    2 :
      Begin
        { superstructure, cheminee, deux tourelles }
        SB(X + W * 36 Div 100, Top - H * 30 Div 100, X + W * 60 Div 100, Top - 1, Hc);
        SB(X + W * 36 Div 100, Top - H * 30 Div 100, X + W * 60 Div 100, Top - H * 30 Div 100, Lt);
        SB(X + W * 44 Div 100, Top - H * 50 Div 100, X + W * 50 Div 100, Top - H * 30 Div 100, Dk);
        SB(X + W * 56 Div 100, Top - H * 70 Div 100, X + W * 56 Div 100, Top - H * 30 Div 100, Dk);
        SB(X + W * 16 Div 100, Top - H * 13 Div 100, X + W * 24 Div 100, Top - 1, Hc);
        SB(X + W * 8 Div 100, Top - H * 9 Div 100, X + W * 16 Div 100, Top - H * 9 Div 100, Dk);
        SB(X + W * 70 Div 100, Top - H * 13 Div 100, X + W * 78 Div 100, Top - 1, Hc);
        SB(X + W * 78 Div 100, Top - H * 9 Div 100, X + W * 87 Div 100, Top - H * 9 Div 100, Dk);
      End;
    3 :
      Begin
        { kiosque et periscope }
        SB(X + W * 40 Div 100, Top - H * 40 Div 100, X + W * 54 Div 100, Top, Hc);
        SB(X + W * 40 Div 100, Top - H * 40 Div 100, X + W * 54 Div 100, Top - H * 40 Div 100, Lt);
        SB(X + W * 47 Div 100, Top - H * 65 Div 100, X + W * 47 Div 100, Top - H * 40 Div 100, Dk);
        SB(X + W * 47 Div 100, Top - H * 65 Div 100, X + W * 50 Div 100, Top - H * 65 Div 100, Dk);
      End;
  Else
    Begin
      { torpilleur : passerelle, cheminee, une tourelle avant }
      SB(X + W * 52 Div 100, Top - H * 30 Div 100, X + W * 66 Div 100, Top - 1, Hc);
      SB(X + W * 52 Div 100, Top - H * 30 Div 100, X + W * 66 Div 100, Top - H * 30 Div 100, Lt);
      SB(X + W * 38 Div 100, Top - H * 40 Div 100, X + W * 45 Div 100, Top - 1, Dk);
      SB(X + W * 60 Div 100, Top - H * 60 Div 100, X + W * 60 Div 100, Top - H * 30 Div 100, Dk);
      SB(X + W * 74 Div 100, Top - H * 12 Div 100, X + W * 80 Div 100, Top - 1, Hc);
      SB(X + W * 80 Div 100, Top - H * 9 Div 100, X + W * 87 Div 100, Top - H * 9 Div 100, Dk);
    End;
  End;
End;

Procedure CellXY(X0, C : LongInt; Var X, Y : LongInt);
Begin
  X := X0 + (C Mod 10) * Cs + Cs Div 2; Y := GY + (C Div 10) * Cs + Cs Div 2;
End;

Procedure Frame2(X0, C, Col : LongInt);
Var X, Y : LongInt;
Begin
  X := X0 + (C Mod 10) * Cs; Y := GY + (C Div 10) * Cs;
  Edge(X, Y, X + Cs - 1, Y + Cs - 1, Col, Col);
  Edge(X + 1, Y + 1, X + Cs - 2, Y + Cs - 2, Col, Col);
End;

{ grille de la flotte de P (Ships : navires visibles) }
Procedure DrawGrid(X0, P : LongInt; Ships, Target : Boolean);
Var K, S, X, Y, C, Q : LongInt; Ok : Boolean;
Begin
  FBar(X0 - 2, GY - 2, X0 + GW + 1, GY + GW + 1, CLR_PALEGRAY);
  Edge(X0 - 2, GY - 2, X0 + GW + 1, GY + GW + 1, CLR_DARKGRAY, CLR_WHITE);
  FBar(X0, GY, X0 + GW - 1, GY + GW - 1, CLR_DARKBLUE);
  For K := 1 To 9 Do
  Begin
    FBar(X0 + K * Cs, GY, X0 + K * Cs, GY + GW - 1, CLR_BLUE);
    FBar(X0, GY + K * Cs, X0 + GW - 1, GY + K * Cs, CLR_BLUE);
  End;
  For K := 0 To 9 Do
  Begin
    OutTxt(X0 + K * Cs + Cs Div 2 - 4, GY - 18, Chr(65 + K), CLR_BLACK, CLR_PALEGRAY);
    If K = 9 Then OutTxt(X0 - 22, GY + K * Cs + 4, '10', CLR_BLACK, CLR_PALEGRAY)
    Else OutTxt(X0 - 14, GY + K * Cs + 4, IStr(K + 1), CLR_BLACK, CLR_PALEGRAY);
  End;
  For S := 0 To NShip - 1 Do
    If SPos[P * NShip + S] >= 0 Then
      If Ships Or Sunk(P, S) Then
        DrawShip(X0, SPos[P * NShip + S], SDir[P * NShip + S], S, Sunk(P, S) And Not Ships, CLR_DARKBLUE);
  For C := 0 To 99 Do
  Begin
    CellXY(X0, C, X, Y);
    If Shot[P * 100 + C] = 1 Then
    Begin
      Disc(X, Y, 4, CLR_WHITE);
      Disc(X, Y, 2, CLR_CYAN);
    End
    Else If Shot[P * 100 + C] = 2 Then
    Begin
      Disc(X, Y, 7, CLR_RED);
      Disc(X, Y - 1, 4, CLR_YELLOW);
      Disc(X, Y - 2, 2, CLR_WHITE);
    End;
  End;
  If (LastShot[P] >= 0) And (Phase = 1) Then Frame2(X0, LastShot[P], CLR_YELLOW);
  { navire a placer (fantome) }
  If Placing And Not Target And (CurShip >= 0) And (Hover >= 0) Then
  Begin
    Ok := CanPlace(P, CurShip, Hover, PDir);
    For K := 0 To SLen[CurShip] - 1 Do
    Begin
      Q := ShipCell(Hover, PDir, K);
      If (PDir = 0) And (Q Div 10 <> Hover Div 10) Then Q := -1;
      If Q > 99 Then Q := -1;
      If Q >= 0 Then
      Begin
        If Ok Then Frame2(X0, Q, CLR_GREEN) Else Frame2(X0, Q, CLR_RED);
      End;
    End;
  End;
  { curseur du clavier }
  If ((Target And HumanFires) Or (Not Target And Placing)) And (Cur >= 0) Then
  Begin
    X := X0 + (Cur Mod 10) * Cs; Y := GY + (Cur Div 10) * Cs;
    Edge(X + 2, Y + 2, X + Cs - 3, Y + Cs - 3, CLR_PINK, CLR_PINK);
  End;
End;

{ liste des navires de P sous sa grille }
Procedure DrawPanel(X0, P : LongInt; Mine : Boolean);
Var S, K, Y, Col, W : LongInt; T : String;
Begin
  FBar(X0 - 30, PanY, X0 + GW + 1, PanY + 114, CLR_PALEGRAY);
  If Mine And (Mode = 0) Then T := Tx(T_YOURFLEET)
  Else If Mine Or (Mode <> 0) Then T := Fmt1(Tx(T_FLEETOF), PName(P))
  Else T := Tx(T_ENEMYFLEET);
  OutTxt(X0, PanY, T, CLR_DARKBLUE, CLR_PALEGRAY);
  FBar(X0, PanY + 17, X0 + Length(T) * 8, PanY + 17, CLR_DARKBLUE);
  For S := 0 To NShip - 1 Do
  Begin
    Y := PanY + 20 + S * 16;
    T := ShipName(S);
    If Placing And Mine And (S = CurShip) Then OutTxt(X0 - 14, Y, Chr(16), CLR_RED, CLR_PALEGRAY);
    If Sunk(P, S) Then Col := CLR_DARKGRAY Else Col := CLR_BLACK;
    OutTxt(X0, Y, T, Col, CLR_PALEGRAY);
    If Sunk(P, S) Then FBar(X0, Y + 8, X0 + Length(T) * 8 - 1, Y + 8, CLR_RED);
    { silhouette de profil sur l'eau ; touches en rouge }
    FBar(X0 + 130, Y, X0 + GW - 1, Y + 15, CLR_DARKBLUE);
    W := SLen[S] * 20 + 2;
    SideShip(X0 + 133, Y + 13, W, 14, S, Sunk(P, S));
    FBar(X0 + 130, Y + 14, X0 + GW - 1, Y + 15, CLR_BLUE);
    If Mine Or Sunk(P, S) Then
      For K := 0 To SHits[P * NShip + S] - 1 Do
        Disc(X0 + 133 + W * (2 * K + 1) Div (2 * SLen[S]), Y + 10, 2, CLR_RED);
    If Mine And (Phase = 0) And (SPos[P * NShip + S] >= 0) Then
      OutTxt(X0 + 114, Y, Chr(251), CLR_DARKGREEN, CLR_PALEGRAY);
  End;
  If Phase > 0 Then
    OutTxt(X0, PanY + 100, Fmt2(Tx(T_STATS), IStr(NShots[P]), IStr(NHits[P])), CLR_DARKGRAY, CLR_PALEGRAY);
End;

{ panneau de placement (a la place de la grille ennemie) }
Procedure DrawPlacePanel;
Var X0, Y : LongInt;
Begin
  X0 := RX;
  FBar(X0 - 2, GY - 20, X0 + GW + 1, GY + GW + 1, CLR_PALEGRAY);
  Edge(X0 - 2, GY - 2, X0 + GW + 1, GY + GW + 1, CLR_DARKGRAY, CLR_WHITE);
  FBar(X0, GY, X0 + GW - 1, GY + GW - 1, CLR_WHITE);
  Y := GY + 6;
  OutTxt(X0 + 6, Y, Tx(T_PLACE1), CLR_DARKBLUE, CLR_WHITE);
  OutTxt(X0 + 6, Y + 18, Tx(T_PLACE2), CLR_BLACK, CLR_WHITE);
  OutTxt(X0 + 6, Y + 34, Tx(T_PLACE3), CLR_BLACK, CLR_WHITE);
  OutTxt(X0 + 6, Y + 50, Tx(T_PLACE4), CLR_BLACK, CLR_WHITE);
  OutTxt(X0 + 6, Y + 66, Tx(T_PLACE5), CLR_BLACK, CLR_WHITE);
  If CurShip >= 0 Then
  Begin
    OutTxt(X0 + 6, Y + 84, Chr(16) + ' ' + ShipName(CurShip) + ' (' + IStr(SLen[CurShip]) + ')', CLR_RED, CLR_WHITE);
    { le navire de profil, sur l'eau }
    FBar(X0 + 6, GY + 108, X0 + GW - 7, GY + 160, CLR_DARKBLUE);
    FBar(X0 + 6, GY + 154, X0 + GW - 7, GY + 160, CLR_BLUE);
    SideShip(X0 + (GW - SLen[CurShip] * 42) Div 2, GY + 154, SLen[CurShip] * 42, 44, CurShip, False);
  End;
  Button(X0 + 4, GY + 166, 114, 30, Tx(T_BROTATE), CurShip >= 0);
  Button(X0 + 122, GY + 166, 114, 30, Tx(T_BRANDOM), True);
  Button(X0 + 4, GY + 202, 114, 30, Tx(T_BCLEAR), True);
  Button(X0 + 122, GY + 202, 114, 30, Tx(T_BDONE), CurShip < 0);
End;

{ rideau (deux joueurs : l'autre ne doit pas voir la flotte) }
Procedure DrawCurtain;
Var S : String; P : LongInt;
Begin
  FBar(10, 8, CW - 11, CH - 30, CLR_DARKBLUE);
  Edge(10, 8, CW - 11, CH - 30, CLR_BLUE, CLR_BLACK);
  If Phase = 0 Then
  Begin
    P := Placer;
    S := Fmt1(Tx(T_CURTPLACE), PName(P));
  End
  Else
  Begin
    P := Turn;
    S := Fmt1(Tx(T_CURT1), PName(P));
  End;
  BigText((CW - Length(S) * 16) Div 2, 150, S, CLR_YELLOW, CLR_DARKBLUE);
  S := Tx(T_CURT2);
  OutTxt((CW - Length(S) * 8) Div 2, 210, S, CLR_WHITE, CLR_DARKBLUE);
  S := Tx(T_CURT3);
  OutTxt((CW - Length(S) * 8) Div 2, 232, S, CLR_PALEGRAY, CLR_DARKBLUE);
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure DrawAll;
Var V : LongInt;
Begin
  FBar(0, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  If Curtain <> 0 Then DrawCurtain
  Else
  Begin
    V := ViewP;
    DrawGrid(LX, V, True, False);
    DrawPanel(LX, V, True);
    If Placing Then DrawPlacePanel
    Else
    Begin
      DrawGrid(RX, Opp(V), (Mode = 2) Or (Over <> 0), True);
      DrawPanel(RX, Opp(V), False);
    End;
  End;
  DrawStatus;
End;

Procedure PaintAll(H : LongInt);
Begin
  Hps := WinBeginPaint(H, 0, 0);
  DrawAll;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ redessine une grille sans effacer la fenetre (survol, curseur) }
Procedure ShowGrid(Right : Boolean);
Var V : LongInt;
Begin
  If (Client = 0) Or (Curtain <> 0) Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  V := ViewP;
  If Right Then DrawGrid(RX, Opp(V), (Mode = 2) Or (Over <> 0), True)
  Else DrawGrid(LX, V, True, False);
  Dummy := WinReleasePS(Hps);
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

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure SetMark(Id : LongInt; On : Boolean);
Var M : LongInt;
Begin
  M := WinWindowFromID(Frame, $8005);
  If M = 0 Then Exit;
  If On Then Dummy := WinSendMsg(M, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16))
  Else Dummy := WinSendMsg(M, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED);
End;

Procedure SetMarks;
Var L : LongInt;
Begin
  SetMark(CM_HVC, Mode = 0); SetMark(CM_HVH, Mode = 1); SetMark(CM_CVC, Mode = 2);
  SetMark(CM_EASY, Level = 0); SetMark(CM_NORMAL, Level = 1);
  SetMark(CM_SALVO, Salvo <> 0);
  For L := 0 To 4 Do SetMark(CM_LANG0 + L, Lang = L);
End;

Function ShotsFor(P : LongInt) : LongInt;
Begin
  If Salvo <> 0 Then ShotsFor := Afloat(P) Else ShotsFor := 1;
End;

{ message de la barre d'etat selon l'etat de la partie }
Procedure StateMsg;
Begin
  If Over <> 0 Then Msg := Fmt1(Tx(T_GAMEOVER), PName(Winner))
  Else If Phase = 0 Then
  Begin
    If CurShip < 0 Then Msg := Tx(T_ALLPLACED)
    Else Msg := Tx(T_PLACEMSG);
  End
  Else If Kind[Turn] = 1 Then Msg := Fmt1(Tx(T_AIMING), PName(Turn))
  Else Msg := Fmt2(Tx(T_YOURTURN), PName(Turn), IStr(ShotsLeft));
End;

Procedure StartBattle;
Begin
  Phase := 1; Turn := 0; ShotsLeft := ShotsFor(0); Pending := 0; Cur := 44;
  If Mode = 1 Then Curtain := 1;
  If Kind[Turn] = 1 Then Wait := 6 Else Wait := 0;
  StateMsg;
  If Mode = 2 Then Msg := Tx(T_DEMO);
  Redraw;
End;

Procedure StartPlacing(P : LongInt);
Begin
  Placer := P; Phase := 0;
  CurShip := NextUnplaced(P); PDir := 0; Hover := -1; Cur := 0;
  If Mode = 1 Then Curtain := 1;
  StateMsg;
  Redraw;
End;

Procedure NewGame;
Var P : LongInt;
Begin
  For P := 0 To 1 Do
  Begin
    ClearFleet(P);
    NShots[P] := 0; NHits[P] := 0; LastShot[P] := -1;
  End;
  For P := 0 To 199 Do Shot[P] := 0;
  Case Mode Of
    0 : Begin Kind[0] := 0; Kind[1] := 1; End;
    1 : Begin Kind[0] := 0; Kind[1] := 0; End;
  Else
    Begin Kind[0] := 1; Kind[1] := 1; End;
  End;
  Over := 0; Winner := 0; Curtain := 0; Pending := 0; Wait := 0;
  For P := 0 To 1 Do If Kind[P] = 1 Then RandomFleet(P);
  If Kind[0] = 0 Then StartPlacing(0) Else StartBattle;
End;

{ fin du placement du joueur qui place }
Procedure PlaceDone;
Begin
  If CurShip >= 0 Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  If (Mode = 1) And (Placer = 0) Then StartPlacing(1) Else StartBattle;
End;

Procedure PlaceAt(C : LongInt);
Var S : LongInt;
Begin
  If Not Placing Or (C < 0) Then Exit;
  S := Own[Placer * 100 + C];
  If (S > 0) And ((CurShip < 0) Or Not CanPlace(Placer, CurShip, C, PDir)) Then
  Begin
    { reprendre ce navire }
    S := S - 1;
    PDir := SDir[Placer * NShip + S];
    Unplace(Placer, S);
    CurShip := S;
    StateMsg;
    Redraw;
    Exit;
  End;
  If CurShip < 0 Then Exit;
  If Not CanPlace(Placer, CurShip, C, PDir) Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Msg := Tx(T_NOTFIT);
    Redraw;
    Exit;
  End;
  Place(Placer, CurShip, C, PDir);
  CurShip := NextUnplaced(Placer);
  StateMsg;
  Redraw;
End;

Procedure Rotate;
Begin
  If Not Placing Or (CurShip < 0) Then Exit;
  PDir := 1 - PDir;
  ShowGrid(False);
End;

Procedure PlaceRandom;
Begin
  If Not Placing Then Exit;
  RandomFleet(Placer);
  CurShip := -1;
  StateMsg;
  Redraw;
End;

Procedure PlaceClear;
Begin
  If Not Placing Then Exit;
  ClearFleet(Placer);
  CurShip := 0;
  StateMsg;
  Redraw;
End;

Procedure GameOver(W : LongInt);
Var S : String; A : LongInt;
Begin
  Over := 1; Winner := W; Pending := 0; Curtain := 0;
  StateMsg;
  Redraw;
  If AutoAll <> 0 Then Exit;
  A := 0;
  If NShots[W] > 0 Then A := NHits[W] * 100 Div NShots[W];
  S := Fmt1(Tx(T_WINS), PName(W)) + Chr(10) + Fmt2(Tx(T_STATS), IStr(NShots[W]), IStr(NHits[W])) + '  ' +
       Fmt1(Tx(T_ACCURACY), IStr(A)) + Chr(10) + Chr(10) + Tx(T_NEWQ);
  If Ask(S, Tx(T_TITLE), MB_YESNO Or MB_QUERY) = MBID_YES Then NewGame;
End;

{ tir du joueur Turn sur la case C de la flotte adverse }
Procedure Fire(C : LongInt);
Var T, Q, S, Si : LongInt;
Begin
  T := Turn; Q := Opp(T);
  If (C < 0) Or (C > 99) Then Exit;
  If Shot[Q * 100 + C] <> 0 Then
  Begin
    If Kind[T] = 0 Then
    Begin
      Dummy := WinAlarm(HWND_DESKTOP, 0);
      Msg := Tx(T_ALREADY);
      Redraw;
    End;
    Exit;
  End;
  Inc(NShots[T]);
  LastShot[Q] := C;
  S := Own[Q * 100 + C];
  If S > 0 Then
  Begin
    Shot[Q * 100 + C] := 2;
    Si := Q * NShip + S - 1;
    Inc(SHits[Si]);
    Inc(NHits[T]);
    If Sunk(Q, S - 1) Then
    Begin
      Msg := Fmt1(Fmt2(Tx(T_SUNK), PName(T), SqName(C)), ShipName(S - 1));
      If Afloat(Q) = 0 Then
      Begin
        GameOver(T);
        Exit;
      End;
    End
    Else Msg := Fmt2(Tx(T_HIT), PName(T), SqName(C));
  End
  Else
  Begin
    Shot[Q * 100 + C] := 1;
    Msg := Fmt2(Tx(T_MISS), PName(T), SqName(C));
  End;
  Dec(ShotsLeft);
  If ShotsLeft <= 0 Then
  Begin
    { on voit le resultat un instant avant de passer la main }
    Pending := 1;
    If Mode = 1 Then Wait := 12 Else Wait := 7;
  End
  Else If Kind[T] = 1 Then Wait := 5
  Else Msg := Msg + '  (' + IStr(ShotsLeft) + ')';
  Redraw;
End;

Procedure SwitchTurn;
Begin
  Pending := 0;
  Turn := Opp(Turn);
  ShotsLeft := ShotsFor(Turn);
  If Mode = 1 Then Curtain := 1;
  If Kind[Turn] = 1 Then Wait := 5 Else Wait := 0;
  StateMsg;
  Redraw;
End;

Procedure TimerTick;
Begin
  If Over <> 0 Then
  Begin
    If AutoAll <> 0 Then
    Begin
      Inc(Wait);
      If Wait > 50 Then NewGame;
    End;
    Exit;
  End;
  If (Phase <> 1) Or (Curtain <> 0) Then Exit;
  If Wait > 0 Then
  Begin
    Dec(Wait);
    Exit;
  End;
  If Pending <> 0 Then
  Begin
    SwitchTurn;
    Exit;
  End;
  If Kind[Turn] = 1 Then Fire(CpuTarget(Opp(Turn)));
End;

{ ==================================================================== }
{ Menus (refaits quand on change de langue)                             }
{ ==================================================================== }

Procedure BuildMenu;
Var H0, H1, H2, H3, L : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, Tx(T_MGAME));
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, Tx(T_MNEW) + Chr(9) + 'F2');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_HVC, Tx(T_MHVC));
  MItem(MIS_TEXT, 0, CM_HVH, Tx(T_MHVH));
  MItem(MIS_TEXT, 0, CM_CVC, Tx(T_MCVC));
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_EASY, Tx(T_MEASY));
  MItem(MIS_TEXT, 0, CM_NORMAL, Tx(T_MNORMAL));
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_SALVO, Tx(T_MSALVO));
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, Tx(T_MQUIT));
  MenuClose(H1, 12);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, Tx(T_MLANG));
  H2 := MenuOpen;
  For L := 0 To 4 Do MItem(MIS_TEXT, 0, CM_LANG0 + L, LangName(L));
  MenuClose(H2, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, Tx(T_MHELP));
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, Tx(T_MRULES) + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, Tx(T_MABOUT));
  MenuClose(H3, 2);
  MenuClose(H0, 3);
  Dummy := WinCreateMenu(Frame, LongInt(@MenuT));
  SetMarks;
End;

Procedure SetLang(L : LongInt);
Begin
  Lang := L;
  BuildMenu;
  Dummy := WinSetWindowText(Frame, Z(Tx(T_TITLE)));
  StateMsg;
  Redraw;
End;

Procedure SetMode(M : LongInt);
Begin
  Mode := M;
  SetMarks;
  NewGame;
End;

Procedure Command(Id : LongInt);
Begin
  If (Id >= CM_LANG0) And (Id < CM_LANG0 + 5) Then
  Begin
    SetLang(Id - CM_LANG0);
    Exit;
  End;
  Case Id Of
    CM_NEW : NewGame;
    CM_HVC : SetMode(0);
    CM_HVH : SetMode(1);
    CM_CVC : SetMode(2);
    CM_EASY : Begin Level := 0; SetMarks; End;
    CM_NORMAL : Begin Level := 1; SetMarks; End;
    CM_SALVO :
      Begin
        Salvo := 1 - Salvo;
        SetMarks;
        If Salvo <> 0 Then Msg := Tx(T_SALVOON);
        NewGame;
        If Salvo <> 0 Then
        Begin
          Msg := Tx(T_SALVOON);
          Redraw;
        End;
      End;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES :
      Begin
        LClr;
        LAdd(Tx(T_RULES1)); LAdd(Tx(T_RULES2)); LAdd(Tx(T_RULES3));
        LAdd(Chr(10) + Chr(10)); LAdd(Tx(T_RULES4));
        Dummy := LMsgBox(Tx(T_RULESCAP), MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT :
      Begin
        LClr;
        LAdd(Tx(T_ABOUT1)); LAdd(Chr(10)); LAdd(Tx(T_ABOUT2));
        Dummy := LMsgBox(Tx(T_ABOUTCAP), MB_OK Or MB_INFORMATION);
      End;
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Function CellAt(X0, X, Y : LongInt) : LongInt;
Begin
  CellAt := -1;
  If (X >= X0) And (X < X0 + GW) And (Y >= GY) And (Y < GY + GW) Then
    CellAt := ((Y - GY) Div Cs) * 10 + (X - X0) Div Cs;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, C : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If Curtain <> 0 Then
  Begin
    Curtain := 0;
    Redraw;
    Exit;
  End;
  If Placing Then
  Begin
    C := CellAt(LX, X, Y);
    If C >= 0 Then
    Begin
      Cur := C;
      PlaceAt(C);
      Exit;
    End;
    If (Y >= GY + 166) And (Y < GY + 196) Then
    Begin
      If (X >= RX + 4) And (X < RX + 118) Then Rotate
      Else If (X >= RX + 122) And (X < RX + 236) Then PlaceRandom;
    End
    Else If (Y >= GY + 202) And (Y < GY + 232) Then
    Begin
      If (X >= RX + 4) And (X < RX + 118) Then PlaceClear
      Else If (X >= RX + 122) And (X < RX + 236) Then PlaceDone;
    End;
    Exit;
  End;
  If HumanFires Then
  Begin
    C := CellAt(RX, X, Y);
    If C >= 0 Then
    Begin
      Cur := C;
      Fire(C);
    End;
  End;
End;

Procedure MoveCur(D : LongInt);
Begin
  If Not (Placing Or HumanFires) Then Exit;
  Case D Of
    0 : If Cur Mod 10 > 0 Then Dec(Cur);
    1 : If Cur Mod 10 < 9 Then Inc(Cur);
    2 : If Cur >= 10 Then Cur := Cur - 10;
  Else
    If Cur < 90 Then Cur := Cur + 10;
  End;
  If Placing Then
  Begin
    Hover := Cur;
    ShowGrid(False);
  End
  Else ShowGrid(True);
End;

Procedure Action;
Begin
  If Curtain <> 0 Then
  Begin
    Curtain := 0;
    Redraw;
  End
  Else If Placing Then
  Begin
    If CurShip < 0 Then PlaceDone Else PlaceAt(Cur);
  End
  Else If HumanFires Then Fire(Cur);
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
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If Vk = VK_LEFT Then Begin MoveCur(0); Exit; End;
    If Vk = VK_RIGHT Then Begin MoveCur(1); Exit; End;
    If Vk = VK_UP Then Begin MoveCur(2); Exit; End;
    If Vk = VK_DOWN Then Begin MoveCur(3); Exit; End;
    If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Or (Vk = VK_SPACE) Then Begin Action; Exit; End;
  End;
  If ((Fl And KC_CHAR) = 0) Or ((Fl And (KC_ALT Or KC_CTRL)) <> 0) Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Ch = 82) Or (Ch = 114) Then Rotate
  Else If (Ch = 65) Or (Ch = 97) Then PlaceRandom
  Else If Ch = 32 Then Action
  Else KeyChar := False;
End;

Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; C : LongInt;
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
    WM_MOUSEMOVE :
      Begin
        If Placing Then
        Begin
          C := CellAt(LX, S16(Mp1), CH - 1 - S16(Mp1 Shr 16));
          If C <> Hover Then
          Begin
            Hover := C;
            ShowGrid(False);
          End;
        End;
        MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_BUTTON1DOWN :
      Begin
        Dummy := WinSetFocus(HWND_DESKTOP, H);
        Click(S16(Mp1), S16(Mp1 Shr 16));
        MainProc := 1;
      End;
    WM_BUTTON2DOWN :
      Begin
        Rotate;
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

Var
  FcF, ScrW, ScrH, Fw, Fh, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  SLen[0] := 5; SLen[1] := 4; SLen[2] := 3; SLen[3] := 3; SLen[4] := 2;
  Msg := ''; AutoAll := 0; Mode := 0; Level := 1; Salvo := 0; Phase := 0; Curtain := 0; Over := 0; Pending := 0;
  Client := 0; Frame := 0;
  Lang := LangOf(EnvLang);
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) > 6) And (UpStr(Copy(S, 1, 6)) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If (Length(S) > 6) And (UpStr(Copy(S, 1, 6)) = '/LANG:') Then Lang := LangOf(Copy(S, 7, 3));
    If UpStr(S) = '/AUTO' Then
    Begin
      AutoAll := 1; Mode := 2;
    End;
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  Dummy := WinRegisterClass(Hab, Z('BATTLE'), LongInt(@MainProc), 0, 0);
  FcF := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@FcF), Z('BATTLE'), Z2(Tx(T_TITLE)), 0, 0, 0,
                              LongInt(@Client));
  BuildMenu;
  Rc[0] := 0; Rc[1] := 0; Rc[2] := CWant; Rc[3] := CHWant;
  Dummy := WinCalcFrameRect(Frame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  ScrW := WinQuerySysValue(HWND_DESKTOP, 20); ScrH := WinQuerySysValue(HWND_DESKTOP, 21);
  X := (ScrW - Fw) Div 2; Y := (ScrH - Fh) Div 2;
  If X < 0 Then X := 0;
  If Y < 0 Then Y := ScrH - Fh;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  NewGame;
  Dummy := WinStartTimer(Hab, Client, 1, 100);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
